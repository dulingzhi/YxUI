local YxUI, Language, Assets, Settings, Defaults = select(2, ...):get()

Defaults["unitframes-target-width"] = 200
Defaults["unitframes-target-health-height"] = 34
Defaults["unitframes-target-health-reverse"] = false
Defaults["unitframes-target-health-color"] = "CLASS"
Defaults["unitframes-target-health-smooth"] = true
Defaults["unitframes-target-power-height"] = 16
Defaults["unitframes-target-power-reverse"] = false
Defaults["unitframes-target-power-color"] = "POWER"
Defaults["unitframes-target-power-smooth"] = true
Defaults["unitframes-target-health-left"] = "[LevelColor][Level][Plus][ColorStop] [Name(30)]"
Defaults["unitframes-target-health-right"] = "[HealthPercent]"
Defaults["unitframes-target-power-left"] = "[HealthValues:Short]"
Defaults["unitframes-target-power-right"] = "[PowerValues:Short]"
Defaults["unitframes-target-cast-width"] = 268
Defaults["unitframes-target-cast-height"] = 34
Defaults["unitframes-target-cast-classcolor"] = true
Defaults["unitframes-target-enable-castbar"] = true
Defaults["target-enable-portrait"] = false
Defaults["target-portrait-style"] = "2D"
Defaults["target-overlay-alpha"] = 30
Defaults["target-enable"] = true
Defaults.TargetBuffPerLine = 6
Defaults.TargetBuffSpacing = 6
Defaults.TargetBuffSize = (Defaults["unitframes-target-width"] - (Defaults.TargetBuffPerLine - 1) * Defaults.TargetBuffSpacing) / Defaults.TargetBuffPerLine - 0.3
Defaults.TargetDebuffSize = Defaults.TargetBuffSize
Defaults.TargetDebuffSpacing = Defaults.TargetBuffSpacing
Defaults.TargetHealthTexture = "YxUI 4"
Defaults.TargetPowerTexture = "YxUI 4"

local UF = YxUI:GetModule("Unit Frames")

