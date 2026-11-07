local YxUI, Language, Assets, Settings, Defaults = select(2, ...):get()

local AB = YxUI:GetModule("Action Bars")
local GUI = YxUI:GetModule("GUI")

local NUM_PET_ACTION_SLOTS = NUM_PET_ACTION_SLOTS
local ActionBarDescriptors = AB.ActionBarDescriptors

local BarButtonOnEnter = function(self)
	if self.ParentBar.Fader:IsPlaying() then
		self.ParentBar.Fader:Stop()
	end

	for i = 1, #self.ParentBar do
		self.ParentBar[i].cooldown:SetDrawBling(true)
	end

	self.ParentBar.Fader:SetChange(self.ParentBar.MaxAlpha / 100)
	self.ParentBar.Fader:Play()
end

local BarButtonOnLeave = function(self)
	if self.ParentBar.Fader:IsPlaying() then
		self.ParentBar.Fader:Stop()
	end

	for i = 1, #self.ParentBar do
		self.ParentBar[i].cooldown:SetDrawBling(false)
	end

	self.ParentBar.Fader:SetChange(self.ParentBar.ShouldFade and 0 or (self.ParentBar.MaxAlpha / 100))
	self.ParentBar.Fader:Play()
end

local BarOnEnter = function(self)
	if self.Fader:IsPlaying() then
		self.Fader:Stop()
	end

	for i = 1, #self do
		self[i].cooldown:SetDrawBling(true)
	end

	self.Fader:SetChange(self.MaxAlpha / 100)
	self.Fader:Play()
end

local BarOnLeave = function(self)
	if self.Fader:IsPlaying() then
		self.Fader:Stop()
	end

	for i = 1, #self do
		self[i].cooldown:SetDrawBling(false)
	end

	self.Fader:SetChange(self.ShouldFade and 0 or (self.MaxAlpha / 100))
	self.Fader:Play()
end

AB.BarOnEnter = BarOnEnter
AB.BarOnLeave = BarOnLeave

local function ResolveAnchorValue(owner, value, gap)
	if value == "UIParent" then
		return YxUI.UIParent
	elseif value == "gap" then
		return gap
	elseif value == "negativeGap" then
		return -gap
	elseif type(value) == "string" then
		return owner[value]
	end

	return value
end

