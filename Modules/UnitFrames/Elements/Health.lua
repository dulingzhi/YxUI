local _, ns = ...
local YxUI = ns:get()
local UF = YxUI:GetModule("Unit Frames")

local HealthValueEvents = {YxUI.IsMainline and "UNIT_HEALTH" or "UNIT_HEALTH_FREQUENT", "UNIT_MAXHEALTH"}
local HealthStateEvents = {"UNIT_CONNECTION", "UNIT_FLAGS", "PARTY_MEMBER_ENABLE", "PARTY_MEMBER_DISABLE"}
local HealthStateEventLookup = {UNIT_CONNECTION = true, UNIT_FLAGS = true, PARTY_MEMBER_ENABLE = true, PARTY_MEMBER_DISABLE = true}
local HealthColorEvents = {"UNIT_CONNECTION", "PARTY_MEMBER_ENABLE", "PARTY_MEMBER_DISABLE", "UNIT_FACTION", "UNIT_FLAGS", "UNIT_NAME_UPDATE", "UNIT_TARGETABLE_CHANGED", "UNIT_THREAT_LIST_UPDATE", "UNIT_THREAT_SITUATION_UPDATE"}

local function Run(element, fallback, frame, ...)
	return (element.Override or fallback)(frame, ...)
end

local function Unregister(frame, handler, ...)
	for i = 1, select("#", ...) do
		frame:UnregisterEvent(select(i, ...), handler)
	end
end

local function HealthColor(frame, event, unit)
	if unit ~= frame.unit then
		return
	end

	local element, color = frame.Health
	local r, g, b

	if element.colorDisconnected and not UnitIsConnected(unit) then
		color = frame.colors.disconnected
	elseif element.colorTapping and not UnitPlayerControlled(unit) and UnitIsTapDenied(unit) then
		color = frame.colors.tapped
	elseif element.colorThreat and not UnitPlayerControlled(unit) then
		local threat = UnitThreatSituation("player", unit)
		color = (threat and frame.colors.threat[threat]) or frame.colors.reaction[UnitReaction(unit, "player") or 5]
	elseif element.colorClass and UnitIsPlayer(unit) then
		local _, class = UnitClass(unit)
		color = frame.colors.class[class]
	elseif element.colorSelection and UnitSelectionColor then
		r, g, b = UnitSelectionColor(unit)
	elseif element.colorReaction then
		color = frame.colors.reaction[UnitReaction(unit, "player") or 5]
	elseif element.colorHealth then
		color = frame.colors.health
	end

	if color then
		r, g, b = color[1], color[2], color[3]
	end

	if b then
		element:SetStatusBarColor(r, g, b)

		if element.bg then
			local m = element.bg.multiplier or 1
			element.bg:SetVertexColor(r*m, g*m, b*m)
		end
	end

	if element.PostUpdateColor then
		element:PostUpdateColor(unit, r, g, b)
	end
end

local function UpdateHealth(frame, event, unit)
	if unit ~= frame.unit then
		return
	end

	local bar = frame.Health
	local isValueEvent = event == "UNIT_HEALTH" or event == "UNIT_HEALTH_FREQUENT"
	local unitChanged = bar._healthStateUnit ~= unit
	local refreshRange = not bar._healthStateReady or unitChanged or not (isValueEvent or HealthStateEventLookup[event])
	local refreshConnection = not bar._healthStateReady or unitChanged or not isValueEvent
	local maximum = refreshRange and UnitHealthMax(unit) or bar.max

	if refreshConnection then
		bar._healthConnected = UnitIsConnected(unit)
	end

	local current = UnitHealth(unit)

	if bar.PreUpdate then
		bar:PreUpdate(unit)
	end

	if refreshRange then
		bar:SetMinMaxValues(0, maximum)
	end

	local value = bar._healthConnected and current or maximum

	-- Initialize newly shown/reassigned frames before animating normal health changes.
	local immediate = event == "UNIT_MAXHEALTH" or event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED"
		or event == "RefreshUnit" or event == "OnShow" or event == "OnAttributeChanged" or event == "PollIdentityChanged"

	if bar.SetValueImmediately and immediate then
		bar:SetValue(value, true)
	else
		bar:SetValue(value)
	end

	bar.cur, bar.max = current, maximum
	bar._healthStateUnit = unit
	bar._healthStateReady = true

	local inaccessible = YxUI.IsMainline and issecretvalue(current) and not canaccessvalue(current)

	if not inaccessible and current == 0 then
		if frame.HealBar then
			frame.HealBar:SetValue(0)
		end

		if frame.AbsorbsBar then
			frame.AbsorbsBar:SetValue(0)
		end
	end

	if bar.PostUpdate then
		bar:PostUpdate(unit, current, maximum)
	end
end

local function HealthValuePath(frame, event, unit, ...)
	Run(frame.Health, UpdateHealth, frame, event, unit, ...)
end

local function UpdateHealthColor(frame, event, unit)
	local bar = frame.Health
	return (bar.UpdateColor or HealthColor)(frame, event, unit)
end

local function HealthPath(frame, event, unit, ...)
	HealthValuePath(frame, event, unit, ...)
	UpdateHealthColor(frame, event, unit)
end

local function EnableHealth(frame)
	local bar = frame.Health

	if not bar then
		return
	end

	bar.__owner, bar.ForceUpdate = frame, UF:CreateForceUpdate(bar, HealthPath)
	bar._healthStateReady = nil
	bar._healthStateUnit = nil
	bar._healthConnected = nil

	for _, event in ipairs(HealthValueEvents) do
		frame:RegisterEvent(event, HealthValuePath)
	end

	for _, event in ipairs(HealthStateEvents) do
		frame:RegisterEvent(event, HealthValuePath)
	end

	for _, event in ipairs(HealthColorEvents) do
		frame:RegisterEvent(event, UpdateHealthColor)
	end

	bar:Show()

	return true
end

local function DisableHealth(frame)
	frame.Health:Hide()
	frame.Health._healthStateReady = nil
	frame.Health._healthStateUnit = nil
	frame.Health._healthConnected = nil
	Unregister(frame, HealthValuePath, "UNIT_HEALTH", "UNIT_HEALTH_FREQUENT", "UNIT_MAXHEALTH")
	for _, event in ipairs(HealthStateEvents) do
		frame:UnregisterEvent(event, HealthValuePath)
	end
	for _, event in ipairs(HealthColorEvents) do
		frame:UnregisterEvent(event, UpdateHealthColor)
	end
end

UF:RegisterElement("Health", {
	update = HealthPath,
	enable = EnableHealth,
	disable = DisableHealth,
})
