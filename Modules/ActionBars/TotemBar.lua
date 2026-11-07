local YxUI, Language, Assets, Settings, Defaults = select(2, ...):get()

local AB = YxUI:GetModule("Action Bars")
local GUI = YxUI:GetModule("GUI")

function AB:UpdateFlyout()
	if not self.FlyoutArrow then
		return
	end

	if SpellFlyout and SpellFlyout:IsShown() then
		SpellFlyout.BgEnd:SetTexture()
		SpellFlyout.HorizBg:SetTexture()
		SpellFlyout.VertBg:SetTexture()
	end

	if self.FlyoutBorder then
		self.FlyoutBorder:SetTexture()
		self.FlyoutBorderShadow:SetTexture()
	end

	for i = 1, 8 do
		local Button = _G["SpellFlyoutButton" .. i]

		if Button then
			AB:StylePetActionButton(Button)

			if Button.GlyphIcon then
				Button.GlyphIcon:ClearAllPoints()
				Button.GlyphIcon:SetPoint("TOPRIGHT", Button, 2, 2)
			end
		end
	end
end

function AB:ShowActionBars()
	-- SetActionBarToggles is a legacy wrapper which only knew about the
	-- original four multi-bars. Set the current CVars directly so bars added
	-- through Edit Mode are enabled as well.
	for i = 1, 7 do
		C_CVar.SetCVar("showMultiActionBar" .. i, "1")
	end

	self:EnableAlwaysShowButtons()
end

local function EnableAlwaysShowButtons()
	if InCombatLockdown() then
		return false
	end

	-- Older clients use the CVar; current clients store this per Edit Mode bar.
	if not (C_EditMode and C_EditMode.GetLayouts) then
		if C_CVar.GetCVar("alwaysShowActionBars") ~= nil then
			C_CVar.SetCVar("alwaysShowActionBars", "1")
			return true
		end
		return false
	end

	if not (EditModePresetLayoutManager and Enum.EditModeActionBarSetting
		and Enum.EditModeActionBarSetting.AlwaysShowButtons) then
		return false
	end

	-- Only edit fresh copies, never the tables owned by Blizzard's secure frames.
	local Info = C_EditMode.GetLayouts()
	local Layouts = EditModePresetLayoutManager:GetCopyOfPresetLayouts()
	local PresetCount = #Layouts

	for _, Layout in ipairs(Info.layouts) do
		table.insert(Layouts, Layout)
	end

	local Layout = Layouts[Info.activeLayout]
	if not Layout then
		return false
	end

	local Changed = false
	for _, System in ipairs(Layout.systems) do
		if System.system == Enum.EditModeSystem.ActionBar then
			for _, Setting in ipairs(System.settings) do
				if Setting.setting == Enum.EditModeActionBarSetting.AlwaysShowButtons and Setting.value ~= 1 then
					Setting.value = 1
					Changed = true
				end
			end
		end
	end

	if not Changed then
		return true
	end

	local AddedLayout
	if Info.activeLayout <= PresetCount then
		-- Presets are read-only. Save a character copy rather than changing them.
		local CharacterCount = 0
		for _, SavedLayout in ipairs(Info.layouts) do
			if SavedLayout.layoutType == Enum.EditModeLayoutType.Character then
				CharacterCount = CharacterCount + 1
			end
		end

		if CharacterCount >= Constants.EditModeConsts.EditModeMaxLayoutsPerType then
			YxUI:print("Select a custom Edit Mode layout to enable Always Show Buttons; character layout slots are full.")
			return true
		end

		Layout = CopyTable(Layout)
		Layout.layoutType = Enum.EditModeLayoutType.Character
		Layout.layoutName = "YxUI"
		Layout.layoutIndex = nil
		-- Restore the original preset in the save table.
		Layouts[Info.activeLayout] = EditModePresetLayoutManager:GetCopyOfPresetLayouts()[Info.activeLayout]
		table.insert(Layouts, Layout)
		AddedLayout = #Layouts
	end

	Info.layouts = Layouts
	C_EditMode.SaveLayouts(Info)
	if AddedLayout then
		C_EditMode.OnLayoutAdded(AddedLayout, true, false)
	else
		C_EditMode.SetActiveLayout(Info.activeLayout)
	end
	return true
end

function AB:EnableAlwaysShowButtons()
	-- This frame is separate from AB's extra-action-bar combat repair handler.
	local Pending = CreateFrame("Frame")
	local Applying = false
	local function Apply()
		if Applying then
			return
		end
		Applying = true
		local Complete = EnableAlwaysShowButtons()
		Applying = false
		if Complete then
			Pending:UnregisterAllEvents()
			Pending:SetScript("OnEvent", nil)
		end
	end

	Pending:RegisterEvent("PLAYER_ENTERING_WORLD")
	Pending:RegisterEvent("PLAYER_REGEN_ENABLED")
	if C_EditMode and C_EditMode.GetLayouts then
		Pending:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
	end
	Pending:SetScript("OnEvent", Apply)
	Apply()
