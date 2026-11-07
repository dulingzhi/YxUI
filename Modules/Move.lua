local YxUI, Language, Assets, Settings = select(2, ...):get()

local unpack = unpack
local find = string.find
local gsub = string.gsub
local match = string.match
local Round = Round

YxUI.MovingFrames = {}
YxUI.FrameDefaults = {}
YxUI.MovingActive = false

local GUI = YxUI:GetModule("GUI")

function YxUI:PositionToString(frame)
	local A1, Parent, A2, X, Y = frame:GetPoint()

	return format("%s:%s:%s:%s:%s", A1, Parent and Parent:GetName() or "YxUIParent", A2, Round(X or 0), Round(Y or 0))
end

function YxUI:StringToPosition(str)
	if type(str) == "table" then -- Remove this after a month or two. (June 2nd 2020)
		return unpack(str) -- Migrated data will provide a table here. This leftover will be flushed after one login
	end

	local A1, Parent, A2, X, Y = match(str, "(.*):(.*):(.*):(.*):(.*)")

	return A1, _G[Parent], A2, tonumber(X), tonumber(Y)
end

local function SaveMoverPosition(Mover)
	local Profile = YxUI:GetActiveProfile()
	Profile.Move = Profile.Move or {}
	Profile.Move[Mover.Name] = YxUI:PositionToString(Mover)
end

function YxUI:SelectMover(Mover)
	if self.SelectedMover and self.SelectedMover ~= Mover then
		self.SelectedMover:SetBackdropColor(self:HexToRGB(Settings["ui-window-bg-color"]))
	end

	self.SelectedMover = Mover
	if Mover then
		Mover:SetBackdropColor(self:HexToRGB(Settings["ui-widget-color"]))
	end
end

function YxUI:UpdateMoverGuides()
	local Mover = self.SelectedMover
	if not self.MoverGuides or not Mover or not self.MovingActive then
		return
	end

	local Canvas = self.MoverGuides
	local CenterX, CenterY = Mover:GetCenter()
	local ParentX, ParentY = self.UIParent:GetCenter()
	if not (CenterX and CenterY and ParentX and ParentY) then
		Canvas.Vertical:Hide()
		Canvas.Horizontal:Hide()
		return
	end

	local VerticalTarget, VerticalPoint, HorizontalTarget, HorizontalPoint
	local Tolerance = 5
	local BestX = math.abs(CenterX - ParentX)
	local BestY = math.abs(CenterY - ParentY)
	if BestX <= Tolerance then VerticalTarget, VerticalPoint = self.UIParent, "CENTER" end
	if BestY <= Tolerance then HorizontalTarget, HorizontalPoint = self.UIParent, "CENTER" end

	local Left, Right, Top, Bottom = Mover:GetLeft(), Mover:GetRight(), Mover:GetTop(), Mover:GetBottom()
	if Left and Right and Top and Bottom then
		for i = 1, #self.MovingFrames do
			local Other = self.MovingFrames[i]
			if Other ~= Mover and Other:IsShown() then
				local OtherLeft, OtherRight = Other:GetLeft(), Other:GetRight()
				local OtherTop, OtherBottom = Other:GetTop(), Other:GetBottom()
				if OtherLeft and OtherRight and OtherTop and OtherBottom then
					local Delta = math.min(math.abs(Left - OtherLeft), math.abs(Right - OtherLeft))
					if Delta <= Tolerance and Delta < BestX then
						BestX, VerticalTarget, VerticalPoint = Delta, Other, "LEFT"
					end
					Delta = math.min(math.abs(Left - OtherRight), math.abs(Right - OtherRight))
					if Delta <= Tolerance and Delta < BestX then
						BestX, VerticalTarget, VerticalPoint = Delta, Other, "RIGHT"
					end
					Delta = math.min(math.abs(Top - OtherTop), math.abs(Bottom - OtherTop))
					if Delta <= Tolerance and Delta < BestY then
						BestY, HorizontalTarget, HorizontalPoint = Delta, Other, "TOP"
					end
					Delta = math.min(math.abs(Top - OtherBottom), math.abs(Bottom - OtherBottom))
					if Delta <= Tolerance and Delta < BestY then
						BestY, HorizontalTarget, HorizontalPoint = Delta, Other, "BOTTOM"
					end
				end
			end
		end
	end

	Canvas.Vertical:Hide()
	Canvas.Horizontal:Hide()
	if VerticalTarget then
		Canvas.Vertical:ClearAllPoints()
		Canvas.Vertical:SetPoint("CENTER", VerticalTarget, VerticalPoint)
		Canvas.Vertical:Show()
	end
	if HorizontalTarget then
		Canvas.Horizontal:ClearAllPoints()
		Canvas.Horizontal:SetPoint("CENTER", HorizontalTarget, HorizontalPoint)
		Canvas.Horizontal:Show()
	end
