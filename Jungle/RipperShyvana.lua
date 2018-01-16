require 'DamageLib'
require 'Eternal Prediction'
local sqrt = math.sqrt 
local abs = math.abs 
local deg = math.deg
local acos = math.acos 
local insert = table.insert
local TEAM_JUNGLE = 300
local TEAM_ENEMY = 300 - myHero.team
local ScriptVersion = "v2.0"
--- Engine ---
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

	local function VectorPointProjectionOnLineSegment(v1, v2, v)
		local cx, cy, ax, ay, bx, by = v.x, v.z, v1.x, v1.z, v2.x, v2.z
	    local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) * (bx - ax) + (by - ay) * (by - ay))
	    local pointLine = { x = ax + rL * (bx - ax), z = ay + rL * (by - ay) }
	    local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
	    local isOnSegment = rS == rL
	    local pointSegment = isOnSegment and pointLine or {x = ax + rS * (bx - ax), z = ay + rS * (by - ay)}
		return pointSegment, pointLine, isOnSegment
	end

local function Ready(spell)
	return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana and Game.CanUseSpell(spell) == 0 
end

function MinionsAround(pos, range, team)
    local Count = {}
    for i = 1, Game.MinionCount() do
        local m = Game.Minion(i)
		local bR = m.boundingRadius
        if m.team == team and not m.dead and GetDistanceSqr(m.pos, pos) - bR * bR < range then
           Count[#Count + 1] = m
        end
    end
    return Count
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

	local _EnemyHeroes
	local function GetEnemyHeroes()
		if _EnemyHeroes then return _EnemyHeroes end
		_EnemyHeroes = {}
		for i = 1, Game.HeroCount() do
			local unit = Game.Hero(i)
			if unit.team == TEAM_ENEMY then
				insert(_EnemyHeroes, unit)
			end
		end
		return _EnemyHeroes
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

	
		local function MCollision(hpos,cpos,width)
		local Count = 0
		for i = 1, Game.MinionCount() do
			local m = Game.Minion(i)
			if m and m.team ~= TEAM_ALLY and m.dead == false and m.isTargetable then
				local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(hpos, cpos, m.pos)
				local w = width + m.boundingRadius
				local pos = m.pos
				if isOnSegment and GetDistanceSqr(pointSegment, pos) < w * w and GetDistanceSqr(hpos, cpos) > GetDistanceSqr(hpos, pos) then
					Count = Count + 1
				end
			end
		end
		return Count
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

	local function Priority(charName)
	  local p1 = {"Alistar", "Amumu", "Blitzcrank", "Braum", "Cho'Gath", "Dr. Mundo", "Garen", "Gnar", "Maokai", "Hecarim", "Jarvan IV", "Leona", "Lulu", "Malphite", "Nasus", "Nautilus", "Nunu", "Olaf", "Rammus", "Renekton", "Sejuani", "Shen", "Shyvana", "Singed", "Sion", "Skarner", "Taric", "TahmKench", "Thresh", "Volibear", "Warwick", "MonkeyKing", "Yorick", "Zac", "Poppy"}
	  local p2 = {"Aatrox", "Darius", "Elise", "Evelynn", "Galio", "Gragas", "Irelia", "Jax", "Lee Sin", "Morgana", "Janna", "Nocturne", "Pantheon", "Rengar", "Rumble", "Swain", "Trundle", "Tryndamere", "Udyr", "Urgot", "Vi", "XinZhao", "RekSai", "Bard", "Nami", "Sona", "Camille", "Rakan", "Kayn"}
	  local p3 = {"Akali", "Diana", "Ekko", "FiddleSticks", "Fiora", "Gangplank", "Fizz", "Heimerdinger", "Jayce", "Kassadin", "Kayle", "Kha'Zix", "Lissandra", "Mordekaiser", "Nidalee", "Riven", "Shaco", "Vladimir", "Yasuo", "Zilean", "Zyra", "Ryze"}
	  local p4 = {"Ahri", "Anivia", "Annie", "Ashe", "Azir", "Brand", "Caitlyn", "Cassiopeia", "Corki", "Draven", "Ezreal", "Graves", "Jinx", "Kalista", "Karma", "Karthus", "Katarina", "Kennen", "KogMaw", "Kindred", "Leblanc", "Lucian", "Lux", "Malzahar", "MasterYi", "MissFortune", "Orianna", "Quinn", "Sivir", "Syndra", "Talon", "Teemo", "Tristana", "TwistedFate", "Twitch", "Varus", "Vayne", "Veigar", "Velkoz", "Viktor", "Xerath", "Zed", "Ziggs", "Jhin", "Soraka", "Xayah"}
	  if table.contains(p1, charName) then return 1 end
	  if table.contains(p2, charName) then return 1.25 end
	  if table.contains(p3, charName) then return 1.75 end
	  return table.contains(p4, charName) and 2.25 or 1
	end
	
	local function GetTarget(range,t,pos)
	local t = t or "AD"
	local pos = pos or myHero.pos
	local target = {}
		for i = 1, Game.HeroCount() do
			local hero = Game.Hero(i)
			if hero.team ~= myHero.team and hero.dead == false then
				OnVision(hero)
			end
			if hero.team ~= myHero.team and hero.valid and hero.dead == false and (OnVision(hero).state == true or (OnVision(hero).state == false and GetTickCount() - OnVision(hero).tick < 650)) and hero.isTargetable then
				local heroPos = hero.pos
				if OnVision(hero).state == false then heroPos = hero.pos + Vector(hero.pos,hero.posTo):Normalized() * ((GetTickCount() - OnVision(hero).tick)/1000 * hero.ms) end
				if GetDistance(pos,heroPos) <= range then
					if t == "AD" then
						target[(CalcPhysicalDamage(myHero,hero,100) / hero.health)*Priority(hero.charName)] = hero
					elseif t == "AP" then
						target[(CalcMagicalDamage(myHero,hero,100) / hero.health)*Priority(hero.charName)] = hero
					elseif t == "HYB" then
						target[((CalcMagicalDamage(myHero,hero,50) + CalcPhysicalDamage(myHero,hero,50))/ hero.health)*Priority(hero.charName)] = hero
					end
				end
			end
		end
		local bT = 0
		for d,v in pairs(target) do
			if d > bT then
				bT = d
			end
		end
		if bT ~= 0 then return target[bT] end
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
   	Q = { range = 800, range2 = 640000, mrange = 1035, mrange2 = 1071225, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed, speed2 = myHero:GetSpellData(_Q).speed * myHero:GetSpellData(_Q).speed ,width = 235, width2 = 55225, icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/7/7b/Twin_Bite.png" }
	W = { range = myHero:GetSpellData(_W).range, range2 = myHero:GetSpellData(_W).range * myHero:GetSpellData(_W).range, delay = myHero:GetSpellData(_W).delay, speed = myHero:GetSpellData(_W).speed, width = myHero:GetSpellData(_W).width, width2 = myHero:GetSpellData(_W).width * myHero:GetSpellData(_W).width, icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/f/fb/Burnout.png" }
	E = { range = 925, range2 = 855625, delay = 0.25, speed = myHero:GetSpellData(_E).speed, width = myHero:GetSpellData(_E).width, width2 = myHero:GetSpellData(_E).width * myHero:GetSpellData(_E).width, icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/f/f2/Flame_Breath.png" }
	R = { range = 1000, range2 = 1000000, delay = 0.25, speed = myHero:GetSpellData(_R).speed, width = myHero:GetSpellData(_R).width, width2 = myHero:GetSpellData(_R).width * myHero:GetSpellData(_R).width, icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/5/50/Dragon%27s_Descent.png" }
end

function Shyvana:LoadMenu()
  	TRS = MenuElement({type = MENU, id = "Menu", name = "Shyvana The Ripper "..ScriptVersion.."", leftIcon = "https://raw.githubusercontent.com/TheRipperGos/GoS/master/Sprites/Shyvana.png"})
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
	if myHero.dead == false and Game.IsChatOpen() == false then
	local Mode = GetMode()
	if Mode == "Combo" then
		self:Combo()
		
	elseif Mode == "Harass" then
		self:Harass()
	elseif Mode == "Clear" then
		self:Clear()
    elseif Mode == "Flee" then
    	self:Flee()
    end
    self:AutoR()
	self:KS()
	self:LastHitE()
	end
end

function Shyvana:Combo()	
	local target = GetTarget(1200)
	if target == nil then return end  
	
	local h = myHero.pos
	local F = IsFacing(target)
	local bR = target.boundingRadius
    
	if myHero.pos:DistanceTo(target.pos) < 170 and TRS.Combo.W:Value() and Ready(_W) then
    	Control.CastSpell(HK_W)
    end
  	if myHero.pos:DistanceTo(target.pos) < 500 and TRS.Combo.W:Value() and Ready(_W) and TRS.Misc.SpeedW:Value() then
    	Control.CastSpell(HK_W)
    end
  	if TRS.Combo.E:Value() and Ready(_E) then
    	local Pos = GetPred(target, E.speed, E.delay + Game.Latency()/1000)
    	local Dist = GetDistanceSqr(Pos, h) - bR * bR
    	local EColl = MCollision(h, Pos, E.width)
    	if EColl == 0 then 
    		if F and Dist < E.range2 then 
    			Control.CastSpell(HK_E, Pos)
    		elseif Dist < 0.97*E.range2 then 
    			Control.CastSpell(HK_E, Pos)
    		end
    	end
    end
  	if myHero.pos:DistanceTo(target.pos) < 130 and TRS.Combo.Q:Value() and Ready(_Q) then
    	Control.CastSpell(HK_Q)
    end
  	if myHero.pos:DistanceTo(target.pos) < 850 and TRS.Combo.R:Value() and Ready(_R) and (target.health/target.maxHealth <= TRS.Combo.RHP:Value() / 100) then
    	if HeroesAround(myHero.pos,1200,200) >= TRS.Combo.ER:Value() then
			local Pos = GetPred(target, R.speed, R.delay + Game.Latency()/1000)
			local Dist = GetDistanceSqr(Pos, h) - bR * bR
			local RColl = MCollision(h, Pos, R.width)
			if RColl == 0 then 
				if F and Dist < R.range2 then 
					Control.CastSpell(HK_R, Pos)
				elseif Dist < 0.97*R.range2 then 
					Control.CastSpell(HK_R, Pos)
				end
			end
      	end
    end
end

function Shyvana:LastHitQ()
  	if TRS.LastHit.Q:Value() == false then return end
	if not Ready(_Q) then return end
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
	local h = myHero.pos
	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
	if myHero.pos:DistanceTo(minion.pos) < 925 and minion.team == 200 or 300 then
    	local Edamage = (20 + 40 * level + 0.3 * myHero.ap)
      	if Edamage >= minion.health and Ready(_E) then
			local Pos = GetPred(minion, E.speed, E.delay + Game.Latency()/1000)				
  			Control.CastSpell(HK_E, Pos)
    		end
        end
      	end
end 

function Shyvana:Clear()
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
    	Control.CastSpell(HK_R,cursor.pos)
    	end
    end
end
  	
function Shyvana:AutoR()
  	local target = GetTarget(1200)
	if not target then return end
	local h = myHero.pos
	local F = IsFacing(target)
	local bR = target.boundingRadius
	if Ready(_R) and TRS.Misc.AutoR:Value() then
    	if HeroesAround(myHero.pos,1200,200) >= TRS.Misc.EAutoR:Value() then
			local Pos = GetPred(target, R.speed, R.delay + Game.Latency()/1000)
			local Dist = GetDistanceSqr(Pos, h) - bR * bR
			local RColl = MCollision(h, Pos, R.width)
			if RColl == 0 then 
				if F and Dist < R.range2 then 
					Control.CastSpell(HK_R, Pos)
				elseif Dist < 0.97*R.range2 then 
					Control.CastSpell(HK_R, Pos)
				end
			end
      	end
    end
end

function Shyvana:Harass()
	local target = GetTarget(925)
	if not target then return end
	local F = IsFacing(target)
	local bR = target.boundingRadius
	local h = myHero.pos	
  	if TRS.Harass.E:Value() and Ready(_E) then
   	local Pos = GetPred(target, E.speed, E.delay + Game.Latency()/1000)
    	local Dist = GetDistanceSqr(Pos, h) - bR * bR
    	local EColl = MCollision(h, Pos, E.width)
    	if EColl == 0 then 
    		if F and Dist < E.range2 then 
    			Control.CastSpell(HK_E, Pos)
    		elseif Dist < 0.97*E.range2 then 
    			Control.CastSpell(HK_E, Pos)
    		end
    end
    end
end

function Shyvana:KS()
	local target = GetTarget(1200)
    if not target then return end 
	if target.dead then return end
		local F = IsFacing(target)
	local bR = target.boundingRadius
	local h = myHero.pos
  	if h:DistanceTo(target.pos) < 175 and TRS.KS.W:Value() and Ready(_W) then
    	local level = myHero:GetSpellData(_W).level
    	local Wdamage = CalcMagicalDamage(myHero, target, (({20, 35, 50, 65, 80})[level] + 0.2 * myHero.totalDamage + 0.1 * myHero.ap))
	if Wdamage >= target.health + target.shieldAP + target.shieldAD then
  	Control.CastSpell(HK_W)
	return
	end
    end
  	if TRS.KS.E:Value() and Ready(_E) then
    local level = myHero:GetSpellData(_E).level
    local Edamage = CalcMagicalDamage(myHero, target, (({60, 100, 140, 180, 220})[level] + 0.3 * myHero.ap))
	if Edamage >= target.health + target.shieldAP + target.shieldAD then
  	local Pos = GetPred(target, E.speed, E.delay + Game.Latency()/1000)
    	local Dist = GetDistanceSqr(Pos, h) - bR * bR
    	local EColl = MCollision(h, Pos, E.width)
    	if EColl == 0 then 
    		if F and Dist < E.range2 then 
    			Control.CastSpell(HK_E, Pos)
    		elseif Dist < 0.97*E.range2 then 
    			Control.CastSpell(HK_E, Pos)
    		end
    end
	end
	end
	if TRS.KS.R:Value() and Ready(_R) then
    	local level = myHero:GetSpellData(_R).level
    	local Rdamage = CalcMagicalDamage(myHero, target, (({150, 250, 350})[level] + (0.7 * myHero.ap)))
	if HeroesAround(myHero.pos,1200,200) >= TRS.KS.ER:Value() and Rdamage >= target.health then
			local Pos = GetPred(target, R.speed, R.delay + Game.Latency()/1000)
			local Dist = GetDistanceSqr(Pos, h) - bR * bR
			local RColl = MCollision(h, Pos, R.width)
			if RColl == 0 then 
				if F and Dist < R.range2 then 
					Control.CastSpell(HK_R, Pos)
				elseif Dist < 0.97*R.range2 then 
					Control.CastSpell(HK_R, Pos)
				end
			end
	return
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
	else print ("TRS doens't support "..myHero.charName.." shutting down...") return
	end
end)
