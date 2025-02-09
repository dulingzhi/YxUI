local Y, L, A, C, D = YxUIGlobal:get()

-- Default setting values
D['chat-enable'] = true
D['chat-bg-opacity'] = 70
D['chat-top-opacity'] = 100
D['chat-bottom-opacity'] = 100
D['chat-enable-url-links'] = true
D['chat-enable-discord-links'] = true
D['chat-enable-email-links'] = true
D['chat-enable-friend-links'] = true
D['chat-font'] = 'PT Sans'
D['chat-font-size'] = 12
D['chat-font-flags'] = ''
D['chat-tab-font'] = 'Roboto'
D['chat-tab-font-size'] = 12
D['chat-tab-font-flags'] = ''
D['chat-tab-font-color'] = 'FFFFFF'
D['chat-tab-font-color-mouseover'] = 'FFCE54'
D['chat-frame-width'] = 392
D['chat-frame-height'] = 170
D['chat-bottom-height'] = 26
D['chat-top-height'] = 26
D['chat-enable-fading'] = false
D['chat-fade-time'] = 15
D['chat-link-tooltip'] = true
D['chat-shorten-channels'] = true
D['chat-history-enable'] = true

D['right-window-enable'] = false
D['right-window-size'] = 'SINGLE'
D['right-window-width'] = 392
D['right-window-height'] = 128
D['right-window-fill'] = 70
D['right-window-left-fill'] = 70
D['right-window-right-fill'] = 70
D['right-window-middle-pos'] = 50
D['right-window-bottom-height'] = 26
D['right-window-top-height'] = 26
D['rw-top-fill'] = 100
D['rw-bottom-fill'] = 100
D['rw-single-embed'] = 'None'

local select = select
local tostring = tostring
local format = string.format
local sub = string.sub
local gsub = string.gsub
local match = string.match

local NoCall = function()
end
local DT

local SetHyperlink = ItemRefTooltip.SetHyperlink
local ChatEdit_ChooseBoxForSend = ChatEdit_ChooseBoxForSend
local ChatEdit_ActivateChat = ChatEdit_ActivateChat
local ChatEdit_ParseText = ChatEdit_ParseText
local ChatEdit_UpdateHeader = ChatEdit_UpdateHeader
local CHAT_LABEL = CHAT_LABEL

local Window = Y:NewModule('Right Window')
local Chat = Y:NewModule('Chat')

-- When hovering over a chat frame, fade in the scroll controls

local FormatDiscordHyperlink = function(id)
    return format('|cFF7289DA|Hdiscord:%s|h[%s: %s]|h|r', format('https://discord.gg/%s', id), L['NetEase DD'], id)
end

local FormatURLHyperlink = function(url)
    return format('|cFF%s|Hurl:%s|h[%s]|h|r', C['ui-widget-color'], url, url)
end

local FormatEmailHyperlink = function(address)
    return format('|cFF%s|Hemail:%s|h[%s]|h|r', C['ui-widget-color'], address, address)
end

-- This can be b.net or discord, so just calling it a "friend tag" for now.
local FormatFriendHyperlink = function(tag) -- /run print("Player#1111")
    return format('|cFF00AAFF|Hfriend:%s|h[%s]|h|r', tag, tag)
end

local FormatLinks = function(message)
    if (not message) then
        return
    end

    if C['chat-enable-discord-links'] then
        local NewMessage, Subs = gsub(message, 'https://discord.gg/(%S+)', FormatDiscordHyperlink('%1'))

        if (Subs > 0) then
            return NewMessage
        end

        NewMessage, Subs = gsub(message, 'discord.gg/(%S+)', FormatDiscordHyperlink('%1'))

        if (Subs > 0) then
            return NewMessage
        end
    end

    if C['chat-enable-url-links'] then
        if (match(message, '%a+://(%S+)%.%a+/%S+') == 'discord') and (not C['chat-enable-discord-links']) then
            return message
        end

        local NewMessage, Subs = gsub(message, '(%a+)://(%S+)', FormatURLHyperlink('%1://%2'))

        if (Subs > 0) then
            return NewMessage
        end

        NewMessage, Subs = gsub(message, 'www%.([_A-Za-z0-9-]+)%.(%S+)', FormatURLHyperlink('www.%1.%2'))

        if (Subs > 0) then
            return NewMessage
        end
    end

    if C['chat-enable-email-links'] then
        local NewMessage, Subs = gsub(message, '([_A-Za-z0-9-%.]+)@([_A-Za-z0-9-]+)(%.+)([_A-Za-z0-9-%.]+)', FormatEmailHyperlink('%1@%2%3%4'))

        if (Subs > 0) then
            return NewMessage
        end
    end

    if C['chat-enable-friend-links'] then
        local NewMessage, Subs = gsub(message, '(%a+)#(%d+)', FormatFriendHyperlink('%1#%2'))

        if (Subs > 0) then
            return NewMessage
        end
    end

    return message
end

local FindLinks = function(self, event, msg, ...)
    msg = FormatLinks(msg)

    return false, msg, ...
end

--[[ Scooping the GMOTD to see if there's any yummy links.
ChatFrame_DisplayGMOTD = function(frame, message)
	if (message and (message ~= "")) then
		local Info = ChatTypeInfo["GUILD"]

		message = format(GUILD_MOTD_TEMPLATE, message)
		message = FormatLinks(message)

		frame:AddMessage(message, Info.r, Info.g, Info.b, Info.id)
	end
end]]

local SetEditBoxToLink = function(box, text)
    box:SetText('')

    if (not box:IsShown()) then
        ChatEdit_ActivateChat(box)
    else
        ChatEdit_UpdateHeader(box)
    end

    box:SetFocus(true)
    box:Insert(text)
    box:HighlightText()
end

ItemRefTooltip.SetHyperlink = function(self, link, text, button, chatFrame)
    if (sub(link, 1, 3) == 'url') then
        local EditBox = ChatEdit_ChooseBoxForSend()
        local Link = sub(link, 5)

        EditBox:SetAttribute('chatType', 'URL')

        SetEditBoxToLink(EditBox, Link)
    elseif (sub(link, 1, 5) == 'email') then
        local EditBox = ChatEdit_ChooseBoxForSend()
        local Email = sub(link, 7)

        EditBox:SetAttribute('chatType', 'EMAIL')

        SetEditBoxToLink(EditBox, Email)
    elseif (sub(link, 1, 7) == 'discord') then
        local EditBox = ChatEdit_ChooseBoxForSend()
        local Link = sub(link, 9)

        EditBox:SetAttribute('chatType', 'DISCORD')

        SetEditBoxToLink(EditBox, Link)
    elseif (sub(link, 1, 6) == 'friend') then
        local EditBox = ChatEdit_ChooseBoxForSend()
        local Tag = sub(link, 8)

        EditBox:SetAttribute('chatType', 'FRIEND')

        SetEditBoxToLink(EditBox, Tag)
    elseif (sub(link, 1, 7) == 'command') then
        local EditBox = ChatEdit_ChooseBoxForSend()
        local Command = sub(link, 9)

        EditBox:SetText('')

        if (not EditBox:IsShown()) then
            ChatEdit_ActivateChat(EditBox)
        else
            ChatEdit_UpdateHeader(EditBox)
        end

        EditBox:Insert(Command)
        ChatEdit_ParseText(EditBox, 1)
    else
        SetHyperlink(self, link, text, button, chatFrame)
    end
end

Chat.RemoveTextures = {'TabLeft', 'TabMiddle', 'TabRight', 'TabSelectedLeft', 'TabSelectedMiddle', 'TabSelectedRight', 'TabHighlightLeft', 'TabHighlightMiddle', 'TabHighlightRight', 'ButtonFrameUpButton', 'ButtonFrameDownButton',
                       'ButtonFrameBottomButton', 'ButtonFrameMinimizeButton', 'ButtonFrame', 'EditBoxFocusLeft', 'EditBoxFocusMid', 'EditBoxFocusRight', 'EditBoxLeft', 'EditBoxMid', 'EditBoxRight'}

function Chat:CreateChatWindow()
    local R, G, B = Y:HexToRGB(C['ui-window-main-color'])
    local Border = C['ui-border-thickness']
    local Width = C['chat-frame-width']

    self:SetSize(Width, C['chat-frame-height'] + (4 * 2))
    self:SetPoint('BOTTOMLEFT', Y.UIParent, 5, 5)
    self:SetFrameStrata('BACKGROUND')
    self:CreateBorder()

    self.Bottom = CreateFrame('Frame', 'YxUIChatFrameBottom', self, 'BackdropTemplate')
    self.Bottom:SetSize(Width, C['chat-bottom-height'])
    self.Bottom:SetPoint('TOPLEFT', Y.UIParent, 0, 0)

    self.Middle = CreateFrame('Frame', nil, self, 'BackdropTemplate')
    self.Middle:SetSize(Width, C['chat-frame-height'])
    self.Middle:SetAllPoints()

    self.Top = CreateFrame('Frame', nil, self, 'BackdropTemplate')
    self.Top:SetSize(Width, C['chat-top-height'])
    self.Top:SetPoint('BOTTOM', self, 'TOP', 0, 1 > Border and -1 or -(Border + 2))

    self.EditBox = CreateFrame('Frame', 'YxUIChatFrameTop', self, 'BackdropTemplate')
    self.EditBox:SetSize(Width, C['chat-bottom-height'])
    self.EditBox:SetPoint('BOTTOMLEFT', self.Top, 'TOPLEFT', 0, 0)
    self.EditBox:CreateBorder()
    self.EditBox:SetAlpha(0)
    self.EditBox:EnableMouse(false)

    Y:CreateMover(self, 2)
