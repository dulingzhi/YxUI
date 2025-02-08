-- 团队工具
local Y, L, A, C, D = YxUIGlobal:get()

local Module = Y:GetModule('Miscellaneous')

----------------------------------------------------------------------------------------
--	Disband party or raid(by Monolit)
----------------------------------------------------------------------------------------
local function DisbandRaidGroup()
    if InCombatLockdown() then
        return
    end
    if UnitInRaid('player') then
        SendChatMessage(L['Disbanding group...'], 'RAID')
        for i = 1, GetNumGroupMembers() do
            local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
            if online and name ~= Y.UserName then
                UninviteUnit(name)
            end
        end
    else
        SendChatMessage(L['Disbanding group...'], 'PARTY')
        for i = MAX_PARTY_MEMBERS, 1, -1 do
            local token = 'party' .. i
            if UnitExists(token) then
                UninviteUnit(UnitName(token))
            end
        end
    end
    if not Y.IsMainline then
        LeaveParty()
    else
        C_PartyInfo.LeaveParty()
    end
end

StaticPopupDialogs.DISBAND_RAID = {
    text = L['Are you sure you want to disband the group?'],
    button1 = ACCEPT,
    button2 = CANCEL,
    OnAccept = DisbandRaidGroup,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = true,
    preferredIndex = 5
}

SlashCmdList.GROUPDISBAND = function()
    StaticPopup_Show('DISBAND_RAID')
end
SLASH_GROUPDISBAND1 = '/rd'

