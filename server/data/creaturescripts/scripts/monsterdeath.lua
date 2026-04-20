function onDeath(creature, corpse, killer, mostDamageKiller, unjustified, mostDamageUnjustified)
	local player = creature:getMaster()
    if player then
	local item = player:getUsingBall()
			if item then
				local ballKey = getBallKey(item)
				item:setSpecialAttribute("pokeHealth", 0)
				player:sendCancelMessage("Your pokemon has died.")
				creature:unregisterEvent("MonsterDeath")
				player:say("Thanks, " .. creature:getName() .. "!", TALKTYPE_MONSTER_SAY)
				item:setSpecialAttribute("isBeingUsed", 0)
				applyPokeballStateVisual(item, "released", ballKey)
				doSendGobackInformations(player, creature, "remove")
				doSendPokeTeamByClient(player)
				player:setUsingPokeball(false)
			end
    end
    return true
end
