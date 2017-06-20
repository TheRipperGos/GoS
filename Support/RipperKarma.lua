require 'DamageLib'
require 'Eternal Prediction'

local ScriptVersion = "v0.5a"
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

class "Karma"

function Karma:__init()
	self:LoadSpells()
	self:LoadMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end

function Karma:LoadSpells()
	Q = { range = myHero:GetSpellData(_Q).range, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed, width = myHero:GetSpellData(_Q).width, icon = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/a/ad/Inner_Flame.png" }
	W = { range = myHero:GetSpellData(_W).range, delay = myHero:GetSpellData(_W).delay, speed = myHero:GetSpellData(_W).speed, width = myHero:GetSpellData(_W).width, icon = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/0/0c/Focused_Resolve.png" }
	E = { range = myHero:GetSpellData(_E).range, delay = myHero:GetSpellData(_E).delay, speed = myHero:GetSpellData(_E).speed, width = myHero:GetSpellData(_E).width, icon = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/c/c4/Inspire.png" }
	R = { range = myHero:GetSpellData(_R).range, delay = myHero:GetSpellData(_R).delay, speed = myHero:GetSpellData(_R).speed, width = myHero:GetSpellData(_R).width, icon = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/7/76/Mantra.png" }
end

function Karma:LoadMenu()
	TRS = MenuElement({type = MENU, id = "Menu", name = "Karma The Enlightening "..ScriptVersion.."", leftIcon = "https://raw.githubusercontent.com/TheRipperGos/GoS/master/Sprites/Karma.png"})
	--- Combo ---
	TRS:MenuElement({type = MENU, id = "Combo", name = "Combo Settings"})
	TRS.Combo:MenuElement({id = "Q", name = "Use [Q]", value = true, leftIcon = Q.icon})
	TRS.Combo:MenuElement({id = "W", name = "Use [W]", value = true, leftIcon = W.icon})
	TRS.Combo:MenuElement({id = "E", name = "Use [E]", value = true, leftIcon = E.icon})
	TRS.Combo:MenuElement({id = "R", name = "Use [R]", value = true, leftIcon = R.icon})
	--- Harass ---
	TRS:MenuElement({type = MENU, id = "Harass", name = "Harass Settings"})
	TRS.Harass:MenuElement({id = "Key", name = "Use [Q]", value = true, leftIcon = Q.icon})
	TRS.Harass:MenuElement({id = "Mana", name = "Min Mana to Harass [%]", value = 0, min = 0, max = 100})
	--- Clear ---
	TRS:MenuElement({type = MENU, id = "Clear", name = "Clear Settings"})
	TRS.Clear:MenuElement({id = "Q", name = "Use [Q]", value = true, leftIcon = Q.icon})
	TRS.Clear:MenuElement({id = "Minion", name = "Min Minions to [Q]", value = 3, min = 1, max = 5})
	TRS.Clear:MenuElement({id = "Mana", name = "Min Mana to Clear [Q]", value = 30, min = 0, max = 100})
	--- Misc ---
	TRS:MenuElement({type = MENU, id = "Misc", name = "Misc Settings"})	
	TRS.Misc:MenuElement({id = "Qks", name = "Killsteal [Q]", value = true, leftIcon = W.icon})
	TRS.Misc:MenuElement({id = "Wks", name = "Killsteal [W]", value = true, leftIcon = R.icon})
	TRS.Misc:MenuElement({id = "Qimbl", name = "Auto [Q] on Immobile", value = true, leftIcon = Q.icon})
	TRS.Misc:MenuElement({id = "Qinter", name = "Auto [Q] to interrupt", value = true, leftIcon = Q.icon})
	--- Shield ---
	TRS:MenuElement({type = MENU, id = "Shield", name = "Shield Settings"})
	TRS.Shield:MenuElement({id = "E", name = "Use [E]", value = true, leftIcon = E.icon, leftIcon = E.icon})
	TRS.Shield:MenuElement({type = MENU, id = "Elist", name = "Auto use [E] Whitelist"})
	for i,ally in pairs(GetAllyHeroes()) do
		TRS.Shield.Elist:MenuElement({id = ally.networkID, name = ally.charName, value = true, leftIcon = "https://raw.githubusercontent.com/TheRipperGos/GoS/master/Sprites/"..ally.charName..".png"})
	end
	TRS.Shield:MenuElement({type = MENU, id = "minE", name = "HP to auto use [E]", value = true})
		for i,ally in pairs(GetAllyHeroes()) do
		if not ally.isMe then
		TRS.Shield.minE:MenuElement({id = ally.networkID, name = ally.charName, value = 20, min = 1, max = 100, leftIcon = "https://raw.githubusercontent.com/TheRipperGos/GoS/master/Sprites/"..ally.charName..".png"})
		end
		TRS.Shield.minE:MenuElement({id = ally.networkID, name = myHero.charName, value = 20, min = 1, max = 100, leftIcon = "https://raw.githubusercontent.com/TheRipperGos/GoS/master/Sprites/Karma.png"})
	end
	TRS.Shield:MenuElement({id = "spellsE", name = "Auto Use [E] to shield spells", value = true})
	--- Draw ---
	TRS:MenuElement({type = MENU, id = "Draw", name = "Draw Settings"})
	TRS.Draw:MenuElement({id = "Q", name = "Draw [Q] Range", value = true, leftIcon = Q.icon})
	TRS.Draw:MenuElement({id = "W", name = "Draw [W] Range", value = true, leftIcon = W.icon})
		--------- Prediction --------------------------------------------------------------------
	TRS:MenuElement({type = MENU, id = "Pred", name = "Prediction Settings"})
	TRS.Pred:MenuElement({id = "Chance", name = "Hitchance", value = 0.0, min = 0.0, max = 1, step = 0.05})
end

function Karma:Tick()
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
	self:Misc()
	self:Shield()
end

local LastW = Game.Timer()

function Karma:Combo()
	local target = GetTarget(950)
	if not target then return end
	if myHero.pos:DistanceTo(target.pos) < 675 then
		if TRS.Combo.R:Value() and Ready(_R) and Ready(_W or _E or _Q) then
		Control.CastSpell(HK_R)
		end
		if TRS.Combo.W:Value() and Ready(_W) then
			Control.CastSpell(HK_W,target.pos)
--		LastW
		end
		if TRS.Combo.E:Value() and Ready(_E and _Q or _W) then
			Control.CastSpell(HK_E,myHero)
		end
		if TRS.Combo.Q:Value() and Ready(_Q) and target:GetCollision(Q.width,Q.speed,Q.delay) == 0 then
--			if Game.Timer() - LastW > 2 then
		CastSpell(HK_Q,_Q,target,TYPE_LINE)
--					end
		end
	else 
	if myHero.pos:DistanceTo(target.pos) < 950 then
		if TRS.Combo.Q:Value() and Ready(_Q) then
			if TRS.Combo.R:Value() and Ready(_R) then
			Control.CastSpell(HK_R)
			end
		CastSpell(HK_Q,_Q,target,TYPE_LINE)
		return
		end
		if TRS.Combo.E:Value() and Ready(_E) then
			if TRS.Combo.R:Value() and Ready(_R) then
			Control.CastSpell(HK_R)
			end
		Control.CastSpell(HK_E,myHero)
		return
		end
	end
	end
end

function Karma:Harass()
	local target = GetTarget(950)
	if TRS.Harass.Key:Value() == false then return end
	if myHero.mana/myHero.maxMana < TRS.Harass.Mana:Value() then return end
	if not target then return end
	if TRS.Harass.Q:Value() and Ready(_Q) and myHero.pos:DistanceTo(target.pos) < 950 and target:GetCollision(Q.width,Q.speed,Q.delay) == 0  then
		CastSpell(HK_Q,_Q,target,TYPE_LINE)
	end
end

function Karma:Clear()
	if TRS.Clear.Q:Value() == false then return end
	if myHero.mana/myHero.maxMana < TRS.Clear.Mana:Value() then return end
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if  minion.team = 200 or 300 then
			if  TRS.Clear.Q:Value() and Ready(_Q) and myHero.pos:DistanceTo(minion.pos) < 950 then
				Control.CastSpell(HK_Q,minion.pos)
			end
		end
	end
end

function Karma:Misc()
	local target = GetTarget(950)
	if not target then return end
	if TRS.Misc.Qks:Value() and Ready(_Q) then
		local Qdmg = CalcMagicalDamage(myHero, target, ( 35 + 45 * myHero:GetSpellData(_Q).level + 0.6 * myHero.ap))
		local Qrdmg = CalcMagicalDamage(myHero, target, ( 35 + 45 * myHero:GetSpellData(_Q).level + 25 + 50 * myHero:GetSpellData(_R).level + 0.9 * myHero.ap))
		if not self:HasMantra() and Qdmg > target.health and Ready(_Q) then
			CastSpell(HK_Q,_Q,target,TYPE_LINE)
		end
		if self:HasMantra() and Qrdmg > target.health and Ready(_Q) then
			CastSpell(HK_Q,_Q,target,TYPE_LINE)
		end			
	end
	if TRS.Misc.Wks:Value() and Ready(_W) and myHero.pos:DistanceTo(target.pos) < 675 then
		local Wdmg = CalcPhysicalDamage(myHero, target, (5 + 15 * myHero:GetSpellData(_W).level + myHero.totalDamage))
		if Wdmg > target.health and target:GetCollision(W.width,W.speed,W.delay) == 0 and Ready(_W) then
			Control.CastSpell(HK_W,target)
		end
	end
end

function Karma:Shield()
	if TRS.Shield.E:Value() == false then return end
	if not Ready(_E) then return end
	-- Shield to low HP
	for i,ally in pairs(GetAllyHeroes()) do
		if myHero.pos:DistanceTo(ally.pos) < 600 and not ally.dead then
			if TRS.Shield.Elist[ally.networkID]:Value() and HeroesAround(ally.pos, 500, 200) > 0 then
				if (ally.health/ally.maxHealth <= TRS.Shield.minE[ally.networkID]:Value() / 100) and Ready(_E) then
				Control.CastSpell(HK_E,ally)
				end
				if (myHero.health/myHero.maxHealth <= TRS.Shield.minE[myHero.networkID]:Value() / 100) and Ready(_E) then
				Control.CastSpell(HK_E,myHero)
				end
			end
		end
	end
	if TRS.Shield.spellsE:Value() then
	--auto protect missiles MeoBeo credits
		for i = 1, Game.MissileCount() do
		local obj = Game.Missile(i)
		if obj and obj.isEnemy and obj.missileData and self.MissileSpells[obj.missileData.name] then
			local speed = obj.missileData.speed
			local width = obj.missileData.width
			local endPos = obj.missileData.endPos
			local pos = obj.pos
			if speed and width and endPos and pos then
				for k, ally in pairs(GetAllyHeroes()) do 
					if not ally.dead and myHero.pos:DistanceTo(ally.pos) < 800 then
						local pointSegment,pointLine,isOnSegment = VectorPointProjectionOnLineSegment(pos,endPos,ally.pos)
						if isOnSegment and ally.pos:DistanceTo(Vector(pointSegment.x,myHero.pos.y,pointSegment.y)) < width+ ally.boundingRadius and Ready(_E) then
						CastSpell(HK_E,ally)
						end
					end
				end
			elseif pos then
				for k,ally in pairs(GetAllyHeroes()) do
					if not ally.dead and myHero.pos:DistanceTo(ally.pos) < 800 and pos:DistanceTo(ally.pos) < 80 and Ready(_E) then
					CastSpell(HK_E,ally)
					end
				end
			end
		end
	end
	self.MissileSpells = {}
	for i = 1,Game.HeroCount() do
	local hero = Game.Hero(i)
	if hero.isEnemy then
		if HeroesAround(myHero.pos,1100,200) and hero.isChanneling then
		local currSpell = hero.activeSpell
		local sRadious = 100
		local spellPos = Vector(currSpell.placementPos.x, currSpell.placementPos.y, currSpell.placementPos.z)
		if (spellPos:DistanceTo(myHero.pos) < 100) and Ready(_E) then
			Control.CastSpell(HK_E, myHero.pos)
		end			
	end
		if self.MissileSpells[hero.charName] then
			for k,v in pairs(self.MissileSpells[hero.charName]) do
				if #v > 1 then
				self.MissileSpells[v] = true
				end	
				end
			end
		end
	end
	end
end

function Karma:HasMantra()
	for i = 0, myHero.buffCount do
		local buff = myHero:GetBuff(i)
		if buff.name and buff.name:lower() == "karmamantra" and buff.count > 0 and Game.Timer() < buff.expireTime then 
		return true
		end
	end
	return false
end

function Karma:Draw()
	if TRS.Draw.W:Value() and Ready(_W) then Draw.Circle(myHero.pos, 675, 3,  Draw.Color(255,255, 162, 000)) end
	if TRS.Draw.Q:Value() and Ready(_Q) then Draw.Circle(myHero.pos, 950, 3,  Draw.Color(255,255, 162, 000)) end
end

Callback.Add("Load", function()
	if not _G.Prediction_Loaded then return end
	if _G[myHero.charName] then
		_G[myHero.charName]()
		print("TRS "..ScriptVersion..": "..myHero.charName.."  Loaded")
	else print ("TRS doens't support "..myHero.charName.." shutting down...") return end
	end
end)
