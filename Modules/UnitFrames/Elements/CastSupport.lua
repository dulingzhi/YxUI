local addon, ns = ...
local YxUI, _, _, Settings = ns:get()
local UF = YxUI:GetModule("Unit Frames")

local UnitClass = UnitClass
local UnitIsPlayer = UnitIsPlayer
local floor = math.floor

-- Select the spell-info adapter once.  The hot event path is shared by every client and does not repeatedly inspect the project version.
local CastingInfo, ChannelInfo
local NativeCastTimers = YxUI.IsMainline and UnitCastingDuration and UnitChannelDuration
if YxUI.IsMainline then
	CastingInfo = function(unit)
		local name,text,texture,startTime,endTime,isTradeSkill,castID,notInterruptible,spellID,castBarID = UnitCastingInfo(unit)

		return name,text,texture,startTime,endTime,isTradeSkill,castID,notInterruptible,spellID,nil,nil,castBarID
	end

	ChannelInfo = function(unit)
		local name,text,texture,startTime,endTime,isTradeSkill,notInterruptible,spellID,isEmpowered,numStages,castBarID = UnitChannelInfo(unit)

		return name,text,texture,startTime,endTime,isTradeSkill,nil,notInterruptible,spellID,isEmpowered,numStages,castBarID
	end
else
	CastingInfo = UnitCastingInfo
	ChannelInfo = function(unit)
		local name,text,texture,startTime,endTime,isTradeSkill,notInterruptible,spellID,isEmpowered,numStages = UnitChannelInfo(unit)

		return name,text,texture,startTime,endTime,isTradeSkill,nil,notInterruptible,spellID,isEmpowered,numStages
	end
end

local function UpdateCastColor(bar)
	local r, g, b

	if YxUI.IsMainline and issecretvalue and issecretvalue(bar.notInterruptible) then
		local normalR, normalG, normalB = YxUI:HexToRGB(Settings["color-casting-start"])
		local lockedR, lockedG, lockedB = YxUI:HexToRGB(Settings["color-casting-uninterruptible"])
		if C_CurveUtil and C_CurveUtil.EvaluateColorValueFromBoolean then
			r = C_CurveUtil.EvaluateColorValueFromBoolean(bar.notInterruptible, lockedR, normalR)
			g = C_CurveUtil.EvaluateColorValueFromBoolean(bar.notInterruptible, lockedG, normalG)
			b = C_CurveUtil.EvaluateColorValueFromBoolean(bar.notInterruptible, lockedB, normalB)
		else
			r, g, b = normalR, normalG, normalB
		end
	elseif bar.notInterruptible then
		r, g, b = YxUI:HexToRGB(Settings["color-casting-uninterruptible"])
	elseif bar.ClassColor then
		local isPlayer = UnitIsPlayer(bar.__owner.unit)
		if (not issecretvalue or not issecretvalue(isPlayer)) and isPlayer then
			local _, class = UnitClass(bar.__owner.unit)
			local color = (not issecretvalue or not issecretvalue(class)) and class and YxUI.ClassColors[class]
			if color then
				r, g, b = color[1], color[2], color[3]
			end
		end
	end

	if not r then
		r, g, b = YxUI:HexToRGB(Settings["color-casting-start"])
	end

	bar:SetStatusBarColor(r, g, b)
	bar.bg:SetVertexColor(r, g, b)
end

UF.PostCastStart = UpdateCastColor
UF.PostCastInterruptible = UpdateCastColor

UF.PostCastStop = function(self)
	local r, g, b = YxUI:HexToRGB(Settings["color-casting-stopped"])
	self:SetStatusBarColor(r, g, b)
	self.bg:SetVertexColor(r, g, b)
end

UF.PostCastFail = function(self)
	local r, g, b = YxUI:HexToRGB(Settings["color-casting-interrupted"])
	self:SetStatusBarColor(r, g, b)
	self.bg:SetVertexColor(r, g, b)
end

local FALLBACK_ICON = 136243
local FAILED = _G.FAILED or "Failed"
local INTERRUPTED = _G.INTERRUPTED or "Interrupted"
local LibCC = (YxUI.IsVanilla or YxUI.IsTBC) and LibStub and LibStub("LibClassicCasterino", true)

