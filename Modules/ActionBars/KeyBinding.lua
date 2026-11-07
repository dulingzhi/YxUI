local YxUI, Language, Assets, Settings = select(2, ...):get()

local KeyBinding = YxUI:NewModule("Key Binding")
local GUI = YxUI:GetModule("GUI")

local match = string.match

KeyBinding.ValidBindings = {
	["ACTIONBUTTON"] = true,
	["BONUSACTIONBUTTON"] = true,
	["MULTIACTIONBAR1BUTTON"] = true,
	["MULTIACTIONBAR2BUTTON"] = true,
	["MULTIACTIONBAR3BUTTON"] = true,
	["MULTIACTIONBAR4BUTTON"] = true,
	["SHAPESHIFTBUTTON"] = true,
}

KeyBinding.Translate = {
	["ActionButton"] = "ACTIONBUTTON",
	["MultiBarBottomLeftButton"] = "MULTIACTIONBAR1BUTTON",
	["MultiBarBottomRightButton"] = "MULTIACTIONBAR2BUTTON",
	["MultiBarRightButton"] = "MULTIACTIONBAR3BUTTON",
	["MultiBarLeftButton"] = "MULTIACTIONBAR4BUTTON",
}

KeyBinding.Filter = {
	["BACKSPACE"] = true,
	["LALT"] = true,
	["RALT"] = true,
	["LCTRL"] = true,
	["RCTRL"] = true,
	["LSHIFT"] = true,
	["RSHIFT"] = true,
	["ENTER"] = true,
	["LeftButton"] = true,
	["RightButton"] = true,
}

local GetMouseFocusNew = function()
	local Focus

	if GetMouseFocus then
		Focus = GetMouseFocus()
	elseif GetMouseFoci then
		local Foci = GetMouseFoci()
		Focus = Foci and Foci[1]
	end

	if Focus then
		return Focus
	end
end

function KeyBinding:UpdateTarget()
	local Focus = GetMouseFocusNew()
	local Name = Focus and Focus.GetName and Focus:GetName()
	local ButtonName, Number
	if Name then
		ButtonName, Number = match(Name, "^(.-)(%d+)$")
	end
	local Binding = ButtonName and self.Translate[ButtonName]

	if Binding and Number and self.ValidBindings[Binding] then
		self.TargetBindingName = Binding .. Number
		return Focus
	end

	self.TargetBindingName = nil
end

function KeyBinding:OnKeyUp(key)
	self:UpdateTarget()

	if not IsKeyPressIgnoredForBinding(key) and not self.Filter[key] and self.TargetBindingName then
		if key == "ESCAPE" then
			local Binding = GetBindingKey(self.TargetBindingName)

			if Binding then
				SetBinding(Binding)
			end

			return
		end

		key = format("%s%s%s%s", IsAltKeyDown() and "ALT-" or "", IsControlKeyDown() and "CTRL-" or "", IsShiftKeyDown() and "SHIFT-" or "", key)

		local OldAction = GetBindingAction(key, true)

		if OldAction then
			local OldName = GetBindingName(OldAction)

			YxUI:print(format(Language['Unbound "%s" from %s'], key, OldName))
		end

		SetBinding(key, self.TargetBindingName, 1)

		local NewAction = GetBindingAction(key, true)
		local NewName = GetBindingName(NewAction)

		YxUI:print(format(Language['Bound "%s" to %s'], key, NewName))

		GUI:GetWidget("kb-save"):Enable()
		GUI:GetWidget("kb-discard"):Enable()
	end
end

function KeyBinding:OnKeyDown(key)
	self:UpdateTarget()
end

function KeyBinding:OnMouseWheel(delta)
	local key

	if delta > 0 then
		key = "MOUSEWHEELUP"
	else
		key = "MOUSEWHEELDOWN"
	end

	self:UpdateTarget()

	if not self.Filter[key] and self.TargetBindingName then
		key = format("%s%s%s%s", IsAltKeyDown() and "ALT-" or "", IsControlKeyDown() and "CTRL-" or "", IsShiftKeyDown() and "SHIFT-" or "", key)

		local OldAction = GetBindingAction(key, true)

		if OldAction then
			local OldName = GetBindingName(OldAction)

			YxUI:print(format(Language['Unbound "%s" from %s'], key, OldName))
		end

		SetBinding(key, self.TargetBindingName, 1)

		local NewAction = GetBindingAction(key, true)
		local NewName = GetBindingName(NewAction)

		YxUI:print(format(Language['Bound "%s" to %s'], key, NewName))

		GUI:GetWidget("kb-save"):Enable()
		GUI:GetWidget("kb-discard"):Enable()
	end
end

