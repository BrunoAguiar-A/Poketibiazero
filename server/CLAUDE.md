# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**The Forgotten Server** — a C++20 MMORPG server emulator (Tibia-like). This is a "PokeMonster" fork. The server speaks the Tibia binary protocol over TCP, uses MariaDB/MySQL for persistence, and exposes Lua scripting for all game content/behavior.

## Build

```bash
mkdir build && cd build
cmake ..
make
```

Output binary: `build/tfs`

There is no test suite and no lint configuration. The compiler enforces `-Wall -Werror` on non-Windows, so warnings are build failures.

**CMake build types:**
- `cmake -DCMAKE_BUILD_TYPE=Release ..` — production
- `cmake -DCMAKE_BUILD_TYPE=Performance ..` — `-O3 -march=native`

## Running the Server

```bash
./start.sh   # via gdb with auto-restart on crash; backs up DB after each run
./build/tfs  # direct run (no watchdog)
```

Config is read from `config.lua` at startup (copy from `config.lua.dist`). MySQL credentials, ports, rates, and world type are all set there. The schema is in `pokemonster.sql`.

## Architecture

The codebase is layered; data flows top-to-bottom:

```
Network (server.cpp, connection.cpp)
  └─ Protocol (protocolgame.cpp, protocollogin.cpp — XTEA encrypted binary)
       └─ Game (game.cpp — central singleton g_game, orchestrates everything)
            ├─ World (map.cpp, tile.cpp, spawn.cpp, pathfinding.cpp)
            ├─ Creatures (creature.cpp → player.cpp / monster.cpp / npc.cpp)
            ├─ Items (item.cpp, items.cpp, container.cpp, weapons.cpp)
            ├─ Combat (combat.cpp, spells.cpp, condition.cpp)
            ├─ Scripting (luascript.cpp, scriptmanager.cpp, baseevents.cpp)
            └─ Persistence (database.cpp, iologindata.cpp, databasetasks.cpp)
```

**Key singletons** (initialized in `otserv.cpp::main()`):
`g_game`, `g_config`, `g_scheduler`, `g_dispatcher`, `g_databaseTasks`, `g_monsters`, `g_vocations`, `g_scripts`, `g_RSA`

**Threading model:** The dispatcher runs game logic on a single thread. `scheduler.cpp` queues timed events into the dispatcher. Database queries are issued asynchronously via `databasetasks.cpp` (separate thread). Network I/O uses Boost.Asio.

## Scripting System

All game behavior that isn't hardcoded lives in `data/` as Lua scripts or XML definitions:

| Path | Controls |
|------|----------|
| `data/actions/` | Item use actions |
| `data/talkactions/` | Chat commands (player-facing) |
| `data/creaturescripts/` | Creature event hooks (onDeath, onKill, etc.) |
| `data/globalevents/` | Timer and server-level events |
| `data/spells/` | Spell definitions (instant, rune, conjure) |
| `data/movements/` | Tile step-on/step-off triggers |
| `data/npc/` | NPC dialog scripts |
| `data/monster/` | Monster stat/loot/behavior XMLs |
| `data/XML/` | Vocations, groups, outfits, mounts, wings, quests, stages |
| `data/lib/` | Shared Lua libraries |

The Lua–C++ bridge is in `src/luascript.cpp` (very large file, ~17K lines). Script registration entrypoints are the `register*()` methods on `LuaScriptInterface`. `scriptmanager.cpp` loads all scripts at startup.

## Data Files vs. C++ Code

A useful distinction: **game content** (what monsters drop, how spells work, what NPCs say) lives in `data/` and can be changed without recompiling. **Engine behavior** (protocol parsing, pathfinding algorithm, combat formula) lives in `src/` and requires a rebuild.

## Dependencies

Managed via `vcpkg.json`: Boost (asio, iostreams, lockfree, …), LuaJIT 2.1, MariaDB Connector/C, fmt, Crypto++, PugiXML, GMP, zlib, OpenSSL.

System packages needed (Debian/Ubuntu): `libcrypto++-dev libboost-all-dev libgmp3-dev libluajit-5.1-dev libmariadb-dev libxml2-dev zlib1g-dev libfmt-dev libpugixml-dev`

Precompiled header: `src/otpch.h` — pulls in most STL and Boost headers; add new heavy includes here rather than in individual files.
