local YxUI, Language, Assets, Settings, Defaults = select(2, ...):get()
local UF = YxUI:GetModule("Unit Frames")

-- Player resources are driven directly by the native unit-frame core.  Only a descriptor actually instantiated by BuildPlayerComponents is touched.
local PlayerResourceEvents = {
	"PLAYER_SPECIALIZATION_CHANGED",
	"UNIT_DISPLAYPOWER",
	"UNIT_MAXPOWER",
	"UNIT_POWER_UPDATE",
}

local UpdatePlayerResourceAnchors

local function PlayerSpecializationIs(specializationID, classicTalentTab)
	if GetSpecialization and GetSpecializationInfo then
		local specialization = GetSpecialization()
		return specialization and GetSpecializationInfo(specialization) == specializationID
	end
	if classicTalentTab and GetTalentTabInfo then
		local selected, mostPoints = 1, -1
		for index = 1, GetNumTalentTabs() do
			local _, _, points = GetTalentTabInfo(index)
			if (points or 0) > mostPoints then
				selected, mostPoints = index, points or 0
			end
		end
		return selected == classicTalentTab
	end
	return false
end

local function IsInaccessibleAuraValue(value)
	return YxUI.IsMainline and issecretvalue and issecretvalue(value) and (not canaccessvalue or not canaccessvalue(value))
end

local function PlayerAuraStacks(spellIDs)
	if C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret() then
		return nil
	end

	if C_UnitAuras and C_UnitAuras.GetUnitAuraBySpellID then
		for spellID in pairs(spellIDs) do
			local aura = C_UnitAuras.GetUnitAuraBySpellID("player", spellID)
			if IsInaccessibleAuraValue(aura) then
				return nil
			end
			if aura then
				local count = aura.applications
				return not IsInaccessibleAuraValue(count) and (count or 0) or nil
			end
		end
		return 0
	end

	for index = 1, 40 do
		local name, _, count, _, _, _, _, _, _, spellID = UnitAura("player", index, "HELPFUL")
		if IsInaccessibleAuraValue(name) or IsInaccessibleAuraValue(spellID) or IsInaccessibleAuraValue(count) then
			return nil
		end
		if not name then
			break
		end
		if spellIDs[spellID] then
			return count or 0
		end
	end
	return 0
end

local RuneColors = {
	{1, 0, 0}, -- Blood
	{0, 1, 1}, -- Frost
	{0, 0.5, 0}, -- Unholy
	{0.9, 0.1, 1}, -- Death
}

local function UpdateRuneColor(segment)
	local runeType = GetRuneType and GetRuneType(segment:GetID())
	local color = runeType and RuneColors[runeType]
	local r, g, b
	if color then
		r, g, b = unpack(color)
	else
		r, g, b = YxUI:HexToRGB(Settings["color-runes"])
	end
	segment:SetStatusBarColor(r, g, b)
	segment.bg:SetVertexColor(r, g, b)
end

local function UpdateRuneProgress(segment)
	local startTime, duration, ready = GetRuneCooldown(segment:GetID())
	duration = duration or 1
	if segment.runeDuration ~= duration then
		segment:SetMinMaxValues(0, duration)
		segment.runeDuration = duration
	end
	segment:SetValue(ready and duration or math.max(0, GetTime() - (startTime or 0)))
	if ready then
		segment:SetScript("OnUpdate", nil)
	end
	return ready
end

local function UpdateRune(segment)
	if not UpdateRuneProgress(segment) then
		segment:SetScript("OnUpdate", UpdateRuneProgress)
	end
end

local function ChargedPoints()
	local charged = {}
	if GetUnitChargedPowerPoints then
		local points = GetUnitChargedPowerPoints("player")
		for i = 1, #(points or {}) do
			charged[points[i]] = true
		end
	end
	return charged
end

local function UpdatePlayerResourceColors(resource)
	local descriptor = resource.Descriptor
	if descriptor.runes then
		for i = 1, descriptor.count do
			UpdateRuneColor(resource[i])
		end
	elseif resource.UpdateColors then
		resource:UpdateColors()
	elseif descriptor.colorSetting then
		local r, g, b = YxUI:HexToRGB(Settings[descriptor.colorSetting])
		for i = 1, descriptor.count do
			local segment = resource[i]
			segment:SetStatusBarColor(r, g, b)
			segment.bg:SetVertexColor(r, g, b)
		end
	end
end

local function UpdatePlayerResources(frame, event, unit)
	-- Rune events supply a rune index instead of a unit token.
	if type(unit) == "string" and unit ~= "player" and event ~= "COMBO_TARGET_CHANGED" then
		return
	end

	local resource = frame.ClassResource
	if not resource or resource.Descriptor.totems then
		return
	end

	local descriptor = resource.Descriptor
	if descriptor.runes then
		if event == "RUNE_TYPE_UPDATE" then
			if type(unit) == "number" and resource[unit] then
				UpdateRuneColor(resource[unit])
			else
				UpdatePlayerResourceColors(resource)
			end
			return
		end
		if event == "RUNE_POWER_UPDATE" and type(unit) == "number" and resource[unit] then
			UpdateRune(resource[unit])
			return
		end
		if event == "UNIT_POWER_UPDATE" or event == "UNIT_AURA" then
			return
		end
		for i = 1, descriptor.count do
			UpdateRune(resource[i])
		end
		if event == "ForceUpdate" then
			UpdatePlayerResourceColors(resource)
		end
		return
	end

	if descriptor.targetBoundCombo then
		local comboPoints = GetComboPoints("player", "target")
		for i = 1, descriptor.count do
			resource[i]:SetValue(comboPoints)
		end
		return
	end

	if descriptor.currentProvider and event == "UNIT_POWER_UPDATE" then
		return
	end

	local valueEvent = event == "UNIT_POWER_UPDATE" or event == "UNIT_AURA"
	local refreshLayout = not valueEvent or not resource.maximumInitialized
	if refreshLayout then
		local active = not descriptor.active or descriptor.active()
		local powerType = Enum.PowerType[descriptor.alias or descriptor.field] or Enum.PowerType.ComboPoints
		local maximum = descriptor.maximumProvider and descriptor.maximumProvider() or UnitPowerMax("player", powerType)
		local visible = active and maximum and maximum > 0
		if resource:IsShown() ~= (not not visible) then
			resource:SetShown(not not visible)
		end
		if not visible then
			resource.visibleMaximum = maximum
			resource.maximumInitialized = true
			return
		end

		local visibleCount = math.max(1, math.min(maximum, descriptor.count))
		if resource.layoutCount ~= visibleCount then
			resource:SetWidth(resource:GetWidth())
		end
		if resource.visibleMaximum ~= maximum or not resource.maximumInitialized then
			for i = 1, descriptor.count do
				resource[i]:SetShown(i <= maximum)
			end
			resource.visibleMaximum = maximum
		end
		resource.maximumInitialized = true
		if not resource.rangesInitialized then
			for i = 1, descriptor.count do
				resource[i]:SetMinMaxValues(0, 1)
			end
			resource.rangesInitialized = true
		end
	else
		if not resource:IsShown() then
			return
		end
	end

	local powerType = Enum.PowerType[descriptor.alias or descriptor.field] or Enum.PowerType.ComboPoints
	local current
	if descriptor.currentProvider then
		current = descriptor.currentProvider()
		if current == nil or IsInaccessibleAuraValue(current) then
			return
		end
	else
		current = UnitPower("player", powerType, descriptor.unmodified)
	end
	if descriptor.displayMod then
		local displayMod = UnitPowerDisplayMod and UnitPowerDisplayMod(powerType) or 1
		current = current / math.max(1, displayMod)
	end
	local charged = descriptor.charged and ChargedPoints()
	for i = 1, descriptor.count do
		local segment = resource[i]
		segment:SetValue(math.max(0, math.min(1, current - i + 1)))
		if segment.Charged then
			segment.Charged:SetShown(charged ~= nil and charged[i] == true)
		end
	end
	if event == "ForceUpdate" then
		UpdatePlayerResourceColors(resource)
	end
