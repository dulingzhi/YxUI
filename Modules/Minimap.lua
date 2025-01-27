local Y, L, A, C, D = YxUIGlobal:get()

local Map = Y:NewModule("Minimap")

-- Default settings values
D["minimap-enable"] = true
D["minimap-size"] = 160
D["minimap-show-top"] = true
D["minimap-show-bottom"] = true
D["minimap-buttons-enable"] = true
D["minimap-buttons-size"] = 22
D["minimap-buttons-spacing"] = 2
D["minimap-buttons-perrow"] = 8
D["minimap-top-height"] = 28
D["minimap-bottom-height"] = 28
D["minimap-top-fill"] = 100
D["minimap-bottom-fill"] = 100
D["minimap-show-calendar"] = true

function Map:Disable(object)
	if (not object) then
		return
	end

	if object.UnregisterAllEvents then
		object:UnregisterAllEvents()
	end

	if (object.HasScript and object:HasScript("OnUpdate")) then
		object:SetScript("OnUpdate", nil)
	end

	object.Show = function() end
	object:Hide()
end

local OnMouseWheel = function(self, delta)
	if (delta > 0) then
		Minimap_ZoomIn()
	elseif (delta < 0) then
		Minimap_ZoomOut()
	end
end

local MailOnEnter = function()
	MiniMapMailIcon:SetVertexColor(Y:HexToRGB("FFFFFF"))
end

local MailOnLeave = function()
	MiniMapMailIcon:SetVertexColor(Y:HexToRGB("EEEEEE"))
end

