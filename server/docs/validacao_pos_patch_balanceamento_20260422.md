# Validacao Pos-Patch do Balanceamento - 2026-04-22

## Objetivo

Validar no runtime real se o patch estrutural de tuning resolveu a sensacao de:

- pokemons fortes demais;
- TTK curto demais;
- melee alto demais;
- especiais/STAB explodindo demais.

Tambem fechar se o problema dominante era:

- formula;
- tuning;
- base stats;
- speed/mobilidade/uptime.

## Correcoes Relevantes em Producao

1. `monsterhealthchange.lua`
   - curva defensiva fortalecida;
   - multiplicador ofensivo comprimido.
2. `src/game.cpp`
   - STAB reduzido de `+50%` para `+35%`.
3. `data/events/scripts/monster.lua`
   - spawns artificiais deixaram de ter level sobrescrito por randomizacao no `onSpawn`.
4. `data/talkactions/scripts/place_monster.lua`
   - `/m` passou a aceitar `level=`.

## Comparativo Runtime Real

### Charizard 100

| Cenario | Antes | Depois | Variacao |
| --- | ---: | ---: | ---: |
| melee vs Venusaur 50 | 1430 | 640 | -55.2% |
| Flamethrower vs Venusaur 50 | >6000 | 2665 | <= -55.6% |
| melee vs Snorlax 64 | 756 | 346 | -54.2% |
| Flamethrower vs Snorlax 64 | 3045 | 1357 | -55.4% |
| Flamethrower vs Onix 33 | 1693 | 789 | -53.4% |

Leitura:

- o burst principal do Charizard caiu pela metade ou mais;
- o dano em neutro, favoravel e resistido ficou bem menos explosivo;
- o TTK subiu de forma perceptivel.

### Snorlax 100

| Cenario | Antes | Depois | Variacao |
| --- | ---: | ---: | ---: |
| melee vs Venusaur 50/57 | 989 | 627 | -36.6% |
| melee vs Charmeleon 16 | 1119 | 728 | -34.9% |

Leitura:

- Snorlax ainda bate forte;
- mas saiu do patamar claramente exagerado;
- contra alvo fragil continua forte, porem nao mais fora de controle.

### Charmeleon 60

| Cenario | Antes | Depois | Variacao |
| --- | ---: | ---: | ---: |
| melee vs Venusaur 50 | 674 | 491 | -27.2% |

Leitura:

- species intermediaria manteve identidade ofensiva;
- a queda foi menor que a do Charizard, o que faz sentido porque o hot path mais abusivo estava nos extremos de burst.

## Evidencia Qualitativa do Runtime

Relato pos-patch:

- `Charizard melee vs Venusaur 50`: "pareceu aceitavel", meia vida em ~20 hits.
- `Charizard Flamethrower vs Venusaur 50`: "pareceu aceitavel", meia vida em ~4 hits.
- `Charizard melee vs Snorlax 64`: "pareceu aceitavel".
- `Charizard Flamethrower vs Snorlax 64`: "pareceu aceitavel".
- `Charizard Flamethrower vs Onix 33`: "pareceu aceitavel".
- `Snorlax melee vs Venusaur 50`: "pareceu aceitavel".
- `Snorlax melee vs Charmeleon 16`: "alto aceitavel", kill em ~8 hits.
- `Charmeleon melee vs Venusaur 50`: "pareceu aceitavel".

## Veredito Fechado

### 1. Formula

Nao havia um bug estrutural novo na formula principal de dano causando o overtuning atual.

O bug estrutural real encontrado nesta etapa foi operacional:

- runtime antigo sendo executado;
- e depois um bug de spawn artificial:
  - `Monster:onSpawn` sobrescrevia o `level=` de `/m`.

Depois dessas correcoes, a formula final respondeu como esperado ao tuning.

Conclusao:

- `formula` nao era a causa dominante da sensacao de "forte demais";
- os problemas estruturais reais desta rodada foram de fluxo/runtime, nao de matematica principal.

### 2. Tuning

Foi a causa dominante.

A prova e o comparativo antes/depois:

- queda de ~53% a ~56% nos cenarios mais abusivos do Charizard;
- queda de ~35% no Snorlax;
- melhora perceptivel de TTK e survivability no runtime real.

Conclusao:

- o que fazia o jogo parecer forte demais era principalmente `tuning ofensivo alto + mitigacao defensiva fraca + STAB excessivo`.

### 3. Base Stats

Ha indicio residual, mas nao dominante.

Sinais:

- `Snorlax` ainda permanece no topo do melee mesmo apos o patch;
- `Charizard` continua sendo um atacante muito acima da media, como esperado;
- `Charmeleon` nao mostrou distorcao fora do aceitavel no pos-patch.

Conclusao:

- `base stats` podem merecer ajustes finos por especie depois;
- mas nao eram a causa principal da sensacao global de desbalanceamento.

### 4. DEF / HP / TTK

Eram parte central do problema junto do tuning.

Depois do patch:

- alvos passaram a segurar melhor;
- TTK subiu;
- dano em resistido e neutro deixou de explodir.

Conclusao:

- `DEF/HP` estavam contribuindo diretamente para a sensacao de overtuning;
- o patch melhorou isso de forma relevante.

### 5. Speed / Mobilidade / Uptime

Nao apareceu como causa dominante nesta bateria.

Os testes que fecharam o problema foram de dano e TTK, e eles ja explicam a maior parte da sensacao relatada antes.

Conclusao:

- com a evidencia atual, `speed` nao e a origem principal do "forte demais";
- se ainda houver sensacao de "rapido demais", isso deve ser tratado como eixo separado de mobilidade/pressao, nao como causa primaria do overtuning de dano.

## Diagnostico Final Consolidado

A sensacao de que os pokemons estavam fortes demais no runtime real vinha principalmente da combinacao de:

1. `tuning ofensivo agressivo demais`;
2. `mitigacao defensiva insuficiente`;
3. `STAB` forte demais;
4. `TTK` curto demais como consequencia direta dos tres pontos acima.

Nao foi confirmado:

- colapso atual de progressao por level como causa dominante desta fase;
- bug principal de formula de dano;
- speed como motor principal do problema;
- base stats como causa principal global.

## Estado Atual

Estado atual apos patch:

- problema principal de "forte demais" ficou majoritariamente resolvido;
- sobram, no maximo, ajustes finos por especie/top offenders;
- principal candidato residual para tuning fino: `Snorlax melee`.
