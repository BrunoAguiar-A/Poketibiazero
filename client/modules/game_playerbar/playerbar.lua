-- chunkname: @/modules/game_playerbar/playerbar.lua

playerBarWindow = nil
healthTooltip = "Your character health is %d out of %d."
manaTooltip = "Your character mana is %d out of %d."
experienceTooltip = "EXP: %s / %s (%d%%) para o nivel %d."
imageClipPokeball = {
	[0] = 0,
	14,
	28,
	42,
	56,
	70,
	84
}

local imageBarPath = "/images/game/playerbar/"
local imageBar = {
	"bar_valor",
	"bar_mystic",
	[-1] = "default",
	[3] = "bar_instinct"
}
local profileBar = {
	[0] = {
		image = "girl_player_bar",
		size = {
			height = 141,
			width = 94
		}
	},
	{
		image = "boy_player_bar",
		size = {
			height = 112,
			width = 107
		}
	}
}

function init()
	connect(g_game, {
		onGameEnd = offline,
		onGameStart = refresh
	})
	connect(LocalPlayer, {
		onHealthChange = onHealthChange,
		onManaChange = onManaChange,
		onExperienceChange = onExperienceChange,
		onLevelChange = onLevelChange,
		onFreeCapacityChange = onFreeCapacityChange,
		onExtraSkillChange = onExtraSkillChange,
		onInventoryChange = onInventoryChange
	})

	playerBarWindow = g_ui.loadUI("playerbar", modules.game_interface.getRootPanel())

	if not playerBarWindow then
		print("[game_playerbar] ERRO: Falha ao carregar playerbar.otui - widget retornou nil")
		return
	end

	print("[game_playerbar] init OK, window=" .. tostring(playerBarWindow))

	refresh()

	-- Inicia o polling para atualizar pokébolas
	startPokebarPolling()
end

function terminate()
	disconnect(g_game, {
		onGameEnd = offline,
		onGameStart = refresh
	})
	disconnect(LocalPlayer, {
		onHealthChange = onHealthChange,
		onManaChange = onManaChange,
		onExperienceChange = onExperienceChange,
		onLevelChange = onLevelChange,
		onFreeCapacityChange = onFreeCapacityChange,
		onExtraSkillChange = onExtraSkillChange,
		onInventoryChange = onInventoryChange
	})

	-- Para o polling
	stopPokebarPolling()

	if playerBarWindow then
		playerBarWindow:destroy()
	end

	playerBarWindow = nil
end

function toggle()
	if playerBarWindow then
		playerBarWindow:setVisible(not playerBarWindow:isVisible())
	end
end

function refresh()
	if not g_game.isOnline() then
		return
	end

	if not playerBarWindow then
		print("[game_playerbar] refresh: playerBarWindow é nil")
		return
	end

	print("[game_playerbar] refresh: mostrando barra do player")

	local settings = g_settings.getNode("playerBar")

	if settings and settings.position then
		local pos = topoint(settings.position)
		if pos and pos.x and pos.y then
			playerBarWindow:setPosition(pos)
		end
	end

	-- Sempre garante que a barra está dentro da tela
	playerBarWindow:bindRectToParent()
	playerBarWindow:setVisible(true)
	playerBarWindow:raise()

	local player = g_game.getLocalPlayer()
	if not player then return end

	onHealthChange(player, player:getHealth(), player:getMaxHealth())
	onLevelChange(player, player:getLevel(), player:getLevelPercent())
	onExperienceChange(player, player:getExperience())
	updateExperienceBar(player)
end

function offline()
	if not playerBarWindow then return end
	local settings = {
		position = pointtostring(playerBarWindow:getPosition()),
	}

	g_settings.setNode("playerBar", settings)
	playerBarWindow:hide()
end

function onMiniWindowClose()
	return
end

