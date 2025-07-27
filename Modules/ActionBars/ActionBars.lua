local Y, L, A, C, D = select(2, ...):get()

local AB = Y:NewModule("Action Bars")
local GUI = Y:GetModule("GUI")

local IsUsableAction = IsUsableAction
local NUM_PET_ACTION_SLOTS = NUM_PET_ACTION_SLOTS

-- Defaults
D["ab-enable"] = true

D["ab-show-hotkey"] = true
D["ab-show-count"] = true
D["ab-show-macro"] = true
D["ab-show-empty"] = true

D["ab-font"] = "PT Sans"
D["ab-font-size"] = 13
D["ab-cd-size"] = 18
D["ab-font-flags"] = "OUTLINE"

D["ab-bar1-enable"] = true
D["ab-bar1-hover"] = false
D["ab-bar1-button-size"] = 38
D["ab-bar1-button-gap"] = 5
D["ab-bar1-button-max"] = 12
D["ab-bar1-per-row"] = 12
D["ab-bar1-alpha"] = 100

D["ab-bar2-enable"] = true
D["ab-bar2-hover"] = false
D["ab-bar2-button-size"] = 38
D["ab-bar2-button-gap"] = 5
D["ab-bar2-button-max"] = 12
D["ab-bar2-per-row"] = 12
D["ab-bar2-alpha"] = 100

D["ab-bar3-enable"] = false
D["ab-bar3-hover"] = false
D["ab-bar3-button-size"] = 38
D["ab-bar3-button-gap"] = 5
D["ab-bar3-button-max"] = 12
D["ab-bar3-per-row"] = 12
D["ab-bar3-alpha"] = 100

D["ab-bar4-enable"] = false
D["ab-bar4-hover"] = false
D["ab-bar4-button-size"] = 38
D["ab-bar4-button-gap"] = 5
D["ab-bar4-button-max"] = 12
D["ab-bar4-per-row"] = 1
D["ab-bar4-alpha"] = 100

D["ab-bar5-enable"] = false
D["ab-bar5-hover"] = false
D["ab-bar5-button-size"] = 38
D["ab-bar5-button-gap"] = 5
D["ab-bar5-button-max"] = 12
D["ab-bar5-per-row"] = 1
D["ab-bar5-alpha"] = 100

D["ab-bar6-enable"] = true
D["ab-bar6-hover"] = false
D["ab-bar6-button-size"] = 38
D["ab-bar6-button-gap"] = 5
D["ab-bar6-button-max"] = 12
D["ab-bar6-per-row"] = 1
D["ab-bar6-alpha"] = 100

D["ab-bar7-enable"] = true
D["ab-bar7-hover"] = false
D["ab-bar7-button-size"] = 38
D["ab-bar7-button-gap"] = 5
D["ab-bar7-button-max"] = 12
D["ab-bar7-per-row"] = 1
D["ab-bar7-alpha"] = 100

D["ab-bar8-enable"] = true
D["ab-bar8-hover"] = false
D["ab-bar8-button-size"] = 38
D["ab-bar8-button-gap"] = 5
D["ab-bar8-button-max"] = 12
D["ab-bar8-per-row"] = 1
D["ab-bar8-alpha"] = 100

D["ab-pet-enable"] = true
D["ab-pet-hover"] = false
D["ab-pet-button-size"] = 28
D["ab-pet-button-gap"] = 5
D["ab-pet-per-row"] = 1
D["ab-pet-alpha"] = 100

D["ab-stance-enable"] = true
D["ab-stance-position-bar"] = true
D["ab-stance-hover"] = false
D["ab-stance-button-size"] = 30
D["ab-stance-button-gap"] = 5
D["ab-stance-per-row"] = 12
D["ab-stance-alpha"] = 100

D["ab-totem-enable"] = true
D["ab-extra-button-size"] = 60

local ActionBars = {
    "ActionButton",
    "MultiBarBottomLeftButton",
    "MultiBarBottomRightButton",
    "MultiBarLeftButton",
    "MultiBarRightButton",
}

function AB:Disable(object)
    if object.UnregisterAllEvents then
        object:UnregisterAllEvents()
    end

    object:SetParent(self.Hide)
end

function AB:EnableBar(bar)
    if bar.frameVisibility then
        RegisterAttributeDriver(bar, "state-visibility", bar.frameVisibility)
    else
        RegisterAttributeDriver(bar, "state-visibility", "[nopetbattle] show; hide")
    end
    bar:Show()
end

function AB:DisableBar(bar)
    UnregisterAttributeDriver(bar, "state-visibility")
    bar:Hide()
end

local keyButton = gsub(KEY_BUTTON4, "%d", "")
local keyNumpad = gsub(KEY_NUMPAD1, "%d", "")

local replaces = {
    { "(" .. keyButton .. ")", "M" },
    { "(" .. keyNumpad .. ")", "N" },
    { "(a%-)",                 "a" },
    { "(c%-)",                 "c" },
    { "(s%-)",                 "s" },
    { KEY_BUTTON3,             "M3" },
    { KEY_MOUSEWHEELUP,        "MU" },
    { KEY_MOUSEWHEELDOWN,      "MD" },
    { KEY_SPACE,               "Sp" },
    { "CAPSLOCK",              "CL" },
    { "Capslock",              "CL" },
    { "BUTTON",                "M" },
    { "NUMPAD",                "N" },
    { "(META%-)",              "m" },
    { "(Meta%-)",              "m" },
    { "(ALT%-)",               "a" },
    { "(CTRL%-)",              "c" },
    { "(SHIFT%-)",             "s" },
    { "MOUSEWHEELUP",          "MU" },
    { "MOUSEWHEELDOWN",        "MD" },
    { "SPACE",                 "Sp" },
}

function AB:UpdateHotKeyText()
    local text = self.HotKey:GetText()
    if not text then
        return
    end

    if text == RANGE_INDICATOR then
        text = ""
    else
        for _, value in pairs(replaces) do
            text = gsub(text, value[1], value[2])
        end
    end
    self.HotKey:SetFormattedText("%s", text)
end

function AB:PositionButtons(bar, numbuttons, perrow, size, spacing)
    if (numbuttons < perrow) then
        perrow = numbuttons
    end

    local Columns = ceil(numbuttons / perrow)

    if (Columns < 1) then
        Columns = 1
    end

    -- Bar sizing
    bar:SetWidth((size * perrow) + (spacing * (perrow - 1)))
    bar:SetHeight((size * Columns) + (spacing * (Columns - 1)))

    -- Actual moving
    for i = 1, #bar do
        local Button = bar[i]

        Button:ClearAllPoints()
        Button:SetSize(size, size)

        if (i == 1) then
            Button:SetPoint("TOPLEFT", bar, 0, 0)
        elseif ((i - 1) % perrow == 0) then
            Button:SetPoint("TOP", bar[i - perrow], "BOTTOM", 0, -spacing)
        else
            Button:SetPoint("LEFT", bar[i - 1], "RIGHT", spacing, 0)
        end

        if (i > numbuttons) then
            Button:SetParent(self.Hide)
        else
            Button:SetParent(bar.ButtonParent or bar)
        end
    end
end

function AB:StyleActionButton(button)
    if button.Styled then
        return
    end

    if button.IconMask then
        button.IconMask:Hide()
    end

    if button.RightDivider then
        button.RightDivider:Hide()
    end

    if button.SlotArt then
        button.SlotArt:Hide()
    end

    if _G[button:GetName() .. "NormalTexture"] then
        _G[button:GetName() .. "NormalTexture"]:SetTexture(nil)
    end

    if button:GetNormalTexture() then
        button:GetNormalTexture():SetTexture(nil)
    end

    button:SetNormalTexture("")

    if button.Border then
        button.Border:SetTexture(nil)
    end

    if button.icon then
        button.icon:ClearAllPoints()
        button.icon:SetPoint("TOPLEFT", button, 1, -1)
        button.icon:SetPoint("BOTTOMRIGHT", button, -1, 1)
        button.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    end

    if _G[button:GetName() .. "FloatingBG"] then
        self:Disable(_G[button:GetName() .. "FloatingBG"])
    end

    if button.HotKey then
        button.HotKey:ClearAllPoints()
        button.HotKey:SetPoint("TOPRIGHT", button, -2, -4)
        Y:SetFontInfo(button.HotKey, C["ab-font"], C["ab-font-size"], C["ab-font-flags"])
        button.HotKey:SetJustifyH("RIGHT")
        button.HotKey:SetTextColor(0.75, 0.75, 0.75)
        button.HotKey.SetTextColor = function() end

        AB.UpdateHotKeyText(button)

        if (not C["ab-show-hotkey"]) then
            button.HotKey:SetAlpha(0)
        end
    end

    if button.Name then
        button.Name:ClearAllPoints()
        button.Name:SetPoint("BOTTOMLEFT", button, 2, 2)
        button.Name:SetWidth(button:GetWidth() - 4)
        Y:SetFontInfo(button.Name, C["ab-font"], C["ab-font-size"], C["ab-font-flags"])
        button.Name:SetJustifyH("LEFT")
        button.Name:SetTextColor(1, 1, 1)
        button.Name.SetTextColor = function() end

        if (not C["ab-show-macro"]) then
            button.Name:SetAlpha(0)
        end
    end

    if button.Count then
        button.Count:ClearAllPoints()
        button.Count:SetPoint("BOTTOMRIGHT", button, -2, 2)
        Y:SetFontInfo(button.Count, C["ab-font"], C["ab-font-size"], C["ab-font-flags"])
        button.Count:SetJustifyH("RIGHT")
        button.Count:SetDrawLayer("OVERLAY")
        button.Count:SetTextColor(1, 1, 1)
        button.Count.SetTextColor = function() end

        if (not C["ab-show-count"]) then
            button.Count:SetAlpha(0)
        end
    end

    button:CreateBorder(nil, nil, nil, nil, nil, nil, "Interface\\AddOns\\YxUI\\Media\\Textures\\UI-Slot-Background", nil, nil, nil, { 1, 1, 1 })

    if button:GetCheckedTexture() then
        local Checked = button:GetCheckedTexture()
        Checked:SetTexture(A:GetTexture(C["action-bars-button-highlight"]))
        Checked:SetColorTexture(0.1, 0.9, 0.1, 0.2)
        Checked:SetPoint("TOPLEFT", button, 1, -1)
        Checked:SetPoint("BOTTOMRIGHT", button, -1, 1)
    end

    if button:GetPushedTexture() then
        local Pushed = button:GetPushedTexture()
        Pushed:SetTexture(A:GetTexture(C["action-bars-button-highlight"]))
        Pushed:SetColorTexture(0.9, 0.8, 0.1, 0.3)
        Pushed:SetPoint("TOPLEFT", button, 1, -1)
        Pushed:SetPoint("BOTTOMRIGHT", button, -1, 1)
    end

    local Highlight = button:GetHighlightTexture()
    Highlight:SetTexture(A:GetTexture(C["action-bars-button-highlight"]))
    Highlight:SetColorTexture(1, 1, 1, 0.2)
    Highlight:SetPoint("TOPLEFT", button, 1, -1)
    Highlight:SetPoint("BOTTOMRIGHT", button, -1, 1)

    if button.Flash then
        button.Flash:SetVertexColor(0.7, 0.7, 0.1, 0.3)
        button.Flash:SetPoint("TOPLEFT", button, 1, -1)
        button.Flash:SetPoint("BOTTOMRIGHT", button, -1, 1)
    end

    local Range = button:CreateTexture(nil, "ARTWORK")
    Range:SetTexture(A:GetTexture(C["action-bars-button-highlight"]))
    Range:SetVertexColor(0.7, 0, 0)
    Range:SetPoint("TOPLEFT", button, 1, -1)
    Range:SetPoint("BOTTOMRIGHT", button, -1, 1)
    Range:SetAlpha(0)

    button.Range = Range

    if button.cooldown then
        button.cooldown:ClearAllPoints()
        button.cooldown:SetPoint("TOPLEFT", button, 1, -1)
        button.cooldown:SetPoint("BOTTOMRIGHT", button, -1, 1)

        button.cooldown:SetDrawEdge(true)
        button.cooldown:SetEdgeTexture(A:GetTexture("Blank"))
        button.cooldown:SetSwipeColor(0, 0, 0, 1)

        local FontString = button.cooldown:GetRegions()

        if FontString then
            Y:SetFontInfo(FontString, C["ab-font"], C["ab-cd-size"], C["ab-font-flags"])
        end
    end

    button:SetFrameLevel(15)
    button:SetFrameStrata("MEDIUM")

    if button.Update then
        hooksecurefunc(button, "Update", AB.UpdateHotKeyText)
    elseif ActionButton_UpdateHotkeys then
        hooksecurefunc("ActionButton_UpdateHotkeys", AB.UpdateHotKeyText)
    end

    button.Styled = true
