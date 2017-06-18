class "XinZhao" 

function XinZhao:__init() 
	self:LoadSpells()
  	self:LoadMenu() 
  	Callback.Add("Tick", function() self:Tick() end)
  	Callback.Add("Draw", function() self:Draw() end) 
end

function XinZhao:LoadSpells() 
  	Q = { range = myHero:GetSpellData(_Q).range, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed, width = myHero:GetSpellData(_Q).width }
	W = { range = myHero:GetSpellData(_W).range, delay = myHero:GetSpellData(_W).delay, speed = myHero:GetSpellData(_W).speed, width = myHero:GetSpellData(_W).width }
	E = { range = myHero:GetSpellData(_E).range, delay = myHero:GetSpellData(_E).delay, speed = myHero:GetSpellData(_E).speed, width = myHero:GetSpellData(_E).width }
	R = { range = myHero:GetSpellData(_R).range, delay = myHero:GetSpellData(_R).delay, speed = myHero:GetSpellData(_R).speed, width = myHero:GetSpellData(_R).width }
end

function XinZhao:LoadMenu()
  	local Icons = { C = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/6/63/Xin_ZhaoSquare.png",
    			Q = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/0/07/Three_Talon_Strike.png",
    			W = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/0/03/Battle_Cry.png",
    			E = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/d/d7/Audacious_Charge.png",
                    	R = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/6/69/Crescent_Sweep.png" }
	-- Main Menu -------------------------------------------------------------------------------------------------------------------
  	self.Menu = MenuElement({type = MENU, id = "Menu", name = "The Ripper Series", leftIcon = Icons.C})
	-- XinZhao ---------------------------------------------------------------------------------------------------------------------
	self.Menu:MenuElement({type = MENU, id = "Ripper", name = "Xin Zhao The Ripper", leftIcon = Icons.C })
	-- Combo -----------------------------------------------------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "Combo", name = "Combo"})
  	self.Menu.Ripper.Combo:MenuElement({id = "Q", name = "Use Q", value = true, leftIcon = Icons.Q})
  	self.Menu.Ripper.Combo:MenuElement({id = "W", name = "Use W", value = true, leftIcon = Icons.W})
  	self.Menu.Ripper.Combo:MenuElement({id = "E", name = "Use E", value = true, leftIcon = Icons.E})
  	self.Menu.Ripper.Combo:MenuElement({id = "R", name = "Use R", value = true, leftIcon = Icons.R})
	self.Menu.Ripper.Combo:MenuElement({id = "ER", name = "Min enemies to use R", value = 2, min = 1, max = 5})
	-- LastHit ---------------------------------------------------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "LastHit", name = "Last Hit"})
  	self.Menu.Ripper.LastHit:MenuElement({id = "Q", name = "Use Q", value = true, leftIcon = Icons.Q})
  	self.Menu.Ripper.LastHit:MenuElement({id = "E", name = "Use E", value = true, leftIcon = Icons.E})
	self.Menu.Ripper.LastHit:MenuElement({id = "Mana", name = "Min mana to Clear (%)", value = 40, min = 0, max = 100})
	-- LaneClear -------------------------------------------------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "LaneClear", name = "Lane Clear"})
  	self.Menu.Ripper.LaneClear:MenuElement({id = "Q", name = "Use Q", value = true, leftIcon = Icons.Q})
  	self.Menu.Ripper.LaneClear:MenuElement({id = "W", name = "Use W", value = true, leftIcon = Icons.W})
  	self.Menu.Ripper.LaneClear:MenuElement({id = "E", name = "Use E", value = true, leftIcon = Icons.E})
	self.Menu.Ripper.LaneClear:MenuElement({id = "Mana", name = "Min mana to Clear (%)", value = 40, min = 0, max = 100})
	-- JungleClear -----------------------------------------------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "JungleClear", name = "Jungle Clear"})
  	self.Menu.Ripper.JungleClear:MenuElement({id = "Q", name = "Use Q", value = true, leftIcon = Icons.Q})
  	self.Menu.Ripper.JungleClear:MenuElement({id = "W", name = "Use W", value = true, leftIcon = Icons.W})
  	self.Menu.Ripper.JungleClear:MenuElement({id = "E", name = "Use E", value = true, leftIcon = Icons.E})
	self.Menu.Ripper.JungleClear:MenuElement({id = "Mana", name = "Min mana to Clear (%)", value = 40, min = 0, max = 100})
	-- Flee ------------------------------------------------------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "Flee", name = "Flee"})
  	self.Menu.Ripper.Flee:MenuElement({id ="R", name = "Use R", value = true, leftIcon = Icons.R})
  	self.Menu.Ripper.Flee:MenuElement({id = "ER", name = "Min enemies to use R", value = 3, min = 1, max = 5})
	-- Killsteal -------------------------------------------------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "KS", name = "Killsteal"})
  	self.Menu.Ripper.KS:MenuElement({id = "E", name = "Use E", value = true, leftIcon = Icons.E})
  	self.Menu.Ripper.KS:MenuElement({id = "R", name = "Use R", value = true, leftIcon = Icons.R})
	-- Harass ----------------------------------------------------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "Harass", name = "Harass"})
  	self.Menu.Ripper.Harass:MenuElement({id = "E", name = "Use E", value = true, leftIcon = Icons.E})
	self.Menu.Ripper.Harass:MenuElement({id = "Mana", name = "Min mana to Harass (%)", value = 40, min = 0, max = 100})
	-- Misc ------------------------------------------------------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "Misc", name = "Misc"})
  	self.Menu.Ripper.Misc:MenuElement({id = "AutoR", name = "Auto R", value = false, leftIcon = Icons.R})
	self.Menu.Ripper.Misc:MenuElement({id = "EAutoR", name = "Enemies to auto R", value = 4, min = 1, max = 5})
  	self.Menu.Ripper.Misc:MenuElement({id = "Key", name = "Auto R Key", key = string.byte(" ")})
	-- Drawings --------------------------------------------------------------------------------------------------------------------
  	self.Menu.Ripper:MenuElement({type = MENU, id = "Drawings", name = "Drawings"})
  	self.Menu.Ripper.Drawings:MenuElement({id = "E", name = "Draw E range", value = true})
  	self.Menu.Ripper.Drawings:MenuElement({id = "R", name = "Draw R range", value = true})
  	self.Menu.Ripper.Drawings:MenuElement({id = "Width", name = "Width", value = 3, min = 1, max = 5, step = 1})
	self.Menu.Ripper.Drawings:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 0, 0, 255)})
