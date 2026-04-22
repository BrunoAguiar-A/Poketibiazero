# Auditoria Completa do Balanceamento Pos-Patch - Fase 2

## Resumo executivo

Estado atual do meta:

- O problema central anterior de `burst bruto excessivo + mitigacao fraca + TTK curto` foi majoritariamente resolvido.
- O runtime atual esta mais saudavel em dano, defesa e sobrevivencia nos cenarios neutros e nos hot paths que estavam quebrados.
- Nao foi encontrado um novo bug dominante de formula de dano no gameplay real.
- A progressao de level voltou a funcionar de forma consistente no mid/late game.
- O maior risco estrutural remanescente hoje nao e dano bruto: e `speed/mobilidade/uptime`.

Veredito curto:

- `dano / mitigacao / TTK`: saudavel o suficiente para sair de emergencia, mas nao completamente estabilizado.
- `progressao`: consistente no que foi medido, sem novo achatamento estrutural de dano.
- `outliers`: ainda existem, mas agora o problema e mais de `microtuning e sistemas laterais` do que de formula principal.
- `maior inconsistencia estrutural atual`: formula de `speed` misturando base legada e escala GBA.

Riscos remanescentes de maior prioridade:

1. `speed` estruturalmente descalibrado em parte do roster.
2. `stack` de modificadores high-end ainda nao auditado a fundo:
   - boost
   - held boost
   - held attack
   - starFusion
   - maestria
   - pokeCard
   - guild buffs
   - shiny multiplier
3. `Snorlax melee` ainda e o microtuning mais suspeito entre os testes reais.
4. Algumas especies bulky/all-rounder parecem `rapidas demais` para o papel, com destaque para Venusaur.
5. O subsistema de auditoria automatica ainda esta com formulas esperadas desatualizadas, entao os `observed` dos logs sao confiaveis, mas os `expected/validation` nao sao fonte de verdade hoje.

## Estado atual geral do meta

### O jogo hoje esta saudavel em termos de dano, mitigacao e TTK?

Resposta:

- `parcialmente sim`.

Confirmado:

- os testes reais pos-patch mostram queda de ~53% a ~56% nos cenarios mais abusivos do Charizard;
- Snorlax caiu ~35% nos cenarios testados;
- o usuario passou a classificar a maior parte dos cenarios criticos como `aceitavel`;
- resistencias, neutros e favoraveis voltaram a se comportar de forma menos explosiva;
- o TTK subiu de forma perceptivel.

Conclusao:

- o meta saiu do estado de overtuning estrutural grave;
- mas ainda nao da para chamar de `100% saudavel` por causa de speed, stacks high-end e alguns outliers de especie.

### O problema central anterior foi resolvido ou apenas amortecido?

Resposta:

- `majoritariamente resolvido no eixo de dano bruto`.

O que foi confirmado no runtime real:

- `Charizard melee vs Venusaur 50`: `1430 -> 640`
- `Charizard Flamethrower vs Venusaur 50`: `>6000 -> 2665`
- `Charizard melee vs Snorlax 64`: `756 -> 346`
- `Charizard Flamethrower vs Snorlax 64`: `3045 -> 1357`
- `Charizard Flamethrower vs Onix 33`: `1693 -> 789`
- `Snorlax melee vs Venusaur`: `989 -> 627`
- `Snorlax melee vs Charmeleon 16`: `1119 -> 728`

Leitura:

- isso nao e so amortecimento visual;
- houve correcao real do dano aplicado e do TTK percebido.

## O que melhorou desde a auditoria anterior

1. A dupla `STAB + scaling ofensivo + pouca mitigacao` deixou de explodir o jogo.
2. A progressao do atacante voltou a chegar no dano final.
3. O runtime passou a rodar no binario correto.
4. O `/m` passou a aceitar `level=` e o `onSpawn` parou de sobrescrever level artificial.
5. O dano final percebido passou a ficar coerente com a barra de HP e com o runtime real.

## O que ainda preocupa

1. `speed` continua estruturalmente suspeito.
2. HP e speed ainda usam bases legadas no pipeline, ao contrario de atk/def/spatk/spdef, que estao bem mais GBA-driven.
3. O meta high-end com stacks reais de jogador ainda nao foi fechado:
   - held boost
   - held attack
   - defense/vitality/haste
   - cards
   - star fusion
   - maestria
   - shiny
   - guild buffs
