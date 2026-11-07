local YxUI, Language, Assets, Settings, Defaults = select(2, ...):get()

Defaults["unitframes-focus-width"] = 200
Defaults["unitframes-focus-health-height"] = 26
Defaults["unitframes-focus-health-reverse"] = false
Defaults["unitframes-focus-health-color"] = "CLASS"
Defaults["unitframes-focus-health-smooth"] = true
Defaults["unitframes-focus-power-height"] = 6
Defaults["unitframes-focus-power-reverse"] = false
Defaults["unitframes-focus-power-color"] = "POWER"
Defaults["unitframes-focus-power-smooth"] = true
Defaults["unitframes-focus-power-left"] = ""
Defaults["unitframes-focus-power-right"] = ""
Defaults["unitframes-focus-cast-width"] = 170
Defaults["unitframes-focus-cast-height"] = 24
Defaults["unitframes-focus-cast-classcolor"] = false
Defaults["unitframes-focus-health-left"] = "[Name(10)]"
Defaults["unitframes-focus-health-right"] = "[HealthPercent]"
Defaults["focus-enable"] = true
Defaults["focus-enable-castbar"] = true
Defaults["focus-enable-buffs"] = true
Defaults["focus-enable-debuffs"] = true
Defaults.FocusHealthTexture = "YxUI 4"
Defaults.FocusPowerTexture = "YxUI 4"

local UF = YxUI:GetModule("Unit Frames")

local function CreateFocusCastbar(factory, frame)
	factory:CreateCastbar(frame, nil,
		Settings["unitframes-focus-cast-width"], Settings["unitframes-focus-cast-height"],
		"TOPRIGHT", frame, "BOTTOMRIGHT", -1, -3, Settings["ui-widget-texture"], "Blank",
		-Settings["unitframes-focus-cast-height"] - 2, 1, 1, -1,
		Settings["unitframes-font"], Settings["unitframes-font-size"], Settings["unitframes-font-flags"],
		-5, 5, Settings["unitframes-focus-cast-width"] * 0.7,
		Settings["unitframes-focus-cast-height"], -4, true, nil, true, 0.7, Settings["unitframes-focus-cast-classcolor"],
		factory.PostCastStart, factory.PostCastStop, factory.PostCastFail, factory.PostCastInterruptible)
end

local function BuildFocusComponents(factory, frame, unit)
	if Settings["focus-enable-castbar"] then
		CreateFocusCastbar(factory, frame)
	end

	-- Auras
	local AuraSize = Settings["unitframes-focus-health-height"] + Settings["unitframes-focus-power-height"] + 3
	local Buffs = factory:CreateAuraContainer(frame, frame:GetName() .. "Buffs", nil, (AuraSize * 3) + 4, AuraSize,
		"LEFT", frame, "RIGHT", 2, 0, AuraSize, 2, 3,
		"LEFT", "ANCHOR_TOP", "RIGHT", nil, factory.PostCreateIcon, factory.PostUpdateIcon, nil, nil, nil)
	local Debuffs = factory:CreateAuraContainer(frame, frame:GetName() .. "Debuffs", nil, (AuraSize * 3) + 4, AuraSize,
		"LEFT", Buffs, "RIGHT", 2, 0, AuraSize, 2, 3,
		"LEFT", "ANCHOR_TOP", "RIGHT", nil, factory.PostCreateIcon, factory.PostUpdateIcon, nil, Settings["unitframes-only-focus-debuffs"], nil)

	frame.Buffs = Buffs
	frame.Debuffs = Debuffs
end

local FocusFrameConfig = {
	settingsPrefix = "unitframes-focus",
	healthTextureKey = "FocusHealthTexture",
	powerTextureKey = "FocusPowerTexture",
	powerTags = true,
	colorTapping = false,
	colorDisconnected = false,
	powerReaction = false,
	raidTarget = false,
	auras = BuildFocusComponents,
}

YxUI.StyleFuncs["focus"] = function(self, unit)
	UF:BuildSingleUnitFrame(self, unit, FocusFrameConfig)
end

local function UpdateFocusCastbar()
	UF:RunAfterCombat("focus:castbar", function()
		local frame = YxUI.UnitFrames["focus"]
		if not frame then
			return
		end
		if Settings["focus-enable-castbar"] then
			if not frame.Castbar then
				CreateFocusCastbar(UF, frame)
			end
			frame:EnableElement("Castbar")
			if frame.Castbar.ForceUpdate then
				frame.Castbar:ForceUpdate()
			end
		else
			frame:DisableElement("Castbar")
		end
	end)
end

local UpdateFocusWidth = UF:CreateUnitUpdater("focus", "Width")

