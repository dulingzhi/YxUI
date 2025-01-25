local YxUI, Language, Assets, Settings = select(2, ...):get()

local Objectives = YxUI:NewModule("PVP Objectives")

local SetBelowMinimapPosition = function(self, anchor, parent)
	if (parent ~= Objectives.MinimapAnchor) then
		self:ClearAllPoints()
		self:SetParent(Objectives.MinimapAnchor)
		self:SetPoint("CENTER", Objectives.MinimapAnchor)
	end
end

function Objectives:Load()
	self.MinimapAnchor = CreateFrame("Frame", "PVP Objectives", YxUI.UIParent)
	self.MinimapAnchor:SetSize(173, 26)
	self.MinimapAnchor:SetPoint("TOP", YxUI.UIParent, 0, -70)

	hooksecurefunc(UIWidgetBelowMinimapContainerFrame, "SetPoint", SetBelowMinimapPosition)

	YxUI:CreateMover(self.MinimapAnchor)
end