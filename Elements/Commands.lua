local YxUI, Language, Assets, Settings = select(2, ...):get()

local Commands = {}

Commands["move"] = function()
	YxUI:ToggleMovers()
end

Commands["movereset"] = function()
	YxUI:ResetAllMovers()
end

Commands["settings"] = function()
	YxUI:GetModule("GUI"):Toggle()
end

Commands["keybind"] = function()
	YxUI:GetModule("Key Binding"):Toggle()
end

Commands["reset"] = function()
	YxUI:Reset()
end

Commands["texel"] = function()
	IsGMClient = function()
		return true
	end

	if (not IsAddOnLoaded("Blizzard_DebugTools")) then
		LoadAddOn("Blizzard_DebugTools")
	end

	TexelSnappingVisualizer:Show()

	--[[
	local PIXEL_SNAPPING_OPTIONS = {
		{ text = "Default", cvarValue = "-1" },
		{ text = "Override On", cvarValue = "1" },
		{ text = "Override Off", cvarValue = "0" },
	}

	SetCVar("overrideTexelSnappingBias", "1")

	SetCVar("overridePixelGridSnapping", "-1")

	--]]
end

Commands["help"] = function()
	print(format(Language["|cFF%sYxUI|r Commands"], Settings["ui-widget-color"]))
	print(" ")
	print(format("|Hcommand:/yxui|h|cFF%s/yxui|r|h - Toggle the settings window", Settings["ui-widget-color"]))
	print(format("|Hcommand:/yxui move|h|cFF%s/yxui move|r|h - Drag UI elements around the screen", Settings["ui-widget-color"]))
	print(format("|Hcommand:/yxui movereset|h|cFF%s/yxui movereset|r|h - Reposition all movers to their default locations", Settings["ui-widget-color"]))
	print(format("|Hcommand:/yxui keybind|h|cFF%s/yxui keybind|r|h - Toggle mouseover keybinding", Settings["ui-widget-color"]))
	print(format("|Hcommand:/yxui reset|h|cFF%s/yxui reset|r|h - Reset all stored UI information and settings", Settings["ui-widget-color"]))
end

local RunCommand = function(arg)
	if Commands[arg] then
		Commands[arg]()
	else
		Commands.settings()
	end
end

SLASH_YXUI1 = "/yxui"
SlashCmdList["YXUI"] = RunCommand

SLASH_RELOAD1 = "/rl"
SlashCmdList["RELOAD"] = C_UI.Reload

SLASH_GLOBALSTRINGFIND1 = "/gfind"
SlashCmdList["GLOBALSTRINGFIND"] = function(query)
	for Key, Value in next, _G do
		if (Value and type(Value) == "string") then
			if Value:lower():find(query:lower()) then
				print(format("|cFFFFFF00%s|r |cFFFFFFFF= %s|r", Key, Value))
			end
		end
	end
end