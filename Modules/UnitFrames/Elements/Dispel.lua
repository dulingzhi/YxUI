local _, ns = ...
local YxUI = ns:get()
local UF = YxUI:GetModule("Unit Frames")
local PlayerClass = select(2, UnitClass("player"))

local DispelTypesByClass = {
	DRUID = {Poison = true, Curse = true},
	MONK = {Magic = false, Poison = true, Disease = true},
	PALADIN = {Magic = true, Poison = true, Disease = true},
	PRIEST = {Magic = true, Disease = true},
	SHAMAN = {Poison = true, Disease = true},
}
local DispelPriority = {Magic = 4, Curse = 3, Disease = 2, Poison = 1}
local ValidDispelTypes = DispelTypesByClass[PlayerClass]

local function IsInaccessible(value)
	return YxUI.IsMainline and issecretvalue(value) and not canaccessvalue(value)
end

local function ShowDispel(element, bestIcon, bestCount, bestType, bestDuration, bestExpiration, bestSpellID)
	if not bestType then
		element.SpellID = nil
		element:Hide()
		return
	end

	element.SpellID = IsInaccessible(bestSpellID) and nil or bestSpellID
	element.icon:SetTexture(IsInaccessible(bestIcon) and nil or bestIcon)
	if not IsInaccessible(bestDuration) and not IsInaccessible(bestExpiration) and bestDuration and bestDuration > 0 and bestExpiration then
		element.cd:SetCooldown(bestExpiration - bestDuration, bestDuration)
		element.cd:SetDrawEdge(false)
		element.cd:Show()
	else
		element.cd:Hide()
	end
	if IsInaccessible(bestCount) then
		element.count:SetText("")
	else
		element.count:SetText(bestCount and bestCount > 1 and bestCount or "")
	end
	local color = YxUI.DebuffColors[bestType] or YxUI.DebuffColors.none
	element:SetBackdropBorderColor(unpack(color))
	element:Show()
end

local function UpdateGroupAuraIndicators(frame, _, unit)
	if unit and unit ~= frame.unit then
		return
	end

	local watch = frame:IsElementEnabled("AuraWatch") and frame.AuraWatch
	local dispel = frame:IsElementEnabled("Dispel") and frame.Dispel
	if not watch and not dispel then
		return
	end

	if watch then
		UF.ClearAuraWatch(watch)
		UF.EnumerateAuras(frame.unit, "HELPFUL", function(_, name, icon, count, debuffType, duration, expiration, caster, stealable, spellID)
			UF.RecordAuraWatch(watch, spellID, count, duration, expiration, caster)
		end)
	end

	local bestPriority, bestIcon, bestCount, bestType, bestDuration, bestExpiration, bestSpellID
	UF.EnumerateAuras(frame.unit, "HARMFUL", function(_, name, icon, count, debuffType, duration, expiration, caster, stealable, spellID)
		if watch then
			UF.RecordAuraWatch(watch, spellID, count, duration, expiration, caster)
		end
		if dispel and not IsInaccessible(debuffType) then
			local priority = debuffType and ValidDispelTypes and ValidDispelTypes[debuffType] and DispelPriority[debuffType]
			if priority and (not bestPriority or priority > bestPriority) then
				bestPriority, bestIcon, bestCount, bestType = priority, icon, count, debuffType
				bestDuration, bestExpiration, bestSpellID = duration, expiration, spellID
			end
		end
	end)
	if dispel then
		ShowDispel(dispel, bestIcon, bestCount, bestType, bestDuration, bestExpiration, bestSpellID)
	end
end

UF.UpdateGroupAuraIndicators = UpdateGroupAuraIndicators

local function EnableDispel(frame)
	local element = frame.Dispel

	if not element or not ValidDispelTypes then
		if element then
			element:Hide()
		end

		return
	end

	element.__owner = frame
	element.ForceUpdate = function()
		UpdateGroupAuraIndicators(frame, "ForceUpdate", frame.unit)
	end
	frame:RegisterEvent("UNIT_AURA", UpdateGroupAuraIndicators)
	element:Hide()

	return true
end

local function DisableDispel(frame)
	if not frame:IsElementEnabled("AuraWatch") then
		frame:UnregisterEvent("UNIT_AURA", UpdateGroupAuraIndicators)
	end
	frame.Dispel:Hide()
end

UF:RegisterElement("Dispel", {
	update = UpdateGroupAuraIndicators,
	enable = EnableDispel,
	disable = DisableDispel,
})
