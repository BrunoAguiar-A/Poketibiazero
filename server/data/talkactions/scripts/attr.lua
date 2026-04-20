local function setPokemonLevel(item, target)
	if not item:isPokeball() then
		return false
	end
	local level = math.floor(tonumber(target) or 1)
	if PokemonLevel and PokemonLevel.CONFIG then
		level = math.max(1, math.min(PokemonLevel.CONFIG.maxLevel, level))
		PokemonLevel.ensureBall(item, item:getSpecialAttribute("pokeName"))
		PokemonLevel.setPokemonTotalExp(item, PokemonLevel.getExpForLevel(level))
	else
		item:setSpecialAttribute("pokeLevel", level)
	end
	return true
end

local function setPokemonExp(item, target)
	if not item:isPokeball() then
		return false
	end
	local exp = math.max(0, math.floor(tonumber(target) or 0))
	if PokemonLevel and PokemonLevel.setPokemonTotalExp then
		PokemonLevel.ensureBall(item, item:getSpecialAttribute("pokeName"))
		PokemonLevel.setPokemonTotalExp(item, exp)
	else
		item:setSpecialAttribute("pokeExp", exp)
	end
	return true
end

local function addPokemonExp(item, target)
	if not item:isPokeball() or not (PokemonLevel and PokemonLevel.addExp) then
		return false
	end
	PokemonLevel.addExp(item, tonumber(target) or 0)
	return true
end

local function setPokemonBL(item, target)
	if not item:isPokeball() then
		return false
	end
	local bl = math.floor(tonumber(target) or 0)
	bl = math.max(0, math.min(12, bl))
	if PokemonLevel and PokemonLevel.setBL then
		return PokemonLevel.setBL(item, bl) ~= false
	end
	item:setSpecialAttribute("pokeBL", bl)
	return true
end

local function setPokemonBoost(item, target)
	if not item:isPokeball() then
		return false
	end
	if PokemonLevel and PokemonLevel.setBoost then
		return PokemonLevel.setBoost(item, target) ~= false
	end
	item:setSpecialAttribute("pokeBoost", math.max(0, math.floor(tonumber(target) or 0)))
	return true
end

local function rerollPokemonBL(item)
	if not item:isPokeball() or not (PokemonLevel and PokemonLevel.rerollBL) then
		return false
	end
	PokemonLevel.rerollBL(item)
	return true
end

local function setPokemonNature(item, target)
	if not item:isPokeball() or not (PokemonLevel and PokemonLevel.setNature) then
		return false
	end
	return PokemonLevel.setNature(item, target)
end

local function rerollPokemonNature(item)
	if not item:isPokeball() or not (PokemonLevel and PokemonLevel.rerollNature) then
		return false
	end
	PokemonLevel.rerollNature(item)
	return true
end

local function setPokemonIV(statName)
	return function(item, target)
		if not item:isPokeball() or not (PokemonLevel and PokemonLevel.setIV) then
			return false
		end
		return PokemonLevel.setIV(item, statName, target)
	end
end

local function rerollPokemonIVs(item)
	if not item:isPokeball() or not (PokemonLevel and PokemonLevel.rerollIVs) then
		return false
	end
	PokemonLevel.rerollIVs(item)
	return true
end

local itemFunctions = {
    ["actionid"] = { isActive = true, targetFunction = function (item, target) return item:setActionId(target) end },
    ["action"] = { isActive = true, targetFunction = function (item, target) return item:setActionId(target) end },
    ["aid"] = { isActive = true, targetFunction = function (item, target) return item:setActionId(target) end },
    ["description"] = { isActive = true, targetFunction = function (item, target) return item:setAttribute(ITEM_ATTRIBUTE_DESCRIPTION, target) end },
    ["desc"] = { isActive = true, targetFunction = function (item, target) return item:setAttribute(ITEM_ATTRIBUTE_DESCRIPTION, target) end },
    ["remove"] = { isActive = true, targetFunction = function (item, target) return item:remove() end },
    ["decay"] = { isActive = true, targetFunction = function (item, target) return item:decay() end },
    ["transform"] = { isActive = true, targetFunction = function (item, target) return item:transform(target) end },
    ["clone"] = { isActive = true, targetFunction = function (item, target) return item:clone() end },
    ["boost"] = { isActive = true, targetFunction = setPokemonBoost },
    ["level"] = { isActive = true, targetFunction = setPokemonLevel },
    ["lv"] = { isActive = true, targetFunction = setPokemonLevel },
    ["exp"] = { isActive = true, targetFunction = setPokemonExp },
    ["addexp"] = { isActive = true, targetFunction = addPokemonExp },
    ["bl"] = { isActive = true, targetFunction = setPokemonBL },
    ["rerollbl"] = { isActive = true, targetFunction = function (item, target) return rerollPokemonBL(item) end },
    ["nature"] = { isActive = true, targetFunction = setPokemonNature },
    ["rerollnature"] = { isActive = true, targetFunction = function (item, target) return rerollPokemonNature(item) end },
    ["ivhp"] = { isActive = true, targetFunction = setPokemonIV("hp") },
    ["ivatk"] = { isActive = true, targetFunction = setPokemonIV("atk") },
    ["ivdef"] = { isActive = true, targetFunction = setPokemonIV("def") },
    ["ivspatk"] = { isActive = true, targetFunction = setPokemonIV("spatk") },
    ["ivspdef"] = { isActive = true, targetFunction = setPokemonIV("spdef") },
    ["ivspeed"] = { isActive = true, targetFunction = setPokemonIV("speed") },
    ["rerollivs"] = { isActive = true, targetFunction = function (item, target) return rerollPokemonIVs(item) end },
    ["nickname"] = { isActive = true, targetFunction = function (item, target) return item:setSpecialAttribute("nickname", target) end },
    ["poke"] = { isActive = true, targetFunction = function (item, target) return item:setSpecialAttribute("pokeName", target) end },
    ["pokemon"] = { isActive = true, targetFunction = function (item, target) return item:setSpecialAttribute("pokeName", target) end },
    ["dono"] = { isActive = true, targetFunction = function (item, target) return item:setSpecialAttribute("ownerPokemon", target) end },
    ["heldx"] = { isActive = true, targetFunction = function (item, target) return item:setAttribute(ITEM_ATTRIBUTE_HELDX, tonumber(target)) end },
    ["heldy"] = { isActive = true, targetFunction = function (item, target) return item:setAttribute(ITEM_ATTRIBUTE_HELDY, tonumber(target)) end },
    ["heldu"] = { isActive = true, targetFunction = function (item, target) return item:setAttribute(ITEM_ATTRIBUTE_HELDU, tonumber(target)) end },
}
 
