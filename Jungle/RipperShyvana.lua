require 'DamageLib'
require 'Eternal Prediction'

local ScriptVersion = "v1.0"
--- Engine ---
local function Ready(spell)
	return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana and Game.CanUseSpell(spell) == 0 
end

local function OnScreen(unit)
	return unit.pos:To2D().onScreen;
end

function MinionsAround(pos, range, team)
    local Count = 0
    for i = 1, Game.MinionCount() do
        local m = Game.Minion(i)
        if m and m.team == team and not m.dead and m.pos:DistanceTo(pos,m.pos) < range then
            Count = Count + 1
        end
    end
    return Count
end

local function HeroesAround(pos, range, team)
	local Count = 0
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero and hero.team == team and not hero.dead and hero.pos:DistanceTo(pos, hero.pos) < range then
			Count = Count + 1
		end
	end
	return Count
end

local function GetDistance(p1,p2)
return  math.sqrt(math.pow((p2.x - p1.x),2) + math.pow((p2.y - p1.y),2) + math.pow((p2.z - p1.z),2))
end

local function GetDistance2D(p1,p2)
return  math.sqrt(math.pow((p2.x - p1.x),2) + math.pow((p2.y - p1.y),2))
end

local _AllyHeroes
function GetAllyHeroes()
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

function GetBuffs(unit)
	T = {}
	for i = 0, unit.buffCount do
		local Buff = unit:GetBuff(i)
		if Buff.count > 0 then
			table.insert(T, Buff)
		end
	end
	return T
end

function HasBuff(unit, buffname, bufftype)
	for i = 0, unit.buffCount do
	local buff = unit:GetBuff(i)
	if buff.name == buffname and buff.type == bufftype and buff.count > 0 and buff.duration > 0 then 
		return true
	end
	end
	return false
end

local function GetTarget(range)
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

local function GetMode()
	if _G.EOWLoaded then
		if EOW.CurrentMode == 1 then
			return "Combo"
		elseif EOW.CurrentMode == 2 then
			return "Harass"
		elseif EOW.CurrentMode == 3 then
			return "Lasthit"
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
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT] then
			return "Lasthit"
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE] then
			return "Flee"
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_NONE] then
			return "None"
		end
	else
		return GOS.GetMode()
	end
end

local function CastSpell(hotkey,slot,target,predmode)
	local data = { range = myHero:GetSpellData(slot).range, delay = myHero:GetSpellData(slot).delay, speed = myHero:GetSpellData(slot).speed}
	local spell = Prediction:SetSpell(data, predmode, true)
	local pred = spell:GetPrediction(target,myHero.pos)
	if pred and pred.hitChance >= TRS.Pred.Chance:Value() then
		Control.CastSpell(hotkey, pred.castPos)
	end
end
-- engine --
-- Shyvana -- 
class "Shyvana" 

function Shyvana:__init() 
	self:LoadSpells()
  	self:LoadMenu() 
  	Callback.Add("Tick", function() self:Tick() end)
  	Callback.Add("Draw", function() self:Draw() end) 
end