4. `Snorlax melee` segue como principal suspeito de microtuning.
5. O subsistema de auditoria automatica ainda calcula expectativa com formula antiga, o que reduz a confiabilidade dos `expected/validation`.

## Fonte de verdade por subsistema

Fonte de verdade principal desta auditoria:

- `src/game.cpp`
- `data/creaturescripts/scripts/monsterhealthchange.lua`
- `data/lib/pokemon/level_system.lua`
- `data/lib/core/newfunctions.lua`
- `data/events/scripts/monster.lua`
- `data/logs/manual_runtime_live_trace.log`
- `data/logs/auditoria/balance_audit_runtime_20260422_093158.log`
- testes reais pos-patch consolidados em `docs/validacao_pos_patch_balanceamento_20260422.md`

Observacao importante:

- os docs antigos sao contexto historico;
- nao sao fonte de verdade absoluta.

Observacao importante sobre os logs de auditoria:

- os campos `observed*` continuam uteis;
- os campos `expected*` e `validation` do script de auditoria estao defasados porque o arquivo ainda usa:
  - `STAB_MULTIPLIER = 1.5`
  - curva antiga de reducao (`def/(def+180)*60`, cap `85`)
  - multiplicador ofensivo sem o blend de `0.58`

Conclusao:

- para esta auditoria, os `observed` dos logs sao validos;
- os `expected` do script de auditoria devem ser tratados como referencia historica, nao como verdade atual do runtime.

## Progressao por level

### Mid/Late game

Confirmado no log de auditoria atual:

- `Charizard wild 70 -> 100`
  - `totalMeleeAttack`: `122 -> 173` (`+41.8%`)
  - `totalMagicAttack`: `157 -> 223` (`+42.0%`)
  - `totalHealth`: `16600 -> 23363` (`+40.7%`)
  - `totalPhysicalDefense`: `68 -> 97` (`+42.6%`)
  - `totalSpecialDefense`: `74 -> 105` (`+41.9%`)
  - `totalSpeed`: `193 -> 273` (`+41.5%`)

- `Charizard summon 70 -> 100`
  - `totalMeleeAttack`: `136 -> 191` (`+40.4%`)
  - `totalMagicAttack`: `175 -> 247` (`+41.1%`)
  - `totalHealth`: `17742 -> 24944` (`+40.6%`)
  - `totalPhysicalDefense`: `76.18 -> 107.63` (`+41.3%`)
  - `totalSpecialDefense`: `82.59 -> 116.35` (`+40.9%`)
  - `totalSpeed`: `214.67 -> 302.67` (`+41.0%`)

Leitura:

- nao ha achatamento de progressao no mid/late game nos cenarios auditados;
- ataque basico, especial, bulk e speed sobem de forma coerente;
- a correccao da progressao de dano esta viva no runtime atual.

### Early game

Confirmado:

- nao apareceu evidencia de novo colapso em dano early;
- mas `speed early` esta suspeito.

Evidencia:

- `Charmander pokeLevel=5`, `effectiveLevel=12`, `currentStats.speed=22`, `totalSpeed=360`
- no snapshot wild de auditoria, `Charmander level=100` chegou a `totalSpeed=2209`

Leitura:

- a progressao ofensiva/defensiva early nao foi provada como quebrada nesta fase;
- a progressao de `speed` early tem forte indicio de distorcao estrutural.

### Ha faixa quebrada?

Conclusao atual:

- `early`: suspeita relevante em `speed/mobilidade`
- `mid`: sem evidencia de quebra estrutural em dano/bulk
- `late`: sem evidencia de achatamento; outliers agora parecem ser de especie e stack, nao de progressao base

## Peso real de cada variavel

## Level

Peso real hoje:

- `alto`

Motivo:

- entra no calculo dos `currentStats` via formula GBA;
- afeta ataque, defesa, HP e speed;
- os snapshots 70 -> 100 mostram impacto de ~40% em quase todos os eixos.

## EffectiveLevel

Peso real hoje:

- `dominante`

Motivo:

- `effectiveLevel = level + boost + heldBoostCap + BL`
- ele e o verdadeiro nivel usado para gerar os stats finais da pokeball.

Conclusao:

- `effectiveLevel` pesa mais que o `level nominal` exibido.

## Base stats

Peso real hoje:

