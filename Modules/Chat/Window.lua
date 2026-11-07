local YxUI, Language, Assets, Settings = select(2, ...):get()
local Chat = YxUI:GetModule("Chat")
local Window = YxUI:GetModule("Right Window")
local DT
local match = string.match

function Chat:CreateChatWindow()
	local R, G, B = YxUI:HexToRGB(Settings["ui-window-main-color"])
	local Border = Settings["ui-border-thickness"]
	local Width = Settings["chat-frame-width"]

	self:SetSize(Width, Settings["chat-frame-height"] + Settings["chat-bottom-height"] + Settings["chat-top-height"] + (4 * 2))
	self:SetPoint("BOTTOMLEFT", YxUI.UIParent, 12, 12)
	self:SetFrameStrata("BACKGROUND")

	self.Bottom = CreateFrame("Frame", "YxUIChatFrameBottom", self, "BackdropTemplate")
	self.Bottom:SetSize(Width, Settings["chat-bottom-height"])
	self.Bottom:SetPoint("BOTTOMLEFT", self, 0, 0)
	YxUI:AddBackdrop(self.Bottom, Assets:GetTexture(Settings["ui-header-texture"]))
	self.Bottom.Outside:SetBackdropColor(R, G, B, (Settings["chat-bottom-opacity"] / 100))

	self.EditBox = CreateFrame("Frame", nil, self, "BackdropTemplate")
	self.EditBox:SetSize(Width, Settings["chat-bottom-height"])
	self.EditBox:SetPoint("BOTTOMLEFT", self, 0, 0)
	YxUI:AddBackdrop(self.EditBox, Assets:GetTexture(Settings["ui-header-texture"]))
	self.EditBox.Outside:SetBackdropColor(R, G, B, (Settings["chat-bottom-opacity"] / 100))
	self.EditBox:Hide()

	self.Middle = CreateFrame("Frame", "YxUIChatFrameMiddle", self, "BackdropTemplate")
	self.Middle:SetSize(Width, Settings["chat-frame-height"])
	self.Middle:SetPoint("BOTTOM", self.Bottom, "TOP", 0, 1 > Border and -1 or -(Border + 2))
	YxUI:AddBackdrop(self.Middle)
	self.Middle.Outside:SetBackdropColor(R, G, B, (Settings["chat-bg-opacity"] / 100))
	self.Middle.Outside:SetFrameStrata("BACKGROUND")

	self.Top = CreateFrame("Frame", "YxUIChatFrameTop", self, "BackdropTemplate")
	self.Top:SetSize(Width, Settings["chat-top-height"])
	self.Top:SetPoint("BOTTOM", self.Middle, "TOP", 0, 1 > Border and -1 or -(Border + 2))
	YxUI:AddBackdrop(self.Top, Assets:GetTexture(Settings["ui-header-texture"]))
	self.Top.Outside:SetBackdropColor(R, G, B, (Settings["chat-top-opacity"] / 100))

	YxUI:CreateMover(self, 2)
end

Chat.Window = {
	SetChatDataTextWidth = function(_, width)
		local dataText = YxUI:GetModule("DataText")
		local names = {"Chat-Left", "Chat-Middle", "Chat-Right"}

		for i = 1, #names do
			local anchor = dataText:GetAnchor(names[i])

			if anchor then
				anchor:SetWidth(width / 3)
			end
		end
	end,
	GetEmbedFrame = function()
		return Window.Middle
	end,
}

