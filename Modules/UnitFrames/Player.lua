local Y, L, A, C, D = YxUIGlobal:get()

D["unitframes-player-width"] = 200
D["unitframes-player-health-height"] = 34
D["unitframes-player-health-reverse"] = false
D["unitframes-player-health-color"] = "CLASS"
D["unitframes-player-health-smooth"] = true
D["unitframes-player-power-height"] = 16
D["unitframes-player-power-reverse"] = false
D["unitframes-player-power-color"] = "POWER"
D["unitframes-player-power-smooth"] = true
D["unitframes-player-health-left"] = "[LevelColor][Level][Plus][ColorStop] [Name(30)]" -- [Resting]
D["unitframes-player-health-right"] = "[HealthPercent]"
D["unitframes-player-power-left"] = "[HealthValues:Short]"
D["unitframes-player-power-right"] = "[PowerValues:Short]"
D["unitframes-player-enable-power"] = true
D["unitframes-player-enable-resource"] = true
D["unitframes-player-cast-width"] = 268
D["unitframes-player-cast-height"] = 28
D["unitframes-player-cast-classcolor"] = true
D["unitframes-player-enable-castbar"] = true
D["unitframes-show-mana-timer"] = true
D["unitframes-show-energy-timer"] = true
D["player-enable-portrait"] = false
D["player-portrait-style"] = "2D"
D["player-overlay-alpha"] = 30
D["player-enable-pvp"] = true
D["player-resource-height"] = 8
D["player-move-resource"] = false
D["player-move-power"] = false
D["player-enable"] = true
D["unitframes-player-swing-width"] = 273
D["unitframes-player-swing-height"] = 10
D["unitframes-player-enable-swingbar"] = true
D.PlayerBuffPerLine = 6
D.PlayerBuffSpacing = 6
D.PlayerBuffSize = (D["unitframes-player-width"] - (D.PlayerBuffPerLine - 1) * D.PlayerBuffSpacing) / D.PlayerBuffPerLine - 0.3
D.PlayerDebuffSize = D.PlayerBuffSize
D.PlayerDebuffSpacing = D.PlayerBuffSpacing
D.PlayerHealthTexture = "YxUI 4"
D.PlayerPowerTexture = "YxUI 4"
D.PlayerResourceTexture = "YxUI 4"

-- Can do textures for health/power/castbar/player resources. That's only 4 settings, and only player needs the resources setting

local UF = Y:GetModule("Unit Frames")

