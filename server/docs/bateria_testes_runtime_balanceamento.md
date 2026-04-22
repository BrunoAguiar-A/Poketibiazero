# Bateria Curta de Testes para Identificar "Pokemon Forte Demais" no Runtime Real

Data: 2026-04-22
Repo: `/root/SERVER`

## Resumo curto

A sensacao atual de "forte demais" provavelmente nao vem de um unico ponto.
Pelo codigo atual e pelos logs recentes, o quadro mais provavel e:

- especiais dominando o combate mais do que o esperado;
- mitigacao de DEF/SPDEF segurando pouco;
- TTK curto demais nos matchups favoraveis e ate em neutro;
- SPEED amplificando a sensacao por mobilidade/uptime, nao por reduzir cooldown;
- compressao de identidade entre especies high-tier no melee basico;
- STAB + type multiplier + spell power + attack multiplier atuando em cascata.

Em outras palavras: a causa mais provavel hoje e `8. combinacao de varios fatores`, com peso maior em `1`, `4`, `6` e `7`.

## Fonte de verdade usada

- Codigo atual do servidor.
- `data/logs/manual_runtime_live_trace.log`
- `data/logs/auditoria/balance_audit_runtime_20260421_234148.log`

Sinais ja visiveis no runtime atual:

- Charizard lv 100 em alvo neutro:
  - melee: `675`
  - Fire Punch: `2037`
- Charizard lv 100 em alvo resistido Fire:
  - Flamethrower: `1455`
- Charizard lv 100 em alvo Grass:
  - melee tipado Fire: `1351`
- Charizard lv 70 real em Venusaur:
  - Fire Punch: `3032`
  - Ember: `4305`

Leitura:

- o especial continua muito alto mesmo fora do cenario "critico";
- resist ainda nao derruba tanto o dano;
- super efetivo explode o TTK;
- melee high-tier nao esta fixo, mas a diferenca entre especies ficou comprimida;
- o problema atual parece mais tuning estrutural do runtime do que bug isolado.

## Variaveis que precisam ficar controladas

Sempre fixe estes pontos para nao contaminar o teste:

- `boost=0`
- `bl=1`
- `nature=Hardy`
- `ivs=4`
- helds vazios
- sem guild buffs
- sem shiny
- sem treino natural acumulado fora do padrao do `/cb`
- mesma distancia inicial entre atacante e alvo
- alvo sempre com HP cheio antes de cada tentativa
- mesmo terreno aberto, sem obstaculo
- sem usar ball antiga ou reaproveitada

Observacao critica:

- se voce omitir `bl` no `/cb`, o script cria a ball com `BL` randomico.
- portanto, para teste limpo, `bl` precisa ser explicitado sempre.

## Campos do `/cb` que alteram combate real

Estes campos importam para o runtime:

- `species` ou nome do pokemon
- `level`
- `exp`
- `boost`
- `bl`
- `nature`
- `ivs`
- `ivhp`, `ivatk`, `ivdef`, `ivspatk`, `ivspdef`, `ivspeed`

Impacto pratico:

- `level` e `exp` alteram o level real salvo.
- `boost` entra no effective level.
- `bl` entra no effective level.
- `nature` altera stat em `+5%/-5%`.
- `ivs` alteram o perfil final real de stats.

## Campos do `/cb` que sao cosméticos ou irrelevantes para estes testes

Estes campos nao devem alterar a formula principal de combate atual:

- `gender`
- `stars`
- `rank`
- `nickname`
- `ball`, `ballkey`, `pokeball`

## Instrumentacao

Nao foi necessario adicionar patch novo para dano.
O runtime atual ja registra o essencial em:

- `data/logs/manual_runtime_live_trace.log`

Campos ja disponiveis no log atual:

- attacker
- target
- move
- raw damage input
- final applied damage
- hp delta real
- current stats
- total melee attack
- total magic attack

Para esta etapa, isso ja basta para confirmar se o problema e:

- formula estrutural;
- tuning;
- stats base;
- multiplicadores finais;
- TTK.

Para SPEED, o mais diagnostico nao e novo log de dano.
O que precisa ser observado e:

- tempo ate o primeiro hit;
- numero de hits em janela fixa;
- capacidade de manter contato/perseguicao.

Pelo codigo atual, SPEED nao reduz cooldown base de ataque.
Os intervalos de golpes continuam vindo de `pokemon.moves` e `Monster::canUseAttack`.
Logo, SPEED tende a impactar mais mobilidade e uptime do que cadencia bruta.

## Bateria priorizada

### Prioridade 1 — Grupo 5: STAB / Type / Multiplicadores finais

Motivo:

- e o teste com maior poder de diagnostico para saber se o dano final esta sendo dominado por multiplicadores mais do que por stats.

Confirma ou descarta:

