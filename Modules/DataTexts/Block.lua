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

local Label = STAT_BLOCK or BLOCK_CHANCE or "Block"

local GetValue = function()
	if not GetBlockChance then
		return
	end
	local Value = GetBlockChance()
	return IsReadable(Value) and Value or nil
end

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	local Value = GetValue()
	GameTooltip:AddLine(Label, 1, 0.82, 0)
	GameTooltip:AddLine(" ")
	if Value ~= nil then
		GameTooltip:AddDoubleLine(Label, format("%.2f%%", Value), 1, 1, 1, 1, 1, 1)
	end
	if YxUI.IsTBC and CR_BLOCK and GetCombatRating and GetCombatRatingBonus then
		local Rating = GetCombatRating(CR_BLOCK)
		local Bonus = GetCombatRatingBonus(CR_BLOCK)
		if IsReadable(Rating) and IsReadable(Bonus) then
			GameTooltip:AddDoubleLine(COMBAT_RATING_NAME5 or Label, format("%d (+%.2f%%)", Rating, Bonus), 1, 1, 1, 1, 1, 1)
		end
	end
	if GetShieldBlock then
		local Amount = GetShieldBlock()
		if IsReadable(Amount) then
			GameTooltip:AddDoubleLine(BLOCK_VALUE or "Block Value", tostring(Amount), 1, 1, 1, 1, 1, 1)
		end
	end

	GameTooltip:Show()
end

local Update = function(self, event, unit)
	if (event == "UNIT_STATS" or event == "UNIT_AURA") and unit and unit ~= "player" then
		return
	end

	local Value = YxUI.GetDataTextLastValue(self, GetValue())
	if Value == nil then
		self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s--|r", Settings["data-text-label-color"], Label, YxUI.ValueColor)
	else
		self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%.2f%%|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, Value)
	end
end

local OnEnable = function(self)
	self:RegisterUnitEvent("UNIT_STATS", "player")
	self:RegisterUnitEvent("UNIT_AURA", "player")
	self:RegisterEvent("COMBAT_RATING_UPDATE")
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
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
	self:UnregisterEvent("COMBAT_RATING_UPDATE")
	self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:UnregisterEvent("UPDATE_SHAPESHIFT_FORM")
	self:SetScript("OnEvent", nil)
	self:SetScript("OnMouseUp", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)
	self.Text:SetText("")
end

YxUI:AddDataText("Block", OnEnable, OnDisable, Update)