YxUI.StyleFuncs["target"] = function(self, unit)
	-- General
	self:RegisterForClicks("AnyUp")
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)
    if not YxUI.IsClassic then
        self:SetAttribute('alt-type1', 'focus')
    end

	self.colors.debuff = YxUI.DebuffColors

	local Backdrop = self:CreateTexture(nil, "BACKGROUND")
	Backdrop:SetAllPoints()
	Backdrop:SetTexture(Assets:GetTexture("Blank"))
	Backdrop:SetVertexColor(0, 0, 0)

	-- Threat
	local Threat = CreateFrame("Frame", nil, self, "BackdropTemplate")
	Threat:SetPoint("TOPLEFT", -1, 1)
	Threat:SetPoint("BOTTOMRIGHT", 1, -1)
	Threat:SetBackdrop(YxUI.Outline)
	Threat.PostUpdate = UF.ThreatPostUpdate

	self.ThreatIndicator = Threat

	-- Health Bar
	local Health = CreateFrame("StatusBar", nil, self)
	Health:SetPoint("TOPLEFT", self, 1, -1)
	Health:SetPoint("TOPRIGHT", self, -1, -1)
	Health:SetHeight(Settings["unitframes-target-health-height"])
	Health:SetStatusBarTexture(Assets:GetTexture(Settings.TargetHealthTexture))
	Health:SetReverseFill(Settings["unitframes-target-health-reverse"])
    Health:CreateBorder()

	local HealBar = CreateFrame("StatusBar", nil, Health)
	HealBar:SetWidth(Settings["unitframes-target-width"])
	HealBar:SetHeight(Settings["unitframes-target-health-height"])
	HealBar:SetStatusBarTexture(Assets:GetTexture(Settings.TargetHealthTexture))
	HealBar:SetStatusBarColor(0, 0.48, 0)
	HealBar:SetFrameLevel(Health:GetFrameLevel() - 1)

	if Settings["unitframes-target-health-reverse"] then
		HealBar:SetPoint("RIGHT", Health:GetStatusBarTexture(), "LEFT", 0, 0)
	else
		HealBar:SetPoint("LEFT", Health:GetStatusBarTexture(), "RIGHT", 0, 0)
	end

	self.HealBar = HealBar

	if YxUI.IsMainline then
		local AbsorbsBar = CreateFrame("StatusBar", nil, Health)
		AbsorbsBar:SetWidth(Settings["unitframes-target-width"])
		AbsorbsBar:SetHeight(Settings["unitframes-target-health-height"])
		AbsorbsBar:SetStatusBarTexture(Assets:GetTexture(Settings.TargetHealthTexture))
		AbsorbsBar:SetStatusBarColor(0, 0.66, 1)
		AbsorbsBar:SetFrameLevel(Health:GetFrameLevel() - 2)

		if Settings["unitframes-target-health-reverse"] then
			AbsorbsBar:SetPoint("RIGHT", Health:GetStatusBarTexture(), "LEFT", 0, 0)
		else
			AbsorbsBar:SetPoint("LEFT", Health:GetStatusBarTexture(), "RIGHT", 0, 0)
		end

		self.AbsorbsBar = AbsorbsBar
	end

	local HealthBG = self:CreateTexture(nil, "BORDER")
	HealthBG:SetAllPoints(Health)
	HealthBG:SetTexture(Assets:GetTexture(Settings.TargetHealthTexture))
	HealthBG.multiplier = 0.2

	local HealthLeft = Health:CreateFontString(nil, "OVERLAY")
	YxUI:SetFontInfo(HealthLeft, Settings["unitframes-font"], Settings["unitframes-font-size"], Settings["unitframes-font-flags"])
	HealthLeft:SetPoint("LEFT", Health, 3, 0)
	HealthLeft:SetJustifyH("LEFT")

	local HealthRight = Health:CreateFontString(nil, "OVERLAY")
	YxUI:SetFontInfo(HealthRight, Settings["unitframes-font"], Settings["unitframes-font-size"], Settings["unitframes-font-flags"])
	HealthRight:SetPoint("RIGHT", Health, -3, 0)
	HealthRight:SetJustifyH("RIGHT")

    -- Portrait
	local Portrait

	if (Settings["target-portrait-style"] == "2D") then
		Portrait = self:CreateTexture(nil, "OVERLAY")
		Portrait:SetTexCoord(0.12, 0.88, 0.12, 0.88)
		Portrait:SetSize(Settings["unitframes-target-health-height"] + Settings["unitframes-target-power-height"] + 3, Settings["unitframes-target-health-height"] + Settings["unitframes-target-power-height"] + 3)
		Portrait:SetPoint("LEFT", self, "RIGHT", 3, 0)

        Portrait.Border = CreateFrame("Frame", nil, self)
        Portrait.Border:SetAllPoints(Portrait)
        Portrait.Border:CreateBorder()
        Portrait.Border.YxUIBackground:Hide()

		Portrait.BG = self:CreateTexture(nil, "BACKGROUND")
		Portrait.BG:SetPoint("TOPLEFT", Portrait, -1, 1)
		Portrait.BG:SetPoint("BOTTOMRIGHT", Portrait, 1, -1)
		Portrait.BG:SetTexture(Assets:GetTexture(Settings["Blank"]))
		Portrait.BG:SetVertexColor(0, 0, 0)
	elseif (Settings["target-portrait-style"] == "OVERLAY") then
		Portrait = CreateFrame("PlayerModel", nil, self)
		Portrait:SetSize(Settings["unitframes-target-width"], Settings["unitframes-target-health-height"] )
		Portrait:SetPoint("CENTER", Health, 0, 0)
		Portrait:SetAlpha(0.3)
	else
		Portrait = CreateFrame("PlayerModel", nil, self)
	    Portrait:SetSize(Settings["unitframes-target-health-height"] + Settings["unitframes-target-power-height"] + 3, Settings["unitframes-target-health-height"] + Settings["unitframes-target-power-height"] + 3)
		Portrait:SetPoint("LEFT", self, "RIGHT", 3, 0)
        Portrait:CreateBorder()

		Portrait.BG = self:CreateTexture(nil, "BACKGROUND")
		Portrait.BG:SetPoint("TOPLEFT", Portrait, -1, 1)
		Portrait.BG:SetPoint("BOTTOMRIGHT", Portrait, 1, -1)
		Portrait.BG:SetTexture(Assets:GetTexture(Settings["Blank"]))
		Portrait.BG:SetVertexColor(0, 0, 0)
	end

	if (Portrait.BG and not Settings["target-enable-portrait"]) then
		Portrait.BG:Hide()
	end

    self.Portrait = Portrait

	-- Target Icon
	local RaidTarget = Health:CreateTexture(nil, 'OVERLAY', nil, 2)
	RaidTarget:SetSize(16, 16)
	RaidTarget:SetPoint("CENTER", Health, "TOP")

	local R, G, B = YxUI:HexToRGB(Settings["ui-header-texture-color"])

	-- Attributes
	Health.Smooth = true
	Health.colorTapping = true
	Health.colorDisconnected = true
	self.colors.health = {R, G, B}

	UF:SetHealthAttributes(Health, Settings["unitframes-target-health-color"])

	local Power = CreateFrame("StatusBar", nil, self)
	Power:SetPoint("BOTTOMLEFT", self, 1, 1)
	Power:SetPoint("BOTTOMRIGHT", self, -1, 1)
	Power:SetHeight(Settings["unitframes-target-power-height"])
	Power:SetStatusBarTexture(Assets:GetTexture(Settings.TargetPowerTexture))
	Power:SetReverseFill(Settings["unitframes-target-power-reverse"])
    Power:CreateBorder()

	local PowerBG = Power:CreateTexture(nil, "BORDER")
	PowerBG:SetPoint("TOPLEFT", Power, 0, 0)
	PowerBG:SetPoint("BOTTOMRIGHT", Power, 0, 0)
	PowerBG:SetTexture(Assets:GetTexture(Settings.TargetPowerTexture))
	PowerBG:SetAlpha(0.2)

	local PowerLeft = Power:CreateFontString(nil, "OVERLAY")
	YxUI:SetFontInfo(PowerLeft, Settings["unitframes-font"], Settings["unitframes-font-size"], Settings["unitframes-font-flags"])
	PowerLeft:SetPoint("LEFT", Power, 3, 0)
	PowerLeft:SetJustifyH("LEFT")

	local PowerRight = Power:CreateFontString(nil, "OVERLAY")
	YxUI:SetFontInfo(PowerRight, Settings["unitframes-font"], Settings["unitframes-font-size"], Settings["unitframes-font-flags"])
	PowerRight:SetPoint("RIGHT", Power, -3, 0)
	PowerRight:SetJustifyH("RIGHT")

	-- Attributes
	Power.frequentUpdates = true
	Power.colorReaction = true
	Power.Smooth = true

	UF:SetPowerAttributes(Power, Settings["unitframes-target-power-color"])

	-- Auras
	local Buffs = CreateFrame("Frame", self:GetName() .. "Buffs", self)
	Buffs:SetSize(Settings["unitframes-player-width"], 28)
	Buffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 1, 4)
	Buffs.size = Settings.TargetBuffSize
	Buffs.spacing = Settings.TargetBuffSpacing
	Buffs.num = 16
	Buffs.initialAnchor = "TOPLEFT"
	Buffs.tooltipAnchor = "ANCHOR_TOP"
	Buffs["growth-x"] = "RIGHT"
	Buffs["growth-y"] = "UP"
	Buffs.PostCreateIcon = UF.PostCreateIcon
	Buffs.PostUpdateIcon = UF.PostUpdateIcon

	local Debuffs = CreateFrame("Frame", self:GetName() .. "Debuffs", self)
	Debuffs:SetSize(Settings["unitframes-player-width"], 28)
	Debuffs.size = Settings.TargetDebuffSize
	Debuffs.spacing = Settings.TargetDebuffSpacing
	Debuffs.num = 16
	Debuffs.initialAnchor = "TOPRIGHT"
	Debuffs.tooltipAnchor = "ANCHOR_TOP"
	Debuffs["growth-x"] = "LEFT"
	Debuffs["growth-y"] = "UP"
	Debuffs.PostCreateIcon = UF.PostCreateIcon
	Debuffs.PostUpdateIcon = UF.PostUpdateIcon
	Debuffs.onlyShowPlayer = Settings["unitframes-only-player-debuffs"]
	Debuffs.showStealableBuffs = true

	if Settings["unitframes-show-player-buffs"] then
		Debuffs:SetPoint("BOTTOM", Buffs, "TOP", 0, 3)
	else
		Debuffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 1, 4)
	end

    -- Castbar
	if Settings["unitframes-target-enable-castbar"] then
		local Anchor = CreateFrame("Frame", "YxUI Target Casting Bar", self)
		Anchor:SetSize(Settings["unitframes-target-cast-width"], Settings["unitframes-target-cast-height"])

		local Castbar = CreateFrame("StatusBar", nil, self)
		Castbar:SetSize(Settings["unitframes-target-cast-width"] - Settings["unitframes-target-cast-height"] - 1, Settings["unitframes-target-cast-height"])
		Castbar:SetPoint("RIGHT", Anchor, 0, 0)
		Castbar:SetStatusBarTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
        Castbar:CreateBorder()

		local CastbarBG = Castbar:CreateTexture(nil, "ARTWORK")
		CastbarBG:SetPoint("TOPLEFT", Castbar, 0, 0)
		CastbarBG:SetPoint("BOTTOMRIGHT", Castbar, 0, 0)
		CastbarBG:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
		CastbarBG:SetAlpha(0.2)

		local Background = Castbar:CreateTexture(nil, "BACKGROUND")
		Background:SetPoint("TOPLEFT", Castbar, -(Settings["unitframes-target-cast-height"] + 2), 1)
		Background:SetPoint("BOTTOMRIGHT", Castbar, 1, -1)
		Background:SetTexture(Assets:GetTexture("Blank"))
		Background:SetVertexColor(0, 0, 0)

		local Time = Castbar:CreateFontString(nil, "OVERLAY")
		YxUI:SetFontInfo(Time, Settings["unitframes-font"], Settings["unitframes-font-size"], Settings["unitframes-font-flags"])
		Time:SetPoint("RIGHT", Castbar, -5, 0)
		Time:SetJustifyH("RIGHT")

		local Text = Castbar:CreateFontString(nil, "OVERLAY")
		YxUI:SetFontInfo(Text, Settings["unitframes-font"], Settings["unitframes-font-size"], Settings["unitframes-font-flags"])
		Text:SetPoint("LEFT", Castbar, 5, 0)
		Text:SetSize(Settings["unitframes-target-cast-width"] * 0.7, Settings["unitframes-font-size"])
		Text:SetJustifyH("LEFT")

		local Icon = Castbar:CreateTexture(nil, "OVERLAY")
		Icon:SetSize(Settings["unitframes-target-cast-height"], Settings["unitframes-target-cast-height"])
		Icon:SetPoint("TOPRIGHT", Castbar, "TOPLEFT", -6, 0)
		Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

		local Button = CreateFrame("Frame", nil, Castbar)
		Button:CreateBorder()
		Button:SetAllPoints(Icon)
		Button:SetFrameLevel(Castbar:GetFrameLevel())

		Castbar.bg = CastbarBG
		Castbar.Time = Time
		Castbar.Text = Text
		Castbar.Icon = Icon
		Castbar.showTradeSkills = true
		Castbar.timeToHold = 0.3
		Castbar.ClassColor = Settings["unitframes-target-cast-classcolor"]
		Castbar.PostCastStart = UF.PostCastStart
		Castbar.PostCastStop = UF.PostCastStop
		Castbar.PostCastFail = UF.PostCastFail
		Castbar.PostCastInterruptible = UF.PostCastInterruptible

		self.Castbar = Castbar
		self.CastAnchor = Anchor
	end

	-- Tags
	self:Tag(HealthLeft, Settings["unitframes-target-health-left"])
	self:Tag(HealthRight, Settings["unitframes-target-health-right"])
	self:Tag(PowerLeft, Settings["unitframes-target-power-left"])
	self:Tag(PowerRight, Settings["unitframes-target-power-right"])

	self.Range = {
		insideAlpha = 1,
		outsideAlpha = 0.5,
	}

	self.Health = Health
	self.Health.bg = HealthBG
	self.HealthLeft = HealthLeft
	self.HealthRight = HealthRight
	self.Power = Power
	self.Power.bg = PowerBG
	self.PowerLeft = PowerLeft
	self.PowerRight = PowerRight
	self.Buffs = Buffs
	self.Debuffs = Debuffs
	self.RaidTargetIndicator = RaidTarget
