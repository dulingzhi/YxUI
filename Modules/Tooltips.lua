local Y, L, A, C, D = YxUIGlobal:get()

local Tooltips = Y:NewModule("Tooltips")

-- Default settings values
D["tooltips-enable"] = true
D["tooltips-on-cursor"] = false
D["tooltips-show-id"] = false
D["tooltips-display-realm"] = true
D["tooltips-display-title"] = true
D["tooltips-display-rank"] = false
D["tooltips-font"] = "Roboto"
D["tooltips-font-size"] = 12
D["tooltips-font-flags"] = ""
D["tooltips-hide-on-unit"] = "NEVER"
D["tooltips-hide-on-item"] = "NEVER"
D["tooltips-hide-on-action"] = "NEVER"
D["tooltips-health-bar-height"] = 15
D["tooltips-show-health-text"] = true
D["tooltips-show-target"] = true
D["tooltips-cursor-anchor"] = "ANCHOR_CURSOR"
D["tooltips-cursor-anchor-x"] = 0
D["tooltips-cursor-anchor-y"] = 8
D["tooltips-show-health"] = true
D["tooltips-show-price"] = true
D["tooltips-opacity"] = 100

local select = select
local find = string.find
local match = string.match
local floor = floor
local format = format
local UnitPVPName = UnitPVPName
local UnitReaction = UnitReaction
local UnitExists = UnitExists
local UnitClass = UnitClass
local GetGuildInfo = GetGuildInfo
local UnitCreatureType = UnitCreatureType
local UnitLevel = UnitLevel
local UnitEffectiveLevel = UnitEffectiveLevel
local UnitRace = UnitRace
local UnitName = UnitName
local UnitIsAFK = UnitIsAFK
local UnitIsDND = UnitIsDND
local UnitIsGhost = UnitIsGhost
local UnitIsDead = UnitIsDead
local UnitClassification = UnitClassification
local GetMouseFocus = GetMouseFocus
local GetItemInfo = GetItemInfo
local InCombatLockdown = InCombatLockdown
local UnitPlayerControlled = UnitPlayerControlled
local UnitCanAttack = UnitCanAttack
local UnitIsPVP = UnitIsPVP
local GetHappiness

local GameTooltipStatusBar = GameTooltipStatusBar
local MyGuild

if (not Y.IsMainline) then
    GetHappiness = GetPetHappiness
end

Tooltips.Handled = {
    ['GameTooltip'] = false,
    ['ItemRefTooltip'] = false,
    ['ItemRefShoppingTooltip1'] = false,
    ['ItemRefShoppingTooltip2'] = false,
    --AutoCompleteBox] = false,
    ['FriendsTooltip'] = false,
    ['ShoppingTooltip1'] = false,
    ['ShoppingTooltip2'] = false,
    ['EmbeddedItemTooltip'] = false,
    ['FrameStackTooltip'] = 'Blizzard_DebugTools',
    ['EventTraceTooltip'] = 'Blizzard_EventTrace',
    ['LibDBIconTooltip'] = false,
    ['AceConfigDialogTooltip'] = false,
}

Tooltips.Classifications = {
    ["rare"] = L["|cFFBDBDBDRare|r"],
    ["elite"] = L["|cFFFDD835Elite|r"],
    ["rareelite"] = L["|cFFBDBDBDRare Elite|r"],
    ["worldboss"] = L["Boss"],
}

Tooltips.HappinessLevels = {
    [1] = L["Unhappy"],
    [2] = L["Content"],
    [3] = L["Happy"]
}

