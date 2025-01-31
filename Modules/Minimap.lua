local Y, L, A, C, D = YxUIGlobal:get()

local Map = Y:NewModule("Minimap")

-- Default settings values
D["minimap-enable"] = true
D["minimap-size"] = 230
D["minimap-show-top"] = true
D["minimap-show-bottom"] = true
D["minimap-buttons-enable"] = true
D["minimap-buttons-size"] = 22
D["minimap-buttons-spacing"] = 6
D["minimap-buttons-perrow"] = 8
D["minimap-top-height"] = 15
D["minimap-bottom-height"] = 15
D["minimap-top-fill"] = 0
D["minimap-bottom-fill"] = 0
D["minimap-show-calendar"] = true
D["minimap-mail-pulse"] = true

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

    -- Backdrop
    self:SetPoint("TOPRIGHT", Y.UIParent, -4, -4)
    self:SetSize(C["minimap-size"], C["minimap-size"])

    -- Style minimap
    Minimap:SetMaskTexture(A:GetTexture("Blank"))
    Minimap:SetFrameLevel(10)
    Minimap:SetParent(self)
    Minimap:ClearAllPoints()
    Minimap:SetSize(C["minimap-size"], C["minimap-size"])
    Minimap:SetAllPoints(self)
    Minimap:EnableMouseWheel(true)
    Minimap:SetScript("OnMouseWheel", OnMouseWheel)

    local minimapBorder = CreateFrame("Frame", nil, Minimap)
    minimapBorder:SetAllPoints(Minimap)
    minimapBorder:SetFrameLevel(Minimap:GetFrameLevel())
    minimapBorder:SetFrameStrata("LOW")
    minimapBorder:CreateBorder()

    if C["minimap-mail-pulse"] then
        local MinimapMailFrame = MiniMapMailFrame or MinimapCluster.IndicatorFrame.MailFrame

        local minimapMailPulse = CreateFrame("Frame", nil, Minimap, "BackdropTemplate")
        minimapMailPulse:SetBackdrop({
            edgeFile = A:GetTexture("Glow Overlay"),
            edgeSize = 12,
        })
        minimapMailPulse:SetPoint("TOPLEFT", minimapBorder, -5, 5)
        minimapMailPulse:SetPoint("BOTTOMRIGHT", minimapBorder, 5, -5)
        minimapMailPulse:Hide()

        local anim = minimapMailPulse:CreateAnimationGroup()
        anim:SetLooping("BOUNCE")
        anim.fader = anim:CreateAnimation("Alpha")
        anim.fader:SetFromAlpha(0.8)
        anim.fader:SetToAlpha(0.2)
        anim.fader:SetDuration(1)
        anim.fader:SetSmoothing("OUT")

        -- Add comments to describe the purpose of the function
        local function updateMinimapBorderAnimation(_, event)
            local borderColor = nil

            -- If player enters combat, set border color to red
            if event == "PLAYER_REGEN_DISABLED" then
                borderColor = { 1, 0, 0, 0.8 }
            elseif not InCombatLockdown() then
                if C_Calendar.GetNumPendingInvites() > 0 or MinimapMailFrame:IsShown() then
                    -- If there are pending calendar invites or minimap mail frame is shown, set border color to yellow
                    borderColor = { 1, 1, 0, 0.8 }
                end
            end

            -- If a border color was set, show the minimap mail pulse frame and play the animation
            if borderColor then
                minimapMailPulse:Show()
                minimapMailPulse:SetBackdropBorderColor(unpack(borderColor))
                anim:Play()
            else
                minimapMailPulse:Hide()
                minimapMailPulse:SetBackdropBorderColor(1, 1, 0, 0.8)
                -- Stop the animation
                anim:Stop()
            end
        end
        self:RegisterEvent("CALENDAR_UPDATE_PENDING_INVITES", updateMinimapBorderAnimation)
        self:RegisterEvent("PLAYER_REGEN_DISABLED", updateMinimapBorderAnimation)
        self:RegisterEvent("PLAYER_REGEN_ENABLED", updateMinimapBorderAnimation)
        self:RegisterEvent("UPDATE_PENDING_MAIL", updateMinimapBorderAnimation)

        MinimapMailFrame:HookScript("OnHide", function()
            if InCombatLockdown() then
                return
            end

            if anim and anim:IsPlaying() then
                anim:Stop()
                minimapMailPulse:Hide()
            end
        end)
    end

    self.TopFrame = CreateFrame("Frame", "YxUIMinimapTop", self, "BackdropTemplate")
    self.TopFrame:SetHeight(C["minimap-top-height"])
    self.TopFrame:SetPoint("TOPLEFT", Minimap, 0, 0)
    self.TopFrame:SetPoint("TOPRIGHT", Minimap, 0, 0)
    self.TopFrame:SetFrameLevel(Minimap:GetFrameLevel() + 1)
    Y:AddBackdrop(self.TopFrame, A:GetTexture("YxUI 4"))
    self.TopFrame.Outside:SetBackdropColor(R, G, B, (C["minimap-top-fill"] / 100))
    self.TopFrame.Outside:SetBackdropBorderColor(0, 0, 0, C["minimap-top-fill"] > 0 and 1 or 0)

    if C["minimap-top-fill"] == 0 then
        self.TopFrame:Hide()
        Minimap:HookScript("OnEnter", function()
            self.TopFrame.Anchor:SetPoint('LEFT', 25, 0)
            self.TopFrame.Anchor:SetPoint('RIGHT', -25, 0)
            self.TopFrame:Show()
        end)

        Minimap:HookScript("OnLeave", function()
            if not MouseIsOver(self.TopFrame) then
                self.TopFrame:Hide()
            end
        end)
    end

    self.BottomFrame = CreateFrame("Frame", "YxUIMinimapBottom", self, "BackdropTemplate")
    self.BottomFrame:SetHeight(C["minimap-bottom-height"])
    self.BottomFrame:SetPoint("BOTTOMLEFT", self, 50, 0)
    self.BottomFrame:SetPoint("BOTTOMRIGHT", self, -50, 0)
    Y:AddBackdrop(self.BottomFrame, A:GetTexture("YxUI 4"))
    self.BottomFrame.Outside:SetBackdropColor(R, G, B, (C["minimap-bottom-fill"] / 100))
    self.BottomFrame.Outside:SetBackdropBorderColor(0, 0, 0, C["minimap-top-fill"] > 0 and 1 or 0)

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
            MiniMapLFGFrame:SetSize(24, 24)
            MiniMapLFGFrame:ClearAllPoints()
            MiniMapLFGFrame:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 0, 0)
            MiniMapLFGFrame.SetPoint = Y.Dummy
            MiniMapLFGFrameBorder:Hide()

            MiniMapLFGFrameIcon:SetAlpha(0)

            local queueIcon = MiniMapLFGFrame:CreateTexture(nil, "ARTWORK")
            queueIcon:SetPoint("CENTER", MiniMapLFGFrame)
            queueIcon:SetSize(56, 56)
            queueIcon:SetTexture("Interface\\Minimap\\Dungeon_Icon")

            local anim = queueIcon:CreateAnimationGroup()
            anim:SetLooping("REPEAT")
            anim.rota = anim:CreateAnimation("Rotation")
            anim.rota:SetDuration(2)
            anim.rota:SetDegrees(360)

            hooksecurefunc(MiniMapLFGFrameIcon, "SetScript", function()
                if MiniMapLFGFrameIcon:GetScript('OnUpdate') then
                    anim:Play()
                else
                    anim:Stop()
                end
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
        self.Tracking:SetPoint("TOPLEFT", Minimap, 1, -1)
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
        MiniMapTrackingFrame:SetPoint("TOPLEFT", Minimap, 2, -4)
        MiniMapTrackingFrame:SetFrameLevel(Minimap:GetFrameLevel() + 12)

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
        GameTimeFrame:SetFrameLevel(Minimap:GetFrameLevel() + 12)
        GameTimeFrame:ClearAllPoints()
        GameTimeFrame:SetPoint("TOPRIGHT", Minimap, -1, -1)
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

local function UpdateMinimapSize(value)
    C_Timer.After(0.1, function()
        if not value then
            value = C["minimap-size"]
        end
        Map:SetSize(value, value)
        Minimap:SetSize(value, value)
        Minimap:SetZoom(Minimap:GetZoom() + 1)
        Minimap:SetZoom(Minimap:GetZoom() - 1)
        Minimap:UpdateBlips()
    end)
end

local function UpdateShowTopBar(value)
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

    UpdateMinimapSize()
end

local function UpdateShowBottomBar(value)
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

    UpdateMinimapSize()
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