end

local UpdateTargetWidth = function(value)
	if YxUI.UnitFrames["target"] then
		local Frame = YxUI.UnitFrames["target"]

		Frame:SetWidth(value)

		-- Auras
		Frame.Buffs:SetWidth(value)
		Frame.Debuffs:SetWidth(value)
	end
end

local UpdateTargetHealthHeight = function(value)
	if YxUI.UnitFrames["target"] then
		local Frame = YxUI.UnitFrames["target"]

		Frame.Health:SetHeight(value)
		Frame:SetHeight(value + Settings["unitframes-target-power-height"] + 3)
	end
end

local UpdateTargetHealthFill = function(value)
	if YxUI.UnitFrames["target"] then
		local Unit = YxUI.UnitFrames["target"]

		Unit.Health:SetReverseFill(value)
		Unit.HealBar:SetReverseFill(value)
		Unit.HealBar:ClearAllPoints()

		if value then
			Unit.HealBar:SetPoint("RIGHT", Unit.Health:GetStatusBarTexture(), "LEFT", 0, 0)

			if Unit.AbsorbsBar then
				Unit.AbsorbsBar:SetReverseFill(value)
				Unit.AbsorbsBar:ClearAllPoints()
				Unit.AbsorbsBar:SetPoint("RIGHT", Unit.Health:GetStatusBarTexture(), "LEFT", 0, 0)
			end
		else
			Unit.HealBar:SetPoint("LEFT", Unit.Health:GetStatusBarTexture(), "RIGHT", 0, 0)

			if Unit.AbsorbsBar then
				Unit.AbsorbsBar:SetReverseFill(value)
				Unit.AbsorbsBar:ClearAllPoints()
				Unit.AbsorbsBar:SetPoint("LEFT", Unit.Health:GetStatusBarTexture(), "RIGHT", 0, 0)
			end
		end
	end
