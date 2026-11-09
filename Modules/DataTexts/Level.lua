local YxUI, Language, Assets, Settings = select(2, ...):get()

local UnitLevel = UnitLevel
local Label = Language["Level"]
local IsReadable = YxUI.IsDataTextReadable

local OnMouseUp = function()
	if InCombatLockdown() then
		return print(ERR_NOT_IN_COMBAT)
	end

	ToggleCharacter("PaperDollFrame")
end


local OnLeave = function()
	GameTooltip:Hide()
end

local OnEnter = function(self)
	if not self:SetTooltip() then return end

	local level = YxUI.GetDataTextLastValue(self, UnitLevel("player"), "level-tooltip")
	GameTooltip:AddLine((LEVEL or "Level") .. " " .. (IsReadable(level) and level or "--"), 1, 0.82, 0)
	GameTooltip:AddLine(" ")
	local xp, maxXP = UnitXP("player"), UnitXPMax("player")
	local snapshot = YxUI.GetDataTextLastValue(self, IsReadable(xp) and IsReadable(maxXP) and {xp, maxXP} or nil, "level-xp")
	if snapshot and snapshot[2] > 0 then
		xp, maxXP = snapshot[1], snapshot[2]
		GameTooltip:AddDoubleLine(POWER_TYPE_EXPERIENCE or "Experience", format("%s / %s (%.1f%%)", YxUI:Comma(xp), YxUI:Comma(maxXP), 100 * xp / maxXP), 1, 1, 1, 1, 1, 1)
		GameTooltip:AddDoubleLine(Language["Remaining Experience"] or "Remaining", YxUI:Comma(math.max(0, maxXP - xp)), 1, 1, 1, 1, 1, 1)
		local rested = GetXPExhaustion and GetXPExhaustion()
		if IsReadable(rested) and rested > 0 then
			GameTooltip:AddDoubleLine(Language["Rested Experience"] or "Rested", format("%s (%.1f%%)", YxUI:Comma(rested), 100 * rested / maxXP), 1, 1, 1, 1, 1, 1)
		end
	elseif IsReadable(maxXP) and maxXP <= 0 then
		GameTooltip:AddLine(GUILD_RECRUITMENT_MAXLEVEL or "Maximum level", 0.75, 0.75, 0.75)
	end
	GameTooltip:Show()
end

local Update = function(self)
	local Value = YxUI.GetDataTextLastValue(self, UnitLevel("player"))
	self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%s|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, IsReadable(Value) and Value or "--")
end

local OnEnable = function(self)
	self:RegisterEvent("PLAYER_LEVEL_UP")
	self:SetScript("OnEvent", Update)
	self:SetScript("OnMouseUp", OnMouseUp)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)

	self:Update()
end

local OnDisable = function(self)
	self:UnregisterEvent("PLAYER_LEVEL_UP")
	self:SetScript("OnEvent", nil)
	self:SetScript("OnMouseUp", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)

	self.Text:SetText("")
end

YxUI:AddDataText("Level", OnEnable, OnDisable, Update)
