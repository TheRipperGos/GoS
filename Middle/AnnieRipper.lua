class "Annie"

function Annie:__init()
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

function Annie:LoadSpells()
  	Q = { range = myHero:GetSpellData(_Q).range, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed, width = myHero:GetSpellData(_Q).width }
	W = { range = myHero:GetSpellData(_W).range, delay = myHero:GetSpellData(_W).delay, speed = myHero:GetSpellData(_W).speed, width = myHero:GetSpellData(_W).width }
	E = { range = myHero:GetSpellData(_E).range, delay = myHero:GetSpellData(_E).delay, speed = myHero:GetSpellData(_E).speed, width = myHero:GetSpellData(_E).width }
	R = { range = myHero:GetSpellData(_R).range, delay = myHero:GetSpellData(_R).delay, speed = myHero:GetSpellData(_R).speed, width = myHero:GetSpellData(_R).width, radius = 290 }
end

function Annie:LoadMenu()
  	local Icons = { C = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/6/6f/AnnieSquare.png",
    				Q = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/2/25/Disintegrate.png", 
    				W = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/2/21/Incinerate.png", 
    				E = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/9/90/Molten_Shield.png", 
                    R = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/5/54/Summon_Tibbers.png" 
                  }
  
	--------- Menu Principal --------------------------------------------------------------
  	self.Menu = MenuElement({type = MENU, id = "Menu", name = "The Ripper Series", leftIcon = Icons.C})
	--------- Annie --------------------------------------------------------------------
	self.Menu:MenuElement({type = MENU, id = "Ripper", name = "Annie The Ripper", leftIcon = Icons.C })
	--------- Menu Principal --------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "Combo", name = "Combo"})
  	self.Menu.Ripper.Combo:MenuElement({id = "Q", name = "Use Q", value = true, leftIcon = Icons.Q})
	self.Menu.Ripper.Combo:MenuElement({id = "W", name = "Use W", value = true, leftIcon = Icons.W})
  	self.Menu.Ripper.Combo:MenuElement({id = "E", name = "Use E", value = true, leftIcon = Icons.E})
	self.Menu.Ripper.Combo:MenuElement({id = "R", name = "Use R", value = true, leftIcon = Icons.R})
	self.Menu.Ripper.Combo:MenuElement({id = "RS", name = "R just if have stun", value = true,})
	self.Menu.Ripper.Combo:MenuElement({id = "ER", name = "Min enemies to R", value = 2, min = 1, max = 5})
	--------- Menu LastHit --------------------------------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "LastHit", name = "Last Hit"})
  	self.Menu.Ripper.LastHit:MenuElement({id = "Q", name = "Use Q", value = true, leftIcon = Icons.Q})
	self.Menu.Ripper.LastHit:MenuElement({id = "SS", name = "Save Stun", value = true})
    self.Menu.Ripper.LastHit:MenuElement({id = "Mana", name = "Min mana to LastHit (%)", value = 40, min = 0, max = 100})
	--------- Menu LaneClear ------------------------------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "LaneClear", name = "Lane Clear"})
  	self.Menu.Ripper.LaneClear:MenuElement({id = "Q", name = "Use Q", value = true, leftIcon = Icons.Q})
	self.Menu.Ripper.LaneClear:MenuElement({id = "W", name = "Use W", value = true, leftIcon = Icons.W})
    self.Menu.Ripper.LaneClear:MenuElement({id = "HW", name = "Min minions hit by W", value = 4, min = 1, max = 7})
	self.Menu.Ripper.LaneClear:MenuElement({id = "SS", name = "Save Stun", value = true})
    self.Menu.Ripper.LaneClear:MenuElement({id = "Mana", name = "Min mana to Clear (%)", value = 40, min = 0, max = 100})
	--------- Menu JungleClear ------------------------------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "JungleClear", name = "Jungle Clear"})
  	self.Menu.Ripper.JungleClear:MenuElement({id = "Q", name = "Use Q", value = true, leftIcon = Icons.Q})
	self.Menu.Ripper.JungleClear:MenuElement({id = "W", name = "Use W", value = true, leftIcon = Icons.W})
	self.Menu.Ripper.JungleClear:MenuElement({id = "SS", name = "Save Stun", value = true})
    self.Menu.Ripper.JungleClear:MenuElement({id = "Mana", name = "Min mana to Clear (%)", value = 40, min = 0, max = 100})
	--------- Menu Harass ---------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "Harass", name = "Harass"})
  	self.Menu.Ripper.Harass:MenuElement({id = "Q", name = "Use Q", value = true, leftIcon = Icons.Q})
  	self.Menu.Ripper.Harass:MenuElement({id = "W", name = "Use W", value = true, leftIcon = Icons.W})
	self.Menu.Ripper.Harass:MenuElement({id = "SS", name = "Save Stun", value = false})
    self.Menu.Ripper.Harass:MenuElement({id = "Mana", name = "Min mana to Harass (%)", value = 40, min = 0, max = 100})
	--------- Menu Flee ----------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "Flee", name = "Flee"})
  	self.Menu.Ripper.Flee:MenuElement({id ="Q", name = "Use Q if have stun", value = true, leftIcon = Icons.Q})
	self.Menu.Ripper.Flee:MenuElement({id ="W", name = "Use W to stack stun", value = true, leftIcon = Icons.W})
  	self.Menu.Ripper.Flee:MenuElement({id ="E", name = "Use E to stack stun", value = true, leftIcon = Icons.E})
	--------- Menu KS -----------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "KS", name = "Killsteal"})
  	self.Menu.Ripper.KS:MenuElement({id = "Q", name = "Use Q", value = true, leftIcon = Icons.Q})
  	self.Menu.Ripper.KS:MenuElement({id = "W", name = "Use W", value = true, leftIcon = Icons.W})
	self.Menu.Ripper.KS:MenuElement({id = "R", name = "Use R", value = true, leftIcon = Icons.R})	
	--------- Menu Misc -----------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "Misc", name = "Misc"})
    self.Menu.Ripper.Misc:MenuElement({id = "AI", name = "Auto Q interrupter", value = true})
	self.Menu.Ripper.Misc:MenuElement({id = "ES", name = "Auto E passive stack", value = true})
    self.Menu.Ripper.Misc:MenuElement({id = "Mana", name = "Min mana to auto E (%)", value = 40, min = 0, max = 100})
	--------- Menu Drawings --------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "Drawings", name = "Drawings"})
  	self.Menu.Ripper.Drawings:MenuElement({id = "Q", name = "Draw Q range", value = true, leftIcon = Icons.Q})
  	self.Menu.Ripper.Drawings:MenuElement({id = "W", name = "Draw W range", value = true, leftIcon = Icons.W})
  	self.Menu.Ripper.Drawings:MenuElement({id = "R", name = "Draw R range", value = true, leftIcon = Icons.R})
  	self.Menu.Ripper.Drawings:MenuElement({id = "Width", name = "Width", value = 2, min = 1, max = 5, step = 1})
	self.Menu.Ripper.Drawings:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 0, 0, 255)})
