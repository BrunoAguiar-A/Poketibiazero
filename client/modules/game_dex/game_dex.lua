local OPCODE = 80
local currentHoveredWidget
pokedexWindow2, pokedexWindow = nil
local timing = os.clock()
local generated = false
local infoPokes
local pokemons = {}

function updateText(description, text, speed, startTime, index)
	local currentTime = os.clock()
	if currentTime - startTime >= 1 / speed then
		local currentText = string.sub(text, 1, index)
		description:setText(currentText)
		index = index + 1
		startTime = currentTime
	end
	if index <= #text then
		currentAnimation = scheduleEvent(function() updateText(description, text, speed, startTime, index) end)
	else
		isAnimating = false
		currentAnimation = nil
	end
end

function sendPokeBuffer(id)
	local buffer = {
		type     = "showPoke",
		pokeName = id,
	}
	g_game.getProtocolGame():sendExtendedOpcode(OPCODE, json.encode(buffer))
end

function getOpCode(protocol, opcode, json_data)
	local action = json_data['action']
	local data = json_data['data']
	local status = json_data['status']
	if not action or not data then
		return false
	end
	if action == "sendInformation" then
		showInformation(data)
	end

	if action == "lists" then
		pokemons = data
	end

	if action == "updateList" then
		local id = data.id
		local pokename = capitalizeFirstLetter(pokemons[id].name)
		for _, child in ipairs(pokedexWindow.panelSearch:getChildren()) do
			local childId = capitalizeFirstLetter(child:getId())
			if childId == pokename then
				child.nome:setText(pokename)
				child.nome:setColor("green")
				child.pokemonImageSearch:setOutfit({ type = pokemons[id].outfit.type })
				break
			end
		end
		pokemons[id] = { name = pokemons[id].name, found = true, outfit = { type = pokemons[id].outfit.type } }
	end
end

function capitalizeFirstLetter(word)
	if not word then
		return ""
	end
	word = string.lower(word)
	return word:gsub("(%l)(%w*)", function(a, b) return string.upper(a) .. b end)
end

