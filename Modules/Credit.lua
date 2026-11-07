local YxUI, Language, Assets, Settings = select(2, ...):get()

local GUI = YxUI:GetModule("GUI")

local Tiers = {"FF8000", "A335EE", "0070DD", "1EFF00", "FFFFFF"}

local Previous = {
	{"SwoopCrown", "Cheeso_76", "Erieeroot", "last", "Dragonhawk", "Halven"},
	{"Smelly", "Trix", "wolimazo", "Ari", "MrPoundsign"},
	{"Euphoria", "Mitooshin", "MisseFar", "FrankPatten", "Dillan", "Quiet", "deck"},
	{"Maski", "Raze", "Ingrimmosch", "Chris B.", "Suppabad", "Aaron B.", "Steve R.", "Angel", "Jeor", "Mcbooze", "stko", "Syn", "Rytok", "Ryex", "Blom", "Innie", "Cyber", "protocol7", "Dellamaik", "JDoubleU00", "sylvester", "thurin"},
	{"Akab00m", "OzzFreak", "madmaddy", "Uzify", "Erthelmi", "silence", "momzzze", "Oxymorphone", "Paul D."},
}

local Donors = [[Innie Brightsides Erthelmi Gene JDoubleU00 Duds Shazlen Shawna W Dillan Bruce N last Wrynn Ryxân Andrei B Anthony M AtticaOnline Hawksworth WingZero
Elizabeth T Quadra Brandon W Richard S Andreas M Morgana N LeeMcMurtry]]

GUI:AddWidgetsID("Info", "Credits", function(left, right)
	left:CreateHeader(Language["Scripting Help & Inspiration"])
	left:CreateMessage("", "Tukz, Foof, Eclipse, nightcracker, Elv, Smelly, Azilroka, AlleyKat, Zork, Simpy, Safturento, Dandruff, Haste, lightspark, p3lim, Rainrider")

	left:CreateHeader("AceSerializer")
	left:CreateLine("", "Nevcairiel")

	right:CreateHeader("LibStub")
	right:CreateMessage("", "Kaelten, Cladhaire, ckknight, Mikk, Ammo, Nevcairiel, joshborke")

	right:CreateHeader("LibSharedMedia")
	right:CreateLine("", "Elkano, funkehdude")

	right:CreateHeader("LibDeflate")
	right:CreateLine("", "yoursafety")

	left:CreateHeader("YxUI")
	left:CreateLine("", "Hydra")
end)

GUI:AddWidgetsID("Info", "Supporters", function(left, right)
	local ExPatrons = ""

	for i = 1, #Previous do
		for n = 1, #Previous[i] do
			ExPatrons = ExPatrons .. "|cFF" .. Tiers[i] .. Previous[i][n] .. "|r "
		end
	end

	left:CreateHeader(Language["Former Patreon Supporters"])
	left:CreateMessage("", ExPatrons)

	right:CreateHeader(Language["Donors"])
	right:CreateMessage("", Donors)

	right:CreateHeader(Language["Thank you so much!"])
	right:CreateMessage("", Language["Thank you to all of these amazing people for their support, through donations and Patreon pledges! This generosity allows me to spend so much of my time developing the interface for everyone."])
end)
