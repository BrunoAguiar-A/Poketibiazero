PokemonLevel = PokemonLevel or {}

PokemonLevel.CONFIG = {
	maxLevel = 100,
	defaultLevel = 1,
	defaultLegacyBL = 0,
	expShare = 0.02,
	maxExpGainPerKill = 5000,
	progression = {
		maxBoost = 50000,
	},
	statScale = {
		hp = 0.0020,
		atk = 0.0030,
		def = 0.0024,
		spatk = 0.0030,
		spdef = 0.0024,
		speed = 0.0018,
	},
	statScaleCap = {
		hp = 2.00,
		atk = 2.10,
		def = 1.85,
		spatk = 2.10,
		spdef = 1.85,
		speed = 1.60,
	},
}

local STAT_ORDER = {"hp", "atk", "def", "spatk", "spdef", "speed"}
local IV_KEYS
local readSpecialAttributeAny
local writeNature
local writeIV
local IV_DEFAULT = 4

local NATURE_DATA = {
	hardy = {label = "Hardy", effectText = "Nature neutra", impactText = "Sem impacto"},
	lonely = {label = "Lonely", plus = "atk", minus = "def", effectText = "Aumenta ATK e reduz DEF", impactText = "ATK +10%, DEF -10%"},
	brave = {label = "Brave", plus = "atk", minus = "speed", effectText = "Aumenta ATK e reduz SPEED", impactText = "ATK +10%, SPEED -10%"},
	adamant = {label = "Adamant", plus = "atk", minus = "spatk", effectText = "Aumenta ATK e reduz SPATK", impactText = "ATK +10%, SPATK -10%"},
	naughty = {label = "Naughty", plus = "atk", minus = "spdef", effectText = "Aumenta ATK e reduz SPDEF", impactText = "ATK +10%, SPDEF -10%"},
	bold = {label = "Bold", plus = "def", minus = "atk", effectText = "Aumenta DEF e reduz ATK", impactText = "DEF +10%, ATK -10%"},
	docile = {label = "Docile", effectText = "Nature neutra", impactText = "Sem impacto"},
	relaxed = {label = "Relaxed", plus = "def", minus = "speed", effectText = "Aumenta DEF e reduz SPEED", impactText = "DEF +10%, SPEED -10%"},
	impish = {label = "Impish", plus = "def", minus = "spatk", effectText = "Aumenta DEF e reduz SPATK", impactText = "DEF +10%, SPATK -10%"},
	lax = {label = "Lax", plus = "def", minus = "spdef", effectText = "Aumenta DEF e reduz SPDEF", impactText = "DEF +10%, SPDEF -10%"},
	timid = {label = "Timid", plus = "speed", minus = "atk", effectText = "Aumenta SPEED e reduz ATK", impactText = "SPEED +10%, ATK -10%"},
	hasty = {label = "Hasty", plus = "speed", minus = "def", effectText = "Aumenta SPEED e reduz DEF", impactText = "SPEED +10%, DEF -10%"},
	serious = {label = "Serious", effectText = "Nature neutra", impactText = "Sem impacto"},
	jolly = {label = "Jolly", plus = "speed", minus = "spatk", effectText = "Aumenta SPEED e reduz SPATK", impactText = "SPEED +10%, SPATK -10%"},
	naive = {label = "Naive", plus = "speed", minus = "spdef", effectText = "Aumenta SPEED e reduz SPDEF", impactText = "SPEED +10%, SPDEF -10%"},
	modest = {label = "Modest", plus = "spatk", minus = "atk", effectText = "Aumenta SPATK e reduz ATK", impactText = "SPATK +10%, ATK -10%"},
	mild = {label = "Mild", plus = "spatk", minus = "def", effectText = "Aumenta SPATK e reduz DEF", impactText = "SPATK +10%, DEF -10%"},
	quiet = {label = "Quiet", plus = "spatk", minus = "speed", effectText = "Aumenta SPATK e reduz SPEED", impactText = "SPATK +10%, SPEED -10%"},
	bashful = {label = "Bashful", effectText = "Nature neutra", impactText = "Sem impacto"},
	rash = {label = "Rash", plus = "spatk", minus = "spdef", effectText = "Aumenta SPATK e reduz SPDEF", impactText = "SPATK +10%, SPDEF -10%"},
	calm = {label = "Calm", plus = "spdef", minus = "atk", effectText = "Aumenta SPDEF e reduz ATK", impactText = "SPDEF +10%, ATK -10%"},
	gentle = {label = "Gentle", plus = "spdef", minus = "def", effectText = "Aumenta SPDEF e reduz DEF", impactText = "SPDEF +10%, DEF -10%"},
	sassy = {label = "Sassy", plus = "spdef", minus = "speed", effectText = "Aumenta SPDEF e reduz SPEED", impactText = "SPDEF +10%, SPEED -10%"},
	careful = {label = "Careful", plus = "spdef", minus = "spatk", effectText = "Aumenta SPDEF e reduz SPATK", impactText = "SPDEF +10%, SPATK -10%"},
	quirky = {label = "Quirky", effectText = "Nature neutra", impactText = "Sem impacto"},
}

local NATURE_ORDER = {
	"Hardy", "Lonely", "Brave", "Adamant", "Naughty",
	"Bold", "Docile", "Relaxed", "Impish", "Lax",
	"Timid", "Hasty", "Serious", "Jolly", "Naive",
	"Modest", "Mild", "Quiet", "Bashful", "Rash",
	"Calm", "Gentle", "Sassy", "Careful", "Quirky",
}

