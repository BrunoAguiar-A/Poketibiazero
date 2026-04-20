#!/usr/bin/env python3
"""
Export Pokemon balance data without loading or changing the game server.

Usage:
  python3 tools/export_pokemon_balance.py > /tmp/pokemon_balance.csv
  python3 tools/export_pokemon_balance.py --format json --output /tmp/pokemon_balance.json
  python3 tools/export_pokemon_balance.py --monster-dir data/monster --level-system data/lib/pokemon/level_system.lua
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from pathlib import Path

PREFIXES = (
    "shiny ",
    "mega ",
    "ancient ",
    "master ",
    "guardian ",
    "sabrina s ",
    "dark ",
    "alolan ",
    "galarian ",
    "brave ",
    "elder ",
    "furious ",
    "tribal ",
    "war ",
    "perfect ",
    "mini ",
    "black ",
    "white ",
    "green ",
    "ice ",
    "light ball ",
    "golden ",
    "crystal ",
    "shadow ",
)

FIELDNAMES = (
    "name",
    "source_file",
    "hp_base",
    "attack_base",
    "defense_base",
    "speed",
    "wild_range",
    "wild_range_source",
    "evolution_requirements",
    "stones",
    "stats_formula_source",
    "uses_gba_stats",
)


def clean_lua_comments(text: str) -> str:
    return re.sub(r"--[^\r\n]*", "", text)


def normalize_name(name: str) -> str:
    value = str(name or "").lower()
    value = re.sub(r"[\x00-\x1f]", "", value)
    value = re.sub(r"[.']", "", value)
    value = value.replace("-", " ")
    value = re.sub(r"\s+", " ", value).strip()

    changed = True
    while changed:
        changed = False
        for prefix in PREFIXES:
            if value.startswith(prefix):
                value = value[len(prefix):]
                changed = True

    return re.sub(r"\s+", " ", value).strip()


def normalize_exact_key(name: str) -> str:
    value = str(name or "").lower()
    value = re.sub(r"[\x00-\x1f]", "", value)
    value = re.sub(r"[.']", "", value)
    value = value.replace("-", " ")
    return re.sub(r"\s+", " ", value).strip()


def extract_table_body(text: str, table_name: str) -> str:
    match = re.search(rf"local\s+{re.escape(table_name)}\s*=\s*\{{", text)
    if not match:
        return ""

    start = match.end()
    depth = 1
    pos = start
    while pos < len(text):
        char = text[pos]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return text[start:pos]
        pos += 1

    return ""


def parse_level_system(path: Path) -> tuple[dict[str, tuple[int, int]], set[str]]:
    text = path.read_text(encoding="utf-8-sig", errors="replace")

    gba_names: set[str] = set()
    stats_match = re.search(r"local\s+GBA_STATS_DATA\s*=\s*\[\[(.*?)\]\]", text, re.S)
    if stats_match:
        for line in stats_match.group(1).splitlines():
            parts = [part.strip() for part in line.split(",")]
            if len(parts) == 7 and all(part.isdigit() for part in parts[1:]):
                gba_names.add(normalize_name(parts[0]))

    ranges: dict[str, tuple[int, int]] = {}
    body = extract_table_body(clean_lua_comments(text), "WILD_LEVEL_RANGES")
    for key, min_level, max_level in re.findall(r'\["([^"]+)"\]\s*=\s*\{\s*(\d+)\s*,\s*(\d+)\s*\}', body):
        ranges[normalize_exact_key(key)] = (int(min_level), int(max_level))
    for key, min_level, max_level in re.findall(r"\b([A-Za-z0-9_]+)\s*=\s*\{\s*(\d+)\s*,\s*(\d+)\s*\}", body):
        ranges[normalize_exact_key(key)] = (int(min_level), int(max_level))

    return ranges, gba_names


def number_after(pattern: str, text: str) -> str:
    match = re.search(pattern, text)
    return match.group(1) if match else ""


def extract_evolution_blocks(text: str) -> list[str]:
    match = re.search(r"pokemon\.evolutions\s*=\s*\{", text)
    if not match:
        return []

    start = match.end()
    depth = 1
    pos = start
    body_end = None
    while pos < len(text):
        char = text[pos]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                body_end = pos
                break
        pos += 1

    if body_end is None:
        return []

    body = text[start:body_end]
    blocks: list[str] = []
    depth = 0
    block_start = None
    for index, char in enumerate(body):
        if char == "{":
            depth += 1
            if depth == 1:
                block_start = index
        elif char == "}":
            if depth == 1 and block_start is not None:
                blocks.append(body[block_start:index + 1])
                block_start = None
            depth -= 1

    return blocks


def parse_evolutions(text: str) -> tuple[str, str]:
    requirements: list[str] = []
    stones_out: list[str] = []

    for block in extract_evolution_blocks(clean_lua_comments(text)):
        name_match = re.search(r'pokeName\s*=\s*"([^"]+)"', block)
        level_match = re.search(r"level\s*=\s*(\d+)", block)
        target = name_match.group(1) if name_match else "unknown"
        level = level_match.group(1) if level_match else ""
        stones = []

        for stone_id, count in re.findall(r"stoneId\s*=\s*(\d+)\s*,\s*stoneCount\s*=\s*(\d+)", block):
            stones.append(f"{stone_id}x{count}")

        requirements.append(f"{target}@{level}" if level else target)
        stones_out.append(f"{target}:{'+'.join(stones) if stones else 'none'}")

    return "; ".join(requirements), "; ".join(stones_out)


def parse_monster_file(
    path: Path,
    root: Path,
    wild_ranges: dict[str, tuple[int, int]],
    gba_names: set[str],
) -> dict[str, str] | None:
    text = path.read_text(encoding="utf-8-sig", errors="replace")
    name_match = re.search(r'Game\.createMonsterType\("([^"]+)"\)', text)
    if not name_match:
        return None

    name = name_match.group(1)
    exact_key = normalize_exact_key(name)
    species_key = normalize_name(name)
    range_value = wild_ranges.get(exact_key) or wild_ranges.get(species_key)
    if range_value:
        wild_range = f"{range_value[0]}-{range_value[1]}"
        wild_source = "WILD_LEVEL_RANGES"
    else:
        min_level = int(number_after(r"minimumLevel\s*=\s*(\d+)", text) or 1)
        max_level = min(100, min_level + 10)
        wild_range = f"{min_level}-{max_level}"
        wild_source = "fallback:minimumLevel+10"

    evolution_requirements, stones = parse_evolutions(text)
    uses_gba_stats = species_key in gba_names

    return {
        "name": name,
        "source_file": str(path.relative_to(root)),
        "hp_base": number_after(r"pokemon\.health\s*=\s*(\d+)", text),
        "attack_base": number_after(r"moveMagicAttackBase\s*=\s*(\d+)", text),
        "defense_base": number_after(r"moveMagicDefenseBase\s*=\s*(\d+)", text),
        "speed": number_after(r"pokemon\.speed\s*=\s*(\d+)", text),
        "wild_range": wild_range,
        "wild_range_source": wild_source,
        "evolution_requirements": evolution_requirements,
        "stones": stones,
        "stats_formula_source": "GBA_STATS_DATA" if uses_gba_stats else "fallbackStats(monsterType)",
        "uses_gba_stats": "yes" if uses_gba_stats else "no",
    }


def collect_rows(root: Path, monster_dir: Path, level_system: Path) -> list[dict[str, str]]:
    wild_ranges, gba_names = parse_level_system(level_system)
    rows: list[dict[str, str]] = []

    for path in sorted(monster_dir.rglob("*")):
        if path.suffix.lower() not in {".lua", ".txt"}:
            continue
        row = parse_monster_file(path, root, wild_ranges, gba_names)
        if row:
            rows.append(row)

    return rows


def write_csv(rows: list[dict[str, str]], output) -> None:
    writer = csv.DictWriter(output, fieldnames=FIELDNAMES, lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)


def main() -> int:
    parser = argparse.ArgumentParser(description="Export Pokemon balance data for audit.")
    parser.add_argument("--monster-dir", default="data/monster", help="Directory with monster definition files.")
    parser.add_argument("--level-system", default="data/lib/pokemon/level_system.lua", help="Pokemon level system file.")
    parser.add_argument("--format", choices=("csv", "json"), default="csv", help="Output format.")
    parser.add_argument("--output", help="Write to this file instead of stdout.")
    args = parser.parse_args()

    root = Path.cwd()
    monster_dir = (root / args.monster_dir).resolve()
    level_system = (root / args.level_system).resolve()
    rows = collect_rows(root, monster_dir, level_system)

    if args.output:
        output_path = Path(args.output)
        with output_path.open("w", encoding="utf-8", newline="") as output:
            if args.format == "json":
                json.dump(rows, output, ensure_ascii=False, indent=2)
                output.write("\n")
            else:
                write_csv(rows, output)
    elif args.format == "json":
        json.dump(rows, sys.stdout, ensure_ascii=False, indent=2)
        sys.stdout.write("\n")
    else:
        write_csv(rows, sys.stdout)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
