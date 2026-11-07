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
	if not hex then
		return
	end

	return tonumber("0x" .. sub(hex, 1, 2)) / 255, tonumber("0x" .. sub(hex, 3, 4)) / 255, tonumber("0x" .. sub(hex, 5, 6)) / 255
end

function YxUI:RGBToHex(r, g, b)
	return format("%02x%02x%02x", r * 255, g * 255, b * 255)
end

function YxUI:FormatTime(seconds)
	if seconds > 86399 then
		return format("%dd", ceil(seconds / 86400))
	elseif seconds > 3599 then
		return format("%dh", ceil(seconds / 3600))
	elseif seconds > 59 then
		return format("%dm", ceil(seconds / 60))
	elseif seconds > 5 then
		return format("%ds", floor(seconds))
	end

	return format("%.1fs", seconds)
end

function YxUI:FormatFullTime(seconds)
	local Days = floor(seconds / 86400)
	local Hours = floor((seconds % 86400) / 3600)
	local Mins = floor((seconds % 3600) / 60)

	if Days > 0 then
		return format("%dd", Days)
	elseif Hours > 0 then
		return format("%dh %sm", Hours, Mins)
	elseif Mins > 0 then
		return format("%sm", Mins)
	else
		return format("%ss", floor(seconds))
	end
end

function YxUI:AuraFormatTime(seconds)
	if seconds > 86399 then
		return format("%dd", ceil(seconds / 86400))
	elseif seconds > 3599 then
		return format("%dh", ceil(seconds / 3600))
	elseif seconds > 59 then
		return format("%dm", ceil(seconds / 60))
	elseif seconds > 5 then
		return format("%d", floor(seconds))
	end

	return format("%.1f", seconds)
end

-- Duration text does not need a per-frame updater.  Keep one deadline timer for
-- every duration label and only revisit labels whose displayed value can have
-- changed.  The small offset puts floor/rounding boundaries just behind us;
-- at the boundary itself (for example, exactly 10 seconds) the old label is
-- still correct.
local DurationText = {
	Buttons = setmetatable({}, {__mode = "k"}),
}
local DurationTextTimer
local DurationTextDeadline
local DurationTextUpdatingDue
local DurationBoundaryOffset = 0.001

local function GetNextDurationChange(remaining)
	local Boundary

	if remaining > 86399 then
		Boundary = math.max(86399, (ceil(remaining / 86400) - 1) * 86400)
	elseif remaining > 3599 then
		Boundary = math.max(3599, (ceil(remaining / 3600) - 1) * 3600)
	elseif remaining > 59 then
		Boundary = math.max(59, (ceil(remaining / 60) - 1) * 60)
	elseif remaining > 5 then
		Boundary = floor(remaining)
	else
		-- This mirrors the rounding used by both %.1f duration formatters.
		Boundary = tonumber(format("%.1f", remaining)) - 0.05
	end

	return math.min(remaining, math.max(0, remaining - Boundary)) + DurationBoundaryOffset
end

local function ScheduleDurationDeadline(Deadline)
	if Deadline == DurationTextDeadline then
		return
	end

	if DurationTextTimer then
		DurationTextTimer:Cancel()
		DurationTextTimer = nil
	end

	DurationTextDeadline = Deadline

	if Deadline then
		DurationTextTimer = C_Timer.NewTimer(math.max(0, Deadline - GetTime()), function()
			DurationTextTimer = nil
			DurationTextDeadline = nil
			DurationText:UpdateDue()
		end)
	end
end

function DurationText:ScheduleNext()
	local Deadline

	for _, Record in pairs(self.Buttons) do
		if Record.Deadline and (not Deadline or Record.Deadline < Deadline) then
			Deadline = Record.Deadline
		end
	end

	ScheduleDurationDeadline(Deadline)
end

local function ScheduleRecord(record)
	if record.Deadline and (not DurationTextDeadline or record.Deadline < DurationTextDeadline) then
		ScheduleDurationDeadline(record.Deadline)
	end