local creatureFunctions = {
    ["health"] = { isActive = true, targetFunction = function (creature, target) return creature:addHealth(target) end },
    ["mana"] = { isActive = true, targetFunction = function (creature, target) return creature:addMana(target) end },
    ["speed"] = { isActive = true, targetFunction = function (creature, target) return creature:changeSpeed(target) end },
    ["droploot"] = { isActive = true, targetFunction = function (creature, target) return creature:setDropLoot(target) end },
    ["skull"] = { isActive = true, targetFunction = function (creature, target) return creature:setSkull(target) end },
    ["direction"] = { isActive = true, targetFunction = function (creature, target) return creature:setDirection(target) end },
    ["maxHealth"] = { isActive = true, targetFunction = function (creature, target) return creature:setMaxHealth(target) end },
    ["say"] = { isActive = true, targetFunction = function (creature, target) creature:say(target, TALKTYPE_SAY) end }
}
 
local playerFunctions = {
    ["fyi"] = { isActive = true, targetFunction = function (player, target) return player:popupFYI(target) end },
    ["tutorial"] = { isActive = true, targetFunction = function (player, target) return player:sendTutorial(target) end },
    ["guildnick"] = { isActive = true, targetFunction = function (player, target) return player:setGuildNick(target) end },
    ["group"] = { isActive = true, targetFunction = function (player, target) return player:setGroup(Group(target)) end },
    ["vocation"] = { isActive = true, targetFunction = function (player, target) return player:setVocation(Vocation(target)) end },
    ["stamina"] = { isActive = true, targetFunction = function (player, target) return player:setStamina(target) end },
    ["town"] = { isActive = true, targetFunction = function (player, target) return player:setTown(Town(target)) end },
    ["balance"] = { isActive = true, targetFunction = function (player, target) return player:setBankBalance(target + player:getBankBalance()) end },
    ["save"] = { isActive = true, targetFunction = function (player, target) return target:save() end },
    ["type"] = { isActive = true, targetFunction = function (player, target) return player:setAccountType(target) end },
    ["skullTime"] = { isActive = true, targetFunction = function (player, target) return player:setSkullTime(target) end },
    ["maxMana"] = { isActive = true, targetFunction = function (player, target) return player:setMaxMana(target) end },
    ["addItem"] = { isActive = true, targetFunction = function (player, target) return player:addItem(target, 1) end },
    ["removeItem"] = { isActive = true, targetFunction = function (player, target) return player:removeItem(target, 1) end },
    ["premium"] = { isActive = true, targetFunction = function (player, target) return player:addPremiumDays(target) end }
}
 
function onSay(player, words, param)
    if(not player:getGroup():getAccess()) or player:getAccountType() < ACCOUNT_TYPE_GOD then
        return true
    end
   
    if(param == "") then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Command param required.")
        return false
    end
   
    local position = player:getPosition()
    position:getNextPosition(player:getDirection(), 1)
   
    local split = param:split(",")
    local itemFunction, creatureFunction, playerFunction = itemFunctions[split[1]], creatureFunctions[split[1]], playerFunctions[split[1]]
    if(itemFunction and itemFunction.isActive) then
        local item = Tile(position):getTopVisibleThing(player)
        if(not item or not item:isItem()) then
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Item not found.")
            return false
        end
       
        if(itemFunction.targetFunction(item, split[2])) then
            position:sendMagicEffect(CONST_ME_MAGIC_GREEN)
        else
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "You cannot add that attribute to this item.")
        end
    elseif(creatureFunction and creatureFunction.isActive) then
        local creature = Tile(position):getTopCreature()
        if(not creature or not creature:isCreature()) then
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Creature not found.")
            return false
        end
       
        if(creatureFunction.targetFunction(creature, split[2])) then
            position:sendMagicEffect(CONST_ME_MAGIC_GREEN)
        else
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "You cannot add that attribute to this creature.")
        end
    elseif(playerFunction and playerFunction.isActive) then
        local targetPlayer = Tile(position):getTopCreature()
        if(not targetPlayer or not targetPlayer:getPlayer()) then
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Player not found.")
            return false
        end
       
        if(playerFunction.targetFunction(targetPlayer, split[2])) then
            position:sendMagicEffect(CONST_ME_MAGIC_GREEN)
        else
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "You cannot add that attribute to this player.")
        end
    else
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Unknow attribute.")
    end
    return false
end