end

local Disable = function(object)
    if not object then
        return
    end

    if object.UnregisterAllEvents then
        object:UnregisterAllEvents()
    end

    if (object.HasScript and object:HasScript('OnUpdate')) then
        object:SetScript('OnUpdate', nil)
    end

    object.Show = NoCall
    object:Hide()
end

local OnMouseWheel = function(self, delta)
    if (delta < 0) then
        if IsShiftKeyDown() then
            self:ScrollToBottom()
        elseif IsControlKeyDown() then
            for i = 1, 5 do
                self:ScrollDown()
            end
        else
            self:ScrollDown()
        end
    elseif (delta > 0) then
        if IsShiftKeyDown() then
            self:ScrollToTop()
        elseif IsControlKeyDown() then
            for i = 1, 5 do
                self:ScrollUp()
            end
        else
            self:ScrollUp()
        end
    end
end

local UpdateHeader = function(editbox)
    local ChatType = editbox:GetAttribute('chatType')
    local r, g, b

    if (ChatType == 'CHANNEL') then
        if editbox:GetAttribute('channelTarget') then
            local ID = GetChannelName(editbox:GetAttribute('channelTarget'))

            if (ID == 0) then
                r, g, b = Y:HexToRGB(C['ui-header-texture-color'])
            else
                r, g, b = ChatTypeInfo[ChatType .. ID].r, ChatTypeInfo[ChatType .. ID].g, ChatTypeInfo[ChatType .. ID].b
            end
        else
            r, g, b = Y:HexToRGB(C['ui-header-texture-color'])
        end
    else
        r, g, b = ChatTypeInfo[ChatType].r, ChatTypeInfo[ChatType].g, ChatTypeInfo[ChatType].b
    end
    Chat.EditBox.YxUIBorder:SetVertexColor(r, g, b)
end

local OnEditFocusLost = function(self)
    Chat.EditBox:SetAlpha(0)
    Chat.EditBox:EnableMouse(false)
end

local OnEditFocusGained = function(self)
    Chat.EditBox:SetAlpha(1)
    Chat.EditBox:EnableMouse(true)
end

local CheckForBottom = function(self)
    if (not self:AtBottom() and not self.JumpButton.FadeIn:IsPlaying()) then
        if (self.JumpButton:GetAlpha() == 0) then
            self.JumpButton:Show()
            self.JumpButton.FadeIn:Play()
        end
    elseif (self:AtBottom() and self.JumpButton:IsShown() and not self.JumpButton.FadeOut:IsPlaying()) then
        if (self.JumpButton:GetAlpha() > 0) then
            self.JumpButton.FadeOut:Play()
        end
    end
end

local JumpButtonOnMouseUp = function(self)
    self:GetParent():ScrollToBottom()
end

local JumpButtonOnEnter = function(self)
    self.Arrow:SetVertexColor(1, 1, 1)
end

local JumpButtonOnLeave = function(self)
    self.Arrow:SetVertexColor(Y:HexToRGB(C['ui-widget-color']))
end

local JumpButtonOnFinished = function(self)
    self.Parent:Hide()
end

local TabOnEnter = function(self)
    self.TabText:_SetTextColor(Y:HexToRGB(C['chat-tab-font-color-mouseover']))
end

local TabOnLeave = function(self)
    self.TabText:_SetTextColor(Y:HexToRGB(C['chat-tab-font-color']))
end

local CopyWindowOnEscapePressed = function(self)
    Chat.CopyWindow.FadeOut:Play()
end

local CopyWindowOnMouseDown = function(self)
    self:SetAutoFocus(true)
end

local FadeOnFinished = function(self)
    self.Parent:Hide()
end

function Chat:CreateCopyWindow()
    if self.CopyWindow then
        return
    end

    local Window = CreateFrame('Frame', nil, Y.UIParent, 'BackdropTemplate')
    Window:SetSize(700, 400)
    Window:SetPoint('CENTER')
    Window:SetFrameStrata('DIALOG')
    Window:SetMovable(true)
    Window:EnableMouse(true)
    Window:RegisterForDrag('LeftButton')
    Window:SetScript('OnDragStart', Window.StartMoving)
    Window:SetScript('OnDragStop', Window.StopMovingOrSizing)
    Window:SetClampedToScreen(true)
    Window:SetAlpha(0)
    Window:CreateBorder()
    Window:Hide()

    -- Close button
    Window.CloseButton = CreateFrame('Button', nil, Window, 'UIPanelCloseButton')
    Window.CloseButton:SetPoint('TOPRIGHT')
    Window.CloseButton:SkinCloseButton()
    Window.CloseButton:SetScript('OnClick', function(self)
        self:GetParent().FadeOut:Play()
    end)

    Window.Inner = CreateFrame('ScrollFrame', nil, Window, 'UIPanelScrollFrameTemplate')
    Window.Inner:SetPoint('TOPLEFT', Window, 12, -40)
    Window.Inner:SetPoint('BOTTOMRIGHT', Window, -30, 20)
    Y.SkinScrollBar(Window.Inner.ScrollBar)

    Window.Input = CreateFrame('EditBox', nil, Window.Inner)
    Y:SetFontInfo(Window.Input, C['ui-widget-font'], C['ui-font-size'])
    Window.Input:SetMultiLine(true)
    Window.Input:SetMaxLetters(99999)
    Window.Input:EnableMouse(true)
    Window.Input:SetAutoFocus(false)
    Window.Input:SetWidth(Window.Inner:GetWidth())
    Window.Input:SetHeight(400)

    Window.Input:SetScript('OnEscapePressed', CopyWindowOnEscapePressed)
    Window.Input:SetScript('OnMouseDown', CopyWindowOnMouseDown)

    Window.Input:SetScript('OnTextChanged', function(_, userInput)
        if userInput then
            return
        end

        local _, max = Window.Inner.ScrollBar:GetMinMaxValues()
        for _ = 1, max do
            ScrollFrameTemplate_OnMouseWheel(Window.Inner, -1)
        end
    end)

    Window.Inner:SetScrollChild(Window.Input)
    Window.Inner:HookScript('OnVerticalScroll', function(self, offset)
        Window.Input:SetHitRectInsets(0, 0, offset, (Window.Input:GetHeight() - offset - self:GetHeight()))
    end)

    -- This just makes the animation look better. That's all. ಠ_ಠ
    Window.BlackTexture = Window:CreateTexture(nil, 'BACKGROUND')
    Window.BlackTexture:SetPoint('TOPLEFT', Window, 0, 0)
    Window.BlackTexture:SetPoint('BOTTOMRIGHT', Window, 0, 0)
    Window.BlackTexture:SetTexture(A:GetTexture('Blank'))
    Window.BlackTexture:SetDrawLayer('BACKGROUND', -7)
    Window.BlackTexture:SetVertexColor(0, 0, 0, 0)

    Window.Fade = LibMotion:CreateAnimationGroup()

    Window.FadeIn = LibMotion:CreateAnimation(Window, 'Fade')
    Window.FadeIn:SetEasing('in')
    Window.FadeIn:SetDuration(0.15)
    Window.FadeIn:SetChange(1)

    Window.FadeOut = LibMotion:CreateAnimation(Window, 'Fade')
    Window.FadeOut:SetEasing('out')
    Window.FadeOut:SetDuration(0.15)
    Window.FadeOut:SetChange(0)
    Window.FadeOut:SetScript('OnFinished', FadeOnFinished)

    self.CopyWindow = Window

    return Window
end

local function canChangeMessage(arg1, id)
	if id and arg1 == "" then
		return id
	end
end

local function isMessageProtected(msg)
	return msg and (msg ~= string.gsub(msg, "(:?|?)|K(.-)|k", canChangeMessage))
end

local function replaceMessage(msg, r, g, b)
	-- Convert the color values to a hex string
	local hexRGB = Y:RGBToHex(r, g, b)
	-- Replace the texture path or id with only the path/id
	msg = string.gsub(msg, "|T(.-):.-|t", "%1")
	-- Replace the atlas path or id with only the path/id
	msg = string.gsub(msg, "|A(.-):.-|a", "%1")
	-- Return the modified message with the hex color code added
	return string.format("%s%s|r", hexRGB, msg)
end

