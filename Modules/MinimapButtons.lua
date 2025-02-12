-- File written by Smelly, maintained by Jai

local Y, L, A, C = select(2, ...):get()

local MinimapButtons = Y:NewModule("Minimap Buttons")

local lower = string.lower
local find = string.find
local MouseIsOver = MouseIsOver

MinimapButtons.Items = {}

local IgnoredBlizzard = {
    ["BattlefieldMinimap"] = true,
    ["ButtonCollectFrame"] = true,
    ["FeedbackUIButton"] = true,
    ["GameTimeFrame"] = true,
    ["HelpOpenTicketButton"] = true,
    ["HelpOpenWebTicketButton"] = true,
    ["MinimapBackdrop"] = true,
    ["MiniMapBattlefieldFrame"] = true,
    ["MiniMapLFGFrame"] = true,
    ["MiniMapMailFrame"] = true,
    ["MiniMapTracking"] = true,
    ["MiniMapTrackingFrame"] = true,
    ["MiniMapVoiceChatFrame"] = true,
    ["MinimapZoneTextButton"] = true,
    ["MinimapZoomIn"] = true,
    ["MinimapZoomOut"] = true,
    ["QueueStatusMinimapButton"] = true,
    ["TimeManagerClockButton"] = true,
}

local IgnoredAddOns = {
    "archy",
    "bookoftracksframe",
    "cartographernotespoi",
    "cork",
    "da_minimap",
    "dugisarrowminimappoint",
    "enhancedframeminimapbutton",
    "fishingextravaganzamini",
    "flower",
    "fwgminimappoi",
    "gatherarchnote",
    "gathermatepin",
    "gathernote",
    "gfw_trackmenuframe",
    "gfw_trackmenubutton",
    "gpsarrow",
    "guildmap3mini",
    "guildinstance",
    "handynotespin",
    "librockconfig-1.0_minimapbutton",
    "mininotepoi",
    "nauticusminiicon",
    "poiminimap",
    "premadefilter_minimapbutton",
    "questieframe",
    "questpointerpoi",
    "reciperadarminimapicon",
    "spy_mapnotelist_mini",
    "tdial_trackingicon",
    "tdial_trackButton",
    "tuber",
    "westpointer",
    "zgvmarker",
}

local RemoveByID = {
    [136430] = true,
    [136467] = true,
    [130924] = true,
}

local IsIgnoredAddOn = function(name)
    name = lower(name)

    for i = 1, #IgnoredAddOns do
        if find(name, IgnoredAddOns[i]) then
            return true
        end
    end
end

function MinimapButtons:PositionButtons(perrow, size, spacing)
    local Total = #self.Items

    if (Total < perrow) then
        perrow = Total
    end

    local Columns = ceil(Total / perrow)

    if (Columns < 1) then
        Columns = 1
    end

    -- Panel sizing
    self.Panel:SetWidth((size * perrow) + (spacing * (perrow - 1)) + 6)
    self.Panel:SetHeight((size * Columns) + (spacing * (Columns - 1)) + 6)

    -- Positioning
    for i = 1, Total do
        local Button = self.Items[i]

        Button:ClearAllPoints()
        Button:SetSize(size, size)

        if (i == 1) then
            Button:SetPoint("TOPLEFT", self.Panel, 3, -3)
        elseif ((i - 1) % perrow == 0) then
            Button:SetPoint("TOP", self.Items[i - perrow], "BOTTOM", 0, -spacing)
        else
            Button:SetPoint("LEFT", self.Items[i - 1], "RIGHT", spacing, 0)
        end
    end
end

function MinimapButtons:SkinButtons()
    for _, Child in next, { Minimap:GetChildren() } do
        local Name = Child:GetName()
        local Type = Child:GetObjectType()

        if (Child:IsShown() and Type ~= "Frame") then
            local Valid = (Name and not IgnoredBlizzard[Name] and not IsIgnoredAddOn(Name)) or not Name

            if Valid then
                Child:SetParent(self.Panel)
                Child:SetSize(22, 22)

                if (Child:HasScript("OnDragStart")) then
                    Child:SetScript("OnDragStart", nil)
                end

                if (Child:HasScript("OnDragStop")) then
                    Child:SetScript("OnDragStop", nil)
                end

                if (Child:HasScript("OnClick")) then
                    Child:HookScript("OnClick", function()
                        if not MouseIsOver(self.Panel) then
                            self:Hide(true)
                        end
                    end)
                end

                for i = 1, Child:GetNumRegions() do
                    local Region = select(i, Child:GetRegions())

                    if (Region:GetObjectType() == "Texture") then
                        local ID = Region:GetTextureFileID()
                        local Texture = Region:GetTexture() or ""
                        Texture = lower(Texture)

                        if (ID and RemoveByID[ID]) then
                            Region:SetTexture(nil)
                        end

                        if (
                                find(Texture, [[interface\characterframe]]) or
                                find(Texture, [[interface\minimap]]) or
                                find(Texture, "border") or
                                find(Texture, "background") or
                                find(Texture, "alphamask") or
                                find(Texture, "highlight")
                            ) then
                            Region:SetTexture(nil)
                            Region:SetAlpha(0)
                        end

                        Region:ClearAllPoints()
                        Region:SetPoint("TOPLEFT", Child, 1, -1)
                        Region:SetPoint("BOTTOMRIGHT", Child, -1, 1)
                        Region:SetDrawLayer('ARTWORK')
                        Region:SetTexCoord(0.1, 0.9, 0.1, 0.9)
                    end
                end

                Child:SetFrameLevel(Minimap:GetFrameLevel() + 10)
                Child:SetFrameStrata(Minimap:GetFrameStrata())
                Child:CreateBorder()
                Child:StyleButton()
                tinsert(self.Items, Child)
            end
        end
    end
