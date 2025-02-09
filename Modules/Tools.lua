local YxUI, Language, Assets, Settings, Defaults = select(2, ...):get()

local tonumber = tonumber
local tostring = tostring
local select = select
local date = date
local sub = string.sub
local format = string.format
local floor = math.floor
local match = string.match
local reverse = string.reverse

-- Tools
function YxUI:HexToRGB(hex)
	if (not hex) then
		return
	end

	return tonumber("0x" .. sub(hex, 1, 2)) / 255, tonumber("0x" .. sub(hex, 3, 4)) / 255, tonumber("0x" .. sub(hex, 5, 6)) / 255
end

function YxUI:RGBToHex(r, g, b)
	return format("%02x%02x%02x", r * 255, g * 255, b * 255)
end

----------------------------------------------------------------------------------------
--	Chat channel check
----------------------------------------------------------------------------------------
function YxUI:CheckChat(warning)
	if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
		return "INSTANCE_CHAT"
	elseif IsInRaid(LE_PARTY_CATEGORY_HOME) then
		if warning and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") or IsEveryoneAssistant()) then
			return "RAID_WARNING"
		else
        return "EMOTE"
		end
	elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
        if UnitIsGroupLeader("player") then
		    return "PARTY"
        end
        return "EMOTE"
	end
    return "EMOTE"
end

function YxUI:FormatTime(seconds)
	if (seconds > 86399) then
		return format("%dd", ceil(seconds / 86400))
	elseif (seconds > 3599) then
		return format("%dh", ceil(seconds / 3600))
	elseif (seconds > 59) then
		return format("%dm", ceil(seconds / 60))
	elseif (seconds > 5) then
		return format("%ds", floor(seconds))
	end

	return format("%.1fs", seconds)
end

function YxUI:FormatFullTime(seconds)
	local Days = floor(seconds / 86400)
	local Hours = floor((seconds % 86400) / 3600)
	local Mins = floor((seconds % 3600) / 60)

	if (Days > 0) then
		return format("%dd", Days)
	elseif (Hours > 0) then
		return format("%dh %sm", Hours, Mins)
	elseif (Mins > 0) then
		return format("%sm", Mins)
	else
		return format("%ss", floor(seconds))
	end
end

function YxUI:AuraFormatTime(seconds)
	if (seconds > 86399) then
		return format("%dd", ceil(seconds / 86400))
	elseif (seconds > 3599) then
		return format("%dh", ceil(seconds / 3600))
	elseif (seconds > 59) then
		return format("%dm", ceil(seconds / 60))
	elseif (seconds > 5) then
		return format("%d", floor(seconds))
	end

	return format("%.1f", seconds)
end

function YxUI:ShortValue(num)
	if (num > 999999) then
		return format("%.2fm", num / 1000000)
	elseif (num > 999) then
		return format("%.1fk", num / 1000)
	end

	return num
end

function YxUI:Comma(number)
	if (not number) then
		return
	end

   	local Left, Number = match(floor(number + 0.5), "^([^%d]*%d)(%d+)(.-)$")

	return Left and Left .. reverse(gsub(reverse(Number), "(%d%d%d)", "%1,")) or number
end

function YxUI:CopperToGold(copper)
	local Gold = floor(copper / (100 * 100))
	local Silver = floor((copper - (Gold * 100 * 100)) / 100)
	local Copper = floor(copper % 100)
	local Separator = ""
	local String = ""

	if (Gold > 0) then
		String = self:Comma(Gold) .. "|cffffe02eg|r"
		Separator = " "
	end

	if (Silver > 0) then
		if (Silver < 10) then
			Silver = "0" .. Silver
		end

		String = String .. Separator .. Silver .. "|cffd6d6d6s|r"
		Separator = " "
	end

	if (Copper > 0 or String == "") then
		if (Copper < 10) then
			Copper = "0" .. Copper
		end

		String = String .. Separator .. Copper .. "|cfffc8d2bc|r"
	end

	return String
end

function YxUI:GetCurrentDate()
	return date("%Y-%m-%d %I:%M %p")
end

-- If the date given is today, change "2019-07-24 2:06 PM" to "Today 2:06 PM"
function YxUI:IsToday(s)
	local Date, Time = match(s, "(%d+%-%d+%-%d+)%s(.+)")

	if (not Date or not Time) then
		return s
	end

	if (Date == date("%Y-%m-%d")) then
		s = format("%s %s", Language["Today"], Time)
	end

	return s
end

function YxUI:BindSavedVariable(global, key)
	if (not _G[global]) then
		_G[global] = {}
	end

	if (not self[key]) then
		self[key] = _G[global]
	end
end

local ResetOnAccept = function()
	YxUIProfileData = nil
	YxUIProfiles = nil
	YxUIData = nil
	YxUIGold = nil

	ReloadUI()
end

