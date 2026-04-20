#!/usr/bin/env python3
import argparse
import datetime as dt
import os
import re
import shlex
import struct
import subprocess
import sys
from dataclasses import dataclass
from typing import Dict, Iterable, List, Optional, Tuple


ATTR_SPECIAL = 34
ATTR_CUSTOM_ATTRIBUTES = 46

DEFAULT_NATURE = "Hardy"
DEFAULT_IV = 4

POKEBALL_ITEM_TYPES = {
    10975, 10977, 11826, 11828, 11829, 11831, 11832, 11834, 11835, 11837,
    12617, 13228, 13229, 13231, 16704, 16706, 16707, 16709, 16710, 16712,
    16713, 16715, 16716, 16718, 16719, 16721, 16722, 16724, 16725, 16727,
    16728, 16730, 16731, 16733, 16734, 16736, 16737, 16739, 16740, 16742,
    22919, 22921, 22922, 22927, 22928, 22929, 22930, 22931, 22932, 22942,
    22943, 22944, 22945, 22946, 22947, 22948, 22949, 22950, 22951, 22952,
    22953, 23455, 23456, 24406, 24407, 26659, 26660, 26661, 26662, 26663,
    26666, 26670, 26672, 26674, 26675, 26677, 26678, 26681, 26683, 26686,
    26688, 32509, 32510, 32511, 32512, 32513, 32514, 32515, 32516, 32517,
    32518, 32520, 32535,
}

PERSONALITY_DEFAULTS = {
    "pokeNature": DEFAULT_NATURE,
    "pokeIVHP": DEFAULT_IV,
    "pokeIVATK": DEFAULT_IV,
    "pokeIVDEF": DEFAULT_IV,
    "pokeIVSPATK": DEFAULT_IV,
    "pokeIVSPDEF": DEFAULT_IV,
    "pokeIVSPEED": DEFAULT_IV,
}

LEGACY_TO_CANONICAL = {
    "nature": "pokeNature",
    "Nature": "pokeNature",
    "pokeIvHP": "pokeIVHP",
    "ivHP": "pokeIVHP",
    "iv_hp": "pokeIVHP",
    "IV_HP": "pokeIVHP",
    "pokeIvATK": "pokeIVATK",
    "ivATK": "pokeIVATK",
    "iv_atk": "pokeIVATK",
    "IV_ATK": "pokeIVATK",
    "pokeIvDEF": "pokeIVDEF",
    "ivDEF": "pokeIVDEF",
    "iv_def": "pokeIVDEF",
    "IV_DEF": "pokeIVDEF",
    "pokeIvSPATK": "pokeIVSPATK",
    "ivSPATK": "pokeIVSPATK",
    "iv_spatk": "pokeIVSPATK",
    "IV_SPATK": "pokeIVSPATK",
    "pokeIvSPDEF": "pokeIVSPDEF",
    "ivSPDEF": "pokeIVSPDEF",
    "iv_spdef": "pokeIVSPDEF",
    "IV_SPDEF": "pokeIVSPDEF",
    "pokeIvSPEED": "pokeIVSPEED",
    "ivSPEED": "pokeIVSPEED",
    "iv_speed": "pokeIVSPEED",
    "IV_SPEED": "pokeIVSPEED",
}

LEGACY_SPECIAL_TABLE_RE = re.compile(r'\["([^"]+)"\]\s*=\s*("([^"\\]|\\.)*"|-?\d+(?:\.\d+)?|true|false)')


@dataclass
class RowRef:
    table: str
    key_columns: Tuple[str, ...]
    key_values: Tuple[int, ...]
    itemtype: int
    attributes_hex: str
    player_id: int

    @property
    def where_sql(self) -> str:
        parts = []
        for column, value in zip(self.key_columns, self.key_values):
            parts.append(f"`{column}` = {int(value)}")
        return " AND ".join(parts)


@dataclass
class MigrationResult:
    row: RowRef
    format_name: str
    before_hex: str
    after_hex: str
    added_keys: List[str]


def run_mysql_query(args: argparse.Namespace, sql: str) -> str:
    cmd = [
        "mysql",
        f"-h{args.host}",
        f"-P{args.port}",
        f"-u{args.user}",
    ]
    if args.password:
        cmd.append(f"-p{args.password}")
    cmd.extend(["-N", "-B", args.database, "-e", sql])
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "mysql command failed")
    return result.stdout


