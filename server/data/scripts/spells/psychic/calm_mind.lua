local spell = Spell(SPELL_INSTANT)

function spell.onCastSpell(creature, variant)
    PokemonLevel.applyBonusCondition(creature, CONDITION_ATTACKBONUS, 14, 10000, 325, 1000)
    PokemonLevel.applyBonusCondition(creature, CONDITION_DEFENSEBONUS, 10, 10000, 325, 1000)
    return true
end

spell:name("Calm Mind")
spell:words("### Calm Mind ###")
spell:isAggressive(false)
spell:needLearn(false)
spell:register()
