local Y, L, A, C, D = YxUIGlobal:get()

local function skin(self)
    self.fixedWidth = self.fixedWidth - 22
    self.fixedHeight = self.fixedHeight - 15

    Y.SkinFrame(self, true)

    do
        self.OwnerSelector:CreateBorder()
        self.OwnerSelector:StyleButton()
        self.OwnerSelector:SetSize(20, 20)
        self.OwnerSelector:SetPoint('TOPLEFT', 2, -2)
        local icon = self.OwnerSelector:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        hooksecurefunc(self.OwnerSelector, "UpdateIcon", function()
            icon:SetTexture(self.portrait:GetTexture())
            icon:SetTexCoord(self.portrait:GetTexCoord())
        end)
    end

    self.TitleFrame:ClearAllPoints()
    self.TitleFrame:SetPoint('LEFT', self.OwnerSelector, 'RIGHT', 2, 0)
    self.TitleFrame:SetPoint('RIGHT', self.CloseButton, 'LEFT', -2, 0)

    self.BagFrame:SetPoint('TOPLEFT', 2, -29)
    hooksecurefunc(self.BagFrame, 'Update', function()
        for _, button in ipairs({ self.BagFrame:GetChildren() }) do
            local obj = button.Icon or button:GetNormalTexture()
            local tex = obj and obj:GetTexture()
            button:CreateBorder()
            button:StyleButton()
            local icon = button:CreateTexture(nil, "ARTWORK")
            icon:SetPoint('CENTER')
            icon:SetTexture(tex)
            icon:SetSize(button:GetWidth() - 4, button:GetHeight() - 4)
            if button.Icon then
                button.Icon:SetAlpha(0)
                icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
                hooksecurefunc(button, 'Update', function()
                    button.Icon:SetAlpha(0)
                    icon:SetTexture(button.Icon:GetTexture())
                end)
            else
                icon:SetTexCoord(0.1, 0.479375, 0.1, 0.5025)
            end
        end
    end)

    -- T.SkinEditBox(self.SearchBox)
    self.SearchBox:SetHeight(20)

    hooksecurefunc(self, 'PlaceSearchBox', function()
        if self.SearchBox:IsShown() then
            if self.PluginFrame:IsShown() then
                self.SearchBox:SetPoint('RIGHT', self.PluginFrame, 'LEFT', -4, 0)
            else
                self.SearchBox:SetPoint('RIGHT', self, 'TOPRIGHT', -20, -33)
            end

            if self.BagFrame:IsShown() then
                self.SearchBox:SetPoint('LEFT', self.BagFrame, 'RIGHT', 5, -1)
            else
                self.SearchBox:SetPoint('LEFT', self, 'TOPLEFT', 4, -43)
            end
        end
    end)

    self.PluginFrame:SetPoint('TOPRIGHT', -2, -31)
    self.PluginFrame.SPACING = 4
    hooksecurefunc(self.PluginFrame, 'CreatePluginButton', function(f, plugin)
        local button = f.pluginButtons[plugin.key]
        button:CreateBorder()
        button:StyleButton(false, false, true)
        button:SetNormalTexture(0)
        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetTexture(plugin.icon)
    end)

    self.Inset:SetPoint('TOPLEFT', 2, -60)
    self.Inset:SetPoint('BOTTOMRIGHT', -2, 25)
    self.Container:SetPoint('TOPLEFT', self.Inset, 'TOPLEFT', 0, 0)

    local function skinbg(f)
        f.BgLeft:SetAlpha(0)
        f.BgMiddle:SetAlpha(0)
        f.BgRight:SetAlpha(0)
        if f.LeftSeparator then
            f.LeftSeparator:SetAlpha(0)
        end
    end

    skinbg(self.MoneyFrame)
    self.MoneyFrame:SetPoint('BOTTOMRIGHT', -2, 1)
    skinbg(self.TokenFrame)
    self.TokenFrame:SetPoint('BOTTOMLEFT', 2, 1)
end

local function SetupUi()
    hooksecurefunc(_G.tdBag2, "CreateFrame", function(self, bagId)
        if bagId == "bag" or bagId == "bank" then
            skin(self.frames[bagId])
        end
    end)
end

Y.Skin:Add("tdBag2", SetupUi)
