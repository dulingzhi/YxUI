local YxUI, Language, Assets, Settings, Defaults = select(2, ...):get()

local AceSerializer = LibStub:GetLibrary("AceSerializer-3.0")
local LibDeflate = LibStub:GetLibrary("LibDeflate")
local GUI = YxUI:GetModule("GUI")
local DefaultKey = "%s-%s"

local next = next
local format = format
local match = string.match

YxUI.ProfileList = {}

YxUI.ProfileMetadata = {
	["profile-name"] = true,
	["profile-created"] = true,
	["profile-created-by"] = true,
	["profile-last-modified"] = true,
}

YxUI.PreserveSettings = {
	"ui-scale",
	"ui-display-welcome",
	"ui-picker-palette",
}

function YxUI:UpdateProfileList()
	if self.Profiles then
		for Name in next, self.Profiles do
			self.ProfileList[Name] = Name
		end
	end
end

function YxUI:GetProfileCount()
	local Count = 0

	for Name in next, self.Profiles do
		Count = Count + 1
	end

	return Count
end

function YxUI:GetDefaultProfileKey()
	return format(DefaultKey, self.UserName, self.UserRealm)
end

function YxUI:GetActiveProfileName()
	if (self.ProfileData and self.ProfileData[self.UserProfileKey]) then
		return self.ProfileData[self.UserProfileKey]
	end
end

function YxUI:GetActiveProfile()
	if (self.ProfileData and self.ProfileData[self.UserProfileKey]) then
		return self:GetProfile(self.ProfileData[self.UserProfileKey])
	end
end

function YxUI:SetActiveProfile(name)
	if (self.ProfileData and self.ProfileData[self.UserProfileKey]) then
		self.ProfileData[self.UserProfileKey] = name
	end
end

function YxUI:CountChangedValues(name)
	local Profile = self:GetProfile(name)
	local Count = 0

	for ID in next, Profile do
		if (not self.ProfileMetadata[ID]) then
			Count = Count + 1
		end
	end

	return Count
end

function YxUI:CreateProfileData()
	if (not self.ProfileData) then -- No profile data exists, create a default
		self:CreateProfile(Language["Default"])
	end

	if (not self.ProfileData[self.UserProfileKey]) then
		self.ProfileData[self.UserProfileKey] = self:GetMostUsedProfile()
	end
end

function YxUI:CreateProfileNameID(name)
	local ID = 0
	local Found

	repeat
		ID = ID + 1

		if (not self.Profiles[format("%s (%d)", name, ID)]) then
			Found = true
		end
	until Found == true

	return format("%s (%d)", name, ID)
end

function YxUI:AddProfile(profile)
	if (type(profile) ~= "table") then
		return
	end

	local Name = profile["profile-name"]

	if (not Name) then
		return
	end

	if self.Profiles[Name] then
		local NewName = self:CreateProfileNameID(Name)

		self:print(format(Language['A profile already exists with the name "%s".'], Name))

		Name = NewName
	end

	profile["profile-created"] = self:GetCurrentDate()
	profile["profile-created-by"] = self.UserProfileKey
	profile["profile-last-modified"] = self:GetCurrentDate()

	self.Profiles[Name] = profile
	self.ProfileList[Name] = Name

	local Widget = GUI:GetWidget("ui-profile")
	Widget.Dropdown:CreateSelection(Name, Name)
	Widget.Dropdown:Sort()

	self:print(format(Language['Added profile: "%s".'], Name))

	self:UpdateProfileInfo()
end

function YxUI:CreateProfile(name)
	self:BindSavedVariable("YxUIProfileData", "ProfileData")
	self:BindSavedVariable("YxUIProfiles", "Profiles")

	if (not name) then
		name = self:GetDefaultProfileKey()
	end

	if (not self.ProfileData[self.UserProfileKey]) then
		self.ProfileData[self.UserProfileKey] = name
	end

	if self.Profiles[name] then
		self.ProfileList[name] = name

		return self.Profiles[name]
	end

	self.Profiles[name] = {}

	-- Some metadata just for additional information
	self.Profiles[name]["profile-name"] = name
	self.Profiles[name]["profile-created"] = self:GetCurrentDate()
	self.Profiles[name]["profile-created-by"] = self:GetDefaultProfileKey()
	self.Profiles[name]["profile-last-modified"] = self:GetCurrentDate()

	self.ProfileList[name] = name

	return self.Profiles[name]
