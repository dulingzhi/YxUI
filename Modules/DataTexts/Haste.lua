local YxUI, Language, Assets, Settings = select(2, ...):get()

local CR_HASTE_MELEE = CR_HASTE_MELEE
local GetHaste = GetHaste
local Label = STAT_HASTE
local IsReadable = YxUI.IsDataTextReadable

local OnMouseUp = function()
	if InCombatLockdown() then
		return print(ERR_NOT_IN_COMBAT)
	end

	ToggleCharacter("PaperDollFrame")
end

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	GameTooltip:AddLine(Label, 1, 0.82, 0)
	GameTooltip:AddLine(" ")

	if _G["STAT_HASTE_" .. YxUI.UserClass .. "_TOOLTIP"] then
		GameTooltip:AddLine(_G["STAT_HASTE_" .. YxUI.UserClass .. "_TOOLTIP"], 0.75, 0.75, 0.75, true)
	else
		GameTooltip:AddLine(STAT_HASTE_TOOLTIP, 0.75, 0.75, 0.75, true)
	end

	local Rating = GetCombatRating(CR_HASTE_MELEE)
	local Bonus = GetCombatRatingBonus(CR_HASTE_MELEE)
	if IsReadable(Rating) and IsReadable(Bonus) then
		GameTooltip:AddLine(format(STAT_HASTE_BASE_TOOLTIP, YxUI:Comma(Rating), YxUI:Comma(Bonus)), 0.75, 0.75, 0.75, true)
	end

	local Sources = {
		{MELEE or "Melee", GetMeleeHaste},
		{RANGED or "Ranged", GetRangedHaste},
		{SPELLS or "Spell", UnitSpellHaste},
	}
	local HasDetails, HasProtected = false, false
	for i = 1, #Sources do
		local Getter = Sources[i][2]
		if Getter then
			local Raw = (i == 3) and Getter("player") or Getter()
			local Value = YxUI.GetDataTextLastValue(self, IsReadable(Raw) and type(Raw) == "number" and Raw or nil, "haste-" .. i)
			if Value then
				if not HasDetails then
					GameTooltip:AddLine(" ")
					HasDetails = true
				end
				GameTooltip:AddDoubleLine(Sources[i][1], format("%.2f%%", Value), 1, 1, 1, 1, 1, 1)
			end
			if not IsReadable(Raw) then
				HasProtected = true
			end
		end
	end
	if HasProtected and HasDetails then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Last available values where current stats are restricted", 0.75, 0.75, 0.75, true)
	end

	GameTooltip:Show()
end

local OnLeave = function()
	GameTooltip:Hide()
end

local Update = function(self, event, unit)
	if unit and unit ~= "player" then
		return
	end

	local Value = YxUI.GetDataTextLastValue(self, GetHaste())
	if IsReadable(Value) then
		self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%.2f%%|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, Value)
	else
		self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s--|r", Settings["data-text-label-color"], Label, YxUI.ValueColor)
	end
end

local OnEnable = function(self)
	self:RegisterUnitEvent("UNIT_STATS", "player")
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

YxUI:AddDataText("Haste", OnEnable, OnDisable, Update)
