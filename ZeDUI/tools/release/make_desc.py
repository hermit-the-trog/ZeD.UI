"""ZeDUI/tools/release/make_desc.py  (Oct 22 2026)

The Workshop description with pictures in it (director, Oct 21: "liven that up with
images, do a real layout not just a word document looking bit of text").

Steam draws a description's [img] at most about 636 px wide, so every picture here is
made at twice that (1272 px) and stays sharp on high-density screens:
  * a title plate in place of the [h1], and a section plate in place of each [h2],
    drawn as the gallery cards' System 7 title bar (make_shots.py: same palette, the
    racing stripes, the close box, Chicago for the title)
  * eight gallery cards, reduced to 1272 x 716, each placed where the text describes it
    (--links wraps each in a link to the full card; off by default, to stay under 8,000)
The words are the description's own (workshop_description_draft.bbcode): nothing is
reworded, only the headings become plates and the pictures go between paragraphs.

Steam needs every picture at a public address. The layout uses IMG_BASE in front of
each file name; once the files are hosted (Steam artwork uploads, or the repo's raw
files if it is public), replace IMG_BASE with that address.

Run (Windows, from the repo root):
    py -I ZeDUI/tools/release/make_desc.py
Output: ZeDUI/workshop/desc/*.png|jpg and ZeDUI/workshop/workshop_description_layout.bbcode
Options: --fonts DIR (where ChicagoFLF.ttf and the Fira fonts are; default: the user
and system font folders, as make_shots.py)   --root DIR (the repo root)
"""
import argparse
import json
import os
import re

from PIL import Image, ImageDraw, ImageFont

# ---- palette: the gallery cards' (make_shots.py), ZeD dark with the orange accent ----
BG        = (20, 19, 17)
SCAN      = (16, 15, 13)
BAND      = (30, 29, 26)
BAND_EDGE = (58, 56, 51)
STRIPE    = (64, 61, 56)
TITLE_TX  = (238, 233, 222)
SUB_TX    = (168, 163, 152)
ACCENT    = (212, 146, 42)
MARK      = "ZeD-GUI"

W = 1272                        # twice Steam's description width
PLATE_H = 104                   # a section plate (52 px as Steam shows it)
TITLE_H = 230                   # the title plate

# ---- where the pictures go -----------------------------------------------------------
# Cards are named by their id in shots.json (the file is NN_id.jpg, NN its place in the
# gallery), so a reordered gallery still finds them. Oct 22: the v4 gallery, the Fossoil story.
# a card after the paragraph that starts with these words ...
AFTER_PARA = [
    ("ZeD-GUI replaces", "hero"),
    ("Open containers show as columns", "stocking_shelves"),
    ("[b]Cards.[/b]", "item_cards"),
    ("The main menu is a desk", "desk"),
    ("[b]Mods.[/b]", "mod_manager"),          # (two cards after one paragraph: listed in order)
    ("[b]Mods.[/b]", "load_order"),
    ("[b]Workshop.[/b]", "uploader"),
    ("ZeD setup is the first page", "options_menu"),
]
# ... or at the end of a section, before the next heading
END_OF_SECTION = {
    "HUD": "smoke_break",
    "Maps": "the_route",
    "Controller": "customers",
    "Options": "themes",
}


def font_dirs(extra):
    d = [extra] if extra else []
    d += [os.path.expanduser("~/AppData/Local/Microsoft/Windows/Fonts"),
          os.path.join(os.environ.get("WINDIR", "C:\\Windows"), "Fonts")]
    return d


def find_font(dirs, name, size):
    for d in dirs:
        p = os.path.join(d, name)
        if os.path.isfile(p):
            return ImageFont.truetype(p, size)
    raise SystemExit("font not found: %s (looked in %s)" % (name, dirs))


def slug(t):
    return re.sub(r"[^a-z0-9]+", "_", t.lower()).strip("_")


def stripes(d, x0, x1, yc, n=6, step=6):
    """System 7 racing stripes between x0 and x1 around yc (make_shots.stripes)."""
    if x1 - x0 < 8:
        return
    top = yc - (n - 1) * step // 2 - 1
    for i in range(n):
        y = top + i * step
        d.rectangle([x0, y, x1, y + 1], fill=STRIPE)


