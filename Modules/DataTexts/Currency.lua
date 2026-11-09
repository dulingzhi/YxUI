local YxUI, Language, Assets, Settings = select(2, ...):get()

local DT = YxUI:GetModule("DataText")
local IsReadable = YxUI.IsDataTextReadable
local GetInfo = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo
local GetListInfo = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListInfo
local GetListSize = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListSize
local GetLegacyListInfo = GetCurrencyListInfo
local GetLegacyListSize = GetCurrencyListSize
local MenuFrame

local function IsNumber(value)
	return IsReadable(value) and type(value) == "number"
end

local function IsString(value)
	return IsReadable(value) and type(value) == "string" and value ~= ""
end

local function GetSettingID(self)
	return "data-text-currency-" .. self.Name
end

local function ReadCurrency(id)
	if not IsNumber(id) or id <= 0 then
		return
	end

	if GetInfo then
		local info = GetInfo(id)
		if IsReadable(info) and IsString(info.name) and IsNumber(info.quantity) then
			return {
				name = info.name,
				quantity = info.quantity,
				maxQuantity = IsNumber(info.maxQuantity) and info.maxQuantity or nil,
				maxWeeklyQuantity = IsNumber(info.maxWeeklyQuantity) and info.maxWeeklyQuantity or nil,
				quantityEarnedThisWeek = IsNumber(info.quantityEarnedThisWeek) and info.quantityEarnedThisWeek or nil,
				totalEarned = IsNumber(info.totalEarned) and info.totalEarned or nil,
				description = IsString(info.description) and info.description or nil,
			}
		end
	end
end

