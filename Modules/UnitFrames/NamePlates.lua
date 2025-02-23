local Y, L, A, C, D = YxUIGlobal:get()

D['nameplates-enable'] = true
D['nameplates-width'] = 200
D['nameplates-height'] = 18
D['nameplates-font'] = 'Roboto'
D['nameplates-font-size'] = 12
D['nameplates-font-flags'] = ''
D['nameplates-cc-health'] = false
D['nameplates-top-text'] = ''
D['nameplates-topleft-text'] = '[LevelColor][Level][Plus][ColorStop] [Name(20)]'
D['nameplates-topright-text'] = ''
D['nameplates-bottom-text'] = ''
D['nameplates-bottomleft-text'] = ''
D['nameplates-bottomright-text'] = '[HealthPercent]'
D['nameplates-only-player-debuffs'] = true
D['nameplates-health-color'] = 'CLASS'
D['nameplates-health-smooth'] = true
D['nameplates-enable-elite-indicator'] = true
D['nameplates-enable-target-indicator'] = true
D['nameplates-target-indicator-size'] = 'SMALL'
D['nameplates-enable-castbar'] = true
D['nameplates-cast-classcolor'] = true
D['nameplates-castbar-height'] = 12
D['nameplates-castbar-enable-icon'] = true
D['nameplates-selected-alpha'] = 100
D['nameplates-unselected-alpha'] = 40
D['nameplates-enable-auras'] = true
D['nameplates-buffs-direction'] = 'LTR'
D['nameplates-debuffs-direction'] = 'RTL'
D.NPHealthTexture = 'YxUI 4'
D.NPCastTexture = 'YxUI 4'

local UF = Y:GetModule('Unit Frames')

local GetNamePlates = C_NamePlate.GetNamePlates