function Window:CreateSingleWindow()
	local R, G, B = YxUI:HexToRGB(Settings["ui-window-main-color"])
	local Border = Settings["ui-border-thickness"]
	local Width = Settings["right-window-width"]

	if not self.Bottom then
		self.Bottom = CreateFrame("Frame", nil, self, "BackdropTemplate")
		self.Bottom:SetSize(Width, Settings["right-window-bottom-height"])
		self.Bottom:SetPoint("BOTTOMRIGHT", self, 0, 0)
		YxUI:AddBackdrop(self.Bottom, Assets:GetTexture(Settings["ui-header-texture"]))
		self.Bottom.Outside:SetBackdropColor(R, G, B, (Settings["rw-bottom-fill"] / 100))
		self.Bottom.Outside:SetFrameStrata("BACKGROUND")
	end

	self.Middle = CreateFrame("Frame", nil, self, "BackdropTemplate")
	self.Middle:SetSize(Width, Settings["right-window-height"])
	self.Middle:SetPoint("BOTTOMLEFT", self.Bottom, "TOPLEFT", 0, 1 > Border and -1 or -(Border + 2))
	YxUI:AddBackdrop(self.Middle)
	self.Middle.Outside:SetBackdropColor(R, G, B, (Settings["right-window-fill"] / 100))
	self.Middle.Outside:SetFrameStrata("BACKGROUND")

	self.Top = CreateFrame("Frame", nil, self, "BackdropTemplate")
	self.Top:SetSize(Width, Settings["right-window-top-height"])
	self.Top:SetPoint("BOTTOMLEFT", self.Middle, "TOPLEFT", 0, 1 > Border and -1 or -(Border + 2))
	YxUI:AddBackdrop(self.Top, Assets:GetTexture(Settings["ui-header-texture"]))
	self.Top.Outside:SetBackdropColor(R, G, B, (Settings["rw-top-fill"] / 100))
	self.Top.Outside:SetFrameStrata("BACKGROUND")
end

function Window:CreateDoubleWindow()
	local R, G, B = YxUI:HexToRGB(Settings["ui-window-main-color"])
	local Border = Settings["ui-border-thickness"]
	local Adjust = 1 > Border and -1 or -(Border + 2)
	local Width = Settings["right-window-width"]
	local LeftWidth = (Width * Settings["right-window-middle-pos"] / 100) - Adjust
	local RightWidth = (Width - (Width * Settings["right-window-middle-pos"] / 100))

	if not self.Bottom then
		self.Bottom = CreateFrame("Frame", nil, self, "BackdropTemplate")
		self.Bottom:SetSize(Width, Settings["right-window-bottom-height"])
		self.Bottom:SetPoint("BOTTOMRIGHT", self, 0, 0)
		YxUI:AddBackdrop(self.Bottom, Assets:GetTexture(Settings["ui-header-texture"]))
		self.Bottom.Outside:SetBackdropColor(R, G, B, Settings["rw-bottom-fill"] / 100)
	end

	self.Left = CreateFrame("Frame", nil, self, "BackdropTemplate")
	self.Left:SetSize(LeftWidth, Settings["right-window-height"])
	self.Left:SetPoint("BOTTOMLEFT", self.Bottom, "TOPLEFT", 0, Adjust) -- -4
	YxUI:AddBackdrop(self.Left)
	self.Left.Outside:SetBackdropColor(R, G, B, (Settings["right-window-fill"] / 100))
	self.Left.Outside:SetFrameStrata("BACKGROUND")

	self.Right = CreateFrame("Frame", nil, self, "BackdropTemplate")
	self.Right:SetSize(RightWidth, Settings["right-window-height"])
	self.Right:SetPoint("BOTTOMRIGHT", self.Bottom, "TOPRIGHT", 0, Adjust) -- -4
	YxUI:AddBackdrop(self.Right)
	self.Right.Outside:SetBackdropColor(R, G, B, (Settings["right-window-fill"] / 100))
	self.Right.Outside:SetFrameStrata("BACKGROUND")

	self.TopLeft = CreateFrame("Frame", nil, self, "BackdropTemplate")
	self.TopLeft:SetSize(LeftWidth, Settings["right-window-top-height"])
	self.TopLeft:SetPoint("BOTTOMLEFT", self.Left, "TOPLEFT", 0, Adjust) -- -4
	YxUI:AddBackdrop(self.TopLeft, Assets:GetTexture(Settings["ui-header-texture"]))
	self.TopLeft.Outside:SetBackdropColor(R, G, B, Settings["rw-top-fill"] / 100)

	self.TopRight = CreateFrame("Frame", nil, self, "BackdropTemplate")
	self.TopRight:SetSize(RightWidth, Settings["right-window-top-height"])
	self.TopRight:SetPoint("BOTTOMRIGHT", self.Right, "TOPRIGHT", 0, Adjust) -- -4
	YxUI:AddBackdrop(self.TopRight, Assets:GetTexture(Settings["ui-header-texture"]))
	self.TopRight.Outside:SetBackdropColor(R, G, B, Settings["rw-top-fill"] / 100)
