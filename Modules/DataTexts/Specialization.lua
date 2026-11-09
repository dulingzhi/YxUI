local YxUI, Language, Assets, Settings = select(2, ...):get()

local IsReadable = YxUI.IsDataTextReadable
local SpecAPI = C_SpecializationInfo
local LegacyTrees = YxUI.IsVanilla or YxUI.IsTBC
local ShowBuildPoints = LegacyTrees or YxUI.IsForever

local ForeverTreeNames = {
	WARRIOR = {"Arms", "Fury", "Protection"},
	PALADIN = {"Holy", "Protection", "Retribution"},
	HUNTER = {"Beast Mastery", "Marksmanship", "Survival"},
	ROGUE = {"Assassination", "Combat", "Subtlety"},
	PRIEST = {"Discipline", "Holy", "Shadow"},
	SHAMAN = {"Elemental", "Enhancement", "Restoration"},
	MAGE = {"Arcane", "Fire", "Frost"},
	WARLOCK = {"Affliction", "Demonology", "Destruction"},
	DRUID = {"Balance", "Feral Combat", "Restoration"},
}

local function ReadModernSpec()
	local index = SpecAPI and SpecAPI.GetSpecialization and SpecAPI.GetSpecialization()
	if not (IsReadable(index) and type(index) == "number" and index > 0) then
		return
	end
	local _, name, _, _, role = SpecAPI.GetSpecializationInfo(index)
	if not (IsReadable(name) and type(name) == "string" and name ~= "") then
		return
	end
	return {name = name, role = IsReadable(role) and role or nil}
end

