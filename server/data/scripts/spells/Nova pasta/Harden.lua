local spell = Spell(SPELL_INSTANT)

function spell.onCastSpell(creature, variant)
    PokemonLevel.applyBonusCondition(creature, CONDITION_DEFENSEBONUS, 18, 10000, 118, 2000)
    return true
end

spell:name("Harden")
spell:words("### Harden ###")
spell:isAggressive(false)
spell:needLearn(false)
spell:register()