- se STAB esta pesado demais;
- se resistencias seguram pouco;
- se super efetivo esta explodindo TTK;
- se o especial alto vem mais de multiplicadores do que do stat puro.

Setup:

- atacante: Charizard lv 100
- alvo neutro: Snorlax lv 100
- alvo resistido Fire: Charmeleon lv 60
- alvo favoravel Fire: Venusaur lv 60

Golpes:

- STAB: `Flamethrower`
- nao-STAB: `Ancient Fury`

O que observar:

- `hpDeltaReal`
- `rawPrimaryDamageInput`
- dano por power do golpe
- diferenca entre neutro, resistido e favoravel

Leitura esperada:

- se `Flamethrower` continuar muito alto ate no resistido, o problema pesa em multiplicadores + mitigacao fraca;
- se `Ancient Fury` normalizado por power ficar perto demais do STAB, STAB nao e o principal culpado;
- se `Flamethrower` disparar demais no favoravel, type multiplier esta dominando o resultado final.

Comandos `/cb`:

```text
/cb Charizard, level=100, boost=0, bl=1, nature=Hardy, ivs=4
/cb Snorlax, level=100, boost=0, bl=1, nature=Hardy, ivs=4
/cb Charmeleon, level=60, boost=0, bl=1, nature=Hardy, ivs=4
/cb Venusaur, level=60, boost=0, bl=1, nature=Hardy, ivs=4
```

### Prioridade 2 — Grupo 3: DEF / SPDEF / HP / TTK

Motivo:

- e o teste mais direto para separar "dano alto demais" de "alvo aguenta pouco demais".

Confirma ou descarta:

- se HP esta baixo demais no runtime real;
- se DEF e SPDEF amortecem pouco;
- se o problema e TTK curto por falta de tanqueza;
- se tank fisico e tank especial estao realmente diferenciados.

Setup:

- atacante fisico: Snorlax lv 100 usando melee
- atacante especial: Charizard lv 100 usando Flamethrower
- alvo fragil: Charmeleon lv 60
- alvo medio: Venusaur lv 60
- alvo tanque fisico: Onix lv 60
- alvo tanque misto/HP alto: Snorlax lv 100

O que observar:

- quantos hits para matar
- dano por hit
- diferenca fisico vs especial no mesmo alvo
- se Onix segura melee muito mais que Snorlax segura especial

Leitura esperada:

- se quase tudo morre em poucos hits, TTK esta curto estruturalmente;
- se Onix nao segura melee o bastante, DEF esta com peso baixo;
- se Snorlax nao segura especial o bastante, SPDEF/HP estao com peso baixo;
- se a diferenca entre fragil e tanque for pequena, o problema e mais de mitigacao/HP do que de ataque.

Comandos `/cb`:

```text
/cb Snorlax, level=100, boost=0, bl=1, nature=Hardy, ivs=4
/cb Charizard, level=100, boost=0, bl=1, nature=Hardy, ivs=4
/cb Charmeleon, level=60, boost=0, bl=1, nature=Hardy, ivs=4
/cb Venusaur, level=60, boost=0, bl=1, nature=Hardy, ivs=4
/cb Onix, level=60, boost=0, bl=1, nature=Hardy, ivs=4
/cb Snorlax, level=100, boost=0, bl=1, nature=Hardy, ivs=4
```

### Prioridade 3 — Grupo 1: Level Scaling

Motivo:

- este teste separa progressao fraca de overtuning fixo.

Confirma ou descarta:

- se level pesa de verdade;
- se o ganho de dano por level esta baixo demais;
- se o especial cresce mais que o fisico;
- se o problema e "pokemon forte demais em qualquer level" ou "progressao mal distribuida".

Setup:

- mesma especie: Charizard
- levels: 30, 60, 100
- medir: melee e Flamethrower
- alvo padrao: Snorlax lv 100 ou dummy neutro

O que observar:

- crescimento percentual do melee
- crescimento percentual do especial
- diferenca de TTK entre 30, 60 e 100

Leitura esperada:

- se 30 ja mata rapido demais, o baseline esta alto;
- se 100 cresce pouco sobre 60, a progressao esta fraca;
- se o especial cresce muito mais que o melee, o tuning ofensivo especial esta dominando.

Comandos `/cb`:

```text
/cb Charizard, level=30, boost=0, bl=1, nature=Hardy, ivs=4
/cb Charizard, level=60, boost=0, bl=1, nature=Hardy, ivs=4
/cb Charizard, level=100, boost=0, bl=1, nature=Hardy, ivs=4
/cb Snorlax, level=100, boost=0, bl=1, nature=Hardy, ivs=4
```

### Prioridade 4 — Grupo 4: SPEED

Motivo:

- este grupo mede se a sensacao de desbalanceamento vem da mobilidade e do uptime, nao do dano por hit.

