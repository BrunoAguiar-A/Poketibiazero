local hasteCondition = createConditionObject(CONDITION_HASTE)
hasteCondition:setParameter(CONDITION_PARAM_TICKS, 15000)  -- Duração do efeito em milissegundos
hasteCondition:setFormula(0.7, 0, 0.7, 0)  -- Aumenta a velocidade do Pokémon

local spell = Spell(SPELL_INSTANT)

function spell.onCastSpell(creature, variant)
    creature:addCondition(hasteCondition)
    PokemonLevel.applyBonusCondition(creature, CONDITION_ATTACKBONUS, 10, 15000, 15, 850)
    
    local effectInterval = 850 -- Intervalo de 1 segundo para o efeito visual

    local function showEffect()
        if creature:getCondition(CONDITION_HASTE) then
            local position = creature:getPosition()
            position:sendMagicEffect(15)
            addEvent(showEffect, effectInterval)
        end
    end

    showEffect()
    return true
end

spell:name("Agility")
spell:words("### Agility ###")
spell:isAggressive(false)
spell:needLearn(false)
spell:register()
