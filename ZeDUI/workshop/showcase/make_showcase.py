"""make_showcase.py - the 1.0 Workshop description's showcase graphics (Nov 18 2026, Build).

The director: "those image slots are all new graphics, and those are showcases, not part of the book. A collage of
just screenshots, or a split of two screenshots, to show what the bullet points below are talking about. Outline
stuff, highlight stuff, but not enough that you can't tell what's going on or where that fits on the screen."

Each graphic: the whole screen on top (where things are), the parts its bullets name outlined and labeled; under it,
close-ups at the game's own pixels (what they look like). Shots: QA's 4K captures in Zomboid/Screenshots/gallery_v1_wip.

Run from the repo root:  python ZeDUI/workshop/showcase/make_showcase.py <slot numbers>
Writes ZeDUI/workshop/showcase/review/<n>_<name>.jpg; once the director approves, copy it into description_img/ (the live page reads that).
"""
import os
import sys
from PIL import Image, ImageDraw, ImageFont

SHOTS = os.path.join(os.path.expanduser("~"), "Zomboid", "Screenshots", "gallery_v1_wip")
OUT = os.path.join("ZeDUI", "workshop", "showcase", "review")
FONTS = os.path.join("ZeDUI", "workshop", "gallery", "fonts")

W = 1280                       # the graphic's width (Steam shows the description about 636 wide: twice that, sharp)
BG = (16, 16, 18)
ACCENT = (212, 146, 42)        # ZeD's default accent, #d4922a
INK = (16, 16, 18)
PAD = 16


def font(size):
    return ImageFont.truetype(os.path.join(FONTS, "FiraMono-Regular.ttf"), size)


def shot(name):
    return Image.open(os.path.join(SHOTS, name)).convert("RGB")


def chip(d, x, y, text, size=20, anchor="lt"):
    """A label: the accent's chip with dark words (ZeD's selected-tab look)."""
    f = font(size)
    l, t, r, b = d.textbbox((0, 0), text, font=f)
    w, h = r - l + 14, b - t + 10
    if anchor == "lb":
        y = y - h
    if anchor == "rt":
        x = x - w
    d.rectangle((x, y, x + w, y + h), fill=ACCENT)
    d.text((x + 7 - l, y + 5 - t), text, font=f, fill=INK)
    return (x, y, x + w, y + h)


def outline(d, box, width=4):
    x1, y1, x2, y2 = box
    for i in range(width):
        d.rectangle((x1 - i, y1 - i, x2 + i, y2 + i), outline=ACCENT)


def scaled(box, s, ox=0, oy=0):
    return tuple(int(v * s) + (ox if i % 2 == 0 else oy) for i, v in enumerate(box))


def inset_row(canvas, d, y, items, h):
    """Close-ups side by side, each cropped from a 4K shot and scaled to height h, centred as a row.
    items: (shot name, crop box, label, [boxes inside the crop to outline])"""
    pics = []
    for name, crop, label, marks in items:
        im = shot(name).crop(crop)
        s = h / im.height
        pics.append((im.resize((int(im.width * s), h), Image.LANCZOS), s, crop, label, marks))
    total = sum(p[0].width for p in pics) + PAD * (len(pics) - 1)
    x = (W - total) // 2
    for im, s, crop, label, marks in pics:
        canvas.paste(im, (x, y))
        d.rectangle((x - 1, y - 1, x + im.width, y + im.height), outline=(70, 70, 76))
        for m in marks:
            outline(d, scaled((m[0] - crop[0], m[1] - crop[1], m[2] - crop[0], m[3] - crop[1]), s, x, y), 3)
        chip(d, x, y + h, label, 18, "lb")
        x += im.width + PAD


