"""Dashboard parts in pixel art. Each part draws into a Dash and returns its live anchors (what the code moves)."""
import math
import numpy as np
from engine import Dash, Mask, hx, text_w, edt

ICONS = {  # 1 = ink
    "headlamp": ["0111000", "1111011", "1111000", "1111011", "0111000"],
    "beam":     ["0111001", "1111010", "1111000", "1111010", "0111001"],
    "oil":      ["0000010", "0111110", "1111101", "0111000", "0000000"],
    "batt":     ["0100010", "1111111", "1010101", "1000001", "1111111"],
    "temp":     ["01000", "01110", "01000", "01110", "11111"],
    "fuel":     ["11110", "10010", "11111", "11101", "11110"],
    "arrow_l":  ["00100", "01100", "11111", "01100", "00100"],
    "arrow_r":  ["00100", "00110", "11111", "00110", "00100"],
    "brake":    ["0111110", "1101011", "1101011", "1100011", "1101011", "0111110"],
    "engine":   ["0011100", "0100111", "1111101", "1111111", "0111110"],
    "fan":      ["0010000", "0011000", "1111111", "0001100", "0000100"],
    "defrost":  ["1111111", "1000001", "1010101", "1010101", "1111111"],
    "wiper":    ["0000001", "0000010", "0000100", "0001000", "1111111"],
    "hazard":   ["0001000", "0010100", "0101010", "1011101", "1111111"],
    "key":      ["0110000", "1001111", "1001010", "0110000"],
    "lock":     ["01110", "10001", "11111", "11011", "11111"],
}


def icon_mask(d, name, x, y):
    g = ICONS[name]; m = np.zeros((d.H, d.W), bool)
    for ry, row in enumerate(g):
        for rx, b in enumerate(row):
            if b == "1" and 0 <= x + rx < d.W and 0 <= y + ry < d.H: m[y + ry, x + rx] = True
    return m


def icon_size(name): return len(ICONS[name][0]), len(ICONS[name])


def line_mask(d, x0, y0, x1, y1, w=1.0):
    return Mask(d.W, d.H).line([(x0, y0), (x1, y1)], w).get(0.45)


# ------------------------------------------------------------------ chrome lips and bezels
def chrome_frame(d, x, y, w, h, z_on, t=1, r=0, mat="chrome", z=1.4):
    """a thin bright lip around a rectangle (t px wide): four round bars, so each catches sky on top and cabin below"""
    ring = np.zeros((d.H, d.W), bool)
    for (bx, by, bw, bh, ax) in ((x, y, w, t, "h"), (x, y + h - t, w, t, "h"), (x, y + t, t, h - 2 * t, "v"), (x + w - t, y + t, t, h - 2 * t, "v")):
        if t == 1:
            m = np.zeros((d.H, d.W), bool); m[by:by + bh, bx:bx + bw] = True
            d.h[m] = z_on + z; d.mat[m] = d.mid(mat); d.solid |= m; d.polish[m] = 1.0
            ring |= m
        else:
            ring |= d.cyl(bx, by, bw, bh, z, mat, axis=ax, polish=1.0, on=z_on)
    if t == 1:
        top = np.zeros((d.H, d.W), bool); top[y, x:x + w] = True
        bot = np.zeros((d.H, d.W), bool); bot[y + h - 1, x:x + w] = True
        lef = np.zeros((d.H, d.W), bool); lef[y:y + h, x] = True
        rig = np.zeros((d.H, d.W), bool); rig[y:y + h, x + w - 1] = True
        d.chrome_tone(top, 6); d.chrome_tone(lef, 5); d.chrome_tone(rig, 3); d.chrome_tone(bot, 2)
    return ring


def glare(d, mask, slope=-0.55, width=7, offset=0.18, amount=0.11):
    """the lens over a dial: one soft diagonal band of reflected sky"""
    ys, xs = np.nonzero(mask)
    if not len(xs): return
    x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
    u = (d.XX - x0) + (d.YY - y0) * slope * -1.0
    c = x0 + (x1 - x0) * offset - x0
    band = mask & (np.abs(u - c) < width / 2)
    band2 = mask & (np.abs(u - c - width * 1.6) < 1.0)
    d.tex[band] += amount; d.tex[band2] += amount * 0.7


