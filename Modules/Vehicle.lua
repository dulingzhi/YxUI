local Y, L, A, C = YxUIGlobal:get()

local Vehicle = Y:NewModule('Vehicle', 'SecureHandlerStateTemplate')

function Vehicle:OnEnter()
    local R, G, B = Y:HexToRGB(C['ui-widget-font-color'])

    GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT', 0, -6)
    GameTooltip:AddLine(TAXI_CANCEL_DESCRIPTION, R, G, B)
    GameTooltip:Show()
end

function Vehicle:OnLeave()
    GameTooltip:Hide()
end

function Vehicle:Load()
    self:SetSize(34, 34)
    self:SetPoint('BOTTOM', Y.UIParent, 320, 100)
    self:CreateBorder()

	self.frameVisibility = "[canexitvehicle]c;[mounted]m;n"
	RegisterStateDriver(self, "exit", self.frameVisibility)

	self:SetAttribute("_onstate-exit", [[ if CanExitVehicle() then self:Show() else self:Hide() end ]])
    if (not CanExitVehicle()) then
        self:SetAlpha(0)
        self:Hide()
    end

	local button = CreateFrame("CheckButton", nil, self, "ActionButtonTemplate, SecureHandlerClickTemplate")
	button:SetAllPoints()
	button:RegisterForClicks("AnyUp")
	button.icon:SetTexture("INTERFACE\\VEHICLES\\UI-Vehicles-Button-Exit-Up")
	button.icon:SetTexCoord(0.216, 0.784, 0.216, 0.784)
	button.icon:SetDrawLayer("ARTWORK")
	button.icon.__lockdown = true

	button:SetScript("OnEnter", self.OnEnter)
	button:SetScript("OnLeave", self.OnLeave)
	button:SetScript("OnClick", function(self)
		if UnitOnTaxi("player") then
			TaxiRequestEarlyLanding()
            Y:print(L['Requested early landing.'])
		else
			VehicleExit()
		end
		self:SetChecked(true)
	end)
	button:SetScript("OnShow", function(self)
		self:SetChecked(false)
	end)

    Y:CreateMover(self)
end