local GBA_BASE_STATS = {}
local GBA_STATS_DATA = [[
bulbasaur,45,49,49,65,65,45
ivysaur,60,62,63,80,80,60
venusaur,80,82,83,100,100,80
charmander,39,52,43,60,50,65
charmeleon,58,64,58,80,65,80
charizard,78,84,78,109,85,100
squirtle,44,48,65,50,64,43
wartortle,59,63,80,65,80,58
blastoise,79,83,100,85,105,78
caterpie,45,30,35,20,20,45
metapod,50,20,55,25,25,30
butterfree,60,45,50,80,80,70
weedle,40,35,30,20,20,50
kakuna,45,25,50,25,25,35
beedrill,65,80,40,45,80,75
pidgey,40,45,40,35,35,56
pidgeotto,63,60,55,50,50,71
pidgeot,83,80,75,70,70,91
rattata,30,56,35,25,35,72
raticate,55,81,60,50,70,97
spearow,40,60,30,31,31,70
fearow,65,90,65,61,61,100
ekans,35,60,44,40,54,55
arbok,60,85,69,65,79,80
pikachu,35,55,30,50,40,90
raichu,60,90,55,90,80,100
sandshrew,50,75,85,20,30,40
sandslash,75,100,110,45,55,65
nidoran f,55,47,52,40,40,41
nidoranfe,55,47,52,40,40,41
nidorina,70,62,67,55,55,56
nidoqueen,90,82,87,75,85,76
nidoran m,46,57,40,40,40,50
nidoranma,46,57,40,40,40,50
nidorino,61,72,57,55,55,65
nidoking,81,92,77,85,75,85
clefairy,70,45,48,60,65,35
clefable,95,70,73,85,90,60
vulpix,38,41,40,50,65,65
ninetales,73,76,75,81,100,100
jigglypuff,115,45,20,45,25,20
wigglytuff,140,70,45,75,50,45
zubat,40,45,35,30,40,55
golbat,75,80,70,65,75,90
oddish,45,50,55,75,65,30
gloom,60,65,70,85,75,40
vileplume,75,80,85,100,90,50
paras,35,70,55,45,55,25
parasect,60,95,80,60,80,30
venonat,60,55,50,40,55,45
venomoth,70,65,60,90,75,90
diglett,10,55,25,35,45,95
dugtrio,35,80,50,50,70,120
meowth,40,45,35,40,40,90
persian,65,70,60,65,65,115
psyduck,50,52,48,65,50,55
golduck,80,82,78,95,80,85
mankey,40,80,35,35,45,70
primeape,65,105,60,60,70,95
growlithe,55,70,45,70,50,60
arcanine,90,110,80,100,80,95
poliwag,40,50,40,40,40,90
poliwhirl,65,65,65,50,50,90
poliwrath,90,85,95,70,90,70
abra,25,20,15,105,55,90
kadabra,40,35,30,120,70,105
alakazam,55,50,45,135,85,120
machop,70,80,50,35,35,35
machoke,80,100,70,50,60,45
machamp,90,130,80,65,85,55
bellsprout,50,75,35,70,30,40
weepinbell,65,90,50,85,45,55
victreebel,80,105,65,100,60,70
tentacool,40,40,35,50,100,70
tentacruel,80,70,65,80,120,100
geodude,40,80,100,30,30,20
graveler,55,95,115,45,45,35
golem,80,110,130,55,65,45
ponyta,50,85,55,65,65,90
rapidash,65,100,70,80,80,105
slowpoke,90,65,65,40,40,15
slowbro,95,75,110,100,80,30
magnemite,25,35,70,95,55,45
magneton,50,60,95,120,70,70
farfetchd,52,65,55,58,62,60
doduo,35,85,45,35,35,75
dodrio,60,110,70,60,60,100
seel,65,45,55,45,70,45
dewgong,90,70,80,70,95,70
grimer,80,80,50,40,50,25
muk,105,105,75,65,100,50
shellder,30,65,100,45,25,40
cloyster,50,95,180,85,45,70
gastly,30,35,30,100,35,80
haunter,45,50,45,115,55,95
gengar,60,65,60,130,75,110
onix,35,45,160,30,45,70
drowzee,60,48,45,43,90,42
hypno,85,73,70,73,115,67
krabby,30,105,90,25,25,50
kingler,55,130,115,50,50,75
voltorb,40,30,50,55,55,100
electrode,60,50,70,80,80,140
exeggcute,60,40,80,60,45,40
exeggutor,95,95,85,125,65,55
cubone,50,50,95,40,50,35
marowak,60,80,110,50,80,45
hitmonlee,50,120,53,35,110,87
hitmonchan,50,105,79,35,110,76
lickitung,90,55,75,60,75,30
koffing,40,65,95,60,45,35
weezing,65,90,120,85,70,60
rhyhorn,80,85,95,30,30,25
rhydon,105,130,120,45,45,40
chansey,250,5,5,35,105,50
tangela,65,55,115,100,40,60
kangaskhan,105,95,80,40,80,90
horsea,30,40,70,70,25,60
seadra,55,65,95,95,45,85
goldeen,45,67,60,35,50,63
seaking,80,92,65,65,80,68
staryu,30,45,55,70,55,85
starmie,60,75,85,100,85,115
mr mime,40,45,65,100,120,90
scyther,70,110,80,55,80,105
jynx,65,50,35,115,95,95
electabuzz,65,83,57,95,85,105
magmar,65,95,57,100,85,93
pinsir,65,125,100,55,70,85
tauros,75,100,95,40,70,110
magikarp,20,10,55,15,20,80
gyarados,95,125,79,60,100,81
lapras,130,85,80,85,95,60
ditto,48,48,48,48,48,48
eevee,55,55,50,45,65,55
vaporeon,130,65,60,110,95,65
jolteon,65,65,60,110,95,130
flareon,65,130,60,95,110,65
porygon,65,60,70,85,75,40
omanyte,35,40,100,90,55,35
omastar,70,60,125,115,70,55
kabuto,30,80,90,55,45,55
kabutops,60,115,105,65,70,80
aerodactyl,80,105,65,60,75,130
snorlax,160,110,65,65,110,30
articuno,90,85,100,95,125,85
zapdos,90,90,85,125,90,100
moltres,90,100,90,125,85,90
dratini,41,64,45,50,50,50
dragonair,61,84,65,70,70,70
dragonite,91,134,95,100,100,80
mewtwo,106,110,90,154,90,130
mew,100,100,100,100,100,100
chikorita,45,49,65,49,65,45
bayleef,60,62,80,63,80,60
meganium,80,82,100,83,100,80
cyndaquil,39,52,43,60,50,65
quilava,58,64,58,80,65,80
typhlosion,78,84,78,109,85,100
totodile,50,65,64,44,48,43
croconaw,65,80,80,59,63,58
feraligatr,85,105,100,79,83,78
treecko,40,45,35,65,55,70
grovyle,50,65,45,85,65,95
sceptile,70,85,65,105,85,120
torchic,45,60,40,70,50,45
combusken,60,85,60,85,60,55
blaziken,80,120,70,110,70,80
mudkip,50,70,50,50,50,40
marshtomp,70,85,70,60,70,50
swampert,100,110,90,85,90,60
turtwig,55,68,64,45,55,31
grotle,75,89,85,55,65,36
torterra,95,109,105,75,85,56
chimchar,44,58,44,58,44,61
monferno,64,78,52,78,52,81
infernape,76,104,71,104,71,108
piplup,53,51,53,61,56,40
prinplup,64,66,68,81,76,50
empoleon,84,86,88,111,101,60
]]

