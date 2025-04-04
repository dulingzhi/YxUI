local YxUI, Language, Assets, Settings, Defaults = select(2, ...):get()

Defaults["unitframes-pet-width"] = 110
Defaults["unitframes-pet-health-height"] = 26
Defaults["unitframes-pet-health-reverse"] = false
Defaults["unitframes-pet-health-color"] = "CLASS"
Defaults["unitframes-pet-health-smooth"] = true
Defaults["unitframes-pet-enable-power"] = true
Defaults["unitframes-pet-power-height"] = 10
Defaults["unitframes-pet-power-reverse"] = false
Defaults["unitframes-pet-power-color"] = "POWER"
Defaults["unitframes-pet-power-smooth"] = true
Defaults["unitframes-pet-health-right"] = "[HealthPercent]"
Defaults["unitframes-pet-buffs"] = true
Defaults["unitframes-pet-buff-size"] = 20
Defaults["unitframes-pet-buff-pos"] = "BOTTOM"
Defaults["unitframes-pet-debuff-size"] = 20
Defaults["unitframes-pet-debuff-pos"] = "BOTTOM"
Defaults["pet-enable"] = true
Defaults.PetHealthTexture = "YxUI 4"
Defaults.PetPowerTexture = "YxUI 4"

if YxUI.IsMainline then
	Defaults["unitframes-pet-health-left"] = "[Name(10)]"
else
	Defaults["unitframes-pet-health-left"] = "[HappinessColor][Name(10)]"
end

local UF = YxUI:GetModule("Unit Frames")

