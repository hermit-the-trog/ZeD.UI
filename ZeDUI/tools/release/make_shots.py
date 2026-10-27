"""
make_shots.py: the Steam Workshop gallery pictures for ZeD UI (Oct 20 2026).

Reads a shot list (JSON) and writes 1920 x 1080 masters (PNG), Workshop copies
(JPG, each under 1 MB) and a contact sheet. Two kinds of picture:

  ingame   the whole game scene (or a 16:9 box of it) scaled to 1920 x 1080,
           with one to three Balloon Help balloons over it.
  feature  one or more crops of a screenshot laid on the house backdrop: a
           System 7 window (title bar with racing stripes, dark ZeD body with
           faint CRT scanlines, an info bar at the bottom), each crop framed
           like a System 7 window with a hard shadow, and three to six
           balloons pointing at parts of the crops.

The balloons are System 7 Balloon Help: white, a black outline, rounded, a
pointed tail whose tip sits exactly on the anchor (marked with a small pin),
a soft shadow. Text: an optional short head in Chicago, the body in Fira Sans.
A small solver places them: it tries each side of the anchor at a few
distances and slides, never overlaps another balloon, an anchor, a target box
or the edges, and prefers the backdrop to the picture.

Shot list (see ZeDUI/workshop/shots/shots.json):
{
  "screens": "C:/Users/danie/Zomboid/Screenshots",     source folder (relative paths resolve here)
  "out": "out",                                         relative to the JSON's folder
  "patches": [[x0,y0,x1,y1,dx,dy]],                     copy pixels over a corner of every source
                                                        (the debug text), from dx, dy away
  "shots": [
    { "id": "hero", "kind": "ingame", "src": "ws_01_street.png",
      "box": [x0,y0,x1,y1],              optional, ingame: the part of the scene to show
      "avoid": [[x0,y0,x1,y1], ...],     optional, source px: keep balloons off these (ingame: a cost;
                                         feature: never covered, both corners in one crop)
      "title": "...", "caption": "...",  feature: title band text; optional caption strip
      "crops": [ {"box": [x0,y0,x1,y1],   source px
                  "src": "other.png",       optional: a crop from another screenshot
                  "label": "SURVEY",        optional caps label under the crop
                  "tag": "VANILLA",         optional name tab on the crop's top edge
                  "place": [x,y,w],         optional: put it here (output px), no auto layout
                  "frame": false,           optional: no window frame; the source's alpha is kept
                                            (a drawing on a transparent ground)
                  "resample": "nearest",    optional: pixel art zoomed x1.5 / x2 stays crisp
                  "box_todo": true} ],      the box is a guess until the real capture
      "layout": {"fill": 0.52,              share of the width the crops take together
                 "gap": 64,                 px between crops
                 "direction": "column",     stack them instead of a row
                 "zoom": 1.5,               exact scale instead of fill
                 "align": "center",         or left / right (with "inset")
                 "dx": 0, "dy": 0},         nudge; without dy the whole group is centred
                                            in the window body after the balloons are placed
      "balloons": [
        { "head": "Item card", "text": "Hover any item for its full card",
          "anchor": [x,y],               source px; must fall inside a crop for features
          "target": [x0,y0,x1,y1],       optional, source px: the thing; never covered
          "side": "right",               left|right|top|bottom|auto (preferred)
          "at": [x,y],                   optional: force the balloon's top-left (output px)
          "crop": 0,                     optional: which crop the anchor belongs to
          "anchor_todo": true }          the anchor is a guess until the real capture
      ] } ] }

Run (Python with Pillow only):
  py -I ZeDUI/tools/release/make_shots.py ZeDUI/workshop/shots/shots_placeholder.json
  py -I ZeDUI/tools/release/make_shots.py ZeDUI/workshop/shots/shots.json --stub
  options: --only id1,id2   --debug (draw anchors, targets, avoid boxes)
           --stub (draw a stand-in for missing sources instead of skipping them)
"""
import argparse
import io
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1920, 1080
JPG_MAX = 1_000_000            # Steam's gallery limit is 1 MB; stay under a decimal megabyte

FONT_DIRS = [os.path.expanduser("~/AppData/Local/Microsoft/Windows/Fonts"),
             os.path.join(os.environ.get("WINDIR", "C:\\Windows"), "Fonts")]

# ---- palette: ZeD dark theme, default orange accent (Tokens.lua) ----------
BG        = (20, 19, 17)       # window body (surf1, a touch warm)
SCAN      = (16, 15, 13)       # every third row: faint CRT scanline
BAND      = (30, 29, 26)       # title bar / info bar (surf2)
BAND_EDGE = (58, 56, 51)       # borderS
STRIPE    = (64, 61, 56)       # System 7 racing stripes
TITLE_TX  = (238, 233, 222)
SUB_TX    = (168, 163, 152)
ACCENT    = (212, 146, 42)     # #D4922A
MARK      = "ZeD-GUI"          # the mod's display name, top right of every feature picture
FRAME     = (86, 82, 74)       # hairline round each picture, so dark crops keep an edge
INK       = (10, 10, 10)
PAPER     = (255, 255, 255)

