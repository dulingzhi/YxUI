local YxUI, Language, Assets, Settings, Defaults = select(2, ...):get()

-- Constants
local SPACING = 3
local WIDGET_HEIGHT = 20
local SELECTED_HIGHLIGHT_ALPHA = 0.25

-- Locals
local type = type
local floor = math.floor
local max = math.max
local min = math.min

local Round = function(num, dec)
	local Mult = 10 ^ (dec or 0)

	return floor(num * Mult + 0.5) / Mult
end

local GUI = YxUI:NewModule("GUI")

-- Shared scrolling primitives. Keep these independent of a particular row type so
-- widget pages, the navigation list, and dropdowns can all use the same rules.
function GUI.GetMaxRowOffset(totalRows, maxVisibleRows)
	return max((totalRows or 0) - maxVisibleRows + 1, 1)
end

function GUI.NormalizeRowOffset(offset, totalRows, maxVisibleRows)
	return min(max(Round(tonumber(offset) or 1), 1), GUI.GetMaxRowOffset(totalRows, maxVisibleRows))
end

function GUI.GetVisibleRowRange(offset, totalRows, maxVisibleRows)
	local First = GUI.NormalizeRowOffset(offset, totalRows, maxVisibleRows)

	return First, min(First + maxVisibleRows - 1, totalRows)
end

function GUI:StyleVerticalSlider(slider, options)
	options = options or {}

	slider:SetThumbTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	slider:SetOrientation("VERTICAL")
	slider:SetValueStep(1)
	slider:SetBackdrop(YxUI.BackdropAndBorder)
	slider:SetBackdropColor(YxUI:HexToRGB(Settings["ui-window-main-color"]))
	slider:SetBackdropBorderColor(0, 0, 0)

	local Thumb = slider:GetThumbTexture()
	Thumb:SetSize(options.Width or slider:GetWidth(), WIDGET_HEIGHT)
	Thumb:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	Thumb:SetVertexColor(0, 0, 0)

	slider.NewThumb = slider:CreateTexture(nil, "BORDER")
	slider.NewThumb:SetPoint("TOPLEFT", Thumb, 0, 0)
	slider.NewThumb:SetPoint("BOTTOMRIGHT", Thumb, 0, 0)
	slider.NewThumb:SetTexture(Assets:GetTexture("Blank"))
	slider.NewThumb:SetVertexColor(0, 0, 0)

	slider.NewThumb2 = slider:CreateTexture(nil, "OVERLAY")
	slider.NewThumb2:SetPoint("TOPLEFT", slider.NewThumb, 1, -1)
	slider.NewThumb2:SetPoint("BOTTOMRIGHT", slider.NewThumb, -1, 1)
	slider.NewThumb2:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	slider.NewThumb2:SetVertexColor(YxUI:HexToRGB(Settings["ui-widget-bright-color"]))

	if options.Highlight then
		slider.Highlight = slider:CreateTexture(nil, "HIGHLIGHT")
		slider.Highlight:SetPoint("TOPLEFT", slider.NewThumb, 1, -1)
		slider.Highlight:SetPoint("BOTTOMRIGHT", slider.NewThumb, -1, 1)
		slider.Highlight:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
		slider.Highlight:SetVertexColor(1, 1, 1)
		slider.Highlight:SetAlpha(SELECTED_HIGHLIGHT_ALPHA)
	end

	slider.Progress = slider:CreateTexture(nil, "ARTWORK")
	slider.Progress:SetPoint("TOPLEFT", slider, 1, -1)
	slider.Progress:SetPoint("BOTTOMRIGHT", slider.NewThumb, "TOPRIGHT", -1, 0)
	slider.Progress:SetTexture(Assets:GetTexture(options.ProgressTexture or "Blank"))
	slider.Progress:SetVertexColor(YxUI:HexToRGB(Settings[options.ProgressColor or "ui-widget-bright-color"]))
	if options.ProgressAlpha then
		slider.Progress:SetAlpha(options.ProgressAlpha)
	end
end

local RowViewport = {}
RowViewport.__index = RowViewport

function RowViewport:GetRows()
	return type(self.Rows) == "function" and self.Rows(self.Owner) or self.Rows
end

