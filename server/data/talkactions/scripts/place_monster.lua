local function trim(value)
	value = tostring(value or "")
	value = value:gsub("^%s+", "")
	value = value:gsub("%s+$", "")
	return value
end

local function normalizeKey(value)
	return trim(value):lower():gsub("%s+", "")
end

function onSay(player, words, param)
	if not player:getGroup():getAccess() then
		return true
	end

	if player:getAccountType() < ACCOUNT_TYPE_GOD then
		return false
	end
	local parts = param:split(",")
	local monsterName = trim(parts[1])
	local quantity = 1
	local level = 0
	local boost = 0
	local outfitConfig = {
		head = 0,
		body = 0,
		legs = 0,
		feet = 0,
		addons = 0,
	}

	local positional = {}
	for i = 2, #parts do
		local token = trim(parts[i])
		if token ~= "" then
			local key, value = token:match("^([^=]+)=(.+)$")
			if key then
				key = normalizeKey(key)
				value = trim(value)
				if key == "qtd" or key == "qty" or key == "quantidade" or key == "count" then
					quantity = tonumber(value) or quantity
				elseif key == "level" or key == "lv" then
					level = tonumber(value) or level
				elseif key == "boost" then
					boost = tonumber(value) or boost
				elseif key == "head" then
					outfitConfig.head = tonumber(value) or outfitConfig.head
				elseif key == "body" then
					outfitConfig.body = tonumber(value) or outfitConfig.body
				elseif key == "legs" then
					outfitConfig.legs = tonumber(value) or outfitConfig.legs
				elseif key == "feet" then
					outfitConfig.feet = tonumber(value) or outfitConfig.feet
				elseif key == "addons" then
					outfitConfig.addons = tonumber(value) or outfitConfig.addons
				end
			else
				positional[#positional + 1] = token
			end
		end
	end

	if #positional >= 1 then
		quantity = tonumber(positional[1]) or quantity
	end
	if #positional >= 2 then
		outfitConfig.head = tonumber(positional[2]) or outfitConfig.head
	end
	if #positional >= 3 then
		outfitConfig.body = tonumber(positional[3]) or outfitConfig.body
	end
	if #positional >= 4 then
		outfitConfig.legs = tonumber(positional[4]) or outfitConfig.legs
	end
	if #positional >= 5 then
		outfitConfig.feet = tonumber(positional[5]) or outfitConfig.feet
	end
	if #positional >= 6 then
		outfitConfig.addons = tonumber(positional[6]) or outfitConfig.addons
	end

	local position = player:getPosition()
	for i = 1, math.max(1, math.floor(quantity)) do
		local monster = Game.createMonster(monsterName, position, false, true, level, boost)

		if monster == nil then
			player:sendCancelMessage(string.format("Monster '%s' not found.", monsterName))
			return false
		end

		local outfit = monster:getOutfit()
		local newOutfit = {
			lookType = outfit.lookType,
			lookHead = outfitConfig.head,
			lookBody = outfitConfig.body,
			lookLegs = outfitConfig.legs,
			lookFeet = outfitConfig.feet,
			lookAddons = outfitConfig.addons
		}

		monster:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		monster:setOutfit(newOutfit)
	end
	return false
end
