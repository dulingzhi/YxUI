-- 团队工具
local Y, L, A, C, D = YxUIGlobal:get()

local Module = Y:GetModule('Miscellaneous')

local function load()
    ----------------------------------------------------------------------------------------
    --	Raid Utility(by Elv22)
    ----------------------------------------------------------------------------------------
    -- Create main frame
    local RaidUtilityPanel = CreateFrame('Frame', 'YxUIRaidUtilityPanel', Y.UIParent)
    RaidUtilityPanel:SetSize(170, 145)
    RaidUtilityPanel:CreateBorder()
    if GetCVarBool('watchFrameWidth') then
        RaidUtilityPanel:SetPoint("TOP", Y.UIParent, "TOP", -180, 1)
    end
    RaidUtilityPanel.toggled = false
    Y:CreateMover(RaidUtilityPanel)

    -- Check if We are Raid Leader or Raid Officer
    local function CheckRaidStatus()
        local _, instanceType = IsInInstance()
        if ((GetNumGroupMembers() > 0 and UnitIsGroupLeader('player') and not UnitInRaid('player')) or UnitIsGroupLeader('player') or UnitIsGroupAssistant('player')) and (instanceType ~= 'pvp' or instanceType ~= 'arena') then
            return true
        else
            return false
        end
    end

    -- Function to create buttons in this module
    local function CreateButton(name, parent, template, width, height, point, relativeto, point2, xOfs, yOfs, text)
        local b = CreateFrame('Button', name, parent, template)
        b:SetWidth(width)
        b:SetHeight(height)
        b:SetPoint(point, relativeto, point2, xOfs, yOfs)
        b:EnableMouse(true)
        b:StyleButton()
        if text then
            b.t = b:CreateFontString(nil, 'OVERLAY')
            b.t:SetFont(C['ui-button-font'], C['ui-font-size'], "")
            b.t:SetPoint('CENTER')
            b.t:SetJustifyH('CENTER')
            b.t:SetText(text)
            b.t:SetWidth(width - 2)
            b.t:SetHeight(C['ui-font-size'])
        end
        return b
    end

    -- Show button
    CreateButton('RaidUtilityShowButton', Y.UIParent, 'UIPanelButtonTemplate, SecureHandlerClickTemplate', RaidUtilityPanel:GetWidth() / 1.5, 18, 'TOP', RaidUtilityPanel, 'TOP', 0, 0, RAID_CONTROL)
    RaidUtilityShowButton:SetFrameRef('RaidUtilityPanel', RaidUtilityPanel)
    RaidUtilityShowButton:SetAttribute('_onclick', [=[self:Hide(); self:GetFrameRef("RaidUtilityPanel"):Show();]=])
    RaidUtilityShowButton:SetScript('OnMouseUp', function(_, button)
        if button == 'RightButton' then
            if CheckRaidStatus() then
                DoReadyCheck()
            end
        elseif Y.IsMainline and button == 'MiddleButton' then
            if CheckRaidStatus() then
                InitiateRolePoll()
            end
        elseif button == 'LeftButton' then
            RaidUtilityPanel.toggled = true
        end
    end)

    -- Close button
    CreateButton('RaidUtilityCloseButton', RaidUtilityPanel, 'UIPanelButtonTemplate, SecureHandlerClickTemplate', RaidUtilityPanel:GetWidth() / 1.5, 18, 'TOP', RaidUtilityPanel, 'BOTTOM', 0, -1, CLOSE)
    RaidUtilityCloseButton:SetFrameRef('RaidUtilityShowButton', RaidUtilityShowButton)
    RaidUtilityCloseButton:SetAttribute('_onclick', [=[self:GetParent():Hide(); self:GetFrameRef("RaidUtilityShowButton"):Show();]=])
    RaidUtilityCloseButton:SetScript('OnMouseUp', function()
        RaidUtilityPanel.toggled = false
    end)

    -- Disband Group button
    CreateButton('RaidUtilityDisbandButton', RaidUtilityPanel, 'UIPanelButtonTemplate', RaidUtilityPanel:GetWidth() * 0.8, 18, 'TOP', RaidUtilityPanel, 'TOP', 0, -5, L_RAID_UTIL_DISBAND)
    RaidUtilityDisbandButton:SetScript('OnMouseUp', function()
        StaticPopup_Show('DISBAND_RAID')
    end)

    -- Convert Group button
    CreateButton('RaidUtilityConvertButton', RaidUtilityPanel, 'UIPanelButtonTemplate', RaidUtilityPanel:GetWidth() * 0.8, 18, 'TOP', RaidUtilityDisbandButton, 'BOTTOM', 0, -5, UnitInRaid('player') and CONVERT_TO_PARTY or CONVERT_TO_RAID)
    RaidUtilityConvertButton:SetScript('OnMouseUp', function()
        if UnitInRaid('player') then
            if not Y.IsMainline then
                ConvertToParty()
            else
                C_PartyInfo.ConvertToParty()
            end
            RaidUtilityConvertButton.t:SetText(CONVERT_TO_RAID)
        elseif UnitInParty('player') then
            if not Y.IsMainline then
                ConvertToRaid()
            else
                C_PartyInfo.ConvertToRaid()
            end
            RaidUtilityConvertButton.t:SetText(CONVERT_TO_PARTY)
        end
    end)

    -- Role Check button
    if Y.IsMainline then
        CreateButton('RaidUtilityRoleButton', RaidUtilityPanel, 'UIPanelButtonTemplate', RaidUtilityPanel:GetWidth() * 0.8, 18, 'TOP', RaidUtilityConvertButton, 'BOTTOM', 0, -5, ROLE_POLL)
        RaidUtilityRoleButton:SetScript('OnMouseUp', function()
            InitiateRolePoll()
        end)
    end

    -- MainTank button
    CreateButton('RaidUtilityMainTankButton', RaidUtilityPanel, 'UIPanelButtonTemplate, SecureActionButtonTemplate', (RaidUtilityDisbandButton:GetWidth() / 2) - 2, 18, 'TOPLEFT', RaidUtilityRoleButton or RaidUtilityConvertButton,
        'BOTTOMLEFT', 0, -5, TANK)
    RaidUtilityMainTankButton:SetAttribute('type', 'maintank')
    RaidUtilityMainTankButton:SetAttribute('unit', 'target')
    RaidUtilityMainTankButton:SetAttribute('action', 'toggle')

    -- MainAssist button
    CreateButton('RaidUtilityMainAssistButton', RaidUtilityPanel, 'UIPanelButtonTemplate, SecureActionButtonTemplate', (RaidUtilityDisbandButton:GetWidth() / 2) - 2, 18, 'TOPRIGHT', RaidUtilityRoleButton or RaidUtilityConvertButton,
        'BOTTOMRIGHT', 0, -5, MAINASSIST)
    RaidUtilityMainAssistButton:SetAttribute('type', 'mainassist')
    RaidUtilityMainAssistButton:SetAttribute('unit', 'target')
    RaidUtilityMainAssistButton:SetAttribute('action', 'toggle')

    -- Ready Check button
    CreateButton('RaidUtilityReadyCheckButton', RaidUtilityPanel, 'UIPanelButtonTemplate', (RaidUtilityPanel:GetWidth() * 0.8) * 0.75, 18, 'TOPLEFT', RaidUtilityMainTankButton, 'BOTTOMLEFT', 0, -5, READY_CHECK)
    RaidUtilityReadyCheckButton:SetScript('OnMouseUp', function()
        DoReadyCheck()
    end)

    -- World Marker button
    if Y.IsMainline then
        CompactRaidFrameManagerDisplayFrameLeaderOptionsRaidWorldMarkerButton:ClearAllPoints()
        CompactRaidFrameManagerDisplayFrameLeaderOptionsRaidWorldMarkerButton:SetPoint('TOPRIGHT', RaidUtilityMainAssistButton, 'BOTTOMRIGHT', 0, -5)
        CompactRaidFrameManagerDisplayFrameLeaderOptionsRaidWorldMarkerButton:SetParent(RaidUtilityPanel)
        CompactRaidFrameManagerDisplayFrameLeaderOptionsRaidWorldMarkerButton:SetHeight(18)
        CompactRaidFrameManagerDisplayFrameLeaderOptionsRaidWorldMarkerButton:SetWidth(RaidUtilityRoleButton:GetWidth() * 0.22)
        CompactRaidFrameManagerDisplayFrameLeaderOptionsRaidWorldMarkerButton:StripTextures(true)

        local MarkTexture = CompactRaidFrameManagerDisplayFrameLeaderOptionsRaidWorldMarkerButton:CreateTexture(nil, 'OVERLAY')
        MarkTexture:SetTexture('Interface\\RaidFrame\\Raid-WorldPing')
        MarkTexture:SetPoint('CENTER', 0, -1)
    end

    -- Raid Control Panel
    CreateButton('RaidUtilityRaidControlButton', RaidUtilityPanel, 'UIPanelButtonTemplate', (RaidUtilityPanel:GetWidth() * 0.8), 18, 'TOPLEFT', RaidUtilityReadyCheckButton, 'BOTTOMLEFT', 0, -5, RAID_CONTROL)
    RaidUtilityRaidControlButton:SetScript('OnMouseUp', function()
        if Y.IsCata then
            ToggleFriendsFrame(3)
        else
            ToggleFriendsFrame(4)
        end
    end)

    local function ToggleRaidUtil(self, event)
        if InCombatLockdown() then
            self:RegisterEvent('PLAYER_REGEN_ENABLED')
            return
        end

        if CheckRaidStatus() then
            if RaidUtilityPanel.toggled == true then
                RaidUtilityShowButton:Hide()
                RaidUtilityPanel:Show()
            else
                RaidUtilityShowButton:Show()
                RaidUtilityPanel:Hide()
            end
        else
            RaidUtilityShowButton:Hide()
            RaidUtilityPanel:Hide()
        end

        if event == 'PLAYER_REGEN_ENABLED' then
            self:UnregisterEvent('PLAYER_REGEN_ENABLED')
        end
    end

    -- Automatically show/hide the frame if we have Raid Leader or Raid Officer
    local LeadershipCheck = CreateFrame('Frame')
    LeadershipCheck:RegisterEvent('PLAYER_ENTERING_WORLD')
    LeadershipCheck:RegisterEvent('GROUP_ROSTER_UPDATE')
    LeadershipCheck:SetScript('OnEvent', ToggleRaidUtil)

    -- Support Aurora
    if IsAddOnLoaded('Aurora') then
        local F = unpack(Aurora)
        RaidUtilityPanel:SetBackdropColor(0, 0, 0, 0)
        RaidUtilityPanel:SetBackdropBorderColor(0, 0, 0, 0)
        RaidUtilityPanelInnerBorder:SetBackdropBorderColor(0, 0, 0, 0)
        RaidUtilityPanelOuterBorder:SetBackdropBorderColor(0, 0, 0, 0)
        F.CreateBD(RaidUtilityPanel)
    end
end

Module:Add('misc-raid-tools', true, L['Raid Tools'], L['Button at the top of the screen for ready check (Left-click), checking roles (Middle-click), setting marks, etc. (for leader and assistants)'], function(self, enable)
    if enable then
        load()
    end
end, true)
