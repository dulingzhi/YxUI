local YxUI, Language, Assets, Settings, Defaults = select(2, ...):get()

local AceSerializer = LibStub:GetLibrary("AceSerializer-3.0")
local LibDeflate = LibStub:GetLibrary("LibDeflate")
local GUI = YxUI:GetModule("GUI")
local DefaultKey = "%s-%s"

local next = next
local format = format
local match = string.match
local SupportsSpecProfiles = (YxUI.IsMainline and not YxUI.IsForever) or YxUI.IsMists

YxUI.ProfileList = {}

YxUI.ProfileMetadata = {
	["profile-name"] = true,
	["profile-created"] = true,
	["profile-created-by"] = true,
	["profile-last-modified"] = true,
}

YxUI.PreserveSettings = {
	["ui-scale"] = true,
	["ui-display-welcome"] = true,
	["ui-picker-palette"] = true,
}

function YxUI:UpdateProfileList()
	if self.Profiles then
		for Name in next, self.Profiles do
			self.ProfileList[Name] = Name
		end
	end
end

function YxUI:SynchronizeProfileSelectors(renamedFrom, renamedTo)
	local ids = {"profile-character-default", "profile-copy", "profile-delete"}
	for _, slot in ipairs(self:GetSpecializationSlots()) do
		ids[#ids + 1] = "profile-spec-" .. slot.Key
	end

	for i = 1, #ids do
		local id = ids[i]
		local widget = GUI:GetWidget(id)
		local dropdown = widget and widget.Dropdown
		if dropdown then
			local isSpec = id:sub(1, 13) == "profile-spec-"
			local options = self.ProfileList
			dropdown.Values = options
			if dropdown.Menu.Initialized then
				for j = #dropdown.Menu, 1, -1 do
					if not options[dropdown.Menu[j].Key] then
						dropdown:RemoveSelection(dropdown.Menu[j].Key)
					end
				end
				local listed = {}
				for j = 1, #dropdown.Menu do listed[dropdown.Menu[j].Key] = true end
				for name, value in next, options do
					if not listed[name] then dropdown:CreateSelection(name, value) end
				end
			end

			if id == "profile-character-default" then
				dropdown.Value = self:GetCharacterDefaultProfileName()
			elseif isSpec then
				dropdown.Value = self:GetSpecializationProfile(id:sub(14)) or self:GetCharacterDefaultProfileName()
			elseif dropdown.Value == renamedFrom and renamedTo then
				dropdown.Value = renamedTo
			elseif not self.ProfileList[dropdown.Value] then
				dropdown.Value = self:GetActiveProfileName()
			end

			for name, value in next, options do
				if value == dropdown.Value then
					dropdown.Current:SetText(name)
					break
				end
			end
			if dropdown.Menu.Initialized then dropdown:Sort() end
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

function YxUI:GetCharacterDefaultProfileName()
	return self.ProfileData and self.ProfileData[self.UserProfileKey]
end

function YxUI:GetActiveProfileName()
	return self.RuntimeProfileName or self:GetCharacterDefaultProfileName()
end

function YxUI:GetActiveProfile()
	local Name = self:GetActiveProfileName()
	return Name and self:GetProfile(Name)
end

function YxUI:SetActiveProfile(name)
	if self.ProfileData and self.ProfileData[self.UserProfileKey] then
		self.ProfileData[self.UserProfileKey] = name
	end
end

function YxUI:CountChangedValues(name)
	local Profile = self:GetProfile(name)
	local Count = 0

	for ID in next, Profile do
		if not self.ProfileMetadata[ID] then
			Count = Count + 1
		end
	end

	return Count
end

function YxUI:CreateProfileData()
	if not self.ProfileData then
		self:BindSavedVariable("YxUIProfileData", "ProfileData")
	end
	if not self.Profiles then
		self:BindSavedVariable("YxUIProfiles", "Profiles")
	end
	self:BindSavedVariable("YxUISpecializationProfiles", "SpecializationProfiles")
	if not next(self.Profiles) then
		self:CreateProfile(Language["Default"])
	end

	local Name = self.ProfileData[self.UserProfileKey]
	if not Name or not self.Profiles[Name] then
		local Replacement = self:GetMostUsedProfile()
		if not Replacement then
			Replacement = Language["Default"]
			self:CreateProfile(Replacement)
		end
		self.ProfileData[self.UserProfileKey] = Replacement
	end
end

-- Character defaults stay in ProfileData; spec assignments never overwrite them.
local function GetTalentGroupCount()
	local count = GetNumSpecGroups and GetNumSpecGroups()
	if type(count) == "number" then return count end
	return GetNumTalentGroups and GetNumTalentGroups()
end

local function GetActiveTalentGroupIndex()
	local api = C_SpecializationInfo
	local group = api and api.GetActiveSpecGroup and api.GetActiveSpecGroup()
	if type(group) == "number" then return group end
	group = GetActiveSpecGroup and GetActiveSpecGroup()
	if type(group) == "number" then return group end
	return GetActiveTalentGroup and GetActiveTalentGroup()
end

function YxUI:GetSpecializationSlots()
	local slots = {}
	if not SupportsSpecProfiles then return slots end
	local api = C_SpecializationInfo
	local modern = (self.IsMainline and not self.IsForever) or self.IsMists
	local _, _, classID = UnitClass("player")
	local count = modern and api and api.GetNumSpecializationsForClassID and classID and api.GetNumSpecializationsForClassID(classID)
	if modern and not count and GetNumSpecializations then
		count = GetNumSpecializations()
	end

	if modern and count and count > 0 and (api and api.GetSpecializationInfo or GetSpecializationInfo) then
		for i = 1, count do
			local id, name
			if api and api.GetSpecializationInfo then
				id, name = api.GetSpecializationInfo(i)
			else
				id, name = GetSpecializationInfo(i)
			end
			if id and id > 0 and name then
				slots[#slots + 1] = { Key = "spec:" .. id, Name = name }
			end
		end
	else
		local groups = GetTalentGroupCount()
		if type(groups) == "number" and groups > 1 then
			for i = 1, groups do
				slots[#slots + 1] = { Key = "talent:" .. i, Name = "Talent Group " .. i }
			end
		end
	end
	return slots
end

function YxUI:GetCurrentSpecializationKey()
	if not SupportsSpecProfiles then return nil end
	local api = C_SpecializationInfo
	local modern = (self.IsMainline and not self.IsForever) or self.IsMists
	local index = modern and (api and api.GetSpecialization and api.GetSpecialization() or (GetSpecialization and GetSpecialization()))
	if type(index) == "number" and index > 0 then
		local id
		if api and api.GetSpecializationInfo then
			id = api.GetSpecializationInfo(index)
		elseif GetSpecializationInfo then
			id = GetSpecializationInfo(index)
		end
		if id and id > 0 then
			return "spec:" .. id
		end
	end
	local groups = GetTalentGroupCount()
	if type(groups) == "number" and groups > 1 then
		local group = GetActiveTalentGroupIndex()
		if type(group) == "number" and group >= 1 and group <= groups then
			return "talent:" .. group
		end
	end
end

function YxUI:GetSpecializationProfile(key)
	local Assignments = self.SpecializationProfiles and self.SpecializationProfiles[self.UserProfileKey]
	local Name = Assignments and Assignments[key]
	return Name and self.Profiles[Name] and Name or nil
end

function YxUI:ResolveProfileForSpecialization()
	local Key = self:GetCurrentSpecializationKey()
	return (Key and self:GetSpecializationProfile(Key)) or self:GetCharacterDefaultProfileName()
end

function YxUI:SetSpecializationProfile(key, name)
	if name and not self.Profiles[name] then return end
	local Assignments = self.SpecializationProfiles[self.UserProfileKey]
	if not Assignments then
		Assignments = {}
		self.SpecializationProfiles[self.UserProfileKey] = Assignments
	end
	Assignments[key] = name
	if self:GetCurrentSpecializationKey() == key then
		self:SwitchProfile(self:ResolveProfileForSpecialization())
	end
	self:SynchronizeProfileSelectors()
	if GUI:GetWidget("current-profile") then self:UpdateProfileInfo() end
end

function YxUI:CreateProfileNameID(name)
	local ID = 1

	while self.Profiles[format("%s (%d)", name, ID)] do
		ID = ID + 1
	end

	return format("%s (%d)", name, ID)
end

function YxUI:AddProfile(profile)
	if type(profile) ~= "table" then
		return
	end

	local Name = profile["profile-name"]

	if type(Name) ~= "string" or not match(Name, "%S") then
		return
	end

	if self.Profiles[Name] then
		local NewName = self:CreateProfileNameID(Name)

		self:print(format(Language['A profile already exists with the name "%s".'], Name))

		Name = NewName
	end

	profile["profile-name"] = Name
	profile["profile-created"] = self:GetCurrentDate()
	profile["profile-created-by"] = self.UserProfileKey
	profile["profile-last-modified"] = self:GetCurrentDate()

	self.Profiles[Name] = profile
	self.ProfileList[Name] = Name

	self:SynchronizeProfileSelectors()

	self:print(format(Language['Added profile: "%s".'], Name))

	self:UpdateProfileInfo()
	return Name
end

function YxUI:CreateProfile(name)
	self:BindSavedVariable("YxUIProfileData", "ProfileData")
	self:BindSavedVariable("YxUIProfiles", "Profiles")

	if not name then
		name = self:GetDefaultProfileKey()
	end

	if not self.ProfileData[self.UserProfileKey] then
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
	self:SynchronizeProfileSelectors()

	return self.Profiles[name]
end

function YxUI:RestoreToDefault(name)
	if not self.Profiles[name] then
		return
	end

	for ID in next, self.Profiles[name] do
		if not self.ProfileMetadata[ID] then
			self.Profiles[name][ID] = nil
		end
	end

	self:print(format(Language['Restored profile "%s" to default.'], name))
end

function YxUI:GetProfile(name)
	if self.Profiles[name] then
		return self.Profiles[name]
	else
		local Default = self:GetMostUsedProfile()

		if not Default then
			return self:CreateProfile(Language["Default"])
		elseif Default and self.Profiles[Default] then
			return self.Profiles[Default]
		end
	end
end

function YxUI:SetProfileValue(name, id, value)
	if self.Profiles[name] then
		if value ~= Defaults[id] then -- Only saving a value if it's different than default
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
		if ProfileName == name then
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

function YxUI:GetMostUsedProfile()
	local Counts = {}
	local HighestName = self.Profiles[Language["Default"]] and Language["Default"] or next(self.Profiles)
	local HighestValue = 0

	for Key, Name in next, self.ProfileData do
		if self.Profiles[Name] then
			Counts[Name] = (Counts[Name] or 0) + 1
		end
	end

	for Name, Count in next, Counts do
		if Count > HighestValue then
			HighestValue = Count
			HighestName = Name
		end
	end

	return HighestName
end

function YxUI:GetNumServedByProfile(name)
	local Count = 0
	local Total = 0

	for Key, ProfileName in next, self.ProfileData do
		if ProfileName == name then
			Count = Count + 1
		end

		Total = Total + 1
	end

	return Count, (Count == Total)
end

function YxUI:DeleteProfile(name, deferSelectorSync)
	if not self.Profiles[name] then
		self:print(format(Language['No profile exists with the name "%s".'], name))

		return
	end

	local ReloadActive = name == self:GetActiveProfileName()
	self.Profiles[name] = nil
	self.ProfileList[name] = nil

	local Counts = {}
	for Key, ProfileName in next, self.ProfileData do
		if self.Profiles[ProfileName] then
			Counts[ProfileName] = (Counts[ProfileName] or 0) + 1
		end
	end

	local Replacement, Highest = nil, -1
	for ProfileName in next, self.Profiles do
		local Used = Counts[ProfileName] or 0
		if Used > Highest then
			Replacement, Highest = ProfileName, Used
		end
	end

	if not Replacement then
		Replacement = Language["Default"]
		self:CreateProfile(Replacement)
	end

	for Key, ProfileName in next, self.ProfileData do
		if ProfileName == name then
			self.ProfileData[Key] = Replacement
		end
	end
	for Character, Assignments in next, self.SpecializationProfiles do
		for Key, ProfileName in next, Assignments do
			if ProfileName == name then Assignments[Key] = nil end
		end
	end

	self:print(format(Language['Deleted profile "%s".'], name))
	if not deferSelectorSync then
		self:SynchronizeProfileSelectors()
	end

	if ReloadActive then
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
			local Default = Defaults[ID]
			if Default == nil or type(Value) == type(Default) then
				Values[ID] = Value
			end
		end
	end

	return Values
end

function YxUI:ApplyProfile(name)
	if not self.Profiles[name] then return end
	local Values = self:MergeWithDefaults(name)
	for ID in next, Defaults do
		Settings[ID] = Values[ID]
	end
	-- Translations are loaded before profiles; keep the displayed language in sync.
	Settings["ui-language"] = self.UserLocale
	self.RuntimeProfileName = name
end

function YxUI:SwitchProfile(name)
	if not name or not self.Profiles[name] then return false end
	if name == self:GetActiveProfileName() then
		self.PendingProfileName = nil
		self.PendingProfileSpecKey = nil
		return true
	end
	if InCombatLockdown() then
		self.PendingProfileName = name
		self.PendingProfileSpecKey = self:GetCurrentSpecializationKey()
		return false
	end

	local previousName = self:GetActiveProfileName()
	local Values = self:MergeWithDefaults(name)
	Values["ui-language"] = self.UserLocale
	local definitions = GUI.SettingDefinitions
	local changed = {}
	local needsReload = false
	for id in next, Defaults do
		if Settings[id] ~= Values[id] then
			changed[#changed + 1] = id
		end
	end

	-- Apply all values first, so callbacks observe the complete destination profile.
	for i = 1, #changed do
		local id = changed[i]
		Settings[id] = Values[id]
	end
	self.RuntimeProfileName = name
	for i = 1, #changed do
		local id = changed[i]
		local definition = definitions[id]
		local callback = definition and definition.OnChange
		if definition and not definition.RequiresReload then
			if type(callback) == "function" and callback ~= ReloadUI and (not C_UI or callback ~= C_UI.Reload) then
				local ok, err = pcall(callback, Values[id], id)
				if not ok then
					needsReload = true
					self:print('Live profile update failed for ' .. id .. ': ' .. tostring(err))
				end
			elseif not definition.ReadOnUse then
				needsReload = true
			end
		else
			needsReload = true
		end
	end

	self:ApplyProfileMoverPositions(previousName, name)
	self.PendingProfileName = nil
	self.PendingProfileSpecKey = nil
	self.ReloadProfileName = needsReload and name or nil
	if needsReload then
		self:print('Profile "' .. name .. '" activated. Some settings require /reload to finish applying.')
	end
	if GUI.Loaded then
		GUI:RefreshSettingWidgets(changed)
		-- Page definitions, not profile values, determine when frames need rebuilding.
		if GUI.ActivePage and GUI.ActivePage.WindowNeedsRebuild then
			GUI:ShowWindow(GUI.ActivePage)
		end
		self:SynchronizeProfileSelectors()
		if GUI:GetWidget("current-profile") then self:UpdateProfileInfo() end
	end
	return not needsReload
end

function YxUI:SwitchToSpecializationProfile()
	if not SupportsSpecProfiles then return end
	local name = self:ResolveProfileForSpecialization()
	if name then self:SwitchProfile(name) end
end

local SpecializationDriver = CreateFrame("Frame")
SpecializationDriver:RegisterEvent("PLAYER_REGEN_ENABLED")
SpecializationDriver:RegisterEvent("PLAYER_ENTERING_WORLD")
if YxUI.IsMainline and not YxUI.IsForever then
	SpecializationDriver:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
	SpecializationDriver:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	SpecializationDriver:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	SpecializationDriver:RegisterEvent("PLAYER_TALENT_UPDATE")
elseif YxUI.IsMists then
	SpecializationDriver:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	SpecializationDriver:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	SpecializationDriver:RegisterEvent("PLAYER_TALENT_UPDATE")
end

local function RefreshAfterSpecializationChange()
	if not YxUI.Profiles then return end
	YxUI:SwitchToSpecializationProfile()
	if YxUI.ProfileSpecializationSlotCount then
		local slots = YxUI:GetSpecializationSlots()
		if #slots ~= YxUI.ProfileSpecializationSlotCount then
			local page = GUI:HasButton("General", "Profiles")
			if page and page.Window then page.WindowNeedsRebuild = true end
		end
	end
	local chat = YxUI:GetModule("Chat")
	if chat and chat.Loaded and chat.Middle then
		chat:MoveChatFrames()
	end
end

local function ScheduleSpecializationRefresh()
	if SpecializationDriver.RefreshScheduled then return end
	SpecializationDriver.RefreshScheduled = true
	C_Timer.After(0.2, function()
		SpecializationDriver.RefreshScheduled = nil
		RefreshAfterSpecializationChange()
	end)
end

SpecializationDriver:SetScript("OnEvent", function(_, event, unit)
	if event == "PLAYER_REGEN_ENABLED" then
		if YxUI.PendingProfileName then
			local requested = YxUI.PendingProfileName
			if YxUI.PendingProfileSpecKey ~= YxUI:GetCurrentSpecializationKey() then
				requested = YxUI:ResolveProfileForSpecialization()
			end
			YxUI.PendingProfileName = nil
			YxUI.PendingProfileSpecKey = nil
			YxUI:SwitchProfile(requested)
		end
	elseif event ~= "PLAYER_SPECIALIZATION_CHANGED" or not unit or unit == "player" then
		ScheduleSpecializationRefresh()
	end
end)

function YxUI:GetUnusedProfileNames()
	local Used = {}
	local Unused = {}
	local Active = self:GetActiveProfileName()

	for Key, Name in next, self.ProfileData or {} do
		Used[Name] = true
	end
	for Character, Assignments in next, self.SpecializationProfiles or {} do
		for Key, Name in next, Assignments do
			Used[Name] = true
		end
	end

	for Name in next, self.Profiles do
		if Name ~= Active and not Used[Name] then
			Unused[#Unused + 1] = Name
		end
	end

	return Unused
end

function YxUI:DeleteUnusedProfiles()
	local Unused = self:GetUnusedProfileNames()

	for i = 1, #Unused do
		self:DeleteProfile(Unused[i], true)
	end

	self:SynchronizeProfileSelectors()
	self:print(format(Language["Deleted %s unused profiles."], #Unused))
end

function YxUI:CountUnusedProfiles()
	return #self:GetUnusedProfileNames()
end

function YxUI:RenameProfile(from, to)
	if not self.Profiles[from] then
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
		if ProfileName == from then
			self.ProfileData[Key] = to
		end
	end
	for Character, Assignments in next, self.SpecializationProfiles do
		for Key, ProfileName in next, Assignments do
			if ProfileName == from then Assignments[Key] = to end
		end
	end
	if self.RuntimeProfileName == from then self.RuntimeProfileName = to end

	self:SynchronizeProfileSelectors(from, to)

	self:print(format(Language['Profile "%s" has been renamed to "%s".'], from, to))
end

local function CopyProfileValue(value, seen)
	if type(value) ~= "table" then
		return value
	end

	if seen[value] then
		return seen[value]
	end

	local copy = {}
	seen[value] = copy

	for key, item in next, value do
		copy[CopyProfileValue(key, seen)] = CopyProfileValue(item, seen)
	end

	return copy
end

function YxUI:CopyProfile(from, to)
	local Source, Destination = self.Profiles[from], self.Profiles[to]
	if not Source or not Destination or from == to then
		return
	end

	local Copy, Seen = {}, {}
	for ID, Value in next, Source do
		if not self.ProfileMetadata[ID] then
			Copy[ID] = CopyProfileValue(Value, Seen)
		end
	end

	for ID in next, self.ProfileMetadata do
		Copy[ID] = Destination[ID]
	end

	Copy["profile-name"] = to
	Copy["profile-last-modified"] = self:GetCurrentDate()
	self.Profiles[to] = Copy

	self:print(format(Language['Profile "%s" has been copied from "%s".'], to, from))

	C_UI.Reload()
end

function YxUI:UpdateProfileLastModified(name)
	local Profile = self:GetProfile(name)

	Profile["profile-last-modified"] = self:GetCurrentDate()
end

function YxUI:SetProfileMetadata(name, meta, value) -- /run YxUIGlobal:get():SetProfileMetadata("ProfileName", "profile-created-by", "Hydra")
	if self.Profiles[name] and self.ProfileMetadata[meta] then
		self.Profiles[name][meta] = value

		if name == self:GetActiveProfileName() then
			self:UpdateProfileInfo()
		end
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
		if not self.PreserveSettings[Key] then -- Ignore preserved settings for serializing
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

	if not Decoded then
		return self:print(Language["Failure decoding"])
	end

	local Decompressed = LibDeflate:DecompressDeflate(Decoded)

	if not Decompressed then
		return self:print(Language["Failure decompressing"])
	end

	local Success, Deserialized = AceSerializer:Deserialize(Decompressed)

	if not Success then
		return self:print(Language["Failure deserializing"])
	end

	if type(Deserialized) ~= "table" or type(Deserialized["profile-name"]) ~= "string" or not match(Deserialized["profile-name"], "%S") then
		return self:print(Language["Invalid profile data"])
	end

	local Profile = { ["profile-name"] = Deserialized["profile-name"] }
	local Skipped = 0

	for ID, Value in next, Deserialized do
		if not self.ProfileMetadata[ID] then
			local Default = Defaults[ID]
			if type(ID) == "string" and Default ~= nil and not self.PreserveSettings[ID] and type(Value) == type(Default) and (type(Value) ~= "number" or (Value == Value and Value ~= math.huge and Value ~= -math.huge)) then
				Profile[ID] = Value
			else
				Skipped = Skipped + 1
			end
		end
	end

	return Profile, Skipped
end

function YxUI:UpdateProfileInfo()
	local Widget = GUI:GetWidget("current-profile")
	if Widget then
		Widget.Right:SetText(self:GetActiveProfileName())
	end
end

local function ShowActiveProfileTooltip(self)
	local Name = YxUI:GetActiveProfileName()
	local Profile = YxUI:GetProfile(Name)
	local NumServed, IsAll = YxUI:GetNumServedByProfile(Name)

	if IsAll then
		NumServed = format("%d (%s)", NumServed, Language["All"])
	end

	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	GameTooltip:AddLine(Name, 1, 1, 1)
	GameTooltip:AddDoubleLine(Language["Created By:"], tostring(Profile["profile-created-by"] or ""), 1, 1, 1, 1, 1, 1)
	GameTooltip:AddDoubleLine(Language["Created On:"], tostring(YxUI:IsToday(Profile["profile-created"]) or ""), 1, 1, 1, 1, 1, 1)
	GameTooltip:AddDoubleLine(Language["Last Modified:"], tostring(YxUI:IsToday(Profile["profile-last-modified"]) or ""), 1, 1, 1, 1, 1, 1)
	GameTooltip:AddDoubleLine(Language["Modifications:"], tostring(YxUI:CountChangedValues(Name)), 1, 1, 1, 1, 1, 1)
	GameTooltip:AddDoubleLine(Language["Serving Characters:"], tostring(NumServed), 1, 1, 1, 1, 1, 1)
	GameTooltip:Show()
end

local CreateProfile = function(value)
	if YxUI.Profiles[value] then
		return YxUI:print(format(Language['A profile already exists with the name "%s".'], value))
	end

	YxUI:CreateProfile(value)
	YxUI:UpdateProfileInfo()
end

local DeleteProfile = function(value)
	YxUI:DeleteProfile(value)
	YxUI:UpdateProfileInfo()
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

local PromptDeleteUnused = function()
	local Count = YxUI:CountUnusedProfiles()
	if Count == 0 then
		YxUI:print(Language["No unused profiles to delete."])
		return
	end

	local Description = format("%d unused profile%s", Count, Count == 1 and "" or "s")
	YxUI:DisplayPopup(Language["Attention"], format(Language["Are you sure you want to delete %s?"], Description), ACCEPT, DeleteUnused, CANCEL)
end

local RenameProfile = function(value)
	if value and match(value, "%S+") then
		YxUI:RenameProfile(YxUI:GetActiveProfileName(), value)
		YxUI:UpdateProfileInfo()
	end
end

local RestoreToDefault = function(name)
	if not YxUI.Profiles[name] then
		return
	end

	YxUI:RestoreToDefault(name)
	C_UI.Reload()
end

local PromptRestoreToDefault = function()
	local Name = YxUI:GetActiveProfileName()
	YxUI:DisplayPopup(Language["Attention"], format(Language['Restore "%s" to default settings and reload the UI?'], Name), ACCEPT, RestoreToDefault, CANCEL, nil, Name)
end

local CopyProfileOnAccept = function(from)
	YxUI:CopyProfile(from, YxUI:GetActiveProfileName())
end

local PromptDelete = function(value)
	YxUI:DisplayPopup(Language["Attention"], format(Language["Are you sure you want to delete %s?"], value), ACCEPT, DeleteProfile, CANCEL, nil, value)
end

local CopyProfile = function(value)
	YxUI:DisplayPopup(Language["Attention"], format(Language["Are you sure you want to copy %s to %s?"], value, YxUI:GetActiveProfileName()), ACCEPT, CopyProfileOnAccept, CANCEL, nil, value)
end

GUI:AddWidgetsID("General", "Profiles", function(left, right)
	left:CreateHeader(Language["Profiles"])
	left:CreateDoubleLine("current-profile", Language["Active Profile:"], YxUI:GetActiveProfileName())
	local ActiveProfile = GUI:GetWidget("current-profile")
	ActiveProfile:EnableMouse(true)
	ActiveProfile:SetScript("OnEnter", ShowActiveProfileTooltip)
	ActiveProfile:SetScript("OnLeave", function() GameTooltip:Hide() end)

	left:CreateHeader(Language["Modify"])
	left:CreateInput("profile-key", YxUI:GetDefaultProfileKey(), Language["Create New Profile"], Language["Create a new profile to store a different collection of settings"], CreateProfile):DisableSaving()
	--left:CreateInput("profile-delete", YxUI:GetDefaultProfileKey(), Language["Delete Profile"], Language["Delete a profile"], DeleteProfile):DisableSaving()
	left:CreateInput("profile-rename", "", Language["Rename Profile"], Language["Rename the currently selected profile"], RenameProfile):DisableSaving()
	left:CreateDropdown("profile-delete", YxUI:GetActiveProfileName(), YxUI:GetProfileList(), Language["Delete Profile"],  Language["Delete a profile"], PromptDelete):DisableSaving()
	left:CreateDropdown("profile-copy", YxUI:GetActiveProfileName(), YxUI:GetProfileList(), Language["Copy From"], Language["Copy the settings from another profile"], CopyProfile)


	left:CreateHeader(Language["Manage"])
	left:CreateButton("", Language["Restore"], Language["Restore to Default"], Language["Restore the currently selected profile to default settings"], PromptRestoreToDefault)
	left:CreateButton("", Language["Delete"], Language["Delete Unused Profiles"], Language["Delete any profiles that are not currently in use by any characters"], PromptDeleteUnused)

	left:CreateHeader(Language["Sharing is caring"])
	left:CreateButton("", Language["Import"], Language["Import A Profile"], Language["Import a profile using an import string"], ShowImportWindow)
	left:CreateButton("", Language["Export"], Language["Export Current Profile"], Language["Export the currently active profile as a string that can be shared with others"], ShowExportWindow)

	right:CreateHeader(Language["What is a profile?"])
	right:CreateMessage("", Language["Profiles store your settings so that you can quickly and easily change between configurations."])
	if SupportsSpecProfiles then
		right:CreateHeader(Language["Specialization Profiles"])
		right:CreateMessage("", Language["Specialization profiles override the character default when assigned."])
	end
	right:CreateDropdown("profile-character-default", YxUI:GetCharacterDefaultProfileName(), YxUI:GetProfileList(), SupportsSpecProfiles and Language["Character Default"] or Language["Select Profile"], SupportsSpecProfiles and Language["Fallback profile for specializations without an override"] or Language["Select a profile to load"], function(value)
		YxUI:SetActiveProfile(value)
		if not YxUI:GetSpecializationProfile(YxUI:GetCurrentSpecializationKey()) then
			YxUI:SwitchProfile(value)
		end
		YxUI:SynchronizeProfileSelectors()
		if GUI:GetWidget("current-profile") then YxUI:UpdateProfileInfo() end
	end):DisableSaving()
	if SupportsSpecProfiles then
		local slots = YxUI:GetSpecializationSlots()
		YxUI.ProfileSpecializationSlotCount = #slots
		for _, spec in ipairs(slots) do
			local key = spec.Key
			right:CreateDropdown("profile-spec-" .. key, YxUI:GetSpecializationProfile(key) or YxUI:GetCharacterDefaultProfileName(), YxUI:GetProfileList(), spec.Name, Language["Profile used for this specialization"], function(value)
				YxUI:SetSpecializationProfile(key, value ~= YxUI:GetCharacterDefaultProfileName() and value or nil)
			end):DisableSaving()
		end
	end
end)
YxUI:GetModule("GUI"):RegisterPageSettingsID("General", "Profiles", {
	{"profile-copy", CopyProfile},
}, nil)

