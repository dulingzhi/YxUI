-- Disenchant confirmation(tekKrush by Tekkub)
local Y, L, A, C, D = YxUIGlobal:get()

local Module = Y:GetModule('Miscellaneous')
local STATICPOPUP_NUMDIALOGS = STATICPOPUP_NUMDIALOGS or 4

local function AutoConfirm()
    for i = 1, STATICPOPUP_NUMDIALOGS do
        local frame = _G['StaticPopup' .. i]
        if (frame.which == 'CONFIRM_LOOT_ROLL' or frame.which == 'LOOT_BIND') and frame:IsVisible() then
            StaticPopup_OnClick(frame, 1)
        end
    end
end

Module:Add('misc-auto-confirm', true, L['Auto Confirm Loot Bind'], L['Auto confirm loot/roll binds'], function(self, enable)
    if enable then
        if Y.IsMainline then
            self:Event('CONFIRM_DISENCHANT_ROLL', AutoConfirm)
        end
        self:Event('CONFIRM_LOOT_ROLL', AutoConfirm)
        self:Event('LOOT_BIND_CONFIRM', AutoConfirm)
        ----------------------------------------------------------------------------------------
        --	Easy delete good items
        ----------------------------------------------------------------------------------------
        local deleteDialog = StaticPopupDialogs['DELETE_GOOD_ITEM']
        if deleteDialog.OnShow then
            hooksecurefunc(deleteDialog, 'OnShow', function(s)
                s.editBox:SetText(DELETE_ITEM_CONFIRM_STRING)
                s.editBox:SetAutoFocus(false)
                s.editBox:ClearFocus()
            end)
        end
    else
        if Y.IsMainline then
            self:UnEvent('CONFIRM_DISENCHANT_ROLL', AutoConfirm)
        end
        self:UnEvent('CONFIRM_LOOT_ROLL', AutoConfirm)
        self:UnEvent('LOOT_BIND_CONFIRM', AutoConfirm)
    end
end)
