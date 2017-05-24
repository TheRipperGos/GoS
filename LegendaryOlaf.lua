if myHero.charName ~= "Olaf" then return end

local Legendary = MenuElement({type = MENU, id = "Legendary", name = "Legendary " ..myHero.charName, leftIcon = "https://raw.githubusercontent.com/TheRipperGos/GoS/master/Sprites/"..myHero.charName..".png"})

Legendary:MenuElement({type = MENU, id = "Keys", name = "Key Settings"})
Legendary:MenuElement({type = MENU, id = "Combo", name = "Combo Settings"})
Legendary:MenuElement({type = MENU, id = "Harass", name = "Harass Settings"})
Legendary:MenuElement({type = MENU, id = "Clear", name = "Clear Settings"})
Legendary:MenuElement({type = MENU, id = "Lasthit", name = "Lasthit Settings"})
Legendary:MenuElement({type = MENU, id = "Flee", name = "Flee Settings"})
Legendary:MenuElement({type = MENU, id = "Cleanse", name = "Cleanse Settings"})
Legendary:MenuElement({type = MENU, id = "Killsteal", name = "Killsteal Settings"})
Legendary:MenuElement({type = MENU, id = "Drawing", name = "Drawing Settings"})

local function Ready(spell)
	return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana
end

function GetTarget(range)
	if _G.SDK then return _G.SDK.TargetSelector:GetTarget(1000, _G.SDK.DAMAGE_TYPE_PHYSICAL) elseif _G.GOS then return _G.GOS:GetTarget(1000,"AD")
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

function ValidTarget(unit, range, onScreen)
    local range = range or 20000
    
    return unit and unit.distance <= range and not unit.dead and unit.valid and unit.visible and unit.isTargetable and not (onScreen and not unit.pos2D.onScreen)
end

local _OnVision = {}
function OnVision(unit)
	if _OnVision[unit.networkID] == nil then _OnVision[unit.networkID] = {state = unit.visible , tick = GetTickCount(), pos = unit.pos} end
	if _OnVision[unit.networkID].state == true and not unit.visible then _OnVision[unit.networkID].state = false _OnVision[unit.networkID].tick = GetTickCount() end
	if _OnVision[unit.networkID].state == false and unit.visible then _OnVision[unit.networkID].state = true _OnVision[unit.networkID].tick = GetTickCount() end
	return _OnVision[unit.networkID]
end
Callback.Add("Tick", function() OnVisionF() end)
local visionTick = GetTickCount()
function OnVisionF()
	if GetTickCount() - visionTick > 100 then
		for i,v in pairs(GetEnemyHeroes()) do
			OnVision(v)
		end
	end
end

local _OnWaypoint = {}
function OnWaypoint(unit)
	if _OnWaypoint[unit.networkID] == nil then _OnWaypoint[unit.networkID] = {pos = unit.posTo , speed = unit.ms, time = Game.Timer()} end
	if _OnWaypoint[unit.networkID].pos ~= unit.posTo then 
		-- print("OnWayPoint:"..unit.charName.." | "..math.floor(Game.Timer()))
		_OnWaypoint[unit.networkID] = {startPos = unit.pos, pos = unit.posTo , speed = unit.ms, time = Game.Timer()}
			DelayAction(function()
				local time = (Game.Timer() - _OnWaypoint[unit.networkID].time)
				local speed = GetDistance2D(_OnWaypoint[unit.networkID].startPos,unit.pos)/(Game.Timer() - _OnWaypoint[unit.networkID].time)
				if speed > 1250 and time > 0 and unit.posTo == _OnWaypoint[unit.networkID].pos and GetDistance(unit.pos,_OnWaypoint[unit.networkID].pos) > 200 then
					_OnWaypoint[unit.networkID].speed = GetDistance2D(_OnWaypoint[unit.networkID].startPos,unit.pos)/(Game.Timer() - _OnWaypoint[unit.networkID].time)
					-- print("OnDash: "..unit.charName)
				end
			end,0.05)
	end
	return _OnWaypoint[unit.networkID]
