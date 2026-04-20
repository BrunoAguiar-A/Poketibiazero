function Player:onNetworkMessage(recvByte, msg)
	local handler = PacketHandlers[recvByte]
	if not handler then
		--io.write(string.format("Player: %s sent an unknown packet header: 0x%02X with %d bytes!\n", self:getName(), recvByte, msg:len()))
		return
	end

	handler(self, msg)
end

function Player:onBrowseField(position)
	return false
end

local function getPokemonLevelLookText(ball, pokeName, includeStats)
	if not (PokemonLevel and PokemonLevel.ensureBall and PokemonLevel.getProgressInfo) then
		return ""
	end

	PokemonLevel.ensureBall(ball, pokeName)
	local progress = PokemonLevel.getProgressInfo(ball)
	local nextExp = progress.level >= PokemonLevel.CONFIG.maxLevel and "MAX" or tostring(progress.nextExp)
	local text = string.format(
		"\nLevel: %d\nEXP: %d / %s (%d%%)",
		progress.level,
		progress.exp,
		nextExp,
		progress.percent
	)

	if includeStats and PokemonLevel.getDisplayStats then
		local stats = PokemonLevel.getDisplayStats(ball, pokeName, MonsterType(pokeName))
		text = string.format(
			"%s\nStats: HP %d | ATK %d | DEF %d | SPATK %d | SPDEF %d | SPEED %d",
			text,
			stats.hp,
			stats.atk,
			stats.def,
			stats.spatk,
			stats.spdef,
			stats.speed
		)
	end
	return text
end