function onHealthChange(localPlayer, health, maxHealth)
	if not playerBarWindow then return end
	if not playerBarWindow.healthBar then return end
	if maxHealth < health then
		maxHealth = health
	end

	local percent = maxHealth > 0 and math.floor((health * 100) / maxHealth) or 0
	playerBarWindow.healthBar:setValue(health, 0, maxHealth)
	playerBarWindow.healthBar:setTooltip(tr(healthTooltip, health, maxHealth))
	playerBarWindow.healthBar:setPercent(percent)
	playerBarWindow.healthBar:setText(percent .. "%")
end

local function expForLevel(level)
	return math.floor((50 * level * level * level) / 3 - 100 * level * level + (850 * level) / 3 - 200)
end

local function formatNumber(value)
	if comma_value then
		return comma_value(value)
	end
	return tostring(value)
end

function updateExperienceBar(player)
	if not playerBarWindow or not playerBarWindow.expBar or not playerBarWindow.lvlLabel or not player then
		return
	end

	local level = player:getLevel()
	local currentExp = player:getExperience()
	local currentLevelExp = expForLevel(level)
	local nextLevelExp = expForLevel(level + 1)
	local levelRange = math.max(1, nextLevelExp - currentLevelExp)
	local gainedInLevel = math.max(0, math.min(currentExp - currentLevelExp, levelRange))
	local percent = math.floor((gainedInLevel * 100) / levelRange)

	playerBarWindow.lvlLabel:setText(tr("Nv. %d", level))
	playerBarWindow.expBar:setValue(gainedInLevel, 0, levelRange)
	playerBarWindow.expBar:setPercent(percent)
	playerBarWindow.expBar:setText(percent .. "%")
	playerBarWindow.expBar:setTooltip(tr(experienceTooltip, formatNumber(gainedInLevel), formatNumber(levelRange), percent, level + 1))
end

function onExperienceChange(localPlayer, value)
	updateExperienceBar(localPlayer)
end

function onLevelChange(localPlayer, value, percent)
	updateExperienceBar(localPlayer)
end

function onManaChange(localPlayer, mana, maxMana)
	return
end

local pokeballCountCache = 0
local pokebarUpdateEvent = nil
local pokebarPollingEvent = nil

function updatePokeballCount()
	if not playerBarWindow or not playerBarWindow.pokeballs then
		return
	end

	local ok, rootPanel = pcall(function() return modules.game_interface.getRootPanel() end)
	if not ok or not rootPanel then return end

	local pokebar = rootPanel:recursiveGetChildById("panelBar")
	local pokeballCount = 0

	if pokebar then
		pokeballCount = pokebar:getChildCount()
	end

	-- Limita a 6 pokébolas para a exibição
	if pokeballCount > 6 then
		pokeballCount = 6
	end

	-- Só atualiza se o valor mudou
	if pokeballCountCache ~= pokeballCount then
		pokeballCountCache = pokeballCount
		playerBarWindow.pokeballs:setImageClip("0 " .. (imageClipPokeball[pokeballCount] or 0) .. " 82 12")
	end
end

function startPokebarPolling()
	-- Para o polling anterior se existir
	if pokebarPollingEvent then
		removeEvent(pokebarPollingEvent)
	end
	
	-- Inicia polling a cada 500ms para verificar mudanças na pokebar
	pokebarPollingEvent = scheduleEvent(function()
		updatePokeballCount()
		startPokebarPolling()
	end, 500)
end

function stopPokebarPolling()
	if pokebarPollingEvent then
		removeEvent(pokebarPollingEvent)
		pokebarPollingEvent = nil
	end
end

function onFreeCapacityChange(player, freeCapacity)
	if not playerBarWindow or not playerBarWindow.pokeballs then
		return
	end
	
	-- O polling vai cuidar de atualizar as pokébolas
end

function onInventoryChange(player, slot, item)
	-- Atualiza as pokébolas quando o inventário muda
	updatePokeballCount()
end

function onExtraSkillChange(player, id, value)
	if id == Skill.Clan then
		playerBarWindow:setImageSource(imageBarPath .. (imageBar[value] or "default"))
	elseif id == Skill.Profile then
		local profile = profileBar[value]

		if profile then
			playerBarWindow.profile:setImageSource(imageBarPath .. profile.image)
		end
	end
end
