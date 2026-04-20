# Exemplos de Uso - Daily Rewards Module

## Exemplos Básicos

### 1. Abrir a Janela de Recompensas

```lua
-- Abrir a janela
modules.game_daily_rewards.show()
```

### 2. Fechar a Janela

```lua
-- Fechar a janela
modules.game_daily_rewards.hide()
```

### 3. Alternar Visibilidade

```lua
-- Mostrar se estiver oculta, ocultar se estiver visível
modules.game_daily_rewards.toggleWindow()
```

### 4. Coletar Recompensa

```lua
-- Tentar coletar a recompensa do dia
modules.game_daily_rewards.claimReward()
```

### 5. Atualizar Dados

```lua
-- Solicitar atualização dos dados ao servidor
modules.game_daily_rewards.requestRewardsData()
```

## Exemplos Avançados

### 1. Integração com Botão do Menu

```lua
-- Adicionar botão no menu superior
local button = modules.client_topmenu.addRightGameToggleButton(
    "dailyRewards",
    tr("Daily Rewards"),
    "/modules/game_daily_rewards/images/gift.png",
    function()
        modules.game_daily_rewards.toggleWindow()
    end,
    true
)
```

### 2. Abrir Automaticamente ao Logar

```lua
-- Conectar ao evento de login
connect(g_game, {
    onGameStart = function()
        scheduleEvent(function()
            if g_game.isOnline() then
                modules.game_daily_rewards.show()
            end
        end, 2000)
    end
})
```

### 3. Notificação ao Receber Recompensa

```lua
-- Adicionar notificação visual
local originalClaim = modules.game_daily_rewards.claimReward
modules.game_daily_rewards.claimReward = function()
    originalClaim()
    -- Adicionar efeito visual ou som
    g_sounds.play("/sounds/reward.ogg")
end
```

### 4. Verificar Status das Recompensas

```lua
-- Verificar dados atuais
local currentDay = modules.game_daily_rewards.currentDay
local canClaim = modules.game_daily_rewards.canClaim
local nextClaimTime = modules.game_daily_rewards.nextClaimTime

print("Dia atual: " .. currentDay)
print("Pode coletar: " .. tostring(canClaim))
print("Próxima recompensa em: " .. nextClaimTime)
```

### 5. Customizar Recompensas

```lua
-- Modificar dados das recompensas (antes de criar os widgets)
modules.game_daily_rewards.rewardsData[1] = {
    clientId = 12345,
    count = 5,
    name = "Item Customizado"
}
```

## Exemplos de Integração com Outros Módulos

### 1. Integração com Sistema de Notificações

```lua
-- Notificar quando recompensa está disponível
if modules.game_daily_rewards.canClaim then
    modules.game_textmessage.displayGameMessage(
        "Você tem uma recompensa diária disponível!"
    )
end
```

### 2. Integração com Sistema de Quests

```lua
-- Marcar quest como completa ao coletar recompensa
local originalClaim = modules.game_daily_rewards.claimReward
modules.game_daily_rewards.claimReward = function()
    originalClaim()
    -- Marcar quest
    if modules.game_questlog then
        modules.game_questlog.markQuestAsCompleted("daily_reward")
    end
end
```

### 3. Integração com Sistema de Achievements

```lua
-- Desbloquear achievement ao coletar 21 dias seguidos
local function checkAchievement()
    if modules.game_daily_rewards.currentDay == 21 then
        -- Desbloquear achievement
        if modules.game_achievements then
            modules.game_achievements.unlock("daily_master")
        end
    end
end
```

## Exemplos de Customização Visual

### 1. Mudar Cores dos Estados

```lua
-- Editar o arquivo game_daily_rewards.lua
-- Na função updateRewardsDisplay(), modificar as cores:

-- Dia coletado (verde)
widget:setBackgroundColor('#0a2a0a')
widget:setBorderColor('#00aa00')

-- Dia atual disponível (amarelo)
widget:setBackgroundColor('#2a2a00')
widget:setBorderColor('#ffcc00')

-- Dia atual indisponível (vermelho)
widget:setBackgroundColor('#2a0a0a')
widget:setBorderColor('#ff6666')

-- Dia futuro (cinza)
widget:setBackgroundColor('#0f0f0f')
widget:setBorderColor('#2a2a2a')
```

### 2. Adicionar Som ao Coletar

```lua
-- Adicionar som de recompensa
local originalClaim = modules.game_daily_rewards.claimReward
modules.game_daily_rewards.claimReward = function()
    originalClaim()
    g_sounds.play("/sounds/reward_collected.ogg")
end
```