Confirma ou descarta:

- se SPEED esta forte demais no chase;
- se pokemon rapido conecta o primeiro hit muito cedo;
- se a sensacao de "forte demais" vem de manter contato o tempo inteiro;
- se SPEED esta inflando a quantidade real de hits em janela curta.

Setup:

- rapido: Electrode lv 60
- medio: Charizard lv 60
- lento: Snorlax lv 60
- alvo padrao: Venusaur lv 60
- todos usando melee
- iniciar todos na mesma distancia, em campo aberto

O que observar:

- tempo ate o primeiro hit
- hits totais em 15s
- facilidade de manter alcance

Leitura esperada:

- se a diferenca de hits em 15s vier principalmente do tempo de contato, SPEED esta pesando pela mobilidade;
- se depois de colar no alvo o volume de hits fica parecido, SPEED nao esta alterando cooldown, so uptime;
- se o rapido consegue converter muito mais dano total em janela curta, SPEED esta contribuindo fortemente para a percepcao de overtuning.

Comandos `/cb`:

```text
/cb Electrode, level=60, boost=0, bl=1, nature=Hardy, ivs=4
/cb Charizard, level=60, boost=0, bl=1, nature=Hardy, ivs=4
/cb Snorlax, level=60, boost=0, bl=1, nature=Hardy, ivs=4
/cb Venusaur, level=60, boost=0, bl=1, nature=Hardy, ivs=4
```

### Prioridade 5 — Grupo 2: Base Stats / Identidade entre especies

Motivo:

- este grupo mostra se as especies estao mesmo diferenciadas ou se os dados/base legacy estao achatando o roster.

Confirma ou descarta:

- se especies high-tier estao proximas demais;
- se uma especie media encosta demais em uma especie top;
- se os stats base GBA ainda aparecem no runtime final;
- se a identidade por especie foi achatada pelo pipeline atual.

Setup:

- mesmo level: 60
- especies: Charizard, Blaziken, Venusaur, Charmeleon
- medir melee e golpe principal

O que observar:

- diferenca de melee entre tops
- diferenca de especial entre tops
- distancia de Charmeleon para os tops

Leitura esperada:

- se Charizard, Blaziken e Venusaur ficarem quase iguais no melee, ha compressao de identidade;
- se Charmeleon encostar demais nos tops, base stats ou escalonamento estao frouxos;
- se especial abrir muito mais que melee, o problema e mais de tuning ofensivo do que de roster bruto.

Comandos `/cb`:

```text
/cb Charizard, level=60, boost=0, bl=1, nature=Hardy, ivs=4
/cb Blaziken, level=60, boost=0, bl=1, nature=Hardy, ivs=4
/cb Venusaur, level=60, boost=0, bl=1, nature=Hardy, ivs=4
/cb Charmeleon, level=60, boost=0, bl=1, nature=Hardy, ivs=4
/cb Snorlax, level=100, boost=0, bl=1, nature=Hardy, ivs=4
```

## Ordem pratica recomendada

Use esta ordem para obter o maximo diagnostico com o minimo de teste:

1. Grupo 5
2. Grupo 3
3. Grupo 1
4. Grupo 4
5. Grupo 2

Se os dois primeiros grupos ja mostrarem:

- especial alto ate no resistido;
- TTK curto ate em tanque;
- pouco amortecimento de defesa;

entao o problema principal ja fica praticamente localizado em:

- dano especial estruturalmente alto;
- mitigacao defensiva fraca;
- multiplicadores finais dominando demais.

## O que anotar em cada repeticao

Para cada hit relevante:

- especie atacante
- especie alvo
- golpe
- `rawPrimaryDamageInput`
- `finalAppliedDamage`
- `hpDeltaReal`
- hits para matar
- tempo ate o primeiro hit
- hits em 15s, quando o teste for de SPEED

## Veredito tecnico mais provavel antes dos novos testes

O mais provavel hoje e:

- `nao` ser um problema de level "nao pesar";
- `nao` ser um bug isolado de runtime ignorando stats;
- `ser` um problema de calibragem combinada.

Pesos mais provaveis:

- especial forte demais: alto
- mitigacao DEF/SPDEF fraca: alto
- TTK curto demais: alto
- multiplicadores finais dominando mais que stats: alto
- SPEED causando uptime excessivo: medio
- base stats totalmente fora da curva: medio
- progressao por level fraca: medio/baixo

## Observacao final

Se for preciso fechar o diagnostico com numeros mais finos depois desta bateria, o proximo passo nao deve ser "rebalancear tudo".
O passo correto e:

1. rodar estes testes;
2. identificar qual grupo estoura primeiro;
3. mexer apenas na camada culpada:
   - formula ofensiva;
   - defesa/mitigacao;
   - powers de golpes;
   - dados/base stats;
   - speed/uptime.
