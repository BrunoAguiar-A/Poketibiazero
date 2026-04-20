local spell = Spell(SPELL_INSTANT)

function spell.onCastSpell(creature, variant)
    for _, target in ipairs(PokemonLevel.getFriendlyTargetsAround(creature, 3, 3, true)) do
        PokemonLevel.applyBonusCondition(target, CONDITION_ATTACKBONUS, 14, 10000, 1800, 1000)
    end
    return true
end

spell:name("Helping Hand")
spell:words("### Helping Hand ###")
spell:isAggressive(false)
spell:needLearn(false)
spell:register()