# ---- type --------------------------------------------------------------------
def font(name, size):
    for d in FONT_DIRS:
        p = os.path.join(d, name)
        if os.path.isfile(p):
            return ImageFont.truetype(p, size)
    raise SystemExit("font not found: %s (looked in %s)" % (name, FONT_DIRS))

F_TITLE   = font("ChicagoFLF.ttf", 46)
F_HEAD    = font("ChicagoFLF.ttf", 27)
F_BODY    = font("FiraSans-Regular.ttf", 28)
F_CAPTION = font("FiraSans-Regular.ttf", 28)
F_LABEL   = font("FiraMono-Bold.ttf", 22)
F_MARK    = font("FiraMono-Bold.ttf", 22)

# ---- layout ------------------------------------------------------------------
M        = 56                  # outer margin
BAND_H   = 92                  # title bar
CAP_H    = 70                  # info bar (caption strip)
BAL_W    = 470                 # balloon text column, max
BAL_PADX = 22
BAL_PADY = 16
BAL_R    = 16                  # corner radius
OUTLINE  = 2                   # at 1080p: reads as 1 px at Steam's half-size display
LINE_GAP = 6
TAIL_W   = 30                  # tail base
PIN_R    = 9
SS       = 3                   # supersampling for balloon shapes


# ==============================================================================
# text
# ==============================================================================
def wrap(text, f, maxw):
    lines, cur = [], ""
    for word in text.split():
        t = word if not cur else cur + " " + word
        if f.getlength(t) <= maxw or not cur:
            cur = t
        else:
            lines.append(cur)
            cur = word
    if cur:
        lines.append(cur)
    return lines


def wrap_even(text, f, maxw, minw=0):
    """Wrap to the fewest lines that fit maxw, then narrow the column as far as the
    line count allows, so lines come out even (no lone last word)."""
    lines = wrap(text, f, maxw)
    if len(lines) < 2:
        return lines
    lo, hi = int(max(maxw * 0.45, min(minw, maxw))), int(maxw)
    if len(wrap(text, f, lo)) <= len(lines):
        return wrap(text, f, lo)
    while hi - lo > 4:
        m = (lo + hi) // 2
        if len(wrap(text, f, m)) <= len(lines):
            hi = m
        else:
            lo = m
    return wrap(text, f, hi)


def line_h(f):
    a, d = f.getmetrics()
    return a + d


def balloon_layout(b, maxw=BAL_W):
    """Lines and the balloon's outer size (w, h) for its head and body at a text width."""
    head = b.get("head")
    text = b.get("text", "")
    hl = wrap(head, F_HEAD, maxw) if head else []
    headw = max((F_HEAD.getlength(l) for l in hl), default=0)
    bl = wrap_even(text, F_BODY, maxw, headw) if text else []   # never narrower than the head
    widths = [F_HEAD.getlength(l) for l in hl] + [F_BODY.getlength(l) for l in bl]
    tw = max(widths) if widths else 40
    th = len(hl) * (line_h(F_HEAD) + 2) + len(bl) * (line_h(F_BODY) + LINE_GAP) - (LINE_GAP if bl else 0)
    if hl and bl:
        th += 6
    return hl, bl, (int(tw + 2 * BAL_PADX + 0.5), int(th + 2 * BAL_PADY + 0.5))


# ==============================================================================
# geometry
# ==============================================================================
def rect_overlap(a, b):
    x0, y0 = max(a[0], b[0]), max(a[1], b[1])
    x1, y1 = min(a[2], b[2]), min(a[3], b[3])
    return max(0, x1 - x0) * max(0, y1 - y0)


def grow(r, p):
    return (r[0] - p, r[1] - p, r[2] + p, r[3] + p)


def seg_hits_rect(p, q, r, steps=24):
    for i in range(steps + 1):
        t = i / steps
        x, y = p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t
        if r[0] < x < r[2] and r[1] < y < r[3]:
            return True
    return False


def seg_len_in_rect(p, q, r, steps=40):
    """About how much of the segment p-q lies inside rect r (px)."""
    n = sum(1 for i in range(steps + 1)
            if r[0] < p[0] + (q[0] - p[0]) * i / steps < r[2] and r[1] < p[1] + (q[1] - p[1]) * i / steps < r[3])
    return n / (steps + 1) * ((q[0] - p[0]) ** 2 + (q[1] - p[1]) ** 2) ** 0.5


def segs_cross(p1, p2, p3, p4):
    def ccw(a, b, c):
        return (c[1] - a[1]) * (b[0] - a[0]) > (b[1] - a[1]) * (c[0] - a[0])
    return ccw(p1, p3, p4) != ccw(p2, p3, p4) and ccw(p1, p2, p3) != ccw(p1, p2, p4)


