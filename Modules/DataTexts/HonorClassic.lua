local YxUI, Language, Assets, Settings = select(2, ...):get()

local GetCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo
local Label = HONOR
local HonorCurrencyID = YxUI.IsMists and 392 or 1901

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	GameTooltip:AddLine(HONOR or "Honor", 1, 0.82, 0)
	GameTooltip:AddLine(" ")

	local HK = GetPVPSessionStats()
	local Rank = UnitPVPRank("player")

	if Rank > 0 then
		local Name, Number = GetPVPRankInfo(Rank, "player")

		GameTooltip:AddDoubleLine(Name, format("%s %s", RANK, Number), 1, 1, 1, 1, 1, 1)
	end

	if HK > 0 then
		if Rank > 0 then
			GameTooltip:AddLine(" ")
		end

		GameTooltip:AddLine(HONOR_TODAY, 1, 0.82, 0)
		GameTooltip:AddDoubleLine(HONORABLE_KILLS, YxUI:Comma(HK), 1, 1, 1, 1, 1, 1)
	end

	local LHK = GetPVPLifetimeStats()

	if LHK > 0 then
		if HK > 0 or Rank > 0 then
			GameTooltip:AddLine(" ")
		end

		GameTooltip:AddLine(HONOR_LIFETIME, 1, 0.82, 0)
		GameTooltip:AddDoubleLine(HONORABLE_KILLS, YxUI:Comma(LHK), 1, 1, 1, 1, 1, 1)
	end

	-- GetCurrentArenaSeason()


	--[[
		if IsInArenaTeam() then -- Inside OnEnable
			self:RegisterEvent("ARENA_TEAM_ROSTER_UPDATE")

			ArenaTeamRoster(1)
			ArenaTeamRoster(2)
			ArenaTeamRoster(3)
		end

		-- Inside tooltip
		local name, rank, level, class, online, played, win, seasonPlayed, seasonWin, personalRating = GetArenaTeamRosterInfo(teamindex, playerid); teamindex=1-3, playerid=1-5
	--]]

	GameTooltip:Show()
end

local OnLeave = function()
	GameTooltip:Hide()
end

local OnMouseUp = function()
	if YxUI.IsVanilla then
		ToggleCharacter("HonorFrame")
	elseif YxUI.IsWrath then
		TogglePVPFrame()
	else
		ToggleCharacter("PVPFrame")
	end
end

local Update = function(self)
	local Info = GetCurrencyInfo(HonorCurrencyID)

    if Info and Info.quantity ~= nil then
        self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%s|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, YxUI:Comma(Info.quantity))
    else
        self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s--|r", Settings["data-text-label-color"], Label, YxUI.ValueColor)
    end
end

local OnEnable = function(self)
	self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
	self:SetScript("OnEvent", Update)
	self:SetScript("OnMouseUp", OnMouseUp)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)

	self:Update()
end

local OnDisable = function(self)
	self:UnregisterEvent("CURRENCY_DISPLAY_UPDATE")
	self:SetScript("OnEvent", nil)
	self:SetScript("OnMouseUp", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)

	self.Text:SetText("")
end

YxUI:AddDataText("Honor", OnEnable, OnDisable, Update)