end

function AB:StylePetActionButton(button)
    if button.Styled then
        return
    end

    button:SetSize(C["ab-pet-button-size"], C["ab-pet-button-size"])

    local Name = button:GetName()

    if _G[Name .. "AutoCastable"] then
        _G[Name .. "AutoCastable"]:SetSize(C["ab-pet-button-size"] * 2 - 4, C["ab-pet-button-size"] * 2 - 4)
    end

    local Shine = _G[Name .. "Shine"]

    if Shine then
        Shine:SetSize(C["ab-pet-button-size"] - 6, C["ab-pet-button-size"] - 6)
        Shine:ClearAllPoints()
        Shine:SetPoint("CENTER", button, 0, 0)
    end

    button.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    button.icon:SetDrawLayer("BACKGROUND", 7)
    button.icon:SetPoint("TOPLEFT", button, 1, -1)
    button.icon:SetPoint("BOTTOMRIGHT", button, -1, 1)

    if button.IconMask then
        button.IconMask:Hide()
    end

    if button.SlotArt then
        button.SlotArt:Hide()
    end

    _G[button:GetName() .. "NormalTexture"]:SetAlpha(0)
    _G[button:GetName() .. "NormalTexture"]:Hide()
    button:GetNormalTexture():SetAlpha(0)
    button:GetNormalTexture():Hide()

    button:SetNormalTexture("")

    if button.HotKey then
        button.HotKey:ClearAllPoints()
        button.HotKey:SetPoint("TOPLEFT", button, 2, -3)
        Y:SetFontInfo(button.HotKey, C["ab-font"], C["ab-font-size"], C["ab-font-flags"])
        button.HotKey:SetJustifyH("LEFT")
        button.HotKey:SetDrawLayer("OVERLAY")
        button.HotKey:SetTextColor(1, 1, 1)
        button.HotKey.SetTextColor = function() end

        local Text = button.HotKey:GetText()

        if Text then
            button.HotKey:SetText("|cFFFFFFFF" .. Text .. "|r")
        end

        button.HotKey.OST = button.HotKey.SetText
        button.HotKey.SetText = function(self, text)
            self:OST("|cFFFFFFFF" .. text .. "|r")
        end

        if (not C["action-bars-show-hotkeys"]) then
            button.HotKey:SetAlpha(0)
        end
    end

    if button.Name then
        button.Name:ClearAllPoints()
        button.Name:SetPoint("BOTTOMLEFT", button, 2, 2)
        button.Name:SetWidth(button:GetWidth() - 4)
        Y:SetFontInfo(button.Name, C["ab-font"], C["ab-font-size"], C["ab-font-flags"])
        button.Name:SetJustifyH("LEFT")
        button.Name:SetDrawLayer("OVERLAY")
        button.Name:SetTextColor(1, 1, 1)
        button.Name.SetTextColor = function() end

        if (not C["action-bars-show-macro-names"]) then
            button.Name:SetAlpha(0)
        end
    end

    if button.Count then
        button.Count:ClearAllPoints()
        button.Count:SetPoint("BOTTOMRIGHT", button, -2, 2)
        Y:SetFontInfo(button.Count, C["ab-font"], C["ab-font-size"], C["ab-font-flags"])
        button.Count:SetJustifyH("RIGHT")
        button.Count:SetDrawLayer("OVERLAY")
        button.Count:SetTextColor(1, 1, 1)
        button.Count.SetTextColor = function() end

        if (not C["action-bars-show-count"]) then
            button.Count:SetAlpha(0)
        end
    end

    _G[Name .. "Flash"]:SetTexture("")

    if _G[Name .. "NormalTexture2"] then
        _G[Name .. "NormalTexture2"]:Hide()
    end

    local Checked = button:GetCheckedTexture()
    Checked:SetTexture(A:GetTexture(C["action-bars-button-highlight"]))
    Checked:SetColorTexture(0.1, 0.9, 0.1, 0.3)
    Checked:SetPoint("TOPLEFT", button, 1, -1)
    Checked:SetPoint("BOTTOMRIGHT", button, -1, 1)

    local Pushed = button:GetPushedTexture()
    Pushed:SetTexture(A:GetTexture(C["action-bars-button-highlight"]))
    Pushed:SetColorTexture(0.9, 0.8, 0.1, 0.3)
    Pushed:SetPoint("TOPLEFT", button, 1, -1)
    Pushed:SetPoint("BOTTOMRIGHT", button, -1, 1)

    local Highlight = button:GetHighlightTexture()
    Highlight:SetTexture(A:GetTexture(C["action-bars-button-highlight"]))
    Highlight:SetColorTexture(1, 1, 1, 0.2)
    Highlight:SetPoint("TOPLEFT", button, 1, -1)
    Highlight:SetPoint("BOTTOMRIGHT", button, -1, 1)

    button:CreateBorder()

    button.Styled = true
end

function AB:PetActionBar_Update()
    for i = 1, NUM_PET_ACTION_SLOTS do
        AB.PetBar[i]:SetNormalTexture("")
    end
end

function AB:StanceBar_UpdateState()
    if (not C["ab-stance-enable"]) then
        return
    end

    if (GetNumShapeshiftForms() > 0) then
        if (not AB.StanceBar:IsShown()) then
            AB:EnableBar(AB.StanceBar)
        end
    elseif AB.StanceBar:IsShown() then
        AB:DisableBar(AB.StanceBar)
    end
end

function AB:UpdateButtonStatus(check, inrange)
    if (not check or not self.action) then
        return
    end

    local IsUsable, NoMana = IsUsableAction(self.action)

    if IsUsable then
        if (inrange == false) then
            self.icon:SetVertexColor(Y:HexToRGB("FF4C19"))
        else
            self.icon:SetVertexColor(Y:HexToRGB("FFFFFF"))
        end
    elseif NoMana then
        self.icon:SetVertexColor(Y:HexToRGB("7F7FE1"))
    else
        self.icon:SetVertexColor(Y:HexToRGB("4C4C4C"))
    end
end

local BarButtonOnEnter = function(self)
    if self.ParentBar.Fader:IsPlaying() then
        self.ParentBar.Fader:Stop()
    end

    for i = 1, #self.ParentBar do
        self.ParentBar[i].cooldown:SetDrawBling(true)
    end

    self.ParentBar.Fader:SetChange(self.ParentBar.MaxAlpha / 100)
    self.ParentBar.Fader:Play()
end

local BarButtonOnLeave = function(self)
    if self.ParentBar.Fader:IsPlaying() then
        self.ParentBar.Fader:Stop()
    end

    for i = 1, #self.ParentBar do
        self.ParentBar[i].cooldown:SetDrawBling(false)
    end

    self.ParentBar.Fader:SetChange(self.ParentBar.ShouldFade and 0 or (self.ParentBar.MaxAlpha / 100))
    self.ParentBar.Fader:Play()
end

local BarOnEnter = function(self)
    if self.Fader:IsPlaying() then
        self.Fader:Stop()
    end

    for i = 1, #self do
        self[i].cooldown:SetDrawBling(true)
    end

    self.Fader:SetChange(self.MaxAlpha / 100)
    self.Fader:Play()
end

local BarOnLeave = function(self)
    if self.Fader:IsPlaying() then
        self.Fader:Stop()
    end

    for i = 1, #self do
        self[i].cooldown:SetDrawBling(false)
    end

    self.Fader:SetChange(self.ShouldFade and 0 or (self.MaxAlpha / 100))
    self.Fader:Play()
end

-- Bar 1
function AB:CreateBar1()
    self.Bar1 = CreateFrame("Frame", "YxUI Action Bar 1", Y.UIParent, "SecureHandlerStateTemplate")
    self.Bar1:SetPoint("BOTTOM", Y.UIParent, "BOTTOM", 0, 3)
    self.Bar1:SetAlpha(C["ab-bar1-alpha"] / 100)
    self.Bar1.ShouldFade = C["ab-bar1-hover"]
    self.Bar1.MaxAlpha = C["ab-bar1-alpha"]
    self.Bar1.GetSpellFlyoutDirection = function() return "UP" end -- Temp

    self.Bar1.Fader = LibMotion:CreateAnimation(self.Bar1, "Fade")
    self.Bar1.Fader:SetDuration(0.15)
    self.Bar1.Fader:SetEasing("inout")

    for i = 1, 12 do
        local Button = _G["ActionButton" .. i]

        self:StyleActionButton(Button)

        Button:SetParent(self.Bar1)
        Button.ParentBar = self.Bar1

        Button:HookScript("OnEnter", BarButtonOnEnter)
        Button:HookScript("OnLeave", BarButtonOnLeave)

        self.Bar1:SetFrameRef("Button" .. i, Button)

        self.Bar1[i] = Button
    end

    if C["ab-bar1-hover"] then
        self.Bar1:SetAlpha(0)
        self.Bar1:SetScript("OnEnter", BarOnEnter)
        self.Bar1:SetScript("OnLeave", BarOnLeave)

        for i = 1, #self.Bar1 do
            self.Bar1[i].cooldown:SetDrawBling(false)
        end
    end

    self.Bar1:Execute([[
		Buttons = table.new()

		for i = 1, 12 do
			table.insert(Buttons, self:GetFrameRef("Button" .. i))
		end
	]])

    local Page = {}
    if not Y.IsMainline then
        Page = {
            ["DRUID"] = "[bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10;",
            ["WARRIOR"] = "[bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9;",
            ["PRIEST"] = "[bonusbar:1] 7;",
            ["ROGUE"] = "[bonusbar:1] 7; [form:3] 7;",
            ["WARLOCK"] = "[form:2] 10;",
            ["DEFAULT"] = "[possessbar] 16; [shapeshift] 17; [overridebar] 18; [vehicleui] 16; [bar:2] 2; [bar:3] 3; [bar:4] 4; [bar:5] 5; [bar:6] 6; [bonusbar: 5] 11;",
        }
    else
        Page = {
            ["DRUID"] = "[bonusbar:1,nostealth] 7; [bonusbar:1,stealth] 8; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10;",
            ["EVOKER"] = "[bonusbar:1] 7;",
            ["ROGUE"] = "[bonusbar:1] 7;",
            ["DEFAULT"] = "[possessbar] 16; [shapeshift] 17; [overridebar] 18; [vehicleui] 16; [bar:2] 2; [bar:3] 3; [bar:4] 4; [bar:5] 5; [bar:6] 6; [bonusbar:5] 11;",
        }
    end
    local function GetBar()
        local condition = Page["DEFAULT"]
        local class = Y.UserClass
        local page = Page[class]
        if page then
            condition = condition.." "..page
        end
        condition = condition.." 1"
        return condition
    end

    self.Bar1:Execute([[
        buttons = table.new()
        for i = 1, 12 do
            table.insert(buttons, self:GetFrameRef("Button"..i))
        end
    ]])

    self.Bar1:SetAttribute("_onstate-page", [[
        for i, button in ipairs(buttons) do
            button:SetAttribute("actionpage", tonumber(newstate))
        end
    ]])

    RegisterStateDriver(self.Bar1, "page", GetBar())

    self:PositionButtons(self.Bar1, C["ab-bar1-button-max"], C["ab-bar1-per-row"], C["ab-bar1-button-size"], C["ab-bar1-button-gap"])

    if OverrideActionBar then
        self:Disable(OverrideActionBar)
    end

    if C["ab-bar1-enable"] then
        self:EnableBar(self.Bar1)
    else
        self:DisableBar(self.Bar1)
    end
end

