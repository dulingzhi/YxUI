local YxUI, Language, Assets, Settings, Defaults = select(2, ...):get()

local DT = YxUI:NewModule("DataText")

-- Default settings values
Defaults["data-text-font"] = "Roboto"
Defaults["data-text-font-size"] = 12
Defaults["data-text-font-flags"] = ""
Defaults["data-text-label-color"] = "FFFFFF"
Defaults["data-text-value-color"] = "FFC44D"
Defaults["data-text-chat-left"] = "Gold"
Defaults["data-text-chat-middle"] = "Crit"
Defaults["data-text-chat-right"] = "Durability"
Defaults["data-text-minimap-top"] = "Location"
Defaults["data-text-minimap-bottom"] = "Time - Local"
Defaults["data-text-extra-left"] = "Bag Slots"
Defaults["data-text-extra-middle"] = "Friends"
Defaults["data-text-extra-right"] = "Guild"
Defaults["data-text-enable-tooltips"] = true
Defaults["data-text-hover-tooltips"] = true
Defaults["data-text-24-hour"] = false
Defaults["data-text-classcolor"] = false

DT.Anchors = {}
DT.Types = {}
DT.List = {}
YxUI.ValueColor = "ffffff"

local SetTooltip = function(anchor)
	if Settings["data-text-hover-tooltips"] then
		local X, Y = anchor:GetCenter()
		local Position = (Y > YxUI.UIParent:GetHeight() / 2) and "TOP" or "BOTTOM"

		GameTooltip:SetOwner(anchor, "ANCHOR_NONE")
		GameTooltip:ClearAllPoints()

		if (Position == "TOP") then
			GameTooltip:SetPoint("TOP", anchor, "BOTTOM", 0, -8)
		else
			GameTooltip:SetPoint("BOTTOM", anchor, "TOP", 0, 8)
		end
	else
		GameTooltip_SetDefaultAnchor(GameTooltip, anchor)
	end
end

function DT:OnMouseDown()
	self.Text:SetPoint("LEFT", self, 2, -1)
	self.Text:SetPoint("RIGHT", self, 0, -1)
end

function DT:OnMouseUp()
	self.Text:SetPoint("LEFT", self, 0, 0)
	self.Text:SetPoint("RIGHT", self, 0, 0)
end

function DT:NewAnchor(name, parent)
	if self.Anchors[name] then
		return
	end

	if (not parent) then
		parent = YxUI.UIParent
	end

	local Anchor = CreateFrame("Frame", nil, parent)
	Anchor:SetFrameLevel(parent:GetFrameLevel() + 1)
	Anchor:SetFrameStrata(parent:GetFrameStrata())
	Anchor.Name = name
	Anchor.SetTooltip = SetTooltip
    parent.Anchor = Anchor

	Anchor.Text = Anchor:CreateFontString(nil, "OVERLAY")
	YxUI:SetFontInfo(Anchor.Text, Settings["data-text-font"], Settings["data-text-font-size"], Settings["data-text-font-flags"])
	Anchor.Text:SetPoint("LEFT", Anchor, 0, 0)
	Anchor.Text:SetPoint("RIGHT", Anchor, 0, 0)
	Anchor.Text:SetJustifyH("CENTER")
	Anchor.Text:SetHeight(Settings["data-text-font-size"])

	Anchor.Highlight = Anchor:CreateTexture(nil, "ARTWORK")
	Anchor.Highlight:SetHeight(14)
	Anchor.Highlight:SetPoint("BOTTOMLEFT", Anchor, "BOTTOMLEFT", 18, 1)
	Anchor.Highlight:SetPoint("BOTTOMRIGHT", Anchor, "BOTTOMRIGHT", -18, 1)
	Anchor.Highlight:SetTexture(Assets:GetTexture("RenHorizonUp"))
	Anchor.Highlight:SetVertexColor(YxUI:HexToRGB(Settings["ui-widget-color"]))
	Anchor.Highlight:SetAlpha(0)

	self.Anchors[name] = Anchor

	return Anchor
end

function DT:GetAnchor(name)
	if self.Anchors[name] then
		return self.Anchors[name]
	end
end

function DT:SetDataText(anchor, name)
	if ((not self.Anchors[anchor]) or (not self.Types[name])) then
		return
	end

	local Anchor = self.Anchors[anchor]
	local Type = self.Types[name]

	if Anchor.Disable then
		Anchor:Disable()
	end

	Anchor.Enable = Type.Enable
	Anchor.Disable = Type.Disable
	Anchor.Update = Type.Update

	Anchor:Enable()

	Anchor:HookScript("OnMouseDown", self.OnMouseDown)
	Anchor:HookScript("OnMouseUp", self.OnMouseUp)
end

function DT:SetTooltipsEnabled(value)
	for Name, Anchor in next, self.Anchors do
		if (Anchor:HasScript("OnEnter")) then
			Anchor:EnableMouse(value)
		end
	end
