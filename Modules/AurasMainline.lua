local YxUI, Language, Assets, Settings, Defaults = select(2, ...):get()

if not YxUI.IsMainline then
	return
end

local Auras = YxUI:NewModule("Auras")

Defaults["auras-enable"] = true
Defaults["auras-show"] = true
Defaults["auras-size"] = 30
Defaults["auras-spacing"] = 2
Defaults["auras-row-spacing"] = 16
Defaults["auras-per-row"] = 12
Defaults["auras-font"] = "Roboto"
Defaults["auras-font-size"] = 12
Defaults["auras-font-flags"] = ""
Defaults["auras-count-color"] = "FFFFFF"
Defaults["auras-count-xoffset"] = 10
Defaults["auras-count-yoffset"] = -8
Defaults["auras-count-align"] = "RIGHT"
Defaults["auras-duration-color"] = "FFFFFF"
Defaults["auras-duration-xoffset"] = 0
Defaults["auras-duration-yoffset"] = -24
Defaults["auras-duration-align"] = "CENTER"

Auras.Headers = {}
Auras.Buttons = setmetatable({}, {__mode = "k"})

local function SetTextStyle(button)
	YxUI:SetFontInfo(button.Count, Settings["auras-font"], Settings["auras-font-size"], Settings["auras-font-flags"])
	button.Count:SetTextColor(YxUI:HexToRGB(Settings["auras-count-color"]))
	button.Count:SetJustifyH(Settings["auras-count-align"])
	button.Count:ClearAllPoints()
	button.Count:SetPoint("CENTER", button, Settings["auras-count-xoffset"], Settings["auras-count-yoffset"])

	YxUI:SetFontInfo(button.Duration, Settings["auras-font"], Settings["auras-font-size"], Settings["auras-font-flags"])
	button.Duration:SetTextColor(YxUI:HexToRGB(Settings["auras-duration-color"]))
	button.Duration:SetJustifyH(Settings["auras-duration-align"])
	button.Duration:ClearAllPoints()
	button.Duration:SetPoint("CENTER", button, Settings["auras-duration-xoffset"], Settings["auras-duration-yoffset"])
end

local function InitializeAuraButton(button)
	local size = Settings["auras-size"]
	button:SetSize(size, size)
	button:SetTooltipAnchorPoint("ANCHOR_BOTTOMLEFT", 0, 0)

	local backdrop = CreateFrame("Frame", nil, button, "BackdropTemplate")
	backdrop:SetAllPoints(button)
	backdrop:SetFrameLevel(button:GetFrameLevel() - 1)
	backdrop:SetBackdrop(YxUI.BackdropAndBorder)
	backdrop:SetBackdropColor(0, 0, 0, 0)
	backdrop:SetBackdropBorderColor(0, 0, 0)

	local icon = button:CreateTexture(nil, "BORDER")
	icon:SetPoint("TOPLEFT", button, 1, -1)
	icon:SetPoint("BOTTOMRIGHT", button, -1, 1)
	icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	button:SetIcon(icon)

	local count = button:CreateFontString(nil, "OVERLAY")
	local duration = button:CreateFontString(nil, "OVERLAY")
	button.Count = count
	button.Duration = duration
	SetTextStyle(button)
	button:SetApplicationCount(count, {})
	button:SetDurationText(duration, {})
	button:SetCancelAuraButtons("RightButtonUp")

	if button.AddDispelTypeTexture and Enum and Enum.CustomAuraButtonDispelTypeTextureStyle then
		local border = button:CreateTexture(nil, "OVERLAY")
		border:SetAllPoints(button)
		button:AddDispelTypeTexture(border, {
			style = Enum.CustomAuraButtonDispelTypeTextureStyle.Border,
			showWhenHarmful = true,
		})
	end

	Auras.Buttons[button] = true
end

local function GetLayout()
	return {
		elementSpacing = Settings["auras-spacing"],
		lineSpacing = Settings["auras-row-spacing"],
	}
end

local function ApplyContainerLayout(container, key)
	container:SetFlowLayoutMaximumLineSize(Settings["auras-per-row"] * (Settings["auras-size"] + Settings["auras-spacing"]))
	container:SetAuraGroupLayout(key, GetLayout())
end

local function ApplyLayout()
	if not Auras.Headers[1] then
		return
	end

	for index = 1, 2 do
		local container = Auras.Headers[index]
		ApplyContainerLayout(container, index == 1 and "buffs" or "debuffs")
	end

	local width = Settings["auras-per-row"] * (Settings["auras-size"] + Settings["auras-spacing"])
	Auras.Buffs:SetSize(width, 3 * Settings["auras-size"] + 2 * Settings["auras-row-spacing"])
	Auras.Debuffs:SetSize(width, 2 * Settings["auras-size"] + Settings["auras-row-spacing"])
