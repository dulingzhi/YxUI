-- File written by Smelly, maintained by Hydra

local YxUI, Language, Assets, Settings = select(2, ...):get()
local MinimapButtons = YxUI:NewModule("Minimap Buttons")
local IsMainline = YxUI.IsMainline
local lower, find = string.lower, string.find

MinimapButtons.Items = {}
MinimapButtons.Collected = {}

local IgnoredBlizzard = {
	["BattlefieldMinimap"] = true,
	["ButtonCollectFrame"] = true,
	["FeedbackUIButton"] = true,
	["GameTimeFrame"] = true,
	["HelpOpenTicketButton"] = true,
	["HelpOpenWebTicketButton"] = true,
	["MinimapBackdrop"] = true,
	["MiniMapBattlefieldFrame"] = true,
	["MiniMapLFGFrame"] = true,
	["MiniMapMailFrame"] = true,
	["MiniMapTracking"] = true,
	["MiniMapTrackingFrame"] = true,
	["MiniMapVoiceChatFrame"] = true,
	["MinimapZoneTextButton"] = true,
	["MinimapZoomIn"] = true,
	["MinimapZoomOut"] = true,
	["QueueStatusMinimapButton"] = true,
	["TimeManagerClockButton"] = true,
}

local IgnoredAddOns = {
	"archy",
	"bookoftracksframe",
	"cartographernotespoi",
	"cork",
	"da_minimap",
	"dugisarrowminimappoint",
	"enhancedframeminimapbutton",
	"fishingextravaganzamini",
	"flower",
	"fwgminimappoi",
	"gatherarchnote",
	"gathermatepin",
	"gathernote",
	"gfw_trackmenuframe",
	"gfw_trackmenubutton",
	"gpsarrow",
	"guildmap3mini",
	"guildinstance",
	"handynotespin",
	"librockconfig-1.0_minimapbutton",
	"mininotepoi",
	"nauticusminiicon",
	"poiminimap",
	"premadefilter_minimapbutton",
	"questieframe",
	"questpointerpoi",
	"reciperadarminimapicon",
	"spy_mapnotelist_mini",
	"tdial_trackingicon",
	"tdial_trackButton",
	"tuber",
	"westpointer",
	"zgvmarker",
}

local RemoveByID = {
	[136430] = true,
	[136467] = true,
	[130924] = true,
}

local IsIgnoredAddOn = function(name)
	name = lower(name)

	for i = 1, #IgnoredAddOns do
		if find(name, IgnoredAddOns[i]) then
			return true
		end
	end
end

local RetailIgnored = {
	AddonCompartmentFrame = true,
	GameTimeFrame = true,
	GarrisonLandingPageMinimapButton = true,
	ExpansionLandingPageMinimapButton = true,
	MinimapZoomIn = true,
	MinimapZoomOut = true,
	MiniMapMailFrame = true,
	MiniMapTracking = true,
	MiniMapTrackingFrame = true,
	MiniMapWorldMapButton = true,
	MinimapZoneTextButton = true,
	QueueStatusButton = true,
	QueueStatusMinimapButton = true,
	TimeManagerClockButton = true,
}

local function IsCandidate(Button, registered, strict)
	if not Button or not Button.IsObjectType or not Button:IsObjectType("Button") then
		return false
	end

	if (Button.IsForbidden and Button:IsForbidden()) or (Button.IsProtected and Button:IsProtected()) then
		return false
	end

	local Name = Button:GetName()
	if Name ~= nil and type(Name) ~= "string" then
		return false
	end

	if Name and (RetailIgnored[Name] or Name:find("^Blizzard_")) then
		return false
	end

	if strict and not registered then
		local Lower = Name and Name:lower() or ""
		if not (Lower:find("libdbicon", 1, true) or Lower:find("minimapbutton", 1, true) or Lower:find("minimapicon", 1, true) or Lower:find("_mmb", 1, true)) then
			return false
		end
	end

	local Width, Height = Button:GetSize()
	if type(Width) ~= "number" or type(Height) ~= "number" or Width <= 0 or Height <= 0 or Width > 64 or Height > 64 then
		return false
	end

	return Button:IsShown()
end