function Map:Style()
	local R, G, B = Y:HexToRGB(C["ui-window-main-color"])
	local Border = C["ui-border-thickness"]
	local Width = C["minimap-size"] + (Border * 2)

	-- Backdrop
	self:SetPoint("TOPRIGHT", Y.UIParent, -12, -12)
	self:SetSize((C["minimap-size"] + 8), ((C["minimap-show-top"] == true and 22 or 0) + (C["minimap-show-bottom"] == true and 22 or 0) + 8 + C["minimap-size"]))

	self.TopFrame = CreateFrame("Frame", "YxUIMinimapTop", self, "BackdropTemplate")
	self.TopFrame:SetSize(Width, C["minimap-top-height"])
	self.TopFrame:SetPoint("TOP", self, 0, 0)
	Y:AddBackdrop(self.TopFrame, A:GetTexture("YxUI 4"))
	self.TopFrame.Outside:SetBackdropColor(R, G, B, (C["minimap-top-fill"] / 100))

	self.Middle = CreateFrame("Frame", nil, self, "BackdropTemplate")
	self.Middle:SetSize(Width, C["minimap-size"])
	self.Middle:SetPoint("TOP", self.TopFrame, "BOTTOM", 0, 1 > Border and 1 or (Border + 2))
	Y:AddBackdrop(self.Middle)
	self.Middle.Outside:SetBackdropColor(R, G, B, 0)

	self.BottomFrame = CreateFrame("Frame", "YxUIMinimapBottom", self, "BackdropTemplate")
	self.BottomFrame:SetSize(Width, C["minimap-bottom-height"])
	self.BottomFrame:SetPoint("TOP", self.Middle, "BOTTOM", 0, 1 > Border and 1 or (Border + 2))
	Y:AddBackdrop(self.BottomFrame, A:GetTexture("YxUI 4"))
	self.BottomFrame.Outside:SetBackdropColor(R, G, B, (C["minimap-bottom-fill"] / 100))

	-- Style minimap
	Minimap:SetMaskTexture(A:GetTexture("Blank"))
	Minimap:SetParent(self)
	Minimap:ClearAllPoints()
	Minimap:SetSize(C["minimap-size"], C["minimap-size"])
	Minimap:SetPoint("TOPLEFT", self.Middle, Border + 1, -(Border + 1))
	Minimap:SetPoint("BOTTOMRIGHT", self.Middle, -(Border + 1), Border + 1)
	Minimap:EnableMouseWheel(true)
	Minimap:SetScript("OnMouseWheel", OnMouseWheel)

	if MinimapCompassTexture then
		MinimapCompassTexture:SetTexture(nil)
	end

	if Y.IsMainline then
	    Minimap:SetArchBlobRingScalar(0)
		Minimap:SetQuestBlobRingScalar(0)

		if QueueStatusButton then
			QueueStatusButton:ClearAllPoints()
			QueueStatusButton:SetPoint("BOTTOMLEFT", Y.UIParent, "BOTTOMRIGHT", -460, 13)

			if (not QueueStatusButton:IsMovable()) then
				QueueStatusButton:SetMovable(true)
				QueueStatusButton:SetClampedToScreen(true)
				QueueStatusButton:RegisterForDrag("LeftButton")
				QueueStatusButton:SetScript("OnDragStart", QueueStatusButton.StartMoving)
				QueueStatusButton:SetScript("OnDragStop", QueueStatusButton.StopMovingOrSizing)
			end
		end

		if GarrisonLandingPageMinimapButton then
			GarrisonLandingPageMinimapButton:SetSize(40, 40)
			GarrisonLandingPageMinimapButton:ClearAllPoints()
			GarrisonLandingPageMinimapButton:SetPoint("BOTTOMRIGHT", Minimap, 3, -4)
			GarrisonLandingPageMinimapButton.ClearAllPoints = function() end
			GarrisonLandingPageMinimapButton.SetPoint = function() end
			GarrisonLandingPageMinimapButton.SetSize = function() end
		end

		if ExpansionLandingPageMinimapButton then
			ExpansionLandingPageMinimapButton:SetSize(40, 40)
			ExpansionLandingPageMinimapButton:ClearAllPoints()
			ExpansionLandingPageMinimapButton:SetPoint("BOTTOMRIGHT", Minimap, 3, -4)
			ExpansionLandingPageMinimapButton.ClearAllPoints = function() end
			ExpansionLandingPageMinimapButton.SetPoint = function() end
			ExpansionLandingPageMinimapButton.SetSize = function() end
		end
	else
		if MiniMapLFGFrame then
			MiniMapLFGFrame:SetSize(18, 18)
			MiniMapLFGFrame:ClearAllPoints()
			MiniMapLFGFrame:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 0, 0)
			MiniMapLFGFrame.SetPoint = Y.Dummy
			MiniMapLFGFrameBorder:Hide()
			
			MiniMapLFGFrameIcon:SetAlpha(0)
			MiniMapLFGFrameIcon:Hide()
			
			local queueIcon = MiniMapLFGFrame:CreateTexture(nil, "ARTWORK")
			queueIcon:SetPoint("CENTER", MiniMapLFGFrame)
			queueIcon:SetSize(36, 36)
			queueIcon:SetTexture("Interface\\Minimap\\Dungeon_Icon")

			local anim = queueIcon:CreateAnimationGroup()
			anim:SetLooping("REPEAT")
			anim.rota = anim:CreateAnimation("Rotation")
			anim.rota:SetDuration(2)
			anim.rota:SetDegrees(360)

			hooksecurefunc("EyeTemplate_StartAnimating", function()
				anim:Play()
			end)

			hooksecurefunc("EyeTemplate_StopAnimating", function()
				anim:Pause()
			end)
			if MiniMapLFGFrameIcon:GetScript('OnUpdate') then
				anim:Play()
			end
		end

		if LFGMinimapFrame then
			LFGMinimapFrame:ClearAllPoints()
			LFGMinimapFrame:SetPoint("BOTTOMRIGHT", Minimap, 0, -3)
			LFGMinimapFrame:SetFrameLevel(10)
		end

		MiniMapBattlefieldFrame:ClearAllPoints()
		MiniMapBattlefieldFrame:SetPoint("BOTTOMLEFT", Minimap, 0, -3)
		MiniMapBattlefieldFrame:SetFrameLevel(10)
	end

	if MiniMapTrackingBorder then
		MiniMapTrackingBorder:SetTexture(nil)
	end

	if MiniMapTrackingButtonBorder then
		MiniMapTrackingButtonBorder:SetTexture(nil)
	end

	if MiniMapTrackingShine then
		MiniMapTrackingShine:SetTexture(nil)
	end

	if MiniMapMailFrame then
		MiniMapMailFrame:ClearAllPoints()
		MiniMapMailFrame:HookScript("OnEnter", MailOnEnter)
		MiniMapMailFrame:HookScript("OnLeave", MailOnLeave)
		MiniMapMailFrame:SetFrameLevel(10)

		if (MiniMapTracking and MiniMapTracking:IsShown()) then
			MiniMapMailFrame:SetPoint("TOPLEFT", MiniMapTracking, "BOTTOMLEFT", -7, 16)
		elseif (MiniMapTrackingFrame and MiniMapTrackingFrame:IsShown()) then
			MiniMapMailFrame:SetPoint("TOPLEFT", MiniMapTrackingFrame, "BOTTOMLEFT", -7, 16)
		else
			MiniMapMailFrame:SetPoint("TOPLEFT", Minimap, 4, 12)
		end

		MiniMapMailIcon:SetSize(32, 32)
		MiniMapMailIcon:SetTexture(A:GetTexture("Mail 2"))
		MiniMapMailIcon:SetVertexColor(Y:HexToRGB("EEEEEE"))
	end

	if MinimapNorthTag then
		MinimapNorthTag:SetTexture(nil)
	end

	if MiniMapTrackingBackground then
		MiniMapTrackingBackground:SetTexture(nil)
	end

	if (MiniMapTracking and MiniMapTracking:IsShown()) then
		self.Tracking = CreateFrame("Frame", nil, Minimap, "BackdropTemplate")
		self.Tracking:SetSize(24, 24)
		self.Tracking:SetPoint("TOPLEFT", Minimap, 2, -2)
		self.Tracking:SetFrameLevel(10)
		self.Tracking:SetBackdrop(Y.BackdropAndBorder)
		self.Tracking:SetBackdropColor(0, 0, 0)
		self.Tracking:SetBackdropBorderColor(0, 0, 0)

		self.Tracking.Tex = self.Tracking:CreateTexture(nil, "ARTWORK")
		self.Tracking.Tex:SetPoint("TOPLEFT", self.Tracking, 1, -1)
		self.Tracking.Tex:SetPoint("BOTTOMRIGHT", self.Tracking, -1, 1)
		self.Tracking.Tex:SetTexture(A:GetTexture(C["ui-header-texture"]))
		self.Tracking.Tex:SetVertexColor(Y:HexToRGB(C["ui-header-texture-color"]))

		MiniMapTracking:SetParent(self.Tracking)
		MiniMapTracking:ClearAllPoints()
		MiniMapTracking:SetPoint("CENTER", self.Tracking, 0, 0)

		MiniMapTrackingIcon:SetSize(20, 20)
		MiniMapTrackingIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		MiniMapTrackingIcon:SetPoint("CENTER", self.Tracking)
	end

	if MiniMapTrackingFrame then
		MiniMapTrackingFrame:ClearAllPoints()
		MiniMapTrackingFrame:SetSize(24, 24)
		MiniMapTrackingFrame:SetPoint("TOPLEFT", Minimap, 1, -1)
		MiniMapTrackingFrame:SetFrameLevel(Minimap:GetFrameLevel() + 1)

		MiniMapTrackingIcon:SetSize(18, 18)
		MiniMapTrackingIcon:ClearAllPoints()
		MiniMapTrackingIcon:SetPoint("TOPLEFT", MiniMapTrackingFrame, 1, -1)
		MiniMapTrackingIcon:SetPoint("BOTTOMRIGHT", MiniMapTrackingFrame, -1, 1)
		MiniMapTrackingIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

		if MiniMapTrackingBorder then
			MiniMapTrackingBorder:Hide()
			MiniMapTrackingBorder.Show = function() end
		end
	end

	self:Disable(MinimapCluster)
	self:Disable(MinimapBorder)
	self:Disable(MinimapBorderTop)
	self:Disable(MinimapZoomIn)
	self:Disable(MinimapZoomOut)
	self:Disable(MinimapNorthTag)
	self:Disable(MiniMapWorldMapButton)
	self:Disable(MiniMapMailBorder)
	self:Disable(TimeManagerClockButton)

	if (Y.ClientVersion > 30000) then
		local GameTimeFrame = GameTimeFrame
		local calendarText = GameTimeFrame:CreateFontString(nil, "OVERLAY")

		GameTimeFrame:SetParent(Minimap)
		GameTimeFrame:SetFrameLevel(16)
		GameTimeFrame:ClearAllPoints()
		GameTimeFrame:SetPoint("TOPRIGHT", Minimap, -4, -4)
		GameTimeFrame:SetHitRectInsets(0, 0, 0, 0)
		GameTimeFrame:SetSize(22, 22)
		GameTimeFrame:SetNormalTexture("Interface\\AddOns\\YxUI\\Media\\Textures\\Minimap\\Calendar.blp")
		GameTimeFrame:SetPushedTexture("Interface\\AddOns\\YxUI\\Media\\Textures\\Minimap\\Calendar.blp")
		GameTimeFrame:SetHighlightTexture(0)
		GameTimeFrame:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
		GameTimeFrame:GetPushedTexture():SetTexCoord(0, 1, 0, 1)

		calendarText:ClearAllPoints()
		calendarText:SetPoint("CENTER", 0, -3)
		calendarText:SetFont(A:GetFont("Matthan"), 12)
		calendarText:SetTextColor(0, 0, 0)
		calendarText:SetShadowOffset(0, 0)
		calendarText:SetAlpha(0.9)
		calendarText:SetText(C_DateAndTime.GetCurrentCalendarTime().monthDay)

		hooksecurefunc("GameTimeFrame_SetDate", function()
			calendarText:SetText(C_DateAndTime.GetCurrentCalendarTime().monthDay)
		end)

		if (not C["minimap-show-calendar"]) then
			GameTimeFrame:Hide()
		else
			GameTimeFrame:Show()
		end
	end

	if C["minimap-show-top"] and not C["minimap-show-bottom"] then
		Minimap:SetPoint("BOTTOM", Map, 0, 4)
	elseif C["minimap-show-bottom"] and not C["minimap-show-top"] then
		Minimap:SetPoint("TOP", Map, 0, -4)
	else
		Minimap:SetPoint("CENTER", Map, 0, 0)
	end

	if (not C["minimap-show-top"]) then
		self.TopFrame:Hide()
	end

	if (not C["minimap-show-bottom"]) then
		self.BottomFrame:Hide()
	end

	Y:CreateMover(self)
