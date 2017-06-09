require 'DamageLib'
require 'Eternal Prediction'

local ScriptVersion = "Pre-Release"
--- Engine ---
local function Ready(spell)
	return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana and Game.CanUseSpell(spell) == 0 
end

local function OnScreen(unit)
	return unit.pos:To2D().onScreen;
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

local function GetTarget(range)
	local target = nil
	if Orb == 1 then
		target = EOW:GetTarget(range)
	elseif Orb == 2 then
		target = _G.SDK.TargetSelector:GetTarget(range)
	elseif Orb == 3 then
		target = GOS:GetTarget(range)
	end
	return target
end

local intToMode = {
   	[0] = "None",
   	[1] = "Combo",
   	[2] = "Harass",
   	[3] = "LastHit",
   	[4] = "Clear"
}

local function GetMode()
	if Orb == 1 then
		return intToMode[EOW.CurrentMode]
	elseif Orb == 2 then
		if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
			return "Combo"
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then
			return "Harass"	
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR] or _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR] then
			return "Clear"
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT] then
			return "LastHit"
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

local function HasBuff(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name == buffname and buff.count > 0 then 
			return true
		end
	end
	return false
end
--- Engine ---
--- Elise ---
class "Elise"

function Elise:__init()
	if _G.EOWLoaded then
		Orb = 1
	elseif _G.SDK and _G.SDK.Orbwalker then
		Orb = 2
	end
	self:LoadSpells()
	self:LoadMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end

function Elise:LoadSpells()
	Q = { range = myHero:GetSpellData(_Q).range, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed, width = myHero:GetSpellData(_Q).width}
	W = { range = myHero:GetSpellData(_W).range, delay = myHero:GetSpellData(_W).delay, speed = myHero:GetSpellData(_W).speed, width = myHero:GetSpellData(_W).width }
	E = { range = myHero:GetSpellData(_E).range, delay = myHero:GetSpellData(_E).delay, speed = myHero:GetSpellData(_E).speed, width = myHero:GetSpellData(_E).width }
	R = { range = myHero:GetSpellData(_R).range, delay = myHero:GetSpellData(_R).delay, speed = myHero:GetSpellData(_R).speed, width = myHero:GetSpellData(_R).width }
end

function Elise:LoadMenu()
	Romanov = MenuElement({type = MENU, id = "Romanov", name = "Romanov Elise"})
	--- Version ---
	Romanov:MenuElement({name = "Elise", drop = {ScriptVersion}, leftIcon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/9/91/EliseSquare.png"})
	--- Combo ---
	Romanov:MenuElement({type = MENU, id = "Combo", name = "Combo Settings"})
	Romanov.Combo:MenuElement({id = "Q", name = "Human [Q]",  value = true})
	Romanov.Combo:MenuElement({id = "W", name = "Human [W]",  value = true})
	Romanov.Combo:MenuElement({id = "E", name = "Human [E]",  value = true})
	Romanov.Combo:MenuElement({id = "Q2", name = "Spider [Q]",  value = true})
	Romanov.Combo:MenuElement({id = "W2", name = "Spider [W]",  value = true})
	Romanov.Combo:MenuElement({id = "E2", name = "Spider [E]",  value = true})
	Romanov.Combo:MenuElement({id = "BE", name = "Max Enemies to Rappel", value = 2, min = 1, max = 5})
	Romanov.Combo:MenuElement({id = "R", name = "Auto [R]", value = true})
	Romanov.Combo:MenuElement({type = SPACE, id = "info", name = "Tip: Manual [R] is better"})
	--- Clear ---
	Romanov:MenuElement({type = MENU, id = "Clear", name = "Jungle Clear Settings"})
	Romanov.Clear:MenuElement({id = "Key", name = "Toggle: Key", key = string.byte("A"), toggle = true})
	Romanov.Clear:MenuElement({id = "Q", name = "Human [Q]",  value = true})
	Romanov.Clear:MenuElement({id = "W", name = "Human [W]",  value = true})
	Romanov.Clear:MenuElement({id = "E", name = "Human [E]",  value = false})
	Romanov.Clear:MenuElement({id = "Q2", name = "Spider [Q]",  value = true})
	Romanov.Clear:MenuElement({id = "W2", name = "Spider [W]",  value = true})
	Romanov.Clear:MenuElement({id = "E2", name = "Spider [E]",  value = true})
	Romanov.Clear:MenuElement({id = "R", name = "Auto [R]", value = true})
	Romanov.Clear:MenuElement({type = SPACE, id = "info", name = "Tip: Manual [R] is better"})
	Romanov.Clear:MenuElement({id = "Mana", name = "Min Mana to Clear [%]", value = 0, min = 0, max = 100})
	--- Misc ---
	Romanov:MenuElement({type = MENU, id = "Misc", name = "KS Settings"})
	Romanov.Misc:MenuElement({id = "Q", name = "KS Human [Q]", value = true})
	Romanov.Misc:MenuElement({id = "Q2", name = "KS Spider [Q]", value = true})
	Romanov.Misc:MenuElement({id = "W", name = "KS Human [W]", value = true})
	--- Draw ---
	Romanov:MenuElement({type = MENU, id = "Draw", name = "Draw Settings"})
	Romanov.Draw:MenuElement({id = "Q", name = "Draw Human [Q]", value = true})
	Romanov.Draw:MenuElement({id = "Q2", name = "Draw Spider [Q]", value = true})
	Romanov.Draw:MenuElement({id = "W", name = "Draw [W]", value = true})
	Romanov.Draw:MenuElement({id = "E", name = "Draw Human [E]", value = true})
	Romanov.Draw:MenuElement({id = "E2", name = "Draw Spider [E]", value = true})
	Romanov.Draw:MenuElement({id = "CT", name = "Clear Toggle", value = true})
	Romanov.Draw:MenuElement({id = "DMG", name = "Draw Combo Damage", value = true})
	--- Pred ---
	Romanov:MenuElement({type = MENU, id = "Pred", name = "Pred Settings"})
	Romanov.Pred:MenuElement({id = "Chance", name = "Pred Hitchance", value = 0.2, min = 0.05, max = 1, step = 0.025})
end

function Elise:Tick()
	local Mode = GetMode()
	if Mode == "Combo" then
		self:Combo()
	elseif Mode == "Clear" then
		self:Clear()
	end
		self:KS()
end

function Elise:Combo()
	local target = GetTarget(1075)
	if target == nil then return end
	if HasBuff(myHero,"EliseR") then
		if Romanov.Combo.Q2:Value() and Ready(_Q) and myHero.pos:DistanceTo(target.pos) < 475 then
			Control.CastSpell(HK_Q,target)
		end
		if Romanov.Combo.W2:Value() and Ready(_W)  and myHero.pos:DistanceTo(target.pos) < 300 then
			Control.CastSpell(HK_W)
		end
		if Romanov.Combo.E2:Value() and Ready(_E) and  myHero.pos:DistanceTo(target.pos) > 400 and HeroesAround(target, 600, 200) <= Romanov.Combo.BE:Value() then
			Control.CastSpell(HK_E,target)
		end
		if Romanov.Combo.R:Value() and Ready(_R) and not Ready(_Q) and not Ready (_W) then
			Control.CastSpell(HK_R)
		end
	else
		if Romanov.Combo.E:Value() and Ready(_E) and myHero.pos:DistanceTo(target.pos) < 1075 then
			self:CastE(target)
		end
		if Romanov.Combo.W:Value() and Ready(_W) and not Ready(_E) and myHero.pos:DistanceTo(target.pos) < 950 then
			Control.CastSpell(HK_W,target)
		end
		if Romanov.Combo.Q:Value() and Ready(_Q) and not Ready(_W) and myHero.pos:DistanceTo(target.pos) < 625 then
			Control.CastSpell(HK_Q,target)
		end
		if Romanov.Combo.R:Value() and Ready(_R) and not Ready(_Q) and not Ready (_W) and not Ready(_E) then
			Control.CastSpell(HK_R)
		end
	end
end

function Elise:Clear()
	if Romanov.Clear.Key:Value() == false then return end
	if myHero.mana/myHero.maxMana < Romanov.Clear.Mana:Value() then return end
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if  minion and minion.team == 300 then
			if HasBuff(myHero,"EliseR") then
				if Romanov.Clear.Q2:Value() and Ready(_Q) and myHero.pos:DistanceTo(minion.pos) < 475 then
					Control.CastSpell(HK_Q,minion)
				end
				if Romanov.Clear.W2:Value() and Ready(_W)  and myHero.pos:DistanceTo(minion.pos) < 300 then
					Control.CastSpell(HK_W)
				end
				if Romanov.Clear.E2:Value() and Ready(_E) and  myHero.pos:DistanceTo(minion.pos) > 400 and HeroesAround(minion, 600, 200) <= Romanov.Clear.BE:Value() then
					Control.CastSpell(HK_E,minion)
				end
				if Romanov.Clear.R:Value() and Ready(_R) and not Ready(_Q) and not Ready (_W) then
					Control.CastSpell(HK_R)
				end
			else
				if Romanov.Clear.E:Value() and Ready(_E) and myHero.pos:DistanceTo(minion.pos) < 1075 then
					self:CastE(minion)
				end
				if Romanov.Clear.W:Value() and Ready(_W) and not Ready(_E) and myHero.pos:DistanceTo(minion.pos) < 950 then
					Control.CastSpell(HK_W,minion)
				end
				if Romanov.Clear.Q:Value() and Ready(_Q) and myHero.pos:DistanceTo(minion.pos) < 625 then
					Control.CastSpell(HK_Q,minion)
				end
				if Romanov.Clear.R:Value() and Ready(_R) and not Ready(_Q) and not Ready (_W) and not Ready(_E) then
					Control.CastSpell(HK_R)
				end
			end
		end
	end
end

function Elise:KS()
	local target = GetTarget(900)
	if target == nil then return end
	if HasBuff(myHero,"EliseR") then
		if Romanov.Misc.Q:Value() and Ready(_Q) and myHero.pos:DistanceTo(target.pos) < 475 then
			local Q2dmg = CalcMagicalDamage(myHero, target, (20+40*myHero:GetSpellData(_Q).level + (0.08 + 0.03 / 100 * myHero.ap) * (target.maxHealth - target.health)))
			if Q2dmg > target.health then
				Control.CastSpell(HK_Q,target)
			end
		end
	else
		if Romanov.Misc.Q:Value() and Ready(_Q) and myHero.pos:DistanceTo(target.pos) < 625 then
			local Qdmg = CalcMagicalDamage(myHero, target, (5+ 35*myHero:GetSpellData(_Q).level + (0.08 + 0.03 / 100 * myHero.ap) * target.health))
			if Qdmg > target.health then
				Control.CastSpell(HK_Q,target)
			end
		end
		if Romanov.Misc.W:Value() and Ready(_W) and myHero.pos:DistanceTo(target.pos) < 900 then
			local Wdmg = CalcMagicalDamage(myHero, target, (10+50*myHero:GetSpellData(_Q).level + 0.8 * myHero.ap))
			if Wdmg > target.health then
				Control.CastSpell(HK_W,target)
			end
		end
	end
end

function Elise:CastE(target)
	local Qdata = {speed = 1600, delay = 0.25,range = 1075 }
	local Qspell = Prediction:SetSpell(Qdata, TYPE_LINEAR, true)
	local pred = Qspell:GetPrediction(target,myHero.pos)
	if pred and pred.hitChance >= Romanov.Pred.Chance:Value() and pred:mCollision() == 0 and pred:hCollision() == 0 then
		EnableOrb(false)
		Control.CastSpell(HK_E,pred.castPos)
		EnableOrb(true)
	end
end

function Elise:GetComboDamage(unit)
	local Total = 0
	local Qdmg = CalcMagicalDamage(myHero, unit, (5+ 35*myHero:GetSpellData(_Q).level + (0.08 + 0.03 / 100 * myHero.ap) * unit.health))
	local Q2dmg = CalcMagicalDamage(myHero, unit, (20+40*myHero:GetSpellData(_Q).level + (0.08 + 0.03 / 100 * myHero.ap) * (unit.maxHealth - unit.health)))
	local Wdmg =  CalcMagicalDamage(myHero, unit, (10+50*myHero:GetSpellData(_Q).level + 0.8 * myHero.ap))
	if HasBuff(myHero,"EliseR") then
		if Ready(_Q) then
			Total = Total + Q2dmg
		end
		return Total
	else
		if Ready(_Q) then
			Total = Total + Qdmg
		end
		if Ready(_W) then
			Total = Total + Wdmg
		end
		return Total
	end
end

function Elise:Draw()
	local MenuQ = Romanov.Draw.Q:Value()
	local MenuE = Romanov.Draw.E:Value()
	if HasBuff(myHero,"EliseR") then
		if Romanov.Draw.Q2:Value() and Ready(_Q) then Draw.Circle(myHero.pos, 475, 3,  Draw.Color(255,255, 162, 000)) end
		if Romanov.Draw.E2:Value() and Ready(_E) then Draw.Circle(myHero.pos, 800, 3,  Draw.Color(255,255, 000, 000)) end
	else
		if Romanov.Draw.Q:Value() and Ready(_Q) then Draw.Circle(myHero.pos, 625, 3,  Draw.Color(255,255, 162, 000)) end
		if Romanov.Draw.W:Value() and Ready(_W) then Draw.Circle(myHero.pos, 950, 3,  Draw.Color(255,000, 162, 255)) end
		if Romanov.Draw.E:Value() and Ready(_E) then Draw.Circle(myHero.pos, 1075, 3,  Draw.Color(255,255, 000, 000)) end
	end
	if Romanov.Draw.CT:Value() then
		local textPos = myHero.pos:To2D()
		if Romanov.Clear.Key:Value() then
			Draw.Text("Clear: On", 20, textPos.x - 33, textPos.y + 60, Draw.Color(255, 000, 255, 000)) 
		else
			Draw.Text("Clear: Off", 20, textPos.x - 33, textPos.y + 60, Draw.Color(255, 225, 000, 000)) 
		end
	end
	if Romanov.Draw.DMG:Value() then
		for i = 1, Game.HeroCount() do
			local enemy = Game.Hero(i)
			if enemy and enemy.isEnemy and not enemy.dead then
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

Callback.Add("Load", function()
	if not _G.Prediction_Loaded then return end
	if _G[myHero.charName] then
		_G[myHero.charName]()
		print("Romanov "..myHero.charName.." "..ScriptVersion.." Loaded")
		print("PM me for suggestions/fix problems")
		print("Discord: Romanov#6333")
	else print ("Romanov doens't support "..myHero.charName.." shutting down...") return
	end
end)
