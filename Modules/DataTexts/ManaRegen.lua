local YxUI, Language, Assets, Settings = select(2, ...):get()

local floor = floor
local UnitPowerMax = UnitPowerMax
local GetManaRegen = GetManaRegen
local InCombatLockdown = InCombatLockdown
local NOT_APPLICABLE = NOT_APPLICABLE
local Label = MANA_REGEN
local ManaID = Enum.PowerType.Mana
local IsReadable = YxUI.IsDataTextReadable

local OnEnter = function(self)
	if not self:SetTooltip() then return end

	GameTooltip:AddLine(Label, 1, 0.82, 0)
	GameTooltip:AddLine(" ")
	local maxMana = UnitPowerMax("player", ManaID)
	if IsReadable(maxMana) and maxMana > 0 then
		local base, casting = GetManaRegen()
		if IsReadable(base) then
			GameTooltip:AddDoubleLine("Not casting", format("%s / 5s", YxUI:Comma(floor(base * 5))), 1, 1, 1, 1, 1, 1)
		end
		if IsReadable(casting) then
			GameTooltip:AddDoubleLine("While casting", format("%s / 5s", YxUI:Comma(floor(casting * 5))), 1, 1, 1, 1, 1, 1)
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
	if unit and unit ~= "player" then
		return
	end

	local Result

	local MaxMana = UnitPowerMax("player", ManaID)
	if IsReadable(MaxMana) then
		if MaxMana > 0 then
			local Base, Combat = GetManaRegen()
			local Regen = InCombatLockdown() and Combat or Base
			Result = IsReadable(Regen) and floor(Regen * 5) or nil
		else
			Result = NOT_APPLICABLE
		end
	end

	Result = YxUI.GetDataTextLastValue(self, Result) or "--"

	self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%s|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, Result)
end

local OnEnable = function(self)
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("UNIT_MAXPOWER")
	self:SetScript("OnEvent", Update)
	self:SetScript("OnMouseUp", OnMouseUp)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)

	self:Update("player")
end

local OnDisable = function(self)
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:UnregisterEvent("PLAYER_REGEN_DISABLED")
	self:UnregisterEvent("UNIT_MAXPOWER")
	self:SetScript("OnEvent", nil)
	self:SetScript("OnMouseUp", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)

	self.Text:SetText("")
end

YxUI:AddDataText("Mana Regen", OnEnable, OnDisable, Update)