YxUI.StyleFuncs["pet"] = function(self, unit)
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
	Health:SetHeight(Settings["unitframes-pet-health-height"])
	Health:SetStatusBarTexture(Assets:GetTexture(Settings.PetHealthTexture))
	Health:SetReverseFill(Settings["unitframes-pet-health-reverse"])
    Health:CreateBorder()

	local HealBar = CreateFrame("StatusBar", nil, Health)
	HealBar:SetWidth(Settings["unitframes-pet-width"])
	HealBar:SetHeight(Settings["unitframes-pet-health-height"])
	HealBar:SetStatusBarTexture(Assets:GetTexture(Settings.PetHealthTexture))
	HealBar:SetStatusBarColor(0, 0.48, 0)
	HealBar:SetFrameLevel(Health:GetFrameLevel() - 1)

	if Settings["unitframes-pet-health-reverse"] then
		HealBar:SetPoint("RIGHT", Health:GetStatusBarTexture(), "LEFT", 0, 0)
	else
		HealBar:SetPoint("LEFT", Health:GetStatusBarTexture(), "RIGHT", 0, 0)
	end

	self.HealBar = HealBar

	if YxUI.IsMainline then
		local AbsorbsBar = CreateFrame("StatusBar", nil, Health)
		AbsorbsBar:SetWidth(Settings["unitframes-pet-width"])
		AbsorbsBar:SetHeight(Settings["unitframes-pet-health-height"])
		AbsorbsBar:SetStatusBarTexture(Assets:GetTexture(Settings.PetHealthTexture))
		AbsorbsBar:SetStatusBarColor(0, 0.66, 1)
		AbsorbsBar:SetFrameLevel(Health:GetFrameLevel() - 2)

		if Settings["unitframes-pet-health-reverse"] then
			AbsorbsBar:SetPoint("RIGHT", Health:GetStatusBarTexture(), "LEFT", 0, 0)
		else
			AbsorbsBar:SetPoint("LEFT", Health:GetStatusBarTexture(), "RIGHT", 0, 0)
		end

		self.AbsorbsBar = AbsorbsBar
	end

	local HealthBG = self:CreateTexture(nil, "BORDER")
	HealthBG:SetAllPoints(Health)
	HealthBG:SetTexture(Assets:GetTexture(Settings.PetHealthTexture))
	HealthBG.multiplier = 0.2

	local HealthLeft = Health:CreateFontString(nil, "OVERLAY")
	YxUI:SetFontInfo(HealthLeft, Settings["unitframes-font"], Settings["unitframes-font-size"], Settings["unitframes-font-flags"])
	HealthLeft:SetPoint("LEFT", Health, 3, 0)
	HealthLeft:SetJustifyH("LEFT")

	local HealthRight = Health:CreateFontString(nil, "OVERLAY")
	YxUI:SetFontInfo(HealthRight, Settings["unitframes-font"], Settings["unitframes-font-size"], Settings["unitframes-font-flags"])
	HealthRight:SetPoint("RIGHT", Health, -3, 0)
	HealthRight:SetJustifyH("RIGHT")

	local R, G, B = YxUI:HexToRGB(Settings["ui-header-texture-color"])

	-- Attributes
	Health.colorTapping = true
	Health.colorDisconnected = true
	Health.Smooth = true
	self.colors.health = {R, G, B}

	UF:SetHealthAttributes(Health, Settings["unitframes-pet-health-color"])

	-- Power Bar
	local Power = CreateFrame("StatusBar", nil, self)
	Power:SetPoint("BOTTOMLEFT", self, 1, 1)
	Power:SetPoint("BOTTOMRIGHT", self, -1, 1)
	Power:SetHeight(Settings["unitframes-pet-power-height"])
	Power:SetStatusBarTexture(Assets:GetTexture(Settings.PetPowerTexture))
	Power:SetReverseFill(Settings["unitframes-pet-power-reverse"])
    Power:CreateBorder()

	local PowerBG = Power:CreateTexture(nil, "BORDER")
	PowerBG:SetPoint("TOPLEFT", Power, 0, 0)
	PowerBG:SetPoint("BOTTOMRIGHT", Power, 0, 0)
	PowerBG:SetTexture(Assets:GetTexture(Settings.PetPowerTexture))
	PowerBG:SetAlpha(0.2)

	-- Attributes
	Power.frequentUpdates = true
	Power.colorReaction = true
	Power.Smooth = true

	UF:SetPowerAttributes(Power, Settings["unitframes-pet-power-color"])

	if Settings["unitframes-pet-buffs"] then
		local Buffs = CreateFrame("Frame", self:GetName() .. "Buffs", self)
		Buffs:SetSize(Settings["unitframes-pet-width"], Settings["unitframes-pet-buff-size"])
		Buffs.size = Settings["unitframes-pet-buff-size"]
		Buffs.spacing = 2
		Buffs.num = 5
		Buffs.tooltipAnchor = "ANCHOR_TOP"
		Buffs.PostCreateIcon = UF.PostCreateIcon
		Buffs.PostUpdateIcon = UF.PostUpdateIcon

		if (Settings["unitframes-pet-buff-pos"] == "TOP") then
			Buffs:SetPoint("BOTTOM", self, "TOP", 0, 2)
			Buffs.initialAnchor = "TOPLEFT"
			Buffs["growth-x"] = "RIGHT"
			Buffs["growth-y"] = "UP"
		else
			Buffs:SetPoint("TOP", self, "BOTTOM", 0, -2)
			Buffs.initialAnchor = "TOPLEFT"
			Buffs["growth-x"] = "RIGHT"
			Buffs["growth-y"] = "DOWN"
		end

		self.Buffs = Buffs
	end

	if Settings["unitframes-pet-debuffs"] then
		local Debuffs = CreateFrame("Frame", self:GetName() .. "Debuffs", self)
		Debuffs:SetSize(Settings["unitframes-pet-width"], Settings["unitframes-pet-debuff-size"])
		Debuffs.size = Settings["unitframes-pet-debuff-size"]
		Debuffs.spacing = 2
		Debuffs.num = 5
		Debuffs.tooltipAnchor = "ANCHOR_TOP"
		Debuffs.PostCreateIcon = UF.PostCreateIcon
		Debuffs.PostUpdateIcon = UF.PostUpdateIcon

		if (Settings["unitframes-pet-debuff-pos"] == "TOP") then
			if self.Buffs then
				if (Settings["unitframes-pet-buff-pos"] == "TOP") then
					Debuffs:SetPoint("BOTTOM", self.Buffs or self, "TOP", 0, 2)
				else
					Debuffs:SetPoint("BOTTOM", self, "TOP", 0, 2)
				end
			else
				Debuffs:SetPoint("BOTTOM", self, "TOP", 0, 2)
			end

			Debuffs.initialAnchor = "TOPRIGHT"
			Debuffs["growth-x"] = "LEFT"
			Debuffs["growth-y"] = "DOWN"
			Debuffs["growth-y"] = "UP"
		else
			if self.Buffs then
				if (Settings["unitframes-pet-buff-pos"] == "BOTTOM") then
					Debuffs:SetPoint("TOP", self.Buffs or self, "BOTTOM", 0, -2)
				else
					Debuffs:SetPoint("TOP", self, "BOTTOM", 0, -2)
				end
			else
				Debuffs:SetPoint("TOP", self, "BOTTOM", 0, -2)
			end
		end

		self.Debuffs = Debuffs
	end

	self:Tag(HealthLeft, Settings["unitframes-pet-health-left"])
	self:Tag(HealthRight, Settings["unitframes-pet-health-right"])

	self.Range = {
		insideAlpha = 1,
		outsideAlpha = 0.5,
	}

	self.Health = Health
	self.Health.bg = HealthBG
	self.HealthLeft = HealthLeft
	self.Power = Power
	self.Power.bg = PowerBG
