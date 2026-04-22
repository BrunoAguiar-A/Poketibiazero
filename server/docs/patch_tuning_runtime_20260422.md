# Patch de Tuning do Runtime Real - 2026-04-22

## Diagnóstico Fechado

Os testes manuais no runtime real fecharam quatro pontos:

1. `melee baseline` estava alto demais.
2. `especial/STAB` estava forte demais, inclusive em neutro e em resist.
3. `DEF/SPDEF` estavam segurando pouco.
4. O problema dominante era `tuning estrutural`, nao bug novo de progressao.

Evidencias principais:

- Charizard 100 melee em Venusaur ~50: `1430`
- Charizard 100 Flamethrower em Venusaur ~47: `>6000`
- Charizard 100 Flamethrower em Snorlax ~52: `3500`
- Snorlax 100 melee em Venusaur ~57: `989`
- Snorlax 100 melee em Charmeleon ~16: `1119`
- Charmeleon 60 melee em Venusaur ~50: `674`
- Charizard 100 Flamethrower em Onix 33: `1693` mesmo em resist

Conclusao:

- o sistema estava ofensivo demais em geral;
- o peso da defesa era insuficiente;
- STAB estava inflando burst demais;
- `Ancient Fury` nao estava funcionando como buff de preparo; ele estava se comportando como dano proprio.

## Causa Estrutural

O dano final estava ficando alto pela soma de tres fatores:

1. `attackStatMultiplier` aplicando quase todo o delta do ataque dinamico:
   - `dynamicAttack / resolvedBaseAttack`
2. `STAB` de `+50%` no core
3. curva de defesa muito leve:
   - `def / (def + 180) * 60`

Essa combinacao deixava:

- melee alto demais ao simples contato;
- especiais explodindo TTK;
- alvos tank segurando pouco no runtime real.

## Correcao Aplicada

### 1. Defesa mais relevante

Arquivo:

- [data/creaturescripts/scripts/monsterhealthchange.lua](/root/SERVER/data/creaturescripts/scripts/monsterhealthchange.lua:1)

Mudanca:

- antes:
  - `reducao = (def / (def + 180)) * 60`
  - cap `85`
- agora:
  - `reducao = (def / (def + 140)) * 70`
  - cap `88`

Efeito esperado:

- DEF/SPDEF passam a amortecer mais;
- tank fisico e tank especial ficam mais perceptiveis;
- TTK sobe sem zerar dano.

### 2. Multiplicador ofensivo comprimido

Arquivo:

- [data/creaturescripts/scripts/monsterhealthchange.lua](/root/SERVER/data/creaturescripts/scripts/monsterhealthchange.lua:193)

Mudanca:

- antes:
  - `attackStatMultiplier = dynamic / base`
- agora:
  - `1 + ((dynamic/base - 1) * 0.58)`

Efeito esperado:

- level continua pesando;
- ataque dinamico continua importando;
- mas deixa de dominar o dano final sozinho.

### 3. STAB reduzido

Arquivo:

- [src/game.cpp](/root/SERVER/src/game.cpp:4487)

Mudanca:

- antes:
  - `+50%`
- agora:
  - `+35%`

Efeito esperado:

- reduz burst global sem matar identidade de tipo;
- ajuda principalmente melee tipado e especiais com STAB.

## Mudanca Operacional Extra

### `/m` agora aceita level

Arquivo:

- [data/talkactions/scripts/place_monster.lua](/root/SERVER/data/talkactions/scripts/place_monster.lua:1)

Novo uso:

```text
/m Onix, level=33
/m Snorlax, level=64
/m Venusaur, qty=3, level=50
```

Tambem continua aceitando quantidade e outfit.

Objetivo:

- permitir criar selvagem controlado para teste;
- reduzir ruído de nivel aleatorio na bateria de validacao.

## Validacao Esperada Apos Patch

Comparado ao estado anterior, espera-se:

- queda clara no melee baseline;
- queda forte no burst especial com STAB;
- Onix e Snorlax segurando melhor;
- Venusaur nao ficando quase IK por Flame em cenarios proximos aos testados;
- diferenca de tank entre Onix / Snorlax / Venusaur mais visivel.

## Proximo Passo de Validacao

Repetir os cenarios mais criticos:

```text
/cb Charizard, level=100, boost=0, bl=1, nature=Hardy, ivs=4
/cb Snorlax, level=100, boost=0, bl=1, nature=Hardy, ivs=4
/cb Charmeleon, level=60, boost=0, bl=1, nature=Hardy, ivs=4
/cb Venusaur, level=60, boost=0, bl=1, nature=Hardy, ivs=4
```

E para selvagens controlados:

```text
/m Onix, level=33
/m Snorlax, level=64
/m Venusaur, level=50
/m Charmeleon, level=20
```

## Resumo Final

Este patch nao foi rebalance por especie.
Foi um ajuste estrutural em tres pontos:

- ofensiva dinamica menos explosiva;
- defesa com mais peso;
- STAB menos agressivo.

O objetivo foi atacar exatamente o que o runtime real mostrou: dano alto demais, TTK curto demais e bulk insuficiente.