end

function DT:UpdateAllAnchors()
	for Name, Anchor in next, self.Anchors do
		if Anchor.Update then
			Anchor:Update(999, "player")
		end
	end
end

function DT:Load()
	YxUI.ValueColor = Settings["data-text-classcolor"] and YxUI.ClassColors[YxUI.UserClass].Hex or Settings["data-text-value-color"]

	if Settings["chat-enable"] then
		local Width = YxUIChatFrameBottom:GetWidth() / 3
		local Height = YxUIChatFrameBottom:GetHeight()

		local ChatLeft = self:NewAnchor("Chat-Left", YxUIChatFrameBottom)
		ChatLeft:SetSize(Width, Height)
		ChatLeft:SetPoint("LEFT", YxUIChatFrameBottom, 0, 0)

		local ChatMiddle = self:NewAnchor("Chat-Middle", YxUIChatFrameBottom)
		ChatMiddle:SetSize(Width, Height)
		ChatMiddle:SetPoint("LEFT", ChatLeft, "RIGHT", 0, 0)

		local ChatRight = self:NewAnchor("Chat-Right", YxUIChatFrameBottom)
		ChatRight:SetSize(Width, Height)
		ChatRight:SetPoint("LEFT", ChatMiddle, "RIGHT", 0, 0)

		self:SetDataText("Chat-Left", Settings["data-text-chat-left"])
		self:SetDataText("Chat-Middle", Settings["data-text-chat-middle"])
		self:SetDataText("Chat-Right", Settings["data-text-chat-right"])
	end

	if Settings["minimap-enable"] then
		local MinimapTop = self:NewAnchor("Minimap-Top", YxUIMinimapTop)
		MinimapTop:SetSize(YxUIMinimapTop:GetSize())
		MinimapTop:SetPoint("CENTER", YxUIMinimapTop, 0, 0)

		local MinimapBottom = self:NewAnchor("Minimap-Bottom", YxUIMinimapBottom)
		MinimapBottom:SetSize(YxUIMinimapBottom:GetSize())
		MinimapBottom:SetPoint("CENTER", YxUIMinimapBottom, 0, 0)

		self:SetDataText("Minimap-Top", Settings["data-text-minimap-top"])
		self:SetDataText("Minimap-Bottom", Settings["data-text-minimap-bottom"])
	end

	SetCVar("timeMgrUseMilitaryTime", Settings["data-text-24-hour"])

	self:SetTooltipsEnabled(Settings["data-text-enable-tooltips"])
	self:UpdateAllAnchors()
end

function YxUI:AddDataText(name, enable, disable, update)
	if DT.Types[name] then
		return
	end

	DT.Types[name] = {Enable = enable, Disable = disable, Update = update}
	DT.List[name] = name
end

local UpdateChatLeftText = function(value)
	DT:SetDataText("Chat-Left", value)
end

local UpdateChatMiddleText = function(value)
	DT:SetDataText("Chat-Middle", value)
end

local UpdateChatRightText = function(value)
	DT:SetDataText("Chat-Right", value)
end

local UpdateWindowLeftText = function(value)
	DT:SetDataText("Window-Left", value)
end

local UpdateWindowMiddleText = function(value)
	DT:SetDataText("Window-Middle", value)
end

local UpdateWindowRightText = function(value)
	DT:SetDataText("Window-Right", value)
end

local UpdateMinimapTopText = function(value)
	if Settings["minimap-enable"] then
		DT:SetDataText("Minimap-Top", value)
	end
end

local UpdateMinimapBottomText = function(value)
	if Settings["minimap-enable"] then
		DT:SetDataText("Minimap-Bottom", value)
	end
end

local UpdateFont = function()
	for Name, Anchor in next, DT.Anchors do
		YxUI:SetFontInfo(Anchor.Text, Settings["data-text-font"], Settings["data-text-font-size"], Settings["data-text-font-flags"])
	end
end

local UpdateEnableTooltips = function(value)
	DT:SetTooltipsEnabled(value)
end

local ResetOnAccept = function()
	YxUI:GetModule("Gold"):Reset()
end

local ResetGold = function()
	YxUI:DisplayPopup(Language["Attention"], Language["Are you sure you would like to reset all stored gold information?"], ACCEPT, ResetOnAccept, CANCEL)
end

local UpdateTimeFormat = function(value)
	SetCVar("timeMgrUseMilitaryTime", value)
	DT:UpdateAllAnchors()
end

local DeleteGoldData = function(value)
	if YxUI.GoldData[YxUI.UserRealm] then
		for name, money in next, YxUI.GoldData[YxUI.UserRealm] do
			if (string.match(name, "|cff%x%x%x%x%x%x(.*)|r") == value) then
				YxUI.GoldData[YxUI.UserRealm][name] = nil

				YxUI:print(format(Language["Deleted stored gold data for %s."], name))

				return
			end
		end

		YxUI:print(format(Language["No character data found for %s."], value))
	end
