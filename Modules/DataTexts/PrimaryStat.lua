local YxUI, Language, Assets, Settings = select(2, ...):get()

local UnitStat = UnitStat
local IsReadable = YxUI.IsDataTextReadable

local ValidStat = {
	[1] = SPELL_STAT1_NAME,
	[2] = SPELL_STAT2_NAME,
	[4] = SPELL_STAT4_NAME,
}

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

	GameTooltip:AddLine(STAT_PRIMARY or "Primary Stats", 1, 0.82, 0)
	GameTooltip:AddLine(" ")
	for _, index in ipairs({1, 2, 4}) do
		local base, effective, positive, negative = UnitStat("player", index)
		if IsReadable(base) and IsReadable(effective) and IsReadable(positive) and IsReadable(negative) then
			local bonus = positive + negative
			local detail = YxUI:Comma(effective)
			if bonus ~= 0 then
				detail = detail .. format(" (%+d)", bonus)
			end
			GameTooltip:AddDoubleLine(ValidStat[index], detail, 1, 1, 1, 1, 1, 1)
		end
	end
	GameTooltip:Show()
end

local Update = function(self, event, unit)
	if unit and unit ~= "player" then
		return
	end

	local Stat, StatEffective, PositiveBuffs, NegativeBuffs
	local Highest, HighestStat, HighestEffective = 0, 0, 0
	local HasUnreadableStat = false

	for i = 1, 4 do
		if ValidStat[i] then
			Stat, StatEffective, PositiveBuffs, NegativeBuffs = UnitStat("player", i)

			if IsReadable(Stat) and IsReadable(StatEffective) and IsReadable(PositiveBuffs) and IsReadable(NegativeBuffs) then
				local Effective = StatEffective
				if Effective > HighestEffective then
					Highest, HighestStat, HighestEffective = i, Stat, Effective
				end
			else
				HasUnreadableStat = true
			end
		end
	end

	local Current = not HasUnreadableStat and Highest > 0 and {Highest, HighestStat} or nil
	local Data = YxUI.GetDataTextLastValue(self, Current)
	local Label = Data and ValidStat[Data[1]] or STAT_PRIMARY or "Primary Stat"
	local Value = Data and Data[2] or "--"
	self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%s|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, Value)
end

local OnEnable = function(self)
	self:RegisterEvent("UNIT_STATS")
	self:RegisterEvent("UNIT_AURA")
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
	self:UnregisterEvent("UNIT_AURA")
	if YxUI.IsMainline then
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end
	self:SetScript("OnEvent", nil)
	self:SetScript("OnMouseUp", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)

	self.Text:SetText("")
end

YxUI:AddDataText("Primary Stat", OnEnable, OnDisable, Update)
