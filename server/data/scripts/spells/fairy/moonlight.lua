local spell = Spell(SPELL_INSTANT)

function spell.onCastSpell(creature, variant)
    PokemonLevel.healCreature(creature, creature, "Moonlight", 0.20, 2100)
    return true
end

spell:name("Moonlight")
spell:words("#Moonlight#")
spell:isAggressive(false)
spell:needLearn(false)
spell:register()
