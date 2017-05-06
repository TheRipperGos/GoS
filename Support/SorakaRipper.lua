class "Soraka"

function Soraka:__init()
  	self:LoadSpells()
  	self:LoadMenu()
	self.Spells = {
		["Fiddlesticks"] = {{Key = _W, Duration = 5, KeyName = "W" },{Key = _R,Duration = 1,KeyName = "R"  }},
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
	self.Enemies = {}
	self.Allies = {}
	for i = 1,Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.isAlly then
			table.insert(self.Allies,hero)
		else
			table.insert(self.Enemies,hero)
		end	
	end	
  	Callback.Add("Tick", function() self:Tick() end)
  	Callback.Add("Draw", function() self:Draw() end)
end

function Soraka:LoadSpells()
  	Q = { range = myHero:GetSpellData(_Q).range, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed, width = myHero:GetSpellData(_Q).width, radius = myHero:GetSpellData(_Q).radius, Type = "circle" }
	W = { range = myHero:GetSpellData(_W).range, delay = myHero:GetSpellData(_W).delay, speed = myHero:GetSpellData(_W).speed, width = myHero:GetSpellData(_W).width }
	E = { range = myHero:GetSpellData(_E).range, delay = myHero:GetSpellData(_E).delay, speed = myHero:GetSpellData(_E).speed, width = myHero:GetSpellData(_E).width }
	R = { range = myHero:GetSpellData(_R).range, delay = myHero:GetSpellData(_R).delay, speed = myHero:GetSpellData(_R).speed, width = myHero:GetSpellData(_R).width }
end

function Soraka:LoadMenu()
  	local Icons = { C = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/8/8d/SorakaSquare.png",
    				Q = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/c/cd/Starcall.png", 
    				W = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/6/6f/Astral_Infusion.png", 
    				E = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/e/e7/Equinox.png", 
                    R = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/f/f3/Wish.png" 
                  }
  
	--------- Menu Principal --------------------------------------------------------------
  	self.Menu = MenuElement({type = MENU, id = "Menu", name = "The Ripper Series", leftIcon = Icons.C})
	--------- Soraka --------------------------------------------------------------------
	self.Menu:MenuElement({type = MENU, id = "Ripper", name = "Soraka The Healer", leftIcon = Icons.C })
	--------- Menu Principal --------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "Combo", name = "Combo"})
  	self.Menu.Ripper.Combo:MenuElement({id = "Q", name = "Use Q", value = true, leftIcon = Icons.Q})
  	self.Menu.Ripper.Combo:MenuElement({id = "E", name = "Use E", value = true, leftIcon = Icons.E})
	--------- Menu LastHit --------------------------------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "LastHit", name = "Last Hit"})
  	self.Menu.Ripper.LastHit:MenuElement({id = "Q", name = "Use Q", value = true, leftIcon = Icons.Q})
    self.Menu.Ripper.LastHit:MenuElement({id = "Mana", name = "Min mana to LastHit (%)", value = 40, min = 0, max = 100})
	--------- Menu LaneClear ------------------------------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "LaneClear", name = "Lane Clear"})
  	self.Menu.Ripper.LaneClear:MenuElement({id = "Q", name = "Use Q", value = true, leftIcon = Icons.Q})
    self.Menu.Ripper.LaneClear:MenuElement({id = "HQ", name = "Min minions in Q range", value = 4, min = 1, max = 7})
    self.Menu.Ripper.LaneClear:MenuElement({id = "Mana", name = "Min mana to Clear (%)", value = 40, min = 0, max = 100})
	--------- Menu JungleClear ------------------------------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "JungleClear", name = "Jungle Clear"})
  	self.Menu.Ripper.JungleClear:MenuElement({id = "Q", name = "Use Q", value = true, leftIcon = Icons.Q})
    self.Menu.Ripper.JungleClear:MenuElement({id = "Mana", name = "Min mana to Clear (%)", value = 40, min = 0, max = 100})
	--------- Menu Harass ---------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "Harass", name = "Harass"})
  	self.Menu.Ripper.Harass:MenuElement({id = "Q", name = "Use Q", value = true, leftIcon = Icons.Q})
  	self.Menu.Ripper.Harass:MenuElement({id = "E", name = "Use E", value = true, leftIcon = Icons.E})
    self.Menu.Ripper.Harass:MenuElement({id = "Mana", name = "Min mana to Harass (%)", value = 40, min = 0, max = 100})
	--------- Menu Flee ----------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "Flee", name = "Flee"})
  	self.Menu.Ripper.Flee:MenuElement({id ="Q", name = "Use Q", value = true, leftIcon = Icons.Q})
  	self.Menu.Ripper.Flee:MenuElement({id ="E", name = "Use E", value = true, leftIcon = Icons.E})
	--------- Menu Heal------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "Heal", name = "Heal"})
  	self.Menu.Ripper.Heal:MenuElement({id = "W", name = "Use W", value = true, leftIcon = Icons.W})
  	self.Menu.Ripper.Heal:MenuElement({id = "Health", name = "Min Soraka Health (%)", value = 45, min = 5, max = 100})
	DelayAction(function()
		for i = 1,Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.team == myHero.team and not hero.isMe then
				self.Menu.Ripper.Heal:MenuElement({id = hero.networkID, name = hero.charName, value = true, leftIcon = "https://raw.githubusercontent.com/TheRipperGos/GoS/master/Sprites/"..hero.charName..".png"})
			end
		end
	end, 2)
	self.Menu.Ripper.Heal:MenuElement({type = MENU, id = "HP", name = "HP settings"})
  	DelayAction(function()
		for i = 1,Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.team == myHero.team and not hero.isMe then
				self.Menu.Ripper.Heal.HP:MenuElement({id = hero.networkID, name = hero.charName.." max HP (%)", value = 85, min = 0, max = 100})
			end
		end
	end, 2)
	--------- Menu ULT ----------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "ULT", name = "Ultimate"})
  	self.Menu.Ripper.ULT:MenuElement({id = "R", name = "Use R", value = true, leftIcon = Icons.R})
  	self.Menu.Ripper.ULT:MenuElement({id = "Health", name = "Max Soraka Health (%)", value = 20, min = 0, max = 100})
	DelayAction(function()
		for i = 1,Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.team == myHero.team and not hero.isMe then
				self.Menu.Ripper.ULT:MenuElement({id = hero.networkID, name = hero.charName, value = true, leftIcon = "https://raw.githubusercontent.com/TheRipperGos/GoS/master/Sprites/"..hero.charName..".png"})
			end
		end
	end, 2)
	self.Menu.Ripper.ULT:MenuElement({type = MENU, id = "HP", name = "HP settings"})
  	DelayAction(function()
		for i = 1,Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.team == myHero.team and not hero.isMe then
				self.Menu.Ripper.ULT.HP:MenuElement({id = hero.networkID, name = hero.charName.." max HP (%)", value = 15, min = 0, max = 100})
			end
		end
	end, 2)
	--------- Menu KS -----------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "KS", name = "Killsteal"})
  	self.Menu.Ripper.KS:MenuElement({id = "Q", name = "Use Q", value = true, leftIcon = Icons.Q})
  	self.Menu.Ripper.KS:MenuElement({id = "E", name = "Use E", value = true, leftIcon = Icons.E})                   
	--------- Menu Misc -----------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "Misc", name = "Misc"})
    self.Menu.Ripper.Misc:MenuElement({id = "CCE", name = "Auto E if enemy has CC", value = true})
  	self.Menu.Ripper.Misc:MenuElement({id = "CancelE", name = "Auto E Interrupter", value = true})
	--------- Menu Drawings --------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "Drawings", name = "Drawings"})
  	self.Menu.Ripper.Drawings:MenuElement({id = "Q", name = "Draw Q range", value = true, leftIcon = Icons.Q})
  	self.Menu.Ripper.Drawings:MenuElement({id = "E", name = "Draw E range", value = true, leftIcon = Icons.E})
  	self.Menu.Ripper.Drawings:MenuElement({id = "Width", name = "Width", value = 2, min = 1, max = 5, step = 1})
	self.Menu.Ripper.Drawings:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 0, 0, 255)})
