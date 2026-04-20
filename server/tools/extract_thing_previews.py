#!/usr/bin/env python3
"""
Extrai previews de item IDs do Tibia.dat/Tibia.spr e gera uma contact sheet BMP.

Uso:
  python3 tools/extract_thing_previews.py \
    --dat /root/nordemon-client/data/things/1098/Tibia.dat \
    --spr /root/nordemon-client/data/things/1098/Tibia.spr \
    --start 34158 --count 180 \
    --out /tmp/pokeballs_alive_34158.bmp
"""

from __future__ import annotations

import argparse
import math
import os
import struct
import zlib
from dataclasses import dataclass


THING_LAST_ATTR = 255
GAME_SPRITES_U32 = True
GAME_SPRITES_ALPHA = True
GAME_ENHANCED_ANIMATIONS = True
CLIENT_VERSION = 1098
ITEM_FIRST_ID = 100
SPRITE_SIZE = 32


def read_u8(f):
    return struct.unpack("<B", f.read(1))[0]


def read_i8(f):
    return struct.unpack("<b", f.read(1))[0]


def read_u16(f):
    return struct.unpack("<H", f.read(2))[0]


def read_u32(f):
    return struct.unpack("<I", f.read(4))[0]


def skip_exact(f, size: int):
    if size > 0:
        f.seek(size, os.SEEK_CUR)


def normalize_attr(attr: int) -> int:
    if CLIENT_VERSION >= 1000:
        if attr == 16:
            return 253  # ThingAttrNoMoveAnimation
        if attr > 16:
            return attr - 1
    return attr


def skip_attr_payload(f, attr: int):
    if attr == 24:  # ThingAttrDisplacement
        skip_exact(f, 4)
    elif attr == 21:  # ThingAttrLight
        skip_exact(f, 4)
    elif attr == 33:  # ThingAttrMarket
        skip_exact(f, 6)
        strlen = read_u16(f)
        skip_exact(f, strlen)
        skip_exact(f, 4)
    elif attr == 25:  # ThingAttrElevation
        skip_exact(f, 2)
    elif attr in (34, 0, 8, 9, 28, 32, 29):  # usable, ground, writable...
        skip_exact(f, 2)
    elif attr == 38:  # ThingAttrBones
        skip_exact(f, 16)
    else:
        return


def skip_animator(f, animation_phases: int):
    if animation_phases <= 1 or not GAME_ENHANCED_ANIMATIONS:
        return
    skip_exact(f, 1)  # async
    skip_exact(f, 4)  # loop count
    skip_exact(f, 1)  # start phase
    skip_exact(f, animation_phases * 8)  # min/max phase durations


@dataclass
class ThingInfo:
    item_id: int
    width: int
    height: int
    layers: int
    pattern_x: int
    pattern_y: int
    pattern_z: int
    animation_phases: int
    sprites: list[int]


def parse_item_thing(f, item_id: int) -> ThingInfo:
    while True:
        attr = read_u8(f)
        if attr == THING_LAST_ATTR:
            break
        attr = normalize_attr(attr)
        skip_attr_payload(f, attr)

    width = read_u8(f)
    height = read_u8(f)
    if width > 1 or height > 1:
        _real_size = read_u8(f)

    layers = read_u8(f)
    pattern_x = read_u8(f)
    pattern_y = read_u8(f)
    pattern_z = read_u8(f)
    animation_phases = read_u8(f)

    skip_animator(f, animation_phases)

    total_sprites = width * height * layers * pattern_x * pattern_y * pattern_z * animation_phases
    sprites = [read_u32(f) if GAME_SPRITES_U32 else read_u16(f) for _ in range(total_sprites)]

    return ThingInfo(
        item_id=item_id,
        width=width,
        height=height,
        layers=layers,
        pattern_x=pattern_x,
        pattern_y=pattern_y,
        pattern_z=pattern_z,
        animation_phases=animation_phases,
        sprites=sprites,
    )


