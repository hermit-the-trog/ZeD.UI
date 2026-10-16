"""
Bake the car radios (ZeD-UI, Oct 15 2026; mockup zed_car_radio_v1.html, approved:
"love it, build it, yes match the dash to the radio").

Vanilla fits its own radio items into a car's Radio part; each gets a face:

  premium   Premium Technologies Radio (Base.RadioRed): CD receiver, cyan display
  valutech  ValuTech Radio (Base.RadioBlack): budget, amber digits, presets on tape
  makeshift Makeshift Radio (Base.RadioMakeShift): a bare board, a 2-line LCD
  ham       Premium Technologies Ham Radio (Base.HamRadio1): two-way rig, big dial
  army      US ARMY COMM. Ham Radio (Base.HamRadio2): olive drab, red LED digits
  hammake   Makeshift Ham Radio (Base.HamRadioMakeShift): a bigger bare board

For each, two sizes:
  radio_<kind>.png          the face up close (the prop above the dash), with its
                            knob bodies; 2 px per unit
  dhead_<kind>_<h>.png      the small face for the dash console's head-unit slot,
                            252 units wide and h tall (one per console height)
What moves is drawn live: the display, the knob pointers, the lamps, presses.
Anchors go to 42/media/lua/client/ZeD/RadioPlates.lua (ZeD.RadioPlates).

Usage:  py ZeDUI/tools/plates/bake_radio_plates.py
"""
import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
OUT = os.path.join(ROOT, "42", "media", "textures", "ZeD", "dash")
OUT_LUA = os.path.join(ROOT, "42", "media", "lua", "client", "ZeD", "RadioPlates.lua")
FONTS = os.path.join(os.environ.get("LOCALAPPDATA", ""), "Microsoft", "Windows", "Fonts")
K = 2
SH = 4
DASH_W = 252
DASH_HEIGHTS = (38, 46, 48, 50, 52)


def u(v):
    return int(round(v * K))


def font(name, size):
    return ImageFont.truetype(os.path.join(FONTS, name), max(1, u(size)))


MONO_B = "FiraMono-Bold.ttf"


def hexc(s, a=255):
    s = s.lstrip("#")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), a)


def canvas(w, h, shadow=True):
    im = Image.new("RGBA", (u(w + (SH if shadow else 0)), u(h + (SH if shadow else 0))), (0, 0, 0, 0))
    if shadow:
        sh = Image.new("RGBA", im.size, (0, 0, 0, 0))
        ImageDraw.Draw(sh).rounded_rectangle([u(3), u(3), u(3 + w) - 1, u(3 + h) - 1], radius=u(4), fill=(0, 0, 0, 115))
        im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(1)))
    return im


def body(im, w, h, top, bottom, noise=0.0, radius=4, edge="#000000", hi="#3c3f44", seed=1):
    """the case: a vertical gradient (or flat), optional grain, a dark outline, a lit top edge"""
    W, H = u(w), u(h)
    t = np.linspace(0, 1, H, dtype=np.float32)[:, None]
    a, b = np.array(hexc(top)[:3], np.float32), np.array(hexc(bottom)[:3], np.float32)
    rgb = a[None, None, :] * (1 - t[..., None]) + b[None, None, :] * t[..., None]
    rgb = np.repeat(rgb, W, axis=1)
    if noise > 0:
        rng = np.random.default_rng(seed)
        n = rng.normal(0, 1, (H, W)).astype(np.float32)
        n = np.asarray(Image.fromarray(((n * 40) + 128).clip(0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.7)), np.float32) - 128
        rgb = rgb + n[..., None] * noise
    face = Image.fromarray(np.concatenate([rgb.clip(0, 255), np.full((H, W, 1), 255, np.float32)], axis=2).astype(np.uint8), "RGBA")
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, W - 1, H - 1], radius=u(radius), fill=255)
    im.paste(face, (0, 0), mask)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([0, 0, W - 1, H - 1], radius=u(radius), outline=hexc(edge), width=u(1))
    if hi:
        d.line([(u(radius), u(1)), (W - u(radius), u(1))], fill=hexc(hi), width=u(1))
    return d


def text(d, x, y, s, size, fill, f=MONO_B, spacing=0.0, anchor="la"):
    fo = font(f, size)
    if spacing <= 0:
        d.text((u(x), u(y)), s, font=fo, fill=hexc(fill) if isinstance(fill, str) else fill, anchor=anchor)
        return
    total = sum(d.textlength(c, font=fo) for c in s) + u(spacing) * (len(s) - 1)
    cx = u(x) - (total if anchor[0] == "r" else (total / 2 if anchor[0] == "m" else 0))
    for c in s:
        d.text((cx, u(y)), c, font=fo, fill=hexc(fill) if isinstance(fill, str) else fill, anchor="l" + anchor[1])
        cx += d.textlength(c, font=fo) + u(spacing)


