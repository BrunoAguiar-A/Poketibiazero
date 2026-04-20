function onSay(player, words, param)
    local summon = player:getSummon()
    if not summon then
        player:sendCancelMessage("Sorry, not possible. You need a summon to conjure spells.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    local tile = Tile(player:getPosition())
    if tile:hasFlag(TILESTATE_PROTECTIONZONE) then
        player:sendCancelMessage("Sorry, not possible in protection zone.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    local summonName = summon:getName()
    local monsterType = MonsterType(summonName)
    local move = monsterType:getMoveList()
    local target = summon:getTarget()

    if not move then
        player:sendCancelMessage("Sorry, not possible. No moves available.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    local stunned = (summon:getCondition(CONDITION_STUN) or player:getCondition(CONDITION_STUN))
    local silence = (summon:getCondition(CONDITION_SILENCE) or player:getCondition(CONDITION_SILENCE))
    local feared = (summon:getCondition(CONDITION_FEAR) or player:getCondition(CONDITION_FEAR))

    if stunned then
        player:sendCancelMessage("Sorry, not possible. You are stunned.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    if silence then
        player:sendCancelMessage("Sorry, not possible. You are silenced.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    if feared then
        player:sendCancelMessage("Sorry, not possible. You are feared.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    for i = 1, #moveWords do
        if words == moveWords[i] then
            if move[i] then
                if move[i].level > player:getLevel() then
                    player:sendCancelMessage("Sorry, not possible. You need to be at least level " .. move[i].level .. " to use this move.")
                    player:getPosition():sendMagicEffect(CONST_ME_POFF)
                    break
                end

                if move[i].passive == 1 then return false end
                if move[i].isTarget == 1 and not target then
                    player:sendCancelMessage("Sorry, not possible. You need a target.")
                    player:getPosition():sendMagicEffect(CONST_ME_POFF)
                    break
                end
                if target and move[i].isTarget == 1 and move[i].range ~= 0 and summon:getPosition():getDistance(target:getPosition()) > move[i].range then
                    player:sendCancelMessage("Sorry, not possible. You are too far.")
                    player:getPosition():sendMagicEffect(CONST_ME_POFF)
                    break
                end
                if summon:getCondition(CONDITION_SLEEP) then
                    player:sendCancelMessage("Sorry, not possible. Your pokemon is sleeping.")
                    player:getPosition():sendMagicEffect(CONST_ME_POFF)
                    break
                end
                local cooldown = math.max(1, math.ceil((tonumber(move[i].speed) or 1000) / 1000))
                local exhausted = player:checkMoveExhaustion(i, cooldown)
                if exhausted then
                    if player.sendSummonMoves then
                        player:sendSummonMoves()
                    end
                    break
                end

                if not exhausted then
                    local moveName = move[i].name
                    doCreatureCastSpell(summon, moveName)
                    player:say(summonName .. ", use " .. moveName .. "!", TALKTYPE_MONSTER_SAY)
                    if player.sendSummonMoves then
                        player:sendSummonMoves()
                    end
                end
            else
                player:sendCancelMessage("Sorry, not possible.")
                player:getPosition():sendMagicEffect(CONST_ME_POFF)
                break
            end
        end
    end
    return false
end