Y.StyleFuncs["player"] = function(self, unit)
	-- General
	self:RegisterForClicks("AnyUp")
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self.AuraParent = self

	local Backdrop = self:CreateTexture(nil, "BACKGROUND")
	Backdrop:SetAllPoints()
	Backdrop:SetTexture(A:GetTexture("Blank"))
	Backdrop:SetVertexColor(0, 0, 0)

	-- Health Bar
	local Health = CreateFrame("StatusBar", nil, self)
	Health:SetPoint("TOPLEFT", self, 1, -1)
	Health:SetPoint("TOPRIGHT", self, -1, -1)
	Health:SetHeight(C["unitframes-player-health-height"])
	Health:SetStatusBarTexture(A:GetTexture(C.PlayerHealthTexture))
	Health:SetReverseFill(C["unitframes-player-health-reverse"])
    Health:CreateBorder()

	local HealBar = CreateFrame("StatusBar", nil, Health)
	HealBar:SetWidth(C["unitframes-player-width"])
	HealBar:SetHeight(C["unitframes-player-health-height"])
	HealBar:SetStatusBarTexture(A:GetTexture(C.PlayerHealthTexture))
	HealBar:SetStatusBarColor(0, 0.48, 0)
	HealBar:SetFrameLevel(Health:GetFrameLevel() - 1)
	HealBar:SetReverseFill(C["unitframes-player-health-reverse"])

	if C["unitframes-player-health-reverse"] then
		HealBar:SetPoint("RIGHT", Health:GetStatusBarTexture(), "LEFT", 0, 0)
	else
		HealBar:SetPoint("LEFT", Health:GetStatusBarTexture(), "RIGHT", 0, 0)
	end

	self.HealBar = HealBar

	if Y.IsMainline then
		local AbsorbsBar = CreateFrame("StatusBar", nil, Health)
		AbsorbsBar:SetWidth(C["unitframes-player-width"])
		AbsorbsBar:SetHeight(C["unitframes-player-health-height"])
		AbsorbsBar:SetStatusBarTexture(A:GetTexture(C.PlayerHealthTexture))
		AbsorbsBar:SetStatusBarColor(0, 0.66, 1)
		AbsorbsBar:SetReverseFill(C["unitframes-player-health-reverse"])
		AbsorbsBar:SetFrameLevel(Health:GetFrameLevel() - 2)

		if C["unitframes-player-health-reverse"] then
			AbsorbsBar:SetPoint("RIGHT", Health:GetStatusBarTexture(), "LEFT", 0, 0)
		else
			AbsorbsBar:SetPoint("LEFT", Health:GetStatusBarTexture(), "RIGHT", 0, 0)
		end

		self.AbsorbsBar = AbsorbsBar
	end

	local HealthBG = self:CreateTexture(nil, "BORDER")
	HealthBG:SetAllPoints(Health)
	HealthBG:SetTexture(A:GetTexture(C.PlayerHealthTexture))
	HealthBG.multiplier = 0.2

	local HealthLeft = Health:CreateFontString(nil, "OVERLAY")
	Y:SetFontInfo(HealthLeft, C["unitframes-font"], C["unitframes-font-size"], C["unitframes-font-flags"])
	HealthLeft:SetPoint("LEFT", Health, 3, 0)
	HealthLeft:SetJustifyH("LEFT")

	local HealthRight = Health:CreateFontString(nil, "OVERLAY")
	Y:SetFontInfo(HealthRight, C["unitframes-font"], C["unitframes-font-size"], C["unitframes-font-flags"])
	HealthRight:SetPoint("RIGHT", Health, -3, 0)
	HealthRight:SetJustifyH("RIGHT")

    -- Portrait
	local Portrait

	if (C["player-portrait-style"] == "2D") then
		Portrait = self:CreateTexture(nil, "OVERLAY")
		Portrait:SetTexCoord(0.12, 0.88, 0.12, 0.88)
		Portrait:SetSize(C["unitframes-player-health-height"] + C["unitframes-player-power-height"] + 3, C["unitframes-player-health-height"] + C["unitframes-player-power-height"] + 3)
    	Portrait:SetPoint("RIGHT", self, "LEFT", -3, 0)

		Portrait.BG = self:CreateTexture(nil, "BACKGROUND")
		Portrait.BG:SetPoint("TOPLEFT", Portrait, -1, 1)
		Portrait.BG:SetPoint("BOTTOMRIGHT", Portrait, 1, -1)
		Portrait.BG:SetTexture(A:GetTexture(C["Blank"]))
		Portrait.BG:SetVertexColor(0, 0, 0)

        Portrait.Border = CreateFrame("Frame", nil, self)
        Portrait.Border:SetAllPoints(Portrait)
        Portrait.Border:CreateBorder()
        Portrait.Border.YxUIBackground:Hide()

	elseif (C["player-portrait-style"] == "OVERLAY") then
		Portrait = CreateFrame("PlayerModel", nil, self)
		Portrait:SetSize(C["unitframes-player-width"], C["unitframes-player-health-height"] )
		Portrait:SetPoint("CENTER", Health, 0, 0)
		Portrait:SetAlpha(C["player-overlay-alpha"] / 100)
	else
		Portrait = CreateFrame("PlayerModel", nil, self)
		Portrait:SetSize(C["unitframes-player-health-height"] + C["unitframes-player-power-height"] + 3, C["unitframes-player-health-height"] + C["unitframes-player-power-height"] + 3)
    	Portrait:SetPoint("RIGHT", self, "LEFT", -3, 0)
        Portrait:CreateBorder()

		Portrait.BG = self:CreateTexture(nil, "BACKGROUND")
		Portrait.BG:SetPoint("TOPLEFT", Portrait, -1, 1)
		Portrait.BG:SetPoint("BOTTOMRIGHT", Portrait, 1, -1)
		Portrait.BG:SetTexture(A:GetTexture(C["Blank"]))
		Portrait.BG:SetVertexColor(0, 0, 0)
	end

	if (Portrait.BG and not C["player-enable-portrait"]) then
		Portrait.BG:Hide()
	end

    self.Portrait = Portrait

	local Combat = Health:CreateTexture(nil, "OVERLAY")
	Combat:SetSize(20, 20)
	Combat:SetPoint("CENTER", Health)

    local Leader = Health:CreateTexture(nil, "OVERLAY")
    Leader:SetSize(16, 16)
    Leader:SetPoint("LEFT", Health, "TOPLEFT", 3, 0)
    Leader:SetTexture(A:GetTexture("Leader"))
    Leader:SetVertexColor(Y:HexToRGB("FFEB3B"))
    Leader:Hide()

    -- PVP indicator
	local PvPIndicator = Health:CreateTexture(nil, "ARTWORK", nil, 1)

	if Y.IsMainline then
		PvPIndicator:SetSize(30, 30)
		PvPIndicator:SetPoint("RIGHT", Health, "LEFT", -4, -2)

		PvPIndicator.Badge = Health:CreateTexture(nil, "ARTWORK")
		PvPIndicator.Badge:SetSize(50, 52)
		PvPIndicator.Badge:SetPoint("CENTER", PvPIndicator, "CENTER")
	else
		PvPIndicator:SetSize(32, 32)
		PvPIndicator:SetPoint("CENTER", Health, 5, -6)
	end

	local RaidTarget = Health:CreateTexture(nil, "OVERLAY")
	RaidTarget:SetSize(16, 16)
	RaidTarget:SetPoint("CENTER", Health, "TOP")

	local R, G, B = Y:HexToRGB(C["ui-header-texture-color"])

	-- Attributes
	Health.Smooth = true
	self.colors.health = {R, G, B}
	UF:SetHealthAttributes(Health, C["unitframes-player-health-color"])

	if C["unitframes-player-enable-power"] then
		local Power = CreateFrame("StatusBar", nil, self)
		local PowerAnchor = CreateFrame("Frame", "YxUI Player Power", Y.UIParent)
		PowerAnchor:SetSize(C["unitframes-player-width"], C["unitframes-player-power-height"])
		PowerAnchor:SetPoint("CENTER", Y.UIParent, 0, -133)
		Y:CreateMover(PowerAnchor)

		if C["player-move-power"] then
			Power:SetPoint("BOTTOMLEFT", PowerAnchor, 1, 1)
			Power:SetPoint("BOTTOMRIGHT", PowerAnchor, -1, 1)
		else
			Power:SetPoint("BOTTOMLEFT", self, 1, 1)
			Power:SetPoint("BOTTOMRIGHT", self, -1, 1)
		end

		Power:SetHeight(C["unitframes-player-power-height"])
		Power:SetStatusBarTexture(A:GetTexture(C.PlayerPowerTexture))
		Power:SetReverseFill(C["unitframes-player-power-reverse"])
        Power:CreateBorder()

		local PowerBG = Power:CreateTexture(nil, "BORDER")
		PowerBG:SetPoint("TOPLEFT", Power, 0, 0)
		PowerBG:SetPoint("BOTTOMRIGHT", Power, 0, 0)
		PowerBG:SetTexture(A:GetTexture(C.PlayerPowerTexture))
		PowerBG:SetAlpha(0.2)

		local Backdrop = Power:CreateTexture(nil, "BACKGROUND")
		Backdrop:SetPoint("TOPLEFT", -1, 1)
		Backdrop:SetPoint("BOTTOMRIGHT", 1, -1)
		Backdrop:SetTexture(A:GetTexture("Blank"))
		Backdrop:SetVertexColor(0, 0, 0)

		local PowerRight = Power:CreateFontString(nil, "OVERLAY")
		Y:SetFontInfo(PowerRight, C["unitframes-font"], C["unitframes-font-size"], C["unitframes-font-flags"])
		PowerRight:SetPoint("RIGHT", Power, -3, 0)
		PowerRight:SetJustifyH("RIGHT")

		local PowerLeft = Power:CreateFontString(nil, "OVERLAY")
		Y:SetFontInfo(PowerLeft, C["unitframes-font"], C["unitframes-font-size"], C["unitframes-font-flags"])
		PowerLeft:SetPoint("LEFT", Power, 3, 0)
		PowerLeft:SetJustifyH("LEFT")

		--[[ AdditionalPower
		local AdditionalPower = CreateFrame("StatusBar", nil, self)
		AdditionalPower:SetAllPoints(Power)
		AdditionalPower:SetStatusBarTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
		AdditionalPower:SetReverseFill(Settings["unitframes-player-power-reverse"])]]

		-- Mana regen
		if (C["unitframes-show-mana-timer"] and not Y.IsMainline) then
			local ManaTimer = CreateFrame("StatusBar", nil, Power)
			ManaTimer:SetAllPoints(Power)
			ManaTimer:SetStatusBarTexture(A:GetTexture(C.PlayerPowerTexture))
			ManaTimer:SetStatusBarColor(0, 0, 0, 0)
			ManaTimer:Hide()

			ManaTimer.Spark = ManaTimer:CreateTexture(nil, "ARTWORK")
			ManaTimer.Spark:SetSize(3, C["unitframes-player-power-height"])
			ManaTimer.Spark:SetPoint("LEFT", ManaTimer:GetStatusBarTexture(), "RIGHT", -1, 0)
			ManaTimer.Spark:SetTexture(A:GetTexture("Blank"))
			ManaTimer.Spark:SetVertexColor(1, 1, 1, 0.2)

			ManaTimer.Spark2 = ManaTimer:CreateTexture(nil, "ARTWORK")
			ManaTimer.Spark2:SetSize(1, C["unitframes-player-power-height"])
			ManaTimer.Spark2:SetPoint("CENTER", ManaTimer.Spark, 0, 0)
			ManaTimer.Spark2:SetTexture(A:GetTexture("Blank"))
			ManaTimer.Spark2:SetVertexColor(1, 1, 1, 0.8)

			self.ManaTimer = ManaTimer
		end

		-- Energy ticks
		if (C["unitframes-show-energy-timer"] and (Y.IsClassic or Y.IsTBC)) then
			local EnergyTick = CreateFrame("StatusBar", nil, Power)
			EnergyTick:SetAllPoints(Power)
			EnergyTick:SetStatusBarTexture(A:GetTexture(C.PlayerPowerTexture))
			EnergyTick:SetStatusBarColor(0, 0, 0, 0)
			EnergyTick:Hide()

			EnergyTick.Spark = EnergyTick:CreateTexture(nil, "ARTWORK")
			EnergyTick.Spark:SetSize(3, C["unitframes-player-power-height"])
			EnergyTick.Spark:SetPoint("LEFT", EnergyTick:GetStatusBarTexture(), "RIGHT", -1, 0)
			EnergyTick.Spark:SetTexture(A:GetTexture("Blank"))
			EnergyTick.Spark:SetVertexColor(1, 1, 1, 0.2)

			EnergyTick.Spark2 = EnergyTick:CreateTexture(nil, "ARTWORK")
			EnergyTick.Spark2:SetSize(1, C["unitframes-player-power-height"])
			EnergyTick.Spark2:SetPoint("CENTER", EnergyTick.Spark, 0, 0)
			EnergyTick.Spark2:SetTexture(A:GetTexture("Blank"))
			EnergyTick.Spark2:SetVertexColor(1, 1, 1, 0.8)

			self.EnergyTick = EnergyTick
		end

		-- Power prediction
		if Y.IsMainline then
			local MainBar = CreateFrame("StatusBar", nil, Power)
			MainBar:SetReverseFill(true)
			MainBar:SetPoint("TOPLEFT")
			MainBar:SetPoint("BOTTOMRIGHT")
			MainBar:SetStatusBarTexture(A:GetTexture(C.PlayerPowerTexture))
			MainBar:SetStatusBarColor(0.8, 0.1, 0.1)
			--MainBar:SetReverseFill(Settings["unitframes-player-power-reverse"])

			self.PowerPrediction = {
				mainBar = MainBar,
			}
		end

		-- Attributes
		Power.frequentUpdates = true
		Power.Smooth = true

		UF:SetPowerAttributes(Power, C["unitframes-player-power-color"])

		self:Tag(PowerLeft, C["unitframes-player-power-left"])
		self:Tag(PowerRight, C["unitframes-player-power-right"])

		self.Power = Power
		self.Power.bg = PowerBG
		self.PowerLeft = PowerLeft
		self.PowerRight = PowerRight
		self.PowerAnchor = PowerAnchor
		--self.AdditionalPower = AdditionalPower
	end

    -- Castbar
	if C["unitframes-player-enable-castbar"] then
		local Anchor = CreateFrame("Frame", "YxUI Casting Bar", self)
		Anchor:SetSize(C["unitframes-player-cast-width"], C["unitframes-player-cast-height"])

		local Castbar = CreateFrame("StatusBar", nil, self)
		Castbar:SetSize(C["unitframes-player-cast-width"] - C["unitframes-player-cast-height"] - 1, C["unitframes-player-cast-height"])
		Castbar:SetPoint("RIGHT", Anchor, 0, 0)
		Castbar:SetStatusBarTexture(A:GetTexture(C["ui-widget-texture"]))
        Castbar:CreateBorder()

		local CastbarBG = Castbar:CreateTexture(nil, "ARTWORK")
		CastbarBG:SetPoint("TOPLEFT", Castbar, 0, 0)
		CastbarBG:SetPoint("BOTTOMRIGHT", Castbar, 0, 0)
		CastbarBG:SetTexture(A:GetTexture(C["ui-widget-texture"]))
		CastbarBG:SetAlpha(0.2)

		local Background = Castbar:CreateTexture(nil, "BACKGROUND")
		Background:SetPoint("TOPLEFT", Castbar, -(C["unitframes-player-cast-height"] + 2), 1)
		Background:SetPoint("BOTTOMRIGHT", Castbar, 1, -1)
		Background:SetTexture(A:GetTexture("Blank"))
		Background:SetVertexColor(0, 0, 0)

		local Time = Castbar:CreateFontString(nil, "OVERLAY")
		Y:SetFontInfo(Time, C["unitframes-font"], C["unitframes-font-size"], C["unitframes-font-flags"])
		Time:SetPoint("RIGHT", Castbar, -5, 0)
		Time:SetJustifyH("RIGHT")

		local Text = Castbar:CreateFontString(nil, "OVERLAY")
		Y:SetFontInfo(Text, C["unitframes-font"], C["unitframes-font-size"], C["unitframes-font-flags"])
		Text:SetPoint("LEFT", Castbar, 5, 0)
		Text:SetSize(C["unitframes-player-cast-width"] * 0.7, C["unitframes-font-size"])
		Text:SetJustifyH("LEFT")

		local Icon = Castbar:CreateTexture(nil, "OVERLAY")
		Icon:SetSize(C["unitframes-player-cast-height"], C["unitframes-player-cast-height"])
		Icon:SetPoint("TOPRIGHT", Castbar, "TOPLEFT", -6, 0)
		Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

		local Button = CreateFrame("Frame", nil, Castbar)
		Button:CreateBorder()
		Button:SetAllPoints(Icon)
		Button:SetFrameLevel(Castbar:GetFrameLevel())

		local SafeZone = Castbar:CreateTexture(nil, "ARTWORK")
		SafeZone:SetTexture(A:GetTexture(C["ui-widget-texture"]))
		SafeZone:SetVertexColor(0.9, 0.15, 0.15, 0.75)

		Castbar.bg = CastbarBG
		Castbar.Time = Time
		Castbar.Text = Text
		Castbar.Icon = Icon
		Castbar.SafeZone = SafeZone
		Castbar.showTradeSkills = true
		Castbar.timeToHold = 0.7
		Castbar.ClassColor = C["unitframes-player-cast-classcolor"]
		Castbar.PostCastStart = UF.PostCastStart
		Castbar.PostCastStop = UF.PostCastStop
		Castbar.PostCastFail = UF.PostCastFail
		Castbar.PostCastInterruptible = UF.PostCastInterruptible

		self.Castbar = Castbar
		self.CastAnchor = Anchor
	end

    if C["unitframes-player-enable-swingbar"] then
		local SwingTimer = CreateFrame("Frame", "YxUI Casting Bar", self)
		SwingTimer:SetSize(C["unitframes-player-swing-width"], C["unitframes-player-swing-height"])

        local MainHand = CreateFrame("StatusBar", nil, SwingTimer) do
            MainHand:SetSize(C["unitframes-player-swing-width"], (C["unitframes-player-swing-height"] - 2) / 2)
            MainHand:SetPoint("RIGHT", SwingTimer, 0, 0)
            MainHand:SetStatusBarTexture(A:GetTexture(C["ui-widget-texture"]))
            local bg = MainHand:CreateTexture(nil, "ARTWORK")
            bg:SetAllPoints()
            bg:SetTexture(A:GetTexture(C["ui-widget-texture"]))
            bg.multiplier = 0.15
            MainHand.bg = bg
        end

        local OffHand = CreateFrame("StatusBar", nil, SwingTimer) do
            OffHand:SetSize(C["unitframes-player-swing-width"], (C["unitframes-player-swing-height"] - 2) / 2)
            OffHand:SetPoint("TOP", MainHand, "BOTTOM", 0, -1)
            OffHand:SetStatusBarTexture(A:GetTexture(C["ui-widget-texture"]))
            local bg = OffHand:CreateTexture(nil, "ARTWORK")
            bg:SetAllPoints()
            bg:SetTexture(A:GetTexture(C["ui-widget-texture"]))
            bg.multiplier = 0.15
            OffHand.bg = bg
        end

        self.SwingTimer = SwingTimer
        self.SwingTimer.MainHand = MainHand
        self.SwingTimer.OffHand = OffHand
    end

	if C["unitframes-player-enable-resource"] then
		local ResourceAnchor = CreateFrame("Frame", "YxUI Class Resource", Y.UIParent)
		ResourceAnchor:SetSize(C["unitframes-player-width"], C["player-resource-height"] + 2)
		ResourceAnchor:SetPoint("CENTER", Y.UIParent, 0, -120)
		Y:CreateMover(ResourceAnchor)

		if (Y.UserClass == "ROGUE" or Y.UserClass == "DRUID") then
			local ComboPoints = CreateFrame("Frame", self:GetName() .. "ComboPoints", self, "BackdropTemplate")
			ComboPoints:SetSize(C["unitframes-player-width"], C["player-resource-height"] + 2)
			ComboPoints:SetBackdrop(Y.Backdrop)
			ComboPoints:SetBackdropColor(0, 0, 0)
			ComboPoints:SetBackdropBorderColor(0, 0, 0)

			if C["player-move-resource"] then
				ComboPoints:SetPoint("CENTER", ResourceAnchor, 0, 0)
			else
				ComboPoints:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, -1)
			end

			local Max = Y.UserClass == "DRUID" and 5 or (not Y.IsMainline and 5 or 7)
			local Width = (C["unitframes-player-width"] / Max) - 1

			for i = 1, Max do
				ComboPoints[i] = CreateFrame("StatusBar", self:GetName() .. "ComboPoint" .. i, ComboPoints)
				ComboPoints[i]:SetSize(Width, C["player-resource-height"])
				ComboPoints[i]:SetStatusBarTexture(A:GetTexture(C.PlayerResourceTexture))
				ComboPoints[i]:SetStatusBarColor(Y.ComboPoints[i][1], Y.ComboPoints[i][2], Y.ComboPoints[i][3])
				ComboPoints[i]:SetWidth(i == 1 and Width - 1 or Width)

				ComboPoints[i].BG = ComboPoints:CreateTexture(nil, "BORDER")
				ComboPoints[i].BG:SetAllPoints(ComboPoints[i])
				ComboPoints[i].BG:SetTexture(A:GetTexture(C.PlayerResourceTexture))
				ComboPoints[i].BG:SetVertexColor(Y.ComboPoints[i][1], Y.ComboPoints[i][2], Y.ComboPoints[i][3])
				ComboPoints[i].BG:SetAlpha(0.3)

				if Y.IsMainline then
					ComboPoints[i].Charged = ComboPoints[i]:CreateTexture(nil, "ARTWORK")
					ComboPoints[i].Charged:SetAllPoints()
					ComboPoints[i].Charged:SetTexture(A:GetTexture(C.PlayerResourceTexture))
					ComboPoints[i].Charged:SetVertexColor(Y:HexToRGB(C["color-combo-charged"]))
					ComboPoints[i].Charged:Hide()
				end

				if (i == 1) then
					ComboPoints[i]:SetPoint("LEFT", ComboPoints, 1, 0)
				else
					ComboPoints[i]:SetPoint("TOPLEFT", ComboPoints[i-1], "TOPRIGHT", 1, 0)
				end
			end

			self.ComboPoints = ComboPoints
			self.AuraParent = ComboPoints
		elseif (Y.UserClass == "WARLOCK" and (Y.IsMainline or Y.IsCata)) then
			local Count = Y.IsMainline and 5 or 3
		
			local SoulShards = CreateFrame("Frame", self:GetName() .. "SoulShards", self, "BackdropTemplate")
			SoulShards:SetSize(C["unitframes-player-width"], C["player-resource-height"] + 2)
			SoulShards:SetBackdrop(Y.Backdrop)
			SoulShards:SetBackdropColor(0, 0, 0)
			SoulShards:SetBackdropBorderColor(0, 0, 0)

			if C["player-move-resource"] then
				SoulShards:SetPoint("CENTER", ResourceAnchor, 0, 0)
			else
				SoulShards:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, -1)
			end

			local Width = (C["unitframes-player-width"] / Count) - 1

			for i = 1, Count do
				SoulShards[i] = CreateFrame("StatusBar", self:GetName() .. "SoulShard" .. i, SoulShards)
				SoulShards[i]:SetSize(Width, C["player-resource-height"])
				SoulShards[i]:SetStatusBarTexture(A:GetTexture(C.PlayerResourceTexture))
				SoulShards[i]:SetStatusBarColor(Y:HexToRGB(C["color-soul-shards"]))
				SoulShards[i]:SetWidth(i == 1 and Width - 1 or Width)

				SoulShards[i].bg = SoulShards:CreateTexture(nil, "BORDER")
				SoulShards[i].bg:SetAllPoints(SoulShards[i])
				SoulShards[i].bg:SetTexture(A:GetTexture(C.PlayerResourceTexture))
				SoulShards[i].bg:SetVertexColor(Y:HexToRGB(C["color-soul-shards"]))
				SoulShards[i].bg:SetAlpha(0.3)

				if (i == 1) then
					SoulShards[i]:SetPoint("LEFT", SoulShards, 1, 0)
				else
					SoulShards[i]:SetPoint("TOPLEFT", SoulShards[i-1], "TOPRIGHT", 1, 0)
				end
			end

			self.ClassPower = SoulShards
			self.SoulShards = SoulShards
			self.AuraParent = SoulShards
		elseif (Y.UserClass == "MAGE" and Y.IsMainline) then
			local ArcaneCharges = CreateFrame("Frame", self:GetName() .. "ArcaneCharges", self, "BackdropTemplate")
			ArcaneCharges:SetSize(C["unitframes-player-width"], C["player-resource-height"] + 2)
			ArcaneCharges:SetBackdrop(Y.Backdrop)
			ArcaneCharges:SetBackdropColor(0, 0, 0)
			ArcaneCharges:SetBackdropBorderColor(0, 0, 0)

			if C["player-move-resource"] then
				ArcaneCharges:SetPoint("CENTER", ResourceAnchor, 0, 0)
			else
				ArcaneCharges:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, -1)
			end

			local Width = (C["unitframes-player-width"] / 4) - 1

			for i = 1, 4 do
				ArcaneCharges[i] = CreateFrame("StatusBar", self:GetName() .. "ArcaneCharge" .. i, ArcaneCharges)
				ArcaneCharges[i]:SetSize(Width, C["player-resource-height"])
				ArcaneCharges[i]:SetStatusBarTexture(A:GetTexture(C.PlayerResourceTexture))
				ArcaneCharges[i]:SetStatusBarColor(Y:HexToRGB(C["color-arcane-charges"]))
				ArcaneCharges[i]:SetWidth(i == 1 and Width - 1 or Width)

				ArcaneCharges[i].bg = ArcaneCharges:CreateTexture(nil, "BORDER")
				ArcaneCharges[i].bg:SetAllPoints(ArcaneCharges[i])
				ArcaneCharges[i].bg:SetTexture(A:GetTexture(C.PlayerResourceTexture))
				ArcaneCharges[i].bg:SetVertexColor(Y:HexToRGB(C["color-arcane-charges"]))
				ArcaneCharges[i].bg:SetAlpha(0.3)

				if (i == 1) then
					ArcaneCharges[i]:SetPoint("LEFT", ArcaneCharges, 1, 0)
				else
					ArcaneCharges[i]:SetPoint("TOPLEFT", ArcaneCharges[i-1], "TOPRIGHT", 1, 0)
				end
			end

			self.ClassPower = ArcaneCharges
			self.ArcaneCharges = ArcaneCharges
			self.AuraParent = ArcaneCharges
		elseif (Y.UserClass == "MONK") then
			local Chi = CreateFrame("Frame", self:GetName() .. "Chi", self, "BackdropTemplate")
			Chi:SetSize(C["unitframes-player-width"], C["player-resource-height"] + 2)
			Chi:SetBackdrop(Y.Backdrop)
			Chi:SetBackdropColor(0, 0, 0)
			Chi:SetBackdropBorderColor(0, 0, 0)

			if C["player-move-resource"] then
				Chi:SetPoint("CENTER", ResourceAnchor, 0, 0)
			else
				Chi:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, -1)
			end

			local Width = (C["unitframes-player-width"] / 6) - 1

			for i = 1, 6 do
				Chi[i] = CreateFrame("StatusBar", self:GetName() .. "Chi" .. i, Chi)
				Chi[i]:SetSize(Width, C["player-resource-height"])
				Chi[i]:SetStatusBarTexture(A:GetTexture(C.PlayerResourceTexture))
				Chi[i]:SetStatusBarColor(Y:HexToRGB(C["color-chi"]))
				Chi[i]:SetWidth(i == 1 and Width - 1 or Width)

				Chi[i].bg = Chi:CreateTexture(nil, "BORDER")
				Chi[i].bg:SetAllPoints(Chi[i])
				Chi[i].bg:SetTexture(A:GetTexture(C.PlayerResourceTexture))
				Chi[i].bg:SetVertexColor(Y:HexToRGB(C["color-chi"]))
				Chi[i].bg:SetAlpha(0.3)

				if (i == 1) then
					Chi[i]:SetPoint("LEFT", Chi, 1, 0)
				else
					Chi[i]:SetPoint("TOPLEFT", Chi[i-1], "TOPRIGHT", 1, 0)
				end
			end

			local Stagger = CreateFrame("StatusBar", nil, self)
			Stagger:SetSize(C["unitframes-player-width"] - 2, C["player-resource-height"])
			Stagger:SetStatusBarTexture(A:GetTexture(C.PlayerResourceTexture))
			Stagger:Hide()

			if C["player-move-resource"] then
				Stagger:SetPoint("CENTER", ResourceAnchor, 0, 0)
			else
				Stagger:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 1, 0)
			end

			Stagger.bg = Stagger:CreateTexture(nil, "ARTWORK")
			Stagger.bg:SetAllPoints()
			Stagger.bg:SetTexture(A:GetTexture(C.PlayerResourceTexture))
			Stagger.bg.multiplier = 0.3

			Stagger.Backdrop = Stagger:CreateTexture(nil, "BACKGROUND")
			Stagger.Backdrop:SetPoint("TOPLEFT", Stagger, -1, 1)
			Stagger.Backdrop:SetPoint("BOTTOMRIGHT", Stagger, 1, -1)
			Stagger.Backdrop:SetColorTexture(0, 0, 0)

			self.Stagger = Stagger
			self.ClassPower = Chi
			self.Chi = Chi
			self.AuraParent = Chi
		elseif (Y.UserClass == "DEATHKNIGHT") then
			local Runes = CreateFrame("Frame", self:GetName() .. "Runes", self, "BackdropTemplate")
			Runes:SetSize(C["unitframes-player-width"], C["player-resource-height"] + 2)
			Runes:SetBackdrop(Y.Backdrop)
			Runes:SetBackdropColor(0, 0, 0)
			Runes:SetBackdropBorderColor(0, 0, 0)
			Runes.sortOrder = "asc" -- desc

			if C["player-move-resource"] then
				Runes:SetPoint("CENTER", ResourceAnchor, 0, 0)
			else
				Runes:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, -1)
			end

			local Width = (C["unitframes-player-width"] / 6) - 1

			for i = 1, 6 do
				Runes[i] = CreateFrame("StatusBar", self:GetName() .. "Rune" .. i, Runes)
				Runes[i]:SetSize(Width, C["player-resource-height"])
				Runes[i]:SetStatusBarTexture(A:GetTexture(C.PlayerResourceTexture))
				Runes[i]:SetStatusBarColor(Y:HexToRGB(C["color-runes"]))
				Runes[i]:SetWidth(i == 1 and Width - 1 or Width)
				Runes[i].Duration = 0

				Runes[i].bg = Runes[i]:CreateTexture(nil, "BORDER")
				Runes[i].bg:SetAllPoints(Runes[i])
				Runes[i].bg:SetTexture(A:GetTexture(C.PlayerResourceTexture))
				Runes[i].bg:SetVertexColor(Y:HexToRGB(C["color-runes"]))
				Runes[i].bg:SetAlpha(0.2)

				Runes[i].Shine = Runes[i]:CreateTexture(nil, "ARTWORK")
				Runes[i].Shine:SetAllPoints(Runes[i])
				Runes[i].Shine:SetTexture(A:GetTexture("pHishTex28"))
				Runes[i].Shine:SetVertexColor(0.8, 0.8, 0.8)
				Runes[i].Shine:SetAlpha(0)
				Runes[i].Shine:SetDrawLayer("ARTWORK", 7)

				Runes[i].ReadyAnim = LibMotion:CreateAnimationGroup()

				Runes[i].ReadyAnim.In = LibMotion:CreateAnimation(Runes[i].Shine, "Fade")
				Runes[i].ReadyAnim.In:SetGroup(Runes[i].ReadyAnim)
				Runes[i].ReadyAnim.In:SetOrder(1)
				Runes[i].ReadyAnim.In:SetEasing("in")
				Runes[i].ReadyAnim.In:SetDuration(0.2)
				Runes[i].ReadyAnim.In:SetChange(0.5)

				Runes[i].ReadyAnim.Out = LibMotion:CreateAnimation(Runes[i].Shine, "Fade")
				Runes[i].ReadyAnim.Out:SetGroup(Runes[i].ReadyAnim)
				Runes[i].ReadyAnim.Out:SetOrder(2)
				Runes[i].ReadyAnim.Out:SetEasing("out")
				Runes[i].ReadyAnim.Out:SetDuration(0.2)
				Runes[i].ReadyAnim.Out:SetChange(0)

				if (i == 1) then
					Runes[i]:SetPoint("LEFT", Runes, 1, 0)
				else
					Runes[i]:SetPoint("TOPLEFT", Runes[i-1], "TOPRIGHT", 1, 0)
				end
			end

			self.Runes = Runes
			self.AuraParent = Runes
		elseif (Y.UserClass == "PALADIN" and (Y.ClientVersion > 40000)) then
			local Count = Y.IsMainline and 5 or 3
		
			local HolyPower = CreateFrame("Frame", self:GetName() .. "HolyPower", self, "BackdropTemplate")
			HolyPower:SetSize(C["unitframes-player-width"], C["player-resource-height"] + 2)
			HolyPower:SetBackdrop(Y.Backdrop)
			HolyPower:SetBackdropColor(0, 0, 0)
			HolyPower:SetBackdropBorderColor(0, 0, 0)

			if C["player-move-resource"] then
				HolyPower:SetPoint("CENTER", ResourceAnchor, 0, 0)
			else
				HolyPower:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, -1)
			end

			local Width = (C["unitframes-player-width"] / Count) - 1

			for i = 1, Count do
				HolyPower[i] = CreateFrame("StatusBar", self:GetName() .. "HolyPower" .. i, HolyPower)
				HolyPower[i]:SetSize(Width, C["player-resource-height"])
				HolyPower[i]:SetStatusBarTexture(A:GetTexture(C.PlayerResourceTexture))
				HolyPower[i]:SetStatusBarColor(Y:HexToRGB(C["color-holy-power"]))
				HolyPower[i]:SetWidth(i == 1 and Width - 1 or Width)

				HolyPower[i].bg = HolyPower:CreateTexture(nil, "BORDER")
				HolyPower[i].bg:SetAllPoints(HolyPower[i])
				HolyPower[i].bg:SetTexture(A:GetTexture(C.PlayerResourceTexture))
				HolyPower[i].bg:SetVertexColor(Y:HexToRGB(C["color-holy-power"]))
				HolyPower[i].bg:SetAlpha(0.3)

				if (i == 1) then
					HolyPower[i]:SetPoint("LEFT", HolyPower, 1, 0)
				else
					HolyPower[i]:SetPoint("TOPLEFT", HolyPower[i-1], "TOPRIGHT", 1, 0)
				end
			end

			self.ClassPower = HolyPower
			self.HolyPower = HolyPower
			self.AuraParent = HolyPower
		elseif (Y.UserClass == "SHAMAN") and (not Y.IsMainline) then
			local Totems = CreateFrame("Frame", self:GetName() .. "Totems", self, "BackdropTemplate")
			Totems:SetSize(C["unitframes-player-width"], C["player-resource-height"] + 2)
			Totems:SetBackdrop(Y.Backdrop)
			Totems:SetBackdropColor(0, 0, 0)
			Totems:SetBackdropBorderColor(0, 0, 0)
			Totems.PostUpdate = UF.PostUpdateTotems

			if C["player-move-resource"] then
				Totems:SetPoint("CENTER", ResourceAnchor, 0, 0)
			else
				Totems:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, -1)
			end

			--[[local TotemBar = CreateFrame("Frame", "YxUI Totem Bar", YxUI.UIParent)
			TotemBar:SetSize(40 * 4 + 5, 40 + 2)
			TotemBar:SetPoint("CENTER", YxUI.UIParent, 0, -120)
			TotemBar:SetMovable("CENTER", YxUI.UIParent, 0, -120)
			--YxUI:CreateMover(TotemBar)
			TotemBar:EnableMouse(true)
			TotemBar:RegisterForDrag("LeftButton")
			TotemBar:SetUserPlaced(true)
			TotemBar:SetScript("OnDragStart", TotemBar.StartMoving)
			TotemBar:SetScript("OnDragStop", TotemBar.StopMovingOrSizing)

			TotemBar.bg = TotemBar:CreateTexture(nil, "BACKGROUND")
			TotemBar.bg:SetAllPoints()
			TotemBar.bg:SetTexture(Assets:GetTexture("Blank"))
			TotemBar.bg:SetVertexColor(0, 0, 0)]]

			local Width = (C["unitframes-player-width"] / 4) - 1

			for i = 1, 4 do
				Totems[i] = CreateFrame("Button", nil, self)
				Totems[i]:SetSize(40, 40)

				--[[Totems[i].bg = Totems:CreateTexture(nil, "BACKGROUND")
				Totems[i].bg:SetAllPoints(Totems[i])
				Totems[i].bg:SetTexture(Assets:GetTexture("Blank"))
				Totems[i].bg:SetVertexColor(YxUI.TotemColors[i][1], YxUI.TotemColors[i][2], YxUI.TotemColors[i][3], 0.3)

				Totems[i].Icon = Totems[i]:CreateTexture(nil, "OVERLAY")
				Totems[i].Icon:SetPoint("TOPLEFT", 0, 0)
				Totems[i].Icon:SetPoint("BOTTOMRIGHT", 0, 0)
				Totems[i].Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

				Totems[i].Cooldown = CreateFrame("Cooldown", nil, Totems[i], "CooldownFrameTemplate")
				Totems[i].Cooldown:SetAllPoints()

				local Cooldown = Totems[i].Cooldown:GetRegions()

				if Cooldown then
					YxUI:SetFontInfo(Cooldown, Settings["unitframes-font"], 18, Settings["unitframes-font-flags"])
				end]]

				Totems[i].Bar = CreateFrame("StatusBar", self:GetName() .. "Totems" .. i, Totems)
				Totems[i].Bar:SetSize(Width, C["player-resource-height"])
				Totems[i].Bar:SetStatusBarTexture(A:GetTexture(C.PlayerResourceTexture))
				Totems[i].Bar:SetStatusBarColor(Y.TotemColors[i][1], Y.TotemColors[i][2], Y.TotemColors[i][3])
				Totems[i].Bar:SetWidth(i == 1 and Width - 1 or Width)
				Totems[i].Bar:EnableMouse(true)
				Totems[i].Bar:SetID(i)
				Totems[i].Bar:Hide()

				Totems[i].bg = Totems:CreateTexture(nil, "BORDER")
				Totems[i].bg:SetAllPoints(Totems[i].Bar)
				Totems[i].bg:SetTexture(A:GetTexture(C.PlayerResourceTexture))
				Totems[i].bg:SetVertexColor(Y.TotemColors[i][1], Y.TotemColors[i][2], Y.TotemColors[i][3])
				Totems[i].bg:SetAlpha(0.3)

				if (i == 1) then
					--Totems[i]:SetPoint("LEFT", TotemBar, 1, 0)
					Totems[i].Bar:SetPoint("LEFT", Totems, 1, 0)
				else
					--Totems[i]:SetPoint("LEFT", Totems[i-1], "RIGHT", 1, 0)
					Totems[i].Bar:SetPoint("TOPLEFT", Totems[i-1].Bar, "TOPRIGHT", 1, 0)
				end
			end

			self.ClassPower = Totems
			self.Totems = Totems
			self.AuraParent = Totems
		elseif (Y.UserClass == "EVOKER") then
			local Essence = CreateFrame("Frame", self:GetName() .. "Essence", self, "BackdropTemplate")
			Essence:SetSize(C["unitframes-player-width"], C["player-resource-height"] + 2)
			Essence:SetBackdrop(Y.Backdrop)
			Essence:SetBackdropColor(0, 0, 0)
			Essence:SetBackdropBorderColor(0, 0, 0)

			if C["player-move-resource"] then
				Essence:SetPoint("CENTER", ResourceAnchor, 0, 0)
			else
				Essence:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, -1)
			end

			local Width = (C["unitframes-player-width"] / 6) - 1

			for i = 1, 6 do
				Essence[i] = CreateFrame("StatusBar", self:GetName() .. "Essence" .. i, Essence)
				Essence[i]:SetSize(Width, C["player-resource-height"])
				Essence[i]:SetStatusBarTexture(A:GetTexture(C.PlayerResourceTexture))
				Essence[i]:SetStatusBarColor(Y:HexToRGB(C["color-essence"]))
				Essence[i]:SetWidth(i == 1 and Width - 1 or Width)

				Essence[i].bg = Essence:CreateTexture(nil, "BORDER")
				Essence[i].bg:SetAllPoints(Essence[i])
				Essence[i].bg:SetTexture(A:GetTexture(C.PlayerResourceTexture))
				Essence[i].bg:SetVertexColor(Y:HexToRGB(C["color-essence"]))
				Essence[i].bg:SetAlpha(0.3)

				if (i == 1) then
					Essence[i]:SetPoint("LEFT", Essence, 1, 0)
				else
					Essence[i]:SetPoint("TOPLEFT", Essence[i-1], "TOPRIGHT", 1, 0)
				end
			end

			self.ClassPower = Essence
			self.Essence = Essence
			self.AuraParent = Essence
		end

		self.ResourceAnchor = ResourceAnchor
	end

	-- Threat
	local Threat = CreateFrame("Frame", nil, self, "BackdropTemplate")

	if C["player-move-resource"] then
		Threat:SetPoint("TOPLEFT", -1, 1)
		Threat:SetPoint("BOTTOMRIGHT", 1, -1)
	else
		Threat:SetPoint("TOPLEFT", self.AuraParent, -1, 1)
		Threat:SetPoint("BOTTOMRIGHT", 1, -1)
	end

	Threat:SetBackdrop(Y.Outline)
	Threat.PostUpdate = UF.ThreatPostUpdate

	self.ThreatIndicator = Threat

	-- Auras
	local Buffs = CreateFrame("Frame", self:GetName() .. "Buffs", self)
	Buffs:SetSize(C["unitframes-player-width"], C.PlayerBuffSize)
	Buffs.size = C.PlayerBuffSize
	Buffs.spacing = C.PlayerBuffSpacing
	Buffs.num = 40
	Buffs.initialAnchor = "BOTTOMLEFT"
	Buffs.tooltipAnchor = "ANCHOR_TOP"
	Buffs["growth-x"] = "RIGHT"
	Buffs["growth-y"] = "UP"
	Buffs.PostCreateIcon = UF.PostCreateIcon
	Buffs.PostUpdateIcon = UF.PostUpdateIcon

	local Debuffs = CreateFrame("Frame", self:GetName() .. "Debuffs", self)
	Debuffs:SetSize(C["unitframes-player-width"], 28)
	Debuffs.size = C.PlayerDebuffSize
	Debuffs.spacing = C.PlayerDebuffSpacing
	Debuffs.num = 16
	Debuffs.initialAnchor = "BOTTOMRIGHT"
	Debuffs.tooltipAnchor = "ANCHOR_TOP"
	Debuffs["growth-x"] = "LEFT"
	Debuffs["growth-y"] = "UP"
	Debuffs.PostCreateIcon = UF.PostCreateIcon
	Debuffs.PostUpdateIcon = UF.PostUpdateIcon
	Debuffs.onlyShowPlayer = C["unitframes-only-player-debuffs"]

	if C["player-move-resource"] then
		if C["unitframes-show-player-buffs"] then
			Buffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 1, 4)
			Debuffs:SetPoint("BOTTOM", Buffs, "TOP", 0, 2)

		else
			Debuffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 1, 4)
		end
	else
		if C["unitframes-show-player-buffs"] then
			Buffs:SetPoint("BOTTOMLEFT", self.AuraParent, "TOPLEFT", 1, 4)
			Debuffs:SetPoint("BOTTOM", Buffs, "TOP", 0, 2)
		else
			Debuffs:SetPoint("BOTTOMLEFT", self.AuraParent, "TOPLEFT", 1, 4)
		end
	end

	-- Resurrect
	local Resurrect = Health:CreateTexture(nil, "OVERLAY")
	Resurrect:SetSize(16, 16)
	Resurrect:SetPoint("CENTER", Health, 0, 0)
	Resurrect:Hide()

	do
		local RestingIndicator = CreateFrame("Frame", nil, Health)
		RestingIndicator:SetSize(5, 5)
		if C["player-portrait-style"] and C["player-portrait-style"] ~= "OVERLAY" then
			RestingIndicator:SetPoint("TOPLEFT", Portrait, "TOPLEFT", -2, 4)
		else
			RestingIndicator:SetPoint("TOPLEFT", Health, "TOPLEFT", -2, 4)
		end
		RestingIndicator:Hide()

		local textFrame = CreateFrame("Frame", nil, RestingIndicator)
		textFrame:SetAllPoints()
		textFrame:SetFrameLevel(6)

		local texts = {}
		local offsets = {
			{ 4, -4 },
			{ 0, 0 },
			{ -5, 5 },
		}

		for i = 1, 3 do
			texts[i] = Y.CreateFontString(textFrame, (7 + i * 3), "z", "", "system", "CENTER", offsets[i][1], offsets[i][2])
		end

		local step, stepSpeed = 0, 0.33

		local stepMaps = {
			[1] = { true, false, false },
			[2] = { true, true, false },
			[3] = { true, true, true },
			[4] = { false, true, true },
			[5] = { false, false, true },
			[6] = { false, false, false },
		}

		RestingIndicator:SetScript("OnUpdate", function(self, elapsed)
			self.elapsed = (self.elapsed or 0) + elapsed
			if self.elapsed > stepSpeed then
				step = step + 1
				if step == 7 then
					step = 1
				end

				for i = 1, 3 do
					texts[i]:SetShown(stepMaps[step][i])
				end

				self.elapsed = 0
			end
		end)

		RestingIndicator:SetScript("OnHide", function()
			step = 6
		end)

		self.RestingIndicator = RestingIndicator
	end

	-- Tags
	self:Tag(HealthLeft, C["unitframes-player-health-left"])
	self:Tag(HealthRight, C["unitframes-player-health-right"])

	self.Health = Health
	self.Health.bg = HealthBG
	self.HealthLeft = HealthLeft
	self.HealthRight = HealthRight
	self.CombatIndicator = Combat
	self.Buffs = Buffs
	self.Debuffs = Debuffs
	--self.RaidTargetIndicator = RaidTarget
	self.ResurrectIndicator = Resurrect
	self.LeaderIndicator = Leader
	self.PvPIndicator = PvPIndicator
