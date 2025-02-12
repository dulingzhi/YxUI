local Y, L, A, C, D = YxUIGlobal:get()

local Module = Y:NewModule('Miscellaneous')
Module.widgets = {}

function Module:Load()
    for _, widget in ipairs(Module.widgets) do
        if C[widget.configKey] then
            widget.toggle(self, true)
        end
    end
end

function Module:Add(configKey, default, name, desc, toggle, requireReload)
    assert(not self.widgets[name], L['The name of the widget is already in use.'])
    self.widgets[name] = true
    table.insert(self.widgets, {
        configKey = configKey,
        default = default,
        name = name,
        desc = desc,
        toggle = toggle,
        requireReload = requireReload == true
    })
    D[configKey] = default
end

Y:GetModule('GUI'):AddWidgets(L['General'], L['Miscellaneous'], function(left, right)
    left:CreateHeader(L['Miscellaneous'])
    for _, widget in ipairs(Module.widgets) do
        left:CreateSwitch(widget.configKey, C[widget.configKey], widget.name, widget.desc, function()
            widget.toggle(Module, C[widget.configKey])
        end):RequiresReload(widget.requireReload)
    end
end)
