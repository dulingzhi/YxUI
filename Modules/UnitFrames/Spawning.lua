local addon, ns = ...
local YxUI, _, _, Settings = ns:get()

local floor = math.floor

local UF = YxUI:GetModule("Unit Frames")
local Hider = assert(UF.Hider, "unit-frame core must create the hider")
local function HideBlizzardFrame(frame, keepParent)
	if not frame then
		return
	end

	frame:UnregisterAllEvents()
	frame:Hide()

	if not keepParent then
		frame:SetParent(Hider)
	end

	for _, child in pairs({frame.healthBar or frame.healthbar, frame.manabar, frame.castBar or frame.spellbar, frame.powerBarAlt, frame.BuffFrame}) do
		if child then
			child:UnregisterAllEvents()
		end
	end
end

-- Suppress stock frames before creating YxUI's native unit frames.
function UF:DisableBlizzardUnitFrame(unit)
	if unit == "player" then
		HideBlizzardFrame(PlayerFrame)

		-- Blizzard still needs these events to switch the vehicle unit safely.
		if PlayerFrame then
			for _, event in ipairs({"PLAYER_ENTERING_WORLD", "UNIT_ENTERING_VEHICLE", "UNIT_ENTERED_VEHICLE", "UNIT_EXITING_VEHICLE", "UNIT_EXITED_VEHICLE"}) do
				PlayerFrame:RegisterEvent(event)
			end

			PlayerFrame:SetUserPlaced(true)
			PlayerFrame:SetDontSavePosition(true)
		end
	elseif unit == "pet" then
		HideBlizzardFrame(PetFrame)
	elseif unit == "target" then
		HideBlizzardFrame(TargetFrame)
		HideBlizzardFrame(ComboFrame)
	elseif unit == "focus" then
		HideBlizzardFrame(FocusFrame)
		HideBlizzardFrame(TargetofFocusFrame)
	elseif unit == "targettarget" then
		HideBlizzardFrame(TargetFrameToT)
	elseif unit == "boss" then
		for index = 1, (MAX_BOSS_FRAMES or 5) do
			HideBlizzardFrame(_G["Boss" .. index .. "TargetFrame"])
		end
	elseif unit == "party" then
		HideBlizzardFrame(PartyFrame)

		for index = 1, (MAX_PARTY_MEMBERS or 4) do
			HideBlizzardFrame(_G["PartyMemberFrame" .. index])
		end
	end
end

local UpdateRaidSortingMethod = function(value)
	if value == "CLASS" then
		YxUI.UnitFrames["raid"]:SetAttribute("groupingOrder", "DEATHKNIGHT,DEMONHUNTER,DRUID,HUNTER,MAGE,MONK,PALADIN,PRIEST,SHAMAN,WARLOCK,WARRIOR")
		YxUI.UnitFrames["raid"]:SetAttribute("sortMethod", "NAME")
		YxUI.UnitFrames["raid"]:SetAttribute("groupBy", "CLASS")
	elseif value == "ROLE" then
		YxUI.UnitFrames["raid"]:SetAttribute("groupingOrder", "TANK,HEALER,DAMAGER,NONE")
		YxUI.UnitFrames["raid"]:SetAttribute("sortMethod", "NAME")
		YxUI.UnitFrames["raid"]:SetAttribute("groupBy", "ASSIGNEDROLE")
	elseif value == "NAME" then
		YxUI.UnitFrames["raid"]:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
		YxUI.UnitFrames["raid"]:SetAttribute("sortMethod", "NAME")
		YxUI.UnitFrames["raid"]:SetAttribute("groupBy", nil)
	elseif value == "MTMA" then
		YxUI.UnitFrames["raid"]:SetAttribute("groupingOrder", "MAINTANK,MAINASSIST,NONE")
		YxUI.UnitFrames["raid"]:SetAttribute("sortMethod", "NAME")
		YxUI.UnitFrames["raid"]:SetAttribute("groupBy", "ROLE")
	else -- GROUP
		YxUI.UnitFrames["raid"]:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
		YxUI.UnitFrames["raid"]:SetAttribute("sortMethod", "INDEX")
		YxUI.UnitFrames["raid"]:SetAttribute("groupBy", "GROUP")
	end