function Player:onLook(thing, position, distance)
	local description = "You see " .. thing:getDescription(distance)
	if not thing:isItem() and isSummon(thing) then
		local master = thing:getMaster()
		if master:isPlayer() then
			local item        = master:getUsingBall()
			if not item then self:sendTextMessage(MESSAGE_INFO_DESCR, description) return false end
			local pokeName    = item:getSpecialAttribute("pokeName")
			local pokeBoost   = item:getSpecialAttribute("pokeBoost") or 0

			local heldx = item:getAttribute(ITEM_ATTRIBUTE_HELDX)
			local isHeldBoost = isHeld("boost", heldx)
			if isHeldBoost then
				local tier = HELDS_X_INFO[heldx].tier
				local bonusHeld = HELDS_BONUS["boost"][tier]
				pokeBoost = pokeBoost + bonusHeld
			end

			local avgDmg = (thing:getTotalMagicAttack() + thing:getTotalMeleeAttack()) / 2
			local avgDef = thing:getTotalDefense()
			local levelStr = getPokemonLevelLookText(item, pokeName, true)

			if pokeName ~= nil then				
				description = description .. "\nIt belongs to " .. master:getName()
				description = description .. "\nBoost: " .. pokeBoost 
				description = description .. levelStr
				description = description .. "\nHealth: " .. thing:getHealth() .. " / " .. thing:getTotalHealth() 
				description = description .. "\nDamage: " .. avgDmg
				description = description .. "\nSpeed: " .. thing:getTotalSpeed()
				description = description .. "\nDefense: " .. math.floor(avgDef)
			end
		end
	end

	if thing:isItem() and thing:isPokeball() then
		local pokeName = thing:getSpecialAttribute("pokeName")
		local pokeBoost = thing:getSpecialAttribute("pokeBoost") or 0
		local ownerName = thing:getSpecialAttribute("ownerPokemon")
		local card_system = thing:getSpecialAttribute("pokeCard") or 0
		local regenOrb = thing:getSpecialAttribute("regenOrb") or 0
		local expOrb = thing:getSpecialAttribute("expOrb") or 0
		local cdOrb = thing:getSpecialAttribute("orbCooldown") or 0
		local pokeHealth = tonumber(thing:getSpecialAttribute("pokeHealth")) or 0
		local starFusion = thing:getSpecialAttribute("starFusion") or 0
		local maestria = thing:getSpecialAttribute("maestria") or 0

		local heldx = thing:getAttribute(ITEM_ATTRIBUTE_HELDX)
		local heldy = thing:getAttribute(ITEM_ATTRIBUTE_HELDY)
		local heldu = thing:getAttribute(ITEM_ATTRIBUTE_HELDU)

		local isHeldBoost = isHeld("boost", heldx)
		if isHeldBoost then
			local tier = HELDS_X_INFO[heldx].tier
			local bonusHeld = HELDS_BONUS["boost"][tier]
			pokeBoost = pokeBoost + bonusHeld
		end
		local txt_helds = ""
		if heldx ~= 0 or heldy ~= 0 or heldu ~= 0 then
			txt_helds = "\nHelds:"
		end

		if heldx ~= 0 then
			txt_helds = ("%s\n%s"):format(txt_helds, HELDS_X_INFO[heldx].heldName)
		end

		if heldy ~= 0 then
			txt_helds = ("%s\n%s"):format(txt_helds, HELDS_Y_INFO[heldy].heldName)
		end

		if heldu ~= 0 then
			txt_helds = ("%s\n%s"):format(txt_helds, HELDS_U_INFO[heldu].heldName)
		end

		local regenOrbStr = ""
		local expOrbStr = ""
		local cdOrbStr = ""
		local starStr = ""
		local cardStr = ""
		local maestriaStr = ""
		local healthStr = ""
		local levelStr = getPokemonLevelLookText(thing, pokeName, true)

		if ownerName then
			healthStr = "It belongs to " .. ownerName .. "."
		end

		if starFusion >= 1 then
		starStr = "\nStar: " .. starFusion
		end

		if maestria >= 1 then
			maestriaStr = "\nMaestria: " .. maestria
		end

		if regenOrb >= 1 then
			regenOrbStr = "\nRegeneration Orb"
		end

		if expOrb >= 1 then
			expOrbStr = "\nExperience Orb"
		end

		if cdOrb >= 1 then
			cdOrbStr = "\nCooldown Orb"
		end

		if card_system ~= 0 then
			cardStr = "\nCard: " .. card_system .. " ".. cardsInfo[card_system] .. "% "		
		end
		if pokeHealth <= 0 then
			healthStr = "It is fainted."
		end
		if pokeName ~= nil and healthStr ~= nil then			
			description = string.format("%s\nIt contains a %s.\nBoost: +%s%s\n%s%s%s%s%s%s%s%s", description, pokeName, pokeBoost, levelStr, healthStr, cardStr, regenOrbStr, expOrbStr, cdOrbStr, starStr, maestriaStr, txt_helds)
		end
	end

	if thing:isPlayer() and thing ~= self then
		if thing:getAccountType() == ACCOUNT_TYPE_TUTOR then
			if thing:getSex() == PLAYERSEX_MALE then
				description = string.format("%s He is a Tutor.", description)
			else
				description = string.format("%s She is a Tutor.", description)
			end
		end
	end
	if thing:isPlayer() and thing == self then
		if thing:getAccountType() == ACCOUNT_TYPE_TUTOR then
			description = string.format("%s You are a Tutor.", description)
		end
	end

	if self:getGroup():getAccess() then
		if thing:isCreature() then
			description = description .. string.format("\nLookType: %d", thing:getOutfit().lookType)
		end
		if thing:isItem() then
			description = string.format("%s\nItem ID: %d Client ID:  %d", description, thing:getId(), ItemType(thing:getId()):getClientId())
			local zone = Tile(thing:getPosition()):getZone()
			description = description .. ("\nZone: %s (%d)"):format(zone:getName(), zone:getId())
			local actionId = thing:getActionId()
			if actionId ~= 0 then
				description = string.format("%s, Action ID: %d", description, actionId)
			end

			local uniqueId = thing:getAttribute(ITEM_ATTRIBUTE_UNIQUEID)
			if uniqueId > 0 and uniqueId < 65536 then
				description = string.format("%s, Unique ID: %d", description, uniqueId)
			end

			local itemType = thing:getType()
			local transformEquipId = itemType:getTransformEquipId()
			local transformDeEquipId = itemType:getTransformDeEquipId()
			if transformEquipId ~= 0 then
				description = string.format("%s\nTransforms to: %d (onEquip)", description, transformEquipId)
			elseif transformDeEquipId ~= 0 then
				description = string.format("%s\nTransforms to: %d (onDeEquip)", description, transformDeEquipId)
			end

			local decayId = itemType:getDecayId()
			if decayId ~= -1 then
				description = string.format("%s\nDecays to: %d", description, decayId)
			end
		end

		if thing:isCreature() then
			if thing:isPlayer() then
				description = string.format("%s\nIP: %s.", description, thing:getIp())
			end
		end
	end
	if self:getAccountType() >= ACCOUNT_TYPE_TUTOR then
		local position = thing:getPosition()
		description = string.format(
			"%s\nPosition(%d, %d, %d)",
			description, position.x, position.y, position.z
		)
	end
	if thing:isItem() then
		if thing:isUniqueItem() then
			description = description .. "\nEste item � um unique item. ( N�o pode ser negociado )"
		end
	end

	self:sendTextMessage(MESSAGE_INFO_DESCR, description)
