"""Exports the dashboards for the game: the PNGs (plates, state sprites, lever tabs, radio faces, the blanking plate)
and two generated Lua files the code reads: ZeD/DashPx.lua (every dash's live parts, hits and anchors; the radio faces;
the vans' logo stickers) and ZeD/PixelFonts.lua (the two pixel fonts).

usage: python export_lua.py <mod root, the folder that holds 42/>   (default: ./out/mod/ZeD-UI)
Runs as rect lists [x, y, w, h, ...] in plate pixels: vertically adjacent runs of the same span are merged.
"""
import json
import os
import sys
import numpy as np
from PIL import Image
try:
    from scipy import ndimage as ndi
except ImportError:          # no scipy here: the same calls in plain numpy (ndi_np.py)
    import ndi_np as ndi
    ndi.install_as_scipy()   # (the radio faces come from ../physpx, which asks for scipy by name)

import build
import dashlib
import designs as DZ
import night as NT
import radios
import v6
from engine import F35, F57

HERE = os.path.dirname(os.path.abspath(__file__))
# the vans' stickers (round 6, Oct 24 2026): a business van whose logo the game ships (v6.VAN_LOGOS) wears that decal,
# read at runtime from the game's own files (media/textures/shirtdecals); the export bakes each one's die-cut backing
DECAL_DIR = "media/textures/shirtdecals/"
GAME_ROOTS = ("/mnt/user-data/uploads/Project Zomboid/SteamApps/common/ProjectZomboid/",
              "E:/Project Zomboid/steamapps/common/ProjectZomboid/")


def decal_src(name):
    """the decal's PNG in the game's files, or None when the game is not here"""
    return next((r + DECAL_DIR + name + ".png" for r in GAME_ROOTS if os.path.exists(r + DECAL_DIR + name + ".png")), None)


WRITTEN = set()      # every picture this export wrote or found unchanged: the rest of the folder is stale (main)


def save_png(im, path):
    """write the picture unless the file already holds exactly these pixels (another PNG encoder's bytes are no change)"""
    WRITTEN.add(os.path.normcase(os.path.abspath(path)))
    if os.path.exists(path):
        try:
            old = np.asarray(Image.open(path).convert("RGBA")); new = np.asarray(im.convert("RGBA"))
            if old.shape == new.shape and (old == new).all(): return
        except OSError:
            pass
    im.save(path)


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
    # Kahlua strings are Java strings: a letter past ASCII goes in as string.char(code), never as UTF-8 bytes
    # (the middle dot 183, the degree sign 176)
    if len(s) == 1 and ord(s) > 127: return f"string.char({ord(s)})"
    out = s.replace("\\", "\\\\").replace('"', '\\"')
    if any(ord(c) > 127 for c in out):
        bits, cur = [], ""
        for c in out:
            if ord(c) > 127:
                if cur: bits.append('"' + cur + '"'); cur = ""
                bits.append(f"string.char({ord(c)})")
            else: cur += c
        if cur: bits.append('"' + cur + '"')
        return " .. ".join(bits)
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


def write_fonts(lua_dir):
    """ZeD/PixelFonts.lua: the two pixel fonts every pixel-art organism reads (the dashboards, the machine plates)"""
    fonts = {"35": F35, "57": F57}
    with open(os.path.join(lua_dir, "PixelFonts.lua"), "w", newline="\n") as f:
        f.write("-- ZeD-UI/42/media/lua/client/ZeD/PixelFonts.lua\n"
                "-- GENERATED by ZeDUI/tools/dashpx/export_lua.py - do not edit.\n"
                "-- A generated data table (client): the dashboards' two pixel fonts, 3 x 5 for\n"
                "-- legends, 5 x 7 for badges and readouts. Each glyph is its rows top to\n"
                "-- bottom, '1' = ink. Kahlua strings are Java strings, so the middle dot is\n"
                "-- string.char(183).\n"
                "ZeD = ZeD or {}\nZeD.PixelFonts = " + to_lua(fonts) + "\n")


# ---------------------------------------------------------------------------- the cabin colors
# A civilian dash ships in three cabin colors (designs.CABINS). Every color is built in full: the state sprites are
# cut from the plate and carry the vinyl round them (the key's shadow, the ash tray's face), and the night pictures are
# relit from it. The parts file must come out the same in every color; the one thing allowed to differ is a maker
# mark's model-line shadow, read off the vinyl under it (brands.py), which the parts carry as "cabin" and des.cabins
# per color. A picture that differs between colors is named <name>__<cabin>; one the same in all ships once.
CAB_SEP = "__"
CAB_KEYS = ("shadow", "tagShadow")      # the badge part fields a color may change