function AB:CreateActionBar(descriptor)
	if not descriptor.available() then
		return
	end

	local index = descriptor.index
	local key = "ab-bar" .. index
	local anchor = descriptor.anchor
	local gap = Settings[key .. "-button-gap"]
	local bar = CreateFrame("Frame", "YxUI Action Bar " .. index, YxUI.UIParent, "SecureHandlerStateTemplate")
	self[descriptor.field] = bar
	self.Bars[#self.Bars + 1] = bar
	bar.Descriptor = descriptor
	bar:SetPoint(anchor[1], ResolveAnchorValue(self, anchor[2], gap), anchor[3], ResolveAnchorValue(self, anchor[4], gap), ResolveAnchorValue(self, anchor[5], gap))
	bar:SetAlpha(Settings[key .. "-alpha"] / 100)
	bar.ShouldFade = Settings[key .. "-hover"]
	bar.MaxAlpha = Settings[key .. "-alpha"]

	local blizzardParent = descriptor.parent and _G[descriptor.parent]
	bar.ButtonParent = blizzardParent
	if blizzardParent then
		blizzardParent:SetParent(bar)
	end

	bar.Fader = LibMotion:CreateAnimation(bar, "Fade")
	bar.Fader:SetDuration(0.15)
	bar.Fader:SetEasing("inout")

	for i = 1, 12 do
		local button = _G[descriptor.prefix .. i]
		self:StyleActionButton(button)
		if descriptor.securePaging then
			button:SetParent(bar)
			bar:SetFrameRef("Button" .. i, button)
		end
		button.ParentBar = bar
		button:HookScript("OnEnter", BarButtonOnEnter)
		button:HookScript("OnLeave", BarButtonOnLeave)
		bar[i] = button
	end

	if Settings[key .. "-hover"] then
		bar:SetAlpha(0)
		bar:SetScript("OnEnter", BarOnEnter)
		bar:SetScript("OnLeave", BarOnLeave)
		for i = 1, #bar do
			bar[i].cooldown:SetDrawBling(false)
		end
	end

	self:PositionButtons(bar, Settings[key .. "-button-max"], Settings[key .. "-per-row"], Settings[key .. "-button-size"], gap)
	if Settings[key .. "-enable"] then
		self:EnableBar(bar)
	else
		self:DisableBar(bar)
	end
	return bar
end

function AB:ConfigureBar1Paging(bar)
	bar.GetSpellFlyoutDirection = function() return "UP" end -- Temp
	bar:Execute([[
		Buttons = table.new()
		for i = 1, 12 do
			table.insert(Buttons, self:GetFrameRef("Button" .. i))
		end
	]])

	if YxUI.IsVanilla then
		bar:SetAttribute("_onstate-page", [[
			if GetOverrideBarIndex and HasOverrideActionBar() then
				newstate = GetOverrideBarIndex() or newstate
			elseif HasTempShapeshiftActionBar() then
				newstate = GetTempShapeshiftBarIndex() or newstate
			elseif HasBonusActionBar() and GetActionBarPage() == 1 then
				newstate = GetBonusBarIndex() or newstate
			else
				newstate = GetActionBarPage() or newstate
			end
			for i = 1, 12 do
				Buttons[i]:SetAttribute("actionpage", newstate)
			end
		]])
		RegisterAttributeDriver(bar, "state-page", "[overridebar] 14; [shapeshift] 13; [possessbar] 16; [bar:2] 2; [bar:3] 3; [bar:4] 4; [bar:5] 5; [bar:6] 6; [bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10; [bonusbar:5] 11; [form] 1; 1")
	else
		bar:SetAttribute("_onstate-page", [[
			if GetVehicleBarIndex and HasVehicleActionBar() then
				newstate = GetVehicleBarIndex()
			elseif HasOverrideActionBar and HasOverrideActionBar() then
				newstate = GetOverrideBarIndex()
			elseif HasTempShapeshiftActionBar() then
				newstate = GetTempShapeshiftBarIndex()
			elseif HasBonusActionBar() then
				newstate = GetBonusBarIndex()
			end
			for i = 1, 12 do
				Buttons[i]:SetAttribute("actionpage", newstate)
			end
		]])
		RegisterAttributeDriver(bar, "state-page", "[overridebar] 14; [shapeshift] 13; [possessbar] 16; [vehicleui] 12; [bar:2] 2; [bar:3] 3; [bar:4] 4; [bar:5] 5; [bar:6] 6; [bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10; [bonusbar:5] 11; [form] 1; 1")
	end

	if OverrideActionBar then
		self:Disable(OverrideActionBar)
	end
end

local PetBarUpdateGridLayout = function()
	if not AB.PetBar or not AB.PetBar:IsShown() then
		return
	end

	AB:PositionButtons(AB.PetBar, NUM_PET_ACTION_SLOTS, Settings["ab-pet-per-row"], Settings["ab-pet-button-size"], Settings["ab-pet-button-gap"])
end

-- Pet
function AB:CreatePetBar()
	self.PetBar = CreateFrame("Frame", "YxUI Pet Bar", YxUI.UIParent, "SecureHandlerStateTemplate")
	self.PetBar:SetPoint("RIGHT", self.Bar5, "LEFT", -Settings["ab-pet-button-gap"], 0)
	self.PetBar:SetAlpha(Settings["ab-pet-alpha"] / 100)
	self.PetBar.ButtonParent = PetActionBar or PetActionBarFrame
	self.PetBar.ShouldFade = Settings["ab-pet-hover"]
	self.PetBar.MaxAlpha = Settings["ab-pet-alpha"]

	self.PetBar.Fader = LibMotion:CreateAnimation(self.PetBar, "Fade")
	self.PetBar.Fader:SetDuration(0.15)
	self.PetBar.Fader:SetEasing("inout")

	if PetActionBar then
		PetActionBar:SetParent(self.PetBar)
		PetActionBar:SetAllPoints(self.PetBar)
		PetActionBar:EnableMouse(false)

		hooksecurefunc(PetActionBar, "UpdateGridLayout", PetBarUpdateGridLayout)
	else
		PetActionBarFrame:SetParent(self.PetBar)

		for i = 1, PetActionBarFrame:GetNumRegions() do
			local Region = select(i, PetActionBarFrame:GetRegions())

			if Region.SetTexture then
				Region:SetTexture(nil)
			end
		end
	end

	for i = 1, NUM_PET_ACTION_SLOTS do
		local Button = _G["PetActionButton" .. i]

		self:StylePetActionButton(Button)

		Button.ParentBar = self.PetBar

		Button:HookScript("OnEnter", BarButtonOnEnter)
		Button:HookScript("OnLeave", BarButtonOnLeave)

		self.PetBar[i] = Button
	end

	if Settings["ab-pet-hover"] then
		self.PetBar:SetAlpha(0)
		self.PetBar:SetScript("OnEnter", BarOnEnter)
		self.PetBar:SetScript("OnLeave", BarOnLeave)

		for i = 1, #self.PetBar do
			self.PetBar[i].cooldown:SetDrawBling(false)
		end
	end

	self:PositionButtons(self.PetBar, NUM_PET_ACTION_SLOTS, Settings["ab-pet-per-row"], Settings["ab-pet-button-size"], Settings["ab-pet-button-gap"])

	if PetActionBar_Update then
		hooksecurefunc("PetActionBar_Update", AB.PetActionBar_Update)
	end

	if Settings["ab-pet-enable"] then
		self:EnableBar(self.PetBar)
	else
		self:DisableBar(self.PetBar)
	end
end

-- Stance
local StanceBarUpdateGridLayout = function()
	if not AB.StanceBar then
		return
	end

	AB:PositionButtons(AB.StanceBar, #AB.StanceBar, Settings["ab-stance-per-row"], Settings["ab-stance-button-size"], Settings["ab-stance-button-gap"])
end

function AB:CreateStanceBar()
	self.StanceBar = CreateFrame("Frame", "YxUI Stance Bar", YxUI.UIParent, "SecureHandlerStateTemplate")
	self.StanceBar:SetPoint("TOPLEFT", YxUI.UIParent, 10, -10)
	self.StanceBar:SetAlpha(Settings["ab-stance-alpha"] / 100)
	self.StanceBar.ButtonParent = StanceBar or StanceBarFrame
	self.StanceBar.ShouldFade = Settings["ab-stance-hover"]
	self.StanceBar.MaxAlpha = Settings["ab-stance-alpha"]

	self.StanceBar.Fader = LibMotion:CreateAnimation(self.StanceBar, "Fade")
	self.StanceBar.Fader:SetDuration(0.15)
	self.StanceBar.Fader:SetEasing("inout")

	if StanceBar then
		StanceBar:SetParent(self.StanceBar)
	else
		StanceBarFrame:SetParent(self.StanceBar)
	end

	if StanceBar then
		if StanceBar.UpdateGridLayout then
			hooksecurefunc(StanceBar, "UpdateGridLayout", StanceBarUpdateGridLayout)
		end

		for i, button in next, StanceBar.actionButtons do
			self:StyleActionButton(button)

			button.ParentBar = self.StanceBar

			button:HookScript("OnEnter", BarButtonOnEnter)
			button:HookScript("OnLeave", BarButtonOnLeave)

			self.StanceBar[i] = button
		end

		self:PositionButtons(self.StanceBar, #self.StanceBar, Settings["ab-stance-per-row"], Settings["ab-stance-button-size"], Settings["ab-stance-button-gap"])

		--hooksecurefunc("StanceBar_UpdateState", self.StanceBar_UpdateState)

		if Settings["ab-stance-hover"] then
			self.StanceBar:SetAlpha(0)
			self.StanceBar:SetScript("OnEnter", BarOnEnter)
			self.StanceBar:SetScript("OnLeave", BarOnLeave)

			for i = 1, #self.StanceBar do
				self.StanceBar[i].cooldown:SetDrawBling(false)
			end
		end
	end

	if StanceBarFrame and StanceBarFrame.StanceButtons then
		StanceBarLeft:SetAlpha(0)
		StanceBarRight:SetAlpha(0)

		for i = 1, NUM_STANCE_SLOTS do
			local Button = StanceBarFrame.StanceButtons[i]

			self:StyleActionButton(Button)

			Button.ParentBar = self.StanceBar

			Button:HookScript("OnEnter", BarButtonOnEnter)
			Button:HookScript("OnLeave", BarButtonOnLeave)

			self.StanceBar[i] = Button
		end

		self:PositionButtons(self.StanceBar, #self.StanceBar, Settings["ab-stance-per-row"], Settings["ab-stance-button-size"], Settings["ab-stance-button-gap"])

		hooksecurefunc("StanceBar_UpdateState", self.StanceBar_UpdateState)

		if Settings["ab-stance-hover"] then
			self.StanceBar:SetAlpha(0)
			self.StanceBar:SetScript("OnEnter", BarOnEnter)
			self.StanceBar:SetScript("OnLeave", BarOnLeave)

			for i = 1, #self.StanceBar do
				self.StanceBar[i].cooldown:SetDrawBling(false)
			end
		end
	end

	if Settings["ab-stance-enable"] then
		self:EnableBar(self.StanceBar)
	else
		self:DisableBar(self.StanceBar)
	end
end

local UpdateZoneAbilityPosition = function(self, anchor, parent)
	if parent and parent ~= AB.ExtraBar then
		if InCombatLockdown() then
			return AB:RunProtectedUpdate(self, "position", function()
				if AB.ExtraBar then
					self:ClearAllPoints()
					self:SetPoint("CENTER", AB.ExtraBar)
				end
			end)
		end
		self:ClearAllPoints()
		self:SetPoint("CENTER", AB.ExtraBar)
	end
end

local SkinZoneAbilityButtons = function()
	for Button in ZoneAbilityFrame.SpellButtonContainer:EnumerateActive() do
		if not Button.Styled then
			Button.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
			Button.NormalTexture:SetAlpha(0)

			Button.Backdrop = CreateFrame("Frame", nil, Button, "BackdropTemplate")
			Button.Backdrop:SetPoint("TOPLEFT", Button, -1, 1)
			Button.Backdrop:SetPoint("BOTTOMRIGHT", Button, 1, -1)
			Button.Backdrop:SetBackdrop(YxUI.Backdrop)
			Button.Backdrop:SetBackdropColor(0, 0, 0)
			Button.Backdrop:SetFrameLevel(Button:GetFrameLevel() - 1)

			Button.Styled = true
		end
	end
end

local UpdateExtraActionParent = function(self, parent)
	if InCombatLockdown() then
		AB.NeedsCombatFix = true

		AB:RegisterEvent("PLAYER_REGEN_ENABLED")
		AB:SetScript("OnEvent", AB.OnEvent)

		return
	end

	if parent and parent ~= AB.ExtraBar then
		self:SetParent(AB.ExtraBar)
	end
end

-- Extra Bar
function AB:CreateExtraBar()
	self.ExtraBar = CreateFrame("Frame", "YxUI Extra Action", YxUI.UIParent, "SecureHandlerStateTemplate")
	self.ExtraBar:SetSize(Settings["ab-extra-button-size"], Settings["ab-extra-button-size"])
	self.ExtraBar:SetPoint("CENTER", YxUI.UIParent, 0, -220)

	ExtraActionBarFrame:SetParent(YxUIParent)
	ExtraActionBarFrame:ClearAllPoints()
	ExtraActionBarFrame:SetAllPoints(self.ExtraBar)
	ExtraActionButton1.style:SetAlpha(0)
	ExtraActionBarFrame.ignoreInLayout = true

	--hooksecurefunc(ExtraActionBarFrame, "SetPoint", UpdateExtraActionPosition)
	hooksecurefunc(ExtraActionBarFrame, "SetParent", UpdateExtraActionParent)

	self:StyleActionButton(ExtraActionButton1)

	if YxUI.IsMists then
		--ExtraActionButton1:SetParent(ExtraActionBarFrame)
		ExtraActionButton1:ClearAllPoints()
		ExtraActionButton1:SetPoint("CENTER", ExtraActionBarFrame)
	end

	if ZoneAbilityFrame then
		ZoneAbilityFrame:ClearAllPoints()
		ZoneAbilityFrame:SetPoint("CENTER", self.ExtraBar)
		ZoneAbilityFrame.Style:SetAlpha(0)
		--ZoneAbilityFrame.ignoreInLayout = true

		hooksecurefunc(ZoneAbilityFrame, "SetPoint", UpdateZoneAbilityPosition)
		hooksecurefunc(ZoneAbilityFrame, "UpdateDisplayedZoneAbilities", SkinZoneAbilityButtons)
	end
end

function AB:OnEvent(event, ...)
	if self[event] then
		self[event](self, ...)
	end
end

function AB:PLAYER_REGEN_ENABLED()
	if self.NeedsCombatFix then
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
		self:SetScript("OnEvent", nil)

		ExtraActionBarFrame:SetParent(AB.ExtraBar)

		self.NeedsCombatFix = nil
	end
end

function AB:CreateBars()
	self.Bars = {}
	for _, descriptor in ipairs(ActionBarDescriptors) do
		local bar = self:CreateActionBar(descriptor)
		if bar and descriptor.securePaging then
			self:ConfigureBar1Paging(bar)
		end
	end

	if PetActionBar or PetActionBarFrame then
		self:CreatePetBar()
	end
	if StanceBar or StanceBarFrame then
		self:CreateStanceBar()
	end
	if ExtraActionButton1 then
		self:CreateExtraBar()
	end
	if MultiCastActionBarFrame and MultiCastActionBarFrame.numActiveSlots and MultiCastActionBarFrame.numActiveSlots > 0 then
		self:StyleTotemBar()
	end
end

-- Black magic, the movers won't budge if a secure frame is positioned on it
local Bar1PreMove = function(self)
	local A1, P, A2, X, Y = self:GetPoint()

	AB.Bar1:Hide()
	AB.Bar1:ClearAllPoints() -- Clear the bar from the mover
	AB.Bar1:SetPoint(A1, YxUI.UIParent, A2, X, Y)
end

local Bar1PostMove = function(self)
	local A1, P, A2, X, Y = self:GetPoint()

	self:ClearAllPoints()

	AB.Bar1:ClearAllPoints()
	AB.Bar1:SetPoint("CENTER", self, 0, 0) -- Position the frame to the mover again
	AB.Bar1:Show()

	self:SetPoint(A1, YxUI.UIParent, A2, X, Y)
end

function AB:CreateMovers()
	for _, bar in ipairs(self.Bars) do
		local mover = YxUI:CreateMover(bar)
		if bar == self.Bar1 then
			self.Bar1Mover = mover
		end
	end

	if self.StanceBar then
		YxUI:CreateMover(self.StanceBar)
	end

	if self.PetBar then
		YxUI:CreateMover(self.PetBar)
	end

	if self.TotemBar then
		YxUI:CreateMover(self.TotemBar)
	end

	if YxUI.IsMists then -- Temporarily disabling the mover on Mists, causing issues
	--if ExtraActionButton1 then
		self.ExtraBarMover = YxUI:CreateMover(self.ExtraBar)
	end

	self.Bar1Mover.PreMove = Bar1PreMove
	self.Bar1Mover.PostMove = Bar1PostMove
end

local NUM_PET_ACTION_SLOTS = NUM_PET_ACTION_SLOTS
local ActionBarDescriptors = AB.ActionBarDescriptors
local BarOnEnter = AB.BarOnEnter
local BarOnLeave = AB.BarOnLeave

local UpdateBar = {}
local UpdateEnableBar = {}

local function CreateBarLayoutCallback(descriptor)
	local index, field = descriptor.index, descriptor.field
	local key = "ab-bar" .. index
	return function()
		local bar = AB[field]
		if bar then
			AB:PositionButtons(bar, descriptor.hasButtonMax and Settings[key .. "-button-max"] or #bar, Settings[key .. "-per-row"], Settings[key .. "-button-size"], Settings[key .. "-button-gap"])
		end
	end
end

local function CreateBarEnableCallback(descriptor)
	local field = descriptor.field
	return function(value)
		local bar = AB[field]
		if value then
			AB:EnableBar(bar)
		else
			AB:DisableBar(bar)
		end
	end
end

for _, descriptor in ipairs(ActionBarDescriptors) do
	UpdateBar[descriptor.index] = CreateBarLayoutCallback(descriptor)
	UpdateEnableBar[descriptor.index] = CreateBarEnableCallback(descriptor)
end

AB.BarLayoutCallbacks = UpdateBar

-- Keep bar layouts aligned after Blizzard changes specialization or action pages.
local LayoutEvents = CreateFrame("Frame")
LayoutEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
if YxUI.IsMainline then
	LayoutEvents:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
	LayoutEvents:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	LayoutEvents:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	LayoutEvents:RegisterEvent("PLAYER_TALENT_UPDATE")
elseif GetActiveTalentGroup then
	LayoutEvents:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
end
LayoutEvents:SetScript("OnEvent", function(self, event, unit)
	if event == "PLAYER_SPECIALIZATION_CHANGED" and unit ~= "player" then return end
	if self.Pending then return end
	self.Pending = true
	C_Timer.After(0.7, function()
		self.Pending = nil
		if not AB.Loaded or not Settings["ab-enable"] then return end
		for index, callback in next, UpdateBar do
			local ok, err = pcall(callback)
			if not ok then YxUI:print("Action bar layout refresh failed for bar " .. index .. ": " .. tostring(err)) end
		end
	end)
end)

local UpdatePetBar
UpdatePetBar = function()
	if not AB.PetBar then return end
	if InCombatLockdown() then
		return AB:RunProtectedUpdate(AB.PetBar, "layout", UpdatePetBar)
	end
	AB:PositionButtons(AB.PetBar, NUM_PET_ACTION_SLOTS, Settings["ab-pet-per-row"], Settings["ab-pet-button-size"], Settings["ab-pet-button-gap"])

	for i = 1, #AB.PetBar do
		local Name = AB.PetBar[i]:GetName()

		if _G[Name .. "AutoCastable"] then
			_G[Name .. "AutoCastable"]:SetSize(Settings["ab-pet-button-size"] * 2 - 4, Settings["ab-pet-button-size"] * 2 - 4)
		end
	end
end

local UpdateStanceBar = function()
	if not AB.StanceBar then return end
	AB:PositionButtons(AB.StanceBar, #AB.StanceBar, Settings["ab-stance-per-row"], Settings["ab-stance-button-size"], Settings["ab-stance-button-gap"])
end

local UpdateEnablePetBar = function(value)
	if value then
		AB:EnableBar(AB.PetBar)
	else
		AB:DisableBar(AB.PetBar)
	end
end

local UpdateEnableStanceBar = function(value)
	if value then
		AB:EnableBar(AB.StanceBar)
	else
		AB:DisableBar(AB.StanceBar)
	end
end

local UpdateEnableTotemBar = function(value)
	if value then
		AB:EnableBar(AB.TotemBar)
	else
		AB:DisableBar(AB.TotemBar)
	end
end



local function SetBarHover(bar, enabled)
	if not bar then
		return
	end
	if InCombatLockdown() then
		return AB:RunProtectedUpdate(bar, "hover", function() SetBarHover(bar, enabled) end)
	end

	bar.ShouldFade = enabled
	bar:SetScript("OnEnter", enabled and BarOnEnter or nil)
	bar:SetScript("OnLeave", enabled and BarOnLeave or nil)
	bar:SetAlpha(enabled and 0 or (bar.MaxAlpha / 100))

	for i = 1, #bar do
		bar[i].cooldown:SetDrawBling(not enabled)
	end
end

local function SetBarAlpha(bar, percent)
	if not bar then
		return
	end

	bar.MaxAlpha = percent
	bar:SetAlpha(bar.ShouldFade and 0 or (percent / 100))
end

local UpdateHoverBar = {}
local UpdateAlphaBar = {}

local function CreateBarHoverCallback(descriptor)
	return function(value)
		SetBarHover(AB[descriptor.field], value)
	end
end

local function CreateBarAlphaCallback(descriptor)
	return function(value)
		SetBarAlpha(AB[descriptor.field], value)
	end
end

for _, descriptor in ipairs(ActionBarDescriptors) do
	UpdateHoverBar[descriptor.index] = CreateBarHoverCallback(descriptor)
	UpdateAlphaBar[descriptor.index] = CreateBarAlphaCallback(descriptor)
end

local UpdatePetHover = function(value)
	SetBarHover(AB.PetBar, value)
end
local UpdateStanceHover = function(value)
	SetBarHover(AB.StanceBar, value)
end
local UpdatePetBarAlpha = function(value)
	SetBarAlpha(AB.PetBar, value)
end
local UpdateStanceBarAlpha = function(value)
	SetBarAlpha(AB.StanceBar, value)
end



local function AddActionBarWidgets(descriptor)
	if not descriptor.available() then
		return
	end

	local index = descriptor.index
	local key = "ab-bar" .. index
	local function UpdateBarDependencies()
		local enabled = Settings[key .. "-enable"]
		local rules = {
			[key .. "-hover"] = enabled,
			[key .. "-alpha"] = enabled,
			[key .. "-per-row"] = enabled,
			[key .. "-button-size"] = enabled,
			[key .. "-button-gap"] = enabled,
		}
		if descriptor.hasButtonMax then rules[key .. "-button-max"] = enabled end
		GUI.WidgetCore.UpdateDependencies(rules)
	end
	GUI:AddWidgetsID("General", descriptor.label, "Action Bars", function(left, right)
		left:CreateHeader(Language["Enable"])
		left:CreateSwitch(key .. "-enable", Settings[key .. "-enable"], Language["Enable Bar"], Language["Enable action bar " .. index], function(value) UpdateEnableBar[index](value); UpdateBarDependencies() end)

		left:CreateHeader(Language["Styling"])
		left:CreateSwitch(key .. "-hover", Settings[key .. "-hover"], Language["Set Mouseover"], Language["Only display the bar while hovering over it"], UpdateHoverBar[index])
		left:CreateSlider(key .. "-alpha", Settings[key .. "-alpha"], 0, 100, 5, Language["Bar Opacity"], Language["Set the opacity of the action bar"], UpdateAlphaBar[index])

		right:CreateHeader(Language["Buttons"])
		right:CreateSlider(key .. "-per-row", Settings[key .. "-per-row"], 1, 12, 1, Language["Buttons Per Row"], Language["Set the number of buttons per row"], UpdateBar[index])
		if descriptor.hasButtonMax then
			right:CreateSlider(key .. "-button-max", Settings[key .. "-button-max"], 1, 12, 1, Language["Max Buttons"], Language["Set the number of buttons displayed on the action bar"], UpdateBar[index])
		end
		right:CreateSlider(key .. "-button-size", Settings[key .. "-button-size"], 20, 50, 1, Language["Button Size"], Language["Set the action button size"], UpdateBar[index])
		right:CreateSlider(key .. "-button-gap", Settings[key .. "-button-gap"], -1, 8, 1, Language["Button Spacing"], Language["Set the spacing between action buttons"], UpdateBar[index])
		UpdateBarDependencies()
	end)
YxUI:GetModule("GUI"):RegisterPageSettingsID("General", descriptor.label, {
	{key .. "-enable", function(value) UpdateEnableBar[index](value); UpdateBarDependencies() end},
	{key .. "-hover", UpdateHoverBar[index]},
	{key .. "-alpha", UpdateAlphaBar[index]},
	{key .. "-per-row", UpdateBar[index]},
	{key .. "-button-max", UpdateBar[index]},
	{key .. "-button-size", UpdateBar[index]},
	{key .. "-button-gap", UpdateBar[index]},
}, "Action Bars")

end

for _, descriptor in ipairs(ActionBarDescriptors) do
	AddActionBarWidgets(descriptor)
end

GUI:AddWidgetsID("General", "Pet Bar", "Action Bars", function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("ab-pet-enable", Settings["ab-pet-enable"], Language["Enable Bar"], Language["Enable the pet action bar"], function(value) UpdateEnablePetBar(value); GUI.WidgetCore.UpdateDependencies({["ab-pet-hover"] = value, ["ab-pet-alpha"] = value, ["ab-pet-per-row"] = value, ["ab-pet-button-size"] = value, ["ab-pet-button-gap"] = value}) end)

	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("ab-pet-hover", Settings["ab-pet-hover"], Language["Set Mouseover"], Language["Only display the bar while hovering over it"], UpdatePetHover)
	left:CreateSlider("ab-pet-alpha", Settings["ab-pet-alpha"], 0, 100, 5, Language["Bar Opacity"], Language["Set the opacity of the action bar"], UpdatePetBarAlpha)

	right:CreateHeader(Language["Buttons"])
	right:CreateSlider("ab-pet-per-row", Settings["ab-pet-per-row"], 1, NUM_PET_ACTION_SLOTS, 1, Language["Buttons Per Row"], Language["Set the number of buttons per row"], UpdatePetBar)
	right:CreateSlider("ab-pet-button-size", Settings["ab-pet-button-size"], 20, 50, 1, Language["Button Size"], Language["Set the action button size"], UpdatePetBar)
	right:CreateSlider("ab-pet-button-gap", Settings["ab-pet-button-gap"], -1, 8, 1, Language["Button Spacing"], Language["Set the spacing between action buttons"], UpdatePetBar)
	GUI.WidgetCore.UpdateDependencies({["ab-pet-hover"] = Settings["ab-pet-enable"], ["ab-pet-alpha"] = Settings["ab-pet-enable"], ["ab-pet-per-row"] = Settings["ab-pet-enable"], ["ab-pet-button-size"] = Settings["ab-pet-enable"], ["ab-pet-button-gap"] = Settings["ab-pet-enable"]})
end)
YxUI:GetModule("GUI"):RegisterPageSettingsID("General", "Pet Bar", {
	{"ab-pet-enable", function(value) UpdateEnablePetBar(value); GUI.WidgetCore.UpdateDependencies({["ab-pet-hover"] = value, ["ab-pet-alpha"] = value, ["ab-pet-per-row"] = value, ["ab-pet-button-size"] = value, ["ab-pet-button-gap"] = value}) end},
	{"ab-pet-hover", UpdatePetHover},
	{"ab-pet-alpha", UpdatePetBarAlpha},
	{"ab-pet-per-row", UpdatePetBar},
	{"ab-pet-button-size", UpdatePetBar},
	{"ab-pet-button-gap", UpdatePetBar},
}, "Action Bars")


GUI:AddWidgetsID("General", "Stance Bar", "Action Bars", function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("ab-stance-enable", Settings["ab-stance-enable"], Language["Enable Bar"], Language["Enable the stance bar"], function(value) UpdateEnableStanceBar(value); GUI.WidgetCore.UpdateDependencies({["ab-stance-hover"] = value, ["ab-stance-alpha"] = value, ["ab-stance-per-row"] = value, ["ab-stance-button-size"] = value, ["ab-stance-button-gap"] = value}) end)

	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("ab-stance-hover", Settings["ab-stance-hover"], Language["Set Mouseover"], Language["Only display the bar while hovering over it"], UpdateStanceHover)
	left:CreateSlider("ab-stance-alpha", Settings["ab-stance-alpha"], 0, 100, 5, Language["Bar Opacity"], Language["Set the opacity of the action bar"], UpdateStanceBarAlpha)

	right:CreateHeader(Language["Buttons"])
	right:CreateSlider("ab-stance-per-row", Settings["ab-stance-per-row"], 1, 12, 1, Language["Buttons Per Row"], Language["Set the number of buttons per row"], UpdateStanceBar)
	right:CreateSlider("ab-stance-button-size", Settings["ab-stance-button-size"], 20, 50, 1, Language["Button Size"], Language["Set the action button size"], UpdateStanceBar)
	right:CreateSlider("ab-stance-button-gap", Settings["ab-stance-button-gap"], -1, 8, 1, Language["Button Spacing"], Language["Set the spacing between action buttons"], UpdateStanceBar)
	GUI.WidgetCore.UpdateDependencies({["ab-stance-hover"] = Settings["ab-stance-enable"], ["ab-stance-alpha"] = Settings["ab-stance-enable"], ["ab-stance-per-row"] = Settings["ab-stance-enable"], ["ab-stance-button-size"] = Settings["ab-stance-enable"], ["ab-stance-button-gap"] = Settings["ab-stance-enable"]})
end)
YxUI:GetModule("GUI"):RegisterPageSettingsID("General", "Stance Bar", {
	{"ab-stance-enable", function(value) UpdateEnableStanceBar(value); GUI.WidgetCore.UpdateDependencies({["ab-stance-hover"] = value, ["ab-stance-alpha"] = value, ["ab-stance-per-row"] = value, ["ab-stance-button-size"] = value, ["ab-stance-button-gap"] = value}) end},
	{"ab-stance-hover", UpdateStanceHover},
	{"ab-stance-alpha", UpdateStanceBarAlpha},
	{"ab-stance-per-row", UpdateStanceBar},
	{"ab-stance-button-size", UpdateStanceBar},
	{"ab-stance-button-gap", UpdateStanceBar},
}, "Action Bars")