end

local function EnablePlayerResources(frame)
	if frame.unit ~= "player" or not frame.ClassResource or frame.ClassResource.Descriptor.totems then
		return
	end

	local resource = frame.ClassResource
	local descriptor = resource.Descriptor
	if descriptor.targetBoundCombo then
		frame:RegisterEvent("UNIT_POWER_UPDATE", UpdatePlayerResources)
		frame:RegisterEvent("PLAYER_TARGET_CHANGED", UpdatePlayerResources)
		frame:RegisterEvent("COMBO_TARGET_CHANGED", UpdatePlayerResources)
	elseif descriptor.runes then
		frame:RegisterEvent("RUNE_POWER_UPDATE", UpdatePlayerResources, true)
		frame:RegisterEvent("RUNE_TYPE_UPDATE", UpdatePlayerResources, true)
	else
		for i = 1, #PlayerResourceEvents do
			frame:RegisterEvent(PlayerResourceEvents[i], UpdatePlayerResources)
		end
		if descriptor.currentProvider or descriptor.charged then
			frame:RegisterEvent("UNIT_AURA", UpdatePlayerResources)
		end
	end
	resource.__owner = frame
	resource.RefreshColors = function()
		UpdatePlayerResourceColors(resource)
	end
	resource.ForceUpdate = function()
		UpdatePlayerResources(frame, "ForceUpdate", "player")
	end
	return true
end

local function DisablePlayerResources(frame)
	local resource = frame.ClassResource
	if resource and resource.Descriptor.targetBoundCombo then
		frame:UnregisterEvent("UNIT_POWER_UPDATE", UpdatePlayerResources)
		frame:UnregisterEvent("PLAYER_TARGET_CHANGED", UpdatePlayerResources)
		frame:UnregisterEvent("COMBO_TARGET_CHANGED", UpdatePlayerResources)
	elseif resource and resource.Descriptor.runes then
		frame:UnregisterEvent("RUNE_POWER_UPDATE", UpdatePlayerResources)
		frame:UnregisterEvent("RUNE_TYPE_UPDATE", UpdatePlayerResources)
	else
		for i = 1, #PlayerResourceEvents do
			frame:UnregisterEvent(PlayerResourceEvents[i], UpdatePlayerResources)
		end
		frame:UnregisterEvent("UNIT_AURA", UpdatePlayerResources)
	end
	for i = 1, #(resource or {}) do
		resource[i]:SetScript("OnUpdate", nil)
	end
	if resource then
		resource:Hide()
	end
end

UF:RegisterElement("PlayerResources", {
	update = UpdatePlayerResources,
	enable = EnablePlayerResources,
	disable = DisablePlayerResources,
})

Defaults["unitframes-player-width"] = 240
Defaults["unitframes-player-health-height"] = 32
Defaults["unitframes-player-health-reverse"] = false
Defaults["unitframes-player-health-color"] = "CLASS"
Defaults["unitframes-player-health-smooth"] = true
Defaults["unitframes-player-power-height"] = 15
Defaults["unitframes-player-power-reverse"] = false
Defaults["unitframes-player-power-color"] = "POWER"
Defaults["unitframes-player-mana-cost-color"] = "CC1A1A"
Defaults["unitframes-player-power-smooth"] = true
Defaults["unitframes-player-health-left"] = "[LevelColor][Level][Plus][ColorStop] [Name(30)] [Resting]"
Defaults["unitframes-player-health-right"] = "[HealthPercent]"
Defaults["unitframes-player-power-left"] = "[HealthValues:Short]"
Defaults["unitframes-player-power-right"] = "[PowerValues:Short]"
Defaults["unitframes-player-enable-power"] = true
Defaults["unitframes-player-enable-resource"] = true
Defaults["unitframes-player-cast-width"] = 250
Defaults["unitframes-player-cast-height"] = 24
Defaults["unitframes-player-cast-classcolor"] = true
Defaults["unitframes-player-enable-castbar"] = true
Defaults["unitframes-show-mana-timer"] = true
Defaults["unitframes-show-energy-timer"] = true
Defaults["player-enable-portrait"] = false
Defaults["player-portrait-style"] = "3D"
Defaults["player-overlay-alpha"] = 30
Defaults["player-enable-pvp"] = true
Defaults["player-resource-height"] = 8
Defaults["player-move-resource"] = false
Defaults["player-move-power"] = false
Defaults["player-enable"] = true
Defaults.PlayerBuffSize = 28
Defaults.PlayerBuffSpacing = 2
Defaults.PlayerDebuffSize = 28
Defaults.PlayerDebuffSpacing = 2
Defaults.PlayerHealthTexture = "YxUI 4"
Defaults.PlayerPowerTexture = "YxUI 4"
Defaults.PlayerResourceTexture = "YxUI 4"

local function UpdatePlayerPortraitSize(frame)
	if not frame or not frame.Portrait then
		return
	end
	local overlay = Settings["player-portrait-style"] == "OVERLAY"
	frame.Portrait:SetSize(overlay and Settings["unitframes-player-width"] or 55,
		overlay and Settings["unitframes-player-health-height"] or Settings["unitframes-player-health-height"] + Settings["unitframes-player-power-height"] + 1)
end

local function GetPlayerResourceAnchor(frame, resourceDetached)
	if resourceDetached == nil then
		resourceDetached = Settings["player-move-resource"]
	end
	local resource = frame.ClassResource
	return resource and resource:IsShown() and not resourceDetached and resource or frame
end

local function UpdatePlayerAuraAnchors(frame, resourceDetached)
	if not frame.Buffs or not frame.Debuffs then
		return
	end
	local anchor = GetPlayerResourceAnchor(frame, resourceDetached)
	frame.Buffs:ClearAllPoints()
	frame.Debuffs:ClearAllPoints()
	if Settings["unitframes-show-player-buffs"] then
		frame.Buffs:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 2)
		frame.Debuffs:SetPoint("BOTTOM", frame.Buffs, "TOP", 0, 2)
	else
		frame.Debuffs:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 2)
	end
end

UpdatePlayerResourceAnchors = function(frame, resourceDetached)
	if resourceDetached == nil then
		resourceDetached = Settings["player-move-resource"]
	end
	UpdatePlayerAuraAnchors(frame, resourceDetached)
	if frame.ThreatIndicator then
		frame.ThreatIndicator:ClearAllPoints()
		local anchor = GetPlayerResourceAnchor(frame, resourceDetached)
		frame.ThreatIndicator:SetPoint("TOPLEFT", anchor, -1, 1)
		frame.ThreatIndicator:SetPoint("BOTTOMRIGHT", frame, 1, -1)
	end
end

