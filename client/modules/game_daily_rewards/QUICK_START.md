# Quick Start - Daily Rewards Module

## 🚀 Início Rápido

### 1. Verificar Instalação

O módulo já está instalado em:
```
CLIENT/OTCLIENT NORDEMON/modules/game_daily_rewards/
```

### 2. Verificar Imagens

As imagens foram copiadas da PSTORY para:
```
CLIENT/OTCLIENT NORDEMON/modules/game_daily_rewards/images/
```

Imagens incluídas:
- ✅ banner.png
- ✅ corki.png
- ✅ gift.png
- ✅ sonia.png

### 3. Abrir a Janela

**Via Console do Cliente:**
```lua
modules.game_daily_rewards.show()
```

**Via Botão (Descomente no código):**
Edite `game_daily_rewards.lua` linha 27:
```lua
buttonRewards = modules.client_topmenu.addRightGameToggleButton("dailyRewards", tr("Daily Rewards"), "/images/topbuttons/gift", toggleWindow, true)
```

### 4. Testar Funcionalidades

```lua
-- Abrir janela
modules.game_daily_rewards.show()

-- Fechar janela
modules.game_daily_rewards.hide()

-- Coletar recompensa
modules.game_daily_rewards.claimReward()

-- Atualizar dados
modules.game_daily_rewards.requestRewardsData()
```

---

## 📋 Checklist de Configuração

### Cliente
- [x] Módulo instalado
- [x] Imagens copiadas
- [x] Arquivo Lua compilado
- [x] Interface carregada
- [ ] Botão adicionado ao menu (opcional)

### Servidor
- [ ] Handler do protocolo registrado
- [ ] Banco de dados configurado
- [ ] Recompensas definidas
- [ ] Testes realizados

---

## 🔌 Integração com Servidor

### Passo 1: Registrar Handler

Adicione ao seu servidor (em um arquivo de inicialização):

```lua
local DAILY_REWARDS_OPCODE = 2

function onExtendedOpcode(player, opcode, buffer)
    if opcode ~= DAILY_REWARDS_OPCODE then
        return
    end
    
    local status, data = pcall(function() return json.decode(buffer) end)
    if not status then return end
    
    if data.action == "refresh" then
        -- Enviar dados de recompensas
        local response = {
            rewards = dailyRewards,
            currentDay = 5,
            canClaim = true,
            nextClaim = os.time() + 86400,
            autoShow = false
        }
        player:sendExtendedOpcode(DAILY_REWARDS_OPCODE, json.encode(response))
    end
end

registerExtendedOpcodeHandler(2, onExtendedOpcode)
```

### Passo 2: Definir Recompensas

```lua
local dailyRewards = {
    [1] = {clientId = 26731, count = 1, name = "Leaf Stone"},
    [2] = {clientId = 26728, count = 1, name = "Fire Stone"},
    -- ... adicione as 21 recompensas
}
```

### Passo 3: Testar

1. Iniciar servidor
2. Conectar cliente
3. Abrir console do cliente
4. Executar: `modules.game_daily_rewards.requestRewardsData()`
5. Verificar se dados são recebidos

---

## 🎨 Customização Rápida

### Mudar Cores

Edite `game_daily_rewards.lua` na função `updateRewardsDisplay()`:

```lua
-- Dia coletado (verde)
widget:setBackgroundColor('#0a2a0a')
widget:setBorderColor('#00aa00')

-- Dia atual (amarelo)
widget:setBackgroundColor('#2a2a00')
widget:setBorderColor('#ffcc00')

-- Dia futuro (cinza)
widget:setBackgroundColor('#0f0f0f')
widget:setBorderColor('#2a2a2a')
```

### Mudar Tamanho da Janela

Edite `game_daily_rewards.otui`:

```
MainWindow
  id: dailyRewardsWindow
  size: 600 480  # Altere aqui
```

### Mudar Número de Dias

Edite `game_daily_rewards.lua` na função `createRewardWidgets()`:

```lua
for dayIndex = 1, 30 do  # Mude de 21 para 30
```

---

## 🐛 Troubleshooting Rápido

### Problema: Janela não abre
```lua
-- Verificar se módulo está carregado
print(modules.game_daily_rewards)

-- Verificar se mainWindow existe
print(modules.game_daily_rewards.mainWindow)
```

### Problema: Imagens não aparecem
```lua
-- Verificar se arquivo existe
-- Verificar caminho em game_daily_rewards.otui
-- Verificar permissões de arquivo
```

### Problema: Servidor não responde
```lua
-- Verificar se handler está registrado
-- Verificar se opcode está correto (2)
-- Verificar logs do servidor
```

### Problema: Recompensa não aparece
```lua
-- Verificar se inventário tem espaço
-- Verificar se clientId é válido
-- Verificar se servidor está enviando dados corretos
```

---

## 📚 Documentação Completa

Para mais informações, consulte:

- **README.md** - Visão geral do módulo
- **SERVER_INTEGRATION.md** - Guia de integração com servidor
- **USAGE_EXAMPLES.md** - Exemplos práticos
- **CHANGELOG.md** - Histórico de versões
- **styles.otui** - Estilos customizáveis

---

## 🎯 Próximos Passos

1. ✅ Verificar instalação
2. ✅ Testar no cliente
3. ⏳ Implementar no servidor
4. ⏳ Configurar recompensas
5. ⏳ Testar integração completa
6. ⏳ Deploy em produção

---

## 💡 Dicas

- Use o console do cliente para testar funções
- Verifique os logs do servidor para erros
- Faça backup antes de fazer mudanças
- Teste em ambiente de desenvolvimento primeiro
- Leia a documentação completa para customizações avançadas

---

## 📞 Suporte

- Website: https://nordemon.online
- Forum: https://nordemon.online/forum
- Discord: https://discord.gg/nordemon

---

**Versão:** 1.1.0  
**Data:** 13/03/2026  
**Status:** ✅ Pronto para uso
