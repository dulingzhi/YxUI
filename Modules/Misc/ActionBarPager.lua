-- 主动作跳ESC返回第一页 by tdUI
local Y, L, A, C, D = YxUIGlobal:get()

local Module = Y:GetModule('Miscellaneous')

Module:Add('misc-ab-pager', true, L['Actionbar Quickly to Page 1'], L['Press ESC Actionbar to Page 1'], function(self, enable)
    if enable then
        if not self.ReturnPageButton then
            self.ReturnPageButton = CreateFrame('Frame', 'YxUIReturnPageButton', Y.UIParent, 'SecureHandlerStateTemplate')

            self.ReturnPageButton:SetAttribute('_onstate-usable', [[
if newstate == 1 then
self:SetBinding(true, 'Escape', 'ACTIONPAGE1')
else
self:ClearBindings()
end
]])
            RegisterStateDriver(self.ReturnPageButton, 'usable', '[noactionbar:1]1;0')
        end
        self.ReturnPageButton:Show()
    elseif self.ReturnPageButton then
        self.ReturnPageButton:Hide()
    end
end)