-- Bar 2
function AB:CreateBar2()
    self.Bar2 = CreateFrame("Frame", "YxUI Action Bar 2", Y.UIParent, "SecureHandlerStateTemplate")
    self.Bar2:SetPoint("BOTTOM", self.Bar1, "TOP", 0, C["ab-bar2-button-gap"])
    self.Bar2:SetAlpha(C["ab-bar2-alpha"] / 100)
    self.Bar2.ButtonParent = MultiBarBottomLeft
    self.Bar2.ShouldFade = C["ab-bar2-hover"]
    self.Bar2.MaxAlpha = C["ab-bar2-alpha"]

    self.Bar2.Fader = LibMotion:CreateAnimation(self.Bar2, "Fade")
    self.Bar2.Fader:SetDuration(0.15)
    self.Bar2.Fader:SetEasing("inout")

    MultiBarBottomLeft:SetParent(self.Bar2)

    for i = 1, 12 do
        local Button = _G["MultiBarBottomLeftButton" .. i]

        self:StyleActionButton(Button)

        Button.ParentBar = self.Bar2

        Button:HookScript("OnEnter", BarButtonOnEnter)
        Button:HookScript("OnLeave", BarButtonOnLeave)

        self.Bar2[i] = Button
    end

    if C["ab-bar2-hover"] then
        self.Bar2:SetAlpha(0)
        self.Bar2:SetScript("OnEnter", BarOnEnter)
        self.Bar2:SetScript("OnLeave", BarOnLeave)

        for i = 1, #self.Bar2 do
            self.Bar2[i].cooldown:SetDrawBling(false)
        end
    end

    self:PositionButtons(self.Bar2, C["ab-bar2-button-max"], C["ab-bar2-per-row"], C["ab-bar2-button-size"], C["ab-bar2-button-gap"])

    if C["ab-bar2-enable"] then
        self:EnableBar(self.Bar2)
    else
        self:DisableBar(self.Bar2)
    end
end

-- Bar 3
function AB:CreateBar3()
    self.Bar3 = CreateFrame("Frame", "YxUI Action Bar 3", Y.UIParent, "SecureHandlerStateTemplate")
    self.Bar3:SetPoint("BOTTOM", self.Bar2, "TOP", 0, C["ab-bar3-button-gap"])
    self.Bar3:SetAlpha(C["ab-bar3-alpha"] / 100)
    self.Bar3.ButtonParent = MultiBarBottomRight
    self.Bar3.ShouldFade = C["ab-bar3-hover"]
    self.Bar3.MaxAlpha = C["ab-bar3-alpha"]

    self.Bar3.Fader = LibMotion:CreateAnimation(self.Bar3, "Fade")
    self.Bar3.Fader:SetDuration(0.15)
    self.Bar3.Fader:SetEasing("inout")

    MultiBarBottomRight:SetParent(self.Bar3)

    for i = 1, 12 do
        local Button = _G["MultiBarBottomRightButton" .. i]

        self:StyleActionButton(Button)

        Button.ParentBar = self.Bar3

        Button:HookScript("OnEnter", BarButtonOnEnter)
        Button:HookScript("OnLeave", BarButtonOnLeave)

        self.Bar3[i] = Button
    end

    if C["ab-bar3-hover"] then
        self.Bar3:SetAlpha(0)
        self.Bar3:SetScript("OnEnter", BarOnEnter)
        self.Bar3:SetScript("OnLeave", BarOnLeave)

        for i = 1, #self.Bar3 do
            self.Bar3[i].cooldown:SetDrawBling(false)
        end
    end

    self:PositionButtons(self.Bar3, C["ab-bar3-button-max"], C["ab-bar3-per-row"], C["ab-bar3-button-size"], C["ab-bar3-button-gap"])

    if C["ab-bar3-enable"] then
        self:EnableBar(self.Bar3)
    else
        self:DisableBar(self.Bar3)
    end
end

-- Bar 4
function AB:CreateBar4()
    self.Bar4 = CreateFrame("Frame", "YxUI Action Bar 4", Y.UIParent, "SecureHandlerStateTemplate")
    self.Bar4:SetPoint("RIGHT", Y.UIParent, -12, 0)
    self.Bar4:SetAlpha(C["ab-bar4-alpha"] / 100)
    self.Bar4.ButtonParent = MultiBarRight
    self.Bar4.ShouldFade = C["ab-bar4-hover"]
    self.Bar4.MaxAlpha = C["ab-bar4-alpha"]

    self.Bar4.Fader = LibMotion:CreateAnimation(self.Bar4, "Fade")
    self.Bar4.Fader:SetDuration(0.15)
    self.Bar4.Fader:SetEasing("inout")

    MultiBarRight:SetParent(self.Bar4)

    for i = 1, 12 do
        local Button = _G["MultiBarRightButton" .. i]

        self:StyleActionButton(Button)

        Button.ParentBar = self.Bar4

        Button:HookScript("OnEnter", BarButtonOnEnter)
        Button:HookScript("OnLeave", BarButtonOnLeave)

        self.Bar4[i] = Button
    end

    if C["ab-bar4-hover"] then
        self.Bar4:SetAlpha(0)
        self.Bar4:SetScript("OnEnter", BarOnEnter)
        self.Bar4:SetScript("OnLeave", BarOnLeave)

        for i = 1, #self.Bar4 do
            self.Bar4[i].cooldown:SetDrawBling(false)
        end
    end

    self:PositionButtons(self.Bar4, C["ab-bar4-button-max"], C["ab-bar4-per-row"], C["ab-bar4-button-size"], C["ab-bar4-button-gap"])

    if C["ab-bar4-enable"] then
        self:EnableBar(self.Bar4)
    else
        self:DisableBar(self.Bar4)
    end
end

-- Bar 5
function AB:CreateBar5()
    self.Bar5 = CreateFrame("Frame", "YxUI Action Bar 5", Y.UIParent, "SecureHandlerStateTemplate")
    self.Bar5:SetPoint("RIGHT", self.Bar4, "LEFT", -C["ab-bar5-button-gap"], 0)
    self.Bar5:SetAlpha(C["ab-bar5-alpha"] / 100)
    self.Bar5.ButtonParent = MultiBarLeft
    self.Bar5.ShouldFade = C["ab-bar5-hover"]
    self.Bar5.MaxAlpha = C["ab-bar5-alpha"]

    self.Bar5.Fader = LibMotion:CreateAnimation(self.Bar5, "Fade")
    self.Bar5.Fader:SetDuration(0.15)
    self.Bar5.Fader:SetEasing("inout")

    MultiBarLeft:SetParent(self.Bar5)

    for i = 1, 12 do
        local Button = _G["MultiBarLeftButton" .. i]

        self:StyleActionButton(Button)

        Button.ParentBar = self.Bar5

        Button:HookScript("OnEnter", BarButtonOnEnter)
        Button:HookScript("OnLeave", BarButtonOnLeave)

        self.Bar5[i] = Button
    end

    if C["ab-bar5-hover"] then
        self.Bar5:SetAlpha(0)
        self.Bar5:SetScript("OnEnter", BarOnEnter)
        self.Bar5:SetScript("OnLeave", BarOnLeave)

        for i = 1, #self.Bar5 do
            self.Bar5[i].cooldown:SetDrawBling(false)
        end
    end

    self:PositionButtons(self.Bar5, C["ab-bar5-button-max"], C["ab-bar5-per-row"], C["ab-bar5-button-size"], C["ab-bar5-button-gap"])

    if C["ab-bar5-enable"] then
        self:EnableBar(self.Bar5)
    else
        self:DisableBar(self.Bar5)
    end
end

-- Bar 6
function AB:CreateBar6()
    self.Bar6 = CreateFrame("Frame", "YxUI Action Bar 6", Y.UIParent, "SecureHandlerStateTemplate")
    self.Bar6:SetPoint("RIGHT", self.Bar5, "LEFT", -C["ab-bar6-button-gap"], 0)
    self.Bar6:SetAlpha(C["ab-bar6-alpha"] / 100)
    self.Bar6.ButtonParent = MultiBar5
    self.Bar6.ShouldFade = C["ab-bar6-hover"]
    self.Bar6.MaxAlpha = C["ab-bar6-alpha"]

    self.Bar6.Fader = LibMotion:CreateAnimation(self.Bar6, "Fade")
    self.Bar6.Fader:SetDuration(0.15)
    self.Bar6.Fader:SetEasing("inout")

    MultiBar5:SetParent(self.Bar6)

    for i = 1, 12 do
        local Button = _G["MultiBar5Button" .. i]

        self:StyleActionButton(Button)

        Button.ParentBar = self.Bar6

        Button:HookScript("OnEnter", BarButtonOnEnter)
        Button:HookScript("OnLeave", BarButtonOnLeave)

        self.Bar6[i] = Button
    end

    if C["ab-bar6-hover"] then
        self.Bar6:SetAlpha(0)
        self.Bar6:SetScript("OnEnter", BarOnEnter)
        self.Bar6:SetScript("OnLeave", BarOnLeave)

        for i = 1, #self.Bar6 do
            self.Bar6[i].cooldown:SetDrawBling(false)
        end
    end

    self:PositionButtons(self.Bar6, C["ab-bar6-button-max"], C["ab-bar6-per-row"], C["ab-bar6-button-size"], C["ab-bar6-button-gap"])

    if C["ab-bar6-enable"] then
        self:EnableBar(self.Bar6)
    else
        self:DisableBar(self.Bar6)
    end
end

-- Bar 7
function AB:CreateBar7()
    self.Bar7 = CreateFrame("Frame", "YxUI Action Bar 7", Y.UIParent, "SecureHandlerStateTemplate")
    self.Bar7:SetPoint("RIGHT", self.Bar6, "LEFT", -C["ab-bar7-button-gap"], 0)
    self.Bar7:SetAlpha(C["ab-bar7-alpha"] / 100)
    self.Bar7.ButtonParent = MultiBar6
    self.Bar7.ShouldFade = C["ab-bar7-hover"]
    self.Bar7.MaxAlpha = C["ab-bar7-alpha"]

    self.Bar7.Fader = LibMotion:CreateAnimation(self.Bar7, "Fade")
    self.Bar7.Fader:SetDuration(0.15)
    self.Bar7.Fader:SetEasing("inout")

    MultiBar6:SetParent(self.Bar7)

    for i = 1, 12 do
        local Button = _G["MultiBar6Button" .. i]

        self:StyleActionButton(Button)

        Button.ParentBar = self.Bar7

        Button:HookScript("OnEnter", BarButtonOnEnter)
        Button:HookScript("OnLeave", BarButtonOnLeave)

        self.Bar7[i] = Button
    end

    if C["ab-bar7-hover"] then
        self.Bar7:SetAlpha(0)
        self.Bar7:SetScript("OnEnter", BarOnEnter)
        self.Bar7:SetScript("OnLeave", BarOnLeave)

        for i = 1, #self.Bar7 do
            self.Bar7[i].cooldown:SetDrawBling(false)
        end
    end

    self:PositionButtons(self.Bar7, C["ab-bar7-button-max"], C["ab-bar7-per-row"], C["ab-bar7-button-size"], C["ab-bar7-button-gap"])

    if C["ab-bar7-enable"] then
        self:EnableBar(self.Bar7)
    else
        self:DisableBar(self.Bar7)
    end
end

-- Bar 8
function AB:CreateBar8()
    self.Bar8 = CreateFrame("Frame", "YxUI Action Bar 8", Y.UIParent, "SecureHandlerStateTemplate")
    self.Bar8:SetPoint("RIGHT", self.Bar7, "LEFT", -C["ab-bar8-button-gap"], 0)
    self.Bar8:SetAlpha(C["ab-bar8-alpha"] / 100)
    self.Bar8.ButtonParent = MultiBar7
    self.Bar8.ShouldFade = C["ab-bar8-hover"]
    self.Bar8.MaxAlpha = C["ab-bar8-alpha"]

    self.Bar8.Fader = LibMotion:CreateAnimation(self.Bar8, "Fade")
    self.Bar8.Fader:SetDuration(0.15)
    self.Bar8.Fader:SetEasing("inout")

    MultiBar7:SetParent(self.Bar8)

    for i = 1, 12 do
        local Button = _G["MultiBar7Button" .. i]

        self:StyleActionButton(Button)

        Button.ParentBar = self.Bar8

        Button:HookScript("OnEnter", BarButtonOnEnter)
        Button:HookScript("OnLeave", BarButtonOnLeave)

        self.Bar8[i] = Button
    end

    if C["ab-bar8-hover"] then
        self.Bar8:SetAlpha(0)
        self.Bar8:SetScript("OnEnter", BarOnEnter)
        self.Bar8:SetScript("OnLeave", BarOnLeave)

        for i = 1, #self.Bar8 do
            self.Bar8[i].cooldown:SetDrawBling(false)
        end
    end

    self:PositionButtons(self.Bar8, C["ab-bar8-button-max"], C["ab-bar8-per-row"], C["ab-bar8-button-size"], C["ab-bar8-button-gap"])

    if C["ab-bar8-enable"] then
        self:EnableBar(self.Bar8)
    else
        self:DisableBar(self.Bar8)
    end
