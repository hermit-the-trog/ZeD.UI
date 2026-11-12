"""The Workshop gallery as a worked-through 1993 manual (director, Nov 1 2026; docs/handoffs/HANDOFF_gallery_manual_20261101.md).

Every slide is the book lying open: one 1920 x 1080 picture, two facing pages. What is printed is the publisher's
(Doidbros & Buzzlord Division of Informatics Publishing LLC; the author, Ann Sibyl), set as a 1993 manual: a serif
body in a measured column, bold sans headings, monospace for anything typed, numbered figures and tables with printed
captions, a wide outer margin, running heads with the page numbers. What is on top is the reader's, the man who wrote
the kernel: his printed screenshots taped over the paragraphs they replace, his sticky notes (black pen), his
four-colour ballpoint in the margins (blue explains, red points, green circles).

Two page kinds, chosen per page in spreads.json: "taped" (screenshots taped over the printed page, a sticky note at
the bottom) and "manual" (the printed page carries it: words, a list, a table; only light marks from him).

Grids, as before: the desk and the book are pixel art at 4x (page_px.art_layer); print and ink are 1-bit at 2x; the
screenshots are printed crisp.
usage: python spread.py <spreads.json> <out dir> [--only id,id]"""
import argparse
import json
import math
import os
import random
import re
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import page_px as pp   # noqa: E402
try:
    from watch import stamp as watch_stamp   # the layout desk (watch.html); a render never needs it
except Exception:   # noqa: BLE001
    watch_stamp = None

FIRA = os.path.join(HERE, "fonts")          # Fira Sans SemiBold and Fira Mono, OFL (fonts/FONTS.md)
SERIF, SERIF_B, BALL = pp.SERIF, pp.SERIF_B, pp.BALL
SANS_B = os.path.join(FIRA, "FiraSans-SemiBold.ttf")
MONO = os.path.join(FIRA, "FiraMono-Regular.ttf")
OW, OH = pp.OW, pp.OH
PRN = pp.C["ink"]

# the open book on the art grid (page_px.art_layer): pages x 12-240 and 240-468, y 7-260, at 4x
GUT = 960
PAGES = {"left": (48, 960), "right": (960, 1872)}
TOP, BOT = 28, 1040
OUTER, INNER = 210, 70                     # the wide outer margin is where he writes
PRINT_PAPER, TAPE, STICKY = (241, 237, 226), (214, 198, 150), (238, 222, 118)

_fc = {}


def F(path, size):
    k = (path, size)
    if k not in _fc:
        _fc[k] = ImageFont.truetype(path, size)
    return _fc[k]


def column(side):
    x0, x1 = PAGES[side]
    return (x0 + OUTER, x1 - INNER) if side == "left" else (x0 + INNER, x1 - OUTER)


def ev(v):
    return int(round(v / 2.0)) * 2


# ---------------------------------------------------------------- print: 1-bit at 2x, on a shared baseline
REF = "(dfl|"     # drawn ahead of every run and cut off: the run's box then always spans the face's tallest and
                  # deepest marks, so every run is rasterised from the same baseline (alone, a short word like "is"
                  # sets 2 px higher than "card")


def tok(text, path, size):
    """A run of type, 1-bit, doubled. Returns (mask, x pad, baseline offset) so runs in different faces share a line."""
    f = F(path, size)
    asc, desc = f.getmetrics()
    m = Image.new("L", (int(math.ceil(f.getlength(REF + text))) + 10, asc + desc + 10), 0)
    d = ImageDraw.Draw(m); d.fontmode = "1"
    d.text((3, 3), REF + text, font=f, fill=255)
    m = m.crop((3 + int(round(f.getlength(REF))), 0, m.width, m.height))
    return m.resize((m.width * 2, m.height * 2), Image.NEAREST), 0, (3 + asc) * 2


def put_tok(canvas, text, path, size, x, base, col=PRN):
    m, pad, boff = tok(text, path, size)
    canvas.paste(col, (ev(x) - pad, ev(base) - boff), m)
    return F(path, size).getlength(text) * 2


STYLE = {"": SERIF, "b": SERIF_B, "m": MONO, "h": SANS_B}


