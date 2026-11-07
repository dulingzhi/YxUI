local AddonName, Namespace = ...
local YxUI, Language, Assets, Settings, Defaults = Namespace:get()
local R, G, B

-- Shared unit-frame palette remains private to YxUI rather than using the
-- addon namespace as a library-style data registry.
local UnitFrameColors = {
	class = {}, reaction = {}, power = {}, debuff = {},
	threat = {}, smooth = {{1, 0, 0}, {1, 1, 0}, {0, 1, 0}},
}

function YxUI:ColorGradient(current, maximum, ...)
	if maximum == 0 then
		return 0, 0, 0
	end
	local percentage = current / maximum
	if percentage >= 1 then
		local count = select("#", ...)
		return select(count - 2, ...)
	elseif percentage <= 0 then
		return ...
	end
	local count = select("#", ...) / 3
	local segment, relative = math.modf(percentage * (count - 1))
	local index = segment * 3 + 1
	local r1, g1, b1, r2, g2, b2 = select(index, ...)
	return r1 + (r2-r1)*relative, g1 + (g2-g1)*relative, b1 + (b2-b1)*relative
end

-- Class Colors
Defaults["color-death-knight"] = "C41E3A"
Defaults["color-demon-hunter"] = "A330C9"
Defaults["color-druid"] = "FF7C0A"
Defaults["color-evoker"] = "33937F"
Defaults["color-hunter"] = "AAD372"
Defaults["color-mage"] = "3FC7EB"
Defaults["color-monk"] = "00FF98"
Defaults["color-paladin"] = "F48CBA"
Defaults["color-priest"] = "FFFFFF"
Defaults["color-rogue"] = "FFF468"
Defaults["color-shaman"] = "0070DD"
Defaults["color-warlock"] = "8788EE"
Defaults["color-warrior"] = "C69B6D"

-- Power Types
Defaults["color-mana"] = "477CB2" -- 0000FF for the default mana color
Defaults["color-rage"] = "E53935" -- FF0000 ^
Defaults["color-energy"] = "FFEB3B" -- FFFF00 ^
Defaults["color-essence"] = "64ADCE"
Defaults["color-focus"] = "FF7F3F"
Defaults["color-fuel"] = "008C7F"
Defaults["color-insanity"] = "6600CC"
Defaults["color-holy-power"] = "F2E599"
Defaults["color-fury"] = "C842FC"
Defaults["color-runic-power"] = "00D1FF"
Defaults["color-chi"] = "B5FFEA"
Defaults["color-maelstrom"] = "007FFF"
Defaults["color-lunar-power"] = "4C84E5"
Defaults["color-arcane-charges"] = "1E88E5"
Defaults["color-ammo-slot"] = "CC9900"
Defaults["color-soul-shards"] = "D35832" -- 7F518C for the default soul shards color
Defaults["color-runes"] = "9905CC" -- 7F7F7F ^
Defaults["color-combo-points"] = "FFF468"

-- Reactions
Defaults["color-reaction-1"] = "BF4400" -- Hated
Defaults["color-reaction-2"] = "BF4400" -- Hostile
Defaults["color-reaction-3"] = "BF4400" -- Unfriendly
Defaults["color-reaction-4"] = "E5B200" -- Neutral
Defaults["color-reaction-5"] = "009919" -- Friendly
Defaults["color-reaction-6"] = "009919" -- Honored
Defaults["color-reaction-7"] = "009919" -- Revered
Defaults["color-reaction-8"] = "009919" -- Exalted

-- Zone PVP Types
Defaults["color-sanctuary"] = "68CCEF"
Defaults["color-arena"] = "FF1919"
Defaults["color-hostile"] = "FF1919"
Defaults["color-combat"] = "FF1919"
Defaults["color-friendly"] = "19FF19"
Defaults["color-contested"] = "FFB200"
Defaults["color-other"] = "FFECC1"

-- Debuff Types
Defaults["color-curse"] = "9900FF"
Defaults["color-disease"] = "996600"
Defaults["color-magic"] = "3399FF"
Defaults["color-poison"] = "009900"
Defaults["color-none"] = "000000"

-- Happiness
Defaults["color-happiness-1"] = "C62828" -- "8BC94D"
Defaults["color-happiness-2"] = "FBC02D" -- "FFC44D"
Defaults["color-happiness-3"] = "4CAF50" -- "EE4D4D"