KNOBS = {
    "silver": ((58, 60, 64), (106, 109, 114), (138, 141, 146), (44, 46, 49)),
    "black": ((26, 26, 27), (26, 26, 27), (74, 74, 76), (28, 28, 29)),
    "ham": ((42, 44, 47), (69, 72, 76), (85, 88, 92), (27, 28, 30)),
    "bakelite": ((14, 14, 14), (14, 14, 14), (70, 70, 70), (8, 8, 8)),
    "pot": ((17, 17, 17), (44, 44, 44), (60, 60, 60), (14, 14, 14)),
}


def knob(im, cx, cy, r, style):
    ring_a, ring_b, cap_hi, cap_lo = KNOBS[style]
    S = r * 2 + 8
    W = u(S)
    yy, xx = np.mgrid[0:W, 0:W].astype(np.float32) / K
    c = S / 2
    dx, dy = xx - c, yy - c
    dist = np.hypot(dx, dy)
    ang = (np.degrees(np.arctan2(dx, -dy)) + 360) % 360
    knurl = ((ang // 6) % 2 == 0)
    ring = np.where(knurl[..., None], np.array(ring_a, np.float32), np.array(ring_b, np.float32))
    capr = r - max(4, r * 0.28)
    t = np.clip(np.hypot(xx - (c - 0.25 * capr), yy - (c - 0.3 * capr)) / (capr * 1.5), 0, 1)[..., None]
    cap = np.array(cap_hi, np.float32) * (1 - t) + np.array(cap_lo, np.float32) * t
    rgb = np.where((dist <= capr)[..., None], cap, ring)
    a = np.clip((r - dist) * K + 0.5, 0, 1) * 255
    k = Image.fromarray(np.concatenate([rgb, a[..., None]], axis=2).astype(np.uint8), "RGBA")
    kd = ImageDraw.Draw(k)
    kd.ellipse([u(c - r), u(c - r), u(c + r) - 1, u(c + r) - 1], outline=(5, 5, 5, 255), width=max(1, u(1)))
    kd.ellipse([u(c - capr), u(c - capr), u(c + capr) - 1, u(c + capr) - 1], outline=(10, 10, 10, 255), width=1)
    sh = Image.new("RGBA", k.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse([u(c - r + 2), u(c - r + 3), u(c + r + 2), u(c + r + 3)], fill=(0, 0, 0, 140))
    im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(0.8)), (u(cx - c), u(cy - c)))
    im.alpha_composite(k, (u(cx - c), u(cy - c)))


BUTTONS = {
    "pt": ("#3a3c40", "#232528", "#55585d", "#c7cbd0"),
    "vt": ("#3b3b3e", "#333336", "#5a5a5e", "#d6d6d8"),
    "ham": ("#3b3e42", "#26282b", "#5a5d61", "#d0d4d8"),
    "army": ("#2f3320", "#23261a", "#4a4f33", "#e8e6d4"),
    "tact": ("#1a1a1a", "#0e0e0e", "#3a3a3a", "#f2f2f2"),
}


def glyph(d, kind, cx, cy, s, fg):
    """small symbols the font lacks: eject, play/stop, up and down triangles"""
    c = hexc(fg)
    if kind == "eject":
        d.polygon([(u(cx - s), u(cy + 0.5)), (u(cx + s), u(cy + 0.5)), (u(cx), u(cy - s))], fill=c)
        d.rectangle([u(cx - s), u(cy + 2), u(cx + s), u(cy + 3.4)], fill=c)
    elif kind == "playstop":
        d.polygon([(u(cx - s - 6), u(cy - s)), (u(cx - s - 6), u(cy + s)), (u(cx - 6 + s * 0.6), u(cy))], fill=c)
        text(d, cx, cy + 0.5, "/", s * 2.4, fg, anchor="mm")
        d.rectangle([u(cx + 4), u(cy - s * 0.85), u(cx + 4 + s * 1.7), u(cy + s * 0.85)], fill=c)
    elif kind in ("up", "down"):
        sgn = -1 if kind == "up" else 1
        d.polygon([(u(cx - s), u(cy - sgn * s * 0.6)), (u(cx + s), u(cy - sgn * s * 0.6)), (u(cx), u(cy + sgn * s * 0.8))], fill=c)


def button(im, x, y, w, h, label, style, size=9):
    top, bot, hi, fg = BUTTONS[style]
    d = ImageDraw.Draw(im)
    b = Image.new("RGBA", (u(w), u(h)), (0, 0, 0, 0))
    t = np.linspace(0, 1, u(h), dtype=np.float32)[:, None, None]
    rgb = np.array(hexc(top)[:3], np.float32) * (1 - t) + np.array(hexc(bot)[:3], np.float32) * t
    rgb = np.repeat(rgb, u(w), axis=1)
    b = Image.fromarray(np.concatenate([rgb, np.full((u(h), u(w), 1), 255, np.float32)], axis=2).astype(np.uint8), "RGBA")
    m = Image.new("L", b.size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, u(w) - 1, u(h) - 1], radius=u(2), fill=255)
    im.paste(b, (u(x), u(y)), m)
    d.rounded_rectangle([u(x) - 1, u(y) - 1, u(x + w), u(y + h)], radius=u(2), outline=(5, 5, 5, 255), width=1)
    d.line([(u(x + 2), u(y) + 1), (u(x + w - 2), u(y) + 1)], fill=hexc(hi), width=1)
    if label and label.startswith("@"):
        glyph(d, label[1:], x + w / 2, y + h / 2, 3.5, fg)
    elif label and label.startswith("CH") and label[2:] in ("+", "-"):
        text(d, x + w / 2 - 5, y + h / 2 + 0.5, "CH", size, fg, anchor="mm")
        glyph(d, "up" if label[2] == "+" else "down", x + w / 2 + 9, y + h / 2, 3, fg)
    elif label:
        text(d, x + w / 2, y + h / 2 + 0.5, label, size, fg, anchor="mm")


