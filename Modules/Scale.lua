local YxUI, Language, Assets, Settings, Defaults = select(2, ...):get()

Defaults["enable-scale"] = true
Defaults["ui-scale"] = (768 / select(2, GetPhysicalScreenSize()))

local Scale = YxUI:NewModule("Scale")

function Scale:Load()
	C_CVar.SetCVar("useUiScale", Settings["enable-scale"] and "1" or "0")
	C_CVar.SetCVar("uiScale", Settings["ui-scale"])
end

local function ShowScaleValue(value)
	local anchor = YxUI:GetModule("GUI"):GetWidget("ui-scale")
	if not anchor or not anchor.Slider then return end
	local slider = anchor.Slider
	slider.AppliedValue = value
	slider.EditBox.Value = value
	slider:SetValue(value)
	slider.EditBox:SetText(slider.Prefix .. value .. slider.Postfix)
end

local function AcceptScale(value)
	YxUI:GetModule("GUI").WidgetCore.SetVariable("ui-scale", value)
	C_CVar.SetCVar("uiScale", value)
	ShowScaleValue(value)
end

local function CancelScale()
	ShowScaleValue(Settings["ui-scale"])
end

local function SetSuggestedScale()
	local value = (768 / select(2, GetPhysicalScreenSize()))
	YxUI:DisplayPopup(Language["Attention"], format(Language["Are you sure you want to change your UI scale to %s?"], value), ACCEPT, AcceptScale, CANCEL, CancelScale, value)
end

local function SetScaleFromSlider(value)
	YxUI:DisplayPopup(Language["Attention"], format(Language["Are you sure you want to change your UI scale to %s?"], value), ACCEPT, AcceptScale, CANCEL, CancelScale, value)
end

local UseUIScale = function(value)
	C_CVar.SetCVar("useUiScale", value == true and "1" or "0")
end

YxUI:GetModule("GUI"):AddWidgetsID("General", "General", function(left, right)
	right:CreateHeader(Language["Scale"])
	right:CreateSwitch("enable-scale", C_CVar.GetCVar("useUiScale") == "1" and true or false, USE_UISCALE, OPTION_TOOLTIP_USE_UISCALE, UseUIScale)
	right:CreateButton("", Language["Apply"], Language["Set Suggested Scale"], Language["Apply the recommended scale based on your resolution"], SetSuggestedScale)
	right:CreateSlider("ui-scale", tonumber(C_CVar.GetCVar("uiScale")), 0.4, 1.2, 0.01, Language["Set UI Scale"], Language["Adjust the UI scale"], SetScaleFromSlider):DisableSaving()
end)
YxUI:GetModule("GUI"):RegisterPageSettingsID("General", "General", {
	{"enable-scale", UseUIScale},
}, nil)

