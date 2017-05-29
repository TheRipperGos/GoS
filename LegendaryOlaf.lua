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
Legendary:MenuElement({type = MENU, id = "AS", name = "CastDelay Settings"})

local function Ready(spell)
	return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana
end

function KoreanTarget(range)
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

require "DamageLib"
require "Collision"

_G.Spells = { 
        ["Olaf"] = {
            ["targetvalue"] = 1000,
            ["OlafAxeThrowCast"] = {delay = 0.25, range = 1000, speed = 1450, width = 70, skillshot = true, collision = false},
            ["OlafFrenziedStrikes"] = {delay = 0.25, skillshot = false, collision = false},
            ["OlafRecklessStrike"] = {delay = 0.25, range = 325, speed = 1600, skillshot = false, collision = false},
    		["OlafRagnarok"] = {delay = 0, skillshot = false, collision = false}}
}
--KoreanCast
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

class "Olaf"

function Olaf:__init()
    print("Legendary Olaf v1.0 Loaded")
    self:Menu()
    Callback.Add("Draw", function() self:Draw() end)
    Callback.Add("Tick", function() self:Tick() end)
end

function Olaf:Menu()
    local Icon = { 	Q = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/6/61/Undertow.png",
					W = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/a/ad/Vicious_Strikes.png",
					E = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/2/25/Reckless_Swing.png",
					R = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/6/68/Ragnarok.png",
					}
	-- Keys --
	Legendary.Keys:MenuElement({id = "SpellClear", name = "Spell Usage (Clear)", key = 65, toggle = true})
	Legendary.Keys:MenuElement({id = "SpellHarass", name = "Spell Usage (Harass)", key = 83, toggle = true})
	-- Combo --
	Legendary.Combo:MenuElement({id = "Q", name = "[Q] Undertow", value = true, leftIcon = Icon.Q})
	Legendary.Combo:MenuElement({id = "W", name = "[W] Vicious Strikes", value = true, leftIcon = Icon.W})
	Legendary.Combo:MenuElement({id = "E", name = "[E] Reckless Swing", value = true, leftIcon = Icon.E})
	-- Clear --
	Legendary.Clear:MenuElement({id = "Q", name = "[Q] Undertow", value = true, leftIcon = Icon.Q})
	Legendary.Clear:MenuElement({id = "W", name = "[W] Vicious Strikes", value = true, leftIcon = Icon.W})
	Legendary.Clear:MenuElement({id = "E", name = "[E] Reckless Swing", value = true, leftIcon = Icon.E})
	Legendary.Clear:MenuElement({id = "Mana", name = "Min Mana to Clear (%)", value = 40, min = 0, max = 100})
	Legendary.Clear:MenuElement({id = "Life", name = "Min Life to [E] Clear (%)", value = 65, min = 0, max = 100})
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
	-- Killsteal -- 
	Legendary.Killsteal:MenuElement({id = "Q", name = "[Q] Undertow", value = true, leftIcon = Icon.Q})
	Legendary.Killsteal:MenuElement({id = "E", name = "[E] Reckless Swing", value = true, leftIcon = Icon.E})
	-- Cleanse --
	Legendary.Cleanse:MenuElement({id = "R", name = "[R] Ragnarok", value = true, leftIcon = Icon.R})
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
	Legendary.Drawing:MenuElement({id = "DrawClear", name = "Draw Spell (Clear) Status", value = true})
	Legendary.Drawing:MenuElement({id = "DrawHarass", name = "Draw Spell (Harass) Status", value = true})
	-- Delay --
	Legendary.AS:MenuElement({id = "QAS", name = "[Q] Delay Value", value = 250, min = 1, max = 1000, step = 10, leftIcon = Icon.Q})
end