end

local UpdatePetWidth = function(value)
	if YxUI.UnitFrames["pet"] then
		YxUI.UnitFrames["pet"]:SetWidth(value)
	end
end

local UpdatePetHealthHeight = function(value)
	if YxUI.UnitFrames["pet"] then
		YxUI.UnitFrames["pet"].Health:SetHeight(value)
		YxUI.UnitFrames["pet"]:SetHeight(value + Settings["unitframes-pet-power-height"] + 3)
	end
end

local UpdatePetPowerHeight = function(value)
	if YxUI.UnitFrames["pet"] then
		local Frame = YxUI.UnitFrames["pet"]

		Frame.Power:SetHeight(value)
		Frame:SetHeight(Settings["unitframes-pet-health-height"] + value + 3)
	end
end

local UpdatePetHealthColor = function(value)
	if YxUI.UnitFrames["pet"] then
		local Health = YxUI.UnitFrames["pet"].Health

		UF:SetHealthAttributes(Health, value)

		Health:ForceUpdate()
	end
end

local UpdatePetHealthFill = function(value)
	if YxUI.UnitFrames["pet"] then
		local Unit = YxUI.UnitFrames["pet"]

		Unit.Health:SetReverseFill(value)
		Unit.HealBar:SetReverseFill(value)
		Unit.HealBar:ClearAllPoints()

		if value then
			Unit.HealBar:SetPoint("RIGHT", Unit.Health:GetStatusBarTexture(), "LEFT", 0, 0)

			if Unit.AbsorbsBar then
				Unit.AbsorbsBar:ClearAllPoints()
				Unit.AbsorbsBar:SetReverseFill(value)
				Unit.AbsorbsBar:SetPoint("RIGHT", Unit.Health:GetStatusBarTexture(), "LEFT", 0, 0)
			end
		else
			Unit.HealBar:SetPoint("LEFT", Unit.Health:GetStatusBarTexture(), "RIGHT", 0, 0)

			if Unit.AbsorbsBar then
				Unit.AbsorbsBar:ClearAllPoints()
				Unit.AbsorbsBar:SetReverseFill(value)
				Unit.AbsorbsBar:SetPoint("LEFT", Unit.Health:GetStatusBarTexture(), "RIGHT", 0, 0)
			end
		end
	end
end

local UpdatePetPowerColor = function(value)
	if YxUI.UnitFrames["pet"] then
		local Power = YxUI.UnitFrames["pet"].Power

		UF:SetPowerAttributes(Power, value)

		Power:ForceUpdate()
	end
end

local UpdatePetPowerFill = function(value)
	if YxUI.UnitFrames["pet"] then
		YxUI.UnitFrames["pet"].Power:SetReverseFill(value)
	end
end