end

function YxUI:NudgeMover(Mover, DeltaX, DeltaY)
	if not Mover or not self.MovingActive or InCombatLockdown() then
		return
	end

	local A1, Parent, A2, X, Y = Mover:GetPoint()
	if not A1 then return end
	Mover:ClearAllPoints()
	Mover:SetPoint(A1, Parent, A2, Round(X or 0) + DeltaX, Round(Y or 0) + DeltaY)
	SaveMoverPosition(Mover)
	self:SelectMover(Mover)
	self:UpdateMoverGuides()

	local Editor = self:GetModule("m")
	if Editor.Loaded and Editor.CurrentFrame == Mover then
		Editor:UpdateFrameInfo()
	end
end

function YxUI:CreateMoverHelpers()
	if self.MoverGuides then return end

	local Guides = CreateFrame("Frame", nil, self.UIParent)
	Guides:SetAllPoints(self.UIParent)
	Guides:SetFrameStrata("HIGH")
	Guides:SetFrameLevel(50)
	Guides:EnableMouse(false)
	local R, G, B = self:HexToRGB(Settings["ui-widget-color"])
	Guides.Vertical = Guides:CreateTexture(nil, "OVERLAY")
	Guides.Vertical:SetColorTexture(R, G, B, 0.4)
	Guides.Vertical:SetSize(1, self.UIParent:GetHeight())
	Guides.Horizontal = Guides:CreateTexture(nil, "OVERLAY")
	Guides.Horizontal:SetColorTexture(R, G, B, 0.4)
	Guides.Horizontal:SetSize(self.UIParent:GetWidth(), 1)
	Guides.Vertical:Hide()
	Guides.Horizontal:Hide()
	Guides:Hide()
	self.MoverGuides = Guides

	local Keyboard = CreateFrame("Frame", nil, self.UIParent)
	Keyboard:SetFrameStrata("TOOLTIP")
	Keyboard:SetFrameLevel(100)
	Keyboard:SetAllPoints(self.UIParent)
	Keyboard:EnableMouse(false)
	Keyboard:SetPropagateKeyboardInput(true)
	Keyboard:EnableKeyboard(true)
	Keyboard:SetScript("OnKeyDown", function(Input, Key)
		if InCombatLockdown() then return end
		Input:SetPropagateKeyboardInput(true)
		if not YxUI.MovingActive or (GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus()) then
			return
		end

		if not YxUI.SelectedMover then return end
		local Delta = IsShiftKeyDown() and 10 or 1
		local X, Y
		if Key == "LEFT" then X, Y = -Delta, 0
		elseif Key == "RIGHT" then X, Y = Delta, 0
		elseif Key == "UP" then X, Y = 0, Delta
		elseif Key == "DOWN" then X, Y = 0, -Delta
		end
		if X then
			YxUI:NudgeMover(YxUI.SelectedMover, X, Y)
			Input:SetPropagateKeyboardInput(false)
		end
	end)
	Keyboard:SetScript("OnKeyUp", function(Input)
		if not InCombatLockdown() then Input:SetPropagateKeyboardInput(true) end
	end)
	Keyboard:Hide()
	self.MoverKeyboard = Keyboard

	local CombatEvents = CreateFrame("Frame")
	CombatEvents:RegisterEvent("PLAYER_REGEN_DISABLED")
	CombatEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
	CombatEvents:SetScript("OnEvent", function(_, Event)
		if Event == "PLAYER_REGEN_DISABLED" then
			Keyboard:Hide()
		elseif YxUI.MovingActive then
			Keyboard:Show()
		end
	end)
end

local OnDragStart = function(self)
	YxUI:SelectMover(self)
	self.WasDragged = true
	self.DragElapsed = 0
	if self.PreMove then self:PreMove() end
	self:StartMoving()
	if YxUI.MoverGuides then
		YxUI.MoverGuides:SetScript("OnUpdate", function(_, Elapsed)
			self.DragElapsed = self.DragElapsed + Elapsed
			if self.DragElapsed >= 0.04 then
				self.DragElapsed = 0
				YxUI:UpdateMoverGuides()
			end
		end)
	end
end

local OnDragStop = function(self)
	self:StopMovingOrSizing()
	if YxUI.MoverGuides then YxUI.MoverGuides:SetScript("OnUpdate", nil) end
	if self.PostMove then self:PostMove() end
	SaveMoverPosition(self)
	YxUI:UpdateMoverGuides()
