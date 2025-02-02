local Y, L, A, C, D = YxUIGlobal:get()

local Module = Y:NewModule("Miscellaneous")

D["misc-auto-greed"] = true

local C_Item_GetItemInfo = C_Item.GetItemInfo
local GetLootRollItemInfo = GetLootRollItemInfo
local GetLootRollItemLink = GetLootRollItemLink
local RollOnLoot = RollOnLoot

local function SetupAutoGreed(_, _, id)
    local _, _, _, quality, BoP, _, _, canDisenchant = GetLootRollItemInfo(id)
    if id and quality == 2 and not BoP then
        local link = GetLootRollItemLink(id)
        local _, _, _, ilevel = C_Item_GetItemInfo(link)
        if canDisenchant and ilevel > 270 then
            RollOnLoot(id, 3)
        else
            RollOnLoot(id, 2)
        end
    end
end

function Module:AutoGreed()
    if C["misc-auto-greed"] and Y.UserLevel == GetMaxLevelForExpansionLevel(GetExpansionLevel()) then
        self:Event("START_LOOT_ROLL", SetupAutoGreed)
    else
        self:UnEvent("START_LOOT_ROLL", SetupAutoGreed)
    end
end

function Module:Load()
    self:AutoGreed()
end

Y:GetModule("GUI"):AddWidgets(L["General"], L["Miscellaneous"], function(left, right)
	left:CreateHeader(L["Loot"])
	left:CreateSwitch("misc-auto-greed", C["misc-auto-greed"], L["Enable Auto Greed"], L["Auto greed green items"], function()
        Module:AutoGreed()
    end)
end)
