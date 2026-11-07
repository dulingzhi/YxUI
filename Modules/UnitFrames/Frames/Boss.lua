local YxUI, Language, Assets, Settings, Defaults = select(2, ...):get()

Defaults["unitframes-boss-enable"] = true
Defaults["unitframes-boss-width"] = 240
Defaults["unitframes-boss-health-height"] = 28
Defaults["unitframes-boss-health-reverse"] = false
Defaults["unitframes-boss-health-color"] = "CLASS"
Defaults["unitframes-boss-health-smooth"] = true
Defaults["unitframes-boss-health-left"] = "[LevelColor][Level][Plus]|r [Name(30)]"
Defaults["unitframes-boss-health-right"] = "[HealthPercent]"
Defaults["unitframes-boss-power-height"] = 16
Defaults["unitframes-boss-power-reverse"] = false
Defaults["unitframes-boss-power-color"] = "POWER"
Defaults["unitframes-boss-power-smooth"] = true
Defaults["unitframes-boss-power-left"] = "[HealthValues:Short]"
Defaults["unitframes-boss-power-right"] = "[PowerValues:Short]"
Defaults["unitframes-boss-buffs"] = true
Defaults["unitframes-boss-enable-castbar"] = true
Defaults["unitframes-boss-cast-width"] = 212
Defaults["unitframes-boss-cast-height"] = 22
Defaults["unitframes-boss-debuffs"] = true
Defaults["unitframes-boss-buff-size"] = 47
Defaults["unitframes-boss-debuff-size"] = 47
Defaults.BossHealthTexture = "YxUI 4"
Defaults.BossPowerTexture = "YxUI 4"

local UF = YxUI:GetModule("Unit Frames")

local function BuildBossComponents(factory, frame, unit)
	-- Auras
	local Buffs = factory:CreateAuraContainer(frame, frame:GetName() .. "Buffs", nil, Settings["unitframes-boss-width"], Settings["unitframes-boss-buff-size"],
		"RIGHT", frame, "LEFT", -2, 0, Settings["unitframes-boss-buff-size"], 2, 3,
		"TOPRIGHT", "ANCHOR_TOP", "LEFT", "UP", factory.PostCreateIcon, factory.PostUpdateIcon, nil, nil, nil)
	local Debuffs = factory:CreateAuraContainer(frame, frame:GetName() .. "Debuffs", nil, Settings["unitframes-boss-width"], Settings["unitframes-boss-debuff-size"],
		"LEFT", frame, "RIGHT", 2, 0, Settings["unitframes-boss-debuff-size"], 2, 4,
		"TOPLEFT", "ANCHOR_TOP", "RIGHT", "UP", factory.PostCreateIcon, factory.PostUpdateIcon, nil, Settings["unitframes-only-player-debuffs"], nil)
	if Settings["unitframes-boss-enable-castbar"] then
		factory:CreateCastbar(frame, frame:GetName() .. " Casting Bar",
		Settings["unitframes-boss-cast-width"], Settings["unitframes-boss-cast-height"],
		"TOPRIGHT", frame, "BOTTOMRIGHT", -1, -3, Settings["ui-widget-texture"], "Blank",
		-Settings["unitframes-boss-cast-height"] - 2, 1, 1, -1,
		Settings["unitframes-font"], Settings["unitframes-font-size"], Settings["unitframes-font-flags"],
		-5, 5, Settings["unitframes-boss-cast-width"] * 0.7,
		Settings["unitframes-boss-cast-height"], -4, true, nil, true, 0.3, nil,
			factory.PostCastStart, factory.PostCastStop, factory.PostCastFail, factory.PostCastInterruptible)
	end

	frame.Buffs = Buffs
	frame.Debuffs = Debuffs
end

local SingleUnitRange = {insideAlpha = 1, outsideAlpha = 0.5}
local BossFrameConfig = {
	settingsPrefix = "unitframes-boss",
	threat = false,
	powerReverse = false,
	healthTextureKey = "BossHealthTexture",
	powerTextureKey = "BossPowerTexture",
	powerTags = true,
	colorTapping = true,
	colorDisconnected = true,
	powerReaction = true,
	raidTarget = true,
	auras = BuildBossComponents,
	range = SingleUnitRange,
}

YxUI.StyleFuncs["boss"] = function(self, unit)
	UF:BuildSingleUnitFrame(self, unit, BossFrameConfig)
end

