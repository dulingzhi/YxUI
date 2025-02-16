local YxUI, Language, Assets, Settings, Defaults = select(2, ...):get()

Defaults["party-enable"] = true
Defaults["party-width"] = 78
Defaults["party-show-debuffs"] = true
Defaults["party-show-role"] = true
Defaults["party-show-aurawatch"] = true
Defaults["party-in-range"] = 100
Defaults["party-out-of-range"] = 50
Defaults["party-health-height"] = 42 -- 40
Defaults["party-health-reverse"] = false
Defaults["party-health-color"] = "CLASS"
Defaults["party-health-orientation"] = "HORIZONTAL"
Defaults["party-health-top"] = "[Name(10)]"
Defaults["party-health-bottom"] = "[HealthDeficit:Short]"
Defaults["party-health-smooth"] = true
Defaults["party-power-enable"] = true
Defaults["party-power-height"] = 6
Defaults["party-power-reverse"] = false
Defaults["party-power-color"] = "POWER"
Defaults["party-power-smooth"] = true
Defaults["party-point"] = "LEFT"
Defaults["party-spacing"] = 2
Defaults["party-show-solo"] = false
Defaults["party-font"] = "Roboto"
Defaults["party-font-size"] = 12
Defaults["party-font-flags"] = ""
Defaults.PartyHealthTexture = "YxUI 4"
Defaults.PartyPowerTexture = "YxUI 4"
Defaults.PartyEnableMouseover = true

local UF = YxUI:GetModule("Unit Frames")

local PartyDebuffFilter = function(self, unit, icon, name, texture, count, dtype, duration, timeLeft, caster, stealable, nameplateshow, id, canapply, boss, player)
	local hasCustom, alwaysShowMine, showForMySpec = SpellGetVisibilityInfo(id, "RAID_INCOMBAT")

	if hasCustom then
		return showForMySpec or (alwaysShowMine and (caster == "player" or caster == "pet" or caster == "vehicle"))
	else
		return true
	end
end

local PartyBuffFilter = function(self, unit, icon, name, texture, count, dtype, duration, timeLeft, caster, stealable, nameplateshow, id, canapply, boss, player)

end

