local Y, L, A, C, D = select(2, ...):get()

local Skin = Y:NewModule("Skin")
local IsAddOnLoaded = IsAddOnLoaded or C_AddOn.IsAddOnLoaded

Skin.Configs = {}

function Skin:Enable()
    self:RegisterEvent("ADDON_LOADED")
    self:SetScript("OnEvent", self.OnEvent)
    for AddOn, setup in pairs(self.Configs) do
        if IsAddOnLoaded(AddOn) and type(setup) == 'function' then
            setup()
            self.Configs[AddOn] = true
        end
    end
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
    if self.Configs[AddOn] and type(self.Configs[AddOn]) == 'function' then
        self.Configs[AddOn]()
        self.Configs[AddOn] = true
    end
end

function Skin:Add(name, func)
    assert(not self.Configs[name], "Skin: %s already exists.")
    self.Configs[name] = func
end
