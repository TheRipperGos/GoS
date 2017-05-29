if myHero.charName ~= "Caitlyn" then return end
local Legendary = MenuElement({type = MENU, id = "Legendary", name = "Legendary " ..myHero.charName, leftIcon = "https://raw.githubusercontent.com/TheRipperGos/GoS/master/Sprites/"..myHero.charName..".png"})

Legendary:MenuElement({type = MENU, id = "Keys", name = "Key Settings"})
Legendary:MenuElement({type = MENU, id = "Combo", name = "Combo Settings"})
Legendary:MenuElement({type = MENU, id = "Harass", name = "Harass Settings"})
Legendary:MenuElement({type = MENU, id = "Clear", name = "Clear Settings"})
Legendary:MenuElement({type = MENU, id = "Lasthit", name = "Lasthit Settings"})
Legendary:MenuElement({type = MENU, id = "Flee", name = "Flee Settings"})
Legendary:MenuElement({type = MENU, id = "Cleanse", name = "Cleanse Settings"})
Legendary:MenuElement({type = MENU, id = "Killsteal", name = "Killsteal Settings"})
Legendary:MenuElement({type = MENU, id = "W", name = "Misc Settings"})
Legendary:MenuElement({type = MENU, id = "Drawing", name = "Drawing Settings"})
Legendary:MenuElement({type = MENU, id = "AS", name = "CastDelay Settings"})

local function Ready(spell)
	return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana
end

function KoreanTarget(range)
	if _G.SDK then return _G.SDK.TargetSelector:GetTarget(3000, _G.SDK.DAMAGE_TYPE_PHYSICAL) elseif _G.GOS then return _G.GOS:GetTarget(3000,"AD")
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
require "Collision"

_G.Spells = { 
        ["Caitlyn"] = {
            ["targetvalue"] = 3000,
            ["CaitlynPiltoverPeacemaker"] = {delay = 1, range = 1250, speed = 2200, width = 60, skillshot = true, collision = false},
            ["CaitlynYordleTrap"] = {delay = 0.25, range = 800, speed = 1450, skillshot = false, collision = false},
            ["CaitlynEntrapment"] = {delay = 0.25, range = 850, speed = 1600, width = 70, skillshot = true, collision = true},
    		["CaitlynAceintheHole"] = {delay = 1, range = (({2000,2500,3000})[myHero:GetSpellData(_R).level]), width = 60, speed = 3200, skillshot = false, collision = false}}
}

function KoreanCanCast(spell)
local target = KoreanTarget(Spells[myHero.charName]["targetvalue"])
local spellname = Spells[myHero.charName][tostring(myHero:GetSpellData(spell).name)]
    if target == nil then return end
    local Range = spellname.range * 0.969 or math.huge
    if spellname.skillshot == true and spellname.collision == true then 
        if IsValidTarget(target, Range , true) then 
            if not spellname.spellColl:__GetCollision(myHero, target, 5) then
                return true
            end
        end
    end
    if spellname.collision == false then
        return IsValidTarget(target, Range, true) 
    end
end 

function KoreanPred(target, spell)
local spellname = Spells[myHero.charName][tostring(myHero:GetSpellData(spell).name)]
local pos = GetPred(target, spellname.speed, spellname.delay + Game.Latency()/1000)
    if pos and GetDistance(pos,myHero.pos) < spellname.range then 
      return pos
    end
end     

local castSpell = {state = 0, tick = GetTickCount(), casting = GetTickCount() - 1000, mouse = mousePos}

local function KoreanCast(spell,pos,delay)
	if pos == nil then return end
