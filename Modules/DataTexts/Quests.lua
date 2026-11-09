local YxUI, Language, Assets, Settings = select(2, ...):get()

local select = select
local GetMaxNumQuestsCanAccept = C_QuestLog.GetMaxNumQuestsCanAccept
local GetQuestDifficultyColor = GetQuestDifficultyColor
local Label = QUESTS_LABEL
local IsReadable = YxUI.IsDataTextReadable
local DungeonLabel = TRACKER_HEADER_DUNGEON or "Dungeon"
local EliteLabel = ELITE or "Elite"
local DungeonQuestTagID = Enum and Enum.QuestTag and Enum.QuestTag.Dungeon or 81
local EliteQuestTagID = Enum and Enum.QuestTag and Enum.QuestTag.Elite or 1
local GetQuestTagInfo = C_QuestLog.GetQuestTagInfo or GetQuestTagInfo

local GetNumQuests, GetQuestInfo

if YxUI.IsMainline then
	GetNumQuests = C_QuestLog.GetNumQuestLogEntries
	GetQuestInfo = C_QuestLog.GetInfo
else
	GetNumQuests = GetNumQuestLogEntries
	GetQuestInfo = function(Index)
		local Title, Level, _, IsHeader, _, IsComplete, _, QuestID = GetQuestLogTitle(Index)

		return {
			title = Title,
			level = Level,
			isHeader = IsHeader,
			isComplete = IsComplete,
			questID = QuestID,
		}
	end
end

local GetQuestTags = function(QuestID)
	if not GetQuestTagInfo or not IsReadable(QuestID) then
		return false, false
	end

	local TagInfo = GetQuestTagInfo(QuestID)

	if not IsReadable(TagInfo) then
		return false, false
	end

	if type(TagInfo) == "table" then
		if not IsReadable(TagInfo.tagID) or (issecretvalue and issecretvalue(TagInfo.isElite)) then
			return false, false
		end
		return TagInfo.tagID == DungeonQuestTagID, TagInfo.isElite or TagInfo.tagID == EliteQuestTagID
	end

	return TagInfo == DungeonQuestTagID, TagInfo == EliteQuestTagID
end

local OnMouseUp = function()
	if InCombatLockdown() then
		return
	end
	ToggleFrame(YxUI.IsMainline and QuestMapFrame or QuestLogFrame)
end

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	local Header
	local HasQuest

	local Count, QuestCount = GetNumQuests()
	if not IsReadable(Count) then
		GameTooltip:AddLine(Label, 1, 0.82, 0)
		GameTooltip:Show()
		return
	end

	GameTooltip:AddLine(Label, 1, 0.82, 0)
	GameTooltip:AddLine(" ")
	for Index = 1, Count do
		local Info = GetQuestInfo(Index)
		if not IsReadable(Info) then
			Info = nil
		elseif (issecretvalue and issecretvalue(Info.isHeader)) or not IsReadable(Info.title)
			or (not Info.isHeader and (not IsReadable(Info.level) or (issecretvalue and issecretvalue(Info.isComplete)))) then
			Info = nil
		end
		if Info and Info.isHeader then
			Header = Info.title
		elseif Info then
			if Header then
				if HasQuest then
					GameTooltip:AddLine(" ")
				end

				GameTooltip:AddLine(Header, 1, 0.82, 0)
				Header = nil
			end

			local Color = GetQuestDifficultyColor(Info.level)
			local QuestText = format("[%s] %s", Info.level, Info.title)
			local IsComplete = Info.isComplete == true or Info.isComplete == 1
			local IsDungeon, IsElite = GetQuestTags(Info.questID)
			local Status = {}
			local DifficultyColor = YxUI:RGBToHex(Color.r, Color.g, Color.b)

			if IsDungeon then
				Status[#Status + 1] = format("|cFF%s%s|r", DifficultyColor, DungeonLabel)
			end

			if IsElite then
				Status[#Status + 1] = format("|cFF%s%s|r", DifficultyColor, EliteLabel)
			end

			if IsComplete then
				Status[#Status + 1] = format("|cFF00FF00%s|r", COMPLETE)
			end

			if #Status > 0 then
				GameTooltip:AddDoubleLine(QuestText, table.concat(Status, ", "), Color.r, Color.g, Color.b, 1, 1, 1)
			else
				GameTooltip:AddLine(QuestText, Color.r, Color.g, Color.b)
			end

			HasQuest = true
		end
	end

	if IsReadable(QuestCount) then
		local Limit = GetMaxNumQuestsCanAccept()
		if HasQuest then
			GameTooltip:AddLine(" ")
		end
		GameTooltip:AddDoubleLine("Quest log", IsReadable(Limit) and format("%s / %s", QuestCount, Limit) or tostring(QuestCount), 1, 1, 1, 1, 1, 1)
	end

	GameTooltip:Show()
end

local OnLeave = function()
	GameTooltip:Hide()
end

local Update = function(self)
	local Count = select(2, GetNumQuests())
	local Limit = GetMaxNumQuestsCanAccept()
	local Values = YxUI.GetDataTextLastValue(self, IsReadable(Count) and IsReadable(Limit) and {Count, Limit} or nil)
	Count, Limit = Values and Values[1], Values and Values[2]
	self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%s/%s|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, IsReadable(Count) and Count or "--", IsReadable(Limit) and Limit or "--")
end

local OnEnable = function(self)
	self:RegisterEvent("QUEST_LOG_UPDATE")
	self:SetScript("OnEvent", Update)
	self:SetScript("OnMouseUp", OnMouseUp)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)

	self:Update()
end

local OnDisable = function(self)
	self:UnregisterEvent("QUEST_LOG_UPDATE")
	self:SetScript("OnEvent", nil)
	self:SetScript("OnMouseUp", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)

	self.Text:SetText("")
end

YxUI:AddDataText("Quests", OnEnable, OnDisable, Update)
