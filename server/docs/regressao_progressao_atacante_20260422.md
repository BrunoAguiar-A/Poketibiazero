# Regressao Aparente da Progressao do Atacante - Causa Exata

Data: 2026-04-22
Repo: `/root/SERVER`

## Veredito Objetivo

- Nao houve rollback literal da correcao no fonte.
- Houve execucao do binario errado no runtime real.
- O servidor estava subindo `./tfs` antigo, compilado em `2026-04-20 19:14`.
- O estado corrigido estava em `build/tfs`, compilado em `2026-04-21 23:16`.
- Portanto, a "regressao" foi causada por `drift de executavel`, nao por reversao de codigo em `src/game.cpp`.

## Causa Exata

O runtime real estava executando um binario antigo:

- `tfs` antigo:
  - timestamp anterior: `2026-04-20 19:14:08`
  - hash anterior: `443a742b4f1f3ec1b4305533b7106558`
- `build/tfs` corrigido:
  - timestamp: `2026-04-21 23:16:09`
  - hash: `32af7d34942d7d70947ef8ec471e5beb`

As correcoes do dia `2026-04-21` estavam presentes no fonte e no binario de `build/`, mas o servidor real seguia usando o executavel antigo do root.

## Diferenca Concreta Entre Ontem e Hoje

### Estado corrigido no fonte

O fonte atual ainda contem a protecao contra sobrescrita no segundo passe pos-Lua:

- [src/game.cpp](/root/SERVER/src/game.cpp:4431)

Trecho relevante:

- `damage.traceOriginalOrigin = damage.origin`
- `isPostLuaHealthChangePass = damage.origin == ORIGIN_NONE && damage.traceOriginalOrigin != ORIGIN_NONE`
- o recompute do bruto so roda quando `!isPostLuaHealthChangePass`

Isso prova que a correcao estrutural nao foi removida do codigo atual.

### Estado efetivamente executado no runtime

Os scripts de subida estavam apontando para `./tfs`, nao para `./build/tfs`:

- [start.sh](/root/SERVER/start.sh:27) antes usava `./tfs`
- [start_protected.sh](/root/SERVER/start_protected.sh:32) antes usava `./tfs`

Como `./tfs` estava defasado, o runtime real subiu um executavel anterior a parte das correcoes.

## Evidencia Forte do Runtime Real

Os numeros relatados pelo jogador batem exatamente com o valor bruto pre-Lua, nao com o dano final corrigido.

Exemplos do log de `2026-04-22`:

### Charizard 100 vs Charmeleon

Linha do log:

- `08:32:33`
- `rawPrimaryDamageInput=700`
- `finalAppliedDamage=1446`

O jogador reportou:

- `Flamethrower ... contra Charmeleon = 700`

Ou seja:

- o valor percebido no jogo estava refletindo o bruto pre-Lua do runtime antigo.

### Charizard 100 vs Venusaur

Linha do log:

- `08:33:04`
- `rawPrimaryDamageInput=2800`
- `finalAppliedDamage=5030`

O jogador reportou:

- `Flamethrower ... contra Venusaur = 2800`

Novamente:

- o numero observado bate com o bruto pre-Lua, nao com o dano final pos-correcoes.

### Charizard 100 melee

Linha do log:

- `08:33:03`
- `rawPrimaryDamageInput=420`
- `finalAppliedDamage=780`

O jogador reportou:

- `melee ... = 420`

Mesmo padrao:

- o runtime exposto ao jogador estava mostrando o valor cru, nao o resultado final escalado.

## Ponto Que Matou a Progressao "Percebida"

O problema nao foi a progressao real do atacante sumir do fonte.

O que matou a progressao percebida foi:

1. o servidor subiu o binario antigo `./tfs`;
2. esse binario antigo nao era o executavel que continha a cadeia final corrigida do dano;
3. o numero visto pelo jogador voltou a refletir o bruto pre-Lua, que naturalmente tende a colapsar por level em varios cenarios;
4. por isso `Charizard 70` e `Charizard 100` pareciam iguais no gameplay visual, embora o fonte corrigido atual continue preservando a progressao pos-Lua.

