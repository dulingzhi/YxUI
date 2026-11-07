local _, ns = ...
local YxUI, _, _, Settings = ns:get()
local UF = YxUI:GetModule("Unit Frames")

local function IsSecret(value)
	return issecretvalue and issecretvalue(value)
end

local function ManaOnUpdate(element, elapsed)
	element.elapsed = element.elapsed + elapsed
	element:SetValue(element.elapsed)

	if element.elapsed >= element.max then
		local power = UnitPower("player")
		element.LastPower = not IsSecret(power) and power or nil
		element:Hide()
		element:SetScript("OnUpdate", nil)
	end
end

local function UpdateMana(frame, _, unit)
	if unit and unit ~= "player" then
		return
	end

	local element = frame.ManaTimer
	local power = UnitPower("player")
	local maxPower = UnitPowerMax("player")
	local powerType = UnitPowerType("player")

	if IsSecret(power) or IsSecret(maxPower) or IsSecret(powerType) then
		element.LastPower = nil
		element:Hide()
		element:SetScript("OnUpdate", nil)
		return
	end

	if powerType ~= Enum.PowerType.Mana or power == maxPower then
		element.LastPower = power
		element:Hide()
		element:SetScript("OnUpdate", nil)

		return
	end

	if element.LastPower == nil or IsSecret(element.LastPower) then
		element.LastPower = power
		return
	end

	if element.LastPower > power then
		element.max = 5.5
	elseif power > element.LastPower then
		element.max = 2
	else
		return
	end

	element.elapsed = 0
	element:SetMinMaxValues(0, element.max)
	element:Show()
	element:SetScript("OnUpdate", ManaOnUpdate)
	element.LastPower = power
end

local function EnableMana(frame)
	local element = frame.ManaTimer

	if YxUI.IsMists or (YxUI.IsMainline and not YxUI.IsForever) or not Settings["unitframes-show-mana-timer"] or not element or not UnitIsUnit(frame.unit, "player") then
		return
	end

	element.__owner = frame
	local power = UnitPower("player")
	element.LastPower = not IsSecret(power) and power or nil
	element.ForceUpdate = function()
		UpdateMana(frame, "ForceUpdate", "player")
	end

	frame:RegisterEvent("UNIT_POWER_FREQUENT", UpdateMana)
	element:Hide()

	return true
end

local function DisableMana(frame)
	frame:UnregisterEvent("UNIT_POWER_FREQUENT", UpdateMana)
	frame.ManaTimer:Hide()
	frame.ManaTimer:SetScript("OnUpdate", nil)
end

UF:RegisterElement("ManaRegen", {
	update = UpdateMana,
	enable = EnableMana,
	disable = DisableMana,
})

local lastEnergyTick = GetTime()
local lastEnergy = nil

local function EnergyOnUpdate(element)
	local power = UnitPower("player")

	if IsSecret(power) then
		lastEnergy = nil
		if not element.SecretPower then
			element:SetAlpha(0)
			element.SecretPower = true
		end
		return
	end

	if element.SecretPower then
		element:SetAlpha(1)
		element.SecretPower = nil
	end

	local currentTime = GetTime()

	if lastEnergy == nil or power > lastEnergy or currentTime - lastEnergyTick >= 2 then
		lastEnergyTick = currentTime
	end

	element:SetValue(currentTime - lastEnergyTick)
	lastEnergy = power
end

local function UpdateEnergy(frame)
	EnergyOnUpdate(frame.EnergyTick)
end

local function EnableEnergy(frame)
	local element = frame.EnergyTick

	if not Settings["unitframes-show-energy-timer"] or not (YxUI.IsVanilla or YxUI.IsTBC) or not element or not UnitIsUnit(frame.unit, "player") then
		return
	end

	local class = select(2, UnitClass("player"))

	if class ~= "ROGUE" and class ~= "DRUID" then
		return
	end

	element.__owner = frame
	element.ForceUpdate = function()
		EnergyOnUpdate(element)
	end
	element:SetMinMaxValues(0, 2)
	element:SetScript("OnUpdate", EnergyOnUpdate)
	element:Show()

	return true
end

local function DisableEnergy(frame)
	frame.EnergyTick:Hide()
	frame.EnergyTick:SetScript("OnUpdate", nil)
	frame.EnergyTick:SetAlpha(1)
	frame.EnergyTick.SecretPower = nil
	lastEnergy = nil
