"""The dashboards at night (director, Oct 21 2026): no gauge is backlit; small bulbs behind the fascia wash the faces.

"The backlight is behind the dash plate, in front of the gauges, so the gauges get the light wash, and the bulbs
would be on one side, just out of frame so you don't see the bulb." And: "There might be a light shining down from
the top of the dash onto the controls below, same warm natural light, incandescent."

So a dash at night is lit by what designs.NIGHT puts in it, nothing else:
  wash    every gauge opening (a dial, a square window, the ribbon's window, the clock) has one small incandescent
          bulb hidden behind the edge of the plate on one side of it, between the plate and the face: no bulb is
          drawn. Its light crosses the face from that side, brightest at the near edge and dying unevenly toward the
          far one, so the figures and the needle near the lit edge read and the far side stays dim. The plate round
          the opening (wood, vinyl, steel) stays dark but for a faint spill on the rim. Displays that make their own
          light (the VFD clusters) get no bulb.
  lamps   a lamp under the dash's brow aimed down at the controls (the radio, the climate, the switches): a row of
          points under a hood, so it lights a band that dies away downward
The relight runs on the same height field, normals and materials as the day plate (engine.render), lands every pixel
on its own material's ramp (warmed to a 2700 K bulb: amber-cream, never white or blue; two darker steps under each
ramp for the night), and steps the falloff with an ordered 4 x 4 dither on the art grid. What the day plate shows
faintly in the dark is the night's ambient.

Out, per design: the night plate (bulbs on), the dark plate (bulbs off, ambient only), and for the game a light map
(the light a flat live part would get, 4 x 4 plate pixels a cell, 16 levels) plus the backlit LCD glass to redraw
while the car has power. Lamps, LEDs, VFD and LED figures and the radio's readout are live parts and keep their
colours; everything else the game draws follows the map.
"""
import math
import numpy as np
from PIL import Image
from engine import RAMPS, OUTLINE, hx

TINT = (1.0, 0.80, 0.56)        # what a 2700 K bulb does to a colour: warm, amber-cream (the default bulb, and the
                                # game's fallback for a dash with no tint map)
TINT_GREEN = (0.42, 1.00, 0.74)  # a blue-green filtered bulb, the early-90s GM gauge light (director, Oct 29 2026: a
                                # starting value, approved on the night sheet)
TINTS = {"amber": TINT, "green": TINT_GREEN}
DEFAULT_TINT = "amber"          # a light source names its tint in designs.NIGHT; none named is amber
TINT_EPS = 0.01                 # light below this leans back to the default tint (no edge where a pool of light ends)
TINT_STEPS = 8                  # a light-map cell's mix of tints, in eighths
AMB = 0.07                      # the night ambient, a share of the day's shade (the cabin by starlight and street glow)
BULB_GAIN = 2.5                 # a bulb's power 1 in light units
LAMP_GAIN = 1.2                 # a lamp's power 1, per point of its row
WASH_GAIN = 1.5                 # a gauge bulb's power 1 at the near edge of its face
SPILL = 0.22                    # the share of a gauge bulb's light that reaches the rim of its opening
K_LIT = 0.62                    # the shade a flat surface gets from one unit of bulb light (the day's flat shade is 0.52)
CELL = 4                        # the light map's cell, in plate pixels
LEVELS = 15                     # the light map's top level (hex digits 0..f)
BAYER4 = (np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]], np.float32) + 0.5) / 16.0
DAY_FLAT = 0.52
DITHER_FROM = 0.03              # the light below which the dark stays clean (no dither)
DARK_STEPS = (0.3, 0.6)         # the night's two steps under a ramp's darkest
BACKLIT = ("lcd",)              # glass a car lights from behind while it has power (the 90s odometer and climate LCDs)


def warm(c, f=1.0, tint=TINT):
    return tuple(int(max(0, min(255, round(v * t * f)))) for v, t in zip(c, tint))


def _lamp_tint(lamp):
    """a lamp row (x0, x1, y, z, power[, reach][, tint]): its tint, the default unless it names one"""
    return next((v for v in lamp[5:] if isinstance(v, str)), DEFAULT_TINT)


