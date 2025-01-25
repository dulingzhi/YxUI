local HydraUI, Language, Assets, Settings, Defaults = select(2, ...):get()

local AB = HydraUI:NewModule("Action Bars")
local GUI = HydraUI:GetModule("GUI")

local IsUsableAction = IsUsableAction
local NUM_PET_ACTION_SLOTS = NUM_PET_ACTION_SLOTS

local NumPad = KEY_NUMPAD1:gsub("%s%S$", "")
local WheelUp = KEY_MOUSEWHEELUP
local WheelDown = KEY_MOUSEWHEELDOWN
local MouseButton = KEY_BUTTON4:gsub("%s%S$", "")
local MiddleButton = KEY_BUTTON3

-- Defaults
Defaults["ab-enable"] = true

Defaults["ab-show-hotkey"] = true
Defaults["ab-show-count"] = true
Defaults["ab-show-macro"] = true
Defaults["ab-show-empty"] = true

Defaults["ab-font"] = "PT Sans"
Defaults["ab-font-size"] = 12
Defaults["ab-cd-size"] = 18
Defaults["ab-font-flags"] = ""

Defaults["ab-bar1-enable"] = true
Defaults["ab-bar1-hover"] = false
Defaults["ab-bar1-button-size"] = 32
Defaults["ab-bar1-button-gap"] = 2
Defaults["ab-bar1-button-max"] = 12
Defaults["ab-bar1-per-row"] = 12
Defaults["ab-bar1-alpha"] = 100

Defaults["ab-bar2-enable"] = true
Defaults["ab-bar2-hover"] = false
Defaults["ab-bar2-button-size"] = 32
Defaults["ab-bar2-button-gap"] = 2
Defaults["ab-bar2-button-max"] = 12
Defaults["ab-bar2-per-row"] = 12
Defaults["ab-bar2-alpha"] = 100

Defaults["ab-bar3-enable"] = true
Defaults["ab-bar3-hover"] = false
Defaults["ab-bar3-button-size"] = 32
Defaults["ab-bar3-button-gap"] = 2
Defaults["ab-bar3-button-max"] = 12
Defaults["ab-bar3-per-row"] = 12
Defaults["ab-bar3-alpha"] = 100

Defaults["ab-bar4-enable"] = true
Defaults["ab-bar4-hover"] = false
Defaults["ab-bar4-button-size"] = 32
Defaults["ab-bar4-button-gap"] = 2
Defaults["ab-bar4-button-max"] = 12
Defaults["ab-bar4-per-row"] = 1
Defaults["ab-bar4-alpha"] = 100

Defaults["ab-bar5-enable"] = true
Defaults["ab-bar5-hover"] = false
Defaults["ab-bar5-button-size"] = 32
Defaults["ab-bar5-button-gap"] = 2
Defaults["ab-bar5-button-max"] = 12
Defaults["ab-bar5-per-row"] = 1
Defaults["ab-bar5-alpha"] = 100

Defaults["ab-bar6-enable"] = true
Defaults["ab-bar6-hover"] = false
Defaults["ab-bar6-button-size"] = 32
Defaults["ab-bar6-button-gap"] = 2
Defaults["ab-bar6-button-max"] = 12
Defaults["ab-bar6-per-row"] = 1
Defaults["ab-bar6-alpha"] = 100

Defaults["ab-bar7-enable"] = true
Defaults["ab-bar7-hover"] = false
Defaults["ab-bar7-button-size"] = 32
Defaults["ab-bar7-button-gap"] = 2
Defaults["ab-bar7-button-max"] = 12
Defaults["ab-bar7-per-row"] = 1
Defaults["ab-bar7-alpha"] = 100

Defaults["ab-bar8-enable"] = true
Defaults["ab-bar8-hover"] = false
Defaults["ab-bar8-button-size"] = 32
Defaults["ab-bar8-button-gap"] = 2
Defaults["ab-bar8-button-max"] = 12
Defaults["ab-bar8-per-row"] = 1
Defaults["ab-bar8-alpha"] = 100

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

local ActionBars = {
	"ActionButton",
	"MultiBarBottomLeftButton",
	"MultiBarBottomRightButton",
	"MultiBarLeftButton",
	"MultiBarRightButton",
}

function AB:Disable(object)
	if object.UnregisterAllEvents then
		object:UnregisterAllEvents()
	end

	object:SetParent(self.Hide)
end

function AB:EnableBar(bar)
	RegisterAttributeDriver(bar, "state-visibility", "[nopetbattle] show; hide")
	bar:Show()
end

function AB:DisableBar(bar)
	UnregisterAttributeDriver(bar, "state-visibility")
	bar:Hide()
end

function AB:UpdateHotKeyText()
	local Text = self.HotKey:GetText()

	if Text then
		Text = Text:gsub(NumPad, "N")
		Text = Text:gsub(WheelUp, "MWU")
		Text = Text:gsub(WheelDown, "MWD")
		Text = Text:gsub(MouseButton, "MB")
		Text = Text:gsub(MiddleButton, "MMB")
		Text = Text:gsub(CTRL_KEY_TEXT, "c")
		Text = Text:gsub(SHIFT_KEY_TEXT, "s")
		Text = Text:gsub(ALT_KEY_TEXT, "a")

		self.HotKey:SetText("|cFFFFFFFF" .. Text .. "|r")
	end
end

function AB:PositionButtons(bar, numbuttons, perrow, size, spacing)
	if (numbuttons < perrow) then
		perrow = numbuttons
	end

	local Columns = ceil(numbuttons / perrow)

	if (Columns < 1) then
		Columns = 1
	end

	-- Bar sizing
	bar:SetWidth((size * perrow) + (spacing * (perrow - 1)))
	bar:SetHeight((size * Columns) + (spacing * (Columns - 1)))

	-- Actual moving
	for i = 1, #bar do
		local Button = bar[i]

		Button:ClearAllPoints()
		Button:SetSize(size, size)

		if (i == 1) then
			Button:SetPoint("TOPLEFT", bar, 0, 0)
		elseif ((i - 1) % perrow == 0) then
			Button:SetPoint("TOP", bar[i - perrow], "BOTTOM", 0, -spacing)
		else
			Button:SetPoint("LEFT", bar[i - 1], "RIGHT", spacing, 0)
		end

		if (i > numbuttons) then
			Button:SetParent(self.Hide)
		else
			Button:SetParent(bar.ButtonParent or bar)
		end
	end
end

function AB:StyleActionButton(button)
	if button.Styled then
		return
	end

	if button.IconMask then
		button.IconMask:Hide()
	end

	if button.RightDivider then
		button.RightDivider:Hide()
	end

	if button.SlotArt then
		button.SlotArt:Hide()
	end

	if _G[button:GetName().."NormalTexture"] then
		_G[button:GetName().."NormalTexture"]:SetTexture(nil)
	end

	if button:GetNormalTexture() then
		button:GetNormalTexture():SetTexture(nil)
	end

	button:SetNormalTexture("")

	if button.Border then
		button.Border:SetTexture(nil)
	end

	if button.icon then
		button.icon:ClearAllPoints()
		button.icon:SetPoint("TOPLEFT", button, 1, -1)
		button.icon:SetPoint("BOTTOMRIGHT", button, -1, 1)
		button.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
	end

	if _G[button:GetName() .. "FloatingBG"] then
		self:Disable(_G[button:GetName() .. "FloatingBG"])
	end

	if button.HotKey then
		button.HotKey:ClearAllPoints()
		button.HotKey:SetPoint("TOPLEFT", button, 2, -3)
		HydraUI:SetFontInfo(button.HotKey, Settings["ab-font"], Settings["ab-font-size"], Settings["ab-font-flags"])
		button.HotKey:SetJustifyH("LEFT")
		button.HotKey:SetTextColor(1, 1, 1)
		button.HotKey.SetTextColor = function() end

		local Text = button.HotKey:GetText()

		if Text then
			Text = Text:gsub(NumPad, "N")
			Text = Text:gsub(WheelUp, "MWU")
			Text = Text:gsub(WheelDown, "MWD")
			Text = Text:gsub(MouseButton, "MB")
			Text = Text:gsub(MiddleButton, "MMB")
			Text = Text:gsub(CTRL_KEY_TEXT, "c")
			Text = Text:gsub(SHIFT_KEY_TEXT, "s")
			Text = Text:gsub(ALT_KEY_TEXT, "a")

			button.HotKey:SetText("|cFFFFFFFF" .. Text .. "|r")
		end

		button.HotKey.OST = button.HotKey.SetText
		button.HotKey.SetText = function(self, text)
			self:OST("|cFFFFFFFF" .. text .. "|r")
		end

		if (not Settings["ab-show-hotkey"]) then
			button.HotKey:SetAlpha(0)
		end
	end

	if button.Name then
		button.Name:ClearAllPoints()
		button.Name:SetPoint("BOTTOMLEFT", button, 2, 2)
		button.Name:SetWidth(button:GetWidth() - 4)
		HydraUI:SetFontInfo(button.Name, Settings["ab-font"], Settings["ab-font-size"], Settings["ab-font-flags"])
		button.Name:SetJustifyH("LEFT")
		button.Name:SetTextColor(1, 1, 1)
		button.Name.SetTextColor = function() end

		if (not Settings["ab-show-macro"]) then
			button.Name:SetAlpha(0)
		end
	end

	if button.Count then
		button.Count:ClearAllPoints()
		button.Count:SetPoint("BOTTOMRIGHT", button, -2, 2)
		HydraUI:SetFontInfo(button.Count, Settings["ab-font"], Settings["ab-font-size"], Settings["ab-font-flags"])
		button.Count:SetJustifyH("RIGHT")
		button.Count:SetDrawLayer("OVERLAY")
		button.Count:SetTextColor(1, 1, 1)
		button.Count.SetTextColor = function() end

		if (not Settings["ab-show-count"]) then
			button.Count:SetAlpha(0)
		end
	end

	button.Backdrop = CreateFrame("Frame", nil, button, "BackdropTemplate")
	button.Backdrop:SetPoint("TOPLEFT", button, 0, 0)
	button.Backdrop:SetPoint("BOTTOMRIGHT", button, 0, 0)
	button.Backdrop:SetBackdrop(HydraUI.Backdrop)
	button.Backdrop:SetBackdropColor(0, 0, 0)
	button.Backdrop:SetFrameLevel(button:GetFrameLevel() - 1)

	button.Backdrop.Texture = button.Backdrop:CreateTexture(nil, "BORDER")
	button.Backdrop.Texture:SetPoint("TOPLEFT", button.Backdrop, 1, -1)
	button.Backdrop.Texture:SetPoint("BOTTOMRIGHT", button.Backdrop, -1, 1)
	button.Backdrop.Texture:SetTexture(Assets:GetTexture(Settings["ui-header-texture"]))
	button.Backdrop.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-window-main-color"]))

	if button:GetCheckedTexture() then
		local Checked = button:GetCheckedTexture()
		Checked:SetTexture(Assets:GetTexture(Settings["action-bars-button-highlight"]))
		Checked:SetColorTexture(0.1, 0.9, 0.1, 0.2)
		Checked:SetPoint("TOPLEFT", button, 1, -1)
		Checked:SetPoint("BOTTOMRIGHT", button, -1, 1)
	end

	if button:GetPushedTexture() then
		local Pushed = button:GetPushedTexture()
		Pushed:SetTexture(Assets:GetTexture(Settings["action-bars-button-highlight"]))
		Pushed:SetColorTexture(0.9, 0.8, 0.1, 0.3)
		Pushed:SetPoint("TOPLEFT", button, 1, -1)
		Pushed:SetPoint("BOTTOMRIGHT", button, -1, 1)
	end

	local Highlight = button:GetHighlightTexture()
	Highlight:SetTexture(Assets:GetTexture(Settings["action-bars-button-highlight"]))
	Highlight:SetColorTexture(1, 1, 1, 0.2)
	Highlight:SetPoint("TOPLEFT", button, 1, -1)
	Highlight:SetPoint("BOTTOMRIGHT", button, -1, 1)

	if button.Flash then
		button.Flash:SetVertexColor(0.7, 0.7, 0.1, 0.3)
		button.Flash:SetPoint("TOPLEFT", button, 1, -1)
		button.Flash:SetPoint("BOTTOMRIGHT", button, -1, 1)
	end

	local Range = button:CreateTexture(nil, "ARTWORK")
	Range:SetTexture(Assets:GetTexture(Settings["action-bars-button-highlight"]))
	Range:SetVertexColor(0.7, 0, 0)
	Range:SetPoint("TOPLEFT", button, 1, -1)
	Range:SetPoint("BOTTOMRIGHT", button, -1, 1)
	Range:SetAlpha(0)

	button.Range = Range

	if button.cooldown then
		button.cooldown:ClearAllPoints()
		button.cooldown:SetPoint("TOPLEFT", button, 1, -1)
		button.cooldown:SetPoint("BOTTOMRIGHT", button, -1, 1)

		button.cooldown:SetDrawEdge(true)
		button.cooldown:SetEdgeTexture(Assets:GetTexture("Blank"))
		button.cooldown:SetSwipeColor(0, 0, 0, 1)

		local FontString = button.cooldown:GetRegions()

		if FontString then
			HydraUI:SetFontInfo(FontString, Settings["ab-font"], Settings["ab-cd-size"], Settings["ab-font-flags"])
		end
	end

	button:SetFrameLevel(15)
	button:SetFrameStrata("MEDIUM")

	if button.Update then
		hooksecurefunc(button, "Update", AB.UpdateHotKeyText)
	elseif ActionButton_UpdateHotkeys then
		hooksecurefunc("ActionButton_UpdateHotkeys", AB.UpdateHotKeyText)
	end

	button.Styled = true