def _plain(o):
    """o as plain JSON values, for comparing two builds"""
    return json.loads(json.dumps(o, sort_keys=True, default=lambda v: v.tolist() if hasattr(v, "tolist") else str(v)))


def edge_inks(base):
    """the two words the game prints along the top edge (PASSENGER at the left, the gamepad hint at the right) take a
    dark ink where that edge is a light paint (the ambulance's old white); elsewhere cream with a dark shadow"""
    out = {}
    for key, (x0, x1) in (("passInk", (10, 62)), ("hintInk", (dashlib.HINT_X0, dashlib.HINT_X1 + 1))):
        a = np.asarray(base.convert("RGBA"), dtype=float)[1:9, x0:x1]
        solid = a[..., 3] > 127
        if solid.mean() > 0.8:
            px = a[solid]
            lum = float((0.2126 * px[:, 0] + 0.7152 * px[:, 1] + 0.0722 * px[:, 2]).mean() / 255.0)
            if lum > 0.5: out[key] = "#1c1c1a"
    return out


def build_cabin(did, cab, seed):
    """one color of a design, built in full and baked for the night; any placement warning stops the export"""
    b, base, sprites, doc, dt = build.build_one(did, cabin=cab)
    if b.warnings: raise SystemExit(f"{did} ({cab}): placement warnings, fix before export: {b.warnings}")
    # at night (night.py): the plate with its bulbs on, the plate in the dark, the light map, the backlit glass;
    # a dash lit in two colors (the late models' green gauges) also its tint map (tints, tmap) and needleOwn
    nimg, dimg, nd, _lv = NT.bake(did, b, base, DZ.NIGHT[did], seed=seed, needles=DZ.NEEDLES_UNDER_TINT)
    nd.pop("_tidx", None)
    print(f"  {did:10s} {cab:9s} {dt:5.1f}s", flush=True)
    return dict(cab=cab, b=b, base=base, sprites=sprites, doc=doc, nimg=nimg, dimg=dimg, nd=nd, inks=edge_inks(base))


def one_parts_file(did, runs):
    """-> the design's parts (the lead's, a color-read model-line shadow as "cabin") and {cabin: {field: color}}.
    Stops the export when the colors' parts files differ in anything else: hits, meta, sprite names and sizes, the
    marks, the head unit, the night data or the top edge's inks"""
    lead = runs[0]
    parts = [dict(p) for p in lead["doc"]["parts"]]
    p0 = _plain(lead["doc"]["parts"])
    rest0 = _plain({k: v for k, v in lead["doc"].items() if k not in ("parts", "cabin")})
    nd0 = _plain(lead["nd"])
    brand0 = _plain(lead["b"].brand)
    ink = {}
    for r in runs[1:]:
        cab = r["cab"]
        if _plain({k: v for k, v in r["doc"].items() if k not in ("parts", "cabin")}) != rest0:
            raise SystemExit(f"{did}: the {cab} build's hits, meta or sprites differ from the {lead['cab']} build's")
        if _plain(r["nd"]) != nd0: raise SystemExit(f"{did}: the {cab} build's night data differ")
        if _plain(r["b"].brand) != brand0: raise SystemExit(f"{did}: the {cab} build's marks differ")
        if r["inks"] != lead["inks"]: raise SystemExit(f"{did}: the {cab} build's top-edge inks differ")
        pc = _plain(r["doc"]["parts"])
        if len(pc) != len(p0): raise SystemExit(f"{did}: the {cab} build has {len(pc)} parts, the lead {len(p0)}")
        for i, (a, c) in enumerate(zip(p0, pc)):
            if a == c: continue
            keys = {k for k in set(a) | set(c) if a.get(k) != c.get(k)}
            if a.get("t") != "badge" or not keys <= set(CAB_KEYS):
                raise SystemExit(f"{did}: part {i} ({a.get('t')} {a.get('src', a.get('role'))}) differs in {sorted(keys)} for {cab}")
            for k in keys: parts[i][k] = "cabin"
    # every color's value for each field that became "cabin": one per color, the same on all its parts
    for r in runs:
        got = {}
        for p, q in zip(parts, r["doc"]["parts"]):
            for k in CAB_KEYS:
                if p.get(k) != "cabin": continue
                if got.setdefault(k, q[k]) != q[k]:
                    raise SystemExit(f"{did}: the {r['cab']} build's model lines have more than one {k}")
        if got: ink[r["cab"]] = got
    return parts, ink


def cabin_textures(did, runs):
    """the design's picture names that differ between its colors (the plate and the night pictures always do)"""
    names = {f"dash_{did}", runs[0]["nd"]["plate"], runs[0]["nd"]["dark"]}
    for name, im in runs[0]["sprites"].items():
        if name in dashlib.TAB_SPRITES: continue
        a = np.asarray(im.convert("RGBA"))
        for r in runs[1:]:
            o = r["sprites"].get(name)
            if o is None or o.size != im.size or not (np.asarray(o.convert("RGBA")) == a).all():
                names.add(name); break
    return names


