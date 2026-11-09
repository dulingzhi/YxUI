local YxUI, Language, Assets, Settings = select(2, ...):get()

local GetRangedCritChance = GetRangedCritChance
local GetSpellCritChance = GetSpellCritChance
local GetCritChance = GetCritChance
local max = max
local Label = CRIT_ABBR

local GetSpellCrit = function()
	local Max = GetSpellCritChance(2)

	for i = 3, 7 do
		Max = max(Max, GetSpellCritChance(i))
	end

	return Max
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

local OnEnter = function(self)
	if not self:SetTooltip() then return end

	GameTooltip:AddLine(CRIT_ABBR or "Critical Strike", 1, 0.82, 0)
	GameTooltip:AddLine(" ")
	local melee = GetCritChance()
	local ranged = GetRangedCritChance()
	if YxUI.IsDataTextReadable(melee) then
		GameTooltip:AddDoubleLine(MELEE or "Melee", format("%.2f%%", melee), 1, 1, 1, 1, 1, 1)
	end
	if YxUI.IsDataTextReadable(ranged) then
		GameTooltip:AddDoubleLine(RANGED or "Ranged", format("%.2f%%", ranged), 1, 1, 1, 1, 1, 1)
	end
	local Spell = GetSpellCrit()
	if YxUI.IsDataTextReadable(Spell) then
		GameTooltip:AddDoubleLine(SPELLS or "Spells", format("%.2f%%", Spell), 1, 1, 1, 1, 1, 1)
	end
	GameTooltip:Show()
end

local Update = function(self, event, unit)
	if unit and unit ~= "player" then
		return
	end

	local Crit
	local Spell = GetSpellCrit()
	local Melee = GetCritChance()

	if YxUI.UserClass == "HUNTER" then
		Crit = GetRangedCritChance()
	elseif Spell > Melee then
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
	self:SetScript("OnMouseUp", OnMouseUp)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)

	self:Update(nil, "player")
end

local OnDisable = function(self)
	self:UnregisterEvent("UNIT_STATS")
	self:UnregisterEvent("UNIT_AURA")
	self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
	self:UnregisterEvent("UPDATE_SHAPESHIFT_FORM")
	self:SetScript("OnEvent", nil)
	self:SetScript("OnMouseUp", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)

	self.Text:SetText("")
end

YxUI:AddDataText("Crit", OnEnable, OnDisable, Update)
