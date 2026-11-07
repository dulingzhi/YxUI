local _, ns = ...
local YxUI = ns:get()
local UF = YxUI:GetModule("Unit Frames")
local RangeEnabledFrames, RangeFrames, RangeDriver = {}, {}, nil

local function IsInaccessible(value)
	return YxUI.IsMainline and issecretvalue(value) and not canaccessvalue(value)
end

local ForeverRangeYardsSquared = 40 * 40
local AlphaVerifyInterval = 5

local function GetForeverRange(unit)
	if unit == "player" then
		return true, true
	end

	if UnitIsUnit then
		local ok, isPlayer = pcall(UnitIsUnit, unit, "player")
		if ok and not IsInaccessible(isPlayer) and isPlayer == true then
			return true, true
		end
	end

	if UnitInRange then
		local ok, inRange, checked = pcall(UnitInRange, unit)
		if ok and not IsInaccessible(checked) and checked == true
			and (IsInaccessible(inRange) or type(inRange) == "boolean") then
			return inRange, true
		end
	end

	if UnitDistanceSquared then
		local ok, distance, checked = pcall(UnitDistanceSquared, unit)
		if ok and not IsInaccessible(checked) and checked == true
			and not IsInaccessible(distance) and type(distance) == "number" then
			return distance <= ForeverRangeYardsSquared, true
		end
	end

	return nil, false
end

local function ApplyRangeAlpha(frame, range, alpha, forceVerify)
	if range.__lastAlpha ~= alpha then
		frame:SetAlpha(alpha)
		range.__lastAlpha = alpha
		range.__alphaVerifyTicks = 0
		return
	end

	range.__alphaVerifyTicks = (range.__alphaVerifyTicks or 0) + 1
	if forceVerify or range.__alphaVerifyTicks >= AlphaVerifyInterval then
		range.__alphaVerifyTicks = 0
		local currentAlpha = frame:GetAlpha()
		if not IsInaccessible(currentAlpha) and currentAlpha ~= alpha then
			frame:SetAlpha(alpha)
		end
	end
end

local function UpdateRange(frame, forceVerify)
	local range = frame.Range

	if range.PreUpdate then
		range:PreUpdate()
	end

	if range.insideAlpha == range.outsideAlpha and not range.PostUpdate then
		ApplyRangeAlpha(frame, range, range.insideAlpha, forceVerify)
		return
	end

	local connected = UnitIsConnected(frame.unit)

	if IsInaccessible(connected) then
		connected = nil
	end

	local inRange, checked
	local alphaSet

	if connected then
		if YxUI.IsForever then
			inRange, checked = GetForeverRange(frame.unit)
		else
			inRange, checked = UnitInRange(frame.unit)
		end

		if IsInaccessible(inRange) then
			if frame.SetAlphaFromBoolean and not IsInaccessible(checked) and checked then
				frame:SetAlphaFromBoolean(inRange, range.insideAlpha, range.outsideAlpha)
				alphaSet = true
			end

			inRange = nil
			checked = nil
		end

		if IsInaccessible(checked) then
			checked = nil
		end
	end

	local outsideRange = connected and checked and not inRange

	if alphaSet then
		range.__lastAlpha = nil
		range.__alphaVerifyTicks = 0
	else
		local alpha = outsideRange and range.outsideAlpha or range.insideAlpha
		ApplyRangeAlpha(frame, range, alpha, forceVerify)
	end

	if range.PostUpdate then
		range:PostUpdate(frame, inRange, checked, connected)
	end
end

local function RangeOnUpdate(driver, delta)
	driver.Elapsed = driver.Elapsed + delta

	if driver.Elapsed < 0.2 then
		return
	end

	driver.Elapsed = 0

	for frame in pairs(RangeFrames) do
		UpdateRange(frame)
	end
end

local function CreateRangeDriver()
	local driver = CreateFrame("Frame")

	driver.Elapsed = 0

	return driver
end

local function StartRangeDriver()
	RangeDriver = RangeDriver or CreateRangeDriver()

	if not RangeDriver:GetScript("OnUpdate") then
		RangeDriver.Elapsed = 0
		RangeDriver:SetScript("OnUpdate", RangeOnUpdate)
	end
end

local function StopRangeDriver()
	if RangeDriver and not next(RangeFrames) then
		RangeDriver:SetScript("OnUpdate", nil)
		RangeDriver.Elapsed = 0
	end
end

local function RangeOnShow(frame)
	if RangeEnabledFrames[frame] then
		RangeFrames[frame] = true
		StartRangeDriver()
		UpdateRange(frame, true)
	end
end

local function RangeOnHide(frame)
	RangeFrames[frame] = nil
	StopRangeDriver()
end

local function EnableRange(frame)
	local range = frame.Range

	if not range then
		return
	end

	range.__owner = frame
	range.ForceUpdate = function()
		UpdateRange(frame, true)
	end
	range.insideAlpha = range.insideAlpha or 1
	range.outsideAlpha = range.outsideAlpha or 0.55
	range.__lastAlpha = nil
	range.__alphaVerifyTicks = 0
	RangeEnabledFrames[frame] = true

	if not frame.RangeDriverHooks then
		frame:HookScript("OnShow", RangeOnShow)
		frame:HookScript("OnHide", RangeOnHide)
		frame.RangeDriverHooks = true
	end

	if frame:IsVisible() then
		RangeOnShow(frame)
	end

	return true
end

local function DisableRange(frame)
	RangeEnabledFrames[frame] = nil
	RangeFrames[frame] = nil
	frame:SetAlpha(frame.Range.insideAlpha)
	frame.Range.__lastAlpha = nil
	frame.Range.__alphaVerifyTicks = nil
	StopRangeDriver()
end

UF:RegisterElement("Range", {
	update = UpdateRange,
	enable = EnableRange,
	disable = DisableRange,
})
