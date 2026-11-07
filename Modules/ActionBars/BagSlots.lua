local YxUI, Language, Assets, Settings, Defaults = select(2, ...):get()

local BagsFrame = YxUI:NewModule("Bags Frame")

-- Default settings values
Defaults["bags-loot-from-left"] = false
Defaults["bags-frame-visibility"] = "SHOW"
Defaults["bags-frame-opacity"] = 40
Defaults["bags-frame-max"] = 100
Defaults["bags-frame-size"] = 32

local IsVanilla = YxUI.IsVanilla
local IsTBC = YxUI.IsTBC
local HasLegacyKeyRing = IsVanilla or IsTBC
local HasKeyRing = HasLegacyKeyRing or (YxUI.IsForever and KeyRingButton ~= nil)
local ForeverKeyRingWidthRatio = 33 / 45

local StyleKeyRingTextures = function(button)
	-- Keyring artwork occupies only 18x39 pixels of a 32x64 texture.
	-- Crop inside that region, and replace the stock fixed-size CENTER anchor.
	local Normal = button:GetNormalTexture()
	local Pushed = button:GetPushedTexture()

	for _, Texture in ipairs({Normal, Pushed}) do
		Texture:ClearAllPoints()
		Texture:SetAllPoints(button)
		Texture:SetRotation(0)
		Texture:SetTexCoord(0.05625, 0.50625, 0.0609375, 0.5484375)
	end
end

if YxUI.IsForever and HasKeyRing then
	BagsFrame.Objects = {
		KeyRingButton,
		CharacterReagentBag0Slot,
		CharacterBag3Slot,
		CharacterBag2Slot,
		CharacterBag1Slot,
		CharacterBag0Slot,
		MainMenuBarBackpackButton,
	}
elseif YxUI.IsMainline then
	BagsFrame.Objects = {
		CharacterReagentBag0Slot,
		CharacterBag3Slot,
		CharacterBag2Slot,
		CharacterBag1Slot,
		CharacterBag0Slot,
		MainMenuBarBackpackButton,
	}
elseif HasKeyRing then
	BagsFrame.Objects = {
		KeyRingButton,
		CharacterBag3Slot,
		CharacterBag2Slot,
		CharacterBag1Slot,
		CharacterBag0Slot,
		MainMenuBarBackpackButton,
	}
else
	BagsFrame.Objects = {
		CharacterBag3Slot,
		CharacterBag2Slot,
		CharacterBag1Slot,
		CharacterBag0Slot,
		MainMenuBarBackpackButton,
	}
end

local BagsFrameButtonOnEnter = function(self)
	if Settings["bags-frame-visibility"] == "MOUSEOVER" then
		BagsFrame:SetAlpha(Settings["bags-frame-max"] / 100)
	end
end

local BagsFrameOnEnter = function(self)
	BagsFrame:SetAlpha(Settings["bags-frame-max"] / 100)
end

local BagsFrameButtonOnLeave = function(self)
	if Settings["bags-frame-visibility"] == "MOUSEOVER" then
		BagsFrame:SetAlpha(Settings["bags-frame-opacity"] / 100)
	end
end

local BagsFrameOnLeave = function(self)
	BagsFrame:SetAlpha(Settings["bags-frame-opacity"] / 100)
end

function BagsFrame:SetAlpha(alpha)
	self.Panel:SetAlpha(alpha)

	if HasKeyRing then
		KeyRingButton:SetAlpha(alpha)
	end
end

function BagsFrame:UpdateVisibility()
	if not self.Panel then
		return
	end

	if InCombatLockdown() then
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end

	if Settings["bags-frame-visibility"] == "HIDE" then
		self.Panel:SetScript("OnEnter", nil)
		self.Panel:SetScript("OnLeave", nil)
		self:SetAlpha(0)

		if HasKeyRing then
			KeyRingButton:EnableMouse(false)
		end

		self.Panel:Hide()
	elseif Settings["bags-frame-visibility"] == "MOUSEOVER" then
		self.Panel:SetScript("OnEnter", BagsFrameOnEnter)
		self.Panel:SetScript("OnLeave", BagsFrameOnLeave)
		self:SetAlpha(Settings["bags-frame-opacity"] / 100)

		if HasKeyRing then
			KeyRingButton:EnableMouse(true)
		end

		self.Panel:Show()
	elseif Settings["bags-frame-visibility"] == "SHOW" then
		self.Panel:SetScript("OnEnter", nil)
		self.Panel:SetScript("OnLeave", nil)
		self:SetAlpha(Settings["bags-frame-max"] / 100)

		if HasKeyRing then
			KeyRingButton:EnableMouse(true)
		end

		self.Panel:Show()
	end
end