end

function YxUI:ToggleMovers()
	if InCombatLockdown() then
		self:print(ERR_NOT_IN_COMBAT)
		return
	end

	if self.MovingActive then
		for i = 1, #self.MovingFrames do
			local Mover = self.MovingFrames[i]
			Mover:EnableMouse(false)
			Mover:StopMovingOrSizing()
			Mover:SetScript("OnDragStart", nil)
			Mover:SetScript("OnDragStop", nil)
			Mover:SetBackdropColor(self:HexToRGB(Settings["ui-window-bg-color"]))
			Mover.WasDragged = false
			Mover:Hide()
		end

		local Editor = self:GetModule("m")
		if Editor:IsShown() then Editor:Hide() end
		if self.MoverGuides then
			self.MoverGuides:SetScript("OnUpdate", nil)
			self.MoverGuides:Hide()
		end
		if self.MoverKeyboard then self.MoverKeyboard:Hide() end
		self.SelectedMover = nil
		self.MovingActive = false

		local ReturnToSettings = self.ReturnToSettings
		self.ReturnToSettings = false
		if ReturnToSettings and GUI.Loaded then
			if not GUI:IsShown() then
				GUI:Toggle()
			else
				C_Timer.After(0.25, function()
					if not YxUI.MovingActive and not GUI:IsShown() then GUI:Toggle() end
				end)
			end
		end
	else
		self:CreateMoverHelpers()
		self.ReturnToSettings = GUI.Loaded and GUI:IsShown()
		if self.ReturnToSettings then GUI:Toggle() end
		for i = 1, #self.MovingFrames do
			local Mover = self.MovingFrames[i]
			Mover:EnableMouse(true)
			Mover:RegisterForDrag("LeftButton")
			Mover:SetScript("OnDragStart", OnDragStart)
			Mover:SetScript("OnDragStop", OnDragStop)
			Mover:Show()
		end
		self.MovingActive = true
		self.MoverGuides:Show()
		self.MoverKeyboard:Show()
	end
end

function YxUI:ApplyProfileMoverPositions(previousName, nextName)
	local previous = self.Profiles[previousName]
	local destination = self.Profiles[nextName]
	local oldPositions = previous and previous.Move or {}
	local newPositions = destination and destination.Move or {}

	for i = 1, #self.MovingFrames do
		local mover = self.MovingFrames[i]
		local name = mover.Name
		local position = newPositions and newPositions[name]
		if position ~= (oldPositions and oldPositions[name]) then
			local a1, parent, a2, x, y
			if position then
				a1, parent, a2, x, y = self:StringToPosition(position)
			else
				local default = self.FrameDefaults[name]
				if default then
					a1, parent, a2, x, y = default[1], _G[default[2]], default[3], default[4], default[5]
				end
			end
			if a1 and parent and a2 and x and y then
				mover:ClearAllPoints()
				mover:SetPoint(a1, parent, a2, x, y)
			end
		end
	end
end

function YxUI:ResetMovers()
	local Profile = YxUI:GetActiveProfile()

	if Profile.Move then
		Profile.Move = nil

		for i = 1, #YxUI.MovingFrames do
			if YxUI.FrameDefaults[YxUI.MovingFrames[i].Name] then
				local A1, Parent, A2, X, Y = unpack(YxUI.FrameDefaults[YxUI.MovingFrames[i].Name])

				YxUI.MovingFrames[i]:ClearAllPoints()
				YxUI.MovingFrames[i]:SetPoint(A1, _G[Parent], A2, X, Y)
			end
		end
	end
end

function YxUI:ResetMover(name)
	for i = 1, #YxUI.MovingFrames do
		if YxUI.MovingFrames[i].Name == name then
			local A1, Parent, A2, X, Y = unpack(YxUI.FrameDefaults[YxUI.MovingFrames[i].Name])

			YxUI.MovingFrames[i]:ClearAllPoints()
			YxUI.MovingFrames[i]:SetPoint(A1, _G[Parent], A2, X, Y)

			break
		end
	end
end

function YxUI:ResetAllMovers()
	self:DisplayPopup(Language["Attention"], Language["Are you sure you want to reset the position of all moved frames?"], ACCEPT, self.ResetMovers, CANCEL)
end

function YxUI:IsMoved(frame)
	local Profile = self:GetActiveProfile()

	if not Profile.Move then
		return
	end

	if frame and frame.GetName then
		if Profile.Move[frame:GetName()] then
			return true
		end
	end
end

