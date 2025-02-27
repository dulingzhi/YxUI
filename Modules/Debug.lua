local YxUI, Language, Assets, Settings = select(2, ...):get()

local Debug = YxUI:NewModule("Debug")
local GUI = YxUI:GetModule("GUI")

local format = format
local select = select
local GetZoneText = GetZoneText
local GetMinimapZoneText = GetMinimapZoneText
local GetQuests, GetSpecInfo

local GetNumLoadedAddOns = function()
	local NumLoaded = 0

	for i = 1, C_AddOns.GetNumAddOns() do
		if C_AddOns.IsAddOnLoaded(i) then
			NumLoaded = NumLoaded + 1
		end
	end

	return NumLoaded
end

local GetClient = function()
	if IsWindowsClient() then
		return Language["Windows"]
	elseif IsMacClient() then
		return Language["Mac"]
	else -- IsLinuxClient
		return Language["Linux"]
	end
end

local CountMovedFrames = function()
	local Profile = YxUI:GetActiveProfile()

	if (not Profile.Move) then
		return 0
	end

	local Count = 0

	for data in next, Profile.Move do
		Count = Count + 1
	end

	return Count
end

if YxUI.IsMainline then
	GetQuests = function()
		local NumQuests = select(2, C_QuestLog.GetNumQuestLogEntries())
		local MaxQuests = C_QuestLog.GetMaxNumQuestsCanAccept()

		return format("%s / %s", NumQuests, MaxQuests)
	end

	GetSpecInfo = function()
		return select(2, GetSpecializationInfo(GetSpecialization()))
	end
elseif YxUI.IsCata then
	GetQuests = function()
		local NumQuests = select(2, GetNumQuestLogEntries())
		local MaxQuests = C_QuestLog.GetMaxNumQuestsCanAccept()

		return format("%s / %s", NumQuests, MaxQuests)
	end

	GetSpecInfo = function()
		local MainSpec
		local PointsTotal = ""
		local HighestPoints = 0

		for i = 1, 5 do -- Default UI uses 5 here for some reason? Just going to roll with it right now even though it makes no sense to me
			ID, Name, Desc, Icon, PointsSpent = GetTalentTabInfo(i)

			if Name then
				if (PointsSpent > HighestPoints) then
					MainSpec = Name
					HighestPoints = PointsSpent
				end

				PointsTotal = PointsTotal == "" and PointsSpent or PointsTotal .. "/" .. PointsSpent
			end
		end

		return MainSpec and format("%s (%s)", MainSpec, PointsTotal) or NOT_APPLICABLE
	end
else
	GetQuests = function()
		local NumQuests = select(2, GetNumQuestLogEntries())
		local MaxQuests = C_QuestLog.GetMaxNumQuestsCanAccept()

		return format("%s / %s", NumQuests, MaxQuests)
	end

	GetSpecInfo = function()
		local MainSpec
		local PointsTotal = ""
		local HighestPoints = 0

		for i = 1, 5 do -- Default UI uses 5 here for some reason? Just going to roll with it right now even though it makes no sense to me
			Name, Texture, PointsSpent = GetTalentTabInfo(i)

			if Name then
				if (PointsSpent > HighestPoints) then
					MainSpec = Name
					HighestPoints = PointsSpent
				end

				PointsTotal = PointsTotal == "" and PointsSpent or PointsTotal .. "/" .. PointsSpent
			end
		end

		return MainSpec and format("%s (%s)", MainSpec, PointsTotal) or NOT_APPLICABLE
	end
end

local UpdateZoneInfo = function()
	local ZoneText = GetZoneText()
	local SubZoneText = GetMinimapZoneText()

	GUI:GetWidget("dbg-zone").Right:SetText(ZoneText)
	GUI:GetWidget("dbg-subzone").Right:SetText(SubZoneText)
end

local OnShow = function()
	Debug:RegisterEvent("ZONE_CHANGED")
	Debug:RegisterEvent("ZONE_CHANGED_INDOORS")
	Debug:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	Debug:RegisterEvent("DISPLAY_SIZE_CHANGED")
	Debug:RegisterEvent("UI_SCALE_CHANGED")
	Debug:RegisterEvent("QUEST_LOG_UPDATE")
	Debug:RegisterEvent("CVAR_UPDATE")
	Debug:RegisterEvent("CHARACTER_POINTS_CHANGED")

	if (UnitLevel("player") > 59) then
		Debug:RegisterEvent("PLAYER_LEVEL_UP")
	end

	Debug:SetScript("OnEvent", Debug.OnEvent)
end

local OnHide = function()
	Debug:UnregisterAllEvents()
end

