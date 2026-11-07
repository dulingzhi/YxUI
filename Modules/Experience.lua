local YxUI, Language, Assets, Settings, Defaults = select(2, ...):get()

local Experience = YxUI:NewModule("Experience")

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
local GetNumQuests
local LEVEL = LEVEL
local HasXPBuff
local XPMod = 1
local FirstRun = true

if YxUI.IsMainline then
	GetNumQuests = C_QuestLog.GetNumQuestLogEntries
elseif YxUI.IsMists then
	GetNumQuests = GetNumQuestLogEntries
	HasXPBuff = IsSpellKnown(78632) -- Fast Track +10%
	XPMod = 1.10
else
	GetNumQuests = GetNumQuestLogEntries
	--HasXPBuff = AuraUtil.FindAuraByName("player", GetSpellInfo(377749), "HELPFUL") -- Joyous Journeys +50%
	XPMod = 1.50
end

Defaults["experience-enable"] = true
Defaults["experience-width"] = 316
Defaults["experience-height"] = 24
Defaults["experience-mouseover"] = false
Defaults["experience-mouseover-opacity"] = 0
Defaults["experience-display-level"] = false
Defaults["experience-display-progress"] = true
Defaults["experience-display-percent"] = true
Defaults["experience-display-rested-value"] = true
Defaults["experience-show-tooltip"] = true
Defaults["experience-animate"] = true
Defaults["experience-progress-visibility"] = "ALWAYS"
Defaults["experience-percent-visibility"] = "ALWAYS"
Defaults["experience-bar-color"] = "4C9900" -- 1AE045
Defaults["experience-rested-color"] = "00B4FF"
Defaults.XPQuestColor = "CCCC19"

local FadeOnFinished = function(self)
	self.Parent:Hide()
end

local UpdateDisplayProgress = function(value)
	if not Settings["experience-enable"] then
		return
	end

	if value and Settings["experience-progress-visibility"] == "ALWAYS" then
		Experience.Progress:Show()
	else
		Experience.Progress:Hide()
	end

	Experience:MarkTooltipDirty()
end

local UpdateDisplayPercent = function(value)
	if not Settings["experience-enable"] then
		return
	end

	if value and Settings["experience-percent-visibility"] == "ALWAYS" then
		Experience.Percentage:Show()
	else
		Experience.Percentage:Hide()
	end

	Experience:MarkTooltipDirty()
end

local UpdateBarWidth = function(value)
	if not Settings["experience-enable"] then
		return
	end

	Experience:SetWidth(value)
	Experience:MarkTooltipDirty()
end

local UpdateBarHeight = function(value)
	if not Settings["experience-enable"] then
		return
	end

	Experience:SetHeight(value)
	Experience.Bar.Spark:SetHeight(value)
	Experience:MarkTooltipDirty()
end

local UpdateProgressVisibility = function(value)
	if not Settings["experience-enable"] then
		return
	end

	if value == "MOUSEOVER" then
		Experience.Progress:Hide()
	elseif value == "ALWAYS" and Settings["experience-display-progress"] then
		Experience.Progress:Show()
	end

	Experience:MarkTooltipDirty()
end

local UpdatePercentVisibility = function(value)
	if not Settings["experience-enable"] then
		return
	end

	if value == "MOUSEOVER" then
		Experience.Percentage:Hide()
	elseif value == "ALWAYS" and Settings["experience-display-percent"] then
		Experience.Percentage:Show()
	end

	Experience:MarkTooltipDirty()
end

function Experience:OnMouseUp()
	ToggleCharacter("PaperDollFrame")
end

function Experience:CreateForeverCharacterButton()
	if self.CharacterClick or InCombatLockdown() or not CharacterMicroButton then
		return
	end

	local Button = CreateFrame("Button", nil, self, "InsecureActionButtonTemplate")
	Button:SetAllPoints(self)
	Button:SetFrameLevel(self:GetFrameLevel() + 10)
	Button:RegisterForClicks("AnyUp")
	Button:SetAttribute("useOnKeyDown", false)
	Button:SetAttribute("type1", "click")
	Button:SetAttribute("clickbutton1", CharacterMicroButton)
	Button:SetScript("OnEnter", function() self:OnEnter() end)
	Button:SetScript("OnLeave", function() self:OnLeave() end)

	self.CharacterClick = Button
