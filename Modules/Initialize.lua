local AddOn, Namespace = ... -- YxUI was created on May 22, 2019

-- Data storage
local Assets = {}
local Settings = {}
local Defaults = {}
local Modules = {}
local Plugins = {}
local ModuleQueue = {}
local PluginQueue = {}

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
YxUI.UserLocale = GetLocale()
YxUI.UserProfileKey = format("%s:%s", YxUI.UserName, YxUI.UserRealm)
YxUI.ClientVersion = select(4, GetBuildInfo())
YxUI.IsClassic = YxUI.ClientVersion > 10000 and YxUI.ClientVersion < 20000
YxUI.IsTBC = YxUI.ClientVersion > 20000 and YxUI.ClientVersion < 30000
YxUI.IsWrath = YxUI.ClientVersion > 30000 and YxUI.ClientVersion < 40000
YxUI.IsCata = YxUI.ClientVersion > 40000 and YxUI.ClientVersion < 50000
YxUI.IsMainline = YxUI.ClientVersion > 90000

if (YxUI.UserLocale == "enGB") then
	YxUI.UserLocale = "enUS"
end

-- Language
local Language = {}

local Index = function(self, key)
	return key
end

Language.Raw = {}
local NewIndex = function (self, key, value)
	rawset(self, key, value)
	Language.Raw[value] = key
end

setmetatable(Language, {__index = Index, __newindex = NewIndex})

-- Modules and plugins
function YxUI:NewModule(name)
	local Module = self:GetModule(name)

	if Module then
		return Module
	end

	Module = CreateFrame("Frame", "YxUI " .. name, self.UIParent, "BackdropTemplate")
	Module.Name = name

	Modules[name] = Module
	ModuleQueue[#ModuleQueue + 1] = Module

	return Module
end

function YxUI:GetModule(name)
	if Modules[name] then
		return Modules[name]
	end
end

function YxUI:LoadModules()
	for i = 1, #ModuleQueue do
		if (ModuleQueue[i].Load and not ModuleQueue[i].Loaded) then
			ModuleQueue[i]:Load()
			ModuleQueue[i].Loaded = true
		end
	end

	-- Wipe the queue
end

function YxUI:NewPlugin(name)
	local Plugin = self:GetPlugin(name)

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
	if Plugins[name] then
		return Plugins[name]
	end
end

function YxUI:LoadPlugins()
	if (#PluginQueue == 0) then
		return
	end

	for i = 1, #PluginQueue do
		if PluginQueue[i].Load then
			PluginQueue[i]:Load()
		end
	end

	self:GetModule("GUI"):AddWidgets(Language["Info"], Language["Plugins"], function(left, right)
		local Anchor

		for i = 1, #PluginQueue do
			if ((i % 2) == 0) then
				Anchor = right
			else
				Anchor = left
			end

			Anchor:CreateHeader(PluginQueue[i].Title)
			Anchor:CreateDoubleLine("", Language["Author"], PluginQueue[i].Author)
			Anchor:CreateDoubleLine("", Language["Version"], PluginQueue[i].Version)
			Anchor:CreateMessage("", PluginQueue[i].Notes)
		end
	end)
end

-- Events
function YxUI:OnEvent(event)
	-- Import profile data and load a profile
	self:CreateProfileData()
	self:UpdateProfileList()
	self:ApplyProfile(self:GetActiveProfileName())

	self:UpdateColors()
	self:UpdateoUFColors()

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