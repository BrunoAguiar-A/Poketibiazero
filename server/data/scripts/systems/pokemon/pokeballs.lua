if type(POKEBALL_SPECIES_IDS) ~= "table" or type(applyPokeballStateVisual) ~= "function" then
    dofile("data/lib/pokeBallSpecies.lua")
end

CONST_EXHAUST_POKEBALL = 500

local function isOwnedPokeball(player, ball)
    return type(player) == "userdata" and type(ball) == "userdata" and ball:getTopParent() == player
end

function Player.canSummonPokemon(self, ball)
    local pokeName = ball:getSpecialAttribute("pokeName") or ball:getCustomAttribute("pokeName")
    if pokeName then
        if PokemonLevel and PokemonLevel.ensureBall then
            PokemonLevel.ensureBall(ball, pokeName)
        end
        local pokemonType = MonsterType(pokeName)
        if pokemonType then
            local minLevel = pokemonType:minimumLevel()
            local pLevel = self:getLevel()
            if pLevel < minLevel then
                self:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "You need to be at least level " .. minLevel .. " to summon this pokemon.")
                return false
            end
        end
    end
    return true
end

local action = Action()
function action.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local timeNow = os.mtime()
    if timeNow < player:getLastTimePokeballUse() then
        return true
    end
    if player:isSummonBlocked() then return true end

    player:setLastTimePokeballUse(timeNow + CONST_EXHAUST_POKEBALL)
    local ballKey = getBallKey(item)

    if hasSummons(player) then
        local usingBall = player:getUsingBall()
        if not usingBall then return true end

        if usingBall ~= item then
            local usingBallKey = getBallKey(usingBall)
            doRemoveSummon(player:getId(), balls[usingBallKey].effectRelease, false, true, balls[usingBallKey].missile)
            player:setUsingPokeball(false)
            applyPokeballStateVisual(usingBall, "stored", usingBallKey)

            if item:getTopParent() ~= player then return true end
            if not player:canSummonPokemon(item) then return true end

            ballKey = getBallKey(item)
            player:setUsingPokeball(item)
            item:setSpecialAttribute("isBeingUsed", 1)
            local _, transformedBall = applyPokeballStateVisual(item, "released", ballKey)
            if transformedBall then
                player:setUsingPokeball(transformedBall)
                item = transformedBall
            end
            doReleaseSummon(player:getId(), player:getPosition(), balls[ballKey].effectRelease, true, balls[ballKey].missile)
            return true
        end

        doRemoveSummon(player:getId(), balls[ballKey].effectRelease, false, true, balls[ballKey].missile)
        player:setUsingPokeball(false)
        applyPokeballStateVisual(item, "stored", ballKey)
    else
        if not player:canSummonPokemon(item) then return true end
        if item:getTopParent() == player then
            player:setUsingPokeball(item)

            item:setSpecialAttribute("isBeingUsed", 1)
            local _, transformedBall = applyPokeballStateVisual(item, "released", ballKey)
            if transformedBall then
                player:setUsingPokeball(transformedBall)
                item = transformedBall
            end
            doReleaseSummon(player:getId(), player:getPosition(), balls[ballKey].effectRelease, true, balls[ballKey].missile)
        else
            if item:getSpecialAttribute("isBeingUsed") == 1 then
                applyPokeballStateVisual(item, "stored", ballKey)
                item:setSpecialAttribute("isBeingUsed", 0)
            end
        end
    end
    return true
end

for _, pokeball in pairs(balls) do
    action:id(pokeball.usedOn)
    action:id(pokeball.usedOff)
end

if POKEBALL_SPECIES_IDS then
    for itemId in pairs(POKEBALL_SPECIES_IDS) do
        action:id(itemId)
    end
end

action:register()

local talkaction = TalkAction("!p")

