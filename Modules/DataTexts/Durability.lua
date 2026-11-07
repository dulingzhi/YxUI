local YxUI, Language, Assets, Settings = select(2, ...):get()

local Slots = {1, 3, 5, 9, 10, 6, 7, 8, 16, 17, 18}
local GetInventoryItemLink = GetInventoryItemLink
local GetInventoryItemTexture = GetInventoryItemTexture
local GetInventoryItemDurability = GetInventoryItemDurability
local GetCoinTextureString = (C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString) or GetCoinTextureString
local floor = math.floor
local format = format
local Label = Language["Durability"]

local ScanTooltip = CreateFrame("GameTooltip", nil, UIParent, "GameTooltipTemplate")

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	local TotalCost = 0
	local Current, Max

	for i = 1, #Slots do
		Current, Max = GetInventoryItemDurability(Slots[i])

		if Current and Max and Max > 0 then
			local RepairCost

			if C_TooltipInfo and C_TooltipInfo.GetInventoryItem then
				local Data = C_TooltipInfo.GetInventoryItem("player", Slots[i], true)
				RepairCost = Data and Data.repairCost
			else
				local HasItem, _, Cost = ScanTooltip:SetInventoryItem("player", Slots[i], true)
				RepairCost = HasItem and Cost
			end

			if type(RepairCost) == "number" and RepairCost > 0 then
				TotalCost = TotalCost + RepairCost
			end
		end
	end

	ScanTooltip:ClearLines()

	GameTooltip:AddLine(Label)
	GameTooltip:AddLine(" ")

	for i = 1, #Slots do
		Current, Max = GetInventoryItemDurability(Slots[i])

		if Current and Max and Max > 0 then
			GameTooltip:AddDoubleLine(format("|T%s:14:14:0:0:64:64:4:60:4:60|t  %s", GetInventoryItemTexture("player", Slots[i]), GetInventoryItemLink("player", Slots[i])), format("%s%%", floor(Current / Max * 100)), 1, 1, 1, 1, 1, 1)
		end
	end

	if TotalCost > 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(format("%s %s", REPAIR_COST, GetCoinTextureString(TotalCost)), 1, 1, 1)
	end

	GameTooltip:Show()
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

local Update = function(self)
	local Total, Count = 0, 0
	local Current, Max

	for i = 1, #Slots do
		Current, Max = GetInventoryItemDurability(Slots[i])

		if Current and Max and Max > 0 then
			Total = Total + (Current / Max)
			Count = Count + 1
		end
	end

	local Percent

	if Count > 0 then
		Percent = floor(Total / Count * 100)
		self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%s%%|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, Percent)
	else
		self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%s|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, NOT_APPLICABLE)
	end

	if Percent and Percent < 25 then
		if not self.Anim:IsPlaying() then
			self.Anim:Play()
		end
	elseif self.Anim:IsPlaying() then
		self.Anim:Stop()
		self.Anim:SetChange(0.5)
		self.Highlight:SetAlpha(0)
	end
end

local OnFinished = function(self)
	self:SetChange(self:GetChange() == 0 and 0.5 or 0)
	self:Play()
end

local OnEnable = function(self)
	self:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
	self:RegisterEvent("MERCHANT_SHOW")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:SetScript("OnEvent", Update)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)
	self:SetScript("OnMouseUp", OnMouseUp)

	if not self.Anim then
		self.Anim = LibMotion:CreateAnimation(self.Highlight, "Fade")
		self.Anim:SetEasing("inout")
		self.Anim:SetDuration(1.2)
		self.Anim:SetChange(0.5)
		self.Anim:SetScript("OnFinished", OnFinished)
	end

	self:Update()
end

local OnDisable = function(self)
	if self.Anim and self.Anim:IsPlaying() then
		self.Anim:Stop()
		self.Anim:SetChange(0.5)
		self.Highlight:SetAlpha(0)
	end

	self:UnregisterEvent("UPDATE_INVENTORY_DURABILITY")
	self:UnregisterEvent("MERCHANT_SHOW")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:SetScript("OnEvent", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)
	self:SetScript("OnMouseUp", nil)

	self.Text:SetText("")
end

YxUI:AddDataText("Durability", OnEnable, OnDisable, Update)
