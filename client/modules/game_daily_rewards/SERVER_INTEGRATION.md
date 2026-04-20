# Integração do Daily Rewards com o Servidor

## Visão Geral

O módulo `game_daily_rewards` se comunica com o servidor através do protocolo estendido usando o opcode `2`. Esta documentação descreve como implementar o lado servidor.

## Protocolo de Comunicação

### Opcode: 2

#### Requisições do Cliente

**1. Refresh (Atualizar dados)**
```json
{
  "action": "refresh"
}
```

**2. Claim (Coletar recompensa)**
```json
{
  "action": "claim"
}
```

#### Respostas do Servidor

**Estrutura completa:**
```json
{
  "rewards": {
    "1": {"clientId": 26731, "count": 1, "name": "Leaf Stone"},
    "2": {"clientId": 26728, "count": 1, "name": "Fire Stone"},
    "3": {"clientId": 26736, "count": 1, "name": "Water Stone"},
    "4": {"clientId": 26734, "count": 1, "name": "Thunder Stone"},
    "5": {"clientId": 2152, "count": 5, "name": "Hundred Dollar"},
    "6": {"clientId": 27643, "count": 3, "name": "Great Potion"},
    "7": {"clientId": 26748, "count": 1, "name": "Sun Stone"},
    "8": {"clientId": 38787, "count": 2, "name": "Rare Candy"},
    "9": {"clientId": 2160, "count": 1, "name": "Ten Thousand Dollar"},
    "10": {"clientId": 27641, "count": 2, "name": "Ultra Potion"},
    "11": {"clientId": 26731, "count": 2, "name": "Leaf Stone"},
    "12": {"clientId": 27645, "count": 3, "name": "Revive"},
    "13": {"clientId": 2152, "count": 10, "name": "Hundred Dollar"},
    "14": {"clientId": 26728, "count": 2, "name": "Fire Stone"},
    "15": {"clientId": 38787, "count": 3, "name": "Rare Candy"},
    "16": {"clientId": 26736, "count": 2, "name": "Water Stone"},
    "17": {"clientId": 2160, "count": 2, "name": "Ten Thousand Dollar"},
    "18": {"clientId": 27647, "count": 5, "name": "Hyper Potion"},
    "19": {"clientId": 26734, "count": 2, "name": "Thunder Stone"},
    "20": {"clientId": 38787, "count": 5, "name": "Rare Candy"},
    "21": {"clientId": 2160, "count": 10, "name": "Ten Thousand Dollar"}
  },
  "currentDay": 5,
  "canClaim": true,
  "nextClaim": 1710345600,
  "autoShow": false
}
```

## Campos da Resposta

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `rewards` | Object | Dicionário com as 21 recompensas (dia → item) |
| `currentDay` | Number | Dia atual do jogador (1-21) |
| `canClaim` | Boolean | Se o jogador pode coletar hoje |
| `nextClaim` | Number | Timestamp Unix da próxima recompensa disponível |
| `autoShow` | Boolean | Se deve mostrar a janela automaticamente |

## Estrutura de Recompensa

Cada recompensa deve ter:
```json
{
  "clientId": 26731,      // ID do item no cliente
  "count": 1,             // Quantidade
  "name": "Leaf Stone"    // Nome do item (para referência)
}
```

## Exemplo de Implementação (Lua - Servidor)

### Tabela de Dados

