local Y, L, A, C = select(2, ...):get()

local Quest = Y:NewModule("Quest Watch")

local function QuestLogLevel()
    local numEntries = GetNumQuestLogEntries()
    local scrollOffset = HybridScrollFrame_GetOffset(QuestLogListScrollFrame)
    local buttons = QuestLogListScrollFrame.buttons

    local questIndex, questLogTitle, questTitleTag, questNumGroupMates, questNormalText, questCheck
    local questLogTitleText, level, isHeader, isComplete

    for i = 1, QUESTS_DISPLAYED, 1 do
        questLogTitle = buttons[i]
        if not questLogTitle then break end -- precaution for other addons

        questIndex = i + scrollOffset
        questTitleTag = questLogTitle.tag
        questNumGroupMates = questLogTitle.groupMates
        questNormalText = questLogTitle.normalText
        questCheck = questLogTitle.check

        if questIndex <= numEntries then
            questLogTitleText, level, _, isHeader, _, isComplete = GetQuestLogTitle(questIndex)
            if not isHeader then
                questLogTitle:SetText("[" .. level .. "] " .. questLogTitleText)
                if isComplete then
                    questLogTitle.r = 1
                    questLogTitle.g = .5
                    questLogTitle.b = 1
                    questTitleTag:SetTextColor(1, .5, 1)
                end
            end

            if questNormalText then
                questNormalText:SetWidth(questNormalText:GetWidth() + 30)
                local width = questNormalText:GetStringWidth()
                if width then
                    if width <= 210 then
                        questCheck:SetPoint("LEFT", questLogTitle, "LEFT", width + 22, 0)
                    else
                        questCheck:SetPoint("LEFT", questLogTitle, "LEFT", 210, 0)
                    end
                end
            end

            if not questNumGroupMates.anchored then
                questNumGroupMates:SetPoint("LEFT")
                questNumGroupMates.anchored = true
            end
        end
    end
end


function Quest:StyleFrame()
    self:SetSize(240, 50) -- Not sure why, Blizzard did it.

    if Minimap:IsShown() then
        self:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", -70, -55)
    else
        self:SetPoint("TOPRIGHT", Y.UIParent, "TOPRIGHT", -300, -400)
    end

    self.Mover = Y:CreateMover(self)

    WatchFrame:ClearAllPoints()
    WatchFrame:SetPoint("TOPRIGHT", self)
    WatchFrame:SetClampedToScreen(false)
    WatchFrame:SetHeight(Y.ScreenHeight / 1.6)

    hooksecurefunc(WatchFrame, "SetPoint", function(f, _, parent)
        if parent ~= self then
            f:ClearAllPoints()
            f:SetPoint("TOPRIGHT", self)
        end
    end)

    local function updateMinimizeButton(self)
        WatchFrameCollapseExpandButton.__texture:DoCollapse(self.collapsed)
        WatchFrame.header:SetShown(not self.collapsed)
    end

    local function reskinMinimizeButton(button)
        Y.SkinExpandOrCollapse(button)
        button:GetNormalTexture():SetAlpha(0)
        button:GetPushedTexture():SetAlpha(0)
        button.__texture:DoCollapse(false)
    end

    reskinMinimizeButton(WatchFrameCollapseExpandButton)
    hooksecurefunc("WatchFrame_Collapse", updateMinimizeButton)
    hooksecurefunc("WatchFrame_Expand", updateMinimizeButton)

    local header = CreateFrame("Frame", nil, WatchFrameHeader)
    header:SetSize(1, 1)
    header:SetPoint("TOPLEFT")
    WatchFrame.header = header

    local bg = header:CreateTexture(nil, "ARTWORK")
    bg:SetTexture("Interface\\LFGFrame\\UI-LFG-SEPARATOR")
    bg:SetTexCoord(0, .66, 0, .31)
    bg:SetVertexColor(Y.UserColor.r, Y.UserColor.g, Y.UserColor.b, .8)
    bg:SetPoint("TOPLEFT", -25, 5)
    bg:SetSize(250, 30)

    hooksecurefunc("QuestLog_Update", QuestLogLevel)
    hooksecurefunc(QuestLogListScrollFrame, "update", QuestLogLevel)

    -- Extend the wrap text on WatchFrame, needs review
    hooksecurefunc("WatchFrame_SetLine", function(line)
        if not line.text then return end

        local height = line:GetHeight()
        if height > 28 and height < 34 then
            line:SetHeight(34)
            line.text:SetHeight(34)
        end
    end)

    -- Allow to send quest name
    hooksecurefunc("WatchFrameLinkButtonTemplate_OnClick", function(self)
        if IsModifiedClick("CHATLINK") and ChatEdit_GetActiveWindow() then
            if self.type == "QUEST" then
                local name, level = GetQuestLogTitle(GetQuestIndexForWatch(self.index))
                if name then
                    ChatEdit_InsertLink("[" .. name .. "]")
                end
            end
        end
    end)

    ----------------------------------------------------------------------------------------
    --	Difficulty color for WatchFrame lines
    ----------------------------------------------------------------------------------------
    hooksecurefunc("WatchFrame_Update", function()
        local numQuestWatches = GetNumQuestWatches()

        for i = 1, numQuestWatches do
            local questIndex = GetQuestIndexForWatch(i)
            if questIndex then
                local title, level = GetQuestLogTitle(questIndex)
                local col = GetQuestDifficultyColor(level)

                for j = 1, #WATCHFRAME_QUESTLINES do
                    if WATCHFRAME_QUESTLINES[j].text:GetText() == title then
                        WATCHFRAME_QUESTLINES[j].text:SetTextColor(col.r, col.g, col.b)
                        WATCHFRAME_QUESTLINES[j].col = col
                    end
                end
                for k = 1, #WATCHFRAME_ACHIEVEMENTLINES do
                    WATCHFRAME_ACHIEVEMENTLINES[k].col = nil
                end
            end
        end
    end)


    hooksecurefunc("WatchFrameLinkButtonTemplate_Highlight", function(self, onEnter)
        local i = self.startLine
        if not (self.lines[i] and self.lines[i].col) then return end
        if onEnter then
            self.lines[i].text:SetTextColor(1, 0.8, 0)
        else
            self.lines[i].text:SetTextColor(self.lines[i].col.r, self.lines[i].col.g, self.lines[i].col.b)
        end
    end)
end

function Quest:Load()
    self:StyleFrame()
end