end

local UpdateOnlyPlayerDebuffs = function(value)
	if Y.UnitFrames["target"] then
		Y.UnitFrames["target"].Debuffs.onlyShowPlayer = value
	end
end

local UpdatePlayerWidth = function(value)
	if Y.UnitFrames["player"] then
		local Frame = Y.UnitFrames["player"]

		Frame:SetWidth(value)

		-- Auras
		Frame.Buffs:SetWidth(value)
		Frame.Debuffs:SetWidth(value)

		if C["player-move-power"] then
			return
		end

		if Frame.ComboPoints then
			Frame.ComboPoints:SetWidth(value)

			local Max = UnitPowerMax("player", Enum.PowerType.ComboPoints)
			local Width = (C["unitframes-player-width"] / Max) - 1

			for i = 1, Max do
				Frame.ComboPoints[i]:SetWidth(i == 1 and Width - 1 or Width)
			end
		elseif Frame.SoulShards then
			Frame.SoulShards:SetWidth(value)

			local Width = (C["unitframes-player-width"] / 5) - 1

			for i = 1, 5 do
				Frame.SoulShards[i]:SetWidth(i == 1 and Width - 1 or Width)
			end
		elseif Frame.ArcanePower then
			Frame.ArcanePower:SetWidth(value)

			local Width = (C["unitframes-player-width"] / 4) - 1

			for i = 1, 4 do
				Frame.ArcanePower[i]:SetWidth(i == 1 and Width - 1 or Width)
			end
		elseif Frame.Totems then
			Frame.Totems:SetWidth(value)

			local Width = (C["unitframes-player-width"] / 4) - 1

			for i = 1, 4 do
				Frame.Totems[i]:SetWidth(i == 1 and Width - 1 or Width)
			end
		elseif Frame.Chi then
			Frame.Chi:SetWidth(value)
			Frame.Stagger:SetWidth(value)

			local Width = (C["unitframes-player-width"] / 6) - 1

			for i = 1, 6 do
				Frame.Chi[i]:SetWidth(i == 1 and Width - 1 or Width)
			end
		elseif Frame.Runes then
			Frame.Runes:SetWidth(value)

			local Width = (C["unitframes-player-width"] / 6) - 1

			for i = 1, 6 do
				Frame.Runes[i]:SetWidth(i == 1 and Width - 1 or Width)
			end
		elseif Frame.HolyPower then
			Frame.HolyPower:SetWidth(value)

			local Width = (C["unitframes-player-width"] / 5) - 1

			for i = 1, 5 do
				Frame.HolyPower[i]:SetWidth(i == 1 and Width - 1 or Width)
			end
		end
	end
