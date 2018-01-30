if myHero.charName ~= "Kindred" then return end

local sqrt = math.sqrt 
local abs = math.abs 
local deg = math.deg
local acos = math.acos
local huge = math.huge 
local insert = table.insert
local TEAM_JUNGLE = 300
local TEAM_ENEMY = 300 - myHero.team
local ScriptVersion = "BETA"

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

local function GetDistanceSqr(p1, p2)
	local dx, dz = p1.x - p2.x, p1.z - p2.z 
	return dx * dx + dz * dz
end

local function GetDistance(p1, p2)
    return sqrt(GetDistanceSqr(p1, p2))
end

local function GetDistance2D(p1,p2)
    return sqrt((p2.x - p1.x)*(p2.x - p1.x) + (p2.y - p1.y)*(p2.y - p1.y))
end

local function CurrentTarget(range)
	if _G.SDK then
		return _G.SDK.TargetSelector:GetTarget(range, _G.SDK.DAMAGE_TYPE_PHYSICAL);
	elseif _G.EOW then
		return _G.EOW:GetTarget(range)
	else
		return _G.GOS:GetTarget(range,"AD")
	end
end

local function IsReady(spell)
	return myHero:GetSpellData(spell).currentCd == 0 and  myHero:GetSpellData(spell).level > 0 and Game.CanUseSpell(spell) == 0 
end

local function CheckMana(spellSlot)
	return myHero:GetSpellData(spellSlot).mana < myHero.mana
end

local function CanCast(spellSlot)
	return IsReady(spellSlot) and CheckMana(spellSlot)
end

function ValidTarget(target, range)
	range = range and range or math.huge
	return target ~= nil and target.valid and target.visible and not target.dead and target.distance <= range
end

local function GetEnemyHeroes()
	EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero and Hero.isEnemy then
			table.insert(EnemyHeroes, Hero)
		end
	end
	return EnemyHeroes
end

local function GetAllyHeroes()
	AllyHeroes = {}	
  	for i = 1, Game.HeroCount() do
    	local unit = Game.Hero(i)
    	if unit and unit.isAlly then
	  		table.insert(AllyHeroes, unit)
  		end
  	end
  	return AllyHeroes
end

local function GetMinions()
	mobs = {}
	for i = 1,Game.MinionCount() do
    	local minion = Game.Minion(i)
    	if minion and minion.team ~= myHero.team then
    		table.insert(mobs, minion)
    	end
    end
    return mobs
end