end

local PetBarUpdateGridLayout = function()
    if (not AB.PetBar:IsShown() or InCombatLockdown()) then
        return
    end

    AB:PositionButtons(AB.PetBar, NUM_PET_ACTION_SLOTS, C["ab-pet-per-row"], C["ab-pet-button-size"], C["ab-pet-button-gap"])
end

function AB:UpdatePetBarPosition()
    if not self.PetBar then
        return
    end
    self.PetBar:ClearAllPoints()
    if C["ab-bar5-enable"] then
        self.PetBar:SetPoint("RIGHT", self.Bar5, "LEFT", -C["ab-pet-button-gap"], 0)
    elseif C["ab-bar4-enable"] then
        self.PetBar:SetPoint("RIGHT", self.Bar4, "LEFT", -C["ab-pet-button-gap"], 0)
    else
        self.PetBar:SetPoint("RIGHT", Y.UIParent, -C["ab-pet-button-gap"], 0)
    end
end

-- Pet
function AB:CreatePetBar()
    self.PetBar = CreateFrame("Frame", "YxUI Pet Bar", Y.UIParent, "SecureHandlerStateTemplate")
    self.PetBar:SetAlpha(C["ab-pet-alpha"] / 100)
    self.PetBar.ButtonParent = PetActionBar or PetActionBarFrame
    self.PetBar.ShouldFade = C["ab-pet-hover"]
    self.PetBar.MaxAlpha = C["ab-pet-alpha"]
    self:UpdatePetBarPosition()

    self.PetBar.Fader = LibMotion:CreateAnimation(self.PetBar, "Fade")
    self.PetBar.Fader:SetDuration(0.15)
    self.PetBar.Fader:SetEasing("inout")

    if PetActionBar then
        PetActionBar:SetParent(self.PetBar)
		PetActionBar:SetAllPoints(self.PetBar)

        hooksecurefunc(PetActionBar, "UpdateGridLayout", PetBarUpdateGridLayout)
    else
        PetActionBarFrame:SetParent(self.PetBar)

        for i = 1, PetActionBarFrame:GetNumRegions() do
            local Region = select(i, PetActionBarFrame:GetRegions())

            if Region.SetTexture then
                Region:SetTexture(nil)
            end
        end
    end

    for i = 1, NUM_PET_ACTION_SLOTS do
        local Button = _G["PetActionButton" .. i]

        self:StylePetActionButton(Button)

        Button.ParentBar = self.PetBar

        Button:HookScript("OnEnter", BarButtonOnEnter)
        Button:HookScript("OnLeave", BarButtonOnLeave)

        self.PetBar[i] = Button
    end

    if C["ab-pet-hover"] then
        self.PetBar:SetAlpha(0)
        self.PetBar:SetScript("OnEnter", BarOnEnter)
        self.PetBar:SetScript("OnLeave", BarOnLeave)

        for i = 1, #self.PetBar do
            self.PetBar[i].cooldown:SetDrawBling(false)
        end
    end

    self:PositionButtons(self.PetBar, NUM_PET_ACTION_SLOTS, C["ab-pet-per-row"], C["ab-pet-button-size"], C["ab-pet-button-gap"])

    if PetActionBar_Update then
        hooksecurefunc("PetActionBar_Update", AB.PetActionBar_Update)
    end
    self.PetBar.frameVisibility = "[petbattle][overridebar][vehicleui][possessbar][shapeshift] hide; [pet] show; hide"

    if C["ab-pet-enable"] then
        self:EnableBar(self.PetBar)
    else
        self:DisableBar(self.PetBar)
    end
end

