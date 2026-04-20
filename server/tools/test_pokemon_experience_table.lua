local root = arg and arg[0] and arg[0]:match("^(.*)/tools/test_pokemon_experience_table.lua$") or "."
if root == "" then
	root = "."
end

dofile(root .. "/data/lib/pokemon/experience_table.lua")
dofile(root .. "/data/lib/pokemon/level_system.lua")

local function assertEquals(actual, expected, label)
	if actual ~= expected then
		error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)), 2)
	end
end

local ok, badLevel = PokemonExperienceTable.validate()
assertEquals(ok, true, "table consistency")
assertEquals(badLevel, nil, "bad consistency level")

for level = 1, PokemonExperienceTable.MAX_LEVEL - 1 do
	local minExp = PokemonExperienceTable.getMinTotalExpForLevel(level)
	local expToNext = PokemonExperienceTable.getExpToNextForLevel(level)
	assertEquals(PokemonExperienceTable.getLevelByTotalExp(minExp), level, "level start " .. level)
	assertEquals(PokemonExperienceTable.getLevelByTotalExp(minExp + expToNext - 1), level, "level end " .. level)
	assertEquals(PokemonExperienceTable.getLevelByTotalExp(minExp + expToNext), level + 1, "level transition " .. level)
end

assertEquals(PokemonLevel.getPokemonLevelByTotalExp(0), 1, "example exp 0")
assertEquals(PokemonLevel.getPokemonLevelByTotalExp(749), 1, "example exp 749")
assertEquals(PokemonLevel.getPokemonLevelByTotalExp(750), 2, "example exp 750")
assertEquals(PokemonLevel.getPokemonLevelByTotalExp(2474), 2, "example exp 2474")
assertEquals(PokemonLevel.getPokemonLevelByTotalExp(2475), 3, "example exp 2475")
assertEquals(PokemonLevel.getPokemonLevelByTotalExp(5999), 3, "example exp 5999")
assertEquals(PokemonLevel.getPokemonLevelByTotalExp(6000), 4, "example exp 6000")
assertEquals(PokemonLevel.getPokemonLevelByTotalExp(93749999), 99, "example exp 93749999")
assertEquals(PokemonLevel.getPokemonLevelByTotalExp(93750000), 100, "example exp 93750000")
assertEquals(PokemonLevel.getPokemonLevelByTotalExp(93750001), 100, "example exp over cap")

assertEquals(PokemonLevel.getExpInCurrentLevel(6000000), 0, "level 40 progress start")
assertEquals(PokemonLevel.getRemainingExpToNext(6000000), 461325, "level 40 remaining start")
assertEquals(PokemonLevel.getExpInCurrentLevel(6000100), 100, "level 40 progress 100")
assertEquals(PokemonLevel.getRemainingExpToNext(6000100), 461225, "level 40 remaining 100")

local FakeBall = {}
FakeBall.__index = FakeBall

function FakeBall:new(attrs)
	return setmetatable({attrs = attrs or {}}, self)
end

function FakeBall:getSpecialAttribute(key)
	return self.attrs[key]
end

function FakeBall:setSpecialAttribute(key, value)
	self.attrs[key] = value
end

local ball = FakeBall:new({pokeName = "Bulbasaur", pokeExp = 0, pokeLevel = 1})
local gained, oldLevel, newLevel = PokemonLevel.addPokemonExp(ball, 6000)
assertEquals(gained, 6000, "multi-level gain amount")
assertEquals(oldLevel, 1, "multi-level old level")
assertEquals(newLevel, 4, "multi-level new level")
assertEquals(ball:getSpecialAttribute("pokeLevel"), 4, "multi-level stored level")
assertEquals(ball:getSpecialAttribute("pokeExp"), 6000, "multi-level stored total exp")

PokemonLevel.setPokemonTotalExp(ball, PokemonLevel.getMinTotalExpForLevel(99))
gained, oldLevel, newLevel = PokemonLevel.addPokemonExp(ball, PokemonLevel.getExpToNextForLevel(99))
assertEquals(gained, 2784525, "99 to 100 gain")
assertEquals(oldLevel, 99, "99 to 100 old level")
assertEquals(newLevel, 100, "99 to 100 new level")
assertEquals(ball:getSpecialAttribute("pokeExp"), 93750000, "99 to 100 stored exp")

PokemonLevel.setPokemonTotalExp(ball, 93750001)
assertEquals(ball:getSpecialAttribute("pokeExp"), 93750000, "set exp clamps at max total")
assertEquals(ball:getSpecialAttribute("pokeLevel"), 100, "set exp clamps at level 100")
gained, oldLevel, newLevel = PokemonLevel.addPokemonExp(ball, 1000000)
assertEquals(gained, 0, "max level gain")
assertEquals(oldLevel, 100, "max level old")
assertEquals(newLevel, 100, "max level new")

print("pokemon experience table tests passed")
