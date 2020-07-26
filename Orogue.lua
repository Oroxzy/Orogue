
MB_isCasting=false
MB_isChanneling=false

UFIDRUIDMANA = 0;
DRUIDMAXMANA = 0;

HASTECHARGES = 0;

local function Print(msg) 
    if (not DEFAULT_CHAT_FRAME) then
        return;
    end
    DEFAULT_CHAT_FRAME:AddMessage(msg);
end

local function Debug(msg) 
    if (Fury_Configuration["Debug"]) then
        if (not DEFAULT_CHAT_FRAME) then
            return;
        end
        DEFAULT_CHAT_FRAME:AddMessage(msg);
    end
end

function PrintEffects()
    local id = 1;
    if (UnitBuff("target", id)) then
        Print("Buffs:");
        while (UnitBuff("target", id)) do
            Print(UnitBuff("target", id));
            id = id + 1;
        end
        id = 1;
    end
    if (UnitDebuff("target", id)) then
        Print("Debuffs:");
        while (UnitDebuff("target", id)) do
            Print(UnitDebuff("target", id));
            id = id + 1;
        end
    end
end

function ActiveStance()
    --Detect the active stance
    for i = 1, 3 do
        local _, _, active = GetShapeshiftFormInfo(i);
        if (active) then
            return i;
        end
    end
    return nil;
end

function Weapon()
    --Detect if a suitable weapon (not a skinning knife/mining pick and not broken) is present
    if (GetInventoryItemLink("player", 16)) then
        local _, _, itemCode = strfind(GetInventoryItemLink("player", 16), "(%d+):");
        local itemName, itemLink, _, _, itemType = GetItemInfo(itemCode);
        if (itemLink ~= "item:7005:0:0:0" and itemLink ~= "item:2901:0:0:0" and not GetInventoryItemBroken("player", 16)) then
            return true;
        end
    end
    return nil;
end

function Shield()
    --Detect if a shield is present
    if (GetInventoryItemLink("player", 17)) then
        local _, _, itemCode = strfind(GetInventoryItemLink("player", 17), "(%d+):")
        local _, _, _, _, _, itemType = GetItemInfo(itemCode)
        if (itemType == ITEM_SHIELDS_OROGUE and not GetInventoryItemBroken("player", 17)) then
            return true;
        end
    end
    return nil;
end

function HamstringCost()
    --Calculate the cost of Hamstring based on gear
    local i = 0;
    if (GetInventoryItemLink("player", 10)) then
        local _, _, itemCode = strfind(GetInventoryItemLink("player", 10), "(%d+):")
        local itemName = GetItemInfo(itemCode)
        if (itemName == ITEM_GAUNTLETS1_OROGUE or itemName == ITEM_GAUNTLETS2_OROGUE or itemName == ITEM_GAUNTLETS3_OROGUE or itemName == ITEM_GAUNTLETS4_OROGUE) then
            i = 3;
        end
    end
    return (10 - i);
end

function AntiStealthDebuff()
    --Detect anti-stealth debuffs
    --Rend, Deep Wounds, Serpent Sting, Immolate, Curse of Agony , Garrote, Rupture, Deadly Poison, Fireball, Ignite, Pyroblast, Corruption, Siphon Life, Faerie Fire, Moonfire, Rake, Rip, Pounce, Insect Swarm, Holy Fire, Wyvern Sting, Devouring Plague
    if (HasDebuff("target", "Ability_Gouge") or HasDebuff("target", "Ability_Backstab") or HasDebuff("target", "Ability_Hunter_Quickshot") or HasDebuff("target", "Spell_Fire_Immolation") or HasDebuff("target", "Spell_Shadow_CurseOfSargeras") or HasDebuff("target", "Ability_Rogue_Garrote") or HasDebuff("target", "Ability_Rogue_Rupture") or HasDebuff("target", "Ability_Rogue_DualWeild") or HasDebuff("target", "Spell_Shadow_ShadowWordPain") or HasDebuff("target", "Spell_Fire_FlmaeBolt") or HasDebuff("target", "Spell_Fire_Incinerate") or HasDebuff("target", "Spell_Fire_Fireball02") or HasDebuff("target", "Spell_Shadow_AbominationExplosion") or HasDebuff("target", "Spell_Shadow_Requiem") or HasDebuff("target", "Spell_Nature_FaerieFire") or HasDebuff("target", "Spell_Nature_StarFall") or HasDebuff("target", "Ability_Druid_Disembowel") or HasDebuff("target", "Ability_GhoulFrenzy") or HasDebuff("target", "Ability_Druid_SurpriseAttack") or HasDebuff("target", "Spell_Nature_InsectSwarm") or HasDebuff("target", "Spell_Holy_SearingLight") or HasDebuff("target", "INV_Spear_02") or HasDebuff("target", "Spell_Shadow_BlackPlague")) then
        return true;
    end
    return nil;
end

