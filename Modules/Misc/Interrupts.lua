-- 打断提示
local Y, L, A, C, D = YxUIGlobal:get()

local Module = Y:GetModule('Miscellaneous')

local GetSpellLink = GetSpellLink or C_Spell.GetSpellLink
local RaidIconMaskToIndex = {
    [COMBATLOG_OBJECT_RAIDTARGET1] = 1,
    [COMBATLOG_OBJECT_RAIDTARGET2] = 2,
    [COMBATLOG_OBJECT_RAIDTARGET3] = 3,
    [COMBATLOG_OBJECT_RAIDTARGET4] = 4,
    [COMBATLOG_OBJECT_RAIDTARGET5] = 5,
    [COMBATLOG_OBJECT_RAIDTARGET6] = 6,
    [COMBATLOG_OBJECT_RAIDTARGET7] = 7,
    [COMBATLOG_OBJECT_RAIDTARGET8] = 8
}

local function GetRaidIcon(unitFlags)
    local raidTarget = bit.band(unitFlags, COMBATLOG_OBJECT_RAIDTARGET_MASK)
    if raidTarget == 0 then
        return ''
    end

    return '{rt' .. RaidIconMaskToIndex[raidTarget] .. '}'
end

local function COMBAT_LOG_EVENT_UNFILTERED()
    if not IsInGroup() then
        return
    end
    local _, event, _, sourceGUID, _, _, _, _, destName, _, destRaidFlags, _, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    if not (event == 'SPELL_INTERRUPT' and sourceGUID == UnitGUID('player')) then
        return
    end

    local destIcon = ''
    if destName then
        destIcon = GetRaidIcon(destRaidFlags)
    end

    if Y.IsClassic then
        SendChatMessage('[' .. Y.AddOnName .. '] ' .. L['Interrupted'] .. ' ' .. destIcon .. destName .. ': ' .. spellName, Y:CheckChat())
    else
        SendChatMessage('[' .. Y.AddOnName .. '] ' .. L['Interrupted'] .. ' ' .. destIcon .. destName .. ': ' .. GetSpellLink(spellID), Y:CheckChat())
    end
end

Module:Add('misc-interrupts-announce', true, L['Enable Interrupts Announce'], L['Announce interrupts spell'], function(self, enable)
    if enable then
        self:Event('COMBAT_LOG_EVENT_UNFILTERED', COMBAT_LOG_EVENT_UNFILTERED)
    else
        self:UnEvent('COMBAT_LOG_EVENT_UNFILTERED', COMBAT_LOG_EVENT_UNFILTERED)
    end
end)
