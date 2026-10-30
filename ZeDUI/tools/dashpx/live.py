"""The game's side, in Python: draws a dash's live parts over its plate for a given vehicle state.
This mirrors the Lua interpreter (ZeD_Dashboard) step for step, so the previews show what the game will draw:
every live part is rect runs on the art pixel grid (k screen px per art px), nearest filtered, nothing smoothed.
"""
import math
import numpy as np
from PIL import Image
from engine import F35, F57, FONTS, RAMPS, hx

LIGHT2 = (-0.45, -1.0)
_l = math.hypot(*LIGHT2); LIGHT2 = (LIGHT2[0] / _l, LIGHT2[1] / _l)


def derive(st):
    """the values the parts read, from the raw vehicle state (the same derivations the Lua makes)"""
    s = dict(st)
    live = s.get("running") or s.get("keysIn") or s.get("hotwired")
    batt = s.get("battery", 0.8) if live else 0.0
    power = bool(live) and batt > 0.02
    s["power"] = power
    kmh = s.get("speed_kmh", 0) if power else 0
    s["speed_kmh"] = kmh
    s["speed_mph"] = kmh * 0.6214
    s["rpm"] = s.get("rpm", 0) if s.get("running") else 0
    s["fuel"] = s.get("fuel", 0.6) if power else 0.0
    s["batt"] = batt if power else 0.0
    s["temp"] = (0.82 if s.get("engWarn") else 0.5) if s.get("running") else (0.12 if power else 0.0)
    s["oil"] = (0.45 + 0.35 * min(1, s["rpm"] / 6000.0)) if s.get("running") else 0.0
    s["volts"] = (0.75 if s.get("running") else 0.35 + 0.25 * batt) if power else 0.0
    check = power and not s.get("running")
    s["check"] = check
    s["oilLamp"] = check
    s["genLamp"] = check or (power and batt < 0.2)
    s["brakeLamp"] = check
    s["beltLamp"] = check
    s["engLamp"] = check or (s.get("running") and s.get("engWarn", False))
    s["fuelLamp"] = power and s["fuel"] < 0.15
    s["tempLamp"] = power and s["temp"] > 0.8
    s["hiBeam"] = power and s.get("lights", False)
    s["lightsLamp"] = power and s.get("lights", False)
    s["turnL"] = False; s["turnR"] = False
    s["cruiseLamp"] = power and s.get("cruise", False)
    s["keyLed"] = s.get("keysIn", False)
    s["fourWD"] = False
    s["lbarLamp"] = s.get("lightbar", 0) > 0
    s["sirenLamp"] = s.get("siren", 0) > 0
    s["heatOn"] = s.get("heaterOn", False) and not s.get("ac", False)
    ht = s.get("heaterTemp", 0)
    s["tempF"] = max(0.0, min(1.0, (ht + 25) / 50.0))
    s["fanF"] = s.get("fan", 0) / 3.0
    s["modeF"] = 0.0 if not s.get("heaterOn") else (0.33 if s.get("ac") else (1.0 if ht >= 25 else 0.66))
    gear = s.get("gear", "P") if s.get("running") else "P"
    s["gear"] = gear
    s["odo"] = s.get("odo", 1234)
    s["shiftLamp"] = bool(s.get("running")) and s["rpm"] >= 6500
    return s