end

local SingletonUnits = {
	{unit = "player", globalName = "YxUI Player", enabled = "player-enable", dimensions = {width = "unitframes-player-width", health = "unitframes-player-health-height", power = "unitframes-player-power-height"}, defaultAnchor = {"TOPRIGHT", "CENTER", -68, -281}, postSpawn = "ConfigurePlayer"},
	{unit = "target", globalName = "YxUI Target", enabled = "target-enable", dimensions = {width = "unitframes-target-width", health = "unitframes-target-health-height", power = "unitframes-target-power-height"}, defaultAnchor = {"TOPLEFT", "CENTER", 68, -281}, postSpawn = "ConfigureTarget"},
	{unit = "targettarget", globalName = "YxUI Target Target", enabled = "tot-enable", powerEnabledKey = "unitframes-targettarget-enable-power", dimensions = {width = "unitframes-targettarget-width", health = "unitframes-targettarget-health-height", power = "unitframes-targettarget-power-height"}, defaultAnchor = {"TOPRIGHT", "CENTER", 68, -341}, postSpawn = "ConfigureTargetTarget"},
	{unit = "pet", globalName = "YxUI Pet", enabled = "pet-enable", powerEnabledKey = "unitframes-pet-enable-power", dimensions = {width = "unitframes-pet-width", health = "unitframes-pet-health-height", power = "unitframes-pet-power-height"}, defaultAnchor = {"TOPLEFT", "CENTER", -68, -341}, postSpawn = "ConfigurePet"},
	{unit = "focus", globalName = "YxUI Focus", enabled = "focus-enable", dimensions = {width = "unitframes-focus-width", health = "unitframes-focus-health-height", power = "unitframes-focus-power-height"}, defaultAnchor = {"RIGHT", "CENTER", -68, 304}, postSpawn = "ConfigureFocus"},
}

UF.SingletonUnits = SingletonUnits

function UF:SpawnSingletonFrames()
	for _, descriptor in ipairs(SingletonUnits) do
		if Settings[descriptor.enabled] then
			UF:DisableBlizzardUnitFrame(descriptor.unit)

			local dimensions = descriptor.dimensions
			local frame = YxUI.UnitFrames:CreateUnitButton(descriptor.unit, descriptor.globalName, YxUI.StyleFuncs[descriptor.unit])

			local powerHeight = descriptor.powerEnabledKey and not Settings[descriptor.powerEnabledKey] and 0 or Settings[dimensions.power]
			frame:SetSize(Settings[dimensions.width], Settings[dimensions.health] + powerHeight + (powerHeight > 0 and 3 or 2))
			frame:SetPoint(descriptor.defaultAnchor[1], YxUI.UIParent, descriptor.defaultAnchor[2], descriptor.defaultAnchor[3], descriptor.defaultAnchor[4])
			frame:SetParent(YxUI.UIParent)

			YxUI.UnitFrames[descriptor.unit] = frame
		end
	end

	-- Configure only after every singleton exists, so companion anchors can
	-- resolve player/target frames regardless of descriptor order.
	for _, descriptor in ipairs(SingletonUnits) do
		local frame = YxUI.UnitFrames[descriptor.unit]

		if Settings[descriptor.enabled] then
			self[descriptor.postSpawn](self, frame)
		end
	end
end

function UF:ConfigurePlayer(player)
	if not Settings["unitframes-player-enable-power"] or Settings["player-move-power"] then
		player:SetSize(Settings["unitframes-player-width"], Settings["unitframes-player-health-height"] + 2)
	end

	if Settings["player-enable-portrait"] then
		player:EnableElement("Portrait")
	else
		player:DisableElement("Portrait")
	end

	if not Settings["player-enable-pvp"] then
		player:DisableElement("PvPIndicator")
		player.PvPIndicator:Hide()
	end

	if Settings["unitframes-show-player-buffs"] then
		player.Buffs:Show()
	else
		player.Buffs:Hide()
	end

	if Settings["unitframes-show-player-debuffs"] then
		player.Debuffs:Show()
	else
		player.Debuffs:Hide()
	end

	if Settings["unitframes-player-enable-castbar"] then
		player.CastAnchor:SetPoint("BOTTOM", YxUI.UIParent, 0, 118)
		YxUI:CreateMover(player.CastAnchor, 2)
	end

	YxUI:CreateMover(player)

	player:Refresh("ForceUpdate")
