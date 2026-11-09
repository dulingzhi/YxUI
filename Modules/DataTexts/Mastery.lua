local YxUI, Language, Assets, Settings = select(2, ...):get()

local GetMasteryEffect = GetMasteryEffect
local GetCombatRatingBonus = GetCombatRatingBonus
local CR_MASTERY = CR_MASTERY
local Label = STAT_MASTERY

local GetPlayerSpecialization = function()
	if C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then
		return C_SpecializationInfo.GetSpecialization()
	end

	if GetSpecialization then
		return GetSpecialization()
	end
end

local GetPlayerMasterySpells = function(Spec)
	if C_SpecializationInfo and C_SpecializationInfo.GetSpecializationMasterySpells then
		local Spells = C_SpecializationInfo.GetSpecializationMasterySpells(Spec)
		if type(Spells) == "table" then
			return Spells[1], Spells[2]
		end
	end

	if GetSpecializationMasterySpells then
		return GetSpecializationMasterySpells(Spec)
	end
end
local IsReadable = YxUI.IsDataTextReadable

local GetMasteryBonus = function()
	local _, Multiplier = GetMasteryEffect()
	local RatingBonus = GetCombatRatingBonus(CR_MASTERY)
	if IsReadable(Multiplier) and IsReadable(RatingBonus) then
		return RatingBonus * Multiplier
	end
end

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

	local MasteryBonus = GetMasteryBonus()
	local Rating = GetCombatRating(CR_MASTERY)
	local Spec = GetPlayerSpecialization()

	if IsReadable(Spec) and Spec then
		local MasterySpell, MasterySpell2 = GetPlayerMasterySpells(Spec)
		local HasSpell = false

		if IsReadable(MasterySpell) then
			GameTooltip:AddSpellByID(MasterySpell)
			HasSpell = true
		end

		if IsReadable(MasterySpell2) then
			if HasSpell then
				GameTooltip:AddLine(" ")
			end
			GameTooltip:AddSpellByID(MasterySpell2)
			HasSpell = true
		end

		if not HasSpell then
			GameTooltip:AddLine(Label, 1, 0.82, 0)
		end
		if IsReadable(Rating) and MasteryBonus then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(format(STAT_MASTERY_TOOLTIP, YxUI:Comma(Rating), MasteryBonus), 0.75, 0.75, 0.75, true)
		end
	else
		GameTooltip:AddLine(Label, 1, 0.82, 0)
		if IsReadable(Rating) and MasteryBonus then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(format(STAT_MASTERY_TOOLTIP, YxUI:Comma(Rating), MasteryBonus), 0.75, 0.75, 0.75, true)
		end
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(STAT_MASTERY_TOOLTIP_NO_TALENT_SPEC, 0.75, 0.75, 0.75, true)
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

	local MasteryBonus = YxUI.GetDataTextLastValue(self, GetMasteryBonus())
	if MasteryBonus then
		self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%.2f%%|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, MasteryBonus)
	else
		self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s--|r", Settings["data-text-label-color"], Label, YxUI.ValueColor)
	end
end

local OnEnable = function(self)
	self:RegisterUnitEvent("UNIT_STATS", "player")
	if YxUI.IsMainline then
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
	end
	self:SetScript("OnEvent", Update)
	self:SetScript("OnMouseUp", OnMouseUp)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)

	self:Update(nil, "player")
end

local OnDisable = function(self)
	self:UnregisterEvent("UNIT_STATS")
	if YxUI.IsMainline then
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end
	self:SetScript("OnEvent", nil)
	self:SetScript("OnMouseUp", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)

	self.Text:SetText("")
end

YxUI:AddDataText("Mastery", OnEnable, OnDisable, Update)
