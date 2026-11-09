local YxUI, Language, Assets, Settings = select(2, ...):get()

local GetAverageItemLevel = GetAverageItemLevel
local Label = STAT_AVERAGE_ITEM_LEVEL
local IsReadable = YxUI.IsDataTextReadable

local OnMouseUp = function()
	if InCombatLockdown() then
		return print(ERR_NOT_IN_COMBAT)
	end

	ToggleCharacter("PaperDollFrame")
end

local OnEnter = function(self)
	if not self:SetTooltip() then return end

	local average, equipped = GetAverageItemLevel()
	local snapshot = YxUI.GetDataTextLastValue(self, IsReadable(average) and IsReadable(equipped) and {average, equipped} or nil, "item-level-details")
	GameTooltip:AddLine(Label, 1, 0.82, 0)
	GameTooltip:AddLine(" ")
	if snapshot then
		GameTooltip:AddDoubleLine("Equipped", format("%.1f", snapshot[2]), 1, 1, 1, 1, 1, 1)
		GameTooltip:AddDoubleLine("Overall", format("%.1f", snapshot[1]), 1, 1, 1, 1, 1, 1)
	end
	if STAT_AVERAGE_ITEM_LEVEL_TOOLTIP then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(STAT_AVERAGE_ITEM_LEVEL_TOOLTIP, 0.75, 0.75, 0.75, true)
	end
	GameTooltip:Show()
end

local OnLeave = function()
	GameTooltip:Hide()
end

local Update = function(self)
	local Average, Equipped = GetAverageItemLevel()
	if IsReadable(Average) and IsReadable(Equipped) then
		YxUI.GetDataTextLastValue(self, {Average, Equipped}, "item-level-details")
	end
	Equipped = YxUI.GetDataTextLastValue(self, IsReadable(Equipped) and Equipped or nil)

	if Equipped ~= nil then
		self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%d|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, Equipped)
	else
		self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s--|r", Settings["data-text-label-color"], Label, YxUI.ValueColor)
	end
end

local OnEnable = function(self)
	self:RegisterEvent("PLAYER_AVG_ITEM_LEVEL_UPDATE")
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
	self:UnregisterEvent("PLAYER_AVG_ITEM_LEVEL_UPDATE")
	if YxUI.IsMainline then
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end
	self:SetScript("OnEvent", nil)
	self:SetScript("OnMouseUp", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)

	self.Text:SetText("")
end

YxUI:AddDataText("Item Level", OnEnable, OnDisable, Update)
