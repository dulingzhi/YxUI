local YxUI, Language, Assets, Settings, Defaults = select(2, ...):get()

Defaults["raid-pets-enable"] = true
Defaults["raid-pets-width"] = 78
Defaults["raid-pets-health-height"] = 22
Defaults["raid-pets-health-reverse"] = false
Defaults["raid-pets-health-color"] = "CLASS"
Defaults["raid-pets-health-orientation"] = "HORIZONTAL"
Defaults["raid-pets-health-smooth"] = true
Defaults["raid-pets-power-height"] = 0 -- NYI

local UF = YxUI:GetModule("Unit Frames")
local InCombatLockdown = InCombatLockdown

YxUI.StyleFuncs["raidpet"] = function(self, unit)
	-- General
    if not InCombatLockdown() then
        self:RegisterForClicks("AnyUp")
    end
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	local Backdrop = self:CreateTexture(nil, "BORDER")
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
	Health:SetHeight(Settings["raid-pets-health-height"])
	Health:SetStatusBarTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	Health:SetReverseFill(Settings["raid-pets-health-reverse"])
	Health:SetOrientation(Settings["raid-pets-health-orientation"])

	local HealBar = CreateFrame("StatusBar", nil, self)
	HealBar:SetAllPoints(Health)
	HealBar:SetStatusBarTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	HealBar:SetStatusBarColor(0, 0.48, 0)
	HealBar:SetFrameLevel(Health:GetFrameLevel() - 1)

	if Settings["raid-health-reverse"] then
		HealBar:SetPoint("RIGHT", Health:GetStatusBarTexture(), "LEFT", 0, 0)
	else
		HealBar:SetPoint("LEFT", Health:GetStatusBarTexture(), "RIGHT", 0, 0)
	end

	self.HealBar = HealBar

	if YxUI.IsMainline then
		local AbsorbsBar = CreateFrame("StatusBar", nil, Health)
		AbsorbsBar:SetWidth(Settings["raid-width"])
		AbsorbsBar:SetHeight(Settings["raid-pets-health-height"])
		AbsorbsBar:SetStatusBarTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
		AbsorbsBar:SetStatusBarColor(0, 0.66, 1)
		AbsorbsBar:SetFrameLevel(Health:GetFrameLevel() - 2)

		if Settings["raid-health-reverse"] then
			AbsorbsBar:SetPoint("RIGHT", Health:GetStatusBarTexture(), "LEFT", 0, 0)
		else
			AbsorbsBar:SetPoint("LEFT", Health:GetStatusBarTexture(), "RIGHT", 0, 0)
		end

		self.AbsorbsBar = AbsorbsBar
	end

	local HealthBG = self:CreateTexture(nil, "BACKGROUND")
	HealthBG:SetAllPoints(Health)
	HealthBG:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
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

	if (not Settings.RaidEnableMouseover) then
		Highlight:Hide()
	end

	local HealthMiddle = Health:CreateFontString(nil, "OVERLAY")
	YxUI:SetFontInfo(HealthMiddle, Settings["raid-font"], Settings["raid-font-size"], Settings["raid-font-flags"])
	HealthMiddle:SetPoint("CENTER", Health, 0, 0)
	HealthMiddle:SetJustifyH("CENTER")

	-- Attributes
	Health.frequentUpdates = true
	Health.colorDisconnected = true
	Health.Smooth = true

	UF:SetHealthAttributes(Health, Settings["raid-pets-health-color"])

	-- Target Icon
	local RaidTarget = Health:CreateTexture(nil, 'OVERLAY')
	RaidTarget:SetSize(16, 16)
	RaidTarget:SetPoint("CENTER", Health, "TOP")

	-- Tags
	self:Tag(HealthMiddle, "[Name10]")

	self.Range = {
		insideAlpha = Settings["raid-in-range"] / 100,
		outsideAlpha = Settings["raid-out-of-range"] / 100,
	}

	self.Health = Health
	self.Health.bg = HealthBG
	self.HealthMiddle = HealthMiddle
	self.RaidTargetIndicator = RaidTarget
end

YxUI:GetModule("GUI"):AddWidgets(Language["General"], Language["Raid Pets"], Language["Unit Frames"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("raid-pets-enable", Settings["raid-pets-enable"], Language["Enable Raid Pet Frames"], Language["Enable the Raid pet frames module"], ReloadUI):RequiresReload(true)

	--[[Defaults["raid-pets-enable"] = true
	Defaults["raid-pets-width"] = 78
	Defaults["raid-pets-health-height"] = 22
	Defaults["raid-pets-health-reverse"] = false
	Defaults["raid-pets-health-color"] = "CLASS"
	Defaults["raid-pets-health-orientation"] = "HORIZONTAL"
	Defaults["raid-pets-health-smooth"] = true
	Defaults["raid-pets-power-height"] = 0 -- NYI]]
end)