function SnareDebuff()
    --Detect snaring debuffs
    --Hamstring, Wing Clip, Curse of Exhaustion, Crippling Poison, Frostbolt, Cone of Cold, Frost Shock
    if (HasDebuff("target", "Ability_ShockWave") or HasDebuff("target", "Ability_Rogue_Trip") or HasDebuff("target", "Spell_Shadow_GrimWard") or HasDebuff("target", "Ability_PoisonSting") or HasDebuff("target", "Spell_Frost_FrostBolt02") or HasDebuff("target", "Spell_Frost_Glacier") or HasDebuff("target", "Spell_Frost_FrostShock")) then
        return true;
    end
    return nil;
end

function Orogue_RunnerDetect(arg1, arg2)
    --Thanks to HateMe
    if (arg1 == CHAT_RUNNER_OROGUE) then
        Orogue_Runners[arg2] = true;
    end
end

-- Add /startattack Command.
SLASH_STARTATTACK1 = "/startattack"
SLASH_STOPATTACK1 = "/stopattack"

local function findAttackSlot()
    for i=1,120 do
        if IsAttackAction(i) then
            return i
        end
    end
end

local function startAttack(start)
    if not AttackActionSlot or not IsAttackAction(AttackActionSlot) then
        AttackActionSlot = findAttackSlot()        
        if not AttackActionSlot then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFFstartattack|r: No attack action found on your actionbars!")
            return
        end
    end    
    if (start and not IsCurrentAction(AttackActionSlot)) or (not start and IsCurrentAction(AttackActionSlot)) then
        UseAction(AttackActionSlot)
    end
end

function startattack()
    startAttack(true)
end

function stopattack()
    startAttack(false)
end
SlashCmdList.STARTATTACK = startattack
SlashCmdList.STOPATTACK = stopattack

-- return true if one of the cc-abilities is on your target.
function rogue_target_has_cc()
    if buffed("Gouge","target") or buffed("Blind","target") or buffed("Sap","target") then
        return true
    end
end

-- return true if one of the stun-abilities is on your target.
function rogue_target_has_stun()
    if buffed("Kidney Shot","target") or buffed("Cheap Shot","target") then
        return true
    end
end

-- gouge and sap immun.
function target_incapacitate_immune()
    if buffed("Berserker Rage","target") or buffed("Divine Shield","target") or buffed("Blessing of Protection","target") or buffed("Blessing of Protection","target") then
        return true
    end
end

function target_all_immune()
    if buffed("Divine Shield","target") or buffed("Blessing of Protection","target") or buffed("Blessing of Protection","target") then
        return true
    end
end

function no_cc_ready()
    if OnCooldown("Kidney Shot") and OnCooldown("Gouge") and OnCooldown("Kidney Shot") then
        return true
    end
end

function ManaDown()
    if ManaUser() then 
     return UnitManaMax("player")-UnitMana("player")
    else
     return 0
    end
end

function InstantPoisonMain()
  has_enchant_main,mx,mc,has_enchant_off = GetWeaponEnchantInfo()
  if not has_enchant_main then 
    use("Instant Poison VI")
    PickupInventoryItem(16)
  end
  ResetCursor()
end

function DeadlyPoisonMain()
  has_enchant_main,mx,mc,has_enchant_off = GetWeaponEnchantInfo()
  if not has_enchant_main then 
    use("Deadly Poison V")
    PickupInventoryItem(16)
  end
  ResetCursor()
end

function DeadlyPoisonOff()
  has_enchant_main,mx,mc,has_enchant_off = GetWeaponEnchantInfo()
  if not has_enchant_off then 
    use("Deadly Poison V")
    --use("Wound Poison IV")
    PickupInventoryItem(17)
  end
  ResetCursor()
end

function InstantPoisonOff()
  has_enchant_main,mx,mc,has_enchant_off = GetWeaponEnchantInfo()
  if not has_enchant_off then 
    use("Instant Poison VI")
    --use("Wound Poison IV")
    PickupInventoryItem(17)
  end
  ResetCursor()
end

function SelfBuff(spell)
--Important spell which allows a player to buff themselves without recasting. Only buffs if you don't have buff
    if not buffed(spell,"player") then
        CastSpellByName(spell,1)
    end
end

function MyRage()
  return UnitMana("player")
end
function MyEnergy()
  return UnitMana("player")
end
function MyMana()
  return UnitMana("player")
end
function MyManaPct()
  return UnitMana("player")/UnitManaMax("player")
end
function MyHealth()
  return UnitHealth("player")
end
function MyHealthPct()
  return UnitHealth("player")/UnitHealthMax("player")
end
function focus()
  return UnitMana("pet")
end

function ImBusy()
   if MB_isCasting or MB_isChanneling then return true end
end

function PVP()
    return (UnitIsPlayer("target") and UnitIsEnemy("target","player"))
end

function InCombat()
    return UnitAffectingCombat("player")
end

function TargetInCombat()
--save some wording
--Below level 13 ignore this. Return True
--NOTE: In Jindo fight, all targets are considered in combat. This is to work around a bug where some totems are sometimes NOT in combat!
--All non 60s always shoot at everything. I assume you are power-leveling. Comment out the next line if not.
if UnitLevel("player")<59 then return true end
 return (UnitAffectingCombat("target") or PVP()) and not (buffed("Banish","target") or buffed("Polymorph","target") or buffed("Shackle Undead","target") or buffed("Hibernate","target") or buffed("Wyvern Sting","target"))
end