def _pow2(n):
    v = 1
    while v < n: v <<= 1
    return v


def texture_report(tex_dir, data):
    """the game pads each texture to powers of two, 4 bytes a texel; a picture loads the first time a dash asks for it
    and stays: one car's dash costs its color's pictures, and a long session at most every picture"""
    gpu = {}
    for f in os.listdir(tex_dir):
        if f.endswith(".png"):
            w, h = Image.open(os.path.join(tex_dir, f)).size
            gpu[f[:-4]] = _pow2(w) * _pow2(h) * 4
    mib = lambda n: n / 2 ** 20
    total = sum(gpu.values())
    worst = 0.0
    for did, des in data["designs"].items():
        names = [des["plate"], des["night"]["plate"], des["night"]["dark"]] + list(des["sprites"])
        sfx = CAB_SEP + des["cabins"][0]["id"] if des.get("cabins") else ""
        tex = set(des.get("cabinTex") or ())
        one = sum(gpu.get(n + sfx if n in tex else n, 0) for n in names)
        worst = max(worst, mib(one))
    print(f"texture memory: {len(gpu)} pictures, {mib(total):.1f} MiB if every one is loaded; one car's dash at most "
          f"{worst:.2f} MiB; PNG on disk {sum(os.path.getsize(os.path.join(tex_dir, f + '.png')) for f in gpu) / 1e6:.2f} MB")


