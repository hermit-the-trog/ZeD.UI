"""Review sheets for the container row's icons (i_row.py plus the three taken from the wheels), written to
ZeDUI/mockups/zed_strip_icons_v1/:
  review_catalogue.png   every button: today's picture, the new 16 (at rest) and 24 at 5x and 4x, both at 1x
  review_rows_dark.png   the row in both windows, before and after, at 1x (and 1x doubled to read) and 1.75x
  review_rows_light.png  the same in the light theme
  review_true_size.png   every icon at the sizes the row draws it (1x, 1.25x, 1.5x, 1.75x, 2x), no zoom
The row draws an icon the way the wheels do: the largest drawing (16, 24, 32 = 16 doubled, 48 = 24 doubled) that
fits the button's 16-unit icon box, at its own size, centred, never stretched."""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import allicons  # noqa: F401
from kit import render
from review import cell, PAPER, ACC

ROOT = os.path.normpath(os.path.join(HERE, "..", "..", ".."))
OUT = os.path.join(ROOT, "ZeDUI", "mockups", "zed_strip_icons_v1")
OLD = os.path.join(ROOT, "42", "media", "textures", "ZeD", "icons")
FONTS = os.path.join(ROOT, "zed_backups", "fonts_for_desc")
os.makedirs(OUT, exist_ok=True)

# (id, the button, today's picture, from the wheels?)
BUTTONS = [
    ("tray_out", "Transfer all (your side)", "inbox-out", False),
    ("tray_in", "Take all (the other side)", "inbox-in", False),
    ("same_type", "Same type", "copy", False),
    ("same_nearby", "Same type, all nearby", "arrows-from-dotted-line", False),
    ("to_floor", "To floor", "fi-br-arrow-down-to-dotted-line", False),
    ("trash", "Delete all (a trash can)", "trash", False),
    ("power", "On / off (stove, washer, dryer, barbecue)", "power", False),
    ("gears", "Settings (a stove)", "settings", True),
    ("match", "Light (a campfire)", "fi-br-match-fire", False),
    ("campfire", "Add fuel (a campfire)", "fi-br-campfire", True),
    ("extinguisher", "Put out (a campfire)", "fi-br-fire-extinguisher", False),
    ("padlock", "Lock trunk (a car)", "lock", True),
    ("star", "Fav (item card)", "essential-collection-128-like", False),
    ("craft_off", "No-craft (item card)", "text-editor-052-save", False),
]

SCREENS = [   # the other windows' licensed pictures (outside the right-click menu)
    ("view_list", "List view (containers, equipment, maps list, appearance)", "list", False),
    ("view_grid", "Grid / pictures view (containers, appearance)", "apps", False),
    ("stand", "Doll view (equipment tab)", "equip-doll", True),
    ("expand", "Unfold to a window (maps, radio)", "expand", False),
    ("contract", "Fold back (maps, radio)", "contract", False),
    ("pop_out", "Pop out (an appliance station)", "arrow-up-right-from-square", False),
    ("no", "Delete a row / remove a block", "cross-small", True),
    ("move_up", "Move a block up (description editor)", "arrow-up", False),
    ("move_down", "Move a block down (description editor)", "arrow-down", False),
    ("pencil", "Draw on the map (with Draw On Map)", "edit", False),
    ("car_exit", "A door in the seat chooser", "exit", True),
    ("help", "A question (ZeD's prompt)", "question", True),
    ("info", "A note (ZeD's prompt)", "info", True),
    ("stop", "Stop: a costly step (ZeD's prompt)", "octagon-minus", False),
    ("star", "A favourite mod (Mods screen)", "icon-star", False),
]

