"""
Bake the siren controller prop (ZeD-UI, Oct 15 2026; mockup zed_seats_lightbar_v1.html,
approved: "lightbar is cool, better than the plain version").

The dash's own siren controller brought up close: a crinkle-black faceplate,
four screws, the stencilled header between two rules, the LIGHTS and SIREN
labels, the tick marks around each switch and the dark pilot-lamp sockets.
What moves is baked apart and drawn by the game over the faceplate:

  siren_plate.png  the faceplate (440 x 150 units + 4 for its drop shadow)
  siren_knob.png   one rotary knob (knurled ring + cap, its own shadow), 56 x 56
  siren_led.png    a lit pilot lamp (white, tinted blue / amber), 8 x 8
  siren_glow.png   the lamp's glow (white radial falloff), 28 x 28

All at 2 px per unit (the dash plates' density). The legends (OFF 1 2 3,
STANDBY YELP WAIL ALARM), the pointers and the lamps are drawn live. Anchors
go to 42/media/lua/client/ZeD/SirenPlate.lua (ZeD.SirenPlate).

Usage:  py ZeDUI/tools/plates/bake_siren_plate.py
"""
import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
OUT = os.path.join(ROOT, "42", "media", "textures", "ZeD", "dash")
OUT_LUA = os.path.join(ROOT, "42", "media", "lua", "client", "ZeD", "SirenPlate.lua")
FONTS = os.path.join(os.environ.get("LOCALAPPDATA", ""), "Microsoft", "Windows", "Fonts")
MONO_BOLD = os.path.join(FONTS, "FiraMono-Bold.ttf")
K = 2                      # px per unit
W, H = 440, 150            # the faceplate
SH = 4                     # room for the drop shadow
GROUPS = [                 # x of each switch group, its label, knob centre (group-local), lamp colour
    {"id": "lights", "x": 12, "label": "LIGHTS", "led": "#5AA0FF"},
    {"id": "siren", "x": 222, "label": "SIREN", "led": "#FFB347"},
]
GY, GW, GH = 28, 206, 112  # group box
KX, KY = 122, 72           # knob centre in the group
KNOB_R = 25
LEG_R, TICK_R0, TICK_R1 = 52, 30, 35
ANGLES = [-60, -20, 20, 60]


def hexc(s, a=255):
    s = s.lstrip("#")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), a)


def u(v):
    return int(round(v * K))


def spaced_text(draw, x, y, text, font, fill, spacing):
    """draw text letter by letter with extra spacing (units); returns the width in px"""
    cx = x
    for ch in text:
        draw.text((cx, y), ch, font=font, fill=fill)
        cx += draw.textlength(ch, font=font) + u(spacing)
    return cx - x - u(spacing)


def text_width(draw, text, font, spacing):
    return sum(draw.textlength(ch, font=font) for ch in text) + u(spacing) * (len(text) - 1)


