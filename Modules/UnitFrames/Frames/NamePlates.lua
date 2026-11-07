local addon, ns = ...
local YxUI, Language, Assets, Settings, Defaults = ns:get()

Defaults["nameplates-enable"] = true
Defaults["nameplates-width"] = 138
Defaults["nameplates-height"] = 14
Defaults["nameplates-font"] = "Roboto"
Defaults["nameplates-font-size"] = 12
Defaults["nameplates-font-flags"] = ""
Defaults["nameplates-cc-health"] = false
Defaults["nameplates-top-text"] = ""
Defaults["nameplates-topleft-text"] = "[LevelColor][Level][Plus][ColorStop] [Name(20)]"
Defaults["nameplates-topright-text"] = ""
Defaults["nameplates-bottom-text"] = ""
Defaults["nameplates-bottomleft-text"] = ""
Defaults["nameplates-bottomright-text"] = "[HealthPercent]"
Defaults["nameplates-only-player-debuffs"] = true
Defaults["nameplates-health-color"] = "CLASS"
Defaults["nameplates-health-smooth"] = true
Defaults["nameplates-enable-elite-indicator"] = true
Defaults["nameplates-enable-target-indicator"] = true
Defaults["nameplates-target-indicator-size"] = "SMALL"
Defaults["nameplates-enable-castbar"] = true
Defaults["nameplates-cast-classcolor"] = true
Defaults["nameplates-castbar-height"] = 12
Defaults["nameplates-castbar-enable-icon"] = true
Defaults["nameplates-enable-auras"] = true
Defaults["nameplates-buffs-direction"] = "LTR"
Defaults["nameplates-buff-size"] = 26
Defaults["nameplates-buff-count"] = 5
Defaults["nameplates-debuff-size"] = 26
Defaults["nameplates-debuff-count"] = 5
Defaults["nameplates-debuffs-direction"] = "RTL"
Defaults.NPHealthTexture = "YxUI 4"
Defaults.NPCastTexture = "YxUI 4"

local UF = YxUI:GetModule("Unit Frames")

local GetNamePlates = C_NamePlate.GetNamePlates

local function SetAuraDirection(auras, direction)
	if direction == "LTR" then
		auras.initialAnchor = "TOPLEFT"
		auras["growth-x"] = "RIGHT"
	else
		auras.initialAnchor = "TOPRIGHT"
		auras["growth-x"] = "LEFT"
	end

	auras["growth-y"] = "UP"
end

