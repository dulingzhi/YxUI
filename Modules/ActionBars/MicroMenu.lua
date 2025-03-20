local YxUI, Language, Assets, Settings, Defaults = select(2, ...):get()

local MicroButtons = YxUI:NewModule("Micro Buttons")

if YxUI.IsMainline then
    MicroButtons.Buttons = {
        CharacterMicroButton,
        ProfessionMicroButton,
        PlayerSpellsMicroButton,
        AchievementMicroButton,
        QuestLogMicroButton,
        GuildMicroButton,
        LFDMicroButton,
        CollectionsMicroButton,
        EJMicroButton,
        StoreMicroButton,
        MainMenuMicroButton,
    }
elseif YxUI.IsTBC then
    MicroButtons.Buttons = {
        CharacterMicroButton,
        SpellbookMicroButton,
        TalentMicroButton,
        AchievementMicroButton,
        QuestLogMicroButton,
        SocialsMicroButton,
        LFGMicroButton,
        MainMenuMicroButton,
        HelpMicroButton,
    }
elseif YxUI.IsWrath then
    MicroButtons.Buttons = {
        CharacterMicroButton,
        SpellbookMicroButton,
        TalentMicroButton,
        AchievementMicroButton,
        QuestLogMicroButton,
        SocialsMicroButton,
        CollectionsMicroButton,
        PVPMicroButton,
        LFGMicroButton,
        MainMenuMicroButton,
        HelpMicroButton,
    }
