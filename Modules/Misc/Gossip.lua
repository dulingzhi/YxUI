-- NPC对话框快捷键
local Y, L, A, C, D = YxUIGlobal:get()

local Module = Y:GetModule('Miscellaneous')

local function GetOption(index)
    for _, option in ipairs(C_GossipInfo.GetOptions()) do
        if option.orderIndex == index then
            return option
        end
    end
end

local function GossipFrameOnKeyDown(self, key)
    local i = tonumber(key)
    local ignore = true
    if i then
        local option = GetOption(i - 1)
        if option then
            C_GossipInfo.SelectOption(option.gossipOptionID)
            ignore = false
        end
    end
    if not InCombatLockdown() then
        self:SetPropagateKeyboardInput(ignore)
    end
end

if GossipFrame then
    Module:Add('misc-gossip-hotkey', true, L['Gossip Hotkey'], L['Enable hotkey for Gossip Frame'], function(self, enable)
        if enable then
            GossipFrame:SetScript('OnKeyDown', GossipFrameOnKeyDown)
        else
            GossipFrame:SetScript('OnKeyDown', nil)
        end
    end)
end