-- Combo Points
Defaults["color-combo-1"] = "FF6666"
Defaults["color-combo-2"] = "FFB266"
Defaults["color-combo-3"] = "FFFF66"
Defaults["color-combo-4"] = "B2FF66"
Defaults["color-combo-5"] = "66FF66"
Defaults["color-combo-6"] = "66FF66"
Defaults["color-combo-7"] = "33FF33"
Defaults["color-combo-charged"] = "64B5F6"

-- Stagger
Defaults["color-stagger-1"] = "66FF66"
Defaults["color-stagger-2"] = "FFFF66"
Defaults["color-stagger-3"] = "FF6666"

-- Casting
Defaults["color-casting-start"] = "4C9900"
Defaults["color-casting-stopped"] = "F39C12"
Defaults["color-casting-interrupted"] = "D35400"
Defaults["color-casting-uninterruptible"] = "FF4444"
Defaults["color-casting-success"] = "4C9900" -- NYI

-- Mirror Timers
Defaults["color-mirror-exhaustion"] = "FFE500"
Defaults["color-mirror-breath"] = "007FFF"
Defaults["color-mirror-death"] = "FFB200"
Defaults["color-mirror-feign-death"] = "FFB200"

-- Totems
Defaults["color-totem-fire"] = "D64545"
Defaults["color-totem-earth"] = "E5B045"
Defaults["color-totem-water"] = "45B0E5"
Defaults["color-totem-air"] = "B3E5FC"

-- Other
Defaults["color-tapped"] = "A6A6A6"
Defaults["color-disconnected"] = "A6A6A6"

YxUI.ClassColors = {}
YxUI.ReactionColors = {}
YxUI.ZoneColors = {}
YxUI.PowerColors = {}
YxUI.DebuffColors = {}
YxUI.HappinessColors = {}
YxUI.ComboPoints = {}
YxUI.TotemColors = {}

function YxUI:SetColorEntry(t, key, hex)
	R, G, B = self:HexToRGB(hex)

	if not t[key] then
		t[key] = {}
	end

	t[key][1] = R
	t[key][2] = G
	t[key][3] = B
	t[key]["Hex"] = hex
end

function YxUI:UpdateClassColors()
	self:SetColorEntry(self.ClassColors, "DEATHKNIGHT", Settings["color-death-knight"])
	self:SetColorEntry(self.ClassColors, "DEMONHUNTER", Settings["color-demon-hunter"])
	self:SetColorEntry(self.ClassColors, "DRUID", Settings["color-druid"])
	self:SetColorEntry(self.ClassColors, "EVOKER", Settings["color-evoker"])
	self:SetColorEntry(self.ClassColors, "HUNTER", Settings["color-hunter"])
	self:SetColorEntry(self.ClassColors, "MAGE", Settings["color-mage"])
	self:SetColorEntry(self.ClassColors, "MONK", Settings["color-monk"])
	self:SetColorEntry(self.ClassColors, "PALADIN", Settings["color-paladin"])
	self:SetColorEntry(self.ClassColors, "PRIEST", Settings["color-priest"])
	self:SetColorEntry(self.ClassColors, "ROGUE", Settings["color-rogue"])
	self:SetColorEntry(self.ClassColors, "SHAMAN", Settings["color-shaman"])
	self:SetColorEntry(self.ClassColors, "WARLOCK", Settings["color-warlock"])
	self:SetColorEntry(self.ClassColors, "WARRIOR", Settings["color-warrior"])
end

function YxUI:UpdateReactionColors()
	self:SetColorEntry(self.ReactionColors, 1, Settings["color-reaction-1"])
	self:SetColorEntry(self.ReactionColors, 2, Settings["color-reaction-2"])
	self:SetColorEntry(self.ReactionColors, 3, Settings["color-reaction-3"])
	self:SetColorEntry(self.ReactionColors, 4, Settings["color-reaction-4"])
	self:SetColorEntry(self.ReactionColors, 5, Settings["color-reaction-5"])
	self:SetColorEntry(self.ReactionColors, 6, Settings["color-reaction-6"])
	self:SetColorEntry(self.ReactionColors, 7, Settings["color-reaction-7"])
	self:SetColorEntry(self.ReactionColors, 8, Settings["color-reaction-8"])
end