def spec_tints(spec):
    """the tints a designs.NIGHT entry's lights carry, the default first: ['amber'] for a one-colour dash"""
    names = [DEFAULT_TINT]
    w = spec.get("wash")
    if w and w.get("tint", DEFAULT_TINT) not in names: names.append(w["tint"])
    for t in [_lamp_tint(lamp) for lamp in spec.get("lamps", ())] +              [next((v for v in bulb[4:] if isinstance(v, str)), DEFAULT_TINT) for bulb in spec.get("bulbs", ())]:
        if t not in names: names.append(t)
    for t in names:
        if t not in TINTS: raise SystemExit(f"night: unknown tint {t!r} (night.TINTS)")
    return names


def hexc(c): return "#%02x%02x%02x" % tuple(int(v) for v in c[:3])


# ---------------------------------------------------------------------------------------------------- the light
def _normals(d, terms):
    n = terms["n"].copy()
    n[d.flatlight] = (0, 0, 1)
    return n


def _shadow(hh, solid, px, py, pz, bx, by, bz, reach, sel):
    """soft height-field shadow toward a point light: 1 = lit, 0 = blocked (only where `sel`)"""
    H, W = hh.shape
    ys, xs = np.nonzero(sel)
    if not len(ys): return np.ones(hh.shape, np.float32)
    x0 = xs + 0.5; y0 = ys + 0.5; z0 = hh[ys, xs]
    dx = bx - x0; dy = by - y0; dist = np.hypot(dx, dy)
    ux = dx / np.maximum(dist, 1e-3); uy = dy / np.maximum(dist, 1e-3)
    rise = (bz - z0) / np.maximum(dist, 1e-3)
    occ = np.zeros(len(ys), np.float32)
    kmax = int(min(reach, np.ceil(dist.max())))
    for k in range(1, kmax + 1):
        act = dist > k
        if not act.any(): break
        sx = np.clip(np.floor(x0 + ux * k).astype(int), 0, W - 1)
        sy = np.clip(np.floor(y0 + uy * k).astype(int), 0, H - 1)
        hs = hh[sy, sx]
        zr = z0 + rise * k
        o = np.clip((hs - zr - 0.35) / 1.6, 0, 1) * act
        occ = np.maximum(occ, o)
    out = np.ones(hh.shape, np.float32)
    out[ys, xs] = 1 - occ
    return out


def _lights(spec):
    """designs.NIGHT entry -> point lights: (x, y, z, power, radius, spot dir or None, spot power, tint name).
    A bulb (x, y, z, power[, reach][, tint]) or a lamp row (x0, x1, y, z, power[, reach][, tint]) may name its tint"""
    pts = []
    for (x, y, z, pw, *rest) in spec.get("bulbs", ()):
        nums = [v for v in rest if not isinstance(v, str)]
        r = nums[0] if nums else 26.0
        tn = next((v for v in rest if isinstance(v, str)), DEFAULT_TINT)
        pts.append((float(x), float(y), float(z), float(pw) * BULB_GAIN, float(r), None, 0.0, tn))
    for lamp in spec.get("lamps", ()):
        x0, x1, y, z, pw = lamp[:5]
        nums = [v for v in lamp[5:] if not isinstance(v, str)]
        r = nums[0] if nums else 100.0
        tn = _lamp_tint(lamp)
        n = max(2, int(round((x1 - x0) / 8.0)) + 1)          # a long tube: points close enough to leave no scallops
        for i in range(n):
            x = x0 + (x1 - x0) * i / (n - 1)
            # the hood aims it down at the controls, into the dash
            pts.append((float(x), float(y), float(z), float(pw) * LAMP_GAIN * 8.0 / 22.0, float(r), (0.0, 1.0, -0.5), 2.0, tn))
    return pts


def _grow(seed, allowed, it_max=400):
    """the 4-way connected part of `allowed` holding `seed` (a plain flood by dilation, inside the allowed box)"""
    ys, xs = np.nonzero(allowed)
    if not len(ys) or not allowed[seed]: return np.zeros_like(allowed)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    al = allowed[y0:y1, x0:x1]
    reach = np.zeros_like(al); reach[seed[0] - y0, seed[1] - x0] = True
    for _ in range(it_max):
        g = reach.copy()
        g[1:, :] |= reach[:-1, :]; g[:-1, :] |= reach[1:, :]; g[:, 1:] |= reach[:, :-1]; g[:, :-1] |= reach[:, 1:]
        g &= al
        if (g == reach).all(): break
        reach = g
    out = np.zeros_like(allowed); out[y0:y1, x0:x1] = reach
    return out