end

local function GetPred(unit,speed,delay)
	local speed = speed or math.huge
	local delay = delay or 0.25
	local unitSpeed = unit.ms
	if OnWaypoint(unit).speed > unitSpeed then unitSpeed = OnWaypoint(unit).speed end
	if OnVision(unit).state == false then
		local unitPos = unit.pos + Vector(unit.pos,unit.posTo):Normalized() * ((GetTickCount() - OnVision(unit).tick)/1000 * unitSpeed)
		local predPos = unitPos + Vector(unit.pos,unit.posTo):Normalized() * (unitSpeed * (delay + (GetDistance(myHero.pos,unitPos)/speed)))
		if GetDistance(unit.pos,predPos) > GetDistance(unit.pos,unit.posTo) then predPos = unit.posTo end
		return predPos
	else
		if unitSpeed > unit.ms then
			local predPos = unit.pos + Vector(OnWaypoint(unit).startPos,unit.posTo):Normalized() * (unitSpeed * (delay + (GetDistance(myHero.pos,unit.pos)/speed)))
			if GetDistance(unit.pos,predPos) > GetDistance(unit.pos,unit.posTo) then predPos = unit.posTo end
			return predPos
		elseif IsImmobileTarget(unit) then
			return unit.pos
		else
			return unit:GetPrediction(speed,delay)
		end
	end
end

local function GetEnemyMinions(range)
    EnemyMinions = {}
    for i = 1, Game.MinionCount() do
        local Minion = Game.Minion(i)
        if Minion.isEnemy and ValidTarget(Minion, range, false, myHero) and not Minion.dead then
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
if Legendary.Keys.Smite:Value() == false then return end
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
									if (SData.ammo > 0) then
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

require "DamageLib"

class "Olaf"

function Olaf:__init()
    print("Legendary Olaf v1.0 Loaded")
    self:Menu()
	self:LoadSpells()
    Callback.Add("Draw", function() self:Draw() end)
    Callback.Add("Tick", function() self:Tick() end)
end

function Olaf:LoadSpells()
	Q = { range = 1000, speed = 1450, delay = 0.25 }
end

