"""ZeD overhead bubbles, mockup (director, Oct 24 2026): "for text that appears above the character, can that be made
to appear in a speech bubble, like we have been using in the screenshot mockups. And update the verbose progress to
be a thought bubble?"

Drawn here exactly as the game would (design units on whole multiples k, the HUD's pixel faces), over a real 4K
frame (k = 2 there, as the action bar draws today).

  speech    the System 7 balloon of the gallery cards: paper, a 1-unit ink line, stepped round corners, a hard
            shadow, its tail a wedge to the head; the line in the 5 x 7 face, capitals like comic lettering
  thought   the action bar's verbose layout inside a cloud: a scalloped ink line, paper, three bubbles
            stepping down to the head
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "dash", "dashpx"))
from engine import FONTS

HERE = os.path.dirname(os.path.abspath(__file__))
# the glyphs speech needs that the faces lack (added to PixelFonts.lua with the bubbles)
FONTS["57"].update({"!": ["1", "1", "1", "1", "1", "0", "1"], "?": ["01110", "10001", "00001", "00110", "00100", "00000", "00100"],
                    ",": ["00", "00", "00", "00", "00", "01", "10"], '"': ["101", "101", "000", "000", "000", "000", "000"]})
FONTS["35"].update({"!": ["1", "1", "1", "0", "1"], "?": ["111", "001", "010", "000", "010"], ",": ["00", "00", "00", "01", "10"],
                    "&": ["010", "101", "010", "101", "011"], "|": ["1", "1", "1", "1", "1"]})


def hx(h):
    h = h.lstrip("#"); return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


THEMES = {   # paper is the gallery's balloon on every theme; dark follows ZeD.T (Dark, accent orange)
    "paper": dict(fill="#fbfaf6", ink="#141414", shadow=(0, 0, 0, 90), text="#141414", legend="#5a5650", accent="#c8661a",
                  track="#d8d4ca", positive="#2e8a4a"),
    "dark": dict(fill="#232527", ink="#0a0a0a", shadow=(0, 0, 0, 110), text="#e8e6e0", legend="#a8a49c", accent="#e8862a",
                 track="#3c3f42", positive="#4cc26a"),
}


class Canvas:
    """design units drawn as k x k blocks onto an RGBA image at (ox, oy)"""
    def __init__(s, img, ox, oy, k):
        s.img, s.ox, s.oy, s.k = img, ox, oy, k
        s.d = ImageDraw.Draw(img, "RGBA")

    def rect(s, x, y, w, h, c):
        if w <= 0 or h <= 0: return
        c = hx(c) + (255,) if isinstance(c, str) else c
        s.d.rectangle([s.ox + x * s.k, s.oy + y * s.k, s.ox + (x + w) * s.k - 1, s.oy + (y + h) * s.k - 1], fill=c)

    def text(s, t, x, y, c, font="57", align="l"):
        f = FONTS[font]; w = text_w(t, font)
        if align == "c": x -= w // 2
        elif align == "r": x -= w
        for ch in t:
            g = f.get(ch, f.get(ch.upper(), f[" "]))
            for ry, row in enumerate(g):
                for rx, b in enumerate(row):
                    if b == "1": s.rect(x + rx, y + ry, 1, 1, c)
            x += len(g[0]) + 1


def text_w(t, font="57"):
    f = FONTS[font]
    return sum(len(f.get(c, f.get(c.upper(), f[" "]))[0]) + 1 for c in t) - 1 if t else 0


def wrap(t, font, maxw):
    words, lines, cur = t.upper().split(), [], ""
    for w_ in words:
        nxt = (cur + " " + w_).strip()
        if text_w(nxt, font) <= maxw or not cur: cur = nxt
        else: lines.append(cur); cur = w_
    if cur: lines.append(cur)
    return lines


# --------------------------------------------------------------------------- shapes, in design units
def round_box(cv, x, y, w, h, fill, ink, steps=(2, 1)):
    """a box with stepped round corners (rows trimmed by `steps` at each end), a 1-unit ink line round it"""
    def inset(j, hh):
        if j < len(steps): return steps[j]
        if hh - 1 - j < len(steps): return steps[hh - 1 - j]
        return 0
    for j in range(h):
        c = inset(j, h); cv.rect(x + c, y + j, w - 2 * c, 1, ink)
    for j in range(h - 2):
        c = inset(j, h - 2); cv.rect(x + 1 + c, y + 1 + j, w - 2 - 2 * c, 1, fill)


def speech(cv, text, hx_, hy_, th, side=1, maxw=120, gap=3):
    """a speech balloon whose tail tip touches (hx_, hy_), the top of the head; the body sits above, shifted to `side`.
    Returns its box."""
    lines = wrap(text, "57", maxw)
    tw = max(text_w(l, "57") for l in lines)
    pad = 5
    w = tw + pad * 2; h = len(lines) * 9 - 2 + pad * 2
    tail_h = 9
    x = hx_ - (w // 3 if side > 0 else 2 * w // 3)
    y = hy_ - gap - tail_h - h
    tb = x + (w // 3 if side > 0 else 2 * w // 3)      # the tail's base, a third along
    by = y + h - 1
    round_box(cv, x + 2, y + 2, w, h, th["shadow"], th["shadow"])
    tm = tail(cv, tb - 5, tb + 5, by, (hx_, hy_ - 1), th)
    round_box(cv, x, y, w, h, th["fill"], th["ink"])
    tail_draw(cv, *tm, by, th)
    for i, ln in enumerate(lines):
        cv.text(ln, x + w // 2, y + pad + i * 9, th["text"], "57", "c")
    return (x, y, w, h + tail_h)


def thought(cv, st, hx_, hy_, th, gap=3):
    """the action bar's verbose layout in a cloud; three bubbles step down to the head"""
    L1, R1, L2, R2, frac, qn = st["L1"], st.get("R1", ""), st["L2"], st.get("R2", ""), st["frac"], st.get("qn", 1)
    w1 = text_w(L1, "57") + (6 + text_w(R1, "57") if R1 else 0)
    w2 = text_w(L2, "35") + (6 + text_w(R2, "35") if R2 else 0)
    iw = max(60, max(w1, w2))
    pad = 7
    w = iw + pad * 2; h = 24 + 6
    trail = [(0, 1.0), (3, 1.6), (7, 2.4)]
    trail_h = 12
    x = hx_ - w // 2 + 6
    y = hy_ - gap - trail_h - h
    sh = th["shadow"]

    def cloud(ox, oy, fill, ink, shadow=False):
        # a rounded body, then bumps along every edge (radius 3, pitch 8), the ink round the union
        import numpy as np
        m = np.zeros((h + 8, w + 8), bool)
        Y, X = np.mgrid[0:h + 8, 0:w + 8]
        cx0, cy0 = 4, 4
        body = (X >= cx0 + 2) & (X < cx0 + w - 2) & (Y >= cy0 + 2) & (Y < cy0 + h - 2)
        m |= body
        for bx in range(cx0 + 5, cx0 + w - 4, 8):
            for by in (cy0 + 3, cy0 + h - 4):
                m |= (X + 0.5 - bx) ** 2 + (Y + 0.5 - by) ** 2 <= 3.6 ** 2
        for by in range(cy0 + 7, cy0 + h - 6, 8):
            for bx in (cx0 + 3, cx0 + w - 4):
                m |= (X + 0.5 - bx) ** 2 + (Y + 0.5 - by) ** 2 <= 3.6 ** 2
        for (bx, by) in ((cx0 + 4, cy0 + 4), (cx0 + w - 5, cy0 + 4), (cx0 + 4, cy0 + h - 5), (cx0 + w - 5, cy0 + h - 5)):
            m |= (X + 0.5 - bx) ** 2 + (Y + 0.5 - by) ** 2 <= 3.6 ** 2
        edge = m & ~(np.roll(m, 1, 0) & np.roll(m, -1, 0) & np.roll(m, 1, 1) & np.roll(m, -1, 1))
        for (yy, xx) in zip(*np.nonzero(m)):
            cv.rect(ox + xx - cx0, oy + yy - cy0, 1, 1, ink if (edge[yy, xx] or shadow) else fill)

    cloud(x + 2, y + 2, sh, sh, shadow=True)
    # the trail of bubbles toward the head, the smallest nearest it
    tx0, ty0 = x + w // 2 - 6, y + h + 2
    pts = [(tx0 + 1, ty0 + 2, 2.4), (tx0 + 4, ty0 + 7, 1.6), (hx_ - 1, hy_ - gap - 1, 1.0)]
    for (bx, by, r) in pts:
        rr = int(r + 1)
        for j in range(-rr, rr + 1):
            for i in range(-rr, rr + 1):
                dd = (i ** 2 + j ** 2) ** 0.5
                if dd <= r + 0.3: cv.rect(bx + i + 1, by + j + 1, 1, 1, sh)
        for j in range(-rr, rr + 1):
            for i in range(-rr, rr + 1):
                dd = (i ** 2 + j ** 2) ** 0.5
                if dd <= r + 0.3: cv.rect(bx + i, by + j, 1, 1, th["ink"] if dd > r - 0.75 else th["fill"])
    cloud(x, y, th["fill"], th["ink"])
    # the verbose layout, as the action bar draws it today
    px_, py_ = x + pad, y + 5
    c1 = th["positive"] if st.get("phase") == "done" else th["accent"]
    cv.text(L1, px_, py_, c1, "57")
    if R1: cv.text(R1, px_ + iw, py_, th["text"], "57", "r")
    cv.text(L2, px_, py_ + 9, th["legend"], "35")
    if R2: cv.text(R2, px_ + iw, py_ + 9, th["legend"], "35", "r")
    by = py_ + 16
    cv.rect(px_, by, iw, 2, th["track"])
    cv.rect(px_, by, int(round(iw * frac)), 2, c1)
    if qn > 1:
        for i in range(1, qn): cv.rect(px_ + int(round(iw * i / qn)), by, 1, 2, th["fill"])
    return (x, y, w, h + trail_h)


