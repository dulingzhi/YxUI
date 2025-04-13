local Y, L, A, C, D = YxUIGlobal:get()

local Reputation = Y:NewModule("Reputation")

local format = format
local floor = floor
local GetWatchedFactionInfo = GetWatchedFactionInfo
local GetWatchedFactionData = C_Reputation and C_Reputation.GetWatchedFactionData

D["reputation-enable"] = true
D["reputation-width"] = 316 -- 310
D["reputation-height"] = 16 -- 18
D["reputation-mouseover"] = false
D["reputation-mouseover-opacity"] = 0
D["reputation-display-progress"] = true
D["reputation-display-percent"] = true
D["reputation-show-tooltip"] = true
D["reputation-animate"] = true
D["reputation-progress-visibility"] = "ALWAYS"
D["reputation-percent-visibility"] = "ALWAYS"

local FadeOnFinished = function(self)
	self.Parent:Hide()
end

local UpdateProgressVisibility = function(value)
	if (not C["reputation-enable"]) then
		return
	end

	if (value == "MOUSEOVER") then
		Reputation.Progress:Hide()
	elseif (value == "ALWAYS" and C["experience-display-progress"]) then
		Reputation.Progress:Show()
	end
end

local UpdatePercentVisibility = function(value)
	if (not C["reputation-enable"]) then
		return
	end

	if (value == "MOUSEOVER") then
		Reputation.Percentage:Hide()
	elseif (value == "ALWAYS" and C["experience-display-percent"]) then
		Reputation.Percentage:Show()
	end
end

function Reputation:CreateBar()
	local Border = C["ui-border-thickness"]
	local Offset = 1 > Border and 1 or (Border + 2)

	self:SetSize(C["reputation-width"], C["reputation-height"])
	self:SetFrameStrata("MEDIUM")
    self:CreateBorder()

	if (C["experience-enable"] and not Y.IsMaxLevel) then
		local f = Y:GetModule("Experience")
        self:SetPoint("TOP", f, "BOTTOM", 0, -3)
        self:SetWidth(f:GetWidth())
    elseif Minimap:IsShown() then
        self:SetPoint("TOP", Minimap, "BOTTOM", 0, -6)
        self:SetWidth(C["minimap-size"])
	else
		self:SetPoint("TOP", Y.UIParent, 0, -13)
	end

	if C["reputation-mouseover"] then
		self:SetAlpha(C["reputation-mouseover-opacity"] / 100)
	end

	self.FadeIn = LibMotion:CreateAnimation(self, "Fade")
	self.FadeIn:SetEasing("in")
	self.FadeIn:SetDuration(0.15)
	self.FadeIn:SetChange(1)

	self.FadeOut = LibMotion:CreateAnimation(self, "Fade")
	self.FadeOut:SetEasing("out")
	self.FadeOut:SetDuration(0.15)
	self.FadeOut:SetChange(0)
	self.FadeOut:SetScript("OnFinished", FadeOnFinished)

	self.BarBG = CreateFrame("Frame", nil, self, "BackdropTemplate")
	self.BarBG:SetPoint("TOPLEFT", self, 0, 0)
	self.BarBG:SetPoint("BOTTOMRIGHT", self, 0, 0)
	Y:AddBackdrop(self.BarBG)
	self.BarBG.Outside:SetBackdropColor(Y:HexToRGB(C["ui-window-main-color"]))

	self.Bar = CreateFrame("StatusBar", nil, self.BarBG)
	self.Bar:SetStatusBarTexture(A:GetTexture(C["ui-widget-texture"]))
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
	self.Change:SetEasing("inout")
	self.Change:SetDuration(0.3)

	self.Flash = LibMotion:CreateAnimationGroup()

	self.Flash.In = LibMotion:CreateAnimation(self.Shine, "Fade")
	self.Flash.In:SetEasing("in")
	self.Flash.In:SetDuration(0.3)
	self.Flash.In:SetChange(0.3)
	self.Flash.In:SetGroup(self.Flash)

	self.Flash.Out = LibMotion:CreateAnimation(self.Shine, "Fade")
	self.Flash.Out:SetOrder(2)
	self.Flash.Out:SetEasing("out")
	self.Flash.Out:SetDuration(0.5)
	self.Flash.Out:SetChange(0)
	self.Flash.Out:SetGroup(self.Flash)

	self.Progress = self.Bar:CreateFontString(nil, "OVERLAY")
	self.Progress:SetPoint("LEFT", self.Bar, 5, 0)
	Y:SetFontInfo(self.Progress, C["ui-widget-font"], C["ui-font-size"])
	self.Progress:SetJustifyH("LEFT")

	if (not C["reputation-display-progress"] or C["reputation-progress-visibility"] ~= "ALWAYS") then
		self.Progress:Hide()
	end

	self.Percentage = self.Bar:CreateFontString(nil, "OVERLAY")
	self.Percentage:SetPoint("RIGHT", self.Bar, -5, 0)
	Y:SetFontInfo(self.Percentage, C["ui-widget-font"], C["ui-font-size"])
	self.Percentage:SetJustifyH("RIGHT")

	if (not C["reputation-display-percent"] or C["reputation-percent-visibility"] ~= "ALWAYS") then
		self.Percentage:Hide()
	end

	Y:CreateMover(self, 6)
