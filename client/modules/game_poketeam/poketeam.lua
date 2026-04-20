-- chunkname: @/modules/game_poketeam/poketeam.lua

PokeBar = {}

local panelBar, currentSlotBar
local protocol = runinsandbox("protocol")
local pokemonOrder = {}
local slotBarAssociationsHotkeys = {}
local abilities = {
	fly = {
		tooltip = "Fly",
		imageClip = { x = 0, y = 0, width = 20, height = 20 },
		-- callback = function()
			-- g_game.getLocalPlayer():doUseSelfOrder()
		-- end
	},
	teleport = {
		tooltip = "Teleport",
		imageClip = { x = 20, y = 0, width = 20, height = 20 },
		-- callback = function()
			-- modules.game_minimap.toggleFullMap()
		-- end
	},
	cut = {
		tooltip = "Cut",
		imageClip = { x = 40, y = 0, width = 20, height = 20 },
		-- callback = function()
			-- g_game.talk("!cut")
		-- end
	},
	surf = {
		tooltip = "Surf",
		imageClip = { x = 60, y = 0, width = 20, height = 20 },
		-- callback = function()
			-- g_game.talk("!surf")
		-- end
	},
	dig = {
		tooltip = "Dig",
		imageClip = { x = 80, y = 0, width = 20, height = 20 },
		callback = function()
			g_game.talk("!dig")
		end
	},
	-- headbutt = {
		-- tooltip = "Headbutt",
		-- imageClip = { x = 100, y = 0, width = 20, height = 20 },
		-- -- callback = function()
			-- -- g_game.talk("!headbutt")
		-- -- end
	-- },
	strength = {
		tooltip = "Strength",
		imageClip = { x = 0, y = 0, width = 20, height = 20 },
		-- callback = function()
			-- g_game.talk("!strength")
		-- end
	},
	waterfall = {
		tooltip = "Waterfall",
		imageClip = { x = 20, y = 0, width = 20, height = 20 },
		-- callback = function()
			-- g_game.talk("!waterfall")
		-- end
	},
	rocksmash = {
		tooltip = "Rock Smash",
		imageClip = { x = 40, y = 0, width = 20, height = 20 },
		-- callback = function()
			-- g_game.talk("!rocksmash")
		-- end
	},
	flash = {
		tooltip = "Flash",
		imageClip = { x = 120, y = 0, width = 20, height = 20 },
		-- callback = function()
			-- g_game.talk("!flash")
		-- end
	}
}

local function doUpdateHotkey(slotBar)
	if not KeybindManager then return end
	local keybind = KeybindManager:getKeybindByName("Chamar " .. panelBar:getChildIndex(slotBar), "Pokemon")

	if keybind then
		slotBar.keyCombo:setText(keybind.keyCombo)

		slotBarAssociationsHotkeys[keybind.name] = slotBar
	end
end

local function doEditOrder()
	panelBar.isEditingMode = not panelBar.isEditingMode

	for i, slotBar in ipairs(panelBar:getChildren()) do
		local opacityEdit = panelBar.isEditingMode and 0.8 or 1

		slotBar:setOpacity(opacityEdit)
	end

	g_mouse.popCursor("target")
end

local function doUpdateOrder()
	local children = panelBar:getChildren()

	table.sort(children, function(a, b)
		if not a.pokemon or not b.pokemon then return false end
		return (pokemonOrder[a.pokemon.name] or 100) < (pokemonOrder[b.pokemon.name] or 100)
	end)
	panelBar:reorderChildren(children)

	for i, slotBar in pairs(panelBar:getChildren()) do
		doUpdateHotkey(slotBar)
	end
end

local function doUpdateResizeBar()
	local height = 20

	for i, slotBar in ipairs(panelBar:getChildren()) do
		height = height + slotBar:getHeight() + slotBar:getMarginTop()
	end

	panelBar:resize(199, height)
end