function YxUI:Reset()
	YxUI:DisplayPopup(Language["Attention"], Language["This action will delete ALL saved UI information. Are you sure you wish to continue?"], ACCEPT, ResetOnAccept, CANCEL)
end

local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME

local NewPrint = function(...)
	local NumArgs = select("#", ...)
	local String = ""

	if (NumArgs == 0) then
		return
	elseif (NumArgs > 1) then
		for i = 1, NumArgs do
			if (i == 1) then
				String = tostring(select(i, ...))
			else
				String = format("%s %s", String, tostring(select(i, ...)))
			end
		end

		if YxUI.FormatLinks then
			String = YxUI.FormatLinks(String)
		end

		DEFAULT_CHAT_FRAME:AddMessage(String)
	else
		if YxUI.FormatLinks then
			String = YxUI.FormatLinks(tostring(...))

			DEFAULT_CHAT_FRAME:AddMessage(String)
		else
			DEFAULT_CHAT_FRAME:AddMessage(...)
		end
	end
end

if not IsAddOnLoaded('!!!tdDevTools') then
    setprinthandler(NewPrint)
end

function YxUI:print(...)
	if Settings["ui-widget-color"] then
		NewPrint("|cFF" .. Settings["ui-widget-color"] .. "Yx|rUI:", ...)
	else
		NewPrint("|cFF" .. Defaults["ui-widget-color"] .. "Yx|rUI:", ...)
	end
end

function YxUI:SetFontInfo(object, font, size, flags)
	if (not object) then
		return
	end

	local Font, IsPixel = Assets:GetFont(font)

	if IsPixel then
		object:SetFont(Font, size, "MONOCHROME, OUTLINE")
		object:SetShadowColor(0, 0, 0, 0)
	else
		object:SetFont(Font, size, flags or "")
		object:SetShadowColor(0, 0, 0)
		object:SetShadowOffset(1, -1)
	end
end

-- Backdrops
YxUI.Backdrop = {
	bgFile = "Interface\\AddOns\\YxUI\\Media\\Textures\\YxUIBlank.tga",
	insets = {top = 0, left = 0, bottom = 0, right = 0},
}

YxUI.BackdropAndBorder = {
	bgFile = "Interface\\AddOns\\YxUI\\Media\\Textures\\YxUIBlank.tga",
	edgeFile = "Interface\\AddOns\\YxUI\\Media\\Textures\\YxUIBlank.tga",
	edgeSize = 1,
	insets = {top = 0, left = 0, bottom = 0, right = 0},
}

YxUI.Outline = {
	edgeFile = "Interface\\AddOns\\YxUI\\Media\\Textures\\YxUIBlank.tga",
	edgeSize = 1,
	insets = {left = 0, right = 0, top = 0, bottom = 0},
}

local Outside = {
	edgeFile = "Interface\\AddOns\\YxUI\\Media\\Textures\\YxUIBlank.tga",
}

local Inside = {
	bgFile = "Interface\\AddOns\\YxUI\\Media\\Textures\\YxUIBlank.tga",
	edgeFile = "Interface\\AddOns\\YxUI\\Media\\Textures\\YxUIBlank.tga",
}

function YxUI:AddBackdrop(frame, texture)
	if (frame.Outside or frame.Inside) then
		return
	end

	local Border = Settings["ui-border-thickness"]

	Outside.edgeSize = 1 > Border and 1 or (Border + 2)
	Inside.edgeSize = Border

	if texture then
		Outside.bgFile = texture
	else
		Outside.bgFile = Assets:GetTexture("Blank")
	end

	frame.Outside = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	frame.Outside:SetAllPoints()
	frame.Outside:SetBackdrop(Outside)
	frame.Outside:SetBackdropBorderColor(0, 0, 0)
	frame.Outside:SetBackdropColor(0, 0, 0, 0)

	if (Border == 0) then
		return
	end

	frame.Inside = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	frame.Inside:SetPoint("TOPLEFT", 1, -1)
	frame.Inside:SetPoint("BOTTOMRIGHT", -1, 1)
	frame.Inside:SetFrameLevel(frame.Outside:GetFrameLevel() + 1)
	frame.Inside:SetBackdrop(Inside)
	frame.Inside:SetBackdropBorderColor(YxUI:HexToRGB(Settings["ui-window-bg-color"]))
	frame.Inside:SetBackdropColor(0, 0, 0, 0)
end

-- NYI, Concept list for my preferred CVars, and those important to the UI
function YxUI:SetCVars()
	C_CVar.SetCVar("countdownForCooldowns", 1)

	-- Name plates
	C_CVar.SetCVar("NameplatePersonalShowAlways", 0)
	C_CVar.SetCVar("NameplatePersonalShowInCombat", 0)
	C_CVar.SetCVar("NameplatePersonalShowWithTarget", 0)
end

function YxUI:GetRoleIcon(role)
    return format([[Interface\AddOns\YxUI\Media\Textures\Icon\%s.tga]], role)
end
