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

local Label = STAT_SPELLPOWER or STAT_SPELLDAMAGE or "Spell Power"
local HealingLabel = STAT_SPELLHEALING or "Healing"

local Schools = {
	{2, HOLY or "Holy"},
	{3, FIRE or "Fire"},
	{4, NATURE or "Nature"},
	{5, FROST or "Frost"},
	{6, SHADOW or "Shadow"},
	{7, ARCANE or "Arcane"},
}

local GetValues = function()
	if not GetSpellBonusDamage then
		return
	end

	local Highest = 0
	local Values = {}
	for i = 1, #Schools do
		local Value = GetSpellBonusDamage(Schools[i][1])
		if not IsReadable(Value) then
			return
		end
		Values[i] = Value
		Highest = math.max(Highest, Value)
	end

	local Healing = GetSpellBonusHealing and GetSpellBonusHealing()
	if not IsReadable(Healing) then
		Healing = nil
	end

	return Highest, Values, Healing
end

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	local Highest, Values, Healing = GetValues()
	GameTooltip:AddLine(Label, 1, 0.82, 0)
	GameTooltip:AddLine(" ")
	if Highest ~= nil then
		for i = 1, #Schools do
			GameTooltip:AddDoubleLine(Schools[i][2], YxUI:Comma(Values[i]), 1, 1, 1, 1, 1, 1)
		end
	end
	if Healing ~= nil then
		GameTooltip:AddDoubleLine(HealingLabel, YxUI:Comma(Healing), 1, 1, 1, 1, 1, 1)
	end
	GameTooltip:Show()
end

local Update = function(self, event, unit)
	if (event == "UNIT_STATS" or event == "UNIT_AURA") and unit and unit ~= "player" then
		return
	end

	local Highest = YxUI.GetDataTextLastValue(self, (GetValues()))
	self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%s|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, Highest and YxUI:Comma(Highest) or "--")
end

local OnEnable = function(self)
	self:RegisterUnitEvent("UNIT_STATS", "player")
	self:RegisterUnitEvent("UNIT_AURA", "player")
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

YxUI:AddDataText("Spell Power", OnEnable, OnDisable, Update)
