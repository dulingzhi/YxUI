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

local Label = RESISTANCES or "Resistances"
local Schools = {
	{2, RESISTANCE2_NAME or FIRE or "Fire"},
	{3, RESISTANCE3_NAME or NATURE or "Nature"},
	{4, RESISTANCE4_NAME or FROST or "Frost"},
	{5, RESISTANCE5_NAME or SHADOW or "Shadow"},
	{6, RESISTANCE6_NAME or ARCANE or "Arcane"},
}

local GetValues = function()
	if not UnitResistance then
		return
	end

	local Highest = 0
	local Values = {}
	for i = 1, #Schools do
		local Base, Total = UnitResistance("player", Schools[i][1])
		if not IsReadable(Total) then
			return
		end
		Values[i] = Total
		Highest = math.max(Highest, Total)
	end
	return Highest, Values
end

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	local Highest, Values = GetValues()
	GameTooltip:AddLine(Label, 1, 0.82, 0)
	if Highest ~= nil then
		GameTooltip:AddLine(" ")
		for i = 1, #Schools do
			GameTooltip:AddDoubleLine(Schools[i][2], YxUI:Comma(Values[i]), 1, 1, 1, 1, 1, 1)
		end
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Highest elemental resistance shown in the data text", 0.75, 0.75, 0.75, true)
	end
	GameTooltip:Show()
end

local Update = function(self, event, unit)
	if (event == "UNIT_RESISTANCES" or event == "UNIT_AURA") and unit and unit ~= "player" then
		return
	end

	local Highest = GetValues()
	self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%s|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, Highest and YxUI:Comma(Highest) or "--")
end

local OnEnable = function(self)
	self:RegisterUnitEvent("UNIT_RESISTANCES", "player")
	self:RegisterUnitEvent("UNIT_AURA", "player")
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	self:RegisterEvent("PLAYER_LEVEL_UP")
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

YxUI:AddDataText("Resistances", OnEnable, OnDisable, Update)
