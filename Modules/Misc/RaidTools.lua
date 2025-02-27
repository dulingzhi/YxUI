-- 团队工具
local Y, L, A, C, D = YxUIGlobal:get()

local Misc = Y:GetModule('Miscellaneous')
local Module = Y:NewModule('Button.RaidTools')

local next, pairs, mod, select = next, pairs, mod, select
local tinsert, strsplit, format = table.insert, string.split, string.format

local IsInGroup, IsInRaid, IsInInstance = IsInGroup, IsInRaid, IsInInstance
local UnitIsGroupLeader, UnitIsGroupAssistant = UnitIsGroupLeader, UnitIsGroupAssistant
local IsPartyLFG, IsLFGComplete, HasLFGRestrictions = IsPartyLFG, IsLFGComplete, HasLFGRestrictions
local GetInstanceInfo, GetNumGroupMembers, GetRaidRosterInfo, GetRaidTargetIndex, SetRaidTarget = GetInstanceInfo, GetNumGroupMembers, GetRaidRosterInfo, GetRaidTargetIndex, SetRaidTarget
local GetTime, SendChatMessage, IsAddOnLoaded, LoadAddOn = GetTime, SendChatMessage, IsAddOnLoaded or C_AddOns.IsAddOnLoaded, LoadAddOn or C_AddOns.LoadAddOn
local IsAltKeyDown, IsControlKeyDown, IsShiftKeyDown, InCombatLockdown = IsAltKeyDown, IsControlKeyDown, IsShiftKeyDown, InCombatLockdown
local UnitExists, UninviteUnit = UnitExists, UninviteUnit
local DoReadyCheck, InitiateRolePoll, GetReadyCheckStatus = DoReadyCheck, InitiateRolePoll, GetReadyCheckStatus
local LeaveParty = LeaveParty or C_PartyInfo.LeaveParty
local ConvertToRaid = ConvertToRaid or C_PartyInfo.ConvertToRaid
local ConvertToParty = ConvertToParty or C_PartyInfo.ConvertToParty
local GetSpellTexture = GetSpellTexture or C_Spell.GetSpellTexture
local GetSpellCharges = GetSpellCharges or function(...)
    local charges = C_Spell.GetSpellCharges(...)
    if charges then
        return charges.currentCharges, charges.maxCharges, charges.cooldownStartTime, charges.cooldownDuration, charges.chargeModRate
    end
end

Misc:Add('misc-raid-tools', true, L['Raid Tools'], L['Button at the top of the screen for ready check (Left-click), checking roles (Middle-click), setting marks, etc. (for leader and assistants)'], function(self, enable)
    if enable then
        Module:Enable()
    end
end, true)

function Module:Load()
    if C['misc-raid-tools'] then
        self:Enable()
    end
end

function Module:IsFrameOnTop(frame)
    local y = select(2, frame:GetCenter())
    local screenHeight = Y.UIParent:GetTop()
    return y > screenHeight / 2
end

function Module:CreatePanel()
    self:SetSize(120, 22)
    self:SetFrameLevel(2)
    self:SkinButton()
    self:SetPoint('TOP', Y.UIParent, -220, -8)
    Y:CreateMover(self)

    self:UpdateVisibility()
    self:Event('GROUP_ROSTER_UPDATE', self.UpdateVisibility)

    self:RegisterForClicks('AnyUp')
    self:SetScript('OnClick', function(_, button)
        if button == 'LeftButton' then
            Y.TogglePanel(self.menu)
            if self.menu:IsShown() then
                self.menu:ClearAllPoints()
                if self:IsFrameOnTop(self) then
                    self.menu:SetPoint('TOP', self, 'BOTTOM', 0, -6)
                else
                    self.menu:SetPoint('BOTTOM', self, 'TOP', 0, 6)
                end
                self.buttons[2].text:SetText(IsInRaid() and CONVERT_TO_PARTY or CONVERT_TO_RAID)
            end
        end
    end)
    self:SetScript('OnDoubleClick', function(_, btn)
        if btn == 'RightButton' and (IsPartyLFG() and IsLFGComplete() or not IsInInstance()) then
            LeaveParty()
        end
    end)
end