local OnSizeChanged = function(self)
	self.Mover:SetSize(self:GetSize())
end

local MoverOnMouseUp = function(self, button)
	YxUI:SelectMover(self)
	if button == "RightButton" then
		if YxUI.FrameDefaults[self.Name] then
			local A1, Parent, A2, X, Y = unpack(YxUI.FrameDefaults[self.Name])
			self:ClearAllPoints()
			self:SetPoint(A1, _G[Parent], A2, X, Y)

			local Profile = YxUI:GetActiveProfile()
			if Profile.Move then Profile.Move[self.Name] = nil end
			YxUI:UpdateMoverGuides()
			local Editor = YxUI:GetModule("m")
			if Editor.Loaded and Editor.CurrentFrame == self then Editor:PopulateFrameInfo() end
		end
	elseif button == "LeftButton" then
		if self.WasDragged then
			self.WasDragged = false
			return
		end

		local Editor = YxUI:GetModule("m")
		if not Editor.Loaded then Editor:LoadFrame() end
		Editor.CurrentFrame = self
		Editor:PopulateFrameInfo()
		if not Editor:IsShown() then Editor:Show() end
	end
end

local MoverOnEnter = function(self)
	self:SetBackdropColor(YxUI:HexToRGB("FF4444"))

	local A1, Parent, A2, X, Y = self:GetPoint()

	GameTooltip_SetDefaultAnchor(GameTooltip, self)

	GameTooltip:AddLine(self.Name)
	GameTooltip:AddLine(Language["Drag to move  |  Click to edit  |  Right-click to reset"], 0.8, 0.8, 0.8)
	GameTooltip:AddLine(Language["Arrows: 1px  |  Shift + arrows: 10px"], 0.8, 0.8, 0.8)
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine(Language["Anchor 1:"], A1, 1, 1, 1, 1, 1, 1)
	GameTooltip:AddDoubleLine(Language["Parent:"], Parent and Parent:GetName() or "YxUIParent", 1, 1, 1, 1, 1, 1)
	GameTooltip:AddDoubleLine(Language["Anchor 2:"], A2, 1, 1, 1, 1, 1, 1)
	GameTooltip:AddDoubleLine(Language["X offset:"], Round(X), 1, 1, 1, 1, 1, 1)
	GameTooltip:AddDoubleLine(Language["Y offset:"], Round(Y), 1, 1, 1, 1, 1, 1)
	GameTooltip:Show()

	for i = 1, #YxUI.MovingFrames do
		if YxUI.MovingFrames[i].Name ~= self.Name then
			YxUI.MovingFrames[i]:SetAlpha(0.5)
		end
	end
end

local MoverOnLeave = function(self)
	self:SetBackdropColor(YxUI:HexToRGB(YxUI.SelectedMover == self and Settings["ui-widget-color"] or Settings["ui-window-bg-color"]))

	GameTooltip:Hide()

	for i = 1, #YxUI.MovingFrames do
		YxUI.MovingFrames[i]:SetAlpha(1)
	end
end

function YxUI:CreateMover(frame, padding)
	local A1, Parent, A2, X, Y = frame:GetPoint()
	local Name = frame:GetName()

	if not Name then
		return
	end

	local Label = Name

	if find(Label, "YxUI") then
		Label = gsub(Label, "YxUI ", "")
	end

	if not Parent then
		Parent = YxUIParent
	end

	local ParentName = Parent:GetName()
	local ParentObject = _G[ParentName]
	local Padding = padding or 0
	local Width, Height = frame:GetSize()

	local Mover = CreateFrame("Frame", nil, YxUI.UIParent, "SecureHandlerStateTemplate, BackdropTemplate")
	Mover:SetSize(Width + Padding, Height + Padding)
	Mover:SetBackdrop(YxUI.BackdropAndBorder)
	Mover:SetBackdropColor(YxUI:HexToRGB(Settings["ui-window-bg-color"]))
	Mover:SetBackdropBorderColor(0, 0, 0)
	Mover:SetFrameLevel(20)
	Mover:SetFrameStrata("HIGH")
	Mover:SetMovable(true)
	Mover:SetClampedToScreen(true)
	Mover:SetScript("OnMouseUp", MoverOnMouseUp)
	Mover:SetScript("OnEnter", MoverOnEnter)
	Mover:SetScript("OnLeave", MoverOnLeave)
	Mover.Frame = frame
	Mover.Name = Name
	Mover:Hide()

	Mover.BG = CreateFrame("Frame", nil, Mover, "BackdropTemplate")
	Mover.BG:SetPoint("TOPLEFT", Mover, 3, -3)
	Mover.BG:SetPoint("BOTTOMRIGHT", Mover, -3, 3)
	Mover.BG:SetBackdrop(YxUI.BackdropAndBorder)
	Mover.BG:SetBackdropColor(YxUI:HexToRGB(Settings["ui-window-main-color"]))
	Mover.BG:SetBackdropBorderColor(0, 0, 0)

	Mover.Label = Mover.BG:CreateFontString(nil, "OVERLAY")
	YxUI:SetFontInfo(Mover.Label, Settings["ui-widget-font"], 12)
	Mover.Label:SetPoint("CENTER", Mover, 0, 0)
	Mover.Label:SetText(Label)

	frame:ClearAllPoints()
	frame:SetPoint("CENTER", Mover, 0, 0)
	frame.Mover = Mover
	frame:HookScript("OnSizeChanged", OnSizeChanged)

	self.FrameDefaults[Name] = {A1, ParentName, A2, X, Y}

	local Profile = self:GetActiveProfile()

	if Profile and Profile.Move and Profile.Move[Name] then
		local A1, Parent, A2, X, Y = self:StringToPosition(Profile.Move[Name])

		Mover:SetPoint(A1, Parent, A2, X, Y)
	else
		Mover:SetPoint(A1, Parent, A2, X, Y)
	end

	table.insert(self.MovingFrames, Mover)

	return Mover
