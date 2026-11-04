"""Beta 3 gallery (Nov 4 2026, QA; the director: full-screen breaks between the book's spreads, BETA3_ORDER.md).
Builds upload_beta3/: the spreads from upload/ in their order, with plain full-screen captures placed after the run
of spreads each one shows. Breaks are 1920x1080 JPEGs under Steam's 1 MB, made from the 4K captures; names sort into
place ("14b_break_station.jpg" after "14_night_shift.jpg").
usage: py make_beta3.py
"""
import os, shutil
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
UP = os.path.join(HERE, "upload")
OUT = os.path.join(HERE, "upload_beta3")
SHOTS = "C:/Users/you/Zomboid/Screenshots"
G14 = SHOTS + "/gallery_t14"

BREAKS = [
    ("14b_break_station", G14 + "/story_10_customers_queue.png"),
    ("18b_break_windows", SHOTS + "/gal_b3_br_onscreen.png"),
    ("26b_break_equip", SHOTS + "/gal_b3_br_equip.png"),
    ("29b_break_crafting", SHOTS + "/gal_b3_br_craft.png"),
    ("33b_break_smoke", G14 + "/story_11_smoke_break.png"),
    ("41b_break_newspaper", SHOTS + "/gal_b3_br_reader.png"),
    ("44b_break_controller", G14 + "/gb_bugreport_wheel.png"),
    ("49b_break_desk", SHOTS + "/desk_01_painting.png"),
    ("55b_break_mods", SHOTS + "/mm4_03_mods_conflict.png"),
    ("63d_break_guide", SHOTS + "/gal_b3_br_guide.png"),
]
# today's plain screenshots 64-68 move to the runs they belong to
MOVES = {"64_livestock_trailer.jpg": "62b_livestock_trailer.jpg", "65_sports_car.jpg": "62c_sports_car.jpg",
         "66_van_hood.jpg": "62d_van_hood.jpg", "67_stew_for_two.jpg": "63b_stew_for_two.jpg",
         "68_stir_fry.jpg": "63c_stir_fry.jpg"}


def jpeg(src, dst):
    im = Image.open(src).convert("RGB").resize((1920, 1080), Image.LANCZOS)
    for q in (92, 88, 84, 80, 76):
        im.save(dst, quality=q, optimize=True, subsampling=0)
        if os.path.getsize(dst) < 1000000:
            return q
    return q


def main():
    if os.path.isdir(OUT):
        shutil.rmtree(OUT)
    os.makedirs(OUT)
    for f in sorted(os.listdir(UP)):
        if f.endswith(".jpg"):
            shutil.copy2(os.path.join(UP, f), os.path.join(OUT, MOVES.get(f, f)))
    for name, src in BREAKS:
        q = jpeg(src, os.path.join(OUT, name + ".jpg"))
        print("break", name, "q", q, os.path.getsize(os.path.join(OUT, name + ".jpg")))
    files = sorted(os.listdir(OUT))
    print(len(files), "pictures:")
    for f in files:
        print(" ", f)


if __name__ == "__main__":
    main()
