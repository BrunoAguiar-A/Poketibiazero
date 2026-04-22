function calcularReducaoDano(defesa, multiplicador)
	defesa = math.max(0, tonumber(defesa) or 0)
	multiplicador = math.max(0, tonumber(multiplicador) or 1)

	-- Defesa estava segurando pouco no runtime real. A curva abaixo aumenta
	-- o peso de DEF/SPDEF sem voltar ao comportamento binario do modelo antigo.
	local reducao = (defesa / (defesa + 140)) * 70 * multiplicador
	if reducao > 88 then
		reducao = 88
	end
	return reducao
end

local LIVE_TRACE_FILE = "data/logs/manual_runtime_live_trace.log"

local function safeValue(value)
	if value == nil then
		return "nil"
	end
	if type(value) == "boolean" then
		return value and "true" or "false"
	end
	if type(value) == "number" then
		return string.format("%.6f", value)
	end
	if type(value) == "string" then
		return string.format("%q", value)
	end
	if type(value) ~= "table" then
		return tostring(value)
	end

	local keys = {}
	for key in pairs(value) do
		keys[#keys + 1] = key
	end
	table.sort(keys, function(a, b)
		return tostring(a) < tostring(b)
	end)

	local parts = {}
	for _, key in ipairs(keys) do
		parts[#parts + 1] = tostring(key) .. "=" .. safeValue(value[key])
	end
	return "{" .. table.concat(parts, ", ") .. "}"
end

local function appendLiveTrace(tag, payload)
	local file = io.open(LIVE_TRACE_FILE, "a")
	if not file then
		return
	end

	file:write(string.format("[%s] %s %s\n", os.date("%Y-%m-%d %H:%M:%S"), tag, safeValue(payload)))
	file:close()
end

local function safeItemUid(item)
	if not item then
		return 0
	end

	local ok, value = pcall(function()
		if item.getUniqueId then
			return item:getUniqueId()
		end
		return 0
	end)

	if ok and value then
		return value
	end
	return 0
end

local function safeRaceNameFromMonsterType(monsterType, which)
	if not monsterType then
		return "none"
	end

	local ok, value = pcall(function()
		if which == "secondary" and monsterType.getRace2 then
			return tonumber(monsterType:getRace2()) or 0
		end
		if monsterType.getRace then
			return tonumber(monsterType:getRace()) or 0
		end
		return 0
	end)

	if not ok then
		return "none"
	end

	local raceId = tonumber(value) or 0
	return tostring(raceId)
end

local function collectSummonRuntimeContext(attacker, creature, damageCategory, spellName, rawPrimaryDamageInput, finalDamageAfterRound, primaryTypeName)
	if not attacker or not attacker:isMonster() then
		return nil
	end

	local master = attacker:getMaster()
	if not master or not master:isPlayer() then
		return nil
	end

	local ball = master:getUsingBall()
	local ballUid = safeItemUid(ball)
	local ballSource = "usingBall"
	if (not ball or ball:getTopParent() ~= master or ball:getSpecialAttribute("isBeingUsed") ~= 1) and master.getPokeballsCached then
		for _, cachedBall in ipairs(master:getPokeballsCached()) do
			if cachedBall and cachedBall:getTopParent() == master and cachedBall:getSpecialAttribute("isBeingUsed") == 1 then
				ball = cachedBall
				ballUid = safeItemUid(cachedBall)
				ballSource = "cachedBall"
				break
			end
		end
	end

	local attackerMonsterType = MonsterType(attacker:getName())
	local combatBaseStats = PokemonLevel and PokemonLevel.getCombatBaseStats and PokemonLevel.getCombatBaseStats(attacker:getName(), attackerMonsterType) or nil
	local baseKey = damageCategory == "physical" and "atk" or "spatk"
	local resolvedBaseAttack = math.max(1, tonumber(combatBaseStats and combatBaseStats[baseKey]) or tonumber(attackerMonsterType and attackerMonsterType:moveMagicAttackBase()) or 1)
	local profile = nil
	if ball and PokemonLevel and PokemonLevel.getFinalStatProfile then
		profile = PokemonLevel.getFinalStatProfile(ball, attacker:getName())
	end

	local targetMonsterType = creature and creature:isMonster() and MonsterType(creature:getName()) or nil
	local meleeResolvedType = primaryTypeName == "physical" and safeRaceNameFromMonsterType(attackerMonsterType, "primary") or nil

	return {
		attackerId = attacker:getId(),
		attackerName = attacker:getName(),
		attackerMaster = master:getName(),
		targetId = creature and creature:getId() or 0,
		pokeLevel = ball and (PokemonLevel and PokemonLevel.getLevel and PokemonLevel.getLevel(ball) or ball:getSpecialAttribute("pokeLevel")) or attacker:getLevel(),
		effectiveLevel = ball and (PokemonLevel and PokemonLevel.getEffectiveLevel and PokemonLevel.getEffectiveLevel(ball) or nil) or nil,
		ballUid = ballUid,
		ballSource = ballSource,
		boost = ball and (PokemonLevel and PokemonLevel.getBoost and PokemonLevel.getBoost(ball, false) or ball:getSpecialAttribute("pokeBoost")) or attacker:getBoost(),
		bl = ball and (PokemonLevel and PokemonLevel.getBL and PokemonLevel.getBL(ball) or ball:getSpecialAttribute("pokeBL")) or nil,
		currentStats = profile and profile.currentStats or nil,
		totalMeleeAttack = attacker.getTotalMeleeAttack and attacker:getTotalMeleeAttack() or nil,
		totalMagicAttack = attacker.getTotalMagicAttack and attacker:getTotalMagicAttack() or nil,
		resolvedAttackBase = resolvedBaseAttack,
		meleeResolvedType = meleeResolvedType,
		spellName = spellName,
		combatType = primaryTypeName,
		damageCategory = damageCategory,
		rawPrimaryDamageInput = rawPrimaryDamageInput,
		finalAppliedDamage = finalDamageAfterRound,
		targetName = creature and creature:getName() or "nil",
		targetTypes = {
			primary = safeRaceNameFromMonsterType(targetMonsterType, "primary"),
			secondary = safeRaceNameFromMonsterType(targetMonsterType, "secondary"),
		},
	}
end

local HELD_ATTACK_PERCENT_BY_ID = {
	[27] = 8,
	[28] = 12,
	[29] = 16,
	[30] = 20,
	[31] = 24,
	[32] = 28,
	[33] = 32,
	[34] = 36,
	[35] = 40,
	[36] = 45,
	[37] = 50,
	[38] = 76,
	[39] = 60,
}

local function softCapValue(value, cap, overflowFactor, hardCap)
	value = tonumber(value) or 0
	cap = tonumber(cap) or value
	overflowFactor = tonumber(overflowFactor) or 1.0
	if value > cap then
		value = cap + ((value - cap) * overflowFactor)
	end
	if hardCap ~= nil then
		value = math.min(value, tonumber(hardCap) or value)
	end
	return value
end

local function getAttackStatMultiplier(attacker, damageCategory)
	if not attacker or not attacker:isMonster() then
		return 1.0
	end

	local monsterType = MonsterType(attacker:getName())
	if not monsterType then
		return 1.0
	end

	local combatBaseStats = PokemonLevel and PokemonLevel.getCombatBaseStats and PokemonLevel.getCombatBaseStats(attacker:getName(), monsterType) or nil
	local baseKey = damageCategory == "physical" and "atk" or "spatk"
	local resolvedBaseAttack = math.max(1, tonumber(combatBaseStats and combatBaseStats[baseKey]) or tonumber(monsterType:moveMagicAttackBase()) or 1)
	local dynamicAttack = resolvedBaseAttack

	if damageCategory == "physical" and attacker.getTotalMeleeAttack then
		dynamicAttack = tonumber(attacker:getTotalMeleeAttack()) or resolvedBaseAttack
	elseif attacker.getTotalMagicAttack then
		dynamicAttack = tonumber(attacker:getTotalMagicAttack()) or resolvedBaseAttack
	end

	dynamicAttack = math.max(1, dynamicAttack)
	local rawMultiplier = dynamicAttack / resolvedBaseAttack

	-- O runtime estava convertendo praticamente todo o delta de ataque em dano,
	-- o que deixava melee e especiais agressivos demais. Este blend preserva
	-- progressao por level sem deixar o multiplicador ofensivo dominar sozinho.
	local blendFactor = damageCategory == "special" and 0.58 or 0.58
	return 1.0 + ((rawMultiplier - 1.0) * blendFactor)
end

local function getHeldAttackCorrection(attacker)
	if not attacker then
		return 1.0
	end

	local attackerMaster = attacker:getMaster()
	if not attackerMaster or not attackerMaster:isPlayer() then
		return 1.0
	end

	local ball = attackerMaster:getUsingBall()
	if not ball then
		return 1.0
	end

	local heldx = ball:getAttribute(ITEM_ATTRIBUTE_HELDX)
	local rawBonus = HELD_ATTACK_PERCENT_BY_ID[heldx]
	if not rawBonus or rawBonus <= 0 then
		return 1.0
	end

	local cappedBonus = softCapValue(rawBonus, 30, 0.35, 45)
	return (100 + cappedBonus) / (100 + rawBonus)
end

local function emitAuditTrace(payload)
	local audit = rawget(_G, "BalanceAudit")
	if audit and type(audit.capture) == "function" then
		pcall(audit.capture, payload)
	end
end

ManualRuntimeTrace = ManualRuntimeTrace or {}

local function shallowCopy(value)
	if type(value) ~= "table" then
		return value
	end

	local copy = {}
	for key, entry in pairs(value) do
		copy[key] = entry
	end
	return copy
end

local function buildPendingRuntimeKey(attackerId, targetId, spellName, primaryTypeName, finalDamage)
	return table.concat({
		tostring(attackerId or 0),
		tostring(targetId or 0),
		tostring(spellName or ""),
		tostring(primaryTypeName or "none"),
		tostring(math.floor((tonumber(finalDamage) or 0) + 0.5)),
	}, "|")
end

local function queuePendingRuntimeContext(liveContext, origin)
	ManualRuntimeTrace.pending = ManualRuntimeTrace.pending or {}
	local key = buildPendingRuntimeKey(liveContext.attackerId, liveContext.targetId, liveContext.spellName, liveContext.combatType, liveContext.finalAppliedDamage)
	local queue = ManualRuntimeTrace.pending[key] or {}
	local storedContext = shallowCopy(liveContext)
	storedContext.currentStats = shallowCopy(liveContext.currentStats)
	storedContext.targetTypes = shallowCopy(liveContext.targetTypes)
	storedContext.origin = origin
	queue[#queue + 1] = storedContext
	ManualRuntimeTrace.pending[key] = queue
end

local function popPendingRuntimeContext(attacker, creature, spellName, primaryTypeName, damageAfterOnHealthChange)
	local pending = ManualRuntimeTrace.pending
	if not pending then
		return nil
	end

	local key = buildPendingRuntimeKey(attacker and attacker:getId() or 0, creature and creature:getId() or 0, spellName, primaryTypeName, damageAfterOnHealthChange)
	local queue = pending[key]
	if not queue or #queue == 0 then
		return nil
	end

	local context = table.remove(queue, 1)
	if #queue == 0 then
		pending[key] = nil
	end
	return context
end

function ManualRuntimeTrace.captureAppliedDamage(creature, attacker, primaryType, spellName, origin, rawPrimaryDamageInput, damageAfterOnHealthChange, damageAppliedByCore, targetHealthBefore, targetHealthAfter, hpDeltaReal)
	if not creature or not attacker then
		return false
	end

	local primaryTypeName = getCombatName(primaryType)
	local damageCategory = PokemonLevel and PokemonLevel.getDamageCategory and PokemonLevel.getDamageCategory(primaryTypeName) or "special"
	local liveContext = popPendingRuntimeContext(attacker, creature, spellName, primaryTypeName, damageAfterOnHealthChange)
	if not liveContext then
		liveContext = collectSummonRuntimeContext(attacker, creature, damageCategory, spellName, rawPrimaryDamageInput, damageAfterOnHealthChange, primaryTypeName)
	end
	if not liveContext then
		return false
	end

	liveContext.origin = origin
	liveContext.damageAfterOnHealthChange = tonumber(damageAfterOnHealthChange) or nil
	liveContext.damageAppliedByCore = tonumber(damageAppliedByCore) or nil
	liveContext.targetHealthBefore = tonumber(targetHealthBefore) or nil
	liveContext.targetHealthAfter = tonumber(targetHealthAfter) or nil
	liveContext.hpDeltaReal = tonumber(hpDeltaReal) or nil

	appendLiveTrace("manual_hit_real", liveContext)
	return true
end

function onHealthChange(creature, attacker, primaryDamage, primaryType, spellName, origin)
	if origin and origin == ORIGIN_RETURN or not attacker then
		return primaryDamage, primaryType, false
	end

	local primaryTypeName = getCombatName(primaryType)
	local attackerMaster = attacker:getMaster()
	local rawPrimaryDamageInput = tonumber(primaryDamage) or 0
	local attackStatMultiplier = 1.0
	local heldAttackCorrection = 1.0
	local damageAfterAttackStage = math.abs(rawPrimaryDamageInput)
	local finalDamageBeforeRound = math.abs(rawPrimaryDamageInput)
	local finalDamageAfterRound = math.abs(rawPrimaryDamageInput)

	if creature:isPlayer() and attackerMaster then
		primaryDamage = creature:getMaxHealth() * 0.1
		return primaryDamage, primaryType, false
	end

	if creature:isPlayer() or attacker:isPlayer() then
		if primaryTypeName == "physical" then
			return 0, primaryType
		end
		return primaryDamage, primaryType, false
	end

	local localDamageMultiplier = 1.0
	local damageCategory = PokemonLevel and PokemonLevel.getDamageCategory and PokemonLevel.getDamageCategory(primaryTypeName) or "special"

	if primaryDamage and attacker:isMonster() then
		attackStatMultiplier = getAttackStatMultiplier(attacker, damageCategory)
		heldAttackCorrection = getHeldAttackCorrection(attacker)
		primaryDamage = math.abs(primaryDamage) * attackStatMultiplier
		primaryDamage = primaryDamage * heldAttackCorrection

		if attacker:hasCondition(CONDITION_MELEE_RAGE) and origin == ORIGIN_MELEE then
			primaryDamage = primaryDamage * (1.35 / 2.0)
		end

		if attacker:hasCondition(CONDITION_RAGE) then
			primaryDamage = primaryDamage * (1.45 / 2.0)
		end

		damageAfterAttackStage = math.abs(primaryDamage)
	end

	if attacker:getCondition(CONDITION_CONFUSION) then
		if math.random(100) >= 30 then
			Game.sendAnimatedText(creature:getPosition(), "MISS", TEXTCOLOR_WHITE_EXP, true)
			return 0, primaryType, false
		end
	end

	local isCritical = false
	local defense = creature:getTotalDefense()
	local chanceCritical = 0
	local criticalDamage = 1.5
	local chanceBlock = 0
	local damageReductionMultiplier = 1.0

	if attackerMaster and attackerMaster:isPlayer() then
		local ball = attackerMaster:getUsingBall()
		if ball then
			local heldType = "critical"
			local ident = ball:getAttribute(ITEM_ATTRIBUTE_HELDY)
			local isCriticalHeld = isHeld(heldType, ident)

			if isCriticalHeld then
				local tier = HELDS_Y_INFO[ident].tier
				chanceCritical = chanceCritical + HELDS_BONUS[heldType][tier]
			end
		end

		local guild = attackerMaster:getGuild()
		if guild then
			local hasCriticalChanceBuff = guild:hasBuff(COLUMN_2, CRITICAL_CHANCE_BUFF)
			if hasCriticalChanceBuff then
				chanceCritical = chanceCritical + GUILD_BUFF_CRITICAL_CHANCE
			end

			local hasCriticalDamageBuff = guild:hasBuff(COLUMN_2, CRITICAL_DAMAGE_BUFF)
			if hasCriticalDamageBuff then
				criticalDamage = criticalDamage + (GUILD_BUFF_CRITICAL_DAMAGE / 100)
			end

			local hasDefenseBuff = guild:hasBuff(COLUMN_3, DEFENSE_BUFF)
			if hasDefenseBuff then
				damageReductionMultiplier = damageReductionMultiplier * (1 + GUILD_BUFF_DEFENSE / 100)
			end
		end
	end

	chanceCritical = softCapValue(chanceCritical, 35, 0.4, 55)

	if chanceCritical > 0 and math.random(1, 100) <= chanceCritical then
		localDamageMultiplier = localDamageMultiplier * criticalDamage
		isCritical = true
	end

	if damageCategory == "physical" and creature.getTotalPhysicalDefense then
		defense = creature:getTotalPhysicalDefense()
	elseif damageCategory == "special" and creature.getTotalSpecialDefense then
		defense = creature:getTotalSpecialDefense()
	end

	local reducaoDano = calcularReducaoDano(defense, damageReductionMultiplier)
	localDamageMultiplier = localDamageMultiplier * (1 - (reducaoDano / 100))
	if primaryDamage then
		local finalDamage = math.abs(primaryDamage * localDamageMultiplier)
		finalDamageBeforeRound = finalDamage
		if finalDamage > 0 then
			finalDamage = math.max(1, math.floor(finalDamage + 0.5))
		end
		primaryDamage = finalDamage
		finalDamageAfterRound = finalDamage
	end

	emitAuditTrace({
		attackerId = attacker:getId(),
		attackerName = attacker:getName(),
		targetId = creature:getId(),
		targetName = creature:getName(),
		spellName = spellName,
		origin = origin,
		primaryType = primaryType,
		primaryTypeName = primaryTypeName,
		damageCategory = damageCategory,
		rawPrimaryDamageInput = rawPrimaryDamageInput,
		attackStatMultiplier = attackStatMultiplier,
		heldAttackCorrection = heldAttackCorrection,
		damageAfterAttackStage = damageAfterAttackStage,
		defense = defense,
		damageReductionMultiplier = damageReductionMultiplier,
		reductionPercent = reducaoDano,
		reductionCapped = reducaoDano >= 85,
		criticalChance = chanceCritical,
		criticalDamage = criticalDamage,
		isCritical = isCritical,
		localDamageMultiplier = localDamageMultiplier,
		finalDamageBeforeRound = finalDamageBeforeRound,
		finalDamageAfterRound = finalDamageAfterRound,
		hasMeleeRage = attacker:hasCondition(CONDITION_MELEE_RAGE),
		hasRage = attacker:hasCondition(CONDITION_RAGE),
		hasConfusion = attacker:getCondition(CONDITION_CONFUSION) ~= nil,
	})

	local liveContext = collectSummonRuntimeContext(attacker, creature, damageCategory, spellName, rawPrimaryDamageInput, finalDamageAfterRound, primaryTypeName)
	if liveContext then
		appendLiveTrace("manual_hit", liveContext)
		queuePendingRuntimeContext(liveContext, origin)
	end

	local masterCreature = creature:getMaster()
	if masterCreature and masterCreature:isPlayer() then
		addEvent(function(pid)
			local p = Player(pid)
			if p then
				doSendPokeTeamByClient(p)
			end
		end, 100, masterCreature:getId())

		local ball = masterCreature:getUsingBall()
		if ball then
			local heldx = ball:getAttribute(ITEM_ATTRIBUTE_HELDX)
			local type = "return"
			local isReturnHeld = isHeld(type, heldx)
			if isReturnHeld then
				local tier = HELDS_X_INFO[heldx].tier
				local porcentagemDano = HELDS_BONUS[type][tier]
				local damageToReturn = (primaryDamage * porcentagemDano)
				doTargetCombatHealth(creature.uid, attacker.uid, COMBAT_NORMALDAMAGE, damageToReturn, damageToReturn, 0, ORIGIN_RETURN)
			end
		end
		local guild = masterCreature:getGuild()
		if guild then
			local hasBlockChance = guild:hasBuff(COLUMN_6, BLOCK_CHANCE_BUFF)
			if hasBlockChance then
				chanceBlock = chanceBlock + GUILD_BUFF_BLOCK
			end
		end
	end

	if math.random(100) <= chanceBlock then
		Game.sendAnimatedText(creature:getPosition(), "BLOCK", TEXTCOLOR_WHITE_EXP, true)
		return 0, primaryType, false
	end

	return primaryDamage, primaryType, isCritical
end
