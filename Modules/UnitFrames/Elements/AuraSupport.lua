local addon, ns = ...
local YxUI, _, _, Settings = ns:get()

local UF = YxUI:GetModule("Unit Frames")
local Hider = assert(UF.Hider, "unit-frame core must create the hider")
local AuraButtons = setmetatable({}, {__mode = "k"})

local function IsInaccessible(value)
	return YxUI.IsMainline and issecretvalue and issecretvalue(value) and not (canaccessvalue and canaccessvalue(value))
end

local UnregisterAuraTimer = function(button)
	YxUI.DurationText:Unregister(button)
	button.__auraTimerExpiration = nil
	button.LastAuraTime = nil

	if button.Time then
		button.Time:Hide()
	end
end

local function GetAuraRemaining(button, now)
	return button.Expiration and (button.Expiration - now)
end

local function FormatAuraRemaining(remaining)
	return YxUI:AuraFormatTime(remaining)
end

local function ClearAuraTimer(button)
	button.__auraTimerExpiration = nil
	button.LastAuraTime = nil
	button.Time:Hide()
end

local RegisterAuraTimer = function(button, expiration)
	button.Expiration = expiration
	if not Settings["unitframes-display-aura-timers"] then
		return
	end
	button.Time:Show()
	button.__auraTimerExpiration = expiration
	YxUI.DurationText:Register(button, button.Time, FormatAuraRemaining, GetAuraRemaining, ClearAuraTimer)
end

function UF:SetAuraTimersEnabled(enabled)
	for button in pairs(AuraButtons) do
		if enabled then
			button.Time:SetParent(button.cd)
			if button:IsVisible() and button.Expiration then
				RegisterAuraTimer(button, button.Expiration)
			end
		else
			UnregisterAuraTimer(button)
			button.Time:SetParent(Hider)
		end
	end
end

UF.ThreatPostUpdate = function(self, unit, status, r, g, b)
	if status and status > 0 then
		self:SetBackdropBorderColor(r, g, b)
	end
end

UF.NPThreatPostUpdate = function(self, unit, status, r, g, b)
	if status and status > 0 then
		self.Top:SetVertexColor(r, g, b)
		self.Bottom:SetVertexColor(r, g, b)
	end
end

local function UpdateAuraAppearance(self, button, duration, expiration, debuffType, isStealable)
	local cooldown = button.cd
	if cooldown then
		if duration and duration > 0 and expiration then
			local start = expiration - duration
			if button.__cooldownStart ~= start or button.__cooldownDuration ~= duration or not cooldown:IsShown() then
				cooldown:SetCooldown(start, duration)
				button.__cooldownStart, button.__cooldownDuration = start, duration
			end
			if not cooldown:IsShown() then
				cooldown:Show()
			end
		else
			button.__cooldownStart, button.__cooldownDuration = nil, nil
			if cooldown:IsShown() then
				cooldown:Hide()
			end
		end
	end

	local color = debuffType and debuffType ~= "" and self.__owner.colors.debuff[debuffType]
	local borderKind = color and debuffType or (button.__container.showStealableBuffs and isStealable and "stealable")
	if not button.__auraBorderValid or button.__auraBorderKind ~= borderKind then
		button.__auraBorderValid = true
		button.__auraBorderKind = borderKind
		if color then
			button.DebuffType:SetBackdropBorderColor(color[1], color[2], color[3])
			button.DebuffType:Show()
		elseif borderKind == "stealable" then
			button.DebuffType:SetBackdropBorderColor(0.2, 0.6, 1)
			button.DebuffType:Show()
		else
			button.DebuffType:Hide()
		end
	end

	local desaturated = not not (button.filter == "HARMFUL" and not button.isPlayer and debuffType and debuffType ~= "")
	if button.__auraDesaturated ~= desaturated then
		button.icon:SetDesaturated(desaturated)
		button.__auraDesaturated = desaturated
	end

	if expiration and expiration ~= 0 then
		button.Expiration = expiration
		if Settings["unitframes-display-aura-timers"] and button.__auraTimerExpiration ~= expiration then
			UnregisterAuraTimer(button)
			RegisterAuraTimer(button, expiration)
		end
	else
		button.Expiration = nil
		if button.__auraTimerExpiration then
			UnregisterAuraTimer(button)
		end
	end
