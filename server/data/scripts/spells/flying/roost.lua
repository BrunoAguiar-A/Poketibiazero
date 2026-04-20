local spell = Spell(SPELL_INSTANT)

function spell.onCastSpell(creature, variant)
    PokemonLevel.healCreature(creature, creature, "Roost", 0.20, 104)
    return true
end

spell:name("Roost")
spell:words("### Roost ###")
spell:isAggressive(false)
spell:needLearn(false)
spell:register()