local BossUpdaterOptions = {count = 8}
local UpdateWidth = UF:CreateUnitUpdater("boss", "Width", BossUpdaterOptions)
local UpdateHealthHeight = UF:CreateUnitUpdater("boss", "HealthHeight", {count = 8, powerHeight = "unitframes-boss-power-height"})
local UpdatePowerHeight = UF:CreateUnitUpdater("boss", "PowerHeight", {count = 8, healthHeight = "unitframes-boss-health-height"})
local UpdateHealthColor = UF:CreateUnitUpdater("boss", "HealthColor", BossUpdaterOptions)
local UpdateHealthFill = UF:CreateUnitUpdater("boss", "HealthReverse", BossUpdaterOptions)
local UpdatePowerColor = UF:CreateUnitUpdater("boss", "PowerColor", BossUpdaterOptions)
local UpdatePowerFill = UF:CreateUnitUpdater("boss", "PowerReverse", BossUpdaterOptions)
local function UpdateBossAuras()
	local buffs = Settings["unitframes-boss-buffs"]
	local debuffs = Settings["unitframes-boss-debuffs"]
	for i = 1, 8 do
		local frame = YxUI.UnitFrames["boss" .. i]
		if frame then
			if buffs or debuffs then
				frame:EnableElement("Auras")
				frame.Buffs:SetShown(buffs)
				frame.Debuffs:SetShown(debuffs)
			else
				frame:DisableElement("Auras")
			end
		end
	end
end

local function UpdateBossCastSize()
	for i = 1, 8 do
		local frame = YxUI.UnitFrames["boss" .. i]
		if frame and frame.Castbar then
			local bar = frame.Castbar
			bar:SetSize(Settings["unitframes-boss-cast-width"], Settings["unitframes-boss-cast-height"])
			bar.Icon:SetSize(Settings["unitframes-boss-cast-height"], Settings["unitframes-boss-cast-height"])
			bar.Text:SetWidth(Settings["unitframes-boss-cast-width"] * 0.7)
		end
	end
end
local UpdateBuffSize = UF:CreateUnitUpdater("boss", "AuraSize", {count = 8, element = "Buffs", width = "unitframes-boss-width"})
local UpdateDebuffSize = UF:CreateUnitUpdater("boss", "AuraSize", {count = 8, element = "Debuffs", width = "unitframes-boss-width"})
local UpdateHealthTexture = UF:CreateUnitUpdater("boss", "HealthTexture", BossUpdaterOptions)
local UpdatePowerTexture = UF:CreateUnitUpdater("boss", "PowerTexture", BossUpdaterOptions)

local UpdateHealthSmooth = UF:CreateUnitUpdater("boss", "HealthSmooth", {count = 8})
local UpdatePowerSmooth = UF:CreateUnitUpdater("boss", "PowerSmooth", {count = 8})