end

if YxUI.IsVanilla then
	local LCD = LibStub("LibClassicDurations")
	local UnitAura = UnitAura

	LCD:Register("YxUI")

	UF.PostUpdateIcon = function(self, unit, button, index, position, duration, expiration, debuffType, isStealable)
		local name, _, _, _, auraDuration, auraExpiration, caster, _, _, spellID = UnitAura(unit, index, button.filter)
		local estimatedDuration, estimatedExpiration = LCD:GetAuraDurationByUnit(unit, spellID, caster, name)
		if auraDuration == 0 and estimatedDuration then
			auraDuration, auraExpiration = estimatedDuration, estimatedExpiration
		end
		UpdateAuraAppearance(self, button, auraDuration, auraExpiration, debuffType, isStealable)
	end
else
	UF.PostUpdateIcon = function(self, unit, button, index, position, duration, expiration, debuffType, isStealable)
		UpdateAuraAppearance(self, button, duration, expiration, debuffType, isStealable)
	end
end

local CancelAuraOnMouseUp = function(aura, button)
	if button ~= "RightButton" or InCombatLockdown() or aura.filter ~= "HELPFUL" or aura.__owner.unit ~= "player" then
		return
	end

	CancelUnitBuff("player", aura.__index)
end

UF.PostCreateIcon = function(unit, button)
	AuraButtons[button] = true
	UnregisterAuraTimer(button)
	button:HookScript("OnHide", function(self)
		UnregisterAuraTimer(self)
		self.__auraPostValid = nil
	end)
	button:SetScript("OnMouseUp", CancelAuraOnMouseUp)

	button.bg = button:CreateTexture(nil, "BACKGROUND")
	button.bg:SetPoint("TOPLEFT", button, 0, 0)
	button.bg:SetPoint("BOTTOMRIGHT", button, 0, 0)
	button.bg:SetColorTexture(0, 0, 0)

	button.cd.noOCC = true
	button.cd.noCooldownCount = true
	button.cd:ClearAllPoints()
	button.cd:SetPoint("TOPLEFT", button, 1, -1)
	button.cd:SetPoint("BOTTOMRIGHT", button, -1, 1)
	button.cd:SetHideCountdownNumbers(true)
	button.cd:SetDrawSwipe(true)
	button.cd:SetDrawEdge(false)
	button.cd:SetDrawBling(false)
	button.cd:SetReverse(true)

	button.icon:SetPoint("TOPLEFT", 1, -1)
	button.icon:SetPoint("BOTTOMRIGHT", -1, 1)
	button.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

	button.count:SetPoint("BOTTOMRIGHT", 1, 2)
	button.count:SetJustifyH("RIGHT")
	YxUI:SetFontInfo(button.count, Settings["unitframes-font"], Settings["unitframes-font-size"], "OUTLINE")

	button.Time = button.cd:CreateFontString(nil, "OVERLAY")
	button.Time:Hide()
	YxUI:SetFontInfo(button.Time, Settings["unitframes-font"], Settings["unitframes-font-size"], "OUTLINE")
	button.Time:SetPoint("TOPLEFT", -1, -1)
	button.Time:SetJustifyH("LEFT")

	button.DebuffType = CreateFrame("Frame", nil, button, "BackdropTemplate")
	button.DebuffType:SetPoint("TOPLEFT", 1, -1)
	button.DebuffType:SetPoint("BOTTOMRIGHT", -1, 1)
	button.DebuffType:SetBackdrop(YxUI.Outline)
	button.DebuffType:SetFrameLevel(button:GetFrameLevel() + 3)

	if not Settings["unitframes-display-aura-timers"] then
		button.Time:SetParent(Hider)
	end
end

UF.AuraOffsets = {
	TOPLEFT = {6, 0},
	TOPRIGHT = {-6, 0},
	BOTTOMLEFT = {6, 0},
	BOTTOMRIGHT = {-6, 0},
	LEFT = {6, 0},
	RIGHT = {-6, 0},
	TOP = {0, 0},
	BOTTOM = {0, 0},
}