function RowViewport:GetRow(index, rows)
	rows = rows or self:GetRows()
	return self.RowAt and self.RowAt(self.Owner, rows, index) or rows[index]
end

function RowViewport:GetTotalRows()
	local Rows = self:GetRows()
	return type(self.TotalRows) == "function" and self.TotalRows(self.Owner, Rows) or (self.TotalRows or #Rows)
end

function RowViewport:SyncScrollBar()
	if self.ScrollBar and (self.ScrollBar:GetValue() ~= self.Offset) then
		self.Synchronizing = true
		self.Owner.UpdatingScrollBar = true -- compatibility for external handlers
		self.ScrollBar:SetValue(self.Offset)
		self.Owner.UpdatingScrollBar = false
		self.Synchronizing = false
	end
end

function RowViewport:SetScrollBar(scrollBar)
	self.ScrollBar = scrollBar
	if self.ExposeScrollBar ~= false then
		self.Owner.ScrollBar = scrollBar
	end
	scrollBar:SetScript("OnValueChanged", function(_, value)
		if not self.Synchronizing then
			self:SetOffset(value)
		end
	end)
	self:AttachMouseWheel(scrollBar)
	self:SyncScrollBar()
end

function RowViewport:AttachMouseWheel(frame)
	frame:EnableMouseWheel(true)
	frame:SetScript("OnMouseWheel", function(_, delta) self:ScrollBy(delta) end)
end

function RowViewport:SetScrollRange(totalRows)
	if not self.ScrollBar then
		return
	end
	self.Synchronizing = true
	self.Owner.UpdatingScrollBar = true
	local maximum = GUI.GetMaxRowOffset(totalRows, self.MaxVisibleRows)
	if maximum ~= self.LastScrollMaximum then
		self.ScrollBar:SetMinMaxValues(1, maximum)
		self.LastScrollMaximum = maximum
	end
	self.Owner.UpdatingScrollBar = false
	self.Synchronizing = false
end

function RowViewport:Render(rowsChanged)
	local Rows = self:GetRows()
	local Count = self:GetTotalRows()
	local First, Last = GUI.GetVisibleRowRange(self.Offset, Count, self.MaxVisibleRows)
	local OldRows, OldFirst = self.LastRenderedRows, self.LastRenderedOffset
	local OldLast = OldRows and OldFirst and min(OldFirst + self.MaxVisibleRows - 1, #OldRows)

	self.Offset = First
	self.Owner.Offset = First
	self:SetScrollRange(Count)
	self:SyncScrollBar()

	if (not rowsChanged) and (OldRows == Rows) and (OldFirst == First) then
		return
	end

	if self.RenderRows then
		self.RenderRows(self.Owner, self, Rows, First, Last, rowsChanged)
	elseif self.RenderRow then
		for slot = 1, self.MaxVisibleRows do
			self.RenderRow(self.Owner, slot, self:GetRow(First + slot - 1, Rows), First + slot - 1)
		end
	elseif self.UpdateRows then
		self.UpdateRows(self.Owner, Rows, OldRows, OldFirst, OldLast, First, Last, rowsChanged)
	else
		if OldRows and OldFirst then
			for i = OldFirst, OldLast do
				if rowsChanged or (i < First) or (i > Last) then
					OldRows[i]:Hide()
				end
			end
		end

		-- Newly-created frames are shown by default. When the row collection is
		-- replaced, hide every row outside the viewport even if a previous (often
		-- empty) collection has already been rendered.
		if rowsChanged or (not OldRows) then
			for i = 1, First - 1 do
				Rows[i]:Hide()
			end
			for i = Last + 1, Count do
				Rows[i]:Hide()
			end
		end

		for i = First, Last do
			if rowsChanged or (not OldFirst) or (i < OldFirst) or (i > OldLast) then
				Rows[i]:Show()
			end
		end
	end

	if self.AnchorRows then
		self.AnchorRows(self.Owner, Rows, First, Last)
	end
	self.LastRenderedRows = Rows
	self.LastRenderedOffset = First
	self.Owner.LastRenderedOffset = First
	if self.AfterRender then
		self.AfterRender(self.Owner, First, Last)
	end
end

function RowViewport:SetOffset(offset, rowsChanged)
	self.Offset = GUI.NormalizeRowOffset(offset, self:GetTotalRows(), self.MaxVisibleRows)
	self.Owner.Offset = self.Offset
	self:Render(rowsChanged)
end

function RowViewport:SetOffsetByDelta(delta)
	self:SetOffset(self.Offset + (delta > 0 and -1 or 1))
end

RowViewport.ScrollBy = RowViewport.SetOffsetByDelta

function GUI:CreateRowViewport(owner, options)
	local Viewport = setmetatable({
		Owner = owner,
		Rows = options.Rows,
		RowAt = options.RowAt,
		TotalRows = options.TotalRows,
		MaxVisibleRows = options.MaxVisibleRows,
		AnchorRows = options.AnchorRows,
		UpdateRows = options.UpdateRows,
		RenderRows = options.RenderRows,
		RenderRow = options.RenderRow,
		AfterRender = options.AfterRender,
		ExposeScrollBar = options.ExposeScrollBar,
		Offset = GUI.NormalizeRowOffset(options.Offset or owner.Offset, 0, options.MaxVisibleRows),
	}, RowViewport)

	owner.RowViewport = Viewport
	return Viewport
end

-- Storage
GUI.CategoryOrder = {}
GUI.Categories = {}
GUI.Pages = {}
GUI.Widgets = {}
GUI.WidgetID = {}
GUI.ScrollButtons = {}

-- Refresh existing controls after a profile change; only page-definition changes rebuild frames.
function GUI:RefreshSettingWidgets(changed)
	local ids = {}
	for i = 1, #changed do ids[changed[i]] = true end
	for i = 1, #self.CategoryOrder do
		local category = self.CategoryOrder[i]
		for _, page in pairs(category.IDLookup) do
			local window = page.Window
			if window and not page.WindowNeedsRebuild then
				for _, widgets in ipairs({window.LeftWidgets, window.RightWidgets}) do
					for j = 1, #widgets do
						local anchor = widgets[j]
						if ids[anchor.ID] and anchor.Refresh then anchor:Refresh() end
					end
				end
			end
		end
	end
end

-- Setting callbacks are registered when modules load, independently of page widgets.
GUI.SettingDefinitions = {}
function GUI:RegisterSetting(id, definition)
	if type(id) ~= "string" or id == "" or type(definition) ~= "table" then return end
	local existing = self.SettingDefinitions[id]
	if existing and not existing.Auto and definition.Auto then return existing end
	if not existing or (existing.Auto and not definition.Auto) then
		existing = {}
		self.SettingDefinitions[id] = existing
	end
	for key, value in pairs(definition) do
		if value ~= nil then existing[key] = value end
	end
	if existing.Default == nil then existing.Default = Defaults[id] end
	return existing
end

-- The registry is the source for both user edits and profile transitions.
local function RegisterSettingsOnPage(gui, page, settings)
	for i = 1, #settings do
		local entry = settings[i]
		local id, callback, options = entry[1], entry[2], entry[3]
		if type(id) == "string" and id ~= "" then
			local definition = {Page = page}
			if type(callback) == "function" then definition.OnChange = callback end
			if type(options) == "table" then
				for key, value in pairs(options) do definition[key] = value end
			end
			if callback == ReloadUI or (C_UI and callback == C_UI.Reload) then
				definition.RequiresReload = true
			end
			gui:RegisterSetting(id, definition)
		end
	end
end

function GUI:RegisterPageSettings(category, name, settings, parent)
	local page = self:HasButton(category, name, parent)
	assert(page, "Cannot register settings for missing GUI page: " .. tostring(category) .. "/" .. tostring(name))
	RegisterSettingsOnPage(self, page, settings)
end

function GUI:RegisterPageSettingsID(categoryID, pageID, settings, parentID)
	local category = self.CategoriesByID and self.CategoriesByID[categoryID]
	local page = category and category.IDLookup[pageID]
	assert(page and ((not parentID and not page.Parent) or (page.Parent and page.Parent.ID == parentID)),
		"Cannot register settings for missing GUI page ID: " .. tostring(categoryID) .. "/" .. tostring(pageID))
	RegisterSettingsOnPage(self, page, settings)
end

function GUI:RegisterReadOnUseSettings(ids)
	for i = 1, #ids do
		self:RegisterSetting(ids[i], {ReadOnUse = true, RequiresReload = false})
	end
end

function GUI:RegisterReloadSettings(ids)
	for i = 1, #ids do
		self:RegisterSetting(ids[i], {RequiresReload = true})
	end
end

function GUI:GetWidget(id)
	return self.WidgetID[id]
end

function GUI:Toggle()
	if not self.Loaded then
		self:CreateGUI()
	end

	if self:IsShown() then
		self.WidgetCore.DismissWindowControllers(self)
		self.IsMoving = false
		self.FadeOut:Play()
		self.ScaleOut:Play()
		self:UnregisterEvent("MODIFIER_STATE_CHANGED")

		if Settings["gui-enable-fade"] then
			self:UnregisterEvent("PLAYER_STARTED_MOVING")
			self:UnregisterEvent("PLAYER_STOPPED_MOVING")
		end
	else
		if Settings["gui-hide-in-combat"] and InCombatLockdown() then
			YxUI:print(ERR_NOT_IN_COMBAT)

			return
		end

		if Settings["gui-enable-fade"] then
			self:RegisterEvent("PLAYER_STARTED_MOVING")
			self:RegisterEvent("PLAYER_STOPPED_MOVING")
		end

		if not self.FirstToggle then
			C_Timer.After(0.2, function()
				self:Show()
				self.FadeIn:Play()
				self.ScaleIn:Play()
			end)

			self.FirstToggle = true
		else
			self:Show()
			self.FadeIn:Play()
			self.ScaleIn:Play()
		end

		self:RegisterEvent("MODIFIER_STATE_CHANGED")
	end
end

function GUI:PLAYER_REGEN_DISABLED()
	if Settings["gui-hide-in-combat"] and self:IsVisible() then
		self.WidgetCore.DismissWindowControllers(self)
		self:SetAlpha(0)
		self:Hide()
		--CloseLastDropdown()
		self.WasCombatClosed = true
	end
end

local ReopenWindow = function()
	GUI:SetAlpha(0)
	GUI:Show()
	GUI.ScaleIn:Play()
	GUI.FadeIn:Play()
end

function GUI:PLAYER_REGEN_ENABLED()
	if Settings["gui-hide-in-combat"] and self.WasCombatClosed then
		YxUI:DisplayPopup(Language["Attention"], Language["The settings window was automatically closed due to combat. Would you like to open it again?"], ACCEPT, ReopenWindow, CANCEL)
	end

	self.WasCombatClosed = false
end

-- Enabling the mouse wheel will stop the scrolling if we pass over a widget, but I really want mousewheeling
function GUI:MODIFIER_STATE_CHANGED(key, state)
	if GetMouseFocus then
		local MouseFocus = GetMouseFocus()

		if not MouseFocus then
			return
		end

		if MouseFocus.OnMouseWheel and state == 1 then
			MouseFocus:SetScript("OnMouseWheel", MouseFocus.OnMouseWheel)
		elseif MouseFocus.HasScript and MouseFocus:HasScript("OnMouseWheel") then
			MouseFocus:SetScript("OnMouseWheel", nil)
		end
	elseif GetMouseFoci then
		local MouseFocus = GetMouseFoci()

		if not MouseFocus then
			return
		end

		MouseFocus = MouseFocus[1]

		if not MouseFocus then
			return
		end

		if MouseFocus.OnMouseWheel and state == 1 then
			MouseFocus:SetScript("OnMouseWheel", MouseFocus.OnMouseWheel)
		elseif MouseFocus.HasScript and MouseFocus:HasScript("OnMouseWheel") then
			MouseFocus:SetScript("OnMouseWheel", nil)
		end
	end
end

function GUI:PLAYER_STARTED_MOVING()
	self.IsMoving = true
	if self.Fader:IsPlaying() then
		self.Fader:Stop()
	end

	self.Fader:SetEasing("out")
	self.Fader:SetChange(Settings["gui-faded-alpha"] / 100)
	self.Fader:Play()
end

function GUI:PLAYER_STOPPED_MOVING()
	self.IsMoving = false
	if self.Fader:IsPlaying() then
		self.Fader:Stop()
	end

	self.Fader:SetEasing("in")
	self.Fader:SetChange(1)
	self.Fader:Play()
end