function BagsFrame:PositionButtons()
	if not self.Panel or self.IsPositioning then
		return
	end

	if InCombatLockdown() then
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end

	self.IsPositioning = true

	for i = 1, #self.Objects do
		local Object = self.Objects[i]

		if Object ~= KeyRingButton then
			Object:SetParent(self.Panel)
		end
	end

	local Previous
	local VisibleCount = 0
	local Size = Settings["bags-frame-size"]

	for i = #self.Objects, 1, -1 do
		local Object = self.Objects[i]

		if not YxUI.IsMainline or Object:IsShown() then
			Object:ClearAllPoints()

			if Previous then
				Object:SetPoint("RIGHT", Previous, "LEFT", -4, 0)
			else
				Object:SetPoint("RIGHT", self.Panel, -4, 0)
			end

			Previous = Object
			VisibleCount = VisibleCount + 1
		end

		if HasLegacyKeyRing and i == 1 then
			Object:SetSize(Size / 2, Size)
		elseif YxUI.IsForever and Object == KeyRingButton then
			Object:SetSize(Size * ForeverKeyRingWidthRatio, Size)
		else
			Object:SetSize(Size, Size)
		end
	end

	if HasLegacyKeyRing then
		StyleKeyRingTextures(KeyRingButton)
		self.Panel:SetSize(((Size + 4) * (#self.Objects - 1)) + 8 + (Size / 2), Size + 8)
	else
		-- IsShown checks each button's own state even when our panel is hidden.
		-- Collapsed retail bars retain only the backpack and reagent bag.
		local Width = ((Size + 4) * VisibleCount) + 4
		if YxUI.IsForever and HasKeyRing and KeyRingButton:IsShown() then
			Width = Width - Size * (1 - ForeverKeyRingWidthRatio)
		end
		self.Panel:SetSize(Width, Size + 8)
	end

	self.IsPositioning = false
end

local RestoreBagButtonPositions = function()
	BagsFrame:PositionButtons()
end

local StyleForeverBagBar = function()
	if not YxUI.IsForever or not BagsBar then
		return
	end

	if BagsBar.BorderArt then
		BagsBar.BorderArt:SetTexture(nil)
	end

	BagsBar.useDividers = false

	if BagsBar.HorizontalDividersPool then
		BagsBar.HorizontalDividersPool:ReleaseAll()
	end

	if BagsBar.VerticalDividersPool then
		BagsBar.VerticalDividersPool:ReleaseAll()
	end
end

local HideForeverBagContextOverlay = function(button)
	if button.ItemContextOverlay then
		button.ItemContextOverlay:Hide()
	end
end

local StyleMainlineBagTextures = function(button)
	-- CircularItemButtonTemplate masks the item and both search overlays.
	-- Detach the mask rather than hiding it, which leaves textures masked.
	if button.CircleMask then
		local Icon = button.Icon or button.icon

		if Icon then
			Icon:RemoveMaskTexture(button.CircleMask)
		end

		if button.searchOverlay then
			button.searchOverlay:RemoveMaskTexture(button.CircleMask)
		end

		if button.ItemContextOverlay then
			button.ItemContextOverlay:RemoveMaskTexture(button.CircleMask)
		end
	end

	if YxUI.IsForever and button.SquareMask then
		local Icon = button.Icon or button.icon

		if Icon then
			Icon:RemoveMaskTexture(button.SquareMask)
		end
	end

	-- UpdateTextures reapplies circular atlases on bag updates. Keep the
	-- original regions available to Blizzard, but replace their artwork.
	local Normal = button:GetNormalTexture()
	local Pushed = button:GetPushedTexture()
	local Highlight = button:GetHighlightTexture()

	if Normal then
		Normal:SetTexture(nil)
	end

	if Pushed then
		Pushed:SetColorTexture(0.2, 0.9, 0.2, 0.4)
	end

	if Highlight then
		Highlight:SetColorTexture(1, 1, 1, 0.25)
		Highlight:SetBlendMode("BLEND")
		Highlight:SetAlpha(1)
	end

	if button.SlotHighlightTexture then
		button.SlotHighlightTexture:SetColorTexture(0.9, 0.9, 0.1, 0.2)
	end
end

function BagsFrame:Load()
	if not Settings["ab-enable"] then
		return
	end

	self.Panel = CreateFrame("Frame", "YxUI Bags Window", YxUI.UIParent, "BackdropTemplate")
	self.Panel:SetPoint("BOTTOMRIGHT", YxUI:GetModule("Micro Buttons").Panel, "TOPRIGHT", 0, 3)
	self.Panel:SetBackdrop(YxUI.BackdropAndBorder)
	self.Panel:SetBackdropColor(YxUI:HexToRGB(Settings["ui-window-bg-color"]))
	self.Panel:SetBackdropBorderColor(0, 0, 0)
	self.Panel:SetFrameStrata("LOW")

	if HasLegacyKeyRing then
		self.Panel:SetSize(((Settings["bags-frame-size"] + 4) * (#self.Objects - 1)) + 8 + (Settings["bags-frame-size"] / 2), Settings["bags-frame-size"] + 8)
	else
		local Size = Settings["bags-frame-size"]
		local Width = ((Size + 4) * #self.Objects) + 4
		if YxUI.IsForever and HasKeyRing and KeyRingButton:IsShown() then
			Width = Width - Size * (1 - ForeverKeyRingWidthRatio)
		end
		self.Panel:SetSize(Width, Size + 8)
	end

	YxUI:CreateMover(self.Panel)

	local Object

	for i = 1, #self.Objects do
		Object = self.Objects[i]

		if Object ~= KeyRingButton then
			Object:SetParent(self.Panel)
		end
		Object:HookScript("OnEnter", BagsFrameButtonOnEnter)
		Object:HookScript("OnLeave", BagsFrameButtonOnLeave)

		local Name = Object:GetName()
		local Normal = Object:GetNormalTexture() or _G[Name .. "NormalTexture"]
		local Count = _G[Name .. "Count"]
		local Stock = _G[Name .. "Stock"]

		if Object.IconBorder then
			Object.IconBorder:SetAlpha(0)
		end

		if Normal and Object ~= KeyRingButton then
			Normal:SetTexture(nil)
		end

		if Count then
			Count:ClearAllPoints()
			Count:SetPoint("BOTTOMRIGHT", 0, 2)
			Count:SetJustifyH("RIGHT")
			YxUI:SetFontInfo(Count, Settings["ui-widget-font"], Settings["ui-font-size"])
		end

		if Stock then
			Stock:ClearAllPoints()
			Stock:SetPoint("TOPLEFT", 0, -2)
			Stock:SetJustifyH("LEFT")
			YxUI:SetFontInfo(Stock, Settings["ui-widget-font"], Settings["ui-font-size"])
		end

		local Icon = Object.Icon or Object.icon or _G[Name .. "IconTexture"]

		-- The retail backpack uses button-state artwork rather than an item
		-- icon. Give it a separate texture so clearing the normal artwork
		-- cannot erase the backpack, including when Blizzard updates its state.
		if YxUI.IsMainline and Object == MainMenuBarBackpackButton then
			Icon = Object:CreateTexture(nil, "ARTWORK")
			Icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_08")
			Object.BackpackIcon = Icon
		end

		if Icon then
			if Object.IconMask then
				Icon:RemoveMaskTexture(Object.IconMask)
				Object.IconMask:Hide()
			end

			Icon:ClearAllPoints()
			Icon:SetAllPoints(Object)
			Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		end

		if Object.SlotArt then
			Object.SlotArt:Hide()
		end

		if Object.SlotBackground then
			Object.SlotBackground:Hide()
		end

		Object.BG = Object:CreateTexture(nil, "BACKGROUND")
		Object.BG:SetPoint("TOPLEFT", Object, -1, 1)
		Object.BG:SetPoint("BOTTOMRIGHT", Object, 1, -1)
		Object.BG:SetColorTexture(0, 0, 0)

		if YxUI.IsMainline and Object.SlotHighlightTexture then
			Object.SlotHighlightTexture:SetTexture(Assets:GetTexture("Blank"))
			Object.SlotHighlightTexture:SetVertexColor(0.9, 0.9, 0.1, 0.2)
		else
			local Checked = Object:CreateTexture(nil, "ARTWORK")
			Checked:SetPoint("TOPLEFT", Object, 0, 0)
			Checked:SetPoint("BOTTOMRIGHT", Object, 0, 0)
			Checked:SetColorTexture(0.9, 0.9, 0.1, 0.2)
			Checked:SetDrawLayer("ARTWORK", 7)

			Object:SetCheckedTexture(Checked)
		end

		local Highlight = Object:CreateTexture(nil, "ARTWORK")
		Highlight:SetPoint("TOPLEFT", Object, 0, 0)
		Highlight:SetPoint("BOTTOMRIGHT", Object, 0, 0)
		Highlight:SetColorTexture(1, 1, 1, 0.25)

		Object:SetHighlightTexture(Highlight)

		if Object ~= KeyRingButton then
			local Pushed = Object:CreateTexture(nil, "ARTWORK")
			Pushed:SetPoint("TOPLEFT", Object, 0, 0)
			Pushed:SetPoint("BOTTOMRIGHT", Object, 0, 0)
			Pushed:SetColorTexture(0.2, 0.9, 0.2, 0.4)
			Pushed:SetDrawLayer("ARTWORK", 7)

			Object:SetPushedTexture(Pushed)
		end
	end

	if YxUI.IsForever then
		StyleForeverBagBar()
	end

	if YxUI.IsMainline and BagsBar and EventRegistry then
		-- Blizzard's expansion callback reanchors bag buttons during combat.
		EventRegistry:UnregisterCallback("MainMenuBarManager.OnExpandChanged", BagsBar)
	end

	if YxUI.IsMainline then
		for i = 1, #self.Objects do
			local Button = self.Objects[i]
			StyleMainlineBagTextures(Button)
			hooksecurefunc(Button, "UpdateTextures", StyleMainlineBagTextures)

			if YxUI.IsForever and Button.UpdateItemContextOverlay and Button.ItemContextOverlay then
				HideForeverBagContextOverlay(Button)
				hooksecurefunc(Button, "UpdateItemContextOverlay", HideForeverBagContextOverlay)
			end
		end
	end

	self:PositionButtons()

	-- Keep Blizzard's Edit Mode/layout updates from moving the buttons back
	-- under a bag bar whose visibility is controlled independently of ours.
	for i = 1, #self.Objects do
		hooksecurefunc(self.Objects[i], "SetPoint", RestoreBagButtonPositions)

		if YxUI.IsMainline then
			self.Objects[i]:HookScript("OnShow", RestoreBagButtonPositions)
			self.Objects[i]:HookScript("OnHide", RestoreBagButtonPositions)
			hooksecurefunc(self.Objects[i], "SetParent", RestoreBagButtonPositions)
			hooksecurefunc(self.Objects[i], "SetSize", RestoreBagButtonPositions)
		end
	end

	if HasKeyRing and KeyRingButton.UpdateOrientation then
		hooksecurefunc(KeyRingButton, "UpdateOrientation", RestoreBagButtonPositions)
	end

	self:SetScript("OnEvent", function(self)
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
		self:PositionButtons()
		self:UpdateVisibility()
	end)

	if C_Container and C_Container.SetInsertItemsLeftToRight then
		C_Container.SetInsertItemsLeftToRight(Settings["bags-loot-from-left"])
	else
		SetInsertItemsLeftToRight(Settings["bags-loot-from-left"])
	end

	self:UpdateVisibility()
end

local UpdateBagVisibility = function()
	BagsFrame:UpdateVisibility()
end

local UpdateBagFrameSize = function(value)
	if not BagsFrame.Panel then
		return
	end

	BagsFrame:PositionButtons()
end

local function UpdateVisibilityDependencies()
	YxUI:GetModule("GUI").WidgetCore.UpdateDependencies({
		["bags-frame-opacity"] = Settings["bags-frame-visibility"] == "MOUSEOVER",
		["bags-frame-max"] = Settings["bags-frame-visibility"] == "MOUSEOVER",
	})
end

YxUI:GetModule("GUI"):AddWidgetsID("General", "Action Bars", function(left, right)
	right:CreateHeader(Language["Bags Frame"])
	right:CreateDropdown("bags-frame-visibility", Settings["bags-frame-visibility"], {[Language["Hide"]] = "HIDE", [Language["Mouseover"]] = "MOUSEOVER", [Language["Show"]] = "SHOW"}, Language["Set Visibility"], Language["Set the visibility of the bag frame"], function(value) UpdateBagVisibility(value); UpdateVisibilityDependencies() end)
	right:CreateSlider("bags-frame-size", Settings["bags-frame-size"], 12, 60, 2, Language["Set Bag Size"], Language["Set the size of the bag frame slots"], UpdateBagFrameSize)
	right:CreateSlider("bags-frame-opacity", Settings["bags-frame-opacity"], 0, 100, 10, Language["Set Faded Opacity"], Language["Set the opacity of the bags frame when visibility is set to Mouseover"], UpdateBagVisibility, nil, "%")
	right:CreateSlider("bags-frame-max", Settings["bags-frame-max"], 0, 100, 10, Language["Set Max Opacity"], Language["Set the max opacity of the bags frame when visibility is set to Mouseover"], UpdateBagVisibility, nil, "%")
	right:CreateSwitch("bags-loot-from-left", Settings["bags-loot-from-left"], Language["Loot Left to Right"], Language["When looting, new items will be placed in the leftmost bag"], C_Container and C_Container.SetInsertItemsLeftToRight or SetInsertItemsLeftToRight)
	UpdateVisibilityDependencies()
end)
YxUI:GetModule("GUI"):RegisterPageSettingsID("General", "Action Bars", {
	{"bags-frame-visibility", function(value) UpdateBagVisibility(value); UpdateVisibilityDependencies() end},
	{"bags-frame-size", UpdateBagFrameSize},
	{"bags-frame-opacity", UpdateBagVisibility},
	{"bags-frame-max", UpdateBagVisibility},
	{"bags-loot-from-left", C_Container and C_Container.SetInsertItemsLeftToRight or SetInsertItemsLeftToRight},
}, nil)