class Canvas:
    def __init__(s, plate, k=1):
        s.k = k
        s.img = plate.convert("RGBA").resize((plate.width * k, plate.height * k), Image.NEAREST)
        s.a = np.array(s.img)

    def rect(s, x, y, w, h, color, alpha=1.0):
        if w <= 0 or h <= 0: return
        k = s.k
        c = np.array(hx(color) if isinstance(color, str) else color, np.float32)
        y0, y1, x0, x1 = int(y * k), int((y + h) * k), int(x * k), int((x + w) * k)
        y0, x0 = max(0, y0), max(0, x0); y1, x1 = min(s.a.shape[0], y1), min(s.a.shape[1], x1)
        if y1 <= y0 or x1 <= x0: return
        reg = s.a[y0:y1, x0:x1, :3].astype(np.float32)
        s.a[y0:y1, x0:x1, :3] = (reg * (1 - alpha) + c * alpha).astype(np.uint8)
        s.a[y0:y1, x0:x1, 3] = 255

    def runs(s, runs, color, alpha=1.0, dx=0, dy=0):
        for x, y, w in runs: s.rect(x + dx, y + dy, w, 1, color, alpha)

    def sprite(s, im, x, y):
        k = s.k
        im = im.convert("RGBA").resize((im.width * k, im.height * k), Image.NEAREST)
        a = np.array(im)
        h, w = a.shape[:2]
        y0, x0 = int(y * k), int(x * k)
        if y0 < 0: a = a[-y0:]; h += y0; y0 = 0          # a sprite may rise above the plate (the hula girl): clip it
        if x0 < 0: a = a[:, -x0:]; w += x0; x0 = 0
        if h <= 0 or w <= 0: return
        sub = s.a[y0:y0 + h, x0:x0 + w]
        m = a[:sub.shape[0], :sub.shape[1], 3] > 0
        sub[m] = a[:sub.shape[0], :sub.shape[1]][m]

    def image(s): return Image.fromarray(s.a, "RGBA")


def pixels_to_runs(px):
    rows = {}
    for x, y in px: rows.setdefault(y, set()).add(x)
    out = []
    for y, xs in rows.items():
        xs = sorted(xs); st = pv = xs[0]
        for x in xs[1:]:
            if x == pv + 1: pv = x
            else: out.append((st, y, pv - st + 1)); st = pv = x
        out.append((st, y, pv - st + 1))
    return out


def needle_pixels(cx, cy, a_deg, r0, r1, w, hub=0.0):
    """the needle as art pixels: stepped along its length, thickened across its minor axis; split into lit and shade sides"""
    a = a_deg * math.pi / 180                          # the Lua's arithmetic, so a needle on a pixel edge lands the same
    ca, sa = math.cos(a), math.sin(a)
    px, py = -sa, ca                                   # across the needle
    lit_side = 1 if (px * LIGHT2[0] + py * LIGHT2[1]) > 0 else -1
    body, edge = set(), set()
    steps = int(abs(r1 - r0) * 2) + 1
    horiz = abs(ca) >= abs(sa)
    for i in range(steps + 1):
        r = r0 + (r1 - r0) * i / steps
        if abs(r) < hub: continue
        x, y = cx + ca * r, cy + sa * r
        for j in range(w):
            off = j - (w - 1) / 2.0
            if horiz: X, Y = math.floor(x), math.floor(y + off)
            else: X, Y = math.floor(x + off), math.floor(y)
            # which side of the centre line this pixel's centre sits on
            side = (X + 0.5 - x) * px + (Y + 0.5 - y) * py
            (body if (w == 1 or side * lit_side >= 0) else edge).add((X, Y))
    edge -= body
    return body, edge


def shade(color, f):
    c = hx(color); return tuple(max(0, min(255, int(v * f))) for v in c)


def draw_text(cv, t, x, y, color, font="35", scale=1, align="l", style="flat", shadow=None, mul=None):
    f = FONTS[font]
    w = (sum(len(f.get(c, f.get(c.upper(), f[" "]))[0]) + 1 for c in t) - 1) * scale    # the glyphs drawn (lower case as upper)
    if align == "c": x -= w // 2
    elif align == "r": x -= w
    rows = len(f["A"])
    pix = {}
    cx = x
    for ch in t:
        g = f.get(ch, f.get(ch.upper(), f[" "]))
        for ry, row in enumerate(g):
            for rx, b in enumerate(row):
                if b == "1":
                    for sy in range(scale):
                        for sx in range(scale):
                            pix[(cx + rx * scale + sx, y + ry * scale + sy)] = ry * scale + sy
        cx += (len(g[0]) + 1) * scale
    if shadow:
        sp = [(px + 1, py + 1) for (px, py) in pix if (px + 1, py + 1) not in pix]
        cv.runs(pixels_to_runs(sp), shadow, 1.0)
    if style == "chrome":
        H = rows * scale
        ramp = RAMPS["chrome"]
        by_tone = {}
        tones = {5: [7, 6, 5, 5, 4], 7: [7, 7, 6, 5, 5, 4, 3]}.get(H) or [7 if i < H * 0.2 else (6 if i < H * 0.4 else (5 if i < H * 0.65 else 4)) for i in range(H)]
        for (px, py), ry in pix.items():
            by_tone.setdefault(tones[min(ry, len(tones) - 1)], []).append((px, py))
        for tone, pp in by_tone.items():
            c = ramp[tone] if mul is None else tuple(max(0, min(255, int(v * f))) for v, f in zip(ramp[tone], mul))
            cv.runs(pixels_to_runs(pp), c)
    elif style == "emboss":
        cv.runs(pixels_to_runs(list(pix)), color)
    else:
        cv.runs(pixels_to_runs(list(pix)), color)
    return w


