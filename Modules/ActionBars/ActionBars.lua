local YxUI, Language, Assets, Settings, Defaults = select(2, ...):get()

local AB = YxUI:NewModule("Action Bars")
local GUI = YxUI:GetModule("GUI")
local NumPad = KEY_NUMPAD1:gsub("%s%S$", "")
local WheelUp = KEY_MOUSEWHEELUP
local WheelDown = KEY_MOUSEWHEELDOWN
local MouseButton = KEY_BUTTON4:gsub("%s%S$", "")
local MiddleButton = KEY_BUTTON3

-- The descriptor table is the single source of truth for standard action bars.
-- Optional bars report their availability so creation and configuration can skip them.
local ActionBarDescriptors = {
	{ index = 1, field = "Bar1", label = "Bar 1", parent = nil, prefix = "ActionButton", anchor = { "BOTTOM", "UIParent", "BOTTOM", 0, 13 }, defaultPerRow = 12, hasButtonMax = true, available = function() return ActionButton1 ~= nil end, securePaging = true },
	{ index = 2, field = "Bar2", label = "Bar 2", parent = "MultiBarBottomLeft", prefix = "MultiBarBottomLeftButton", anchor = { "BOTTOM", "Bar1", "TOP", 0, "gap" }, defaultPerRow = 12, hasButtonMax = true, available = function() return MultiBarBottomLeft ~= nil end },
	{ index = 3, field = "Bar3", label = "Bar 3", parent = "MultiBarBottomRight", prefix = "MultiBarBottomRightButton", anchor = { "BOTTOM", "Bar2", "TOP", 0, "gap" }, defaultPerRow = 12, hasButtonMax = true, available = function() return MultiBarBottomRight ~= nil end },
	{ index = 4, field = "Bar4", label = "Bar 4", parent = "MultiBarRight", prefix = "MultiBarRightButton", anchor = { "RIGHT", "UIParent", "RIGHT", -12, 0 }, defaultPerRow = 1, hasButtonMax = true, available = function() return MultiBarRight ~= nil end },
	{ index = 5, field = "Bar5", label = "Bar 5", parent = "MultiBarLeft", prefix = "MultiBarLeftButton", anchor = { "RIGHT", "Bar4", "LEFT", "negativeGap", 0 }, defaultPerRow = 1, hasButtonMax = true, available = function() return MultiBarLeft ~= nil end },
	{ index = 6, field = "Bar6", label = "Bar 6", parent = "MultiBar5", prefix = "MultiBar5Button", anchor = { "RIGHT", "Bar5", "LEFT", "negativeGap", 0 }, defaultPerRow = 1, hasButtonMax = true, available = function() return MultiBar5 ~= nil end },
	{ index = 7, field = "Bar7", label = "Bar 7", parent = "MultiBar6", prefix = "MultiBar6Button", anchor = { "RIGHT", "Bar6", "LEFT", "negativeGap", 0 }, defaultPerRow = 1, hasButtonMax = true, available = function() return MultiBar6 ~= nil end },
	{ index = 8, field = "Bar8", label = "Bar 8", parent = "MultiBar7", prefix = "MultiBar7Button", anchor = { "RIGHT", "Bar7", "LEFT", "negativeGap", 0 }, defaultPerRow = 1, hasButtonMax = true, available = function() return MultiBar7 ~= nil end },
}

AB.ActionBarDescriptors = ActionBarDescriptors

-- Defaults
Defaults["ab-enable"] = true

Defaults["ab-show-hotkey"] = true
Defaults["ab-show-swipe"] = true
if YxUI.IsMainline then
	Defaults["ab-hide-assisted-combat"] = true
	Defaults["ab-show-action-cast-animation"] = false
end
Defaults["ab-show-count"] = true
Defaults["ab-show-macro"] = true

Defaults["ab-font"] = "PT Sans"
Defaults["ab-font-size"] = 12
Defaults["ab-cd-size"] = 18
Defaults["ab-font-flags"] = ""

for _, descriptor in ipairs(ActionBarDescriptors) do
	local key = "ab-bar" .. descriptor.index
	Defaults[key .. "-enable"] = descriptor.index <= 5
	Defaults[key .. "-hover"] = false
	Defaults[key .. "-button-size"] = 32
	Defaults[key .. "-button-gap"] = 2
	Defaults[key .. "-per-row"] = descriptor.defaultPerRow
	Defaults[key .. "-alpha"] = 100

	if descriptor.hasButtonMax then
		Defaults[key .. "-button-max"] = 12
	end
end

Defaults["ab-pet-enable"] = true
Defaults["ab-pet-hover"] = false
Defaults["ab-pet-button-size"] = 32
Defaults["ab-pet-button-gap"] = 2
Defaults["ab-pet-per-row"] = 1
Defaults["ab-pet-alpha"] = 100

