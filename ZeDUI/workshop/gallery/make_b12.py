"""Beta 12 gallery (plan v2, PLAN_ALTERNATE_20261111.md, approved Nov 11 2026).

    py make_b12.py [out folder, default upload_b12]

Builds the upload set in Workshop order (file-name order): the cover, Angel's opening break, the title, the 63
chapters (make_upload.py), a cinema break after every part, Angel's closing break and the director's closing picture.
Writes upload_contact_b12.jpg (every picture at a sixth) and B12_ORDER.md (the order, each name, the shots missing).

The breaks are movie scenes on a cinema screen (cinema_frame.py). Eight reuse the framed pictures in cinema/. Six are
new or reshot: QA's raw 4K captures land in ~/Zomboid/Screenshots as cin_<cast>_<topic>.png (the scene scripts'
TakeFullScreenshot); each one found is framed into cinema/<same name>.jpg. A break whose picture is missing is
reported and left out, never stood in for. Never writes upload_b11 (live on the Workshop).
"""
import json
import os
import shutil
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import cinema_frame   # noqa: E402
import make_upload    # noqa: E402

OUT = os.path.join(HERE, sys.argv[1] if len(sys.argv) > 1 else "upload_b12")
CIN = os.path.join(HERE, "cinema")
RAW = os.path.join(os.path.expanduser("~"), "Zomboid", "Screenshots")
LIMIT = 1000000
STORY = set(range(1, 15))   # Angel's story: the chapters approved as 1 to 14 (their seed), one at the head of each part

# (upload name, framed picture in cinema/, what it shows). "new": QA's raw capture is framed when it lands.
BREAKS = [
    ("00b_break_angel_open", "cin_ang_open", "new", "Angel, Light + Blue: the Fossoil in the morning, both windows on Loot"),
    ("07b_break_plizken_windows", "cin_plz_equip", "reuse", "Plizken, the stadium: Equipment and Maps"),
    ("12b_break_kohners_house", "cin_koh_house", "new", "Kohners, Dark + Pink: a house with power, an item card open, the washer-dryer's card"),
    ("17b_break_laura_building", "cin_lau_build", "reuse", "Laura, the camp: Skills and Building"),
    ("22b_break_mckline_kitchen", "cin_mck_kitchen", "new", "McKline, High Contrast + Red: his kitchen, Cooking and the oven in Crafting"),
    ("27b_break_laura_lake", "cin_lau_lake", "new", "Laura, Light + Teal (reshoot): the lake, Radio (a walkie) and Fishing"),
    ("30b_break_kohners_car", "cin_koh_vehicle", "reuse", "Kohners, the broken-down car: Equipment and Vehicle"),
    ("35b_break_laura_camp", "cin_lau_wide", "reuse", "Laura, the camp wide: the belt, no windows"),
    ("40b_break_mckline_radio", "cin_mck_radio", "reuse", "McKline, the roof: a notice bubble, Radio and Maps"),
    ("45b_break_kohners_dusk", "cin_koh_dusk", "new", "Kohners, Dark + Pink: driving at dusk, the dashboard and the car radio, no windows"),
    ("50b_break_plizken_stadium", "cin_plz_wide", "reuse", "Plizken, the stadium wide"),
    ("55b_break_mckline_health", "cin_mck_health", "reuse", "McKline, the roof: Health and Maps"),
    ("60b_break_plizken_vehicle", "cin_plz_vehicle", "reuse", "Plizken, the ID card and a wreck: Identity and Vehicle"),
    ("63b_break_angel_close", "cin_ang_close", "new", "Angel, Light + Blue, night: Angel meets a group of survivors on a server, Server and Loot"),
]
THE_END = ("69_the_end.jpg", os.path.join(HERE, "upload", "69_the_end.jpg"))   # the director's, placed by hand


def frame_new(cin):
    """Frame QA's raw capture into cinema/ when it is there and newer than the framed one. Returns the framed path or None."""
    raw = os.path.join(RAW, cin + ".png")
    framed = os.path.join(CIN, cin + ".jpg")
    if os.path.exists(raw) and (not os.path.exists(framed) or os.path.getmtime(raw) > os.path.getmtime(framed)):
        cinema_frame.main(raw, framed)
    return framed if os.path.exists(framed) else None


def jpeg(src, dst):
    im = Image.open(src).convert("RGB")
    if im.size != (1920, 1080):
        im = im.resize((1920, 1080), Image.LANCZOS)
    for q in (92, 88, 84, 80, 76):
        im.save(dst, quality=q, optimize=True, subsampling=0)
        if os.path.getsize(dst) < LIMIT:
            break
    return q, os.path.getsize(dst)


