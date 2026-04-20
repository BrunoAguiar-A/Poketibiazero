function calcularReducaoDano(defesa, multiplicador)
	defesa = math.max(0, tonumber(defesa) or 0)
	multiplicador = math.max(0, tonumber(multiplicador) or 1)

	-- Usa uma curva suave para a defesa não zerar todo o dano quando os
	-- stats passam de ~200. O valor retornado continua em porcentagem.
	local reducao = (defesa / (defesa + 180)) * 60 * multiplicador
	if reducao > 85 then
		reducao = 85
	end
	return reducao
end

function onHealthChange(creature, attacker, primaryDamage, primaryType, spellName, origin)
	if origin and origin == ORIGIN_RETURN or not attacker then
		return primaryDamage, primaryType, false
	end

	local primaryTypeName = getCombatName(primaryType)
	local attackerMaster = attacker:getMaster()

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

	if chanceCritical > 0 and math.random(1, 100) <= chanceCritical then
		localDamageMultiplier = localDamageMultiplier * criticalDamage
		isCritical = true
	end

	local damageCategory = PokemonLevel and PokemonLevel.getDamageCategory and PokemonLevel.getDamageCategory(primaryTypeName) or "special"
	if PokemonLevel and PokemonLevel.getCreatureAttackScale and primaryDamage then
		primaryDamage = primaryDamage * PokemonLevel.getCreatureAttackScale(attacker, damageCategory)
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
		if finalDamage > 0 then
			finalDamage = math.max(1, math.floor(finalDamage + 0.5))
		end
		primaryDamage = finalDamage
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