THEMES = {
    "dark": dict(warning=(196, 154, 42), win=(20, 20, 20), band=(28, 28, 28), line=(32, 32, 32), border=(56, 56, 56),
                 text=(218, 218, 218), dim=(150, 150, 150), accent=(212, 146, 42), on_acc=(12, 12, 12),
                 hover=(212, 146, 42, 56), danger=(196, 90, 42), row=(24, 24, 24)),
    "light": dict(warning=(107, 85, 16), win=(190, 190, 190), band=(182, 182, 182), line=(150, 150, 150), border=(118, 118, 118),
                  text=(12, 12, 12), dim=(60, 60, 60), accent=(122, 80, 16), on_acc=(242, 240, 236),
                  hover=(122, 80, 16, 38), danger=(122, 42, 17), row=(196, 196, 196)),
}
BG = (40, 42, 36)
LABEL = (232, 232, 222)
HEAD = (232, 160, 40)


def font(px, bold=False):
    name = "FiraMono-Bold.ttf" if bold else "FiraMono-Regular.ttf"
    try: return ImageFont.truetype(os.path.join(FONTS, name), px)
    except OSError: return ImageFont.load_default()


def sans(px):
    try: return ImageFont.truetype(os.path.join(FONTS, "FiraSans-Regular.ttf"), px)
    except OSError: return ImageFont.load_default()


def P(u, sc): return int(u * sc + 0.5)


# ------------------------------------------------------------------ the icon at a box, the way the game picks it
def drawing_for(id_, box):
    """the largest of 48, 32, 24, 16 that fits the box (32 and 48 are the 16 and 24 doubled)"""
    for sz in (48, 32, 24, 16):
        if sz <= box:
            base = render(id_, 16 if sz in (16, 32) else 24)
            return base.resize((sz, sz), Image.NEAREST) if sz != base.width else base
    return render(id_, 16).resize((box, box), Image.BOX)


def old_for(name, box):
    """today's picture: a Flaticon PNG fitted into the box (the game filters it smooth)"""
    im = Image.open(os.path.join(OLD, name + ".png")).convert("RGBA")
    im.thumbnail((box, box), Image.LANCZOS)
    return im