if YxUI.IsMainline then
	UF.BuffIDs = {
		["DRUID"] = {
			{774, "TOPLEFT", {0.8, 0.4, 0.8}},      -- Rejuvenation
			{155777, "LEFT", {0.8, 0.4, 0.8}},      -- Germination
			{8936, "TOPRIGHT", {0.2, 0.8, 0.2}},    -- Regrowth
			{33763, "BOTTOMLEFT", {0.4, 0.8, 0.2}}, -- Lifebloom
			{48438, "BOTTOMRIGHT", {0.8, 0.4, 0}},  -- Wild Growth
			{102342, "RIGHT", {0.8, 0.2, 0.2}},     -- Ironbark
			{102351, "BOTTOM", {0.84, 0.92, 0.77}}, -- Cenarion Ward
			{102352, "BOTTOM", {0.84, 0.92, 0.77}}, -- Cenarion Ward (Heal)
		},

		["MONK"] = {
			{119611, "TOPLEFT", {0.32, 0.89, 0.74}},  -- Renewing Mist
			{116849, "TOPRIGHT", {0.2, 0.8, 0.2}},	  -- Life Cocoon
			{124682, "BOTTOMLEFT", {0.9, 0.8, 0.48}}, -- Enveloping Mist
			{124081, "BOTTOMRIGHT", {0.7, 0.4, 0}},   -- Zen Sphere
			{115175, "LEFT", {0.24, 0.87, 0.49}},     -- Soothing Mist
		},

		["PALADIN"] = {
			{53563, "TOPRIGHT", {0.7, 0.3, 0.7}},	        -- Beacon of Light
			{156910, "TOPRIGHT", {0.7, 0.3, 0.7}},	        -- Beacon of Faith
			{200025, "TOPRIGHT", {0.7, 0.3, 0.7}},	        -- Beacon of Virtue
			{287280, "BOTTOMLEFT", {0.99, 0.75, 0.36}},	    -- Glimmer of Light
			{1022, "BOTTOMRIGHT", {0.29, 0.45, 0.73}, true},-- Blessing of Protection
			{1044, "BOTTOMRIGHT", {0.89, 0.45, 0}, true},	-- Blessing of Freedom
			--{1038, "BOTTOMRIGHT", {0.93, 0.75, 0}, true},	-- Blessing of Salvation
			{6940, "BOTTOMRIGHT", {0.89, 0.1, 0.1}, true},	-- Blessing of Sacrifice
			--{223306, "TOPLEFT", {0.81, 0.85, 0.1}},	    -- Bestow Faith
		},

		["PRIEST"] = {
			{41635, "BOTTOMRIGHT", {0.2, 0.7, 0.2}},  -- Prayer of Mending
			{139, "BOTTOMLEFT", {0.4, 0.7, 0.2}},     -- Renew
			{17, "TOPLEFT", {0.81, 0.85, 0.1}, true}, -- Power Word: Shield
			{194384, "TOPRIGHT", {1, 0, 0}},          -- Atonement

			{33206, "BOTTOMLEFT", {0.93, 0.91, 0.87}}, -- Pain Suppression
			{121536, "BOTTOMRIGHT", {0.98, 0.76, 0.03}}, -- Angelic Feather
		},

		["SHAMAN"] = {
			{61295, "TOPLEFT", {0.7, 0.3, 0.7}},   -- Riptide
			{974, "TOPRIGHT", {0.73, 0.61, 0.33}}, -- Earth Shield
		},

		["EVOKER"] = { -- Requires IDs

		}
	}