if LibCC then
	CastingInfo = function(unit)
		return LibCC:UnitCastingInfo(unit)
	end
	ChannelInfo = function(unit)
		local name,text,texture,startTime,endTime,isTradeSkill,notInterruptible,spellID = LibCC:UnitChannelInfo(unit)
		return name,text,texture,startTime,endTime,isTradeSkill,nil,notInterruptible,spellID
	end
end

local function UpdateNativeTime(bar, duration)
	if not bar.Time or not C_DurationUtil or not C_DurationUtil.CreateDurationTextBinding then
		return
	end

	local binding = bar.DurationTextBinding
	if not binding then
		binding = C_DurationUtil.CreateDurationTextBinding()
		binding:SetFontString(bar.Time)
		if C_StringUtil and C_StringUtil.CreateSecondsFormatter then
			local formatter = C_StringUtil.CreateSecondsFormatter()
			formatter:SetMillisecondsThreshold(5)
			binding:SetFormatter(formatter)
		end
		bar.DurationTextBinding = binding
	end

	binding:SetDuration(duration)
	binding:SetEnabled(true)
end

local function ResetCast(bar)
	if bar.DurationTextBinding then
		bar.DurationTextBinding:SetEnabled(false)
	end
	bar.castID = nil
	bar.castBarID = nil
	bar.__nativeTimer = nil
	bar.casting = nil
	bar.channeling = nil
	bar.empowering = nil
	bar.notInterruptible = nil
	bar.spellID = nil
	bar.__lastTimeTick = nil
	bar.__lastTimeDelay = nil
	bar.__syncElapsed = nil
end

local function SameCast(bar, castID, spellID, castBarID)
	if not bar:IsShown() then
		return false
	end
	if YxUI.IsMainline then
		if castBarID ~= nil and bar.castBarID ~= nil then
			return bar.castBarID == castBarID
		end
		if castID ~= nil and bar.castID ~= nil and (not issecretvalue or not (issecretvalue(castID) or issecretvalue(bar.castID))) then
			return bar.castID == castID
		end
		return true
	end
	return (not castID or not bar.castID or bar.castID == castID) and (not spellID or not bar.spellID or bar.spellID == spellID)
end

local function FinishCast(bar, failed, unit, spellID)
	if not bar:IsShown() then
		ResetCast(bar)

		return
	end
	if failed then
		if bar.Text then
			bar.Text:SetText(failed == "FAILED" and FAILED or INTERRUPTED)
		end

		if bar.Spark then
			bar.Spark:Hide()
		end

		bar.holdTime = bar.timeToHold or 0
		if not bar.__nativeTimer then
			bar:SetValue(bar.max or 0)
		end
		ResetCast(bar)

		if bar.PostCastFail then
			bar:PostCastFail(unit, spellID)
		end

		if bar.holdTime == 0 then
			bar:Hide()
		end
	else
		ResetCast(bar)
		bar.holdTime = 0

		if bar.PostCastStop then
			bar:PostCastStop(unit, spellID)
		end

		bar:Hide()
	end
end

local SyncNativeCast

local function CastOnUpdate(bar, elapsed)
	if bar.__nativeTimer then
		bar.__syncElapsed = (bar.__syncElapsed or 0) + elapsed
		if bar.__syncElapsed >= 0.3 then
			bar.__syncElapsed = 0
			SyncNativeCast(bar)
		end
		return
	end
	if bar.casting or bar.channeling or bar.empowering then
		local increasing = bar.casting or bar.empowering

		bar.duration = bar.duration + (increasing and elapsed or -elapsed)

		if (increasing and bar.duration >= bar.max) or (bar.channeling and bar.duration <= 0) then
			local spellID = bar.spellID
			ResetCast(bar)
			bar:Hide()

			if bar.PostCastStop then
				bar:PostCastStop(bar.__owner.unit, spellID)
			end

			return
		end
		if bar.Time then
			local tick = floor(bar.duration * 10 + 0.5)
			local delay = bar.delay or 0

			if tick ~= bar.__lastTimeTick or delay ~= bar.__lastTimeDelay then
				bar.__lastTimeTick = tick
				bar.__lastTimeDelay = delay

				if delay ~= 0 then
					bar.Time:SetFormattedText("%.1f|cffff0000%s%.2f|r", bar.duration, increasing and "+" or "-", delay)
				else
					bar.Time:SetFormattedText("%.1f", bar.duration)
				end
			end
		end

		bar:SetValue(bar.duration)
	elseif bar.holdTime and bar.holdTime > 0 then
		bar.holdTime = bar.holdTime - elapsed

		if bar.holdTime <= 0 then
			bar:Hide()
		end
	end