def _fill_holes(m):
    """True where m is, plus what it encloses (the hub cap in a dial's face)"""
    ys, xs = np.nonzero(m)
    if not len(ys): return m
    y0, y1, x0, x1 = max(0, ys.min() - 1), ys.max() + 2, max(0, xs.min() - 1), xs.max() + 2
    sub = m[y0:y1, x0:x1]
    bg = ~sub
    reach = np.zeros_like(sub)
    reach[0, :] = bg[0, :]; reach[-1, :] = bg[-1, :]; reach[:, 0] |= bg[:, 0]; reach[:, -1] |= bg[:, -1]
    for _ in range(2000):
        g = reach.copy()
        g[1:, :] |= reach[:-1, :]; g[:-1, :] |= reach[1:, :]; g[:, 1:] |= reach[:, :-1]; g[:, :-1] |= reach[:, 1:]
        g &= bg
        if (g == reach).all(): break
        reach = g
    out = m.copy(); out[y0:y1, x0:x1] = sub | (bg & ~reach)
    return out


def gauge_faces(d, parts):
    """the gauge openings, from the live parts: a needle's (or the clock's) pivot, a ribbon's window. Each face is the
    flat recess its needle sweeps (flooded at the face's height, bounded by its bezel or window wall; a dial printed
    on an open panel is cut to its circle). -> [(mask, face height)]"""
    hh = d.lit_terms["hh"]
    H, W = hh.shape
    X = d.XX + 0.5; Y = d.YY + 0.5
    out, seen = [], []

    def seed_near(x, y, win=4):
        x, y = int(round(x)), int(round(y))
        ya, yb, xa, xb = max(0, y - win), min(H, y + win + 1), max(0, x - win), min(W, x + win + 1)
        sub = np.where(d.solid[ya:yb, xa:xb], hh[ya:yb, xa:xb], 1e9)
        k = np.unravel_index(int(np.argmin(sub)), sub.shape)
        return (ya + k[0], xa + k[1])

    for p in parts:
        if p["t"] in ("needle", "clock"):
            cx, cy = float(p["cx"]), float(p["cy"])
            if any(abs(cx - a) < 1.5 and abs(cy - b) < 1.5 for a, b in seen): continue
            seen.append((cx, cy))
            r1 = max([float(q["r1"]) for q in parts if q["t"] == "needle" and abs(q["cx"] - cx) < 1.5 and abs(q["cy"] - cy) < 1.5]
                     + [float(p.get("rm", 0))])
            sd = seed_near(cx, cy - 0.6 * r1)
            h0 = float(hh[sd])
            rr = np.hypot(X - cx, Y - cy)
            cap = max(r1 + 12.0, 60.0)
            reg = _grow(sd, d.solid & (np.abs(hh - h0) <= 0.8) & (rr <= cap))
            band = (rr > cap - 2.0) & (rr <= cap)
            if band.any() and (reg & band).sum() > 0.2 * band.sum():        # printed on an open panel: its circle
                reg &= rr <= r1 + 4.0
            out.append((_fill_holes(reg), h0))
        elif p["t"] == "ribbon":
            x0, x1, y = float(p["x0"]), float(p["x1"]), float(p["y"])
            sd = seed_near((x0 + x1) / 2.0, y)
            h0 = float(hh[sd])
            boxm = (X >= x0 - 24) & (X <= x1 + 40) & (Y >= y - 24) & (Y <= y + 40)
            out.append((_fill_holes(_grow(sd, d.solid & (np.abs(hh - h0) <= 0.8) & boxm)), h0))
    return [(m, h0) for (m, h0) in out if m.sum() >= 40]


