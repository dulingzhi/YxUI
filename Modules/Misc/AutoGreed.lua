-- 满级自动贪婪绿装、自动需求指定物品
local Y, L, A, C, D = YxUIGlobal:get()

local Module = Y:GetModule('Miscellaneous')

local C_Item_GetItemInfo = C_Item.GetItemInfo
local GetLootRollItemInfo = GetLootRollItemInfo
local GetLootRollItemLink = GetLootRollItemLink
local RollOnLoot = RollOnLoot
local NeedItems = {
    ['冰冻宝珠'] = true
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

Module:Add('misc-auto-greed', true, L['Enable Auto Greed'], L['Auto greed green items'], function(self, enable)
    if enable and Y.IsMaxLevel then
        self:Event('START_LOOT_ROLL', SetupAutoGreed)
    else
        self:UnEvent('START_LOOT_ROLL', SetupAutoGreed)
    end
end)