def tail_base(rect, anchor):
    """The edge of the balloon facing the anchor and the tail's base points on it.
    Longer tails get a wider base so they stay a wedge, not a needle."""
    x0, y0, x1, y1 = rect
    ax, ay = anchor
    cx_, cy_ = min(max(ax, x0), x1), min(max(ay, y0), y1)
    length = ((ax - cx_) ** 2 + (ay - cy_) ** 2) ** 0.5
    TAIL_W = min(46, max(26, 0.15 * length))
    # which side faces the anchor (the anchor is outside the rect)
    dx = ax - x1 if ax > x1 else (x0 - ax if ax < x0 else 0)
    dy = ay - y1 if ay > y1 else (y0 - ay if ay < y0 else 0)
    lo = BAL_R + TAIL_W / 2 + 4
    lo = min(lo, (x1 - x0) / 2, (y1 - y0) / 2)
    if dx >= dy:     # left or right edge
        ex = x1 if ax > x1 else x0
        cy = min(max(ay, y0 + lo), y1 - lo)
        # lean the base away from the anchor's side a little, like System 7's wedge
        return (ex, cy - TAIL_W / 2), (ex, cy + TAIL_W / 2)
    ey = y1 if ay > y1 else y0
    cx = min(max(ax, x0 + lo), x1 - lo)
    return (cx - TAIL_W / 2, ey), (cx + TAIL_W / 2, ey)


# ==============================================================================
# placement solver
# ==============================================================================
SIDES = ("right", "left", "bottom", "top")
GAPS = (60, 84, 112, 150, 200, 260, 330, 410)
WIDTHS = (BAL_W, 400, 340)        # text columns the solver may try, widest first
SLIDES = (0.0, -0.3, 0.3, -0.6, 0.6, -0.9, 0.9)


def candidates(anchor, size, side):
    ax, ay = anchor
    w, h = size
    for gap in GAPS:
        for s in SLIDES:
            if side == "right":
                x0, y0 = ax + gap, ay - h / 2 + s * h / 2
            elif side == "left":
                x0, y0 = ax - gap - w, ay - h / 2 + s * h / 2
            elif side == "bottom":
                x0, y0 = ax - w / 2 + s * w / 2, ay + gap
            else:
                x0, y0 = ax - w / 2 + s * w / 2, ay - gap - h
            yield gap, s, (round(x0), round(y0), round(x0 + w), round(y0 + h))


def _mid(r, anchor):
    b1, b2 = tail_base(r, anchor)
    return ((b1[0] + b2[0]) / 2, (b1[1] + b2[1]) / 2)


def _best_spot(b, others, safe, protect, soft, soft_w):
    """The cheapest legal (score, rect, tail_mid, layout) for balloon b, or None."""
    pref = b.get("side", "auto")
    order = list(SIDES) if pref in (None, "auto") else [pref] + [s for s in SIDES if s != pref]
    layouts = []
    for mw in ([b["maxw"]] if b.get("maxw") else WIDTHS):
        lay = balloon_layout(b, mw)
        if not layouts or lay[2] != layouts[-1][2]:
            layouts.append(lay)
    best = None
    for li, lay in enumerate(layouts):
        w, h = lay[2]
        for si, side in enumerate(order):
            for gap, sl, r in candidates(b["anchor"], (w, h), side):
                if r[0] < safe[0] or r[1] < safe[1] or r[2] > safe[2] or r[3] > safe[3]:
                    continue
                if any(rect_overlap(grow(r, 18), o["rect"]) for o in others):
                    continue
                if any(rect_overlap(r, p) for p in protect):
                    continue
                score = si * 260 + (gap - GAPS[0]) * 1.2 + abs(sl) * 120 + li * 140
                for sr in soft:
                    score += 1600 * soft_w * rect_overlap(r, sr) / (w * h)
                mid = _mid(r, b["anchor"])
                ax, ay = b["anchor"]
                for sr in soft:        # nor a long way across the picture
                    score += 2.5 * soft_w * seg_len_in_rect(mid, b["anchor"], sr)
                for p in protect:      # tails should not run across the things explained
                    if p[0] < ax < p[2] and p[1] < ay < p[3] and (p[2] - p[0]) <= 60:
                        continue       # its own pin
                    score += 9 * seg_len_in_rect(mid, b["anchor"], p)
                for o in others:
                    if seg_hits_rect(mid, b["anchor"], grow(o["rect"], 6)):
                        score += 6000
                    if segs_cross(mid, b["anchor"], o["tail_mid"], o["anchor"]):
                        score += 3000
                    if seg_hits_rect(o["tail_mid"], o["anchor"], grow(r, 6)):
                        score += 6000
                if best is None or score < best[0]:
                    best = (score, r, mid, lay)
    if best is None:      # nothing legal: preferred side, closest gap, kept on the canvas
        print("  ! no clean spot for balloon %r; placed anyway" % (b.get("head") or b.get("text", ""))[:40])
        lay = layouts[-1]
        r = next(candidates(b["anchor"], lay[2], order[0]))[2]
        dx = max(0, safe[0] - r[0]) - max(0, r[2] - safe[2])
        dy = max(0, safe[1] - r[1]) - max(0, r[3] - safe[3])
        r = (r[0] + dx, r[1] + dy, r[2] + dx, r[3] + dy)
        best = (10 ** 9, r, _mid(r, b["anchor"]), lay)
    return best


