local YxUI, Language, Assets, Settings, Defaults = select(2, ...):get()

Defaults["unitframes-targettarget-width"] = 110
Defaults["unitframes-targettarget-health-height"] = 26
Defaults["unitframes-targettarget-health-reverse"] = false
Defaults["unitframes-targettarget-health-color"] = "CLASS"
Defaults["unitframes-targettarget-health-smooth"] = true
Defaults["unitframes-targettarget-enable-power"] = true
Defaults["unitframes-targettarget-power-height"] = 10
Defaults["unitframes-targettarget-power-reverse"] = false
Defaults["unitframes-targettarget-power-color"] = "POWER"
Defaults["unitframes-targettarget-power-smooth"] = true
Defaults["unitframes-targettarget-health-left"] = "[Name(10)]"
Defaults["unitframes-targettarget-health-right"] = "[HealthPercent]"
Defaults["unitframes-targettarget-debuffs"] = true
Defaults["unitframes-targettarget-debuff-size"] = 20
Defaults["unitframes-targettarget-debuff-pos"] = "BOTTOM"
Defaults["tot-enable"] = true
Defaults.ToTHealthTexture = "YxUI 4"
Defaults.ToTPowerTexture = "YxUI 4"

local UF = YxUI:GetModule("Unit Frames")