local UpdateFocusHealthHeight = UF:CreateUnitUpdater("focus", "HealthHeight", {powerHeight = "unitframes-focus-power-height"})

local UpdateFocusPowerHeight = UF:CreateUnitUpdater("focus", "PowerHeight", {healthHeight = "unitframes-focus-health-height"})

local UpdateFocusHealthColor = UF:CreateUnitUpdater("focus", "HealthColor")

local UpdateFocusHealthFill = UF:CreateUnitUpdater("focus", "HealthReverse")

local UpdateFocusPowerColor = UF:CreateUnitUpdater("focus", "PowerColor")

local function UpdateFocusAuras()
	local frame = YxUI.UnitFrames["focus"]
	if not frame then return end

	local buffs = Settings["focus-enable-buffs"]
	local debuffs = Settings["focus-enable-debuffs"]
	if buffs or debuffs then
		frame:EnableElement("Auras")
		frame.Buffs:SetShown(buffs)
		frame.Debuffs:SetShown(debuffs)
	else
		frame:DisableElement("Auras")
	end
end

local function UpdateFocusCastbarSize()
	local frame = YxUI.UnitFrames["focus"]
	if not frame or not frame.Castbar then return end
	local bar = frame.Castbar
	bar:SetSize(Settings["unitframes-focus-cast-width"], Settings["unitframes-focus-cast-height"])
	bar.Icon:SetSize(Settings["unitframes-focus-cast-height"], Settings["unitframes-focus-cast-height"])
	bar.Text:SetWidth(Settings["unitframes-focus-cast-width"] * 0.7)
end

local function UpdateFocusCastClassColor(value)
	local frame = YxUI.UnitFrames["focus"]
	if frame and frame.Castbar then
		frame.Castbar.ClassColor = value
		frame.Castbar:ForceUpdate()
	end
end

local UpdateFocusPowerFill = UF:CreateUnitUpdater("focus", "PowerReverse")

local UpdateHealthTexture = UF:CreateUnitUpdater("focus", "HealthTexture")

local UpdatePowerTexture = UF:CreateUnitUpdater("focus", "PowerTexture")

local UpdateHealthSmooth = UF:CreateUnitUpdater("focus", "HealthSmooth")
local UpdatePowerSmooth = UF:CreateUnitUpdater("focus", "PowerSmooth")