def glass(im, x, y, w, h, base, rim="#2c2f33", radius=2):
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([u(x) - 2, u(y) - 2, u(x + w) + 1, u(y + h) + 1], radius=u(radius) + 1, fill=hexc(rim))
    d.rounded_rectangle([u(x), u(y), u(x + w) - 1, u(y + h) - 1], radius=u(radius), fill=hexc(base))
    sh = Image.new("RGBA", (u(w), u(h)), (0, 0, 0, 0))
    ImageDraw.Draw(sh).rectangle([0, 0, u(w), u(3)], fill=(0, 0, 0, 120))
    ImageDraw.Draw(sh).rectangle([0, 0, u(2), u(h)], fill=(0, 0, 0, 90))
    im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(1.5)), (u(x), u(y)))


def screw(im, x, y, r=3.5):
    S = u(r * 2 + 2)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32) / K
    c = r + 1
    dist = np.hypot(xx - c, yy - c)
    t = np.clip(np.hypot(xx - c * 0.7, yy - c * 0.7) / (r * 1.4), 0, 1)
    v = 150 + (55 - 150) * t
    a = np.clip((r - dist) * K + 0.5, 0, 1) * 255
    s = Image.fromarray(np.stack([v, v, v, a], -1).astype(np.uint8), "RGBA")
    sd = ImageDraw.Draw(s)
    sd.ellipse([u(1), u(1), u(1 + 2 * r) - 1, u(1 + 2 * r) - 1], outline=(10, 10, 10, 255), width=1)
    ang = math.radians(35)
    sd.line([(u(c) - math.cos(ang) * u(r - 1), u(c) - math.sin(ang) * u(r - 1)), (u(c) + math.cos(ang) * u(r - 1), u(c) + math.sin(ang) * u(r - 1))], fill=(21, 21, 21, 255), width=u(1))
    im.alpha_composite(s, (u(x - r - 1), u(y - r - 1)))


def pcb(im, w, h, seed):
    """a bare circuit board: solder-mask green, copper traces, a silkscreen edge"""
    d = body(im, w, h, "#1f3d24", "#173019", noise=0.25, radius=3, edge="#0a140b", hi="#2f5a36", seed=seed)
    rng = np.random.default_rng(seed)
    for _ in range(22):
        x0, y0 = rng.uniform(10, w - 10), rng.uniform(10, h - 10)
        x1 = x0 + rng.choice([-1, 1]) * rng.uniform(20, 90)
        y1 = y0 + rng.choice([-1, 1]) * rng.uniform(4, 30)
        x1, y1 = min(max(x1, 8), w - 8), min(max(y1, 8), h - 8)
        mid = (x1, y0)
        d.line([(u(x0), u(y0)), (u(mid[0]), u(mid[1])), (u(x1), u(y1))], fill=(176, 120, 52, 150), width=u(1.2))
        d.ellipse([u(x0 - 1.6), u(y0 - 1.6), u(x0 + 1.6), u(y0 + 1.6)], fill=(205, 170, 90, 255))
    d.rectangle([u(3), u(3), u(w - 3) - 1, u(h - 3) - 1], outline=(220, 228, 210, 70), width=1)
    for sx, sy in ((7, 7), (w - 7, 7), (7, h - 7), (w - 7, h - 7)):
        d.ellipse([u(sx - 3.5), u(sy - 3.5), u(sx + 3.5), u(sy + 3.5)], fill=(190, 190, 185, 255), outline=(40, 40, 40, 255))
        d.ellipse([u(sx - 1.5), u(sy - 1.5), u(sx + 1.5), u(sy + 1.5)], fill=(30, 30, 30, 255))
    return d