end

function Annie:Tick()
  	local Combo = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO]) or (_G.GOS and _G.GOS:GetMode() == "Combo") or (_G.EOWLoaded and EOW:Mode() == "Combo")
  	local LastHit = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT]) or (_G.GOS and _G.GOS:GetMode() == "Lasthit") or (_G.EOWLoaded and EOW:Mode() == "LastHit")
  	local Clear = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR]) or (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR]) or (_G.GOS and _G.GOS:GetMode() == "Clear") or (_G.EOWLoaded and EOW:Mode() == "LaneClear")
  	local Harass = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS]) or (_G.GOS and _G.GOS:GetMode() == "Harass") or (_G.EOWLoaded and EOW:Mode() == "Harass")
  	local Flee = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE]) or (_G.GOS and _G.GOS:GetMode() == "Flee") or (_G.EOWLoaded and EOW:Mode() == "Flee")
  	if Combo then
    	self:Combo()
	elseif Clear then
		self:LaneClear()
		self:JungleClear()
    elseif LastHit then
    	self:LastQ()
	elseif Harass then
		self:Harass()
	elseif Flee then
		self:Flee()
	end
		self:Misc()
		self:AutoPilot()
		self:KS()
end

function Annie:GetValidEnemy(range)
  	for i = 1,Game.HeroCount() do
    	local enemy = Game.Hero(i)
    	if  enemy.team ~= myHero.team and enemy.valid and enemy.pos:DistanceTo(myHero.pos) < 1200 then
    		return true
    	end
    end
  	return false
