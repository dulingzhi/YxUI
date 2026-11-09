local YxUI, Language, Assets, Settings, Defaults = select(2, ...):get()

Defaults["party-enable"] = true
Defaults["party-width"] = 78
Defaults["party-show-debuffs"] = true
Defaults["party-show-role"] = true
Defaults["party-show-aurawatch"] = true
Defaults["party-in-range"] = 100
Defaults["party-out-of-range"] = 50
Defaults["party-health-height"] = 42 -- 40
Defaults["party-health-reverse"] = false
Defaults["party-health-color"] = "CLASS"
Defaults["party-health-orientation"] = "HORIZONTAL"
Defaults["party-health-top"] = "[Name(10)]"
Defaults["party-health-bottom"] = "[HealthDeficit:Short]"
Defaults["party-health-smooth"] = true
Defaults["party-power-enable"] = true
Defaults["party-power-height"] = 6
Defaults["party-power-reverse"] = false
Defaults["party-power-color"] = "POWER"
Defaults["party-power-smooth"] = true
Defaults["party-point"] = "LEFT"
Defaults["party-spacing"] = 2
Defaults["party-show-solo"] = false
Defaults["party-font"] = "Roboto"
Defaults["party-font-size"] = 12
Defaults["party-font-flags"] = ""
Defaults.PartyHealthTexture = "YxUI 4"
Defaults.PartyPowerTexture = "YxUI 4"
Defaults.PartyEnableMouseover = true

local UF = YxUI:GetModule("Unit Frames")

local PartyDebuffFilter = function(self, unit, aura)
	local hasCustom, alwaysShowMine, showForMySpec = SpellGetVisibilityInfo(aura.spellId, "RAID_INCOMBAT")

	return not hasCustom or showForMySpec or (alwaysShowMine and aura.isFromPlayerOrPlayerPet)
end

local function SetPartyDebuffLayout(debuffs, frame, point)
	local horizontal = point == "LEFT" or point == "RIGHT"
	debuffs:SetSize(24 * 3 + 4, horizontal and 24 or 50)
	debuffs.num = horizontal and 3 or 6
	debuffs.initialAnchor = horizontal and "BOTTOMLEFT" or "TOPLEFT"
	debuffs["growth-x"] = "RIGHT"
	if horizontal then
		debuffs["growth-y"] = nil
	else
		debuffs["growth-y"] = "DOWN"
	end
	debuffs:ClearAllPoints()
	debuffs:SetPoint(horizontal and "BOTTOMLEFT" or "TOPLEFT", frame, horizontal and "TOPLEFT" or "TOPRIGHT", horizontal and 0 or 2, horizontal and 2 or 0)
end

local function CreatePartyDebuffs(frame, health, filter)
	local debuffs = UF:CreateAuraContainer(frame, frame:GetName() .. "Debuffs", health, 24 * 3 + 4, 24, nil, nil, nil, nil, nil, 24, 1, 3,
		"BOTTOMLEFT", "ANCHOR_TOP", "RIGHT", nil, UF.PostCreateIcon, UF.PostUpdateIcon, filter, nil, nil)
	SetPartyDebuffLayout(debuffs, frame, Settings["party-point"])
	return debuffs
end

local PartyGroup = {
	prefix = "party", header = "party", petHeader = "party-pets",
	healthTextureKey = "PartyHealthTexture", powerTextureKey = "PartyPowerTexture", mouseoverKey = "PartyEnableMouseover",
	debuffFilter = PartyDebuffFilter, createDebuffs = CreatePartyDebuffs, dispelSize = 20, dispelAboveDebuffs = true,
	indicators = { auraWatch = Settings["party-show-aurawatch"], role = Settings["party-show-role"], leaderX = 0, phasePoint = "TOPRIGHT" }, testStart = -4,
	afterUpdate = function(operation)
		if operation == "width" or operation == "healthHeight" or operation == "powerHeight" then
			UF:UpdatePartyAnchorSize()
		end
	end,
}

YxUI.PartyPreviewDescriptor = PartyGroup

