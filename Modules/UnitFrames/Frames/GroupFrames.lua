local YxUI, _, Assets, Settings = select(2, ...):get()
local UF = YxUI:GetModule("Unit Frames")

local PendingUpdates = {}
local UpdateDriver = CreateFrame("Frame")
UpdateDriver:SetScript("OnEvent", function(self)
	if InCombatLockdown() then
		return
	end

	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	local Updates = PendingUpdates
	PendingUpdates = {}

	for Key, Action in next, Updates do
		Action()
	end
end)

function UF:RunAfterCombat(key, action)
	if InCombatLockdown() then
		PendingUpdates[key] = action
		UpdateDriver:RegisterEvent("PLAYER_REGEN_ENABLED")
	else
		PendingUpdates[key] = nil
		action()
	end
end

local function Setting(descriptor, suffix)
	return Settings[descriptor.prefix .. suffix]
end

-- Group frame descriptors are deliberately data-only and live for the lifetime of the addon.  Settings callbacks can therefore pass one stable object through the header iterator instead of manufacturing a closure (or a children table).
local function CreateAuraWatch(frame, health, descriptor)
	if not descriptor.indicators.auraWatch or not UF.BuffIDs[YxUI.UserClass] then
		return
	end

	local auras = CreateFrame("Frame", nil, health)
	auras:SetPoint("TOPLEFT", health)
	auras:SetPoint("BOTTOMRIGHT", health)
	auras:SetFrameLevel(10)
	auras:SetFrameStrata("HIGH")
	auras.presentAlpha, auras.missingAlpha = 1, 0
	auras.strictMatching, auras.icons = true, {}
	auras.PostCreateIcon = UF.PostCreateAuraWatchIcon
	local blank = Assets:GetTexture("Blank")
	local font = Setting(descriptor, "-font")
	for _, spell in pairs(UF.BuffIDs[YxUI.UserClass]) do
		local icon = CreateFrame("Frame", nil, auras)
		icon.spellID, icon.anyUnit, icon.strictMatching = spell[1], spell[4], true
		icon:SetSize(8, 8)
		icon:SetPoint(spell[2], 0, 0)
		local texture = icon:CreateTexture(nil, "OVERLAY")
		texture:SetAllPoints(icon)
		texture:SetTexture(blank)
		if spell[3] then
			texture:SetVertexColor(unpack(spell[3]))
		else
			texture:SetVertexColor(0.8, 0.8, 0.8)
		end

		local bg = icon:CreateTexture(nil, "BORDER")
		bg:SetPoint("TOPLEFT", icon, -1, 1)
		bg:SetPoint("BOTTOMRIGHT", icon, 1, -1)
		bg:SetTexture(blank)
		bg:SetVertexColor(0, 0, 0)
		local count = icon:CreateFontString(nil, "OVERLAY")
		YxUI:SetFontInfo(count, font, 10)
		count:SetPoint("CENTER", unpack(UF.AuraOffsets[spell[2]]))
		icon.count = count
		auras.icons[spell[1]] = icon
	end
	frame.AuraWatch = auras
end

local function CreateDeadAnimation(health)
	local dead = health:CreateTexture(nil, "OVERLAY")
	dead:SetAllPoints(health)
	dead:SetTexture(Assets:GetTexture("RenHorizonUp"))
	dead:SetVertexColor(0.8, 0.8, 0.8)
	dead:SetAlpha(0)
	dead:SetDrawLayer("OVERLAY", 7)

	local animation = LibMotion:CreateAnimationGroup()
	local fadeIn = LibMotion:CreateAnimation(dead, "Fade")
	fadeIn:SetEasing("in")
	fadeIn:SetDuration(0.15)
	fadeIn:SetChange(0.6)
	fadeIn:SetGroup(animation)
	fadeIn:SetOrder(1)
	animation.In = fadeIn

	local fadeOut = LibMotion:CreateAnimation(dead, "Fade")
	fadeOut:SetEasing("out")
	fadeOut:SetDuration(0.3)
	fadeOut:SetChange(0)
	fadeOut:SetGroup(animation)
	fadeOut:SetOrder(2)
	animation.Out = fadeOut
	health.DeadAnim = animation
