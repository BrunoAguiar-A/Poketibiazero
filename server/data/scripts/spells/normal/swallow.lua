local spell = Spell(SPELL_INSTANT)

function spell.onCastSpell(creature, variant)
    PokemonLevel.healCreature(creature, creature, "Swallow", 0.22, CONST_ME_HITBYPOISON)
    return true
end

spell:name("Swallow")
spell:words("###Swallow###")
spell:isAggressive(false)
spell:needLearn(false)
spell:needTarget(false)
spell:register()