function IsAlive(id)
  if not id then return end
  if UnitName(id) and (not UnitIsDead(id) and not UnitIsGhost(id) and UnitIsConnected(id)) then return true end
end

function CooldownTime(spell)
--Experimental helper function that returns how long a spell has been in cooldown
  if not SpellExists(spell) then return end
  local time=GetTime()
  local cdtime
  local start,duration,enable = GetSpellCooldown(SpellNum(spell),BOOKTYPE_SPELL)
  if duration==0 then cdtime=0
  else
    cdtime=time-start
  end
  return cdtime
end

function OnCooldown(spell)
--Important helper function that returns true(actually the duration left) if a spell is on cooldown, nil if not.
  if not SpellExists(spell) then return true end
  local start,duration,enable = GetSpellCooldown(SpellNum(spell),BOOKTYPE_SPELL)
  if duration==0 then 
    return
  else 
    return duration
  end
end

local function setTimer(duration)
    local endTime = GetTime() + duration;
    if (endTime < GetTime()) then
        return true
    end
end

local function ItemOnCooldownTime(item)
    local time=GetTime()
    local cdtime
    local start,duration,enable = GetItemCooldown(item);
    if not duration then return -1 end
    if duration==0 then cdtime=0
    else
        cdtime=time-start
    end
    return cdtime
end

local function ItemCooldown(item)
    local start,duration = GetItemCooldown(item)
    if not duration then return -1 end
        if start==0 then
            return 0
        else
            return duration-(GetTime()-start)
        end
end

function SpellExists(findspell)
    for i = 1, MAX_SKILLLINE_TABS do
   local name, texture, offset, numSpells = GetSpellTabInfo(i);
   
   if not name then
      break;
   end
   
   for s = offset + 1, offset + numSpells do
      local spell, rank = GetSpellName(s, BOOKTYPE_SPELL);
      
      if rank then
          local spell = spell.." "..rank;
      end
      if string.find(spell,findspell,nil,true) then 
       return true
      end
   end
end
end

function GetArmor()
    local base, effectiveArmor, armor, posBuff, negBuff = UnitArmor("target")
    return effectiveArmor
end

function InCatForm()
    local powerType, powerTypeString = UnitPowerType("player");

    if powerType == 3 then
        return true
    else
        return false
    end
end


function Orogue_Vanish()
    if InCombat() then
        if not buffed("Stealth","player") then cast("Vanish") end
    else
        if not buffed("Stealth","player") then
            cast("Stealth")
        end
    end
end

function TheEndofDreamsEquipped()
  return string.find(GetInventoryItemLink("player",16), "The End of Dreams")
end

function TomeofKnowledgeEquipped()
  return string.find(GetInventoryItemLink("player",17), "Tome of Knowledge")
end

function ManualCrowdPummelerEquipped()
  return string.find(GetInventoryItemLink("player",16), "Manual Crowd Pummeler")
end

PummelerCharges = 0

function Orogue_Combat_Feral()
    if not UnitClass("player") == CLASS_DRUID then return end
    -- Do nothing if channeling or casting.
    if ImBusy() then return end

    -- Go Prowl if not in combat.
        if not buffed("Omen of Clarity","player") and UFIDRUIDMANA > 598 then
            if InCatForm() then cast("Cat Form") end
            --if buffed("Cat Form","player") then cast("Cat Form") end
            cast("Omen of Clarity")
            return
        end

        if not InCombat() then
            if not buffed("Prowl","player") then cast("Prowl") end
            if buffed("Prowl","player") then cast("Ravage") end
        end

    -- If Mana points are not known unshift and save current Mana points.
    --if UFIDRUIDMANA == 0 and buffed("Cat Form","player") then cast("Cat Form") end

    -- Store Mana Points cause in Cat we can not know how much Mana we have.
    if not InCatForm() then
        --UFIDRUIDMANA = UnitMana("player")
        if InCombat() then
            if (UnitManaMax("player") - UnitMana("player"))>2000 and ItemCooldown("Dark Rune") > 10 and ItemCooldown("Major Mana Potion") > 10 and not OnCooldown("Innervate") then
                cast("Innervate")
                return
            else
                if (UnitManaMax("player") - UnitMana("player"))>500 and ItemCooldown("Dark Rune") == 0 then
                    use("Dark Rune")
                    return
                end
                if (UnitManaMax("player") - UnitMana("player"))>750 and ItemCooldown("Major Mana Potion") == 0 then
                    use("Major Mana Potion")
                    return
                end
            end
            if ItemOnCooldownTime("Juju Flurry") == 0 then
                use("Juju Flurry")
                return
            end
        end
    end

    -- Alway go back to Cat.
    --SelfBuff("Cat Form")
    if not InCatForm() then cast("Cat Form") end

    -- Do nothing if not in combat.
    if not InCombat() then return end

        startattack()

    -- Powershift.
	if not buffed("Metamorphosis Rune","player") then
		if MyEnergy()<48 and InCatForm() and SHAPESHIFT_GO then
		    if UFIDRUIDMANA > 600 then
		        cast("Cat Form")
		    end
		end
    else
        if MyEnergy()<60 and InCatForm() and SHAPESHIFT_GO then
            cast("Cat Form")
        end
	end

    -- DPS.
    if InCatForm() then
        if not buffed("Haste","player") then
            --use("Might of the Shapeshifter")
            --if ItemCooldown("Manual Crowd Pummeler") > 0 then
                --HASTECHARGES = 0
            --end
            --if not ManualCrowdPummelerEquipped then
                --use("Manual Crowd Pummeler")
            --end
            --if ManualCrowdPummelerEquipped and (HASTECHARGES == 3 and ItemCooldown("Manual Crowd Pummeler") == 0) then
                --PickupInventoryItem(16) DeleteCursorItem()