local lines = {}
local function GetChatLines(self)
	local index = 1
	for i = 1, self:GetNumMessages() do
		local msg, r, g, b = self:GetMessageInfo(i)
		if msg and not isMessageProtected(msg) then
			r, g, b = r or 1, g or 1, b or 1
			msg = replaceMessage(msg, r, g, b)
			lines[index] = tostring(msg)
			index = index + 1
		end
	end

	return index - 1
end

local CopyButtonOnMouseUp = function(self)
    if (not Chat.CopyWindow) then
        Chat:CreateCopyWindow()
    end

    if not Chat.CopyWindow:IsVisible() then
        local chatframe = SELECTED_DOCK_FRAME
        local _, fontSize = chatframe:GetFont()
        FCF_SetChatWindowFontSize(chatframe, chatframe, 0.01)
        PlaySound(21968)

        local lineCt = GetChatLines(chatframe)
        local text = table.concat(lines, '\n', 1, lineCt)
        FCF_SetChatWindowFontSize(chatframe, chatframe, fontSize)
        Chat.CopyWindow.Input:SetText(text)
        Chat.CopyWindow:SetAlpha(0)
        Chat.CopyWindow:Show()
        Chat.CopyWindow.FadeIn:Play()
    else
        Chat.CopyWindow.FadeOut:Play()
    end
end

local ChatFrameOnEnter = function(self)
    self.CopyButton:SetAlpha(1)
end

local ChatFrameOnLeave = function(self)
    self.CopyButton:SetAlpha(0)
end

local ValidLinkTypes = {
    ['item'] = true,
    ['spell'] = true,
    ['enchant'] = true
}

local OnHyperlinkEnter = function(self, link, text, button)
    local LinkType = match(link, '^(%a+):')

    if (not ValidLinkTypes[LinkType]) then
        return
    end

    GameTooltip:SetOwner(self, 'ANCHOR_CURSOR')
    GameTooltip:ClearAllPoints()

    -- GameTooltip_SetDefaultAnchor(GameTooltip, self)
    GameTooltip:SetHyperlink(link)
    GameTooltip:Show()
end

local OnHyperlinkLeave = function(self)
    GameTooltip:Hide()
end

function Chat:OverrideAddMessage(msg, ...)
    msg = gsub(msg, '|h%[(%d+)%.%s.-%]|h', '|h[%1]|h')

    self.OldAddMessage(self, msg, ...)
end

function Chat:StyleChatFrame(frame)
    if frame.Styled then
        return
    end

    if C['chat-shorten-channels'] then
        frame.OldAddMessage = frame.AddMessage
        frame.AddMessage = Chat.OverrideAddMessage
    end

    local FrameName = frame:GetName()
    local Tab = _G[FrameName .. 'Tab']
    local TabText = Tab.Text or _G[FrameName .. 'TabText']
    local EditBox = _G[FrameName .. 'EditBox']
    local Minimize = _G[FrameName .. 'MinimizeButton']
    local Language = _G[FrameName .. 'EditBoxLanguage']

    if frame.ScrollBar then
        Disable(frame.ScrollBar)
        Disable(frame.ScrollToBottomButton)
        Disable(_G[FrameName .. 'ThumbTexture'])
    end

    if Tab.conversationIcon then
        Disable(Tab.conversationIconKill)
    end

    if Minimize then
        Disable(Minimize)
    end

    -- Tabs Alpha
    Tab.mouseOverAlpha = 1
    Tab.noMouseAlpha = 1
    Tab:SetAlpha(1)
    Tab.SetAlpha = UIFrameFadeRemoveFrame
    Tab.TabText = TabText

    if Tab.ActiveLeft then
        Tab.Left:SetTexture(nil)
        Tab.HighlightLeft:SetTexture(nil)
        Tab.ActiveLeft:SetTexture(nil)
        Tab.Middle:SetTexture(nil)
        Tab.HighlightMiddle:SetTexture(nil)
        Tab.ActiveMiddle:SetTexture(nil)
        Tab.Right:SetTexture(nil)
        Tab.HighlightRight:SetTexture(nil)
        Tab.ActiveRight:SetTexture(nil)
    end

    Tab:HookScript('OnEnter', TabOnEnter)
    Tab:HookScript('OnLeave', TabOnLeave)

    if TabText then
        Y:SetFontInfo(TabText, C['chat-tab-font'], C['chat-tab-font-size'], C['chat-tab-font-flags'])
        TabText._SetFont = TabText.SetFont
        TabText.SetFont = NoCall

        TabText:SetTextColor(Y:HexToRGB(C['chat-tab-font-color']))
        TabText._SetTextColor = TabText.SetTextColor
        TabText.SetTextColor = NoCall

        if Tab.glow then
            Tab.glow:ClearAllPoints()
            Tab.glow:SetPoint('BOTTOM', Tab, 0, 1 > C['ui-border-thickness'] and -1 or -(C['ui-border-thickness'] + 2)) -- 1
            Tab.glow:SetWidth(TabText:GetStringWidth() + 10)
        end
    end

    frame:SetFrameStrata('MEDIUM')
    frame:SetClampRectInsets(0, 0, 0, 0)
    frame:SetClampedToScreen(false)
    frame:SetFading(false)
    frame:EnableMouse(true)
    frame:HookScript('OnMouseWheel', OnMouseWheel)
    frame:SetSize(self:GetWidth() - 8, self:GetHeight() - 8)
    frame:SetFrameLevel(self:GetFrameLevel() + 1)
    frame:SetFrameStrata('MEDIUM')
    frame:SetJustifyH('LEFT')
    frame:SetFading(C['chat-enable-fading'])
    frame:SetTimeVisible(C['chat-fade-time'])
    frame:HookScript('OnEnter', ChatFrameOnEnter)
    frame:HookScript('OnLeave', ChatFrameOnLeave)
    frame:Hide()

    if C['chat-link-tooltip'] then
        frame:SetScript('OnHyperlinkEnter', OnHyperlinkEnter)
        frame:SetScript('OnHyperlinkLeave', OnHyperlinkLeave)
    end

    FCF_SetChatWindowFontSize(nil, frame, 12)

    if (not frame.isLocked) then
        FCF_SetLocked(frame, 1)
    end

    EditBox:ClearAllPoints()
    EditBox:SetPoint('TOPLEFT', self.EditBox, -2, 0)
    EditBox:SetPoint('BOTTOMRIGHT', self.EditBox, 0, 0)
    Y:SetFontInfo(EditBox, C['chat-font'], C['chat-font-size'], C['chat-font-flags'])
    EditBox:SetAltArrowKeyMode(false)
    EditBox:SetTextInsets(0, 0, 0, 0)
    EditBox:SetAlpha(0)
    EditBox:EnableMouse(false)
    EditBox:HookScript('OnEditFocusLost', OnEditFocusLost)
    EditBox:HookScript('OnEditFocusGained', OnEditFocusGained)

    Language:GetRegions():SetAlpha(0)
    Language:CreateBorder()
    Language:SetPoint('TOPLEFT', EditBox, 'TOPRIGHT', 5, 0)
    Language:SetPoint('BOTTOMRIGHT', EditBox, 'BOTTOMRIGHT', 29, 0)

    Y:SetFontInfo(EditBox.header, C['chat-font'], C['chat-font-size'], C['chat-font-flags'])

    -- Scroll to bottom
    -- if (not YxUI.IsMainline) then
    local JumpButton = CreateFrame('Frame', nil, frame, 'BackdropTemplate')
    JumpButton:SetSize(20, 20)
    JumpButton:SetPoint('BOTTOMRIGHT', frame, 0, 0)
    JumpButton:SetBackdrop(Y.BackdropAndBorder)
    JumpButton:SetBackdropColor(Y:HexToRGB(C['ui-window-main-color']))
    JumpButton:SetBackdropBorderColor(0, 0, 0)
    JumpButton:SetFrameStrata('HIGH')
    JumpButton:SetScript('OnMouseUp', JumpButtonOnMouseUp)
    JumpButton:SetScript('OnEnter', JumpButtonOnEnter)
    JumpButton:SetScript('OnLeave', JumpButtonOnLeave)
    JumpButton:SetAlpha(0)
    JumpButton:Hide()

    JumpButton.Texture = JumpButton:CreateTexture(nil, 'ARTWORK')
    JumpButton.Texture:SetPoint('TOPLEFT', JumpButton, 1, -1)
    JumpButton.Texture:SetPoint('BOTTOMRIGHT', JumpButton, -1, 1)
    JumpButton.Texture:SetTexture(A:GetTexture(C['ui-header-texture']))
    JumpButton.Texture:SetVertexColor(Y:HexToRGB(C['ui-header-texture-color']))

    JumpButton.Arrow = JumpButton:CreateTexture(nil, 'OVERLAY')
    JumpButton.Arrow:SetPoint('CENTER', JumpButton, 0, 0)
    JumpButton.Arrow:SetSize(16, 16)
    JumpButton.Arrow:SetTexture(A:GetTexture('Arrow Down'))
    JumpButton.Arrow:SetVertexColor(Y:HexToRGB(C['ui-widget-color']))

    JumpButton.Fade = LibMotion:CreateAnimationGroup()

    JumpButton.FadeIn = LibMotion:CreateAnimation(JumpButton, 'Fade')
    JumpButton.FadeIn:SetEasing('in')
    JumpButton.FadeIn:SetDuration(0.15)
    JumpButton.FadeIn:SetChange(1)

    JumpButton.FadeOut = LibMotion:CreateAnimation(JumpButton, 'Fade')
    JumpButton.FadeOut:SetEasing('out')
    JumpButton.FadeOut:SetDuration(0.15)
    JumpButton.FadeOut:SetChange(0)
    JumpButton.FadeOut:SetScript('OnFinished', JumpButtonOnFinished)

    frame.JumpButton = JumpButton

    hooksecurefunc(frame, 'SetScrollOffset', CheckForBottom)
    -- end

    -- Copy chat
    local CopyButton = CreateFrame('Frame', nil, frame, 'BackdropTemplate')
    CopyButton:SetSize(24, 24)
    CopyButton:SetPoint('TOPRIGHT', frame, 0, 0)
    CopyButton:SetBackdrop(Y.BackdropAndBorder)
    CopyButton:SetBackdropColor(Y:HexToRGB(C['ui-window-main-color']))
    CopyButton:SetBackdropBorderColor(0, 0, 0)
    CopyButton:SetFrameStrata('HIGH')
    CopyButton:SetScript('OnMouseUp', CopyButtonOnMouseUp)
    CopyButton:SetScript('OnEnter', function(self)
        self:SetAlpha(1)
    end)
    CopyButton:SetScript('OnLeave', function(self)
        self:SetAlpha(0)
    end)
    CopyButton:SetAlpha(0)

    CopyButton.Texture = CopyButton:CreateTexture(nil, 'ARTWORK')
    CopyButton.Texture:SetPoint('CENTER', CopyButton, 0, 0)
    CopyButton.Texture:SetSize(16, 16)
    CopyButton.Texture:SetTexture(A:GetTexture('Copy'))

    frame.CopyButton = CopyButton

    -- Remove textures
    for i = 1, #CHAT_FRAME_TEXTURES do
        _G[FrameName .. CHAT_FRAME_TEXTURES[i]]:SetTexture(nil)
    end

    for i = 1, #self.RemoveTextures do
        Disable(_G[FrameName .. self.RemoveTextures[i]])
    end

    FCFTab_UpdateAlpha(frame)

    frame.Styled = true
