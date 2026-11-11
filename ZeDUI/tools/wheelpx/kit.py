"""wheelpx: the radial wheels' icons (and later the context strip's), one-colour pixel ink with pictogram figures.
Director, Oct 27 2026: "Ink + pictogram figures", every icon drawn twice (16 at rest, 24 pointed), the figures on a
template ("follow a template or doll"; approved: "just rough enough to still be clear").

The kit: a canvas that takes vector shapes (rendered 8x, cut at half cover, so edges land on pixels) and hand-placed
pixels; badges (+ - x check, arrows) cut clear into a corner; 45-degree bands; the registry.

Style rules (the whole set keeps them):
  - one colour, white on clear; the game tints it (ink on the paper cell, accent when pointed)
  - 16: objects in the 14 x 14 live area (1..14), 1 px details, cut-outs at least 1 px; figures use all 16 rows
  - 24: objects in the 22 x 22 live area (1..22), 2 px lines, cut-outs 1-2 px; figures use all 24 rows
  - masses solid, details cut out of them; outlines only where a mass would hide the meaning (a glass, a frame)
  - badges sit bottom right (5 x 5 at 16, 8 x 8 at 24) with one clear pixel round them; on a figure (its feet fill
    the bottom) the badge sits top right
  - turning a thing off strikes it through (slash()); stopping something a figure does takes the x badge; in and out
    are arrows (up/down, left/right), add and remove are plus and minus
  - a figure follows the doll's template (i_fig, doll.py): head, gap, trunk, legs on fixed rows at each size
"""
import contextlib
import math

from PIL import Image, ImageDraw

SS = 8


class _Tee:
    """an ImageDraw that draws on the icon and on its mark layer at once (inside C.mark())"""
    def __init__(s, a, b): s._a, s._b = a, b

    def __getattr__(s, name):
        fa, fb = getattr(s._a, name), getattr(s._b, name)

        def both(*args, **kw):
            fb(*args, **kw)
            return fa(*args, **kw)
        return both


