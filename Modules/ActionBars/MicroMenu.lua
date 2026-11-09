local YxUI, Language, Assets, Settings, Defaults = select(2, ...):get()

local MicroButtons = YxUI:NewModule("Micro Buttons")

if YxUI.IsForever then
	MicroButtons.Buttons = {}

	if MicroMenu then
		for _, Button in ipairs({MicroMenu:GetChildren()}) do
			if Button.layoutIndex then
				MicroButtons.Buttons[#MicroButtons.Buttons + 1] = Button
			end
		end

		table.sort(MicroButtons.Buttons, function(a, b)
			return a.layoutIndex < b.layoutIndex
		end)
	end

	if #MicroButtons.Buttons == 0 then
		for _, Name in ipairs({
			"CharacterMicroButton", "ProfessionMicroButton", "PlayerSpellsMicroButton",
			"SpellbookMicroButton", "TalentMicroButton", "LegacyMicroButton",
			"AchievementMicroButton", "QuestLogMicroButton", "HousingMicroButton",
			"GuildMicroButton", "LFDMicroButton", "CollectionsMicroButton",
			"EJMicroButton", "HelpMicroButton", "StoreMicroButton", "MainMenuMicroButton",
		}) do
			if _G[Name] then
				MicroButtons.Buttons[#MicroButtons.Buttons + 1] = _G[Name]
			end
		end
	end
elseif YxUI.IsMainline then
	MicroButtons.Buttons = {
		CharacterMicroButton,
		ProfessionMicroButton,
		PlayerSpellsMicroButton,
		AchievementMicroButton,
		QuestLogMicroButton,
		GuildMicroButton,
		LFDMicroButton,
		CollectionsMicroButton,
		HousingMicroButton,
		EJMicroButton,
		StoreMicroButton,
		MainMenuMicroButton,
	}
elseif YxUI.IsTBC then
	MicroButtons.Buttons = {
		CharacterMicroButton,
		SpellbookMicroButton,
		TalentMicroButton,
		AchievementMicroButton,
		QuestLogMicroButton,
		SocialsMicroButton,
		LFGMicroButton,
		WorldMapMicroButton,
		MainMenuMicroButton,
		HelpMicroButton,
	}
elseif YxUI.IsWrath then
	MicroButtons.Buttons = {
		CharacterMicroButton,
		SpellbookMicroButton,
		TalentMicroButton,
		AchievementMicroButton,
		QuestLogMicroButton,
		SocialsMicroButton,
		CollectionsMicroButton,
		PVPMicroButton,
		LFGMicroButton,
		MainMenuMicroButton,
		HelpMicroButton,
	}
elseif YxUI.IsCata then
	MicroButtons.Buttons = {
		CharacterMicroButton,
		SpellbookMicroButton,
		TalentMicroButton,
		AchievementMicroButton,
		QuestLogMicroButton,
		GuildMicroButton,
		CollectionsMicroButton,
		PVPMicroButton,
		LFGMicroButton,
		EJMicroButton,
		MainMenuMicroButton,
		HelpMicroButton,
	}
elseif YxUI.IsMists then
	MicroButtons.Buttons = {
		CharacterMicroButton,
		SpellbookMicroButton,
		TalentMicroButton,
		AchievementMicroButton,
		QuestLogMicroButton,
		GuildMicroButton,
		PVPMicroButton,
		LFGMicroButton,
		CollectionsMicroButton,
		EJMicroButton,
		StoreMicroButton,
		MainMenuMicroButton,
	}
else
	MicroButtons.Buttons = {
		CharacterMicroButton,
		SpellbookMicroButton,
		TalentMicroButton,
		QuestLogMicroButton,
		GuildMicroButton,
		WorldMapMicroButton,
		MainMenuMicroButton,
		HelpMicroButton,
	}
end

-- Default settings values
Defaults["micro-buttons-visibility"] = "SHOW"
Defaults["micro-buttons-opacity"] = 40
Defaults["micro-buttons-max"] = 100
Defaults["micro-buttons-per-row"] = #MicroButtons.Buttons
Defaults["micro-buttons-gap"] = 2

local ButtonOnEnter = function(self)
	if YxUI.IsForever then
		local Normal = self:GetNormalTexture()
		if Normal then
			Normal:SetAlpha(1)
		end
	end

	if Settings["micro-buttons-visibility"] == "MOUSEOVER" then
		self:GetParent():SetAlpha(Settings["micro-buttons-max"] / 100)
	end
end

local PanelOnEnter = function(self)
	MicroButtons.Panel:SetAlpha(Settings["micro-buttons-max"] / 100)
end

local ButtonOnLeave = function(self)
	if Settings["micro-buttons-visibility"] == "MOUSEOVER" then
		self:GetParent():SetAlpha(Settings["micro-buttons-opacity"] / 100)
	end
end

local PanelOnLeave = function(self)
	MicroButtons.Panel:SetAlpha(Settings["micro-buttons-opacity"] / 100)
end

function MicroButtons:UpdateVisibility()
	if Settings["micro-buttons-visibility"] == "HIDE" then
		self.Panel:SetScript("OnEnter", nil)
		self.Panel:SetScript("OnLeave", nil)
		self.Panel:SetAlpha(0)

		if MicroMenu then
			-- Clients that use Blizzard's shared MicroMenu layout can temporarily
			-- reparent these buttons while updating Edit Mode. Hiding our panel
			-- makes their coordinates nil during that update, so GetEdgeButton
			-- attempts to compare nil values. Keep the panel shown but transparent
			-- and disable the invisible buttons' mouse input instead.
			self.Panel:Show()

			for i = 1, #self.Buttons do
				self.Buttons[i]:EnableMouse(false)
			end
		else
			self.Panel:Hide()
		end
	elseif Settings["micro-buttons-visibility"] == "MOUSEOVER" then
		for i = 1, #self.Buttons do
			self.Buttons[i]:EnableMouse(true)
		end

		self.Panel:SetScript("OnEnter", PanelOnEnter)
		self.Panel:SetScript("OnLeave", PanelOnLeave)
		self.Panel:SetAlpha(Settings["micro-buttons-opacity"] / 100)
		self.Panel:Show()
	elseif Settings["micro-buttons-visibility"] == "SHOW" then
		for i = 1, #self.Buttons do
			self.Buttons[i]:EnableMouse(true)
		end

		self.Panel:SetScript("OnEnter", nil)
		self.Panel:SetScript("OnLeave", nil)
		self.Panel:SetAlpha(Settings["micro-buttons-max"] / 100)
		self.Panel:Show()
	end
end

function MicroButtons:UpdateMicroButtonsParent()
	if MicroMenu then
		-- The shared MicroMenu layout finds its edge buttons by enumerating its
		-- children. Keep the buttons owned by MicroMenu so Edit Mode can never
		-- run its layout while they are parented elsewhere. Blizzard supports
		-- moving the MicroMenu itself for override layouts.
		MicroMenu:SetParent(MicroButtons.Panel)
		MicroMenu:ClearAllPoints()
		MicroMenu:SetAllPoints(MicroButtons.Panel)
	else
		for i = 1, #MicroButtons.Buttons do
			MicroButtons.Buttons[i]:SetParent(MicroButtons.Panel)
		end
	end
end

function MicroButtons:PositionButtons()
	local VisibleButtons = {}

	for i = 1, #MicroButtons.Buttons do
		local Button = MicroButtons.Buttons[i]

		if Button:IsShown() then
			VisibleButtons[#VisibleButtons + 1] = Button
		end
	end

	local NumButtons = #VisibleButtons
	local PerRow = Settings["micro-buttons-per-row"]
	local Spacing = Settings["micro-buttons-gap"]
	local Width, Height = MicroButtons.Buttons[1]:GetSize()
	local HorizontalGap = Spacing - 2

	if NumButtons == 0 then
		MicroButtons.Panel:SetSize(1, 1)
		return
	end

	if NumButtons < PerRow then
		PerRow = NumButtons
	end

	local Columns = ceil(NumButtons / PerRow)

	-- Bar sizing
	if YxUI.IsForever then
		MicroButtons.Panel:SetWidth((Width * PerRow) + (Spacing * 2) + (HorizontalGap * (PerRow - 1)))
	else
		MicroButtons.Panel:SetWidth((((Width - 1.8) + Spacing) * PerRow) + Spacing)
	end

	MicroButtons.Panel:SetHeight((Height * Columns) + (Spacing * (Columns + 1)))

	-- Actual moving
	for i = 1, NumButtons do
		local Button = VisibleButtons[i]

		-- Clear and replace each anchor as one operation. Clearing every button
		-- first leaves visible retail buttons without coordinates while Blizzard's
		-- MicroMenu layout callbacks run, causing GetEdgeButton to compare nils.
		Button:ClearAllPoints()

		if i == 1 then
			Button:SetPoint("TOPLEFT", MicroButtons.Panel, Spacing, -Spacing)
		elseif (i - 1) % PerRow == 0 then
			Button:SetPoint("TOP", VisibleButtons[i - PerRow], "BOTTOM", 0, -Spacing)
		else
			Button:SetPoint("LEFT", VisibleButtons[i - 1], "RIGHT", HorizontalGap, 0)
		end
	end
end

local AddForeverMicroOutline = function(button)
	if button.HydraMicroOutline then
		return
	end

	local Border = {}
	local function AddEdge(point, oppositePoint, width, height)
		local Edge = button:CreateTexture(nil, "OVERLAY")
		Edge:SetDrawLayer("OVERLAY", 7)
		Edge:SetColorTexture(0, 0, 0)
		Edge:SetPoint(point, button.BG, point)
		Edge:SetPoint(oppositePoint, button.BG, oppositePoint)
		if width then
			Edge:SetWidth(width)
		else
			Edge:SetHeight(height)
		end
		Border[#Border + 1] = Edge
	end

	AddEdge("TOPLEFT", "TOPRIGHT", nil, 1)
	AddEdge("BOTTOMLEFT", "BOTTOMRIGHT", nil, 1)
	AddEdge("TOPLEFT", "BOTTOMLEFT", 1)
	AddEdge("TOPRIGHT", "BOTTOMRIGHT", 1)
	button.HydraMicroOutline = Border
end

local StyleForeverMicroButton = function(button)
	for _, Name in ipairs({"Background", "PushedBackground", "PushedShadow", "FlashContent", "FlashBorder"}) do
		local Texture = button[Name]
		if Texture then
			Texture:SetTexture(nil)
		end
	end

	if button.NotificationOverlay then
		button.NotificationOverlay:SetAlpha(0)
	end

	local Highlight = button:GetHighlightTexture()
	if Highlight then
		Highlight:SetColorTexture(1, 1, 1, 0.25)
		Highlight:SetVertexColor(1, 1, 1, 1)
		Highlight:SetBlendMode("BLEND")
		Highlight:SetAlpha(1)
	end
end

function MicroButtons:Load()
	if not Settings["ab-enable"] then
		return
	end

	self.Panel = CreateFrame("Frame", "YxUI Micro Buttons", YxUI.UIParent, "BackdropTemplate")
	self.Panel:SetBackdrop(YxUI.BackdropAndBorder)
	self.Panel:SetBackdropColor(YxUI:HexToRGB(Settings["ui-window-bg-color"]))
	self.Panel:SetBackdropBorderColor(0, 0, 0)
	self.Panel:SetFrameStrata("LOW")

	if YxUI.IsMainline then
		self.Panel:SetSize(312, 40)
	else
		self.Panel:SetSize(228, 40)
	end

	if Settings["right-window-enable"] then
		self.Panel:SetPoint("BOTTOMRIGHT", YxUI:GetModule("Right Window"), "TOPRIGHT", 0, 3)
	else
		self.Panel:SetPoint("BOTTOMRIGHT", YxUI.UIParent, -10, 10)
	end

	YxUI:CreateMover(self.Panel)
	self:UpdateMicroButtonsParent()

	if YxUI.IsForever and MicroMenu then
		if MicroMenu.BorderArt then
			MicroMenu.BorderArt:SetTexture(nil)
			MicroMenu.BorderArt:Hide()
		end

		if MicroMenu.BackgroundArt then
			MicroMenu.BackgroundArt:SetTexture(nil)
			MicroMenu.BackgroundArt:Hide()
		end
	end

	for i = 1, #self.Buttons do
		self.Buttons[i]:SetHitRectInsets(0, 0, 0, 0)

		if not YxUI.IsMainline or YxUI.IsForever then
			self.Buttons[i]:SetSize(28, 36)
		end

		self.Buttons[i]:HookScript("OnEnter", ButtonOnEnter)
		self.Buttons[i]:HookScript("OnLeave", ButtonOnLeave)
		self.Buttons[i]:HookScript("OnShow", self.PositionButtons)
		self.Buttons[i]:HookScript("OnHide", self.PositionButtons)

		self.Buttons[i].BG = self.Buttons[i]:CreateTexture(nil, "BACKGROUND")
		self.Buttons[i].BG:SetPoint("TOPLEFT", self.Buttons[i], 1, -1)
		self.Buttons[i].BG:SetPoint("BOTTOMRIGHT", self.Buttons[i], -1, 1)
		self.Buttons[i].BG:SetTexture(Assets:GetTexture("Blank"))
		self.Buttons[i].BG:SetVertexColor(0, 0, 0)

		if self.Buttons[i].FlashContent then
			self.Buttons[i].FlashContent:ClearAllPoints()
			self.Buttons[i].FlashContent:SetAllPoints(self.Buttons[i])

			self.Buttons[i].FlashBorder:ClearAllPoints()
			self.Buttons[i].FlashBorder:SetPoint("TOPLEFT", self.Buttons[i], -3, 3)
			self.Buttons[i].FlashBorder:SetPoint("BOTTOMRIGHT", self.Buttons[i], 3, -3)
		end

		local Normal = self.Buttons[i]:GetNormalTexture()
		local Pushed = self.Buttons[i]:GetPushedTexture()
		local Disabled = self.Buttons[i]:GetDisabledTexture()
		local Highlight = self.Buttons[i]:GetHighlightTexture()

		if Normal then
			Normal:ClearAllPoints()
			Normal:SetPoint("TOPLEFT", self.Buttons[i], 2, -2)
			Normal:SetPoint("BOTTOMRIGHT", self.Buttons[i], -2, 2)
		end

		if Pushed then
			Pushed:ClearAllPoints()
			Pushed:SetPoint("TOPLEFT", self.Buttons[i], 2, -2)
			Pushed:SetPoint("BOTTOMRIGHT", self.Buttons[i], -2, 2)
		end

		if Disabled then
			Disabled:ClearAllPoints()
			Disabled:SetPoint("TOPLEFT", self.Buttons[i], 2, -2)
			Disabled:SetPoint("BOTTOMRIGHT", self.Buttons[i], -2, 2)
		end

		if not YxUI.IsMainline then
			if Normal then
				Normal:SetTexCoord(0.2, 0.85, 0.5, 0.9)
			end

			if Pushed then
				Pushed:SetTexCoord(0.2, 0.85, 0.5, 0.9)
			end

			if Disabled then
				Disabled:SetTexCoord(0.2, 0.85, 0.5, 0.9)
			end
		end

		if Highlight then
			Highlight:ClearAllPoints()
			Highlight:SetPoint("TOPLEFT", self.Buttons[i], 2, -2)
			Highlight:SetPoint("BOTTOMRIGHT", self.Buttons[i], -2, 2)
			Highlight:SetTexture(Assets:GetTexture("Blank"))
			Highlight:SetVertexColor(1, 1, 1, 0.2)
		end

		if YxUI.IsForever then
			local Button = self.Buttons[i]
			AddForeverMicroOutline(Button)
			StyleForeverMicroButton(Button)

			if Button.SetNormal then
				hooksecurefunc(Button, "SetNormal", StyleForeverMicroButton)
			end

			if Button.SetPushed then
				hooksecurefunc(Button, "SetPushed", StyleForeverMicroButton)
			end
		end
	end

	if MicroButtonPortrait then
		MicroButtonPortrait:ClearAllPoints()
		MicroButtonPortrait:SetPoint("TOPLEFT", CharacterMicroButton, 2, -2)
		MicroButtonPortrait:SetPoint("BOTTOMRIGHT", CharacterMicroButton, -2, 2)
	end

	if YxUI.IsWrath or YxUI.IsCata or YxUI.IsMists then
		PVPMicroButtonTexture:ClearAllPoints()
		PVPMicroButtonTexture:SetPoint("TOP", PVPMicroButton, 6, -6)
	end

	if MainMenuBarPerformanceBar then
		MainMenuBarPerformanceBar:Hide()
	end

	if UpdateMicroButtonsParent then
		hooksecurefunc("UpdateMicroButtonsParent", self.UpdateMicroButtonsParent)
	end

	if MoveMicroButtons then
		hooksecurefunc("MoveMicroButtons", self.PositionButtons)
	end

	self:UpdateVisibility()
	self:PositionButtons()
end

local UpdateMicroVisibility = function(value)
	MicroButtons:UpdateVisibility()
end

local UpdateMicroPositions = function()
	MicroButtons:PositionButtons()
end

local function UpdateVisibilityDependencies()
	YxUI:GetModule("GUI").WidgetCore.UpdateDependencies({
		["micro-buttons-opacity"] = Settings["micro-buttons-visibility"] == "MOUSEOVER",
		["micro-buttons-max"] = Settings["micro-buttons-visibility"] == "MOUSEOVER",
	})
end

YxUI:GetModule("GUI"):AddWidgetsID("General", "Action Bars", function(left, right)
	right:CreateHeader(Language["Micro Menu Buttons"])
	right:CreateDropdown("micro-buttons-visibility", Settings["micro-buttons-visibility"], {[Language["Hide"]] = "HIDE", [Language["Mouseover"]] = "MOUSEOVER", [Language["Show"]] = "SHOW"}, Language["Set Visibility"], Language["Set the visibility of the micro menu buttons"], function(value) UpdateMicroVisibility(value); UpdateVisibilityDependencies() end)
	right:CreateSlider("micro-buttons-opacity", Settings["micro-buttons-opacity"], 0, 100, 10, Language["Set Faded Opacity"], Language["Set the opacity of the micro menu buttons when visibility is set to Mouseover"], UpdateMicroVisibility, nil, "%")
	right:CreateSlider("micro-buttons-max", Settings["micro-buttons-max"], 0, 100, 10, Language["Set Max Opacity"], Language["Set the max opacity of the micro menu buttons when visibility is set to Mouseover"], UpdateMicroVisibility, nil, "%")
	right:CreateSlider("micro-buttons-per-row", Settings["micro-buttons-per-row"], 1, #MicroButtons.Buttons, 1, Language["Buttons Per Row"], Language["Set the number of buttons per row"], UpdateMicroPositions)
	right:CreateSlider("micro-buttons-gap", Settings["micro-buttons-gap"], -1, 10, 1, Language["Button Spacing"], Language["Set the spacing between micro buttons"], UpdateMicroPositions)
	UpdateVisibilityDependencies()
end)
YxUI:GetModule("GUI"):RegisterPageSettingsID("General", "Action Bars", {
	{"micro-buttons-visibility", function(value) UpdateMicroVisibility(value); UpdateVisibilityDependencies() end},
	{"micro-buttons-opacity", UpdateMicroVisibility},
	{"micro-buttons-max", UpdateMicroVisibility},
	{"micro-buttons-per-row", UpdateMicroPositions},
	{"micro-buttons-gap", UpdateMicroPositions},
}, nil)

