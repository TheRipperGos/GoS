if myHero.charName ~= "MasterYi" then return end
local Legendary = MenuElement({type = MENU, id = "Legendary", name = "Legendary " ..myHero.charName, leftIcon = "https://raw.githubusercontent.com/TheRipperGos/GoS/master/Sprites/"..myHero.charName..".png"})

Legendary:MenuElement({type = MENU, id = "Keys", name = "Key Settings"})
Legendary:MenuElement({type = MENU, id = "Combo", name = "Combo Settings"})
Legendary:MenuElement({type = MENU, id = "Harass", name = "Harass Settings"})
Legendary:MenuElement({type = MENU, id = "Clear", name = "Clear Settings"})
Legendary:MenuElement({type = MENU, id = "Flee", name = "Flee Settings"})
Legendary:MenuElement({type = MENU, id = "Killsteal", name = "Killsteal Settings"})
Legendary:MenuElement({type = MENU, id = "Drawing", name = "Drawing Settings"})

local function Ready(spell)
	return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana
end

function LegendaryTarget(range)
	if _G.SDK then return _G.SDK.TargetSelector:GetTarget(900, _G.SDK.DAMAGE_TYPE_PHYSICAL) elseif _G.GOS then return _G.GOS:GetTarget(900,"AD")
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

local sqrt = math.sqrt 
local function GetDistance(p1,p2)
	return sqrt((p2.x - p1.x)*(p2.x - p1.x) + (p2.y - p1.y)*(p2.y - p1.y) + (p2.z - p1.z)*(p2.z - p1.z))
end

local function GetDistance2D(p1,p2)
	return sqrt((p2.x - p1.x)*(p2.x - p1.x) + (p2.y - p1.y)*(p2.y - p1.y))
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
        if m and m.team == 200 and not m.dead and m.pos:DistanceTo(pos, m.pos) < 550 then
            Count = Count + 1
        end
    end
    return Count
end

require "DamageLib"

class "MasterYi"

function MasterYi:__init()
    self:Menu()
    Callback.Add("Draw", function() self:Draw() end)
    Callback.Add("Tick", function() self:Tick() end)
end

function MasterYi:Menu()
    local Icon = { 	Q = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/e/e6/Alpha_Strike.png",
					W = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/6/61/Meditate.png",
					E = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/7/74/Wuju_Style.png",
					R = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/3/34/Highlander.png",
					}
	-- Keys --
	Legendary.Keys:MenuElement({id = "SpellClear", name = "Spell Usage (Clear)", key = 65, toggle = true})
	Legendary.Keys:MenuElement({id = "SpellHarass", name = "Spell Usage (Harass)", key = 83, toggle = true})
	-- Combo --
	Legendary.Combo:MenuElement({id = "Q", name = "[Q] Alpha Strike", value = true, leftIcon = Icon.Q})
	Legendary.Combo:MenuElement({id = "W", name = "[W] Meditate", value = true, leftIcon = Icon.W})
	Legendary.Combo:MenuElement({id = "E", name = "[E] Wuju Style", value = true, leftIcon = Icon.E})
	Legendary.Combo:MenuElement({id = "R", name = "[R] Highlander", value = true, leftIcon = Icon.R})
	-- Clear --
	Legendary.Clear:MenuElement({id = "Q", name = "[Q] Alpha Strike", value = true, leftIcon = Icon.Q})
	Legendary.Clear:MenuElement({id = "Mana", name = "Min Mana to [Q] Clear (%)", value = 40, min = 0, max = 100})
	-- Harass --
	Legendary.Harass:MenuElement({id = "Q", name = "[Q] Alpha Strike", value = true, leftIcon = Icon.Q})
	Legendary.Harass:MenuElement({id = "Mana", name = "Min Mana to [Q] Harass (%)", value = 40, min = 0, max = 100})
	-- Flee --
	Legendary.Flee:MenuElement({id = "R", name = "[R] Highlander", value = true, leftIcon = Icon.R})
	-- Killsteal -- 
	Legendary.Killsteal:MenuElement({id = "Q", name = "[Q] Alpha Strike", value = true, leftIcon = Icon.Q})
	-- Drawings --
	Legendary.Drawing:MenuElement({id = "DrawQ", name = "Draw [Q] Range", value = true, leftIcon = Icon.Q})
	Legendary.Drawing:MenuElement({id = "ColorQ", name = "Color", color = Draw.Color(255, 0, 0, 255)})
	Legendary.Drawing:MenuElement({id = "DrawClear", name = "Draw Spell (Clear) Status", value = true})
	Legendary.Drawing:MenuElement({id = "DrawHarass", name = "Draw Spell (Harass) Status", value = true})