end

UF:RegisterElement("EnergyTick", {
	update = UpdateEnergy,
	enable = EnableEnergy,
	disable = DisableEnergy,
})

local function FindSpellCost(unit, spellID)
	local costs = C_Spell.GetSpellPowerCost(spellID)

	if not costs or (YxUI.IsForever and IsSecret(costs)) then
		return 0
	end

	local powerType = UnitPowerType(unit)
	if YxUI.IsForever and IsSecret(powerType) then
		return 0
	end

	for _, costInfo in next, costs do
		if not YxUI.IsForever or not (IsSecret(costInfo.type) or IsSecret(costInfo.cost) or IsSecret(costInfo.hasRequiredAura)) then
			if costInfo.type == powerType and (#costs == 1 or costInfo.hasRequiredAura) then
				return costInfo.cost
			end
		end
	end

	return 0
end

local function UpdatePredictionRange(frame, element, event)
	local refreshRange = not element._rangeReady or element._rangeUnit ~= frame.unit
		or event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" or event == "ForceUpdate"
		or event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED"

	if refreshRange then
		local maximum = UnitPowerMax(frame.unit)
		if IsSecret(maximum) then
			element._rangeReady = nil
			element._rangeMaximum = nil
			if YxUI.IsForever then
				return false
			end
			element.mainBar:SetMinMaxValues(0, maximum)
			return true
		end

		if not element._rangeReady or element._rangeUnit ~= frame.unit or element._rangeMaximum ~= maximum then
			element.mainBar:SetMinMaxValues(0, maximum)
		end

		element._rangeUnit = frame.unit
		element._rangeMaximum = maximum
		element._rangeReady = true
	end

	return true
end

local function UpdatePrediction(frame, event, unit)
	if unit and unit ~= frame.unit then
		return
	end

	local element = frame.PowerPrediction
	local _, _, _, startTime, endTime, _, _, _, spellID = UnitCastingInfo(frame.unit)
	local cost = 0

	if YxUI.IsForever and (IsSecret(startTime) or IsSecret(endTime) or IsSecret(spellID)) then
		element.mainCost = 0
		element.mainBar:Hide()
		return
	end

	if event == "UNIT_SPELLCAST_START" and startTime ~= endTime and spellID then
		cost = FindSpellCost(frame.unit, spellID)
		element.mainCost = cost
	elseif spellID then
		cost = element.mainCost or 0
	else
		element.mainCost = 0
	end

	if element.mainBar then
		if (YxUI.IsForever and IsSecret(cost)) or not UpdatePredictionRange(frame, element, event) then
			element.mainCost = 0
			element.mainBar:Hide()
			return
		end

		element.mainBar:SetValue(cost)
		element.mainBar:SetShown(cost > 0)
	end
end

local PredictionEvents = {
	"UNIT_DISPLAYPOWER",
	"UNIT_MAXPOWER",
	"PLAYER_REGEN_DISABLED",
	"PLAYER_REGEN_ENABLED",
	"UNIT_SPELLCAST_FAILED",
	"UNIT_SPELLCAST_START",
	"UNIT_SPELLCAST_STOP",
	"UNIT_SPELLCAST_SUCCEEDED",
}

local function EnablePrediction(frame, unit)
	local element = frame.PowerPrediction

	if not element or not C_Spell or not UnitIsUnit(unit, "player") then
		return
	end

	element.__owner = frame
	element._rangeReady = nil
	element._rangeUnit = nil
	element._rangeMaximum = nil
	element.ForceUpdate = function()
		UpdatePrediction(frame, "ForceUpdate", frame.unit)
	end

	for i = 1, #PredictionEvents do
		frame:RegisterEvent(PredictionEvents[i], UpdatePrediction)
	end

	return true
end

local function DisablePrediction(frame)
	local element = frame.PowerPrediction
	element._rangeReady = nil
	element._rangeUnit = nil
	element._rangeMaximum = nil
	for i = 1, #PredictionEvents do
		frame:UnregisterEvent(PredictionEvents[i], UpdatePrediction)
	end

	if frame.PowerPrediction.mainBar then
		frame.PowerPrediction.mainBar:Hide()
	end
end

UF:RegisterElement("PowerPrediction", {
	update = UpdatePrediction,
	enable = EnablePrediction,
	disable = DisablePrediction,
})
