local YxUI, Language, Assets, Settings = select(2, ...):get()

local Popup = CreateFrame("Frame", "YxUIPopupFrame", YxUI.UIParent, "BackdropTemplate")

local POPUP_WIDTH = 320
local POPUP_HEIGHT = 100
local BUTTON_WIDTH = ((POPUP_WIDTH - 6) / 2) - 1

-- IsSevere flag, where you need to hold accept for 1 sec to apply the click. place a statusbar in the button. For things like deleting profiles/saved data

local ButtonOnMouseUp = function(self)
	self.Texture:SetVertexColor(YxUI:HexToRGB(Settings["ui-button-texture-color"]))

	if self.Callback then
		self.Callback(self.Arg1, self.Arg2)
	end

	self.Text:ClearAllPoints()
	self.Text:SetPoint("CENTER", self, 0, 0)

	self:GetParent():Hide()
end

local ButtonOnMouseDown = function(self)
	local R, G, B = YxUI:HexToRGB(Settings["ui-button-texture-color"])

	self.Texture:SetVertexColor(R * 0.85, G * 0.85, B * 0.85)

	self.Text:ClearAllPoints()
	self.Text:SetPoint("CENTER", self, 1, -1)
end

local ButtonOnEnter = function(self)
	self.Highlight:SetAlpha(0.1)
end

local ButtonOnLeave = function(self)
	self.Highlight:SetAlpha(0)
end

local FadeOnFinished = function(self)
	self.Parent:Hide()
end