def speech_side(cv, text, hx_, hy_, th, maxw=96, beside=None):
    """speech while a thought bubble is up: the balloon right of the cloud, bottoms nearly level, its tail down-left
    to the side of the head"""
    lines = wrap(text, "57", maxw)
    tw = max(text_w(l, "57") for l in lines)
    pad = 5
    w = tw + pad * 2; h = len(lines) * 9 - 2 + pad * 2
    if beside:
        x = beside[0] + beside[2] + 2; y = beside[1] + beside[3] - 4 - h
    else:
        x = hx_ + 34; y = hy_ - 40 - h
    tip = (hx_ + 8, hy_ + 5)
    by = y + h - 1
    round_box(cv, x + 2, y + 2, w, h, th["shadow"], th["shadow"])
    tm = tail(cv, x + 2, x + 20, by, tip, th)
    round_box(cv, x, y, w, h, th["fill"], th["ink"])
    tail_draw(cv, *tm, by, th)
    for i, ln in enumerate(lines):
        cv.text(ln, x + w // 2, y + pad + i * 9, th["text"], "57", "c")
    return (x, y, w, h)


def wedge_mask(pts):
    """a tail polygon on the unit grid: (filled set, ink set), the ink its outline minus the edge it shares with the body"""
    import numpy as np
    xs = [p[0] for p in pts]; ys = [p[1] for p in pts]
    x0, y0 = int(min(xs)) - 2, int(min(ys)) - 2
    w, h = int(max(xs)) - x0 + 3, int(max(ys)) - y0 + 3
    im = Image.new("L", (w * 4, h * 4), 0)
    ImageDraw.Draw(im).polygon([((x - x0) * 4, (y - y0) * 4) for x, y in pts], fill=255)
    m = np.array(im.resize((w, h), Image.BOX)) > 100
    edge = m & ~(np.roll(m, 1, 0) & np.roll(m, -1, 0) & np.roll(m, 1, 1) & np.roll(m, -1, 1))
    return x0, y0, m, edge


def tail(cv, base_l, base_r, by, tip, th, shadow=True):
    """a speech tail: base along the body's bottom line (by), point at tip; drawn after the body so it opens into it"""
    import numpy as np
    x0, y0, m, edge = wedge_mask([(base_l, by), (base_r + 1, by), (tip[0] + 0.5, tip[1] + 1)])
    if shadow:
        for (yy, xx) in zip(*np.nonzero(m)):
            if y0 + yy > by: cv.rect(x0 + xx + 2, y0 + yy + 2, 1, 1, th["shadow"])
    return x0, y0, m, edge


def tail_draw(cv, x0, y0, m, edge, by, th):
    import numpy as np
    for (yy, xx) in zip(*np.nonzero(m)):
        Y = y0 + yy
        if Y < by: continue
        if Y == by: cv.rect(x0 + xx, Y, 1, 1, th["ink"] if edge[yy, xx] else th["fill"]); continue
        cv.rect(x0 + xx, Y, 1, 1, th["ink"] if edge[yy, xx] else th["fill"])