end

function Window:AddDataTexts()
	local Width = self.Bottom:GetWidth() / 3
	local Height = self.Bottom:GetHeight()

	local Left = DT:NewAnchor("Window-Left", self.Bottom)
	Left:SetSize(Width, Height)
	Left:SetPoint("LEFT", self.Bottom, 0, 0)

	local Middle = DT:NewAnchor("Window-Middle", self.Bottom)
	Middle:SetSize(Width, Height)
	Middle:SetPoint("LEFT", Left, "RIGHT", 0, 0)

	local Right = DT:NewAnchor("Window-Right", self.Bottom)
	Right:SetSize(Width, Height)
	Right:SetPoint("LEFT", Middle, "RIGHT", 0, 0)

	DT:SetDataText("Window-Left", Settings["data-text-extra-left"])
	DT:SetDataText("Window-Middle", Settings["data-text-extra-middle"])
	DT:SetDataText("Window-Right", Settings["data-text-extra-right"])
end

function Window:UpdateDataTexts()
	local Width = self.Bottom:GetWidth() / 3

	local Left = DT:GetAnchor("Window-Left")
	Left:SetWidth(Width)
	Left:ClearAllPoints()
	Left:SetPoint("LEFT", self.Bottom, 0, 0)

	local Middle = DT:GetAnchor("Window-Middle")
	Middle:SetWidth(Width)
	Middle:ClearAllPoints()
	Middle:SetPoint("LEFT", Left, "RIGHT", 0, 0)

	local Right = DT:GetAnchor("Window-Right")
	Right:SetWidth(Width)
	Right:ClearAllPoints()
	Right:SetPoint("LEFT", Middle, "RIGHT", 0, 0)
end

function Window:Load()
	DT = YxUI:GetModule("DataText")

	if not Settings["right-window-enable"] then
		return
	end

	self:SetSize(Settings["right-window-width"], Settings["right-window-height"] + Settings["right-window-bottom-height"] + Settings["right-window-top-height"]) -- Border fix me
	self:SetPoint("BOTTOMRIGHT", YxUI.UIParent, -13, 13)
	self:SetFrameStrata("BACKGROUND")

	if Settings["right-window-size"] == "SINGLE" then
		self:CreateSingleWindow()
	else
		self:CreateDoubleWindow()
	end
	self.WindowStyle = Settings["right-window-size"]

	self:AddDataTexts()

	YxUI:CreateMover(self)
end

local UpdateOpacity = function(value)
	if not Window.Bottom then return end
	local R, G, B = YxUI:HexToRGB(Settings["ui-window-main-color"])

	if (Window.WindowStyle or Settings["right-window-size"]) == "SINGLE" then
		if Window.Middle then Window.Middle.Outside:SetBackdropColor(R, G, B, (value / 100)) end
	else
		if Window.Left then Window.Left.Outside:SetBackdropColor(R, G, B, (value / 100)) end
		if Window.Right then Window.Right.Outside:SetBackdropColor(R, G, B, (value / 100)) end
	end
end

local UpdateWidth = function(value)
	if not Window.Bottom then return end
	Window:SetWidth(value)
	if (Window.WindowStyle or Settings["right-window-size"]) == "SINGLE" then
		Window.Bottom:SetWidth(value)
		if Window.Middle then Window.Middle:SetWidth(value) end
		if Window.Top then Window.Top:SetWidth(value) end
	else
		local LeftWidth = (value * Settings["right-window-middle-pos"] / 100)
		local RightWidth = (value - LeftWidth) + (Settings["ui-border-thickness"] < 2 and 1 or 0)

		Window.Bottom:SetWidth(value)
		if Window.Left then Window.Left:SetWidth(LeftWidth) end
		if Window.TopLeft then Window.TopLeft:SetWidth(LeftWidth) end
		if Window.Right then Window.Right:SetWidth(RightWidth) end
		if Window.TopRight then Window.TopRight:SetWidth(RightWidth) end
	end

	Window:UpdateDataTexts()
end