function KeyBinding:OnEvent(event, button)
	self:UpdateTarget()

	if button and not self.Filter[button] and self.TargetBindingName then
		if button == "MiddleButton" then
			button = "BUTTON3"
		end

		if match(button, "Button%d+") then
			button = string.upper(button)
		end

		button = format("%s%s%s%s", IsAltKeyDown() and "ALT-" or "", IsControlKeyDown() and "CTRL-" or "", IsShiftKeyDown() and "SHIFT-" or "", button)

		local OldAction = GetBindingAction(button, true)

		if OldAction then
			local OldName = GetBindingName(OldAction)

			YxUI:print(format(Language['Unbound "%s" from %s'], button, OldName))
		end

		SetBinding(button, self.TargetBindingName, 1)

		local NewAction = GetBindingAction(button, true)
		local NewName = GetBindingName(NewAction)

		YxUI:print(format(Language['Bound "%s" to %s'], button, NewName))

		GUI:GetWidget("kb-save"):Enable()
		GUI:GetWidget("kb-discard"):Enable()
	end
end

function KeyBinding:OnUpdate(elapsed)
	self.Elapsed = self.Elapsed + elapsed

	if self.Elapsed > 0.05 then
		local MouseFocus = self:UpdateTarget()

		if MouseFocus then
			if self.HoveredButton ~= MouseFocus then
				self.Hover:ClearAllPoints()
				self.Hover:SetPoint("TOPLEFT", MouseFocus, 1, -1)
				self.Hover:SetPoint("BOTTOMRIGHT", MouseFocus, -1, 1)
				self.HoveredButton = MouseFocus
			end
			self.Hover:Show()
		elseif self.Hover:IsShown() then
			self.Hover:Hide()
			self.HoveredButton = nil
		end

		self.Elapsed = 0
	end
end

local PopupOnAccept = function()
	KeyBinding:Disable()
end

local PopupOnCancel = function()
	KeyBinding:Disable()
end

local OnAccept = function()
	if YxUI.IsVanilla then
		AttemptToSaveBindings(GetCurrentBindingSet())
	else
		SaveBindings(GetCurrentBindingSet())
	end

	GUI:GetWidget("kb-discard"):Disable()
	GUI:GetWidget("kb-save"):Disable()

	KeyBinding:Disable()
end

local OnCancel = function()
	KeyBinding:Disable()
end

function KeyBinding:Enable()
	self:EnableKeyboard(true)
	self:EnableMouseWheel(true)
	self:SetScript("OnUpdate", self.OnUpdate)
	self:SetScript("OnKeyDown", self.OnKeyDown)
	self:SetScript("OnKeyUp", self.OnKeyUp)
	self:SetScript("OnMouseWheel", self.OnMouseWheel)
	self:SetScript("OnEvent", self.OnEvent)
	self.Active = true

	YxUI:DisplayPopup(Language["Attention"], Language["Key binding mode is active. Would you like to save your changes?"], ACCEPT, OnAccept, CANCEL, OnCancel)
end

function KeyBinding:Disable()
	self:EnableKeyboard(false)
	self:EnableMouseWheel(false)
	self:SetScript("OnUpdate", nil)
	self:SetScript("OnKeyDown", nil)
	self:SetScript("OnKeyUp", nil)
	self:SetScript("OnMouseWheel", nil)
	self:SetScript("OnEvent", nil)
	self.Active = false
	self.TargetBindingName = nil
	self.HoveredButton = nil
	self.Hover:Hide()

	YxUI:ClearPopup()
end

function KeyBinding:Toggle()
	if self.Active then
		self:Disable()
	else
		self:Enable()
	end
end

function KeyBinding:Load()
	self.Elapsed = 0
	self:SetFrameStrata("DIALOG")
	self:SetAllPoints(YxUI.UIParent)

	self.Hover = CreateFrame("Frame", nil, self, "BackdropTemplate")
	self.Hover:SetFrameLevel(50)
	self.Hover:SetFrameStrata("DIALOG")
	self.Hover:SetBackdrop(YxUI.BackdropAndBorder)
	self.Hover:SetBackdropColor(YxUI:HexToRGB("FFC44D"))
	self.Hover:SetBackdropBorderColor(YxUI:HexToRGB("FFC44D"))
	self.Hover:SetAlpha(0.6)
	self.Hover:Hide()
end

local ToggleBindingMode = function()
	KeyBinding:Toggle()
end

local SaveChanges = function()
	YxUI:DisplayPopup(Language["Attention"], Language["Are you sure you want to save these key binding changes?"], ACCEPT, OnAccept, CANCEL, OnCancel)
end

local DiscardChanges = function()
	YxUI:DisplayPopup(Language["Attention"], Language["Are you sure you want to discard these key binding changes?"], ACCEPT, ReloadUI, CANCEL)
end

GUI:AddWidgetsID("General", "Action Bars", function(left, right)
	right:CreateHeader(Language["Key Binding"])
	right:CreateButton("kb-toggle", Language["Toggle"], Language["Key Bind Mode"], Language["While toggled, you can hover over action buttons and press a key combination to rebind them"], ToggleBindingMode)
	right:CreateButton("kb-save", ACCEPT, Language["Save Changes"], Language["Save key binding changes"], SaveChanges):Disable()
	right:CreateButton("kb-discard", Language["Discard"], Language["Discard Changes"], Language["Discard key binding changes"], DiscardChanges):Disable()

	--self:GetWidget("kb-save"):Disable()
	--self:GetWidget("kb-discard"):Disable()
end)
