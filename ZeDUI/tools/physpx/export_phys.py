"""Exports the machine plates for the game: every plate's picture and state sprites (PNG) and ZeD/PhysPx.lua, the data
the shared plate template (ZeD_Plate.lua) draws them from: per plate its size, its live parts and its click areas, plus
which of the game's tiles, generator items and radio faces use which plate. Also rewrites ZeD/PixelFonts.lua (the two
pixel fonts, shared with the dashboards).

usage: python export_phys.py [mod root, the folder that holds 42/]   (default: ./out/mod/ZeD-UI)
Rect lists are flat {x, y, w, h, ...} in plate pixels. Angles are screen degrees: 0 = right, 90 = down.
"""
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from physlib import build                                    # noqa: E402  (puts the dash tools on the path)
from plates import DESIGNS                                   # noqa: E402
from export_lua import to_lua, rects_of_runs, write_fonts    # noqa: E402  (the dash exporter's serialiser and fonts)

TEXDIR = "media/textures/ZeD/physpx/"

# the game's tiles -> plates (appliances_cooking_01: the IsoStove ovens and microwaves, the propane barbecues)
TILE_PLATES = [
    (range(0, 4), "oven_green"), (range(4, 8), "oven_grey"), (range(8, 12), "oven_red"), (range(12, 16), "oven_modern"),
    (range(20, 24), "oven_industrial"), (range(24, 28), "mw_white"), (range(28, 32), "mw_chrome"),
    (range(36, 40), "grill_propane"), (range(44, 48), "grill_propane"), (range(40, 44), "oven_large"), (range(48, 52), "oven_large"),
    (range(52, 56), "fryer"),
]
# the generator items -> plates (IsoGenerator:getGeneratorItemType)
ITEM_PLATES = {"Base.Generator": "gen_red", "Base.Generator_Yellow": "gen_yellow", "Base.Generator_Blue": "gen_blue",
               "Base.Generator_Old": "gen_old"}
# the radio faces (ZeD.RadioOps.kindOf) -> plates
RADIO_PLATES = {"premium": "radio_premium", "valutech": "radio_valutech", "makeshift": "radio_makeshift", "ham": "radio_ham",
                "army": "radio_army", "hammake": "radio_hammake"}
# the two-way radios in the radio tab (director, Oct 25 2026): an item by its full type, a placed set (IsoWaveSignal) by
# the item it was placed from or else its tile (appliances_com_01, the items' WorldObjectSprite and its turns)
TWOWAY_ITEMS = {"Base.WalkieTalkie1": "walkie_toy", "Base.WalkieTalkie2": "walkie_valutech", "Base.WalkieTalkie3": "walkie_premium",
                "Base.WalkieTalkie4": "walkie_tactical", "Base.WalkieTalkie5": "walkie_army",
                "Base.WalkieTalkieMakeShift": "walkie_makeshift", "Base.ManPackRadio": "walkie_manpack",
                "Base.HamRadio1": "ham_civilian", "Base.HamRadio2": "ham_army", "Base.HamRadioMakeShift": "ham_makeshift"}
TWOWAY_TILES = [(range(0, 4), "ham_civilian"), (range(8, 12), "ham_army"), (range(16, 20), "walkie_toy"),
                (range(24, 28), "walkie_valutech"), (range(32, 36), "walkie_premium"), (range(40, 44), "walkie_tactical"),
                (range(48, 52), "walkie_army"), (range(56, 60), "ham_makeshift"), (range(64, 68), "walkie_makeshift")]
# a machine the tables above do not name (a modded oven, a modded generator) borrows one of these
FALLBACK = {"oven": "oven_modern", "micro": "mw_white", "generator": "gen_red", "propane": "grill_propane"}


def norm(v):
    """numbers as the data holds them: floats to 3 places (the previews draw from the same rounded data)"""
    if isinstance(v, (bool, np.bool_)): return bool(v)
    if isinstance(v, (int, np.integer)): return int(v)
    if isinstance(v, (float, np.floating)):
        f = round(float(v), 3)
        return int(f) if f == int(f) else f
    if isinstance(v, (list, tuple)): return [norm(x) for x in v]
    if isinstance(v, dict): return {k: norm(x) for k, x in v.items() if x is not None}
    return v