function YxUI:UpdateZoneColors()
	self:SetColorEntry(self.ZoneColors, "sanctuary", Settings["color-sanctuary"])
	self:SetColorEntry(self.ZoneColors, "arena", Settings["color-arena"])
	self:SetColorEntry(self.ZoneColors, "hostile", Settings["color-hostile"])
	self:SetColorEntry(self.ZoneColors, "combat", Settings["color-combat"])
	self:SetColorEntry(self.ZoneColors, "friendly", Settings["color-friendly"])
	self:SetColorEntry(self.ZoneColors, "contested", Settings["color-contested"])
	self:SetColorEntry(self.ZoneColors, "other", Settings["color-other"])
end

function YxUI:UpdatePowerColors()
	self:SetColorEntry(self.PowerColors, "MANA", Settings["color-mana"])
	self:SetColorEntry(self.PowerColors, "RAGE", Settings["color-rage"])
	self:SetColorEntry(self.PowerColors, "ENERGY", Settings["color-energy"])
	self:SetColorEntry(self.PowerColors, "COMBO_POINTS", Settings["color-combo-points"])
	self:SetColorEntry(self.PowerColors, "FOCUS", Settings["color-focus"])
	self:SetColorEntry(self.PowerColors, "SOUL_SHARDS", Settings["color-soul-shards"])
	self:SetColorEntry(self.PowerColors, "INSANITY", Settings["color-insanity"])
	self:SetColorEntry(self.PowerColors, "FURY", Settings["color-fury"])
	self:SetColorEntry(self.PowerColors, "PAIN", Settings["color-pain"])
	self:SetColorEntry(self.PowerColors, "CHI", Settings["color-chi"])
	self:SetColorEntry(self.PowerColors, "MAELSTROM", Settings["color-maelstrom"])
	self:SetColorEntry(self.PowerColors, "ARCANE_CHARGES", Settings["color-arcane-charges"])
	self:SetColorEntry(self.PowerColors, "HOLY_POWER", Settings["color-holy-power"])
	self:SetColorEntry(self.PowerColors, "LUNAR_POWER", Settings["color-lunar-power"])
	self:SetColorEntry(self.PowerColors, "RUNIC_POWER", Settings["color-runic-power"])
	self:SetColorEntry(self.PowerColors, "RUNES", Settings["color-runes"])
	self:SetColorEntry(self.PowerColors, "FUEL", Settings["color-fuel"])
	self:SetColorEntry(self.PowerColors, "AMMO_SLOT", Settings["color-ammo-slot"])
	self:SetColorEntry(self.PowerColors, "ESSENCE", Settings["color-essence"])
end

function YxUI:UpdateDebuffColors()
	self:SetColorEntry(self.DebuffColors, "Curse", Settings["color-curse"])
	self:SetColorEntry(self.DebuffColors, "Disease", Settings["color-disease"])
	self:SetColorEntry(self.DebuffColors, "Magic", Settings["color-magic"])
	self:SetColorEntry(self.DebuffColors, "Poison", Settings["color-poison"])
	self:SetColorEntry(self.DebuffColors, "none", Settings["color-none"])
end

function YxUI:UpdateHappinessColors()
	self:SetColorEntry(self.HappinessColors, 1, Settings["color-happiness-1"])
	self:SetColorEntry(self.HappinessColors, 2, Settings["color-happiness-2"])
	self:SetColorEntry(self.HappinessColors, 3, Settings["color-happiness-3"])
end

function YxUI:UpdateComboColors()
	self:SetColorEntry(self.ComboPoints, 1, Settings["color-combo-1"])
	self:SetColorEntry(self.ComboPoints, 2, Settings["color-combo-2"])
	self:SetColorEntry(self.ComboPoints, 3, Settings["color-combo-3"])
	self:SetColorEntry(self.ComboPoints, 4, Settings["color-combo-4"])
	self:SetColorEntry(self.ComboPoints, 5, Settings["color-combo-5"])
	self:SetColorEntry(self.ComboPoints, 6, Settings["color-combo-6"])
	self:SetColorEntry(self.ComboPoints, 7, Settings["color-combo-7"])
end

function YxUI:UpdateTotemColors()
	self:SetColorEntry(self.TotemColors, 1, Settings["color-totem-fire"])
	self:SetColorEntry(self.TotemColors, 2, Settings["color-totem-earth"])
	self:SetColorEntry(self.TotemColors, 3, Settings["color-totem-water"])
	self:SetColorEntry(self.TotemColors, 4, Settings["color-totem-air"])
