local _, ns = ...
local YxUI, _, _, Settings = ns:get()

local UF = YxUI:GetModule("Unit Frames")

local function Setting(key)
	return key and Settings[key]
end

local function FamilySetting(config, suffix)
	return Setting(config.settingsPrefix .. suffix)
end

-- These descriptions are shared by every singleton style.  Keep them in this file so every BuildSingleUnitFrame invocation can access them without recreating the tables for each frame.
local SingleUnitText = {
	left = {point = "LEFT", x = 3, justify = "LEFT"},
	right = {point = "RIGHT", x = -3, justify = "RIGHT"},
}

-- Compose the pieces common to non-group unit frames.  Optional or unusual pieces are functions on the descriptor; this keeps knowledge of targets, bosses, etc. out of the factory.
function UF:BuildSingleUnitFrame(frame, unit, config)
	assert(type(config) == "table" and config.settingsPrefix, "single unit frame requires settingsPrefix")

	frame:RegisterForClicks("AnyUp")
	frame:SetScript("OnEnter", UnitFrame_OnEnter)
	frame:SetScript("OnLeave", UnitFrame_OnLeave)

	if config.debuffColors then
		frame.colors.debuff = YxUI.DebuffColors
	end

	self:CreateBackdrop(frame, config.backdropTexture or "Blank", config.backdropLayer or "BACKGROUND")

	if config.threat ~= false then
		self:CreateThreatIndicator(frame, YxUI.Outline, self.ThreatPostUpdate)
	end

	local healthHeight = FamilySetting(config, "-health-height")
	local healthReverse = FamilySetting(config, "-health-reverse")
	local width = FamilySetting(config, "-width")
	local healthTexture = Setting(config.healthTextureKey)
	local health = self:CreateHealthBar(frame, healthHeight, healthTexture, healthReverse, config.healthOrientation and FamilySetting(config, "-health-orientation"), config.healthBackgroundLayer or "BORDER")

	self:CreateHealAndAbsorbBars(frame, health, width, healthHeight, healthTexture, healthReverse, YxUI.IsMainline)

	local font, fontSize, fontFlags = Setting(config.fontKey or "unitframes-font"), Setting(config.fontSizeKey or "unitframes-font-size"), Setting(config.fontFlagsKey or "unitframes-font-flags")
	local trackUnitFont = not config.fontKey and not config.fontSizeKey and not config.fontFlagsKey
	local leftSpec, rightSpec = SingleUnitText.left, SingleUnitText.right
	local healthLeft, healthRight

	if config.healthTags ~= false then
		healthLeft = self:CreateFontString(health, font, fontSize, fontFlags, leftSpec.point, leftSpec.point, leftSpec.x, 0, leftSpec.justify)
		healthRight = self:CreateFontString(health, font, fontSize, fontFlags, rightSpec.point, rightSpec.point, rightSpec.x, 0, rightSpec.justify)
		if trackUnitFont then
			self:TrackUnitFont(healthLeft)
			self:TrackUnitFont(healthRight)
		end
	end

	local r, g, b = YxUI:HexToRGB(Settings["ui-header-texture-color"])
	frame.colors.health = {r, g, b}
	health.Smooth = FamilySetting(config, "-health-smooth") ~= false

	health.frequentUpdates = config.healthFrequentUpdates
	health.colorTapping = config.colorTapping
	health.colorDisconnected = config.colorDisconnected

	self:SetHealthAttributes(health, FamilySetting(config, "-health-color"))

	local power, powerLeft, powerRight

	if config.power ~= false and (not config.powerEnabledKey or Setting(config.powerEnabledKey)) then
		local powerReverse = config.powerReverse

		if powerReverse == nil then
			powerReverse = FamilySetting(config, "-power-reverse")
		end

		power = self:CreatePowerBar(frame, FamilySetting(config, "-power-height"), Setting(config.powerTextureKey), powerReverse)
		power.frequentUpdates = true
		power.colorReaction = config.powerReaction
		power.Smooth = FamilySetting(config, "-power-smooth") ~= false

		self:SetPowerAttributes(power, FamilySetting(config, "-power-color"))

		if config.powerTags then
			powerLeft = self:CreateFontString(power, font, fontSize, fontFlags, leftSpec.point, leftSpec.point, leftSpec.x, 0, leftSpec.justify)
			powerRight = self:CreateFontString(power, font, fontSize, fontFlags, rightSpec.point, rightSpec.point, rightSpec.x, 0, rightSpec.justify)
			if trackUnitFont then
				self:TrackUnitFont(powerLeft)
				self:TrackUnitFont(powerRight)
			end

			frame:Tag(powerLeft, FamilySetting(config, "-power-left"))
			frame:Tag(powerRight, FamilySetting(config, "-power-right"))
		end
	end

	if healthLeft then
		frame:Tag(healthLeft, FamilySetting(config, "-health-left"))
	end

	if healthRight then
		frame:Tag(healthRight, FamilySetting(config, "-health-right"))
	end

	frame.Health, frame.HealthLeft, frame.HealthRight = health, healthLeft, healthRight
	frame.Power, frame.PowerLeft, frame.PowerRight = power, powerLeft, powerRight

	if config.middleTag then
		local middle = self:CreateFontString(health, font, fontSize, fontFlags, "CENTER", "CENTER", 0, 0, "CENTER")
		if trackUnitFont then
			self:TrackUnitFont(middle)
		end
		frame:Tag(middle, config.middleTag)
		frame.HealthMiddle = middle
	end

	if config.mouseoverKey then
		self:CreateMouseoverHighlight(frame, health, "Blank", Setting(config.mouseoverKey))
	end

	if config.raidTarget then
		frame.RaidTargetIndicator = self:CreateRaidTargetIndicator(health, 16)
	end

	if config.range then
		frame.Range = config.range
	end

	if config.portrait then
		config.portrait(self, frame, unit)
	end

	if config.cast then
		config.cast(self, frame, unit)
	end

	if config.auras then
		config.auras(self, frame, unit)
	end

	if config.postBuild then
		config.postBuild(self, frame, unit)
	end

	return frame
end