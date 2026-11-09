local YxUI, Language, Assets, Settings = select(2, ...):get()

local GetHitModifier = GetHitModifier
local GetSpellHitModifier = GetSpellHitModifier
local Label = Language["Hit"]

local OnMouseUp = function()
	if InCombatLockdown() then
		return print(ERR_NOT_IN_COMBAT)
	end

	ToggleCharacter("PaperDollFrame")
end

local function GetValues()
	local melee = GetHitModifier and GetHitModifier() or 0
	local ranged = GetRangedHitModifier and GetRangedHitModifier() or nil
	local spell = GetSpellHitModifier and GetSpellHitModifier() or 0

	if YxUI.IsTBC and GetCombatRatingBonus then
		melee = melee + (GetCombatRatingBonus(CR_HIT_MELEE) or 0)
		spell = spell + (GetCombatRatingBonus(CR_HIT_SPELL) or 0)
		ranged = (ranged or 0) + (GetCombatRatingBonus(CR_HIT_RANGED) or 0)
	end
	return melee, ranged, spell
end

local OnLeave = function()
	GameTooltip:Hide()
end

local OnEnter = function(self)
	if not self:SetTooltip() then return end

	local melee, ranged, spell = GetValues()
	GameTooltip:AddLine(Label, 1, 0.82, 0)
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine(MELEE or "Melee", format("%.2f%%", melee), 1, 1, 1, 1, 1, 1)
	if ranged ~= nil then
		GameTooltip:AddDoubleLine(RANGED or "Ranged", format("%.2f%%", ranged), 1, 1, 1, 1, 1, 1)
	end
	GameTooltip:AddDoubleLine(SPELLS or "Spell", format("%.2f%%", spell), 1, 1, 1, 1, 1, 1)
	GameTooltip:Show()
end

local Update = function(self, event, unit)
	if unit and unit ~= "player" then return end

	local melee, ranged, spell = GetValues()
	local hit = YxUI.IsTBC and YxUI.UserClass == "HUNTER" and (ranged or melee) or melee
	local primary = math.max(hit, spell)
	self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%.2f%%|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, primary)
end

local OnEnable = function(self)
	self:RegisterEvent("UNIT_STATS")
    self:RegisterEvent("COMBAT_RATING_UPDATE")
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	self:SetScript("OnEvent", Update)
	self:SetScript("OnMouseUp", OnMouseUp)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)

	self:Update("player")
end

local OnDisable = function(self)
	self:UnregisterEvent("UNIT_STATS")
    self:UnregisterEvent("COMBAT_RATING_UPDATE")
    self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
	self:SetScript("OnEvent", nil)
	self:SetScript("OnMouseUp", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)

	self.Text:SetText("")
end

YxUI:AddDataText("Hit", OnEnable, OnDisable, Update)
