require 'DamageLib'
require 'Eternal Prediction'
require '2DGeometry'

local AioVersion = "v1.0"
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

local ItemHotKey = {
	[ITEM_1] = HK_ITEM_1,
	[ITEM_2] = HK_ITEM_2,
	[ITEM_3] = HK_ITEM_3,
	[ITEM_4] = HK_ITEM_4,
	[ITEM_5] = HK_ITEM_5,
	[ITEM_6] = HK_ITEM_6,}

function GetItemSlot(unit, id)
	for i = ITEM_1, ITEM_7 do
		if unit:GetItemData(i).itemID == id then
			return i
		end
	end
	return 0
end

local function PredCast(hotkey,slot,target,predmode)
	local data = { range = myHero:GetSpellData(slot).range, delay = myHero:GetSpellData(slot).delay, speed = myHero:GetSpellData(slot).speed}
	local spell = Prediction:SetSpell(data, predmode, true)
	local pred = spell:GetPrediction(target,myHero.pos)
	if pred and pred.hitChance >= Romanov.Pred.Chance:Value() then
		Control.CastSpell(hotkey, pred.castPos)
	end
end

local function PredMinimapCast(hotkey,slot,target,predmode)
	local data = { range = myHero:GetSpellData(slot).range, delay = myHero:GetSpellData(slot).delay, speed = myHero:GetSpellData(slot).speed}
	local spell = Prediction:SetSpell(data, predmode, true)
	local pred = spell:GetPrediction(target,myHero.pos)
	if pred and pred.hitChance >= 0.25 then
		Control.CastSpell(hotkey, pred.castPos:ToMM().x,pred.castPos:ToMM().y)
	end
end
--- Engine ---
--- Amumu ---
class "Amumu"

local AmumuVersion = "v1.0"

