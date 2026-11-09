local YxUI, Language, Assets, Settings = select(2, ...):get()
local Chat = YxUI:GetModule("Chat")
local DefaultHistoryLimit = 25
local LegacyMaxHistoryMessages = 50
local MessageTuplePool, MessageListPool = {}, {}
local HistoryVersion = 4
local UnknownBNetName = "Battle.net friend"

local function IsReadable(value)
	return value ~= nil and (not issecretvalue or not issecretvalue(value))
end

local function SafeName(value)
	if not IsReadable(value) or type(value) ~= "string" or value == "" or value:find("|K", 1, true) then
		return nil
	end

	return value
end

local function ShortBNetName(value)
	value = SafeName(value)
	return value and (value:gsub("#%d+$", ""))
end

local function ShortenBNetSender(message)
	local count
	message, count = message:gsub("(%[[^%]]-)#%d+(|r%])", "%1%2", 1)
	if count > 0 then
		return message
	end
	return (message:gsub("(%[[^%]]-)#%d+(%])", "%1%2", 1))
end

local function ResolveBNetAccount(accountID)
	if not IsReadable(accountID) then
		return nil, nil, nil
	end

	accountID = tonumber(accountID)
	if not accountID or accountID <= 0 then
		return nil, nil, nil
	end

	if C_BattleNet and C_BattleNet.GetAccountInfoByID then
		local ok, info = pcall(C_BattleNet.GetAccountInfoByID, accountID)
		if ok and IsReadable(info) and type(info) == "table" then
			local battleTag = SafeName(info.battleTag)
			return ShortBNetName(info.accountName) or ShortBNetName(battleTag), battleTag, accountID
		end
	end

	return nil, nil, accountID
end

-- Save a literal display name; Blizzard's |K...|k identifiers can refer to another friend after relogging.
local function FreezeBNetMessage(message, senderName, senderID, resolveCurrent)
	message = message:gsub("|HBNplayer:.-|h.-|h", function(link)
		local linkID = tonumber(link:match("^|HBNplayer:[^:]*:([^:]+):"))
		local linkName
		if resolveCurrent then
			linkName = select(1, ResolveBNetAccount(linkID))
			if not linkName and linkID and senderID == linkID then
				linkName = senderName
			end
		end

		local display = link:match("|h(.-)|h$") or ""
		if display == "" then
			return "[" .. (linkName or UnknownBNetName) .. "]"
		end
		return (display:gsub("|K.-|k", linkName or UnknownBNetName))
	end)

	message = message:gsub("|K.-|k", resolveCurrent and (senderName or UnknownBNetName) or UnknownBNetName)
	return ShortenBNetSender(message)
end

local function CurrentBNetAccount(info, battleTag)
	if not IsReadable(info) or type(info) ~= "table" or SafeName(info.battleTag) ~= battleTag then
		return nil
	end

	local id = IsReadable(info.bnetAccountID) and tonumber(info.bnetAccountID)
	local name = SafeName(info.accountName)
	if id and id > 0 and name and not name:find("[|:]") then
		return {ID = id, Name = name}
	end
end

local function GetCurrentBNetFriends()
	local accounts = {}
	if not BNGetNumFriends or not (C_BattleNet and C_BattleNet.GetFriendAccountInfo) then
		return accounts
	end

	local ok, count = pcall(BNGetNumFriends)
	if not ok or not IsReadable(count) or type(count) ~= "number" or count < 0 or count > 10000 then
		return accounts
	end

	for index = 1, count do
		local success, info = pcall(C_BattleNet.GetFriendAccountInfo, index)
		if success and IsReadable(info) and type(info) == "table" then
			local tag = SafeName(info.battleTag)
			if tag then
				accounts[tag] = CurrentBNetAccount(info, tag)
			end
		end
	end

	return accounts
end

local function GetCurrentBNetAccount(entry, accounts)
	local tag = SafeName(entry.BNetBattleTag)
	if not tag or not tag:match("#%d+$") then
		return nil
	end

	local id = IsReadable(entry.BNetSessionID) and tonumber(entry.BNetSessionID)
	if id and id > 0 and C_BattleNet and C_BattleNet.GetAccountInfoByID then
		local ok, info = pcall(C_BattleNet.GetAccountInfoByID, id)
		if ok then
			local match = CurrentBNetAccount(info, tag)
			if match then
				return match
			end
		end
	end

	return accounts[tag]
end

local function RestorePlayerLinks(message)
	return (message:gsub("|Hplayer:([^|]+)|h(.-)|h", function(options, display)
		local name = SafeName(options:match("^([^:]+)"))
		if not name or name:find("[|:]", 1) then
			return "|Hplayer:" .. options .. "|h" .. display .. "|h"
		end

		if GetPlayerLink then
			return GetPlayerLink(name, display)
		end
		return "|Hplayer:" .. name .. "|h" .. display .. "|h"
	end))