YxUI.StyleFuncs["nameplate"] = function(self, unit)
	-- The Blizzard nameplate parent already supplies its effective world/UI scale. Applying UIParent's scale here as well would multiply that scale on the child.
	self:SetScale(1)
	self:SetSize(Settings["nameplates-width"], Settings["nameplates-height"])
	self:SetPoint("CENTER", 0, 0)

	local Backdrop = self:CreateTexture(nil, "BACKGROUND")
	Backdrop:SetAllPoints()
	Backdrop:SetTexture(Assets:GetTexture("Blank"))
	Backdrop:SetVertexColor(0, 0, 0)

	self.colors.debuff = YxUI.DebuffColors

	-- Health Bar
	local Health = CreateFrame("StatusBar", nil, self)
	Health:SetPoint("TOPLEFT", self, 1, -1)
	Health:SetPoint("BOTTOMRIGHT", self, -1, 1)
	Health:SetStatusBarTexture(Assets:GetTexture(Settings.NPHealthTexture))
	Health:EnableMouse(false)

	local HealBar = CreateFrame("StatusBar", nil, Health)
	HealBar:SetWidth(Settings["nameplates-width"])
	HealBar:SetHeight(Settings["nameplates-height"])
	HealBar:SetPoint("LEFT", Health:GetStatusBarTexture(), "RIGHT", 0, 0)
	HealBar:SetStatusBarTexture(Assets:GetTexture(Settings.NPHealthTexture))
	HealBar:SetStatusBarColor(0, 0.48, 0)

	self.HealBar = HealBar

	if YxUI.IsMainline then
		local AbsorbsBar = CreateFrame("StatusBar", nil, Health)
		AbsorbsBar:SetWidth(Settings["nameplates-width"])
		AbsorbsBar:SetHeight(Settings["nameplates-height"])
		AbsorbsBar:SetPoint("LEFT", Health:GetStatusBarTexture(), "RIGHT", 0, 0)
		AbsorbsBar:SetStatusBarTexture(Assets:GetTexture(Settings.NPHealthTexture))
		AbsorbsBar:SetStatusBarColor(0, 0.66, 1)

		self.AbsorbsBar = AbsorbsBar
	end

	local HealthBG = self:CreateTexture(nil, "BORDER")
	HealthBG:SetAllPoints(Health)
	HealthBG:SetTexture(Assets:GetTexture(Settings.NPHealthTexture))
	HealthBG.multiplier = 0.2

	-- Target Icon
	local RaidTargetIndicator = Health:CreateTexture(nil, 'OVERLAY')
	RaidTargetIndicator:SetSize(16, 16)
	RaidTargetIndicator:SetPoint("LEFT", Health, "RIGHT", 5, 0)

	local Top = Health:CreateFontString(nil, "OVERLAY")
	YxUI:SetFontInfo(Top, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	Top:SetPoint("CENTER", Health, "TOP", 0, 3)
	Top:SetJustifyH("CENTER")

	local TopLeft = Health:CreateFontString(nil, "OVERLAY")
	YxUI:SetFontInfo(TopLeft, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	TopLeft:SetPoint("LEFT", Health, "TOPLEFT", 4, 3)
	TopLeft:SetJustifyH("LEFT")

	local TopRight = Health:CreateFontString(nil, "OVERLAY")
	YxUI:SetFontInfo(TopRight, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	TopRight:SetPoint("RIGHT", Health, "TOPRIGHT", -4, 3)
	TopRight:SetJustifyH("RIGHT")

	local Bottom = Health:CreateFontString(nil, "OVERLAY")
	YxUI:SetFontInfo(Bottom, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	Bottom:SetPoint("CENTER", Health, "BOTTOM", 0, -3)
	Bottom:SetJustifyH("CENTER")

	local BottomRight = Health:CreateFontString(nil, "OVERLAY")
	YxUI:SetFontInfo(BottomRight, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	BottomRight:SetPoint("RIGHT", Health, "BOTTOMRIGHT", -4, -3)
	BottomRight:SetJustifyH("RIGHT")

	local BottomLeft = Health:CreateFontString(nil, "OVERLAY")
	YxUI:SetFontInfo(BottomLeft, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	BottomLeft:SetPoint("LEFT", Health, "BOTTOMLEFT", 4, -3)
	BottomLeft:SetJustifyH("LEFT")

	--[[local InsideCenter = Health:CreateFontString(nil, "OVERLAY")
	YxUI:SetFontInfo(InsideCenter, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	InsideCenter:SetPoint("CENTER", Health, 0, 0)
	InsideCenter:SetJustifyH("CENTER")]]

	Health.Smooth = Settings["nameplates-health-smooth"]
	Health.colorTapping = true
	Health.colorDisconnected = true

	UF:SetHealthAttributes(Health, Settings["nameplates-health-color"])

	local Threat = CreateFrame("Frame", nil, Health)
	Threat:SetAllPoints(Health)
	Threat:SetFrameLevel(Health:GetFrameLevel() - 1)
	Threat.feedbackUnit = "player"
	Threat.PostUpdate = UF.NPThreatPostUpdate

	Threat.Top = Threat:CreateTexture(nil, "BORDER")
	Threat.Top:SetHeight(6)
	Threat.Top:SetPoint("BOTTOMLEFT", Threat, "TOPLEFT", 8, 1)
	Threat.Top:SetPoint("BOTTOMRIGHT", Threat, "TOPRIGHT", -8, 1)
	Threat.Top:SetTexture(Assets:GetTexture("RenHorizonUp"))
	Threat.Top:SetAlpha(0.8)

	Threat.Bottom = Threat:CreateTexture(nil, "BORDER")
	Threat.Bottom:SetHeight(6)
	Threat.Bottom:SetPoint("TOPLEFT", Threat, "BOTTOMLEFT", 8, -1)
	Threat.Bottom:SetPoint("TOPRIGHT", Threat, "BOTTOMRIGHT", -8, -1)
	Threat.Bottom:SetTexture(Assets:GetTexture("RenHorizonDown"))
	Threat.Bottom:SetAlpha(0.8)

	-- Buffs
	if Settings["nameplates-enable-auras"] then
		local Buffs = CreateFrame("Frame", nil, self)
		Buffs:SetSize(Settings["nameplates-width"], Settings["nameplates-buff-size"])
		Buffs:SetPoint("BOTTOM", self, "TOP", 0, 10)
		Buffs.size = Settings["nameplates-buff-size"]
		Buffs.spacing = 2
		Buffs.num = Settings["nameplates-buff-count"]
		Buffs.PostCreateIcon = UF.PostCreateIcon
		Buffs.PostUpdateIcon = UF.PostUpdateIcon

		SetAuraDirection(Buffs, Settings["nameplates-buffs-direction"])

		self.Buffs = Buffs
	end

	-- Debuffs
	local Debuffs = CreateFrame("Frame", nil, self)
	Debuffs:SetSize(Settings["nameplates-width"], Settings["nameplates-debuff-size"])
	Debuffs.size = Settings["nameplates-debuff-size"]
	Debuffs.spacing = 2
	Debuffs.num = Settings["nameplates-debuff-count"]
	Debuffs.numRow = Settings["nameplates-debuff-count"]
	Debuffs.PostCreateIcon = UF.PostCreateIcon
	Debuffs.PostUpdateIcon = UF.PostUpdateIcon
	Debuffs.onlyShowPlayer = Settings["nameplates-only-player-debuffs"]
	Debuffs.showStealableBuffs = true
	Debuffs.disableMouse = true

	SetAuraDirection(Debuffs, Settings["nameplates-debuffs-direction"])

	if Settings["nameplates-enable-auras"] then
		Debuffs:SetPoint("BOTTOM", self.Buffs, "TOP", 0, 2)
	else
		Debuffs:SetPoint("BOTTOM", self, "TOP", 0, 10)
	end

	-- Castbar
	local Castbar = CreateFrame("StatusBar", nil, self)
	Castbar:SetSize(Settings["nameplates-width"] - 2, Settings["nameplates-castbar-height"])
	Castbar:SetPoint("TOP", Health, "BOTTOM", 0, -4)
	Castbar:SetStatusBarTexture(Assets:GetTexture(Settings.NPCastTexture))

	local CastbarBG = Castbar:CreateTexture(nil, "ARTWORK")
	CastbarBG:SetPoint("TOPLEFT", Castbar, 0, 0)
	CastbarBG:SetPoint("BOTTOMRIGHT", Castbar, 0, 0)
	CastbarBG:SetTexture(Assets:GetTexture(Settings.NPCastTexture))
	CastbarBG:SetAlpha(0.2)

	local Background = Castbar:CreateTexture(nil, "BACKGROUND")
	Background:SetPoint("TOPLEFT", Castbar, -1, 1)
	Background:SetPoint("BOTTOMRIGHT", Castbar, 1, -1)
	Background:SetTexture(Assets:GetTexture("Blank"))
	Background:SetVertexColor(0, 0, 0)

	local Time = Castbar:CreateFontString(nil, "OVERLAY")
	YxUI:SetFontInfo(Time, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	Time:SetPoint("RIGHT", Castbar, "BOTTOMRIGHT", -4, -3)
	Time:SetJustifyH("RIGHT")

	local Text = Castbar:CreateFontString(nil, "OVERLAY")
	YxUI:SetFontInfo(Text, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	Text:SetPoint("LEFT", Castbar, "BOTTOMLEFT", 4, -3)
	Text:SetWidth(Settings["nameplates-width"] / 2 + 4)
	Text:SetJustifyH("LEFT")

	local Icon = Castbar:CreateTexture(nil, "OVERLAY")
	Icon:SetSize(Settings["nameplates-height"] + 12 + 2, Settings["nameplates-height"] + 12 + 2)
	Icon:SetPoint("BOTTOMRIGHT", Castbar, "BOTTOMLEFT", -4, 0)
	Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

	local IconBG = Castbar:CreateTexture(nil, "BACKGROUND")
	IconBG:SetPoint("TOPLEFT", Icon, -1, 1)
	IconBG:SetPoint("BOTTOMRIGHT", Icon, 1, -1)
	IconBG:SetTexture(Assets:GetTexture("Blank"))
	IconBG:SetVertexColor(0, 0, 0)

	Castbar.bg = CastbarBG
	Castbar.Time = Time
	Castbar.Text = Text
	Castbar.Icon = Icon
	Castbar.showTradeSkills = true
	Castbar.timeToHold = 0.7
	Castbar.ClassColor = Settings["nameplates-cast-classcolor"]
	Castbar.PostCastStart = UF.PostCastStart
	Castbar.PostCastStop = UF.PostCastStop
	Castbar.PostCastFail = UF.PostCastFail
	Castbar.PostCastInterruptible = UF.PostCastInterruptible

	--[[ Elite icon
	local EliteIndicator = Health:CreateTexture(nil, "OVERLAY")
	EliteIndicator:SetSize(16, 16)
	EliteIndicator:SetPoint("RIGHT", Health, "LEFT", -1, 0)
	EliteIndicator:SetTexture(Assets:GetTexture("Small Star"))
	EliteIndicator:Hide()]]

	-- Target
	local TargetIndicator = CreateFrame("Frame", nil, self)
	TargetIndicator:SetPoint("TOPLEFT", Health, 0, 0)
	TargetIndicator:SetPoint("BOTTOMRIGHT", Health, 0, 0)
	TargetIndicator:Hide()

	TargetIndicator.Left = TargetIndicator:CreateTexture(nil, "ARTWORK")
	TargetIndicator.Left:SetSize(16, 16)
	TargetIndicator.Left:SetPoint("RIGHT", TargetIndicator, "LEFT", 2, 0)
	TargetIndicator.Left:SetVertexColor(YxUI:HexToRGB(Settings["ui-widget-color"]))

	TargetIndicator.Right = TargetIndicator:CreateTexture(nil, "ARTWORK")
	TargetIndicator.Right:SetSize(16, 16)
	TargetIndicator.Right:SetPoint("LEFT", TargetIndicator, "RIGHT", -3, 0)
	TargetIndicator.Right:SetVertexColor(YxUI:HexToRGB(Settings["ui-widget-color"]))

	if Settings["nameplates-target-indicator-size"] == "SMALL" then
		TargetIndicator.Left:SetTexture(Assets:GetTexture("Arrow Left"))
		TargetIndicator.Right:SetTexture(Assets:GetTexture("Arrow Right"))
	elseif Settings["nameplates-target-indicator-size"] == "LARGE" then
		TargetIndicator.Left:SetTexture(Assets:GetTexture("Arrow Left Large"))
		TargetIndicator.Right:SetTexture(Assets:GetTexture("Arrow Right Large"))
	elseif Settings["nameplates-target-indicator-size"] == "HUGE" then
		TargetIndicator.Left:SetTexture(Assets:GetTexture("Arrow Left Huge"))
		TargetIndicator.Right:SetTexture(Assets:GetTexture("Arrow Right Huge"))
	end

	self:Tag(Top, Settings["nameplates-top-text"])
	self:Tag(TopLeft, Settings["nameplates-topleft-text"])
	self:Tag(TopRight, Settings["nameplates-topright-text"])
	self:Tag(Bottom, Settings["nameplates-bottom-text"])
	self:Tag(BottomRight, Settings["nameplates-bottomright-text"])
	self:Tag(BottomLeft, Settings["nameplates-bottomleft-text"])

	self.Health = Health
	self.Top = Top
	self.TopLeft = TopLeft
	self.TopRight = TopRight
	self.Bottom = Bottom
	self.BottomRight = BottomRight
	self.BottomLeft = BottomLeft
	self.Health.bg = HealthBG
	self.Debuffs = Debuffs
	self.Castbar = Castbar
	--self.EliteIndicator = EliteIndicator
	self.TargetIndicator = TargetIndicator
	self.ThreatIndicator = Threat
	self.RaidTargetIndicator = RaidTargetIndicator
end

UF.NamePlateCVars = {
	nameplateGlobalScale = 1,
	NamePlateHorizontalScale = 1,
	NamePlateVerticalScale = 1,
	nameplateLargerScale = 1,
	nameplateMaxScale = 1,
	nameplateMinScale = 1,
	nameplateSelectedScale = 1,
	nameplateSelfScale = 1,
}

function UF:CreateNamePlateDriver()
	if self.NamePlateDriver then
		return
	end
	local driver = CreateFrame("Frame", "YxUINamePlateDriver")
	self.NamePlateDriver = driver
	self.NamePlatesByUnit = {}
	local function ApplyCVars()
		for cvar, value in next, self.NamePlateCVars do
			C_CVar.SetCVar(cvar, value)
		end
	end

	local suppressedArtwork = setmetatable({}, {__mode = "k"})
	local function SuppressAlpha(object)
		if not object or (object.IsForbidden and object:IsForbidden()) or suppressedArtwork[object] then
			return
		end
		suppressedArtwork[object] = true
		local updating = false
		hooksecurefunc(object, "SetAlpha", function()
			if updating then
				return
			end
			updating = true
			object:SetAlpha(0)
			updating = false
		end)
		object:SetAlpha(0)
	end

	local hiddenArtwork = setmetatable({}, {__mode = "k"})
	local function HideArtwork(frame)
		if not frame or frame:IsForbidden() then
			return
		end
		if hiddenArtwork[frame] then
			return
		end
		hiddenArtwork[frame] = true
		frame:HookScript("OnShow", function(self) self:Hide() end)
		frame:Hide()
	end

	local scannedRegionCounts = setmetatable({}, {__mode = "k"})
	local auraContainers = {"BuffFrame", "buffFrame", "DebuffFrame", "debuffFrame", "Auras", "auras", "AuraContainer"}

	local function SuppressRegions(region, ...)
		if not region then
			return
		end
		SuppressAlpha(region)
		return SuppressRegions(...)
	end

	local SuppressBlizzardArtwork
	local function SuppressChildren(blizzard, plate, ancestors, child, ...)
		if not child then
			return
		end
		SuppressBlizzardArtwork(child, blizzard, plate, ancestors)
		return SuppressChildren(blizzard, plate, ancestors, ...)
	end

	SuppressBlizzardArtwork = function(frame, blizzard, plate, ancestors)
		if frame == plate or frame == blizzard.WidgetContainer or frame:IsForbidden() then
			return
		end
		if not ancestors[frame] then
			HideArtwork(frame)
		end
		local count = frame:GetNumRegions()
		local secretCount = issecretvalue and issecretvalue(count)
		if secretCount or scannedRegionCounts[frame] ~= count then
			if secretCount or count > 0 then
				SuppressRegions(frame:GetRegions())
			end
			if not secretCount then
				scannedRegionCounts[frame] = count
			end
		end
		SuppressChildren(blizzard, plate, ancestors, frame:GetChildren())
	end

	function self:SuppressBlizzardNamePlate(blizzard, plate)
		if blizzard:IsForbidden() then
			return
		end
		local ancestors = plate._suppressionAncestors
		if ancestors then
			wipe(ancestors)
		else
			ancestors = {}
			plate._suppressionAncestors = ancestors
		end
		local parent = plate:GetParent()
		while parent do
			ancestors[parent] = true
			parent = parent:GetParent()
		end
		SuppressAlpha(blizzard.name)
		for i = 1, #auraContainers do
			local container = blizzard[auraContainers[i]]
			if container and not ancestors[container] then
				HideArtwork(container)
			end
		end
		SuppressBlizzardArtwork(blizzard, blizzard, plate, ancestors)
	end

	local function Added(unit)
		local base = C_NamePlate.GetNamePlateForUnit(unit)
		if not base or base:IsForbidden() then
			return
		end
		local blizzard = base.UnitFrame or base.unitFrame
		if not blizzard or blizzard:IsForbidden() then
			return
		end
		local parent = (blizzard.HealthBarsContainer and blizzard.HealthBarsContainer.healthBar) or blizzard.healthBar or blizzard.healthbar or blizzard
		if parent:IsForbidden() then
			return
		end
		local plate = base._unitFrame
		if not plate then
			-- Inherit visibility from the rendered native bar, not its world-space
			-- base, which can remain alive while the bar is hidden.
			plate = YxUI.UnitFrames:CreateNamePlateButton(parent, unit, YxUI.StyleFuncs.nameplate)
			base._unitFrame = plate
		else
			plate._nameplateRebinding = true
			plate:SetParent(parent)
		end
		self:SuppressBlizzardNamePlate(blizzard, plate)
		YxUI.UnitFrames:SetNamePlateUnit(plate, unit, true)
		self.NamePlatesByUnit[unit] = plate
		UF.NamePlateCallback(plate)
		plate:Refresh("NAME_PLATE_UNIT_ADDED")
		plate._nameplateRebinding = nil
	end

	local function Removed(unit)
		local plate = self.NamePlatesByUnit[unit]
		if not plate then
			return
		end
		YxUI.UnitFrames:SetNamePlateUnit(plate, nil)
		self.NamePlatesByUnit[unit] = nil
	end

	-- Blizzard initializes its nameplate CVars during login. Apply ours at the same point so those defaults cannot overwrite YxUI's 1:1 nameplate scale afterwards.
	if IsLoggedIn() then
		ApplyCVars()
	else
		driver:RegisterEvent("PLAYER_LOGIN")
	end
	-- Observe additions after Blizzard has assigned its unit frame, including
	-- clients that acquire a different pooled frame on every addition.
	if NamePlateDriverFrame and type(NamePlateDriverFrame.OnNamePlateAdded) == "function" then
		hooksecurefunc(NamePlateDriverFrame, "OnNamePlateAdded", function(_, unit)
			Added(unit)
		end)
	else
		driver:RegisterEvent("NAME_PLATE_UNIT_ADDED")
	end
	driver:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
	driver:RegisterEvent("PLAYER_TARGET_CHANGED")
	driver:SetScript("OnEvent", function(_, event, unit)
		if event == "PLAYER_LOGIN" then
			ApplyCVars()
			driver:UnregisterEvent("PLAYER_LOGIN")
		elseif event == "NAME_PLATE_UNIT_ADDED" then
			Added(unit)
		elseif event == "NAME_PLATE_UNIT_REMOVED" then
			Removed(unit)
		else
			local plate = C_NamePlate.GetNamePlateForUnit("target")
			plate = plate and plate._unitFrame
			if plate then
				plate:Refresh(event)
			end
		end
	end)
end

local namePlateStyleRevision = 0

local function InvalidateNamePlateStyle()
	namePlateStyleRevision = namePlateStyleRevision + 1
end

local UpdateAuraLayout

UF.NamePlateCallback = function(plate)
	if not plate or plate._namePlateStyleRevision == namePlateStyleRevision then
		return
	end

	if Settings["nameplates-enable-auras"] then
		plate:EnableElement("Auras")
	else
		plate:DisableElement("Auras")
	end

	if Settings["nameplates-enable-target-indicator"] then
		plate:EnableElement("TargetIndicator")

		if Settings["nameplates-target-indicator-size"] == "SMALL" then
			plate.TargetIndicator.Left:SetTexture(Assets:GetTexture("Arrow Left"))
			plate.TargetIndicator.Right:SetTexture(Assets:GetTexture("Arrow Right"))
		elseif Settings["nameplates-target-indicator-size"] == "LARGE" then
			plate.TargetIndicator.Left:SetTexture(Assets:GetTexture("Arrow Left Large"))
			plate.TargetIndicator.Right:SetTexture(Assets:GetTexture("Arrow Right Large"))
		elseif Settings["nameplates-target-indicator-size"] == "HUGE" then
			plate.TargetIndicator.Left:SetTexture(Assets:GetTexture("Arrow Left Huge"))
			plate.TargetIndicator.Right:SetTexture(Assets:GetTexture("Arrow Right Huge"))
		end
	else
		plate:DisableElement("TargetIndicator")
	end

	if Settings["nameplates-enable-castbar"] then
		plate:EnableElement("Castbar")
	else
		plate:DisableElement("Castbar")
	end

	if plate.Buffs then
		SetAuraDirection(plate.Buffs, Settings["nameplates-buffs-direction"])
	end

	if plate.Debuffs then
		plate.Debuffs.onlyShowPlayer = Settings["nameplates-only-player-debuffs"]

		SetAuraDirection(plate.Debuffs, Settings["nameplates-debuffs-direction"])
	end
	UpdateAuraLayout(plate)

	if plate.Health then
		UF:SetBarSmoothing(plate.Health, Settings["nameplates-health-smooth"])
	end
	if plate.Castbar then
		plate.Castbar.ClassColor = Settings["nameplates-cast-classcolor"]
	end

	plate:SetSize(Settings["nameplates-width"], Settings["nameplates-height"])
	plate.Castbar:SetHeight(Settings["nameplates-castbar-height"])
	plate.Castbar:SetStatusBarTexture(Assets:GetTexture(Settings.NPCastTexture))
	plate.Castbar.bg:SetTexture(Assets:GetTexture(Settings.NPCastTexture))

	plate.Health:SetStatusBarTexture(Assets:GetTexture(Settings.NPHealthTexture))
	plate.Health.bg:SetTexture(Assets:GetTexture(Settings.NPHealthTexture))

	if plate.HealBar then
		plate.HealBar:SetStatusBarTexture(Assets:GetTexture(Settings.NPHealthTexture))
	end

	if plate.AbsorbsBar then
		plate.AbsorbsBar:SetStatusBarTexture(Assets:GetTexture(Settings.NPHealthTexture))
	end

	YxUI:SetFontInfo(plate.Top, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	YxUI:SetFontInfo(plate.TopLeft, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	YxUI:SetFontInfo(plate.TopRight, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	YxUI:SetFontInfo(plate.Bottom, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	YxUI:SetFontInfo(plate.BottomRight, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	YxUI:SetFontInfo(plate.BottomLeft, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	YxUI:SetFontInfo(plate.Castbar.Time, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	YxUI:SetFontInfo(plate.Castbar.Text, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	plate._namePlateStyleRevision = namePlateStyleRevision
end

local RunForAllNamePlates = function(func, value)
	local NamePlates = GetNamePlates()

	if NamePlates then
		for i = 1, #NamePlates do
			if NamePlates[i]._unitFrame then
				func(NamePlates[i]._unitFrame, value)
			end
		end
	end
end

local NamePlatesUpdateEnableAuras = function(self, value)
	if value then
		self:EnableElement("Auras")
	else
		self:DisableElement("Auras")
	end
end

local UpdateNamePlatesEnableAuras = function(value)
	InvalidateNamePlateStyle()
	RunForAllNamePlates(NamePlatesUpdateEnableAuras, value)
end

local NamePlatesUpdateShowPlayerDebuffs = function(self)
	if self.Debuffs then
		self.Debuffs.onlyShowPlayer = Settings["nameplates-only-player-debuffs"]
		self.Debuffs:ForceUpdate()
	end
end

local UpdateNamePlatesShowPlayerDebuffs = function(value)
	InvalidateNamePlateStyle()
	RunForAllNamePlates(NamePlatesUpdateShowPlayerDebuffs, value)
end

local NamePlateSetWidth = function(self)
	self:SetWidth(Settings["nameplates-width"])
end

local UpdateNamePlatesWidth = function()
	InvalidateNamePlateStyle()
	RunForAllNamePlates(NamePlateSetWidth)
end

local NamePlateSetHeight = function(self)
	self:SetHeight(Settings["nameplates-height"])
end

local UpdateNamePlatesHeight = function()
	InvalidateNamePlateStyle()
	RunForAllNamePlates(NamePlateSetHeight)
end

local NamePlateSetHealthColor = function(self)
	if self.Health then
		UF:SetHealthAttributes(self.Health, Settings["nameplates-health-color"])
		self.Health:ForceUpdate()
	end
end

local UpdateNamePlatesHealthColor = function()
	InvalidateNamePlateStyle()
	RunForAllNamePlates(NamePlateSetHealthColor)
end

local NamePlateSetHealthSmooth = function(self, value)
	if self.Health then
		UF:SetBarSmoothing(self.Health, value)
		if self.Health.ForceUpdate then
			self.Health:ForceUpdate()
		end
	end
end

local UpdateNamePlatesHealthSmooth = function(value)
	InvalidateNamePlateStyle()
	RunForAllNamePlates(NamePlateSetHealthSmooth, value)
end

local NamePlateSetCastClassColor = function(self, value)
	local castbar = self.Castbar
	if not castbar then
		return
	end

	castbar.ClassColor = value
	if castbar.casting or castbar.channeling or castbar.empowering then
		UF.PostCastInterruptible(castbar)
	end
end

local UpdateNamePlatesCastClassColor = function(value)
	InvalidateNamePlateStyle()
	RunForAllNamePlates(NamePlateSetCastClassColor, value)
end

local NamePlateSetTargetHightlight = function(self, value)
	if not self.TargetIndicator then
		return
	end

	if value then
		self:EnableElement("TargetIndicator")
	else
		self:DisableElement("TargetIndicator")
	end
end

local UpdateNamePlatesTargetHighlight = function(value)
	InvalidateNamePlateStyle()
	RunForAllNamePlates(NamePlateSetTargetHightlight, value)
end

local NamePlateSetFont = function(self)
	YxUI:SetFontInfo(self.Top, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	YxUI:SetFontInfo(self.TopLeft, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	YxUI:SetFontInfo(self.TopRight, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	YxUI:SetFontInfo(self.Bottom, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	YxUI:SetFontInfo(self.BottomRight, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
	YxUI:SetFontInfo(self.BottomLeft, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])

	if self.Castbar then
		if self.Castbar.Time then
			YxUI:SetFontInfo(self.Castbar.Time, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
		end

		if self.Castbar.Text then
			YxUI:SetFontInfo(self.Castbar.Text, Settings["nameplates-font"], Settings["nameplates-font-size"], Settings["nameplates-font-flags"])
		end
	end
end

local UpdateNamePlatesFont = function()
	InvalidateNamePlateStyle()
	RunForAllNamePlates(NamePlateSetFont)
end

local NamePlateEnableCastBars = function(self, value)
	if not self.Castbar then
		return
	end

	if value then
		self:EnableElement("Castbar")
	else
		self:DisableElement("Castbar")
	end
end

local UpdateNamePlatesEnableCastBars = function(value)
	InvalidateNamePlateStyle()
	RunForAllNamePlates(NamePlateEnableCastBars, value)
end

local NamePlateSetCastBarsHeight = function(self, value)
	if self.Castbar then
		self.Castbar:SetHeight(value)
	end
end

local UpdateNamePlatesCastBarsHeight = function(value)
	InvalidateNamePlateStyle()
	RunForAllNamePlates(NamePlateSetCastBarsHeight, value)
end

local NamePlateSetTargetIndicatorSize = function(self, value)
	if not self.TargetIndicator or not self.TargetIndicator.Left or not self.TargetIndicator.Right then
		return
	end

	if value == "SMALL" then
		self.TargetIndicator.Left:SetTexture(Assets:GetTexture("Arrow Left"))
		self.TargetIndicator.Right:SetTexture(Assets:GetTexture("Arrow Right"))
	elseif value == "LARGE" then
		self.TargetIndicator.Left:SetTexture(Assets:GetTexture("Arrow Left Large"))
		self.TargetIndicator.Right:SetTexture(Assets:GetTexture("Arrow Right Large"))
	elseif value == "HUGE" then
		self.TargetIndicator.Left:SetTexture(Assets:GetTexture("Arrow Left Huge"))
		self.TargetIndicator.Right:SetTexture(Assets:GetTexture("Arrow Right Huge"))
	end
end

local UpdateNamePlatesTargetIndicatorSize = function(value)
	InvalidateNamePlateStyle()
	RunForAllNamePlates(NamePlateSetTargetIndicatorSize, value)
end

local AuraContainers = {"Buffs", "Debuffs"}
UpdateAuraLayout = function(self)
	for _, kind in ipairs(AuraContainers) do
		local container = self[kind]
		if container then
			local prefix = kind == "Buffs" and "nameplates-buff-" or "nameplates-debuff-"
			local size = Settings[prefix .. "size"]
			container.size = size
			container.num = Settings[prefix .. "count"]
			container:SetHeight(size)
			if kind == "Debuffs" then
				container.numRow = container.num
			end
			for index = 1, #container do
				local icon = container[index]
				if icon then
					icon:SetSize(size, size)
				end
			end
			if container.ForceUpdate then
				container:ForceUpdate()
			end
		end
	end
end

local function UpdateNamePlatesAuraLayout()
	UF:RunAfterCombat("nameplates:auraLayout", function()
		InvalidateNamePlateStyle()
		RunForAllNamePlates(UpdateAuraLayout)
	end)
end

local NamePlateSetBuffDirection = function(self, value)
	if not self.Buffs then
		return
	end

	SetAuraDirection(self.Buffs, Settings["nameplates-buffs-direction"])

	self.Buffs:ForceUpdate()
end

local UpdateNamePlatesBuffDirection = function(value)
	InvalidateNamePlateStyle()
	RunForAllNamePlates(NamePlateSetBuffDirection, value)
end

local NamePlateSetDebuffDirection = function(self, value)
	if not self.Debuffs then
		return
	end

	SetAuraDirection(self.Debuffs, Settings["nameplates-debuffs-direction"])

	self.Debuffs:ForceUpdate()
end

local UpdateNamePlatesDebuffDirection = function(value)
	InvalidateNamePlateStyle()
	RunForAllNamePlates(NamePlateSetDebuffDirection, value)
end

local SetHealthTexture = function(self, value)
	local Texture = Assets:GetTexture(value)

	if self.Health then
		self.Health:SetStatusBarTexture(Texture)

		if self.Health.bg then
			self.Health.bg:SetTexture(Texture)
		end
	end

	if self.HealBar then
		self.HealBar:SetStatusBarTexture(Texture)
	end

	if self.AbsorbsBar then
		self.AbsorbsBar:SetStatusBarTexture(Texture)
	end
end

local UpdateHealthTexture = function(value)
	InvalidateNamePlateStyle()
	RunForAllNamePlates(SetHealthTexture, value)
end

local SetCastTexture = function(self, value)
	if self.Castbar then
		local Texture = Assets:GetTexture(value)

		self.Castbar:SetStatusBarTexture(Texture)

		if self.Castbar.bg then
			self.Castbar.bg:SetTexture(Texture)
		end
	end
end

local UpdateCastTexture = function(value)
	InvalidateNamePlateStyle()
	RunForAllNamePlates(SetCastTexture, value)
end

YxUI:GetModule("GUI"):AddWidgetsID("General", "Name Plates", function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("nameplates-enable", Settings["nameplates-enable"], Language["Enable Name Plates"], Language["Enable the YxUI name plates module"], ReloadUI):RequiresReload(true)

	left:CreateHeader(Language["Font"])
	left:CreateDropdown("nameplates-font", Settings["nameplates-font"], Assets:GetFontList(), Language["Font"], Language["Set the font of the name plates"], UpdateNamePlatesFont, "Font")
	left:CreateSlider("nameplates-font-size", Settings["nameplates-font-size"], 8, 32, 1, Language["Font Size"], Language["Set the font size of the name plates"], UpdateNamePlatesFont)
	left:CreateDropdown("nameplates-font-flags", Settings["nameplates-font-flags"], Assets:GetFlagsList(), Language["Font Flags"], Language["Set the font flags of the name plates"], UpdateNamePlatesFont)

	left:CreateHeader(Language["Health"])
	left:CreateSlider("nameplates-width", Settings["nameplates-width"], 60, 220, 1, Language["Set Width"], Language["Set the width of name plates"], UpdateNamePlatesWidth)
	left:CreateSlider("nameplates-height", Settings["nameplates-height"], 4, 50, 1, Language["Set Height"], Language["Set the height of name plates"], UpdateNamePlatesHeight)
	left:CreateDropdown("nameplates-health-color", Settings["nameplates-health-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Custom"]] = "CUSTOM", [Language["Blizzard"]] = "BLIZZARD", [Language["Threat"]] = "THREAT"}, Language["Health Bar Color"], Language["Set the color of the health bar"], UpdateNamePlatesHealthColor)
	left:CreateSwitch("nameplates-health-smooth", Settings["nameplates-health-smooth"], Language["Smooth Health"], Language["Animate health changes"], UpdateNamePlatesHealthSmooth)
	left:CreateDropdown("NPHealthTexture", Settings.NPHealthTexture, Assets:GetTextureList(), Language["Health Texture"], "", UpdateHealthTexture, "Texture")

	left:CreateHeader(Language["Buffs"])
	left:CreateSwitch("nameplates-enable-auras", Settings["nameplates-enable-auras"], Language["Enable Buffs"], Language["Display buffs above nameplates"], UpdateNamePlatesEnableAuras)
	left:CreateSlider("nameplates-buff-size", Settings["nameplates-buff-size"], 12, 40, 1, Language["Buff Icon Size"], Language["Size of nameplate buff icons"], UpdateNamePlatesAuraLayout)
	left:CreateSlider("nameplates-buff-count", Settings["nameplates-buff-count"], 1, 12, 1, Language["Max Buffs"], Language["Maximum buffs shown per nameplate"], UpdateNamePlatesAuraLayout)
	left:CreateDropdown("nameplates-buffs-direction", Settings["nameplates-buffs-direction"], {[Language["Left to Right"]] = "LTR", [Language["Right to Left"]] = "RTL"}, Language["Buff Direction"], Language["Set which direction the buffs will grow towards"], UpdateNamePlatesBuffDirection)

	left:CreateHeader(Language["Debuffs"])
	left:CreateSlider("nameplates-debuff-size", Settings["nameplates-debuff-size"], 12, 40, 1, Language["Debuff Icon Size"], Language["Size of nameplate debuff icons"], UpdateNamePlatesAuraLayout)
	left:CreateSlider("nameplates-debuff-count", Settings["nameplates-debuff-count"], 1, 12, 1, Language["Max Debuffs"], Language["Maximum debuffs shown per nameplate"], UpdateNamePlatesAuraLayout)
	left:CreateSwitch("nameplates-only-player-debuffs", Settings["nameplates-only-player-debuffs"], Language["Only Display Player Debuffs"], Language["If enabled, only your own debuffs will be displayed"], UpdateNamePlatesShowPlayerDebuffs)
	left:CreateDropdown("nameplates-debuffs-direction", Settings["nameplates-debuffs-direction"], {[Language["Left to Right"]] = "LTR", [Language["Right to Left"]] = "RTL"}, Language["Debuff Direction"], Language["Set which direction the debuffs will grow towards"], UpdateNamePlatesDebuffDirection)

	right:CreateHeader(Language["Information"])
	right:CreateTagInput("nameplates-top-text", Settings["nameplates-top-text"], Language["Top Text"], "")
	right:CreateTagInput("nameplates-topleft-text", Settings["nameplates-topleft-text"], Language["Top Left Text"], "")
	right:CreateTagInput("nameplates-topright-text", Settings["nameplates-topright-text"], Language["Top Right Text"], "")
	right:CreateTagInput("nameplates-bottom-text", Settings["nameplates-bottom-text"], Language["Bottom Text"], "")
	right:CreateTagInput("nameplates-bottomleft-text", Settings["nameplates-bottomleft-text"], Language["Bottom Left Text"], "")
	right:CreateTagInput("nameplates-bottomright-text", Settings["nameplates-bottomright-text"], Language["Bottom Right Text"], "")

	right:CreateHeader(Language["Casting Bar"])
	right:CreateSwitch("nameplates-enable-castbar", Settings["nameplates-enable-castbar"], Language["Enable Casting Bar"], Language["Enable cast bars on nameplates"], UpdateNamePlatesEnableCastBars)
	right:CreateSwitch("nameplates-cast-classcolor", Settings["nameplates-cast-classcolor"], Language["Enable Class Color"], Language["Use class colors"], UpdateNamePlatesCastClassColor)
	right:CreateSlider("nameplates-castbar-height", Settings["nameplates-castbar-height"], 3, 28, 1, Language["Set Height"], Language["Set the height of name plate casting bars"], UpdateNamePlatesCastBarsHeight)
	right:CreateDropdown("NPCastTexture", Settings.NPCastTexture, Assets:GetTextureList(), Language["Castbar Texture"], "", UpdateCastTexture, "Texture")

	right:CreateHeader(Language["Target Indicator"])
	right:CreateSwitch("nameplates-enable-target-indicator", Settings["nameplates-enable-target-indicator"], Language["Enable Target Indicator"], Language["Display an indication on the targeted unit nameplate"], UpdateNamePlatesTargetHighlight)
	right:CreateDropdown("nameplates-target-indicator-size", Settings["nameplates-target-indicator-size"], {[Language["Small"]] = "SMALL", [Language["Large"]] = "LARGE", [Language["Huge"]] = "HUGE"}, Language["Indicator Size"], Language["Select the size of the target indicator"], UpdateNamePlatesTargetIndicatorSize)

end)
YxUI:GetModule("GUI"):RegisterPageSettingsID("General", "Name Plates", {
	{"nameplates-font", UpdateNamePlatesFont},
	{"nameplates-font-size", UpdateNamePlatesFont},
	{"nameplates-font-flags", UpdateNamePlatesFont},
	{"nameplates-width", UpdateNamePlatesWidth},
	{"nameplates-height", UpdateNamePlatesHeight},
	{"nameplates-health-color", UpdateNamePlatesHealthColor},
	{"nameplates-health-smooth", UpdateNamePlatesHealthSmooth},
	{"NPHealthTexture", UpdateHealthTexture},
	{"nameplates-enable-auras", UpdateNamePlatesEnableAuras},
	{"nameplates-buff-size", UpdateNamePlatesAuraLayout},
	{"nameplates-buff-count", UpdateNamePlatesAuraLayout},
	{"nameplates-buffs-direction", UpdateNamePlatesBuffDirection},
	{"nameplates-debuff-size", UpdateNamePlatesAuraLayout},
	{"nameplates-debuff-count", UpdateNamePlatesAuraLayout},
	{"nameplates-only-player-debuffs", UpdateNamePlatesShowPlayerDebuffs},
	{"nameplates-debuffs-direction", UpdateNamePlatesDebuffDirection},
	{"nameplates-enable-castbar", UpdateNamePlatesEnableCastBars},
	{"nameplates-cast-classcolor", UpdateNamePlatesCastClassColor},
	{"nameplates-castbar-height", UpdateNamePlatesCastBarsHeight},
	{"NPCastTexture", UpdateCastTexture},
	{"nameplates-enable-target-indicator", UpdateNamePlatesTargetHighlight},
	{"nameplates-target-indicator-size", UpdateNamePlatesTargetIndicatorSize},
}, nil)


YxUI:GetModule("GUI"):RegisterReloadSettings({"nameplates-enable"})
