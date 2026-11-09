local YxUI, Language, Assets, Settings = select(2, ...):get()

local format = format
local IsReadable = YxUI.IsDataTextReadable
local IsSecret = function(v) return issecretvalue and issecretvalue(v) end
local floor = math.floor
local GetWatchedFactionInfo = GetWatchedFactionInfo
local GetWatchedFactionData = C_Reputation and C_Reputation.GetWatchedFactionData
local GetMajorFactionData = YxUI.IsMainline and C_MajorFactions and C_MajorFactions.GetMajorFactionData
local HasMaximumRenown = YxUI.IsMainline and C_MajorFactions and C_MajorFactions.HasMaximumRenown
local GetFriendshipReputation = YxUI.IsMainline and C_GossipInfo and C_GossipInfo.GetFriendshipReputation
local GetFriendshipReputationRanks = YxUI.IsMainline and C_GossipInfo and C_GossipInfo.GetFriendshipReputationRanks

local GetProgress = function(minimum, maximum, current)
	if IsSecret(minimum) or IsSecret(maximum) or IsSecret(current) then
		return 0, 0, 0, 0
	end
	minimum = minimum or 0
	local Range = math.max(0, (maximum or minimum) - minimum)

	if Range == 0 then
		return 0, 0, 100, 0
	end

	local Value = math.max(0, math.min(Range, (current or minimum) - minimum))
	local Percent = floor(Value / Range * 1000 + 0.5) / 10
	local RemainingPercent = floor((Range - Value) / Range * 1000 + 0.5) / 10
	return Value, Range, Percent, RemainingPercent
end

local GetWatchedProgress = function()
	local Name, StandingID, Min, Max, Value, FactionID

	if GetWatchedFactionData then
		local Data = GetWatchedFactionData()
		if IsSecret(Data) then
			return nil, true
		end
		if IsReadable(Data) then
			Name = Data.name
			StandingID = Data.reaction
			Min = Data.currentReactionThreshold
			Max = Data.nextReactionThreshold
			Value = Data.currentStanding
			FactionID = Data.factionID
		end
	elseif GetWatchedFactionInfo then
		Name, StandingID, Min, Max, Value, FactionID = GetWatchedFactionInfo()
	end

	if not IsReadable(Name) or IsSecret(StandingID) or IsSecret(Min) or IsSecret(Max) or IsSecret(Value) or IsSecret(FactionID) then
		return nil, IsSecret(Name) or IsSecret(StandingID) or IsSecret(Min) or IsSecret(Max) or IsSecret(Value) or IsSecret(FactionID)
	end

	if FactionID and GetMajorFactionData then
		local Data = GetMajorFactionData(FactionID)
		if IsReadable(Data) and IsReadable(Data.renownLevel) and not IsSecret(Data.maxLevel) and not IsSecret(Data.renownReputationEarned) and not IsSecret(Data.renownLevelThreshold) then
			local AtMax = (Data.maxLevel and Data.renownLevel >= Data.maxLevel) or (HasMaximumRenown and HasMaximumRenown(FactionID))
			if IsSecret(AtMax) then
				return nil, true
			end
			local Current = Data.renownReputationEarned or 0
			local Threshold = Data.renownLevelThreshold or 0
			if AtMax then
				Current, Threshold = 0, 0
			end
			return Name, "renown", 0, Threshold, Current, Data.renownLevel, nil, Data.maxLevel
		end
	end

	if FactionID and GetFriendshipReputation then
		local Data = GetFriendshipReputation(FactionID)
		if IsReadable(Data) and IsReadable(Data.friendshipFactionID) and Data.friendshipFactionID > 0
			and not IsSecret(Data.reactionThreshold) and not IsSecret(Data.nextThreshold) and not IsSecret(Data.standing) and not IsSecret(Data.reaction) then
			local Rank = GetFriendshipReputationRanks and GetFriendshipReputationRanks(FactionID)
			if IsSecret(Rank) or (Rank and (IsSecret(Rank.currentLevel) or IsSecret(Rank.maxLevel))) then
				return nil, true
			end
			local Minimum = Data.reactionThreshold or 0
			local Maximum = Data.nextThreshold or Minimum
			return Name, "friendship", Minimum, Maximum, Data.standing or Minimum, Data.reaction, Rank and Rank.currentLevel, Rank and Rank.maxLevel
		end
	end

	return Name, "standard", Min, Max, Value, StandingID