def solve(balloons, safe, protect, soft, soft_w=1.0, passes=3):
    """Place every balloon. balloons: dicts with 'anchor' (out px), 'side', optional
    'at' (fixed top-left). safe: the rect they stay inside. protect: rects never
    covered (anchors, targets). soft: rects that cost something to cover (the
    pictures). Greedy in list order, then a few passes re-placing each balloon
    against all the others. Sets rect, tail_mid, hl, bl, size on each."""
    fixed = [b for b in balloons if b.get("at")]
    for b in fixed:
        b["hl"], b["bl"], b["size"] = balloon_layout(b, b.get("maxw", BAL_W))
        x, y = b["at"]
        b["rect"] = (x, y, x + b["size"][0], y + b["size"][1])
        b["tail_mid"] = _mid(b["rect"], b["anchor"])
    free = [b for b in balloons if not b.get("at")]
    placed = list(fixed)
    for b in free:
        sc, r, mid, lay = _best_spot(b, placed, safe, protect, soft, soft_w)
        b["rect"], b["tail_mid"], b["_score"] = r, mid, sc
        b["hl"], b["bl"], b["size"] = lay
        placed.append(b)
    for _ in range(passes):
        moved = False
        for b in free:
            others = [o for o in placed if o is not b]
            sc, r, mid, lay = _best_spot(b, others, safe, protect, soft, soft_w)
            if sc < b["_score"] - 1:
                b["rect"], b["tail_mid"], b["_score"] = r, mid, sc
                b["hl"], b["bl"], b["size"] = lay
                moved = True
        if not moved:
            break
    align_columns(free, placed, safe, protect)


def _side_of(b):
    r, (ax, ay) = b["rect"], b["anchor"]
    if r[2] <= ax:
        return "left"
    if r[0] >= ax:
        return "right"
    return "top" if r[3] <= ay else "bottom"


def align_columns(free, placed, safe, protect):
    """Tidy: balloons on the same side line up on their outer edge (a manual's
    margin column), when that stays legal."""
    for side in SIDES:
        group = [b for b in free if _side_of(b) == side]
        if len(group) < 2:
            continue
        old = {id(b): b["rect"] for b in group}
        for b in group:
            r = b["rect"]
            if side == "left":
                dx, dy = min(o["rect"][2] for o in group) - r[2], 0
            elif side == "right":
                dx, dy = max(o["rect"][0] for o in group) - r[0], 0
            elif side == "top":
                dx, dy = 0, min(o["rect"][3] for o in group) - r[3]
            else:
                dx, dy = 0, max(o["rect"][1] for o in group) - r[1]
            b["rect"] = (r[0] + dx, r[1] + dy, r[2] + dx, r[3] + dy)
        ok = True
        for b in group:
            r = b["rect"]
            if r[0] < safe[0] or r[1] < safe[1] or r[2] > safe[2] or r[3] > safe[3]:
                ok = False
            if any(rect_overlap(r, p) for p in protect):
                ok = False
            if any(o is not b and rect_overlap(grow(r, 12), o["rect"]) for o in placed):
                ok = False
        for b in group:
            if not ok:
                b["rect"] = old[id(b)]
            b["tail_mid"] = _mid(b["rect"], b["anchor"])