GUI:AddWidgets(Language["Info"], Language["Debug"], function(left, right)
	left:HookScript("OnShow", OnShow)
	left:HookScript("OnHide", OnHide)

	local Version, _, _, Build = GetBuildInfo()
	local ScreenWidth, ScreenHeight = GetPhysicalScreenSize()

	left:CreateHeader(Language["UI Information"])
	left:CreateDoubleLine("dbg-ui-version", Language["UI Version"], YxUI.UIVersion)
	left:CreateDoubleLine("dbg-game-version", Language["Game Version"], format("%s (%s)", Version, Build))
	left:CreateDoubleLine("dbg-client", Language["Client"], GetClient())
	left:CreateDoubleLine("dbg-ui-scale", Language["UI Scale"], C_CVar.GetCVar("uiScale"))
	left:CreateDoubleLine("dbg-suggested-scale", Language["Suggested Scale"], (768 / ScreenHeight))
	left:CreateDoubleLine("dbg-reso", Language["Resolution"], format("%sx%s", ScreenWidth, ScreenHeight))
	left:CreateDoubleLine("dbg-screen-size", Language["Screen Size"], format("%sx%s", GetPhysicalScreenSize()))
	left:CreateDoubleLine("dbg-fullscreen", Language["Fullscreen"], GetCVar("gxMaximize") == "1" and Language["Enabled"] or Language["Disabled"])
	left:CreateDoubleLine("dbg-profile", Language["Profile"], YxUI:GetActiveProfileName())
	left:CreateDoubleLine("dbg-profile-count", Language["Profile Count"], YxUI:GetProfileCount())
	left:CreateDoubleLine("dbg-moved-frames", Language["Moved Frames"], CountMovedFrames())
	left:CreateDoubleLine("dbg-locale", Language["Locale"], YxUI.UserLocale)
	left:CreateDoubleLine("dbg-show-errors", Language["Display Errors"], GetCVar("scriptErrors") == "1" and Language["Enabled"] or Language["Disabled"])

	right:CreateHeader(Language["User Information"])
	right:CreateDoubleLine("dbg-level", Language["Level"], UnitLevel("player"))
	right:CreateDoubleLine("dbg-race", Language["Race"], YxUI.UserRace)
	right:CreateDoubleLine("dbg-class", Language["Class"], UnitClass("player"))
	right:CreateDoubleLine("dbg-spec", Language["Spec"], GetSpecInfo())
	right:CreateDoubleLine("dbg-realm", Language["Realm"], YxUI.UserRealm)
	right:CreateDoubleLine("dbg-zone", Language["Zone"], GetZoneText())
	right:CreateDoubleLine("dbg-subzone", Language["Sub Zone"], GetMinimapZoneText())
	right:CreateDoubleLine("dbg-quests", Language["Quests"], GetQuests())
	right:CreateDoubleLine("dbg-trial", Language["Trial Account"], IsTrialAccount() and YES or NO)

	right:CreateHeader(Language["AddOns Information"])
	right:CreateDoubleLine("dbg-total-addons", Language["Total AddOns"], C_AddOns.GetNumAddOns())
	right:CreateDoubleLine("dbg-loaded-addons", Language["Loaded AddOns"], GetNumLoadedAddOns())
	right:CreateDoubleLine("dbg-loaded-plugins", Language["Loaded Plugins"], #YxUI.Plugins)
end)

function Debug:DISPLAY_SIZE_CHANGED()
	GUI:GetWidget("dbg-suggested-scale").Right:SetText((768 / select(2, GetPhysicalScreenSize())))
	GUI:GetWidget("dbg-reso").Right:SetText(YxUI.ScreenResolution)
	GUI:GetWidget("dbg-fullscreen").Right:SetText(GetCVar("gxMaximize") == "1" and Language["Enabled"] or Language["Disabled"])
end

function Debug:UI_SCALE_CHANGED()
	GUI:GetWidget("dbg-suggested-scale").Right:SetText((768 / select(2, GetPhysicalScreenSize())))
end

function Debug:PLAYER_LEVEL_UP()
	GUI:GetWidget("dbg-level").Right:SetText(UnitLevel("player"))
end

function Debug:QUEST_LOG_UPDATE()
	GUI:GetWidget("dbg-quests").Right:SetText(GetQuests())
end

function Debug:ADDON_LOADED()
    local get = GetLoadedAddOns or GetNumLoadedAddOns
	GUI:GetWidget("dbg-loaded-addons").Right:SetText(get())
end

function Debug:CVAR_UPDATE(cvar)
	if (cvar == "scriptErrors") then
		GUI:GetWidget("dbg-show-errors").Right:SetText(GetCVar("scriptErrors") == "1" and Language["Enabled"] or Language["Disabled"])
	end
end

function Debug:CHARACTER_POINTS_CHANGED()
	GUI:GetWidget("dbg-spec").Right:SetText(GetSpecInfo())
end

Debug.ZONE_CHANGED = UpdateZoneInfo
Debug.ZONE_CHANGED_INDOORS = UpdateZoneInfo
Debug.ZONE_CHANGED_NEW_AREA = UpdateZoneInfo

function Debug:OnEvent(event)
	if self[event] then
		self[event](self)
	end
end