end

function UF:ConfigureTarget(target)
	if Settings["target-enable-portrait"] then
		target:EnableElement("Portrait")
	else
		target:DisableElement("Portrait")
	end

	if Settings["unitframes-show-target-buffs"] then
		target.Buffs:Show()
	else
		target.Buffs:Hide()
	end

	if Settings["unitframes-show-target-debuffs"] then
		target.Debuffs:Show()
	else
		target.Debuffs:Hide()
	end

	if Settings["unitframes-target-enable-castbar"] then
		target.CastAnchor:SetPoint("BOTTOM", YxUI.UIParent, 0, 146)
		YxUI:CreateMover(target.CastAnchor, 2)
	end

	YxUI:CreateMover(target)

	target:Refresh("ForceUpdate")
end

function UF:ConfigureTargetTarget(targetTarget)
	if Settings["target-enable"] then
		targetTarget:SetPoint("TOPRIGHT", YxUI.UnitFrames["target"], "BOTTOMRIGHT", 0, -2)
	end

	YxUI:CreateMover(targetTarget)
end

function UF:ConfigurePet(pet)
	if Settings["player-enable"] then
		pet:SetPoint("TOPLEFT", YxUI.UnitFrames["player"], "BOTTOMLEFT", 0, -2)
	end

	YxUI:CreateMover(pet)
end

function UF:ConfigureFocus(focus)
	if Settings["focus-enable-buffs"] or Settings["focus-enable-debuffs"] then
		focus:EnableElement("Auras")
		focus.Buffs:SetShown(Settings["focus-enable-buffs"])
		focus.Debuffs:SetShown(Settings["focus-enable-debuffs"])
	else
		focus:DisableElement("Auras")
	end

	YxUI:CreateMover(focus)
end

function UF:SpawnBossFrames()
	if Settings["unitframes-boss-enable"] then
		self:DisableBlizzardUnitFrame("boss")
		for i = 1, 8 do
			local Boss = YxUI.UnitFrames:CreateUnitButton("boss" .. i, "YxUI Boss " .. i, YxUI.StyleFuncs["boss"])
			Boss:SetSize(Settings["unitframes-boss-width"], Settings["unitframes-boss-health-height"] + Settings["unitframes-boss-power-height"] + 3)
			Boss:SetParent(YxUI.UIParent)
			if Settings["unitframes-boss-buffs"] or Settings["unitframes-boss-debuffs"] then
				Boss.Buffs:SetShown(Settings["unitframes-boss-buffs"])
				Boss.Debuffs:SetShown(Settings["unitframes-boss-debuffs"])
			else
				Boss:DisableElement("Auras")
			end

			if i == 1 then
				Boss:SetPoint("LEFT", YxUI.UIParent, 300, 200)
			else
				Boss:SetPoint("TOP", YxUI.UnitFrames["boss" .. (i-1)], "BOTTOM", 0, -28) -- -2
			end

			YxUI:CreateMover(Boss)

			YxUI.UnitFrames["boss" .. i] = Boss
		end
	end
end

function UF:GetGrowthOffsets(point, spacing)
	if point == "LEFT" then
		return spacing, 0
	end

	if point == "RIGHT" then
		return -spacing, 0
	end

	if point == "TOP" then
		return 0, -spacing
	end

	if point == "BOTTOM" then
		return 0, spacing
	end

	return 0, 0
end

function UF:BuildHeaderAttributes(options)
	assert(options.width and options.height, "header attributes require width and height")

	return {
		"initial-width", options.width, "initial-height", options.height,
		"showSolo", options.showSolo, "showPlayer", options.showPlayer,
		"showParty", options.showParty, "showRaid", options.showRaid,
		"point", options.point, "xOffset", options.xOffset or 0,
		"yOffset", options.yOffset or 0,
	}