function talkaction.onSay(player, words, param)
    local timeNow = os.mtime()
    if timeNow < player:getLastTimePokeballUse() then
        return false
    end
    if player:isSummonBlocked() then return false end
    player:setLastTimePokeballUse(timeNow + CONST_EXHAUST_POKEBALL)

    local index = tonumber(param)
    if not index then return false end

    local pokeballs = player:getPokeballsCached()
    local ball = pokeballs[index]
    if not ball or not isOwnedPokeball(player, ball) then
        player:normalizePokeballItems()
        doSendPokeTeamByClient(player)
        return false
    end

    local usingBall = player:getUsingBall()
    if hasSummons(player) then
        if not usingBall then
            doSendPokeTeamByClient(player)
            return false
        end
        local usingBallKey = getBallKey(usingBall)
        doRemoveSummon(player:getId(), balls[usingBallKey].effectRelease, false, true, balls[usingBallKey].missile)
        player:setUsingPokeball(false)
        applyPokeballStateVisual(usingBall, "stored", usingBallKey)
    end
    local position = player:getPosition()
    if ball ~= usingBall then
        if not player:canSummonPokemon(ball) then return false end
        local ballKey = getBallKey(ball)
        ball:setSpecialAttribute("isBeingUsed", 1)
        local _, transformedBall = applyPokeballStateVisual(ball, "released", ballKey)
        if transformedBall then
            ball = transformedBall
        end

        player:setUsingPokeball(ball)
        doReleaseSummon(player:getId(), position, balls[ballKey].effectRelease, true, balls[ballKey].missile)
    end
    doSendPokeTeamByClient(player)
    return false
end

talkaction:separator(" ")
talkaction:register()

local creatureevent = CreatureEvent("testeBallLogin")

function creatureevent.onLogin(player)
    doSendPokeTeamByClient(player)
	return true
end

creatureevent:register()


function Player.handlePokebar(self, buffer)
    local payload = json.decode(buffer)
    if payload.type == "revive" then
        if not (self:revivePokemon(payload.info)) then
            self:getPosition():sendMagicEffect(CONST_ME_POFF)
        end
	elseif payload.type == "update" then
		doSendPokeTeamByClient(self:getId())
    end
    return true
end

function Item:resetMoves()
	for i = 1, 12 do
		self:setSpecialAttribute("cd" .. i, 0)
	end
end

function isReviveClient(itemId)
    local revives = {25228}
    if isInArray(revives, itemId) then
        return true
    end
    return false
end