local ticker = GetTickCount()

	if castSpell.state == 0 and ticker - castSpell.casting > delay + Game.Latency() and pos:ToScreen().onScreen then
		castSpell.state = 1
		castSpell.mouse = mousePos
		castSpell.tick = ticker
	end
	if castSpell.state == 1 then
		if ticker - castSpell.tick < Game.Latency() then
			Control.SetCursorPos(pos)
			Control.KeyDown(spell)
			Control.KeyUp(spell)
			castSpell.casting = ticker + delay
			DelayAction(function()
				if castSpell.state == 1 then
					Control.SetCursorPos(castSpell.mouse)
					castSpell.state = 0
				end
			end, Game.Latency()/1000)
		end
		if ticker - castSpell.casting > Game.Latency() then
			Control.SetCursorPos(castSpell.mouse)
			castSpell.state = 0
		end
	end
end

local function KoreanCast2(spell, pos, delay)
    local Cursor = Game.mousePos()
    if pos == nil then return end
        Control.SetCursorPos(pos)
        DelayAction(function() Control.KeyDown(spell) end,0.01) 
        DelayAction(function() Control.KeyUp(spell) end, (delay + Game.Latency()) / 1000) -- ˇ ˆ
end 

local function CountEnemys(range)
	local heroesCount = 0
	for i = 1,Game.HeroCount() do
		local enemy = Game.Hero(i)
		if  enemy.team ~= myHero.team and enemy.valid and enemy.pos:DistanceTo(myHero.pos) < 1500 then
		heroesCount = heroesCount + 1
		end
	end
	return heroesCount
end

class "Caitlyn"

function Caitlyn:__init()
    self:Menu()
    Callback.Add("Draw", function() self:Draw() end)
    Callback.Add("Tick", function() self:Tick() end)
	local _CaitlynE = Spells["Caitlyn"]["CaitlynEntrapment"]
	_CaitlynE.spellColl = Collision:SetSpell(_CaitlynE.range, _CaitlynE.speed, _CaitlynE.delay, _CaitlynE.width, true)
end

