"""Beta 3 gallery (Nov 4 2026, QA; the director: full-screen breaks between the book's spreads, BETA3_ORDER.md).
Builds upload_beta3/: the spreads from upload/ in their order, with plain full-screen captures placed after the run
of spreads each one shows. Breaks are 1920x1080 JPEGs under Steam's 1 MB, made from the 4K captures; names sort into
place ("14b_break_station.jpg" after "14_night_shift.jpg").
usage: py make_beta3.py [out folder, default upload_beta3]
"""
import os, shutil, sys
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
UP = os.path.join(HERE, "upload")
OUT = os.path.join(HERE, sys.argv[1] if len(sys.argv) > 1 else "upload_beta3")
SHOTS = os.path.expanduser("~/Zomboid/Screenshots")
G14 = SHOTS + "/gallery_t14"

CIN = os.path.join(HERE, "cinema")
# Nov 4 2026 (the director): every break is a movie scene on a cinema screen (cinema_frame.py; the pictures are framed
# already, in cinema/). Each follows the run whose screens it shows best. The Beta 3 set's plain breaks are in git
# (upload_beta3/, live on Steam until this set replaces it).
BREAKS = [
    ("14b_break_kohners_map", CIN + "/cin_koh_maps.jpg"),        # the story: the route, a paper map
    ("18b_break_plizken_windows", CIN + "/cin_plz_equip.jpg"),   # every window: both open
    ("26b_break_mckline_health", CIN + "/cin_mck_health.jpg"),   # items and the character: the Health tab
    ("29b_break_laura_crafting", CIN + "/cin_lau_craft.jpg"),    # making things: Crafting at the camp
    ("33b_break_laura_camp", CIN + "/cin_lau_wide.jpg"),         # on screen: the belt with its holsters
    ("41b_break_mckline_radio", CIN + "/cin_mck_radio.jpg"),     # machines and media: the walkie in the Radio tab
    ("44b_break_plizken_stadium", CIN + "/cin_plz_wide.jpg"),    # the controller run ends: the stadium
    ("49b_break_laura_building", CIN + "/cin_lau_build.jpg"),    # looks: the Light theme, Skills and Building
    ("55b_break_plizken_vehicle", CIN + "/cin_plz_vehicle.jpg"), # mods: the ID card (Veteran) and a wreck
    ("63d_break_kohners_car", CIN + "/cin_koh_vehicle.jpg"),     # vehicles and cooking: the broken-down car
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