def convert_part(p, pid):
    q = {}
    for k, v in p.items():
        if v is None: continue
        if k == "runs": q["r"] = rects_of_runs(v)
        elif k == "halo": q["halo"] = rects_of_runs(v)
        elif k == "bars" and p.get("t") == "bars": q["bars"] = [rects_of_runs(r) for r in v]
        elif k == "sprite": q["sprite"] = f"{pid}_{v}"
        else: q[k] = norm(v)
    return q


def build_plate(pid):
    """-> (data for PhysPx.lua, the base picture, {sprite name: picture})"""
    D = DESIGNS[pid]
    p, base, sprites = build(D["fn"], D["variants"], **D.get("base", {}))
    if D.get("post"): D["post"](p)
    if p.warnings: raise SystemExit(f"{pid}: placement warnings, fix before export: {p.warnings}")
    data = {"w": p.W, "h": p.H, "plate": pid, "title": D["title"],
            "parts": [convert_part(q, pid) for q in p.parts],
            "hits": [{k: v for k, v in h.items() if v is not None} for h in p.hits]}
    for k, v in p.meta.items(): data[k] = norm(v)
    return data, base, {f"{pid}_{n}": im for n, im in sprites.items()}


def export(root, only=None):
    tex_dir = os.path.join(root, "42", *TEXDIR.strip("/").split("/"))
    lua_dir = os.path.join(root, "42", "media", "lua", "client", "ZeD")
    os.makedirs(tex_dir, exist_ok=True); os.makedirs(lua_dir, exist_ok=True)
    plates = {}
    pictures = {}
    for pid in (only or DESIGNS):
        data, base, sprites = build_plate(pid)
        base.save(os.path.join(tex_dir, f"{pid}.png"))
        for name, im in sprites.items(): im.save(os.path.join(tex_dir, f"{name}.png"))
        plates[pid] = data
        pictures[pid] = (base, sprites)
        print(f"{pid:16s} {data['w']}x{data['h']} parts {len(data['parts']):2d} hits {len(data['hits']):2d} sprites {len(sprites)}")
    tiles = {}
    for rng, pid in TILE_PLATES:
        for i in rng: tiles[f"appliances_cooking_01_{i}"] = pid
    twTiles = {}
    for rng, pid in TWOWAY_TILES:
        for i in rng: twTiles[f"appliances_com_01_{i}"] = pid
    out = {"texdir": TEXDIR, "plates": plates, "tiles": tiles, "items": ITEM_PLATES, "radios": RADIO_PLATES, "fallback": FALLBACK,
           "twoway": {"items": TWOWAY_ITEMS, "tiles": twTiles}}
    head = ("-- GENERATED by ZeDUI/tools/physpx/export_phys.py - do not edit.\n"
            "-- The machine plates in pixel art (director, Oct 16 2026): the ovens, microwaves and the fryer, the four\n"
            "-- generators, the propane grill, the six car radios, the siren controller and the ten two-way radios. Per\n"
            "-- plate: its size, its picture (texdir .. plate .. \".png\"), its live parts and its click areas, all in plate\n"
            "-- pixels (one plate pixel = one screen pixel at 1080p, whole multiples above). The shared plate template\n"
            "-- (ZeD_Plate.lua) draws them.\n"
            "-- tiles / items / radios: which plate the game's tiles, generator items and radio faces use; fallback: what an\n"
            "-- unknown (modded) machine borrows; twoway: the two-way radios' faces by item and by placed tile. Rect lists\n"
            "-- are flat {x, y, w, h, ...}; angles are screen degrees.\n"
            "ZeD = ZeD or {}\n")
    with open(os.path.join(lua_dir, "PhysPx.lua"), "w", newline="\n") as f:
        f.write(head + "ZeD.PhysPx = " + to_lua(out) + "\nreturn ZeD.PhysPx\n")
    write_fonts(lua_dir)
    print("wrote", os.path.join(lua_dir, "PhysPx.lua"), os.path.getsize(os.path.join(lua_dir, "PhysPx.lua")), "bytes;",
          len(os.listdir(tex_dir)), "textures")
    return out, pictures


if __name__ == "__main__":
    export(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "out", "mod", "ZeD-UI"))