def plate():
    im = Image.new("RGBA", (u(W + SH), u(H + SH)), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # drop shadow (3, 3) at .45
    sh = Image.new("RGBA", im.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle([u(3), u(3), u(3 + W) - 1, u(3 + H) - 1], radius=u(3), fill=(0, 0, 0, 115))
    im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(1)))
    # faceplate: crinkle black (fine noise over #1d1e1f)
    face = np.zeros((u(H), u(W), 4), dtype=np.float32)
    rng = np.random.default_rng(1993)
    noise = rng.normal(0, 1, (u(H), u(W))).astype(np.float32)
    noise = np.asarray(Image.fromarray(((noise * 40) + 128).clip(0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.7)), dtype=np.float32) - 128
    base = np.array(hexc("#1d1e1f")[:3], dtype=np.float32)
    for i in range(3):
        face[..., i] = base[i] + noise * 0.55
    face[..., 3] = 255
    face_im = Image.fromarray(face.clip(0, 255).astype(np.uint8), "RGBA")
    mask = Image.new("L", face_im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, u(W) - 1, u(H) - 1], radius=u(3), fill=255)
    im.paste(face_im, (0, 0), mask)
    # edges: the black outline, the lit top, the dark bottom
    d.rounded_rectangle([0, 0, u(W) - 1, u(H) - 1], radius=u(3), outline=hexc("#000000"), width=u(1))
    d.line([(u(3), u(1)), (u(W - 3), u(1))], fill=hexc("#444444"), width=u(1))
    d.line([(u(3), u(H - 1.5)), (u(W - 3), u(H - 1.5))], fill=hexc("#0b0b0b"), width=u(2))
    # screws
    for sx, sy in ((6, 6), (426, 6), (6, 136), (426, 136)):
        cx, cy, r = sx + 4, sy + 4, 4
        disc = Image.new("RGBA", (u(10), u(10)), (0, 0, 0, 0))
        g = np.zeros((u(10), u(10), 4), dtype=np.float32)
        yy, xx = np.mgrid[0:u(10), 0:u(10)].astype(np.float32) / K
        dd = np.hypot(xx - 1 - r * 0.7, yy - 1 - r * 0.7) / (r * 1.4)
        lo, hi = np.array([58, 58, 58]), np.array([138, 138, 138])
        t = np.clip(dd, 0, 1)
        for i in range(3):
            g[..., i] = hi[i] + (lo[i] - hi[i]) * t
        inside = np.hypot(xx - 1 - r, yy - 1 - r) <= r
        g[..., 3] = inside * 255
        disc = Image.fromarray(g.astype(np.uint8), "RGBA")
        ImageDraw.Draw(disc).ellipse([u(1), u(1), u(1 + 2 * r) - 1, u(1 + 2 * r) - 1], outline=hexc("#0a0a0a"), width=1)
        a = math.radians(35)
        p0 = (u(1 + r) - math.cos(a) * u(r - 1), u(1 + r) - math.sin(a) * u(r - 1))
        p1 = (u(1 + r) + math.cos(a) * u(r - 1), u(1 + r) + math.sin(a) * u(r - 1))
        ImageDraw.Draw(disc).line([p0, p1], fill=hexc("#151515"), width=u(1))
        im.alpha_composite(disc, (u(cx - r - 1), u(cy - r - 1)))
    # header + rules
    head = ImageFont.truetype(MONO_BOLD, u(10))
    tw = text_width(d, "SIREN CONTROLLER", head, 4)
    asc, desc = head.getmetrics()
    spaced_text(d, (u(W) - tw) / 2, u(16) - (asc + desc) / 2 - u(0.5), "SIREN CONTROLLER", head, hexc("#bdbdbd"), 4)
    d.line([(u(22), u(16)), (u(140), u(16))], fill=hexc("#4a4a4a"), width=u(1))
    d.line([(u(300), u(16)), (u(418), u(16))], fill=hexc("#4a4a4a"), width=u(1))
    # the two switch groups: label, lamp socket, ticks
    lab = ImageFont.truetype(MONO_BOLD, u(10))
    for gp in GROUPS:
        gx = gp["x"]
        spaced_text(d, u(gx + 12), u(GY + 8), gp["label"], lab, hexc("#bdbdbd"), 2)
        lx, ly = gx + 12, GY + 26
        d.ellipse([u(lx - 1), u(ly - 1), u(lx + 9) - 1, u(ly + 9) - 1], fill=hexc("#0b0b0b"))
        d.ellipse([u(lx), u(ly), u(lx + 8) - 1, u(ly + 8) - 1], fill=hexc("#2b2b2b"))
        d.arc([u(lx), u(ly), u(lx + 8) - 1, u(ly + 8) - 1], 200, 340, fill=hexc("#101010"), width=u(1))
        kx, ky = gx + KX, GY + KY
        for a in ANGLES:
            r = math.radians(a)
            p0 = (u(kx + TICK_R0 * math.sin(r)), u(ky - TICK_R0 * math.cos(r)))
            p1 = (u(kx + TICK_R1 * math.sin(r)), u(ky - TICK_R1 * math.cos(r)))
            d.line([p0, p1], fill=hexc("#9a9a9a"), width=u(1))
    im.save(os.path.join(OUT, "siren_plate.png"), optimize=True)