local function normalizeName(name)
	name = tostring(name or ""):lower()
	name = name:gsub("[%z\1-\31]", "")
	name = name:gsub("[%.']", "")
	name = name:gsub("%-", " ")
	name = name:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
	local prefixes = {
		"shiny ", "mega ", "ancient ", "master ", "guardian ", "sabrina s ",
		"dark ", "alolan ", "galarian ", "brave ", "elder ", "furious ",
		"tribal ", "war ", "perfect ", "mini ", "black ", "white ", "green ",
		"ice ", "light ball ", "golden ", "crystal ", "shadow ",
	}
	local changed = true
	while changed do
		changed = false
		for _, prefix in ipairs(prefixes) do
			if name:sub(1, #prefix) == prefix then
				name = name:sub(#prefix + 1)
				changed = true
			end
		end
	end
	return name:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
end

for line in GBA_STATS_DATA:gmatch("[^\r\n]+") do
	local name, hp, atk, def, spatk, spdef, speed = line:match("^([^,]+),(%d+),(%d+),(%d+),(%d+),(%d+),(%d+)$")
	if name then
		GBA_BASE_STATS[normalizeName(name)] = {
			hp = tonumber(hp),
			atk = tonumber(atk),
			def = tonumber(def),
			spatk = tonumber(spatk),
			spdef = tonumber(spdef),
			speed = tonumber(speed),
		}
	end
end

local function clamp(value, minValue, maxValue)
	value = tonumber(value) or minValue
	if value < minValue then
		return minValue
	end
	if value > maxValue then
		return maxValue
	end
	return value
end

local function normalizeNatureKey(nature)
	nature = tostring(nature or "")
	nature = nature:gsub("[%z\1-\31]", "")
	nature = nature:gsub("%s+", " ")
	nature = nature:gsub("^%s+", ""):gsub("%s+$", "")
	return nature:lower()
end

local function getNatureRecord(nature)
	local key = normalizeNatureKey(nature)
	return NATURE_DATA[key] or NATURE_DATA.hardy
end

local function getNatureName(nature)
	return getNatureRecord(nature).label or "Hardy"
end

local function getNatureMultiplier(ball, statName)
	if not ball or statName == "hp" then
		return 1.0
	end
	local record = getNatureRecord(PokemonLevel.getNature and PokemonLevel.getNature(ball) or nil)
	if record.plus == statName then
		return 1.1
	end
	if record.minus == statName then
		return 0.9
	end
	return 1.0
end

local function getIVKeyForStat(statName)
	local keys = IV_KEYS[statName]
	if not keys then
		return nil
	end
	return keys[1]
end

local function getIVValue(ball, statName)
	if not ball then
		return IV_DEFAULT
	end
	local value = readSpecialAttributeAny(ball, IV_KEYS[statName])
	value = math.floor(tonumber(value) or IV_DEFAULT)
	return clamp(value, 1, 7)
end

local function getModifiedStatValue(ball, pokeName, statName, level, monsterType)
	local stats = PokemonLevel.getBaseStats(pokeName or (ball and ball:getSpecialAttribute("pokeName")), monsterType)
	local baseStat = tonumber(stats[statName] or stats.spatk or 60) or 60
	local ivPercent = getIVValue(ball, statName)
	local adjustedBase = baseStat * (1 + (ivPercent / 100))
	local value = PokemonLevel.gbaStat(adjustedBase, level, statName == "hp")
	return math.floor(value * getNatureMultiplier(ball, statName))
end

local function getMonsterType(pokeName)
	if not pokeName then
		return nil
	end
	return MonsterType(pokeName)
end

local function fallbackStats(pokeName, monsterType)
	monsterType = monsterType or getMonsterType(pokeName)
	if not monsterType then
		return {hp = 60, atk = 60, def = 60, spatk = 60, spdef = 60, speed = 60}
	end

	local hp = math.floor((monsterType:maxHealth() or monsterType:getMaxHealth() or 6000) / 180)
	local attack = monsterType:moveMagicAttackBase() or 60
	local defense = monsterType:moveMagicDefenseBase() or 60
	local speed = math.floor((monsterType:getBaseSpeed() or 120) / 2)

	return {
		hp = clamp(hp, 20, 255),
		atk = clamp(math.floor(attack * 0.75), 20, 255),
		def = clamp(defense, 20, 255),
		spatk = clamp(attack, 20, 255),
		spdef = clamp(defense, 20, 255),
		speed = clamp(speed, 20, 180),
	}
end

function PokemonLevel.normalizeName(name)
	return normalizeName(name)
end

function PokemonLevel.titleCase(str)
	return titleCase(str)
end

-- GBA-based wild level spawn ranges (normalized species name → {min, max})
-- min = minimum level wild can spawn, max = just below next evolution or cap for finals
local GBA_WILD_LEVELS = {
	-- Gen 1 starters
	bulbasaur = {1, 15}, ivysaur = {16, 31}, venusaur = {32, 70},
	charmander = {1, 15}, charmeleon = {16, 35}, charizard = {36, 70},
	squirtle = {1, 15}, wartortle = {16, 35}, blastoise = {36, 70},
	-- Bugs
	caterpie = {1, 6}, metapod = {7, 9}, butterfree = {10, 45},
	weedle = {1, 6}, kakuna = {7, 9}, beedrill = {10, 45},
	-- Birds / rodents
	pidgey = {1, 17}, pidgeotto = {18, 35}, pidgeot = {36, 65},
	rattata = {1, 19}, raticate = {20, 55},
	spearow = {1, 19}, fearow = {20, 55},
	-- Poison
	ekans = {1, 21}, arbok = {22, 55},
	nidoranfe = {1, 15}, nidorina = {16, 35}, nidoqueen = {36, 65},
	nidoranma = {1, 15}, nidorino = {16, 35}, nidoking = {36, 65},
	grimer = {1, 37}, muk = {38, 65},
	koffing = {1, 34}, weezing = {35, 65},
	-- Electric
	pikachu = {5, 35}, raichu = {36, 65},
	magnemite = {1, 29}, magneton = {30, 60},
	voltorb = {1, 29}, electrode = {30, 60},
	-- Ground
	sandshrew = {1, 21}, sandslash = {22, 55},
	diglett = {1, 25}, dugtrio = {26, 55},
	rhyhorn = {1, 41}, rhydon = {42, 70},
	geodude = {1, 24}, graveler = {25, 35}, golem = {36, 65},
	-- Fairy / Normal
	clefairy = {5, 30}, clefable = {31, 65},
	jigglypuff = {5, 30}, wigglytuff = {31, 65},
	chansey = {15, 60}, kangaskhan = {15, 60},
	tauros = {20, 60}, snorlax = {25, 65}, lickitung = {25, 60},
	ditto = {5, 55},
	-- Fire
	vulpix = {5, 35}, ninetales = {36, 65},
	growlithe = {5, 35}, arcanine = {36, 70},
	ponyta = {5, 39}, rapidash = {40, 70},
	magmar = {25, 60},
	-- Water
	poliwag = {1, 24}, poliwhirl = {25, 39}, poliwrath = {40, 65},
	tentacool = {1, 29}, tentacruel = {30, 60},
	seel = {1, 33}, dewgong = {34, 65},
	shellder = {5, 35}, cloyster = {36, 65},
	krabby = {1, 27}, kingler = {28, 60},
	horsea = {1, 31}, seadra = {32, 65},
	goldeen = {1, 32}, seaking = {33, 65},
	staryu = {5, 35}, starmie = {36, 65},
	magikarp = {1, 19}, gyarados = {20, 70},
	lapras = {15, 60},
	omanyte = {5, 39}, omastar = {40, 65},
	kabuto = {5, 39}, kabutops = {40, 65},
	vaporeon = {35, 65}, jolteon = {35, 65}, flareon = {35, 65},
	eevee = {5, 35},
	-- Psychic
	abra = {1, 15}, kadabra = {16, 35}, alakazam = {36, 65},
	slowpoke = {1, 36}, slowbro = {37, 65},
	drowzee = {1, 25}, hypno = {26, 60},
	jynx = {25, 60},
	-- Grass
	oddish = {1, 20}, gloom = {21, 35}, vileplume = {36, 65},
	paras = {1, 23}, parasect = {24, 55},
	venonat = {1, 30}, venomoth = {31, 60},
	bellsprout = {1, 20}, weepinbell = {21, 35}, victreebel = {36, 65},
	exeggcute = {5, 35}, exeggutor = {36, 65},
	tangela = {10, 60},
	-- Fighting
	mankey = {1, 27}, primeape = {28, 60},
	machop = {1, 27}, machoke = {28, 54}, machamp = {55, 75},
	hitmonlee = {30, 65}, hitmonchan = {30, 65},
	-- Ghost
	gastly = {1, 24}, haunter = {25, 35}, gengar = {36, 70},
	-- Dragon
	dratini = {1, 29}, dragonair = {30, 54}, dragonite = {55, 80},
	-- Rock / Steel
	onix = {5, 60},
	pinsir = {20, 65}, scyther = {20, 65},
	aerodactyl = {20, 70},
	-- Flying
	farfetchd = {5, 60},
	doduo = {1, 30}, dodrio = {31, 65},
	-- Misc
	meowth = {1, 27}, persian = {28, 60},
	psyduck = {1, 32}, golduck = {33, 65},
	porygon = {15, 60},
	-- Legendaries
	articuno = {50, 85}, zapdos = {50, 85}, moltres = {50, 85},
	mewtwo = {70, 100}, mew = {40, 85},
	-- Gen 2 starters
	chikorita = {1, 15}, bayleef = {16, 31}, meganium = {32, 70},
	cyndaquil = {1, 14}, quilava = {15, 35}, typhlosion = {36, 70},
	totodile = {1, 17}, croconaw = {18, 29}, feraligatr = {30, 70},
	-- Gen 3 starters
	treecko = {1, 15}, grovyle = {16, 35}, sceptile = {36, 70},
	torchic = {1, 15}, combusken = {16, 35}, blaziken = {36, 70},
	mudkip = {1, 15}, marshtomp = {16, 35}, swampert = {36, 70},
	-- Gen 4 starters
	turtwig = {1, 17}, grotle = {18, 31}, torterra = {32, 70},
	chimchar = {1, 13}, monferno = {14, 35}, infernape = {36, 70},
	piplup = {1, 15}, prinplup = {16, 35}, empoleon = {36, 70},
}

function PokemonLevel.getWildLevelRange(pokeName)
	local normalized = normalizeName(pokeName)
	local range = GBA_WILD_LEVELS[normalized]
	if range then
		return range[1], range[2]
	end
	-- Fallback: use minimumLevel if available, cap at minimumLevel + 20
	return nil, nil
end

function PokemonLevel.getBaseStats(pokeName, monsterType)
	return GBA_BASE_STATS[normalizeName(pokeName)] or fallbackStats(pokeName, monsterType)
end

function PokemonLevel.getExpForLevel(level)
	level = clamp(math.floor(tonumber(level) or 1), 1, PokemonLevel.CONFIG.maxLevel)
	if level <= 1 then
		return 0
	end
	local total = ((6 / 5) * level * level * level) - (15 * level * level) + (100 * level) - 140
	return math.max(0, math.floor(total))
end

function PokemonLevel.getLevelForExp(exp)
	exp = math.max(0, math.floor(tonumber(exp) or 0))
	local level = 1
	for i = 2, PokemonLevel.CONFIG.maxLevel do
		if exp < PokemonLevel.getExpForLevel(i) then
			return level
		end
		level = i
	end
	return PokemonLevel.CONFIG.maxLevel
end

function PokemonLevel.getPokemonLevelByTotalExp(exp)
	return PokemonLevel.getLevelForExp(exp)
end

function PokemonLevel.getMinTotalExpForLevel(level)
	return PokemonLevel.getExpForLevel(level)
end

function PokemonLevel.getExpToNextForLevel(level)
	level = clamp(math.floor(tonumber(level) or 1), 1, PokemonLevel.CONFIG.maxLevel)
	if level >= PokemonLevel.CONFIG.maxLevel then
		return 0
	end
	return math.max(0, PokemonLevel.getExpForLevel(level + 1) - PokemonLevel.getExpForLevel(level))
end

function PokemonLevel.getExpInCurrentLevel(exp)
	exp = math.max(0, math.floor(tonumber(exp) or 0))
	local level = PokemonLevel.getLevelForExp(exp)
	return math.max(0, exp - PokemonLevel.getExpForLevel(level))
end

function PokemonLevel.getRemainingExpToNext(exp)
	exp = math.max(0, math.floor(tonumber(exp) or 0))
	local level = PokemonLevel.getLevelForExp(exp)
	if level >= PokemonLevel.CONFIG.maxLevel then
		return 0
	end
	local currentLevelExp = PokemonLevel.getExpForLevel(level)
	local nextExp = PokemonLevel.getExpForLevel(level + 1)
	return math.max(0, nextExp - exp)
end

function PokemonLevel.rollBL()
	local weights = {
		[0] = 180, [1] = 170, [2] = 150,
		[3] = 120, [4] = 105, [5] = 90,
		[6] = 65, [7] = 50, [8] = 38,
		[9] = 24, [10] = 16, [11] = 8, [12] = 4,
	}
	local total = 0
	for _, weight in pairs(weights) do
		total = total + weight
	end
	local roll = math.random(1, total)
	local cursor = 0
	for bl = 0, 12 do
		cursor = cursor + weights[bl]
		if roll <= cursor then
			return bl
		end
	end
	return 0
end

function PokemonLevel.getLevel(ball)
	if not ball then
		return PokemonLevel.CONFIG.defaultLevel
	end
	return clamp(math.floor(tonumber(ball:getSpecialAttribute("pokeLevel")) or PokemonLevel.CONFIG.defaultLevel), 1, PokemonLevel.CONFIG.maxLevel)
end

function PokemonLevel.getExp(ball)
	if not ball then
		return 0
	end
	return math.max(0, math.floor(tonumber(ball:getSpecialAttribute("pokeExp")) or 0))
end

function PokemonLevel.getBL(ball)
	if not ball then
		return PokemonLevel.CONFIG.defaultLegacyBL
	end
	return clamp(math.floor(tonumber(ball:getSpecialAttribute("pokeBL")) or PokemonLevel.CONFIG.defaultLegacyBL), 0, 12)
end

function PokemonLevel.getEffectiveLevel(ball)
	return clamp(PokemonLevel.getLevel(ball) + PokemonLevel.getBL(ball), 1, PokemonLevel.CONFIG.maxLevel + 12)
end

function PokemonLevel.ensureBall(ball, pokeName, options)
	if not ball then
		return false
	end
	options = options or {}
	pokeName = pokeName or ball:getSpecialAttribute("pokeName")
	if pokeName and not ball:getSpecialAttribute("pokeName") then
		ball:setSpecialAttribute("pokeName", pokeName)
	end

	local level = tonumber(ball:getSpecialAttribute("pokeLevel"))
	if not level then
		level = options.level or PokemonLevel.CONFIG.defaultLevel
		ball:setSpecialAttribute("pokeLevel", clamp(level, 1, PokemonLevel.CONFIG.maxLevel))
	end

	local exp = tonumber(ball:getSpecialAttribute("pokeExp"))
	if not exp then
		local initialExp = options.exp
		if initialExp == nil then
			initialExp = PokemonLevel.getExpForLevel(PokemonLevel.getLevel(ball))
		end
		ball:setSpecialAttribute("pokeExp", math.max(0, math.floor(initialExp)))
		exp = tonumber(ball:getSpecialAttribute("pokeExp")) or 0
	end

	local normalizedLevel = PokemonLevel.getLevel(ball)
	local currentLevelExp = PokemonLevel.getExpForLevel(normalizedLevel)
	local nextLevelExp = PokemonLevel.getExpForLevel(math.min(normalizedLevel + 1, PokemonLevel.CONFIG.maxLevel))

	-- Corrige pokebolas antigas/inconsistentes que ficaram com pokeExp fora da
	-- faixa do level salvo, deixando a barra presa em 100% ou abaixo de 0%.
	if exp < currentLevelExp or (normalizedLevel < PokemonLevel.CONFIG.maxLevel and exp >= nextLevelExp) then
		exp = currentLevelExp
		ball:setSpecialAttribute("pokeExp", exp)
	end

	local storedNature = PokemonLevel.getNature(ball)
	writeNature(ball, storedNature == "None" and "Hardy" or storedNature)

	for _, statName in ipairs(STAT_ORDER) do
		local ivValue = readSpecialAttributeAny(ball, IV_KEYS[statName])
		if ivValue == nil then
			ivValue = IV_DEFAULT
		end
		writeIV(ball, statName, ivValue)
	end

	if ball:getSpecialAttribute("pokeBoost") == nil then
		ball:setSpecialAttribute("pokeBoost", 0)
	end

	local bl = tonumber(ball:getSpecialAttribute("pokeBL"))
	if bl == nil then
		if options.generateBL then
			bl = PokemonLevel.rollBL()
		else
			bl = PokemonLevel.CONFIG.defaultLegacyBL
		end
		ball:setSpecialAttribute("pokeBL", clamp(bl, 0, 12))
	end

	return true
end

function PokemonLevel.initializeBall(ball, pokeName, options)
	options = options or {}
	options.generateBL = options.generateBL ~= false
	options.level = options.level or PokemonLevel.CONFIG.defaultLevel
	options.exp = options.exp or PokemonLevel.getExpForLevel(options.level)
	local ok = PokemonLevel.ensureBall(ball, pokeName, options)
	if ok then
		if not ball:getSpecialAttribute("pokeNature") then
			writeNature(ball, "Hardy")
		end
		for _, statName in ipairs(STAT_ORDER) do
			if readSpecialAttributeAny(ball, IV_KEYS[statName]) == nil then
				writeIV(ball, statName, IV_DEFAULT)
			end
		end
	end
	return ok
end

function PokemonLevel.rerollBL(ball)
	if not ball then
		return false
	end
	local oldBL = PokemonLevel.getBL(ball)
	local newBL = PokemonLevel.rollBL()
	ball:setSpecialAttribute("pokeBL", newBL)
	return newBL, oldBL
end

function PokemonLevel.setBL(ball, value)
	if not ball then
		return false
	end
	value = clamp(math.floor(tonumber(value) or 0), 0, 12)
	ball:setSpecialAttribute("pokeBL", value)
	return value
end

function PokemonLevel.addLevel(ball, amount)
	if not ball then
		return 0, 0
	end
	amount = math.floor(tonumber(amount) or 1)
	if amount == 0 then
		return PokemonLevel.getLevel(ball), PokemonLevel.getLevel(ball)
	end
	PokemonLevel.ensureBall(ball)
	local oldLevel = PokemonLevel.getLevel(ball)
	local newLevel = clamp(oldLevel + amount, 1, PokemonLevel.CONFIG.maxLevel)
	ball:setSpecialAttribute("pokeLevel", newLevel)
	ball:setSpecialAttribute("pokeExp", PokemonLevel.getExpForLevel(newLevel))
	return newLevel, oldLevel
end

function PokemonLevel.addExp(ball, amount)
	if not ball then
		return 0, 0, 0
	end
	PokemonLevel.ensureBall(ball)
	local oldLevel = PokemonLevel.getLevel(ball)
	if oldLevel >= PokemonLevel.CONFIG.maxLevel then
		ball:setSpecialAttribute("pokeExp", PokemonLevel.getExpForLevel(PokemonLevel.CONFIG.maxLevel))
		return 0, oldLevel, oldLevel
	end
	local currentExp = PokemonLevel.getExp(ball)
	local gain = math.max(0, math.floor(tonumber(amount) or 0))
	local newExp = math.min(PokemonLevel.getExpForLevel(PokemonLevel.CONFIG.maxLevel), currentExp + gain)
	local newLevel = PokemonLevel.getLevelForExp(newExp)
	ball:setSpecialAttribute("pokeExp", newExp)
	if newLevel ~= oldLevel then
		ball:setSpecialAttribute("pokeLevel", newLevel)
	end
	return gain, oldLevel, newLevel
end

function PokemonLevel.addExperienceFromPlayerGain(ball, playerExp)
	local gain = math.floor((tonumber(playerExp) or 0) * PokemonLevel.CONFIG.expShare)
	gain = math.min(gain, PokemonLevel.CONFIG.maxExpGainPerKill)
	return PokemonLevel.addExp(ball, gain)
end

writeNature = function(ball, natureName)
	if not ball then
		return false
	end
	local normalized = getNatureName(natureName)
	ball:setSpecialAttribute("pokeNature", normalized)
	ball:setSpecialAttribute("nature", normalized)
	ball:setSpecialAttribute("Nature", normalized)
	return normalized
end

writeIV = function(ball, statName, value)
	local key = getIVKeyForStat(statName)
	if not ball or not key then
		return false
	end
	value = clamp(math.floor(tonumber(value) or IV_DEFAULT), 1, 7)
	for _, attrKey in ipairs(IV_KEYS[statName]) do
		ball:setSpecialAttribute(attrKey, value)
	end
	return value
end

function PokemonLevel.getBoost(ball, includeHeldBoost)
	if not ball then
		return 0
	end
	local boost = math.max(0, math.floor(tonumber(ball:getSpecialAttribute("pokeBoost")) or 0))
	if includeHeldBoost then
		local heldx = ball:getAttribute(ITEM_ATTRIBUTE_HELDX)
		if isHeld and type(isHeld) == "function" then
			if isHeld("boost", heldx) and HELDS_X_INFO and HELDS_BONUS and HELDS_X_INFO[heldx] then
				local tier = HELDS_X_INFO[heldx].tier
				local bonusHeld = HELDS_BONUS.boost and HELDS_BONUS.boost[tier] or 0
				boost = boost + bonusHeld
			end
		end
	end
	return boost
end

function PokemonLevel.setBoost(ball, value)
	if not ball then
		return false
	end
	local maxBoost = (PokemonLevel.CONFIG and PokemonLevel.CONFIG.progression and PokemonLevel.CONFIG.progression.maxBoost) or 50000
	value = clamp(math.floor(tonumber(value) or 0), 0, maxBoost)
	ball:setSpecialAttribute("pokeBoost", value)
	return value
end

function PokemonLevel.setPokemonTotalExp(ball, totalExp)
	if not ball then
		return false
	end
	PokemonLevel.ensureBall(ball)
	totalExp = math.max(0, math.floor(tonumber(totalExp) or 0))
	local maxTotalExp = PokemonLevel.getExpForLevel(PokemonLevel.CONFIG.maxLevel)
	totalExp = math.min(totalExp, maxTotalExp)
	local level = PokemonLevel.getPokemonLevelByTotalExp(totalExp)
	ball:setSpecialAttribute("pokeExp", totalExp)
	ball:setSpecialAttribute("pokeLevel", level)
	return totalExp, level
end

function PokemonLevel.setNature(ball, nature)
	if not ball then
		return false
	end
	if type(nature) == "number" then
		local index = clamp(math.floor(nature), 1, #NATURE_ORDER)
		local record = getNatureRecord(NATURE_ORDER[index])
		return writeNature(ball, record.label)
	end
	nature = cleanSpaces(nature or "")
	if nature == "" then
		return writeNature(ball, "Hardy")
	end
	local record = getNatureRecord(nature)
	return writeNature(ball, record.label)
end

function PokemonLevel.rerollNature(ball)
	if not ball then
		return false
	end
	local pick = NATURE_ORDER[math.random(1, #NATURE_ORDER)]
	return writeNature(ball, getNatureRecord(pick).label)
end

function PokemonLevel.setIV(ball, statName, value)
	if not ball then
		return false
	end
	statName = tostring(statName or ""):lower()
	if not IV_KEYS[statName] then
		return false
	end
	return writeIV(ball, statName, value)
end

function PokemonLevel.rerollIVs(ball)
	if not ball then
		return false
	end
	for _, statName in ipairs(STAT_ORDER) do
		writeIV(ball, statName, math.random(1, 7))
	end
	return true
end

function PokemonLevel.getNatureDetails(ball)
	local record = getNatureRecord(PokemonLevel.getNature(ball))
	return {
		key = normalizeNatureKey(record.label),
		label = record.label,
		effectText = record.effectText,
		impactText = record.impactText,
		plus = record.plus,
		minus = record.minus,
	}
end

function PokemonLevel.getIVDetails(ball)
	local ivs = PokemonLevel.getIVs(ball)
	local details = {
		values = ivs,
	}
	local lines = {}
	for _, statName in ipairs(STAT_ORDER) do
		lines[#lines + 1] = string.format("%s %s", STAT_LABELS[statName], tostring(ivs[statName]))
	end
	details.text = table.concat(lines, " | ")
	details.ruleText = "Valor salvo 1-7 interpretado como 1% a 7% real sobre o Base Stat correspondente antes do gbaStat."
	return details
end

local function buildInstanceProfile(ball, pokeName, monsterType, progress, currentStats, baseStats, options)
	options = options or {}
	if not ball then
		return {
			hasInstance = false,
			progress = progress,
			currentStats = currentStats or {},
			baseStats = baseStats or {},
			ivs = {},
			ivDetails = {},
			nature = "",
			natureDetails = getNatureRecord("Hardy"),
			blText = "-",
			expText = "",
			boost = 0,
		}
	end

	local nature = PokemonLevel.getNature(ball)
	local natureDetails = PokemonLevel.getNatureDetails(ball)
	local ivs = PokemonLevel.getIVs(ball)
	local ivDetails = PokemonLevel.getIVDetails(ball)
	local boost = math.max(0, math.floor(tonumber(options.boost or PokemonLevel.getBoost(ball, false)) or 0))
	local blText = tostring(progress.bl or PokemonLevel.getBL(ball))
	local expText = PokemonLevel.getExpText(ball)

	return {
		hasInstance = true,
		progress = progress,
		currentStats = currentStats or {},
		baseStats = baseStats or {},
		ivs = ivs,
		ivDetails = ivDetails,
		nature = nature,
		natureDetails = natureDetails,
		bl = progress.bl,
		blText = blText,
		expText = expText,
		boost = boost,
		pokeName = pokeName,
		monsterType = monsterType,
	}
end

function PokemonLevel.gbaStat(baseStat, level, isHp)
	level = clamp(math.floor(tonumber(level) or 1), 1, PokemonLevel.CONFIG.maxLevel + 12)
	baseStat = math.max(1, tonumber(baseStat) or 1)
	if isHp then
		return math.floor(((2 * baseStat * level) / 100) + level + 10)
	end
	return math.floor(((2 * baseStat * level) / 100) + 5)
end

function PokemonLevel.getStatScale(ball, pokeName, statName, monsterType)
	if not ball then
		return 1.0
	end
	PokemonLevel.ensureBall(ball, pokeName)
	statName = statName or "spatk"
	local stats = PokemonLevel.getBaseStats(pokeName or ball:getSpecialAttribute("pokeName"), monsterType)
	local baseStat = tonumber(stats[statName] or stats.spatk or 60) or 60
	local effectiveLevel = PokemonLevel.getEffectiveLevel(ball)
	local isHp = statName == "hp"
	local baseValue = PokemonLevel.gbaStat(baseStat, 1, isHp)
	local currentValue = PokemonLevel.gbaStat(baseStat, effectiveLevel, isHp)
	local diff = math.max(0, currentValue - baseValue)
	local scale = 1 + (diff * (PokemonLevel.CONFIG.statScale[statName] or 0.0025))
	local ivBonus = 1 + (getIVValue(ball, statName) / 100)
	local natureBonus = getNatureMultiplier(ball, statName)
	scale = scale * ivBonus * natureBonus
	return clamp(scale, 1.0, PokemonLevel.CONFIG.statScaleCap[statName] or 2.0)
end

function PokemonLevel.getDisplayStats(ball, pokeName, monsterType)
	local poke = pokeName or (ball and ball:getSpecialAttribute("pokeName"))
	local stats = PokemonLevel.getBaseStats(poke, monsterType)
	local effectiveLevel = ball and PokemonLevel.getEffectiveLevel(ball) or PokemonLevel.CONFIG.defaultLevel
	local result = {}
	for _, statName in ipairs(STAT_ORDER) do
		result[statName] = getModifiedStatValue(ball, poke, statName, effectiveLevel, monsterType)
	end
	return result
end

local PHYSICAL_TYPES = {
	physical = true,
	normal = true,
	fighting = true,
	flying = true,
	poison = true,
	ground = true,
	earth = true,
	rock = true,
	bug = true,
	ghost = true,
	steel = true,
}

local SPECIAL_TYPES = {
	fire = true,
	water = true,
	grass = true,
	electric = true,
	psychic = true,
	ice = true,
	dragon = true,
	dark = true,
	fairy = true,
	energy = true,
}

function PokemonLevel.getDamageCategory(combatName)
	combatName = tostring(combatName or ""):lower()
	if PHYSICAL_TYPES[combatName] then
		return "physical"
	end
	if SPECIAL_TYPES[combatName] then
		return "special"
	end
	return "special"
end

local function getBallFromPokemon(creature)
	if not creature or not creature:isPokemon() then
		return nil
	end
	local master = creature:getMaster()
	if not master or not master:isPlayer() then
		return nil
	end
	return master:getUsingBall()
end

function PokemonLevel.getCreatureAttackScale(creature, category)
	local ball = getBallFromPokemon(creature)
	if not ball then
		return 1.0
	end
	local statName = category == "physical" and "atk" or "spatk"
	return PokemonLevel.getStatScale(ball, ball:getSpecialAttribute("pokeName"), statName)
end

function PokemonLevel.getCreatureDefenseScale(creature, category)
	local ball = getBallFromPokemon(creature)
	if not ball then
		return 1.0
	end
	local statName = category == "physical" and "def" or "spdef"
	return PokemonLevel.getStatScale(ball, ball:getSpecialAttribute("pokeName"), statName)
end

function PokemonLevel.getProgressInfo(ball)
	if not ball then
		return {
			level = 1,
			exp = 0,
			totalExp = 0,
			nextExp = 0,
			expToNext = 0,
			currentLevelExp = 0,
			expInCurrentLevel = 0,
			remainingExpToNext = 0,
			percent = 0,
			bl = 0,
		}
	end
	PokemonLevel.ensureBall(ball)
	local level = PokemonLevel.getLevel(ball)
	local exp = PokemonLevel.getExp(ball)
	local currentLevelExp = PokemonLevel.getExpForLevel(level)
	local nextExp = PokemonLevel.getExpForLevel(math.min(level + 1, PokemonLevel.CONFIG.maxLevel))
	local expToNext = PokemonLevel.getExpToNextForLevel(level)
	local expInCurrentLevel = PokemonLevel.getExpInCurrentLevel(exp)
	local remainingExpToNext = PokemonLevel.getRemainingExpToNext(exp)
	local percent = 100
	if level < PokemonLevel.CONFIG.maxLevel then
		percent = math.floor(((exp - currentLevelExp) / math.max(1, nextExp - currentLevelExp)) * 100)
	end
	return {
		level = level,
		exp = exp,
		totalExp = exp,
		nextExp = nextExp,
		expToNext = expToNext,
		currentLevelExp = currentLevelExp,
		expInCurrentLevel = expInCurrentLevel,
		remainingExpToNext = remainingExpToNext,
		percent = clamp(percent, 0, 100),
		bl = PokemonLevel.getBL(ball),
	}
end

local STAT_LABELS = {
	hp = "HP",
	atk = "ATK",
	def = "DEF",
	spatk = "SPATK",
	spdef = "SPDEF",
	speed = "SPEED",
}

IV_KEYS = {
	hp = {"pokeIVHP", "pokeIvHP", "ivHP", "iv_hp", "IV_HP"},
	atk = {"pokeIVATK", "pokeIvATK", "ivATK", "iv_atk", "IV_ATK"},
	def = {"pokeIVDEF", "pokeIvDEF", "ivDEF", "iv_def", "IV_DEF"},
	spatk = {"pokeIVSPATK", "pokeIvSPATK", "ivSPATK", "iv_spatk", "IV_SPATK"},
	spdef = {"pokeIVSPDEF", "pokeIvSPDEF", "ivSPDEF", "iv_spdef", "IV_SPDEF"},
	speed = {"pokeIVSPEED", "pokeIvSPEED", "ivSPEED", "iv_speed", "IV_SPEED"},
}

local function cleanSpaces(value)
	value = tostring(value or ""):gsub("%s+", " ")
	return value:gsub("^%s+", ""):gsub("%s+$", "")
end

local function titleCase(str)
	str = tostring(str or "")
	return (str:gsub("(%a)([%w_']*)", function(first, rest)
		return first:upper() .. rest:lower()
	end))
end

readSpecialAttributeAny = function(ball, keys)
	if not ball then
		return nil
	end
	for _, key in ipairs(keys) do
		local value = ball:getSpecialAttribute(key)
		if value ~= nil then
			return value
		end
	end
	return nil
end

function PokemonLevel.formatOverheadName(pokeName, level, boost, includeBoost)
	pokeName = titleCase(cleanSpaces(pokeName))
	if pokeName == "" then
		pokeName = "Pokemon"
	end

	level = math.max(1, math.floor(tonumber(level) or PokemonLevel.CONFIG.defaultLevel))
	if includeBoost then
		boost = math.max(0, math.floor(tonumber(boost) or 0))
		if boost >= 1 then
			return string.format("%s [%d +%d]", pokeName, level, boost)
		end
	end
	return string.format("%s [%d]", pokeName, level)
end

function PokemonLevel.getExpText(ball)
	if not ball then
		return "XP: 0 / " .. PokemonLevel.getExpForLevel(2)
	end

	local progress = PokemonLevel.getProgressInfo(ball)
	if progress.level >= PokemonLevel.CONFIG.maxLevel then
		return "XP: MAX"
	end
	return string.format("XP: %d / %d", progress.exp, progress.nextExp)
end

function PokemonLevel.getNature(ball)
	local nature = readSpecialAttributeAny(ball, {"pokeNature", "nature", "Nature"})
	nature = cleanSpaces(nature or "")
	if nature == "" then
		return getNatureName("Hardy")
	end
	return getNatureName(nature)
end

function PokemonLevel.getIVs(ball)
	local ivs = {}
	for _, statName in ipairs(STAT_ORDER) do
		local value = readSpecialAttributeAny(ball, IV_KEYS[statName])
		if value == nil then
			ivs[statName] = IV_DEFAULT
		else
			ivs[statName] = math.floor(tonumber(value) or IV_DEFAULT)
		end
	end
	return ivs
end

local function buildStatsText(title, stats)
	local lines = {title .. ":"}
	for _, statName in ipairs(STAT_ORDER) do
		lines[#lines + 1] = string.format("%s: %s", STAT_LABELS[statName], tostring(stats[statName] or "N/A"))
	end
	return table.concat(lines, "\n")
end

function PokemonLevel.buildDisplayData(ball, pokeName, monsterType, options)
	options = options or {}
	pokeName = cleanSpaces(pokeName or (ball and ball:getSpecialAttribute("pokeName")) or "")
	if pokeName == "" then
		pokeName = "Pokemon"
	end

	if ball then
		PokemonLevel.ensureBall(ball, pokeName)
	end

	local progress = ball and PokemonLevel.getProgressInfo(ball) or {
		level = 1,
		exp = 0,
		totalExp = 0,
		nextExp = PokemonLevel.getExpForLevel(2),
		expToNext = PokemonLevel.getExpToNextForLevel(1),
		currentLevelExp = 0,
		expInCurrentLevel = 0,
		remainingExpToNext = PokemonLevel.getExpToNextForLevel(1),
		percent = 0,
		bl = 0,
	}
	local boost = math.max(0, math.floor(tonumber(options.boost or (ball and ball:getSpecialAttribute("pokeBoost")) or 0) or 0))
	local baseStats = PokemonLevel.getBaseStats(pokeName, monsterType)
	local currentStats = ball and PokemonLevel.getDisplayStats(ball, pokeName, monsterType) or {}
	if not ball then
		for _, statName in ipairs(STAT_ORDER) do
			currentStats[statName] = PokemonLevel.gbaStat(baseStats[statName], progress.level, statName == "hp")
		end
	end

	local ivs = PokemonLevel.getIVs(ball)
	local nature = PokemonLevel.getNature(ball)
	local natureDetails = PokemonLevel.getNatureDetails(ball)
	local ivDetails = PokemonLevel.getIVDetails(ball)
	local hasInstance = ball ~= nil
	local blText = hasInstance and tostring(progress.bl) or "Individual"
	local expText = ball and PokemonLevel.getExpText(ball) or "XP: Individual"
	local overheadName = PokemonLevel.formatOverheadName(pokeName, progress.level, boost, options.includeBoost == true)
	local instanceProfile = buildInstanceProfile(ball, pokeName, monsterType, progress, currentStats, baseStats, {boost = boost})

	local description = table.concat({
		string.format("Especie: %s", pokeName),
		string.format("Level: %d", progress.level),
		"BL: " .. blText,
		"Nature: " .. nature,
		"",
		buildStatsText("Base Stats", baseStats),
		"",
		buildStatsText("Current Stats", currentStats),
		"",
		buildStatsText("IV", ivs),
	}, "\n")

	return {
		species = pokeName,
		level = progress.level,
		boost = boost,
		bl = progress.bl,
		blText = blText,
		nature = nature,
		natureDetails = natureDetails,
		ivs = ivs,
		ivDetails = ivDetails,
		progress = progress,
		expText = expText,
		overheadName = overheadName,
		baseStats = baseStats,
		currentStats = currentStats,
		instanceProfile = instanceProfile,
		statsSections = {
			{title = "Base Stats", stats = baseStats},
			{title = "Current Stats", stats = currentStats},
			{title = "IV", stats = ivs},
		},
		description = description,
		hasInstance = hasInstance,
	}
end
