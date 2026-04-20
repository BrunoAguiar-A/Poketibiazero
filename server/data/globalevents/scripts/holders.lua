function onHolders(pokeball)
	print("Holder Created")
	if not pokeball or not pokeball.isPokeball or not pokeball:isPokeball() then
		return false
	end

	local spawnName = pokeball:getSpecialAttribute("pokeName")
	if not spawnName or spawnName == "" then
		return false
	end
	local pokeBoost = pokeball:getSpecialAttribute("pokeBoost") or 0
	if PokemonLevel and PokemonLevel.ensureBall then
		PokemonLevel.ensureBall(pokeball, spawnName)
	end
	local pokeLevel = PokemonLevel and PokemonLevel.getLevel and PokemonLevel.getLevel(pokeball) or (pokeball:getSpecialAttribute("pokeLevel") or 1)
	local creatureName = PokemonLevel and PokemonLevel.formatOverheadName and PokemonLevel.formatOverheadName(spawnName, pokeLevel, pokeBoost, true) or (pokeBoost >= 1 and string.format("%s [%d +%d]", spawnName, pokeLevel, pokeBoost) or string.format("%s [%d]", spawnName, pokeLevel))
	local spawnType = MonsterType(spawnName)
	if not spawnType then
		return false
	end
	local spawnPosition = pokeball:getTopParent():getPosition()
	local npc = Game.createNpc("Holder", spawnPosition, false, true, creatureName, true)
	if npc then
		npc:setSpeechBubble(0)
		pokeball:setSpecialAttribute("creatureID", npc:getId())
		npc:setOutfit(spawnType:outfit())
		local updateTile = Tile(spawnPosition)
		updateTile:update()
		local ballKey = getBallKey(pokeball)
		npc:getPosition():sendMagicEffect(balls[ballKey].effectRelease)
		return npc
	end
	return false
end
