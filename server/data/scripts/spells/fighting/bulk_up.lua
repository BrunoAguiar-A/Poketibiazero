local spell = Spell(SPELL_INSTANT)

function spell.onCastSpell(creature, variant)
    PokemonLevel.applyBonusCondition(creature, CONDITION_DEFENSEBONUS, 12, 10000, 55, 2000)
    PokemonLevel.applyBonusCondition(creature, CONDITION_ATTACKBONUS, 16, 10000, 55, 2000)
    return true
end

spell:name("Bulk Up")
spell:words("### Bulk Up ###")
spell:isAggressive(false)
spell:needLearn(false)
spell:register()