def words_of(text):
    """'plain (*bold*). `typed`' -> words, each a list of (piece, style): punctuation stays on its word."""
    words, cur = [], []
    for run in re.split(r"(\*[^*]+\*|`[^`]+`)", text):
        if not run:
            continue
        st = "b" if run.startswith("*") else "m" if run.startswith("`") else ""
        for piece in re.split(r"(\s+)", run[1:-1] if st else run):
            if not piece:
                continue
            if piece.isspace():
                if cur: words.append(cur); cur = []
            else:
                cur.append((piece, st))
    if cur:
        words.append(cur)
    return words


def para(canvas, x0, y, width, text, size=11, lead=28, justify=True, boxes=None, size_m=None):
    """A paragraph set in the column: justified, the last line ragged. y is the first baseline. Records each word's
    box in `boxes` (for his circles and underlines). Returns the baseline after the paragraph."""
    ws = words_of(text)
    sp = F(SERIF, size).getlength(" ") * 2
    szof = lambda s: (size_m or size - 1) if s == "m" else size
    wid = [sum(F(STYLE[s], szof(s)).getlength(p) * 2 for p, s in w_) for w_ in ws]
    lines, cur, cw = [], [], 0
    for i, w_ in enumerate(wid):
        if cur and cw + sp + w_ > width:
            lines.append(cur); cur, cw = [i], w_
        else:
            cw += (sp if cur else 0) + w_; cur.append(i)
    if cur:
        lines.append(cur)
    for li, line in enumerate(lines):
        gap = sp
        if justify and li < len(lines) - 1 and len(line) > 1:
            gap = (width - sum(wid[i] for i in line)) / (len(line) - 1)
        x = x0
        for i in line:
            xx = x
            for p, s in ws[i]:
                xx += put_tok(canvas, p, STYLE[s], szof(s), xx, y)
            if boxes is not None:
                boxes.append(("".join(p for p, s in ws[i]).strip(".,;:()!?'"), (x, y - size * 2 + 2, x + wid[i], y + 6)))
            x += wid[i] + gap
        y += lead
    return y


def rule(d, x0, x1, y, w=2):
    d.rectangle((ev(x0), ev(y), ev(x1) - 1, ev(y) + w - 1), fill=PRN)


def running_head(canvas, d, side, page_no, text):
    c0, c1 = column(side)
    base = TOP + 50
    num = str(page_no)
    nw = F(SANS_B, 10).getlength(num) * 2
    tw = F(SERIF, 9).getlength(text) * 2
    if side == "left":
        put_tok(canvas, num, SANS_B, 10, c0, base); put_tok(canvas, text, SERIF, 9, c0 + nw + 28, base)
    else:
        put_tok(canvas, num, SANS_B, 10, c1 - nw, base); put_tok(canvas, text, SERIF, 9, c1 - nw - 28 - tw, base)
    rule(d, c0, c1, base + 12)


def table(canvas, d, x0, y, width, spec, boxes):
    """A table set in the column: its caption above, rules above and below and under the head."""
    cols = spec["cols"]                    # fractions of the width
    put_tok(canvas, spec["label"], SANS_B, 10, x0, y)
    put_tok(canvas, spec["title"], SERIF, 10, x0 + F(SANS_B, 10).getlength(spec["label"]) * 2 + 18, y)
    y += 18; rule(d, x0, x0 + width, y, 2); y += 30
    xs = [x0]
    for c in cols[:-1]:
        xs.append(xs[-1] + width * c)
    for k, h in enumerate(spec["head"]):
        put_tok(canvas, h, SANS_B, 10, xs[k], y)
    y += 12; rule(d, x0, x0 + width, y, 2); y += 30
    for row in spec["rows"]:
        bottoms = []
        for k, cell in enumerate(row):
            cw = (xs[k + 1] if k + 1 < len(xs) else x0 + width) - xs[k] - 20
            if k == 0:
                put_tok(canvas, cell, SERIF_B, 10, xs[k], y); bottoms.append(y + 26)
            else:
                bottoms.append(para(canvas, xs[k], y, cw, cell, size=10, lead=26, justify=False, boxes=boxes))
        y = max(bottoms) + 10
    rule(d, x0, x0 + width, y - 22, 2)
    return y + 12