--end
            if ManualCrowdPummelerEquipped and ItemCooldown("Manual Crowd Pummeler") == 0 then
                use("Manual Crowd Pummeler")
                HASTECHARGES = HASTECHARGES + 1
            end
        end

        if not buffed("Metamorphosis Rune","player") then
            use("Rune of Metamorphosis")
        end
        if not buffed("Slayer's Crest","player") then
            use("Slayer's Crest")
        end
        if not buffed("Kiss of the Spider","player") then
            use("Kiss of the Spider")
        end
        --if not buffed("Haste","player") and ItemOnCooldownTime("Badge of the Swarmguard") > 40 and ManualCrowdPummelerEquipped() then use("The End of Dreams") end
        --if not buffed("Haste","player") and ItemOnCooldownTime("Badge of the Swarmguard") > 40 and ManualCrowdPummelerEquipped() then use("Tome of Knowledge") end
		--if not buffed("Tiger's Fury","player") and GetComboPoints()<4 and MyEnergy()>60 then
        --    cast("Tiger's Fury")
        --end
        if GetComboPoints()>=4 then
            cast("Ferocious Bite")
        end
        if GetComboPoints()<4 then
            cast("Shred")
        end
    end

end

function Orogue_Eviscerate()
    -- Do nothing if channeling or casting.
    if ImBusy() then return end

    -- Apply Poison.
    if buffed("Stealth","player") then
        --DeadlyPoisonMain()
        InstantPoisonOff()
    end

    -- Restealth for blind. TargetInCombat
    if target_hasBlind and OnCooldown("Blind") and not buffed("Stealth","player") then
        cast("Stealth")
        ClearTarget()
        return
    end
    if buffed("Blind","target") and not target_hasBlind then target_hasBlind = true end

    -- Go Stealth if not in combat.
    if not InCombat() and not buffed("Stealth","player") then
        cast("Stealth")
    end

    if buffed("Stealth","player") and not target_hasBlind then cast("Sinister Strike") end

    -- Do nothing if not in combat.
    if not InCombat() then return end

    if not buffed("Stealth","player") and InCombat() and not rogue_target_has_cc() then
        startattack()
        if buffed("Slice and Dice","player") then
            if buffed("Blade Flurry","player") then
                if not OnCooldown("Adrenaline Rush") then cast("Adrenaline Rush") end
            end
            if not OnCooldown("Blade Flurry") then cast("Blade Flurry") end
            use("Slayer's Crest")
            use("Kiss of the Spider")
            use("Juju Flurry")
            cast("Blood Fury")
            cast("Cold Blood")
        end
        if MyEnergy()<=10 and buffed("Blade Flurry","player") then
            use("Thistle Tea")
        end
        if GetComboPoints()>=4 and MyEnergy()>=35 then
            if buffed("Slice and Dice","player") then
                cast("Eviscerate")
            else
                cast("Slice and Dice")
            end
        end
        if not buffed("Slice and Dice","player") then
            cast("Slice and Dice")
        end
        if MyEnergy()>=55 and GetComboPoints()<5 then cast("Sinister Strike") end
    end
end

function Orogue_Backstab()
    -- Do nothing if channeling or casting.
    if ImBusy() then return end

    -- Apply Poison.
    if buffed("Stealth","player") then
        --DeadlyPoisonMain()
        InstantPoisonOff()
    end

    -- Restealth for blind. TargetInCombat
    if target_hasBlind and OnCooldown("Blind") and not buffed("Stealth","player") then
        cast("Stealth")
        ClearTarget()
        return
    end
    if buffed("Blind","target") and not target_hasBlind then target_hasBlind = true end

    -- Go Stealth if not in combat.
    if not InCombat() and not buffed("Stealth","player") then
        cast("Stealth")
    end

    if buffed("Stealth","player") and not target_hasBlind then cast("Ambush") end

    if not buffed("Stealth","player") and buffed("Slice and Dice","player") and MyEnergy()>=60 then
        cast("Cold Blood")
        cast("Vanish")
    end
    -- Do nothing if not in combat.
    if not InCombat() then return end

    if not buffed("Stealth","player") and InCombat() and not rogue_target_has_cc() then
        startattack()
        if buffed("Slice and Dice","player") then
            if buffed("Blade Flurry","player") then
                if not OnCooldown("Adrenaline Rush") then cast("Adrenaline Rush") end
            end
            if not OnCooldown("Blade Flurry") then cast("Blade Flurry") end
            use("Slayer's Crest")
            use("Kiss of the Spider")
            use("Juju Flurry")
            cast("Blood Fury")
        end
        if MyEnergy()<=10 and buffed("Blade Flurry","player") then
            use("Thistle Tea")
        end
        if GetComboPoints()>=4 and buffed("Slice and Dice","player") and MyEnergy()>80 then
            cast("Eviscerate")
            if OnCooldown("Feint") then
                cast("Slice and Dice")
            end
        end
        if GetComboPoints()<=4 and buffed("Slice and Dice","player") then
            if MyEnergy()>=75 then cast("Backstab") end
        end
        if not buffed("Slice and Dice","player") then
            cast("Slice and Dice")
        end
        if GetComboPoints()==0 and not buffed("Slice and Dice","player") then 
            cast("Backstab")
        end
    end