def knob():
    S = 56
    im = Image.new("RGBA", (u(S), u(S)), (0, 0, 0, 0))
    c = 26                                   # knob centre in its box (units)
    sh = Image.new("RGBA", im.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse([u(c - KNOB_R + 2), u(c - KNOB_R + 3), u(c + KNOB_R + 2), u(c + KNOB_R + 3)], fill=(0, 0, 0, 150))
    im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(0.8)))
    yy, xx = np.mgrid[0:u(S), 0:u(S)].astype(np.float32) / K
    dx, dy = xx - c, yy - c
    dist = np.hypot(dx, dy)
    ang = (np.degrees(np.arctan2(dx, -dy)) + 360) % 360
    ring = np.where((ang // 5) % 2 == 0, 44, 76).astype(np.float32)          # knurl: #2c / #4c every 5 degrees
    cr = KNOB_R - 6                                                            # the cap, lit from the upper left
    cap_t = np.clip(np.hypot(xx - (c - 0.2 * cr), yy - (c - 0.3 * cr)) / (cr * 1.5), 0, 1)
    cap = 74 + (27 - 74) * cap_t                                               # #4a -> #1b
    rgb = np.where(dist <= KNOB_R - 6, cap, ring)
    a = (dist <= KNOB_R).astype(np.float32) * 255
    arr = np.stack([rgb, rgb, rgb, a], axis=-1).astype(np.uint8)
    body = Image.fromarray(arr, "RGBA")
    dd = ImageDraw.Draw(body)
    dd.ellipse([u(c - KNOB_R), u(c - KNOB_R), u(c + KNOB_R) - 1, u(c + KNOB_R) - 1], outline=hexc("#050505"), width=u(1))
    dd.ellipse([u(c - KNOB_R + 6), u(c - KNOB_R + 6), u(c + KNOB_R - 6) - 1, u(c + KNOB_R - 6) - 1], outline=hexc("#0a0a0a"), width=u(1))
    im.alpha_composite(body)
    im.save(os.path.join(OUT, "siren_knob.png"), optimize=True)
    return c


def led_and_glow():
    S = 8
    yy, xx = np.mgrid[0:u(S), 0:u(S)].astype(np.float32) / K
    dist = np.hypot(xx - S / 2, yy - S / 2)
    a = np.clip((S / 2 - dist) * K, 0, 1) * 255
    hl = np.clip(1 - np.hypot(xx - S * 0.38, yy - S * 0.32) / (S * 0.5), 0, 1)
    v = 200 + 55 * hl
    Image.fromarray(np.stack([v, v, v, a], axis=-1).astype(np.uint8), "RGBA").save(os.path.join(OUT, "siren_led.png"), optimize=True)
    G = 28
    yy, xx = np.mgrid[0:u(G), 0:u(G)].astype(np.float32) / K
    dist = np.hypot(xx - G / 2, yy - G / 2) / (G / 2)
    a = np.clip(1 - dist, 0, 1) ** 2 * 255
    w = np.full_like(a, 255)
    Image.fromarray(np.stack([w, w, w, a], axis=-1).astype(np.uint8), "RGBA").save(os.path.join(OUT, "siren_glow.png"), optimize=True)


def anchors(knob_c):
    lines = ["-- GENERATED by ZeDUI/tools/plates/bake_siren_plate.py - do not edit.",
             "-- The siren controller prop: faceplate size, the two switch groups (group box,",
             "-- label, lamp socket, knob centre), the positions' angles and radii; all in",
             "-- plate units (1 unit = 1 design px; the PNGs are 2 px per unit).",
             "ZeD = ZeD or {}",
             "ZeD.SirenPlate = {",
             "  w = %d, h = %d, shadow = %d," % (W, H, SH),
             "  angles = { %s }," % ", ".join(str(a) for a in ANGLES),
             "  legR = %d, knobR = %d, knobBox = 56, knobC = %d," % (LEG_R, KNOB_R, knob_c),
             "  groups = {"]
    for gp in GROUPS:
        gx = gp["x"]
        lines.append('    { id = "%s", x = %d, y = %d, w = %d, h = %d, kx = %d, ky = %d, led = { x = %d, y = %d, sz = 8, c = "%s" } },'
                     % (gp["id"], gx, GY, GW, GH, gx + KX, GY + KY, gx + 12, GY + 26, gp["led"]))
    lines += ["  },", "}", "return ZeD.SirenPlate", ""]
    open(OUT_LUA, "w", encoding="utf-8", newline="\n").write("\n".join(lines))


if __name__ == "__main__":
    plate()
    kc = knob()
    led_and_glow()
    anchors(kc)
    print("baked", [f for f in sorted(os.listdir(OUT)) if f.startswith("siren_")], "anchors", OUT_LUA)