# ==============================================================================
# drawing
# ==============================================================================
def draw_balloon(canvas, b):
    """Composite one balloon (shape, outline, shadow, text) onto canvas (RGBA)."""
    r = b["rect"]
    ax, ay = b["anchor"]
    pad = 30
    lx0 = int(min(r[0], ax) - pad)
    ly0 = int(min(r[1], ay) - pad)
    lx1 = int(max(r[2], ax) + pad)
    ly1 = int(max(r[3], ay) + pad)
    lw, lh = lx1 - lx0, ly1 - ly0

    def L(p):   # to local supersampled coords
        return ((p[0] - lx0) * SS, (p[1] - ly0) * SS)

    b1, b2 = tail_base(r, (ax, ay))
    # pull the base 1 px into the body so the union is seamless
    rr = (L((r[0], r[1])), L((r[2], r[3])))
    mask = Image.new("L", (lw * SS, lh * SS), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle([rr[0], rr[1]], radius=BAL_R * SS, fill=255)
    md.polygon([L(b1), L(b2), L((ax, ay))], fill=255)
    # the outline: grow the shape, keep the ring (the tip grows past the anchor by
    # the outline width; the pin covers it)
    k = OUTLINE * SS * 2 + 1
    outer = mask.filter(ImageFilter.MaxFilter(k))

    small = lambda im: im.resize((lw, lh), Image.LANCZOS)
    outer_s, mask_s = small(outer), small(mask)

    layer = Image.new("RGBA", (lw, lh), (0, 0, 0, 0))
    # soft shadow
    sh = Image.new("L", (lw, lh), 0)
    sh.paste(outer_s, (5, 7))
    sh = sh.filter(ImageFilter.GaussianBlur(7)).point(lambda v: v * 0.55)
    layer.paste(Image.new("RGBA", (lw, lh), (0, 0, 0, 255)), (0, 0), sh)
    layer.paste(Image.new("RGBA", (lw, lh), INK + (255,)), (0, 0), outer_s)
    layer.paste(Image.new("RGBA", (lw, lh), PAPER + (255,)), (0, 0), mask_s)

    d = ImageDraw.Draw(layer)
    x = r[0] - lx0 + BAL_PADX
    y = r[1] - ly0 + BAL_PADY
    for l in b["hl"]:
        d.text((x, y), l, font=F_HEAD, fill=INK)
        y += line_h(F_HEAD) + 2
    if b["hl"] and b["bl"]:
        y += 6
    for l in b["bl"]:
        d.text((x, y), l, font=F_BODY, fill=(24, 24, 24))
        y += line_h(F_BODY) + LINE_GAP
    canvas.alpha_composite(layer, (lx0, ly0))


def draw_pin(canvas, p):
    x, y = p
    big = Image.new("RGBA", ((PIN_R * 2 + 8) * SS,) * 2, (0, 0, 0, 0))
    d = ImageDraw.Draw(big)
    c = (PIN_R + 4) * SS
    R = PIN_R * SS
    d.ellipse([c - R - OUTLINE * SS, c - R - OUTLINE * SS, c + R + OUTLINE * SS, c + R + OUTLINE * SS], fill=INK + (255,))
    d.ellipse([c - R, c - R, c + R, c + R], fill=PAPER + (255,))
    r2 = int(R * 0.52)
    d.ellipse([c - r2, c - r2, c + r2, c + r2], fill=ACCENT + (255,))
    sm = big.resize((PIN_R * 2 + 8,) * 2, Image.LANCZOS)
    canvas.alpha_composite(sm, (int(round(x - PIN_R - 4)), int(round(y - PIN_R - 4))))


def backdrop():
    im = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(im)
    for y in range(0, H, 3):
        d.line([(0, y), (W, y)], fill=SCAN)
    return im


def stripes(d, x0, x1, yc):
    """System 7 title bar racing stripes between x0 and x1 around yc."""
    if x1 - x0 < 8:
        return
    for i in range(6):
        y = yc - 15 + i * 6
        d.rectangle([x0, y, x1, y + 1], fill=STRIPE)


def title_band(im, title, number):
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, W, BAND_H], fill=BAND)
    d.rectangle([0, BAND_H, W, BAND_H + 1], fill=BAND_EDGE)
    yc = BAND_H // 2
    tw = F_TITLE.getlength(title)
    tx0 = (W - tw) / 2
    # close box (left) and the ZeD mark (right), as a System 7 window
    bx = M
    d.rectangle([bx, yc - 13, bx + 26, yc + 13], fill=BAND)
    d.rectangle([bx, yc - 13, bx + 26, yc + 13], outline=STRIPE, width=2)
    mark = MARK
    mw = F_MARK.getlength(mark)
    mx = W - M - mw
    stripes(d, bx + 26 + 18, tx0 - 30, yc)
    stripes(d, tx0 + tw + 30, mx - 22, yc)
    a, de = F_TITLE.getmetrics()
    d.text((tx0, yc - (a + de) / 2 + 3), title, font=F_TITLE, fill=TITLE_TX)
    a2, d2 = F_MARK.getmetrics()
    d.text((mx, yc - (a2 + d2) / 2 + 1), mark, font=F_MARK, fill=ACCENT)


def caption_band(im, caption):
    d = ImageDraw.Draw(im)
    y0 = H - CAP_H
    d.rectangle([0, y0, W, H], fill=BAND)
    d.rectangle([0, y0, W, y0 + 1], fill=BAND_EDGE)
    tw = F_CAPTION.getlength(caption)
    a, de = F_CAPTION.getmetrics()
    d.text(((W - tw) / 2, y0 + (CAP_H - (a + de)) / 2 + 1), caption, font=F_CAPTION, fill=SUB_TX)


def scaled(src, box, w, h, resample="auto"):
    """Crop box from src and resize to (w, h): Lanczos down + mild unsharp; up: nearest
    for near-integer zooms (keeps pixel art crisp), else Lanczos. resample='nearest'
    forces nearest (pixel art at 4K is 2 px per art pixel, so x1.5 is crisp too)."""
    c = src.crop(box)
    k = w / c.width
    if resample == "nearest":
        return c.resize((w, h), Image.NEAREST)
    if abs(k - 1) < 0.002:
        return c
    if k < 0.999:
        out = c.resize((w, h), Image.LANCZOS, reducing_gap=3.0)
        return out.filter(ImageFilter.UnsharpMask(radius=1.0, percent=55, threshold=2))
    if abs(k - round(k)) < 0.04:
        return c.resize((w, h), Image.NEAREST)
    return c.resize((w, h), Image.LANCZOS)


TAG_H = 38


def draw_tag(d, text, x, y_bottom):
    """A name tab sitting on a crop's top edge, left-aligned: white, black outline,
    Fira Mono Bold caps (VANILLA, ZeD-GUI, DARK | ORANGE)."""
    tw = F_LABEL.getlength(text)
    a, de = F_LABEL.getmetrics()
    x1 = x + tw + 28
    d.rectangle([x, y_bottom - TAG_H, x1, y_bottom], fill=INK)
    d.rectangle([x + 2, y_bottom - TAG_H + 2, x1 - 2, y_bottom], fill=PAPER)
    d.text((x + 14, y_bottom - TAG_H + (TAG_H - (a + de)) / 2 + 1), text, font=F_LABEL, fill=INK)


