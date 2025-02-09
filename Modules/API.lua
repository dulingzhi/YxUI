---@class YxUI
local Y, L, A, C, D = YxUIGlobal:get()

local backdropr, backdropg, backdropb, backdropa
local borderr, borderg, borderb, bordera

local Mult = Y.Mult
if Y.ScreenHeight > 1200 then
    Mult = Y.Scale(1)
end

-- Utility Functions
local function rad(degrees)
	return degrees * math.pi / 180
end

-- Set Border Color
do
    function Y.SetBorderColor(self)
        -- Prevent issues related to invalid inputs or configurations
        if not self or type(self) ~= 'table' or not self.SetVertexColor then
            return
        end

        self:SetVertexColor(1, 1, 1) -- Default color
    end
end

----------------------------------------------------------------------------------------
--	Position functions
----------------------------------------------------------------------------------------
local function SetOutside(obj, anchor, xOffset, yOffset)
    xOffset = xOffset or 2
    yOffset = yOffset or 2
    anchor = anchor or obj:GetParent()

    if obj:GetPoint() then
        obj:ClearAllPoints()
    end

    obj:SetPoint('TOPLEFT', anchor, 'TOPLEFT', -xOffset, yOffset)
    obj:SetPoint('BOTTOMRIGHT', anchor, 'BOTTOMRIGHT', xOffset, -yOffset)
end

local function SetInside(obj, anchor, xOffset, yOffset)
    xOffset = xOffset or 2
    yOffset = yOffset or 2
    anchor = anchor or obj:GetParent()

    if obj:GetPoint() then
        obj:ClearAllPoints()
    end

    obj:SetPoint('TOPLEFT', anchor, 'TOPLEFT', xOffset, -yOffset)
    obj:SetPoint('BOTTOMRIGHT', anchor, 'BOTTOMRIGHT', -xOffset, yOffset)
end

----------------------------------------------------------------------------------------
--	Template functions
----------------------------------------------------------------------------------------
local function CreateOverlay(f)
    if f.overlay then
        return
    end

    local overlay = f:CreateTexture('$parentOverlay', 'BORDER')
    overlay:SetInside()
    overlay:SetTexture([[Interface\AddOns\YxUI\Media\Textures\YxUIBlank.tga]])
    overlay:SetVertexColor(0.1, 0.1, 0.1, 1)
    f.overlay = overlay
end

local function CreateBorder(bFrame, ...)
    if not bFrame or type(bFrame) ~= 'table' then
        return nil, 'Invalid frame provided'
    end

    local bSubLevel, bLayer, bSize, bTexture, bOffset, bColor, bgTexture, bgSubLevel, bgLayer, bgPoint, bgColor = ...
    local BorderSize = 12

    if not bFrame.YxUIBorder then
        local BorderTexture = bTexture or A:GetBorder('YxUI')
        local BorderOffset = bOffset or -4
        local BorderColor = bColor or {1, 1, 1}

        local border = Y.CreateBorder(bFrame, bSubLevel or 'OVERLAY', bLayer or 1)
        border:SetSize(BorderSize)
        border:SetTexture(BorderTexture)
        border:SetOffset(BorderOffset)

        local r, g, b = unpack(BorderColor)
        border:SetVertexColor(r, g, b)

        bFrame.YxUIBorder = border
    end

    if not bFrame.YxUIBackground then
        local BackgroundTexture = bgTexture or 'Interface\\BUTTONS\\WHITE8X8'
        local BackgroundSubLevel = bgSubLevel or 'BACKGROUND'
        local BackgroundLayer = bgLayer or -2
        local BackgroundPoint = bgPoint or 0
        local BackgroundColor = bgColor or {0.060, 0.060, 0.060, 0.9}

        local background = bFrame:CreateTexture(nil, BackgroundSubLevel, nil, BackgroundLayer)
        background:SetTexture(BackgroundTexture, true, true)
        background:SetTexCoord(Y.TexCoords[1], Y.TexCoords[2], Y.TexCoords[3], Y.TexCoords[4])
        background:SetPoint('TOPLEFT', bFrame, 'TOPLEFT', BackgroundPoint, -BackgroundPoint)
        background:SetPoint('BOTTOMRIGHT', bFrame, 'BOTTOMRIGHT', -BackgroundPoint, BackgroundPoint)
        background:SetVertexColor(unpack(BackgroundColor))

        bFrame.YxUIBackground = background
    end

    return bFrame
end

local function GetTemplate(t)
    if t == 'ClassColor' then
        borderr, borderg, borderb, bordera = Y.UserColor.r, Y.UserColor.g, Y.UserColor.b, 1
        backdropr, backdropg, backdropb, backdropa = 0, 0, 0, 1
    else
        borderr, borderg, borderb, bordera = 0.1, 0.1, 0.1, 1
        backdropr, backdropg, backdropb, backdropa = 0, 0, 0, 1
    end
end

local function SetTemplate(f, t)
    Mixin(f, BackdropTemplateMixin) -- 9.0 to set backdrop
    GetTemplate(t)

    f:SetBackdrop({
        bgFile = [[Interface\AddOns\YxUI\Media\Textures\YxUIBlank.tga]],
        edgeFile = [[Interface\AddOns\YxUI\Media\Textures\YxUIBlank.tga]],
        edgeSize = Mult,
        insets = {
            left = -Mult,
            right = -Mult,
            top = -Mult,
            bottom = -Mult
        }
    })

    if t == 'Transparent' then
        backdropa = 0.7
        f:CreateBorder(true, true)
    elseif t == 'Overlay' then
        backdropa = 1
        f:CreateOverlay()
    else
        backdropa = 1
    end

    f:SetBackdropColor(backdropr, backdropg, backdropb, backdropa)
    f:SetBackdropBorderColor(borderr, borderg, borderb, bordera)
