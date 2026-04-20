local delay = 12*60*60
local savedOutfitStorages = {50000, 50001, 50002, 50003, 50004}

local function refreshWalkCache(player)
	pcall(function()
		player:refreshWalkCache()
	end)
end

local function clearUsedPokeballs(player)
	local pokeballs = player:getPokeballsCached() or {}
	for i = 1, #pokeballs do
		local ball = pokeballs[i]
		ball:setSpecialAttribute("isBeingUsed", 0)

		local ballKey = getBallKey(ball)
		applyPokeballStateVisual(ball, "stored", ballKey)
	end
	player:setUsingPokeball(false)
end

local function clearSummons(player)
	while hasSummons(player) do
		if not doRemoveSummon(player:getId(), false, nil, false) then
			local summons = player:getSummons()
			if not summons or not summons[1] then
				break
			end
			summons[1]:remove()
		end
	end
end

local function resetOutfitAndMovement(player)
	player:removeCondition(CONDITION_OUTFIT)
	player:setSpeed(player:getBaseSpeed())

	local defaultLookType = player:getSex() == PLAYERSEX_FEMALE and (femaleOutfit or 3116) or (maleOutfit or 3119)
	player:setOutfit({
		lookType = defaultLookType,
		lookHead = 0,
		lookBody = 0,
		lookLegs = 0,
		lookFeet = 0,
	})

	for i = 1, #savedOutfitStorages do
		player:setStorageValue(savedOutfitStorages[i], -1)
	end
end

function onSay(player, words, param)
	local timeSinceLast = os.time() - player:getStorageValue(storageDelayDesbugar)
	if timeSinceLast < delay then
		player:sendCancelMessage("Voce precisa aguardar " .. delay - timeSinceLast .. " segundos para desbugar seu char novamente.")
		return false		
	end

	if player:isOnDive() then
		player:setStorageValue(storageDive, -1)
		player:removeCondition(CONDITION_OUTFIT)
	end

	if player:isDuelingWithNpc() then
		player:unsetDuelWithNpc()
	end

	player:setStorageValue(storageFly, -1)
	player:setStorageValue(storageSurf, -1)
	player:setStorageValue(storageSurfEffect, -1)
	player:setStorageValue(storageRide, -1)
	player:setStorageValue(storageBike, -1)
	player:setStorageValue(storageDive, -1)
	clearSummons(player)
	clearUsedPokeballs(player)
	resetOutfitAndMovement(player)
	refreshWalkCache(player)

	player:teleportTo(player:getTown():getTemplePosition())
	player:setStorageValue(storageDelayDesbugar, os.time())
	doSendPokeTeamByClient(player:getId())

	return false
end