elseif YxUI.IsCata or YxUI.IsMists then
	UF.BuffIDs = {
		["DRUID"] = {
			-- Regrowth
			{8936, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{8938, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{8939, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{8940, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{8941, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{9750, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{9856, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{9857, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{9858, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{26980, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{48442, "TOPRIGHT", {0.2, 0.8, 0.2}}, -- rank 11
			{48443, "TOPRIGHT", {0.2, 0.8, 0.2}}, -- rank 12

			-- Rejuvenation
			{774, "TOPLEFT", {0.8, 0.4, 0.8}},
			{1058, "TOPLEFT", {0.8, 0.4, 0.8}},
			{1430, "TOPLEFT", {0.8, 0.4, 0.8}},
			{2090, "TOPLEFT", {0.8, 0.4, 0.8}},
			{2091, "TOPLEFT", {0.8, 0.4, 0.8}},
			{3627, "TOPLEFT", {0.8, 0.4, 0.8}},
			{8910, "TOPLEFT", {0.8, 0.4, 0.8}},
			{9839, "TOPLEFT", {0.8, 0.4, 0.8}},
			{9840, "TOPLEFT", {0.8, 0.4, 0.8}},
			{9841, "TOPLEFT", {0.8, 0.4, 0.8}},
			{25299, "TOPLEFT", {0.8, 0.4, 0.8}},
			{26981, "TOPLEFT", {0.8, 0.4, 0.8}},
			{26982, "TOPLEFT", {0.8, 0.4, 0.8}},
			{48440, "TOPLEFT", {0.8, 0.4, 0.8}}, -- rank 14
			{48441, "TOPLEFT", {0.8, 0.4, 0.8}}, -- rank 15

			-- Lifebloom
			{33763, "BOTTOMLEFT", {0.4, 0.8, 0.2}},
			{48450, "BOTTOMLEFT", {0.4, 0.8, 0.2}}, -- rank 2
			{48451, "BOTTOMLEFT", {0.4, 0.8, 0.2}}, -- rank 3
		},

		["PALADIN"] = {
			-- Beacon of Light
			{53563, "TOPRIGHT", {0.81, 0.85, 0.1}, true},

			-- Sacred Shield
			{53601, "TOPLEFT", {0.80, 0.61, 0.11}, true},

			-- Hand of Freedom
			{1044, "BOTTOMRIGHT", {0.89, 0.45, 0}, true},

			-- Hand of Protection
			{1022, "BOTTOMRIGHT", {0.29, 0.45, 0.73}, true},
			{5599, "BOTTOMRIGHT", {0.29, 0.45, 0.73}, true},
			{10278, "BOTTOMRIGHT", {0.29, 0.45, 0.73}, true},

			-- Hand of Sacrifice
			{6940, "BOTTOMRIGHT", {0.89, 0.1, 0.1}, true},
			{20729, "BOTTOMRIGHT", {0.89, 0.1, 0.1}, true},
			{27147, "BOTTOMRIGHT", {0.89, 0.1, 0.1}, true},
			{27148, "BOTTOMRIGHT", {0.89, 0.1, 0.1}, true},
		},

		["PRIEST"] = {
			-- Prayer of Mending
			{33076, "BOTTOMRIGHT", {0.2, 0.7, 0.2}},
			{351575, "BOTTOMRIGHT", {0.2, 0.7, 0.2}},
			{41635, "BOTTOMRIGHT", {0.2, 0.7, 0.2}},
			{41637, "BOTTOMRIGHT", {0.2, 0.7, 0.2}},
			{44583, "BOTTOMRIGHT", {0.2, 0.7, 0.2}},
			{44586, "BOTTOMRIGHT", {0.2, 0.7, 0.2}},
			{46045, "BOTTOMRIGHT", {0.2, 0.7, 0.2}},
			{48112, "BOTTOMRIGHT", {0.2, 0.7, 0.2}},
			{48113, "BOTTOMRIGHT", {0.2, 0.7, 0.2}},

			-- Power Word: Shield
			{17, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{592, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{600, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{3747, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{6065, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{6066, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{10898, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{10899, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{10900, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{10901, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{25217, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{25218, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{48065, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{48066, "TOPLEFT", {0.81, 0.85, 0.1}, true},

			-- Renew
			{139, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{6074, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{6075, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{6076, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{6077, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{6078, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{10927, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{10928, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{10929, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{25315, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{25221, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{25222, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{48067, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{48068, "BOTTOMLEFT", {0.4, 0.7, 0.2}},

			-- Weakened Soul
			{6788, "TOPRIGHT", {0.9, 0.1, 0.1}, true},
		},

		["SHAMAN"] = {
			-- Earth Shield
			{974, "TOPRIGHT", {0.73, 0.61, 0.33}},
			{32593, "TOPRIGHT", {0.73, 0.61, 0.33}},
			{32594, "TOPRIGHT", {0.73, 0.61, 0.33}},
			{49283, "TOPRIGHT", {0.73, 0.61, 0.33}},
			{49284, "TOPRIGHT", {0.73, 0.61, 0.33}},

			-- Riptide
			{61295, "TOPLEFT", {0, 0.4, 0.6}},
			{61299, "TOPLEFT", {0, 0.4, 0.6}},
			{61300, "TOPLEFT", {0, 0.4, 0.6}},
			{61301, "TOPLEFT", {0, 0.4, 0.6}},
		},
	}
else -- Classic
	UF.BuffIDs = {
		["DRUID"] = {
			-- Regrowth
			{8936, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{8938, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{8939, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{8940, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{8941, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{9750, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{9856, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{9857, "TOPRIGHT", {0.2, 0.8, 0.2}},
			{9858, "TOPRIGHT", {0.2, 0.8, 0.2}},

			-- Rejuvenation
			{774, "TOPLEFT", {0.8, 0.4, 0.8}},
			{1058, "TOPLEFT", {0.8, 0.4, 0.8}},
			{1430, "TOPLEFT", {0.8, 0.4, 0.8}},
			{2090, "TOPLEFT", {0.8, 0.4, 0.8}},
			{2091, "TOPLEFT", {0.8, 0.4, 0.8}},
			{3627, "TOPLEFT", {0.8, 0.4, 0.8}},
			{8910, "TOPLEFT", {0.8, 0.4, 0.8}},
			{9839, "TOPLEFT", {0.8, 0.4, 0.8}},
			{9840, "TOPLEFT", {0.8, 0.4, 0.8}},
			{9841, "TOPLEFT", {0.8, 0.4, 0.8}},
			{25299, "TOPLEFT", {0.8, 0.4, 0.8}},
		},

		["PALADIN"] = {
			-- Blessing of Freedom
			{1044, "BOTTOMRIGHT", {0.89, 0.45, 0}, true},

			-- Blessing of Protection
			{1022, "BOTTOMRIGHT", {0.29, 0.45, 0.73}, true},
			{5599, "BOTTOMRIGHT", {0.29, 0.45, 0.73}, true},
			{10278, "BOTTOMRIGHT", {0.29, 0.45, 0.73}, true},

			-- Blessing of Sacrifice
			{6940, "BOTTOMRIGHT", {0.89, 0.1, 0.1}, true},
			{20729, "BOTTOMRIGHT", {0.89, 0.1, 0.1}, true},
		},

		["PRIEST"] = {
			-- Power Word: Shield
			{17, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{592, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{600, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{3747, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{6065, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{6066, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{10898, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{10899, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{10900, "TOPLEFT", {0.81, 0.85, 0.1}, true},
			{10901, "TOPLEFT", {0.81, 0.85, 0.1}, true},

			-- Renew
			{139, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{6074, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{6075, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{6076, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{6077, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{6078, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{10927, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{10928, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{10929, "BOTTOMLEFT", {0.4, 0.7, 0.2}},
			{25315, "BOTTOMLEFT", {0.4, 0.7, 0.2}},

			-- Weakened Soul
			{6788, "TOPRIGHT", {0.9, 0.1, 0.1}, true},
		},
	}
end

UF.PostCreateAuraWatchIcon = function(auras, icon)
	icon.icon:SetPoint("TOPLEFT", 1, -1)
	icon.icon:SetPoint("BOTTOMRIGHT", -1, 1)
	icon.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
	icon.icon:SetDrawLayer("ARTWORK")

	icon.bg = icon:CreateTexture(nil, "BORDER")
	icon.bg:SetPoint("TOPLEFT", icon, -1, 1)
	icon.bg:SetPoint("BOTTOMRIGHT", icon, 1, -1)
	icon.bg:SetTexture(0, 0, 0)

	icon.overlay:SetTexture()
end

local EnumerateAuras = UF.EnumerateAuras

local function AuraTooltipEnter(button)
	GameTooltip:SetOwner(button, button.__container.tooltipAnchor or "ANCHOR_BOTTOMRIGHT")
	GameTooltip:SetUnitAura(button.__owner.unit, button.__index, button.filter)
end
local function AuraTooltipLeave()
	GameTooltip:Hide()
end

local function AcquireAuraButton(container, position)
	local button = container[position]

	if button then
		return button
	end

	button = CreateFrame("Button", nil, container)
	button:SetSize(container.size, container.size)
	button.__auraSize = container.size
	button.icon = button:CreateTexture(nil, "ARTWORK")
	button.icon:SetAllPoints()
	button.cd = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	button.cd:SetAllPoints()
	button.count = button.cd:CreateFontString(nil, "OVERLAY")
	button.__container, button.__owner = container, container.__owner
	button:SetScript("OnEnter", AuraTooltipEnter)
	button:SetScript("OnLeave", AuraTooltipLeave)
	container[position] = button

	if container.PostCreateIcon then
		container:PostCreateIcon(button)
	end

	return button
end

local function LayoutAura(container, button, position, columns, stride, anchor, growthX, growthY)
	local column, row = (position - 1) % columns, math.floor((position - 1) / columns)
	button:ClearAllPoints()
	button:SetPoint(anchor, container, anchor, column * stride * growthX, row * stride * growthY)
end

local function UpdateAuraButton(frame, container, button, position, index, filter, icon, count, debuffType, duration, expiration, caster, stealable, spellID, instanceID)
	local isPlayer = caster == "player" or caster == "pet" or caster == "vehicle"
	local displayCount = count and count > 1 and count or ""
	local first = not button.__auraPostValid or button.__auraSpellID ~= spellID or button.__auraInstanceID ~= instanceID

	button.__index, button.filter, button.isPlayer, button.__auraPosition = index, filter, isPlayer, position

	if first or button.__auraIcon ~= icon then
		button.icon:SetTexture(icon)
		button.__auraIcon = icon
	end
	if first or button.__auraCount ~= displayCount then
		button.count:SetText(displayCount)
		button.__auraCount = displayCount
	end

	if container.PostUpdateIcon and (YxUI.IsVanilla or first or button.__auraDuration ~= duration
		or button.__auraExpiration ~= expiration or button.__auraDebuffType ~= debuffType
		or button.__auraStealable ~= stealable or button.__auraPlayer ~= isPlayer
		or button.__auraStealableEnabled ~= container.showStealableBuffs) then
		container:PostUpdateIcon(frame.unit, button, index, position, duration, expiration, debuffType, stealable)
	end

	button.__auraPostValid = true
	button.__auraSpellID, button.__auraInstanceID = spellID, instanceID
	button.__auraDuration, button.__auraExpiration = duration, expiration
	button.__auraDebuffType, button.__auraStealable = debuffType, stealable
	button.__auraPlayer, button.__auraCaster = isPlayer, caster
	button.__auraStealableEnabled = container.showStealableBuffs

	if not button:IsShown() then
		button:Show()
	end
end

local function UpdateAuraContainer(frame, container, filter)
	local position, limit = 0, container.num or 32
	local size, spacing = container.size, container.spacing or 0
	local stride = size + spacing
	local columns = math.max(1, math.floor((container:GetWidth() + spacing) / stride))
	local anchor = container.initialAnchor or "TOPLEFT"
	local growthX = container["growth-x"] == "LEFT" and -1 or 1
	local growthY = container["growth-y"] == "UP" and 1 or -1

	if container.__layoutSize ~= size or container.__layoutStride ~= stride or container.__layoutColumns ~= columns
		or container.__layoutAnchor ~= anchor or container.__layoutGrowthX ~= growthX or container.__layoutGrowthY ~= growthY then
		container.__layoutSize = size
		container.__layoutStride = stride
		container.__layoutColumns = columns
		container.__layoutAnchor = anchor
		container.__layoutGrowthX = growthX
		container.__layoutGrowthY = growthY
		container.__layoutVersion = (container.__layoutVersion or 0) + 1
	end

	local layoutVersion = container.__layoutVersion
	local lookup = container.__auraLookup
	if not lookup then
		lookup = {}
		container.__auraLookup = lookup
	end
	for instanceID in pairs(lookup) do
		lookup[instanceID] = nil
	end

	EnumerateAuras(frame.unit, filter, function(index, name, icon, count, debuffType, duration, expiration, caster, stealable, spellID, auraData)
		local isPlayer = caster == "player" or caster == "pet" or caster == "vehicle"

		if container.onlyShowPlayer and not isPlayer then
			return
		end

		if container.CustomFilter then
			local aura = container.__filterAura
			if not aura then
				aura = {}
				container.__filterAura = aura
			end
			aura.name = name
			aura.spellId = spellID
			aura.sourceUnit = caster
			aura.isFromPlayerOrPlayerPet = isPlayer

			if not container:CustomFilter(frame.unit, aura, frame) then
				return
			end
		end

		if position >= limit then
			return false
		end

		position = position + 1
		local button = AcquireAuraButton(container, position)
		local instanceID = auraData and auraData.auraInstanceID
		if not IsInaccessible(instanceID) and instanceID then
			lookup[instanceID] = button
		else
			instanceID = nil
		end

		if button.__layoutVersion ~= layoutVersion then
			if button.__auraSize ~= size then
				button:SetSize(size, size)
				button.__auraSize = size
			end
			LayoutAura(container, button, position, columns, stride, anchor, growthX, growthY)
			button.__layoutVersion = layoutVersion
		end

		UpdateAuraButton(frame, container, button, position, index, filter, icon, count, debuffType, duration, expiration, caster, stealable, spellID, instanceID)
	end)

	for index = position + 1, #container do
		local button = container[index]
		if button:IsShown() then
			button:Hide()
		elseif button.__auraTimerExpiration then
			UnregisterAuraTimer(button)
		end
	end

	local guid = UnitGUID(frame.unit)
	container.__auraUnitGUID = not IsInaccessible(guid) and guid or nil
end

local function IsReadableAura(aura)
	if IsInaccessible(aura) or not aura then
		return false
	end
	return not IsInaccessible(aura.auraInstanceID)
		and not IsInaccessible(aura.name) and not IsInaccessible(aura.icon)
		and not IsInaccessible(aura.applications) and not IsInaccessible(aura.dispelName)
		and not IsInaccessible(aura.duration) and not IsInaccessible(aura.expirationTime)
		and not IsInaccessible(aura.sourceUnit) and not IsInaccessible(aura.isStealable)
		and not IsInaccessible(aura.spellId) and not IsInaccessible(aura.isHelpful)
		and not IsInaccessible(aura.isHarmful)
end

local function TryIncrementalAuraContainer(frame, container, filter, updateInfo)
	if not YxUI.IsMidnight or IsInaccessible(updateInfo) or not updateInfo
		or IsInaccessible(updateInfo.isFullUpdate) or updateInfo.isFullUpdate
		or IsInaccessible(updateInfo.addedAuras) or IsInaccessible(updateInfo.removedAuraInstanceIDs)
		or (updateInfo.removedAuraInstanceIDs and #updateInfo.removedAuraInstanceIDs > 0)
		or not (C_UnitAuras and C_UnitAuras.GetAuraDataByAuraInstanceID) then
		return false
	end

	local added = updateInfo.addedAuras
	if added then
		for i = 1, #added do
			local aura = added[i]
			if IsInaccessible(aura) or not aura or IsInaccessible(aura.isHelpful) or IsInaccessible(aura.isHarmful)
				or not ((filter == "HELPFUL" and aura.isHarmful == true and aura.isHelpful == false)
					or (filter == "HARMFUL" and aura.isHelpful == true and aura.isHarmful == false)) then
				return false
			end
		end
	end

	if C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret() then
		return false
	end

	local guid = UnitGUID(frame.unit)
	if IsInaccessible(guid) or not guid or container.__auraUnitGUID ~= guid then
		return false
	end

	local updated = updateInfo.updatedAuraInstanceIDs
	if IsInaccessible(updated) then
		return false
	end
	if not updated or #updated == 0 then
		return true
	end

	local lookup = container.__auraLookup
	if not lookup then
		return false
	end

	for i = 1, #updated do
		local instanceID = updated[i]
		if IsInaccessible(instanceID) then
			return false
		end
		local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(frame.unit, instanceID)
		if not IsReadableAura(aura) then
			return false
		end

		if (filter == "HELPFUL" and aura.isHarmful) or (filter == "HARMFUL" and aura.isHelpful) then
			-- The other aura container owns this instance.
		elseif not lookup[instanceID] then
			-- A hidden aura might now pass a custom filter.
			return false
		else
			local button = lookup[instanceID]
			local indexedAura = C_UnitAuras.GetAuraDataByIndex(frame.unit, button.__index, filter)
			if IsInaccessible(indexedAura) or not indexedAura or IsInaccessible(indexedAura.auraInstanceID)
				or indexedAura.auraInstanceID ~= instanceID then
				return false
			end
			local isPlayer = aura.sourceUnit == "player" or aura.sourceUnit == "pet" or aura.sourceUnit == "vehicle"
			if button.__auraCaster ~= aura.sourceUnit or (container.onlyShowPlayer and not isPlayer) then
				return false
			end
			if container.CustomFilter then
				local filterAura = container.__filterAura
				filterAura.name = aura.name
				filterAura.spellId = aura.spellId
				filterAura.sourceUnit = aura.sourceUnit
				filterAura.isFromPlayerOrPlayerPet = isPlayer
				if not container:CustomFilter(frame.unit, filterAura, frame) then
					return false
				end
			end

			UpdateAuraButton(frame, container, button, button.__auraPosition, button.__index, filter, aura.icon,
				aura.applications, aura.dispelName, aura.duration, aura.expirationTime,
				aura.sourceUnit, aura.isStealable, aura.spellId, instanceID)
		end
	end

	return true
end

local function UpdateAuras(frame, event, unit, updateInfo)
	if unit and unit ~= frame.unit then
		return
	end

	if UF:IsForeverAuraFrame(frame) then
		UF:UpdateForeverAuras(frame, event)
		return
	end

	if frame.Buffs and not (event == "UNIT_AURA" and TryIncrementalAuraContainer(frame, frame.Buffs, "HELPFUL", updateInfo)) then
		UpdateAuraContainer(frame, frame.Buffs, "HELPFUL")
	end

	if frame.Debuffs and not (event == "UNIT_AURA" and TryIncrementalAuraContainer(frame, frame.Debuffs, "HARMFUL", updateInfo)) then
		UpdateAuraContainer(frame, frame.Debuffs, "HARMFUL")
	end
end

local function EnableAuras(frame)
	if not frame.Buffs and not frame.Debuffs then
		return
	end

	if UF:IsForeverAuraFrame(frame) then
		return UF:EnableForeverAuras(frame)
	end

	local function EnableContainer(container)
		if not container then
			return
		end

		container.__owner = frame
		container.ForceUpdate = function()
			UpdateAuras(frame, "ForceUpdate", frame.unit)
		end
		container:Show()
	end

	EnableContainer(frame.Buffs)
	EnableContainer(frame.Debuffs)

	frame:RegisterEvent("UNIT_AURA", UpdateAuras)

	if frame:IsVisible() and UnitExists(frame.unit) then
		UpdateAuras(frame, "ForceUpdate", frame.unit)
	end

	return true
end

local function DisableAuraContainer(container)
	if not container then
		return
	end

	container:Hide()

	container.__auraUnitGUID = nil
	if container.__auraLookup then
		for instanceID in pairs(container.__auraLookup) do
			container.__auraLookup[instanceID] = nil
		end
	end
	for i = 1, #container do
		UnregisterAuraTimer(container[i])
		container[i].__auraPostValid = nil
	end
end

local function DisableAuras(frame)
	if UF:IsForeverAuraFrame(frame) then
		UF:DisableForeverAuras(frame)
		return
	end

	frame:UnregisterEvent("UNIT_AURA", UpdateAuras)
	DisableAuraContainer(frame.Buffs)
	DisableAuraContainer(frame.Debuffs)
end

UF:RegisterElement("Auras", {
	update = UpdateAuras,
	enable = EnableAuras,
	disable = DisableAuras,
})
