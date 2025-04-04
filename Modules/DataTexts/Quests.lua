local YxUI, Language, Assets, Settings = select(2, ...):get()

local select = select
local GetMaxNumQuestsCanAccept = C_QuestLog.GetMaxNumQuestsCanAccept
local Label = QUESTS_LABEL

local GetNumQuests

if YxUI.IsMainline then
	GetNumQuests = C_QuestLog.GetNumQuestLogEntries
else
	GetNumQuests = GetNumQuestLogEntries
end

local OnMouseUp = function()
	ToggleFrame(YxUI.IsMainline and QuestMapFrame or QuestLogFrame)
end

local Update = function(self)
	self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%s/%s|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, select(2, GetNumQuests()), GetMaxNumQuestsCanAccept())
end

local OnEnable = function(self)
	self:RegisterEvent("QUEST_LOG_UPDATE")
	self:SetScript("OnEvent", Update)
	self:SetScript("OnMouseUp", OnMouseUp)

	self:Update()
end

local OnDisable = function(self)
	self:UnregisterEvent("QUEST_LOG_UPDATE")
	self:SetScript("OnEvent", nil)
	self:SetScript("OnMouseUp", nil)

	self.Text:SetText("")
end

YxUI:AddDataText("Quests", OnEnable, OnDisable, Update)