YxUI.StyleFuncs["party"] = function(frame, unit)
	UF:BuildGroupFrame(frame, unit, PartyGroup)
end

local function Update(operation, value)
	UF:UpdateGroupFrames(PartyGroup, operation, value)
end

local function UpdatePartyWidth(value)
	Update("width", value)
end

local function UpdatePartyHealthHeight(value)
	Update("healthHeight", value)
end

local function UpdatePartyHealthColor(value)
	Update("healthColor", value)
end

local function UpdatePartyHealthOrientation(value)
	Update("healthOrientation", value)
end

local function UpdatePartyHealthReverseFill(value)
	Update("healthReverse", value)
end

local function UpdateEnablePartyPower(value)
	Update("powerEnabled", value)
end

local function UpdatePartyPowerHeight(value)
	Update("powerHeight", value)
end

local function UpdatePartyPowerReverseFill(value)
	Update("powerReverse", value)
end

local function UpdatePartyPowerColor(value)
	Update("powerColor", value)
end

local function UpdatePartyHealthSmooth(value)
	Update("healthSmooth", value)
end

local function UpdatePartyPowerSmooth(value)
	Update("powerSmooth", value)
end

local function UpdatePartyAuraWatch(value)
	PartyGroup.indicators.auraWatch = value
	Update("auraWatch", value)
end

local function UpdatePartyRole(value)
	PartyGroup.indicators.role = value
	Update("role", value)
end

local function UpdatePartyShowDebuffs(value)
	Update("debuffs", value)
end

local function UpdatePartyShowHighlight(value)
	Update("highlight", value)
end

local function UpdateHealthTexture(value)
	Update("healthTexture", value)
end

local function UpdatePowerTexture(value)
	Update("powerTexture", value)
end

local function TestParty()
	UF:ToggleGroupTest(PartyGroup)
end

local function UpdateShowSolo(value)
	UF:RunAfterCombat("party:showSolo", function()
		UF:SetGroupHeaderShowSolo(YxUI.UnitFrames["party"], "party", value)
		UF:SetGroupHeaderShowSolo(YxUI.UnitFrames["party-pets"], "party", value)
	end)
end

local function SetSpacing(header, value, point)
	local x, y = 0, 0

	if point == "LEFT" then
		x = value
	elseif point == "RIGHT" then
		x = -value
	elseif point == "TOP" then
		y = -value
	else
		y = value
	end

	header:SetAttribute("xOffset", x)
	header:SetAttribute("yOffset", y)
end

local function UpdatePartyPoint(value)
	UF:RunAfterCombat("party:point", function()
		local x, y = UF:GetGrowthOffsets(value, Settings["party-spacing"])
		for _, key in ipairs({"party", "party-pets"}) do
			local header = YxUI.UnitFrames[key]
			if header then
				header:SetAttribute("point", value)
				header:SetAttribute("xOffset", x)
				header:SetAttribute("yOffset", y)
			end
		end

		UF:ForEachHeaderChild(YxUI.UnitFrames["party"], function(frame)
			if frame.Debuffs then
				SetPartyDebuffLayout(frame.Debuffs, frame, value)
				if frame.Debuffs.ForceUpdate then
					frame.Debuffs:ForceUpdate()
				end
			end
		end)
		UF:UpdatePartyAnchorSize()
		UF:LayoutGroupPreview(PartyGroup)
	end)
end

local function UpdatePartySpacing(value)
	UF:RunAfterCombat("party:spacing", function()
		local header = YxUI.UnitFrames["party"]
		if not header then
			return
		end

		local point = header:GetAttribute("point")
		SetSpacing(header, value, point)

		if YxUI.UnitFrames["party-pets"] then
			SetSpacing(YxUI.UnitFrames["party-pets"], value, point)
		end
		UF:UpdatePartyAnchorSize()
		UF:LayoutGroupPreview(PartyGroup)
	end)
end

