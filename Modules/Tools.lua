local YxUI, Language, Assets, Settings, Defaults = select(2, ...):get()

local tonumber = tonumber
local tostring = tostring
local select = select
local date = date
local sub = string.sub
local format = string.format
local floor = math.floor
local match = string.match
local reverse = string.reverse
local IsAddOnLoaded = IsAddOnLoaded or C_AddOns.IsAddOnLoaded

-- Tools
function YxUI:HexToRGB(hex)
    if (not hex) then
        return
    end

    return tonumber('0x' .. sub(hex, 1, 2)) / 255, tonumber('0x' .. sub(hex, 3, 4)) / 255, tonumber('0x' .. sub(hex, 5, 6)) / 255
end

function YxUI:RGBToHex(r, g, b)
    return format('%02x%02x%02x', r * 255, g * 255, b * 255)
end

----------------------------------------------------------------------------------------
--	Chat channel check
----------------------------------------------------------------------------------------
function YxUI:CheckChat(warning)
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return 'INSTANCE_CHAT'
    elseif IsInRaid(LE_PARTY_CATEGORY_HOME) then
        if warning and (UnitIsGroupLeader('player') or UnitIsGroupAssistant('player') or IsEveryoneAssistant()) then
            return 'RAID_WARNING'
        end
        return 'RAID'
    elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
        return 'PARTY'
    end
    return 'EMOTE'
end

function YxUI:FormatTime(seconds)
    if (seconds > 86399) then
        return format('%dd', ceil(seconds / 86400))
    elseif (seconds > 3599) then
        return format('%dh', ceil(seconds / 3600))
    elseif (seconds > 59) then
        return format('%dm', ceil(seconds / 60))
    elseif (seconds > 5) then
        return format('%ds', floor(seconds))
    end

    return format('%.1fs', seconds)
end

function YxUI:FormatFullTime(seconds)
    local Days = floor(seconds / 86400)
    local Hours = floor((seconds % 86400) / 3600)
    local Mins = floor((seconds % 3600) / 60)

    if (Days > 0) then
        return format('%dd', Days)
    elseif (Hours > 0) then
        return format('%dh %sm', Hours, Mins)
    elseif (Mins > 0) then
        return format('%sm', Mins)
    else
        return format('%ss', floor(seconds))
    end
end

function YxUI:AuraFormatTime(seconds)
    if (seconds > 86399) then
        return format('%dd', ceil(seconds / 86400))
    elseif (seconds > 3599) then
        return format('%dh', ceil(seconds / 3600))
    elseif (seconds > 59) then
        return format('%dm', ceil(seconds / 60))
    elseif (seconds > 5) then
        return format('%d', floor(seconds))
    end

    return format('%.1f', seconds)
end

function YxUI:ShortValue(num)
    if (num > 999999) then
        return format('%.2fm', num / 1000000)
    elseif (num > 999) then
        return format('%.1fk', num / 1000)
    end

    return num
end

function YxUI:Comma(number)
    if (not number) then
        return
    end

    local Left, Number = match(floor(number + 0.5), '^([^%d]*%d)(%d+)(.-)$')

    return Left and Left .. reverse(gsub(reverse(Number), '(%d%d%d)', '%1,')) or number
end

function YxUI:CopperToGold(copper)
    local Gold = floor(copper / (100 * 100))
    local Silver = floor((copper - (Gold * 100 * 100)) / 100)
    local Copper = floor(copper % 100)
    local Separator = ''
    local String = ''

    if (Gold > 0) then
        String = self:Comma(Gold) .. '|cffffe02eg|r'
        Separator = ' '
    end

    if (Silver > 0) then
        if (Silver < 10) then
            Silver = '0' .. Silver
        end

        String = String .. Separator .. Silver .. '|cffd6d6d6s|r'
        Separator = ' '
    end

    if (Copper > 0 or String == '') then
        if (Copper < 10) then
            Copper = '0' .. Copper
        end

        String = String .. Separator .. Copper .. '|cfffc8d2bc|r'
    end

    return String
