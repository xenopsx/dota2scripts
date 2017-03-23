local Utility = require("Utility")
local AutoStash = require("AutoStash")

local AutoUseItems = {}

AutoUseItems.optionSoulRing = Menu.AddOption({"Item Specific"}, "Soul Ring", "Auto use soul ring before casting spells or items")
AutoUseItems.optionTomeOfKnowledge = Menu.AddOption({"Item Specific"}, "Tome of Knowledge", "Auto purchase tome of knowledge once available")
AutoUseItems.optionDeward = Menu.AddOption({"Item Specific"}, "Deward", "Auto use quelling blade, iron talen, or battle fury to deward")
AutoUseItems.optionIronTalon = Menu.AddOption({"Item Specific"}, "Iron Talon", "Auto use iron talen to remove creep's HP")
AutoUseItems.optionHeal = Menu.AddOption({"Item Specific"}, "Heal", "Auto use magic wand(stick) or faerie fire if HP is low")
AutoUseItems.optionSheepstick = Menu.AddOption({"Item Specific"}, "Sheepstick", "Auto use sheepstick on enemy hero once available")
AutoUseItems.optionOrchid = Menu.AddOption({"Item Specific"}, "Orchid & Bloodthorn", "Auto use orchid or bloodthorn on enemy hero once available")
AutoUseItems.optionAtos = Menu.AddOption({"Item Specific"}, "Rod of Atos", "Auto use atos on enemy hero once available")
AutoUseItems.optionDagon = Menu.AddOption({"Item Specific"}, "Dagon", "Auto use dagon on enemy hero once available")
AutoUseItems.optionVeil = Menu.AddOption({"Item Specific"}, "Veil of Discord", "Auto use veil once available")
AutoUseItems.optionLotus = Menu.AddOption({"Item Specific"}, "Lotus Orb", "(For tinker) auto use lotus orb on self or allies once available")

function AutoUseItems.OnUpdate()
    local myHero = Heroes.GetLocal()
    if not myHero then return end

    if NPC.HasState(myHero, Enum.ModifierState.MODIFIER_STATE_INVISIBLE) then return end
    -- if not NPC.IsVisible(myHero) then return end
    if NPC.IsChannellingAbility(myHero) then return end
    if NPC.IsStunned(myHero) or not Entity.IsAlive(myHero) then return end

    -- ========================
    -- Defensive items 
    -- ========================
    if Menu.IsEnabled(AutoUseItems.optionTomeOfKnowledge) then
    	AutoUseItems.item_tome_of_knowledge(myHero)
    end

    if Menu.IsEnabled(AutoUseItems.optionDeward) then
    	AutoUseItems.deward(myHero)
    end

    if Menu.IsEnabled(AutoUseItems.optionIronTalon) then
    	AutoUseItems.item_iron_talon(myHero)
    end

    if Menu.IsEnabled(AutoUseItems.optionHeal) then
    	AutoUseItems.heal(myHero)
    end

    if Menu.IsEnabled(AutoUseItems.optionLotus) then
    	AutoUseItems.item_lotus_orb(myHero)
    end

    -- ========================
    -- Aggressive items 
    -- ========================
    if Menu.IsEnabled(AutoUseItems.optionSheepstick) and NPC.IsVisible(myHero) then
    	AutoUseItems.item_sheepstick(myHero)
    end

    if Menu.IsEnabled(AutoUseItems.optionOrchid) and NPC.IsVisible(myHero) then
    	AutoUseItems.item_orchid(myHero)
    end

    if Menu.IsEnabled(AutoUseItems.optionAtos) and NPC.IsVisible(myHero) then
    	AutoUseItems.item_rod_of_atos(myHero)
    end

    if Menu.IsEnabled(AutoUseItems.optionDagon) and NPC.IsVisible(myHero) then
    	AutoUseItems.item_dagon(myHero)
    end

    if Menu.IsEnabled(AutoUseItems.optionVeil) and NPC.IsVisible(myHero) then
    	AutoUseItems.item_veil_of_discord(myHero)
    end
end