end

local OpenTemporaryWindow = function()
    local Frame = FCF_GetCurrentChatFrame()

    if (Frame.name and Frame.name == PET_BATTLE_COMBAT_LOG) then
        return FCF_Close(Frame)
    end

    if (not Frame.Styled) then
        Chat:StyleChatFrame(Frame)
    end
end

function Chat:MoveChatFrames()
    for i = 1, NUM_CHAT_WINDOWS do
        local Frame = _G['ChatFrame' .. i]

        Frame:SetFrameLevel(self.Middle:GetFrameLevel() + 1)
        Frame:SetFrameStrata('MEDIUM')
        Frame:SetJustifyH('LEFT')

        if Frame.Tab then -- only Voice has .Tab
            FCF_UnDockFrame(Frame)
            FCF_SetLocked(Frame, false)
            FCF_Close(Frame)
        end

        if (C['right-window-enable'] and (C['right-window-size'] == 'SINGLE') and (Frame.name and Frame.name == C['rw-single-embed'])) then
            local Window = Y:GetModule('Right Window')

            FCF_UnDockFrame(Frame)
            FCF_SetTabPosition(Frame, 0)

            Frame:SetMovable(true)
            Frame:SetUserPlaced(true)
            Frame:ClearAllPoints()
            Frame:SetPoint('TOPLEFT', Window.Middle, 4 + C['ui-border-thickness'], -(4 + C['ui-border-thickness']))
            Frame:SetPoint('BOTTOMRIGHT', Window.Middle, -(4 + C['ui-border-thickness']), 4 + C['ui-border-thickness'])
            Frame:Show()
        else
            -- if (Frame.name and (not match(Frame.name, CHAT_LABEL .. "%s%d+")) and not Frame.Tab) then
            if (not Frame.isLocked) and (Frame.name and Frame.name ~= VOICE_LABEL) then
                FCF_DockFrame(Frame)
            end

            if (i == 1) then
                Frame:SetUserPlaced(true)
                Frame:ClearAllPoints()
                Frame:SetPoint('TOPLEFT', self.Middle, 4 + C['ui-border-thickness'], -(4 + C['ui-border-thickness']))
                Frame:SetPoint('BOTTOMRIGHT', self.Middle, -(4 + C['ui-border-thickness']), 4 + C['ui-border-thickness'])
            end
        end

        if (not Frame.isLocked) then
            FCF_SetLocked(Frame, true)
        end

        FCF_SetChatWindowFontSize(nil, Frame, C['chat-font-size'])
        FCF_SavePositionAndDimensions(Frame)

        local Font, IsPixel = A:GetFont(C['chat-font'])

        if IsPixel then
            Frame:SetFont(Font, C['chat-font-size'], 'MONOCHROME, OUTLINE')
            Frame:SetShadowColor(0, 0, 0, 0)
        else
            Frame:SetFont(Font, C['chat-font-size'], C['chat-font-flags'])
            Frame:SetShadowColor(0, 0, 0)
            Frame:SetShadowOffset(1, -1)
        end
    end

    GeneralDockManager:ClearAllPoints()
    GeneralDockManager:SetFrameStrata('MEDIUM')

    if (Y.ClientVersion >= 100000) then
        GeneralDockManager:SetPoint('TOPLEFT', self.Top, 0, 0)
        GeneralDockManager:SetPoint('BOTTOMRIGHT', self.Top, 0, 0)
    else
        GeneralDockManager:SetPoint('TOPLEFT', self.Top, 0, 5)
        GeneralDockManager:SetPoint('BOTTOMRIGHT', self.Top, 0, 5)
    end

    GeneralDockManagerOverflowButton:ClearAllPoints()
    GeneralDockManagerOverflowButton:SetPoint('RIGHT', self.Top, -2, 0)

    FCF_SelectDockFrame(ChatFrame1)
end

function Chat:StyleChatFrames()
    for i = 1, NUM_CHAT_WINDOWS do
        self:StyleChatFrame(_G['ChatFrame' .. i])
    end

    Disable(ChatConfigFrameDefaultButton)
    Disable(ChatFrameMenuButton)
    Disable(QuickJoinToastButton)

    Disable(ChatFrameChannelButton)
    Disable(ChatFrameToggleVoiceDeafenButton)
    Disable(ChatFrameToggleVoiceMuteButton)

    -- Restyle Combat Log objects
    CombatLogQuickButtonFrame_Custom:ClearAllPoints()
    CombatLogQuickButtonFrame_Custom:SetHeight(26)
    CombatLogQuickButtonFrame_Custom:SetPoint('TOPLEFT', ChatFrame2, -4, 29)
    CombatLogQuickButtonFrame_Custom:SetPoint('TOPRIGHT', ChatFrame2, 4, 29)

    CombatLogQuickButtonFrame_CustomProgressBar:ClearAllPoints()
    CombatLogQuickButtonFrame_CustomProgressBar:SetPoint('BOTTOMLEFT', CombatLogQuickButtonFrame_Custom, 1, 1)
    CombatLogQuickButtonFrame_CustomProgressBar:SetPoint('BOTTOMRIGHT', CombatLogQuickButtonFrame_Custom, -1, 1)
    CombatLogQuickButtonFrame_CustomProgressBar:SetHeight(3)
    CombatLogQuickButtonFrame_CustomProgressBar:SetStatusBarTexture(A:GetTexture(C['ui-widget-texture']))

    for i = 1, CombatLogQuickButtonFrame_Custom:GetNumChildren() do
        local Child = select(i, CombatLogQuickButtonFrame_Custom:GetChildren())

        for i = 1, Child:GetNumRegions() do
            local Region = select(i, Child:GetRegions())

            if (Region:GetObjectType() == 'FontString') then
                Y:SetFontInfo(Region, C['chat-tab-font'], C['chat-tab-font-size'], C['chat-tab-font-flags'])
            end
        end
    end
end