end

function YxUI:GetCurrentDate()
    return date('%Y-%m-%d %I:%M %p')
end

-- If the date given is today, change "2019-07-24 2:06 PM" to "Today 2:06 PM"
function YxUI:IsToday(s)
    local Date, Time = match(s, '(%d+%-%d+%-%d+)%s(.+)')

    if (not Date or not Time) then
        return s
    end

    if (Date == date('%Y-%m-%d')) then
        s = format('%s %s', Language['Today'], Time)
    end

    return s
end

function YxUI:BindSavedVariable(global, key)
    if (not _G[global]) then
        _G[global] = {}
    end

    if (not self[key]) then
        self[key] = _G[global]
    end
end

local ResetOnAccept = function()
    YxUIProfileData = nil
    YxUIProfiles = nil
    YxUIData = nil
    YxUIGold = nil

    ReloadUI()
end

function YxUI:Reset()
    YxUI:DisplayPopup(Language['Attention'], Language['This action will delete ALL saved UI information. Are you sure you wish to continue?'], ACCEPT, ResetOnAccept, CANCEL)
end

local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME

local NewPrint = function(...)
    local NumArgs = select('#', ...)
    local String = ''

    if (NumArgs == 0) then
        return
    elseif (NumArgs > 1) then
        for i = 1, NumArgs do
            if (i == 1) then
                String = tostring(select(i, ...))
            else
                String = format('%s %s', String, tostring(select(i, ...)))
            end
        end

        if YxUI.FormatLinks then
            String = YxUI.FormatLinks(String)
        end

        DEFAULT_CHAT_FRAME:AddMessage(String)
    else
        if YxUI.FormatLinks then
            String = YxUI.FormatLinks(tostring(...))

            DEFAULT_CHAT_FRAME:AddMessage(String)
        else
            DEFAULT_CHAT_FRAME:AddMessage(...)
        end
    end
end

if not IsAddOnLoaded('!!!tdDevTools') then
    setprinthandler(NewPrint)
end

function YxUI:print(...)
    if Settings['ui-widget-color'] then
        NewPrint('|cFF' .. Settings['ui-widget-color'] .. 'Yx|rUI:', ...)
    else
        NewPrint('|cFF' .. Defaults['ui-widget-color'] .. 'Yx|rUI:', ...)
    end
end

-- Adaptive fonts
-- The shipped fonts only cover Latin plus a few extra scripts. Unit frame tags
-- set them to arbitrary player/NPC names, so a name written in Cyrillic, Greek,
-- CJK or Vietnamese would render as boxes. AdaptFontForText keeps per-object
-- state and swaps in a font that covers the detected script, falling back to the
-- configured font whenever the fallback is unavailable.
--
-- Declared before SetFontInfo because SetFontInfo invalidates this cache.
local AdaptiveFonts = setmetatable({}, {
    __mode = 'k'
})

function YxUI:SetFontInfo(object, font, size, flags)
    if (not object) then
        return
    end

    local Font, IsPixel = Assets:GetFont(font)

    if IsPixel then
        object:SetFont(Font, size, 'MONOCHROME, OUTLINE')
        object:SetShadowColor(0, 0, 0, 0)
    else
        object:SetFont(Font, size, flags or '')
        object:SetShadowColor(0, 0, 0)
        object:SetShadowOffset(1, -1)
    end

    -- Any previously adapted font string is stale now and has to be re-evaluated
    -- the next time its text is set.
    if AdaptiveFonts[object] then
        AdaptiveFonts[object].Dirty = true
        object.__yxuiAdaptiveDirty = true
    end
end

-- Adaptive fonts