function Tooltips:UpdateFonts(tooltip)
    for i = 1, tooltip:GetNumRegions() do
        local Region = select(i, tooltip:GetRegions())

        if (Region:GetObjectType() == "FontString") then
            Y:SetFontInfo(Region, C["tooltips-font"], C["tooltips-font-size"], C["tooltips-font-flags"])
        end
    end

    for i = 1, tooltip:GetNumChildren() do
        local Child = select(i, tooltip:GetChildren())

        if (Child and Child.GetName and Child:GetName() ~= nil and find(Child:GetName(), "MoneyFrame")) then
            local Prefix = _G[Child:GetName() .. "PrefixText"]
            local Suffix = _G[Child:GetName() .. "SuffixText"]

            if Prefix then
                Y:SetFontInfo(Prefix, C["tooltips-font"], C["tooltips-font-size"], C["tooltips-font-flags"])
            end

            if Suffix then
                Y:SetFontInfo(Suffix, C["tooltips-font"], C["tooltips-font-size"], C["tooltips-font-flags"])
            end
        end
    end

    if tooltip.numMoneyFrames then
        local MoneyFrame

        for i = 1, tooltip.numMoneyFrames do
            MoneyFrame = _G[tooltip:GetName() .. "MoneyFrame" .. i]

            if MoneyFrame then
                for j = 1, MoneyFrame:GetNumChildren() do
                    local Region = select(j, MoneyFrame:GetChildren())

                    if (Region and Region.GetName and Region:GetName()) then
                        local Text = _G[Region:GetName() .. "Text"]

                        if Text then
                            Y:SetFontInfo(Text, C["tooltips-font"], C["tooltips-font-size"], C["tooltips-font-flags"])
                        end
                    end
                end
            end
        end
    end

    self:UpdateStatusBarFonts()
end

local StripBackdrop = function(self)
    if self.NineSlice then
        self.NineSlice:SetAlpha(0)
    end
    if self.SetBackdrop then
        self:SetBackdrop(nil)
    end
end

local SetTooltipStyle = function(self)
    if not self or self:IsForbidden() then
        return
    end

    if self.Styled then
        Tooltips:UpdateFonts(self)

        local data = self.GetTooltipData and self:GetTooltipData()
        if data then
            local link = data.guid and C_Item.GetItemLinkByGUID(data.guid) or data.hyperlink
            if link then
                local quality = select(3, C_Item.GetItemInfo(link))
                local color = Y.QualityColors[quality or 1]
                if color then
                    self.bg.YxUIBorder:SetVertexColor(color.r, color.g, color.b)
                end
            end
        end
    else
        StripBackdrop(self)
        self:DisableDrawLayer("BACKGROUND")

        self.bg = CreateFrame("Frame", nil, self)
        self.bg:ClearAllPoints()
        self.bg:SetPoint("TOPLEFT", self, "TOPLEFT", 2, -2)
        self.bg:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -2, 2)
        self.bg:SetFrameLevel(self:GetFrameLevel())
        self.bg:CreateBorder()
        self.bg.YxUIBorder:SetVertexColor(1, 1, 1) -- Default color

        if (self == AutoCompleteBox) then
            for i = 1, AUTOCOMPLETE_MAX_BUTTONS do
                Y:SetFontInfo(_G["AutoCompleteButton" .. i .. "Text"], C["tooltips-font"], C["tooltips-font-size"], C["tooltips-font-flags"])
            end

            Y:SetFontInfo(AutoCompleteInstructions, C["tooltips-font"], C["tooltips-font-size"], C["tooltips-font-flags"])
        end

        Tooltips:UpdateFonts(self)

        self.Styled = true

        self:Show()
    end
end

local GetUnitColor = function(unit)
    local Color

    if UnitIsPlayer(unit) then
        local Class = select(2, UnitClass(unit))

        if Class then
            Color = Y.ClassColors[Class]
        end
    else
        local Reaction = UnitReaction(unit, "player")

        if Reaction then
            Color = Y.ReactionColors[Reaction]
        end
    end

    if Color then
        return Y:RGBToHex(Color[1], Color[2], Color[3])
    else
        return "FFFFFF"
    end
end