end

function Orogue_Stunlock()
    if not UnitClass("player") == CLASS_ROGUE then return end

    --Eviscerate Calculation START-----------------------------------------------------------------------------

        -- Get AttackPower.
        local base, posBuff, negBuff = UnitAttackPower("player")
        local Effective = base + posBuff + negBuff

        -- Calculate Eviscerate Rank 9 damage.
        local Modifier = Effective * (GetComboPoints() * 0.03)
        local EviscerateDamage = 0
        local EviscerateDamageCrit = 0
        if GetComboPoints()==1 then
            EviscerateDamage = ((224 + 332) / 2)
        elseif GetComboPoints()==2 then
            EviscerateDamage = ((394 + 502) / 2)
        elseif GetComboPoints()==3 then
            EviscerateDamage = ((564 + 672) / 2)
        elseif GetComboPoints()==4 then
            EviscerateDamage = ((734 + 842) / 2)
        elseif GetComboPoints()==5 then
            EviscerateDamage = ((904 + 1012) / 2)
        end

        -- Calculate the increased damage of Eviscerate based on talents.
        -- Talent Improved Eviscerate.
        local _, _, _, _, currRank = GetTalentInfo(1, 1)
        local Imp_EviscerateDamageFactor = 0.05 * tonumber(currRank)
        -- Talent Aggression
        local _, _, _, _, currRank = GetTalentInfo(2, 18)
        local AggressionDamageFactor = 0.02 * tonumber(currRank)
    
        local EviscerateDamageFactor = (Imp_EviscerateDamageFactor + AggressionDamageFactor + 1.0)

        EviscerateDamage = (EviscerateDamage + Modifier)
        EviscerateDamage = (EviscerateDamage * EviscerateDamageFactor)
        EviscerateDamageCrit = (EviscerateDamage * 2)

        -- Calculate Armor/damage reduction from target.
        -- Source: http://classic-wow.wikia.com/wiki/Armor
        --local base, effectiveArmor, armor, posBuff, negBuff = UnitArmor("target")
        local playerLevel = UnitLevel("player")
        if GetArmor() then
            local damageReduction = GetArmor()/((85 * playerLevel) + 400)
            damageReduction = 100 * (damageReduction/(damageReduction + 1))
            EviscerateDamage = EviscerateDamage - ((EviscerateDamage / 100) * damageReduction)
            EviscerateDamageCrit = EviscerateDamageCrit - ((EviscerateDamageCrit / 100) * damageReduction)
        end

    --Eviscerate Calculation END-----------------------------------------------------------------------------

    --Expose Armor Calculation START-----------------------------------------------------------------------------

        -- Expose Armor Rank 5 armor reduction.
        local ExposeArmorReduction = 0
        if GetComboPoints()==1 then
            ExposeArmorReduction = (340)
        elseif GetComboPoints()==2 then
            ExposeArmorReduction = (680)
        elseif GetComboPoints()==3 then
            ExposeArmorReduction = (1020)
        elseif GetComboPoints()==4 then
            ExposeArmorReduction = (1360)
        elseif GetComboPoints()==5 then
            ExposeArmorReduction = (1700)
        end
        
        -- Talent Expose Armor.
        local _, _, _, _, currRank = GetTalentInfo(1, 8)
        local ExposeArmorReductionFactor = 0.25 * tonumber(currRank)
        ExposeArmorReductionFactor = ExposeArmorReductionFactor + 1.0
        ExposeArmorReduction = (ExposeArmorReduction * ExposeArmorReductionFactor)

    --Expose Armor Calculation END-----------------------------------------------------------------------------

    -- Use Eviscerate if target health lower than possible Eviscerate dmg.
    --if UnitHealth("target")<EviscerateDamage and MyEnergy()>=35 then
    --  PlaySoundFile("Sound\\Interface\\PlayerInviteA.wav")
    --  cast("Eviscerate")
    --  print(EviscerateDamage)
    --  print(UnitHealth("player"))

    --end

    -- Do nothing if channeling or casting.
    if ImBusy() then return end

    -- Apply Poison.
    if buffed("Stealth","player") then
        DeadlyPoisonMain()
        DeadlyPoisonOff()
    end

    -- Restealth for blind. TargetInCombat
    if target_hasBlind and OnCooldown("Blind") and not buffed("Stealth","player") then
        cast("Stealth")
        ClearTarget()
        return
    end
    if buffed("Blind","target") and not target_hasBlind then target_hasBlind = true end

    -- Go Stealth if not in combat.
    if not InCombat() and not buffed("Stealth","player") then
        cast("Stealth")
    end


    --if GetArmor()>=0 and MyEnergy()>=25 and not buffed("Expose Armor","target") and GetComboPoints()>=3 then
    --  if buffed("Gouge","target") then
    --      cast("Expose Armor")
    --      stopattack()
    --  end
    --end

    -- Do nothing if in stealth if not full Energy.
    if not InCombat() and buffed("Stealth","player") and MyEnergy()<60 and not IsAlive("target") and UnitIsCivilian("target") and (target_all_immune() or rogue_target_has_cc or rogue_target_has_stun) then return end

    -- Cheap Shot if full Energy.
    if buffed("Stealth","player") and not target_hasBlind then cast("Cheap Shot") end

    -- Do nothing if not in combat.
    if not InCombat() then return end

    -- instant cast Sinister Strike after Cheap Shot to have no gcd for Gouge.
    if buffed("Cheap Shot","target") and MyEnergy()>=40 and GetComboPoints()==2 then cast("Sinister Strike") end

    -- Interrupt targets cast if no other CC ready.
    if (SpellInterrupt) then
        if ((GetTime() - SpellInterrupt) > 2) then
            SpellInterrupt = nil
        end
    end
    if SpellInterrupt and not rogue_target_has_cc() and not rogue_target_has_stun() and OnCooldown("Kidney Shot") and (OnCooldown("Gouge") or target_incapacitate_immune()) then cast("kick") end

    -- Blind and bandage if Health under 60%.
    if MyEnergy()>=30 and no_cc_ready() and not rogue_target_has_cc() and not rogue_target_has_stun() and not buffed("Stealth","player") and not OnCooldown("Blind") then
        if PVP() then cast("Blind") end
        if MyHealthPct()<.60 then cast("Blind") end
        -- Make sure not to move here... or you just get a "Recently Bandaged" debuff without getting bandaged.
        -- if buffed("Blind","target") then use("Heavy Runecloth Bandage") end
    end

    -- Vanish if Health under 25%.
    if (MyHealthPct()<.25 and InCombat() and not OnCooldown("Vanish") and not buffed("Stealth","player")) and (not rogue_target_has_cc() or not rogue_target_has_stun()) then 
        cast("Vanish")
        stopattack()
    end

    -- Sinister Strike if no ComboPoints and in combat (maybe target switched).
    if not buffed("Stealth","player") and InCombat() and not rogue_target_has_cc() and not GetComboPoints()==5 then
        startattack()
        if MyEnergy()>=85 and GetComboPoints()==0 then cast("Sinister Strike") end
        if MyEnergy()>=95 then cast("Sinister Strike") end
    end

    -- Dont hit target if CC'd or in stealth.
    if buffed("Stealth","player") or rogue_target_has_cc() and MyEnergy()<100 then return end

    -- Start auto attacking.
    startattack()

    -- Use Gouge.
    if not rogue_target_has_stun() and not target_incapacitate_immune() then
        if not OnCooldown("Gouge") and not rogue_target_has_cc() then cast("Gouge") end
    end

    -- Use Kidney Shot if target health higher than possible Eviscerate dmg.
    if not buffed("Cheap Shot","target") and not OnCooldown("Kidney Shot") then
        if OnCooldown("Gouge") and GetComboPoints()>=3 then cast("Kidney Shot") end
        if GetComboPoints()>=3 and OnCooldown("Gouge") and OnCooldown("kick") then cast("Kidney Shot") end
    end

    -- Use Eviscerate if target health higher than possible Eviscerate dmg.
    if MyEnergy()>=35 then
        if GetComboPoints()>=4 and CooldownTime("Kidney Shot")<18 then cast("Eviscerate") end
        --if GetComboPoints()>=4 and OnCooldown("Kidney Shot")>2 then cast("Eviscerate") end
    end

    if not buffed("Cheap Shot","target") and GetComboPoints()<=5 then
        if CooldownTime("Gouge")<3 and MyEnergy()>=45 then cast("Sinister Strike") end
        if CooldownTime("Gouge")>3 and MyEnergy()>=85 then cast("Sinister Strike") end
    end
    if not OnCooldown("Gouge") and GetComboPoints()==0 and not OnCooldown("Kidney Shot") then cast("Sinister Strike") end

