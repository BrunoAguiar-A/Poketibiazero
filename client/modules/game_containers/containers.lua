local gameStart = 0

-- Manter estas listas alinhadas com o servidor:
-- balls em data/lib/core/newfunctions.lua, loot em data/monster e consumiveis nos actions scripts.
ITEM_CATEGORIES = {
	pokemon = {},
	pokeballs = {
		10975, 10977, 12617, 13228, 13229, 13231, 16704, 16706, 16707, 16709,
		16710, 16712, 16713, 16715, 16716, 16718, 16719, 16721, 16722, 16724,
		16725, 16727, 16728, 16730, 16731, 16733, 16734, 16736, 16740, 16742,
		22919, 22921, 22922, 22927, 22928, 22929, 22930, 22931, 22932, 22942,
		22943, 22944, 22945, 22946, 22947, 22948, 22949, 22950, 22951, 22952,
		22953, 23455, 23456, 24406, 24407, 26659, 26660, 26662, 26663, 26666,
		26670, 26672, 26674, 26675, 26677, 26678, 26681, 26683, 26686, 26688,
		32509, 32510, 32511, 32512, 32513, 32514, 32515, 32516, 32517, 32518,
		32520, 32535
	},
	emptyPokeballs = {
		12617, 13228, 22919, 22927, 22928, 22929, 22930, 22931, 22932, 24407,
		26659, 26660, 26662, 26683, 26688, 32509, 32510, 32511, 32512, 32513,
		32514, 32515, 32516, 32517, 32518, 32520, 32535
	},
	loot = {
		1294, 2111, 26724, 26725, 26726, 26727, 26728, 26729, 26730, 26731,
		26732, 26733, 26734, 26735, 26736, 26742, 26743, 26747, 27651, 27656,
		27660, 27668, 27669, 27670, 27671, 27672, 27678, 27679, 27681, 27684,
		27685, 27687, 27700, 27702, 27710, 27719, 27784, 28569, 41605, 41607,
		41608, 41611, 41612, 41613, 43521
	},
	food = {
		2362, 2666, 2667, 2668, 2669, 2670, 2671, 2672, 2673, 2674,
		2675, 2676, 2677, 2678, 2679, 2680, 2681, 2682, 2683, 2684,
		2685, 2686, 2687, 2688, 2689, 2690, 2691, 2695, 2696, 2787,
		2788, 2789, 2790, 2791, 2792, 2793, 2794, 2795, 2796, 5097,
		6125, 6278, 6279, 6393, 6394, 6501, 6541, 6542, 6543, 6544,
		6545, 6569, 6574, 7158, 7159, 7372, 7373, 7374, 7375, 7376,
		7377, 7909, 7910, 7963, 8112, 8838, 8839, 8840, 8841, 8842,
		8843, 8844, 8845, 8847, 9005, 9114, 9996, 10454, 11246, 11370,
		11429, 12415, 12416, 12417, 12418, 12637, 12638, 12639, 13297, 15405,
		15487, 15488, 16014, 18397, 19737, 20100, 20101
	},
	medicine = {27641, 27642, 27643, 27644, 27645, 27646, 27647, 40926},
	others = {}
}

local ITEM_CATEGORY_NAMES = {
	loot = {
		"band aid", "bandaid", "bitten apple", "bottle of poison", "bug gosme",
		"cocoon stone", "comb", "crystal stone", "dark gem", "darkness stone",
		"dragon scale", "earth ball", "earth stone", "electric box", "enchanted gem",
		"enigma stone", "essence of fire", "feather stone", "fire stone", "future orb",
		"ghost essence", "heart stone", "ice orb", "ice stone", "leaf stone",
		"leaves", "metal stone", "piece of steel", "pot of lava", "pot of moss bug",
		"punch stone", "rock stone", "rubber ball", "sandbag", "screw",
		"seed", "small stone", "snow ball", "snowball", "stone orb",
		"straw", "thunder stone", "traces of ghost", "venom stone", "water gem",
		"water pendant", "water stone"
	}
}

local FILTER_ALIASES = {
	all = "all",
	pokemon = "pokemon",
	pokemons = "pokemon",
	pokeball = "pokeballs",
	pokeballs = "pokeballs",
	loot = "loot",
	food = "food",
	foods = "food",
	medicine = "medicine",
	medicines = "medicine",
	others = "others"
}

FILTER_BUTTONS = {
	{ id = "filterAll", name = "All", image = "/images/ui/miniwindowbtn/filter_icon/all", action = "all" },
	{ id = "filterPokemon", name = "Pokemon", image = "/images/ui/miniwindowbtn/filter_icon/pokemon", action = "pokemon" },
	{ id = "filterPokeballs", name = "Pokeballs", image = "/images/ui/miniwindowbtn/filter_icon/pokeballs", action = "pokeballs" },
	{ id = "filterLoot", name = "Loot", image = "/images/ui/miniwindowbtn/filter_icon/loot", action = "loot" },
	{ id = "filterFoods", name = "Foods", image = "/images/ui/miniwindowbtn/filter_icon/food", action = "food" },
	{ id = "filterMedicines", name = "Medicines", image = "/images/ui/miniwindowbtn/filter_icon/medicine", action = "medicine" },
	{ id = "filterOthers", name = "Others", image = "/images/ui/miniwindowbtn/filter_icon/others", action = "others" },
}

local POKEMON_NAME_ATTRIBUTE_KEYS = {"pokeName", "poke", "pokemon", "monster", "monsterName", "creature"}
local POKEMON_INSIDE_ATTRIBUTE_KEYS = {"pokeName", "poke", "pokemon", "monster", "monsterName", "creature", "hp", "pokeHP", "pokeHealth", "pokeMaxHealth", "pokeLevel"}
local CATEGORY_LOOKUP = {}
local CATEGORY_NAME_LOOKUP = {}

