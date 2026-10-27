"""Pixel rules for the hands-together mockup: the round hand, its framed ring, and the joined capsule with a framed
track (one item in both hands), at a given scale, drawn the way ZeD_Belt.lua draws its rows."""
import math
from PIL import Image

def hx(h): return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5)) + (255,)
SURF2, BASE, BORDER = hx("#1C1C1C"), hx("#0C0C0C"), hx("#383838")
POS, WARN, DANG = hx("#7A9A34"), hx("#C49A2A"), hx("#C45A2A")

def grad(f): return POS if f > 0.6 else (WARN if f > 0.3 else DANG)

def stadium_rows(s, L, t=None):
    """[(row, x0, w)] for a stadium s tall with a straight middle L long (L = 0: the circle), as ring()/disc() do."""
    rad = s / 2
    inner = max(0, rad - t) if t else 0
    out = []
    for row in range(s):
        dy = abs(row - rad + 0.5)
        hw = math.floor(math.sqrt(max(0, rad * rad - dy * dy)) + 0.5)
        if hw <= 0: continue
        cx = math.floor(rad)
        iw = math.floor(math.sqrt(inner * inner - dy * dy) + 0.5) if (t and dy < inner) else 0
        if iw <= 0:
            out.append((row, cx - hw, hw * 2 + L))
        else:
            out.append((row, cx - hw, hw - iw))
            out.append((row, cx + iw + L, hw - iw))
            if L > 0 and False: pass
    # (a ring's straight runs: top and bottom bands across the middle)
    if t:
        for row in range(s):
            dy = abs(row - rad + 0.5)
            if dy >= inner and dy < rad:
                pass
    return out

def band_rows(s, L, t):
    """the stadium's ring: the outer stadium minus the inner one, as runs"""
    outer = {}
    for row, x, w in stadium_rows(s, L): outer.setdefault(row, []).append((x, x + w))
    inner = {}
    if s - 2 * t > 0:
        for row, x, w in stadium_rows(s - 2 * t, L): inner.setdefault(row + t, []).append((x + t, x + t + w))
    out = []
    for row, spans in outer.items():
        for a, b in spans:
            cuts = sorted(inner.get(row, []))
            cur = a
            for c, d in cuts:
                if c > cur: out.append((row, cur, min(c, b) - cur))
                cur = max(cur, d)
            if cur < b: out.append((row, cur, b - cur))
    return out

def put(im, rows, ox, oy, c, keep=None):
    px = im.load()
    for row, x, w in rows:
        for xx in range(x, x + w):
            if keep and not keep(xx, row): continue
            X, Y = ox + xx, oy + row
            if 0 <= X < im.width and 0 <= Y < im.height: px[X, Y] = c

def track_param(x, y, s, L, t):
    """how far along the track's middle line (clockwise from top centre) the pixel (x, y) is, and the total"""
    r = s / 2 - t / 2
    cy = s / 2
    lx, rx = s / 2, s / 2 + L                # the two caps' centres
    mid = (lx + rx) / 2
    tot = 2 * L + 2 * math.pi * r
    px_, py_ = x + 0.5, y + 0.5
    if lx <= px_ <= rx:
        if py_ < cy:                          # the top straight
            d = px_ - mid
            return (d if d >= 0 else tot + d), tot
        return L / 2 + math.pi * r + (rx - px_), tot
    if px_ > rx:                              # the right cap, clockwise from its top
        a = math.atan2(px_ - rx, cy - py_)   # 0 at the top, pi/2 at the right
        return L / 2 + r * a, tot
    a = math.atan2(lx - px_, py_ - cy)       # the left cap: 0 at its bottom, clockwise up the left
    return L / 2 + math.pi * r + L + r * a, tot

def hand(im, x, y, sc, f=None, L=0):
    """a hand (L = 0) or the joined hands (L = the straight length) with its outline and framed condition track"""
    hair = max(1, math.floor(sc + 0.5)); s = math.floor(52 * sc + 0.5)
    put(im, stadium_rows(s, L), x, y, SURF2)
    put(im, band_rows(s, L, hair * 2), x, y, BORDER)
    if f is None: return s
    ins, t, fw = 3 * hair, 6 * hair, hair
    rx, ry, rs = x + ins, y + ins, s - 2 * ins
    put(im, band_rows(rs, L, t), rx, ry, BASE)
    if f > 0:
        fs, ft = rs - 2 * fw, t - 2 * fw
        _, tot = track_param(0, 0, fs, L, ft)
        f = max(f, math.floor(2 * sc + 0.5) / tot)
        put(im, band_rows(fs, L, ft), rx + fw, ry + fw, grad(f), keep=lambda X, Y: track_param(X, Y, fs, L, ft)[0] <= f * tot)
    put(im, band_rows(rs, L, fw), rx, ry, BORDER)
    i = t - fw
    put(im, band_rows(rs - 2 * i, L, fw), rx + i, ry + i, BORDER)
    return s

if __name__ == "__main__":
    import sys
    im = Image.new("RGBA", (600, 140), hx("#141414"))
    hand(im, 10, 20, 1.75, 0.8)
    s = math.floor(52 * 1.75 + 0.5); g = math.floor(6 * 1.75 + 0.5)
    hand(im, 120, 20, 1.75, 0.62, L=s + g)
    hand(im, 360, 20, 1.75, 0.2, L=s + g)
    im.save(sys.argv[1])