YxUI.StyleFuncs["party"] = function(self, unit)
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
	Health:SetHeight(Settings["party-health-height"])
	Health:SetStatusBarTexture(Assets:GetTexture(Settings.PartyHealthTexture))
	Health:SetReverseFill(Settings["party-health-reverse"])
	Health:SetOrientation(Settings["party-health-orientation"])

	local HealBar = CreateFrame("StatusBar", nil, Health)
	HealBar:SetWidth(Settings["party-width"])
	HealBar:SetHeight(Settings["party-health-height"])
	HealBar:SetStatusBarTexture(Assets:GetTexture(Settings.PartyHealthTexture))
	HealBar:SetStatusBarColor(0, 0.48, 0)
	HealBar:SetFrameLevel(Health:GetFrameLevel() - 1)

	if Settings["party-health-reverse"] then
		HealBar:SetPoint("RIGHT", Health:GetStatusBarTexture(), "LEFT", 0, 0)
	else
		HealBar:SetPoint("LEFT", Health:GetStatusBarTexture(), "RIGHT", 0, 0)
	end

	self.HealBar = HealBar

	if YxUI.IsMainline then
		local AbsorbsBar = CreateFrame("StatusBar", nil, Health)
		AbsorbsBar:SetWidth(Settings["party-width"])
		AbsorbsBar:SetHeight(Settings["party-health-height"])
		AbsorbsBar:SetStatusBarTexture(Assets:GetTexture(Settings.PartyHealthTexture))
		AbsorbsBar:SetStatusBarColor(0, 0.66, 1)
		AbsorbsBar:SetFrameLevel(Health:GetFrameLevel() - 2)

		if Settings["party-health-reverse"] then
			AbsorbsBar:SetPoint("RIGHT", Health:GetStatusBarTexture(), "LEFT", 0, 0)
		else
			AbsorbsBar:SetPoint("LEFT", Health:GetStatusBarTexture(), "RIGHT", 0, 0)
		end

		self.AbsorbsBar = AbsorbsBar
	end

	local HealthBG = self:CreateTexture(nil, "BORDER")
	HealthBG:SetAllPoints(Health)
	HealthBG:SetTexture(Assets:GetTexture(Settings.PartyHealthTexture))
	HealthBG.multiplier = 0.2

	local Highlight = Health:CreateTexture(nil, "OVERLAY")
	Highlight:SetAllPoints(Health)
	Highlight:SetTexture(Assets:GetTexture("Blank"))
	Highlight:SetVertexColor(0.8, 0.8, 0.8)
	Highlight:SetAlpha(0)
	Highlight:SetDrawLayer("OVERLAY", 7)
	self:HookScript("OnEnter", function(self) self.Highlight:SetAlpha(0.15) end)
	self:HookScript("OnLeave", function(self) self.Highlight:SetAlpha(0) end)

	self.Highlight = Highlight

	if (not Settings.PartyEnableMouseover) then
		Highlight:Hide()
	end

	local HealthDead = Health:CreateTexture(nil, "OVERLAY")
	HealthDead:SetAllPoints(Health)
	HealthDead:SetTexture(Assets:GetTexture("RenHorizonUp"))
	HealthDead:SetVertexColor(0.8, 0.8, 0.8)
	HealthDead:SetAlpha(0)
	HealthDead:SetDrawLayer("OVERLAY", 7)

	Health.DeadAnim = LibMotion:CreateAnimationGroup()

	Health.DeadAnim.In = LibMotion:CreateAnimation(HealthDead, "Fade")
	Health.DeadAnim.In:SetEasing("in")
	Health.DeadAnim.In:SetDuration(0.15)
	Health.DeadAnim.In:SetChange(0.6)
	Health.DeadAnim.In:SetGroup(Health.DeadAnim)
	Health.DeadAnim.In:SetOrder(1)

	Health.DeadAnim.Out = LibMotion:CreateAnimation(HealthDead, "Fade")
	Health.DeadAnim.Out:SetEasing("out")
	Health.DeadAnim.Out:SetDuration(0.3)
	Health.DeadAnim.Out:SetChange(0)
	Health.DeadAnim.Out:SetGroup(Health.DeadAnim)
	Health.DeadAnim.Out:SetOrder(2)

	local HealthName = Health:CreateFontString(nil, "OVERLAY")
	YxUI:SetFontInfo(HealthName, Settings["party-font"], Settings["party-font-size"], Settings["party-font-flags"])
	HealthName:SetPoint("BOTTOM", Health, "CENTER", 0, 1)
	HealthName:SetJustifyH("CENTER")

	local HealthBottom = Health:CreateFontString(nil, "OVERLAY")
	YxUI:SetFontInfo(HealthBottom, Settings["party-font"], Settings["party-font-size"], Settings["party-font-flags"])
	HealthBottom:SetPoint("TOP", Health, "CENTER", 0, -1)
	HealthBottom:SetJustifyH("CENTER")

	-- Attributes
	Health.colorDisconnected = true
	Health.Smooth = true

	UF:SetHealthAttributes(Health, Settings["party-health-color"])

	local Power = CreateFrame("StatusBar", nil, self)
	Power:SetPoint("BOTTOMLEFT", self, 1, 1)
	Power:SetPoint("BOTTOMRIGHT", self, -1, 1)
	Power:SetHeight(Settings["party-power-height"])
	Power:SetStatusBarTexture(Assets:GetTexture(Settings.PartyPowerTexture))
	Power:SetReverseFill(Settings["party-power-reverse"])

	local PowerBG = Power:CreateTexture(nil, "BORDER")
	PowerBG:SetPoint("TOPLEFT", Power, 0, 0)
	PowerBG:SetPoint("BOTTOMRIGHT", Power, 0, 0)
	PowerBG:SetTexture(Assets:GetTexture(Settings.PartyPowerTexture))
	PowerBG:SetAlpha(0.2)

	-- Attributes
	Power.frequentUpdates = true

	UF:SetPowerAttributes(Power, Settings["party-power-color"])

	-- Debuffs
	local Debuffs = CreateFrame("Frame", self:GetName() .. "Debuffs", Health)
	Debuffs.PostCreateIcon = UF.PostCreateIcon
	Debuffs.PostUpdateIcon = UF.PostUpdateIcon
	Debuffs.CustomFilter = PartyDebuffFilter

	if (Settings["party-point"] == "LEFT") or (Settings["party-point"] == "RIGHT") then
		Debuffs:SetSize(24 * 3 + (2 * 2), 24)
		Debuffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 2)
		Debuffs.size = 24
		Debuffs.num = 3
		Debuffs.spacing = 1
		Debuffs.initialAnchor = "BOTTOMLEFT"
		Debuffs.tooltipAnchor = "ANCHOR_TOP"
		Debuffs["growth-x"] = "RIGHT"
	else
		Debuffs:SetSize(24 * 3 + (2 * 2), 24 * 2 + 2)
		Debuffs:SetPoint("TOPLEFT", self, "TOPRIGHT", 2, 0)
		Debuffs.size = 24
		Debuffs.num = 6
		Debuffs.spacing = 1
		Debuffs.initialAnchor = "TOPLEFT"
		Debuffs.tooltipAnchor = "ANCHOR_TOP"
		Debuffs["growth-x"] = "RIGHT"
		Debuffs["growth-y"] = "DOWN"
	end

	if UF.BuffIDs[YxUI.UserClass] then
		local Auras = CreateFrame("Frame", nil, Health)
		Auras:SetPoint("TOPLEFT", Health)
		Auras:SetPoint("BOTTOMRIGHT", Health)
		Auras:SetFrameLevel(10)
		Auras:SetFrameStrata("HIGH")
		Auras.presentAlpha = 1
		Auras.missingAlpha = 0
		Auras.strictMatching = true
		Auras.icons = {}
		Auras.PostCreateIcon = UF.PostCreateAuraWatchIcon

		for key, spell in pairs(UF.BuffIDs[YxUI.UserClass]) do
			local Icon = CreateFrame("Frame", nil, Auras)
			Icon.spellID = spell[1]
			Icon.anyUnit = spell[4]
			Icon.strictMatching = true
			Icon:SetSize(8, 8)
			Icon:SetPoint(spell[2], 0, 0)

			local Texture = Icon:CreateTexture(nil, "OVERLAY")
			Texture:SetAllPoints(Icon)
			Texture:SetTexture(Assets:GetTexture("Blank"))

			local BG = Icon:CreateTexture(nil, "BORDER")
			BG:SetPoint("TOPLEFT", Icon, -1, 1)
			BG:SetPoint("BOTTOMRIGHT", Icon, 1, -1)
			BG:SetTexture(Assets:GetTexture("Blank"))
			BG:SetVertexColor(0, 0, 0)

			if (spell[3]) then
				Texture:SetVertexColor(unpack(spell[3]))
			else
				Texture:SetVertexColor(0.8, 0.8, 0.8)
			end

			local Count = Icon:CreateFontString(nil, "OVERLAY")
			YxUI:SetFontInfo(Count, Settings["party-font"], 10)
			Count:SetPoint("CENTER", unpack(UF.AuraOffsets[spell[2]]))
			Icon.count = Count

			Auras.icons[spell[1]] = Icon
		end

		self.AuraWatch = Auras
	end

	-- Leader
    local Leader = Health:CreateTexture(nil, "OVERLAY")
    Leader:SetSize(16, 16)
    Leader:SetPoint("LEFT", Health, "TOPLEFT", 0, 0)
    Leader:SetTexture(Assets:GetTexture("Leader"))
    Leader:SetVertexColor(YxUI:HexToRGB("FFEB3B"))
    Leader:Hide()

	-- Assist
    local Assist = Health:CreateTexture(nil, "OVERLAY")
    Assist:SetSize(16, 16)
    Assist:SetPoint("LEFT", Health, "TOPLEFT", 0, 0)
    Assist:SetTexture(Assets:GetTexture("Assist"))
    Assist:SetVertexColor(YxUI:HexToRGB("FFEB3B"))
    Assist:Hide()

	-- Ready Check
    local ReadyCheck = Health:CreateTexture(nil, "OVERLAY")
	ReadyCheck:SetSize(16, 16)
    ReadyCheck:SetPoint("LEFT", Health, 2, 0)

    -- Phase
    local PhaseIndicator = CreateFrame("Frame", nil, Health)
    PhaseIndicator:SetSize(16, 16)
    PhaseIndicator:SetPoint("TOPRIGHT", Health, 0, 0)

	PhaseIndicator.Icon = PhaseIndicator:CreateTexture(nil, "OVERLAY")
	PhaseIndicator.Icon:SetAllPoints()

	-- Target Icon
	local RaidTarget = Health:CreateTexture(nil, "OVERLAY")
	RaidTarget:SetSize(16, 16)
	RaidTarget:SetPoint("CENTER", Health, "TOP")

    -- Resurrect
	local Resurrect = Health:CreateTexture(nil, "OVERLAY")
	Resurrect:SetSize(16, 16)
	Resurrect:SetPoint("LEFT", Health, 2, 0)

	-- Role
	if Settings["party-show-role"] then
		local RoleIndicator = Health:CreateTexture(nil, "OVERLAY")
		RoleIndicator:SetSize(12, 12)
        RoleIndicator:SetPoint("TOPLEFT", Health, 3, 5)
        RoleIndicator.PostUpdate = function(self)
            self:ClearAllPoints()
            if Leader:IsShown() then
                RoleIndicator:SetPoint("LEFT", Leader, "RIGHT", 3, 0)
            elseif  Assist:IsShown() then
                self:SetPoint("LEFT",  Assist, "RIGHT", 3, 0)
            else
                RoleIndicator:SetPoint("TOPLEFT", Health, 3, 5)
            end
        end

		self.GroupRoleIndicator = RoleIndicator
	end

	-- Dispels
	local Dispel = CreateFrame("Frame", nil, Health, "BackdropTemplate")
	Dispel:SetSize(20, 20)
	Dispel:SetPoint("CENTER", Health, 0, 0)
	Dispel:SetFrameLevel(Health:GetFrameLevel() + 20)
	Dispel:SetBackdrop(YxUI.BackdropAndBorder)
	Dispel:SetBackdropColor(0, 0, 0)
	Dispel:SetFrameLevel(Debuffs:GetFrameLevel() + 1)

	Dispel.icon = Dispel:CreateTexture(nil, "ARTWORK")
	Dispel.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
	Dispel.icon:SetPoint("TOPLEFT", Dispel, 1, -1)
	Dispel.icon:SetPoint("BOTTOMRIGHT", Dispel, -1, 1)

	Dispel.cd = CreateFrame("Cooldown", nil, Dispel, "CooldownFrameTemplate")
	Dispel.cd:SetPoint("TOPLEFT", Dispel, 1, -1)
	Dispel.cd:SetPoint("BOTTOMRIGHT", Dispel, -1, 1)
	Dispel.cd:SetHideCountdownNumbers(true)
	Dispel.cd:SetDrawEdge(false)

	Dispel.count = Dispel.cd:CreateFontString(nil, "ARTWORK")
	YxUI:SetFontInfo(Dispel.count, Settings["party-font"], Settings["party-font-size"], Settings["party-font-flags"])
	Dispel.count:SetPoint("BOTTOMRIGHT", Dispel, "BOTTOMRIGHT", -3, 3)
	Dispel.count:SetTextColor(1, 1, 1)
	Dispel.count:SetJustifyH("RIGHT")
	Dispel.count:SetDrawLayer("ARTWORK", 7)

	Dispel.bg = Dispel:CreateTexture(nil, "BACKGROUND")
	Dispel.bg:SetPoint("TOPLEFT", Dispel, -1, 1)
	Dispel.bg:SetPoint("BOTTOMRIGHT", Dispel, 1, -1)
	Dispel.bg:SetTexture(Assets:GetTexture("Blank"))
	Dispel.bg:SetVertexColor(0, 0, 0)

	self:Tag(HealthName, Settings["party-health-top"])
	self:Tag(HealthBottom, Settings["party-health-bottom"])

	self.Range = {
		insideAlpha = Settings["party-in-range"] / 100,
		outsideAlpha = Settings["party-out-of-range"] / 100,
	}

	self.Health = Health
	self.Health.bg = HealthBG
	self.Power = Power
	self.Power.bg = PowerBG
	self.HealthName = HealthName
	self.HealthBottom = HealthBottom
	self.Debuffs = Debuffs
	self.Dispel = Dispel
	self.LeaderIndicator = Leader
	self.AssistantIndicator = Assist
	self.ReadyCheckIndicator = ReadyCheck
	self.ResurrectIndicator = Resurrect
	self.RaidTargetIndicator = RaidTarget
	self.PhaseIndicator = PhaseIndicator
