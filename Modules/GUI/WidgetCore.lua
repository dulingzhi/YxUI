local YxUI, Language, Assets, Settings, Defaults = select(2, ...):get()
local GUI = YxUI:GetModule("GUI")

local Core = {
	SPACING = 3,
	HEADER_HEIGHT = 20,
	HEADER_SPACING = 5,
	GROUP_HEIGHT = 80,
	WIDGET_HEIGHT = 20,
	LABEL_SPACING = 3,
	SELECTED_HIGHLIGHT_ALPHA = 0.25,
	MOUSEOVER_HIGHLIGHT_ALPHA = 0.1,
	Controllers = {
		Dropdown = { Active = nil },
		Input = { Active = nil },
		Color = { Active = nil },
	},
}
Core.GROUP_WIDTH = 279 - (Core.SPACING * 2)
GUI.WidgetCore = Core

-- All interactive widgets use the same lightweight container. Keeping the
-- metadata and tooltip wiring here prevents constructors from drifting apart.
function Core.CreateWidgetAnchor(owner, id, label, tooltip)
	local Anchor = CreateFrame("Frame", nil, owner)
	Anchor:SetSize(Core.GROUP_WIDTH, Core.WIDGET_HEIGHT)
	Anchor.ID = id
	Anchor.Text = label
	Anchor.Tooltip = tooltip
	Anchor:SetScript("OnEnter", Core.AnchorOnEnter)
	Anchor:SetScript("OnLeave", Core.AnchorOnLeave)
	if tooltip and string.match(tooltip, "%S") then
		Anchor:EnableMouse(true)
	end

	return Anchor
end

-- Value setters update presentation without saving or calling hooks.
function Core.WidgetGetValue(self)
	if self.ValueReader then return self.ValueReader(self.Control) end
	return self.Control.Value
end

function Core.WidgetSetValue(self, value)
	if self.ValueRenderer then
		self.ValueRenderer(self.Control, value)
	else
		self.Control.Value = value
	end
	return self
end

function Core.WidgetRefresh(self)
	if self.ID and Settings[self.ID] ~= nil then
		self:SetValue(Settings[self.ID])
	end
	return self
end

function Core.WidgetSetEnabled(self, enabled)
	if enabled then
		if self.Enable then self:Enable() end
	elseif self.Disable then
		self:Disable()
	end
	if not self.Enable and not self.Disable then
		if self.Control and self.Control.EnableMouse then self.Control:EnableMouse(enabled) end
		if self.Control and self.Control.Box and self.Control.Box.EnableMouse then
			self.Control.Box:EnableMouse(enabled)
		end
		if self.Color then
			self.Color.MiddleText:SetTextColor(YxUI:HexToRGB(enabled and "FFFFFF" or "A5A5A5"))
		end
	end
	return self
end

function Core.BindControl(anchor, control, read, render)
	anchor.Control = control
	anchor.ValueReader = read
	anchor.ValueRenderer = render
	anchor.GetValue = Core.WidgetGetValue
	anchor.SetValue = Core.WidgetSetValue
	anchor.Refresh = Core.WidgetRefresh
	anchor.SetEnabled = Core.WidgetSetEnabled
	local definition = GUI.SettingDefinitions[anchor.ID]
	if definition and not definition.Auto then
		-- Registered behavior is shared by profile changes and GUI controls.
		if definition.OnChange then control.Hook = definition.OnChange end
	elseif Defaults[anchor.ID] ~= nil and type(control.Hook) == "function" then
		-- Older third-party widgets can still register their callback when opened.
		local owner = anchor:GetParent()
		local window = owner and owner:GetParent()
		if window and window.Page then
			local requiresReload = control.Hook == ReloadUI or (C_UI and control.Hook == C_UI.Reload)
			definition = { OnChange = control.Hook, RequiresReload = requiresReload, Page = window.Page, Auto = true, Anchor = anchor }
			GUI:RegisterSetting(anchor.ID, definition)
		end
	end
	control.HydraSettingDefinition = definition
	return anchor
end

local function BelongsToWindow(frame, window)
	while frame do
		if frame == window then return true end
		frame = frame.GetParent and frame:GetParent()
	end
	return false
end

local ControllerKinds = {"Dropdown", "Input", "Color"}

local function StopFade(frame)
	if frame.FadeIn then frame.FadeIn:Stop() end
	if frame.FadeOut then frame.FadeOut:Stop() end
end

