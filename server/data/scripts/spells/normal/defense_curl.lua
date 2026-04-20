local spell = Spell(SPELL_INSTANT)

function spell.onCastSpell(creature, variant)
    PokemonLevel.applyBonusCondition(creature, CONDITION_DEFENSEBONUS, 20, 10000, 145, 2000)
    return true
end

spell:name("Defense Curl")
spell:words("### Defense Curl ###")
spell:isAggressive(false)
spell:needLearn(false)
spell:register()