end

local UpdatePartyWidth = function(value)
	if YxUI.UnitFrames["party"] then
		local Unit

		for i = 1, YxUI.UnitFrames["party"]:GetNumChildren() do
			Unit = select(i, YxUI.UnitFrames["party"]:GetChildren())

			if Unit then
				Unit:SetWidth(value)
			end
		end
	end
end

local UpdatePartyHealthHeight = function(value)
	if YxUI.UnitFrames["party"] then
		local Unit

		for i = 1, YxUI.UnitFrames["party"]:GetNumChildren() do
			Unit = select(i, YxUI.UnitFrames["party"]:GetChildren())

			if Unit then
				Unit:SetHeight(value + Settings["party-power-height"] + 3)
				Unit.Health:SetHeight(value)
			end
		end
	end
end

local UpdatePartyHealthColor = function(value)
	if YxUI.UnitFrames["party"] then
		local Unit

		for i = 1, YxUI.UnitFrames["party"]:GetNumChildren() do
			Unit = select(i, YxUI.UnitFrames["party"]:GetChildren())

			if Unit then
				UF:SetHealthAttributes(Unit.Health, value)

				Unit.Health:ForceUpdate()
			end
		end
	end
end

local UpdateEnablePartyPower = function(value)
	if YxUI.UnitFrames["party"] then
		local Unit

		for i = 1, YxUI.UnitFrames["party"]:GetNumChildren() do
			Unit = select(i, YxUI.UnitFrames["party"]:GetChildren())

			if Unit then
				if value then
					Unit:EnableElement("Power")
					Unit:SetHeight(Settings["party-health-height"] + Settings["party-power-height"] + 3)
				else
					Unit:DisableElement("Power")
					Unit:SetHeight(Settings["party-health-height"] + 2)
				end
			end
		end
	end
