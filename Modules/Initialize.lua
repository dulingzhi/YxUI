local AddOn, Namespace = ... -- YxUI was created on May 22, 2019

-- Data storage
local Assets = {}
local Settings = {}
local Defaults = {}
local Modules = {}
local Plugins = {}
local ModuleQueue = {}
local PluginQueue = {}
local ModuleQueueIndex = 0

-- Core functions and data
local YxUI = CreateFrame("Frame", nil, UIParent)
YxUI.Modules = Modules
YxUI.Plugins = Plugins

YxUI.UIParent = CreateFrame("Frame", "YxUIParent", UIParent, "SecureHandlerStateTemplate")
YxUI.UIParent:SetAllPoints(UIParent)
YxUI.UIParent:SetFrameLevel(UIParent:GetFrameLevel())

-- Constants
local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
local GetAddOnInfo = C_AddOns and C_AddOns.GetAddOnInfo or GetAddOnInfo

YxUI.UIVersion = GetAddOnMetadata("YxUI", "Version")
YxUI.UserName = UnitName("player")
YxUI.UserClass = select(2, UnitClass("player"))
YxUI.UserRace = UnitRace("player")
YxUI.UserRealm = GetRealmName()
YxUI.ClientLocale = GetLocale()
YxUI.UserProfileKey = format("%s:%s", YxUI.UserName, YxUI.UserRealm)
YxUI.ClientVersion = select(4, GetBuildInfo())

local IsMainlineProject = (WOW_PROJECT_ID and WOW_PROJECT_MAINLINE and WOW_PROJECT_ID == WOW_PROJECT_MAINLINE) or false

YxUI.IsForever = (WOW_PROJECT_CAMELOT and WOW_PROJECT_ID == WOW_PROJECT_CAMELOT) or (YxUI.ClientVersion >= 16000 and YxUI.ClientVersion < 17000)
YxUI.IsMidnight = IsMainlineProject and YxUI.ClientVersion >= 120000 and YxUI.ClientVersion < 130000
YxUI.IsVanilla = (not YxUI.IsForever) and YxUI.ClientVersion > 10000 and YxUI.ClientVersion < 20000
YxUI.IsTBC = YxUI.ClientVersion > 20000 and YxUI.ClientVersion < 30000
YxUI.IsWrath = YxUI.ClientVersion > 30000 and YxUI.ClientVersion < 40000
YxUI.IsCata = YxUI.ClientVersion > 40000 and YxUI.ClientVersion < 50000
YxUI.IsMists = YxUI.ClientVersion > 50000 and YxUI.ClientVersion < 60000
YxUI.IsMainline = IsMainlineProject or YxUI.IsForever

if YxUI.ClientLocale == "enGB" then
	YxUI.ClientLocale = "enUS"
end

-- Language
local Language = {}

local Index = function(self, key)
	return key
end

setmetatable(Language, {__index = Index})

YxUI.Languages = {
	["enUS"] = "English",
	["deDE"] = "Deutsch",
	["esES"] = "Espa\195\177ol (Espa\195\177a)",
	["esMX"] = "Espa\195\177ol (Latinoam\195\169rica)",
	["frFR"] = "Fran\195\167ais",
	["itIT"] = "Italiano",
	["koKR"] = "\237\149\156\234\181\173\236\150\180",
	["ptBR"] = "Portugu\195\170s (Brasil)",
	["ruRU"] = "\208\160\209\131\209\129\209\129\208\186\208\184\208\185",
	["zhCN"] = "\231\174\128\228\189\147\228\184\173\230\150\135",
	["zhTW"] = "\231\185\129\233\171\148\228\184\173\230\150\135",
}

YxUI.UserLocale = YxUI.ClientLocale

-- Language is a character preference, independent of specialization profiles.
local LanguageOverrides = type(YxUIData) == "table" and YxUIData.LanguageOverrides
local PreferredLocale = type(LanguageOverrides) == "table" and LanguageOverrides[YxUI.UserProfileKey]

