local YxUI, Language, Assets, Settings = select(2, ...):get()

local IsReadable = YxUI.IsDataTextReadable

local function IsNumber(value)
    return IsReadable(value) and type(value) == "number"
end

local function IsSafe(value)
    return not (issecretvalue and issecretvalue(value))
end

local function FormatReset(seconds)
    if SecondsToTime then
        return SecondsToTime(math.ceil(seconds), true)
    end
    if seconds >= 86400 then
        return string.format("%dd", math.ceil(seconds / 86400))
    elseif seconds >= 3600 then
        return string.format("%dh", math.ceil(seconds / 3600))
    end
    return string.format("%dm", math.ceil(seconds / 60))
end

local function ReadLockouts()
    if not GetNumSavedInstances or not GetSavedInstanceInfo then
        return
    end
    local size = GetNumSavedInstances()
    if not IsNumber(size) then return end

    local result = {raids = 0, dungeons = 0, bosses = 0, entries = {}}
    for index = 1, math.min(size, 200) do
        local name, _, reset, _, locked, extended, _, isRaid, _, difficultyName, numEncounters, encounterProgress = GetSavedInstanceInfo(index)
        if not (IsSafe(locked) and IsSafe(extended) and IsSafe(isRaid)) then
            return
        end
        if locked or extended then
            if not (IsReadable(name) and type(name) == "string") then return end
            if isRaid then
                result.raids = result.raids + 1
            else
                result.dungeons = result.dungeons + 1
            end
            result.entries[#result.entries + 1] = {
                name = name,
                difficulty = IsReadable(difficultyName) and type(difficultyName) == "string" and difficultyName or nil,
                reset = IsNumber(reset) and reset or nil,
                extended = extended == true,
                total = IsNumber(numEncounters) and numEncounters or nil,
                defeated = IsNumber(encounterProgress) and encounterProgress or nil,
            }
        end
    end

    if GetNumSavedWorldBosses and GetSavedWorldBossInfo then
        local worldBosses = GetNumSavedWorldBosses()
        if not IsNumber(worldBosses) then return end
        for index = 1, math.min(worldBosses, 100) do
            local name, _, reset = GetSavedWorldBossInfo(index)
            if not (IsReadable(name) and type(name) == "string") then return end
            result.bosses = result.bosses + 1
            result.entries[#result.entries + 1] = {
                name = name,
                difficulty = RAID_INFO_WORLD_BOSS or "World Boss",
                reset = IsNumber(reset) and reset or nil,
            }
        end
    end

    result.total = result.raids + result.dungeons + result.bosses
    return result
end

local function GetData(self)
    return YxUI.GetDataTextLastValue(self, ReadLockouts())
end

local function Update(self)
    local data = GetData(self)
    local value = data and tostring(data.total) or "--"
    self.Text:SetFormattedText("|cFF%sLockouts:|r |cFF%s%s|r", Settings["data-text-label-color"], YxUI.ValueColor, value)
end

local function OnEnter(self)
    if not self:SetTooltip() then return end
    local data = GetData(self)
    GameTooltip:AddLine("Saved Instances", 1, 0.82, 0)
    GameTooltip:AddLine(" ")
    if data then
        GameTooltip:AddDoubleLine("Raids", tostring(data.raids), 1, 1, 1, 1, 1, 1)
        GameTooltip:AddDoubleLine("Dungeons", tostring(data.dungeons), 1, 1, 1, 1, 1, 1)
        if data.bosses > 0 then
            GameTooltip:AddDoubleLine("World bosses", tostring(data.bosses), 1, 1, 1, 1, 1, 1)
        end
        if data.total == 0 then
            GameTooltip:AddLine("No active saved instances", 0.7, 0.7, 0.7)
        else
            GameTooltip:AddLine(" ")
            for index, entry in ipairs(data.entries) do
                if index > 24 then
                    GameTooltip:AddLine(string.format("...and %d more", #data.entries - 24), 0.65, 0.65, 0.65)
                    break
                end
                local title = entry.difficulty and string.format("%s (%s)", entry.name, entry.difficulty) or entry.name
                local reset = entry.reset and FormatReset(entry.reset) or ""
                GameTooltip:AddDoubleLine(title, reset, 1, 1, 1, 1, 0.77, 0.3)
                if entry.total and entry.total > 0 and entry.defeated then
                    GameTooltip:AddDoubleLine("  Bosses defeated", string.format("%d/%d", entry.defeated, entry.total), 0.7, 0.7, 0.7, 0.7, 0.7, 0.7)
                end
                if entry.extended then
                    GameTooltip:AddLine("  Extended lockout", 0.7, 0.7, 0.7)
                end
            end
        end
    else
        GameTooltip:AddLine("Saved instance information unavailable", 0.75, 0.75, 0.75)
    end
    GameTooltip:Show()
end

local function OnEvent(self, event)
    if event == "PLAYER_ENTERING_WORLD" and RequestRaidInfo then
        RequestRaidInfo()
    end
    Update(self)
end

local function OnEnable(self)
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("UPDATE_INSTANCE_INFO")
    self:SetScript("OnEvent", OnEvent)
    self:SetScript("OnEnter", OnEnter)
    self:SetScript("OnLeave", function() GameTooltip:Hide() end)
    if RequestRaidInfo then RequestRaidInfo() end
    Update(self)
end

local function OnDisable(self)
    self:UnregisterAllEvents()
    self:SetScript("OnEvent", nil)
    self:SetScript("OnEnter", nil)
    self:SetScript("OnLeave", nil)
    self.Text:SetText("")
end

YxUI:AddDataText("Lockouts", OnEnable, OnDisable, Update)