local function AnchorPlayerPowerPrediction(frame, reverse)
	if not YxUI.IsForever or not frame or not frame.PowerPrediction then
		return
	end

	local power = frame.Power
	local prediction = frame.PowerPrediction.mainBar
	local fill = power:GetStatusBarTexture()
	prediction:ClearAllPoints()

	if reverse == nil then
		reverse = Settings["unitframes-player-power-reverse"]
	end

	prediction:SetReverseFill(not reverse)
	if reverse then
		prediction:SetPoint("TOPLEFT", fill, "TOPLEFT")
		prediction:SetPoint("BOTTOMLEFT", fill, "BOTTOMLEFT")
	else
		prediction:SetPoint("TOPRIGHT", fill, "TOPRIGHT")
		prediction:SetPoint("BOTTOMRIGHT", fill, "BOTTOMRIGHT")
	end

	prediction:SetWidth(power:GetWidth())
end

local function UpdatePlayerPowerLayout(frame, powerHeight, detached, healthHeight)
	if not frame.Power then
		return
	end
	powerHeight = powerHeight or Settings["unitframes-player-power-height"]
	healthHeight = healthHeight or Settings["unitframes-player-health-height"]
	if detached == nil then
		detached = Settings["player-move-power"]
	end
	frame.Power:ClearAllPoints()
	frame.Power:SetHeight(powerHeight)
	if detached then
		frame:SetHeight(healthHeight + 2)
		frame.Power:SetPoint("BOTTOMLEFT", frame.PowerAnchor, 1, 1)
		frame.Power:SetPoint("BOTTOMRIGHT", frame.PowerAnchor, -1, 1)
	else
		frame:SetHeight(healthHeight + powerHeight + 3)
		frame.Power:SetPoint("BOTTOMLEFT", frame, 1, 1)
		frame.Power:SetPoint("BOTTOMRIGHT", frame, -1, 1)
	end
end

local function UpdatePlayerResourceLayout(frame, resourceHeight, detached)
	resourceHeight = resourceHeight or Settings["player-resource-height"]
	if detached == nil then
		detached = Settings["player-move-resource"]
	end
	if frame.ClassResource then
		frame.ClassResource:SetHeight(resourceHeight)
		frame.ClassResource:SetDetached(detached)
	end
	UpdatePlayerResourceAnchors(frame, detached)
end

-- Forever has target-bound combo points that may be secret in combat.
-- Native status-bar ranges render individual segments without comparisons on protected values.
local HasModernClassResources = YxUI.IsMainline and not YxUI.IsForever
local MaelstromAuraIDs = {[53817] = true, [344179] = true}

local PlayerResourceDescriptors = {
	ROGUE = { field = "ComboPoints", count = HasModernClassResources and 7 or 5, countProvider = not YxUI.IsForever and function() return UnitPowerMax("player", Enum.PowerType.ComboPoints) end or nil, color = function(i) return unpack(YxUI.ComboPoints[i]) end, charged = HasModernClassResources, targetBoundCombo = YxUI.IsForever},
	DRUID = { field = "ComboPoints", count = 5, countProvider = not YxUI.IsForever and function() return UnitPowerMax("player", Enum.PowerType.ComboPoints) end or nil, color = function(i) return unpack(YxUI.ComboPoints[i]) end, charged = HasModernClassResources, targetBoundCombo = YxUI.IsForever},
	DEATHKNIGHT = { field = "Runes", count = 6, colorSetting = "color-runes", runes = true},
	MONK = { field = "ClassPower", alias = "Chi", count = 6, countProvider = function() return UnitPowerMax("player", Enum.PowerType.Chi) end, colorSetting = "color-chi", stagger = true, active = function() return YxUI.IsMists or PlayerSpecializationIs(269) end},
	EVOKER = { field = "ClassPower", alias = "Essence", count = 6, countProvider = function() return UnitPowerMax("player", Enum.PowerType.Essence) end, colorSetting = "color-essence"},
	WARLOCK = (HasModernClassResources or YxUI.IsCata or YxUI.IsMists) and {field = "ClassPower", alias = "SoulShards", count = HasModernClassResources and 5 or (YxUI.IsMists and 4 or 3), countProvider = function() return UnitPowerMax("player", Enum.PowerType.SoulShards) end, colorSetting = "color-soul-shards", unmodified = HasModernClassResources, displayMod = HasModernClassResources, active = function() return not YxUI.IsMists or PlayerSpecializationIs(265) end} or nil,
	MAGE = (HasModernClassResources or YxUI.IsMists) and {field = "ClassPower", alias = "ArcaneCharges", count = 4, countProvider = function() return UnitPowerMax("player", Enum.PowerType.ArcaneCharges) end, colorSetting = "color-arcane-charges", active = function() return PlayerSpecializationIs(62) end} or nil,
	PALADIN = (HasModernClassResources or YxUI.IsCata or YxUI.IsMists) and {field = "ClassPower", alias = "HolyPower", count = 5, countProvider = function() return UnitPowerMax("player", Enum.PowerType.HolyPower) end, colorSetting = "color-holy-power"} or nil,
	PRIEST = YxUI.IsMists and {field = "ClassPower", alias = "ShadowOrbs", count = 3, countProvider = function() return UnitPowerMax("player", Enum.PowerType.ShadowOrbs or 13) end, colorSetting = "color-soul-shards", active = function() return PlayerSpecializationIs(258) end} or nil,
	SHAMAN = (YxUI.IsWrath or YxUI.IsMists or HasModernClassResources) and {field = "ClassPower", alias = "MaelstromWeapon", count = HasModernClassResources and 10 or 5, countProvider = function() return HasModernClassResources and IsPlayerSpell(384149) and 10 or 5 end, maximumProvider = function() return HasModernClassResources and IsPlayerSpell(384149) and 10 or 5 end, currentProvider = function() return PlayerAuraStacks(MaelstromAuraIDs) end, colorSetting = "color-maelstrom", active = function() return PlayerSpecializationIs(263, 2) end} or {field = "Totems", count = 4, color = function(i) return unpack(YxUI.TotemColors[i]) end, postUpdate = UF.PostUpdateTotems, totems = true},
}