- `alto` em `atk/def/spatk/spdef`
- `medio` em `hp`
- `baixo a medio` em `speed`, porque speed esta contaminado por base legada

Motivo:

- atk/def/spatk/spdef usam species base stats GBA como base principal;
- HP usa `maxHealth` legado como `combatBaseStats.hp`;
- speed usa `getBaseSpeed()` legado como `combatBaseStats.speed`.

Conclusao:

- base stats estao bem representados em ofensiva/defesa;
- HP e speed ainda sao parcialmente dominados pela camada legacy.

## Boost

Peso real hoje:

- `muito alto`

Motivo:

- cada ponto de boost soma diretamente no `effectiveLevel`;
- o sistema aceita boost muito acima de `0-10`;
- held boost ainda adiciona niveis efetivos extras.

Conclusao:

- boost e uma das alavancas mais fortes do jogo hoje.

## BL

Peso real hoje:

- `alto`

Motivo:

- BL soma diretamente no `effectiveLevel`;
- em summons controlados, mesmo `BL=1` ja cria diferenca real contra o wild de mesmo level nominal.

Conclusao:

- BL nao e cosmetico;
- ele altera poder real de combate.

## IV

Peso real hoje:

- `medio`

Motivo:

- IV vai de `0%` ate `+20%` sobre o base stat antes da formula final;
- altera todos os stats, inclusive HP e speed.

Conclusao:

- IV pesa, mas muito menos que `boost + BL + level`.

## Nature

Peso real hoje:

- `baixo`

Motivo:

- impacta so `+5% / -5%` em stats nao-HP.

Conclusao:

- nature hoje e um ajuste fino;
- sozinha nao muda matchup de forma estrutural.

## Helds

Peso real hoje:

- `alto`, dependendo do tipo

Resumo dos helds relevantes:

- `boost`: adiciona ate `+30 effective levels` apos soft cap
- `attack`: efetivamente pode empurrar ate `+45%` no dano ofensivo apos correcao
- `defense`: pode chegar perto de `+35%` de defesa efetiva apos soft cap
- `vitality`: chega a `+33.5%` de HP
- `haste`: chega a `+80%` de speed efetiva
- `critical`: pode empurrar a chance combinada ate cap final de `55%`

Conclusao:

- helds estao entre os fatores mais fortes do sistema atual;
- em auditoria de baixo ruido, precisam ficar zerados/controlados.

## STAB

Peso real hoje:

- `medio-alto`

Valor atual:

- `+35%`

Conclusao:

- STAB isoladamente parece saudavel;
- ele so volta a explodir quando entra junto de:
  - type favoravel
  - atacante high-end
  - target fragil

## Type effectiveness

Peso real hoje:

- `alto`

Valores:

- `0`
- `0.5`
- `1`
- `2`
- podendo multiplicar no segundo tipo

Conclusao:

- type effectiveness continua sendo um dos maiores determinantes do dano final;
- isso esta saudavel em principio;
- os matchups explosivos remanescentes vem mais do `2x/4x` do que de STAB sozinho.

## DEF / SPDEF

Peso real hoje:

- `medio`

Formula atual:

- `reducao = (def / (def + 140)) * 70`
- cap `88`

Exemplo de ordem de grandeza:

- `def=100` -> ~`29.17%`
- `def=130` -> ~`33.83%`
- `def=48` -> ~`17.87%`

Conclusao:

- defesa voltou a importar;
- ainda nao e binaria;
- hoje esta em faixa muito melhor que no estado pre-patch.

## HP

Peso real hoje:

- `medio-alto`

Motivo:

- bulk real depende de `HP x mitigacao`;
- HP ainda nasce de `maxHealth` legado multiplicado pela escala atual.

Conclusao:

- HP pesa bastante no TTK;
- mas sua distribuicao entre especies ainda e fortemente herdada da camada antiga.

## SPEED

Peso real hoje:

- `alto` para mobilidade/uptime
- `baixo ou nulo` para cadencia direta de ataque

Confirmado no codigo:

- speed altera `getStepDuration()` e movimento;
- ataque usa `attackTicks` e `sb.speed` dos spells, nao `creature:getSpeed()` diretamente.

Conclusao:

- speed afeta principalmente:
  - aproximacao
  - perseguicao
  - reposicionamento
  - uptime sobre o alvo
  - percepcao de pressao
- nao ha evidencia aqui de que speed aumente diretamente a cadencia base do dano.

