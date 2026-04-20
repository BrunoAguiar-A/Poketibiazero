local spell = Spell(SPELL_INSTANT)

function spell.onCastSpell(creature, variant)
    PokemonLevel.applyBonusCondition(creature, CONDITION_DEFENSEBONUS, 24, 10000, CONST_ME_HITBYPOISON, 1000)
    return true
end

spell:name("Barrier")
spell:words("###Barrier###")
spell:isAggressive(false)
spell:needLearn(false)
spell:needTarget(false)
spell:register()