end

local function CastAvailable(name, castBarID)
	if YxUI.IsMainline then
		if issecretvalue and (issecretvalue(name) or issecretvalue(castBarID)) then
			return true
		end
		return name ~= nil or castBarID ~= nil
	end
	return (not issecretvalue or not issecretvalue(name)) and name
end

local function ReadCast(unit)
	local name, text, texture, startMS, endMS, isTradeSkill, castID, notInterruptible, spellID, _, _, castBarID = CastingInfo(unit)

	if CastAvailable(name, castBarID) then
		return name, text, texture, startMS, endMS, isTradeSkill, castID, notInterruptible, spellID, false, false, castBarID
	end

	local numStages

	local castBarID
	name, text, texture, startMS, endMS, isTradeSkill, castID, notInterruptible, spellID, _, numStages, castBarID = ChannelInfo(unit)

	return name, text, texture, startMS, endMS, isTradeSkill, castID, notInterruptible, spellID, true, numStages and (not issecretvalue or not issecretvalue(numStages)) and numStages > 0, castBarID
end

local function StartCast(frame, event, unit)
	if unit ~= frame.unit then
		return
	end

	local bar = frame.Castbar
	local name, text, texture, startMS, endMS, isTradeSkill, castID, notInterruptible, spellID, channel, empower, castBarID = ReadCast(unit)

	local hasCast = CastAvailable(name, castBarID)
	local safeTradeSkill = not issecretvalue or not issecretvalue(isTradeSkill)
	if not hasCast or (safeTradeSkill and isTradeSkill and not bar.showTradeSkills) then
		ResetCast(bar)
		bar:Hide()

		return
	end

	bar.delay, bar.holdTime = 0, 0
	bar.__lastTimeTick, bar.__lastTimeDelay = nil, nil
	bar.castID, bar.castBarID, bar.spellID = castID, castBarID, spellID
	bar.notInterruptible = notInterruptible
	bar.casting, bar.channeling, bar.empowering = not channel, channel and not empower, empower
	bar.__nativeTimer = nil

	local protectedTimes = YxUI.IsMainline and issecretvalue and (issecretvalue(startMS) or issecretvalue(endMS))
	if bar.DurationTextBinding then
		bar.DurationTextBinding:SetEnabled(false)
	end
	if protectedTimes and not (NativeCastTimers and bar.SetTimerDuration) then
		ResetCast(bar)
		bar:Hide()
		return
	end

	local nativeDuration
	if protectedTimes then
		local duration = channel and (empower and UnitEmpoweredChannelDuration and UnitEmpoweredChannelDuration(unit) or UnitChannelDuration(unit)) or UnitCastingDuration(unit)
		if not duration then
			ResetCast(bar)
			bar:Hide()
			return
		end

		bar.__nativeTimer = true
		nativeDuration = duration
		bar:SetTimerDuration(duration, nil, channel and Enum.StatusBarTimerDirection.RemainingTime or Enum.StatusBarTimerDirection.ElapsedTime)
	else
		if empower and GetUnitEmpowerHoldAtMaxTime then
			endMS = endMS + GetUnitEmpowerHoldAtMaxTime(unit)
		end

		bar.startTime, bar.endTime = startMS / 1000, endMS / 1000
		bar.max = bar.endTime - bar.startTime
		bar.duration = bar.channeling and (bar.endTime - GetTime()) or (GetTime() - bar.startTime)
		bar:SetMinMaxValues(0, bar.max)
		bar:SetValue(bar.duration)
	end

	if bar.Text then
		local castText = name
		if (not issecretvalue or not issecretvalue(text)) and text and text ~= "" then
			castText = text
		end
		if YxUI.IsForever and not issecretvalue(spellID) and spellID == 22810 and type(castText) == "string" and not issecretvalue(castText) then
			castText = castText:match("^(.-) %- ") or castText
		end
		bar.Text:SetText(castText)
	end

	if bar.Time then
		bar.Time:SetText("")
		if nativeDuration then
			UpdateNativeTime(bar, nativeDuration)
		end
	end

	if bar.Icon then
		if YxUI.IsMainline then
			bar.Icon:SetTexture(texture)
		else
			bar.Icon:SetTexture(texture or FALLBACK_ICON)
		end
	end

	if bar.Shield then
		if YxUI.IsMainline and issecretvalue and issecretvalue(notInterruptible) then
			if bar.Shield.SetAlphaFromBoolean then
				bar.Shield:Show()
				bar.Shield:SetAlphaFromBoolean(notInterruptible, 1, 0)
			else
				bar.Shield:Hide()
			end
		else
			bar.Shield:SetShown(notInterruptible)
		end
	end

	if bar.Spark then
		bar.Spark:Show()
	end

	bar:Show()

	if bar.SafeZone and unit == "player" and not bar.__nativeTimer and bar.max > 0 then
		local horizontal = bar:GetOrientation() == "HORIZONTAL"
		local ratio = math.min(1, (select(4, GetNetStats()) / 1000) / bar.max)

		bar.SafeZone:ClearAllPoints()
		bar.SafeZone:SetPoint(horizontal and "TOP" or "LEFT")
		bar.SafeZone:SetPoint(horizontal and "BOTTOM" or "RIGHT")

		local reverse = bar:GetReverseFill()

		if bar.channeling then
			bar.SafeZone:SetPoint(reverse and (horizontal and "RIGHT" or "TOP") or (horizontal and "LEFT" or "BOTTOM"))
		else
			bar.SafeZone:SetPoint(reverse and (horizontal and "LEFT" or "BOTTOM") or (horizontal and "RIGHT" or "TOP"))
		end

		local setSize = horizontal and bar.SafeZone.SetWidth or bar.SafeZone.SetHeight
		local getSize = horizontal and bar.GetWidth or bar.GetHeight
		setSize(bar.SafeZone, getSize(bar) * ratio)
	end

	if bar.PostCastStart then
		bar:PostCastStart(unit)
	end
