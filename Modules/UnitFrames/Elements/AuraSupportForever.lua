local _, ns = ...
local YxUI, _, Assets, Settings = ns:get()
local UF = YxUI:GetModule("Unit Frames")

function UF:IsForeverAuraFrame(frame)
	return YxUI.IsForever and (frame.isNamePlate or frame.unit == "target" or frame.unit == "player")
end

if not YxUI.IsForever then
	return
end

local holders = setmetatable({}, {__mode = "k"})
local AuraKinds = {"Buffs", "Debuffs"}

local DurationFormatter = C_StringUtil.CreateSecondsFormatter()
DurationFormatter:SetDefaultAbbreviation(Enum.SecondsFormatterAbbreviation.OneLetter)
DurationFormatter:SetStripIntervalWhitespace(Enum.SecondsFormatterIntervalWhitespace.StripIgnoreLocale)
DurationFormatter:SetDesiredUnitCount(1)
DurationFormatter:SetMillisecondsThreshold(0)
local DurationTextOptions = {textFormatter = DurationFormatter}

local function UpdateButtonStyle(button, holder)
	if button.IsForbidden and button:IsForbidden() then
		return
	end

	button:SetSize(holder.size, holder.size)
	YxUI:SetFontInfo(button.Count, Settings["unitframes-font"], Settings["unitframes-font-size"], "OUTLINE")
	YxUI:SetFontInfo(button.Time, Settings["unitframes-font"], Settings["unitframes-font-size"], "OUTLINE")

	if Settings["unitframes-display-aura-timers"] then
		button:SetDurationText(button.Time, DurationTextOptions)
	else
		button:ClearDurationText()
	end
end

local function InitializeAuraButton(button, holder)
	button:SetSize(holder.size, holder.size)
	button:EnableMouse(not holder.disableMouse)
	button:SetTooltipAnchorPoint(holder.tooltipAnchor or "ANCHOR_TOP")

	local background = button:CreateTexture(nil, "BACKGROUND")
	background:SetAllPoints()
	background:SetColorTexture(0, 0, 0)

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
	icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
	icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
	button:SetIcon(icon)

	local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	cooldown:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
	cooldown:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
	cooldown.noOCC = true
	cooldown.noCooldownCount = true
	cooldown:SetHideCountdownNumbers(true)
	cooldown:SetDrawSwipe(true)
	cooldown:SetDrawEdge(false)
	cooldown:SetDrawBling(false)
	cooldown:SetReverse(true)
	button:SetDurationCooldown(cooldown)

	local borderOverlay = CreateFrame("Frame", nil, button, "BackdropTemplate")
	borderOverlay:SetAllPoints()
	borderOverlay:SetFrameLevel(cooldown:GetFrameLevel() + 1)
	borderOverlay:SetBackdrop(YxUI.Outline)
	borderOverlay:SetBackdropBorderColor(0, 0, 0)

	local textOverlay = CreateFrame("Frame", nil, button)
	textOverlay:SetAllPoints()
	textOverlay:SetFrameLevel(borderOverlay:GetFrameLevel() + 1)

	local count = textOverlay:CreateFontString(nil, "OVERLAY")
	count:SetPoint("BOTTOMRIGHT", 1, 2)
	count:SetJustifyH("RIGHT")
	YxUI:SetFontInfo(count, Settings["unitframes-font"], Settings["unitframes-font-size"], "OUTLINE")
	button.Count = count
	button:SetApplicationCount(count, {})

	local time = textOverlay:CreateFontString(nil, "OVERLAY")
	time:SetPoint("TOPLEFT", -1, -1)
	time:SetJustifyH("LEFT")
	YxUI:SetFontInfo(time, Settings["unitframes-font"], Settings["unitframes-font-size"], "OUTLINE")
	button.Time = time

	UpdateButtonStyle(button, holder)
end

local function GetFilter(holder, kind)
	if kind == "Debuffs" and holder.onlyShowPlayer then
		return "HARMFUL|PLAYER"
	end
	return kind == "Buffs" and "HELPFUL" or "HARMFUL"
end