end

local UpdateMinimapSize = function(value)
	Map:SetSize((value + 8), ((C["minimap-show-top"] == true and C["minimap-top-height"] or 0) + (C["minimap-show-bottom"] == true and C["minimap-bottom-height"] or 0) + 8 + value))

	Minimap:SetSize(value, value)
	Minimap:SetZoom(Minimap:GetZoom() + 1)
	Minimap:SetZoom(Minimap:GetZoom() - 1)
	Minimap:UpdateBlips()

	Map.Middle:SetSize(value, value)
	Map.TopFrame:SetWidth(value)
	Map.BottomFrame:SetWidth(value)
end

local UpdateShowTopBar = function(value)
	local Anchor = Y:GetModule("DataText"):GetAnchor("Minimap-Top")

	if value then
		Map.TopFrame:Show()

		if Anchor.Enable then
			Anchor:Enable()
		end
	else
		Map.TopFrame:Hide()

		if Anchor.Disable then
			Anchor:Disable()
		end
	end

	UpdateMinimapSize(C["minimap-size"])
end

local UpdateShowBottomBar = function(value)
	local Anchor = Y:GetModule("DataText"):GetAnchor("Minimap-Bottom")

	if value then
		Map.BottomFrame:Show()

		if Anchor.Enable then
			Anchor:Enable()
		end
	else
		Map.BottomFrame:Hide()

		if Anchor.Disable then
			Anchor:Disable()
		end
	end

	UpdateMinimapSize(C["minimap-size"])