end

function DurationText:Unregister(button)
	local Record = self.Buttons[button]

	if not Record then
		return
	end

	local WasScheduled = Record.Deadline == DurationTextDeadline

	self.Buttons[button] = nil

	if Record.OnUnregister then
		Record.OnUnregister(button)
	end

	if not DurationTextUpdatingDue and WasScheduled then
		self:ScheduleNext()
	end
end

function DurationText:UpdateButton(button, record, now)
	local Remaining = record.GetRemaining(button, now)

	if not Remaining or Remaining <= 0 then
		self:Unregister(button)
		return false
	end

	local Text = record.Format(Remaining)

	if Text ~= record.LastText then
		record.LastText = Text
		record.Text:SetText(Text)
	end

	record.Deadline = now + GetNextDurationChange(Remaining)

	return true
end

function DurationText:Register(button, text, formatter, getRemaining, onUnregister)
	local Record = self.Buttons[button]

	if not Record then
		Record = {}
		self.Buttons[button] = Record
	end

	Record.Text = text
	Record.Format = formatter
	Record.GetRemaining = getRemaining
	Record.OnUnregister = onUnregister

	if self:UpdateButton(button, Record, GetTime()) and not DurationTextUpdatingDue then
		ScheduleRecord(Record)
	end
end

function DurationText:UpdateDue()
	local Now = GetTime()

	DurationTextUpdatingDue = true

	for Button, Record in pairs(self.Buttons) do
		if Record.Deadline <= Now then
			if Button:IsShown() then
				self:UpdateButton(Button, Record, Now)
			else
				self:Unregister(Button)
			end
		end
	end

	DurationTextUpdatingDue = nil
	self:ScheduleNext()
end

YxUI.DurationText = DurationText

if YxUI.IsMainline then
	local ShortValueOptions = {
		breakpointData = {
			{breakpoint = 1000000, abbreviation = "m", significandDivisor = 10000, fractionDivisor = 100, abbreviationIsGlobal = false},
			{breakpoint = 1000, abbreviation = "k", significandDivisor = 100, fractionDivisor = 10, abbreviationIsGlobal = false},
		},
	}

	function YxUI:ShortValue(num)
		return AbbreviateNumbers(num, ShortValueOptions)
	end

	function YxUI:Comma(number)
		if not number then
			return
		end

		if issecretvalue(number) and not canaccessvalue(number) then
			return BreakUpLargeNumbers(number)
		end

		local Left, Number = match(floor(number + 0.5), "^([^%d]*%d)(%d+)(.-)$")

		return Left and Left .. reverse(gsub(reverse(Number), "(%d%d%d)", "%1,")) or number
	end
else
	local function ShortDecimal(value, pattern)
		return (format(pattern, value):gsub("(%..-)0+$", "%1"):gsub("%.$", ""))
	end

	function YxUI:ShortValue(num)
		if num > 999999 then
			return ShortDecimal(num / 1000000, "%.2f") .. "m"
		elseif num > 999 then
			return ShortDecimal(num / 1000, "%.1f") .. "k"
		end

		return num
	end

	function YxUI:Comma(number)
		if not number then
			return
		end

		local Left, Number = match(floor(number + 0.5), "^([^%d]*%d)(%d+)(.-)$")

		return Left and Left .. reverse(gsub(reverse(Number), "(%d%d%d)", "%1,")) or number
	end
end

function YxUI:CopperToGold(copper)
	local Gold = floor(copper / (100 * 100))
	local Silver = floor((copper - (Gold * 100 * 100)) / 100)
	local Copper = floor(copper % 100)
	local Separator = ""
	local String = ""

	if Gold > 0 then
		String = self:Comma(Gold) .. "|cffffe02eg|r"
		Separator = " "
	end

	if Silver > 0 then
		if Silver < 10 then
			Silver = "0" .. Silver
		end

		String = String .. Separator .. Silver .. "|cffd6d6d6s|r"
		Separator = " "
	end

	if Copper > 0 or String == "" then
		if Copper < 10 then
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

	if not Date or not Time then
		return s
	end

	if Date == date("%Y-%m-%d") then
		s = format("%s %s", Language["Today"], Time)
	end

	return s