def printed(canvas, d, side, blocks, boxes):
    """The publisher's page: the blocks down the column."""
    c0, c1 = column(side)
    width = c1 - c0
    y = TOP + 128
    for b in blocks:
        if "chapter" in b:
            n, title = b["chapter"]
            put_tok(canvas, n, SANS_B, 30, c0, y + 30)
            put_tok(canvas, title, SANS_B, 22, c0 + F(SANS_B, 30).getlength(n) * 2 + 30, y + 30)
            y += 54; rule(d, c0, c1, y, 4); y += 58
        elif "h2" in b:
            put_tok(canvas, b["h2"], SANS_B, 14, c0, y + 8); y += 50
        elif "p" in b:
            y = para(canvas, c0, y, width, b["p"], boxes=boxes) + 16
        elif "note" in b:                                    # the manual's own aside, set off with a rule
            rule(d, c0, c0 + 90, y - 22, 2)
            put_tok(canvas, "Note", SANS_B, 10, c0, y)
            y = para(canvas, c0 + 90, y, width - 90, b["note"], size=10, lead=26, justify=False, boxes=boxes) + 16
        elif "table" in b:
            y = table(canvas, d, c0, y, width, b["table"], boxes)
        elif "caption" in b:
            lab, txt = b["caption"]
            put_tok(canvas, lab, SANS_B, 10, c0, y)
            lw = F(SANS_B, 10).getlength(lab) * 2 + 18
            y = para(canvas, c0 + lw, y, width - lw, txt, size=10, lead=26, justify=False, boxes=boxes) + 16
        elif "list" in b:                                    # steps (numbered) or a bulleted list, hanging
            for k, item in enumerate(b["list"]):
                mark = ("%d." % (k + 1)) if b.get("numbered") else "•"
                put_tok(canvas, mark, SANS_B if b.get("numbered") else SERIF, 10 if b.get("numbered") else 11, c0 + 6, y)
                y = para(canvas, c0 + 44, y, width - 44, item, justify=False, boxes=boxes) + 6
            y += 10
        elif "code" in b:                                    # anything typed, in monospace, set in
            for ln in b["code"]:
                put_tok(canvas, ln, MONO, 10, c0 + 44, y); y += 26
            y += 14
        elif "gap" in b:
            y += b["gap"]
        elif "at" in b:
            y = b["at"]
    return y


# ---------------------------------------------------------------- what he put on the page
def darken(canvas, box, k):
    x0, y0, x1, y1 = [ev(v) for v in box]
    reg = canvas.crop((x0, y0, x1, y1)).point(lambda v: int(v * k))
    canvas.paste(reg, (x0, y0))


def resample_of(p):
    """How a print is scaled: Lanczos, but pixels doubled (nearest) at 2x, 3x.. so the UI stays crisp; "resample" overrides."""
    r = p.get("resample")
    if r is None:
        s = p["scale"]
        r = "nearest" if s >= 2 and abs(s - round(s)) < 1e-6 else "lanczos"
    return Image.NEAREST if r == "nearest" else Image.LANCZOS


def print_on(canvas, d, img, box, scale, at, border=10, resample=None):
    """His printed screenshot, crisp, on print paper with a narrow border, lying on the page.
    Returns a function from capture coordinates to the canvas."""
    bx0, by0, bx1, by1 = box
    tw, th = round((bx1 - bx0) * scale), round((by1 - by0) * scale)
    tile = img.crop(box).resize((tw, th), Image.LANCZOS if resample is None else resample)
    x, y = ev(at[0]), ev(at[1])
    darken(canvas, (x + 6, y + 8, x + tw + 2 * border + 6, y + th + 2 * border + 8), 0.72)    # it lies on the page
    d.rectangle((x, y, x + tw + 2 * border - 1, y + th + 2 * border - 1), fill=PRINT_PAPER)
    canvas.paste(tile, (x + border, y + border))
    return (lambda X, Y: (x + border + (X - bx0) * scale, y + border + (Y - by0) * scale)), (x, y, x + tw + 2 * border, y + th + 2 * border)


