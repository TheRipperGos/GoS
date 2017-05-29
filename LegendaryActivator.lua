local Legendary = MenuElement({type = MENU, id = "Legendary", name = "Legendary Activator", leftIcon = "https://raw.githubusercontent.com/TheRipperGos/GoS/master/Sprites/"..myHero.charName..".png"})

Legendary:MenuElement({type = MENU, id = "Combo", name = "Combo Settings"})
Legendary:MenuElement({type = MENU, id = "Clear", name = "Clear Settings"})
Legendary:MenuElement({type = MENU, id = "Flee", name = "Flee Settings"})
Legendary:MenuElement({type = MENU, id = "Shield", name = "Shield Settings"})
Legendary:MenuElement({type = MENU, id = "Heal", name = "Heal Settings"})
Legendary:MenuElement({type = MENU, id = "Cleanse", name = "Cleanse Settings"})
Legendary:MenuElement({type = MENU, id = "Killsteal", name = "Killsteal Settings"})

local function Ready(spell)
	return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana
end

function LegendaryTarget(range)
	if _G.SDK then return _G.SDK.TargetSelector:GetTarget(5500, _G.SDK.DAMAGE_TYPE_PHYSICAL) elseif _G.GOS then return _G.GOS:GetTarget(5500,"AD")
	end
end

local function HpPred(unit, delay)
	if _G.GOS then
	hp =  GOS:HP_Pred(unit,delay)
	else
	hp = unit.health
	end
	return hp
end

local _AllyHeroes
local function GetAllyHeroes()
	if _AllyHeroes then return _AllyHeroes end
	_AllyHeroes = {}
	for i = 1, Game.HeroCount() do
		local unit = Game.Hero(i)
		if unit.isAlly then
			table.insert(_AllyHeroes, unit)
		end
	end
	return _AllyHeroes
end

local _EnemyHeroes
local function GetEnemyHeroes()
	if _EnemyHeroes then return _EnemyHeroes end
	_EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local unit = Game.Hero(i)
		if unit.isEnemy then
			table.insert(_EnemyHeroes, unit)
		end
	end
	return _EnemyHeroes
end

local function GetPercentHP(unit)
	if type(unit) ~= "userdata" then error("{GetPercentHP}: bad argument #1 (userdata expected, got "..type(unit)..")") end
	return 100*unit.health/unit.maxHealth
end

local function GetPercentMP(unit)
	if type(unit) ~= "userdata" then error("{GetPercentMP}: bad argument #1 (userdata expected, got "..type(unit)..")") end
	return 100*unit.mana/unit.maxMana
end

local function GetBuffData(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name == buffname and buff.count > 0 then 
			return buff
		end
	end
	return {type = 0, name = "", startTime = 0, expireTime = 0, duration = 0, stacks = 0, count = 0}--
end

local function GetBuffs(unit)
	local t = {}
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.count > 0 then
			table.insert(t, buff)
		end
	end
	return t
end

local sqrt = math.sqrt 
local function GetDistance(p1,p2)
	return sqrt((p2.x - p1.x)*(p2.x - p1.x) + (p2.y - p1.y)*(p2.y - p1.y) + (p2.z - p1.z)*(p2.z - p1.z))
end

local function GetDistance2D(p1,p2)
	return sqrt((p2.x - p1.x)*(p2.x - p1.x) + (p2.y - p1.y)*(p2.y - p1.y))
end

local function HasBuff(unit, buffname)
	if type(unit) ~= "userdata" then error("{HasBuff}: bad argument #1 (userdata expected, got "..type(unit)..")") end
	if type(buffname) ~= "string" then error("{HasBuff}: bad argument #2 (string expected, got "..type(buffname)..")") end
	for i, buff in pairs(GetBuffs(unit)) do
		if buff.name == buffname then 
			return true
		end
	end
	return false
end

local function IsImmobileTarget(unit)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.name == "recall") and buff.count > 0 then
			return true
		end
	end
	return false	
end

local ItemHotKey = {
    [ITEM_1] = HK_ITEM_1,
    [ITEM_2] = HK_ITEM_2,
    [ITEM_3] = HK_ITEM_3,
    [ITEM_4] = HK_ITEM_4,
    [ITEM_5] = HK_ITEM_5,
    [ITEM_6] = HK_ITEM_6,
}

local function GetItemSlot(unit, id)
  for i = ITEM_1, ITEM_7 do
    if unit:GetItemData(i).itemID == id then
      return i
    end
  end
  return 0 
end

local function IsImmune(unit)
	if type(unit) ~= "userdata" then error("{IsImmune}: bad argument #1 (userdata expected, got "..type(unit)..")") end
	for i, buff in pairs(GetBuffs(unit)) do
		if (buff.name == "KindredRNoDeathBuff" or buff.name == "UndyingRage") and GetPercentHP(unit) <= 10 then
			return true
		end
		if buff.name == "VladimirSanguinePool" or buff.name == "JudicatorIntervention" then 
			return true
		end
	end
	return false
end

function IsValidTarget(unit, range, onScreen)
    local range = range or 20000
    
    return unit and unit.distance <= range and not unit.dead and unit.valid and unit.visible and unit.isTargetable and not (onScreen and not unit.pos2D.onScreen)
end

local function GetEnemyMinions(range)
    EnemyMinions = {}
    for i = 1, Game.MinionCount() do
        local Minion = Game.Minion(i)
        if Minion.isEnemy and IsValidTarget(Minion, range, false, myHero) and not Minion.dead then
            table.insert(EnemyMinions, Minion)
        end
    end
    return EnemyMinions
end

local function MinionsAround(pos, range, team)
	local Count = 0
	for i = 1, Game.MinionCount() do
		local m = Game.Minion(i)
		if m and m.team == team and not m.dead and GetDistance(pos, m.pos) <= range then
			Count = Count + 1
		end
	end
	return Count
end

