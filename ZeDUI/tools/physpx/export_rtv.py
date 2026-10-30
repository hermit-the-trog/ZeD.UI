"""Exports everything export_fill.py does with the radios, the CD player, the TVs and the laundry machines added
(rtv_plates.py), then the TVs' off-air screens for every TV face, and three tables in PhysPx.lua:

    rtv     = { items = { ["Base.RadioBlack"] = "radio_black", ... } }      a radio or TV item (a placed set: the item it
                                                                              turns into when picked up) -> its plate
    laundry = { classes = { IsoClothingWasher = "washer", ... } }          a laundry machine's class -> its plate
    offair  = { channels = {...}, screens = {...}, logos = {...}, sets = { ["tv_widescreen@392"] = "offair/tv_widescreen@392/", ... } }

The radios' and laundry machines' widths and narrow faces go in the existing `widths` and `narrow` tables. Each TV
face's off-air screens are drawn at that face's screen size (its tvScreen part), the tube's round corners cut out,
the antique set's in black and white in its tube's tint, ready to draw over the screen rect as they are:
    <texdir>offair/<plate>/<screen>.png      screen = bars, standby, signoff_<channel>, snow_0..2
The two channels the game has a logo for leave a box on their card for the game's own picture (logos: the file, the
box as fractions of the screen, the tint to draw it with).
usage: python export_rtv.py [mod root]   (default: ./out/mod/ZeD-UI)"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import rtv_plates as RP              # noqa: E402  (registers the faces first)
import export_fill as EF             # noqa: E402
import export_phys as EX             # noqa: E402
import offair as O                   # noqa: E402
from export_lua import to_lua        # noqa: E402

NOTE = ("-- rtv / laundry / offair (design session Oct 30 2026, REQUEST_design_radio_tv_faces_20261030.md; the washer and\n"
        "-- dryer on the director's word): the faces for the ordinary radios, the CD player, the TVs and the laundry\n"
        "-- machines by item and by class; each TV face's off-air screens (texdir .. offair.sets[plate] .. screen .. \".png\").\n")


def screen_pictures(q):
    """every off-air screen at the tvScreen part's size, corners cut, black and white where the set has a tint"""
    w, h = q["w"], q["h"]
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, w - 1, h - 1], radius=q.get("r", 0), fill=255)
    out = {}
    for name, fn in O.screens():
        a = O.crt(fn(w, h))
        if q.get("tint"):
            lum = (a[..., 0] * 0.3 + a[..., 1] * 0.59 + a[..., 2] * 0.11)[..., None]
            a = np.clip(lum * (np.array(O.hexc(q["tint"]), np.float32) / 255) * 1.15, 0, 1)
        im = O.to_img(a).convert("RGBA")
        im.putalpha(m)
        out[name] = im
    return out


def export(root, only=None):
    out, pictures = EF.export(root, only)
    tex_dir = os.path.join(root, "42", *EX.TEXDIR.strip("/").split("/"))
    sets = {}
    for key, data in out["plates"].items():
        base = data.get("base", key[:-2] if key.endswith("_n") else key)
        if base not in RP.TVS: continue
        q = [x for x in data["parts"] if x.get("t") == "tvScreen"][0]
        sub = f"offair/{key}/"
        os.makedirs(os.path.join(tex_dir, *sub.strip("/").split("/")), exist_ok=True)
        for name, im in screen_pictures(q).items():
            im.save(os.path.join(tex_dir, *sub.strip("/").split("/"), f"{name}.png"))
        sets[key] = sub
        print(f"offair {key:24s} {q['w']}x{q['h']}{'  black and white' if q.get('tint') else ''}")
    out["rtv"] = {"items": dict(RP.ITEMS)}
    out["laundry"] = {"classes": dict(RP.CLASSES)}
    out["offair"] = {
        "channels": [{"id": cid, "name": nm, "number": n} for cid, nm, n in O.CHANNELS],
        "screens": [n for n, _ in O.screens()],
        "logos": {cid: {"file": O.GAME_LOGOS[cid], "box": list(O.LOGO_BOX[cid]),
                        "tint": list(O.LOGO_TINT.get(cid, (1.0, 1.0, 1.0)))} for cid in O.GAME_LOGOS},
        "sets": sets}
    path = os.path.join(root, "42", "media", "lua", "client", "ZeD", "PhysPx.lua")
    head = open(path, encoding="utf-8").read().split("ZeD = ZeD or {}\n")[0]
    with open(path, "w", newline="\n", encoding="utf-8") as f:
        f.write(head + NOTE + "ZeD = ZeD or {}\n" + "ZeD.PhysPx = " + to_lua(out) + "\nreturn ZeD.PhysPx\n")
    n_tex = sum(len(fs) for _, _, fs in os.walk(tex_dir))
    print("rtv:", len(RP.ITEMS), "items; laundry:", len(RP.CLASSES), "classes; offair:", len(sets), "sets;",
          n_tex, "textures in all;", os.path.getsize(path), "bytes of PhysPx.lua")
    return out, pictures


if __name__ == "__main__":
    export(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "out", "mod", "ZeD-UI"))