end

local UpdatePlayerHealthHeight = function(value)
	if Y.UnitFrames["player"] then
		local Frame = Y.UnitFrames["player"]

		Frame.Health:SetHeight(value)
		Frame:SetHeight(value + C["unitframes-player-power-height"] + 3)
	end
end

local UpdatePlayerHealthFill = function(value)
	if Y.UnitFrames["player"] then
		local Unit = Y.UnitFrames["player"]

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

local UpdatePlayerPowerHeight = function(value)
	if Y.UnitFrames["player"] then
		local Frame = Y.UnitFrames["player"]

		Frame.Power:SetHeight(value)

		if (not C["player-move-power"]) then
			Frame:SetHeight(C["unitframes-player-health-height"] + value + 3)
		end
	end
end

local UpdatePlayerPowerFill = function(value)
	if Y.UnitFrames["player"] then
		Y.UnitFrames["player"].Power:SetReverseFill(value)
	end
end

local UpdatePlayerCastBarSize = function()
	if Y.UnitFrames["player"].Castbar then
		Y.UnitFrames["player"].Castbar:SetSize(C["unitframes-player-cast-width"], C["unitframes-player-cast-height"])
		Y.UnitFrames["player"].Castbar.Icon:SetSize(C["unitframes-player-cast-height"], C["unitframes-player-cast-height"])
	end