if not YxUI.Languages[PreferredLocale] and type(YxUIProfileData) == "table" and type(YxUIProfiles) == "table" then
	local ProfileName = YxUIProfileData[YxUI.UserProfileKey]
	local Profile = ProfileName and YxUIProfiles[ProfileName]
	PreferredLocale = Profile and Profile["ui-language"]
end

if YxUI.Languages[PreferredLocale] then
	YxUI.UserLocale = PreferredLocale
end

function YxUI:GetLanguageList()
	local Languages = {}

	for Locale, Name in pairs(self.Languages) do
		Languages[Name] = Locale
	end

	return Languages
end

-- Modules and plugins
function YxUI:NewModule(name)
	local Module = Modules[name]

	--print("NewModule:", name)

	if Module then
		return Module
	end

	Module = CreateFrame("Frame", "YxUI " .. name, self.UIParent, "BackdropTemplate")
	Module.Name = name

	Modules[name] = Module

	ModuleQueueIndex = ModuleQueueIndex + 1
	ModuleQueue[ModuleQueueIndex] = Module

	return Module
end

function YxUI:GetModule(name)
	return Modules[name]
end

function YxUI:LoadModules()
	for i = 1, #ModuleQueue do
		local Module = ModuleQueue[i]

		if Module.Load and not Module.Loaded then
			Module:Load()
			Module.Loaded = true
		end
	end
end

function YxUI:NewPlugin(name)
	local Plugin = Plugins[name]

	if Plugin then
		return
	end

	local Name, Title, Notes = GetAddOnInfo(name)
	local Author = GetAddOnMetadata(name, "Author")
	local Version = GetAddOnMetadata(name, "Version")

	Plugin = CreateFrame("Frame", name, self.UIParent, "BackdropTemplate")
	Plugin.Name = Name
	Plugin.Title = Title
	Plugin.Notes = Notes
	Plugin.Author = Author
	Plugin.Version = Version

	Plugins[name] = Plugin
	PluginQueue[#PluginQueue + 1] = Plugin

	return Plugin
end

function YxUI:GetPlugin(name)
	return Plugins[name]
end

function YxUI:LoadPlugins()
	if #PluginQueue == 0 then
		return
	end

	for i = 1, #PluginQueue do
		local Plugin = PluginQueue[i]

		if Plugin.Load then
			Plugin:Load()
		end
	end

	self:GetModule("GUI"):AddWidgetsID("Info", "Plugins", function(left, right)
		local Anchor

		for i = 1, #PluginQueue do
			local Plugin = PluginQueue[i]

			if (i % 2) == 0 then
				Anchor = right
			else
				Anchor = left
			end

			Anchor:CreateHeader(Plugin.Title)
			Anchor:CreateDoubleLine("", Language["Author"], Plugin.Author)
			Anchor:CreateDoubleLine("", Language["Version"], Plugin.Version)
			Anchor:CreateMessage("", Plugin.Notes)
		end
	end)
end

-- Events
function YxUI:OnEvent(event)
	--[[if (YxUI.ClientVersion >= 20000) then
		print(Language["YxUI is not supported for this version of World of Warcraft"])

		return
	end]]

	-- Import profile data and load a profile
	self:CreateProfileData()
	self:UpdateProfileList()
	self:ApplyProfile(self:ResolveProfileForSpecialization())

	self:UpdateColors()
	self:UpdateUnitFrameColors()

	self:WelcomeMessage()

	self:LoadSharedAssets()

	self:LoadModules()
	self:LoadPlugins()

	self:UnregisterEvent(event)
end

YxUI:RegisterEvent("PLAYER_ENTERING_WORLD")
YxUI:SetScript("OnEvent", YxUI.OnEvent)

-- Access data tables
function Namespace:get()
	return YxUI, Language, Assets, Settings, Defaults
end

-- Global access
_G.YxUIGlobal = Namespace