end

local HEADER_INITIAL_CONFIG = [[
	local Header = self:GetParent()
	local unit

	if Header:GetAttribute("showRaid") then
		unit = "raid"
	elseif Header:GetAttribute("showParty") then
		unit = "party"
	end

	if unit and Header:GetAttribute("YxUI-headerType") == "pet" then
		unit = unit .. "pet"
	end

	self:SetWidth(Header:GetAttribute("initial-width"))
	self:SetHeight(Header:GetAttribute("initial-height"))
	self:SetAttribute("*type1", "target")
	self:SetAttribute("*type2", "togglemenu")
	RegisterUnitWatch(self)
	Header:CallMethod("InitializeChild", self:GetName(), unit)
]]

function UF:SetGroupHeaderShowSolo(header, visibility, enabled)
	if not header then
		return
	end

	header:SetAttribute("showSolo", enabled)
	local condition
	if visibility == "party" then
		condition = enabled and "[group:raid] hide; [group:party] show; [nogroup] show; hide" or "[group:raid] hide; [group:party] show; hide"
	else
		condition = enabled and "[group:raid] show; [nogroup] show; hide" or "[group:raid] show; hide"
	end

	RegisterAttributeDriver(header, "state-visibility", condition)
end

function UF:CreateGroupHeader(name, petHeader, visibility, attributes)
	assert(not InCombatLockdown(), "secure group headers cannot be created during combat")

	local template = petHeader and "SecureGroupPetHeaderTemplate" or "SecureGroupHeaderTemplate"
	local header = CreateFrame("Frame", name, YxUI.UIParent, template)
	-- Header children need their own secure handlers. This matches oUF's group
	-- button template and, together with RegisterUnitWatch in the initializer,
	-- lets Blizzard show a child when its assigned unit exists.
	header:SetAttribute("template", "SecureUnitButtonTemplate, SecureHandlerStateTemplate, SecureHandlerEnterLeaveTemplate")
	header:SetAttribute("YxUI-headerType", petHeader and "pet" or "group")

	header.InitializeChild = function(_, childName, guessedUnit)
		local child = _G[childName]

		if not child or child._unitFrameInitialized then
			return
		end

		-- SecureGroupHeaderTemplate does not guarantee that the child's concrete
		-- unit attribute is assigned before initialConfigFunction runs.  oUF
		-- handles the same ordering by passing a family-level guessed unit to its
		-- style function; use the concrete unit when available and otherwise do
		-- the same so every party/raid (and pet) child is styled exactly once.
		local unit = child:GetAttribute("unit") or guessedUnit

		if not unit then
			return
		end

		local style = petHeader and (visibility == "party" and "partypet" or "raidpet") or visibility
		YxUI.UnitFrames:InitializeHeaderChild(child, unit, YxUI.StyleFuncs[style])
	end

	for index = 1, #attributes, 2 do
		header:SetAttribute(attributes[index], attributes[index + 1])
	end

	-- Setting the secure initializer can immediately create children when the
	-- player is already grouped. Install the insecure callback and all header
	-- attributes first so those children can be styled on every client.
	header:SetAttribute("initialConfigFunction", HEADER_INITIAL_CONFIG)

	-- Keep the secure visibility driver synchronized with showSolo changes.
	self:SetGroupHeaderShowSolo(header, visibility, attributes[attributes.showSoloIndex + 1])

	return header
end

local function HeaderAttributes(values)
	local attributes = {}

	for index = 1, #values do
		attributes[index] = values[index]
	end

	attributes.showSoloIndex = #attributes + 1
	attributes[attributes.showSoloIndex] = "showSolo"
	attributes[attributes.showSoloIndex + 1] = values.showSolo

	return attributes
end

