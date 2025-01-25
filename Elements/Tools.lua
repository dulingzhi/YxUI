local HydraUI, Language, Assets, Settings, Defaults = select(2, ...):get()

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
function HydraUI:HexToRGB(hex)
	if (not hex) then
		return
	end

	return tonumber("0x" .. sub(hex, 1, 2)) / 255, tonumber("0x" .. sub(hex, 3, 4)) / 255, tonumber("0x" .. sub(hex, 5, 6)) / 255
end

function HydraUI:RGBToHex(r, g, b)
	return format("%02x%02x%02x", r * 255, g * 255, b * 255)
end

function HydraUI:FormatTime(seconds)
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

function HydraUI:FormatFullTime(seconds)
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

function HydraUI:AuraFormatTime(seconds)
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

function HydraUI:ShortValue(num)
	if (num > 999999) then
		return format("%.2fm", num / 1000000)
	elseif (num > 999) then
		return format("%.1fk", num / 1000)
	end

	return num
end

function HydraUI:Comma(number)
	if (not number) then
		return
	end

   	local Left, Number = match(floor(number + 0.5), "^([^%d]*%d)(%d+)(.-)$")

	return Left and Left .. reverse(gsub(reverse(Number), "(%d%d%d)", "%1,")) or number
end

function HydraUI:CopperToGold(copper)
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

function HydraUI:GetCurrentDate()
	return date("%Y-%m-%d %I:%M %p")
end

-- If the date given is today, change "2019-07-24 2:06 PM" to "Today 2:06 PM"
function HydraUI:IsToday(s)
	local Date, Time = match(s, "(%d+%-%d+%-%d+)%s(.+)")

	if (not Date or not Time) then
		return s
	end

	if (Date == date("%Y-%m-%d")) then
		s = format("%s %s", Language["Today"], Time)
	end

	return s
end

function HydraUI:BindSavedVariable(global, key)
	if (not _G[global]) then
		_G[global] = {}
	end

	if (not self[key]) then
		self[key] = _G[global]
	end
end

local ResetOnAccept = function()
	HydraUIProfileData = nil
	HydraUIProfiles = nil
	HydraUIData = nil
	HydraUIGold = nil

	ReloadUI()
end

function HydraUI:Reset()
	HydraUI:DisplayPopup(Language["Attention"], Language["This action will delete ALL saved UI information. Are you sure you wish to continue?"], ACCEPT, ResetOnAccept, CANCEL)
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

		if HydraUI.FormatLinks then
			String = HydraUI.FormatLinks(String)
		end

		DEFAULT_CHAT_FRAME:AddMessage(String)
	else
		if HydraUI.FormatLinks then
			String = HydraUI.FormatLinks(tostring(...))

			DEFAULT_CHAT_FRAME:AddMessage(String)
		else
			DEFAULT_CHAT_FRAME:AddMessage(...)
		end
	end
end

setprinthandler(NewPrint)

function HydraUI:print(...)
	if Settings["ui-widget-color"] then
		print("|cFF" .. Settings["ui-widget-color"] .. "Hydra|rUI:", ...)
	else
		print("|cFF" .. Defaults["ui-widget-color"] .. "Hydra|rUI:", ...)
	end
end

function HydraUI:SetFontInfo(object, font, size, flags)
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
HydraUI.Backdrop = {
	bgFile = "Interface\\AddOns\\HydraUI\\Elements\\Assets\\Textures\\HydraUIBlank.tga",
	insets = {top = 0, left = 0, bottom = 0, right = 0},
}

HydraUI.BackdropAndBorder = {
	bgFile = "Interface\\AddOns\\HydraUI\\Elements\\Assets\\Textures\\HydraUIBlank.tga",
	edgeFile = "Interface\\AddOns\\HydraUI\\Elements\\Assets\\Textures\\HydraUIBlank.tga",
	edgeSize = 1,
	insets = {top = 0, left = 0, bottom = 0, right = 0},
}

HydraUI.Outline = {
	edgeFile = "Interface\\AddOns\\HydraUI\\Elements\\Assets\\Textures\\HydraUIBlank.tga",
	edgeSize = 1,
	insets = {left = 0, right = 0, top = 0, bottom = 0},
}

local Outside = {
	edgeFile = "Interface\\AddOns\\HydraUI\\Elements\\Assets\\Textures\\HydraUIBlank.tga",
}

local Inside = {
	bgFile = "Interface\\AddOns\\HydraUI\\Elements\\Assets\\Textures\\HydraUIBlank.tga",
	edgeFile = "Interface\\AddOns\\HydraUI\\Elements\\Assets\\Textures\\HydraUIBlank.tga",
}

function HydraUI:AddBackdrop(frame, texture)
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
	frame.Inside:SetBackdropBorderColor(HydraUI:HexToRGB(Settings["ui-window-bg-color"]))
	frame.Inside:SetBackdropColor(0, 0, 0, 0)
end

-- NYI, Concept list for my preferred CVars, and those important to the UI
function HydraUI:SetCVars()
	C_CVar.SetCVar("countdownForCooldowns", 1)

	-- Name plates
	C_CVar.SetCVar("NameplatePersonalShowAlways", 0)
	C_CVar.SetCVar("NameplatePersonalShowInCombat", 0)
	C_CVar.SetCVar("NameplatePersonalShowWithTarget", 0)
end