end

local UpdateTopHeight = function(value)
	Map.TopFrame:SetHeight(value)
end

local UpdateBottomHeight = function(value)
	Map.BottomFrame:SetHeight(value)
end

local UpdateTopFill = function(value)
	local R, G, B = Y:HexToRGB(C["ui-window-main-color"])

	Map.TopFrame.Outside:SetBackdropColor(R, G, B, (value / 100))
end

local UpdateBottomFill = function(value)
	local R, G, B = Y:HexToRGB(C["ui-window-main-color"])

	Map.BottomFrame.Outside:SetBackdropColor(R, G, B, (value / 100))
end

local UpdateShowTracking = function(value)
	if value then
		Map.Tracking:Show()
	else
		Map.Tracking:Hide()
	end
end

local UpdateShowCalendar = function(value)
	if value then
		GameTimeFrame:Show()
	else
		GameTimeFrame:Hide()
	end
end

function Map:Load()
	if (not C["minimap-enable"]) then
		return
	end

	self:Style()

	function GetMinimapShape()
		return "SQUARE"
	end
end

Y:GetModule("GUI"):AddWidgets(L["General"], L["Minimap"], function(left, right)
	left:CreateHeader(L["Enable"])
	left:CreateSwitch("minimap-enable", C["minimap-enable"], L["Enable Minimap Module"], L["Enable the YxUI mini map module"], ReloadUI):RequiresReload(true)

	left:CreateHeader(L["Styling"])
	left:CreateSwitch("minimap-show-top", C["minimap-show-top"], L["Enable Top Bar"], L["Enable the data text bar on top of the mini map"], UpdateShowTopBar)
	left:CreateSwitch("minimap-show-bottom", C["minimap-show-bottom"], L["Enable Bottom Bar"], L["Enable the data text bar on the bottom of the mini map"], UpdateShowBottomBar)

	if (Y.ClientVersion > 30000) then
		left:CreateSwitch("minimap-show-calendar", C["minimap-show-calendar"], L["Enable Calendar"], L["Enable the calendar button on the minimap"], UpdateShowCalendar)
	end

	left:CreateSlider("minimap-size", C["minimap-size"], 100, 250, 10, L["Mini Map Size"], L["Set the size of the mini map"], UpdateMinimapSize)
	left:CreateSlider("minimap-top-height", C["minimap-top-height"], 14, 40, 1, L["Top Height"], L["Set the height for the top of the minimap"], UpdateTopHeight)
	left:CreateSlider("minimap-bottom-height", C["minimap-bottom-height"], 14, 40, 1, L["Bottom Height"], L["Set the height for the bottom of the minimap"], UpdateBottomHeight)
	left:CreateSlider("minimap-top-fill", C["minimap-top-fill"], 0, 100, 5, L["Top Fill"], L["Set the opacity for the top of the minimap"], UpdateTopFill, nil, "%")
	left:CreateSlider("minimap-bottom-fill", C["minimap-bottom-fill"], 0, 100, 5, L["Bottom Fill"], L["Set the opacity for the bottom of the minimap"], UpdateBottomFill, nil, "%")
end)