end

function Annie:CountEnemyMinions(range)
	local minionsCount = 0
    for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < Q.range then
            minionsCount = minionsCount + 1
        end
    end
    return minionsCount
end

function Annie:IsValidTarget(unit,range)
    return unit ~= nil and unit.valid and unit.visible and not unit.dead and unit.isTargetable and not unit.isImmortal and unit.pos:DistanceTo(myHero.pos) <= 300000
end

function Annie:StunIsUp()
	if myHero.hudAmmo == myHero.hudMaxAmmo then
	return true
	end
	return false
end

function Annie:TibbersAlive()
	if myHero:GetSpellData(_R).toggleState == 2 then
		return true
	end
	return false
end

function Annie:TibbersCanBeCast()
	if myHero:GetSpellData(_R).toggleState == 1 and self:Ready(_R) then
		return true
	end
	return false
end

function Annie:Ready (spell)
	return Game.CanUseSpell(spell) == 0 
end
	
function Annie:EnemiesAround(pos, range)
    local Count = 0
    for i = 1, Game.HeroCount() do
        local e = Game.Hero(i)
        if e and e.team ~= myHero.team and not e.dead and e.pos:DistanceTo(pos, e.pos) <= 290 then
            Count = Count + 1
        end
    end
    return Count
end
	
function Annie:Combo()
  	if self:GetValidEnemy(1200) == false then return end
  	if (not _G.SDK and not _G.GOS and not _G.EOWLoaded) then return end
  	local target = (_G.SDK and _G.SDK.TargetSelector:GetTarget(1200, _G.SDK.DAMAGE_TYPE_PHYSICAL)) or (_G.GOS and _G.GOS:GetTarget(1200,"AD")) or ( _G.EOWLoaded and EOW:GetTarget())

    if self:IsValidTarget(target,625) and myHero.pos:DistanceTo(target.pos) < 625 and self.Menu.Ripper.Combo.Q:Value() and self:Ready(_Q) and not self:StunIsUp() then
        Control.CastSpell(HK_Q,target)
    end
    if self:IsValidTarget(target,600) and myHero.pos:DistanceTo(target.pos) < 600 and self.Menu.Ripper.Combo.W:Value() and self:Ready(_W) and not self:StunIsUp() then
        Control.CastSpell(HK_W,target:GetPrediction(W.speed,W.delay))
    end
	if self:IsValidTarget(target,600) and myHero.pos:DistanceTo(target.pos) < 600 and self.Menu.Ripper.Combo.E:Value() and self:Ready(_E) and not self:StunIsUp() then
        Control.CastSpell(HK_E)
    end
	if self:IsValidTarget(target,600) and myHero.pos:DistanceTo(target.pos) < 600 and self.Menu.Ripper.Combo.R:Value() and self:Ready(_R) and not self:StunIsUp() and self:EnemiesAround(target.pos, 290) >= self.Menu.Ripper.Combo.ER:Value() and not self:TibbersAlive() then
		if self.Menu.Ripper.Combo.RS:Value() == true then return end
        Control.CastSpell(HK_R,target:GetPrediction(R.speed,R.delay))
	end
	if self:IsValidTarget(target,625) and myHero.pos:DistanceTo(target.pos) < 625 and self.Menu.Ripper.Combo.Q:Value() and self:Ready(_Q) and self:StunIsUp() and not self:TibbersCanBeCast() then
        Control.CastSpell(HK_Q,target)
    end
    if self:IsValidTarget(target,600) and myHero.pos:DistanceTo(target.pos) < 600 and self.Menu.Ripper.Combo.W:Value() and self:Ready(_W) and self:StunIsUp() and not self:TibbersCanBeCast() then
        Control.CastSpell(HK_W,target:GetPrediction(W.speed,W.delay))
    end
	if self:IsValidTarget(target,600) and myHero.pos:DistanceTo(target.pos) < 600 and self.Menu.Ripper.Combo.R:Value() and self:Ready(_R) and self:StunIsUp() and self:EnemiesAround(target.pos, 290) >= self.Menu.Ripper.Combo.ER:Value() and not self:TibbersAlive() then
        Control.CastSpell(HK_R,target:GetPrediction(R.speed,R.delay))
    end
	if self:IsValidTarget(target,625) and myHero.pos:DistanceTo(target.pos) < 625 and self.Menu.Ripper.Combo.Q:Value() and self:Ready(_Q) and self:StunIsUp() and self:EnemiesAround(target.pos, 290) < self.Menu.Ripper.Combo.ER:Value() then
        Control.CastSpell(HK_Q,target)
    end
    if self:IsValidTarget(target,600) and myHero.pos:DistanceTo(target.pos) < 600 and self.Menu.Ripper.Combo.W:Value() and self:Ready(_W) and self:StunIsUp() and self:EnemiesAround(target.pos, 290) < self.Menu.Ripper.Combo.ER:Value() then
        Control.CastSpell(HK_W,target:GetPrediction(W.speed,W.delay))
    end