end

function Experience:PLAYER_REGEN_ENABLED()
	self:CreateForeverCharacterButton()

	if self.CharacterClick then
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end
end

function Experience:UpdateTooltipTimer()
	if GameTooltip:IsOwned(self) and GameTooltip:IsShown() and self.Gained > 0 then
		self:SetScript("OnUpdate", self.OnUpdate)
	else
		self:SetScript("OnUpdate", nil)
		self.Elapsed = 0
	end
end

function Experience:MarkTooltipDirty()
	self.TooltipDirty = true

	if GameTooltip:IsOwned(self) and GameTooltip:IsShown() then
		self:UpdateTooltip()
	end
end

function Experience:CreateBar()
	local Border = Settings["ui-border-thickness"]
	local Offset = 1 > Border and 1 or (Border + 2)

	self:SetSize(Settings["experience-width"], Settings["experience-height"])
	self:SetPoint("TOP", YxUI.UIParent, 0, -13)
	self:SetFrameStrata("MEDIUM")
	self.Elapsed = 0

	if Settings["experience-mouseover"] then
		self:SetAlpha(Settings["experience-mouseover-opacity"] / 100)
	end

	self.LastXP = UnitXP("player")
	self.LastMax = UnitXPMax("player")
	self.LastLevel = UnitLevel("player")
	self.Seconds = 0
	self.Gained = 0

	self.BarBG = CreateFrame("Frame", nil, self, "BackdropTemplate")
	self.BarBG:SetPoint("TOPLEFT", self, 0, 0)
	self.BarBG:SetPoint("BOTTOMRIGHT", self, 0, 0)
	YxUI:AddBackdrop(self.BarBG)
	self.BarBG.Outside:SetBackdropColor(YxUI:HexToRGB(Settings["ui-window-main-color"]))

	self.Bar = CreateFrame("StatusBar", nil, self.BarBG)
	self.Bar:SetStatusBarTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	self.Bar:SetStatusBarColor(YxUI:HexToRGB(Settings["experience-bar-color"]))
	self.Bar:SetPoint("TOPLEFT", self.BarBG, Offset, -Offset)
	self.Bar:SetPoint("BOTTOMRIGHT", self.BarBG, -Offset, Offset)
	self.Bar:SetFrameLevel(6)

	self.Bar.BG = self.Bar:CreateTexture(nil, "BORDER")
	self.Bar.BG:SetAllPoints(self.Bar)
	self.Bar.BG:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	self.Bar.BG:SetVertexColor(YxUI:HexToRGB(Settings["ui-window-main-color"]))
	self.Bar.BG:SetAlpha(0.2)

	self.Bar.Spark = self.Bar:CreateTexture(nil, "OVERLAY")
	self.Bar.Spark:SetDrawLayer("OVERLAY", 7)
	self.Bar.Spark:SetWidth(1)
	self.Bar.Spark:SetPoint("TOPLEFT", self.Bar:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
	self.Bar.Spark:SetPoint("BOTTOMLEFT", self.Bar:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
	self.Bar.Spark:SetTexture(Assets:GetTexture("Blank"))
	self.Bar.Spark:SetVertexColor(0, 0, 0)

	self.Shine = self.Bar:CreateTexture(nil, "ARTWORK")
	self.Shine:SetAllPoints(self.Bar:GetStatusBarTexture())
	self.Shine:SetTexture(Assets:GetTexture("pHishTex12"))
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
	self.Bar.Rested:SetStatusBarTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	self.Bar.Rested:SetStatusBarColor(YxUI:HexToRGB(Settings["experience-rested-color"]))
	self.Bar.Rested:SetFrameLevel(5)
	self.Bar.Rested:SetAllPoints(self.Bar)

	self.Bar.Rested.Spark = self.Bar.Rested:CreateTexture(nil, "OVERLAY")
	self.Bar.Rested.Spark:SetWidth(1)
	self.Bar.Rested.Spark:SetPoint("TOPLEFT", self.Bar:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
	self.Bar.Rested.Spark:SetPoint("BOTTOMLEFT", self.Bar:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
	self.Bar.Rested.Spark:SetTexture(Assets:GetTexture("Blank"))
	self.Bar.Rested.Spark:SetVertexColor(0, 0, 0)

	self.Bar.Quest = CreateFrame("StatusBar", nil, self.Bar)
	self.Bar.Quest:SetStatusBarTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	self.Bar.Quest:SetStatusBarColor(YxUI:HexToRGB(Settings.XPQuestColor))
	self.Bar.Quest:SetFrameLevel(6)
	self.Bar.Quest:SetAllPoints(self.Bar)

	self.Bar.Quest.Spark = self.Bar.Quest:CreateTexture(nil, "OVERLAY")
	self.Bar.Quest.Spark:SetWidth(1)
	self.Bar.Quest.Spark:SetPoint("TOPLEFT", self.Bar:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
	self.Bar.Quest.Spark:SetPoint("BOTTOMLEFT", self.Bar:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
	self.Bar.Quest.Spark:SetTexture(Assets:GetTexture("Blank"))
	self.Bar.Quest.Spark:SetVertexColor(0, 0, 0)

	self.Progress = self.Bar:CreateFontString(nil, "OVERLAY")
	self.Progress:SetPoint("LEFT", self.Bar, 5, 0)
	YxUI:SetFontInfo(self.Progress, Settings["ui-widget-font"], Settings["ui-font-size"])
	self.Progress:SetJustifyH("LEFT")

	self.Percentage = self.Bar:CreateFontString(nil, "OVERLAY")
	self.Percentage:SetPoint("RIGHT", self.Bar, -5, 0)
	YxUI:SetFontInfo(self.Percentage, Settings["ui-widget-font"], Settings["ui-font-size"])
	self.Percentage:SetJustifyH("RIGHT")

	YxUI:CreateMover(self, 6)
end

function Experience:Update()
	Rested = GetXPExhaustion()
	XP = UnitXP("player")
	MaxXP = UnitXPMax("player")

	if not MaxXP or MaxXP <= 0 then
		if YxUI.IsForever then
			self.Change:Stop()
		end

		self:Hide()
		if GameTooltip:IsOwned(self) then
			GameTooltip:Hide()
		end

		self:SetScript("OnUpdate", nil)
		self.Elapsed = 0
		self.Bar.QuestXP = 0
		self.LastXP = XP
		self.LastMax = 0
		self.TooltipValues = nil
		self.TooltipDirty = true
		return
	end

	if self.LastMax == 0 then
		self.LastXP = XP
		self.LastMax = MaxXP
		self.Gained = 0
		self.StartTime = nil
		FirstRun = true
	end

	if not self:IsShown() then
		self:Show()
	end

	RestingText = IsResting() and ("|cFF" .. Settings["experience-rested-color"] .. "zZz|r") or ""

	local QuestLogXP = 0
	local ZoneName
	local Level = Settings["experience-display-level"] and (format("%s %d - ", LEVEL, UnitLevel("player"))) or ""
	local MapID = C_Map.GetBestMapForUnit("player")
	local CurrentZone

	if MapID then
		CurrentZone = C_Map.GetMapInfo(MapID).name or GetRealZoneText()
	else
		CurrentZone = GetRealZoneText()
	end

	if YxUI.IsMainline then
		for i = 1, GetNumQuests() do
			local Info = GetQuestInfo(i)

			if Info.isHeader and not Info.isHidden then
				ZoneName = Info.title
			else
				if ZoneName and ZoneName == CurrentZone and ReadyForTurnIn(Info.questID) then
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
				if ZoneName and ZoneName == CurrentZone and IsComplete then
					QuestLogXP = QuestLogXP + GetQuestLogRewardXP(QuestID)
				end
			end
		end
	end

	if QuestLogXP > 0 then
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

		if Settings["experience-display-rested-value"] then
			self.Progress:SetFormattedText("%s%s / %s (+%s) %s", Level, YxUI:Comma(XP), YxUI:Comma(MaxXP), YxUI:Comma(Rested), RestingText)
		else
			self.Progress:SetFormattedText("%s%s / %s %s", Level, YxUI:Comma(XP), YxUI:Comma(MaxXP), RestingText)
		end
	else
		self.Bar.Rested:SetValue(0)
		self.Progress:SetFormattedText("%s%s / %s %s", Level, YxUI:Comma(XP), YxUI:Comma(MaxXP), RestingText)
	end

	self.Percentage:SetText(floor((XP / MaxXP * 100 + 0.05) * 10) / 10 .. "%")

	if XP > 0 then
		if self.Bar.Spark:GetAlpha() == 0 then
			self.Bar.Spark:SetAlpha(1)
		end
	elseif self.Bar.Spark:GetAlpha() > 0 then
		self.Bar.Spark:SetAlpha(0)
	end

	if Rested and (Rested > 0) then
		if self.Bar.Rested.Spark:GetAlpha() == 0 then
			self.Bar.Rested.Spark:SetAlpha(1)
		end
	elseif self.Bar.Rested.Spark:GetAlpha() > 0 then
		self.Bar.Rested.Spark:SetAlpha(0)
	end

	local LevelReset = YxUI.IsForever and (MaxXP ~= self.LastMax or XP < self.LastXP or UnitLevel("player") ~= self.LastLevel)

	if Settings["experience-animate"] then
		if FirstRun or LevelReset then
			if YxUI.IsForever then
				self.Change:Stop()
			end

			self.Bar:SetValue(XP)
			FirstRun = false
		elseif not YxUI.IsForever or XP ~= self.LastXP then
			if YxUI.IsForever then
				self.Change:Stop()
			end

			self.Change:SetChange(XP)
			self.Change:Play()

			if (XP > self.LastXP) and not self.Flash:IsPlaying() then
				self.Flash:Play()
			end
		end
	else
		if YxUI.IsForever then
			self.Change:Stop()
		end

		self.Bar:SetValue(XP)
	end

	if MaxXP ~= self.LastMax then
		self.Gained = self.LastMax - self.LastXP + XP + self.Gained
	else
		self.Gained = (XP - self.LastXP) + self.Gained
	end

	if not self.StartTime then
		self.StartTime = GetTime()
	end

	self.LastXP = XP
	self.LastMax = MaxXP
	self.LastLevel = UnitLevel("player")

	self:MarkTooltipDirty()
end

function Experience:PLAYER_LEVEL_UP()
	self:Update()
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
	if not GameTooltip:IsOwned(self) or not GameTooltip:IsShown() or self.Gained <= 0 then
		self:UpdateTooltipTimer()
		return
	end

	self.Elapsed = self.Elapsed + elapsed

	if self.Elapsed > 1 then
		self.Elapsed = 0
		self:MarkTooltipDirty()
	end
end

function Experience:UpdateTooltip()
	if not GameTooltip:IsOwned(self) then
		return
	end

	if not self.TooltipDirty then
		self:UpdateTooltipTimer()
		return
	end

	local RestedXP = GetXPExhaustion()
	local CurrentXP = UnitXP("player")
	local MaximumXP = UnitXPMax("player")
	if not MaximumXP or MaximumXP <= 0 then
		GameTooltip:Hide()
		self:UpdateTooltipTimer()
		return
	end

	local Percent = floor((CurrentXP / MaximumXP * 100 + 0.05) * 10) / 10
	local Remaining = MaximumXP - CurrentXP
	local RemainingPercent = floor((Remaining / MaximumXP * 100 + 0.05) * 10) / 10
	local QuestXP = self.Bar.QuestXP or 0
	local SessionPerHour
	local SessionTimeToLevel
	local SessionDuration

	if self.Gained > 0 then
		local Duration = max(GetTime() - self.StartTime, 1)
		local PerSec = self.Gained / Duration

		SessionPerHour = YxUI:Comma(((PerSec * 60) * 60))
		SessionTimeToLevel = YxUI:FormatFullTime(Remaining / PerSec)
		SessionDuration = YxUI:FormatFullTime(Duration)
	end

	local Values = table.concat({
		UnitLevel("player"),
		CurrentXP,
		MaximumXP,
		RestedXP or "",
		QuestXP,
		self.Gained,
		SessionPerHour or "",
		SessionTimeToLevel or "",
		SessionDuration or "",
	}, "\031")

	self.TooltipDirty = false

	if Values == self.TooltipValues then
		self:UpdateTooltipTimer()
		return
	end

	self.TooltipValues = Values
	GameTooltip:ClearLines()
	GameTooltip:AddLine(LEVEL .. " " .. UnitLevel("player"))
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(Language["Current Experience"])
	GameTooltip:AddDoubleLine(format("%s / %s", YxUI:Comma(CurrentXP), YxUI:Comma(MaximumXP)), format("%s%%", Percent), 1, 1, 1, 1, 1, 1)

	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(Language["Remaining Experience"])
	GameTooltip:AddDoubleLine(format("%s", YxUI:Comma(Remaining)), format("%s%%", RemainingPercent), 1, 1, 1, 1, 1, 1)

	if RestedXP then
		local RestedPercent = floor((RestedXP / MaximumXP * 100 + 0.05) * 10) / 10

		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(Language["Rested Experience"])
		GameTooltip:AddDoubleLine(YxUI:Comma(RestedXP), format("%s%%", RestedPercent), 1, 1, 1, 1, 1, 1)
	end

	if QuestXP > 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(Language["Quest Experience"])
		GameTooltip:AddDoubleLine(YxUI:Comma(QuestXP), format("%s%%", floor((QuestXP / MaximumXP * 100 + 0.05) * 10) / 10), 1, 1, 1, 1, 1, 1)
	end

	if self.Gained > 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(Language["Session Stats"])
		GameTooltip:AddDoubleLine(Language["Experience gained"], YxUI:Comma(self.Gained), 1, 1, 1, 1, 1, 1)
		GameTooltip:AddDoubleLine(Language["Per hour"], SessionPerHour, 1, 1, 1, 1, 1, 1)
		GameTooltip:AddDoubleLine(Language["Time to level:"], SessionTimeToLevel, 1, 1, 1, 1, 1, 1)
		GameTooltip:AddDoubleLine(Language["Duration"], SessionDuration, 1, 1, 1, 1, 1, 1)
	end

	GameTooltip:Show()
	self:UpdateTooltipTimer()
end

function Experience:OnEnter()
	if Settings["experience-mouseover"] then
		self:SetAlpha(1)
	end

	if Settings["experience-display-progress"] and Settings["experience-progress-visibility"] == "MOUSEOVER" then
		if not self.Progress:IsShown() then
			self.Progress:Show()
		end
	end

	if Settings["experience-display-percent"] and Settings["experience-percent-visibility"] == "MOUSEOVER" then
		if not self.Percentage:IsShown() then
			self.Percentage:Show()
		end
	end

	if not Settings["experience-show-tooltip"] then
		return
	end

	GameTooltip:SetOwner(self, "ANCHOR_BOTTOM", 0, -8)
	self.TooltipDirty = true
	self.TooltipValues = nil
	self:UpdateTooltip()
end

function Experience:OnLeave()
	if Settings["experience-mouseover"] then
		self:SetAlpha(Settings["experience-mouseover-opacity"] / 100)
	end

	if Settings["experience-show-tooltip"] then
		GameTooltip:Hide()
	end

	if Settings["experience-display-progress"] and Settings["experience-progress-visibility"] == "MOUSEOVER" then
		if self.Progress:IsShown() then
			self.Progress:Hide()
		end
	end

	if Settings["experience-display-percent"] and Settings["experience-percent-visibility"] == "MOUSEOVER" then
		if self.Percentage:IsShown() then
			self.Percentage:Hide()
		end
	end

	self:SetScript("OnUpdate", nil)
	self.Elapsed = 0
	self.TooltipValues = nil
end

function Experience:Load()
	if not Settings["experience-enable"] then
		return
	end

	self:CreateBar()
	self:RegisterEvent("QUEST_LOG_UPDATE")
	self:RegisterEvent("PLAYER_LEVEL_UP")
	self:RegisterEvent("PLAYER_XP_UPDATE")
	self:RegisterEvent("PLAYER_UPDATE_RESTING")
	self:RegisterEvent("UPDATE_EXHAUSTION")
	self:RegisterEvent("ZONE_CHANGED")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:SetScript("OnEvent", self.OnEvent)

	if YxUI.IsForever then
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		self:CreateForeverCharacterButton()
	else
		self:SetScript("OnMouseUp", self.OnMouseUp)
	end

	self:SetScript("OnEnter", self.OnEnter)
	self:SetScript("OnLeave", self.OnLeave)

	self:Update()

	UpdateDisplayProgress(Settings["experience-display-progress"])
	UpdateDisplayPercent(Settings["experience-display-percent"])
	UpdateProgressVisibility(Settings["experience-progress-visibility"])
	UpdatePercentVisibility(Settings["experience-percent-visibility"])

	if StatusTrackingBarManager then
		StatusTrackingBarManager:Hide()
	end
end

local UpdateBarColor = function(value)
	if not Settings["experience-enable"] then
		return
	end

	Experience.Bar:SetStatusBarColor(YxUI:HexToRGB(value))
	Experience.Bar.BG:SetVertexColor(YxUI:HexToRGB(value))
	Experience:MarkTooltipDirty()
end

local UpdateRestedColor = function(value)
	if not Settings["experience-enable"] then
		return
	end

	Experience.Bar.Rested:SetStatusBarColor(YxUI:HexToRGB(value))
	Experience:MarkTooltipDirty()
end

local UpdateQuestColor = function(value)
	if not Settings["experience-enable"] then
		return
	end

	Experience.Bar.Quest:SetStatusBarColor(YxUI:HexToRGB(value))
	Experience:MarkTooltipDirty()
end

local UpdateExperience = function()
	Experience:Update()
end

local UpdateTooltipSetting = function(value)
	if not Settings["experience-enable"] then
		return
	end

	Experience.TooltipDirty = true

	if not value and GameTooltip:IsOwned(Experience) then
		GameTooltip:Hide()
		Experience:UpdateTooltipTimer()
	elseif value and GameTooltip:IsOwned(Experience) and GameTooltip:IsShown() then
		Experience:UpdateTooltip()
	end
end

local UpdateMouseover = function(value)
	if not Settings["experience-enable"] then
		return
	end

	if value then
		Experience:SetAlpha(Settings["experience-mouseover-opacity"] / 100)
	else
		Experience:SetAlpha(1)
	end

	Experience:MarkTooltipDirty()
end

local UpdateMouseoverOpacity = function(value)
	if not Settings["experience-enable"] then
		return
	end

	if Settings["experience-mouseover"] then
		Experience:SetAlpha(value / 100)
	end

	Experience:MarkTooltipDirty()
end

YxUI:GetModule("GUI"):AddWidgetsID("General", "Experience", function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("experience-enable", Settings["experience-enable"], Language["Enable Experience Module"], Language["Enable the YxUI experience module"], ReloadUI):RequiresReload(true)

	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("experience-display-level", Settings["experience-display-level"], Language["Display Level"], Language["Display your current level in the experience bar"], UpdateExperience)
	left:CreateSwitch("experience-display-progress", Settings["experience-display-progress"], Language["Display Progress Value"], Language["Display your current progress in the experience bar"], UpdateDisplayProgress)
	left:CreateSwitch("experience-display-percent", Settings["experience-display-percent"], Language["Display Percent Value"], Language["Display your current percentage in the experience bar"], UpdateDisplayPercent)
	left:CreateSwitch("experience-display-rested-value", Settings["experience-display-rested-value"], Language["Display Rested Value"], Language["Display your current rested value on the experience bar"], UpdateExperience)
	left:CreateSwitch("experience-show-tooltip", Settings["experience-show-tooltip"], Language["Enable Tooltip"], Language["Display a tooltip when hovering over the experience bar"], UpdateTooltipSetting)
	left:CreateSwitch("experience-animate", Settings["experience-animate"], Language["Animate Experience Changes"], Language["Smoothly animate changes to the experience bar"])

	right:CreateHeader(Language["Size"])
	right:CreateSlider("experience-width", Settings["experience-width"], 180, 400, 2, Language["Bar Width"], Language["Set the width of the experience bar"], UpdateBarWidth)
	right:CreateSlider("experience-height", Settings["experience-height"], 6, 30, 1, Language["Bar Height"], Language["Set the height of the experience bar"], UpdateBarHeight)

	right:CreateHeader(Language["Colors"])
	right:CreateColorSelection("experience-bar-color", Settings["experience-bar-color"], Language["Experience Color"], Language["Set the color of the experience bar"], UpdateBarColor)
	right:CreateColorSelection("experience-rested-color", Settings["experience-rested-color"], Language["Rested Color"], Language["Set the color of the rested bar"], UpdateRestedColor)
	right:CreateColorSelection("XPQuestColor", Settings.XPQuestColor, Language["Quest Color"], Language["Set the color of quest experience"], UpdateQuestColor)

	right:CreateHeader(Language["Visibility"])
	right:CreateDropdown("experience-progress-visibility", Settings["experience-progress-visibility"], {[Language["Always Show"]] = "ALWAYS", [Language["Mouseover"]] = "MOUSEOVER"}, Language["Progress Text"], Language["Set when to display the progress information"], UpdateProgressVisibility)
	right:CreateDropdown("experience-percent-visibility", Settings["experience-percent-visibility"], {[Language["Always Show"]] = "ALWAYS", [Language["Mouseover"]] = "MOUSEOVER"}, Language["Percent Text"], Language["Set when to display the percent information"], UpdatePercentVisibility)

	left:CreateHeader(Language["Mouseover"])
	left:CreateSwitch("experience-mouseover", Settings["experience-mouseover"], Language["Display on Mouseover"], Language["Only display the experience bar while hovering over it"], function(value) UpdateMouseover(value); YxUI:GetModule("GUI").WidgetCore.UpdateDependencies({["experience-mouseover-opacity"] = value}) end)
	left:CreateSlider("experience-mouseover-opacity", Settings["experience-mouseover-opacity"], 0, 100, 5, Language["Mouseover Opacity"], Language["Set the opacity of the experience bar while not hovering over it"], UpdateMouseoverOpacity, nil, "%")
	YxUI:GetModule("GUI").WidgetCore.UpdateDependencies({["experience-mouseover-opacity"] = Settings["experience-mouseover"]})
end)
YxUI:GetModule("GUI"):RegisterPageSettingsID("General", "Experience", {
	{"experience-display-level", UpdateExperience},
	{"experience-display-progress", UpdateDisplayProgress},
	{"experience-display-percent", UpdateDisplayPercent},
	{"experience-display-rested-value", UpdateExperience},
	{"experience-show-tooltip", UpdateTooltipSetting},
	{"experience-width", UpdateBarWidth},
	{"experience-height", UpdateBarHeight},
	{"experience-bar-color", UpdateBarColor},
	{"experience-rested-color", UpdateRestedColor},
	{"XPQuestColor", UpdateQuestColor},
	{"experience-progress-visibility", UpdateProgressVisibility},
	{"experience-percent-visibility", UpdatePercentVisibility},
	{"experience-mouseover", function(value) UpdateMouseover(value); YxUI:GetModule("GUI").WidgetCore.UpdateDependencies({["experience-mouseover-opacity"] = value}) end},
	{"experience-mouseover-opacity", UpdateMouseoverOpacity},
}, nil)


YxUI:GetModule("GUI"):RegisterReloadSettings({"experience-enable"})
