local Y, L, A, C, D = YxUIGlobal:get()
local Module = Y:GetModule("Chat")

local ChatFrame_MessageEventHandler = ChatFrame_MessageEventHandler
local ChatFrame1 = ChatFrame1

local entryEvent = 30
local entryTime = 31
local MAX_LOG_ENTRIES

local hasPrinted = false
local isPrinting = false

local EVENTS_TO_LOG = {
    "CHAT_MSG_INSTANCE_CHAT",
    "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_EMOTE",
    "CHAT_MSG_GUILD",
    "CHAT_MSG_OFFICER",
    "CHAT_MSG_PARTY",
    "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID",
    "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_RAID_WARNING",
    "CHAT_MSG_SAY",
    "CHAT_MSG_WHISPER",
    "CHAT_MSG_WHISPER_INFORM",
    "CHAT_MSG_YELL",
}

local function printChatHistory()
    if isPrinting then
        return
    end

    isPrinting = true
    local count = #YxUIData.ChatHistory

    if count > 0 then
        ChatFrame1:AddMessage(L["|cffbbbbbb    [Saved Chat History]|r"])

        for i = count, 1, -1 do
            local temp = YxUIData.ChatHistory[i]
            pcall(ChatFrame_MessageEventHandler, ChatFrame1, temp[entryEvent], unpack(temp))
        end

        ChatFrame1:AddMessage(L["|cffbbbbbb    [End of Saved Chat History]|r"])
    end

    isPrinting = false
    hasPrinted = true
end

local function saveChatHistory(event, ...)
    local temp = { ... }
    if not temp[1] then
        return
    end

    temp[entryEvent] = event
    temp[entryTime] = time()

    table.insert(YxUIData.ChatHistory, 1, temp)

    while #YxUIData.ChatHistory > MAX_LOG_ENTRIES do
        table.remove(YxUIData.ChatHistory, #YxUIData.ChatHistory)
    end
end

local function setupChatHistory(self, event, ...)
    if event == "PLAYER_LOGIN" then
        self:UnEvent(event)
        printChatHistory()
    elseif hasPrinted then
        saveChatHistory(event, ...)
    end
end

function Module:CreateChatHistory()
    MAX_LOG_ENTRIES = C["chat-log-max"]
    if MAX_LOG_ENTRIES == 0 then
        return
    end

    YxUIData.ChatHistory = YxUIData.ChatHistory or {}

    for _, event in ipairs(EVENTS_TO_LOG) do
        self:Event(event, setupChatHistory)
    end

    printChatHistory()
end

function Module:UpdateChatHistory()
    MAX_LOG_ENTRIES = C["chat-log-max"]
end