end

function Reputation:OnEvent()
	local Name, StandingID, Min, Max, Value

	if Y.IsMainline then
		local Data = GetWatchedFactionData()
		
		if Data then
			Name = Data.name
			StandingID = Data.reaction
			Min = Data.currentReactionThreshold
			Max = Data.nextReactionThreshold
			Value = Data.currentStanding
		end
	else
		Name, StandingID, Min, Max, Value = GetWatchedFactionInfo()
	end

	if Name then
		Max = Max - Min
		Value = Value - Min

		self.Bar:SetMinMaxValues(0, Max)
		self.Bar:SetStatusBarColor(Y:HexToRGB(C["color-reaction-" .. StandingID]))

		self.Progress:SetText(format("%s: %s / %s", Name, Y:Comma(Value), Y:Comma(Max)))
		self.Percentage:SetText(floor((Value / Max * 100 + 0.05) * 10) / 10 .. "%")

		if C["reputation-animate"] then
			self.Change:SetChange(Value)
			self.Change:Play()

			if (not self.Flash:IsPlaying()) then
				self.Flash:Play()
			end
		else
			self.Bar:SetValue(Value)
		end

		if (not self:IsShown()) then
			self:Show()
			self.FadeIn:Play()
		end
	elseif self:IsShown() then
		self.FadeOut:Play()
	end
end

function Reputation:OnMouseUp()
	if not InCombatLockdown() then
		ToggleCharacter("ReputationFrame")
	end
end

function Reputation:OnEnter()
	if C["reputation-mouseover"] then
		self:SetAlpha(1)
	end

	if (C["reputation-display-progress"] and C["reputation-progress-visibility"] == "MOUSEOVER") then
		if (not self.Progress:IsShown()) then
			self.Progress:Show()
		end
	end

	if (C["reputation-display-percent"] and C["reputation-percent-visibility"] == "MOUSEOVER") then
		if (not self.Percentage:IsShown()) then
			self.Percentage:Show()
		end
	end

	if (not C["reputation-show-tooltip"]) then
		return
	end

	GameTooltip:SetOwner(self, "ANCHOR_BOTTOM", 0, -8)

	local Name, StandingID, Min, Max, Value

	if Y.IsMainline then
		local Data = GetWatchedFactionData()

		if Data then
			Name = Data.name
			StandingID = Data.reaction
			Min = Data.currentReactionThreshold
			Max = Data.nextReactionThreshold
			Value = Data.currentStanding
		end
	else
		Name, StandingID, Min, Max, Value = GetWatchedFactionInfo()
	end

	if (not Name) then
		return
	end

	GameTooltip:AddLine(Name)
	GameTooltip:AddLine(" ")

	Max = Max - Min
	Value = Value - Min

	local Remaining = Max - Value
	local RemainingPercent = floor((Remaining / Max * 100 + 0.05) * 10) / 10

	GameTooltip:AddLine(L["Current reputation"])
	GameTooltip:AddDoubleLine(format("%s / %s", Y:Comma(Value), Y:Comma(Max)), format("%s%%", floor((Value / Max * 100 + 0.05) * 10) / 10), 1, 1, 1, 1, 1, 1)

	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(L["Remaining reputation"])
	GameTooltip:AddDoubleLine(format("%s", Y:Comma(Remaining)), format("%s%%", RemainingPercent), 1, 1, 1, 1, 1, 1)

	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(L["Faction standing"])
	GameTooltip:AddLine(_G["FACTION_STANDING_LABEL" .. StandingID], 1, 1, 1)

	self.TooltipShown = true

	GameTooltip:Show()
end

function Reputation:OnLeave()
	if C["reputation-mouseover"] then
		self:SetAlpha(C["reputation-mouseover-opacity"] / 100)
	end

	if C["reputation-show-tooltip"] then
		GameTooltip:Hide()

		self.TooltipShown = false
	end

	if (C["reputation-display-progress"] and C["reputation-progress-visibility"] == "MOUSEOVER") then
		if self.Progress:IsShown() then
			self.Progress:Hide()
		end
	end

	if (C["reputation-display-percent"] and C["reputation-percent-visibility"] == "MOUSEOVER") then
		if self.Percentage:IsShown() then
			self.Percentage:Hide()
		end
	end