end

local UpdateCastClassColor = function(value)
	if Y.UnitFrames["player"].Castbar then
		Y.UnitFrames["player"].Castbar.ClassColor = value
		Y.UnitFrames["player"].Castbar:ForceUpdate()
	end
end

local UpdatePlayerHealthColor = function(value)
	if Y.UnitFrames["player"] then
		local Health = Y.UnitFrames["player"].Health

		UF:SetHealthAttributes(Health, value)

		Health:ForceUpdate()
	end
end

local UpdatePlayerPowerColor = function(value)
	if Y.UnitFrames["player"] then
		local Power = Y.UnitFrames["player"].Power

		UF:SetPowerAttributes(Power, value)

		Power:ForceUpdate()
	end
end

local UpdatePlayerEnablePortrait = function(value)
	if Y.UnitFrames["player"] then
		if value then
			Y.UnitFrames["player"]:EnableElement("Portrait")

			if Y.UnitFrames["player"].Portrait.BG then
				Y.UnitFrames["player"].Portrait.BG:Show()
			end
		else
			Y.UnitFrames["player"]:DisableElement("Portrait")

			if Y.UnitFrames["player"].Portrait.BG then
				Y.UnitFrames["player"].Portrait.BG:Hide()
			end
		end

		Y.UnitFrames["player"].Portrait:ForceUpdate()
	end