local function doUpdateElementSlotBar(slotBar)
	slotBar.elements:destroyChildren()

	local width = slotBar.elements:getWidth()
	local pokemon = Pokedex_PokemonsByName[getPokemonName(slotBar.pokemon.name):lower()]

	if pokemon then
		for i, name in pairs(pokemon.Types) do
			local info = Pokedex_Types[name]

			if info then
				local widget = g_ui.createWidget("UIWidget", slotBar.elements)
				widget:setSize({width = width, height = width})
				widget:setImageSource("/modules/game_dex/images/types/" .. name:lower())
				widget:setTooltip(info.Text)
			end
		end
	end

	slotBar.elements:setHeight(slotBar.elements:getChildCount() * width)
end

local function doUpdateTimerBall(slotBar)
	if not slotBar.pokemon.cooldown then
		slotBar.pokemon.cooldown = -1
	end

	if slotBar.pokemon.cooldown > -1 then
		slotBar.timer:setOn(true)
		removeEvent(slotBar.eventId)

		slotBar.eventId = scheduleEvent(function()
			slotBar.timer:setOn(false)
		end, slotBar.pokemon.cooldown * 1000)
	end
end

local function doUpdateAbilities(slotBar)
	slotBar.abilities:setVisible(true)
	slotBar.timer:setVisible(slotBar.pokemon.cooldown and slotBar.pokemon.cooldown > -1)

	slotBar.abilities:destroyChildren()

	local pokemon = Pokedex_PokemonsByName[getPokemonName(slotBar.pokemon.name):lower()]
	local abilitiesToShow = {}

	-- Se o pokémon tem abilities definidas no Pokedex, usa essas
	if pokemon and #pokemon.Abilities > 0 then
		abilitiesToShow = pokemon.Abilities
	else
		-- Caso contrário, mostra as habilidades padrão (fly, teleport, cut, surf)
		abilitiesToShow = {"fly", "teleport", "cut", "surf"}
	end

	local width = 0

	for i, name in ipairs(abilitiesToShow) do
		local value = abilities[name]

		if value then
			local icon = g_ui.createWidget("SlotBarAbilitiesIcon", slotBar.abilities)

			icon:setImageClip(value.imageClip)
			icon:setTooltip(value.tooltip)

			icon.onClick = value.callback
			width = width + 12
		end
	end

	slotBar.abilities:setWidth(width)
end

local function doUpdateStateSlotBar(slotBar, state)
	slotBar:setChecked(state)

	for i, child in pairs(slotBar:getChildren()) do
		child:setChecked(state)
	end

	doUpdateElementSlotBar(slotBar, slotBar.pokemon)
end

local function doUpdateLocalSummonXpPercent(pokemon)
	if not pokemon or not pokemon.use then return end
	local player = g_game.getLocalPlayer()
	if not player then return end
	local summons = g_map.getSpectators(player:getPosition(), false)
	for _, creature in ipairs(summons) do
		if creature:isLocalSummon() then
			creature:setManaPercent(math.min(100, math.max(0, pokemon.xpPercent or pokemon.expPercent or 0)))
			return
		end
	end
end

local function doRemoveSlotBar(slotBar)
	if slotBar == currentSlotBar then
		currentSlotBar = nil
	end

	slotBarAssociationsHotkeys[slotBar.keyCombo:getText()] = nil
	pokemonOrder[slotBar.pokemon.name] = nil
	panelBar[slotBar:getId()] = nil

	removeEvent(slotBar.eventId)
	slotBar:destroy()
	doUpdateResizeBar()
end