YxUI.StyleFuncs["targettarget"] = function(self, unit)
	-- General
	self:RegisterForClicks("AnyUp")
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

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
	Health:SetHeight(Settings["unitframes-targettarget-health-height"])
	Health:SetStatusBarTexture(Assets:GetTexture(Settings.ToTHealthTexture))
	Health:SetReverseFill(Settings["unitframes-targettarget-health-reverse"])
    Health:CreateBorder()

	local HealBar = CreateFrame("StatusBar", nil, Health)
	HealBar:SetWidth(Settings["unitframes-targettarget-width"])
	HealBar:SetHeight(Settings["unitframes-targettarget-health-height"])
	HealBar:SetStatusBarTexture(Assets:GetTexture(Settings.ToTHealthTexture))
	HealBar:SetStatusBarColor(0, 0.48, 0)
	HealBar:SetFrameLevel(Health:GetFrameLevel() - 1)

	if Settings["unitframes-targettarget-health-reverse"] then
		HealBar:SetPoint("RIGHT", Health:GetStatusBarTexture(), "LEFT", 0, 0)
	else
		HealBar:SetPoint("LEFT", Health:GetStatusBarTexture(), "RIGHT", 0, 0)
	end

	self.HealBar = HealBar

	if YxUI.IsMainline then
		local AbsorbsBar = CreateFrame("StatusBar", nil, Health)
		AbsorbsBar:SetWidth(Settings["unitframes-targettarget-width"])
		AbsorbsBar:SetHeight(Settings["unitframes-targettarget-health-height"])
		AbsorbsBar:SetStatusBarTexture(Assets:GetTexture(Settings.ToTHealthTexture))
		AbsorbsBar:SetStatusBarColor(0, 0.66, 1)
		AbsorbsBar:SetFrameLevel(Health:GetFrameLevel() - 2)

		if Settings["unitframes-targettarget-health-reverse"] then
			AbsorbsBar:SetPoint("RIGHT", Health:GetStatusBarTexture(), "LEFT", 0, 0)
		else
			AbsorbsBar:SetPoint("LEFT", Health:GetStatusBarTexture(), "RIGHT", 0, 0)
		end

		self.AbsorbsBar = AbsorbsBar
	end

	local HealthBG = self:CreateTexture(nil, "BORDER")
	HealthBG:SetAllPoints(Health)
	HealthBG:SetTexture(Assets:GetTexture(Settings.ToTHealthTexture))
	HealthBG.multiplier = 0.2

	local HealthLeft = Health:CreateFontString(nil, "OVERLAY")
	YxUI:SetFontInfo(HealthLeft, Settings["unitframes-font"], Settings["unitframes-font-size"], Settings["unitframes-font-flags"])
	HealthLeft:SetPoint("LEFT", Health, 3, 0)
	HealthLeft:SetJustifyH("LEFT")

	local HealthRight = Health:CreateFontString(nil, "OVERLAY")
	YxUI:SetFontInfo(HealthRight, Settings["unitframes-font"], Settings["unitframes-font-size"], Settings["unitframes-font-flags"])
	HealthRight:SetPoint("RIGHT", Health, -3, 0)
	HealthRight:SetJustifyH("RIGHT")

	-- Target Icon
	local RaidTargetIndicator = Health:CreateTexture(nil, 'OVERLAY')
	RaidTargetIndicator:SetSize(16, 16)
	RaidTargetIndicator:SetPoint("CENTER", Health, "TOP")

	local R, G, B = YxUI:HexToRGB(Settings["ui-header-texture-color"])

	-- Attributes
	Health.colorTapping = true
	Health.colorDisconnected = true
	Health.Smooth = true
	self.colors.health = {R, G, B}

	UF:SetHealthAttributes(Health, Settings["unitframes-targettarget-health-color"])

	-- Power Bar
	local Power = CreateFrame("StatusBar", nil, self)
	Power:SetPoint("BOTTOMLEFT", self, 1, 1)
	Power:SetPoint("BOTTOMRIGHT", self, -1, 1)
	Power:SetHeight(Settings["unitframes-targettarget-power-height"])
	Power:SetStatusBarTexture(Assets:GetTexture(Settings.ToTPowerTexture))
	Power:SetReverseFill(Settings["unitframes-targettarget-power-reverse"])
    Power:CreateBorder()

	local PowerBG = Power:CreateTexture(nil, "BORDER")
	PowerBG:SetPoint("TOPLEFT", Power, 0, 0)
	PowerBG:SetPoint("BOTTOMRIGHT", Power, 0, 0)
	PowerBG:SetTexture(Assets:GetTexture(Settings.ToTPowerTexture))
	PowerBG:SetAlpha(0.2)

	-- Attributes
	Power.frequentUpdates = true
	Power.colorReaction = true
	Power.Smooth = true

	UF:SetPowerAttributes(Power, Settings["unitframes-targettarget-power-color"])

	if Settings["unitframes-targettarget-debuffs"] then
		local Debuffs = CreateFrame("Frame", self:GetName() .. "Debuffs", self)
		Debuffs:SetSize(Settings["unitframes-targettarget-width"], Settings["unitframes-targettarget-debuff-size"])
		Debuffs.size = Settings["unitframes-targettarget-debuff-size"]
		Debuffs.spacing = 2
		Debuffs.num = 5
		Debuffs.tooltipAnchor = "ANCHOR_TOP"
		Debuffs.PostCreateIcon = UF.PostCreateIcon
		Debuffs.PostUpdateIcon = UF.PostUpdateIcon

		if (Settings["unitframes-targettarget-debuff-pos"] == "TOP") then
			Debuffs:SetPoint("BOTTOM", self, "TOP", 0, 2)
			Debuffs.initialAnchor = "TOPRIGHT"
			Debuffs["growth-x"] = "LEFT"
			Debuffs["growth-y"] = "DOWN"
		else
			Debuffs:SetPoint("TOP", self, "BOTTOM", 0, -2)
			Debuffs.initialAnchor = "TOPRIGHT"
			Debuffs["growth-x"] = "LEFT"
			Debuffs["growth-y"] = "DOWN"
		end

		self.Debuffs = Debuffs
	end

	self:Tag(HealthLeft, Settings["unitframes-targettarget-health-left"])
	self:Tag(HealthRight, Settings["unitframes-targettarget-health-right"])

	self.Range = {
		insideAlpha = 1,
		outsideAlpha = 0.5,
	}

	self.Health = Health
	self.Health.bg = HealthBG
	self.Power = Power
	self.Power.bg = PowerBG
	self.HealthLeft = HealthLeft
	self.HealthRight = HealthRight
	self.RaidTargetIndicator = RaidTargetIndicator
