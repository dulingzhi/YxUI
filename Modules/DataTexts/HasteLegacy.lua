local YxUI, Language, Assets, Settings = select(2, ...):get()

local Label = STAT_HASTE or "Haste"

local GetValues = function()
    local Melee = GetMeleeHaste and GetMeleeHaste() or 0
    local Ranged = GetRangedHaste and GetRangedHaste() or 0
    local Spell = UnitSpellHaste and UnitSpellHaste("player") or 0

    if issecretvalue and (issecretvalue(Melee) or issecretvalue(Ranged) or issecretvalue(Spell)) then
        return
    end

    return Melee, Ranged, Spell
end

local OnEnter = function(self)
    if not self:SetTooltip() then
        return
    end

    local Melee, Ranged, Spell = GetValues()
    GameTooltip:AddLine(Label, 1, 0.82, 0)
    GameTooltip:AddLine(" ")

    if Melee then
        GameTooltip:AddDoubleLine(MELEE or "Melee", format("%.2f%%", Melee), 1, 1, 1, 1, 1, 1)
        GameTooltip:AddDoubleLine(RANGED or "Ranged", format("%.2f%%", Ranged), 1, 1, 1, 1, 1, 1)
        GameTooltip:AddDoubleLine(SPELLS or "Spell", format("%.2f%%", Spell), 1, 1, 1, 1, 1, 1)
    end

    GameTooltip:Show()
end

local OnLeave = function()
    GameTooltip:Hide()
end

local OnMouseUp = function()
    if InCombatLockdown() then
        return print(ERR_NOT_IN_COMBAT)
    end

    ToggleCharacter("PaperDollFrame")
end

local Update = function(self, event, unit)
    if unit and unit ~= "player" then
        return
    end

    local Melee, Ranged, Spell = GetValues()
    if not Melee then
        self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s--|r", Settings["data-text-label-color"], Label, YxUI.ValueColor)
        return
    end

    local Value
    if YxUI.UserClass == "HUNTER" then
        Value = Ranged
    elseif YxUI.UserClass == "MAGE" or YxUI.UserClass == "PRIEST" or YxUI.UserClass == "WARLOCK" then
        Value = Spell
    else
        Value = math.max(Melee, Spell)
    end

    self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%.2f%%|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, Value)
end

local OnEnable = function(self)
    self:RegisterUnitEvent("UNIT_STATS", "player")
    self:RegisterUnitEvent("UNIT_AURA", "player")
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    self:RegisterEvent("COMBAT_RATING_UPDATE")
    self:SetScript("OnEvent", Update)
    self:SetScript("OnMouseUp", OnMouseUp)
    self:SetScript("OnEnter", OnEnter)
    self:SetScript("OnLeave", OnLeave)
    self:Update(nil, "player")
end

local OnDisable = function(self)
    self:UnregisterEvent("UNIT_STATS")
    self:UnregisterEvent("UNIT_AURA")
    self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
    self:UnregisterEvent("COMBAT_RATING_UPDATE")
    self:SetScript("OnEvent", nil)
    self:SetScript("OnMouseUp", nil)
    self:SetScript("OnEnter", nil)
    self:SetScript("OnLeave", nil)
    self.Text:SetText("")
end

YxUI:AddDataText("Haste", OnEnable, OnDisable, Update)