local _EnemyHeroes
local function GetEnemyHeroes()
    if _EnemyHeroes then return _EnemyHeroes end
    _EnemyHeroes = {}
    for i = 1, Game.HeroCount() do
        local unit = Game.Hero(i)
        if unit.isEnemy then
            _EnemyHeroes[#_EnemyHeroes + 1] = unit
        end
    end
    return _EnemyHeroes
end

local SmiteTable = {
	SRU_Baron = "Baron",
	SRU_RiftHerald = "Herald",
	SRU_Dragon_Water = "Ocean",
	SRU_Dragon_Fire = "Infernal",
	SRU_Dragon_Earth = "Mountain",
	SRU_Dragon_Air = "Cloud",
	SRU_Dragon_Elder = "Elder",
	SRU_Blue = "Blue",
	SRU_Red = "Red",
	SRU_Gromp = "Gromp",
	SRU_Murkwolf = "Wolf",
	SRU_Razorbeak = "Raptor",
	SRU_Krug = "Krug",
	SRU_Crab = "Crab",
}

local SmiteNames = {'SummonerSmite','S5_SummonerSmiteDuel','S5_SummonerSmitePlayerGanker','S5_SummonerSmiteQuick','ItemSmiteAoE'};
local SmiteDamage = {390 , 410 , 430 , 450 , 480 , 510 , 540 , 570 , 600 , 640 , 680 , 720 , 760 , 800 , 850 , 900 , 950 , 1000};
local mySmiteSlot = 0;

local function GetSmite(smiteSlot)
	local returnVal = 0;
	local spellName = myHero:GetSpellData(smiteSlot).name;
	for i = 1, 5 do
		if spellName == SmiteNames[i] then
			returnVal = smiteSlot
		end
	end
	return returnVal;
end

function OnLoad()
	mySmiteSlot = GetSmite(SUMMONER_1);
	if mySmiteSlot == 0 then
		mySmiteSlot = GetSmite(SUMMONER_2);
	end
end

local function AutoSmiteMinion(type,minion)
	if not type or not Legendary.Clear.Smite[type] then
		return
	end
	if Legendary.Clear.Smite[type]:Value() then
		if minion.pos2D.onScreen then
			if mySmiteSlot == SUMMONER_1 then
				Control.CastSpell(HK_SUMMONER_1,minion)
			else
				Control.CastSpell(HK_SUMMONER_2,minion)
			end
		end
	end
end

function OnDraw()
if myHero.alive == false then return end
	if Legendary.Clear.Smite.S:Value() and (mySmiteSlot > 0) then
		if Legendary.Clear.Smite.S:Value() then
			local SData = myHero:GetSpellData(mySmiteSlot);
			for i = 1, Game.MinionCount() do
				minion = Game.Minion(i);
				if minion and minion.valid and (minion.team == 300) and minion.visible then
					if minion.health <= SmiteDamage[myHero.levelData.lvl] then
						local minionName = minion.charName;
						if Legendary.Clear.Smite.S:Value() then
							if mySmiteSlot > 0 then
								if SData.level > 0 then
									if (SData.currentCd == 0) then
										if minion.distance <= (500+myHero.boundingRadius+minion.boundingRadius) then
											AutoSmiteMinion(SmiteTable[minionName], minion);
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

local function CountEnemys(range)
	local heroesCount = 0
	for i = 1,Game.HeroCount() do
		local enemy = Game.Hero(i)
		if  enemy.team ~= myHero.team and enemy.valid and enemy.pos:DistanceTo(myHero.pos) < 1200 then
		heroesCount = heroesCount + 1
		end
	end
	return heroesCount
end

local function CountAllyEnemies(pos,range)
	local N = 0
	for i = 1,Game.HeroCount()  do
		local hero = Game.Hero(i)	
		if IsValidTarget(hero,range) and hero.team ~= myHero.team then
			N = N + 1
		end
	end
	return N	
end

local function CountAlly(pos,range)
	local N = 0
	for i = 1,Game.HeroCount()  do
		local hero = Game.Hero(i)	
		if IsValidTarget(hero,range) and hero.team == myHero.team then
			N = N + 1
		end
	end
	return N	
end

local castSpell = {state = 0, tick = GetTickCount(), casting = GetTickCount() - 1000, mouse = mousePos}

local function CastSpellMM(spell,pos,range,delay)
local range = range or math.huge
local delay = delay or 250
local ticker = GetTickCount()
	if castSpell.state == 0 and GetDistance(myHero.pos,pos) < range and ticker - castSpell.casting > delay + Game.Latency() then
		castSpell.state = 1
		castSpell.mouse = mousePos
		castSpell.tick = ticker
	end
	if castSpell.state == 1 then
		if ticker - castSpell.tick < Game.Latency() then
			local castPosMM = pos:ToMM()
			Control.SetCursorPos(castPosMM.x,castPosMM.y)
			Control.KeyDown(spell)
			Control.KeyUp(spell)
			castSpell.casting = ticker + delay
			DelayAction(function()
				if castSpell.state == 1 then
					Control.SetCursorPos(castSpell.mouse)
					castSpell.state = 0
				end
			end,Game.Latency()/1000)
		end
		if ticker - castSpell.casting > Game.Latency() then
			Control.SetCursorPos(castSpell.mouse)
			castSpell.state = 0
		end
	end
end

require "DamageLib"

    
	local Icon = { 	T = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/e/e3/Tiamat_item.png",
					RH = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/e/e8/Ravenous_Hydra_item.png",
					TH = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/2/22/Titanic_Hydra_item.png",
					EN = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/6/69/Edge_of_Night_item.png",
					BC = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/4/44/Bilgewater_Cutlass_item.png",
					BOTRK = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/2/2f/Blade_of_the_Ruined_King_item.png",
					RO = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/0/08/Randuin%27s_Omen_item.png",
					RG = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/9/9f/Righteous_Glory_item.png",
					YG = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/4/41/Youmuu%27s_Ghostblade_item.png",
					QSS = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/f/f9/Quicksilver_Sash_item.png",
					MS = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/0/0a/Mercurial_Scimitar_item.png",
					FOM = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/e/e8/Face_of_the_Mountain_item.png",
					FQC = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/7/77/Frost_Queen%27s_Claim_item.png",
					GLP = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/c/c9/Hextech_GLP-800_item.png",
					HG = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/6/64/Hextech_Gunblade_item.png",
					HP1 = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/8/8d/Hextech_Protobelt-01_item.png",
					LOCK = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/5/56/Locket_of_the_Iron_Solari_item.png",
					MC = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/d/de/Mikael%27s_Crucible_item.png",
					OHM = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/6/6c/Ohmwrecker_item.png",
					RD = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/9/94/Redemption_item.png",
					SER = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/b/b9/Seraph%27s_Embrace_item.png",
					TAL = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/3/32/Talisman_of_Ascension_item.png",
					CP = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/8/87/Corrupting_Potion_item.png",
					HP = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/1/13/Health_Potion_item.png",
					HSP = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/6/63/Hunter%27s_Potion_item.png",
					RP = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/7/7f/Refillable_Potion_item.png",
					TB = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/0/01/Total_Biscuit_of_Rejuvenation_item.png",
					IG = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/f/f4/Ignite.png",
					EX = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/4/4a/Exhaust.png",
					Cleanse = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/9/95/Cleanse.png",
					Barrier = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/c/cc/Barrier.png",
					Heal = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/6/6e/Heal.png",
					S = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/0/05/Smite.png",
					RS = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/6/69/Challenging_Smite.png",
					BS = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/0/05/Chilling_Smite.png",
					Gromp = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/e/e8/GrompSquare.png",
					Raptor = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/9/94/Crimson_RaptorSquare.png",
					Wolf = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/d/d6/Greater_Murk_WolfSquare.png",
					Krug = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/f/fe/Ancient_KrugSquare.png",
					Blue = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/8/85/Blue_SentinelSquare.png",
					Red = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/e/e7/Red_BramblebackSquare.png",
					Crab = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/a/a2/Rift_ScuttlerSquare.png",
					Cloud = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/4/47/Cloud_DrakeSquare.png",
					Infernal = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/a/a0/Infernal_DrakeSquare.png",
					Mountain = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/0/00/Mountain_DrakeSquare.png",
					Ocean = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/5/55/Ocean_DrakeSquare.png",
					Elder = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/3/34/Elder_DragonSquare.png",
					Herald = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/c/c3/Rift_HeraldSquare.png",
					Baron = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/3/38/Baron_NashorSquare.png",
					}
	-- Combo --
	Legendary.Combo:MenuElement({type = MENU, id = "Items", name = "Items"})
	Legendary.Combo.Items:MenuElement({id = "T", name = "Tiamat", value = true, leftIcon = Icon.T})
	Legendary.Combo.Items:MenuElement({id = "RH", name = "Ravenous Hydra", value = true, leftIcon = Icon.RH})
	Legendary.Combo.Items:MenuElement({id = "TH", name = "Titanic Hydra", value = true, leftIcon = Icon.TH})
	Legendary.Combo.Items:MenuElement({id = "FQC", name = "Frost Queen's Claim", value = true, leftIcon = Icon.FQC})
	Legendary.Combo.Items:MenuElement({type = MENU, id = "FQCS", name = "Settings"})
	Legendary.Combo.Items.FQCS:MenuElement({id = "EN", name = "Min Enemies", value = 2, min = 1, max = 2})
	Legendary.Combo.Items:MenuElement({id = "TAL", name = "Talisman of Ascension", value = true, leftIcon = Icon.TAL})
	Legendary.Combo.Items:MenuElement({type = MENU, id = "TALS", name = "Settings"})
	Legendary.Combo.Items.TALS:MenuElement({id = "MA", name = "Min Allies [?]", value = 2, min = 1, max = 5, tooltip = "Includes You"})
	Legendary.Combo.Items.TALS:MenuElement({id = "EN", name = "Min Enemies", value = 2, min = 1, max = 5})
	Legendary.Combo.Items:MenuElement({id = "EN", name = "Edge of Night", value = true, leftIcon = Icon.EN})
	Legendary.Combo.Items:MenuElement({type = MENU, id = "ENS", name = "Settings"})
	Legendary.Combo.Items.ENS:MenuElement({id = "EN", name = "Min Enemies", value = 2, min = 1, max = 5})
	Legendary.Combo.Items:MenuElement({id = "GLP", name = "Hextech GLP-800", value = true, leftIcon = Icon.GLP})
	Legendary.Combo.Items:MenuElement({type = MENU, id = "GLPS", name = "Settings"})
	Legendary.Combo.Items.GLPS:MenuElement({id = "EHP", name = "Max enemy HP (%)", value = 70, min = 0, max = 100})
	Legendary.Combo.Items:MenuElement({id = "HG", name = "Hextech Gunblade", value = true, leftIcon = Icon.HG})
	Legendary.Combo.Items:MenuElement({type = MENU, id = "HGS", name = "Settings"})
	Legendary.Combo.Items.HGS:MenuElement({id = "EHP", name = "Max enemy HP (%)", value = 70, min = 0, max = 100})
	Legendary.Combo.Items:MenuElement({id = "HP1", name = "Hextech Protobelt-01", value = true, leftIcon = Icon.HP1})
	Legendary.Combo.Items:MenuElement({type = MENU, id = "HP1S", name = "Settings"})
	Legendary.Combo.Items.HP1S:MenuElement({id = "EHP", name = "Max enemy HP (%)", value = 70, min = 0, max = 100})
	Legendary.Combo.Items:MenuElement({id = "BC", name = "Bilgewater Cutlass", value = true, leftIcon = Icon.BC})
	Legendary.Combo.Items:MenuElement({type = MENU, id = "BCS", name = "Settings"})
	Legendary.Combo.Items.BCS:MenuElement({id = "HP", name = "Max HP (%)", value = 70, min = 0, max = 100})
	Legendary.Combo.Items.BCS:MenuElement({id = "EHP", name = "Max Enemy HP (%)", value = 70, min = 0, max = 100})
	Legendary.Combo.Items:MenuElement({id = "BOTRK", name = "Blade of the Ruined King", value = true, leftIcon = Icon.BOTRK})
	Legendary.Combo.Items:MenuElement({type = MENU, id = "BOTRKS", name = "Settings"})
	Legendary.Combo.Items.BOTRKS:MenuElement({id = "HP", name = "Max HP (%)", value = 70, min = 0, max = 100})
	Legendary.Combo.Items.BOTRKS:MenuElement({id = "EHP", name = "Max Enemy HP (%)", value = 70, min = 0, max = 100})
	Legendary.Combo.Items:MenuElement({id = "RO", name = "Randuin's Omen", value = true, leftIcon = Icon.RO})
	Legendary.Combo.Items:MenuElement({type = MENU, id = "ROS", name = "Settings"})
	Legendary.Combo.Items.ROS:MenuElement({id = "HP", name = "Max HP (%)", value = 70, min = 0, max = 100})
	Legendary.Combo.Items.ROS:MenuElement({id = "EHP", name = "Max Enemy HP (%)", value = 70, min = 0, max = 100})
	Legendary.Combo.Items:MenuElement({id = "RG", name = "Righteous Glory", value = true, leftIcon = Icon.RG})
	Legendary.Combo.Items:MenuElement({type = MENU, id = "RGS", name = "Settings"})
	Legendary.Combo.Items.RGS:MenuElement({id = "ED", name = "Enemy Distance", value = 1000, min = 400, max = 2500, step = 25})
	Legendary.Combo.Items:MenuElement({id = "YG", name = "Youmuu's Ghostblade", value = true, leftIcon = Icon.YG})
	Legendary.Combo.Items:MenuElement({type = MENU, id = "YGS", name = "Settings"})
	Legendary.Combo.Items.YGS:MenuElement({id = "ED", name = "Enemy Distance", value = 1000, min = 400, max = 2500, step = 25})
	Legendary.Combo.Items:MenuElement({id = "OHM", name = "Ohmwrecker", value = true, leftIcon = Icon.OHM})
	Legendary.Combo.Items:MenuElement({type = MENU, id = "OHMS", name = "Settings"})
	Legendary.Combo.Items.OHMS:MenuElement({id = "MA", name = "Min Allies Diving [?]", value = 2, min = 1, max = 5, tooltip = "Includes You"})
	Legendary.Combo:MenuElement({type = MENU, id = "Spells", name = "Summoner Spells"})
	Legendary.Combo.Spells:MenuElement({id = "IG", name = "Ignite", value = true, leftIcon = Icon.IG})
	Legendary.Combo.Spells:MenuElement({type = MENU, id = "IGS", name = "Settings"})
	Legendary.Combo.Spells.IGS:MenuElement({id = "HP", name = "Enemy HP (%)", value = 40, min = 0, max = 100})
	Legendary.Combo.Spells:MenuElement({id = "EX", name = "Exhaust", value = true, leftIcon = Icon.EX})
	Legendary.Combo.Spells:MenuElement({type = MENU, id = "EXS", name = "Settings"})
	Legendary.Combo.Spells.EXS:MenuElement({id = "HP", name = "Enemy HP (%)", value = 40, min = 0, max = 100})
	Legendary.Combo.Spells:MenuElement({id = "RS", name = "Challenging Smite", value = true, leftIcon = Icon.RS})
	Legendary.Combo.Spells:MenuElement({type = MENU, id = "RSS", name = "Settings"})
	Legendary.Combo.Spells.RSS:MenuElement({id = "HP", name = "Enemy HP (%)", value = 40, min = 0, max = 100})
	Legendary.Combo.Spells:MenuElement({id = "BS", name = "Chilling Smite", value = true, leftIcon = Icon.BS})
	Legendary.Combo.Spells:MenuElement({type = MENU, id = "BSS", name = "Settings"})
	Legendary.Combo.Spells.BSS:MenuElement({id = "HP", name = "Enemy HP (%)", value = 40, min = 0, max = 100})
	-- Clear --
	Legendary.Clear:MenuElement({type = MENU, id = "Items", name = "Items"})
	Legendary.Clear.Items:MenuElement({id = "T", name = "Tiamat", value = true, leftIcon = Icon.T})
	Legendary.Clear.Items:MenuElement({id = "RH", name = "Ravenous Hydra", value = true, leftIcon = Icon.RH})
	Legendary.Clear:MenuElement({type = MENU, id = "Smite", name = "Smite"})
	Legendary.Clear.Smite:MenuElement({id = "S", name = "Use Smite", value = true, leftIcon = Icon.S})
	Legendary.Clear.Smite:MenuElement({id = "Gromp", name = "Gromp", value = false, leftIcon = Icon.Gromp})
	Legendary.Clear.Smite:MenuElement({id = "Raptor", name = "Crimson Raptor", value = false, leftIcon = Icon.Raptor})
	Legendary.Clear.Smite:MenuElement({id = "Wolf", name = "Greater Murk Wolf", value = false, leftIcon = Icon.Wolf})
	Legendary.Clear.Smite:MenuElement({id = "Krug", name = "Ancient Krug", value = false, leftIcon = Icon.Krug})
	Legendary.Clear.Smite:MenuElement({id = "Blue", name = "Blue Sentinel", value = true, leftIcon = Icon.Blue})
	Legendary.Clear.Smite:MenuElement({id = "Red", name = "Red Brambleback", value = true, leftIcon = Icon.Red})
	Legendary.Clear.Smite:MenuElement({id = "Crab", name = "Rift Scuttler", value = false, leftIcon = Icon.Crab})
	Legendary.Clear.Smite:MenuElement({id = "Cloud", name = "Cloud Drake", value = true, leftIcon = Icon.Cloud})
	Legendary.Clear.Smite:MenuElement({id = "Infernal", name = "Infernal Drake", value = true, leftIcon = Icon.Infernal})
	Legendary.Clear.Smite:MenuElement({id = "Mountain", name = "Mountain Drake", value = true, leftIcon = Icon.Mountain})
	Legendary.Clear.Smite:MenuElement({id = "Ocean", name = "Ocean Drake", value = true, leftIcon = Icon.Ocean})
	Legendary.Clear.Smite:MenuElement({id = "Elder", name = "Elder Dragon", value = true, leftIcon = Icon.Elder})
	Legendary.Clear.Smite:MenuElement({id = "Herald", name = "Rift Herald", value = true, leftIcon = Icon.Herald})
	Legendary.Clear.Smite:MenuElement({id = "Baron", name = "Baron Nashor", value = true, leftIcon = Icon.Baron})
	-- Flee --
	Legendary.Flee:MenuElement({type = MENU, id = "Items", name = "Items"})
	Legendary.Flee.Items:MenuElement({id = "FQC", name = "Frost Queen's Claim", value = true, leftIcon = Icon.FQC})
	Legendary.Flee.Items:MenuElement({id = "TAL", name = "Talisman of Ascension", value = true, leftIcon = Icon.TAL})
	Legendary.Flee.Items:MenuElement({id = "EN", name = "Edge of Night", value = true, leftIcon = Icon.EN})
	Legendary.Flee.Items:MenuElement({id = "GLP", name = "Hextech GLP-800", value = true, leftIcon = Icon.GLP})
	Legendary.Flee.Items:MenuElement({id = "HG", name = "Hextech Gunblade", value = true, leftIcon = Icon.HG})
	Legendary.Flee.Items:MenuElement({id = "HP1", name = "Hextech Protobelt-01", value = true, leftIcon = Icon.HP1})
	Legendary.Flee.Items:MenuElement({id = "BC", name = "Bilgewater Cutlass", value = true, leftIcon = Icon.BC})
	Legendary.Flee.Items:MenuElement({id = "BOTRK", name = "Blade of the Ruined King", value = true, leftIcon = Icon.BOTRK})
	Legendary.Flee.Items:MenuElement({id = "RO", name = "Randuin's Omen", value = true, leftIcon = Icon.RO})
	Legendary.Flee.Items:MenuElement({id = "RG", name = "Righteous Glory", value = true, leftIcon = Icon.RG})
	Legendary.Flee.Items:MenuElement({id = "YG", name = "Youmuu's Ghostblade", value = true, leftIcon = Icon.YG})
	Legendary.Flee:MenuElement({type = MENU, id = "Spells", name = "Summoner Spells"})
	Legendary.Flee.Spells:MenuElement({id = "EX", name = "Exhaust", value = true, leftIcon = Icon.EX})
	Legendary.Flee.Spells:MenuElement({id = "BS", name = "Chilling Smite", value = true, leftIcon = Icon.BS})
	-- Killsteal --
	Legendary.Killsteal:MenuElement({type = MENU, id = "Items", name = "Items"})
	Legendary.Killsteal.Items:MenuElement({id = "RD", name = "Redemption", value = true, leftIcon = Icon.RD})
	Legendary.Killsteal.Items:MenuElement({id = "BC", name = "Bilgewater Cutlass", value = true, leftIcon = Icon.BC})
	Legendary.Killsteal.Items:MenuElement({id = "BOTRK", name = "Blade of the Ruined King", value = true, leftIcon = Icon.BOTRK})
	Legendary.Killsteal:MenuElement({type = MENU, id = "Spells", name = "Summoner Spells"})
	Legendary.Killsteal.Spells:MenuElement({id = "IG", name = "Ignite", value = true, leftIcon = Icon.IG})
	Legendary.Killsteal.Spells:MenuElement({id = "BS", name = "Chilling Smite", value = true, leftIcon = Icon.BS})
	-- Shield --
	Legendary.Shield:MenuElement({type = MENU, id = "Items", name = "Items"})
	Legendary.Shield.Items:MenuElement({id = "SER", name = "Seraph's Embrace", value = true, leftIcon = Icon.SER})
	Legendary.Shield.Items:MenuElement({type = MENU, id = "SERS", name = "Settings"})
	Legendary.Shield.Items.SERS:MenuElement({id = "HP", name = "If my HP less than (%)", value = 15, min = 0, max = 100})
	Legendary.Shield.Items:MenuElement({id = "FOM", name = "Face of the Mountain", value = true, leftIcon = Icon.FOM})
	Legendary.Shield.Items:MenuElement({type = MENU, id = "FOMS", name = "Settings"})
	Legendary.Shield.Items.FOMS:MenuElement({id = "HP", name = "If my HP less than (%)", value = 15, min = 0, max = 100})
	Legendary.Shield.Items:MenuElement({id = "LOCK", name = "Locket of the Iron Solari", value = true, leftIcon = Icon.LOCK})
	Legendary.Shield.Items:MenuElement({type = MENU, id = "LOCKS", name = "Settings"})
	Legendary.Shield.Items.LOCKS:MenuElement({id = "HP", name = "If my HP less than (%)", value = 15, min = 0, max = 100})
	Legendary.Shield:MenuElement({type = MENU, id = "Spells", name = "Summoner Spells"})
	Legendary.Shield.Spells:MenuElement({id = "Barrier", name = "Barrier", value = true, leftIcon = Icon.Barrier})
	Legendary.Shield.Spells:MenuElement({type = MENU, id = "BarrierS", name = "Settings"})
	Legendary.Shield.Spells.BarrierS:MenuElement({id = "HP", name = "If my HP less than (%)", value = 25, min = 0, max = 100})
	-- Heal --
	Legendary.Heal:MenuElement({type = MENU, id = "Items", name = "Items"})
	Legendary.Heal.Items:MenuElement({id = "HP", name = "Health Potion", value = true, leftIcon = Icon.HP})
	Legendary.Heal.Items:MenuElement({type = MENU, id = "HPS", name = "Settings"})
	Legendary.Heal.Items.HPS:MenuElement({id = "HP", name = "If my HP less than (%)", value = 60, min = 0, max = 100})
	Legendary.Heal.Items:MenuElement({id = "TB", name = "Total Biscuit of Rejuvenation", value = true, leftIcon = Icon.TB})
	Legendary.Heal.Items:MenuElement({type = MENU, id = "TBS", name = "Settings"})
	Legendary.Heal.Items.TBS:MenuElement({id = "TB", name = "If my HP less than (%)", value = 60, min = 0, max = 100})
	Legendary.Heal.Items:MenuElement({id = "RP", name = "Refillable Potion", value = true, leftIcon = Icon.RP})
	Legendary.Heal.Items:MenuElement({type = MENU, id = "RPS", name = "Settings"})
	Legendary.Heal.Items.RPS:MenuElement({id = "RP", name = "If my HP less than (%)", value = 60, min = 0, max = 100})
	Legendary.Heal.Items:MenuElement({id = "CP", name = "Corrupting Potion", value = true, leftIcon = Icon.CP})
	Legendary.Heal.Items:MenuElement({type = MENU, id = "CPS", name = "Settings"})
	Legendary.Heal.Items.CPS:MenuElement({id = "HP", name = "If my HP less than (%)", value = 60, min = 0, max = 100})
	Legendary.Heal.Items:MenuElement({id = "HSP", name = "Hunter's Potion", value = true, leftIcon = Icon.HSP})
	Legendary.Heal.Items:MenuElement({type = MENU, id = "HSPS", name = "Settings"})
	Legendary.Heal.Items.HSPS:MenuElement({id = "HSP", name = "If my HP less than (%)", value = 60, min = 0, max = 100})
	Legendary.Heal.Items:MenuElement({id = "RD", name = "Redemption", value = true, leftIcon = Icon.RD})
	Legendary.Heal.Items:MenuElement({type = MENU, id = "RDS", name = "Settings"})
	Legendary.Heal.Items.RDS:MenuElement({id = "HP", name = "If my HP less than (%)", value = 30, min = 0, max = 100})
	Legendary.Heal:MenuElement({type = MENU, id = "Spells", name = "Summoner Spells"})
	Legendary.Heal.Spells:MenuElement({id = "Heal", name = "Heal", value = true, leftIcon = Icon.Heal})
	Legendary.Heal.Spells:MenuElement({type = MENU, id = "HealS", name = "Settings"})
	Legendary.Heal.Spells.HealS:MenuElement({id = "HP", name = "If my HP less than (%)", value = 25, min = 0, max = 100})
	-- Cleanse --
	Legendary.Cleanse:MenuElement({id = "Cleanse", name = "Cleanse", value = true, leftIcon = Icon.Cleanse})
	Legendary.Cleanse:MenuElement({id = "QSS", name = "Quicksilver Sash", value = true, leftIcon = Icon.QSS})
	Legendary.Cleanse:MenuElement({id = "MS", name = "Mercurial Scimitar", value = true, leftIcon = Icon.MS})
	Legendary.Cleanse:MenuElement({id = "MC", name = "Mikael's Crucible", value = true, leftIcon = Icon.MC})
	Legendary.Cleanse:MenuElement({id = "Stun", name = "Stun", value = true, leftIcon = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/8/8d/Gold_Card.png"})
	Legendary.Cleanse:MenuElement({id = "Silence", name = "Silence", value = false, leftIcon = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/3/3b/Feral_Scream.png"})
	Legendary.Cleanse:MenuElement({id = "Taunt", name = "Taunt", value = true, leftIcon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/9/92/Shadow_Dash.png"})
	Legendary.Cleanse:MenuElement({id = "Polimorphy", name = "Polimorphy", value = true, leftIcon = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/7/7c/Whimsy.png"})
	Legendary.Cleanse:MenuElement({id = "Slow", name = "Slow", value = false, leftIcon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/a/aa/Wither.png"})
	Legendary.Cleanse:MenuElement({id = "Snare", name = "Snare", value = true, leftIcon = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/a/a2/Dark_Binding.png"})
	Legendary.Cleanse:MenuElement({id = "Nearsight", name = "Nearsight", value = false, leftIcon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/e/e5/Smoke_Screen.png"})
	Legendary.Cleanse:MenuElement({id = "Fear", name = "Fear", value = true, leftIcon = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/b/bb/Jack_in_the_Box.png"})
	Legendary.Cleanse:MenuElement({id = "Charm", name = "Charm", value = true, leftIcon = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/0/04/Charm.png"})
	Legendary.Cleanse:MenuElement({id = "Poison", name = "Poison", value = false, leftIcon = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/5/54/Noxious_Blast.png"})
	Legendary.Cleanse:MenuElement({id = "Supression", name = "Supression", value = true, leftIcon = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/4/4e/Nether_Grasp.png"})
	Legendary.Cleanse:MenuElement({id = "Blind", name = "Blind", value = true, leftIcon = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/c/c7/Blinding_Dart.png"})
	Legendary.Cleanse:MenuElement({id = "Knockup", name = "Knockup", value = true, leftIcon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/4/44/Glacial_Fissure.png"})
	Legendary.Cleanse:MenuElement({id = "Knockback", name = "Knockback", value = true, leftIcon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/2/21/Emperor%27s_Divide.png"})

Callback.Add("Tick", function() Tick() end)
function Tick()
	target = LegendaryTarget(5500)
    if (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO]) or (_G.GOS and _G.GOS:GetMode() == "Combo") then
        Combo(target)
    elseif (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR]) or (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR]) or (_G.GOS and _G.GOS:GetMode() == "Clear") then
		Clear()
	elseif (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE]) or (_G.GOS and _G.GOS:GetMode() == "Flee") then
		Flee(target)
	end
		Killsteal(target)
		Cleanse()
		Shield()
		Heals()
		Potions()
end

function Combo()
    if target == nil then return end
	-- Items
	if Legendary.Combo.Items.T:Value() and GetItemSlot(myHero, 3077) >= 1 and myHero.attackData.state == STATE_WINDDOWN then 
		if Ready(GetItemSlot(myHero, 3077)) and target.distance <= 350 then
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3077)], target)
		end 
	end
	if Legendary.Combo.Items.RH:Value() and GetItemSlot(myHero, 3074) >= 1 and myHero.attackData.state == STATE_WINDDOWN then 
		if Ready(GetItemSlot(myHero, 3074)) and target.distance <= 350 then
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3074)], target)
		end 
	end
	if Legendary.Combo.Items.TH:Value() and GetItemSlot(myHero, 3748) >= 1 and myHero.attackData.state == STATE_WINDDOWN then 
		if Ready(GetItemSlot(myHero, 3748)) and target.distance <= 550 then
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3748)], target)
		end 
	end
	if Legendary.Combo.Items.FQC:Value() and GetItemSlot(myHero, 3092) >= 1 and CountEnemys(2000) >= Legendary.Combo.Items.FQCS.EN:Value() then 
		if Ready(GetItemSlot(myHero, 3092)) and target.distance <= 2000 then
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3092)])
		end 
	end
	if Legendary.Combo.Items.TAL:Value() and GetItemSlot(myHero, 3069) >= 1 and CountAlly(600) >= Legendary.Combo.Items.TALS.MA:Value() and CountEnemys(1500) >= Legendary.Combo.Items.TALS.EN:Value() then 
		if Ready(GetItemSlot(myHero, 3069)) and target.distance <= 1500 then
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3069)])
		end 
	end
	if Legendary.Combo.Items.EN:Value() and GetItemSlot(myHero, 3814) >= 1 and CountEnemys(1200) >= Legendary.Combo.Items.ENS.EN:Value() then 
		if Ready(GetItemSlot(myHero, 3814)) and target.distance <= 1200 then
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3814)])
		end 
	end
	if Legendary.Combo.Items.GLP:Value() and GetItemSlot(myHero, 3030) >= 1 and (target.health/target.maxHealth <= Legendary.Combo.Items.GLPS.EHP:Value() / 100) then 
		if Ready(GetItemSlot(myHero, 3030)) and target.distance <= 800 then
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3030)], target)
		end 
	end
	if Legendary.Combo.Items.HG:Value() and GetItemSlot(myHero, 3146) >= 1 and (target.health/target.maxHealth <= Legendary.Combo.Items.HGS.EHP:Value() / 100) then 
		if Ready(GetItemSlot(myHero, 3146)) and target.distance <= 700 then
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3146)], target)
		end 
	end
	if Legendary.Combo.Items.HP1:Value() and GetItemSlot(myHero, 3152) >= 1 and (target.health/target.maxHealth <= Legendary.Combo.Items.HP1S.EHP:Value() / 100) then 
		if Ready(GetItemSlot(myHero, 3152)) and target.distance <= 800 then
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3152)], target)
		end 
	end
	if Legendary.Combo.Items.BC:Value() and GetItemSlot(myHero, 3144) >= 1 and (target.health/target.maxHealth <= Legendary.Combo.Items.BCS.EHP:Value() / 100) and (myHero.health/myHero.maxHealth <= Legendary.Combo.Items.BCS.HP:Value() / 100) then 
		if Ready(GetItemSlot(myHero, 3144)) and target.distance <= 550 then
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3144)], target)
		end 
	end
	if Legendary.Combo.Items.BOTRK:Value() and GetItemSlot(myHero, 3153) >= 1 and (target.health/target.maxHealth <= Legendary.Combo.Items.BOTRKS.EHP:Value() / 100) and (myHero.health/myHero.maxHealth <= Legendary.Combo.Items.BOTRKS.HP:Value() / 100) then 
		if Ready(GetItemSlot(myHero, 3153)) and target.distance <= 550 then
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3153)], target)
		end 
	end
	if Legendary.Combo.Items.RO:Value() and GetItemSlot(myHero, 3143) >= 1 and (target.health/target.maxHealth <= Legendary.Combo.Items.ROS.EHP:Value() / 100) and (myHero.health/myHero.maxHealth <= Legendary.Combo.Items.ROS.HP:Value() / 100) then 
		if Ready(GetItemSlot(myHero, 3143)) and target.distance <= 500 then
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3143)])
		end 
	end
	if Legendary.Combo.Items.RG:Value() and GetItemSlot(myHero, 3800) >= 1 then 
		if Ready(GetItemSlot(myHero, 3800)) and target.distance >= Legendary.Combo.Items.RGS.ED:Value() then
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3800)])
		end 
	end
	if Legendary.Combo.Items.YG:Value() and GetItemSlot(myHero, 3142) >= 1 then 
		if Ready(GetItemSlot(myHero, 3142)) and target.distance >= Legendary.Combo.Items.YGS.ED:Value() then
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3142)])
		end 
	end
	if Legendary.Combo.Items.OHM:Value() and GetItemSlot(myHero, 3056) >= 1 then
		for i = 1, Game.TurretCount() do
		local turret = Game.Turret(i)
		local range = (turret.boundingRadius + 750 + myHero.boundingRadius / 2)
			if turret.valid and turret.isEnemy then
				if turret.distance <= range then
					if Ready(GetItemSlot(myHero, 3056)) and CountAlly(600) >= Legendary.Combo.Items.OHMS.MA:Value() then
						Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3056)])
					end
				end
			end
		end
	end
	-- Spells
	if Legendary.Combo.Spells.IG:Value() then 
   		if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and Ready(SUMMONER_1) then
       		if IsValidTarget(target, 600, true, myHero) and target.health/target.maxHealth <= Legendary.Combo.Spells.IGS.HP:Value()/100 then
            	Control.CastSpell(HK_SUMMONER_1, target)
       		end
		elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_2) then
        	if IsValidTarget(target, 600, true, myHero) and target.health/target.maxHealth <= Legendary.Combo.Spells.IGS.HP:Value()/100 then
           		 Control.CastSpell(HK_SUMMONER_2, target)
       		end
		end
	end
	if Legendary.Combo.Spells.EX:Value() then 
   		if myHero:GetSpellData(SUMMONER_1).name == "SummonerExhaust" and Ready(SUMMONER_1) then
       		if IsValidTarget(target, 650, true, myHero) and target.health/target.maxHealth <= Legendary.Combo.Spells.EXS.HP:Value()/100 then
            	Control.CastSpell(HK_SUMMONER_1, target)
       		end
		elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerExhaust" and Ready(SUMMONER_2) then
        	if IsValidTarget(target, 650, true, myHero) and target.health/target.maxHealth <= Legendary.Combo.Spells.EXS.HP:Value()/100 then
           		 Control.CastSpell(HK_SUMMONER_2, target)
       		end
		end
	end
	if Legendary.Combo.Spells.RS:Value() then 
   		if myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmiteDuel" and Ready(SUMMONER_1) and myHero:GetSpellData(SUMMONER_1).currentCd == 0 then
       		if IsValidTarget(target, 500, true, myHero) and target.health/target.maxHealth <= Legendary.Combo.Spells.RSS.HP:Value()/100 then
            	Control.CastSpell(HK_SUMMONER_1, target)
       		end
		elseif myHero:GetSpellData(SUMMONER_2).name == "S5_SummonerSmiteDuel" and Ready(SUMMONER_2) and myHero:GetSpellData(SUMMONER_2).currentCd == 0 then
        	if IsValidTarget(target, 500, true, myHero) and target.health/target.maxHealth <= Legendary.Combo.Spells.RSS.HP:Value()/100 then
           		 Control.CastSpell(HK_SUMMONER_2, target)
       		end
		end
	end
	if Legendary.Combo.Spells.BS:Value() then 
   		if myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmitePlayerGanker" and Ready(SUMMONER_1) and myHero:GetSpellData(SUMMONER_1).currentCd == 0 then
       		if IsValidTarget(target, 500, true, myHero) and target.health/target.maxHealth <= Legendary.Combo.Spells.BSS.HP:Value()/100 then
            	Control.CastSpell(HK_SUMMONER_1, target)
       		end
		elseif myHero:GetSpellData(SUMMONER_2).name == "S5_SummonerSmitePlayerGanker" and Ready(SUMMONER_2) and myHero:GetSpellData(SUMMONER_2).currentCd == 0 then
        	if IsValidTarget(target, 500, true, myHero) and target.health/target.maxHealth <= Legendary.Combo.Spells.BSS.HP:Value()/100 then
           		 Control.CastSpell(HK_SUMMONER_2, target)
       		end
		end
	end