local function GetCurrencyRows()
	local rows = {}
	local group = CURRENCY or "Currencies"
	local size = (GetListSize and GetListSize()) or (GetLegacyListSize and GetLegacyListSize()) or 0
	if not IsNumber(size) then
		return rows
	end

	for index = 1, math.min(size, 500) do
		local id, name, isHeader
		if GetListInfo then
			local info = GetListInfo(index)
			if IsReadable(info) then
				id, name, isHeader = info.currencyID, info.name, info.isHeader
			end
		elseif GetLegacyListInfo then
			local listName, header, _, _, _, _, _, _, _, _, _, currencyID = GetLegacyListInfo(index)
			id, name, isHeader = currencyID, listName, header
		end

		if IsString(name) and not (issecretvalue and issecretvalue(isHeader)) then
			if isHeader then
				group = name
			elseif IsNumber(id) and id > 0 then
				rows[#rows + 1] = {name = name, id = id, group = group}
			end
		end
	end

	return rows
end

local function SelectCurrency(anchor, id)
	local settingID = GetSettingID(anchor)
	if Settings[settingID] == id then
		return
	end

	Settings[settingID] = id
	local profileName = YxUI:GetActiveProfileName()
	if profileName then
		YxUI:SetProfileValue(profileName, settingID, id)
	end

	anchor.DataTextLastValues = nil
	anchor.DataTextNeedsRefresh = nil
	anchor:Update()
end

local function ShowCurrencyMenu(anchor)
	local rows = GetCurrencyRows()
	local current = Settings[GetSettingID(anchor)] or 0

	if MenuUtil and MenuUtil.CreateContextMenu then
		MenuUtil.CreateContextMenu(anchor, function(owner, root)
			root:CreateTitle("Tracked Currency")
			local lastGroup, submenu
			for _, row in ipairs(rows) do
				if row.group ~= lastGroup then
					lastGroup = row.group
					submenu = root:CreateButton(lastGroup)
				end
				local currencyID = row.id
				local text = (currencyID == current and "|cff66ff66" or "") .. row.name .. (currencyID == current and "|r" or "")
				local parent = submenu or root
				parent:CreateButton(text, function() SelectCurrency(anchor, currencyID) end)
			end
			if #rows == 0 then
				root:CreateTitle("Open the Currency tab to discover currencies")
			end
		end)
	elseif EasyMenu then
		if not MenuFrame then
			MenuFrame = CreateFrame("Frame", "YxUICurrencyDataTextMenu", UIParent, "UIDropDownMenuTemplate")
		end
		local menu = {{text = "Tracked Currency", isTitle = true, notCheckable = true}}
		local groups, order = {}, {}
		for _, row in ipairs(rows) do
			if not groups[row.group] then
				groups[row.group] = {}
				order[#order + 1] = row.group
			end
			local currencyID = row.id
			groups[row.group][#groups[row.group] + 1] = {
				text = row.name, checked = currencyID == current,
				func = function() SelectCurrency(anchor, currencyID) end,
			}
		end
		for _, name in ipairs(order) do
			menu[#menu + 1] = {text = name, hasArrow = true, notCheckable = true, menuList = groups[name]}
		end
		if #rows == 0 then
			menu[#menu + 1] = {text = "Open the Currency tab to discover currencies", disabled = true, notCheckable = true}
		end
		EasyMenu(menu, MenuFrame, anchor, 0, 0, "MENU")
	end
end

local function OnMouseUp(self, button)
	if button == "RightButton" then
		ShowCurrencyMenu(self)
	elseif button == "LeftButton" and not InCombatLockdown() and ToggleCharacter then
		ToggleCharacter("TokenFrame")
	end
end

local function OnEnter(self)
	if not self:SetTooltip() then
		return
	end

	GameTooltip:ClearLines()
	local id = Settings[GetSettingID(self)] or 0
	local data = id > 0 and YxUI.GetDataTextLastValue(self, ReadCurrency(id))
	GameTooltip:AddLine("Tracked Currency", 1, 0.82, 0)
	GameTooltip:AddLine(" ")
	if data then
		GameTooltip:AddDoubleLine(data.name, YxUI:Comma(data.quantity), 1, 1, 1, 1, 1, 1)
		if data.maxQuantity and data.maxQuantity > 0 then
			GameTooltip:AddDoubleLine("Maximum", YxUI:Comma(data.maxQuantity), 1, 1, 1, 1, 1, 1)
			GameTooltip:AddDoubleLine("Remaining to cap", YxUI:Comma(math.max(0, data.maxQuantity - data.quantity)), 1, 1, 1, 1, 1, 1)
		end
		if data.maxWeeklyQuantity and data.maxWeeklyQuantity > 0 then
			if data.quantityEarnedThisWeek then
				GameTooltip:AddDoubleLine("Earned this week", format("%s / %s", YxUI:Comma(data.quantityEarnedThisWeek), YxUI:Comma(data.maxWeeklyQuantity)), 1, 1, 1, 1, 1, 1)
				GameTooltip:AddDoubleLine("Remaining this week", YxUI:Comma(math.max(0, data.maxWeeklyQuantity - data.quantityEarnedThisWeek)), 1, 1, 1, 1, 1, 1)
			else
				GameTooltip:AddDoubleLine("Weekly limit", YxUI:Comma(data.maxWeeklyQuantity), 1, 1, 1, 1, 1, 1)
			end
		end
		if data.totalEarned and data.totalEarned > 0 then
			GameTooltip:AddDoubleLine("Total earned", YxUI:Comma(data.totalEarned), 1, 1, 1, 1, 1, 1)
		end
		if data.description then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(data.description, 0.75, 0.75, 0.75, true)
		end
	elseif id ~= 0 then
		GameTooltip:AddLine("Currency information unavailable", 0.75, 0.75, 0.75)
	end
	if id ~= 0 then
		GameTooltip:AddLine(" ")
	end
	GameTooltip:AddLine(id == 0 and "Right-click to choose a currency" or "Right-click to change currency", 0.5, 0.85, 1)
	GameTooltip:Show()
end

local function Update(self)
	local id = Settings[GetSettingID(self)] or 0
	local data = id > 0 and YxUI.GetDataTextLastValue(self, ReadCurrency(id))
	local name = data and data.name or "Currency"
	local amount = data and YxUI:Comma(data.quantity) or (id > 0 and "--" or "Select")
	self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%s|r", Settings["data-text-label-color"], name, YxUI.ValueColor, amount)
end

local function OnEnable(self)
	self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:SetScript("OnEvent", Update)
	self:SetScript("OnMouseUp", OnMouseUp)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", function() GameTooltip:Hide() end)
	self:Update()
end

local function OnDisable(self)
	self:UnregisterAllEvents()
	self:SetScript("OnEvent", nil)
	self:SetScript("OnMouseUp", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)
	self.Text:SetText("")
end

YxUI:AddDataText("Currency", OnEnable, OnDisable, Update)