function Caitlyn:Menu()
    local Icon = { 	Q = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/f/fd/Piltover_Peacemaker.png",
					W = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/0/03/Yordle_Snap_Trap.png",
					E = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/0/0b/90_Caliber_Net.png",
					R = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/a/aa/Ace_in_the_Hole.png",
					BC = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/4/44/Bilgewater_Cutlass_item.png",
					BOTRK = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/2/2f/Blade_of_the_Ruined_King_item.png",
					YG = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/4/41/Youmuu%27s_Ghostblade_item.png",
					QSS = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/f/f9/Quicksilver_Sash_item.png",
					MS = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/0/0a/Mercurial_Scimitar_item.png",
					IG = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/f/f4/Ignite.png",
					EX = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/4/4a/Exhaust.png",
					Cleanse = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/9/95/Cleanse.png",
					}
	-- Keys --
	Legendary.Keys:MenuElement({id = "SpellClear", name = "Spell Usage (Clear)", key = 65, toggle = true})
	Legendary.Keys:MenuElement({id = "SpellHarass", name = "Spell Usage (Harass)", key = 83, toggle = true})
	-- Combo --
	Legendary.Combo:MenuElement({id = "Q", name = "[Q] Piltover Peacemaker", value = true, leftIcon = Icon.Q})
	Legendary.Combo:MenuElement({id = "W", name = "[W] Yordle Snap Trap", value = true, leftIcon = Icon.W})
	Legendary.Combo:MenuElement({id = "WA", name = "Min Stacks to [W] in combo", value = 2, min = 1, max = 3})
	Legendary.Combo:MenuElement({id = "WI", name = "Ignore Stack Check if X enemies", value = 3, min = 1, max = 5})
	Legendary.Combo:MenuElement({id = "E", name = "[E] 90 Caliber Net", value = true, leftIcon = Icon.E})
	Legendary.Combo:MenuElement({id = "R", name = "[R] Ace in the Hole", value = true, leftIcon = Icon.R})
	Legendary.Combo:MenuElement({id = "EQ", name = "[E]+[Q] Combo", value = true})
	Legendary.Combo:MenuElement({type = MENU, id = "Items", name = "Items"})
	Legendary.Combo.Items:MenuElement({id = "BC", name = "Bilgewater Cutlass", value = true, leftIcon = Icon.BC})
	Legendary.Combo.Items:MenuElement({type = MENU, id = "BCS", name = "Settings"})
	Legendary.Combo.Items.BCS:MenuElement({id = "HP", name = "Max HP (%)", value = 70, min = 0, max = 100})
	Legendary.Combo.Items.BCS:MenuElement({id = "EHP", name = "Max Enemy HP (%)", value = 70, min = 0, max = 100})
	Legendary.Combo.Items:MenuElement({id = "BOTRK", name = "Blade of the Ruined King", value = true, leftIcon = Icon.BOTRK})
	Legendary.Combo.Items:MenuElement({type = MENU, id = "BOTRKS", name = "Settings"})
	Legendary.Combo.Items.BOTRKS:MenuElement({id = "HP", name = "Max HP (%)", value = 70, min = 0, max = 100})
	Legendary.Combo.Items.BOTRKS:MenuElement({id = "EHP", name = "Max Enemy HP (%)", value = 70, min = 0, max = 100})
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
	-- Clear --
	Legendary.Clear:MenuElement({id = "Q", name = "[Q] Piltover Peacemaker", value = true, leftIcon = Icon.Q})
	Legendary.Clear:MenuElement({id = "Mana", name = "Min Mana to [Q] Clear (%)", value = 40, min = 0, max = 100})
	-- Lasthit --
	Legendary.Lasthit:MenuElement({id = "Q", name = "[Q] Piltover Peacemaker", value = true, leftIcon = Icon.Q})
	Legendary.Lasthit:MenuElement({id = "Mana", name = "Min Mana to [Q] Lasthit (%)", value = 40, min = 0, max = 100})
	-- Harass --
	Legendary.Harass:MenuElement({id = "Q", name = "[Q] Piltover Peacemaker", value = true, leftIcon = Icon.Q})
	Legendary.Harass:MenuElement({id = "Mana", name = "Min Mana to [Q] Harass (%)", value = 40, min = 0, max = 100})
	-- Auto W --
	Legendary.W:MenuElement({id = "W", name = "Auto [W] if CC", value = true, leftIcon = Icon.W})
	-- Flee --
	Legendary.Flee:MenuElement({id = "E", name = "[E] Piltover Peacemaker", value = true, leftIcon = Icon.E})
	Legendary.Flee:MenuElement({type = MENU, id = "Items", name = "Items"})
	Legendary.Flee.Items:MenuElement({id = "BC", name = "Bilgewater Cutlass", value = true, leftIcon = Icon.BC})
	Legendary.Flee.Items:MenuElement({id = "BOTRK", name = "Blade of the Ruined King", value = true, leftIcon = Icon.BOTRK})
	Legendary.Flee.Items:MenuElement({id = "YG", name = "Youmuu's Ghostblade", value = true, leftIcon = Icon.YG})
	Legendary.Flee:MenuElement({type = MENU, id = "Spells", name = "Summoner Spells"})
	Legendary.Flee.Spells:MenuElement({id = "EX", name = "Exhaust", value = true, leftIcon = Icon.EX})
	-- Killsteal -- 
	Legendary.Killsteal:MenuElement({id = "Q", name = "[Q] Piltover Peacemaker", value = true, leftIcon = Icon.Q})
	Legendary.Killsteal:MenuElement({id = "R", name = "[R] Ace in the Hole", value = true, leftIcon = Icon.R})
	Legendary.Killsteal:MenuElement({type = MENU, id = "Items", name = "Items"})
	Legendary.Killsteal.Items:MenuElement({id = "BC", name = "Bilgewater Cutlass", value = true, leftIcon = Icon.BC})
	Legendary.Killsteal.Items:MenuElement({id = "BOTRK", name = "Blade of the Ruined King", value = true, leftIcon = Icon.BOTRK})
	Legendary.Killsteal:MenuElement({type = MENU, id = "Spells", name = "Summoner Spells"})
	Legendary.Killsteal.Spells:MenuElement({id = "IG", name = "Ignite", value = true, leftIcon = Icon.IG})
	-- Cleanse --
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
	Legendary.Cleanse:MenuElement({id = "Knockup", name = "Knockup", value = false, leftIcon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/4/44/Glacial_Fissure.png"})
	Legendary.Cleanse:MenuElement({id = "Knockback", name = "Knockback", value = false, leftIcon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/2/21/Emperor%27s_Divide.png"})
	-- Drawings --
	Legendary.Drawing:MenuElement({id = "DrawQ", name = "Draw [Q] Range", value = true, leftIcon = Icon.Q})
	Legendary.Drawing:MenuElement({id = "ColorQ", name = "Color", color = Draw.Color(255, 0, 0, 255)})
	Legendary.Drawing:MenuElement({id = "DrawE", name = "Draw [E] Range", value = true, leftIcon = Icon.E})
	Legendary.Drawing:MenuElement({id = "ColorE", name = "Color", color = Draw.Color(255, 0, 0, 255)})
	Legendary.Drawing:MenuElement({id = "DrawClear", name = "Draw Spell (Clear) Status", value = true})
	Legendary.Drawing:MenuElement({id = "DrawHarass", name = "Draw Spell (Harass) Status", value = true})
	-- Delay --
	Legendary.AS:MenuElement({id = "QAS", name = "[Q] Delay Value", value = 250, min = 1, max = 1000, step = 10, leftIcon = Icon.Q})
	Legendary.AS:MenuElement({id = "EAS", name = "[E] Delay Value", value = 250, min = 1, max = 1000, step = 10, leftIcon = Icon.E})
end

function Caitlyn:Tick()
	local Combo = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO]) or (_G.GOS and _G.GOS:GetMode() == "Combo")
  	local LastHit = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT]) or (_G.GOS and _G.GOS:GetMode() == "Lasthit")
  	local Clear = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR]) or (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR]) or (_G.GOS and _G.GOS:GetMode() == "Clear")
  	local Harass = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS]) or (_G.GOS and _G.GOS:GetMode() == "Harass")
  	local Flee = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE]) or (_G.GOS and _G.GOS:GetMode() == "Flee")
    if myHero.dead then return end
    target = KoreanTarget(3000)
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
		self:AutoW(target)