end

local UpdateClassColor = function(value)
	YxUI.ValueColor = value and YxUI.ClassColors[YxUI.UserClass].Hex or Settings["data-text-value-color"]

	DT:UpdateAllAnchors()
end

YxUI:GetModule("GUI"):AddWidgets(Language["General"], Language["Data Texts"], function(left, right)
	left:CreateHeader(Language["Chat Frame Texts"])
	left:CreateDropdown("data-text-chat-left", Settings["data-text-chat-left"], DT.List, Language["Set Left Text"], Language["Set the information to be displayed in the left data text anchor"], UpdateChatLeftText)
	left:CreateDropdown("data-text-chat-middle", Settings["data-text-chat-middle"], DT.List, Language["Set Middle Text"], Language["Set the information to be displayed in the middle data text anchor"], UpdateChatMiddleText)
	left:CreateDropdown("data-text-chat-right", Settings["data-text-chat-right"], DT.List, Language["Set Right Text"], Language["Set the information to be displayed in the right data text anchor"], UpdateChatRightText)

	left:CreateHeader(Language["Right Window Texts"])
	left:CreateDropdown("data-text-extra-left", Settings["data-text-extra-left"], DT.List, Language["Set Left Text"], Language["Set the information to be displayed in the left data text anchor"], UpdateWindowLeftText)
	left:CreateDropdown("data-text-extra-middle", Settings["data-text-extra-middle"], DT.List, Language["Set Middle Text"], Language["Set the information to be displayed in the middle data text anchor"], UpdateWindowMiddleText)
	left:CreateDropdown("data-text-extra-right", Settings["data-text-extra-right"], DT.List, Language["Set Right Text"], Language["Set the information to be displayed in the right data text anchor"], UpdateWindowRightText)

	left:CreateHeader(Language["Mini Map Texts"])
	left:CreateDropdown("data-text-minimap-top", Settings["data-text-minimap-top"], DT.List, Language["Set Top Text"], Language["Set the information to be displayed in the top mini map data text anchor"], UpdateMinimapTopText)
	left:CreateDropdown("data-text-minimap-bottom", Settings["data-text-minimap-bottom"], DT.List, Language["Set Bottom Text"], Language["Set the information to be displayed in the bottom mini map data text anchor"], UpdateMinimapBottomText)

	right:CreateHeader(Language["Font"])
	right:CreateDropdown("data-text-font", Settings["data-text-font"], Assets:GetFontList(), Language["Font"], Language["Set the font of the data texts"], UpdateFont, "Font")
	right:CreateSlider("data-text-font-size", Settings["data-text-font-size"], 8, 32, 1, Language["Font Size"], Language["Set the font size of the data texts"], UpdateFont)
	right:CreateDropdown("data-text-font-flags", Settings["data-text-font-flags"], Assets:GetFlagsList(), Language["Font Flags"], Language["Set the font flags of the data texts"], UpdateFont)

	right:CreateHeader(Language["Colors"])
	right:CreateColorSelection("data-text-label-color", Settings["data-text-label-color"], Language["Label Color"], Language["Set the text color of data text labels"], function() DT:UpdateAllAnchors() end)
	right:CreateColorSelection("data-text-value-color", Settings["data-text-value-color"], Language["Value Color"], Language["Set the text color of data text values"], function() DT:UpdateAllAnchors() end)
	right:CreateSwitch("data-text-classcolor", Settings["data-text-classcolor"], Language["Use Class Color"], Language["Use class color for Value Color"], UpdateClassColor)

	right:CreateHeader(Language["Styling"])
	right:CreateSwitch("data-text-enable-tooltips", Settings["data-text-enable-tooltips"], Language["Enable Tooltips"], Language["Display tooltip information when hovering over data texts"], UpdateEnableTooltips)
	right:CreateSwitch("data-text-hover-tooltips", Settings["data-text-hover-tooltips"], Language["Hover Tooltips"], Language["Display tooltip information directly by the data text instead of at the default tooltip location"])
	right:CreateSwitch("data-text-24-hour", Settings["data-text-24-hour"], Language["Enable 24 Hour Time"], Language["Display time in a 24 hour format"], UpdateTimeFormat)

	right:CreateHeader(Language["Gold"])
	right:CreateButton("", Language["Reset"], Language["Reset Gold"], Language["Reset stored information for each characters gold"], ResetGold)
	right:CreateInput("gold-reset", YxUI.UserName, Language["Delete Character Data"], Language["Remove the stored data for a character. Enter the character name and hit enter."], DeleteGoldData):DisableSaving()

	--left:CreateHeader(Language["Misc."])
	--left:CreateSlider("data-text-max-lines", Settings["data-text-max-lines"], 5, 50, 1, "Max Lines", "Set the maximum number of players shown in the guild or friends data text tooltips")
end)