local YxUI, Language, Assets, Settings = select(2, ...):get()

local Gold = YxUI:NewModule("Gold")

local GetMoney = GetMoney
local tinsert = table.insert
local tremove = table.remove

local SessionChange = 0
local Sorted = {}
local TablePool = {}
local CurrentUser

local Sort = function(a, b)
	return a[2] > b[2]
end

function Gold:GetTable()
	local Table

	if TablePool[1] then
		Table = tremove(TablePool, 1)
	else
		Table = {}
	end

	return Table
end

function Gold:GetSessionStats()
	return SessionChange, GetMoney()
end

function Gold:GetServerInfo()
	if Sorted[1] then
		for i = 1, #Sorted do
			tinsert(TablePool, tremove(Sorted, 1))
		end
	end

	local Table
	local Total = 0

	for Name, Value in next, YxUI.GoldData[YxUI.UserRealm] do
		Table = self:GetTable()

		Table[1] = Name
		Table[2] = Value

		Total = Total + Value

		tinsert(Sorted, Table)
	end

	table.sort(Sorted, Sort)

	return Sorted, Total
end

function Gold:OnEvent()
	local CurrentValue = GetMoney()

	SessionChange = SessionChange + (CurrentValue - YxUI.GoldData[YxUI.UserRealm][CurrentUser])

	YxUI.GoldData[YxUI.UserRealm][CurrentUser] = CurrentValue
end

function Gold:Reset()
	YxUIGold = nil
	YxUI.GoldData = nil

	self:Load()
end

function Gold:Load()
	YxUI:BindSavedVariable("YxUIGold", "GoldData")

	if (not YxUI.GoldData[YxUI.UserRealm]) then
		YxUI.GoldData[YxUI.UserRealm] = {}
	end

	CurrentUser = string.format("|c%s%s|r", RAID_CLASS_COLORS[YxUI.UserClass].colorStr, YxUI.UserName)

	YxUI.GoldData[YxUI.UserRealm][CurrentUser] = GetMoney()

	self:RegisterEvent("PLAYER_MONEY")
	self:SetScript("OnEvent", self.OnEvent)
end