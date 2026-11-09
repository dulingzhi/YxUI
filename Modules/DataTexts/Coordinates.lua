local YxUI, Language, Assets, Settings = select(2, ...):get()

local GetBestMapForUnit = C_Map.GetBestMapForUnit
local GetPlayerMapPosition = C_Map.GetPlayerMapPosition
local IsReadable = YxUI.IsDataTextReadable
local IsModernZonePVP = C_PvP and type(C_PvP.GetZonePVPInfo) == "function"
local GetZonePVPInfo = IsModernZonePVP and C_PvP.GetZonePVPInfo or GetZonePVPInfo

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end
	GameTooltip:ClearLines()

	-- Location
	local ZoneText = GetRealZoneText()
	local SubZoneText = GetMinimapZoneText()
	local PVPType, IsFFA, Faction = GetZonePVPInfo()
	if IsModernZonePVP then
		IsFFA = PVPType == "arena"
	end
	local Color = YxUI.ZoneColors[PVPType or "other"]
	local Label

	if ZoneText ~= SubZoneText then
		Label = format("%s - %s", ZoneText, SubZoneText)
	else
		Label = ZoneText
	end

	GameTooltip:AddLine(Label, 1, 0.82, 0)

	if PVPType == "friendly" or PVPType == "hostile" then
		GameTooltip:AddLine(format(FACTION_CONTROLLED_TERRITORY, Faction), Color[1], Color[2], Color[3])
	elseif PVPType == "sanctuary" then
		GameTooltip:AddLine(SANCTUARY_TERRITORY, Color[1], Color[2], Color[3])
	elseif IsFFA then
		GameTooltip:AddLine(FREE_FOR_ALL_TERRITORY, Color[1], Color[2], Color[3])
	else
		GameTooltip:AddLine(CONTESTED_TERRITORY, Color[1], Color[2], Color[3])
	end


	self.TooltipShown = true

	GameTooltip:Show()
end

local OnLeave = function(self)
	GameTooltip:Hide()
	self.TooltipShown = false
end

local Update = function(self)
	local MapID = GetBestMapForUnit("player")
	local Position = IsReadable(MapID) and GetPlayerMapPosition(MapID, "player")
	local X, Y
	if IsReadable(Position) then
		X, Y = Position:GetXY()
	end

	local Values = YxUI.GetDataTextLastValue(self, IsReadable(X) and IsReadable(Y) and {X, Y} or nil)
	if Values then
		self.Text:SetFormattedText("|cFF%s%.2f|r, |cFF%s%.2f|r", YxUI.ValueColor, Values[1] * 100, YxUI.ValueColor, Values[2] * 100)
	else
		self.Text:SetText("--, --")
	end

	if self.TooltipShown then
		OnEnter(self)
	end
end

local OnEnable = function(self)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)

	if self.Ticker then
		self.Ticker:Cancel()
	end

	self.Ticker = C_Timer.NewTicker(0.5, function()
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
	self.TooltipShown = false

	self.Text:SetText("")
end

YxUI:AddDataText("Coordinates", OnEnable, OnDisable, Update)