YxUI:GetModule("GUI"):AddWidgetsID("General", "Bosses", "Unit Frames", function(left, right)
	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("unitframes-boss-enable", Settings["unitframes-boss-enable"], Language["Enable Boss Frames"], Language["Enable the boss unit frames"], ReloadUI):RequiresReload(true)
	left:CreateSlider("unitframes-boss-width", Settings["unitframes-boss-width"], 60, 320, 1, Language["Width"], Language["Set the width of the unit frame"], UpdateWidth)

	left:CreateHeader(Language["Health"])
	left:CreateSwitch("unitframes-boss-health-reverse", Settings["unitframes-boss-health-reverse"], Language["Reverse Health Fill"], Language["Reverse the fill of the health bar"], UpdateHealthFill)
	left:CreateSlider("unitframes-boss-health-height", Settings["unitframes-boss-health-height"], 6, 60, 1, Language["Health Bar Height"], Language["Set the height of the health bar"], UpdateHealthHeight)
	left:CreateSwitch("unitframes-boss-health-smooth", Settings["unitframes-boss-health-smooth"], Language["Smooth Health"], Language["Animate health changes"], UpdateHealthSmooth)
	left:CreateDropdown("unitframes-boss-health-color", Settings["unitframes-boss-health-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Custom"]] = "CUSTOM"}, Language["Health Bar Color"], Language["Set the color of the health bar"], UpdateHealthColor)
	left:CreateTagInput("unitframes-boss-health-left", Settings["unitframes-boss-health-left"], Language["Left Health Text"], Language["Set the text on the left of the health bar"], UF:CreateUnitUpdater("boss", "TagText", {field = "HealthLeft", count = 8}))
	left:CreateTagInput("unitframes-boss-health-right", Settings["unitframes-boss-health-right"], Language["Right Health Text"], Language["Set the text on the right of the health bar"], UF:CreateUnitUpdater("boss", "TagText", {field = "HealthRight", count = 8}))
	left:CreateDropdown("BossHealthTexture", Settings.BossHealthTexture, Assets:GetTextureList(), Language["Health Texture"], "", UpdateHealthTexture, "Texture")

	right:CreateHeader(Language["Power"])
	right:CreateSwitch("unitframes-boss-power-reverse", Settings["unitframes-boss-power-reverse"], Language["Reverse Power Fill"], Language["Reverse the fill of the power bar"], UpdatePowerFill)
	right:CreateSlider("unitframes-boss-power-height", Settings["unitframes-boss-power-height"], 1, 30, 1, Language["Power Bar Height"], Language["Set the height of the power bar"], UpdatePowerHeight)
	right:CreateSwitch("unitframes-boss-power-smooth", Settings["unitframes-boss-power-smooth"], Language["Smooth Power"], Language["Animate power changes"], UpdatePowerSmooth)
	right:CreateDropdown("unitframes-boss-power-color", Settings["unitframes-boss-power-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Power Type"]] = "POWER"}, Language["Power Bar Color"], Language["Set the color of the power bar"], UpdatePowerColor)
	right:CreateTagInput("unitframes-boss-power-left", Settings["unitframes-boss-power-left"], Language["Left Power Text"], Language["Text on the left of boss power bars"], UF:CreateUnitUpdater("boss", "TagText", {field = "PowerLeft", count = 8}))
	right:CreateTagInput("unitframes-boss-power-right", Settings["unitframes-boss-power-right"], Language["Right Power Text"], Language["Text on the right of boss power bars"], UF:CreateUnitUpdater("boss", "TagText", {field = "PowerRight", count = 8}))
	right:CreateDropdown("BossPowerTexture", Settings.BossPowerTexture, Assets:GetTextureList(), Language["Power Texture"], "", UpdatePowerTexture, "Texture")

	right:CreateHeader(Language["Cast Bar"])
	right:CreateSwitch("unitframes-boss-enable-castbar", Settings["unitframes-boss-enable-castbar"], Language["Enable Cast Bar"], Language["Display boss cast bars"], ReloadUI):RequiresReload(true)
	right:CreateSlider("unitframes-boss-cast-width", Settings["unitframes-boss-cast-width"], 80, 360, 1, Language["Cast Bar Width"], Language["Set the width of boss cast bars"], UpdateBossCastSize)
	right:CreateSlider("unitframes-boss-cast-height", Settings["unitframes-boss-cast-height"], 8, 50, 1, Language["Cast Bar Height"], Language["Set the height of boss cast bars"], UpdateBossCastSize)

	right:CreateHeader(Language["Buffs"])
	right:CreateSwitch("unitframes-boss-buffs", Settings["unitframes-boss-buffs"], Language["Enable buffs"], Language["Display boss buffs"], UpdateBossAuras)
	right:CreateSlider("unitframes-boss-buff-size", Settings["unitframes-boss-buff-size"], 10, 50, 1, Language["Buff Size"], Language["Set the size of the debuff icons"], UpdateBuffSize)

	right:CreateHeader(Language["Debuffs"])
	right:CreateSwitch("unitframes-boss-debuffs", Settings["unitframes-boss-debuffs"], Language["Enable Debuffs"], Language["Display boss debuffs"], UpdateBossAuras)
	right:CreateSlider("unitframes-boss-debuff-size", Settings["unitframes-boss-debuff-size"], 10, 50, 1, Language["Debuff Size"], Language["Set the size of the debuff icons"], UpdateDebuffSize)
end)
YxUI:GetModule("GUI"):RegisterPageSettingsID("General", "Bosses", {
	{"unitframes-boss-width", UpdateWidth},
	{"unitframes-boss-health-reverse", UpdateHealthFill},
	{"unitframes-boss-health-height", UpdateHealthHeight},
	{"unitframes-boss-health-smooth", UpdateHealthSmooth},
	{"unitframes-boss-health-color", UpdateHealthColor},
	{"unitframes-boss-health-left", UF:CreateUnitUpdater("boss", "TagText", {field = "HealthLeft", count = 8})},
	{"unitframes-boss-health-right", UF:CreateUnitUpdater("boss", "TagText", {field = "HealthRight", count = 8})},
	{"BossHealthTexture", UpdateHealthTexture},
	{"unitframes-boss-power-reverse", UpdatePowerFill},
	{"unitframes-boss-power-height", UpdatePowerHeight},
	{"unitframes-boss-power-smooth", UpdatePowerSmooth},
	{"unitframes-boss-power-color", UpdatePowerColor},
	{"unitframes-boss-power-left", UF:CreateUnitUpdater("boss", "TagText", {field = "PowerLeft", count = 8})},
	{"unitframes-boss-power-right", UF:CreateUnitUpdater("boss", "TagText", {field = "PowerRight", count = 8})},
	{"BossPowerTexture", UpdatePowerTexture},
	{"unitframes-boss-cast-width", UpdateBossCastSize},
	{"unitframes-boss-cast-height", UpdateBossCastSize},
	{"unitframes-boss-buffs", UpdateBossAuras},
	{"unitframes-boss-buff-size", UpdateBuffSize},
	{"unitframes-boss-debuffs", UpdateBossAuras},
	{"unitframes-boss-debuff-size", UpdateDebuffSize},
}, "Unit Frames")


YxUI:GetModule("GUI"):RegisterReloadSettings({"unitframes-boss-enable", "unitframes-boss-enable-castbar"})