local FilterUnit = function(unit)
    local State

    if UnitPlayerControlled(unit) then
        if UnitCanAttack(unit, "player") then
            if (not UnitCanAttack("player", unit)) then
                State = 1
            else
                State = 2
            end
        elseif UnitCanAttack("player", unit) then
            State = 1
        elseif UnitIsPVP(unit) then
            State = 1
        else
            State = 1
        end
    else
        local Reaction = UnitReaction(unit, "player")

        if Reaction then
            if (Reaction >= 4) then
                State = 1
            else
                State = 2
            end
        else
            State = 1
        end
    end

    if (C["tooltips-hide-on-unit"] == "FRIENDLY" and State == 1) then
        return true
    elseif (C["tooltips-hide-on-unit"] == "HOSTILE" and State == 2) then
        return true
    end
end

local OnTooltipSetUnit = function(self)
    if (C["tooltips-hide-on-unit"] == "NO_COMBAT" and InCombatLockdown()) or C["tooltips-hide-on-unit"] == "ALWAYS" then
        self:Hide()

        return
    end

    local Unit, UnitID = self:GetUnit()

    if UnitID then
        local Class = UnitClass(UnitID)

        if (not Class) then
            return
        end

        if FilterUnit(UnitID) then
            self:Hide()
            return
        end

        local Name, Realm = UnitName(UnitID)
        local Race = UnitRace(UnitID)
        local Level = UnitLevel(UnitID)
        local Title = UnitPVPName(UnitID)
        local Guild, Rank = GetGuildInfo(UnitID)
        local Color = GetUnitColor(UnitID)
        local CreatureType = UnitCreatureType(UnitID)
        local Classification = Tooltips.Classifications[UnitClassification(UnitID)]
        local Flag = ""
        local Line
        local LineText

        if (Class == Name) then
            Class = ""
        end

        GameTooltipStatusBar:SetStatusBarColor(Y:HexToRGB(Color))

        if Y.IsMainline then
            local EffectiveLevel = UnitEffectiveLevel(UnitID)

            if (EffectiveLevel > 0 and EffectiveLevel ~= Level) then
                local EffectiveColor = GetQuestDifficultyColor(EffectiveLevel)
                local EffectiveHex = Y:RGBToHex(EffectiveColor.r, EffectiveColor.g, EffectiveColor.b)

                local LevelColor = GetQuestDifficultyColor(Level)
                local ColorHex = Y:RGBToHex(LevelColor.r, LevelColor.g, LevelColor.b)

                if (Level == -1) then
                    Level = "??"
                end

                Level = format("|cFF%s%s|r (|cFF%s%s|r)", EffectiveHex, EffectiveLevel, ColorHex, Level)
            end
        else
            local LevelColor = GetQuestDifficultyColor(Level)
            local Hex = Y:RGBToHex(LevelColor.r, LevelColor.g, LevelColor.b)

            if (Level == -1) then
                Level = "??"
            end

            Level = format("|cFF%s%s|r", Hex, Level)
        end

        --[[if CanInspect(UnitID) then
			if self.GUID then
				if UnitGUID(UnitID) == self.GUID then
					print(UnitName())
				end
			else
				Tooltips.Unit = UnitID
				NotifyInspect(UnitID)
			end
		end]]

        if UnitIsAFK(UnitID) then
            Flag = "|cFFFDD835" .. CHAT_FLAG_AFK .. "|r "
        elseif UnitIsDND(UnitID) then
            Flag = "|cFFF44336" .. CHAT_FLAG_DND .. "|r "
        end

        if (Realm and Realm ~= "" and C["tooltips-display-realm"]) then
            GameTooltipTextLeft1:SetText(format("%s|cFF%s%s - %s|r", Flag, Color, (C["tooltips-display-title"] and Title or Name), Realm))
        else
            GameTooltipTextLeft1:SetText(format("%s|cFF%s%s|r", Flag, Color, (C["tooltips-display-title"] and Title or Name)))
        end

        for i = 2, self:NumLines() do
            Line = _G["GameTooltipTextLeft" .. i]
            LineText = Line and Line.GetText and Line:GetText() or ""
            if (find(LineText, "^" .. LEVEL)) then
                if Race then
                    Line:SetText(format("%s %s|r %s %s", LEVEL, Level, Race, Class))
                elseif CreatureType then
                    if Classification then
                        Line:SetText(format("%s %s|r %s %s", LEVEL, Level, Classification, CreatureType))
                    else
                        Line:SetText(format("%s %s|r %s", LEVEL, Level, CreatureType))
                    end
                else
                    Line:SetText(format("%s %s|r %s", LEVEL, Level, Class))
                end
            elseif (find(LineText, PVP)) then
                Line:SetText(format("|cFFEE4D4D%s|r", PVP))
            elseif Guild and find(LineText, Guild) then
                if (Guild == MyGuild) then
                    if C["tooltips-display-rank"] then
                        Guild = format("|cFF5DADE2<%s>|r (%s)", Guild, Rank)
                    else
                        Guild = format("|cFF5DADE2<%s>|r", Guild)
                    end
                else
                    if C["tooltips-display-rank"] then
                        Guild = format("|cFF66BB6A<%s>|r (%s)", Guild, Rank)
                    else
                        Guild = format("|cFF66BB6A<%s>|r", Guild)
                    end
                end

                Line:SetText(Guild)
            end
        end

        if (C["tooltips-show-target"] and (UnitID ~= "player" and UnitExists(UnitID .. "target"))) then
            local TargetColor = GetUnitColor(UnitID .. "target")

            self:AddLine(L["Targeting: |cFF"] .. TargetColor .. UnitName(UnitID .. "target") .. "|r", 1, 1, 1)
        end

        if ((not Y.IsMainline) and Y.UserClass == "HUNTER" and UnitID == "pet") then
            local Level = GetHappiness()

            if Level then
                local Color = Y.HappinessColors[Level]

                if Color then
                    self:AddLine(" ")
                    self:AddDoubleLine(L["Happiness:"], format("|cFF%s%s|r", Y:RGBToHex(Color[1], Color[2], Color[3]), Tooltips.HappinessLevels[Level]))
                end
            end
        end
    end