end

local UpdateOverlayAlpha = function(value)
	if Y.UnitFrames["player"] and C["player-portrait-style"] == "OVERLAY" then
		Y.UnitFrames["player"].Portrait:SetAlpha(value / 100)
	end
end

local UpdatePlayerEnablePVPIndicator = function(value)
	if Y.UnitFrames["player"] then
		if value then
			Y.UnitFrames["player"]:EnableElement("PvPIndicator")
			Y.UnitFrames["player"].PvPIndicator:ForceUpdate()
		else
			Y.UnitFrames["player"]:DisableElement("PvPIndicator")
			Y.UnitFrames["player"].PvPIndicator:Hide()
		end
	end
end

local UpdateResourceBarHeight = function(value)
	if Y.UnitFrames["player"] then
		local Frame = Y.UnitFrames["player"]

		if Frame.ComboPoints then
			Frame.ComboPoints:SetHeight(value + 2)

			local Max = UnitPowerMax("player", Enum.PowerType.ComboPoints)

			for i = 1, Max do
				Frame.ComboPoints[i]:SetHeight(value)
			end
		elseif Frame.SoulShards then
			Frame.SoulShards:SetHeight(value + 2)

			for i = 1, 5 do
				Frame.SoulShards[i]:SetHeight(value)
			end
		elseif Frame.ArcanePower then
			Frame.ArcanePower:SetHeight(value + 2)

			for i = 1, 4 do
				Frame.ArcanePower[i]:SetHeight(value)
			end
		elseif Frame.Chi then
			Frame.Chi:SetHeight(value + 2)
			Frame.Stagger:SetHeight(value)

			for i = 1, 6 do
				Frame.Chi[i]:SetHeight(value)
			end
		elseif Frame.Runes then
			Frame.Runes:SetHeight(value + 2)

			for i = 1, 6 do
				Frame.Runes[i]:SetHeight(value)
			end
		elseif Frame.HolyPower then
			Frame.HolyPower:SetHeight(value + 2)

			for i = 1, 5 do
				Frame.HolyPower[i]:SetHeight(value)
			end
		elseif Frame.Totems then
			Frame.Totems:SetHeight(value + 2)

			for i = 1, 4 do
				Frame.Totems[i]:SetHeight(value)
			end
		end
	end