function Chat:Install()
    -- General
    FCF_ResetChatWindows()
    FCF_SetLocked(ChatFrame1, true)
    FCF_SetWindowName(ChatFrame1, L['General'])
    ChatFrame1:Show()

    ChatFrame_RemoveAllMessageGroups(ChatFrame1)
    ChatFrame_RemoveChannel(ChatFrame1, TRADE)
    ChatFrame_RemoveChannel(ChatFrame1, GENERAL)
    ChatFrame_RemoveChannel(ChatFrame1, 'LocalDefense')
    ChatFrame_RemoveChannel(ChatFrame1, 'GuildRecruitment')
    ChatFrame_RemoveChannel(ChatFrame1, 'LookingForGroup')
    ChatFrame_RemoveChannel(ChatFrame1, 'Services')

    ChatFrame_AddMessageGroup(ChatFrame1, 'SAY')
    ChatFrame_AddMessageGroup(ChatFrame1, 'EMOTE')
    ChatFrame_AddMessageGroup(ChatFrame1, 'YELL')
    ChatFrame_AddMessageGroup(ChatFrame1, 'GUILD')
    ChatFrame_AddMessageGroup(ChatFrame1, 'OFFICER')
    ChatFrame_AddMessageGroup(ChatFrame1, 'GUILD_ACHIEVEMENT')
    ChatFrame_AddMessageGroup(ChatFrame1, 'MONSTER_SAY')
    ChatFrame_AddMessageGroup(ChatFrame1, 'MONSTER_EMOTE')
    ChatFrame_AddMessageGroup(ChatFrame1, 'MONSTER_YELL')
    ChatFrame_AddMessageGroup(ChatFrame1, 'MONSTER_WHISPER')
    ChatFrame_AddMessageGroup(ChatFrame1, 'MONSTER_BOSS_EMOTE')
    ChatFrame_AddMessageGroup(ChatFrame1, 'MONSTER_BOSS_WHISPER')
    ChatFrame_AddMessageGroup(ChatFrame1, 'PARTY')
    ChatFrame_AddMessageGroup(ChatFrame1, 'PARTY_LEADER')
    ChatFrame_AddMessageGroup(ChatFrame1, 'RAID')
    ChatFrame_AddMessageGroup(ChatFrame1, 'RAID_LEADER')
    ChatFrame_AddMessageGroup(ChatFrame1, 'RAID_WARNING')
    ChatFrame_AddMessageGroup(ChatFrame1, 'INSTANCE_CHAT')
    ChatFrame_AddMessageGroup(ChatFrame1, 'INSTANCE_CHAT_LEADER')
    ChatFrame_AddMessageGroup(ChatFrame1, 'BG_HORDE')
    ChatFrame_AddMessageGroup(ChatFrame1, 'BG_ALLIANCE')
    ChatFrame_AddMessageGroup(ChatFrame1, 'BG_NEUTRAL')
    ChatFrame_AddMessageGroup(ChatFrame1, 'SYSTEM')
    ChatFrame_AddMessageGroup(ChatFrame1, 'ERRORS')
    ChatFrame_AddMessageGroup(ChatFrame1, 'AFK')
    ChatFrame_AddMessageGroup(ChatFrame1, 'DND')
    ChatFrame_AddMessageGroup(ChatFrame1, 'IGNORED')
    ChatFrame_AddMessageGroup(ChatFrame1, 'ACHIEVEMENT')

    -- Combat Log
    FCF_DockFrame(ChatFrame2)
    FCF_SetLocked(ChatFrame2, true)
    FCF_SetWindowName(ChatFrame2, L['Combat'])
    ChatFrame2:Show()

    -- Whispers
    local Whispers = FCF_OpenNewWindow(L['Whispers'])
    FCF_SetLocked(Whispers, true)
    FCF_DockFrame(Whispers)

    ChatFrame_RemoveAllMessageGroups(Whispers)
    ChatFrame_AddMessageGroup(Whispers, 'WHISPER')
    ChatFrame_AddMessageGroup(Whispers, 'BN_WHISPER')
    ChatFrame_AddMessageGroup(Whispers, 'BN_CONVERSATION')

    -- Trade
    local Trade = FCF_OpenNewWindow(L['Trade'])
    FCF_SetLocked(Trade, true)
    FCF_DockFrame(Trade)

    ChatFrame_RemoveAllMessageGroups(Trade)
    ChatFrame_AddChannel(Trade, TRADE)
    ChatFrame_AddChannel(Trade, GENERAL)

    if Y.IsMainline then
        ChatFrame_AddChannel(Trade, 'Services')
    end

    -- Loot
    local Loot = FCF_OpenNewWindow(L['Loot'])
    FCF_SetLocked(Loot, true)
    FCF_DockFrame(Loot)

    ChatFrame_RemoveAllMessageGroups(Loot)
    ChatFrame_AddMessageGroup(Loot, 'COMBAT_XP_GAIN')
    ChatFrame_AddMessageGroup(Loot, 'COMBAT_HONOR_GAIN')
    ChatFrame_AddMessageGroup(Loot, 'COMBAT_FACTION_CHANGE')
    ChatFrame_AddMessageGroup(Loot, 'LOOT')
    ChatFrame_AddMessageGroup(Loot, 'MONEY')
    ChatFrame_AddMessageGroup(Loot, 'SKILL')

    DEFAULT_CHAT_FRAME:SetUserPlaced(true)

    C_CVar.SetCVar('chatMouseScroll', '1')
    C_CVar.SetCVar('chatStyle', 'im')
    C_CVar.SetCVar('WholeChatWindowClickable', '0')
    C_CVar.SetCVar('WhisperMode', 'inline')
    -- C_CVar.SetCVar("BnWhisperMode", "inline")
    C_CVar.SetCVar('removeChatDelay', '1')
    C_CVar.SetCVar('colorChatNamesByClass', 0)
    C_CVar.SetCVar('chatClassColorOverride', 0)
    C_CVar.SetCVar('speechToText', '0')

    if (C_CVar.GetCVar('colorChatNamesByClass') ~= '0') then
        C_CVar.SetCVar('colorChatNamesByClass', 0)
    end

    if (C_CVar.GetCVar('chatClassColorOverride') ~= '0') then
        C_CVar.SetCVar('chatClassColorOverride', 0)
    end

    -- Chat:MoveChatFrames()
    FCF_SelectDockFrame(ChatFrame1)
end

function Chat:AddMessageFilters()
    ChatFrame_AddMessageEventFilter('CHAT_MSG_SYSTEM', FindLinks)
    ChatFrame_AddMessageEventFilter('CHAT_MSG_CHANNEL', FindLinks)
    ChatFrame_AddMessageEventFilter('CHAT_MSG_SAY', FindLinks)
    ChatFrame_AddMessageEventFilter('CHAT_MSG_YELL', FindLinks)
    ChatFrame_AddMessageEventFilter('CHAT_MSG_GUILD', FindLinks)
    ChatFrame_AddMessageEventFilter('CHAT_MSG_OFFICER', FindLinks)
    ChatFrame_AddMessageEventFilter('CHAT_MSG_PARTY', FindLinks)
    ChatFrame_AddMessageEventFilter('CHAT_MSG_PARTY_LEADER', FindLinks)
    ChatFrame_AddMessageEventFilter('CHAT_MSG_RAID', FindLinks)
    ChatFrame_AddMessageEventFilter('CHAT_MSG_RAID_LEADER', FindLinks)
    ChatFrame_AddMessageEventFilter('CHAT_MSG_BATTLEGROUND', FindLinks)
    ChatFrame_AddMessageEventFilter('CHAT_MSG_BATTLEGROUND_LEADER', FindLinks)
    ChatFrame_AddMessageEventFilter('CHAT_MSG_WHISPER', FindLinks)
    ChatFrame_AddMessageEventFilter('CHAT_MSG_WHISPER_INFORM', FindLinks)
    ChatFrame_AddMessageEventFilter('CHAT_MSG_BN_WHISPER', FindLinks)
    ChatFrame_AddMessageEventFilter('CHAT_MSG_BN_WHISPER_INFORM', FindLinks)
    ChatFrame_AddMessageEventFilter('CHAT_MSG_BN_CONVERSATION', FindLinks)
end

