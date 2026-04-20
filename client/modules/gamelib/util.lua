function postostring(pos)
  return pos.x .. " " .. pos.y .. " " .. pos.z
end

function dirtostring(dir)
  for k,v in pairs(Directions) do
    if v == dir then
      return k
    end
  end
end

function getHealthColor(health)
	return health < 9 and "#AB2F2FFA" or health < 31 and "#DF6E56" or health < 61 and "#D7CB60EB" or "#23B266"
end

function isShinyName(pokemonName)
	return string.find(pokemonName, "shiny") ~= nil
end

function getPokemonName(pokemonName)
	return isShinyName(pokemonName) and pokemonName:match("shiny (.*)") or pokemonName
end

function getPokemonImage(pokemonName)
	local name = pokemonName and pokemonName:lower() or "none"
	local cleanName = getPokemonName(name):lower()

	-- Tenta primeiro o portrait
	if g_resources.fileExists("/data/images/game/portrait/" .. cleanName .. ".png") then
		return "/data/images/game/portrait/" .. cleanName
	end

	-- Fallback para pokemon regular
	local folder = isShinyName(name) and "/pokemon/shiny/" or "/pokemon/regular/"
	if g_resources.fileExists(folder .. cleanName .. ".png") then
		return folder .. cleanName
	end

	return "/pokemon/regular/abra" -- fallback
end

function getPokemonPortrait(pokemonName)
	return getPokemonImage(pokemonName)
end