function showInformation(data)
	local dexInfo = data.info

	local typePokemon = dexInfo.type
	local typePokemon2 = dexInfo.type2

	local entryPokemon = dexInfo.entry
	local namePokemon = dexInfo.name

	local habilidades = {
		blink = dexInfo.blink,
		teleport = dexInfo.teleport,
		dig = dexInfo.dig,
		smash = dexInfo.smash,
		cut = dexInfo.cut,
		light = dexInfo.light,
		levitate = dexInfo.levitate,
		controlmind = dexInfo.controlmind,
		fly = dexInfo.fly,
		ride = dexInfo.ride,
		surf = dexInfo.surf,
		-- headbutt =			dexInfo.headbutt,
	}

	namePokemon = namePokemon:lower()
	local funcaoPokemon = dexInfo.funcao
	if funcaoPokemon and funcaoPokemon ~= "" then
		pokedexWindow.funcao:setImageSource("new_images/funcoes/" .. funcaoPokemon)
	end

	local hasShiny = dexInfo.hasShiny
	pokedexWindow.hasShiny:setVisible(false)
	if hasShiny then
		pokedexWindow.hasShiny:setVisible(true)
		pokedexWindow.pokemonImage.onClick = function ()
			sendPokeBuffer("shiny " .. namePokemon)
		end
	elseif string.find(namePokemon, "shiny ") then
		local getShinyName = string.match(namePokemon:lower(), "shiny" .. "%s*(.+)")
		pokedexWindow.pokemonImage.onClick = function ()
			sendPokeBuffer(getShinyName)
		end
	elseif string.find(namePokemon, "mega ") then
		local getMegaName = string.match(namePokemon:lower(), "mega" .. "%s*(.+)")
		pokedexWindow.pokemonImage.onClick = function ()
			sendPokeBuffer(getMegaName)
		end
	else
		pokedexWindow.pokemonImage.onClick = nil
	end

	if typePokemon ~= "none" then
		pokedexWindow.pokemonType:setImageSource("images/types/" .. typePokemon)
		pokedexWindow.pokemonType:setTooltip(textTypes[typePokemon])
	else
		pokedexWindow.pokemonType:setImageSource("")
		pokedexWindow.pokemonType:setTooltip("")
	end

	if typePokemon2 ~= "none" then
		pokedexWindow.pokemonType2:setImageSource("images/types/" .. typePokemon2)
		pokedexWindow.pokemonType2:setTooltip(textTypes[typePokemon2])
	else
		pokedexWindow.pokemonType2:setImageSource("")
		pokedexWindow.pokemonType2:setTooltip("")
	end

	if namePokemon ~= "" then
		local nami = capitalizeFirstLetter(namePokemon)
		pokedexWindow.pokemonName:setText(nami)
	end

	pokedexWindow.pokemonImage:setOutfit({ type = dexInfo.looktype })
	pokedexWindow.pokemonImage:setOldScaling(true)
	pokedexWindow.pokemonImage:setAnimate(true)
	pokedexWindow.pokemonEntry:setText("#" .. entryPokemon)
	pokedexWindow.pokemonRank:setText(dexInfo.rank)

	local painelHabilidades = pokedexWindow.panelAbilities

	painelHabilidades:destroyChildren()
	for i, hability in pairs(habilidades) do
		if hability then
			local widget = g_ui.createWidget("abilitiesButton", painelHabilidades)
			widget:setImageSource("images/abilities/" .. i)
			widget:setTooltip(habilidadesDescription[i])
		end
	end

	local buttonsMain = pokedexWindow.buttonsPokemon
	local textButton = pokedexWindow.textButtons
	local description = buttonsMain.description
	local estatisticas = buttonsMain.estatisticas
	local efetividade = buttonsMain.efetividade
	local moves = buttonsMain.moves
	local loot = buttonsMain.loot
	local textBox = pokedexWindow.panelDesc.description
	local statsPanel = pokedexWindow.panelStats
	local statsTextBox = pokedexWindow.panelStats.statsText
	local instanceData = dexInfo.instanceData or {}
	local legacyStatsWidgets = {
		"healthLabel", "progressHP_base", "progressHP",
		"defenseLabel", "progressDEF_base", "progressDEF",
		"speedLabel", "progressSpeed_base", "progressSpeed",
		"attackLabel", "progressAttack_base", "progressAttack",
	}
	local statLabels = {
		hp = "HP",
		atk = "ATK",
		def = "DEF",
		spatk = "SPATK",
		spdef = "SPDEF",
		speed = "SPEED"
	}
	local statOrder = {"hp", "atk", "def", "spatk", "spdef", "speed"}

	local function trimText(value)
		value = tostring(value or "")
		value = value:gsub("\r\n", "\n")
		value = value:gsub("^%s+", "")
		value = value:gsub("%s+$", "")
		return value
	end

	local function toNumber(value, fallback)
		local number = tonumber(value)
		if number == nil then
			return fallback or 0
		end
		return number
	end

	local function buildSpeciesDescription()
		local lines = {}

		if not shiny then
			for _, evo in ipairs(dexInfo.evo) do
				if evo.name then
					local evoname = capitalizeFirstLetter(evo.name)
					local evoItemName = capitalizeFirstLetter(evo.itemName or "")
					lines[#lines + 1] = "Evolucao: " .. evoname
					if evo.count and evoItemName ~= "" then
						lines[#lines + 1] = "Custo: " .. evo.count .. " " .. evoItemName
					end
					if evo.level then
						lines[#lines + 1] = "Level Minimo: " .. evo.level
					end
					lines[#lines + 1] = ""
				end
			end
		end

		if #lines > 0 and lines[#lines] == "" then
			table.remove(lines, #lines)
		end

		return trimText(table.concat(lines, "\n"))
	end

	local function getExpData()
		local progress = instanceData.progress or dexInfo.expProgress or {}
		local currentInLevel = progress.expInCurrentLevel
		if currentInLevel == nil then
			currentInLevel = progress.currentInLevel
		end
		local requiredForLevel = progress.expToNext
		if requiredForLevel == nil then
			requiredForLevel = progress.requiredForLevel
		end

		return {
			currentInLevel = currentInLevel,
			requiredForLevel = requiredForLevel,
			totalExp = progress.totalExp or dexInfo.totalExp,
			percent = progress.percent or dexInfo.expPercent or dexInfo.xpPercent or 0
		}
	end

	local function buildExpDisplay()
		if instanceData.hasInstance == false or dexInfo.hasInstance == false then
			return "-"
		end

		local expData = getExpData()
		if expData.currentInLevel ~= nil and expData.requiredForLevel ~= nil then
			return string.format("%s / %s (%d%%)", tostring(expData.currentInLevel), tostring(expData.requiredForLevel), toNumber(expData.percent, 0))
		end

		local expText = trimText(instanceData.expText or dexInfo.expText)
		if expText ~= "" then
			return expText:gsub("^XP:%s*", "")
		end

		return "-"
	end

	local function buildExpTotalDisplay()
		if instanceData.hasInstance == false or dexInfo.hasInstance == false then
			return "-"
		end

		local expData = getExpData()
		if expData.totalExp ~= nil then
			return tostring(expData.totalExp)
		end
		return "-"
	end

	local function getStatValue(stats, statName)
		return toNumber(stats[statName], 0)
	end

	local function getStatDisplay(stats, statName, blankWhenMissing)
		if blankWhenMissing and stats[statName] == nil then
			return "-"
		end
		return tostring(getStatValue(stats, statName))
	end

	local function getIvRowValue(statName)
		local ivDetails = instanceData.ivDetails or {}
		local ivDetail = ivDetails[statName] or {}
		local rawValue = ivDetail.raw
		if rawValue == nil then
			rawValue = ((instanceData.ivs or dexInfo.ivs or dexInfo.iv or {})[statName])
		end
		if rawValue == nil then
			return "-", ""
		end

		local tooltipParts = {
			"Valor salvo: " .. tostring(rawValue) .. " (" .. tostring(ivDetail.displayPercent or (tostring(rawValue) .. "%")) .. ")",
		}
		if ivDetail.baseBonusDisplay ~= nil then
			tooltipParts[#tooltipParts + 1] = "Bonus sobre Base Stat: +" .. tostring(ivDetail.baseBonusDisplay)
		end
		if ivDetail.finalImpact ~= nil then
			tooltipParts[#tooltipParts + 1] = "Impacto final: " .. string.format("%+d", ivDetail.finalImpact)
		end
		if trimText(instanceData.ivRule) ~= "" then
			tooltipParts[#tooltipParts + 1] = instanceData.ivRule
		end

		return tostring(ivDetail.displayPercent or (tostring(rawValue) .. "%")), table.concat(tooltipParts, "\n")
	end

	local function formatStatsLine(label, value)
		value = tostring(value)
		local labelText = label .. ":"
		if #value <= 15 then
			return string.format("%-16s %15s", labelText, value)
		end
		return string.format("%-16s %s", labelText, value)
	end

	local function formatComparisonLine(leftLabel, leftValue, rightLabel, rightValue)
		local left = string.format("%-10s %5s", leftLabel .. ":", tostring(leftValue))
		local right = string.format("%-12s %5s", rightLabel .. ":", tostring(rightValue))
		return left .. "  " .. right
	end

	local function hideLegacyStatsWidgets()
		for _, widgetId in ipairs(legacyStatsWidgets) do
			local widget = pokedexWindow[widgetId]
			if widget then
				widget:setVisible(false)
			end
		end
	end

	hideLegacyStatsWidgets()

	function showEstatisticas()
		local hasInstance = instanceData.hasInstance
		if hasInstance == nil then
			hasInstance = dexInfo.hasInstance
		end

		local baseStats = instanceData.baseStats or dexInfo.baseStats or dexInfo.statusBase or {}
		local currentStats = instanceData.currentStats or dexInfo.currentStats or dexInfo.statusCurrent or {}
		local vitality = instanceData.vitality or dexInfo.vitality or {}
		local natureDetails = instanceData.natureDetails or {}
		local natureName = trimText(natureDetails.name or instanceData.nature or dexInfo.nature)
		local natureEffect = trimText(natureDetails.effectText)
		local natureImpact = trimText(natureDetails.impactText)
		local expTooltip = trimText(instanceData.expText or dexInfo.expText)

		if not hasInstance then
			natureName = "-"
			natureEffect = "Nature neutra"
			natureImpact = "Sem impacto"
		end

		hideLegacyStatsWidgets()
		textButton:setText("Dados do seu Pokémon")
		pokedexWindow.panelDesc:setVisible(false)
		textBox:setVisible(false)
		pokedexWindow.searchBar2:setVisible(false)
		statsPanel:setVisible(true)
		statsTextBox:setVisible(true)
		pokedexWindow.statsBar:setVisible(true)
		statsTextBox:setFont("terminus-10px")
		if statsPanel.getWidth then
			local availableWidth = math.max(210, statsPanel:getWidth() - 26)
			statsTextBox:setWidth(availableWidth)
		end

		local lines = {
			"Resumo do seu Pokémon",
			formatStatsLine("Nível", instanceData.level or dexInfo.pokemonLevel or dexInfo.level or "-"),
			formatStatsLine("BL", instanceData.blText or dexInfo.blText or dexInfo.bl or "-"),
			formatStatsLine("EXP atual", buildExpDisplay()),
			formatStatsLine("EXP total", buildExpTotalDisplay()),
			"",
			"Vitalidade",
			formatStatsLine("Vida", string.format("%s/%s", tostring(vitality.current ~= nil and vitality.current or "-"), tostring(vitality.max ~= nil and vitality.max or "-"))),
			"",
			"Natureza",
			formatStatsLine("Natureza", natureName ~= "" and natureName or "-"),
			formatStatsLine("Efeito", natureEffect ~= "" and natureEffect or "Nature neutra"),
			formatStatsLine("Impacto", natureImpact ~= "" and natureImpact or "Sem impacto"),
			"",
			"Comparação de Status",
			string.format("%-17s %s", "Status Atuais", "Status Base"),
			formatComparisonLine("Status HP", getStatDisplay(currentStats, "hp", not hasInstance), "HP Base", tostring(getStatValue(baseStats, "hp"))),
		}

		for _, statName in ipairs(statOrder) do
			if statName ~= "hp" then
				lines[#lines + 1] = formatComparisonLine(
					statLabels[statName] or statName:upper(),
					getStatDisplay(currentStats, statName, not hasInstance),
					(statLabels[statName] or statName:upper()) .. " Base",
					tostring(getStatValue(baseStats, statName))
				)
			end
		end

		lines[#lines + 1] = ""
		lines[#lines + 1] = "IVs"
		for _, statName in ipairs(statOrder) do
			local rowValue = select(1, getIvRowValue(statName))
			lines[#lines + 1] = formatStatsLine(statLabels[statName] or statName:upper(), rowValue)
		end

		local finalText = table.concat(lines, "\n")
		statsTextBox:setText(finalText)
		statsTextBox:setTooltip("")
		statsTextBox:setHeight(math.max(statsPanel:getHeight() + 140, (#lines * 15) + 36))
		statsPanel:updateLayout()
		pokedexWindow.statsBar:setValue(0)
	end

	function hideEstatisticas()
		statsPanel:setVisible(false)
		statsTextBox:clearText()
		statsTextBox:setVisible(false)
		pokedexWindow.statsBar:setVisible(false)
	end

	function showDescription()
		hideLegacyStatsWidgets()
		statsPanel:setVisible(false)
		statsTextBox:setVisible(false)
		pokedexWindow.statsBar:setVisible(false)
		textButton:setText("Descrição da espécie")
		pokedexWindow.panelDesc:setVisible(true)
		textBox:setVisible(true)
		pokedexWindow.searchBar2:setVisible(true)
		textBox:setFont("damas")
		local text = buildSpeciesDescription()

		if text == "" then
			text = "Nenhuma informacao de especie disponivel."
		end

		textBox:setText(text)
		textBox:setTooltip("")
	end

	function hideDescription()
		pokedexWindow.panelDesc:setVisible(false)
		textBox:clearText()
		textBox:setVisible(false)
		pokedexWindow.searchBar2:setVisible(false)
	end

	-- Paineis de efetividade

	local painelEfetivo   = pokedexWindow.panelAbilities2.panelEfetivo
	local painelNormal    = pokedexWindow.panelAbilities2.panelNormal
	local painelInefetivo = pokedexWindow.panelAbilities2.panelInefetivo
	local painelImune     = pokedexWindow.panelAbilities2.panelImune

	function showEfetividade()
		textButton:setText("Efetividades")

		painelEfetivo:setVisible(true)
		painelNormal:setVisible(true)
		painelImune:setVisible(true)
		painelInefetivo:setVisible(true)

		pokedexWindow.panelAbilities2.muitoinefetivocontra:setVisible(true)
		pokedexWindow.panelAbilities2.normalcontra:setVisible(true)
		pokedexWindow.panelAbilities2.efetivocontra:setVisible(true)
		pokedexWindow.panelAbilities2.inefetivocontra:setVisible(true)
		pokedexWindow.abilitiesBar2:setVisible(true)

		pokedexWindow.panelAbilities2:setVisible(true)
		-- pokedexWindow.abilitiesBar2:setVisible(true)

		-- painel efetivo

		painelEfetivo:destroyChildren()
		if typePokemon ~= "none" then
			for i, efetividade in pairs(typeEffectiveness[typePokemon].superEffectiveAgainst) do
				local widget = g_ui.createWidget("efetividadeButtons", painelEfetivo)
				widget:setId(efetividade)
				widget:setImageSource("images/types/" .. efetividade)
				widget:setTooltip(capitalizeFirstLetter(efetividade))
			end
		end

		if typePokemon2 ~= "none" then
			for i, efetividade in pairs(typeEffectiveness[typePokemon2].superEffectiveAgainst) do
				if not painelEfetivo:getChildren(efetividade) then
					local widget = g_ui.createWidget("efetividadeButtons", painelEfetivo)
					widget:setId(efetividade)
					widget:setImageSource("images/types/" .. efetividade)
					widget:setTooltip(capitalizeFirstLetter(efetividade))
				end
			end
		end

		if #painelEfetivo:getChildren() < 13 then
			painelEfetivo:setSize("300 25")
		end

		-- painel normal

		painelNormal:destroyChildren()
		if typePokemon ~= "none" then
			for i, efetividade in pairs(typeEffectiveness[typePokemon].normalAgainst) do
				local widget = g_ui.createWidget("efetividadeButtons", painelNormal)
				widget:setId(efetividade)
				widget:setImageSource("images/types/" .. efetividade)
				widget:setTooltip(capitalizeFirstLetter(efetividade))
			end
		end

		if typePokemon2 ~= "none" then
			for i, efetividade in pairs(typeEffectiveness[typePokemon2].normalAgainst) do
				if not painelNormal:getChildren(efetividade) then
					local widget = g_ui.createWidget("efetividadeButtons", painelNormal)
					widget:setId(efetividade)
					widget:setImageSource("images/types/" .. efetividade)
					widget:setTooltip(capitalizeFirstLetter(efetividade))
				end
			end
		end

		if #painelNormal:getChildren() < 13 then
			painelNormal:setSize("300 25")
		end

		-- painel inefetivo
		painelInefetivo:destroyChildren()
		if typePokemon ~= "none" then
			for i, efetividade in pairs(typeEffectiveness[typePokemon].notVeryEffectiveAgainst) do
				local widget = g_ui.createWidget("efetividadeButtons", painelInefetivo)
				widget:setId(efetividade)
				widget:setImageSource("images/types/" .. efetividade)
				widget:setTooltip(capitalizeFirstLetter(efetividade))
			end
		end

		if typePokemon2 ~= "none" then
			for i, efetividade in pairs(typeEffectiveness[typePokemon2].notVeryEffectiveAgainst) do
				if not painelInefetivo:getChildren(efetividade) then
					local widget = g_ui.createWidget("efetividadeButtons", painelInefetivo)
					widget:setId(efetividade)
					widget:setImageSource("images/types/" .. efetividade)
					widget:setTooltip(capitalizeFirstLetter(efetividade))
				end
			end
		end

		if #painelInefetivo:getChildren() < 13 then
			painelInefetivo:setSize("300 25")
		end
		-- painel imune

		painelImune:destroyChildren()
		if typePokemon ~= "none" then
			for i, efetividade in pairs(typeEffectiveness[typePokemon].noEffectAgainst) do
				local widget = g_ui.createWidget("efetividadeButtons", painelImune)
				widget:setId(efetividade)
				widget:setImageSource("images/types/" .. efetividade)
				widget:setTooltip(capitalizeFirstLetter(efetividade))
			end
		end

		if typePokemon2 ~= "none" then
			for i, efetividade in pairs(typeEffectiveness[typePokemon2].noEffectAgainst) do
				if not painelImune:getChildren(efetividade) then
					local widget = g_ui.createWidget("efetividadeButtons", painelImune)
					widget:setId(efetividade)
					widget:setImageSource("images/types/" .. efetividade)
					widget:setTooltip(capitalizeFirstLetter(efetividade))
				end
			end
		end

		if #painelImune:getChildren() < 13 then
			painelImune:setSize("300 25")
		end

		if #painelImune:getChildren() == 0 then
			painelImune:setVisible(false)
			pokedexWindow.panelAbilities2.muitoinefetivocontra:setVisible(false)
		end

		if #painelNormal:getChildren() == 0 then
			painelNormal:setVisible(false)
			pokedexWindow.panelAbilities2.normalcontra:setVisible(false)
		end

		if #painelEfetivo:getChildren() == 0 then
			painelEfetivo:setVisible(false)
			pokedexWindow.panelAbilities2.efetivocontra:setVisible(false)
		end

		if #painelInefetivo:getChildren() == 0 then
			painelInefetivo:setVisible(false)
			pokedexWindow.panelAbilities2.inefetivocontra:setVisible(false)
		end
	end

	function hideEfetividade()
		pokedexWindow.panelAbilities2:setVisible(false)
		pokedexWindow.abilitiesBar2:setVisible(false)
		painelNormal:destroyChildren()
		painelEfetivo:destroyChildren()
		painelImune:destroyChildren()
		painelInefetivo:destroyChildren()
	end

	painelMoves = pokedexWindow.panelMoves

	function showMoves()
		painelMoves:destroyChildren()
		painelMoves:setVisible(true)
		textButton:setText("Pokemon Moves")

		for i, move in pairs(dexInfo.moves) do
			if i > 12 then break end
			local widget = g_ui.createWidget("movesButton", painelMoves)
			widget:setId(move.name)
			local path = "images/moves_icon/" .. (move.name) .. "_on.png"
			if g_resources.fileExists(path) then
				widget:setImageSource(path)
			else
				widget:setImageSource("images/moves_icon/Base")
			end
			local text = ""
			local moveName = capitalizeFirstLetter(move.name)
			text = text .. "Nome: " .. moveName .. "\n"
			text = text .. "Level: " .. move.level .. "\n"
			text = text .. "Cooldown: " .. move.cooldown .. " segundos\n"
			text = text .. (move.isTarget and "Target: Sim" or "Ranged: Sim")

			widget:setTooltip(text)
		end
	end

	function hideMoves()
		painelMoves:destroyChildren()
		painelMoves:setVisible(false)
	end

	local painelLoot = pokedexWindow.panelLoot

	function showLoot()
		painelLoot:setVisible(true)
		pokedexWindow.lootBar:setVisible(true)
		textButton:setText("Pokemon Drops")
		painelLoot:destroyChildren()

		for i, loot in pairs(dexInfo.loot) do
			local widget = g_ui.createWidget("lootButtons", painelLoot)
			widget.item:setItemId(loot.clientId)
			widget.name:setText(loot.name)
			widget.quantity:setText("1 - " .. loot.maxCount)
			widget.chance:setText(loot.chance .. " %")
		end
	end

	function hideLoot()
		painelLoot:destroyChildren()
		painelLoot:setVisible(false)
		pokedexWindow.lootBar:setVisible(false)
	end

	hideLoot()
	hideMoves()
	hideEstatisticas()
	hideEfetividade()
	showDescription()


	description.onClick = function()
		hideEstatisticas()
		hideMoves()
		hideLoot()
		hideEfetividade()

		showDescription()
	end

	efetividade.onClick = function()
		hideDescription()
		hideEstatisticas()
		hideMoves()
		hideLoot()

		showEfetividade()
	end

	estatisticas.onClick = function()
		hideDescription()
		hideMoves()
		hideLoot()
		hideEfetividade()

		showEstatisticas()
	end

	moves.onClick = function()
		hideDescription()
		hideEstatisticas()
		hideLoot()
		hideEfetividade()

		showMoves()
	end

	loot.onClick = function()
		hideDescription()
		hideEstatisticas()
		hideMoves()
		hideEfetividade()

		showLoot()
	end

	local panelSearchPokemons = pokedexWindow.panelSearch

	if not generated then
		panelSearchPokemons:destroyChildren()
		for i, pokemon in ipairs(pokemons) do
			generated = true
			local widget = g_ui.createWidget("panelSearchBase", panelSearchPokemons)
			local newid = capitalizeFirstLetter(pokemon.name)
			widget:setId(newid)
			widget.nome:setText(pokemon.name)
			widget.nome:setColor("green")
			widget.numero:setText("#" .. i)
			widget.pokemonImageSearch:setOutfit(pokemon.outfit)
			widget.pokemonImageSearch:setOldScaling(true)
			widget.pokemonImageSearch:setAnimate(false)
			widget.onClick = function()
				sendPokeBuffer(newid)
			end

			if pokemon.type and pokemon.type ~= "none" then
				widget.type:setImageSource("images/types/" .. pokemon.type)
			end

			if pokemon.type2 and pokemon.type2 ~= "none" then
				widget.type2:setImageSource("images/types/" .. pokemon.type2)
			end

			if not pokemon.found then
				pokemon.outfit.shader = "outfit_black"
				widget.pokemonImageSearch:setOutfit(pokemon.outfit)
				widget.nome:setColor("red")
			end
		end
	end

	pokedexWindow.search.onTextChange = function(widget, newText)
		newText = newText:lower()
		for i, child in ipairs(panelSearchPokemons:getChildren()) do
			local text = child:getId():lower()
			if child:getId() ~= "search" then
				child:setVisible(text:find(newText))
			end
		end
	end

	showDex()
end

function showDex()
	pokedexWindow:show()
end

function hideDex()
	pokedexWindow:hide()
end

function init()
	pokedexWindow  = g_ui.loadUI('game_dex', modules.game_interface.getRootPanel())
	pokedexWindow2 = pokedexWindow:getChildById('mainDex')

	ProtocolGame.registerExtendedJSONOpcode(OPCODE, getOpCode)
	connect(g_game, {
		onGameEnd = function()
			pokedexWindow:hide()
		end,
		onGameStart = sendRequest
	})

	pokedexWindow:hide()
end

function sendRequest()
	local buffer = {
		type = "request"
	}
	g_game.getProtocolGame():sendExtendedOpcode(OPCODE, json.encode(buffer))
end

function toggle()
	if pokedexWindow:isVisible() then
		hideDex()
	else
		showDex()
	end
end

function terminate()
	ProtocolGame.unregisterExtendedJSONOpcode(OPCODE)
	pokedexWindow:destroy()
	pokedexWindow:hide()
	disconnect(g_game, {
		onGameEnd = function()
			pokedexWindow:hide()
		end
	})
end

function hide()
	pokedexWindow:hide()
end

function dump(tbl, indent)
	indent = indent or 0

	for k, v in pairs(tbl) do
		local formattedKey = tostring(k)
		local formattedValue = tostring(v)

		if type(v) == "table" then
			print(string.rep("  ", indent) .. formattedKey .. " =>")
			dump(v, indent + 1)
		else
			print(string.rep("  ", indent) .. formattedKey .. " => " .. formattedValue)
		end
	end
end

textTypes = {
    water = 
    "Os Pokï¿½mon do tipo ï¿½gua sï¿½o frequentemente encontrados em ambientes aquï¿½ticos.\n Eles tï¿½m uma afinidade natural com a ï¿½gua e geralmente sï¿½o bons nadadores. Alguns exemplos incluem Squirtle e Vaporeon.",
    fire = 
    "Os Pokï¿½mon do tipo Fogo sï¿½o conhecidos por sua chama interior.\n Eles sï¿½o criaturas ardentes e muitas vezes vivem em ï¿½reas vulcï¿½nicas. Charizard e Arcanine sï¿½o exemplos notï¿½veis desse tipo.",
    grass = 
    "Os Pokï¿½mon do tipo Grama sï¿½o encontrados em ï¿½reas verdes e sï¿½o geralmente associados ï¿½ natureza.\n Eles tï¿½m habilidades botï¿½nicas, como o Bulbasaur, que possui uma planta em suas costas.",
    electric = 
    "Pokï¿½mon do tipo Elï¿½trico tï¿½m a capacidade de gerar eletricidade.\n Eles sï¿½o conhecidos por seus ataques elï¿½tricos, como Pikachu e Jolteon.",
    flying = 
    "Os Pokï¿½mon do tipo Voador tï¿½m a habilidade de voar.\n Muitos deles tï¿½m asas e podem se mover rapidamente pelo cï¿½u, como Pidgeot e Swellow.",
    psychic = 
    "Os Pokï¿½mon do tipo Psï¿½quico possuem poderes mentais e sï¿½o capazes de ler pensamentos e prever o futuro.\n Mewtwo e Alakazam sï¿½o exemplos de Pokï¿½mon Psï¿½quicos poderosos.",
    poison = 
    "Pokï¿½mon do tipo Venenoso tï¿½m veneno em seus corpos.\n Eles sï¿½o conhecidos por seus ataques tï¿½xicos e incluem criaturas como Arbok e Muk.",
    rock = 
    "Os Pokï¿½mon do tipo Pedra sï¿½o geralmente robustos e resistentes.\n Eles podem ser encontrados em cavernas e montanhas. Onix e Geodude sï¿½o exemplos desse tipo.",
    ice = 
    "Os Pokï¿½mon do tipo Gelo tï¿½m afinidade com o frio e sï¿½o frequentemente encontrados em regiï¿½es geladas.\n Lapras e Articuno sï¿½o exemplos notï¿½veis.",
    fighting = 
    "Pokï¿½mon do tipo Lutador sï¿½o conhecidos por suas habilidades em combate corpo a corpo.\n Eles sï¿½o fortes e ï¿½geis, como Machamp e Hitmonlee.",
    bug = 
    "Os Pokï¿½mon do tipo Inseto sï¿½o frequentemente pequenos e ï¿½geis, e muitas vezes tï¿½m aparï¿½ncia de insetos reais.\n Scyther e Pinsir sï¿½o exemplos desse tipo.",
    ghost = 
    "Pokï¿½mon do tipo Fantasma sï¿½o misteriosos e muitas vezes associados a eventos sobrenaturais.\n Gengar e Haunter sï¿½o exemplos de Pokï¿½mon Fantasmas.",
    dragon = 
    "Os Pokï¿½mon do tipo Dragï¿½o sï¿½o poderosos e lendï¿½rios.\n Eles tï¿½m habilidades impressionantes e sï¿½o raros. Dragonite e Salamence sï¿½o alguns exemplos.",
    steel = 
    "Os Pokï¿½mon do tipo Aï¿½o sï¿½o conhecidos por sua resistï¿½ncia e durabilidade.\n Eles sï¿½o frequentemente feitos de metal ou tï¿½m uma cobertura de aï¿½o. Exemplos incluem Steelix e Aggron.",
    dark = 
    "Os Pokï¿½mon do tipo Noturno sï¿½o ativos principalmente durante a noite e tï¿½m habilidades relacionadas ï¿½ escuridï¿½o.\n Umbreon e Honchkrow sï¿½o exemplos desse tipo.",
    fairy = 
    "Os Pokï¿½mon do tipo Fada sï¿½o criaturas mï¿½gicas e encantadoras.\n Eles sï¿½o conhecidos por sua resistï¿½ncia a tipos como Dragï¿½o e Lutador. Clefable e Gardevoir sï¿½o exemplos notï¿½veis.",
    normal = 
    "O tipo Normal ï¿½ versï¿½til e comum, nï¿½o tem fraquezas naturais e ï¿½ resistente a ataques do tipo Fantasma.\n Eles sï¿½o conhecidos por sua adaptabilidade e aprendem uma variedade de movimentos. Alguns exemplos incluem Snorlax, Eevee e Porygon.",
    ground = 
    "O tipo Ground (Terra) ï¿½ associado a Pokï¿½mon que vivem na terra firme e em ambientes terrestres.\n Eles sï¿½o imunes a ataques elï¿½tricos, tï¿½m movimentos poderosos como Terremoto e sï¿½o conhecidos por sua resistï¿½ncia. Exemplos incluem Onix e Groudon.",
}

habilidadesDescription = {
    blink = "Teletransporta instantaneamente curtas distï¿½ncias.",
    teleport = "Teletransporta para um local especï¿½fico, mesmo distante.",
    dig = "Cava o solo para abrir caminho.",
    smash = "Pode destruir obstï¿½culos que estï¿½o obstruindo o caminho",
    cut = "Corta objetos ou vegetaï¿½ï¿½o.",
    light = "Gera luz para iluminar ï¿½reas escuras.",
    levitate = "Permite flutuar acima do chï¿½o.",
    controlmind = "Controla a mente de outros seres.",
    fly = "Permite voar pelos cï¿½us.",
    ride = "Monta criaturas para se deslocar mais rapidamente.",
    surf = "Navega na ï¿½gua para atravessar corpos d'ï¿½gua.",
    -- headbutt = "Derruba pokemons de ï¿½rvores.",
}


typeEffectiveness      = {
	none = {
		superEffectiveAgainst = {},
		notVeryEffectiveAgainst = {},
		noEffectAgainst = {},
		normalAgainst = {}
	},
	physical = {
		superEffectiveAgainst = {},
		notVeryEffectiveAgainst = {},
		noEffectAgainst = {},
		normalAgainst = {}
	},
	unknown = {
		superEffectiveAgainst = {},
		notVeryEffectiveAgainst = {},
		noEffectAgainst = {},
		normalAgainst = {}
	},
	normal = {
		superEffectiveAgainst = {},
		notVeryEffectiveAgainst = { "rock", "steel" },
		noEffectAgainst = { "ghost" },
		normalAgainst = { "normal", "fire", "water", "electric", "grass", "ice", "fighting", "poison", "ground", "flying", "psychic", "bug", "dragon", "dark", "fairy" }
	},
	fire = {
		superEffectiveAgainst = { "grass", "ice", "bug", "steel" },
		notVeryEffectiveAgainst = { "fire", "water", "rock", "dragon" },
		noEffectAgainst = {},
		normalAgainst = { "normal", "electric", "fighting", "poison", "ground", "flying", "psychic", "ghost", "dark", "fairy" }
	},
	water = {
		superEffectiveAgainst = { "fire", "ground", "rock" },
		notVeryEffectiveAgainst = { "water", "grass", "dragon" },
		noEffectAgainst = {},
		normalAgainst = { "normal", "electric", "ice", "fighting", "poison", "flying", "psychic", "bug", "ghost", "dark", "steel", "fairy" }
	},
	electric = {
		superEffectiveAgainst = { "water", "flying" },
		notVeryEffectiveAgainst = { "electric", "grass", "dragon" },
		noEffectAgainst = { "ground" },
		normalAgainst = { "normal", "fire", "ice", "fighting", "poison", "psychic", "bug", "rock", "ghost", "dark", "steel", "fairy" }
	},
	grass = {
		superEffectiveAgainst = { "water", "ground", "rock" },
		notVeryEffectiveAgainst = { "fire", "grass", "poison", "flying", "bug", "dragon", "steel" },
		noEffectAgainst = {},
		normalAgainst = { "normal", "electric", "ice", "fighting", "psychic", "ghost", "dark", "fairy" }
	},
	ice = {
		superEffectiveAgainst = { "grass", "ground", "flying", "dragon" },
		notVeryEffectiveAgainst = { "fire", "water", "ice", "steel" },
		noEffectAgainst = {},
		normalAgainst = { "normal", "electric", "fighting", "poison", "psychic", "bug", "rock", "ghost", "dark", "fairy" }
	},
	fighting = {
		superEffectiveAgainst = { "normal", "ice", "rock", "dark", "steel" },
		notVeryEffectiveAgainst = { "poison", "flying", "psychic", "bug", "fairy" },
		noEffectAgainst = { "ghost" },
		normalAgainst = { "fire", "water", "electric", "grass", "fighting", "ground", "dragon" }
	},
	poison = {
		superEffectiveAgainst = { "grass", "fairy" },
		notVeryEffectiveAgainst = { "poison", "ground", "rock", "ghost" },
		noEffectAgainst = {},
		normalAgainst = { "normal", "fire", "water", "electric", "ice", "fighting", "flying", "psychic", "bug", "dragon", "dark", "steel" }
	},
	ground = {
		superEffectiveAgainst = { "fire", "electric", "poison", "rock", "steel" },
		notVeryEffectiveAgainst = { "grass", "bug" },
		noEffectAgainst = { "flying" },
		normalAgainst = { "normal", "water", "ice", "fighting", "ground", "psychic", "ghost", "dragon", "dark", "fairy" }
	},
	flying = {
		superEffectiveAgainst = { "grass", "fighting", "bug" },
		notVeryEffectiveAgainst = { "electric", "rock", "steel" },
		noEffectAgainst = {},
		normalAgainst = { "normal", "fire", "water", "ice", "poison", "ground", "flying", "psychic", "ghost", "dragon", "dark", "fairy" }
	},
	psychic = {
		superEffectiveAgainst = { "fighting", "poison" },
		notVeryEffectiveAgainst = { "psychic", "steel" },
		noEffectAgainst = { "dark" },
		normalAgainst = { "normal", "fire", "water", "electric", "grass", "ice", "ground", "flying", "bug", "rock", "ghost", "dragon", "fairy" }
	},
	bug = {
		superEffectiveAgainst = { "grass", "psychic", "dark" },
		notVeryEffectiveAgainst = { "fire", "fighting", "poison", "flying", "ghost", "steel", "fairy" },
		noEffectAgainst = {},
		normalAgainst = { "normal", "water", "electric", "ice", "ground", "bug", "rock", "dragon" }
	},
	rock = {
		superEffectiveAgainst = { "fire", "ice", "flying", "bug" },
		notVeryEffectiveAgainst = { "fighting", "ground", "steel" },
		noEffectAgainst = {},
		normalAgainst = { "normal", "water", "electric", "grass", "poison", "psychic", "rock", "ghost", "dragon", "dark", "fairy" }
	},
	ghost = {
		superEffectiveAgainst = { "psychic", "ghost" },
		notVeryEffectiveAgainst = { "dark" },
		noEffectAgainst = { "normal" },
		normalAgainst = { "fire", "water", "electric", "grass", "ice", "fighting", "poison", "ground", "flying", "bug", "rock", "dragon", "steel", "fairy" }
	},
	dragon = {
		superEffectiveAgainst = { "dragon" },
		notVeryEffectiveAgainst = { "steel" },
		noEffectAgainst = { "fairy" },
		normalAgainst = { "normal", "fire", "water", "electric", "grass", "ice", "fighting", "poison", "ground", "flying", "psychic", "bug", "rock", "ghost", "dark" }
	},
	dark = {
		superEffectiveAgainst = { "psychic", "ghost" },
		notVeryEffectiveAgainst = { "fighting", "dark", "fairy" },
		noEffectAgainst = {},
		normalAgainst = { "normal", "fire", "water", "electric", "grass", "ice", "poison", "ground", "flying", "bug", "rock", "dragon", "steel" }
	},
	steel = {
		superEffectiveAgainst = { "ice", "rock", "fairy" },
		notVeryEffectiveAgainst = { "fire", "water", "electric", "steel" },
		noEffectAgainst = {},
		normalAgainst = { "normal", "grass", "fighting", "poison", "ground", "flying", "psychic", "bug", "ghost", "dragon", "dark" }
	},
	fairy = {
		superEffectiveAgainst = { "fighting", "dragon", "dark" },
		notVeryEffectiveAgainst = { "fire", "poison", "steel" },
		noEffectAgainst = {},
		normalAgainst = { "normal", "water", "electric", "grass", "ice", "ground", "flying", "psychic", "bug", "rock", "ghost", "fairy" }
	}
}
