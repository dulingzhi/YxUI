local HydraUI, Language, Assets, Settings = select(2, ...):get()

local UnitAttackPower = UnitAttackPower
local UnitRangedAttackPower = UnitRangedAttackPower
local Label = ATTACK_POWER

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

	local AttackBase, AttackPositiveBuffs, AttackNegativeBuffs = UnitAttackPower("player")
	local Attack =  AttackBase + AttackPositiveBuffs + AttackNegativeBuffs

	local RangedBase, RangedPositiveBuffs, RangedNegativeBuffs = UnitRangedAttackPower("player")
	local Ranged = RangedBase + RangedPositiveBuffs + RangedNegativeBuffs

	if (HydraUI.UserClass == "HUNTER") then
		Rating = Ranged
	else
		Rating = Attack
	end

	self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%s|r", Settings["data-text-label-color"], Label, HydraUI.ValueColor, Rating)
end

local OnEnable = function(self)
	self:RegisterEvent("UNIT_STATS")
	self:RegisterEvent("UNIT_ATTACK_POWER")
	self:RegisterEvent("UNIT_RANGED_ATTACK_POWER")
	self:RegisterEvent("UNIT_AURA")
	self:SetScript("OnEvent", Update)
	self:SetScript("OnMouseUp", OnMouseUp)

	self:Update(nil, "player")
end

local OnDisable = function(self)
	self:UnregisterEvent("UNIT_STATS")
	self:UnregisterEvent("UNIT_ATTACK_POWER")
	self:UnregisterEvent("UNIT_RANGED_ATTACK_POWER")
	self:UnregisterEvent("UNIT_AURA")
	self:SetScript("OnEvent", nil)
	self:SetScript("OnMouseUp", nil)

	self.Text:SetText("")
end

HydraUI:AddDataText("Attack Power", OnEnable, OnDisable, Update)