end

local function CreateIndicatorTexture(health, texture, point, relativePoint, x, y)
	local indicator = health:CreateTexture(nil, "OVERLAY")
	indicator:SetSize(16, 16)
	indicator:SetPoint(point, health, relativePoint or point, x or 0, y or 0)
	if texture then
		indicator:SetTexture(Assets:GetTexture(texture))
	end

	return indicator
end

local function CreatePhaseIndicator(health, point)
	local phase = CreateFrame("Frame", nil, health)
	phase:SetSize(16, 16)
	phase:SetPoint(point, health, point, 0, 0)
	phase.Icon = phase:CreateTexture(nil, "OVERLAY")
	phase.Icon:SetAllPoints()
	return phase
end

local function CreateDispelIndicator(health, debuffs, descriptor)
	local dispel = CreateFrame("Frame", nil, health, "BackdropTemplate")
	dispel:SetSize(descriptor.dispelSize, descriptor.dispelSize)
	dispel:SetPoint("CENTER", health)
	dispel:SetBackdrop(YxUI.BackdropAndBorder)
	dispel:SetBackdropColor(0, 0, 0)
	local baseLevel = descriptor.dispelAboveDebuffs and debuffs:GetFrameLevel() or health:GetFrameLevel() + 19
	dispel:SetFrameLevel(baseLevel + 1)

	dispel.icon = dispel:CreateTexture(nil, "ARTWORK")
	dispel.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
	dispel.icon:SetPoint("TOPLEFT", dispel, 1, -1)
	dispel.icon:SetPoint("BOTTOMRIGHT", dispel, -1, 1)

	dispel.cd = CreateFrame("Cooldown", nil, dispel, "CooldownFrameTemplate")
	dispel.cd:SetPoint("TOPLEFT", dispel, 1, -1)
	dispel.cd:SetPoint("BOTTOMRIGHT", dispel, -1, 1)
	dispel.cd:SetHideCountdownNumbers(true)
	dispel.cd:SetDrawSwipe(true)
	dispel.cd:SetDrawEdge(false)
	dispel.cd:SetDrawBling(false)

	dispel.count = dispel.cd:CreateFontString(nil, "ARTWORK")
	YxUI:SetFontInfo(
		dispel.count,
		Setting(descriptor, "-font"),
		Setting(descriptor, "-font-size"),
		Setting(descriptor, "-font-flags")
	)
	dispel.count:SetPoint("BOTTOMRIGHT", dispel, "BOTTOMRIGHT", -3, 3)
	dispel.count:SetTextColor(1, 1, 1)
	dispel.count:SetJustifyH("RIGHT")
	dispel.count:SetDrawLayer("ARTWORK", 7)

	dispel.bg = dispel:CreateTexture(nil, "BACKGROUND")
	dispel.bg:SetPoint("TOPLEFT", dispel, -1, 1)
	dispel.bg:SetPoint("BOTTOMRIGHT", dispel, 1, -1)
	dispel.bg:SetTexture(Assets:GetTexture("Blank"))
	dispel.bg:SetVertexColor(0, 0, 0)
	return dispel
end

