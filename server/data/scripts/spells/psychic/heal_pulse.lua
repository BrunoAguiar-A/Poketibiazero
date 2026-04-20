local spell = Spell(SPELL_INSTANT)

function spell.onCastSpell(creature, variant)
    PokemonLevel.healFriendlyTargetsAround(creature, "Heal Pulse", 0.18, 3, 3, 2020)
    return true
end

spell:name("Heal Pulse")
spell:words("#Heal Pulse#")
spell:isAggressive(false)
spell:needLearn(false)
spell:range(6)
spell:needTarget(false)
spell:register()
