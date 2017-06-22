require 'DamageLib'
require 'Eternal Prediction'

local ScriptVersion = "alpha 0.1"
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

local _EnemyHeroes
function GetEnemyHeroes()
  if _EnemyHeroes then return _EnemyHeroes end
  for i = 1, Game.HeroCount() do
    local unit = Game.Hero(i)
    if unit.isEnemy then
	  if _EnemyHeroes == nil then _EnemyHeroes = {} end
      table.insert(_EnemyHeroes, unit)
    end
  end
  return {}
end

function IsImmobileTarget(unit)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.name == "recall") and buff.count > 0 then
			return true
		end
	end
	return false	
end

function IsRooted(unit)
    for i = 0, unit.buffCount do
        local buff = unit:GetBuff(i)
        if buff and (buff.type == 11) and buff.count > 0 then
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

local function EnableOrb(bool)
	if Orb == 1 then
		EOW:SetMovements(bool)
		EOW:SetAttacks(bool)
	elseif Orb == 2 then
		_G.SDK.Orbwalker:SetMovement(bool)
		_G.SDK.Orbwalker:SetAttack(bool)
	else
		GOS.BlockMovement = not bool
		GOS.BlockAttack = not bool
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

local function CastMinimap(hotkey,slot,target,predmode)
	local data = { range = myHero:GetSpellData(slot).range, delay = myHero:GetSpellData(slot).delay, speed = myHero:GetSpellData(slot).speed}
	local spell = Prediction:SetSpell(data, predmode, true)
	local pred = spell:GetPrediction(target,myHero.pos)
	if pred and pred.hitChance >= 0.25 then
		Control.CastSpell(hotkey, pred.castPos:ToMM().x,pred.castPos:ToMM().y)
	end
end

local function Variables()
	AnimationList = {
		["Spell3"]	= true,
		["Ult_A"]	= true,
		["Ult_B"]	= true,
		["Ult_C"]	= true,
		["Ult_D"]	= true,
		["Ult_E"]	= true
}
	InterruptingSpells = {
		["AbsoluteZero"]				= true,
		["AlZaharNetherGrasp"]			= true,
		["CaitlynAceintheHole"]			= true,
		["Crowstorm"]					= true,
		["DrainChannel"]				= true,
		["FallenOne"]					= true,
		["GalioIdolOfDurand"]			= true,
		["InfiniteDuress"]				= true,
		["KatarinaR"]					= true,
		["MissFortuneBulletTime"]		= true,
		["Teleport"]					= true,
		["Pantheon_GrandSkyfall_Jump"]	= true,
		["ShenStandUnited"]				= true,
		["UrgotSwap2"]					= true
}
end

class "Pantheon"

function Pantheon:__init()
	self:LoadSpells()
	self:LoadMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end