Defaults["ab-stance-enable"] = true
Defaults["ab-stance-hover"] = false
Defaults["ab-stance-button-size"] = 32
Defaults["ab-stance-button-gap"] = 2
Defaults["ab-stance-per-row"] = 12
Defaults["ab-stance-alpha"] = 100

Defaults["ab-totem-enable"] = true
Defaults["ab-extra-button-size"] = 60

function AB:Disable(object)
	if not object then
		return
	end

	if object.UnregisterAllEvents then
		object:UnregisterAllEvents()
	end

	object:SetParent(self.Hide)
end

local PendingBarUpdates = {}
local SecureUpdateDriver = CreateFrame("Frame")
SecureUpdateDriver:SetScript("OnEvent", function(self)
	if InCombatLockdown() then
		return
	end

	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	local updates = PendingBarUpdates
	PendingBarUpdates = {}

	for bar, pending in next, updates do
		if pending.layout then pending.layout() end
		if pending.flyout then pending.flyout() end
		if pending.position then pending.position() end
		if pending.hover then pending.hover() end
		if pending.visibility then pending.visibility() end
	end
end)

function AB:RunProtectedUpdate(bar, operation, action)
	if not bar then
		return
	end

	if InCombatLockdown() then
		local pending = PendingBarUpdates[bar]
		if not pending then
			pending = {}
			PendingBarUpdates[bar] = pending
		end
		pending[operation] = action
		SecureUpdateDriver:RegisterEvent("PLAYER_REGEN_ENABLED")
	else
		local pending = PendingBarUpdates[bar]
		if pending then
			pending[operation] = nil
			if not next(pending) then PendingBarUpdates[bar] = nil end
		end
		action()
	end
end

function AB:EnableBar(bar)
	if not bar then
		return
	end
	if InCombatLockdown() then
		return self:RunProtectedUpdate(bar, "visibility", function() self:EnableBar(bar) end)
	end

	RegisterAttributeDriver(bar, "state-visibility", "[nopetbattle] show; hide")
	bar:Show()
end

function AB:DisableBar(bar)
	if not bar then
		return
	end
	if InCombatLockdown() then
		return self:RunProtectedUpdate(bar, "visibility", function() self:DisableBar(bar) end)
	end

	UnregisterAttributeDriver(bar, "state-visibility")
	bar:Hide()
end

function AB:UpdateHotKeyText()
	local HotKey = self.HotKey
	if not HotKey then
		return
	end

	local Text = HotKey:GetText()
	if not Text or (issecretvalue and issecretvalue(Text)) then
		return
	end

	if Text == self.YxUIHotKeyFormatted then
		return
	elseif Text == self.YxUIHotKeySource then
		HotKey:SetText(self.YxUIHotKeyFormatted)
		return
	end

	local Formatted = Text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
	Formatted = Formatted:gsub(NumPad, "N")
	Formatted = Formatted:gsub(WheelUp, "MWU")
	Formatted = Formatted:gsub(WheelDown, "MWD")
	Formatted = Formatted:gsub(MouseButton, "MB")
	Formatted = Formatted:gsub(MiddleButton, "MMB")
	Formatted = Formatted:gsub(CTRL_KEY_TEXT, "c")
	Formatted = Formatted:gsub(SHIFT_KEY_TEXT, "s")
	Formatted = Formatted:gsub(ALT_KEY_TEXT, "a")

	self.YxUIHotKeySource = Text
	self.YxUIHotKeyFormatted = Formatted

	if Formatted ~= Text then
		HotKey:SetText(Formatted)
	end
end

local function GetVisibleButtonParent(bar)
	local parent = bar.ButtonParent
	if parent and parent:IsVisible() then
		return parent
	end
	return bar
end

local function RestoreButton(button, parent)
	if button:GetParent() ~= parent then
		button:SetParent(parent)
	end
	if not button:IsShown() then
		button:Show()
	end
end

function AB:PositionButtons(bar, numbuttons, perrow, size, spacing)
	if not bar then
		return
	end
	if InCombatLockdown() then
		return self:RunProtectedUpdate(bar, "layout", function()
			self:PositionButtons(bar, numbuttons, perrow, size, spacing)
		end)
	end

	local isActionBar = bar.Descriptor and bar.Descriptor.hasButtonMax
	local parent = isActionBar and GetVisibleButtonParent(bar)
	if isActionBar and bar.DisplayedButtonCount and numbuttons > bar.DisplayedButtonCount then
		-- Restore all slots first, then apply the destination profile's button limit.
		for i = 1, #bar do
			RestoreButton(bar[i], parent)
		end
	end

	if numbuttons < perrow then
		perrow = numbuttons
	end

	local Columns = ceil(numbuttons / perrow)

	if Columns < 1 then
		Columns = 1
	end

	bar:SetWidth((size * perrow) + (spacing * (perrow - 1)))
	bar:SetHeight((size * Columns) + (spacing * (Columns - 1)))

	for i = 1, #bar do
		local Button = bar[i]

		Button:ClearAllPoints()
		Button:SetSize(size, size)

		if i == 1 then
			Button:SetPoint("TOPLEFT", bar, 0, 0)
		elseif (i - 1) % perrow == 0 then
			Button:SetPoint("TOP", bar[i - perrow], "BOTTOM", 0, -spacing)
		else
			Button:SetPoint("LEFT", bar[i - 1], "RIGHT", spacing, 0)
		end

		if i > numbuttons then
			if Button:GetParent() ~= self.Hide then
				Button:SetParent(self.Hide)
			end
		elseif isActionBar then
			RestoreButton(Button, parent)
		else
			local buttonParent = bar.ButtonParent
			if not buttonParent or not buttonParent:IsShown() then
				buttonParent = bar
			end
			if Button:GetParent() == self.Hide or (bar.ButtonParent and Button:GetParent() == bar.ButtonParent and buttonParent == bar) then
				Button:SetParent(buttonParent)
			end
			if not Button:IsShown() then
				Button:Show()
			end
		end
	end

	if isActionBar then
		bar.DisplayedButtonCount = numbuttons
	end