function UF:BuildGroupFrame(frame, unit, descriptor)
	frame:RegisterForClicks("AnyUp")
	frame:SetScript("OnEnter", UnitFrame_OnEnter)
	frame:SetScript("OnLeave", UnitFrame_OnLeave)
	UF:CreateBackdrop(frame, "Blank", "BACKGROUND")
	UF:CreateThreatIndicator(frame, YxUI.Outline, UF.ThreatPostUpdate)
	local healthHeight = Setting(descriptor, "-health-height")
	local healthReverse = Setting(descriptor, "-health-reverse")
	local healthTexture = Settings[descriptor.healthTextureKey]
	local health, healthBG = UF:CreateHealthBar(
		frame, healthHeight, healthTexture, healthReverse,
		Setting(descriptor, "-health-orientation"), "BORDER"
	)
	UF:CreateHealAndAbsorbBars(
		frame, health, Setting(descriptor, "-width"), healthHeight,
		healthTexture, healthReverse, YxUI.IsMainline
	)
	UF:CreateMouseoverHighlight(frame, health, "Blank", Settings[descriptor.mouseoverKey])
	CreateDeadAnimation(health)
	local font = Setting(descriptor, "-font")
	local fontSize = Setting(descriptor, "-font-size")
	local fontFlags = Setting(descriptor, "-font-flags")
	local healthName = UF:CreateFontString(health, font, fontSize, fontFlags, "BOTTOM", "CENTER", 0, 1, "CENTER")
	local healthBottom = UF:CreateFontString(health, font, fontSize, fontFlags, "TOP", "CENTER", 0, -1, "CENTER")
	health.colorDisconnected, health.Smooth = true, Setting(descriptor, "-health-smooth")
	UF:SetHealthAttributes(health, Setting(descriptor, "-health-color"))
	local power, powerBG = UF:CreatePowerBar(
		frame, Setting(descriptor, "-power-height"),
		Settings[descriptor.powerTextureKey], Setting(descriptor, "-power-reverse")
	)
	power.frequentUpdates = true
	power.Smooth = Setting(descriptor, "-power-smooth")
	UF:SetPowerAttributes(power, Setting(descriptor, "-power-color"))
	local debuffs = descriptor.createDebuffs(frame, health, descriptor.debuffFilter)
	CreateAuraWatch(frame, health, descriptor)
	local leader = CreateIndicatorTexture(health, "Leader", "LEFT", "TOPLEFT", descriptor.indicators.leaderX, 0)
	leader:SetVertexColor(YxUI:HexToRGB("FFEB3B"))
	leader:Hide()
	local assist = CreateIndicatorTexture(health, "Assist", "LEFT", "TOPLEFT", 3, 0)
	assist:SetVertexColor(YxUI:HexToRGB("FFEB3B"))
	assist:Hide()
	local ready = CreateIndicatorTexture(health, nil, "LEFT", "LEFT", 2, 0)
	local resurrect = CreateIndicatorTexture(health, nil, "LEFT", "LEFT", 2, 0)
	local phase = CreatePhaseIndicator(health, descriptor.indicators.phasePoint)
	local raidTarget = UF:CreateRaidTargetIndicator(health, 16)
	local role
	if descriptor.indicators.role then
		role = CreateIndicatorTexture(health, nil, "LEFT", "LEFT", 2, 0)
	end

	local dispel = CreateDispelIndicator(health, debuffs, descriptor)
	frame:Tag(healthName, Setting(descriptor, "-health-top"))
	frame:Tag(healthBottom, Setting(descriptor, "-health-bottom"))
	frame.Range = {
		insideAlpha = Setting(descriptor, "-in-range") / 100,
		outsideAlpha = Setting(descriptor, "-out-of-range") / 100,
	}
	frame.Health, health.bg, frame.Power, power.bg = health, healthBG, power, powerBG
	frame.HealthName, frame.HealthBottom, frame.Debuffs, frame.Dispel = healthName, healthBottom, debuffs, dispel
	frame.LeaderIndicator, frame.AssistantIndicator, frame.ReadyCheckIndicator = leader, assist, ready
	frame.ResurrectIndicator, frame.RaidTargetIndicator, frame.PhaseIndicator = resurrect, raidTarget, phase
	frame.GroupRoleIndicator = role
	if descriptor.finish then
		descriptor.finish(frame, health)
	end
end

local Operations = {}
local PowerOptions = {element = "Power"}
local DebuffOptions = {element = "Auras", component = "Debuffs"}

function Operations.width(frame, value)
	UF.UnitOperations.Width(UF, frame, value)
end

function Operations.healthHeight(frame, value, descriptor)
	UF.UnitOperations.HealthHeight(UF, frame, value, descriptor.updateOptions)
end

function Operations.textTop(frame, value)
	if frame.HealthName then
		frame:Tag(frame.HealthName, value)
	end
end

function Operations.textBottom(frame, value)
	if frame.HealthBottom then
		frame:Tag(frame.HealthBottom, value)
	end
end

