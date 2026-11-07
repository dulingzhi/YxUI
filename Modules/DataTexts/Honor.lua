local YxUI, Language, Assets, Settings = select(2, ...):get()

local floor = floor
local UnitHonor = UnitHonor
local UnitHonorMax = UnitHonorMax
local UnitHonorLevel = UnitHonorLevel
local Label = HONOR

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	local Honor = UnitHonor("player") or 0
	local MaxHonor = UnitHonorMax("player") or 0
	local HonorLevel = UnitHonorLevel("player") or 0
	local NextRewardLevel = C_PvP and C_PvP.GetNextHonorLevelForReward and C_PvP.GetNextHonorLevelForReward(HonorLevel)
	local RewardInfo = NextRewardLevel and C_PvP.GetHonorRewardInfo and C_PvP.GetHonorRewardInfo(NextRewardLevel)
	local Percent = MaxHonor > 0 and floor((Honor / MaxHonor * 100 + 0.05) * 10) / 10 or 0
	local Remaining = MaxHonor > 0 and math.max(MaxHonor - Honor, 0) or 0
	local RemainingPercent = MaxHonor > 0 and floor((Remaining / MaxHonor * 100 + 0.05) * 10) / 10 or 0
	local Kills = GetPVPLifetimeStats() or 0

	GameTooltip:AddLine(format(HONOR_LEVEL_TOOLTIP, HonorLevel))
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(Language["Current honor"])
	GameTooltip:AddDoubleLine(format("%s / %s", YxUI:Comma(Honor), YxUI:Comma(MaxHonor)), format("%s%%", Percent), 1, 1, 1, 1, 1, 1)

	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(Language["Remaining honor"])
	GameTooltip:AddDoubleLine(format("%s", YxUI:Comma(Remaining)), format("%s%%", RemainingPercent), 1, 1, 1, 1, 1, 1)

	if Kills > 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(HONORABLE_KILLS)
		GameTooltip:AddLine(YxUI:Comma(Kills), 1, 1, 1)
	end

	if RewardInfo and RewardInfo.achievementRewardedID then
		local RewardText = select(11, GetAchievementInfo(RewardInfo.achievementRewardedID))

		if type(RewardText) == "string" and RewardText:match("%S") then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(PVP_PRESTIGE_RANK_UP_NEXT_MAX_LEVEL_REWARD:format(NextRewardLevel))
			GameTooltip:AddLine(RewardText, 1, 1, 1)
		end
	end

	GameTooltip:Show()
end

local OnLeave = function()
	GameTooltip:Hide()
end

local OnMouseUp = function()
	PVEFrame_ToggleFrame("PVPUIFrame", "HonorFrame")
end

local Update = function(self, event, unit)
	if unit and unit ~= "player" then
		return
	end

	self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%s / %s|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, UnitHonor("player"), UnitHonorMax("player"))
end

local OnEnable = function(self)
	self:RegisterUnitEvent("HONOR_XP_UPDATE", "player")

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
