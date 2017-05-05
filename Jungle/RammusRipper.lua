class "Rammus" 

function Rammus:__init() 
	self:LoadSpells()
  	self:LoadMenu() 
  	Callback.Add("Tick", function() self:Tick() end)
  	Callback.Add("Draw", function() self:Draw() end) 
end

function Rammus:LoadSpells() 
  	Q = { range = myHero:GetSpellData(_Q).range, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed, width = myHero:GetSpellData(_Q).width }
	W = { range = myHero:GetSpellData(_W).range, delay = myHero:GetSpellData(_W).delay, speed = myHero:GetSpellData(_W).speed, width = myHero:GetSpellData(_W).width }
	E = { range = myHero:GetSpellData(_E).range, delay = myHero:GetSpellData(_E).delay, speed = myHero:GetSpellData(_E).speed, width = myHero:GetSpellData(_E).width }
	R = { range = myHero:GetSpellData(_R).range, delay = myHero:GetSpellData(_R).delay, speed = myHero:GetSpellData(_R).speed, width = myHero:GetSpellData(_R).width }
end

function Rammus:LoadMenu()
  	local Icons = { C = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/7/7c/RammusSquare.png",
    			Q = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/8/8d/Powerball.png",
    			W = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/f/f7/Defensive_Ball_Curl.png",
    			E = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/2/26/Puncturing_Taunt.png",
                    	R = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/1/1c/Tremors.png" }
	-- Main Menu -------------------------------------------------------------------------------------------------------------------
  	self.Menu = MenuElement({type = MENU, id = "Menu", name = "The Ripper Series", leftIcon = Icons.C})
	-- Rammus ---------------------------------------------------------------------------------------------------------------------
	self.Menu:MenuElement({type = MENU, id = "Ripper", name = "Rammus The Ripper", leftIcon = Icons.C })
	-- Combo -----------------------------------------------------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "Combo", name = "Combo"})
  	self.Menu.Ripper.Combo:MenuElement({id = "Q", name = "Use Q", value = true, leftIcon = Icons.Q})
  	self.Menu.Ripper.Combo:MenuElement({id = "W", name = "Use W", value = true, leftIcon = Icons.W})
  	self.Menu.Ripper.Combo:MenuElement({id = "E", name = "Use E", value = true, leftIcon = Icons.E})
  	self.Menu.Ripper.Combo:MenuElement({id = "R", name = "Use R", value = true, leftIcon = Icons.R})
	self.Menu.Ripper.Combo:MenuElement({id = "XR", name = "Use R to kill in X secs (ticks)", value = 2, min = 1, max = 8})
	-- LaneClear -------------------------------------------------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "LaneClear", name = "Lane Clear"})
  	self.Menu.Ripper.LaneClear:MenuElement({id = "W", name = "Use W", value = true, leftIcon = Icons.W})
	self.Menu.Ripper.LaneClear:MenuElement({id = "Mana", name = "Min mana to Clear (%)", value = 40, min = 0, max = 100})
	-- JungleClear -----------------------------------------------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "JungleClear", name = "Jungle Clear"})
  	self.Menu.Ripper.JungleClear:MenuElement({id = "Q", name = "Use Q", value = true, leftIcon = Icons.Q})
  	self.Menu.Ripper.JungleClear:MenuElement({id = "W", name = "Use W", value = true, leftIcon = Icons.W})
  	self.Menu.Ripper.JungleClear:MenuElement({id = "E", name = "Use E", value = true, leftIcon = Icons.E})
	self.Menu.Ripper.JungleClear:MenuElement({id = "Mana", name = "Min mana to Clear (%)", value = 40, min = 0, max = 100})
	-- Flee ------------------------------------------------------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "Flee", name = "Flee"})
  	self.Menu.Ripper.Flee:MenuElement({id ="Q", name = "Use Q", value = true, leftIcon = Icons.Q})
	-- Killsteal -------------------------------------------------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "KS", name = "Killsteal"})
  	self.Menu.Ripper.KS:MenuElement({id = "R", name = "Use R", value = true, leftIcon = Icons.R})
	-- Harass ----------------------------------------------------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "Harass", name = "Harass"})
  	self.Menu.Ripper.Harass:MenuElement({id = "W", name = "Use W", value = true, leftIcon = Icons.W})
	self.Menu.Ripper.Harass:MenuElement({id = "Mana", name = "Min mana to Harass (%)", value = 40, min = 0, max = 100})
	-- Misc ------------------------------------------------------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "Misc", name = "Misc"})
	self.Menu.Ripper.Misc:MenuElement({id = "RangeQ", name = "Enemy max distance to Q", value = 1200, min = 325, max = 2000, step = 25})
  	self.Menu.Ripper.Misc:MenuElement({id = "AutoR", name = "Auto R", value = false, leftIcon = Icons.R})
	self.Menu.Ripper.Misc:MenuElement({id = "EAutoR", name = "Enemies to auto R", value = 4, min = 1, max = 5})
  	self.Menu.Ripper.Misc:MenuElement({id = "Key", name = "Auto R Key", key = string.byte(" ")})
	-- Drawings --------------------------------------------------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "Drawings", name = "Drawings"})
	self.Menu.Ripper.Drawings:MenuElement({id = "Q", name = "Draw Q engage range", value = true})
  	self.Menu.Ripper.Drawings:MenuElement({id = "R", name = "Draw R range", value = true})
  	self.Menu.Ripper.Drawings:MenuElement({id = "Width", name = "Width", value = 3, min = 1, max = 5, step = 1})
	self.Menu.Ripper.Drawings:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 0, 0, 255)})