function Olaf:Menu()
    local Icon = { 	Q = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/6/61/Undertow.png",
					W = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/a/ad/Vicious_Strikes.png",
					E = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/2/25/Reckless_Swing.png",
					R = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/6/68/Ragnarok.png",
					T = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/e/e3/Tiamat_item.png",
					RH = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/e/e8/Ravenous_Hydra_item.png",
					TH = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/2/22/Titanic_Hydra_item.png",
					BC = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/4/44/Bilgewater_Cutlass_item.png",
					BOTRK = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/2/2f/Blade_of_the_Ruined_King_item.png",
					RO = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/0/08/Randuin%27s_Omen_item.png",
					RG = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/9/9f/Righteous_Glory_item.png",
					YG = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/4/41/Youmuu%27s_Ghostblade_item.png",
					QSS = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/f/f9/Quicksilver_Sash_item.png",
					MS = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/0/0a/Mercurial_Scimitar_item.png",
					IG = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/f/f4/Ignite.png",
					EX = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/4/4a/Exhaust.png",
					Cleanse = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/9/95/Cleanse.png",
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
	-- Keys --
	Legendary.Keys:MenuElement({id = "Smite", name = "Smite Usage", key = 77, toggle = true})
	Legendary.Keys:MenuElement({id = "SpellClear", name = "Spell Usage (Clear)", key = 65, toggle = true})
	Legendary.Keys:MenuElement({id = "SpellHarass", name = "Spell Usage (Harass)", key = 83, toggle = true})
	-- Combo --
	Legendary.Combo:MenuElement({id = "Q", name = "[Q] Undertow", value = true, leftIcon = Icon.Q})
	Legendary.Combo:MenuElement({id = "W", name = "[W] Vicious Strikes", value = true, leftIcon = Icon.W})
	Legendary.Combo:MenuElement({id = "E", name = "[E] Reckless Swing", value = true, leftIcon = Icon.E})
	Legendary.Combo:MenuElement({type = MENU, id = "Items", name = "Items"})
	Legendary.Combo.Items:MenuElement({id = "T", name = "Tiamat", value = true, leftIcon = Icon.T})
	Legendary.Combo.Items:MenuElement({id = "RH", name = "Ravenous Hydra", value = true, leftIcon = Icon.RH})
	Legendary.Combo.Items:MenuElement({id = "TH", name = "Titanic Hydra", value = true, leftIcon = Icon.TH})
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
	Legendary.Clear:MenuElement({id = "Q", name = "[Q] Undertow", value = true, leftIcon = Icon.Q})
	Legendary.Clear:MenuElement({id = "W", name = "[W] Vicious Strikes", value = true, leftIcon = Icon.W})
	Legendary.Clear:MenuElement({id = "E", name = "[E] Reckless Swing", value = true, leftIcon = Icon.E})
	Legendary.Clear:MenuElement({id = "Mana", name = "Min Mana to Clear (%)", value = 40, min = 0, max = 100})
	Legendary.Clear:MenuElement({id = "Life", name = "Min Life to [E] Clear (%)", value = 65, min = 0, max = 100})
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
	-- Lasthit --
	Legendary.Lasthit:MenuElement({id = "Q", name = "[Q] Undertow", value = true, leftIcon = Icon.Q})
	Legendary.Lasthit:MenuElement({id = "E", name = "[E] Reckless Swing", value = true, leftIcon = Icon.E})
	Legendary.Lasthit:MenuElement({id = "Mana", name = "Min Mana to [Q] Lasthit (%)", value = 40, min = 0, max = 100})
	Legendary.Lasthit:MenuElement({id = "Life", name = "Min Life to [E] Lasthit (%)", value = 65, min = 0, max = 100})
	-- Harass --
	Legendary.Harass:MenuElement({id = "Q", name = "[Q] Undertow", value = true, leftIcon = Icon.Q})
	Legendary.Harass:MenuElement({id = "E", name = "[E] Reckless Swing", value = true, leftIcon = Icon.E})
	Legendary.Harass:MenuElement({id = "Mana", name = "Min Mana to [Q] Harass (%)", value = 40, min = 0, max = 100})
	Legendary.Harass:MenuElement({id = "Life", name = "Min Life to [E] Harass (%)", value = 65, min = 0, max = 100})
	-- Flee --
	Legendary.Flee:MenuElement({id = "Q", name = "[Q] Undertow", value = true, leftIcon = Icon.Q})
	Legendary.Flee:MenuElement({type = MENU, id = "Items", name = "Items"})
	Legendary.Flee.Items:MenuElement({id = "BC", name = "Bilgewater Cutlass", value = true, leftIcon = Icon.BC})
	Legendary.Flee.Items:MenuElement({id = "BOTRK", name = "Blade of the Ruined King", value = true, leftIcon = Icon.BOTRK})
	Legendary.Flee.Items:MenuElement({id = "RO", name = "Randuin's Omen", value = true, leftIcon = Icon.RO})
	Legendary.Flee.Items:MenuElement({id = "RG", name = "Righteous Glory", value = true, leftIcon = Icon.RG})
	Legendary.Flee.Items:MenuElement({id = "YG", name = "Youmuu's Ghostblade", value = true, leftIcon = Icon.YG})
	Legendary.Flee:MenuElement({type = MENU, id = "Spells", name = "Summoner Spells"})
	Legendary.Flee.Spells:MenuElement({id = "EX", name = "Exhaust", value = true, leftIcon = Icon.EX})
	Legendary.Flee.Spells:MenuElement({id = "BS", name = "Chilling Smite", value = true, leftIcon = Icon.BS})
	-- Killsteal -- 
	Legendary.Killsteal:MenuElement({id = "Q", name = "[Q] Undertow", value = true, leftIcon = Icon.Q})
	Legendary.Killsteal:MenuElement({id = "E", name = "[E] Reckless Swing", value = true, leftIcon = Icon.E})
	Legendary.Killsteal:MenuElement({type = MENU, id = "Items", name = "Items"})
	Legendary.Killsteal.Items:MenuElement({id = "BC", name = "Bilgewater Cutlass", value = true, leftIcon = Icon.BC})
	Legendary.Killsteal.Items:MenuElement({id = "BOTRK", name = "Blade of the Ruined King", value = true, leftIcon = Icon.BOTRK})
	Legendary.Killsteal:MenuElement({type = MENU, id = "Spells", name = "Summoner Spells"})
	Legendary.Killsteal.Spells:MenuElement({id = "IG", name = "Ignite", value = true, leftIcon = Icon.IG})
	Legendary.Killsteal.Spells:MenuElement({id = "BS", name = "Chilling Smite", value = true, leftIcon = Icon.BS})
	-- Cleanse --
	Legendary.Cleanse:MenuElement({id = "R", name = "[R] Ragnarok", value = true, leftIcon = Icon.R})
	Legendary.Cleanse:MenuElement({id = "Cleanse", name = "Cleanse", value = true, leftIcon = Icon.Cleanse})
	Legendary.Cleanse:MenuElement({id = "QSS", name = "Quicksilver Sash", value = true, leftIcon = Icon.QSS})
	Legendary.Cleanse:MenuElement({id = "MS", name = "Mercurial Scimitar", value = true, leftIcon = Icon.MS})
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
	-- Drawings --
	Legendary.Drawing:MenuElement({id = "DrawQ", name = "Draw [Q] Range", value = true, leftIcon = Icon.Q})
	Legendary.Drawing:MenuElement({id = "ColorQ", name = "Color", color = Draw.Color(255, 0, 0, 255)})
	Legendary.Drawing:MenuElement({id = "DrawE", name = "Draw [E] Range", value = true, leftIcon = Icon.E})
	Legendary.Drawing:MenuElement({id = "ColorE", name = "Color", color = Draw.Color(255, 0, 0, 255)})
	Legendary.Drawing:MenuElement({id = "Smite", name = "Smite Status", value = true})
	Legendary.Drawing:MenuElement({id = "DrawClear", name = "Draw Spell (Clear) Status", value = true})
	Legendary.Drawing:MenuElement({id = "DrawHarass", name = "Draw Spell (Harass) Status", value = true})
end

function Olaf:Tick()
	local Combo = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO]) or (_G.GOS and _G.GOS:GetMode() == "Combo")
  	local LastHit = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT]) or (_G.GOS and _G.GOS:GetMode() == "Lasthit")
  	local Clear = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR]) or (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR]) or (_G.GOS and _G.GOS:GetMode() == "Clear")
  	local Harass = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS]) or (_G.GOS and _G.GOS:GetMode() == "Harass")
  	local Flee = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE]) or (_G.GOS and _G.GOS:GetMode() == "Flee")
    if myHero.dead then return end
    target = GetTarget(1000)
    if Combo then
        self:Combo(target)
    elseif target and Harass then
        self:Harass(target)
    elseif Clear then
		self:Clear()
	elseif LastHit then
		self:Lasthit()
	elseif Flee then
		self:Flee(target)
	end
		self:Killsteal(target)
		self:Cleanse()