end

local function CreatePanel(f, t, w, h, a1, p, a2, x, y)
    Mixin(f, BackdropTemplateMixin) -- 9.0 to set backdrop
    GetTemplate(t)

    f:SetWidth(w)
    f:SetHeight(h)
    f:SetFrameLevel(3)
    f:SetFrameStrata('BACKGROUND')
    f:SetPoint(a1, p, a2, x, y)
    f:SetBackdrop({
        bgFile = C.media.blank,
        edgeFile = C.media.blank,
        edgeSize = Mult,
        insets = {
            left = -Mult,
            right = -Mult,
            top = -Mult,
            bottom = -Mult
        }
    })

    if t == 'Transparent' then
        backdropa = C.media.backdrop_alpha
        f:CreateBorder(true, true)
    elseif t == 'Overlay' then
        backdropa = 1
        f:CreateOverlay()
    elseif t == 'Invisible' then
        backdropa = 0
        bordera = 0
    else
        backdropa = C.media.backdrop_color[4]
    end

    f:SetBackdropColor(backdropr, backdropg, backdropb, backdropa)
    f:SetBackdropBorderColor(borderr, borderg, borderb, bordera)
end

local function CreateBackdrop(bFrame, ...)
    if not bFrame or type(bFrame) ~= 'table' then
        return nil, 'Invalid frame provided'
    end

    local bPointa, bPointb, bPointc, bPointd, bSubLevel, bLayer, bSize, bTexture, bOffset, bColor, bAlpha, bgTexture, bgSubLevel, bgLayer, bgPoint, bgColor = ...

    if not bFrame.YxUIBackground then
        -- Assign default values if not provided
        local BorderPoints = {bPointa or 0, bPointb or 0, bPointc or 0, bPointd or 0}

        local backdrop = CreateFrame('Frame', '$parentBackdrop', bFrame, 'BackdropTemplate')
        backdrop:SetPoint('TOPLEFT', bFrame, 'TOPLEFT', BorderPoints[1], BorderPoints[2])
        backdrop:SetPoint('BOTTOMRIGHT', bFrame, 'BOTTOMRIGHT', BorderPoints[3], BorderPoints[4])

        -- Ensure CreateBorder function exists and is callable
        if type(backdrop.CreateBorder) == 'function' then
            backdrop:CreateBorder(bSubLevel, bLayer, bSize, bTexture, bOffset, bColor, bAlpha, bgTexture, bgSubLevel, bgLayer, bgPoint, bgColor)
        end

        backdrop:SetFrameLevel(max(0, bFrame:GetFrameLevel() - 1))

        bFrame.YxUIBackground = backdrop
    end

    return bFrame
end

local StripTexturesBlizzFrames = {'Inset', 'inset', 'InsetFrame', 'LeftInset', 'RightInset', 'NineSlice', 'BG', 'Bg', 'border', 'Border', 'BorderFrame', 'bottomInset', 'BottomInset', 'bgLeft', 'bgRight', 'FilligreeOverlay',
                                  'PortraitOverlay', 'ArtOverlayFrame', 'Portrait', 'portrait', 'ScrollFrameBorder'}

local function StripTextures(object, kill)
    if object.GetNumRegions then
        for _, region in next, {object:GetRegions()} do
            if region and region.IsObjectType and region:IsObjectType('Texture') then
                if kill then
                    region:Kill()
                else
                    region:SetTexture(0)
                    region:SetAtlas('')
                end
            end
        end
    end

    local frameName = object.GetName and object:GetName()
    for _, blizzard in pairs(StripTexturesBlizzFrames) do
        local blizzFrame = object[blizzard] or frameName and _G[frameName .. blizzard]
        if blizzFrame then
            blizzFrame:StripTextures(kill)
        end
    end
end

----------------------------------------------------------------------------------------
--	Kill object function
----------------------------------------------------------------------------------------
local HiddenFrame = CreateFrame('Frame')
HiddenFrame:Hide()
Y.Hider = HiddenFrame
local function Kill(object)
    if object.UnregisterAllEvents then
        object:UnregisterAllEvents()
        object:SetParent(HiddenFrame)
    else
        object.Show = Y.Dummy
    end
    object:Hide()
end

----------------------------------------------------------------------------------------
--	Style ActionBars/Bags buttons function(by Chiril & Karudon)
----------------------------------------------------------------------------------------

-- Create Texture
local function CreateTexture(button, noTexture, texturePath, desaturated, vertexColor, setPoints)
    if not noTexture then
        local texture = button:CreateTexture()
        texture:SetTexture(texturePath)
        texture:SetPoint('TOPLEFT', button, 'TOPLEFT', setPoints, -setPoints)
        texture:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', -setPoints, setPoints)
        texture:SetBlendMode('ADD')

        if desaturated then
            texture:SetDesaturated(true)
        end

        if vertexColor then
            texture:SetVertexColor(unpack(vertexColor))
        end

        return texture
    end
end

