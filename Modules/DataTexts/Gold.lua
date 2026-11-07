local YxUI, Language, Assets, Settings = select(2, ...):get()

local Gold = YxUI:GetModule("Gold")

local GetMoney = GetMoney
local floor = math.floor
local GetCoinTextureString = GetCoinTextureString

if C_CurrencyInfo then
	GetCoinTextureString = C_CurrencyInfo.GetCoinTextureString
end

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	local TrashValue = select(2, YxUI:GetTrashValue())
	local ServerInfo, ServerTotalGold = Gold:GetServerInfo()
	local Change, _, Earned, Spent, Elapsed = Gold:GetSessionStats()

	GameTooltip:AddLine(YxUI.UserRealm)
	GameTooltip:AddLine(" ")

	if #ServerInfo > 1 then
		GameTooltip:AddDoubleLine(Language["Total"], GetCoinTextureString(ServerTotalGold), 1, 0.82, 0, 1, 1, 1)
		GameTooltip:AddLine(" ")
	end

	for i = 1, #ServerInfo do
		GameTooltip:AddDoubleLine(ServerInfo[i][1], GetCoinTextureString(ServerInfo[i][2]), 1, 1, 1, 1, 1, 1)
	end

	if Earned > 0 or Spent > 0 then
		GameTooltip:AddLine(" ")
		if Earned > 0 then
			GameTooltip:AddDoubleLine("Earned", GetCoinTextureString(Earned), 1, 1, 1, 0.4, 1, 0.4)
		end
		if Spent > 0 then
			GameTooltip:AddDoubleLine("Spent", GetCoinTextureString(Spent), 1, 1, 1, 1, 0.4, 0.4)
		end
		if Change >= 0 then
			GameTooltip:AddDoubleLine(Language["Session:"], GetCoinTextureString(Change), 1, 1, 1, 0.4, 1, 0.4)
		else
			GameTooltip:AddDoubleLine(Language["Session:"], GetCoinTextureString(-Change), 1, 1, 1, 1, 0.4, 0.4)
		end
		if Elapsed >= 60 and Earned > 0 then
			GameTooltip:AddDoubleLine("Gold per hour (earned)", GetCoinTextureString(floor(Earned * 3600 / Elapsed)), 1, 1, 1, 1, 1, 1)
		end
	end

	if TrashValue > 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddDoubleLine(Language["|cFF9D9D9D[Poor quality]|r item value:"], GetCoinTextureString(TrashValue), 1, 1, 1, 1, 1, 1)
	end

	GameTooltip:Show()
end

local OnLeave = function()
	GameTooltip:Hide()
end

local Update = function(self)
	self.Text:SetFormattedText("|cFF%s%s|r", Settings["data-text-label-color"], YxUI:CopperToGold(GetMoney()))
end

local OnEnable = function(self)
	self:RegisterEvent("PLAYER_MONEY")
	self:SetScript("OnEvent", Update)
	self:SetScript("OnMouseUp", ToggleAllBags)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)

	self:Update()
end

local OnDisable = function(self)
	self:UnregisterEvent("PLAYER_MONEY")
	self:SetScript("OnEvent", nil)
	self:SetScript("OnMouseUp", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)

	self.Text:SetText("")
end

YxUI:AddDataText("Gold", OnEnable, OnDisable, Update)
