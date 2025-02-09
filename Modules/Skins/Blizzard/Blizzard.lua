local Y, L, A, C, D = YxUIGlobal:get()

D['skin-blizzard-enable'] = true

local Module = Y:NewModule('Blizzard')
Module.frames = {}

function Module:Load()
    if C['skin-blizzard-enable'] then
        for _, widget in ipairs(Module.frames) do
            widget.loader(self, true)
        end
    end
end

function Module:Add(name, loader)
    assert(not self.frames[name], 'The name of the Blizzard Frame is already in use.')
    self.frames[name] = true
    table.insert(self.frames, {
        name = name,
        loader = loader
    })
end

Y:GetModule('GUI'):AddWidgets(L['General'], L['Skins'], function(left, right)
    right:CreateHeader(L['Miscellaneous'])
    right:CreateSwitch('skin-blizzard-enable', C['skin-blizzard-enable'], L['Blizzard Frame Skin'], L['Skin some blizzard frames & objects']):RequiresReload(true)
end)
