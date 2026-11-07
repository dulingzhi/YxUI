local YxUI, Language, Assets, Settings, Defaults = select(2, ...):get()

Defaults["unitframes-target-width"] = 240
Defaults["unitframes-target-health-height"] = 32
Defaults["unitframes-target-health-reverse"] = false
Defaults["unitframes-target-health-color"] = "CLASS"
Defaults["unitframes-target-health-smooth"] = true
Defaults["unitframes-target-power-height"] = 15
Defaults["unitframes-target-power-reverse"] = false
Defaults["unitframes-target-power-color"] = "POWER"
Defaults["unitframes-target-power-smooth"] = true
Defaults["unitframes-target-health-left"] = "[LevelColor][Level][Plus][ColorStop] [Name(30)]"
Defaults["unitframes-target-health-right"] = "[HealthPercent]"
Defaults["unitframes-target-power-left"] = "[HealthValues:Short]"
Defaults["unitframes-target-power-right"] = "[PowerValues:Short]"
Defaults["unitframes-target-cast-width"] = 250
Defaults["unitframes-target-cast-height"] = 24
Defaults["unitframes-target-cast-classcolor"] = true
Defaults["unitframes-target-enable-castbar"] = true
Defaults["target-enable-portrait"] = false
Defaults["target-portrait-style"] = "3D"
Defaults["target-overlay-alpha"] = 30
Defaults["target-enable"] = true
Defaults.TargetBuffSize = 28
Defaults.TargetBuffSpacing = 2
Defaults.TargetDebuffSize = 28
Defaults.TargetDebuffSpacing = 2
Defaults.TargetHealthTexture = "YxUI 4"
Defaults.TargetPowerTexture = "YxUI 4"

local UF = YxUI:GetModule("Unit Frames")

local function CreateTargetCastbar(factory, frame)
	local Anchor = CreateFrame("Frame", "YxUI Target Casting Bar", frame)
	Anchor:SetSize(Settings["unitframes-target-cast-width"], Settings["unitframes-target-cast-height"])
	factory:CreateCastbar(frame, nil,
		Settings["unitframes-target-cast-width"] - Settings["unitframes-target-cast-height"] - 1, Settings["unitframes-target-cast-height"],
		"RIGHT", Anchor, "RIGHT", 0, 0, Settings["ui-widget-texture"], "Blank",
		-Settings["unitframes-target-cast-height"] - 2, 1, 1, -1,
		Settings["unitframes-font"], Settings["unitframes-font-size"], Settings["unitframes-font-flags"],
		-5, 5, Settings["unitframes-target-cast-width"] * 0.7,
		Settings["unitframes-target-cast-height"], nil, nil, nil, true, 0.3, Settings["unitframes-target-cast-classcolor"],
		factory.PostCastStart, factory.PostCastStop, factory.PostCastFail, factory.PostCastInterruptible)
	frame.CastAnchor = Anchor
end

local function BuildTargetComponents(factory, frame, unit)
-- Portrait
	factory:CreatePortrait(frame,
		Settings["target-portrait-style"],
		Settings["target-portrait-style"] == "OVERLAY" and Settings["unitframes-target-width"] or 55,
		Settings["target-portrait-style"] == "OVERLAY" and Settings["unitframes-target-health-height"] or Settings["unitframes-target-health-height"] + Settings["unitframes-target-power-height"] + 1,
		Settings["target-portrait-style"] == "OVERLAY" and "CENTER" or "LEFT",
		Settings["target-portrait-style"] == "OVERLAY" and frame.Health or frame,
		Settings["target-portrait-style"] == "OVERLAY" and "CENTER" or "RIGHT",
		Settings["target-portrait-style"] == "OVERLAY" and 0 or 3, 0,
		Settings["target-portrait-style"] == "OVERLAY" and Settings["target-overlay-alpha"] / 100 or nil,
		Settings["Blank"], Settings["target-enable-portrait"])


	-- Auras
	local Buffs = factory:CreateAuraContainer(frame, frame:GetName() .. "Buffs", nil, Settings["unitframes-target-width"], 28,
		"BOTTOMLEFT", frame, "TOPLEFT", 0, 2, Settings.TargetBuffSize, Settings.TargetBuffSpacing, 16,
		"TOPLEFT", "ANCHOR_TOP", "RIGHT", "UP", factory.PostCreateIcon, factory.PostUpdateIcon, nil, nil, nil)
	local Debuffs = factory:CreateAuraContainer(frame, frame:GetName() .. "Debuffs", nil, Settings["unitframes-target-width"], 28,
		nil, nil, nil, 0, 0, Settings.TargetDebuffSize, Settings.TargetDebuffSpacing, 16,
		"TOPRIGHT", "ANCHOR_TOP", "LEFT", "UP", factory.PostCreateIcon, factory.PostUpdateIcon, nil, Settings["unitframes-only-player-debuffs"], true)
	if Settings["unitframes-show-player-buffs"] then
		Debuffs:SetPoint("BOTTOM", Buffs, "TOP", 0, 2)
	else
		Debuffs:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 2)
	end

	-- Castbar
	if Settings["unitframes-target-enable-castbar"] then
		CreateTargetCastbar(factory, frame)
	end

	frame.Buffs = Buffs
	frame.Debuffs = Debuffs