end

function Shield()
	if target and target.distance <= 800 and Legendary.Shield.Spells.Barrier:Value() and (myHero.health/myHero.maxHealth <= Legendary.Shield.Spells.BarrierS.HP:Value() / 100) then 
		if myHero:GetSpellData(SUMMONER_1).name == "SummonerBarrier" and Ready(SUMMONER_1) then
			Control.CastSpell(HK_SUMMONER_1)
		elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerBarrier" and Ready(SUMMONER_2) then
			Control.CastSpell(HK_SUMMONER_2)
		end
	end
	if target and target.distance <= 800 and GetItemSlot(myHero, 3040) >= 1 then
		if Ready(GetItemSlot(myHero, 3040)) and Legendary.Shield.Items.SER:Value() then
			if (myHero.health/myHero.maxHealth <= Legendary.Shield.Items.SERS.HP:Value() / 100) then
				Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3040)])
			end
		end
	end
	if target and target.distance <= 800 and GetItemSlot(myHero, 3401) >= 1 then
		if Ready(GetItemSlot(myHero, 3401)) and Legendary.Shield.Items.FOM:Value() then
			if (myHero.health/myHero.maxHealth <= Legendary.Shield.Items.FOMS.HP:Value() / 100) then
				Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3401)],myHero.pos)
			end
		end
	end
	if target and target.distance <= 800 and GetItemSlot(myHero, 3190) >= 1 then
		if Ready(GetItemSlot(myHero, 3190)) and Legendary.Shield.Items.LOCK:Value() then
			if (myHero.health/myHero.maxHealth <= Legendary.Shield.Items.LOCKS.HP:Value() / 100) then
				Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3190)],myHero.pos)
			end
		end
	end
