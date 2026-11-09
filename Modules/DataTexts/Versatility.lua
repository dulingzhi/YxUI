local YxUI, Language, Assets, Settings = select(2, ...):get()

local CR_VERSATILITY_DAMAGE_DONE = CR_VERSATILITY_DAMAGE_DONE
local GetCombatRating = GetCombatRating
local Label = STAT_VERSATILITY
local IsReadable = YxUI.IsDataTextReadable

local GetBonus = function(rating)
	local RatingBonus = GetCombatRatingBonus(rating)
	local ExtraBonus = GetVersatilityBonus(rating)
	if IsReadable(RatingBonus) and IsReadable(ExtraBonus) then
		return RatingBonus + ExtraBonus
	end
end

local OnMouseUp = function()
	if InCombatLockdown() then
		return
	end

	ToggleCharacter("PaperDollFrame")
end

local OnEnter = function(self)
	if not self:SetTooltip() then
		return
	end

	local Versatility = GetCombatRating(CR_VERSATILITY_DAMAGE_DONE)
	local DamageBonus = GetBonus(CR_VERSATILITY_DAMAGE_DONE)
	local DamageReduction = GetBonus(CR_VERSATILITY_DAMAGE_TAKEN)

	GameTooltip:AddLine(Label, 1, 0.82, 0)
	if IsReadable(Versatility) and DamageBonus and DamageReduction then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(format(CR_VERSATILITY_TOOLTIP, DamageBonus, DamageReduction, YxUI:Comma(Versatility), DamageBonus, DamageReduction), 0.75, 0.75, 0.75, true)
	end

	GameTooltip:Show()
end

local OnLeave = function()
	GameTooltip:Hide()
end

local Update = function(self, event, unit)
	if unit and unit ~= "player" then
		return
	end

	local DamageBonus = YxUI.GetDataTextLastValue(self, GetBonus(CR_VERSATILITY_DAMAGE_DONE))
	if DamageBonus then
		self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%.02f%%|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, DamageBonus)
	else
		self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s--|r", Settings["data-text-label-color"], Label, YxUI.ValueColor)
	end
end

local OnEnable = function(self)
	self:RegisterUnitEvent("UNIT_STATS", "player")
	if YxUI.IsMainline then
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
	end
	self:SetScript("OnEvent", Update)
	self:SetScript("OnMouseUp", OnMouseUp)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)

	self:Update(nil, "player")
end

local OnDisable = function(self)
	self:UnregisterEvent("UNIT_STATS")
	if YxUI.IsMainline then
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end
	self:SetScript("OnEvent", nil)
	self:SetScript("OnMouseUp", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)

	self.Text:SetText("")
end

YxUI:AddDataText("Versatility", OnEnable, OnDisable, Update)
