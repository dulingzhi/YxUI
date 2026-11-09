local YxUI, Language, Assets, Settings = select(2, ...):get()

local GetCombatRatingBonus = GetCombatRatingBonus
local Label = HIT

local OnMouseUp = function()
	if InCombatLockdown() then
		return print(ERR_NOT_IN_COMBAT)
	end

	ToggleCharacter("PaperDollFrame")
end

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	GameTooltip:AddLine(Label, 1, 0.82, 0)
	GameTooltip:AddLine(" ")
	if YxUI.UserClass == "HUNTER" then
		GameTooltip:AddDoubleLine(COMBAT_RATING_NAME6, tostring(GetCombatRating(CR_HIT_RANGED)), 1, 1, 1, 1, 1, 1)
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(format(CR_HIT_MELEE_TOOLTIP, UnitLevel("player"), GetCombatRatingBonus(CR_HIT_RANGED), GetArmorPenetration(), GetCombatRatingBonus(CR_ARMOR_PENETRATION)), 0.75, 0.75, 0.75, true)
	elseif GetCombatRatingBonus(CR_HIT_SPELL) > GetCombatRatingBonus(CR_HIT_MELEE) then
		GameTooltip:AddDoubleLine(COMBAT_RATING_NAME6, tostring(GetCombatRating(CR_HIT_SPELL)), 1, 1, 1, 1, 1, 1)
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(format(CR_HIT_SPELL_TOOLTIP, UnitLevel("player"), GetCombatRatingBonus(CR_HIT_SPELL), GetSpellPenetration(), GetSpellPenetration()), 0.75, 0.75, 0.75, true)
	else
		GameTooltip:AddDoubleLine(COMBAT_RATING_NAME6, tostring(GetCombatRating(CR_HIT_MELEE)), 1, 1, 1, 1, 1, 1)
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(format(CR_HIT_MELEE_TOOLTIP, UnitLevel("player"), GetCombatRatingBonus(CR_HIT_MELEE), GetArmorPenetration(), GetCombatRatingBonus(CR_ARMOR_PENETRATION)), 0.75, 0.75, 0.75, true)
	end

	GameTooltip:Show()
end

local OnLeave = function()
	GameTooltip:Hide()
end

local Update = function(self, event, unit)
	if unit and unit ~= "player" then
		return
	end

	local Rating

	if YxUI.UserClass == "HUNTER" then
		Rating = GetCombatRatingBonus(CR_HIT_RANGED)
	elseif GetCombatRatingBonus(CR_HIT_SPELL) > GetCombatRatingBonus(CR_HIT_MELEE) then
		Rating = GetCombatRatingBonus(CR_HIT_SPELL)
	else
		Rating = GetCombatRatingBonus(CR_HIT_MELEE)
	end

	self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%.2f%%|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, Rating)
end

local OnEnable = function(self)
	self:RegisterEvent("UNIT_STATS")
	self:SetScript("OnEvent", Update)
	self:SetScript("OnMouseUp", OnMouseUp)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)

	self:Update("player")
end

local OnDisable = function(self)
	self:UnregisterEvent("UNIT_STATS")
	self:SetScript("OnEvent", nil)
	self:SetScript("OnMouseUp", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)

	self.Text:SetText("")
end

YxUI:AddDataText(Label, OnEnable, OnDisable, Update)
