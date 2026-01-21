local Y, L, A, C, D = select(2, ...):get()

D["fast-loot"] = true
D["loot-hide-on-click"] = false

local Loot = Y:NewModule("Loot")

local GetCVar = GetCVar
local IsModifiedClick = IsModifiedClick
local GetLootMethod = GetLootMethod
local GetNumLootItems = GetNumLootItems
local GetLootThreshold = GetLootThreshold
local GetLootSlotInfo = GetLootSlotInfo
local LootSlot = LootSlot

local Icon, Name, Quantity, CurrencyID, Quality, Locked, QuestItem, QuestID, IsActive
local Quality, Locked, Threshold, _

Loot.LootSlots = {}
Loot.Grouped = false

if C_PartyInfo and C_PartyInfo.GetLootMethod then
    GetLootMethod = C_PartyInfo.GetLootMethod
end

function Loot:LOOT_READY()
    if (GetCVar("autoLootDefault") == "1" and not IsModifiedClick("AUTOLOOTTOGGLE")) or (GetCVar("autoLootDefault") ~= "1" and IsModifiedClick("AUTOLOOTTOGGLE")) then
        if GetLootMethod() == "master" then
            return
        end

        if IsInGroup() and GetLootMethod() == "master" then
            self.Grouped = true
        end

        for i = GetNumLootItems(), 1, -1 do
            _, _, _, _, Quality, Locked = GetLootSlotInfo(i)
            Threshold = GetLootThreshold()

            if Locked ~= nil and not Locked then
                if self.Grouped and Quality < Threshold then
                    self.LootSlots[#self.LootSlots + 1] = i
                end
            end
        end
        if not self.lootTimer and #self.LootSlots > 0 then
            self.lootTimer = C_Timer.NewTicker(0.033, function()
                self:OnUpdate()
            end)
        end
    end
end

function Loot:OnUpdate()
    if #self.LootSlots == 0 then
        if self.lootTimer then
            self.lootTimer:Cancel()
            self.lootTimer = nil
        end
        return
    end

    for i = 1, #self.LootSlots do
        LootSlot(self.LootSlots[i])
    end

    if GetNumLootItems() == 0 then
        if self.lootTimer then
            self.lootTimer:Cancel()
            self.lootTimer = nil
        end

        for i = #self.LootSlots, 1, -1 do
            table.remove(self.LootSlots, i)
        end

        self.Grouped = false

        CloseLoot()
    end
end

function Loot:OnEvent(event, ...)
    self[event](self)
end

function Loot:Load()
    if not C["fast-loot"] then
        return
    end

    self:RegisterEvent("LOOT_READY")
    self:SetScript("OnEvent", self.OnEvent)
end

local UpdateFastLoot = function(value)
    if value then
        Loot:RegisterEvent("LOOT_READY")
        Loot:SetScript("OnEvent", Loot.OnEvent)
    else
        Loot:UnregisterEvent("LOOT_READY")
        Loot:SetScript("OnEvent", nil)
    end
end

Y:GetModule("GUI"):AddWidgets(L["General"], L["General"], function(left, right)
    right:CreateHeader(L["Loot"])
    right:CreateSwitch("fast-loot", C["fast-loot"], L["Enable Fast Loot"], L["Speed up auto looting"], UpdateFastLoot)
    right:CreateSwitch("loot-hide-on-click", C["loot-hide-on-click"], L["Enable Hide Loot When Click"], L["Close the loot window when you click on an item to loot it."])
end)