## Fatores super-representados

Confirmado:

1. `effectiveLevel`
2. `boost + held boost`
3. `speed` por mistura legacy/GBA
4. `type multiplier` em 2x/4x
5. `stack` high-end de itens/sistemas extras do jogador

## Fatores sub-representados

Confirmado:

1. `nature`
2. `IV` quando comparado com boost/BL/held boost
3. `species speed` puro, porque o totalSpeed ainda usa base legada
4. `species HP` puro, porque HP total ainda usa maxHealth legado como base

## Fatores que quase nao mudam o resultado final sozinhos

Confirmado:

- `nature`

Provavel, mas com menor certeza:

- `IV` isolado em comparacao com `level/boost/BL`

## Analise de DEF / SPDEF / HP / TTK

Confirmado pelos testes reais pos-patch:

- `Charizard melee vs Venusaur 50`: meia vida em ~20 hits
- `Charizard Flamethrower vs Venusaur 50`: meia vida em ~4 hits
- `Charizard vs Snorlax`: danos classificados como aceitaveis
- `Snorlax melee vs Charmeleon 16`: ainda alto, mas kill em ~8 hits e ja fora do patamar absurdo pre-patch

Leitura:

- TTK subiu;
- tanques estao segurando melhor;
- fragis continuam punidos, mas nao no mesmo grau anterior;
- bulk atual parece muito mais proximo do saudavel.

Risco remanescente:

- como HP ainda usa base legada, especies com `maxHealth` antigo muito inflado ou muito baixo podem virar outlier mesmo com species base stats razoaveis.

## Analise de SPEED / mobilidade / uptime

### O que esta confirmado

1. SPEED nao e o motor principal do dano bruto atual.
2. SPEED afeta movimento e uptime, nao a cadencia direta do ataque basico/spell.
3. A formula atual de totalSpeed mistura:
   - `combatBaseStats.speed = sourceType:getBaseSpeed()` (legacy)
   - `combatScale.speed = currentStatSpeed / combatReferenceSpeed` (GBA)

### Consequencia pratica

Isso cria distorcoes como:

- `Charmander effectiveLevel=12`, `current speed=22`, `totalSpeed=360`
- `shiny charizard effectiveLevel=32`, `current speed=90`, `totalSpeed=120`
- `Snorlax effectiveLevel=101`, `current speed=77`, `totalSpeed=213.23`
- `Venusaur level=100` no snapshot wild com `totalSpeed=294`, acima de `Charizard=273`

Conclusao:

- `speed` hoje esta estruturalmente incoerente entre especies e faixas;
- a sensacao de `rapido demais` e mais provavelmente de:
  - aproximacao/perseguicao
  - uptime
  - responsividade visual
do que de `cadencia de ataque`.

Veredito:

- este e o principal risco estrutural remanescente do meta atual.

## Analise de STAB / type effectiveness

### STAB atual

Valor real ativo:

- `+35%`

Leitura:

- saudavel no neutro;
- nao parece mais o vilao central do meta;
- nao ha motivo para novo nerf global de STAB agora.

### Type effectiveness

Leitura:

- continua forte, como deveria;
- continua sendo o maior amplificador de burst em matchups favoraveis;
- matchups 2x/4x continuam explosivos, especialmente com especies de alto `spatk`.

Evidencia real:

- `Shiny Charizard`, `effectiveLevel=102`, `Flame Burst` em `Bellsprout`
  - `rawPrimaryDamageInput=5298`
  - `finalAppliedDamage=8121`
  - `hpDeltaReal=900`

Leitura correta desse caso:

- nao houve dano duplicado bugado;
- o alvo so tinha `900 HP`;
- o que aparece ali e explosao de matchup favoravel + atacante high-end.

Conclusao:

- `STAB` esta saudavel;
- `type effectiveness` esta em faixa boa;
- o que ainda pode parecer explosivo demais e o encontro entre:
  - type favoravel
  - shiny/high effective level
  - alvo muito fragil

## Analise por funcao e por especie

### Tanks

`Blastoise`

- saudavel
- papel defensivo claro
- HP e defesas muito acima da media
- ofensiva menor que Charizard/Venusaur, o que e coerente com a funcao

`Snorlax`

- forte demais no melee comparado ao resto do campo testado
- ainda nao parece quebrado como antes
- segue como principal candidato a microtuning fino