function Module:GetRaidMaxGroup()
    local _, instType, difficulty = GetInstanceInfo()
    if (instType == 'party' or instType == 'scenario') and not IsInRaid() then
        return 1
    elseif instType ~= 'raid' then
        return 8
    elseif difficulty == 8 or difficulty == 1 or difficulty == 2 then
        return 1
    elseif difficulty == 14 or difficulty == 15 or (difficulty == 24 and instType == 'raid') then
        return 6
    elseif difficulty == 16 then
        return 4
    elseif difficulty == 3 or difficulty == 5 then
        return 2
    elseif difficulty == 9 then
        return 8
    else
        return 5
    end
end

function Module:CreateRoleCount()
    local roleIndex = {'TANK', 'HEALER', 'DAMAGER'}
    local frame = CreateFrame('Frame', nil, self)
    frame:SetAllPoints()
    local role = {}
    for i = 1, 3 do
        role[i] = frame:CreateTexture(nil, 'OVERLAY')
        role[i]:SetPoint('LEFT', 36 * i - 27, 0)
        role[i]:SetSize(14, 14)
        Y.ReskinSmallRole(role[i], roleIndex[i])
        role[i].text = Y.CreateFontString(frame, 13, '0', '')
        role[i].text:ClearAllPoints()
        role[i].text:SetPoint('CENTER', role[i], 'RIGHT', 12, 0)
    end

    local raidCounts = {
        totalTANK = 0,
        totalHEALER = 0,
        totalDAMAGER = 0
    }

    local function updateRoleCount()
        for k in pairs(raidCounts) do
            raidCounts[k] = 0
        end

        local maxgroup = self:GetRaidMaxGroup()
        for i = 1, GetNumGroupMembers() do
            local name, _, subgroup, _, _, _, _, online, isDead, _, _, assignedRole = GetRaidRosterInfo(i)
            if name and online and subgroup <= maxgroup and not isDead and assignedRole ~= 'NONE' then
                raidCounts['total' .. assignedRole] = raidCounts['total' .. assignedRole] + 1
            end
        end

        role[1].text:SetText(raidCounts.totalTANK)
        role[2].text:SetText(raidCounts.totalHEALER)
        role[3].text:SetText(raidCounts.totalDAMAGER)
    end

    local eventList = {'GROUP_ROSTER_UPDATE', 'UPDATE_ACTIVE_BATTLEFIELD', 'UNIT_FLAGS', 'PLAYER_FLAGS_CHANGED', 'PLAYER_ENTERING_WORLD'}
    for _, event in next, eventList do
        self:Event(event, updateRoleCount)
    end

    self.roleFrame = frame
end

