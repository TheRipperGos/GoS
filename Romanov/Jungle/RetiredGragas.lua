--[[    Romanov
        gggggggggg    ggggggggg       ggggggggggg     gggggggggg     ggggggggggg    gggggggggg
      gg              gg      gg     gg         gg  gg              gg         gg  gg        gg
      gg              gg       gg    gg         gg  gg              gg         gg  gg
      gg              gg      gg     gg         gg  gg              gg         gg  gg
      gg     ggggggg  ggggggggg      ggggggggggggg  gg     ggggggg  ggggggggggggg   ggggggggggg
      gg          gg  gg      gg     gg         gg  gg          gg  gg         gg             gg
      gg          gg  gg       gg    gg         gg  gg          gg  gg         gg             gg
      gg          gg  gg        gg   gg         gg  gg          gg  gg         gg  gg         gg
        gggggggggg    gg         gg  gg         gg    gggggggggg    gg         gg   ggggggggggg
--]]
------------------------------------------------------------------------------------------------------------------------------------------
if myHero.charName ~= "Gragas" then return end
------------------------------------------------------------------------------------------------------------------------------------------
local Author,Version,Patch = "Romanov","Alpha v1","RIOT: 7.12"
------------------------------------------------------------------------------------------------------------------------------------------
require "MapPosition"
require "DamageLib"
require "Eternal Prediction"
------------------------------------------------------------------------------------------------------------------------------------------
local Q = {Range = 850, Delay = 0.25, Width = 110, Radius = 250, Speed = 1000}
local E = {Range = 600, Delay = 0.25, Width = 50, Speed = 900}
local R = {Range = 1000, Delay = 0.25, Width = 120, Radius = 400, Speed = 200}
------------------------------------------------------------------------------------------------------------------------------------------
local QtoPred = Prediction:SetSpell(Q, TYPE_CIRCULAR, true)
local EtoPred = Prediction:SetSpell(E, TYPE_LINE, true)
local RtoPred = Prediction:SetSpell(R, TYPE_CIRCULAR, true)
------------------------------------------------------------------------------------------------------------------------------------------
local function TargetSearch(range)
	local target = nil
	if _G.EOWLoaded then
		target = EOW:GetTarget(range)
	elseif _G.SDK and _G.SDK.Orbwalker then
		target = _G.SDK.TargetSelector:GetTarget(range)
	else
		target = GOS:GetTarget(range)
	end
	return target
end
------------------------------------------------------------------------------------------------------------------------------------------
local function CurrentMode()
	if _G.EOWLoaded then
		if EOW.CurrentMode == 1 then
			return "Combo"
		elseif EOW.CurrentMode == 2 then
			return "Harass"
		elseif EOW.CurrentMode == 4 then
			return "Clear"
		end
	elseif _G.SDK and _G.SDK.Orbwalker then
		if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
			return "Combo"
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then
			return "Harass"	
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR] or _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR] then
			return "Clear"
		end
	else
		return GOS.GetMode()
	end
end
------------------------------------------------------------------------------------------------------------------------------------------
function Ready(slot)
	return Game.CanUseSpell(slot) == 0
end
------------------------------------------------------------------------------------------------------------------------------------------
function Valid(obj,range)
	range = range and range or math.huge
	return obj ~= nil and obj.valid and obj.visible and not obj.dead and obj.isTargetable and obj.distance <= range
end
------------------------------------------------------------------------------------------------------------------------------------------
function MP100(obj)
    return 100 * obj.mana / obj.maxMana
end
------------------------------------------------------------------------------------------------------------------------------------------
function HP100(obj)
    return 100 * obj.health / obj.maxHealth
end
------------------------------------------------------------------------------------------------------------------------------------------
local HKITEM = {
	[ITEM_1] = HK_ITEM_1,
	[ITEM_2] = HK_ITEM_2,
	[ITEM_3] = HK_ITEM_3,
	[ITEM_4] = HK_ITEM_4,
	[ITEM_5] = HK_ITEM_5,
	[ITEM_6] = HK_ITEM_6,
	[ITEM_7] = HK_ITEM_7,
}
------------------------------------------------------------------------------------------------------------------------------------------
function GetDistanceSqr(Pos1, Pos2)
    local Pos2 = Pos2 or myHero.pos
    local dx = Pos1.x - Pos2.x
    local dz = (Pos1.z or Pos1.y) - (Pos2.z or Pos2.y)
    return dx^2 + dz^2
end
------------------------------------------------------------------------------------------------------------------------------------------
function GetDistance(Pos1, Pos2)
    return math.sqrt(GetDistanceSqr(Pos1, Pos2))
