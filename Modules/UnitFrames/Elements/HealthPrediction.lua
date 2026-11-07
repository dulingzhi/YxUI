local _, ns = ...
local YxUI = ns:get()
local UF = YxUI:GetModule("Unit Frames")

local HealComm = YxUI.IsVanilla and LibStub and LibStub("LibHealComm-4.0", true)
local PredictionEvents = HealComm and {
	"UNIT_HEALTH_FREQUENT",
	"UNIT_MAXHEALTH",
} or {
	"UNIT_HEAL_PREDICTION",
	"UNIT_MAXHEALTH",
	"UNIT_HEALTH",
	"UNIT_ABSORB_AMOUNT_CHANGED",
	"UNIT_HEAL_ABSORB_AMOUNT_CHANGED",
}

local function IsInaccessible(value)
	return YxUI.IsMainline and issecretvalue(value) and not canaccessvalue(value)
end

local function GetIncomingHeals(unit)
	if HealComm then
		local guid = UnitGUID(unit)

		if not guid then
			return 0
		end

		return (HealComm:GetHealAmount(guid, HealComm.ALL_HEALS) or 0) * (HealComm:GetHealModifier(guid) or 1)
	end

	return UnitGetIncomingHeals and (UnitGetIncomingHeals(unit) or 0) or 0
end

local PredictionValueEvents = {
	UNIT_HEALTH = true,
	UNIT_HEALTH_FREQUENT = true,
	UNIT_HEAL_PREDICTION = true,
	UNIT_ABSORB_AMOUNT_CHANGED = true,
	UNIT_HEAL_ABSORB_AMOUNT_CHANGED = true,
	HealComm = true,
}

local function UpdatePrediction(frame, event, unit)
	if not frame.unit or unit and unit ~= frame.unit then
		return
	end

	local updateRange = not frame._predictionRangeReady or frame._predictionUnit ~= frame.unit or not PredictionValueEvents[event]
	local maximum = updateRange and UnitHealthMax(frame.unit) or frame._predictionMaximum

	-- Secret maximums can become accessible again; do not retain stale protected values.
	if not updateRange and IsInaccessible(maximum) then
		maximum = UnitHealthMax(frame.unit)
		if not IsInaccessible(maximum) then
			updateRange = true
		end
	end

	if updateRange then
		frame.HealBar:SetMinMaxValues(0, maximum)
		if frame.AbsorbsBar then
			frame.AbsorbsBar:SetMinMaxValues(0, maximum)
		end
		frame._predictionMaximum = maximum
		frame._predictionUnit = frame.unit
		frame._predictionRangeReady = true
	end

	local updateHeals = updateRange or event ~= "UNIT_ABSORB_AMOUNT_CHANGED"
	local updateAbsorbs = updateRange or (event ~= "UNIT_HEAL_PREDICTION" and event ~= "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" and event ~= "HealComm")
	local health = UnitHealth(frame.unit)
	local inaccessible = IsInaccessible(health) or IsInaccessible(maximum)

	if updateHeals then
		local incoming = GetIncomingHeals(frame.unit)
		frame.HealBar:SetValue(not inaccessible and not IsInaccessible(incoming) and health > 0 and math.min(incoming, maximum - health) or 0)
	end

	if updateAbsorbs and frame.AbsorbsBar then
		local absorbs = UnitGetTotalAbsorbs(frame.unit) or 0
		frame.AbsorbsBar:SetValue(not inaccessible and not IsInaccessible(absorbs) and health > 0 and math.min(absorbs, maximum - health) or 0)
	end
end

local function UpdateHealCommUnit(frame, ...)
	-- Detached nameplates still receive the library's global callbacks.
	if not frame.unit then
		return
	end

	local guid = UnitGUID(frame.unit)

	if not guid then
		return
	end

	for i = 1, select("#", ...) do
		if select(i, ...) == guid then
			UpdatePrediction(frame, "HealComm", frame.unit)
			return
		end
	end
end

local function HealUpdated(frame, _, _, _, _, _, ...)
	UpdateHealCommUnit(frame, ...)
end

local function HealModifierChanged(frame, _, guid)
	UpdateHealCommUnit(frame, guid)
end

local function EnablePrediction(frame)
	local heal = frame.HealBar

	if not heal then
		return
	end

	heal.__owner = frame
	frame._predictionRangeReady = nil
	heal.ForceUpdate = UF:CreateForceUpdate(heal, UpdatePrediction)

	for _, event in ipairs(PredictionEvents) do
		frame:RegisterEvent(event, UpdatePrediction)
	end

	if HealComm then
		frame:RegisterEvent("PLAYER_TARGET_CHANGED", UpdatePrediction, true)
		HealComm.RegisterCallback(frame, "HealComm_HealStarted", HealUpdated, frame)
		HealComm.RegisterCallback(frame, "HealComm_HealUpdated", HealUpdated, frame)
		HealComm.RegisterCallback(frame, "HealComm_HealDelayed", HealUpdated, frame)
		HealComm.RegisterCallback(frame, "HealComm_HealStopped", HealUpdated, frame)
		HealComm.RegisterCallback(frame, "HealComm_ModifierChanged", HealModifierChanged, frame)
		HealComm.RegisterCallback(frame, "HealComm_GUIDDisappeared", HealModifierChanged, frame)
	end

	heal:SetMinMaxValues(0, 1)
	heal:SetValue(0)
	heal:Show()

	if frame.AbsorbsBar then
		frame.AbsorbsBar:SetMinMaxValues(0, 1)
		frame.AbsorbsBar:SetValue(0)
		frame.AbsorbsBar:Show()
	end

	return true
end

local function DisablePrediction(frame)
	frame._predictionRangeReady = nil
	frame._predictionMaximum = nil
	frame._predictionUnit = nil
	frame.HealBar:Hide()

	if frame.AbsorbsBar then
		frame.AbsorbsBar:Hide()
	end

	for _, event in ipairs(PredictionEvents) do
		frame:UnregisterEvent(event, UpdatePrediction)
	end

	if HealComm then
		frame:UnregisterEvent("PLAYER_TARGET_CHANGED", UpdatePrediction)
		HealComm.UnregisterCallback(frame, "HealComm_HealStarted")
		HealComm.UnregisterCallback(frame, "HealComm_HealUpdated")
		HealComm.UnregisterCallback(frame, "HealComm_HealDelayed")
		HealComm.UnregisterCallback(frame, "HealComm_HealStopped")
		HealComm.UnregisterCallback(frame, "HealComm_ModifierChanged")
		HealComm.UnregisterCallback(frame, "HealComm_GUIDDisappeared")
	end
end

UF:RegisterElement("HealPrediction", {
	update = UpdatePrediction,
	enable = EnablePrediction,
	disable = DisablePrediction,
})
