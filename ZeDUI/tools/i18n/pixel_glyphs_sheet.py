"""
Contact sheet of ZeD's two pixel faces, including every extra letter.

Reads the glyph tables straight from the Lua files (PixelFonts.lua and PixelFontsExt.lua, both in
42/media/lua/client/ZeD/) and draws every glyph at a large zoom with its character printed under it,
then a few sample lines the way the game lays them out (one blank column between glyphs, lowercase
shown as capitals).

Usage: py -I pixel_glyphs_sheet.py [output.png]
"""
import os
import re
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
CLIENT = os.path.join(ROOT, "42", "media", "lua", "client", "ZeD")
DEFAULT_OUT = os.path.join(
    os.environ.get("LOCALAPPDATA", ""), "Temp", "claude", "C--Users-danie-Zomboid",
    "bc20a731-3edf-404d-99ca-934f503e9abc", "scratchpad", "pixel_glyphs.png")

BG = (24, 26, 30)
PANEL = (34, 37, 43)
INK = (232, 234, 238)
NEW_INK = (120, 210, 150)
DIM = (140, 146, 156)
GRID = (52, 56, 64)


def parse_faces():
    """{face: {char: rows}} from the base file (letters, string.char keys) and the extension (numeric keys)."""
    faces = {"35": {}, "57": {}}
    base = open(os.path.join(CLIENT, "PixelFonts.lua"), encoding="utf-8").read()
    for face in faces:
        m = re.search(r'\["%s"\] = \{(.*?)\n  \},' % face, base, re.S)
        for line in m.group(1).splitlines():
            km = re.match(r'\s*(?:\["(.)"\]|\[string\.char\((\d+)\)\]|([A-Za-z])) = \{ (.*) \},?\s*$', line)
            if not km:
                continue
            key = km.group(1) or (chr(int(km.group(2))) if km.group(2) else km.group(3))
            faces[face][key] = re.findall(r'"([01]+)"', km.group(4))
    base_keys = {f: set(faces[f]) for f in faces}
    ext_path = os.path.join(CLIENT, "PixelFontsExt.lua")
    new_keys = {"35": [], "57": []}
    if os.path.exists(ext_path):
        ext = open(ext_path, encoding="utf-8").read()
        for face in faces:
            m = re.search(r'\["%s"\] = \{(.*?)\n  \},' % face, ext, re.S)
            for line in m.group(1).splitlines():
                km = re.match(r'\s*\[(\d+)\] = \{ (.*) \},', line)
                if km:
                    ch = chr(int(km.group(1)))
                    if ch not in faces[face]:
                        faces[face][ch] = re.findall(r'"([01]+)"', km.group(2))
                        new_keys[face].append(ch)
    return faces, base_keys, new_keys


def font(size, bold=False):
    path = r"C:\Windows\Fonts\arialbd.ttf" if bold else r"C:\Windows\Fonts\arial.ttf"
    return ImageFont.truetype(path, size)


def blit(draw, x, y, rows, zoom, ink):
    for ry, row in enumerate(rows):
        for rx, c in enumerate(row):
            if c == "1":
                draw.rectangle([x + rx * zoom, y + ry * zoom, x + (rx + 1) * zoom - 1, y + (ry + 1) * zoom - 1], fill=ink)


def string_rows(face_glyphs, text, height):
    """Lay a string out the way P.text does and return the glyph rows joined with one blank column between."""
    cols = [""] * height
    first = True
    missing = []
    for ch in text:
        g = face_glyphs.get(ch) or face_glyphs.get(ch.upper())
        if g is None:
            missing.append(ch)
            g = face_glyphs[" "]
        for i in range(height):
            cols[i] += ("" if first else "0") + g[i]
        first = False
    return cols, missing


def group_chars(face_glyphs, new_chars):
    latin = [c for c in new_chars if ord(c) < 0x400 or 0x100 <= ord(c) < 0x300]
    latin = [c for c in new_chars if not (0x400 <= ord(c) < 0x500) and c.isalpha()]
    cyr = [c for c in new_chars if 0x400 <= ord(c) < 0x500]
    signs = [c for c in new_chars if not c.isalpha()]
    return sorted(latin, key=ord), sorted(cyr, key=ord), sorted(signs, key=ord)


