local YxUI, Language, Assets, Settings = select(2, ...):get()

local GetShardCount = C_Item and C_Item.GetItemCount or GetItemCount
local Label = SOUL_SHARDS_POWER

local Update = function(self)
	local Count = GetShardCount(6265, false) or 0

	self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%s|r", Settings["data-text-label-color"], Label, Settings["color-soul-shards"], Count)
end

local OnEnable = function(self)
	self:RegisterEvent("BAG_UPDATE_DELAYED")
	self:SetScript("OnEvent", Update)

	self:Update()
end

local OnDisable = function(self)
	self:UnregisterEvent("BAG_UPDATE_DELAYED")
	self:SetScript("OnEvent", nil)

	self.Text:SetText("")
end

YxUI:AddDataText("Soul Shards", OnEnable, OnDisable, Update)