function Shyvana:LoadSpells() 
  	Q = { range = myHero:GetSpellData(_Q).range, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed, width = myHero:GetSpellData(_Q).width, icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/7/7b/Twin_Bite.png" }
	W = { range = myHero:GetSpellData(_W).range, delay = myHero:GetSpellData(_W).delay, speed = myHero:GetSpellData(_W).speed, width = myHero:GetSpellData(_W).width, icon = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/f/fb/Burnout.png" }
	E = { range = myHero:GetSpellData(_E).range, delay = myHero:GetSpellData(_E).delay, speed = myHero:GetSpellData(_E).speed, width = myHero:GetSpellData(_E).width, icon = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/f/f2/Flame_Breath.png" }
	R = { range = myHero:GetSpellData(_R).range, delay = myHero:GetSpellData(_R).delay, speed = myHero:GetSpellData(_R).speed, width = myHero:GetSpellData(_R).width, icon = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/5/50/Dragon%27s_Descent.png" }
end

function Shyvana:LoadMenu()
  	self.Menu = MenuElement({type = MENU, id = "Menu", name = "Shyvana The Ripper "..ScriptVersion.."", leftIcon = "https://raw.githubusercontent.com/TheRipperGos/GoS/master/Sprites/Shyvana.png"})
	-- Combo -----------------------------------------------------------------------------------------------------------------------
  	TRS:MenuElement({type = MENU, id = "Combo", name = "Combo"})
  	TRS.Combo:MenuElement({id = "Q", name = "Use [Q]", value = true, leftIcon = Q.icon})
  	TRS.Combo:MenuElement({id = "W", name = "Use [W]", value = true, leftIcon = W.icon})
  	TRS.Combo:MenuElement({id = "E", name = "Use [E]", value = true, leftIcon = E.icon})
  	TRS.Combo:MenuElement({id = "R", name = "Use [R]", value = true, leftIcon = R.icon})
  	TRS.Combo:MenuElement({id = "RHP", name = "Max enemy HP to use [R] (%)", value = 65, min = 0, max = 100})
    TRS.Combo:MenuElement({id = "ER", name = "Min enemies to use [R]", value = 1, min = 1, max = 5})
	-- LastHit ---------------------------------------------------------------------------------------------------------------------
  	TRS:MenuElement({type = MENU, id = "LastHit", name = "Last Hit"})
  	TRS.LastHit:MenuElement({id = "Q", name = "Use [Q]", value = true, leftIcon = Q.icon})
  	TRS.LastHit:MenuElement({id = "E", name = "Use [E]", value = true, leftIcon = E.icon})
	-- LaneClear -------------------------------------------------------------------------------------------------------------------
  	TRS:MenuElement({type = MENU, id = "Clear", name = "Lane Clear"})
  	TRS.Clear:MenuElement({id = "Q", name = "Use [Q]", value = true, leftIcon = Q.icon})
  	TRS.Clear:MenuElement({id = "W", name = "Use [W]", value = true, leftIcon = W.icon})
  	TRS.Clear:MenuElement({id = "E", name = "Use [E]", value = true, leftIcon = E.icon})
	-- Flee ------------------------------------------------------------------------------------------------------------------------
  	TRS:MenuElement({type = MENU, id = "Flee", name = "Flee"})
  	TRS.Flee:MenuElement({id ="W", name = "Use W", value = true, leftIcon = W.icon})
  	TRS.Flee:MenuElement({id ="R", name = "Use R", value = true, leftIcon = R.icon})
  	TRS.Flee:MenuElement({id = "ER", name = "Min enemies to use R", value = 3, min = 1, max = 5})
	-- Killsteal -------------------------------------------------------------------------------------------------------------------
  	TRS:MenuElement({type = MENU, id = "KS", name = "Killsteal"})
  	TRS.KS:MenuElement({id = "W", name = "Use W", value = true, leftIcon = W.icon})
  	TRS.KS:MenuElement({id = "E", name = "Use E", value = true, leftIcon = E.icon})
  	TRS.KS:MenuElement({id = "R", name = "Use R", value = true, leftIcon = R.icon})                     
    TRS.KS:MenuElement({id = "ER", name = "Min enemies to use R", value = 3, min = 1, max = 5})
	-- Harass ----------------------------------------------------------------------------------------------------------------------
  	TRS:MenuElement({type = MENU, id = "Harass", name = "Harass"})
  	TRS.Harass:MenuElement({id = "E", name = "Use E", value = true, leftIcon = E.icon})
	-- Misc ------------------------------------------------------------------------------------------------------------------------
  	TRS:MenuElement({type = MENU, id = "Misc", name = "Misc"})
    TRS.Misc:MenuElement({id = "SpeedW", name = "Use W for engage", value = false, leftIcon = W.icon})
  	TRS.Misc:MenuElement({id = "AutoR", name = "Auto R", value = false, leftIcon = R.icon})
    TRS.Misc:MenuElement({id = "EAutoR", name = "Enemies to auto R", value = 4, min = 1, max = 5})
  	TRS.Misc:MenuElement({id = "Key", name = "Auto R Key", key = string.byte(" ")})
	-- Drawings --------------------------------------------------------------------------------------------------------------------
  	TRS:MenuElement({type = MENU, id = "Drawings", name = "Drawings"})
  	TRS.Drawings:MenuElement({id = "E", name = "Draw E range", value = true})
  	TRS.Drawings:MenuElement({id = "R", name = "Draw R range", value = true})
  	TRS.Drawings:MenuElement({id = "Width", name = "Width", value = 3, min = 1, max = 5, step = 1})
	TRS.Drawings:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 0, 0, 255)})
end

function Shyvana:Tick()
	local Mode = GetMode()
	if Mode == "Combo" then
		self:Combo()
	elseif Mode == "Harass" then
		self:Harass()
	elseif Mode == "Clear" then
		self:Clear()
    elseif Mode == "Flee" then
    	self:Flee()
    elseif TRS.Misc.Key:Value() then
    	self:AutoR()
    end
	self:KS()
end

function Shyvana:Combo()
	local target = GetTarget(1500)
    if not target then return end 
	if myHero.pos:DistanceTo(target.pos) < 175 and TRS.Combo.W:Value() and Ready(_W) then
    	Control.CastSpell(HK_W)
    	end
  	if myHero.pos:DistanceTo(target.pos) < 500 and TRS.Combo.W:Value() and Ready(_W) and TRS.Misc.SpeedW:Value() then
    	Control.CastSpell(HK_W)
    	end
  	if myHero.pos:DistanceTo(target.pos) < 825  and TRS.Combo.E:Value() and Ready(_E) then
    	Control.CastSpell(HK_E,target:GetPrediction(E.speed,E.delay))
    	end
  	if myHero.pos:DistanceTo(target.pos) < 125 and TRS.Combo.Q:Value() and Ready(_Q) then
    	Control.CastSpell(HK_Q)
    	end
  	if myHero.pos:DistanceTo(target.pos) < 850 and TRS.Combo.R:Value() and Ready(_R) and (target.health/target.maxHealth <= TRS.Combo.RHP:Value() / 100) then
    	if HeroesAround(myHero,1200,200) >= TRS.Combo.ER:Value() then
    	CastSpell(HK_R,_R,target,TYPE_LINE)
      	end
    	end
end

function Shyvana:LastHitQ()
  	if TRS.LastHit.Q:Value() == false then return end
  	local level = myHero:GetSpellData(_Q).level
	if level == nil or level == 0 then return end
  	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
	if myHero.pos:DistanceTo(minion.pos) < 125 and minion.team == 200 or 300 then
    	local Qdamage = (25 + 15 * level / 100 * myHero.totalDamage)
      	if Qdamage >= minion.health and Ready(_Q) then
        Control.CastSpell(HK_Q)
        elseif Qdamage >= minion.health and HasBuff(myHero, "ShyvanaDoubleAttack") then
        Control.SetCursorPos(minion.pos)
        end
      	end
    end
end  	

function Shyvana:LastHitE()
  	if TRS.LastHit.E:Value() == false then return end
  	local level = myHero:GetSpellData(_E).level
	if level == nil or level == 0 then return end
  	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
	if myHero.pos:DistanceTo(minion.pos) < 925 and minion.team == 200 or 300 then
    	local Edamage = (20 + 40 * level + 0.3 * myHero.ap)
      	if Edamage >= minion.health and Ready(_E) then
        Control.CastSpell(HK_E,minion.pos)
        end
      	end
    end
end  

function Shyvana:LaneClear()
	if TRS.Clear.Q:Value() == false then return end
  	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
    if  minion.team == 200 or 300 then
    if myHero.pos:DistanceTo(minion.pos) < 125 and TRS.Clear.Q:Value() and Ready(_Q) then
	Control.CastSpell(HK_Q)
	return
	end
	if myHero.pos:DistanceTo(minion.pos) < 175 and TRS.Clear.W:Value() and Ready(_W) then
	Control.CastSpell(HK_W)
	return
	end
	if myHero.pos:DistanceTo(minion.pos) < 400 and TRS.Clear.E:Value() and Ready(_E) then
	Control.CastSpell(HK_E,minion.pos)
	return
	end
    end
    end
end

function Shyvana:Flee()
  	if TRS.Flee.W:Value() and Ready(_W) then
    	Control.CastSpell(HK_W)
    end
  	if TRS.Flee.R:Value() and Ready(_R) then
		if HeroesAround(myHero.pos,600,200) >= TRS.Flee.ER:Value() then
    	Control.CastSpell(HK_R)
    	end
    end
end
  	
function Shyvana:AutoR()
  	if Ready(_R) and TRS.Misc.AutoR:Value() then
    	if HeroesAround(myHero.pos,1200,200) >= TRS.Misc.EAutoR:Value() then
      	Control.CastSpell(HK_R)
      	end
    end
end

function Shyvana:Harass()
	local target = GetTarget(925)
    if not target then return end 
  	if myHero.pos:DistanceTo(target.pos) < 900 and TRS.Harass.E:Value() and Ready(_E) then
    	CastSpell(HK_E,_E,target,TYPE_LINE)
    	end
end

function Shyvana:KS()
	local target = GetTarget(1200)
    if not target then return end 
  	if myHero.pos:DistanceTo(target.pos) < 175 and TRS.KS.W:Value() and Ready(_W) then
    	local level = myHero:GetSpellData(_W).level
    	local Wdamage = CalcMagicalDamage(myHero, target, (({20, 32, 45, 57, 70})[level] + 0.2 * myHero.totalDamage + 0.1 * myHero.ap))
	if Wdamage >= target.health then
  	Control.CastSpell(HK_W)
	end
    end
  	if myHero.pos:DistanceTo(target.pos) < 825 and TRS.KS.E:Value() and Ready(_E) then
    	local level = myHero:GetSpellData(_E).level
    	local Edamage = CalcMagicalDamage(myHero, target, (({60, 100, 140, 180, 220})[level] + 0.3 * myHero.ap))
	if Edamage >= target.health then
  	CastSpell(HK_E,_E,target,TYPE_LINE)
	end
	end
	if myHero.pos:DistanceTo(target.pos) < 800 and TRS.KS.R:Value() and Ready(_R) then
    	local level = myHero:GetSpellData(_R).level
    	local Rdamage = CalcMagicalDamage(myHero, target, (({150, 250, 350})[level] + (0.7 * myHero.ap)))
	if HeroesAround(myHero.pos,1200,200) >= TRS.KS.ER:Value() and Rdamage >= target.health then
  	CastSpell(HK_R,_R,target,TYPE_LINE)
	end
    end
end

function Shyvana:Draw()
	if myHero.dead then return end
	if TRS.Drawings.E:Value() then Draw.Circle(myHero.pos, 925, TRS.Drawings.Width:Value(), TRS.Drawings.Color:Value())
	end
	if TRS.Drawings.R:Value() then Draw.Circle(myHero.pos, 850, TRS.Drawings.Width:Value(), TRS.Drawings.Color:Value())	
	end	
end
  
Callback.Add("Load", function()
	if not _G.Prediction_Loaded then return end
	if _G[myHero.charName] then
		_G[myHero.charName]()
		print("TRS "..ScriptVersion..": "..myHero.charName.."  Loaded")
	else print ("TRS doens't support "..myHero.charName.." shutting down...") return end
	end
end)