end

function XinZhao:Tick()
  	local Combo = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO]) or (_G.GOS and _G.GOS:GetMode() == "Combo") or (_G.EOWLoaded and EOW:Mode() == "Combo")
  	local LastHit = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT]) or (_G.GOS and _G.GOS:GetMode() == "Lasthit") or (_G.EOWLoaded and EOW:Mode() == "LastHit")
  	local Clear = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR]) or (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR]) or (_G.GOS and _G.GOS:GetMode() == "Clear") or (_G.EOWLoaded and EOW:Mode() == "LaneClear")
  	local Harass = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS]) or (_G.GOS and _G.GOS:GetMode() == "Harass") or (_G.EOWLoaded and EOW:Mode() == "Harass")
  	local Flee = (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE]) or (_G.GOS and _G.GOS:GetMode() == "Flee") or (_G.EOWLoaded and EOW:Mode() == "Flee")
  	if Combo then
    	self:Combo()
    	elseif LastHit then
    	self:LastHitQ()
    	self:LastHitE()
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

function XinZhao:GetValidEnemy(range)
  	for i = 1,Game.HeroCount() do
    	local enemy = Game.Hero(i)
    	if  enemy.team ~= myHero.team and enemy.valid and enemy.pos:DistanceTo(myHero.pos) < 650 then
    	return true
    	end
    	end
  	return false
end

function XinZhao:IsValidTarget(unit,range) 
	return unit ~= nil and unit.valid and unit.visible and not unit.dead and unit.isTargetable and not unit.isImmortal and unit.pos:DistanceTo(myHero.pos) <= 650 
end

function XinZhao:Ready (spell)
	return Game.CanUseSpell(spell) == 0 
end

function XinZhao:CountEnemys(range)
	local heroesCount = 0
    	for i = 1,Game.HeroCount() do
        local enemy = Game.Hero(i)
        if  enemy.team ~= myHero.team and enemy.valid and enemy.pos:DistanceTo(myHero.pos) < 650 then
	heroesCount = heroesCount + 1
        end
    	end
    	return heroesCount
end

