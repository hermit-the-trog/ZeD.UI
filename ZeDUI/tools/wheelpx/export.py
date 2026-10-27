"""Export the wheel icons: white on clear, pixel for pixel.
  out/export/wheel/16/<id>.png   the 16 drawing                 (the cell at rest at 1x)
  out/export/wheel/24/<id>.png   the 24 drawing                 (the pointed cell at 1x)
  out/export/wheel/32/<id>.png   the 16 drawing, each pixel 2x2 (the cell at rest at 2x)
  out/export/wheel/48/<id>.png   the 24 drawing, each pixel 2x2 (the pointed cell at 2x)
and out/export/wheel_icons_map.json: every icon (its group, what it means) and the rules that say where it goes."""
import json
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import allicons  # noqa: F401
import kit
import map as M

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "out", "export")


def main():
    for sz in (16, 24, 32, 48): os.makedirs(os.path.join(OUT, "wheel", str(sz)), exist_ok=True)
    for id_ in kit.ICONS:
        a, b = kit.render(id_, 16), kit.render(id_, 24)
        for im, sz in ((a, 16), (b, 24), (a.resize((32, 32), Image.NEAREST), 32), (b.resize((48, 48), Image.NEAREST), 48)):
            im.save(os.path.join(OUT, "wheel", str(sz), id_ + ".png"), optimize=True)
    used = M.used()
    data = {
        "icons": {k: {"group": v["cat"], "means": v["means"], "mapped": k in used} for k, v in kit.ICONS.items()},
        "order": "TEXT, then KEEP, then TEX; ZeD's own wheels name ids directly (ZED, TABS)",
        "TEXT": [{"key": k, "texture": t, "id": i, "why": w} for k, t, i, w in M.TEXT],
        "KEEP": M.KEEP,
        "TEX": [{"group": g, "texture": t, "id": i} for g, t, i in M.TEX],
        "ZED": [{"wheel": w, "slice": s, "now": n, "id": i} for w, s, n, i in M.ZED],
        "TABS": [{"tab": t, "id": i} for t, i in M.TABS],
    }
    with open(os.path.join(OUT, "wheel_icons_map.json"), "w", encoding="utf-8") as f: json.dump(data, f, indent=1)
    print(len(kit.ICONS), "icons,", 4 * len(kit.ICONS), "files")


if __name__ == "__main__":
    main()
