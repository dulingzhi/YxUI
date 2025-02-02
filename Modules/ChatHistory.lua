----------------------------------------------------------------------------------------
--	Chat history (TrueChatFrameHistory by Kanegasi)
----------------------------------------------------------------------------------------
local Y, L, A, C, D = YxUIGlobal:get()
local ChatHistory = Y:NewModule("ChatHistory")

local DB, CF, cfid, hook = {}, {}, {}, {}

local function prnt(frame, message)
    if frame.historyBuffer:PushFront({ message = message, r = 1, g = 1, b = 1, extraData = { [1] = "temp", n = 1 }, timestamp = GetTime() }) then
        if frame:GetScrollOffset() ~= 0 then
            frame:ScrollUp()
        end
        frame:MarkDisplayDirty()
    end
end

-- CircularBuffer bug (feature?) due to modulus usage (CircularBuffer.lua:38,46,123), causing elements to be added at the back when buffer is full, screwing up saved data
function ChatHistory:pushfront(frame)
    if frame == COMBATLOG then return end                    -- ensure Combat Log is ignored
    if not hook[frame] then
        hook[frame] = true                                   -- hook only once, hook doesn't go away when temporary frames are closed (11+)
        hooksecurefunc(frame.historyBuffer, "PushFront", function(frame)
            while #frame.elements > frame.maxElements - 5 do -- minimum of 2 less than max is needed, 5 to provide some buffer
                table.remove(frame.elements, 1)
            end
            frame.headIndex = #frame.elements
        end)
    end
end

-- element fading timestamp comes from GetTime() (ScrollingMessageFrame.lua:583), causing restored elements to effectively not fade if you restart your computer
function ChatHistory:timestamps(frame)
    local nameorid, timestamp = CF[frame] > NUM_CHAT_WINDOWS and frame.name or CF[frame], GetTime()
    if DB[nameorid] then
        for element = #DB[nameorid], 1, -1 do
            DB[nameorid][element].timestamp = timestamp
        end
    end
end

function ChatHistory:Setup()
    hooksecurefunc("FCF_SetWindowName", function(frame)
        local id = frame:GetID()
        CF[frame] = id   -- main ChatFrame pointers
        cfid[id] = frame -- access by id, used for /tcfh and ordered iteration of ChatHistory.missed
    end)
    hooksecurefunc("FCFManager_RegisterDedicatedFrame", function(frame)
        if CF[frame] > NUM_CHAT_WINDOWS then
            self:pushfront(frame)
            if DB[frame.name] then
                self:timestamps(frame)
                frame.historyBuffer:ReplaceElements(DB[frame.name])
            end
        end
    end) -- restore any history for Pet Combat Log and whispers
    hooksecurefunc("FCFManager_UnregisterDedicatedFrame", function(frame)
        if CF[frame] > NUM_CHAT_WINDOWS then
            DB[frame.name] = frame.historyBuffer.elements
        end
    end) -- save any history for Pet Combat Log and whispers

    local frames = { GetFramesRegisteredForEvent("PLAYER_LEAVING_WORLD") }
    while frames[1] ~= self do
        frames[1]:UnregisterEvent("PLAYER_LEAVING_WORLD")
        frames[1]:RegisterEvent("PLAYER_LEAVING_WORLD")
        table.remove(frames, 1)
    end -- attempt to ensure TCFH is first to trigger upon UI unload
end

function ChatHistory:DisplayHistory()
    if self.pew then return end
    for id = #cfid, 1, -1 do
        if cfid[id] ~= COMBATLOG then
            self:pushfront(cfid[id])
            self:timestamps(cfid[id])
            if id <= NUM_CHAT_WINDOWS and DB[id] and #DB[id] > 0 then
                cfid[id].historyBuffer:ReplaceElements(DB[id])
            end -- restore any history for ChatFrame1-10 (excluding Combat Log)
            prnt(cfid[id], "|cffBCEE68--- " .. HISTORY .. " ---|r")
        end
    end
    self.pew = true
end

function ChatHistory:PLAYER_LEAVING_WORLD()
    for frame, id in next, CF do
        if frame ~= COMBATLOG then
            DB[id > NUM_CHAT_WINDOWS and frame.name or id] = frame.historyBuffer.elements
        end
    end -- save any history for all ChatFrames (excluding Combat Log)
end

function ChatHistory:ADDON_LOADED(_, addon)
    if addon == Y.AddOnName then
        self:UnEvent("ADDON_LOADED", self.ADDON_LOADED)
        self:Setup()
    end
end

function ChatHistory:Load()
    if not C["chat-history-enable"] then
        return
    end
    YxUIData.ChatHistory = YxUIData.ChatHistory or {}
    DB = YxUIData.ChatHistory

    for frame, elements in next, DB do
        for element = #elements, 1, -1 do
            if elements[element].extraData then
                for _, v in next, elements[element].extraData do
                    if v == "temp" then
                        table.remove(DB[frame], element)
                        break
                    end -- remove TCFH's entries
                    -- note to authors: passing "temp" in _any_ arg beyond the r,g,b args of AddMessage
                    -- will allow your message to also be removed upon chat restoration, if you so desire
                    -- examples: frame:AddMessage("message",r,g,b,"temp")
                    -- frame:AddMessage("message",r,g,b,chatTypeID,accessID,lineID,"temp")
                end
            end
        end
    end

    self:Event('PLAYER_LEAVING_WORLD', self.PLAYER_LEAVING_WORLD)
    self:DisplayHistory()
end

ChatHistory:Event("ADDON_LOADED", ChatHistory.ADDON_LOADED)
