local spell = Spell(SPELL_INSTANT)

function spell.onCastSpell(creature, variant)
    PokemonLevel.applyBonusCondition(creature, CONDITION_ATTACKBONUS, 18, 8000, 336, 1000)
    return true
end

spell:name("Charge")
spell:words("### Charge ###")
spell:isAggressive(false)
spell:needLearn(false)
spell:register()