end

local UpdatePartyPowerHeight = function(value)
	if YxUI.UnitFrames["party"] then
		local Unit

		for i = 1, YxUI.UnitFrames["party"]:GetNumChildren() do
			Unit = select(i, YxUI.UnitFrames["party"]:GetChildren())

			if Unit then
				Unit:SetHeight(value + Settings["party-health-height"] + 3)
				Unit.Power:SetHeight(value)
			end
		end
	end
end

local UpdatePartyHealthOrientation = function(value)
	if YxUI.UnitFrames["party"] then
		local Unit

		for i = 1, YxUI.UnitFrames["party"]:GetNumChildren() do
			Unit = select(i, YxUI.UnitFrames["party"]:GetChildren())

			if Unit then
				Unit.Health:SetOrientation(value)
			end
		end
	end
end

local UpdatePartyHealthReverseFill = function(value)
	if YxUI.UnitFrames["party"] then
		local Unit

		for i = 1, YxUI.UnitFrames["party"]:GetNumChildren() do
			Unit = select(i, YxUI.UnitFrames["party"]:GetChildren())

			if Unit then
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
	end
end

local UpdatePartyPowerReverseFill = function(value)
	if YxUI.UnitFrames["party"] then
		local Unit

		for i = 1, YxUI.UnitFrames["party"]:GetNumChildren() do
			Unit = select(i, YxUI.UnitFrames["party"]:GetChildren())

			if Unit then
				Unit.Power:SetReverseFill(value)
			end
		end
	end