end

--------------------------------------------------
--
-- Chat Handlers
--
--------------------------------------------------

function Orogue_SlashCommand(msg)
    local _, _, command, options = string.find(msg, "([%w%p]+)%s*(.*)$");
    if (command) then
        command = string.lower(command);
    end
    if (command == "eviscerate") then
        Orogue_Eviscerate();
    end
    if (command == "feral") then
        Orogue_Combat_Feral();
    end
    if (command == "backstab") then
        Orogue_Backstab();
    end
    if (command == "stunlock") then
        Orogue_Stunlock();
    end
    if (command == "vanish") then
        Orogue_Vanish();
    end
end

--------------------------------------------------
--
-- Event Handlers
--
--------------------------------------------------

function Orogue_OnLoad()
    this:RegisterEvent("PLAYER_REGEN_ENABLED");
    this:RegisterEvent("PLAYER_REGEN_DISABLED");
    this:RegisterEvent("PLAYER_ENTER_COMBAT");
    this:RegisterEvent("PLAYER_LEAVE_COMBAT");
    this:RegisterEvent("CHAT_MSG_COMBAT_SELF_MISSES");
    this:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE");
    this:RegisterEvent("CHAT_MSG_MONSTER_EMOTE");
    this:RegisterEvent("VARIABLES_LOADED");
    this:RegisterEvent("CHARACTER_POINTS_CHANGED");
    this:RegisterEvent("PLAYER_TARGET_CHANGED")

    this:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE");
    this:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE");
    this:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF");
    this:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF");
    this:RegisterEvent("CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF");
    this:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER");
    this:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS");
    this:RegisterEvent("CHAT_MSG_COMBAT_MISC_INFO");
    this:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF");
    this:RegisterEvent("CHAT_MSG_SPELL_DAMAGESHIELDS_ON_OTHERS");

    this:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS");
    this:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF");
    this:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE");
    this:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE");

    this:RegisterEvent("PLAYER_AURAS_CHANGED");

    this:RegisterEvent("SPELLCAST_START")
    this:RegisterEvent("UNIT_AURA")
    this:RegisterEvent("SPELLCAST_INTERRUPTED")
    this:RegisterEvent("SPELLCAST_FAILED")
    this:RegisterEvent("SPELLCAST_DELAYED")
    this:RegisterEvent("SPELLCAST_STOP")
    this:RegisterEvent("SPELLCAST_CHANNEL_START")
    this:RegisterEvent("SPELLCAST_CHANNEL_UPDATE")
    this:RegisterEvent("SPELLCAST_CHANNEL_STOP")

    this:RegisterEvent("UNIT_INVENTORY_CHANGED")
    this:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    this:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")

    this:RegisterEvent("MERCHANT_SHOW")
    this:RegisterEvent("PLAYER_LOGIN")
    this:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")
    this:RegisterEvent("START_AUTOREPEAT_SPELL")
    this:RegisterEvent("STOP_AUTOREPEAT_SPELL")
    this:RegisterEvent("ITEM_LOCK_CHANGED")
    this:RegisterEvent("CHAT_MSG_MONSTER_YELL")

    FuryLastSpellCast = GetTime();
    FuryLastStanceCast = GetTime();
    SlashCmdList["OROGUE"] = Orogue_SlashCommand;
    SLASH_OROGUE1 = "/orogue";