local function BuildPlayerComponents(factory, self, unit)
	local Health = self.Health
	self.AuraParent = self
	-- Portrait
	factory:CreatePortrait(self,
		Settings["player-portrait-style"],
		Settings["player-portrait-style"] == "OVERLAY" and Settings["unitframes-player-width"] or 55,
		Settings["player-portrait-style"] == "OVERLAY" and Settings["unitframes-player-health-height"] or Settings["unitframes-player-health-height"] + Settings["unitframes-player-power-height"] + 1,
		Settings["player-portrait-style"] == "OVERLAY" and "CENTER" or "RIGHT",
		Settings["player-portrait-style"] == "OVERLAY" and Health or self,
		Settings["player-portrait-style"] == "OVERLAY" and "CENTER" or "LEFT",
		Settings["player-portrait-style"] == "OVERLAY" and 0 or -3, 0,
		Settings["player-portrait-style"] == "OVERLAY" and Settings["player-overlay-alpha"] / 100 or nil,
		Settings["Blank"], Settings["player-enable-portrait"])

	local Combat = Health:CreateTexture(nil, "OVERLAY")
	Combat:SetSize(20, 20)
	Combat:SetPoint("CENTER", Health)

	local Leader = Health:CreateTexture(nil, "OVERLAY")
	Leader:SetSize(16, 16)
	Leader:SetPoint("LEFT", Health, "TOPLEFT", 3, 0)
	Leader:SetTexture(Assets:GetTexture("Leader"))
	Leader:SetVertexColor(YxUI:HexToRGB("FFEB3B"))
	Leader:Hide()

	-- PVP indicator
	local PvPIndicator = Health:CreateTexture(nil, "ARTWORK", nil, 1)

	if YxUI.IsMainline then
		PvPIndicator:SetSize(30, 30)
		PvPIndicator:SetPoint("RIGHT", Health, "LEFT", -4, -2)

		PvPIndicator.Badge = Health:CreateTexture(nil, "ARTWORK")
		PvPIndicator.Badge:SetSize(50, 52)
		PvPIndicator.Badge:SetPoint("CENTER", PvPIndicator, "CENTER")
	else
		PvPIndicator:SetSize(32, 32)
		PvPIndicator:SetPoint("CENTER", Health, 5, -6)
	end

	local Power = self.Power
	if Power then
		local PowerAnchor = CreateFrame("Frame", "YxUI Player Power", YxUI.UIParent)
		PowerAnchor:SetSize(Settings["unitframes-player-width"], Settings["unitframes-player-power-height"])
		PowerAnchor:SetPoint("CENTER", YxUI.UIParent, 0, -133)
		YxUI:CreateMover(PowerAnchor)
		self.PowerAnchor = PowerAnchor
		UpdatePlayerPowerLayout(self)
		factory:CreateBackdrop(Power, "Blank", "BACKGROUND")
		-- Mana regen
		if not (YxUI.IsMists or (YxUI.IsMainline and not YxUI.IsForever)) then
			local ManaTimer = CreateFrame("StatusBar", nil, Power)
			ManaTimer:SetAllPoints(Power)
			ManaTimer:SetStatusBarTexture(Assets:GetTexture(Settings.PlayerPowerTexture))
			ManaTimer:SetStatusBarColor(0, 0, 0, 0)
			ManaTimer:Hide()

			ManaTimer.Spark = ManaTimer:CreateTexture(nil, "ARTWORK")
			ManaTimer.Spark:SetSize(3, Settings["unitframes-player-power-height"])
			ManaTimer.Spark:SetPoint("LEFT", ManaTimer:GetStatusBarTexture(), "RIGHT", -1, 0)
			ManaTimer.Spark:SetTexture(Assets:GetTexture("Blank"))
			ManaTimer.Spark:SetVertexColor(1, 1, 1, 0.2)

			ManaTimer.Spark2 = ManaTimer:CreateTexture(nil, "ARTWORK")
			ManaTimer.Spark2:SetSize(1, Settings["unitframes-player-power-height"])
			ManaTimer.Spark2:SetPoint("CENTER", ManaTimer.Spark, 0, 0)
			ManaTimer.Spark2:SetTexture(Assets:GetTexture("Blank"))
			ManaTimer.Spark2:SetVertexColor(1, 1, 1, 0.8)

			self.ManaTimer = ManaTimer
		end

		-- Energy ticks
		if YxUI.IsVanilla or YxUI.IsTBC then
			local EnergyTick = CreateFrame("StatusBar", nil, Power)
			EnergyTick:SetAllPoints(Power)
			EnergyTick:SetStatusBarTexture(Assets:GetTexture(Settings.PlayerPowerTexture))
			EnergyTick:SetStatusBarColor(0, 0, 0, 0)
			EnergyTick:Hide()

			EnergyTick.Spark = EnergyTick:CreateTexture(nil, "ARTWORK")
			EnergyTick.Spark:SetSize(3, Settings["unitframes-player-power-height"])
			EnergyTick.Spark:SetPoint("LEFT", EnergyTick:GetStatusBarTexture(), "RIGHT", -1, 0)
			EnergyTick.Spark:SetTexture(Assets:GetTexture("Blank"))
			EnergyTick.Spark:SetVertexColor(1, 1, 1, 0.2)

			EnergyTick.Spark2 = EnergyTick:CreateTexture(nil, "ARTWORK")
			EnergyTick.Spark2:SetSize(1, Settings["unitframes-player-power-height"])
			EnergyTick.Spark2:SetPoint("CENTER", EnergyTick.Spark, 0, 0)
			EnergyTick.Spark2:SetTexture(Assets:GetTexture("Blank"))
			EnergyTick.Spark2:SetVertexColor(1, 1, 1, 0.8)

			self.EnergyTick = EnergyTick
		end

		-- Power prediction
		if YxUI.IsMainline then
			local MainBar = CreateFrame("StatusBar", nil, Power)
			MainBar:SetReverseFill(true)
			MainBar:SetStatusBarTexture(Assets:GetTexture(Settings.PlayerPowerTexture))
			MainBar:SetStatusBarColor(YxUI:HexToRGB(Settings["unitframes-player-mana-cost-color"]))

			self.PowerPrediction = {
				mainBar = MainBar,
			}

			if YxUI.IsForever then
				AnchorPlayerPowerPrediction(self)
				Power:HookScript("OnSizeChanged", function(_, width)
					MainBar:SetWidth(width)
				end)

				local TextLayer = CreateFrame("Frame", nil, Power)
				TextLayer:SetAllPoints(Power)
				TextLayer:SetFrameLevel(MainBar:GetFrameLevel() + 1)
				if self.PowerLeft then
					self.PowerLeft:SetParent(TextLayer)
				end
				if self.PowerRight then
					self.PowerRight:SetParent(TextLayer)
				end
				MainBar:Hide()
			else
				MainBar:SetPoint("TOPLEFT")
				MainBar:SetPoint("BOTTOMRIGHT")
			end
		end

	end
	-- Castbar
	if Settings["unitframes-player-enable-castbar"] then
		local Anchor = CreateFrame("Frame", "YxUI Casting Bar", self)
		Anchor:SetSize(Settings["unitframes-player-cast-width"], Settings["unitframes-player-cast-height"])
		factory:CreateCastbar(self, nil,
		Settings["unitframes-player-cast-width"] - Settings["unitframes-player-cast-height"] - 1, Settings["unitframes-player-cast-height"],
		"RIGHT", Anchor, "RIGHT", 0, 0, Settings["ui-widget-texture"], "Blank",
		-Settings["unitframes-player-cast-height"] - 2, 1, 1, -1,
		Settings["unitframes-font"], Settings["unitframes-font-size"], Settings["unitframes-font-flags"],
		-5, 5, Settings["unitframes-player-cast-width"] * 0.7,
		Settings["unitframes-player-cast-height"], nil, nil, true, true, 0.7, Settings["unitframes-player-cast-classcolor"],
		factory.PostCastStart, factory.PostCastStop, factory.PostCastFail, factory.PostCastInterruptible)
		self.CastAnchor = Anchor
	end

	if Settings["unitframes-player-enable-resource"] then
		local ResourceAnchor = CreateFrame("Frame", "YxUI Class Resource", YxUI.UIParent)
		ResourceAnchor:SetSize(Settings["unitframes-player-width"], Settings["player-resource-height"] + 2)
		ResourceAnchor:SetPoint("CENTER", YxUI.UIParent, 0, -120)
		YxUI:CreateMover(ResourceAnchor)

		local function SelectResourceDescriptor(class)
			return PlayerResourceDescriptors[class]
		end

		local function CreateResourceBar(frame, descriptor)
			if not descriptor then
				return
			end
			local resource = CreateFrame("Frame", frame:GetName() .. descriptor.field, frame, "BackdropTemplate")
			resource:SetBackdrop(YxUI.Backdrop)
			resource:SetBackdropColor(0, 0, 0)
			resource:SetBackdropBorderColor(0, 0, 0)
			resource.Descriptor = descriptor
			resource.PostUpdate = descriptor.postUpdate
			resource.sortOrder = descriptor.runes and "asc" or nil

			local function Segment(bar, i)
				return descriptor.totems and bar[i].Bar or bar[i]
			end
			local function GetSegmentColor(index)
				if descriptor.color then
					return descriptor.color(index)
				end

				return YxUI:HexToRGB(Settings[descriptor.colorSetting])
			end
			local function Count(bar)
				local count = descriptor.countProvider and descriptor.countProvider() or descriptor.count
				return math.max(1, math.min(count or descriptor.count, descriptor.count))
			end
			local function Anchor(bar, detached)
				bar:ClearAllPoints()
				bar:SetPoint(detached and "CENTER" or "BOTTOMLEFT", detached and ResourceAnchor or frame, detached and "CENTER" or "TOPLEFT", 0, detached and 0 or -1)
				if bar.Stagger then
					bar.Stagger:ClearAllPoints()
					bar.Stagger:SetPoint(detached and "CENTER" or "BOTTOMLEFT", detached and ResourceAnchor or frame, detached and "CENTER" or "TOPLEFT", detached and 0 or 1, 0)
				end
			end
			local NativeSetWidth, NativeSetHeight = resource.SetWidth, resource.SetHeight
			function resource:SetWidth(width)
				NativeSetWidth(self, width)
				local count = Count(self)
				self.layoutCount = count
				local segmentWidth = (width / count) - 1
				for i = 1, descriptor.count do
					Segment(self, i):SetWidth(i == 1 and segmentWidth - 1 or segmentWidth)
				end
				if self.Stagger then
					self.Stagger:SetWidth(width - 2)
				end
			end
			function resource:SetHeight(height)
				NativeSetHeight(self, height + 2)
				for i = 1, descriptor.count do
					Segment(self, i):SetHeight(height)
				end
				if self.Stagger then
					self.Stagger:SetHeight(height)
				end
			end
			if descriptor.field == "ComboPoints" then
				function resource:UpdateColors()
					for i = 1, descriptor.count do
						local segment = self[i]
						local r, g, b = YxUI:HexToRGB(Settings["color-combo-" .. i])
						segment:SetStatusBarColor(r, g, b)
						segment.bg:SetVertexColor(r, g, b)
						if segment.Charged then
							segment.Charged:SetVertexColor(YxUI:HexToRGB(Settings["color-combo-charged"]))
						end
					end
				end
			end
			function resource:SetTexture(texture)
				texture = Assets:GetTexture(texture)
				for i = 1, descriptor.count do
					local segment = Segment(self, i)
					segment:SetStatusBarTexture(texture)
					segment.bg:SetTexture(texture)
					if segment.Charged then
						segment.Charged:SetTexture(texture)
					end
				end
				if self.Stagger then
					self.Stagger:SetStatusBarTexture(texture)
					self.Stagger.bg:SetTexture(texture)
				end
				if self.UpdateColors then
					self:UpdateColors()
				end
			end
			function resource:SetDetached(detached)
				Anchor(self, detached)
			end

			for i = 1, descriptor.count do
				local owner = resource
				if descriptor.totems then
					owner = CreateFrame("Button", nil, frame)
					resource[i] = owner
				end
				local segment = CreateFrame("StatusBar", frame:GetName() .. descriptor.field .. i, owner)
				if descriptor.totems then
					owner.Bar = segment
					segment:EnableMouse(true)
					segment:SetID(i)
					segment:Hide()
				else
					resource[i] = segment
				end
				if descriptor.targetBoundCombo then
					segment:SetMinMaxValues(i - 1, i)
				end
				-- Logical expressions collapse multiple return values to one in Lua. Resolve each branch directly so all three color channels survive.
				local r, g, b = GetSegmentColor(i)
				segment:SetStatusBarColor(r, g, b)
				segment.bg = resource:CreateTexture(nil, "BORDER")
				segment.bg:SetAllPoints(segment)
				segment.bg:SetVertexColor(r, g, b)
				segment.bg:SetAlpha(descriptor.runes and 0.2 or 0.3)
				if descriptor.charged then
					segment.Charged = segment:CreateTexture(nil, "ARTWORK")
					segment.Charged:SetAllPoints()
					segment.Charged:SetVertexColor(YxUI:HexToRGB(Settings["color-combo-charged"]))
					segment.Charged:Hide()
				end
				if descriptor.runes then
					segment:SetID(i)
					segment.Duration = 0
					segment.Shine = segment:CreateTexture(nil, "ARTWORK")
					segment.Shine:SetAllPoints()
					segment.Shine:SetTexture(Assets:GetTexture("pHishTex28"))
					segment.Shine:SetVertexColor(0.8, 0.8, 0.8)
					segment.Shine:SetAlpha(0)
					segment.Shine:SetDrawLayer("ARTWORK", 7)
					segment.ReadyAnim = LibMotion:CreateAnimationGroup()
					segment.ReadyAnim.In = LibMotion:CreateAnimation(segment.Shine, "Fade")
					segment.ReadyAnim.In:SetGroup(segment.ReadyAnim)
					segment.ReadyAnim.In:SetOrder(1)
					segment.ReadyAnim.In:SetEasing("in")
					segment.ReadyAnim.In:SetDuration(0.2)
					segment.ReadyAnim.In:SetChange(0.5)
					segment.ReadyAnim.Out = LibMotion:CreateAnimation(segment.Shine, "Fade")
					segment.ReadyAnim.Out:SetGroup(segment.ReadyAnim)
					segment.ReadyAnim.Out:SetOrder(2)
					segment.ReadyAnim.Out:SetEasing("out")
					segment.ReadyAnim.Out:SetDuration(0.2)
					segment.ReadyAnim.Out:SetChange(0)
				end
				segment:SetPoint(i == 1 and "LEFT" or "TOPLEFT", i == 1 and resource or Segment(resource, i - 1), i == 1 and "LEFT" or "TOPRIGHT", i == 1 and 1 or 1, 0)
			end

			if descriptor.stagger then
				local stagger = CreateFrame("StatusBar", nil, frame)
				stagger:Hide()
				stagger.bg = stagger:CreateTexture(nil, "ARTWORK")
				stagger.bg:SetAllPoints()
				stagger.bg.multiplier = 0.3
				stagger.Backdrop = stagger:CreateTexture(nil, "BACKGROUND")
				stagger.Backdrop:SetPoint("TOPLEFT", stagger, -1, 1)
				stagger.Backdrop:SetPoint("BOTTOMRIGHT", stagger, 1, -1)
				stagger.Backdrop:SetColorTexture(0, 0, 0)
				resource.Stagger, frame.Stagger = stagger, stagger
			end

			resource:SetWidth(Settings["unitframes-player-width"])
			resource:SetHeight(Settings["player-resource-height"])
			resource:SetTexture(Settings.PlayerResourceTexture)
			resource:SetDetached(Settings["player-move-resource"])
			frame[descriptor.field] = resource
			if descriptor.alias then
				frame[descriptor.alias] = resource
			end
			frame.ClassResource, frame.AuraParent = resource, resource
			-- Visibility can also be changed outside UpdatePlayerResources (for
			-- example when the element is disabled, or by a native resource
			-- provider). Keep auras flush with the unit frame for every such
			-- transition, rather than reserving space for a hidden bar.
			resource:HookScript("OnShow", function()
				UpdatePlayerResourceAnchors(frame)
			end)
			resource:HookScript("OnHide", function()
				UpdatePlayerResourceAnchors(frame)
			end)
			return resource
		end

		CreateResourceBar(self, SelectResourceDescriptor(YxUI.UserClass))
		self.ResourceAnchor = ResourceAnchor
	end
	-- Threat
	local Threat = CreateFrame("Frame", nil, self, "BackdropTemplate")

	if Settings["player-move-resource"] then
		Threat:SetPoint("TOPLEFT", -1, 1)
		Threat:SetPoint("BOTTOMRIGHT", 1, -1)
	else
		Threat:SetPoint("TOPLEFT", self.AuraParent, -1, 1)
		Threat:SetPoint("BOTTOMRIGHT", 1, -1)
	end

	Threat:SetBackdrop(YxUI.Outline)
	Threat.PostUpdate = UF.ThreatPostUpdate

	self.ThreatIndicator = Threat

	-- Auras
	local Buffs = factory:CreateAuraContainer(self, self:GetName() .. "Buffs", nil, Settings["unitframes-player-width"], Settings.PlayerBuffSize,
		nil, nil, nil, 0, 0, Settings.PlayerBuffSize, Settings.PlayerBuffSpacing, 40,
		"BOTTOMLEFT", "ANCHOR_TOP", "RIGHT", "UP", UF.PostCreateIcon, UF.PostUpdateIcon, nil, nil, nil)
	local Debuffs = factory:CreateAuraContainer(self, self:GetName() .. "Debuffs", nil, Settings["unitframes-player-width"], 28,
		nil, nil, nil, 0, 0, Settings.PlayerDebuffSize, Settings.PlayerDebuffSpacing, 16,
		"BOTTOMRIGHT", "ANCHOR_TOP", "LEFT", "UP", UF.PostCreateIcon, UF.PostUpdateIcon, nil, Settings["unitframes-only-player-debuffs"], nil)
	self.Buffs = Buffs
	self.Debuffs = Debuffs
	UpdatePlayerAuraAnchors(self)

	-- Resurrect
	local Resurrect = Health:CreateTexture(nil, "OVERLAY")
	Resurrect:SetSize(16, 16)
	Resurrect:SetPoint("CENTER", Health, 0, 0)
	Resurrect:Hide()

	self.CombatIndicator = Combat
	self.ResurrectIndicator = Resurrect
	self.LeaderIndicator = Leader
	self.PvPIndicator = PvPIndicator
	UpdatePlayerResourceLayout(self)