end

local UpdatePartyPowerColor = function(value)
	if YxUI.UnitFrames["party"] then
		local Unit

		for i = 1, YxUI.UnitFrames["party"]:GetNumChildren() do
			Unit = select(i, YxUI.UnitFrames["party"]:GetChildren())

			if Unit then
				UF:SetPowerAttributes(Unit.Power, value)

				Unit.Power:ForceUpdate()
			end
		end
	end
end

local UpdatePartyShowDebuffs = function(value)
	if YxUI.UnitFrames["party"] then
		local Unit

		for i = 1, YxUI.UnitFrames["party"]:GetNumChildren() do
			Unit = select(i, YxUI.UnitFrames["party"]:GetChildren())

			if Unit then
				if value then
					Unit:EnableElement("Debuffs")
				else
					Unit:DisableElement("Debuffs")
				end
			end
		end
	end
end

local UpdatePartyShowHighlight = function(value)
	if YxUI.UnitFrames["party"] then
		local Unit

		for i = 1, YxUI.UnitFrames["party"]:GetNumChildren() do
			Unit = select(i, YxUI.UnitFrames["party"]:GetChildren())

			if Unit then
				if value then
					Unit.Highlight:Show()
				else
					Unit.Highlight:Hide()
				end
			end
		end

		for i = 1, YxUI.UnitFrames["party-pets"]:GetNumChildren() do
			Unit = select(i, YxUI.UnitFrames["party-pets"]:GetChildren())

			if Unit then
				if value then
					Unit.Highlight:Show()
				else
					Unit.Highlight:Hide()
				end
			end
		end
	end
