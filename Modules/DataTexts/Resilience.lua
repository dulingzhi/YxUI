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

local Label = STAT_RESILIENCE or "Resilience"
local RatingIndex = CR_RESILIENCE_PLAYER_DAMAGE_TAKEN

local GetValues = function()
	if not RatingIndex or not GetCombatRatingBonus then
		return
	end

	local Bonus = GetCombatRatingBonus(RatingIndex)
	local Rating = GetCombatRating and GetCombatRating(RatingIndex)
	if not IsReadable(Bonus) then
		return
	end
	if not IsReadable(Rating) then
		Rating = nil
	end
	return Bonus, Rating
end

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	local Bonus, Rating = GetValues()
	GameTooltip:AddLine(Label, 1, 0.82, 0)
	GameTooltip:AddLine(" ")
	if Bonus ~= nil then
		GameTooltip:AddDoubleLine("Bonus from rating", format("+%.2f%%", Bonus), 1, 1, 1, 1, 1, 1)
	end
	if Rating ~= nil then
		GameTooltip:AddDoubleLine(COMBAT_RATING_NAME16 or "Resilience Rating", YxUI:Comma(Rating), 1, 1, 1, 1, 1, 1)
	end
	if Bonus ~= nil or Rating ~= nil then
		GameTooltip:AddLine(" ")
	end
	GameTooltip:AddLine("Does not include base PvP Resilience, which varies by game mode.", 0.75, 0.75, 0.75, true)
	GameTooltip:Show()
end

local Update = function(self, event, unit)
	if (event == "UNIT_STATS" or event == "UNIT_AURA") and unit and unit ~= "player" then
		return
	end

	local Bonus = GetValues()
	if Bonus == nil then
		self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s--|r", Settings["data-text-label-color"], Label, YxUI.ValueColor)
	else
		self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s+%.2f%%|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, Bonus)
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

YxUI:AddDataText("Resilience", OnEnable, OnDisable, Update)