Y.StyleFuncs['nameplate'] = function(self, unit)
    self:SetScale(UIParent:GetScale())
    self:SetSize(C['nameplates-width'], C['nameplates-height'])
    self:SetPoint('CENTER')

    local Backdrop = self:CreateTexture(nil, 'BACKGROUND')
    Backdrop:SetAllPoints()
    Backdrop:SetTexture(A:GetTexture('Blank'))
    Backdrop:SetVertexColor(0, 0, 0)

    self.colors.debuff = Y.DebuffColors

    -- Health Bar
    local Health = CreateFrame('StatusBar', nil, self)
    Health:SetPoint('TOPLEFT', self, 1, -1)
    Health:SetPoint('BOTTOMRIGHT', self, -1, 1)
    Health:SetStatusBarTexture(A:GetTexture(C.NPHealthTexture))
    Health:EnableMouse(false)

    local HealBar = CreateFrame('StatusBar', nil, Health)
    HealBar:SetWidth(C['nameplates-width'])
    HealBar:SetHeight(C['nameplates-height'])
    HealBar:SetPoint('LEFT', Health:GetStatusBarTexture(), 'RIGHT', 0, 0)
    HealBar:SetStatusBarTexture(A:GetTexture(C.NPHealthTexture))
    HealBar:SetStatusBarColor(0, 0.48, 0)

    self.HealBar = HealBar

    if Y.IsMainline then
        local AbsorbsBar = CreateFrame('StatusBar', nil, Health)
        AbsorbsBar:SetWidth(C['nameplates-width'])
        AbsorbsBar:SetHeight(C['nameplates-height'])
        AbsorbsBar:SetPoint('LEFT', Health:GetStatusBarTexture(), 'RIGHT', 0, 0)
        AbsorbsBar:SetStatusBarTexture(A:GetTexture(C.NPHealthTexture))
        AbsorbsBar:SetStatusBarColor(0, 0.66, 1)

        self.AbsorbsBar = AbsorbsBar
    end

    local HealthBG = self:CreateTexture(nil, 'BORDER')
    HealthBG:SetAllPoints(Health)
    HealthBG:SetTexture(A:GetTexture(C.NPHealthTexture))
    HealthBG.multiplier = 0.2

    -- Target Icon
    local RaidTargetIndicator = Health:CreateTexture(nil, 'OVERLAY')
    RaidTargetIndicator:SetSize(16, 16)
    RaidTargetIndicator:SetPoint('LEFT', Health, 'RIGHT', 5, 0)

    local Top = Health:CreateFontString(nil, 'OVERLAY')
    Y:SetFontInfo(Top, C['nameplates-font'], C['nameplates-font-size'], C['nameplates-font-flags'])
    Top:SetPoint('CENTER', Health, 'TOP', 0, 3)
    Top:SetJustifyH('CENTER')

    local TopLeft = Health:CreateFontString(nil, 'OVERLAY')
    Y:SetFontInfo(TopLeft, C['nameplates-font'], C['nameplates-font-size'], C['nameplates-font-flags'])
    TopLeft:SetPoint('LEFT', Health, 'TOPLEFT', 4, 3)
    TopLeft:SetJustifyH('LEFT')

    local TopRight = Health:CreateFontString(nil, 'OVERLAY')
    Y:SetFontInfo(TopRight, C['nameplates-font'], C['nameplates-font-size'], C['nameplates-font-flags'])
    TopRight:SetPoint('RIGHT', Health, 'TOPRIGHT', -4, 3)
    TopRight:SetJustifyH('RIGHT')

    local Bottom = Health:CreateFontString(nil, 'OVERLAY')
    Y:SetFontInfo(Bottom, C['nameplates-font'], C['nameplates-font-size'], C['nameplates-font-flags'])
    Bottom:SetPoint('CENTER', Health, 'BOTTOM', 0, -3)
    Bottom:SetJustifyH('CENTER')

    local BottomRight = Health:CreateFontString(nil, 'OVERLAY')
    Y:SetFontInfo(BottomRight, C['nameplates-font'], C['nameplates-font-size'], C['nameplates-font-flags'])
    BottomRight:SetPoint('RIGHT', Health, 'BOTTOMRIGHT', -4, -3)
    BottomRight:SetJustifyH('RIGHT')

    local BottomLeft = Health:CreateFontString(nil, 'OVERLAY')
    Y:SetFontInfo(BottomLeft, C['nameplates-font'], C['nameplates-font-size'], C['nameplates-font-flags'])
    BottomLeft:SetPoint('LEFT', Health, 'BOTTOMLEFT', 4, -3)
    BottomLeft:SetJustifyH('LEFT')

    --[[local InsideCenter = Health:CreateFontString(nil, "OVERLAY")
	YxUI:SetFontInfo(InsideCenter, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	InsideCenter:SetPoint("CENTER", Health, 0, 0)
	InsideCenter:SetJustifyH("CENTER")]]

    Health.Smooth = C['nameplates-health-smooth']
    Health.colorTapping = true
    Health.colorDisconnected = true

    UF:SetHealthAttributes(Health, C['nameplates-health-color'])

    local Threat = CreateFrame('Frame', nil, Health)
    Threat:SetAllPoints(Health)
    Threat:SetFrameLevel(Health:GetFrameLevel() - 1)
    Threat.feedbackUnit = 'player'
    Threat.PostUpdate = UF.NPThreatPostUpdate

    Threat.Top = Threat:CreateTexture(nil, 'BORDER')
    Threat.Top:SetHeight(6)
    Threat.Top:SetPoint('BOTTOMLEFT', Threat, 'TOPLEFT', 8, 1)
    Threat.Top:SetPoint('BOTTOMRIGHT', Threat, 'TOPRIGHT', -8, 1)
    Threat.Top:SetTexture(A:GetTexture('RenHorizonUp'))
    Threat.Top:SetAlpha(0.8)

    Threat.Bottom = Threat:CreateTexture(nil, 'BORDER')
    Threat.Bottom:SetHeight(6)
    Threat.Bottom:SetPoint('TOPLEFT', Threat, 'BOTTOMLEFT', 8, -1)
    Threat.Bottom:SetPoint('TOPRIGHT', Threat, 'BOTTOMRIGHT', -8, -1)
    Threat.Bottom:SetTexture(A:GetTexture('RenHorizonDown'))
    Threat.Bottom:SetAlpha(0.8)

    -- Buffs
    if C['nameplates-enable-auras'] then
        local Buffs = CreateFrame('Frame', self:GetName() .. 'Buffs', self)
        Buffs:SetSize(C['nameplates-width'], 26)
        Buffs:SetPoint('BOTTOM', self, 'TOP', 0, 10)
        Buffs.size = 26
        Buffs.spacing = 2
        Buffs.num = 5
        Buffs.PostCreateIcon = UF.PostCreateIcon
        Buffs.PostUpdateIcon = UF.PostUpdateIcon

        if (C['nameplates-buffs-direction'] == 'LTR') then
            Buffs.initialAnchor = 'TOPLEFT'
            Buffs['growth-x'] = 'RIGHT'
            Buffs['growth-y'] = 'UP'
        else
            Buffs.initialAnchor = 'TOPRIGHT'
            Buffs['growth-x'] = 'LEFT'
            Buffs['growth-y'] = 'UP'
        end

        self.Buffs = Buffs
    end

    -- Debuffs
    local Debuffs = CreateFrame('Frame', self:GetName() .. 'Debuffs', self)
    Debuffs:SetSize(C['nameplates-width'], 26)
    Debuffs.size = 26
    Debuffs.spacing = 2
    Debuffs.num = 5
    Debuffs.numRow = 4
    Debuffs.PostCreateIcon = UF.PostCreateIcon
    Debuffs.PostUpdateIcon = UF.PostUpdateIcon
    Debuffs.onlyShowPlayer = C['nameplates-only-player-debuffs']
    Debuffs.showStealableBuffs = true
    Debuffs.disableMouse = true

    if (C['nameplates-debuffs-direction'] == 'LTR') then
        Debuffs.initialAnchor = 'TOPLEFT'
        Debuffs['growth-x'] = 'RIGHT'
        Debuffs['growth-y'] = 'UP'
    else
        Debuffs.initialAnchor = 'TOPRIGHT'
        Debuffs['growth-x'] = 'LEFT'
        Debuffs['growth-y'] = 'UP'
    end

    if C['nameplates-enable-auras'] then
        Debuffs:SetPoint('BOTTOM', self.Buffs, 'TOP', 0, 2)
    else
        Debuffs:SetPoint('BOTTOM', self, 'TOP', 0, 10)
    end

    -- Castbar
    local Castbar = CreateFrame('StatusBar', nil, self)
    Castbar:SetSize(C['nameplates-width'] - 2, C['nameplates-castbar-height'])
    Castbar:SetPoint('TOP', Health, 'BOTTOM', 0, -4)
    Castbar:SetStatusBarTexture(A:GetTexture(C.NPCastTexture))

    local CastbarBG = Castbar:CreateTexture(nil, 'ARTWORK')
    CastbarBG:SetPoint('TOPLEFT', Castbar, 0, 0)
    CastbarBG:SetPoint('BOTTOMRIGHT', Castbar, 0, 0)
    CastbarBG:SetTexture(A:GetTexture(C.NPCastTexture))
    CastbarBG:SetAlpha(0.2)

    local Background = Castbar:CreateTexture(nil, 'BACKGROUND')
    Background:SetPoint('TOPLEFT', Castbar, -1, 1)
    Background:SetPoint('BOTTOMRIGHT', Castbar, 1, -1)
    Background:SetTexture(A:GetTexture('Blank'))
    Background:SetVertexColor(0, 0, 0)

    local Time = Castbar:CreateFontString(nil, 'OVERLAY')
    Y:SetFontInfo(Time, C['nameplates-font'], C['nameplates-font-size'], C['nameplates-font-flags'])
    Time:SetPoint('RIGHT', Castbar, 'BOTTOMRIGHT', -4, -3)
    Time:SetJustifyH('RIGHT')

    local Text = Castbar:CreateFontString(nil, 'OVERLAY')
    Y:SetFontInfo(Text, C['nameplates-font'], C['nameplates-font-size'], C['nameplates-font-flags'])
    Text:SetPoint('LEFT', Castbar, 'BOTTOMLEFT', 4, -3)
    Text:SetWidth(C['nameplates-width'] / 2 + 4)
    Text:SetJustifyH('LEFT')

    local Icon = Castbar:CreateTexture(nil, 'OVERLAY')
    Icon:SetSize(C['nameplates-height'] + 12 + 2, C['nameplates-height'] + 12 + 2)
    Icon:SetPoint('BOTTOMRIGHT', Castbar, 'BOTTOMLEFT', -4, 0)
    Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

    local IconBG = Castbar:CreateTexture(nil, 'BACKGROUND')
    IconBG:SetPoint('TOPLEFT', Icon, -1, 1)
    IconBG:SetPoint('BOTTOMRIGHT', Icon, 1, -1)
    IconBG:SetTexture(A:GetTexture('Blank'))
    IconBG:SetVertexColor(0, 0, 0)

    Castbar.bg = CastbarBG
    Castbar.Time = Time
    Castbar.Text = Text
    Castbar.Icon = Icon
    Castbar.showTradeSkills = true
    Castbar.timeToHold = 0.7
    Castbar.ClassColor = C['nameplates-cast-classcolor']
    Castbar.PostCastStart = UF.PostCastStart
    Castbar.PostCastStop = UF.PostCastStop
    Castbar.PostCastFail = UF.PostCastFail
    Castbar.PostCastInterruptible = UF.PostCastInterruptible

    --[[ Elite icon
	local EliteIndicator = Health:CreateTexture(nil, "OVERLAY")
    EliteIndicator:SetSize(16, 16)
    EliteIndicator:SetPoint("RIGHT", Health, "LEFT", -1, 0)
    EliteIndicator:SetTexture(Assets:GetTexture("Small Star"))
    EliteIndicator:Hide()]]

    -- Target
    local TargetIndicator = CreateFrame('Frame', nil, self)
    TargetIndicator:SetPoint('TOPLEFT', Health, 0, 0)
    TargetIndicator:SetPoint('BOTTOMRIGHT', Health, 0, 0)
    TargetIndicator:Hide()

    TargetIndicator.Border = TargetIndicator:CreateTexture(nil, 'BORDER')
    TargetIndicator.Border:SetPoint('TOPLEFT', -1, 1)
    TargetIndicator.Border:SetPoint('BOTTOMRIGHT', 1, -1)
    TargetIndicator.Border:SetTexture(A:GetTexture('Blank'))
    TargetIndicator.Border:SetVertexColor(Y:HexToRGB(C['ui-widget-color']))

    TargetIndicator.Bg = TargetIndicator:CreateTexture(nil, 'BORDER')
    TargetIndicator.Bg:SetPoint('TOPLEFT', 0, 0)
    TargetIndicator.Bg:SetPoint('BOTTOMRIGHT', 0, 0)
    TargetIndicator.Bg:SetTexture(A:GetTexture('Blank'))
    TargetIndicator.Bg:SetVertexColor(0.086, 0.086, 0.086)

    TargetIndicator.Left = TargetIndicator:CreateTexture(nil, 'ARTWORK')
    TargetIndicator.Left:SetSize(16, 16)
    TargetIndicator.Left:SetPoint('RIGHT', TargetIndicator, 'LEFT', 2, 0)
    TargetIndicator.Left:SetVertexColor(Y:HexToRGB(C['ui-widget-color']))

    TargetIndicator.Right = TargetIndicator:CreateTexture(nil, 'ARTWORK')
    TargetIndicator.Right:SetSize(16, 16)
    TargetIndicator.Right:SetPoint('LEFT', TargetIndicator, 'RIGHT', -3, 0)
    TargetIndicator.Right:SetVertexColor(Y:HexToRGB(C['ui-widget-color']))

    if (C['nameplates-target-indicator-size'] == 'SMALL') then
        TargetIndicator.Left:SetTexture(A:GetTexture('Arrow Left'))
        TargetIndicator.Right:SetTexture(A:GetTexture('Arrow Right'))
    elseif (C['nameplates-target-indicator-size'] == 'LARGE') then
        TargetIndicator.Left:SetTexture(A:GetTexture('Arrow Left Large'))
        TargetIndicator.Right:SetTexture(A:GetTexture('Arrow Right Large'))
    elseif (C['nameplates-target-indicator-size'] == 'HUGE') then
        TargetIndicator.Left:SetTexture(A:GetTexture('Arrow Left Huge'))
        TargetIndicator.Right:SetTexture(A:GetTexture('Arrow Right Huge'))
    end

    self:Tag(Top, C['nameplates-top-text'])
    self:Tag(TopLeft, C['nameplates-topleft-text'])
    self:Tag(TopRight, C['nameplates-topright-text'])
    self:Tag(Bottom, C['nameplates-bottom-text'])
    self:Tag(BottomRight, C['nameplates-bottomright-text'])
    self:Tag(BottomLeft, C['nameplates-bottomleft-text'])

    self.Health = Health
    self.Top = Top
    self.TopLeft = TopLeft
    self.TopRight = TopRight
    self.Bottom = Bottom
    self.BottomRight = BottomRight
    self.BottomLeft = BottomLeft
    self.Health.bg = HealthBG
    self.Debuffs = Debuffs
    self.Castbar = Castbar
    -- self.EliteIndicator = EliteIndicator
    self.TargetIndicator = TargetIndicator
    self.ThreatIndicator = Threat
    self.RaidTargetIndicator = RaidTargetIndicator
end

UF.NamePlateCVars = {
    nameplateGlobalScale = 1,
    NamePlateHorizontalScale = 1,
    NamePlateVerticalScale = 1,
    nameplateLargerScale = 1,
    nameplateMaxScale = 1,
    nameplateMinScale = 1,
    nameplateSelectedScale = 1,
    nameplateSelfScale = 1
}

UF.NamePlateCallback = function(plate)
    if (not plate) then
        return
    end

    if C['nameplates-enable-auras'] then
        plate:EnableElement('Auras')
    else
        plate:DisableElement('Auras')
    end

    if C['nameplates-enable-target-indicator'] then
        plate:EnableElement('TargetIndicator')

        if (C['nameplates-target-indicator-size'] == 'SMALL') then
            plate.TargetIndicator.Left:SetTexture(A:GetTexture('Arrow Left'))
            plate.TargetIndicator.Right:SetTexture(A:GetTexture('Arrow Right'))
        elseif (C['nameplates-target-indicator-size'] == 'LARGE') then
            plate.TargetIndicator.Left:SetTexture(A:GetTexture('Arrow Left Large'))
            plate.TargetIndicator.Right:SetTexture(A:GetTexture('Arrow Right Large'))
        elseif (C['nameplates-target-indicator-size'] == 'HUGE') then
            plate.TargetIndicator.Left:SetTexture(A:GetTexture('Arrow Left Huge'))
            plate.TargetIndicator.Right:SetTexture(A:GetTexture('Arrow Right Huge'))
        end
    else
        plate:DisableElement('TargetIndicator')
    end

    if C['nameplates-enable-castbar'] then
        plate:EnableElement('Castbar')
    else
        plate:DisableElement('Castbar')
    end

    if plate.Buffs then
        if (C['nameplates-buffs-direction'] == 'LTR') then
            plate.Buffs.initialAnchor = 'TOPLEFT'
            plate.Buffs['growth-x'] = 'RIGHT'
            plate.Buffs['growth-y'] = 'UP'
        else
            plate.Buffs.initialAnchor = 'TOPRIGHT'
            plate.Buffs['growth-x'] = 'LEFT'
            plate.Buffs['growth-y'] = 'UP'
        end
    end

    if plate.Debuffs then
        plate.Debuffs.onlyShowPlayer = C['nameplates-only-player-debuffs']

        if (C['nameplates-debuffs-direction'] == 'LTR') then
            plate.Debuffs.initialAnchor = 'TOPLEFT'
            plate.Debuffs['growth-x'] = 'RIGHT'
            plate.Debuffs['growth-y'] = 'UP'
        else
            plate.Debuffs.initialAnchor = 'TOPRIGHT'
            plate.Debuffs['growth-x'] = 'LEFT'
            plate.Debuffs['growth-y'] = 'UP'
        end
    end

    plate:SetSize(C['nameplates-width'], C['nameplates-height'])
    plate.Castbar:SetHeight(C['nameplates-castbar-height'])
    plate.Castbar:SetStatusBarTexture(A:GetTexture(C.NPCastTexture))
    plate.Castbar.bg:SetTexture(A:GetTexture(C.NPCastTexture))

    plate.Health:SetStatusBarTexture(A:GetTexture(C.NPHealthTexture))
    plate.Health.bg:SetTexture(A:GetTexture(C.NPHealthTexture))

    if plate.HealBar then
        plate.HealBar:SetStatusBarTexture(A:GetTexture(C.NPHealthTexture))
    end

    if plate.AbsorbsBar then
        plate.AbsorbsBar:SetStatusBarTexture(A:GetTexture(C.NPHealthTexture))
    end

    Y:SetFontInfo(plate.Top, C['nameplates-font'], C['nameplates-font-size'], C['nameplates-font-flags'])
    Y:SetFontInfo(plate.TopLeft, C['nameplates-font'], C['nameplates-font-size'], C['nameplates-font-flags'])
    Y:SetFontInfo(plate.TopRight, C['nameplates-font'], C['nameplates-font-size'], C['nameplates-font-flags'])
    Y:SetFontInfo(plate.Bottom, C['nameplates-font'], C['nameplates-font-size'], C['nameplates-font-flags'])
    Y:SetFontInfo(plate.BottomRight, C['nameplates-font'], C['nameplates-font-size'], C['nameplates-font-flags'])
    Y:SetFontInfo(plate.BottomLeft, C['nameplates-font'], C['nameplates-font-size'], C['nameplates-font-flags'])
    Y:SetFontInfo(plate.Castbar.Time, C['nameplates-font'], C['nameplates-font-size'], C['nameplates-font-flags'])
    Y:SetFontInfo(plate.Castbar.Text, C['nameplates-font'], C['nameplates-font-size'], C['nameplates-font-flags'])
end

local RunForAllNamePlates = function(func, value)
    local NamePlates = GetNamePlates()

    if NamePlates then
        for i = 1, #NamePlates do
            func(NamePlates[i].unitFrame, value)

            NamePlates[i].unitFrame:UpdateAllElements('ForceUpdate')
        end
    end
end

local NamePlatesUpdateEnableAuras = function(self, value)
    if value then
        self:EnableElement('Auras')
    else
        self:DisableElement('Auras')
    end
end

local UpdateNamePlatesEnableAuras = function(value)
    RunForAllNamePlates(NamePlatesUpdateEnableAuras, value)
end

local NamePlatesUpdateShowPlayerDebuffs = function(self)
    if self.Debuffs then
        self.Debuffs.onlyShowPlayer = C['nameplates-only-player-debuffs']
    end
end

local UpdateNamePlatesShowPlayerDebuffs = function(value)
    RunForAllNamePlates(NamePlatesUpdateShowPlayerDebuffs, value)
end

local NamePlateSetWidth = function(self)
    self:SetWidth(C['nameplates-width'])
end

local UpdateNamePlatesWidth = function()
    RunForAllNamePlates(NamePlateSetWidth)
end

local NamePlateSetHeight = function(self)
    self:SetHeight(C['nameplates-height'])
end

local UpdateNamePlatesHeight = function()
    RunForAllNamePlates(NamePlateSetHeight)
end

local NamePlateSetHealthColor = function(self)
    UF:SetHealthAttributes(self.Health, C['nameplates-health-color'])
end

local UpdateNamePlatesHealthColor = function()
    RunForAllNamePlates(NamePlateSetHealthColor)
end

local NamePlateSetTargetHightlight = function(self, value)
    if value then
        self:EnableElement('TargetIndicator')
    else
        self:DisableElement('TargetIndicator')
    end
end

local UpdateNamePlatesTargetHighlight = function(value)
    RunForAllNamePlates(NamePlateSetTargetHightlight, value)
end

local NamePlateSetFont = function(self)
    Y:SetFontInfo(self.Top, C['nameplates-font'], C['nameplates-font-size'], C['nameplates-font-flags'])
    Y:SetFontInfo(self.TopLeft, C['nameplates-font'], C['nameplates-font-size'], C['nameplates-font-flags'])
    Y:SetFontInfo(self.TopRight, C['nameplates-font'], C['nameplates-font-size'], C['nameplates-font-flags'])
    Y:SetFontInfo(self.Bottom, C['nameplates-font'], C['nameplates-font-size'], C['nameplates-font-flags'])
    Y:SetFontInfo(self.BottomRight, C['nameplates-font'], C['nameplates-font-size'], C['nameplates-font-flags'])
    Y:SetFontInfo(self.BottomLeft, C['nameplates-font'], C['nameplates-font-size'], C['nameplates-font-flags'])
    Y:SetFontInfo(self.Castbar.Time, C['nameplates-font'], C['nameplates-font-size'], C['nameplates-font-flags'])
    Y:SetFontInfo(self.Castbar.Text, C['nameplates-font'], C['nameplates-font-size'], C['nameplates-font-flags'])
end

local UpdateNamePlatesFont = function()
    RunForAllNamePlates(NamePlateSetFont)
end

local NamePlateEnableCastBars = function(self, value)
    if value then
        self:EnableElement('Castbar')
    else
        self:DisableElement('Castbar')
    end
end

local UpdateNamePlatesEnableCastBars = function(value)
    RunForAllNamePlates(NamePlateSetTargetHightlight, value)
end

local NamePlateSetCastBarsHeight = function(self, value)
    self.Castbar:SetHeight(value)
end

local UpdateNamePlatesCastBarsHeight = function(value)
    RunForAllNamePlates(NamePlateSetCastBarsHeight, value)
end

local NamePlateSetTargetIndicatorSize = function(self, value)
    if (value == 'SMALL') then
        self.TargetIndicator.Left:SetTexture(A:GetTexture('Arrow Left'))
        self.TargetIndicator.Right:SetTexture(A:GetTexture('Arrow Right'))
    elseif (value == 'LARGE') then
        self.TargetIndicator.Left:SetTexture(A:GetTexture('Arrow Left Large'))
        self.TargetIndicator.Right:SetTexture(A:GetTexture('Arrow Right Large'))
    elseif (value == 'HUGE') then
        self.TargetIndicator.Left:SetTexture(A:GetTexture('Arrow Left Huge'))
        self.TargetIndicator.Right:SetTexture(A:GetTexture('Arrow Right Huge'))
    end
end

local UpdateNamePlatesTargetIndicatorSize = function(value)
    RunForAllNamePlates(NamePlateSetTargetIndicatorSize, value)
end

local UpdateNamePlateSelectedAlpha = function(value)
    C_CVar.SetCVar('nameplateSelectedAlpha', value / 100)
end

local UpdateNamePlateUnselectedAlpha = function(value)
    C_CVar.SetCVar('nameplateMinAlpha', value / 100)
    C_CVar.SetCVar('nameplateMaxAlpha', value / 100)
end

local NamePlateSetBuffDirection = function(self, value)
    if (C['nameplates-buffs-direction'] == 'LTR') then
        self.Buffs.initialAnchor = 'TOPLEFT'
        self.Buffs['growth-x'] = 'RIGHT'
        self.Buffs['growth-y'] = 'UP'
    else
        self.Buffs.initialAnchor = 'TOPRIGHT'
        self.Buffs['growth-x'] = 'LEFT'
        self.Buffs['growth-y'] = 'UP'
    end
end

local UpdateNamePlatesBuffDirection = function(value)
    RunForAllNamePlates(NamePlateSetBuffDirection, value)
end

local NamePlateSetDebuffDirection = function(self, value)
    if (C['nameplates-debuffs-direction'] == 'LTR') then
        self.Debuffs.initialAnchor = 'TOPLEFT'
        self.Debuffs['growth-x'] = 'RIGHT'
        self.Debuffs['growth-y'] = 'UP'
    else
        self.Debuffs.initialAnchor = 'TOPRIGHT'
        self.Debuffs['growth-x'] = 'LEFT'
        self.Debuffs['growth-y'] = 'UP'
    end
end

local UpdateNamePlatesDebuffDirection = function(value)
    RunForAllNamePlates(NamePlateSetDebuffDirection, value)
end

local SetHealthTexture = function(self, value)
    self.Health:SetStatusBarTexture(A:GetTexture(value))
    self.Health.bg:SetTexture(A:GetTexture(value))
    self.HealBar:SetStatusBarTexture(A:GetTexture(value))

    if self.AbsorbsBar then
        self.AbsorbsBar:SetStatusBarTexture(A:GetTexture(value))
    end
end

local UpdateHealthTexture = function(value)
    RunForAllNamePlates(SetHealthTexture, value)
end

local SetCastTexture = function(self, value)
    self.Castbar:SetStatusBarTexture(A:GetTexture(value))
    self.Castbar.bg:SetTexture(A:GetTexture(value))
end

local UpdateCastTexture = function(value)
    RunForAllNamePlates(SetCastTexture, value)
end

Y:GetModule('GUI'):AddWidgets(L['General'], L['Name Plates'], function(left, right)
    left:CreateHeader(L['Enable'])
    left:CreateSwitch('nameplates-enable', C['nameplates-enable'], L['Enable Name Plates'], L['Enable the YxUI name plates module'], ReloadUI):RequiresReload(true)

    left:CreateHeader(L['Font'])
    left:CreateDropdown('nameplates-font', C['nameplates-font'], A:GetFontList(), L['Font'], L['Set the font of the name plates'], UpdateNamePlatesFont, 'Font')
    left:CreateSlider('nameplates-font-size', C['nameplates-font-size'], 8, 32, 1, L['Font Size'], L['Set the font size of the name plates'], UpdateNamePlatesFont)
    left:CreateDropdown('nameplates-font-flags', C['nameplates-font-flags'], A:GetFlagsList(), L['Font Flags'], L['Set the font flags of the name plates'], UpdateNamePlatesFont)

    left:CreateHeader(L['Health'])
    left:CreateSlider('nameplates-width', C['nameplates-width'], 60, 220, 1, 'Set Width', 'Set the width of name plates', UpdateNamePlatesWidth)
    left:CreateSlider('nameplates-height', C['nameplates-height'], 4, 50, 1, 'Set Height', 'Set the height of name plates', UpdateNamePlatesHeight)
    left:CreateDropdown('nameplates-health-color', C['nameplates-health-color'], {
        [L['Class']] = 'CLASS',
        [L['Reaction']] = 'REACTION',
        [L['Custom']] = 'CUSTOM',
        [L['Blizzard']] = 'BLIZZARD',
        [L['Threat']] = 'THREAT'
    }, L['Health Bar Color'], L['Set the color of the health bar'], UpdateNamePlatesHealthColor)
    left:CreateSwitch('nameplates-health-smooth', C['nameplates-health-smooth'], L['Enable Smooth Progress'], L['Set the health bar to animate changes smoothly'], ReloadUI):RequiresReload(true)
    left:CreateDropdown('NPHealthTexture', C.NPHealthTexture, A:GetTextureList(), L['Health Texture'], '', UpdateHealthTexture, 'Texture')

    left:CreateHeader(L['Buffs'])
    left:CreateSwitch('nameplates-enable-auras', C['nameplates-enable-auras'], L['Enable Buffs'], L['Display buffs above nameplates'], UpdateNamePlatesEnableAuras)
    left:CreateDropdown('nameplates-buffs-direction', C['nameplates-buffs-direction'], {
        [L['Left to Right']] = 'LTR',
        [L['Right to Left']] = 'RTL'
    }, L['Buff Direction'], L['Set which direction the buffs will grow towards'], UpdateNamePlatesBuffDirection)

    left:CreateHeader(L['Debuffs'])
    left:CreateSwitch('nameplates-only-player-debuffs', C['nameplates-only-player-debuffs'], L['Only Display Player Debuffs'], L['If enabled, only your own debuffs will be displayed'], UpdateNamePlatesShowPlayerDebuffs)
    left:CreateDropdown('nameplates-debuffs-direction', C['nameplates-debuffs-direction'], {
        [L['Left to Right']] = 'LTR',
        [L['Right to Left']] = 'RTL'
    }, L['Debuff Direction'], L['Set which direction the debuffs will grow towards'], UpdateNamePlatesDebuffDirection)

    right:CreateHeader(L['Information'])
    right:CreateInput('nameplates-top-text', C['nameplates-top-text'], L['Top Text'], '')
    right:CreateInput('nameplates-topleft-text', C['nameplates-topleft-text'], L['Top Left Text'], '')
    right:CreateInput('nameplates-topright-text', C['nameplates-topright-text'], L['Top Right Text'], '')
    right:CreateInput('nameplates-bottom-text', C['nameplates-bottom-text'], L['Bottom Text'], '')
    right:CreateInput('nameplates-bottomleft-text', C['nameplates-bottomleft-text'], L['Bottom Left Text'], '')
    right:CreateInput('nameplates-bottomright-text', C['nameplates-bottomright-text'], L['Bottom Right Text'], '')

    right:CreateHeader(L['Casting Bar'])
    right:CreateSwitch('nameplates-enable-castbar', C['nameplates-enable-castbar'], L['Enable Casting Bar'], L['Enable the casting bar the name plates'], UpdateNamePlatesEnableCastBars)
    right:CreateSwitch('nameplates-cast-classcolor', C['nameplates-cast-classcolor'], L['Enable Class Color'], L['Use class colors'], ReloadUI):RequiresReload(true)
    right:CreateSlider('nameplates-castbar-height', C['nameplates-castbar-height'], 3, 28, 1, L['Set Height'], L['Set the height of name plate casting bars'], UpdateNamePlatesCastBarsHeight)
    right:CreateDropdown('NPCastTexture', C.NPCastTexture, A:GetTextureList(), L['Castbar Texture'], '', UpdateCastTexture, 'Texture')

    right:CreateHeader(L['Target Indicator'])
    right:CreateSwitch('nameplates-enable-target-indicator', C['nameplates-enable-target-indicator'], L['Enable Target Indicator'], L['Display an indication on the targetted unit name plate'], UpdateNamePlatesTargetHighlight)
    right:CreateDropdown('nameplates-target-indicator-size', C['nameplates-target-indicator-size'], {
        [L['Small']] = 'SMALL',
        [L['Large']] = 'LARGE',
        [L['Huge']] = 'HUGE'
    }, L['Indicator Size'], L['Select the size of the target indicator'], UpdateNamePlatesTargetIndicatorSize)

    right:CreateHeader(L['Opacity'])
    right:CreateSlider('nameplates-selected-alpha', C['nameplates-selected-alpha'], 1, 100, 5, L['Selected Opacity'], L['Set the opacity of the selected name plate'], UpdateNamePlateSelectedAlpha)
    right:CreateSlider('nameplates-unselected-alpha', C['nameplates-unselected-alpha'], 0, 100, 5, L['Unselected Opacity'], L['Set the opacity of unselected name plates'], UpdateNamePlateUnselectedAlpha)
end)