YxUI:GetModule("GUI"):AddWidgetsID("General", "Focus", "Unit Frames", function(left, right)
	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("focus-enable", Settings["focus-enable"], Language["Enable Focus"], Language["Enable the focus unit frame"], ReloadUI):RequiresReload(true)
	left:CreateSlider("unitframes-focus-width", Settings["unitframes-focus-width"], 60, 320, 1, Language["Width"], Language["Set the width of the focus unit frame"], UpdateFocusWidth)

	left:CreateHeader(Language["Health"])
	left:CreateSwitch("unitframes-focus-health-reverse", Settings["unitframes-focus-health-reverse"], Language["Reverse Health Fill"], Language["Reverse the fill of the health bar"], UpdateFocusHealthFill)
	left:CreateSlider("unitframes-focus-health-height", Settings["unitframes-focus-health-height"], 6, 60, 1, Language["Health Bar Height"], Language["Set the height of the focus health bar"], UpdateFocusHealthHeight)
	left:CreateSwitch("unitframes-focus-health-smooth", Settings["unitframes-focus-health-smooth"], Language["Smooth Health"], Language["Animate health changes"], UpdateHealthSmooth)
	left:CreateDropdown("unitframes-focus-health-color", Settings["unitframes-focus-health-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Custom"]] = "CUSTOM"}, Language["Health Bar Color"], Language["Set the color of the health bar"], UpdateFocusHealthColor)
	left:CreateTagInput("unitframes-focus-health-left", Settings["unitframes-focus-health-left"], Language["Left Health Text"], Language["Set the text on the left of the focus health bar"], UF:CreateUnitUpdater("focus", "TagText", {field = "HealthLeft"}))
	left:CreateTagInput("unitframes-focus-health-right", Settings["unitframes-focus-health-right"], Language["Right Health Text"], Language["Set the text on the right of the focus health bar"], UF:CreateUnitUpdater("focus", "TagText", {field = "HealthRight"}))
	left:CreateDropdown("FocusHealthTexture", Settings.FocusHealthTexture, Assets:GetTextureList(), Language["Health Texture"], "", UpdateHealthTexture, "Texture")

	right:CreateHeader(Language["Power"])
	right:CreateSwitch("unitframes-focus-power-reverse", Settings["unitframes-focus-power-reverse"], Language["Reverse Power Fill"], Language["Reverse the fill of the power bar"], UpdateFocusPowerFill)
	right:CreateSlider("unitframes-focus-power-height", Settings["unitframes-focus-power-height"], 1, 30, 1, Language["Power Bar Height"], Language["Set the height of the focus power bar"], UpdateFocusPowerHeight)
	right:CreateSwitch("unitframes-focus-power-smooth", Settings["unitframes-focus-power-smooth"], Language["Smooth Power"], Language["Animate power changes"], UpdatePowerSmooth)
	right:CreateDropdown("unitframes-focus-power-color", Settings["unitframes-focus-power-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Power Type"]] = "POWER"}, Language["Power Bar Color"], Language["Set the color of the power bar"], UpdateFocusPowerColor)
	right:CreateTagInput("unitframes-focus-power-left", Settings["unitframes-focus-power-left"], Language["Left Power Text"], Language["Text on the left of the focus power bar"], UF:CreateUnitUpdater("focus", "TagText", {field = "PowerLeft"}))
	right:CreateTagInput("unitframes-focus-power-right", Settings["unitframes-focus-power-right"], Language["Right Power Text"], Language["Text on the right of the focus power bar"], UF:CreateUnitUpdater("focus", "TagText", {field = "PowerRight"}))
	right:CreateDropdown("FocusPowerTexture", Settings.FocusPowerTexture, Assets:GetTextureList(), Language["Power Texture"], "", UpdatePowerTexture, "Texture")

	right:CreateHeader(Language["Cast Bar"])
	right:CreateSwitch("focus-enable-castbar", Settings["focus-enable-castbar"], Language["Enable Cast Bar"], Language["Enable the cast bar"], UpdateFocusCastbar)
	right:CreateSwitch("unitframes-focus-cast-classcolor", Settings["unitframes-focus-cast-classcolor"], Language["Enable Class Color"], Language["Use class colors"], UpdateFocusCastClassColor)
	right:CreateSlider("unitframes-focus-cast-width", Settings["unitframes-focus-cast-width"], 80, 360, 1, Language["Cast Bar Width"], Language["Set the width of the focus cast bar"], UpdateFocusCastbarSize)
	right:CreateSlider("unitframes-focus-cast-height", Settings["unitframes-focus-cast-height"], 8, 50, 1, Language["Cast Bar Height"], Language["Set the height of the focus cast bar"], UpdateFocusCastbarSize)

	right:CreateHeader(Language["Buffs"])
	right:CreateSwitch("focus-enable-buffs", Settings["focus-enable-buffs"], Language["Show Focus Buffs"], Language["Display focus buffs"], UpdateFocusAuras)
	right:CreateHeader(Language["Debuffs"])
	right:CreateSwitch("focus-enable-debuffs", Settings["focus-enable-debuffs"], Language["Show Debuffs"], Language["Display focus debuffs"], UpdateFocusAuras)
end)
YxUI:GetModule("GUI"):RegisterPageSettingsID("General", "Focus", {
	{"unitframes-focus-width", UpdateFocusWidth},
	{"unitframes-focus-health-reverse", UpdateFocusHealthFill},
	{"unitframes-focus-health-height", UpdateFocusHealthHeight},
	{"unitframes-focus-health-smooth", UpdateHealthSmooth},
	{"unitframes-focus-health-color", UpdateFocusHealthColor},
	{"unitframes-focus-health-left", UF:CreateUnitUpdater("focus", "TagText", {field = "HealthLeft"})},
	{"unitframes-focus-health-right", UF:CreateUnitUpdater("focus", "TagText", {field = "HealthRight"})},
	{"FocusHealthTexture", UpdateHealthTexture},
	{"unitframes-focus-power-reverse", UpdateFocusPowerFill},
	{"unitframes-focus-power-height", UpdateFocusPowerHeight},
	{"unitframes-focus-power-smooth", UpdatePowerSmooth},
	{"unitframes-focus-power-color", UpdateFocusPowerColor},
	{"unitframes-focus-power-left", UF:CreateUnitUpdater("focus", "TagText", {field = "PowerLeft"})},
	{"unitframes-focus-power-right", UF:CreateUnitUpdater("focus", "TagText", {field = "PowerRight"})},
	{"FocusPowerTexture", UpdatePowerTexture},
	{"focus-enable-castbar", UpdateFocusCastbar},
	{"unitframes-focus-cast-classcolor", UpdateFocusCastClassColor},
	{"unitframes-focus-cast-width", UpdateFocusCastbarSize},
	{"unitframes-focus-cast-height", UpdateFocusCastbarSize},
	{"focus-enable-buffs", UpdateFocusAuras},
	{"focus-enable-debuffs", UpdateFocusAuras},
}, "Unit Frames")


YxUI:GetModule("GUI"):RegisterReloadSettings({"focus-enable"})