end

local UpdateResourceTexture = function(value)
	if Y.UnitFrames["player"] then
		local Frame = Y.UnitFrames["player"]

		if Frame.ComboPoints then
			for i = 1, #Frame.ComboPoints do
				Frame.ComboPoints[i]:SetStatusBarTexture(A:GetTexture(value))
				Frame.ComboPoints[i].bg:SetTexture(A:GetTexture(value))
			end
		elseif Frame.SoulShards then
			for i = 1, 5 do
				Frame.SoulShards[i]:SetStatusBarTexture(A:GetTexture(value))
				Frame.SoulShards[i].bg:SetTexture(A:GetTexture(value))
			end
		elseif Frame.ArcanePower then
			for i = 1, 4 do
				Frame.ArcanePower[i]:SetStatusBarTexture(A:GetTexture(value))
				Frame.ArcanePower[i].bg:SetTexture(A:GetTexture(value))
			end
		elseif Frame.Chi then
			Frame.Stagger:SetStatusBarTexture(A:GetTexture(value))
			Frame.Stagger.bg:SetTexture(A:GetTexture(value))

			for i = 1, 6 do
				Frame.Chi[i]:SetStatusBarTexture(A:GetTexture(value))
				Frame.Chi[i].bg:SetTexture(A:GetTexture(value))
			end
		elseif Frame.Runes then
			for i = 1, 6 do
				Frame.Runes[i]:SetStatusBarTexture(A:GetTexture(value))
				Frame.Runes[i].bg:SetTexture(A:GetTexture(value))
			end
		elseif Frame.HolyPower then
			for i = 1, 5 do
				Frame.HolyPower[i]:SetStatusBarTexture(A:GetTexture(value))
				Frame.HolyPower[i].bg:SetTexture(A:GetTexture(value))
			end
		elseif Frame.Totems then
			for i = 1, 4 do
				Frame.Totems[i]:SetStatusBarTexture(A:GetTexture(value))
				Frame.Totems[i].bg:SetTexture(A:GetTexture(value))
			end
		end
	end
end

local UpdateBuffSize = function(value)
	if Y.UnitFrames["player"] then
		Y.UnitFrames["player"].Buffs.size = value
		Y.UnitFrames["player"].Buffs:SetSize(C["unitframes-player-width"], value)
		Y.UnitFrames["player"].Buffs:ForceUpdate()
	end
end

local UpdateBuffSpacing = function(value)
	if Y.UnitFrames["player"] then
		Y.UnitFrames["player"].Buffs.spacing = value
		Y.UnitFrames["player"].Buffs:ForceUpdate()
	end
end

local UpdateDebuffSize = function(value)
	if Y.UnitFrames["player"] then
		Y.UnitFrames["player"].Debuffs.size = value
		Y.UnitFrames["player"].Debuffs:SetSize(C["unitframes-player-width"], value)
		Y.UnitFrames["player"].Debuffs:ForceUpdate()
	end
end

local UpdateDebuffSpacing = function(value)
	if Y.UnitFrames["player"] then
		Y.UnitFrames["player"].Debuffs.spacing = value
		Y.UnitFrames["player"].Debuffs:ForceUpdate()
	end
end

local UpdateDisplayedAuras = function()
	if (not Y.UnitFrames["player"]) then
		return
	end

	local Player = Y.UnitFrames["player"]

	Player.Buffs:ClearAllPoints()
	Player.Debuffs:ClearAllPoints()

	if C["player-move-resource"] then
		if C["unitframes-show-player-buffs"] then
			Player.Buffs:SetPoint("BOTTOMLEFT", Player, "TOPLEFT", 0, 2)
			Player.Debuffs:SetPoint("BOTTOM", Player.Buffs, "TOP", 0, 2)

		else
			Player.Debuffs:SetPoint("BOTTOMLEFT", Player, "TOPLEFT", 0, 2)
		end
	else
		if C["unitframes-show-player-buffs"] then
			Player.Buffs:SetPoint("BOTTOMLEFT", Player.AuraParent, "TOPLEFT", 0, 2)
			Player.Debuffs:SetPoint("BOTTOM", Player.Buffs, "TOP", 0, 2)
		else
			Player.Debuffs:SetPoint("BOTTOMLEFT", Player.AuraParent, "TOPLEFT", 0, 2)
		end
	end

	if C["unitframes-show-player-buffs"] then
		Player.Buffs:Show()
	else
		Player.Buffs:Hide()
	end

	if C["unitframes-show-player-debuffs"] then
		Player.Debuffs:Show()
	else
		Player.Debuffs:Hide()
	end
end

local UpdateResourcePosition = function(value)
	if Y.UnitFrames["player"] then
		local Frame = Y.UnitFrames["player"]

		Frame.Debuffs:ClearAllPoints()
		Frame.ThreatIndicator:ClearAllPoints()

		if value then
			if C["unitframes-show-player-buffs"] then
				Frame.Buffs:ClearAllPoints()
				Frame.Buffs:SetPoint("BOTTOMLEFT", Frame, "TOPLEFT", 0, 2)
				Frame.Debuffs:SetPoint("BOTTOM", Frame.Buffs, "TOP", 0, 2)
			else
				Frame.Debuffs:SetPoint("BOTTOMLEFT", Frame, "TOPLEFT", 0, 2)
			end

			Frame.ThreatIndicator:SetPoint("TOPLEFT", Frame, -1, 1)
			Frame.ThreatIndicator:SetPoint("BOTTOMRIGHT", Frame, 1, -1)
		else
			if C["unitframes-show-player-buffs"] then
				Frame.Buffs:ClearAllPoints()
				Frame.Buffs:SetPoint("BOTTOMLEFT", Frame.AuraParent, "TOPLEFT", 0, 2)
				Frame.Debuffs:SetPoint("BOTTOM", Frame.Buffs, "TOP", 0, 2)
			else
				Frame.Debuffs:SetPoint("BOTTOMLEFT", Frame.AuraParent, "TOPLEFT", 0, 2)
			end

			Frame.ThreatIndicator:SetPoint("TOPLEFT", Frame.AuraParent, -1, 1)
			Frame.ThreatIndicator:SetPoint("BOTTOMRIGHT", 1, -1)
		end

		if Frame.ComboPoints then
			Frame.ComboPoints:ClearAllPoints()

			if value then
				Frame.ComboPoints:SetPoint("CENTER", Frame.ResourceAnchor, 0, 0)
			else
				Frame.ComboPoints:SetPoint("BOTTOMLEFT", Frame, "TOPLEFT", 0, -1)
			end
		elseif Frame.SoulShards then
			Frame.SoulShards:ClearAllPoints()

			if value then
				Frame.SoulShards:SetPoint("CENTER", Frame.ResourceAnchor, 0, 0)
			else
				Frame.SoulShards:SetPoint("BOTTOMLEFT", Frame, "TOPLEFT", 0, -1)
			end
		elseif Frame.ArcanePower then
			Frame.ArcanePower:ClearAllPoints()

			if value then
				Frame.ArcanePower:SetPoint("CENTER", Frame.ResourceAnchor, 0, 0)
			else
				Frame.ArcanePower:SetPoint("BOTTOMLEFT", Frame, "TOPLEFT", 0, -1)
			end
		elseif Frame.Chi then
			Frame.Chi:ClearAllPoints()
			Frame.Stagger:ClearAllPoints()

			if value then
				Frame.Chi:SetPoint("CENTER", Frame.ResourceAnchor, 0, 0)
				Frame.Stagger:SetPoint("CENTER", Frame.ResourceAnchor, 0, 0)
			else
				Frame.Chi:SetPoint("BOTTOMLEFT", Frame, "TOPLEFT", 0, -1)
				Frame.Stagger:SetPoint("BOTTOMLEFT", Frame, "TOPLEFT", 0, -1)
			end
		elseif Frame.Runes then
			Frame.Runes:ClearAllPoints()

			if value then
				Frame.Runes:SetPoint("CENTER", Frame.ResourceAnchor, 0, 0)
			else
				Frame.Runes:SetPoint("BOTTOMLEFT", Frame, "TOPLEFT", 0, -1)
			end
		elseif Frame.HolyPower then
			Frame.HolyPower:ClearAllPoints()

			if value then
				Frame.HolyPower:SetPoint("CENTER", Frame.ResourceAnchor, 0, 0)
			else
				Frame.HolyPower:SetPoint("BOTTOMLEFT", Frame, "TOPLEFT", 0, -1)
			end
		elseif Frame.Totems then
			Frame.Totems:ClearAllPoints()

			if value then
				Frame.Totems:SetPoint("CENTER", Frame.ResourceAnchor, 0, 0)
			else
				Frame.Totems:SetPoint("BOTTOMLEFT", Frame, "TOPLEFT", 0, -1)
			end
		end
	end
end

local UpdatePowerBarPosition = function(value)
	if Y.UnitFrames["player"] then
		local Frame = Y.UnitFrames["player"]

		Frame.Power:ClearAllPoints()

		if value then
			Frame:SetHeight(C["unitframes-player-health-height"] + 2)

			Frame.Power:SetPoint("BOTTOMLEFT", Frame.PowerAnchor, 1, 1)
			Frame.Power:SetPoint("BOTTOMRIGHT", Frame.PowerAnchor, -1, 1)
		else
			Frame:SetHeight(C["unitframes-player-health-height"] + C["unitframes-player-power-height"] + 3)

			Frame.Power:SetPoint("BOTTOMLEFT", Frame, 1, 1)
			Frame.Power:SetPoint("BOTTOMRIGHT", Frame, -1, 1)
		end
	end