Popup.CreatePopupFrame = function(self)
	self:SetSize(POPUP_WIDTH, POPUP_HEIGHT)
	self:SetPoint("CENTER", YxUI.UIParent, 0, 234)
	self:SetBackdrop(YxUI.BackdropAndBorder)
	self:SetBackdropColor(YxUI:HexToRGB(Settings["ui-window-bg-color"]))
	self:SetBackdropBorderColor(0, 0, 0)
	self:SetFrameLevel(22)
	self:SetFrameStrata("HIGH")
	self:EnableMouse(true)
	self:SetMovable(true)
	self:RegisterForDrag("LeftButton")
	self:SetScript("OnDragStart", self.StartMoving)
	self:SetScript("OnDragStop", self.StopMovingOrSizing)
	self:SetClampedToScreen(true)
	self:SetAlpha(0)
	self:Hide()


	self.FadeIn = LibMotion:CreateAnimation(self, "Fade")
	self.FadeIn:SetEasing("in")
	self.FadeIn:SetDuration(0.15)
	self.FadeIn:SetChange(1)

	self.FadeOut = LibMotion:CreateAnimation(self, "Fade")
	self.FadeOut:SetEasing("out")
	self.FadeOut:SetDuration(0.15)
	self.FadeOut:SetChange(0)
	self.FadeOut:SetScript("OnFinished", FadeOnFinished)

	-- Header
	self.Header = CreateFrame("Frame", nil, self, "BackdropTemplate")
	self.Header:SetSize(POPUP_WIDTH - 6, 20)
	self.Header:SetPoint("TOP", self, 0, -3)
	self.Header:SetBackdrop(YxUI.BackdropAndBorder)
	self.Header:SetBackdropColor(0, 0, 0, 0)
	self.Header:SetBackdropBorderColor(0, 0, 0)

	self.Header.Texture = self.Header:CreateTexture(nil, "ARTWORK")
	self.Header.Texture:SetPoint("TOPLEFT", self.Header, 1, -1)
	self.Header.Texture:SetPoint("BOTTOMRIGHT", self.Header, -1, 1)
	self.Header.Texture:SetTexture(Assets:GetTexture(Settings["ui-header-texture"]))
	self.Header.Texture:SetVertexColor(YxUI:HexToRGB(Settings["ui-header-texture-color"]))

	self.Header.Text = self.Header:CreateFontString(nil, "OVERLAY")
	self.Header.Text:SetPoint("LEFT", self.Header, 5, -1)
	YxUI:SetFontInfo(self.Header.Text, Assets:GetFont(Settings["ui-header-font"]), 14)
	self.Header.Text:SetJustifyH("LEFT")
	self.Header.Text:SetShadowColor(0, 0, 0)
	self.Header.Text:SetShadowOffset(1, -1)
	self.Header.Text:SetTextColor(YxUI:HexToRGB(Settings["ui-header-font-color"]))

	-- Body
	self.Body = CreateFrame("Frame", nil, self, "BackdropTemplate")
	self.Body:SetSize(POPUP_WIDTH - 6, POPUP_HEIGHT - 50)
	self.Body:SetPoint("TOP", self.Header, "BOTTOM", 0, -2)
	self.Body:SetBackdrop(YxUI.BackdropAndBorder)
	self.Body:SetBackdropColor(YxUI:HexToRGB(Settings["ui-window-main-color"]))
	self.Body:SetBackdropBorderColor(0, 0, 0)

	self.Body.Text = self.Body:CreateFontString(nil, "OVERLAY")
	self.Body.Text:SetPoint("TOPLEFT", self.Body, 3, -3)
	self.Body.Text:SetPoint("BOTTOMRIGHT", self.Body, -3, 3)
	YxUI:SetFontInfo(self.Body.Text, Assets:GetFont(Settings["ui-button-font"]), Settings["ui-font-size"])
	self.Body.Text:SetShadowColor(0, 0, 0)
	self.Body.Text:SetShadowOffset(1, -1)
	self.Body.Text:SetText(value)

	-- Button1
	self.Button1 = CreateFrame("Frame", nil, self, "BackdropTemplate")
	self.Button1:SetSize(BUTTON_WIDTH, 20)
	self.Button1:SetPoint("BOTTOMLEFT", self, 3, 3)
	self.Button1:SetBackdrop(YxUI.BackdropAndBorder)
	self.Button1:SetBackdropColor(YxUI:HexToRGB(Settings["ui-button-texture-color"]))
	self.Button1:SetBackdropBorderColor(0, 0, 0)
	self.Button1:SetScript("OnMouseUp", ButtonOnMouseUp)
	self.Button1:SetScript("OnMouseDown", ButtonOnMouseDown)
	self.Button1:SetScript("OnEnter", ButtonOnEnter)
	self.Button1:SetScript("OnLeave", ButtonOnLeave)

	self.Button1.Texture = self.Button1:CreateTexture(nil, "BORDER")
	self.Button1.Texture:SetPoint("TOPLEFT", self.Button1, 1, -1)
	self.Button1.Texture:SetPoint("BOTTOMRIGHT", self.Button1, -1, 1)
	self.Button1.Texture:SetTexture(Assets:GetTexture(Settings["ui-button-texture"]))
	self.Button1.Texture:SetVertexColor(YxUI:HexToRGB(Settings["ui-button-texture-color"]))

	self.Button1.Highlight = self.Button1:CreateTexture(nil, "ARTWORK")
	self.Button1.Highlight:SetPoint("TOPLEFT", self.Button1, 1, -1)
	self.Button1.Highlight:SetPoint("BOTTOMRIGHT", self.Button1, -1, 1)
	self.Button1.Highlight:SetTexture(Assets:GetTexture("Blank"))
	self.Button1.Highlight:SetVertexColor(1, 1, 1, 0.4)
	self.Button1.Highlight:SetAlpha(0)

	self.Button1.Text = self.Button1:CreateFontString(nil, "OVERLAY")
	self.Button1.Text:SetPoint("CENTER", self.Button1)
	self.Button1.Text:SetSize(BUTTON_WIDTH - 6, 20)
	self.Button1.Text:SetFont(Assets:GetFont(Settings["ui-button-font"]), Settings["ui-font-size"])
	self.Button1.Text:SetJustifyH("CENTER")
	self.Button1.Text:SetShadowColor(0, 0, 0)
	self.Button1.Text:SetShadowOffset(1, -1)
	self.Button1.Text:SetText(value)

	-- Button2
	self.Button2 = CreateFrame("Frame", nil, self, "BackdropTemplate")
	self.Button2:SetSize(BUTTON_WIDTH, 20)
	self.Button2:SetPoint("BOTTOMRIGHT", self, -3, 3)
	self.Button2:SetBackdrop(YxUI.BackdropAndBorder)
	self.Button2:SetBackdropColor(YxUI:HexToRGB(Settings["ui-button-texture-color"]))
	self.Button2:SetBackdropBorderColor(0, 0, 0)
	self.Button2:SetScript("OnMouseUp", ButtonOnMouseUp)
	self.Button2:SetScript("OnMouseDown", ButtonOnMouseDown)
	self.Button2:SetScript("OnEnter", ButtonOnEnter)
	self.Button2:SetScript("OnLeave", ButtonOnLeave)

	self.Button2.Texture = self.Button2:CreateTexture(nil, "BORDER")
	self.Button2.Texture:SetPoint("TOPLEFT", self.Button2, 1, -1)
	self.Button2.Texture:SetPoint("BOTTOMRIGHT", self.Button2, -1, 1)
	self.Button2.Texture:SetTexture(Assets:GetTexture(Settings["ui-button-texture"]))
	self.Button2.Texture:SetVertexColor(YxUI:HexToRGB(Settings["ui-button-texture-color"]))

	self.Button2.Highlight = self.Button2:CreateTexture(nil, "ARTWORK")
	self.Button2.Highlight:SetPoint("TOPLEFT", self.Button2, 1, -1)
	self.Button2.Highlight:SetPoint("BOTTOMRIGHT", self.Button2, -1, 1)
	self.Button2.Highlight:SetTexture(Assets:GetTexture("Blank"))
	self.Button2.Highlight:SetVertexColor(1, 1, 1, 0.4)
	self.Button2.Highlight:SetAlpha(0)

	self.Button2.Text = self.Button2:CreateFontString(nil, "OVERLAY")
	self.Button2.Text:SetPoint("CENTER", self.Button2, "CENTER", 0, 0)
	self.Button2.Text:SetSize(BUTTON_WIDTH - 6, 20)
	self.Button2.Text:SetFont(Assets:GetFont(Settings["ui-button-font"]), Settings["ui-font-size"])
	self.Button2.Text:SetJustifyH("CENTER")
	self.Button2.Text:SetShadowColor(0, 0, 0)
	self.Button2.Text:SetShadowOffset(1, -1)
	self.Button2.Text:SetText(value)

	self.Created = true
end

Popup.Display = function(self, header, body, accept, acceptfunc, cancel, cancelfunc, arg1, arg2)
	if (not self.Created) then
		self:CreatePopupFrame()
	end

	self.Header.Text:SetText(header)

	self.Body.Text:SetText(body)

	self.Button1.Text:SetText(accept)
	self.Button1.Callback = acceptfunc and acceptfunc or nil

	self.Button2.Text:SetText(cancel)
	self.Button2.Callback = cancelfunc and cancelfunc or nil

	self.Button1.Arg1 = arg1
	self.Button1.Arg2 = arg2

	self.Button2.Arg1 = arg1
	self.Button2.Arg2 = arg2

	if (not self:IsShown()) then
		self:SetAlpha(0)
		self:Show()
		self.FadeIn:Play()
	end
end

function YxUI:ClearPopup()
	Popup.FadeOut:Play()
end

function YxUI:DisplayPopup(...)
	Popup:Display(...)
end