end

local function ApplyRowCount()
	if not Auras.Headers[1] then
		return
	end

	for index = 1, 2 do
		local key = index == 1 and "buffs" or "debuffs"
		Auras.Headers[index]:SetAuraGroupMaxFrameCount(key, Settings["auras-per-row"] * (index == 1 and 3 or 2))
	end

	ApplyLayout()
end

local function UpdateAuraSize()
	if not Auras.Headers[1] then return end
	if InCombatLockdown() then
		Auras.PendingSizeUpdate = true
		Auras:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end
	Auras.PendingSizeUpdate = nil
	Auras:UnregisterEvent("PLAYER_REGEN_ENABLED")
	local size = Settings["auras-size"]
	for button in pairs(Auras.Buttons) do
		if not button.IsForbidden or not button:IsForbidden() then
			button:SetSize(size, size)
		end
	end
	ApplyRowCount()
end

local function UpdateRowCount()
	if InCombatLockdown() then
		Auras:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end

	Auras:UnregisterEvent("PLAYER_REGEN_ENABLED")
	ApplyRowCount()
end

Auras:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_REGEN_ENABLED" then
		if Auras.PendingSizeUpdate then UpdateAuraSize() else UpdateRowCount() end
	end
end)

local function UpdateDisplay()
	if not Auras.Headers[1] then
		return
	end

	for i = 1, 2 do
		Auras.Headers[i]:SetEnabled(Settings["auras-show"])
		Auras.Headers[i]:SetShown(Settings["auras-show"])
	end
end

local function UpdateButtonStyle()
	for button in pairs(Auras.Buttons) do
		if not button.IsForbidden or not button:IsForbidden() then
			SetTextStyle(button)
		end
	end
end

