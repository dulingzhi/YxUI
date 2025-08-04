local Y, L, A, C, D = YxUIGlobal:get()

local Experience = Y:NewModule("Experience")

local format = format
local floor = floor
local XP, MaxXP, Rested
local GetTime = GetTime
local IsResting = IsResting
local RestingText
local UnitXP = UnitXP
local UnitXPMax = UnitXPMax
local UnitLevel = UnitLevel
local GetXPExhaustion = GetXPExhaustion
local GetQuestInfo = C_QuestLog.GetInfo
local ReadyForTurnIn = C_QuestLog.ReadyForTurnIn
local IsPlayerAtEffectiveMaxLevel = IsPlayerAtEffectiveMaxLevel
local GetNumQuests
local LEVEL = LEVEL
local HasXPBuff
local XPMod = 1

if Y.IsMainline then
	GetNumQuests = C_QuestLog.GetNumQuestLogEntries
elseif Y.IsCata or Y.IsMists then
	GetNumQuests = GetNumQuestLogEntries
	HasXPBuff = IsSpellKnown(78632) -- Fast Track +10%
	XPMod = 1.10
else
	GetNumQuests = GetNumQuestLogEntries
	HasXPBuff = AuraUtil.FindAuraByName(GetSpellInfo(377749), "player", "HELPFUL") -- Joyous Journeys +50%
	XPMod = 1.50
end

D["experience-enable"] = true
D["experience-width"] = 316
D["experience-height"] = 16
D["experience-mouseover"] = false
D["experience-mouseover-opacity"] = 0
D["experience-display-level"] = false
D["experience-display-progress"] = true
D["experience-display-percent"] = true
D["experience-display-rested-value"] = true
D["experience-show-tooltip"] = true
D["experience-animate"] = true
D["experience-progress-visibility"] = "ALWAYS"
D["experience-percent-visibility"] = "ALWAYS"
D["experience-bar-color"] = "4C9900" -- 1AE045
D["experience-rested-color"] = "00B4FF"
D.XPQuestColor = "CCCC19"

local FadeOnFinished = function(self)
	self.Parent:Hide()
end

local UpdateDisplayProgress = function(value)
	if (not C["experience-enable"]) then
		return
	end

	if (value and C["experience-progress-visibility"] == "ALWAYS") then
		Experience.Progress:Show()
	else
		Experience.Progress:Hide()
	end
end

local UpdateDisplayPercent = function(value)
	if (not C["experience-enable"]) then
		return
	end

	if (value and C["experience-percent-visibility"] == "ALWAYS") then
		Experience.Percentage:Show()
	else
		Experience.Percentage:Hide()
	end
end

local UpdateBarWidth = function(value)
	if (not C["experience-enable"]) then
		return
	end

	Experience:SetWidth(value)
end

local UpdateBarHeight = function(value)
	if (not C["experience-enable"]) then
		return
	end

	Experience:SetHeight(value)
	Experience.Bar.Spark:SetHeight(value)
end

local UpdateProgressVisibility = function(value)
	if (not C["experience-enable"]) then
		return
	end

	if (value == "MOUSEOVER") then
		Experience.Progress:Hide()
	elseif (value == "ALWAYS" and C["experience-display-progress"]) then
		Experience.Progress:Show()
	end
end

local UpdatePercentVisibility = function(value)
	if (not C["experience-enable"]) then
		return
	end

	if (value == "MOUSEOVER") then
		Experience.Percentage:Hide()
	elseif (value == "ALWAYS" and C["experience-display-percent"]) then
		Experience.Percentage:Show()
	end
end

function Experience:OnMouseUp()
	ToggleCharacter("PaperDollFrame")
end

