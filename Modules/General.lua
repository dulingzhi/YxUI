local YxUI, Language, Assets, Settings = select(2, ...):get()

local Throttle = YxUI:GetModule("Throttle")
local GUI = YxUI:GetModule("GUI")

function YxUI:WelcomeMessage()
	if (not Settings["ui-display-welcome"]) then
		return
	end

	local Color = Settings["ui-widget-color"]

	print(format(Language["Welcome to |cFF%sYx|r|cFFEFFFFFUI|r version |cFF%s%s|r - https://dd.163.com/i/zY5l3huBtM"], Color, Settings["ui-header-font-color"], YxUI.UIVersion))
	print(format(Language["Type |cFF%s/yxui|r to access the settings window, or click |cFF%s|Hcommand:/yxui|h[here]|h|r."], Color, Color))
end

local UpdateUIScale = function(value)
	YxUI:SetScale(tonumber(value))
end

local GetDiscordLink = function()
	if (not Throttle:IsThrottled("discord-request")) then
		YxUI:print(Language["Join the NetEase DD community for support and feedback https://dd.163.com/i/zY5l3huBtM"])

		Throttle:Start("discord-request", 10)
	end
end

local GetYouTubeLink = function()
	if (not Throttle:IsThrottled("yt-request")) then
		YxUI:print(Language["Subscribe to YouTube to see new features https://www.youtube.com/c/HydraMods"])

		Throttle:Start("yt-request", 10)
	end
end

local ToggleMove = function()
	YxUI:ToggleMovers()
end

local ResetMovers = function()
	YxUI:ResetAllMovers()
end

local UpdateGUIEnableFade = function(value)
	if value then
		GUI:RegisterEvent("PLAYER_STARTED_MOVING")
		GUI:RegisterEvent("PLAYER_STOPPED_MOVING")
	else
		GUI:UnregisterEvent("PLAYER_STARTED_MOVING")
		GUI:UnregisterEvent("PLAYER_STOPPED_MOVING")
		GUI:SetAlpha(1)
	end
end

GUI:AddWidgets(Language["General"], Language["General"], function(left, right)
	left:CreateHeader(Language["Welcome"])
	left:CreateSwitch("ui-display-welcome", Settings["ui-display-welcome"], Language["Display Welcome Message"], Language["Display a welcome message on login with UI information"])
	--left:CreateSwitch("ui-display-whats-new", Settings["ui-display-whats-new"], Language[ [[Display "What's New" Pop-ups]] ], "")
	left:CreateButton("", Language["Get Link"], Language["Join NetEase DD"], Language["Get a link to join the YxUI NetEase DD community"], GetDiscordLink)
	left:CreateButton("", Language["Get Link"], Language["Watch YouTube"], Language["Get a link for the YxUI YouTube channel"], GetYouTubeLink)

	left:CreateHeader(Language["Move UI"])
	left:CreateButton("", Language["Toggle"], Language["Move UI"], Language["While toggled, you can drag some elements of YxUI around the screen"], ToggleMove)
	left:CreateButton("", Language["Restore"], Language["Restore To Defaults"], Language["Restore all YxUI movable frames to their default locations"], ResetMovers)

	right:CreateHeader(Language["Settings Window"])
	right:CreateSwitch("gui-hide-in-combat", Settings["gui-hide-in-combat"], Language["Hide In Combat"], Language["Hide the settings window when engaging in combat"])
	right:CreateSwitch("gui-enable-fade", Settings["gui-enable-fade"], Language["Fade While Moving"], Language["Fade out the settings window while moving"], UpdateGUIEnableFade)
	right:CreateSlider("gui-faded-alpha", Settings["gui-faded-alpha"], 0, 100, 10, Language["Set Faded Opacity"], Language["Set the opacity of the settings window while faded"], nil, nil, "%")

	right:CreateHeader(Language["Border Thickness"])
	right:CreateSlider('ui-border-thickness', Settings['ui-border-thickness'], 0, 2, 1, Language["Border Thickness"], Language["Set how thick the border on UI elements is"], ReloadUI, nil, "px"):RequiresReload(true)
end)

-- Putting Styles here too
local AcceptNewStyle = function(value)
	Assets:ApplyStyle(value)

	ReloadUI()
end

local UpdateStyle = function(value)
	YxUI:DisplayPopup(Language["Attention"], format(Language['Are you sure you would like to change to the current style to "%s"?'], value), ACCEPT, AcceptNewStyle, CANCEL, nil, value)
end