-- Closing an unfinished control never writes settings or invokes callbacks.
function Core.DismissTransient(kind)
	if kind == "Dropdown" then
		local active = Core.Controllers.Dropdown.Active
		if not active then return end
		if active.Menu then
			StopFade(active.Menu)
			active.Menu:Hide()
		end
		if active.Arrow then active.Arrow:SetTexture(Assets:GetTexture("Arrow Down")) end
		Core.Controllers.Dropdown.Active = nil
	elseif kind == "Input" then
		local window = GUI.InputWindow
		if window then
			StopFade(window)
			if window.Input then
				window.Input:SetAutoFocus(false)
				window.Input:ClearFocus()
			end
			window:Hide()
			window.ActiveInput = nil
		end
		Core.Controllers.Input.Active = nil
	elseif kind == "Color" then
		local window = GUI.ColorPicker
		if window then
			local dropdown = Core.Controllers.Dropdown.Active
			if dropdown and BelongsToWindow(dropdown, window) then
				Core.DismissTransient("Dropdown")
			end
			StopFade(window)
			window.Dismissing = true
			if window.NewHexText then
				window.NewHexText:SetAutoFocus(false)
				window.NewHexText:ClearFocus()
			end
			window:Hide()
			window.Dismissing = nil
			window.Active = nil
		end
		Core.Controllers.Color.Active = nil
	end
end

-- A dropdown inside the colour picker is allowed to coexist with that picker.
function Core.ActivateTransient(kind, anchor)
	for _, other in ipairs(ControllerKinds) do
		local active = Core.Controllers[other].Active
		if active and not (other == kind and active == anchor) then
			if not (other == "Color" and kind == "Dropdown" and GUI.ColorPicker and BelongsToWindow(anchor, GUI.ColorPicker)) then
				Core.DismissTransient(other)
			end
		end
	end
	Core.Controllers[kind].Active = anchor
end

-- Keyboard handling is active only while a GUI frame is visible; other keys propagate.
-- Never call the restricted propagation setter in combat.
function Core.BindEscape(frame, callback)
	if not frame.SetPropagateKeyboardInput then return end
	frame.EscapeCallback = callback
	frame:HookScript("OnShow", function(self)
		if InCombatLockdown() then
			self:EnableKeyboard(false)
		else
			self:SetPropagateKeyboardInput(true)
			self:EnableKeyboard(true)
		end
	end)
	frame:HookScript("OnHide", function(self)
		self:EnableKeyboard(false)
	end)
	frame:SetScript("OnKeyDown", function(self, key)
		if key == "ESCAPE" then
			local handled = self.EscapeCallback(self)
			if handled and not InCombatLockdown() then
				self:SetPropagateKeyboardInput(false)
			end
		end
	end)
end

function Core.DismissWindowControllers(window)
	if not window then return end
	for _, kind in ipairs(ControllerKinds) do
		local active = Core.Controllers[kind].Active
		if active and BelongsToWindow(active, window) then
			Core.DismissTransient(kind)
		end
	end
	if window == GUI then
		for _, dialog in pairs({GUI.ImportWindow, GUI.ExportWindow}) do
			if dialog then
				if dialog.Input then dialog.Input:SetAutoFocus(false); dialog.Input:ClearFocus() end
				dialog:Hide()
			end
		end
	end
end

function Core.UnregisterWindow(window)
	if not window then return end
	Core.DismissWindowControllers(window)
	for _, widgets in ipairs({window.LeftWidgets, window.RightWidgets}) do
		if widgets then
			for i = 1, #widgets do
				local anchor = widgets[i]
				local id = anchor.ID
				if id and GUI.WidgetID[id] == anchor then
					GUI.WidgetID[id] = nil
				end
				local definition = id and GUI.SettingDefinitions[id]
				if definition and definition.Auto and definition.Anchor == anchor then
					GUI.SettingDefinitions[id] = nil
				end
			end
		end
	end
end

function Core.RegisterWidget(owner, anchor, id)
	table.insert(owner.Widgets, anchor)
	if id and id ~= "" then
		GUI.WidgetID[id] = anchor
		if type(anchor.Text) == "string" and anchor.Text ~= "" and (GUI.SearchIndexReady or GUI.SearchIndexBuilding) and not (GUI.SearchKnownWidgetIDs and GUI.SearchKnownWidgetIDs[id]) then
			GUI:InvalidateSettingsSearchIndex()
		end
	end

	return anchor
end

-- Constructors receive defaults, but a saved setting always takes priority.
function Core.GetInitialValue(id, default)
	if Settings[id] ~= nil then
		return Settings[id]
	end

	return default
end

function Core.SetRequiresReload(self, flag)
	self.ReloadFlag = flag
	if self.HydraSettingDefinition and self.HydraSettingDefinition.Auto then
		self.HydraSettingDefinition.RequiresReload = flag or self.Hook == ReloadUI or (C_UI and self.Hook == C_UI.Reload)
	end
	return self