local function ReadTalentTrees()
	local _, _, classID = UnitClass("player")
	local count = SpecAPI and SpecAPI.GetNumSpecializationsForClassID and IsReadable(classID) and SpecAPI.GetNumSpecializationsForClassID(classID)
	if not count and GetNumTalentTabs then
		count = GetNumTalentTabs()
	end
	if not (IsReadable(count) and type(count) == "number") then
		return
	end
	local trees, bestName, mostPoints, total = {}, nil, -1, 0
	local group = SpecAPI and SpecAPI.GetActiveSpecGroup and SpecAPI.GetActiveSpecGroup()
	if not (IsReadable(group) and type(group) == "number") then
		group = nil
	end
	for index = 1, count do
		local name, points
		if SpecAPI and SpecAPI.GetSpecializationInfo then
			local _, treeName, _, _, _, _, spent = SpecAPI.GetSpecializationInfo(index, false, false, nil, nil, group)
			name, points = treeName, spent
		elseif GetTalentTabInfo then
			local treeName, _, spent = GetTalentTabInfo(index)
			name, points = treeName, spent
		end
		if not (IsReadable(name) and IsReadable(points) and type(name) == "string" and type(points) == "number") then
			return
		end
		trees[#trees + 1] = {name = name, points = points}
		total = total + points
		if points > mostPoints then
			bestName, mostPoints = name, points
		end
	end
	if #trees == 0 then
		return
	end
	return {name = total > 0 and bestName or "Unassigned", trees = trees, group = group}
end

local function ReadForeverTrees()
	local Traits = C_Traits
	if not (SpecAPI and SpecAPI.GetActiveSpecGroup and SpecAPI.GetCombatConfigIDForSpecGroup
		and Traits and Traits.GetConfigInfo and Traits.GetTreeNodes and Traits.GetNodeInfo) then
		return
	end

	local group = SpecAPI.GetActiveSpecGroup()
	if not (IsReadable(group) and type(group) == "number") then return end
	local configID = SpecAPI.GetCombatConfigIDForSpecGroup(group)
	if not (IsReadable(configID) and type(configID) == "number") then return end
	local config = Traits.GetConfigInfo(configID)
	if not (IsReadable(config) and IsReadable(config.treeIDs) and type(config.treeIDs) == "table") then return end
	local treeCount = #config.treeIDs
	if treeCount ~= 1 and treeCount ~= 3 then return end

	local nodes = {}
	for treeIndex, treeID in ipairs(config.treeIDs) do
		if not (IsReadable(treeID) and type(treeID) == "number") then return end
		local nodeIDs = Traits.GetTreeNodes(treeID)
		if not (IsReadable(nodeIDs) and type(nodeIDs) == "table") then return end
		for _, nodeID in ipairs(nodeIDs) do
			if not (IsReadable(nodeID) and type(nodeID) == "number") then return end
			local node = Traits.GetNodeInfo(configID, nodeID)
			if not (IsReadable(node) and IsReadable(node.entryIDs) and type(node.entryIDs) == "table") then return end
			if #node.entryIDs > 0 then
				local x, rank = node.posX, node.activeRank
				if not (IsReadable(x) and type(x) == "number" and IsReadable(rank) and type(rank) == "number") then return end
				if rank < 0 or rank % 1 ~= 0 then return end
				nodes[#nodes + 1] = {x = x, rank = rank, tree = treeIndex}
			end
		end
	end
	if #nodes < 3 then return end

	if treeCount == 1 then
		local columns, seen = {}, {}
		for _, node in ipairs(nodes) do
			if not seen[node.x] then
				seen[node.x] = true
				columns[#columns + 1] = node.x
			end
		end
		table.sort(columns)
		local gaps = {}
		for index = 1, #columns - 1 do
			gaps[#gaps + 1] = {index = index, width = columns[index + 1] - columns[index]}
		end
		if #gaps < 2 then return end
		table.sort(gaps, function(a, b) return a.width > b.width end)
		if #gaps > 2 and gaps[2].width <= gaps[3].width * 1.5 then return end
		local first = math.min(gaps[1].index, gaps[2].index)
		local second = math.max(gaps[1].index, gaps[2].index)
		for _, node in ipairs(nodes) do
			node.tree = node.x <= columns[first] and 1 or (node.x <= columns[second] and 2 or 3)
		end
	end

	local _, class = UnitClass("player")
	if not (IsReadable(class) and type(class) == "string") then return end
	local names = ForeverTreeNames[class]
	local trees, bestName, mostPoints, total = {}, nil, -1, 0
	for index = 1, 3 do
		trees[index] = {name = names and names[index] or ("Tree " .. index), points = 0, count = 0}
	end
	for _, node in ipairs(nodes) do
		local tree = trees[node.tree]
		tree.points = tree.points + node.rank
		tree.count = tree.count + 1
	end
	for _, tree in ipairs(trees) do
		if tree.count == 0 then return end
		total = total + tree.points
		if tree.points > mostPoints then
			bestName, mostPoints = tree.name, tree.points
		end
		tree.count = nil
	end
	return {name = total > 0 and bestName or "Unassigned", trees = trees, group = group}
end

local function GetSpec(self)
	local value
	if YxUI.IsForever then
		value = ReadForeverTrees()
	elseif LegacyTrees then
		value = ReadTalentTrees()
	else
		value = ReadModernSpec()
	end
	return YxUI.GetDataTextLastValue(self, value)
end

local function Update(self)
	local data = GetSpec(self)
	local name = data and data.name or "--"
	if ShowBuildPoints and data and data.trees then
		local points = {}
		for index, tree in ipairs(data.trees) do
			points[index] = tree.points
		end
		self.Text:SetFormattedText("|cFF%s%s|r |cFF%s(%s)|r", Settings["data-text-label-color"], name, YxUI.ValueColor, table.concat(points, "/"))
	else
		self.Text:SetFormattedText("|cFF%s%s|r", Settings["data-text-label-color"], name)
	end
end

local function OnEnter(self)
	if not self:SetTooltip() then
		return
	end
	local data = GetSpec(self)
	GameTooltip:AddLine(SPECIALIZATION or TALENTS or "Specialization", 1, 0.82, 0)
	GameTooltip:AddLine(" ")
	if data then
		GameTooltip:AddDoubleLine("Current", data.name, 1, 1, 1, 1, 1, 1)
		if data.role and _G[data.role] then
			GameTooltip:AddDoubleLine("Role", _G[data.role], 1, 1, 1, 1, 1, 1)
		end
		if data.group and data.group > 1 then
			GameTooltip:AddDoubleLine("Talent group", tostring(data.group), 1, 1, 1, 1, 1, 1)
		end
		if data.trees then
			GameTooltip:AddLine(" ")
			for _, tree in ipairs(data.trees) do
				GameTooltip:AddDoubleLine(tree.name, tostring(tree.points), 1, 1, 1, 1, 1, 1)
			end
		end
		GameTooltip:AddLine(" ")
	end
	GameTooltip:AddLine("Click to open talents", 0.5, 0.85, 1)
	GameTooltip:Show()
end

local function OnMouseUp(self, button)
	if button ~= "LeftButton" or InCombatLockdown() then
		return
	end
	if (YxUI.IsMainline or YxUI.IsForever) and PlayerSpellsUtil and PlayerSpellsUtil.ToggleClassTalentOrSpecFrame then
		PlayerSpellsUtil.ToggleClassTalentOrSpecFrame()
	elseif ToggleTalentFrame then
		ToggleTalentFrame()
	end
end

local function OnEnable(self)
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_TALENT_UPDATE")
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	if LegacyTrees then
		self:RegisterEvent("CHARACTER_POINTS_CHANGED")
	elseif YxUI.IsForever then
		self:RegisterEvent("TRAIT_CONFIG_UPDATED")
		self:RegisterEvent("TRAIT_NODE_CHANGED")
	else
		self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	end
	self:SetScript("OnEvent", function(anchor, event, unit)
		if event == "PLAYER_SPECIALIZATION_CHANGED" and unit ~= "player" then return end
		Update(anchor)
	end)
	self:SetScript("OnMouseUp", OnMouseUp)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", function() GameTooltip:Hide() end)
	self:Update()
end

local function OnDisable(self)
	self:UnregisterAllEvents()
	self:SetScript("OnEvent", nil)
	self:SetScript("OnMouseUp", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)
	self.Text:SetText("")
end

YxUI:AddDataText("Specialization", OnEnable, OnDisable, Update)