end

function MasterYi:Tick()
	local Combo = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO]) or (_G.GOS and _G.GOS:GetMode() == "Combo")
  	local Clear = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR]) or (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR]) or (_G.GOS and _G.GOS:GetMode() == "Clear")
  	local Harass = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS]) or (_G.GOS and _G.GOS:GetMode() == "Harass")
  	local Flee = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE]) or (_G.GOS and _G.GOS:GetMode() == "Flee")
    if myHero.dead then return end
    target = LegendaryTarget(900)
    if Combo then
        self:Combo(target)
    elseif target and Harass then
        self:Harass(target)
    elseif Clear then
		self:Clear()
	elseif Flee then
		self:Flee(target)
	end
		self:Killsteal(target)
end

function MasterYi:Combo()
    if target == nil then return end
    if Legendary.Combo.Q:Value() and Ready(_Q) and myHero.pos:DistanceTo(target.pos) < 600 then
		Control.CastSpell(HK_Q,target)
	end
	if Legendary.Combo.R:Value() and Ready(_R) and target.distance < 300 then
		Control.CastSpell(HK_R)
	end
	if Legendary.Combo.W:Value() and Ready(_W) and myHero.pos:DistanceTo(target.pos) < 125 and myHero.attackData.state == STATE_WINDDOWN then
		Control.CastSpell(HK_W)
	end
	if Legendary.Combo.E:Value() and Ready(_E) and target.distance < 300 then
		Control.CastSpell(HK_E)
	end
end

function MasterYi:Harass()
	if Legendary.Keys.SpellHarass:Value() == false then return end
	if target == nil then return end
	if Legendary.Harass.Q:Value() and Ready(_Q) and myHero.mana/myHero.maxMana >= Legendary.Harass.Mana:Value()/100 then
		 Control.CastSpell(HK_Q,target)
	end
end

function MasterYi:Clear()
if Legendary.Keys.SpellClear:Value() == false then return end
local ClearQ = Legendary.Clear.Q:Value()
local ClearMana = Legendary.Clear.Mana:Value()
local GetEnemyMinions = GetEnemyMinions()
local minion = nil	
	if ClearQ and Ready(_Q) and (myHero.mana/myHero.maxMana >= ClearMana / 100) then
		for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		local Count = MinionsAround(minion.pos, 550, 200)
			if Count >= 3 and minion.distance <= 600 and minion.team == 200 then
				Control.CastSpell(HK_Q, minion.pos)
			end
		end
	end
	if ClearQ and Ready(_Q) and (myHero.mana/myHero.maxMana >= ClearMana / 100) then
		for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
			if  minion.distance <= 600 and minion.team == 300 then
				Control.CastSpell(HK_Q, minion.pos)
			end
		end
	end
end

function MasterYi:Flee()
	if target == nil then return end
	if Legendary.Flee.R:Value() and Ready(_R) and myHero.pos:DistanceTo(target.pos) < 900 then
		Control.CastSpell(HK_R)
	end
end

function MasterYi:Killsteal()
	if target == nil then return end
	if Legendary.Killsteal.Q:Value() and Ready(_Q) then
		local Qlevel = myHero:GetSpellData(_Q).level
		local Qdamage = CalcPhysicalDamage(myHero, target, (({25, 60, 95, 130, 165})[Qlevel] + myHero.totalDamage))
		if Qdamage >= HpPred(target, 1) then
			Control.CastSpell(HK_Q,target)
		end
	end
end

function MasterYi:Draw()
	if myHero.dead then return end
	if Legendary.Drawing.DrawQ:Value() and Ready(_Q) then Draw.Circle(myHero.pos, 600, 3, Legendary.Drawing.ColorQ:Value()) end
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