end

function Soraka:Tick()
  	local Combo = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO]) or (_G.GOS and _G.GOS:GetMode() == "Combo") or (_G.EOWLoaded and EOW:Mode() == "Combo")
  	local LastHit = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT]) or (_G.GOS and _G.GOS:GetMode() == "Lasthit") or (_G.EOWLoaded and EOW:Mode() == "LastHit")
  	local Clear = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR]) or (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR]) or (_G.GOS and _G.GOS:GetMode() == "Clear") or (_G.EOWLoaded and EOW:Mode() == "LaneClear")
  	local Harass = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS]) or (_G.GOS and _G.GOS:GetMode() == "Harass") or (_G.EOWLoaded and EOW:Mode() == "Harass")
  	local Flee = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE]) or (_G.GOS and _G.GOS:GetMode() == "Flee") or (_G.EOWLoaded and EOW:Mode() == "Flee")
  	if Combo then
    	self:Combo()
    elseif LastHit then
    	self:LastQ()
    elseif Clear then
    	self:LaneClear()
		self:JungleClear()
    elseif Harass then
    	self:Harass()
    elseif Flee then
    	self:Flee()
    end
        self:Heal()
		self:AutoR()
		self:SelfAutoR()
  		self:KS()
  		self:Misc()
end

function Soraka:GetValidEnemy(range)
  	for i = 1,Game.HeroCount() do
    	local enemy = Game.Hero(i)
    	if  enemy.team ~= myHero.team and enemy.valid and enemy.pos:DistanceTo(myHero.pos) < 1200 then
    		return true
    	end
    end
  	return false