def window(d, x, y, w, h, depth, face="face", bezel="chrome", r=2, bezel_t=2, on=0.0, lens=True):
    """a recessed instrument window: bezel lip, sloped wall, flat face, the glass's glare"""
    body = Mask(d.W, d.H).rrect(x, y, w, h, r).get()
    inner = Mask(d.W, d.H).rrect(x + bezel_t, y + bezel_t, w - 2 * bezel_t, h - 2 * bezel_t, max(0, r - 1)).get()
    d.h[inner] = on - depth
    d.mat[inner] = d.mid(face); d.solid |= inner; d.polish[inner] = 0.1; d.tex[inner] = 0
    if lens and w > 24: glare(d, inner)
    if bezel:
        ring = body & ~inner
        d.slab(ring, 1.6, bezel, bevel=1.0, polish=1.0, on=on)
    return inner


# ------------------------------------------------------------------ round gauge
def gauge(d, cx, cy, r, a0, a1, major, minor=0, labels=None, bezel="chrome", bezel_w=2, face="face", depth=3.0, on=0.0,
          redzone=None, label=None, label2=None, tick_mat="paint_w", num_mat="paint_w", num_r=None, label_y=None, lab_mat="paint_c",
          hub=2.5, needle_len=None):
    """angles in degrees, screen convention (0 = right, 90 = down). Returns the live needle anchor."""
    rr = np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - cy)
    faceM = rr <= r
    d.h[faceM] = on - depth; d.mat[faceM] = d.mid(face); d.solid |= faceM; d.polish[faceM] = 0.15; d.tex[faceM] = 0
    if bezel:
        d.torus(cx, cy, r, r + bezel_w + 0.6, 2.0, bezel, polish=1.0, on=on)
    # ticks
    def tick(a, l, w=1.0, mat=tick_mat):
        ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
        m = line_mask(d, cx + ca * (r - 1.6), cy + sa * (r - 1.6), cx + ca * (r - 1.6 - l), cy + sa * (r - 1.6 - l), w)
        d.paint(m & faceM, mat)
    n = len(major)
    for i, v in enumerate(major):
        a = a0 + (a1 - a0) * i / max(1, n - 1)
        red = redzone is not None and v >= redzone
        tick(a, max(3, r * 0.16), 1.0, "paint_r" if red else tick_mat)
        if minor and i < n - 1:
            for k in range(1, minor + 1):
                am = a + (a1 - a0) / max(1, n - 1) * k / (minor + 1)
                vm = v + (major[i + 1] - v) * k / (minor + 1)
                tick(am, max(2, r * 0.08), 1.0, "paint_r" if (redzone is not None and vm >= redzone) else tick_mat)
    if labels:
        nr = num_r if num_r else r - max(3, r * 0.16) - 6
        for i, t in enumerate(labels):
            if t is None or t == "": continue
            a = a0 + (a1 - a0) * i / max(1, len(labels) - 1)
            x = cx + math.cos(math.radians(a)) * nr; y = cy + math.sin(math.radians(a)) * nr
            red = redzone is not None and major[i] >= redzone
            d.text(t, int(round(x)), int(round(y - 2)), "paint_r" if red else num_mat, align="c")
    if label:
        d.text(label, int(cx), int(label_y if label_y is not None else cy + r * 0.38), lab_mat, align="c")
    if label2:
        d.text(label2, int(cx), int((label_y if label_y is not None else cy + r * 0.38) + 7), lab_mat, align="c")
    # hub
    d.dome(cx, cy, hub + 0.5, hub + 0.5, 2.2, "blackp", polish=0.9, on=on - depth)
    return {"cx": cx, "cy": cy, "r1": needle_len or (r - 3), "r0": -max(2, r * 0.12), "a0": a0, "a1": a1}


def needle(d, an, frac, color="#f07a28", width=2, edge="#7a2a08"):
    """preview only: the live needle at a value (0..1)"""
    a = an["a0"] + (an["a1"] - an["a0"]) * max(0, min(1, frac))
    ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
    x0, y0 = an["cx"] + ca * an["r0"], an["cy"] + sa * an["r0"]
    x1, y1 = an["cx"] + ca * an["r1"], an["cy"] + sa * an["r1"]
    m = line_mask(d, x0, y0, x1, y1, width)
    d.glow(m, color)
    # hub cap back on top
    rr = np.hypot(d.XX + 0.5 - an["cx"], d.YY + 0.5 - an["cy"])
    cap = rr <= 2.2
    d.emit[cap, 3] = 0
    return m


