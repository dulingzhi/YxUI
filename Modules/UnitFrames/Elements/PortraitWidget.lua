local _, ns = ...
local YxUI, _, Assets = ns:get()

local UF = YxUI:GetModule("Unit Frames")

function UF:CreatePortrait(frame, style, width, height, point, relativeTo, relativePoint, x, y, alpha, backgroundTexture, backgroundVisible)
	local variants = frame.PortraitVariants
	if not variants then
		variants = {}
		frame.PortraitVariants = variants
	end

	local key = style == "2D" and "2D" or "MODEL"
	local portrait = variants[key]
	if not portrait then
		if key == "2D" then
			portrait = frame:CreateTexture(nil, "OVERLAY")
			portrait:SetTexCoord(0.12, 0.88, 0.12, 0.88)
		else
			portrait = CreateFrame("PlayerModel", nil, frame)
		end
		variants[key] = portrait
	end

	portrait:ClearAllPoints()
	portrait:SetSize(width, height)
	portrait:SetPoint(point, relativeTo or frame, relativePoint, x or 0, y or 0)
	portrait:SetAlpha(alpha or 1)

	if style ~= "OVERLAY" then
		local background = portrait.BG
		if not background then
			background = frame:CreateTexture(nil, "BACKGROUND")
			background:SetPoint("TOPLEFT", portrait, -1, 1)
			background:SetPoint("BOTTOMRIGHT", portrait, 1, -1)
			background:SetTexture(Assets:GetTexture(backgroundTexture))
			background:SetVertexColor(0, 0, 0)
			portrait.BG = background
		end
		background:SetShown(backgroundVisible ~= false)
	elseif portrait.BG then
		portrait.BG:Hide()
	end

	frame.Portrait = portrait
	return portrait
end

function UF:SetPortraitStyle(frame, style, width, height, point, relativeTo, relativePoint, x, y, alpha, backgroundTexture)
	local enabled = frame._enabledElements and frame._enabledElements.Portrait
	if enabled then
		frame:DisableElement("Portrait")
	end

	local previous = frame.Portrait
	if previous then
		previous:Hide()
		if previous.BG then
			previous.BG:Hide()
		end
	end

	local portrait = self:CreatePortrait(frame, style, width, height, point, relativeTo, relativePoint, x, y, alpha, backgroundTexture, enabled)
	if enabled then
		frame:EnableElement("Portrait")
		if portrait.ForceUpdate then
			portrait:ForceUpdate()
		end
	else
		portrait:Hide()
	end

	return portrait
end