end
------------------------------------------------------------------------------------------------------------------------------------------
function MinionsAround(pos, range, team)
	local Count = 0
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if minion and minion.team == team and not minion.dead and GetDistance(pos, minion.pos) <= range then
			Count = Count + 1
		end
	end
	return Count
end
------------------------------------------------------------------------------------------------------------------------------------------
function BestCircFarm(range, radius, team)
	local BestPos = nil
	local MostHit = 0
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if minion and minion.isEnemy and not minion.dead and GetDistance(minion.pos, myHero.pos) <= range then
			local Count = MinionsAround(minion.pos, radius, team)
			if Count > MostHit then
				MostHit = Count
				BestPos = minion.pos
			end
		end
	end
	return BestPos, MostHit
end
------------------------------------------------------------------------------------------------------------------------------------------
local function Qdmg(unit)
    local level = myHero:GetSpellData(_Q).level
	if Ready(_Q) then
    	return CalcMagicalDamage(myHero, unit, (40 + 40 * level + 0.6 * myHero.ap))
	end
	return 0
end
------------------------------------------------------------------------------------------------------------------------------------------
local function Wdmg(unit)
    local level = myHero:GetSpellData(_W).level
    if Ready(_W) then
		return CalcMagicalDamage(myHero, unit, (-10 + 30 * level + 0.08 * unit.maxHealth + 0.3 * myHero.ap))
	end
	return 0
end
------------------------------------------------------------------------------------------------------------------------------------------
local function Edmg(unit)
    local level = myHero:GetSpellData(_E).level
	if Ready(_E) then
    	return CalcMagicalDamage(myHero, unit, (30 + 50 * level + 0.6 * myHero.ap))
	end
	return 0
end
------------------------------------------------------------------------------------------------------------------------------------------
local function Rdmg(unit)
    local level = myHero:GetSpellData(_R).level
	if Ready(_R) then
    	return CalcMagicalDamage(myHero, unit, (100 + 100 * level + 0.7 * myHero.ap))
	end
	return 0
end
------------------------------------------------------------------------------------------------------------------------------------------
local function Idmg(unit)
	if (myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and Ready(SUMMONER_1))
	or (myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_2)) then
		return 50 + 20 * myHero.levelData.lvl
	end
	return 0