end

local UpdateTargetPowerHeight = function(value)
	if YxUI.UnitFrames["target"] then
		local Frame = YxUI.UnitFrames["target"]

		Frame.Power:SetHeight(value)
		Frame:SetHeight(Settings["unitframes-target-health-height"] + value + 3)
	end
end

local UpdateTargetPowerFill = function(value)
	if YxUI.UnitFrames["target"] then
		YxUI.UnitFrames["target"].Power:SetReverseFill(value)
	end
end

local UpdateTargetHealthColor = function(value)
	if YxUI.UnitFrames["target"] then
		local Health = YxUI.UnitFrames["target"].Health

		UF:SetHealthAttributes(Health, value)

		Health:ForceUpdate()
	end
end

local UpdateTargetPowerColor = function(value)
	if YxUI.UnitFrames["target"] then
		local Power = YxUI.UnitFrames["target"].Power

		UF:SetPowerAttributes(Power, value)

		Power:ForceUpdate()
	end
end

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
	if YxUI.UnitFrames["target"] then
		if value then
			YxUI.UnitFrames["target"]:EnableElement("Portrait")

			if YxUI.UnitFrames["target"].Portrait.BG then
				YxUI.UnitFrames["target"].Portrait.BG:Show()
			end
		else
			YxUI.UnitFrames["target"]:DisableElement("Portrait")

			if YxUI.UnitFrames["target"].Portrait.BG then
				YxUI.UnitFrames["target"].Portrait.BG:Hide()
			end
		end

		YxUI.UnitFrames["target"].Portrait:ForceUpdate()
	end