end

local UpdatePartyShowRole = function(value)
	if YxUI.UnitFrames["party"] then
		local Unit

		for i = 1, YxUI.UnitFrames["party"]:GetNumChildren() do
			Unit = select(i, YxUI.UnitFrames["party"]:GetChildren())

			if Unit then
				if value then
					Unit:EnableElement("GroupRoleIndicator")
				else
					Unit:DisableElement("GroupRoleIndicator")
				end

				Unit:UpdateAllElements("ForceUpdate")
			end
		end
	end
end

local UpdatePartySpacing = function(value)
	if YxUI.UnitFrames["party"] then
		local Point = YxUI.UnitFrames["party"]:GetAttribute("point")

		if (Point == "LEFT") then
			YxUI.UnitFrames["party"]:SetAttribute("xOffset", value)
			YxUI.UnitFrames["party"]:SetAttribute("yOffset", 0)
		elseif (Point == "RIGHT") then
			YxUI.UnitFrames["party"]:SetAttribute("xOffset", -value)
			YxUI.UnitFrames["party"]:SetAttribute("yOffset", 0)
		elseif (Point == "TOP") then
			YxUI.UnitFrames["party"]:SetAttribute("xOffset", 0)
			YxUI.UnitFrames["party"]:SetAttribute("yOffset", -value)
		elseif (Point == "BOTTOM") then
			YxUI.UnitFrames["party"]:SetAttribute("xOffset", 0)
			YxUI.UnitFrames["party"]:SetAttribute("yOffset", value)
		end

		if YxUI.UnitFrames["party-pets"] then
			if (Point == "LEFT") then
				YxUI.UnitFrames["party-pets"]:SetAttribute("xOffset", value)
				YxUI.UnitFrames["party-pets"]:SetAttribute("yOffset", 0)
			elseif (Point == "RIGHT") then
				YxUI.UnitFrames["party-pets"]:SetAttribute("xOffset", -value)
				YxUI.UnitFrames["party-pets"]:SetAttribute("yOffset", 0)
			elseif (Point == "TOP") then
				YxUI.UnitFrames["party-pets"]:SetAttribute("xOffset", 0)
				YxUI.UnitFrames["party-pets"]:SetAttribute("yOffset", -value)
			elseif (Point == "BOTTOM") then
				YxUI.UnitFrames["party-pets"]:SetAttribute("xOffset", 0)
				YxUI.UnitFrames["party-pets"]:SetAttribute("yOffset", value)
			end
		end
	end
end

local Testing = false

