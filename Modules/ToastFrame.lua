local YxUI, Language, Assets, Settings = select(2, ...):get()

local Toast = YxUI:NewModule("Toast")

local AddToast = function(self)
	if self.Styled then
		return
	end

	YxUI:SetFontInfo(self.TopLine, Settings["tooltips-font"], Settings["tooltips-font-size"], Settings["tooltips-font-flags"])
	YxUI:SetFontInfo(self.MiddleLine, Settings["tooltips-font"], Settings["tooltips-font-size"], Settings["tooltips-font-flags"])
	YxUI:SetFontInfo(self.BottomLine, Settings["tooltips-font"], Settings["tooltips-font-size"], Settings["tooltips-font-flags"])
	YxUI:SetFontInfo(self.DoubleLine, Settings["tooltips-font"], Settings["tooltips-font-size"], Settings["tooltips-font-flags"])

	self.TooltipFrame:Hide()

	self:ClearAllPoints()
	self:SetPoint("BOTTOMLEFT", YxUI:GetModule("Chat"), "TOPLEFT", 0, 3)

	local R, G, B = YxUI:HexToRGB(Settings["ui-window-main-color"])

	self:SetBackdrop(YxUI.BackdropAndBorder)
	self:SetBackdropColor(R, G, B, (Settings["chat-bg-opacity"] / 100))
	self:SetBackdropBorderColor(0, 0, 0)
end

function Toast:Load()
	hooksecurefunc(BNToastFrame, "AddToast", AddToast)
end