end

local OnMouseUp = function()
	if InCombatLockdown() then
		return
	end
	ToggleCharacter("ReputationFrame")
end

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	local Name, Kind, Min, Max, Value, Standing, Level, MaxLevel = GetWatchedProgress()
	if not Name then
		GameTooltip:Hide()
		return
	end

	local Progress, Total, Percent, RemainingPercent = GetProgress(Min, Max, Value)
	local Remaining = Total - Progress

	GameTooltip:AddLine(Name, 1, 0.82, 0)
	GameTooltip:AddLine(" ")

	if Kind == "renown" then
		local Rank = MaxLevel and format("Renown %s / %s", Standing, MaxLevel) or format("Renown %s", Standing)
		GameTooltip:AddDoubleLine(Language["Faction standing"], Rank, 1, 1, 1, 1, 1, 1)
	elseif Kind == "friendship" then
		local Rank = Level and MaxLevel and format("%s (%s/%s)", Standing or "", Level, MaxLevel) or Standing
		GameTooltip:AddDoubleLine(Language["Faction standing"], Rank or "", 1, 1, 1, 1, 1, 1)
	else
		local Label = Standing and _G["FACTION_STANDING_LABEL" .. Standing] or nil
		GameTooltip:AddDoubleLine(Language["Faction standing"], Label or NOT_APPLICABLE, 1, 1, 1, 1, 1, 1)
	end

	if Total > 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddDoubleLine(Language["Current reputation"], format("%s / %s (%s%%)", YxUI:Comma(Progress), YxUI:Comma(Total), Percent), 1, 1, 1, 1, 1, 1)
		GameTooltip:AddDoubleLine(Language["Remaining reputation"], format("%s (%s%%)", YxUI:Comma(Remaining), RemainingPercent), 1, 1, 1, 1, 1, 1)
	end

	GameTooltip:Show()
end

local OnLeave = function()
	GameTooltip:Hide()
end

local Update = function(self)
	local Name, Kind, Min, Max, Value, Standing = GetWatchedProgress()
	if not Name then
		local Cached = Kind == true and YxUI.GetDataTextLastValue(self, nil)
		self.Text:SetText(Cached or "")
		return
	end

	local _, _, Percent = GetProgress(Min, Max, Value)
	local Display
	if Kind == "renown" then
		Display = format("|cff%sR%s: %s%%|r", YxUI.ValueColor, Standing, Percent)
	else
		Display = format("|cff%s%s%%|r", YxUI.ValueColor, Percent)
	end
	self.Text:SetText(YxUI.GetDataTextLastValue(self, Display))
end

local OnEnable = function(self)
	self:RegisterEvent("UPDATE_FACTION")
	if YxUI.IsMainline then
		self:RegisterEvent("MAJOR_FACTION_RENOWN_LEVEL_CHANGED")
	end
	self:SetScript("OnEvent", Update)
	self:SetScript("OnMouseUp", OnMouseUp)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)
	self:Update()
end

local OnDisable = function(self)
	self:UnregisterEvent("UPDATE_FACTION")
	if YxUI.IsMainline then
		self:UnregisterEvent("MAJOR_FACTION_RENOWN_LEVEL_CHANGED")
	end
	self:SetScript("OnEvent", nil)
	self:SetScript("OnMouseUp", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)
	self.Text:SetText("")
end

YxUI:AddDataText(REPUTATION, OnEnable, OnDisable, Update)
