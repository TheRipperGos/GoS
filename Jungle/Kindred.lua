if myHero.charName ~= "Kindred" then return end

local sqrt = math.sqrt 
local abs = math.abs 
local deg = math.deg
local acos = math.acos 
local insert = table.insert
local TEAM_JUNGLE = 300
local TEAM_ENEMY = 300 - myHero.team
local ScriptVersion = "BETA"

function GetMode()
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

function GetDistance(p1, p2)
    return sqrt(GetDistanceSqr(p1, p2))
end

function GetDistance2D(p1,p2)
    return sqrt((p2.x - p1.x)*(p2.x - p1.x) + (p2.y - p1.y)*(p2.y - p1.y))
end

function Ready(spell)
	return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana and Game.CanUseSpell(spell) == 0 
end

function CurrentTarget(range)
	if _G.SDK then
		return _G.SDK.TargetSelector:GetTarget(range, _G.SDK.DAMAGE_TYPE_PHYSICAL);
	elseif _G.EOW then
		return _G.EOW:GetTarget(range)
	else
		return _G.GOS:GetTarget(range,"AD")
	end
end

function IsReady(spell)
	return Game.CanUseSpell(spell) == 0
end

function CheckMana(spellSlot)
	return myHero:GetSpellData(spellSlot).mana < myHero.mana
end

function CanCast(spellSlot)
	return IsReady(spellSlot) and CheckMana(spellSlot)
end

function GetEnemyHeroes()
	EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero and Hero.isEnemy then
			table.insert(EnemyHeroes, Hero)
		end
	end
	return EnemyHeroes
end

function GetAllyHeroes()
	AllyHeroes = {}	
  	for i = 1, Game.HeroCount() do
    	local unit = Game.Hero(i)
    	if unit and unit.isAlly then
	  		table.insert(AllyHeroes, unit)
  		end
  	end
  	return AllyHeroes
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

function EnemyInRange(range)
	local count = 0
	for i, target in ipairs(GetEnemyHeroes()) do
		if target.pos:DistanceTo(myHero.pos) < range then 
			count = count + 1
		end
	end
	return count
end

function AllyInRange(range)
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
	W = { range2 =  myHero:GetSpellData(_W).range *  myHero:GetSpellData(_W).range, width2 = myHero:GetSpellData(_W).width *  myHero:GetSpellData(_W).width, speed = 1400, delay =  myHero:GetSpellData(_W).delay, icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/0/08/Wolf%27s_Frenzy.png" }
	E = { range = myHero:GetSpellData(_E).range, icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/3/3f/Mounting_Dread.png" }
	R = { range = myHero:GetSpellData(_R).range, icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/c/ca/Lamb%27s_Respite.png" }
end

function Kindred:LoadMenu()
	Kindred = MenuElement({type = MENU, id = "Kindred", name = "Kindred BETA"})

	Kindred:MenuElement({type = MENU, id = "Combo", name = "Combo Settings"})
	Kindred.Combo:MenuElement({id = "Q", name = "Use [Q]", value = true})
	Kindred.Combo:MenuElement({id = "rQ", name = "Enemy Range to [Q]", value = 650, min = 400, max = 800})
	Kindred.Combo:MenuElement({id = "W", name = "Use [W]", value = true})
	Kindred.Combo:MenuElement({id = "E", name = "Use [E]", value = true})

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

end

function Kindred:Tick()
	if myHero.dead == false and Game.IsChatOpen() == false  then
	local Mode = GetMode()
		if Mode == "Combo" then
			self:Combo()
		elseif Mode == "Flee" then
			self:Flee()
		end
		self:AutoR()
	end
end

function Kindred:AutoR()
	if CanCast(_R) and Kindred.ult.R:Value() then
		if Kindred.ult.pR:Value() and myHero.health/myHero.maxHealth <= 0.15 then
			Control.CastSpell(HK_R)
		end
		if (myHero.health/myHero.maxHealth <= Kindred.ult.MyHP:Value()/100) and EnemyInRange(1000) > Kindred.ult.Enemies:Value() then
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
		local target = CurrentTarget(1200)
		if target == nil then return end
		local h = myHero.pos
		local bR = target.boundingRadius
		local F = IsFacing(target)
		local list = HeroesAround(h,W.range2,TEAM_ENEMY)
		local Pos = GetBestCircularCastPos(W.width2,list,W.speed,W.delay,target)
		local Dist = GetDistanceSqr(Pos, h)
    	if F and Dist - bR * bR < W.range2 then 
    		Control.CastSpell(HK_W, Pos)
    	elseif Dist - bR * bR < 0.95*W.range2 then 
    		Control.CastSpell(HK_W, Pos)
    	end
	end

	if CanCast(_Q) and Kindred.Combo.Q:Value() then
		-- FLASH Q
		--[[if MENU FLASH then
				if PODE USAR FLASH then
					
				end
		end]]

		local target = CurrentTarget(700)
		if target == nil then return end
		if (GetDistance(myHero.pos, target.pos) <= Kindred.Combo.rQ:Value()) --[[and ValidTarget(target)]] then
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

	local Check = p1 + (Vector(p2) - p1):Normalized()*distance/2
	local Checkdistance = p1 +(Vector(p2) - p1):Normalized()*distance
	
	if MapPosition:inWall(Check) and not MapPosition:inWall(Checkdistance) then
		return true
	end
end

function Kindred:Flee()
	if CanCast(_Q) then
		if WallBetween(myHero.pos, mousePos,  340) then
			Control.CastSpell(HK_Q, mousePos)
		end
	end
end

Callback.Add("Load",function() _G[myHero.charName]() end)