end

local UpdateTargetTargetWidth = function(value)
	if YxUI.UnitFrames["target"] then
		YxUI.UnitFrames["targettarget"]:SetWidth(value)
	end
end

local UpdateTargetTargetHealthHeight = function(value)
	if YxUI.UnitFrames["targettarget"] then
		YxUI.UnitFrames["targettarget"].Health:SetHeight(value)
		YxUI.UnitFrames["targettarget"]:SetHeight(value + Settings["unitframes-targettarget-power-height"] + 3)
	end
end

local UpdateTargetTargetPowerHeight = function(value)
	if YxUI.UnitFrames["targettarget"] then
		local Frame = YxUI.UnitFrames["targettarget"]

		Frame.Power:SetHeight(value)
		Frame:SetHeight(Settings["unitframes-targettarget-health-height"] + value + 3)
	end
end

local UpdateTargetTargetHealthColor = function(value)
	if YxUI.UnitFrames["targettarget"] then
		local Health = YxUI.UnitFrames["targettarget"].Health

		UF:SetHealthAttributes(Health, value)

		Health:ForceUpdate()
	end
end

local UpdateTargetTargetHealthFill = function(value)
	if YxUI.UnitFrames["targettarget"] then
		local Unit = YxUI.UnitFrames["targettarget"]

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

local UpdateTargetTargetPowerColor = function(value)
	if YxUI.UnitFrames["targettarget"] then
		local Power = YxUI.UnitFrames["targettarget"].Power

		UF:SetPowerAttributes(Power, value)

		Power:ForceUpdate()
	end
end

local UpdateTargetTargetPowerFill = function(value)
	if YxUI.UnitFrames["targettarget"] then
		YxUI.UnitFrames["targettarget"].Power:SetReverseFill(value)
	end
end

local UpdateEnableDebuffs = function(value)
	if YxUI.UnitFrames["targettarget"] then
		if value then
			YxUI.UnitFrames["targettarget"]:EnableElement("Debuffs")
		else
			YxUI.UnitFrames["targettarget"]:DisableElement("Debuffs")
		end
	end
end

local UpdateDebuffSize = function(value)
	if YxUI.UnitFrames["targettarget"] then
		YxUI.UnitFrames["targettarget"].Debuffs.size = value
		YxUI.UnitFrames["targettarget"].Debuffs:SetSize(Settings["unitframes-targettarget-width"], value)
		YxUI.UnitFrames["targettarget"].Debuffs:ForceUpdate()
	end
end

local UpdateDebuffPosition = function(value)
	if YxUI.UnitFrames["targettarget"] then
		local Unit = YxUI.UnitFrames["targettarget"]

		Unit.Debuffs:ClearAllPoints()

		if (value == "TOP") then
			Unit.Debuffs:SetPoint("BOTTOM", self, "TOP", 0, 2)
			Unit.Debuffs["growth-x"] = "LEFT"
			Unit.Debuffs["growth-y"] = "UP"
		else
			Unit.Debuffs:SetPoint("TOP", self, "BOTTOM", 0, -2)
			Unit.Debuffs["growth-x"] = "LEFT"
			Unit.Debuffs["growth-y"] = "DOWN"
		end
	end
end

local UpdateHealthTexture = function(value)
	if YxUI.UnitFrames["targettarget"] then
		local Frame = YxUI.UnitFrames["targettarget"]

		Frame.Health:SetStatusBarTexture(Assets:GetTexture(value))
		Frame.Health.bg:SetTexture(Assets:GetTexture(value))
		Frame.HealBar:SetStatusBarTexture(Assets:GetTexture(value))

		if Frame.AbsorbsBar then
			Frame.AbsorbsBar:SetStatusBarTexture(Assets:GetTexture(value))
		end
	end
end