end

function Olaf:Combo()
    if target == nil then return end
	-- Combo
    if Legendary.Combo.Q:Value() and Ready(_Q) then
		 if target.valid and not target.dead then
			Control.CastSpell(HK_Q,target:GetPrediction(Q.speed,Q.delay))
		end
	end
	if Legendary.Combo.W:Value() and Ready(_W) and target.distance < 250 then
		 if target.valid and not target.dead then
			Control.CastSpell(HK_W)
		end
	end
	if Legendary.Combo.E:Value() and Ready(_E) and target.distance < 325 then
		 if target.valid and not target.dead then
			Control.CastSpell(HK_E,target)
		end
	end
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
	-- Spells
	if Legendary.Combo.Spells.IG:Value() then 
   		if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and Ready(SUMMONER_1) then
       		if ValidTarget(target, 600, true, myHero) and target.health/target.maxHealth <= Legendary.Combo.Spells.IGS.HP:Value()/100 then
            	Control.CastSpell(HK_SUMMONER_1, target)
       		end
		elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_2) then
        	if ValidTarget(target, 600, true, myHero) and target.health/target.maxHealth <= Legendary.Combo.Spells.IGS.HP:Value()/100 then
           		 Control.CastSpell(HK_SUMMONER_2, target)
       		end
		end
	end
	if Legendary.Combo.Spells.EX:Value() then 
   		if myHero:GetSpellData(SUMMONER_1).name == "SummonerExhaust" and Ready(SUMMONER_1) then
       		if ValidTarget(target, 650, true, myHero) and target.health/target.maxHealth <= Legendary.Combo.Spells.EXS.HP:Value()/100 then
            	Control.CastSpell(HK_SUMMONER_1, target)
       		end
		elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerExhaust" and Ready(SUMMONER_2) then
        	if ValidTarget(target, 650, true, myHero) and target.health/target.maxHealth <= Legendary.Combo.Spells.EXS.HP:Value()/100 then
           		 Control.CastSpell(HK_SUMMONER_2, target)
       		end
		end
	end
	if Legendary.Combo.Spells.RS:Value() then 
   		if myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmiteDuel" and Ready(SUMMONER_1) then
       		if ValidTarget(target, 500, true, myHero) and target.health/target.maxHealth <= Legendary.Combo.Spells.RSS.HP:Value()/100 then
            	Control.CastSpell(HK_SUMMONER_1, target)
       		end
		elseif myHero:GetSpellData(SUMMONER_2).name == "S5_SummonerSmiteDuel" and Ready(SUMMONER_2) then
        	if ValidTarget(target, 500, true, myHero) and target.health/target.maxHealth <= Legendary.Combo.Spells.RSS.HP:Value()/100 then
           		 Control.CastSpell(HK_SUMMONER_2, target)
       		end
		end
	end
	if Legendary.Combo.Spells.BS:Value() then 
   		if myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmitePlayerGanker" and Ready(SUMMONER_1) then
       		if ValidTarget(target, 500, true, myHero) and target.health/target.maxHealth <= Legendary.Combo.Spells.BSS.HP:Value()/100 then
            	Control.CastSpell(HK_SUMMONER_1, target)
       		end
		elseif myHero:GetSpellData(SUMMONER_2).name == "S5_SummonerSmitePlayerGanker" and Ready(SUMMONER_2) then
        	if ValidTarget(target, 500, true, myHero) and target.health/target.maxHealth <= Legendary.Combo.Spells.BSS.HP:Value()/100 then
           		 Control.CastSpell(HK_SUMMONER_2, target)
       		end
		end
	end
