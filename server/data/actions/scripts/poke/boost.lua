local buttonMachineId_on = 26694
local buttonMachineId_off = 26693
local ballMachineId_on = 26695
local ballMachineId_off = 26696
local stoneMachineId_on = 26697
local stoneMachineId_off = 26698

function necessaryStones(boostLevel)
	return math.ceil(1.3 * boostLevel)
end

function doChangeBackBoostMachine(buttonMachinePos, ballMachinePos, stoneMachinePos)
	local buttonTile = Tile(buttonMachinePos)
	local ballTile   = Tile(ballMachinePos)
	local stoneTile  = Tile(stoneMachinePos)
	if not buttonTile or not ballTile or not stoneTile then return end

	local button = buttonTile:getItemById(buttonMachineId_on)
	local ball   = ballTile:getItemById(ballMachineId_on)
	local stone  = stoneTile:getItemById(stoneMachineId_on)

	if button then button:transform(buttonMachineId_off) end
	if ball   then ball:transform(ballMachineId_off)     end
	if stone  then stone:transform(stoneMachineId_off)   end
end

-- Retrieves the item placed ON TOP of a machine slot tile (the pokeball or stone
-- that the player dropped there). Falls back to the first item in the tile's list.
local function getMachineSlotItem(tilePos, slotItemId)
	local tile = Tile(tilePos)
	if not tile then return nil end

	-- Try to get the topmost item; skip the slot machine item itself.
	local topItem = tile:getTopTopItem()
	if topItem and topItem:getId() ~= slotItemId then
		return topItem
	end

	-- Fallback: iterate the tile's item list for a non-machine item.
	local items = tile:getItems()
	if items then
		for _, it in ipairs(items) do
			if it:getId() ~= slotItemId then
				return it
			end
		end
	end
	return nil
end

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local buttonMachinePos = Position(fromPosition.x, fromPosition.y, fromPosition.z)
	local ballMachinePos   = Position(fromPosition.x + 1, fromPosition.y, fromPosition.z)
	local stoneMachinePos  = Position(fromPosition.x - 1, fromPosition.y, fromPosition.z)

	local buttonTile = Tile(buttonMachinePos)
	local ballTile   = Tile(ballMachinePos)
	local stoneTile  = Tile(stoneMachinePos)

	local buttonMachine = buttonTile and buttonTile:getItemById(buttonMachineId_off)
	local ballMachine   = ballTile   and ballTile:getItemById(ballMachineId_off)
	local stoneMachine  = stoneTile  and stoneTile:getItemById(stoneMachineId_off)

	if not (buttonMachine and ballMachine and stoneMachine) then
		print(string.format(
			"[BoostMachine] WARNING: machine items not found at position %d,%d,%d | button=%s ball=%s stone=%s",
			fromPosition.x, fromPosition.y, fromPosition.z,
			tostring(buttonMachine ~= nil), tostring(ballMachine ~= nil), tostring(stoneMachine ~= nil)
		))
		player:sendCancelMessage("Sorry, not possible. This problem was reported.")
		return true
	end

	-- Retrieve the pokeball and stone placed on the machine tiles.
	local ball  = getMachineSlotItem(ballMachinePos, ballMachineId_off)
	local stone = getMachineSlotItem(stoneMachinePos, stoneMachineId_off)

	if not (ball and stone and ball:isPokeball()) then
		player:sendCancelMessage("Sorry, not possible. Please use the correct items.")
		return true
	end

	local pokeName = ball:getSpecialAttribute("pokeName")
	if not pokeName then
		player:sendCancelMessage("Sorry, not possible. The pokeball has no pokemon.")
		return true
	end

	local monsterType = MonsterType(pokeName)
	if not monsterType then
		player:sendCancelMessage("Sorry, not possible. Unknown pokemon species.")
		return true
	end

	local function toRaceStone(race)
		local map = {
			psychic = "enigma", grass = "leaf", normal = "heart", electric = "thunder",
			poison = "venom", flying = "feather", ground = "earth", bug = "cocoon",
			dark = "darkness", ghost = "darkness", steel = "metal", fairy = "heart",
			fighting = "punch", dragon = "crystal",
		}
		return map[race] or race
	end

	local race1 = toRaceStone(monsterType:getRaceName())
	local race2 = toRaceStone(monsterType:getRace2Name())

	local stoneName  = (race1 == "metal" and "metal coat" or (race1 .. " stone"))
	local stone2Name = (race2 == "metal" and "metal coat" or (race2 .. " stone"))

	local stoneLower = stone:getName():lower()
	if stoneLower ~= stoneName and stoneLower ~= stone2Name then
		local word = stoneName
		if race2 and race2 ~= "none" and race2 ~= race1 then
			word = word .. " or " .. stone2Name
		end
		player:sendCancelMessage("Sorry, not possible. You need " .. word .. " to boost this pokemon.")
		return true
	end

	local maxBoostValue = PokemonLevel and PokemonLevel.CONFIG and PokemonLevel.CONFIG.progression and PokemonLevel.CONFIG.progression.maxBoost or maxBoost
	local currentBoost = PokemonLevel and PokemonLevel.getBoost and PokemonLevel.getBoost(ball, false) or (ball:getSpecialAttribute("pokeBoost") or 0)
	if currentBoost >= maxBoostValue then
		player:sendCancelMessage("Sorry, not possible. Your pokemon is at the maximum boost.")
		return true
	end

	local newBoost = currentBoost + 1
	local neededStones = necessaryStones(newBoost)
	if not stone:remove(neededStones) then
		player:sendCancelMessage("Sorry, not possible. You need " .. neededStones .. " stones to boost this pokemon.")
		return true
	end

	-- Apply boost and animate the machine.
	if PokemonLevel and PokemonLevel.setBoost then
		PokemonLevel.setBoost(ball, newBoost)
	else
		ball:setSpecialAttribute("pokeBoost", math.min(newBoost, maxBoostValue))
	end
	buttonMachine:transform(buttonMachineId_on)
	ballMachine:transform(ballMachineId_on)
	stoneMachine:transform(stoneMachineId_on)
	player:sendTextMessage(MESSAGE_INFO_DESCR, "Boost applied! " .. pokeName .. " is now at boost +" .. (PokemonLevel and PokemonLevel.getBoost and PokemonLevel.getBoost(ball, false) or newBoost) .. ".")
	addEvent(doChangeBackBoostMachine, 3000, buttonMachinePos, ballMachinePos, stoneMachinePos)
	return true
end