local UpdateEnableBuffs = function(value)
	if YxUI.UnitFrames["pet"] then
		if value then
			YxUI.UnitFrames["pet"]:EnableElement("Buffs")
		else
			YxUI.UnitFrames["pet"]:DisableElement("Buffs")
		end
	end
end

local UpdateBuffSize = function(value)
	if YxUI.UnitFrames["pet"] then
		YxUI.UnitFrames["pet"].Buffs.size = value
		YxUI.UnitFrames["pet"].Buffs:SetSize(Settings["unitframes-pet-width"], value)
		YxUI.UnitFrames["pet"].Buffs:ForceUpdate()
	end
end

local UpdateBuffPosition = function(value)
	if YxUI.UnitFrames["pet"] then
		local Unit = YxUI.UnitFrames["pet"]

		Unit.Buffs:ClearAllPoints()

		if (value == "TOP") then
			Unit.Buffs:SetPoint("BOTTOM", Unit, "TOP", 0, 2)
			Unit.Buffs["growth-x"] = "LEFT"
			Unit.Buffs["growth-y"] = "UP"
		else
			Unit.Buffs:SetPoint("TOP", Unit, "BOTTOM", 0, -2)
			Unit.Buffs["growth-x"] = "LEFT"
			Unit.Buffs["growth-y"] = "DOWN"
		end
	end
end

local UpdateDebuffSize = function(value)
	if YxUI.UnitFrames["pet"] then
		YxUI.UnitFrames["pet"].Debuffs.size = value
		YxUI.UnitFrames["pet"].Debuffs:SetSize(Settings["unitframes-pet-width"], value)
		YxUI.UnitFrames["pet"].Debuffs:ForceUpdate()
	end
end

local UpdateDebuffPosition = function(value)
	if YxUI.UnitFrames["pet"] then
		local Unit = YxUI.UnitFrames["pet"]

		Unit.Debuffs:ClearAllPoints()

		if (value == "TOP") then
			if Unit.Buffs then
				if (Settings["unitframes-pet-buff-pos"] == "TOP") then
					Unit.Debuffs:SetPoint("BOTTOM", Unit.Buffs or Unit, "TOP", 0, 2)
				else
					Unit.Debuffs:SetPoint("BOTTOM", Unit, "TOP", 0, 2)
				end
			else
				Unit.Debuffs:SetPoint("BOTTOM", Unit, "TOP", 0, 2)
			end

			Unit.Debuffs["growth-x"] = "LEFT"
			Unit.Debuffs["growth-y"] = "UP"
		else
			if Unit.Buffs then
				if (Settings["unitframes-pet-buff-pos"] == "BOTTOM") then
					Unit.Debuffs:SetPoint("TOP", Unit.Buffs or Unit, "BOTTOM", 0, -2)
				else
					Unit.Debuffs:SetPoint("TOP", Unit, "BOTTOM", 0, -2)
				end
			else
				Unit.Debuffs:SetPoint("TOP", Unit, "BOTTOM", 0, -2)
			end

			Unit.Debuffs:SetPoint("TOP", Unit.Buffs or Unit, "BOTTOM", 0, -2)
			Unit.Debuffs["growth-x"] = "LEFT"
			Unit.Debuffs["growth-y"] = "DOWN"
		end
	end
end

local UpdateHealthTexture = function(value)
	if YxUI.UnitFrames["pet"] then
		local Frame = YxUI.UnitFrames["pet"]

		Frame.Health:SetStatusBarTexture(Assets:GetTexture(value))
		Frame.Health.bg:SetTexture(Assets:GetTexture(value))
		Frame.HealBar:SetStatusBarTexture(Assets:GetTexture(value))

		if Frame.AbsorbsBar then
			Frame.AbsorbsBar:SetStatusBarTexture(Assets:GetTexture(value))
		end
	end
end

local UpdatePowerTexture = function(value)
	if YxUI.UnitFrames["pet"] then
		local Frame = YxUI.UnitFrames["pet"]

		Frame.Power:SetStatusBarTexture(Assets:GetTexture(value))
		Frame.Power.bg:SetTexture(Assets:GetTexture(value))
	end
end

