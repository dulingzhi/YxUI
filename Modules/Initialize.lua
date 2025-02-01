---@class YxUIGlobal
local Namespace = select(2, ...)

-- Data storage
---@class Assets
local Assets = {}
---@class Settings
local Settings = {}
---@class Defaults
local Defaults = {}
local Modules = {}
local Plugins = {}
local ModuleQueue = {}
local PluginQueue = {}

-- Core functions and data
---@class YxUI
local Y = CreateFrame("Frame", nil, UIParent)
Y.Modules = Modules
Y.Plugins = Plugins

Y.UIParent = CreateFrame("Frame", "YxUIParent", UIParent, "SecureHandlerStateTemplate")
Y.UIParent:SetAllPoints(UIParent)
Y.UIParent:SetFrameLevel(UIParent:GetFrameLevel())

-- Constants
local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
local GetAddOnInfo = C_AddOns and C_AddOns.GetAddOnInfo or GetAddOnInfo

Y.UIVersion = GetAddOnMetadata("YxUI", "Version")
Y.UserName = UnitName("player")
Y.UserClass = select(2, UnitClass("player"))
Y.UserRace = UnitRace("player")
Y.UserRealm = GetRealmName()
Y.UserLocale = GetLocale()
Y.UserProfileKey = format("%s:%s", Y.UserName, Y.UserRealm)
Y.UserColor = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[Y.UserClass]
Y.ClientVersion = select(4, GetBuildInfo())
Y.IsClassic = Y.ClientVersion > 10000 and Y.ClientVersion < 20000
Y.IsTBC = Y.ClientVersion > 20000 and Y.ClientVersion < 30000
Y.IsWrath = Y.ClientVersion > 30000 and Y.ClientVersion < 40000
Y.IsCata = Y.ClientVersion > 40000 and Y.ClientVersion < 50000
Y.IsMainline = Y.ClientVersion > 90000
Y.Dummy = function() end

Y.ScreenWidth, Y.ScreenHeight = GetPhysicalScreenSize()
Y.HiDPI = GetScreenHeight() / Y.ScreenHeight < 0.75
Y.UiScale = tonumber(C_CVar.GetCVar("uiScale"))
Y.Mult = 768 / Y.ScreenHeight / Y.UiScale
Y.NoScaleMult = Y.Mult * Y.UiScale
if Y.HiDPI then
    Y.NoScaleMult = Y.NoScaleMult * 2
end
function Y.Scale(x)
    return Y.Mult * math.floor(x / Y.Mult + 0.5)
end

Y.TexCoords = { 0.08, 0.92, 0.08, 0.92 }

if (Y.UserLocale == "enGB") then
    Y.UserLocale = "enUS"
end

-- Lists
Y.ClassList = {}
Y.ClassColors = {}
Y.QualityColors = {}

-- Populate the ClassList table with localized class names
for k, v in pairs(LOCALIZED_CLASS_NAMES_MALE) do
    Y.ClassList[v] = k
end

for k, v in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do
    Y.ClassList[v] = k
end

-- Populate the ClassColors table with the colors of each class
local colors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
for class, value in pairs(colors) do
    Y.ClassColors[class] = {}
    Y.ClassColors[class].r = value.r
    Y.ClassColors[class].g = value.g
    Y.ClassColors[class].b = value.b
    Y.ClassColors[class].colorStr = value.colorStr
end

-- Get the player's class color
Y.r, Y.g, Y.b = Y.ClassColors[Y.UserClass].r, Y.ClassColors[Y.UserClass].g, Y.ClassColors[Y.UserClass].b
Y.MyClassColor = string.format("|cff%02x%02x%02x", Y.r * 255, Y.g * 255, Y.b * 255)

-- Populate the QualityColors table with the colors of each item quality
local qualityColors = BAG_ITEM_QUALITY_COLORS
for index, value in pairs(qualityColors) do
    Y.QualityColors[index] = { r = value.r, g = value.g, b = value.b }
end
Y.QualityColors[-1] = { r = 1, g = 1, b = 1 }
Y.QualityColors[LE_ITEM_QUALITY_POOR or Enum.ItemQuality.Poor] = { r = 0.61, g = 0.61, b = 0.61 }
Y.QualityColors[LE_ITEM_QUALITY_COMMON or Enum.ItemQuality.Common] = { r = 1, g = 1, b = 1 } -- This is the default color, but it's included here for completeness.