function Olaf:Tick()
	local Combo = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO]) or (_G.GOS and _G.GOS:GetMode() == "Combo")
  	local LastHit = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT]) or (_G.GOS and _G.GOS:GetMode() == "Lasthit")
  	local Clear = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR]) or (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR]) or (_G.GOS and _G.GOS:GetMode() == "Clear")
  	local Harass = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS]) or (_G.GOS and _G.GOS:GetMode() == "Harass")
  	local Flee = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE]) or (_G.GOS and _G.GOS:GetMode() == "Flee")
    if myHero.dead then return end
    target = KoreanTarget(1500)
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
    if Legendary.Combo.Q:Value() and Ready(_Q) then
		 if KoreanCanCast(_Q) then
                KoreanCast(HK_Q, KoreanPred(target, _Q), Legendary.AS.QAS:Value())
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
end

function Olaf:Harass()
	if Legendary.Keys.SpellHarass:Value() == false then return end
	if target == nil then return end
	if Legendary.Harass.Q:Value() and Ready(_Q) and myHero.mana/myHero.maxMana >= Legendary.Harass.Mana:Value()/100 then
		 if KoreanCanCast(_Q) then
                KoreanCast(HK_Q, KoreanPred(target, _Q), Legendary.AS.QAS:Value())
		end
	end
	if Legendary.Harass.E:Value() and Ready(_E) and myHero.health/myHero.maxHealth >= Legendary.Harass.Life:Value()/100 and target.distance < 325 then
		 if target.valid and not target.dead then
			Control.CastSpell(HK_E,target)
		end
	end
end

function Olaf:Clear()
if Legendary.Keys.SpellClear:Value() == false then return end
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
			local Qdamage = (({70, 115, 160, 205, 250})[Qlevel] + myHero.bonusDamage)
			if IsValidTarget(minion,950) and myHero.pos:DistanceTo(minion.pos) < 950 and Ready(_Q) and (myHero.mana/myHero.maxMana >= Legendary.Lasthit.Mana:Value()/100 ) and minion.isEnemy then
				if Qdamage >= HpPred(minion, 0.5) then
				local Qpos = minion:GetPrediction(1450, 0.25)
					Control.CastSpell(HK_Q, Qpos)
				end
			end
			local Elevel = myHero:GetSpellData(_E).level
			local Edamage = (({70, 115, 160, 205, 250})[Elevel] + 0.4 * myHero.totalDamage)
			if IsValidTarget(minion,325) and myHero.pos:DistanceTo(minion.pos) < 325 and Ready(_E) and (myHero.health/myHero.maxHealth >= Legendary.Lasthit.Life:Value()/100 ) and minion.isEnemy then
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
				if Legendary.Cleanse.R:Value() then
					if Ready(_R) then
						Control.CastSpell(HK_R)
					end
				end
			end
		end
	end
end

function Olaf:Flee()
	if target == nil then return end
	if Legendary.Flee.Q:Value() and Ready(_Q) then
		 if KoreanCanCast(_Q) then
                KoreanCast(HK_Q, KoreanPred(target, _Q), Legendary.AS.QAS:Value())
		end
	end
end

function Olaf:Killsteal()
	if target == nil then return end
	local Qlevel = myHero:GetSpellData(_Q).level
	local Qdamage = CalcPhysicalDamage(myHero, target, (({70, 115, 160, 205, 250})[Qlevel] + myHero.bonusDamage))
	if Legendary.Killsteal.Q:Value() and Ready(_Q) then
		if Qdamage >= HpPred(target, 1) then
			if KoreanCanCast(_Q) then
                KoreanCast(HK_Q, KoreanPred(target, _Q), Legendary.AS.QAS:Value())
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
end

function Olaf:Draw()
	if myHero.dead then return end
	if Legendary.Drawing.DrawQ:Value() and Ready(_Q) then Draw.Circle(myHero.pos, 1000, 3, Legendary.Drawing.ColorQ:Value()) end
	if Legendary.Drawing.DrawE:Value() and Ready(_E) then Draw.Circle(myHero.pos, 325, 3, Legendary.Drawing.ColorE:Value()) end
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

if _G[myHero.charName]() then print("Thanks for using Legendary " ..myHero.charName.. " v1.2") end