end

local UpdateOverlayAlpha = function(value)
	if YxUI.UnitFrames["target"] and Settings["target-portrait-style"] == "OVERLAY" then
		YxUI.UnitFrames["target"].Portrait:SetAlpha(value / 100)
	end
end

local UpdateBuffSize = function(value)
	if YxUI.UnitFrames["target"] then
		YxUI.UnitFrames["target"].Buffs.size = value
		YxUI.UnitFrames["target"].Buffs:SetSize(Settings["unitframes-target-width"], value)
		YxUI.UnitFrames["target"].Buffs:ForceUpdate()
	end
end

local UpdateBuffSpacing = function(value)
	if YxUI.UnitFrames["target"] then
		YxUI.UnitFrames["target"].Buffs.spacing = value
		YxUI.UnitFrames["target"].Buffs:ForceUpdate()
	end
end

local UpdateDebuffSize = function(value)
	if YxUI.UnitFrames["target"] then
		YxUI.UnitFrames["target"].Debuffs.size = value
		YxUI.UnitFrames["target"].Debuffs:SetSize(Settings["unitframes-target-width"], value)
		YxUI.UnitFrames["target"].Debuffs:ForceUpdate()
	end
end

local UpdateDebuffSpacing = function(value)
	if YxUI.UnitFrames["target"] then
		YxUI.UnitFrames["target"].Debuffs.spacing = value
		YxUI.UnitFrames["target"].Debuffs:ForceUpdate()
	end