end

function Caitlyn:Combo()
    if target == nil then return end
	-- Combo
	local AAdmg = CalcPhysicalDamage(myHero, target, myHero.totalDamage)
	if Legendary.Combo.R:Value() and Ready(_R) then
		local Rlevel = myHero:GetSpellData(_R).level
		local Rrange = (({2000,2500,3000})[Rlevel])
		local Rdamage = CalcPhysicalDamage(myHero, target, (({250, 475, 700})[Rlevel] + 2 * myHero.totalDamage))
		if Rdamage * 0.9 >= HpPred(target, 1) and myHero.pos:DistanceTo(target.pos) < Rrange and myHero.pos:DistanceTo(target.pos) > 1200 and not Rdamage * 0.5 >= HpPred(target, 1) then
			CastSpellMM(HK_R,target.pos,Rrange,0)
		end
	end
	if Legendary.Combo.EQ:Value() and Ready(_E) and Ready(_Q) and myHero.pos:DistanceTo(target.pos) < 775 and AAdmg*2 <= HpPred(target, 1) then
		 if KoreanCanCast(_E) and Ready(_E) then
                KoreanCast(HK_E, KoreanPred(target, _E), Legendary.AS.EAS:Value())
			if KoreanCanCast(_Q) and Ready(_Q) then
					KoreanCast(HK_Q, KoreanPred(target, _Q), Legendary.AS.QAS:Value())
			end
		end
	end
    if Legendary.Combo.Q:Value() and Ready(_Q) and AAdmg <= HpPred(target, 1) then
		 if KoreanCanCast(_Q) then
                KoreanCast(HK_Q, KoreanPred(target, _Q), Legendary.AS.QAS:Value())
		end
	end
	if Legendary.Combo.E:Value() and Ready(_E) and myHero.pos:DistanceTo(target.pos) < 775 then
		 if KoreanCanCast(_E) then
                KoreanCast(HK_E, KoreanPred(target, _E), Legendary.AS.EAS:Value())
		end
	end
	if Legendary.Combo.W:Value() and Ready(_W) and target.distance < 800 and myHero:GetSpellData(_W).ammo >= Legendary.Combo.WA:Value() then
		 if target.valid and not target.dead then
			Control.CastSpell(HK_W,target)
		end
	end
	if Legendary.Combo.W:Value() and Ready(_W) and target.distance < 800 and CountEnemys(1500) >= Legendary.Combo.WI:Value() and myHero:GetSpellData(_W).ammo >= 1 then
		 if target.valid and not target.dead then
			Control.CastSpell(HK_W,target)
		end
	end
	-- Items
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
	if Legendary.Combo.Items.YG:Value() and GetItemSlot(myHero, 3142) >= 1 then 
		if Ready(GetItemSlot(myHero, 3142)) and target.distance >= Legendary.Combo.Items.YGS.ED:Value() then
			Control.CastSpell(ItemHotKey[GetItemSlot(myHero, 3142)])
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
end