end

local OnTooltipSetItem = function(self)
    if (C["tooltips-hide-on-item"] == "NO_COMBAT" and InCombatLockdown()) or C["tooltips-hide-on-item"] == "ALWAYS" then
        self:Hide()

        return
    end

    if (MerchantFrame and MerchantFrame:IsShown()) or (not self.GetItem) then
        return
    end

    local Name, Link = self:GetItem()

    if (not Link) then
        return
    end

    if (not Y.IsMainline) and C["tooltips-show-price"] then
        local Price = select(11, GetItemInfo(Link))

        if Price then
            local MouseFocus
            local Count = 1

            if GetMouseFocus then
                MouseFocus = GetMouseFocus()
            elseif GetMouseFoci then
                MouseFocus = GetMouseFoci()
                MouseFocus = MouseFocus[1]
            end

            if (MouseFocus and MouseFocus.count) then
                Count = MouseFocus.count
            end

            if (Count and type(Count) == "number") then
                local CopperValue = Price * Count

                if (CopperValue > 0) then
                    local CoinString = GetCoinTextureString(CopperValue)

                    if CoinString then
                        self:AddLine(CoinString, 1, 1, 1)
                    end
                end
            end
        end
    end

    if C["tooltips-show-id"] then
        local id = match(Link, ":(%w+)")

        self:AddLine(" ")
        self:AddLine(format("%s |cFFFFFFFF%d|r", ID, id))
    end
end

local OnItemRefTooltipSetItem = function(self)
    if (not self.GetItem) then
        return
    end

    local Link = select(2, self:GetItem())

    if (not Link) then
        return
    end

    local Price = select(11, GetItemInfo(Link))

    if (Price and Price > 0) then
        local CoinString = GetCoinTextureString(Price)

        if CoinString then
            self:AddLine(CoinString, 1, 1, 1)
        end
    end

    if C["tooltips-show-id"] then
        local id = match(Link, ":(%w+)")

        self:AddLine(" ")
        self:AddLine(format("%s |cFFFFFFFF%d|r", ID, id))
    end
