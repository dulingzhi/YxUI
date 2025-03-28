local YxUI, Language, Assets, Settings = select(2, ...):get()

local BagSearch = YxUI:NewModule("Bag Search")

if (not SetItemSearch) then -- Blizz is adding their bags to all game versions it looks like, this file will be removed soon
	return
end

local SearchOnTextChanged = function(self)
	local Text = self:GetText()

	if Text then
		SetItemSearch(Text)
	end
end

local SearchOnEnterPressed = function(self)
	self:ClearFocus()
	self:SetText("")
end

local SearchOnEditFocusLost = function(self)
	SetItemSearch("")
end

function BagSearch:Load()
	local Search = CreateFrame("EditBox", nil, ContainerFrame1, "InputBoxTemplate")
	Search:SetPoint("TOPRIGHT", ContainerFrame1, -10, -24)
	Search:SetSize(120, 30)
	Search:SetFrameLevel(ContainerFrame1:GetFrameLevel() + 10)
	Search:SetAutoFocus(false)
	Search:SetScript("OnTextChanged", SearchOnTextChanged)
	Search:SetScript("OnEnterPressed", SearchOnEnterPressed)
	Search:SetScript("OnEscapePressed", SearchOnEnterPressed)
	Search:SetScript("OnEditFocusLost", SearchOnEditFocusLost)
end