local _, ns = ...
local YxUI = ns:get()
local UF = YxUI:GetModule("Unit Frames")

local active = {}
local driver = CreateFrame("Frame")
local running = false
local min, max, abs = math.min, math.max, math.abs
local nativeInterpolation = YxUI.IsMainline and Enum and Enum.StatusBarInterpolation

local function IsSecret(value)
	return YxUI.IsMainline and issecretvalue(value) and not canaccessvalue(value)
end

local function StopIfIdle()
	if running and not next(active) then
		driver:SetScript("OnUpdate", nil)
		running = false
	end
end

local function Animate()
	local frameStep = 30 / GetFramerate()
	for bar, target in pairs(active) do
		local current = bar:GetValue()

		if IsSecret(current) or IsSecret(target) then
			bar:SetValueImmediately(target)
			active[bar] = nil
		else
			local difference = target - current
			local value = current + min(difference / 3, max(difference, frameStep))

			if value ~= value then
				value = target
			end

			bar:SetValueImmediately(value)

			if current == target or abs(value - target) < 2 then
				bar:SetValueImmediately(target)
				active[bar] = nil
			end
		end
	end

	StopIfIdle()
end

local function SmoothValue(bar, value, immediate)
	-- Blizzard interpolates secret values without exposing them to Lua.
	if nativeInterpolation then
		local interpolation = (immediate or not bar.__smoothInitialized) and nativeInterpolation.Immediate or nativeInterpolation.ExponentialEaseOut
		bar:SetValueImmediately(value, interpolation)
		bar.__smoothInitialized = true
		return
	end

	local _, maximum = bar:GetMinMaxValues()
	local secretMaximum = IsSecret(maximum)

	-- The first value initializes the bar; only subsequent updates should animate.
	if immediate or IsSecret(value) or secretMaximum or bar.__smoothMaximum ~= maximum then
		bar:SetValueImmediately(value)
		active[bar] = nil
	else
		local current = bar:GetValue()
		if not IsSecret(current) and current == value then
			active[bar] = nil
		else
			active[bar] = value
			if not running then
				driver:SetScript("OnUpdate", Animate)
				running = true
			end
		end
	end

	if secretMaximum then
		bar.__smoothMaximum = nil
	else
		bar.__smoothMaximum = maximum
	end
	StopIfIdle()
end

local function SmoothBar(_, bar)
	if not bar or bar.SetValueImmediately then
		return
	end

	bar.SetValueImmediately = bar.SetValue
	bar.SetValue = SmoothValue
end

local function Enable(frame)
	frame.SmoothBar = SmoothBar

	-- Opt into smoothing unless explicitly disabled
	if frame.Health and frame.Health.Smooth ~= false then
		frame:SmoothBar(frame.Health)
	end

	if frame.Power and frame.Power.Smooth ~= false then
		frame:SmoothBar(frame.Power)
	end

	return frame.Health ~= nil or frame.Power ~= nil
end

local function Restore(bar)
	if bar and bar.SetValueImmediately then
		bar.SetValue = bar.SetValueImmediately
		bar.SetValueImmediately = nil
		bar.__smoothMaximum = nil
		bar.__smoothInitialized = nil
		active[bar] = nil
	end
end

function UF:SetBarSmoothing(bar, enabled)
	if not bar then
		return
	end

	bar.Smooth = enabled
	if enabled then
		SmoothBar(nil, bar)
	else
		Restore(bar)
		StopIfIdle()
	end
end

UF:RegisterElement("Smooth", {
	update = function() end,
	enable = Enable,
	disable = function(frame)
		Restore(frame.Health)
		Restore(frame.Power)

		StopIfIdle()
	end,
})
