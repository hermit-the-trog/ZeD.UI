"""Exports everything export_336.py does, then every machine plate and walkie at the other widths that fill the card
(REQUEST_design_plates_fill_20261030.md, w_plates.py), and adds the `widths` table to PhysPx.lua:

    widths = { oven_green = { [336] = "oven_green", [392] = "oven_green@392", [450] = "oven_green@450", [562] = "oven_green@562" },
               walkie_toy = { [154] = "walkie_toy@154", [180] = "walkie_toy@180", [206] = "walkie_toy@206", [257] = "walkie_toy@257" }, ... }

Each "<pid>@<W>" is a full entry in `plates` (size, parts, click areas) with its own textures, "<pid>@<W>.png" and
"<pid>@<W>_<state>.png", so ZeD_Plate draws it like any plate. The key's number is the width from the fit tables: the
plate's own width for the 17 machine plates, the half card's PANEL width for the walkies (whose face is 20 px narrower,
today's margins). Today's faces keep their names; `narrow` (the 200 px faces) is unchanged.
usage: python export_fill.py [mod root]   (default: ./out/mod/ZeD-UI)"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import export_336 as E336            # noqa: E402  (plates_336 over the registry, then the narrow table)
import export_phys as EX             # noqa: E402
import w_plates as WP                # noqa: E402
from physlib import build            # noqa: E402
from plates import DESIGNS           # noqa: E402
from export_lua import to_lua        # noqa: E402

NOTE = ("-- widths: each plate's faces by the width that fills its card (design session Oct 30 2026,\n"
        "-- REQUEST_design_plates_fill_20261030.md): the game draws the widest that fits at the plates' whole zoom. For the\n"
        "-- machine plates the key is the plate's width (336 is today's face); for the walkies it is the half card's panel\n"
        "-- width (220 is today's; the face is 20 px narrower). Same click areas and live parts at every width.\n")


def build_wide(pid, W):
    D = DESIGNS[pid]
    key = f"{pid}@{W}"
    p, base, sprites = build(WP.WIDE[pid], D["variants"], W=W, **D.get("base", {}))
    if D.get("post"): D["post"](p)
    if p.warnings: raise SystemExit(f"{key}: placement warnings, fix before export: {p.warnings}")
    data = {"w": p.W, "h": p.H, "plate": key, "title": D["title"], "base": pid, "fill": W,
            "parts": [EX.convert_part(q, key) for q in p.parts],
            "hits": [{k: v for k, v in h.items() if v is not None} for h in p.hits]}
    for k, v in p.meta.items(): data[k] = EX.norm(v)
    return data, base, {f"{key}_{n}": im for n, im in sprites.items()}


def export(root, only=None):
    out, pictures = E336.export(root, only)
    tex_dir = os.path.join(root, "42", *EX.TEXDIR.strip("/").split("/"))
    widths = {}
    for pid in WP.WIDE:
        if only and pid not in only: continue
        W0, ws = WP.widths(pid)
        widths[pid] = {W0: pid}
        for W in ws:
            if W == W0: continue
            data, base, sprites = build_wide(pid, W)
            key = data["plate"]
            base.save(os.path.join(tex_dir, f"{key}.png"))
            for name, im in sprites.items(): im.save(os.path.join(tex_dir, f"{name}.png"))
            out["plates"][key] = data
            pictures[key] = (base, sprites)
            widths[pid][W] = key
            print(f"{key:22s} {data['w']}x{data['h']} parts {len(data['parts']):2d} hits {len(data['hits']):2d} sprites {len(sprites)}")
    out["widths"] = widths
    path = os.path.join(root, "42", "media", "lua", "client", "ZeD", "PhysPx.lua")
    head = open(path, encoding="utf-8").read().split("ZeD = ZeD or {}\n")[0]
    with open(path, "w", newline="\n", encoding="utf-8") as f:
        f.write(head + NOTE + "ZeD = ZeD or {}\n" + "ZeD.PhysPx = " + to_lua(out) + "\nreturn ZeD.PhysPx\n")
    print("widths table:", len(widths), "plates;", sum(len(v) - 1 for v in widths.values()), "extra faces;",
          len(os.listdir(tex_dir)), "textures;", os.path.getsize(path), "bytes of PhysPx.lua")
    return out, pictures


if __name__ == "__main__":
    export(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "out", "mod", "ZeD-UI"))
