local spell = Spell(SPELL_INSTANT)

function spell.onCastSpell(creature, variant)
    PokemonLevel.applyBonusCondition(creature, CONDITION_DEFENSEBONUS, 16, 12000, CONST_ME_HITBYPOISON, 1000)
    return true
end

spell:name("Stockpile")
spell:words("###Stockpile###")
spell:isAggressive(false)
spell:needLearn(false)
spell:needTarget(false)
spell:register()