end

function Rammus:Tick()
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
    	elseif Harass then
    	self:Harass()
    	elseif Flee then
    	self:Flee()
    	elseif self.Menu.Ripper.Misc.Key:Value() then
    	self:AutoR()
    	end
	self:KS()
end

function Rammus:GetValidEnemy(range)
  	for i = 1,Game.HeroCount() do
    	local enemy = Game.Hero(i)
    	if  enemy.team ~= myHero.team and enemy.valid and enemy.pos:DistanceTo(myHero.pos) < 1500 then
    	return true
    	end
    	end
  	return false
end

function Rammus:IsValidTarget(unit,range) 
	return unit ~= nil and unit.valid and unit.visible and not unit.dead and unit.isTargetable and not unit.isImmortal and unit.pos:DistanceTo(myHero.pos) <= 1500 
end

function Rammus:Ready (spell)
	return Game.CanUseSpell(spell) == 0 
end

function Rammus:CountEnemys(range)
	local heroesCount = 0
    	for i = 1,Game.HeroCount() do
        local enemy = Game.Hero(i)
        if  enemy.team ~= myHero.team and enemy.valid and enemy.pos:DistanceTo(myHero.pos) < 1500 then
	heroesCount = heroesCount + 1
        end
    	end
    	return heroesCount
end

function Rammus:Combo()
  	if self:GetValidEnemy(2000) == false then return end
  	if (not _G.SDK and not _G.GOS and not _G.EOWLoaded) then return end
  	local target = (_G.SDK and _G.SDK.TargetSelector:GetTarget(2000, _G.SDK.DAMAGE_TYPE_PHYSICAL)) or (_G.GOS and _G.GOS:GetTarget(2000,"AD")) or ( _G.EOWLoaded and EOW:GetTarget())

	if self:IsValidTarget(target,325) and not self:HasBuff(myHero, "PowerBall") and myHero.pos:DistanceTo(target.pos) < 125 and self.Menu.Ripper.Combo.W:Value() and self:Ready(_W) then
    	Control.CastSpell(HK_W)
    	end
  	if self:IsValidTarget(target,325) and not self:HasBuff(myHero, "PowerBall") and myHero.pos:DistanceTo(target.pos) < 325  and self.Menu.Ripper.Combo.E:Value() and self:Ready(_E) then
    	Control.CastSpell(HK_E,target)
    	end
  	if self:IsValidTarget(target,self.Menu.Ripper.Misc.RangeQ:Value()) and not self:HasBuff(myHero, "PowerBall") and myHero.pos:DistanceTo(target.pos) < self.Menu.Ripper.Misc.RangeQ:Value() and self.Menu.Ripper.Combo.Q:Value() and self:Ready(_Q) then
    	Control.CastSpell(HK_Q)
    	end
  	if self:IsValidTarget(target,R.range) and not self:HasBuff(myHero, "PowerBall") and myHero.pos:DistanceTo(target.pos) < R.range and self.Menu.Ripper.Combo.R:Value() and self:Ready(_R) then
			local level = myHero:GetSpellData(_R).level
			local Rdamage = CalcMagicalDamage(myHero, target, (({65, 130, 195})[level] + 0.3 * myHero.ap))
			if Rdamage >= (self:HpPred(target,1) + target.hpRegen * 2) /  self.Menu.Ripper.Combo.XR:Value() then
			Control.CastSpell(HK_R)
      	end
    	end
end

function Rammus:GetValidMinion(range)
    	for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 650 then
        return true
        end
    	end
    	return false
end

function Rammus:HpPred(unit, delay)
	if _G.GOS then
	hp =  GOS:HP_Pred(unit,delay)
	else
	hp = unit.health
	end
	return hp
	end

function Rammus:HasBuff(unit, buffname)
	for i = 0, unit.buffCount do
	local buff = unit:GetBuff(i)
	if buff.name == buffname and buff.count > 0 then 
	return true
	end
	end
	return false
	end	 
    		