def load_item_things(dat_path: str, start_id: int, end_id: int) -> list[ThingInfo]:
    out: list[ThingInfo] = []
    with open(dat_path, "rb") as f:
        _signature = read_u32(f)
        counts = [read_u16(f) + 1 for _ in range(4)]
        item_count = counts[0]

        for item_id in range(ITEM_FIRST_ID, item_count):
            thing = parse_item_thing(f, item_id)
            if start_id <= item_id <= end_id:
                out.append(thing)
            if item_id > end_id:
                break
    return out


def load_sprite_offsets(spr_path: str) -> tuple[object, list[int]]:
    f = open(spr_path, "rb")
    _signature = read_u32(f)
    sprites_count = read_u32(f) if GAME_SPRITES_U32 else read_u16(f)
    offsets = [0] * (sprites_count + 1)
    for sprite_id in range(1, sprites_count + 1):
        offsets[sprite_id] = read_u32(f)
    return f, offsets


def decode_sprite(f, offsets: list[int], sprite_id: int) -> bytearray:
    pixels = bytearray(SPRITE_SIZE * SPRITE_SIZE * 4)
    if sprite_id <= 0 or sprite_id >= len(offsets):
        return pixels
    addr = offsets[sprite_id]
    if addr == 0:
        return pixels

    f.seek(addr)
    skip_exact(f, 3)  # color key
    pixel_data_size = read_u16(f)

    write_pos = 0
    read_total = 0
    while read_total < pixel_data_size and write_pos < len(pixels):
        transparent = read_u16(f)
        colored = read_u16(f)
        write_pos += transparent * 4

        for _ in range(colored):
            if write_pos + 3 >= len(pixels):
                break
            pixels[write_pos + 0] = read_u8(f)
            pixels[write_pos + 1] = read_u8(f)
            pixels[write_pos + 2] = read_u8(f)
            pixels[write_pos + 3] = read_u8(f) if GAME_SPRITES_ALPHA else 255
            write_pos += 4

        read_total += 4 + (4 * colored if GAME_SPRITES_ALPHA else 3 * colored)
    return pixels


def blit_rgba(dst: bytearray, dst_w: int, dst_h: int, src: bytearray, src_w: int, src_h: int, off_x: int, off_y: int):
    for sy in range(src_h):
        dy = off_y + sy
        if dy < 0 or dy >= dst_h:
            continue
        for sx in range(src_w):
            dx = off_x + sx
            if dx < 0 or dx >= dst_w:
                continue
            sidx = (sy * src_w + sx) * 4
            didx = (dy * dst_w + dx) * 4
            sa = src[sidx + 3]
            if sa == 0:
                continue
            dst[didx + 0] = src[sidx + 0]
            dst[didx + 1] = src[sidx + 1]
            dst[didx + 2] = src[sidx + 2]
            dst[didx + 3] = 255


def compose_preview(thing: ThingInfo, spr_file, offsets: list[int]) -> tuple[int, int, bytearray]:
    width = thing.width * SPRITE_SIZE
    height = thing.height * SPRITE_SIZE
    canvas = bytearray(width * height * 4)

    # Usa apenas layer 0, pattern 0, anim phase 0 para preview.
    idx = 0
    for h in range(thing.height):
        for w in range(thing.width):
            sprite_id = thing.sprites[idx] if idx < len(thing.sprites) else 0
            idx += 1
            sprite = decode_sprite(spr_file, offsets, sprite_id)
            x = (thing.width - w - 1) * SPRITE_SIZE
            y = (thing.height - h - 1) * SPRITE_SIZE
            blit_rgba(canvas, width, height, sprite, SPRITE_SIZE, SPRITE_SIZE, x, y)

    return width, height, canvas


FONT = {
    "0": ["111", "101", "101", "101", "111"],
    "1": ["010", "110", "010", "010", "111"],
    "2": ["111", "001", "111", "100", "111"],
    "3": ["111", "001", "111", "001", "111"],
    "4": ["101", "101", "111", "001", "001"],
    "5": ["111", "100", "111", "001", "111"],
    "6": ["111", "100", "111", "101", "111"],
    "7": ["111", "001", "010", "010", "010"],
    "8": ["111", "101", "111", "101", "111"],
    "9": ["111", "101", "111", "001", "111"],
}


