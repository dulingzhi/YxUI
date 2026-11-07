local YxUI, Language, Assets, Settings, Defaults = select(2, ...):get()

local AutoVendor = YxUI:NewModule("Auto Vendor") -- Automatically sell useless items

local select = select
local GetContainerNumSlots = GetContainerNumSlots
local GetContainerItemLink = GetContainerItemLink
local GetContainerItemInfo = GetContainerItemInfo
local GetContainerItemID = GetContainerItemID
local UseContainerItem = UseContainerItem
local PickupMerchantItem = PickupMerchantItem
local GetCoinTextureString = (C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString) or GetCoinTextureString
local CanGuildBankRepair = CanGuildBankRepair
local GetGuildBankWithdrawMoney = GetGuildBankWithdrawMoney
local GetItemInfo = GetItemInfo

if C_Item then
	GetItemInfo = C_Item.GetItemInfo
end

Defaults["auto-vendor-enable"] = true
Defaults["auto-vendor-report"] = true

AutoVendor.Filter = {
	[6196] = true,
	[4813] = true,
}

-- Temporary during DF prepatch
if C_Container and C_Container.GetContainerNumSlots then
	GetContainerNumSlots = C_Container.GetContainerNumSlots
end
if C_Container and C_Container.GetContainerItemLink then
	GetContainerItemLink = C_Container.GetContainerItemLink
end
if C_Container and C_Container.GetContainerItemID then
	GetContainerItemID = C_Container.GetContainerItemID
end
if C_Container and C_Container.GetContainerItemInfo then
	GetContainerItemInfo = C_Container.GetContainerItemInfo
end
if C_Container and C_Container.UseContainerItem then
	UseContainerItem = C_Container.UseContainerItem
end

local function GetStackCount(bag, slot)
	local Info, Count = GetContainerItemInfo(bag, slot)

	if type(Info) == "table" then
		return Info.stackCount or 1
	elseif Info then
		return Count or 1
	end
end

function YxUI:GetTrashValue()
	local Profit = 0
	local TotalCount = 0

	for Bag = 0, 4 do
		for Slot = 1, (GetContainerNumSlots(Bag) or 0) do
			local Link, ID = GetContainerItemLink(Bag, Slot), GetContainerItemID(Bag, Slot)

			if Link and ID and not AutoVendor.Filter[ID] then
				local _, _, Quality, _, _, _, _, _, _, _, VendorPrice = GetItemInfo(Link)
				local Count = GetStackCount(Bag, Slot)
				local TotalPrice = (VendorPrice or 0) * (Count or 0)

				if Quality and Quality <= 0 and TotalPrice > 0 then
					Profit = Profit + TotalPrice
					TotalCount = TotalCount + Count
				end
			end
		end
	end

	return TotalCount, Profit
end

function AutoVendor:OnEvent()
	local Profit = 0
	local TotalCount = 0

	for Bag = 0, 4 do
		for Slot = 1, (GetContainerNumSlots(Bag) or 0) do
			local Link, ID = GetContainerItemLink(Bag, Slot), GetContainerItemID(Bag, Slot)

			if Link and ID and not self.Filter[ID] then
				local _, _, Quality, _, _, _, _, _, _, _, VendorPrice = GetItemInfo(Link)
				local Count = GetStackCount(Bag, Slot)
				local TotalPrice = (VendorPrice or 0) * (Count or 0)

				if Quality and Quality <= 0 and TotalPrice > 0 then
					UseContainerItem(Bag, Slot)
					PickupMerchantItem()
					Profit = Profit + TotalPrice
					TotalCount = TotalCount + Count
				end
			end
		end
	end

	if Profit > 0 and Settings["auto-vendor-report"] then
		YxUI:print(format(Language[TotalCount == 1 and "You sold %d item for a total of %s" or "You sold %d items for a total of %s"], TotalCount, GetCoinTextureString(Profit)))
	end
end

