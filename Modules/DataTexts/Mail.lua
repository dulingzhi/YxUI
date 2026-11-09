local YxUI, Language, Assets, Settings = select(2, ...):get()

local Label = MAIL_LABEL

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	local Senders = {GetLatestThreeSenders()}
	local HasSender
	GameTooltip:AddLine(Label, 1, 0.82, 0)
	GameTooltip:AddLine(" ")

	for Index = 1, 3 do
		local Sender = Senders[Index]

		if Sender and (not issecretvalue or not issecretvalue(Sender)) and Sender ~= "" then
			if not HasSender then
				GameTooltip:AddLine(HAVE_MAIL_FROM, 1, 0.82, 0)
			end

			GameTooltip:AddLine(Sender, 1, 1, 1)
			HasSender = true
		end
	end

	if not HasSender then
		local Pending = HasNewMail()
		if issecretvalue and issecretvalue(Pending) then
			GameTooltip:AddLine("Mail status unavailable", 0.75, 0.75, 0.75)
		elseif Pending then
			GameTooltip:AddLine(HAVE_MAIL, 1, 1, 1)
		else
			GameTooltip:AddLine("No new mail", 0.75, 0.75, 0.75)
		end
	end
	GameTooltip:Show()
end

local OnLeave = function()
	GameTooltip:Hide()
end

local Update = function(self, event)
	local One, Two, Three = GetLatestThreeSenders()
	local Result = 0

	if One then
		Result = Result + 1
	end

	if Two then
		Result = Result + 1
	end

	if Three then
		Result = Result + 1
	end

	if HasNewMail() and Result == 0 then
		Result = Result + 1
	end

	self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%s|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, Result)
end

local OnEnable = function(self)
	self:RegisterEvent("UPDATE_PENDING_MAIL")
	self:SetScript("OnEvent", Update)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)

	self:Update("player")
end

local OnDisable = function(self)
	self:UnregisterEvent("UPDATE_PENDING_MAIL")
	self:SetScript("OnEvent", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)

	self.Text:SetText("")
end

YxUI:AddDataText(Label, OnEnable, OnDisable, Update)
