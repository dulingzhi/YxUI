local HydraUI, Language, Assets, Settings = select(2, ...):get()

local GetHitModifier = GetHitModifier
local GetSpellHitModifier = GetSpellHitModifier
local Label = Language["Hit"]

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

	local Rating
	local Hit = GetHitModifier()
	local Spell = GetSpellHitModifier()

	if (Spell > Hit) then
		Rating = Spell
	else
		Rating = Hit
	end

	self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%.2f%%|r", Settings["data-text-label-color"], Label, HydraUI.ValueColor, Rating)
end

local OnEnable = function(self)
	self:RegisterEvent("UNIT_STATS")
	self:SetScript("OnEvent", Update)
	self:SetScript("OnMouseUp", OnMouseUp)

	self:Update("player")
end

local OnDisable = function(self)
	self:UnregisterEvent("UNIT_STATS")
	self:SetScript("OnEvent", nil)
	self:SetScript("OnMouseUp", nil)

	self.Text:SetText("")
end

HydraUI:AddDataText("Hit", OnEnable, OnDisable, Update)