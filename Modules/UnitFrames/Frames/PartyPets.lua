local YxUI, Language, _, Settings, Defaults = select(2, ...):get()

Defaults["party-pets-enable"] = true
Defaults["party-pets-width"] = 78
Defaults["party-pets-health-height"] = 22
Defaults["party-pets-health-reverse"] = false
Defaults["party-pets-health-color"] = "CLASS"
Defaults["party-pets-health-orientation"] = "HORIZONTAL"
Defaults["party-pets-health-smooth"] = true

local UF = YxUI:GetModule("Unit Frames")

local PartyPetsFrameConfig = {
	settingsPrefix = "party-pets",
	backdropLayer = "BORDER",
	healthTextureKey = "ui-widget-texture",
	healthBackgroundLayer = "BACKGROUND",
	healthOrientation = true,
	healthSmoothKey = "party-pets-health-smooth",
	healthFrequentUpdates = true,
	healthTags = false,
	fontKey = "party-font",
	fontSizeKey = "party-font-size",
	fontFlagsKey = "party-font-flags",
	middleTag = "[Name10]",
	mouseoverKey = "PartyEnableMouseover",
	power = false,
	colorDisconnected = true,
	raidTarget = true,
	range = {},
}

YxUI.StyleFuncs["partypet"] = function(self, unit)
	PartyPetsFrameConfig.range.insideAlpha = Settings["party-in-range"] / 100
	PartyPetsFrameConfig.range.outsideAlpha = Settings["party-out-of-range"] / 100

	UF:BuildSingleUnitFrame(self, unit, PartyPetsFrameConfig)
end

local function UpdatePetHealth(operation)
	return function(value)
		UF:UpdatePetFrames("party-pets", operation, value)
	end
end

YxUI:GetModule("GUI"):AddWidgetsID("General", "Party Pets", "Unit Frames", function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("party-pets-enable", Settings["party-pets-enable"], Language["Enable Party Pet Frames"], Language["Enable the party pet frames module"], ReloadUI):RequiresReload(true)

	right:CreateHeader(Language["Party Pets Size"])
	right:CreateSlider("party-pets-width", Settings["party-pets-width"], 40, 200, 1, Language["Width"], Language["Set the width of party pet unit frames"], function() UF:UpdatePetDimensions("party-pets") end, nil)

	right:CreateHeader(Language["Health"])
	right:CreateSlider("party-pets-health-height", Settings["party-pets-health-height"], 12, 60, 1, Language["Health Height"], Language["Set the height of party health bars"], function() UF:UpdatePetDimensions("party-pets") end)
	right:CreateDropdown("party-pets-health-color", Settings["party-pets-health-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Custom"]] = "CUSTOM"}, Language["Health Bar Color"], Language["Set the color of the health bar"], UpdatePetHealth("healthColor"))
	right:CreateDropdown("party-pets-health-orientation", Settings["party-pets-health-orientation"], {[Language["Horizontal"]] = "HORIZONTAL", [Language["Vertical"]] = "VERTICAL"}, Language["Fill Orientation"], Language["Set the fill orientation of the health bar"], UpdatePetHealth("healthOrientation"))
	right:CreateSwitch("party-pets-health-reverse", Settings["party-pets-health-reverse"], Language["Reverse Health Fill"], Language["Reverse the fill of the health bar"], UpdatePetHealth("healthReverse"))
	right:CreateSwitch("party-pets-health-smooth", Settings["party-pets-health-smooth"], Language["Smooth Health"], Language["Animate health changes"], UpdatePetHealth("healthSmooth"))
end)
YxUI:GetModule("GUI"):RegisterPageSettingsID("General", "Party Pets", {
	{"party-pets-width", function() UF:UpdatePetDimensions("party-pets") end},
	{"party-pets-health-height", function() UF:UpdatePetDimensions("party-pets") end},
	{"party-pets-health-color", UpdatePetHealth("healthColor")},
	{"party-pets-health-orientation", UpdatePetHealth("healthOrientation")},
	{"party-pets-health-reverse", UpdatePetHealth("healthReverse")},
	{"party-pets-health-smooth", UpdatePetHealth("healthSmooth")},
}, "Unit Frames")


YxUI:GetModule("GUI"):RegisterReloadSettings({"party-pets-enable"})
