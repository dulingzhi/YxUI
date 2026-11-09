local YxUI, Language, Assets, Settings = select(2, ...):get()

local GetFramerate = GetFramerate
local GetNetStats = GetNetStats
local floor = floor
local select = select
local FPSLabel = Language["FPS"]
local MSLabel = Language["MS"]

local OnEnter = function(self)
	if not self:SetTooltip() then return end

	GameTooltip:AddLine(SYSTEM or "System", 1, 0.82, 0)
	GameTooltip:AddLine(" ")
	local fps = GetFramerate()
	if fps and (not issecretvalue or not issecretvalue(fps)) then
		GameTooltip:AddDoubleLine(FPSLabel, format("%d", floor(fps + 0.5)), 1, 1, 1, 1, 1, 1)
	end

	local bandwidthIn, bandwidthOut, home, world = GetNetStats()
	if home and (not issecretvalue or not issecretvalue(home)) then
		GameTooltip:AddDoubleLine(HOME or "Home", format("%d ms", home), 1, 1, 1, 1, 1, 1)
	end
	if world and (not issecretvalue or not issecretvalue(world)) then
		GameTooltip:AddDoubleLine(WORLD or "World", format("%d ms", world), 1, 1, 1, 1, 1, 1)
	end
	if bandwidthIn and bandwidthOut and (not issecretvalue or (not issecretvalue(bandwidthIn) and not issecretvalue(bandwidthOut))) then
		GameTooltip:AddDoubleLine("Download / Upload", format("%.1f / %.1f KB/s", bandwidthIn, bandwidthOut), 0.85, 0.85, 0.85, 1, 1, 1)
	end

	if UpdateAddOnMemoryUsage and GetAddOnMemoryUsage then
		UpdateAddOnMemoryUsage()
		local kb = GetAddOnMemoryUsage("YxUI")
		if type(kb) == "number" and (not issecretvalue or not issecretvalue(kb)) then
			GameTooltip:AddDoubleLine("YxUI memory", format("%.2f MB", kb / 1024), 0.85, 0.85, 0.85, 1, 1, 1)
		end
	end
	GameTooltip:Show()
end

local OnLeave = function()
	GameTooltip:Hide()
end

local Update = function(self)
	self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%s|r |cFF%s%s:|r |cFF%s%s|r", Settings["data-text-label-color"], FPSLabel, YxUI.ValueColor, floor(GetFramerate() + 0.5), Settings["data-text-label-color"], MSLabel, YxUI.ValueColor, select(4, GetNetStats()))
end

local OnEnable = function(self)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)

	if self.Ticker then
		self.Ticker:Cancel()
	end

	self.Ticker = C_Timer.NewTicker(1, function()
		Update(self)
	end)

	Update(self)
end

local OnDisable = function(self)
	if self.Ticker then
		self.Ticker:Cancel()
		self.Ticker = nil
	end

	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)

	self.Text:SetText("")
end

YxUI:AddDataText("System", OnEnable, OnDisable, Update)
