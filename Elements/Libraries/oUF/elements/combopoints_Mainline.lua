local _, ns = ...
local oUF = ns.oUF
local HydraUI, Language, Assets, Settings = ns:get()

local GetShapeshiftForm = GetShapeshiftForm
local GetComboPoints = GetComboPoints
local GetUnitChargedPowerPoints = GetUnitChargedPowerPoints
local UnitPowerMax = UnitPowerMax
local Index = Enum.PowerType.ComboPoints

local Update = function(self, event, unit, power)
	if ((unit ~= self.unit) or (unit == "player" and power ~= "COMBO_POINTS")) then
		return
	end

	local element = self.ComboPoints

	if element.PreUpdate then
		element:PreUpdate()
	end

	local Points = GetComboPoints("player", "target")

	for i = 1, UnitPowerMax("player", Index) do
		if (i > Points) then
			if (element[i]:GetAlpha() > 0.3) then
				element[i]:SetAlpha(0.3)
			end
		else
			if (element[i]:GetAlpha() < 1) then
				element[i]:SetAlpha(1)
			end
		end
	end

	if element.PostUpdate then
		return element:PostUpdate(Points)
	end
end

local Path = function(self, ...)
	return (self.ComboPoints.Override or Update)(self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, "ForceUpdate")
end

local UpdateForm = function(self)
	if (GetShapeshiftForm() == 2) then
		self.ComboPoints:Show()
	else
		self.ComboPoints:Hide()
	end
end

local UpdateMaxPoints = function(self)
	local Points = self.ComboPoints
	local Max = UnitPowerMax("player", Index)
	local Width = (Settings["unitframes-player-width"] / Max) - 1

	for i = 1, Max do
		Points[i]:SetWidth(i == 1 and Width - 1 or Width)
	end

	for i = 1, 7 do
		if (i > Max) then
			Points[i]:Hide()
			Points[i].BG:Hide()
		else
			Points[i]:Show()
			Points[i]:SetAlpha(0.3)
			Points[i].BG:Show()
		end
	end
end

local UpdateChargedPoint = function(self) -- Really want a cleaner way to write this without 2 loops. Can't wait for blizz to remove this dumb feature
	for i = 2, UnitPowerMax("player", Index) do -- Reset charges
		self.ComboPoints[i].Charged:Hide()
	end

	local Charged = GetUnitChargedPowerPoints("player")

	if Charged then
		for i = 1, #Charged do
			self.ComboPoints[Charged[i]].Charged:Show()
		end
	end
end

local Enable = function(self)
	local element = self.ComboPoints

	if element then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent("PLAYER_ENTERING_WORLD", Path, true)
		self:RegisterEvent("UNIT_POWER_UPDATE", Path, true)

		if (HydraUI.UserClass == "DRUID") then
			self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", UpdateForm, true)
			self:RegisterEvent("PLAYER_ENTERING_WORLD", UpdateForm, true)
		else
			self:RegisterEvent("SPELLS_CHANGED", UpdateMaxPoints, true)
			self:RegisterEvent("UNIT_POWER_POINT_CHARGE", UpdateChargedPoint)
		end

		for i = 1, UnitPowerMax("player", Index) do
			if (element[i]:IsObjectType("Texture") and not element[i]:GetTexture()) then
				element[i]:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
			end

			element[i]:SetAlpha(0.3)
		end

		return true
	end
end

local Disable = function(self)
	local element = self.ComboPoints

	if element then
		element:Hide()

		self:UnregisterEvent("PLAYER_ENTERING_WORLD", Path)
		self:UnregisterEvent("UNIT_POWER_UPDATE", Path)

		if (HydraUI.UserClass == "DRUID") then
			self:UnregisterEvent("UPDATE_SHAPESHIFT_FORM", UpdateForm)
			self:UnregisterEvent("PLAYER_ENTERING_WORLD", UpdateForm)
		else
			self:UnregisterEvent("SPELLS_CHANGED", UpdateMaxPoints)
			self:UnregisterEvent("UNIT_POWER_POINT_CHARGE", UpdateChargedPoint)
		end
	end
end

oUF:AddElement("ComboPoints", Path, Enable, Disable)