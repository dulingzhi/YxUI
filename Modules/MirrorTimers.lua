local YxUI, Language, Assets, Settings = select(2, ...):get()

local MirrorTimers = YxUI:NewModule("Mirror Timers")

local GetMirrorTimerProgress = GetMirrorTimerProgress
local GetMirrorTimerInfo = GetMirrorTimerInfo

MirrorTimers.Colors = {
	["EXHAUSTION"] = "FFE500",
	["BREATH"] = "007FFF",
	["DEATH"] = "FFB200",
	["FEIGNDEATH"] = "FFB200",
}

local function UpdateText(Bar, Value)
	local tick = Value > 5 and math.floor(Value) or math.floor(Value * 10 + 0.5)
	if tick == Bar.LastTimeTick then
		return
	end
	Bar.LastTimeTick = tick
	local Text

	if Value > 0 then
		Text = format("%s (%s)", Bar.Label, YxUI:FormatTime(Value))
	else
		Text = format("%s", Bar.Label)
	end

	if Text ~= Bar.LastText then
		Bar.LastText = Text
		Bar.Text:SetText(Text)
	end
end

function MirrorTimers:OnUpdate()
	if self.Paused then
		return
	end

	self.Value = GetMirrorTimerProgress(self.Timer) / 1000
	UpdateText(self, self.Value)
	self:SetValue(self.Value)
end

function MirrorTimers:MIRROR_TIMER_PAUSE(ispaused)
	if ispaused then
		self.Bar.Paused = true
	else
		self.Bar.Paused = false
	end
end

function MirrorTimers:MIRROR_TIMER_STOP()
	self.Bar.LastText = nil
	self.Bar:Hide()
end

function MirrorTimers:OnEvent(event, ...)
	if self[event] then
		self[event](self, ...)
	end
end

MirrorTimers.MirrorTimer_Show = function(timer, value, maxvalue, scale, paused, label)
	MirrorTimers.Bar.Max = maxvalue
	MirrorTimers.Bar.Value = value
	MirrorTimers.Bar.Timer = timer
	MirrorTimers.Bar.Label = label
	MirrorTimers.Bar.LastText = nil
	MirrorTimers.Bar.LastTimeTick = nil

	MirrorTimers.Bar:SetMinMaxValues(0, maxvalue / 1000)
	MirrorTimers.Bar:SetValue(value)
	MirrorTimers.Bar:SetStatusBarColor(YxUI:HexToRGB(MirrorTimers.Colors[timer]))
	MirrorTimers.BarBG:SetVertexColor(YxUI:HexToRGB(MirrorTimers.Colors[timer]))
	UpdateText(MirrorTimers.Bar, value / 1000)
	MirrorTimers.Bar:Show()
end

function MirrorTimers:Load()
	if YxUI.IsMainline then
		return -- Patch 10.1.5; Need a rewrite
	end

	self.Bar = CreateFrame("StatusBar", "YxUI Timers Bar", YxUI.UIParent)
	self.Bar:SetPoint("TOP", YxUI.UIParent, 0, -120)
	self.Bar:SetSize(210, 20)
	self.Bar:SetFrameLevel(5)
	self.Bar:SetStatusBarTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	self.Bar:SetScript("OnUpdate", self.OnUpdate)
	self.Bar:Hide()

	self.BarBG = self.Bar:CreateTexture(nil, "BORDER")
	self.BarBG:SetPoint("TOPLEFT", self.Bar, 0, 0)
	self.BarBG:SetPoint("BOTTOMRIGHT", self.Bar, 0, 0)
	self.BarBG:SetTexture(Assets:GetTexture(Settings["ui-widget-texture"]))
	self.BarBG:SetAlpha(0.2)

	self.Bar.Text = self.Bar:CreateFontString(nil, "OVERLAY")
	self.Bar.Text:SetPoint("CENTER", self.Bar, 0, 0)
	YxUI:SetFontInfo(self.Bar.Text, Settings["ui-widget-font"], Settings["ui-font-size"])
	self.Bar.Text:SetJustifyH("CENTER")

	self.BarOutline = self.Bar:CreateTexture(nil, "BORDER")
	self.BarOutline:SetPoint("TOPLEFT", self.Bar, -1, 1)
	self.BarOutline:SetPoint("BOTTOMRIGHT", self.Bar, 1, -1)
	self.BarOutline:SetTexture(Assets:GetTexture("Blank"))
	self.BarOutline:SetVertexColor(0, 0, 0)

	self.OuterBG = CreateFrame("Frame", nil, self.Bar, "BackdropTemplate")
	self.OuterBG:SetPoint("TOPLEFT", self.Bar, -4, 4)
	self.OuterBG:SetPoint("BOTTOMRIGHT", self.Bar, 4, -4)
	self.OuterBG:SetBackdrop(YxUI.BackdropAndBorder)
	self.OuterBG:SetBackdropBorderColor(0, 0, 0)
	self.OuterBG:SetFrameLevel(1)
	self.OuterBG:SetFrameStrata("BACKGROUND")
	self.OuterBG:SetBackdropColor(YxUI:HexToRGB(Settings["ui-window-bg-color"]))

	hooksecurefunc("MirrorTimer_Show", self.MirrorTimer_Show)

	self:RegisterEvent("MIRROR_TIMER_PAUSE")
	self:RegisterEvent("MIRROR_TIMER_STOP")

	self.Hider = CreateFrame("Frame", nil, YxUI.UIParent)
	self.Hider:Hide()

	YxUI:CreateMover(self.Bar, 6)

	for i = 1, MIRRORTIMER_NUMTIMERS do
		_G["MirrorTimer" .. i]:SetParent(self.Hider)
	end

	self:SetScript("OnEvent", self.OnEvent)
end
