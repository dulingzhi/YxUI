local YxUI, Language, Assets, Settings = select(2, ...):get()

local GetRangedCritChance = GetRangedCritChance
local GetSpellCritChance = GetSpellCritChance
local GetCritChance = GetCritChance
local Label = CRIT_ABBR

local OnEnter = function(self)
	self:SetTooltip()

	local Crit
	local Spell = GetSpellCritChance()
	local Melee = GetCritChance()

	if (YxUI.UserClass == "HUNTER") then
		GameTooltip:AddLine(format("%s %.2f%%", RANGED_CRIT_CHANCE, GetRangedCritChance()))
		GameTooltip:AddLine(format(CR_CRIT_TOOLTIP, GetCombatRating(CR_CRIT_RANGED), GetCombatRatingBonus(CR_CRIT_RANGED)), 1, 1, 1)
	elseif (Spell > Melee) then
		GameTooltip:AddLine(format("%s %.2f%%", SPELL_CRIT_CHANCE, Spell))
		GameTooltip:AddLine(format(CR_CRIT_TOOLTIP, GetCombatRating(CR_CRIT_SPELL), GetCombatRatingBonus(CR_CRIT_SPELL)), 1, 1, 1)
	else
		GameTooltip:AddLine(format("%s %.2f%%", MELEE_CRIT_CHANCE, Melee))
		GameTooltip:AddLine(format(CR_CRIT_TOOLTIP, GetCombatRating(CR_CRIT_MELEE), GetCombatRatingBonus(CR_CRIT_MELEE)), 1, 1, 1)
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
	if (unit and unit ~= "player") then
		return
	end

	local Crit
	local Spell = GetSpellCritChance()
	local Melee = GetCritChance()

	if (YxUI.UserClass == "HUNTER") then
		Crit = GetRangedCritChance()
	elseif (Spell > Melee) then
		Crit = Spell
	else
		Crit = Melee
	end

	self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%.2f%%|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, Crit)
end

local OnEnable = function(self)
	self:RegisterUnitEvent("UNIT_STATS", "player")
	self:RegisterUnitEvent("UNIT_AURA", "player")
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
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
	self:UnregisterEvent("UPDATE_SHAPESHIFT_FORM")
	self:SetScript("OnEvent", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)
	self:SetScript("OnLeave", OnMouseUp)

	self.Text:SetText("")
end

YxUI:AddDataText("Crit", OnEnable, OnDisable, Update)