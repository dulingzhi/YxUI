local YxUI, Language, Assets, Settings = select(2, ...):get()

local floor = floor
local UnitHonor = UnitHonor
local UnitHonorMax = UnitHonorMax
local UnitHonorLevel = UnitHonorLevel
local Label = HONOR
local IsReadable = YxUI.IsDataTextReadable

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	local Honor = UnitHonor("player")
	local MaxHonor = UnitHonorMax("player")
	local Values = YxUI.GetDataTextLastValue(self, IsReadable(Honor) and IsReadable(MaxHonor) and {Honor, MaxHonor} or nil)
	Honor, MaxHonor = Values and Values[1], Values and Values[2]
	local HonorLevel = UnitHonorLevel("player")
	local Kills = GetPVPLifetimeStats()
	local Available = Values ~= nil
	local Percent = Available and MaxHonor > 0 and floor((Honor / MaxHonor * 100 + 0.05) * 10) / 10 or 0
	local Remaining = Available and MaxHonor > 0 and math.max(MaxHonor - Honor, 0) or 0
	local RemainingPercent = Available and MaxHonor > 0 and floor((Remaining / MaxHonor * 100 + 0.05) * 10) / 10 or 0
	local NextRewardLevel = IsReadable(HonorLevel) and C_PvP and C_PvP.GetNextHonorLevelForReward and C_PvP.GetNextHonorLevelForReward(HonorLevel)
	local RewardInfo = IsReadable(NextRewardLevel) and C_PvP.GetHonorRewardInfo and C_PvP.GetHonorRewardInfo(NextRewardLevel)

	GameTooltip:AddLine(IsReadable(HonorLevel) and format(HONOR_LEVEL_TOOLTIP, HonorLevel) or Label, 1, 0.82, 0)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(Language["Current honor"], 1, 0.82, 0)
	GameTooltip:AddDoubleLine(Available and format("%s / %s", YxUI:Comma(Honor), YxUI:Comma(MaxHonor)) or "--", Available and format("%s%%", Percent) or "--", 1, 1, 1, 1, 1, 1)

	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(Language["Remaining honor"], 1, 0.82, 0)
	GameTooltip:AddDoubleLine(Available and YxUI:Comma(Remaining) or "--", Available and format("%s%%", RemainingPercent) or "--", 1, 1, 1, 1, 1, 1)

	if IsReadable(Kills) and Kills > 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddDoubleLine(HONORABLE_KILLS, YxUI:Comma(Kills), 1, 1, 1, 1, 1, 1)
	end

	if IsReadable(RewardInfo) and IsReadable(RewardInfo.achievementRewardedID) then
		local RewardText = select(11, GetAchievementInfo(RewardInfo.achievementRewardedID))

		if IsReadable(RewardText) and type(RewardText) == "string" and RewardText:match("%S") then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(PVP_PRESTIGE_RANK_UP_NEXT_MAX_LEVEL_REWARD:format(NextRewardLevel), 1, 0.82, 0)
			GameTooltip:AddLine(RewardText, 0.75, 0.75, 0.75, true)
		end
	end

	GameTooltip:Show()
end

local OnLeave = function()
	GameTooltip:Hide()
end

local OnMouseUp = function()
	if InCombatLockdown() then
		return
	end
	PVEFrame_ToggleFrame("PVPUIFrame", "HonorFrame")
end

local Update = function(self, event, unit)
	if unit and unit ~= "player" then
		return
	end

	local Honor = UnitHonor("player")
	local MaxHonor = UnitHonorMax("player")
	local Values = YxUI.GetDataTextLastValue(self, IsReadable(Honor) and IsReadable(MaxHonor) and {Honor, MaxHonor} or nil)
	local Left = Values and Values[1] or "--"
	local Right = Values and Values[2] or "--"
	self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%s / %s|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, Left, Right)
end

local OnEnable = function(self)
	self:RegisterUnitEvent("HONOR_XP_UPDATE", "player")
	if YxUI.IsMainline then
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
	end

	if YxUI.IsMainline and not YxUI.IsForever then
		self:RegisterEvent("HONOR_LEVEL_UPDATE")
	end

	self:SetScript("OnEvent", Update)
	self:SetScript("OnMouseUp", OnMouseUp)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)

	self:Update(nil, "player")
end

local OnDisable = function(self)
	self:UnregisterEvent("HONOR_XP_UPDATE")
	if YxUI.IsMainline then
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end

	if YxUI.IsMainline and not YxUI.IsForever then
		self:UnregisterEvent("HONOR_LEVEL_UPDATE")
	end

	self:SetScript("OnEvent", nil)
	self:SetScript("OnMouseUp", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)

	self.Text:SetText("")
end

YxUI:AddDataText("Honor", OnEnable, OnDisable, Update)
