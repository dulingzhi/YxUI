local addon, ns = ...
local YxUI, Language, Assets, Settings, Defaults = ns:get()

local find = string.find

Defaults["unitframes-only-player-debuffs"] = false
Defaults["unitframes-show-player-buffs"] = true
Defaults["unitframes-show-player-debuffs"] = true
Defaults["unitframes-show-target-buffs"] = true
Defaults["unitframes-show-target-debuffs"] = true
Defaults["unitframes-show-druid-mana"] = true
Defaults["unitframes-font"] = "Roboto"
Defaults["unitframes-font-size"] = 12
Defaults["unitframes-font-flags"] = ""
Defaults["unitframes-display-aura-timers"] = true

local UF = YxUI:GetModule("Unit Frames")

local function ForEachChild(operation, value, descriptor, child, ...)
	if not child then
		return
	end

	operation(child, value, descriptor)

	return ForEachChild(operation, value, descriptor, ...)
end

-- Secure group headers return their children as multiple values. Pass those values through the iterator so each invocation uses the header's current children without allocating a temporary table.
function UF:ForEachHeaderChild(header, operation, value, descriptor)
	if not header then
		return
	end

	ForEachChild(operation, value, descriptor, header:GetChildren())
end

YxUI.UnitFrames = YxUI.UnitFrames or {}
YxUI.StyleFuncs = {}

function UF:GetRoleTexCoords(role)
	if role == "TANK" then
		return 0, 19/64, 22/64, 41/64
	elseif role == "HEALER" then
		return 20/64, 39/64, 1/64, 20/64
	elseif role == "DAMAGER" then
		return 20/64, 39/64, 22/64, 41/64
	end
end

if CompactRaidFrameManager then
	CompactRaidFrameManager:SetParent(UIParent)
end

local Style = function(self, unit)
	local StyleFunc = YxUI.StyleFuncs[unit]

	if (not StyleFunc) and find(unit, "raidpet") and Settings["raid-pets-enable"] then
		StyleFunc = YxUI.StyleFuncs["raidpet"]
	elseif (not StyleFunc) and find(unit, "raid") and Settings["raid-enable"] then
		StyleFunc = YxUI.StyleFuncs["raid"]
	elseif (not StyleFunc) and find(unit, "partypet") and Settings["party-enable"] and Settings["party-pets-enable"] then
		StyleFunc = YxUI.StyleFuncs["partypet"]
	elseif (not StyleFunc) and find(unit, "party") and not find(unit, "pet") and Settings["party-enable"] then
		StyleFunc = YxUI.StyleFuncs["party"]
	elseif (not StyleFunc) and find(unit, "nameplate") and Settings["nameplates-enable"] then
		StyleFunc = YxUI.StyleFuncs["nameplate"]
	elseif (not StyleFunc) and find(unit, "boss%d") then
		StyleFunc = YxUI.StyleFuncs["boss"]
	end

	if StyleFunc then
		StyleFunc(self, unit)
	end
end

UF.Style = Style

function UF:Load()
	if YxUI.IsForever and C_AddOns and C_AddOns.LoadAddOn then
		C_AddOns.LoadAddOn("Blizzard_AuraContainer")
	end

	self:SpawnSingletonFrames()
	self:SpawnBossFrames()
	self:SpawnPartyHeaders()
	self:SpawnRaidHeaders()
	self:SpawnNameplates()
end

YxUI:GetModule("GUI"):AddWidgetsID("General", "Unit Frames", function(left, right)
	left:CreateHeader(Language["Font"])
	left:CreateDropdown("unitframes-font", Settings["unitframes-font"], Assets:GetFontList(), Language["Font"], Language["Set the font of the unit frames"], function() UF:UpdateUnitFonts() end, "Font")
	left:CreateSlider("unitframes-font-size", Settings["unitframes-font-size"], 8, 32, 1, Language["Font Size"], Language["Set the font size of the unit frames"], function() UF:UpdateUnitFonts() end)
	left:CreateDropdown("unitframes-font-flags", Settings["unitframes-font-flags"], Assets:GetFlagsList(), Language["Font Flags"], Language["Set the font flags of the unit frames"], function() UF:UpdateUnitFonts() end)

	right:CreateHeader(Language["Auras"])
	right:CreateSwitch("unitframes-display-aura-timers", Settings["unitframes-display-aura-timers"], Language["Display Aura Timers"], Language["Display the timer on unit frame auras"], function(value) UF:SetAuraTimersEnabled(value) end)
end)
YxUI:GetModule("GUI"):RegisterPageSettingsID("General", "Unit Frames", {
	{"unitframes-font", function() UF:UpdateUnitFonts() end},
	{"unitframes-font-size", function() UF:UpdateUnitFonts() end},
	{"unitframes-font-flags", function() UF:UpdateUnitFonts() end},
	{"unitframes-display-aura-timers", function(value) UF:SetAuraTimersEnabled(value) end},
}, nil)

