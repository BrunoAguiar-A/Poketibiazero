# Debug - Daily Rewards Module

## Verificação de Carregamento

Se o módulo não está abrindo, siga estes passos:

### 1. Verificar se o módulo foi carregado

Abra o console do cliente e execute:

```lua
print(modules.game_daily_rewards)
```

Se retornar `nil`, o módulo não foi carregado.

### 2. Verificar se a janela foi criada

```lua
print(modules.game_daily_rewards.mainWindow)
```

Se retornar `nil`, a janela não foi criada.

### 3. Verificar se o botão foi criado

```lua
print(modules.game_daily_rewards.buttonRewards)
```

Se retornar `nil`, o botão não foi criado.

### 4. Tentar abrir manualmente

```lua
modules.game_daily_rewards.show()
```

Se funcionar, o problema é com o botão.

### 5. Verificar logs

Procure por mensagens de erro no console:
- "ERRO: Falha ao carregar game_daily_rewards.otui"
- "ERROR: failed to load UI"
- "ERROR: unable to create widget"

### 6. Verificar dependências

Certifique-se de que estes módulos estão carregados:
- `modules.game_interface` - Para carregar UI
- `modules.client_topmenu` - Para adicionar botão

```lua
print(modules.game_interface)
print(modules.client_topmenu)
```

## Possíveis Problemas

### Problema: Módulo não carrega
**Solução:** Verifique se o arquivo `game_daily_rewards.otui` está correto

### Problema: Janela não abre
**Solução:** Verifique se `mainWindow` é nil

### Problema: Botão não aparece
**Solução:** Verifique se `buttonRewards` é nil

### Problema: Ícone não aparece
**Solução:** Verifique se o arquivo `/data/images/topbuttons/daily_rewards.png` existe

## Teste Rápido

Execute no console:

```lua
-- Verificar módulo
if modules.game_daily_rewards then
    print("✓ Módulo carregado")
    
    -- Verificar janela
    if modules.game_daily_rewards.mainWindow then
        print("✓ Janela criada")
        
        -- Abrir janela
        modules.game_daily_rewards.show()
        print("✓ Janela aberta")
    else
        print("✗ Janela não criada")
    end
    
    -- Verificar botão
    if modules.game_daily_rewards.buttonRewards then
        print("✓ Botão criado")
    else
        print("✗ Botão não criado")
    end
else
    print("✗ Módulo não carregado")
end
```

## Solução Alternativa

Se o botão não aparecer, você pode abrir a janela manualmente:

1. Abra o console do cliente
2. Execute: `modules.game_daily_rewards.show()`
3. A janela deve abrir

## Contato

Se o problema persistir, verifique:
- Se todos os arquivos estão presentes
- Se não há erros de sintaxe no Lua
- Se as dependências estão carregadas
- Se o cliente foi reiniciado após as mudanças