local pokemonIconCache = {}
local pokeballInfoCache = {}

local function normalizeNameKey(value)
	return tostring(value or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
end

local function buildLookup(values, normalize)
	local lookup = {}
	for _, value in ipairs(values or {}) do
		lookup[normalize and normalizeNameKey(value) or value] = true
	end
	return lookup
end

for category, values in pairs(ITEM_CATEGORIES) do
	CATEGORY_LOOKUP[category] = buildLookup(values)
end

for category, values in pairs(ITEM_CATEGORY_NAMES) do
	CATEGORY_NAME_LOOKUP[category] = buildLookup(values, true)
end

local function applyPokemonTooltipInfo(itemWidget, item)
	if not itemWidget then
		return
	end

	if not item then
		itemWidget.pokemonTooltipInfo = nil
		itemWidget.pokeballsInfo = nil
		itemWidget.itemTooltipInfo = nil
		if itemWidget.removeAdvancedTooltip then
			itemWidget:removeAdvancedTooltip()
		end
		return
	end

	local itemInfo = item:getItemInfo()
	if itemInfo and itemInfo.pokeballInfo and itemInfo.pokeballInfo ~= "" then
		-- Ativar tooltip completo de Pokémon (com todas as infos)
		itemWidget.pokemonTooltipInfo = true
		if itemWidget.setAdvancedTooltip then
			itemWidget:setAdvancedTooltip(true)
		end
	else
		itemWidget.pokemonTooltipInfo = nil
		itemWidget.pokeballsInfo = nil
		itemWidget.itemTooltipInfo = nil
	end
	if itemWidget.removeAdvancedTooltip then
		itemWidget:removeAdvancedTooltip()
	end
end

local function normalizeFilterType(filterType)
	return FILTER_ALIASES[tostring(filterType or "all"):lower()] or "all"
end

local function categoryContains(category, value)
	return value ~= nil and CATEGORY_LOOKUP[category] and CATEGORY_LOOKUP[category][value] == true
end

local function categoryNameContains(category, value)
	return value ~= nil
		and CATEGORY_NAME_LOOKUP[category]
		and CATEGORY_NAME_LOOKUP[category][normalizeNameKey(value)] == true
end

local function getItemInfo(item)
	if not item or not item.getItemInfo then
		return nil
	end
	return item:getItemInfo()
end

local function getItemId(item)
	if not item then
		return nil
	end

	if item.getId then
		local id = item:getId()
		if id and id > 0 then
			return id
		end
	end

	local itemInfo = getItemInfo(item)
	return itemInfo and itemInfo.ItemID or nil
end

local function readJsonName(rawName)
	if not rawName or rawName == "" then
		return ""
	end

	local status, decoded = pcall(function() return json.decode(rawName) end)
	if status and type(decoded) == "table" then
		return decoded.tag or decoded.name or decoded.itemName or rawName
	end
	return rawName
end

local function getItemName(item)
	local itemInfo = getItemInfo(item)
	if not itemInfo then
		return ""
	end

	if itemInfo.pokeballInfo and itemInfo.pokeballInfo ~= "" then
		local ok, pokeName = pcall(function()
			return getBallSpecialAttribute("pokeName", itemInfo.pokeballInfo)
		end)
		if ok and pokeName and pokeName ~= "" then
			return pokeName
		end
	end

	return readJsonName(itemInfo.name or itemInfo.Name or "")
end

local function trimText(text)
	return tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function hasAttributeValue(value)
	if value == nil or value == false then
		return false
	end

	if type(value) == "number" then
		return value > 0
	end

	if type(value) == "string" then
		local text = value:lower()
		return trimText(text) ~= "" and text ~= "0" and text ~= "false" and text ~= "none" and text ~= "nil"
	end

	return true
end

local function getPokeballInfoAttribute(item, attribute)
	local itemInfo = getItemInfo(item)
	if not itemInfo or not itemInfo.pokeballInfo or itemInfo.pokeballInfo == "" then
		return nil
	end

	local rawInfo = itemInfo.pokeballInfo
	if pokeballInfoCache[rawInfo] == nil then
		local ok, data = pcall(function()
			return stringToTable(rawInfo)
		end)
		pokeballInfoCache[rawInfo] = ok and type(data) == "table" and data or false
	end

	local data = pokeballInfoCache[rawInfo]
	return data and data[attribute] or nil
end

local function hasAnyPokeballInfoAttribute(item, attributes)
	for _, attribute in ipairs(attributes) do
		if hasAttributeValue(getPokeballInfoAttribute(item, attribute)) then
			return true
		end
	end

	return false
end

local function sanitizePokemonAssetName(pokemonName)
	local name = trimText(pokemonName):lower()
	if name == "" then
		return nil
	end

	name = name:gsub("[%.']", "")
	name = name:gsub("[^%w%s%-]", "")
	name = trimText(name)
	return name ~= "" and name or nil
end

local function addPokemonAssetCandidate(candidates, seen, value)
	value = trimText(value)
	if value == "" or seen[value] then
		return
	end

	seen[value] = true
	table.insert(candidates, value)
end

local function getPokemonAssetCandidates(pokemonName)
	local rawName = trimText(pokemonName)
	local lowerName = rawName:lower()
	local isShinyPokemon = lowerName:find("^shiny%s+") ~= nil
	local baseName = isShinyPokemon and trimText(rawName:gsub("^[Ss][Hh][Ii][Nn][Yy]%s+", "")) or rawName
	local lowerBaseName = baseName:lower()
	local cleanBaseName = sanitizePokemonAssetName(baseName) or lowerBaseName
	local candidates = {}
	local seen = {}

	addPokemonAssetCandidate(candidates, seen, baseName)
	addPokemonAssetCandidate(candidates, seen, lowerBaseName)
	addPokemonAssetCandidate(candidates, seen, cleanBaseName)
	addPokemonAssetCandidate(candidates, seen, cleanBaseName:gsub("%s+", "-"))
	addPokemonAssetCandidate(candidates, seen, cleanBaseName:gsub("[%s%-]+", ""))
	addPokemonAssetCandidate(candidates, seen, lowerBaseName:gsub("[%.']", ""))
	addPokemonAssetCandidate(candidates, seen, lowerBaseName:gsub("%s+", "-"))
	addPokemonAssetCandidate(candidates, seen, lowerBaseName:gsub("[%s%-]+", ""))

	local regionalForms = {
		alolan = "alola",
		galarian = "galar",
		hisuian = "hisui",
		paldean = "paldea"
	}
	for prefix, suffix in pairs(regionalForms) do
		local formBaseName = lowerBaseName:match("^" .. prefix .. "%s+(.+)$")
		if formBaseName then
			local cleanFormName = sanitizePokemonAssetName(formBaseName) or formBaseName
			addPokemonAssetCandidate(candidates, seen, cleanFormName .. "-" .. suffix)
			addPokemonAssetCandidate(candidates, seen, cleanFormName:gsub("%s+", "-") .. "-" .. suffix)
			addPokemonAssetCandidate(candidates, seen, cleanFormName:gsub("[%s%-]+", "") .. suffix)
		end
	end

	local megaBaseName = lowerBaseName:match("^mega%s+(.+)$")
	if megaBaseName then
		local cleanMegaName = sanitizePokemonAssetName(megaBaseName) or megaBaseName
		addPokemonAssetCandidate(candidates, seen, cleanMegaName .. "-mega")
		addPokemonAssetCandidate(candidates, seen, cleanMegaName:gsub("%s+", "-") .. "-mega")
		addPokemonAssetCandidate(candidates, seen, cleanMegaName:gsub("[%s%-]+", "") .. "mega")
	end

	local primalBaseName = lowerBaseName:match("^primal%s+(.+)$")
	if primalBaseName then
		local cleanPrimalName = sanitizePokemonAssetName(primalBaseName) or primalBaseName
		addPokemonAssetCandidate(candidates, seen, cleanPrimalName .. "-primal")
		addPokemonAssetCandidate(candidates, seen, cleanPrimalName:gsub("%s+", "-") .. "-primal")
		addPokemonAssetCandidate(candidates, seen, cleanPrimalName:gsub("[%s%-]+", "") .. "primal")
	end

	return candidates, isShinyPokemon, rawName
end

local function getExistingPokemonIconPath(pokemonName)
	local candidates, isShinyPokemon, rawName = getPokemonAssetCandidates(pokemonName)
	if not rawName or rawName == "" then
		return nil
	end

	local cacheKey = rawName:lower()
	if pokemonIconCache[cacheKey] ~= nil then
		return pokemonIconCache[cacheKey]
	end

	local primaryFolder = isShinyPokemon and "/pokemon/shiny/" or "/pokemon/regular/"
	for _, name in ipairs(candidates) do
		local path = primaryFolder .. name
		if g_resources.fileExists(path .. ".png") then
			pokemonIconCache[cacheKey] = path
			return path
		end
	end

	if isShinyPokemon then
		for _, name in ipairs(candidates) do
			local path = "/pokemon/regular/" .. name
			if g_resources.fileExists(path .. ".png") then
				pokemonIconCache[cacheKey] = path
				return path
			end
		end
	end

	local portraitPrefix = isShinyPokemon and "shiny " or ""
	for _, name in ipairs(candidates) do
		local path = "/images/game/portrait/" .. portraitPrefix .. name
		if g_resources.fileExists(path .. ".png") then
			pokemonIconCache[cacheKey] = path
			return path
		end
	end

	local spriteFolder = isShinyPokemon and "/pokemon/sprites/shiny/" or "/pokemon/sprites/regular/"
	for _, name in ipairs(candidates) do
		local path = spriteFolder .. name
		if g_resources.fileExists(path .. ".png") then
			pokemonIconCache[cacheKey] = path
			return path
		end
	end

	pokemonIconCache[cacheKey] = false
	return nil
end

local function getPokeballPokemonName(item)
	if not item then
		return nil
	end

	local itemInfo = getItemInfo(item)
	if itemInfo and itemInfo.pokeballInfo and itemInfo.pokeballInfo ~= "" then
		for _, attribute in ipairs(POKEMON_NAME_ATTRIBUTE_KEYS) do
			local pokeName = getPokeballInfoAttribute(item, attribute)
			if pokeName and trimText(pokeName) ~= "" then
				return trimText(pokeName)
			end
		end
	end

	local descriptionParts = {}
	if itemInfo and itemInfo.desc and itemInfo.desc ~= "" then
		table.insert(descriptionParts, itemInfo.desc)
	end
	if item.getDescription then
		local ok, description = pcall(function() return item:getDescription() end)
		if ok and description and description ~= "" then
			table.insert(descriptionParts, description)
		end
	end
	if item.getTooltip then
		local ok, tooltip = pcall(function() return item:getTooltip() end)
		if ok and tooltip and tooltip ~= "" then
			table.insert(descriptionParts, tooltip)
		end
	end

	for _, description in ipairs(descriptionParts) do
		local text = description:lower()
		local pokeName = text:match("contains a ([%w%s%-']+)")
			or text:match("contains an ([%w%s%-']+)")
			or text:match("contém um ([%w%s%-']+)")
			or text:match("contem um ([%w%s%-']+)")
		if pokeName then
			pokeName = trimText(pokeName:gsub("%s+inside.*$", ""):gsub("%s+with.*$", ""))
			if pokeName ~= "" then
				return pokeName
			end
		end
	end

	return nil
end

function hasPokemonInside(item)
	if not item then
		return false
	end

	return hasAnyPokeballInfoAttribute(item, POKEMON_NAME_ATTRIBUTE_KEYS)
		or hasAnyPokeballInfoAttribute(item, POKEMON_INSIDE_ATTRIBUTE_KEYS)
end

function isPokeball(item)
	if not item then
		return false
	end

	if categoryContains("pokeballs", getItemId(item)) then
		return true
	end

	local itemInfo = getItemInfo(item)
	if itemInfo and itemInfo.pokeballInfo and itemInfo.pokeballInfo ~= "" and hasPokemonInside(item) then
		return true
	end

	return false
end

function isEmptyPokeball(item)
	if not item then
		return false
	end

	return categoryContains("emptyPokeballs", getItemId(item)) and not hasPokemonInside(item)
end

function isFood(item)
	if not item or isPokeball(item) then
		return false
	end

	return categoryContains("food", getItemId(item))
end

function isMedicine(item)
	if not item or isPokeball(item) then
		return false
	end

	return categoryContains("medicine", getItemId(item))
end

function isShopItem(item)
	return false
end

function isLoot(item)
	if not item or isPokeball(item) or isShopItem(item) then
		return false
	end

	local itemId = getItemId(item)
	if categoryContains("loot", itemId) then
		return true
	end

	if isFood(item) or isMedicine(item) then
		return false
	end

	if categoryContains("others", itemId) then
		return false
	end

	return categoryNameContains("loot", getItemName(item))
end

local function clearPokeballPokemonIcon(itemWidget)
	if not itemWidget then
		return
	end

	local pokemonIcon = itemWidget:getChildById("pokeballPokemonIcon")
	if pokemonIcon then
		pokemonIcon:destroy()
	end

	local ballOverlay = itemWidget:getChildById("pokeballItemOverlay")
	if ballOverlay then
		ballOverlay:destroy()
	end

	local pokemonBase = itemWidget:getChildById("pokeballPokemonBase")
	if pokemonBase then
		pokemonBase:destroy()
	end

	if itemWidget.setItemVisible then
		itemWidget:setItemVisible(true)
	end

	itemWidget.pokeballPokemonIconPath = nil
end

local function applyPokeballPokemonIcon(itemWidget, item)
	if not itemWidget then
		return
	end

	-- O servidor agora controla o visual da pokebola pelo item id.
	-- Mantemos apenas o sprite real do item visivel e removemos overlays
	-- antigos que desenhavam o pokemon por cima da pokebola.
	clearPokeballPokemonIcon(itemWidget)
end

function getItemCategory(item)
	if not item then
		return "others"
	end

	if isPokeball(item) and hasPokemonInside(item) then
		return "pokemon"
	end

	if isEmptyPokeball(item) then
		return "pokeballs"
	end

	if categoryContains("pokemon", getItemId(item)) then
		return "pokemon"
	end

	if isMedicine(item) then
		return "medicine"
	end

	if isFood(item) then
		return "food"
	end

	if isLoot(item) then
		return "loot"
	end

	return "others"
end

function isOtherItem(item)
	return item ~= nil and getItemCategory(item) == "others"
end

function applyFilter(filterType, item)
	filterType = normalizeFilterType(filterType)

	if filterType == "all" then
		return item ~= nil
	end

	return getItemCategory(item) == filterType
end

local function updateFilterButtons(container)
	if not container or not container.window or not container.window.filterPanel then
		return
	end

	local activeFilter = normalizeFilterType(container.window.filter)
	local panel = container.window.filterPanel.buttonsPael
	if not panel then
		return
	end

	for _, button in ipairs(panel:getChildren()) do
		local selected = button.filterType == activeFilter
		button:setOn(selected)
		if selected then
			button:focus()
			button:setImageColor("#79b2ff")
		else
			button:setImageColor("#8d8e8e")
		end
	end
end

local function createContainerItemWidget(container, containerPanel, slot, item, itemIndex)
	local itemWidget = g_ui.createWidget('Item', containerPanel)
	itemWidget:setId('item' .. itemIndex)
	itemWidget:setItem(item)
	itemWidget:setMarginLeft(0)
	itemWidget.position = container:getSlotPosition(slot)
	itemWidget:setOpacity(item and 1 or 0.25)

	if not container:isUnlocked() then
		itemWidget:setBorderColor('red')
	end

	applyPokemonTooltipInfo(itemWidget, item)
	applyPokeballPokemonIcon(itemWidget, item)
	return itemWidget
end

local function updateContainerContentHeight(container, delay)
	local containerPanel = container.itemsPanel
	local containerWindow = container.window
	if not containerPanel or not containerWindow then
		return
	end

	local function update()
		if not containerWindow or not containerPanel or not containerWindow.setContentMinimumHeight then
			return
		end

		local layout = containerPanel:getLayout()
		local cellSize = layout:getCellSize()
		containerWindow:setContentMinimumHeight(cellSize.height)
		containerWindow:setContentMaximumHeight(cellSize.height * layout:getNumLines() + layout:getNumLines())
	end

	if delay and delay > 0 then
		scheduleEvent(update, delay)
	else
		update()
	end
end

function init()
  g_ui.importStyle('container')
  connect(Container, { onOpen = onContainerOpen,
                       onClose = onContainerClose,
                       onSizeChange = onContainerChangeSize,
                       onAddItem = onContainerAddItem,
                       onRemoveItem = onContainerRemoveItem,
                       onUpdateItem = onContainerUpdateItem })
  connect(g_game, {
    onGameStart = markStart,
    onGameEnd = clean
  })

  reloadContainers()
end

function terminate()
  disconnect(Container, { onOpen = onContainerOpen,
                          onClose = onContainerClose,
                          onSizeChange = onContainerChangeSize,
                          onAddItem = onContainerAddItem,
                          onRemoveItem = onContainerRemoveItem,
                          onUpdateItem = onContainerUpdateItem })
  disconnect(g_game, { 
    onGameStart = markStart,
    onGameEnd = clean
  })
end

function reloadContainers()
  clean()
  for _, container in pairs(g_game.getContainers()) do
    onContainerOpen(container)
  end
end

function clean()
  for containerid,container in pairs(g_game.getContainers()) do
    destroy(container)
  end
end

function markStart()
  gameStart = g_clock.millis()
end

function destroy(container)
  if container.window then
    container.window:destroy()
    container.window = nil
    container.itemsPanel = nil
    if doCheckDepotStatus(container) then
      modules.game_walking.enableWSAD()
    end
  end
end

function refreshContainerItemsALL(container)
  local containerPanel = container.itemsPanel
  local containerWindow = container.window
  if not containerPanel or not containerWindow then return end
  containerPanel:destroyChildren()
  for slot = 0, container:getCapacity()-1 do
    local item = container:getItem(slot)
    createContainerItemWidget(container, containerPanel, slot, item, slot)
  end

  updateFilterButtons(container)
  toggleContainerPages(containerWindow, container:hasPages())
  refreshContainerPages(container)
  updateContainerContentHeight(container)
end

function refreshContainerItems(container)
  local containerPanel = container.itemsPanel
  local containerWindow = container.window
  if not containerPanel or not containerWindow then return end

  local filterId = normalizeFilterType(containerWindow.filter)
  containerWindow.filter = filterId

  if containerWindow.editSearch and containerWindow.editSearch:getText() ~= "" then
    containerWindow.editSearch:setText("")
  end

  if filterId == "all" then
    return refreshContainerItemsALL(container)
  end

  containerPanel:destroyChildren()
  local visibleIndex = 0
  for slot = 0, container:getCapacity()-1 do
    local item = container:getItem(slot)
    if item and applyFilter(filterId, item) then
      createContainerItemWidget(container, containerPanel, slot, item, visibleIndex)
      visibleIndex = visibleIndex + 1
    end
  end

  updateFilterButtons(container)
  toggleContainerPages(containerWindow, container:hasPages())
  refreshContainerPages(container)
  updateContainerContentHeight(container)
end

function toggleContainerPages(containerWindow, hasPages)
  if not depotBoll then
    if hasPages == containerWindow.pagePanel:isOn() then
      return
    end
    if hasPages then
      containerWindow.miniwindowScrollBar:setMarginTop(containerWindow.miniwindowScrollBar:getMarginTop() + containerWindow.pagePanel:getHeight())
      containerWindow.contentsPanel:setMarginTop(containerWindow.contentsPanel:getMarginTop() + containerWindow.pagePanel:getHeight())  
    else  
      containerWindow.miniwindowScrollBar:setMarginTop(containerWindow.miniwindowScrollBar:getMarginTop() - containerWindow.pagePanel:getHeight())
      containerWindow.contentsPanel:setMarginTop(containerWindow.contentsPanel:getMarginTop() - containerWindow.pagePanel:getHeight())
    end
  end
  containerWindow.pagePanel:setOn(hasPages)
end

function refreshContainerPages(container)
  if not container.window:recursiveGetChildById('pageLabel') then return false end
  local currentPage = 1 + math.floor(container:getFirstIndex() / container:getCapacity())
  local pages = 1 + math.floor(math.max(0, (container:getSize() - 1)) / container:getCapacity())
  container.window:recursiveGetChildById('pageLabel'):setText(string.format('Page %i of %i', currentPage, pages))

  local prevPageButton = container.window:recursiveGetChildById('prevPageButton')
  if currentPage == 1 then
    prevPageButton:setEnabled(false)
  else
    prevPageButton:setEnabled(true)
    prevPageButton.onClick = function() g_game.seekInContainer(container:getId(), container:getFirstIndex() - container:getCapacity()) end
  end

  local nextPageButton = container.window:recursiveGetChildById('nextPageButton')
  if currentPage >= pages then
    nextPageButton:setEnabled(false)
  else
    nextPageButton:setEnabled(true)
    nextPageButton.onClick = function() g_game.seekInContainer(container:getId(), container:getFirstIndex() + container:getCapacity()) end
  end
  
  local pagePanel = container.window:recursiveGetChildById('pagePanel')
  if pagePanel then
    pagePanel.onMouseWheel = function(widget, mousePos, mouseWheel)
      if pages == 1 then return end
      if mouseWheel == MouseWheelUp then
        return prevPageButton.onClick()
      else
        return nextPageButton.onClick()
      end
    end
  end
end

function formatDateTime(dateTime)
    local year, month, day, hour, min, sec = dateTime:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
    local formattedDateTime = string.format("%04d-%02d-%02d\n%02d:%02d:%02d", year, month, day, hour, min, sec)
    return formattedDateTime
end
function capitalizeWords(str)
    return (str:gsub("(%w)([%w']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end))
end
function getColorByString(str)
	if str == "MARKET" or str == "SYSTEM" or str == "CATCH" then
		return "#b7b7b7"
	elseif str == "QUEST" or str == "NPC" then
		return "#fdff5d"
	elseif str == "ADMIN" then
		return "#ff7800"
	elseif str == "BOX 5" or str == "BOX 4" or str == "BOX 3" or str == "BOX 2" or str == "BOX 1" then
		return "#8986ff"
	elseif str == "DONATION" then
		return "#abff86"
	else
		return "#a5fffe"
	end
end


function doCheckIsPokeball(data)
	local newdata = json.decode(data.details)
	local attributes = newdata.itemAtribute
	if getBallSpecialAttribute("pokeName", attributes) then
		return true, attributes
	else
		return false, nil
	end
end

function onContainerOpen(container, previousContainer)
  local containerWindow
  local depotBoll
  if previousContainer then
    containerWindow = previousContainer.window
    previousContainer.window = nil
    previousContainer.itemsPanel = nil
  else
    containerWindow = g_ui.createWidget('ContainerWindow', modules.game_interface.getContainerPanel())
    containerWindow:getChildById('text'):setColor('#057FFA')
  end
  if doCheckDepotStatus(container) then
	depotBoll = true
  else
	depotBoll = false
  end
  if containerWindow:getChildById('InboxHistoryPanel') then
	containerWindow:getChildById('InboxHistoryPanel'):destroy()
  end

  local filterPanel = containerWindow.filterPanel.buttonsPael
  filterPanel:destroyChildren()
  for slot, button in ipairs(FILTER_BUTTONS) do
    local ButtonFilter = g_ui.createWidget('ButtonSelectFilter', filterPanel)
	ButtonFilter:setImageSource(button.image)
	ButtonFilter:setTooltip(button.name)
	ButtonFilter:setId(button.id)
	ButtonFilter.filterType = button.action
	ButtonFilter.onClick = function()
      setFilter(containerWindow, container, button.action)
    end
  end
  
  containerWindow:setId('container'..container:getId())
  if gameStart + 1000 < g_clock.millis() then
    containerWindow:clearSettings()
  end
  
  local containerPanel = containerWindow:getChildById('contentsPanel')
  local containerItemWidget = containerWindow:getChildById('containerItemWidget')
  containerWindow.onClose = function()
    g_game.close(container)
    containerWindow:hide()
  end
  containerWindow.onDrop = function(container, widget, mousePos)
    if containerPanel:getChildByPos(mousePos) then
      return false
    end
    local child = containerPanel:getChildByIndex(-1)
    if child then
      child:onDrop(widget, mousePos, true)        
    end
  end
  
  if depotBoll == false then
    containerWindow.onMouseRelease = function(widget, mousePos, mouseButton)
      if mouseButton == MouseButton4 then
        if container:hasParent() then
          return g_game.openParent(container)
        end
      elseif mouseButton == MouseButton5 then
        for i, item in ipairs(container:getItems()) do
          if item:isContainer() then
            return g_game.open(item, container)
          end
        end
      end
    end
  end
  -- this disables scrollbar auto hiding
  local scrollbar = containerWindow:getChildById('miniwindowScrollBar')
  scrollbar:mergeStyle({ ['$!on'] = { }})

  local upButton = containerWindow:getChildById('upButton')
  local closeButton = containerWindow:getChildById('closeButton')
  local minimizeButton = containerWindow:getChildById('minimizeButton')
  local lockButton = containerWindow:getChildById('lockButton')
  local editSearch = containerWindow:getChildById('editSearch')
  upButton.onClick = function()
    g_game.openParent(container)
  end
  upButton:setVisible(container:hasParent())

  local name = container:getName()
  name = name:sub(1, 1):upper() .. name:sub(2)
  if #name > 10 then
	containerWindow:getChildById('text'):setText(name:sub(1, 7).."...")
  else
	containerWindow:getChildById('text'):setText(name)
  end
  containerItemWidget:setItem(container:getContainerItem())
  containerWindow:getChildById('text'):setTooltip(name)
  containerWindow:getChildById('item'):setItem(container:getContainerItem())

  container.window = containerWindow
  container.depotBoll = depotBoll
  container.itemsPanel = containerPanel
  containerWindow.filter = normalizeFilterType(containerWindow.filter)
  refreshContainerItems(container)

  containerWindow:setup()

  if not doCheckDepotStatus(container) then
    if container:hasPages() then
      local height = containerWindow.miniwindowScrollBar:getMarginTop() + containerWindow.pagePanel:getHeight() + 32
      if containerWindow:getHeight() < height then
        containerWindow:setHeight(height)
      end
    end
    local hasHeightInSettings = containerWindow:getSettings("height")
    if not previousContainer and not hasHeightInSettings then
      local filledLines = math.max(math.ceil(container:getItemsCount() / layout:getNumColumns()), 1)
      containerWindow:setContentHeight(filledLines*cellSize.height)
    end
	containerWindow.backgroundTopTittle:setVisible(false)

  elseif doCheckDepotStatus(container) then
	-- 3497 -- POK?MON CENTER MACHINE
	-- 3502 -- DEPOT 
	-- 3498 -- MAIL
	
	local slotItem = container:getContainerItem():getId()
	if slotItem == 3497 then
	  containerWindow.backgroundTopTittle.StatusName:setText("")
	elseif slotItem == 3502 then
      editSearch.onTextChange = function() onSearchItemInContainer(containerWindow, container, editSearch:getText()) end
	else
	  editSearch:setVisible(false)
      editSearch.onTextChange = function() end
	end
	
	if containerWindow:getChildById('return') then containerWindow:getChildById('return'):destroy() end
  
	containerWindow.backgroundTopTittle:setVisible(true)
    upButton:setVisible(false)
    closeButton:setVisible(false)
    minimizeButton:setVisible(false)
    lockButton:setVisible(false)
	containerWindow.pagePanel:setOn(false)
    modules.game_walking.disableWSAD()

    containerWindow:getChildById('text'):setVisible(false)
    containerWindow:getChildById('item'):setVisible(false)
	
	if not containerWindow:getChildById('InboxHistoryPanel') then
		InboxHistoryPanel = g_ui.createWidget('InboxHistoryPanel', containerWindow)
		InboxHistoryPanel:setVisible(false)
	end
  
    containerWindow:setParent(modules.game_interface.getRootPanel())
    containerWindow:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
    containerWindow:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
	containerWindow:setSize('550 399')
	-- containerWindow:setImageSource('/images/ui/container/background_container')
	
	containerWindow.contentsPanel:breakAnchors()
	containerWindow.contentsPanel:addAnchor(AnchorTop, 'parent', AnchorTop)
	containerWindow.contentsPanel:addAnchor(AnchorBottom, 'parent', AnchorBottom)
	containerWindow.contentsPanel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
	containerWindow.contentsPanel:setSize('494 263')
	containerWindow.contentsPanel:setMarginTop(92)
	containerWindow.contentsPanel:setMarginBottom(11)
	containerWindow.contentsPanel:setMarginLeft(20)
	
	containerWindow.filterPanel:breakAnchors()
	containerWindow.filterPanel:addAnchor(AnchorBottom, 'contentsPanel', AnchorTop)
	containerWindow.filterPanel:addAnchor(AnchorLeft, 'contentsPanel', AnchorLeft)
	containerWindow.filterPanel:setSize('185 32')
	-- containerWindow.filterPanel:setImageSource('/images/ui/clear')
	containerWindow.filterPanel:setImageBorder(11)
	containerWindow.filterPanel:setMarginBottom(5)
	containerWindow.filterPanel:setMarginLeft(-2)
	
    CloseDepotButton = g_ui.createWidget('CloseDepotButton', containerWindow)
    CloseDepotButton.onClick = function()
      g_game.close(container)
      containerWindow:hide()
	  modules.game_walking.enableWSAD()
    end

	containerWindow.miniwindowScrollBar:breakAnchors()
	containerWindow.miniwindowScrollBar:addAnchor(AnchorTop, 'contentsPanel', AnchorTop)
	containerWindow.miniwindowScrollBar:addAnchor(AnchorBottom, 'contentsPanel', AnchorBottom)
	containerWindow.miniwindowScrollBar:addAnchor(AnchorLeft, 'contentsPanel', AnchorRight)
	containerWindow.miniwindowScrollBar:setMarginTop(0)
	containerWindow.miniwindowScrollBar:setMarginBottom(0)
	containerWindow.miniwindowScrollBar:setMarginLeft(9)

    if slotItem == 3502 or slotItem == 3498 then
	   containerWindow.pagePanel:setVisible(false)
       containerWindow.contentsPanel:setVisible(false)
       containerWindow.miniwindowScrollBar:setVisible(false)
       containerWindow.filterPanel:setVisible(false)
       containerWindow.editSearch:setVisible(false)
			
       LoadItensPanel = g_ui.createWidget('LoadItensPanel', containerWindow)
	   if slotItem == 3502 then
         LoadItensPanel.progress_back:setImageSource("/images/ui/container/depot_loading")
	   elseif slotItem == 3498 then
         LoadItensPanel.progress_back:setImageSource("/images/ui/container/inbox_loading")
		--  local playerName = g_game.getLocalPlayer():getName()
		--  getMailHistoryByAPI(InboxHistoryPanel.panelList, playerName)
	   end
       
       local numSlots = 8
       local realSlotItems = 0
       local SlotItems = 0
       local totalItems = #container:getItems()
       local reamingTime = 50
       
       local startPercentage = 0
       local endPercentage = 0
    
       for slot, item in ipairs(container:getItems()) do
           if item then
               realSlotItems = realSlotItems + 1
               startPercentage = realSlotItems / totalItems
               endPercentage = realSlotItems / totalItems * 100
               
               scheduleEvent(function()
                   SlotItems = SlotItems + 1
                   local slotIndex = (slot - 1) % numSlots + 1
                   LoadItensPanel.itens_panel["item_"..slotIndex]:setItem(item)
                   local percentage = startPercentage + (endPercentage - startPercentage) * (SlotItems / totalItems)
                   local progressPercentgb = math.floor(100 * percentage / 100)
                   local Yhppcgb = math.floor(281 * (1 - (progressPercentgb / 100)))
                   local rectgb = { x = 0, y = 0, width = 281 - Yhppcgb + 1, height = 11 }
                   LoadItensPanel.progressbar:setImageClip(rectgb)
                   LoadItensPanel.progressbar:setImageRect(rectgb)
               end, reamingTime * slot)
           end
       end
       
       scheduleEvent(function()
         scheduleEvent(function()
            containerWindow.contentsPanel:setVisible(true)
            containerWindow.miniwindowScrollBar:setVisible(true)
            containerWindow.filterPanel:setVisible(true)
            if slotItem == 3502 then
              containerWindow.editSearch:setVisible(true)
              g_effects.fadeIn(containerWindow.editSearch, 350)
              containerWindow.backgroundTopTittle.StatusName:setText("(DEPOT)")
              containerWindow.backgroundTopTittle.StatusName:setColor('#057FFA')
              InboxHistoryPanel:destroy()
            elseif slotItem == 3498 then
              containerWindow.backgroundTopTittle.StatusName:setText("(INBOX)")
              containerWindow.pagePanel:setOn(true)
              containerWindow.miniwindowScrollBar:setVisible(false)
              InboxHistoryPanel:setVisible(true)
            end
            g_effects.fadeIn(InboxHistoryPanel, 350)
            g_effects.fadeIn(containerWindow.contentsPanel, 350)
            g_effects.fadeIn(containerWindow.miniwindowScrollBar, 350)
            g_effects.fadeIn(containerWindow.filterPanel, 350)
            LoadItensPanel:setVisible(false)
            if slotItem == 3502 or slotItem == 3498 then
              ReturnDepotButton = g_ui.createWidget('ReturnDepotButton', containerWindow)
              ReturnDepotButton.onClick = function()
                g_game.openParent(container)
              end
            end
         end, 500)
         g_effects.fadeIn(containerWindow.backgroundTopTittle.StatusName, 350)
         g_effects.fadeOut(LoadItensPanel, 350)
       end, reamingTime * (realSlotItems - 1))
    end

    if slotItem == 3497 then
		containerWindow.contentsPanel:setVisible(false)
		containerWindow.miniwindowScrollBar:setVisible(false)
		containerWindow.filterPanel:setVisible(false)

		-- Destruir widget anterior se existir
		if DepotSelectionButtons and not DepotSelectionButtons:isDestroyed() then
			DepotSelectionButtons:destroy()
			DepotSelectionButtons = nil
		end

		-- Criar com delay para garantir que o container está pronto
		scheduleEvent(function()
			DepotSelectionButtons = g_ui.createWidget('DepotSelectionButtons', containerWindow)
			
			local depotBtn = DepotSelectionButtons:getChildById('depotButton')
			local inboxBtn = DepotSelectionButtons:getChildById('inboxButton')
			
			if depotBtn then
				depotBtn.onClick = function()
					for slot, item in ipairs(container:getItems()) do
						if item:getId() == 3502 then
							g_effects.fadeOut(DepotSelectionButtons, 350)
							scheduleEvent(function()
								if DepotSelectionButtons and not DepotSelectionButtons:isDestroyed() then
									DepotSelectionButtons:destroy()
									DepotSelectionButtons = nil
								end
							end, 400)
							g_game.open(item, container)
							InboxHistoryPanel:setVisible(false)
						end
					end
				end
			end
			
			if inboxBtn then
				inboxBtn.onClick = function()
					for slot, item in ipairs(container:getItems()) do
						if item:getId() == 3498 then
							g_effects.fadeOut(DepotSelectionButtons, 350)
							scheduleEvent(function()
								if DepotSelectionButtons and not DepotSelectionButtons:isDestroyed() then
									DepotSelectionButtons:destroy()
									DepotSelectionButtons = nil
								end
							end, 400)
							g_game.open(item, container)
							InboxHistoryPanel:setVisible(false)
						end
					end
				end
			end
		end, 100)
	end
  end
end

function doResetFilter(panel, container)
    local children = panel:getChildren()
	local panelFilter = container.window.filter
	
    for i = 1, #children do
	  if children[i].filterType == panelFilter or children[i]:getId() == panelFilter then
		children[i]:focus()
		children[i]:setOn(true)
		children[i]:setImageColor("#79b2ff")
	  else
		children[i]:setOn(false)
		children[i]:setImageColor("#8d8e8e")
	  end
    end
end

function onSearchItemInContainer(containerWindow, container, filterKey)
  local containerPanel = containerWindow:getChildById('contentsPanel')
  local panelFilter = container.window.filterPanel.buttonsPael

  container.window.filter = "all"
  doResetFilter(panelFilter, container)
  
  if filterKey == nil or #filterKey == 0 then
	return refreshContainerItemsALL(container)
  end

  containerPanel:destroyChildren()
  for slot, item in ipairs(container:getItems()) do
	local itemInfoName = getItemName(item)

	if itemInfoName ~= "" and string.find(string.lower(itemInfoName), string.lower(filterKey)) then
      createContainerItemWidget(container, containerPanel, slot, item, slot)
	end
  end

  container.window = containerWindow
  container.itemsPanel = containerPanel

  toggleContainerPages(containerWindow, container:hasPages())
  refreshContainerPages(container)

  updateContainerContentHeight(container, 10 * (container:getCapacity()-1))
  
  containerWindow.filter = "all"
  containerWindow:setup()
end

function setFilter(containerWindow, container, filterType)
  if not containerWindow or not container then
    return
  end

  containerWindow.filter = normalizeFilterType(filterType)
  refreshContainerItems(container)
  if containerWindow.setup then
    containerWindow:setup()
  end
end

function onContainerFilter(containerWindow, container, filterKey)
  setFilter(containerWindow, container, filterKey)
end

function onContainerClose(container)
  if container:getContainerItem():getId() == 3497 then
    if DepotSelectionButtons and not DepotSelectionButtons:isDestroyed() then
      DepotSelectionButtons:destroy()
      DepotSelectionButtons = nil
    end
  end
  destroy(container)
end

function onContainerChangeSize(container, size)
  if not container.window then return end
  refreshContainerItems(container)
end

function onContainerUpdateItem(container, slot, item, oldItem)
  if not container.window then return end
  if container.window.filter and normalizeFilterType(container.window.filter) ~= "all" then
    refreshContainerItems(container)
    return
  end

  local itemWidget = container.itemsPanel and container.itemsPanel:getChildById('item' .. slot)
  if itemWidget then
    itemWidget:setItem(item)
    itemWidget:setOpacity(item and 1 or 0.25)
    applyPokemonTooltipInfo(itemWidget, item)
    applyPokeballPokemonIcon(itemWidget, item)
  else
    refreshContainerItems(container)
  end
end

function onContainerAddItem(container, slot, item)
  if not container.window then return end
  refreshContainerItems(container)
end

function onContainerRemoveItem(container, slot, item)
  if not container.window then return end
  refreshContainerItems(container)
end


function itemExistsInContainer(container, tableId)
  local items = container:getItems()

  for _, item in ipairs(items) do
    local itemInfo = item:getItemInfo() 
      for _, pokemonID in ipairs(tableId) do
          if itemInfo.ItemID == pokemonID then
              return true
          end
      end
  end

  return false
end
function itemExistsInTable(item, table)
  for _, value in ipairs(table) do
      if value == item then
          return true
      end
  end
  return false
end

isDepotTable = {3497,3498,3499,3500,3502,3497,3502}
function doCheckDepotStatus(container)
	local containerId = container:getContainerItem():getId()
	local containerIdState = container:getId()
	if itemExistsInTable(containerId, isDepotTable) then
		return true
	elseif itemExistsInTable(containerIdState, isDepotTable) then
		return true
	end
	return false
end