end

local function UpdateCast(frame, event, unit, castID, spellID, castBarID)
	if unit ~= frame.unit or not SameCast(frame.Castbar, castID, spellID, castBarID) then
		return
	end

	local bar = frame.Castbar
	if bar.__nativeTimer then
		local duration = bar.channeling and UnitChannelDuration(unit) or bar.empowering and UnitEmpoweredChannelDuration and UnitEmpoweredChannelDuration(unit) or UnitCastingDuration(unit)
		if duration then
			bar:SetTimerDuration(duration, nil, (bar.channeling or bar.empowering) and Enum.StatusBarTimerDirection.RemainingTime or Enum.StatusBarTimerDirection.ElapsedTime)
			UpdateNativeTime(bar, duration)
		end
		return
	end

	local name, _, _, startMS, endMS

	if event == "UNIT_SPELLCAST_DELAYED" then
		name, _, _, startMS, endMS = CastingInfo(unit)
	else
		name, _, _, startMS, endMS = ChannelInfo(unit)
	end

	if not CastAvailable(name) then
		return
	end

	if bar.empowering and GetUnitEmpowerHoldAtMaxTime then
		endMS = endMS + GetUnitEmpowerHoldAtMaxTime(unit)
	end

	local startTime, endTime = startMS / 1000, endMS / 1000
	local delta

	if bar.channeling then
		delta = bar.startTime - startTime
		bar.duration = endTime - GetTime()
	else
		delta = startTime - bar.startTime
		bar.duration = GetTime() - startTime
	end

	bar.delay = (bar.delay or 0) + math.max(0, delta)
	bar.startTime, bar.endTime, bar.max = startTime, endTime, endTime - startTime
	bar:SetMinMaxValues(0, bar.max)
	bar:SetValue(bar.duration)

	if bar.PostCastUpdate then
		bar:PostCastUpdate(unit)
	end
end

SyncNativeCast = function(bar)
	local unit = bar.__owner.unit
	if not unit then
		FinishCast(bar, nil, unit)
		return
	end

	local name, _, _, _, _, _, _, _, _, channel, empower, castBarID = ReadCast(unit)
	if not CastAvailable(name, castBarID) then
		FinishCast(bar, nil, unit)
	elseif castBarID ~= nil and bar.castBarID ~= nil and castBarID ~= bar.castBarID then
		StartCast(bar.__owner, "NativeCastChanged", unit)
	elseif channel ~= (bar.channeling or bar.empowering) or (empower and true or false) ~= (bar.empowering or false) then
		StartCast(bar.__owner, "NativeCastModeChanged", unit)
	end
end