local function StyleButton(button, noHover, noPushed, noChecked, setPoints)
    -- setPoints default value is 0
    setPoints = setPoints or 0

    -- Create highlight, pushed, and checked textures for the button if they do not exist
    if button.SetHighlightTexture and not noHover then
        button.hover = CreateTexture(button, noHover, 'Interface\\Buttons\\ButtonHilight-Square', false, nil, setPoints)
        button:SetHighlightTexture(button.hover)
    end

    if button.SetPushedTexture and not noPushed then
        button.pushed = CreateTexture(button, noPushed, 'Interface\\Buttons\\ButtonHilight-Square', true, {246 / 255, 196 / 255, 66 / 255}, setPoints)
        button:SetPushedTexture(button.pushed)
    end

    if button.SetCheckedTexture and not noChecked then
        button.checked = CreateTexture(button, noChecked, 'Interface\\Buttons\\CheckButtonHilight', false, nil, setPoints)
        button:SetCheckedTexture(button.checked)
    end

    local name = button.GetName and button:GetName()
    local cooldown = name and _G[name .. 'Cooldown']

    if cooldown then
        cooldown:ClearAllPoints()
        cooldown:SetPoint('TOPLEFT', button, 'TOPLEFT', 1, -1)
        cooldown:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', -1, 1)
        cooldown:SetDrawEdge(false)
        cooldown:SetSwipeColor(0, 0, 0, 1)
    end
end

----------------------------------------------------------------------------------------
--	Style buttons function
----------------------------------------------------------------------------------------
local function Button_OnEnter(self)
    if not self:IsEnabled() then
        return
    end

    self.YxUIBorder:SetVertexColor(102 / 255, 157 / 255, 255 / 255)
end

local function Button_OnLeave(self)
    Y.SetBorderColor(self.YxUIBorder)
end

-- Skin Button
local blizzRegions = {'Left', 'Middle', 'Right', 'TopLeft', 'TopRight', 'BottomLeft', 'BottomRight', 'Background', 'Border', 'Center'}

local function SkinButton(self, override, ...)
    local bSubLevel, bLayer, bSize, bTexture, bOffset, bColor, bgTexture, bgSubLevel, bgLayer, bgPoint, bgColor = ...
    -- Remove the normal, highlight, pushed and disabled textures
    if self.SetNormalTexture and not override then
        self:SetNormalTexture(0)
    end

    if self.SetHighlightTexture then
        self:SetHighlightTexture(0)
    end

    if self.SetPushedTexture then
        self:SetPushedTexture(0)
    end

    if self.SetDisabledTexture then
        self:SetDisabledTexture(0)
    end

    -- Hide all regions defined in the blizzRegions table
    for _, region in pairs(blizzRegions) do
        if self[region] then
            self[region]:SetAlpha(0)
            self[region]:Hide()
        end
    end

    -- Do not apply custom border if the override argument is true
    self:CreateBorder(bSubLevel, bLayer, bSize, bTexture, bOffset, bColor, bgTexture, bgSubLevel, bgLayer, bgPoint, bgColor)

    -- Hook the OnEnter and OnLeave events
    self:HookScript('OnEnter', Button_OnEnter)
    self:HookScript('OnLeave', Button_OnLeave)
end

----------------------------------------------------------------------------------------
--	Style icon function
----------------------------------------------------------------------------------------
local function SkinIcon(icon, t, parent)
    parent = parent or icon:GetParent()

    if t then
        icon.b = CreateFrame('Frame', nil, parent)
        icon.b:SetTemplate('Default')
        icon.b:SetOutside(icon)
    else
        parent:CreateBackdrop('Default')
        parent.backdrop:SetOutside(icon)
    end

    icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    icon:SetParent(t and icon.b or parent)
end

local function CropIcon(icon)
    icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    icon:SetInside()
end

----------------------------------------------------------------------------------------
--	Font function
----------------------------------------------------------------------------------------
local function FontString(parent, name, fontName, fontHeight, fontStyle)
    local fs = parent:CreateFontString(nil, 'OVERLAY')
    fs:SetFont(fontName, fontHeight, fontStyle)
    fs:SetJustifyH('LEFT')

    if not name then
        parent.text = fs
    else
        parent[name] = fs
    end

    return fs
end

----------------------------------------------------------------------------------------
--	Inject API functions into Blizzard frames
----------------------------------------------------------------------------------------
local function FadeIn(f)
    UIFrameFadeIn(f, 0.4, f:GetAlpha(), 1)
end

local function FadeOut(f)
    UIFrameFadeOut(f, 0.8, f:GetAlpha(), 0)
end

local function attachAPI(object)
    local mt = getmetatable(object).__index
    if not object.SetOutside then
        mt.SetOutside = SetOutside
    end
    if not object.SetInside then
        mt.SetInside = SetInside
    end
    if not object.CreateOverlay then
        mt.CreateOverlay = CreateOverlay
    end
    if not object.CreateBorder then
        mt.CreateBorder = CreateBorder
    end
    if not object.SetTemplate then
        mt.SetTemplate = SetTemplate
    end
    if not object.CreatePanel then
        mt.CreatePanel = CreatePanel
    end
    if not object.CreateBackdrop then
        mt.CreateBackdrop = CreateBackdrop
    end
    if not object.StripTextures then
        mt.StripTextures = StripTextures
    end
    if not object.Kill then
        mt.Kill = Kill
    end
    if not object.StyleButton then
        mt.StyleButton = StyleButton
    end
    if not object.SkinButton then
        mt.SkinButton = SkinButton
    end
    if not object.SkinIcon then
        mt.SkinIcon = SkinIcon
    end
    if not object.CropIcon then
        mt.CropIcon = CropIcon
    end
    if not object.FontString then
        mt.FontString = FontString
    end
    if not object.FadeIn then
        mt.FadeIn = FadeIn
    end
    if not object.FadeOut then
        mt.FadeOut = FadeOut
    end
end

local handled = {
    ['Frame'] = true
}
local object = CreateFrame('Frame')
attachAPI(object)
attachAPI(object:CreateTexture())
attachAPI(object:CreateFontString())

