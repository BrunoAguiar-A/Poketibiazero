local spell = Spell(SPELL_INSTANT)

function spell.onCastSpell(creature, variant)
    PokemonLevel.healCreature(creature, creature, "Recover", 0.24, 307)
    return true
end

spell:name("Recover")
spell:words("### Recover ###")
spell:isAggressive(false)
spell:needLearn(false)
spell:register()