function Operations.healthColor(frame, value)
	UF.UnitOperations.HealthColor(UF, frame, value)
end

function Operations.healthSmooth(frame, value)
	UF:SetBarSmoothing(frame.Health, value)
end

function Operations.powerSmooth(frame, value)
	UF:SetBarSmoothing(frame.Power, value)
end

function Operations.auraWatch(frame, value, descriptor)
	if value and not frame.AuraWatch then
		CreateAuraWatch(frame, frame.Health, descriptor)
	end
	if not frame.AuraWatch then
		return
	end

	if value then
		frame:EnableElement("AuraWatch")
		if frame.AuraWatch.ForceUpdate then
			frame.AuraWatch:ForceUpdate()
		end
	else
		frame:DisableElement("AuraWatch")
	end
end

function Operations.healthOrientation(frame, value)
	frame.Health:SetOrientation(value)
end

function Operations.healthReverse(frame, value)
	UF.UnitOperations.HealthReverse(UF, frame, value)
end

function Operations.powerEnabled(frame, value, descriptor)
	UF.UnitOperations.ElementEnabled(UF, frame, value, PowerOptions)
	frame:SetHeight(Settings[descriptor.prefix .. "-health-height"] + (value and Settings[descriptor.prefix .. "-power-height"] + 3 or 2))
end

function Operations.powerHeight(frame, value, descriptor)
	UF.UnitOperations.PowerHeight(UF, frame, value, descriptor.updateOptions)
end

function Operations.powerReverse(frame, value)
	UF.UnitOperations.PowerReverse(UF, frame, value)
end

function Operations.powerColor(frame, value)
	UF.UnitOperations.PowerColor(UF, frame, value)
end

function Operations.healthTexture(frame, value)
	UF.UnitOperations.HealthTexture(UF, frame, value)
end

function Operations.powerTexture(frame, value)
	UF.UnitOperations.PowerTexture(UF, frame, value)
end

function Operations.debuffs(frame, value)
	UF.UnitOperations.ElementEnabled(UF, frame, value, DebuffOptions)
end

function Operations.role(frame, value)
	if value then
		if not frame.GroupRoleIndicator then
			frame.GroupRoleIndicator = CreateIndicatorTexture(frame.Health, nil, "LEFT", "LEFT", 2, 0)
		end
		frame:EnableElement("GroupRoleIndicator")
		if frame.GroupRoleIndicator.ForceUpdate then
			frame.GroupRoleIndicator:ForceUpdate()
		end
	else
		frame:DisableElement("GroupRoleIndicator")
	end
end

function Operations.highlight(frame, value)
	if value then
		frame.Highlight:Show()
	else
		frame.Highlight:Hide()
	end
end

local function RefreshGroupFont(frame, fontSettings)
	local font, size, flags = fontSettings.font, fontSettings.size, fontSettings.flags
	if frame.HealthName then
		YxUI:SetFontInfo(frame.HealthName, font, size, flags)
	end
	if frame.HealthBottom then
		YxUI:SetFontInfo(frame.HealthBottom, font, size, flags)
	end
	if frame.HealthMiddle then
		YxUI:SetFontInfo(frame.HealthMiddle, font, size, flags)
	end

	if frame.Dispel and frame.Dispel.count then
		YxUI:SetFontInfo(frame.Dispel.count, font, size, flags)
	end

	if frame.AuraWatch then
		for _, icon in pairs(frame.AuraWatch.icons) do
			if icon.count then
				YxUI:SetFontInfo(icon.count, font, 10, flags)
			end
		end
	end
end