function Module:UpdateCombatRes(elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed > 0.1 then
        local charges, _, started, duration = GetSpellCharges(20484)

        if charges then
            local timer = duration - (GetTime() - started)
            if timer < 0 then
                self.Timer:SetText('--:--')
            else
                self.Timer:SetFormattedText('%d:%.2d', timer / 60, timer % 60)
            end
            self.Count:SetText(charges)
            if charges == 0 then
                self.Count:SetTextColor(1, 0, 0)
            else
                self.Count:SetTextColor(0, 1, 0)
            end
            self.__owner.resFrame:SetAlpha(1)
            self.__owner.roleFrame:SetAlpha(0)
        else
            self.__owner.resFrame:SetAlpha(0)
            self.__owner.roleFrame:SetAlpha(1)
        end

        self.elapsed = 0
    end
end

function Module:CreateCombatRes()
    local frame = CreateFrame('Frame', nil, self)
    frame:SetAllPoints()
    frame:SetAlpha(0)
    local res = CreateFrame('Frame', nil, frame)
    res:SetSize(22, 22)
    res:SetPoint('LEFT', 5, 0)

    res.Icon = res:CreateTexture(nil, 'ARTWORK')
    res.Icon:SetTexture(GetSpellTexture(20484))
    res.Icon:SetAllPoints()
    res.Icon:SetTexCoord(unpack(Y.TexCoords))
    res.__owner = self

    res.Count = Y.CreateFontString(res, 16, '0', '')
    res.Count:ClearAllPoints()
    res.Count:SetPoint('LEFT', res, 'RIGHT', 10, 0)
    res.Timer = Y.CreateFontString(frame, 16, '00:00', '', false, 'RIGHT', -5, 0)
    res:SetScript('OnUpdate', Module.UpdateCombatRes)

    self.resFrame = frame
end

function Module:CreateReadyCheck()
    local frame = CreateFrame('Frame', nil, self)
    frame:SetPoint('TOP', self, 'BOTTOM', 0, -6)
    frame:SetSize(120, 50)
    frame:Hide()
    frame:SetScript('OnMouseUp', function(self)
        self:Hide()
    end)
    frame:CreateBorder()
    Y.CreateFontString(frame, 14, READY_CHECK, '', true, 'TOP', 0, -8)
    local rc = Y.CreateFontString(frame, 14, '', '', false, 'TOP', 0, -28)

    local count, total
    local function hideRCFrame()
        frame:Hide()
        rc:SetText('')
        count, total = 0, 0
    end

    local function updateReadyCheck(_, event)
        if event == 'READY_CHECK_FINISHED' then
            if count == total then
                rc:SetTextColor(0, 1, 0)
            else
                rc:SetTextColor(1, 0, 0)
            end
            self:Delay(5, hideRCFrame)
        else
            count, total = 0, 0

            frame:ClearAllPoints()
            if Module:IsFrameOnTop(self) then
                frame:SetPoint('TOP', self, 'BOTTOM', 0, -6)
            else
                frame:SetPoint('BOTTOM', self, 'TOP', 0, 6)
            end
            frame:Show()

            local maxgroup = Module:GetRaidMaxGroup()
            for i = 1, GetNumGroupMembers() do
                local name, _, subgroup, _, _, _, _, online = GetRaidRosterInfo(i)
                if name and online and subgroup <= maxgroup then
                    total = total + 1
                    local status = GetReadyCheckStatus(name)
                    if status and status == 'ready' then
                        count = count + 1
                    end
                end
            end
            rc:SetText(count .. ' / ' .. total)
            if count == total then
                rc:SetTextColor(0, 1, 0)
            else
                rc:SetTextColor(1, 1, 0)
            end
        end
    end
    self:Event('READY_CHECK', updateReadyCheck)
    self:Event('READY_CHECK_CONFIRM', updateReadyCheck)
    self:Event('READY_CHECK_FINISHED', updateReadyCheck)
end

function Module:CreateBuffChecker()
    local frame = CreateFrame('Button', nil, self)
    frame:SetPoint('RIGHT', self, 'LEFT', -6, 0)
    frame:SetSize(22, 22)
    frame:SkinButton()

    local icon = frame:CreateTexture(nil, 'ARTWORK')
    icon:SetAllPoints()
    icon:SetTexture('interface/icons/spell_misc_food')

    local BuffName = {L['Flask'], L['Food'], SPELL_STAT4_NAME, RAID_BUFF_2, RAID_BUFF_3, RUNES}
    local NoBuff, numGroups, numPlayer = {}, 6, 0
    for i = 1, numGroups do
        NoBuff[i] = {}
    end

    local debugMode = false
    local function sendMsg(text)
        if debugMode then
            Y:print(text)
        else
            SendChatMessage(text, Y:CheckChat())
        end
    end

    local function sendResult(i)
        local count = #NoBuff[i]
        if count > 0 then
            if count >= numPlayer then
                sendMsg(L['Lack'] .. ' ' .. BuffName[i] .. ': ' .. L['Everyone'])
            elseif count >= 5 and i > 2 then
                sendMsg(L['Lack'] .. ' ' .. BuffName[i] .. ': ' .. format(L['%s players'], count))
            else
                local str = L['Lack'] .. ' ' .. BuffName[i] .. ': '
                for j = 1, count do
                    str = str .. NoBuff[i][j] .. (j < #NoBuff[i] and ', ' or '')
                    if #str > 230 then
                        sendMsg(str)
                        str = ''
                    end
                end
                sendMsg(str)
            end
        end
    end

    local function scanBuff()
        for i = 1, numGroups do
            wipe(NoBuff[i])
        end
        numPlayer = 0

        local maxgroup = Module:GetRaidMaxGroup()
        for i = 1, GetNumGroupMembers() do
            local name, _, subgroup, _, _, _, _, online, isDead = GetRaidRosterInfo(i)
            if name and online and subgroup <= maxgroup and not isDead then
                numPlayer = numPlayer + 1
                for j = 1, numGroups do
                    local HasBuff
                    local buffTable = C.RaidUtilityBuffCheckList[j]
                    for k = 1, #buffTable do
                        local buffName = C_Spell.GetSpellName(buffTable[k])
                        if buffName and C_UnitAuras.GetAuraDataBySpellName(name, buffName) then
                            HasBuff = true
                            break
                        end
                    end
                    if not HasBuff then
                        name = strsplit('-', name) -- remove realm name
                        tinsert(NoBuff[j], name)
                    end
                end
            end
        end
        if not C['Misc'].RMRune then
            NoBuff[numGroups] = {}
        end

        if #NoBuff[1] == 0 and #NoBuff[2] == 0 and #NoBuff[3] == 0 and #NoBuff[4] == 0 and #NoBuff[5] == 0 and #NoBuff[6] == 0 then
            sendMsg(L['All Buffs Ready'])
        else
            sendMsg(L['Raid Buff Checker'])
            for i = 1, 5 do
                sendResult(i)
            end
            if false then
                sendResult(numGroups)
            end
        end
    end

    local potionCheck = IsAddOnLoaded('MRT')

    frame:HookScript('OnEnter', function(self)
        GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMLEFT')
        GameTooltip:ClearLines()
        GameTooltip:AddLine(L['Raid Tool'], 0, 0.6, 1)
        GameTooltip:AddLine(' ')
        GameTooltip:AddDoubleLine(Y.LeftButton .. Y.InfoColor .. L['Check Status'])
        if potionCheck then
            GameTooltip:AddDoubleLine(Y.RightButton .. Y.InfoColor .. L['MRT Potioncheck'])
        end
        GameTooltip:Show()
    end)
    frame:HookScript('OnLeave', Y.HideTooltip)

    local reset = true
    self:Event('PLAYER_REGEN_ENABLED', function()
        reset = true
    end)

    frame:HookScript('OnMouseDown', function(_, btn)
        if btn == 'LeftButton' then
            scanBuff()
        elseif potionCheck then
            SlashCmdList['mrtSlash']('potionchat')
        end
    end)
end

function Module:CreateMenu()
    local frame = CreateFrame('Frame', nil, self)
    frame:SetPoint('TOP', self, 'BOTTOM', 0, -6)
    frame:SetSize(250, 70)
    frame:CreateBorder()
    frame:Hide()

    local function updateDelay(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed > 0.1 then
            if not frame:IsMouseOver() then
                self:Hide()
                self:SetScript('OnUpdate', nil)
            end

            self.elapsed = 0
        end
    end

    frame:SetScript('OnLeave', function(self)
        self:SetScript('OnUpdate', updateDelay)
    end)

    StaticPopupDialogs['Group_Disband'] = {
        text = L['Disband Info'],
        button1 = YES,
        button2 = NO,
        OnAccept = function()
            if InCombatLockdown() then
                UIErrorsFrame:AddMessage(Y.InfoColor .. ERR_NOT_IN_COMBAT)
                return
            end
            if IsInRaid() then
                SendChatMessage(L['Disband Process'], 'RAID')
                for i = 1, GetNumGroupMembers() do
                    local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
                    if online and name ~= Y.UserName then
                        UninviteUnit(name)
                    end
                end
            else
                for i = MAX_PARTY_MEMBERS, 1, -1 do
                    if UnitExists('party' .. i) then
                        UninviteUnit(UnitName('party' .. i))
                    end
                end
            end
            LeaveParty()
        end,
        timeout = 0,
        whileDead = 1
    }

    local buttons = {{TEAM_DISBAND, function()
        if UnitIsGroupLeader('player') then
            StaticPopup_Show('Group_Disband')
        else
            UIErrorsFrame:AddMessage(Y.InfoColor .. ERR_NOT_LEADER)
        end
    end}, {CONVERT_TO_RAID, function()
        if UnitIsGroupLeader('player') and not HasLFGRestrictions() and GetNumGroupMembers() <= 5 then
            if IsInRaid() then
                ConvertToParty()
            else
                ConvertToRaid()
            end
            frame:Hide()
            frame:SetScript('OnUpdate', nil)
        else
            UIErrorsFrame:AddMessage(Y.InfoColor .. ERR_NOT_LEADER)
        end
    end}, {ROLE_POLL, function()
        if IsInGroup() and not HasLFGRestrictions() and (UnitIsGroupLeader('player') or (UnitIsGroupAssistant('player') and IsInRaid())) then
            InitiateRolePoll()
        else
            UIErrorsFrame:AddMessage(Y.InfoColor .. ERR_NOT_LEADER)
        end
    end}, {RAID_CONTROL, function()
        ToggleFriendsFrame(3)
    end}}

    local bu = {}
    for i, j in pairs(buttons) do
        bu[i] = CreateFrame('Button', nil, frame)
        bu[i]:SetSize(116, 26)
        bu[i]:SkinButton()
        bu[i].text = Y.CreateFontString(bu[i], 12, j[1], '', true)
        bu[i]:SetPoint(mod(i, 2) == 0 and 'TOPRIGHT' or 'TOPLEFT', mod(i, 2) == 0 and -6 or 6, i > 2 and -38 or -6)
        bu[i]:SetScript('OnClick', j[2])
    end

    self.menu = frame
    self.buttons = bu
end

function Module:CreateCountDown()
    local frame = CreateFrame('Button', nil, self)
    frame:SetPoint('LEFT', self, 'RIGHT', 6, 0)
    frame:SetSize(22, 22)
    frame:SkinButton()

    local icon = frame:CreateTexture(nil, 'ARTWORK')
    icon:SetAllPoints()
    icon:SetTexture('interface/icons/ui_chat')

    frame:HookScript('OnEnter', function(self)
        GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMLEFT')
        GameTooltip:ClearLines()
        GameTooltip:AddLine('Raid Tool', 0, 0.6, 1)
        GameTooltip:AddLine(' ')
        GameTooltip:AddDoubleLine(Y.LeftButton .. Y.InfoColor .. READY_CHECK)
        GameTooltip:AddDoubleLine(Y.RightButton .. Y.InfoColor .. L['Count Down'])
        GameTooltip:Show()
    end)
    frame:HookScript('OnLeave', Y.HideTooltip)

    local reset = true
    self:Event('PLAYER_REGEN_ENABLED', function()
        reset = true
    end)

    frame:HookScript('OnMouseDown', function(_, btn)
        if btn == 'LeftButton' then
            if InCombatLockdown() then
                UIErrorsFrame:AddMessage(Y.InfoColor .. ERR_NOT_IN_COMBAT)
                return
            end
            if IsInGroup() and (UnitIsGroupLeader('player') or (UnitIsGroupAssistant('player') and IsInRaid())) then
                DoReadyCheck()
            else
                UIErrorsFrame:AddMessage(Y.InfoColor .. ERR_NOT_LEADER)
            end
        else
            if IsInGroup() and (UnitIsGroupLeader('player') or (UnitIsGroupAssistant('player') and IsInRaid())) then
                if IsAddOnLoaded('DBM-Core') then
                    if reset then
                        SlashCmdList['DEADLYBOSSMODS']('pull ' .. '5')
                    else
                        SlashCmdList['DEADLYBOSSMODS']('pull 0')
                    end
                    reset = not reset
                elseif IsAddOnLoaded('BigWigs') then
                    if not SlashCmdList['BIGWIGSPULL'] then
                        LoadAddOn('BigWigs_Plugins')
                    end
                    if reset then
                        SlashCmdList['BIGWIGSPULL']('5')
                    else
                        SlashCmdList['BIGWIGSPULL']('0')
                    end
                    reset = not reset
                else
                    UIErrorsFrame:AddMessage(Y.InfoColor .. L['DBM Required'])
                end
            else
                UIErrorsFrame:AddMessage(Y.InfoColor .. ERR_NOT_LEADER)
            end
        end
    end)
end

function Module:Enable()
    self:CreatePanel()
    self:CreateRoleCount()
    self:CreateCombatRes()
    self:CreateReadyCheck()
    self:CreateBuffChecker()
    self:CreateMenu()
    self:CreateCountDown()
end

function Module:UpdateVisibility()
    if IsInGroup() then
        self:Show()
    else
        self:Hide()
    end
end

