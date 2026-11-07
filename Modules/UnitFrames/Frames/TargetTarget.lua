local YxUI, Language, Assets, Settings, Defaults = select(2, ...):get()

Defaults["unitframes-targettarget-width"] = 110
Defaults["unitframes-targettarget-health-height"] = 26
Defaults["unitframes-targettarget-health-reverse"] = false
Defaults["unitframes-targettarget-health-color"] = "CLASS"
Defaults["unitframes-targettarget-health-smooth"] = true
Defaults["unitframes-targettarget-enable-power"] = true
Defaults["unitframes-targettarget-power-height"] = 3
Defaults["unitframes-targettarget-power-reverse"] = false
Defaults["unitframes-targettarget-power-color"] = "POWER"
Defaults["unitframes-targettarget-power-smooth"] = true
Defaults["unitframes-targettarget-power-left"] = ""
Defaults["unitframes-targettarget-power-right"] = ""
Defaults["unitframes-targettarget-health-left"] = "[Name(10)]"
Defaults["unitframes-targettarget-health-right"] = "[HealthPercent]"
Defaults["unitframes-targettarget-debuffs"] = true
Defaults["unitframes-targettarget-debuff-size"] = 20
Defaults["unitframes-targettarget-debuff-pos"] = "BOTTOM"
Defaults["tot-enable"] = true
Defaults.ToTHealthTexture = "YxUI 4"
Defaults.ToTPowerTexture = "YxUI 4"

local UF = YxUI:GetModule("Unit Frames")

local function BuildTargetTargetComponents(factory, frame, unit)
	if Settings["unitframes-targettarget-debuffs"] then
		local position = Settings["unitframes-targettarget-debuff-pos"]
		frame.Debuffs = factory:CreateAuraContainer(frame, frame:GetName() .. "Debuffs", nil, Settings["unitframes-targettarget-width"], Settings["unitframes-targettarget-debuff-size"],
		position == "TOP" and "BOTTOM" or "TOP", frame, position == "TOP" and "TOP" or "BOTTOM", 0, position == "TOP" and 2 or -2, Settings["unitframes-targettarget-debuff-size"], 2, 5,
		"TOPRIGHT", "ANCHOR_TOP", "LEFT", position == "TOP" and "UP" or "DOWN", UF.PostCreateIcon, UF.PostUpdateIcon, nil, nil, nil)
	end
end

local SingleUnitRange = {insideAlpha = 1, outsideAlpha = 0.5}
local TargetTargetFrameConfig = {
	settingsPrefix = "unitframes-targettarget",
	healthTextureKey = "ToTHealthTexture",
	powerTextureKey = "ToTPowerTexture",
	powerTags = true,
	powerEnabledKey = "unitframes-targettarget-enable-power",
	colorTapping = true,
	colorDisconnected = true,
	powerReaction = true,
	raidTarget = true,
	auras = BuildTargetTargetComponents,
	range = SingleUnitRange,
}

YxUI.StyleFuncs["targettarget"] = function(self, unit)
	UF:BuildSingleUnitFrame(self, unit, TargetTargetFrameConfig)
end

local UpdateTargetTargetWidth = UF:CreateUnitUpdater("targettarget", "Width")

local UpdateTargetTargetHealthHeight = UF:CreateUnitUpdater("targettarget", "HealthHeight", {powerHeight = "unitframes-targettarget-power-height"})

local UpdateTargetTargetPowerHeight = UF:CreateUnitUpdater("targettarget", "PowerHeight", {healthHeight = "unitframes-targettarget-health-height"})

local UpdateTargetTargetHealthColor = UF:CreateUnitUpdater("targettarget", "HealthColor")

local UpdateTargetTargetHealthFill = UF:CreateUnitUpdater("targettarget", "HealthReverse")

local UpdateTargetTargetPowerColor = UF:CreateUnitUpdater("targettarget", "PowerColor")

local UpdateTargetTargetPowerFill = UF:CreateUnitUpdater("targettarget", "PowerReverse")