end

-- Create mover frame
--if 1 == 1 then return end

local m = YxUI:NewModule("m")

local InputOnEnterPressed = function(self)
	local Text = self:GetText() or ""

	self:SetAutoFocus(false)
	self:ClearFocus()

	if self.Hook then
		self:Hook(self:GetParent())
	end
end

local InputOnEscapePressed = function(self)
	self:SetAutoFocus(false)
	self:ClearFocus()
end

local InputOnMouseDown = function(self)
	self:HighlightText()
	self:SetAutoFocus(true)
end

function m:CreateLine(parent, label)
	parent.Text = parent:CreateFontString(nil, "OVERLAY")
	YxUI:SetFontInfo(parent.Text, Settings["ui-widget-font"], Settings["ui-font-size"])
	parent.Text:SetSize(parent:GetWidth(), parent:GetHeight())
	parent.Text:SetPoint("LEFT", parent, 3, 0)
	parent.Text:SetJustifyH("LEFT")
	parent.Text:SetText(label)
end

function m:CreateInput(parent, label, hook)
	parent.EditBox = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
	parent.EditBox:SetSize(100, 20)
	parent.EditBox:SetPoint("RIGHT", parent, -2, 0)
	YxUI:SetFontInfo(parent.EditBox, Settings["ui-widget-font"], Settings["ui-font-size"])
	parent.EditBox:SetJustifyH("LEFT")
	parent.EditBox:SetAutoFocus(false)
	parent.EditBox:EnableKeyboard(true)
	parent.EditBox:EnableMouse(true)
	parent.EditBox:SetMaxLetters(255)
	parent.EditBox:SetTextInsets(5, 0, 0, 0)
	parent.EditBox:SetText("") -- change me
	parent.EditBox:SetBackdrop(YxUI.BackdropAndBorder)
	parent.EditBox:SetBackdropBorderColor(0, 0, 0)
	parent.EditBox:SetScript("OnEnterPressed", InputOnEnterPressed)
	parent.EditBox:SetScript("OnEscapePressed", InputOnEscapePressed)
	parent.EditBox:SetScript("OnMouseDown", InputOnMouseDown)
	parent.EditBox:SetScript("OnEditFocusLost", InputOnEscapePressed)

	parent.EditBox.BG = parent.EditBox:CreateTexture(nil, "BORDER")
	parent.EditBox.BG:SetTexture(Assets:GetTexture("Blank"))
	parent.EditBox.BG:SetVertexColor(0, 0, 0)
	parent.EditBox.BG:SetPoint("TOPLEFT", parent.EditBox, 0, 0)
	parent.EditBox.BG:SetPoint("BOTTOMRIGHT", parent.EditBox, 0, 0)

	parent.EditBox.Tex = parent.EditBox:CreateTexture(nil, "ARTWORK")
	parent.EditBox.Tex:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	parent.EditBox.Tex:SetPoint("TOPLEFT", parent.EditBox, 1, -1)
	parent.EditBox.Tex:SetPoint("BOTTOMRIGHT", parent.EditBox, -1, 1)
	parent.EditBox.Tex:SetVertexColor(YxUI:HexToRGB(Settings["ui-widget-bright-color"]))

	if hook then
		parent.EditBox.Hook = hook
	end

	parent.Text = parent:CreateFontString(nil, "OVERLAY")
	YxUI:SetFontInfo(parent.Text, Settings["ui-widget-font"], Settings["ui-font-size"])
	parent.Text:SetSize(parent:GetWidth(), parent:GetHeight())
	parent.Text:SetPoint("LEFT", parent, 3, 0)
	parent.Text:SetJustifyH("LEFT")
	parent.Text:SetText(label)
