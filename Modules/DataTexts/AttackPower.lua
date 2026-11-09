local YxUI, Language, Assets, Settings = select(2, ...):get()

local UnitAttackPower = UnitAttackPower
local UnitRangedAttackPower = UnitRangedAttackPower
local Label = ATTACK_POWER

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

	GameTooltip:AddLine(Label, 1, 0.82, 0)
	GameTooltip:AddLine(" ")
	local meleeBase, meleePositive, meleeNegative = UnitAttackPower("player")
	local rangedBase, rangedPositive, rangedNegative = UnitRangedAttackPower("player")
	local function AddPower(label, base, positive, negative)
		if not (YxUI.IsDataTextReadable(base) and YxUI.IsDataTextReadable(positive) and YxUI.IsDataTextReadable(negative)) then
			return
		end
		GameTooltip:AddDoubleLine(label, YxUI:Comma(base + positive + negative), 1, 1, 1, 1, 1, 1)
		if positive ~= 0 or negative ~= 0 then
			GameTooltip:AddDoubleLine("    " .. (BONUS or "Bonuses") .. " / " .. (PENALTY or "Penalties"), format("%+d / %d", positive, negative), 0.75, 0.75, 0.75, 1, 1, 1)
		end
	end
	AddPower(MELEE or "Melee", meleeBase, meleePositive, meleeNegative)
	AddPower(RANGED or "Ranged", rangedBase, rangedPositive, rangedNegative)
	GameTooltip:Show()
end

local Update = function(self, event, unit)
	if unit and unit ~= "player" then
		return
	end

	local Rating

	local AttackBase, AttackPositiveBuffs, AttackNegativeBuffs = UnitAttackPower("player")
	local Attack =  AttackBase + AttackPositiveBuffs + AttackNegativeBuffs

	local RangedBase, RangedPositiveBuffs, RangedNegativeBuffs = UnitRangedAttackPower("player")
	local Ranged = RangedBase + RangedPositiveBuffs + RangedNegativeBuffs

	if YxUI.UserClass == "HUNTER" then
		Rating = Ranged
	else
		Rating = Attack
	end

	self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%s|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, Rating)
end

local OnEnable = function(self)
	self:RegisterEvent("UNIT_STATS")
	self:RegisterEvent("UNIT_ATTACK_POWER")
	self:RegisterEvent("UNIT_RANGED_ATTACK_POWER")
	self:RegisterEvent("UNIT_AURA")
	self:SetScript("OnEvent", Update)
	self:SetScript("OnMouseUp", OnMouseUp)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)

	self:Update(nil, "player")
end

local OnDisable = function(self)
	self:UnregisterEvent("UNIT_STATS")
	self:UnregisterEvent("UNIT_ATTACK_POWER")
	self:UnregisterEvent("UNIT_RANGED_ATTACK_POWER")
	self:UnregisterEvent("UNIT_AURA")
	self:SetScript("OnEvent", nil)
	self:SetScript("OnMouseUp", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)

	self.Text:SetText("")
end

YxUI:AddDataText("Attack Power", OnEnable, OnDisable, Update)