-- Language
---@class Language
local L = {}

local Index = function(self, key)
    return key
end

L.Raw = {}
local NewIndex = function(self, key, value)
    rawset(self, key, value)
    L.Raw[value] = key
end

setmetatable(L, { __index = Index, __newindex = NewIndex })

-- Modules and plugins
function Y:NewModule(name)
    local Module = self:GetModule(name)

    if Module then
        return Module
    end

    Module = CreateFrame("Frame", "YxUI " .. name, self.UIParent, "BackdropTemplate")
    Module.Name = name

    Modules[name] = Module
    ModuleQueue[#ModuleQueue + 1] = Module
    self[name] = Module
    Module.events = {}
    Module.Event = function(self, event, func, unit1, unit2)
        if event == "CLEU" then
            event = "COMBAT_LOG_EVENT_UNFILTERED"
        end
        -- Check if the event is already registered with the function
        if self.events[event] and self.events[event][func] then
            return
        end
        if not self.events[event] then
            self.events[event] = {}
            if unit1 then
                self:RegisterUnitEvent(event, unit1, unit2)
            else
                self:RegisterEvent(event)
            end
        end
        self.events[event][func] = true
    end
    Module.UnEvent = function(self, event, func)
        if event == "CLEU" then
            event = "COMBAT_LOG_EVENT_UNFILTERED"
        end

        local funcs = self.events[event]
        if funcs and funcs[func] then
            funcs[func] = nil

            if not next(funcs) then
                self.events[event] = nil
                self:UnregisterEvent(event)
            end
        end
    end
    Module:SetScript('OnEvent', function(self, event, ...)
        local eventFuncs = self.events[event]
        if eventFuncs then
            for func in pairs(eventFuncs) do
                local success, err
                if event == "COMBAT_LOG_EVENT_UNFILTERED" then
                    success, err = pcall(func, self, event, CombatLogGetCurrentEventInfo())
                else
                    success, err = pcall(func, self, event, ...)
                end
                if not success then
                    print("Error in event handler for event:", event, "-", err)
                end
            end
        end
    end)

    return Module
end

function Y:GetModule(name)
    if Modules[name] then
        return Modules[name]
    end
end

function Y:LoadModules()
    for i = 1, #ModuleQueue do
        if (ModuleQueue[i].Load and not ModuleQueue[i].Loaded) then
            ModuleQueue[i]:Load()
            ModuleQueue[i].Loaded = true
        end
    end

    -- Wipe the queue
end

function Y:NewPlugin(name)
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

function Y:GetPlugin(name)
    if Plugins[name] then
        return Plugins[name]
    end
end

function Y:LoadPlugins()
    if (#PluginQueue == 0) then
        return
    end

    for i = 1, #PluginQueue do
        if PluginQueue[i].Load then
            PluginQueue[i]:Load()
        end
    end

    self:GetModule("GUI"):AddWidgets(L["Info"], L["Plugins"], function(left, right)
        local Anchor

        for i = 1, #PluginQueue do
            if ((i % 2) == 0) then
                Anchor = right
            else
                Anchor = left
            end

            Anchor:CreateHeader(PluginQueue[i].Title)
            Anchor:CreateDoubleLine("", L["Author"], PluginQueue[i].Author)
            Anchor:CreateDoubleLine("", L["Version"], PluginQueue[i].Version)
            Anchor:CreateMessage("", PluginQueue[i].Notes)
        end
    end)
end

-- Events
function Y:OnEvent(event)
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

    -- Set the UI scale
    if Settings["enable-scale"] and Settings["ui-scale"] and Settings["ui-scale"] ~= Y.UiScale then
        C_CVar.SetCVar("uiScale", Settings["ui-scale"])
        Y.UiScale = Settings["ui-scale"]
    end

    self:UnregisterEvent(event)
end

Y:RegisterEvent("PLAYER_ENTERING_WORLD")
Y:SetScript("OnEvent", Y.OnEvent)

-- Access data tables
function Namespace:get()
    return Y, L, Assets, Settings, Defaults
end

-- Global access
_G.YxUIGlobal = Namespace
