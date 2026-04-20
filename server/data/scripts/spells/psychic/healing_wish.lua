local spell = Spell(SPELL_INSTANT)

function spell.onCastSpell(creature, variant)
    PokemonLevel.healFriendlyTargetsAround(creature, "Healing Wish", 0.22, 3, 3, 13)
    return true
end

spell:name("Healing Wish")
spell:words("### Healing Wish ###")
spell:isAggressive(false)
spell:needLearn(false)
spell:register()