end
------------------------------------------------------------------------------------------------------------------------------------------
local function BSdmg(unit)
	if (myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmiteDuel" and Ready(SUMMONER_1))
	or (myHero:GetSpellData(SUMMONER_2).name == "S5_SummonerSmiteDuel" and Ready(SUMMONER_2)) then
		return 20 + 8 * myHero.levelData.lvl
	end
	return 0
end
------------------------------------------------------------------------------------------------------------------------------------------
local function RSdmg(unit)
	if (myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmitePlayerGanker" and Ready(SUMMONER_1))
	or (myHero:GetSpellData(SUMMONER_2).name == "S5_SummonerSmitePlayerGanker" and Ready(SUMMONER_2)) then
		return 54 + 6 * myHero.levelData.lvl
	end
	return 0
end
------------------------------------------------------------------------------------------------------------------------------------------
local function NoPotion()
	for i = 0, 63 do 
	local buff = myHero:GetBuff(i)
		if buff.type == 13 and Game.Timer() < buff.expireTime then 
			return false
		end
	end
	return true
end
------------------------------------------------------------------------------------------------------------------------------------------
LastFlash = Game.Timer()
------------------------------------------------------------------------------------------------------------------------------------------
--- Create Menu
local Gragas = MenuElement({type = MENU, id = "Gragas", name = "Retired Gragas", leftIcon = "https://raw.githubusercontent.com/ParadOx999/GamingOnSteroids-EXT/master/Gragas/Gragas.png"})
------------------------------------------------------------------------------------------------------------------------------------------
--- Main Menu
Gragas:MenuElement({type = MENU, id = "Q", name = "Q: Barrel Roll", leftIcon = "https://raw.githubusercontent.com/ParadOx999/GamingOnSteroids-EXT/master/Gragas/Spells/Q.png"})
Gragas:MenuElement({type = MENU, id = "W", name = "W: Drunken Rage", leftIcon = "https://raw.githubusercontent.com/ParadOx999/GamingOnSteroids-EXT/master/Gragas/Spells/W.png"})
Gragas:MenuElement({type = MENU, id = "E", name = "E: Body Slam", leftIcon = "https://raw.githubusercontent.com/ParadOx999/GamingOnSteroids-EXT/master/Gragas/Spells/E.png"})
Gragas:MenuElement({type = MENU, id = "R", name = "R: Explosive Cask", leftIcon = "https://raw.githubusercontent.com/ParadOx999/GamingOnSteroids-EXT/master/Gragas/Spells/R.png"})
Gragas:MenuElement({type = MENU, id = "M", name = "General Settings", leftIcon = "https://raw.githubusercontent.com/ParadOx999/GamingOnSteroids-EXT/master/General/Items/Mana.png"})
Gragas:MenuElement({type = MENU, id = "A", name = "Activator Settings", leftIcon = "https://raw.githubusercontent.com/ParadOx999/GamingOnSteroids-EXT/master/General/Items/Control.png"})
Gragas:MenuElement({id = "Author", name = "Author", drop = {Author}})
Gragas:MenuElement({id = "Version", name = "Version", drop = {Version}})
Gragas:MenuElement({id = "Patch", name = "Patch", drop = {Patch}})
------------------------------------------------------------------------------------------------------------------------------------------
--- Q
Gragas.Q:MenuElement({id = "Enable", name = "Enable", value = true})
Gragas.Q:MenuElement({id = "Combo", name = "Use in Combo", value = true})
Gragas.Q:MenuElement({id = "Lane", name = "Use in Laneclear", value = true})
Gragas.Q:MenuElement({id = "LMin", name = "X Minions (lane)", value = 5, min = 1, max = 7})
Gragas.Q:MenuElement({id = "Jungle", name ="Use in Jungleclear", value = true})
Gragas.Q:MenuElement({id = "JMin", name = "X Minons (jungle)", value = 1, min = 1, max = 5})
Gragas.Q:MenuElement({id = "Harass", name = "Use in Harass", value = true})
Gragas.Q:MenuElement({id = "KS", name = "Use to Killsteal", value = true})
Gragas.Q:MenuElement({id = "Draw", name = "Draw Range", value = true})
------------------------------------------------------------------------------------------------------------------------------------------
--- W
Gragas.W:MenuElement({id = "Enable", name = "Enable", value = true})
Gragas.W:MenuElement({id = "Combo", name = "Use in Combo", value = true})
Gragas.W:MenuElement({id = "Lane", name = "Use in Lancelar", value = true})
Gragas.W:MenuElement({id = "LMin", name = "X Minions (lane)", value = 3, min = 1, max = 7})
Gragas.W:MenuElement({id = "Jungle", name ="Use in Jungleclear", value = true})
Gragas.W:MenuElement({id = "JMin", name = "X Minons (jungle)", value = 1, min = 1, max = 5})
Gragas.W:MenuElement({id = "Harass", name = "Use in Harass", value = false})
------------------------------------------------------------------------------------------------------------------------------------------
--- E
Gragas.E:MenuElement({id = "Enable", name = "Enable", value = true})
Gragas.E:MenuElement({id = "Combo", name = "Use in Combo", value = true})
Gragas.E:MenuElement({id = "Lane", name = "Use in Laneclear", value = false})
Gragas.E:MenuElement({id = "Jungle", name ="Use in Jungleclear", value = true})
Gragas.E:MenuElement({id = "Harass", name = "Use in Harass", value = false})
Gragas.E:MenuElement({id = "KS", name = "Use to Killsteal", value = true})
Gragas.E:MenuElement({id = "Wall", name = "E Walljump", key = string.byte("Z")})
DelayAction(function()
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerFlash"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerFlash" then
		Gragas.E:MenuElement({id = "Flash", name = "E + Flash", key = string.byte("A")})
	end
end, 2)
Gragas.E:MenuElement({id = "Draw", name = "Draw Range", value = true})
------------------------------------------------------------------------------------------------------------------------------------------
--- R
Gragas.R:MenuElement({id = "Enable", name = "Enable", value = true})
Gragas.R:MenuElement({id = "Combo", name = "Use in Combo", value = true})
Gragas.R:MenuElement({id = "Info", name = "Note: Only if Combo Killable", type = SPACE})
Gragas.R:MenuElement({id = "KS", name = "Use to Killsteal", value = true})
Gragas.R:MenuElement({id = "Insec", name = "Insec", key = string.byte("S")})
Gragas.R:MenuElement({id = "Draw", name = "Draw Range", value = false})
Gragas.R:MenuElement({id = "DrawI", name = "Draw Insec Range", value = true})
------------------------------------------------------------------------------------------------------------------------------------------
--- General
Gragas.M:MenuElement({id = "Combo", name = "Mana % to Combo", value = 0, min = 0, max = 100})
Gragas.M:MenuElement({id = "Lane", name = "Mana % to Laneclear", value = 45, min = 0, max = 100})
Gragas.M:MenuElement({id = "Jungle", name = "Mana % to Jungleclear", value = 25, min = 0, max = 100})
Gragas.M:MenuElement({id = "Harass", name = "Mana % to Harass", value = 60, min = 0, max = 100})
Gragas.M:MenuElement({id = "KS", name = "Mana % to Killsteal", value = 0, min = 0, max = 100})
Gragas.M:MenuElement({id = "Misc", name = "Mana % to Misc (?)", value = 0, min = 0, max = 100, tooltip = "Insec/Walljump/Flash + E"})
Gragas.M:MenuElement({id = "Dmg", name = "Draw Damage over HP bar", value = true})
------------------------------------------------------------------------------------------------------------------------------------------
--- Activator
Gragas.A:MenuElement({type = MENU, id = "P", name = "Potions"})
Gragas.A.P:MenuElement({id = "Pot", name = "All Potions", value = true})
Gragas.A.P:MenuElement({id = "HP", name = "Health % to Potion", value = 60, min = 0, max = 100})
Gragas.A:MenuElement({type = MENU, id = "I", name = "Items"})
Gragas.A.I:MenuElement({id = "RO", name = "Randuin's Omen", value = true})
Gragas.A.I:MenuElement({id = "Proto", name = "Hextec Protobelt-01", value = true})
Gragas.A:MenuElement({type = MENU, id = "S", name = "Summoner Spells"})
DelayAction(function()
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerSmite" or myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmitePlayerGanker" or myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmiteDuel"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerSmite" or myHero:GetSpellData(SUMMONER_2).name == "S5_SummonerSmitePlayerGanker" or myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmiteDuel" then
		Gragas.A.S:MenuElement({id = "Smite", name = "Smite in Combo [?]", value = true, tooltip = "If Combo will kill"})
		Gragas.A.S:MenuElement({id = "SmiteS", name = "Smite Stacks to Combo", value = 1, min = 1, max = 2})
	end
end, 2)
DelayAction(function()
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerHeal"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerHeal" then
		Gragas.A.S:MenuElement({id = "Heal", name = "Auto Heal", value = true})
		Gragas.A.S:MenuElement({id = "HealHP", name = "Health % to Heal", value = 25, min = 0, max = 100})
	end
end, 2)
DelayAction(function()
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerBarrier"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerBarrier" then
		Gragas.A.S:MenuElement({id = "Barrier", name = "Auto Barrier", value = true})
		Gragas.A.S:MenuElement({id = "BarrierHP", name = "Health % to Barrier", value = 25, min = 0, max = 100})
	end
end, 2)
DelayAction(function()
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" then
		Gragas.A.S:MenuElement({id = "Ignite", name = "Ignite in Combo", value = true})
	end
end, 2)
DelayAction(function()
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerExhaust"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerExhaust" then
		Gragas.A.S:MenuElement({id = "Exh", name = "Exhaust in Combo [?]", value = true, tooltip = "If Combo will kill"})
	end
end, 2)
DelayAction(function()
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerBoost"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerBoost" then
		Gragas.A.S:MenuElement({id = "Cleanse", name = "Auto Cleanse", value = true})
		Gragas.A.S:MenuElement({id = "Blind", name = "Blind", value = false})
		Gragas.A.S:MenuElement({id = "Charm", name = "Charm", value = true})
		Gragas.A.S:MenuElement({id = "Flee", name = "Flee", value = true})
		Gragas.A.S:MenuElement({id = "Slow", name = "Slow", value = false})
		Gragas.A.S:MenuElement({id = "Root", name = "Root/Snare", value = true})
		Gragas.A.S:MenuElement({id = "Poly", name = "Polymorph", value = true})
		Gragas.A.S:MenuElement({id = "Silence", name = "Silence", value = true})
		Gragas.A.S:MenuElement({id = "Stun", name = "Stun", value = true})
		Gragas.A.S:MenuElement({id = "Taunt", name = "Taunt", value = true})
	end
end, 2)
Gragas.A.S:MenuElement({type = SPACE, id = "Note", name = "Note: Ghost/TP/Flash is not supported"})
------------------------------------------------------------------------------------------------------------------------------------------
--- Item Usage
function CastItems()
	local Hero = TargetSearch(900)
	if Hero == nil then return end
	local items = {}
	for slot = ITEM_1,ITEM_6 do
		local id = myHero:GetItemData(slot).itemID 
		if id > 0 then
			items[id] = slot
		end
	end

	local Potion = items[2003] or items[2010] or items[2031] or items[2032] or items[2033]
	if Potion and myHero:GetSpellData(Potion).currentCd == 0 and Gragas.A.P.Pot:Value() and HP100(myHero) < Gragas.A.P.HP:Value() and NoPotion() then
		Control.CastSpell(HKITEM[Potion])
	end

	if CurrentMode() == "Combo" then
		local Randuin = items[3143]
		if Randuin and myHero:GetSpellData(Randuin).currentCd == 0 and Gragas.A.I.RO:Value() and myHero.pos:DistanceTo(Hero.pos) < 500 then
			Control.CastSpell(HKITEM[Randuin])
		end

		local Proto = items[3152]
		if Proto and myHero:GetSpellData(Proto).currentCd == 0 and Gragas.A.I.Proto:Value() and myHero.pos:DistanceTo(Hero.pos) > 600 then
			Control.CastSpell(HKITEM[Proto], Hero.pos)
		end
	end
end
------------------------------------------------------------------------------------------------------------------------------------------
--- Summoners Usage
function CastSummoners()
	local Hero = TargetSearch(1500)
	if Hero == nil then return end
	if CurrentMode() == "Combo" then
		if myHero:GetSpellData(SUMMONER_1).name == "SummonerSmite" or myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmitePlayerGanker" or myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmiteDuel"
		or myHero:GetSpellData(SUMMONER_2).name == "SummonerSmite" or myHero:GetSpellData(SUMMONER_2).name == "S5_SummonerSmitePlayerGanker" or myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmiteDuel" then
			if Gragas.A.S.Smite:Value() then
				local RedDamage = Qdmg(Hero) + Wdmg(Hero) + Edmg(Hero) + Rdmg(Hero) + RSdmg(Hero)
				if myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmiteDuel" and Ready(SUMMONER_1) and RedDamage > Hero.health
				and myHero:GetSpellData(SUMMONER_1).ammo >= Gragas.A.S.SmiteS:Value() and myHero.pos:DistanceTo(Hero.pos) < 500 then
					Control.CastSpell(HK_SUMMONER_1, Hero)
				elseif myHero:GetSpellData(SUMMONER_2).name == "S5_SummonerSmiteDuel" and Ready(SUMMONER_2) and RedDamage > Hero.health
				and myHero:GetSpellData(SUMMONER_2).ammo >= Gragas.A.S.SmiteS:Value() and myHero.pos:DistanceTo(Hero.pos) < 500 then
					Control.CastSpell(HK_SUMMONER_2, Hero)
				end
				local BlueDamage = Qdmg(Hero) + Wdmg(Hero) + Edmg(Hero) + Rdmg(Hero) + BSdmg(Hero)
				if myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmitePlayerGanker" and Ready(SUMMONER_1) and BlueDamage > Hero.health
				and myHero:GetSpellData(SUMMONER_1).ammo >= Gragas.A.S.SmiteS:Value() and myHero.pos:DistanceTo(Hero.pos) < 500 then
					Control.CastSpell(HK_SUMMONER_1, Hero)
				elseif myHero:GetSpellData(SUMMONER_2).name == "S5_SummonerSmitePlayerGanker" and Ready(SUMMONER_2) and BlueDamage > Hero.health
				and myHero:GetSpellData(SUMMONER_2).ammo >= Gragas.A.S.SmiteS:Value() and myHero.pos:DistanceTo(Hero.pos) < 500 then
					Control.CastSpell(HK_SUMMONER_2, Hero)
				end
			end
		end
		if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot"
		or myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" then
			if Gragas.A.S.Ignite:Value() then
				local IgDamage = Qdmg(Hero) + Wdmg(Hero) + Edmg(Hero) + Rdmg(Hero) + Idmg(Hero)
				if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and Ready(SUMMONER_1) and IgDamage > Hero.health
				and myHero.pos:DistanceTo(Hero.pos) < 600 then
					Control.CastSpell(HK_SUMMONER_1, Hero)
				elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_1) and IgDamage > Hero.health
				and myHero.pos:DistanceTo(Hero.pos) < 600 then
					Control.CastSpell(HK_SUMMONER_2, Hero)
				end
			end
		end
		if myHero:GetSpellData(SUMMONER_1).name == "SummonerExhaust"
		or myHero:GetSpellData(SUMMONER_2).name == "SummonerExhaust" then
			if Gragas.A.S.Exh:Value() then
				local Damage = Qdmg(Hero) + Wdmg(Hero) + Edmg(Hero) + Rdmg(Hero)
				if myHero:GetSpellData(SUMMONER_1).name == "SummonerExhaust" and Ready(SUMMONER_1) and Damage > Hero.health
				and myHero.pos:DistanceTo(Hero.pos) < 650 then
					Control.CastSpell(HK_SUMMONER_1, Hero)
				elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerExhaust" and Ready(SUMMONER_1) and Damage > Hero.health
				and myHero.pos:DistanceTo(Hero.pos) < 650 then
					Control.CastSpell(HK_SUMMONER_2, Hero)
				end
			end
		end
	end
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerHeal"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerHeal" then
		if Gragas.A.S.Heal:Value() then
			if myHero:GetSpellData(SUMMONER_1).name == "SummonerHeal" and Ready(SUMMONER_1) and HP100(myHero) < Gragas.A.S.HealHP:Value() then
				Control.CastSpell(HK_SUMMONER_1)
			elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerHeal" and Ready(SUMMONER_1) and HP100(myHero) < Gragas.A.S.HealHP:Value() then
				Control.CastSpell(HK_SUMMONER_2)
			end
		end
	end
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerBarrier"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerBarrier" then
		if Gragas.A.S.Barrier:Value() then
			if myHero:GetSpellData(SUMMONER_1).name == "SummonerBarrier" and Ready(SUMMONER_1) and HP100(myHero) < Gragas.A.S.BarrierHP:Value() then
				Control.CastSpell(HK_SUMMONER_1)
			elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerBarrier" and Ready(SUMMONER_1) and HP100(myHero) < Gragas.A.S.BarrierHP:Value() then
				Control.CastSpell(HK_SUMMONER_2)
			end
		end
	end
	if myHero:GetSpellData(SUMMONER_1).name == "SummonerBoost"
	or myHero:GetSpellData(SUMMONER_2).name == "SummonerBoost" then
		if Gragas.A.S.Cleanse:Value() then
			for i = 0, myHero.buffCount do
			local buff = myHero:GetBuff(i);
				if buff.count > 0 then
					if ((buff.type == 5 and Gragas.A.S.Stun:Value())
					or (buff.type == 7 and  Gragas.A.S.Silence:Value())
					or (buff.type == 8 and  Gragas.A.S.Taunt:Value())
					or (buff.type == 9 and  Gragas.A.S.Poly:Value())
					or (buff.type == 10 and  Gragas.A.S.Slow:Value())
					or (buff.type == 11 and  Gragas.A.S.Root:Value())
					or (buff.type == 21 and  Gragas.A.S.Flee:Value())
					or (buff.type == 22 and  Gragas.A.S.Charm:Value())
					or (buff.type == 25 and  Gragas.A.S.Blind:Value())
					or (buff.type == 28 and  Gragas.A.S.Flee:Value())) then
						if myHero:GetSpellData(SUMMONER_1).name == "SummonerBoost" and Ready(SUMMONER_1) then
							Control.CastSpell(HK_SUMMONER_1)
						elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerBoost" and Ready(SUMMONER_2) then
							Control.CastSpell(HK_SUMMONER_2)
						end
					end
				end
			end
		end
	end
end
------------------------------------------------------------------------------------------------------------------------------------------
Callback.Add('Tick',function() CastItems() CastSummoners()
------------------------------------------------------------------------------------------------------------------------------------------
--- Q usage
    if Ready(_Q) and Gragas.Q.Enable:Value() then
        local Hero = TargetSearch(Q.Range)
        if Hero and Valid(Hero, Q.Range) then
            if (Gragas.Q.Combo:Value() and CurrentMode() == "Combo" and MP100(myHero) >= Gragas.M.Combo:Value())
            or (Gragas.Q.Harass:Value() and CurrentMode() == "Harass" and MP100(myHero) >= Gragas.M.Harass:Value())
            or (Gragas.Q.KS:Value() and MP100(myHero) >= Gragas.M.KS:Value() and Qdmg(Hero) >= Hero.health) then
                local Point = QtoPred:GetPrediction(Hero, myHero.pos)
                if Point and Point.hitChance >= 0.25 and myHero:GetSpellData(_Q).toggleState == 1 then
                    Control.CastSpell(HK_Q, Point.castPos)
                elseif myHero:GetSpellData(_Q).toggleState == 2 then
                    Control.CastSpell(HK_Q)
                end
            end
        end
        for i = 1, Game.MinionCount() do
		    local minion = Game.Minion(i)
            if minion and minion.team == 200 then
                if Gragas.Q.Lane:Value() and CurrentMode() == "Clear" and MP100(myHero) >= Gragas.M.Lane:Value() then
                    local BestPos, BestHit = BestCircFarm(Q.Range, Q.Radius, 200)
                    if BestPos and BestHit >= Gragas.Q.LMin:Value() and myHero:GetSpellData(_Q).toggleState == 1 then
                        Control.CastSpell(HK_Q, BestPos)
                    elseif myHero:GetSpellData(_Q).toggleState == 2 then
                        Control.CastSpell(HK_Q)
                    end
                end
            elseif minion and minion.team == 300 then
                if Gragas.Q.Jungle:Value() and CurrentMode() == "Clear" and MP100(myHero) >= Gragas.M.Jungle:Value() then
                    local BestPos, BestHit = BestCircFarm(Q.Range, Q.Radius, 300)
                    if BestPos and BestHit >= Gragas.Q.JMin:Value() and myHero:GetSpellData(_Q).toggleState == 1 then
                        Control.CastSpell(HK_Q, BestPos)
                    elseif myHero:GetSpellData(_Q).toggleState == 2 then
                        Control.CastSpell(HK_Q)
                    end
                end
            end
        end
	end
------------------------------------------------------------------------------------------------------------------------------------------
--- W usage
    if Ready(_W) and Gragas.W.Enable:Value() then
	    local Hero = TargetSearch(650)
        if Hero and Valid(Hero, 650) then
            if (Gragas.W.Combo:Value() and CurrentMode() == "Combo" and MP100(myHero) >= Gragas.M.Combo:Value())
            or (Gragas.W.Harass:Value() and CurrentMode() == "Harass" and MP100(myHero) >= Gragas.M.Harass:Value()) then
                Control.CastSpell(HK_W)
            end
        end
        for i = 1, Game.MinionCount() do
		    local minion = Game.Minion(i)
            if minion and minion.team == 200 then
                if Gragas.W.Lane:Value() and CurrentMode() == "Clear" and MP100(myHero) >= Gragas.M.Lane:Value() then
                    if MinionsAround(myHero.pos, 300, 200) >= Gragas.W.LMin:Value() then
                        Control.CastSpell(HK_W)
                    end
                end
            elseif minion and minion.team == 300 then
                if Gragas.W.Jungle:Value() and CurrentMode() == "Clear" and MP100(myHero) >= Gragas.M.Jungle:Value() then
                    if MinionsAround(myHero.pos, 300, 300) >= Gragas.W.JMin:Value() then
                        Control.CastSpell(HK_W)
                    end
                end
            end
        end
    end
------------------------------------------------------------------------------------------------------------------------------------------
--- E usage
    if Ready(_E) and Gragas.E.Enable:Value() then
        local Hero = TargetSearch(E.Range)
        if Hero and Valid(Hero, E.Range) then
            if (Gragas.E.Combo:Value() and CurrentMode() == "Combo" and MP100(myHero) >= Gragas.M.Combo:Value())
            or (Gragas.E.Harass:Value() and CurrentMode() == "Harass" and MP100(myHero) >= Gragas.M.Harass:Value())
            or (Gragas.E.KS:Value() and MP100(myHero) >= Gragas.M.KS:Value() and Edmg(Hero) >= Hero.health) then
                local Point = EtoPred:GetPrediction(Hero, myHero.pos)
                if Point and Point.hitChance >= 0.25 and Point:mCollision() == 0 then
                    Control.CastSpell(HK_E, Point.castPos)
                end
            end
        end
		for i = 1, Game.MinionCount() do
		    local minion = Game.Minion(i)
            if minion and minion.team == 200 then
                if Gragas.E.Lane:Value() and CurrentMode() == "Clear" and MP100(myHero) >= Gragas.M.Lane:Value() then
                    Control.CastSpell(HK_E, minion.pos)
                end
            elseif minion and minion.team == 300 then
                if Gragas.E.Jungle:Value() and CurrentMode() == "Clear" and MP100(myHero) >= Gragas.M.Jungle:Value() then
                    Control.CastSpell(HK_E, minion.pos)
                end
            end
        end
		if Gragas.E.Wall:Value() and MP100(myHero) >= Gragas.M.Misc:Value() then
			local Wall = myHero.pos:Extended(mousePos, 200)
			local AfterWall = myHero.pos:Extended(mousePos, E.Range)       
        	if MapPosition:inWall(Wall) and myHero.pos:DistanceTo(Wall) < 200 then                         
        		if not MapPosition:inWall(AfterWall) and mousePos.y-myHero.pos.y < 230 then                                 
        			Control.CastSpell(HK_E, AfterWall)
        		else
					Control.Move(AfterWall)
				end     
			end  
        end
		local FlashTarget = TargetSearch(975)
		if FlashTarget and Valid(FlashTarget, 975) then
			if myHero:GetSpellData(SUMMONER_1).name == "SummonerFlash"
			or myHero:GetSpellData(SUMMONER_2).name == "SummonerFlash" then
				if Gragas.E.Flash:Value() and MP100(myHero) >= Gragas.M.Misc:Value() and myHero.pos:DistanceTo(FlashTarget.pos) > 650 then
					if myHero:GetSpellData(SUMMONER_1).name == "SummonerFlash" and Ready(SUMMONER_1) then
						Control.CastSpell(HK_SUMMONER_1, FlashTarget)
						LastFlash = Game.Timer()
					elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerFlash" and Ready(SUMMONER_2) then
						Control.CastSpell(HK_SUMMONER_2, FlashTarget)
						LastFlash = Game.Timer()
					end
				end
				if Game.Timer() - LastFlash < 0.5 then
					Control.CastSpell(HK_E, FlashTarget)
				end
			end
		end
    end
------------------------------------------------------------------------------------------------------------------------------------------
--- R usage
	if Ready(_R) and Gragas.R.Enable:Value() then
		local Hero = TargetSearch(R.Range)
        if Hero and Valid(Hero, R.Range) then
			if Gragas.R.KS:Value() and MP100(myHero) >= Gragas.M.KS:Value() and Rdmg(Hero) >= Hero.health then
				local Point = RtoPred:GetPrediction(Hero, myHero.pos)
                if Point and Point.hitChance >= 0.25 and Point:mCollision() == 0 then
                    Control.CastSpell(HK_R, Point.castPos)
                end
			end
			if (Gragas.R.Combo:Value() and CurrentMode() == "Combo" and MP100(myHero) >= Gragas.M.Combo:Value() and Qdmg(Hero) + Wdmg(Hero) + Edmg(Hero) + Rdmg(Hero) > Hero.health)
			or (Gragas.R.Insec:Value() and MP100(myHero) >= Gragas.M.Misc:Value()) then
				if myHero.pos:DistanceTo(Hero.pos) < R.Range - 200 then
					local castPos = Vector(myHero.pos) + Vector(Vector(Hero.pos) - Vector(myHero.pos)):Normalized() * (myHero.pos:DistanceTo(Hero.pos) + 200)
					Control.CastSpell(HK_R, castPos)
				end
			end
		end
	end
------------------------------------------------------------------------------------------------------------------------------------------
end)
------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------
Callback.Add("Draw", function()
	if myHero.dead then return end
------------------------------------------------------------------------------------------------------------------------------------------
--- Ranges
	if Gragas.Q.Draw:Value() and Ready(_Q) then Draw.Circle(myHero.pos, Q.Range, 3,  Draw.Color(255, 000, 222, 255)) end
	if Gragas.E.Draw:Value() and Ready(_E) then Draw.Circle(myHero.pos, E.Range, 3,  Draw.Color(255, 246, 000, 255)) end
	if Gragas.R.Draw:Value() and Ready(_R) then Draw.Circle(myHero.pos, R.Range, 3,  Draw.Color(255, 255, 138, 000)) end
	if Gragas.R.DrawI:Value() and Ready(_R) then Draw.Circle(myHero.pos, R.Range - 200, 3,  Draw.Color(255, 000, 043, 255)) end
------------------------------------------------------------------------------------------------------------------------------------------
--- Damages
	if Gragas.M.Dmg:Value() then
		for i = 1, Game.HeroCount() do
			local Hero = Game.Hero(i)
			if Hero and Hero.isEnemy and not Hero.dead and Hero.visible then
				local barPos = Hero.hpBar
				local health = Hero.health
				local maxHealth = Hero.maxHealth
				local Qdmg = Qdmg(Hero)
				local Wdmg = Wdmg(Hero)
				local Edmg = Edmg(Hero)
				local Rdmg = Rdmg(Hero)
				local Damage = Qdmg + Wdmg + Edmg + Rdmg
				if Damage < health then
					Draw.Rect(barPos.x + (((health - Qdmg) / maxHealth) * 100), barPos.y, (Qdmg / maxHealth )*100, 10, Draw.Color(170, 000, 222, 255))
					Draw.Rect(barPos.x + (((health - (Qdmg + Wdmg)) / maxHealth) * 100), barPos.y, (Wdmg / maxHealth )*100, 10, Draw.Color(170, 255, 200, 000))
					Draw.Rect(barPos.x + (((health - (Qdmg + Wdmg + Edmg)) / maxHealth) * 100), barPos.y, (Edmg / maxHealth )*100, 10, Draw.Color(170, 246, 000, 255))
					Draw.Rect(barPos.x + (((health - (Qdmg + Wdmg + Edmg + Rdmg)) / maxHealth) * 100), barPos.y, (Rdmg / maxHealth )*100, 10, Draw.Color(170, 000, 043, 255))
				else
    				Draw.Rect(barPos.x, barPos.y, (health / maxHealth ) * 100, 10, Draw.Color(170, 000, 255, 000))
				end
			end
		end
	end
------------------------------------------------------------------------------------------------------------------------------------------
end)
------------------------------------------------------------------------------------------------------------------------------------------
