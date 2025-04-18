local YxUI, Language, Assets, Settings = select(2, ...):get()

local gsub = gsub
local format = format
local GameTime_GetGameTime = GameTime_GetGameTime

local OnMouseUp = function(self, button)
	if InCombatLockdown() then
		return print(ERR_NOT_IN_COMBAT)
	end

	if (ToggleCalendar and button == "LeftButton") then
		ToggleCalendar()
	else
		TimeManager_Toggle()
	end
end

local OnEnter = function(self)
	self:SetTooltip()

	local HomeLatency, WorldLatency = select(3, GetNetStats())
	local Framerate = floor(GetFramerate())
	local LocalTime = GameTime_GetLocalTime(true)

	GameTooltip:AddLine(TIMEMANAGER_TOOLTIP_LOCALTIME, 1, 0.7, 0)
	GameTooltip:AddLine(LocalTime, 1, 1, 1)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(Language["Latency:"], 1, 0.7, 0)
	GameTooltip:AddLine(format(Language["%s ms (home)"], HomeLatency), 1, 1, 1)
	GameTooltip:AddLine(format(Language["%s ms (world)"], WorldLatency), 1, 1, 1)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(Language["Framerate:"], 1, 0.7, 0)
	GameTooltip:AddLine(Framerate .. " " .. FPS_ABBR, 1, 1, 1)

	GameTooltip:Show()
end

local OnLeave = function()
	GameTooltip:Hide()
end

local Update = function(self, elapsed)
	self.Elapsed = self.Elapsed + elapsed

	if (self.Elapsed > 10) then
		local Time = GameTime_GetGameTime(true)

		Time = gsub(Time, "%a+", format("|cFF%s%s|r", YxUI.ValueColor, "%1"))

		self.Text:SetText(Time)

		self.Elapsed = 0
	end
end

local OnEnable = function(self)
	self.Elapsed = 0
	self:SetScript("OnUpdate", Update)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)
	self:SetScript("OnMouseUp", OnMouseUp)

	self:Update(11)
end

local OnDisable = function(self)
	self:SetScript("OnUpdate", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)
	self:SetScript("OnMouseUp", nil)
	self.Elapsed = 0

	self.Text:SetText("")
end

YxUI:AddDataText("Time - Realm", OnEnable, OnDisable, Update)