def read_u16(buf: bytes, offset: int) -> Tuple[int, int]:
    return struct.unpack_from("<H", buf, offset)[0], offset + 2


def read_u64(buf: bytes, offset: int) -> Tuple[int, int]:
    return struct.unpack_from("<Q", buf, offset)[0], offset + 8


def read_i64(buf: bytes, offset: int) -> Tuple[int, int]:
    return struct.unpack_from("<q", buf, offset)[0], offset + 8


def parse_custom_attributes(blob: bytes) -> Tuple[List[Tuple[str, object, int]], int]:
    if not blob or blob[0] != ATTR_CUSTOM_ATTRIBUTES:
        raise ValueError("not a custom-attributes blob")

    offset = 1
    count, offset = read_u64(blob, offset)
    entries: List[Tuple[str, object, int]] = []
    for _ in range(count):
        key_len, offset = read_u16(blob, offset)
        key = blob[offset:offset + key_len].decode("utf-8")
        offset += key_len
        value_type = blob[offset]
        offset += 1
        if value_type == 1:
            str_len, offset = read_u16(blob, offset)
            value = blob[offset:offset + str_len].decode("utf-8")
            offset += str_len
        elif value_type == 2:
            value, offset = read_i64(blob, offset)
        elif value_type == 3:
            value = struct.unpack_from("<d", blob, offset)[0]
            offset += 8
        elif value_type == 4:
            value = bool(blob[offset])
            offset += 1
        else:
            raise ValueError(f"unsupported custom attribute variant {value_type}")
        entries.append((key, value, value_type))
    return entries, offset


def serialize_custom_attributes(entries: Iterable[Tuple[str, object, int]]) -> bytes:
    entries = list(entries)
    out = bytearray()
    out.append(ATTR_CUSTOM_ATTRIBUTES)
    out.extend(struct.pack("<Q", len(entries)))
    for key, value, value_type in entries:
        key_bytes = key.encode("utf-8")
        out.extend(struct.pack("<H", len(key_bytes)))
        out.extend(key_bytes)
        out.append(value_type)
        if value_type == 1:
            value_bytes = str(value).encode("utf-8")
            out.extend(struct.pack("<H", len(value_bytes)))
            out.extend(value_bytes)
        elif value_type == 2:
            out.extend(struct.pack("<q", int(value)))
        elif value_type == 3:
            out.extend(struct.pack("<d", float(value)))
        elif value_type == 4:
            out.extend(struct.pack("<?", bool(value)))
        else:
            raise ValueError(f"unsupported value type {value_type}")
    return bytes(out)


def parse_special_table(text: str) -> Dict[str, str]:
    values: Dict[str, str] = {}
    for match in LEGACY_SPECIAL_TABLE_RE.finditer(text):
        values[match.group(1)] = match.group(2)
    return values


def encode_lua_literal(value: object) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return str(value)
    escaped = str(value).replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def patch_special_table_string(text: str, additions: Dict[str, object]) -> str:
    stripped = text.rstrip()
    if not stripped.endswith("}"):
        raise ValueError("legacy special table does not end with '}'")

    inner = stripped[:-1].rstrip()
    while inner.endswith(","):
        inner = inner[:-1].rstrip()
    insert = ",".join(f'["{key}"] = {encode_lua_literal(value)}' for key, value in additions.items())
    return inner + ("," if inner != "{" else "") + insert + "}"


def normalize_special_table_string(text: str) -> str:
    stripped = text.strip()
    if not stripped.startswith("{") or not stripped.endswith("}"):
        return text
    body = stripped[1:-1]
    body = re.sub(r",\s*,+", ",", body)
    body = re.sub(r",\s*$", "", body)
    return "{" + body + "}"


def serialize_special_string(text: str) -> bytes:
    text_bytes = text.encode("utf-8")
    return bytes([ATTR_SPECIAL]) + struct.pack("<H", len(text_bytes)) + text_bytes


def canonicalize_existing_values(existing: Dict[str, object], added_keys: List[str]) -> None:
    for legacy_key, canonical_key in LEGACY_TO_CANONICAL.items():
        if canonical_key in existing or legacy_key not in existing:
            continue
        existing[canonical_key] = existing[legacy_key]
        added_keys.append(canonical_key)