-- Stance
local StanceBarUpdateGridLayout = function()
    if InCombatLockdown() then
        return
    end

    AB:PositionButtons(AB.StanceBar, #AB.StanceBar, C["ab-stance-per-row"], C["ab-stance-button-size"], C["ab-stance-button-gap"])
end

function AB:UpdateStanceBarPosition()
    if not self.StanceBar then
        return
    end
    self.StanceBar:ClearAllPoints()
    if C["ab-stance-position-bar"] then
        if C["ab-bar3-enable"] then
            self.StanceBar:SetPoint("BOTTOMLEFT", self.Bar3, 'TOPLEFT', 0, 5)
        elseif C["ab-bar2-enable"] then
            self.StanceBar:SetPoint("BOTTOMLEFT", self.Bar2, 'TOPLEFT', 0, 5)
        elseif C["ab-bar1-enable"] then
            self.StanceBar:SetPoint("BOTTOMLEFT", self.Bar1, 'TOPLEFT', 0, 5)
        else
            self.StanceBar:SetPoint("TOPLEFT", Y.UIParent, 10, -10)
        end
    else
        self.StanceBar:SetPoint("TOPLEFT", Y.UIParent, 10, -10)
    end
end

function AB:CreateStanceBar()
    self.StanceBar = CreateFrame("Frame", "YxUI Stance Bar", Y.UIParent, "SecureHandlerStateTemplate")
    self.StanceBar:SetAlpha(C["ab-stance-alpha"] / 100)
    self.StanceBar.ButtonParent = StanceBar or StanceBarFrame
    self.StanceBar.ShouldFade = C["ab-stance-hover"]
    self.StanceBar.MaxAlpha = C["ab-stance-alpha"]

    self.StanceBar.Fader = LibMotion:CreateAnimation(self.StanceBar, "Fade")
    self.StanceBar.Fader:SetDuration(0.15)
    self.StanceBar.Fader:SetEasing("inout")
    self:UpdateStanceBarPosition()

    if StanceBar then
        StanceBar:SetParent(self.StanceBar)
    else
        StanceBarFrame:SetParent(self.StanceBar)
    end

    if StanceBar then
        if StanceBar.UpdateGridLayout then
            hooksecurefunc(StanceBar, "UpdateGridLayout", StanceBarUpdateGridLayout)
        end

        for i, button in next, StanceBar.actionButtons do
            self:StyleActionButton(button)

            button.ParentBar = self.StanceBar

            button:HookScript("OnEnter", BarButtonOnEnter)
            button:HookScript("OnLeave", BarButtonOnLeave)

            self.StanceBar[i] = button
        end

        self:PositionButtons(self.StanceBar, #self.StanceBar, C["ab-stance-per-row"], C["ab-stance-button-size"], C["ab-stance-button-gap"])

        --hooksecurefunc("StanceBar_UpdateState", self.StanceBar_UpdateState)

        if C["ab-stance-hover"] then
            self.StanceBar:SetAlpha(0)
            self.StanceBar:SetScript("OnEnter", BarOnEnter)
            self.StanceBar:SetScript("OnLeave", BarOnLeave)

            for i = 1, #self.StanceBar do
                self.StanceBar[i].cooldown:SetDrawBling(false)
            end
        end
    end

    if (StanceBarFrame and StanceBarFrame.StanceButtons) then
        StanceBarLeft:SetAlpha(0)
        StanceBarRight:SetAlpha(0)

        for i = 1, NUM_STANCE_SLOTS do
            local Button = StanceBarFrame.StanceButtons[i]

            self:StyleActionButton(Button)

            Button.ParentBar = self.StanceBar

            Button:HookScript("OnEnter", BarButtonOnEnter)
            Button:HookScript("OnLeave", BarButtonOnLeave)

            self.StanceBar[i] = Button
        end

        self:PositionButtons(self.StanceBar, #self.StanceBar, C["ab-stance-per-row"], C["ab-stance-button-size"], C["ab-stance-button-gap"])

        -- hooksecurefunc("StanceBar_UpdateState", self.StanceBar_UpdateState)

        if C["ab-stance-hover"] then
            self.StanceBar:SetAlpha(0)
            self.StanceBar:SetScript("OnEnter", BarOnEnter)
            self.StanceBar:SetScript("OnLeave", BarOnLeave)

            for i = 1, #self.StanceBar do
                self.StanceBar[i].cooldown:SetDrawBling(false)
            end
        end
    end

    self.StanceBar.frameVisibility = "[petbattle][overridebar][vehicleui][possessbar,@vehicle,exists][shapeshift] hide; show"

    if C["ab-stance-enable"] then
        self:EnableBar(self.StanceBar)
    else
        self:DisableBar(self.StanceBar)
    end
end

local UpdateZoneAbilityPosition = function(self, anchor, parent)
    --if (not InCombatLockdown()) and (parent and parent ~= AB.ExtraBar) then
    if (parent and parent ~= AB.ExtraBar) then
        self:ClearAllPoints()
        self:SetPoint("CENTER", AB.ExtraBar)
    end
end

local SkinZoneAbilityButtons = function()
    for Button in ZoneAbilityFrame.SpellButtonContainer:EnumerateActive() do
        if (not Button.Styled) then
            Button.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
            Button.NormalTexture:SetAlpha(0)

            Button.Backdrop = CreateFrame("Frame", nil, Button, "BackdropTemplate")
            Button.Backdrop:SetPoint("TOPLEFT", Button, -1, 1)
            Button.Backdrop:SetPoint("BOTTOMRIGHT", Button, 1, -1)
            Button.Backdrop:SetBackdrop(Y.Backdrop)
            Button.Backdrop:SetBackdropColor(0, 0, 0)
            Button.Backdrop:SetFrameLevel(Button:GetFrameLevel() - 1)

            Button.Styled = true
        end
    end
end

local UpdateExtraActionParent = function(self, parent)
    if InCombatLockdown() then
        AB.NeedsCombatFix = true

        AB:RegisterEvent("PLAYER_REGEN_ENABLED")
        AB:SetScript("OnEvent", AB.OnEvent)

        return
    end

    if (parent and parent ~= AB.ExtraBar) then
        self:SetParent(AB.ExtraBar)
    end
end

-- Extra Bar
function AB:CreateExtraBar()
    self.ExtraBar = CreateFrame("Frame", "YxUI Extra Action", Y.UIParent, "SecureHandlerStateTemplate")
    self.ExtraBar:SetSize(C["ab-extra-button-size"], C["ab-extra-button-size"])
    self.ExtraBar:SetPoint("CENTER", Y.UIParent, 0, -220)

	ExtraActionBarFrame:SetParent(YxUIParent)
    ExtraActionBarFrame:ClearAllPoints()
    ExtraActionBarFrame:SetAllPoints(self.ExtraBar)
    ExtraActionButton1.style:SetAlpha(0)
    ExtraActionBarFrame.ignoreInLayout = true

    --hooksecurefunc(ExtraActionBarFrame, "SetPoint", UpdateExtraActionPosition)
    hooksecurefunc(ExtraActionBarFrame, "SetParent", UpdateExtraActionParent)

    self:StyleActionButton(ExtraActionButton1)
    
    if Y.IsMists then
        --ExtraActionButton1:SetParent(ExtraActionBarFrame)
        ExtraActionButton1:ClearAllPoints()
        ExtraActionButton1:SetPoint("CENTER", ExtraActionBarFrame)
    end

	if ZoneAbilityFrame then
        ZoneAbilityFrame:ClearAllPoints()
        ZoneAbilityFrame:SetPoint("CENTER", self.ExtraBar)
        ZoneAbilityFrame.Style:SetAlpha(0)
        --ZoneAbilityFrame.ignoreInLayout = true

        hooksecurefunc(ZoneAbilityFrame, "SetPoint", UpdateZoneAbilityPosition)
        hooksecurefunc(ZoneAbilityFrame, "UpdateDisplayedZoneAbilities", SkinZoneAbilityButtons)
    end
end

function AB:OnEvent(event, ...)
    if self[event] then
        self[event](self, ...)
    end
end

function AB:PLAYER_REGEN_ENABLED()
    if self.NeedsCombatFix then
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        self:SetScript("OnEvent", nil)

        ExtraActionBarFrame:SetParent(AB.ExtraBar)

        self.NeedsCombatFix = nil
    end
end

function AB:CreateBars()
    self:CreateBar1()
    self:CreateBar2()
    self:CreateBar3()
    self:CreateBar4()
    self:CreateBar5()

    if MultiBar5 then
        self:CreateBar6()
        self:CreateBar7()
        self:CreateBar8()
    end

    if (PetActionBar or PetActionBarFrame) then
        self:CreatePetBar()
    end

    if (StanceBar or StanceBarFrame) then
        self:CreateStanceBar()
    end

    -- if Y.IsMainline then
    if ExtraActionButton1 then
        self:CreateExtraBar()
    end

    if (MultiCastActionBarFrame and Y.UserClass == 'SHAMAN') then
        if not MultiCastActionBarFrame.numActiveSlots or MultiCastActionBarFrame.numActiveSlots == 0 then
            C_Timer.After(1, function()
                if not InCombatLockdown() then
                    MultiCastActionBarFrame_Update(MultiCastActionBarFrame)
                    self:StyleTotemBar()
                end
            end)
        else
            self:StyleTotemBar()
        end
        --MultiCastActionBarFrame:SetParent(UIParent)
        --MultiCastActionBarFrame:ClearAllPoints()
        --MultiCastActionBarFrame:SetPoint("BOTTOMLEFT", UIParent, 300, 20)
    end
end

-- Black magic, the movers won't budge if a secure frame is positioned on it
local Bar1PreMove = function(self)
    local A1, P, A2, X, Y = self:GetPoint()

    AB.Bar1:Hide()
    AB.Bar1:ClearAllPoints() -- Clear the bar from the mover
    AB.Bar1:SetPoint(A1, Y.UIParent, A2, X, Y)
end

local Bar1PostMove = function(self)
    local A1, P, A2, X, Y = self:GetPoint()

    self:ClearAllPoints()

    AB.Bar1:ClearAllPoints()
    AB.Bar1:SetPoint("CENTER", self, 0, 0) -- Position the frame to the mover again
    AB.Bar1:Show()

    self:SetPoint(A1, Y.UIParent, A2, X, Y)
end

function AB:CreateMovers()
    self.Bar1Mover = Y:CreateMover(self.Bar1)
    Y:CreateMover(self.Bar2)
    Y:CreateMover(self.Bar3)
    Y:CreateMover(self.Bar4)
    Y:CreateMover(self.Bar5)

    if self.Bar6 then
        Y:CreateMover(self.Bar6)
        Y:CreateMover(self.Bar7)
        Y:CreateMover(self.Bar8)
    end

    if self.StanceBar and not C["ab-stance-position-bar"] then
        Y:CreateMover(self.StanceBar)
    end

    if self.PetBar then
        Y:CreateMover(self.PetBar)
    end

    if self.TotemBar then
        Y:CreateMover(self.TotemBar)
    end

    if Y.IsMainline or Y.IsMists then -- Temporarily disabling the mover on Mists, causing issues
	--if ExtraActionButton1 then
        self.ExtraBarMover = Y:CreateMover(self.ExtraBar)
    end

    self.Bar1Mover.PreMove = Bar1PreMove
    self.Bar1Mover.PostMove = Bar1PostMove
end

function AB:SetCVars()
    C_CVar.SetCVar("showgrid", 1)
end

function AB:UpdateFlyout()
    if (not self.FlyoutArrow) then
        return
    end

    if (SpellFlyout and SpellFlyout:IsShown()) then
        SpellFlyout.BgEnd:SetTexture()
        SpellFlyout.HorizBg:SetTexture()
        SpellFlyout.VertBg:SetTexture()
    end

    if self.FlyoutBorder then
        self.FlyoutBorder:SetTexture()
        self.FlyoutBorderShadow:SetTexture()
    end

    for i = 1, 8 do
        local Button = _G["SpellFlyoutButton" .. i]

        if Button then
            AB:StylePetActionButton(Button)

            if Button.GlyphIcon then
                Button.GlyphIcon:ClearAllPoints()
                Button.GlyphIcon:SetPoint("TOPRIGHT", Button, 2, 2)
            end
        end
    end
end

function AB:UpdateEmptyButtons()
    if C["ab-show-empty"] then
        for i = 1, #ActionBars do
            for j = 1, 12 do
                local Button = _G[ActionBars[i] .. j]

                if Button then
                    if Button.ShowGrid then
                        Button:ShowGrid(ACTION_BUTTON_SHOW_GRID_REASON_EVENT)
                    end

                    if Y.IsMainline then
                        Button:SetAttribute("showgrid", 1)
                    else
                        Button:SetAttribute("showgrid", 2)
                        ActionButton_ShowGrid(Button)
                    end
                end
            end
        end
    else
        for i = 1, #ActionBars do
            for j = 1, 12 do
                local Button = _G[ActionBars[i] .. j]

                if Button then
                    Button:SetAttribute("showgrid", 0)

                    if Button.HideGrid then
                        Button:HideGrid(ACTION_BUTTON_SHOW_GRID_REASON_EVENT)
                    end
                end
            end
        end
    end
end

local MultiCastSummonSpellButton_Update = function()
    for i = 1, 12 do
        local Slot = _G["MultiCastSlotButton" .. i]
        local Button = _G["MultiCastActionButton" .. i]
        Button:ClearAllPoints()

        if (i % 4) == 1 then
            Button:SetPoint("LEFT", MultiCastSummonSpellButton, "RIGHT", 5, 0)
        else
            Button:SetPoint("LEFT", _G["MultiCastActionButton" .. i - 1], "RIGHT", 5, 0)
        end
    end
end
local MultiCastRecallSpellButton_Update = function()
    MultiCastRecallSpellButton:ClearAllPoints()
    MultiCastRecallSpellButton:SetPoint("LEFT", MultiCastActionButton4, "RIGHT", 5, 0)
end

local MultiCastFlyoutFrame_ToggleFlyout = function(frame, type, parent)
    for i = 1, #frame.buttons do
        local FlyoutButton = frame.buttons[i]

        if (not FlyoutButton) then
            return
        end

        if not FlyoutButton.YxUIBorder then
            FlyoutButton:SkinButton()
            FlyoutButton:SetSize(30, 30)

            if FlyoutButton.Border then
                FlyoutButton.Border:SetTexture(nil)
            end
        end

        if (FlyoutButton.icon and i ~= 1) then
            FlyoutButton.icon:ClearAllPoints()
            FlyoutButton.icon:SetPoint("TOPLEFT", FlyoutButton, 0, 0)
            FlyoutButton.icon:SetPoint("BOTTOMRIGHT", FlyoutButton, 0, 0)
            FlyoutButton.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        end

        if _G[FlyoutButton:GetName() .. "FloatingBG"] then
            AB:Disable(_G[FlyoutButton:GetName() .. "FloatingBG"])
        end

        FlyoutButton:ClearAllPoints()

        if (i == 1) then
            FlyoutButton:SetPoint("BOTTOM", MultiCastFlyoutFrame, 0, 5)
        else
            FlyoutButton:SetPoint("BOTTOM", _G["MultiCastFlyoutButton" .. i - 1], "TOP", 0, 5)
        end
        if FlyoutButton:IsShown() then
            MultiCastFlyoutFrameCloseButton:ClearAllPoints()
            MultiCastFlyoutFrameCloseButton:SetPoint("BOTTOM", FlyoutButton, "TOP", 0, -3)
        end
    end
end

function AB:UpdateTotemBarPosition()
    if not self.TotemBar then
        return
    end
    self.TotemBar:ClearAllPoints()
    if C["ab-stance-position-bar"] then
        if C["ab-bar3-enable"] then
            self.TotemBar:SetPoint("BOTTOMLEFT", self.Bar3, 'TOPLEFT', 0, 5)
        elseif C["ab-bar2-enable"] then
            self.TotemBar:SetPoint("BOTTOMLEFT", self.Bar2, 'TOPLEFT', 0, 5)
        elseif C["ab-bar1-enable"] then
            self.TotemBar:SetPoint("BOTTOMLEFT", self.Bar1, 'TOPLEFT', 0, 5)
        else
            self.TotemBar:SetPoint("BOTTOMLEFT", Y.UIParent, 408, 13)
        end
    else
        self.TotemBar:SetPoint("BOTTOMLEFT", Y.UIParent, 408, 13)
    end
end

function AB:StyleTotemBar()
    self.TotemBar = CreateFrame("Frame", "YxUI Totem Bar", Y.UIParent, "SecureHandlerStateTemplate")
    self.TotemBar:SetSize((30 * 6) + (2 * 5), 30)
    self:UpdateTotemBarPosition()

    MultiCastActionBarFrame:SetParent(self.TotemBar)
    MultiCastSummonSpellButton:SetParent(self.TotemBar)
    MultiCastSummonSpellButton:ClearAllPoints()
    MultiCastSummonSpellButton:SetPoint("LEFT", self.TotemBar, 0, 0)

    self:StyleActionButton(MultiCastSummonSpellButton)

    MultiCastSummonSpellButtonHighlight:SetTexture(nil)

    for i = 1, 4 do
        local Slot = _G["MultiCastSlotButton" .. i]

        Slot:SetParent(MultiCastActionBarFrame)

        Slot.background:ClearAllPoints()
        Slot.background:SetPoint("TOPLEFT", Slot, 1, -1)
        Slot.background:SetPoint("BOTTOMRIGHT", Slot, -1, 1)
        Slot.background:SetDrawLayer("BACKGROUND", -1)
        Slot.overlayTex:SetTexture(nil) -- Colored border

        Slot:ClearAllPoints()

        if (i == 1) then
            Slot:SetPoint("LEFT", MultiCastSummonSpellButton, "RIGHT", 5, 0)
        else
            Slot:SetPoint("LEFT", _G["MultiCastSlotButton" .. i - 1], "RIGHT", 5, 0)
        end
    end

    for i = 1, 12 do
        local Button = _G["MultiCastActionButton" .. i]

        self:StyleActionButton(Button)

        --Button:SetParent(MultiCastActionBarFrame)
        Button:ClearAllPoints()
        Button.overlayTex:SetTexture(nil)

        --Button.Backdrop:SetFrameStrata("BACKGROUND")

        --Button:ClearAllPoints()

        if (i % 4) == 1 then
            Button:SetPoint("LEFT", MultiCastSummonSpellButton, "RIGHT", 5, 0)
        else
            Button:SetPoint("LEFT", _G["MultiCastActionButton" .. i - 1], "RIGHT", 5, 0)
        end
    end

    MultiCastRecallSpellButton:SetParent(self.TotemBar)
    self:StyleActionButton(MultiCastRecallSpellButton)
    MultiCastRecallSpellButton:ClearAllPoints()
    MultiCastRecallSpellButton:SetPoint("LEFT", MultiCastSlotButton4, "RIGHT", 5, 0)

    MultiCastRecallSpellButtonHighlight:SetTexture(nil)

    MultiCastFlyoutFrame.top:SetTexture(nil)
    MultiCastFlyoutFrame.middle:SetTexture(nil)

    hooksecurefunc("MultiCastSummonSpellButton_Update", MultiCastSummonSpellButton_Update)
    hooksecurefunc("MultiCastRecallSpellButton_Update", MultiCastRecallSpellButton_Update)
    hooksecurefunc("MultiCastFlyoutFrame_ToggleFlyout", MultiCastFlyoutFrame_ToggleFlyout)
    self.TotemBar.frameVisibility = "[petbattle][overridebar][vehicleui][possessbar,@vehicle,exists][shapeshift] hide; show"
    if C["ab-totem-enable"] then
        self:EnableBar(self.TotemBar)
    else
        self:DisableBar(self.TotemBar)
    end
end

local GetBarHeight = function()
    return 0
end

function AB:Load()
    if (not C["ab-enable"]) then
        return
    end

    self.Hide = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
    self.Hide:Hide()

    SetActionBarToggles(1, 1, 1, 1, 1, 1, 1, 1)

    self:SetCVars()
    self:Disable(MainMenuBar)
    self:CreateBars()
    self:CreateMovers()
    self:UpdateEmptyButtons()

    if Y.IsMainline then
        MainMenuBar.GetBottomAnchoredHeight = GetBarHeight
        OverrideActionBar.GetBottomAnchoredHeight = GetBarHeight
        MultiBarBottomLeft.GetBottomAnchoredHeight = GetBarHeight
        MultiBarBottomRight.GetBottomAnchoredHeight = GetBarHeight
        StanceBar.GetBottomAnchoredHeight = GetBarHeight
        PetActionBar.GetBottomAnchoredHeight = GetBarHeight
        PossessActionBar.GetBottomAnchoredHeight = GetBarHeight
        MainMenuBarVehicleLeaveButton.GetBottomAnchoredHeight = GetBarHeight

        MultiBarLeft.IsInDefaultPosition = function() return false end
        MultiBarRight.IsInDefaultPosition = function() return false end

        if EditModeManagerFrame then
            EditModeManagerFrame.UpdateBottomActionBarPositions = function() end
            EditModeManagerFrame.UpdateRightActionBarPositions = function() end
        end
    end

    hooksecurefunc("ActionButton_UpdateRangeIndicator", AB.UpdateButtonStatus)

    if ActionButton_UpdateFlyout then
        hooksecurefunc("ActionButton_UpdateFlyout", AB.UpdateFlyout)
    end

    if ActionButton_Update then
        hooksecurefunc("ActionButton_Update", AB.UpdateButtonStatus)
    end
end

local UpdateBar1 = function()
    AB:PositionButtons(AB.Bar1, C["ab-bar1-button-max"], C["ab-bar1-per-row"], C["ab-bar1-button-size"], C["ab-bar1-button-gap"])
end

local UpdateBar2 = function()
    AB:PositionButtons(AB.Bar2, C["ab-bar2-button-max"], C["ab-bar2-per-row"], C["ab-bar2-button-size"], C["ab-bar2-button-gap"])
end

local UpdateBar3 = function()
    AB:PositionButtons(AB.Bar3, C["ab-bar3-button-max"], C["ab-bar3-per-row"], C["ab-bar3-button-size"], C["ab-bar3-button-gap"])
end

local UpdateBar4 = function()
    AB:PositionButtons(AB.Bar4, C["ab-bar4-button-max"], C["ab-bar4-per-row"], C["ab-bar4-button-size"], C["ab-bar4-button-gap"])
end

local UpdateBar5 = function()
    AB:PositionButtons(AB.Bar5, C["ab-bar5-button-max"], C["ab-bar5-per-row"], C["ab-bar5-button-size"], C["ab-bar5-button-gap"])
end

local UpdateBar6 = function()
    AB:PositionButtons(AB.Bar6, C["ab-bar6-button-max"], C["ab-bar6-per-row"], C["ab-bar6-button-size"], C["ab-bar6-button-gap"])
end

local UpdateBar7 = function()
    AB:PositionButtons(AB.Bar7, C["ab-bar7-button-max"], C["ab-bar7-per-row"], C["ab-bar7-button-size"], C["ab-bar7-button-gap"])
end

local UpdateBar8 = function()
    AB:PositionButtons(AB.Bar8, C["ab-bar8-button-max"], C["ab-bar8-per-row"], C["ab-bar8-button-size"], C["ab-bar8-button-gap"])
end

local UpdatePetBar = function()
    AB:PositionButtons(AB.PetBar, NUM_PET_ACTION_SLOTS, C["ab-pet-per-row"], C["ab-pet-button-size"], C["ab-pet-button-gap"])

    for i = 1, #AB.PetBar do
        local Name = AB.PetBar[i]:GetName()

        if _G[Name .. "AutoCastable"] then
            _G[Name .. "AutoCastable"]:SetSize(C["ab-pet-button-size"] * 2 - 4, C["ab-pet-button-size"] * 2 - 4)
        end
    end
end

local UpdateStanceBar = function()
    AB:PositionButtons(AB.StanceBar, #AB.StanceBar, C["ab-stance-per-row"], C["ab-stance-button-size"], C["ab-stance-button-gap"])
end

local UpdateEnableBar1 = function(value)
    if value then
        AB:EnableBar(AB.Bar1)
    else
        AB:DisableBar(AB.Bar1)
    end
    AB:UpdateStanceBarPosition()
    AB:UpdateTotemBarPosition()
end

local UpdateEnableBar2 = function(value)
    if value then
        AB:EnableBar(AB.Bar2)
    else
        AB:DisableBar(AB.Bar2)
    end
    AB:UpdateStanceBarPosition()
    AB:UpdateTotemBarPosition()
end

local UpdateEnableBar3 = function(value)
    if value then
        AB:EnableBar(AB.Bar3)
    else
        AB:DisableBar(AB.Bar3)
    end
    AB:UpdateStanceBarPosition()
    AB:UpdateTotemBarPosition()
end

local UpdateEnableBar4 = function(value)
    if value then
        AB:EnableBar(AB.Bar4)
    else
        AB:DisableBar(AB.Bar4)
    end
    AB:UpdatePetBarPosition()
end

local UpdateEnableBar5 = function(value)
    if value then
        AB:EnableBar(AB.Bar5)
    else
        AB:DisableBar(AB.Bar5)
    end
    AB:UpdatePetBarPosition()
end

local UpdateEnableBar6 = function(value)
    if value then
        AB:EnableBar(AB.Bar6)
    else
        AB:DisableBar(AB.Bar6)
    end
end

local UpdateEnableBar7 = function(value)
    if value then
        AB:EnableBar(AB.Bar7)
    else
        AB:DisableBar(AB.Bar7)
    end
end

local UpdateEnableBar8 = function(value)
    if value then
        AB:EnableBar(AB.Bar8)
    else
        AB:DisableBar(AB.Bar8)
    end
end

local UpdateEnablePetBar = function(value)
    if value then
        AB:EnableBar(AB.PetBar)
    else
        AB:DisableBar(AB.PetBar)
    end
end

local UpdateEnableStanceBar = function(value)
    if value then
        AB:EnableBar(AB.StanceBar)
    else
        AB:DisableBar(AB.StanceBar)
    end
end

local UpdateAutoPositionStanceBar = function(value)
    AB:UpdateStanceBarPosition()
    AB:UpdateTotemBarPosition()
end

local UpdateEnableTotemBar = function(value)
    if value then
        AB:EnableBar(AB.TotemBar)
    else
        AB:DisableBar(AB.TotemBar)
    end
end

local UpdateShowHotKey = function(value)
    if value then
        for i = 1, 12 do
            AB.Bar1[i].HotKey:SetAlpha(1)
            AB.Bar2[i].HotKey:SetAlpha(1)
            AB.Bar3[i].HotKey:SetAlpha(1)
            AB.Bar4[i].HotKey:SetAlpha(1)
            AB.Bar5[i].HotKey:SetAlpha(1)

            if AB.Bar6 then
                AB.Bar6[i].HotKey:SetAlpha(1)
                AB.Bar7[i].HotKey:SetAlpha(1)
                AB.Bar8[i].HotKey:SetAlpha(1)
            end

            if AB.PetBar[i] then
                AB.PetBar[i].HotKey:SetAlpha(1)
            end

            if AB.StanceBar[i] then
                AB.StanceBar[i].HotKey:SetAlpha(1)
            end
        end

        if ExtraActionButton1 then
            ExtraActionButton1.HotKey:SetAlpha(1)
        end
    else
        for i = 1, 12 do
            AB.Bar1[i].HotKey:SetAlpha(0)
            AB.Bar2[i].HotKey:SetAlpha(0)
            AB.Bar3[i].HotKey:SetAlpha(0)
            AB.Bar4[i].HotKey:SetAlpha(0)
            AB.Bar5[i].HotKey:SetAlpha(0)

            if AB.Bar6 then
                AB.Bar6[i].HotKey:SetAlpha(1)
                AB.Bar7[i].HotKey:SetAlpha(1)
                AB.Bar8[i].HotKey:SetAlpha(1)
            end

            if AB.PetBar[i] then
                AB.PetBar[i].HotKey:SetAlpha(0)
            end

            if AB.StanceBar[i] then
                AB.StanceBar[i].HotKey:SetAlpha(0)
            end
        end

        if ExtraActionButton1 then
            ExtraActionButton1.HotKey:SetAlpha(0)
        end
    end
end

local UpdateShowMacroName = function(value)
    if value then
        for i = 1, 12 do
            AB.Bar1[i].Name:SetAlpha(1)
            AB.Bar2[i].Name:SetAlpha(1)
            AB.Bar3[i].Name:SetAlpha(1)
            AB.Bar4[i].Name:SetAlpha(1)
            AB.Bar5[i].Name:SetAlpha(1)

            if AB.Bar6 then
                AB.Bar6[i].HotKey:SetAlpha(1)
                AB.Bar7[i].HotKey:SetAlpha(1)
                AB.Bar8[i].HotKey:SetAlpha(1)
            end
        end
    else
        for i = 1, 12 do
            AB.Bar1[i].Name:SetAlpha(0)
            AB.Bar2[i].Name:SetAlpha(0)
            AB.Bar3[i].Name:SetAlpha(0)
            AB.Bar4[i].Name:SetAlpha(0)
            AB.Bar5[i].Name:SetAlpha(0)

            if AB.Bar6 then
                AB.Bar6[i].HotKey:SetAlpha(1)
                AB.Bar7[i].HotKey:SetAlpha(1)
                AB.Bar8[i].HotKey:SetAlpha(1)
            end
        end
    end
end

local UpdateShowCount = function(value)
    if value then
        for i = 1, 12 do
            AB.Bar1[i].Count:SetAlpha(1)
            AB.Bar2[i].Count:SetAlpha(1)
            AB.Bar3[i].Count:SetAlpha(1)
            AB.Bar4[i].Count:SetAlpha(1)
            AB.Bar5[i].Count:SetAlpha(1)

            if AB.Bar6 then
                AB.Bar6[i].HotKey:SetAlpha(1)
                AB.Bar7[i].HotKey:SetAlpha(1)
                AB.Bar8[i].HotKey:SetAlpha(1)
            end
        end
    else
        for i = 1, 12 do
            AB.Bar1[i].Count:SetAlpha(0)
            AB.Bar2[i].Count:SetAlpha(0)
            AB.Bar3[i].Count:SetAlpha(0)
            AB.Bar4[i].Count:SetAlpha(0)
            AB.Bar5[i].Count:SetAlpha(0)

            if AB.Bar6 then
                AB.Bar6[i].HotKey:SetAlpha(1)
                AB.Bar7[i].HotKey:SetAlpha(1)
                AB.Bar8[i].HotKey:SetAlpha(1)
            end
        end
    end
end

function AB:UpdateButtonFont(button)
    if button.HotKey then
        Y:SetFontInfo(button.HotKey, C["ab-font"], C["ab-font-size"], C["ab-font-flags"])
    end

    if button.Name then
        Y:SetFontInfo(button.Name, C["ab-font"], C["ab-font-size"], C["ab-font-flags"])
    end

    if button.Count then
        Y:SetFontInfo(button.Count, C["ab-font"], C["ab-font-size"], C["ab-font-flags"])
    end

    if button.cooldown then
        local Cooldown = button.cooldown:GetRegions()

        if Cooldown then
            Y:SetFontInfo(Cooldown, C["ab-font"], C["ab-cd-size"], C["ab-font-flags"])
        end
    end
end

local UpdateActionBarFont = function()
    for i = 1, 12 do
        AB:UpdateButtonFont(AB.Bar1[i])
        AB:UpdateButtonFont(AB.Bar2[i])
        AB:UpdateButtonFont(AB.Bar3[i])
        AB:UpdateButtonFont(AB.Bar4[i])
        AB:UpdateButtonFont(AB.Bar5[i])

        if AB.Bar6 then
            AB:UpdateButtonFont(AB.Bar6[i])
            AB:UpdateButtonFont(AB.Bar7[i])
            AB:UpdateButtonFont(AB.Bar8[i])
        end

        if AB.PetBar[i] then
            AB:UpdateButtonFont(AB.PetBar[i])
        end

        if AB.StanceBar[i] then
            AB:UpdateButtonFont(AB.StanceBar[i])
        end
    end
end

local UpdateBar1Hover = function(value)
    AB.Bar1.ShouldFade = value

    if value then
        AB.Bar1:SetAlpha(0)
        AB.Bar1:SetScript("OnEnter", BarOnEnter)
        AB.Bar1:SetScript("OnLeave", BarOnLeave)

        for i = 1, #AB.Bar1 do
            AB.Bar1[i].cooldown:SetDrawBling(false)
        end
    else
        AB.Bar1:SetAlpha(1)
        AB.Bar1:SetScript("OnEnter", nil)
        AB.Bar1:SetScript("OnLeave", nil)

        for i = 1, #AB.Bar1 do
            AB.Bar1[i].cooldown:SetDrawBling(true)
        end
    end
end

local UpdateBar2Hover = function(value)
    AB.Bar2.ShouldFade = value

    if value then
        AB.Bar2:SetAlpha(0)
        AB.Bar2:SetScript("OnEnter", BarOnEnter)
        AB.Bar2:SetScript("OnLeave", BarOnLeave)

        for i = 1, #AB.Bar2 do
            AB.Bar2[i].cooldown:SetDrawBling(false)
        end
    else
        AB.Bar2:SetAlpha(1)
        AB.Bar2:SetScript("OnEnter", nil)
        AB.Bar2:SetScript("OnLeave", nil)

        for i = 1, #AB.Bar2 do
            AB.Bar2[i].cooldown:SetDrawBling(true)
        end
    end
end

local UpdateBar3Hover = function(value)
    AB.Bar3.ShouldFade = value

    if value then
        AB.Bar3:SetAlpha(0)
        AB.Bar3:SetScript("OnEnter", BarOnEnter)
        AB.Bar3:SetScript("OnLeave", BarOnLeave)

        for i = 1, #AB.Bar3 do
            AB.Bar3[i].cooldown:SetDrawBling(false)
        end
    else
        AB.Bar3:SetAlpha(1)
        AB.Bar3:SetScript("OnEnter", nil)
        AB.Bar3:SetScript("OnLeave", nil)

        for i = 1, #AB.Bar3 do
            AB.Bar3[i].cooldown:SetDrawBling(true)
        end
    end
end

local UpdateBar4Hover = function(value)
    AB.Bar4.ShouldFade = value

    if value then
        AB.Bar4:SetAlpha(0)
        AB.Bar4:SetScript("OnEnter", BarOnEnter)
        AB.Bar4:SetScript("OnLeave", BarOnLeave)

        for i = 1, #AB.Bar4 do
            AB.Bar4[i].cooldown:SetDrawBling(false)
        end
    else
        AB.Bar4:SetAlpha(1)
        AB.Bar4:SetScript("OnEnter", nil)

        for i = 1, #AB.Bar4 do
            AB.Bar4[i].cooldown:SetDrawBling(true)
        end
    end
end

local UpdateBar5Hover = function(value)
    AB.Bar5.ShouldFade = value

    if value then
        AB.Bar5:SetAlpha(0)
        AB.Bar5:SetScript("OnEnter", BarOnEnter)
        AB.Bar5:SetScript("OnLeave", BarOnLeave)

        for i = 1, #AB.Bar5 do
            AB.Bar5[i].cooldown:SetDrawBling(false)
        end
    else
        AB.Bar5:SetAlpha(1)
        AB.Bar5:SetScript("OnEnter", nil)
        AB.Bar5:SetScript("OnLeave", nil)

        for i = 1, #AB.Bar5 do
            AB.Bar5[i].cooldown:SetDrawBling(true)
        end
    end
end

local UpdateBar6Hover = function(value)
    AB.Bar6.ShouldFade = value

    if value then
        AB.Bar6:SetAlpha(0)
        AB.Bar6:SetScript("OnEnter", BarOnEnter)
        AB.Bar6:SetScript("OnLeave", BarOnLeave)

        for i = 1, #AB.Bar6 do
            AB.Bar6[i].cooldown:SetDrawBling(false)
        end
    else
        AB.Bar6:SetAlpha(1)
        AB.Bar6:SetScript("OnEnter", nil)
        AB.Bar6:SetScript("OnLeave", nil)

        for i = 1, #AB.Bar6 do
            AB.Bar6[i].cooldown:SetDrawBling(true)
        end
    end
end

local UpdateBar7Hover = function(value)
    AB.Bar7.ShouldFade = value

    if value then
        AB.Bar7:SetAlpha(0)
        AB.Bar7:SetScript("OnEnter", BarOnEnter)
        AB.Bar7:SetScript("OnLeave", BarOnLeave)

        for i = 1, #AB.Bar7 do
            AB.Bar7[i].cooldown:SetDrawBling(false)
        end
    else
        AB.Bar7:SetAlpha(1)
        AB.Bar7:SetScript("OnEnter", nil)
        AB.Bar7:SetScript("OnLeave", nil)

        for i = 1, #AB.Bar7 do
            AB.Bar7[i].cooldown:SetDrawBling(true)
        end
    end
end

local UpdateBar8Hover = function(value)
    AB.Bar8.ShouldFade = value

    if value then
        AB.Bar8:SetAlpha(0)
        AB.Bar8:SetScript("OnEnter", BarOnEnter)
        AB.Bar8:SetScript("OnLeave", BarOnLeave)

        for i = 1, #AB.Bar8 do
            AB.Bar8[i].cooldown:SetDrawBling(false)
        end
    else
        AB.Bar8:SetAlpha(1)
        AB.Bar8:SetScript("OnEnter", nil)
        AB.Bar8:SetScript("OnLeave", nil)

        for i = 1, #AB.Bar8 do
            AB.Bar8[i].cooldown:SetDrawBling(true)
        end
    end
end

local UpdatePetHover = function(value)
    AB.PetBar.ShouldFade = value

    if value then
        AB.PetBar:SetAlpha(0)
        AB.PetBar:SetScript("OnEnter", BarOnEnter)
        AB.PetBar:SetScript("OnLeave", BarOnLeave)

        for i = 1, #AB.PetBar do
            AB.PetBar[i].cooldown:SetDrawBling(false)
        end
    else
        AB.PetBar:SetAlpha(1)
        AB.PetBar:SetScript("OnEnter", nil)
        AB.PetBar:SetScript("OnLeave", nil)

        for i = 1, #AB.PetBar do
            AB.PetBar[i].cooldown:SetDrawBling(true)
        end
    end
end

local UpdateStanceHover = function(value)
    AB.StanceBar.ShouldFade = value

    if value then
        AB.StanceBar:SetAlpha(0)
        AB.StanceBar:SetScript("OnEnter", BarOnEnter)
        AB.StanceBar:SetScript("OnLeave", BarOnLeave)

        for i = 1, #AB.StanceBar do
            AB.StanceBar[i].cooldown:SetDrawBling(false)
        end
    else
        AB.StanceBar:SetAlpha(1)
        AB.StanceBar:SetScript("OnEnter", nil)
        AB.StanceBar:SetScript("OnLeave", nil)

        for i = 1, #AB.StanceBar do
            AB.StanceBar[i].cooldown:SetDrawBling(true)
        end
    end
end

local UpdateEmptyButtons = function()
    AB:UpdateEmptyButtons()
end

local UpdateBar1Alpha = function(value)
    AB.Bar1.MaxAlpha = value
    AB.Bar1:SetAlpha(value / 100)
end

local UpdateBar2Alpha = function(value)
    AB.Bar2.MaxAlpha = value
    AB.Bar2:SetAlpha(value / 100)
end

local UpdateBar3Alpha = function(value)
    AB.Bar3.MaxAlpha = value
    AB.Bar3:SetAlpha(value / 100)
end

local UpdateBar4Alpha = function(value)
    AB.Bar4.MaxAlpha = value
    AB.Bar4:SetAlpha(value / 100)
end

local UpdateBar5Alpha = function(value)
    AB.Bar5.MaxAlpha = value
    AB.Bar5:SetAlpha(value / 100)
end

local UpdateBar6Alpha = function(value)
    AB.Bar6.MaxAlpha = value
    AB.Bar6:SetAlpha(value / 100)
end

local UpdateBar7Alpha = function(value)
    AB.Bar7.MaxAlpha = value
    AB.Bar7:SetAlpha(value / 100)
end

local UpdateBar8Alpha = function(value)
    AB.Bar8.MaxAlpha = value
    AB.Bar8:SetAlpha(value / 100)
end

local UpdatePetBarAlpha = function(value)
    AB.PetBar.MaxAlpha = value
    AB.PetBar:SetAlpha(value / 100)
end

local UpdateStanceBarAlpha = function(value)
    AB.StanceBar.MaxAlpha = value
    AB.StanceBar:SetAlpha(value / 100)
end

GUI:AddWidgets(L["General"], L["Action Bars"], function(left, right)
    left:CreateHeader(L["Enable"])
    left:CreateSwitch("ab-enable", C["ab-enable"], L["Enable Action Bar"], L["Enable action bars module"], ReloadUI):RequiresReload(true)

    left:CreateHeader(L["Styling"])
    left:CreateSwitch("ab-show-hotkey", C["ab-show-hotkey"], L["Show Hotkeys"], L["Display hotkey text on action buttons"], UpdateShowHotKey)
    left:CreateSwitch("ab-show-macro", C["ab-show-macro"], L["Show Macro Names"], L["Display macro name text on action buttons"], UpdateShowMacroName)
    left:CreateSwitch("ab-show-count", C["ab-show-count"], L["Show Count Text"], L["Display count text on action buttons"], UpdateShowCount)

    left:CreateHeader(L["Font"])
    left:CreateDropdown("ab-font", C["ab-font"], A:GetFontList(), L["Font"], L["Set the font of the action bar buttons"], UpdateActionBarFont, "Font")
    left:CreateSlider("ab-font-size", C["ab-font-size"], 8, 42, 1, L["Font Size"], L["Set the font size of the action bar buttons"], UpdateActionBarFont)
    left:CreateSlider("ab-cd-size", C["ab-cd-size"], 8, 42, 1, L["Cooldown Font Size"], L["Set the font size of the action bar cooldowns"], UpdateActionBarFont)
    left:CreateDropdown("ab-font-flags", C["ab-font-flags"], A:GetFlagsList(), L["Font Flags"], L["Set the font flags of the action bar buttons"], UpdateActionBarFont)
end)

GUI:AddWidgets(L["General"], L["Bar 1"], L["Action Bars"], function(left, right)
    left:CreateHeader(L["Enable"])
    left:CreateSwitch("ab-bar1-enable", C["ab-bar1-enable"], L["Enable Bar"], L["Enable action bar 1"], UpdateEnableBar1)

    left:CreateHeader(L["Styling"])
    left:CreateSwitch("ab-bar1-hover", C["ab-bar1-hover"], L["Set Mouseover"], L["Only display the bar while hovering over it"], UpdateBar1Hover)
    left:CreateSlider("ab-bar1-alpha", C["ab-bar1-alpha"], 0, 100, 5, L["Bar Opacity"], L["Set the opacity of the action bar"], UpdateBar1Alpha)

    right:CreateHeader(L["Buttons"])
    right:CreateSlider("ab-bar1-per-row", C["ab-bar1-per-row"], 1, 12, 1, L["Buttons Per Row"], L["Set the number of buttons per row"], UpdateBar1)
    right:CreateSlider("ab-bar1-button-max", C["ab-bar1-button-max"], 1, 12, 1, L["Max Buttons"], L["Set the number of buttons displayed on the action bar"], UpdateBar1)
    right:CreateSlider("ab-bar1-button-size", C["ab-bar1-button-size"], 20, 50, 1, L["Button Size"], L["Set the action button size"], UpdateBar1)
    right:CreateSlider("ab-bar1-button-gap", C["ab-bar1-button-gap"], -1, 8, 1, L["Button Spacing"], L["Set the spacing between action buttons"], UpdateBar1)
end)

GUI:AddWidgets(L["General"], L["Bar 2"], L["Action Bars"], function(left, right)
    left:CreateHeader(L["Enable"])
    left:CreateSwitch("ab-bar2-enable", C["ab-bar2-enable"], L["Enable Bar"], L["Enable action bar 2"], UpdateEnableBar2)

    left:CreateHeader(L["Styling"])
    left:CreateSwitch("ab-bar2-hover", C["ab-bar2-hover"], L["Set Mouseover"], L["Only display the bar while hovering over it"], UpdateBar2Hover)
    left:CreateSlider("ab-bar2-alpha", C["ab-bar2-alpha"], 0, 100, 5, L["Bar Opacity"], L["Set the opacity of the action bar"], UpdateBar2Alpha)

    right:CreateHeader(L["Buttons"])
    right:CreateSlider("ab-bar2-per-row", C["ab-bar2-per-row"], 1, 12, 1, L["Buttons Per Row"], L["Set the number of buttons per row"], UpdateBar2)
    right:CreateSlider("ab-bar2-button-max", C["ab-bar2-button-max"], 1, 12, 1, L["Max Buttons"], L["Set the number of buttons displayed on the action bar"], UpdateBar2)
    right:CreateSlider("ab-bar2-button-size", C["ab-bar2-button-size"], 20, 50, 1, L["Button Size"], L["Set the action button size"], UpdateBar2)
    right:CreateSlider("ab-bar2-button-gap", C["ab-bar2-button-gap"], -1, 8, 1, L["Button Spacing"], L["Set the spacing between action buttons"], UpdateBar2)
end)

GUI:AddWidgets(L["General"], L["Bar 3"], L["Action Bars"], function(left, right)
    left:CreateHeader(L["Enable"])
    left:CreateSwitch("ab-bar3-enable", C["ab-bar3-enable"], L["Enable Bar"], L["Enable action bar 3"], UpdateEnableBar3)

    left:CreateHeader(L["Styling"])
    left:CreateSwitch("ab-bar3-hover", C["ab-bar3-hover"], L["Set Mouseover"], L["Only display the bar while hovering over it"], UpdateBar3Hover)
    left:CreateSlider("ab-bar3-alpha", C["ab-bar3-alpha"], 0, 100, 5, L["Bar Opacity"], L["Set the opacity of the action bar"], UpdateBar3Alpha)

    right:CreateHeader(L["Buttons"])
    right:CreateSlider("ab-bar3-per-row", C["ab-bar3-per-row"], 1, 12, 1, L["Buttons Per Row"], L["Set the number of buttons per row"], UpdateBar3)
    right:CreateSlider("ab-bar3-button-max", C["ab-bar3-button-max"], 1, 12, 1, L["Max Buttons"], L["Set the number of buttons displayed on the action bar"], UpdateBar3)
    right:CreateSlider("ab-bar3-button-size", C["ab-bar3-button-size"], 20, 50, 1, L["Button Size"], L["Set the action button size"], UpdateBar3)
    right:CreateSlider("ab-bar3-button-gap", C["ab-bar3-button-gap"], -1, 8, 1, L["Button Spacing"], L["Set the spacing between action buttons"], UpdateBar3)
end)

GUI:AddWidgets(L["General"], L["Bar 4"], L["Action Bars"], function(left, right)
    left:CreateHeader(L["Enable"])
    left:CreateSwitch("ab-bar4-enable", C["ab-bar4-enable"], L["Enable Bar"], L["Enable action bar 4"], UpdateEnableBar4)

    left:CreateHeader(L["Styling"])
    left:CreateSwitch("ab-bar4-hover", C["ab-bar4-hover"], L["Set Mouseover"], L["Only display the bar while hovering over it"], UpdateBar4Hover)
    left:CreateSlider("ab-bar4-alpha", C["ab-bar4-alpha"], 0, 100, 5, L["Bar Opacity"], L["Set the opacity of the action bar"], UpdateBar4Alpha)

    right:CreateHeader(L["Buttons"])
    right:CreateSlider("ab-bar4-per-row", C["ab-bar4-per-row"], 1, 12, 1, L["Buttons Per Row"], L["Set the number of buttons per row"], UpdateBar4)
    right:CreateSlider("ab-bar4-button-max", C["ab-bar4-button-max"], 1, 12, 1, L["Max Buttons"], L["Set the number of buttons displayed on the action bar"], UpdateBar4)
    right:CreateSlider("ab-bar4-button-size", C["ab-bar4-button-size"], 20, 50, 1, L["Button Size"], L["Set the action button size"], UpdateBar4)
    right:CreateSlider("ab-bar4-button-gap", C["ab-bar4-button-gap"], -1, 8, 1, L["Button Spacing"], L["Set the spacing between action buttons"], UpdateBar4)
end)

GUI:AddWidgets(L["General"], L["Bar 5"], L["Action Bars"], function(left, right)
    left:CreateHeader(L["Enable"])
    left:CreateSwitch("ab-bar5-enable", C["ab-bar5-enable"], L["Enable Bar"], L["Enable action bar 5"], UpdateEnableBar5)

    left:CreateHeader(L["Styling"])
    left:CreateSwitch("ab-bar5-hover", C["ab-bar5-hover"], L["Set Mouseover"], L["Only display the bar while hovering over it"], UpdateBar5Hover)
    left:CreateSlider("ab-bar5-alpha", C["ab-bar5-alpha"], 0, 100, 5, L["Bar Opacity"], L["Set the opacity of the action bar"], UpdateBar5Alpha)

    right:CreateHeader(L["Buttons"])
    right:CreateSlider("ab-bar5-per-row", C["ab-bar5-per-row"], 1, 12, 1, L["Buttons Per Row"], L["Set the number of buttons per row"], UpdateBar5)
    right:CreateSlider("ab-bar5-button-max", C["ab-bar5-button-max"], 1, 12, 1, L["Max Buttons"], L["Set the number of buttons displayed on the action bar"], UpdateBar5)
    right:CreateSlider("ab-bar5-button-size", C["ab-bar5-button-size"], 20, 50, 1, L["Button Size"], L["Set the action button size"], UpdateBar5)
    right:CreateSlider("ab-bar5-button-gap", C["ab-bar5-button-gap"], -1, 8, 1, L["Button Spacing"], L["Set the spacing between action buttons"], UpdateBar5)
end)

if Y.IsMainline then
    GUI:AddWidgets(L["General"], L["Bar 6"], L["Action Bars"], function(left, right)
        left:CreateHeader(L["Enable"])
        left:CreateSwitch("ab-bar6-enable", C["ab-bar6-enable"], L["Enable Bar"], L["Enable action bar 6"], UpdateEnableBar6)

        left:CreateHeader(L["Styling"])
        left:CreateSwitch("ab-bar6-hover", C["ab-bar6-hover"], L["Set Mouseover"], L["Only display the bar while hovering over it"], UpdateBar6Hover)
        left:CreateSlider("ab-bar6-alpha", C["ab-bar6-alpha"], 0, 100, 5, L["Bar Opacity"], L["Set the opacity of the action bar"], UpdateBar6Alpha)

        right:CreateHeader(L["Buttons"])
        right:CreateSlider("ab-bar6-per-row", C["ab-bar6-per-row"], 1, 12, 1, L["Buttons Per Row"], L["Set the number of buttons per row"], UpdateBar6)
        right:CreateSlider("ab-bar6-button-max", C["ab-bar6-button-max"], 1, 12, 1, L["Max Buttons"], L["Set the number of buttons displayed on the action bar"], UpdateBar6)
        right:CreateSlider("ab-bar6-button-size", C["ab-bar6-button-size"], 20, 50, 1, L["Button Size"], L["Set the action button size"], UpdateBar6)
        right:CreateSlider("ab-bar6-button-gap", C["ab-bar6-button-gap"], -1, 8, 1, L["Button Spacing"], L["Set the spacing between action buttons"], UpdateBar6)
    end)

    GUI:AddWidgets(L["General"], L["Bar 7"], L["Action Bars"], function(left, right)
        left:CreateHeader(L["Enable"])
        left:CreateSwitch("ab-bar7-enable", C["ab-bar7-enable"], L["Enable Bar"], L["Enable action bar 7"], UpdateEnableBar7)

        left:CreateHeader(L["Styling"])
        left:CreateSwitch("ab-bar7-hover", C["ab-bar7-hover"], L["Set Mouseover"], L["Only display the bar while hovering over it"], UpdateBar7Hover)
        left:CreateSlider("ab-bar7-alpha", C["ab-bar7-alpha"], 0, 100, 5, L["Bar Opacity"], L["Set the opacity of the action bar"], UpdateBar7Alpha)

        right:CreateHeader(L["Buttons"])
        right:CreateSlider("ab-bar7-per-row", C["ab-bar7-per-row"], 1, 12, 1, L["Buttons Per Row"], L["Set the number of buttons per row"], UpdateBar7)
        right:CreateSlider("ab-bar7-button-max", C["ab-bar7-button-max"], 1, 12, 1, L["Max Buttons"], L["Set the number of buttons displayed on the action bar"], UpdateBar7)
        right:CreateSlider("ab-bar7-button-size", C["ab-bar7-button-size"], 20, 50, 1, L["Button Size"], L["Set the action button size"], UpdateBar7)
        right:CreateSlider("ab-bar7-button-gap", C["ab-bar7-button-gap"], -1, 8, 1, L["Button Spacing"], L["Set the spacing between action buttons"], UpdateBar7)
    end)

    GUI:AddWidgets(L["General"], L["Bar 8"], L["Action Bars"], function(left, right)
        left:CreateHeader(L["Enable"])
        left:CreateSwitch("ab-bar8-enable", C["ab-bar8-enable"], L["Enable Bar"], L["Enable action bar 8"], UpdateEnableBar8)

        left:CreateHeader(L["Styling"])
        left:CreateSwitch("ab-bar8-hover", C["ab-bar8-hover"], L["Set Mouseover"], L["Only display the bar while hovering over it"], UpdateBar8Hover)
        left:CreateSlider("ab-bar8-alpha", C["ab-bar8-alpha"], 0, 100, 5, L["Bar Opacity"], L["Set the opacity of the action bar"], UpdateBar8Alpha)

        right:CreateHeader(L["Buttons"])
        right:CreateSlider("ab-bar8-per-row", C["ab-bar8-per-row"], 1, 12, 1, L["Buttons Per Row"], L["Set the number of buttons per row"], UpdateBar8)
        right:CreateSlider("ab-bar8-button-max", C["ab-bar8-button-max"], 1, 12, 1, L["Max Buttons"], L["Set the number of buttons displayed on the action bar"], UpdateBar8)
        right:CreateSlider("ab-bar8-button-size", C["ab-bar8-button-size"], 20, 50, 1, L["Button Size"], L["Set the action button size"], UpdateBar8)
        right:CreateSlider("ab-bar8-button-gap", C["ab-bar8-button-gap"], -1, 8, 1, L["Button Spacing"], L["Set the spacing between action buttons"], UpdateBar8)
    end)
end

GUI:AddWidgets(L["General"], L["Pet Bar"], L["Action Bars"], function(left, right)
    left:CreateHeader(L["Enable"])
    left:CreateSwitch("ab-pet-enable", C["ab-pet-enable"], L["Enable Bar"], L["Enable the pet action bar"], UpdateEnablePetBar)

    left:CreateHeader(L["Styling"])
    left:CreateSwitch("ab-pet-hover", C["ab-pet-hover"], L["Set Mouseover"], L["Only display the bar while hovering over it"], UpdatePetHover)
    left:CreateSlider("ab-pet-alpha", C["ab-pet-alpha"], 0, 100, 5, L["Bar Opacity"], L["Set the opacity of the action bar"], UpdatePetBarAlpha)

    right:CreateHeader(L["Buttons"])
    right:CreateSlider("ab-pet-per-row", C["ab-pet-per-row"], 1, NUM_PET_ACTION_SLOTS, 1, L["Buttons Per Row"], L["Set the number of buttons per row"], UpdatePetBar)
    right:CreateSlider("ab-pet-button-size", C["ab-pet-button-size"], 20, 50, 1, L["Button Size"], L["Set the action button size"], UpdatePetBar)
    right:CreateSlider("ab-pet-button-gap", C["ab-pet-button-gap"], -1, 8, 1, L["Button Spacing"], L["Set the spacing between action buttons"], UpdatePetBar)
end)

GUI:AddWidgets(L["General"], L["Stance Bar"], L["Action Bars"], function(left, right)
    left:CreateHeader(L["Enable"])
    left:CreateSwitch("ab-stance-enable", C["ab-stance-enable"], L["Enable Bar"], L["Enable the stance bar"], UpdateEnableStanceBar)
    left:CreateSwitch("ab-stance-position-bar", C["ab-stance-position-bar"], L["Auto Position"], L["Position is attached to the action bar."], UpdateAutoPositionStanceBar)

    left:CreateHeader(L["Styling"])
    left:CreateSwitch("ab-stance-hover", C["ab-stance-hover"], L["Set Mouseover"], L["Only display the bar while hovering over it"], UpdateStanceHover)
    left:CreateSlider("ab-stance-alpha", C["ab-stance-alpha"], 0, 100, 5, L["Bar Opacity"], L["Set the opacity of the action bar"], UpdateStanceBarAlpha)

    right:CreateHeader(L["Buttons"])
    right:CreateSlider("ab-stance-per-row", C["ab-stance-per-row"], 1, 12, 1, L["Buttons Per Row"], L["Set the number of buttons per row"], UpdateStanceBar)
    right:CreateSlider("ab-stance-button-size", C["ab-stance-button-size"], 20, 50, 1, L["Button Size"], L["Set the action button size"], UpdateStanceBar)
    right:CreateSlider("ab-stance-button-gap", C["ab-stance-button-gap"], -1, 8, 1, L["Button Spacing"], L["Set the spacing between action buttons"], UpdateStanceBar)
end)

GUI:AddWidgets(L["General"], L["Totem Bar"], L["Action Bars"], function(left, right)
    left:CreateHeader(L["Enable"])
    left:CreateSwitch("ab-totem-enable", C["ab-totem-enable"], L["Enable Bar"], L["Enable the totem bar"], UpdateEnableTotemBar)
end)