function AutoVendor:Load()
	if Settings["auto-vendor-enable"] then
		self:RegisterEvent("MERCHANT_SHOW")
		self:SetScript("OnEvent", self.OnEvent)
	end
end

local AutoRepair = YxUI:NewModule("Auto Repair")

Defaults["auto-repair-enable"] = true
Defaults["auto-repair-use-guild"] = true
Defaults["auto-repair-report"] = true

function AutoRepair:OnEvent()
	local Money = GetMoney()

	if CanMerchantRepair() then
		local Cost = GetRepairAllCost()
		local CostString = GetCoinTextureString(Cost)

		if Cost == 0 then
			return
		end

		if CanGuildBankRepair() and (GetGuildBankWithdrawMoney() >= Cost) and Settings["auto-repair-use-guild"] then
			RepairAllItems(1)

			if Settings["auto-repair-report"] then
				YxUI:print(format(Language["Your equipped items have been repaired for %s using guild funds"], CostString))
			end
		else
			if Money >= Cost then
				RepairAllItems()

				if Settings["auto-repair-report"] then
					YxUI:print(format(Language["Your equipped items have been repaired for %s"], CostString))
				end
			else
				local Required = Cost - Money
				local RequiredString = GetCoinTextureString(Required)

				if Settings["auto-repair-report"] then
					YxUI:print(format(Language["You require %s to repair all equipped items (costs %s total)"], RequiredString, CostString))
				end
			end
		end
	end
end

function AutoRepair:Load()
	if Settings["auto-repair-enable"] then
		self:RegisterEvent("MERCHANT_SHOW")
		self:SetScript("OnEvent", self.OnEvent)
	end
end

local UpdateAutoVendor = function(value)
	if value then
		AutoVendor:RegisterEvent("MERCHANT_SHOW")
	else
		AutoVendor:UnregisterEvent("MERCHANT_SHOW")
	end
end

local UpdateAutoRepair = function(value)
	if value then
		AutoRepair:RegisterEvent("MERCHANT_SHOW")
	else
		AutoRepair:UnregisterEvent("MERCHANT_SHOW")
	end
end

local function UpdateMerchantDependencies()
	YxUI:GetModule("GUI").WidgetCore.UpdateDependencies({
		["auto-repair-use-guild"] = Settings["auto-repair-enable"],
		["auto-repair-report"] = Settings["auto-repair-enable"],
		["auto-vendor-report"] = Settings["auto-vendor-enable"],
	})
end

YxUI:GetModule("GUI"):AddWidgetsID("General", "General", function(left, right)
	right:CreateHeader(Language["Merchant"])
	right:CreateSwitch("auto-repair-enable", Settings["auto-repair-enable"], Language["Auto Repair Equipment"], Language["Automatically repair damaged items when visiting a repair merchant"], function(value) UpdateAutoRepair(value); UpdateMerchantDependencies() end)
	right:CreateSwitch("auto-repair-use-guild", Settings["auto-repair-use-guild"], Language["Use Guild Funds"], Language["Use guild funds if available for automatic repairs"])
	right:CreateSwitch("auto-repair-report", Settings["auto-repair-report"], Language["Auto Repair Report"], Language["Report the cost of automatic repairs into the chat"])
	right:CreateSwitch("auto-vendor-enable", Settings["auto-vendor-enable"], Language["Auto Sell Greys"], Language["Automatically sell all |cFF9D9D9D[Poor]|r quality items"], function(value) UpdateAutoVendor(value); UpdateMerchantDependencies() end)
	right:CreateSwitch("auto-vendor-report", Settings["auto-vendor-report"], Language["Auto Sell Report"], Language["Report the profit of automatic sales into the chat"])
	UpdateMerchantDependencies()
end)
YxUI:GetModule("GUI"):RegisterPageSettingsID("General", "General", {
	{"auto-repair-enable", function(value) UpdateAutoRepair(value); UpdateMerchantDependencies() end},
	{"auto-vendor-enable", function(value) UpdateAutoVendor(value); UpdateMerchantDependencies() end},
}, nil)

