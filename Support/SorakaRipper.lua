require 'DamageLib'
require 'Eternal Prediction'

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
        if m and m.team == team and not m.dead and m.pos:DistanceTo(pos, hero.pos) < range then
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

function IsRecalling()
    for K, Buff in pairs(GetBuffs(myHero)) do
        if Buff.name == "recall" and Buff.duration > 0 then
            return true
        end
    end
    return false
end

function HasBuff(unit, buffname)
	for i = 0, unit.buffCount do
	local buff = unit:GetBuff(i)
	if buff.name == buffname and buff.count > 0 then 
	return true
	end
	end
	return false
end

local function GetDistance(p1,p2)
return  math.sqrt(math.pow((p2.x - p1.x),2) + math.pow((p2.y - p1.y),2) + math.pow((p2.z - p1.z),2))
end

local function GetDistance2D(p1,p2)
return  math.sqrt(math.pow((p2.x - p1.x),2) + math.pow((p2.y - p1.y),2))
end

local _EnemyHeroes
function GetEnemyHeroes()
  if _EnemyHeroes then return _EnemyHeroes end
  for i = 1, Game.HeroCount() do
    local unit = Game.Hero(i)
    if unit.isEnemy then
	  if _EnemyHeroes == nil then _EnemyHeroes = {} end
      table.insert(_EnemyHeroes, unit)
    end
  end
  return {}
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

local function CastSpell(hotkey,slot,target,predmode)
	local data = { range = myHero:GetSpellData(slot).range, delay = myHero:GetSpellData(slot).delay, speed = myHero:GetSpellData(slot).speed}
	local spell = Prediction:SetSpell(data, predmode, true)
	local pred = spell:GetPrediction(target,myHero.pos)
	if pred and pred.hitChance >= Romanov.Pred.Chance:Value() then
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

class "Soraka"

function Soraka:__init()
	if _G.EOWLoaded then
        Orb = 1
    elseif _G.SDK and _G.SDK.Orbwalker then
        Orb = 2
    end
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
  	Callback.Add("Tick", function() self:Tick() end)
  	Callback.Add("Draw", function() self:Draw() end)
end

