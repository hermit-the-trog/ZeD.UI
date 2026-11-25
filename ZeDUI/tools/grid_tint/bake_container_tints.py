"""Bake each container icon's main color, for the container strips' tinted buttons (the director, Nov 25 2026).

    python -I ZeDUI/tools/grid_tint/bake_container_tints.py [<PZ>/media]

The container buttons of both windows take a stronger tint of their icon's main color (the mock-up
ZeDUI/mockups/container_tabs_color_v4.html, "Stronger tint"). A bag's button shows the bag's item icon, which
ZeD.ItemTints already has; the world's containers (crates, bodies, fridges, the floor) and the main inventory
show the game's Container_* pictures (shared/Definitions/ContainerButtonIcons.lua), baked here the same way
(bake_item_tints.main_color). Writes 42/media/lua/shared/ZeD/ContainerTints.lua: "Container_Crate" -> 0xRRGGBB.
A gray, black or white picture is 0x808080, a neutral tint. Run with the ComfyUI venv's Python (Pillow, numpy).
"""
import io
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import bake_item_tints as B  # noqa: E402

OUT = os.path.join(B.ROOT, "42", "media", "lua", "shared", "ZeD", "ContainerTints.lua")


def main():
    media = sys.argv[1] if len(sys.argv) > 1 else B.MEDIA
    colors = {}
    for pk in B.PACKS:
        p = os.path.join(media, "texturepacks", pk)
        if not os.path.isfile(p):
            continue
        for ents, data in B.pages(p):
            hits = [e for e in ents if e[0].startswith("Container_")]
            if not hits:
                continue
            page = Image.open(io.BytesIO(data)).convert("RGBA")
            for en, (x, y, w, h, _ox, _oy, _tw, _th) in hits:
                colors[en] = B.main_color(page.crop((x, y, x + w, y + h)))
    ui = os.path.join(media, "ui")
    for fn in os.listdir(ui):
        if fn.startswith("Container_") and fn.lower().endswith(".png"):
            k = fn[:-4]
            if k not in colors:
                colors[k] = B.main_color(Image.open(os.path.join(ui, fn)).convert("RGBA"))
    gray = 0
    rows = []
    for k in sorted(colors):
        c = colors[k]
        if c is None:
            gray += 1
            c = (128, 128, 128)
        rows.append('    ["%s"] = %d,' % (k, (c[0] << 16) | (c[1] << 8) | c[2]))
    head = [
        "-- ZeD-UI/42/media/lua/shared/ZeD/ContainerTints.lua",
        "-- ============================================================================",
        "-- EACH CONTAINER PICTURE'S MAIN COLOR, for the container strips' tinted buttons (the director, Nov 25 2026):",
        "-- a generated data table, written by ZeDUI/tools/grid_tint/bake_container_tints.py from the game's Container_*",
        "-- pictures: do not edit by hand. The picture's name -> its main color, 0xRRGGBB (gray ones 0x808080).",
        "-- ZeD.GridTint.stripFill turns it into each theme's tint. Shared, plain data. Pure ASCII.",
        "-- %d pictures, %d of them gray." % (len(rows), gray),
        "-- ============================================================================",
        "ZeD = ZeD or {}",
        "ZeD.ContainerTints = {",
    ]
    with open(OUT, "w", encoding="ascii", newline="\n") as f:
        f.write("\n".join(head + rows + ["}", ""]))
    print("wrote %s: %d colors, %d gray" % (OUT, len(rows), gray))


if __name__ == "__main__":
    main()