-- auto use soul ring before casting spells or items
function AutoUseItems.OnPrepareUnitOrders(orders)
    if not Menu.IsEnabled(AutoUseItems.optionSoulRing) then return true end
    if not orders or not orders.ability then return true end

    if not Entity.IsAbility(orders.ability) then return true end
    if Ability.GetManaCost(orders.ability) <= 0 then return true end

    local myHero = Heroes.GetLocal()
    if not myHero or NPC.IsStunned(myHero) then return true end
    
    local soul_ring = NPC.GetItem(myHero, "item_soul_ring", true)
    if not soul_ring or not Ability.IsCastable(soul_ring, 0) then return true end

    local HpThreshold = 200
    if Entity.GetHealth(myHero) <= HpThreshold then return true end

    -- If in base, stash items before using soul ring.
    -- It has to team with stash2inventory() action in AutoStash.lua
    if NPC.HasModifier(myHero, "modifier_fountain_aura_buff") then
    	AutoStash.inventory2stash(myHero)
    end

    Ability.CastNoTarget(soul_ring)
    return true
end

-- auto purchase tome of knowledge once available
function AutoUseItems.item_tome_of_knowledge(myHero)
end

-- Auto use quelling blade, iron talen, or battle fury to deward
function AutoUseItems.deward(myHero)
	local item1 = NPC.GetItem(myHero, "item_quelling_blade", true)
	local item2 = NPC.GetItem(myHero, "item_iron_talon", true)
	local item3 = NPC.GetItem(myHero, "item_bfury", true)

	local item = nil
	if item1 and Ability.IsCastable(item1, 0) then item = item1 end
	if item2 and Ability.IsCastable(item2, 0) then item = item2 end
	if item3 and Ability.IsCastable(item3, 0) then item = item3 end
	if not item then return end

	local range = 450
	local wards = NPC.GetUnitsInRadius(myHero, range, Enum.TeamType.TEAM_ENEMY)
	for i, npc in ipairs(wards) do
		if NPC.GetUnitName(npc) == "npc_dota_observer_wards" or NPC.GetUnitName(npc) == "npc_dota_sentry_wards" then
			Ability.CastTarget(item, npc)
			return
		end
	end
end

-- Auto use iron talon to remove creep's HP
function AutoUseItems.item_iron_talon(myHero)
	local item = NPC.GetItem(myHero, "item_iron_talon", true)
	if not item or not Ability.IsCastable(item, 0) then return end

	local radius = 1200
	local enemyHeroes = NPC.GetHeroesInRadius(myHero, radius, Enum.TeamType.TEAM_ENEMY)
	if enemyHeroes and #enemyHeroes > 0 then return end

	local range = 350 + 200
	local creeps = NPC.GetUnitsInRadius(myHero, range, Enum.TeamType.TEAM_ENEMY)
	if not creeps or #creeps <= 0 then return end

	local maxHp = 0
	local target = nil
	local ratio = 0.5
	for i, npc in ipairs(creeps) do
		local tmpHp = Entity.GetHealth(npc)
		if tmpHp > maxHp and NPC.IsCreep(npc) 
			and (not NPC.IsAncient(npc)) and (not NPC.IsRoshan(npc)) 
			and tmpHp > ratio*Entity.GetMaxHealth(npc) then
			maxHp = tmpHp
			target = npc
		end
	end

	if target then Ability.CastTarget(item, target) end
end

-- Auto use magic wand(stick) or faerie fire if HP is low
function AutoUseItems.heal(myHero)
	local item1 = NPC.GetItem(myHero, "item_magic_stick", true)
	local item2 = NPC.GetItem(myHero, "item_magic_wand", true)
	local item3 = NPC.GetItem(myHero, "item_faerie_fire", true)

	local item = nil
	if item1 and Ability.IsCastable(item1, 0) and Item.GetCurrentCharges(item1)>0 then item = item1 end
	if item2 and Ability.IsCastable(item2, 0) and Item.GetCurrentCharges(item2)>0 then item = item2 end
	if item3 and Ability.IsCastable(item3, 0) then item = item3 end
	if not item then return end

	local HpThreshold = 200
	if Entity.GetHealth(myHero) <= HpThreshold then
		Ability.CastNoTarget(item)
	end
