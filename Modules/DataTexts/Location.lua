local YxUI, Language, Assets, Settings = select(2, ...):get()

local GetMinimapZoneText = GetMinimapZoneText
local IsModernZonePVP = C_PvP and type(C_PvP.GetZonePVPInfo) == "function"
local GetZonePVPInfo = IsModernZonePVP and C_PvP.GetZonePVPInfo or GetZonePVPInfo

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	local ZoneText = GetRealZoneText()
	local SubZoneText = GetMinimapZoneText()
	local PVPType, IsFFA, Faction = GetZonePVPInfo()
	if IsModernZonePVP then
		IsFFA = PVPType == "arena"
	end
	local Color = YxUI.ZoneColors[PVPType or "other"]
	local Label

	if ZoneText and ZoneText ~= SubZoneText then
		Label = format("%s - %s", SubZoneText, ZoneText)
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

	if GetInstanceInfo then
		local InstanceName, InstanceType, _, DifficultyName, MaxPlayers = GetInstanceInfo()
		local Readable = YxUI.IsDataTextReadable
		if Readable(InstanceType) and InstanceType ~= "none" and Readable(InstanceName) and type(InstanceName) == "string" and InstanceName ~= "" then
			GameTooltip:AddLine(" ")
			GameTooltip:AddDoubleLine(INSTANCE or "Instance", InstanceName, 1, 1, 1, 1, 1, 1)
			if Readable(DifficultyName) and type(DifficultyName) == "string" and DifficultyName ~= "" then
				GameTooltip:AddDoubleLine(DUNGEON_DIFFICULTY or "Difficulty", DifficultyName, 1, 1, 1, 1, 1, 1)
			end
			if Readable(MaxPlayers) and type(MaxPlayers) == "number" and MaxPlayers > 0 then
				GameTooltip:AddDoubleLine("Maximum players", tostring(MaxPlayers), 1, 1, 1, 1, 1, 1)
			end
		end
	end

	self.TooltipShown = true

	GameTooltip:Show()
end

local OnLeave = function(self)
	GameTooltip:Hide()
	self.TooltipShown = false
end

local OnMouseUp = function(self)
	if WorldMapFrame then
		ToggleFrame(WorldMapFrame)
	end
end

local Update = function(self)
	local Color = YxUI.ZoneColors[GetZonePVPInfo() or "other"]

	self.Text:SetText(GetMinimapZoneText())
	self.Text:SetTextColor(Color[1], Color[2], Color[3])

	if self.TooltipShown then
		GameTooltip:ClearLines()
		OnEnter(self)
	end
end

local OnEnable = function(self)
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("ZONE_CHANGED")
	self:RegisterEvent("ZONE_CHANGED_INDOORS")
	self:SetScript("OnEvent", Update)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)
	self:SetScript("OnMouseUp", OnMouseUp)

	self:Update()
end

local OnDisable = function(self)
	self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
	self:UnregisterEvent("ZONE_CHANGED")
	self:UnregisterEvent("ZONE_CHANGED_INDOORS")
	self:SetScript("OnEvent", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)
	self:SetScript("OnMouseUp", nil)

	self.Text:SetText("")
	self.Text:SetTextColor(1, 1, 1)
end

YxUI:AddDataText("Location", OnEnable, OnDisable, Update)