end

function AB:StylePetActionButton(button)
	if button.Styled then
		return
	end

	button:SetSize(Settings["ab-pet-button-size"], Settings["ab-pet-button-size"])

	local Name = button:GetName()

	if _G[Name .. "AutoCastable"] then
		_G[Name .. "AutoCastable"]:SetSize(Settings["ab-pet-button-size"] * 2 - 4, Settings["ab-pet-button-size"] * 2 - 4)
	end

	local Shine = _G[Name .. "Shine"]

	if Shine then
		Shine:SetSize(Settings["ab-pet-button-size"] - 6, Settings["ab-pet-button-size"] - 6)
		Shine:ClearAllPoints()
		Shine:SetPoint("CENTER", button, 0, 0)
	end

	button.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
	button.icon:SetDrawLayer("BACKGROUND", 7)
	button.icon:SetPoint("TOPLEFT", button, 1, -1)
	button.icon:SetPoint("BOTTOMRIGHT", button, -1, 1)

	if button.IconMask then
		button.IconMask:Hide()
	end

	if button.SlotArt then
		button.SlotArt:Hide()
	end

	_G[button:GetName().."NormalTexture"]:SetAlpha(0)
	_G[button:GetName().."NormalTexture"]:Hide()
	button:GetNormalTexture():SetAlpha(0)
	button:GetNormalTexture():Hide()

	button:SetNormalTexture("")

	if button.HotKey then
		button.HotKey:ClearAllPoints()
		button.HotKey:SetPoint("TOPLEFT", button, 2, -3)
		HydraUI:SetFontInfo(button.HotKey, Settings["ab-font"], Settings["ab-font-size"], Settings["ab-font-flags"])
		button.HotKey:SetJustifyH("LEFT")
		button.HotKey:SetDrawLayer("OVERLAY")
		button.HotKey:SetTextColor(1, 1, 1)
		button.HotKey.SetTextColor = function() end

		local Text = button.HotKey:GetText()

		if Text then
			button.HotKey:SetText("|cFFFFFFFF" .. Text .. "|r")
		end

		button.HotKey.OST = button.HotKey.SetText
		button.HotKey.SetText = function(self, text)
			self:OST("|cFFFFFFFF" .. text .. "|r")
		end

		if (not Settings["action-bars-show-hotkeys"]) then
			button.HotKey:SetAlpha(0)
		end
	end

	if button.Name then
		button.Name:ClearAllPoints()
		button.Name:SetPoint("BOTTOMLEFT", button, 2, 2)
		button.Name:SetWidth(button:GetWidth() - 4)
		HydraUI:SetFontInfo(button.Name, Settings["ab-font"], Settings["ab-font-size"], Settings["ab-font-flags"])
		button.Name:SetJustifyH("LEFT")
		button.Name:SetDrawLayer("OVERLAY")
		button.Name:SetTextColor(1, 1, 1)
		button.Name.SetTextColor = function() end

		if (not Settings["action-bars-show-macro-names"]) then
			button.Name:SetAlpha(0)
		end
	end

	if button.Count then
		button.Count:ClearAllPoints()
		button.Count:SetPoint("BOTTOMRIGHT", button, -2, 2)
		HydraUI:SetFontInfo(button.Count, Settings["ab-font"], Settings["ab-font-size"], Settings["ab-font-flags"])
		button.Count:SetJustifyH("RIGHT")
		button.Count:SetDrawLayer("OVERLAY")
		button.Count:SetTextColor(1, 1, 1)
		button.Count.SetTextColor = function() end

		if (not Settings["action-bars-show-count"]) then
			button.Count:SetAlpha(0)
		end
	end

	_G[Name.."Flash"]:SetTexture("")

	if _G[Name .. "NormalTexture2"] then
		_G[Name .. "NormalTexture2"]:Hide()
	end

	local Checked = button:GetCheckedTexture()
	Checked:SetTexture(Assets:GetTexture(Settings["action-bars-button-highlight"]))
	Checked:SetColorTexture(0.1, 0.9, 0.1, 0.3)
	Checked:SetPoint("TOPLEFT", button, 1, -1)
	Checked:SetPoint("BOTTOMRIGHT", button, -1, 1)

	local Pushed = button:GetPushedTexture()
	Pushed:SetTexture(Assets:GetTexture(Settings["action-bars-button-highlight"]))
	Pushed:SetColorTexture(0.9, 0.8, 0.1, 0.3)
	Pushed:SetPoint("TOPLEFT", button, 1, -1)
	Pushed:SetPoint("BOTTOMRIGHT", button, -1, 1)

	local Highlight = button:GetHighlightTexture()
	Highlight:SetTexture(Assets:GetTexture(Settings["action-bars-button-highlight"]))
	Highlight:SetColorTexture(1, 1, 1, 0.2)
	Highlight:SetPoint("TOPLEFT", button, 1, -1)
	Highlight:SetPoint("BOTTOMRIGHT", button, -1, 1)

	button.Backdrop = CreateFrame("Frame", nil, button, "BackdropTemplate")
	button.Backdrop:SetPoint("TOPLEFT", button, 0, 0)
	button.Backdrop:SetPoint("BOTTOMRIGHT", button, 0, 0)
	button.Backdrop:SetBackdrop(HydraUI.Backdrop)
	button.Backdrop:SetBackdropColor(0, 0, 0)
	button.Backdrop:SetFrameLevel(button:GetFrameLevel() - 1)

	button.Backdrop.Texture = button.Backdrop:CreateTexture(nil, "BORDER")
	button.Backdrop.Texture:SetPoint("TOPLEFT", button.Backdrop, 1, -1)
	button.Backdrop.Texture:SetPoint("BOTTOMRIGHT", button.Backdrop, -1, 1)
	button.Backdrop.Texture:SetTexture(Assets:GetTexture(Settings["ui-header-texture"]))
	button.Backdrop.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-window-main-color"]))

	button.Styled = true
end

function AB:PetActionBar_Update()
	for i = 1, NUM_PET_ACTION_SLOTS do
		AB.PetBar[i]:SetNormalTexture("")
	end
end

function AB:StanceBar_UpdateState()
	if (not Settings["ab-stance-enable"]) then
		return
	end

	if (GetNumShapeshiftForms() > 0) then
		if (not AB.StanceBar:IsShown()) then
			AB:EnableBar(AB.StanceBar)
		end
	elseif AB.StanceBar:IsShown() then
		AB:DisableBar(AB.StanceBar)
	end
end

function AB:UpdateButtonStatus(check, inrange)
	if (not check or not self.action) then
		return
	end

	local IsUsable, NoMana = IsUsableAction(self.action)

	if IsUsable then
		if (inrange == false) then
			self.icon:SetVertexColor(HydraUI:HexToRGB("FF4C19"))
		else
			self.icon:SetVertexColor(HydraUI:HexToRGB("FFFFFF"))
		end
	elseif NoMana then
		self.icon:SetVertexColor(HydraUI:HexToRGB("7F7FE1"))
	else
		self.icon:SetVertexColor(HydraUI:HexToRGB("4C4C4C"))
	end
end

local BarButtonOnEnter = function(self)
	if self.ParentBar.Fader:IsPlaying() then
		self.ParentBar.Fader:Stop()
	end

	for i = 1, #self.ParentBar do
		self.ParentBar[i].cooldown:SetDrawBling(true)
	end

	self.ParentBar.Fader:SetChange(self.ParentBar.MaxAlpha / 100)
	self.ParentBar.Fader:Play()
end

local BarButtonOnLeave = function(self)
	if self.ParentBar.Fader:IsPlaying() then
		self.ParentBar.Fader:Stop()
	end

	for i = 1, #self.ParentBar do
		self.ParentBar[i].cooldown:SetDrawBling(false)
	end

	self.ParentBar.Fader:SetChange(self.ParentBar.ShouldFade and 0 or (self.ParentBar.MaxAlpha / 100))
	self.ParentBar.Fader:Play()
end

local BarOnEnter = function(self)
	if self.Fader:IsPlaying() then
		self.Fader:Stop()
	end

	for i = 1, #self do
		self[i].cooldown:SetDrawBling(true)
	end

	self.Fader:SetChange(self.MaxAlpha / 100)
	self.Fader:Play()
end

local BarOnLeave = function(self)
	if self.Fader:IsPlaying() then
		self.Fader:Stop()
	end

	for i = 1, #self do
		self[i].cooldown:SetDrawBling(false)
	end

	self.Fader:SetChange(self.ShouldFade and 0 or (self.MaxAlpha / 100))
	self.Fader:Play()
end

-- Bar 1
function AB:CreateBar1()
	self.Bar1 = CreateFrame("Frame", "HydraUI Action Bar 1", HydraUI.UIParent, "SecureHandlerStateTemplate")
	self.Bar1:SetPoint("BOTTOM", HydraUI.UIParent, "BOTTOM", 0, 13)
	self.Bar1:SetAlpha(Settings["ab-bar1-alpha"] / 100)
	self.Bar1.ShouldFade = Settings["ab-bar1-hover"]
	self.Bar1.MaxAlpha = Settings["ab-bar1-alpha"]
	self.Bar1.GetSpellFlyoutDirection = function() return "UP" end -- Temp

	self.Bar1.Fader = LibMotion:CreateAnimation(self.Bar1, "Fade")
	self.Bar1.Fader:SetDuration(0.15)
	self.Bar1.Fader:SetEasing("inout")

	for i = 1, 12 do
		local Button = _G["ActionButton" .. i]

		self:StyleActionButton(Button)

		Button:SetParent(self.Bar1)
		Button.ParentBar = self.Bar1

		Button:HookScript("OnEnter", BarButtonOnEnter)
		Button:HookScript("OnLeave", BarButtonOnLeave)

		self.Bar1:SetFrameRef("Button" .. i, Button)

		self.Bar1[i] = Button
	end

	if Settings["ab-bar1-hover"] then
		self.Bar1:SetAlpha(0)
		self.Bar1:SetScript("OnEnter", BarOnEnter)
		self.Bar1:SetScript("OnLeave", BarOnLeave)

		for i = 1, #self.Bar1 do
			self.Bar1[i].cooldown:SetDrawBling(false)
		end
	end

	self.Bar1:Execute([[
		Buttons = table.new()

		for i = 1, 12 do
			table.insert(Buttons, self:GetFrameRef("Button" .. i))
		end
	]])

	if HydraUI.IsClassic then
		self.Bar1:SetAttribute("_onstate-page", [[
			if GetOverrideBarIndex and HasOverrideActionBar() then
				newstate = GetOverrideBarIndex() or newstate
			elseif HasTempShapeshiftActionBar() then
				newstate = GetTempShapeshiftBarIndex() or newstate
			elseif HasBonusActionBar() and GetActionBarPage() == 1 then
				newstate = GetBonusBarIndex() or newstate
			else
				newstate = GetActionBarPage() or newstate
			end

			for i = 1, 12 do
				Buttons[i]:SetAttribute("actionpage", newstate)
			end
		]])

		RegisterAttributeDriver(self.Bar1, "state-page", "[overridebar] 14; [shapeshift] 13; [possessbar] 16; [bar:2] 2; [bar:3] 3; [bar:4] 4; [bar:5] 5; [bar:6] 6; [bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10; [bonusbar:5] 11; [form] 1; 1")
	else
		self.Bar1:SetAttribute("_onstate-page", [[
			if GetVehicleBarIndex and HasVehicleActionBar() then
				newstate = GetVehicleBarIndex()
			elseif HasOverrideActionBar and HasOverrideActionBar() then
				newstate = GetOverrideBarIndex()
			elseif HasTempShapeshiftActionBar() then
				newstate = GetTempShapeshiftBarIndex()
			elseif HasBonusActionBar() then
				newstate = GetBonusBarIndex()
			end

			for i = 1, 12 do
				Buttons[i]:SetAttribute("actionpage", newstate)
			end
		]])

		RegisterAttributeDriver(self.Bar1, "state-page", "[overridebar] 14; [shapeshift] 13; [possessbar] 16; [vehicleui] 12; [bar:2] 2; [bar:3] 3; [bar:4] 4; [bar:5] 5; [bar:6] 6; [bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10; [bonusbar:5] 11; [form] 1; 1")
	end

	self:PositionButtons(self.Bar1, Settings["ab-bar1-button-max"], Settings["ab-bar1-per-row"], Settings["ab-bar1-button-size"], Settings["ab-bar1-button-gap"])

	if OverrideActionBar then
		self:Disable(OverrideActionBar)
	end

	if Settings["ab-bar1-enable"] then
		self:EnableBar(self.Bar1)
	else
		self:DisableBar(self.Bar1)
	end
