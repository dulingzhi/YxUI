local YxUI, Language, Assets, Settings = select(2, ...):get()

local floor = floor
local GetSpeed = GetSpeed
local Label = STAT_SPEED
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
	local Rating = GetCombatRating(CR_SPEED)
	local Bonus = GetCombatRatingBonus(CR_SPEED)
	if IsReadable(Rating) and IsReadable(Bonus) then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(format(CR_SPEED_TOOLTIP, YxUI:Comma(Rating), Bonus), 0.75, 0.75, 0.75, true)
	end

	GameTooltip:Show()
end

local OnLeave = function()
	GameTooltip:Hide()
end

local Update = function(self)
	local Value = YxUI.GetDataTextLastValue(self, GetSpeed())
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

	self:Update()
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

YxUI:AddDataText("Speed", OnEnable, OnDisable, Update)