end

local PlayerFrameConfig = {
	settingsPrefix = "unitframes-player",
	threat = false,
	healthTextureKey = "PlayerHealthTexture",
	powerTextureKey = "PlayerPowerTexture",
	powerEnabledKey = "unitframes-player-enable-power",
	powerTags = true,
	raidTarget = true,
	portrait = BuildPlayerComponents,
}

YxUI.StyleFuncs["player"] = function(self, unit)
	UF:BuildSingleUnitFrame(self, unit, PlayerFrameConfig)
end

local UpdatePlayerWidth = function(value)
	local Frame = YxUI.UnitFrames["player"]
	if not Frame then
		return
	end
	UF:SetFrameWidth("player", value)
	UpdatePlayerPortraitSize(Frame)
	Frame.Buffs:SetWidth(value)
	Frame.Debuffs:SetWidth(value)
	if Frame.ClassResource and not Settings["player-move-resource"] then
		Frame.ClassResource:SetWidth(value)
	end
end
local UpdatePlayerHealthHeight = function(value)
	local frame = YxUI.UnitFrames["player"]
	if not frame then
		return
	end
	frame.Health:SetHeight(value)
	UpdatePlayerPowerLayout(frame, nil, nil, value)
	UpdatePlayerPortraitSize(frame)
end