end

local UpdateHealthTexture = function(value)
	if Y.UnitFrames["player"] then
		local Frame = Y.UnitFrames["player"]

		Frame.Health:SetStatusBarTexture(A:GetTexture(value))
		Frame.Health.bg:SetTexture(A:GetTexture(value))
		Frame.HealBar:SetStatusBarTexture(A:GetTexture(value))

		if Frame.AbsorbsBar then
			Frame.AbsorbsBar:SetStatusBarTexture(A:GetTexture(value))
		end
	end
end

local UpdatePowerTexture = function(value)
	if Y.UnitFrames["player"] then
		local Frame = Y.UnitFrames["player"]

		Frame.Power:SetStatusBarTexture(A:GetTexture(value))
		Frame.Power.bg:SetTexture(A:GetTexture(value))

		if Frame.ManaTimer then
			Frame.ManaTimer:SetStatusBarTexture(A:GetTexture(value))
		end

		if Frame.EnergyTick then
			Frame.EnergyTick:SetStatusBarTexture(A:GetTexture(value))
		end

		if Frame.PowerPrediction then
			Frame.PowerPrediction.mainBar:SetStatusBarTexture(A:GetTexture(value))
		end
	end
end

Y:GetModule("GUI"):AddWidgets(L["General"], L["Player"], L["Unit Frames"], function(left, right)
	left:CreateHeader(L["Styling"])
	left:CreateSwitch("player-enable", C["player-enable"], L["Enable Player"], L["Enable the player unit frame"], ReloadUI):RequiresReload(true)
	left:CreateSlider("unitframes-player-width", C["unitframes-player-width"], 120, 320, 1, L["Width"], L["Set the width of the player unit frame"], UpdatePlayerWidth)
	left:CreateSwitch("player-enable-pvp", C["player-enable-pvp"], L["Enable PVP Indicator"], L["Display the pvp indicator"], UpdatePlayerEnablePVPIndicator)

	if (Y.IsClassic or Y.IsTBC) then
		left:CreateSwitch("unitframes-show-mana-timer", C["unitframes-show-mana-timer"], L["Enable Mana Regen Timer"], L["Display the time until your full mana regeneration is active"], ReloadUI):RequiresReload(true)
		left:CreateSwitch("unitframes-show-energy-timer", C["unitframes-show-energy-timer"], L["Enable Energy Timer"], L["Display the time until your next energy tick on the power bar"], ReloadUI):RequiresReload(true)
	end

	left:CreateSwitch("player-enable-portrait", C["player-enable-portrait"], L["Enable Portrait"], L["Display the player unit portrait"], UpdatePlayerEnablePortrait)
	left:CreateDropdown("player-portrait-style", C["player-portrait-style"], {[L["2D"]] = "2D", [L["3D"]] = "3D", [L["Overlay"]] = "OVERLAY"}, L["Set Portrait Style"], L["Set the style of the portrait"], ReloadUI):RequiresReload(true)
	left:CreateSlider("player-overlay-alpha", C["player-overlay-alpha"], 0, 100, 5, L["Set Overlay Opacity"], L["Set the opacity of the portrait overlay"], UpdateOverlayAlpha, nil, "%")

	left:CreateHeader(L["Health"])
	left:CreateSwitch("unitframes-player-health-reverse", C["unitframes-player-health-reverse"], L["Reverse Health Fill"], L["Reverse the fill of the health bar"], UpdatePlayerHealthFill)
	left:CreateSlider("unitframes-player-health-height", C["unitframes-player-health-height"], 6, 60, 1, L["Health Bar Height"], L["Set the height of the player health bar"], UpdatePlayerHealthHeight)
	left:CreateDropdown("unitframes-player-health-color", C["unitframes-player-health-color"], {[L["Class"]] = "CLASS", [L["Reaction"]] = "REACTION", [L["Custom"]] = "CUSTOM"}, L["Health Bar Color"], L["Set the color of the health bar"], UpdatePlayerHealthColor)
	left:CreateInput("unitframes-player-health-left", C["unitframes-player-health-left"], L["Left Health Text"], L["Set the text on the left of the player health bar"], ReloadUI):RequiresReload(true)
	left:CreateInput("unitframes-player-health-right", C["unitframes-player-health-right"], L["Right Health Text"], L["Set the text on the right of the player health bar"], ReloadUI):RequiresReload(true)
	left:CreateDropdown("PlayerHealthTexture", C.PlayerHealthTexture, A:GetTextureList(), L["Health Texture"], "", UpdateHealthTexture, "Texture")

	left:CreateHeader(L["Buffs"])
	left:CreateSwitch("unitframes-show-player-buffs", C["unitframes-show-player-buffs"], L["Show Player Buffs"], L["Show your auras above the player unit frame"], UpdateDisplayedAuras)
	left:CreateSlider("PlayerBuffSize", C.PlayerBuffSize, 26, 50, 2, L["Set Size"], L["Set the size of the auras"], UpdateBuffSize)
	left:CreateSlider("PlayerBuffSpacing", C.PlayerBuffSpacing, -1, 10, 1, L["Set Spacing"], L["Set the spacing between the auras"], UpdateBuffSpacing)

	left:CreateHeader(L["Debuffs"])
	left:CreateSwitch("unitframes-show-player-debuffs", C["unitframes-show-player-debuffs"], L["Show Player Debuffs"], L["Show your debuff auras above the player unit frame"], UpdateDisplayedAuras)
	left:CreateSlider("PlayerDebuffSize", C.PlayerDebuffSize, 26, 50, 2, L["Set Size"], L["Set the size of the auras"], UpdateDebuffSize)
	left:CreateSlider("PlayerDebuffSpacing", C.PlayerDebuffSpacing, -1, 10, 1, L["Set Spacing"], L["Set the spacing between the auras"], UpdateDebuffSpacing)

	right:CreateHeader(L["Power"])
	right:CreateSwitch("unitframes-player-enable-power", C["unitframes-player-enable-power"], L["Enable Power Bar"], L["Enable the player power bar"], ReloadUI):RequiresReload(true)
	right:CreateSwitch("unitframes-player-power-reverse", C["unitframes-player-power-reverse"], L["Reverse Power Fill"], L["Reverse the fill of the power bar"], UpdatePlayerPowerFill)
	right:CreateSwitch("player-move-power", C["player-move-power"], L["Detach Power"], L["Detach the power bar from the unit frame"], UpdatePowerBarPosition)
	right:CreateSlider("unitframes-player-power-height", C["unitframes-player-power-height"], 2, 30, 1, L["Power Bar Height"], L["Set the height of the player power bar"], UpdatePlayerPowerHeight)
	right:CreateDropdown("unitframes-player-power-color", C["unitframes-player-power-color"], {[L["Class"]] = "CLASS", [L["Reaction"]] = "REACTION", [L["Power Type"]] = "POWER"}, L["Power Bar Color"], L["Set the color of the power bar"], UpdatePlayerPowerColor)
	right:CreateInput("unitframes-player-power-left", C["unitframes-player-power-left"], L["Left Power Text"], L["Set the text on the left of the player power bar"], ReloadUI):RequiresReload(true)
	right:CreateInput("unitframes-player-power-right", C["unitframes-player-power-right"], L["Right Power Text"], L["Set the text on the right of the player power bar"], ReloadUI):RequiresReload(true)
	right:CreateDropdown("PlayerPowerTexture", C.PlayerPowerTexture, A:GetTextureList(), L["Power Texture"], "", UpdatePowerTexture, "Texture")

	right:CreateHeader(L["Cast Bar"])
	right:CreateSwitch("unitframes-player-enable-castbar", C["unitframes-player-enable-castbar"], L["Enable Cast Bar"], L["Enable the player cast bar"], ReloadUI):RequiresReload(true)
	right:CreateSwitch("unitframes-player-cast-classcolor", C["unitframes-player-cast-classcolor"], L["Enable Class Color"], L["Use class colors"], UpdateCastClassColor)
	right:CreateSlider("unitframes-player-cast-width", C["unitframes-player-cast-width"], 80, 360, 1, L["Cast Bar Width"], L["Set the width of the player cast bar"], UpdatePlayerCastBarSize)
	right:CreateSlider("unitframes-player-cast-height", C["unitframes-player-cast-height"], 8, 50, 1, L["Cast Bar Height"], L["Set the height of the player cast bar"], UpdatePlayerCastBarSize)

	right:CreateHeader(L["Class Resource"])
	right:CreateSwitch("unitframes-player-enable-resource", C["unitframes-player-enable-resource"], L["Enable Resource Bar"], L["Enable the player resource such as combo points, runes, etc."], ReloadUI):RequiresReload(true)
	right:CreateSwitch("player-move-resource", C["player-move-resource"], L["Detach Class Bar"], L["Detach the class resource from the unit frame, to be moved by the UI"], UpdateResourcePosition)
	right:CreateSlider("player-resource-height", C["player-resource-height"], 4, 30, 1, L["Set Height"], L["Set the height of the player resource bar"], UpdateResourceBarHeight)
	right:CreateDropdown("PlayerResourceTexture", C.PlayerResourceTexture, A:GetTextureList(), L["Texture"], "", UpdateResourceTexture, "Texture")
end)