local function doUpdateSlotBar(slotBar, pokemon)
	local isAlive = pokemon.health > 0

	slotBar.pokemon = pokemon

	slotBar:setOn(not isAlive)
	slotBar.image:setEnabled(isAlive)
	slotBar.keyCombo:setOn(not isAlive)
	local percent = pokemon.health
	if pokemon.maxHealth and pokemon.maxHealth > 100 then
		percent = math.floor((pokemon.health / pokemon.maxHealth) * 100)
	end
	percent = math.min(100, math.max(0, percent))

	slotBar.progress:setPercent(percent)
	slotBar.progress:setText(("%d%%"):format(percent))
	slotBar.image:setImageSource(getPokemonPortrait(pokemon.name))
	slotBar.progress:setBackgroundColor(getHealthColor(percent))
	doUpdateTimerBall(slotBar)
	doUpdateAbilities(slotBar)
	doUpdateElementSlotBar(slotBar)
	doUpdateLocalSummonXpPercent(pokemon)

	if pokemon.text == tr("USE") or pokemon.use then
		currentSlotBar = slotBar

		doUpdateStateSlotBar(slotBar, true)
	elseif slotBar == currentSlotBar then
		currentSlotBar = nil

		doUpdateStateSlotBar(slotBar, false)
	end
end

local function onDragEnter(slotBar, mousePosition)
	if panelBar.isEditingMode then
		slotBar.drag = true

		g_mouse.pushCursor("target")
	else
		panelBar:breakAnchors()

		slotBar.movingReference = {
			x = mousePosition.x - panelBar:getX(),
			y = mousePosition.y - panelBar:getY()
		}
	end

	return not panelBar:isOn()
end

local function onDragMove(slotBar, mousePosition, mouseMoved)
	if not panelBar.isEditingMode then
		local pos = {
			x = mousePosition.x - slotBar.movingReference.x,
			y = mousePosition.y - slotBar.movingReference.y
		}

		panelBar:setPosition(pos)
		panelBar:bindRectToParent()
	end

	return not panelBar:isOn()
end

local function onDragLeave(slotBar, droppedWidget, mousePosition)
	if panelBar.isEditingMode then
		local move = panelBar:getChildByPos(mousePosition)

		if move and move ~= slotBar and move.moveSlot then
			local moveIndex = panelBar:getChildIndex(move)
			local selfIndex = panelBar:getChildIndex(slotBar)

			pokemonOrder[move.pokemon.name] = selfIndex
			pokemonOrder[slotBar.pokemon.name] = moveIndex

			panelBar:moveChildToIndex(move, selfIndex)
			panelBar:moveChildToIndex(slotBar, moveIndex)
			doUpdateHotkey(move)
			doUpdateHotkey(slotBar)
		end

		slotBar.drag = false

		slotBar:setOpacity(0.8)
		g_mouse.popCursor("target")
	else
		slotBar.dragLeave = g_clock.millis() + 2
	end
end

local function onMouseRelease(slotBar, mousePosition, mouseButton)
	if mouseButton == MouseLeftButton and g_clock.millis() > slotBar.dragLeave and not panelBar.isEditingMode then
		g_game.talk("!p " .. slotBar.pokemon.fastcallNumber)
	end

	return true
end

local function onHoverChange(slotBar, hovered)
	if panelBar.isEditingMode then
		if hovered then
			slotBar:setOpacity(1)
		elseif not slotBar.drag then
			slotBar:setOpacity(0.8)
		end
	end
end

local function onClick(widget)
	if not KeybindManager then return end
	local slotBar = widget:getParent()
	local keybind = KeybindManager:getKeybindByName("Chamar " .. panelBar:getChildIndex(slotBar), "Pokemon")

	if keybind then
		keybind:capture(KEYCOMBO_PRIMARY)
	end
end

local function onRemoveAllSlotBars()
	panelBar:destroyChildren()
	doUpdateResizeBar()
end

local function onAddSlotBar(pokemon)
	if not pokemon.fastcallNumber then
		pokemon.fastcallNumber = pokemon.pokeid:gsub("!p ", "")
	end
	local slotBar = g_ui.createWidget("SlotBar", panelBar)
	if not slotBar then return end

	slotBar.onDragEnter = onDragEnter
	slotBar.onDragMove = onDragMove
	slotBar.onDragLeave = onDragLeave
	slotBar.onMouseRelease = onMouseRelease
	slotBar.onHoverChange = onHoverChange
	slotBar.keyCombo.onClick = onClick
	pokemonOrder[pokemon.name] = pokemonOrder[pokemon.name] or panelBar:getChildCount()

	g_mouse.bindPress(slotBar, createMenu, MouseRightButton)
	slotBar:setId(pokemon.fastcallNumber)
	doUpdateSlotBar(slotBar, pokemon)
	doUpdateHotkey(slotBar)
	doUpdateResizeBar()