function Soraka:LoadSpells()
  	Q = { range = myHero:GetSpellData(_Q).range, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed, width = myHero:GetSpellData(_Q).width, radius = 235, icon = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/c/cd/Starcall.png" }
	W = { range = myHero:GetSpellData(_W).range, delay = myHero:GetSpellData(_W).delay, speed = myHero:GetSpellData(_W).speed, width = myHero:GetSpellData(_W).width, icon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/6/6f/Astral_Infusion.png" }
	E = { range = myHero:GetSpellData(_E).range, delay = myHero:GetSpellData(_E).delay, speed = myHero:GetSpellData(_E).speed, width = myHero:GetSpellData(_E).width, icon = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/e/e7/Equinox.png" }
	R = { range = myHero:GetSpellData(_R).range, delay = myHero:GetSpellData(_R).delay, speed = myHero:GetSpellData(_R).speed, width = myHero:GetSpellData(_R).width, icon = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/f/f3/Wish.png" }
end

function Soraka:LoadMenu()
	--------- Menu Principal --------------------------------------------------------------
  	TRS = MenuElement({type = MENU, id = "Menu", name = "The Ripper Series"})
	--------- Soraka --------------------------------------------------------------------
	--------- Menu Principal --------------------------------------------------------------
  	TRS:MenuElement({type = MENU, id = "Combo", name = "Combo"})
  	TRS.Combo:MenuElement({id = "Q", name = "Use [Q]", value = true, leftIcon = Q.icon})
  	TRS.Combo:MenuElement({id = "E", name = "Use [E]", value = true, leftIcon = E.icon})
	--------- Menu LaneClear ------------------------------------------------------------------------------------------------
  	TRS:MenuElement({type = MENU, id = "LaneClear", name = "Lane Clear"})
  	TRS.LaneClear:MenuElement({id = "Q", name = "Use [Q]", value = true, leftIcon = Q.icon})
    TRS.LaneClear:MenuElement({id = "HQ", name = "Minimum minions to hit by [Q]", value = 4, min = 1, max = 7})
    TRS.LaneClear:MenuElement({id = "Mana", name = "Min mana to Clear (%)", value = 40, min = 0, max = 100})
	--------- Menu JungleClear ------------------------------------------------------------------------------------------------
  	TRS:MenuElement({type = MENU, id = "JungleClear", name = "Jungle Clear"})
  	TRS.JungleClear:MenuElement({id = "Q", name = "Use [Q]", value = true, leftIcon = Q.icon})
    TRS.JungleClear:MenuElement({id = "Mana", name = "Min mana to Clear (%)", value = 40, min = 0, max = 100})
	--------- Menu Harass ---------------------------------------------------------------------
  	TRS:MenuElement({type = MENU, id = "Harass", name = "Harass"})
  	TRS.Harass:MenuElement({id = "Q", name = "Use [Q]", value = true, leftIcon = Q.icon})
  	TRS.Harass:MenuElement({id = "E", name = "Use [E]", value = true, leftIcon = E.icon})
    TRS.Harass:MenuElement({id = "Mana", name = "Min mana to Harass (%)", value = 40, min = 0, max = 100})
	--------- Menu Flee ----------------------------------------------------------------------------
  	TRS:MenuElement({type = MENU, id = "Flee", name = "Flee"})
  	TRS.Flee:MenuElement({id ="Q", name = "Use [Q]", value = true, leftIcon = Q.icon})
  	TRS.Flee:MenuElement({id ="E", name = "Use [E]", value = true, leftIcon = E.icon})
	--------- Menu Heal------------------------------------------------------------------------
  	TRS:MenuElement({type = MENU, id = "Heal", name = "Heal"})
  	TRS.Heal:MenuElement({id = "W", name = "Use [W]", value = true, leftIcon = W.icon})
  	TRS.Heal:MenuElement({id = "Health", name = "Min Soraka Health (%)", value = 45, min = 5, max = 100})
	DelayAction(function()
		for i = 1,Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.team == myHero.team and not hero.isMe then
				TRS.Heal:MenuElement({id = hero.networkID, name = hero.charName, value = true, leftIcon = "https://raw.githubusercontent.com/TheRipperGos/GoS/master/Sprites/"..hero.charName..".png"})
			end
		end
	end, 2)
	TRS.Heal:MenuElement({type = MENU, id = "HP", name = "HP settings"})
  	DelayAction(function()
		for i = 1,Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.team == myHero.team and not hero.isMe then
				TRS.Heal.HP:MenuElement({id = hero.networkID, name = hero.charName.." max HP (%)", value = 85, min = 0, max = 100})
			end
		end
	end, 2)
	--------- Menu ULT ----------------------------------------------------------------------------
  	TRS:MenuElement({type = MENU, id = "ULT", name = "Ultimate"})
  	TRS.ULT:MenuElement({id = "R", name = "Use [R]", value = true, leftIcon = R.Icon})
  	TRS.ULT:MenuElement({id = "Health", name = "Max Soraka Health (%)", value = 20, min = 0, max = 100})
	DelayAction(function()
		for i = 1,Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.team == myHero.team and not hero.isMe then
				TRS.ULT:MenuElement({id = hero.networkID, name = hero.charName, value = true, leftIcon = "https://raw.githubusercontent.com/TheRipperGos/GoS/master/Sprites/"..hero.charName..".png"})
			end
		end
	end, 2)
	TRS.ULT:MenuElement({type = MENU, id = "HP", name = "HP settings"})
  	DelayAction(function()
		for i = 1,Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.team == myHero.team and not hero.isMe then
				TRS.ULT.HP:MenuElement({id = hero.networkID, name = hero.charName.." max HP (%)", value = 15, min = 0, max = 100})
			end
		end
	end, 2)
	--------- Menu KS -----------------------------------------------------------------------------
  	TRS:MenuElement({type = MENU, id = "KS", name = "Killsteal"})
  	TRS.KS:MenuElement({id = "Q", name = "Use [Q]", value = true, leftIcon = Q.icon})
  	TRS.KS:MenuElement({id = "E", name = "Use [E]", value = true, leftIcon = E.icon})                   
	--------- Menu Misc -----------------------------------------------------------------------
  	TRS:MenuElement({type = MENU, id = "Misc", name = "Misc"})
    TRS.Misc:MenuElement({id = "CCE", name = "Auto [E] if enemy has CC", value = true})
  	TRS.Misc:MenuElement({id = "CancelE", name = "Auto [E] Interrupter", value = true})
	--------- Menu Drawings --------------------------------------------------------------------
  	TRS:MenuElement({type = MENU, id = "Drawings", name = "Drawings"})
  	TRS.Drawings:MenuElement({id = "Q", name = "Draw [Q] range", value = true, leftIcon = Q.icon})
  	TRS.Drawings:MenuElement({id = "E", name = "Draw [E] range", value = true, leftIcon = E.icon})
  	TRS.Drawings:MenuElement({id = "Width", name = "Width", value = 2, min = 1, max = 5, step = 1})
	TRS.Drawings:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 0, 0, 255)})
end

function Soraka:Tick()
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
	self:AutoR()
	self:SelfAutoR()
	self:KS()
	if Ready(_W) then
        self:Heal()
	end

	end
  	self:Misc()
end
	
function Soraka:Combo()
  	local target = GetTarget(925)
  	if not target then return end
    if myHero.pos:DistanceTo(target.pos) < 790 and TRS.Combo.Q:Value() and Ready(_Q) then
        CastSpell(HK_Q,_Q,target)
    end
    if myHero.pos:DistanceTo(target.pos) < 900  and TRS.Combo.E:Value() and Ready(_E) then
        CastSpell(HK_E,_E,target)
    end
end

function Soraka:Clear()
  	if TRS.LaneClear.Q:Value() == false then return end
  	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
      	if minion.team ~= myHero.team and myHero.pos:DistanceTo(minion.pos) < 800 and Ready(_Q) and myHero.mana/myHero.maxMana < TRS.LaneClear.Mana:Value() then
			if MinionsAround(minion.pos,235,200) >= TRS.LaneClear.HQ:Value() then
				CastSpell(HK_Q,_Q,minion.pos,TYPE_CIRCULAR)
				end
			end
		end
	end

function Soraka:Harass()
    if myHero.pos:DistanceTo(target.pos) < 800 and (myHero.mana/myHero.maxMana > TRS.Harass.Mana:Value() / 100) and TRS.Harass.Q:Value() and Ready(_Q) then
        CastSpell(HK_Q,_Q,target)
    end
    if myHero.pos:DistanceTo(target.pos) < 925 and (myHero.mana/myHero.maxMana > TRS.Harass.Mana:Value() / 100) and TRS.Harass.E:Value() and Ready(_E) then
        CastSpell(HK_E,_Q,target)
    end
end

function Soraka:Flee()
	local target = GetTarget(925)
  	if not target then return end
    if myHero.pos:DistanceTo(target.pos) < 800 and TRS.Flee.Q:Value() and Ready(_Q) then
        CastSpell(HK_Q,_Q,target)
    end
    if myHero.pos:DistanceTo(target.pos) < 925  and TRS.Flee.E:Value() and Ready(_E) then
        CastSpell(HK_E,_E,target)
    end
	for i,ally in pairs(GetAllyHeroes()) do
	if not ally.isMe then
	if HeroesAround(myHero.pos,550,100) > 0 then
  	if myHero.pos:DistanceTo(ally.pos) < 550 and HasBuff(myHero, "sorakaqregen") and Ready(_W) and (myHero.helth/myHero.maxHealth >= 60 / 100 ) then
    if	(self:CountEnemies(ally.pos,500) > 0) and not ally.isMe then
		Control.CastSpell(HK_W,ally)
    end
	end
    end
	end
	end
end

function Soraka:Heal()
  	if TRS.Heal.W:Value() == false then return end
		for i,ally in pairs(GetAllyHeroes()) do
		if myHero.pos:DistanceTo(ally.pos) < 550 then
		if not ally.isMe then
		for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.team == myHero.team and not hero.isMe then
		if TRS.Heal[hero.networkID]:Value() then
		if (ally.health/ally.maxHealth <= TRS.Heal.HP[hero.networkID]:Value() / 100) and not ally.isMe and (myHero.health/myHero.maxHealth >= TRS.Heal.Health:Value() / 100 ) and Ready(_W) and not IsRecalling() then
				Control.CastSpell(HK_W,ally)	
				return
		end
		end
		end
		end
		end
		end
		end
end

function Soraka:AutoR()
	local target = GetTarget(300000)
	if not target then return end
  	if TRS.ULT.R:Value() == false then return end
		for i,ally in pairs(GetAllyHeroes()) do
		if not ally.isMe then
		for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if hero.team == myHero.team and not hero.isMe then
		if TRS.ULT[hero.networkID]:Value() and Ready(_R) then
		if (ally.health/ally.maxHealth <= TRS.ULT.HP[hero.networkID]:Value() / 100) and not ally.isMe then
		if (HeroesAround(ally.pos,600,200) > 0) then
				Control.CastSpell(HK_R)	
				return
		end
		end
		end
		end
		end
		end
		end
		end

function Soraka:SelfAutoR()
    local target = GetTarget(450)
	if not target then return end
	if TRS.ULT.R:Value() == false then return end
		if (myHero.health/myHero.maxHealth <= TRS.ULT.Health:Value() / 100) and Ready(_R) and myHero.pos:DistanceTo(target.pos) < 425 then
			Control.CastSpell(HK_R)
			return
		end
end
  
function Soraka:KS()
	local target = GetTarget(925)
    if not target then return end 
  	if myHero.pos:DistanceTo(target.pos) < 925 and TRS.KS.E:Value() and Ready(_E) then
    	local Edamage = CalcMagicalDamage(myHero, target, (30 + 40 * myHero:GetSpellData(_E).level + 0.4 * myHero.ap))
	if Edamage > target.health then
		CastSpell(HK_E,_E,target)
	end
	end
	if myHero.pos:DistanceTo(target.pos) < 800 and TRS.KS.Q:Value() and Ready(_Q) then
    	local Qdamage = CalcMagicalDamage(myHero, target, (30 + 40 * myHero:GetSpellData(_E).level + 0.35 * myHero.ap))
	if 	Qdamage > target.health then
  	CastSpell(HK_Q,_Q,target)
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
    local target = GetTarget(925)
  	if not target then return end
    if Ready(_E) and self:IsChannelling(enemy) and TRS.Misc.CancelE:Value() then
          CastSpell(HK_E,_E,target)
    end
	if Ready(_E) and self:HasCC() and TRS.Misc.CCE:Value() then
          CastSpell(HK_E,_E,target)
    end
end

function Soraka:Draw()
	if myHero.dead then return end
	if TRS.Drawings.Q:Value() then Draw.Circle(myHero.pos, 800, TRS.Drawings.Width:Value(), TRS.Drawings.Color:Value())
	end
	if TRS.Drawings.E:Value() then Draw.Circle(myHero.pos, 925, TRS.Drawings.Width:Value(), TRS.Drawings.Color:Value())	
	end	
end

function Soraka:HasCC(unit)	
	for i = 0, unit.buffCount do
	local buff = myHero:GetBuff(i);
	if buff.count > 0 then
		if ((buff.type == 5) or (buff.type == 8) or (buff.type == 9) or (buff.type == 10) or (buff.type == 11) or (buff.type == 21) or (buff.type == 22) or (buff.type == 24) or (buff.type == 28) or (buff.type == 29)	or (buff.type == 31)) then
		return true
		end
		end
		end
	return false
end
    
function OnLoad()
    if myHero.charName ~= "Soraka" then return end
	Soraka()
end