end


function Heals()
	if target and target.distance <= 800 and GetItemSlot(myHero, 3107) >= 1 then
		if Ready(GetItemSlot(myHero, 3107)) and Legendary.Heal.Items.RD:Value() then
			if (myHero.health/myHero.maxHealth <= Legendary.Heal.Items.RDS.HP:Value() / 100) then
				Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3107)],myHero.pos)
			end
		end
	end
	if target and target.distance <= 800 and Legendary.Heal.Spells.Heal:Value() and (myHero.health/myHero.maxHealth <= Legendary.Heal.Spells.HealS.HP:Value() / 100) then 
		if myHero:GetSpellData(SUMMONER_1).name == "SummonerHeal" and Ready(SUMMONER_1) then
			Control.CastSpell(HK_SUMMONER_1)
		elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerHeal" and Ready(SUMMONER_2) then
			Control.CastSpell(HK_SUMMONER_2)
		end
	end
end


function Potions()
	if target and target.distance <= 800 and GetItemSlot(myHero, 2003) >= 1 then
		if Ready(GetItemSlot(myHero, 2003)) and Legendary.Heal.Items.HP:Value() then
			if (myHero.health/myHero.maxHealth <= Legendary.Heal.Items.HPS.HP:Value() / 100) then
				Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 2003)])
			end
		end
	end
	if target and target.distance <= 800 and GetItemSlot(myHero, 2031) >= 1 then
		if Ready(GetItemSlot(myHero, 2031)) and Legendary.Heal.Items.RP:Value() then
			if (myHero.health/myHero.maxHealth <= Legendary.Heal.Items.RPS.HP:Value() / 100) then
				Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 2031)])
			end
		end
	end
	if target and target.distance <= 800 and GetItemSlot(myHero, 2010) >= 1 then
		if Ready(GetItemSlot(myHero, 2010)) and Legendary.Heal.Items.TB:Value() then
			if (myHero.health/myHero.maxHealth <= Legendary.Heal.Items.TBS.HP:Value() / 100) then
				Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 2010)])
			end
		end
	end
	if target and target.distance <= 800 and GetItemSlot(myHero, 2032) >= 1 then
		if Ready(GetItemSlot(myHero, 2032)) and Legendary.Heal.Items.HSP:Value() then
			if (myHero.health/myHero.maxHealth <= Legendary.Heal.Items.HSPS.HP:Value() / 100) then
				Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 2032)])
			end
		end
	end
	if target and target.distance <= 800 and GetItemSlot(myHero, 2033) >= 1 then
		if Ready(GetItemSlot(myHero, 2033)) and Legendary.Heal.Items.CP:Value() then
			if (myHero.health/myHero.maxHealth <= Legendary.Heal.Items.CPS.HP:Value() / 100) then
				Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 2033)])
			end
		end
	end