function Experience:CreateBar()
	local Border = C["ui-border-thickness"]
	local Offset = 1 > Border and 1 or (Border + 2)

	self:SetSize(C["experience-width"], C["experience-height"])
    self:CreateBorder()

	if Minimap:IsShown() then
        self:SetPoint("TOP", Minimap, "BOTTOM", 0, -6)
        self:SetWidth(C["minimap-size"])
	else
		self:SetPoint("TOP", Y.UIParent, 0, -13)
	end

	self:SetFrameStrata("MEDIUM")
	self.Elapsed = 0

	if C["experience-mouseover"] then
		self:SetAlpha(C["experience-mouseover-opacity"] / 100)
	end

	self.LastXP = UnitXP("player")
	self.LastMax = UnitXPMax("player")
	self.Seconds = 0
	self.Gained = 0

	self.BarBG = CreateFrame("Frame", nil, self, "BackdropTemplate")
	self.BarBG:SetPoint("TOPLEFT", self, 0, 0)
	self.BarBG:SetPoint("BOTTOMRIGHT", self, 0, 0)
	Y:AddBackdrop(self.BarBG)
	self.BarBG.Outside:SetBackdropColor(Y:HexToRGB(C["ui-window-main-color"]))

	self.Bar = CreateFrame("StatusBar", nil, self.BarBG)
	self.Bar:SetStatusBarTexture(A:GetTexture(C["ui-widget-texture"]))
	self.Bar:SetStatusBarColor(Y:HexToRGB(C["experience-bar-color"]))
	self.Bar:SetPoint("TOPLEFT", self.BarBG, Offset, -Offset)
	self.Bar:SetPoint("BOTTOMRIGHT", self.BarBG, -Offset, Offset)
	self.Bar:SetFrameLevel(6)

	self.Bar.BG = self.Bar:CreateTexture(nil, "BORDER")
	self.Bar.BG:SetAllPoints(self.Bar)
	self.Bar.BG:SetTexture(A:GetTexture(C["ui-widget-texture"]))
	self.Bar.BG:SetVertexColor(Y:HexToRGB(C["ui-window-main-color"]))
	self.Bar.BG:SetAlpha(0.2)

	self.Bar.Spark = self.Bar:CreateTexture(nil, "OVERLAY")
	self.Bar.Spark:SetDrawLayer("OVERLAY", 7)
	self.Bar.Spark:SetWidth(1)
	self.Bar.Spark:SetPoint("TOPLEFT", self.Bar:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
	self.Bar.Spark:SetPoint("BOTTOMLEFT", self.Bar:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
	self.Bar.Spark:SetTexture(A:GetTexture("Blank"))
	self.Bar.Spark:SetVertexColor(0, 0, 0)

	self.Shine = self.Bar:CreateTexture(nil, "ARTWORK")
	self.Shine:SetAllPoints(self.Bar:GetStatusBarTexture())
	self.Shine:SetTexture(A:GetTexture("pHishTex12"))
	self.Shine:SetVertexColor(1, 1, 1)
	self.Shine:SetAlpha(0)
	self.Shine:SetDrawLayer("ARTWORK", 7)

	self.Change = LibMotion:CreateAnimation(self.Bar, "Progress")
	self.Change:SetEasing("in")
	self.Change:SetDuration(0.3)

	self.Flash = LibMotion:CreateAnimationGroup()

	self.Flash.In = LibMotion:CreateAnimation(self.Shine, "Fade")
	self.Flash.In:SetGroup(self.Flash)
	self.Flash.In:SetEasing("in")
	self.Flash.In:SetDuration(0.3)
	self.Flash.In:SetChange(0.3)

	self.Flash.Out = LibMotion:CreateAnimation(self.Shine, "Fade")
	self.Flash.Out:SetGroup(self.Flash)
	self.Flash.Out:SetOrder(2)
	self.Flash.Out:SetEasing("out")
	self.Flash.Out:SetDuration(0.5)
	self.Flash.Out:SetChange(0)

	self.Bar.Rested = CreateFrame("StatusBar", nil, self.Bar)
	self.Bar.Rested:SetStatusBarTexture(A:GetTexture(C["ui-widget-texture"]))
	self.Bar.Rested:SetStatusBarColor(Y:HexToRGB(C["experience-rested-color"]))
	self.Bar.Rested:SetFrameLevel(5)
	self.Bar.Rested:SetAllPoints(self.Bar)

	self.Bar.Rested.Spark = self.Bar.Rested:CreateTexture(nil, "OVERLAY")
	self.Bar.Rested.Spark:SetWidth(1)
	self.Bar.Rested.Spark:SetPoint("TOPLEFT", self.Bar:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
	self.Bar.Rested.Spark:SetPoint("BOTTOMLEFT", self.Bar:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
	self.Bar.Rested.Spark:SetTexture(A:GetTexture("Blank"))
	self.Bar.Rested.Spark:SetVertexColor(0, 0, 0)

	self.Bar.Quest = CreateFrame("StatusBar", nil, self.Bar)
	self.Bar.Quest:SetStatusBarTexture(A:GetTexture(C["ui-widget-texture"]))
	self.Bar.Quest:SetStatusBarColor(Y:HexToRGB(C.XPQuestColor))
	self.Bar.Quest:SetFrameLevel(6)
	self.Bar.Quest:SetAllPoints(self.Bar)

	self.Bar.Quest.Spark = self.Bar.Quest:CreateTexture(nil, "OVERLAY")
	self.Bar.Quest.Spark:SetWidth(1)
	self.Bar.Quest.Spark:SetPoint("TOPLEFT", self.Bar:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
	self.Bar.Quest.Spark:SetPoint("BOTTOMLEFT", self.Bar:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
	self.Bar.Quest.Spark:SetTexture(A:GetTexture("Blank"))
	self.Bar.Quest.Spark:SetVertexColor(0, 0, 0)

	self.Progress = self.Bar:CreateFontString(nil, "OVERLAY")
	self.Progress:SetPoint("LEFT", self.Bar, 5, 0)
	Y:SetFontInfo(self.Progress, C["ui-widget-font"], C["ui-font-size"])
	self.Progress:SetJustifyH("LEFT")

	self.Percentage = self.Bar:CreateFontString(nil, "OVERLAY")
	self.Percentage:SetPoint("RIGHT", self.Bar, -5, 0)
	Y:SetFontInfo(self.Percentage, C["ui-widget-font"], C["ui-font-size"])
	self.Percentage:SetJustifyH("RIGHT")

	Y:CreateMover(self, 6)
end

function Experience:Update()
	Rested = GetXPExhaustion()
    XP = UnitXP("player")
    MaxXP = UnitXPMax("player")
    RestingText = IsResting() and ("|cFF" .. C["experience-rested-color"] .. "zZz|r") or ""

	local QuestLogXP = 0
	local ZoneName
	local Level = C["experience-display-level"] and (format("%s %d - ", LEVEL, UnitLevel("player"))) or ""
	local MapID = C_Map.GetBestMapForUnit("player")
	local CurrentZone

	-- Expansion transition script, remove after launch
	if (not self:IsShown() and not IsPlayerAtEffectiveMaxLevel()) then
		self:Show()
	end

	if MapID then
		CurrentZone = C_Map.GetMapInfo(MapID).name or GetRealZoneText()
	else
		CurrentZone = GetRealZoneText()
	end

	if Y.IsMainline then
		for i = 1, GetNumQuests() do
			local Info = GetQuestInfo(i)

			if (Info.isHeader and not Info.isHidden) then
				ZoneName = Info.title
			else
				if (ZoneName and ZoneName == CurrentZone and ReadyForTurnIn(Info.questID)) then
					QuestLogXP = QuestLogXP + GetQuestLogRewardXP(Info.questID)
				end
			end
		end
	else
		for i = 1, GetNumQuestLogEntries() do
			local TitleText, _, _, IsHeader, _, IsComplete, _, QuestID = GetQuestLogTitle(i)

			if IsHeader then
				ZoneName = TitleText
			else
				if (ZoneName and ZoneName == CurrentZone and IsComplete) then
					QuestLogXP = QuestLogXP + GetQuestLogRewardXP(QuestID)
				end
			end
		end
	end

	if (QuestLogXP > 0) then
		if HasXPBuff then
			QuestLogXP = QuestLogXP * XPMod
		end

		self.Bar.QuestXP = QuestLogXP
		self.Bar.Quest:SetValue(min(XP + QuestLogXP, MaxXP))
		self.Bar.Quest:Show()
	else
		self.Bar.Quest:Hide()
		self.Bar.QuestXP = 0
	end

	self.Bar:SetMinMaxValues(0, MaxXP)
	self.Bar.Rested:SetMinMaxValues(0, MaxXP)
	self.Bar.Quest:SetMinMaxValues(0, MaxXP)

	if Rested then
		self.Bar.Rested:SetValue(XP + Rested)

		if C["experience-display-rested-value"] then
			self.Progress:SetFormattedText("%s%s / %s (+%s) %s", Level, Y:Comma(XP), Y:Comma(MaxXP), Y:Comma(Rested), RestingText)
		else
			self.Progress:SetFormattedText("%s%s / %s %s", Level, Y:Comma(XP), Y:Comma(MaxXP), RestingText)
		end
	else
		self.Bar.Rested:SetValue(0)
		self.Progress:SetFormattedText("%s%s / %s %s", Level, Y:Comma(XP), Y:Comma(MaxXP), RestingText)
	end

	self.Percentage:SetText(floor((XP / MaxXP * 100 + 0.05) * 10) / 10 .. "%")

	if (XP > 0) then
		if (self.Bar.Spark:GetAlpha() == 0) then
			self.Bar.Spark:SetAlpha(1)
		end
	elseif (self.Bar.Spark:GetAlpha() > 0) then
		self.Bar.Spark:SetAlpha(0)
	end

	if (Rested and (Rested > 0)) then
		if (self.Bar.Rested.Spark:GetAlpha() == 0) then
			self.Bar.Rested.Spark:SetAlpha(1)
		end
	elseif (self.Bar.Rested.Spark:GetAlpha() > 0) then
		self.Bar.Rested.Spark:SetAlpha(0)
	end

	if C["experience-animate"] then
		if (not first) then
			self.Change:SetChange(XP)
			self.Change:Play()

			if ((XP > self.LastXP) and not self.Flash:IsPlaying()) then
				self.Flash:Play()
			end
		else
			self.Bar:SetValue(XP)
		end
	else
		self.Bar:SetValue(XP)
	end

	if self.TooltipShown then
		GameTooltip:ClearLines()
		self:OnEnter()
	end

	if (MaxXP ~= self.LastMax) then
		self.Gained = self.LastMax - self.LastXP + XP + self.Gained
	else
		self.Gained = (XP - self.LastXP) + self.Gained
	end

	if (not self.StartTime) then
		self.StartTime = GetTime()
	end

	self.LastXP = XP
	self.LastMax = MaxXP
end

function Experience:PLAYER_LEVEL_UP()
	if IsPlayerAtEffectiveMaxLevel() then
		-- self:Hide()
		--self:UnregisterAllEvents()
		--self:SetScript("OnEnter", nil)
		--self:SetScript("OnLeave", nil)
		--self:SetScript("OnEvent", nil)
	end
end

function Experience:QUEST_LOG_UPDATE()
	self:Update()
end

function Experience:PLAYER_XP_UPDATE()
	self:Update()
end

function Experience:PLAYER_UPDATE_RESTING()
	self:Update()
end

function Experience:UPDATE_EXHAUSTION()
	self:Update()
end

function Experience:ZONE_CHANGED()
	self:Update()
end

function Experience:ZONE_CHANGED_NEW_AREA()
	self:Update()
end

function Experience:OnEvent(event)
	if self[event] then
		self[event](self)
	end
end

function Experience:OnUpdate(elapsed)
	self.Elapsed = self.Elapsed + elapsed

	if (self.Elapsed > 1) then
		GameTooltip:ClearLines()
		self:OnEnter()

		self.Elapsed = 0
	end
end

function Experience:OnEnter()
	if C["experience-mouseover"] then
		self:SetAlpha(1)
	end

	if (C["experience-display-progress"] and C["experience-progress-visibility"] == "MOUSEOVER") then
		if (not self.Progress:IsShown()) then
			self.Progress:Show()
		end
	end

	if (C["experience-display-percent"] and C["experience-percent-visibility"] == "MOUSEOVER") then
		if (not self.Percentage:IsShown()) then
			self.Percentage:Show()
		end
	end

	if (not C["experience-show-tooltip"]) then
		return
	end

	GameTooltip:SetOwner(self, "ANCHOR_BOTTOM", 0, -8)

	Rested = GetXPExhaustion()
	XP = UnitXP("player")
	Max = UnitXPMax("player")

	local Percent = floor((XP / Max * 100 + 0.05) * 10) / 10
	local Remaining = Max - XP
	local RemainingPercent = floor((Remaining / Max * 100 + 0.05) * 10) / 10

	GameTooltip:AddLine(LEVEL .. " " .. UnitLevel("player"))
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(L["Current Experience"])
	GameTooltip:AddDoubleLine(format("%s / %s", Y:Comma(XP), Y:Comma(Max)), format("%s%%", Percent), 1, 1, 1, 1, 1, 1)

	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(L["Remaining Experience"])
	GameTooltip:AddDoubleLine(format("%s", Y:Comma(Remaining)), format("%s%%", RemainingPercent), 1, 1, 1, 1, 1, 1)

	if Rested then
		local RestedPercent = floor((Rested / Max * 100 + 0.05) * 10) / 10

		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["Rested Experience"])
		GameTooltip:AddDoubleLine(Y:Comma(Rested), format("%s%%", RestedPercent), 1, 1, 1, 1, 1, 1)
	end

	if (self.Bar.QuestXP and self.Bar.QuestXP > 0) then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["Quest Experience"])
		GameTooltip:AddDoubleLine(Y:Comma(self.Bar.QuestXP), format("%s%%", floor((self.Bar.QuestXP / Max * 100 + 0.05) * 10) / 10), 1, 1, 1, 1, 1, 1)
	end

	-- Advanced information
	if (self.Gained > 0) then
		local Now = GetTime()
		local Duration = (Now - self.StartTime)
		local PerSec = self.Gained / Duration

		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["Session Stats"])
		GameTooltip:AddDoubleLine(L["Experience gained"], Y:Comma(self.Gained), 1, 1, 1, 1, 1, 1)
		GameTooltip:AddDoubleLine(L["Per hour"], Y:Comma(((PerSec * 60) * 60)), 1, 1, 1, 1, 1, 1)
		GameTooltip:AddDoubleLine(L["Time to level:"], Y:FormatFullTime((Max - XP) / PerSec), 1, 1, 1, 1, 1, 1)
		GameTooltip:AddDoubleLine(L["Duration"], Y:FormatFullTime(Duration), 1, 1, 1, 1, 1, 1)
	end

	self.TooltipShown = true

	GameTooltip:Show()

	self:SetScript("OnUpdate", self.OnUpdate)
end

function Experience:OnLeave()
	if C["experience-mouseover"] then
		self:SetAlpha(C["experience-mouseover-opacity"] / 100)
	end

	if C["experience-show-tooltip"] then
		GameTooltip:Hide()

		self.TooltipShown = false
	end

	if (C["experience-display-progress"] and C["experience-progress-visibility"] == "MOUSEOVER") then
		if self.Progress:IsShown() then
			self.Progress:Hide()
		end
	end

	if (C["experience-display-percent"] and C["experience-percent-visibility"] == "MOUSEOVER") then
		if self.Percentage:IsShown() then
			self.Percentage:Hide()
		end
	end

	self:SetScript("OnUpdate", nil)
end

function Experience:Load()
	if (not C["experience-enable"] or Y.IsMaxLevel) then
		return
	end

	self:CreateBar()
	self:PLAYER_LEVEL_UP()

	--if self:IsShown() then -- Uncomment this after expansion transition
		self:RegisterEvent("QUEST_LOG_UPDATE")
		self:RegisterEvent("PLAYER_LEVEL_UP")
		self:RegisterEvent("PLAYER_XP_UPDATE")
		self:RegisterEvent("PLAYER_UPDATE_RESTING")
		self:RegisterEvent("UPDATE_EXHAUSTION")
		self:RegisterEvent("ZONE_CHANGED")
		self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
		self:SetScript("OnEvent", self.OnEvent)
		self:SetScript("OnMouseUp", self.OnMouseUp)
		self:SetScript("OnEnter", self.OnEnter)
		self:SetScript("OnLeave", self.OnLeave)

		self:Update()

		UpdateDisplayProgress(C["experience-display-progress"])
		UpdateDisplayPercent(C["experience-display-percent"])
		UpdateProgressVisibility(C["experience-progress-visibility"])
		UpdatePercentVisibility(C["experience-percent-visibility"])
	--end

	if StatusTrackingBarManager then
		StatusTrackingBarManager:Hide()
	end
end

local UpdateBarColor = function(value)
	if (not C["experience-enable"]) then
		return
	end

	Experience.Bar:SetStatusBarColor(Y:HexToRGB(value))
	Experience.Bar.BG:SetVertexColor(Y:HexToRGB(value))
end

local UpdateRestedColor = function(value)
	if (not C["experience-enable"]) then
		return
	end

	Experience.Bar.Rested:SetStatusBarColor(Y:HexToRGB(value))
end

local UpdateQuestColor = function(value)
	if (not C["experience-enable"]) then
		return
	end

	Experience.Bar.Quest:SetStatusBarColor(Y:HexToRGB(value))
end

local UpdateExperience = function()
	Experience:Update()
end

local UpdateMouseover = function(value)
	if (not C["experience-enable"]) then
		return
	end

	if value then
		Experience:SetAlpha(C["experience-mouseover-opacity"] / 100)
	else
		Experience:SetAlpha(1)
	end
end

local UpdateMouseoverOpacity = function(value)
	if (not C["experience-enable"]) then
		return
	end

	if C["experience-mouseover"] then
		Experience:SetAlpha(value / 100)
	end
end

Y:GetModule("GUI"):AddWidgets(L["General"], L["Experience"], function(left, right)
	left:CreateHeader(L["Enable"])
	left:CreateSwitch("experience-enable", C["experience-enable"], L["Enable Experience Module"], L["Enable the YxUI experience module"], ReloadUI):RequiresReload(true)

	left:CreateHeader(L["Styling"])
	left:CreateSwitch("experience-display-level", C["experience-display-level"], L["Display Level"], L["Display your current level in the experience bar"], UpdateExperience)
	left:CreateSwitch("experience-display-progress", C["experience-display-progress"], L["Display Progress Value"], L["Display your current progress information in the experience bar"], UpdateDisplayProgress)
	left:CreateSwitch("experience-display-percent", C["experience-display-percent"], L["Display Percent Value"], L["Display your current percent information in the experience bar"], UpdateDisplayPercent)
	left:CreateSwitch("experience-display-rested-value", C["experience-display-rested-value"], L["Display Rested Value"], L["Display your current rested value on the experience bar"], UpdateExperience)
	left:CreateSwitch("experience-show-tooltip", C["experience-show-tooltip"], L["Enable Tooltip"], L["Display a tooltip when mousing over the experience bar"])
	left:CreateSwitch("experience-animate", C["experience-animate"], L["Animate Experience Changes"], L["Smoothly animate changes to the experience bar"])

	right:CreateHeader(L["Size"])
	right:CreateSlider("experience-width", C["experience-width"], 180, 400, 2, L["Bar Width"], L["Set the width of the experience bar"], UpdateBarWidth)
	right:CreateSlider("experience-height", C["experience-height"], 6, 30, 1, L["Bar Height"], L["Set the height of the experience bar"], UpdateBarHeight)

	right:CreateHeader(L["Colors"])
	right:CreateColorSelection("experience-bar-color", C["experience-bar-color"], L["Experience Color"], L["Set the color of the experience bar"], UpdateBarColor)
	right:CreateColorSelection("experience-rested-color", C["experience-rested-color"], L["Rested Color"], L["Set the color of the rested bar"], UpdateRestedColor)
	right:CreateColorSelection("XPQuestColor", C.XPQuestColor, L["Quest Color"], L["Set the color of quest experience"], UpdateQuestColor)

	right:CreateHeader(L["Visibility"])
	right:CreateDropdown("experience-progress-visibility", C["experience-progress-visibility"], {[L["Always Show"]] = "ALWAYS", [L["Mouseover"]] = "MOUSEOVER"}, L["Progress Text"], L["Set when to display the progress information"], UpdateProgressVisibility)
	right:CreateDropdown("experience-percent-visibility", C["experience-percent-visibility"], {[L["Always Show"]] = "ALWAYS", [L["Mouseover"]] = "MOUSEOVER"}, L["Percent Text"], L["Set when to display the percent information"], UpdatePercentVisibility)

	left:CreateHeader("Mouseover")
	left:CreateSwitch("experience-mouseover", C["experience-mouseover"], L["Display On Mouseover"], L["Only display the experience bar while mousing over it"], UpdateMouseover)
	left:CreateSlider("experience-mouseover-opacity", C["experience-mouseover-opacity"], 0, 100, 5, L["Mouseover Opacity"], L["Set the opacity of the experience bar while not mousing over it"], UpdateMouseoverOpacity, nil, "%")
end)