end

m.Valid = {
	"LEFT",
	"RIGHT",
	"TOP",
	"BOTTOM",
	"CENTER",
}

function m:ValidatePoint(point)
	local Valid

	for i = 1, #self.Valid do
		if point:find(self.Valid[i]) then
			Valid = true

			break
		end
	end

	return Valid
end

function m:PopulateFrameInfo()
	local A1, P, A2, X, Y = self.CurrentFrame:GetPoint()
	P = P or YxUI.UIParent

	self.Lines[1].Text:SetText(self.CurrentFrame.Name)
	self.Lines[2].EditBox:SetText(P:GetName())
	self.Lines[3].EditBox:SetText(A1)
	self.Lines[4].EditBox:SetText(A2)
	self.Lines[5].EditBox:SetText(Round(X or 0))
	self.Lines[6].EditBox:SetText(Round(Y or 0))
end

function m:UpdateFrameInfo()
	self:PopulateFrameInfo()
	local Profile = YxUI:GetActiveProfile()

	if not Profile.Move then
		Profile.Move = {}
	end

	Profile.Move[self.CurrentFrame.Name] = YxUI:PositionToString(self.CurrentFrame)
	YxUI:UpdateMoverGuides()
end

function m:UpdateParent()
	local Name = self:GetText()

	if not _G[Name] then
		return
	end

	local Frame = YxUI:GetModule("m").CurrentFrame
	local A1, P, A2, X, Y = Frame:GetPoint()

	Frame:ClearAllPoints()
	Frame:SetPoint(A1, Name, A2, X, Y)

	m:UpdateFrameInfo()
end

function m:UpdateFromPoint()
	local Point = self:GetText()

	if not m:ValidatePoint(Point) then
		Point = "CENTER"
		self:SetText(Point)
	end

	local Frame = YxUI:GetModule("m").CurrentFrame

	local A1, P, A2, X, Y = Frame:GetPoint()

	Frame:ClearAllPoints()
	Frame:SetPoint(Point, P, A2, X, Y)

	m:UpdateFrameInfo()
end

function m:UpdateToPoint()
	local Point = self:GetText()

	if not m:ValidatePoint(Point) then
		Point = "CENTER"
		self:SetText(Point)
	end

	local Frame = YxUI:GetModule("m").CurrentFrame

	local A1, P, A2, X, Y = Frame:GetPoint()

	Frame:ClearAllPoints()
	Frame:SetPoint(A1, P, Point, X, Y)

	m:UpdateFrameInfo()
end

function m:UpdateXOffset()
	local Offset = tonumber(self:GetText())

	if type(Offset) ~= "number" then
		return
	end

	local Frame = YxUI:GetModule("m").CurrentFrame

	local A1, P, A2, X, Y = Frame:GetPoint()

	Frame:ClearAllPoints()
	Frame:SetPoint(A1, P, A2, Offset, Y)

	m:UpdateFrameInfo()
end

function m:UpdateYOffset()
	local Offset = tonumber(self:GetText())

	if type(Offset) ~= "number" then
		return
	end

	local Frame = YxUI:GetModule("m").CurrentFrame

	local A1, P, A2, X, Y = Frame:GetPoint()

	Frame:ClearAllPoints()
	Frame:SetPoint(A1, P, A2, X, Offset)

	m:UpdateFrameInfo()
end

function m:OnNudgeMouseDown()
	self.Arrow:ClearAllPoints()
	self.Arrow:SetPoint("CENTER", self, 1, -1)
end

local function NudgeButton(Button, X, Y)
	Button.Arrow:ClearAllPoints()
	Button.Arrow:SetPoint("CENTER", Button, 0, 0)
	local Editor = Button:GetParent()
	YxUI:NudgeMover(Editor.CurrentFrame, X, Y)
end

function m:NudgeDown() NudgeButton(self, 0, -1) end
function m:NudgeUp() NudgeButton(self, 0, 1) end
function m:NudgeLeft() NudgeButton(self, -1, 0) end
function m:NudgeRight() NudgeButton(self, 1, 0) end