def plate(title, f_title, f_mark, h=PLATE_H, sub=None, f_sub=None, mark=True):
    """A title bar: the close box, stripes either side of the title, the ZeD mark right."""
    im = Image.new("RGB", (W, h), BG)
    d = ImageDraw.Draw(im)
    for y in range(0, h, 3):
        d.line([(0, y), (W, y)], fill=SCAN)
    d.rectangle([0, 0, W, h - 1], fill=BAND)
    d.rectangle([0, h - 2, W, h - 1], fill=BAND_EDGE)
    yc = (h // 2) if not sub else int(h * 0.42)
    m = 40
    tw = f_title.getlength(title)
    tx0 = (W - tw) / 2
    box = 28 if h <= PLATE_H else 36
    d.rectangle([m, yc - box // 2, m + box, yc + box // 2], fill=BAND)
    d.rectangle([m, yc - box // 2, m + box, yc + box // 2], outline=STRIPE, width=2)
    mx = W - m
    if mark:
        mw = f_mark.getlength(MARK)
        mx = W - m - mw
        a2, d2 = f_mark.getmetrics()
        d.text((mx, yc - (a2 + d2) / 2 + 1), MARK, font=f_mark, fill=ACCENT)
    n = 6 if h <= PLATE_H else 9
    stripes(d, m + box + 18, tx0 - 30, yc, n=n)
    stripes(d, tx0 + tw + 30, mx - 22, yc, n=n)
    a, de = f_title.getmetrics()
    d.text((tx0, yc - (a + de) / 2 + 3), title, font=f_title, fill=TITLE_TX)
    if sub:
        sw = f_sub.getlength(sub)
        a3, d3 = f_sub.getmetrics()
        d.text(((W - sw) / 2, int(h * 0.78) - (a3 + d3) / 2), sub, font=f_sub, fill=ACCENT)
    return im


def card(src, dst):
    im = Image.open(src).convert("RGB")
    im = im.resize((W, round(W * im.height / im.width)), Image.LANCZOS)
    q = 88
    while True:
        im.save(dst, "JPEG", quality=q, optimize=True, progressive=True)
        if os.path.getsize(dst) <= 400_000 or q <= 70:
            break
        q -= 4


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=".")
    ap.add_argument("--fonts", default=None)
    ap.add_argument("--links", action="store_true",
                    help="wrap each card in a link to the full card (costs about 70 characters a card once hosted)")
    a = ap.parse_args()
    ws = os.path.join(a.root, "ZeDUI", "workshop")
    out = os.path.join(ws, "desc")
    os.makedirs(out, exist_ok=True)
    fd = font_dirs(a.fonts)
    f_plate = find_font(fd, "ChicagoFLF.ttf", 44)
    f_title = find_font(fd, "ChicagoFLF.ttf", 92)
    f_mark = find_font(fd, "FiraMono-Bold.ttf", 24)
    f_sub = find_font(fd, "FiraMono-Bold.ttf", 30)

    src = open(os.path.join(ws, "workshop_description_draft.bbcode"), encoding="utf-8").read().replace("\r\n", "\n")
    shots = json.load(open(os.path.join(ws, "shots", "shots.json"), encoding="utf-8"))["shots"]
    card_file = {s["id"]: "%02d_%s.jpg" % (i + 1, s["id"]) for i, s in enumerate(shots)}
    lines = src.split("\n")
    made = []

    def img(name, link=None):
        t = "[img]IMG_BASE/%s[/img]" % name
        return "[url=IMG_BASE/%s]%s[/url]" % (link, t) if link else t

    def put_card(key):
        if key not in card_file:
            raise SystemExit("no shot %r in shots.json" % key)
        name = key + ".jpg"        # (the hosted name keeps no gallery number: a reorder renames nothing)
        card(os.path.join(ws, "shots", "out", card_file[key]), os.path.join(out, name))
        made.append(name)
        # with --links, the card opens the gallery card at full size (also hosted, under full/)
        return img(name, "full/" + card_file[key]) if a.links else img(name)

    res = []
    section = None
    for i, ln in enumerate(lines):
        m1 = re.fullmatch(r"\[h1\](.*?)\[/h1\]", ln)
        m2 = re.fullmatch(r"\[h2\](.*?)\[/h2\]", ln)
        if m1:
            title = re.sub(r"\s*\[B42\]\s*", "", m1.group(1)).strip()
            plate(title, f_title, f_mark, h=TITLE_H, sub="FOR PROJECT ZOMBOID  \u00b7  BUILD 42", f_sub=f_sub,
                  mark=False).save(os.path.join(out, "title.png"), optimize=True)
            made.append("title.png")
            res.append(img("title.png"))
            continue
        if m2:
            if section in END_OF_SECTION:
                while res and res[-1] == "":
                    res.pop()
                res += ["", put_card(END_OF_SECTION.pop(section)), ""]
            section = m2.group(1)
            name = "h_%s.png" % slug(section)
            # (no ZeD mark on these: thirteen of them down one page is noise; the cards carry it)
            plate(section, f_plate, f_mark, mark=False).save(os.path.join(out, name), optimize=True)
            made.append(name)
            res.append(img(name))
            continue
        res.append(ln)
        for start, key in AFTER_PARA:
            nxt = lines[i + 1] if i + 1 < len(lines) else ""
            if ln.startswith(start) and nxt.strip() == "":
                res += ["", put_card(key)]
    if section in END_OF_SECTION:
        res += ["", put_card(END_OF_SECTION.pop(section))]
    text = "\n".join(res).rstrip() + "\n"
    with open(os.path.join(ws, "workshop_description_layout.bbcode"), "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    print("wrote %d pictures in %s and workshop_description_layout.bbcode (%d characters with IMG_BASE)"
          % (len(made), out, len(text)))
    for k in made:
        print("  " + k)


if __name__ == "__main__":
    main()