end

-- Auto use sheepstick on enemy hero once available
-- Doesn't use on enemy who is lotus orb protected or AM with aghs.
function AutoUseItems.item_sheepstick(myHero)
	local item = NPC.GetItem(myHero, "item_sheepstick", true)
	if not item or not Ability.IsCastable(item, NPC.GetMana(myHero)) then return end

	local range = 800
	local enemyAround = NPC.GetHeroesInRadius(myHero, range, Enum.TeamType.TEAM_ENEMY)

	local minDistance = 99999
	local target = nil
	for i, enemy in ipairs(enemyAround) do
		if Utility.IsEligibleEnemy(enemy) and not Utility.IsLotusProtected(enemy) then
			local dis = (NPC.GetAbsOrigin(myHero) - NPC.GetAbsOrigin(enemy)):Length()
			if dis < minDistance then
				minDistance = dis
				target = enemy
			end
		end
	end

	-- cast sheepstick on nearest enemy in range
	if target then Ability.CastTarget(item, target) end
end

-- Auto use orchid or bloodthorn on enemy hero once available
-- Doesn't use on enemy who is lotus orb protected or AM with aghs.
function AutoUseItems.item_orchid(myHero)
	local item1 = NPC.GetItem(myHero, "item_orchid", true)
	local item2 = NPC.GetItem(myHero, "item_bloodthorn", true)

	local item = nil
	if item1 and Ability.IsCastable(item1, NPC.GetMana(myHero)) then item = item1 end
	if item2 and Ability.IsCastable(item2, NPC.GetMana(myHero)) then item = item2 end
	if not item then return end

	local range = 900
	local enemyAround = NPC.GetHeroesInRadius(myHero, range, Enum.TeamType.TEAM_ENEMY)
	
	local minDistance = 99999
	local target = nil
	for i, enemy in ipairs(enemyAround) do
		if Utility.IsEligibleEnemy(enemy) and not NPC.IsSilenced(enemy) and not Utility.IsLotusProtected(enemy) then
			local dis = (NPC.GetAbsOrigin(myHero) - NPC.GetAbsOrigin(enemy)):Length()
			if dis < minDistance then
				minDistance = dis
				target = enemy
			end
		end
	end

	-- cast orchid/bloodthorn on nearest enemy in range
	if target then Ability.CastTarget(item, target) end
end

-- Auto use rod of atos on enemy hero once available
-- Doesn't use on enemy who is lotus orb protected or AM with aghs.
function AutoUseItems.item_rod_of_atos(myHero)
	local item = NPC.GetItem(myHero, "item_rod_of_atos", true)
	if not item or not Ability.IsCastable(item, NPC.GetMana(myHero)) then return end

	local range = 1150
	local enemyAround = NPC.GetHeroesInRadius(myHero, range, Enum.TeamType.TEAM_ENEMY)

	local minDistance = 99999
	local target = nil
	for i, enemy in ipairs(enemyAround) do
		if Utility.IsEligibleEnemy(enemy) and not Utility.IsLotusProtected(enemy)
			and not NPC.HasState(npc, Enum.ModifierState.MODIFIER_STATE_ROOTED) then
			local dis = (NPC.GetAbsOrigin(myHero) - NPC.GetAbsOrigin(enemy)):Length()
			if dis < minDistance then
				minDistance = dis
				target = enemy
			end
		end
	end

	-- cast rod of atos on nearest enemy in range
	if target then Ability.CastTarget(item, target) end
end