local UpdatePowerTexture = function(value)
	if YxUI.UnitFrames["targettarget"] then
		local Frame = YxUI.UnitFrames["targettarget"]

		Frame.Power:SetStatusBarTexture(Assets:GetTexture(value))
		Frame.Power.bg:SetTexture(Assets:GetTexture(value))
	end
end

YxUI:GetModule("GUI"):AddWidgets(Language["General"], Language["Target of Target"], Language["Unit Frames"], function(left, right)
	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("tot-enable", Settings["tot-enable"], Language["Enable Target Target"], Language["Enable the target of target unit frame"], ReloadUI):RequiresReload(true)
	left:CreateSlider("unitframes-targettarget-width", Settings["unitframes-targettarget-width"], 60, 320, 1, Language["Width"], Language["Set the width of the target's target unit frame"], UpdateTargetTargetWidth)

	left:CreateHeader(Language["Health"])
	left:CreateSwitch("unitframes-targettarget-health-reverse", Settings["unitframes-targettarget-health-reverse"], Language["Reverse Health Fill"], Language["Reverse the fill of the health bar"], UpdateTargetTargetHealthFill)
	left:CreateSlider("unitframes-targettarget-health-height", Settings["unitframes-targettarget-health-height"], 6, 60, 1, Language["Health Bar Height"], Language["Set the height of the target of target health bar"], UpdateTargetTargetHealthHeight)
	left:CreateDropdown("unitframes-targettarget-health-color", Settings["unitframes-targettarget-health-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Custom"]] = "CUSTOM"}, Language["Health Bar Color"], Language["Set the color of the health bar"], UpdateTargetTargetHealthColor)
	left:CreateInput("unitframes-targettarget-health-left", Settings["unitframes-targettarget-health-left"], Language["Left Health Text"], Language["Set the text on the left of the target of target health bar"], ReloadUI):RequiresReload(true)
	left:CreateInput("unitframes-targettarget-health-right", Settings["unitframes-targettarget-health-right"], Language["Right Health Text"], Language["Set the text on the right of the target of target health bar"], ReloadUI):RequiresReload(true)

	left:CreateDropdown("ToTHealthTexture", Settings.ToTHealthTexture, Assets:GetTextureList(), Language["Health Texture"], "", UpdateHealthTexture, "Texture")

	right:CreateHeader(Language["Power"])
	right:CreateSwitch("unitframes-targettarget-power-reverse", Settings["unitframes-targettarget-power-reverse"], Language["Reverse Power Fill"], Language["Reverse the fill of the power bar"], UpdateTargetTargetPowerFill)
	right:CreateSlider("unitframes-targettarget-power-height", Settings["unitframes-targettarget-power-height"], 1, 30, 1, Language["Power Bar Height"], Language["Set the height of the target of target power bar"], UpdateTargetTargetPowerHeight)
	right:CreateDropdown("unitframes-targettarget-power-color", Settings["unitframes-targettarget-power-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Power Type"]] = "POWER"}, Language["Power Bar Color"], Language["Set the color of the power bar"], UpdateTargetTargetPowerColor)

	right:CreateDropdown("ToTPowerTexture", Settings.ToTPowerTexture, Assets:GetTextureList(), Language["Power Texture"], "", UpdatePowerTexture, "Texture")

	right:CreateHeader(Language["Debuffs"])
	right:CreateSwitch("unitframes-targettarget-debuffs", Settings["unitframes-targettarget-debuffs"], Language["Enable Debuffs"], Language["Enable debuffs on the unit frame"], UpdateEnableDebuffs)
	right:CreateSlider("unitframes-targettarget-debuff-size", Settings["unitframes-targettarget-debuff-size"], 10, 40, 1, Language["Debuff Size"], Language["Set the size of the debuff icons"], UpdateDebuffSize)
	right:CreateDropdown("unitframes-targettarget-debuff-pos", Settings["unitframes-targettarget-debuff-pos"], {[Language["Bottom"]] = "BOTTOM", [Language["Top"]] = "TOP"}, Language["Set Position"], Language["Set the position of the debuffs"], UpdateDebuffPosition)
end)