local TestParty = function()
	local Header = _G["YxUI Party"]
	local Pets = _G["YxUI Party Pets"]

	if Testing then
		if Header then
			Header:SetAttribute("isTesting", false)

			if (Header:GetAttribute("startingIndex") ~= -4) then
				Header:SetAttribute("startingIndex", -4)
			end

			for i = 1, select("#", Header:GetChildren()) do
				local Frame = select(i, Header:GetChildren())

				UnregisterUnitWatch(Frame)
				Frame:Hide()
			end
		end

		if Pets then
			Pets:SetAttribute("isTesting", false)

			if (Pets:GetAttribute("startingIndex") ~= -4) then
				Pets:SetAttribute("startingIndex", -4)
			end

			for i = 1, select("#", Pets:GetChildren()) do
				local Frame = select(i, Pets:GetChildren())

				UnregisterUnitWatch(Frame)
				Frame:Hide()
			end
		end

		Testing = false
	else
		if Header then
			Header:SetAttribute("isTesting", true)

			if (Header:GetAttribute("startingIndex") ~= -4) then
				Header:SetAttribute("startingIndex", -4)
			end

			for i = 1, select("#", Header:GetChildren()) do
				local Frame = select(i, Header:GetChildren())

				Frame.unit = "player"
				UnregisterUnitWatch(Frame)
				RegisterUnitWatch(Frame, true)
				Frame:Show()
			end
		end

		if Pets then
			Pets:SetAttribute("isTesting", true)

			if (Pets:GetAttribute("startingIndex") ~= -4) then
				Pets:SetAttribute("startingIndex", -4)
			end

			for i = 1, select("#", Pets:GetChildren()) do
				local Frame = select(i, Pets:GetChildren())

				Frame.unit = UnitExists("pet") and "pet" or "player"
				UnregisterUnitWatch(Frame)
				RegisterUnitWatch(Frame, true)
				Frame:Show()
			end
		end

		Testing = true
	end
end

local UpdateShowSolo = function(value)
	_G["YxUI Party"]:SetAttribute("showSolo", value)
end

local UpdateHealthTexture = function(value)
	if YxUI.UnitFrames["party"] then
		local Unit

		for i = 1, YxUI.UnitFrames["party"]:GetNumChildren() do
			Unit = select(i, YxUI.UnitFrames["party"]:GetChildren())

			Unit.Health:SetStatusBarTexture(Assets:GetTexture(value))
			Unit.Health.bg:SetTexture(Assets:GetTexture(value))
			Unit.HealBar:SetStatusBarTexture(Assets:GetTexture(value))

			if Unit.AbsorbsBar then
				Unit.AbsorbsBar:SetStatusBarTexture(Assets:GetTexture(value))
			end
		end
	end
end

local UpdatePowerTexture = function(value)
	if YxUI.UnitFrames["party"] then
		local Unit

		for i = 1, YxUI.UnitFrames["party"]:GetNumChildren() do
			Unit = select(i, YxUI.UnitFrames["party"]:GetChildren())

			Unit.Power:SetStatusBarTexture(Assets:GetTexture(value))
			Unit.Power.bg:SetTexture(Assets:GetTexture(value))
		end
	end
end