```lua
local DAILY_REWARDS_OPCODE = 2

local dailyRewards = {
    [1] = {clientId = 26731, count = 1, name = "Leaf Stone"},
    [2] = {clientId = 26728, count = 1, name = "Fire Stone"},
    [3] = {clientId = 26736, count = 1, name = "Water Stone"},
    [4] = {clientId = 26734, count = 1, name = "Thunder Stone"},
    [5] = {clientId = 2152, count = 5, name = "Hundred Dollar"},
    [6] = {clientId = 27643, count = 3, name = "Great Potion"},
    [7] = {clientId = 26748, count = 1, name = "Sun Stone"},
    [8] = {clientId = 38787, count = 2, name = "Rare Candy"},
    [9] = {clientId = 2160, count = 1, name = "Ten Thousand Dollar"},
    [10] = {clientId = 27641, count = 2, name = "Ultra Potion"},
    [11] = {clientId = 26731, count = 2, name = "Leaf Stone"},
    [12] = {clientId = 27645, count = 3, name = "Revive"},
    [13] = {clientId = 2152, count = 10, name = "Hundred Dollar"},
    [14] = {clientId = 26728, count = 2, name = "Fire Stone"},
    [15] = {clientId = 38787, count = 3, name = "Rare Candy"},
    [16] = {clientId = 26736, count = 2, name = "Water Stone"},
    [17] = {clientId = 2160, count = 2, name = "Ten Thousand Dollar"},
    [18] = {clientId = 27647, count = 5, name = "Hyper Potion"},
    [19] = {clientId = 26734, count = 2, name = "Thunder Stone"},
    [20] = {clientId = 38787, count = 5, name = "Rare Candy"},
    [21] = {clientId = 2160, count = 10, name = "Ten Thousand Dollar"}
}

-- Função para obter dados do jogador
function getDailyRewardsData(player)
    local playerData = player:getStorageValue("daily_rewards_data")
    local lastClaimTime = player:getStorageValue("daily_rewards_last_claim")
    
    if not playerData then
        playerData = {
            currentDay = 1,
            lastClaim = 0
        }
    end
    
    local now = os.time()
    local canClaim = false
    local nextClaim = 0
    
    -- Verificar se pode coletar hoje
    if lastClaimTime == 0 or (now - lastClaimTime) >= 86400 then
        canClaim = true
        nextClaim = now + 86400
    else
        nextClaim = lastClaimTime + 86400
    end
    
    return {
        rewards = dailyRewards,
        currentDay = playerData.currentDay,
        canClaim = canClaim,
        nextClaim = nextClaim,
        autoShow = false
    }
end

-- Função para coletar recompensa
function claimDailyReward(player)
    local data = getDailyRewardsData(player)
    
    if not data.canClaim then
        return false, "Você já coletou a recompensa de hoje!"
    end
    
    local reward = dailyRewards[data.currentDay]
    if not reward then
        return false, "Recompensa não encontrada!"
    end
    
    -- Adicionar item ao jogador
    local item = Game.createItem(reward.clientId, reward.count)
    if player:addItemEx(item) ~= RETURNVALUE_NOERROR then
        return false, "Seu inventário está cheio!"
    end
    
    -- Atualizar dados
    local newDay = data.currentDay + 1
    if newDay > 21 then
        newDay = 1  -- Reiniciar após 21 dias
    end
    
    player:setStorageValue("daily_rewards_data", {currentDay = newDay})
    player:setStorageValue("daily_rewards_last_claim", os.time())
    
    return true, "Recompensa coletada com sucesso!"
end

-- Handler do protocolo estendido
function onExtendedOpcode(player, opcode, buffer)
    if opcode ~= DAILY_REWARDS_OPCODE then
        return
    end
    
    local status, data = pcall(function() return json.decode(buffer) end)
    if not status then
        return
    end
    
    if data.action == "refresh" then
        local rewardsData = getDailyRewardsData(player)
        player:sendExtendedOpcode(DAILY_REWARDS_OPCODE, json.encode(rewardsData))
        
    elseif data.action == "claim" then
        local success, message = claimDailyReward(player)
        if success then
            local rewardsData = getDailyRewardsData(player)
            player:sendExtendedOpcode(DAILY_REWARDS_OPCODE, json.encode(rewardsData))
            player:sendTextMessage(MESSAGE_INFO_DESCR, message)
        else
            player:sendTextMessage(MESSAGE_ERROR, message)
        end
    end
end
```

## Integração com o Servidor

### 1. Registrar o Handler

```lua
-- Em um arquivo de inicialização do servidor
registerExtendedOpcodeHandler(2, onExtendedOpcode)
```

### 2. Banco de Dados (Alternativa)

Se preferir usar banco de dados em vez de storage:

```lua
function getDailyRewardsDataDB(player)
    local result = db.query("SELECT * FROM player_daily_rewards WHERE player_id = " .. player:getId())
    
    if not result then
        db.query("INSERT INTO player_daily_rewards (player_id, current_day, last_claim) VALUES (" .. player:getId() .. ", 1, 0)")
        return {
            currentDay = 1,
            lastClaim = 0
        }
    end
    
    return {
        currentDay = result[1].current_day,
        lastClaim = result[1].last_claim
    }
end
```

### 3. Criar Tabela no Banco

```sql
CREATE TABLE IF NOT EXISTS `player_daily_rewards` (
  `player_id` int(11) NOT NULL,
  `current_day` int(11) DEFAULT 1,
  `last_claim` int(11) DEFAULT 0,
  PRIMARY KEY (`player_id`),
  FOREIGN KEY (`player_id`) REFERENCES `players`(`id`) ON DELETE CASCADE
);
```

## Testes

### Teste de Refresh
```lua
-- No console do cliente
modules.game_daily_rewards.requestRewardsData()
```

### Teste de Claim
```lua
-- No console do cliente
modules.game_daily_rewards.claimReward()
```

## Notas Importantes

1. **Sincronização de Tempo**: Use `os.time()` para timestamps Unix
2. **Reset Diário**: O reset deve ocorrer a cada 24 horas (86400 segundos)
3. **Validação**: Sempre valide os dados no servidor antes de dar recompensas
4. **Segurança**: Nunca confie nos dados do cliente para determinar recompensas
5. **Limite de Dias**: O sistema suporta até 21 dias, mas pode ser expandido

## Troubleshooting

### Problema: Recompensa não aparece no inventário
- Verificar se o inventário tem espaço
- Verificar se o clientId do item é válido
- Verificar logs do servidor

### Problema: Timer não atualiza
- Verificar se o servidor está respondendo corretamente
- Verificar se o JSON está bem formatado
- Verificar console do cliente para erros

### Problema: Não consegue coletar recompensa
- Verificar se `canClaim` é true
- Verificar se o dia atual é válido (1-21)
- Verificar se o item existe no servidor

## Suporte

Para mais informações, consulte a documentação do OTClient e do servidor.