local function SyncHolder(holder, unit, kind, event)
	local auraContainer = holder.__foreverAuraContainer
	local filter = GetFilter(holder, kind)
	local filterChanged = false

	if not auraContainer then
		auraContainer = CreateFrame("AuraContainer", nil, holder, "CustomAuraContainerTemplate")
		auraContainer:SetSize(1, 1)
		auraContainer:SetPoint(holder.initialAnchor or "TOPLEFT", holder, holder.initialAnchor or "TOPLEFT")
		auraContainer:SetFlowLayoutAnchorPoint(holder.initialAnchor or "TOPLEFT")
		local growthX = holder["growth-x"] == "LEFT" and -1 or 1
		local growthY = holder["growth-y"] == "UP" and 1 or -1
		auraContainer:SetFlowLayoutGrowthDirection(growthX, growthY)
		auraContainer:SetFlowLayoutMaximumLineSize(holder:GetWidth())
		auraContainer:AddAuraGroup("auras", filter, {
			maxFrameCount = holder.num or 16,
			initializeFrame = function(button) InitializeAuraButton(button, holder) end,
			layout = {elementSpacing = holder.spacing or 0, lineSpacing = holder.spacing or 0},
		})
		holder.__foreverAuraContainer = auraContainer
		holder.__foreverFilter = filter
		holder.__foreverLayout = {width = holder:GetWidth(), size = holder.size, spacing = holder.spacing or 0,
			count = holder.num or 16, anchor = holder.initialAnchor or "TOPLEFT", x = growthX, y = growthY}
		holders[holder] = true
	else
		if holder.__foreverFilter ~= filter then
			auraContainer:SetAuraGroupFilterString("auras", filter)
			holder.__foreverFilter = filter
			filterChanged = true
		end

		local growthX = holder["growth-x"] == "LEFT" and -1 or 1
		local growthY = holder["growth-y"] == "UP" and 1 or -1
		local anchor = holder.initialAnchor or "TOPLEFT"
		local width, size, spacing, count = holder:GetWidth(), holder.size, holder.spacing or 0, holder.num or 16
		local layout = holder.__foreverLayout
		if not layout or layout.width ~= width or layout.size ~= size or layout.spacing ~= spacing
			or layout.count ~= count or layout.anchor ~= anchor or layout.x ~= growthX or layout.y ~= growthY then
			if not InCombatLockdown() then
				auraContainer:SetFlowLayoutAnchorPoint(anchor)
				auraContainer:SetFlowLayoutGrowthDirection(growthX, growthY)
				auraContainer:SetFlowLayoutMaximumLineSize(width)
				auraContainer:SetAuraGroupMaxFrameCount("auras", count)
				auraContainer:SetAuraGroupLayout("auras", {elementSpacing = spacing, lineSpacing = spacing})
				for i = 1, auraContainer:GetAuraGroupFrameCount("auras") do
					local button = auraContainer:GetAuraGroupFrame("auras", i)
					if button then
						UpdateButtonStyle(button, holder)
					end
				end
				holder.__foreverLayout = {width = width, size = size, spacing = spacing,
					count = count, anchor = anchor, x = growthX, y = growthY}
			end
		end
	end

	if holder.__foreverUnit ~= unit then
		auraContainer:SetUnit(unit)
		holder.__foreverUnit = unit
	elseif not filterChanged and (event == "ForceUpdate"
		or (event == "PLAYER_TARGET_CHANGED" and unit == "target")
		or event == "NAME_PLATE_UNIT_ADDED") then
		auraContainer:UpdateAllAuras()
	end
end

function UF:UpdateForeverAuras(frame, event)
	for _, kind in ipairs(AuraKinds) do
		local holder = frame[kind]
		if holder then
			SyncHolder(holder, frame.unit, kind, event)
		end
	end
end

function UF:EnableForeverAuras(frame)
	if not frame.Buffs and not frame.Debuffs then
		return
	end

	for _, kind in ipairs(AuraKinds) do
		local holder = frame[kind]
		if holder then
			holder.__owner = frame
			local auraKind = kind
			holder.ForceUpdate = function()
				SyncHolder(holder, frame.unit, auraKind, "ForceUpdate")
			end
			holder:Show()
		end
	end

	self:UpdateForeverAuras(frame)
	return true
end

function UF:DisableForeverAuras(frame)
	for _, kind in ipairs(AuraKinds) do
		local holder = frame[kind]
		if holder then
			holder:Hide()
		end
	end
end

local OldSetAuraTimersEnabled = UF.SetAuraTimersEnabled
function UF:SetAuraTimersEnabled(enabled)
	OldSetAuraTimersEnabled(self, enabled)
	if InCombatLockdown() then
		return
	end
	for holder in pairs(holders) do
		local auraContainer = holder.__foreverAuraContainer
		if auraContainer then
			for i = 1, auraContainer:GetAuraGroupFrameCount("auras") do
				local button = auraContainer:GetAuraGroupFrame("auras", i)
				if button and not (button.IsForbidden and button:IsForbidden()) then
					if enabled then
						button:SetDurationText(button.Time, DurationTextOptions)
					else
						button:ClearDurationText()
					end
				end
			end
		end
	end
end