YxUI:GetModule("GUI"):AddWidgets(Language["General"], Language["Party"], Language["Unit Frames"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("party-enable", Settings["party-enable"], Language["Enable Party Module"], Language["Enable the party frames module"], ReloadUI):RequiresReload(true)

	left:CreateHeader(Language["Party Size"])
	left:CreateSlider("party-width", Settings["party-width"], 40, 200, 1, Language["Width"], Language["Set the width of the party frames"], UpdatePartyWidth)

	left:CreateHeader(Language["Font"])
	left:CreateDropdown("party-font", Settings["party-font"], Assets:GetFontList(), Language["Font"], Language["Set the font of the party frames"], nil, "Font")
	left:CreateSlider("party-font-size", Settings["party-font-size"], 8, 32, 1, Language["Font Size"], Language["Set the font size of the party frames"])
	left:CreateDropdown("party-font-flags", Settings["party-font-flags"], Assets:GetFlagsList(), Language["Font Flags"], Language["Set the font flags of the party frames"])

	right:CreateHeader(Language["Test Party Frames"])
	right:CreateButton("", Language["Test"], Language["Test Party"], Language["Test the party frames"], TestParty)

	right:CreateHeader(Language["Health"])
	right:CreateSlider("party-health-height", Settings["party-health-height"], 12, 60, 1, Language["Health Height"], Language["Set the height of party health bars"], UpdatePartyHealthHeight)
	right:CreateDropdown("party-health-color", Settings["party-health-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Custom"]] = "CUSTOM"}, Language["Health Bar Color"], Language["Set the color of the health bar"], UpdatePartyHealthColor)
	right:CreateSwitch("party-health-reverse", Settings["party-health-reverse"], Language["Reverse Health Fill"], Language["Reverse the fill of the health bar"], UpdatePartyHealthReverseFill)
	right:CreateDropdown("PartyHealthTexture", Settings.PartyHealthTexture, Assets:GetTextureList(), Language["Health Texture"], "", UpdateHealthTexture, "Texture")

	right:CreateHeader(Language["Power"])
	right:CreateSwitch("party-power-enable", Settings["party-power-enable"], Language["Enable Power Bar"], Language["Enable the power bar"], UpdateEnablePartyPower)
	right:CreateSwitch("party-power-reverse", Settings["party-power-reverse"], Language["Reverse Power Fill"], Language["Reverse the fill of the power bar"], UpdatePartyPowerReverseFill)
	right:CreateSlider("party-power-height", Settings["party-power-height"], 2, 30, 1, Language["Power Height"], Language["Set the height of party power bars"], UpdatePartyPowerHeight)
	right:CreateDropdown("party-power-color", Settings["party-power-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Power Type"]] = "POWER"}, Language["Power Bar Color"], Language["Set the color of the power bar"], UpdatePartyPowerColor)
	right:CreateDropdown("PartyPowerTexture", Settings.PartyPowerTexture, Assets:GetTextureList(), Language["Power Texture"], "", UpdatePowerTexture, "Texture")

	right:CreateHeader(Language["Text"])
	right:CreateInput("party-health-top", Settings["party-health-top"], Language["Top Text"], Language["Set the text on the top of the party frame"], ReloadUI):RequiresReload(true)
	right:CreateInput("party-health-bottom", Settings["party-health-bottom"], Language["Bottom Text"], Language["Set the text on the bottom of the party frame"], ReloadUI):RequiresReload(true)

	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("party-show-debuffs", Settings["party-show-debuffs"], Language["Enable Debuffs"], Language["Display debuffs on party members"], UpdatePartyShowDebuffs)
	--left:CreateSwitch("party-show-role", Settings["party-show-role"], Language["Enable Role Icons"], Language["Display role icons on party members"], UpdatePartyShowRole)
	left:CreateSwitch("party-show-role", Settings["party-show-role"], Language["Enable Role Icons"], Language["Display role icons on party members"], ReloadUI):RequiresReload(true)
	left:CreateSwitch("PartyEnableMouseover", Settings.PartyEnableMouseover, Language["Enable Mouseover"], Language["Enable a mouseover highlight on party members"], UpdatePartyShowHighlight)

	left:CreateHeader(Language["Range Opacity"])
	left:CreateSlider("party-in-range", Settings["party-in-range"], 0, 100, 5, Language["In Range"], Language["Set the opacity of party members within range of you"])
	left:CreateSlider("party-out-of-range", Settings["party-out-of-range"], 0, 100, 5, Language["Out of Range"], Language["Set the opacity of party members out of your range"])

	left:CreateHeader(Language["Attributes"])
	left:CreateSwitch("party-show-solo", Settings["party-show-solo"], Language["Show Solo"], Language["Display the frames while not in a group"], UpdateShowSolo)
	left:CreateDropdown("party-point", Settings["party-point"], {[Language["Left"]] = "LEFT", [Language["Right"]] = "RIGHT", [Language["Top"]] = "TOP", [Language["Bottom"]] = "BOTTOM"}, Language["Anchor Point"], Language["Set the anchor point for the party frames"], ReloadUI):RequiresReload(true)
	left:CreateSlider("party-spacing", Settings["party-spacing"], -10, 10, 1, Language["Set Spacing"], Language["Set the spacing of party units from eachother"], UpdatePartySpacing)
end)