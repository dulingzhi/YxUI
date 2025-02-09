local Y, L, A, C, D = YxUIGlobal:get()

local Module = Y:GetModule('Blizzard')

Module:Add('StaticPopup', function()

    -- Helper function to skin popup buttons
    local function SkinPopupButtons(popup)
        for j = 1, 4 do
            local button = _G[popup .. 'Button' .. j]
            if button then
                button:SkinButton()
            end
        end
    end

    -- Helper function to skin popup edit boxes
    local function SkinPopupEditBoxes(popup)
        local editBox = _G[popup .. 'EditBox']
        if editBox then
            editBox:SkinEditBox()
            editBox.YxUIBackground:SetPoint('TOPLEFT', -3, -6)
            editBox.YxUIBackground:SetPoint('BOTTOMRIGHT', -3, 6)
        end

        local goldBox = _G[popup .. 'MoneyInputFrameGold']
        local silverBox = _G[popup .. 'MoneyInputFrameSilver']
        local copperBox = _G[popup .. 'MoneyInputFrameCopper']

        if goldBox then
            goldBox:SkinEditBox()
            goldBox.YxUIBackground:SetPoint('TOPLEFT', -3, 0)
        end
        if silverBox then
            silverBox:SkinEditBox()
            silverBox.YxUIBackground:SetPoint('TOPLEFT', -3, 0)
        end
        if copperBox then
            copperBox:SkinEditBox()
            copperBox.YxUIBackground:SetPoint('TOPLEFT', -3, 0)
        end
    end

    -- Helper function to skin popup item frame
    local function SkinPopupItemFrame(popup)
        local itemFrame = _G[popup .. 'ItemFrame']
        if itemFrame then
            _G[popup .. 'ItemFrameNameFrame']:Kill()
            itemFrame:GetNormalTexture():Kill()
            itemFrame:CreateBorder()
            itemFrame:StyleButton()
            itemFrame.IconBorder:SetAlpha(0)

            local iconTexture = itemFrame.IconTexture
            if iconTexture then -- Check if iconTexture exists
                iconTexture:SetTexCoord(0.1, 0.9, 0.1, 0.9)
                iconTexture:ClearAllPoints()
                iconTexture:SetPoint('TOPLEFT', 2, -2)
                iconTexture:SetPoint('BOTTOMRIGHT', -2, 2)
            end
        end
    end

    -- Skin StaticPopup frames
    for i = 1, 4 do
        local popup = 'StaticPopup' .. i
        SkinPopupButtons(popup)

        local frame = _G[popup]
        frame:StripTextures()
        if frame.Border then
            frame.Border:StripTextures()
        end
        frame:CreateBackdrop()
        frame.YxUIBackground:SetPoint('TOPLEFT', 2, -2)
        frame.YxUIBackground:SetPoint('BOTTOMRIGHT', -2, 2)

        SkinPopupEditBoxes(popup)
        SkinPopupItemFrame(popup)

        local closeButton = _G[popup .. 'CloseButton']
        closeButton:SetNormalTexture(0)
        closeButton.SetNormalTexture = Y.Dummy
        closeButton:SetPushedTexture(0)
        closeButton.SetPushedTexture = Y.Dummy
        closeButton:SkinCloseButton()
    end

    -- Skin the extra button on StaticPopup1
    _G['StaticPopup1ExtraButton']:SkinButton()
end)
