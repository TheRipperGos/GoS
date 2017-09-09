require 'DamageLib'
require 'Eternal Prediction'
require "MapPosition"
local sqrt = math.sqrt 
local abs = math.abs 
local deg = math.deg
local acos = math.acos 
local insert = table.insert
local TEAM_JUNGLE = 300
local TEAM_ENEMY = 300 - myHero.team
local ScriptVersion = "v0.8"
-- engine --
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

local Spells = {["Fiddlesticks"] = {{Key = _W, Duration = 5, KeyName = "W" },{Key = _R,Duration = 1,KeyName = "R" }},
		["VelKoz"] = {{Key = _R, Duration = 1, KeyName = "R", Buff = "VelkozR" }},
		["Warwick"] = {{Key = _R, Duration = 1,KeyName = "R" , Buff = "warwickrsound"}},
		["MasterYi"] = {{Key = _W, Duration = 4,KeyName = "W", Buff = "Meditate" }},
		["Lux"] = {{Key = _R, Duration = 1,KeyName = "R" }},
		["Janna"] = {{Key = _R, Duration = 3,KeyName = "R",Buff = "ReapTheWhirlwind" }},
		["Jhin"] = {{Key = _R, Duration = 1,KeyName = "R" }},
		["Xerath"] = {{Key = _R, Duration = 3,KeyName = "R", SpellName = "XerathRMissileWrapper" }},
		["Karthus"] = {{Key = _R, Duration = 3,KeyName = "R", Buff = "karthusfallenonecastsound" }},
		["Ezreal"] = {{Key = _R, Duration = 1,KeyName = "R" }},
		["Galio"] = {{Key = _R, Duration = 2,KeyName = "R", Buff = "GalioIdolOfDurand" }},
		["Caitlyn"] = {{Key = _R, Duration = 2,KeyName = "R" , Buff = "CaitlynAceintheHole"}},
		["Malzahar"] = {{Key = _R, Duration = 2,KeyName = "R" }},
		["MissFortune"] = {{Key = _R, Duration = 2,KeyName = "R", Buff = "missfortunebulletsound" }},
		["Nunu"] = {{Key = _R, Duration = 2,KeyName = "R", Buff = "AbsoluteZero"  }},
		["TwistedFate"] = {{Key = _R, Duration = 2,KeyName = "R",Buff = "Destiny" }},
		["Shen"] = {{Key = _R, Duration = 2,KeyName = "R",Buff = "shenstandunitedlock" }},
		}
	
function IsChannelling(unit)
	if not Spells[unit.charName] then return false end
	local result = false
	for _, spell in pairs(Spells[unit.charName]) do
		if unit:GetSpellData(spell.Key).level > 0 and (unit:GetSpellData(spell.Key).name == spell.SpellName or unit:GetSpellData(spell.Key).currentCd > unit:GetSpellData(spell.Key).cd - spell.Duration or (spell.Buff and HasBuff(unit,spell.Buff) > 0)) then
				result = true
				break
		end
	end
	return result
end

local _AllyHeroes
function GetAllyHeroes()
  if _AllyHeroes then return _AllyHeroes end
  _AllyHeroes = {}
  for i = 1, Game.HeroCount() do
    local unit = Game.Hero(i)
    if unit.isAlly then
		insert(_AllyHeroes, unit)
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
	if not unit.team == 100 then
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
	
local function GetHeal(t)
	local target = {}
	local pos = myHero.pos
	for i,ally in pairs(GetAllyHeroes()) do
		if ally and ally.dead == false and ally.isTargetable and not ally.isMe and (ally.health/ally.maxHealth <= TRS.Heal.heroHP[ally.networkID]:Value() / 100)then
			local heroPos = ally.pos
			if pos:DistanceTo(ally.pos) < 550 and TRS.Heal.Heroes[ally.networkID]:Value() then
				if t == 1 then
					target[(CalcPhysicalDamage(myHero,ally,100) / ally.health)*Priority(ally.charName)] = ally
				elseif t == 2 then
					target[(CalcMagicalDamage(myHero,ally,100) / ally.health)*Priority(ally.charName)] = ally
				elseif t == 3 then
					target[((CalcMagicalDamage(myHero,ally,50) + CalcPhysicalDamage(myHero,ally,50))/ ally.health)*Priority(ally.charName)] = ally
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
-- engine --
-- Soraka -- 
class "Soraka"

local SorakaVersion = "v1.0"