end

local OnTooltipSetSpell = function(self)
    if (C["tooltips-hide-on-action"] == "NO_COMBAT" and InCombatLockdown()) or C["tooltips-hide-on-action"] == "ALWAYS" then
        self:Hide()

        return
    end

    if (not C["tooltips-show-id"]) then
        return
    end

    local id = select(2, self:GetSpell())

    self:AddLine(" ")
    self:AddLine(format("%s |cFFFFFFFF%d|r", ID, id))
end

local SetDefaultAnchor = function(self, parent)
    if self:IsForbidden() then
        return
    end
    if not parent then
        return
    end
    if C["tooltips-on-cursor"] then
        self:SetOwner(parent, C["tooltips-cursor-anchor"], C["tooltips-cursor-anchor-x"], C["tooltips-cursor-anchor-y"])
        return
    end

    self:ClearAllPoints()

    local Offset = C["ui-border-thickness"]
    if C["right-window-enable"] then
        self:SetPoint("BOTTOMLEFT", Tooltips, 0, 3 + Offset)
    else
        self:SetPoint("BOTTOMRIGHT", Tooltips, 0, 3 + Offset)
    end
end

local OnTooltipSetAura = function(self, unit, index, filter)
    if (not C["tooltips-show-id"]) or not UnitAura then
        return
    end

    local _, _, _, _, _, _, Caster, _, _, id = UnitAura(unit, index, filter)

    if (not id) then
        return
    end

    if Caster then
        local Name = UnitName(Caster)
        local _, Class = UnitClass(Caster)
        local Color = RAID_CLASS_COLORS[Class]

        self:AddLine(" ")
        self:AddDoubleLine(format("%s |cFFFFFFFF%d|r", ID, id), format("|c%s%s|r", Color.colorStr, Name))
    else
        self:AddLine(" ")
        self:AddLine(format("%s |cFFFFFFFF%d|r", ID, id))
    end

    self:Show()
end

-- Tooltip Skin Registration
local tipTable = {}
function Tooltips:RegisterTooltips(addon, func)
    tipTable[addon] = func
end

local function addonStyled(self, _, addon)
    if tipTable[addon] then
        tipTable[addon]()
        tipTable[addon] = nil
        if not next(tipTable) then
            self:UnEvent("ADDON_LOADED", addonStyled)
        end
    end
end
Tooltips:Event("ADDON_LOADED", addonStyled)

function Tooltips:AddHooks()
    for k, v in pairs(self.Handled) do
        if _G[k] then
            _G[k]:HookScript("OnShow", SetTooltipStyle)
        elseif v then
            self:RegisterTooltips(v, function()
                if _G[k] then
                    _G[k]:HookScript("OnShow", SetTooltipStyle)
                else
                    print("Tooltip not found: " .. k .. " (addon: " .. v .. ")")
                end
            end)
        else
            print("Tooltip not found: " .. k)
        end
    end

    if (TooltipDataProcessor and not Y.IsCata) then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnTooltipSetUnit)
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, OnTooltipSetSpell)
    else
        GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipSetUnit)
        GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
        GameTooltip:HookScript("OnTooltipSetSpell", OnTooltipSetSpell)

        ItemRefTooltip:HookScript("OnTooltipSetItem", OnItemRefTooltipSetItem)
    end

    hooksecurefunc("GameTooltip_SetDefaultAnchor", SetDefaultAnchor)
    hooksecurefunc("SharedTooltip_SetBackdropStyle", StripBackdrop)

    hooksecurefunc(GameTooltip, "SetUnitAura", OnTooltipSetAura)
    hooksecurefunc(GameTooltip, "SetUnitBuff", OnTooltipSetAura)
    hooksecurefunc(GameTooltip, "SetUnitDebuff", OnTooltipSetAura)