end

function Soraka:IsValidTarget(unit,range)
    return unit ~= nil and unit.valid and unit.visible and not unit.dead and unit.isTargetable and not unit.isImmortal and unit.pos:DistanceTo(myHero.pos) <= 300000
end

function Soraka:Ready (spell)
	return Game.CanUseSpell(spell) == 0 
end
	
function Soraka:Combo()
  	if self:GetValidEnemy(1200) == false then return end
  	if (not _G.SDK and not _G.GOS and not _G.EOWLoaded) then return end
  	local target = (_G.SDK and _G.SDK.TargetSelector:GetTarget(1200, _G.SDK.DAMAGE_TYPE_PHYSICAL)) or (_G.GOS and _G.GOS:GetTarget(1200,"AD")) or ( _G.EOWLoaded and EOW:GetTarget())

    if self:IsValidTarget(target,800) and myHero.pos:DistanceTo(target.pos) < 800 and self.Menu.Ripper.Combo.Q:Value() and self:Ready(_Q) then
        Control.CastSpell(HK_Q,target:GetPrediction(Q.speed, Q.delay))
    end
    if self:IsValidTarget(target,925) and myHero.pos:DistanceTo(target.pos) < 925  and self.Menu.Ripper.Combo.E:Value() and self:Ready(_E) then
        Control.CastSpell(HK_E,target:GetPrediction(E.speed,E.delay))
    end
end

function Soraka:GetValidMinion(range)
    	for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < E.range then
        return true
        end
    	end
    	return false
end

function Soraka:HasCC(unit)	
	for i = 0, unit.buffCount do
	local buff = myHero:GetBuff(i);
	if buff.count > 0 then
		if ((buff.type == 5)
		or (buff.type == 8)
		or (buff.type == 9)
		or (buff.type == 10)
		or (buff.type == 11)
		or (buff.type == 21)
		or (buff.type == 22)
		or (buff.type == 24)
		or (buff.type == 28)
		or (buff.type == 29)
		or (buff.type == 31)) then
		return true
		end
		end
		end
	return false
end

