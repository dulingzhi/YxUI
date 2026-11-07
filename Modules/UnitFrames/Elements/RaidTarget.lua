local _, ns = ...
local YxUI = ns:get()

local UF = YxUI:GetModule("Unit Frames")

function UF:CreateRaidTargetIndicator(health, size, layer, point, relativePoint, x, y)
	size = size or 16

	local indicator = health:CreateTexture(nil, layer or "OVERLAY")
	indicator:SetSize(size, size)
	indicator:SetPoint(point or "CENTER", health, relativePoint or "TOP", x or 0, y or 0)

	return indicator
end

-- Shared update callbacks operate on existing frames and values so settings changes do not need to allocate per-frame closures or temporary tables.