end

function Olaf:Harass()
	if target == nil then return end
	if Legendary.Harass.Q:Value() and Ready(_Q) and myHero.mana/myHero.maxMana >= Legendary.Harass.Mana:Value()/100 then
		 if target.valid and not target.dead then
			Control.CastSpell(HK_Q,target:GetPrediction(Q.speed,Q.delay))
		end
	end
	if Legendary.Harass.E:Value() and Ready(_E) and myHero.health/myHero.maxHealth >= Legendary.Harass.Life:Value()/100 and target.distance < 325 then
		 if target.valid and not target.dead then
			Control.CastSpell(HK_E,target)
		end
	end
end

function Olaf:Clear()
local ClearQ = Legendary.Clear.Q:Value()
local ClearW = Legendary.Clear.W:Value()
local ClearE = Legendary.Clear.E:Value()
local ClearMana = Legendary.Clear.Mana:Value()
local ClearLife = Legendary.Clear.Life:Value()
local GetEnemyMinions = GetEnemyMinions()
local minion = nil	
	if ClearQ and Ready(_Q) and (myHero.mana/myHero.maxMana >= ClearMana / 100) then
		for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		local Count = MinionsAround(minion.pos, 1000 , minion.team)
			if Count >= 1 and minion.distance <= 1000 then
			local Qpos = minion:GetPrediction(1450, 0.25)
				Control.CastSpell(HK_Q, Qpos)
			end
		end
	end
	if ClearW and Ready(_W) and (myHero.mana/myHero.maxMana >= ClearMana / 100) then
		for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		local Count = MinionsAround(minion.pos, 325 , minion.team)
			if Count >= 3 and minion.distance <= 325 and minion.isEnemy then
				Control.CastSpell(HK_W)
			end
		end
	end
	if ClearE and Ready(_E) and (myHero.mana/myHero.maxMana >= ClearLife / 100) then
		for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
			if minion.distance <= 325 and minion.isEnemy then
				Control.CastSpell(HK_E, minion.pos)
			end
		end
	end