function Pantheon:LoadSpells()
	Q = { range = myHero:GetSpellData(_Q).range, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed, width = myHero:GetSpellData(_Q).width, icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/1/1b/Spear_Shot.png" }
	W = { range = myHero:GetSpellData(_W).range, delay = myHero:GetSpellData(_W).delay, speed = myHero:GetSpellData(_W).speed, width = myHero:GetSpellData(_W).width, icon = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/1/1b/Aegis_of_Zeonia.png" }
	E = { range = myHero:GetSpellData(_E).range, delay = myHero:GetSpellData(_E).delay, speed = myHero:GetSpellData(_E).speed, width = myHero:GetSpellData(_E).width, icon = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/e/ea/Heartseeker_Strike.png" }
	R = { range = myHero:GetSpellData(_R).range, delay = myHero:GetSpellData(_R).delay, speed = myHero:GetSpellData(_R).speed, width = myHero:GetSpellData(_R).width, icon = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/d/dd/Grand_Skyfall.png" }
end

function Pantheon:LoadMenu()
	TRS = MenuElement({type = MENU, id = "Menu", name = "Pantheon The Ripper "..ScriptVersion.."", leftIcon = "https://raw.githubusercontent.com/TheRipperGos/GoS/master/Sprites/Pantheon.png"})
	--- Combo ---
	TRS:MenuElement({type = MENU, id = "Combo", name = "Combo Settings"})
	TRS.Combo:MenuElement({id = "Q", name = "Use [Q]", value = true, leftIcon = Q.icon})
	TRS.Combo:MenuElement({id = "W", name = "Use [W]", value = true, leftIcon = W.icon})
	TRS.Combo:MenuElement({id = "E", name = "Use [E]", value = true, leftIcon = E.icon})
	TRS.Combo:MenuElement({id = "R", name = "Use [R]", value = true, leftIcon = R.icon})
	--- Harass ---
	TRS:MenuElement({type = MENU, id = "Harass", name = "Harass Settings"})
	TRS.Harass:MenuElement({id = "hMode", name = "Harass Mode", value = 1, drop = {"Q","W+E"}})
	TRS.Harass:MenuElement({id = "autoQ", name = "Auto [Q] when Target in Range", value = false, leftIcon = Q.icon})
	TRS.Harass:MenuElement({id = "aQT", name = "Don't Auto [Q] if enemy Turret Range", value = true})
	TRS.Harass:MenuElement({id = "Mana", name = "Min Mana to Harass [%]", value = 0, min = 0, max = 100})
	--- Clear ---
	TRS:MenuElement({type = MENU, id = "Clear", name = "Clear Settings"})
	TRS.Clear:MenuElement({id = "Q", name = "Use [Q]", value = true, leftIcon = Q.icon})
	TRS.Clear:MenuElement({id = "W", name = "Use [W]", value = true, leftIcon = W.icon})
	TRS.Clear:MenuElement({id = "W", name = "Use [E] (jungle)", value = true, leftIcon = Q.icon})
	TRS.Clear:MenuElement({id = "Mana", name = "Min Mana to Clear [Q]", value = 30, min = 0, max = 100})
	--- Misc ---
	TRS:MenuElement({type = MENU, id = "Misc", name = "Misc Settings"})	
	TRS.Misc:MenuElement({id = "ks", name = "Use Smart Killsecure", value = true})
	TRS.Misc:MenuElement({id = "interrupt", name = "Interrupt Channeling Spells", value = true})
	TRS.Misc:MenuElement({type = MENU, id = "ult", name = "Ultimate Alerts"})
		TRS.Misc.ult:MenuElement({id = "ultAlert", name = "Enable Ultimate Alert", value = true})
		TRS.Misc.ult:MenuElement({id = "AlertTime", name = "Time to be shown", value = 3, min = 1, max = 10})
	--ignite
	--- Draw ---
	TRS:MenuElement({type = MENU, id = "Draw", name = "Draw Settings"})
	TRS.Draw:MenuElement({id = "W", name = "Draw [W] Range", value = true, leftIcon = W.icon})
	TRS.Draw:MenuElement({id = "R", name = "Draw Minimap [R] Range", value = true})
	TRS.Draw:MenuElement({id = "DMG", name = "Draw Combo Damage", value = true})
		--------- Prediction --------------------------------------------------------------------
	TRS:MenuElement({type = MENU, id = "Pred", name = "Prediction Settings"})
	TRS.Pred:MenuElement({id = "Chance", name = "Hitchance", value = 0.0, min = 0.0, max = 1, step = 0.05})
end

function Pantheon:Tick()
	local Mode = GetMode()
	if Mode == "Combo" then
		self:Combo()
	elseif Mode == "Harass" then
		self:Harass()
	elseif Mode == "Clear" then
	self:Clear()
--	elseif Mode == "Flee" then
 --   	self:Flee()
    end
	self:Misc()
	self:AutoQ()
end

function Pantheon:OnProcessSpell(unit, spell)
	if TRS.Misc.interrupt:Value() then
		if myHero.pos:DistanceTo(unit) < 600 then
			if InterruptingSpells[spell.name] then
				Control.CastSpell(HK_W,unit)
			end
		end
	end
end

function Pantheon:OnAnimation(unit, animationName)
	if unit.isMe then 
		if AnimationList[animationName] then
			EnableOrb(false)
		else
			EnableOrb(true)
		end
	end
end

function Pantheon:Combo()
	local target = GetTarget(600)
	if not target then return end
	if myHero.pos:DistanceTo(target.pos) < 600 and TRS.Combo.Q:Value() and Ready(_Q) then
        Control.CastSpell(HK_Q,target)
    end
    if myHero.pos:DistanceTo(target.pos) < 600  and TRS.Combo.W:Value() and Ready(_W) then
        Control.CastSpell(HK_W,target)
    end
	if not Ready(_W) then
		if myHero.pos:DistanceTo(target.pos) < 600 and TRS.Combo.E:Value() and Ready(_E) then
			CastSpell(HK_E,_E,target,TYPE_CONE)
		end
	end
end

function Pantheon:Harass()
	local target = GetTarget(600)
	if not target then return end
	if (myHero.mana/myHero.maxMana > TRS.Harass.Mana:Value() / 100) then
		if TRS.Harass.hMode:Value() == "Q" then
			Control.CastSpell(HK_Q,target)
		end
		if TRS.Harass.hMode:Value() == "W+E" then
			Control.CastSpell(HK_W,target)
			if not Ready(_W) then Control.CastSpell(HK_E,target) end
		end
	end
end

function Pantheon:AutoQ()
	local target = GetTarget(600)
	if not target then return end
	if TRS.Harass.autoQ:Value() == false then return end
	if (myHero.mana/myHero.maxMana < TRS.Harass.Mana:Value() / 100) then return end
	if (TRS.Harass.aQT:Value() == true and not InEnemyTurretRange(myHero)) or TRS.Harass.aQT:Value() == false then
		Control.CastSpell(HK_Q,target)
	end
end

function Pantheon:Misc()
	local target = GetTarget(600)
	if not target then return end
		if TRS.Misc.ks:Value() then
			local Qdmg = CalcPhysicalDamage(myHero, target, (15 + 40 * myHero:GetSpellData(_Q).level + 1.4 * myHero.totalDamage) * ((target.health / target.maxHealth < 0.15) and 2 or 1))
			local Wdmg = CalcMagicalDamage(myHero, target, (25 + 25 * myHero:GetSpellData(_W).level + myHero.ap))
			local Edmg = CalcPhysicalDamage(myHero, target, (3 + 3 * myHero:GetSpellData(_E).level  + 0.6 * myHero.totalDamage) * ((target.type == Obj_AI_Hero) and 2 or 1))
			local Rdmg = CalcMagicalDamage(myHero, target, (100 + 300 * myHero:GetSpellData(_R).level + source.ap))
			if target.health < Qdmg and Ready(_Q) then
				Control.CastSpell(HK_Q,target)
			elseif target.health < Wdmg and Ready(_W) then
				Control.CastSpell(HK_W,target)
			elseif target.health < Edmg and Ready(_E) then
				Control.CastSpell(HK_E,target)
			elseif target.health < Qdmg + Wdmg and Ready(_Q) and Ready(_W) then
				Control.CastSpell(HK_W,target)
			elseif target.health < Qdmg + Edmg and Ready(_Q) and Ready(_E) then
				Control.CastSpell(HK_Q,target)
			elseif target.health < Wdmg + Edmg and Ready(_W) and Ready(_E) then
				Control.CastSpell(HK_W,target)
			elseif target.health < Qdmg + Wdmg + Edmg then
				Control.CastSpell(HK_Q,target)
			end
		end
end

function Pantheon:GetComboDamage(unit)
	local Total = 0
	local Qdmg = CalcPhysicalDamage(myHero, target, (15 + 40 * myHero:GetSpellData(_Q).level + 1.4 * myHero.totalDamage) * ((target.health / target.maxHealth < 0.15) and 2 or 1))
	local Wdmg = CalcMagicalDamage(myHero, target, (25 + 25 * myHero:GetSpellData(_W).level + myHero.ap))
	local Edmg = CalcPhysicalDamage(myHero, target, (3 + 3 * myHero:GetSpellData(_E).level  + 0.6 * myHero.totalDamage) * ((target.type == Obj_AI_Hero) and 2 or 1))
	local Rdmg = CalcMagicalDamage(myHero, target, (100 + 300 * myHero:GetSpellData(_R).level + source.ap))
	if Ready(_W) then
		Total = Total + Wdmg
	end
	if Ready(_Q) then
		Total = Total + Qdmg
	end
	if Ready(_E) then
		Total = Total + Edmg
	end
	if Ready(_R) then
		Total = Total + Rdmg
	end
	return Total
end
	
function Pantheon:Draw()
	if not myHero.dead then
		if TRS.Draw.W:Value() and Ready(_W) then Draw.Circle(myHero.pos, 600, 3,  Draw.Color(255,255, 162, 000)) end
		if TRS.Draw.R:Value() and Ready(_R) then Draw.CircleMinimap(myHero.pos, 700, 1.5, Draw.Color(200,50,180,230)) end
		if TRS.Draw.DMG:Value() then
		for i,enemy in pairs(GetEnemyHeroes()) do
			if enemy and enemy.isEnemy and enemy.visible and not enemy.dead then
				if OnScreen(enemy) then
				local rectPos = enemy.hpBar
					if self:GetComboDamage(enemy) < enemy.health then
						Draw.Rect(rectPos.x , rectPos.y ,(tostring(math.floor(self:GetComboDamage(enemy)/enemy.health*100)))*((enemy.health/enemy.maxHealth)),10, Draw.Color(150, 000, 000, 255)) 
					else
						Draw.Rect(rectPos.x , rectPos.y ,((enemy.health/enemy.maxHealth)*100),10, Draw.Color(150, 255, 255, 000)) 
					end
				end
			end
		end
		end
	end
end

function Pantheon:InEnemyTurretRange(unit)
	for i, turret in pairs(GetTurrets()) do
		if turret ~= nil then
			if turret.team ~= myHero.team then
				if unit.pos:DistanceTo(turret.pos) <= turret.range then
				return true
				end
			end
		end
	end
	return false
end

Callback.Add("Load", function()
	if not _G.Prediction_Loaded then return end
	if _G[myHero.charName] then
		_G[myHero.charName]()
		print("TRS "..ScriptVersion..": "..myHero.charName.."  Loaded")
	else print ("TRS doens't support "..myHero.charName.." shutting down...") return
	end
end)
