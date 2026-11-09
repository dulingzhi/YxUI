local YxUI, Language, Assets, Settings = select(2, ...):get()

local Label = DEFENSE or "Defense"

local IsReadable = YxUI.IsDataTextReadable

local GetDefense = function()
	if not UnitDefenseSkill then
		return
	end

	local Base, Modifier = UnitDefenseSkill("player")

	if not IsReadable(Base) or not IsReadable(Modifier) then
		return
	end

	return math.max(0, Base + Modifier), Base, Modifier
end

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	local Defense = YxUI.GetDataTextLastValue(self, (GetDefense()))

	GameTooltip:AddLine(Label, 1, 0.82, 0)
	GameTooltip:AddLine(" ")
	if Defense == nil then
		GameTooltip:AddDoubleLine(Label, "--", 1, 1, 1, 1, 1, 1)
	else
		local Level = UnitLevel("player")
		local MaxSkill = IsReadable(Level) and Level * 5
		local Value = MaxSkill and format("%d / %d", Defense, MaxSkill) or tostring(Defense)
		GameTooltip:AddDoubleLine(Label, Value, 1, 1, 1, 1, 1, 1)

		if MaxSkill and DEFAULT_STATDEFENSE_TOOLTIP then
			local Bonus = math.max(0, Defense - MaxSkill) * 0.04
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(format(DEFAULT_STATDEFENSE_TOOLTIP, Bonus, Bonus), 0.75, 0.75, 0.75, true)
		end
	end

	GameTooltip:Show()
end

local OnLeave = function()
	GameTooltip:Hide()
end

local OnMouseUp = function()
	if InCombatLockdown() then
		return print(ERR_NOT_IN_COMBAT)
	end

	ToggleCharacter("PaperDollFrame")
end

local Update = function(self, event, unit)
	if (event == "UNIT_STATS" or event == "UNIT_AURA") and unit and unit ~= "player" then
		return
	end

	local Defense = YxUI.GetDataTextLastValue(self, (GetDefense()))

	if Defense == nil then
		self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s--|r", Settings["data-text-label-color"], Label, YxUI.ValueColor)
	else
		self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%d|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, Defense)
	end
end

local OnEnable = function(self)
	self:RegisterUnitEvent("UNIT_STATS", "player")
	self:RegisterUnitEvent("UNIT_AURA", "player")
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	self:RegisterEvent("COMBAT_RATING_UPDATE")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_LEVEL_UP")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
	self:SetScript("OnEvent", Update)
	self:SetScript("OnMouseUp", OnMouseUp)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)

	self:Update(nil, "player")
end

local OnDisable = function(self)
	self:UnregisterEvent("UNIT_STATS")
	self:UnregisterEvent("UNIT_AURA")
	self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
	self:UnregisterEvent("COMBAT_RATING_UPDATE")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:UnregisterEvent("PLAYER_LEVEL_UP")
	self:UnregisterEvent("UPDATE_SHAPESHIFT_FORM")
	self:SetScript("OnEvent", nil)
	self:SetScript("OnMouseUp", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)

	self.Text:SetText("")
end

YxUI:AddDataText("Defense", OnEnable, OnDisable, Update)