YxUI:GetModule("GUI"):AddWidgets(Language["General"], Language["Pet"], Language["Unit Frames"], function(left, right)
	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("pet-enable", Settings["pet-enable"], Language["Enable Pet"], Language["Enable the pet unit frame"], ReloadUI):RequiresReload(true)
	left:CreateSlider("unitframes-pet-width", Settings["unitframes-pet-width"], 60, 320, 1, Language["Width"], Language["Set the width of the pet unit frame"], UpdatePetWidth)

	left:CreateHeader(Language["Health"])
	left:CreateSwitch("unitframes-pet-health-reverse", Settings["unitframes-pet-health-reverse"], Language["Reverse Health Fill"], Language["Reverse the fill of the health bar"], UpdatePetHealthFill)
	left:CreateSlider("unitframes-pet-health-height", Settings["unitframes-pet-health-height"], 6, 60, 1, Language["Health Bar Height"], Language["Set the height of the pet health bar"], UpdatePetHealthHeight)
	left:CreateDropdown("unitframes-pet-health-color", Settings["unitframes-pet-health-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Custom"]] = "CUSTOM"}, Language["Health Bar Color"], Language["Set the color of the health bar"], UpdatePetHealthColor)
	left:CreateInput("unitframes-pet-health-left", Settings["unitframes-pet-health-left"], Language["Left Health Text"], Language["Set the text on the left of the pet health bar"], ReloadUI):RequiresReload(true)
	left:CreateInput("unitframes-pet-health-right", Settings["unitframes-pet-health-right"], Language["Right Health Text"], Language["Set the text on the right of the pet health bar"], ReloadUI):RequiresReload(true)
	left:CreateDropdown("PetHealthTexture", Settings.PetHealthTexture, Assets:GetTextureList(), Language["Health Texture"], "", UpdateHealthTexture, "Texture")

	right:CreateHeader(Language["Power"])
	right:CreateSwitch("unitframes-pet-power-reverse", Settings["unitframes-pet-power-reverse"], Language["Reverse Power Fill"], Language["Reverse the fill of the power bar"], UpdatePetPowerFill)
	right:CreateSlider("unitframes-pet-power-height", Settings["unitframes-pet-power-height"], 1, 30, 1, Language["Power Bar Height"], Language["Set the height of the pet power bar"], UpdatePetPowerHeight)
	right:CreateDropdown("unitframes-pet-power-color", Settings["unitframes-pet-power-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Power Type"]] = "POWER"}, Language["Power Bar Color"], Language["Set the color of the power bar"], UpdatePetPowerColor)
	right:CreateDropdown("PetPowerTexture", Settings.PetPowerTexture, Assets:GetTextureList(), Language["Power Texture"], "", UpdatePowerTexture, "Texture")

	right:CreateHeader(Language["Buffs"])
	right:CreateSwitch("unitframes-pet-buffs", Settings["unitframes-pet-buffs"], Language["Enable buffs"], Language["Enable debuffs on the unit frame"], UpdateEnableBuffs)
	right:CreateSlider("unitframes-pet-buff-size", Settings["unitframes-pet-buff-size"], 10, 40, 1, Language["Buff Size"], Language["Set the size of the buff icons"], UpdateBuffSize)
	right:CreateDropdown("unitframes-pet-buff-pos", Settings["unitframes-pet-buff-pos"], {[Language["Bottom"]] = "BOTTOM", [Language["Top"]] = "TOP"}, Language["Set Position"], Language["Set the position of the buffs"], UpdateBuffPosition)

	right:CreateHeader(Language["Debuffs"])
	right:CreateSlider("unitframes-pet-debuff-size", Settings["unitframes-pet-debuff-size"], 10, 40, 1, Language["Debuff Size"], Language["Set the size of the debuff icons"], UpdateDebuffSize)
	right:CreateDropdown("unitframes-pet-debuff-pos", Settings["unitframes-pet-debuff-pos"], {[Language["Bottom"]] = "BOTTOM", [Language["Top"]] = "TOP"}, Language["Set Position"], Language["Set the position of the debuffs"], UpdateDebuffPosition)
end)