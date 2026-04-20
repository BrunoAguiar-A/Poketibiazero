#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GENERATOR_SRC="$ROOT_DIR/tools/generate_otmm_minimap.cpp"
GENERATOR_BIN="$ROOT_DIR/tools/generate_otmm_minimap"
GENERATED_DIR="$ROOT_DIR/tools/generated"
GENERATED_OTMM="$GENERATED_DIR/minimap.otmm"
CLIENT_ZIP="${1:-$ROOT_DIR/client_pokewarden.zip}"

MAP_NAME="$(
  awk -F'=' '
    /^[[:space:]]*mapName[[:space:]]*=/ {
      gsub(/[[:space:]"]/, "", $2)
      print $2
      exit
    }
  ' "$ROOT_DIR/config.lua"
)"

if [[ -z "$MAP_NAME" ]]; then
  echo "Could not determine mapName from $ROOT_DIR/config.lua" >&2
  exit 1
fi

ITEMS_FILE="$ROOT_DIR/data/items/items.otb"
MAP_FILE="$ROOT_DIR/data/world/${MAP_NAME}.otbm"

mkdir -p "$GENERATED_DIR"

g++ \
  -std=c++17 \
  -O2 \
  -Isrc \
  "$GENERATOR_SRC" \
  "$ROOT_DIR/src/fileloader.cpp" \
  -o "$GENERATOR_BIN" \
  -lz \
  -lboost_iostreams

"$GENERATOR_BIN" "$ITEMS_FILE" "$MAP_FILE" "$GENERATED_OTMM"

if [[ ! -f "$CLIENT_ZIP" ]]; then
  echo "Generated OTMM at $GENERATED_OTMM, but client zip was not found at $CLIENT_ZIP" >&2
  exit 0
fi

CLIENT_ZIP="$CLIENT_ZIP" GENERATED_OTMM="$GENERATED_OTMM" python3 - <<'PY'
import os
from pathlib import Path
import shutil
from tempfile import NamedTemporaryFile
from zipfile import ZIP_DEFLATED, ZipFile

client_zip = os.environ["CLIENT_ZIP"]
generated_otmm = os.environ["GENERATED_OTMM"]
archive_path = "OTCLIENT POKEWARDEN/data/minimap.otmm"

client_zip_path = Path(client_zip)

with ZipFile(client_zip_path, "r") as source_zip, NamedTemporaryFile(
    delete=False,
    suffix=".zip",
    dir=Path(generated_otmm).parent,
) as tmp_file:
    tmp_path = Path(tmp_file.name)

with ZipFile(client_zip_path, "r") as source_zip, ZipFile(tmp_path, "w", compression=ZIP_DEFLATED) as target_zip:
    for zip_info in source_zip.infolist():
        if zip_info.filename == archive_path:
            continue
        target_zip.writestr(zip_info, source_zip.read(zip_info.filename))

    target_zip.write(generated_otmm, archive_path)

shutil.move(str(tmp_path), client_zip_path)

print(f"Updated {client_zip} with {archive_path}")
PY

echo "Client minimap package refreshed successfully."
