local YxUI, Language, Assets, Settings = select(2, ...):get()
local GUI = YxUI:GetModule("GUI")
-- Unit Frames is registered after GUI files in the addon manifests.
local function GetUnitFrames()
	return YxUI:GetModule("Unit Frames")
end

local Builder = {Width = 422, Height = 395}
GUI.TagBuilder = Builder

local PillWidth = Builder.Width - GUI.WidgetCore.SPACING * 4
local PanelPadding = 4
local HorizontalPadding = PanelPadding - 1
local ButtonGap = 2
local CatalogButtonGap = 2
local ScrollbarWidth = 16
local ScrollbarGap = 2
local ScrollbarLane = ScrollbarWidth + ScrollbarGap
local CatalogColumns = 3
local CatalogHeight = 165
local CatalogWidth = PillWidth - ScrollbarLane
local CatalogButtonWidth = math.floor((CatalogWidth - HorizontalPadding * 2 - CatalogButtonGap * (CatalogColumns - 1)) / CatalogColumns)
local CatalogLastButtonWidth = CatalogWidth - HorizontalPadding * 2 - CatalogButtonGap * (CatalogColumns - 1) - CatalogButtonWidth * (CatalogColumns - 1)
local CatalogStep = CatalogButtonWidth + CatalogButtonGap

local TagDescriptions = {
	["+ Text"] = Language["Adds your own text."],
	Classification = Language["Rare, Elite, or Rare Elite."],
	ColorStop = Language["Resets text color."],
	GroupStatus = Language["Colored health number (82), or unit status."],
	HappinessColor = Language["Sets text color by pet happiness."],
	Health = Language["Current health (e.g. 850)."],
	["Health:Short"] = Language["Shortened health (e.g. 12.5K)."],
	HealthColor = Language["Sets text color by health level."],
	HealthDeficit = Language["Missing health (-2500), or status; blank when full."],
	["HealthDeficit:Short"] = Language["Shortened missing health (-2.5K), or status; blank when full."],
	HealthPercent = Language["Health percentage (e.g. 82.5%)."],
	HealthValues = Language["Current / maximum health (e.g. 850 / 1000)."],
	["HealthValues:Short"] = Language["Shortened current / maximum health (e.g. 8K / 10K)."],
	Level = Language["Unit level (e.g. 60), or Boss / ??."],
	LevelColor = Language["Sets text color by level difficulty."],
	LevelPlus = Language["Level with rare/elite marker (e.g. 60+)."],
	Name = Language["Unit name; optional length limit."],
	NameColor = Language["Sets text color by class or reaction."],
	PartyIndex = Language["Party number (your character is 1)."],
	PetColor = Language["Sets text color by pet happiness or reaction."],
	Plus = Language["Rare/elite marker (R, +, or R+)."],
	Power = Language["Current resource (e.g. 85); blank at zero."],
	["Power:Short"] = Language["Shortened resource (e.g. 2.5K); blank at zero."],
	PowerColor = Language["Sets text color by resource type."],
	PowerPercent = Language["Resource percentage (e.g. 75%); blank at zero."],
	PowerValues = Language["Current / maximum resource (e.g. 60 / 100)."],
	["PowerValues:Short"] = Language["Shortened current / maximum resource (e.g. 2K / 3K)."],
	RaidGroup = Language["Raid group number (1–8)."],
	RaidIndex = Language["Raid roster number (1–40)."],
	Reaction = Language["Sets text color by friendly or hostile reaction."],
	Resting = Language["Shows zZz while resting."],
	ShortClassification = Language["Rare/elite marker (R, +, or R+)."],
	Space = Language["Adds one space."],
	Status = Language["Dead, Ghost, Offline, or AFK when applicable."],
}

local function TagDescription(name)
	local limit = name:match("^Name(%d+)$")
	return TagDescriptions[name] or (limit and format(Language["First %s characters of the unit name."], limit)) or format(Language["Displays %s"], name)
end

local function FitLabel(font, label, width)
	font:SetText(label)
	if font:GetStringWidth() <= width then
		return label
	end
	while #label > 1 do
		label = label:sub(1, -2)
		font:SetText(label .. "...")
		if font:GetStringWidth() <= width then
			return label .. "..."
		end
	end
	font:SetText("...")
	return "..."
end

