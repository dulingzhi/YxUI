local YxUI, Language, Assets, Settings = select(2, ...):get()

local GetRangedCritChance = GetRangedCritChance
local GetSpellCritChance = GetSpellCritChance
local GetCritChance = GetCritChance
local Label = CRIT_ABBR
local LastCrit, LastCritType, LastRatingIndex

local IsSecret = function(value)
	return YxUI.IsForever and issecretvalue and issecretvalue(value)
end

local GetCritData = function()
	if YxUI.UserClass == "HUNTER" then
		local Crit = GetRangedCritChance()

		if IsSecret(Crit) then
			return LastCrit, LastCritType, LastRatingIndex
		end

		LastCrit, LastCritType, LastRatingIndex = Crit, RANGED_CRIT_CHANCE, CR_CRIT_RANGED
		return LastCrit, LastCritType, LastRatingIndex
	end

	local Spell = GetSpellCritChance()
	local Melee = GetCritChance()

	if IsSecret(Spell) or IsSecret(Melee) then
		return LastCrit, LastCritType, LastRatingIndex
	end

	if Spell > Melee then
		LastCrit, LastCritType, LastRatingIndex = Spell, SPELL_CRIT_CHANCE, CR_CRIT_SPELL
	else
		LastCrit, LastCritType, LastRatingIndex = Melee, MELEE_CRIT_CHANCE, CR_CRIT_MELEE
	end

	return LastCrit, LastCritType, LastRatingIndex
end

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	local Crit, CritType, RatingIndex = GetCritData()

	if Crit == nil then
		GameTooltip:AddLine(format("%s: --", Label))
	else
		GameTooltip:AddLine(format("%s %.2f%%", CritType, Crit))

		local Rating = GetCombatRating(RatingIndex)
		local Bonus = GetCombatRatingBonus(RatingIndex)

		if not IsSecret(Rating) and not IsSecret(Bonus) then
			GameTooltip:AddLine(format(CR_CRIT_TOOLTIP, Rating, Bonus), 1, 1, 1)
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

	local Crit = GetCritData()

	if Crit == nil then
		self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s--|r", Settings["data-text-label-color"], Label, YxUI.ValueColor)
		return
	end

	self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%.2f%%|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, Crit)
end

local OnEnable = function(self)
	self:RegisterUnitEvent("UNIT_STATS", "player")
	self:RegisterUnitEvent("UNIT_AURA", "player")
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	self:RegisterEvent("COMBAT_RATING_UPDATE")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
	self:SetScript("OnEvent", Update)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)
	self:SetScript("OnMouseUp", OnMouseUp)

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
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)
	self:SetScript("OnMouseUp", nil)

	self.Text:SetText("")
end

YxUI:AddDataText("Crit", OnEnable, OnDisable, Update)
