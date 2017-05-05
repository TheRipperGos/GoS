class "Soraka"

function Soraka:__init()
  	self:LoadSpells()
  	self:LoadMenu()
  	Callback.Add("Tick", function() self:tick() end)
  	Callback.Add("Draw", function() self:draw() end)
end

function Soraka:LoadSpells()
  	Q = { range = myHero:GetSpellData(_Q).range, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed, width = myHero:GetSpellData(_Q).width }
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
  	local 
  
  --------- Menu Principal --------------------------------------------------------------
  ------ Main Menu -------------------------------------------------------------------------------------------------------------------
  	self.Menu = MenuElement({type = MENU, id = "Menu", name = "The Ripper Series", leftIcon = Icons.C})
-- Shyvana ---------------------------------------------------------------------------------------------------------------------
	self.Menu:MenuElement({type = MENU, id = "Ripper", name = "Soraka The Healer", leftIcon = Icons.C })
  --------- Menu Principal --------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "Combo", name = "Combo"})
  	self.Menu.Ripper.Combo:MenuElement({id = "Q", name = "Use Q", value = true, leftIcon = Icons.Q})
  	self.Menu.Ripper.Combo:MenuElement({id = "W", name = "Use W", value = true, leftIcon = Icons.W})
  	self.Menu.Ripper.Combo:MenuElement({id = "E", name = "Use E", value = true, leftIcon = Icons.E})
  --------- Menu LastHit --------------------------------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "LastHit", name = "Last Hit"})
  	self.Menu.Ripper.LastHit:MenuElement({id = "Q", name = "Use Q", value = true, leftIcon = Icons.Q})
    self.Menu.Ripper.LastHit:MenuElement({id = "HQ", name = "Min minions hit Q", value = 4, min = 1, max = 5})
  --------- Menu LaneClear ------------------------------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "LaneClear", name = "Lane Clear"})
  	self.Menu.Ripper.LaneClear:MenuElement({id = "Q", name = "Use Q", value = true, leftIcon = Icons.Q})
    self.Menu.Ripper.LaneClear:MenuElement({id = "HQ", name = "Min minions hit Q", value = 4, min = 1, max = 5})
    self.Menu.Riper.LaneClear:MenuElement({id = "MQ", name = "Minimum mana", value = 40, min = 0, max = 100})
  --------- Menu JungleClear --------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "JungleClear", name = "Jungle Clear"})
  	self.Menu.Ripper.JungleClear:MenuElement({id = "Q", name = "Use Q", value = true, leftIcon = Icons.Q})
    self.Menu.Ripper.JungleClear:MenuElement({id = "MQ", name = "Minimum mana", value = 30, min = 0, max = 100})
     --------- Menu Harass ---------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "Harass", name = "Harass"})
  	self.Menu.Ripper.Harass:MenuElement({id = "Q", name = "Use E", value = true, leftIcon = Icons.Q})
  	self.Menu.Ripper.Harass:MenuElement({id = "E", name = "Use E", value = true, leftIcon = Icons.E})
  --------- Menu Flee ----------------------------------------------------------------------------
  	self.Menu.Ripper.MenuPrincipal:MenuElement({type = MENU, id = "Flee", name = "Flee"})
  	self.Menu.Ripper.Flee:MenuElement({id ="W", name = "Use Q", value = true, leftIcon = Icons.W})
  	self.Menu.Ripper.Flee:MenuElement({id ="E", name = "Use E", value = true, leftIcon = Icons.E})
    --------- Menu Heal------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "Heal", name = "Heal"})
  	self.Menu.Ripper.Heal:MenuElement({id = "W", name = "Use W", value = true, leftIcon = Icons.W})
  	self.Menu.Ripper.Heal:MenuElement({id = "Health", name = "Min Soraka Health", value = 20, min = 5, max = 100})
  	self.Menu.Ripper.Heal:MenuElement({id = "Ally1", name = "ALLY NAME", value = true, leftIcon = })
  	self.Menu.Ripper.Heal:MenuElement({id = "A1H", name = "Max Health", value = 60, min = 0, max = 100})
  	self.Menu.Ripper.Heal:MenuElement({id = "Ally2", name = "ALLY NAME", value = true, leftIcon = })
  	self.Menu.Ripper.Heal:MenuElement({id = "A2H", name = "Max Health", value = 60, min = 0, max = 100})
  	self.Menu.Ripper.Heal:MenuElement({id = "Ally3", name = "ALLY NAME", value = true, leftIcon = })
  	self.Menu.Ripper.Heal:MenuElement({id = "A3H", name = "Max Health", value = 60, min = 0, max = 100})
  	self.Menu.Ripper.Heal:MenuElement({id = "Ally4", name = "ALLY NAME", value = true, leftIcon = })
  	self.Menu.Ripper.Heal:MenuElement({id = "A4H", name = "Max Health", value = 60, min = 0, max = 100})
  	self.Menu.Ripper.Heal:MenuElement({id = "Allyy5", name = "ALLY NAME", value = true, leftIcon = })
  	self.Menu.Ripper.Heal:MenuElement({id = "A5H", name = "Max Health", value = 60, min = 0, max = 100})
  --------- Menu ULT ----------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "ULT", name = "Ultimate"})
  	self.Menu.Ripper.ULT:MenuElement({id = "R", name = "Use R", value = true, leftIcon = Icons.R})
  	self.Menu.Ripper.ULT:MenuElement({id = "All", name = "Heal Allies", value = true})
  	self.Menu.Ripper.ULT:MenuElement({id = "AHP", name = "Ally HP", value = 30, min = 0, max = 100})
  	self.Menu.Ripper.ULT:MenuElement({id = "MyHP", name = "My HP", value = 25, min = 0, max = 100})
  --------- Menu KS -----------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "KS", name = "Killsteal"})
  	self.Menu.Ripper.KS:MenuElement({id = "W", name = "Use W", value = true, leftIcon = Icons.W})
  	self.Menu.Ripper.KS:MenuElement({id = "E", name = "Use E", value = true, leftIcon = Icons.E})                   
  --------- Menu Misc -----------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "Misc", name = "Misc"}) -- coloca, Auto E if enemy has CC
    self.Menu.Ripper.Misc:MenuElement({id = "CCE", name = "Auto E if enemy has CC", value = true})
  	self.Menu.Ripper.Misc:MenuElement({id = "CancelE", name = "Cancel spells E", value = true})
  --------- Menu Drawings --------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "Drawings", name = "Drawings"})
  	self.Menu.Ripper.Drawings:MenuElement({id = "Q", name = "Draw Q range", value = true, leftIcon = Icons.Q})
  	self.Menu.Ripper.Drawings:MenuElement({id = "E", name = "Draw E range", value = true, leftIcon = Icons.E})
  	self.Menu.Ripper.Drawings:MenuElement({id = "Width", name = "Width", value = 2, min = 1, max = 5, step = 1})
	self.Menu.Ripper.Drawings:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 0, 0, 255)})
  	self.Menu.Ripper.Drawings:MenuElement({id = "W", name = "Draw W range", value = true, leftIcon = Icons.W})
    self.Menu.Ripper.Drawings:MenuElement({id = "WWidth", name = "Width", value = 2, min = 1, max = 5, step = 1})
	self.Menu.Ripper.Drawings:MenuElement({id = "WColor", name = "Color", color = Draw.Color(0, 255, 0, 255)})
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
    	self:LastHitQ()
    elseif Clear then
    	self:LaneClear()
    	self:JungleClear()
    elseif Harass then
    	self:Harass()
    elseif Flee then
    	self:Flee()
    end
        self:AutoW()
		self:AutoR()
  		self:KS()
  		self:AutoCC()
  		self:AutoCancel()
  	end
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
    return unit ~= nil and unit.valid and unit.visible and not unit.dead and unit.isTargetable and not unit.isImmortal and unit.pos:DistanceTo(myHero.pos) <= 1200
end

function Soraka:Ready (spell)
	return Game.CanUseSpell(spell) == 0 
end

function Soraka:CountEnemys(range)
	local heroesCount = 0
    for i = 1,Game.HeroCount() do
        local enemy = Game.Hero(i)
        if  enemy.team ~= myHero.team and enemy.valid and enemy.pos:DistanceTo(myHero.pos) < 1200 then
            heroesCount = heroesCount + 1
        end
    end
    return heroesCount
end

function Soraka:EnemiesSkillRange()
	
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
    local Qdamage = (({70, 110, 150, 190, 230})[level] + 0.35 * myHero.ap) --({70, 110, 150, 190, 230})[level] + 0.35 * source.ap
    if self:IsValidTarget(minion,800) and minion.isEnemy then
    	if Qdamage >= minion.health and Qdamage >= self:HpPred(minion, 0.5) and self:Ready(_Q) then
    		Control.CastSpell(HK_W,minion.pos)
    	end
    end
    end
end

function OnLoad()
    	if myHero.charName ~= "Soraka" then return end
	Soraka()
end