local function StopCast(frame, event, unit, castID, spellID, eventDetail, extra, finalCastBarID)
	local bar = frame.Castbar
	local castBarID = eventDetail

	if YxUI.IsMainline then
		if event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_INTERRUPTED" then
			castBarID = extra
		elseif event == "UNIT_SPELLCAST_EMPOWER_STOP" then
			castBarID = finalCastBarID
		end
	end
	if unit ~= frame.unit or not SameCast(bar, castID, spellID, castBarID) then
		return
	end

	local failed = event == "UNIT_SPELLCAST_FAILED" and "FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" and "INTERRUPTED"

	FinishCast(bar, failed, unit, spellID)
end

local function Interruptible(frame, event, unit)
	local bar = frame.Castbar

	if unit ~= frame.unit or not bar:IsShown() then
		return
	end

	bar.notInterruptible = event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE"

	if bar.Shield then
		bar.Shield:SetShown(bar.notInterruptible)
	end

	if bar.PostCastInterruptible then
		bar:PostCastInterruptible(unit)
	end
end

local CastEvents = {
	UNIT_SPELLCAST_START = StartCast,
	UNIT_SPELLCAST_CHANNEL_START = StartCast,
	UNIT_SPELLCAST_DELAYED = UpdateCast,
	UNIT_SPELLCAST_CHANNEL_UPDATE = UpdateCast,
	UNIT_SPELLCAST_STOP = StopCast,
	UNIT_SPELLCAST_CHANNEL_STOP = StopCast,
	UNIT_SPELLCAST_FAILED = StopCast,
	UNIT_SPELLCAST_INTERRUPTED = StopCast,
	UNIT_SPELLCAST_INTERRUPTIBLE = Interruptible,
	UNIT_SPELLCAST_NOT_INTERRUPTIBLE = Interruptible,
}

if YxUI.IsMainline then
	CastEvents.UNIT_SPELLCAST_EMPOWER_START = StartCast
	CastEvents.UNIT_SPELLCAST_EMPOWER_UPDATE = UpdateCast
	CastEvents.UNIT_SPELLCAST_EMPOWER_STOP = StopCast
end

local function EnableCast(frame)
	local bar = frame.Castbar

	if not bar then
		return
	end

	bar.__owner = frame
	bar.ForceUpdate = function()
		StartCast(frame, "ForceUpdate", frame.unit)
	end
	bar.ForceClear = function()
		ResetCast(bar)
		bar.holdTime = 0
		bar:Hide()
	end
	bar:HookScript("OnHide", function()
		ResetCast(bar)
	end)

	bar:SetScript("OnUpdate", bar.OnUpdate or CastOnUpdate)

	bar:Hide()

	if LibCC then
		bar.__classicCallback = function(event, ...)
			local handler = CastEvents[event]

			if handler then
				handler(frame, event, ...)
			end
		end

		for event in pairs(CastEvents) do
			LibCC.RegisterCallback(frame, event, bar.__classicCallback)
		end
	else
		for event, handler in pairs(CastEvents) do
			frame:RegisterEvent(event, handler)
		end
	end
	if frame.unit == "player" and not frame.isNamePlate then
		if CastingBarFrame_SetUnit then
			CastingBarFrame_SetUnit(CastingBarFrame,nil)
			CastingBarFrame_SetUnit(PetCastingBarFrame, nil)
		elseif PlayerCastingBarFrame then
			PlayerCastingBarFrame:SetUnit(nil)

			if PetCastingBarFrame then
				PetCastingBarFrame:SetUnit(nil)
			end
		end
	end

	return true
end

local function DisableCast(frame)
	local bar = frame.Castbar

	ResetCast(bar)
	bar:SetScript("OnUpdate", nil)
	bar:Hide()

	if LibCC then
		for event in pairs(CastEvents) do
			LibCC.UnregisterCallback(frame,event)
		end
	else
		for event, handler in pairs(CastEvents) do
			frame:UnregisterEvent(event, handler)
		end
	end
end

UF:RegisterElement("Castbar", {
	update = function(frame, event)
		if event == "OnShow" or event == "NamePlateShown" or event == "NAME_PLATE_UNIT_ADDED"
			or event == "RefreshUnit" or event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED"
			or event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" or event == "PollIdentityChanged"
			or event == "OnAttributeChanged" then
			StartCast(frame, event, frame.unit)
		end
	end,
	enable = EnableCast,
	disable = DisableCast,
})