### Bruisers

`Machamp`

- papel esta coerente:
  - melee muito alto
  - special bem menor
- nao ha teste real suficiente para chamar de over ou under
- parece role-correct no snapshot

### Glass cannon

`Alakazam`

- role split esta correto:
  - `totalMagicAttack=297`
  - `totalMeleeAttack=113`
- `totalPhysicalDefense=48` indica fragilidade fisica clara

Leitura:

- parece funcionalmente correto;
- principal risco e `baixo demais` na sobrevivencia fisica, nao alto demais no dano.

### Special attacker / all-rounder

`Charizard`

- pos-patch parece muito mais saudavel;
- continua forte, o que e esperado;
- nao e mais o principal problema estrutural do meta.

`Venusaur`

- bulk bom;
- especial bom;
- speed acima do esperado para um bulky all-rounder.

Leitura:

- maior suspeita do Venusaur hoje nao e dano bruto;
- e `mobilidade/uptime`.

### Mobility / chaser

`Charmander` e especies de baseLevel muito baixo

- forte suspeita de estarem acima da curva de mobilidade por causa da formula atual de speed.

### Suporte

- nao ha evidencia suficiente nesta fase para fechar suporte/buffer/healer.
- este papel segue em aberto.

## Top outliers positivos

### Confirmados

1. `Snorlax melee`
   - confirmado por testes reais
   - ainda e o melhor candidato de microtuning

2. `speed estrutural da linha Charmander / especies low-base-level`
   - confirmado em logs
   - problema de sistema, nao so de especie

3. `Venusaur speed/uptime`
   - forte suspeita
   - sustentada por snapshot atual

### Confirmados no sistema, mas nao ainda fechados por meta live completo

4. `boost + held boost`
   - super representados

5. `stack high-end de offensive extras`
   - card
   - star fusion
   - maestria
   - shiny
   - guild

## Top outliers negativos

### Confirmado

1. `Alakazam physical bulk`
   - muito baixo
   - provavelmente e o ponto mais perto de under-curve entre os perfis auditados

### Suspeitos, mas nao fechados

2. `Blastoise offensive ceiling`
   - menor pressao ofensiva
   - possivelmente role-correct, nao necessariamente problema

3. `suportes puros`
   - sem evidencia suficiente

Conclusao:

- nao ha hoje a mesma quantidade de under-outliers confirmados que de positive outliers;
- o principal problema remanescente ainda esta mais do lado `high pressure / speed / stack`.

## Summon vs selvagem

### Coerencia geral

Confirmado:

- summon e wild hoje estao coerentes no pipeline principal de dano;
- o bug de sobrescrita de level via `onSpawn` artificial foi corrigido;
- `/m level=` funciona para nivel fixo.

### O que ainda nao e perfeitamente coerente

1. `summon` e `wild` no mesmo level nominal nao sao equivalentes em poder real.

Motivo:

- summon usa camada de instancia:
  - IV
  - nature
  - BL
  - boost
  - held boost
  - training/shiny quando houver
- wild nao usa essa mesma camada.

Evidencia:

- no audit snapshot, `Charizard summon 100` ficou acima do `Charizard wild 100` em:
  - melee
  - special
  - HP
  - defesas
  - speed

2. `/cb` ainda nao gera paridade perfeita com `/m`.

Motivo:

- mesmo um `/cb` "limpo" com `bl=1, ivs=4, nature=Hardy` ja cria um summon acima do wild baseline.

Conclusao:

- `/cb` e ideal para teste de summon controlado;
- `/m` e ideal para teste de wild controlado;
- mas `summon level X` e `wild level X` nao devem ser tratados como equivalentes sem ressalva.

### Contaminacoes ainda possiveis

Confirmado:

- o nivel artificial do `/m` ja nao e sobrescrito;
- a leitura de stats do summon vem da pokeball e esta coerente para combate.

Caveat remanescente:

- `player-facing display` ainda nao e totalmente coerente com o poder real.

Motivo:

- o protocolo C++ monta o nome com `monster->getLevel()` e `monster->getBoost()`;
- o overhead do summon usa `pokeBoost` visual da ball;
- o combate usa `effectiveLevel = level + boost + held boost + BL`.

Consequencia:

- o poder real pode ser maior do que o label visual sugere;
- isso e problema de coerencia player-facing, nao de dano aplicado.

