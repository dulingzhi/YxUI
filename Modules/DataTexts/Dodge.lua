local YxUI, Language, Assets, Settings = select(2, ...):get()

local Label = STAT_DODGE or "Dodge"

local IsReadable = YxUI.IsDataTextReadable

local GetDodge = function()
	if not GetDodgeChance then
		return
	end

	local Chance = GetDodgeChance()

	if not IsReadable(Chance) then
		return
	end

	return Chance
end

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	local Chance = YxUI.GetDataTextLastValue(self, GetDodge())

	GameTooltip:AddLine(Label, 1, 0.82, 0)
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine(Label .. " chance", Chance and format("%.2f%%", Chance) or "--", 1, 1, 1, 1, 1, 1)

	if CR_DODGE and GetCombatRating and GetCombatRatingBonus then
		local Rating = GetCombatRating(CR_DODGE)
		local Bonus = GetCombatRatingBonus(CR_DODGE)

		if IsReadable(Rating) and IsReadable(Bonus) then
			GameTooltip:AddDoubleLine(Label .. " rating", format("%d (+%.2f%%)", Rating, Bonus), 1, 1, 1, 1, 1, 1)
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

	local Chance = YxUI.GetDataTextLastValue(self, GetDodge())

	if Chance == nil then
		self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s--|r", Settings["data-text-label-color"], Label, YxUI.ValueColor)
	else
		self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%.2f%%|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, Chance)
	end
end

local OnEnable = function(self)
	self:RegisterUnitEvent("UNIT_STATS", "player")
	self:RegisterUnitEvent("UNIT_AURA", "player")
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	self:RegisterEvent("COMBAT_RATING_UPDATE")
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
	self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
	self:UnregisterEvent("COMBAT_RATING_UPDATE")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:UnregisterEvent("UPDATE_SHAPESHIFT_FORM")
	self:SetScript("OnEvent", nil)
	self:SetScript("OnMouseUp", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)

	self.Text:SetText("")
end

YxUI:AddDataText("Dodge", OnEnable, OnDisable, Update)
