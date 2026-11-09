local _, ns = ...
local YxUI = ns:get()
local UF = YxUI:GetModule("Unit Frames")

if YxUI.IsMainline then
	local GetAuraDataByIndex = C_UnitAuras.GetAuraDataByIndex
	local IsAuraIndexSecret = C_Secrets and C_Secrets.ShouldUnitAuraIndexBeSecret
	local AreAurasSecret = C_Secrets and C_Secrets.ShouldAurasBeSecret
	local function IsInaccessible(value)
		return issecretvalue and issecretvalue(value) and not (canaccessvalue and canaccessvalue(value))
	end
	-- Retail's aura table API is selected once while files load.  Shared aura layout code therefore never branches on the client for each icon.
	function UF.EnumerateAuras(unit, filter, visitor)
		if AreAurasSecret and AreAurasSecret() then
			return
		end

		for index = 1, 40 do
			if not (IsAuraIndexSecret and IsAuraIndexSecret(unit, index, filter)) then
				local aura = GetAuraDataByIndex(unit, index, filter)
				if IsInaccessible(aura) or not aura then
					break
				end

				if not IsInaccessible(aura.name)
					and not IsInaccessible(aura.icon) and not IsInaccessible(aura.applications)
					and not IsInaccessible(aura.dispelName) and not IsInaccessible(aura.duration)
					and not IsInaccessible(aura.expirationTime) and not IsInaccessible(aura.sourceUnit)
					and not IsInaccessible(aura.isStealable) and not IsInaccessible(aura.spellId) then
					if visitor(index, aura.name, aura.icon, aura.applications, aura.dispelName,
						aura.duration, aura.expirationTime, aura.sourceUnit, aura.isStealable, aura.spellId, aura) == false then
						break
					end
				end
			end
		end
	end
end
