local YxUI, Language, Assets, Settings = select(2, ...):get()

local IsReadable = function(value)
	return value ~= nil and (not issecretvalue or not issecretvalue(value))
end

local OnMouseUp = function()
	if InCombatLockdown() then
		return print(ERR_NOT_IN_COMBAT)
	end

	ToggleCharacter("PaperDollFrame")
end

local OnLeave = function()
	GameTooltip:Hide()
end

local Label = STAT_PVP_POWER or "PvP Power"

local GetValues = function()
	local Damage = GetPvpPowerDamage and GetPvpPowerDamage()
	local Healing = GetPvpPowerHealing and GetPvpPowerHealing()
	if not IsReadable(Damage) then
		Damage = nil
	end
	if not IsReadable(Healing) then
		Healing = nil
	end
	return Damage, Healing
end

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	local Damage, Healing = GetValues()
	GameTooltip:AddLine(Label, 1, 0.82, 0)
	GameTooltip:AddLine(" ")
	if Damage ~= nil then
		GameTooltip:AddDoubleLine(DAMAGE or "Damage", format("%.2f%%", Damage), 1, 1, 1, 1, 1, 1)
	end
	if Healing ~= nil then
		GameTooltip:AddDoubleLine(HEALING or "Healing", format("%.2f%%", Healing), 1, 1, 1, 1, 1, 1)
	end
	if CR_PVP_POWER and GetCombatRating then
		local Rating = GetCombatRating(CR_PVP_POWER)
		if IsReadable(Rating) then
			GameTooltip:AddDoubleLine(COMBAT_RATING_NAME27 or "PvP Power Rating", YxUI:Comma(Rating), 1, 1, 1, 1, 1, 1)
		end
	end
	GameTooltip:Show()
end

local Update = function(self, event, unit)
	if (event == "UNIT_STATS" or event == "UNIT_AURA") and unit and unit ~= "player" then
		return
	end

	local Damage = GetValues()
	if Damage == nil then
		self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s--|r", Settings["data-text-label-color"], Label, YxUI.ValueColor)
	else
		self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%.2f%%|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, Damage)
	end
end

local OnEnable = function(self)
	self:RegisterUnitEvent("UNIT_STATS", "player")
	self:RegisterUnitEvent("UNIT_AURA", "player")
	self:RegisterEvent("COMBAT_RATING_UPDATE")
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:SetScript("OnEvent", Update)
	self:SetScript("OnMouseUp", OnMouseUp)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)
	self:Update(nil, "player")
end

local OnDisable = function(self)
	self:UnregisterAllEvents()
	self:SetScript("OnEvent", nil)
	self:SetScript("OnMouseUp", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)
	self.Text:SetText("")
end

YxUI:AddDataText("PvP Power", OnEnable, OnDisable, Update)