function Amumu:__init()
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
	Romanov = MenuElement({type = MENU, id = "Romanov", name = "Romanov AIO "..AioVersion})
	--- Version ---
	Romanov:MenuElement({name = "Amumu", drop = {AmumuVersion}, leftIcon = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/2/26/AmumuSquare.png"})
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
	--- Hitchance ---
	Romanov:MenuElement({type = MENU, id = "Pred", name = "Prediction Settings"})
	Romanov.Pred:MenuElement({id = "Chance", name = "Hitchance", value = 0.15, min = 0.1, max = 1, step = 0.05})
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
		PredCast(HK_Q,_Q,target,TYPE_LINE)
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
				PredCast(HK_Q,_Q,minion,TYPE_LINE)
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
			PredCast(HK_Q,_Q,target,TYPE_LINE)
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
--- Amumu ---
--- Ashe ---
class "Ashe"

local AsheVersion = "v1.0"

function Ashe:__init()
	self:LoadSpells()
	self:LoadMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end

function Ashe:LoadSpells()
	Q = { range = myHero:GetSpellData(_Q).range, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed, width = myHero:GetSpellData(_Q).width, icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/1/1d/Ranger%27s_Focus.png" }
	W = { range = myHero:GetSpellData(_W).range, delay = myHero:GetSpellData(_W).delay, speed = myHero:GetSpellData(_W).speed, width = myHero:GetSpellData(_W).width, icon = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/5/5d/Volley.png" }
	R = { range = myHero:GetSpellData(_R).range, delay = myHero:GetSpellData(_R).delay, speed = myHero:GetSpellData(_R).speed, width = myHero:GetSpellData(_R).width, icon = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/2/28/Enchanted_Crystal_Arrow.png" }
end

function Ashe:LoadMenu()
	Romanov = MenuElement({type = MENU, id = "Romanov", name = "Romanov AIO "..AioVersion})
	--- Version ---
	Romanov:MenuElement({name = "Ashe", drop = {AsheVersion}, leftIcon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/4/4a/AsheSquare.png"})
	--- Combo ---
	Romanov:MenuElement({type = MENU, id = "Combo", name = "Combo Settings"})
	Romanov.Combo:MenuElement({id = "Q", name = "Use [Q]", value = true, leftIcon = Q.icon})
	Romanov.Combo:MenuElement({id = "W", name = "Use [W]", value = true, leftIcon = W.icon})
	Romanov.Combo:MenuElement({id = "R", name = "[R] Smart Combo [?]", value = true, leftIcon = R.icon, tooltip = "It'll cast R when total combo DMG will kill target"})
	Romanov.Combo:MenuElement({id = "RAA", name = "Auto Attacks After Ult", value = 5, min = 1, max = 15})
	--- Clear ---
	Romanov:MenuElement({type = MENU, id = "Clear", name = "Clear Settings"})
	Romanov.Clear:MenuElement({id = "Key", name = "Toggle: Key", key = string.byte("A"), toggle = true})
	Romanov.Clear:MenuElement({id = "Q", name = "Use [Q]", value = true, leftIcon = Q.icon})
	Romanov.Clear:MenuElement({id = "W", name = "Use [W]", value = true, leftIcon = W.icon})
	Romanov.Clear:MenuElement({id = "Mana", name = "Min Mana to Clear [%]", value = 0, min = 0, max = 100})
	--- Harass ---
	Romanov:MenuElement({type = MENU, id = "Harass", name = "Harass Settings"})
	Romanov.Harass:MenuElement({id = "Key", name = "Toggle: Key", key = string.byte("S"), toggle = true})
	Romanov.Harass:MenuElement({id = "Q", name = "Use [Q]", value = true, leftIcon = Q.icon})
	Romanov.Harass:MenuElement({id = "W", name = "Use [W]", value = true, leftIcon = W.icon})
	Romanov.Harass:MenuElement({id = "Mana", name = "Min Mana to Harass [%]", value = 0, min = 0, max = 100})
	--- Misc ---
	Romanov:MenuElement({type = MENU, id = "Misc", name = "Misc Settings"})
	Romanov.Misc:MenuElement({id = "Rkey", name = "Semi-Manual [R] Key [?]", key = string.byte("T"), tooltip = "Select manually your target before pressing the key"})
	Romanov.Misc:MenuElement({id = "Raoe", name = "Auto Use [R] AoE", value = true})
	Romanov.Misc:MenuElement({id = "Rally", name = "Min Near Allies to [R] AoE", value = 2, min = 1, max = 5})
	Romanov.Misc:MenuElement({id = "Rene", name = "Enemies to [R] AoE", value = 3, min = 1, max = 5})
	Romanov.Misc:MenuElement({id = "Rmax", name = "Max Distance to [R] AoE", value = 3600, min = 200, max = 20000, step = 200})
	Romanov.Misc:MenuElement({id = "Wks", name = "Killsecure [W]", value = true, leftIcon = W.icon})
	Romanov.Misc:MenuElement({id = "Rks", name = "Killsecure [R]", value = true, leftIcon = R.icon})
	--- Draw ---
	Romanov:MenuElement({type = MENU, id = "Draw", name = "Draw Settings"})
	Romanov.Draw:MenuElement({id = "W", name = "Draw [W] Range", value = true, leftIcon = W.icon})
	Romanov.Draw:MenuElement({id = "CT", name = "Clear Toggle", value = true})
	Romanov.Draw:MenuElement({id = "HT", name = "Harass Toggle", value = true})
	Romanov.Draw:MenuElement({id = "DMG", name = "Draw Combo Damage", value = true})
	--- Hitchance ---
	Romanov:MenuElement({type = MENU, id = "Pred", name = "Prediction Settings"})
	Romanov.Pred:MenuElement({id = "Chance", name = "Hitchance", value = 0.15, min = 0.1, max = 1, step = 0.05})
end

function Ashe:Tick()
	local Mode = GetMode()
	if Mode == "Combo" then
		self:Combo()
	elseif Mode == "Harass" then
		self:Harass()
	elseif Mode == "Clear" then
		self:Clear()
	end
		self:Misc()
end

function Ashe:Combo()
	local target = GetTarget(3000)
	if not target then return end
	if Romanov.Combo.W:Value() and Ready(_W)and myHero.pos:DistanceTo(target.pos) < 1200 and target:GetCollision(W.width,W.speed,W.delay) == 0 then
		PredCast(HK_W,_W,target,TYPE_CONE)
	end
	if Romanov.Combo.R:Value() and Ready(_R) and OnScreen(target) then
		local AA = CalcPhysicalDamage(myHero, target, myHero.totalDamage)
		if self:GetComboDamage(target) + AA * (Romanov.Combo.RAA:Value()) > target.health then
			if OnScreen(target) then
				PredCast(HK_R,_R,target,TYPE_LINE)
			else
				PredMinimapCast(HK_R,_R,target,TYPE_LINE)
			end
		end
	end
	if Romanov.Combo.Q:Value() and Ready(_Q) and myHero.pos:DistanceTo(target.pos) < myHero.range then
		Control.CastSpell(HK_Q)
	end
end

function Ashe:Harass()
	local target = GetTarget(1200)
	if Romanov.Harass.Key:Value() == false then return end
	if myHero.mana/myHero.maxMana < Romanov.Harass.Mana:Value() then return end
	if not target then return end
	if Romanov.Harass.Q:Value() and Ready(_Q)and myHero.pos:DistanceTo(target.pos) < myHero.range then
		Control.CastSpell(HK_Q)
	end
	if Romanov.Harass.W:Value() and Ready(_W)and myHero.pos:DistanceTo(target.pos) < 1200 and target:GetCollision(W.width,W.speed,W.delay) == 0  then
		PredCast(HK_W,_W,target)
	end
end

function Ashe:Clear()
	if Romanov.Clear.Key:Value() == false then return end
	if myHero.mana/myHero.maxMana < Romanov.Clear.Mana:Value() then return end
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if  minion.team ~= myHero.team then
			if  Romanov.Clear.Q:Value() and Ready(_Q) and myHero.pos:DistanceTo(minion.pos) < myHero.range then
				Control.CastSpell(HK_Q)
			end
			if  Romanov.Clear.W:Value() and Ready(_W) and myHero.pos:DistanceTo(minion.pos) < 1200 then
				PredCast(HK_W,_W,minion,TYPE_CONE)
			end
		end
	end
end

function Ashe:Misc()
	local target = GetTarget(20000)
	if not target then return end
	if Romanov.Misc.Rks:Value() and Ready(_R) and OnScreen(target) then
		local Rdmg = CalcMagicalDamage(myHero, target, (200 * myHero:GetSpellData(_R).level + myHero.ap))
		if Rdmg > target.health then
			if OnScreen(target) then
				PredCast(HK_R,_R,target,TYPE_LINE)
			end
		end
	end
	if Romanov.Misc.Wks:Value() and Ready(_W) and myHero.pos:DistanceTo(target.pos) < 1200 then
		local Wdmg = CalcPhysicalDamage(myHero, target, (5 + 15 * myHero:GetSpellData(_W).level + myHero.totalDamage))
		if Wdmg > target.health then
			PredCast(HK_W,_W,target,TYPE_CONE)
		end
	end
	if Romanov.Misc.Rkey:Value() and Ready(_R) then
		if OnScreen(target) then
			PredCast(HK_R,_R,target,TYPE_LINE)
		else
			PredMinimapCast(HK_R,_R,target,TYPE_LINE)
		end
	end
	if Romanov.Misc.Raoe:Value() and Ready(_R) and Romanov.Misc.Rene:Value() <=  HeroesAround(target.pos,125,200) and Romanov.Misc.Rally:Value() <=  AlliesAround(target.pos,600,100) then
		if myHero.pos:DistanceTo(target.pos) > Romanov.Misc.Rmax:Value() then return end
		if OnScreen(target) then
			PredCast(HK_R,_R,target,TYPE_LINE)
		else
			PredMinimapCast(HK_R,_R,target,TYPE_LINE)
		end
	end
end

function Ashe:GetComboDamage(unit)
	local Total = 0
	local Wdmg = CalcPhysicalDamage(myHero, unit, (5 + 15 * myHero:GetSpellData(_W).level + myHero.totalDamage))
	local Rdmg = CalcMagicalDamage(myHero, unit, (200 * myHero:GetSpellData(_R).level + myHero.ap))
	if Ready(_W) then
		Total = Total + Wdmg
	end
	if Ready(_R) then
		Total = Total + Rdmg
	end
	return Total
end

function Ashe:Draw()
	if Romanov.Draw.W:Value() and Ready(_W) then Draw.Circle(myHero.pos, 1200, 3,  Draw.Color(255,255, 162, 000)) end
	if Romanov.Draw.CT:Value() then
		local textPos = myHero.pos:To2D()
		if Romanov.Clear.Key:Value() then
			Draw.Text("Clear: On", 20, textPos.x - 33, textPos.y + 60, Draw.Color(255, 000, 255, 000)) 
		else
			Draw.Text("Clear: Off", 20, textPos.x - 33, textPos.y + 60, Draw.Color(255, 225, 000, 000)) 
		end
	end
	if Romanov.Draw.HT:Value() then
		local textPos = myHero.pos:To2D()
		if Romanov.Harass.Key:Value() then
			Draw.Text("Harass: On", 20, textPos.x - 40, textPos.y + 80, Draw.Color(255, 000, 255, 000)) 
		else
			Draw.Text("Harass: Off", 20, textPos.x - 40, textPos.y + 80, Draw.Color(255, 255, 000, 000)) 
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
--- Ashe ---
--- Lucian ---
class "Lucian"

local LucianVersion = "v1.0"

function Lucian:__init()
	self:LoadSpells()
	self:LoadMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end

function Lucian:LoadSpells()
	Q = { range = myHero:GetSpellData(_Q).range, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed, width = myHero:GetSpellData(_Q).width, icon = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/2/2d/Piercing_Light.png" }
	W = { range = myHero:GetSpellData(_W).range, delay = myHero:GetSpellData(_W).delay, speed = myHero:GetSpellData(_W).speed, width = myHero:GetSpellData(_W).width, icon = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/6/60/Ardent_Blaze.png" }
	E = { range = myHero:GetSpellData(_E).range, delay = myHero:GetSpellData(_E).delay, speed = myHero:GetSpellData(_E).speed, width = myHero:GetSpellData(_E).width, icon = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/f/f1/Relentless_Pursuit.png" }
	R = { range = myHero:GetSpellData(_R).range, delay = myHero:GetSpellData(_R).delay, speed = myHero:GetSpellData(_R).speed, width = myHero:GetSpellData(_R).width, icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/6/6e/The_Culling.png" }
end

function Lucian:LoadMenu()
  	Romanov = MenuElement({type = MENU, id = "Romanov", name = "Romanov AIO "..AioVersion})
	--- Version ---
	Romanov:MenuElement({name = "Lucian", drop = {LucianVersion}, leftIcon = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/1/1e/LucianSquare.png"})
	--- Combo ---
	Romanov:MenuElement({type = MENU, id = "Combo", name = "Combo Settings"})
	Romanov.Combo:MenuElement({id = "Q", name = "Use [Q]", value = true, leftIcon = Q.icon})
	Romanov.Combo:MenuElement({id = "W", name = "Use [W]", value = true, leftIcon = W.icon})
	Romanov.Combo:MenuElement({id = "E", name = "Use [E]", value = true, leftIcon = E.icon})
	Romanov.Combo:MenuElement({id = "R", name = "Use [R]", value = true, leftIcon = R.icon})
	--- Clear ---
	Romanov:MenuElement({type = MENU, id = "Clear", name = "Clear Settings"})
	Romanov.Clear:MenuElement({id = "Key", name = "Toggle: Key", key = string.byte("A"), toggle = true})
	Romanov.Clear:MenuElement({id = "Q", name = "Use [Q]", value = true, leftIcon = Q.icon})
	Romanov.Clear:MenuElement({id = "W", name = "Use [W]", value = true, leftIcon = W.icon})
	Romanov.Clear:MenuElement({id = "Mana", name = "Min Mana to Clear [%]", value = 0, min = 0, max = 100})
	--- Harass ---
	Romanov:MenuElement({type = MENU, id = "Harass", name = "Harass Settings"})
	Romanov.Harass:MenuElement({id = "Key", name = "Toggle: Key", key = string.byte("S"), toggle = true})
	Romanov.Harass:MenuElement({id = "Q", name = "Use [Q]", value = true, leftIcon = Q.icon})
	Romanov.Harass:MenuElement({id = "W", name = "Use [W]", value = true, leftIcon = W.icon})
	Romanov.Harass:MenuElement({id = "Mana", name = "Min Mana to Harass [%]", value = 0, min = 0, max = 100})
	--- KS ---
	Romanov:MenuElement({type = MENU, id = "KS", name = "Killsteal Settings"})
	Romanov.KS:MenuElement({id = "Q", name = "Use [Q]", value = true, leftIcon = Q.icon})
	Romanov.KS:MenuElement({id = "W", name = "Use [W]", value = true, leftIcon = W.icon})
	Romanov.KS:MenuElement({id = "R", name = "Use [R]", value = true, leftIcon = R.icon})
	--- Draw ---
	Romanov:MenuElement({type = MENU, id = "Draw", name = "Draw Settings"})
	Romanov.Draw:MenuElement({id = "Q", name = "Draw [Q] Range", value = true, leftIcon = Q.icon})
	Romanov.Draw:MenuElement({id = "EQ", name = "Extended [Q] Range", value = true})
	Romanov.Draw:MenuElement({id = "W", name = "Draw [W] Range", value = true, leftIcon = W.icon})
	Romanov.Draw:MenuElement({id = "R", name = "Draw [R] Range", value = true, leftIcon = R.icon})
	Romanov.Draw:MenuElement({id = "CT", name = "Clear Toggle", value = true})
	Romanov.Draw:MenuElement({id = "HT", name = "Harass Toggle", value = true})
	Romanov.Draw:MenuElement({id = "DMG", name = "Draw Combo Damage", value = true})
	--- Hitchance ---
	Romanov:MenuElement({type = MENU, id = "Pred", name = "Prediction Settings"})
	Romanov.Pred:MenuElement({id = "Chance", name = "Hitchance", value = 0.15, min = 0.1, max = 1, step = 0.05})
end

function Lucian:Tick()
	local Mode = GetMode()
	if Mode == "Combo" then
		self:Combo()
	elseif Mode == "Harass" then
		self:Harass()
	elseif Mode == "Clear" then
		self:Clear()
	end
		self:Killsteal()
end

function Lucian:Combo()
	local target = GetTarget(1200)
	if not target then return end
	if Romanov.Combo.Q:Value() and Ready(_Q) and myHero.pos:DistanceTo(target.pos) < 900 then 
		if myHero.pos:DistanceTo(target.pos) < 500 and myHero.attackData.state == STATE_WINDDOWN then
			Control.CastSpell(HK_Q,target)
		elseif myHero.pos:DistanceTo(target.pos) > 500 then
			self:ExtendedQ(target)
		end
	end
	if Romanov.Combo.E:Value() and Ready(_E) and myHero.pos:DistanceTo(target.pos) < 300 + myHero.range then
		if myHero.pos:DistanceTo(target.pos) < myHero.range and not myHero.attackData.state ~= STATE_WINDDOWN then return end
		Control.CastSpell(HK_E)
	end
	if Romanov.Combo.W:Value() and Ready(_W)and myHero.pos:DistanceTo(target.pos) < 900 and target:GetCollision(W.width,W.speed,W.delay) == 0 then
		if myHero.pos:DistanceTo(target.pos) < myHero.range and not myHero.attackData.state ~= STATE_WINDDOWN then return end
		PredCast(HK_W,_W,target,TYPE_LINE)
	end
	if Romanov.Combo.R:Value() and Ready(_R) and myHero.pos:DistanceTo(target.pos) < 1200 and target:GetCollision(R.width,R.speed,R.delay) == 0 then
		local Rdmg = CalcPhysicalDamage(myHero, target, ((5 + 15 * myHero:GetSpellData(_R).level + 0.2 * myHero.totalDamage + 0.1 * myHero.ap) * (15 + 5 * myHero:GetSpellData(_R).level)))
		if Rdmg >= target.health * 1.5 and myHero:GetSpellData(_R).toggleState == 1 then
			Control.CastSpell(HK_R,target)
		end
	end
end

function Lucian:Harass()
	if Romanov.Harass.Key:Value() == false then return end
	if myHero.mana/myHero.maxMana < Romanov.Harass.Mana:Value() then return end
	local winddown = myHero.attackData.state == STATE_WINDDOWN
	local target = GetTarget(1200)
	if not target then return end
	if Romanov.Harass.Q:Value() and Ready(_Q) and myHero.pos:DistanceTo(target.pos) < 900 then 
		if myHero.pos:DistanceTo(target.pos) < 500 and myHero.attackData.state == STATE_WINDDOWN then
			Control.CastSpell(HK_Q,target)
		elseif myHero.pos:DistanceTo(target.pos) > 500 then
			self:ExtendedQ(target)
		end
	end
	if Romanov.Harass.W:Value() and Ready(_W)and myHero.pos:DistanceTo(target.pos) < 900 and target:GetCollision(W.width,W.speed,W.delay) == 0 then
		if myHero.pos:DistanceTo(target.pos) < myHero.range and not myHero.attackData.state ~= STATE_WINDDOWN then return end
		PredCast(HK_W,_W,target,TYPE_LINE)
	end
end

function Lucian:Clear()
	if Romanov.Clear.Key:Value() == false then return end
	if myHero.mana/myHero.maxMana < Romanov.Clear.Mana:Value() then return end
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if  minion.team == 200 then
			if  Romanov.Clear.Q:Value() and Ready(_Q) and myHero.pos:DistanceTo(minion.pos) < 900 and minion:GetCollision(Q.width,Q.speed,Q.delay) >= 3  then
				if myHero.pos:DistanceTo(minion.pos) < 500 then
					Control.CastSpell(HK_Q,minion)
				elseif myHero.pos:DistanceTo(minion.pos) > 500 then
					self:ExtendedQ(minion)
				end
			end
			if Romanov.Clear.W:Value() and Ready(_W) and myHero.pos:DistanceTo(minion.pos) < 900 then
				PredCast(HK_W,_W,minion,TYPE_LINE)
			end
		elseif minion.team == 300 then
			if  Romanov.Clear.Q:Value() and Ready(_Q) and myHero.pos:DistanceTo(minion.pos) < 900 then
				if myHero.pos:DistanceTo(minion.pos) < 500 then
					Control.CastSpell(HK_Q,minion)
				end
			end
			if Romanov.Clear.W:Value() and Ready(_W) and myHero.pos:DistanceTo(minion.pos) < 900 then
				PredCast(HK_W,_W,minion,TYPE_LINE)
			end
		end
	end
end

function Lucian:Killsteal()
	local target = GetTarget(1200)
	if not target then return end
	if Romanov.KS.Q:Value() and Ready(_Q) and myHero.pos:DistanceTo(target.pos) < 900 then 
		local Qdmg = CalcPhysicalDamage(myHero, target, (45 + 35 * myHero:GetSpellData(_Q).level + (0.5 + 0.1 * myHero.totalDamage)))
		if Qdmg < target.health then return end
		if myHero.pos:DistanceTo(target.pos) < 500 then
			Control.CastSpell(HK_Q,target)
		elseif myHero.pos:DistanceTo(target.pos) > 500 then
			self:ExtendedQ(target)
		end
	end
	if Romanov.KS.W:Value() and Ready(_W)and myHero.pos:DistanceTo(target.pos) < 900 and target:GetCollision(W.width,W.speed,W.delay) == 0 then
		local Wdmg = CalcMagicalDamage(myHero, target, (20 + 40 * myHero:GetSpellData(_W).level + 0.9 * myHero.ap))
		if Wdmg < target.health then return end
		PredCast(HK_W,_W,target,TYPE_LINE)
	end
	if Romanov.KS.R:Value() and Ready(_R) and myHero.pos:DistanceTo(target.pos) < 1200 and target:GetCollision(R.width,R.speed,R.delay) == 0 then
		local Rdmg = CalcPhysicalDamage(myHero, target, ((5 + 15 * myHero:GetSpellData(_R).level + 0.2 * myHero.totalDamage + 0.1 * myHero.ap) * (15 + 5 * myHero:GetSpellData(_R).level)))
		if Rdmg >= target.health * 1.5 and myHero:GetSpellData(_R).toggleState == 1 then
			Control.CastSpell(HK_R,target)
		end
	end
end

function Lucian:ExtendedQ(unit)
	for i = 1, Game.MinionCount() do
		local extend = Game.Minion(i)
		if  extend.team == 200 then
			local pred = unit:GetPrediction(Q.speed,Q.delay)
			local Me = Point(myHero)
			local Unit = Point(pred)
			local LS = LineSegment(Me, Unit)
			local Minion = Point(extend)
			if LS:__distance(Minion) <= 12.5 and myHero.pos:DistanceTo(extend.pos) < 500 then
				Control.CastSpell(HK_Q,extend)
			end
		end
	end
end

function Lucian:GetComboDamage(unit)
	local Total = 0
	local Qdmg = CalcPhysicalDamage(myHero, unit, (45 + 35 * myHero:GetSpellData(_Q).level + (0.5 + 0.1 * myHero.totalDamage)))
	local Wdmg = CalcMagicalDamage(myHero, unit, (20 + 40 * myHero:GetSpellData(_W).level + 0.9 * myHero.ap))
	local Rdmg = CalcPhysicalDamage(myHero, unit, ((5 + 15 * myHero:GetSpellData(_R).level + 0.2 * myHero.totalDamage + 0.1 * myHero.ap) * (15 + 5 * myHero:GetSpellData(_R).level)))
	if Ready(_Q) then
		Total = Total + Qdmg
	end
	if Ready(_W) then
		Total = Total + Wdmg
	end
	if Ready(_R) then
		Total = Total + Rdmg/2
	end
	return Total
end

function Lucian:Draw()
	if Romanov.Draw.Q:Value() and Ready(_Q) then Draw.Circle(myHero.pos, 500, 3,  Draw.Color(255,000, 075, 180)) end
	if Romanov.Draw.EQ:Value() and Ready(_Q) then Draw.Circle(myHero.pos, 900, 3,  Draw.Color(255,138, 162, 255)) end
	if Romanov.Draw.W:Value() and Ready(_W) then Draw.Circle(myHero.pos, 900, 3,  Draw.Color(255,255, 162, 000)) end
	if Romanov.Draw.R:Value() and Ready(_R) then Draw.Circle(myHero.pos, 1200, 3,  Draw.Color(255,120, 255, 120)) end
	if Romanov.Draw.CT:Value() then
		local textPos = myHero.pos:To2D()
		if Romanov.Clear.Key:Value() then
			Draw.Text("Clear: On", 20, textPos.x - 33, textPos.y + 60, Draw.Color(255, 000, 255, 000)) 
		else
			Draw.Text("Clear: Off", 20, textPos.x - 33, textPos.y + 60, Draw.Color(255, 225, 000, 000)) 
		end
	end
	if Romanov.Draw.HT:Value() then
		local textPos = myHero.pos:To2D()
		if Romanov.Harass.Key:Value() then
			Draw.Text("Harass: On", 20, textPos.x - 40, textPos.y + 80, Draw.Color(255, 000, 255, 000)) 
		else
			Draw.Text("Harass: Off", 20, textPos.x - 40, textPos.y + 80, Draw.Color(255, 255, 000, 000)) 
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
--- Lucian ---
--- Olaf ---
class "Olaf"

local OlafVersion = "v1.0"

function Olaf:__init()
	self:LoadSpells()
	self:LoadMenu()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end

function Olaf:LoadSpells()
	Q = { range = myHero:GetSpellData(_Q).range, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed, width = myHero:GetSpellData(_Q).width, icon = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/6/61/Undertow.png" }
	W = { range = myHero:GetSpellData(_W).range, delay = myHero:GetSpellData(_W).delay, speed = myHero:GetSpellData(_W).speed, width = myHero:GetSpellData(_W).width, icon = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/a/ad/Vicious_Strikes.png" }
	E = { range = myHero:GetSpellData(_E).range, delay = myHero:GetSpellData(_E).delay, speed = myHero:GetSpellData(_E).speed, width = myHero:GetSpellData(_E).width, icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/2/25/Reckless_Swing.png" }
	R = { range = myHero:GetSpellData(_R).range, delay = myHero:GetSpellData(_R).delay, speed = myHero:GetSpellData(_R).speed, width = myHero:GetSpellData(_R).width, icon = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/6/68/Ragnarok.png" }
end

function Olaf:LoadMenu()
	Romanov = MenuElement({type = MENU, id = "Romanov", name = "Romanov AIO "..AioVersion})
	--- Version ---
	Romanov:MenuElement({name = "Olaf", drop = {OlafVersion}, leftIcon = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/2/2b/OlafSquare.png"})
	--- Combo ---
	Romanov:MenuElement({type = MENU, id = "Combo", name = "Combo Settings"})
	Romanov.Combo:MenuElement({id = "Q", name = "Use [Q]", value = true, leftIcon = Q.icon})
	Romanov.Combo:MenuElement({id = "W", name = "Use [W]", value = true, leftIcon = W.icon})
	Romanov.Combo:MenuElement({id = "E", name = "Use [E]", value = true, leftIcon = E.icon})
	--- Clear ---
	Romanov:MenuElement({type = MENU, id = "Clear", name = "Clear Settings"})
	Romanov.Clear:MenuElement({id = "Key", name = "Toggle: Key", key = string.byte("A"), toggle = true})
	Romanov.Clear:MenuElement({id = "Q", name = "Use [Q]", value = true, leftIcon = Q.icon})
	Romanov.Clear:MenuElement({id = "Qhit", name = "[Q] X Hit", value = 1, min = 1, max = 7})
	Romanov.Clear:MenuElement({id = "W", name = "Use [W]", value = true, leftIcon = W.icon})
	Romanov.Clear:MenuElement({id = "E", name = "Use [E]", value = true, leftIcon = E.icon})
	Romanov.Clear:MenuElement({id = "Mana", name = "Min Mana to Clear [%]", value = 0, min = 0, max = 100})
	--- Harass ---
	Romanov:MenuElement({type = MENU, id = "Harass", name = "Harass Settings"})
	Romanov.Harass:MenuElement({id = "Key", name = "Toggle: Key", key = string.byte("S"), toggle = true})
	Romanov.Harass:MenuElement({id = "Q", name = "Use [Q]", value = true, leftIcon = Q.icon})
	Romanov.Harass:MenuElement({id = "Mana", name = "Min Mana to Harass [%]", value = 0, min = 0, max = 100})
	--- Misc ---
	Romanov:MenuElement({type = MENU, id = "Misc", name = "Cleanse Settings"})
	Romanov.Misc:MenuElement({id = "R", name = "Use [R]", value = true, leftIcon = R.icon})
	Romanov.Misc:MenuElement({id = "Stun", name = "Stun", value = true})
	Romanov.Misc:MenuElement({id = "Silence", name = "Silence", value = false})
	Romanov.Misc:MenuElement({id = "Taunt", name = "Taunt", value = true})
	Romanov.Misc:MenuElement({id = "Polimorphy", name = "Polimorphy", value = true})
	Romanov.Misc:MenuElement({id = "Slow", name = "Slow", value = false})
	Romanov.Misc:MenuElement({id = "Snare", name = "Snare", value = true})
	Romanov.Misc:MenuElement({id = "Nearsight", name = "Nearsight", value = false})
	Romanov.Misc:MenuElement({id = "Fear", name = "Fear", value = true})
	Romanov.Misc:MenuElement({id = "Charm", name = "Charm", value = true})
	Romanov.Misc:MenuElement({id = "Poison", name = "Poison", value = false})
	Romanov.Misc:MenuElement({id = "Supression", name = "Supression", value = true})
	Romanov.Misc:MenuElement({id = "Blind", name = "Blind", value = true})
	Romanov.Misc:MenuElement({id = "Knockup", name = "Knockup", value = false})
	Romanov.Misc:MenuElement({id = "Knockback", name = "Knockback", value = false})
	--- Killsteal ---
	Romanov:MenuElement({type = MENU, id = "KS", name = "Killsteal Settings"})
	Romanov.KS:MenuElement({id = "Q", name = "Use [Q]", value = true, leftIcon = Q.icon})
	Romanov.KS:MenuElement({id = "E", name = "Use [E]", value = true, leftIcon = E.icon})
	--- Draw ---
	Romanov:MenuElement({type = MENU, id = "Draw", name = "Draw Settings"})
	Romanov.Draw:MenuElement({id = "Q", name = "Draw [Q] Range", value = true, leftIcon = Q.icon})
	Romanov.Draw:MenuElement({id = "E", name = "Draw [E] Range", value = true, leftIcon = E.icon})
	Romanov.Draw:MenuElement({id = "CT", name = "Clear Toggle", value = true})
	Romanov.Draw:MenuElement({id = "HT", name = "Harass Toggle", value = true})
	Romanov.Draw:MenuElement({id = "DMG", name = "Draw Combo Damage", value = true})
	--- Hitchance ---
	Romanov:MenuElement({type = MENU, id = "Pred", name = "Prediction Settings"})
	Romanov.Pred:MenuElement({id = "Chance", name = "Hitchance", value = 0.15, min = 0.1, max = 1, step = 0.05})
end

function Olaf:Tick()
	local Mode = GetMode()
	if Mode == "Combo" then
		self:Combo()
	elseif Mode == "Harass" then
		self:Harass()
	elseif Mode == "Clear" then
		self:Clear()
	end
		self:Cleanse()
		self:Killsteal()
end

function Olaf:Combo()
	local target = GetTarget(1000)
	if target == nil then return end
	if Romanov.Combo.Q:Value() and Ready(_Q) and myHero.pos:DistanceTo(target.pos) < 900 then
		PredCast(HK_Q,_Q,target,TYPE_LINE)
	end
	if Romanov.Combo.W:Value() and Ready(_W) and myHero.pos:DistanceTo(target.pos) < 300 then
		Control.CastSpell(HK_W)
	end
	if Romanov.Combo.E:Value() and Ready(_E) and myHero.pos:DistanceTo(target.pos) < 325 then
		Control.CastSpell(HK_E,target)
	end
end

function Olaf:Clear()
	if Romanov.Clear.Key:Value() == false then return end
	if myHero.mana/myHero.maxMana < Romanov.Clear.Mana:Value() then return end
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if  minion and minion.team ~= myHero.team then
			if Romanov.Clear.Q:Value() and Ready(_Q) and myHero.pos:DistanceTo(minion.pos) < 900 and minion:GetCollision(60,1450,0.25) >= (Romanov.Clear.Qhit:Value() - 1) then
				PredCast(HK_Q,_Q,minion,TYPE_LINE)
			end
			if Romanov.Clear.W:Value() and Ready(_W) and myHero.pos:DistanceTo(minion.pos) < 300 then
				Control.CastSpell(HK_W)
			end
			if Romanov.Clear.E:Value() and Ready(_E) and myHero.pos:DistanceTo(minion.pos) < 325 then
				Control.CastSpell(HK_E,minion)
			end
		end
	end
end

function Olaf:Harass()
	local target = GetTarget(1000)
	if Romanov.Harass.Key:Value() == false then return end
	if myHero.mana/myHero.maxMana < Romanov.Harass.Mana:Value() then return end
	if not target then return end
	if Romanov.Harass.Q:Value() and Ready(_Q) and myHero.pos:DistanceTo(target.pos) < 900 then
		PredCast(HK_Q,_Q,target,TYPE_LINE)
	end
end

function Olaf:Cleanse()
	for i = 0, myHero.buffCount do
	local buff = myHero:GetBuff(i);
		if buff.count > 0 then
			if ((buff.type == 5 and Romanov.Misc.Stun:Value())
			or (buff.type == 7 and  Romanov.Misc.Silence:Value())
			or (buff.type == 8 and  Romanov.Misc.Taunt:Value())
			or (buff.type == 9 and  Romanov.Misc.Polimorphy:Value())
			or (buff.type == 10 and  Romanov.Misc.Slow:Value())
			or (buff.type == 11 and  Romanov.Misc.Snare:Value())
			or (buff.type == 19 and  Romanov.Misc.Nearsight:Value())
			or (buff.type == 21 and  Romanov.Misc.Fear:Value())
			or (buff.type == 22 and  Romanov.Misc.Charm:Value()) 
			or (buff.type == 23 and  Romanov.Misc.Poison:Value()) 
			or (buff.type == 24 and  Romanov.Misc.Supression:Value())
			or (buff.type == 25 and  Romanov.Misc.Blind:Value())
			or (buff.type == 28 and  Romanov.Misc.Fear:Value())
			or (buff.type == 29 and  Romanov.Misc.Knockup:Value())
			or (buff.type == 30 and  Romanov.Misc.Knockback:Value())) then
				if Romanov.Misc.R:Value() then
					if Ready(_R) then
						Control.CastSpell(HK_R)
					end
				end
			end
		end
	end
end

function Olaf:Killsteal()
	local target = GetTarget(1000)
	if target == nil then return end
	if Romanov.KS.Q:Value() and Ready(_Q) then
		local Qlevel = myHero:GetSpellData(_Q).level
		local Qdamage = CalcPhysicalDamage(myHero, target, (({70, 115, 160, 205, 250})[Qlevel] + myHero.bonusDamage))
		if Qdamage >= target.health then
			PredCast(HK_Q,_Q,target,TYPE_LINE)
		end
	end
	if Romanov.KS.E:Value() and Ready(_E) and target.distance < 325 then
		local Elevel = myHero:GetSpellData(_E).level
		local Edamage = (({70, 115, 160, 205, 250})[Elevel] + 0.4 * myHero.totalDamage)
		if target.valid and not target.dead then
			if Edamage >= target.health then
				Control.CastSpell(HK_E,target)
			end
		end
	end
end

function Olaf:GetComboDamage(unit)
	local Total = 0
	local Qdmg = CalcPhysicalDamage(myHero, unit, (25 + 45 * myHero:GetSpellData(_Q).level + myHero.totalDamage))
	local Edmg = 25 + 45 * myHero:GetSpellData(_E).level + 0.4 * myHero.totalDamage
	if Ready(_Q) then
		Total = Total + Qdmg
	end
	if Ready(_E) then
		Total = Total + Edmg
	end
	return Total
end

function Olaf:Draw()
	if Romanov.Draw.Q:Value() and Ready(_Q) then Draw.Circle(myHero.pos, 1000, 3,  Draw.Color(255,255, 162, 000)) end
	if Romanov.Draw.E:Value() and Ready(_E) then Draw.Circle(myHero.pos, 325, 3,  Draw.Color(255,255, 000, 000)) end
	if Romanov.Draw.CT:Value() then
		local textPos = myHero.pos:To2D()
		if Romanov.Clear.Key:Value() then
			Draw.Text("Clear: On", 20, textPos.x - 33, textPos.y + 60, Draw.Color(255, 000, 255, 000)) 
		else
			Draw.Text("Clear: Off", 20, textPos.x - 33, textPos.y + 60, Draw.Color(255, 225, 000, 000)) 
		end
	end
	if Romanov.Draw.HT:Value() then
		local textPos = myHero.pos:To2D()
		if Romanov.Harass.Key:Value() then
			Draw.Text("Harass: On", 20, textPos.x - 40, textPos.y + 80, Draw.Color(255, 000, 255, 000)) 
		else
			Draw.Text("Harass: Off", 20, textPos.x - 40, textPos.y + 80, Draw.Color(255, 255, 000, 000)) 
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
--- Olaf ---
--- Utility ---
class "Utility"

function Utility:__init()
	self:Menu()
	Callback.Add("Tick", function() self:Tick() end)
end

function Utility:Menu()
	Romanov:MenuElement({type = MENU, id = "Leveler", name = "Auto Leveler Settings"})
	Romanov.Leveler:MenuElement({id = "Enabled", name = "Enable", value = true})
	Romanov.Leveler:MenuElement({id = "Block", name = "Block on Level 1", value = true})
	Romanov.Leveler:MenuElement({id = "Order", name = "Skill Priority", drop = {"[Q] - [W] - [E] > Max [Q]","[Q] - [E] - [W] > Max [Q]","[W] - [Q] - [E] > Max [W]","[W] - [E] - [Q] > Max [W]","[E] - [Q] - [W] > Max [E]","[E] - [W] - [Q] > Max [E]"}})
end

function Utility:Tick()
	local Mode = GetMode()
	if Mode == "Combo" then
		self:Combo()
	end
	self:AutoLevel()
end

function Utility:AutoLevel()
	if Romanov.Leveler.Enabled:Value() == false then return end
	local Sequence = {
	[1] = { HK_Q, HK_W, HK_E, HK_Q, HK_Q, HK_R, HK_Q, HK_W, HK_Q, HK_W, HK_R, HK_W, HK_W, HK_E, HK_E, HK_R, HK_E, HK_E },
	[2] = { HK_Q, HK_E, HK_W, HK_Q, HK_Q, HK_R, HK_Q, HK_E, HK_Q, HK_E, HK_R, HK_E, HK_E, HK_W, HK_W, HK_R, HK_W, HK_W },
	[3] = { HK_W, HK_Q, HK_E, HK_W, HK_W, HK_R, HK_W, HK_Q, HK_W, HK_Q, HK_R, HK_Q, HK_Q, HK_E, HK_E, HK_R, HK_E, HK_E },
	[4] = { HK_W, HK_E, HK_Q, HK_W, HK_W, HK_R, HK_W, HK_E, HK_W, HK_E, HK_R, HK_E, HK_E, HK_Q, HK_Q, HK_R, HK_Q, HK_Q },
	[5] = { HK_E, HK_Q, HK_W, HK_E, HK_E, HK_R, HK_E, HK_Q, HK_E, HK_Q, HK_R, HK_Q, HK_Q, HK_W, HK_W, HK_R, HK_W, HK_W },
	[6] = { HK_E, HK_W, HK_Q, HK_E, HK_E, HK_R, HK_E, HK_W, HK_E, HK_W, HK_R, HK_W, HK_W, HK_Q, HK_Q, HK_R, HK_Q, HK_Q },
	}
	local Slot = nil
	local Tick = 0
	local SkillPoints = myHero.levelData.lvlPts
	local level = myHero.levelData.lvl
	local Check = Sequence[Romanov.Leveler.Order:Value()][level - SkillPoints + 1]
	if SkillPoints > 0 then
		if Romanov.Leveler.Block:Value() and level == 1 then return end
		if GetTickCount() - Tick > 800 and Check ~= nil then
			Control.KeyDown(HK_LUS)
			Control.KeyDown(Check)
			Slot = Check
			Tick = GetTickCount()
		end
	end
	if Control.IsKeyDown(HK_LUS) then
		Control.KeyUp(HK_LUS)
	end
	if Slot and Control.IsKeyDown(Slot) then
		Control.KeyUp(Slot)
	end
end
--- Utility ---

Callback.Add("Load", function()
	if not _G.Prediction_Loaded then return end
	if _G[myHero.charName] then
		_G[myHero.charName]()
		Utility()
		print("Romanov AIO "..AioVersion..": "..myHero.charName.." Loaded")
		print("PM me for suggestions/fix problems")
		print("Discord: Romanov#6333")
	else print ("Romanov AIO doens't support "..myHero.charName.." shutting down...") return
	end
end)
