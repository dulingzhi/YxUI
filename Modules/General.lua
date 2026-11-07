local YxUI, Language, Assets, Settings = select(2, ...):get()

local Throttle = YxUI:GetModule("Throttle")
local GUI = YxUI:GetModule("GUI")

function YxUI:WelcomeMessage()
	if not Settings["ui-display-welcome"] then
		return
	end

	local Color = Settings["ui-widget-color"]

	print(format(Language["Welcome to |cFF%sHydra|r|cFFEFFFFFUI|r version |cFF%s%s|r"], Color, Settings["ui-header-font-color"], YxUI.UIVersion))
	print(format(Language["Type |cFF%s/hui|r to access the settings window, or click |cFF%s|Hcommand:/hui|h[here]|h|r."], Color, Color))
end

local UpdateUIScale = function(value)
	YxUI:SetScale(tonumber(value))
end

local UpdateFadeOpacity = function()
	if Settings["gui-enable-fade"] and GUI.IsMoving and GUI:IsShown() then
		GUI:PLAYER_STARTED_MOVING()
	end
end

local ToggleMove = function()
	YxUI:ToggleMovers()
end

local ResetMovers = function()
	YxUI:ResetAllMovers()
end

local function RestoreLanguageSelection()
	local Anchor = GUI:GetWidget("ui-language")
	local Dropdown = Anchor and Anchor.Dropdown
	if not Dropdown then return end
	Dropdown.Value = Settings["ui-language"]
	Dropdown.Menu.SynchronizedValue = nil
	for Label, Value in pairs(Dropdown.Values) do
		if Value == Dropdown.Value then
			Dropdown.Current:SetText(Label)
			YxUI:SetFontForText(Dropdown.Current, Label, Settings["ui-widget-font"], Settings["ui-font-size"], nil, Value)
			break
		end
	end
end

local function AcceptLanguage(value)
	if not YxUI.Languages[value] then return end
	YxUIData = YxUIData or {}
	YxUIData.LanguageOverrides = YxUIData.LanguageOverrides or {}
	YxUIData.LanguageOverrides[YxUI.UserProfileKey] = value
	GUI.WidgetCore.SetVariable("ui-language", value)
	ReloadUI()
end

local function SelectLanguage(value)
	if value == Settings["ui-language"] then return end
	YxUI:DisplayPopup(Language["Attention"], Language["You have changed a setting that requires a UI reload. Would you like to reload the UI now?"], ACCEPT, AcceptLanguage, CANCEL, RestoreLanguageSelection, value)
end

local UpdateGUIEnableFade = function(value)
	if value then
		GUI:RegisterEvent("PLAYER_STARTED_MOVING")
		GUI:RegisterEvent("PLAYER_STOPPED_MOVING")
	else
		GUI:UnregisterEvent("PLAYER_STARTED_MOVING")
		GUI:UnregisterEvent("PLAYER_STOPPED_MOVING")
		GUI.IsMoving = false
		GUI:SetAlpha(1)
	end
end

GUI:AddWidgetsID("General", "General", function(left, right)
	left:CreateHeader(Language["Welcome"])
	left:CreateSwitch("ui-display-welcome", Settings["ui-display-welcome"], Language["Display Welcome Message"], Language["Display a welcome message on login with UI information"])
	left:CreateDropdown("ui-language", Settings["ui-language"], YxUI:GetLanguageList(), Language["Language"], Language["Choose the language used by YxUI"], SelectLanguage):DisableSaving()
	--left:CreateSwitch("ui-display-whats-new", Settings["ui-display-whats-new"], Language[ [[Display "What's New" Pop-ups]] ], "")

	left:CreateHeader(Language["Move UI"])
	left:CreateButton("", Language["Toggle"], Language["Move UI"], Language["While toggled, you can drag some elements of YxUI around the screen"], ToggleMove)
	left:CreateButton("", Language["Restore"], Language["Restore to Defaults"], Language["Restore all YxUI movable frames to their default locations"], ResetMovers)

	right:CreateHeader(Language["Settings Window"])
	right:CreateSwitch("gui-hide-in-combat", Settings["gui-hide-in-combat"], Language["Hide in Combat"], Language["Hide the settings window when engaging in combat"])
	right:CreateSwitch("gui-enable-fade", Settings["gui-enable-fade"], Language["Fade While Moving"], Language["Fade out the settings window while moving"], UpdateGUIEnableFade)
	right:CreateSlider("gui-faded-alpha", Settings["gui-faded-alpha"], 0, 100, 10, Language["Set Faded Opacity"], Language["Set the opacity of the settings window while faded"], UpdateFadeOpacity, nil, "%")

	right:CreateHeader(Language["Border Thickness"])
	right:CreateSlider('ui-border-thickness', Settings['ui-border-thickness'], 0, 2, 1, Language["Border Thickness"], Language["Set how thick the border on UI elements is"], ReloadUI, nil, "px"):RequiresReload(true)
end)
YxUI:GetModule("GUI"):RegisterPageSettingsID("General", "General", {
	{"gui-enable-fade", UpdateGUIEnableFade},
	{"gui-faded-alpha", UpdateFadeOpacity},
}, nil)


-- Putting Styles here too
local function RestoreStyleSelection()
	local anchor = GUI:GetWidget("ui-style")
	local dropdown = anchor and anchor.Dropdown
	if not dropdown then return end

	local value = Settings["ui-style"]
	dropdown.Value = value
	dropdown.Menu.SynchronizedValue = nil
	for label, entry in pairs(dropdown.Values) do
		if entry == value then
			dropdown.Current:SetText(label)
			break
		end
	end
end

local function AcceptNewStyle(value)
	GUI.WidgetCore.SetVariable("ui-style", value)
	Assets:ApplyStyle(value)
	ReloadUI()
end

local function UpdateStyle(value)
	YxUI:DisplayPopup(Language["Attention"], format(Language['Are you sure you want to change the current style to "%s"?'], value), ACCEPT, AcceptNewStyle, CANCEL, RestoreStyleSelection, value)
end

GUI:AddWidgetsID("General", "Styles", function(left, right)
	left:CreateHeader(Language["Styles"])
	left:CreateDropdown("ui-style", Settings["ui-style"], Assets:GetStyleList(), Language["Select Style"], Language["Select a style to load"], UpdateStyle):DisableSaving()

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
	if parent ~= Durability then
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

if VehicleSeatIndicator then
	local SeatIndicator = YxUI:NewModule("Vehicle Seats")

	local SetSeatIndicatorPosition = function(self, anchor, parent)
		if parent ~= SeatIndicator then
			self:ClearAllPoints()
			self:SetPoint("CENTER", SeatIndicator, 0, 0)
		end
	end

	function SeatIndicator:Load()
		local Anchor, Parent, Anchor2, X, Y = VehicleSeatIndicator:GetPoint()

		if Anchor then
			self:SetPoint(Anchor, Parent, Anchor2, X, Y)
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

YxUI:GetModule("GUI"):RegisterReloadSettings({"ui-border-thickness"})