def tape(canvas, cx, cy, length, width, angle, seed):
    """A strip of masking tape on the 2x grid, a little see-through, both ends torn."""
    rng = random.Random(seed)
    lay = Image.new("RGBA", (OW // 2, OH // 2), (0, 0, 0, 0))
    a = math.radians(angle)
    ux, uy, vx, vy = math.cos(a), math.sin(a), -math.sin(a), math.cos(a)
    cx, cy, L, Wd = cx / 2, cy / 2, length / 4, width / 4
    pts = []
    for k in range(7):                      # one torn end
        t = -Wd + 2 * Wd * k / 6
        e = -L + rng.uniform(-1.2, 1.2)
        pts.append((cx + ux * e + vx * t, cy + uy * e + vy * t))
    for k in range(7):                      # the other
        t = Wd - 2 * Wd * k / 6
        e = L + rng.uniform(-1.2, 1.2)
        pts.append((cx + ux * e + vx * t, cy + uy * e + vy * t))
    ImageDraw.Draw(lay).polygon(pts, fill=TAPE + (212,))
    px = lay.load()
    for yy in range(int(cy - L - Wd - 3), int(cy + L + Wd + 3)):
        for xx in range(int(cx - L - Wd - 3), int(cx + L + Wd + 3)):
            if 0 <= xx < OW // 2 and 0 <= yy < OH // 2 and px[xx, yy][3]:
                r, g, b, al = px[xx, yy]
                n = rng.uniform(-10, 8)                      # crepe paper
                px[xx, yy] = (int(r + n), int(g + n), int(b + n), al)
    lay = lay.resize((OW, OH), Image.NEAREST)
    canvas.paste(lay, (0, 0), lay)


def sticky(canvas, d, x, y, w, h, text, size=16):
    """A sticky note stuck on the page, written on in black. With no h it is as tall as its writing.
    Returns (how tall the writing needs it, how tall it is drawn, its widest line)."""
    x, y, w = ev(x), ev(y), ev(w)
    masks = [pp.mask2(ln, BALL, size) for ln in pp.wrap(text, BALL, size, w - 36)]
    need = 36 + 36 * (len(masks) - 1) + (masks[-1].height if masks else 0) + 4
    h = ev(h) if h else ev(max(need + 18, 96))
    darken(canvas, (x + 6, y + 10, x + w + 6, y + h + 10), 0.7)
    d.rectangle((x, y, x + w - 1, y + h - 1), fill=STICKY)
    d.rectangle((x, y, x + w - 1, y + 21), fill=(229, 211, 104))          # the glued strip
    d.polygon([(x + w - 26, y + h), (x + w, y + h - 26), (x + w, y + h)], fill=(202, 186, 92))   # the corner lifts
    yy = y + 36
    for m in masks:
        pp.put(canvas, m, x + 18, yy, pp.C["blk"]); yy += 36
    return need, h, max((m.width for m in masks), default=0)


def scrawl(canvas, x, y, maxw, text, pen="blu", size=14, lead=31):
    """His handwriting. Returns the box it took."""
    wmax, yy = 0, y
    for k, ln in enumerate(pp.wrap(text, BALL, size, maxw)):
        m = pp.mask2(ln, BALL, size)
        pp.put(canvas, m, x, yy + (k % 2), pp.C[pen]); wmax = max(wmax, m.width); yy += lead
    return (x, y, x + wmax, yy - lead + 2 * size)


def circle(d, box, pen="grn", seed=0):
    """A loop round something, in a hurry: it overshoots where it started."""
    rng = random.Random(seed)
    x0, y0, x1, y1 = box
    cx, cy, rx, ry = (x0 + x1) / 2, (y0 + y1) / 2, (x1 - x0) / 2 + 12, (y1 - y0) / 2 + 9
    t0 = rng.uniform(0, 6.28)
    pts = [(cx + rx * (1 + 0.04 * math.sin(3 * t)) * math.cos(t0 + t), cy + ry * (1 + 0.05 * math.cos(2 * t)) * math.sin(t0 + t))
           for t in [i * 6.9 / 60 for i in range(61)]]
    pp.ink_line(d, pts, pp.C[pen])


def gutter(canvas, y0=TOP, y1=BOT):
    px = canvas.load()
    for x in range(GUT - 70, GUT + 70):
        k = 1 - 0.28 * (1 - abs(x - GUT) / 70) ** 2
        for y in range(y0, y1):
            o = px[x, y]; px[x, y] = (int(o[0] * k), int(o[1] * k), int(o[2] * k))


# ---------------------------------------------------------------- one spread
def overlap(a, b, pad=0):
    return a[0] - pad < b[2] and b[0] - pad < a[2] and a[1] - pad < b[3] and b[1] - pad < a[3]


def render(sp, screens, out_path):
    """Returns the CHECK lines: what a look at the picture should confirm or fix."""
    checks = []
    seed = sp.get("seed", sp["n"])            # the paper and tape keep the chapter number they were approved under
    art, geom = pp.art_layer(seed * 97)
    canvas = art.resize((OW, OH), Image.NEAREST).convert("RGB")
    d = ImageDraw.Draw(canvas)
    boxes = {"left": [], "right": []}
    for side in ("left", "right"):
        pg = sp[side]
        running_head(canvas, d, side, sp["pages"][0 if side == "left" else 1], pg.get("head", ""))
        end = printed(canvas, d, side, pg.get("blocks", []), boxes[side])
        if end > BOT - 24:
            checks.append("%s page: the print runs past the foot of the page (to y %d)" % (side, end))
    imgs, maps, pboxes, tapes = {}, [], [], []
    for side in ("left", "right"):                               # his prints, taped over the paragraphs
        for k, p in enumerate(sp[side].get("prints", [])):
            psrc = pp.home_path(p["src"])
            src = psrc if os.path.isabs(psrc) else os.path.join(screens, psrc)
            if src not in imgs:
                imgs[src] = Image.open(src).convert("RGB")
            if p.get("printed"):                                  # the publisher's own figure, printed in the column
                bx0, by0, bx1, by1 = p["box"]
                tw, th = round((bx1 - bx0) * p["scale"]), round((by1 - by0) * p["scale"])
                x, y = ev(p["at"][0]), ev(p["at"][1])
                canvas.paste(imgs[src].crop(p["box"]).resize((tw, th), resample_of(p)), (x, y))
                d.rectangle((x - 2, y - 2, x + tw + 1, y + th + 1), outline=PRN, width=2)
                maps.append(lambda X, Y, x=x, y=y, b=(bx0, by0), s=p["scale"]: (x + (X - b[0]) * s, y + (Y - b[1]) * s))
                pbox = (x - 2, y - 2, x + tw + 2, y + th + 2)
            else:
                fmap, pbox = print_on(canvas, d, imgs[src], p["box"], p["scale"], p["at"], resample=resample_of(p))
                maps.append(fmap)
                x0, y0, x1, y1 = pbox
                for j, corner in enumerate(p.get("tape", ("tl", "tr"))):
                    cx, cy, ang = {"tl": (x0 + 8, y0 + 6, -38), "tr": (x1 - 8, y0 + 6, 36),
                                   "bl": (x0 + 8, y1 - 6, 36), "br": (x1 - 8, y1 - 6, -36),
                                   "t": ((x0 + x1) / 2, y0 + 2, 2), "b": ((x0 + x1) / 2, y1 - 2, -2),
                                   "l": (x0 + 2, (y0 + y1) / 2, 88), "r": (x1 - 2, (y0 + y1) / 2, 92)}[corner]
                    tape(canvas, cx, cy, 104, 34, ang, seed * 13 + k * 5 + j)
                    tapes.append((cx, cy, ang))
            pboxes.append(pbox)
            if pbox[0] < GUT < pbox[2] and not p.get("cross"):
                checks.append("print %d (%s) crosses the spine" % (len(pboxes) - 1, p["src"]))
            pg0, pg1 = PAGES[side]
            if (pbox[0] < pg0 + 8 or pbox[2] > pg1 - 8) and not p.get("cross"):
                checks.append("print %d (%s) runs off its page" % (len(pboxes) - 1, p["src"]))
    margin_y, notes = {}, []
    for side in ("left", "right"):
        pg = sp[side]
        stickies = pg.get("stickies", []) + ([pg["sticky"]] if pg.get("sticky") else [])
        for s in stickies:
            need, hh, wide = sticky(canvas, d, s["at"][0], s["at"][1], s["w"], s.get("h"), s["text"], s.get("size", 16))
            if need > hh:
                checks.append("sticky '%s': the writing runs past the note (make h %d or more)" % (s["text"][:28], need))
            if wide > s["w"] - 24:
                checks.append("sticky '%s': a line is wider than the note" % s["text"][:28])
            pg0, pg1 = PAGES[side]
            if s["at"][0] < pg0 + 8 or s["at"][0] + s["w"] > pg1 - 8 or s["at"][1] + hh > BOT:
                checks.append("sticky '%s' runs off its page" % s["text"][:28])
            notes.append(((s["at"][0], s["at"][1], s["at"][0] + s["w"], s["at"][1] + hh), "sticky", True))
        for m in pg.get("marks", []):                            # his pen
            pen = m.get("pen", "blu")
            if "circle" in m:
                c = m["circle"]
                if "word" in c:
                    hit = [b for w_, b in boxes[side] if w_ == c["word"]]
                    if hit:
                        circle(d, hit[min(c.get("nth", 0), len(hit) - 1)], pen, seed=len(c["word"]))
                    else:
                        checks.append("no word '%s' to circle on the %s page" % (c["word"], side))
                else:
                    a = maps[c["print"]](*c["box"][:2]); b = maps[c["print"]](*c["box"][2:])
                    circle(d, (a[0], a[1], b[0], b[1]), pen, seed=int(a[0]))
            elif "underline" in m:
                hit = [b for w_, b in boxes[side] if w_ == m["underline"]]
                if hit:
                    b = hit[min(m.get("nth", 0), len(hit) - 1)]
                    pp.ink_line(d, [(b[0] - 4, b[3]), ((b[0] + b[2]) / 2, b[3] + 3), (b[2] + 4, b[3])], pp.C[pen])
                else:
                    checks.append("no word '%s' to underline on the %s page" % (m["underline"], side))
            elif "text" in m:
                tos = m.get("to", [])
                tos = [tos] if tos and not isinstance(tos[0], list) else tos
                ny = m["at"][1]
                if ny is None:                                    # down the margin: by its point, below the last
                    ty0 = maps[tos[0][0]](*tos[0][1:])[1] if tos else 0
                    ny = max(margin_y.get((side, m["at"][0]), 0), ty0 - 22)
                bx = scrawl(canvas, m["at"][0], ny, m.get("maxw", 220), m["text"], pen, m.get("size", 13), m.get("lead", 28))
                margin_y[(side, m["at"][0])] = bx[3] + 18
                notes.append((bx, m["text"][:28], m.get("over", False)))
                pg0, pg1 = PAGES[side]
                if bx[0] < pg0 + 6 or bx[2] > pg1 - 6 or bx[3] > BOT:
                    checks.append("note '%s' runs off its page" % m["text"][:28])
                froms = m.get("from") or []                       # where his arrows leave the writing (default: the side nearest)
                if isinstance(froms, str) or (froms and isinstance(froms[0], (int, float))):
                    froms = [froms] * len(tos)
                for q, (i, X, Y) in enumerate(tos):                               # red points
                    tx, ty = maps[i](X, Y)
                    for tcx, tcy, tang in tapes:                  # what he points at must not be under tape
                        ca, sa = math.cos(math.radians(tang)), math.sin(math.radians(tang))
                        if abs((tx - tcx) * ca + (ty - tcy) * sa) < 50 and abs((ty - tcy) * ca - (tx - tcx) * sa) < 15:
                            checks.append("arrow from '%s' points at something under tape" % m["text"][:28])
                    left_of = tx < bx[0]
                    right_of = tx > bx[2]
                    if left_of or right_of:
                        sx = bx[0] - 10 if left_of else bx[2] + 10
                        sy = min(max(ty, bx[1] + 10), bx[3] - 10)
                    else:                                         # the point is above or below the writing
                        sx = min(max(tx, bx[0] + 10), bx[2] - 10)
                        sy = bx[1] - 8 if ty < bx[1] else bx[3] + 8
                    ex = tx + (4 if left_of else -4 if right_of else 0)
                    ey = ty + (0 if (left_of or right_of) else (4 if ty < bx[1] else -4))
                    f = froms[q] if q < len(froms) else None
                    if f:                                         # a side of the writing, or a point on the spread
                        if isinstance(f, str):
                            cy_, cx_ = min(max(ty, bx[1] + 10), bx[3] - 10), min(max(tx, bx[0] + 10), bx[2] - 10)
                            sx, sy = {"left": (bx[0] - 10, cy_), "right": (bx[2] + 10, cy_),
                                      "top": (cx_, bx[1] - 8), "bottom": (cx_, bx[3] + 8)}[f]
                        else:
                            sx, sy = f
                        L = math.hypot(tx - sx, ty - sy) or 1.0
                        ex, ey = tx - 4 * (tx - sx) / L, ty - 4 * (ty - sy) / L
                    bend = m.get("bend", 0.12)                     # one for all its arrows, or a list, one each
                    if isinstance(bend, list):
                        bend = bend[q] if q < len(bend) and bend[q] is not None else 0.12
                    pp.arrow(d, (sx, sy), (ex, ey), pp.C["red"], bend=bend)
                    if math.hypot(ex - sx, ey - sy) > 700:
                        checks.append("arrow from '%s' is long (%d px)" % (m["text"][:28], math.hypot(ex - sx, ey - sy)))
    for i, (a, ta, oa) in enumerate(notes):                       # writing on writing, or on a picture
        for j, (b, tb, ob) in enumerate(notes):
            if j > i and overlap(a, b) and not (ta == "sticky" or tb == "sticky"):
                checks.append("notes overlap: '%s' / '%s'" % (ta, tb))
        if not oa:
            for k, pb in enumerate(pboxes):
                if overlap(a, pb):
                    checks.append("note '%s' is written over print %d" % (ta, k))
            hidden = lambda wb: any(overlap(wb, pb) for pb in pboxes)    # text under a taped print does not show
            under = [w_ for s_ in ("left", "right") for w_, wb in boxes[s_] if overlap(a, wb) and not hidden(wb)]
            if under:
                checks.append("note '%s' is written over printed text ('%s')" % (ta, "', '".join(under[:3])))
        elif ta == "sticky" and sp["left" if a[0] < GUT else "right"].get("kind") == "manual":
            # on a manual page the print carries the page, so a sticky must not hide any of it (on a taped page
            # the print is meant to be covered: that is the approved look)
            hidden = lambda wb: any(overlap(wb, pb) for pb in pboxes)
            under = [w_ for s_ in ("left", "right") for w_, wb in boxes[s_] if overlap(a, wb) and not hidden(wb)]
            if under:
                checks.append("sticky at %d, %d covers printed text ('%s')" % (a[0], a[1], "', '".join(under[:3])))
    gutter(canvas)
    canvas.save(out_path)
    return checks


def load_spreads(path):
    """A folder of spreads (one NN_id.json each, plus _book.json with the screens folder) or one json file."""
    if os.path.isdir(path):
        book = json.load(open(os.path.join(path, "_book.json"), encoding="utf-8"))
        sps = []
        for f in sorted(os.listdir(path)):
            if f.endswith(".json") and not f.startswith("_"):
                sps.append(json.load(open(os.path.join(path, f), encoding="utf-8")))
        return pp.home_path(book["screens"]), sps
    spec = json.load(open(path, encoding="utf-8"))
    return pp.home_path(spec["screens"]), spec["spreads"]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("spec", help="the spreads folder (or one json file)")
    ap.add_argument("out")
    ap.add_argument("--only", default="")
    ap.add_argument("--jpg", default="", help="also write the upload copies here: JPEG under Steam's 1 MB")
    a = ap.parse_args()
    screens, sps = load_spreads(a.spec)
    os.makedirs(a.out, exist_ok=True)
    if a.jpg:
        os.makedirs(a.jpg, exist_ok=True)
    only = set(x for x in a.only.split(",") if x)
    for sp in sps:
        if only and sp["id"] not in only:
            continue
        name = "%02d_%s.png" % (sp["n"], sp["id"])
        checks = render(sp, screens, os.path.join(a.out, name))
        print("wrote", name)
        if watch_stamp:
            watch_stamp(os.path.join(a.out, name), sp, checks)
        for c in checks:
            print("  CHECK", sp["id"] + ":", c)
        if a.jpg:
            im = Image.open(os.path.join(a.out, name)).convert("RGB")
            for q in (92, 88, 84, 80):
                jp = os.path.join(a.jpg, name[:-4] + ".jpg")
                im.save(jp, quality=q, optimize=True)
                if os.path.getsize(jp) < 1000000:
                    break


if __name__ == "__main__":
    main()