end

local OnValueChanged = function(self)
    local Unit = select(2, self:GetParent():GetUnit())

    if (not Unit) then
        return
    end

    local Color = GetUnitColor(Unit)

    self:SetStatusBarColor(Y:HexToRGB(Color))

    if (not C["tooltips-show-health-text"]) then
        return
    end

    local Current = UnitHealth(Unit)
    local Max = UnitHealthMax(Unit)

    if (Max == 0) then
        if UnitIsDead(Unit) then
            self.HealthValue:SetText("|cFFD64545" .. L["Dead"] .. "|r")
        elseif UnitIsGhost(Unit) then
            self.HealthValue:SetText("|cFFEEEEEE" .. L["Ghost"] .. "|r")
        else
            self.HealthValue:SetText(" ")
            self.HealthPercent:SetText(" ")
        end
    else
        if UnitIsDead(Unit) then
            self.HealthValue:SetText("|cFFD64545" .. L["Dead"] .. "|r")
        elseif UnitIsGhost(Unit) then
            self.HealthValue:SetText("|cFFEEEEEE" .. L["Ghost"] .. "|r")
        else
            self.HealthValue:SetText(format("%s / %s", Y:ShortValue(Current), Y:ShortValue(Max)))
        end

        self.HealthPercent:SetText(format("%s%%", floor((Current / Max * 100 + 0.05) * 10) / 10))
    end
end

local OnShow = function(self)
    if (not C["tooltips-show-health"]) then
        GameTooltipStatusBar:Hide()

        return
    end

    OnValueChanged(self)
end

function Tooltips:UpdateStatusBarFonts()
    Y:SetFontInfo(GameTooltipStatusBar.HealthValue, C["tooltips-font"], C["tooltips-font-size"], C["tooltips-font-flags"])
    Y:SetFontInfo(GameTooltipStatusBar.HealthPercent, C["tooltips-font"], C["tooltips-font-size"], C["tooltips-font-flags"])
end

function Tooltips:StyleStatusBar()
    GameTooltipStatusBar:ClearAllPoints()
    GameTooltipStatusBar:SetPoint("BOTTOMLEFT", GameTooltipStatusBar:GetParent(), "TOPLEFT", 2, 3)
    GameTooltipStatusBar:SetPoint("BOTTOMRIGHT", GameTooltipStatusBar:GetParent(), "TOPRIGHT", -2, 3)
    GameTooltipStatusBar:SetStatusBarTexture(A:GetTexture(C["ui-widget-texture"]))
    GameTooltipStatusBar:SetHeight(12)
    GameTooltipStatusBar:CreateBorder()

    GameTooltipStatusBar.HealthValue = GameTooltipStatusBar:CreateFontString(nil, "OVERLAY")
    Y:SetFontInfo(GameTooltipStatusBar.HealthValue, C["tooltips-font"], C["tooltips-font-size"], C["tooltips-font-flags"])
    GameTooltipStatusBar.HealthValue:SetPoint("LEFT", GameTooltipStatusBar, 3, 0)
    GameTooltipStatusBar.HealthValue:SetJustifyH("LEFT")

    GameTooltipStatusBar.HealthPercent = GameTooltipStatusBar:CreateFontString(nil, "OVERLAY")
    Y:SetFontInfo(GameTooltipStatusBar.HealthPercent, C["tooltips-font"], C["tooltips-font-size"], C["tooltips-font-flags"])
    GameTooltipStatusBar.HealthPercent:SetPoint("RIGHT", GameTooltipStatusBar, -3, 0)
    GameTooltipStatusBar.HealthPercent:SetJustifyH("RIGHT")

    GameTooltipStatusBar:HookScript("OnValueChanged", OnValueChanged)
    GameTooltipStatusBar:HookScript("OnShow", OnShow)
end

local ItemRefCloseOnEnter = function(self)
    self.Cross:SetVertexColor(Y:HexToRGB("C0392B"))