end

function Player:onLookInBattleList(creature, distance)
	local description = "You see " .. creature:getDescription(distance)
	if isSummon(creature) then
		local master = creature:getMaster()
		local pokeName = master:getName()
		if pokeName ~= nil then			
			description = string.format("%s\nIt belongs to %s.", description, master:getName())
		end
	end
	if self:getGroup():getAccess() then
		local str = "%s\nHealth: %d / %d"
		if creature:getMaxMana() > 0 then
			str = string.format("%s, Mana: %d / %d", str, creature:getMana(), creature:getMaxMana())
		end
		description = string.format(str, description, creature:getHealth(), creature:getMaxHealth()) .. "."

		local position = creature:getPosition()
		description = string.format(
			"%s\nPosition: %d, %d, %d",
			description, position.x, position.y, position.z
		)

		if creature:isPlayer() then
			description = string.format("%s\nIP: %s", description, Game.convertIpToString(creature:getIp()))
		end
	end
	


	self:sendTextMessage(MESSAGE_INFO_DESCR, description)
end

function Player:onLookInTrade(partner, item, distance)
	local description = "You see " .. item:getDescription(distance)
	if item:isPokeball() then
		local pokeName = item:getSpecialAttribute("pokeName")
		local pokeBoost = item:getSpecialAttribute("pokeBoost") or 0
		local pokeHealth = tonumber(item:getSpecialAttribute("pokeHealth")) or 0
		local card_system = item:getSpecialAttribute("pokeCard") or 0	
		local regen_orb = item:getSpecialAttribute("regenOrb") or 0
		local exp_orb = item:getSpecialAttribute("expOrb") or 0
		local cd_orb = item:getSpecialAttribute("orbCooldown") or 0 

		local starFusion = item:getSpecialAttribute("starFusion") or 0
		local maestria = item:getSpecialAttribute("maestria") or 0

		local healthStr = ""
		local cardStr = ""
		local regenOrbStr = ""
		local expOrbStr = ""
		local cdOrbStr = ""
		local starStr = ""
		local maestriaStr = ""
		local levelStr = getPokemonLevelLookText(item, pokeName, true)

		if regen_orb >= 1 then
			regenOrbStr = "\nRegeneration Orb"
		end
		if exp_orb >= 1 then
			expOrbStr = "\nExperience Orb"
		end
		if cd_orb >= 1 then 
			cdOrbStr = "\nCooldown Orb"
		end

		if starFusion >= 1 then
		starStr = "\nStar: " .. starFusion
		end

		if maestria >= 1 then
		maestriaStr = "\nMaestria: " .. maestria
		end

		if card_system ~= 0 then -- look helds configurar ainda.
			cardStr = "\nCard: " .. card_system .. " ".. cardsInfo[card_system] .. "% "
		end
		if pokeHealth <= 0 then
			healthStr = "It is fainted."
		end

		if pokeName ~= nil and healthStr ~= nil then			
			description = string.format("%s\nIt contains a %s. Boost: +%s.%s %s %s %s %s %s %s %s", description, pokeName,  pokeBoost, levelStr, healthStr, cardStr, regenOrbStr, expOrbStr, cdOrbStr, starStr, maestriaStr)
		end
	end

	self:sendTextMessage(MESSAGE_INFO_DESCR, description)
end

function Player:onLookInShop(itemType, count)
	return true
end

function Item:isUniqueItem()
	local unique = self:getAttribute(ITEM_ATTRIBUTE_UNIQUE_ITEM)
	if unique ~= 0 then
		return true
	end
	return false
end