local ScriptFonts = {
    koKR = 'Fonts\\2002.TTF',
    zhCN = 'Fonts\\ARKai_T.ttf',
    zhTW = 'Fonts\\blei00d.TTF',
    ruRU = 'Fonts\\FRIZQT___CYR.TTF',
    greek = Assets:GetFont('Noto Sans'),
    vietnamese = Assets:GetFont('Noto Sans')
}

local SupportedScripts = {
    ['Roboto'] = {
        ruRU = true,
        greek = true,
        vietnamese = true
    },
    ['Noto Sans'] = {
        ruRU = true,
        greek = true,
        vietnamese = true
    },
    ['Expressway'] = {
        ruRU = true
    },
    ['PT Sans'] = {
        ruRU = true
    }
}

local IsRestrictedText = function(text)
    return YxUI.IsMainline and issecretvalue and issecretvalue(text) and
               (not canaccessvalue or not canaccessvalue(text))
end

local ChineseScript = function(self, locale)
    if (locale == 'zhCN' or locale == 'zhTW') then
        return locale
    end

    if (self.UserLocale == 'zhCN' or self.UserLocale == 'zhTW') then
        return self.UserLocale
    end

    if (self.ClientLocale == 'zhCN' or self.ClientLocale == 'zhTW') then
        return self.ClientLocale
    end

    return 'zhCN'
end

local GetTextScript = function(self, text, locale)
    if (not text:find('[\128-\255]')) then
        return
    end

    local i, Length = 1, #text

    while (i <= Length) do
        local A = text:byte(i)

        if (A >= 0xC2 and A <= 0xDF and i < Length) then
            local B = text:byte(i + 1)

            if (B >= 0x80 and B <= 0xBF) then
                local Code = (A - 0xC0) * 64 + B - 0x80

                if (Code >= 0x0400 and Code <= 0x052F) then
                    return 'ruRU'
                elseif (Code >= 0x0370 and Code <= 0x03FF) then
                    return 'greek'
                end
            end

            i = i + 2
        elseif (A >= 0xE0 and A <= 0xEF and i + 2 <= Length) then
            local B, C = text:byte(i + 1, i + 2)

            if (B >= 0x80 and B <= 0xBF and C >= 0x80 and C <= 0xBF) then
                local Code = (A - 0xE0) * 4096 + (B - 0x80) * 64 + C - 0x80

                if ((Code >= 0x1100 and Code <= 0x11FF) or (Code >= 0x3130 and Code <= 0x318F) or (Code >= 0xAC00 and Code <= 0xD7AF)) then
                    return 'koKR'
                elseif ((Code >= 0x3400 and Code <= 0x9FFF) or (Code >= 0xF900 and Code <= 0xFAFF)) then
                    return ChineseScript(self, locale)
                elseif (Code >= 0x1EA0 and Code <= 0x1EF9) then
                    return 'vietnamese'
                end
            end

            i = i + 3
        else
            i = i + 1
        end
    end
end

function YxUI:AdaptFontForText(object, text, font, size, flags, locale)
    if (not object) or IsRestrictedText(text) or type(text) ~= 'string' then
        return
    end

    local State = AdaptiveFonts[object]
    local SameStyle = State and State.Font == font and State.Size == size and State.Flags == flags and State.Locale == locale

    if (SameStyle and State.Text == text and not State.Dirty) then
        return State.Applied
    end

    local Script = GetTextScript(self, text, locale)
    local Coverage = SupportedScripts[font]
    local Path = Script and not (Coverage and Coverage[Script]) and ScriptFonts[Script]
    local Applied

    if Path then
        if (SameStyle and State.Path == Path and not State.Dirty) then
            Applied = State.Applied
        else
            local Ok, Result = pcall(object.SetFont, object, Path, size, flags or '')

            Applied = Ok and Result == true

            if (not Applied) then
                self:SetFontInfo(object, font, size, flags)
            end
        end
    else
        self:SetFontInfo(object, font, size, flags)
    end

    if (not State) then
        State = {}
        AdaptiveFonts[object] = State
    end

    State.Text, State.Font, State.Size, State.Flags = text, font, size, flags
    State.Locale, State.Path, State.Applied, State.Dirty = locale, Path, Applied, nil

    object.__yxuiAdaptiveDirty = nil

    return Path and Applied
