local spell = Spell(SPELL_INSTANT)

function spell.onCastSpell(creature, variant)
    PokemonLevel.applyBonusCondition(creature, CONDITION_DEFENSEBONUS, 28, 6000, 1100, 1000)
    return true
end

spell:name("Protect")
spell:words("### Protect ###")
spell:isAggressive(false)
spell:needLearn(false)
spell:register()