end

-- Bar 2
function AB:CreateBar2()
	self.Bar2 = CreateFrame("Frame", "HydraUI Action Bar 2", HydraUI.UIParent, "SecureHandlerStateTemplate")
	self.Bar2:SetPoint("BOTTOM", self.Bar1, "TOP", 0, Settings["ab-bar2-button-gap"])
	self.Bar2:SetAlpha(Settings["ab-bar2-alpha"] / 100)
	self.Bar2.ButtonParent = MultiBarBottomLeft
	self.Bar2.ShouldFade = Settings["ab-bar2-hover"]
	self.Bar2.MaxAlpha = Settings["ab-bar2-alpha"]

	self.Bar2.Fader = LibMotion:CreateAnimation(self.Bar2, "Fade")
	self.Bar2.Fader:SetDuration(0.15)
	self.Bar2.Fader:SetEasing("inout")

	MultiBarBottomLeft:SetParent(self.Bar2)

	for i = 1, 12 do
		local Button = _G["MultiBarBottomLeftButton" .. i]

		self:StyleActionButton(Button)

		Button.ParentBar = self.Bar2

		Button:HookScript("OnEnter", BarButtonOnEnter)
		Button:HookScript("OnLeave", BarButtonOnLeave)

		self.Bar2[i] = Button
	end

	if Settings["ab-bar2-hover"] then
		self.Bar2:SetAlpha(0)
		self.Bar2:SetScript("OnEnter", BarOnEnter)
		self.Bar2:SetScript("OnLeave", BarOnLeave)

		for i = 1, #self.Bar2 do
			self.Bar2[i].cooldown:SetDrawBling(false)
		end
	end

	self:PositionButtons(self.Bar2, Settings["ab-bar2-button-max"], Settings["ab-bar2-per-row"], Settings["ab-bar2-button-size"], Settings["ab-bar2-button-gap"])

	if Settings["ab-bar2-enable"] then
		self:EnableBar(self.Bar2)
	else
		self:DisableBar(self.Bar2)
	end
end

-- Bar 3
function AB:CreateBar3()
	self.Bar3 = CreateFrame("Frame", "HydraUI Action Bar 3", HydraUI.UIParent, "SecureHandlerStateTemplate")
	self.Bar3:SetPoint("BOTTOM", self.Bar2, "TOP", 0, Settings["ab-bar3-button-gap"])
	self.Bar3:SetAlpha(Settings["ab-bar3-alpha"] / 100)
	self.Bar3.ButtonParent = MultiBarBottomRight
	self.Bar3.ShouldFade = Settings["ab-bar3-hover"]
	self.Bar3.MaxAlpha = Settings["ab-bar3-alpha"]

	self.Bar3.Fader = LibMotion:CreateAnimation(self.Bar3, "Fade")
	self.Bar3.Fader:SetDuration(0.15)
	self.Bar3.Fader:SetEasing("inout")

	MultiBarBottomRight:SetParent(self.Bar3)

	for i = 1, 12 do
		local Button = _G["MultiBarBottomRightButton" .. i]

		self:StyleActionButton(Button)

		Button.ParentBar = self.Bar3

		Button:HookScript("OnEnter", BarButtonOnEnter)
		Button:HookScript("OnLeave", BarButtonOnLeave)

		self.Bar3[i] = Button
	end

	if Settings["ab-bar3-hover"] then
		self.Bar3:SetAlpha(0)
		self.Bar3:SetScript("OnEnter", BarOnEnter)
		self.Bar3:SetScript("OnLeave", BarOnLeave)

		for i = 1, #self.Bar3 do
			self.Bar3[i].cooldown:SetDrawBling(false)
		end
	end

	self:PositionButtons(self.Bar3, Settings["ab-bar3-button-max"], Settings["ab-bar3-per-row"], Settings["ab-bar3-button-size"], Settings["ab-bar3-button-gap"])

	if Settings["ab-bar3-enable"] then
		self:EnableBar(self.Bar3)
	else
		self:DisableBar(self.Bar3)
	end
end

-- Bar 4
function AB:CreateBar4()
	self.Bar4 = CreateFrame("Frame", "HydraUI Action Bar 4", HydraUI.UIParent, "SecureHandlerStateTemplate")
	self.Bar4:SetPoint("RIGHT", HydraUI.UIParent, -12, 0)
	self.Bar4:SetAlpha(Settings["ab-bar4-alpha"] / 100)
	self.Bar4.ButtonParent = MultiBarRight
	self.Bar4.ShouldFade = Settings["ab-bar4-hover"]
	self.Bar4.MaxAlpha = Settings["ab-bar4-alpha"]

	self.Bar4.Fader = LibMotion:CreateAnimation(self.Bar4, "Fade")
	self.Bar4.Fader:SetDuration(0.15)
	self.Bar4.Fader:SetEasing("inout")

	MultiBarRight:SetParent(self.Bar4)

	for i = 1, 12 do
		local Button = _G["MultiBarRightButton" .. i]

		self:StyleActionButton(Button)

		Button.ParentBar = self.Bar4

		Button:HookScript("OnEnter", BarButtonOnEnter)
		Button:HookScript("OnLeave", BarButtonOnLeave)

		self.Bar4[i] = Button
	end

	if Settings["ab-bar4-hover"] then
		self.Bar4:SetAlpha(0)
		self.Bar4:SetScript("OnEnter", BarOnEnter)
		self.Bar4:SetScript("OnLeave", BarOnLeave)

		for i = 1, #self.Bar4 do
			self.Bar4[i].cooldown:SetDrawBling(false)
		end
	end

	self:PositionButtons(self.Bar4, Settings["ab-bar4-button-max"], Settings["ab-bar4-per-row"], Settings["ab-bar4-button-size"], Settings["ab-bar4-button-gap"])

	if Settings["ab-bar4-enable"] then
		self:EnableBar(self.Bar4)
	else
		self:DisableBar(self.Bar4)
	end
end

-- Bar 5
function AB:CreateBar5()
	self.Bar5 = CreateFrame("Frame", "HydraUI Action Bar 5", HydraUI.UIParent, "SecureHandlerStateTemplate")
	self.Bar5:SetPoint("RIGHT", self.Bar4, "LEFT", -Settings["ab-bar5-button-gap"], 0)
	self.Bar5:SetAlpha(Settings["ab-bar5-alpha"] / 100)
	self.Bar5.ButtonParent = MultiBarLeft
	self.Bar5.ShouldFade = Settings["ab-bar5-hover"]
	self.Bar5.MaxAlpha = Settings["ab-bar5-alpha"]

	self.Bar5.Fader = LibMotion:CreateAnimation(self.Bar5, "Fade")
	self.Bar5.Fader:SetDuration(0.15)
	self.Bar5.Fader:SetEasing("inout")

	MultiBarLeft:SetParent(self.Bar5)

	for i = 1, 12 do
		local Button = _G["MultiBarLeftButton" .. i]

		self:StyleActionButton(Button)

		Button.ParentBar = self.Bar5

		Button:HookScript("OnEnter", BarButtonOnEnter)
		Button:HookScript("OnLeave", BarButtonOnLeave)

		self.Bar5[i] = Button
	end

	if Settings["ab-bar5-hover"] then
		self.Bar5:SetAlpha(0)
		self.Bar5:SetScript("OnEnter", BarOnEnter)
		self.Bar5:SetScript("OnLeave", BarOnLeave)

		for i = 1, #self.Bar5 do
			self.Bar5[i].cooldown:SetDrawBling(false)
		end
	end

	self:PositionButtons(self.Bar5, Settings["ab-bar5-button-max"], Settings["ab-bar5-per-row"], Settings["ab-bar5-button-size"], Settings["ab-bar5-button-gap"])

	if Settings["ab-bar5-enable"] then
		self:EnableBar(self.Bar5)
	else
		self:DisableBar(self.Bar5)
	end
end

-- Bar 6
function AB:CreateBar6()
	self.Bar6 = CreateFrame("Frame", "HydraUI Action Bar 6", HydraUI.UIParent, "SecureHandlerStateTemplate")
	self.Bar6:SetPoint("RIGHT", self.Bar5, "LEFT", -Settings["ab-bar6-button-gap"], 0)
	self.Bar6:SetAlpha(Settings["ab-bar6-alpha"] / 100)
	self.Bar6.ButtonParent = MultiBar5
	self.Bar6.ShouldFade = Settings["ab-bar6-hover"]
	self.Bar6.MaxAlpha = Settings["ab-bar6-alpha"]

	self.Bar6.Fader = LibMotion:CreateAnimation(self.Bar6, "Fade")
	self.Bar6.Fader:SetDuration(0.15)
	self.Bar6.Fader:SetEasing("inout")

	MultiBar5:SetParent(self.Bar6)

	for i = 1, 12 do
		local Button = _G["MultiBar5Button" .. i]

		self:StyleActionButton(Button)

		Button.ParentBar = self.Bar6

		Button:HookScript("OnEnter", BarButtonOnEnter)
		Button:HookScript("OnLeave", BarButtonOnLeave)

		self.Bar6[i] = Button
	end

	if Settings["ab-bar6-hover"] then
		self.Bar6:SetAlpha(0)
		self.Bar6:SetScript("OnEnter", BarOnEnter)
		self.Bar6:SetScript("OnLeave", BarOnLeave)

		for i = 1, #self.Bar6 do
			self.Bar6[i].cooldown:SetDrawBling(false)
		end
	end

	self:PositionButtons(self.Bar6, Settings["ab-bar6-button-max"], Settings["ab-bar6-per-row"], Settings["ab-bar6-button-size"], Settings["ab-bar6-button-gap"])

	if Settings["ab-bar6-enable"] then
		self:EnableBar(self.Bar6)
	else
		self:DisableBar(self.Bar6)
	end
end

-- Bar 7
function AB:CreateBar7()
	self.Bar7 = CreateFrame("Frame", "HydraUI Action Bar 7", HydraUI.UIParent, "SecureHandlerStateTemplate")
	self.Bar7:SetPoint("RIGHT", self.Bar6, "LEFT", -Settings["ab-bar7-button-gap"], 0)
	self.Bar7:SetAlpha(Settings["ab-bar7-alpha"] / 100)
	self.Bar7.ButtonParent = MultiBar6
	self.Bar7.ShouldFade = Settings["ab-bar7-hover"]
	self.Bar7.MaxAlpha = Settings["ab-bar7-alpha"]

	self.Bar7.Fader = LibMotion:CreateAnimation(self.Bar7, "Fade")
	self.Bar7.Fader:SetDuration(0.15)
	self.Bar7.Fader:SetEasing("inout")

	MultiBar6:SetParent(self.Bar7)

	for i = 1, 12 do
		local Button = _G["MultiBar6Button" .. i]

		self:StyleActionButton(Button)

		Button.ParentBar = self.Bar7

		Button:HookScript("OnEnter", BarButtonOnEnter)
		Button:HookScript("OnLeave", BarButtonOnLeave)

		self.Bar7[i] = Button
	end

	if Settings["ab-bar7-hover"] then
		self.Bar7:SetAlpha(0)
		self.Bar7:SetScript("OnEnter", BarOnEnter)
		self.Bar7:SetScript("OnLeave", BarOnLeave)

		for i = 1, #self.Bar7 do
			self.Bar7[i].cooldown:SetDrawBling(false)
		end
	end

	self:PositionButtons(self.Bar7, Settings["ab-bar7-button-max"], Settings["ab-bar7-per-row"], Settings["ab-bar7-button-size"], Settings["ab-bar7-button-gap"])

	if Settings["ab-bar7-enable"] then
		self:EnableBar(self.Bar7)
	else
		self:DisableBar(self.Bar7)
	end
