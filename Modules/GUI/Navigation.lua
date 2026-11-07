local YxUI, Language, Assets, Settings = select(2, ...):get()
local GUI = YxUI:GetModule("GUI")
local SPACING, WIDGET_HEIGHT, MENU_BUTTON_WIDTH = 3, 20, 120
local SELECTED_HIGHLIGHT_ALPHA, MOUSEOVER_HIGHLIGHT_ALPHA = 0.25, 0.1
local MAX_WIDGETS_SHOWN = 15
local tinsert, tsort = table.insert, table.sort
local type = type
-- Keep the settings navigation in the same order across languages.
local NavigationKeys = {
	"General", "Info", "Action Bars", "Unit Frames", "Name Plates", "Chat",
	"Auras", "Profiles", "Styles", "Minimap", "Tooltips", "Colors",
	"Objectives", "Experience", "Reputation", "Data Texts", "Player",
	"Target", "Target of Target", "Focus", "Bosses", "Party", "Raid",
	"Pet", "Party Pets", "Raid Pets", "Left", "Right", "Credits",
	"Supporters", "Debug", "Plugins", "Totem Bar", "Pet Bar", "Stance Bar",
	"Extra Action", "Micro Menu", "Bags", "Key Binding", "General",
}
for i = 1, 8 do
	NavigationKeys[#NavigationKeys + 1] = "Action Bar " .. i
end
local NavigationSortNames = {}
for i = 1, #NavigationKeys do
	local Key = NavigationKeys[i]
	NavigationSortNames[Language[Key]] = Key
end
local SortByName = function(a, b)
	local A = a.ID or NavigationSortNames[a.Name] or a.Name
	local B = b.ID or NavigationSortNames[b.Name] or b.Name
	if A == B then return a.Name < b.Name end
	return A < B
end

local SetArrowDirection = function(arrow, expanded)
	arrow:SetTexture(Assets:GetTexture(expanded and "Arrow Up" or "Arrow Down"))
end

function GUI:SetPageExpanded(page, expanded)
	if page.Parent or #page.Children == 0 or page.Expanded == expanded then
		return
	end

	page.Expanded = expanded
	SetArrowDirection(page.Button.Arrow, expanded)
	self.SelectionRowsDirty = true
	self:ScrollSelections()
end

function GUI:TogglePage(page)
	self:SetPageExpanded(page, not page.Expanded)
end

function GUI:SortMenuButtons()
	tsort(self.CategoryOrder, SortByName)

	self.NumShownButtons = 0

	local Categories = self.CategoryOrder

	for i = 1, #Categories do
		local Category = Categories[i]
		tsort(Category.Pages, SortByName)

		for j = 1, #Category.Pages do
			local Page = Category.Pages[j]
			tsort(Page.Children, SortByName)

			Page.Button:ClearAllPoints()
			if j == 1 then
				Page.Button:SetPoint("TOPLEFT", Category.Frame, "BOTTOMLEFT", 0, -2)
			else
				Page.Button:SetPoint("TOPLEFT", Category.Pages[j-1].Button, "BOTTOMLEFT", 0, -2)
			end

			self.NumShownButtons = self.NumShownButtons + 1
		end

		Category.Frame:ClearAllPoints()
		if i == 1 then
			Category.Frame:SetPoint("TOPLEFT", self.MenuParent, "TOPLEFT", SPACING, -SPACING)
		elseif #Categories[i-1].Pages > 0 then
			Category.Frame:SetPoint("TOPLEFT", Categories[i-1].Pages[#Categories[i-1].Pages].Button, "BOTTOMLEFT", 0, -2)
		else
			Category.Frame:SetPoint("TOPLEFT", Categories[i-1].Frame, "BOTTOMLEFT", 0, -2)
		end

		self.NumShownButtons = self.NumShownButtons + 1
	end

	self.SelectionRowsDirty = true
end

function GUI:CreateCategory(name)
	local Descriptor = self:GetCategoryDescriptor(name)

	if Descriptor.Frame then
		return Descriptor
	end

	local Category = CreateFrame("Frame", nil, self)
	Category:SetSize(MENU_BUTTON_WIDTH, WIDGET_HEIGHT)
	Category:SetFrameLevel(self:GetFrameLevel() + 2)
	Category.Descriptor = Descriptor

	local Text = Category:CreateFontString(nil, "OVERLAY")
	Text:SetPoint("LEFT", Category, 5, 0)
	Text:SetSize(MENU_BUTTON_WIDTH - 10, WIDGET_HEIGHT)
	YxUI:SetFontInfo(Text, Settings["ui-widget-font"], Settings["ui-font-size"])
	Text:SetJustifyH("LEFT")
	Text:SetText(format("|cFF%s%s|r", Settings["ui-header-font-color"], name))

	local BG = Category:CreateTexture(nil, "BORDER")
	BG:SetAllPoints()
	BG:SetColorTexture(0, 0, 0)

	local Texture = Category:CreateTexture(nil, "OVERLAY")
	Texture:SetPoint("TOPLEFT", Category, 1, -1)
	Texture:SetPoint("BOTTOMRIGHT", Category, -1, 1)
	Texture:SetTexture(Assets:GetTexture("Blank"))
	Texture:SetVertexColor(YxUI:HexToRGB(Settings["ui-header-texture-color"]))

	Category.Text = Text
	Category.Texture = Texture
	Descriptor.Frame = Category

	self.TotalSelections = (self.TotalSelections or 0) + 1

	self.SelectionRowsDirty = true

	return Descriptor
end


function GUI:ShowWindow(category, name, parent)
	local Page = type(category) == "table" and category or self:HasButton(category, name, parent)

	if not Page then
		error(format("Unknown GUI page '%s/%s'", tostring(category), tostring(name)), 2)
	end

	local Button = Page.Button
	local PreviousPage = self.ActivePage
	if PreviousPage and PreviousPage ~= Page then
		for _, dialog in pairs({self.ImportWindow, self.ExportWindow}) do
			if dialog then dialog:Hide() end
		end
	end

	if PreviousPage then
		if PreviousPage.Window then
			if PreviousPage ~= Page then
				self.WidgetCore.DismissWindowControllers(PreviousPage.Window)
			end
			PreviousPage.Window:Hide()
		end

		if PreviousPage.Button.Selected:GetAlpha() > 0 then
			PreviousPage.Button.Selected:SetAlpha(0)
		end
	end

	if not Page.Window or Page.WindowNeedsRebuild then
		local previous = Page.Window
		local replacement = self:CreateWidgetWindow(Page)
		Page.Window = replacement
		Page.WindowNeedsRebuild = nil
		if previous then
			previous:Hide()
			self.WidgetCore.UnregisterWindow(previous)
		end
	end

	if Page.Parent then
		local ParentPage = Page.Parent

		if not ParentPage.Expanded then
			self:SetPageExpanded(ParentPage, true)
		end

		if ParentPage.Window then
			ParentPage.Window:Hide()
		end

		if ParentPage.Button.Selected:GetAlpha() > 0 then
			ParentPage.Button.Selected:SetAlpha(0)
		end
	end

	Button.Selected:SetAlpha(SELECTED_HIGHLIGHT_ALPHA)
	Page.Window:Show()
	self.ActivePage = Page

	self:ScrollSelections()

	--CloseLastDropdown()
end

local WindowButtonOnEnter = function(self)
	self.Highlight:SetAlpha(MOUSEOVER_HIGHLIGHT_ALPHA)
end

local WindowButtonOnLeave = function(self)
	self.Highlight:SetAlpha(0)
end

local WindowButtonOnMouseUp = function(self)
	self.Text:ClearAllPoints()
	self.Text:SetPoint("LEFT", self, 4, 0)

	GUI:ShowWindow(self.Page)
end

local WindowButtonOnMouseDown = function(self)
	self.Text:ClearAllPoints()
	self.Text:SetPoint("LEFT", self, 6, -1)
end

local WindowSubButtonOnMouseUp = function(self)
	self.Text:ClearAllPoints()
	self.Text:SetPoint("LEFT", self, SPACING * 3, 0)

	GUI:ShowWindow(self.Page)
end

local WindowSubButtonOnMouseDown = function(self)
	self.Text:ClearAllPoints()
	self.Text:SetPoint("LEFT", self, (SPACING * 3) + 2, -1)
end

function GUI:CreateWindow(page)
	if page.Button then
		return page
	end
	if page.Parent and (not page.Parent.Defined) then
		error(format("GUI page '%s/%s' references missing parent '%s'", page.Category.Name, page.Name, page.Parent.Name), 2)
	end

	local Category = self:CreateCategory(page.Category.Name)

	local Button = CreateFrame("Frame", nil, self)
	Button:SetSize(MENU_BUTTON_WIDTH, WIDGET_HEIGHT)
	Button:SetFrameLevel(self:GetFrameLevel() + 2)
	Button.Page = page
	Button:SetScript("OnEnter", WindowButtonOnEnter)
	Button:SetScript("OnLeave", WindowButtonOnLeave)

	Button.Selected = Button:CreateTexture(nil, "ARTWORK")
	Button.Selected:SetPoint("TOPLEFT", Button, 1, -1)
	Button.Selected:SetPoint("BOTTOMRIGHT", Button, -1, 1)
	Button.Selected:SetTexture(Assets:GetTexture("Blank"))
	Button.Selected:SetAlpha(0)

	Button.Highlight = Button:CreateTexture(nil, "ARTWORK")
	Button.Highlight:SetPoint("TOPLEFT", Button, 1, -1)
	Button.Highlight:SetPoint("BOTTOMRIGHT", Button, -1, 1)
	Button.Highlight:SetTexture(Assets:GetTexture("Blank"))
	Button.Highlight:SetVertexColor(1, 1, 1, 0.4)
	Button.Highlight:SetAlpha(0)

	Button.Text = Button:CreateFontString(nil, "OVERLAY")
	Button.Text:SetSize(MENU_BUTTON_WIDTH - 6, WIDGET_HEIGHT)
	Button.Text:SetJustifyH("LEFT")

	if page.Parent then
		Button:SetScript("OnMouseUp", WindowSubButtonOnMouseUp)
		Button:SetScript("OnMouseDown", WindowSubButtonOnMouseDown)

		Button.Selected:SetVertexColor(YxUI:HexToRGB(Settings["ui-widget-color"]))

		Button.Text:SetPoint("LEFT", Button, SPACING * 3, 0)
		YxUI:SetFontInfo(Button.Text, Settings["ui-widget-font"], 12)
		Button.Text:SetText("|cFF" .. Settings["ui-widget-font-color"] .. page.Name .. "|r")
	else
		Button:SetScript("OnMouseUp", WindowButtonOnMouseUp)
		Button:SetScript("OnMouseDown", WindowButtonOnMouseDown)

		Button.Selected:SetVertexColor(YxUI:HexToRGB(Settings["ui-widget-bright-color"]))

		Button.Text:SetPoint("LEFT", Button, 4, 0)
		YxUI:SetFontInfo(Button.Text, Settings["ui-widget-font"], Settings["ui-header-font-size"])
		Button.Text:SetText("|cFF" .. Settings["ui-button-font-color"] .. page.Name .. "|r")

		self.TotalSelections = (self.TotalSelections or 0) + 1
	end

	page.Button = Button

	if (not page.Parent) and (#page.Children > 0) then
		Button.Arrow = Button:CreateTexture(nil, "OVERLAY")
		Button.Arrow:SetPoint("RIGHT", Button, -3, -1)
		Button.Arrow:SetSize(16, 16)
		Button.Arrow:SetTexture(Assets:GetTexture("Arrow Down"))
		Button.Arrow:SetVertexColor(YxUI:HexToRGB(Settings["ui-widget-color"]))

		local Expand = CreateFrame("Button", nil, Button)
		Expand:SetSize(20, WIDGET_HEIGHT)
		Expand:SetPoint("RIGHT", Button, "RIGHT", 0, 0)
		Expand:SetFrameLevel(Button:GetFrameLevel() + 1)
		Expand:SetScript("OnClick", function()
			GUI:TogglePage(page)
		end)
		Expand:SetScript("OnEnter", function()
			Button.Highlight:SetAlpha(MOUSEOVER_HIGHLIGHT_ALPHA)
			Button.Arrow:SetVertexColor(YxUI:HexToRGB(Settings["ui-widget-bright-color"]))
		end)
		Expand:SetScript("OnLeave", function()
			Button.Highlight:SetAlpha(0)
			Button.Arrow:SetVertexColor(YxUI:HexToRGB(Settings["ui-widget-color"]))
		end)
		Button.Expand = Expand
	end

	self.SelectionRowsDirty = true
	return page
end


function GUI:ScrollSelections()
	local RowsChanged = self.SelectionRowsDirty

	if RowsChanged then
		local Rows = {}
		local Categories = self.CategoryOrder

		for i = 1, #Categories do
			local Category = Categories[i]
			tinsert(Rows, Category.Frame)

			for j = 1, #Category.Pages do
				local Page = Category.Pages[j]

				tinsert(Rows, Page.Button)

				if Page.Expanded then
					for o = 1, #Page.Children do
						tinsert(Rows, Page.Children[o].Button)
					end
				end
			end
		end

		self.ScrollButtons = Rows
		self.TotalSelections = #Rows
		self.SelectionRowsDirty = false
	end

	if RowsChanged then
		self.SelectionViewport:SetScrollRange(#self.ScrollButtons)
	end

	self.SelectionViewport.Rows = self.ScrollButtons
	self.SelectionViewport.TotalRows = #self.ScrollButtons
	self.SelectionViewport:SetOffset(self.Offset, RowsChanged)
	self.LastRenderedSelectionOffset = self.SelectionViewport.LastRenderedOffset
end

-- Index widget labels without constructing their frames. Page callbacks already describe
-- each control; a lightweight recorder reads only the search metadata.
local SEARCH_VISIBLE = 8
local SEARCH_ROW_HEIGHT = 25
local SEARCH_LABEL_ARGUMENT = {
	CreateSwitch = 3, CreateCheckbox = 3, CreateSlider = 6,
	CreateDropdown = 4, CreateColorSelection = 3, CreateInput = 3,
	CreateTagInput = 3, CreateInputWithButton = 4, CreateButton = 3,
	CreateStatusBar = 5,
}
local function SearchMatches(entry, query)
	for word in query:lower():gmatch("%S+") do
		if not entry.SearchText:find(word, 1, true) and not entry.CompactText:find(word:gsub("%s+", ""), 1, true) then
			return false
		end
	end
	return true
end

function GUI:InvalidateSettingsSearchIndex()
	self.SearchGeneration = (self.SearchGeneration or 0) + 1
	self.SearchIndexReady = false
end

local function CollectPageSettings(page, entries)
	local path = page.Category.Name .. " / " .. (page.Parent and (page.Parent.Name .. " / ") or "") .. page.Name
	local callbacks = page.Callbacks
	if not callbacks then return end

	local function MakeRecorder(column)
		local recorder = {}
		setmetatable(recorder, {__index = function(_, method)
			return function(_, ...)
				local position = SEARCH_LABEL_ARGUMENT[method]
				if position then
					local id = select(1, ...)
					local label = select(position, ...)
					if type(id) == "string" and id ~= "" and type(label) == "string" and label ~= "" then
						local search = (path .. " " .. label .. " " .. id):lower()
						entries[#entries + 1] = {
							Label = label, ID = id, Column = column,
							Path = path, Page = page, SearchText = search,
							CompactText = search:gsub("%s+", ""),
						}
					end
				end
				return recorder
			end
		end})
		return recorder
	end

	local left, right = MakeRecorder("Left"), MakeRecorder("Right")
	for i = 1, #callbacks do
		-- Third-party callbacks may assume a real frame. Do not break search if
		-- one cannot be inspected without constructing its page.
		pcall(callbacks[i], left, right)
	end

	-- Include widgets added directly to a page that's already been built.
	if page.Window then
		for _, column in ipairs({"Left", "Right"}) do
			local widgets = page.Window[column .. "Widgets"] or {}
			for i = 1, #widgets do
				local anchor = widgets[i]
				if type(anchor.ID) == "string" and anchor.ID ~= "" and type(anchor.Text) == "string" and anchor.Text ~= "" then
					local found
					for j = 1, #entries do
						local entry = entries[j]
						if entry.Page == page and entry.ID == anchor.ID and entry.Column == column then
							found = true
							break
						end
					end
					if not found then
						local search = (path .. " " .. anchor.Text .. " " .. anchor.ID):lower()
						entries[#entries + 1] = {
							Label = anchor.Text, ID = anchor.ID, Column = column,
							Path = path, Page = page, SearchText = search,
							CompactText = search:gsub("%s+", ""),
						}
					end
				end
			end
		end
	end
end

function GUI:BuildSettingsSearchIndex()
	if self.SearchIndexReady or self.SearchIndexBuilding then return end
	self.SearchIndexBuilding = true
	local generation = self.SearchGeneration or 0
	local pages = {}
	for i = 1, #self.CategoryOrder do
		local category = self.CategoryOrder[i]
		for j = 1, #category.Pages do
			local parent = category.Pages[j]
			pages[#pages + 1] = parent
			for k = 1, #parent.Children do
				pages[#pages + 1] = parent.Children[k]
			end
		end
	end
	local entries, index = {}, 1
	local function BuildBatch()
		if generation ~= (GUI.SearchGeneration or 0) then
			GUI.SearchIndexBuilding = nil
			GUI:BuildSettingsSearchIndex()
			return
		end
		for _ = 1, 4 do
			local page = pages[index]
			if not page then break end
			CollectPageSettings(page, entries)
			index = index + 1
		end
		if index <= #pages then
			C_Timer.After(0, BuildBatch)
			return
		end
		table.sort(entries, function(a, b)
			if a.Path == b.Path then return a.Label < b.Label end
			return a.Path < b.Path
		end)
		local known = {}
		for i = 1, #entries do known[entries[i].ID] = true end
		GUI.SearchEntries = entries
		GUI.SearchKnownWidgetIDs = known
		GUI.SearchIndexReady = true
		GUI.SearchIndexBuilding = nil
		GUI:UpdateSettingsSearch()
	end
	BuildBatch()
end

function GUI:OpenSettingsSearchResult(entry)
	self.SearchPanel:Hide()
	self.SearchBox:ClearFocus()
	self.SearchBox:SetText("")
	self:ShowWindow(entry.Page)
	local window = entry.Page.Window
	local widgets = (entry.Column == "Right") and window.RightWidgets or window.LeftWidgets
	local anchor, rowIndex
	for i = 1, #widgets do
		if widgets[i].ID == entry.ID then
			anchor, rowIndex = widgets[i], i
			break
		end
	end
	if not anchor then return end
	window.RowViewport:SetOffset(math.max(1, rowIndex - 4))

	for index, row in ipairs(self.ScrollButtons) do
		if row == entry.Page.Button then
			self.SelectionViewport:SetOffset(math.max(1, index - 4))
			break
		end
	end

	if not anchor.SearchHighlight then
		local highlight = anchor:CreateTexture(nil, "OVERLAY")
		highlight:SetAllPoints()
		highlight:SetTexture(Assets:GetTexture("Blank"))
		highlight:SetVertexColor(YxUI:HexToRGB(Settings["ui-widget-color"]))
		highlight:SetAlpha(0.22)
		anchor.SearchHighlight = highlight
	end
	anchor.SearchHighlight:Show()
	C_Timer.After(1.5, function() if anchor.SearchHighlight then anchor.SearchHighlight:Hide() end end)
end

function GUI:UpdateSettingsSearch()
	if not self.SearchBox then return end
	local query = (self.SearchBox:GetText() or ""):match("^%s*(.-)%s*$")
	self.SearchPlaceholder:SetShown(query == "")
	if #query < 2 then
		self.SearchPanel:Hide()
		return
	end
	local Panel = self.SearchPanel
	Panel:Show()
	if not self.SearchIndexReady then
		self.SearchMatches = {}
		Panel.Status:SetText(Language["Indexing settings..."])
		for i = 1, SEARCH_VISIBLE do Panel.Rows[i]:Hide() end
		Panel:SetHeight(27)
		self:BuildSettingsSearchIndex()
		return
	end

	local matches = {}
	for i = 1, #self.SearchEntries do
		local entry = self.SearchEntries[i]
		if SearchMatches(entry, query) then matches[#matches + 1] = entry end
	end
	self.SearchMatches = matches
	self.SearchOffset = math.max(1, math.min(self.SearchOffset or 1, math.max(1, #matches - SEARCH_VISIBLE + 1)))
	for i = 1, SEARCH_VISIBLE do
		local row = Panel.Rows[i]
		local entry = matches[self.SearchOffset + i - 1]
		row.Entry = entry
		if entry then
			row.Label:SetText(entry.Label)
			row.Path:SetText(entry.Page.Name)
			row:Show()
		else
			row:Hide()
		end
	end
	local shown = math.min(#matches, SEARCH_VISIBLE)
	Panel:SetHeight(shown * SEARCH_ROW_HEIGHT + 26)
	Panel.Status:SetText(#matches == 0 and Language["No matching settings"] or (Language["%d matching settings  |  Mouse wheel to scroll"]):format(#matches))
end

function GUI:CreateSettingsSearch()
	local Input = CreateFrame("EditBox", nil, self.Header, "BackdropTemplate")
	Input:SetSize(182, 18)
	Input:SetPoint("RIGHT", self.Header, "RIGHT", -27, 0)
	Input:SetBackdrop(YxUI.BackdropAndBorder)
	Input:SetBackdropColor(YxUI:HexToRGB(Settings["ui-window-main-color"]))
	Input:SetBackdropBorderColor(0, 0, 0)
	Input:SetAutoFocus(false)
	Input:SetMaxLetters(80)
	Input:SetTextInsets(6, 6, 0, 0)
	YxUI:SetFontInfo(Input, Settings["ui-widget-font"], Settings["ui-font-size"])
	self.SearchBox = Input

	local Placeholder = Input:CreateFontString(nil, "OVERLAY")
	Placeholder:SetPoint("LEFT", Input, 6, 0)
	YxUI:SetFontInfo(Placeholder, Settings["ui-widget-font"], Settings["ui-font-size"])
	Placeholder:SetTextColor(0.65, 0.65, 0.65)
	Placeholder:SetText(Language["Search settings..."])
	self.SearchPlaceholder = Placeholder

	local Panel = CreateFrame("Frame", nil, self, "BackdropTemplate")
	Panel:SetWidth(390)
	Panel:SetPoint("TOPRIGHT", Input, "BOTTOMRIGHT", 0, -3)
	Panel:SetFrameStrata("DIALOG")
	Panel:SetBackdrop(YxUI.BackdropAndBorder)
	Panel:SetBackdropColor(YxUI:HexToRGB(Settings["ui-window-main-color"]))
	Panel:SetBackdropBorderColor(0, 0, 0)
	Panel:EnableMouse(true)
	Panel.Rows = {}
	self.SearchPanel = Panel
	self.SearchOffset = 1

	for i = 1, SEARCH_VISIBLE do
		local Row = CreateFrame("Button", nil, Panel)
		Row:SetHeight(SEARCH_ROW_HEIGHT)
		Row:SetPoint("TOPLEFT", Panel, "TOPLEFT", 4, -((i - 1) * SEARCH_ROW_HEIGHT) - 3)
		Row:SetPoint("TOPRIGHT", Panel, "TOPRIGHT", -4, -((i - 1) * SEARCH_ROW_HEIGHT) - 3)
		Row:SetHighlightTexture(Assets:GetTexture("Blank"))
		Row:SetScript("OnClick", function(button)
			if button.Entry then GUI:OpenSettingsSearchResult(button.Entry) end
		end)
		local Label = Row:CreateFontString(nil, "OVERLAY")
		Label:SetPoint("LEFT", Row, 5, 0)
		Label:SetWidth(260)
		Label:SetJustifyH("LEFT")
		YxUI:SetFontInfo(Label, Settings["ui-widget-font"], Settings["ui-font-size"])
		Row.Label = Label
		local Path = Row:CreateFontString(nil, "OVERLAY")
		Path:SetPoint("RIGHT", Row, -5, 0)
		Path:SetWidth(112)
		Path:SetJustifyH("RIGHT")
		Path:SetTextColor(0.7, 0.7, 0.7)
		YxUI:SetFontInfo(Path, Settings["ui-widget-font"], Settings["ui-font-size"])
		Row.Path = Path
		Panel.Rows[i] = Row
	end
	Panel.Status = Panel:CreateFontString(nil, "OVERLAY")
	Panel.Status:SetPoint("BOTTOMLEFT", Panel, 9, 5)
	YxUI:SetFontInfo(Panel.Status, Settings["ui-widget-font"], Settings["ui-font-size"])
	Panel.Status:SetTextColor(0.75, 0.75, 0.75)
	Panel:EnableMouseWheel(true)
	Panel:SetScript("OnMouseWheel", function(_, delta)
		local maximum = math.max(1, #(GUI.SearchMatches or {}) - SEARCH_VISIBLE + 1)
		GUI.SearchOffset = math.max(1, math.min(maximum, (GUI.SearchOffset or 1) - delta))
		GUI:UpdateSettingsSearch()
	end)
	Input:SetScript("OnTextChanged", function() GUI.SearchOffset = 1; GUI:UpdateSettingsSearch() end)
	Input:SetScript("OnEscapePressed", function(box) box:SetText(""); box:ClearFocus(); Panel:Hide() end)
	Input:SetScript("OnEnterPressed", function(box)
		local entry = GUI.SearchMatches and GUI.SearchMatches[GUI.SearchOffset]
		if entry then GUI:OpenSettingsSearchResult(entry) else box:ClearFocus() end
	end)
	Input:SetScript("OnEditFocusGained", function() GUI:UpdateSettingsSearch() end)
	Input:SetScript("OnEditFocusLost", function() if Input:GetText() == "" then Panel:Hide() end end)
	Panel:Hide()
end