function XinZhao:Combo()
  	if self:GetValidEnemy(650) == false then return end
  	if (not _G.SDK and not _G.GOS and not _G.EOWLoaded) then return end
  	local target = (_G.SDK and _G.SDK.TargetSelector:GetTarget(650, _G.SDK.DAMAGE_TYPE_PHYSICAL)) or (_G.GOS and _G.GOS:GetTarget(650,"AD")) or ( _G.EOWLoaded and EOW:GetTarget())

	if self:IsValidTarget(target,125) and myHero.pos:DistanceTo(target.pos) < 125 and self.Menu.Ripper.Combo.W:Value() and self:Ready(_W) then
    	Control.CastSpell(HK_W)
    	end
  	if self:IsValidTarget(target,650) and myHero.pos:DistanceTo(target.pos) < 650  and self.Menu.Ripper.Combo.E:Value() and self:Ready(_E) then
    	Control.CastSpell(HK_E,target)
    	end
  	if self:IsValidTarget(target,125) and myHero.pos:DistanceTo(target.pos) < 125 and self.Menu.Ripper.Combo.Q:Value() and self:Ready(_Q) then
    	Control.CastSpell(HK_Q)
    	end
  	if self:IsValidTarget(target,R.range) and myHero.pos:DistanceTo(target.pos) < R.range and self.Menu.Ripper.Combo.R:Value() and self:Ready(_R) then
    	if self:CountEnemys(R.range) >= self.Menu.Ripper.Combo.ER:Value() then
    	Control.CastSpell(HK_R)
      	end
    	end
end

function XinZhao:GetValidMinion(range)
    	for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 650 then
        return true
        end
    	end
    	return false
end

function XinZhao:HpPred(unit, delay)
	if _G.GOS then
	hp =  GOS:HP_Pred(unit,delay)
	else
	hp = unit.health
	end
	return hp
	end

function XinZhao:HasBuff(unit, buffname)
	for i = 0, unit.buffCount do
	local buff = unit:GetBuff(i)
	if buff.name == buffname and buff.count > 0 then 
	return true
	end
	end
	return false
	end

function XinZhao:LastHitQ()
  	if self.Menu.Ripper.LastHit.Q:Value() == false then return end
  	local level = myHero:GetSpellData(_Q).level
	if level == nil or level == 0 then return end
  	if self:GetValidMinion(myHero.range) == false then return end
  	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
    	local Qdamage = (({15, 30, 45, 60, 75})[level] + 0.2 * myHero.totalDamage)
    	if self:IsValidTarget(minion,125) and myHero.pos:DistanceTo(minion.pos) < 125 and myHero.mana/myHero.maxMana >= (self.Menu.Ripper.LastHit.Mana:Value() / 100 ) and minion.isEnemy then
      	if Qdamage >= self:HpPred(minion, 0.5) and self:Ready(_Q) then
        Control.CastSpell(HK_Q)
        elseif Qdamage >= minion.health and self:HasBuff(myHero, "XenZhaoComboTarget") then
        Control.SetCursorPos(minion.pos)
        end
      	end
    	end
end  	

function XinZhao:LastHitE()
  	if self.Menu.Ripper.LastHit.E:Value() == false then return end
  	local level = myHero:GetSpellData(_E).level
	if level == nil or level == 0 then return end
  	if self:GetValidMinion(myHero.range) == false then return end
  	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
    	local Edamage = (({70, 110, 150, 190, 230})[level] + 0.6 * myHero.ap)
    	if self:IsValidTarget(minion,925) and myHero.mana/myHero.maxMana >= (self.Menu.Ripper.LastHit.Mana:Value() / 100 ) and minion.isEnemy then
      	if Edamage >= minion.health and Edamage >= self:HpPred(minion, 0.5) and self:Ready(_E) then
        Control.CastSpell(HK_E,minion.pos)
        end
      	end
    	end
end  
    		
function XinZhao:JungleClear()
  	if self:GetValidMinion(E.range) == false then return end
  	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
    	if  minion.team == 300 then
      	if self:IsValidTarget(minion,125) and myHero.mana/myHero.maxMana >= (self.Menu.Ripper.JungleClear.Mana:Value() / 100 ) and myHero.pos:DistanceTo(minion.pos) < 125  and self.Menu.Ripper.JungleClear.Q:Value() and self:Ready(_Q) then
	Control.CastSpell(HK_Q)
	break
	end
	if self:IsValidTarget(minion,125) and myHero.mana/myHero.maxMana >= (self.Menu.Ripper.JungleClear.Mana:Value() / 100 ) and myHero.pos:DistanceTo(minion.pos) < 125 and self.Menu.Ripper.JungleClear.W:Value() and self:Ready(_W) then
	Control.CastSpell(HK_W)
	break
	end
	if self:IsValidTarget(minion,650) and myHero.mana/myHero.maxMana >= (self.Menu.Ripper.JungleClear.Mana:Value() / 100 ) and myHero.pos:DistanceTo(minion.pos) < 650 and self.Menu.Ripper.JungleClear.E:Value() and self:Ready(_E) then
	Control.CastSpell(HK_E,minion.pos)
	break
	end
      	end
    	end
end

