local YxUI, Language, Assets, Settings = select(2, ...):get()

local GetRangedCritChance = GetRangedCritChance
local GetSpellCritChance = GetSpellCritChance
local GetCritChance = GetCritChance
local Label = CRIT_ABBR
local IsReadable = YxUI.IsDataTextReadable

local GetCritData = function(anchor)
	local Crit, CritType, RatingIndex

	if YxUI.UserClass == "HUNTER" then
		local Ranged = GetRangedCritChance()
		if IsReadable(Ranged) then
			Crit, CritType, RatingIndex = Ranged, RANGED_CRIT_CHANCE, CR_CRIT_RANGED
		end
	else
		local Spell = GetSpellCritChance()
		local Melee = GetCritChance()
		if IsReadable(Spell) and IsReadable(Melee) then
			if Spell > Melee then
				Crit, CritType, RatingIndex = Spell, SPELL_CRIT_CHANCE, CR_CRIT_SPELL
			else
				Crit, CritType, RatingIndex = Melee, MELEE_CRIT_CHANCE, CR_CRIT_MELEE
			end
		end
	end

	local Current = Crit and {Crit, CritType, RatingIndex} or nil
	local Data = YxUI.GetDataTextLastValue(anchor, Current)
	if Data then
		return Data[1], Data[2], Data[3]
	end
end

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	local Crit, CritType, RatingIndex = GetCritData(self)

	GameTooltip:AddLine(Label, 1, 0.82, 0)
	GameTooltip:AddLine(" ")
	if Crit == nil then
		GameTooltip:AddDoubleLine(Label, "--", 1, 1, 1, 1, 1, 1)
	else
		GameTooltip:AddDoubleLine(CritType, format("%.2f%%", Crit), 1, 1, 1, 1, 1, 1)

		local Rating = GetCombatRating(RatingIndex)
		local Bonus = GetCombatRatingBonus(RatingIndex)

		if IsReadable(Rating) and IsReadable(Bonus) then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(format(CR_CRIT_TOOLTIP, Rating, Bonus), 0.75, 0.75, 0.75, true)
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

	local Crit = GetCritData(self)

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
