local YxUI, Language, Assets, Settings = select(2, ...):get()

local Label = STAT_EXPERTISE or "Expertise"

local GetExpertiseValue = function()
    local Main, Offhand
    if YxUI.IsMists and GetExpertise then
        Main, Offhand = GetExpertise()
    elseif GetExpertisePercent then
        Main, Offhand = GetExpertisePercent()
    elseif GetExpertise then
        Main, Offhand = GetExpertise()
    end

    if Main == nil or (issecretvalue and issecretvalue(Main)) then
        return
    end

    if issecretvalue and issecretvalue(Offhand) then
        Offhand = nil
    end

    return Main, Offhand
end

local OnEnter = function(self)
    if not self:SetTooltip() then
        return
    end

    local Main, Offhand = GetExpertiseValue()
    GameTooltip:AddLine(Label, 1, 0.82, 0)
    GameTooltip:AddLine(" ")

    if Main then
        GameTooltip:AddDoubleLine(MELEE or "Main Hand", format("%.2f%%", Main), 1, 1, 1, 1, 1, 1)
        if Offhand and Offhand ~= Main and IsDualWielding() then
            GameTooltip:AddDoubleLine(SECONDARYHANDSLOT or "Off Hand", format("%.2f%%", Offhand), 1, 1, 1, 1, 1, 1)
        end
    end

    if CR_EXPERTISE and GetCombatRating and GetCombatRatingBonus then
        local Rating = GetCombatRating(CR_EXPERTISE)
        local Bonus = GetCombatRatingBonus(CR_EXPERTISE)
        if Rating and Bonus and not (issecretvalue and (issecretvalue(Rating) or issecretvalue(Bonus))) then
            GameTooltip:AddDoubleLine(COMBAT_RATING_NAME24 or Label, format("%d (+%.2f%%)", Rating, Bonus), 1, 1, 1, 1, 1, 1)
        end
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

	local Main = GetExpertiseValue()
    if Main == nil then
        self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s--|r", Settings["data-text-label-color"], Label, YxUI.ValueColor)
    else
        self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%.2f%%|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, Main)
    end
end

local OnEnable = function(self)
	self:RegisterEvent("UNIT_STATS")
    self:RegisterEvent("COMBAT_RATING_UPDATE")
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    self:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
	self:SetScript("OnEvent", Update)
	self:SetScript("OnMouseUp", OnMouseUp)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)

	self:Update(nil, "player")
end

local OnDisable = function(self)
	self:UnregisterEvent("UNIT_STATS")
    self:UnregisterEvent("COMBAT_RATING_UPDATE")
    self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
    self:UnregisterEvent("UPDATE_SHAPESHIFT_FORM")
	self:SetScript("OnEvent", nil)
	self:SetScript("OnMouseUp", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)

	self.Text:SetText("")
end

YxUI:AddDataText(Label, OnEnable, OnDisable, Update)