end

local MultiCastSummonSpellButton_Update
MultiCastSummonSpellButton_Update = function()
	if InCombatLockdown() then
		return AB:RunProtectedUpdate(MultiCastActionBarFrame, "layout", MultiCastSummonSpellButton_Update)
	end

	for i = 1, 12 do
		local Button = _G["MultiCastActionButton" .. i]
		if Button then
			Button:ClearAllPoints()
			if i == 1 or i == 5 or i == 9 then
				Button:SetPoint("LEFT", MultiCastSummonSpellButton, "RIGHT", 2, 0)
			else
				Button:SetPoint("LEFT", _G["MultiCastActionButton" .. i-1], "RIGHT", 2, 0)
			end
		end
	end
end

local MultiCastRecallSpellButton_Update
MultiCastRecallSpellButton_Update = function()
	if InCombatLockdown() then
		return AB:RunProtectedUpdate(MultiCastRecallSpellButton, "layout", MultiCastRecallSpellButton_Update)
	end
	if not (MultiCastRecallSpellButton and MultiCastActionButton4) then return end
	MultiCastRecallSpellButton:ClearAllPoints()
	MultiCastRecallSpellButton:SetPoint("LEFT", MultiCastActionButton4, "RIGHT", 2, 0)
end

local MultiCastFlyoutFrame_LoadSlotSpells
MultiCastFlyoutFrame_LoadSlotSpells = function()
	if InCombatLockdown() then
		return AB:RunProtectedUpdate(MultiCastFlyoutFrame, "flyout", MultiCastFlyoutFrame_LoadSlotSpells)
	end
	if not MultiCastFlyoutFrame then return end

	for i = 1, 8 do
		local Button = _G["MultiCastFlyoutButton" .. i]
		if not Button then break end

		if not Button.HydraFlyoutStyled then
			Button:SetNormalTexture("")
			if Button.Border then Button.Border:SetTexture(nil) end
			if Button.icon and i ~= 1 then
				Button.icon:ClearAllPoints()
				Button.icon:SetPoint("TOPLEFT", Button, 0, 0)
				Button.icon:SetPoint("BOTTOMRIGHT", Button, 0, 0)
				Button.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
			end

			local Name = Button:GetName()
			local FloatingBG = Name and _G[Name .. "FloatingBG"]
			if FloatingBG and FloatingBG.SetParent then
				AB:Disable(FloatingBG)
			end

			local Backdrop = Button.HydraFlyoutBackdrop
			if not Backdrop then
				Backdrop = CreateFrame("Frame", nil, Button, "BackdropTemplate")
				Button.HydraFlyoutBackdrop = Backdrop
				Button.Backdrop = Button.Backdrop or Backdrop
				Backdrop:SetPoint("TOPLEFT", Button, -1, 1)
				Backdrop:SetPoint("BOTTOMRIGHT", Button, 1, -1)
				Backdrop:SetBackdrop(YxUI.Backdrop)
				Backdrop:SetBackdropColor(0, 0, 0)
				Backdrop.Texture = Backdrop:CreateTexture(nil, "BACKGROUND")
				Backdrop.Texture:SetPoint("TOPLEFT", Backdrop, 1, -1)
				Backdrop.Texture:SetPoint("BOTTOMRIGHT", Backdrop, -1, 1)
			end
			Backdrop:SetFrameLevel(math.max(0, Button:GetFrameLevel() - 1))
			Backdrop.Texture:SetTexture(Assets:GetTexture(Settings["ui-header-texture"]))
			Backdrop.Texture:SetVertexColor(YxUI:HexToRGB(Settings["ui-window-main-color"]))

			local Highlight = Button:GetHighlightTexture()
			if Highlight then
				Highlight:SetTexture(Assets:GetTexture(Settings["action-bars-button-highlight"]))
				Highlight:SetColorTexture(1, 1, 1, 0.2)
				Highlight:ClearAllPoints()
				Highlight:SetPoint("TOPLEFT", Button, 0, 0)
				Highlight:SetPoint("BOTTOMRIGHT", Button, 0, 0)
			end
			Button.HydraFlyoutStyled = true
		end

		Button:ClearAllPoints()
		if i == 1 then
			Button:SetPoint("BOTTOM", MultiCastFlyoutFrame, 0, 3)
		else
			Button:SetPoint("BOTTOM", _G["MultiCastFlyoutButton" .. i - 1], "TOP", 0, 4)
		end
	end

	if MultiCastFlyoutFrameCloseButton then
		MultiCastFlyoutFrameCloseButton:ClearAllPoints()
		MultiCastFlyoutFrameCloseButton:SetPoint("BOTTOM", MultiCastFlyoutFrame, "TOP", 0, -8)
	end