end

function Clear()
local GetEnemyMinions = GetEnemyMinions()
local minion = nil	
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		local Count = MinionsAround(minion.pos, 400 , minion.team)
		if Count >= 3 and minion.distance <= 400 then
			if Legendary.Clear.Items.T:Value() and GetItemSlot(myHero, 3077) >= 1 and myHero.attackData.state == STATE_WINDDOWN then 
				if Ready(GetItemSlot(myHero, 3077)) and minion.distance <= 350 then
					Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3077)], minion.pos)
				end 
			end
			if Legendary.Clear.Items.RH:Value() and GetItemSlot(myHero, 3074) >= 1 and myHero.attackData.state == STATE_WINDDOWN then 
				if Ready(GetItemSlot(myHero, 3074)) and minion.distance <= 350 then
					Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3074)], minion.pos)
				end 
			end
		end
	end
end

function Cleanse()
	for i = 0, myHero.buffCount do
	local buff = myHero:GetBuff(i);
		if buff.count > 0 then
			if ((buff.type == 5 and Legendary.Cleanse.Stun:Value())
			or (buff.type == 7 and  Legendary.Cleanse.Silence:Value())
			or (buff.type == 8 and  Legendary.Cleanse.Taunt:Value())
			or (buff.type == 9 and  Legendary.Cleanse.Polimorphy:Value())
			or (buff.type == 10 and  Legendary.Cleanse.Slow:Value())
			or (buff.type == 11 and  Legendary.Cleanse.Snare:Value())
			or (buff.type == 19 and  Legendary.Cleanse.Nearsight:Value())
			or (buff.type == 21 and  Legendary.Cleanse.Fear:Value())
			or (buff.type == 22 and  Legendary.Cleanse.Charm:Value()) 
			or (buff.type == 23 and  Legendary.Cleanse.Poison:Value()) 
			or (buff.type == 24 and  Legendary.Cleanse.Supression:Value())
			or (buff.type == 25 and  Legendary.Cleanse.Blind:Value())
			or (buff.type == 28 and  Legendary.Cleanse.Fear:Value())
			or (buff.type == 29 and  Legendary.Cleanse.Knockup:Value())
			or (buff.type == 30 and  Legendary.Cleanse.Knockback:Value())) then
				if Legendary.Cleanse.Cleanse:Value() then 
					if myHero:GetSpellData(SUMMONER_1).name == "SummonerBoost" and Ready(SUMMONER_1) then
						Control.CastSpell(HK_SUMMONER_1)
					elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerBoost" and Ready(SUMMONER_2) then
						Control.CastSpell(HK_SUMMONER_2)
					end
				end
				if Legendary.Cleanse.QSS:Value() and GetItemSlot(myHero, 3140) >= 1 then 
					if Ready(GetItemSlot(myHero, 3140)) then
						Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3140)])
					end 
				end
				if Legendary.Cleanse.MS:Value() and GetItemSlot(myHero, 3139) >= 1 then 
					if Ready(GetItemSlot(myHero, 3139)) then
						Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3139)])
					end 
				end
				if Legendary.Cleanse.MC:Value() and GetItemSlot(myHero, 3222) >= 1 then 
					if Ready(GetItemSlot(myHero, 3222)) then
						Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3222)])
					end 
				end
			end
		end
	end
