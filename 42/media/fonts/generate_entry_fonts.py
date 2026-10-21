"""
Bake the text-entry faces for ZeD search fields (Fira Sans Medium, the F2 body
face) at fixed pixel sizes.

Why: a search field's typed text is drawn by the engine's Java text box, which
renders its font at the font's native pixel size (no zoom). The ZeD UI scales
everything else continuously (ZeD.Scale.root), so on a 4K screen the body face
at 13 px looks tiny next to the 2x UI. ZeD_SearchField picks the face whose
size is closest to the scaled body size (13 px small preset / 15 px large,
times ZeD.Scale.root) from:

  Small  13 px (body.fnt, generate_fonts.py)
  Large  15 px (bodyLg.fnt, generate_fonts.py)
  Dialogue  18 px  entry18   (1440p Auto, 1.25x-1.5x)
  Intro     26 px  entry26   (2x, the 4K Auto size; larger sizes take it too)

The two slots are faces no vanilla text uses (Oct 16 2026: these were four
Sdf slots until it turned out they are the printed newspapers' faces, named
in their layouts; those went back to the game). No vanilla Lua, script or
game class names Dialogue, and nothing sets the rich-text intro size (the engine fills MediumNew and the AutoNorm
slots itself, so those cannot carry mod faces). Registered in EN/fonts.txt as
plain bitmap faces.

Run from this folder:  py generate_entry_fonts.py
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from generate_fonts import generate_font, print_missing, _FIRA_SANS_MED  # noqa: E402

ENTRY_SIZES = {"entry18": 18, "entry26": 26}


def main():
    out_dir = os.path.dirname(os.path.abspath(__file__))
    if not os.path.isfile(_FIRA_SANS_MED):
        print(f"ERROR: TTF not found: {_FIRA_SANS_MED}")
        sys.exit(1)
    for name, size in ENTRY_SIZES.items():
        count, aw, ahs = generate_font(name, _FIRA_SANS_MED, "Fira Sans", 0, 0, size, 1, out_dir)
        sizes = " + ".join(f"{aw}x{h}" for h in ahs)
        print(f"  {name}: {count} chars, {len(ahs)} page(s) {sizes}")


if __name__ == "__main__":
    main()
    print_missing()
