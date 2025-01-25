local YxUI, Language, Assets, Settings = select(2, ...):get()

local Quest = YxUI:NewModule("Quest Watch")

function Quest:StyleFrame()
	self:SetSize(204, 204) -- Not sure why, Blizzard did it.
	self:SetPoint("TOPRIGHT", YxUI.UIParent, "TOPRIGHT", -300, -400)

	local Mover = YxUI:CreateMover(self)

	WatchFrame:SetMovable(true)
	WatchFrame:SetUserPlaced(true)
	WatchFrame:SetClampedToScreen(false)
	WatchFrame:ClearAllPoints()
	WatchFrame:SetPoint("TOP", self, "TOP", 0, 0)
	WatchFrame:SetSize(204, 757)

	self.Mover = Mover
end

function Quest:Load()
	self:StyleFrame()
end