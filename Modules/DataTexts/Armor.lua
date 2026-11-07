local YxUI, Language, Assets, Settings = select(2, ...):get()

local UnitArmor = UnitArmor
local Label = Language["Armor"]

local OnEnter

if YxUI.IsMainline then
	OnEnter = function(self)
		if not self:SetTooltip() then
			return
		end

		local Base, EffectiveArmor = UnitArmor("player")
		local AttackerLevel = UnitEffectiveLevel("player")
		local ArmorSecret = issecretvalue and issecretvalue(EffectiveArmor)
		local ArmorReduction, AgainstTarget

		if not ArmorSecret and not (issecretvalue and issecretvalue(AttackerLevel)) then
			local Effectiveness = C_PaperDollInfo.GetArmorEffectiveness(EffectiveArmor, AttackerLevel)
			if not (issecretvalue and issecretvalue(Effectiveness)) then
				ArmorReduction = Effectiveness * 100
			end

			local TargetEffectiveness = C_PaperDollInfo.GetArmorEffectivenessAgainstTarget(EffectiveArmor)
			if TargetEffectiveness and not (issecretvalue and issecretvalue(TargetEffectiveness)) then
				AgainstTarget = TargetEffectiveness * 100
			end
		end

		if ArmorSecret then
			GameTooltip:AddLine(Label, 1, 1, 1)
		else
			GameTooltip:AddLine(format("%s %s", Label, YxUI:Comma(EffectiveArmor)), 1, 1, 1)
		end

		if ArmorReduction then
			GameTooltip:AddLine(format(STAT_ARMOR_TOOLTIP, ArmorReduction), nil, nil, nil, true)
		end

		if AgainstTarget then
			GameTooltip:AddLine(format(STAT_ARMOR_TARGET_TOOLTIP, AgainstTarget))
		end

		GameTooltip:Show()
	end
else
	OnEnter = function(self)
		if not self:SetTooltip() then
			return
		end

		local Base, EffectiveArmor = UnitArmor("player")
		local Level = UnitLevel("player")
		local ArmorReduction = EffectiveArmor / ((85 * Level) + 400)
		ArmorReduction = 100 * (ArmorReduction / (ArmorReduction + 1))

		GameTooltip:AddLine(format("%s %s", Label, YxUI:Comma(EffectiveArmor)), 1, 1, 1)
		GameTooltip:AddLine(format(STAT_ARMOR_TOOLTIP, ArmorReduction), nil, nil, nil, true)

		GameTooltip:Show()
	end
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

	local Base, EffectiveArmor = UnitArmor("player")

	self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%s|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, YxUI:Comma(EffectiveArmor))
end

local OnEnable = function(self)
	self:RegisterEvent("UNIT_STATS")
	self:SetScript("OnEvent", Update)
	self:SetScript("OnMouseUp", OnMouseUp)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)

	self:Update(nil, "player")
end

local OnDisable = function(self)
	self:UnregisterEvent("UNIT_STATS")
	self:SetScript("OnEvent", nil)
	self:SetScript("OnMouseUp", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)

	self.Text:SetText("")
end

YxUI:AddDataText("Armor", OnEnable, OnDisable, Update)