class C:
    def __init__(s, size):
        s.n = size
        s.im = Image.new("L", (size * SS, size * SS), 0)
        s.d = ImageDraw.Draw(s.im)
        # the mark layer: the pixels that tell an icon from its twin (a plus or minus, an in or out arrow, the strike
        # of an "off"). Whatever is drawn inside mark() lands here too; the menus color those pixels (marks.py).
        s.mk = Image.new("L", s.im.size, 0)
        s._marking = 0

    @contextlib.contextmanager
    def mark(s):
        """draw the block's shapes on the mark layer as well as on the icon"""
        if s._marking:
            yield s; return
        main = s.d
        s.d = _Tee(main, ImageDraw.Draw(s.mk)); s._marking = 1
        try:
            yield s
        finally:
            s.d = main; s._marking = 0

    # ---- vector (grid units; v=255 ink, v=0 clear)
    def _p(s, pts): return [(x * SS, y * SS) for x, y in pts]

    def rect(s, x, y, w, h, v=255):
        if w <= 0 or h <= 0: return s
        s.d.rectangle([x * SS, y * SS, (x + w) * SS - 1, (y + h) * SS - 1], fill=v); return s

    def rrect(s, x, y, w, h, r, v=255):
        s.d.rounded_rectangle([x * SS, y * SS, (x + w) * SS - 1, (y + h) * SS - 1], radius=r * SS, fill=v); return s

    def circle(s, cx, cy, r, v=255):
        s.d.ellipse([(cx - r) * SS, (cy - r) * SS, (cx + r) * SS - 1, (cy + r) * SS - 1], fill=v); return s

    def ellipse(s, cx, cy, rx, ry, v=255):
        s.d.ellipse([(cx - rx) * SS, (cy - ry) * SS, (cx + rx) * SS - 1, (cy + ry) * SS - 1], fill=v); return s

    def poly(s, pts, v=255): s.d.polygon(s._p(pts), fill=v); return s

    def line(s, pts, w, v=255, caps=True):
        P = s._p(pts)
        s.d.line(P, fill=v, width=max(1, int(round(w * SS))), joint="curve")
        if caps:
            r = w * SS / 2
            for x, y in P: s.d.ellipse([x - r, y - r, x + r, y + r], fill=v)
        return s

    def arc(s, cx, cy, r, a0, a1, w, v=255, n=48, caps=True):
        pts = [(cx + r * math.cos(math.radians(a)), cy + r * math.sin(math.radians(a))) for a in
               [a0 + (a1 - a0) * i / n for i in range(n + 1)]]
        return s.line(pts, w, v, caps)

    def ring(s, cx, cy, r, w, v=255):
        """an annulus: outer radius r, w thick"""
        inner = Image.new("L", s.im.size, 0); di = ImageDraw.Draw(inner)
        di.ellipse([(cx - r) * SS, (cy - r) * SS, (cx + r) * SS - 1, (cy + r) * SS - 1], fill=255)
        di.ellipse([(cx - r + w) * SS, (cy - r + w) * SS, (cx + r - w) * SS - 1, (cy + r - w) * SS - 1], fill=0)
        s.im.paste(v, mask=inner); return s

    # ---- pixel-true
    def px(s, *cells, v=255):
        for x, y in cells: s.rect(x, y, 1, 1, v)
        return s

    def grid(s, rows, ox=0, oy=0, v=255, ch="#"):
        for y, row in enumerate(rows):
            for x, c in enumerate(row):
                if c in ch: s.rect(ox + x, oy + y, 1, 1, v)
        return s

    def dot(s, cx, cy, r, v=255):
        """a pixel-true disc: a pixel is in when its centre lies inside r (corners trimmed, no spurs)"""
        for y in range(int(math.floor(cy - r)) - 1, int(math.ceil(cy + r)) + 1):
            for x in range(int(math.floor(cx - r)) - 1, int(math.ceil(cx + r)) + 1):
                if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r * r + 0.01: s.rect(x, y, 1, 1, v)
        return s

    def cap(s, x0, y0, x1, y1, r, v=255):
        """a pixel-true capsule: every pixel whose centre lies within r of the segment"""
        dx, dy = x1 - x0, y1 - y0; L2 = dx * dx + dy * dy or 1e-9
        for y in range(int(math.floor(min(y0, y1) - r)) - 1, int(math.ceil(max(y0, y1) + r)) + 1):
            for x in range(int(math.floor(min(x0, x1) - r)) - 1, int(math.ceil(max(x0, x1) + r)) + 1):
                px_, py_ = x + 0.5, y + 0.5
                t = max(0.0, min(1.0, ((px_ - x0) * dx + (py_ - y0) * dy) / L2))
                if math.hypot(px_ - x0 - t * dx, py_ - y0 - t * dy) <= r + 0.01: s.rect(x, y, 1, 1, v)
        return s

    def band(s, cx, cy, ux, uy, a, b, r, v=0):
        """pixels whose centre lies a..b along the unit direction (ux, uy) from (cx, cy), within r across it: a cut
        across a strip (a plaster's pad edge, a finger's crease)"""
        for y in range(int(cy - r - b) - 2, int(cy + r + b) + 3):
            for x in range(int(cx - r - b) - 2, int(cx + r + b) + 3):
                px_, py_ = x + 0.5 - cx, y + 0.5 - cy
                t = px_ * ux + py_ * uy; q = -px_ * uy + py_ * ux
                if a - 0.01 <= t <= b + 0.01 and abs(q) <= r + 0.01: s.rect(x, y, 1, 1, v)
        return s

    def oring(s, cx, cy, r, w=1, v=255):
        """a pixel-true ring: centres between r - w and r"""
        for y in range(int(math.floor(cy - r)) - 1, int(math.ceil(cy + r)) + 1):
            for x in range(int(math.floor(cx - r)) - 1, int(math.ceil(cx + r)) + 1):
                dd = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
                if r - w - 0.01 <= dd <= r + 0.01: s.rect(x, y, 1, 1, v)
        return s

    def diag(s, x0, y0, n, w=1, up=True, v=255):
        """a 45-degree band, n steps from pixel (x0, y0): each step one pixel right and one up (or down), w wide"""
        for i in range(n):
            for j in range(w): s.rect(x0 + i + j, y0 - i if up else y0 + i, 1, 1, v)
        return s

    # ---- marks
    def badge(s, kind, corner="br", clear=True, at=None, mark=True):
        """a small mark in a corner, cut clear of what is under it: plus, minus, x, check, up, down, left, right, slash.
        5 x 5 at 16 (1 px bars); 8 x 8 at 24 (2 px bars), an even width so a 2 px bar sits dead centre (the director,
        Nov 9 2026, of the 24 plus: "it's not centered"; it was 7 wide, two rows above the bar and three below).
        mark: the badge goes on the mark layer too (the clearing doesn't)."""
        n = s.n; b = 5 if n == 16 else 8
        x0, y0 = at if at else ((n - b) if "r" in corner else 0, (n - b) if "b" in corner else 0)
        if clear: s.rect(x0 - 1, y0 - 1, b + 2, b + 2, v=0)
        with (s.mark() if mark else contextlib.nullcontext()):
            s._badge(kind, x0, y0, b)
        return s

    def _badge(s, kind, x0, y0, b):
        n = s.n; t = 1 if n == 16 else 2
        if n == 16:
            m = b // 2
            if kind == "plus": s.rect(x0, y0 + m, b, 1); s.rect(x0 + m, y0, 1, b)
            elif kind == "minus": s.rect(x0, y0 + m, b, 1)
            elif kind == "x":
                for i in range(b): s.rect(x0 + i, y0 + i, 1, 1); s.rect(x0 + b - 1 - i, y0 + i, 1, 1)
            elif kind == "check":
                s.px((x0, y0 + 2), (x0 + 1, y0 + 3), (x0 + 2, y0 + 4), (x0 + 3, y0 + 3), (x0 + 4, y0 + 2), (x0 + 4, y0 + 1), (x0 + 4, y0))
            elif kind == "up":
                for i in range(m + 1): s.rect(x0 + m - i, y0 + i, 2 * i + 1, 1)
                s.rect(x0 + m, y0 + m, 1, b - m)
            elif kind == "down":
                for i in range(m + 1): s.rect(x0 + m - i, y0 + b - 1 - i, 2 * i + 1, 1)
                s.rect(x0 + m, y0, 1, b - m)
            elif kind == "right":
                for i in range(m + 1): s.rect(x0 + b - 1 - i, y0 + m - i, 1, 2 * i + 1)
                s.rect(x0, y0 + m, b - m, 1)
            elif kind == "left":
                for i in range(m + 1): s.rect(x0 + i, y0 + m - i, 1, 2 * i + 1)
                s.rect(x0 + m, y0 + m, b - m, 1)
            elif kind == "slash":
                for i in range(b): s.rect(x0 + b - 1 - i, y0 + i, 1, 1)
            return
        # 24: 8 wide, 2 px bars at the middle two columns (3 and 4)
        c = (b - t) // 2; h = b // 2
        if kind == "plus": s.rect(x0, y0 + c, b, t); s.rect(x0 + c, y0, t, b)
        elif kind == "minus": s.rect(x0, y0 + c, b, t)
        elif kind == "x":
            for i in range(b):
                s.rect(x0 + i, y0 + i, 1, 1); s.rect(x0 + b - 1 - i, y0 + i, 1, 1)
                if i < b - 1: s.rect(x0 + i + 1, y0 + i, 1, 1); s.rect(x0 + b - 2 - i, y0 + i, 1, 1)
        elif kind == "check":
            k = b / 7.0
            s.line([(x0 + 0.8 * k, y0 + 3.8 * k), (x0 + 2.8 * k, y0 + 5.8 * k), (x0 + 6.2 * k, y0 + 1.2 * k)], 1.6)
        elif kind == "up":       # a head of 2, 4, 6, 8 then the 2 px shaft
            for i in range(h): s.rect(x0 + c - i, y0 + i, t + 2 * i, 1)
            s.rect(x0 + c, y0 + h, t, b - h)
        elif kind == "down":
            for i in range(h): s.rect(x0 + c - i, y0 + b - 1 - i, t + 2 * i, 1)
            s.rect(x0 + c, y0, t, b - h)
        elif kind == "right":
            for i in range(h): s.rect(x0 + b - 1 - i, y0 + c - i, 1, t + 2 * i)
            s.rect(x0, y0 + c, b - h, t)
        elif kind == "left":
            for i in range(h): s.rect(x0 + i, y0 + c - i, 1, t + 2 * i)
            s.rect(x0 + h, y0 + c, b - h, t)
        elif kind == "slash":
            for i in range(b): s.rect(x0 + b - 1 - i, y0 + i, t, 1)

    def turn_arrow(s, cx, cy, r, w, a0, a1, head=None):
        """an arc from a0 to a1 (degrees, screen: 0 right, 90 down) with an arrowhead at a1 pointing along the turn"""
        s.arc(cx, cy, r - w / 2, a0, a1, w, caps=False)
        h = head or (w * 2.2)
        t = math.radians(a1); sg = 1 if a1 > a0 else -1
        px_, py_ = cx + (r - w / 2) * math.cos(t), cy + (r - w / 2) * math.sin(t)
        tx, ty = -math.sin(t) * sg, math.cos(t) * sg                       # the tangent, along the turn
        nx, ny = math.cos(t), math.sin(t)                                   # outward
        s.poly([(px_ + nx * h * 0.75, py_ + ny * h * 0.75), (px_ - nx * h * 0.75, py_ - ny * h * 0.75),
                (px_ + tx * h, py_ + ty * h)])
        return s

    def slash(s, w=None):
        """a strike across the whole icon (off), cut clear either side so the strike reads on a mass"""
        n = s.n; w = w or (1 if n == 16 else 2)
        a, b = (1, n - 1)
        s.line([(a + 0.5, b - 0.5), (b - 0.5, a + 0.5)], w + 2, v=0)
        with s.mark():
            s.line([(a + 0.5, b - 0.5), (b - 0.5, a + 0.5)], w)
        return s

    def transpose(s, how):
        """turn or mirror the icon and its mark layer together"""
        s.im = s.im.transpose(how); s.mk = s.mk.transpose(how); s.d = ImageDraw.Draw(s.im); return s

    def flip_v(s): return s.transpose(Image.FLIP_TOP_BOTTOM)

    def flip_h(s): return s.transpose(Image.FLIP_LEFT_RIGHT)

    def _cut(s, im): return im.resize((s.n, s.n), Image.BOX).point(lambda q: 255 if q >= 128 else 0)

    def get(s):
        out = Image.new("RGBA", (s.n, s.n), (255, 255, 255, 0))
        out.putalpha(s._cut(s.im))
        return out

    def get_mark(s):
        """the icon's pixels that are on the mark layer (white on clear), or None when it has none"""
        from PIL import ImageChops
        a = ImageChops.multiply(s._cut(s.im), s._cut(s.mk))
        if not a.getbbox(): return None
        out = Image.new("RGBA", (s.n, s.n), (255, 255, 255, 0))
        out.putalpha(a)
        return out


# ------------------------------------------------------------------ the registry
ICONS = {}       # id -> dict(fn, cat, means, slices)


def icon(id_, cat, means, slices=()):
    """register an icon: fn(c, s) draws it on canvas c at size s (16 or 24)"""
    def deco(fn):
        ICONS[id_] = dict(fn=fn, cat=cat, means=means, slices=list(slices), id=id_)
        return fn
    return deco


def canvas(id_, s):
    c = C(s); ICONS[id_]["fn"](c, s); return c


def render(id_, s):
    return canvas(id_, s).get()


def render_mark(id_, s):
    return canvas(id_, s).get_mark()


def from_grid(rows):
    """a drawing that is all hand-placed pixels"""
    def f(c, s): c.grid(rows)
    return f