end

function AB:Load()
	if not Settings["ab-enable"] then
		return
	end

	self.Hide = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
	self.Hide:Hide()

	self:ShowActionBars()
	self:Disable(MainMenuBar)
	self:CreateBars()
	self:CreateMovers()

	if MainActionBar then
		MainActionBar:SetAlpha(0)
		MainActionBar:EnableMouse(false)
	end

	if YxUI.IsMainline and C_ActionBar and C_ActionBar.EnableActionRangeCheck then
		local ButtonsBySlot = {}
		local SlotsByButton = {}

		local function TrackButtonSlot(button)
			local slot = button.action
			if issecretvalue and issecretvalue(slot) then
				slot = nil
			end

			local previous = SlotsByButton[button]
			if previous == slot then
				return
			end

			if previous ~= nil then
				local buttons = ButtonsBySlot[previous]
				buttons[button] = nil
				if not next(buttons) then
					ButtonsBySlot[previous] = nil
				end
			end

			SlotsByButton[button] = slot
			if slot ~= nil then
				local buttons = ButtonsBySlot[slot]
				if not buttons then
					buttons = {}
					ButtonsBySlot[slot] = buttons
				end
				buttons[button] = true
			end
		end

		for _, bar in ipairs(self.Bars) do
			for i = 1, #bar do
				local button = bar[i]
				if button.UpdateAction then
					hooksecurefunc(button, "UpdateAction", TrackButtonSlot)
				elseif button.Update then
					hooksecurefunc(button, "Update", TrackButtonSlot)
				end
				TrackButtonSlot(button)
			end
		end

		local RangeEvents = CreateFrame("Frame")
		RangeEvents:RegisterEvent("ACTION_RANGE_CHECK_UPDATE")
		RangeEvents:SetScript("OnEvent", function(_, _, slot, inRange, checksRange)
			if issecretvalue and issecretvalue(slot) then
				return
			end

			local buttons = ButtonsBySlot[slot]
			if buttons then
				for button in next, buttons do
					AB:UpdateButtonRange(button, inRange, checksRange)
				end
			end
		end)
	elseif ActionButton_UpdateRangeIndicator then
		hooksecurefunc("ActionButton_UpdateRangeIndicator", AB.UpdateButtonStatus)
	end

	if YxUI.IsForever and ActionButton_UpdateRangeIndicator then
		hooksecurefunc("ActionButton_UpdateRangeIndicator", function(button)
			local hotkey = button.Styled and button.HotKey
			if hotkey then
				local text = hotkey:GetText()
				if (not issecretvalue or not issecretvalue(text)) and text == RANGE_INDICATOR then
					hotkey:Hide()
				end
			end
		end)
	end

	if ActionButton_UpdateFlyout then
		hooksecurefunc("ActionButton_UpdateFlyout", AB.UpdateFlyout)
	end

	if not YxUI.IsMainline and ActionButton_Update then
		hooksecurefunc("ActionButton_Update", AB.UpdateButtonStatus)
	end
end

local function UpdateExtraActionSize()
	if not AB.ExtraBar then return end
	AB:RunProtectedUpdate(AB.ExtraBar, "layout", function()
		AB.ExtraBar:SetSize(Settings["ab-extra-button-size"], Settings["ab-extra-button-size"])
	end)
end

GUI:AddWidgetsID("General", "Action Bars", function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("ab-enable", Settings["ab-enable"], Language["Enable Action Bar"], Language["Enable action bars module"], ReloadUI):RequiresReload(true)
	left:CreateHeader(Language["Extra Action"])
	left:CreateSlider("ab-extra-button-size", Settings["ab-extra-button-size"], 32, 100, 2, Language["Button Size"], Language["Size of the extra action button"], UpdateExtraActionSize)
end)

GUI:RegisterPageSettingsID("General", "Action Bars", {
	{"ab-extra-button-size", UpdateExtraActionSize},
}, nil)
GUI:RegisterReloadSettings({"ab-enable"})