local UpdatePlayerHealthFill = UF:CreateUnitUpdater("player", "HealthReverse")

local UpdatePlayerPowerHeight = function(value)
	local frame = YxUI.UnitFrames["player"]
	if frame then
		UpdatePlayerPowerLayout(frame, value)
		UpdatePlayerPortraitSize(frame)
	end
end

local UpdatePowerReverse = UF:CreateUnitUpdater("player", "PowerReverse")
local UpdatePlayerPowerFill = function(value)
	UpdatePowerReverse(value)
	if YxUI.IsForever then
		AnchorPlayerPowerPrediction(YxUI.UnitFrames["player"], value)
	end
end

local UpdatePlayerCastBarSize = function()
	if YxUI.UnitFrames["player"].Castbar then
		YxUI.UnitFrames["player"].Castbar:SetSize(Settings["unitframes-player-cast-width"], Settings["unitframes-player-cast-height"])
		YxUI.UnitFrames["player"].Castbar.Icon:SetSize(Settings["unitframes-player-cast-height"], Settings["unitframes-player-cast-height"])
	end
end

local UpdateCastClassColor = function(value)
	if YxUI.UnitFrames["player"].Castbar then
		YxUI.UnitFrames["player"].Castbar.ClassColor = value
		YxUI.UnitFrames["player"].Castbar:ForceUpdate()
	end
end

local UpdatePlayerHealthColor = UF:CreateUnitUpdater("player", "HealthColor")

local UpdatePlayerPowerColor = UF:CreateUnitUpdater("player", "PowerColor")

local function UpdateManaCostColor(value)
	local frame = YxUI.UnitFrames["player"]
	if frame and frame.PowerPrediction and frame.PowerPrediction.mainBar then
		frame.PowerPrediction.mainBar:SetStatusBarColor(YxUI:HexToRGB(value))
	end
end

local UpdatePlayerEnablePortrait = function(value)
	local Frame = YxUI.UnitFrames["player"]

	if Frame and Frame.Portrait then
		UF:SetElementEnabled("player", value, "Portrait")

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

local function UpdatePlayerPortraitStyle()
	UF:RunAfterCombat("player:portrait-style", function()
		local frame = YxUI.UnitFrames["player"]
		if not frame then
			return
		end
		local style = Settings["player-portrait-style"]
		UF:SetPortraitStyle(frame, style,
			style == "OVERLAY" and Settings["unitframes-player-width"] or 55,
			style == "OVERLAY" and Settings["unitframes-player-health-height"] or Settings["unitframes-player-health-height"] + Settings["unitframes-player-power-height"] + 1,
			style == "OVERLAY" and "CENTER" or "RIGHT",
			style == "OVERLAY" and frame.Health or frame,
			style == "OVERLAY" and "CENTER" or "LEFT",
			style == "OVERLAY" and 0 or -3, 0,
			style == "OVERLAY" and Settings["player-overlay-alpha"] / 100 or nil,
			Settings["Blank"])
	end)
end

local UpdateOverlayAlpha = function(value)
	if YxUI.UnitFrames["player"] and Settings["player-portrait-style"] == "OVERLAY" then
		YxUI.UnitFrames["player"].Portrait:SetAlpha(value / 100)
	end
end

local UpdatePlayerEnablePVPIndicator = function(value)
	if YxUI.UnitFrames["player"] then
		if value then
			YxUI.UnitFrames["player"]:EnableElement("PvPIndicator")
			YxUI.UnitFrames["player"].PvPIndicator:ForceUpdate()
		else
			YxUI.UnitFrames["player"]:DisableElement("PvPIndicator")
			YxUI.UnitFrames["player"].PvPIndicator:Hide()
		end
	end
end

local UpdateResourceBarHeight = function(value)
	local Frame = YxUI.UnitFrames["player"]
	if Frame then
		UpdatePlayerResourceLayout(Frame, value)
	end
end
local UpdateResourceTexture = function(value)
	local Frame = YxUI.UnitFrames["player"]
	if Frame and Frame.ClassResource then
		Frame.ClassResource:SetTexture(value)
	end
