local YxUI, Language, Assets, Settings = select(2, ...):get()

local format = format
local floor = math.floor
local GetTime = GetTime

local SecondsToTime = function(seconds)
	local Total = math.max(0, floor(seconds))
	local Hours = floor(Total / 3600)
	local Minutes = floor((Total % 3600) / 60)
	local Seconds = Total % 60

	if Hours > 0 then
		return format("%d:%02d:%02d", Hours, Minutes, Seconds)
	end

	return format("%02d:%02d", Minutes, Seconds)
end

local UpdateElapsed = function(self)
	if self.CombatStart then
		self.Text:SetText(SecondsToTime(GetTime() - self.CombatStart))
	end
end

local OnEnter = function(self)
	if not self:SetTooltip() then return end

	local now = GetTime()
	local current = self.CombatStart and math.max(0, now - self.CombatStart) or 0
	GameTooltip:AddLine("Combat Time", 1, 0.82, 0)
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine("Current combat", SecondsToTime(current), 1, 1, 1, 1, 1, 1)
	GameTooltip:Show()
end

local OnLeave = function()
	GameTooltip:Hide()
end

local StartCombat = function(self)
	if self.Ticker then
		self.Ticker:Cancel()
	end

	self.CombatStart = GetTime()
	self.Ticker = C_Timer.NewTicker(1, function()
		UpdateElapsed(self)
	end)
	self.Text:SetText(SecondsToTime(0))
	self.Text:SetTextColor(YxUI:HexToRGB(YxUI.ValueColor))
end

local Update = function(self, event)
	if event == "PLAYER_REGEN_DISABLED" then
		StartCombat(self)
	elseif event == "PLAYER_REGEN_ENABLED" then
		if self.Ticker then
			self.Ticker:Cancel()
			self.Ticker = nil
		end

		self.CombatStart = nil
		self.Text:SetText(SecondsToTime(0))
		self.Text:SetTextColor(1, 1, 1)
	end
end

local OnEnable = function(self)
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:SetScript("OnEvent", Update)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)
	self.Text:SetText(SecondsToTime(0))
	self.Text:SetTextColor(1, 1, 1)

	if InCombatLockdown() then
		StartCombat(self)
	end
end

local OnDisable = function(self)
	if self.Ticker then
		self.Ticker:Cancel()
		self.Ticker = nil
	end

	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:UnregisterEvent("PLAYER_REGEN_DISABLED")
	self:SetScript("OnEvent", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)
	self.CombatStart = nil
	self.Text:SetText("")
	self.Text:SetTextColor(1, 1, 1)
end

YxUI:AddDataText("Combat Time", OnEnable, OnDisable, Update)