function Chat:SetChatTypeInfo()
    _G['CHAT_DISCORD_SEND'] = L['NetEase DD: ']
    _G['CHAT_URL_SEND'] = L['URL: ']
    _G['CHAT_EMAIL_SEND'] = L['Email: ']
    _G['CHAT_FRIEND_SEND'] = L['Friend Tag:']

    ChatTypeInfo['URL'] = {
        sticky = 0,
        r = 255 / 255,
        g = 206 / 255,
        b = 84 / 255
    }
    ChatTypeInfo['EMAIL'] = {
        sticky = 0,
        r = 102 / 255,
        g = 187 / 255,
        b = 106 / 255
    }
    ChatTypeInfo['DISCORD'] = {
        sticky = 0,
        r = 114 / 255,
        g = 137 / 255,
        b = 218 / 255
    }
    ChatTypeInfo['FRIEND'] = {
        sticky = 0,
        r = 0,
        g = 170 / 255,
        b = 255 / 255
    }

    ChatTypeInfo['WHISPER'].sticky = 1
    ChatTypeInfo['BN_WHISPER'].sticky = 1
    ChatTypeInfo['OFFICER'].sticky = 1
    ChatTypeInfo['RAID_WARNING'].sticky = 1
    ChatTypeInfo['CHANNEL'].sticky = 1

    ChatTypeInfo['SAY'].colorNameByClass = true
    ChatTypeInfo['YELL'].colorNameByClass = true
    ChatTypeInfo['GUILD'].colorNameByClass = true
    ChatTypeInfo['OFFICER'].colorNameByClass = true
    ChatTypeInfo['WHISPER'].colorNameByClass = true
    ChatTypeInfo['WHISPER_INFORM'].colorNameByClass = true
    ChatTypeInfo['BN_WHISPER'].colorNameByClass = true
    ChatTypeInfo['BN_WHISPER_INFORM'].colorNameByClass = true
    ChatTypeInfo['PARTY'].colorNameByClass = true
    ChatTypeInfo['PARTY_LEADER'].colorNameByClass = true
    ChatTypeInfo['RAID'].colorNameByClass = true
    ChatTypeInfo['RAID_LEADER'].colorNameByClass = true
    ChatTypeInfo['RAID_WARNING'].colorNameByClass = true
    ChatTypeInfo['INSTANCE_CHAT'].colorNameByClass = true
    ChatTypeInfo['INSTANCE_CHAT_LEADER'].colorNameByClass = true
    ChatTypeInfo['EMOTE'].colorNameByClass = true
    ChatTypeInfo['CHANNEL'].colorNameByClass = true
    ChatTypeInfo['CHANNEL1'].colorNameByClass = true
    ChatTypeInfo['CHANNEL2'].colorNameByClass = true
    ChatTypeInfo['CHANNEL3'].colorNameByClass = true
    ChatTypeInfo['CHANNEL4'].colorNameByClass = true
    ChatTypeInfo['CHANNEL5'].colorNameByClass = true
    ChatTypeInfo['CHANNEL6'].colorNameByClass = true
    ChatTypeInfo['CHANNEL7'].colorNameByClass = true
    ChatTypeInfo['CHANNEL8'].colorNameByClass = true
    ChatTypeInfo['CHANNEL9'].colorNameByClass = true
    ChatTypeInfo['CHANNEL10'].colorNameByClass = true
    ChatTypeInfo['CHANNEL11'].colorNameByClass = true
    ChatTypeInfo['CHANNEL12'].colorNameByClass = true
    ChatTypeInfo['CHANNEL13'].colorNameByClass = true
    ChatTypeInfo['CHANNEL14'].colorNameByClass = true
    ChatTypeInfo['CHANNEL15'].colorNameByClass = true
    ChatTypeInfo['CHANNEL16'].colorNameByClass = true
    ChatTypeInfo['CHANNEL17'].colorNameByClass = true
    ChatTypeInfo['CHANNEL18'].colorNameByClass = true
    ChatTypeInfo['CHANNEL19'].colorNameByClass = true
    ChatTypeInfo['CHANNEL20'].colorNameByClass = true

    if (not Y.IsClassic) then
        ChatTypeInfo['GUILD_ACHIEVEMENT'].colorNameByClass = true
    end

    if (C_CVar.GetCVar('colorChatNamesByClass') ~= '0') then
        C_CVar.SetCVar('colorChatNamesByClass', 0)
    end

    if (C_CVar.GetCVar('chatClassColorOverride') ~= '0') then
        C_CVar.SetCVar('chatClassColorOverride', 0)
    end
end

local MoveChatFrames = function()
    Chat:MoveChatFrames()
end

-- Tab colors
local function UpdateTabColors(self, selected)
    if selected then
        self.Text:SetTextColor(1, 0.8, 0)
        self.whisperIndex = 0
    else
        self.Text:SetTextColor(0.5, 0.5, 0.5)
    end

    if self.whisperIndex == 1 then
        self.glow:SetVertexColor(1, 0.5, 1)
    elseif self.whisperIndex == 2 then
        self.glow:SetVertexColor(0, 1, 0.96)
    else
        self.glow:SetVertexColor(1, 0.8, 0)
    end
end

local function UpdateTabEventColors(self, event)
    local tab = _G[self:GetName() .. 'Tab']
    local selected = GeneralDockManager.selected:GetID() == tab:GetID()

    if event == 'CHAT_MSG_WHISPER' then
        tab.whisperIndex = 1
        UpdateTabColors(tab, selected)
    elseif event == 'CHAT_MSG_BN_WHISPER' then
        tab.whisperIndex = 2
        UpdateTabColors(tab, selected)
    end
end

function Chat:Load()
    if (not C['chat-enable']) then
        return
    end

    self:AddMessageFilters()
    self:CreateChatWindow()
    self:StyleChatFrames()

    if (not YxUIData) then
        YxUIData = {}
    end

    if (not YxUIData.ChatInstalled) then
        self:Install()

        YxUIData.ChatInstalled = true
    end

    self:MoveChatFrames()
    self:SetChatTypeInfo()

    DEFAULT_CHAT_FRAME:SetUserPlaced(true)

    hooksecurefunc('ChatEdit_UpdateHeader', UpdateHeader)
    hooksecurefunc('FCF_OpenTemporaryWindow', OpenTemporaryWindow)
    hooksecurefunc('FCF_RestorePositionAndDimensions', MoveChatFrames)
    hooksecurefunc('FCFTab_UpdateColors', UpdateTabColors)
    hooksecurefunc('FloatingChatFrame_OnEvent', UpdateTabEventColors)

    if Y.IsMainline then
        self:Event('PLAYER_ENTERING_WORLD', self.MoveChatFrames)
        self:Event('CVAR_UPDATE', self.MoveChatFrames)
        self:Event('PLAYER_LEVEL_CHANGED', self.MoveChatFrames)
    end

    self:Event('UI_SCALE_CHANGED', self.MoveChatFrames)

    local Hider = CreateFrame('Frame', nil, Y.UIParent, 'SecureHandlerStateTemplate')
    Hider:Hide()

    -- Needs styling for 10.1.0
    if ChatFrame1.ScrollBar then
        ChatFrame1.ScrollBar:SetParent(Hider)
    end
end

Y.FormatLinks = FormatLinks

local UpdateChatFrameHeight = function(value)
    Chat.Middle:SetHeight(value)
end

local UpdateChatFrameWidth = function()
    local Width = C['chat-frame-width']

    Chat.Bottom:SetWidth(Width)
    Chat.Middle:SetWidth(Width)
    Chat.Top:SetWidth(Width)

    -- Update data text width
    DT:GetAnchor('Chat-Left'):SetWidth(Width / 3)
    DT:GetAnchor('Chat-Middle'):SetWidth(Width / 3)
    DT:GetAnchor('Chat-Right'):SetWidth(Width / 3)
end

local UpdateTopHeight = function(value)
    Chat.Top:SetHeight(value)
end

local UpdateBottomHeight = function(value)
    Chat.Top:SetHeight(value)
end

local UpdateTopOpacity = function(value)
    local R, G, B = Y:HexToRGB(C['ui-window-main-color'])

    Chat.Top.Outside:SetBackdropColor(R, G, B, (value / 100))
end

local UpdateMiddleOpacity = function(value)
    local R, G, B = Y:HexToRGB(C['ui-window-main-color'])

    Chat.Middle.Outside:SetBackdropColor(R, G, B, (value / 100))
end

local UpdateBottomOpacity = function(value)
    local R, G, B = Y:HexToRGB(C['ui-window-main-color'])

    Chat.Bottom.Outside:SetBackdropColor(R, G, B, (value / 100))
end

local UpdateChatFont = function()
    for i = 1, NUM_CHAT_WINDOWS do
        local Frame = _G['ChatFrame' .. i]

        FCF_SetChatWindowFontSize(nil, Frame, C['chat-font-size'])

        local Font, IsPixel = A:GetFont(C['chat-font'])

        if IsPixel then
            Frame:SetFont(Font, C['chat-font-size'], 'MONOCHROME, OUTLINE')
            Frame:SetShadowColor(0, 0, 0, 0)
        else
            Frame:SetFont(Font, C['chat-font-size'], C['chat-font-flags'])
            Frame:SetShadowColor(0, 0, 0)
            Frame:SetShadowOffset(1, -1)
        end
    end
end

local UpdateChatTabFont = function()
    local R, G, B = Y:HexToRGB(C['chat-tab-font-color'])

    for i = 1, NUM_CHAT_WINDOWS do
        local TabText = _G['ChatFrame' .. i .. 'TabText']
        local Font, IsPixel = A:GetFont(C['chat-tab-font'])

        TabText:_SetTextColor(R, G, B)

        if IsPixel then
            TabText:_SetFont(Font, C['chat-tab-font-size'], 'MONOCHROME, OUTLINE')
            TabText:SetShadowColor(0, 0, 0, 0)
        else
            TabText:_SetFont(Font, C['chat-tab-font-size'], C['chat-tab-font-flags'])
            TabText:SetShadowColor(0, 0, 0)
            TabText:SetShadowOffset(1, -1)
        end
    end
end

local RunChatInstall = function()
    Chat:Install()
    ReloadUI()
end

local UpdateEnableFading = function(value)
    for i = 1, NUM_CHAT_WINDOWS do
        _G['ChatFrame' .. i]:SetFading(value)
    end
end

local UpdateFadeTime = function(value)
    for i = 1, NUM_CHAT_WINDOWS do
        _G['ChatFrame' .. i]:SetTimeVisible(value)
    end
end

