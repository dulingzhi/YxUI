local Y, L, A, C, D = YxUIGlobal:get()

local Module = Y:NewModule("Miscellaneous")

D["misc-auto-greed"] = true
D["misc-interrupts-announce"] = true
D["misc-auto-confirm"] = true

function Module:Load()
    self:AutoGreed()
    self:Interrupts()
    self:AutoConfirm()
end

Y:GetModule("GUI"):AddWidgets(L["General"], L["Miscellaneous"], function(left, right)
    left:CreateHeader(L["Miscellaneous"])
    left:CreateSwitch("misc-auto-greed", C["misc-auto-greed"], L["Enable Auto Greed"], L["Auto greed green items"], function()
        Module:AutoGreed()
    end)
    left:CreateSwitch("misc-interrupts-announce", C["misc-interrupts-announce"], L["Enable Interrupts Announce"], L["Announce interrupts spell"], function()
        Module:Interrupts()
    end)
    left:CreateSwitch("misc-auto-confirm", C["misc-auto-confirm"], L["Auto Confirm Loot Bind"], L["Auto confirm loot/roll binds"], function()
        Module:AutoConfirm()
    end)
end)

----------------------------------------------------------------------------------------
--- Auto greed green items
local C_Item_GetItemInfo = C_Item.GetItemInfo
local GetLootRollItemInfo = GetLootRollItemInfo
local GetLootRollItemLink = GetLootRollItemLink
local RollOnLoot = RollOnLoot
local NeedItems = {
    ['冰冻宝珠'] = true,
}

local function SetupAutoGreed(_, _, id)
    local _, name, _, quality, BoP, _, _, canDisenchant = GetLootRollItemInfo(id)
    if id then
        if quality == 2 and not BoP then
            local link = GetLootRollItemLink(id)
            local _, _, _, ilevel = C_Item_GetItemInfo(link)
            if canDisenchant and ilevel > 270 then
                RollOnLoot(id, 3)
            else
                RollOnLoot(id, 2)
            end
        elseif NeedItems[name] then
            RollOnLoot(id, 1)
        end
    end
end

function Module:AutoGreed()
    if C["misc-auto-greed"] and Y.IsMaxLevel then
        self:Event("START_LOOT_ROLL", SetupAutoGreed)
    else
        self:UnEvent("START_LOOT_ROLL", SetupAutoGreed)
    end
end

----------------------------------------------------------------------------------------
--- Interrupts announce
local GetSpellLink = GetSpellLink or C_Spell.GetSpellLink
local RaidIconMaskToIndex = {
    [COMBATLOG_OBJECT_RAIDTARGET1] = 1,
    [COMBATLOG_OBJECT_RAIDTARGET2] = 2,
    [COMBATLOG_OBJECT_RAIDTARGET3] = 3,
    [COMBATLOG_OBJECT_RAIDTARGET4] = 4,
    [COMBATLOG_OBJECT_RAIDTARGET5] = 5,
    [COMBATLOG_OBJECT_RAIDTARGET6] = 6,
    [COMBATLOG_OBJECT_RAIDTARGET7] = 7,
    [COMBATLOG_OBJECT_RAIDTARGET8] = 8,
}

local function GetRaidIcon(unitFlags)
    local raidTarget = bit.band(unitFlags, COMBATLOG_OBJECT_RAIDTARGET_MASK)
    if raidTarget == 0 then
        return ""
    end

    return "{rt" .. RaidIconMaskToIndex[raidTarget] .. "}"
end

local function COMBAT_LOG_EVENT_UNFILTERED()
    if not IsInGroup() then return end
    local _, event, _, sourceGUID, _, _, _, _, destName, _, destRaidFlags, _, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
    if not (event == "SPELL_INTERRUPT" and sourceGUID == UnitGUID("player")) then return end

    local destIcon = ""
    if destName then
        destIcon = GetRaidIcon(destRaidFlags)
    end

    if Y.IsClassic then
        SendChatMessage("[" .. Y.AddOnName .. "] " .. L["Interrupted"] .. " " .. destIcon .. destName .. ": " .. spellName, Y:CheckChat())
    else
        SendChatMessage("[" .. Y.AddOnName .. "] " .. L["Interrupted"] .. " " .. destIcon .. destName .. ": " .. GetSpellLink(spellID), Y:CheckChat())
    end
end

function Module:Interrupts()
    if C["misc-interrupts-announce"] then
        self:Event("COMBAT_LOG_EVENT_UNFILTERED", COMBAT_LOG_EVENT_UNFILTERED)
    else
        self:UnEvent("COMBAT_LOG_EVENT_UNFILTERED", COMBAT_LOG_EVENT_UNFILTERED)
    end
end

----------------------------------------------------------------------------------------
--	Disenchant confirmation(tekKrush by Tekkub)
----------------------------------------------------------------------------------------
local function AutoConfirm()
    for i = 1, STATICPOPUP_NUMDIALOGS do
        local frame = _G["StaticPopup" .. i]
        if (frame.which == "CONFIRM_LOOT_ROLL" or frame.which == "LOOT_BIND") and frame:IsVisible() then
            StaticPopup_OnClick(frame, 1)
        end
    end
end

function Module:AutoConfirm()
    if C["misc-auto-confirm"] then
        if Y.IsMainline then
            self:Event("CONFIRM_DISENCHANT_ROLL", AutoConfirm)
        end
        self:Event("CONFIRM_LOOT_ROLL", AutoConfirm)
        self:Event("LOOT_BIND_CONFIRM", AutoConfirm)
    else
        if Y.IsMainline then
            self:UnEvent("CONFIRM_DISENCHANT_ROLL", AutoConfirm)
        end
        self:UnEvent("CONFIRM_LOOT_ROLL", AutoConfirm)
        self:UnEvent("LOOT_BIND_CONFIRM", AutoConfirm)
    end
end
