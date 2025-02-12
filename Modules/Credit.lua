local YxUI, Language, Assets, Settings = select(2, ...):get()

local GUI = YxUI:GetModule("GUI")

local Tiers = {"FF8000", "A335EE", "0070DD", "1EFF00", "FFFFFF"}

local Patrons = {
	{},
	{},
	{},
	{},
	{},
}

local Donors = [[]]

GUI:AddWidgets(Language["Info"], Language["Credits"], function(left, right)
	left:CreateHeader(Language["Scripting Help & Inspiration"])
	left:CreateMessage("", "Tukz, Foof, Eclipse, nightcracker, Elv, Smelly, Azilroka, AlleyKat, Zork, Simpy, Safturento, Dandruff")

	left:CreateHeader("oUF")
	left:CreateLine("", "haste, lightspark, p3lim, Rainrider")

	left:CreateHeader("AceSerializer")
	left:CreateLine("", "Nevcairiel")

	right:CreateHeader("LibStub")
	right:CreateMessage("", "Kaelten, Cladhaire, ckknight, Mikk, Ammo, Nevcairiel, joshborke")

	right:CreateHeader("LibSharedMedia")
	right:CreateLine("", "Elkano, funkehdude")

	right:CreateHeader("LibDeflate")
	right:CreateLine("", "yoursafety")

	left:CreateHeader("HydraUI")
	left:CreateLine("", "Hydra")

	left:CreateHeader("YxUI")
	left:CreateLine("", "Jai")
end)

GUI:AddWidgets(Language["Info"], Language["Supporters"], function(left, right)
	left:CreateHeader(Language["Patreon Supporters"])

	local List = {}
	local R, G, B = YxUI:HexToRGB(Tiers[1])

	for i = 2, #Patrons do
		for n = 1, #Patrons[i] do
			List[#List + 1] = "|cFF" .. Tiers[i] .. Patrons[i][n] .. "|r"
		end
	end

	for n = 1, #Patrons[1], 2 do
		if Patrons[1][n + 1] then
			left:CreateAnimatedDoubleLine("", "|cFF" .. Tiers[1] .. Patrons[1][n] .. "|r", "|cFF" .. Tiers[1] .. Patrons[1][n + 1] .. "|r", R, G, B)
		else
			local Name = tremove(List, 1)

			left:CreateAnimatedLine("", "|cFF" .. Tiers[1] .. Patrons[1][n] .. "|r", Name, R, G, B)
		end
	end

	for i = 1, #List, 2 do
		if List[i + 1] then
			left:CreateDoubleLine("", List[i], List[i + 1])
		else
			left:CreateLine("", List[i])
		end
	end

	right:CreateHeader(Language["Donors"])
	right:CreateMessage("", Donors)

	right:CreateHeader(Language["Thank you so much!"])
	right:CreateMessage("", Language["Your support is greatly appreciated!"])
end)