end

function Olaf:Lasthit()
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if  minion.team == 200 then
			local Qlevel = myHero:GetSpellData(_Q).level
			local Qdamage = (({70, 115, 160, 205, 250})[Qlevel] + myHero.totalDamage)
			if ValidTarget(minion,950) and myHero.pos:DistanceTo(minion.pos) < 950 and Ready(_Q) and (myHero.mana/myHero.maxMana >= Legendary.Lasthit.Mana:Value()/100 ) and minion.isEnemy then
				if Qdamage >= HpPred(minion, 0.5) then
				local Qpos = minion:GetPrediction(1450, 0.25)
					Control.CastSpell(HK_Q, Qpos)
				end
			end
			local Elevel = myHero:GetSpellData(_E).level
			local Edamage = (({70, 115, 160, 205, 250})[Elevel] + 0.4 * myHero.totalDamage)
			if ValidTarget(minion,325) and myHero.pos:DistanceTo(minion.pos) < 325 and Ready(_E) and (myHero.health/myHero.maxHealth >= Legendary.Lasthit.Life:Value()/100 ) and minion.isEnemy then
				if Edamage >= HpPred(minion, 0.5) then
					Control.CastSpell(HK_E,minion.pos)
				end
			end
      	end
	end
end

function Olaf:Cleanse()
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
					if myHero:GetSpellData(SUMMONER_1).name == "SummonerBoost" and Ready(SUMMONER_1) and not Ready(_R) then
						Control.CastSpell(HK_SUMMONER_1)
					elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerBoost" and Ready(SUMMONER_2) and not Ready(_R) then
						Control.CastSpell(HK_SUMMONER_2)
					end
				end
				if Legendary.Cleanse.R:Value() then
					if Ready(_R) then
						Control.CastSpell(HK_R)
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
			end
		end
	end
end

function Olaf:Flee()
	if target == nil then return end
	if Legendary.Flee.Q:Value() and Ready(_Q) then
		 if target.valid and not target.dead then
			Control.CastSpell(HK_Q,target:GetPrediction(Q.speed,Q.delay))
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
       		if ValidTarget(target, 650, true, myHero) then
            	Control.CastSpell(HK_SUMMONER_1, target)
       		end
		elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerExhaust" and Ready(SUMMONER_2) then
        	if ValidTarget(target, 650, true, myHero) then
           		 Control.CastSpell(HK_SUMMONER_2, target)
       		end
		end
	end
	if Legendary.Flee.Spells.BS:Value() then 
   		if myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmitePlayerGanker" and Ready(SUMMONER_1) then
       		if ValidTarget(target, 500, true, myHero) then
            	Control.CastSpell(HK_SUMMONER_1, target)
       		end
		elseif myHero:GetSpellData(SUMMONER_2).name == "S5_SummonerSmitePlayerGanker" and Ready(SUMMONER_2) then
        	if ValidTarget(target, 500, true, myHero) then
           		 Control.CastSpell(HK_SUMMONER_2, target)
       		end
		end
	end
end

