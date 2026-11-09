local YxUI, Language, Assets, Settings = select(2, ...):get()

local UnitArmor = UnitArmor
local Label = Language["Armor"]
local IsReadable = YxUI.IsDataTextReadable

local OnEnter

if YxUI.IsMainline then
	OnEnter = function(self)
		if not self:SetTooltip() then
			return
		end

		local Base, EffectiveArmor = UnitArmor("player")
		EffectiveArmor = YxUI.GetDataTextLastValue(self, EffectiveArmor)
		local AttackerLevel = UnitEffectiveLevel("player")
		local ArmorReadable = IsReadable(EffectiveArmor)
		local ArmorReduction, AgainstTarget

		if ArmorReadable and IsReadable(AttackerLevel) then
			local Effectiveness = C_PaperDollInfo.GetArmorEffectiveness(EffectiveArmor, AttackerLevel)
			if IsReadable(Effectiveness) then
				ArmorReduction = Effectiveness * 100
			end

			local TargetEffectiveness = C_PaperDollInfo.GetArmorEffectivenessAgainstTarget(EffectiveArmor)
			if IsReadable(TargetEffectiveness) then
				AgainstTarget = TargetEffectiveness * 100
			end
		end

		GameTooltip:AddLine(Label, 1, 0.82, 0)
		GameTooltip:AddLine(" ")
		GameTooltip:AddDoubleLine(Label, ArmorReadable and YxUI:Comma(EffectiveArmor) or "--", 1, 1, 1, 1, 1, 1)

		if ArmorReduction or AgainstTarget then
			GameTooltip:AddLine(" ")
		end
		if ArmorReduction then
			GameTooltip:AddLine(format(STAT_ARMOR_TOOLTIP, ArmorReduction), 0.75, 0.75, 0.75, true)
		end
		if AgainstTarget then
			GameTooltip:AddLine(format(STAT_ARMOR_TARGET_TOOLTIP, AgainstTarget), 0.75, 0.75, 0.75, true)
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

		GameTooltip:AddLine(Label, 1, 0.82, 0)
		GameTooltip:AddLine(" ")
		GameTooltip:AddDoubleLine(Label, YxUI:Comma(EffectiveArmor), 1, 1, 1, 1, 1, 1)
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(format(STAT_ARMOR_TOOLTIP, ArmorReduction), 0.75, 0.75, 0.75, true)

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
	local Armor = YxUI.GetDataTextLastValue(self, IsReadable(EffectiveArmor) and EffectiveArmor or nil)
	local Value = Armor and YxUI:Comma(Armor) or "--"

	self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%s|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, Value)
end

local OnEnable = function(self)
	self:RegisterEvent("UNIT_STATS")
	if YxUI.IsMainline then
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
	end
	self:SetScript("OnEvent", Update)
	self:SetScript("OnMouseUp", OnMouseUp)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)

	self:Update(nil, "player")
end

local OnDisable = function(self)
	self:UnregisterEvent("UNIT_STATS")
	if YxUI.IsMainline then
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end
	self:SetScript("OnEvent", nil)
	self:SetScript("OnMouseUp", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)

	self.Text:SetText("")
end

YxUI:AddDataText("Armor", OnEnable, OnDisable, Update)