function XinZhao:LaneClear()
  	if self:GetValidMinion(E.range) == false then return end
  	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
    	if  minion.team == 200 then
      	if self:IsValidTarget(minion,125) and myHero.mana/myHero.maxMana >= (self.Menu.Ripper.LaneClear.Mana:Value() / 100 ) and myHero.pos:DistanceTo(minion.pos) < 125 and self.Menu.Ripper.LaneClear.Q:Value() and self:Ready(_Q) then
	Control.CastSpell(HK_Q)
	break
	end
	if self:IsValidTarget(minion,125) and myHero.mana/myHero.maxMana >= (self.Menu.Ripper.LaneClear.Mana:Value() / 100 ) and myHero.pos:DistanceTo(minion.pos) < 125 and self.Menu.Ripper.LaneClear.W:Value() and self:Ready(_W) then
	Control.CastSpell(HK_W)
	break
	end
	if self:IsValidTarget(minion,650) and myHero.mana/myHero.maxMana >= (self.Menu.Ripper.LaneClear.Mana:Value() / 100 ) and myHero.pos:DistanceTo(minion.pos) < 650 and self.Menu.Ripper.LaneClear.E:Value() and self:Ready(_E) then
	Control.CastSpell(HK_E,minion.pos)
	break
	end
      	end
    	end
end

function XinZhao:Flee()
  	if self.Menu.Ripper.Flee.R:Value() and self:Ready(_R)
    	then
    	if self:CountEnemys(R.range) >= self.Menu.Ripper.Flee.ER:Value() then
    	Control.CastSpell(HK_R)
    	end
    	end
end
  	
function XinZhao:AutoR()
  	if self:GetValidEnemy(R.range) == false then return end
  	if (not _G.SDK and not _G.GOS and not _G.EOWLoaded) then return end
  	if self:Ready(_R) and self.Menu.Ripper.Misc.AutoR:Value() then
    	if self:CountEnemys(R.range) >= self.Menu.Ripper.Misc.EAutoR:Value() then
      	Control.CastSpell(HK_R)
      	end
    	end
end

function XinZhao:Harass()
  	if self:GetValidEnemy(650) == false then return end
  	if (not _G.SDK and not _G.GOS and not _G.EOWLoaded) then return end
  	local target = (_G.SDK and _G.SDK.TargetSelector:GetTarget(650, _G.SDK.DAMAGE_TYPE_PHYSICAL)) or (_G.GOS and _G.GOS:GetTarget(650,"AD")) or ( _G.EOWLoaded and EOW:GetTarget())
  	if self:IsValidTarget(target,650) and myHero.pos:DistanceTo(target.pos) < 650 and self.Menu.Ripper.Harass.E:Value() and self:Ready(_E) then
    	Control.CastSpell(HK_E,target)
    	end
end

function XinZhao:KS()
  	if self:GetValidEnemy(650) == false then return end
  	if (not _G.SDK and not _G.GOS and not _G.EOWLoaded) then return end
  	local target = (_G.SDK and _G.SDK.TargetSelector:GetTarget(650, _G.SDK.DAMAGE_TYPE_PHYSICAL)) or (_G.GOS and _G.GOS:GetTarget(650,"AD")) or ( _G.EOWLoaded and EOW:GetTarget())
  	if self:IsValidTarget(target,650) and myHero.pos:DistanceTo(target.pos) < 650 and self.Menu.Ripper.KS.E:Value() and self:Ready(_E) then
    	local level = myHero:GetSpellData(_E).level
    	local Edamage = CalcMagicalDamage(myHero, target, (({70, 110, 150, 190, 230})[level] + 0.6 * myHero.ap))
	if Edamage >= self:HpPred(target,1) + target.hpRegen * 2 then
  	Control.CastSpell(HK_E,target)
	end
	end
	if self:IsValidTarget(target,R.range) and myHero.pos:DistanceTo(target.pos) < R.range and self.Menu.Ripper.KS.R:Value() and self:Ready(_R) then
    	local level = myHero:GetSpellData(_R).level
    	local Rdamage = CalcMagicalDamage(myHero, target, (({150, 250, 350})[level] + (0.7 * myHero.ap)))
	if Rdamage >= self:HpPred(target,1) + target.hpRegen * 2 then
  	Control.CastSpell(HK_R)
	end
	end
end

function XinZhao:Draw()
	if myHero.dead then return end
	if self.Menu.Ripper.Drawings.E:Value() then Draw.Circle(myHero.pos, 650, self.Menu.Ripper.Drawings.Width:Value(), self.Menu.Ripper.Drawings.Color:Value())
	end
	if self.Menu.Ripper.Drawings.R:Value() then Draw.Circle(myHero.pos, R.range, self.Menu.Ripper.Drawings.Width:Value(), self.Menu.Ripper.Drawings.Color:Value())	
	end	
end
  
function OnLoad()
    	if myHero.charName ~= "XinZhao" then return end
	XinZhao()
end