function Caitlyn:Harass()
	if Legendary.Keys.SpellHarass:Value() == false then return end
	if target == nil then return end
	if Legendary.Harass.Q:Value() and Ready(_Q) and myHero.mana/myHero.maxMana >= Legendary.Harass.Mana:Value()/100 then
		 if KoreanCanCast(_Q) then
                KoreanCast(HK_Q, KoreanPred(target, _Q), Legendary.AS.QAS:Value())
		end
	end
end

function Caitlyn:Clear()
if Legendary.Keys.SpellClear:Value() == false then return end
local ClearQ = Legendary.Clear.Q:Value()
local ClearMana = Legendary.Clear.Mana:Value()
local GetEnemyMinions = GetEnemyMinions()
local minion = nil	
	if ClearQ and Ready(_Q) and (myHero.mana/myHero.maxMana >= ClearMana / 100) then
		for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
			if minion:GetCollision(60,2200,0.25) >= 3 and minion.distance <= 1250 and minion.team == 200 then
			local Qpos = minion:GetPrediction(1250, 0.25)
				Control.CastSpell(HK_Q, Qpos)
			end
		end
	end
	if ClearQ and Ready(_Q) and (myHero.mana/myHero.maxMana >= ClearMana / 100) then
		for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
			if  minion.distance <= 1250 and minion.team == 300 then
			local Qpos = minion:GetPrediction(1250, 0.25)
				Control.CastSpell(HK_Q, Qpos)
			end
		end
	end
end

function Caitlyn:Lasthit()
	if Legendary.Lasthit.Q:Value() == false then return end
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if minion.team == 200 then
			local Qlevel = myHero:GetSpellData(_Q).level
			local Qdamage = (({30, 70, 110, 150, 190})[Qlevel] + ({1.3, 1.4, 1.5, 1.6, 1.7})[Qlevel] * myHero.totalDamage)
			if IsValidTarget(minion,1250) and myHero.pos:DistanceTo(minion.pos) < 1250 and Ready(_Q) and (myHero.mana/myHero.maxMana >= Legendary.Lasthit.Mana:Value()/100 ) then
				if Qdamage >= HpPred(minion, 0.5) then
				local Qpos = minion:GetPrediction(1250, 0.25)
					Control.CastSpell(HK_Q, Qpos)
				end
			end
      	end
	end
end