local function CreateButtonBackdrop(Button, Key)
	local Backdrop = Button[Key]
	if not Backdrop then
		Backdrop = CreateFrame("Frame", nil, Button, "BackdropTemplate")
		Backdrop:SetAllPoints(Button)
		Backdrop:SetBackdrop(YxUI.Backdrop)
		Backdrop:SetBackdropColor(0, 0, 0)

		local Texture = Backdrop:CreateTexture(nil, "BORDER")
		Texture:SetPoint("TOPLEFT", Backdrop, 1, -1)
		Texture:SetPoint("BOTTOMRIGHT", Backdrop, -1, 1)
		Texture:SetTexture(Assets:GetTexture(Settings["ui-header-texture"]))
		Texture:SetVertexColor(YxUI:HexToRGB(Settings["ui-window-main-color"]))
		Backdrop.Texture = Texture
		Button[Key] = Backdrop
	end
	Backdrop:SetFrameLevel(math.max(0, Button:GetFrameLevel() - 1))
end

local function IsDecoration(Texture)
	local Name = Texture:GetName()
	if type(Name) == "string" then
		Name = lower(Name)
		if Name:match("border$") or Name:match("background$") or Name:match("highlight$")
			or Name:match("overlay$") or Name:match("ring$") or Name:match("mask$") then
			return true
		end
	end

	local Source = Texture:GetTexture()
	if type(Source) == "number" then
		return RemoveByID[Source] or false
	end
	if type(Source) ~= "string" then
		return false
	end
	Source = lower(Source):gsub("/", "\\")
	if find(Source, [[interface\icons\]], 1, true) then
		return false
	end
	local File = Source:match("[^\\]+$") or Source
	return find(File, "border", 1, true) or find(File, "background", 1, true)
		or find(File, "highlight", 1, true) or find(File, "overlay", 1, true)
		or find(File, "ring", 1, true) or find(File, "alphamask", 1, true)
end

local function StyleButton(Button, Panel)
	if not IsMainline then
		if Button:HasScript("OnDragStart") then
			Button:SetScript("OnDragStart", nil)
		end
		if Button:HasScript("OnDragStop") then
			Button:SetScript("OnDragStop", nil)
		end
	end
	if Button.SetFixedFrameStrata then
		Button:SetFixedFrameStrata(false)
	end
	if Button.SetFixedFrameLevel then
		Button:SetFixedFrameLevel(false)
	end
	Button:SetFrameStrata(IsMainline and Panel:GetFrameStrata() or "HIGH")
	Button:SetFrameLevel(Panel:GetFrameLevel() + 2)
	if IsMainline and Button.RegisterForDrag then
		Button:RegisterForDrag()
	end

	local Icon = Button.icon
	if not (Icon and Icon.GetObjectType and Icon:GetObjectType() == "Texture") then
		Icon = Button.Icon
	end
	if not (Icon and Icon.GetObjectType and Icon:GetObjectType() == "Texture" and not IsDecoration(Icon)) then
		Icon = nil
		for _, Region in ipairs({Button:GetRegions()}) do
			if Region and Region.GetObjectType and Region:GetObjectType() == "Texture" and not IsDecoration(Region) then
				local Source = Region:GetTexture()
				local Atlas = Region.GetAtlas and Region:GetAtlas()
				if Source or Atlas then
					Icon = Region
					break
				end
			end
		end
	end
	if not Icon and Button.GetNormalTexture then
		local Normal = Button:GetNormalTexture()
		if Normal and not IsDecoration(Normal) then
			Icon = Normal
		end
	end

	local function HideTexture(Texture)
		if Texture and Texture.Hide then
			Texture:SetAlpha(0)
			Texture:Hide()
		end
	end

	-- Hide common decorative layers used by minimap launchers.
	HideTexture(Button.border)
	HideTexture(Button.background)
	HideTexture(Button.overlay)
	HideTexture(Button.Border)
	HideTexture(Button.Background)
	HideTexture(Button.Overlay)

	if Button.GetNormalTexture then
		for _, Texture in ipairs({Button:GetNormalTexture(), Button:GetPushedTexture(), Button:GetHighlightTexture(), Button:GetDisabledTexture()}) do
			if Texture and Texture ~= Icon and IsDecoration(Texture) then
				HideTexture(Texture)
			end
		end
	end

	for _, Region in ipairs({Button:GetRegions()}) do
		if Region and Region ~= Icon and Region.GetObjectType and Region:GetObjectType() == "Texture" and IsDecoration(Region) then
			HideTexture(Region)
		end
	end

	CreateButtonBackdrop(Button, "YxUIMinimapBackdrop")

	if Icon and Icon.GetObjectType and Icon:GetObjectType() == "Texture" then
		Icon:ClearAllPoints()
		Icon:SetPoint("TOPLEFT", Button, 1, -1)
		Icon:SetPoint("BOTTOMRIGHT", Button, -1, 1)
		Icon:SetDrawLayer("ARTWORK")
		Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		Icon:SetAlpha(1)
		Icon:Show()
	end

	if not IsMainline and Button.SetHighlightTexture and not Button.YxUIHighlight then
		local Highlight = Button:CreateTexture(nil, "ARTWORK")
		Highlight:SetTexture(Assets:GetTexture(Settings["action-bars-button-highlight"]))
		Highlight:SetVertexColor(1, 1, 1, 0.2)
		Highlight:SetPoint("TOPLEFT", Button, 1, -1)
		Highlight:SetPoint("BOTTOMRIGHT", Button, -1, 1)
		Button.YxUIHighlight = Highlight
		Button:SetHighlightTexture(Highlight)
	end
	if not IsMainline and Button.SetPushedTexture and not Button.YxUIPushed then
		local Pushed = Button:CreateTexture(nil, "ARTWORK")
		Pushed:SetTexture(Assets:GetTexture(Settings["action-bars-button-highlight"]))
		Pushed:SetVertexColor(0.9, 0.8, 0.1, 0.3)
		Pushed:SetPoint("TOPLEFT", Button, 1, -1)
		Pushed:SetPoint("BOTTOMRIGHT", Button, -1, 1)
		Button.YxUIPushed = Pushed
		Button:SetPushedTexture(Pushed)
	end