end

function YxUI:UpdateColors()
	self:UpdateClassColors()
	self:UpdateReactionColors()
	self:UpdateZoneColors()
	self:UpdatePowerColors()
	self:UpdateDebuffColors()
	self:UpdateComboColors()

	if not self.IsMainline then
		self:UpdateHappinessColors()
		self:UpdateTotemColors()
	end
end

function YxUI:GetUnitFrameColors()
	return UnitFrameColors
end

function YxUI:UpdateUnitFrameColors()
	local Colors = UnitFrameColors

	Colors.class = YxUI.ClassColors
	Colors.reaction = YxUI.ReactionColors
	Colors.power = YxUI.PowerColors
	Colors.debuff = YxUI.DebuffColors
	Colors.tapped = {YxUI:HexToRGB(Settings["color-tapped"])}
	Colors.disconnected = {YxUI:HexToRGB(Settings["color-disconnected"])}
	Colors.health = {YxUI:HexToRGB(Settings["ui-header-texture-color"])}
	Colors.threat[0] = nil
	Colors.threat[1] = {1, 1, 0}
	Colors.threat[2] = {1, 1, 0}
	Colors.threat[3] = {1, 0, 0}
end

local function UpdateComboPointColors()
	YxUI:UpdateComboColors()

	local player = YxUI.UnitFrames and YxUI.UnitFrames.player
	local resource = player and player.ClassResource
	if resource and resource.UpdateColors then
		resource:UpdateColors()
	end
end

local function UpdateClassColorCache() YxUI:UpdateClassColors() end
local function UpdatePowerColorCache()
	YxUI:UpdatePowerColors()
	local player = YxUI.UnitFrames and YxUI.UnitFrames.player
	local resource = player and player.ClassResource
	if resource and resource.RefreshColors then
		resource:RefreshColors()
	end
end
local function UpdateZoneColorCache() YxUI:UpdateZoneColors() end
local function UpdateReactionColorCache() YxUI:UpdateReactionColors() end
local function UpdateDebuffColorCache() YxUI:UpdateDebuffColors() end
local function UpdateHappinessColorCache() YxUI:UpdateHappinessColors() end
local function UpdateTotemColorCache() YxUI:UpdateTotemColors() end
local function UpdateMiscUnitFrameColors() YxUI:UpdateUnitFrameColors() end