function UF:UpdatePartyAnchorSize()
	local point = Settings["party-point"]
	local horizontal = Settings["party-point"] == "LEFT" or Settings["party-point"] == "RIGHT"
	local spacing = Settings["party-spacing"]
	local height = Settings["party-health-height"] + Settings["party-power-height"] + 3
	if self.PartyAnchor then
		self.PartyAnchor:SetSize(horizontal and 5 * Settings["party-width"] + 4 * spacing or Settings["party-width"], horizontal and height or 5 * height + 4 * spacing)
		local header = YxUI.UnitFrames["party"]
		if header then
			local anchor = point == "RIGHT" and "BOTTOMRIGHT" or point == "TOP" and "TOPLEFT" or "BOTTOMLEFT"
			header:ClearAllPoints()
			header:SetPoint(anchor, self.PartyAnchor, anchor)
		end
	end

	if self.PartyPetAnchor then
		local petHeight = Settings["party-pets-health-height"] + 2
		self.PartyPetAnchor:SetSize(horizontal and 5 * Settings["party-width"] + 4 * spacing or Settings["party-pets-width"], horizontal and petHeight or 5 * petHeight + 4 * spacing)
		local header = YxUI.UnitFrames["party-pets"]
		if header then
			local anchor = point == "RIGHT" and "TOPRIGHT" or point == "BOTTOM" and "BOTTOMLEFT" or "TOPLEFT"
			header:ClearAllPoints()
			header:SetPoint(anchor, self.PartyPetAnchor, anchor)
		end
	end
end

function UF:SpawnPartyHeaders()
	if Settings["party-enable"] then
		self:DisableBlizzardUnitFrame("party")
	end

	if not Settings["party-enable"] then
		return
	end

	local xOffset, yOffset = self:GetGrowthOffsets(Settings["party-point"], Settings["party-spacing"])
	local base = {"initial-width", Settings["party-width"], "initial-height", Settings["party-health-height"] + Settings["party-power-height"] + 3, "isTesting", false, "showPlayer", true, "showParty", true, "showRaid", false, "xOffset", xOffset, "yOffset", yOffset, "point", Settings["party-point"]}

	base.showSolo = Settings["party-show-solo"]

	local Party = self:CreateGroupHeader("YxUI Party", false, "party", HeaderAttributes(base))
	self.PartyAnchor = CreateFrame("Frame", "YxUI Party Anchor", YxUI.UIParent)
	self:UpdatePartyAnchorSize()
	self.PartyAnchor:SetPoint("BOTTOMLEFT", YxUIChatFrameTop, "TOPLEFT", -3, 5)
	Party:SetPoint("BOTTOMLEFT", self.PartyAnchor)

	YxUI.UnitFrames["party"] = Party
	YxUI:CreateMover(self.PartyAnchor)

	if Settings["party-pets-enable"] then
		local petXOffset, petYOffset = self:GetGrowthOffsets(Settings["party-point"], Settings["party-spacing"])
		local pet = {"initial-width", Settings["party-pets-width"], "initial-height", Settings["party-pets-health-height"] + 2, "isTesting", false, "showPlayer", false, "showParty", true, "showRaid", false, "xOffset", petXOffset, "yOffset", petYOffset, "point", Settings["party-point"]}

		pet.showSolo = Settings["party-show-solo"]

		local PartyPet = self:CreateGroupHeader("YxUI Party Pets", true, "party", HeaderAttributes(pet))
		self.PartyPetAnchor = CreateFrame("Frame", "YxUI Party Pet Anchor", YxUI.UIParent)
		self:UpdatePartyAnchorSize()
		self.PartyPetAnchor:SetPoint("TOPLEFT", self.PartyAnchor, "BOTTOMLEFT", 0, -2)
		PartyPet:SetPoint("TOPLEFT", self.PartyPetAnchor)

		YxUI:CreateMover(self.PartyPetAnchor)
		YxUI.UnitFrames["party-pets"] = PartyPet
	end

	self:UpdatePartyAnchorSize()
end

