local spell = Spell(SPELL_INSTANT)

function spell.onCastSpell(creature, variant)
    PokemonLevel.applyBonusCondition(creature, CONDITION_DEFENSEBONUS, 18, 10000, 2004, 1000)
    return true
end

spell:name("Light Screen")
spell:words("### Light Screen ###")
spell:isAggressive(false)
spell:needLearn(false)
spell:register()