end

function YxUI:BindSavedVariable(global, key)
	if not _G[global] then
		_G[global] = {}
	end

	if not self[key] then
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

	if NumArgs == 0 then
		return
	elseif NumArgs > 1 then
		for i = 1, NumArgs do
			if i == 1 then
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

setprinthandler(NewPrint)

function YxUI:print(...)
	if Settings["ui-widget-color"] then
		print("|cFF" .. Settings["ui-widget-color"] .. "Hydra|rUI:", ...)
	else
		print("|cFF" .. Defaults["ui-widget-color"] .. "Hydra|rUI:", ...)
	end
end

local FontObjectCache = {}
local FontObjectCount = 0
local AdaptiveFonts = setmetatable({}, {__mode = "k"})

local LocaleFonts = {
	koKR = "Fonts\\2002.TTF",
	zhCN = "Fonts\\ARKai_T.ttf",
	zhTW = "Fonts\\blei00d.TTF",
	ruRU = "Fonts\\FRIZQT___CYR.TTF",
}

local LocaleFontCoverage = {
	["Roboto"] = {ruRU = true},
	["Noto Sans"] = {ruRU = true},
	["Expressway"] = {ruRU = true},
	["PT Sans"] = {ruRU = true},
}

function YxUI:GetDisplayFontPath(font, preserveSelection)
	local Path, IsPixel = Assets:GetFont(font)
	local Locale = self.UserLocale
	if not preserveSelection and LocaleFonts[Locale] and not (LocaleFontCoverage[font] and LocaleFontCoverage[font][Locale]) then
		return LocaleFonts[Locale], false
	end
	return Path, IsPixel
end

local GetFontObject = function(font, size, flags, preserveSelection)
	local Font, IsPixel = YxUI:GetDisplayFontPath(font, preserveSelection)
	local FontFlags = IsPixel and "MONOCHROME, OUTLINE" or (flags or "")
	local CacheKey = format("%s\031%s\031%s", Font, tostring(size), FontFlags)
	local FontObject = FontObjectCache[CacheKey]

	if not FontObject then
		FontObjectCount = FontObjectCount + 1
		FontObject = CreateFont("YxUIFontObject" .. FontObjectCount)
		if not FontObject:SetFont(Font, size, FontFlags) then
			local Fallback, IsFallbackPixel = Assets:GetFont(font)
			IsPixel = IsFallbackPixel
			FontFlags = IsPixel and "MONOCHROME, OUTLINE" or (flags or "")
			FontObject:SetFont(Fallback, size, FontFlags)
		end

		if IsPixel then
			FontObject:SetShadowColor(0, 0, 0, 0)
		else
			FontObject:SetShadowColor(0, 0, 0, 1)
			FontObject:SetShadowOffset(1, -1)
		end

		FontObjectCache[CacheKey] = FontObject
	end

	return FontObject
end

function YxUI:SetFontInfo(object, font, size, flags, preserveSelection)
	if not object then
		return
	end

	object:SetFontObject(GetFontObject(font, size, flags, preserveSelection))
	if AdaptiveFonts[object] then
		AdaptiveFonts[object].Dirty = true
		object.__hydraAdaptiveDirty = true
	end
end

local ScriptFonts = {
	koKR = LocaleFonts.koKR,
	zhCN = LocaleFonts.zhCN,
	zhTW = LocaleFonts.zhTW,
	ruRU = LocaleFonts.ruRU,
	greek = Assets:GetFont("Noto Sans"),
	vietnamese = Assets:GetFont("Noto Sans"),
}