end
local UpdateBuffSize = UF:CreateUnitUpdater("player", "AuraSize", {element = "Buffs", width = "unitframes-player-width"})

local UpdateBuffSpacing = UF:CreateUnitUpdater("player", "AuraSpacing", {element = "Buffs"})

local UpdateDebuffSize = UF:CreateUnitUpdater("player", "AuraSize", {element = "Debuffs", width = "unitframes-player-width"})

local UpdateDebuffSpacing = UF:CreateUnitUpdater("player", "AuraSpacing", {element = "Debuffs"})

local UpdateDisplayedAuras = function()
	local Player = YxUI.UnitFrames["player"]
	if not Player then
		return
	end
	UpdatePlayerAuraAnchors(Player)

	if Settings["unitframes-show-player-buffs"] then
		Player.Buffs:Show()
	else
		Player.Buffs:Hide()
	end

	if Settings["unitframes-show-player-debuffs"] then
		Player.Debuffs:Show()
	else
		Player.Debuffs:Hide()
	end
end

local UpdateResourcePosition = function(value)
	local frame = YxUI.UnitFrames["player"]
	if not frame then
		return
	end
	UpdatePlayerResourceLayout(frame, nil, value)
end

local UpdatePowerBarPosition = function(value)
	local frame = YxUI.UnitFrames["player"]
	if frame then
		UpdatePlayerPowerLayout(frame, nil, value)
	end
end

local UpdateHealthTexture = UF:CreateUnitUpdater("player", "HealthTexture")

local UpdatePowerTexture = function(value)
	local Frame = YxUI.UnitFrames["player"]

	if Frame then
		UF:SetPowerTexture("player", value)

		local Texture = Assets:GetTexture(value)

		if Frame.ManaTimer then
			Frame.ManaTimer:SetStatusBarTexture(Texture)
		end

		if Frame.EnergyTick then
			Frame.EnergyTick:SetStatusBarTexture(Texture)
		end

		if Frame.PowerPrediction then
			Frame.PowerPrediction.mainBar:SetStatusBarTexture(Texture)
		end
	end
end

local function UpdatePowerTimer(element, value)
	UF:RunAfterCombat("player:" .. element, function()
		local player = YxUI.UnitFrames["player"]
		if player then
			if value then
				player:EnableElement(element)
			else
				player:DisableElement(element)
			end
		end
	end)
end

local function UpdateManaTimer(value)
	UpdatePowerTimer("ManaRegen", value)
end

local function UpdateEnergyTimer(value)
	UpdatePowerTimer("EnergyTick", value)
end

local UpdateHealthSmooth = UF:CreateUnitUpdater("player", "HealthSmooth")
local UpdatePowerSmooth = UF:CreateUnitUpdater("player", "PowerSmooth")

YxUI:GetModule("GUI"):AddWidgetsID("General", "Player", "Unit Frames", function(left, right)
	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("player-enable", Settings["player-enable"], Language["Enable Player"], Language["Enable the player unit frame"], ReloadUI):RequiresReload(true)
	left:CreateSlider("unitframes-player-width", Settings["unitframes-player-width"], 120, 320, 1, Language["Width"], Language["Set the width of the player unit frame"], UpdatePlayerWidth)
	left:CreateSwitch("player-enable-pvp", Settings["player-enable-pvp"], Language["Enable PVP Indicator"], Language["Display the PvP indicator"], UpdatePlayerEnablePVPIndicator)

	if YxUI.IsVanilla or YxUI.IsTBC or YxUI.IsForever then
		left:CreateSwitch("unitframes-show-mana-timer", Settings["unitframes-show-mana-timer"], Language["Enable Mana Regen Timer"], Language["Display the time until your full mana regeneration is active"], UpdateManaTimer)
	end
	if YxUI.IsVanilla or YxUI.IsTBC then
		left:CreateSwitch("unitframes-show-energy-timer", Settings["unitframes-show-energy-timer"], Language["Enable Energy Timer"], Language["Display the time until your next energy tick on the power bar"], UpdateEnergyTimer)
	end

	left:CreateSwitch("player-enable-portrait", Settings["player-enable-portrait"], Language["Enable Portrait"], Language["Display the player unit portrait"], UpdatePlayerEnablePortrait)
	left:CreateDropdown("player-portrait-style", Settings["player-portrait-style"], {[Language["2D"]] = "2D", [Language["3D"]] = "3D", [Language["Overlay"]] = "OVERLAY"}, Language["Set Portrait Style"], Language["Set the style of the portrait"], UpdatePlayerPortraitStyle)
	left:CreateSlider("player-overlay-alpha", Settings["player-overlay-alpha"], 0, 100, 5, Language["Set Overlay Opacity"], Language["Set the opacity of the portrait overlay"], UpdateOverlayAlpha, nil, "%")

	left:CreateHeader(Language["Health"])
	left:CreateSwitch("unitframes-player-health-reverse", Settings["unitframes-player-health-reverse"], Language["Reverse Health Fill"], Language["Reverse the fill of the health bar"], UpdatePlayerHealthFill)
	left:CreateSlider("unitframes-player-health-height", Settings["unitframes-player-health-height"], 6, 60, 1, Language["Health Bar Height"], Language["Set the height of the player health bar"], UpdatePlayerHealthHeight)
	left:CreateSwitch("unitframes-player-health-smooth", Settings["unitframes-player-health-smooth"], Language["Smooth Health"], Language["Animate health changes"], UpdateHealthSmooth)
	left:CreateDropdown("unitframes-player-health-color", Settings["unitframes-player-health-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Custom"]] = "CUSTOM"}, Language["Health Bar Color"], Language["Set the color of the health bar"], UpdatePlayerHealthColor)
	left:CreateTagInput("unitframes-player-health-left", Settings["unitframes-player-health-left"], Language["Left Health Text"], Language["Set the text on the left of the player health bar"], UF:CreateUnitUpdater("player", "TagText", {field = "HealthLeft"}))
	left:CreateTagInput("unitframes-player-health-right", Settings["unitframes-player-health-right"], Language["Right Health Text"], Language["Set the text on the right of the player health bar"], UF:CreateUnitUpdater("player", "TagText", {field = "HealthRight"}))
	left:CreateDropdown("PlayerHealthTexture", Settings.PlayerHealthTexture, Assets:GetTextureList(), Language["Health Texture"], "", UpdateHealthTexture, "Texture")

	left:CreateHeader(Language["Buffs"])
	left:CreateSwitch("unitframes-show-player-buffs", Settings["unitframes-show-player-buffs"], Language["Show Player Buffs"], Language["Show your auras above the player unit frame"], UpdateDisplayedAuras)
	left:CreateSlider("PlayerBuffSize", Settings.PlayerBuffSize, 26, 50, 2, Language["Set Size"], Language["Set the size of the auras"], UpdateBuffSize)
	left:CreateSlider("PlayerBuffSpacing", Settings.PlayerBuffSpacing, -1, 4, 1, Language["Set Spacing"], Language["Set the spacing between the auras"], UpdateBuffSpacing)

	left:CreateHeader(Language["Debuffs"])
	left:CreateSwitch("unitframes-show-player-debuffs", Settings["unitframes-show-player-debuffs"], Language["Show Player Debuffs"], Language["Show your debuff auras above the player unit frame"], UpdateDisplayedAuras)
	left:CreateSlider("PlayerDebuffSize", Settings.PlayerDebuffSize, 26, 50, 2, Language["Set Size"], Language["Set the size of the auras"], UpdateDebuffSize)
	left:CreateSlider("PlayerDebuffSpacing", Settings.PlayerDebuffSpacing, -1, 4, 1, Language["Set Spacing"], Language["Set the spacing between the auras"], UpdateDebuffSpacing)

	right:CreateHeader(Language["Power"])
	right:CreateSwitch("unitframes-player-enable-power", Settings["unitframes-player-enable-power"], Language["Enable Power Bar"], Language["Enable the player power bar"], ReloadUI):RequiresReload(true)
	right:CreateSwitch("unitframes-player-power-reverse", Settings["unitframes-player-power-reverse"], Language["Reverse Power Fill"], Language["Reverse the fill of the power bar"], UpdatePlayerPowerFill)
	right:CreateSwitch("player-move-power", Settings["player-move-power"], Language["Detach Power"], Language["Detach the power bar from the unit frame"], UpdatePowerBarPosition)
	right:CreateSlider("unitframes-player-power-height", Settings["unitframes-player-power-height"], 2, 30, 1, Language["Power Bar Height"], Language["Set the height of the player power bar"], UpdatePlayerPowerHeight)
	right:CreateSwitch("unitframes-player-power-smooth", Settings["unitframes-player-power-smooth"], Language["Smooth Power"], Language["Animate power changes"], UpdatePowerSmooth)
	right:CreateDropdown("unitframes-player-power-color", Settings["unitframes-player-power-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Power Type"]] = "POWER"}, Language["Power Bar Color"], Language["Set the color of the power bar"], UpdatePlayerPowerColor)
	if YxUI.IsMainline then
		right:CreateColorSelection("unitframes-player-mana-cost-color", Settings["unitframes-player-mana-cost-color"], Language["Mana Cost Color"], Language["Set the color of the mana cost prediction"], UpdateManaCostColor)
	end
	right:CreateTagInput("unitframes-player-power-left", Settings["unitframes-player-power-left"], Language["Left Power Text"], Language["Set the text on the left of the player power bar"], UF:CreateUnitUpdater("player", "TagText", {field = "PowerLeft"}))
	right:CreateTagInput("unitframes-player-power-right", Settings["unitframes-player-power-right"], Language["Right Power Text"], Language["Set the text on the right of the player power bar"], UF:CreateUnitUpdater("player", "TagText", {field = "PowerRight"}))
	right:CreateDropdown("PlayerPowerTexture", Settings.PlayerPowerTexture, Assets:GetTextureList(), Language["Power Texture"], "", UpdatePowerTexture, "Texture")

	right:CreateHeader(Language["Cast Bar"])
	right:CreateSwitch("unitframes-player-enable-castbar", Settings["unitframes-player-enable-castbar"], Language["Enable Cast Bar"], Language["Enable the player cast bar"], ReloadUI):RequiresReload(true)
	right:CreateSwitch("unitframes-player-cast-classcolor", Settings["unitframes-player-cast-classcolor"], Language["Enable Class Color"], Language["Use class colors"], UpdateCastClassColor)
	right:CreateSlider("unitframes-player-cast-width", Settings["unitframes-player-cast-width"], 80, 360, 1, Language["Cast Bar Width"], Language["Set the width of the player cast bar"], UpdatePlayerCastBarSize)
	right:CreateSlider("unitframes-player-cast-height", Settings["unitframes-player-cast-height"], 8, 50, 1, Language["Cast Bar Height"], Language["Set the height of the player cast bar"], UpdatePlayerCastBarSize)

	right:CreateHeader(Language["Class Resource"])
	right:CreateSwitch("unitframes-player-enable-resource", Settings["unitframes-player-enable-resource"], Language["Enable Resource Bar"], Language["Enable the player resource such as combo points, runes, etc."], ReloadUI):RequiresReload(true)
	right:CreateSwitch("player-move-resource", Settings["player-move-resource"], Language["Detach Class Bar"], Language["Detach the class resource from the unit frame, to be moved by the UI"], UpdateResourcePosition)
	right:CreateSlider("player-resource-height", Settings["player-resource-height"], 4, 30, 1, Language["Set Height"], Language["Set the height of the player resource bar"], UpdateResourceBarHeight)
	right:CreateDropdown("PlayerResourceTexture", Settings.PlayerResourceTexture, Assets:GetTextureList(), Language["Texture"], "", UpdateResourceTexture, "Texture")
