function onSay(player, words, param)
    local starterPokemons = {
        "bulbasaur", "charmander", "squirtle",
        "cyndaquil", "chikorita", "totodile", 
        "mudkip", "torchic", "treecko",
        "turtwig", "chimchar", "piplup", 
    }
    
    if player:getStorageValue(505050) == 0 then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Fale com o Professor Oak para escolher seu Pokémon inicial.")
        return false
    end
    
	player:addItem(2152, 10)
	player:addItem(26662, 50)
	player:addItem(27645, 10)
	
    if player:getStorageValue(505050) ~= 2 then
        -- Verificar se o Pokémon é um inicial
        local isStarter = false
        for i = 1, #starterPokemons do
            if param:lower() == starterPokemons[i]:lower() then
                isStarter = true
                break
            end
        end
        
        if not isStarter then
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Esse pokemon estara disponivel em breve! Escolha um ate a quarta geracao.")
            player:sendExtendedOpcode(69, ":)")
            return false
        end
        

        player:addSlotItems()
        local addPokeball = player:addPokemon(param)
        
        if addPokeball then
			doSendPokeTeamByClient(player:getId())

        else
            print("WARNING! Player " .. player:getName() .. " without initial pokeball.")
        end
			player:setStorageValue(505050, 2)

    end
    
    return false
end
