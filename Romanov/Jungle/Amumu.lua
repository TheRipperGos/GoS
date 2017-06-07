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
--- Engine ---
--- Amumu ---
class "Amumu"

function Amumu:__init()
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

function Amumu:LoadSpells()
	Q = { range = myHero:GetSpellData(_Q).range, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed, width = myHero:GetSpellData(_Q).width, icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/b/b5/Bandage_Toss.png" }
	W = { range = myHero:GetSpellData(_W).range, delay = myHero:GetSpellData(_W).delay, speed = myHero:GetSpellData(_W).speed, width = myHero:GetSpellData(_W).width, icon = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/2/25/Despair.png" }
	E = { range = myHero:GetSpellData(_E).range, delay = myHero:GetSpellData(_E).delay, speed = myHero:GetSpellData(_E).speed, width = myHero:GetSpellData(_E).width, icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/b/b3/Tantrum.png" }
	R = { range = myHero:GetSpellData(_R).range, delay = myHero:GetSpellData(_R).delay, speed = myHero:GetSpellData(_R).speed, width = myHero:GetSpellData(_R).width, icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/7/72/Curse_of_the_Sad_Mummy.png" }
end

function Amumu:LoadMenu()
	Romanov = MenuElement({type = MENU, id = "Romanov", name = "Romanov Amumu"})
	--- Version ---
	Romanov:MenuElement({name = "Amumu", drop = {ScriptVersion}, leftIcon = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/2/26/AmumuSquare.png"})
	--- Combo ---
	Romanov:MenuElement({type = MENU, id = "Combo", name = "Combo Settings"})
	Romanov.Combo:MenuElement({id = "Q", name = "Use [Q]", value = true, leftIcon = Q.icon})
	Romanov.Combo:MenuElement({id = "W", name = "Use [W]", value = true, leftIcon = W.icon})
	Romanov.Combo:MenuElement({id = "E", name = "Use [E]", value = true, leftIcon = E.icon})
	Romanov.Combo:MenuElement({id = "R", name = "Use [R]", value = true, leftIcon = R.icon})
	Romanov.Combo:MenuElement({id = "RE", name = "Min Enemies to [R]", value = 3, min = 1, max = 5})
	--- Clear ---
	Romanov:MenuElement({type = MENU, id = "Clear", name = "Clear Settings"})
	Romanov.Clear:MenuElement({id = "Key", name = "Toggle: Key", key = string.byte("A"), toggle = true})
	Romanov.Clear:MenuElement({id = "Q", name = "Use [Q]", value = true, leftIcon = Q.icon})
	Romanov.Clear:MenuElement({id = "W", name = "Use [W]", value = true, leftIcon = W.icon})
	Romanov.Clear:MenuElement({id = "E", name = "Use [E]", value = true, leftIcon = E.icon})
	Romanov.Clear:MenuElement({id = "Mana", name = "Min Mana to Clear [%]", value = 0, min = 0, max = 100})
	--- Misc ---
	Romanov:MenuElement({type = MENU, id = "Misc", name = "Misc Settings"})
	Romanov.Misc:MenuElement({id = "Raoe", name = "Auto Use [R]", value = true})
	Romanov.Misc:MenuElement({id = "RE", name = "Min Enemies to Auto [R]", value = 4, min = 1, max = 5})
	Romanov.Misc:MenuElement({id = "Qks", name = "Killsecure [Q]", value = true, leftIcon = Q.icon})
	Romanov.Misc:MenuElement({id = "Eks", name = "Killsecure [E]", value = true, leftIcon = E.icon})
	Romanov.Misc:MenuElement({id = "Rks", name = "Killsecure [R]", value = true, leftIcon = R.icon})
	--- Draw ---
	Romanov:MenuElement({type = MENU, id = "Draw", name = "Draw Settings"})
	Romanov.Draw:MenuElement({id = "Q", name = "Draw [Q] Range", value = true, leftIcon = Q.icon})
	Romanov.Draw:MenuElement({id = "R", name = "Draw [R] Range", value = true, leftIcon = R.icon})
	Romanov.Draw:MenuElement({id = "CT", name = "Clear Toggle", value = true})
	Romanov.Draw:MenuElement({id = "DMG", name = "Draw Combo Damage", value = true})
end

function Amumu:Tick()
	local Mode = GetMode()
	if Mode == "Combo" then
		self:Combo()
	elseif Mode == "Clear" then
		self:Clear()
	else
		self:DisableW()
	end
		self:Misc()
end

function Amumu:DisableW()
	if myHero:GetSpellData(_W).toggleState == 2 then
		Control.CastSpell(HK_W)
	end
end

function Amumu:Combo()
	local target = GetTarget(1050)
	if target == nil then return end
		if Romanov.Combo.R:Value() and Ready(_R) and myHero.pos:DistanceTo(target.pos) < 550 and  Romanov.Combo.RE:Value() <= HeroesAround(myHero.pos, 550, 200) then
			Control.CastSpell(HK_R)
		end
		if Romanov.Combo.Q:Value() and Ready(_Q) then
			self:CastQ(target)
		end
		if Romanov.Combo.W:Value() and Ready(_W)and myHero.pos:DistanceTo(target.pos) < 300 and myHero:GetSpellData(_W).toggleState ~= 2 then
			Control.CastSpell(HK_W)
		end
		if Romanov.Combo.E:Value() and Ready(_E) and myHero.pos:DistanceTo(target.pos) < 350 then
			Control.CastSpell(HK_E)
		end
		
end

function Amumu:Clear()
	if Romanov.Clear.Key:Value() == false then return end
	if myHero.mana/myHero.maxMana < Romanov.Clear.Mana:Value() then return end
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if  minion and minion.team ~= myHero.team then
			if  Romanov.Clear.Q:Value() and Ready(_Q) and myHero.pos:DistanceTo(minion.pos) < 1050 and myHero.pos:DistanceTo(minion.pos) > 350 then
				Control.SetCursorPos(minion)
				Control.KeyDown(HK_Q)
				Control.KeyUp(HK_Q)
			end
			if  Romanov.Clear.W:Value() and Ready(_W) and myHero.pos:DistanceTo(minion.pos) < 300 and myHero:GetSpellData(_W).toggleState ~= 2 then
				Control.CastSpell(HK_W)
			end
			if  Romanov.Clear.E:Value() and Ready(_E) and myHero.pos:DistanceTo(minion.pos) < 350 then
				Control.CastSpell(HK_E)
			end
		end
	end
end

function Amumu:Misc()
	local target = GetTarget(1050)
	if not target then return end
	if Romanov.Misc.Raoe:Value() and Ready(_R) and myHero.pos:DistanceTo(target.pos) < 550 and  Romanov.Misc.RE:Value() <= HeroesAround(myHero.pos, 550, 200) then
		Control.CastSpell(HK_R)
	end
	if Romanov.Misc.Qks:Value() and Ready(_Q)and myHero.pos:DistanceTo(target.pos) < 1050 then
		local Qdmg = CalcMagicalDamage(myHero, target, (30 + 50 * myHero:GetSpellData(_Q).level + 0.7* myHero.ap))
		if Qdmg > target.health then
			self:CastQ(target)
		end
	end
	if Romanov.Misc.Eks:Value() and Ready(_E)and myHero.pos:DistanceTo(target.pos) < 350 then
		local Edmg = CalcMagicalDamage(myHero, target, (50 + 25 * myHero:GetSpellData(_E).level + 0.5* myHero.ap))
		if Edmg > target.health then
			Control.CastSpell(HK_E)
		end
	end
	if Romanov.Misc.Rks:Value() and Ready(_R)and myHero.pos:DistanceTo(target.pos) < 550 then
		local Rdmg = CalcMagicalDamage(myHero, target, (50 + 100 * myHero:GetSpellData(_R).level + 0.8* myHero.ap))
		if Rdmg > target.health then
			Control.CastSpell(HK_R)
		end
	end
end

function Amumu:CastQ(target)
	local Qdata = {speed = 2000, delay = 0.25,range = 1100 }
	local Qspell = Prediction:SetSpell(Qdata, TYPE_LINEAR, true)
	local pred = Qspell:GetPrediction(target,myHero.pos)
	if pred and pred.hitChance >= 0.25 and pred:mCollision() == 0 and pred:hCollision() == 0 then
		EnableOrb(false)
		Control.SetCursorPos(pred.castPos)
		Control.KeyDown(HK_Q)
		Control.KeyUp(HK_Q)
		EnableOrb(true)
	end
end

function Amumu:GetComboDamage(unit)
	local Total = 0
	local Qdmg = CalcMagicalDamage(myHero, unit, (30 + 50 * myHero:GetSpellData(_Q).level + 0.7* myHero.ap))
	local Edmg = CalcMagicalDamage(myHero, unit, (50 + 25 * myHero:GetSpellData(_E).level + 0.5* myHero.ap))
	local Rdmg = CalcMagicalDamage(myHero, unit, (50 + 100 * myHero:GetSpellData(_R).level + 0.8* myHero.ap))
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

function Amumu:Draw()
	if Romanov.Draw.Q:Value() and Ready(_Q) then Draw.Circle(myHero.pos, 1100, 3,  Draw.Color(255,255, 162, 000)) end
	if Romanov.Draw.R:Value() and Ready(_R) then Draw.Circle(myHero.pos, 550, 3,  Draw.Color(255,255, 000, 000)) end
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