function Olaf:Killsteal()
	if target == nil then return end
	local Qlevel = myHero:GetSpellData(_Q).level
	local Qdamage = CalcPhysicalDamage(myHero, target, (({70, 115, 160, 205, 250})[Qlevel] + myHero.totalDamage))
	if Legendary.Killsteal.Q:Value() and Ready(_Q) then
		if Qdamage >= HpPred(target, 1) then
			if target.valid and not target.dead then
				Control.CastSpell(HK_Q,target:GetPrediction(Q.speed,Q.delay))
			end
		end
	end
	local Elevel = myHero:GetSpellData(_E).level
	local Edamage = (({70, 115, 160, 205, 250})[Elevel] + 0.4 * myHero.totalDamage)
	if Legendary.Killsteal.E:Value() and Ready(_E) and target.distance < 325 then
		 if target.valid and not target.dead then
			if Edamage >= HpPred(target, 1) then
				Control.CastSpell(HK_E,target)
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
   		if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and Ready(SUMMONER_1) then
       		if ValidTarget(target, 600, true, myHero) then
				if IGdamage >= HpPred(target, 1) then
					Control.CastSpell(HK_SUMMONER_1, target)
				end
       		end
		elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_2) then
        	if ValidTarget(target, 600, true, myHero) then
				if IGdamage >= HpPred(target, 1) then
					Control.CastSpell(HK_SUMMONER_2, target)
				end
       		end
		end
	end
	if Legendary.Killsteal.Spells.BS:Value() then 
		local BSdamage = 20+8*myHero.levelData.lvl
   		if myHero:GetSpellData(SUMMONER_1).name == "S5_SummonerSmitePlayerGanker" and Ready(SUMMONER_1) then
       		if ValidTarget(target, 500, true, myHero) then
				if BSdamage >= HpPred(target, 1) then
					Control.CastSpell(HK_SUMMONER_1, target)
				end
       		end
		elseif myHero:GetSpellData(SUMMONER_2).name == "S5_SummonerSmitePlayerGanker" and Ready(SUMMONER_2) then
        	if ValidTarget(target, 500, true, myHero) then
				if BSdamage >= HpPred(target, 1) then
					Control.CastSpell(HK_SUMMONER_2, target)
				end
       		end
		end
	end
end

function Olaf:Draw()
	if myHero.dead then return end
	if Legendary.Drawing.DrawQ:Value() and Ready(_Q) then Draw.Circle(myHero.pos, 1000, 3, Legendary.Drawing.ColorQ:Value()) end
	if Legendary.Drawing.DrawE:Value() and Ready(_E) then Draw.Circle(myHero.pos, 325, 3, Legendary.Drawing.ColorE:Value()) end
	if Legendary.Drawing.Smite:Value() then
		local textPos = myHero.pos:To2D()
		if Legendary.Keys.Smite:Value() == true then
			Draw.Text("Smite Status: On", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 
		elseif Legendary.Keys.Smite:Value() == false then
			Draw.Text("Smite Status: Off", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 
		end
	end
	if Legendary.Drawing.DrawClear:Value() then
		local textPos = myHero.pos:To2D()
		if Legendary.Keys.SpellClear:Value() == true then
			Draw.Text("Spell Clear: On", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 000, 255, 000)) 
		elseif Legendary.Keys.SpellClear:Value() == false then
			Draw.Text("Spell Clear: Off", 20, textPos.x - 80, textPos.y + 60, Draw.Color(255, 000, 255, 000)) 
		end
	end
	if Legendary.Drawing.DrawHarass:Value() then
		local textPos = myHero.pos:To2D()
		if Legendary.Keys.SpellHarass:Value() == true then
			Draw.Text("Spell Harass: On", 20, textPos.x - 80, textPos.y + 80, Draw.Color(255, 000, 255, 000)) 
		elseif Legendary.Keys.SpellHarass:Value() == false then
			Draw.Text("Spell Harass: Off", 20, textPos.x - 80, textPos.y + 80, Draw.Color(255, 000, 255, 000)) 
		end
	end
end

if _G[myHero.charName]() then print("Thanks for using Legendary " ..myHero.charName.. " v1.0") end