end

function MinimapButtons:AddButton(Button, registered, strict)
	if not Button or self.Collected[Button] then
		return false
	end

	if IsMainline then
		local Ok, Valid = pcall(IsCandidate, Button, registered, strict)
		if not Ok or not Valid then
			return false
		end
	else
		local Name = Button:GetName()
		local Type = Button:GetObjectType()
		local Interactive = Type ~= "Frame" or (Button:IsMouseEnabled() and (Button:HasScript("OnMouseDown") or Button:HasScript("OnMouseUp") or Button:HasScript("OnClick")))
		if not Button:IsShown() or not Interactive or (Name and (IgnoredBlizzard[Name] or IsIgnoredAddOn(Name))) then
			return false
		end
		if strict and not registered and not (Name and (lower(Name):find("libdbicon", 1, true) or lower(Name):find("minimapbutton", 1, true) or lower(Name):find("minimapicon", 1, true) or lower(Name):find("_mmb", 1, true))) then
			return false
		end
	end

	if not pcall(Button.SetParent, Button, self.Panel) then
		return false
	end
	self.Collected[Button] = true
	self.Items[#self.Items + 1] = Button
	StyleButton(Button, self.Panel)
	return true
end

local function ScanButtons(self, Parent, strict)
	if not Parent then
		return
	end
	for _, Button in ipairs({Parent:GetChildren()}) do
		self:AddButton(Button, false, strict)
	end
end

function MinimapButtons:Discover()
	local Lib = LibStub and LibStub("LibDBIcon-1.0", true)
	if Lib and type(Lib.objects) == "table" then
		for _, Button in pairs(Lib.objects) do
			self:AddButton(Button, true, false)
		end
	end

	ScanButtons(self, Minimap, false)
	ScanButtons(self, MinimapCluster, true)
end

function MinimapButtons:PositionButtons()
	if not self.Panel then
		return
	end

	local Size = Settings["minimap-buttons-size"] or 22
	local Spacing = Settings["minimap-buttons-spacing"] or 2
	local PerRow = math.max(1, Settings["minimap-buttons-perrow"] or 5)
	local Visible = {}

	for i = 1, #self.Items do
		local Button = self.Items[i]
		if Button:IsShown() then
			Visible[#Visible + 1] = Button
		end
	end

	local Count = #Visible
	self.LayoutVisible = Visible
	self.LayoutSize = Size
	self.LayoutSpacing = Spacing
	self.LayoutPerRow = PerRow
	if Count == 0 then
		self.Panel:Hide()
		return
	end

	local Columns = math.min(Count, PerRow)
	local Rows = math.ceil(Count / PerRow)
	self.Panel:SetSize(Columns * Size + (Columns - 1) * Spacing + 6, Rows * Size + (Rows - 1) * Spacing + 6)

	for i = 1, Count do
		local Button = Visible[i]
		if Button:GetParent() ~= self.Panel then
			Button:SetParent(self.Panel)
			StyleButton(Button, self.Panel)
		end
		Button:ClearAllPoints()
		Button:SetSize(Size, Size)
		local Column = (i - 1) % PerRow
		local Row = math.floor((i - 1) / PerRow)
		Button:SetPoint("TOPLEFT", self.Panel, "TOPLEFT", 3 + Column * (Size + Spacing), -3 - Row * (Size + Spacing))
	end

	self.Panel:Show()
end

-- Only refresh the layout when a button changes or moves.
local function IsAtPoint(Button, Panel, X, Y)
	local Point, Relative, RelativePoint, OffsetX, OffsetY = Button:GetPoint(1)
	return Point == "TOPLEFT" and Relative == Panel and RelativePoint == "TOPLEFT"
		and math.abs(OffsetX - X) < 0.05 and math.abs(OffsetY - Y) < 0.05
end

local function HasMoved(Button, Panel, Index, PerRow, Size, Spacing)
	local Column = (Index - 1) % PerRow
	local Row = math.floor((Index - 1) / PerRow)
	local X = 3 + Column * (Size + Spacing)
	local Y = -3 - Row * (Size + Spacing)
	local Ok, Matches = pcall(IsAtPoint, Button, Panel, X, Y)
	return not Ok or not Matches
end

function MinimapButtons:NeedsLayout()
	local Visible = self.LayoutVisible
	if not Visible then return true end

	local Size = Settings["minimap-buttons-size"] or 22
	local Spacing = Settings["minimap-buttons-spacing"] or 2
	local PerRow = math.max(1, Settings["minimap-buttons-perrow"] or 5)
	if Size ~= self.LayoutSize or Spacing ~= self.LayoutSpacing or PerRow ~= self.LayoutPerRow then
		return true
	end

	local Count = 0
	for i = 1, #self.Items do
		local Button = self.Items[i]
		if Button:IsShown() then
			Count = Count + 1
			if Button ~= Visible[Count] or Button:GetParent() ~= self.Panel or Button:GetWidth() ~= Size or Button:GetHeight() ~= Size
				or HasMoved(Button, self.Panel, Count, PerRow, Size, Spacing) then
				return true
			end
		end
	end
	if Count ~= #Visible then return true end
	if Count == 0 then return self.Panel:IsShown() end
	if not self.Panel:IsShown() then return true end

	local Columns = math.min(Count, PerRow)
	local Rows = math.ceil(Count / PerRow)
	return self.Panel:GetWidth() ~= Columns * Size + (Columns - 1) * Spacing + 6
		or self.Panel:GetHeight() ~= Rows * Size + (Rows - 1) * Spacing + 6
end

function MinimapButtons:CreatePanel()
	local Name = "YxUIMinimapButtonBar"
	local PreviousName = IsMainline and "YxUIMainlineMinimapButtonBar" or "YxUIClassicMinimapButtonBar"
	for _, Profile in pairs(YxUI.Profiles or {}) do
		if type(Profile) == "table" and type(Profile.Move) == "table" then
			local Move = Profile.Move
			Move[Name] = Move[Name] or Move[PreviousName] or Move["YxUI Minimap Buttons"]
			Move[PreviousName] = nil
			Move["YxUI Minimap Buttons"] = nil
		end
	end

	local Panel = CreateFrame("Frame", Name, YxUI.UIParent, "BackdropTemplate")
	Panel:SetBackdrop(YxUI.BackdropAndBorder)
	Panel:SetBackdropColor(YxUI:HexToRGB(Settings["ui-window-bg-color"]))
	Panel:SetBackdropBorderColor(0, 0, 0)
	Panel:SetFrameStrata(IsMainline and "HIGH" or "MEDIUM")
	Panel:SetFrameLevel(IsMainline and 30 or 10)
	Panel:SetSize(12, 12)

	if IsMainline then
		local Map = YxUI:GetModule("Minimap")
		local Height = Map and Map:GetHeight() or 0
		if Height <= 0 then
			Height = Settings["minimap-size"] + 52
		end
		Panel:SetPoint("TOPRIGHT", YxUI.UIParent, "TOPRIGHT", -12, -18 - Height)
	else
		Panel:SetPoint("TOPRIGHT", YxUI:GetModule("Minimap"), "BOTTOMRIGHT", 0, -2)
	end
	Panel:Hide()
	self.Panel = Panel

	local Mover = YxUI:CreateMover(Panel)
	if Mover then
		Mover.Label:SetText(Language["Minimap Buttons"])
	end
end

function MinimapButtons:CheckPanelPosition()
	local Panel = self.Panel
	if not Panel or not Panel.Mover or not Panel:IsShown() then
		return
	end

	local Left, Right, Top, Bottom = Panel:GetLeft(), Panel:GetRight(), Panel:GetTop(), Panel:GetBottom()
	local Screen = YxUI.UIParent
	local ScreenLeft, ScreenRight = Screen:GetLeft(), Screen:GetRight()
	local ScreenTop, ScreenBottom = Screen:GetTop(), Screen:GetBottom()
	local Invalid = not (Left and Right and Top and Bottom)

	if not Invalid and ScreenLeft and ScreenRight and ScreenTop and ScreenBottom then
		Invalid = Right < ScreenLeft or Left > ScreenRight or Top < ScreenBottom or Bottom > ScreenTop
	end

	if Invalid then
		local Map = YxUI:GetModule("Minimap")
		Panel.Mover:ClearAllPoints()
		Panel.Mover:SetPoint("TOPRIGHT", Screen, "TOPRIGHT", -12, -14 - (Map:GetHeight() or Settings["minimap-size"] + 8))

		local Profile = YxUI:GetActiveProfile()
		if Profile.Move then
			Profile.Move[Panel:GetName()] = nil
		end
	end
end

function MinimapButtons:Hide()
	if self.Panel then
		self.Panel:Hide()
	end
end

function MinimapButtons:RefreshButtons()
	if not self.Panel or InCombatLockdown() then
		if self.ScanEvents and InCombatLockdown() then
			self.ScanEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
		end
		return
	end

	self.ScanEvents:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:Discover()

	if self:NeedsLayout() then
		self:PositionButtons()
	end
	if not IsMainline and #self.Items > 0 then
		C_Timer.After(0.2, function() self:CheckPanelPosition() end)
	end
end

function MinimapButtons:ScheduleRefresh(delay)
	if self.PendingScan then
		return
	end

	self.PendingScan = true
	C_Timer.After(delay or 0.5, function()
		self.PendingScan = false
		self:RefreshButtons()
	end)
end

function MinimapButtons:Load()
	if not Settings["minimap-buttons-enable"] or self.ScanEvents then
		return
	end

	self:CreatePanel()
	self.ScanEvents = CreateFrame("Frame")
	self.ScanEvents:RegisterEvent("ADDON_LOADED")
	if IsMainline then
		self.ScanEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
	end
	self.ScanEvents:SetScript("OnEvent", function(_, Event)
		if Event == "PLAYER_REGEN_ENABLED" then
			self:RefreshButtons()
		else
			self:ScheduleRefresh()
		end
	end)

	C_Timer.NewTicker(5, function() self:RefreshButtons() end)
	if not IsMainline then
		Minimap:HookScript("OnShow", function() self:ScheduleRefresh() end)
	end
	self:ScheduleRefresh(IsMainline and 0.5 or 2)
end

local function UpdateBar()
	MinimapButtons:PositionButtons()
end

YxUI:GetModule("GUI"):AddWidgetsID("General", "Minimap", function(left, right)
	right:CreateHeader(Language["Minimap Buttons"])
	right:CreateSwitch("minimap-buttons-enable", Settings["minimap-buttons-enable"], Language["Enable Minimap Button Bar"], "", ReloadUI):RequiresReload(true)
	right:CreateSlider("minimap-buttons-size", Settings["minimap-buttons-size"], 16, 44, 1, Language["Button Size"], "", UpdateBar)
	right:CreateSlider("minimap-buttons-spacing", Settings["minimap-buttons-spacing"], 1, 5, 1, Language["Button Spacing"], "", UpdateBar)
	right:CreateSlider("minimap-buttons-perrow", Settings["minimap-buttons-perrow"], 1, 20, 1, Language["Buttons Per Row"], Language["Set the number of buttons per row"], UpdateBar)
end)
YxUI:GetModule("GUI"):RegisterPageSettingsID("General", "Minimap", {
	{"minimap-buttons-size", UpdateBar},
	{"minimap-buttons-spacing", UpdateBar},
	{"minimap-buttons-perrow", UpdateBar},
}, nil)


YxUI:GetModule("GUI"):RegisterReloadSettings({"minimap-buttons-enable"})