end)
YxUI:GetModule("GUI"):RegisterPageSettingsID("General", "Player", {
	{"unitframes-player-width", UpdatePlayerWidth},
	{"player-enable-pvp", UpdatePlayerEnablePVPIndicator},
	{"unitframes-show-mana-timer", (YxUI.IsVanilla or YxUI.IsTBC or YxUI.IsForever) and UpdateManaTimer or nil},
	{"unitframes-show-energy-timer", (YxUI.IsVanilla or YxUI.IsTBC) and UpdateEnergyTimer or nil},
	{"player-enable-portrait", UpdatePlayerEnablePortrait},
	{"player-portrait-style", UpdatePlayerPortraitStyle},
	{"player-overlay-alpha", UpdateOverlayAlpha},
	{"unitframes-player-health-reverse", UpdatePlayerHealthFill},
	{"unitframes-player-health-height", UpdatePlayerHealthHeight},
	{"unitframes-player-health-smooth", UpdateHealthSmooth},
	{"unitframes-player-health-color", UpdatePlayerHealthColor},
	{"unitframes-player-health-left", UF:CreateUnitUpdater("player", "TagText", {field = "HealthLeft"})},
	{"unitframes-player-health-right", UF:CreateUnitUpdater("player", "TagText", {field = "HealthRight"})},
	{"PlayerHealthTexture", UpdateHealthTexture},
	{"unitframes-show-player-buffs", UpdateDisplayedAuras},
	{"PlayerBuffSize", UpdateBuffSize},
	{"PlayerBuffSpacing", UpdateBuffSpacing},
	{"unitframes-show-player-debuffs", UpdateDisplayedAuras},
	{"PlayerDebuffSize", UpdateDebuffSize},
	{"PlayerDebuffSpacing", UpdateDebuffSpacing},
	{"unitframes-player-power-reverse", UpdatePlayerPowerFill},
	{"player-move-power", UpdatePowerBarPosition},
	{"unitframes-player-power-height", UpdatePlayerPowerHeight},
	{"unitframes-player-power-smooth", UpdatePowerSmooth},
	{"unitframes-player-power-color", UpdatePlayerPowerColor},
	{"unitframes-player-mana-cost-color", YxUI.IsMainline and UpdateManaCostColor or nil},
	{"unitframes-player-power-left", UF:CreateUnitUpdater("player", "TagText", {field = "PowerLeft"})},
	{"unitframes-player-power-right", UF:CreateUnitUpdater("player", "TagText", {field = "PowerRight"})},
	{"PlayerPowerTexture", UpdatePowerTexture},
	{"unitframes-player-cast-classcolor", UpdateCastClassColor},
	{"unitframes-player-cast-width", UpdatePlayerCastBarSize},
	{"unitframes-player-cast-height", UpdatePlayerCastBarSize},
	{"player-move-resource", UpdateResourcePosition},
	{"player-resource-height", UpdateResourceBarHeight},
	{"PlayerResourceTexture", UpdateResourceTexture},
}, "Unit Frames")


YxUI:GetModule("GUI"):RegisterReloadSettings({"player-enable", "unitframes-player-enable-castbar", "unitframes-player-enable-power", "unitframes-player-enable-resource"})
