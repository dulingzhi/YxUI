local _, ns = ...
local YxUI = ns:get()
local UF = YxUI:GetModule("Unit Frames")

local PowerEvents = {
	"UNIT_MAXPOWER",
	"UNIT_DISPLAYPOWER",
	"UNIT_POWER_BAR_HIDE",
	"UNIT_POWER_BAR_SHOW",
	"UNIT_CONNECTION",
	"UNIT_FACTION",
	"UNIT_FLAGS",
	"UNIT_THREAT_LIST_UPDATE",
}

local function SetPowerColor(frame, bar, unit, powerType, token, altR, altG, altB)
	local color, r, g, b

	if bar.colorPower then
		color = frame.colors.power[token] or frame.colors.power[powerType]

		if not color then
			if bar.GetAlternativeColor then
				r, g, b = bar:GetAlternativeColor(unit, powerType, token, altR, altG, altB)
			elseif altR then
				r, g, b = altR, altG, altB
				if r > 1 or g > 1 or b > 1 then
					r, g, b = r / 255, g / 255, b / 255
				end
			else
				color = frame.colors.power.MANA
			end
		end
	elseif bar.colorClass and UnitIsPlayer(unit) then
		local _, class = UnitClass(unit)
		color = frame.colors.class[class]
	elseif bar.colorReaction then
		color = frame.colors.reaction[UnitReaction(unit, "player") or 5]
	end

	if color then
		r, g, b = color[1], color[2], color[3]
	end

	if r then
		bar:SetStatusBarColor(r, g, b)

		if bar.bg then
			local multiplier = bar.bg.multiplier or 1
			bar.bg:SetVertexColor(r * multiplier, g * multiplier, b * multiplier)
		end
	end

	return r, g, b
end

local function UpdatePower(frame, event, unit)
	if unit ~= frame.unit then
		return
	end

	local bar = frame.Power
	local isValueEvent = event == "UNIT_POWER_UPDATE" or event == "UNIT_POWER_FREQUENT"
	local refreshRange = not bar._powerStateReady or bar._powerStateUnit ~= unit or not (isValueEvent or event == "UNIT_CONNECTION"
		or event == "UNIT_FACTION" or event == "UNIT_FLAGS" or event == "UNIT_THREAT_LIST_UPDATE")
	local displayType, minimum, maximum = bar.displayType, bar.min, bar.max

	if refreshRange then
		if bar.displayAltPower and bar.GetDisplayPower then
			displayType, minimum = bar:GetDisplayPower(unit)
		else
			displayType, minimum = nil, nil
		end
		maximum = UnitPowerMax(unit, displayType)
	end

	if refreshRange or event == "UNIT_CONNECTION" or event == "UNIT_FLAGS" then
		bar._powerConnected = UnitIsConnected(unit)
	end

	local current = UnitPower(unit, displayType)

	if bar.PreUpdate then
		bar:PreUpdate(unit)
	end

	if refreshRange then
		bar:SetMinMaxValues(minimum or 0, maximum)
		bar._powerStateReady = true
		bar._powerStateUnit = unit
	end

	bar:SetValue(bar._powerConnected and current or maximum)
	bar.cur, bar.min, bar.max, bar.displayType = current, minimum, maximum, displayType

	if not isValueEvent then
		local powerType, token, altR, altG, altB = UnitPowerType(unit)
		local r, g, b = SetPowerColor(frame, bar, unit, powerType, token, altR, altG, altB)

		if bar.PostUpdateColor then
			bar:PostUpdateColor(unit, r, g, b)
		end
	end

	if bar.PostUpdate then
		bar:PostUpdate(unit, current, minimum, maximum)
	end
end

local function EnablePower(frame)
	local bar = frame.Power

	if not bar then
		return
	end

	bar.__owner = frame
	bar._powerStateReady = nil
	bar._powerStateUnit = nil
	bar.ForceUpdate = UF:CreateForceUpdate(bar, UpdatePower)
	frame:RegisterEvent(bar.frequentUpdates and "UNIT_POWER_FREQUENT" or "UNIT_POWER_UPDATE", UpdatePower)

	for _, event in ipairs(PowerEvents) do
		frame:RegisterEvent(event, UpdatePower)
	end

	bar:Show()

	return true
end

local function DisablePower(frame)
	frame.Power._powerStateReady = nil
	frame.Power._powerStateUnit = nil
	frame.Power:Hide()
	frame:UnregisterEvent("UNIT_POWER_UPDATE", UpdatePower)
	frame:UnregisterEvent("UNIT_POWER_FREQUENT", UpdatePower)

	for _, event in ipairs(PowerEvents) do
		frame:UnregisterEvent(event, UpdatePower)
	end
end

UF:RegisterElement("Power", {
	update = UpdatePower,
	enable = EnablePower,
	disable = DisablePower,
})
