if myHero.charName ~= "Talon" then return end

require = 'DamageLib'

local function Ready (spell)
	return Game.CanUseSpell(spell) == 0 
end

local function ValidTarget(obj,range)
	range = range and range or math.huge
	return obj ~= nil and obj.valid and obj.visible and not obj.dead and obj.isTargetable and not obj.isImmortal and obj.distance <= range
end

local function GetEnemy(range)
  	for i = 1,Game.HeroCount() do
    	local enemy = Game.Hero(i)
    	if  enemy.team ~= myHero.team and enemy.valid and enemy.pos:DistanceTo(myHero.pos) > 1 then
    		return true
    	end
    end
  	return false
end

local function ValidTarget(unit,range,from)
	from = from or myHero.pos
	range = range or math.huge
	return unit and unit.valid and not unit.dead and unit.visible and unit.isTargetable
end

local function HpPred(unit, delay)
	if _G.GOS then
	hp =  GOS:HP_Pred(unit,delay)
	else
	hp = unit.health
	end
	return hp
end

local Icon = { 	C = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/f/f9/TalonSquare.png",
				Q = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/6/6b/Noxian_Diplomacy.png",
				W = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/b/bd/Rake.png",
				R = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/6/66/Shadow_Assault.png" }

local Talon = MenuElement({type = MENU, id = "Talon", name = "Ripper Talon", leftIcon = Icon.C})
Talon:MenuElement({type = MENU, id = "Combo", name = "Combo"})
Talon.Combo:MenuElement({id = "UseQ", name = "[Q] Noxian Diplomacy", value = true, leftIcon = Icon.Q})
Talon.Combo:MenuElement({id = "UseW", name = "[W] Rake", value = true, leftIcon = Icon.W})
Talon.Combo:MenuElement({id = "UseR", name = "[R] Shadow Assault", value = true, leftIcon = Icon.R})

Talon:MenuElement({type = MENU, id = "Harass", name = "Harass"})
Talon.Harass:MenuElement({id = "UseW", name = "[W] Rake", value = true, leftIcon = Icon.W})
Talon.Harass:MenuElement({id = "Mana", name = "Min Mana to Harass(%)", value = 65, min = 0, max = 100})

Talon:MenuElement({type = MENU, id = "Clear", name = "Lane/Jungle Clear"})
Talon.Clear:MenuElement({id = "Usage", name = "Spells Usage", key = string.byte("A"),toggle = true})
Talon.Clear:MenuElement({id = "UseQ", name = "[Q] Noxian Diplomacy", value = true, leftIcon = Icon.Q})
Talon.Clear:MenuElement({id = "UseW", name = "[W] Rake", value = true, leftIcon = Icon.W})
Talon.Clear:MenuElement({id = "WHit", name = "[W] if x minions", value = 3, min = 1, max = 7})
Talon.Clear:MenuElement({id = "Mana", name = "Min Mana to Clear(%)", value = 50, min = 0, max = 100})

Talon:MenuElement({type = MENU, id = "Lasthit", name = "Lasthit"})
Talon.Lasthit:MenuElement({id = "UseQ", name = "[Q] Noxian Diplomacy", value = true, leftIcon = Icon.Q})
Talon.Lasthit:MenuElement({id = "Mana", name = "Min Mana to Lasthit (%)", value = 65, min = 0, max = 100})

Talon:MenuElement({type = MENU, id = "Killsteal", name = "Killsteal"})
Talon.Killsteal:MenuElement({id = "UseR", name = "[R] Shadow Assault", value = true, leftIcon = Icon.R})

Talon:MenuElement({type = MENU, id = "Drawing", name = "Drawings"})
Talon.Drawing:MenuElement({id = "DrawQ", name = "Draw [Q] Range", value = true, leftIcon = Icon.Q})
Talon.Drawing:MenuElement({id = "ColorQ", name = "Color", color = Draw.Color(255, 0, 0, 255)})
Talon.Drawing:MenuElement({id = "DrawW", name = "Draw [W] Range", value = true, leftIcon = Icon.W})
Talon.Drawing:MenuElement({id = "ColorW", name = "Color", color = Draw.Color(255, 0, 0, 255)})
Talon.Drawing:MenuElement({id = "DrawR", name = "Draw [R] Range", value = true, leftIcon = Icon.R})
Talon.Drawing:MenuElement({id = "ColorR", name = "Color", color = Draw.Color(255, 0, 0, 255)})
Talon.Drawing:MenuElement({id = "DrawStatus", name = "Draw Clear Spell Status", value = true})

local Q = { delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed, width = myHero:GetSpellData(_Q).width } 
local W = { delay = myHero:GetSpellData(_W).delay, speed = myHero:GetSpellData(_W).speed, width = myHero:GetSpellData(_W).width } 
local R = { delay = myHero:GetSpellData(_R).delay, speed = myHero:GetSpellData(_R).speed, width = myHero:GetSpellData(_R).width }

function Combo()
	if GetEnemy(650) == false then return end
	local target = (_G.SDK and _G.SDK.TargetSelector:GetTarget(650, _G.SDK.DAMAGE_TYPE_PHYSICAL)) or (_G.GOS and _G.GOS:GetTarget(650,"AD"))
	if Ready(_R) and Talon.Combo.UseR:Value() and ValidTarget(target,550) then
		Control.CastSpell(HK_R)
	end
	if Ready(_Q) and Talon.Combo.UseQ:Value() and ValidTarget(target,550) then
		Control.CastSpell(HK_Q,target)
	end
	if Ready(_W) and Talon.Combo.UseW:Value() and ValidTarget(target,650) then
		Control.CastSpell(HK_W,target:GetPrediction(W.speed,W.delay))
	end
end

function Harass()
	if GetEnemy(600) == false then return end
	local target = (_G.SDK and _G.SDK.TargetSelector:GetTarget(600, _G.SDK.DAMAGE_TYPE_PHYSICAL)) or (_G.GOS and _G.GOS:GetTarget(600,"AD"))
	if Ready(_W) and Talon.Harass.UseW:Value() and ValidTarget(target,600) and (myHero.mana/myHero.maxMana >= Talon.Harass.Mana:Value() / 100 ) then
		Control.CastSpell(HK_W,target:GetPrediction(W.speed,W.delay))
	end
end

function Lasthit()
	local level = myHero:GetSpellData(_Q).level
  	for i = 1, Game.MinionCount() do
		local minion = Game.Minion(i)
		if  minion.team == 200 then
			local Qdamage = (({60, 85, 110, 135, 160})[level] + myHero.bonusDamage)
			if ValidTarget(minion,550) and myHero.pos:DistanceTo(minion.pos) < 550 and Talon.Lasthit.UseQ:Value() and (myHero.mana/myHero.maxMana >= Talon.Lasthit.Mana:Value() / 100 ) and minion.isEnemy then
				if Qdamage >= HpPred(minion, 0.5) and Ready(_Q) then
					Control.CastSpell(HK_Q,minion.pos)
				end
			end
			local QMelee = (({60, 85, 110, 135, 160})[level] + myHero.totalDamage)
			if ValidTarget(minion,170) and myHero.pos:DistanceTo(minion.pos) < 170 and Talon.Lasthit.UseQ:Value() and (myHero.mana/myHero.maxMana >= Talon.Lasthit.Mana:Value() / 100 ) and minion.isEnemy then
				if QMelee >= HpPred(minion, 0.5) and Ready(_Q) then
					Control.CastSpell(HK_Q,minion.pos)
				end
			end
      	end
	end
end

function CountEnemyMinions(range)
	local minionsCount = 0
    for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 650 then
            minionsCount = minionsCount + 1
        end
    end
    return minionsCount
end

function Clear()
	if Talon.Clear.Usage:Value() == false then return end
	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
		if  minion.team == 200 then
			if ValidTarget(minion,550) and Ready(_Q) and myHero.pos:DistanceTo(minion.pos) < 550 and Talon.Clear.UseQ:Value() and (myHero.mana/myHero.maxMana >= Talon.Clear.Mana:Value() / 100 ) and minion.isEnemy then
				Control.CastSpell(HK_Q,minion.pos)
			end
			if ValidTarget(minion,650) and Ready(_W) and myHero.pos:DistanceTo(minion.pos) < 650 and Talon.Clear.UseW:Value() and (myHero.mana/myHero.maxMana >= Talon.Clear.Mana:Value() / 100 ) and minion.isEnemy then
				if CountEnemyMinions(650) >= Talon.Clear.WHit:Value() then
					Control.CastSpell(HK_W,minion.pos)
				end
			end
		end
		if  minion.team == 300 then
			if ValidTarget(minion,550) and Ready(_Q) and myHero.pos:DistanceTo(minion.pos) < 550 and Talon.Clear.UseQ:Value() and (myHero.mana/myHero.maxMana >= Talon.Clear.Mana:Value() / 100 ) and minion.isEnemy then
				Control.CastSpell(HK_Q,minion.pos)
			end
			if ValidTarget(minion,650) and Ready(_W) and myHero.pos:DistanceTo(minion.pos) < 650 and Talon.Clear.UseW:Value() and (myHero.mana/myHero.maxMana >= Talon.Clear.Mana:Value() / 100 ) and minion.isEnemy then
				Control.CastSpell(HK_W,minion.pos)
			end
		end
	end
end

function Killsteal()
	if myHero:GetSpellData(_R).level == 0 then return end
	if GetEnemy(550) == false then return end
  	if (not _G.SDK and not _G.GOS and not _G.EOWLoaded) then return end
  	local target = (_G.SDK and _G.SDK.TargetSelector:GetTarget(550, _G.SDK.DAMAGE_TYPE_PHYSICAL)) or (_G.GOS and _G.GOS:GetTarget(550,"AD"))
	if ValidTarget(target,550) and Talon.Killsteal.UseR:Value() then
    	local level = myHero:GetSpellData(_R).level
    	local Rdamage = CalcPhysicalDamage(myHero, target, (({80, 120, 160})[level] + 0.8 * myHero.totalDamage))
		if 	Rdamage >= HpPred(target,1) + target.hpRegen * 2 then
			Control.CastSpell(HK_R)
		end
    end
end

Callback.Add('Tick',function()
	if (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO]) or (_G.GOS and _G.GOS:GetMode() == "Combo") then
		Combo()
	elseif 	(_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS]) or (_G.GOS and _G.GOS:GetMode() == "Harass") then
		Harass()
	elseif (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR]) or (_G.GOS and _G.GOS:GetMode() == "Clear") then
		Clear()
	elseif (_G.SDK and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT]) or (_G.GOS and _G.GOS:GetMode() == "Lasthit") then
		Lasthit()
	end
		Killsteal()
end)

Callback.Add("Draw", function()
	if myHero.dead then return end
	if Talon.Drawing.DrawQ:Value() and Ready(_Q) then Draw.Circle(myHero.pos, 550, 3, Talon.Drawing.ColorQ:Value()) end
	if Talon.Drawing.DrawW:Value() and Ready(_W) then Draw.Circle(myHero.pos, 650, 3, Talon.Drawing.ColorW:Value()) end
	if Talon.Drawing.DrawR:Value() and Ready(_R) then Draw.Circle(myHero.pos, 550, 3, Talon.Drawing.ColorR:Value()) end
	if Talon.Drawing.DrawStatus:Value() then
	       		local textPos = myHero.pos:To2D()
				if Talon.Clear.Usage:Value() == true then
					Draw.Text("Spell Clear: On", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 
				elseif Talon.Clear.Usage:Value() == false then
					Draw.Text("Spell Clear: Off", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 
				end
			end 
end)

Callback.Add("Load",function() end)