# ------------------------------------------------------------------ knobs, buttons, switches
def knob(d, cx, cy, r, mat="blackp", on=4.0, z=3.0, knurl=True, pointer=None, ptr_mat="paint_w", cap=None, skirt=None):
    if skirt:
        d.torus(cx, cy, r, r + skirt, 1.4, "chrome", polish=1.0, on=on)
    rr = np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - cy)
    m = rr <= r
    prof = np.where(rr <= r - 1.2, z, z * np.clip((r - rr) / 1.2, 0, 1) ** 0.6)
    d.h = np.where(m, on + prof, d.h).astype(np.float32)
    d.mat[m] = d.mid(mat); d.solid |= m; d.polish[m] = 0.6; d.tex[m] = 0
    if knurl:
        ang = np.degrees(np.arctan2(d.YY + 0.5 - cy, d.XX + 0.5 - cx))
        ring = m & (rr > r - 1.3)
        d.tex[ring & ((np.floor(ang / 20) % 2) == 0)] += 0.12
    if cap:
        d.dome(cx, cy, r - 2, r - 2, z + 0.8, cap, polish=1.0, on=on)
    if pointer is not None:
        ca, sa = math.cos(math.radians(pointer)), math.sin(math.radians(pointer))
        pm = line_mask(d, cx + ca * 1.0, cy + sa * 1.0, cx + ca * (r - 1.5), cy + sa * (r - 1.5), 1.0) & m
        d.paint(pm, ptr_mat, flatlight=True)
    return {"cx": cx, "cy": cy, "r": r}