end

-- Bar 8
function AB:CreateBar8()
	self.Bar8 = CreateFrame("Frame", "HydraUI Action Bar 8", HydraUI.UIParent, "SecureHandlerStateTemplate")
	self.Bar8:SetPoint("RIGHT", self.Bar7, "LEFT", -Settings["ab-bar8-button-gap"], 0)
	self.Bar8:SetAlpha(Settings["ab-bar8-alpha"] / 100)
	self.Bar8.ButtonParent = MultiBar7
	self.Bar8.ShouldFade = Settings["ab-bar8-hover"]
	self.Bar8.MaxAlpha = Settings["ab-bar8-alpha"]

	self.Bar8.Fader = LibMotion:CreateAnimation(self.Bar8, "Fade")
	self.Bar8.Fader:SetDuration(0.15)
	self.Bar8.Fader:SetEasing("inout")

	MultiBar7:SetParent(self.Bar8)

	for i = 1, 12 do
		local Button = _G["MultiBar7Button" .. i]

		self:StyleActionButton(Button)

		Button.ParentBar = self.Bar8

		Button:HookScript("OnEnter", BarButtonOnEnter)
		Button:HookScript("OnLeave", BarButtonOnLeave)

		self.Bar8[i] = Button
	end

	if Settings["ab-bar8-hover"] then
		self.Bar8:SetAlpha(0)
		self.Bar8:SetScript("OnEnter", BarOnEnter)
		self.Bar8:SetScript("OnLeave", BarOnLeave)

		for i = 1, #self.Bar8 do
			self.Bar8[i].cooldown:SetDrawBling(false)
		end
	end

	self:PositionButtons(self.Bar8, Settings["ab-bar8-button-max"], Settings["ab-bar8-per-row"], Settings["ab-bar8-button-size"], Settings["ab-bar8-button-gap"])

	if Settings["ab-bar8-enable"] then
		self:EnableBar(self.Bar8)
	else
		self:DisableBar(self.Bar8)
	end
end

local PetBarUpdateGridLayout = function()
	if (not AB.PetBar:IsShown() or InCombatLockdown()) then
		return
	end

	AB:PositionButtons(AB.PetBar, NUM_PET_ACTION_SLOTS, Settings["ab-pet-per-row"], Settings["ab-pet-button-size"], Settings["ab-pet-button-gap"])
end

-- Pet
function AB:CreatePetBar()
	self.PetBar = CreateFrame("Frame", "HydraUI Pet Bar", HydraUI.UIParent, "SecureHandlerStateTemplate")
	self.PetBar:SetPoint("RIGHT", self.Bar5, "LEFT", -Settings["ab-pet-button-gap"], 0)
	self.PetBar:SetAlpha(Settings["ab-pet-alpha"] / 100)
	self.PetBar.ButtonParent = PetActionBar or PetActionBarFrame
	self.PetBar.ShouldFade = Settings["ab-pet-hover"]
	self.PetBar.MaxAlpha = Settings["ab-pet-alpha"]

	self.PetBar.Fader = LibMotion:CreateAnimation(self.PetBar, "Fade")
	self.PetBar.Fader:SetDuration(0.15)
	self.PetBar.Fader:SetEasing("inout")

	if PetActionBar then
		PetActionBar:SetParent(self.PetBar)

		hooksecurefunc(PetActionBar, "UpdateGridLayout", PetBarUpdateGridLayout)
	else
		PetActionBarFrame:SetParent(self.PetBar)

		for i = 1, PetActionBarFrame:GetNumRegions() do
			local Region = select(i, PetActionBarFrame:GetRegions())

			if Region.SetTexture then
				Region:SetTexture(nil)
			end
		end
	end

	for i = 1, NUM_PET_ACTION_SLOTS do
		local Button = _G["PetActionButton" .. i]

		self:StylePetActionButton(Button)

		Button.ParentBar = self.PetBar

		Button:HookScript("OnEnter", BarButtonOnEnter)
		Button:HookScript("OnLeave", BarButtonOnLeave)

		self.PetBar[i] = Button
	end

	if Settings["ab-pet-hover"] then
		self.PetBar:SetAlpha(0)
		self.PetBar:SetScript("OnEnter", BarOnEnter)
		self.PetBar:SetScript("OnLeave", BarOnLeave)

		for i = 1, #self.PetBar do
			self.PetBar[i].cooldown:SetDrawBling(false)
		end
	end

	self:PositionButtons(self.PetBar, NUM_PET_ACTION_SLOTS, Settings["ab-pet-per-row"], Settings["ab-pet-button-size"], Settings["ab-pet-button-gap"])

	if PetActionBar_Update then
		hooksecurefunc("PetActionBar_Update", AB.PetActionBar_Update)
	end

	if Settings["ab-pet-enable"] then
		self:EnableBar(self.PetBar)
	else
		self:DisableBar(self.PetBar)
	end
end

