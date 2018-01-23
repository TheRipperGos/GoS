if myHero.charName ~= "Kindred" then return end

local TEAM_JUNGLE = 300
local TEAM_ENEMY = 300 - myHero.team
local ScriptVersion = "ALPHA"

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
		if Hero.isEnemy then
			table.insert(EnemyHeroes, Hero)
		end
	end
	return self.EnemyHeroes
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

function calcMaxPos(pos)
	local origin = myHero.pos
	local vectorx = pos.x-origin.x
	local vectory = pos.y-origin.y
	local vectorz = pos.z-origin.z
	local dist= math.sqrt(vectorx^2+vectory^2+vectorz^2)
	return {x = origin.x + qRange * vectorx / dist ,y = origin.y + qRange * vectory / dist, z = origin.z + qRange * vectorz / dist}
end


class "Kindred"

function Kindred:__init()
	self:LoadSpells()
	self:LoadMenu()
	Callback.Add("Tick", function() self:Tick() end)
end

function Kindred:LoadSpells()
	E = { range = myHero:GetSpellData(_E).range }
	R = { range = myHero:GetSpellData(_R).range }
end

function Kindred:LoadMenu()
	self.Menu = MenuElement({type = MENU, id = "Kindred", name = "Kindred ALPHA"})
end

function Kindred:Tick()
	if myHero.dead == false and Game.IsChatOpen() == false  then
		if Mode == "Combo" then
				self:Combo()
		end
		self:AutoR()
	end
end

function Kindred:AutoR()
	if CanCast(_R) then
		if myHero.health/myHero.maxHealth < .70 then
			Control.CastSpell(HK_R)
	end
end

function Kindred:Combo()
	if CanCast(_Q) then

	end

	if CanCast(_W) then

	end

	if CanCast(_E) then
		local target = CurrentTarget(E.range)
	    if target == nil then return end
		if target then
		    if EnemyInRange(E.range) then
				if myHero.pos:DistanceTo(target.pos) < E.range then
				Control.CastSpell(HK_E,target.pos)
				end
			end
		end
	end
end

Callback.Add("Load",function() _G[myHero.charName]() end)
