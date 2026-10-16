"""Exports the dashboards for the game: the PNGs (plates, state sprites, lever tabs, radio faces, the blanking plate)
and two generated Lua files the code reads: ZeD/DashPx.lua (every dash's live parts, hits and anchors; the radio faces;
the sticker) and ZeD/PixelFonts.lua (the two pixel fonts).

usage: python export_lua.py <mod root, the folder that holds 42/>   (default: ./out/mod/ZeD-UI)
Runs as rect lists [x, y, w, h, ...] in plate pixels: vertically adjacent runs of the same span are merged.
"""
import json
import os
import sys
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

import build
import dashlib
import designs as DZ
import radios
from engine import F35, F57

HERE = os.path.dirname(os.path.abspath(__file__))
STICKER_TEX = "media/textures/shirtdecals/Buisness_SpiffosDECAL.png"     # the game's own Spiffo's decal, drawn at runtime
STICKER_SRC = "/mnt/user-data/uploads/Project Zomboid/SteamApps/common/ProjectZomboid/" + STICKER_TEX


def rects_of_runs(runs):
    """[[x, y, w], ...] -> flat [x, y, w, h, ...], merging a run into the one above it when x and w match"""
    by = {}
    for x, y, w in runs: by.setdefault(y, []).append((x, w))
    open_ = {}          # (x, w) -> [x, y0, w, h]
    out = []
    for y in sorted(by):
        row = set(by[y])
        nxt = {}
        for (x, w) in row:
            r = open_.get((x, w))
            if r is not None and r[1] + r[3] == y:
                r[3] += 1; nxt[(x, w)] = r
            else:
                r = [x, y, w, 1]; nxt[(x, w)] = r; out.append(r)
        open_ = nxt
    flat = []
    for r in sorted(out, key=lambda r: (r[1], r[0])): flat += r
    return flat


def convert_part(p):
    q = {}
    for k, v in p.items():
        if v is None: continue
        if k == "runs": q["r"] = rects_of_runs(v)
        elif k == "halo": q["halo"] = rects_of_runs(v)
        elif k == "letters": q["letters"] = {ch: rects_of_runs(r) for ch, r in v.items()}
        elif k == "bars": q["bars"] = [rects_of_runs(r) for r in v]
        elif isinstance(v, float): q[k] = round(v, 2)
        else: q[k] = v
    return q


# ---------------------------------------------------------------------------- Lua serialisation
def lua_str(s):
    s = str(s)
    if s == "·": return "string.char(183)"
    out = s.replace("\\", "\\\\").replace('"', '\\"')
    if "·" in out:
        parts = out.split("·")
        return " .. string.char(183) .. ".join('"' + p + '"' for p in parts)
    return '"' + out + '"'


def is_ident(k):
    import keyword
    return isinstance(k, str) and k.replace("_", "a").isalnum() and not k[0].isdigit() and k not in (
        "and", "break", "do", "else", "elseif", "end", "false", "for", "function", "if", "in", "local", "nil", "not", "or",
        "repeat", "return", "then", "true", "until", "while")


def to_lua(o, ind=0, inline=False):
    sp = "  " * ind
    if o is None: return "nil"
    if o is True: return "true"
    if o is False: return "false"
    if isinstance(o, (int, np.integer)): return str(int(o))
    if isinstance(o, (float, np.floating)):
        f = float(o); return str(int(f)) if f == int(f) else repr(round(f, 3))
    if isinstance(o, str): return lua_str(o)
    if isinstance(o, (list, tuple)):
        if all(isinstance(v, (int, float, np.integer, np.floating)) for v in o):
            return "{" + ",".join(to_lua(v) for v in o) + "}"
        if all(isinstance(v, str) and len(v) <= 8 for v in o):
            return "{ " + ", ".join(to_lua(v) for v in o) + " }"
        if inline or len(o) == 0:
            return "{ " + ", ".join(to_lua(v, ind + 1, True) for v in o) + " }"
        return "{\n" + "".join(sp + "  " + to_lua(v, ind + 1) + ",\n" for v in o) + sp + "}"
    if isinstance(o, dict):
        items = []
        for k, v in o.items():
            if v is None: continue
            key = k if is_ident(k) else "[" + (lua_str(k) if isinstance(k, str) else str(k)) + "]"
            items.append((key, v))
        simple = all(not isinstance(v, (dict, list, tuple)) or (isinstance(v, (list, tuple)) and all(
            isinstance(x, (int, float, np.integer, np.floating)) for x in v)) for _, v in items)
        if inline or (simple and sum(len(str(v)) for _, v in items) < 900):
            return "{ " + ", ".join(f"{k} = {to_lua(v, ind + 1, True)}" for k, v in items) + " }"
        return "{\n" + "".join(f"{sp}  {k} = {to_lua(v, ind + 1)},\n" for k, v in items) + sp + "}"
    raise TypeError(type(o))