end

function YxUI:SetFontForText(object, text, font, size, flags, locale)
    if (not object) then
        return
    end

    self:SetFontInfo(object, font, size, flags)

    return self:AdaptFontForText(object, text, font, size, flags, locale)
end

-- Backdrops
YxUI.Backdrop = {
    bgFile = 'Interface\\AddOns\\YxUI\\Media\\Textures\\YxUIBlank.tga',
    insets = {
        top = 0,
        left = 0,
        bottom = 0,
        right = 0
    }
}

YxUI.BackdropAndBorder = {
    bgFile = 'Interface\\AddOns\\YxUI\\Media\\Textures\\YxUIBlank.tga',
    edgeFile = 'Interface\\AddOns\\YxUI\\Media\\Textures\\YxUIBlank.tga',
    edgeSize = 1,
    insets = {
        top = 0,
        left = 0,
        bottom = 0,
        right = 0
    }
}

YxUI.Outline = {
    edgeFile = 'Interface\\AddOns\\YxUI\\Media\\Textures\\YxUIBlank.tga',
    edgeSize = 1,
    insets = {
        left = 0,
        right = 0,
        top = 0,
        bottom = 0
    }
}

local Outside = {
    edgeFile = 'Interface\\AddOns\\YxUI\\Media\\Textures\\YxUIBlank.tga'
}

local Inside = {
    bgFile = 'Interface\\AddOns\\YxUI\\Media\\Textures\\YxUIBlank.tga',
    edgeFile = 'Interface\\AddOns\\YxUI\\Media\\Textures\\YxUIBlank.tga'
}

function YxUI:AddBackdrop(frame, texture)
    if (frame.Outside or frame.Inside) then
        return
    end

    local Border = Settings['ui-border-thickness']

    Outside.edgeSize = 1 > Border and 1 or (Border + 2)
    Inside.edgeSize = Border

    if texture then
        Outside.bgFile = texture
    else
        Outside.bgFile = Assets:GetTexture('Blank')
    end

    frame.Outside = CreateFrame('Frame', nil, frame, 'BackdropTemplate')
    frame.Outside:SetAllPoints()
    frame.Outside:SetBackdrop(Outside)
    frame.Outside:SetBackdropBorderColor(0, 0, 0)
    frame.Outside:SetBackdropColor(0, 0, 0, 0)

    if (Border == 0) then
        return
    end

    frame.Inside = CreateFrame('Frame', nil, frame, 'BackdropTemplate')
    frame.Inside:SetPoint('TOPLEFT', 1, -1)
    frame.Inside:SetPoint('BOTTOMRIGHT', -1, 1)
    frame.Inside:SetFrameLevel(frame.Outside:GetFrameLevel() + 1)
    frame.Inside:SetBackdrop(Inside)
    frame.Inside:SetBackdropBorderColor(YxUI:HexToRGB(Settings['ui-window-bg-color']))
    frame.Inside:SetBackdropColor(0, 0, 0, 0)
end

-- NYI, Concept list for my preferred CVars, and those important to the UI
function YxUI:SetCVars()
    C_CVar.SetCVar('countdownForCooldowns', 1)

    -- Name plates
    C_CVar.SetCVar('NameplatePersonalShowAlways', 0)
    C_CVar.SetCVar('NameplatePersonalShowInCombat', 0)
    C_CVar.SetCVar('NameplatePersonalShowWithTarget', 0)
end

function YxUI:GetRoleIcon(role)
    return format([[Interface\AddOns\YxUI\Media\Textures\Icon\%s.tga]], role)
end