# ---------------------------------------------------------------------------- the export
def main(root):
    tex_dir = os.path.join(root, "42", "media", "textures", "ZeD", "dashpx")
    lua_dir = os.path.join(root, "42", "media", "lua", "client", "ZeD")
    os.makedirs(tex_dir, exist_ok=True); os.makedirs(lua_dir, exist_ok=True)
    heads = radios.build()
    blank = Image.open(os.path.join(radios.OUT, "hu_blank.png"))
    save_png(blank, os.path.join(tex_dir, "hu_blank.png"))
    shared = set()
    data = {"w": dashlib.W, "h": dashlib.H, "hintRight": dashlib.HINT_X1, "designs": {}, "heads": {}, "order": DZ.ORDER,
            "night": {"tint": list(NT.TINT), "amb": NT.amb_level(), "levels": NT.LEVELS}}
    sizes = {}
    data["cabinSep"] = CAB_SEP
    for did in DZ.ORDER:
        title, cabin, seed, fn, sub, unit, radio = DZ.DESIGNS[did]
        # every cabin color through the whole build (its state sprites and night pictures carry the vinyl too), each
        # one's placement checks (tab travel, movers, legends, needles) passing; then one parts file for them all
        runs = [build_cabin(did, c, seed) for c in DZ.cabins(did)]
        lead = runs[0]
        b, base, sprites, doc = lead["b"], lead["base"], lead["sprites"], lead["doc"]
        parts, cab_ink = one_parts_file(did, runs)
        cab_tex = cabin_textures(did, runs) if len(runs) > 1 else set()
        for r in runs:
            sfx = CAB_SEP + r["cab"]
            pics = [(f"dash_{did}", r["base"]), (r["nd"]["plate"], r["nimg"]), (r["nd"]["dark"], r["dimg"])]
            pics += [(name, im) for name, im in r["sprites"].items() if name not in dashlib.TAB_SPRITES]
            for name, im in pics:
                if name in cab_tex: save_png(im, os.path.join(tex_dir, name + sfx + ".png"))
                elif r is lead: save_png(im, os.path.join(tex_dir, name + ".png"))
        spr = {}
        for name, im in sprites.items():
            if name in dashlib.TAB_SPRITES and name not in shared:
                save_png(im, os.path.join(tex_dir, f"{name}.png")); shared.add(name)
            spr[name] = [im.width, im.height]
        meta = doc["meta"]
        make, model = base_car(did, title)
        des = {
            "plate": f"dash_{did}", "sub": sub, "make": make, "model": model, "sprites": spr,
            "console": {"x": meta["console"][0], "y": meta["console"][1], "w": meta["console"][2], "h": meta["console"][3]},
            "parts": [convert_part(p) for p in parts],
            "hits": [{k: v for k, v in h.items() if v is not None} for h in doc["hits"]],
        }
        if b.brand:     # the makers whose marks are cut for this console (brands.py): the game picks by the car's maker
            des["brands"] = list(b.brand["marks"])
        if "headunit" in meta:
            x, y, w, h = meta["headunit"]; des["headunit"] = {"x": x, "y": y, "w": w, "h": h}
        for key in ("passInk", "hintInk"):
            if key in lead["inks"]: des[key] = lead["inks"][key]
        nd = lead["nd"]
        nd["glass"] = [{"color": g["color"], "r": rects_of_runs(g["runs"])} for g in nd["glass"]]
        des["night"] = nd
        if len(runs) > 1:
            # the colors, lead first: the game picks one per car (ZeD_DashProto.lua) and draws each picture named in
            # cabinTex as <name>__<cabin>; the rest are the same in every color and ship once
            des["cabins"] = [dict({"id": r["cab"]}, **cab_ink.get(r["cab"], {})) for r in runs]
            des["cabinTex"] = sorted(cab_tex)
        data["designs"][did] = des
    for kind, (img, parts, sprites) in heads.items():
        save_png(img, os.path.join(tex_dir, f"dhead_{kind}.png"))
        for nm, im in sprites.items(): save_png(im, os.path.join(tex_dir, f"{nm}.png"))
        NT.head_glass(img, parts)        # the dot-matrix glass, lit from behind at night while the set is on
        data["heads"][kind] = {"tex": f"dhead_{kind}", "w": img.width, "h": img.height, "parts": parts}
    # the stickers: each logo decal at one texel a plate pixel, on a die-cut backing 2 px proud of its outline;
    # vanLogos: the van's script -> its decal
    data["stickers"] = {}
    for name in sorted(set(v6.VAN_LOGOS.values())):
        tex = DECAL_DIR + name + ".png"
        src = decal_src(name)
        if src:
            a = np.array(Image.open(src).convert("RGBA"))[..., 3] > 24
            pad = 2
            m = np.zeros((a.shape[0] + 2 * pad, a.shape[1] + 2 * pad), bool)
            m[pad:pad + a.shape[0], pad:pad + a.shape[1]] = a
            yy, xx = np.mgrid[-pad:pad + 1, -pad:pad + 1]
            m = ndi.binary_dilation(m, structure=(xx ** 2 + yy ** 2) <= pad * pad + 0.5)
            m = ndi.binary_fill_holes(m)
            runs = dashlib.runs_of(m)
            data["stickers"][name] = {"tex": tex, "w": int(a.shape[1]), "h": int(a.shape[0]), "pad": pad,
                                      "backing": rects_of_runs(runs), "color": "#ece8dc", "rim": "#b9b3a3"}
        else:
            print(f"warning: the decal {name} was not staged; its sticker backing is a plain rectangle")
            data["stickers"][name] = {"tex": tex, "w": 64, "h": 64, "pad": 2, "backing": [0, 0, 68, 68], "color": "#ece8dc", "rim": "#b9b3a3"}
    data["vanLogos"] = dict(sorted(v6.VAN_LOGOS.items()))
    # (the shipped file's house header, so an export into the mod changes nothing but the data)
    head = ("-- ZeD-UI/42/media/lua/client/ZeD/DashPx.lua\n"
            "-- ============================================================================\n"
            "-- DASHBOARD PIXEL DATA - client; generated data table. Do not edit by hand:\n"
            "-- ZeDUI/tools/dashpx/export_lua.py writes this file.\n"
            "-- The pixel-art dashboards, one entry per design: the plate, its state\n"
            "-- sprites, the live parts the game draws (needles, ribbons, lamps, LEDs,\n"
            "-- gear letters, digits, bars, knob pointers, lever tabs, badges, the clock,\n"
            "-- the fare meter, the climate readout, the radio slot) and the click areas,\n"
            f"-- all in plate pixels ({dashlib.W} x {dashlib.H}; one plate pixel = one screen pixel at\n"
            "-- 1080p, whole multiples above). Rect lists are flat {x, y, w, h, ...}.\n"
            "-- Angles are screen degrees: 0 = right, 90 = down. ZeD_Dashboard.lua reads it.\n"
            "-- ============================================================================\n"
            "ZeD = ZeD or {}\n")
    with open(os.path.join(lua_dir, "DashPx.lua"), "w", newline="\n") as f:
        f.write(head + "ZeD.DashPx = " + to_lua(data) + "\n")
    write_fonts(lua_dir)
    print("wrote", os.path.join(lua_dir, "DashPx.lua"), os.path.getsize(os.path.join(lua_dir, "DashPx.lua")), "bytes")
    # the export never leaves a picture it no longer writes (a design's old single-color plate, a renamed sprite):
    # the folder holds this export's pictures and nothing else
    for f in sorted(os.listdir(tex_dir)):
        path = os.path.join(tex_dir, f)
        if f.endswith(".png") and os.path.normcase(os.path.abspath(path)) not in WRITTEN:
            os.remove(path); print("removed stale", f)
    print("textures", len(os.listdir(tex_dir)))
    texture_report(tex_dir, data)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "out", "mod", "ZeD-UI"))
