local _, ns = ...
local YxUI = ns:get()
local UF = YxUI:GetModule("Unit Frames")

local function SetMissing(watch, icon)
	if icon.onlyShowPresent then
		icon:Hide()
		return
	end

	if icon.cd then
		icon.cd:Hide()
	end

	if icon.count then
		icon.count:SetText("")
	end

	icon:SetAlpha(watch.missingAlpha or .75)
	icon:Show()
end

local function SetPresent(watch, icon, count, duration, expiration)
	if icon.onlyShowMissing then
		icon:Hide()

		return
	end

	if icon.cd then
		if duration and duration > 0 and expiration then
			icon.cd:SetCooldown(expiration - duration, duration)
			icon.cd:Show()
		else
			icon.cd:Hide()
		end
	end

	if icon.count then
		icon.count:SetText(count and count > 1 and count or "")
	end

	icon:SetAlpha(watch.presentAlpha or 1)
	icon:Show()
end

local function IsInaccessible(value)
	return YxUI.IsMainline and issecretvalue(value) and not canaccessvalue(value)
end

function UF.ClearAuraWatch(watch)
	for _, icon in pairs(watch.icons) do
		SetMissing(watch, icon)
	end
end

function UF.RecordAuraWatch(watch, spellID, count, duration, expiration, caster)
	if IsInaccessible(spellID) then
		return
	end
	local icon = spellID and watch.icons[spellID]
	if not icon then
		return
	end
	if not icon.anyUnit and (IsInaccessible(caster) or (caster ~= "player" and caster ~= "vehicle" and caster ~= "pet")) then
		return
	end
	if IsInaccessible(count) then count = nil end
	if IsInaccessible(duration) then duration = nil end
	if IsInaccessible(expiration) then expiration = nil end
	SetPresent(watch, icon, count, duration, expiration)
end

local function Update(frame, event, unit)
	if not frame:IsElementEnabled("Dispel") then
		UF.UpdateGroupAuraIndicators(frame, event, unit)
	end
end

local function Enable(frame)
	local watch = frame.AuraWatch

	if not watch then
		return
	end

	watch.__owner = frame
	watch.ForceUpdate = function()
		UF.UpdateGroupAuraIndicators(frame, "ForceUpdate", frame.unit)
	end

	frame:RegisterEvent("UNIT_AURA", UF.UpdateGroupAuraIndicators)

	return true
end

local function Disable(frame)
	if not frame:IsElementEnabled("Dispel") then
		frame:UnregisterEvent("UNIT_AURA", UF.UpdateGroupAuraIndicators)
	end
	frame.AuraWatch:Hide()
end

UF:RegisterElement("AuraWatch", {update=Update, enable=Enable, disable=Disable})