end

local SingleUnitRange = {insideAlpha = 1, outsideAlpha = 0.5}
local TargetFrameConfig = {
	settingsPrefix = "unitframes-target",
	debuffColors = true,
	healthTextureKey = "TargetHealthTexture",
	powerTextureKey = "TargetPowerTexture",
	powerTags = true,
	colorTapping = true,
	colorDisconnected = true,
	powerReaction = true,
	raidTarget = true,
	auras = BuildTargetComponents,
	range = SingleUnitRange,
}

YxUI.StyleFuncs["target"] = function(self, unit)
	UF:BuildSingleUnitFrame(self, unit, TargetFrameConfig)
end

local function UpdateTargetCastbar()
	UF:RunAfterCombat("target:castbar", function()
		local frame = YxUI.UnitFrames["target"]
		if not frame then
			return
		end
		if Settings["unitframes-target-enable-castbar"] then
			if not frame.Castbar then
				CreateTargetCastbar(UF, frame)
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

local function UpdateTargetPortraitSize()
	local frame = YxUI.UnitFrames["target"]
	if not frame or not frame.Portrait then
		return
	end
	local overlay = Settings["target-portrait-style"] == "OVERLAY"
	frame.Portrait:SetSize(overlay and Settings["unitframes-target-width"] or 55,
		overlay and Settings["unitframes-target-health-height"] or Settings["unitframes-target-health-height"] + Settings["unitframes-target-power-height"] + 1)
end

local UpdateTargetFrameWidth = UF:CreateUnitUpdater("target", "Width", {widthElements = {"Buffs", "Debuffs"}})
local function UpdateTargetWidth(value)
	UpdateTargetFrameWidth(value)
	UpdateTargetPortraitSize()
end

local UpdateTargetFrameHealthHeight = UF:CreateUnitUpdater("target", "HealthHeight", {powerHeight = "unitframes-target-power-height"})
local function UpdateTargetHealthHeight(value)
	UpdateTargetFrameHealthHeight(value)
	UpdateTargetPortraitSize()
end

local UpdateTargetHealthFill = UF:CreateUnitUpdater("target", "HealthReverse")

local UpdateTargetFramePowerHeight = UF:CreateUnitUpdater("target", "PowerHeight", {healthHeight = "unitframes-target-health-height"})
local function UpdateTargetPowerHeight(value)
	UpdateTargetFramePowerHeight(value)
	UpdateTargetPortraitSize()
end

local UpdateTargetPowerFill = UF:CreateUnitUpdater("target", "PowerReverse")

local UpdateTargetHealthColor = UF:CreateUnitUpdater("target", "HealthColor")

local UpdateTargetPowerColor = UF:CreateUnitUpdater("target", "PowerColor")

local UpdateTargetCastBarSize = function()
	if YxUI.UnitFrames["target"].Castbar then
		YxUI.UnitFrames["target"].Castbar:SetSize(Settings["unitframes-target-cast-width"], Settings["unitframes-target-cast-height"])
		YxUI.UnitFrames["target"].Castbar.Icon:SetSize(Settings["unitframes-target-cast-height"], Settings["unitframes-target-cast-height"])
	end
end

local UpdateCastClassColor = function(value)
	if YxUI.UnitFrames["target"].Castbar then
		YxUI.UnitFrames["target"].Castbar.ClassColor = value
		YxUI.UnitFrames["target"].Castbar:ForceUpdate()
	end
end

local UpdateTargetEnablePortrait = function(value)
	local Frame = YxUI.UnitFrames["target"]

	if Frame and Frame.Portrait then
		UF:SetElementEnabled("target", value, "Portrait")

		if Frame.Portrait.BG then
			if value then
				Frame.Portrait.BG:Show()
			else
				Frame.Portrait.BG:Hide()
			end
		end

		Frame.Portrait:ForceUpdate()
	end
end

local function UpdateTargetPortraitStyle()
	UF:RunAfterCombat("target:portrait-style", function()
		local frame = YxUI.UnitFrames["target"]
		if not frame then
			return
		end
		local style = Settings["target-portrait-style"]
		UF:SetPortraitStyle(frame, style,
			style == "OVERLAY" and Settings["unitframes-target-width"] or 55,
			style == "OVERLAY" and Settings["unitframes-target-health-height"] or Settings["unitframes-target-health-height"] + Settings["unitframes-target-power-height"] + 1,
			style == "OVERLAY" and "CENTER" or "LEFT",
			style == "OVERLAY" and frame.Health or frame,
			style == "OVERLAY" and "CENTER" or "RIGHT",
			style == "OVERLAY" and 0 or 3, 0,
			style == "OVERLAY" and Settings["target-overlay-alpha"] / 100 or nil,
			Settings["Blank"])
	end)
end

local UpdateOverlayAlpha = function(value)
	if YxUI.UnitFrames["target"] and Settings["target-portrait-style"] == "OVERLAY" then
		YxUI.UnitFrames["target"].Portrait:SetAlpha(value / 100)
	end
end

local UpdateBuffSize = UF:CreateUnitUpdater("target", "AuraSize", {element = "Buffs", width = "unitframes-target-width"})

local UpdateBuffSpacing = UF:CreateUnitUpdater("target", "AuraSpacing", {element = "Buffs"})

local UpdateDebuffSize = UF:CreateUnitUpdater("target", "AuraSize", {element = "Debuffs", width = "unitframes-target-width"})

local UpdateDebuffSpacing = UF:CreateUnitUpdater("target", "AuraSpacing", {element = "Debuffs"})

local UpdateDisplayedAuras = function()
	if not YxUI.UnitFrames["target"] then
		return
	end

	local Target = YxUI.UnitFrames["target"]

	Target.Debuffs:ClearAllPoints()

	if Settings["unitframes-show-target-buffs"] then
		Target.Debuffs:SetPoint("BOTTOM", Target.Buffs, "TOP", 0, 2)
	else
		Target.Debuffs:SetPoint("BOTTOMLEFT", Target, "TOPLEFT", 0, 2)
	end

	if Settings["unitframes-show-target-buffs"] then
		Target.Buffs:Show()
	else
		Target.Buffs:Hide()
	end

	if Settings["unitframes-show-target-debuffs"] then
		Target.Debuffs:Show()
	else
		Target.Debuffs:Hide()
	end
end

local UpdateHealthTexture = UF:CreateUnitUpdater("target", "HealthTexture")

local UpdatePowerTexture = UF:CreateUnitUpdater("target", "PowerTexture")

local UpdateHealthSmooth = UF:CreateUnitUpdater("target", "HealthSmooth")
local UpdatePowerSmooth = UF:CreateUnitUpdater("target", "PowerSmooth")

YxUI:GetModule("GUI"):AddWidgetsID("General", "Target", "Unit Frames", function(left, right)
	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("target-enable", Settings["target-enable"], Language["Enable Target"], Language["Enable the target unit frame"], ReloadUI):RequiresReload(true)
	left:CreateSlider("unitframes-target-width", Settings["unitframes-target-width"], 120, 320, 1, Language["Width"], Language["Set the width of the target unit frame"], UpdateTargetWidth)
	left:CreateSwitch("unitframes-only-player-debuffs", Settings["unitframes-only-player-debuffs"], Language["Only Display Player Debuffs"], Language["If enabled, only your own debuffs will be displayed on the target"], UpdateOnlyPlayerDebuffs)
	left:CreateSwitch("target-enable-portrait", Settings["target-enable-portrait"], Language["Enable Portrait"], Language["Display the target unit portrait"], UpdateTargetEnablePortrait)
	left:CreateDropdown("target-portrait-style", Settings["target-portrait-style"], {[Language["2D"]] = "2D", [Language["3D"]] = "3D", [Language["Overlay"]] = "OVERLAY"}, Language["Set Portrait Style"], Language["Set the style of the portrait"], UpdateTargetPortraitStyle)
	left:CreateSlider("target-overlay-alpha", Settings["target-overlay-alpha"], 0, 100, 5, Language["Set Overlay Opacity"], Language["Set the opacity of the portrait overlay"], UpdateOverlayAlpha, nil, "%")

	left:CreateHeader(Language["Health"])
	left:CreateSwitch("unitframes-target-health-reverse", Settings["unitframes-target-health-reverse"], Language["Reverse Health Fill"], Language["Reverse the fill of the health bar"], UpdateTargetHealthFill)
	left:CreateSlider("unitframes-target-health-height", Settings["unitframes-target-health-height"], 6, 60, 1, Language["Health Bar Height"], Language["Set the height of the target health bar"], UpdateTargetHealthHeight)
	left:CreateSwitch("unitframes-target-health-smooth", Settings["unitframes-target-health-smooth"], Language["Smooth Health"], Language["Animate health changes"], UpdateHealthSmooth)
	left:CreateDropdown("unitframes-target-health-color", Settings["unitframes-target-health-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Custom"]] = "CUSTOM"}, Language["Health Color"], Language["Set the color of the health bar"], UpdateTargetHealthColor)
	left:CreateTagInput("unitframes-target-health-left", Settings["unitframes-target-health-left"], Language["Left Health Text"], Language["Set the text on the left of the target health bar"], UF:CreateUnitUpdater("target", "TagText", {field = "HealthLeft"}))
	left:CreateTagInput("unitframes-target-health-right", Settings["unitframes-target-health-right"], Language["Right Health Text"], Language["Set the text on the right of the target health bar"], UF:CreateUnitUpdater("target", "TagText", {field = "HealthRight"}))
	left:CreateDropdown("TargetHealthTexture", Settings.TargetHealthTexture, Assets:GetTextureList(), Language["Health Texture"], "", UpdateHealthTexture, "Texture")

	left:CreateHeader(Language["Buffs"])
	left:CreateSwitch("unitframes-show-target-buffs", Settings["unitframes-show-target-buffs"], Language["Show Buffs"], Language["Show auras above the target unit frame"], UpdateDisplayedAuras)
	left:CreateSlider("TargetBuffSize", Settings.TargetBuffSize, 26, 50, 2, Language["Set Size"], Language["Set the size of the auras"], UpdateBuffSize)
	left:CreateSlider("TargetBuffSpacing", Settings.TargetBuffSpacing, -1, 4, 1, Language["Set Spacing"], Language["Set the spacing between the auras"], UpdateBuffSpacing)

	left:CreateHeader(Language["Debuffs"])
	left:CreateSwitch("unitframes-show-target-debuffs", Settings["unitframes-show-target-debuffs"], Language["Show Debuffs"], Language["Show your debuff auras above the target unit frame"], UpdateDisplayedAuras)
	left:CreateSlider("TargetDebuffSize", Settings.TargetDebuffSize, 26, 50, 2, Language["Set Size"], Language["Set the size of the auras"], UpdateDebuffSize)
	left:CreateSlider("TargetDebuffSpacing", Settings.TargetDebuffSpacing, -1, 4, 1, Language["Set Spacing"], Language["Set the spacing between the auras"], UpdateDebuffSpacing)

	right:CreateHeader(Language["Power"])
	right:CreateSwitch("unitframes-target-power-reverse", Settings["unitframes-target-power-reverse"], Language["Reverse Power Fill"], Language["Reverse the fill of the power bar"], UpdateTargetPowerFill)
	right:CreateSlider("unitframes-target-power-height", Settings["unitframes-target-power-height"], 2, 30, 1, Language["Power Bar Height"], Language["Set the height of the target power bar"], UpdateTargetPowerHeight)
	right:CreateSwitch("unitframes-target-power-smooth", Settings["unitframes-target-power-smooth"], Language["Smooth Power"], Language["Animate power changes"], UpdatePowerSmooth)
	right:CreateDropdown("unitframes-target-power-color", Settings["unitframes-target-power-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Power Type"]] = "POWER"}, Language["Power Bar Color"], Language["Set the color of the power bar"], UpdateTargetPowerColor)
	right:CreateTagInput("unitframes-target-power-left", Settings["unitframes-target-power-left"], Language["Left Power Text"], Language["Set the text on the left of the target power bar"], UF:CreateUnitUpdater("target", "TagText", {field = "PowerLeft"}))
	right:CreateTagInput("unitframes-target-power-right", Settings["unitframes-target-power-right"], Language["Right Power Text"], Language["Set the text on the right of the target power bar"], UF:CreateUnitUpdater("target", "TagText", {field = "PowerRight"}))
	right:CreateDropdown("TargetPowerTexture", Settings.TargetPowerTexture, Assets:GetTextureList(), Language["Power Texture"], "", UpdatePowerTexture, "Texture")

	right:CreateHeader(Language["Cast Bar"])
	right:CreateSwitch("unitframes-target-enable-castbar", Settings["unitframes-target-enable-castbar"], Language["Enable Cast Bar"], Language["Enable the target cast bar"], UpdateTargetCastbar)
	right:CreateSwitch("unitframes-target-cast-classcolor", Settings["unitframes-target-cast-classcolor"], Language["Enable Class Color"], Language["Use class colors"], UpdateCastClassColor)

	right:CreateSlider("unitframes-target-cast-width", Settings["unitframes-target-cast-width"], 80, 360, 1, Language["Cast Bar Width"], Language["Set the width of the target cast bar"], UpdateTargetCastBarSize)
	right:CreateSlider("unitframes-target-cast-height", Settings["unitframes-target-cast-height"], 8, 50, 1, Language["Cast Bar Height"], Language["Set the height of the target cast bar"], UpdateTargetCastBarSize)