SEGS = {"0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc", "5": "afgcd", "6": "afgedc", "7": "abc", "8": "abcdefg",
        "9": "abcfgd", "-": "g", " ": "", "E": "afged", "F": "afge", "A": "abcefg", "P": "abefg", "C": "afed", "L": "fed", "H": "fbgec",
        "r": "eg", "n": "ceg", "o": "cdeg", "d": "bcdeg", "t": "fged", "U": "bcdef", "b": "fgcde", "S": "afgcd"}


def seg_rects(x, y, w, h, t=1):
    return {
        "a": (x + t, y, w - 2 * t, t), "d": (x + t, y + h - t, w - 2 * t, t), "g": (x + t, y + (h - t) // 2, w - 2 * t, t),
        "f": (x, y + t, t, (h - t) // 2 - t), "b": (x + w - t, y + t, t, (h - t) // 2 - t),
        "e": (x, y + (h - t) // 2 + t, t, h - (h - t) // 2 - 2 * t), "c": (x + w - t, y + (h - t) // 2 + t, t, h - (h - t) // 2 - 2 * t),
    }


def draw_digits(cv, txt, x, y, cw, ch, pitch, t, color, off=None, align="r", n=None):
    """seven-segment figures; a '.' rides on the figure before it"""
    cells = []
    for c in txt:
        if c == "." and cells: cells[-1][1] = True
        else: cells.append([c, False])
    n = n or len(cells)
    cells = cells[-n:]
    pad = n - len(cells)
    cells = ([[" ", False]] * pad + cells) if align == "r" else (cells + [[" ", False]] * pad)
    xx = x
    for c, dot in cells:
        rs = seg_rects(xx, y, cw, ch, t)
        lit = SEGS.get(c, "")
        for k_, (sx, sy, sw, sh) in rs.items():
            if k_ in lit: cv.rect(sx, sy, sw, sh, color)
            elif off: cv.rect(sx, sy, sw, sh, off)
        if dot: cv.rect(xx + cw + max(0, (pitch - cw - t) // 2), y + ch - t, t, t, color)
        xx += pitch


def text_width(t, font, scale):
    f = FONTS[font]
    return (sum(len(f.get(c, f.get(c.upper(), f[" "]))[0]) + 1 for c in t) - 1) * scale


def fit_text(t, font, scale, w):
    """the game's fitting: whole words off the front first (the make), then a smaller face, then letters off the end"""
    if text_width(t, font, scale) <= w: return t, font, scale
    if scale > 1 and text_width(t, font, scale - 1) <= w: return t, font, scale - 1
    words = t.split()
    while len(words) > 1 and text_width(" ".join(words), font, scale) > w: words = words[1:]
    t2 = " ".join(words)
    if text_width(t2, font, scale) <= w: return t2, font, scale
    if font == "57" and text_width(t2, "35", scale) <= w: return t2, "35", scale
    font = "35"
    while len(t2) > 1 and text_width(t2, font, scale) > w: t2 = t2[:-1]
    return t2, font, scale


def badge_fit(p, label, tag):
    """a model line with its tag after it: the model fitted to the room the tag leaves (no room: the tag goes), the two
    centred together for align "c". -> (the model's x off p.x, the model, font, scale, the tag's x off p.x or None)"""
    font, scale = p.get("font", "35"), p.get("scale", 1)
    gap = text_width("A ", font, scale) - text_width("A", font, scale)
    room = p["w"] - gap - text_width(tag, font, scale)
    if room <= 0:
        s_, font, scale = fit_text(label, font, scale, p["w"]); tag = None
    else:
        s_, font, scale = fit_text(label, font, scale, room)
    mw = text_width(s_, font, scale)
    total = mw + (gap + text_width(tag, font, scale) if tag else 0)
    lx = (p["w"] // 2 - total // 2) if p.get("align", "c") == "c" else 0
    return lx, s_, font, scale, (lx + mw + gap if tag else None)


def fmt_value(p, st):
    src = p["src"]; v = st.get(src, 0)
    if p.get("fmt") == "int": return str(int(round(v)))
    if p.get("fmt") == "rpm100": return str(int(round(v / 100.0)))
    return str(v)


class Night:
    """the game's night rule (ZeD_Plate.lua, PL.light*): nightness n in eighths, the light map's level under a part,
    the colour multiplier for that level in the colour of the light there (the tint map's, else the one bulb's);
    n = 0 is the day, untouched. data: the bake's night data (its tint map, needleOwn), when the dash has one"""
    def __init__(s, n, lit, levels, night_img=None, dark_img=None, glass=None, cell=4, data=None):
        import night as NT
        s.NT = NT
        s.n8 = int(math.floor(n * 8 + 0.5)); s.n = s.n8 / 8.0
        s.lit = lit; s.lv = levels; s.cell = cell
        s.night_img, s.dark_img, s.glass = night_img, dark_img, glass or []
        s.amb = NT.amb_level()
        data = data or {}
        s.tidx = data.get("_tidx")
        s.tints = [tuple(t) for t in data.get("tints", ())]
        s.needle_own = bool(data.get("needleOwn"))

    def _cell(s, x, y):
        r = int(min(s.lv.shape[0] - 1, max(0, math.floor(y / s.cell))))
        c = int(min(s.lv.shape[1] - 1, max(0, math.floor(x / s.cell))))
        return r, c

    def level(s, x, y):
        if not s.lit: return s.amb
        return int(s.lv[s._cell(x, y)])

    def tint(s, x, y):
        """the colour of the light at a plate point, bulbs on (the Lua's tintRaw)"""
        if s.tidx is None: return None
        return s.tints[int(s.tidx[s._cell(x, y)])]

    def mul(s, level, tint=None): return s.NT.level_mul(level, s.n, s.lit, tint)

    def mul_at(s, x, y): return s.mul(s.level(x, y), s.tint(x, y))

    def dim(s, color, x, y):
        c = hx(color) if isinstance(color, str) else color
        m = s.mul_at(x, y)
        return tuple(max(0, min(255, int(v * f))) for v, f in zip(c, m))

    def dim_level(s, color, x, y):
        """a light-piped needle: its own colour at the level of the light it sits in (the Lua's dimLevel)"""
        c = hx(color) if isinstance(color, str) else color
        m = s.mul(s.level(x, y), (1.0, 1.0, 1.0))
        return tuple(max(0, min(255, int(v * f))) for v, f in zip(c, m))

    def tint_img(s, im, x, y):
        m = s.mul_at(x + im.width / 2.0, y + im.height / 2.0)
        a = np.array(im.convert("RGBA")).astype(np.float32)
        a[..., :3] *= np.array(m, np.float32)
        return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")


def _dimruns(cv, runs, color, nt, dx=0, dy=0, alpha=1.0, piped=False):
    """runs in a colour that follows the light: each run takes the level at its own middle (piped: the level only)"""
    if nt is None or nt.n8 == 0: cv.runs(runs, color, alpha, dx, dy); return
    f = nt.dim_level if piped else nt.dim
    for x, y, w in runs: cv.rect(x + dx, y + dy, w, 1, f(color, x + dx + w / 2.0, y + dy), alpha)


def render_live(plate, design, st, k=1, sprites=None, heads=None, night=None):
    st = derive(st)
    nt = night if (night is not None and night.n8 > 0) else None
    if nt is not None:
        over = nt.night_img if nt.lit else nt.dark_img
        base = plate.convert("RGBA").copy()
        if over is not None: base = Image.blend(base, over.convert("RGBA"), nt.n)
        plate = base
    cv = Canvas(plate, k)
    if nt is not None and st.get("power"):
        for g in nt.glass: cv.runs(g["runs"], g["color"], nt.n)        # the LCD glass, lit from behind
    D = (lambda c, x, y: nt.dim(c, x, y)) if nt is not None else (lambda c, x, y: c)
    for p in design["parts"]:
        t = p["t"]
        if t == "needle":
            v = st.get(p["src"], 0) / float(p.get("max", 1))
            v = max(0.0, min(1.02 if p.get("peg") else 1.0, v))
            a = p["a0"] + (p["a1"] - p["a0"]) * v
            col = p["color"]
            if p.get("low_src") and st.get(p["low_src"]): col = p.get("low_color", "#ff4a3a")
            body, edge = needle_pixels(p["cx"], p["cy"], a, p["r0"], p["r1"], p.get("w", 2), hub=p.get("hub", 0))
            allp = body | edge
            sh = [(x + 1, y + 2) for (x, y) in allp]
            cv.runs(pixels_to_runs(sh), (0, 0, 0), 0.45)
            piped = nt is not None and nt.needle_own
            _dimruns(cv, pixels_to_runs(edge), shade(col, 0.55), nt, piped=piped)
            _dimruns(cv, pixels_to_runs(body), col, nt, piped=piped)
        elif t == "ribbon":
            v = max(0.0, min(1.0, st.get(p["src"], 0) / float(p["max"])))
            xx = int(round(p["x0"] + (p["x1"] - p["x0"]) * v))
            if p.get("mode") == "fill":
                # a cell's width at a time, so the strip takes the light along its length
                for x0 in range(p["x0"], xx, 4):
                    w_ = min(4, xx - x0); cy_ = p["y"] + p["h"] / 2.0
                    cv.rect(x0, p["y"], w_, p["h"], D(p["color"], x0 + w_ / 2.0, cy_))
                    cv.rect(x0, p["y"], w_, 1, D(shade(p["color"], 1.25), x0 + w_ / 2.0, cy_))
                    cv.rect(x0, p["y"] + p["h"] - 1, w_, 1, D(shade(p["color"], 0.6), x0 + w_ / 2.0, cy_))
            else:
                cy_ = p["y"] + p["h"] / 2.0
                cv.rect(xx + 1, p["y"] + 2, 2, p["h"], (0, 0, 0), 0.45)
                cv.rect(xx - 1, p["y"], 1, p["h"], D(p["color"], xx, cy_)); cv.rect(xx, p["y"], 1, p["h"], D(shade(p["color"], 0.6), xx, cy_))
        elif t == "lamp":
            if st.get(p["src"]):
                if p.get("halo"): cv.runs(p["halo"], p["color"], 0.30)
                cv.runs(p["runs"], p["color"])
        elif t == "led":
            if st.get(p["src"]):
                cv.rect(p["x"], p["y"], p["w"], p["h"], p["color"])
        elif t == "gear":
            g = st.get("gear", "P")
            if st.get("power") and g in p["letters"]:
                cv.runs(p["letters"][g], p["color"])
                if p.get("box"):
                    bx, by, bw, bh = p["box"][g]
                    cv.rect(bx, by, bw, 1, p["color"]); cv.rect(bx, by + bh - 1, bw, 1, p["color"])
        elif t == "bars":
            v = max(0.0, min(1.0, st.get(p["src"], 0) / float(p.get("max", 1)))) if st.get("power") else 0.0
            n = int(round(v * len(p["bars"])))
            for i, runs in enumerate(p["bars"][:n]):
                c = p["color"]
                if p.get("red_from") is not None and i >= p["red_from"]: c = p.get("red", "#ff3a20")
                elif p.get("warn_from") is not None and i >= p["warn_from"]: c = p.get("warn", "#ffb02e")
                cv.runs(runs, c)
        elif t == "digits":
            if not st.get("power") and not p.get("always"): continue
            txt = fmt_value(p, st)
            draw_digits(cv, txt, p["x"], p["y"], p["cw"], p["ch"], p["pitch"], p.get("st", 1), p["color"], p.get("off"), p.get("align", "r"), p.get("n"))
        elif t == "ptr":
            if "angles" in p:
                v = st.get(p["src"], 0)
                if isinstance(v, bool): v = 1 if v else 0
                a = p["angles"][max(0, min(len(p["angles"]) - 1, int(v)))]
            else:
                v = max(0.0, min(1.0, st.get(p["src"], 0)))
                a = p["a0"] + (p["a1"] - p["a0"]) * v
            body, edge = needle_pixels(p["cx"], p["cy"], a, p["r0"], p["r1"], p.get("w", 1))
            cv.runs(pixels_to_runs(body | edge), D(p["color"], p["cx"], p["cy"]))
        elif t == "tab":
            v = max(0.0, min(1.0, st.get(p["src"], 0)))
            x = int(round(p["x0"] + (p["x1"] - p["x0"]) * v))
            if sprites and p["sprite"] in sprites:
                im = sprites[p["sprite"]]
                cv.sprite(nt.tint_img(im, x, p["y"]) if nt else im, x, p["y"])
        elif t == "sprite":
            val = st.get(p["src"])
            key = p.get("when", True)
            # a sprite shows while its state reads `when`: a flag (true / false) or one value of several
            # (the key's position "off" / "on" / "start", a frame number)
            hit_ = (val == key) if isinstance(key, (str, int)) and not isinstance(key, bool) else (bool(val) == bool(key))
            if hit_ and sprites and p["sprite"] in sprites:
                im = sprites[p["sprite"]]
                cv.sprite(nt.tint_img(im, p["x"], p["y"]) if nt else im, p["x"], p["y"])
        elif t == "badge":
            # (src / when: a maker's model line shows with its mark, the plaque's name only for a maker we don't know)
            if p.get("src") and st.get(p["src"]) != p.get("when"): continue
            label = st.get("badge_" + p.get("role", "label"), "")
            if not label: continue
            tag = st.get("badge_tag", "") if p.get("tag") else ""
            col = p.get("color", "#d8dade")
            bx_, by_ = p["x"] + p["w"] / 2.0, p["y"] + p["h"] / 2.0
            if tag:      # the model, then the performance tag in its own colour (ZeD_Plate.lua's badgeFit)
                lx, s_, font, scale, tx = badge_fit(p, label, tag)
                y = p["y"] + (p["h"] - len(FONTS[font]["A"]) * scale) // 2
                draw_text(cv, s_, p["x"] + lx, y, D(col, bx_, by_), font, scale, "l", "flat", D(p["shadow"], bx_, by_) if p.get("shadow") else None)
                if tx is not None:
                    draw_text(cv, tag, p["x"] + tx, y, D(p["tag"], bx_, by_), font, scale, "l", "flat",
                              D(p["tagShadow"], bx_, by_) if p.get("tagShadow") else None)
                continue
            label, font, scale = fit_text(label, p.get("font", "35"), p.get("scale", 1), p["w"])
            x = p["x"] + (p["w"] // 2 if p.get("align", "c") == "c" else 0)
            y = p["y"] + (p["h"] - len(FONTS[font]["A"]) * scale) // 2
            if p.get("style") == "emboss":
                draw_text(cv, label, x + 1, y + 1, D("#f0f0ec", bx_, by_), font, scale, p.get("align", "c"))
            draw_text(cv, label, x, y, D(col, bx_, by_), font, scale, p.get("align", "c"), p.get("style", "flat"),
                      D(p["shadow"], bx_, by_) if p.get("shadow") else None, mul=(nt.mul_at(bx_, by_) if nt else None))
        elif t == "clock":
            hr, mn = st.get("hour", 10), st.get("minute", 8)
            am = mn * 6 - 90; ah = (hr % 12) * 30 + mn * 0.5 - 90
            for a, rr, w in ((ah, p["rh"], 2), (am, p["rm"], 1)):
                body, edge = needle_pixels(p["cx"], p["cy"], a, 0, rr, w, hub=1.5)
                cv.runs(pixels_to_runs(body | edge), D(p["color"], p["cx"], p["cy"]))
        elif t == "sticker":
            if st.get("sticker_im") is not None:     # round 6: the van's sticker, a decal or a trade sticker, its name live
                im = st["sticker_im"]
                sx, sy = p["x"] + (p["w"] - im.width) // 2, p["y"] + (p["h"] - im.height) // 2
                cv.sprite(nt.tint_img(im, sx, sy) if nt else im, sx, sy)
                nm = st.get("sticker_name")
                if nm:
                    lines = nm.upper().split("|")
                    for i, ln in enumerate(lines[:2]):
                        draw_text(cv, ln, sx + 32, sy + 47 + i * 6 - (3 if len(lines) == 1 else 0) + 2, "#3a3226", "35", 1, "c")
            elif p.get("match", "") in str(st.get("script", "")).lower():
                cv.rect(p["x"], p["y"], p["w"], p["h"], "#f4f2ea")
                cv.rect(p["x"], p["y"], p["w"], 1, "#ffffff"); cv.rect(p["x"], p["y"] + p["h"] - 1, p["w"], 1, "#b8b4a8")
                draw_text(cv, "STICKER", p["x"] + p["w"] // 2, p["y"] + p["h"] // 2 - 6, "#8a8678", "35", 1, "c")
                draw_text(cv, "(GAME ART)", p["x"] + p["w"] // 2, p["y"] + p["h"] // 2 + 2, "#8a8678", "35", 1, "c")
        elif t == "headunit":
            kind = st.get("radio", None)
            if heads and kind in heads:
                img, hparts = heads[kind][:2]
                head_face(cv, img, p["x"], p["y"], nt)
                for hp in hparts:
                    if hp["t"] == "display" and st.get("radioOn") and st.get("power"):
                        if nt is not None and hp.get("glass"):      # a liquid-crystal glass glows from behind
                            cv.rect(p["x"] + hp["x"], p["y"] + hp["y"], hp["w"], hp["h"], hp["glass"], nt.n)
                        draw_radio_display(cv, hp, p["x"], p["y"], st)
                    elif hp["t"] == "knob":
                        v = st.get("radioVol", 0.6) if hp["id"] == "vol" else (st.get("radioTune", 0.3))
                        a = 135 + 270 * v
                        body, edge = needle_pixels(p["x"] + hp["cx"], p["y"] + hp["cy"], a, 3, hp["r"] - 2, 1)
                        cv.runs(pixels_to_runs(body | edge), D(hp["ptr"], p["x"] + hp["cx"], p["y"] + hp["cy"]))
            elif sprites and "hu_blank" in sprites:
                head_face(cv, sprites["hu_blank"], p["x"], p["y"], nt)
        elif t == "climate":
            if not st.get("power"): continue
            col = p.get("color", "#1c2418")
            tC = int(round(21 + st.get("heaterTemp", 0) * 0.28))
            if p.get("units", "C") == "F": tC = int(round(tC * 9 / 5 + 32))
            draw_digits(cv, str(tC), p["x"], p["y"], 7, 11, 9, 1, col, p.get("off"), "l", 2)
            mode = ("A/C" if st.get("ac") else "AUTO") if st.get("heaterOn") else "OFF"
            draw_text(cv, mode, p["x"] + 21, p["y"], col)
            draw_text(cv, "FAN" + str(st.get("fan", 0)), p["x"] + 21, p["y"] + 6, col)
        elif t == "meter":
            if not st.get("power"): continue
            txt = st.get(p.get("src", "fare"))
            txt = ("%.2f" % txt) if isinstance(txt, (int, float)) else p.get("demo", "3.40")
            draw_digits(cv, txt, p["x"], p["y"], p.get("cw", 6), p.get("ch", 9), p.get("pitch", 9), 1, p["color"], p.get("off"), "r",
                        p.get("digits", 5))
    return cv.image()


def head_face(cv, img, x, y, nt):
    """the radio's face: as it is by day; at night tinted to the light of its brightest cell row, and every row under
    that darkened to its own (the lamp above lights the top of the radio, its lower edge falls away)"""
    if nt is None: cv.sprite(img, x, y); return
    rows = head_rows(nt, x, y, img.width, img.height)
    top = max(lv for _, _, lv, _ in rows)
    tt = next(t for _, _, lv, t in rows if lv == top)        # the light of the brightest row (the first of them)
    m = nt.mul(top, tt)
    a = np.array(img.convert("RGBA")).astype(np.float32); a[..., :3] *= np.array(m, np.float32)
    cv.sprite(Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA"), x, y)
    for (ry, rh, lv, _) in rows:
        al = head_shade(nt, lv, top, tt)
        if al > 0: cv.rect(x, ry, img.width, rh, (0, 0, 0), al)


def head_rows(nt, x, y, w, h):
    """(y, height, level, tint) per light-map cell row across a rect: the row's level is its cells' mean, rounded;
    its tint the light's colour at its middle cell"""
    out = []
    c = nt.cell
    r0, r1 = int(math.floor(y / c)), int(math.floor((y + h - 1) / c))
    c0, c1 = int(math.floor(x / c)), int(math.floor((x + w - 1) / c))
    for r in range(r0, r1 + 1):
        if nt.lit:
            rr = min(nt.lv.shape[0] - 1, max(0, r))
            vals = [int(nt.lv[rr, min(nt.lv.shape[1] - 1, max(0, cc))]) for cc in range(c0, c1 + 1)]
            lv = int(math.floor(sum(vals) / float(len(vals)) + 0.5))
        else:
            lv = nt.amb
        yy0 = max(y, r * c); yy1 = min(y + h, (r + 1) * c)
        out.append((yy0, yy1 - yy0, lv, nt.tint(((c0 + c1) // 2) * c, r * c)))
    return out


def head_shade(nt, lv, top, tt=None):
    """the black over a row: what its light lacks against the face's tint (in eighths, like the game)"""
    m, mt = nt.mul(lv, tt), nt.mul(top, tt)
    lum = 0.3 * m[0] + 0.59 * m[1] + 0.11 * m[2]
    lt = 0.3 * mt[0] + 0.59 * mt[1] + 0.11 * mt[2]
    if lt <= 0: return 0.0
    return math.floor((1 - lum / lt) * 8 + 0.5) / 8.0


def draw_radio_display(cv, hp, ox, oy, st):
    """the radio's display in pixel figures: big seven-segment frequency, or two lines of dot-matrix text"""
    x, y, w, h = ox + hp["x"], oy + hp["y"], hp["w"], hp["h"]
    col = hp["color"]; kind = hp.get("kind")
    band = st.get("radioBand", "FM"); freq = st.get("radioFreq", "98.4")
    ham = kind in ("ham", "army", "hammake")
    if hp["style"] == "seg":
        txt = ("098.400" if ham else freq)
        n = len(txt.replace(".", ""))
        cw, ch, pitch, t = (7, 13, 10, 2) if n <= 4 else (6, 12, 8, 1)
        xr = x + w - 3 - n * pitch
        if hp.get("ghost"):
            draw_digits(cv, "8" * n, xr, y + 3, cw, ch, pitch, t, hp["ghost"], None, "l", n)
        draw_digits(cv, txt, xr, y + 3, cw, ch, pitch, t, col, None, "l", n)
        draw_text(cv, "CH01" if ham else band, x + 3, y + 3, col)
        draw_text(cv, "TX" if ham else "P1", x + 3, y + 10, col)
        sx = x + (21 if ham else 13)
        for i in range(4):
            if i < 3: cv.rect(sx + i * 2, y + 8 - (i + 1) * 2 + 1, 1, (i + 1) * 2, col)
    else:
        l1 = ("CH01 098.400" if ham else (band + " " + freq))
        l2 = ("TX  SQL" if ham else st.get("radioStation", "KNOX TALK"))
        draw_text(cv, l1, x + 3, y + 2, col, "57")
        draw_text(cv, l2[:24], x + 3, y + 11, col, "35")