end

function YxUI:RestoreToDefault(name)
	if (not self.Profiles[name]) then
		return
	end

	for ID in next, self.Profiles[name] do
		if (not self.ProfileMetadata[ID]) then
			self.Profiles[name][ID] = nil
		end
	end

	self:print(format('Restored profile "%s" to default.', name))
end

function YxUI:GetProfile(name)
	if self.Profiles[name] then
		return self.Profiles[name]
	else
		local Default = self:GetMostUsedProfile()

		if (not Default) then
			return self:CreateProfile(Language["Default"])
		elseif (Default and self.Profiles[Default]) then
			return self.Profiles[Default]
		end
	end
end

function YxUI:SetProfileValue(name, id, value)
	if self.Profiles[name] then
		if (value ~= Defaults[id]) then -- Only saving a value if it's different than default
			self.Profiles[name][id] = value

			self:UpdateProfileLastModified(name)
		else
			self.Profiles[name][id] = nil
		end
	end
end

function YxUI:GetProfileList()
	return self.ProfileList
end

function YxUI:ProfileIsUsedBy(name)
	local First = true
	local String

	for Key, ProfileName in next, self.ProfileData do
		if (ProfileName == name) then
			if First then
				String = Key
				First = false
			else
				String = String .. ", " .. Key
			end
		end
	end

	return String
end

function YxUI:GetMostUsedProfile() -- Return most used profile as a fallback instead of "Default" which may not even exist if the user deletes it
	local Temp = {}
	local HighestValue = 0
	local HighestName

	for Key, ProfileName in next, self.ProfileData do
		if (not Temp[ProfileName]) then -- In case we renamed something
			Temp[ProfileName] = 0
		end

		Temp[ProfileName] = (Temp[ProfileName] or 0) + 1
	end

	for Name, Value in next, Temp do
		if (Value > HighestValue) then
			HighestValue = Value
			HighestName = Name
		end
	end

	return HighestName, self.ProfileData[HighestName]
end

function YxUI:GetNumServedByProfile(name)
	local Count = 0
	local Total = 0

	for Key, ProfileName in next, self.ProfileData do
		if (ProfileName == name) then
			Count = Count + 1
		end

		Total = Total + 1
	end

	return Count, (Count == Total)
end

function YxUI:DeleteProfile(name)
	if self.Profiles[name] then
		self.Profiles[name] = nil
		self.ProfileList[name] = nil

		local Default = self:GetMostUsedProfile()

		-- If we just wiped out a profile that characters were using, reroute them to an existing profile.
		for Key, ProfileName in next, self.ProfileData do
			if (ProfileName == name) then
				self.ProfileData[Key] = Default
			end
		end

		self:print(format('Deleted profile "%s".', name))
	else
		self:print(format('No profile exists with the name "%s".', name))
	end

	if (self:GetProfileCount() == 0) then
		self:CreateProfile(Language["Default"]) -- If we just deleted our last profile, make a new default.

		for Key in next, self.ProfileData do
			self.ProfileData[Key] = Language["Default"]
		end
	end

	if (name == self:GetActiveProfileName()) then
		C_UI.Reload()
	end
end

function YxUI:MergeWithDefaults(name)
	local Profile = self:GetProfile(name)
	local Values = {}

	-- Collect default values
	for ID, Value in next, Defaults do
		Values[ID] = Value
	end

	-- And apply stored values
	if Profile then
		for ID, Value in next, Profile do
			Values[ID] = Value
		end
	end

	return Values
end

function YxUI:ApplyProfile(name)
	local Values = self:MergeWithDefaults(name)

	for ID, Value in next, Values do
		Settings[ID] = Value
	end

	self.ProfileData[self.UserProfileKey] = name

	Values = nil

	--[[local Profile = self:GetProfile(name)

	Settings = setmetatable(Profile, {__index = Defaults})
	print(Defaults["ab-enable"],Settings["ab-enable"])
	self.ProfileData[self.UserProfileKey] = name]]