def put_pixel(img: bytearray, w: int, h: int, x: int, y: int, rgb: tuple[int, int, int]):
    if x < 0 or y < 0 or x >= w or y >= h:
        return
    i = (y * w + x) * 4
    img[i + 0], img[i + 1], img[i + 2], img[i + 3] = rgb[0], rgb[1], rgb[2], 255


def draw_text(img: bytearray, w: int, h: int, x: int, y: int, text: str, rgb=(20, 20, 20)):
    cursor = x
    for ch in text:
        glyph = FONT.get(ch)
        if not glyph:
            cursor += 4
            continue
        for gy, row in enumerate(glyph):
            for gx, bit in enumerate(row):
                if bit == "1":
                    put_pixel(img, w, h, cursor + gx, y + gy, rgb)
        cursor += 4


def _png_chunk(chunk_type: bytes, data: bytes) -> bytes:
    return (
        struct.pack(">I", len(data))
        + chunk_type
        + data
        + struct.pack(">I", zlib.crc32(chunk_type + data) & 0xFFFFFFFF)
    )


def save_png(path: str, width: int, height: int, rgba: bytearray):
    raw = bytearray()
    stride = width * 4
    for y in range(height):
        raw.append(0)  # filter type 0
        start = y * stride
        raw.extend(rgba[start:start + stride])

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    idat = zlib.compress(bytes(raw), level=9)
    png = b"\x89PNG\r\n\x1a\n"
    png += _png_chunk(b"IHDR", ihdr)
    png += _png_chunk(b"IDAT", idat)
    png += _png_chunk(b"IEND", b"")

    with open(path, "wb") as f:
        f.write(png)


def build_contact_sheet(things: list[ThingInfo], previews: dict[int, tuple[int, int, bytearray]], out_path: str):
    cols = 6
    cell_w = 84
    cell_h = 58
    rows = math.ceil(len(things) / cols)
    width = cols * cell_w
    height = rows * cell_h
    canvas = bytearray(width * height * 4)

    for i in range(width * height):
        canvas[i * 4 + 0] = 245
        canvas[i * 4 + 1] = 245
        canvas[i * 4 + 2] = 245
        canvas[i * 4 + 3] = 255

    for index, thing in enumerate(things):
        col = index % cols
        row = index // cols
        x0 = col * cell_w
        y0 = row * cell_h

        for y in range(y0 + 12, y0 + cell_h):
            for x in range(x0, x0 + cell_w):
                put_pixel(canvas, width, height, x, y, (255, 255, 255))

        for x in range(x0, x0 + cell_w):
            put_pixel(canvas, width, height, x, y0, (200, 200, 200))
            put_pixel(canvas, width, height, x, y0 + cell_h - 1, (200, 200, 200))
        for y in range(y0, y0 + cell_h):
            put_pixel(canvas, width, height, x0, y, (200, 200, 200))
            put_pixel(canvas, width, height, x0 + cell_w - 1, y, (200, 200, 200))

        draw_text(canvas, width, height, x0 + 4, y0 + 3, str(thing.item_id))

        pw, ph, rgba = previews[thing.item_id]
        off_x = x0 + (cell_w - pw) // 2
        off_y = y0 + 18 + (cell_h - 18 - ph) // 2
        blit_rgba(canvas, width, height, rgba, pw, ph, off_x, off_y)

    save_png(out_path, width, height, canvas)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dat", required=True)
    parser.add_argument("--spr", required=True)
    parser.add_argument("--start", type=int, required=True)
    parser.add_argument("--count", type=int, required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    end_id = args.start + args.count - 1
    things = load_item_things(args.dat, args.start, end_id)
    spr_file, offsets = load_sprite_offsets(args.spr)
    try:
        previews = {}
        for thing in things:
            previews[thing.item_id] = compose_preview(thing, spr_file, offsets)
        build_contact_sheet(things, previews, args.out)
    finally:
        spr_file.close()

    print(f"Gerado: {args.out}")
    print(f"IDs: {args.start}..{end_id}")
    print(f"Itens encontrados: {len(things)}")


if __name__ == "__main__":
    main()