def contact(files, path, cols=8, tw=336, th=189, lab=30):
    rows = (len(files) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * tw, rows * (th + lab)), (24, 22, 26))
    d = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype(os.path.join(HERE, "fonts", "FiraMono-Regular.ttf"), 15)
    except OSError:
        font = ImageFont.load_default()
    for i, f in enumerate(files):
        x, y = (i % cols) * tw, (i // cols) * (th + lab)
        sheet.paste(Image.open(os.path.join(OUT, f)).convert("RGB").resize((tw, th), Image.LANCZOS), (x, y))
        d.text((x + 6, y + th + 6), f[:-4][:38], font=font, fill=(220, 214, 200))
    sheet.save(path, quality=85, optimize=True)


def main():
    if os.path.abspath(OUT) == os.path.abspath(os.path.join(HERE, "upload_b11")):
        sys.exit("upload_b11 is live on the Workshop: build into a new folder")
    if os.path.isdir(OUT):
        shutil.rmtree(OUT)
    os.makedirs(OUT)
    bad = make_upload.main(os.path.join(HERE, "out_spread"), OUT)
    missing = []
    for name, cin, kind, what in BREAKS:
        src = frame_new(cin) if kind == "new" else os.path.join(CIN, cin + ".jpg")
        if not src or not os.path.exists(src):
            missing.append((name, cin, what))
            print("MISSING break", name, "(needs %s.png in %s)" % (cin, RAW.replace(os.path.expanduser("~"), "~")))
            continue
        q, n = jpeg(src, os.path.join(OUT, name + ".jpg"))
        print("break %-30s q%d %7d bytes" % (name, q, n))
        if n >= LIMIT:
            bad += 1
    if os.path.exists(THE_END[1]):
        q, n = jpeg(THE_END[1], os.path.join(OUT, THE_END[0]))
        print("end   %-30s q%d %7d bytes" % (THE_END[0], q, n))
    else:
        missing.append((THE_END[0][:-4], "upload/69_the_end.jpg", "the director's closing picture"))
    files = sorted(f for f in os.listdir(OUT) if f.endswith(".jpg"))
    over = [f for f in files if os.path.getsize(os.path.join(OUT, f)) >= LIMIT]
    contact(files, os.path.join(HERE, "upload_contact_b12.jpg"))
    write_order(files, missing, over)
    print("%d pictures (%d when every shot is in), %d missing, %d over 1 MB" % (len(files), len(files) + len(missing),
                                                                                 len(missing), len(over)))
    return bad + len(over)


def write_order(files, missing, over):
    what = {n: w for n, c, k, w in BREAKS}
    src = {n: c for n, c, k, w in BREAKS}
    L = ["# Beta 12 gallery: the upload order", "",
         "Written by `make_b12.py` (plan v2, `PLAN_ALTERNATE_20261111.md`). Upload `upload_b12/` in file-name order, "
         "one picture at a time. Every picture is 1920 x 1080, each under 1 MB. Contact sheet: `upload_contact_b12.jpg`.",
         "", "%d pictures now; %d when every shot is in." % (len(files), len(files) + len(missing)), "",
         "| # | Picture | What it is |", "|---|---|---|"]
    allnames = sorted([f[:-4] for f in files] + [m[0] for m in missing])
    present = set(f[:-4] for f in files)
    for i, n in enumerate(allnames, 1):
        if n in what:
            desc = "break (`cinema/%s.jpg`): %s" % (src[n], what[n])
        elif n.startswith("00a"):
            desc = "the cover: the desk, the book and the discs"
        elif n.startswith("00c"):
            desc = "the title spread"
        elif n.startswith("69"):
            desc = "the director's closing picture"
        else:
            sp = json.load(open(os.path.join(HERE, "spreads", n + ".json"), encoding="utf-8"))
            title = [b["chapter"][1] for b in sp["left"]["blocks"] if "chapter" in b][0]
            desc = "chapter %d, %s%s" % (sp["n"], title, " (story)" if sp.get("seed", 0) in STORY else "")
        L.append("| %s | `%s.jpg` | %s%s |" % (i, n, desc, "" if n in present else " **(missing)**"))
    L += ["", "## Missing shots", ""]
    if missing:
        L.append("Each is framed and placed when its raw 4K capture is in `~/Zomboid/Screenshots` under this name; "
                 "then run `py make_b12.py` again.")
        L.append("")
        for n, cin, w in missing:
            L.append("- `%s.png` for `%s.jpg`: %s" % (cin, n, w))
    else:
        L.append("None.")
    if over:
        L += ["", "Over 1 MB: " + ", ".join(over)]
    open(os.path.join(HERE, "B12_ORDER.md"), "w", encoding="utf-8").write("\n".join(L) + "\n")


if __name__ == "__main__":
    sys.exit(1 if main() else 0)