local UpdateHeight = function(value)
	if not Window.Bottom then return end
	Window:SetHeight(value + Settings["right-window-top-height"] + Settings["right-window-bottom-height"])
	if (Window.WindowStyle or Settings["right-window-size"]) == "SINGLE" then
		if Window.Middle then Window.Middle:SetHeight(value) end
	else
		if Window.Left then Window.Left:SetHeight(value) end
		if Window.Right then Window.Right:SetHeight(value) end
	end
end

local UpdatePanelHeights = function()
	if not Window.Bottom then return end
	Window.Bottom:SetHeight(Settings["right-window-bottom-height"])
	if Window.Top then Window.Top:SetHeight(Settings["right-window-top-height"]) end
	if Window.TopLeft then Window.TopLeft:SetHeight(Settings["right-window-top-height"]) end
	if Window.TopRight then Window.TopRight:SetHeight(Settings["right-window-top-height"]) end
	Window:SetHeight(Settings["right-window-height"] + Settings["right-window-top-height"] + Settings["right-window-bottom-height"])
end

local UpdateSplitPosition = function(value)
	if not Window.Bottom then return end
	if (Window.WindowStyle or Settings["right-window-size"]) == "SINGLE" then
		return
	end

	local Width = Settings["right-window-width"]
	local LeftWidth = (Width * value / 100)
	local RightWidth = (Width - LeftWidth) + (Settings["ui-border-thickness"] < 2 and 1 or 0)

	if Window.Left then Window.Left:SetWidth(LeftWidth) end
	if Window.TopLeft then Window.TopLeft:SetWidth(LeftWidth) end

	if Window.Right then Window.Right:SetWidth(RightWidth) end
	if Window.TopRight then Window.TopRight:SetWidth(RightWidth) end
end

local UpdateWindowStyle = function(value)
	if not Window.Bottom or Window.WindowStyle == value then return end

	if value == "SINGLE" then
		if not Window.Middle then Window:CreateSingleWindow() end
		if Window.Left then
			Window.Left:Hide()
			Window.Right:Hide()
			Window.TopLeft:Hide()
			Window.TopRight:Hide()
		end
		Window.Middle:Show()
		Window.Top:Show()
	else
		if not Window.Left then Window:CreateDoubleWindow() end
		if Window.Middle then
			Window.Middle:Hide()
			Window.Top:Hide()
		end
		Window.Left:Show()
		Window.Right:Show()
		Window.TopLeft:Show()
		Window.TopRight:Show()
	end

	Window.WindowStyle = value
	Window:SetSize(Settings["right-window-width"], Settings["right-window-height"] + Settings["right-window-top-height"] + Settings["right-window-bottom-height"])
	UpdateWidth(Settings["right-window-width"])
	UpdateHeight(Settings["right-window-height"])
	UpdateOpacity(Settings["right-window-fill"])
	Window:UpdateDataTexts()
	Chat:MoveChatFrames()
end

local UpdateRightChatWindow = function()
	if Window.WindowStyle == Settings["right-window-size"] then
		Chat:MoveChatFrames()
	end
end

local GetChatFrameList = function()
	local Frames = {[Language["None"]] = "None"}
	local Frame
	local Tab

	for i = 4, NUM_CHAT_WINDOWS do
		Frame = _G["ChatFrame"..i]
		Tab = _G[Frame:GetName() .. "Tab"]

		--if Frame.name and Tab and Tab:IsVisible() and (not match(Frame.name, CHAT_LABEL .. "%s%d+")) then
		if Frame.name and Tab and (not match(Frame.name, CHAT_LABEL .. "%s%d+")) then
			Frames[Frame.name] = Frame.name
		end
	end

	return Frames
end

local function UpdateWindowDependencies()
	YxUI:GetModule("GUI").WidgetCore.UpdateDependencies({
		["right-window-middle-pos"] = Settings["right-window-enable"] and Settings["right-window-size"] == "DOUBLE",
		["rw-single-embed"] = Settings["right-window-enable"] and Settings["right-window-size"] == "SINGLE",
	})
end