function Auras:Load()
	if not Settings["auras-enable"] then
		return
	end

	if C_AddOns and C_AddOns.LoadAddOn then
		C_AddOns.LoadAddOn("Blizzard_AuraContainer")
	end

	if not (C_XMLUtil and C_XMLUtil.GetTemplateInfo and C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate")) then
		return
	end

	local width = Settings["auras-per-row"] * (Settings["auras-size"] + Settings["auras-spacing"])
	self.Buffs = CreateFrame("Frame", "YxUI Buffs", YxUI.UIParent)
	self.Buffs:SetSize(width, 3 * Settings["auras-size"] + 2 * Settings["auras-row-spacing"])
	self.Buffs:SetPoint("TOPRIGHT", YxUI.UIParent, "TOPRIGHT", -(Settings["minimap-size"] + 22), -12)

	self.Debuffs = CreateFrame("Frame", "YxUI Debuffs", YxUI.UIParent)
	self.Debuffs:SetSize(width, 2 * Settings["auras-size"] + Settings["auras-row-spacing"])
	self.Debuffs:SetPoint("TOPRIGHT", self.Buffs, "BOTTOMRIGHT", 0, -2)

	for index = 1, 2 do
		local container = CreateFrame("AuraContainer", nil, YxUI.UIParent, "CustomAuraContainerTemplate")
		container:SetSize(1, 1)
		container:SetPoint("TOPRIGHT", index == 1 and self.Buffs or self.Debuffs, "TOPRIGHT")
		container:SetFlowLayoutAnchorPoint("TOPRIGHT")
		container:SetFlowLayoutGrowthDirection(-1, -1)
		container:SetFlowLayoutMaximumLineSize(width)
		local key = index == 1 and "buffs" or "debuffs"
		container:AddAuraGroup(key, index == 1 and "HELPFUL" or "HARMFUL", {
			maxFrameCount = Settings["auras-per-row"] * (index == 1 and 3 or 2),
			initializeFrame = InitializeAuraButton,
			layout = GetLayout(),
		})
		container:SetUnit("player")
		self.Headers[index] = container
	end

	YxUI:CreateMover(self.Buffs)
	YxUI:CreateMover(self.Debuffs)

	if BuffFrame then
		BuffFrame:Hide()
		BuffFrame:UnregisterAllEvents()
	end
	if DebuffFrame then
		DebuffFrame:Hide()
		DebuffFrame:UnregisterAllEvents()
	end

	UpdateDisplay()
end

YxUI:GetModule("GUI"):AddWidgetsID("General", "Auras", function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("auras-enable", Settings["auras-enable"], Language["Enable Auras Module"], Language["Enable the YxUI auras module"], ReloadUI):RequiresReload(true)
	left:CreateHeader(Language["Display"])
	left:CreateSwitch("auras-show", Settings["auras-show"], Language["Display Auras"], Language["Display the player's buffs and debuffs"], UpdateDisplay)
	left:CreateHeader(Language["Styling"])
	left:CreateSlider("auras-size", Settings["auras-size"], 20, 50, 2, Language["Size"], Language["Set the size of auras"], UpdateAuraSize)
	left:CreateSlider("auras-spacing", Settings["auras-spacing"], 0, 10, 1, Language["Spacing"], Language["Set the spacing between auras"], ApplyLayout)
	left:CreateSlider("auras-row-spacing", Settings["auras-row-spacing"], 0, 30, 1, Language["Row Spacing"], Language["Set the vertical spacing between aura rows"], ApplyLayout)
	left:CreateSlider("auras-per-row", Settings["auras-per-row"], 8, 16, 1, Language["Auras Per Row"], Language["Set the number of auras per row"], UpdateRowCount)
	left:CreateHeader(Language["Font"])
	left:CreateDropdown("auras-font", Settings["auras-font"], Assets:GetFontList(), Language["Font"], Language["Set the font of the auras"], UpdateButtonStyle, "Font")
	left:CreateSlider("auras-font-size", Settings["auras-font-size"], 8, 32, 1, Language["Font Size"], Language["Set the font size of the auras"], UpdateButtonStyle)
	left:CreateDropdown("auras-font-flags", Settings["auras-font-flags"], Assets:GetFlagsList(), Language["Font Flags"], Language["Set the font flags of the auras"], UpdateButtonStyle)

	right:CreateHeader(Language["Duration Text"])
	right:CreateSlider("auras-duration-xoffset", Settings["auras-duration-xoffset"], -30, 30, 1, Language["X Offset"], Language["Set the x-axis offset of the duration text"], UpdateButtonStyle)
	right:CreateSlider("auras-duration-yoffset", Settings["auras-duration-yoffset"], -30, 30, 1, Language["Y Offset"], Language["Set the y-axis offset of the duration text"], UpdateButtonStyle)
	right:CreateDropdown("auras-duration-align", Settings["auras-duration-align"], {[Language["Left"]] = "LEFT", [Language["Right"]] = "RIGHT", [Language["Center"]] = "CENTER"}, Language["Text Alignment"], Language["Set the alignment direction of the text"], UpdateButtonStyle)
	right:CreateColorSelection("auras-duration-color", Settings["auras-duration-color"], Language["Color"], Language["Set the color of the aura duration"], UpdateButtonStyle)
	right:CreateHeader(Language["Count Text"])
	right:CreateSlider("auras-count-xoffset", Settings["auras-count-xoffset"], -30, 30, 1, Language["X Offset"], Language["Set the x-axis offset of the count text"], UpdateButtonStyle)
	right:CreateSlider("auras-count-yoffset", Settings["auras-count-yoffset"], -30, 30, 1, Language["Y Offset"], Language["Set the y-axis offset of the count text"], UpdateButtonStyle)
	right:CreateDropdown("auras-count-align", Settings["auras-count-align"], {[Language["Left"]] = "LEFT", [Language["Right"]] = "RIGHT", [Language["Center"]] = "CENTER"}, Language["Text Alignment"], Language["Set the alignment direction of the text"], UpdateButtonStyle)
	right:CreateColorSelection("auras-count-color", Settings["auras-count-color"], Language["Color"], Language["Set the color of the aura count"], UpdateButtonStyle)
end)
YxUI:GetModule("GUI"):RegisterPageSettingsID("General", "Auras", {
	{"auras-show", UpdateDisplay},
	{"auras-size", UpdateAuraSize},
	{"auras-spacing", ApplyLayout},
	{"auras-row-spacing", ApplyLayout},
	{"auras-per-row", UpdateRowCount},
	{"auras-font", UpdateButtonStyle},
	{"auras-font-size", UpdateButtonStyle},
	{"auras-font-flags", UpdateButtonStyle},
	{"auras-duration-xoffset", UpdateButtonStyle},
	{"auras-duration-yoffset", UpdateButtonStyle},
	{"auras-duration-align", UpdateButtonStyle},
	{"auras-duration-color", UpdateButtonStyle},
	{"auras-count-xoffset", UpdateButtonStyle},
	{"auras-count-yoffset", UpdateButtonStyle},
	{"auras-count-align", UpdateButtonStyle},
	{"auras-count-color", UpdateButtonStyle},
}, nil)


YxUI:GetModule("GUI"):RegisterReloadSettings({"auras-enable"})