def framed(im, tile, x, y):
    """Paste a crop as a System 7 window: 2 px black frame and a hard black shadow."""
    d = ImageDraw.Draw(im)
    w, h = tile.size
    shadow = Image.new("RGBA", (w + 4, h + 4), (0, 0, 0, 150))
    im.paste(shadow, (x + 8 - 2, y + 8 - 2), shadow)
    d.rectangle([x - 3, y - 3, x + w + 2, y + h + 2], fill=INK)
    d.rectangle([x - 2, y - 2, x + w + 1, y + h + 1], fill=FRAME)
    im.paste(tile, (x, y))


# ==============================================================================
# shots
# ==============================================================================
def load_src(path, stub):
    if os.path.isfile(path):
        return Image.open(path).convert("RGB")
    if not stub:
        return None
    im = Image.new("RGB", (3840, 2160), (34, 36, 40))
    d = ImageDraw.Draw(im)
    for i in range(-2160, 3840, 80):
        d.line([(i, 0), (i + 2160, 2160)], fill=(44, 47, 52), width=24)
    f = font("FiraMono-Bold.ttf", 90)
    d.text((140, 1000), "MISSING " + os.path.basename(path), font=f, fill=(200, 200, 200))
    return im


def patch(im, patches):
    """Cover small things the capture should not show (the debug corner's text) by
    copying the pixels from dx, dy away: each patch is [x0, y0, x1, y1, dx, dy]."""
    for x0, y0, x1, y1, dx, dy in patches:
        x0, y0 = max(0, x0), max(0, y0)
        x1, y1 = min(im.width, x1), min(im.height, y1)
        if x1 > x0 and y1 > y0:
            im.paste(im.crop((x0 + dx, y0 + dy, x1 + dx, y1 + dy)), (x0, y0))
    return im


