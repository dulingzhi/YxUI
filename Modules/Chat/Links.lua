local YxUI, Language, Assets, Settings = select(2, ...):get()
local Chat = YxUI:GetModule("Chat")
local format, sub, gsub = string.format, string.sub, string.gsub
local PreviousSetHyperlink = ItemRefTooltip.SetHyperlink
local ChatEdit_ChooseBoxForSend = ChatEdit_ChooseBoxForSend
local ChatEdit_ActivateChat, ChatEdit_ParseText, ChatEdit_UpdateHeader = ChatEdit_ActivateChat, ChatEdit_ParseText, ChatEdit_UpdateHeader

local function Discord(id)
	return format("|cFF7289DA|Hdiscord:https://discord.gg/%s|h[%s: %s]|h|r", id, Language["Discord"], id)
end
local function URL(url)
	return format("|cFF%s|Hurl:%s|h[%s]|h|r", Settings["ui-widget-color"], url, url)
end
local function Email(address)
	return format("|cFF%s|Hemail:%s|h[%s]|h|r", Settings["ui-widget-color"], address, address)
end
local function Friend(tag)
	return format("|cFF00AAFF|Hfriend:%s|h[%s]|h|r", tag, tag)
end

-- Pure, ordered transformation pipeline. Existing WoW hyperlinks are protected so
-- later stages never parse their payload or display text.
local function FormatLinks(message, options)
	if type(message) ~= "string" then
		return message
	end

	options = options or Settings

	local protectedLinks = {}
	local function ProtectLink(link)
		protectedLinks[#protectedLinks + 1] = link

		return "\001HYDRA" .. #protectedLinks .. "\002"
	end

	message = gsub(message, "|c%x%x%x%x%x%x%x%x|H.-|h.-|h|r", ProtectLink)

	if options["chat-enable-discord-links"] then
		message = gsub(message, "https://discord%.gg/([%w_-]+)", Discord)
		message = gsub(message, "(|cFF7289DA|Hdiscord:.-|h.-|h|r)", ProtectLink)
		message = gsub(message, "discord%.gg/([%w_-]+)", Discord)
	end

	if options["chat-enable-url-links"] then
		message = gsub(message, "(%a+://[%w%._~:/%?#%[%]@!$&'()%*+,;=%%-]+)", URL)
		message = gsub(message, "(www%.[%w_%-]+%.[%w%._~:/%?#%[%]@!$&'()%*+,;=%%-]+)", URL)
	end

	if options["chat-enable-email-links"] then
		message = gsub(message, "([%w_%.%-]+@[%w_%-]+%.[%w_%.%-]+)", Email)
	end

	if options["chat-enable-friend-links"] then
		message = gsub(message, "(%a[%w_]+#%d+)", Friend)
	end

	message = gsub(message, "\001HYDRA(%d+)\002", function(index)
		return protectedLinks[tonumber(index)]
	end)

	return message
end

local function FindLinks(_, _, message, ...)
	return false, FormatLinks(message), ...
end

local CopyDialog

local function ShowCopyDialog(text)
	if not CopyDialog then
		local Dialog = YxUI:GetModule("GUI").Dialog
		local Window = Dialog.CreateDialogShell(YxUI.UIParent, {
			Width = 440, Height = 94,
			Point = "CENTER", RelativeTo = YxUI.UIParent, X = 0, Y = 0,
			Strata = "DIALOG", ClampedToScreen = true,
		})
		Dialog.CreateDialogHeader(Window, {
			RightInset = 26,
			Text = Language["Copy"],
		})
		Dialog.CreateDialogCloseControl(Window, {
			Point = "TOPRIGHT", RelativeTo = Window, X = -3, Y = -3,
			HoverR = 1, HoverG = 0, HoverB = 0,
			NormalR = 1, NormalG = 1, NormalB = 1,
		})
		Dialog.CreateDialogInnerBackdrop(Window, {
			Field = "Inner",
			TopPoint = "TOPLEFT", TopRelativeTo = Window.Header, TopRelativePoint = "BOTTOMLEFT", TopX = 0, TopY = -3,
			BottomPoint = "BOTTOMRIGHT", BottomRelativeTo = Window, BottomRelativePoint = "BOTTOMRIGHT", BottomX = -3, BottomY = 3,
			Color = "ui-window-main-color",
		})
		Dialog.CreateDialogInnerBackdrop(Window, {
			Parent = Window.Inner, Field = "InputBG", Height = 24, TextureLayer = "BACKGROUND",
			TopPoint = "TOPLEFT", TopRelativeTo = Window.Inner, TopRelativePoint = "TOPLEFT", TopX = 4, TopY = -6,
			BottomPoint = "TOPRIGHT", BottomRelativeTo = Window.Inner, BottomRelativePoint = "TOPRIGHT", BottomX = -4, BottomY = -6,
			R = 0, G = 0, B = 0, A = 0,
		})
		Dialog.CreateDialogEditBox(Window, {
			Parent = Window.InputBG, MaxLetters = 9999,
			Scripts = {
				OnEscapePressed = function() Window:Hide() end,
				OnEnterPressed = function() Window:Hide() end,
			},
		})
		Window.Hint = Window.Inner:CreateFontString(nil, "OVERLAY")
		Window.Hint:SetPoint("TOPLEFT", Window.InputBG, "BOTTOMLEFT", 3, -7)
		YxUI:SetFontInfo(Window.Hint, Settings["ui-widget-font"], Settings["ui-font-size"])
		Window.Hint:SetText(Language["Press ctrl + c to copy"])
		Window:HookScript("OnHide", function(self)
			self.Input:ClearFocus()
		end)
		CopyDialog = Window
	end

	CopyDialog:Show()
	CopyDialog.Input:SetText(text)
	CopyDialog.Input:SetFocus()
	CopyDialog.Input:HighlightText()
end

ItemRefTooltip.SetHyperlink = function(self, link, text, button, chatFrame)
	if sub(link, 1, 4) == "url:" then
		ShowCopyDialog(sub(link, 5))
	elseif sub(link, 1, 6) == "email:" then
		ShowCopyDialog(sub(link, 7))
	elseif sub(link, 1, 8) == "discord:" then
		ShowCopyDialog(sub(link, 9))
	elseif sub(link, 1, 7) == "friend:" then
		ShowCopyDialog(sub(link, 8))
	elseif sub(link, 1, 7) == "command" then
		local EditBox = ChatEdit_ChooseBoxForSend()
		local Command = sub(link, 9)

		EditBox:SetText("")

		if not EditBox:IsShown() then
			ChatEdit_ActivateChat(EditBox)
		else
			ChatEdit_UpdateHeader(EditBox)
		end

		EditBox:Insert(Command)
		ChatEdit_ParseText(EditBox, 1)
	else
		PreviousSetHyperlink(self, link, text, button, chatFrame)
	end
end


Chat.FormatLinks = FormatLinks
YxUI.FormatLinks = FormatLinks
function Chat:InstallLinkHooks()
	local events = {
		"SYSTEM",
		"CHANNEL",
		"SAY",
		"YELL",
		"GUILD",
		"OFFICER",
		"PARTY",
		"PARTY_LEADER",
		"RAID",
		"RAID_LEADER",
		"BATTLEGROUND",
		"BATTLEGROUND_LEADER",
		"WHISPER",
		"WHISPER_INFORM",
		"BN_WHISPER",
		"BN_WHISPER_INFORM",
		"BN_CONVERSATION",
	}

	for i = 1, #events do
		ChatFrame_AddMessageEventFilter("CHAT_MSG_" .. events[i], FindLinks)
	end
end