### 3. Adicionar Animação

```lua
-- Adicionar animação ao widget de recompensa
local function animateRewardWidget(widget)
    local originalOpacity = widget:getOpacity()
    
    for i = 1, 5 do
        scheduleEvent(function()
            widget:setOpacity(1.0)
        end, i * 100)
        
        scheduleEvent(function()
            widget:setOpacity(0.5)
        end, i * 100 + 50)
    end
end
```

## Exemplos de Debug

### 1. Verificar Dados Recebidos

```lua
-- Adicionar log dos dados recebidos
local originalOnReceive = modules.game_daily_rewards.onReceiveRewards
modules.game_daily_rewards.onReceiveRewards = function(protocol, opcode, buffer)
    print("Dados recebidos: " .. buffer)
    originalOnReceive(protocol, opcode, buffer)
end
```

### 2. Verificar Estado dos Widgets

```lua
-- Listar todos os widgets de recompensa
for day, widget in pairs(modules.game_daily_rewards.rewardWidgets) do
    print("Dia " .. day .. ": " .. tostring(widget:isOn()))
end
```

### 3. Forçar Atualização

```lua
-- Forçar atualização da interface
modules.game_daily_rewards.updateRewardsDisplay()
modules.game_daily_rewards.updateInfoText()
```

## Exemplos de Tratamento de Erros

### 1. Verificar se Módulo Está Carregado

```lua
-- Verificar antes de usar
if modules.game_daily_rewards then
    modules.game_daily_rewards.show()
else
    print("Módulo de Daily Rewards não está carregado!")
end
```

### 2. Tratamento de Erro ao Coletar

```lua
-- Envolver em pcall para tratamento de erro
local success, error = pcall(function()
    modules.game_daily_rewards.claimReward()
end)

if not success then
    print("Erro ao coletar recompensa: " .. error)
end
```

### 3. Validar Dados Recebidos

```lua
-- Validar dados antes de usar
local function validateRewardsData(data)
    if not data.rewards or not data.currentDay then
        return false, "Dados inválidos"
    end
    
    if data.currentDay < 1 or data.currentDay > 21 then
        return false, "Dia inválido"
    end
    
    return true
end
```

## Exemplos de Configuração

### 1. Mudar Opcode

```lua
-- No arquivo game_daily_rewards.lua, alterar:
local OPCODE = 3  -- Mudar de 2 para 3
```

### 2. Mudar Tamanho da Janela

```lua
-- No arquivo game_daily_rewards.otui, alterar:
MainWindow
  id: dailyRewardsWindow
  size: 700 550  -- Mudar tamanho
```

### 3. Mudar Número de Dias

```lua
-- Modificar o loop de criação de widgets
for dayIndex = 1, 30 do  -- Mudar de 21 para 30
    -- ...
end
```

## Dicas e Truques

### 1. Abrir Automaticamente com Comando

```lua
-- Adicionar comando para abrir
g_game.registerCommand("dailyrewards", function()
    modules.game_daily_rewards.show()
end)
```

### 2. Salvar Preferência de Visibilidade

```lua
-- Lembrar se estava aberta
local wasVisible = modules.game_daily_rewards.mainWindow:isVisible()
g_settings.set("daily_rewards_visible", wasVisible)

-- Restaurar ao logar
if g_settings.getBoolean("daily_rewards_visible") then
    modules.game_daily_rewards.show()
end
```

### 3. Adicionar Tooltip

```lua
-- Adicionar tooltip ao widget
widget:setTooltip("Dia " .. day .. ": " .. rewardsData[day].name)
```

## Troubleshooting

### Problema: Janela não abre
```lua
-- Verificar se mainWindow foi criado
if not modules.game_daily_rewards.mainWindow then
    print("mainWindow não foi criado!")
end
```

### Problema: Recompensas não aparecem
```lua
-- Verificar se rewardWidgets foi criado
print("Número de widgets: " .. #modules.game_daily_rewards.rewardWidgets)
```

### Problema: Servidor não responde
```lua
-- Verificar se protocolo está registrado
print("Protocolo registrado: " .. tostring(ProtocolGame.isExtendedOpcodeRegistered(2)))
```

## Recursos Adicionais

- Documentação do OTClient: `/docs/otclient/`
- Documentação do Servidor: `/docs/server/`
- Exemplos de Módulos: `/modules/`
- Fórum de Suporte: https://nordemon.online/forum