-- Keep literal segments (including spaces and |r) and all existing tag tokens intact.
function Builder.Parse(expression)
	local parts, cursor = {}, 1
	expression = expression or ""
	while cursor <= #expression do
		local first, last = expression:find("%b[]", cursor)
		if not first then
			parts[#parts + 1] = {kind = "text", value = expression:sub(cursor)}
			break
		end
		if first > cursor then
			parts[#parts + 1] = {kind = "text", value = expression:sub(cursor, first - 1)}
		end
		parts[#parts + 1] = {kind = "tag", value = expression:sub(first, last)}
		cursor = last + 1
	end
	return parts
end

function Builder.Compose(parts)
	local values = {}
	for i = 1, #parts do
		values[i] = parts[i].value
	end
	return table.concat(values)
end

local function PreviewUnit(input)
	local id = input and input.ID or ""
	local unit = id:match("^unitframes%-([%w]+)%-")
	if unit == "boss" then
		unit = "boss1"
	elseif id:match("^party%-") then
		unit = "party1"
	elseif id:match("^raid%-") then
		unit = "raid1"
	elseif id:match("^nameplates%-") then
		unit = "target"
	end
	unit = unit or "player"
	return UnitExists(unit) and unit or "player", unit
end

local function Font(parent, text, size)
	local font = parent:CreateFontString(nil, "OVERLAY")
	YxUI:SetFontInfo(font, Settings["ui-widget-font"], size or Settings["ui-font-size"])
	font:SetJustifyH("LEFT")
	font:SetText(text or "")
	return font
end

-- Use the same backdrop/border renderer as YxUI's other GUI panels.
function Builder.StyleDialog(window)
	window:SetBackdrop(YxUI.BackdropAndBorder)
	window:SetBackdropColor(YxUI:HexToRGB(Settings["ui-window-bg-color"]))
	window:SetBackdropBorderColor(0, 0, 0)
	window.Header:SetBackdrop(YxUI.BackdropAndBorder)
	window.Header:SetBackdropColor(0, 0, 0)
	window.Header:SetBackdropBorderColor(0, 0, 0)
	window.Inner:SetBackdrop(YxUI.BackdropAndBorder)
	window.Inner:SetBackdropColor(YxUI:HexToRGB(Settings["ui-window-main-color"]))
	window.Inner:SetBackdropBorderColor(0, 0, 0)
end

-- Dragging can leave a one-pixel border between physical pixels at fractional UI
-- scales. Snap the *dialog* (not every child border) when movement finishes.
function Builder.AlignDialog(window)
	local parent = YxUI.UIParent
	local scale = window:GetEffectiveScale()
	local parentScale = parent:GetEffectiveScale()
	if not scale or scale <= 0 or not parentScale or parentScale <= 0 then
		return
	end

	local left, top = window:GetLeft(), window:GetTop()
	local parentLeft, parentTop = parent:GetLeft(), parent:GetTop()
	if not left or not top or not parentLeft or not parentTop then
		return
	end

	local function Round(value)
		return math.floor(value + 0.5)
	end

	-- Give both window edges whole-pixel coordinates at the current UI scale.
	local width, height = Round(window:GetWidth() * scale) / scale, Round(window:GetHeight() * scale) / scale
	local x = (Round(left * scale) - Round(parentLeft * parentScale)) / parentScale
	local y = (Round(top * scale) - Round(parentTop * parentScale)) / parentScale
	window:ClearAllPoints()
	window:SetSize(width, height)
	window:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
end

local function Panel(parent)
	local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	frame:SetBackdrop(YxUI.BackdropAndBorder)
	frame:SetBackdropColor(YxUI:HexToRGB(Settings["ui-widget-bg-color"]))
	frame:SetBackdropBorderColor(0, 0, 0)
	return frame
end

local function Button(parent, label, width, height, action)
	local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
	button:SetSize(width, height)
	button:SetBackdrop(YxUI.BackdropAndBorder)
	button:SetBackdropColor(YxUI:HexToRGB(Settings["ui-widget-bright-color"]))
	button:SetBackdropBorderColor(0, 0, 0)
	button.Texture = button:CreateTexture(nil, "BORDER")
	button.Texture:SetPoint("TOPLEFT", button, 1, -1)
	button.Texture:SetPoint("BOTTOMRIGHT", button, -1, 1)
	button.Texture:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	button.Texture:SetVertexColor(YxUI:HexToRGB(Settings["ui-widget-bright-color"]))
	button.Text = Font(button, label)
	button.Text:SetPoint("CENTER", button, 0, 0)
	button.Text:SetJustifyH("CENTER")
	button.Highlight = button:CreateTexture(nil, "ARTWORK")
	button.Highlight:SetPoint("TOPLEFT", button, 1, -1)
	button.Highlight:SetPoint("BOTTOMRIGHT", button, -1, 1)
	button.Highlight:SetTexture(Assets:GetTexture("Blank"))
	button.Highlight:SetVertexColor(1, 1, 1, 0.4)
	button.Highlight:SetAlpha(0)
	button:SetScript("OnMouseDown", function(self)
		local r, g, b = YxUI:HexToRGB(Settings["ui-widget-bright-color"])
		self.Texture:SetVertexColor(r * 0.85, g * 0.85, b * 0.85)
	end)
	button:SetScript("OnMouseUp", function(self)
		self.Texture:SetVertexColor(YxUI:HexToRGB(Settings["ui-widget-bright-color"]))
	end)
	button:SetScript("OnEnter", function(self)
		if self.UpdateHighlight then
			self:UpdateHighlight()
		else
			self.Highlight:SetAlpha(GUI.WidgetCore.MOUSEOVER_HIGHLIGHT_ALPHA)
		end
	end)
	button:SetScript("OnLeave", function(self)
		if self.UpdateHighlight then
			self:UpdateHighlight()
		else
			self.Highlight:SetAlpha(0)
		end
	end)
	button:SetScript("OnClick", action)
	return button
end

local function Move(parts, from, to)
	if not from or to < 1 or to > #parts or from == to then
		return false
	end
	local part = table.remove(parts, from)
	table.insert(parts, to, part)
	return true
end

local function DisplayPart(part)
	if part.kind == "text" then
		if part.value == "|r" then
			return Language["Color reset"]
		end
		local display = part.value:gsub("|", "||")
		if #display > 20 then
			display = display:sub(1, 18) .. "..."
		end
		return format(Language["Text: %s"], display)
	end
	return part.value:sub(2, -2)
end

local function UpdatePreview(self)
	local text = Builder.Compose(self.Parts)
	local UF = GetUnitFrames()
	if not UF or not UF.IsRegisteredTag or not UF.PreviewTag then
		self.Valid = false
		self.Status:SetText("|cFFE7AA67" .. Language["Unit-frame tags are unavailable."] .. "|r")
		self.Status:Show()
		self.Preview:Hide()
		return
	end

	-- Catalog tags are already controlled; check only saved unknown tags and
	-- text fields that could accidentally introduce raw tag syntax.
	local errorText
	for i = 1, #self.Parts do
		local part = self.Parts[i]
		if part.kind == "tag" and not UF.IsRegisteredTag(part.value) then
			errorText = format(Language["Unknown saved tag: %s"], part.value)
			break
		elseif part.kind == "text" and (part.value:find("[", 1, true) or part.value:find("]", 1, true)) then
			errorText = Language["Add tags from Available Tags instead of typing brackets."]
			break
		end
	end

	self.Valid = not errorText
	if errorText then
		self.Status:SetText("|cFFE7AA67" .. errorText .. "|r")
		self.Status:Show()
		self.Preview:Hide()
		return
	end

	self.Status:Hide()
	self.Preview:Show()
	if text == "" then
		self.Preview:SetText(Language["(no text)"])
		return
	end
	local unit = PreviewUnit(self.Window.ActiveInput)
	if not pcall(UF.PreviewTag, self.Preview, text, unit) then
		self.Preview:SetText(Language["Preview unavailable for this unit."])
	end
end

local function UpdateProperties(self)
	local part = self.Parts[self.Selected]
	local nameLimit = part and part.kind == "tag" and (part.value == "[Name]" or part.value:match("^%[Name%(%d+%)%]$"))
	self.SelectionLabel:SetWidth((part and (part.kind == "text" or nameLimit)) and 112 or PillWidth - 64)
	self.EditingProperties = true
	if not part then
		self.SelectionLabel:SetText(Language["Selected: None"])
		self.PropertyLabel:Hide()
		self.PropertyInput:Hide()
		self.PropertyBackground:Hide()
	elseif part.kind == "text" then
		self.SelectionLabel:SetText(Language["Selected: Text"])
		self.PropertyLabel:SetText(Language["Text"])
		self.PropertyLabel:Show()
		self.PropertyInput:SetText(part.value)
		self.PropertyInput:Show()
		self.PropertyBackground:Show()
	elseif nameLimit then
		self.SelectionLabel:SetText(Language["Selected: Name"])
		self.PropertyLabel:SetText(Language["Name length"])
		self.PropertyLabel:Show()
		self.PropertyInput:SetText(part.value:match("^%[Name%((%d+)%)%]$") or "")
		self.PropertyInput:Show()
		self.PropertyBackground:Show()
	else
		self.SelectionLabel:SetText(format(Language["Selected: %s"], DisplayPart(part)))
		self.PropertyLabel:Hide()
		self.PropertyInput:Hide()
		self.PropertyBackground:Hide()
	end
	self.EditingProperties = false
	self.Left:SetEnabled(self.Selected and self.Selected > 1 or false)
	self.Right:SetEnabled(self.Selected and self.Selected < #self.Parts or false)
	local r, g, b = YxUI:HexToRGB(Settings["ui-widget-color"])
	if self.Left:IsEnabled() then
		self.Left.Arrow:SetVertexColor(r, g, b)
	else
		self.Left.Arrow:SetVertexColor(0.65, 0.65, 0.65)
	end
	if self.Right:IsEnabled() then
		self.Right.Arrow:SetVertexColor(r, g, b)
	else
		self.Right.Arrow:SetVertexColor(0.65, 0.65, 0.65)
	end
end

-- Resolve hover from the cursor's actual position: moving pills can skip OnLeave.
local function ContainsCursor(frame, x, y)
	local left, right, top, bottom = frame:GetLeft(), frame:GetRight(), frame:GetTop(), frame:GetBottom()
	return left and right and top and bottom and x >= left and x <= right and y >= bottom and y <= top
end

local function CursorPill(self)
	local scale = self.PillContent:GetEffectiveScale()
	if not scale or scale == 0 then
		return
	end
	local x, y = GetCursorPosition()
	x, y = x / scale, y / scale
	if not self.Scroll:IsShown() or not ContainsCursor(self.Scroll, x, y) then
		return
	end
	for i = 1, #self.Parts do
		local pill = self.Pills[i]
		if pill:IsShown() and ContainsCursor(pill, x, y) then
			return i
		end
	end
end

local function RefreshPillHighlights(self)
	local hovered = CursorPill(self)
	for i = 1, #self.Parts do
		local alpha = 0
		if self.DragIndex == i then
			alpha = 0.38
		elseif hovered == i then
			alpha = 0.24
		elseif self.Selected == i then
			alpha = 0.12
		end
		self.Pills[i].Highlight:SetAlpha(alpha)
	end
end

-- Find the nearest insertion edge, including empty space at the end of a row.
-- The marker is anchored to the candidate pill rather than following the cursor.
local function DropPosition(self)
	if not self.Scroll:IsMouseOver() then
		return
	end
	local scale = self.PillContent:GetEffectiveScale()
	if not scale or scale == 0 then
		return
	end
	local x, y = GetCursorPosition()
	x, y = x / scale, y / scale
	local bestDistance, bestSlot, bestPill, bestSide
	for i = 1, #self.Parts do
		local pill = self.Pills[i]
		if pill:IsShown() then
			local left, right, top, bottom = pill:GetLeft(), pill:GetRight(), pill:GetTop(), pill:GetBottom()
			if left and right and top and bottom then
				local mid = (top + bottom) / 2
				local dy = (y - mid) * 1.5
				local before = (x - left) ^ 2 + dy ^ 2
				local after = (x - right) ^ 2 + dy ^ 2
				if not bestDistance or before < bestDistance then
					bestDistance, bestSlot, bestPill, bestSide = before, i, pill, "LEFT"
				end
				if after < bestDistance then
					bestDistance, bestSlot, bestPill, bestSide = after, i + 1, pill, "RIGHT"
				end
			end
		end
	end
	return bestSlot, bestPill, bestSide
end

local function UpdateDrag(self)
	local slot, pill, side = DropPosition(self)
	self.DropSlot = slot
	if not slot then
		self.DropMarker:Hide()
		return
	end
	if slot ~= self.MarkerSlot or pill ~= self.MarkerPill or side ~= self.MarkerSide then
		self.DropMarker:ClearAllPoints()
		self.DropMarker:SetPoint("CENTER", pill, side, side == "LEFT" and -2 or 2, 0)
		self.MarkerSlot, self.MarkerPill, self.MarkerSide = slot, pill, side
	end
	self.DropMarker:Show()
end

local function StopDragging(self)
	self:SetScript("OnUpdate", nil)
	self.DropMarker:Hide()
	self.DragIndex, self.DropSlot = nil, nil
	self.MarkerSlot, self.MarkerPill, self.MarkerSide = nil, nil, nil
	for i = 1, #self.Parts do
		local pill = self.Pills[i]
		if pill then
			pill.Texture:SetVertexColor(YxUI:HexToRGB(Settings["ui-widget-bright-color"]))
			pill.Highlight:SetAlpha(self.Selected == i and 0.12 or 0)
		end
	end
end

local function UpdatePills(self)
	local x, y, rowHeight = HorizontalPadding, 1 - PanelPadding, 24
	local areaWidth = PillWidth
	for i, part in ipairs(self.Parts) do
		local pill = self.Pills[i]
		if not pill then
			pill = Button(self.PillContent, "", 70, 22, function(button)
				self.Selected = button.Index
				Builder.Refresh(self)
			end)
			pill.UpdateHighlight = function()
				RefreshPillHighlights(self)
			end
			pill:RegisterForDrag("LeftButton")
			pill:SetScript("OnDragStart", function(button)
				self.DragIndex = button.Index
				self.Selected = button.Index
				UpdateProperties(self)
				RefreshPillHighlights(self)
				self:SetScript("OnUpdate", UpdateDrag)
				UpdateDrag(self)
			end)
			pill:SetScript("OnDragStop", function()
				local from = self.DragIndex
				UpdateDrag(self)
				local slot = self.DropSlot
				StopDragging(self)
				if from and slot then
					local to = slot > from and slot - 1 or slot
					if Move(self.Parts, from, to) then
						self.Selected = to
					end
				end
				Builder.Refresh(self)
			end)
			pill.Remove = CreateFrame("Button", nil, pill)
			pill.Remove:SetSize(20, 20)
			pill.Remove:SetPoint("RIGHT", pill, -1, 0)
			pill.Remove.Icon = pill.Remove:CreateTexture(nil, "OVERLAY")
			pill.Remove.Icon:SetSize(16, 16)
			pill.Remove.Icon:SetPoint("CENTER")
			pill.Remove.Icon:SetTexture(Assets:GetTexture("Close"))
			pill.Remove.Icon:SetVertexColor(YxUI:HexToRGB("EEEEEE"))
			pill.Remove:SetScript("OnEnter", function(button)
				button.Icon:SetVertexColor(YxUI:HexToRGB("C0392B"))
			end)
			pill.Remove:SetScript("OnLeave", function(button)
				button.Icon:SetVertexColor(YxUI:HexToRGB("EEEEEE"))
			end)
			pill.Remove:SetScript("OnClick", function(button)
				local index = button:GetParent().Index
				table.remove(self.Parts, index)
				self.Selected = #self.Parts > 0 and math.min(index, #self.Parts) or nil
				Builder.Refresh(self)
			end)
			self.Pills[i] = pill
		end
		local title = DisplayPart(part)
		pill.Text:SetWidth(PillWidth)
		pill.Text:SetText(title)
		pill.Text:ClearAllPoints()
		pill.Text:SetPoint("LEFT", pill, 6, 0)
		pill.Text:SetJustifyH("LEFT")
		pill.Index = i
		local width = math.min(areaWidth - HorizontalPadding * 2, math.max(40, math.ceil(pill.Text:GetStringWidth()) + 27))
		pill:SetWidth(width)
		pill.Text:SetWidth(width - 26)
		if x + width > areaWidth - HorizontalPadding then
			x, y = HorizontalPadding, y - rowHeight
		end
		pill:ClearAllPoints()
		pill:SetPoint("TOPLEFT", self.PillContent, x, y)
		pill:Show()
		x = x + width + ButtonGap
	end
	for i = #self.Parts + 1, #self.Pills do
		self.Pills[i]:Hide()
	end
	self.PillContent:SetHeight(math.max(52, -y + rowHeight + PanelPadding))
	self.Empty:SetShown(#self.Parts == 0)
	RefreshPillHighlights(self)
end

-- Recheck once after layout settles; this is not a continuous update loop.
local function RecheckPillHighlights(self)
	self:SetScript("OnUpdate", nil)
	RefreshPillHighlights(self)
end

function Builder.Refresh(self)
	UpdatePills(self)
	UpdateProperties(self)
	UpdatePreview(self)
	if not self.DragIndex then
		self:SetScript("OnUpdate", RecheckPillHighlights)
	end
end

function Builder.Open(window, expression)
	local self = window.TagBuilder
	self.Parts = Builder.Parse(expression)
	self.Selected = #self.Parts > 0 and 1 or nil
	StopDragging(self)
	self.Scroll:SetVerticalScroll(0)
	Builder.Refresh(self)
end

function Builder.GetText(window)
	local self = window.TagBuilder
	if not self.Valid then
		return nil
	end
	return Builder.Compose(self.Parts)
end

function Builder.Create(window)
	local root = CreateFrame("Frame", nil, window.Inner)
	root:SetPoint("TOPLEFT", window.Inner, GUI.WidgetCore.SPACING, -GUI.WidgetCore.SPACING)
	root:SetPoint("BOTTOMRIGHT", window.Inner, -GUI.WidgetCore.SPACING, GUI.WidgetCore.SPACING)
	root.Window = window
	root.Parts, root.Pills = {}, {}

	local title = Font(root, "|cFFEEEEEESelect to edit or reorder|r")
	title:SetPoint("TOPLEFT", root, 0, 0)

	local function AddText()
		local index = root.Selected and root.Selected + 1 or #root.Parts + 1
		table.insert(root.Parts, index, {kind = "text", value = " "})
		root.Selected = index
		Builder.Refresh(root)
		root.PropertyInput:SetFocus()
	end

	local selectedBox = Panel(root)
	selectedBox:SetPoint("TOPLEFT", root, 0, -23)
	selectedBox:SetPoint("TOPRIGHT", root, 0, -23)
	selectedBox:SetHeight(52)

	root.Scroll = CreateFrame("ScrollFrame", nil, selectedBox)
	root.Scroll:SetPoint("TOPLEFT", selectedBox, 0, 0)
	root.Scroll:SetPoint("BOTTOMRIGHT", selectedBox, 0, 0)
	root.Scroll:EnableMouseWheel(true)
	root.Scroll:SetScript("OnMouseWheel", function(scroll, direction)
		scroll:SetVerticalScroll(math.max(0, math.min(scroll:GetVerticalScroll() - direction * 24, math.max(0, root.PillContent:GetHeight() - scroll:GetHeight()))))
	end)
	root.PillContent = CreateFrame("Frame", nil, root.Scroll)
	root.PillContent:SetWidth(PillWidth)
	root.PillContent:SetHeight(52)
	root.Scroll:SetScrollChild(root.PillContent)

	-- Keep the insertion marker and the existing pill drag behavior unchanged.
	root.DropMarker = CreateFrame("Frame", nil, root.PillContent)
	root.DropMarker:SetSize(10, 26)
	root.DropMarker:SetFrameLevel(root.PillContent:GetFrameLevel() + 5)
	local r, g, b = YxUI:HexToRGB(Settings["ui-widget-color"])
	local stem = root.DropMarker:CreateTexture(nil, "OVERLAY")
	stem:SetSize(2, 21)
	stem:SetPoint("CENTER")
	stem:SetColorTexture(r, g, b)
	for _, direction in ipairs({1, -1}) do
		local spark = root.DropMarker:CreateTexture(nil, "OVERLAY")
		spark:SetSize(8, 2)
		spark:SetPoint("CENTER", root.DropMarker, "CENTER", 0, direction * 11)
		spark:SetColorTexture(r, g, b)
	end
	root.DropMarker:Hide()
	root:SetScript("OnHide", function(self)
		StopDragging(self)
	end)
	root.Empty = Font(selectedBox, Language["Add tags below to build your text"])
	root.Empty:SetPoint("CENTER", selectedBox, 0, 0)
	root.Empty:SetJustifyH("CENTER")

	root.SelectionLabel = Font(root, Language["Selected: None"])
	root.SelectionLabel:SetPoint("TOPLEFT", root, 0, -84)
	root.SelectionLabel:SetWidth(112)

	local function ReorderButton(direction, action)
		local button = Button(root, "", 22, 22, action)
		button.Text:Hide()
		button.Arrow = button:CreateTexture(nil, "OVERLAY")
		button.Arrow:SetSize(16, 16)
		button.Arrow:SetPoint("CENTER")
		button.Arrow:SetTexture(Assets:GetTexture("Arrow " .. direction))
		button.Arrow:SetVertexColor(YxUI:HexToRGB(Settings["ui-widget-color"]))
		return button
	end

	root.Left = ReorderButton("Left", function()
		if Move(root.Parts, root.Selected, (root.Selected or 0) - 1) then
			root.Selected = root.Selected - 1
			Builder.Refresh(root)
		end
	end)
	root.Left:SetPoint("TOPRIGHT", root, -24, -77)
	root.Right = ReorderButton("Right", function()
		if Move(root.Parts, root.Selected, (root.Selected or 0) + 1) then
			root.Selected = root.Selected + 1
			Builder.Refresh(root)
		end
	end)
	root.Right:SetPoint("TOPRIGHT", root, 0, -77)

	root.PropertyLabel = Font(root, Language["Properties"])
	root.PropertyLabel:SetPoint("TOPLEFT", root, 117, -84)
	root.PropertyLabel:SetWidth(87)
	local propertyBg = Panel(root)
	propertyBg:SetSize(88, 22)
	propertyBg:SetPoint("TOPLEFT", root, 205, -80)
	root.PropertyBackground = propertyBg
	root.PropertyInput = CreateFrame("EditBox", nil, propertyBg)
	root.PropertyInput:SetPoint("TOPLEFT", propertyBg, 6, -2)
	root.PropertyInput:SetPoint("BOTTOMRIGHT", propertyBg, -6, 2)
	root.PropertyInput:SetAutoFocus(false)
	root.PropertyInput:SetMaxLetters(255)
	YxUI:SetFontInfo(root.PropertyInput, Settings["ui-widget-font"], Settings["ui-font-size"])
	root.PropertyInput:SetScript("OnEscapePressed", function(edit) edit:ClearFocus() end)
	root.PropertyInput:SetScript("OnEnterPressed", function(edit) edit:ClearFocus() end)
	root.PropertyInput:SetScript("OnTextChanged", function(edit)
		if root.EditingProperties then return end
		local part = root.Parts[root.Selected]
		if not part then return end
		local value = edit:GetText() or ""
		if part.kind == "text" then
			part.value = value
		elseif part.value == "[Name]" or part.value:match("^%[Name%(%d+%)%]$") then
			if value == "" then
				part.value = "[Name]"
			elseif value:match("^[1-9]%d*$") then
				part.value = "[Name(" .. value .. ")]"
			else
				root.Valid = false
				root.Status:SetText("|cFFE7AA67" .. Language["Enter a positive name length."] .. "|r")
				root.Status:Show()
				root.Preview:Hide()
				return
			end
		end
		UpdatePills(root)
		UpdatePreview(root)
	end)
	propertyBg:SetScript("OnEnter", function()
		local part = root.Parts[root.Selected]
		GameTooltip:SetOwner(propertyBg, "ANCHOR_RIGHT")
		GameTooltip:SetText(part and part.kind == "text" and Language["Text between tags"] or Language["Maximum name length (blank for full name)"])
		GameTooltip:Show()
	end)
	propertyBg:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	root.PreviewLabel = Font(root, Language["Live preview"])
	root.PreviewLabel:SetPoint("TOPLEFT", root, 0, -109)
	local previewBox = Panel(root)
	previewBox:SetPoint("TOPLEFT", root, 0, -127)
	previewBox:SetPoint("TOPRIGHT", root, 0, -127)
	previewBox:SetHeight(GUI.WidgetCore.WIDGET_HEIGHT)
	root.Preview = Font(previewBox, "")
	root.Preview:SetPoint("TOPLEFT", previewBox, 7, -2)
	root.Preview:SetPoint("BOTTOMRIGHT", previewBox, -7, 2)
	root.Preview:SetJustifyV("MIDDLE")

	root.Status = Font(previewBox, "")
	root.Status:SetPoint("TOPLEFT", previewBox, 7, -2)
	root.Status:SetPoint("BOTTOMRIGHT", previewBox, -7, 2)
	root.Status:SetJustifyV("MIDDLE")
	root.Status:Hide()

	local catalogLabel = Font(root, "|cFFEEEEEE" .. Language["Available Tags"] .. "|r")
	catalogLabel:SetPoint("TOPLEFT", root, 0, -153)

	local catalogBox = Panel(root)
	catalogBox:SetPoint("TOPLEFT", root, 0, -172)
	catalogBox:SetPoint("TOPRIGHT", root, -ScrollbarLane, -172)
	catalogBox:SetHeight(CatalogHeight)

	root.CatalogScroll = CreateFrame("ScrollFrame", nil, catalogBox)
	root.CatalogScroll:SetPoint("TOPLEFT", catalogBox, 0, 0)
	root.CatalogScroll:SetPoint("BOTTOMRIGHT", catalogBox, 0, 0)
	root.CatalogScroll:EnableMouseWheel(true)
	root.CatalogContent = CreateFrame("Frame", nil, root.CatalogScroll)
	root.CatalogContent:SetWidth(CatalogWidth)
	root.CatalogScroll:SetScrollChild(root.CatalogContent)

	-- Use the same scrollbar artwork and arrow controls as YxUI's settings pages.
	local catalogSlider = CreateFrame("Slider", nil, root, "BackdropTemplate")
	catalogSlider:SetWidth(ScrollbarWidth)
	GUI:StyleVerticalSlider(catalogSlider, {Highlight = true, ProgressAlpha = 0.25})
	catalogSlider:SetBackdrop(YxUI.BackdropAndBorder)
	catalogSlider:SetBackdropColor(YxUI:HexToRGB(Settings["ui-window-main-color"]))
	catalogSlider:SetBackdropBorderColor(0, 0, 0)

	local function ScrollArrow(direction, anchor, delta)
		local arrow = CreateFrame("Frame", nil, root, "BackdropTemplate")
		arrow:SetSize(ScrollbarWidth, 20)
		arrow:SetPoint(anchor, catalogBox, anchor, ScrollbarLane, 0)
		arrow:SetBackdrop(YxUI.BackdropAndBorder)
		arrow:SetBackdropColor(0, 0, 0, 0)
		arrow:SetBackdropBorderColor(0, 0, 0)
		arrow.Texture = arrow:CreateTexture(nil, "ARTWORK")
		arrow.Texture:SetPoint("TOPLEFT", arrow, 1, -1)
		arrow.Texture:SetPoint("BOTTOMRIGHT", arrow, -1, 1)
		arrow.Texture:SetTexture(Assets:GetTexture(Settings["ui-header-texture"]))
		arrow.Texture:SetVertexColor(YxUI:HexToRGB(Settings["ui-widget-bright-color"]))
		arrow.Highlight = arrow:CreateTexture(nil, "HIGHLIGHT")
		arrow.Highlight:SetPoint("TOPLEFT", arrow, 1, -1)
		arrow.Highlight:SetPoint("BOTTOMRIGHT", arrow, -1, 1)
		arrow.Highlight:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
		arrow.Highlight:SetVertexColor(1, 1, 1)
		arrow.Highlight:SetAlpha(0.25)
		arrow.Arrow = arrow:CreateTexture(nil, "OVERLAY")
		arrow.Arrow:SetPoint("CENTER", arrow, 0, 0)
		arrow.Arrow:SetSize(16, 16)
		arrow.Arrow:SetTexture(Assets:GetTexture("Arrow " .. direction))
		arrow:SetScript("OnMouseDown", function(self)
			local r, g, b = YxUI:HexToRGB(Settings["ui-widget-bright-color"])
			self.Texture:SetVertexColor(r * 0.85, g * 0.85, b * 0.85)
		end)
		arrow:SetScript("OnMouseUp", function(self)
			self.Texture:SetVertexColor(YxUI:HexToRGB(Settings["ui-widget-bright-color"]))
			catalogSlider:SetValue(catalogSlider:GetValue() + delta)
		end)
		return arrow
	end

	local scrollUp = ScrollArrow("Up", "TOPRIGHT", -44)
	local scrollDown = ScrollArrow("Down", "BOTTOMRIGHT", 44)
	catalogSlider:SetPoint("TOPLEFT", scrollUp, "BOTTOMLEFT", 0, -2)
	catalogSlider:SetPoint("BOTTOMRIGHT", scrollDown, "TOPRIGHT", 0, 2)
	catalogSlider:SetMinMaxValues(0, 0)
	catalogSlider:SetValueStep(1)
	catalogSlider:SetScript("OnValueChanged", function(slider, value)
		local _, maximum = slider:GetMinMaxValues()
		root.CatalogScroll:SetVerticalScroll(value)
		local r, g, b = YxUI:HexToRGB(Settings["ui-widget-color"])
		if value <= 0 then
			scrollUp.Arrow:SetVertexColor(0.65, 0.65, 0.65)
		else
			scrollUp.Arrow:SetVertexColor(r, g, b)
		end
		if value >= maximum then
			scrollDown.Arrow:SetVertexColor(0.65, 0.65, 0.65)
		else
			scrollDown.Arrow:SetVertexColor(r, g, b)
		end
	end)
	local function ScrollCatalogWheel(_, direction)
		local _, maximum = catalogSlider:GetMinMaxValues()
		catalogSlider:SetValue(math.max(0, math.min(maximum, catalogSlider:GetValue() - direction * 44)))
	end
	root.CatalogScroll:SetScript("OnMouseWheel", ScrollCatalogWheel)
	catalogSlider:EnableMouseWheel(true)
	catalogSlider:SetScript("OnMouseWheel", ScrollCatalogWheel)
	root.CatalogSlider = catalogSlider

	local UF = GetUnitFrames()
	local names = UF and UF.GetTagNames and UF.GetTagNames() or {}
	for i = 1, #names + 1 do
		local name = i == 1 and "+ Text" or names[i - 1]
		local col, row = (i - 1) % CatalogColumns, math.floor((i - 1) / CatalogColumns)
		local buttonWidth = col == CatalogColumns - 1 and CatalogLastButtonWidth or CatalogButtonWidth
		local tagButton = Button(root.CatalogContent, i == 1 and Language["+ Text"] or name, buttonWidth, 21, function()
			if i == 1 then
				AddText()
				return
			end
			local index = root.Selected and root.Selected + 1 or #root.Parts + 1
			table.insert(root.Parts, index, {kind = "tag", value = "[" .. name .. "]"})
			root.Selected = index
			Builder.Refresh(root)
		end)
		tagButton:SetPoint("TOPLEFT", root.CatalogContent, HorizontalPadding + col * CatalogStep, 1 - PanelPadding - row * (21 + CatalogButtonGap))
		tagButton.Text:ClearAllPoints()
		tagButton.Text:SetPoint("LEFT", tagButton, 6, 0)
		tagButton.Text:SetJustifyH("LEFT")
		tagButton.Text:SetWidth(CatalogWidth)
		FitLabel(tagButton.Text, name, buttonWidth - 12)
		tagButton.Text:SetWidth(buttonWidth - 12)
		local description = TagDescription(name)
		tagButton:HookScript("OnEnter", function(button)
			GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
			GameTooltip:SetText(name)
			GameTooltip:AddLine(description, 0.8, 0.8, 0.8, true)
			GameTooltip:Show()
		end)
		tagButton:HookScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end
	local viewportHeight = CatalogHeight
	local contentHeight = math.max(viewportHeight, math.ceil((#names + 1) / CatalogColumns) * (21 + CatalogButtonGap) + PanelPadding * 2)
	root.CatalogContent:SetHeight(contentHeight)
	local maxScroll = math.max(0, contentHeight - viewportHeight)
	catalogSlider:SetMinMaxValues(0, maxScroll)
	catalogSlider:SetValue(0)
	catalogSlider:SetShown(maxScroll > 0)
	scrollUp:SetShown(maxScroll > 0)
	scrollDown:SetShown(maxScroll > 0)

	root.Cancel = Button(root, Language["Cancel"], 78, 22, function()
		window.FadeOut:Play()
	end)
	root.Apply = Button(root, Language["Apply"], 78, 22, function()
		if root.Valid then
			window.Input:GetScript("OnEnterPressed")(window.Input)
		end
	end)
	root.Apply:SetPoint("TOPRIGHT", catalogBox, "BOTTOMRIGHT", ScrollbarLane, -(GUI.WidgetCore.SPACING - 1))
	root.Cancel:SetPoint("RIGHT", root.Apply, "LEFT", -2, 0)
	root:Hide()
	window.TagBuilder = root
	return root
end