## Prova de Que a Progressao Corrigida Continua no Estado Certo

No proprio log atual existe contraste entre `lv 100` e `lv 70` quando o dano final corrigido entra:

### Mesmo alvo Snorlax, melee

Charizard 100:

- `08:37:15`
- `rawPrimaryDamageInput=420`
- `finalAppliedDamage=862`

Charizard 70:

- `08:37:52`
- `rawPrimaryDamageInput=420`
- `finalAppliedDamage=614`

Leitura:

- o bruto cru continua igual;
- a progressao real reaparece no dano final;
- isso e exatamente o comportamento esperado do pipeline corrigido.

### Mesmo alvo Snorlax, especial

Charizard 70:

- `08:38:55`
- `rawPrimaryDamageInput=1400`
- `finalAppliedDamage=1915`

A leitura estrutural permanece a mesma:

- o valor cru nao representa sozinho a progressao;
- o dano final escalado depende do multiplicador dinamico do atacante;
- o colapso observado no jogo era compatível com runtime antigo expondo o valor cru.

## Diff Logico do Problema

### Ontem / estado corrigido

- fonte com protecao de segundo passe em `src/game.cpp`
- binario novo gerado em `build/tfs`
- fluxo corrigido preservando o ajuste pos-Lua

### Hoje / estado executado

- scripts e execucao manual usando `./tfs`
- `./tfs` antigo e anterior ao estado corrigido
- runtime real divergente do fonte atual

Conclusao:

- nao houve rollback do codigo;
- houve `rollback de executavel em runtime`.

## Correcao Aplicada

### 1. Scripts de subida corrigidos

Arquivos alterados:

- [start.sh](/root/SERVER/start.sh:10)
- [start_protected.sh](/root/SERVER/start_protected.sh:9)

Patch logico:

- ambos agora preferem `./build/tfs` quando ele existir;
- so caem para `./tfs` como fallback.

### 2. Binario do root sincronizado

Foi feita a sincronizacao:

- `cp build/tfs tfs`

Estado final:

- `tfs` e `build/tfs` agora tem o mesmo hash:
  - `32af7d34942d7d70947ef8ec471e5beb`

### 3. Runtime reiniciado no binario correto

Depois da sincronizacao, o servidor foi iniciado novamente.

Evidencia:

- o processo atual passou a anunciar compilacao em `Apr 21 2026 23:00:38`
- antes ele rodava o build de `Apr 20 2026`

## Validacao Esperada Apos Patch

Apos subir no executavel correto:

1. `Charizard 70` e `Charizard 100` nao devem mais parecer iguais quando o dano final e o HP real forem observados.
2. o valor exibido e o efeito na barra de HP devem voltar a ficar coerentes com a progressao.
3. o runtime deve ficar alinhado com o estado corrigido do fonte em `src/game.cpp`.

## Arquivos Alterados Nesta Correcao

- `start.sh`
- `start_protected.sh`
- `tfs` sincronizado com `build/tfs`

## Conclusao Final

Diagnostico fechado:

- `houve rollback?`
  - Nao no fonte.
- `houve sobrescrita parcial?`
  - No estado executado pelo binario antigo, sim, o runtime efetivo voltou a se comportar como pre-correcao.
- `qual arquivo/trecho matou novamente a progressao?`
  - O problema operacional estava na rota de execucao dos scripts:
    - [start.sh](/root/SERVER/start.sh:27)
    - [start_protected.sh](/root/SERVER/start_protected.sh:32)
  - ambos chamavam o binario antigo `./tfs`.
- `qual a diferenca concreta entre ontem e agora?`
  - Ontem: binario corrigido em `build/tfs`.
  - Hoje: runtime usando `./tfs` antigo, anterior a esse estado.

O problema real foi `desalinhamento entre fonte corrigido e executavel rodando em producao local`.