local UpdateEnableLinks = function(value)
    for i = 1, NUM_CHAT_WINDOWS do
        if value then
            _G['ChatFrame' .. i]:SetScript('OnHyperlinkEnter', OnHyperlinkEnter)
            _G['ChatFrame' .. i]:SetScript('OnHyperlinkLeave', OnHyperlinkLeave)
        else
            _G['ChatFrame' .. i]:SetScript('OnHyperlinkEnter', nil)
            _G['ChatFrame' .. i]:SetScript('OnHyperlinkLeave', nil)
        end
    end
end

local UpdateShortenChannels = function(value)
    local Frame

    if value then
        for i = 1, NUM_CHAT_WINDOWS do
            Frame = _G['ChatFrame' .. i]

            Frame.OldAddMessage = Frame.AddMessage
            Frame.AddMessage = Chat.OverrideAddMessage
        end
    else
        for i = 1, NUM_CHAT_WINDOWS do
            Frame = _G['ChatFrame' .. i]

            Frame.AddMessage = Frame.OldAddMessage
        end
    end
end

Y:GetModule('GUI'):AddWidgets(L['General'], L['Chat'], function(left, right)
    left:CreateHeader(L['Enable'])
    left:CreateSwitch('chat-enable', C['chat-enable'], L['Enable Chat Module'], L['Enable the YxUI chat module'], ReloadUI):RequiresReload(true)

    left:CreateHeader(L['General'])
    left:CreateSlider('chat-fade-time', C['chat-enable-fading'], 0, 60, 5, L['Set Fade Time'], L['Set the duration to display text before fading out'], UpdateFadeTime, nil, 's')
    left:CreateSwitch('chat-enable-fading', C['chat-enable-fading'], L['Enable Text Fading'], L['Set the text to fade after the set amount of time'], UpdateEnableFading)
    left:CreateSwitch('chat-link-tooltip', C['chat-link-tooltip'], L['Show Link Tooltips'], L['Display a tooltip when hovering over links in chat'], UpdateEnableLinks)
    left:CreateSwitch('chat-shorten-channels', C['chat-shorten-channels'], L['Shorten Channel Names'], L['Shorten chat channel names to their channel number'], UpdateShortenChannels)
    left:CreateSwitch('chat-history-enable', C['chat-history-enable'], L['Enable Chat History'], L['Log chat history']):RequiresReload(true)

    right:CreateHeader(L['Install'])
    right:CreateButton('', L['Install'], L['Install Chat Defaults'], L['Set default channels and settings related to chat'], RunChatInstall):RequiresReload(true)

    left:CreateHeader(L['Links'])
    left:CreateSwitch('chat-enable-url-links', C['chat-enable-url-links'], L['Enable URL Links'], L['Enable URL links in the chat frame'])
    left:CreateSwitch('chat-enable-discord-links', C['chat-enable-discord-links'], L['Enable NetEase DD Links'], L['Enable NetEase DD links in the chat frame'])
    left:CreateSwitch('chat-enable-email-links', C['chat-enable-email-links'], L['Enable Email Links'], L['Enable email links in the chat frame'])
    left:CreateSwitch('chat-enable-friend-links', C['chat-enable-friend-links'], L['Enable Friend Tag Links'], L['Enable friend tag links in the chat frame'])

    right:CreateHeader(L['Chat Frame Font'])
    right:CreateDropdown('chat-font', C['chat-font'], A:GetFontList(), L['Font'], L['Set the font of the chat frame'], UpdateChatFont, 'Font')
    right:CreateSlider('chat-font-size', C['chat-font-size'], 8, 32, 1, L['Font Size'], L['Set the font size of the chat frame'], UpdateChatFont)
    right:CreateDropdown('chat-font-flags', C['chat-font-flags'], A:GetFlagsList(), L['Font Flags'], L['Set the font flags of the chat frame'], UpdateChatFont)

    right:CreateHeader(L['Tab Font'])
    right:CreateDropdown('chat-tab-font', C['chat-tab-font'], A:GetFontList(), L['Font'], L['Set the font of the chat frame tabs'], UpdateChatTabFont, 'Font')
    right:CreateSlider('chat-tab-font-size', C['chat-tab-font-size'], 8, 32, 1, L['Font Size'], L['Set the font size of the chat frame tabs'], UpdateChatTabFont)
    right:CreateDropdown('chat-tab-font-flags', C['chat-tab-font-flags'], A:GetFlagsList(), L['Font Flags'], L['Set the font flags of the chat frame tabs'], UpdateChatTabFont)
    right:CreateColorSelection('chat-tab-font-color', C['chat-tab-font-color'], L['Font Color'], L['Set the color of the chat frame tabs'], UpdateChatTabFont)
    right:CreateColorSelection('chat-tab-font-color-mouseover', C['chat-tab-font-color-mouseover'], L['Font Color Mouseover'], L['Set the color of the chat frame tab while mousing over it'])
end)

Y:GetModule('GUI'):AddWidgets(L['General'], L['Left'], L['Chat'], function(left, right)
    left:CreateHeader(L['General'])
    left:CreateSlider('chat-frame-width', C['chat-frame-width'], 300, 650, 1, L['Chat Width'], L['Set the width of the chat frame'], UpdateChatFrameWidth)
    left:CreateSlider('chat-frame-height', C['chat-frame-height'], 40, 350, 1, L['Chat Height'], L['Set the height of the chat frame'], UpdateChatFrameHeight)
    left:CreateSlider('chat-top-opacity', C['chat-top-opacity'], 0, 100, 5, L['Top Opacity'], L['Set the opacity of the chat top'], UpdateTopOpacity, nil, '%')
    left:CreateSlider('chat-bg-opacity', C['chat-bg-opacity'], 0, 100, 5, L['Background Opacity'], L['Set the opacity of the chat background'], UpdateMiddleOpacity, nil, '%')
    left:CreateSlider('chat-bottom-opacity', C['chat-bottom-opacity'], 0, 100, 5, L['Bottom Opacity'], L['Set the opacity of the chat bottom'], UpdateBottomOpacity, nil, '%')
end)

function Window:CreateSingleWindow()
    local R, G, B = Y:HexToRGB(C['ui-window-main-color'])
    local Border = C['ui-border-thickness']
    local Width = C['right-window-width']

    self.Bottom = CreateFrame('Frame', nil, self, 'BackdropTemplate')
    self.Bottom:SetSize(Width, C['right-window-bottom-height'])
    self.Bottom:SetPoint('BOTTOMRIGHT', self, 0, 0)
    Y:AddBackdrop(self.Bottom, A:GetTexture(C['ui-header-texture']))
    self.Bottom.Outside:SetBackdropColor(R, G, B, (C['rw-bottom-fill'] / 100))
    self.Bottom.Outside:SetFrameStrata('BACKGROUND')

    self.Middle = CreateFrame('Frame', nil, self, 'BackdropTemplate')
    self.Middle:SetSize(Width, C['right-window-height'])
    self.Middle:SetPoint('BOTTOMLEFT', self.Bottom, 'TOPLEFT', 0, 1 > Border and -1 or -(Border + 2))
    Y:AddBackdrop(self.Middle)
    self.Middle.Outside:SetBackdropColor(R, G, B, (C['right-window-fill'] / 100))
    self.Middle.Outside:SetFrameStrata('BACKGROUND')

    self.Top = CreateFrame('Frame', nil, self, 'BackdropTemplate')
    self.Top:SetSize(Width, C['right-window-top-height'])
    self.Top:SetPoint('BOTTOMLEFT', self.Middle, 'TOPLEFT', 0, 1 > Border and -1 or -(Border + 2))
    Y:AddBackdrop(self.Top, A:GetTexture(C['ui-header-texture']))
    self.Top.Outside:SetBackdropColor(R, G, B, (C['rw-top-fill'] / 100))
    self.Top.Outside:SetFrameStrata('BACKGROUND')
end

