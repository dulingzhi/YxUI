local YxUI, Language, Assets, Settings = select(2, ...):get()

local Slots = {1, 3, 5, 9, 10, 6, 7, 8, 16, 17, 18}
local GetInventoryItemLink = GetInventoryItemLink
local GetInventoryItemTexture = GetInventoryItemTexture
local GetInventoryItemDurability = GetInventoryItemDurability
local GetCoinTextureString = (C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString) or GetCoinTextureString
local floor = math.floor
local format = format
local Label = Language["Durability"]
local IsReadable = YxUI.IsDataTextReadable

local ScanTooltip = CreateFrame("GameTooltip", nil, UIParent, "GameTooltipTemplate")
local PreviousMinimumWidth, PreviousMinimumForce

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	if YxUI.IsMainline and GameTooltip.AddTexture then
		PreviousMinimumWidth, PreviousMinimumForce = GameTooltip:GetMinimumWidth()
		GameTooltip:SetMinimumWidth(340, true)
	end
	GameTooltip:ClearLines()

	local TotalCost = 0
	local Broken = 0
	local Current, Max

	for i = 1, #Slots do
		Current, Max = GetInventoryItemDurability(Slots[i])

		if IsReadable(Current) and IsReadable(Max) and Max > 0 then
			if Current == 0 then
				Broken = Broken + 1
			end
			local RepairCost

			if C_TooltipInfo and C_TooltipInfo.GetInventoryItem then
				local Data = C_TooltipInfo.GetInventoryItem("player", Slots[i], true)
				RepairCost = IsReadable(Data) and Data.repairCost or nil
			else
				local HasItem, _, Cost = ScanTooltip:SetInventoryItem("player", Slots[i], true)
				RepairCost = IsReadable(HasItem) and HasItem and Cost or nil
			end

			if IsReadable(RepairCost) and type(RepairCost) == "number" and RepairCost > 0 then
				TotalCost = TotalCost + RepairCost
			end
		end
	end

	ScanTooltip:ClearLines()

	GameTooltip:AddLine(Label, 1, 0.82, 0)
	GameTooltip:AddLine(" ")

	for i = 1, #Slots do
		Current, Max = GetInventoryItemDurability(Slots[i])

		if IsReadable(Current) and IsReadable(Max) and Max > 0 then
			local Texture = GetInventoryItemTexture("player", Slots[i])
			local Link = GetInventoryItemLink("player", Slots[i])
			local Name = IsReadable(Link) and Link or format("Slot %d", Slots[i])
			local Icon = IsReadable(Texture) and Texture or 134400
			local Percent = format("%s%%", floor(Current / Max * 100))

			if YxUI.IsMainline and GameTooltip.AddTexture then
				GameTooltip:AddDoubleLine(Name, Percent, 1, 1, 1, 1, 1, 1)
				GameTooltip:AddTexture(Icon, {
					width = 14,
					height = 14,
					margin = {left = 0, right = 5, top = 0, bottom = 0},
					texCoords = {left = 0.0625, right = 0.9375, top = 0.0625, bottom = 0.9375},
				})
			else
				GameTooltip:AddDoubleLine(format("|T%s:14:14:0:0:64:64:4:60:4:60|t  %s", Icon, Name), Percent, 1, 1, 1, 1, 1, 1)
			end
		end
	end

	if Broken > 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddDoubleLine("Broken equipment", tostring(Broken), 1, 1, 1, 1, 0.4, 0.4)
	end

	if TotalCost > 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddDoubleLine(REPAIR_COST, GetCoinTextureString(TotalCost), 1, 1, 1, 1, 1, 1)
	end

	GameTooltip:Show()
end

local OnLeave = function()
	GameTooltip:Hide()
	if PreviousMinimumWidth then
		GameTooltip:SetMinimumWidth(PreviousMinimumWidth, PreviousMinimumForce)
		PreviousMinimumWidth, PreviousMinimumForce = nil, nil
	end
end

local OnMouseUp = function()
	if InCombatLockdown() then
		return print(ERR_NOT_IN_COMBAT)
	end

	ToggleCharacter("PaperDollFrame")
end

local Update = function(self)
	local Total, Count = 0, 0
	local Unavailable = false
	local Current, Max

	for i = 1, #Slots do
		Current, Max = GetInventoryItemDurability(Slots[i])

		if issecretvalue and (issecretvalue(Current) or issecretvalue(Max)) then
			Unavailable = true
		elseif IsReadable(Current) and IsReadable(Max) and Max > 0 then
			Total = Total + (Current / Max)
			Count = Count + 1
		end
	end

	local Percent

	if Unavailable then
		Percent = YxUI.GetDataTextLastValue(self, nil)
	else
		Percent = YxUI.GetDataTextLastValue(self, Count > 0 and floor(Total / Count * 100) or nil)
	end

	if Percent ~= nil then
		self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%s%%|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, Percent)
	else
		self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%s|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, Unavailable and "--" or NOT_APPLICABLE)
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