end

function Core.DisableSaving(self)
	self.IsSavingDisabled = true
	if self.HydraSettingDefinition and self.HydraSettingDefinition.Auto then
		self.HydraSettingDefinition.RequiresReload = true
	end
	return self
end

local PersistenceOptOut = {
	["ui-profile"] = true,
	["profile-copy"] = true,
}

function Core.ShouldPersist(id, widget)
	return not PersistenceOptOut[id] and not (widget and widget.IsSavingDisabled)
end

function Core.UpdateDependencies(rules)
	for id, enabled in pairs(rules) do
		local anchor = GUI:GetWidget(id)
		if anchor then
			if anchor.SetEnabled then
				anchor:SetEnabled(enabled)
			elseif enabled and anchor.Enable then
				anchor:Enable()
			elseif not enabled and anchor.Disable then
				anchor:Disable()
			elseif anchor.Color then
				anchor.Color:EnableMouse(enabled)
				anchor.Color.MiddleText:SetTextColor(YxUI:HexToRGB(enabled and "FFFFFF" or "A5A5A5"))
			end
		end
	end
end

function Core.SetVariable(id, value, widget)
	if not Core.ShouldPersist(id, widget) then
		return false
	end

	local name = YxUI:GetActiveProfileName()

	if name then
		YxUI:SetProfileValue(name, id, value)
	end

	Settings[id] = value

	return true
end

function Core.NotifyValueChanged(widget, value)
	local definition = GUI.SettingDefinitions[widget.ID]
	local hook = definition and definition.OnChange or widget.Hook
	local reload
	if definition and not definition.Auto and definition.RequiresReload ~= nil then
		reload = definition.RequiresReload
	else
		reload = widget.ReloadFlag
	end
	if reload then
		YxUI:DisplayPopup(Language["Attention"], Language["You have changed a setting that requires a UI reload. Would you like to reload the UI now?"], ACCEPT, hook, CANCEL, nil, value, widget.ID)
	elseif hook then
		hook(value, widget.ID)
	end
end

function Core.CommitValue(widget, value)
	local dropdown = Core.Controllers.Dropdown.Active
	if dropdown and not BelongsToWindow(widget, dropdown.Menu) and widget ~= dropdown.Parent then
		Core.DismissTransient("Dropdown")
	end
	local input = Core.Controllers.Input.Active
	if input and widget ~= input and not BelongsToWindow(widget, GUI.InputWindow) then
		Core.DismissTransient("Input")
	end
	local color = Core.Controllers.Color.Active
	if color and widget ~= color and not BelongsToWindow(widget, GUI.ColorPicker) then
		Core.DismissTransient("Color")
	end
	Core.SetVariable(widget.ID, value, widget)
	Core.NotifyValueChanged(widget, value)
end

function Core.Round(num, dec)
	local mult = 10 ^ (dec or 0)

	return math.floor(num * mult + 0.5) / mult
end

function Core.TrimHex(s)
	return string.match(s, "|c%x%x%x%x%x%x%x%x(.-)|r") or s
end

function Core.NormalizeDropdownOffset(offset, count, shown)
	local requestedOffset = Core.Round(tonumber(offset) or 1)
	local maximumOffset = math.max((count or 0) - (shown or 0) + 1, 1)

	return math.min(math.max(requestedOffset, 1), maximumOffset)
end

function Core.NormalizeSliderValue(value, minimum, maximum, step)
	value = tonumber(value) or minimum

	if step >= 1 then
		value = math.floor(value)
	else
		value = Core.Round(value, step <= 0.01 and 2 or 1)
	end

	return math.min(math.max(value, minimum), maximum)
end

function Core.NormalizeColor(value)
	local hex = tostring(value or ""):gsub("#", ""):upper()

	if #hex == 8 then
		hex = hex:sub(3)
	end

	if #hex ~= 6 or hex:find("[^0-9A-F]") then
		return "FFFFFF"
	end

	return hex
end

function Core.AnchorOnEnter(self)
	if self.Tooltip and string.match(self.Tooltip, "%S") then
		local red, green, blue = YxUI:HexToRGB(Settings["ui-widget-font-color"])

		GameTooltip_SetDefaultAnchor(GameTooltip, self)
		GameTooltip:AddLine(self.Tooltip, red, green, blue, true)
		GameTooltip:Show()
	end
end

function Core.AnchorOnLeave()
	GameTooltip:Hide()
end

function Core.FadeOnFinished(self)
	self.Parent:Hide()
end