end

function Annie:LastQ()
	if self.Menu.Ripper.LastHit.SS:Value() and self:StunIsUp() then return end
	if self.Menu.Ripper.LastHit.Q:Value() == false then return end
  	local level = myHero:GetSpellData(_Q).level
	if level == nil or level == 0 then return end
  	if self:GetValidMinion(625) == false then return end
  	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
    	local Qdamage = (({80, 115, 150, 185, 220})[level] + 0.8 * myHero.ap)
    	if self:IsValidTarget(minion,625) and myHero.pos:DistanceTo(minion.pos) < 625 and (myHero.mana/myHero.maxMana >= self.Menu.Ripper.LastHit.Mana:Value() / 100 ) and minion.isEnemy then
      	if Qdamage >= self:HpPred(minion, 0.5) and self:Ready(_Q) then
			Control.CastSpell(HK_Q,minion.pos)
		end
        end
      	end
end

function Annie:GetValidMinion(range)
    	for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 625 then
        return true
        end
    	end
    	return false
end

function Annie:HasCC(unit)	
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

function Annie:HpPred(unit, delay)
	if _G.GOS then
	hp =  GOS:HP_Pred(unit,delay)
	else
	hp = unit.health
	end
	return hp
end

function Annie:MinionsAround(pos, range, team)
    local Count = 0
    for i = 1, Game.MinionCount() do
        local m = Game.Minion(i)
        if m and m.team == 200 and not m.dead and m.pos:DistanceTo(pos, m.pos) < 175 then
            Count = Count + 1
        end
    end
    return Count
end

function Annie:LaneClear()
	if self.Menu.Ripper.LaneClear.SS:Value() and self:StunIsUp() then return end
  	if self:GetValidMinion(Q.range) == false then return end
  	local level = myHero:GetSpellData(_Q).level
	if level == nil or level == 0 then return end
  	if self:GetValidMinion(625) == false then return end
  	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
		if  minion.team == 200 then
    	local Qdamage = (({80, 115, 150, 185, 220})[level] + 0.8 * myHero.ap)
    	if self:IsValidTarget(minion,625) and myHero.pos:DistanceTo(minion.pos) < 625 and self.Menu.Ripper.LaneClear.Q:Value() and (myHero.mana/myHero.maxMana >= self.Menu.Ripper.LaneClear.Mana:Value() / 100 ) and minion.isEnemy then
      	if Qdamage >= self:HpPred(minion, 0.5) and self:Ready(_Q) then
			Control.CastSpell(HK_Q,minion.pos)
		end
        end
		if self:IsValidTarget(minion,500) and self:Ready(_W) and myHero.pos:DistanceTo(minion.pos) < 500 and self.Menu.Ripper.LaneClear.W:Value() and (myHero.mana/myHero.maxMana >= self.Menu.Ripper.LaneClear.Mana:Value() / 100 ) and minion.isEnemy then
		if self:MinionsAround(minion.pos, 175, 200) >= self.Menu.Ripper.LaneClear.HW:Value() then
			Control.CastSpell(HK_W,minion.pos)
		end
		end
		end
	end
end