object = EnumerateFrames()
while object do
    if not object:IsForbidden() and not handled[object:GetObjectType()] then
        attachAPI(object)
        handled[object:GetObjectType()] = true
    end

    object = EnumerateFrames(object)
end

-- Hacky fix for issue on 7.1 PTR where scroll frames no longer seem to inherit the methods from the "Frame" widget
local scrollFrame = CreateFrame('ScrollFrame')
attachAPI(scrollFrame)

----------------------------------------------------------------------------------------
--	Style functions
----------------------------------------------------------------------------------------
-- Setup Arrow
local arrowDegree = {
    ['up'] = 0,
    ['down'] = 180,
    ['left'] = 90,
    ['right'] = -90
}

function Y.SetupArrow(self, direction)
    self:SetTexture(A:GetTexture("Arrow Up"))
    self:SetRotation(rad(arrowDegree[direction]))
end

-- Reskin Arrow
function Y.ReskinArrow(self, direction)
    self:StripTextures()
    self:SetSize(16, 16)
    self:CreateBorder(nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, {0.20, 0.20, 0.20})
    self:StyleButton()

    self:SetDisabledTexture('Interface\\ChatFrame\\ChatFrameBackground')
    local dis = self:GetDisabledTexture()
    dis:SetVertexColor(0, 0, 0, 0.3)
    dis:SetDrawLayer('OVERLAY')
    dis:SetAllPoints()

    local tex = self:CreateTexture(nil, 'ARTWORK')
    tex:SetAllPoints()
    Y.SetupArrow(tex, direction)
    self.__texture = tex
end

-- Grab ScrollBar Element
local function GrabScrollBarElement(frame, element)
    local frameName = frame:GetDebugName()
    return frame[element] or frameName and (_G[frameName .. element] or string.find(frameName, element)) or nil
end

-- Skin ScrollBar (continued)
function Y.SkinScrollBar(self)
    -- Strip the textures from the parent and scrollbar frame
    self:GetParent():StripTextures()
    self:StripTextures()

    -- Get the thumb texture and set its alpha to 0, width to 16, and create a frame for it
    local thumb = GrabScrollBarElement(self, 'ThumbTexture') or GrabScrollBarElement(self, 'thumbTexture') or self.GetThumbTexture and self:GetThumbTexture()
    if thumb then
        thumb:SetAlpha(0)
        thumb:SetWidth(16)
        self.thumb = thumb

        local bg = CreateFrame('Frame', nil, self)
        -- Create a border for the frame with a dark grey color
        bg:CreateBorder(nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, {0.20, 0.20, 0.20})

        -- Set the position of the frame relative to the thumb texture
        bg:SetPoint('TOPLEFT', thumb, 0, -6)
        bg:SetPoint('BOTTOMRIGHT', thumb, 0, 6)

        -- Assign the frame to the thumb texture's background property
        thumb.bg = bg
    end

    -- Get the up and down arrows from the scrollbar frame and skin them with K.ReskinArrow() function
    local up, down = self:GetChildren()
    Y.ReskinArrow(up, 'up')
    Y.ReskinArrow(down, 'down')
end

local tabs = {'LeftDisabled', 'MiddleDisabled', 'RightDisabled', 'Left', 'Middle', 'Right'}

function Y.SkinTab(tab, bg)
    if not tab then
        return
    end

    for _, object in pairs(tabs) do
        local tex = tab:GetName() and _G[tab:GetName() .. object]
        if tex then
            tex:SetTexture(0)
        end
    end

    if tab.GetHighlightTexture and tab:GetHighlightTexture() then
        tab:GetHighlightTexture():SetTexture(0)
    else
        tab:StripTextures()
    end

    tab.backdrop = CreateFrame('Frame', nil, tab)
    tab.backdrop:SetFrameLevel(tab:GetFrameLevel() - 1)
    if bg then
        tab.backdrop:SetTemplate('Overlay')
        tab.backdrop:SetPoint('TOPLEFT', 2, -9)
        tab.backdrop:SetPoint('BOTTOMRIGHT', -2, -2)
    else
        tab.backdrop:SetTemplate('Transparent')
        if Y.IsClassic then
            tab.backdrop:SetPoint('TOPLEFT', 10, 0)
            tab.backdrop:SetPoint('BOTTOMRIGHT', -10, 6)
        else
            tab.backdrop:SetPoint('TOPLEFT', 0, -3)
            tab.backdrop:SetPoint('BOTTOMRIGHT', 0, 3)
        end
    end
end

