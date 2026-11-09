local YxUI, Language, Assets, Settings = select(2, ...):get()

local GetSpellBonusDamage = GetSpellBonusDamage
local GetSpellBonusHealing = GetSpellBonusHealing
local GetTalentTabInfo = GetTalentTabInfo

local HealingLabel = STAT_SPELLHEALING
local SpellLabel = STAT_SPELLDAMAGE

local GetHighestSpellPower = function()
	local Power = 0

	for i = 2, 7 do
		Power = max(Power, GetSpellBonusDamage(i))
	end

	return Power
end

local GetSpecInfo = function()
    if YxUI.IsMists and GetSpecialization then
        return GetSpecialization()
    end
    if not GetTalentTabInfo then
        return
    end
	local MainSpecID
	local HighestPoints = 0
	local Name, PointsSpent, _

	for i = 1, 3 do
		Name, _, PointsSpent = GetTalentTabInfo(i)

		if Name then
			if PointsSpent > HighestPoints then
				MainSpecID = i
				HighestPoints = PointsSpent
			end
		end
	end

	return MainSpecID
end

local OnMouseUp = function()
	if InCombatLockdown() then
		return
	end

	ToggleCharacter("PaperDollFrame")
end


local OnLeave = function()
	GameTooltip:Hide()
end

local OnEnter = function(self)
	if not self:SetTooltip() then return end

	GameTooltip:AddLine(STAT_SPELLPOWER or STAT_SPELLDAMAGE or "Spell Power", 1, 0.82, 0)
	GameTooltip:AddLine(" ")
	local schools = {HOLY or "Holy", FIRE or "Fire", NATURE or "Nature", FROST or "Frost", SHADOW or "Shadow", ARCANE or "Arcane"}
	for index = 1, #schools do
		local value = GetSpellBonusDamage(index + 1)
		if YxUI.IsDataTextReadable(value) then
			GameTooltip:AddDoubleLine(schools[index], YxUI:Comma(value), 1, 1, 1, 1, 1, 1)
		end
	end
	local healing = GetSpellBonusHealing()
	if YxUI.IsDataTextReadable(healing) then
		GameTooltip:AddDoubleLine(HealingLabel or "Healing", YxUI:Comma(healing), 1, 1, 1, 1, 1, 1)
	end
	GameTooltip:Show()
end

local Update = function(self, event, unit)
	if unit and unit ~= "player" then
		return
	end

	local Rating
	local Label

	local Spell = GetHighestSpellPower()
	local Healing = GetSpellBonusHealing()

	if Spell > 0 or Healing > 0 then
		if (Spell > Healing) or (YxUI.UserClass == "SHAMAN" and GetSpecInfo() ~= 3) then
			Rating = Spell
			Label = SpellLabel
		else
			Rating = Healing
			Label = HealingLabel
		end
	else
		Label = SpellLabel
		Rating = 0
	end

	self.Text:SetFormattedText("|cFF%s%s:|r |cFF%s%s|r", Settings["data-text-label-color"], Label, YxUI.ValueColor, Rating)
end

local OnEnable = function(self)
	self:RegisterEvent("UNIT_STATS")
	self:RegisterEvent("UNIT_AURA")
	self:SetScript("OnEvent", Update)
	self:SetScript("OnMouseUp", OnMouseUp)
	self:SetScript("OnEnter", OnEnter)
	self:SetScript("OnLeave", OnLeave)

	self:Update(nil, "player")
end

local OnDisable = function(self)
	self:UnregisterEvent("UNIT_STATS")
	self:UnregisterEvent("UNIT_AURA")
	self:SetScript("OnEvent", nil)
	self:SetScript("OnMouseUp", nil)
	self:SetScript("OnEnter", nil)
	self:SetScript("OnLeave", nil)

	self.Text:SetText("")
end

YxUI:AddDataText("Spell Power", OnEnable, OnDisable, Update)