YxUI:GetModule("GUI"):AddWidgetsID("General", "Right", "Chat", function(left, right)
	left:CreateHeader(Language["General"])
	left:CreateSwitch("right-window-enable", Settings["right-window-enable"], Language["Enable Right Window"], Language["Enable the right-side window for chat or add-ons"], function(value) UpdateWindowDependencies(); ReloadUI() end):RequiresReload(true)
	left:CreateSlider("right-window-width", Settings["right-window-width"], 300, 650, 1, Language["Window Width"], Language["Set the width of the window"], UpdateWidth)
	left:CreateSlider("right-window-height", Settings["right-window-height"], 40, 350, 1, Language["Window Height"], Language["Set the height of the window"], UpdateHeight)
	left:CreateSlider("right-window-top-height", Settings["right-window-top-height"], 20, 60, 1, Language["Top Panel Height"], Language["Height of the right window header"], UpdatePanelHeights)
	left:CreateSlider("right-window-bottom-height", Settings["right-window-bottom-height"], 20, 60, 1, Language["Bottom Panel Height"], Language["Height of the right window data text panel"], UpdatePanelHeights)

	left:CreateSlider("rw-top-fill", Settings["rw-top-fill"], 0, 100, 5, Language["Top Opacity"], Language["Opacity of the top panel"], function(value)
		local r, g, b = YxUI:HexToRGB(Settings["ui-window-main-color"])
		for _, panel in ipairs({Window.Top, Window.TopLeft, Window.TopRight}) do
			if panel and panel.Outside then
				panel.Outside:SetBackdropColor(r, g, b, value / 100)
			end
		end
	end, nil, "%")
	left:CreateSlider("rw-bottom-fill", Settings["rw-bottom-fill"], 0, 100, 5, Language["Bottom Opacity"], Language["Opacity of the bottom panel"], function(value)
		if Window.Bottom and Window.Bottom.Outside then
			local r, g, b = YxUI:HexToRGB(Settings["ui-window-main-color"])
			Window.Bottom.Outside:SetBackdropColor(r, g, b, value / 100)
		end
	end, nil, "%")
	left:CreateSlider("right-window-fill", Settings["right-window-fill"], 0, 100, 5, Language["Background Opacity"], Language["Set the opacity of the window background"], UpdateOpacity, nil, "%")

	left:CreateSlider("right-window-middle-pos", Settings["right-window-middle-pos"], 1, 99, 1, Language["Divider Position"], Language["Adjust the split between the left and right sections in double-window mode"], UpdateSplitPosition, nil, "%")

	right:CreateHeader(Language["Window Style"])
	right:CreateDropdown("right-window-size", Settings["right-window-size"], {[Language["Single"]] = "SINGLE", [Language["Double"]] = "DOUBLE"}, Language["Window Layout"], Language["Choose a single or double right-window layout"], function(value) UpdateWindowStyle(value); UpdateWindowDependencies() end)

	right:CreateHeader(Language["Single Window Embed"])
	right:CreateDropdown("rw-single-embed", Settings["rw-single-embed"], GetChatFrameList(), Language["Select Chat"], Language["Set which chat frame should be in the right window"], UpdateRightChatWindow)
	UpdateWindowDependencies()
end)
YxUI:GetModule("GUI"):RegisterPageSettingsID("General", "Right", {
	{"right-window-width", UpdateWidth},
	{"right-window-height", UpdateHeight},
	{"right-window-top-height", UpdatePanelHeights},
	{"right-window-bottom-height", UpdatePanelHeights},
	{"rw-top-fill", function(value)
		local r,g,b = YxUI:HexToRGB(Settings["ui-window-main-color"])
		for _,panel in ipairs({Window.Top, Window.TopLeft, Window.TopRight}) do
			if panel and panel.Outside then
				panel.Outside:SetBackdropColor(r, g, b, value / 100)
			end
		end
	end},
	{"rw-bottom-fill", function(value)
		if Window.Bottom and Window.Bottom.Outside then
			local r,g,b = YxUI:HexToRGB(Settings["ui-window-main-color"])
			Window.Bottom.Outside:SetBackdropColor(r, g, b, value / 100)
		end
	end},
	{"right-window-fill", UpdateOpacity},
	{"right-window-middle-pos", UpdateSplitPosition},
	{"right-window-size", function(value) UpdateWindowStyle(value); UpdateWindowDependencies() end},
	{"rw-single-embed", UpdateRightChatWindow},
}, "Chat")


YxUI:GetModule("GUI"):RegisterReloadSettings({"right-window-enable"})