function Soraka:HpPred(unit, delay)
	if _G.GOS then
	hp =  GOS:HP_Pred(unit,delay)
	else
	hp = unit.health
	end
	return hp
end

function Soraka:LastQ()
	if self.Menu.Ripper.LastHit.Q:Value() == false then return end
    local level = myHero:GetSpellData(_Q).level
	if level == nil or level == 0 then return end
  	if self:GetValidMinion(myHero.range) == false then return end
  	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
    local Qdamage = (({70, 110, 150, 190, 230})[level] + 0.35 * myHero.ap)
    if self:IsValidTarget(minion,800) and minion.isEnemy then
    	if Qdamage >= minion.health and Qdamage >= self:HpPred(minion, 0.5) and (myHero.mana/myHero.maxMana >= self.Menu.Ripper.LastHit.Mana:Value() / 100) and self:Ready(_Q) then
    		Control.CastSpell(HK_Q,minion.pos)
    	end
    end
    end
end

function Soraka:CountEnemyMinions(range)
	local minionsCount = 0
    for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < Q.range then
            minionsCount = minionsCount + 1
        end
    end
    return minionsCount
end

function Soraka:LaneClear()
  	if self:GetValidMinion(Q.range) == false then return end
  	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
    	if  minion.team == 200 then
      	if self:IsValidTarget(minion,400) and myHero.pos:DistanceTo(minion.pos) < 400 and self.Menu.Ripper.LaneClear.Q:Value() and (myHero.mana/myHero.maxMana >= self.Menu.Ripper.LaneClear.Mana:Value() / 100 ) and self:Ready(_Q) then
			if self:CountEnemyMinions(Q.range) >= self.Menu.Ripper.LaneClear.HQ:Value() then
				Control.CastSpell(HK_Q,minion.pos)
				end
			end
		end
	end
end

function Soraka:JungleClear()
  	if self:GetValidMinion(Q.range) == false then return end
  	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
    	if  minion.team == 300 then
			if self:IsValidTarget(minion,800) and myHero.pos:DistanceTo(minion.pos) < 800 and self.Menu.Ripper.JungleClear.Q:Value() and (myHero.mana/myHero.maxMana >= self.Menu.Ripper.JungleClear.Mana:Value() / 100 ) and self:Ready(_Q) then
			Control.CastSpell(HK_Q,minion.pos)
			break
			end
		end
    end
end

function Soraka:GetValidAlly(range)
  	for i = 1,Game.HeroCount() do
    	local ally = Game.Hero(i)
    	if  ally.team == myHero.team and ally.valid and ally.pos:DistanceTo(myHero.pos) > 1 then
    		return true
    	end
    end
  	return false
end

function Soraka:Harass()
  	if (not _G.SDK and not _G.GOS and not _G.EOWLoaded) then return end
    if self:GetValidEnemy(925) == false then return end
  	local target = (_G.SDK and _G.SDK.TargetSelector:GetTarget(925, _G.SDK.DAMAGE_TYPE_PHYSICAL)) or (_G.GOS and _G.GOS:GetTarget(925,"AD")) or ( _G.EOWLoaded and EOW:GetTarget())
    if self:IsValidTarget(target,800) and myHero.pos:DistanceTo(target.pos) < 800 and (myHero.mana/myHero.maxMana > self.Menu.Ripper.Harass.Mana:Value() / 100) and self.Menu.Ripper.Harass.Q:Value() and self:Ready(_Q) then
        Control.CastSpell(HK_Q,target:GetPrediction(Q.speed, Q.delay))
    end
    if self:IsValidTarget(target,925) and myHero.pos:DistanceTo(target.pos) < 925 and (myHero.mana/myHero.maxMana > self.Menu.Ripper.Harass.Mana:Value() / 100) and self.Menu.Ripper.Harass.E:Value() and self:Ready(_E) then
        Control.CastSpell(HK_E,target:GetPrediction(E.speed,E.delay))
    end
end