def render(shot, screens, n, stub, debug, patches=()):
    cache = {}

    def get(name):
        path = name if os.path.isabs(name) else os.path.join(screens, name)
        if path not in cache:
            cache[path] = load_src(path, stub)
            if cache[path] is None:
                print("  skip %s: no %s" % (shot["id"], path))
            elif patches:
                patch(cache[path], patches)
        return cache[path]

    src = get(shot["src"])
    if src is None:
        return None
    for c in shot.get("crops", []):
        if c.get("src") and get(c["src"]) is None:
            return None
    kind = shot.get("kind", "feature")
    balloons = [dict(b) for b in shot.get("balloons", [])]
    protect, soft = [], []
    places = []                # feature: (crop, x, y, w, h) in output px

    if kind == "ingame":
        box = shot.get("box") or (0, 0, src.width, src.height)
        k = W / (box[2] - box[0])
        canvas = scaled(src, tuple(box), W, H).convert("RGBA")
        to_out = lambda p, hint=None: ((p[0] - box[0]) * k, (p[1] - box[1]) * k)
        safe = (28, 28, W - 28, H - 28)
        if shot.get("caption"):   # an info bar over the bottom of the scene, nearly opaque
            bar = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            caption_band(bar, shot["caption"])
            bar.putalpha(bar.getchannel("A").point(lambda v: int(v * 0.9)))
            canvas.alpha_composite(bar)
            safe = (28, 28, W - 28, H - CAP_H - 20)
        for r in shot.get("avoid", []):
            soft.append((*to_out(r[:2]), *to_out(r[2:])))
    else:
        has_cap = bool(shot.get("caption"))
        top = BAND_H + 2 + M
        bot = H - (CAP_H if has_cap else 0) - M
        crops = shot.get("crops") or [{"box": [0, 0, src.width, src.height]}]
        lay = shot.get("layout", {})
        fill = lay.get("fill", 0.52)
        gapx = lay.get("gap", 64)
        label_h = 40 if any(c.get("label") for c in crops) else 0
        tag_h = TAG_H + 6 if any(c.get("tag") for c in crops) else 0
        top += tag_h
        avail_h = bot - top - label_h
        # auto size: all crops share one height; together they take fill * the content width
        ratios = [(c["box"][2] - c["box"][0]) / (c["box"][3] - c["box"][1]) for c in crops]
        cw = (W - 2 * M) * fill - gapx * (len(crops) - 1)
        hh = min(avail_h, cw / sum(ratios))
        hh = lay.get("height", hh)
        if lay.get("zoom"):
            hh = (crops[0]["box"][3] - crops[0]["box"][1]) * lay["zoom"]
        widths = [round(hh * r) for r in ratios]
        total = sum(widths) + gapx * (len(crops) - 1)
        align = lay.get("align", "center")
        if align == "left":
            x = M + lay.get("inset", 40)
        elif align == "right":
            x = W - M - lay.get("inset", 40) - total
        else:
            x = (W - total) / 2 + lay.get("dx", 0)
        y = top + (avail_h - hh) / 2 + lay.get("dy", 0)
        if lay.get("direction") == "column":
            # stacked: all crops share one width, together they fit the body's height
            gapy = lay.get("gap", 40)
            inv = [1 / r for r in ratios]
            ww = min((W - 2 * M) * fill, (avail_h + label_h - (gapy + label_h) * (len(crops) - 1) - label_h)
                     / sum(inv))
            if lay.get("zoom"):
                ww = (crops[0]["box"][2] - crops[0]["box"][0]) * lay["zoom"]
            hs = [round(ww * v) for v in inv]
            total_h = sum(hs) + (gapy + label_h) * (len(crops) - 1) + label_h
            x = (W - ww) / 2 + lay.get("dx", 0)
            y = top + (bot - top - total_h) / 2 + lay.get("dy", 0)
            widths = []
            for c, h_ in zip(crops, hs):
                places.append([c, round(x), round(y), round(ww), h_])
                soft.append((x - 2, y - 2 - (tag_h if c.get("tag") else 0), x + ww + 10,
                             y + h_ + 10 + (label_h if c.get("label") else 0)))
                y += h_ + gapy + label_h + tag_h
            crops = []
        for c, cw_ in zip(crops, widths):
            if c.get("place"):
                px, py, pw = c["place"]
                ph = round(pw * (c["box"][3] - c["box"][1]) / (c["box"][2] - c["box"][0]))
            else:
                px, py, pw, ph = round(x), round(y), cw_, round(hh)
                x += cw_ + gapx
            places.append([c, px, py, pw, ph])
            soft.append((px - 2, py - 2 - (tag_h if c.get("tag") else 0), px + pw + 10,
                         py + ph + 10 + (label_h if c.get("label") else 0)))

        def to_out(p, hint=None):
            if hint is None:
                hit = [pl for pl in places if pl[0]["box"][0] <= p[0] <= pl[0]["box"][2]
                       and pl[0]["box"][1] <= p[1] <= pl[0]["box"][3]]
                if not hit:
                    raise SystemExit("%s: anchor %s is in no crop" % (shot["id"], p))
                pl = hit[0]
            else:
                pl = places[hint]
            c, px, py, pw, ph = pl
            kk = pw / (c["box"][2] - c["box"][0])
            return (px + (p[0] - c["box"][0]) * kk, py + (p[1] - c["box"][1]) * kk)
        safe = (24, BAND_H + 22, W - 24, H - (CAP_H if has_cap else 0) - 20)
        # feature: "avoid" boxes (source px, both corners in one crop) are never covered (Oct 27 2026,
        # director: "Be careful with feature bubbles covering/hiding things")
        for r in shot.get("avoid", []):
            hit = [i for i, pl in enumerate(places) if pl[0]["box"][0] <= r[0] <= pl[0]["box"][2]
                   and pl[0]["box"][1] <= r[1] <= pl[0]["box"][3]]
            if not hit:
                raise SystemExit("%s: avoid box %s is in no crop" % (shot["id"], r))
            protect.append((*to_out(r[:2], hit[0]), *to_out(r[2:], hit[0])))

    for b in balloons:
        hint = b.get("crop")
        b["anchor"] = to_out(b["anchor"], hint)
        ax, ay = b["anchor"]
        protect.append((ax - 26, ay - 26, ax + 26, ay + 26))
        if b.get("target"):
            t = b["target"]
            protect.append((*to_out(t[:2], hint), *to_out(t[2:], hint)))
    solve(balloons, safe, protect, soft, 1.0 if kind != "ingame" else 3.0)
    # report every balloon that lands on a picture (feature) or on an avoid box (ingame), and on a
    # protected box, so a card can be checked without looking (the look is still the last word)
    for b in balloons:
        what = (b.get("head") or b.get("text", ""))[:32]
        for j, sr in enumerate(soft):
            ov = rect_overlap(b["rect"], sr)
            if ov > 0:
                print("  NOTE %s: balloon '%s' lies on %s %d (%d px)" % (shot["id"], what,
                      "picture" if kind != "ingame" else "avoid box", j + 1, ov))
        for pr in protect:
            if rect_overlap(b["rect"], pr) > 0:
                print("  WARN %s: balloon '%s' covers a target, an anchor or an avoid box" % (shot["id"], what))
                break

    if kind != "ingame":
        # centre the whole group (pictures, labels, balloons) in the window body,
        # unless the shot places things itself
        lay = shot.get("layout", {})
        if "dy" not in lay and not any(c.get("place") for c in shot.get("crops", []))                 and not any(b.get("at") for b in balloons) and lay.get("center", True):
            rects = [sr for sr in soft] + [b["rect"] for b in balloons]
            gy0 = min(r[1] for r in rects)
            gy1 = max(r[3] for r in rects)
            dy = round((safe[1] + safe[3]) / 2 - (gy0 + gy1) / 2)
            dy = max(safe[1] - gy0, min(safe[3] - gy1, dy))
            if dy:
                sh = lambda r: (r[0], r[1] + dy, r[2], r[3] + dy)
                for pl in places:
                    pl[2] += dy
                soft[:] = [sh(r) for r in soft]
                protect[:] = [sh(r) for r in protect]
                for b in balloons:
                    b["anchor"] = (b["anchor"][0], b["anchor"][1] + dy)
                    b["rect"] = sh(b["rect"])
                    b["tail_mid"] = (b["tail_mid"][0], b["tail_mid"][1] + dy)
        canvas = backdrop()
        title_band(canvas, shot.get("title", shot["id"]), n)
        if shot.get("caption"):
            caption_band(canvas, shot["caption"])
        d = ImageDraw.Draw(canvas)
        for c, px, py, pw, ph in places:
            if c.get("frame") is False:
                # a drawing on a transparent ground (the controller map's pad): no window frame,
                # pasted with its own alpha onto the card's body
                spath = c.get("src") or shot["src"]
                if not os.path.isabs(spath):
                    spath = os.path.join(screens, spath)
                rs = Image.NEAREST if c.get("resample") == "nearest" else Image.LANCZOS   # pixel art stays crisp
                t = Image.open(spath).convert("RGBA").crop(tuple(c["box"])).resize((pw, ph), rs)
                canvas.paste(t, (px, py), t)
            else:
                tile = scaled(get(c["src"]) if c.get("src") else src, tuple(c["box"]), pw, ph,
                              c.get("resample", "auto"))
                framed(canvas, tile, px, py)
            if c.get("tag"):
                draw_tag(d, c["tag"], px - 3, py - 3)
            if c.get("label"):
                lw_ = F_LABEL.getlength(c["label"])
                d.text((px + (pw - lw_) / 2, py + ph + 14), c["label"], font=F_LABEL, fill=SUB_TX)
        canvas = canvas.convert("RGBA")

    if debug:
        d = ImageDraw.Draw(canvas)
        for r in soft:
            d.rectangle(r, outline=(0, 160, 255, 255), width=2)
        for r in protect:
            d.rectangle(r, outline=(255, 0, 80, 255), width=2)
    for b in balloons:
        draw_balloon(canvas, b)
    for b in balloons:
        draw_pin(canvas, b["anchor"])
        if debug and b.get("anchor_todo"):
            ImageDraw.Draw(canvas).text((b["anchor"][0] + 14, b["anchor"][1] - 30), "TODO",
                                        font=F_LABEL, fill=(255, 60, 60, 255))
    return canvas.convert("RGB")