GUI:AddWidgets(Language["General"], Language["Styles"], function(left, right)
	left:CreateHeader(Language["Styles"])
	left:CreateDropdown("ui-style", Settings["ui-style"], Assets:GetStyleList(), Language["Select Style"], Language["Select a style to load"], UpdateStyle)

	left:CreateHeader(Language["Headers"])
	left:CreateColorSelection("ui-header-font-color", Settings["ui-header-font-color"], Language["Text Color"], "")
	left:CreateColorSelection("ui-header-texture-color", Settings["ui-header-texture-color"], Language["Texture Color"], "")
	left:CreateDropdown("ui-header-texture", Settings["ui-header-texture"], Assets:GetTextureList(), Language["Texture"], "", nil, "Texture")
	left:CreateDropdown("ui-header-font", Settings["ui-header-font"], Assets:GetFontList(), Language["Header Font"], "", nil, "Font")

	left:CreateHeader(Language["Widgets"])
	left:CreateColorSelection("ui-widget-color", Settings["ui-widget-color"], Language["Color"], "")
	left:CreateColorSelection("ui-widget-bright-color", Settings["ui-widget-bright-color"], Language["Bright Color"], "")
	left:CreateColorSelection("ui-widget-bg-color", Settings["ui-widget-bg-color"], Language["Background Color"], "")
	left:CreateColorSelection("ui-widget-font-color", Settings["ui-widget-font-color"], Language["Label Color"], "")
	left:CreateDropdown("ui-widget-texture", Settings["ui-widget-texture"], Assets:GetTextureList(), Language["Texture"], "", nil, "Texture")
	left:CreateDropdown("ui-widget-font", Settings["ui-widget-font"], Assets:GetFontList(), Language["Font"], "", nil, "Font")

	right:CreateHeader(Language["What is a style?"])
	right:CreateMessage("", Language["Styles store visual settings such as fonts, textures, and colors to create an overall theme."])

	right:CreateHeader(Language["Console"])
	right:CreateButton("", Language["Reload"], Language["Reload UI"], Language["Reload the UI"], ReloadUI)
	--right:CreateButton("", Language["Delete"], Language["Delete Saved Variables"], Language["Reset all saved variables"], YxUI.Reset)

	right:CreateHeader(Language["Windows"])
	right:CreateColorSelection("ui-window-bg-color", Settings["ui-window-bg-color"], Language["Background Color"], "")
	right:CreateColorSelection("ui-window-main-color", Settings["ui-window-main-color"], Language["Main Color"], "")

	right:CreateHeader(Language["Buttons"])
	right:CreateColorSelection("ui-button-texture-color", Settings["ui-button-texture-color"], Language["Texture Color"], "")
	right:CreateColorSelection("ui-button-font-color", Settings["ui-button-font-color"], Language["Font Color"], "")
	right:CreateDropdown("ui-button-texture", Settings["ui-button-texture"], Assets:GetTextureList(), Language["Texture"], "", nil, "Texture")
	right:CreateDropdown("ui-button-font", Settings["ui-button-font"], Assets:GetFontList(), Language["Font"], "", nil, "Font")

	left:CreateHeader(Language["Font Sizes"])
	left:CreateSlider("ui-font-size", Settings["ui-font-size"], 8, 32, 1, Language["General Font Size"], Language["Set the general font size of the UI"])
	left:CreateSlider("ui-header-font-size", Settings["ui-header-font-size"], 8, 32, 1, Language["Header Font Size"], Language["Set the font size of header elements in the UI"])
	left:CreateSlider("ui-title-font-size", Settings["ui-title-font-size"], 8, 32, 1, Language["Title Font Size"], Language["Set the font size of title elements in the UI"])
end)

local Durability = YxUI:NewModule("Durability")

local SetDurabilityPosition = function(self, anchor, parent)
	if (parent ~= Durability) then
		self:ClearAllPoints()
		self:SetPoint("CENTER", Durability, 0, 0)
	end
end

function Durability:Load() -- Maybe a setting to hide the whole frame?
	self:SetSize(DurabilityFrame:GetSize())
	self:SetPoint("BOTTOM", YxUIParent, -360, 10)

	DurabilityFrame:SetScript("OnShow", nil)
	DurabilityFrame:SetScript("OnHide", nil)
	hooksecurefunc(DurabilityFrame, "SetPoint", SetDurabilityPosition)

	YxUI:CreateMover(self)
end

if (not YxUI.IsClassic) then
	local SeatIndicator = YxUI:NewModule("Vehicle Seats")

	local SetSeatIndicatorPosition = function(self, anchor, parent)
		if (parent ~= SeatIndicator) then
			self:ClearAllPoints()
			self:SetPoint("CENTER", SeatIndicator, 0, 0)
		end
	end

	function SeatIndicator:Load()
		local Anchor, Parent, Anchor2, X, Y = VehicleSeatIndicator:GetPoint()

		if Anchor then
			self:SetPoint(Anchor, Parent, Anchor2, X, Y - 80)
		else
			self:SetPoint("CENTER", UIParent, 0, 0)
		end

		self:SetSize(VehicleSeatIndicator:GetSize())

		VehicleSeatIndicator:SetScript("OnShow", nil)
		VehicleSeatIndicator:SetScript("OnHide", nil)
		hooksecurefunc(VehicleSeatIndicator, "SetPoint", SetSeatIndicatorPosition)

		YxUI:CreateMover(self)
	end
end