-- Stance
local StanceBarUpdateGridLayout = function()
	if InCombatLockdown() then
		return
	end

	AB:PositionButtons(AB.StanceBar, #AB.StanceBar, Settings["ab-stance-per-row"], Settings["ab-stance-button-size"], Settings["ab-stance-button-gap"])
end

function AB:CreateStanceBar()
	self.StanceBar = CreateFrame("Frame", "HydraUI Stance Bar", HydraUI.UIParent, "SecureHandlerStateTemplate")
	self.StanceBar:SetPoint("TOPLEFT", HydraUI.UIParent, 10, -10)
	self.StanceBar:SetAlpha(Settings["ab-stance-alpha"] / 100)
	self.StanceBar.ButtonParent = StanceBar or StanceBarFrame
	self.StanceBar.ShouldFade = Settings["ab-stance-hover"]
	self.StanceBar.MaxAlpha = Settings["ab-stance-alpha"]

	self.StanceBar.Fader = LibMotion:CreateAnimation(self.StanceBar, "Fade")
	self.StanceBar.Fader:SetDuration(0.15)
	self.StanceBar.Fader:SetEasing("inout")

	if StanceBar then
		StanceBar:SetParent(self.StanceBar)
	else
		StanceBarFrame:SetParent(self.StanceBar)
	end

	if StanceBar then
		if StanceBar.UpdateGridLayout then
			hooksecurefunc(StanceBar, "UpdateGridLayout", StanceBarUpdateGridLayout)
		end

		for i, button in next, StanceBar.actionButtons do
			self:StyleActionButton(button)

			button.ParentBar = self.StanceBar

			button:HookScript("OnEnter", BarButtonOnEnter)
			button:HookScript("OnLeave", BarButtonOnLeave)

			self.StanceBar[i] = button
		end

		self:PositionButtons(self.StanceBar, #self.StanceBar, Settings["ab-stance-per-row"], Settings["ab-stance-button-size"], Settings["ab-stance-button-gap"])

		--hooksecurefunc("StanceBar_UpdateState", self.StanceBar_UpdateState)

		if Settings["ab-stance-hover"] then
			self.StanceBar:SetAlpha(0)
			self.StanceBar:SetScript("OnEnter", BarOnEnter)
			self.StanceBar:SetScript("OnLeave", BarOnLeave)

			for i = 1, #self.StanceBar do
				self.StanceBar[i].cooldown:SetDrawBling(false)
			end
		end
	end

	if (StanceBarFrame and StanceBarFrame.StanceButtons) then
		StanceBarLeft:SetAlpha(0)
		StanceBarRight:SetAlpha(0)

		for i = 1, NUM_STANCE_SLOTS do
			local Button = StanceBarFrame.StanceButtons[i]

			self:StyleActionButton(Button)

			Button.ParentBar = self.StanceBar

			Button:HookScript("OnEnter", BarButtonOnEnter)
			Button:HookScript("OnLeave", BarButtonOnLeave)

			self.StanceBar[i] = Button
		end

		self:PositionButtons(self.StanceBar, #self.StanceBar, Settings["ab-stance-per-row"], Settings["ab-stance-button-size"], Settings["ab-stance-button-gap"])

		hooksecurefunc("StanceBar_UpdateState", self.StanceBar_UpdateState)

		if Settings["ab-stance-hover"] then
			self.StanceBar:SetAlpha(0)
			self.StanceBar:SetScript("OnEnter", BarOnEnter)
			self.StanceBar:SetScript("OnLeave", BarOnLeave)

			for i = 1, #self.StanceBar do
				self.StanceBar[i].cooldown:SetDrawBling(false)
			end
		end
	end

	if Settings["ab-stance-enable"] then
		self:EnableBar(self.StanceBar)
	else
		self:DisableBar(self.StanceBar)
	end
end

local UpdateZoneAbilityPosition = function(self, anchor, parent)
	--if (not InCombatLockdown()) and (parent and parent ~= AB.ExtraBar) then
	if (parent and parent ~= AB.ExtraBar) then
		self:ClearAllPoints()
		self:SetPoint("CENTER", AB.ExtraBar)
	end
end

local SkinZoneAbilityButtons = function()
	for Button in ZoneAbilityFrame.SpellButtonContainer:EnumerateActive() do
		if (not Button.Styled) then
			Button.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
			Button.NormalTexture:SetAlpha(0)

			Button.Backdrop = CreateFrame("Frame", nil, Button, "BackdropTemplate")
			Button.Backdrop:SetPoint("TOPLEFT", Button, -1, 1)
			Button.Backdrop:SetPoint("BOTTOMRIGHT", Button, 1, -1)
			Button.Backdrop:SetBackdrop(HydraUI.Backdrop)
			Button.Backdrop:SetBackdropColor(0, 0, 0)
			Button.Backdrop:SetFrameLevel(Button:GetFrameLevel() - 1)

			Button.Styled = true
		end
	end
end

local UpdateExtraActionParent = function(self, parent)
	if InCombatLockdown() then
		AB.NeedsCombatFix = true

		AB:RegisterEvent("PLAYER_REGEN_ENABLED")
		AB:SetScript("OnEvent", AB.OnEvent)

		return
	end

	if (parent and parent ~= AB.ExtraBar) then
		self:SetParent(AB.ExtraBar)
	end
end

-- Extra Bar
function AB:CreateExtraBar()
	self.ExtraBar = CreateFrame("Frame", "HydraUI Extra Action", HydraUI.UIParent, "SecureHandlerStateTemplate")
	self.ExtraBar:SetSize(Settings["ab-extra-button-size"], Settings["ab-extra-button-size"])
	self.ExtraBar:SetPoint("CENTER", HydraUI.UIParent, 0, -220)

	ExtraActionBarFrame:ClearAllPoints()
	ExtraActionBarFrame:SetAllPoints(self.ExtraBar)
	ExtraActionButton1.style:SetAlpha(0)
	ExtraActionBarFrame.ignoreInLayout = true

	--hooksecurefunc(ExtraActionBarFrame, "SetPoint", UpdateExtraActionPosition)
	hooksecurefunc(ExtraActionBarFrame, "SetParent", UpdateExtraActionParent)

	self:StyleActionButton(ExtraActionButton1)

	ZoneAbilityFrame:ClearAllPoints()
	ZoneAbilityFrame:SetPoint("CENTER", self.ExtraBar)
	ZoneAbilityFrame.Style:SetAlpha(0)
	--ZoneAbilityFrame.ignoreInLayout = true

	hooksecurefunc(ZoneAbilityFrame, "SetPoint", UpdateZoneAbilityPosition)
	hooksecurefunc(ZoneAbilityFrame, "UpdateDisplayedZoneAbilities", SkinZoneAbilityButtons)
end

function AB:OnEvent(event, ...)
	if self[event] then
		self[event](self, ...)
	end
end

function AB:PLAYER_REGEN_ENABLED()
	if self.NeedsCombatFix then
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
		self:SetScript("OnEvent", nil)

		ExtraActionBarFrame:SetParent(AB.ExtraBar)

		self.NeedsCombatFix = nil
	end
end

function AB:CreateBars()
	self:CreateBar1()
	self:CreateBar2()
	self:CreateBar3()
	self:CreateBar4()
	self:CreateBar5()

	if MultiBar5 then
		self:CreateBar6()
		self:CreateBar7()
		self:CreateBar8()
	end

	if (PetActionBar or PetActionBarFrame) then
		self:CreatePetBar()
	end

	if (StanceBar or StanceBarFrame) then
		self:CreateStanceBar()
	end

	if HydraUI.IsMainline then
		self:CreateExtraBar()
	end

	if (MultiCastActionBarFrame and MultiCastActionBarFrame.numActiveSlots and MultiCastActionBarFrame.numActiveSlots > 0) then
		self:StyleTotemBar()
		--MultiCastActionBarFrame:SetParent(UIParent)
		--MultiCastActionBarFrame:ClearAllPoints()
		--MultiCastActionBarFrame:SetPoint("BOTTOMLEFT", UIParent, 300, 20)
	end
end

-- Black magic, the movers won't budge if a secure frame is positioned on it
local Bar1PreMove = function(self)
	local A1, P, A2, X, Y = self:GetPoint()

	AB.Bar1:Hide()
	AB.Bar1:ClearAllPoints() -- Clear the bar from the mover
	AB.Bar1:SetPoint(A1, HydraUI.UIParent, A2, X, Y)
end

local Bar1PostMove = function(self)
	local A1, P, A2, X, Y = self:GetPoint()

	self:ClearAllPoints()

	AB.Bar1:ClearAllPoints()
	AB.Bar1:SetPoint("CENTER", self, 0, 0) -- Position the frame to the mover again
	AB.Bar1:Show()

	self:SetPoint(A1, HydraUI.UIParent, A2, X, Y)
end

function AB:CreateMovers()
	self.Bar1Mover = HydraUI:CreateMover(self.Bar1)
	HydraUI:CreateMover(self.Bar2)
	HydraUI:CreateMover(self.Bar3)
	HydraUI:CreateMover(self.Bar4)
	HydraUI:CreateMover(self.Bar5)

	if self.Bar6 then
		HydraUI:CreateMover(self.Bar6)
		HydraUI:CreateMover(self.Bar7)
		HydraUI:CreateMover(self.Bar8)
	end

	if self.StanceBar then
		HydraUI:CreateMover(self.StanceBar)
	end

	if self.PetBar then
		HydraUI:CreateMover(self.PetBar)
	end

	if self.TotemBar then
		HydraUI:CreateMover(self.TotemBar)
	end

	if HydraUI.IsMainline then
		self.ExtraBarMover = HydraUI:CreateMover(self.ExtraBar)
	end

	self.Bar1Mover.PreMove = Bar1PreMove
	self.Bar1Mover.PostMove = Bar1PostMove
end

function AB:SetCVars()
	C_CVar.SetCVar("showgrid", 1)
end

function AB:UpdateFlyout()
	if (not self.FlyoutArrow) then
		return
	end

	if (SpellFlyout and SpellFlyout:IsShown()) then
		SpellFlyout.BgEnd:SetTexture()
		SpellFlyout.HorizBg:SetTexture()
		SpellFlyout.VertBg:SetTexture()
	end

	if self.FlyoutBorder then
		self.FlyoutBorder:SetTexture()
		self.FlyoutBorderShadow:SetTexture()
	end

	for i = 1, 8 do
		local Button = _G["SpellFlyoutButton" .. i]

		if Button then
			AB:StylePetActionButton(Button)

			if Button.GlyphIcon then
				Button.GlyphIcon:ClearAllPoints()
				Button.GlyphIcon:SetPoint("TOPRIGHT", Button, 2, 2)
			end
		end
	end
end

function AB:UpdateEmptyButtons()
	if Settings["ab-show-empty"] then
		for i = 1, #ActionBars do
			for j = 1, 12 do
				local Button = _G[ActionBars[i] .. j]

				if Button then
					if Button.ShowGrid then
						Button:ShowGrid(ACTION_BUTTON_SHOW_GRID_REASON_EVENT)
					end

					if HydraUI.IsMainline then
						Button:SetAttribute("showgrid", 1)
					else
						Button:SetAttribute("showgrid", 2)
						ActionButton_ShowGrid(Button)
					end
				end
			end
		end
	else
		for i = 1, #ActionBars do
			for j = 1, 12 do
				local Button = _G[ActionBars[i] .. j]

				if Button then
					Button:SetAttribute("showgrid", 0)

					if Button.HideGrid then
						Button:HideGrid(ACTION_BUTTON_SHOW_GRID_REASON_EVENT)
					end
				end
			end
		end
	end
end

local MultiCastSummonSpellButton_Update = function()
	for i = 1, 12 do
		local Slot = _G["MultiCastSlotButton"..i]
		local Button = _G["MultiCastActionButton"..i]
		--self:StyleActionButton(Button)
		Button:ClearAllPoints()

		if (i == 1 or i == 5 or i == 9) then
			Button:SetPoint("LEFT", MultiCastSummonSpellButton, "RIGHT", 2, 0)
		else
			Button:SetPoint("LEFT", _G["MultiCastActionButton"..i-1], "RIGHT", 2, 0)
		end
	end
end
local MultiCastRecallSpellButton_Update = function()
	MultiCastRecallSpellButton:ClearAllPoints()
	MultiCastRecallSpellButton:SetPoint("LEFT", MultiCastActionButton4, "RIGHT", 2, 0)
end

local MultiCastFlyoutFrame_LoadSlotSpells = function(parent, slotid)
	local FlyoutButton

	for i = 1, 8 do
		FlyoutButton = _G["MultiCastFlyoutButton" .. i]

		if (not FlyoutButton) then
			return
		end

		FlyoutButton:SetNormalTexture("")

		if FlyoutButton.Border then
			FlyoutButton.Border:SetTexture(nil)
		end

		if (FlyoutButton.icon and i ~= 1) then
			FlyoutButton.icon:ClearAllPoints()
			FlyoutButton.icon:SetPoint("TOPLEFT", FlyoutButton, 0, 0)
			FlyoutButton.icon:SetPoint("BOTTOMRIGHT", FlyoutButton, 0, 0)
			FlyoutButton.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		end

		if _G[FlyoutButton:GetName() .. "FloatingBG"] then
			self:Disable(_G[FlyoutButton:GetName() .. "FloatingBG"])
		end

		FlyoutButton.Backdrop = CreateFrame("Frame", nil, FlyoutButton, "BackdropTemplate")
		FlyoutButton.Backdrop:SetPoint("TOPLEFT", FlyoutButton, -1, 1)
		FlyoutButton.Backdrop:SetPoint("BOTTOMRIGHT", FlyoutButton, 1, -1)
		FlyoutButton.Backdrop:SetBackdrop(HydraUI.Backdrop)
		FlyoutButton.Backdrop:SetBackdropColor(0, 0, 0)
		FlyoutButton.Backdrop:SetFrameLevel(FlyoutButton:GetFrameLevel() - 1)

		FlyoutButton.Backdrop.Texture = FlyoutButton.Backdrop:CreateTexture(nil, "BACKGROUND")
		FlyoutButton.Backdrop.Texture:SetPoint("TOPLEFT", FlyoutButton.Backdrop, 1, -1)
		FlyoutButton.Backdrop.Texture:SetPoint("BOTTOMRIGHT", FlyoutButton.Backdrop, -1, 1)
		FlyoutButton.Backdrop.Texture:SetTexture(Assets:GetTexture(Settings["ui-header-texture"]))
		FlyoutButton.Backdrop.Texture:SetVertexColor(HydraUI:HexToRGB(Settings["ui-window-main-color"]))

		local Highlight = FlyoutButton:GetHighlightTexture()
		Highlight:SetTexture(Assets:GetTexture(Settings["action-bars-button-highlight"]))
		Highlight:SetColorTexture(1, 1, 1, 0.2)
		Highlight:SetPoint("TOPLEFT", FlyoutButton, 0, 0)
		Highlight:SetPoint("BOTTOMRIGHT", FlyoutButton, 0, 0)

		FlyoutButton:ClearAllPoints()

		if (i == 1) then
			FlyoutButton:SetPoint("BOTTOM", MultiCastFlyoutFrame, 0, 3)
		else
			FlyoutButton:SetPoint("BOTTOM", _G["MultiCastFlyoutButton" .. i-1], "TOP", 0, 4)
		end

		MultiCastFlyoutFrameCloseButton:ClearAllPoints()
		MultiCastFlyoutFrameCloseButton:SetPoint("BOTTOM", MultiCastFlyoutFrame, "TOP", 0, -8)
	end
	hooksecurefunc("MultiCastSummonSpellButton_Update", MultiCastSummonSpellButton_Update)
	hooksecurefunc("MultiCastFlyoutFrame_LoadSlotSpells", MultiCastFlyoutFrame_LoadSlotSpells)
end

function AB:StyleTotemBar()
	self.TotemBar = CreateFrame("Frame", "HydraUI Totem Bar", HydraUI.UIParent, "SecureHandlerStateTemplate")
	self.TotemBar:SetPoint("BOTTOMLEFT", HydraUI.UIParent, 408, 13)
	self.TotemBar:SetSize((30 * 6) + (2 * 5), 30)

	MultiCastActionBarFrame:SetParent(self.TotemBar)
	MultiCastSummonSpellButton:SetParent(self.TotemBar)
	MultiCastSummonSpellButton:ClearAllPoints()
	MultiCastSummonSpellButton:SetPoint("LEFT", self.TotemBar, 0, 0)

	self:StyleActionButton(MultiCastSummonSpellButton)

	MultiCastSummonSpellButtonHighlight:SetTexture(nil)

	for i = 1, 4 do
		local Slot = _G["MultiCastSlotButton"..i]

		Slot:SetParent(MultiCastActionBarFrame)

		Slot.background:ClearAllPoints()
		Slot.background:SetPoint("TOPLEFT", Slot, 1, -1)
		Slot.background:SetPoint("BOTTOMRIGHT", Slot, -1, 1)
		Slot.background:SetDrawLayer("BACKGROUND", -1)
		Slot.overlayTex:SetTexture(nil) -- Colored border

		Slot:ClearAllPoints()

		if (i == 1) then
			Slot:SetPoint("LEFT", MultiCastSummonSpellButton, "RIGHT", 2, 0)
		else
			Slot:SetPoint("LEFT", _G["MultiCastSlotButton"..i-1], "RIGHT", 2, 0)
		end
	end

	for i = 1, 12 do
		local Button = _G["MultiCastActionButton"..i]

		self:StyleActionButton(Button)

		--Button:SetParent(MultiCastActionBarFrame)
		Button:ClearAllPoints()
		Button.overlayTex:SetTexture(nil)

		--Button.Backdrop:SetFrameStrata("BACKGROUND")

		--Button:ClearAllPoints()

		if (i == 1 or i == 5 or i == 9) then
			Button:SetPoint("LEFT", MultiCastSummonSpellButton, "RIGHT", 2, 0)
		else
			Button:SetPoint("LEFT", _G["MultiCastActionButton"..i-1], "RIGHT", 2, 0)
		end
	end

	MultiCastRecallSpellButton:SetParent(self.TotemBar)
	self:StyleActionButton(MultiCastRecallSpellButton)
	MultiCastRecallSpellButton:ClearAllPoints()
	MultiCastRecallSpellButton:SetPoint("LEFT", MultiCastSlotButton4, "RIGHT", 2, 0)

	MultiCastRecallSpellButtonHighlight:SetTexture(nil)

	MultiCastFlyoutFrame.top:SetTexture(nil)
	MultiCastFlyoutFrame.middle:SetTexture(nil)

	hooksecurefunc("MultiCastSummonSpellButton_Update", MultiCastSummonSpellButton_Update)
	hooksecurefunc("MultiCastRecallSpellButton_Update", MultiCastRecallSpellButton_Update)
	hooksecurefunc("MultiCastFlyoutFrame_LoadSlotSpells", MultiCastFlyoutFrame_LoadSlotSpells)
	if Settings["ab-totem-enable"] then
		self:EnableBar(self.TotemBar)
	else
		self:DisableBar(self.TotemBar)
	end
end

local GetBarHeight = function()
	return 0
end

function AB:Load()
	if (not Settings["ab-enable"]) then
		return
	end

	self.Hide = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
	self.Hide:Hide()

	SetActionBarToggles(1, 1, 1, 1, 1, 1, 1, 1)

	self:SetCVars()
	self:Disable(MainMenuBar)
	self:CreateBars()
	self:CreateMovers()
	self:UpdateEmptyButtons()

	if HydraUI.IsMainline then
		MainMenuBar.GetBottomAnchoredHeight = GetBarHeight
		OverrideActionBar.GetBottomAnchoredHeight = GetBarHeight
		MultiBarBottomLeft.GetBottomAnchoredHeight = GetBarHeight
		MultiBarBottomRight.GetBottomAnchoredHeight = GetBarHeight
		StanceBar.GetBottomAnchoredHeight = GetBarHeight
		PetActionBar.GetBottomAnchoredHeight = GetBarHeight
		PossessActionBar.GetBottomAnchoredHeight = GetBarHeight
		MainMenuBarVehicleLeaveButton.GetBottomAnchoredHeight = GetBarHeight

		MultiBarLeft.IsInDefaultPosition = function() return false end
		MultiBarRight.IsInDefaultPosition = function() return false end

		if EditModeManagerFrame then
			EditModeManagerFrame.UpdateBottomActionBarPositions = function() end
			EditModeManagerFrame.UpdateRightActionBarPositions = function() end
		end
	end

	hooksecurefunc("ActionButton_UpdateRangeIndicator", AB.UpdateButtonStatus)

	if ActionButton_UpdateFlyout then
		hooksecurefunc("ActionButton_UpdateFlyout", AB.UpdateFlyout)
	end

	if ActionButton_Update then
		hooksecurefunc("ActionButton_Update", AB.UpdateButtonStatus)
	end
end

local UpdateBar1 = function()
	AB:PositionButtons(AB.Bar1, Settings["ab-bar1-button-max"], Settings["ab-bar1-per-row"], Settings["ab-bar1-button-size"], Settings["ab-bar1-button-gap"])
end

local UpdateBar2 = function()
	AB:PositionButtons(AB.Bar2, Settings["ab-bar2-button-max"], Settings["ab-bar2-per-row"], Settings["ab-bar2-button-size"], Settings["ab-bar2-button-gap"])
end

local UpdateBar3 = function()
	AB:PositionButtons(AB.Bar3, Settings["ab-bar3-button-max"], Settings["ab-bar3-per-row"], Settings["ab-bar3-button-size"], Settings["ab-bar3-button-gap"])
end

local UpdateBar4 = function()
	AB:PositionButtons(AB.Bar4, Settings["ab-bar4-button-max"], Settings["ab-bar4-per-row"], Settings["ab-bar4-button-size"], Settings["ab-bar4-button-gap"])
end

local UpdateBar5 = function()
	AB:PositionButtons(AB.Bar5, Settings["ab-bar5-button-max"], Settings["ab-bar5-per-row"], Settings["ab-bar5-button-size"], Settings["ab-bar5-button-gap"])
end

local UpdateBar6 = function()
	AB:PositionButtons(AB.Bar6, Settings["ab-bar6-button-max"], Settings["ab-bar6-per-row"], Settings["ab-bar6-button-size"], Settings["ab-bar6-button-gap"])
end

local UpdateBar7 = function()
	AB:PositionButtons(AB.Bar7, Settings["ab-bar7-button-max"], Settings["ab-bar7-per-row"], Settings["ab-bar7-button-size"], Settings["ab-bar7-button-gap"])
end

local UpdateBar8 = function()
	AB:PositionButtons(AB.Bar8, Settings["ab-bar8-button-max"], Settings["ab-bar8-per-row"], Settings["ab-bar8-button-size"], Settings["ab-bar8-button-gap"])
end

local UpdatePetBar = function()
	AB:PositionButtons(AB.PetBar, NUM_PET_ACTION_SLOTS, Settings["ab-pet-per-row"], Settings["ab-pet-button-size"], Settings["ab-pet-button-gap"])

	for i = 1, #AB.PetBar do
		local Name = AB.PetBar[i]:GetName()

		if _G[Name .. "AutoCastable"] then
			_G[Name .. "AutoCastable"]:SetSize(Settings["ab-pet-button-size"] * 2 - 4, Settings["ab-pet-button-size"] * 2 - 4)
		end
	end
end

local UpdateStanceBar = function()
	AB:PositionButtons(AB.StanceBar, #AB.StanceBar, Settings["ab-stance-per-row"], Settings["ab-stance-button-size"], Settings["ab-stance-button-gap"])
end

local UpdateEnableBar1 = function(value)
	if value then
		AB:EnableBar(AB.Bar1)
	else
		AB:DisableBar(AB.Bar1)
	end
end

local UpdateEnableBar2 = function(value)
	if value then
		AB:EnableBar(AB.Bar2)
	else
		AB:DisableBar(AB.Bar2)
	end
end

local UpdateEnableBar3 = function(value)
	if value then
		AB:EnableBar(AB.Bar3)
	else
		AB:DisableBar(AB.Bar3)
	end
end

local UpdateEnableBar4 = function(value)
	if value then
		AB:EnableBar(AB.Bar4)
	else
		AB:DisableBar(AB.Bar4)
	end
end

local UpdateEnableBar5 = function(value)
	if value then
		AB:EnableBar(AB.Bar5)
	else
		AB:DisableBar(AB.Bar5)
	end
end

local UpdateEnableBar6 = function(value)
	if value then
		AB:EnableBar(AB.Bar6)
	else
		AB:DisableBar(AB.Bar6)
	end
end

local UpdateEnableBar7 = function(value)
	if value then
		AB:EnableBar(AB.Bar7)
	else
		AB:DisableBar(AB.Bar7)
	end
end

local UpdateEnableBar8 = function(value)
	if value then
		AB:EnableBar(AB.Bar8)
	else
		AB:DisableBar(AB.Bar8)
	end
end

local UpdateEnablePetBar = function(value)
	if value then
		AB:EnableBar(AB.PetBar)
	else
		AB:DisableBar(AB.PetBar)
	end
end

local UpdateEnableStanceBar = function(value)
	if value then
		AB:EnableBar(AB.StanceBar)
	else
		AB:DisableBar(AB.StanceBar)
	end
end

local UpdateEnableTotemBar = function(value)
	if value then
		AB:EnableBar(AB.TotemBar)
	else
		AB:DisableBar(AB.TotemBar)
	end
end

local UpdateShowHotKey = function(value)
	if value then
		for i = 1, 12 do
			AB.Bar1[i].HotKey:SetAlpha(1)
			AB.Bar2[i].HotKey:SetAlpha(1)
			AB.Bar3[i].HotKey:SetAlpha(1)
			AB.Bar4[i].HotKey:SetAlpha(1)
			AB.Bar5[i].HotKey:SetAlpha(1)

			if AB.Bar6 then
				AB.Bar6[i].HotKey:SetAlpha(1)
				AB.Bar7[i].HotKey:SetAlpha(1)
				AB.Bar8[i].HotKey:SetAlpha(1)
			end

			if AB.PetBar[i] then
				AB.PetBar[i].HotKey:SetAlpha(1)
			end

			if AB.StanceBar[i] then
				AB.StanceBar[i].HotKey:SetAlpha(1)
			end
		end

		if ExtraActionButton1 then
			ExtraActionButton1.HotKey:SetAlpha(1)
		end
	else
		for i = 1, 12 do
			AB.Bar1[i].HotKey:SetAlpha(0)
			AB.Bar2[i].HotKey:SetAlpha(0)
			AB.Bar3[i].HotKey:SetAlpha(0)
			AB.Bar4[i].HotKey:SetAlpha(0)
			AB.Bar5[i].HotKey:SetAlpha(0)

			if AB.Bar6 then
				AB.Bar6[i].HotKey:SetAlpha(1)
				AB.Bar7[i].HotKey:SetAlpha(1)
				AB.Bar8[i].HotKey:SetAlpha(1)
			end

			if AB.PetBar[i] then
				AB.PetBar[i].HotKey:SetAlpha(0)
			end

			if AB.StanceBar[i] then
				AB.StanceBar[i].HotKey:SetAlpha(0)
			end
		end

		if ExtraActionButton1 then
			ExtraActionButton1.HotKey:SetAlpha(0)
		end
	end
end

local UpdateShowMacroName = function(value)
	if value then
		for i = 1, 12 do
			AB.Bar1[i].Name:SetAlpha(1)
			AB.Bar2[i].Name:SetAlpha(1)
			AB.Bar3[i].Name:SetAlpha(1)
			AB.Bar4[i].Name:SetAlpha(1)
			AB.Bar5[i].Name:SetAlpha(1)

			if AB.Bar6 then
				AB.Bar6[i].HotKey:SetAlpha(1)
				AB.Bar7[i].HotKey:SetAlpha(1)
				AB.Bar8[i].HotKey:SetAlpha(1)
			end
		end
	else
		for i = 1, 12 do
			AB.Bar1[i].Name:SetAlpha(0)
			AB.Bar2[i].Name:SetAlpha(0)
			AB.Bar3[i].Name:SetAlpha(0)
			AB.Bar4[i].Name:SetAlpha(0)
			AB.Bar5[i].Name:SetAlpha(0)

			if AB.Bar6 then
				AB.Bar6[i].HotKey:SetAlpha(1)
				AB.Bar7[i].HotKey:SetAlpha(1)
				AB.Bar8[i].HotKey:SetAlpha(1)
			end
		end
	end
end

local UpdateShowCount = function(value)
	if value then
		for i = 1, 12 do
			AB.Bar1[i].Count:SetAlpha(1)
			AB.Bar2[i].Count:SetAlpha(1)
			AB.Bar3[i].Count:SetAlpha(1)
			AB.Bar4[i].Count:SetAlpha(1)
			AB.Bar5[i].Count:SetAlpha(1)

			if AB.Bar6 then
				AB.Bar6[i].HotKey:SetAlpha(1)
				AB.Bar7[i].HotKey:SetAlpha(1)
				AB.Bar8[i].HotKey:SetAlpha(1)
			end
		end
	else
		for i = 1, 12 do
			AB.Bar1[i].Count:SetAlpha(0)
			AB.Bar2[i].Count:SetAlpha(0)
			AB.Bar3[i].Count:SetAlpha(0)
			AB.Bar4[i].Count:SetAlpha(0)
			AB.Bar5[i].Count:SetAlpha(0)

			if AB.Bar6 then
				AB.Bar6[i].HotKey:SetAlpha(1)
				AB.Bar7[i].HotKey:SetAlpha(1)
				AB.Bar8[i].HotKey:SetAlpha(1)
			end
		end
	end
end

function AB:UpdateButtonFont(button)
	if button.HotKey then
		HydraUI:SetFontInfo(button.HotKey, Settings["ab-font"], Settings["ab-font-size"], Settings["ab-font-flags"])
	end

	if button.Name then
		HydraUI:SetFontInfo(button.Name, Settings["ab-font"], Settings["ab-font-size"], Settings["ab-font-flags"])
	end

	if button.Count then
		HydraUI:SetFontInfo(button.Count, Settings["ab-font"], Settings["ab-font-size"], Settings["ab-font-flags"])
	end

	if button.cooldown then
		local Cooldown = button.cooldown:GetRegions()

		if Cooldown then
			HydraUI:SetFontInfo(Cooldown, Settings["ab-font"], Settings["ab-cd-size"], Settings["ab-font-flags"])
		end
	end
end

local UpdateActionBarFont = function()
	for i = 1, 12 do
		AB:UpdateButtonFont(AB.Bar1[i])
		AB:UpdateButtonFont(AB.Bar2[i])
		AB:UpdateButtonFont(AB.Bar3[i])
		AB:UpdateButtonFont(AB.Bar4[i])
		AB:UpdateButtonFont(AB.Bar5[i])

		if AB.Bar6 then
			AB:UpdateButtonFont(AB.Bar6[i])
			AB:UpdateButtonFont(AB.Bar7[i])
			AB:UpdateButtonFont(AB.Bar8[i])
		end

		if AB.PetBar[i] then
			AB:UpdateButtonFont(AB.PetBar[i])
		end

		if AB.StanceBar[i] then
			AB:UpdateButtonFont(AB.StanceBar[i])
		end
	end
end

local UpdateBar1Hover = function(value)
	AB.Bar1.ShouldFade = value

	if value then
		AB.Bar1:SetAlpha(0)
		AB.Bar1:SetScript("OnEnter", BarOnEnter)
		AB.Bar1:SetScript("OnLeave", BarOnLeave)

		for i = 1, #AB.Bar1 do
			AB.Bar1[i].cooldown:SetDrawBling(false)
		end
	else
		AB.Bar1:SetAlpha(1)
		AB.Bar1:SetScript("OnEnter", nil)
		AB.Bar1:SetScript("OnLeave", nil)

		for i = 1, #AB.Bar1 do
			AB.Bar1[i].cooldown:SetDrawBling(true)
		end
	end
end

local UpdateBar2Hover = function(value)
	AB.Bar2.ShouldFade = value

	if value then
		AB.Bar2:SetAlpha(0)
		AB.Bar2:SetScript("OnEnter", BarOnEnter)
		AB.Bar2:SetScript("OnLeave", BarOnLeave)

		for i = 1, #AB.Bar2 do
			AB.Bar2[i].cooldown:SetDrawBling(false)
		end
	else
		AB.Bar2:SetAlpha(1)
		AB.Bar2:SetScript("OnEnter", nil)
		AB.Bar2:SetScript("OnLeave", nil)

		for i = 1, #AB.Bar2 do
			AB.Bar2[i].cooldown:SetDrawBling(true)
		end
	end
end

local UpdateBar3Hover = function(value)
	AB.Bar3.ShouldFade = value

	if value then
		AB.Bar3:SetAlpha(0)
		AB.Bar3:SetScript("OnEnter", BarOnEnter)
		AB.Bar3:SetScript("OnLeave", BarOnLeave)

		for i = 1, #AB.Bar3 do
			AB.Bar3[i].cooldown:SetDrawBling(false)
		end
	else
		AB.Bar3:SetAlpha(1)
		AB.Bar3:SetScript("OnEnter", nil)
		AB.Bar3:SetScript("OnLeave", nil)

		for i = 1, #AB.Bar3 do
			AB.Bar3[i].cooldown:SetDrawBling(true)
		end
	end
end

local UpdateBar4Hover = function(value)
	AB.Bar4.ShouldFade = value

	if value then
		AB.Bar4:SetAlpha(0)
		AB.Bar4:SetScript("OnEnter", BarOnEnter)
		AB.Bar4:SetScript("OnLeave", BarOnLeave)

		for i = 1, #AB.Bar4 do
			AB.Bar4[i].cooldown:SetDrawBling(false)
		end
	else
		AB.Bar4:SetAlpha(1)
		AB.Bar4:SetScript("OnEnter", nil)

		for i = 1, #AB.Bar4 do
			AB.Bar4[i].cooldown:SetDrawBling(true)
		end
	end
end

local UpdateBar5Hover = function(value)
	AB.Bar5.ShouldFade = value

	if value then
		AB.Bar5:SetAlpha(0)
		AB.Bar5:SetScript("OnEnter", BarOnEnter)
		AB.Bar5:SetScript("OnLeave", BarOnLeave)

		for i = 1, #AB.Bar5 do
			AB.Bar5[i].cooldown:SetDrawBling(false)
		end
	else
		AB.Bar5:SetAlpha(1)
		AB.Bar5:SetScript("OnEnter", nil)
		AB.Bar5:SetScript("OnLeave", nil)

		for i = 1, #AB.Bar5 do
			AB.Bar5[i].cooldown:SetDrawBling(true)
		end
	end
end

local UpdateBar6Hover = function(value)
	AB.Bar6.ShouldFade = value

	if value then
		AB.Bar6:SetAlpha(0)
		AB.Bar6:SetScript("OnEnter", BarOnEnter)
		AB.Bar6:SetScript("OnLeave", BarOnLeave)

		for i = 1, #AB.Bar6 do
			AB.Bar6[i].cooldown:SetDrawBling(false)
		end
	else
		AB.Bar6:SetAlpha(1)
		AB.Bar6:SetScript("OnEnter", nil)
		AB.Bar6:SetScript("OnLeave", nil)

		for i = 1, #AB.Bar6 do
			AB.Bar6[i].cooldown:SetDrawBling(true)
		end
	end
end

local UpdateBar7Hover = function(value)
	AB.Bar7.ShouldFade = value

	if value then
		AB.Bar7:SetAlpha(0)
		AB.Bar7:SetScript("OnEnter", BarOnEnter)
		AB.Bar7:SetScript("OnLeave", BarOnLeave)

		for i = 1, #AB.Bar7 do
			AB.Bar7[i].cooldown:SetDrawBling(false)
		end
	else
		AB.Bar7:SetAlpha(1)
		AB.Bar7:SetScript("OnEnter", nil)
		AB.Bar7:SetScript("OnLeave", nil)

		for i = 1, #AB.Bar7 do
			AB.Bar7[i].cooldown:SetDrawBling(true)
		end
	end
end

local UpdateBar8Hover = function(value)
	AB.Bar8.ShouldFade = value

	if value then
		AB.Bar8:SetAlpha(0)
		AB.Bar8:SetScript("OnEnter", BarOnEnter)
		AB.Bar8:SetScript("OnLeave", BarOnLeave)

		for i = 1, #AB.Bar8 do
			AB.Bar8[i].cooldown:SetDrawBling(false)
		end
	else
		AB.Bar8:SetAlpha(1)
		AB.Bar8:SetScript("OnEnter", nil)
		AB.Bar8:SetScript("OnLeave", nil)

		for i = 1, #AB.Bar8 do
			AB.Bar8[i].cooldown:SetDrawBling(true)
		end
	end
end

local UpdatePetHover = function(value)
	AB.PetBar.ShouldFade = value

	if value then
		AB.PetBar:SetAlpha(0)
		AB.PetBar:SetScript("OnEnter", BarOnEnter)
		AB.PetBar:SetScript("OnLeave", BarOnLeave)

		for i = 1, #AB.PetBar do
			AB.PetBar[i].cooldown:SetDrawBling(false)
		end
	else
		AB.PetBar:SetAlpha(1)
		AB.PetBar:SetScript("OnEnter", nil)
		AB.PetBar:SetScript("OnLeave", nil)

		for i = 1, #AB.PetBar do
			AB.PetBar[i].cooldown:SetDrawBling(true)
		end
	end
end

local UpdateStanceHover = function(value)
	AB.StanceBar.ShouldFade = value

	if value then
		AB.StanceBar:SetAlpha(0)
		AB.StanceBar:SetScript("OnEnter", BarOnEnter)
		AB.StanceBar:SetScript("OnLeave", BarOnLeave)

		for i = 1, #AB.StanceBar do
			AB.StanceBar[i].cooldown:SetDrawBling(false)
		end
	else
		AB.StanceBar:SetAlpha(1)
		AB.StanceBar:SetScript("OnEnter", nil)
		AB.StanceBar:SetScript("OnLeave", nil)

		for i = 1, #AB.StanceBar do
			AB.StanceBar[i].cooldown:SetDrawBling(true)
		end
	end
end

local UpdateEmptyButtons = function()
	AB:UpdateEmptyButtons()
end

local UpdateBar1Alpha = function(value)
	AB.Bar1.MaxAlpha = value
	AB.Bar1:SetAlpha(value / 100)
end

local UpdateBar2Alpha = function(value)
	AB.Bar2.MaxAlpha = value
	AB.Bar2:SetAlpha(value / 100)
end

local UpdateBar3Alpha = function(value)
	AB.Bar3.MaxAlpha = value
	AB.Bar3:SetAlpha(value / 100)
end

local UpdateBar4Alpha = function(value)
	AB.Bar4.MaxAlpha = value
	AB.Bar4:SetAlpha(value / 100)
end

local UpdateBar5Alpha = function(value)
	AB.Bar5.MaxAlpha = value
	AB.Bar5:SetAlpha(value / 100)
end

local UpdateBar6Alpha = function(value)
	AB.Bar6.MaxAlpha = value
	AB.Bar6:SetAlpha(value / 100)
end

local UpdateBar7Alpha = function(value)
	AB.Bar7.MaxAlpha = value
	AB.Bar7:SetAlpha(value / 100)
end

local UpdateBar8Alpha = function(value)
	AB.Bar8.MaxAlpha = value
	AB.Bar8:SetAlpha(value / 100)
end

local UpdatePetBarAlpha = function(value)
	AB.PetBar.MaxAlpha = value
	AB.PetBar:SetAlpha(value / 100)
end

local UpdateStanceBarAlpha = function(value)
	AB.StanceBar.MaxAlpha = value
	AB.StanceBar:SetAlpha(value / 100)
end

GUI:AddWidgets(Language["General"], Language["Action Bars"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("ab-enable", Settings["ab-enable"], Language["Enable Action Bar"], Language["Enable action bars module"], ReloadUI):RequiresReload(true)

	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("ab-show-hotkey", Settings["ab-show-hotkey"], Language["Show Hotkeys"], Language["Display hotkey text on action buttons"], UpdateShowHotKey)
	left:CreateSwitch("ab-show-macro", Settings["ab-show-macro"], Language["Show Macro Names"], Language["Display macro name text on action buttons"], UpdateShowMacroName)
	left:CreateSwitch("ab-show-count", Settings["ab-show-count"], Language["Show Count Text"], Language["Display count text on action buttons"], UpdateShowCount)

	left:CreateHeader(Language["Font"])
	left:CreateDropdown("ab-font", Settings["ab-font"], Assets:GetFontList(), Language["Font"], Language["Set the font of the action bar buttons"], UpdateActionBarFont, "Font")
	left:CreateSlider("ab-font-size", Settings["ab-font-size"], 8, 42, 1, Language["Font Size"], Language["Set the font size of the action bar buttons"], UpdateActionBarFont)
	left:CreateSlider("ab-cd-size", Settings["ab-cd-size"], 8, 42, 1, Language["Cooldown Font Size"], Language["Set the font size of the action bar cooldowns"], UpdateActionBarFont)
	left:CreateDropdown("ab-font-flags", Settings["ab-font-flags"], Assets:GetFlagsList(), Language["Font Flags"], Language["Set the font flags of the action bar buttons"], UpdateActionBarFont)
end)

GUI:AddWidgets(Language["General"], Language["Bar 1"], Language["Action Bars"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("ab-bar1-enable", Settings["ab-bar1-enable"], Language["Enable Bar"], Language["Enable action bar 1"], UpdateEnableBar1)

	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("ab-bar1-hover", Settings["ab-bar1-hover"], Language["Set Mouseover"], Language["Only display the bar while hovering over it"], UpdateBar1Hover)
	left:CreateSlider("ab-bar1-alpha", Settings["ab-bar1-alpha"], 0, 100, 5, Language["Bar Opacity"], Language["Set the opacity of the action bar"], UpdateBar1Alpha)

	right:CreateHeader(Language["Buttons"])
	right:CreateSlider("ab-bar1-per-row", Settings["ab-bar1-per-row"], 1, 12, 1, Language["Buttons Per Row"], Language["Set the number of buttons per row"], UpdateBar1)
	right:CreateSlider("ab-bar1-button-max", Settings["ab-bar1-button-max"], 1, 12, 1, Language["Max Buttons"], Language["Set the number of buttons displayed on the action bar"], UpdateBar1)
	right:CreateSlider("ab-bar1-button-size", Settings["ab-bar1-button-size"], 20, 50, 1, Language["Button Size"], Language["Set the action button size"], UpdateBar1)
	right:CreateSlider("ab-bar1-button-gap", Settings["ab-bar1-button-gap"], -1, 8, 1, Language["Button Spacing"], Language["Set the spacing between action buttons"], UpdateBar1)
end)

GUI:AddWidgets(Language["General"], Language["Bar 2"], Language["Action Bars"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("ab-bar2-enable", Settings["ab-bar2-enable"], Language["Enable Bar"], Language["Enable action bar 2"], UpdateEnableBar2)

	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("ab-bar2-hover", Settings["ab-bar2-hover"], Language["Set Mouseover"], Language["Only display the bar while hovering over it"], UpdateBar2Hover)
	left:CreateSlider("ab-bar2-alpha", Settings["ab-bar2-alpha"], 0, 100, 5, Language["Bar Opacity"], Language["Set the opacity of the action bar"], UpdateBar2Alpha)

	right:CreateHeader(Language["Buttons"])
	right:CreateSlider("ab-bar2-per-row", Settings["ab-bar2-per-row"], 1, 12, 1, Language["Buttons Per Row"], Language["Set the number of buttons per row"], UpdateBar2)
	right:CreateSlider("ab-bar2-button-max", Settings["ab-bar2-button-max"], 1, 12, 1, Language["Max Buttons"], Language["Set the number of buttons displayed on the action bar"], UpdateBar2)
	right:CreateSlider("ab-bar2-button-size", Settings["ab-bar2-button-size"], 20, 50, 1, Language["Button Size"], Language["Set the action button size"], UpdateBar2)
	right:CreateSlider("ab-bar2-button-gap", Settings["ab-bar2-button-gap"], -1, 8, 1, Language["Button Spacing"], Language["Set the spacing between action buttons"], UpdateBar2)
end)

GUI:AddWidgets(Language["General"], Language["Bar 3"], Language["Action Bars"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("ab-bar3-enable", Settings["ab-bar3-enable"], Language["Enable Bar"], Language["Enable action bar 3"], UpdateEnableBar3)

	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("ab-bar3-hover", Settings["ab-bar3-hover"], Language["Set Mouseover"], Language["Only display the bar while hovering over it"], UpdateBar3Hover)
	left:CreateSlider("ab-bar3-alpha", Settings["ab-bar3-alpha"], 0, 100, 5, Language["Bar Opacity"], Language["Set the opacity of the action bar"], UpdateBar3Alpha)

	right:CreateHeader(Language["Buttons"])
	right:CreateSlider("ab-bar3-per-row", Settings["ab-bar3-per-row"], 1, 12, 1, Language["Buttons Per Row"], Language["Set the number of buttons per row"], UpdateBar3)
	right:CreateSlider("ab-bar3-button-max", Settings["ab-bar3-button-max"], 1, 12, 1, Language["Max Buttons"], Language["Set the number of buttons displayed on the action bar"], UpdateBar3)
	right:CreateSlider("ab-bar3-button-size", Settings["ab-bar3-button-size"], 20, 50, 1, Language["Button Size"], Language["Set the action button size"], UpdateBar3)
	right:CreateSlider("ab-bar3-button-gap", Settings["ab-bar3-button-gap"], -1, 8, 1, Language["Button Spacing"], Language["Set the spacing between action buttons"], UpdateBar3)
end)

GUI:AddWidgets(Language["General"], Language["Bar 4"], Language["Action Bars"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("ab-bar4-enable", Settings["ab-bar4-enable"], Language["Enable Bar"], Language["Enable action bar 4"], UpdateEnableBar4)

	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("ab-bar4-hover", Settings["ab-bar4-hover"], Language["Set Mouseover"], Language["Only display the bar while hovering over it"], UpdateBar4Hover)
	left:CreateSlider("ab-bar4-alpha", Settings["ab-bar4-alpha"], 0, 100, 5, Language["Bar Opacity"], Language["Set the opacity of the action bar"], UpdateBar4Alpha)

	right:CreateHeader(Language["Buttons"])
	right:CreateSlider("ab-bar4-per-row", Settings["ab-bar4-per-row"], 1, 12, 1, Language["Buttons Per Row"], Language["Set the number of buttons per row"], UpdateBar4)
	right:CreateSlider("ab-bar4-button-max", Settings["ab-bar4-button-max"], 1, 12, 1, Language["Max Buttons"], Language["Set the number of buttons displayed on the action bar"], UpdateBar4)
	right:CreateSlider("ab-bar4-button-size", Settings["ab-bar4-button-size"], 20, 50, 1, Language["Button Size"], Language["Set the action button size"], UpdateBar4)
	right:CreateSlider("ab-bar4-button-gap", Settings["ab-bar4-button-gap"], -1, 8, 1, Language["Button Spacing"], Language["Set the spacing between action buttons"], UpdateBar4)
end)

GUI:AddWidgets(Language["General"], Language["Bar 5"], Language["Action Bars"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("ab-bar5-enable", Settings["ab-bar5-enable"], Language["Enable Bar"], Language["Enable action bar 5"], UpdateEnableBar5)

	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("ab-bar5-hover", Settings["ab-bar5-hover"], Language["Set Mouseover"], Language["Only display the bar while hovering over it"], UpdateBar5Hover)
	left:CreateSlider("ab-bar5-alpha", Settings["ab-bar5-alpha"], 0, 100, 5, Language["Bar Opacity"], Language["Set the opacity of the action bar"], UpdateBar5Alpha)

	right:CreateHeader(Language["Buttons"])
	right:CreateSlider("ab-bar5-per-row", Settings["ab-bar5-per-row"], 1, 12, 1, Language["Buttons Per Row"], Language["Set the number of buttons per row"], UpdateBar5)
	right:CreateSlider("ab-bar5-button-max", Settings["ab-bar5-button-max"], 1, 12, 1, Language["Max Buttons"], Language["Set the number of buttons displayed on the action bar"], UpdateBar5)
	right:CreateSlider("ab-bar5-button-size", Settings["ab-bar5-button-size"], 20, 50, 1, Language["Button Size"], Language["Set the action button size"], UpdateBar5)
	right:CreateSlider("ab-bar5-button-gap", Settings["ab-bar5-button-gap"], -1, 8, 1, Language["Button Spacing"], Language["Set the spacing between action buttons"], UpdateBar5)
end)

if HydraUI.IsMainline then
	GUI:AddWidgets(Language["General"], Language["Bar 6"], Language["Action Bars"], function(left, right)
		left:CreateHeader(Language["Enable"])
		left:CreateSwitch("ab-bar6-enable", Settings["ab-bar6-enable"], Language["Enable Bar"], Language["Enable action bar 6"], UpdateEnableBar6)

		left:CreateHeader(Language["Styling"])
		left:CreateSwitch("ab-bar6-hover", Settings["ab-bar6-hover"], Language["Set Mouseover"], Language["Only display the bar while hovering over it"], UpdateBar6Hover)
		left:CreateSlider("ab-bar6-alpha", Settings["ab-bar6-alpha"], 0, 100, 5, Language["Bar Opacity"], Language["Set the opacity of the action bar"], UpdateBar6Alpha)

		right:CreateHeader(Language["Buttons"])
		right:CreateSlider("ab-bar6-per-row", Settings["ab-bar6-per-row"], 1, 12, 1, Language["Buttons Per Row"], Language["Set the number of buttons per row"], UpdateBar6)
		right:CreateSlider("ab-bar6-button-max", Settings["ab-bar6-button-max"], 1, 12, 1, Language["Max Buttons"], Language["Set the number of buttons displayed on the action bar"], UpdateBar6)
		right:CreateSlider("ab-bar6-button-size", Settings["ab-bar6-button-size"], 20, 50, 1, Language["Button Size"], Language["Set the action button size"], UpdateBar6)
		right:CreateSlider("ab-bar6-button-gap", Settings["ab-bar6-button-gap"], -1, 8, 1, Language["Button Spacing"], Language["Set the spacing between action buttons"], UpdateBar6)
	end)

	GUI:AddWidgets(Language["General"], Language["Bar 7"], Language["Action Bars"], function(left, right)
		left:CreateHeader(Language["Enable"])
		left:CreateSwitch("ab-bar7-enable", Settings["ab-bar7-enable"], Language["Enable Bar"], Language["Enable action bar 7"], UpdateEnableBar7)

		left:CreateHeader(Language["Styling"])
		left:CreateSwitch("ab-bar7-hover", Settings["ab-bar7-hover"], Language["Set Mouseover"], Language["Only display the bar while hovering over it"], UpdateBar7Hover)
		left:CreateSlider("ab-bar7-alpha", Settings["ab-bar7-alpha"], 0, 100, 5, Language["Bar Opacity"], Language["Set the opacity of the action bar"], UpdateBar7Alpha)

		right:CreateHeader(Language["Buttons"])
		right:CreateSlider("ab-bar7-per-row", Settings["ab-bar7-per-row"], 1, 12, 1, Language["Buttons Per Row"], Language["Set the number of buttons per row"], UpdateBar7)
		right:CreateSlider("ab-bar7-button-max", Settings["ab-bar7-button-max"], 1, 12, 1, Language["Max Buttons"], Language["Set the number of buttons displayed on the action bar"], UpdateBar7)
		right:CreateSlider("ab-bar7-button-size", Settings["ab-bar7-button-size"], 20, 50, 1, Language["Button Size"], Language["Set the action button size"], UpdateBar7)
		right:CreateSlider("ab-bar7-button-gap", Settings["ab-bar7-button-gap"], -1, 8, 1, Language["Button Spacing"], Language["Set the spacing between action buttons"], UpdateBar7)
	end)

	GUI:AddWidgets(Language["General"], Language["Bar 8"], Language["Action Bars"], function(left, right)
		left:CreateHeader(Language["Enable"])
		left:CreateSwitch("ab-bar8-enable", Settings["ab-bar8-enable"], Language["Enable Bar"], Language["Enable action bar 8"], UpdateEnableBar8)

		left:CreateHeader(Language["Styling"])
		left:CreateSwitch("ab-bar8-hover", Settings["ab-bar8-hover"], Language["Set Mouseover"], Language["Only display the bar while hovering over it"], UpdateBar8Hover)
		left:CreateSlider("ab-bar8-alpha", Settings["ab-bar8-alpha"], 0, 100, 5, Language["Bar Opacity"], Language["Set the opacity of the action bar"], UpdateBar8Alpha)

		right:CreateHeader(Language["Buttons"])
		right:CreateSlider("ab-bar8-per-row", Settings["ab-bar8-per-row"], 1, 12, 1, Language["Buttons Per Row"], Language["Set the number of buttons per row"], UpdateBar8)
		right:CreateSlider("ab-bar8-button-max", Settings["ab-bar8-button-max"], 1, 12, 1, Language["Max Buttons"], Language["Set the number of buttons displayed on the action bar"], UpdateBar8)
		right:CreateSlider("ab-bar8-button-size", Settings["ab-bar8-button-size"], 20, 50, 1, Language["Button Size"], Language["Set the action button size"], UpdateBar8)
		right:CreateSlider("ab-bar8-button-gap", Settings["ab-bar8-button-gap"], -1, 8, 1, Language["Button Spacing"], Language["Set the spacing between action buttons"], UpdateBar8)
	end)
end

GUI:AddWidgets(Language["General"], Language["Pet Bar"], Language["Action Bars"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("ab-pet-enable", Settings["ab-pet-enable"], Language["Enable Bar"], Language["Enable the pet action bar"], UpdateEnablePetBar)

	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("ab-pet-hover", Settings["ab-pet-hover"], Language["Set Mouseover"], Language["Only display the bar while hovering over it"], UpdatePetHover)
	left:CreateSlider("ab-pet-alpha", Settings["ab-pet-alpha"], 0, 100, 5, Language["Bar Opacity"], Language["Set the opacity of the action bar"], UpdatePetBarAlpha)

	right:CreateHeader(Language["Buttons"])
	right:CreateSlider("ab-pet-per-row", Settings["ab-pet-per-row"], 1, NUM_PET_ACTION_SLOTS, 1, Language["Buttons Per Row"], Language["Set the number of buttons per row"], UpdatePetBar)
	right:CreateSlider("ab-pet-button-size", Settings["ab-pet-button-size"], 20, 50, 1, Language["Button Size"], Language["Set the action button size"], UpdatePetBar)
	right:CreateSlider("ab-pet-button-gap", Settings["ab-pet-button-gap"], -1, 8, 1, Language["Button Spacing"], Language["Set the spacing between action buttons"], UpdatePetBar)
end)

GUI:AddWidgets(Language["General"], Language["Stance Bar"], Language["Action Bars"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("ab-stance-enable", Settings["ab-stance-enable"], Language["Enable Bar"], Language["Enable the stance bar"], UpdateEnableStanceBar)

	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("ab-stance-hover", Settings["ab-stance-hover"], Language["Set Mouseover"], Language["Only display the bar while hovering over it"], UpdateStanceHover)
	left:CreateSlider("ab-stance-alpha", Settings["ab-stance-alpha"], 0, 100, 5, Language["Bar Opacity"], Language["Set the opacity of the action bar"], UpdateStanceBarAlpha)

	right:CreateHeader(Language["Buttons"])
	right:CreateSlider("ab-stance-per-row", Settings["ab-stance-per-row"], 1, 12, 1, Language["Buttons Per Row"], Language["Set the number of buttons per row"], UpdateStanceBar)
	right:CreateSlider("ab-stance-button-size", Settings["ab-stance-button-size"], 20, 50, 1, Language["Button Size"], Language["Set the action button size"], UpdateStanceBar)
	right:CreateSlider("ab-stance-button-gap", Settings["ab-stance-button-gap"], -1, 8, 1, Language["Button Spacing"], Language["Set the spacing between action buttons"], UpdateStanceBar)
end)

GUI:AddWidgets(Language["General"], Language["Totem Bar"], Language["Action Bars"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("ab-totem-enable", Settings["ab-totem-enable"], Language["Enable Bar"], Language["Enable the totem bar"], UpdateEnableTotemBar)
end)