local Y, L, A, C = YxUIGlobal:get()

local Commands = {}

Commands['move'] = function()
    Y:ToggleMovers()
end

Commands['movereset'] = function()
    Y:ResetAllMovers()
end

Commands['settings'] = function()
    Y:GetModule('GUI'):Toggle()
end

Commands['keybind'] = function()
    Y:GetModule('Key Binding'):Toggle()
end

Commands['reset'] = function()
    Y:Reset()
end

Commands['texel'] = function()
    IsGMClient = function()
        return true
    end

    if (not IsAddOnLoaded('Blizzard_DebugTools')) then
        LoadAddOn('Blizzard_DebugTools')
    end

    TexelSnappingVisualizer:Show()

    --[[
	local PIXEL_SNAPPING_OPTIONS = {
		{ text = "Default", cvarValue = "-1" },
		{ text = "Override On", cvarValue = "1" },
		{ text = "Override Off", cvarValue = "0" },
	}

	SetCVar("overrideTexelSnappingBias", "1")

	SetCVar("overridePixelGridSnapping", "-1")

	--]]
end

Commands['help'] = function()
    print(format(L['|cFF%sYxUI|r Commands'], C['ui-widget-color']))
    print(' ')
    print(format('|Hcommand:/yxui|h|cFF%s/yxui|r|h - Toggle the settings window', C['ui-widget-color']))
    print(format('|Hcommand:/yxui move|h|cFF%s/yxui move|r|h - Drag UI elements around the screen', C['ui-widget-color']))
    print(format('|Hcommand:/yxui movereset|h|cFF%s/yxui movereset|r|h - Reposition all movers to their default locations', C['ui-widget-color']))
    print(format('|Hcommand:/yxui keybind|h|cFF%s/yxui keybind|r|h - Toggle mouseover keybinding', C['ui-widget-color']))
    print(format('|Hcommand:/yxui reset|h|cFF%s/yxui reset|r|h - Reset all stored UI information and settings', C['ui-widget-color']))
end

local RunCommand = function(arg)
    if Commands[arg] then
        Commands[arg]()
    else
        Commands.settings()
    end
end

SLASH_YXUI1 = '/yxui'
SlashCmdList['YXUI'] = RunCommand

SLASH_RELOAD1 = '/rl'
SlashCmdList['RELOAD'] = C_UI.Reload

SLASH_GLOBALSTRINGFIND1 = '/gfind'
SlashCmdList['GLOBALSTRINGFIND'] = function(query)
    for Key, Value in next, _G do
        if (Value and type(Value) == 'string') then
            if Value:lower():find(query:lower()) then
                print(format('|cFFFFFF00%s|r |cFFFFFFFF= %s|r', Key, Value))
            end
        end
    end
end

local button = CreateFrame('Button', nil, GameMenuFrame, Y.IsMainline and 'MainMenuFrameButtonTemplate' or 'GameMenuButtonTemplate')
button:SetFormattedText(Y.UITitle)
button:SetScript('OnClick', function()
    Commands.settings()
    if not InCombatLockdown() then
        HideUIPanel(GameMenuFrame)
    end
end)
if GameMenuFrame.Layout then
else
    button:SetPoint('TOP', GameMenuButtonAddons, 'BOTTOM', 0, -1)
    local buttons = {}
    for _, button in next, {GameMenuFrame:GetChildren()} do
        if button and button.IsObjectType and button:IsObjectType('Button') then
            button:SkinButton()
            local A1, P, A2, X, Y = button:GetPoint()
            button:SetPoint(A1, P, A2, X, Y - 3)
            table.insert(buttons, button)
        end
    end
    GameMenuFrame:StripTextures()
    GameMenuFrame:CreateBorder()
    GameMenuFrameHeader:SetPoint('TOP', GameMenuFrame, 0, 7)
    for _, region in next, {GameMenuFrame:GetRegions()} do
        if region and region.IsObjectType and region:IsObjectType('FontString') then
            region:SetFontObject(Game16Font)
            region:SetTextColor(Y.UserColor.r, Y.UserColor.g, Y.UserColor.b)
        end
    end
    GameMenuFrame:HookScript('OnShow', function(self)
        GameMenuButtonLogout:ClearAllPoints()
        GameMenuButtonLogout:SetPoint('TOP', button, 'BOTTOM', 0, -16)
        self:SetHeight(self:GetHeight() + #buttons * 3 + 10)
    end)
end