end

local function RestoreBNetLink(message, entry, accounts)
	local name = ShortBNetName(entry.BNetName) or ShortBNetName(entry.BNetBattleTag)
	if not name or not GetBNPlayerLink then
		return message
	end

	local account = GetCurrentBNetAccount(entry, accounts)
	if not account then
		return message
	end

	local linked = false
	return (message:gsub("%[[^%]]+%]", function(display)
		if linked then
			return display
		end

		local plain = display:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
		if plain ~= "[" .. name .. "]" then
			return display
		end

		linked = true
		return GetBNPlayerLink(account.Name, display, account.ID, 0, "BN_WHISPER", 0)
	end))
end

local function RestoreMessageLinks(entry, accounts)
	local message = RestorePlayerLinks(entry.Message)
	if entry.BNetBattleTag then
		message = RestoreBNetLink(message, entry, accounts)
	end
	return message
end

local function UpgradeBNetHistory(history)
	for _, frameHistory in pairs(history.Frames) do
		for _, entry in pairs(frameHistory.Records or {}) do
			if type(entry) == "table" and type(entry.Message) == "string" then
				if (history.Version or 0) < 3 then
					entry.Message = FreezeBNetMessage(entry.Message, nil, nil, false)
				elseif entry.BNetName or entry.BNetBattleTag or entry.BNetSessionID then
					entry.Message = ShortenBNetSender(entry.Message)
				end
				entry.BNetName = ShortBNetName(entry.BNetName)
			end
		end
	end
	history.Version = HistoryVersion
end

local NewFrameHistory = function()
	return {
		Start = 1,
		Count = 0,
		Capacity = Settings["chat-history-limit"] or DefaultHistoryLimit,
		Records = {},
	}
end

local AddToFrameHistory = function(History, Entry)
	local MaxMessagesPerFrame = History.Capacity or DefaultHistoryLimit
	local Index

	if History.Count < MaxMessagesPerFrame then
		Index = ((History.Start + History.Count - 1) % MaxMessagesPerFrame) + 1
		History.Count = History.Count + 1
	else
		Index = History.Start
		History.Start = (History.Start % MaxMessagesPerFrame) + 1
	end

	History.Records[Index] = Entry
end

local MigrateHistory = function(History)
	local Frames = {}
	local Count = History.Count or #History
	local Start = History.Start or 1
	local Records = History.Records or History

	for Offset = 1, Count do
		local Index = History.Records and (((Start + Offset - 2) % LegacyMaxHistoryMessages) + 1) or Offset
		local Entry = Records[Index]
		local FrameName = Entry and Entry.Frame

		if FrameName and FrameName ~= "ChatFrame2" then
			local FrameHistory = Frames[FrameName]

			if not FrameHistory then
				FrameHistory = NewFrameHistory()
				Frames[FrameName] = FrameHistory
			end

			AddToFrameHistory(FrameHistory, Entry)
		end
	end

	return {
		Version = 2,
		Frames = Frames,
	}
end

local function ResizeFrameHistory(history, capacity)
	local oldCapacity = history.Capacity or DefaultHistoryLimit
	if oldCapacity == capacity then
		return
	end

	local count = math.min(history.Count or 0, capacity)
	local startOffset = (history.Count or 0) - count
	local records = {}
	for i = 1, count do
		local index = ((history.Start + startOffset + i - 2) % oldCapacity) + 1
		records[i] = history.Records[index]
	end
	history.Start, history.Count, history.Capacity, history.Records = 1, count, capacity, records
end

function Chat:SetHistoryLimit(value)
	local history = self:GetHistory()
	if history.Capacity == value then
		return
	end
	for _, frameHistory in pairs(history.Frames) do
		ResizeFrameHistory(frameHistory, value)
	end
	history.Capacity = value
end

function Chat:GetHistory()
	if not YxUIData then
		YxUIData = {}
	end

	YxUIData.ChatHistory = YxUIData.ChatHistory or {}
	local ProfileKey = YxUI.UserProfileKey
	local History = YxUIData.ChatHistory[ProfileKey]

	if not History then
		History = {
			Version = HistoryVersion,
			Frames = {},
		}
		YxUIData.ChatHistory[ProfileKey] = History
	elseif not History.Frames then
		History = MigrateHistory(History)
		YxUIData.ChatHistory[ProfileKey] = History
	end

	if History.Version ~= HistoryVersion then
		UpgradeBNetHistory(History)
	end

	local capacity = Settings["chat-history-limit"] or DefaultHistoryLimit
	if History.Capacity ~= capacity then
		for _, frameHistory in pairs(History.Frames) do
			ResizeFrameHistory(frameHistory, capacity)
		end
		History.Capacity = capacity
	end

	return History