end

function Reputation:Load()
	if (not C["reputation-enable"]) then
		return
	end

	self:CreateBar()
	self:OnEvent()

	self:RegisterEvent("UPDATE_FACTION")
	self:SetScript("OnEvent", self.OnEvent)
	self:SetScript("OnEnter", self.OnEnter)
	self:SetScript("OnLeave", self.OnLeave)
	self:SetScript("OnMouseUp", self.OnMouseUp)
end

local UpdateDisplayProgress = function(value)
	if (not C["reputation-enable"]) then
		return
	end

	if (value and C["reputation-progress-visibility"] == "ALWAYS") then
		Reputation.Progress:Show()
	else
		Reputation.Progress:Hide()
	end
end

local UpdateDisplayPercent = function(value)
	if (not C["reputation-enable"]) then
		return
	end

	if (value and C["reputation-percent-visibility"] == "ALWAYS") then
		Reputation.Percentage:Show()
	else
		Reputation.Percentage:Hide()
	end
end

local UpdateBarWidth = function(value)
	if (not C["reputation-enable"]) then
		return
	end

	Reputation:SetWidth(value)
end

local UpdateBarHeight = function(value)
	if (not C["reputation-enable"]) then
		return
	end

	Reputation:SetHeight(value)
	Reputation.Bar.Spark:SetHeight(value)
end

local UpdateMouseover = function(value)
	if (not C["reputation-enable"]) then
		return
	end

	if value then
		Reputation:SetAlpha(C["reputation-mouseover-opacity"] / 100)
	else
		Reputation:SetAlpha(1)
	end
end

local UpdateMouseoverOpacity = function(value)
	if (not C["reputation-enable"]) then
		return
	end

	if C["reputation-mouseover"] then
		Reputation:SetAlpha(value / 100)
	end
end

Y:GetModule("GUI"):AddWidgets(L["General"], L["Reputation"], function(left, right)
	left:CreateHeader(L["Enable"])
	left:CreateSwitch("reputation-enable", true, L["Enable Reputation Module"], L["Enable the YxUI reputation module"], ReloadUI):RequiresReload(true)

	left:CreateHeader(L["Styling"])
	left:CreateSwitch("reputation-display-progress", C["reputation-display-progress"], L["Display Progress Value"], L["Display your current progress information in the reputation bar"], UpdateDisplayProgress)
	left:CreateSwitch("reputation-display-percent", C["reputation-display-percent"], L["Display Percent Value"], L["Display your current percent information in the reputation bar"], UpdateDisplayPercent)
	left:CreateSwitch("reputation-show-tooltip", C["reputation-show-tooltip"], L["Enable Tooltip"], L["Display a tooltip when mousing over the reputation bar"])
	left:CreateSwitch("reputation-animate", C["reputation-animate"], L["Animate Reputation Changes"], L["Smoothly animate changes to the reputation bar"])

	right:CreateHeader(L["Size"])
	right:CreateSlider("reputation-width", C["reputation-width"], 180, 400, 2, L["Bar Width"], L["Set the width of the reputation bar"], UpdateBarWidth)
	right:CreateSlider("reputation-height", C["reputation-height"], 6, 30, 1, L["Bar Height"], L["Set the height of the reputation bar"], UpdateBarHeight)

	right:CreateHeader(L["Visibility"])
	right:CreateDropdown("reputation-progress-visibility", C["reputation-progress-visibility"], {[L["Always Show"]] = "ALWAYS", [L["Mouseover"]] = "MOUSEOVER"}, L["Progress Text"], L["Set when to display the progress information"], UpdateProgressVisibility)
	right:CreateDropdown("reputation-percent-visibility", C["reputation-percent-visibility"], {[L["Always Show"]] = "ALWAYS", [L["Mouseover"]] = "MOUSEOVER"}, L["Percent Text"], L["Set when to display the percent information"], UpdatePercentVisibility)

	left:CreateHeader("Mouseover")
	left:CreateSwitch("reputation-mouseover", C["reputation-mouseover"], L["Display On Mouseover"], L["Only display the reputation bar while mousing over it"], UpdateMouseover)
	left:CreateSlider("reputation-mouseover-opacity", C["reputation-mouseover-opacity"], 0, 100, 5, L["Mouseover Opacity"], L["Set the opacity of the reputation bar while not mousing over it"], UpdateMouseoverOpacity, nil, "%")
end)