end

function MinimapButtons:CreatePanel()
    local Frame = CreateFrame("Frame", "YxUI Minimap Buttons", Y.UIParent, "BackdropTemplate")
    Frame:SetFrameStrata("LOW")
    Frame:SetAlpha(0)
    self.Panel = Frame
end

function MinimapButtons:Hide(fade)
    if fade then
        C_Timer.After(0.5, function()
            MinimapButtons.Panel:Hide()
        end)
        UIFrameFadeOut(MinimapButtons.Panel, 0.5, MinimapButtons.Panel:GetAlpha(), 0)
    else
        self.Panel:Hide()
    end
end

local UpdateBar = function()
    MinimapButtons:PositionButtons(C["minimap-buttons-perrow"], C["minimap-buttons-size"], C["minimap-buttons-spacing"])
end

local DelayedLoad = function()
    MinimapButtons:CreatePanel()
    MinimapButtons:SkinButtons()
    MinimapButtons:Hide()

    if (#MinimapButtons.Items == 0) then
        return
    end

    UpdateBar()

    local bu = CreateFrame("Button", nil, Minimap:GetParent())
    bu:SetSize(16, 16)
    bu:SetAlpha(0.7)
    bu:SetPoint("BOTTOMLEFT", -7, -7)
    bu:SetHighlightTexture("Interface\\COMMON\\Indicator-Yellow")
    bu:SetPushedTexture("Interface\\COMMON\\Indicator-Green")
    bu:SetFrameLevel(Minimap:GetFrameLevel() + 2)
    bu.Icon = bu:CreateTexture(nil, "ARTWORK")
    bu.Icon:SetAllPoints()
    bu.Icon:SetTexture("Interface\\COMMON\\Indicator-Gray")

    bu:SetScript("OnClick", function(bu)
        PlaySound(825)
        if MinimapButtons.Panel:IsShown() then
            MinimapButtons:Hide(true)
            bu:UnregisterEvent("GLOBAL_MOUSE_UP")
        else
            UIFrameFadeIn(MinimapButtons.Panel, 0.5, MinimapButtons.Panel:GetAlpha(), 1)
            bu:RegisterEvent("GLOBAL_MOUSE_UP")
        end
    end)
    bu:SetScript('OnEvent', function(bu)
        if not MouseIsOver(bu) and not MouseIsOver(MinimapButtons.Panel) then
            MinimapButtons:Hide(true)
            bu:UnregisterEvent("GLOBAL_MOUSE_UP")
        end
    end)
    MinimapButtons.Panel:SetPoint("BOTTOMRIGHT", bu, "LEFT", -1, 0)
end

function MinimapButtons:Load()
    if (not C["minimap-buttons-enable"]) then
        return
    end

    C_Timer.After(2, DelayedLoad)
end

Y:GetModule("GUI"):AddWidgets(L["General"], L["Minimap"], function(left, right)
    right:CreateHeader(L["Minimap Buttons"])
    right:CreateSwitch("minimap-buttons-enable", C["minimap-buttons-enable"], L["Enable Minimap Button Bar"], "", ReloadUI):RequiresReload(true)
    right:CreateSlider("minimap-buttons-size", C["minimap-buttons-size"], 16, 44, 1, L["Button Size"], "", UpdateBar)
    right:CreateSlider("minimap-buttons-spacing", C["minimap-buttons-spacing"], 1, 6, 1, L["Button Spacing"], "", UpdateBar)
    right:CreateSlider("minimap-buttons-perrow", C["minimap-buttons-perrow"], 1, 20, 1, L["Buttons Per Row"], L["Set the number of buttons per row"], UpdateBar)
end)
