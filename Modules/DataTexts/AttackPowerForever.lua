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

local Label = ATTACK_POWER or "Attack Power"

local GetPower = function(api)
	if not api then
		return
	end

	local Base, Positive, Negative = api("player")
	if not IsReadable(Base) or not IsReadable(Positive) or not IsReadable(Negative) then
		return
	end

	return Base + Positive + Negative
end

local GetValues = function()
	local Melee = GetPower(UnitAttackPower)
	local Ranged = GetPower(UnitRangedAttackPower)
	local Primary = YxUI.UserClass == "HUNTER" and Ranged or Melee
	return Primary, Melee, Ranged
end

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	local Primary, Melee, Ranged = GetValues()
	GameTooltip:AddLine(Label, 1, 0.82, 0)
	GameTooltip:AddLine(" ")
	if Melee ~= nil then
		GameTooltip:AddDoubleLine(MELEE or "Melee", YxUI:Comma(Melee), 1, 1, 1, 1, 1, 1)
	end
	if Ranged ~= nil then
		GameTooltip:AddDoubleLine(RANGED or "Ranged", YxUI:Comma(Ranged), 1, 1, 1, 1, 1, 1)
	end
	GameTooltip:Show()
end

local Update = function(self, event, unit)
	if (event == "UNIT_ATTACK_POWER" or event == "UNIT_RANGED_ATTACK_POWER" or event == "UNIT_STATS" or event == "UNIT_AURA") and unit and unit ~= "player" then
		return
	end

	local Value = YxUI.GetDataTextLastValue(self, (GetValues()))
	self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%s|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, Value and YxUI:Comma(Value) or "--")
end

local OnEnable = function(self)
	self:RegisterUnitEvent("UNIT_STATS", "player")
	self:RegisterUnitEvent("UNIT_AURA", "player")
	self:RegisterUnitEvent("UNIT_ATTACK_POWER", "player")
	self:RegisterUnitEvent("UNIT_RANGED_ATTACK_POWER", "player")
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

YxUI:AddDataText("Attack Power", OnEnable, OnDisable, Update)