# the car a design is drawn for, as its badges name it when the game's name for a car carries no maker
# ("Spiffo Van", "Creature Cruiser", "Taxi"): the maker and model out of the design's title, else these
MAKERS = ("CHEVALIER", "DASH", "FRANKLIN", "MASTERSON", "MERCIA")
BASE_CAR = {"police": ("CHEVALIER", "NYALA"), "taxi": ("CHEVALIER", "NYALA"), "ambulance": ("FRANKLIN", "VALULINE"), "race": ("RACE", "CAR")}


def base_car(did, title):
    words = title.upper().split()
    for i, w in enumerate(words[:-1]):
        if w in MAKERS: return w, " ".join(words[i + 1:])
    if did not in BASE_CAR: raise SystemExit(f"{did}: the title '{title}' names no maker; add the design's car to BASE_CAR")
    return BASE_CAR[did]


# ---------------------------------------------------------------------------- the export
def main(root):
    tex_dir = os.path.join(root, "42", "media", "textures", "ZeD", "dashpx")
    lua_dir = os.path.join(root, "42", "media", "lua", "client", "ZeD")
    os.makedirs(tex_dir, exist_ok=True); os.makedirs(lua_dir, exist_ok=True)
    heads = radios.build()
    blank = Image.open(os.path.join(radios.OUT, "hu_blank.png"))
    blank.save(os.path.join(tex_dir, "hu_blank.png"))
    shared = set()
    data = {"w": dashlib.W, "h": dashlib.H, "hintRight": dashlib.HINT_X1, "designs": {}, "heads": {}, "order": DZ.ORDER}
    sizes = {}
    for did in DZ.ORDER:
        title, cabin, seed, fn, sub, unit, radio = DZ.DESIGNS[did]
        b, base, sprites, doc, dt = build.build_one(did)
        if b.warnings: raise SystemExit(f"{did}: placement warnings, fix before export: {b.warnings}")
        base.save(os.path.join(tex_dir, f"dash_{did}.png"))
        spr = {}
        for name, im in sprites.items():
            if name in dashlib.TAB_SPRITES:
                if name not in shared: im.save(os.path.join(tex_dir, f"{name}.png")); shared.add(name)
            else:
                im.save(os.path.join(tex_dir, f"{name}.png"))
            spr[name] = [im.width, im.height]
        meta = doc["meta"]
        make, model = base_car(did, title)
        des = {
            "plate": f"dash_{did}", "sub": sub, "make": make, "model": model, "sprites": spr,
            "console": {"x": meta["console"][0], "y": meta["console"][1], "w": meta["console"][2], "h": meta["console"][3]},
            "parts": [convert_part(p) for p in doc["parts"]],
            "hits": [{k: v for k, v in h.items() if v is not None} for h in doc["hits"]],
        }
        if "headunit" in meta:
            x, y, w, h = meta["headunit"]; des["headunit"] = {"x": x, "y": y, "w": w, "h": h}
        # the two words the game prints along the top edge (PASSENGER at the left, the gamepad hint at the right)
        # take a dark ink where that edge is a light paint (the ambulance); elsewhere cream with a dark shadow
        for key, (x0, x1) in (("passInk", (10, 62)), ("hintInk", (dashlib.HINT_X0, dashlib.HINT_X1 + 1))):
            a = np.asarray(base.convert("RGBA"), dtype=float)[1:9, x0:x1]
            solid = a[..., 3] > 127
            if solid.mean() > 0.8:
                px = a[solid]
                lum = float((0.2126 * px[:, 0] + 0.7152 * px[:, 1] + 0.0722 * px[:, 2]).mean() / 255.0)
                if lum > 0.5: des[key] = "#1c1c1a"
        data["designs"][did] = des
    for kind, (img, parts) in heads.items():
        img.save(os.path.join(tex_dir, f"dhead_{kind}.png"))
        data["heads"][kind] = {"tex": f"dhead_{kind}", "w": img.width, "h": img.height, "parts": parts}
    # the sticker: the game's decal at one texel a plate pixel, on a die-cut backing 2 px proud of its outline
    if os.path.exists(STICKER_SRC):
        a = np.array(Image.open(STICKER_SRC).convert("RGBA"))[..., 3] > 24
        pad = 2
        m = np.zeros((a.shape[0] + 2 * pad, a.shape[1] + 2 * pad), bool)
        m[pad:pad + a.shape[0], pad:pad + a.shape[1]] = a
        yy, xx = np.mgrid[-pad:pad + 1, -pad:pad + 1]
        m = ndi.binary_dilation(m, structure=(xx ** 2 + yy ** 2) <= pad * pad + 0.5)
        m = ndi.binary_fill_holes(m)
        runs = dashlib.runs_of(m)
        data["sticker"] = {"tex": STICKER_TEX, "w": int(a.shape[1]), "h": int(a.shape[0]), "pad": pad,
                           "backing": rects_of_runs(runs), "color": "#ece8dc", "rim": "#b9b3a3"}
    else:
        print("warning: the decal was not staged; the sticker backing is a plain rectangle")
        data["sticker"] = {"tex": STICKER_TEX, "w": 64, "h": 64, "pad": 2, "backing": [0, 0, 68, 68], "color": "#ece8dc", "rim": "#b9b3a3"}
    head = ("-- GENERATED by ZeDUI/tools/dashpx/export_lua.py - do not edit.\n"
            "-- The pixel-art dashboards (director, Oct 16 2026): per design the plate, its state sprites, the live parts\n"
            "-- the game draws (needles, ribbons, lamps, LEDs, gear letters, digits, bars, knob pointers, lever tabs,\n"
            "-- badges, the clock, the fare meter, the climate readout, the radio slot) and the click areas, all in plate\n"
            "-- pixels (800 x 172; one plate pixel = one screen pixel at 1080p, whole multiples above). Rect lists are\n"
            "-- flat {x, y, w, h, ...}. Angles are screen degrees: 0 = right, 90 = down. Read by ZeD_Dashboard.lua.\n"
            "ZeD = ZeD or {}\n")
    with open(os.path.join(lua_dir, "DashPx.lua"), "w") as f:
        f.write(head + "ZeD.DashPx = " + to_lua(data) + "\n")
    fonts = {"35": F35, "57": F57}
    with open(os.path.join(lua_dir, "PixelFonts.lua"), "w") as f:
        f.write("-- GENERATED by ZeDUI/tools/dashpx/export_lua.py - do not edit.\n"
                "-- The dashboards' two pixel fonts: 3 x 5 for legends, 5 x 7 for badges and readouts. Each glyph is its\n"
                "-- rows top to bottom, '1' = ink. Kahlua strings are Java strings, so the middle dot is string.char(183).\n"
                "ZeD = ZeD or {}\nZeD.PixelFonts = " + to_lua(fonts) + "\n")
    print("wrote", os.path.join(lua_dir, "DashPx.lua"), os.path.getsize(os.path.join(lua_dir, "DashPx.lua")), "bytes")
    print("textures", len(os.listdir(tex_dir)))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "out", "mod", "ZeD-UI"))