function Y.SkinNextPrevButton(btn, left, scroll)
    local normal, pushed, disabled
    local frameName = btn.GetName and btn:GetName()
    local isPrevButton = frameName and (string.find(frameName, 'Left') or string.find(frameName, 'Prev') or string.find(frameName, 'Decrement') or string.find(frameName, 'Back')) or left
    local isScrollUpButton = frameName and string.find(frameName, 'ScrollUp') or scroll == 'Up'
    local isScrollDownButton = frameName and string.find(frameName, 'ScrollDown') or scroll == 'Down'

    if btn:GetNormalTexture() then
        normal = btn:GetNormalTexture():GetTexture()
    end

    if btn:GetPushedTexture() then
        pushed = btn:GetPushedTexture():GetTexture()
    end

    if btn:GetDisabledTexture() then
        disabled = btn:GetDisabledTexture():GetTexture()
    end

    btn:StripTextures()

    if btn.Texture then
        btn.Texture:SetAlpha(0)

        if btn.Overlay then
            btn.Overlay:SetAlpha(0)
        end
    end

    if scroll == 'Up' or scroll == 'Down' or scroll == 'Any' then
        normal = nil
        pushed = nil
        disabled = nil
    end

    if not normal then
        if isPrevButton then
            normal = 'Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up'
        elseif isScrollUpButton then
            normal = 'Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up'
        elseif isScrollDownButton then
            normal = 'Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up'
        else
            normal = 'Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up'
        end
    end

    if not pushed then
        if isPrevButton then
            pushed = 'Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down'
        elseif isScrollUpButton then
            pushed = 'Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Down'
        elseif isScrollDownButton then
            pushed = 'Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down'
        else
            pushed = 'Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down'
        end
    end

    if not disabled then
        if isPrevButton then
            disabled = 'Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled'
        elseif isScrollUpButton then
            disabled = 'Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Disabled'
        elseif isScrollDownButton then
            disabled = 'Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled'
        else
            disabled = 'Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled'
        end
    end

    btn:SetNormalTexture(normal)
    btn:SetPushedTexture(pushed)
    btn:SetDisabledTexture(disabled)

    btn:SetTemplate('Overlay')
    if Y.Wrath then
        btn:SetSize(btn:GetWidth() - 3, btn:GetHeight() - 3)
    else
        btn:SetSize(btn:GetWidth() - 7, btn:GetHeight() - 7)
    end

    if normal and pushed and disabled then
        btn:GetNormalTexture():SetTexCoord(0.3, 0.29, 0.3, 0.81, 0.65, 0.29, 0.65, 0.81)
        if btn:GetPushedTexture() then
            btn:GetPushedTexture():SetTexCoord(0.3, 0.35, 0.3, 0.81, 0.65, 0.35, 0.65, 0.81)
        end
        if btn:GetDisabledTexture() then
            btn:GetDisabledTexture():SetTexCoord(0.3, 0.29, 0.3, 0.75, 0.65, 0.29, 0.65, 0.75)
        end

        btn:GetNormalTexture():ClearAllPoints()
        btn:GetNormalTexture():SetPoint('TOPLEFT', 2, -2)
        btn:GetNormalTexture():SetPoint('BOTTOMRIGHT', -2, 2)
        if btn:GetDisabledTexture() then
            btn:GetDisabledTexture():SetAllPoints(btn:GetNormalTexture())
        end
        if btn:GetPushedTexture() then
            btn:GetPushedTexture():SetAllPoints(btn:GetNormalTexture())
        end
        if btn:GetHighlightTexture() then
            btn:GetHighlightTexture():SetColorTexture(1, 1, 1, 0.3)
            btn:GetHighlightTexture():SetAllPoints(btn:GetNormalTexture())
        end
    end
end

function Y.SkinRotateButton(btn)
    btn:SetTemplate('Default')
    if Y.Wrath then
        btn:SetSize(btn:GetWidth() - 8, btn:GetHeight() - 8)
    else
        btn:SetSize(btn:GetWidth() - 14, btn:GetHeight() - 14)
    end

    btn:GetNormalTexture():SetTexCoord(0.3, 0.29, 0.3, 0.65, 0.69, 0.29, 0.69, 0.65)
    btn:GetPushedTexture():SetTexCoord(0.3, 0.29, 0.3, 0.65, 0.69, 0.29, 0.69, 0.65)

    btn:GetHighlightTexture():SetColorTexture(1, 1, 1, 0.3)

    btn:GetNormalTexture():ClearAllPoints()
    btn:GetNormalTexture():SetPoint('TOPLEFT', 2, -2)
    btn:GetNormalTexture():SetPoint('BOTTOMRIGHT', -2, 2)
    btn:GetPushedTexture():SetAllPoints(btn:GetNormalTexture())
    btn:GetHighlightTexture():SetAllPoints(btn:GetNormalTexture())
end

function Y.SkinEditBox(frame, width, height)
    frame:DisableDrawLayer('BACKGROUND')

    frame:CreateBackdrop('Overlay')

    local frameName = frame.GetName and frame:GetName()
    if frameName and (frameName:find('Gold') or frameName:find('Silver') or frameName:find('Copper')) then
        if frameName:find('Gold') then
            frame.backdrop:SetPoint('TOPLEFT', -3, 1)
            frame.backdrop:SetPoint('BOTTOMRIGHT', -3, 0)
        else
            frame.backdrop:SetPoint('TOPLEFT', -3, 1)
            frame.backdrop:SetPoint('BOTTOMRIGHT', -13, 0)
        end
    end

    if width then
        frame:SetWidth(width)
    end
    if height then
        frame:SetHeight(height)
    end
end

function Y.SkinDropDownBox(frame, width, pos)
    local frameName = frame.GetName and frame:GetName()
    local button = frame.Button or frame.MenuButton or frameName and (_G[frameName .. 'Button'] or _G[frameName .. '_Button'])
    local text = frameName and _G[frameName .. 'Text'] or frame.Text
    if not width then
        width = 155
    end

    frame:StripTextures()
    frame:SetWidth(width)

    if text then
        text:ClearAllPoints()
        text:SetPoint('RIGHT', button, 'LEFT', -2, 0)
    end

    button:ClearAllPoints()
    if pos then
        button:SetPoint('TOPRIGHT', frame.Right, -20, -21)
    else
        button:SetPoint('RIGHT', frame, 'RIGHT', -10, 3)
    end

    if not Y.IsWrath then
        button.SetPoint = Y.Dummy
    end

    Y.SkinNextPrevButton(button, nil, 'Down')

    frame:CreateBackdrop('Overlay')
    frame:SetFrameLevel(frame:GetFrameLevel() + 2)
    frame.backdrop:SetPoint('TOPLEFT', 20, -2)
    frame.backdrop:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', 2, -2)
end

