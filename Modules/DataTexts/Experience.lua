local YxUI, Language, Assets, Settings = select(2, ...):get()

local Message = BONUS_OBJECTIVE_EXPERIENCE_FORMAT
local IsReadable = YxUI.IsDataTextReadable

local OnMouseUp = function()
	if InCombatLockdown() then
		return
	end
	ToggleCharacter("PaperDollFrame")
end

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	local Rested = GetXPExhaustion()
	local XP = UnitXP("player")
	local Max = UnitXPMax("player")
	local Snapshot = YxUI.GetDataTextLastValue(self, IsReadable(XP) and IsReadable(Max) and {XP, Max} or nil, "xp-snapshot")
	XP, Max = Snapshot and Snapshot[1], Snapshot and Snapshot[2]
	if not XP or not Max or Max <= 0 then
		local Level = YxUI.GetDataTextLastValue(self, UnitLevel("player"), "xp-level")
		GameTooltip:AddLine(LEVEL .. " " .. (IsReadable(Level) and Level or "--"), 1, 0.82, 0)
		if Max and Max <= 0 then
			GameTooltip:AddLine(GUILD_RECRUITMENT_MAXLEVEL, 0.75, 0.75, 0.75)
		end
		GameTooltip:Show()
		return
	end

	local Percent = floor((XP / Max * 100 + 0.05) * 10) / 10
	local Remaining = Max - XP
	local RemainingPercent = floor((Remaining / Max * 100 + 0.05) * 10) / 10

	local Level = UnitLevel("player")
	GameTooltip:AddLine(LEVEL .. " " .. (IsReadable(Level) and Level or "--"), 1, 0.82, 0)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(Language["Current Experience"], 1, 0.82, 0)
	GameTooltip:AddDoubleLine(format("%s / %s", YxUI:Comma(XP), YxUI:Comma(Max)), format("%s%%", Percent), 1, 1, 1, 1, 1, 1)

	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(Language["Remaining Experience"], 1, 0.82, 0)
	GameTooltip:AddDoubleLine(format("%s", YxUI:Comma(Remaining)), format("%s%%", RemainingPercent), 1, 1, 1, 1, 1, 1)

	if IsReadable(Rested) then
		local RestedPercent = floor((Rested / Max * 100 + 0.05) * 10) / 10

		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(Language["Rested Experience"], 1, 0.82, 0)
		GameTooltip:AddDoubleLine(YxUI:Comma(Rested), format("%s%%", RestedPercent), 1, 1, 1, 1, 1, 1)
	end

	GameTooltip:Show()
end

local OnLeave = function()
	GameTooltip:Hide()
end

local Update = function(self)
	local Level = UnitLevel("player")
	if IsReadable(Level) and Level == MAX_PLAYER_LEVEL then
		self:Disable()
		self.Text:SetText(GUILD_RECRUITMENT_MAXLEVEL)

		return
	end

	local XP = UnitXP("player")
	local MaxXP = UnitXPMax("player")
	if IsReadable(XP) and IsReadable(MaxXP) then
		YxUI.GetDataTextLastValue(self, {XP, MaxXP}, "xp-snapshot")
	end
	if not IsReadable(XP) or not IsReadable(MaxXP) then
		self.Text:SetText(YxUI.GetDataTextLastValue(self, nil) or "--")
		return
	end
	if MaxXP <= 0 then
		self.Text:SetText(GUILD_RECRUITMENT_MAXLEVEL)
		return
	end

	local Value = "|cff" .. YxUI.ValueColor .. floor((XP / MaxXP * 100 + 0.05) * 10) / 10 .. "%|r"

	local Display = format(Message, Value)
	YxUI.GetDataTextLastValue(self, Display)
	self.Text:SetText(Display)
end

local OnEnable = function(self)
	self:RegisterEvent("PLAYER_XP_UPDATE")
	self:RegisterEvent("PLAYER_UPDATE_RESTING")
	self:RegisterEvent("UPDATE_EXHAUSTION")
	self:RegisterEvent("ZONE_CHANGED")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	if YxUI.IsMainline then
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
	end

	self:SetScript("OnEvent", Update)
	self:SetScript("OnMouseUp", OnMouseUp)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)

	self:Update()
end

local OnDisable = function(self)
	self:UnregisterEvent("PLAYER_XP_UPDATE")
	self:UnregisterEvent("PLAYER_UPDATE_RESTING")
	self:UnregisterEvent("UPDATE_EXHAUSTION")
	self:UnregisterEvent("ZONE_CHANGED")
	self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
	if YxUI.IsMainline then
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end

	self:SetScript("OnEvent", nil)
	self:SetScript("OnMouseUp", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)

	self.Text:SetText("")
end

YxUI:AddDataText(POWER_TYPE_EXPERIENCE, OnEnable, OnDisable, Update)