def wash_lights(d, parts, spec, seed=0):
    """the hidden bulbs per gauge face: (face mask, rim mask, bx, by, bz, power, reach) each. One bulb on the wash's
    side; wash bulbs=n puts n behind the edge, spread over `spread` degrees round that side, each at `each` of the
    one bulb's power (director, Oct 29 2026: a couple more bulbs on the late models' green clusters, brighter and
    more even, the way the period clusters spread theirs behind the face)"""
    w = spec.get("wash")
    if not w: return []
    rng = np.random.default_rng(seed + 101)
    out = []
    for i, (m, h0) in enumerate(gauge_faces(d, parts)):
        side = float(w.get("side", 200)) + float(rng.uniform(-1, 1)) * float(w.get("jitter", 14))
        pw = float(w.get("power", 1.0)) * float(rng.uniform(0.82, 1.1)) * WASH_GAIN
        ux, uy = math.cos(math.radians(side)), math.sin(math.radians(side))
        ys, xs = np.nonzero(m)
        cx, cy = xs.mean() + 0.5, ys.mean() + 0.5
        proj = (xs + 0.5 - cx) * ux + (ys + 0.5 - cy) * uy
        near, far = float(proj.max()), float(-proj.min())
        bx, by = cx + ux * (near + 2.0), cy + uy * (near + 2.0)        # just behind the edge of the plate
        reach = 0.42 * (near + far)
        grow = m.copy()
        for _ in range(3):
            g = grow.copy(); g[1:, :] |= grow[:-1, :]; g[:-1, :] |= grow[1:, :]; g[:, 1:] |= grow[:, :-1]; g[:, :-1] |= grow[:, 1:]
            grow = g
        rim = grow & ~m & d.solid
        n = int(w.get("bulbs", 1))
        if n <= 1:
            out.append((m, rim, bx, by, h0 + 3.0, pw, reach))
            continue
        spread, each = float(w.get("spread", 80.0)), float(w.get("each", 0.5))
        for j in range(n):
            a = math.radians(side + spread * (j / (n - 1.0) - 0.5))
            vx, vy = math.cos(a), math.sin(a)
            nj = float(((xs + 0.5 - cx) * vx + (ys + 0.5 - cy) * vy).max())
            fj = float(-((xs + 0.5 - cx) * vx + (ys + 0.5 - cy) * vy).min())
            out.append((m, rim, cx + vx * (nj + 2.0), cy + vy * (nj + 2.0), h0 + 3.0, pw * each, 0.42 * (nj + fj)))
    return out