function m:LoadFrame()
	self:SetSize(220, 186)
	self:SetPoint("CENTER", UIParent, 0, -20)
	self:SetFrameStrata("DIALOG")
	self:SetFrameLevel(20)
	self:SetBackdrop(YxUI.BackdropAndBorder)
	self:SetBackdropColor(YxUI:HexToRGB(Settings["ui-window-bg-color"]))
	self:SetBackdropBorderColor(0, 0, 0)
	self:SetBackdropBorderColor(0, 0, 0)
	self:SetMovable(true)
	self:SetClampedToScreen(true)
	self:EnableMouse(true)
	self:RegisterForDrag("LeftButton")
	self:SetScript("OnDragStart", self.StartMoving)
	self:SetScript("OnDragStop", self.StopMovingOrSizing)

	self.Header = CreateFrame("Frame", nil, self, "BackdropTemplate")
	self.Header:SetHeight(22)
	self.Header:SetPoint("TOPLEFT", self, 3, -3)
	self.Header:SetPoint("TOPRIGHT", self, -((3 + 2) + 22), -3)
	self.Header:SetBackdrop(YxUI.BackdropAndBorder)
	self.Header:SetBackdropColor(0, 0, 0)
	self.Header:SetBackdropBorderColor(0, 0, 0)

	self.HeaderTexture = self.Header:CreateTexture(nil, "OVERLAY")
	self.HeaderTexture:SetPoint("TOPLEFT", self.Header, 1, -1)
	self.HeaderTexture:SetPoint("BOTTOMRIGHT", self.Header, -1, 1)
	self.HeaderTexture:SetTexture(Assets:GetTexture(Settings["ui-header-texture"]))
	self.HeaderTexture:SetVertexColor(YxUI:HexToRGB(Settings["ui-header-texture-color"]))

	self.Header.Text = self.Header:CreateFontString(nil, "OVERLAY")
	self.Header.Text:SetPoint("LEFT", self.Header, 5, -1)
	YxUI:SetFontInfo(self.Header.Text, Settings["ui-header-font"], Settings["ui-header-font-size"])
	self.Header.Text:SetJustifyH("LEFT")
	self.Header.Text:SetText("|cFF" .. Settings["ui-header-font-color"] .. Language["Frame Position"] .. "|r")

	-- Close button
	self.CloseButton = CreateFrame("Frame", nil, self, "BackdropTemplate")
	self.CloseButton:SetSize(22, 22)
	self.CloseButton:SetPoint("TOPRIGHT", self, -3, -3)
	self.CloseButton:SetBackdrop(YxUI.BackdropAndBorder)
	self.CloseButton:SetBackdropColor(0, 0, 0, 0)
	self.CloseButton:SetBackdropBorderColor(0, 0, 0)
	self.CloseButton:SetScript("OnEnter", function(self) self.Cross:SetVertexColor(YxUI:HexToRGB("C0392B")) end)
	self.CloseButton:SetScript("OnLeave", function(self) self.Cross:SetVertexColor(YxUI:HexToRGB("EEEEEE")) end)
	self.CloseButton:SetScript("OnMouseUp", function(self)
		self.Texture:SetVertexColor(YxUI:HexToRGB(Settings["ui-header-texture-color"]))

		self:GetParent():Hide()
	end)

	self.CloseButton:SetScript("OnMouseDown", function(self)
		local R, G, B = YxUI:HexToRGB(Settings["ui-header-texture-color"])

		self.Texture:SetVertexColor(R * 0.85, G * 0.85, B * 0.85)
	end)

	self.CloseButton.Texture = self.CloseButton:CreateTexture(nil, "ARTWORK")
	self.CloseButton.Texture:SetPoint("TOPLEFT", self.CloseButton, 1, -1)
	self.CloseButton.Texture:SetPoint("BOTTOMRIGHT", self.CloseButton, -1, 1)
	self.CloseButton.Texture:SetTexture(Assets:GetTexture(Settings["ui-header-texture"]))
	self.CloseButton.Texture:SetVertexColor(YxUI:HexToRGB(Settings["ui-header-texture-color"]))

	self.CloseButton.Cross = self.CloseButton:CreateTexture(nil, "OVERLAY")
	self.CloseButton.Cross:SetPoint("CENTER", self.CloseButton, 0, 0)
	self.CloseButton.Cross:SetSize(16, 16)
	self.CloseButton.Cross:SetTexture(Assets:GetTexture("Close"))
	self.CloseButton.Cross:SetVertexColor(YxUI:HexToRGB("EEEEEE"))

	self.Inner = CreateFrame("Frame", nil, self, "BackdropTemplate")
	self.Inner:SetPoint("TOPLEFT", self.Header, "BOTTOMLEFT", 0, -2)
	self.Inner:SetPoint("BOTTOMRIGHT", self, -3, 3)
	self.Inner:SetBackdrop(YxUI.BackdropAndBorder)
	self.Inner:SetBackdropColor(YxUI:HexToRGB(Settings["ui-window-main-color"]))
	self.Inner:SetBackdropBorderColor(0, 0, 0)

	self.Lines = {}

	--for i = 1, 6 do
	for i = 1, 7 do
		local Line = CreateFrame("Frame", nil, self.Inner, "BackdropTemplate")
		Line:SetSize(self.Inner:GetWidth() - 6, 20)

		if i == 1 then
			Line:SetPoint("TOPLEFT", self.Inner, 3, -3)
		else
			Line:SetPoint("TOPLEFT", self.Lines[i-1], "BOTTOMLEFT", 0, -2)
		end

		self.Lines[i] = Line
	end

	self:CreateLine(self.Lines[1], Language["Select a frame"])
	self:CreateInput(self.Lines[2], Language["Anchor Parent"], self.UpdateParent)
	self:CreateInput(self.Lines[3], Language["Anchor From"], self.UpdateFromPoint)
	self:CreateInput(self.Lines[4], Language["Anchor To"], self.UpdateToPoint)
	self:CreateInput(self.Lines[5], Language["X Offset"], self.UpdateXOffset)
	self:CreateInput(self.Lines[6], Language["Y Offset"], self.UpdateYOffset)

	self.Nudge = {}

	for i = 4, 1, -1 do
		local Button = CreateFrame("Frame", nil, self, "BackdropTemplate")
		Button:SetSize(20, 20)
		Button:SetBackdrop(YxUI.BackdropAndBorder)
		Button:SetBackdropColor(0, 0, 0)
		Button:SetBackdropBorderColor(0, 0, 0)

		Button.Texture = Button:CreateTexture(nil, "ARTWORK")
		Button.Texture:SetPoint("TOPLEFT", Button, 1, -1)
		Button.Texture:SetPoint("BOTTOMRIGHT", Button, -1, 1)
		Button.Texture:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
		Button.Texture:SetVertexColor(YxUI:HexToRGB(Settings["ui-widget-bright-color"]))

		Button.Arrow = Button:CreateTexture(nil, "OVERLAY")
		Button.Arrow:SetSize(16, 16)
		Button.Arrow:SetPoint("CENTER", Button, 0, 0)
		Button.Arrow:SetVertexColor(YxUI:HexToRGB(Settings["ui-widget-color"]))

		if i == 4 then
			Button:SetPoint("RIGHT", self.Lines[7], -2, 0)
		else
			Button:SetPoint("RIGHT", self.Nudge[i+1], "LEFT", -2, 0)
		end

		self.Nudge[i] = Button
	end

	self.NudgeText = self.Lines[7]:CreateFontString(nil, "OVERLAY")
	YxUI:SetFontInfo(self.NudgeText, Settings["ui-widget-font"], Settings["ui-font-size"])
	self.NudgeText:SetSize(self.Lines[7]:GetWidth() / 2, self.Lines[7]:GetHeight())
	self.NudgeText:SetPoint("LEFT", self.Lines[7], 3, 0)
	self.NudgeText:SetJustifyH("LEFT")
	self.NudgeText:SetText(Language["Nudge"])

	self.Nudge[1].Arrow:SetTexture(Assets:GetTexture("Arrow Left")) -- l r u d
	self.Nudge[2].Arrow:SetTexture(Assets:GetTexture("Arrow Right"))
	self.Nudge[3].Arrow:SetTexture(Assets:GetTexture("Arrow Up"))
	self.Nudge[4].Arrow:SetTexture(Assets:GetTexture("Arrow Down"))

	self.Nudge[1]:SetScript("OnMouseDown", self.OnNudgeMouseDown)
	self.Nudge[1]:SetScript("OnMouseUp", self.NudgeLeft)
	self.Nudge[2]:SetScript("OnMouseDown", self.OnNudgeMouseDown)
	self.Nudge[2]:SetScript("OnMouseUp", self.NudgeRight)
	self.Nudge[3]:SetScript("OnMouseDown", self.OnNudgeMouseDown)
	self.Nudge[3]:SetScript("OnMouseUp", self.NudgeUp)
	self.Nudge[4]:SetScript("OnMouseDown", self.OnNudgeMouseDown)
	self.Nudge[4]:SetScript("OnMouseUp", self.NudgeDown)

	self.Loaded = true
end