local SupportedScripts = {
	["Roboto"] = {ruRU = true, greek = true, vietnamese = true},
	["Noto Sans"] = {ruRU = true, greek = true, vietnamese = true},
	["Expressway"] = {ruRU = true},
	["PT Sans"] = {ruRU = true},
}

local function ChineseScript(self, locale)
	if locale == "zhCN" or locale == "zhTW" then
		return locale
	end
	if self.UserLocale == "zhCN" or self.UserLocale == "zhTW" then
		return self.UserLocale
	end
	if self.ClientLocale == "zhCN" or self.ClientLocale == "zhTW" then
		return self.ClientLocale
	end
	return "zhCN"
end

local function GetTextScript(self, text, locale)
	if not text:find("[\128-\255]") then
		return
	end

	local i, Length = 1, #text
	while i <= Length do
		local A = text:byte(i)
		if A >= 0xC2 and A <= 0xDF and i < Length then
			local B = text:byte(i + 1)
			if B >= 0x80 and B <= 0xBF then
				local Code = (A - 0xC0) * 64 + B - 0x80
				if Code >= 0x0400 and Code <= 0x052F then
					return "ruRU"
				elseif Code >= 0x0370 and Code <= 0x03FF then
					return "greek"
				end
			end
			i = i + 2
		elseif A >= 0xE0 and A <= 0xEF and i + 2 <= Length then
			local B, C = text:byte(i + 1, i + 2)
			if B >= 0x80 and B <= 0xBF and C >= 0x80 and C <= 0xBF then
				local Code = (A - 0xE0) * 4096 + (B - 0x80) * 64 + C - 0x80
				if (Code >= 0x1100 and Code <= 0x11FF) or (Code >= 0x3130 and Code <= 0x318F) or (Code >= 0xAC00 and Code <= 0xD7AF) then
					return "koKR"
				elseif (Code >= 0x3400 and Code <= 0x9FFF) or (Code >= 0xF900 and Code <= 0xFAFF) then
					return ChineseScript(self, locale)
				elseif Code >= 0x1EA0 and Code <= 0x1EF9 then
					return "vietnamese"
				end
			end
			i = i + 3
		else
			i = i + 1
		end
	end
end

local function IsRestrictedText(text)
	return YxUI.IsMainline and issecretvalue and issecretvalue(text) and (not canaccessvalue or not canaccessvalue(text))
end

function YxUI:AdaptFontForText(object, text, font, size, flags, locale)
	if not object or IsRestrictedText(text) or type(text) ~= "string" then
		return
	end

	local State = AdaptiveFonts[object]
	local SameStyle = State and State.Font == font and State.Size == size and State.Flags == flags and State.Locale == locale
	if SameStyle and State.Text == text and not State.Dirty then
		return State.Applied
	end

	local Script = GetTextScript(self, text, locale)
	local Coverage = SupportedScripts[font]
	local Path = Script and not (Coverage and Coverage[Script]) and ScriptFonts[Script]
	local Applied

	if Path then
		if SameStyle and State.Path == Path and not State.Dirty then
			Applied = State.Applied
		else
			local Ok, Result = pcall(object.SetFont, object, Path, size, flags or "")
			Applied = Ok and Result == true
			if not Applied then
				self:SetFontInfo(object, font, size, flags)
			end
		end
	else
		self:SetFontInfo(object, font, size, flags, true)
	end

	if not State then
		State = {}
		AdaptiveFonts[object] = State
	end
	State.Text, State.Font, State.Size, State.Flags = text, font, size, flags
	State.Locale, State.Path, State.Applied, State.Dirty = locale, Path, Applied, nil
	object.__hydraAdaptiveDirty = nil
	return Path and Applied
end

function YxUI:SetFontForText(object, text, font, size, flags, locale)
	if not object then
		return
	end

	self:SetFontInfo(object, font, size, flags)
	return self:AdaptFontForText(object, text, font, size, flags, locale)
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
	if frame.Outside or frame.Inside then
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

	if Border == 0 then
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
