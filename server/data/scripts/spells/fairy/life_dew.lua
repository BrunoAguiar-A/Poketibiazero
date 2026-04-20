local spell = Spell(SPELL_INSTANT)
function spell.onCastSpell(creature, variant)
    PokemonLevel.healFriendlyTargetsAround(creature, "Life Dew", 0.14, 3, 3, 2515)
    return true
end

spell:name("Life Dew")
spell:words("#Life Dew#")
spell:isAggressive(false)
spell:needLearn(false)
spell:register()