function Soraka:Flee()
  	if (not _G.SDK and not _G.GOS and not _G.EOWLoaded) then return end
    if self:GetValidEnemy(925) == false then return end
  	local target = (_G.SDK and _G.SDK.TargetSelector:GetTarget(925, _G.SDK.DAMAGE_TYPE_PHYSICAL)) or (_G.GOS and _G.GOS:GetTarget(925,"AD")) or ( _G.EOWLoaded and EOW:GetTarget())

    if self:IsValidTarget(target,800) and myHero.pos:DistanceTo(target.pos) < 800 and self.Menu.Ripper.Flee.Q:Value() and self:Ready(_Q) then
        Control.CastSpell(HK_Q,target:GetPrediction(Q.speed, Q.delay))
    end
    if self:IsValidTarget(target,925) and myHero.pos:DistanceTo(target.pos) < 925  and self.Menu.Ripper.Flee.E:Value() and self:Ready(_E) then
        Control.CastSpell(HK_E,target:GetPrediction(E.speed,E.delay))
    end
  	if self:GetValidAlly(550) == false then return end
  	if self:IsValidTarget(ally,550) and myHero.pos:DistanceTo(ally.pos) < 550 and self:Ready(_W) and (myHero.helth/myHero.maxHealth >= 60 / 100 ) then
    if ally.pos:DistanceTo(target.pos) < myHero.pos:DistanceTo(target.pos) then
    	Control.CastSpell(HK_W,ally)
    end
    end
end

function Soraka:GetAllyHeroes()
	local _AllyHeroes
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

function GetPercentHP(unit)
  if type(unit) ~= "userdata" then error("{GetPercentHP}: bad argument #1 (userdata expected, got "..type(unit)..")") end
  return 100*unit.health/unit.maxHealth
end

function Soraka:Heal()
  	if self.Menu.Ripper.Heal.W:Value() == false then return end
		for i,ally in pairs(self.GetAllyHeroes()) do
		if self:IsValidTarget(ally,W.range) and myHero.pos:DistanceTo(ally.pos) < 550 then
		if not ally.isMe then
		for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.team == myHero.team and not hero.isMe then
		if self.Menu.Ripper.Heal[hero.networkID]:Value() and self:Ready(_W) then
		if (ally.health/ally.maxHealth <= self.Menu.Ripper.Heal.HP[hero.networkID]:Value() / 100) and not ally.isMe and (myHero.health/myHero.maxHealth >= self.Menu.Ripper.Heal.Health:Value() / 100 ) then
				Control.CastSpell(HK_W,ally)
		
		end
		end
		end
		end
		end
		end
		end
end

function Soraka:CountEnemies(pos,range)
	local N = 0
	for i = 1,Game.HeroCount()  do
		local hero = Game.Hero(i)	
		if self:IsValidTarget(hero,range) and hero.team ~= myHero.team then
			N = N + 1
		end
	end
	return N	
end

function Soraka:AutoR()
  	if self.Menu.Ripper.ULT.R:Value() == false then return end
		for i,ally in pairs(self.GetAllyHeroes()) do
		if self:IsValidTarget(ally,300000) and myHero.pos:DistanceTo(ally.pos) < 300000 then
		if not ally.isMe then
		for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.team == myHero.team and not hero.isMe then
		if self.Menu.Ripper.ULT[hero.networkID]:Value() and self:Ready(_R) then
		if (ally.health/ally.maxHealth <= self.Menu.Ripper.ULT.HP[hero.networkID]:Value() / 100) and (self:CountEnemies(ally.pos,500) > 0) and not ally.isMe then
				Control.CastSpell(HK_R)
		
		end
		end
		end
		end
		end
		end
		end
end

function Soraka:SelfAutoR()
	if (not _G.SDK and not _G.GOS and not _G.EOWLoaded) then return end
    if self:GetValidEnemy(550) == false then return end
  	local target = (_G.SDK and _G.SDK.TargetSelector:GetTarget(550, _G.SDK.DAMAGE_TYPE_PHYSICAL)) or (_G.GOS and _G.GOS:GetTarget(550,"AD")) or ( _G.EOWLoaded and EOW:GetTarget())
	if self.Menu.Ripper.ULT.R:Value() == false then return end
		if (myHero.health/myHero.maxHealth <= self.Menu.Ripper.ULT.Health:Value() / 100) and self:Ready(_R) and (self:CountEnemies(myHero.pos,500) > 0)then
			Control.CastSpell(HK_R)
		end