function Annie:JungleClear()
	if self.Menu.Ripper.JungleClear.SS:Value() and self:StunIsUp() then return end
  	if self:GetValidMinion(Q.range) == false then return end
  	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
    	if  minion.team == 300 then
			if self:IsValidTarget(minion,625) and myHero.pos:DistanceTo(minion.pos) < 625 and self.Menu.Ripper.JungleClear.Q:Value() and (myHero.mana/myHero.maxMana >= self.Menu.Ripper.JungleClear.Mana:Value() / 100 ) and self:Ready(_Q) then
			Control.CastSpell(HK_Q,minion.pos)
			break
			end
			if self:IsValidTarget(minion,600) and myHero.pos:DistanceTo(minion.pos) < 600 and self.Menu.Ripper.JungleClear.W:Value() and (myHero.mana/myHero.maxMana >= self.Menu.Ripper.JungleClear.Mana:Value() / 100 ) and self:Ready(_W) then
			Control.CastSpell(HK_W,minion.pos)
			break
			end
		end
    end
end

function Annie:GetValidAlly(range)
  	for i = 1,Game.HeroCount() do
    	local ally = Game.Hero(i)
    	if  ally.team == myHero.team and ally.valid and ally.pos:DistanceTo(myHero.pos) > 1 then
    		return true
    	end
    end
  	return false
end

function Annie:Harass()
	if self.Menu.Ripper.Harass.SS:Value() and self:StunIsUp() then return end
  	if (not _G.SDK and not _G.GOS and not _G.EOWLoaded) then return end
    if self:GetValidEnemy(625) == false then return end
  	local target = (_G.SDK and _G.SDK.TargetSelector:GetTarget(625, _G.SDK.DAMAGE_TYPE_PHYSICAL)) or (_G.GOS and _G.GOS:GetTarget(625,"AD")) or ( _G.EOWLoaded and EOW:GetTarget())
    if self:IsValidTarget(target,625) and myHero.pos:DistanceTo(target.pos) < 625 and (myHero.mana/myHero.maxMana > self.Menu.Ripper.Harass.Mana:Value() / 100) and self.Menu.Ripper.Harass.Q:Value() and self:Ready(_Q) then
        Control.CastSpell(HK_Q,target)
    end
    if self:IsValidTarget(target,600) and myHero.pos:DistanceTo(target.pos) < 600 and (myHero.mana/myHero.maxMana > self.Menu.Ripper.Harass.Mana:Value() / 100) and self.Menu.Ripper.Harass.W:Value() and self:Ready(_W) then
        Control.CastSpell(HK_W,target:GetPrediction(W.speed,W.delay))
    end
end

function Annie:HasBuff(unit, buffname)
	for i = 0, unit.buffCount do
	local buff = unit:GetBuff(i)
	if buff.name == buffname and buff.count > 0 then 
	return true
	end
	end
	return false
end

function Annie:Flee()
  	if (not _G.SDK and not _G.GOS and not _G.EOWLoaded) then return end
    if self:GetValidEnemy(625) == false then return end
  	local target = (_G.SDK and _G.SDK.TargetSelector:GetTarget(625, _G.SDK.DAMAGE_TYPE_PHYSICAL)) or (_G.GOS and _G.GOS:GetTarget(625,"AD")) or ( _G.EOWLoaded and EOW:GetTarget())

    if self:IsValidTarget(target,625) and myHero.pos:DistanceTo(target.pos) < 625 and self:StunIsUp() and self.Menu.Ripper.Flee.Q:Value() and self:Ready(_Q) then
        Control.CastSpell(HK_Q,target)
    end
	if self:IsValidTarget(target,600) and myHero.pos:DistanceTo(target.pos) < 600 and not self:StunIsUp() and self.Menu.Ripper.Flee.W:Value() and self:Ready(_W) then
        Control.CastSpell(HK_W,target:GetPrediction(W.speed,W.delay))
    end
    if self:IsValidTarget(target,725) and myHero.pos:DistanceTo(target.pos) < 725 and not self:StunIsUp() and self.Menu.Ripper.Flee.E:Value() and self:Ready(_E) then
        Control.CastSpell(HK_E)
    end
end

function Annie:GetAllyHeroes()
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
  