local function HeroesAround(pos, range, team)
	local Count = {}
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		local bR = hero.boundingRadius
		if hero.team == team and not hero.dead and GetDistanceSqr(hero.pos, pos) - bR * bR < range then
			Count[#Count + 1] = hero
		end
	end
	return Count
end

local function MinionsAround(pos, range, team)
	local Count = {}
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		local bR = minion.boundingRadius
		if minion.team == team and not minion.dead and GetDistanceSqr(minion.pos, pos) - bR * bR < range then
			Count[#Count + 1] = minion
		end
	end
	return Count
end

local function EnemyInRange(range)
	local count = 0
	for i, target in ipairs(GetEnemyHeroes()) do
		if target.pos:DistanceTo(myHero.pos) < range then 
			count = count + 1
		end
	end
	return count
end

local function AllyInRange(range)
	local count = 0
	for i, ally in ipairs(GetAllyHeroes()) do
		if ally.pos:DistanceTo(myHero.pos) < range then 
			count = count + 1
		end
	end
	return count
end

local function HasBuff(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name == buffname and buff.count > 0 then 
			return true
		end
	end
	return false
end

function GetBuffData(unit, buffname)
  for i = 0, unit.buffCount do
    local buff = unit:GetBuff(i)
    if buff.name == buffname and buff.count > 0 then 
      return buff
    end
  end
  return {type = 0, name = "", startTime = 0, expireTime = 0, duration = 0, stacks = 0, count = 0}
end

local function IsImmobileTarget(unit)
	if unit == nil then return false end
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.name == "recall") and buff.count > 0 and Game.Timer() < buff.expireTime - 0.5 then
			return true
		end
	end
	return false	
end

local function IsFacing(unit)
   local V = Vector((unit.pos - myHero.pos))
   local D = Vector(unit.dir)
   local Angle = 180 - deg(acos(V*D/(V:Len()*D:Len())))
   if abs(Angle) < 80 then 
       return true  
   end
   return false
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
		_OnWaypoint[unit.networkID] = {startPos = unit.pos, pos = unit.posTo , speed = unit.ms, time = Game.Timer()}
			DelayAction(function()
				local time = (Game.Timer() - _OnWaypoint[unit.networkID].time)
				local speed = GetDistance2D(_OnWaypoint[unit.networkID].startPos,unit.pos)/(Game.Timer() - _OnWaypoint[unit.networkID].time)
				if speed > 1250 and time > 0 and unit.posTo == _OnWaypoint[unit.networkID].pos and GetDistance(unit.pos,_OnWaypoint[unit.networkID].pos) > 200 then
					_OnWaypoint[unit.networkID].speed = GetDistance2D(_OnWaypoint[unit.networkID].startPos,unit.pos)/(Game.Timer() - _OnWaypoint[unit.networkID].time)
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

local function ExcludeFurthest(average,lst,sTar)
	local removeID = 1 
	for i = 2, #lst do 
		if GetDistanceSqr(average, lst[i].pos) > GetDistanceSqr(average, lst[removeID].pos) then 
			removeID = i 
		end 
	end 
		local Newlst = {}
	for i = 1, #lst do 
		if (sTar and lst[i].networkID == sTar.networkID) or i ~= removeID then 
			Newlst[#Newlst + 1] = lst[i]
		end
	end
	return Newlst 
end

local function GetBestCircularCastPos(r,lst,s,d,sTar)
	local average = {x = 0, y = 0, z = 0, count = 0}
	local point = nil 
	if #lst == 0 then 
		if sTar then return GetPred(sTar,s,d), 0 end 
		return 
	end
		for i = 1, #lst do 
		local org = GetPred(lst[i],s,d)
		average.x = average.x + org.x 
		average.y = average.y + org.y 
		average.z = average.z + org.z 
		average.count = average.count + 1
	end 
		if sTar and sTar.type ~= lst[1].type then 
		local org = GetPred(sTar,s,d)
		average.x = average.x + org.x 
		average.y = average.y + org.y 
		average.z = average.z + org.z 
		average.count = average.count + 1
	end
	average.x = average.x/average.count 
	average.y = average.y/average.count 
	average.z = average.z/average.count 
		local InRange = 0 
	for i = 1, #lst do 
		if GetDistanceSqr(average, lst[i].pos) < r then 
			InRange = InRange + 1 
		end
	end

	local point = Vector(average.x, average.y, average.z)	
		if InRange == #lst then 
		return point, InRange
	else 
		return GetBestCircularCastPos(r, ExcludeFurthest(average, lst),s,d,sTar)
	end
end




class "Kindred"

function Kindred:__init()
	self:LoadSpells()
	self:LoadMenu()
	Callback.Add("Tick", function() self:Tick() end)
end

function Kindred:LoadSpells()
	Q = { range = myHero:GetSpellData(_Q).range, icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/7/76/Dance_of_Arrows.png" }
	W = { range = 500, mrange = 1300, range2 = 250000, mrange2 = 1690000, width = 800, width2 = 640000, speed = 1400, delay =  myHero:GetSpellData(_W).delay, icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/0/08/Wolf%27s_Frenzy.png" }
	E = { range = myHero:GetSpellData(_E).range, icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/3/3f/Mounting_Dread.png" }
	R = { range = myHero:GetSpellData(_R).range, icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/c/ca/Lamb%27s_Respite.png" }
end

function Kindred:LoadMenu()
	Kindred = MenuElement({type = MENU, id = "Kindred", name = "Kindred BETA"})

	--COMBO
	Kindred:MenuElement({type = MENU, id = "Combo", name = "Combo Settings"})
	Kindred.Combo:MenuElement({id = "Q", name = "Use [Q]", value = true})
	Kindred.Combo:MenuElement({id = "rQ", name = "Enemy Range to [Q]", value = 1300, min = 300, max = 1500, step = 50})
	Kindred.Combo:MenuElement({id = "W", name = "Use [W]", value = true})
	Kindred.Combo:MenuElement({id = "E", name = "Use [E]", value = true})

	--LANECLEAR
	Kindred:MenuElement({type = MENU, id = "LC", name = "Lane/Jungle Settings"})
	Kindred.LC:MenuElement({id = "Q", name = "Use [Q]", value = true})
	Kindred.LC:MenuElement({id = "W", name = "Use [W]", value = true})
	Kindred.LC:MenuElement({id = "E", name = "Use [E]", value = true})


	--ULTIMATE
	Kindred:MenuElement({type = MENU, id = "ult", name = "Ultimate Settings"})
	Kindred.ult:MenuElement({id = "R", name = "Use [R]", value = true})
	Kindred.ult:MenuElement({id = "MyHP", name = "If my hp is below %", value = 27, min = 1, max = 99})
	Kindred.ult:MenuElement({id = "Enemies", name = "If [X] enemies around", value = 2, min = 0, max = 5})
	Kindred.ult:MenuElement({id = "pR", name = "Use panic [R]", value = false})
	Kindred.ult:MenuElement({id = "allyR", name = "Use [R] to allies", value = true})
	Kindred.ult:MenuElement({type = MENU, id = "Heroes", name = "Heroes settings"})
	for i,ally in pairs(GetAllyHeroes()) do
		if not ally.isMe then
			Kindred.ult.Heroes:MenuElement({id = ally.networkID, name = ally.charName, value = true, leftIcon = "https://raw.githubusercontent.com/TheRipperGos/GoS/master/Sprites/"..ally.charName..".png"})
		end
	end
	Kindred.ult:MenuElement({type = MENU, id = "heroHP", name = "HP settings"})
	for i,ally in pairs(GetAllyHeroes()) do
		if not ally.isMe then
			Kindred.ult.heroHP:MenuElement({id = ally.networkID, name = "Min. "..ally.charName.." HP (%)", value = 20, min = 0, max = 100, leftIcon = "https://raw.githubusercontent.com/TheRipperGos/GoS/master/Sprites/"..ally.charName..".png"})
		end
	end

	--MISC
	Kindred:MenuElement({type = MENU, id = "misc", name = "Misc"})
	Kindred.misc:MenuElement({id = "Steal", name = "Try to steal", value = true, tooltip = "Baron / Herald / Dragons"})

	--DRAWS

end

function Kindred:Tick()
	if myHero.dead == false and Game.IsChatOpen() == false  then
		local Mode = GetMode()
		self:AutoR()
		if Mode == "Combo" then
			self:Combo()
		elseif Mode == "Flee" then
			self:Flee()
		elseif Mode == "Clear" then
			self:LaneClear()
		end
		self:AutoSteal()
	end
end

function Kindred:AutoR()
	if CanCast(_R) and Kindred.ult.R:Value() then
		if Kindred.ult.pR:Value() and myHero.health/myHero.maxHealth <= 0.18 then
			Control.CastSpell(HK_R)
		end
		if (myHero.health/myHero.maxHealth <= Kindred.ult.MyHP:Value()/100) and EnemyInRange(1000) >= Kindred.ult.Enemies:Value() then
			Control.CastSpell(HK_R)
		end
		if Kindred.ult.allyR:Value() then
			for i,ally in pairs(GetAllyHeroes()) do
				if not ally.isMe and not ally.dead and (GetDistance(myHero.pos, ally.pos) <= 550) then
					if Kindred.ult.Heroes[ally.networkID]:Value() then
						if (ally.health/ally.maxHealth <= Kindred.ult.heroHP[ally.networkID]:Value() / 100) and EnemyInRange(1000) > Kindred.ult.Enemies:Value() then
							Control.CastSpell(HK_R)
						end
					end
				end
			end
		end
	end
end

function Kindred:Combo()
	if CanCast(_W) and Kindred.Combo.W:Value() then
		local target = CurrentTarget(1300)
		if target == nil then return end
		local h = myHero.pos
		local bR = target.boundingRadius
		local F = IsFacing(target)
		local list = HeroesAround(h,W.width2,TEAM_ENEMY)
		local Pos = GetBestCircularCastPos(W.width2,list,W.speed,W.delay,target)
		local Dist = GetDistanceSqr(Pos, h) - bR * bR
    	if F and Dist < W.mrange2 and CanCast(_W) then
    		if Dist > W.range2 then 
    			Pos = h + (Pos - h):Normalized()*W.range
    		end
    		Control.CastSpell(HK_W, Pos)
    	elseif Dist < 0.95*W.mrange2 and CanCast(_W) then
    	    if Dist > W.range2 then 
    			Pos = h + (Pos - h):Normalized()*W.range
    		end
    		Control.CastSpell(HK_W, Pos) 
    	end
	end

	if CanCast(_Q) and Kindred.Combo.Q:Value() then
		-- FLASH Q
		--[[if MENU FLASH then
				if PODE USAR FLASH then
					
				end
		end]]

		local Qtarget = CurrentTarget(Kindred.Combo.rQ:Value() + 50)
		if Qtarget == nil then return end
		if (GetDistance(myHero.pos, Qtarget.pos) <= Kindred.Combo.rQ:Value()) --[[and ValidTarget(target)]] then
			Control.CastSpell(HK_Q, mousePos)
		end
	end


	if CanCast(_E) and Kindred.Combo.E:Value() then
		local Etarget = CurrentTarget(E.range)
	    if Etarget == nil then return end
		if Etarget then
		    if EnemyInRange(E.range) then
				if myHero.pos:DistanceTo(Etarget.pos) < E.range then
					Control.CastSpell(HK_E,Etarget.pos)
					if HasBuff(Etarget, "kindredecharge") then
						self:FocusETarget(Etarget)
					end
				end
			end
		end
	end
end

function Kindred:FocusETarget(target)
	if _G.EOWLoaded then
		EOW:ForceTarget(target)
	elseif _G.SDK.Orbwalker then
		_G.SDK.Orbwalker.ForceTarget = target	
	else
		_G.GOS.ForceTarget = target
	end	
end

function WallBetween(p1, p2, distance) --p1 and p2 are Vectors3d

	local Check =         p1 + (Vector(p2) - p1):Normalized()*distance/2
	local Checkdistance = p1 + (Vector(p2) - p1):Normalized()*distance
	
	if MapPosition:inWall(Check) and not MapPosition:inWall(Checkdistance) then
		return true
	end
end

function Kindred:Flee()
	if CanCast(_Q) then
		if WallBetween(myHero.pos, mousePos,  390) then
			Control.CastSpell(HK_Q, mousePos)
		end
	end
end


function Kindred:AutoSteal()
	if Kindred.misc.Steal.Value() then
	names = { "SRU_Baron", "SRU_RiftHerald", "SRU_Dragon_Water", "SRU_Dragon_Fire",	"SRU_Dragon_Earth ", "SRU_Dragon_Air", "SRU_Dragon_Elder" }
	for _, mob in pairs(GetMinions()) do
		if mob.team == TEAM_JUNGLE then
			for _, Drei in pairs(names) do
				if not mob.dead and mob.charName == Drei and ValidTarget(mob, 1300) then

					local Wdmg = (CanCast(_W) and CalcMagicalDamage(myHero, mob, self:WDMG(mob))*2 or 0)
					local Qdmg = (CanCast(_Q) and CalcPhysicalDamage(myHero, mob, self:QDMG()) or 0)
					local Admg = CalcPhysicalDamage(myHero, unit, (1.1 * myHero.totalDamage + myHero.critChance)) * 2
					local dmg = Wdmg + Qdmg + Admg

					if CanCast(_W) and CanCast(_Q) and (mob.health + mob.shieldAD) <= dmg then
						local h = myHero.pos
						local bR = mob.boundingRadius
						local F = IsFacing(mob)
						local list = MinionsAround(h,W.range2,TEAM_JUNGLE)
						local Pos = GetBestCircularCastPos(W.width2,list,W.speed,W.delay,mob)
						local Dist = GetDistanceSqr(Pos, h) - bR * bR
					    	if F and Dist < W.mrange2 and CanCast(_W) then
					    		if Dist > W.range2 then 
					    			Pos = h + (Pos - h):Normalized()*W.range
					    		end
					    		Control.CastSpell(HK_W, Pos)
					    	elseif Dist < 0.95*W.mrange2 and CanCast(_W) then
					    	    if Dist > W.range2 then 
					    			Pos = h + (Pos - h):Normalized()*W.range
					    		end
					    		Control.CastSpell(HK_W, Pos) 
					    	end
					   Control.CastSpell(HK_Q, mousePos) 
					end
					--[[if CanCast(_Q) and ValidTarget(mob, 1000) and (mob.health + mob.shieldAD) <= Qdmg + Admg then 
						Control.CastSpell(HK_Q, mousePos)
					end]]
				end
			end
		end
	end
end
end


function Kindred:LaneClear()
	names = {"SRU_Gromp", "SRU_Blue", "SRU_Murkwolf", "SRU_Razorbeak", "SRU_Red", "SRU_Krug", "Sru_Crab", "SRU_Baron", "SRU_RiftHerald", "SRU_Dragon_Water", "SRU_Dragon_Fire",	"SRU_Dragon_Earth ", "SRU_Dragon_Air", "SRU_Dragon_Elder"}
	for _, mob in pairs(GetMinions()) do	
		if mob.team == TEAM_JUNGLE then
			if CanCast(_Q) and Kindred.LC.Q:Value() and ValidTarget(mob, 500) then 
				Control.CastSpell(HK_Q, mousePos)
			end
			for _, Drei in pairs(names) do
				if not mob.dead and mob.charName == Drei then 
					if CanCast(_W) and ValidTarget(mob, 1000) and Kindred.LC.W:Value() and (mob.health + mob.shieldAD) >= CalcMagicalDamage(myHero, mob, self:WDMG(mob)) then 
						local h = myHero.pos
						local bR = mob.boundingRadius
						local F = IsFacing(mob)
						local list = HeroesAround(h,W.range2,TEAM_JUNGLE)
						local Pos = GetBestCircularCastPos(W.width2,list,W.speed,W.delay,mob)
						local Dist = GetDistanceSqr(Pos, h)
					    	if F and Dist < W.mrange2 and CanCast(_W) then
					    		if Dist > W.range2 then 
					    			Pos = h + (Pos - h):Normalized()*W.range
					    		end
					    		Control.CastSpell(HK_W, Pos)
					    	elseif Dist < 0.95*W.mrange2 and CanCast(_W) then
					    	    if Dist > W.range2 then 
					    			Pos = h + (Pos - h):Normalized()*W.range
					    		end
					    		Control.CastSpell(HK_W, Pos) 
					    	end
    				end
    				if CanCast(_E) and ValidTarget(mob, 500) and Kindred.LC.E:Value() and  (mob.health + mob.shieldAD) >= CalcPhysicalDamage(myHero, mob, self:EDMG(mob)) then 
    					Control.CastSpell(HK_E,mob.pos)
	    			end
			end end
		elseif mob.team == TEAM_ENEMY then
			if --[[KindredM.QOptions.QL:Value() == false and]] CanCast(_Q) and Kindred.LC.Q:Value() and ValidTarget(mob, 1000) then 
				Control.CastSpell(HK_Q, mousePos)
			end
			if CanCast(_W) and ValidTarget(mob, 800) and Kindred.LC.W:Value() then 
				Control.CastSpell(HK_W, myHero.pos)
			end
			--[[if CanCast(_E) and ValidTarget(mob, 500) and Kindred.LC.E:Value() then 
				Control.CastSpell(HK_E,mob.pos)
			end ]]
		end
	end end

function Kindred:PassiveStacks()
	local passive = GetBuffData(myHero, "kindredmarkofthekindredstackcounter").stacks
	return passive
end


function Kindred:QDMG()
    local level = myHero:GetSpellData(_Q).level
    local qdamage = (({60, 80, 100, 120, 140})[level] + myHero.totalDamage * 0.65)
	return qdamage
end

function Kindred:WDMG(unit)
    local level = myHero:GetSpellData(_W).level
    local wdamage = (({25, 30, 35, 40, 45})[level] + myHero.totalDamage * 0.2 + ((0.015 + (0.01 * self:PassiveStacks())) * unit.health))
	return wdamage
end

function Kindred:EDMG(unit)
    local level = myHero:GetSpellData(_E).level
    local edamage = (({65, 85, 105, 125, 145})[level] + 0.8 * myHero.totalDamage + ((0.08 + (0.005 * self:PassiveStacks())) * (1 - unit.health)))
	return edamage
end

function Kindred:Draw()
	if myHero.dead == false then
	local h = myHero.pos

	end
end



Callback.Add("Load",function() _G[myHero.charName]() end)