function Player:revivePokemon(info)
    -- dump(info)
    local pokeballs = self:getPokeballsCached()
    if not pokeballs or #pokeballs == 0 then
        return false
    end

	if not isReviveClient(info.clientId) then
		return false
	end

    local reviveItem = info.position and self:getItemByPos(info.position, info.stackpos, info.clientId) or Game.getItemIdByClientID(info.clientId)
    if not reviveItem then
       return
    end

    if type(reviveItem) ~= "userdata" then
        if self:getItemCount(reviveItem) < 1 then
            return false
        end
    end

    local pokeball = pokeballs[tonumber(info.index)]
    if not pokeball or not isOwnedPokeball(self, pokeball) then
        self:normalizePokeballItems()
        doSendPokeTeamByClient(self)
        return false
    end

	local ball = self:getUsingBall()
	if ball then
        if (pokeball == ball and #self:getSummons() > 0 and not self:isOnFly()) or (pokeball == ball and self:isOnFly() and #self:getSummons() == 0)then
	    	return false
	    end
    end

	local summonName = pokeball:getSpecialAttribute("pokeName")

	pokeball:resetMoves()

	local monsterType = MonsterType(summonName)
	if not monsterType then
		return false
	end
	if PokemonLevel and PokemonLevel.ensureBall then
		PokemonLevel.ensureBall(pokeball, summonName)
	end
	pokeball:setSpecialAttribute("pokeHealth", monsterType:getTotalHealth(pokeball, self))
	local ballKey = getBallKey(pokeball)
	applyPokeballStateVisual(pokeball, "stored", ballKey)
	self:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	if type(reviveItem) == "userdata" and reviveItem:remove(1) or self:removeItem(reviveItem, 1) then
		doUpdatePokebarOnRevive(self, info.index)
	end
    return true
end

function doUpdatePokebarOnRevive(player, index)
	local player = type(player) == "userdata" and player or type(player) == "number" and Player(player)
	doSendPokeTeamByClient(player)
end

function doSendPokeTeamByClient(player)
    player = Player(player)
    local pokeballs = player:getPokeballsCached()
    local pokemons = {}
    local seenBalls = {}
    local visibleIndex = 0

    local pokesHost = {}
    local isHosting = player:isHosting()
    for i, ball in ipairs(pokeballs) do
        if ball and isOwnedPokeball(player, ball) and not seenBalls[ball.uid] then
            seenBalls[ball.uid] = true
            local pokeName = ball:getSpecialAttribute("pokeName") or ""
            local monsterType = MonsterType(pokeName)

            if monsterType then
                visibleIndex = visibleIndex + 1
                if PokemonLevel and PokemonLevel.ensureBall then
                    PokemonLevel.ensureBall(ball, pokeName)
                end
                local progress = PokemonLevel and PokemonLevel.getProgressInfo and PokemonLevel.getProgressInfo(ball) or {
                    level = ball:getSpecialAttribute("pokeLevel") or 1,
                    exp = 0,
                    nextExp = 0,
                    percent = 0,
                    bl = ball:getSpecialAttribute("pokeBL") or 0,
                }
                local maxHealth = monsterType:getTotalHealth(ball, player)
                local curHealth = ball:getSpecialAttribute("pokeHealth") or 0

                -- Se o pokemon estiver fora, pega a vida real da criatura
                if ball:getSpecialAttribute("isBeingUsed") == 1 then
                    local summons = player:getSummons()
                    if summons and summons[1] then
                        local summon = Creature(summons[1])
                        curHealth = summon:getHealth()
                        maxHealth = summon:getMaxHealth()
                    end
                end

                -- Forçar a escala correta se necessário (muitos servidores usam escala de 10000x)
                if curHealth > maxHealth then
                    if curHealth / 10000 <= maxHealth then
                        curHealth = curHealth / 10000
                    elseif curHealth / 100 <= maxHealth then
                        curHealth = curHealth / 100
                    end
                end

                local healthPercent = maxHealth > 0 and math.floor((curHealth / maxHealth) * 100) or 0
                healthPercent = math.max(0, math.min(100, healthPercent))
                local canonicalName = monsterType:name()
                local displayData = PokemonLevel and PokemonLevel.buildDisplayData and PokemonLevel.buildDisplayData(ball, pokeName, monsterType, {includeBoost = true})
                local rawBoost = ball:getSpecialAttribute("pokeBoost") or 0
                local displayName = displayData and displayData.overheadName or (rawBoost >= 1 and string.format("%s [%d +%d]", canonicalName, progress.level, rawBoost) or string.format("%s [%d]", canonicalName, progress.level))
                local expText = displayData and displayData.expText or string.format("XP: %d / %d", progress.exp, progress.nextExp)

                local pokemon = {
                    type = "PokeBar",
                    pokeid = "!p " .. visibleIndex,
                    name = canonicalName,
                    displayName = displayName,
                    rawName = canonicalName,
                    pokeName = canonicalName,
                    nickname = ball:getSpecialAttribute("nickname"),
                    use = ball:getSpecialAttribute("isBeingUsed") == 1 or false,
                    text = (ball:getSpecialAttribute("isBeingUsed") == 1) and "USE" or "",
                    expText = expText,
                    xpText = expText,
                    subText = expText,
                    bottomText = expText,
                    auxText = expText,
                    cooldown = -1,
                    ball = getBallKey(ball),
                    health = curHealth,
                    maxHealth = maxHealth,
                    looktype = monsterType:getOutfit().lookType,
                    boost = ball:getSpecialAttribute("pokeBoost") or 0,
                    level = progress.level,
                    exp = progress.exp,
                    currentLevelExp = progress.currentLevelExp,
                    nextExp = progress.nextExp,
                    expPercent = progress.percent,
                    xpPercent = progress.percent,
                    xpBarColor = "#2f9bff",
                    expBarColor = "#2f9bff",
                    expProgress = {
                        current = progress.exp,
                        currentLevelExp = progress.currentLevelExp,
                        next = progress.nextExp,
                        percent = progress.percent,
                        color = "#2f9bff",
                    },
                    fastcallNumber = visibleIndex,
                }
                table.insert(pokemons, pokemon)
                if isHosting then
                    pokesHost[visibleIndex] = {name = pokemon.name, lookType = pokemon.looktype}
                end
            end
        end
    end
    if isHosting then
        Hosts[player:getId()].pokeballs = pokesHost
        local spectators = player:getSpectators()
        for i, spectator in ipairs(spectators) do
            spectator:sendHostData()
        end
    end
	player:sendExtendedOpcode(53, json.encode(pokemons))
end