def tinted(im, col, a=255):
    out = Image.new("RGBA", im.size, col + (0,) if len(col) == 3 else col)
    al = im.getchannel("A").point(lambda q: q * a // 255)
    out.putalpha(al); return out


# ------------------------------------------------------------------ a button, the way Molecules draws it
def rounded(d, x, y, w, h, col, hair, fill):
    rad = (2, 1)
    for i, inset in enumerate(rad):
        ix = inset * hair
        if fill:
            d.rectangle([x + ix, y + i * hair, x + w - ix - 1, y + (i + 1) * hair - 1], fill=col)
            d.rectangle([x + ix, y + h - (i + 1) * hair, x + w - ix - 1, y + h - i * hair - 1], fill=col)
        else:
            d.rectangle([x + ix, y + i * hair, x + w - ix - 1, y + (i + 1) * hair - 1], fill=col)
            d.rectangle([x + ix, y + h - (i + 1) * hair, x + w - ix - 1, y + h - i * hair - 1], fill=col)
    top = len(rad) * hair
    if fill: d.rectangle([x, y + top, x + w - 1, y + h - top - 1], fill=col)
    else:
        d.rectangle([x, y + top, x + hair - 1, y + h - top - 1], fill=col)
        d.rectangle([x + w - hair, y + top, x + w - 1, y + h - top - 1], fill=col)


def icon_button(im, x, y, sc, th, picture, lit=False, hover=False, danger=False):
    d = ImageDraw.Draw(im, "RGBA")
    bh, hair = P(26, sc), max(1, P(1, sc))
    if lit: rounded(d, x, y, bh, bh, th["accent"], hair, True)
    elif hover:
        ov = Image.new("RGBA", im.size, (0, 0, 0, 0)); rounded(ImageDraw.Draw(ov), x, y, bh, bh, th["hover"], hair, True)
        im.alpha_composite(ov)
    rounded(d, x, y, bh, bh, th["accent"] if lit else th["border"], hair, False)
    col = th["on_acc"] if lit else (th["danger"] if danger else th["text"])
    pic = tinted(picture, col)
    ix = x + (bh - pic.width) // 2; iy = y + (bh - pic.height) // 2
    im.alpha_composite(pic, (ix, iy))
    return bh


def word_button(im, x, y, sc, th, word):
    d = ImageDraw.Draw(im, "RGBA")
    bh, hair = P(26, sc), max(1, P(1, sc))
    f = font(P(11, sc))
    tw = int(d.textlength(word, font=f))
    w = max(tw + 2 * P(10, sc), P(60, sc))
    rounded(d, x, y, w, bh, th["border"], hair, False)
    asc, desc = f.getmetrics()
    d.text((x + (w - tw) // 2, y + (bh - asc - desc) // 2), word, fill=th["text"], font=f)
    return w


def band(win_w, sc, th, moves, objs, old=False):
    """the row: moves from the left, a divider, the container's own at the right (words first, then icons).
    a button: ("i", id, old name, opts) or ("w", word)"""
    bh = P(26, sc); H = bh + 2 * P(5, sc)
    im = Image.new("RGBA", (win_w, H), th["band"] + (255,))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, win_w - 1, max(1, P(1, sc)) - 1], fill=th["border"])
    box = P(16, sc)
    y = (H - bh) // 2

    def width(b):
        if b[0] == "i": return bh
        f = font(P(11, sc)); tw = int(d.textlength(b[1], font=f)); return max(tw + 2 * P(10, sc), P(60, sc))

    def gap(a, b):
        return P(4, sc) if (a[0] == "i" and b[0] == "i") else P(8, sc)

    def put(b, x):
        if b[0] == "w": return word_button(im, x, y, sc, th, b[1])
        o = b[3] if len(b) > 3 else {}
        pic = old_for(b[2], box) if old else drawing_for(b[1], box)
        return icon_button(im, x, y, sc, th, pic, **o)

    x = P(8, sc)
    for i, b in enumerate(moves):
        put(b, x); x += width(b) + (gap(b, moves[i + 1]) if i + 1 < len(moves) else 0)
    if objs:
        ow = sum(width(b) for b in objs) + sum(gap(objs[i - 1], objs[i]) for i in range(1, len(objs)))
        ox = win_w - P(8, sc) - ow
        dx = ox - P(5, sc) - P(1, sc)
        d.rectangle([dx, y, dx + P(1, sc) - 1, y + bh - 1], fill=th["border"])
        for i, b in enumerate(objs):
            put(b, ox); ox += width(b) + (gap(b, objs[i + 1]) if i + 1 < len(objs) else 0)
    return im


def I(id_, old, **o): return ("i", id_, old, o)


CHAR = [I("tray_out", "inbox-out"), I("same_type", "copy"), I("same_nearby", "arrows-from-dotted-line")]
WORLD = [I("tray_in", "inbox-in"), I("same_type", "copy"), I("to_floor", "fi-br-arrow-down-to-dotted-line")]
ROWS = [
    ("Character window: your bag", CHAR, []),
    ("World window: a crate (Take all pointed at)", [I("tray_in", "inbox-in", hover=True)] + WORLD[1:], []),
    ("World window: the floor (no To floor there)", WORLD[:2], []),
    ("World window: a stove, switched on", WORLD, [I("power", "power", lit=True), I("gears", "settings")]),
    ("World window: a washer-dryer, off", WORLD, [("w", "Mode: dryer"), I("power", "power")]),
    ("World window: a campfire", WORLD, [("w", "Take apart"), I("match", "fi-br-match-fire"), I("campfire", "fi-br-campfire"),
                                        I("extinguisher", "fi-br-fire-extinguisher")]),
    ("World window: a trash can", WORLD, [I("trash", "trash", danger=True)]),
    ("World window: a car's trunk", WORLD, [("w", "Close trunk"), I("padlock", "lock")]),
]


def rows_sheet(theme, path):
    th = THEMES[theme]
    parts = []
    for sc, zoom, title in ((1.0, 2, "1x (a 1080p screen), shown doubled so the pixels read"), (1.75, 1, "1.75x (a 4K screen), true size")):
        win_w = P(330, sc)
        blocks = []
        for label, moves, objs in ROWS:
            a = band(win_w, sc, th, moves, objs, old=True)
            b = band(win_w, sc, th, moves, objs, old=False)
            if zoom > 1:
                a = a.resize((a.width * zoom, a.height * zoom), Image.NEAREST)
                b = b.resize((b.width * zoom, b.height * zoom), Image.NEAREST)
            blocks.append((label, a, b))
        parts.append((title, blocks))
    lf, hf = sans(15), sans(19)
    colw = max(b[1].width for _, bl in parts for b in bl)
    H = 70
    for _, bl in parts: H += 44 + sum(26 + max(b[1].height, b[2].height) + 24 for b in bl)
    W = 2 * colw + 260
    s = Image.new("RGBA", (W, H), BG + (255,)); d = ImageDraw.Draw(s)
    d.text((24, 18), "The container row: today's pictures (left) and the new pixel icons (right), " + theme + " theme", fill=LABEL, font=hf)
    y = 70
    for title, bl in parts:
        d.text((24, y), title, fill=HEAD, font=hf); y += 44
        d.text((24, y - 22), "", fill=LABEL)
        for label, a, b in bl:
            d.text((24, y), label, fill=LABEL, font=lf); y += 26
            s.alpha_composite(a, (24, y)); s.alpha_composite(b, (24 + colw + 60, y))
            y += max(a.height, b.height) + 6 + 18
    d.text((24 + colw // 2 - 30, 44), "today", fill=(170, 170, 160), font=lf)
    d.text((24 + colw + 60 + colw // 2 - 20, 44), "new", fill=(170, 170, 160), font=lf)
    s = s.crop((0, 0, W, y + 10))
    s.save(os.path.join(OUT, path))


def catalogue(path, buttons=None, title=None):
    lf, hf, sf = sans(16), sans(20), sans(13)
    rowh = 33 * 4 + 40
    buttons = buttons or BUTTONS
    W = 1500; H = 90 + len(buttons) * rowh
    s = Image.new("RGBA", (W, H), BG + (255,)); d = ImageDraw.Draw(s)
    d.text((24, 18), title or "The container row's icons: today, then the new drawings (16 at rest on paper at 5x, 24 on the accent at 4x, both at 1x)", fill=LABEL, font=hf)
    d.text((24, 50), "orange name = taken from the wheel icons as they are (signed off Oct 27)", fill=(170, 170, 160), font=sf)
    y = 90
    for id_, name, old, reused in buttons:
        d.text((24, y + 8), name, fill=LABEL, font=lf)
        d.text((24, y + 32), id_ + ("  (from the wheels)" if reused else ""), fill=HEAD if reused else (170, 170, 160), font=sf)
        o = Image.open(os.path.join(OLD, old + ".png")).convert("RGBA"); o.thumbnail((64, 64), Image.LANCZOS)
        s.alpha_composite(tinted(o, (230, 230, 220)), (360, y + 20))
        a = cell(render(id_, 16), 22, PAPER); b = cell(render(id_, 24), 33, ACC)
        s.alpha_composite(a.resize((a.width * 5, a.height * 5), Image.NEAREST), (470, y + 10))
        s.alpha_composite(b.resize((b.width * 4, b.height * 4), Image.NEAREST), (470 + 22 * 5 + 30, y))
        x1 = 470 + 22 * 5 + 30 + 33 * 4 + 40
        s.alpha_composite(a, (x1, y + 20)); s.alpha_composite(b, (x1 + 32, y + 14))
        # on the dark row, at 1x and 1.75x, as the game draws it
        th = THEMES["dark"]
        for k, sc in enumerate((1.0, 1.75)):
            box = P(16, sc); bh = P(26, sc)
            tile = Image.new("RGBA", (bh + 8, bh + 8), th["band"] + (255,))
            icon_button(tile, 4, 4, sc, th, drawing_for(id_, box))
            s.alpha_composite(tile, (x1 + 100 + k * 70, y + 10))
        y += rowh
    d.text((360, 70), "today", fill=(170, 170, 160), font=sf)
    d.text((470, 70), "new: 16 and 24, zoomed", fill=(170, 170, 160), font=sf)
    d.text((470 + 22 * 5 + 30 + 33 * 4 + 40, 70), "1x        in the row at 1x, 1.75x", fill=(170, 170, 160), font=sf)
    s.save(os.path.join(OUT, path))


def true_size(path):
    """every icon in its button at each UI scale, no zoom: what a player sees"""
    th = THEMES["dark"]
    scales = (1.0, 1.25, 1.5, 1.75, 2.0)
    sf = sans(14)
    W = 140 + len(BUTTONS) * 64; H = 60 + len(scales) * 64
    s = Image.new("RGBA", (W, H), th["band"] + (255,)); d = ImageDraw.Draw(s)
    d.text((16, 14), "At true size, in the row's button, each UI scale (the drawing the game picks: 16, 16, 24, 24, 32)", fill=LABEL, font=sf)
    for r, sc in enumerate(scales):
        y = 50 + r * 64
        d.text((16, y + 14), f"{sc:g}x", fill=LABEL, font=sf)
        for i, (id_, *_rest) in enumerate(BUTTONS):
            icon_button(s, 100 + i * 64, y, sc, th, drawing_for(id_, P(16, sc)), danger=(id_ == "trash"))
    s.save(os.path.join(OUT, path))


# ------------------------------------------------------------------ the item card's marks (Fav, No-craft, Dispose)
MARKS = [("fav", "Fav", "star", "accent"), ("nocraft", "No-craft", "craft_off", "warning"), ("dispose", "Dispose", "trash", "danger")]


def frame(d, x, y, w, h, col, hair):
    d.rectangle([x, y, x + w - 1, y + hair - 1], fill=col); d.rectangle([x, y + h - hair, x + w - 1, y + h - 1], fill=col)
    d.rectangle([x, y, x + hair - 1, y + h - 1], fill=col); d.rectangle([x + w - hair, y, x + w - 1, y + h - 1], fill=col)


def card_strip(sc, th, compact, style, on):
    """style: "today" (the square and words / the square and a letter), "chip" (the icon in place of the square),
    "button" (icon buttons, solid in the mark's colour when on)"""
    W = P(220 if compact else 480, sc)
    H = P(24 if compact else 28, sc)
    hair = max(1, P(1, sc))
    im = Image.new("RGBA", (W, H), th["win"] + (255,)); d = ImageDraw.Draw(im, "RGBA")
    d.rectangle([0, H - hair, W - 1, H - 1], fill=th["line"])
    f1 = font(P(11, sc), bold=True)
    asc, desc = f1.getmetrics()
    lbl = "MARKED"
    x = P(8 if compact else 12, sc)
    d.text((x, (H - asc - desc) // 2), lbl, fill=th["dim"], font=f1)
    x += int(d.textlength(lbl, font=f1)) + P(2 if compact else 4, sc)
    gap = P(4 if compact else 6, sc)
    box = P(16, sc)
    for k, word, ic, colk in MARKS:
        is_on = k in on
        mark = th[colk] if is_on else th["dim"]
        tc = th["text"] if is_on else th["dim"]
        if style == "today":
            h = P(18, sc); y = (H - h) // 2 - (0 if compact else 0)
            sq = P(6, sc)
            glyph = {"fav": "*", "nocraft": "o", "dispose": "x"}[k]
            text = glyph if compact else word
            tw = int(d.textlength(text, font=f1))
            w = max(P(22, sc), sq + P(3, sc) + tw + 2 * P(5, sc)) if not compact else P(22, sc)
            frame(d, x, y, w, h, th["border"], hair)
            cx = x + (w - (sq + P(3, sc) + tw)) // 2; sy = y + (h - sq) // 2
            if is_on: d.rectangle([cx, sy, cx + sq - 1, sy + sq - 1], fill=mark)
            else: frame(d, cx, sy, sq, sq, mark, hair)
            d.text((cx + sq + P(3, sc), y + (h - asc - desc) // 2), text, fill=tc, font=f1)
        elif style == "chip":
            h = P(22, sc); y = (H - h) // 2
            pic = drawing_for(ic, box)
            tw = 0 if compact else int(d.textlength(word, font=f1))
            inner = pic.width + (0 if compact else P(4, sc) + tw)
            w = P(22, sc) if compact else inner + 2 * P(5, sc)
            frame(d, x, y, w, h, th["border"], hair)
            cx = x + (w - inner) // 2
            im.alpha_composite(tinted(pic, mark), (cx, y + (h - pic.height) // 2))
            if not compact: d.text((cx + pic.width + P(4, sc), y + (h - asc - desc) // 2), word, fill=tc, font=f1)
        else:
            h = P(22, sc); y = (H - h) // 2; w = h
            if is_on: rounded(d, x, y, w, h, th[colk], hair, True)
            rounded(d, x, y, w, h, th[colk] if is_on else th["border"], hair, False)
            pic = drawing_for(ic, box)
            im.alpha_composite(tinted(pic, th["on_acc"] if is_on else th["text"]), (x + (w - pic.width) // 2, y + (h - pic.height) // 2))
        x += w + gap
    return im


def card_sheet(path):
    lf, hf = sans(15), sans(19)
    blocks = []
    on = {"fav", "dispose"}
    for theme in ("dark", "light"):
        th = THEMES[theme]
        for sc, zoom in ((1.0, 2), (1.75, 1)):
            row = []
            for compact in (False, True):
                for style, name in (("today", "today"), ("chip", "A: the icon takes the square's place, words kept"),
                                    ("button", "B: icon buttons, words in the hover hint")):
                    if compact and style == "button": continue
                    im = card_strip(sc, th, compact, style, on)
                    if zoom > 1: im = im.resize((im.width * zoom, im.height * zoom), Image.NEAREST)
                    row.append((("narrow card: " + ("today (a square and a letter)" if style == "today" else "the icon alone")) if compact else ("wide card: " + name), im))
            blocks.append((f"{theme} theme, {sc:g}x" + (" (shown doubled)" if zoom > 1 else " (true size)"), row))
    W = 24 + max(im.width for _, r in blocks for _, im in r) + 24
    H = 70 + sum(40 + sum(24 + im.height + 14 for _, im in r) for _, r in blocks)
    s = Image.new("RGBA", (W, H), BG + (255,)); d = ImageDraw.Draw(s)
    d.text((24, 18), "The item card's marks (Fav on, No-craft off, Dispose on): today, and two ways to carry the new icons", fill=LABEL, font=hf)
    y = 64
    for title, r in blocks:
        d.text((24, y), title, fill=HEAD, font=hf); y += 36
        for name, im in r:
            d.text((24, y), name, fill=LABEL, font=lf); y += 22
            s.alpha_composite(im, (24, y)); y += im.height + 14
        y += 8
    s.crop((0, 0, W, y + 10)).save(os.path.join(OUT, path))


if __name__ == "__main__":
    catalogue("review_catalogue.png")
    rows_sheet("dark", "review_rows_dark.png")
    rows_sheet("light", "review_rows_light.png")
    true_size("review_true_size.png")
    card_sheet("review_card_marks.png")
    catalogue("review_catalogue_screens.png", SCREENS, "The other windows' licensed pictures: today, then the new drawings (16 on paper at 5x, 24 on the accent at 4x, both at 1x)")
    print("sheets in", OUT)