def parts(im, items):
    """a few components on a bare board: resistors, a capacitor, a chip, wires"""
    d = ImageDraw.Draw(im)
    for kind, x, y, *rest in items:
        if kind == "res":
            d.line([(u(x - 7), u(y)), (u(x + 7), u(y))], fill=(170, 170, 170, 255), width=u(1))
            d.rounded_rectangle([u(x - 4.5), u(y - 2), u(x + 4.5), u(y + 2)], radius=u(1.5), fill=(214, 196, 150, 255), outline=(60, 50, 30, 255))
            for i, c in enumerate(rest[0]):
                d.line([(u(x - 2.5 + i * 2), u(y - 2)), (u(x - 2.5 + i * 2), u(y + 2))], fill=hexc(c), width=u(1))
        elif kind == "cap":
            r = rest[0]
            d.ellipse([u(x - r), u(y - r), u(x + r), u(y + r)], fill=(40, 70, 140, 255), outline=(10, 20, 40, 255), width=u(1))
            d.ellipse([u(x - r * 0.45), u(y - r * 0.45), u(x + r * 0.45), u(y + r * 0.45)], outline=(150, 170, 200, 255), width=u(0.6))
        elif kind == "chip":
            w, h, lab = rest
            for i in range(int(w // 3)):
                d.line([(u(x + 1.5 + i * 3), u(y - 1.5)), (u(x + 1.5 + i * 3), u(y + h + 1.5))], fill=(180, 180, 175, 255), width=u(0.8))
            d.rectangle([u(x), u(y), u(x + w), u(y + h)], fill=(22, 22, 22, 255), outline=(5, 5, 5, 255))
            text(d, x + w / 2, y + h / 2 + 0.3, lab, 5, "#b9b9b4", anchor="mm")
        elif kind == "wire":
            pts, col = rest
            d.line([(u(px), u(py)) for px, py in [(x, y)] + pts], fill=hexc(col), width=u(1.6), joint="curve")


def tact(im, x, y, s, label):
    d = ImageDraw.Draw(im)
    d.rectangle([u(x), u(y), u(x + s) - 1, u(y + s) - 1], fill=(170, 170, 165, 255), outline=(40, 40, 40, 255))
    c = s / 2
    d.ellipse([u(x + c - s * 0.32), u(y + c - s * 0.32), u(x + c + s * 0.32), u(y + c + s * 0.32)], fill=(20, 20, 20, 255))
    if label:
        text(d, x + c, y + s + 4.5, label, 6.5, "#f2f2f2", f="FiraSansCondensed-MediumItalic.ttf", anchor="mm")


# ---------------------------------------------------------------------------
# the faces up close
# ---------------------------------------------------------------------------
def face_premium():
    w, h = 480, 150
    im = canvas(w, h)
    d = body(im, w, h, "#202124", "#151618", hi="#3c3f44")
    for yy in (4, h - 4):
        d.line([(u(10), u(yy)), (u(w - 10), u(yy))], fill=(190, 194, 199, 200), width=1)
    text(d, 16, 9, "PREMIUM TECHNOLOGIES", 8, "#9fa3a8", spacing=1.5)
    text(d, w - 16, 9, "CD RECEIVER", 8, "#9fa3a8", spacing=1.5, anchor="ra")
    knob(im, 46, 60, 24, "silver"); knob(im, 434, 60, 24, "silver")
    text(d, 46, 92, "VOL·PUSH ON", 8, "#9fa3a8", spacing=1, anchor="ma")
    text(d, 434, 92, "TUNE", 8, "#9fa3a8", spacing=1.5, anchor="ma")
    glass(im, 96, 28, 290, 58, "#05080a")
    d.rounded_rectangle([u(120), u(93), u(350), u(101)], radius=u(4), fill=(2, 2, 3, 255), outline=(74, 77, 82, 255))
    buttons = []
    button(im, 356, 89, 30, 17, "@eject", "pt"); buttons.append(("eject", 356, 89, 30, 17))
    for i in range(6):
        x = 96 + i * 25
        button(im, x, 110, 22, 17, str(i + 1), "pt"); buttons.append(("p%d" % (i + 1), x, 110, 22, 17))
    for bid, lab, x, bw in (("scan", "SCAN", 252, 37), ("seek", "SEEK", 295, 37), ("mute", "MUTE", 338, 45)):
        button(im, x, 110, bw, 17, lab, "pt"); buttons.append((bid, x, 110, bw, 17))
    button(im, 410, 110, 48, 17, "@playstop", "pt"); buttons.append(("play", 410, 110, 48, 17))
    text(d, 96, 133, "PRESET · HOLD TO STORE", 8, "#9fa3a8", spacing=1.2)
    text(d, 252, 133, "COMPACT DISC", 8, "#9fa3a8", spacing=1.2)
    return im, {"w": w, "h": h, "display": {"x": 96, "y": 28, "w": 290, "h": 58, "kind": "vfd", "c": "#62E6FF"},
                "vol": {"cx": 46, "cy": 60, "r": 24}, "tune": {"cx": 434, "cy": 60, "r": 24},
                "slot": {"x": 120, "y": 93, "w": 230, "h": 8}, "buttons": buttons}


def face_valutech():
    w, h = 440, 122
    im = canvas(w, h)
    d = body(im, w, h, "#2e2e30", "#262628", noise=0.35, radius=3, hi="#48484b", seed=7)
    text(d, 16, 6, "ValuTech", 15, "#c9cbce", f="FiraSansCondensed-SemiBoldItalic.ttf")
    text(d, 16, 28, "FM STEREO", 8, "#8b8b8f", spacing=1.5)
    knob(im, 43, 73, 19, "black"); knob(im, 399, 73, 19, "black")
    text(d, 43, 98, "VOL·ON", 8, "#8b8b8f", spacing=1, anchor="ma")
    text(d, 399, 98, "TUNE", 8, "#8b8b8f", spacing=1.5, anchor="ma")
    glass(im, 150, 12, 150, 38, "#1a1405", rim="#3a3a3c")
    buttons = []
    for bid, lab, y in (("mute", "MUTE", 22), ("seek", "SEEK", 44)):
        button(im, 310, y, 40, 17, lab, "vt"); buttons.append((bid, 310, y, 40, 17))
    for i in range(6):
        x = 92 + i * 46
        button(im, x, 62, 40, 17, str(i + 1), "vt"); buttons.append(("p%d" % (i + 1), x, 62, 40, 17))
    # the masking tape (names written live)
    tape = Image.new("RGBA", (u(278), u(15)), (232, 220, 179, 255))   # at (88, 84)
    tm = Image.new("L", tape.size, 0)
    ImageDraw.Draw(tm).polygon([(0, u(1)), (u(8), 0), (u(270), u(1.4)), (u(278), 0), (u(277), u(13.6)), (u(268), u(15)), (u(10), u(13.4)), (u(2), u(15))], fill=255)
    tshadow = Image.new("RGBA", (u(278), u(15)), (0, 0, 0, 0)); tshadow.putalpha(tm.point(lambda v: v * 0.4))
    im.alpha_composite(tshadow.filter(ImageFilter.GaussianBlur(1)), (u(88), u(84) + 2))
    im.paste(tape, (u(88), u(84)), tm)
    text(d, 150, 104, "HOLD TO STORE", 8, "#8b8b8f", spacing=1.5)
    return im, {"w": w, "h": h, "display": {"x": 150, "y": 12, "w": 150, "h": 38, "kind": "amber", "c": "#FFB22E"},
                "vol": {"cx": 43, "cy": 73, "r": 19}, "tune": {"cx": 399, "cy": 73, "r": 19},
                "tape": {"x": 88, "y": 84, "w": 278, "h": 15, "pitch": 46, "first": 92}, "buttons": buttons}


def face_makeshift():
    w, h = 440, 128
    im = canvas(w, h)
    d = pcb(im, w, h, 11)
    parts(im, [("res", 112, 96, ["#8b4513", "#000000", "#ff0000"]), ("res", 112, 106, ["#ff0000", "#ff0000", "#000000"]),
               ("cap", 330, 100, 6), ("cap", 348, 104, 4), ("chip", 128, 86, 24, 10, "LM386"),
               ("wire", 20, 64, [(60, 54), (100, 70)], "#b8261c"), ("wire", 22, 70, [(64, 62), (104, 76)], "#202020"),
               ("wire", 420, 30, [(380, 26), (330, 40)], "#c8a018")])
    text(d, 14, 14, "MAKESHIFT · WIRES LIVE", 7, "#e6ead8", spacing=1.2)
    knob(im, 52, 92, 15, "pot"); knob(im, 392, 92, 15, "pot")
    text(d, 52, 112, "VOL", 6.5, "#f2f2f2", f="FiraSansCondensed-MediumItalic.ttf", anchor="ma")
    text(d, 392, 112, "TUNE", 6.5, "#f2f2f2", f="FiraSansCondensed-MediumItalic.ttf", anchor="ma")
    # the 16 x 2 character LCD module on its little board
    d.rectangle([u(140), u(14), u(300), u(64)], fill=(16, 40, 22, 255), outline=(8, 20, 10, 255))
    glass(im, 148, 22, 144, 34, "#a8c460", rim="#20301e", radius=1)
    buttons = []
    for i in range(6):
        x = 158 + i * 22
        tact(im, x, 72, 12, str(i + 1)); buttons.append(("p%d" % (i + 1), x, 72, 12, 12))
    tact(im, 310, 26, 14, "seek"); buttons.append(("seek", 310, 26, 14, 14))
    # the power rocker
    d.rounded_rectangle([u(22), u(26), u(46), u(42)], radius=u(2), fill=(150, 26, 20, 255), outline=(30, 5, 5, 255))
    d.line([(u(24), u(34)), (u(44), u(34))], fill=(90, 14, 10, 255), width=u(1))
    buttons.append(("pwr", 22, 26, 24, 16))
    text(d, 34, 47, "pwr", 6.5, "#f2f2f2", f="FiraSansCondensed-MediumItalic.ttf", anchor="ma")
    return im, {"w": w, "h": h, "display": {"x": 148, "y": 22, "w": 144, "h": 34, "kind": "char", "c": "#1F2A0C"},
                "vol": {"cx": 52, "cy": 92, "r": 15}, "tune": {"cx": 392, "cy": 92, "r": 15}, "buttons": buttons}


def face_ham():
    w, h = 500, 140
    im = canvas(w, h)
    d = body(im, w, h, "#25272a", "#181a1c", radius=3, hi="#44474b")
    fins = Image.new("RGBA", (u(36), u(120)), (0, 0, 0, 0))
    fd = ImageDraw.Draw(fins)
    for i in range(0, u(36), u(6)):
        fd.rectangle([i, 0, i + u(3) - 1, u(120)], fill=(13, 14, 15, 255))
        fd.rectangle([i + u(3), 0, i + u(6) - 1, u(120)], fill=(44, 47, 51, 255))
    im.alpha_composite(fins, (u(8), u(10)))
    text(d, 56, 6, "PREMIUM TECHNOLOGIES  ·  TWO-WAY  ·  10-500 MHz", 8, "#a9adb2", spacing=1.2)
    knob(im, 82, 60, 22, "ham"); knob(im, 424, 54, 32, "ham")
    text(d, 82, 90, "VOL·PWR", 8, "#a9adb2", spacing=1, anchor="ma")
    text(d, 424, 92, "DIAL", 8, "#a9adb2", spacing=1.5, anchor="ma")
    glass(im, 120, 24, 250, 62, "#a9b58f", rim="#0c0d0e")
    buttons = []
    for bid, lab, x in (("chup", "CH+", 120), ("chdn", "CH-", 168), ("mem", "MEM", 216), ("mic", "MIC", 264), ("mute", "MUTE", 312)):
        button(im, x, 96, 44, 17, lab, "ham"); buttons.append((bid, x, 96, 44, 17))
    text(d, 120, 121, "HOLD MEM TO NAME", 8, "#a9adb2", spacing=1.2)
    d.ellipse([u(283), u(118), u(289), u(124)], fill=(42, 18, 18, 255), outline=(5, 5, 5, 255))
    d.rounded_rectangle([u(388), u(112), u(472), u(124)], radius=u(1), fill=(190, 194, 198, 255), outline=(60, 60, 60, 255))
    return im, {"w": w, "h": h, "display": {"x": 120, "y": 24, "w": 250, "h": 62, "kind": "lcd", "c": "#16190F"},
                "vol": {"cx": 82, "cy": 60, "r": 22}, "tune": {"cx": 424, "cy": 54, "r": 32}, "buttons": buttons,
                "micLed": {"x": 283, "y": 118, "sz": 6}, "range": {"x": 430, "y": 118, "c": "#1A1A1A"}}


def face_army():
    w, h = 500, 150
    im = canvas(w, h)
    d = body(im, w, h, "#525a2a", "#454c22", noise=0.45, radius=3, edge="#15180a", hi="#6a7338", seed=23)
    for sx, sy in ((8, 8), (w - 8, 8), (8, h - 8), (w - 8, h - 8)):
        screw(im, sx, sy)
    text(d, 24, 8, "US ARMY COMM.", 12, "#ecead8", spacing=2.5)
    text(d, 24, 26, "RADIO SET  ·  TWO-WAY  ·  10-500 MHz", 7, "#d8d6c0", spacing=1.2)
    knob(im, 66, 84, 26, "bakelite"); knob(im, 432, 80, 32, "bakelite")
    text(d, 66, 116, "VOL·PWR", 8, "#ecead8", spacing=1.2, anchor="ma")
    text(d, 432, 118, "FREQ", 8, "#ecead8", spacing=1.5, anchor="ma")
    glass(im, 120, 42, 250, 46, "#140405", rim="#15180a")
    buttons = []
    for bid, lab, x in (("chup", "CH+", 120), ("chdn", "CH-", 168), ("mem", "MEM", 216), ("mic", "MIC", 264), ("mute", "MUTE", 312)):
        button(im, x, 100, 44, 17, lab, "army"); buttons.append((bid, x, 100, 44, 17))
    d.ellipse([u(283), u(124), u(289), u(130)], fill=(42, 18, 18, 255), outline=(5, 5, 5, 255))
    text(d, 120, 128, "HOLD MEM TO NAME", 7, "#d8d6c0", spacing=1.2)
    d.rectangle([u(384), u(128), u(480), u(140)], fill=(30, 33, 16, 255), outline=(15, 18, 8, 255))
    return im, {"w": w, "h": h, "display": {"x": 120, "y": 42, "w": 250, "h": 46, "kind": "led", "c": "#FF3A24"},
                "vol": {"cx": 66, "cy": 84, "r": 26}, "tune": {"cx": 432, "cy": 80, "r": 32}, "buttons": buttons,
                "micLed": {"x": 283, "y": 124, "sz": 6}, "range": {"x": 432, "y": 134, "c": "#ECEAD8"}}


def face_hammake():
    w, h = 500, 138
    im = canvas(w, h)
    d = pcb(im, w, h, 31)
    parts(im, [("chip", 330, 96, 30, 12, "NE602"), ("chip", 372, 98, 24, 10, "LM386"), ("res", 120, 108, ["#8b4513", "#000000", "#ff8c00"]),
               ("cap", 112, 52, 6), ("cap", 128, 58, 4), ("wire", 20, 70, [(60, 60), (110, 80)], "#b8261c"),
               ("wire", 24, 76, [(66, 68), (112, 88)], "#202020"), ("wire", 480, 40, [(440, 34), (400, 52)], "#c8a018")])
    text(d, 14, 14, "HAM TX/RX", 7, "#e6ead8", spacing=1.2)
    text(d, 340, 14, "KEEP DRY", 7, "#e6ead8", spacing=1.2)
    knob(im, 56, 98, 16, "pot"); knob(im, 444, 92, 22, "pot")
    text(d, 56, 119, "VOL", 6.5, "#f2f2f2", f="FiraSansCondensed-MediumItalic.ttf", anchor="ma")
    text(d, 444, 119, "DIAL", 6.5, "#f2f2f2", f="FiraSansCondensed-MediumItalic.ttf", anchor="ma")
    d.rectangle([u(150), u(14), u(330), u(66)], fill=(16, 40, 22, 255), outline=(8, 20, 10, 255))
    glass(im, 158, 22, 164, 36, "#a8c460", rim="#20301e", radius=1)
    buttons = []
    for i, (bid, lab) in enumerate((("chup", "ch+"), ("chdn", "ch-"), ("mem", "mem"), ("mic", "mic"), ("mute", "mute"))):
        x = 162 + i * 30
        tact(im, x, 76, 13, lab); buttons.append((bid, x, 76, 13, 13))
    d.rounded_rectangle([u(22), u(30), u(46), u(46)], radius=u(2), fill=(150, 26, 20, 255), outline=(30, 5, 5, 255))
    d.line([(u(24), u(38)), (u(44), u(38))], fill=(90, 14, 10, 255), width=u(1))
    buttons.append(("pwr", 22, 30, 24, 16))
    text(d, 34, 51, "pwr", 6.5, "#f2f2f2", f="FiraSansCondensed-MediumItalic.ttf", anchor="ma")
    d.ellipse([u(312), u(78), u(318), u(84)], fill=(42, 18, 18, 255), outline=(5, 5, 5, 255))
    return im, {"w": w, "h": h, "display": {"x": 158, "y": 22, "w": 164, "h": 36, "kind": "char", "c": "#1F2A0C"},
                "vol": {"cx": 56, "cy": 98, "r": 16}, "tune": {"cx": 444, "cy": 92, "r": 22}, "buttons": buttons,
                "micLed": {"x": 312, "y": 78, "sz": 6}, "range": {"x": 250, "y": 124, "c": "#E6EAD8"}}


FACES = {"premium": face_premium, "valutech": face_valutech, "makeshift": face_makeshift,
         "ham": face_ham, "army": face_army, "hammake": face_hammake}

# ---------------------------------------------------------------------------
# the small faces for the dash's head-unit slot
# ---------------------------------------------------------------------------
DASH_STYLE = {
    # body top, bottom, button style, display kind, display base, display colour, knob style
    "premium": ("#202124", "#151618", "pt", "vfd", "#05080a", "#62E6FF", "silver"),
    "valutech": ("#2e2e30", "#262628", "vt", "amber", "#1a1405", "#FFB22E", "black"),
    "makeshift": None,
    "ham": ("#25272a", "#181a1c", "ham", "lcd", "#a9b58f", "#16190F", "ham"),
    "army": ("#525a2a", "#454c22", "army", "led", "#140405", "#FF3A24", "bakelite"),
    "hammake": None,
}
HAM_KINDS = ("ham", "army", "hammake")


def dash_head(kind, h):
    w = DASH_W
    im = canvas(w, h, shadow=False)
    st = DASH_STYLE[kind]
    if st is None:
        pcb(im, w, h, 41 + h)
        top, bot, bstyle, dkind, dbase, dcol, kstyle = None, None, "tact", "char", "#a8c460", "#1F2A0C", "pot"
    else:
        top, bot, bstyle, dkind, dbase, dcol, kstyle = st
        body(im, w, h, top, bot, noise=0.35 if kind in ("valutech", "army") else 0.0, radius=2,
             edge="#000000" if kind != "army" else "#15180a", hi=None, seed=h)
    btnH = max(8, min(11, round(h * 0.2)))
    btnY = h - btnH - 3
    dispY, dispH = 4, max(12, btnY - 3 - 4)
    r = max(7, min(12, h / 2 - 6))
    vol = {"cx": 26, "cy": round(h / 2), "r": r}
    tune = {"cx": w - 26, "cy": round(h / 2), "r": r}
    knob(im, vol["cx"], vol["cy"], r, kstyle); knob(im, tune["cx"], tune["cy"], r, kstyle)
    glass(im, 52, dispY, 148, dispH, dbase, rim="#2c2f33" if st else "#20301e", radius=1)
    buttons = []
    if kind in HAM_KINDS:
        for i, (bid, lab) in enumerate((("chdn", "CH-"), ("chup", "CH+"), ("mic", "MIC"))):
            x = 52 + i * 51
            if bstyle == "tact":
                tact(im, x + 18, btnY, btnH, None)
            else:
                button(im, x, btnY, 46, btnH, lab, bstyle, size=max(4.5, btnH * 0.55))
            buttons.append((bid, x, btnY, 46, btnH))
    else:
        for i in range(6):
            x = 52 + i * 25
            if bstyle == "tact":
                tact(im, x + 5, btnY, btnH, None)
            else:
                button(im, x, btnY, 22, btnH, str(i + 1), bstyle, size=max(4.5, btnH * 0.6))
            buttons.append(("preset%d" % (i + 1), x, btnY, 22, btnH))
    return im, {"display": {"x": 52, "y": dispY, "w": 148, "h": dispH, "kind": dkind, "c": dcol}, "vol": vol, "tune": tune, "buttons": buttons}


# ---------------------------------------------------------------------------
def lua_value(v, ind=""):
    if isinstance(v, dict):
        keys = sorted(v.keys(), key=lambda k: (isinstance(k, int), str(k)))
        out = ["{"]
        for k in keys:
            kk = "[%d]" % k if isinstance(k, int) else k
            out.append(ind + "  %s = %s," % (kk, lua_value(v[k], ind + "  ")))
        out.append(ind + "}")
        return "\n".join(out)
    if isinstance(v, (list, tuple)):
        if v and isinstance(v[0], tuple):   # buttons: (id, x, y, w, h)
            return "{ " + ", ".join('{ id = "%s", x = %s, y = %s, w = %s, h = %s }' % b for b in v) + " }"
        return "{ " + ", ".join(lua_value(x, ind) for x in v) + " }"
    if isinstance(v, str):
        return '"%s"' % v
    if isinstance(v, float):
        return ("%.2f" % v).rstrip("0").rstrip(".")
    return str(v)


def main():
    os.makedirs(OUT, exist_ok=True)
    anchors = {"shadow": SH, "faces": {}, "dash": {}}
    for kind, fn in FACES.items():
        im, a = fn()
        im.save(os.path.join(OUT, "radio_%s.png" % kind), optimize=True)
        anchors["faces"][kind] = a
        anchors["dash"][kind] = {}
        for h in DASH_HEIGHTS:
            dim, da = dash_head(kind, h)
            dim.save(os.path.join(OUT, "dhead_%s_%d.png" % (kind, h)), optimize=True)
            anchors["dash"][kind][h] = da
    lines = ["-- GENERATED by ZeDUI/tools/plates/bake_radio_plates.py - do not edit.",
             "-- The car radios: each fitted radio's face up close (faces.<kind>, the prop above the",
             "-- dash) and small in the dash console's head-unit slot (dash.<kind>[height]); display,",
             "-- knobs, buttons and lamps in plate units (1 unit = 1 design px; the PNGs are 2 px per unit).",
             "ZeD = ZeD or {}",
             "ZeD.RadioPlates = " + lua_value(anchors),
             "return ZeD.RadioPlates", ""]
    open(OUT_LUA, "w", encoding="utf-8", newline="\n").write("\n".join(lines))
    print("baked", len(FACES), "faces and", len(FACES) * len(DASH_HEIGHTS), "dash heads ->", OUT_LUA)


if __name__ == "__main__":
    main()