## Lacunas ainda nao fechadas

1. impacto real de `speed` no tempo ate primeiro hit e no uptime de perseguicao
2. stack high-end real do jogador
3. cobertura de especies alem do nucleo:
   - Charizard
   - Blastoise
   - Venusaur
   - Machamp
   - Alakazam
   - Snorlax
4. papeis de suporte/controle
5. coerencia de display/protocolo com effectiveLevel real

## Testes complementares necessarios

### Grupo 1 - SPEED / uptime

Necessario para fechar:

- tempo ate primeiro hit
- hits em janela fixa
- persistencia de perseguicao

Cenarios minimos:

1. `Charmander low level` vs `Charizard low level`
2. `Venusaur 60` vs `Charizard 60`
3. `Snorlax 100` vs `Charizard 100`

O que medir:

- tempo para encostar
- tempo para reacertar apos kite
- distancia media mantida em chase

### Grupo 2 - Stack high-end

Necessario para fechar o meta real do endgame:

1. mesmo summon, sem gear
2. com held boost
3. com held attack
4. com cards/star/maestria

O que medir:

- delta real de `totalMagicAttack`
- delta real de `totalMeleeAttack`
- delta real de dano final

### Grupo 3 - Coerencia player-facing

Necessario para fechar UX/runtime:

1. level exibido
2. boost exibido
3. effectiveLevel real
4. dano real entregue

## Plano de microtuning em fases

### Fase 0 - Ferramenta de auditoria

Atualizar o script `data/scripts/systems/auditoria/balance_audit_runtime.lua` para refletir a formula atual:

- STAB `1.35`
- reducao atual de defesa
- blend ofensivo `0.58`

Objetivo:

- recuperar confiabilidade dos `expected/validation`.

### Fase 1 - Estrutural de speed

Prioridade alta.

Objetivo:

- unificar `speed` com a mesma logica de base que atk/def/spatk/spdef;
- remover a mistura `legacy baseSpeed * escala GBA`.

Resultado esperado:

- mobilidade coerente por especie;
- menos distorcao em early game;
- menos uptime indevido em species lentas ou low-base-level.

### Fase 2 - Microtuning de especies

Prioridade media-alta.

Foco inicial:

1. `Snorlax melee`
2. `Venusaur speed`
3. especies low-level com speed fora da curva

### Fase 3 - Stack high-end

Prioridade media.

Se o meta real com gear ainda estiver explosivo:

- rever caps de held boost
- rever attack extras
- rever card/star/maestria stack

### Fase 4 - Cobertura de roster

Prioridade media.

Expandir auditoria para:

- outros tanks
- outros glass cannons
- suportes
- perseguidores/mobility picks

## Prioridade de correcoes

1. `Speed estrutural`
2. `Atualizacao do auditor automatico`
3. `Snorlax melee`
4. `Venusaur / low-level mobility outliers`
5. `Stack high-end`

Importante:

- `nao` fazer novo nerf global de dano agora;
- o eixo principal de dano ja saiu do estado critico;
- o proximo ajuste grande deve ser em `speed`, nao em burst global.

## Conclusao final objetiva

Veredito final desta fase:

1. O problema central anterior de `pokemons fortes demais` foi resolvido no eixo principal de dano e TTK.
2. A progressao por level esta funcionando de forma consistente no estado atual pos-patch.
3. A formula principal de dano atual esta aceitavel; o maior risco estrutural remanescente migrou para `speed`.
4. `Base stats` hoje diferenciam bem ofensiva e defesa por funcao, principalmente em atk/def/spatk/spdef.
5. `HP` e `speed` ainda sao os eixos mais legacy-dependent do sistema.
6. `STAB` esta em faixa saudavel; `type effectiveness` continua forte, mas de forma esperada.
7. `Summon` e `wild` estao coerentes no pipeline, mas nao sao equivalentes no mesmo level nominal.
8. O principal outlier de especie ainda visivel em teste real e `Snorlax melee`.
9. O principal outlier sistemico remanescente e `speed/mobilidade/uptime`.

Conclusao final:

- o servidor hoje esta `muito melhor balanceado` do que no estado anterior;
- o proximo ciclo nao deve ser uma nova cirurgia global de dano;
- deve ser uma rodada de:
  - correccao estrutural de speed
  - sincronizacao da ferramenta de auditoria
  - microtuning localizado de especies e stacks high-end.