elseif YxUI.IsCata then
    MicroButtons.Buttons = {
        CharacterMicroButton,
        SpellbookMicroButton,
        TalentMicroButton,
        AchievementMicroButton,
        QuestLogMicroButton,
        CollectionsMicroButton,
        PVPMicroButton,
        LFGMicroButton,
        MainMenuMicroButton,
        HelpMicroButton,
    }
    if EJMicroButton then
        table.insert(MicroButtons.Buttons, #MicroButtons.Buttons - 2, EJMicroButton)
    end
    if GuildMicroButton and GuildMicroButton:IsShown() then
        table.insert(MicroButtons.Buttons, 6, GuildMicroButton)
    end
else
    MicroButtons.Buttons = {
        CharacterMicroButton,
        SpellbookMicroButton,
        TalentMicroButton,
        QuestLogMicroButton,
        GuildMicroButton,
        WorldMapMicroButton,
        MainMenuMicroButton,
        HelpMicroButton,
    }
end

-- Default settings values
Defaults["micro-buttons-visiblity"] = "SHOW"
Defaults["micro-buttons-opacity"] = 40
Defaults["micro-buttons-max"] = 100
Defaults["micro-buttons-per-row"] = #MicroButtons.Buttons
Defaults["micro-buttons-gap"] = 8

local ButtonOnEnter = function(self)
    if (Settings["micro-buttons-visiblity"] == "MOUSEOVER") then
        self:GetParent():SetAlpha(Settings["micro-buttons-max"] / 100)
    end
end

local ButtonOnLeave = function(self)
    if (Settings["micro-buttons-visiblity"] == "MOUSEOVER") then
        self:GetParent():SetAlpha(Settings["micro-buttons-opacity"] / 100)
    end
end

function MicroButtons:UpdateVisibility()
    if (Settings["micro-buttons-visiblity"] == "HIDE") then
        self.Panel:SetScript("OnEnter", nil)
        self.Panel:SetScript("OnLeave", nil)
        self.Panel:SetAlpha(0)
        self.Panel:Hide()
    elseif (Settings["micro-buttons-visiblity"] == "MOUSEOVER") then
        self.Panel:SetScript("OnEnter", BagsFrameOnEnter)
        self.Panel:SetScript("OnLeave", BagsFrameOnLeave)
        self.Panel:SetAlpha(Settings["micro-buttons-opacity"] / 100)
        self.Panel:Show()
    elseif (Settings["micro-buttons-visiblity"] == "SHOW") then
        self.Panel:SetScript("OnEnter", nil)
        self.Panel:SetScript("OnLeave", nil)
        self.Panel:SetAlpha(Settings["micro-buttons-max"] / 100)
        self.Panel:Show()
    end
end

function MicroButtons:UpdateMicroButtonsParent()
    for i = 1, #MicroButtons.Buttons do
        MicroButtons.Buttons[i]:SetParent(MicroButtons.Panel)
    end
end

function MicroButtons:PositionButtons()
    local NumButtons = #MicroButtons.Buttons
    local PerRow = Settings["micro-buttons-per-row"]
    local Spacing = Settings["micro-buttons-gap"]

    if (NumButtons < PerRow) then
        PerRow = NumButtons
    end

    local Columns = ceil(NumButtons / PerRow)

    if (Columns < 1) then
        Columns = 1
    end

    local Width, Height = MicroButtons.Buttons[1]:GetSize()

    -- Bar sizing
    MicroButtons.Panel:SetWidth((Width + Spacing) * (PerRow - 1) + Spacing / 2)
    MicroButtons.Panel:SetHeight(Height * Columns + Spacing * (Columns - 1) + Spacing / 2)

    -- Actual moving
    for i = 1, #MicroButtons.Buttons do
        local Button = MicroButtons.Buttons[i]

        Button:ClearAllPoints()

        if (i == 1) then
            Button:SetPoint("TOPLEFT", MicroButtons.Panel, 0, 0)
        elseif ((i - 1) % PerRow == 0) then
            Button:SetPoint("TOP", MicroButtons.Buttons[i - PerRow], "BOTTOM", 0, -Spacing)
        else
            Button:SetPoint("LEFT", MicroButtons.Buttons[i - 1], "RIGHT", Spacing - 2, 0)
        end
    end
end

function MicroButtons:Load()
    if (not Settings["ab-enable"]) then
        return
    end

    if MicroMenu then
        MicroMenu:SetParent(YxUI.UIParent)
    end

    self.Panel = CreateFrame("Frame", "YxUI Micro Buttons", YxUI.UIParent, "BackdropTemplate")
    self.Panel:SetFrameStrata("LOW")

    if YxUI.IsMainline then
        self.Panel:SetSize(312, 30)
    else
        self.Panel:SetSize(208, 30)
    end

    if Settings["right-window-enable"] then
        self.Panel:SetPoint("BOTTOMRIGHT", YxUI:GetModule("Right Window"), "TOPRIGHT", 0, 3)
    else
        self.Panel:SetPoint("BOTTOMRIGHT", YxUI.UIParent, 0, 0)
    end

    YxUI:CreateMover(self.Panel)

    for i = 1, #self.Buttons do
        self.Buttons[i]:SetParent(self.Panel)
        self.Buttons[i]:ClearAllPoints()
        self.Buttons[i]:SetHitRectInsets(0, 0, 0, 0)
        self.Buttons[i]:CreateBorder()

        if (not YxUI.IsMainline) then
            self.Buttons[i]:SetSize(22, 30)
        end

        self.Buttons[i]:HookScript("OnEnter", ButtonOnEnter)
        self.Buttons[i]:HookScript("OnLeave", ButtonOnLeave)

        if self.Buttons[i].FlashContent then
            self.Buttons[i].FlashContent:ClearAllPoints()
            self.Buttons[i].FlashContent:SetAllPoints(self.Buttons[i])

            self.Buttons[i].FlashBorder:ClearAllPoints()
            self.Buttons[i].FlashBorder:SetPoint("TOPLEFT", self.Buttons[i], -3, 3)
            self.Buttons[i].FlashBorder:SetPoint("BOTTOMRIGHT", self.Buttons[i], 3, -3)
        end

        local Normal = self.Buttons[i]:GetNormalTexture()
        local Pushed = self.Buttons[i]:GetPushedTexture()
        local Disabled = self.Buttons[i]:GetDisabledTexture()
        local Highlight = self.Buttons[i]:GetHighlightTexture()

        if Normal then
            Normal:ClearAllPoints()
            Normal:SetPoint("TOPLEFT", self.Buttons[i], 2, -2)
            Normal:SetPoint("BOTTOMRIGHT", self.Buttons[i], -2, 2)
        end

        if Pushed then
            Pushed:ClearAllPoints()
            Pushed:SetPoint("TOPLEFT", self.Buttons[i], 2, -2)
            Pushed:SetPoint("BOTTOMRIGHT", self.Buttons[i], -2, 2)
        end

        if Disabled then
            Disabled:ClearAllPoints()
            Disabled:SetPoint("TOPLEFT", self.Buttons[i], 2, -2)
            Disabled:SetPoint("BOTTOMRIGHT", self.Buttons[i], -2, 2)
        end

        if (not YxUI.IsMainline) then
            if Normal then
                Normal:SetTexCoord(0.2, 0.85, 0.5, 0.9)
            end

            if Pushed then
                Pushed:SetTexCoord(0.2, 0.85, 0.5, 0.9)
            end

            if Disabled then
                Disabled:SetTexCoord(0.2, 0.85, 0.5, 0.9)
            end
        end

        if Highlight then
            Highlight:ClearAllPoints()
            Highlight:SetPoint("TOPLEFT", self.Buttons[i], 2, -2)
            Highlight:SetPoint("BOTTOMRIGHT", self.Buttons[i], -2, 2)
            Highlight:SetTexture(Assets:GetTexture("Blank"))
            Highlight:SetVertexColor(1, 1, 1, 0.2)
        end
    end

    if MicroButtonPortrait then
        MicroButtonPortrait:ClearAllPoints()
        MicroButtonPortrait:SetPoint("TOPLEFT", CharacterMicroButton, 2, -2)
        MicroButtonPortrait:SetPoint("BOTTOMRIGHT", CharacterMicroButton, -2, 2)
    end

    if (YxUI.IsWrath or YxUI.IsCata) then
        PVPMicroButtonTexture:ClearAllPoints()
        PVPMicroButtonTexture:SetPoint("TOP", PVPMicroButton, 6, -6)
    end

    if MainMenuBarPerformanceBar then
        MainMenuBarPerformanceBar:Hide()
    end

    if (not Settings["micro-buttons-show"]) then
        self.Panel:Hide()
    end

    if UpdateMicroButtonsParent then
        hooksecurefunc("UpdateMicroButtonsParent", self.UpdateMicroButtonsParent)
    end

    if MoveMicroButtons then
        hooksecurefunc("MoveMicroButtons", self.PositionButtons)
    end

    self:UpdateVisibility()
    self:PositionButtons()
end

local UpdateMicroVisibility = function(value)
    MicroButtons:UpdateVisibility()
end

local UpdateMicroPositions = function()
    MicroButtons:PositionButtons()
end

YxUI:GetModule("GUI"):AddWidgets(Language["General"], Language["Action Bars"], function(left, right)
    right:CreateHeader(Language["Micro Menu Buttons"])
    right:CreateDropdown("micro-buttons-visiblity", Settings["micro-buttons-visiblity"], { [Language["Hide"]] = "HIDE", [Language["Mouseover"]] = "MOUSEOVER", [Language["Show"]] = "SHOW" }, Language["Set Visibility"], Language["Set the visibility of the micro menu buttons"], UpdateMicroVisibility)
    right:CreateSlider("micro-buttons-opacity", Settings["micro-buttons-opacity"], 0, 100, 10, Language["Set Faded Opacity"], Language["Set the opacity of the micro menu buttons when visiblity is set to Mouseover"], UpdateMicroVisibility, nil, "%")
    right:CreateSlider("micro-buttons-max", Settings["micro-buttons-max"], 0, 100, 10, Language["Set Max Opacity"], Language["Set the max opacity of the micro menu buttons when visiblity is set to Mouseover"], UpdateMicroVisibility, nil, "%")
    right:CreateSlider("micro-buttons-per-row", Settings["micro-buttons-per-row"], 1, #MicroButtons.Buttons, 1, Language["Buttons Per Row"], Language["Set the number of buttons per row"], UpdateMicroPositions)
    right:CreateSlider("micro-buttons-gap", Settings["micro-buttons-gap"], 5, 10, 1, Language["Button Spacing"], Language["Set the spacing between micro buttons"], UpdateMicroPositions)
end)