def button(d, x, y, w, h, label=None, mat="blackp", on=4.0, z=1.8, lab_mat="paint_w", r=1, led=None, frame=None, lab_below=False):
    if frame:
        chrome_frame(d, x - 1, y - 1, w + 2, h + 2, on, t=1, r=r + 1, mat=frame, z=1.2)
    m = Mask(d.W, d.H).rrect(x, y, w, h, r).get()
    d.slab(m, z, mat, bevel=1.2, polish=0.4, on=on)
    if label:
        if lab_below:
            d.text(label, x + w // 2, y + h + 3, lab_mat, align="c")
        else:
            d.text(label, x + w // 2, y + (h - 5) // 2, lab_mat, align="c", flatlight=True)
    an = {"x": x, "y": y, "w": w, "h": h}
    if led:
        lx, ly = led
        lm = np.zeros((d.H, d.W), bool); lm[ly:ly + 2, lx:lx + 3] = True
        d.paint(lm, "lens", flatlight=True)
        an["led"] = (lx, ly, 3, 2)
    return an


def rocker(d, x, y, w, h, on=4.0, up=True, mat="blackp", icon=None, icon_mat="paint_w"):
    """a rocker switch: the pressed half sits low, the other proud"""
    m = Mask(d.W, d.H).rrect(x, y, w, h, 1).get()
    d.slab(m, 1.0, mat, bevel=1.0, polish=0.3, on=on)
    half = (d.YY < y + h // 2) if up else (d.YY >= y + h // 2)
    hm = m & half
    d.h[hm] += 1.4
    if icon:
        iw, ih = icon_size(icon)
        d.paint(icon_mask(d, icon, x + (w - iw) // 2, y + (h - ih) // 2), icon_mat, flatlight=True)
    return {"x": x, "y": y, "w": w, "h": h}


def toggle(d, cx, cy, up=True, on=4.0, plate=None):
    """an aircraft-style bat toggle on a hex nut"""
    d.dome(cx, cy, 4.2, 4.2, 1.6, "chrome", polish=1.0, on=on)
    d.dome(cx, cy, 2.6, 2.6, 2.4, "alu", polish=1.0, on=on)
    yy = (cy - 11, cy) if up else (cy, cy + 11)
    lever = line_mask(d, cx, cy, cx, (cy - 9) if up else (cy + 9), 2.0)
    d.h[lever] = on + 3.5 + (d.YY[lever] - cy) * (-0.15 if up else 0.15)
    d.mat[lever] = d.mid("chrome"); d.solid |= lever; d.polish[lever] = 1.0
    tip = Mask(d.W, d.H).ellipse(cx + 0.5, (cy - 9.5) if up else (cy + 9.5), 2.2, 2.2).get()
    d.slab(tip, 5.0, "chrome", bevel=1.5, polish=1.0, on=on)
    return {"cx": cx, "cy": cy}


def lever_slot(d, x, y, w, on=4.0, pos=0.5, knob_mat="chrome", labels=None, lab_y=None, grad=None):
    """an HVAC lever: a dark slot and a tab riding in it"""
    slot = np.zeros((d.H, d.W), bool); slot[y:y + 2, x:x + w] = True
    d.well(slot, 1.5, "rubber", bevel=0.6)
    if grad:
        cs = [hx(c) for c in grad]
        for i in range(w):
            t = i / max(1, w - 1)
            c = tuple(int(cs[0][k] + (cs[1][k] - cs[0][k]) * t) for k in range(3))
            d.emit[y - 3, x + i] = (*c, 255)
    tx = int(x + pos * (w - 8))
    tab = Mask(d.W, d.H).rrect(tx, y - 3, 8, 8, 1).get()
    d.slab(tab, 3.2, knob_mat, bevel=1.4, polish=1.0, on=on)
    if labels:
        ly = lab_y if lab_y is not None else y + 6
        n = len(labels)
        for i, t in enumerate(labels):
            lx = int(x + 4 + (w - 8) * i / max(1, n - 1))
            d.text(t, lx, ly, "paint_w", align="c")
    return {"x": x, "y": y, "w": w, "tab": (tx, y - 3, 8, 8)}


# ------------------------------------------------------------------ vents
def vent_rect(d, x, y, w, h, on=4.0, bezel="chrome", louvers=None, depth=3.0):
    inner = window(d, x, y, w, h, depth, face="blackp", bezel=bezel, r=1, bezel_t=2, on=on)
    pitch = 3
    for ly in range(y + 3, y + h - 3, pitch):
        lm = np.zeros((d.H, d.W), bool); lm[ly:ly + 2, x + 2:x + w - 2] = True
        d.cyl(x + 2, ly, w - 4, 2, 1.6, louvers or "blackp", axis="h", polish=0.4, on=on - depth, mask=lm & inner)
    return inner


def vent_round(d, cx, cy, r, on=4.0, bezel="chrome"):
    d.torus(cx, cy, r, r + 2.2, 2.0, bezel, polish=1.0, on=on)
    rr = np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - cy)
    ball = rr <= r
    d.h[ball] = on - 1 + np.sqrt(np.clip(1 - (rr[ball] / r) ** 2, 0, 1)) * 1.5
    d.mat[ball] = d.mid("blackp"); d.solid |= ball; d.polish[ball] = 0.5
    for k in range(-r + 2, r - 1, 3):
        lm = ball & (d.YY == cy + k)
        d.seam(lm, 0.4)
    return ball


# ------------------------------------------------------------------ displays
SEG = {  # 7-segment: a b c d e f g
    "0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc", "5": "afgcd", "6": "afgedc", "7": "abc", "8": "abcdefg",
    "9": "abcfgd", "-": "g", " ": "", "E": "afged", "F": "afge", "A": "abcefg", "P": "abefg", "C": "afed", "L": "fed", "H": "fbgec",
}


def seg_digit(d, ch, x, y, w, h, on_color, off_color=None, t=1):
    """a 7-segment digit, w x h, stroke t; off segments faint if off_color"""
    segs = {
        "a": (x + t, y, w - 2 * t, t), "d": (x + t, y + h - t, w - 2 * t, t), "g": (x + t, y + (h - t) // 2, w - 2 * t, t),
        "f": (x, y + t, t, (h - t) // 2 - t), "b": (x + w - t, y + t, t, (h - t) // 2 - t),
        "e": (x, y + (h - t) // 2 + t, t, h - (h - t) // 2 - 2 * t), "c": (x + w - t, y + (h - t) // 2 + t, t, h - (h - t) // 2 - 2 * t),
    }
    lit = SEG.get(ch, "")
    for k, (sx, sy, sw, sh) in segs.items():
        m = np.zeros((d.H, d.W), bool); m[sy:sy + sh, sx:sx + sw] = True
        if k in lit: d.glow(m, on_color)
        elif off_color: d.glow(m, off_color)


def dot_text(d, t, x, y, color, font="35"):
    m = d.text(t, x, y, "lens", font=font, flatlight=True)
    d.glow(m, color)
    return m


# ------------------------------------------------------------------ plates and stickers
def nameplate(d, t, x, y, on=4.0, mat="chrome", font="57", align="l", z=1.6, scale=1):
    """raised letters"""
    w = text_w(t, font, 1, scale)
    if align == "c": x -= w // 2
    m = d.text(t, x, y, mat, font=font, scale=scale)
    d.h[m] = on + z; d.mat[m] = d.mid(mat); d.solid |= m; d.polish[m] = 1.0
    sh = np.zeros_like(m); sh[1:, 1:] = m[:-1, :-1]
    d.dark[sh & ~m] = np.maximum(d.dark[sh & ~m], 0.25)
    return m


def dymo(d, t, x, y, on=4.0, align="l"):
    """embossed label tape: black tape, raised white letters"""
    w = text_w(t) + 6
    if align == "c": x -= w // 2
    tape = np.zeros((d.H, d.W), bool); tape[y:y + 9, x:x + w] = True
    d.slab(tape, 0.6, "dymo", bevel=0.6, polish=0.8, on=on)
    m = d.text(t, x + 3, y + 2, "paint_w")
    d.h[m] += 0.5
    return tape


def rivet(d, cx, cy, on=4.0):
    d.dome(cx, cy, 1.6, 1.6, 1.2, "alu", polish=1.0, on=on)