end

local UpdateDisplayedAuras = function()
	if (not YxUI.UnitFrames["target"]) then
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

local UpdateHealthTexture = function(value)
	if YxUI.UnitFrames["target"] then
		local Frame = YxUI.UnitFrames["target"]

		Frame.Health:SetStatusBarTexture(Assets:GetTexture(value))
		Frame.Health.bg:SetTexture(Assets:GetTexture(value))
		Frame.HealBar:SetStatusBarTexture(Assets:GetTexture(value))

		if Frame.AbsorbsBar then
			Frame.AbsorbsBar:SetStatusBarTexture(Assets:GetTexture(value))
		end
	end
end

local UpdatePowerTexture = function(value)
	if YxUI.UnitFrames["target"] then
		local Frame = YxUI.UnitFrames["target"]

		Frame.Power:SetStatusBarTexture(Assets:GetTexture(value))
		Frame.Power.bg:SetTexture(Assets:GetTexture(value))
	end
end

YxUI:GetModule("GUI"):AddWidgets(Language["General"], Language["Target"], Language["Unit Frames"], function(left, right)
	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("target-enable", Settings["target-enable"], Language["Enable Target"], Language["Enable the target unit frame"], ReloadUI):RequiresReload(true)
	left:CreateSlider("unitframes-target-width", Settings["unitframes-target-width"], 120, 320, 1, "Width", "Set the width of the target unit frame", UpdateTargetWidth)
	left:CreateSwitch("unitframes-only-player-debuffs", Settings["unitframes-only-player-debuffs"], Language["Only Display Player Debuffs"], Language["If enabled, only your own debuffs will be displayed on the target"], UpdateOnlyPlayerDebuffs)
	left:CreateSwitch("target-enable-portrait", Settings["target-enable-portrait"], Language["Enable Portrait"], Language["Display the target unit portrait"], UpdateTargetEnablePortrait)
	left:CreateDropdown("target-portrait-style", Settings["target-portrait-style"], {[Language["2D"]] = "2D", [Language["3D"]] = "3D", [Language["Overlay"]] = "OVERLAY"}, Language["Set Portrait Style"], Language["Set the style of the portrait"], ReloadUI):RequiresReload(true)
	left:CreateSlider("target-overlay-alpha", Settings["target-overlay-alpha"], 0, 100, 5, Language["Set Overlay Opacity"], Language["Set the opacity of the portrait overlay"], UpdateOverlayAlpha, nil, "%")

	left:CreateHeader(Language["Health"])
	left:CreateSwitch("unitframes-target-health-reverse", Settings["unitframes-target-health-reverse"], Language["Reverse Health Fill"], Language["Reverse the fill of the health bar"], UpdateTargetHealthFill)
	left:CreateSlider("unitframes-target-health-height", Settings["unitframes-target-health-height"], 6, 60, 1, "Health Bar Height", "Set the height of the target health bar", UpdateTargetHealthHeight)
	left:CreateDropdown("unitframes-target-health-color", Settings["unitframes-target-health-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Custom"]] = "CUSTOM"}, Language["Health Color"], Language["Set the color of the health bar"], UpdateTargetHealthColor)
	left:CreateInput("unitframes-target-health-left", Settings["unitframes-target-health-left"], Language["Left Health Text"], Language["Set the text on the left of the target health bar"], ReloadUI):RequiresReload(true)
	left:CreateInput("unitframes-target-health-right", Settings["unitframes-target-health-right"], Language["Right Health Text"], Language["Set the text on the right of the target health bar"], ReloadUI):RequiresReload(true)
	left:CreateDropdown("TargetHealthTexture", Settings.TargetHealthTexture, Assets:GetTextureList(), Language["Health Texture"], "", UpdateHealthTexture, "Texture")

	left:CreateHeader(Language["Buffs"])
	left:CreateSwitch("unitframes-show-target-buffs", Settings["unitframes-show-target-buffs"], Language["Show Buffs"], Language["Show auras above the target unit frame"], UpdateDisplayedAuras)
	left:CreateSlider("TargetBuffSize", Settings.TargetBuffSize, 26, 50, 2, "Set Size", "Set the size of the auras", UpdateBuffSize)
	left:CreateSlider("TargetBuffSpacing", Settings.TargetBuffSpacing, -1, 10, 1, "Set Spacing", "Set the spacing between the auras", UpdateBuffSpacing)

	left:CreateHeader(Language["Debuffs"])
	left:CreateSwitch("unitframes-show-target-debuffs", Settings["unitframes-show-target-debuffs"], Language["Show Debuffs"], Language["Show your debuff auras above the target unit frame"], UpdateDisplayedAuras)
	left:CreateSlider("TargetDebuffSize", Settings.TargetDebuffSize, 26, 50, 2, "Set Size", "Set the size of the auras", UpdateDebuffSize)
	left:CreateSlider("TargetDebuffSpacing", Settings.TargetDebuffSpacing, -1, 10, 1, "Set Spacing", "Set the spacing between the auras", UpdateDebuffSpacing)

	right:CreateHeader(Language["Power"])
	right:CreateSwitch("unitframes-target-power-reverse", Settings["unitframes-target-power-reverse"], Language["Reverse Power Fill"], Language["Reverse the fill of the power bar"], UpdateTargetPowerFill)
	right:CreateSlider("unitframes-target-power-height", Settings["unitframes-target-power-height"], 2, 30, 1, "Power Bar Height", "Set the height of the target power bar", UpdateTargetPowerHeight)
	right:CreateDropdown("unitframes-target-power-color", Settings["unitframes-target-power-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Power Type"]] = "POWER"}, Language["Power Bar Color"], Language["Set the color of the power bar"], UpdateTargetPowerColor)
	right:CreateInput("unitframes-target-power-left", Settings["unitframes-target-power-left"], Language["Left Power Text"], Language["Set the text on the left of the target power bar"], ReloadUI):RequiresReload(true)
	right:CreateInput("unitframes-target-power-right", Settings["unitframes-target-power-right"], Language["Right Power Text"], Language["Set the text on the right of the target power bar"], ReloadUI):RequiresReload(true)
	right:CreateDropdown("TargetPowerTexture", Settings.TargetPowerTexture, Assets:GetTextureList(), Language["Power Texture"], "", UpdatePowerTexture, "Texture")

	right:CreateHeader(Language["Cast Bar"])
	right:CreateSwitch("unitframes-target-enable-castbar", Settings["unitframes-target-enable-castbar"], Language["Enable Cast Bar"], Language["Enable the target cast bar"], ReloadUI):RequiresReload(true)
	right:CreateSwitch("unitframes-target-cast-classcolor", Settings["unitframes-target-cast-classcolor"], Language["Enable Class Color"], Language["Use class colors"], UpdateCastClassColor)

	right:CreateSlider("unitframes-target-cast-width", Settings["unitframes-target-cast-width"], 80, 360, 1, Language["Cast Bar Width"], Language["Set the width of the target cast bar"], UpdateTargetCastBarSize)
	right:CreateSlider("unitframes-target-cast-height", Settings["unitframes-target-cast-height"], 8, 50, 1, Language["Cast Bar Height"], Language["Set the height of the target cast bar"], UpdateTargetCastBarSize)
end)