YxUI:GetModule("GUI"):AddWidgetsID("General", "Party", "Unit Frames", function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("party-enable", Settings["party-enable"], Language["Enable Party Module"], Language["Enable the party frames module"], ReloadUI):RequiresReload(true)

	left:CreateHeader(Language["Party Size"])
	left:CreateSlider("party-width", Settings["party-width"], 40, 200, 1, Language["Width"], Language["Set the width of the party frames"], UpdatePartyWidth)

	left:CreateHeader(Language["Font"])
	left:CreateDropdown("party-font", Settings["party-font"], Assets:GetFontList(), Language["Font"], Language["Set the font of the party frames"], function() UF:UpdateGroupFonts("party") end, "Font")
	left:CreateSlider("party-font-size", Settings["party-font-size"], 8, 32, 1, Language["Font Size"], Language["Set the font size of the party frames"], function() UF:UpdateGroupFonts("party") end)
	left:CreateDropdown("party-font-flags", Settings["party-font-flags"], Assets:GetFlagsList(), Language["Font Flags"], Language["Set the font flags of the party frames"], function() UF:UpdateGroupFonts("party") end)

	right:CreateHeader(Language["Test Party Frames"])
	right:CreateButton("", Language["Test"], Language["Test Party"], Language["Test the party frames"], TestParty)

	right:CreateHeader(Language["Health"])
	right:CreateSlider("party-health-height", Settings["party-health-height"], 12, 60, 1, Language["Health Height"], Language["Set the height of party health bars"], UpdatePartyHealthHeight)
	right:CreateDropdown("party-health-color", Settings["party-health-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Custom"]] = "CUSTOM"}, Language["Health Bar Color"], Language["Set the color of the health bar"], UpdatePartyHealthColor)
	right:CreateDropdown("party-health-orientation", Settings["party-health-orientation"], {[Language["Horizontal"]] = "HORIZONTAL", [Language["Vertical"]] = "VERTICAL"}, Language["Fill Orientation"], Language["Set the direction of the party health bars"], UpdatePartyHealthOrientation)
	right:CreateSwitch("party-health-smooth", Settings["party-health-smooth"], Language["Smooth Health"], Language["Animate party health changes"], UpdatePartyHealthSmooth)
	right:CreateSwitch("party-health-reverse", Settings["party-health-reverse"], Language["Reverse Health Fill"], Language["Reverse the fill of the health bar"], UpdatePartyHealthReverseFill)
	right:CreateDropdown("PartyHealthTexture", Settings.PartyHealthTexture, Assets:GetTextureList(), Language["Health Texture"], "", UpdateHealthTexture, "Texture")

	right:CreateHeader(Language["Power"])
	right:CreateSwitch("party-power-enable", Settings["party-power-enable"], Language["Enable Power Bar"], Language["Enable the power bar"], UpdateEnablePartyPower)
	right:CreateSwitch("party-power-smooth", Settings["party-power-smooth"], Language["Smooth Power"], Language["Animate party power changes"], UpdatePartyPowerSmooth)
	right:CreateSwitch("party-power-reverse", Settings["party-power-reverse"], Language["Reverse Power Fill"], Language["Reverse the fill of the power bar"], UpdatePartyPowerReverseFill)
	right:CreateSlider("party-power-height", Settings["party-power-height"], 2, 30, 1, Language["Power Height"], Language["Set the height of party power bars"], UpdatePartyPowerHeight)
	right:CreateDropdown("party-power-color", Settings["party-power-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Power Type"]] = "POWER"}, Language["Power Bar Color"], Language["Set the color of the power bar"], UpdatePartyPowerColor)
	right:CreateDropdown("PartyPowerTexture", Settings.PartyPowerTexture, Assets:GetTextureList(), Language["Power Texture"], "", UpdatePowerTexture, "Texture")

	right:CreateHeader(Language["Text"])
	right:CreateTagInput("party-health-top", Settings["party-health-top"], Language["Top Text"], Language["Set the text on the top of the party frame"], function(value) Update("textTop", value) end)
	right:CreateTagInput("party-health-bottom", Settings["party-health-bottom"], Language["Bottom Text"], Language["Set the text on the bottom of the party frame"], function(value) Update("textBottom", value) end)

	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("party-show-debuffs", Settings["party-show-debuffs"], Language["Enable Debuffs"], Language["Display debuffs on party members"], UpdatePartyShowDebuffs)
	left:CreateSwitch("party-show-aurawatch", Settings["party-show-aurawatch"], Language["Class Buff Indicators"], Language["Show tracked class buffs on party frames"], UpdatePartyAuraWatch)
	left:CreateSwitch("party-show-role", Settings["party-show-role"], Language["Enable Role Icons"], Language["Display role icons on party members"], UpdatePartyRole)
	left:CreateSwitch("PartyEnableMouseover", Settings.PartyEnableMouseover, Language["Enable Mouseover"], Language["Enable a mouseover highlight on party members"], UpdatePartyShowHighlight)

	left:CreateHeader(Language["Range Opacity"])
	left:CreateSlider("party-in-range", Settings["party-in-range"], 0, 100, 5, Language["In Range"], Language["Set the opacity of party members within range of you"], function(value) UF:UpdateGroupRange("party", "insideAlpha", value) end)
	left:CreateSlider("party-out-of-range", Settings["party-out-of-range"], 0, 100, 5, Language["Out of Range"], Language["Set the opacity of party members out of your range"], function(value) UF:UpdateGroupRange("party", "outsideAlpha", value) end)

	left:CreateHeader(Language["Attributes"])
	left:CreateSwitch("party-show-solo", Settings["party-show-solo"], Language["Show Solo"], Language["Display the frames while not in a group"], UpdateShowSolo)
	left:CreateDropdown("party-point", Settings["party-point"], {[Language["Left"]] = "LEFT", [Language["Right"]] = "RIGHT", [Language["Top"]] = "TOP", [Language["Bottom"]] = "BOTTOM"}, Language["Anchor Point"], Language["Set the anchor point for the party frames"], UpdatePartyPoint)
	left:CreateSlider("party-spacing", Settings["party-spacing"], -10, 10, 1, Language["Set Spacing"], Language["Set the spacing of party units from each other"], UpdatePartySpacing)
