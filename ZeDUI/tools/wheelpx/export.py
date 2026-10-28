"""Export the wheel icons: white on clear, pixel for pixel.
  out/export/wheel/16/zw_<id>.png   the 16 drawing                 (the cell at rest at 1x)
  out/export/wheel/24/zw_<id>.png   the 24 drawing                 (the pointed cell at 1x)
  out/export/wheel/32/zw_<id>.png   the 16 drawing, each pixel 2x2 (the cell at rest at 2x)
  out/export/wheel/48/zw_<id>.png   the 24 drawing, each pixel 2x2 (the pointed cell at 2x)
and out/export/wheel_icons_map.json: every icon (its group, what it means) and the rules that say where it goes.
The zw_ prefix keeps a file's name off the game's packed pictures: getTexture("media/textures/.../map.png")
loads the game's own "map" (map, engine, sneak and heart did; PZAPI-KNOWLEDGE-BANK Q143)."""
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
ROOT = os.path.normpath(os.path.join(HERE, "..", "..", ".."))
GAME = os.path.join(ROOT, "42", "media", "textures", "ZeD")           # --game: the mod's own folder
GAME_MAP = os.path.join(ROOT, "ZeDUI", "mockups", "zed_wheel_icons_v1")  # (where the handoff keeps the map)


def same_pixels(path, im):
    if not os.path.exists(path): return False
    old = Image.open(path).convert("RGBA")
    return old.size == im.size and old.getchannel("A").tobytes() == im.getchannel("A").tobytes()


def main(game=False):
    """game: write straight into the mod (42/media/textures/ZeD/wheel/<size>/ and the handoff's map) instead of out/"""
    out, map_dir = (GAME, GAME_MAP) if game else (OUT, OUT)
    for sz in (16, 24, 32, 48): os.makedirs(os.path.join(out, "wheel", str(sz)), exist_ok=True)
    written = 0
    for id_ in kit.ICONS:
        a, b = kit.render(id_, 16), kit.render(id_, 24)
        for im, sz in ((a, 16), (b, 24), (a.resize((32, 32), Image.NEAREST), 32), (b.resize((48, 48), Image.NEAREST), 48)):
            path = os.path.join(out, "wheel", str(sz), "zw_" + id_ + ".png")
            if game and same_pixels(path, im): continue      # (unchanged drawings keep their files: no churn in git)
            im.save(path, optimize=True); written += 1
    used = M.used()
    data = {
        "icons": {k: {"group": v["cat"], "means": v["means"], "mapped": k in used} for k, v in kit.ICONS.items()},
        "order": "TEXT, then KEEP, then TEX; ZeD's own wheels name ids directly (ZED, TABS)",
        "TEXT": [{"key": k, "texture": t, "id": i, "why": w} for k, t, i, w in M.TEXT],
        "KEEP": M.KEEP,
        "TEX": [{"group": g, "texture": t, "id": i} for g, t, i in M.TEX],
        "ZED": [{"wheel": w, "slice": s, "now": n, "id": i} for w, s, n, i in M.ZED],
        "TABS": [{"tab": t, "id": i} for t, i in M.TABS],
        "ROW": [{"window": w, "button": b, "id": i} for w, b, i in M.ROW],
    }
    os.makedirs(map_dir, exist_ok=True)
    with open(os.path.join(map_dir, "wheel_icons_map.json"), "w", encoding="utf-8") as f: json.dump(data, f, indent=1)
    print(len(kit.ICONS), "icons,", 4 * len(kit.ICONS), "files,", written, "written")


if __name__ == "__main__":
    main(game="--game" in sys.argv)