def save_jpg(img, path):
    for sub in (0, 2):
        for q in range(95, 59, -3):
            buf = io.BytesIO()
            img.save(buf, "JPEG", quality=q, subsampling=sub, optimize=True, progressive=True)
            if buf.tell() < JPG_MAX:
                with open(path, "wb") as fh:
                    fh.write(buf.getvalue())
                return q, sub, buf.tell()
    raise SystemExit("could not get %s under 1 MB" % path)


def contact(paths, out):
    cols, tw, th, lab = 4, 480, 270, 30
    rows = (len(paths) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * tw + (cols + 1) * 16, rows * (th + lab) + (rows + 1) * 16), BG)
    d = ImageDraw.Draw(sheet)
    f = font("FiraMono-Bold.ttf", 15)
    for i, p in enumerate(paths):
        im = Image.open(p).convert("RGB").resize((tw, th), Image.LANCZOS)
        x = 16 + (i % cols) * (tw + 16)
        y = 16 + (i // cols) * (th + lab + 16)
        sheet.paste(im, (x, y))
        d.text((x, y + th + 6), os.path.splitext(os.path.basename(p))[0], font=f, fill=SUB_TX)
    sheet.save(out, optimize=True)


def main():
    ap = argparse.ArgumentParser(description="Build the Workshop gallery pictures from a shot list.")
    ap.add_argument("spec")
    ap.add_argument("--only", default="")
    ap.add_argument("--out", default=None, help="output folder (default: the spec's 'out', next to it)")
    ap.add_argument("--stub", action="store_true", help="draw stand-ins for missing screenshots")
    ap.add_argument("--debug", action="store_true", help="draw anchors, targets and avoid boxes")
    a = ap.parse_args()

    with open(a.spec, encoding="utf-8") as fh:
        spec = json.load(fh)
    base = os.path.dirname(os.path.abspath(a.spec))
    screens = spec.get("screens", "C:/Users/danie/Zomboid/Screenshots")
    out = a.out or os.path.join(base, spec.get("out", "out"))
    os.makedirs(out, exist_ok=True)
    only = set(s for s in a.only.split(",") if s)

    made = []
    for i, shot in enumerate(spec["shots"], 1):
        n = shot.get("n", i)
        if only and shot["id"] not in only:
            continue
        name = "%02d_%s" % (n, shot["id"])
        img = render(shot, screens, n, a.stub, a.debug, shot.get("patches", spec.get("patches", ())))
        if img is None:
            continue
        png = os.path.join(out, name + ".png")
        img.save(png, optimize=True)
        q, sub, size = save_jpg(img, os.path.join(out, name + ".jpg"))
        todo = sum(1 for b in shot.get("balloons", []) if b.get("anchor_todo"))             + sum(1 for c in shot.get("crops", []) if c.get("box_todo"))
        print("%-28s png %5d KB | jpg q%d %s %4d KB%s" % (name, os.path.getsize(png) // 1024, q,
              "4:4:4" if sub == 0 else "4:2:0", size // 1024, ("  (%d boxes / anchors still estimates)" % todo) if todo else ""))
        made.append(png)

    allpng = sorted(os.path.join(out, f) for f in os.listdir(out)
                    if f.endswith(".png") and f[:2].isdigit())
    if allpng:
        contact(allpng, os.path.join(out, "contact.png"))
        print("contact sheet: %s (%d pictures)" % (os.path.join(out, "contact.png"), len(allpng)))


if __name__ == "__main__":
    main()