end

local ItemRefCloseOnLeave = function(self)
    self.Cross:SetVertexColor(Y:HexToRGB("EEEEEE"))
end

local ItemRefCloseOnMouseUp = function(self)
    self.Texture:SetVertexColor(Y:HexToRGB(C["ui-widget-bright-color"]))

    ItemRefTooltip:Hide()
end

local ItemRefCloseOnMouseDown = function(self)
    local R, G, B = Y:HexToRGB(C["ui-widget-bright-color"])

    self.Texture:SetVertexColor(R * 0.5, G * 0.5, B * 0.5)
end

function Tooltips:SkinItemRef()
    if Y.IsMainline then
        Y.SkinCloseButton(ItemRefTooltip.CloseButton, ItemRefTooltip)
    else
        Y.SkinCloseButton(ItemRefCloseButton, ItemRefTooltip)
    end
end

function Tooltips:OnEvent(event, guid)
    self.GUID = guid

    if self.Unit and UnitGUID(self.Unit) == guid then
        --local Level = CalculateAverageItemLevel(self.Unit)

        --print(format("[%s] Item Level: %.2f", UnitName(self.Unit), Level))

        ClearInspectPlayer()

        self.Unit = nil
    end
end

function Tooltips:Load()
    if (not C["tooltips-enable"]) then
        return
    end

    self:SetSize(200, 26)

    if C["right-window-enable"] then
        local Mod = Y:GetModule("Right Window")
        local Offset = C["ui-border-thickness"]

        self:SetPoint("BOTTOMLEFT", Mod.TopLeft or Mod.Top, "TOPLEFT", 0, 1 > Offset and -1 or -(Offset + 2))
    else
        self:SetPoint("BOTTOMRIGHT", Y.UIParent, -195, 50)
    end

    self:AddHooks()
    self:StyleStatusBar()
    self:SkinItemRef()
    --self:RegisterEvent("INSPECT_READY")
    --self:SetScript("OnEvent", self.OnEvent)

    self.Mover = Y:CreateMover(self)

    --self.Mover.PreMove = function() GameTooltip_SetDefaultAnchor(GameTooltip, self) GameTooltip:AddLine("Example tooltip") GameTooltip:Show() end
    --self.Mover.PostMove = function() GameTooltip:Hide() end

    if IsInGuild() then
        MyGuild = GetGuildInfo("player")
    end
end

local UpdateHealthBarHeight = function(value)
    GameTooltipStatusBar:SetHeight(value)
end

local UpdateShowHealthText = function(value)
    if (value ~= true) then
        GameTooltipStatusBar.HealthValue:SetText(" ")
        GameTooltipStatusBar.HealthPercent:SetText(" ")
    end
end

local UpdateTooltipBackdrop = function(value)
    local R, G, B = Y:HexToRGB(C["ui-window-main-color"])

    for k, v in pairs(Tooltips.Handled) do
        if _G[k] and _G[k].Backdrop then
            _G[k].Backdrop.Outside:SetBackdropColor(R, G, B, (value / 100))
        end
    end
end