local function load()
    ----------------------------------------------------------------------------------------
    --	Raid Utility(by Elv22)
    ----------------------------------------------------------------------------------------
    -- Create main frame
    local RaidUtilityPanel = CreateFrame('Frame', 'YxUIRaidUtilityPanel', Y.UIParent)
    RaidUtilityPanel:SetSize(170, 145)
    RaidUtilityPanel:CreateBorder()
    if GetCVarBool('watchFrameWidth') then
        RaidUtilityPanel:SetPoint('TOP', Y.UIParent, 'TOP', -180, -2)
    else
        RaidUtilityPanel:SetPoint('TOP', Y.UIParent, 'TOP', -280, -2)
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

    -- Buttons
    local ButtonOnEnter = function(self)
        self.Highlight:SetAlpha(0.25)
    end

    local ButtonOnLeave = function(self)
        self.Highlight:SetAlpha(0)
    end

    -- Function to create buttons in this module
    local function CreateButton(parent, template, width, height, point, relativeto, point2, xOfs, yOfs, text)
        local b = CreateFrame('Button', nil, parent, template)
        b:SetWidth(width)
        b:SetHeight(height)
        b:SetPoint(point, relativeto, point2, xOfs, yOfs)
        b:CreateBorder()
        b:SetScript('OnEnter', ButtonOnEnter)
        b:SetScript('OnLeave', ButtonOnLeave)
        b.Highlight = b:CreateTexture(nil, 'OVERLAY')
        b.Highlight:SetAllPoints()
        b.Highlight:SetTexture(A:GetTexture(C['ui-widget-texture']))
        b.Highlight:SetVertexColor(123 / 255, 132 / 255, 137 / 255)
        b.Highlight:SetAlpha(0)
        if text then
            b.t = b:CreateFontString(nil, 'OVERLAY')
            b.t:SetFont(A:GetFont(C['ui-button-font']), C['ui-font-size'], '')
            b.t:SetPoint('CENTER')
            b.t:SetJustifyH('CENTER')
            b.t:SetText(text)
            b.t:SetWidth(width - 2)
        end
        return b
    end

    -- Show button
    local RaidUtilityShowButton = CreateButton(Y.UIParent, 'SecureHandlerClickTemplate', RaidUtilityPanel:GetWidth() / 1.5, 18, 'TOP', RaidUtilityPanel, 'TOP', 0, 0, RAID_CONTROL)
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
    local RaidUtilityCloseButton = CreateButton(RaidUtilityPanel, 'SecureHandlerClickTemplate', RaidUtilityPanel:GetWidth() / 1.5, 18, 'TOP', RaidUtilityPanel, 'BOTTOM', 0, -4, CLOSE)
    RaidUtilityCloseButton:SetFrameRef('RaidUtilityShowButton', RaidUtilityShowButton)
    RaidUtilityCloseButton:SetAttribute('_onclick', [=[self:GetParent():Hide(); self:GetFrameRef("RaidUtilityShowButton"):Show();]=])
    RaidUtilityCloseButton:SetScript('OnMouseUp', function()
        RaidUtilityPanel.toggled = false
    end)

    -- Disband Group button
    local RaidUtilityDisbandButton = CreateButton(RaidUtilityPanel, nil, RaidUtilityPanel:GetWidth() * 0.8, 18, 'TOP', RaidUtilityPanel, 'TOP', 0, -5, L['Disband Group'])
    RaidUtilityDisbandButton:SetScript('OnMouseUp', function()
        StaticPopup_Show('DISBAND_RAID')
    end)

    -- Convert Group button
    local RaidUtilityConvertButton = CreateButton(RaidUtilityPanel, nil, RaidUtilityPanel:GetWidth() * 0.8, 18, 'TOP', RaidUtilityDisbandButton, 'BOTTOM', 0, -5, UnitInRaid('player') and CONVERT_TO_PARTY or CONVERT_TO_RAID)
    RaidUtilityConvertButton:SetScript('OnMouseUp', function()
        if UnitInRaid('player') then
            if not Y.IsMainline then
                ConvertToParty()
            else
                C_PartyInfo.ConvertToParty()
            end
            RaidUtilityConvertb.t:SetText(CONVERT_TO_RAID)
        elseif UnitInParty('player') then
            if not Y.IsMainline then
                ConvertToRaid()
            else
                C_PartyInfo.ConvertToRaid()
            end
            RaidUtilityConvertb.t:SetText(CONVERT_TO_PARTY)
        end
    end)

    -- Role Check button
    local RaidUtilityRoleButton
    if Y.IsMainline then
        RaidUtilityRoleButton = CreateButton(RaidUtilityPanel, nil, RaidUtilityPanel:GetWidth() * 0.8, 18, 'TOP', RaidUtilityConvertButton, 'BOTTOM', 0, -5, ROLE_POLL)
        RaidUtilityRoleButton:SetScript('OnMouseUp', function()
            InitiateRolePoll()
        end)
    else
        RaidUtilityPanel:SetHeight(RaidUtilityPanel:GetHeight() - 23)
    end

    -- MainTank button
    local RaidUtilityMainTankButton = CreateButton(RaidUtilityPanel, 'SecureActionButtonTemplate', (RaidUtilityDisbandButton:GetWidth() / 2) - 2, 18, 'TOPLEFT', RaidUtilityRoleButton or RaidUtilityConvertButton, 'BOTTOMLEFT', 0, -5, TANK)
    RaidUtilityMainTankButton:SetAttribute('type', 'maintank')
    RaidUtilityMainTankButton:SetAttribute('unit', 'target')
    RaidUtilityMainTankButton:SetAttribute('action', 'toggle')

    -- MainAssist button
    local RaidUtilityMainAssistButton = CreateButton(RaidUtilityPanel, 'SecureActionButtonTemplate', (RaidUtilityDisbandButton:GetWidth() / 2) - 2, 18, 'TOPRIGHT', RaidUtilityRoleButton or RaidUtilityConvertButton, 'BOTTOMRIGHT', 0, -5,
        MAINASSIST)
    RaidUtilityMainAssistButton:SetAttribute('type', 'mainassist')
    RaidUtilityMainAssistButton:SetAttribute('unit', 'target')
    RaidUtilityMainAssistButton:SetAttribute('action', 'toggle')

    -- Ready Check button
    local RaidUtilityReadyCheckButton = CreateButton(RaidUtilityPanel, nil, (RaidUtilityPanel:GetWidth() * 0.8) * (CompactRaidFrameManagerDisplayFrameLeaderOptionsRaidWorldMarkerButton and 0.75 or 1), 18, 'TOPLEFT',
        RaidUtilityMainTankButton, 'BOTTOMLEFT', 0, -5, READY_CHECK)
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
    local RaidUtilityRaidControlButton = CreateButton(RaidUtilityPanel, nil, (RaidUtilityPanel:GetWidth() * 0.8), 18, 'TOPLEFT', RaidUtilityReadyCheckButton, 'BOTTOMLEFT', 0, -5, RAID_CONTROL)
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

    ToggleRaidUtil(LeadershipCheck)
end

Module:Add('misc-raid-tools', true, L['Raid Tools'], L['Button at the top of the screen for ready check (Left-click), checking roles (Middle-click), setting marks, etc. (for leader and assistants)'], function(self, enable)
    if enable then
        load()
    end
end, true)