function Caitlyn:Cleanse()
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
			end
		end
	end
end

function Caitlyn:AutoW()
	if myHero:GetSpellData(_W).ammo == 0 then return end
	if target == nil then return end
	for i = 0, target.buffCount do
	local buff = target:GetBuff(i);
		if buff.count > 0 then
			if ((buff.type == 5)
			or (buff.type == 11)
			or (buff.type == 24)
			or (buff.type == 29)) then
				if Legendary.W.W:Value() and target.distance <= 775 then 
					if Ready(_W) then
						Control.CastSpell(HK_W,target)
					end 
				end
			end
		end
	end
end

function Caitlyn:Flee()
	if target == nil then return end
	if Legendary.Flee.E:Value() and Ready(_E) and myHero.pos:DistanceTo(target.pos) < 900 then
		 if KoreanCanCast(_E) then
                KoreanCast(HK_E, KoreanPred(target, _E), Legendary.AS.EAS:Value())
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
end

function Caitlyn:Killsteal()
	if target == nil then return end
	if Legendary.Killsteal.R:Value() and Ready(_R) then
		local Rlevel = myHero:GetSpellData(_R).level
		local Rrange = (({2000,2500,3000})[Rlevel])
		local Rdamage = CalcPhysicalDamage(myHero, target, (({250, 475, 700})[Rlevel] + 2 * myHero.totalDamage))
		if Rdamage * 0.9 >= HpPred(target, 1) and myHero.pos:DistanceTo(target.pos) < Rrange and myHero.pos:DistanceTo(target.pos) > 1700 then
			CastSpellMM(HK_R,target.pos,Rrange,0)
		end
	end
	if Legendary.Killsteal.R:Value() and Ready(_R) then
		local Rlevel = myHero:GetSpellData(_R).level
		local Rrange = (({2000,2500,3000})[Rlevel])
		local Rdamage = CalcPhysicalDamage(myHero, target, (({250, 475, 700})[Rlevel] + 2 * myHero.totalDamage))
		if Rdamage * 0.9 >= HpPred(target, 1) and myHero.pos:DistanceTo(target.pos) < Rrange and myHero.pos:DistanceTo(target.pos) > 1200 and Rdamage * 0.5 <= HpPred(target, 1) then
			CastSpellMM(HK_R,target.pos,Rrange,0)
		end
	end
	if Legendary.Killsteal.Q:Value() and Ready(_Q) then
		local Qlevel = myHero:GetSpellData(_Q).level
		local Qdamage = CalcPhysicalDamage(myHero, target, (({30, 70, 110, 150, 190})[Qlevel] + ({1.3, 1.4, 1.5, 1.6, 1.7})[Qlevel] * myHero.totalDamage))
		if Qdamage >= HpPred(target, 1) and not CalcPhysicalDamage(myHero, target, myHero.totalDamage * 2) >= HpPred(target, 1) then
			if KoreanCanCast(_Q) then
                KoreanCast(HK_Q, KoreanPred(target, _Q), Legendary.AS.QAS:Value())
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
       		if IsValidTarget(target, 600, true, myHero) then
				if IGdamage >= HpPred(target, 1) then
					Control.CastSpell(HK_SUMMONER_1, target)
				end
       		end
		elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_2) then
        	if IsValidTarget(target, 600, true, myHero) then
				if IGdamage >= HpPred(target, 1) then
					Control.CastSpell(HK_SUMMONER_2, target)
				end
       		end
		end
	end
end

function Caitlyn:Draw()
	if myHero.dead then return end
	if Legendary.Drawing.DrawQ:Value() and Ready(_Q) then Draw.Circle(myHero.pos, 1250, 3, Legendary.Drawing.ColorQ:Value()) end
	if Legendary.Drawing.DrawE:Value() and Ready(_E) then Draw.Circle(myHero.pos, 950, 3, Legendary.Drawing.ColorE:Value()) end
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