end

local function onRemoveSlotBar(fastcallNumber)
	local slotBar = panelBar[fastcallNumber]

	if slotBar then
		doRemoveSlotBar(slotBar)
	end
end

local function onUpdateSlotBar(pokemon)
	local slotBar = panelBar[pokemon.fastcallNumber]

	if slotBar then
		doUpdateSlotBar(slotBar, pokemon)
	end
end

function init()
	print(">>> game_poketeam init")
	protocol.initProtocol()
	connect(g_game, {
		onGameStart = onGameStart,
		onGameEnd = onGameEnd
	})
	connect(PokeBar, {
		onAddSlotBar = onAddSlotBar,
		onRemoveSlotBar = onRemoveSlotBar,
		onUpdateSlotBar = onUpdateSlotBar,
		onRemoveAllSlotBars = onRemoveAllSlotBars
	})
	connect(Creature, {
		onHealthPercentChange = onCreatureHealthPercentChange
	})
	if KeybindManager then
		connect(KeybindManager, {
			onUpdateHotkey = onUpdateHotkey
		})
	end

	panelBar = g_ui.loadUI("poketeam", modules.game_interface.getRootPanel())
end

function terminate()
	protocol.terminateProtocol()
	disconnect(g_game, {
		onGameStart = onGameStart,
		onGameEnd = onGameEnd
	})
	disconnect(Creature, {
		onHealthPercentChange = onCreatureHealthPercentChange
	})
	if KeybindManager then
		disconnect(KeybindManager, {
			onUpdateHotkey = onUpdateHotkey
		})
	end
	panelBar:destroy()
end

function onGameStart()
	local settings = g_settings.getNode("pokebarConfig")

	if settings then
		if settings.orders then
			pokemonOrder = settings.orders

			scheduleEvent(doUpdateOrder, 100)
		end

		panelBar:breakAnchors()
		panelBar:setOn(settings.locked)
		panelBar:setPosition(settings.position)
	end

	panelBar:setVisible(modules.client_options.getOption("pokebar"))
	
	-- Request pokebar from server
	if g_game.isOnline() then
		g_game.getProtocolGame():sendExtendedOpcode(1, "pokebar")
	end
end

function onGameEnd()
	local settings = {
		position = pointtostring(panelBar:getPosition()),
		locked = panelBar:isOn(),
		orders = pokemonOrder
	}

	currentSlotBar = nil

	panelBar:destroyChildren()
	g_settings.setNode("pokebarConfig", settings)
end

function onCreatureHealthPercentChange(creature, health)
	if currentSlotBar and creature:isLocalSummon() then
		if currentSlotBar.progress then
			local percent = math.min(100, math.max(0, creature:getHealthPercent()))
			currentSlotBar.progress:setPercent(percent)
			currentSlotBar.progress:setText(("%d%%"):format(percent))
			currentSlotBar.progress:setBackgroundColor(getHealthColor(percent))
		end
	end
end

function onUpdateHotkey(category, name, keyCombo, altKeyCombo)
	if category == "Pokemon" and slotBarAssociationsHotkeys[name] then
		slotBarAssociationsHotkeys[name].keyCombo:setText(keyCombo)
	end
end

function createMenu()
	local menu = g_ui.createWidget("PopupMenu")

	menu:addOption(panelBar:isOn() and tr("Unlocked") or tr("Locked"), function()
		panelBar:setOn(not panelBar:isOn())
	end)
	menu:addOption(panelBar.isEditingMode and tr("Save order") or tr("Edit order"), function()
		doEditOrder()
	end)
	menu:display()
end

function getPokemonBar()
	return panelBar
end

function doCallPokemon(index)
	local slotBar = panelBar:getChildByIndex(index)

	if slotBar then
		g_game.talk("!p " .. slotBar.pokemon.fastcallNumber)
	end
end
