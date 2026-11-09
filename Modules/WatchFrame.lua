local YxUI, Language, Assets, Settings = select(2, ...):get()

local Quest = YxUI:NewModule("Quest Watch")

local function SetTrackerFont(FontString)
	if not FontString or FontString:GetObjectType() ~= "FontString" then
		return
	end

	local Current, Size, Flags = FontString:GetFont()
	if not Size then
		return
	end

	local Name = FontString:GetName() or ""
	local Setting = (Name:find("Header") or Name:find("Title") or Size >= 13) and "ui-header-font" or "ui-widget-font"
	local Font = YxUI:GetDisplayFontPath(Settings[Setting])

	if Font and Current ~= Font then
		FontString:SetFont(Font, Size, Flags or "")
	end
end

local function StyleTrackerFonts(Frame, Seen)
	if not Frame or Seen[Frame] then
		return
	end

	Seen[Frame] = true

	for i = 1, select("#", Frame:GetRegions()) do
		SetTrackerFont(select(i, Frame:GetRegions()))
	end

	for i = 1, select("#", Frame:GetChildren()) do
		StyleTrackerFonts(select(i, Frame:GetChildren()), Seen)
	end
end

function Quest:AlignTracker()
	if self.AligningTracker or InCombatLockdown() then
		return
	end

	local Point, Parent, RelativePoint, X, Y = WatchFrame:GetPoint(1)
	if WatchFrame:GetNumPoints() ~= 1 or Point ~= "TOP" or Parent ~= self or RelativePoint ~= "TOP" or X ~= 4 or Y ~= -1 then
		self.AligningTracker = true
		WatchFrame:ClearAllPoints()
		WatchFrame:SetPoint("TOP", self, "TOP", 4, -1)
		self.AligningTracker = nil
	end
end

function Quest:UpdateTracker()
	self:AlignTracker()
	StyleTrackerFonts(WatchFrame, {})
end

function Quest:StyleFrame()
	self:SetSize(253, (Settings["tracker-height"] or 400) + 2)
	self:ClearAllPoints()
	self:SetPoint("RIGHT", YxUIParent, "RIGHT", -260, 0)

	self.Mover = YxUI:CreateMover(self)

	WatchFrame:SetMovable(true)
	WatchFrame:SetUserPlaced(true)
	WatchFrame:SetClampedToScreen(false)
	WatchFrame:SetSize(204, 757)

	self:UpdateTracker()
end

function Quest:Load()
	if not WatchFrame then
		return
	end

	self:StyleFrame()

	-- Blizzard can reanchor WatchFrame outside WatchFrame_Update; restore it in the same call.
	hooksecurefunc(WatchFrame, "SetPoint", function()
		self:AlignTracker()
	end)

	hooksecurefunc("WatchFrame_Update", function()
		self:UpdateTracker()
	end)

	WatchFrame:HookScript("OnShow", function()
		self:UpdateTracker()
	end)

	hooksecurefunc(YxUI, "ApplyProfileMoverPositions", function()
		self:AlignTracker()
	end)

	local Events = CreateFrame("Frame")
	Events:RegisterEvent("PLAYER_REGEN_ENABLED")
	Events:SetScript("OnEvent", function()
		self:AlignTracker()
	end)
end