end

function YxUI:DeleteUnusedProfiles()
	local Deleted = 0
	local Counts = {}
	local Count = 0

	self:UpdateProfileList()

	for Name in next, self.ProfileList do
		Counts[Name] = 0
	end

	for Key, ProfileName in next, self.ProfileData do
		if (not Counts[ProfileName]) then -- In case we renamed something
			Counts[ProfileName] = 0
		end

		Counts[ProfileName] = Counts[ProfileName] + 1
	end

	for Name, Total in next, Counts do
		if (Total == 0) then
			self:DeleteProfile(Name)

			Deleted = Deleted + 1
		end
	end

	for Name, Value in next, self.Profiles do
		Count = 0

		for ID in next, Value do
			if (not self.ProfileMetadata[ID]) then
				Count = Count + 1
			end
		end

		if (Count == 0) then
			self:DeleteProfile(Name)

			Deleted = Deleted + 1
		end
	end

	Counts = nil

	self:print(format("Deleted %s unused profiles.", Deleted))
end

function YxUI:CountUnusedProfiles()
	local Unused = 0
	local Counts = {}
	local Count = 0

	self:UpdateProfileList()

	for Name in next, self.ProfileList do
		Counts[Name] = 0
	end

	for Key, ProfileName in next, self.ProfileData do
		if (not Counts[ProfileName]) then -- In case we renamed something
			Counts[ProfileName] = 0
		end

		Counts[ProfileName] = Counts[ProfileName] + 1
	end

	for Name, Total in next, Counts do
		if (Total == 0) then
			Unused = Unused + 1
		end
	end

	for Name, Value in next, self.Profiles do
		Count = 0

		for ID in next, Value do
			if (not self.ProfileMetadata[ID]) then
				Count = Count + 1
			end
		end

		if (Count == 0) then
			Unused = Unused + 1
		end
	end

	Counts = nil

	return Unused
end

function YxUI:RenameProfile(from, to)
	if (not self.Profiles[from]) then
		return
	elseif self.Profiles[to] then
		self:print(format(Language['A profile already exists with the name "%s".'], to))

		return
	end

	self.Profiles[to] = self.Profiles[from]
	self.Profiles[to]["profile-name"] = to

	self.Profiles[from] = nil
	self.ProfileList[from] = nil
	self.ProfileList[to] = to

	-- Reroute characters who used this profile
	for Key, ProfileName in next, self.ProfileData do
		if (ProfileName == from) then
			self.ProfileData[Key] = to
		end
	end

	-- Update dropdown menu if needed

	self:print(format(Language['Profile "%s" has been renamed to "%s".'], from, to))
end

function YxUI:CopyProfile(from, to)
	if (not self.Profiles[from]) or (not self.Profiles[to]) then
		return
	end

	self.Profiles[to] = self:GetProfile(from)
	self.Profiles[to]["profile-last-modified"] = self:GetCurrentDate()

	self:print(format(Language['Profile "%s" has been copied from "%s".'], to, from))

	C_UI.Reload()
end

function YxUI:UpdateProfileLastModified(name)
	local Profile = self:GetProfile(name)

	Profile["profile-last-modified"] = self:GetCurrentDate()
end

function YxUI:SetProfileMetadata(name, meta, value) -- /run YxUIGlobal:get():SetProfileMetadata("ProfileName", "profile-created-by", "Jai")
	if (self.Profiles[name] and self.ProfileMetadata[meta]) then
		self.Profiles[name][meta] = value

		if (name == self:GetActiveProfileName()) then
			self:UpdateProfileInfo()
		end
	end
end

--[[
	Temporary module
	Sometimes I might want to change setting names or values, but make sure that people still keep their settings so that I don't get yelled at.
	This keeps profiles lean because I can remove old keys, and it allows me to seamlessly change existing settings and profiles
	Remove MigrateValue declarations after a reasonable while.
--]]

YxUI.MigrateKeys = {}
YxUI.MigrateValues = {}
YxUI.MigrateGlobals = {}

function YxUI:MigrateKey(from, to) -- YxUI:MigrateKey("ui-display-welcome", "ui-welcome")
	tinsert(self.MigrateKeys, {From = from, To = to})