end
  
function Soraka:KS()
    if self.Menu.Ripper.KS.Q:Value() == false then return end
    if self:GetValidEnemy(925) == false then return end
  	if (not _G.SDK and not _G.GOS and not _G.EOWLoaded) then return end
  	local target = (_G.SDK and _G.SDK.TargetSelector:GetTarget(925, _G.SDK.DAMAGE_TYPE_PHYSICAL)) or (_G.GOS and _G.GOS:GetTarget(925,"AD")) or ( _G.EOWLoaded and EOW:GetTarget())
    
  	if self:IsValidTarget(target,925) and myHero.pos:DistanceTo(target.pos) < 925 and self.Menu.Ripper.KS.E:Value() and self:Ready(_E) then
    	local level = myHero:GetSpellData(_E).level
    	local Edamage = CalcMagicalDamage(myHero, target, (({70, 110, 150, 190, 230})[level] + 0.4 * myHero.ap))
	if Edamage >= self:HpPred(target,1) + target.hpRegen * 2 then
  	Control.CastSpell(HK_E,target:GetPrediction(E.speed,E.delay))
	end
	end
	if self:IsValidTarget(target,800) and myHero.pos:DistanceTo(target.pos) < 800 and self.Menu.Ripper.KS.Q:Value() and self:Ready(_Q) then
    	local level = myHero:GetSpellData(_Q).level
    	local Qdamage = CalcMagicalDamage(myHero, target, (({70, 110, 150, 190, 230})[level] + 0.35 * myHero.ap))
	if 	Qdamage >= self:HpPred(target,1) + target.hpRegen * 2 then
  	Control.CastSpell(HK_Q,target:GetPrediction(Q.speed,Q.delay))
	end
    end
end

function Soraka:IsChannelling(unit)
	if not self.Spells[unit.charName] then return false end
	local result = false
	for _, spell in pairs(self.Spells[unit.charName]) do
		if unit:GetSpellData(spell.Key).level > 0 and (unit:GetSpellData(spell.Key).name == spell.SpellName or unit:GetSpellData(spell.Key).currentCd > unit:GetSpellData(spell.Key).cd - spell.Duration or (spell.Buff and self:GotBuff(unit,spell.Buff) > 0)) then
				result = true
				break
			
		end
	end
	return result
end

function Soraka:Misc()
    if self:GetValidEnemy(925) == false then return end
  	if (not _G.SDK and not _G.GOS and not _G.EOWLoaded) then return end
    if self:Ready(_E) and self:IsValidTarget(target,E.range) and self:IsChannelling(enemy) and self.Menu.Ripper.Misc.CancelE:Value() then
          Control.CastSpell(HK_E,target:GetPrediction(E.speed,E.delay))
    end
	if self:Ready(_E) and self:IsValidTarget(target,E.range) and self:HasCC() and self.Menu.Ripper.Misc.CCE:Value() then
          Control.CastSpell(HK_E,target:GetPrediction(E.speed,E.delay))
    end
end

function Soraka:Draw()
	if myHero.dead then return end
	if self.Menu.Ripper.Drawings.Q:Value() then Draw.Circle(myHero.pos, 800, self.Menu.Ripper.Drawings.Width:Value(), self.Menu.Ripper.Drawings.Color:Value())
	end
	if self.Menu.Ripper.Drawings.E:Value() then Draw.Circle(myHero.pos, 925, self.Menu.Ripper.Drawings.Width:Value(), self.Menu.Ripper.Drawings.Color:Value())	
	end	
end
    
function OnLoad()
    if myHero.charName ~= "Soraka" then return end
	Soraka()
end