end

function Flee()
	if target == nil then return end
	if Legendary.Combo.Items.FQC:Value() and GetItemSlot(myHero, 3092) >= 1 then 
		if Ready(GetItemSlot(myHero, 3092)) then
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3092)])
		end 
	end
	if Legendary.Combo.Items.TAL:Value() and GetItemSlot(myHero, 3069) >= 1 then 
		if Ready(GetItemSlot(myHero, 3069)) then
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3069)])
		end 
	end
	if Legendary.Combo.Items.EN:Value() and GetItemSlot(myHero, 3814) >= 1 then 
		if Ready(GetItemSlot(myHero, 3814)) then
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3814)])
		end 
	end
	if Legendary.Flee.Items.GLP:Value() and GetItemSlot(myHero, 3030) >= 1 then 
		if Ready(GetItemSlot(myHero, 3030)) and target.distance <= 800 then
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3030)], target)
		end 
	end
	if Legendary.Flee.Items.HG:Value() and GetItemSlot(myHero, 3146) >= 1 then 
		if Ready(GetItemSlot(myHero, 3146)) and target.distance <= 700 then
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3146)], target)
		end 
	end
	if Legendary.Flee.Items.HP1:Value() and GetItemSlot(myHero, 3152) >= 1 then 
		if Ready(GetItemSlot(myHero, 3152)) and target.distance <= 800 then
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3152)])
		end 
	end
	if Legendary.Flee.Items.BC:Value() and GetItemSlot(myHero, 3144) >= 1 then 
		if Ready(GetItemSlot(myHero, 3144)) and target.distance <= 550 then
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3144)], target)
		end 
	end
	if Legendary.Flee.Items.BOTRK:Value() and GetItemSlot(myHero, 3153) >= 1 then 
		if Ready(GetItemSlot(myHero, 3153)) and target.distance <= 550 then
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3153)], target)
		end 
	end
	if Legendary.Flee.Items.RO:Value() and GetItemSlot(myHero, 3143) >= 1 then 
		if Ready(GetItemSlot(myHero, 3143)) and target.distance <= 500 then
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3143)])
		end 
	end
	if Legendary.Flee.Items.RG:Value() and GetItemSlot(myHero, 3800) >= 1 then 
		if Ready(GetItemSlot(myHero, 3800)) and target.distance <= 700 then
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3800)])
		end 
	end
	if Legendary.Flee.Items.YG:Value() and GetItemSlot(myHero, 3142) >= 1 then 
		if Ready(GetItemSlot(myHero, 3142)) then
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3142)])
		end 
	end
	if Legendary.Flee.Spells.EX:Value() then 
   		if myHero:GetSpellData(SUMMONER_1).name == "SummonerExhaust" and Ready(SUMMONER_1) then
       		if IsValidTarget(target, 650, true, myHero) then
            	Control.CastSpell(HK_SUMMONER_1, target)
       		end
		elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerExhaust" and Ready(SUMMONER_2) then
        	if IsValidTarget(target, 650, true, myHero) then
           		 Control.CastSpell(HK_SUMMONER_2, target)
       		end
		end
	end
	if Legendary.Flee.Spells.BS:Value() then 
   		if myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmitePlayerGanker" and Ready(SUMMONER_1) then
       		if IsValidTarget(target, 500, true, myHero) then
            	Control.CastSpell(HK_SUMMONER_1, target)
       		end
		elseif myHero:GetSpellData(SUMMONER_2).name == "S5_SummonerSmitePlayerGanker" and Ready(SUMMONER_2) then
        	if IsValidTarget(target, 500, true, myHero) then
           		 Control.CastSpell(HK_SUMMONER_2, target)
       		end
		end
	end