function Y.SkinCheckBox(frame, size, default)
    if size then
        frame:SetSize(size, size)
    end
    frame:SetNormalTexture(0)
    frame:SetPushedTexture(0)
    frame:CreateBackdrop('Overlay')
    frame:SetFrameLevel(frame:GetFrameLevel() + 2)
    frame.backdrop:SetPoint('TOPLEFT', 4, -4)
    frame.backdrop:SetPoint('BOTTOMRIGHT', -4, 4)

    if frame.SetHighlightTexture then
        local highligh = frame:CreateTexture()
        highligh:SetColorTexture(1, 1, 1, 0.3)
        highligh:SetPoint('TOPLEFT', frame, 6, -6)
        highligh:SetPoint('BOTTOMRIGHT', frame, -6, 6)
        frame:SetHighlightTexture(highligh)
    end

    if frame.SetCheckedTexture then
        if default then
            return
        end
        local checked = frame:CreateTexture()
        checked:SetColorTexture(1, 0.82, 0, 0.8)
        checked:SetPoint('TOPLEFT', frame, 6, -6)
        checked:SetPoint('BOTTOMRIGHT', frame, -6, 6)
        frame:SetCheckedTexture(checked)
    end

    if frame.SetDisabledCheckedTexture then
        local disabled = frame:CreateTexture()
        disabled:SetColorTexture(0.6, 0.6, 0.6, 0.75)
        disabled:SetPoint('TOPLEFT', frame, 6, -6)
        disabled:SetPoint('BOTTOMRIGHT', frame, -6, 6)
        frame:SetDisabledCheckedTexture(disabled)
    end
end

function Y.SkinCheckBoxAtlas(checkbox, size)
    if size then
        checkbox:SetSize(size, size)
    end

    checkbox:CreateBackdrop('Overlay')
    checkbox.backdrop:SetInside(nil, 4, 4)

    for _, region in next, {checkbox:GetRegions()} do
        if region:IsObjectType('Texture') then
            if region:GetAtlas() == 'checkmark-minimal' or region:GetTexture() == 130751 then
                region:SetTexture(C.media.texture)

                local checkedTexture = checkbox:GetCheckedTexture()
                checkedTexture:SetColorTexture(1, 0.82, 0, 0.8)
                checkedTexture:SetInside(checkbox.backdrop)
            else
                region:SetTexture('')
            end
        end
    end
end

function Y.SkinCloseButton(self, parent, xOffset, yOffset)
    -- Define the parent frame and x,y offset of the close button
    parent = parent or self:GetParent()
    xOffset = xOffset or -6
    yOffset = yOffset or -6

    -- Set the size of the close button and its position relative to the parent frame
    self:SetSize(16, 16)
    self:ClearAllPoints()
    self:SetPoint('TOPRIGHT', parent, 'TOPRIGHT', xOffset, yOffset)

    -- Remove any textures that may already be applied to the button
    self:StripTextures()
    -- Check if there is a Border attribute, if so set its alpha to 0
    if self.Border then
        self.Border:SetAlpha(0)
    end

    -- Create a border for the button with specific color and alpha values
    self:CreateBorder(nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, {0.85, 0.25, 0.25})
    -- Apply the 'StyleButton' function to the button
    self:StyleButton()

    -- Remove the default disabled texture
    self:SetDisabledTexture('')
    -- Get the disabled texture and set its color and draw layer
    local dis = self:GetDisabledTexture()
    dis:SetVertexColor(0, 0, 0, 0.4)
    dis:SetDrawLayer('OVERLAY')
    dis:SetAllPoints()

    -- Create a texture for the button
    local tex = self:CreateTexture()
    -- Set the texture to CustomCloseButton
    tex:SetTexture('Interface\\AddOns\\YxUI\\Media\\Textures\\CloseButton_32')
    -- Set the texture to cover the entire button
    tex:SetAllPoints()
    self.__texture = tex
end

function Y.SkinSlider(f)
    f:StripTextures()

    local bd = CreateFrame('Frame', nil, f)
    bd:SetTemplate('Overlay')
    if f:GetOrientation() == 'VERTICAL' then
        bd:SetPoint('TOPLEFT', -2, -6)
        bd:SetPoint('BOTTOMRIGHT', 2, 6)
        f:GetThumbTexture():SetRotation(rad(90))
    else
        bd:SetPoint('TOPLEFT', 14, -2)
        bd:SetPoint('BOTTOMRIGHT', -15, 3)
    end
    bd:SetFrameLevel(f:GetFrameLevel() - 1)

    f:SetThumbTexture('Interface\\CastingBar\\UI-CastingBar-Spark')
    f:GetThumbTexture():SetBlendMode('ADD')
end

function Y.SkinSliderStep(frame, minimal)
    frame:StripTextures()

    local slider = frame.Slider
    if not slider then
        return
    end

    slider:DisableDrawLayer('ARTWORK')

    local thumb = slider.Thumb
    if thumb then
        thumb:SetTexture([[Interface\CastingBar\UI-CastingBar-Spark]])
        thumb:SetBlendMode('ADD')
        thumb:SetSize(20, 30)
    end

    local offset = minimal and 10 or 13
    slider:CreateBackdrop('Overlay')
    slider.backdrop:SetPoint('TOPLEFT', 10, -offset)
    slider.backdrop:SetPoint('BOTTOMRIGHT', -10, offset)

    if not slider.barStep then
        local step = CreateFrame('StatusBar', nil, slider.backdrop)
        step:SetStatusBarTexture(C.media.texture)
        step:SetStatusBarColor(1, 0.82, 0, 1)
        step:SetPoint('TOPLEFT', slider.backdrop, Y.mult * 2, -Y.mult * 2)
        step:SetPoint('BOTTOMLEFT', slider.backdrop, Y.mult * 2, Y.mult * 2)
        step:SetPoint('RIGHT', thumb, 'CENTER')

        slider.barStep = step
    end