function Window:CreateDoubleWindow()
    local R, G, B = Y:HexToRGB(C['ui-window-main-color'])
    local Border = C['ui-border-thickness']
    local Adjust = 1 > Border and -1 or -(Border + 2)
    local Width = C['right-window-width']
    local LeftWidth = (Width * C['right-window-middle-pos'] / 100) - Adjust
    local RightWidth = (Width - (Width * C['right-window-middle-pos'] / 100))

    self.Bottom = CreateFrame('Frame', nil, self, 'BackdropTemplate')
    self.Bottom:SetSize(Width, C['right-window-bottom-height'])
    self.Bottom:SetPoint('BOTTOMRIGHT', self, 0, 0)
    Y:AddBackdrop(self.Bottom, A:GetTexture(C['ui-header-texture']))
    self.Bottom.Outside:SetBackdropColor(R, G, B, 1)

    self.Left = CreateFrame('Frame', nil, self, 'BackdropTemplate')
    self.Left:SetSize(LeftWidth, C['right-window-height'])
    self.Left:SetPoint('BOTTOMLEFT', self.Bottom, 'TOPLEFT', 0, Adjust) -- -4
    Y:AddBackdrop(self.Left)
    self.Left.Outside:SetBackdropColor(R, G, B, (C['right-window-fill'] / 100))
    self.Left.Outside:SetFrameStrata('BACKGROUND')

    self.Right = CreateFrame('Frame', nil, self, 'BackdropTemplate')
    self.Right:SetSize(RightWidth, C['right-window-height'])
    self.Right:SetPoint('BOTTOMRIGHT', self.Bottom, 'TOPRIGHT', 0, Adjust) -- -4
    Y:AddBackdrop(self.Right)
    self.Right.Outside:SetBackdropColor(R, G, B, (C['right-window-fill'] / 100))
    self.Right.Outside:SetFrameStrata('BACKGROUND')

    self.TopLeft = CreateFrame('Frame', nil, self, 'BackdropTemplate')
    self.TopLeft:SetSize(LeftWidth, C['right-window-top-height'])
    self.TopLeft:SetPoint('BOTTOMLEFT', self.Left, 'TOPLEFT', 0, Adjust) -- -4
    Y:AddBackdrop(self.TopLeft, A:GetTexture(C['ui-header-texture']))
    self.TopLeft.Outside:SetBackdropColor(R, G, B)

    self.TopRight = CreateFrame('Frame', nil, self, 'BackdropTemplate')
    self.TopRight:SetSize(RightWidth, C['right-window-top-height'])
    self.TopRight:SetPoint('BOTTOMRIGHT', self.Right, 'TOPRIGHT', 0, Adjust) -- -4
    Y:AddBackdrop(self.TopRight, A:GetTexture(C['ui-header-texture']))
    self.TopRight.Outside:SetBackdropColor(R, G, B)
end

function Window:AddDataTexts()
    local Width = self.Bottom:GetWidth() / 3
    local Height = self.Bottom:GetHeight()

    local Left = DT:NewAnchor('Window-Left', self.Bottom)
    Left:SetSize(Width, Height)
    Left:SetPoint('LEFT', self.Bottom, 0, 0)

    local Middle = DT:NewAnchor('Window-Middle', self.Bottom)
    Middle:SetSize(Width, Height)
    Middle:SetPoint('LEFT', Left, 'RIGHT', 0, 0)

    local Right = DT:NewAnchor('Window-Right', self.Bottom)
    Right:SetSize(Width, Height)
    Right:SetPoint('LEFT', Middle, 'RIGHT', 0, 0)

    DT:SetDataText('Window-Left', C['data-text-extra-left'])
    DT:SetDataText('Window-Middle', C['data-text-extra-middle'])
    DT:SetDataText('Window-Right', C['data-text-extra-right'])
end

function Window:UpdateDataTexts()
    local Width = self.Bottom:GetWidth() / 3

    local Left = DT:GetAnchor('Window-Left')
    Left:SetWidth(Width)
    Left:ClearAllPoints()
    Left:SetPoint('LEFT', self.Bottom, 0, 0)

    local Middle = DT:GetAnchor('Window-Middle')
    Middle:SetWidth(Width)
    Middle:ClearAllPoints()
    Middle:SetPoint('LEFT', Left, 'RIGHT', 0, 0)

    local Right = DT:GetAnchor('Window-Right')
    Right:SetWidth(Width)
    Right:ClearAllPoints()
    Right:SetPoint('LEFT', Middle, 'RIGHT', 0, 0)
end

function Window:Load()
    DT = Y:GetModule('DataText')

    if (not C['right-window-enable']) then
        return
    end

    self:SetSize(C['right-window-width'], C['right-window-height'] + C['right-window-bottom-height'] + C['right-window-top-height']) -- Border fix me
    self:SetPoint('BOTTOMRIGHT', Y.UIParent, -5, 5)
    self:SetFrameStrata('BACKGROUND')

    if (C['right-window-size'] == 'SINGLE') then
        self:CreateSingleWindow()
    else
        self:CreateDoubleWindow()
    end

    self:AddDataTexts()

    Y:CreateMover(self)
end

local UpdateOpacity = function(value)
    if (C['right-window-size'] == 'SINGLE') then
        local R, G, B = Y:HexToRGB(C['ui-window-main-color'])

        Window.Middle.Outside:SetBackdropColor(R, G, B, (C['right-window-fill'] / 100))
    end
end

local UpdateLeftOpacity = function(value)
    if (C['right-window-size'] ~= 'SINGLE') then
        local R, G, B = Y:HexToRGB(C['ui-window-main-color'])

        Window.Left.Outside:SetBackdropColor(R, G, B, (value / 100))
    end
end

local UpdateRightOpacity = function(value)
    if (C['right-window-size'] ~= 'SINGLE') then
        local R, G, B = Y:HexToRGB(C['ui-window-main-color'])

        Window.Right.Outside:SetBackdropColor(R, G, B, (value / 100))
    end
end

local UpdateWidth = function(value)
    if (C['right-window-size'] == 'SINGLE') then
        Window.Bottom:SetWidth(value)
        Window.Middle:SetWidth(value)
        Window.Top:SetWidth(value)
    else
        local LeftWidth = (value * C['right-window-middle-pos'] / 100)
        local RightWidth = (value - LeftWidth) + (C['ui-border-thickness'] < 2 and 1 or 0)

        Window.Bottom:SetWidth(value)
        Window.Left:SetWidth(LeftWidth)
        Window.TopLeft:SetWidth(LeftWidth)
        Window.Right:SetWidth(RightWidth)
        Window.TopRight:SetWidth(RightWidth)
    end

    Window:UpdateDataTexts()
end

local UpdateHeight = function(value)
    if (C['right-window-size'] == 'SINGLE') then
        Window.Middle:SetHeight(value)
    else
        Window.Left:SetHeight(value)
        Window.Right:SetHeight(value)
    end
end

local UpdateSplitPosition = function(value)
    if (C['right-window-size'] == 'SINGLE') then
        return
    end

    local Width = C['right-window-width']
    local LeftWidth = (Width * value / 100)
    local RightWidth = (Width - LeftWidth) + (C['ui-border-thickness'] < 2 and 1 or 0)

    Window.Left:SetWidth(LeftWidth)
    Window.TopLeft:SetWidth(LeftWidth)

    Window.Right:SetWidth(RightWidth)
    Window.TopRight:SetWidth(RightWidth)
end

local UpdateRightChatWindow = function()
    Chat:MoveChatFrames()
end

local GetChatFrameList = function()
    local Frames = {
        [L['None']] = 'None'
    }
    local Frame
    local Tab

    for i = 4, NUM_CHAT_WINDOWS do
        Frame = _G['ChatFrame' .. i]
        Tab = _G[Frame:GetName() .. 'Tab']

        -- if Frame.name and Tab and Tab:IsVisible() and (not match(Frame.name, CHAT_LABEL .. "%s%d+")) then
        if Frame.name and Tab and (not match(Frame.name, CHAT_LABEL .. '%s%d+')) then
            Frames[Frame.name] = Frame.name
        end
    end

    return Frames
end

Y:GetModule('GUI'):AddWidgets(L['General'], L['Right'], L['Chat'], function(left, right)
    left:CreateHeader(L['General'])
    left:CreateSwitch('right-window-enable', C['right-window-enable'], L['Enable Right Window'], L['Enable the right side window, for placing chat or addons into'], ReloadUI):RequiresReload(true)
    left:CreateSlider('right-window-width', C['right-window-width'], 300, 650, 1, L['Window Width'], L['Set the width of the window'], UpdateWidth)
    left:CreateSlider('right-window-height', C['right-window-height'], 40, 350, 1, L['Window Height'], L['Set the height of the window'], UpdateHeight)

    local Single = left:CreateSlider('right-window-fill', C['right-window-fill'], 0, 100, 5, L['Background Opacity'], L['Set the opacity of the window background'], UpdateOpacity, nil, '%')
    local Left = left:CreateSlider('right-window-left-fill', C['right-window-left-fill'], 0, 100, 5, L['Left Opacity'], L['Set the opacity of the left window background'], UpdateLeftOpacity, nil, '%')
    local Right = left:CreateSlider('right-window-right-fill', C['right-window-right-fill'], 0, 100, 5, L['Right Opacity'], L['Set the opacity of the right window background'], UpdateRightOpacity, nil, '%')

    left:CreateSlider('right-window-middle-pos', C['right-window-middle-pos'], 1, 99, 1, 'Set divider', 'blah', UpdateSplitPosition, nil, '%')

    if (C['right-window-size'] == 'SINGLE') then
        Left:GetParent():Disable()
        Right:GetParent():Disable()
    else
        Single:GetParent():Disable()
    end

    right:CreateHeader('Window Style')
    right:CreateDropdown('right-window-size', C['right-window-size'], {
        [L['Single']] = 'SINGLE',
        [L['Double']] = 'DOUBLE'
    }, L['Set Window Size'], L['Set the number of windows to be displayed'], ReloadUI):RequiresReload(true)

    right:CreateHeader('Single Window Embed')
    right:CreateDropdown('rw-single-embed', C['rw-single-embed'], GetChatFrameList(), L['Select Chat'], L['Set which chat frame should be in the right window'], UpdateRightChatWindow)
end)
