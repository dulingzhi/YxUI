local YxUI, Language, Assets, Settings = select(2, ...):get()

local IsReadable = YxUI.IsDataTextReadable

local OnMouseUp = function()
	if InCombatLockdown() then
		return print(ERR_NOT_IN_COMBAT)
	end

	ToggleCharacter("PaperDollFrame")
end

local OnLeave = function()
	GameTooltip:Hide()
end

local Label = HIT or "Hit"

local GetHit = function(modifier, rating)
	if not modifier then
		return
	end

	local Bonus = modifier()
	if not IsReadable(Bonus) then
		return
	end

	if GetCombatRatingBonus and rating then
		local RatingBonus = GetCombatRatingBonus(rating)
		if not IsReadable(RatingBonus) then
			return
		end
		Bonus = Bonus + RatingBonus
	end

	return Bonus
end

local GetValues = function()
	local Melee = GetHit(GetHitModifier, CR_HIT_MELEE)
	local Ranged = GetHit(GetRangedHitModifier, CR_HIT_RANGED)
	local Spell = GetHit(GetSpellHitModifier, CR_HIT_SPELL)

	local Primary
	if YxUI.UserClass == "HUNTER" then
		Primary = Ranged
	elseif Melee ~= nil and Spell ~= nil then
		Primary = math.max(Melee, Spell)
	end

	return Primary, Melee, Ranged, Spell
end

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	local Primary, Melee, Ranged, Spell = GetValues()
	local Values = YxUI.GetDataTextLastValue(self, Primary and {Primary, Melee, Ranged, Spell} or nil, "hit-details")
	if Values then
		Primary, Melee, Ranged, Spell = Values[1], Values[2], Values[3], Values[4]
	end
	GameTooltip:AddLine(Label, 1, 0.82, 0)
	GameTooltip:AddLine(" ")
	if Melee ~= nil then
		GameTooltip:AddDoubleLine(MELEE or "Melee", format("%.2f%%", Melee), 1, 1, 1, 1, 1, 1)
	end
	if Ranged ~= nil then
		GameTooltip:AddDoubleLine(RANGED or "Ranged", format("%.2f%%", Ranged), 1, 1, 1, 1, 1, 1)
	end
	if Spell ~= nil then
		GameTooltip:AddDoubleLine(SPELLS or "Spell", format("%.2f%%", Spell), 1, 1, 1, 1, 1, 1)
	end
	GameTooltip:Show()
end

local Update = function(self, event, unit)
	if (event == "UNIT_STATS" or event == "UNIT_AURA") and unit and unit ~= "player" then
		return
	end

	local Value = YxUI.GetDataTextLastValue(self, (GetValues()))
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

YxUI:AddDataText("Hit Chance", OnEnable, OnDisable, Update)