def migrate_custom_blob(blob: bytes) -> Optional[Tuple[bytes, List[str]]]:
    entries, offset = parse_custom_attributes(blob)
    if offset != len(blob):
        raise ValueError("custom attribute blob has trailing bytes")

    existing: Dict[str, object] = {key: value for key, value, _ in entries}
    added_keys: List[str] = []
    canonicalize_existing_values(existing, added_keys)

    poke_name = existing.get("pokeName") or existing.get("pokename")
    if not poke_name:
        return None

    for key, default_value in PERSONALITY_DEFAULTS.items():
        if key in existing:
            continue
        existing[key] = default_value
        added_keys.append(key)

    if not added_keys:
        return None

    existing_order = {key: idx for idx, (key, _, _) in enumerate(entries)}
    next_order = len(existing_order)
    for key in added_keys:
        if key not in existing_order:
            existing_order[key] = next_order
            next_order += 1

    rebuilt = []
    for key in sorted(existing.keys(), key=lambda current: existing_order.get(current, 10_000)):
        value = existing[key]
        value_type = 1 if isinstance(value, str) else 4 if isinstance(value, bool) else 3 if isinstance(value, float) else 2
        rebuilt.append((key, value, value_type))
    return serialize_custom_attributes(rebuilt), sorted(set(added_keys))


def migrate_special_blob(blob: bytes) -> Optional[Tuple[bytes, List[str]]]:
    if not blob or blob[0] != ATTR_SPECIAL:
        raise ValueError("not a special-string blob")
    if len(blob) < 3:
        raise ValueError("special-string blob too short")
    str_len = struct.unpack_from("<H", blob, 1)[0]
    original_text = blob[3:3 + str_len].decode("utf-8")
    text = normalize_special_table_string(original_text)
    values = parse_special_table(text)
    poke_name = values.get("pokeName") or values.get("pokename")
    if not poke_name:
        return None

    additions: Dict[str, object] = {}
    for legacy_key, canonical_key in LEGACY_TO_CANONICAL.items():
        if legacy_key in values and canonical_key not in values:
            additions[canonical_key] = values[legacy_key].strip('"')

    for key, default_value in PERSONALITY_DEFAULTS.items():
        if key not in values and key not in additions:
            additions[key] = default_value

    if not additions:
        if text != original_text:
            return serialize_special_string(text), []
        return None

    patched_text = patch_special_table_string(text, additions)
    return serialize_special_string(patched_text), sorted(additions.keys())


def maybe_migrate_row(row: RowRef) -> Optional[MigrationResult]:
    if not row.attributes_hex:
        return None
    blob = bytes.fromhex(row.attributes_hex)
    if not blob:
        return None

    migrated: Optional[Tuple[bytes, List[str]]] = None
    format_name = ""
    if blob[0] == ATTR_CUSTOM_ATTRIBUTES:
        migrated = migrate_custom_blob(blob)
        format_name = "custom"
    elif blob[0] == ATTR_SPECIAL:
        migrated = migrate_special_blob(blob)
        format_name = "special"
    else:
        return None

    if not migrated:
        return None

    new_blob, added_keys = migrated
    if new_blob == blob:
        return None

    return MigrationResult(
        row=row,
        format_name=format_name,
        before_hex=row.attributes_hex.upper(),
        after_hex=new_blob.hex().upper(),
        added_keys=added_keys,
    )


def fetch_rows(args: argparse.Namespace, table: str, key_columns: Tuple[str, ...]) -> List[RowRef]:
    key_select = ", ".join(f"`{column}`" for column in key_columns)
    item_filter = ", ".join(str(item_id) for item_id in sorted(POKEBALL_ITEM_TYPES))
    sql = f"""
SELECT {key_select}, itemtype, HEX(attributes)
FROM `{table}`
WHERE itemtype IN ({item_filter})
  AND attributes IS NOT NULL
  AND OCTET_LENGTH(attributes) > 0
  AND player_id NOT IN (SELECT player_id FROM players_online)
"""
    if args.limit:
        sql += f" LIMIT {int(args.limit)}"

    output = run_mysql_query(args, sql)
    rows: List[RowRef] = []
    for raw_line in output.splitlines():
        parts = raw_line.split("\t")
        if len(parts) != len(key_columns) + 2:
            continue
        key_values = tuple(int(value) for value in parts[: len(key_columns)])
        itemtype = int(parts[len(key_columns)])
        attributes_hex = parts[len(key_columns) + 1]
        rows.append(RowRef(table, key_columns, key_values, itemtype, attributes_hex, key_values[0]))
    return rows