local UpdateEnableDebuffs = UF:CreateUnitUpdater("targettarget", "ElementEnabled", {element = "Debuffs"})

local UpdateDebuffSize = UF:CreateUnitUpdater("targettarget", "AuraSize", {element = "Debuffs", width = "unitframes-targettarget-width"})

local UpdateDebuffPosition = UF:CreateUnitUpdater("targettarget", "AuraPosition", {element = "Debuffs", growthX = "LEFT"})

local UpdateHealthTexture = UF:CreateUnitUpdater("targettarget", "HealthTexture")

local UpdatePowerTexture = UF:CreateUnitUpdater("targettarget", "PowerTexture")

local UpdateHealthSmooth = UF:CreateUnitUpdater("targettarget", "HealthSmooth")
local UpdatePowerSmooth = UF:CreateUnitUpdater("targettarget", "PowerSmooth")

YxUI:GetModule("GUI"):AddWidgetsID("General", "Target of Target", "Unit Frames", function(left, right)
	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("tot-enable", Settings["tot-enable"], Language["Enable Target Target"], Language["Enable the target of target unit frame"], ReloadUI):RequiresReload(true)
	left:CreateSlider("unitframes-targettarget-width", Settings["unitframes-targettarget-width"], 60, 320, 1, Language["Width"], Language["Set the width of the target's target unit frame"], UpdateTargetTargetWidth)

	left:CreateHeader(Language["Health"])
	left:CreateSwitch("unitframes-targettarget-health-reverse", Settings["unitframes-targettarget-health-reverse"], Language["Reverse Health Fill"], Language["Reverse the fill of the health bar"], UpdateTargetTargetHealthFill)
	left:CreateSlider("unitframes-targettarget-health-height", Settings["unitframes-targettarget-health-height"], 6, 60, 1, Language["Health Bar Height"], Language["Set the height of the target of target health bar"], UpdateTargetTargetHealthHeight)
	left:CreateSwitch("unitframes-targettarget-health-smooth", Settings["unitframes-targettarget-health-smooth"], Language["Smooth Health"], Language["Animate health changes"], UpdateHealthSmooth)
	left:CreateDropdown("unitframes-targettarget-health-color", Settings["unitframes-targettarget-health-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Custom"]] = "CUSTOM"}, Language["Health Bar Color"], Language["Set the color of the health bar"], UpdateTargetTargetHealthColor)
	left:CreateTagInput("unitframes-targettarget-health-left", Settings["unitframes-targettarget-health-left"], Language["Left Health Text"], Language["Set the text on the left of the target of target health bar"], UF:CreateUnitUpdater("targettarget", "TagText", {field = "HealthLeft"}))
	left:CreateTagInput("unitframes-targettarget-health-right", Settings["unitframes-targettarget-health-right"], Language["Right Health Text"], Language["Set the text on the right of the target of target health bar"], UF:CreateUnitUpdater("targettarget", "TagText", {field = "HealthRight"}))

	left:CreateDropdown("ToTHealthTexture", Settings.ToTHealthTexture, Assets:GetTextureList(), Language["Health Texture"], "", UpdateHealthTexture, "Texture")

	right:CreateHeader(Language["Power"])
	right:CreateSwitch("unitframes-targettarget-enable-power", Settings["unitframes-targettarget-enable-power"], Language["Enable Power Bar"], Language["Show the power bar on this unit frame"], ReloadUI):RequiresReload(true)
	right:CreateSwitch("unitframes-targettarget-power-reverse", Settings["unitframes-targettarget-power-reverse"], Language["Reverse Power Fill"], Language["Reverse the fill of the power bar"], UpdateTargetTargetPowerFill)
	right:CreateSlider("unitframes-targettarget-power-height", Settings["unitframes-targettarget-power-height"], 1, 30, 1, Language["Power Bar Height"], Language["Set the height of the target of target power bar"], UpdateTargetTargetPowerHeight)
	right:CreateSwitch("unitframes-targettarget-power-smooth", Settings["unitframes-targettarget-power-smooth"], Language["Smooth Power"], Language["Animate power changes"], UpdatePowerSmooth)
	right:CreateDropdown("unitframes-targettarget-power-color", Settings["unitframes-targettarget-power-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Power Type"]] = "POWER"}, Language["Power Bar Color"], Language["Set the color of the power bar"], UpdateTargetTargetPowerColor)

	right:CreateTagInput("unitframes-targettarget-power-left", Settings["unitframes-targettarget-power-left"], Language["Left Power Text"], Language["Text on the left of the power bar"], UF:CreateUnitUpdater("targettarget", "TagText", {field = "PowerLeft"}))
	right:CreateTagInput("unitframes-targettarget-power-right", Settings["unitframes-targettarget-power-right"], Language["Right Power Text"], Language["Text on the right of the power bar"], UF:CreateUnitUpdater("targettarget", "TagText", {field = "PowerRight"}))
	right:CreateDropdown("ToTPowerTexture", Settings.ToTPowerTexture, Assets:GetTextureList(), Language["Power Texture"], "", UpdatePowerTexture, "Texture")

	right:CreateHeader(Language["Debuffs"])
	right:CreateSwitch("unitframes-targettarget-debuffs", Settings["unitframes-targettarget-debuffs"], Language["Enable Debuffs"], Language["Enable debuffs on the unit frame"], UpdateEnableDebuffs):RequiresReload(true)
	right:CreateSlider("unitframes-targettarget-debuff-size", Settings["unitframes-targettarget-debuff-size"], 10, 40, 1, Language["Debuff Size"], Language["Set the size of the debuff icons"], UpdateDebuffSize)
	right:CreateDropdown("unitframes-targettarget-debuff-pos", Settings["unitframes-targettarget-debuff-pos"], {[Language["Bottom"]] = "BOTTOM", [Language["Top"]] = "TOP"}, Language["Set Position"], Language["Set the position of the debuffs"], UpdateDebuffPosition)