end

function AB:StyleTotemBar()
	if self.TotemBar then return end
	if not (MultiCastActionBarFrame and MultiCastSummonSpellButton and MultiCastRecallSpellButton and MultiCastFlyoutFrame and MultiCastSlotButton4) then return end
	self.TotemBar = CreateFrame("Frame", "YxUI Totem Bar", YxUI.UIParent, "SecureHandlerStateTemplate")
	self.TotemBar:SetPoint("BOTTOMLEFT", YxUI.UIParent, 408, 13)
	self.TotemBar:SetSize((30 * 6) + (2 * 5), 30)

	MultiCastActionBarFrame:SetParent(self.TotemBar)
	MultiCastSummonSpellButton:SetParent(self.TotemBar)
	MultiCastSummonSpellButton:ClearAllPoints()
	MultiCastSummonSpellButton:SetPoint("LEFT", self.TotemBar, 0, 0)

	self:StyleActionButton(MultiCastSummonSpellButton)

	if MultiCastSummonSpellButtonHighlight then MultiCastSummonSpellButtonHighlight:SetTexture(nil) end

	for i = 1, 4 do
		local Slot = _G["MultiCastSlotButton"..i]

		Slot:SetParent(MultiCastActionBarFrame)

		Slot.background:ClearAllPoints()
		Slot.background:SetPoint("TOPLEFT", Slot, 1, -1)
		Slot.background:SetPoint("BOTTOMRIGHT", Slot, -1, 1)
		Slot.background:SetDrawLayer("BACKGROUND", -1)
		Slot.overlayTex:SetTexture(nil) -- Colored border

		Slot:ClearAllPoints()

		if i == 1 then
			Slot:SetPoint("LEFT", MultiCastSummonSpellButton, "RIGHT", 2, 0)
		else
			Slot:SetPoint("LEFT", _G["MultiCastSlotButton"..i-1], "RIGHT", 2, 0)
		end
	end

	for i = 1, 12 do
		local Button = _G["MultiCastActionButton"..i]

		self:StyleActionButton(Button)

		--Button:SetParent(MultiCastActionBarFrame)
		Button:ClearAllPoints()
		Button.overlayTex:SetTexture(nil)

		--Button.Backdrop:SetFrameStrata("BACKGROUND")

		--Button:ClearAllPoints()

		if i == 1 or i == 5 or i == 9 then
			Button:SetPoint("LEFT", MultiCastSummonSpellButton, "RIGHT", 2, 0)
		else
			Button:SetPoint("LEFT", _G["MultiCastActionButton"..i-1], "RIGHT", 2, 0)
		end
	end

	MultiCastRecallSpellButton:SetParent(self.TotemBar)
	self:StyleActionButton(MultiCastRecallSpellButton)
	MultiCastRecallSpellButton:ClearAllPoints()
	MultiCastRecallSpellButton:SetPoint("LEFT", MultiCastSlotButton4, "RIGHT", 2, 0)

	if MultiCastRecallSpellButtonHighlight then MultiCastRecallSpellButtonHighlight:SetTexture(nil) end

	if MultiCastFlyoutFrame.top then MultiCastFlyoutFrame.top:SetTexture(nil) end
	if MultiCastFlyoutFrame.middle then MultiCastFlyoutFrame.middle:SetTexture(nil) end

	if type(_G.MultiCastSummonSpellButton_Update) == "function" then
		hooksecurefunc("MultiCastSummonSpellButton_Update", MultiCastSummonSpellButton_Update)
	end
	if type(_G.MultiCastRecallSpellButton_Update) == "function" then
		hooksecurefunc("MultiCastRecallSpellButton_Update", MultiCastRecallSpellButton_Update)
	end
	if type(_G.MultiCastFlyoutFrame_LoadSlotSpells) == "function" then
		hooksecurefunc("MultiCastFlyoutFrame_LoadSlotSpells", MultiCastFlyoutFrame_LoadSlotSpells)
	end
	if Settings["ab-totem-enable"] then
		self:EnableBar(self.TotemBar)
	else
		self:DisableBar(self.TotemBar)
	end
end

local UpdateEnableTotemBar = function(value)
	if value then
		AB:EnableBar(AB.TotemBar)
	else
		AB:DisableBar(AB.TotemBar)
	end
end



GUI:AddWidgetsID("General", "Totem Bar", "Action Bars", function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("ab-totem-enable", Settings["ab-totem-enable"], Language["Enable Bar"], Language["Enable the totem bar"], UpdateEnableTotemBar)
end)
YxUI:GetModule("GUI"):RegisterPageSettingsID("General", "Totem Bar", {
	{"ab-totem-enable", UpdateEnableTotemBar},
}, "Action Bars")