function Player:onMoveItem(item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	self:setMarketSellItem(nil)
	local tile = Tile(toPosition)
	if tile then
		if tile:getZoneId() == 2 then
			self:sendTextMessage(MESSAGE_EVENT_DEFAULT, "Voc� n�o pode mover itens para essa zona.")
			return false
		end
		local ground = tile:getGround()
		if ground and ground:getId() == 460 then
			return false
		end
	end

	if self:isDuelingWithNpc() and item:isPokeball() and toPosition.x == 65535 and fromPosition.x ~= 65535 then
		self:sendCancelMessage("Sorry, not possible while in duel.")
		return false
	end

	if item.itemid == 22964 or item.itemid == 22966 then
		self:sendCancelMessage("Voc� n�o pode mover com pok�mon dentro.")
		return false
	end

	if item:isPokeball() then
			local isBallBeingUsed = item:getSpecialAttribute("isBeingUsed")
			if isBallBeingUsed and isBallBeingUsed == 1 then
				self:sendCancelMessage("Sorry, not possible while using Pokemon.")
				doSendPokeTeamByClient(self:getId())
				return false
			end
		elseif item:isContainer() then
			local balls = item:getPokeballsCached()
			for i = 1, #balls do
				local isBallBeingUsed = balls[i]:getSpecialAttribute("isBeingUsed")
				if isBallBeingUsed and isBallBeingUsed == 1 then
					self:sendCancelMessage("Sorry, not possible while using Pokemon.")
					doSendPokeTeamByClient(self:getId())
					return false
				end
			end
		end

		if item:isUniqueItem() then
			if toCylinder:isItem() then
				local topParent = toCylinder:getTopParent()
				local checkPlayer = Player(topParent)
				if not checkPlayer and topParent:getId() ~= 2594 then
					self:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Voc� n�o pode fazer isso com um item �nico!")
					self:getPosition():sendMagicEffect(3)
					return false
				end
			else
				local checkPlayer = Player(toCylinder)
				if not checkPlayer then
					self:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Voc� n�o pode fazer isso com um item �nico!")
					self:getPosition():sendMagicEffect(3)
					return false
				end
			end
		end

		if item:isContainer() then
			local container = Container(item.uid)
			if container and container:isHoldingUniqueItem() then
				if toCylinder:isItem() then
					local topParent = toCylinder:getTopParent()
					local checkPlayer = Player(topParent)
					if not checkPlayer and topParent:getId() ~= 2594 then
						self:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Voc� n�o pode fazer isso com um item �nico!")
						self:getPosition():sendMagicEffect(3)
						return false
					end
				else
					local checkPlayer = Player(toCylinder)
					if not checkPlayer then
						self:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Voc� n�o pode fazer isso com um item �nico!")
						self:getPosition():sendMagicEffect(3)
						return false
					end
				end
			end
		end

	return true
end

function Player:onItemMoved(item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	if item:isPokeball() or item:isContainer() then
		self:normalizePokeballItems()
		doSendPokeTeamByClient(self:getId())
	end
	if item:isPokeball() then
		if toCylinder:isItem() then
			local holderId = toCylinder:getId()
			local holderType = ItemType(holderId)
			if holderType and holderType:isHolder() then
				local creatureId = toCylinder:getAttribute(ITEM_ATTRIBUTE_POKEMONHOLDERCREATUREID)
				if creatureId  and creatureId ~= 0 then
					toCylinder:removeAttribute(ITEM_ATTRIBUTE_POKEMONHOLDERCREATUREID)
					toCylinder:transform(HOLDER_IDS[toCylinder.itemid])
					creatureId = toCylinder:getAttribute(ITEM_ATTRIBUTE_POKEMONHOLDERCREATUREID)
				end
				if not creatureId or creatureId == 0 then
					local checkTile = toCylinder:getParent():isTile()
					if checkTile then
						local spawnName = item:getSpecialAttribute("pokeName")
						local pokeBoost = item:getSpecialAttribute("pokeBoost") or 0
						if PokemonLevel and PokemonLevel.ensureBall then
							PokemonLevel.ensureBall(item, spawnName)
						end
						local pokeLevel = PokemonLevel and PokemonLevel.getLevel and PokemonLevel.getLevel(item) or (item:getSpecialAttribute("pokeLevel") or 1)
						local creatureName = PokemonLevel and PokemonLevel.formatOverheadName and PokemonLevel.formatOverheadName(spawnName, pokeLevel, pokeBoost, true) or (pokeBoost >= 1 and string.format("%s [%d +%d]", spawnName, pokeLevel, pokeBoost) or string.format("%s [%d]", spawnName, pokeLevel))
						local spawnType = MonsterType(spawnName)
						local spawnPosition = toCylinder:getTopParent():getPosition()
						local npc = Game.createNpc("Holder", spawnPosition, false, true, creatureName, true)
						toCylinder:transform(HOLDER_IDS[toCylinder.itemid])
						if npc then
							npc:addCustomIcon("special-24", -25, -7)
							npc:setSpeed(spawnType:getBaseSpeed())
							npc:setNameColor(2)
							item:setAttribute(ITEM_ATTRIBUTE_POKEMONHOLDER, spawnName)
							item:setAttribute(ITEM_ATTRIBUTE_POKEMONHOLDERINFO, creatureName)
							local npcId = npc:getId()
							toCylinder:setIntAttribute(ITEM_ATTRIBUTE_POKEMONHOLDERCREATUREID, npcId)
							npc:setOutfit(spawnType:outfit())
							local updateTile = Tile(spawnPosition)
							updateTile:update()
							local ballKey = getBallKey(item)
							npc:getPosition():sendMagicEffect(balls[ballKey].effectRelease)
						end
					end
				end
			end
		end
		if fromCylinder:isItem() then
			local senderId = fromCylinder:getId()
			local holderType = ItemType(senderId)
			if holderType and holderType:isHolder() then
				local removeCreatureId = fromCylinder:getAttribute(ITEM_ATTRIBUTE_POKEMONHOLDERCREATUREID)
				if removeCreatureId then
					local removeCreature = Creature(removeCreatureId)
					if removeCreature then
						local effectPosition = removeCreature:getPosition()
						if removeCreature then
							item:removeAttribute(ITEM_ATTRIBUTE_POKEMONHOLDER)
							item:removeAttribute(ITEM_ATTRIBUTE_POKEMONHOLDERINFO)
							removeCreature:remove()
							fromCylinder:transform(HOLDER_IDS[fromCylinder.itemid])
							local ballKey = getBallKey(item)
							effectPosition:sendMagicEffect(balls[ballKey].effectRelease)
							fromCylinder:removeAttribute(ITEM_ATTRIBUTE_POKEMONHOLDERCREATUREID)
						end
					end
				end
			end
		end
	end
	local holderType = ItemType(item:getId())
	if holderType and holderType:isHolder() then
		if toPosition.x == CONTAINER_POSITION then
			local removeCreatureId = item:getAttribute(ITEM_ATTRIBUTE_POKEMONHOLDERCREATUREID)
			if removeCreatureId then
				local removeCreature = Creature(removeCreatureId)
				if removeCreature then
					local effectPosition = removeCreature:getPosition()
					local container = Container(item.uid)
					if not container then
						return true
					end
					
					local containerItems = container:getItems()
					if not containerItems then
						return true
					end
					local pokeballItem = nil
					for _, containerItem in pairs (containerItems) do
						if containerItem:isPokeball() then
							pokeballItem = containerItem
							break
						end
					end
					if not pokeballItem then
						return true
					end
					pokeballItem:removeAttribute(ITEM_ATTRIBUTE_POKEMONHOLDER)
					pokeballItem:removeAttribute(ITEM_ATTRIBUTE_POKEMONHOLDERINFO)
					removeCreature:remove()
					local ballKey = getBallKey(pokeballItem)
					effectPosition:sendMagicEffect(balls[ballKey].effectRelease)
					item:removeAttribute(ITEM_ATTRIBUTE_POKEMONHOLDERCREATUREID)
				end
			end
		end
	end
end

function Player:onMoveCreature(creature, fromPosition, toPosition)
 	-- self:sendCancelMessage("Voc� n�o pode fazer isso.")
	return true
end

function Player:onTurn(direction)
	if hasSummons(self) then
		local summon = self:getSummons()[1]
		local summonDirection = summon:getDirection()
		if summonDirection == direction then return true end
		summon:setDirection(direction)
	end
	return true
end

function Player:onTradeRequest(target, item)
	self:setMarketSellItem(nil)
	if self:isDuelingWithNpc() and item:isPokeball() then
		self:sendCancelMessage("Sorry, not possible while in duel.")
		return false
	end
	if item:isPokeball() then
		if item:isBeingUsed() then
			self:sendCancelMessage("Sorry, not possible while using pokeball.")
			return false
		end
	end
	if item:isContainer() then
		local pokeballs = item:getPokeballsCached()
		for i = 1, #pokeballs do
			if pokeballs[i]:isBeingUsed() then
				self:sendCancelMessage("Sorry, not possible while using pokeball.")
				return false
			end
		end
	end

	if item:isUniqueItem() then
		self:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Voc� n�o pode fazer isso com um item �nico!")
		self:getPosition():sendMagicEffect(3)
		return false
	end

	if item:isContainer() then
		local container = Container(item.uid)
		if container and container:isHoldingUniqueItem() then
			self:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Voc� n�o pode fazer isso com um item �nico!")
			self:getPosition():sendMagicEffect(3)
			return false
		end
	end

	return true
end

function Player:onTradeAccept(target, item, targetItem)
	addEvent(function(playerId)
		doSendPokeTeamByClient(playerId)
	end, 100, target:getId())

	addEvent(function(playerId)
		doSendPokeTeamByClient(playerId)
	end, 100, self:getId())

	self:dumpLogTrade("Trade", item, target)
	target:dumpLogTrade("Trade", targetItem, self)

	return true
end

local soulCondition = Condition(CONDITION_SOUL, CONDITIONID_DEFAULT)
soulCondition:setTicks(4 * 60 * 1000)
soulCondition:setParameter(CONDITION_PARAM_SOULGAIN, 1)

local function useStamina(player)
	local staminaMinutes = player:getStamina()
	if staminaMinutes == 0 then
		return
	end

	local playerId = player:getId()
	local currentTime = os.time()
	if nextUseStaminaTime[playerId] == nil then
		return
	end
	local timePassed = currentTime - nextUseStaminaTime[playerId]
	if timePassed <= 0 then
		return
	end

	if timePassed > 60 then
		if staminaMinutes > 2 then
			staminaMinutes = staminaMinutes - 2
		else
			staminaMinutes = 0
		end
		nextUseStaminaTime[playerId] = currentTime + 120
	else
		staminaMinutes = staminaMinutes - 1
		nextUseStaminaTime[playerId] = currentTime + 60
	end
	player:setStamina(staminaMinutes)
end

local function clampExperienceValue(value, minValue, maxValue)
	value = tonumber(value) or minValue
	if value < minValue then
		return minValue
	end
	if value > maxValue then
		return maxValue
	end
	return value
end

local function isMonsterExperienceSource(source)
	if not source or not source.isMonster then
		return false
	end
	local ok, result = pcall(function()
		return source:isMonster()
	end)
	return ok and result == true
end

local function getMonsterWildLevel(source)
	if not source or not source.getLevel then
		return 1
	end
	local ok, level = pcall(function()
		return source:getLevel()
	end)
	return math.max(1, math.floor(tonumber(ok and level or 1) or 1))
end

local function getMonsterBaseExperience(source, exp, rawExp)
	local baseExp = math.max(1, tonumber(exp) or 0, tonumber(rawExp) or 0)
	if source and source.getExperience then
		local ok, monsterExp = pcall(function()
			return source:getExperience()
		end)
		if ok then
			baseExp = math.max(baseExp, tonumber(monsterExp) or 0)
		end
	end
	return baseExp
end

local function getLevelScaledMonsterExperience(player, source, exp, rawExp)
	if not isMonsterExperienceSource(source) then
		return exp, 1
	end

	local wildLevel = getMonsterWildLevel(source)
	local playerLevel = math.max(1, player:getLevel())
	local baseExp = getMonsterBaseExperience(source, exp, rawExp)
	local wildLevelMultiplier = 1 + ((wildLevel - 1) * 0.07)
	local playerLevelMultiplier = clampExperienceValue((wildLevel + 30) / (playerLevel + 30), 0.25, 1.35)

	return math.max(1, math.floor(baseExp * wildLevelMultiplier * playerLevelMultiplier)), wildLevel
end

local function getPlayerExperiencePokeball(player)
	local pokeball = player:getUsingBall()
	if pokeball then
		return pokeball
	end

	local slotBall = player:getSlotItem(CONST_SLOT_AMMO)
	if slotBall and slotBall.isPokeball and slotBall:isPokeball() and slotBall.isBeingUsed and slotBall:isBeingUsed() then
		return slotBall
	end

	if not player.getPokeballsCached then
		return nil
	end

	local ok, pokeballs = pcall(function()
		return player:getPokeballsCached()
	end)
	if not ok or not pokeballs then
		return nil
	end

	for i = 1, #pokeballs do
		local ball = pokeballs[i]
		if ball and ball.isPokeball and ball:isPokeball() and ball.isBeingUsed and ball:isBeingUsed() then
			return ball
		end
	end
	return nil
end

local function getPokemonExperienceFromKill(player, pokeball, wildLevel, monsterBaseExp)
	local share = 0.12
	local maxGain = PokemonLevel and PokemonLevel.CONFIG and PokemonLevel.CONFIG.maxExpGainPerKill or 5000
	local pokemonLevel = 1
	if PokemonLevel and PokemonLevel.getLevel then
		pokemonLevel = PokemonLevel.getLevel(pokeball)
	else
		pokemonLevel = tonumber(pokeball:getSpecialAttribute("pokeLevel")) or 1
	end

	local playerLevel = math.max(1, player:getLevel())
	local baseGain = math.floor((tonumber(monsterBaseExp) or 0) * share)
	local wildLevelMultiplier = 1 + ((wildLevel - 1) * 0.06)
	local pokemonLevelMultiplier = clampExperienceValue((wildLevel + 20) / (pokemonLevel + 20), 0.25, 1.80)
	local ownerLevelBuff = 1 + clampExperienceValue((playerLevel - pokemonLevel) / 2000, 0, 0.20)
	local gain = math.floor(math.max(1, baseGain) * wildLevelMultiplier * pokemonLevelMultiplier * ownerLevelBuff)
	return math.max(1, math.min(gain, maxGain))
end

function Player:onGainExperience(source, exp, rawExp)
	--print(source, exp, rawExp)
	local multiplier = 0.5 -- how many times more exp than players a monster will get

	if not source then
		return exp
	end
	
	if tonumber(getGlobalStorageValue(1)) > os.time() then
		exp = exp * 2
	end

	local pokemonMonsterBaseExp = getMonsterBaseExperience(source, exp, rawExp)
	local wildLevel
	exp, wildLevel = getLevelScaledMonsterExperience(self, source, exp, rawExp)

	-- Soul regeneration
	local vocation = self:getVocation()
	if self:getSoul() < vocation:getMaxSoul() and exp >= self:getLevel() then
		soulCondition:setParameter(CONDITION_PARAM_SOULTICKS, vocation:getSoulGainTicks() * 1000)
		self:addCondition(soulCondition)
	end

	-- Apply experience stage multiplier

	local stages = {
		[1] = 7, -- 30
		[2] = 5.6, -- 50
		[3] = 4.48, -- 80
		[4] = 3.584, -- 100
		[5] = 2.8672, -- 120
		[6] = 2.29376, -- 150
		[7] = 1.835008, -- 180 
		[8] = 1.4680064, -- 200 
		[9] = 0.86472015, -- 250
		[10] = 0.605304105, -- 300
		[11] = 0.4237128735, -- 325
		[12] = 0.29659901145, -- 350
		[13] = 0.207619308015, -- 400
		[14] = 0.1453335156105, -- 450
		[15] = 0.10173346092735, -- 475
		[16] = 0.071213422649145, -- 500
		[17] = 0.0498493958544015, -- 550
		[18] = 0.03489457709808105, -- 575
		[19] = 0.024426203968656735, -- 600
		[20] = 0.017098342778059715, -- 650
		[21] = 0.0119688399446418005, -- 700
		[22] = 0.00837818796124926, -- 750
		[23] = 0.005864731572874482, -- 800


	}

    local stage = Game.getExperienceStage(self:getLevel()) or 1
    local stageMultiplier = stages[stage] or 1
    exp = exp * stageMultiplier

	if self:isVipPlus() then
		exp = math.floor(exp * 1.35)
	end

	-- Stamina modifier
	if configManager.getBoolean(configKeys.STAMINA_SYSTEM) then
		useStamina(self)

		local staminaMinutes = self:getStamina()
		if staminaMinutes > 2400 and self:isPremium() then
			exp = exp * 1.5
		elseif staminaMinutes <= 840 then
			exp = exp * 0.5
		end
	end

	if self:getStorageValue(45144) - os.time() > 1 then
		expBonusItem = exp * self:getStorageValue(45145) / 100
		Game.sendAnimatedText(self:getPosition(), "Bonus: "..expBonusItem, 21)
		exp = exp + expBonusItem
	end

	local pokeball = getPlayerExperiencePokeball(self)
	if pokeball then
		local heldx = pokeball:getAttribute(ITEM_ATTRIBUTE_HELDX)
		local type = "experience"
		local isHeldExp = isHeld(type, heldx)
		if isHeldExp then
			local tier = HELDS_X_INFO[heldx].tier
			local bonusHeld = HELDS_BONUS[type][tier]
			exp = exp + math.floor((exp * bonusHeld) / 100)
		end
	end

	if pokeball and PokemonLevel and PokemonLevel.addExp then
		local pokeName = pokeball:getSpecialAttribute("pokeName") or "Pokemon"
		if PokemonLevel.ensureBall then
			PokemonLevel.ensureBall(pokeball, pokeName)
		end
		local pokemonExpGain = getPokemonExperienceFromKill(self, pokeball, wildLevel or 1, pokemonMonsterBaseExp)
		local gain, oldLevel, newLevel = PokemonLevel.addExp(pokeball, pokemonExpGain)
		if gain > 0 then
			self:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, pokeName .. " ganhou " .. gain .. " exp.")
			if newLevel > oldLevel then
				self:sendTextMessage(MESSAGE_EVENT_ADVANCE, pokeName .. " avancou para o nivel " .. newLevel .. ".")

				local summon = self:getSummon()
				if summon then
					local oldMaxHealth = summon:getMaxHealth()
					local currentHealth = summon:getHealth()
					local newMaxHealth = summon:getTotalHealth()
					summon:setMaxHealth(newMaxHealth)
					if oldMaxHealth > 0 then
						summon:setHealth(math.max(1, math.floor((currentHealth / oldMaxHealth) * newMaxHealth)))
					end
					summon:changeSpeed(-summon:getSpeed() + summon:getTotalSpeed())
					pokeball:setSpecialAttribute("pokeHealth", summon:getHealth())
					local pokeBoost = pokeball:getSpecialAttribute("pokeBoost") or 0
					local overheadName = PokemonLevel.formatOverheadName and PokemonLevel.formatOverheadName(pokeName, newLevel, pokeBoost, true)
					if overheadName then
						summon:setNickname(overheadName)
					end
				end
			end
			doSendPokeTeamByClient(self:getId())
		end
	end


	return exp
end

function Player:onLoseExperience(exp)
	return exp
end

function Player:onGainSkillTries(skill, tries)
	if APPLY_SKILL_MULTIPLIER == false then
		return tries
	end

	if skill == SKILL_MAGLEVEL then
		return tries * configManager.getNumber(configKeys.RATE_MAGIC)
	end
	return tries * configManager.getNumber(configKeys.RATE_SKILL)
end

-- function Player:onReport(message, position, category)

	-- local name = self:getName()
	-- local file = io.open("data/reports/" .. name .. " report.txt", "a")

	-- if not file then
		-- self:sendTextMessage(MESSAGE_EVENT_DEFAULT, "There was an error when processing your report, please contact a gamemaster.")
		-- return true
	-- end

	-- io.output(file)
	-- io.write("------------------------------\n")
	-- io.write("Name: " .. name)
	-- if category == BUG_CATEGORY_MAP then
		-- io.write(" [Map position: " .. position.x .. ", " .. position.y .. ", " .. position.z .. "]")
	-- end
	-- local playerPosition = self:getPosition()
	-- io.write(" [Player Position: " .. playerPosition.x .. ", " .. playerPosition.y .. ", " .. playerPosition.z .. "]\n")
	-- io.write("Comment: " .. message .. "\n")
	-- io.close(file)

	-- self:sendTextMessage(MESSAGE_EVENT_DEFAULT, "Your report has been sent to " .. configManager.getString(configKeys.SERVER_NAME) .. ".")
	-- return true
-- end

function Player:onLostConnection()
	if self:isHosting() then
		self:stopHosting(true)
	end
	if self:getSpectating() then
		self:stopSpectate()
	end
end
