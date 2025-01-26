local YxUI, Language, Assets, Settings, Defaults = select(2, ...):get()

local Skin = YxUI:NewModule("Skin")

function Skin:Enable()
    self:RegisterEvent("ADDON_LOADED")
    self:SetScript("OnEvent", self.OnEvent)
end

function Skin:Disable()
    self:UnregisterAllEvents()
    self:SetScript("OnEvent", nil)
    self:Hide()
end

function Skin:OnEvent(event)
    if self[event] then
        self[event](self)
    end
end

function Skin:Load()
    self:Enable()
end

function Skin:ADDON_LOADED(AddOn)
    print(AddOn)
end