def slot1():
    """Two windows instead of dozens; Your stuff."""
    full = shot("zed_11i_food_card.png")
    s = W / full.width
    top = full.resize((W, int(full.height * s)), Image.LANCZOS)
    inset_h = 300
    H = top.height + PAD + inset_h + PAD
    canvas = Image.new("RGB", (W, H), BG)
    canvas.paste(top, (0, 0))
    d = ImageDraw.Draw(canvas)
    # where the two windows are on the screen
    char_box = scaled((4, 4, 798, 738), s)
    world_box = scaled((2658, 4, 3836, 738), s)
    outline(d, char_box)
    outline(d, world_box)
    chip(d, char_box[0] + 6, char_box[3] + 8, "CHARACTER WINDOW", 20)
    chip(d, world_box[2] - 6, world_box[3] + 8, "WORLD WINDOW", 20, "rt")
    chip(d, scaled((3372, 0, 0, 0), s)[0], scaled((0, 706, 0, 0), s)[1] - 30, "ITEM CARD", 16)
    # the close-ups: the grid, a glance under the pointer, the whole card
    inset_row(canvas, d, top.height + PAD, [
        ("zed_53b_grid_tinted.png", (20, 40, 790, 560), "LIST OR GRID", []),
        ("zed_11g_food_glance.png", (880, 0, 1870, 600), "A GLANCE", [(1558, 165, 1857, 350)]),
        ("zed_11i_food_card.png", (3240, 60, 3780, 700), "THE WHOLE CARD", []),
    ], inset_h)
    return canvas


# QA's showcase captures (SHOWCASE_CAPTURES.md, Nov 18 2026) for slots 2 to 4
SC = os.path.join(os.path.expanduser("~"), "Zomboid", "Screenshots", "showcase")


def top_shot(name, folder=None):
    """A whole 4K screen scaled to the graphic's width, and its scale."""
    full = Image.open(os.path.join(folder or SC, name)).convert("RGB")
    s = W / full.width
    return full.resize((W, int(full.height * s)), Image.LANCZOS), s


def slot4():
    """Before you play (the desk, the mod manager); On a server has no shot (no server kit run)."""
    global SHOTS
    SHOTS = SC
    top, s = top_shot("sc4_mods_conflict.png")
    inset_h = 225
    H = top.height + PAD + inset_h + PAD
    canvas = Image.new("RGB", (W, H), BG)
    canvas.paste(top, (0, 0))
    d = ImageDraw.Draw(canvas)
    folders = scaled((1020, 572, 1878, 1948), s)
    conflict = scaled((1902, 748, 2822, 1040), s)
    profile = scaled((2492, 304, 2652, 342), s)
    outline(d, folders)
    outline(d, conflict)
    outline(d, profile, 3)
    chip(d, folders[0], folders[3] + 8, "FOLDERS", 20)
    chip(d, conflict[0], conflict[3] + 8, "CONFLICTS AND THEIR FIXES", 20)
    chip(d, profile[2], profile[3] + 8, "PROFILE IN USE", 16, "rt")
    inset_row(canvas, d, top.height + PAD, [
        ("sc4_desk.png", (1340, 240, 2880, 1160), "A 1993 DESK", []),
        ("sc4_profiles.png", (1010, 350, 2300, 1000), "PROFILES AND LOAD ORDER", []),
        ("sc4_mods.png", (1900, 690, 2800, 1180), "WARNINGS BEFORE YOU TURN IT OFF", []),
    ], inset_h)
    return canvas


SLOTS = {1: ("two_windows", slot1), 4: ("mod_manager", slot4)}


def main():
    os.makedirs(OUT, exist_ok=True)
    # (slot 1 is Design's labeled version now: only the slots named on the command line are made)
    for n in [int(a) for a in sys.argv[1:]]:
        name, fn = SLOTS[n]
        im = fn()
        p = os.path.join(OUT, "%d_%s.jpg" % (n, name))
        im.save(p, "JPEG", quality=90, optimize=True, progressive=True)
        print(p, im.size, os.path.getsize(p))


if __name__ == "__main__":
    main()