end

function Chat:GetFrameHistory(FrameName)
	local History = self:GetHistory()
	local FrameHistory = History.Frames[FrameName]

	if not FrameHistory then
		FrameHistory = NewFrameHistory()
		History.Frames[FrameName] = FrameHistory
	end

	return FrameHistory
end

function Chat:IterateHistory(History)
	local Offset = 0

	return function()
		Offset = Offset + 1

		if Offset <= History.Count then
			local Index = ((History.Start + Offset - 2) % (History.Capacity or DefaultHistoryLimit)) + 1

			return Offset, History.Records[Index]
		end
	end
end


function Chat:SaveMessage(frame, message, r, g, b, ...)
	if (not Settings["chat-enable-history"]) or self.RestoringHistory or (type(message) ~= "string") or not IsReadable(message) then
		return
	end

	local FrameName = frame:GetName()

	-- Combat messages are intentionally excluded: they are too frequent and are
	-- already managed by Blizzard's combat log.
	if (not FrameName) or FrameName == "ChatFrame2" then
		return
	end

	local History = self:GetFrameHistory(FrameName)
	local Entry = {}
	local _, _, _, event, eventArgs = ...
	if not IsReadable(event) then
		event = nil
	end
	local isBNet = event == "CHAT_MSG_BN_WHISPER" or event == "CHAT_MSG_BN_WHISPER_INFORM"
	local accountID

	if isBNet and IsReadable(eventArgs) and type(eventArgs) == "table" then
		accountID = eventArgs[13]
	end

	if not IsReadable(accountID) then
		accountID = message:match("|HBNplayer:[^:]*:([^:]+):")
	end

	if isBNet or message:find("|HBNplayer:", 1, true) or message:find("|K", 1, true) then
		local name, battleTag, sessionID = ResolveBNetAccount(accountID)
		Entry.Message = FreezeBNetMessage(message, name, sessionID, true)
		if isBNet or sessionID then
			Entry.BNetName = name
			Entry.BNetBattleTag = battleTag
			Entry.BNetSessionID = sessionID
		end
	else
		Entry.Message = message
	end

	Entry.Frame = FrameName
	Entry.R = r
	Entry.G = g
	Entry.B = b

	AddToFrameHistory(History, Entry)
end

function Chat:RestoreHistory()
	if not Settings["chat-enable-history"] then
		return
	end

	local History = self:GetHistory()
	local CurrentMessages = {}

	-- Chat is initialized after Blizzard has already printed login messages (such as the guild MOTD). Save and remove those messages so restored history can be inserted before them, then put the login messages back in their original order.
	for FrameName, FrameHistory in pairs(History.Frames) do
		local Frame = FrameName ~= "ChatFrame2" and _G[FrameName]

		if Frame and Frame.GetNumMessages and Frame.GetMessageInfo and Frame.Clear then
			local Messages = MessageListPool[#MessageListPool]

			if Messages then
				MessageListPool[#MessageListPool] = nil
			else
				Messages = {}
			end

			Messages.Count = 0

			for i = 1, Frame:GetNumMessages() do
				local Message, R, G, B, InfoID, AccessID, TypeID = Frame:GetMessageInfo(i)
				local Values = MessageTuplePool[#MessageTuplePool]

				if Values then
					MessageTuplePool[#MessageTuplePool] = nil
				else
					Values = {}
				end

				Values[1], Values[2], Values[3], Values[4] = Message, R, G, B
				Values[5], Values[6], Values[7] = InfoID, AccessID, TypeID
				Messages.Count = Messages.Count + 1
				Messages[Messages.Count] = Values
			end

			CurrentMessages[Frame] = Messages
			Frame:Clear()
		end
	end

	self.RestoringHistory = true
	local BNetFriends = GetCurrentBNetFriends()

	for FrameName, FrameHistory in pairs(History.Frames) do
		local Frame = FrameName ~= "ChatFrame2" and _G[FrameName]

		if Frame and Frame.AddMessage then
			for _, Entry in self:IterateHistory(FrameHistory) do
				Frame:AddMessage(RestoreMessageLinks(Entry, BNetFriends), Entry.R, Entry.G, Entry.B)
			end
		end
	end

	for Frame, Messages in pairs(CurrentMessages) do
		for i = 1, Messages.Count do
			local Message = Messages[i]

			Frame:AddMessage(unpack(Message, 1, 7))

			for j = 1, 7 do
				Message[j] = nil
			end

			Messages[i] = nil
			MessageTuplePool[#MessageTuplePool + 1] = Message
		end

		Messages.Count = nil
		CurrentMessages[Frame] = nil
		MessageListPool[#MessageListPool + 1] = Messages
	end

	self.RestoringHistory = nil
end