YxUI:GetModule("GUI"):AddWidgetsID("General", "Colors", function(left, right)
	left:CreateHeader(Language["Class Colors"])
	left:CreateColorSelection("color-death-knight", Settings["color-death-knight"], Language["Death Knight"], "", UpdateClassColorCache)
	left:CreateColorSelection("color-demon-hunter", Settings["color-demon-hunter"], Language["Demon Hunter"], "", UpdateClassColorCache)
	left:CreateColorSelection("color-druid", Settings["color-druid"], Language["Druid"], "", UpdateClassColorCache)
	left:CreateColorSelection("color-evoker", Settings["color-evoker"], Language["Evoker"], "", UpdateClassColorCache)
	left:CreateColorSelection("color-hunter", Settings["color-hunter"], Language["Hunter"], "", UpdateClassColorCache)
	left:CreateColorSelection("color-mage", Settings["color-mage"], Language["Mage"], "", UpdateClassColorCache)
	left:CreateColorSelection("color-monk", Settings["color-monk"], Language["Monk"], "", UpdateClassColorCache)
	left:CreateColorSelection("color-paladin", Settings["color-paladin"], Language["Paladin"], "", UpdateClassColorCache)
	left:CreateColorSelection("color-priest", Settings["color-priest"], Language["Priest"], "", UpdateClassColorCache)
	left:CreateColorSelection("color-rogue", Settings["color-rogue"], Language["Rogue"], "", UpdateClassColorCache)
	left:CreateColorSelection("color-shaman", Settings["color-shaman"], Language["Shaman"], "", UpdateClassColorCache)
	left:CreateColorSelection("color-warlock", Settings["color-warlock"], Language["Warlock"], "", UpdateClassColorCache)
	left:CreateColorSelection("color-warrior", Settings["color-warrior"], Language["Warrior"], "", UpdateClassColorCache)

	right:CreateHeader(Language["Power Colors"])
	right:CreateColorSelection("color-mana", Settings["color-mana"], Language["Mana"], "", UpdatePowerColorCache)
	right:CreateColorSelection("color-rage", Settings["color-rage"], Language["Rage"], "", UpdatePowerColorCache)
	right:CreateColorSelection("color-energy", Settings["color-energy"], Language["Energy"], "", UpdatePowerColorCache)
	right:CreateColorSelection("color-essence", Settings["color-essence"], Language["Essence"], "", UpdatePowerColorCache)
	right:CreateColorSelection("color-focus", Settings["color-focus"], Language["Focus"], "", UpdatePowerColorCache)
	--right:CreateColorSelection("color-combo-points", Settings["color-combo-points"], Language["Combo Points"], "")
	right:CreateColorSelection("color-soul-shards", Settings["color-soul-shards"], Language["Soul Shards"], "", UpdatePowerColorCache)
	right:CreateColorSelection("color-insanity", Settings["color-insanity"], Language["Insanity"], "", UpdatePowerColorCache)
	right:CreateColorSelection("color-fury", Settings["color-fury"], Language["Fury"], "", UpdatePowerColorCache)
	right:CreateColorSelection("color-chi", Settings["color-chi"], Language["Chi"], "", UpdatePowerColorCache)
	right:CreateColorSelection("color-maelstrom", Settings["color-maelstrom"], Language["Maelstrom"], "", UpdatePowerColorCache)
	right:CreateColorSelection("color-arcane-charges", Settings["color-arcane-charges"], Language["Arcane Charges"], "", UpdatePowerColorCache)
	right:CreateColorSelection("color-holy-power", Settings["color-holy-power"], Language["Holy Power"], "", UpdatePowerColorCache)
	right:CreateColorSelection("color-lunar-power", Settings["color-lunar-power"], Language["Lunar Power"], "", UpdatePowerColorCache)
	right:CreateColorSelection("color-runic-power", Settings["color-runic-power"], Language["Runic Power"], "", UpdatePowerColorCache)
	right:CreateColorSelection("color-runes", Settings["color-runes"], Language["Runes"], "", UpdatePowerColorCache)
	right:CreateColorSelection("color-fuel", Settings["color-fuel"], Language["Fuel"], "", UpdatePowerColorCache)
	right:CreateColorSelection("color-ammo-slot", Settings["color-ammo-slot"], Language["Ammo Slot"], "", UpdatePowerColorCache)

	left:CreateHeader(Language["Zone Colors"])
	left:CreateColorSelection("color-sanctuary", Settings["color-sanctuary"], Language["Sanctuary"], "", UpdateZoneColorCache)
	left:CreateColorSelection("color-arena", Settings["color-arena"], Language["Arena"], "", UpdateZoneColorCache)
	left:CreateColorSelection("color-hostile", Settings["color-hostile"], Language["Hostile"], "", UpdateZoneColorCache)
	left:CreateColorSelection("color-combat", Settings["color-combat"], Language["Combat"], "", UpdateZoneColorCache)
	left:CreateColorSelection("color-contested", Settings["color-contested"], Language["Contested"], "", UpdateZoneColorCache)
	left:CreateColorSelection("color-friendly", Settings["color-friendly"], Language["Friendly"], "", UpdateZoneColorCache)
	left:CreateColorSelection("color-other", Settings["color-other"], Language["Other"], "", UpdateZoneColorCache)

	right:CreateHeader(Language["Reaction Colors"])
	right:CreateColorSelection("color-reaction-8", Settings["color-reaction-8"], Language["Exalted"], "", UpdateReactionColorCache)
	right:CreateColorSelection("color-reaction-7", Settings["color-reaction-7"], Language["Revered"], "", UpdateReactionColorCache)
	right:CreateColorSelection("color-reaction-6", Settings["color-reaction-6"], Language["Honored"], "", UpdateReactionColorCache)
	right:CreateColorSelection("color-reaction-5", Settings["color-reaction-5"], Language["Friendly"], "", UpdateReactionColorCache)
	right:CreateColorSelection("color-reaction-4", Settings["color-reaction-4"], Language["Neutral"], "", UpdateReactionColorCache)
	right:CreateColorSelection("color-reaction-3", Settings["color-reaction-3"], Language["Unfriendly"], "", UpdateReactionColorCache)
	right:CreateColorSelection("color-reaction-2", Settings["color-reaction-2"], Language["Hostile"], "", UpdateReactionColorCache)
	right:CreateColorSelection("color-reaction-1", Settings["color-reaction-1"], Language["Hated"], "", UpdateReactionColorCache)

	right:CreateHeader(Language["Debuff Colors"])
	right:CreateColorSelection("color-curse", Settings["color-curse"], Language["Curse"], "", UpdateDebuffColorCache)
	right:CreateColorSelection("color-disease", Settings["color-disease"], Language["Disease"], "", UpdateDebuffColorCache)
	right:CreateColorSelection("color-magic", Settings["color-magic"], Language["Magic"], "", UpdateDebuffColorCache)
	right:CreateColorSelection("color-poison", Settings["color-poison"], Language["Poison"], "", UpdateDebuffColorCache)
	right:CreateColorSelection("color-none", Settings["color-none"], Language["None"], "", UpdateDebuffColorCache)

	if not YxUI.IsMainline then
		right:CreateHeader(Language["Pet Happiness Colors"])
		right:CreateColorSelection("color-happiness-3", Settings["color-happiness-3"], Language["Happy"], "", UpdateHappinessColorCache)
		right:CreateColorSelection("color-happiness-2", Settings["color-happiness-2"], Language["Content"], "", UpdateHappinessColorCache)
		right:CreateColorSelection("color-happiness-1", Settings["color-happiness-1"], Language["Unhappy"], "", UpdateHappinessColorCache)

		left:CreateHeader(Language["Totem Colors"])
		left:CreateColorSelection("color-totem-fire", Settings["color-totem-fire"], Language["Fire"], "", UpdateTotemColorCache)
		left:CreateColorSelection("color-totem-earth", Settings["color-totem-earth"], Language["Earth"], "", UpdateTotemColorCache)
		left:CreateColorSelection("color-totem-water", Settings["color-totem-water"], Language["Water"], "", UpdateTotemColorCache)
		left:CreateColorSelection("color-totem-air", Settings["color-totem-air"], Language["Air"], "", UpdateTotemColorCache)
	end

	left:CreateHeader(Language["Combo Points Colors"])
	left:CreateColorSelection("color-combo-1", Settings["color-combo-1"], Language["Combo Point 1"], Language["Set the color of combo point 1"], UpdateComboPointColors)
	left:CreateColorSelection("color-combo-2", Settings["color-combo-2"], Language["Combo Point 2"], Language["Set the color of combo point 2"], UpdateComboPointColors)
	left:CreateColorSelection("color-combo-3", Settings["color-combo-3"], Language["Combo Point 3"], Language["Set the color of combo point 3"], UpdateComboPointColors)
	left:CreateColorSelection("color-combo-4", Settings["color-combo-4"], Language["Combo Point 4"], Language["Set the color of combo point 4"], UpdateComboPointColors)
	left:CreateColorSelection("color-combo-5", Settings["color-combo-5"], Language["Combo Point 5"], Language["Set the color of combo point 5"], UpdateComboPointColors)

	if YxUI.IsMainline and not YxUI.IsForever then
		left:CreateColorSelection("color-combo-6", Settings["color-combo-6"], Language["Combo Point 6"], Language["Set the color of combo point 6"], UpdateComboPointColors)
		left:CreateColorSelection("color-combo-7", Settings["color-combo-7"], Language["Combo Point 7"], Language["Set the color of combo point 7"], UpdateComboPointColors)
		left:CreateColorSelection("color-combo-charged", Settings["color-combo-charged"], Language["Charged Combo Point"], Language["Set the color of the charged combo point provided from the Kyrian Covenant"], UpdateComboPointColors)
	end

	right:CreateHeader(Language["Misc Colors"])
	right:CreateColorSelection("color-tapped", Settings["color-tapped"], Language["Tagged"], "", UpdateMiscUnitFrameColors)
	right:CreateColorSelection("color-disconnected", Settings["color-disconnected"], Language["Disconnected"], "", UpdateMiscUnitFrameColors)

	left:CreateHeader(Language["Casting"])
	left:CreateColorSelection("color-casting-start", Settings["color-casting-start"], Language["Casting"], "")
	left:CreateColorSelection("color-casting-stopped", Settings["color-casting-stopped"], Language["Stopped"], "")
	left:CreateColorSelection("color-casting-interrupted", Settings["color-casting-interrupted"], Language["Interrupted"], "")
	left:CreateColorSelection("color-casting-uninterruptible", Settings["color-casting-uninterruptible"], Language["Uninterruptible"], "")
end)
YxUI:GetModule("GUI"):RegisterPageSettingsID("General", "Colors", {
	{"color-death-knight", UpdateClassColorCache},
	{"color-demon-hunter", UpdateClassColorCache},
	{"color-druid", UpdateClassColorCache},
	{"color-evoker", UpdateClassColorCache},
	{"color-hunter", UpdateClassColorCache},
	{"color-mage", UpdateClassColorCache},
	{"color-monk", UpdateClassColorCache},
	{"color-paladin", UpdateClassColorCache},
	{"color-priest", UpdateClassColorCache},
	{"color-rogue", UpdateClassColorCache},
	{"color-shaman", UpdateClassColorCache},
	{"color-warlock", UpdateClassColorCache},
	{"color-warrior", UpdateClassColorCache},
	{"color-mana", UpdatePowerColorCache},
	{"color-rage", UpdatePowerColorCache},
	{"color-energy", UpdatePowerColorCache},
	{"color-essence", UpdatePowerColorCache},
	{"color-focus", UpdatePowerColorCache},
	{"color-soul-shards", UpdatePowerColorCache},
	{"color-insanity", UpdatePowerColorCache},
	{"color-fury", UpdatePowerColorCache},
	{"color-chi", UpdatePowerColorCache},
	{"color-maelstrom", UpdatePowerColorCache},
	{"color-arcane-charges", UpdatePowerColorCache},
	{"color-holy-power", UpdatePowerColorCache},
	{"color-lunar-power", UpdatePowerColorCache},
	{"color-runic-power", UpdatePowerColorCache},
	{"color-runes", UpdatePowerColorCache},
	{"color-fuel", UpdatePowerColorCache},
	{"color-ammo-slot", UpdatePowerColorCache},
	{"color-sanctuary", UpdateZoneColorCache},
	{"color-arena", UpdateZoneColorCache},
	{"color-hostile", UpdateZoneColorCache},
	{"color-combat", UpdateZoneColorCache},
	{"color-contested", UpdateZoneColorCache},
	{"color-friendly", UpdateZoneColorCache},
	{"color-other", UpdateZoneColorCache},
	{"color-reaction-8", UpdateReactionColorCache},
	{"color-reaction-7", UpdateReactionColorCache},
	{"color-reaction-6", UpdateReactionColorCache},
	{"color-reaction-5", UpdateReactionColorCache},
	{"color-reaction-4", UpdateReactionColorCache},
	{"color-reaction-3", UpdateReactionColorCache},
	{"color-reaction-2", UpdateReactionColorCache},
	{"color-reaction-1", UpdateReactionColorCache},
	{"color-curse", UpdateDebuffColorCache},
	{"color-disease", UpdateDebuffColorCache},
	{"color-magic", UpdateDebuffColorCache},
	{"color-poison", UpdateDebuffColorCache},
	{"color-none", UpdateDebuffColorCache},
	{"color-happiness-3", not YxUI.IsMainline and UpdateHappinessColorCache or nil},
	{"color-happiness-2", not YxUI.IsMainline and UpdateHappinessColorCache or nil},
	{"color-happiness-1", not YxUI.IsMainline and UpdateHappinessColorCache or nil},
	{"color-totem-fire", not YxUI.IsMainline and UpdateTotemColorCache or nil},
	{"color-totem-earth", not YxUI.IsMainline and UpdateTotemColorCache or nil},
	{"color-totem-water", not YxUI.IsMainline and UpdateTotemColorCache or nil},
	{"color-totem-air", not YxUI.IsMainline and UpdateTotemColorCache or nil},
	{"color-combo-1", UpdateComboPointColors},
	{"color-combo-2", UpdateComboPointColors},
	{"color-combo-3", UpdateComboPointColors},
	{"color-combo-4", UpdateComboPointColors},
	{"color-combo-5", UpdateComboPointColors},
	{"color-combo-6", YxUI.IsMainline and not YxUI.IsForever and UpdateComboPointColors or nil},
	{"color-combo-7", YxUI.IsMainline and not YxUI.IsForever and UpdateComboPointColors or nil},
	{"color-combo-charged", YxUI.IsMainline and not YxUI.IsForever and UpdateComboPointColors or nil},
	{"color-tapped", UpdateMiscUnitFrameColors},
	{"color-disconnected", UpdateMiscUnitFrameColors},
}, nil)