end

function Killsteal()
	if target == nil then return end
	if Legendary.Killsteal.Items.RD:Value() and GetItemSlot(myHero, 3107) >= 1 then
		local RDdamage = target.maxHealth*0.1
		if Ready(GetItemSlot(myHero, 3107)) and target.distance <= 5500 then
			if RDdamage*0.9 >= HpPred(target, 1) then
				Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3107)], target)
			end
		end 
	end
	if Legendary.Killsteal.Items.BC:Value() and GetItemSlot(myHero, 3144) >= 1 then
		local BCdamage = CalcMagicalDamage(myHero, target, 100)
		if Ready(GetItemSlot(myHero, 3144)) and target.distance <= 550 then
			if BCdamage >= HpPred(target, 1) then
				Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3144)], target)
			end
		end 
	end
	if Legendary.Killsteal.Items.BOTRK:Value() and GetItemSlot(myHero, 3153) >= 1 then 
		local BOTRKdamage = CalcPhysicalDamage(myHero, target, target.maxHealth*0.1)
		if Ready(GetItemSlot(myHero, 3153)) and target.distance <= 550 then
			if BOTRKdamage >= HpPred(target, 1) then
				Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3153)], target)
			end
		end 
	end
	if Legendary.Killsteal.Spells.IG:Value() then 
		local IGdamage = 50+20*myHero.levelData.lvl - (target.hpRegen*3)
   		if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" then
       		if IsValidTarget(target, 600, true, myHero) and Ready(SUMMONER_1) then
				if IGdamage >= HpPred(target, 1) then
					Control.CastSpell(HK_SUMMONER_1, target)
				end
       		end
		elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" then
        	if IsValidTarget(target, 600, true, myHero) and Ready(SUMMONER_2) then
				if IGdamage >= HpPred(target, 1) then
					Control.CastSpell(HK_SUMMONER_2, target)
				end
       		end
		end
	end
	if Legendary.Killsteal.Spells.BS:Value() then 
		local BSdamage = 20+8*myHero.levelData.lvl
   		if myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmitePlayerGanker" and myHero:GetSpellData(SUMMONER_1).currentCd == 0 then
       		if IsValidTarget(target, 500, true, myHero) and Ready(SUMMONER_1) then
				if BSdamage >= HpPred(target, 1) then
					Control.CastSpell(HK_SUMMONER_1, target)
				end
       		end
		elseif myHero:GetSpellData(SUMMONER_2).name == "S5_SummonerSmitePlayerGanker" and myHero:GetSpellData(SUMMONER_2).currentCd == 0 then
        	if IsValidTarget(target, 500, true, myHero) and Ready(SUMMONER_2) then
				if BSdamage >= HpPred(target, 1) then
					Control.CastSpell(HK_SUMMONER_2, target)
				end
       		end
		end
	end
end