end

function Y.SkinIconSelectionFrame(frame, numIcons, buttonNameTemplate, frameNameOverride)
    local frameName = frameNameOverride or frame:GetName()
    local scrollFrame = frame.ScrollFrame or _G[frameName .. 'ScrollFrame']
    local editBox = frame.EditBox or _G[frameName .. 'EditBox'] or frame.BorderBox.IconSelectorEditBox
    local okayButton = frame.OkayButton or frame.BorderBox.OkayButton or _G[frameName .. 'Okay']
    local cancelButton = frame.CancelButton or frame.BorderBox.CancelButton or _G[frameName .. 'Cancel']

    frame:StripTextures()
    frame.BorderBox:StripTextures()
    frame:CreateBackdrop('Transparent')
    frame.backdrop:SetPoint('TOPLEFT', 3, 1)
    frame:SetHeight(frame:GetHeight() + 13)

    if frame.IconSelector and frame.IconSelector.ScrollBar then
        Y.SkinScrollBar(frame.IconSelector.ScrollBar)
    elseif Y.Classic then
        scrollFrame:StripTextures()
        scrollFrame:CreateBackdrop('Overlay')
        scrollFrame.backdrop:SetPoint('TOPLEFT', 15, 5)
        scrollFrame.backdrop:SetPoint('BOTTOMRIGHT', 31, -8)
        scrollFrame:SetHeight(scrollFrame:GetHeight() + 12)
    end

    okayButton:SkinButton()
    cancelButton:SkinButton()
    cancelButton:ClearAllPoints()
    cancelButton:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -5, 5)

    editBox:DisableDrawLayer('BACKGROUND')
    Y.SkinEditBox(editBox)

    if Y.Classic then
        if buttonNameTemplate then
            for i = 1, numIcons do
                local button = _G[buttonNameTemplate .. i]
                local icon = _G[button:GetName() .. 'Icon']

                button:StripTextures()
                button:StyleButton(true)
                button:SetTemplate('Default')

                icon:ClearAllPoints()
                icon:SetPoint('TOPLEFT', 2, -2)
                icon:SetPoint('BOTTOMRIGHT', -2, 2)
                icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
            end
        end
    else
        local button = frame.BorderBox.SelectedIconArea and frame.BorderBox.SelectedIconArea.SelectedIconButton
        if button then
            button:DisableDrawLayer('BACKGROUND')
            local texture = button.Icon:GetTexture()
            button:StripTextures()
            button:StyleButton(true)
            button:SetTemplate('Default')

            button.Icon:ClearAllPoints()
            button.Icon:SetPoint('TOPLEFT', 2, -2)
            button.Icon:SetPoint('BOTTOMRIGHT', -2, 2)
            button.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
            if texture then
                button.Icon:SetTexture(texture)
            end
        end

        for _, button in next, {frame.IconSelector.ScrollBox.ScrollTarget:GetChildren()} do
            local texture = button.Icon:GetTexture()
            button:StripTextures()
            button:StyleButton(true)
            button:SetTemplate('Default')

            button.Icon:ClearAllPoints()
            button.Icon:SetPoint('TOPLEFT', 2, -2)
            button.Icon:SetPoint('BOTTOMRIGHT', -2, 2)
            button.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
            if texture then
                button.Icon:SetTexture(texture)
            end
        end
    end

    local dropdown = frame.BorderBox.IconTypeDropDown and frame.BorderBox.IconTypeDropDown.DropDownMenu
    if dropdown then
        Y.SkinDropDownBox(dropdown)
    end
end

function Y.SkinMaxMinFrame(frame, point)
    frame:SetSize(18, 18)

    if point then
        frame:SetPoint('RIGHT', point, 'LEFT', -2, 0)
    end

    for name, direction in pairs({
        ['MaximizeButton'] = 'up',
        ['MinimizeButton'] = 'down'
    }) do
        local button = frame[name]
        if button then
            button:StripTextures()
            button:SetTemplate('Overlay')
            button:SetPoint('CENTER')
            button:SetHitRectInsets(1, 1, 1, 1)

            button.minus = button:CreateTexture(nil, 'OVERLAY')
            button.minus:SetSize(7, 1)
            button.minus:SetPoint('CENTER')
            button.minus:SetTexture(C.media.blank)

            if direction == 'up' then
                button.plus = button:CreateTexture(nil, 'OVERLAY')
                button.plus:SetSize(1, 7)
                button.plus:SetPoint('CENTER')
                button.plus:SetTexture(C.media.blank)
            end

            button:HookScript('OnEnter', Y.SetModifiedBackdrop)
            button:HookScript('OnLeave', Y.SetOriginalBackdrop)
        end
    end
end

-- Handle collapse
local function updateCollapseTexture(texture, collapsed)
    if collapsed then
        texture:SetTexCoord(0, .4375, 0, .4375)
    else
        texture:SetTexCoord(.5625, 1, 0, .4375)
    end
end

local function resetCollapseTexture(self, texture)
    if self.settingTexture then
        return
    end
    self.settingTexture = true
    self:SetNormalTexture(0)

    if texture and texture ~= '' then
        if texture:find('Plus') or strfind(texture, 'Closed') then
            self.__texture:DoCollapse(true)
        elseif texture:find('Minus') or strfind(texture, 'Open') then
            self.__texture:DoCollapse(false)
        end
        self.bg:Show()
    else
        self.bg:Hide()
    end
    self.settingTexture = nil
end

local function hideCollapseTexture(self)
    self.bg:Hide()