function AutoUseItems.item_dagon(myHero)
	local level, item
	local item1 = NPC.GetItem(myHero, "item_dagon", true)
	local item2 = NPC.GetItem(myHero, "item_dagon_2", true)
	local item3 = NPC.GetItem(myHero, "item_dagon_3", true)
	local item4 = NPC.GetItem(myHero, "item_dagon_4", true)
	local item5 = NPC.GetItem(myHero, "item_dagon_5", true)

	if item1 and Ability.IsCastable(item1, NPC.GetMana(myHero)) then item = item1; level = 1 end
	if item2 and Ability.IsCastable(item2, NPC.GetMana(myHero)) then item = item2; level = 2 end
	if item3 and Ability.IsCastable(item3, NPC.GetMana(myHero)) then item = item3; level = 3 end
	if item4 and Ability.IsCastable(item4, NPC.GetMana(myHero)) then item = item4; level = 4 end
	if item5 and Ability.IsCastable(item5, NPC.GetMana(myHero)) then item = item5; level = 5 end

	if not item then return end

	local range = 600 + 50 * (level - 1)
	local magic_damage = 400 + 100 * (level - 1)

	local target
	local minHp = 99999
	local enemyAround = NPC.GetHeroesInRadius(myHero, range, Enum.TeamType.TEAM_ENEMY)
	for i, enemy in ipairs(enemyAround) do
		if Utility.IsEligibleEnemy(enemy) and AutoUseItems.IsSafeToCast(myHero, enemy, magic_damage) then
			local enemyHp = Entity.GetHealth(enemy)
			if enemyHp < minHp then
				target = enemy
				minHp = enemyHp
			end
		end
	end

	-- cast dagon on enemy with lowest HP in range
	if target then Ability.CastTarget(item, target) end
end

-- check if it is safe to cast spell or item on enemy
-- in case enemy has blademail or lotus.
-- Caster will take double damage if target has both lotus and blademail
function AutoUseItems.IsSafeToCast(myHero, enemy, magic_damage)
	if not myHero or not enemy or not magic_damage then return true end
	if magic_damage <= 0 then return true end

	local counter = 0
	if NPC.HasModifier(enemy, "modifier_item_lotus_orb_active") then counter = counter + 1 end
	if NPC.HasModifier(enemy, "modifier_item_blade_mail_reflect") then counter = counter + 1 end
	
	local reflect_damage = counter * magic_damage * NPC.GetMagicalArmorDamageMultiplier(myHero)
	return Entity.GetHealth(myHero) > reflect_damage
end

function AutoUseItems.item_veil_of_discord(myHero)
	local item = NPC.GetItem(myHero, "item_veil_of_discord", true)
	if not item or not Ability.IsCastable(item, NPC.GetMana(myHero)) then return end

	local range = 1000
	local enemyHeroes = NPC.GetHeroesInRadius(myHero, range, Enum.TeamType.TEAM_ENEMY)
	if not enemyHeroes or #enemyHeroes <= 0 then return end

	local radius = 600
	local pos = Utility.BestPosition(enemyHeroes, radius)
    if pos then Ability.CastPosition(item, pos) end
end

-- Auto cast lotus orb to save ally
-- For tinker, auto use lotus orb on self or allies once available
function AutoUseItems.item_lotus_orb(myHero)
	local item = NPC.GetItem(myHero, "item_lotus_orb", true)
	if not item or not Ability.IsCastable(item, NPC.GetMana(myHero)) then return end

	local range = 900
	local allyAround = NPC.GetHeroesInRadius(myHero, range, Enum.TeamType.TEAM_FRIEND)
	if not allyAround or #allyAround <= 0 then return end

	-- save ally who get stunned, silenced, rooted, disarmed, low Hp, etc
	for i, ally in ipairs(allyAround) do
		if Utility.NeedToBeSaved(ally) then
			Ability.CastTarget(item, ally)
			return
		end
	end

	-- for tinker
	if NPC.GetUnitName(myHero) ~= "npc_dota_hero_tinker" then return end

	if not NPC.HasModifier(myHero, "modifier_item_lotus_orb_active") then
		Ability.CastTarget(item, myHero)
		return
	end

	-- cast lotus orb once available
	for i, ally in ipairs(allyAround) do
		if Entity.IsAlive(ally) and not NPC.IsIllusion(ally) 
			and not NPC.HasModifier(ally, "modifier_item_lotus_orb_active") then
			
			Ability.CastTarget(item, ally)
			return
		end
	end
end

return AutoUseItems