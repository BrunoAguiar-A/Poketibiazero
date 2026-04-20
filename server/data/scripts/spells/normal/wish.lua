local spell = Spell(SPELL_INSTANT)

function spell.onCastSpell(creature, variant)
    PokemonLevel.healFriendlyTargetsAround(creature, "Wish", 0.16, 2, 2, CONST_ME_HITBYPOISON)
    return true
end

spell:name("Wish")
spell:words("###Wish###")
spell:isAggressive(false)
spell:needLearn(false)
spell:needTarget(false)
spell:register()