SAMPLES = [
    "Brûlée à la crème, déjà vu, Ça va? (OK), 12:30",
    "Straße ÆØÅ Œuvre Łódź Śląsk Ñandú Çok güzel",
    "İŞ ığ Čeština Žluťoučký kůň Ďábel Řeka Ěž Ňuf",
    "Hőség Űr Șapte Țară Ăsta Ţ ŞŢ",
    "Привет, мир! Жёлтый щенок съел ёлку.",
    "Ґанок, Їжак, Єнот, Йод, Ёж",
    "СЪЕШЬ ЕЩЁ ЭТИХ МЯГКИХ БУЛОК ДА ВЫПЕЙ ЧАЮ",
]


def render(out_path):
    faces, base_keys, new_keys = parse_faces()
    f_lab = font(15)
    f_head = font(22, True)
    f_small = font(13)
    sections = []
    W = 1900
    pad = 16
    img_h = 4000
    img = Image.new("RGB", (W, img_h), BG)
    d = ImageDraw.Draw(img)
    y = pad
    d.text((pad, y), "ZeD pixel faces: contact sheet (green = new glyph, white = existing)", font=f_head, fill=INK)
    y += 40
    for face, height, zoom in (("35", 5, 9), ("57", 7, 7)):
        g = faces[face]
        name = "3 x 5 face" if face == "35" else "5 x 7 face"
        d.text((pad, y), "%s: %d glyphs, %d new" % (name, len(g), len(new_keys[face])), font=f_head, fill=INK)
        y += 36
        latin, cyr, signs = group_chars(g, new_keys[face])
        existing = [c for c in sorted(base_keys[face], key=lambda c: (not c.isalnum(), c)) if c.strip()]
        rows_of = [("existing", existing, False), ("new Latin", latin, True), ("new Cyrillic", cyr, True), ("new signs", signs, True)]
        cell_w = 8 * zoom + 18
        cell_h = height * zoom + 26
        for label, chars, is_new in rows_of:
            if not chars:
                continue
            d.text((pad, y), label, font=f_lab, fill=DIM)
            y += 22
            per_row = (W - 2 * pad) // cell_w
            for i in range(0, len(chars), per_row):
                chunk = chars[i:i + per_row]
                d.rectangle([pad, y, W - pad, y + cell_h], fill=PANEL)
                for j, ch in enumerate(chunk):
                    x = pad + 8 + j * cell_w
                    blit(d, x, y + 6, g[ch], zoom, NEW_INK if is_new else INK)
                    d.text((x, y + 6 + height * zoom + 4), ch, font=f_small, fill=DIM)
                y += cell_h + 6
            y += 6
        # sample lines at zoom, as the game lays them out
        d.text((pad, y), "samples", font=f_lab, fill=DIM)
        y += 22
        z = zoom
        for line in SAMPLES:
            rows, missing = string_rows(g, line, height)
            wpx = len(rows[0]) * z
            d.rectangle([pad, y, pad + min(wpx, W - 2 * pad) + 16, y + height * z + 12], fill=PANEL)
            # wrap-free: lines are short enough for the sheet width at these zooms
            blit(d, pad + 8, y + 6, rows, z, INK)
            y += height * z + 22
            if missing:
                d.text((pad, y - 14), "missing: " + "".join(sorted(set(missing))), font=f_small, fill=(230, 120, 120))
                y += 14
        y += 24
    img = img.crop((0, 0, W, min(img_h, y + pad)))
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    img.save(out_path)
    print("wrote", out_path, img.size)
    for face in faces:
        print(face, "glyphs:", len(faces[face]), "new:", len(new_keys[face]))


if __name__ == "__main__":
    render(sys.argv[1] if len(sys.argv) > 1 else DEFAULT_OUT)