def write_sql_files(results: List[MigrationResult], backup_path: str, forward_path: str) -> None:
    with open(backup_path, "w", encoding="utf-8") as backup_file, open(forward_path, "w", encoding="utf-8") as forward_file:
        backup_file.write("-- Rollback for pokeball personality migration\nSTART TRANSACTION;\n")
        forward_file.write("-- Forward migration for pokeball personality materialization\nSTART TRANSACTION;\n")
        for result in results:
            rollback_sql = f"UPDATE `{result.row.table}` SET `attributes` = UNHEX('{result.before_hex}') WHERE {result.row.where_sql};\n"
            forward_sql = f"UPDATE `{result.row.table}` SET `attributes` = UNHEX('{result.after_hex}') WHERE {result.row.where_sql};\n"
            backup_file.write(rollback_sql)
            forward_file.write(forward_sql)
        backup_file.write("COMMIT;\n")
        forward_file.write("COMMIT;\n")


def execute_sql_file(args: argparse.Namespace, sql_path: str) -> None:
    cmd = [
        "mysql",
        f"-h{args.host}",
        f"-P{args.port}",
        f"-u{args.user}",
    ]
    if args.password:
        cmd.append(f"-p{args.password}")
    cmd.append(args.database)
    with open(sql_path, "rb") as handle:
        result = subprocess.run(cmd, stdin=handle, capture_output=True)
    if result.returncode != 0:
        raise RuntimeError(result.stderr.decode("utf-8", errors="replace").strip() or "mysql update failed")


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Materialize IV and nature on legacy pokeballs.")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=3306)
    parser.add_argument("--user", default="root")
    parser.add_argument("--password", default="")
    parser.add_argument("--database", default="poketibia")
    parser.add_argument("--execute", action="store_true", help="Apply updates. Default is dry-run.")
    parser.add_argument("--limit", type=int, default=0, help="Limit rows fetched per table for testing.")
    parser.add_argument("--backup-dir", default="/root/SERVER/backups")
    return parser


def main() -> int:
    args = build_arg_parser().parse_args()
    os.makedirs(args.backup_dir, exist_ok=True)

    online_output = run_mysql_query(args, "SELECT p.id, p.name FROM players_online po JOIN players p ON p.id = po.player_id ORDER BY p.id;")
    online_players = [tuple(line.split("\t", 1)) for line in online_output.splitlines() if line.strip()]

    tables = [
        ("player_items", ("player_id", "pid", "sid")),
        ("player_depotitems", ("player_id", "sid")),
        ("player_inboxitems", ("player_id", "sid")),
    ]

    scanned = 0
    results: List[MigrationResult] = []
    format_counts: Dict[str, int] = {"custom": 0, "special": 0}
    table_counts: Dict[str, int] = {}

    for table, key_columns in tables:
        rows = fetch_rows(args, table, key_columns)
        scanned += len(rows)
        for row in rows:
            migrated = maybe_migrate_row(row)
            if not migrated:
                continue
            results.append(migrated)
            format_counts[migrated.format_name] = format_counts.get(migrated.format_name, 0) + 1
            table_counts[row.table] = table_counts.get(row.table, 0) + 1

    timestamp = dt.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    backup_path = os.path.join(args.backup_dir, f"pokeball_personality_rollback_{timestamp}.sql")
    forward_path = os.path.join(args.backup_dir, f"pokeball_personality_forward_{timestamp}.sql")
    write_sql_files(results, backup_path, forward_path)

    print(f"Scanned rows: {scanned}")
    print(f"Players online excluded: {len(online_players)}")
    for player_id, name in online_players:
        print(f"  excluded player_id={player_id} name={name}")
    print(f"Rows to migrate: {len(results)}")
    print(f"By format: {format_counts}")
    print(f"By table: {table_counts}")
    print(f"Rollback SQL: {backup_path}")
    print(f"Forward SQL: {forward_path}")

    if results:
        print("Sample updates:")
        for result in results[:10]:
            print(
                f"  {result.row.table} {result.row.where_sql} itemtype={result.row.itemtype} "
                f"format={result.format_name} added={','.join(result.added_keys)}"
            )

    if not args.execute:
        print("Dry-run only. Re-run with --execute to apply.")
        return 0

    if not results:
        print("Nothing to migrate.")
        return 0

    execute_sql_file(args, forward_path)
    print("Migration applied.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
