#!/usr/bin/env python3
import argparse
import struct
from pathlib import Path


START = 0xFE
END = 0xFF
ESCAPE = 0xFD

ITEM_ATTR_SERVERID = 0x10
ITEM_ATTR_CLIENTID = 0x11


def unescape_props(data: bytes) -> bytes:
    out = bytearray()
    i = 0
    size = len(data)
    while i < size:
        byte = data[i]
        if byte == ESCAPE:
            i += 1
            if i >= size:
                break
            out.append(data[i])
        else:
            out.append(byte)
        i += 1
    return bytes(out)


def parse_otb_pairs(path: Path) -> dict[int, int]:
    raw = path.read_bytes()
    if len(raw) < 6 or raw[:4] not in (b"OTBI", b"\x00\x00\x00\x00"):
        raise ValueError("items.otb invalido")

    i = 4
    stack = []
    root = {"children": [], "props_begin": None, "props_end": None, "type": None}
    current = root

    if raw[i] != START:
        raise ValueError("items.otb invalido")
    i += 1
    root["type"] = raw[i]
    i += 1
    root["props_begin"] = i
    stack.append(root)

    while i < len(raw):
        byte = raw[i]
        if byte == START:
            parent = stack[-1]
            if not parent["children"]:
                parent["props_end"] = i
            i += 1
            child = {"children": [], "props_begin": i + 1, "props_end": None, "type": raw[i]}
            parent["children"].append(child)
            stack.append(child)
        elif byte == END:
            node = stack[-1]
            if not node["children"]:
                node["props_end"] = i
            stack.pop()
            if not stack:
                break
        elif byte == ESCAPE:
            i += 1
        i += 1

    reverse = {}
    for node in root["children"]:
        props_begin = node["props_begin"]
        props_end = node["props_end"]
        if props_begin is None or props_end is None or props_end <= props_begin:
            continue

        props = memoryview(unescape_props(raw[props_begin:props_end]))
        if len(props) < 4:
            continue

        pos = 4  # flags
        server_id = 0
        client_id = 0
        while pos + 3 <= len(props):
            attr = props[pos]
            pos += 1
            data_len = struct.unpack_from("<H", props, pos)[0]
            pos += 2
            if pos + data_len > len(props):
                break
            chunk = props[pos:pos + data_len]
            pos += data_len

            if attr == ITEM_ATTR_SERVERID and data_len == 2:
                server_id = struct.unpack_from("<H", chunk, 0)[0]
                if 30000 < server_id < 30100:
                    server_id -= 30000
            elif attr == ITEM_ATTR_CLIENTID and data_len == 2:
                client_id = struct.unpack_from("<H", chunk, 0)[0]

        if server_id and client_id:
            reverse[client_id] = server_id
    return reverse


def main() -> int:
    parser = argparse.ArgumentParser(description="Converte clientId do items.otb para server item id.")
    parser.add_argument("ids", nargs="+", type=int, help="client ids para consultar")
    parser.add_argument("--otb", default="data/items/items.otb", help="caminho do items.otb")
    args = parser.parse_args()

    reverse = parse_otb_pairs(Path(args.otb))
    for client_id in args.ids:
        server_id = reverse.get(client_id)
        if server_id is None:
            print(f"{client_id}: not found")
        else:
            print(f"{client_id}: serverId={server_id}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