function Annie:KS()
    if self:GetValidEnemy(625) == false then return end
  	if (not _G.SDK and not _G.GOS and not _G.EOWLoaded) then return end
  	local target = (_G.SDK and _G.SDK.TargetSelector:GetTarget(625, _G.SDK.DAMAGE_TYPE_PHYSICAL)) or (_G.GOS and _G.GOS:GetTarget(625,"AD")) or ( _G.EOWLoaded and EOW:GetTarget())
    
  	if self:IsValidTarget(target,625) and myHero.pos:DistanceTo(target.pos) < 625 and self.Menu.Ripper.KS.Q:Value() and self:Ready(_Q) then
    	local level = myHero:GetSpellData(_Q).level
    	local Qdamage = CalcMagicalDamage(myHero, target, (({80, 115, 150, 185, 220})[level] + 0.8 * myHero.ap))
	if Qdamage >= self:HpPred(target,1) + target.hpRegen * 2 then
  	Control.CastSpell(HK_Q,target)
	end
	end
	if self:IsValidTarget(target,600) and myHero.pos:DistanceTo(target.pos) < 600 and self.Menu.Ripper.KS.W:Value() and self:Ready(_W) then
    	local level = myHero:GetSpellData(_W).level
    	local Wdamage = CalcMagicalDamage(myHero, target, (({70, 115, 160, 205, 250})[level] + 0.85 * myHero.ap))
	if 	Wdamage >= self:HpPred(target,1) + target.hpRegen * 2 then
  	Control.CastSpell(HK_W,target:GetPrediction(W.speed,W.delay))
	end
    end
	if self:IsValidTarget(target,600) and myHero.pos:DistanceTo(target.pos) < 600 and self.Menu.Ripper.KS.R:Value() and self:TibbersCanBeCast() then
    	local level = myHero:GetSpellData(_R).level
    	local Rdamage = CalcMagicalDamage(myHero, target, (({150, 275, 400})[level] + 0.65 * myHero.ap))
	if 	Rdamage >= self:HpPred(target,1) + target.hpRegen * 2 and not self:TibbersAlive() then
  	Control.CastSpell(HK_R,target:GetPrediction(R.speed,R.delay))
	end
    end
end

function Annie:IsChannelling(unit)
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

function Annie:Misc()
  	if (not _G.SDK and not _G.GOS and not _G.EOWLoaded) then return end
    if self:Ready(_Q) and self:IsValidTarget(target,625) and self:StunIsUp() and self:IsChannelling(enemy) and self.Menu.Ripper.Misc.AI:Value() then
          Control.CastSpell(HK_Q,target)
    end
	if self:Ready(_E) and (myHero.mana/myHero.maxMana > self.Menu.Ripper.Misc.Mana:Value() / 100) and self.Menu.Ripper.Misc.ES:Value() and not self:StunIsUp() then
          Control.CastSpell(HK_E)
    end
end

function Annie:AutoPilot()
	if self:TibbersAlive() == false then return end
	if self:GetValidEnemy(650) == false then return end
  	if (not _G.SDK and not _G.GOS and not _G.EOWLoaded) then return end
  	local target = (_G.SDK and _G.SDK.TargetSelector:GetTarget(650, _G.SDK.DAMAGE_TYPE_PHYSICAL)) or (_G.GOS and _G.GOS:GetTarget(650,"AD")) or ( _G.EOWLoaded and EOW:GetTarget())
	if self:IsValidTarget(target,650) then
	DelayAction(function()
	Control.CastSpell(HK_R,target)
	end, 8)
	end
end

function Annie:Draw()
	if myHero.dead then return end
	if self.Menu.Ripper.Drawings.Q:Value() then Draw.Circle(myHero.pos, Q.range, self.Menu.Ripper.Drawings.Width:Value(), self.Menu.Ripper.Drawings.Color:Value())
	end
	if self.Menu.Ripper.Drawings.W:Value() then Draw.Circle(myHero.pos, W.range, self.Menu.Ripper.Drawings.Width:Value(), self.Menu.Ripper.Drawings.Color:Value())
	end
	if self.Menu.Ripper.Drawings.R:Value() then Draw.Circle(myHero.pos, R.range, self.Menu.Ripper.Drawings.Width:Value(), self.Menu.Ripper.Drawings.Color:Value())
	end
end
    
function OnLoad()
    if myHero.charName ~= "Annie" then return end
	Annie()
end