end)
YxUI:GetModule("GUI"):RegisterPageSettingsID("General", "Target", {
	{"unitframes-target-width", UpdateTargetWidth},
	{"unitframes-only-player-debuffs", UpdateOnlyPlayerDebuffs},
	{"target-enable-portrait", UpdateTargetEnablePortrait},
	{"target-portrait-style", UpdateTargetPortraitStyle},
	{"target-overlay-alpha", UpdateOverlayAlpha},
	{"unitframes-target-health-reverse", UpdateTargetHealthFill},
	{"unitframes-target-health-height", UpdateTargetHealthHeight},
	{"unitframes-target-health-smooth", UpdateHealthSmooth},
	{"unitframes-target-health-color", UpdateTargetHealthColor},
	{"unitframes-target-health-left", UF:CreateUnitUpdater("target", "TagText", {field = "HealthLeft"})},
	{"unitframes-target-health-right", UF:CreateUnitUpdater("target", "TagText", {field = "HealthRight"})},
	{"TargetHealthTexture", UpdateHealthTexture},
	{"unitframes-show-target-buffs", UpdateDisplayedAuras},
	{"TargetBuffSize", UpdateBuffSize},
	{"TargetBuffSpacing", UpdateBuffSpacing},
	{"unitframes-show-target-debuffs", UpdateDisplayedAuras},
	{"TargetDebuffSize", UpdateDebuffSize},
	{"TargetDebuffSpacing", UpdateDebuffSpacing},
	{"unitframes-target-power-reverse", UpdateTargetPowerFill},
	{"unitframes-target-power-height", UpdateTargetPowerHeight},
	{"unitframes-target-power-smooth", UpdatePowerSmooth},
	{"unitframes-target-power-color", UpdateTargetPowerColor},
	{"unitframes-target-power-left", UF:CreateUnitUpdater("target", "TagText", {field = "PowerLeft"})},
	{"unitframes-target-power-right", UF:CreateUnitUpdater("target", "TagText", {field = "PowerRight"})},
	{"TargetPowerTexture", UpdatePowerTexture},
	{"unitframes-target-enable-castbar", UpdateTargetCastbar},
	{"unitframes-target-cast-classcolor", UpdateCastClassColor},
	{"unitframes-target-cast-width", UpdateTargetCastBarSize},
	{"unitframes-target-cast-height", UpdateTargetCastBarSize},
}, "Unit Frames")


YxUI:GetModule("GUI"):RegisterReloadSettings({"target-enable"})
