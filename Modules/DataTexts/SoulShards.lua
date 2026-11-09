local YxUI, Language, Assets, Settings = select(2, ...):get()

local GetShardCount = C_Item and C_Item.GetItemCount or GetItemCount
local Label = SOUL_SHARDS_POWER

local OnEnter = function(self)
	if not self:SetTooltip() then return end

	local bags = GetShardCount(6265, false)
	local withBank = GetShardCount(6265, true)
	GameTooltip:AddLine(Label, 1, 0.82, 0)
	GameTooltip:AddLine(" ")
	if YxUI.IsDataTextReadable(bags) then
		GameTooltip:AddDoubleLine("In bags", YxUI:Comma(bags), 1, 1, 1, 1, 1, 1)
	end
	if YxUI.IsDataTextReadable(withBank) and YxUI.IsDataTextReadable(bags) and withBank >= bags then
		GameTooltip:AddDoubleLine("Including bank", YxUI:Comma(withBank), 1, 1, 1, 1, 1, 1)
	end
	GameTooltip:Show()
end

local OnLeave = function()
	GameTooltip:Hide()
end

local Update = function(self)
	local Count = GetShardCount(6265, false) or 0

	self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%s|r", Settings["data-text-label-color"], Label, Settings["color-soul-shards"], Count)
end

local OnEnable = function(self)
	self:RegisterEvent("BAG_UPDATE_DELAYED")
	self:SetScript("OnEvent", Update)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)

	self:Update()
end

local OnDisable = function(self)
	self:UnregisterEvent("BAG_UPDATE_DELAYED")
	self:SetScript("OnEvent", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)

	self.Text:SetText("")
end

YxUI:AddDataText("Soul Shards", OnEnable, OnDisable, Update)