Y:GetModule("GUI"):AddWidgets(L["General"], L["Tooltips"], function(left, right)
    left:CreateHeader(L["Enable"])
    left:CreateSwitch("tooltips-enable", C["tooltips-enable"], L["Enable Tooltips Module"], L["Enable the YxUI tooltips module"], ReloadUI):RequiresReload(true)

    left:CreateHeader(L["Health Bar"])
    left:CreateSwitch("tooltips-show-health", C["tooltips-show-health"], L["Display Health Bar"], L["Display the tooltip health bar"])
    left:CreateSwitch("tooltips-show-health-text", C["tooltips-show-health-text"], L["Display Health Text"], L["Display health information on the tooltip health bar"], UpdateShowHealthText)
    left:CreateSlider("tooltips-health-bar-height", C["tooltips-health-bar-height"], 2, 30, 1, L["Health Bar Height"], L["Set the height of the tooltip health bar"], UpdateHealthBarHeight)

    left:CreateHeader(L["Information"])
    left:CreateSwitch("tooltips-show-target", C["tooltips-show-target"], L["Display Target"], L["Display the units current target"])
    left:CreateSwitch("tooltips-show-id", C["tooltips-show-id"], L["Display ID's"], L["Display item and spell ID's in the tooltip"])
    left:CreateSwitch("tooltips-display-realm", C["tooltips-display-realm"], L["Display Realm"], L["Display character realms"])
    left:CreateSwitch("tooltips-display-title", C["tooltips-display-title"], L["Display Title"], L["Display character titles"])
    left:CreateSwitch("tooltips-display-rank", C["tooltips-display-rank"], L["Display Guild Rank"], L["Display character guild ranks"])
    left:CreateSwitch("tooltips-show-price", C["tooltips-show-price"], L["Display Vendor Price"], L["Display the vendor price of an item"])

    left:CreateHeader(L["Opacity"])
    left:CreateSlider("tooltips-opacity", C["tooltips-opacity"], 0, 100, 5, L["Tooltip Opacity"], L["Set the opacity of the tooltip background"], UpdateTooltipBackdrop)

    right:CreateHeader(L["Font"])
    right:CreateDropdown("tooltips-font", C["tooltips-font"], A:GetFontList(), L["Font"], L["Set the font of the tooltip text"], nil, "Font")
    right:CreateSlider("tooltips-font-size", C["tooltips-font-size"], 8, 32, 1, L["Font Size"], L["Set the font size of the tooltip text"])
    right:CreateDropdown("tooltips-font-flags", C["tooltips-font-flags"], A:GetFlagsList(), L["Font Flags"], L["Set the font flags of the tooltip text"])

    right:CreateHeader(L["Cursor Anchor"])
    right:CreateSwitch("tooltips-on-cursor", C["tooltips-on-cursor"], L["Tooltip On Cursor"], L["Anchor the tooltip to the mouse cursor"])
    right:CreateDropdown("tooltips-cursor-anchor", C["tooltips-cursor-anchor"], { [L["Right"]] = "ANCHOR_CURSOR_RIGHT", [L["Center"]] = "ANCHOR_CURSOR", [L["Left"]] = "ANCHOR_CURSOR_LEFT" }, L["Anchor Point"])
    right:CreateSlider("tooltips-cursor-anchor-x", C["tooltips-cursor-anchor-x"], -64, 64, 1, L["X Offset"], L["Set the horizontal offset of the tooltip. Only works with Left or Right anchor."])
    right:CreateSlider("tooltips-cursor-anchor-y", C["tooltips-cursor-anchor-y"], -64, 64, 1, L["Y Offset"], L["Set the vertical offset of the tooltip. Only works with Left or Right anchor."])

    right:CreateHeader(L["Disable Tooltips"])
    right:CreateDropdown("tooltips-hide-on-unit", C["tooltips-hide-on-unit"], { [L["Never"]] = "NEVER", [L["Always"]] = "ALWAYS", [L["Friendly"]] = "FRIENDLY", [L["Hostile"]] = "HOSTILE", [L["Combat"]] = "NO_COMBAT" }, L["Disable Units"], L["Set the tooltip to not display units"])
    right:CreateDropdown("tooltips-hide-on-item", C["tooltips-hide-on-item"], { [L["Never"]] = "NEVER", [L["Always"]] = "ALWAYS", [L["Combat"]] = "NO_COMBAT" }, L["Disable Items"], L["Set the tooltip to not display items"])
    right:CreateDropdown("tooltips-hide-on-action", C["tooltips-hide-on-action"], { [L["Never"]] = "NEVER", [L["Always"]] = "ALWAYS", [L["Combat"]] = "NO_COMBAT" }, L["Disable Actions"], L["Set the tooltip to not display actions"])
end)