end

Y.SetModifiedBackdrop = function(self)
    if not self.IsEnabled or self:IsEnabled() then
        self:SetBackdropBorderColor(Y.UserColor.r, Y.UserColor.g, Y.UserColor.b)
        if self.overlay then
            self.overlay:SetVertexColor(Y.UserColor.r * 0.3, Y.UserColor.g * 0.3, Y.UserColor.b * 0.3, 1)
        end
    end
end

Y.SetOriginalBackdrop = function(self)
    self:SetBackdropBorderColor(Y.UserColor.r, Y.UserColor.g, Y.UserColor.b)
    if self.overlay then
        self.overlay:SetVertexColor(0.1, 0.1, 0.1, 1)
    end
end

function Y.SkinExpandOrCollapse(f, isAtlas)
    f:SetHighlightTexture(0)
    f:SetPushedTexture(0)

    local bg = CreateFrame('Frame', nil, f)
    bg:SetSize(13, 13)
    bg:SetPoint('TOPLEFT', f:GetNormalTexture(), 0, -1)
    bg:SetTemplate('Overlay')
    f.bg = bg

    f.__texture = bg:CreateTexture(nil, 'OVERLAY')
    f.__texture:SetPoint('CENTER')
    f.__texture:SetSize(7, 7)
    f.__texture:SetTexture('Interface\\Buttons\\UI-PlusMinus-Buttons')
    f.__texture.DoCollapse = updateCollapseTexture

    if isAtlas then
        hooksecurefunc(f, 'SetNormalAtlas', resetCollapseTexture)
    else
        hooksecurefunc(f, 'SetNormalTexture', resetCollapseTexture)
        if f.ClearNormalTexture then
            hooksecurefunc(f, 'ClearNormalTexture', hideCollapseTexture)
        end
    end

    f:HookScript('OnEnter', function(self)
        Y.SetModifiedBackdrop(self.bg)
    end)

    f:HookScript('OnLeave', function(self)
        Y.SetOriginalBackdrop(self.bg)
    end)
end

function Y.SkinHelpBox(frame)
    frame:StripTextures()
    frame:SetTemplate('Transparent')
    if frame.CloseButton then
        Y.SkinCloseButton(frame.CloseButton)
    end
    if frame.Arrow then
        frame.Arrow:Hide()
    end
end

function Y.SkinFrame(frame, backdrop, x, y, x1, y1)
    local name = frame and frame.GetName and frame:GetName()
    local portraitFrame = name and _G[name .. 'Portrait'] or frame.Portrait or frame.portrait
    local portraitFrameOverlay = name and _G[name .. 'PortraitOverlay'] or frame.PortraitOverlay
    local artFrameOverlay = name and _G[name .. 'ArtOverlayFrame'] or frame.ArtOverlayFrame

    frame:StripTextures()

    if backdrop then
        frame:CreateBorder()
    else
        frame:SetTemplate('Transparent')
    end

    local closeButton = frame.CloseButton or (name and _G[name .. 'CloseButton'])
    if closeButton then
        Y.SkinCloseButton(closeButton, frame)
    end

    if portraitFrame then
        portraitFrame:SetAlpha(0)
    end
    if portraitFrameOverlay then
        portraitFrameOverlay:SetAlpha(0)
    end
    if artFrameOverlay then
        artFrameOverlay:SetAlpha(0)
    end
end

local iconColors = {
    ['uncollected'] = {
        r = borderr,
        g = borderg,
        b = borderb
    },
    ['gray'] = {
        r = borderr,
        g = borderg,
        b = borderb
    },
    ['white'] = {
        r = borderr,
        g = borderg,
        b = borderb
    },
    ['green'] = BAG_ITEM_QUALITY_COLORS[2],
    ['blue'] = BAG_ITEM_QUALITY_COLORS[3],
    ['purple'] = BAG_ITEM_QUALITY_COLORS[4],
    ['orange'] = BAG_ITEM_QUALITY_COLORS[5],
    ['artifact'] = BAG_ITEM_QUALITY_COLORS[6],
    ['account'] = BAG_ITEM_QUALITY_COLORS[7]
}

function Y.SkinIconBorder(frame, parent)
    local border = parent or frame:GetParent().backdrop
    frame:SetAlpha(0)
    hooksecurefunc(frame, 'SetVertexColor', function(self, r, g, b)
        if r ~= BAG_ITEM_QUALITY_COLORS[1].r ~= r and g ~= BAG_ITEM_QUALITY_COLORS[1].g then
            border:SetBackdropBorderColor(r, g, b)
        else
            border:SetBackdropBorderColor(unpack(C.media.border_color))
        end
    end)

    hooksecurefunc(frame, 'SetAtlas', function(self, atlas)
        local atlasAbbr = atlas and strmatch(atlas, '%-(%w+)$')
        local color = atlasAbbr and iconColors[atlasAbbr]
        if color then
            border:SetBackdropBorderColor(color.r, color.g, color.b)
        end
    end)

    hooksecurefunc(frame, 'Hide', function(self)
        border:SetBackdropBorderColor(unpack(C.media.border_color))
    end)

    hooksecurefunc(frame, 'SetShown', function(self, show)
        if not show then
            border:SetBackdropBorderColor(unpack(C.media.border_color))
        end
    end)
end

function Y.ReplaceIconString(frame, text)
    if not text then
        text = frame:GetText()
    end
    if not text or text == '' then
        return
    end

    local newText, count = gsub(text, '|T([^:]-):[%d+:]+|t', '|T%1:14:14:0:0:64:64:5:59:5:59|t')
    if count > 0 then
        frame:SetFormattedText('%s', newText)
    end
end