end

function YxUI:MigrateValue(key, from, to) -- YxUI:MigrateValue("unitframes-player-health-color", "CUSTOM", "CLASS") YxUI:MigrateValue("tooltips-hide-on-unit", "NO_COMBAT", "IN_COMBAT")
	tinsert(self.MigrateValues, {Key = key, From = from, To = to})
end

function YxUI:MigrateGlobal(from, to) -- YxUI:MigrateGlobal("YxUIData", "YxUIMisc")
	tinsert(self.MigrateGlobals, {From = from, To = to})
end

function YxUI:Migrate(profile)
	for i = #self.MigrateKeys, 1, -1 do
		if profile[self.MigrateKeys[i].From] then
			profile[self.MigrateKeys[i].To] = profile[self.MigrateKeys[i].From]
			profile[self.MigrateKeys[i].From] = nil

			tremove(self.MigrateKeys, 1)
		end
	end

	for i = #self.MigrateValues, 1, -1 do
		if profile[self.MigrateValues[i].Key] and profile[self.MigrateValues[i].Key] == self.MigrateValues[i].From then
			profile[self.MigrateValues[i].Key] = self.MigrateValues[i].To

			tremove(self.MigrateValues, 1)
		end
	end
end

function YxUI:MigrateData()
	for i = #self.MigrateGlobals, 1, -1 do
		if (not _G[self.MigrateGlobals[i].To]) then
			_G[self.MigrateGlobals[i].To] = {}
		end

		if _G[self.MigrateGlobals[i].From] then
			for Key, Value in next, _G[self.MigrateGlobals[i].From] do
				_G[self.MigrateGlobals[i].To][Key] = Value
			end

			tremove(self.MigrateGlobals, 1)
		end
	end

	if ((not self.Profiles) or (#self.MigrateValues == 0)) then
		return
	end

	for ProfileName, Profile in next, self.Profiles do
		YxUI:Migrate(Profile)
	end
end

function YxUI:MigrateMoverData()
	self:BindSavedVariable("YxUIData", "Data")

	if self.Data.MoversMigrated then
		return
	end

	if (YxUIMove and self.Profiles) then
		for Key, Profile in next, self.Profiles do
			if (not Profile.Move) then
				Profile.Move = {}
			end

			for Frame, Position in next, YxUIMove do
				Profile.Move[Frame] = format("%s:%s:%s:%s:%s", unpack(Position))
			end
		end

		YxUIMove = nil

		self.Data.MoversMigrated = true
	end
end

function YxUI:RemoveData(key)
	self:BindSavedVariable("YxUIData", "Data")

	if self.Data then
		self.Data[key] = nil
	end
end

function YxUI:CloneProfile(profile)
	local Clone = {}

	for Key, Value in next, profile do
		if (not self.PreserveSettings[Key]) then -- Ignore preserved settings for serializing
			Clone[Key] = Value
		end
	end

	return Clone
end

function YxUI:GetEncodedProfile()
	local Profile = self:CloneProfile(self:GetActiveProfile())
	local Serialized = AceSerializer:Serialize(Profile)
	local Compressed = LibDeflate:CompressDeflate(Serialized, {level = 9})
	local Encoded = LibDeflate:EncodeForPrint(Compressed)

	return Encoded
end

function YxUI:DecodeProfile(encoded)
	local Decoded = LibDeflate:DecodeForPrint(encoded)

	if (not Decoded) then
		return self:print("Failure decoding")
	end

	local Decompressed = LibDeflate:DecompressDeflate(Decoded)

	if (not Decompressed) then
		return self:print("Failure decompressing")
	end

	local Success, Deserialized = AceSerializer:Deserialize(Decompressed)

	if (not Success) then
		return self:print("Failure deserializing")
	end

	-- Check for migrated values
	if (#self.MigrateValues > 0) then
		self:Migrate(Deserialized)
	end

	return Deserialized
end

function YxUI:UpdateProfileInfo()
	local Name = self:GetActiveProfileName()
	local Profile = self:GetProfile(Name)
	local MostUsed = self:GetMostUsedProfile()
	local NumServed, IsAll = self:GetNumServedByProfile(Name)
	local MostUsedServed = NumServed

	if IsAll then
		NumServed = format("%d (%s)", NumServed, Language["All"])
	end

	if (Profile ~= MostUsed) then
		MostUsedServed = self:GetNumServedByProfile(MostUsed)
	end

	GUI:GetWidget("current-profile").Right:SetText(Name)
	GUI:GetWidget("created-by").Right:SetText(Profile["profile-created-by"])
	GUI:GetWidget("created-on").Right:SetText(YxUI:IsToday(Profile["profile-created"]))
	GUI:GetWidget("last-modified").Right:SetText(YxUI:IsToday(Profile["profile-last-modified"]))
	GUI:GetWidget("modifications").Right:SetText(self:CountChangedValues(Name))
	GUI:GetWidget("serving-characters").Right:SetText(NumServed)

	GUI:GetWidget("popular-profile").Right:SetText(format("%s (%d)", MostUsed, MostUsedServed))
	GUI:GetWidget("stored-profiles").Right:SetText(self:GetProfileCount())
	GUI:GetWidget("unused-profiles").Right:SetText(self:CountUnusedProfiles())
end

local AcceptNewProfile = function(value)
	YxUI:SetActiveProfile(value)

	C_UI.Reload()
end

local UpdateActiveProfile = function(value)
	if (value ~= YxUI:GetActiveProfileName()) then
		YxUI:DisplayPopup(Language["Attention"], format(Language['Are you sure you would like to change to the current profile to "%s"?'], value), ACCEPT, AcceptNewProfile, CANCEL, nil, value)
	end
end

local CreateProfile = function(value)
	if YxUI.Profiles[value] then
		return YxUI:print(format(Language['A profile already exists with the name "%s".'], value))
	end

	YxUI:CreateProfile(value)
	YxUI:UpdateProfileInfo()

	local Widget = GUI:GetWidget("ui-profile")
	Widget.Dropdown:CreateSelection(value, value)
	Widget.Dropdown:Sort()

	Widget = GUI:GetWidget("profile-copy")
	Widget.Dropdown:CreateSelection(value, value)
	Widget.Dropdown:Sort()

	Widget = GUI:GetWidget("profile-delete")
	Widget.Dropdown:CreateSelection(value, value)
	Widget.Dropdown:Sort()
end

local DeleteProfile = function(value)
	YxUI:DeleteProfile(value)
	YxUI:UpdateProfileInfo()

	local Widget = GUI:GetWidget("ui-profile")
	Widget.Dropdown:RemoveSelection(value)
	Widget.Dropdown.Current:SetText(YxUI:GetActiveProfileName())

	Widget = GUI:GetWidget("profile-copy")
	Widget.Dropdown:RemoveSelection(value)

	Widget = GUI:GetWidget("profile-delete")
	Widget.Dropdown:RemoveSelection(value)
	Widget.Dropdown.Current:SetText("")
end

local ShowExportWindow = function()
	local Encoded = YxUI:GetEncodedProfile()

	GUI:CreateExportWindow()
	GUI:SetExportWindowText(Encoded)
	GUI:ToggleExportWindow()
end

local ShowImportWindow = function()
	GUI:ToggleImportWindow()
end

local DeleteUnused = function()
	YxUI:DeleteUnusedProfiles()
	YxUI:UpdateProfileInfo()
end

local RenameProfile = function(value)
	if (value and match(value, "%S+")) then
		YxUI:RenameProfile(YxUI:GetActiveProfileName(), value)
		YxUI:UpdateProfileInfo()
	end
end

local RestoreToDefault = function()
	YxUI:RestoreToDefault(YxUI:GetActiveProfileName())

	C_UI.Reload() -- Temp
end

local CopyProfileOnAccept = function(from)
	YxUI:CopyProfile(from, YxUI:GetActiveProfileName())
end

local PromptDelete = function(value)
	YxUI:DisplayPopup(Language["Attention"], format(Language["Are you sure you would like to delete %s"], value), ACCEPT, DeleteProfile, CANCEL, nil, value)
end

local CopyProfile = function(value)
	YxUI:DisplayPopup(Language["Attention"], format(Language["Are you sure you would like to copy %s to %s?"], value, YxUI:GetActiveProfileName()), ACCEPT, CopyProfileOnAccept, CANCEL, nil, value)
end

GUI:AddWidgets(Language["General"], Language["Profiles"], function(left, right)
	left:CreateHeader(Language["Profiles"])
	left:CreateDropdown("ui-profile", YxUI:GetActiveProfileName(), YxUI:GetProfileList(), Language["Select Profile"], Language["Select a profile to load"], UpdateActiveProfile)
	--left:CreateButton("Apply", "Apply Current Profile", "", UpdateActiveProfile)

	left:CreateHeader(Language["Modify"])
	left:CreateInput("profile-key", YxUI:GetDefaultProfileKey(), Language["Create New Profile"], Language["Create a new profile to store a different collection of settings"], CreateProfile):DisableSaving()
	--left:CreateInput("profile-delete", YxUI:GetDefaultProfileKey(), Language["Delete Profile"], Language["Delete a profile"], DeleteProfile):DisableSaving()
	left:CreateInput("profile-rename", "", Language["Rename Profile"], Language["Rename the currently selected profile"], RenameProfile):DisableSaving()
	left:CreateDropdown("profile-delete", YxUI:GetActiveProfileName(), YxUI:GetProfileList(), Language["Delete Profile"],  Language["Delete a profile"], DeleteProfile):DisableSaving()
	left:CreateDropdown("profile-copy", YxUI:GetActiveProfileName(), YxUI:GetProfileList(), Language["Copy From"], Language["Copy the settings from another profile"], CopyProfile)

	left:CreateHeader(Language["Manage"])
	left:CreateButton("", Language["Restore"], Language["Restore To Default"], Language["Restore the currently selected profile to default settings"], RestoreToDefault):RequiresReload(true)
	left:CreateButton("", Language["Delete"], Language["Delete Unused Profiles"], Language["Delete any profiles that are not currently in use by any characters"], DeleteUnused)

	left:CreateHeader(Language["Sharing is caring"])
	left:CreateButton("", Language["Import"], Language["Import A Profile"], Language["Import a profile using an import string"], ShowImportWindow)
	left:CreateButton("", Language["Export"], Language["Export Current Profile"], Language["Export the currently active profile as a string that can be shared with others"], ShowExportWindow)

	right:CreateHeader(Language["What is a profile?"])
	right:CreateMessage("", Language["Profiles store your settings so that you can quickly and easily change between configurations."])

	local Name = YxUI:GetActiveProfileName()
	local Profile = YxUI:GetProfile(Name)
	local MostUsed = YxUI:GetMostUsedProfile()
	local NumServed, IsAll = YxUI:GetNumServedByProfile(Name)
	local MostUsedServed = NumServed

	if IsAll then
		NumServed = format("%d (%s)", NumServed, Language["All"])
	end

	if (Profile ~= MostUsed) then
		MostUsedServed = YxUI:GetNumServedByProfile(MostUsed)
	end

	right:CreateHeader(Language["Info"])
	right:CreateDoubleLine("current-profile", Language["Current Profile:"], Name)
	right:CreateDoubleLine("created-by", Language["Created By:"], Profile["profile-created-by"])
	right:CreateDoubleLine("created-on", Language["Created On:"], YxUI:IsToday(Profile["profile-created"]))
	right:CreateDoubleLine("last-modified", Language["Last Modified:"], YxUI:IsToday(Profile["profile-last-modified"]))
	right:CreateDoubleLine("modifications", Language["Modifications:"], YxUI:CountChangedValues(Name))
	right:CreateDoubleLine("serving-characters", Language["Serving Characters:"], NumServed)

	right:CreateHeader(Language["General"])
	right:CreateDoubleLine("popular-profile", Language["Popular Profile:"], format("%s (%d)", MostUsed, MostUsedServed))
	right:CreateDoubleLine("stored-profiles", Language["Stored Profiles:"], YxUI:GetProfileCount())
	right:CreateDoubleLine("unused-profiles", Language["Unused Profiles:"], YxUI:CountUnusedProfiles())
end)