end)
YxUI:GetModule("GUI"):RegisterPageSettingsID("General", "Target of Target", {
	{"unitframes-targettarget-width", UpdateTargetTargetWidth},
	{"unitframes-targettarget-health-reverse", UpdateTargetTargetHealthFill},
	{"unitframes-targettarget-health-height", UpdateTargetTargetHealthHeight},
	{"unitframes-targettarget-health-smooth", UpdateHealthSmooth},
	{"unitframes-targettarget-health-color", UpdateTargetTargetHealthColor},
	{"unitframes-targettarget-health-left", UF:CreateUnitUpdater("targettarget", "TagText", {field = "HealthLeft"})},
	{"unitframes-targettarget-health-right", UF:CreateUnitUpdater("targettarget", "TagText", {field = "HealthRight"})},
	{"ToTHealthTexture", UpdateHealthTexture},
	{"unitframes-targettarget-power-reverse", UpdateTargetTargetPowerFill},
	{"unitframes-targettarget-power-height", UpdateTargetTargetPowerHeight},
	{"unitframes-targettarget-power-smooth", UpdatePowerSmooth},
	{"unitframes-targettarget-power-color", UpdateTargetTargetPowerColor},
	{"unitframes-targettarget-power-left", UF:CreateUnitUpdater("targettarget", "TagText", {field = "PowerLeft"})},
	{"unitframes-targettarget-power-right", UF:CreateUnitUpdater("targettarget", "TagText", {field = "PowerRight"})},
	{"ToTPowerTexture", UpdatePowerTexture},
	{"unitframes-targettarget-debuff-size", UpdateDebuffSize},
	{"unitframes-targettarget-debuff-pos", UpdateDebuffPosition},
}, "Unit Frames")


YxUI:GetModule("GUI"):RegisterReloadSettings({"tot-enable", "unitframes-targettarget-debuffs", "unitframes-targettarget-enable-power"})
