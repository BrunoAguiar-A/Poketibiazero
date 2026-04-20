local spell = Spell(SPELL_INSTANT)

function spell.onCastSpell(creature, variant)
    PokemonLevel.healCreature(creature, creature, "Soft-Boiled", 0.28, 133)
    return true
end

spell:name("Soft-Boiled")
spell:words("### Soft-Boiled ###")
spell:isAggressive(false)
spell:needLearn(false)
spell:register()
