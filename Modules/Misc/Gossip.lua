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

local ICON = {
    [132050] = true, -- 银行
    [132057] = true, -- 鸟点
    [132058] = true, -- 专业技能
    [132060] = true, -- 商店
    [528409] = true -- 拍卖行
}
local function FindChoice(options)
    if #options <= 1 then
        return options[1]
    end
    for _, opt in ipairs(options) do
        if opt.name == 'battlemaster' or ICON[opt.icon] then
            return opt
        end
    end
end

local function GossipOnShow(self)
    if not IsShiftKeyDown() and #C_GossipInfo.GetActiveQuests() == 0 and #C_GossipInfo.GetAvailableQuests() == 0 then
        local opt = FindChoice(C_GossipInfo.GetOptions())
        if opt then
            C_GossipInfo.SelectOption(opt.gossipOptionID)
        end
    end
end

if GossipFrame then
    Module:Add('misc-gossip-autoit', true, L['Gossip AutoIt'], L['Enable AutoIt for Gossip Frame'], function(self, enable)
        if enable then
            GossipFrame:SetScript('OnKeyDown', GossipFrameOnKeyDown)
            self:Event('GOSSIP_SHOW', GossipOnShow)
        else
            GossipFrame:SetScript('OnKeyDown', nil)
            self:UnEvent('GOSSIP_SHOW', GossipOnShow)
        end
    end)
end
