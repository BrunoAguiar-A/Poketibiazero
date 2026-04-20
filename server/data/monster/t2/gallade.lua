
local mType = Game.createMonsterType("Gallade")
local pokemon = {}
pokemon.eventFile = false
pokemon.eventFile = "default" 
pokemon.description = "a Gallade"
pokemon.experience = 6752
pokemon.outfit = {
    lookType = 475
}

pokemon.health = 16156
pokemon.maxHealth = pokemon.health
pokemon.race = "psychic"
pokemon.race2 = "fighting"
pokemon.corpse = 0
pokemon.speed = 180
pokemon.maxSummons = 0

pokemon.changeTarget = {
    interval = 4*1000,
    chance = 20
}
pokemon.wild = {
    health = pokemon.health * 1.8,
    maxHealth = pokemon.health * 1.8,
    speed = 220
}

pokemon.flags = {
    minimumLevel = 22,
    maximumLevel = 45,
    attackable = true,
    summonable = true,
    passive = false,
    hostile = true,
    convinceable = true,
    illusionable = true,
    canPushItems = false,
    canPushCreatures = false,
    targetDistance = 1,
    staticAttackChance = 97,
    pokemonRank = "",
    hasShiny = 1,
    hasMega = 0,
    moveMagicAttackBase = 160,
    moveMagicDefenseBase = 130,
    catchChance = 250,
    canControlMind = 0,
    canLevitate = 0,
    canLight = 0,
    canCut = 0,
    canSmash = 0,
    canDig = 0,
    canTeleport = 0,
    canBlink = 0,
    isSurfable = 0,
    isRideable = 0,
    isFlyable = 0,
}

pokemon.events = {
    "MonsterHealthChange"
}
pokemon.summons = {}

pokemon.voices = {
    interval = 5000,
    chance = 65,
    {text = "ABUUUH!", yell = FALSE},
}

pokemon.loot = {
{id = "rubber ball", chance = 8000000, maxCount = 13},
{id = "bitten apple", chance = 3250000, maxCount = 1},
{id = "heart stone", chance = 150000, maxCount = 1},
}

pokemon.moves = {
	{name = "melee", power = 3, interval = 2000},
    {name = "Psycho Cut", power = 8, interval = 9000},
    {name = "Swift", power = 6, interval = 12000},
    {name = "Leaf Blade", power = 8, interval = 16000},
    {name = "Night Slash", power = 8, interval = 20000},
    {name = "Close Combat", power = 11, interval = 26000},
    {name = "Agility", power = 0, interval = 40000},
}

pokemon.attacks = {
	{name = "melee", power = 3, interval = 2000, chance = 100},
    {name = "Psycho Cut", power = 8, interval = 9000, chance = 100},
    {name = "Swift", power = 6, interval = 12000, chance = 100},
    {name = "Leaf Blade", power = 8, interval = 16000, chance = 100},
    {name = "Night Slash", power = 8, interval = 20000, chance = 100},
    {name = "Close Combat", power = 11, interval = 26000, chance = 100},
}

pokemon.defenses = {
    {name = "Agility", power = 0, interval = 24000, chance = 18},
}
pokemon.elements = {}
pokemon.immunities = {}

mType.onThink = function(pokemon, interval)
end

mType.onAppear = function(pokemon, creature)
end

mType.onDisappear = function(pokemon, creature)
end

mType.onMove = function(pokemon, creature, fromPosition, toPosition)
end

mType.onSay = function(pokemon, creature, type, message)
end

mType:register(pokemon)