def light_field(d, spec, seed=0, parts=(), by_tint=None):
    """per pixel: E (diffuse light on the real surface), S (the bulbs' glints), Ef (the light on a flat part at the
    surface, shadows included: the light map). With by_tint (a dict), each tint's own share of the light goes in it
    as {tint name: (E, S, Ef)}: the wash's light and the lamps' kept apart, so a pixel can take the colour of the mix
    (the totals are summed as before, light by light, so a one-colour dash comes out exactly as it did)"""
    terms = d.lit_terms
    hh = terms["hh"]
    n = _normals(d, terms)
    H, W = hh.shape
    X = d.XX + 0.5; Y = d.YY + 0.5
    E = np.zeros((H, W), np.float32); S = np.zeros((H, W), np.float32); Ef = np.zeros((H, W), np.float32)
    parts_t = {}

    def add_t(tn, e, s_, ef):
        if by_tint is None: return
        if tn not in parts_t: parts_t[tn] = [np.zeros((H, W), np.float32) for _ in range(3)]
        q = parts_t[tn]; q[0] += e; q[1] += s_; q[2] += ef
    for (bx, by, bz, pw, R, spot, sp, tn) in _lights(spec):
        vx = bx - X; vy = by - Y; vz = bz - hh
        dist = np.sqrt(vx * vx + vy * vy + vz * vz) + 1e-3
        lx, ly, lz = vx / dist, vy / dist, vz / dist
        att = pw / (1.0 + (dist / R) ** 2) ** 2.0           # a point source close to the surface: it dies fast
        att = att * np.clip(1.0 - (dist - 1.5 * R) / R, 0, 1)  # and is gone a little past twice its reach
        if spot is not None:
            sd = np.array(spot, np.float32); sd /= np.linalg.norm(sd)
            cosang = np.clip(-(lx * sd[0] + ly * sd[1] + lz * sd[2]), 0, 1)
            att = att * cosang ** sp
            att = att * (Y >= by - 2)                       # the hood: nothing above the lamp
        sel = d.solid & (att > 0.004)
        vis = _shadow(hh, d.solid, X, Y, hh, bx, by, bz, 70, sel)
        ndl = np.clip(n[..., 0] * lx + n[..., 1] * ly + n[..., 2] * lz, 0, 1)
        hx_, hy_, hz_ = lx, ly, lz + 1.0
        hn = np.sqrt(hx_ * hx_ + hy_ * hy_ + hz_ * hz_)
        ndh = np.clip((n[..., 0] * hx_ + n[..., 1] * hy_ + n[..., 2] * hz_) / hn, 0, 1)
        e_ = (ndl * att * vis).astype(np.float32)
        s_ = ((ndh ** 30) * att * vis).astype(np.float32)
        ef_ = (np.clip(lz, 0, 1) * att * vis).astype(np.float32)
        E += e_; S += s_; Ef += ef_
        add_t(tn, e_, s_, ef_)
    # the gauges: each face washed from its hidden bulb's side, the rim of its opening catching a little
    wtn = (spec.get("wash") or {}).get("tint", DEFAULT_TINT)
    for (m, rim, bx, by, bz, pw, R) in wash_lights(d, parts, spec, seed):
        vx = bx - X; vy = by - Y; vz = bz - hh
        dist = np.sqrt(vx * vx + vy * vy + vz * vz) + 1e-3
        lx, ly, lz = vx / dist, vy / dist, vz / dist
        att = pw / (1.0 + (dist / R) ** 2) ** 2.0
        ndl = np.clip(n[..., 0] * lx + n[..., 1] * ly + n[..., 2] * lz, 0, 1)
        hx_, hy_, hz_ = lx, ly, lz + 1.0
        hn = np.sqrt(hx_ * hx_ + hy_ * hy_ + hz_ * hz_)
        ndh = np.clip((n[..., 0] * hx_ + n[..., 1] * hy_ + n[..., 2] * hz_) / hn, 0, 1)
        face = m.astype(np.float32); rimf = rim.astype(np.float32) * SPILL
        e_ = (att * (face * (0.6 + 0.4 * np.clip(ndl * 2.5, 0, 1)) + rimf)).astype(np.float32)
        s_ = ((ndh ** 30) * att * (face * 0.5 + rimf * 2.0)).astype(np.float32)
        ef_ = (att * (face + rimf)).astype(np.float32)
        E += e_; S += s_; Ef += ef_
        add_t(wtn, e_, s_, ef_)
    # bulbs and lamps never do an even job: a slow, lumpy variation over the panel (a dusty lens, a bent reflector)
    r = np.random.default_rng(seed)
    lump = r.random((H // 16 + 2, W // 16 + 2)).astype(np.float32)
    lump = np.array(Image.fromarray((lump * 255).astype(np.uint8)).resize((W + 32, H + 32), Image.BICUBIC),
                    np.float32)[8:8 + H, 8:8 + W] / 255.0
    uneven = 0.78 + 0.44 * lump
    if by_tint is not None:
        for tn, (e_, s_, ef_) in parts_t.items(): by_tint[tn] = (e_ * uneven, s_ * uneven, ef_ * uneven)
    return E * uneven, S * uneven, Ef * uneven


def tint_field(by_tint, shape):
    """per pixel the colour of the light that reaches it: each tint weighted by its own light (E + S), leaning to the
    default tint where there is next to none -> H x W x 3"""
    num = np.zeros(shape + (3,), np.float64)
    den = np.full(shape, TINT_EPS, np.float64)
    num += TINT_EPS * np.array(TINTS[DEFAULT_TINT], np.float64)
    for tn, q in by_tint.items():
        e = np.clip((q[0] + q[1]).astype(np.float64), 0, None)
        num += e[..., None] * np.array(TINTS[tn], np.float64)
        den += e
    return num / den[..., None]


# ---------------------------------------------------------------------------------------------------- the plates
def night_ramp(name, warm_=True):
    """a material's ramp for the night: two darker steps under its darkest (the day's ramps bottom out at a shadow in
    daylight; a cabin at night goes lower), and with the bulbs on every step warmed to the bulb (warm_: True for the
    default bulb, or a tint (r, g, b))"""
    r = [tuple(int(v * f) for v in RAMPS[name][0]) for f in DARK_STEPS] + list(RAMPS[name])
    if warm_ is True: warm_ = TINT
    return np.array([warm(c, tint=warm_) if warm_ else c for c in r], np.int32)


def _steps(v, thr):
    """the shade (in day ramp steps, v = shade * 7) -> an index into night_ramp: below the first step the two dark
    steps take a third each, above it the ramp's own steps; thr is the dither threshold (0.5 = plain rounding)"""
    lo = np.clip(np.floor(v * 3.0 + thr), 0, 2)
    hi = np.clip(np.floor(v + thr), 1, 7) + 2
    return np.where(v * 3.0 + thr < 3.0, lo, hi).astype(int)


def relight(d, day_img, spec, seed=0, lights_on=True, parts=()):
    """the night plate (lights_on) or the dark one, as an RGBA image on the day plate's grid"""
    terms = d.lit_terms
    shade_day = terms["shade"]
    H, W = shade_day.shape
    by_tint = {}
    if lights_on:
        E, S, Ef = light_field(d, spec, seed, parts, by_tint=by_tint)
    else:
        E = np.zeros((H, W), np.float32); S = E.copy(); Ef = E.copy()
    # two colours of bulb on one plate (the late models' green gauges under amber lamps): each pixel warmed to the
    # mix of the light that reaches it; a one-colour dash keeps its one tint, exactly as before
    tpx = tint_field(by_tint, (H, W)) if (lights_on and len(spec_tints(spec)) > 1) else None
    cav = terms["cav"]
    tex = d.tex; dark = d.dark
    form = tex - dark - 0.30 * np.clip(cav, 0, None) + 0.10 * np.clip(-cav, 0, None)
    lit = E * K_LIT + np.minimum(1.0, E * 1.6) * form + 0.55 * S * d.polish
    amb = AMB * shade_day
    v = (amb + lit) * 7.0
    yy, xx = np.mgrid[0:H, 0:W]
    thr = BAYER4[yy % 4, xx % 4]
    # dither only where the bulbs reach: the dark stays a clean dark, the falloff steps in an ordered pattern
    thr = np.where(E + S > DITHER_FROM, thr, 0.5)
    idx = _steps(v, thr)
    # chrome shows what it reflects: the dark cabin, and the bulbs' glints where it faces them
    ci = d.mid("chrome")
    cm = (d.mat == ci) & d.solid
    if cm.any():
        vc = d.idx * AMB * 1.4 + np.clip(E * 3.2 + S * 9.0, 0, 7)
        idx[cm] = _steps(vc, np.where(E + S > DITHER_FROM, thr, 0.5))[cm]
    for (x, y), val in d.lock.items():
        idx[y, x] = int(_steps(np.array([[val * (AMB + float(E[y, x]) * K_LIT / DAY_FLAT)]]), np.array([[0.5]]))[0, 0])
    out = np.zeros((H, W, 4), np.uint8)
    for mi, name in enumerate(d.names):
        sel = d.solid & (d.mat == mi)
        if not sel.any(): continue
        if tpx is None:
            ramp = night_ramp(name, warm_=lights_on)
            out[sel, :3] = ramp[idx][sel]
        else:
            ramp = night_ramp(name, warm_=False)
            out[sel, :3] = np.clip(np.round(ramp[idx][sel].astype(np.float64) * tpx[sel]), 0, 255).astype(np.uint8)
        out[sel, 3] = 255
    # the plate's printed gradients (the temperature scale): paint, lit like the paint around it
    e = d.emit[..., 3] > 0
    if e.any():
        f = np.clip(AMB + Ef * K_LIT / DAY_FLAT, 0, 1)
        src = d.emit[..., :3].astype(np.float32)
        if tpx is None:
            tint = np.array(TINT if lights_on else (1.0, 1.0, 1.0), np.float32)
            out[e, :3] = np.clip(src * f[..., None] * tint, 0, 255).astype(np.uint8)[e]
        else:
            out[e, :3] = np.clip(src[e] * f[e][..., None] * tpx[e].astype(np.float32), 0, 255).astype(np.uint8)
        out[e, 3] = 255
    # the outline ring round the dash, as the day plate draws it
    day = np.asarray(day_img.convert("RGBA"))
    ring = (day[..., 3] > 0) & ~d.solid & ~e
    out[ring] = day[ring]
    relight.by_tint = by_tint            # (bake reads each tint's share of the light map from here)
    return Image.fromarray(out, "RGBA"), Ef


def light_map(Ef, lights_on=True):
    """the light a flat live part gets, as a share of the day's (0..1), in CELL x CELL cells, LEVELS + 1 steps"""
    H, W = Ef.shape
    r = np.clip(AMB + (Ef * K_LIT / DAY_FLAT if lights_on else 0), 0, 1)
    rows, cols = (H + CELL - 1) // CELL, (W + CELL - 1) // CELL
    pad = np.zeros((rows * CELL, cols * CELL), np.float32); pad[:H, :W] = r
    cell = pad.reshape(rows, CELL, cols, CELL).mean(axis=(1, 3))
    lv = np.clip(np.floor(cell * LEVELS + 0.5), 0, LEVELS).astype(int)
    return lv, rows, cols


def tint_map(by_tint, shape, names):
    """the light map's companion: per cell the colour of its light, as an index into a small palette of tints (each
    tint's share of the cell's flat light Ef, in TINT_STEPS steps, leaning to the default where there is next to none)
    -> (index array rows x cols, palette [(r, g, b)])"""
    H, W = shape
    rows, cols = (H + CELL - 1) // CELL, (W + CELL - 1) // CELL

    def cells(a):
        pad = np.zeros((rows * CELL, cols * CELL), np.float64); pad[:H, :W] = a
        return pad.reshape(rows, CELL, cols, CELL).mean(axis=(1, 3))
    share = []
    for tn in names:
        e = cells(np.clip(by_tint[tn][2], 0, None)) if tn in by_tint else np.zeros((rows, cols))
        if tn == DEFAULT_TINT: e = e + TINT_EPS
        share.append(e)
    share = np.stack(share, -1)
    share /= share.sum(-1, keepdims=True)
    # the other tints' shares in whole steps; the default takes what they leave
    q = np.floor(share[..., 1:] * TINT_STEPS + 0.5).astype(int)
    over = np.maximum(q.sum(-1) - TINT_STEPS, 0)
    q[..., -1] -= over
    keys, pal = {}, []
    idx = np.zeros((rows, cols), int)
    for r in range(rows):
        for c in range(cols):
            k = tuple(int(v) for v in q[r, c])
            if k not in keys:
                keys[k] = len(pal)
                w = [(TINT_STEPS - sum(k)) / TINT_STEPS] + [v / TINT_STEPS for v in k]
                pal.append(tuple(round(sum(wi * TINTS[tn][j] for wi, tn in zip(w, names)), 3) for j in range(3)))
            idx[r, c] = keys[k]
    if len(pal) > 16: raise SystemExit(f"night: {len(pal)} tints in one light map (16 at most, one hex digit)")
    return idx, pal


def amb_level():
    return int(np.clip(np.floor(AMB * LEVELS + 0.5), 0, LEVELS))


def level_mul(level, n=1.0, lit=True, tint=None):
    """the colour multiplier a live part gets at a light-map level, at nightness n (the Lua's arithmetic); tint: the
    colour of the light there (the tint map's), else the default bulb's"""
    f = level / float(LEVELS)
    t = (tint or TINT) if lit else (1.0, 1.0, 1.0)
    return tuple((1 - n) + n * f * tc for tc in t)


def glass_runs(d, day_img):
    """the backlit LCD glass (and what is printed on it), as runs per colour from the day plate"""
    day = np.asarray(day_img.convert("RGBA"))
    out = []
    for name in BACKLIT:
        if name not in d.names: continue
        m = d.solid & (d.mat == d.names.index(name))
        if m.sum() < 12: continue
        # each window: the glass and the ghost figures printed on it, everything in its box that is glass or print
        lab = _label(m)
        for li in range(1, lab.max() + 1):
            mm = lab == li
            if mm.sum() < 12: continue
            ys, xs = np.nonzero(mm)
            y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
            box_ = np.zeros_like(m); box_[y0:y1, x0:x1] = True
            pr = box_ & d.solid & np.isin(d.mat, [d.names.index(p) for p in ("segoff", "lcd") if p in d.names])
            cols = {}
            for y, x in zip(*np.nonzero(pr)):
                cols.setdefault(tuple(int(v) for v in day[y, x, :3]), []).append((x, y))
            for c, px in sorted(cols.items(), key=lambda kv: -len(kv[1])):
                out.append({"color": hexc(c), "runs": _runs(px)})
    return out


def _label(m):
    """4-way connected components (a plain flood fill: the glass is small)"""
    lab = np.zeros(m.shape, np.int32)
    cur = 0
    H, W = m.shape
    for y, x in zip(*np.nonzero(m)):
        if lab[y, x]: continue
        cur += 1
        stack = [(y, x)]; lab[y, x] = cur
        while stack:
            cy, cx = stack.pop()
            for ny, nx in ((cy - 1, cx), (cy + 1, cx), (cy, cx - 1), (cy, cx + 1)):
                if 0 <= ny < H and 0 <= nx < W and m[ny, nx] and not lab[ny, nx]:
                    lab[ny, nx] = cur; stack.append((ny, nx))
    return lab


def _runs(px):
    rows = {}
    for x, y in px: rows.setdefault(int(y), []).append(int(x))
    out = []
    for y in sorted(rows):
        xs = sorted(rows[y]); st = pv = xs[0]
        for x in xs[1:]:
            if x == pv + 1: pv = x
            else: out.append([st, y, pv - st + 1]); st = pv = x
        out.append([st, y, pv - st + 1])
    return out


def encode_map(lv):
    return "".join("0123456789abcdef"[v] for v in lv.reshape(-1).tolist())


def bake(did, b, day_img, spec, seed=0, needles="own"):
    """-> night image, dark image, the game's data for the design, the light map's levels. A dash lit in more than
    one colour also gets its tint map (tints: the palette, tmap: a hex digit per cell into it, beside the light map);
    a dash lit in amber alone has none and the game uses the one bulb colour (DashPx.night.tint), as before.
    needles: what a needle does on gauges lit in another colour than amber (designs.NEEDLES_UNDER_TINT): "own" keeps
    its own colour and takes only the light's level, as if light-piped (data.needleOwn); "lit" takes the light's
    colour like everything else"""
    if needles not in ("own", "lit"): raise SystemExit(f"night: needles {needles!r} (own or lit)")
    night, Ef = relight(b.d, day_img, spec, seed=seed, lights_on=True, parts=b.parts)
    by_tint = relight.by_tint
    dark, _ = relight(b.d, day_img, spec, seed=seed, lights_on=False, parts=b.parts)
    lv, rows, cols = light_map(Ef, True)
    data = {"plate": f"dash_{did}_night", "dark": f"dash_{did}_dark", "cell": CELL, "cols": cols, "rows": rows,
            "map": encode_map(lv), "glass": glass_runs(b.d, day_img)}
    names = spec_tints(spec)
    if len(names) > 1:
        ti, pal = tint_map(by_tint, Ef.shape, names)
        data["tints"] = [list(t) for t in pal]
        data["tmap"] = encode_map(ti)
        data["_tidx"] = ti                       # (the previews' copy; the export leaves it out)
        if needles == "own" and (spec.get("wash") or {}).get("tint", DEFAULT_TINT) != DEFAULT_TINT:
            data["needleOwn"] = True
    return night, dark, data, lv


def head_glass(img, parts):
    """a radio face's liquid-crystal glass (the dot-matrix sets): its colour, so the game can light it from behind
    at night while the set is on (the segment sets' figures glow by themselves on dark glass)"""
    a = np.asarray(img.convert("RGBA"))
    for hp in parts:
        if hp.get("t") != "display" or hp.get("style") != "dot": continue
        reg = a[hp["y"]:hp["y"] + hp["h"], hp["x"]:hp["x"] + hp["w"], :3].reshape(-1, 3)
        vals, cnt = np.unique(reg, axis=0, return_counts=True)
        hp["glass"] = hexc(vals[int(np.argmax(cnt))])
    return parts
