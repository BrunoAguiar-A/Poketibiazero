function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    if type(target) ~= "userdata" then return true end

    if target ~= item and target:isCreature() ~= true then return false end

    if target:isCreature() then
        if not target:isMonster() then
            return true
        end
        local name = capitalizeFirstLetter(target:getName())

		if not reverse_pokemons["Bulbasaur"] then
			loadDexInfos()
		end

		local lookupName = name
		if string.find(name:lower(), "^shiny ") then
			lookupName = capitalizeFirstLetter(string.sub(name, 7))
		elseif string.find(name:lower(), "^mega ") then
			lookupName = capitalizeFirstLetter(string.sub(name, 6))
		end
		local pokemonId = reverse_pokemons[lookupName]
		if not pokemonId then return true end
		local storage = pokemonId + BASE_STORAGE_DEX

		if player:getStorageValue(storage) == 1 then
       		sendPokedex(player, name)
		else
        	player:getPosition():sendMagicEffect(15)
			player:setStorageValue(storage, 1)
			sendUpdateDex(player, pokemonId)
			sendPokedex(player, name)
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, string.format("Parabens, voce descobriu o %s", name))
		end
    end
    return true
end