end)
YxUI:GetModule("GUI"):RegisterPageSettingsID("General", "Party", {
	{"party-width", UpdatePartyWidth},
	{"party-font", function() UF:UpdateGroupFonts("party") end},
	{"party-font-size", function() UF:UpdateGroupFonts("party") end},
	{"party-font-flags", function() UF:UpdateGroupFonts("party") end},
	{"party-health-height", UpdatePartyHealthHeight},
	{"party-health-color", UpdatePartyHealthColor},
	{"party-health-orientation", UpdatePartyHealthOrientation},
	{"party-health-smooth", UpdatePartyHealthSmooth},
	{"party-health-reverse", UpdatePartyHealthReverseFill},
	{"PartyHealthTexture", UpdateHealthTexture},
	{"party-power-enable", UpdateEnablePartyPower},
	{"party-power-smooth", UpdatePartyPowerSmooth},
	{"party-power-reverse", UpdatePartyPowerReverseFill},
	{"party-power-height", UpdatePartyPowerHeight},
	{"party-power-color", UpdatePartyPowerColor},
	{"PartyPowerTexture", UpdatePowerTexture},
	{"party-health-top", function(value) Update("textTop", value) end},
	{"party-health-bottom", function(value) Update("textBottom", value) end},
	{"party-show-debuffs", UpdatePartyShowDebuffs},
	{"party-show-aurawatch", UpdatePartyAuraWatch},
	{"party-show-role", UpdatePartyRole},
	{"PartyEnableMouseover", UpdatePartyShowHighlight},
	{"party-in-range", function(value) UF:UpdateGroupRange("party", "insideAlpha", value) end},
	{"party-out-of-range", function(value) UF:UpdateGroupRange("party", "outsideAlpha", value) end},
	{"party-show-solo", UpdateShowSolo},
	{"party-point", UpdatePartyPoint},
	{"party-spacing", UpdatePartySpacing},
}, "Unit Frames")

YxUI:GetModule("GUI"):RegisterReloadSettings({"party-enable"})