function Rammus:JungleClear()
  	if self:GetValidMinion(E.range) == false then return end
  	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
    	if  minion.team == 300 then
      	if self:IsValidTarget(minion,325) and not self:HasBuff(myHero, "PowerBall") and myHero.mana/myHero.maxMana >= (self.Menu.Ripper.JungleClear.Mana:Value() / 100 ) and myHero.pos:DistanceTo(minion.pos) < 325  and self.Menu.Ripper.JungleClear.Q:Value() and self:Ready(_Q) then
	Control.CastSpell(HK_Q)
	break
	end
	if self:IsValidTarget(minion,325) and not self:HasBuff(myHero, "PowerBall") and myHero.mana/myHero.maxMana >= (self.Menu.Ripper.JungleClear.Mana:Value() / 100 ) and myHero.pos:DistanceTo(minion.pos) < 325 and self.Menu.Ripper.JungleClear.W:Value() and self:Ready(_W) then
	Control.CastSpell(HK_W)
	break
	end
	if self:IsValidTarget(minion,325) and not self:HasBuff(myHero, "PowerBall") and myHero.mana/myHero.maxMana >= (self.Menu.Ripper.JungleClear.Mana:Value() / 100 ) and myHero.pos:DistanceTo(minion.pos) < 325 and self.Menu.Ripper.JungleClear.E:Value() and self:Ready(_E) then
	Control.CastSpell(HK_E,minion.pos)
	break
	end
      	end
    	end
end

function Rammus:LaneClear()
  	if self:GetValidMinion(E.range) == false then return end
  	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
    	if  minion.team == 200 then
	if self:IsValidTarget(minion,325) and not self:HasBuff(myHero, "PowerBall") and myHero.mana/myHero.maxMana >= (self.Menu.Ripper.LaneClear.Mana:Value() / 100 ) and myHero.pos:DistanceTo(minion.pos) < 125 and self.Menu.Ripper.LaneClear.W:Value() and self:Ready(_W) then
	Control.CastSpell(HK_W)
	break
	end
      	end
    	end
end

function Rammus:Flee()
  	if self.Menu.Ripper.Flee.Q:Value() and not self:HasBuff(myHero, "PowerBall") and self:Ready(_Q)
    	then
    	Control.CastSpell(HK_Q)
    	end
end
  	
function Rammus:AutoR()
  	if self:GetValidEnemy(R.range) == false then return end
  	if (not _G.SDK and not _G.GOS and not _G.EOWLoaded) then return end
  	if self:Ready(_R) and self.Menu.Ripper.Misc.AutoR:Value() and not self:HasBuff(myHero, "PowerBall") then
    	if self:CountEnemys(R.range) >= self.Menu.Ripper.Misc.EAutoR:Value() then
      	Control.CastSpell(HK_R)
      	end
    	end
end

function Rammus:Harass()
  	if self:GetValidEnemy(325) == false then return end
  	if (not _G.SDK and not _G.GOS and not _G.EOWLoaded) then return end
  	local target = (_G.SDK and _G.SDK.TargetSelector:GetTarget(325, _G.SDK.DAMAGE_TYPE_PHYSICAL)) or (_G.GOS and _G.GOS:GetTarget(325,"AD")) or ( _G.EOWLoaded and EOW:GetTarget())
  	if self:IsValidTarget(target,325) and not self:HasBuff(myHero, "PowerBall") and myHero.pos:DistanceTo(target.pos) < 125 and self.Menu.Ripper.Harass.E:Value() and self:Ready(_E) then
    	Control.CastSpell(HK_W)
    	end
end

function Rammus:KS()
  	if self:GetValidEnemy(R.range) == false then return end
  	if (not _G.SDK and not _G.GOS and not _G.EOWLoaded) then return end
  	local target = (_G.SDK and _G.SDK.TargetSelector:GetTarget(R.range, _G.SDK.DAMAGE_TYPE_PHYSICAL)) or (_G.GOS and _G.GOS:GetTarget(R.range,"AD")) or ( _G.EOWLoaded and EOW:GetTarget())
	if self:IsValidTarget(target,R.range) and not self:HasBuff(myHero, "PowerBall") and myHero.pos:DistanceTo(target.pos) < R.range and self.Menu.Ripper.KS.R:Value() and self:Ready(_R) then
    	local level = myHero:GetSpellData(_R).level
    	local Rdamage = CalcMagicalDamage(myHero, target, (({65, 130, 195})[level] + 0.3 * myHero.ap))
	if Rdamage >= self:HpPred(target,1) + target.hpRegen * 2 then
  	Control.CastSpell(HK_R)
	end
	end
end

function Rammus:Draw()
	if myHero.dead then return end
	if self.Menu.Ripper.Drawings.Q:Value() then Draw.Circle(myHero.pos, self.Menu.Ripper.Misc.RangeQ:Value(), self.Menu.Ripper.Drawings.Width:Value(), self.Menu.Ripper.Drawings.Color:Value())
	end
	if self.Menu.Ripper.Drawings.R:Value() then Draw.Circle(myHero.pos, R.range, self.Menu.Ripper.Drawings.Width:Value(), self.Menu.Ripper.Drawings.Color:Value())	
	end	
end
  
function OnLoad()
    	if myHero.charName ~= "Rammus" then return end
	Rammus()
end