function Soraka:__init()
  	self:LoadSpells()
	self:LoadMissile()
  	self:LoadMenu()
  	Callback.Add("Tick", function() self:Tick() end)
  	Callback.Add("Draw", function() self:Draw() end)
end

function Soraka:LoadSpells()
  	Q = { range = 800, range2 = 640000, mrange = 1035, mrange2 = 1071225, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed, speed2 = myHero:GetSpellData(_Q).speed * myHero:GetSpellData(_Q).speed ,width = 235, width2 = 55225, icon = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/c/cd/Starcall.png" }
	W = { range = myHero:GetSpellData(_W).range, range2 = myHero:GetSpellData(_W).range * myHero:GetSpellData(_W).range, delay = myHero:GetSpellData(_W).delay, speed = myHero:GetSpellData(_W).speed, width = myHero:GetSpellData(_W).width, width2 = myHero:GetSpellData(_W).width * myHero:GetSpellData(_W).width, icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/6/6f/Astral_Infusion.png" }
	E = { range = 925, range2 = 855625, mrange = 1160, mrange2 = 1345600, delay = myHero:GetSpellData(_E).delay, speed = myHero:GetSpellData(_E).speed, speed2 = myHero:GetSpellData(_E).speed * myHero:GetSpellData(_E).speed, width = myHero:GetSpellData(_E).width, width2 = myHero:GetSpellData(_E).width * myHero:GetSpellData(_E).width, icon = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/e/e7/Equinox.png" }
	R = { range = myHero:GetSpellData(_R).range, range2 = myHero:GetSpellData(_R).range * myHero:GetSpellData(_R).range, delay = myHero:GetSpellData(_R).delay, speed = myHero:GetSpellData(_R).speed, width = myHero:GetSpellData(_R).width, width2 = myHero:GetSpellData(_R).width * myHero:GetSpellData(_R).width, icon = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/f/f3/Wish.png" }
end

function Soraka:LoadMissile()
	self.MissileSpells = {}
	for i = 1,Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isEnemy then
			if Spells[hero.charName] then
				for k,v in pairs(Spells[hero.charName]) do
					if #v > 1 then
						self.MissileSpells[v] = true
					else
						--print(hero.charName)
					end	
				end
			end
		end
	end
end

function Soraka:LoadMenu()
  	TRS = MenuElement({type = MENU, id = "Menu", name = "Soraka The Healer", leftIcon = "https://raw.githubusercontent.com/TheRipperGos/GoS/master/Sprites/"..myHero.charName..".png"})
	--Q
	TRS:MenuElement({type = MENU, id = "Q", name = "[Q] settings", leftIcon = Q.icon})
	TRS.Q:MenuElement({id = "Qcombo", name = "Use in Combo", value = true})
	TRS.Q:MenuElement({id = "Qclear", name = "Use in Clear", value = true})
	TRS.Q:MenuElement({id = "Qminions", name = "Minimum minions to hit", value = 3, min = 1, max = 7})
	TRS.Q:MenuElement({id = "QManaC", name = "Min mana to Clear (%)", value = 40, min = 0, max = 100})
	TRS.Q:MenuElement({id = "Qharass", name = "Use in Harass", value = true})
	TRS.Q:MenuElement({id = "QManaH", name = "Min mana to Harass (%)", value = 40, min = 0, max = 100})
	TRS.Q:MenuElement({id = "Qflee", name = "Use in Flee", value = true})
	TRS.Q:MenuElement({id = "Qks", name = "Use to KS", value = true})
	--E
	TRS:MenuElement({type = MENU, id = "E", name = "[E] settings", leftIcon = E.icon})
	TRS.E:MenuElement({id = "Ecombo", name = "Use in Combo", value = true})
	TRS.E:MenuElement({id = "MinE", name = "Minimum enemies to hit", value = 1, min = 1, max = 5})
	TRS.E:MenuElement({id = "Eharass", name = "Use in Harass", value = true})
	TRS.E:MenuElement({id = "EManaH", name = "Min mana to Harass (%)", value = 40, min = 0, max = 100})
	TRS.E:MenuElement({id = "Eflee", name = "Use in Flee", value = true})
	TRS.E:MenuElement({id = "Eks", name = "Use to KS", value = true})
	TRS.E:MenuElement({id = "Ecc", name = "Auto [E] if enemy has CC", value = true})
  	TRS.E:MenuElement({id = "Ecancel", name = "Auto [E] to Interrupt", value = true})
	--Heal
  	TRS:MenuElement({type = MENU, id = "Heal", name = "Heal", leftIcon = W.icon})
  	TRS.Heal:MenuElement({id = "W", name = "Use [W]", value = true})
  	TRS.Heal:MenuElement({id = "myHealth", name = "Minimum Soraka Health (%)", value = 45, min = 5, max = 100})
	TRS.Heal:MenuElement({id = "Wmode", name = "Priorize", drop = {"Most AD", "Most AP", "Hybrid"}})
	TRS.Heal:MenuElement({id = "Mana", name = "Minimum Mana (%)", value = 20, min = 0, max = 100})
	TRS.Heal:MenuElement({type = MENU, id = "Heroes", name = "Heroes settings"})
	for i,ally in pairs(GetAllyHeroes()) do
	if ally.team == myHero.team and not ally.isMe then
		TRS.Heal.Heroes:MenuElement({id = ally.networkID, name = ally.charName, value = true, leftIcon = "https://raw.githubusercontent.com/TheRipperGos/GoS/master/Sprites/"..ally.charName..".png"})
	end
	end
	TRS.Heal:MenuElement({type = MENU, id = "heroHP", name = "HP settings"})
	for i,ally in pairs(GetAllyHeroes()) do
	if ally.team == myHero.team and not ally.isMe then
		TRS.Heal.heroHP:MenuElement({id = ally.networkID, name = "Min. "..ally.charName.." HP (%)", value = 60, min = 0, max = 100, leftIcon = "https://raw.githubusercontent.com/TheRipperGos/GoS/master/Sprites/"..ally.charName..".png"})
	end
	end
	--ULT
  	TRS:MenuElement({type = MENU, id = "ULT", name = "Ultimate", leftIcon = R.Icon})
  	TRS.ULT:MenuElement({id = "R", name = "Use [R]", value = true})
  	TRS.ULT:MenuElement({id = "myHealth", name = "Minimum Soraka Health (%)", value = 25, min = 0, max = 100})
	TRS.ULT:MenuElement({type = MENU, id = "Heroes", name = "Heroes settings"})
	for i,ally in pairs(GetAllyHeroes()) do
		if not ally.isMe then
			TRS.ULT.Heroes:MenuElement({id = ally.networkID, name = ally.charName, value = true, leftIcon = "https://raw.githubusercontent.com/TheRipperGos/GoS/master/Sprites/"..ally.charName..".png"})
		end
	end
	TRS.ULT:MenuElement({type = MENU, id = "heroHP", name = "HP settings"})
	for i,ally in pairs(GetAllyHeroes()) do
		if not ally.isMe then
			TRS.ULT.heroHP:MenuElement({id = ally.networkID, name = "Min. "..ally.charName.." HP (%)", value = 20, min = 0, max = 100, leftIcon = "https://raw.githubusercontent.com/TheRipperGos/GoS/master/Sprites/"..ally.charName..".png"})
		end
	end              
	--Drawings
  	TRS:MenuElement({type = MENU, id = "Drawings", name = "Drawings Settings"})
  	TRS.Drawings:MenuElement({id = "Q", name = "Draw [Q] range", value = true, leftIcon = Q.icon})
  	TRS.Drawings:MenuElement({id = "E", name = "Draw [E] range", value = true, leftIcon = E.icon})
  	TRS.Drawings:MenuElement({id = "Width", name = "Width", value = 2, min = 1, max = 5, step = 1})
	TRS.Drawings:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 0, 0, 255)})
end

function Soraka:Tick()
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
	self:Killsteal()
    self:Heal()
  	self:Misc()
	end
end

function Soraka:Combo()
	local target = GetTarget(1150)
	if target == nil then
	return 
	end 
	if TRS.E.Ecombo:Value() and Ready(_E) then
		local h = myHero.pos
		local bR = target.boundingRadius
		local F = IsFacing(target)
		local list = HeroesAround(h,E.range2,TEAM_ENEMY)
		local Pos, Count = GetBestCircularCastPos(E.width2,list,E.speed,E.delay,target)
		local Dist = GetDistanceSqr(Pos, h)
		print(target.type)
    	if F and Dist - bR * bR < E.range2 then 
    		Control.CastSpell(HK_E, Pos)
    	elseif Dist - bR * bR < 0.95*E.range2 then 
    		Control.CastSpell(HK_E, Pos)
    	end
	end
	if TRS.Q.Qcombo:Value() and Ready(_Q) then
		local h = myHero.pos
		local bR = target.boundingRadius
		local F = IsFacing(target)
		local list = HeroesAround(h,Q.range2,TEAM_ENEMY)
		local Pos = GetBestCircularCastPos(Q.width2,list,Q.speed,Q.delay,target)
		local Dist = GetDistanceSqr(Pos, h)
    	if F and Dist - bR * bR < Q.range2 then 
    		Control.CastSpell(HK_Q, Pos)
    	elseif Dist - bR * bR < 0.95*Q.range2 then 
    		Control.CastSpell(HK_Q, Pos)
    	end
	end
end

function Soraka:Clear()
	if TRS.Q.Qclear:Value() == false then return end
	local h = myHero.pos
	local t = TEAM_ENEMY or 300
	local sTar = nil
	local spell = myHero.activeSpell
	if spell.valid and spell.spellWasCast == false then
   		return
   	end	
		if Ready(_Q) and (myHero.mana/myHero.maxMana > TRS.Q.QManaC:Value() / 100) then 
			local list = MinionsAround(h,Q.range2,t)				
			local target = GetTarget(1035)
			if target then sTar = target end 
			local Pos, Count = GetBestCircularCastPos(Q.width2,list,Q.speed,Q.delay,sTar)
			if Pos and Count >= TRS.Q.Qminions:Value() then 
				Control.CastSpell(HK_Q, Pos)
			end
		end
end

function Soraka:Harass()
	local target = GetTarget(1150)
	if target == nil then return end
	if TRS.Q.Qharass:Value() and Ready(_Q) and (myHero.mana/myHero.maxMana > TRS.Q.QManaH:Value() / 100) then
		local h = myHero.pos
		local bR = target.boundingRadius
		local D = GetDistanceSqr(target.pos, myHero.pos)
		local F = IsFacing(target)		
		local list = HeroesAround(myHero.pos,Q.range2,TEAM_ENEMY)
		local Pos = GetBestCircularCastPos(Q.width2,list,Q.speed,Q.delay,target)
		local Dist = GetDistanceSqr(Pos, h)
    	if F and Dist - bR * bR < Q.range2 then 
    		Control.CastSpell(HK_Q, Pos)
    	elseif Dist - bR * bR < 0.95*Q.range2 then 
    		Control.CastSpell(HK_Q, Pos)
    	end
	end
	if TRS.E.Eharass:Value() and Ready(_E) and (myHero.mana/myHero.maxMana > TRS.E.EManaH:Value() / 100) then
		local h = myHero.pos
		local bR = target.boundingRadius
		local D = GetDistanceSqr(target.pos, myHero.pos)
		local F = IsFacing(target)
		local list = HeroesAround(myHero.pos,E.range2,TEAM_ENEMY)
		local Pos = GetBestCircularCastPos(E.width2,list,E.speed,E.delay,target)
		local Dist = GetDistanceSqr(Pos, h)
    	if F and Dist - bR * bR < E.range2 then 
    		Control.CastSpell(HK_E, Pos)
    	elseif Dist - bR * bR < 0.95*E.range2 then 
    		Control.CastSpell(HK_E, Pos)
    	end
	end
end

function Soraka:Flee()
	local target = GetTarget(1150)
	if target == nil then return end
	local h = myHero.pos
	local bR = target.boundingRadius
	local D = GetDistanceSqr(target.pos, myHero.pos)
	local F = IsFacing(target)	
    if TRS.Q.Qflee:Value() and Ready(_Q) then			
		local list = HeroesAround(myHero.pos,Q.range2,TEAM_ENEMY)
		local Pos = GetBestCircularCastPos(Q.width2,list,Q.speed,Q.delay,target)
		local Dist = GetDistanceSqr(Pos, h)
    	if F and Dist - bR * bR < Q.range2 then 
    		Control.CastSpell(HK_Q, Pos)
    	elseif Dist - bR * bR < 0.95*Q.range2 then 
    		Control.CastSpell(HK_Q, Pos)
    	end
    end
    if TRS.E.Eflee:Value() and Ready(_E) then
		local list = HeroesAround(myHero.pos,E.range2,TEAM_ENEMY)
		local Pos = GetBestCircularCastPos(E.width2,list,E.speed,E.delay,target)
		local Dist = GetDistanceSqr(Pos, h)
    	if F and Dist - bR * bR < E.range2 then 
    		Control.CastSpell(HK_E, Pos)
    	elseif Dist - bR * bR < 0.95*E.range2 then 
    		Control.CastSpell(HK_E, Pos)
    	end
    end
	for i,ally in pairs(GetAllyHeroes()) do
		if not ally.isMe then
		local allys = HeroesAround(myHero.pos,550,myHero.team)
		local enemies = HeroesAround(ally.pos,500,TEAM_ENEMY)
			if #allys > 0 then
				if myHero.pos:DistanceTo(ally.pos) < 550 and HasBuff(myHero, "sorakaqregen") and Ready(_W) and (myHero.helth/myHero.maxHealth >= 60 / 100 ) then
					if #enemies > 0 and not ally.isMe then
						Control.CastSpell(HK_W,ally)
					end
				end
			end
		end
	end
end

function Soraka:Heal()
if TRS.Heal.W:Value() == false then return end
	if Ready(_W) and (myHero.mana/myHero.maxMana > TRS.Heal.Mana:Value() / 100) then
	local ally = GetHeal(TRS.Heal.Wmode:Value())
	if ally == nil then return end
		if (myHero.health/myHero.maxHealth >= TRS.Heal.myHealth:Value() / 100) and (ally.health + 50 + myHero:GetSpellData(_W).level * 30 + 0.6 * myHero.ap <= ally.maxHealth) and not HasBuff(myHero,"recall") then
			Control.CastSpell(HK_W,ally)
		return
		end
		for i = 1, Game.MissileCount() do
		local obj = Game.Missile(i)
		if obj and obj.isEnemy and obj.missileData and self.MissileSpells[obj.missileData.name] then
			local speed = obj.missileData.speed
			local width = obj.missileData.width
			local endPos = obj.missileData.endPos
			local pos = obj.pos
			local damage = obj.totalDamage
			if speed and width > 0 and endPos and pos then
				for k, hero in pairs(GetAllyHeroes) do 
				local afterdmg = ((hero.health - damage)/(hero.MaxHealth))
					if myHero.pos:DistanceTo(hero.pos) < 550 and (afterdmg <= TRS.Heal.heroHP[hero.networkID]:Value() / 100) then
						local pointSegment,pointLine,isOnSegment = VectorPointProjectionOnLineSegment(pos,endPos,hero.pos)
						if isOnSegment and hero.pos:DistanceTo(Vector(pointSegment.x,myHero.pos.y,pointSegment.y)) < width+ hero.boundingRadius and os.clock() - self.LastSpellT > 0.35 then
							self.LastSpellT = os.clock()
							Control.CastSpell(HK_W,hero)
						end
					end
				end
				
			elseif pos and endPos then
				for k,hero in pairs(GetAllyHeroes)	do
				local afterdmg = ((hero.health - damage)/(hero.MaxHealth))
					if myHero.pos:DistanceTo(hero.pos) < 550 and (pos:DistanceTo(hero.pos) < 100 or Vector(endPos):DistanceTo(hero.pos) < 100) and (afterdmg <= TRS.Heal.heroHP[hero.networkID]:Value() / 100)  then
						Control.CastSpell(HK_W,hero)--not sure 
					end
				end
			end
		--Shield Attacks 
--[[		elseif obj and obj.isEnemy and obj.missileData and obj.missileData.name and not obj.missileData.name:find("Minion") and obj.missileData.target > 0 then
			local target = obj.missileData.target
			for k, hero in pairs(GetAllyHeroes) do 
			local afterdmg = ((hero.health - damage)/(hero.MaxHealth))
				if myHero.pos:DistanceTo(hero.pos) < 550 and target == hero.handle and (afterdmg <= TRS.Heal.heroHP[hero.networkID]:Value() / 100)  then
					CastSpell(HK_W,hero)
				end
			end]]
		end
		end
	end
end

function Soraka:AutoR()
  	if TRS.ULT.R:Value() == false then return end
	for i,ally in pairs(GetAllyHeroes()) do
		local a = ally.pos
		local h = myHero.pos
		if not ally.isMe and not ally.dead then
			if TRS.ULT.Heroes[ally.networkID]:Value() and Ready(_R) then
			if(ally.health/ally.maxHealth <= TRS.ULT.heroHP[ally.networkID]:Value() / 100) then
			local lista = HeroesAround(a,1000,TEAM_ENEMY)
			if #lista > 0 then
			Control.CastSpell(HK_R)	
--			return
			end
			end
			end
		if (myHero.health/myHero.maxHealth <= TRS.ULT.myHealth:Value() / 100) and Ready(_R) and not myHero.dead then
			local liste = HeroesAround(h,1000,TEAM_ENEMY)
			if #liste > 0 then
			Control.CastSpell(HK_R)
			end
--			return
			end
		end
		end
end
  
function Soraka:Misc()
	if Ready(_E) then
	for i = 1, Game.HeroCount() do
	local target = Game.Hero(i)
		if target and target.isEnemy and myHero.pos:DistanceTo(target.pos) < 1150 then
		local h = myHero.pos
		local bR = target.boundingRadius
		local D = GetDistanceSqr(target.pos, myHero.pos)
		local F = IsFacing(target)
		local list = HeroesAround(myHero.pos,E.range2,TEAM_ENEMY)
		local Pos = GetBestCircularCastPos(E.width2,list,E.speed,E.delay,target)
		local Dist = GetDistanceSqr(Pos, h)
			if target.isChanneling--[[IsChannelling(hero)]] and TRS.E.Ecancel:Value() then
				if F and Dist - bR * bR < E.range2 then 
					Control.CastSpell(HK_E, Pos)
				elseif Dist - bR * bR < 0.95*E.range2 then 
					Control.CastSpell(HK_E, Pos)
				end
			end
			if HasBuff(target,"recall" or "zhonyasringshield" or "willrevive",5 or 11 or 24 or 29 or 31 --[[cc]]) and TRS.E.Ecc:Value() then
				if F and Dist - bR * bR < E.range2 then 
					Control.CastSpell(HK_E, Pos)
				elseif Dist - bR * bR < 0.95*E.range2 then 
					Control.CastSpell(HK_E, Pos)
				end
			end
		end
	end
	end
end

function Soraka:Killsteal()
	local h = myHero.pos
  	if TRS.E.Eks:Value() and Ready(_E) then
		local target = GetTarget(1150)
		if not target then return end
    	local Edamage = CalcMagicalDamage(myHero, target, (30 + 40 * myHero:GetSpellData(_E).level + 0.4 * myHero.ap))
		if Edamage > (target.health + target.shieldAD + target.hpRegen*1.5) then
			local bR = target.boundingRadius
			local D = GetDistanceSqr(target.pos, myHero.pos)
			local F = IsFacing(target)
			local list = HeroesAround(myHero.pos,E.range2,TEAM_ENEMY)
			local Pos = GetBestCircularCastPos(E.width2,list,E.speed,E.delay,target)
			local Dist = GetDistanceSqr(Pos, h)
			if F and Dist - bR * bR < E.range2 then 
				Control.CastSpell(HK_E, Pos)
			elseif Dist - bR * bR < 0.95*E.range2 then 
				Control.CastSpell(HK_E, Pos)
			end
		return end
	end
	if TRS.Q.Qks:Value() and Ready(_Q) then
		local target = GetTarget(1035)
		if not target then return end
    	local Qdamage = CalcMagicalDamage(myHero, target, (30 + 40 * myHero:GetSpellData(_Q).level + 0.35 * myHero.ap))
		if 	Qdamage > (target.health + target.shieldAD + target.hpRegen*1.5) then
		local target = GetTarget(1035)		
		local bR = target.boundingRadius
		local D = GetDistanceSqr(target.pos, myHero.pos)
		local F = IsFacing(target)		
		local list = HeroesAround(myHero.pos,Q.range2,TEAM_ENEMY)
		local Pos = GetBestCircularCastPos(Q.width2,list,Q.speed,Q.delay,target)
		local Dist = GetDistanceSqr(Pos, h)
    	if F and Dist - bR * bR < Q.range2 then 
    		Control.CastSpell(HK_Q, Pos)
    	elseif Dist - bR * bR < 0.95*Q.range2 then 
    		Control.CastSpell(HK_Q, Pos)
    	end
		return end
    end
end

function Soraka:Draw()
	if myHero.dead then return end
	if TRS.Drawings.Q:Value() then Draw.Circle(myHero.pos, 800, TRS.Drawings.Width:Value(), TRS.Drawings.Color:Value())
	end
	if TRS.Drawings.E:Value() then Draw.Circle(myHero.pos, 925, TRS.Drawings.Width:Value(), TRS.Drawings.Color:Value())	
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