function UF:SpawnRaidHeaders()
	if not Settings["raid-enable"] then
		return
	end

	local common = {"initial-width", Settings["raid-width"], "initial-height", Settings["raid-health-height"] + Settings["raid-power-height"] + 3, "isTesting", false, "showPlayer", true, "showParty", false, "showRaid", true, "point", Settings["raid-point"], "xOffset", Settings["raid-x-offset"], "yOffset", Settings["raid-y-offset"], "maxColumns", Settings["raid-max-columns"], "unitsPerColumn", Settings["raid-units-per-column"], "columnSpacing", Settings["raid-column-spacing"], "columnAnchorPoint", Settings["raid-column-anchor"]}

	common.showSolo = Settings["raid-show-solo"]

	local Raid = self:CreateGroupHeader("YxUI Raid", false, "raid", HeaderAttributes(common))
	local unitHeight, maxSize = Settings["raid-health-height"] + Settings["raid-power-height"] + 1, floor(40 / Settings["raid-max-columns"])

	self.RaidAnchor = CreateFrame("Frame", "YxUI Raid Anchor", YxUI.UIParent)
	self.RaidAnchor:SetSize(maxSize * Settings["raid-width"] + maxSize * Settings["raid-x-offset"] - 2,
		unitHeight * (Settings["raid-max-columns"] + 1) + Settings["raid-y-offset"] * (Settings["raid-max-columns"] - 1))
	self.RaidAnchor:SetPoint("BOTTOMLEFT", YxUIChatFrameTop, "TOPLEFT", -3, 10)

	if CompactRaidFrameContainer then
		CompactRaidFrameContainer:UnregisterAllEvents()
		CompactRaidFrameContainer:SetParent(Hider)
		CompactRaidFrameManager:UnregisterAllEvents()
		CompactRaidFrameManager:SetParent(Hider)
	end

	Raid:SetPoint("BOTTOMLEFT", self.RaidAnchor)
	YxUI:CreateMover(self.RaidAnchor)
	YxUI.UnitFrames["raid"] = Raid
	UpdateRaidSortingMethod(Settings["raid-sorting-method"])

	if Settings["raid-pets-enable"] then
		local pet = {"initial-width", Settings["raid-pets-width"], "initial-height", Settings["raid-pets-health-height"] + 2, "isTesting", false, "showPlayer", true, "showParty", false, "showRaid", true, "point", Settings["raid-point"], "xOffset", Settings["raid-x-offset"], "yOffset", Settings["raid-y-offset"], "maxColumns", Settings["raid-max-columns"], "unitsPerColumn", Settings["raid-units-per-column"], "columnSpacing", Settings["raid-column-spacing"], "columnAnchorPoint", Settings["raid-column-anchor"]}

		pet.showSolo = Settings["raid-show-solo"]

		local RaidPet = self:CreateGroupHeader("YxUI Raid Pets", true, "raid", HeaderAttributes(pet))

		self.RaidPetAnchor = CreateFrame("Frame", "YxUI Raid Pet Anchor", YxUI.UIParent)
		self.RaidPetAnchor:SetSize(maxSize * Settings["raid-width"] + maxSize * Settings["raid-x-offset"] - 2,
			Settings["raid-pets-health-height"] * (Settings["raid-max-columns"] + Settings["raid-y-offset"]) - 1)
		self.RaidPetAnchor:SetPoint("BOTTOMLEFT", self.RaidAnchor, "TOPLEFT")
		YxUI:CreateMover(self.RaidPetAnchor)
		RaidPet:SetPoint("TOPLEFT", self.RaidPetAnchor)
		YxUI.UnitFrames["raid-pets"] = RaidPet
	end
end

function UF:SpawnNameplates()
	if not Settings["nameplates-enable"] then
		return
	end

	UF:CreateNamePlateDriver()
end

--/run UnitFrameFakeBosses()
UnitFrameFakeBosses = function()
	local Boss

	for i = 1, 8 do
		Boss = YxUI.UnitFrames["boss"..i]

		if not Boss:IsShown() then
			Boss.unit = "player"
			UnregisterUnitWatch(Boss)
			RegisterUnitWatch(Boss, true)
			Boss:Show()
		else
			Boss.unit = nil
			UnregisterUnitWatch(Boss)
			Boss:Hide()
		end
	end
end