function UF:UpdatePetDimensions(prefix)
	self:RunAfterCombat(prefix .. ":dimensions", function()
		local header = YxUI.UnitFrames[prefix]
		if not header then
			return
		end

		local width = Settings[prefix .. "-width"]
		local healthHeight = Settings[prefix .. "-health-height"]
		header:SetAttribute("initial-width", width)
		header:SetAttribute("initial-height", healthHeight + 2)

		local function ResizePet(frame)
			frame:SetSize(width, healthHeight + 2)
			if frame.Health then
				frame.Health:SetHeight(healthHeight)
			end
			if frame.HealBar then
				frame.HealBar:SetSize(width, healthHeight)
			end
			if frame.AbsorbsBar then
				frame.AbsorbsBar:SetSize(width, healthHeight)
			end
		end
		self:ForEachHeaderChild(header, ResizePet)

		if prefix == "party-pets" and self.PartyPetAnchor then
			self:UpdatePartyAnchorSize()
		elseif prefix == "raid-pets" and self.RaidPetAnchor then
			self.RaidPetAnchor:SetHeight(healthHeight * (Settings["raid-max-columns"] + Settings["raid-y-offset"]) - 1)
		end
	end)
end

function UF:UpdateGroupFonts(prefix)
	self:RunAfterCombat(prefix .. ":fonts", function()
		local fontSettings = {
			font = Settings[prefix .. "-font"],
			size = Settings[prefix .. "-font-size"],
			flags = Settings[prefix .. "-font-flags"],
		}
		self:ForEachHeaderChild(YxUI.UnitFrames[prefix], RefreshGroupFont, fontSettings)
		self:ForEachHeaderChild(YxUI.UnitFrames[prefix .. "-pets"], RefreshGroupFont, fontSettings)
	end)
end

local function RefreshGroupRange(frame, data)
	if frame.Range then
		frame.Range[data.field] = data.value
		if frame.Range.ForceUpdate then
			frame.Range:ForceUpdate()
		end
	end
end

function UF:UpdateGroupRange(prefix, field, value)
	local data = {field = field, value = value / 100}
	self:ForEachHeaderChild(YxUI.UnitFrames[prefix], RefreshGroupRange, data)
	self:ForEachHeaderChild(YxUI.UnitFrames[prefix .. "-pets"], RefreshGroupRange, data)
end

function UF:UpdateGroupFrames(descriptor, operation, value)
	if InCombatLockdown() then
		self:RunAfterCombat(descriptor.header .. ":" .. operation, function()
			self:UpdateGroupFrames(descriptor, operation, value)
		end)

		return
	end

	-- Resolve setting keys once per family, then reuse them for every child and
	-- subsequent slider callback. UnitOperations accepts frames directly.
	if not descriptor.updateOptions and (operation == "healthHeight" or operation == "powerHeight") then
		descriptor.updateOptions = {
			healthHeight = descriptor.prefix .. "-health-height",
			powerHeight = descriptor.prefix .. "-power-height",
		}
	end

	local header = YxUI.UnitFrames[descriptor.header]
	if header then
		self:ForEachHeaderChild(header, Operations[operation], value, descriptor)
	end

	if operation == "highlight" then
		self:ForEachHeaderChild(YxUI.UnitFrames[descriptor.petHeader], Operations.highlight, value, descriptor)
	end

	if descriptor.afterUpdate then
		descriptor.afterUpdate(operation)
	end
end

local function SetTestFrame(frame, shown, pet)
	frame.unit = shown and (pet and UnitExists("pet") and "pet" or "player") or nil
	UnregisterUnitWatch(frame)

	if shown then
		RegisterUnitWatch(frame, true)
		frame:Show()
		if frame.UpdateTags then
			frame:UpdateTags()
		end
	else
		frame:Hide()
	end
end

local function UpdateTestChild(frame, shown, descriptor)
	SetTestFrame(frame, shown, descriptor.testingPets)
end

function UF:ToggleGroupTest(descriptor)
	if InCombatLockdown() then
		YxUI:print(ERR_NOT_IN_COMBAT)

		return
	end

	descriptor.testing = not descriptor.testing
	for _, key in ipairs({descriptor.header, descriptor.petHeader}) do
		local header = YxUI.UnitFrames[key]
		if header then
			header:SetAttribute("isTesting", descriptor.testing)

			if header:GetAttribute("startingIndex") ~= descriptor.testStart then
				header:SetAttribute("startingIndex", descriptor.testStart)
			end

			descriptor.testingPets = key == descriptor.petHeader
			self:ForEachHeaderChild(header, UpdateTestChild, descriptor.testing, descriptor)
		end
	end
end
