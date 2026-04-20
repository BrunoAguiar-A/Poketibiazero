function Monster:onSpawn(position, startup, artificial)
	self:setRankIcon()

	-- Wild Pokemon level randomization (only for wild, no master)
	if not self:getMaster() and PokemonLevel and PokemonLevel.getWildLevelRange then
		local minLvl, maxLvl = PokemonLevel.getWildLevelRange(self:getName(), self:getType())
		if minLvl and maxLvl and maxLvl >= minLvl then
			self:setLevel(math.random(minLvl, maxLvl))
		end

		local maxHealth = self:getTotalHealth()
		if maxHealth and maxHealth > 0 then
			self:setMaxHealth(maxHealth)
			self:setHealth(maxHealth)
		end
	end

	return true
end

function Monster:onDropLoot(corpse)
	local lootList = {}
	if corpse and not isSummon(self) then
		local level = self:getLevel()
		if level then
			corpse:setCustomAttribute("level", level)
			corpse:setSpecialAttribute("corpseLevel", level)
		end
	end

	local zoneId = self:getZoneId()
	local player = Player(corpse:getCorpseOwner())
	if not player then return end
	local pid = player:getId()
	local mType = self:getType()
	if player and player:getStamina() > 840 then
		local monsterLoot = mType:getLoot()
		local luckyBonus = false
		for i = 1, #monsterLoot do
			local item = corpse:createLootItem(monsterLoot[i], zoneId, player)
			if not item.bool then
				print('[Warning] DropLoot:', 'Could not add loot item to corpse.')
			end
			if item.isFromLucky then
				luckyBonus = true
			end
		end

		if player then
			local msgEvent = ""
			if ACTIVE_ZONE_EVENT and ACTIVE_ZONE_TYPE == "loot" and ACTIVE_ZONE_EVENT_ID == zoneId then
				msgEvent = " [B�nus Zone " .. ACTIVE_ZONE_EVENT_RATE_LOOT .. "x]"
			end
			local luckMsg = "[ LUCKY BONUS ]"
			local text = ("Loot of %s: %s%s"):format(mType:getNameDescription(), corpse:getContentDescription(), msgEvent)
			if luckyBonus then
				text = text .. " " .. luckMsg
			end
			local party = player:getParty()
			if party then
				party:broadcastPartyLoot(text)
			else
				player:sendTextMessage(MESSAGE_LOOT, text)
			end
		end
	else
		local text = ("Loot of %s: nothing (due to low stamina)"):format(mType:getNameDescription())
		local party = player:getParty()
		if party then
			party:broadcastPartyLoot(text)
		else
			player:sendTextMessage(MESSAGE_LOOT, text)
		end
	end

    local items = corpse:getItems()
    for _, item in pairs(items) do
		local itemEffect = CONST_RARITIES[item:getId()]
		if itemEffect then
			self:getPosition():sendMagicEffect(CONST_RARITIES_EFFECT[itemEffect])
		end
	end

	for _, item in pairs(items) do
		local itemType = ItemType(item:getId())
		local itemData = {id = itemType:getClientId(), count = item:getCount(), lootedBy = pid}
		table.insert(lootList, itemData)
		if player:getStorageValue(AUTOLOOT_ALL_ENABLED) ~= 1 then
			for i = AUTOLOOT_STORAGE_START, AUTOLOOT_STORAGE_END do
				if player:getStorageValue(i) == item:getId() then
					if not item:moveTo(player) then
        				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Voc� n�o tem capacidade, ent�o o loot foi deixado no corpo.")
        				break
					end
				end
			end
		else
			if not item:moveTo(player) then
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Voc� n�o tem capacidade, ent�o o loot foi deixado no corpo.")
				break
			end
        end
    end
	player:sendExtendedOpcode(58, json.encode({tabela = lootList, creature = pid}))
end

function Monster:onCheckImmunity(combatType, conditionType)
	return hasEvent.onCheckImmunity and Event.onCheckImmunity(self, combatType, conditionType)
end
