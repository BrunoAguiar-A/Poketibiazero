# Como Editar os Itens de Recompensas

## 📍 Localização do Arquivo

Arquivo: `CLIENT/OTCLIENT NORDEMON/modules/game_daily_rewards/game_daily_rewards.lua`

Linhas: 18 a 42

## 📝 Estrutura de Cada Item

```lua
[DIA] = {clientId = ID_DO_ITEM, count = QUANTIDADE, name = "NOME_DO_ITEM"},
```

**Componentes:**
- `[DIA]` - Número do dia (1 a 21)
- `clientId` - ID do item no cliente
- `count` - Quantidade do item
- `name` - Nome do item (para referência)

## 🔍 Exemplo Atual

```lua
local rewardsData = {
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
```

## ✏️ Como Editar

### Passo 1: Abrir o Arquivo
1. Abra: `CLIENT/OTCLIENT NORDEMON/modules/game_daily_rewards/game_daily_rewards.lua`
2. Procure por: `local rewardsData = {`
3. Você verá a tabela com 21 itens

### Passo 2: Editar um Item
Exemplo - Mudar o Dia 1:

**Antes:**
```lua
[1] = {clientId = 26731, count = 1, name = "Leaf Stone"},
```

**Depois (exemplo):**
```lua
[1] = {clientId = 12345, count = 2, name = "Poção Vermelha"},
```

### Passo 3: Salvar
1. Salve o arquivo (Ctrl+S)
2. Reinicie o cliente
3. Abra a janela de Daily Rewards
4. Verifique se o item mudou

## 🎯 Exemplos de Edição

### Exemplo 1: Aumentar Quantidade
```lua
-- Antes
[5] = {clientId = 2152, count = 5, name = "Hundred Dollar"},

-- Depois (aumentar para 10)
[5] = {clientId = 2152, count = 10, name = "Hundred Dollar"},
```

### Exemplo 2: Mudar Item
```lua
-- Antes
[7] = {clientId = 26748, count = 1, name = "Sun Stone"},

-- Depois (mudar para outro item)
[7] = {clientId = 99999, count = 1, name = "Meu Item Especial"},
```

### Exemplo 3: Mudar Tudo
```lua
-- Antes
[10] = {clientId = 27641, count = 2, name = "Ultra Potion"},

-- Depois
[10] = {clientId = 54321, count = 5, name = "Poção Rara"},
```

## 🔑 IDs de Itens Comuns

Aqui estão alguns IDs de itens que você pode usar:

| ID | Nome | Uso |
|----|------|-----|
| 2152 | Hundred Dollar | Dinheiro |
| 2160 | Ten Thousand Dollar | Dinheiro grande |
| 26731 | Leaf Stone | Pedra de evolução |
| 26728 | Fire Stone | Pedra de evolução |
| 26736 | Water Stone | Pedra de evolução |
| 26734 | Thunder Stone | Pedra de evolução |
| 26748 | Sun Stone | Pedra de evolução |
| 27641 | Ultra Potion | Poção |
| 27643 | Great Potion | Poção |
| 27645 | Revive | Reviver |
| 27647 | Hyper Potion | Poção |
| 38787 | Rare Candy | Doce raro |

**Para encontrar mais IDs:**
1. Procure no banco de dados do servidor
2. Procure em arquivos de configuração
3. Use comandos do jogo (se disponível)

## 📋 Checklist de Edição

- [ ] Abri o arquivo `game_daily_rewards.lua`
- [ ] Encontrei a tabela `rewardsData`
- [ ] Editei os itens que queria
- [ ] Salvei o arquivo
- [ ] Reiniciei o cliente
- [ ] Testei a janela de Daily Rewards
- [ ] Verifiquei se os itens mudaram

## ⚠️ Cuidados

1. **Não remova linhas** - Deve haver exatamente 21 itens
2. **Não mude o formato** - Mantenha a estrutura `{clientId = X, count = Y, name = "Z"}`
3. **Use vírgulas** - Cada linha deve terminar com vírgula (exceto a última)
4. **Salve o arquivo** - Não esqueça de salvar após editar
5. **Reinicie o cliente** - As mudanças só aparecem após reiniciar

## 🔧 Troubleshooting

### Problema: Itens não mudaram
**Solução:**
1. Verifique se salvou o arquivo
2. Reinicie o cliente completamente
3. Verifique se editou o arquivo correto

### Problema: Erro ao abrir a janela
**Solução:**
1. Verifique se há erros de sintaxe
2. Verifique se todas as linhas têm vírgula
3. Verifique se não removeu nenhuma linha

### Problema: Item não aparece
**Solução:**
1. Verifique se o `clientId` é válido
2. Verifique se o item existe no servidor
3. Tente usar um ID diferente

## 📞 Suporte

Se tiver dúvidas:
1. Leia: `SERVER_INTEGRATION.md` (para integração com servidor)
2. Leia: `USAGE_EXAMPLES.md` (para exemplos)
3. Visite: https://nordemon.online/forum

## ✅ Pronto!

Agora você sabe como editar os itens de recompensas!

Próximo passo: Integrar com o servidor (veja `SERVER_INTEGRATION.md`)
