local spell = Spell(SPELL_INSTANT)

function spell.onCastSpell(creature, variant)
    PokemonLevel.applyBonusCondition(creature, CONDITION_DEFENSEBONUS, 22, 10000, CONST_ME_HITBYPOISON, 1000)
    return true
end

spell:name("Protection")
spell:words("###Protection###")
spell:isAggressive(false)
spell:needLearn(false)
spell:needTarget(false)
spell:register()