end

function Orogue_OnEvent(event)
    --if (event == "CHAT_MSG_COMBAT_SELF_MISSES" and string.find(arg1, "You attack.(.+) dodges.") or event == "CHAT_MSG_SPELL_SELF_DAMAGE" and string.find(arg1, "Your (.+) was dodged by (.+).")) then
        --Check to see if enemy dodges
        --FuryOverpower = GetTime();
    if (event == "CHAT_MSG_SPELL_SELF_DAMAGE" and (string.find(arg1, "Your Overpower crits (.+) for (%d+).") or string.find(arg1, "Your Overpower hits (.+) for (%d+).") or string.find(arg1, "Your Overpower missed (.+)."))) then
        --Check to see if Overpower is used
        FuryOverpower = nil;
        
    elseif (event == "CHAT_MSG_COMBAT_SELF_MISSES" or  event == "CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF" or event == "CHAT_MSG_SPELL_SELF_DAMAGE" or event == "CHAT_MSG_COMBAT_SELF_HITS") then
        if (string.find(arg1, "Your Cheap Shot was (.+) by (.+).") or string.find(arg1, "Your Cheap Shot missed (.+).")) then
            Cheap_Shot_failed = true;
        end
        if (string.find(arg1, "Your Kidney Shot was (.+) by (.+).") or string.find(arg1, "Your Kidney Shot missed (.+).")) then
            Kidney_Shot_failed = true;
        end
        if (string.find(arg1, "Your Gouge was (.+) by (.+).") or string.find(arg1, "Your Gouge missed (.+).")) then
            Gouge_failed = true;
        end
    elseif (event == "CHAT_MSG_COMBAT_SELF_MISSES" and (string.find(arg1, "Your Cheap Shot was (.+) by (.+).") or event == "CHAT_MSG_SPELL_SELF_BUFF" and string.find(arg1, "Your Cheap Shot missed (.+)."))) then
        Kidney_Shot_failed = true;
    elseif (event == "CHAT_MSG_SPELL_SELF_DAMAGE" and (string.find(arg1, "Your Eviscerate crits (.+) for (%d+).") or string.find(arg1, "Your Eviscerate hits (.+) for (%d+).") or string.find(arg1, "Your Eviscerate missed (.+)."))) then
        --Check to see if Eviscerate is used
        Rogue_Eviscerate = true;
    elseif (event == "CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF" and (string.find(arg1, "(.+) casts Immune (.+)/(.+)/(.+)."))) then
        --Check to see if Eviscerate is used
        Trinket_used = true;
    elseif (event == "CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE" or event == "CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF" or event == "CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF" or event == "CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE") then
        --Check to see if enemy casts spell
        for mob, spell in string.gfind(arg1, "(.+) begins to cast (.+).") do
            if (mob == UnitName("target") and UnitCanAttack("player", "target") and mob ~= spell) then
                SpellInterrupt = GetTime();
            end
            return;
        end
    elseif (event == "CHAT_MSG_SPELL_AURA_GONE_OTHER") then
        if string.find(arg1, "Blind fades from (.+).") then
            target_Blindfades = true;
            target_hasBlind = false;
        end
    elseif (event == "CHAT_MSG_SPELL_AURA_GONE_OTHERs") then
        if string.find(arg1, "(.+) is afflicted by Blind.") or string.find(arg1, "You perform Blind.") then
         --or string.find(arg1, "(.+) is afflicted by Blind.")
            target_hasBlind = true;
            target_Blindfades = false;
        end
    elseif (event == "CHAT_MSG_SPELL_SELF_DAMAGE" and string.find(arg1, "You interrupt (.+).") or event == "CHAT_MSG_COMBAT_SELF_MISSES" and string.find(arg1, "Your Kick was (.+) by (.+).") or event == "CHAT_MSG_COMBAT_SELF_MISSES" and string.find(arg1, "Your Shield Bash was (.+) by (.+).") or event == "CHAT_MSG_COMBAT_SELF_MISSES" and string.find(arg1, "Your Kick missed (.+).") or event == "CHAT_MSG_COMBAT_SELF_MISSES" and string.find(arg1, "Your Shield Bash missed (.+).")) then
        --Check to see if Pummel/Shield Bash is used
        SpellInterrupt = nil;
    elseif (event == "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE") then
        --Check to see if getting affected by breakable effects
        if (arg1 == "You are afflicted by Sap." or arg1 == "You are afflicted by Gouge." or arg1 == "You are afflicted by Repentance." or arg1 == "You are afflicted by Reckless Charge.") then
            FuryIncapacitate = true;
        elseif (arg1 == "You are afflicted by Fear." or arg1 == "You are afflicted by Intimidating Shout." or arg1 == "You are afflicted by Psychic Scream." or arg1 == "You are afflicted by Panic." or arg1 == "You are afflicted by Bellowing Roar." or arg1 == "You are afflicted by Ancient Despair." or arg1 == "You are afflicted by Terrifying Screech." or arg1 == "You are afflicted by Howl of Terror.") then
            FuryFear = true;
        end
    elseif (event == "CHAT_MSG_SPELL_AURA_GONE_SELF") then
        --Check to see if breakable effects fades
        if (arg1 == "Sap fades from you." or arg1 == "Gouge fades from you." or arg1 == "Repentance fades from you." or arg1 == "Reckless Charge fades from you.") then
            FuryIncapacitate = nil;
        elseif (arg1 == "Fear fades from you." or arg1 == "Intimidating Shout fades from you." or arg1 == "Psychic Scream fades from you." or arg1 == "Panic fades from you." or arg1 == "Bellowing Roar fades from you." or arg1 == "Ancient Despair fades from you." or arg1 == "Terrifying Screech fades from you." or arg1 == "Howl of Terror fades from you.") then
            FuryFear = nil;
        end
    --elseif (event == "CHAT_MSG_MONSTER_EMOTE") then
        --Check to see if enemy flees
        --Fury_RunnerDetect(arg1, arg2);
    elseif (event == "PLAYER_TARGET_CHANGED" or (event == "CHARACTER_POINTS_CHANGED" and arg1 == -1)) then
        --Reset Overpower and interrupts, check to see if talents are being calculated
        if (event == "PLAYER_TARGET_CHANGED") then
            SpellInterrupt = nil;
        end
    elseif event == "SPELLCAST_START" then 
        -- this event fires when you start casting
        --Print(arg1)
        --MB_isCasting=true
        --me=UnitName("player")
        --if not string.find(arg1,"eal") and not string.find(arg1,"ight") then return end
    elseif event == "SPELLCAST_INTERRUPTED" then 
        -- this event fires when your spells gets interrupted
        MB_isCasting=false
        --if MB_debugmsgs and FindInTable(MB_healer_list,UnitName("player")) then RunLine("/raid INTERRUPTED!") end
    elseif event == "SPELLCAST_FAILED" then 
        -- this event fires when your spell fails
        MB_isCasting=false
    elseif event == "SPELLCAST_DELAYED" then 
        -- this event fires when your spell gets delayed
    elseif event == "SPELLCAST_STOP" then 
        -- this event fires when you stop casting
        MB_isCasting=false
    elseif event == "SPELLCAST_CHANNEL_START" then 
        -- this event fires when you stop casting
        MB_isChanneling=true
    elseif event == "SPELLCAST_CHANNEL_STOP" then 
        -- this event fires when you stop casting
        MB_isChanneling=false
    elseif (event == "PLAYER_REGEN_DISABLED") then
        FuryCombat = true;
        RegenOn = false
    elseif (event == "PLAYER_REGEN_ENABLED") then
        FuryCombat = nil;
        FuryDanceDone = nil;
        FuryOldStance = nil;
        RegenOn = true
    elseif (event == "PLAYER_ENTER_COMBAT") then
        CombatLeft = false
        FuryAttack = true;
    elseif (event == "PLAYER_LEAVE_COMBAT") then
        FuryAttack = nil;
        CombatLeft = true
    end
end
