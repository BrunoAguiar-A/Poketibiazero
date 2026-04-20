local spell = Spell(SPELL_INSTANT)

function spell.onCastSpell(creature, variant)
    PokemonLevel.healCreature(creature, creature, "Ingrain", 0.18, CONST_ME_HITBYPOISON)
    PokemonLevel.applyBonusCondition(creature, CONDITION_DEFENSEBONUS, 22, 12000, CONST_ME_HITBYPOISON, 1000)
    return true
end

spell:name("Ingrain")
spell:words("###Ingrain###")
spell:isAggressive(false)
spell:needLearn(false)
spell:needTarget(false)
spell:register()
