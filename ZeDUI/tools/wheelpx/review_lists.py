"""Review sheet for the two lists' icons (i_lists): the six drawings zoomed, then where they live, drawn in the
game's colours at 1x and at the director's 1.75 (the 16 and 24 drawings doubled at 2x zoom): a right-click menu
with Save to outfit / Save to loadout, the item card's mark strip, the Journal page's two list rows."""
import os, sys
from PIL import Image, ImageDraw, ImageFont
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import allicons  # noqa
import review as R
from kit import render

FD = "/usr/share/fonts/truetype/dejavu/"
DARK = dict(bg=(30, 31, 34), surf=(44, 46, 50), border=(80, 84, 90), text=(226, 226, 220), dim=(150, 150, 146), acc=(232, 160, 40), onacc=(20, 20, 20))
LIGHT = dict(bg=(214, 214, 208), surf=(238, 238, 234), border=(120, 120, 116), text=(24, 24, 24), dim=(96, 96, 92), acc=(232, 160, 40), onacc=(20, 20, 20))


def ico(id_, size, col, k=1):
    im = render(id_, 16 if size == 16 else 24)
    im = R.tint(im, col + (255,))
    return im.resize((im.width * k, im.height * k), Image.NEAREST)


def panel(th, k):
    """one theme's panel at zoom k (1 or 2): the menu, the mark strip, the Journal rows"""
    f = ImageFont.truetype(FD + "DejaVuSans.ttf", 12 * k); fb = ImageFont.truetype(FD + "DejaVuSans-Bold.ttf", 12 * k)
    W, H = 560 * k, 210 * k
    im = Image.new("RGBA", (W, H), th["bg"] + (255,)); d = ImageDraw.Draw(im)
    # the right-click menu
    x0, y0, mw, rh = 10 * k, 10 * k, 190 * k, 22 * k
    rows = [("hanger", "Wear"), ("outfit_add", "Save to outfit  ▸"), ("loadout_add", "Save to loadout  ▸"), ("to_floor", "Drop")]
    d.rectangle((x0, y0, x0 + mw, y0 + rh * len(rows) + 4 * k), fill=th["surf"] + (255,), outline=th["border"] + (255,))
    for i, (ic, t) in enumerate(rows):
        y = y0 + 2 * k + i * rh
        on = i == 1
        if on: d.rectangle((x0 + 1, y, x0 + mw - 1, y + rh - 1), fill=th["acc"] + (255,))
        col = th["onacc"] if on else th["text"]
        im.alpha_composite(ico(ic, 16, col, k), (x0 + 4 * k, y + 3 * k))
        d.text((x0 + 26 * k, y + 4 * k), t, font=f, fill=col + (255,))
    # its submenu: the saved outfits, and a new one
    sx = x0 + mw + 2 * k; sub = ["Hiking", "Winter coat", "New outfit…"]
    d.rectangle((sx, y0 + rh, sx + 140 * k, y0 + rh + rh * 3 + 4 * k), fill=th["surf"] + (255,), outline=th["border"] + (255,))
    for i, t in enumerate(sub):
        y = y0 + rh + 2 * k + i * rh
        im.alpha_composite(ico("outfit", 16, th["text"], k), (sx + 4 * k, y + 3 * k))
        d.text((sx + 26 * k, y + 4 * k), t, font=f, fill=th["text"] + (255,))
    # the item card's mark strip: star, craft off, bin, then outfit and loadout (in the outfit: lit; not in the loadout: ink)
    mx, my = 370 * k, 14 * k
    d.text((mx, my - 2 * k), "Mark strip", font=fb, fill=th["dim"] + (255,))
    my += 18 * k
    marks = [("star", False), ("craft_off", False), ("trash", False), ("outfit", True), ("loadout", False)]
    for i, (ic, lit) in enumerate(marks):
        cx = mx + i * 34 * k
        d.rectangle((cx, my, cx + 28 * k, my + 28 * k), fill=(th["acc"] if lit else th["surf"]) + (255,), outline=th["border"] + (255,))
        im.alpha_composite(ico(ic, 24, th["onacc"] if lit else th["text"], k), (cx + 2 * k, my + 2 * k))
    d.text((mx, my + 32 * k), "in the outfit: lit", font=f, fill=th["dim"] + (255,))
    # the Journal page's rows
    jx, jy = 10 * k, 120 * k
    d.text((jx, jy), "Journal: Lists", font=fb, fill=th["dim"] + (255,))
    for i, (ic, t, n) in enumerate((("outfit", "Hiking", "6 pieces"), ("loadout", "Supply run", "14 items"), ("loadout", "Long haul", "22 items"))):
        y = jy + 18 * k + i * 22 * k
        d.rectangle((jx, y, jx + 340 * k, y + 20 * k), fill=th["surf"] + (255,), outline=th["border"] + (255,))
        im.alpha_composite(ico(ic, 16, th["text"], k), (jx + 4 * k, y + 2 * k))
        d.text((jx + 26 * k, y + 3 * k), t, font=f, fill=th["text"] + (255,))
        d.text((jx + 260 * k, y + 3 * k), n, font=f, fill=th["dim"] + (255,))
    return im


def main(out):
    big = R.sheet(["outfit", "outfit_add", "outfit_remove", "loadout", "loadout_add", "loadout_remove"], "_lists_cells.png", k=6, per=3)
    parts = [big] + [panel(th, k) for k in (1, 2) for th in (DARK, LIGHT)]
    W = max(p.width for p in parts) + 40
    H = sum(p.height for p in parts) + 30 * len(parts) + 40
    s = Image.new("RGBA", (W, H), (58, 62, 52, 255)); d = ImageDraw.Draw(s)
    fh = ImageFont.truetype(FD + "DejaVuSans-Bold.ttf", 16)
    labels = ["Outfit and loadout: 16 at rest, 24 pointed", "Dark, 1x", "Light, 1x", "Dark, 1.75 (2x zoom)", "Light, 1.75 (2x zoom)"]
    y = 14
    for p, t in zip(parts, labels):
        d.text((20, y), t, font=fh, fill=(230, 230, 220)); y += 24
        s.alpha_composite(p, (20, y)); y += p.height + 10
    s.save(out); print("wrote", out, s.size)


if __name__ == "__main__":
    main(sys.argv[1])
