require 'DamageLib'

local ScriptVersion = "v1.0"

local function Ready(spell)
	return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana and Game.CanUseSpell(spell) == 0 
end

local function OnScreen(unit)
	return unit.pos:To2D().onScreen;
end

function GetTarget(range)
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
   	[0] = "",
   	[1] = "Combo",
   	[2] = "Harass",
   	[3] = "LastHit",
   	[4] = "Clear"
}

function GetMode()
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
		end
	else
		return GOS.GetMode()
	end
end

function GetHeroByHandle(handle)
	for i = 1, Game.HeroCount() do
		local h = Game.Hero(i)
		if h.handle == handle then
			return h
		end
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

local PointClick = {
	["Ahri"] = {
		["ahrifoxfiremissiletwo"] = {key = "[W]", default = false, name = "Fox-Fire", icon = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/a/a8/Fox-Fire.png"},
		["ahritumblemissile"] = {key = "[R]", default = false, name = "Spirit Rush", icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/8/86/Spirit_Rush.png"}},
	["Akali"] = {
		["akalimota"] = {key = "[Q]", default = false, name = "Mark of the Assasin", icon = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/1/1f/Mark_of_the_Assassin.png"}},
	["Anivia"] = {
		["frostbite"] = {key = "[E]", default = true, name = "Frostbite", icon = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/e/ee/Frostbite.png"}},
	["Annie"] = {
		["disintegrate"] = {key = "[Q]", default = true, name = "Disintegrate", icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/2/25/Disintegrate.png"}},
	["Brand"] = {
		["brandr"] = {key = "[R]", default = true, name = "Pyroclasm", icon = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/c/cd/Pyroclasm.png"}},
	["Caitlyn"] = {
		["caitlynaceintheholemissile"] = {key = "[R]", default = true, name = "Ace in the Hole", icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/a/aa/Ace_in_the_Hole.png"}},
	["Cassiopeia"] = {
		["cassiopeiatwinfang"] = {key = "[E]", default = false, name = "Twin Fang", icon = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/a/ad/Twin_Fang.png"}},
	["Elise"] = {
		["elisehumanq"] = {key = "[Q]", default = true, name = "Neurotoxin", icon = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/2/2b/Neurotoxin.png"}},
	["Ezreal"] = {
		["ezrealarcaneshiftmissile"] = {key = "[Q]", default = false, name = "Arcane Shift", icon = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/f/fb/Arcane_Shift.png"}},
	["FiddleSticks"] = {
		["fiddlesticksdarkwindmissile"] = {key = "[E]", default = true, name = "Dark Wind", icon = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/2/2d/Dark_Wind.png"}},
	["Gangplank"] = {
		["parley"] = {key = "[Q]", default = false, name = "Parley", icon = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/e/e3/Parrrley.png"}},
	["Janna"] = {
		["sowthewind"] = {key = "[W]", default = false, name = "Zephyr", icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/3/3e/Zephyr.png"}},
	["Kassadin"] = {
		["nulllance"] = {key = "[Q]", default = true, name = "Null Sphere", icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/9/97/Null_Sphere.png"}},
	["Katarina"] = {
		["katarinaqmis"] = {key = "[Q]", default = true, name = "Bouncing Blade", icon = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/e/eb/Bouncing_Blade.png"}},
	["Kayle"] = {
		["judicatorreckoning"] = {key = "[Q]", default = true, name = "Reckoning", icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/2/20/Reckoning.png"}},
	["Leblanc"] = {
		["leblancchaosorbm"] = {key = "[Q]", default = true, name = "Shatter Orb", icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/c/c7/Shatter_Orb.png"}},
	["Malphite"] = {
		["seismicshard"] = {key = "[Q]", default = true, name = "Seismic Shard", icon = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/3/3c/Seismic_Shard.png"}},
	["MissFortune"] = {
		["missfortunericochetshot"] = {key = "[Q]", default = true, name = "Double Up", icon = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/2/25/Double_Up.png"}},
	["Nami"] = {
		["namiwmissileenemy"] = {key = "[W]", default = false, name = "Ebb and Flow", icon = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/4/48/Ebb_and_Flow.png"}},
	["Nunu"] = {
		["iceblast"] = {key = "[E]", default = true, name = "Ice Blast", icon = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/7/77/Ice_Blast.png"}},
	["Pantheon"] = {
		["pantheonq"] = {key = "[Q]", default = false, name = "Spear Shot", icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/1/1b/Spear_Shot.png"}},
	["Ryze"] = {
		["ryzee"] = {key = "[E]", default = true, name = "Spell Flux", icon = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/8/81/Spell_Flux.png"}},
	["Shaco"] = {
		["twoshivpoison"] = {key = "[E]", default = true, name = "Two-Shiv Poison", icon = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/3/3b/Two-Shiv_Poison.png"}},
	["Sona"] = {
		["sonaqmissile"] = {key = "[Q]", default = true, name = "Hymn of Valor", icon = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/e/e1/Hymn_of_Valor.png"}},
	["Swain"] = {
		["swaintorment"] = {key = "[E]", default = true, name = "Torment", icon = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/0/08/Torment.png"}},
	["Syndra"] = {
		["syndrarspell"] = {key = "[R]", default = true, name = "Unleashed Power", icon = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/1/1d/Unleashed_Power.png"}},
	["Teemo"] = {
		["blindingdart"] = {key = "[Q]", default = true, name = "Blinding Dart", icon = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/c/c7/Blinding_Dart.png"}},
	["Tristana"] = {
		["detonatingshot"] = {key = "[R]", default = true, name = "Buster Shot", icon = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/f/f3/Buster_Shot.png"}},
	["TwistedFate"] = {
		["bluecardpreattack"] = {key = "[W]", default = true, name = "Blue Card", icon = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/d/d9/Blue_Card.png"},
		["goldcardpreattack"] = {key = "[W]", default = true, name = "Gold Card", icon = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/8/8d/Gold_Card.png"},
		["redcardpreattack"] = {key = "[W]", default = true, name = "Red Card", icon = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/9/93/Red_Card.png"}},
	["Urgot"] = {
		["urgotheatseekinghomemissile"] = {key = "[Q]", default = true, name = "Acid Hunter", icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/2/27/Acid_Hunter.png"}},
	["Vayne"] = {
		["vaynecondemnmissile"] = {key = "[E]", default = true, name = "Condemn", icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/6/66/Condemn.png"}},
	["Veigar"] = {
		["veigarr"] = {key = "[R]", default = true, name = "Primordial Burst", icon = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/e/e7/Primordial_Burst.png"}},
	["Viktor"] = {
		["viktorpowertransfer"] = {key = "[Q]", default = true, name = "Siphon Power", icon = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/d/d1/Siphon_Power.png"}},
	["Vladimir"] = {
		["vladimirtidesofbloodnuke"] = {key = "[E]", default = true, name = "Tides of Blood", icon = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/6/65/Tides_of_Blood.png"}}
}

class "MasterYi"

function MasterYi:__init()
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

function MasterYi:LoadSpells()
	Q = { range = myHero:GetSpellData(_Q).range, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed, width = myHero:GetSpellData(_Q).width, icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/e/e6/Alpha_Strike.png" }
	W = { range = myHero:GetSpellData(_W).range, delay = myHero:GetSpellData(_W).delay, speed = myHero:GetSpellData(_W).speed, width = myHero:GetSpellData(_W).width, icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/6/61/Meditate.png" }
	E = { range = myHero:GetSpellData(_E).range, delay = myHero:GetSpellData(_E).delay, speed = myHero:GetSpellData(_E).speed, width = myHero:GetSpellData(_E).width, icon = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/7/74/Wuju_Style.png" }
	R = { range = myHero:GetSpellData(_R).range, delay = myHero:GetSpellData(_R).delay, speed = myHero:GetSpellData(_R).speed, width = myHero:GetSpellData(_R).width, icon = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/3/34/Highlander.png" }
end

function MasterYi:LoadMenu()
	Romanov = MenuElement({type = MENU, id = "Romanov", name = "Romanov Master Yi"})
	--- Version ---
	Romanov:MenuElement({name = "Master Yi", drop = {ScriptVersion}, leftIcon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/b/b2/Master_YiSquare.png"})
	--- Combo ---
	Romanov:MenuElement({type = MENU, id = "Combo", name = "Combo Settings"})
	Romanov.Combo:MenuElement({id = "Q", name = "Use [Q]", value = true, leftIcon = Q.icon})
	Romanov.Combo:MenuElement({id = "W", name = "Use [W] AA Reset", value = true, leftIcon = W.icon})
	Romanov.Combo:MenuElement({id = "E", name = "Use [E]", value = true, leftIcon = E.icon})
	Romanov.Combo:MenuElement({id = "R", name = "[R] Mode", drop = {"After [Q]","Before [Q]","Disabled"}, leftIcon = R.icon})
	Romanov.Combo:MenuElement({id = "Rsearch", name = "Distance to [R] before [Q]", value = 1200, min = 300, max = 3000, step = 100})
	--- Clear ---
	Romanov:MenuElement({type = MENU, id = "Clear", name = "Clear Settings"})
	Romanov.Clear:MenuElement({id = "Key", name = "Toggle: Key", key = string.byte("A"), toggle = true})
	Romanov.Clear:MenuElement({id = "Q", name = "Use [Q]", value = true, leftIcon = Q.icon})
	Romanov.Clear:MenuElement({id = "E", name = "Use [E]", value = true, leftIcon = E.icon})
	Romanov.Clear:MenuElement({id = "Mana", name = "Min Mana to Clear [%]", value = 0, min = 0, max = 100})
	--- Harass ---
	Romanov:MenuElement({type = MENU, id = "Harass", name = "Harass Settings"})
	Romanov.Harass:MenuElement({id = "Key", name = "Toggle: Key", key = string.byte("S"), toggle = true})
	Romanov.Harass:MenuElement({id = "Q", name = "Use [Q]", value = true, leftIcon = Q.icon})
	Romanov.Harass:MenuElement({id = "E", name = "Use [E]", value = true, leftIcon = E.icon})
	Romanov.Harass:MenuElement({id = "Mana", name = "Min Mana to Harass [%]", value = 0, min = 0, max = 100})
	--- Misc ---
	Romanov:MenuElement({type = MENU, id = "Evade", name = "Evade Settings"})
	Romanov.Evade:MenuElement({id = "QE", name = "Evade with [Q]", value = true, leftIcon = Q.icon})
	Romanov.Evade:MenuElement({id = "SQ", name = "Save [Q] to Evade [?]", value = true, tooltip = "Only during Combo mode"})
	Romanov.Evade:MenuElement({type = MENU, id = "Spells", name = "Enemy Spells"})
	local AddedSpell = false
	DelayAction(function()
		for i = 1, Game.HeroCount() do
			local h = Game.Hero(i)
			if h.isEnemy then
				if PointClick[h.charName] then
					for _, x in pairs(PointClick[h.charName]) do
						Romanov.Evade.Spells:MenuElement({id = x.name, name = h.charName.." "..x.key.." "..x.name, leftIcon = x.icon, type = MENU})
						Romanov.Evade.Spells[x.name]:MenuElement({id = "Enabled", name = "Enabled", value = true})
						AddedSpell = true
					end
				end
			end
		end
	end, 8)
	--- Killsteal ---
	Romanov:MenuElement({type = MENU, id = "Killsteal", name = "Killsteal"})
	Romanov.Killsteal:MenuElement({id = "Q", name = "Killsecure [Q]", value = true, leftIcon = Q.icon})
	--- Draw ---
	Romanov:MenuElement({type = MENU, id = "Draw", name = "Draw Settings"})
	Romanov.Draw:MenuElement({id = "Q", name = "Draw [Q] Range", value = true, leftIcon = Q.icon})
	Romanov.Draw:MenuElement({id = "CT", name = "Clear Toggle", value = true})
	Romanov.Draw:MenuElement({id = "HT", name = "Harass Toggle", value = true})
	Romanov.Draw:MenuElement({id = "DMG", name = "Draw [Q] Damage", value = true})
end

function MasterYi:Tick()
	local Mode = GetMode()
	if Mode == "Combo" then
		self:Combo()
		self:CancelW()
	elseif Mode == "Harass" then
		self:Harass()
	elseif Mode == "Clear" then
		self:Clear()
	end
		self:Evade()
		self:Killsteal()
end

function MasterYi:Combo()
	local target = GetTarget(3000)
	if target == nil then return end
	local Rmenu = Romanov.Combo.R:Value()
	if Romanov.Combo.Q:Value() and Ready(_Q)and myHero.pos:DistanceTo(target.pos) < 600 then
		if  Romanov.Evade.SQ:Value() then return end
		self:CastQ(target)
	end
	if Romanov.Combo.W:Value() and Ready(_W)and myHero.pos:DistanceTo(target.pos) < 200 and  myHero.attackData.state == STATE_WINDDOWN then
		Control.CastSpell(HK_W)
	end
	if Rmenu ~= 3 then
		if Rmenu == 1 then
			if Romanov.Combo.R:Value() and Ready(_R)and myHero.pos:DistanceTo(target.pos) < 400 then
				Control.CastSpell(HK_R)
			end
		end 
		if Rmenu == 2 then
			if Romanov.Combo.R:Value() and Ready(_R)and myHero.pos:DistanceTo(target.pos) <  Romanov.Combo.Rsearch:Value()then
				Control.CastSpell(HK_R)
			end
		end
	end
	if Romanov.Combo.E:Value() and Ready(_E)and myHero.pos:DistanceTo(target.pos) < 200 then
		Control.CastSpell(HK_E)
	end
end

function MasterYi:Harass()
	local target = GetTarget(600)
	if Romanov.Harass.Key:Value() == false then return end
	if myHero.mana/myHero.maxMana < Romanov.Harass.Mana:Value() then return end
	if target == nil then return end
	if Romanov.Harass.Q:Value() and Ready(_Q)and myHero.pos:DistanceTo(target.pos) < 600 then
		self:CastQ(target)
	end
	if Romanov.Harass.E:Value() and Ready(_E)and myHero.pos:DistanceTo(target.pos) < 200 then
		Control.CastSpell(HK_E)
	end
end

function MasterYi:Killsteal()
	local target = GetTarget(600)
	if Romanov.Killsteal.Q:Value() == false then return end
	if target == nil then return end
	if Romanov.Killsteal.Q:Value() and Ready(_Q)and myHero.pos:DistanceTo(target.pos) < 600 then
		if self:GetComboDamage(target) > target.health then
			self:CastQ(target)
		end
	end
end

function MasterYi:Clear()
	if Romanov.Clear.Key:Value() == false then return end
	if myHero.mana/myHero.maxMana < Romanov.Clear.Mana:Value() then return end
	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if  minion.team ~= myHero.team then
			if  Romanov.Clear.Q:Value() and Ready(_Q) and myHero.pos:DistanceTo(minion.pos) <600 then
				self:CastQ(minion)
			end
			if  Romanov.Clear.E:Value() and Ready(_E) and myHero.pos:DistanceTo(minion.pos) < 200 then
				Control.CastSpell(HK_E)
			end
		end
	end
end

function MasterYi:Evade()
	local target = GetTarget(600)
	if not Ready(_Q) then return end
	for i = 1, Game.MissileCount() do
		local m = Game.Missile(i)
		local Data = m.missileData
		local endPos = Data.endPos
		local Width = Data.width
		local Origin = GetHeroByHandle(Data.owner)
		if Origin and Data.target == myHero.handle then
			if PointClick[Origin.charName] then
				Spell = PointClick[Origin.charName][Data.name:lower()]
			end
			if Spell then
				if Romanov.Evade.Spells[Spell.name].Enabled:Value() then
					if target then
						self:CastQ(target)
					end
					local Minion = self:GetNearestMouseMinion() 
					if target == nil and  Minion then
						self:CastQ(Minion)
					end
				end
			end
		end
	end
end

function MasterYi:GetNearestMouseMinion()
	local best = nil
	local closest = math.huge
	for i = 1, Game.MinionCount() do
		local m = Game.Minion(i)
		if m and m.isEnemy then
			local mouse = GetDistance(myHero.pos, mousePos)
			local Mdist = myHero.pos + (m.pos - myHero.pos):Normalized() * 600
			local Mpos = GetDistance(Mdist, mousePos)
			local MposMe = GetDistance(Mdist, myHero.pos)
			if Mpos < mouse and MposMe < closest then
				best = m
				closest = MposMe
			end
		end
	end
	return best
end

function MasterYi:CastQ(pos)
	Control.SetCursorPos(pos)
	Control.KeyDown(HK_Q)
	Control.KeyUp(HK_Q)
end

function MasterYi:CancelW(target)
	local target = GetTarget(600)
	if target == nil then return end
	if HasBuff(myHero, "Meditate") then
		local vec = myHero.pos + (target.pos - myHero.pos):Normalized() * ( myHero.boundingRadius * 1.1)
		Control.Move(vec)
	end
end

function MasterYi:GetComboDamage(unit)
	local Total = 0
	local Qdmg = CalcPhysicalDamage(myHero, unit, (-10 + 35 * myHero:GetSpellData(_Q).level + myHero.totalDamage))
	if Ready(_Q) then
		Total = Total + Qdmg
	end
	return Total
end

function MasterYi:Draw()
	if Romanov.Draw.Q:Value() and Ready(_Q) then Draw.Circle(myHero.pos, 600, 3,  Draw.Color(255,255, 162, 000)) end
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
			if enemy and enemy.isEnemy  and not enemy.dead then
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
	if _G[myHero.charName] then
		_G[myHero.charName]()
		print("Romanov "..myHero.charName.." "..ScriptVersion.." Loaded, pm me for suggestions/fix problems")
		print("Discord: Romanov#6333")
	else print (myHero.charName.." its not supported, shutting down...") return
	end
end)
