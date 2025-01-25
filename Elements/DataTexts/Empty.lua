local YxUI = select(2, ...):get()

local Update = function()

end

local OnEnable = function(self)
	self.Text:SetText("")
end

local OnDisable = function()

end

YxUI:AddDataText("Empty", OnEnable, OnDisable, Update)