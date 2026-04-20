local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid) npcHandler:onCreatureAppear(cid) end

function onCreatureDisappear(cid) npcHandler:onCreatureDisappear(cid) end

function onCreatureSay(cid, type, msg) npcHandler:onCreatureSay(cid, type, msg) end

function onThink() npcHandler:onThink() end

local function creatureGreetCallback(cid, message)
	if message == nil then
		return true
	end
	local player = Player(cid)
	local playerHealth = player:getHealth()
	local playerMaxHealth = player:getMaxHealth()

	if playerHealth < playerMaxHealth then
		player:addHealth(playerMaxHealth - playerHealth)
	end

	if hasSummons(player) then
		local summon = player:getSummons()[1]
		summon:addHealth(-summon:getHealth() + summon:getMaxHealth())
	end

	local pokeballs = player:getPokeballsCached()
	for i = 1, #pokeballs do
		local ball = pokeballs[i]
		local ballKey = getBallKey(ball)

		local summonName = ball:getSpecialAttribute("pokeName")
		local monsterType = MonsterType(summonName)
		if monsterType then
			if PokemonLevel and PokemonLevel.ensureBall then
				PokemonLevel.ensureBall(ball, summonName)
			end
			local maxHealth = monsterType:getTotalHealth(ball, player)
			ball:setSpecialAttribute("pokeHealth", maxHealth)
		end

		local isBallBeingUsed = ball:getSpecialAttribute("isBeingUsed")
		if isBallBeingUsed ~= 1 then
			applyPokeballStateVisual(ball, "stored", ballKey)
		end
	end
		
	local message = "Todos os seus Pok?mons est?o completamente recuperados e prontos para a pr?xima aventura!"
	local closeTime = 2
	doSendCallForNpc(getNpcCid(), player, "HiNpc", "#ff768e", nil, message, nil, closeTime)
	
	selfSay('Take care yourself.', cid)
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	doSendPokeTeamByClient(player)
	return false
end

npcHandler:setCallback(CALLBACK_GREET, creatureGreetCallback)
npcHandler:addModule(FocusModule:new())
