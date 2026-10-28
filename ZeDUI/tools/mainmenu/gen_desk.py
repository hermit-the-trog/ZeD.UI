#!/usr/bin/env python3
"""ZeD-UI main menu desk, v3: the lit night room. Draws the desk picture and the pieces ZeD_MainMenu.lua lays over it.

    python gen_desk.py --to OUT_FOLDER

Writes desk.png (480 x 270), desk_lampdim.png (the same room with the lamp dipped, for its flicker), lamp_dim.png
(the 42 x 36 lamp box cut from it, for the old contract), dial_clean.png (the boombox dial without its needle) and
desk_info.json (the colours the code paints: lights off, the needle, the margins), and prints those as Lua.

The palette is locked (palette_v3.json): the one the approved room was fitted to. Materials drawn since (FRESH) get
their own entries, so a redrawn object changes only its own pixels. --refit fits a fresh palette instead and writes
it to the output folder as palette.json; adopt it by copying it over palette_v3.json.

Contract with ZeD_MainMenu.lua (native pixels of desk.png):
  tube 120,30 240x180 · hard disk light 146,246 3x2 · floppy light 300,262 3x2 · dial 416,120 7x10 · needle 419,121 1x8
  lamp box 60,92 42x36 · power button 126,243 10x10 · desk edge row 184
"""
import os, sys, math
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from desk_engine import Scene, W, H, VPX, VPY, lin, srgb, hx

PAL = {
    # room
    "panel": "#6a4a2f", "panel_g": "#33231a", "panel_h": "#80603f",          # walnut paneling, groove, plank edge
    "desk": "#4b2b1b", "desk_g": "#331b10",                                  # solid walnut top, grain
    # hardware plastics
    "beige": "#dccfae", "beige_s": "#ab9e80", "beige_d": "#6f6650", "beige_h": "#f0e6cc",
    "glass": "#07090c", "glass_r": "#1b2430",
    "ink": "#121212", "black": "#1d1d1f", "dgray": "#38393c", "mgray": "#77797d", "lgray": "#b3b6ba", "chrome": "#d6d9dd",
    # lamp
    "lamp_metal": "#7c8288", "lamp_dark": "#34373b", "lamp_in": "#f2dfb2", "bulb": "#fff4d6",
    # can, floppy case, boxes
    "red": "#b5301d", "red_d": "#6e1a10", "label": "#efe9dc",
    "orange": "#f07818", "orange_d": "#8a3a10", "orange_ink": "#c04a10", "claim": "#f6efdc",   # the orange soda can
    "promo": "#6e2a0c", "claim_hi": "#ffd84a",
    "fruit": "#ffa526", "fruit_d": "#e2700e", "fruit_k": "#6a2208", "fruit_h": "#fff2b8",       # (Oct 28, was the cola)
    "corn": "#f2c230", "corn_l": "#ffe98a", "corn_d": "#b8860f", "leaf": "#4caa3c", "leaf_d": "#1f5c26", "sugar": "#fffaf0",
    "smoke": "#3a3b42", "disk": "#2c3f7d", "disk_l": "#d9d2bd",
    "box_blue": "#24408f", "box_purple": "#5c3c7d", "box_teal": "#2f7f7a",
    # paper, cork, posters
    "cork": "#b17d46", "cork_d": "#8a5c2e", "frame": "#6a4526",
    "paper": "#e8dcb6", "paper_d": "#c4b48c", "sticky": "#e6bf3c", "sticky_d": "#b7922a",
    "pq_purple": "#5a2c6c", "pq_gold": "#e2b834",
    "pz_green": "#2f5230", "pz_green2": "#4f7f46", "pz_dark": "#0e1710", "moon": "#e4e0cc", "pz_text": "#e8e2c8",
    "sky0": "#0b1626", "sky1": "#17304a", "star": "#e6e2cf", "car": "#c3c8ce", "car_d": "#7e848b", "road": "#4a4a4a",
    "dusk0": "#2a3f78", "dusk1": "#c8784e", "grass": "#5fa04a", "grass_d": "#3f7a34", "dirt": "#7a5232", "dirt_d": "#5a3a22",
    "floor": "#b88a58", "floor_d": "#8a6038", "wall_l": "#d8c6a6", "wall_r": "#c2ad8a", "wall_top": "#f0e6d0", "window": "#9cc7e6", "frame_w": "#f0e6d0",
    "blanket": "#3f6fb8", "blanket_d": "#2a4c86", "blanket_s": "#345e9e", "tv": "#2a2a2e", "tv_glow": "#7fb6e8",
    "zskin": "#8fbf6a", "zshirt": "#8a3a3a", "zpants": "#3a3f5a", "navy": "#121a36", "simz_g": "#8fe07a",
    "simz_bg": "#1d3d5e", "simz_grid": "#244a70", "simz_shadow": "#0c1a2c", "simz_gd": "#3a8f34",
    "hd_bg": "#2a1542", "hd_ray": "#35195a", "hd_g1": "#5e1f5a", "hd_g2": "#9c2c5e", "hd_g3": "#d8504a", "hd_g4": "#f08c46", "hd_g5": "#fbc66a",
    "hd_sil": "#120a16", "hd_rim": "#f7c46a", "hd_y1": "#fff0a8", "hd_y2": "#f8cf4e", "hd_y3": "#ee8a30", "hd_shadow": "#1a0a24", "hd_ext": "#8c2440",
    "amber": "#c98a2c", "trail_r": "#e4573f", "trail_a": "#e8a830",
    # boombox
    "bb": "#56595e", "bb_l": "#9ea3a9", "bb_d": "#2a2c30", "grille": "#1c1d20", "tuner": "#c9c2a4", "needle": "#c0341f",
    # emissive bits
    "led_g": "#4ad04a", "led_a": "#e8a830", "led_off_g": "#2b3d2b", "led_off_a": "#4a3412",
}

S = Scene(PAL)
DESK_Y, EDGE_Y = 184, 270
LOCK = os.path.join(os.path.dirname(os.path.abspath(__file__)), "palette_v3.json")
FRESH = ("orange", "orange_d", "orange_ink", "claim", "promo", "claim_hi", "fruit", "fruit_d", "fruit_k", "fruit_h",
         "corn", "corn_l", "corn_d", "leaf", "leaf_d", "sugar")    # materials drawn since the palette was locked
FRESH_SLOTS = 32                                    # the palette entries they share


def zdesk(x, y): return np.maximum(0.0, (y - DESK_Y) * 1.15)


def recede(x, y, k): return (x + (VPX - x) * k, y + (VPY - y) * k)


def box3d(x, y, w, h, k, face, side=None, top=None, z=0.0, depth=10.0, gloss=0.0, d=True):
    """frontal box; receding faces toward the VP by fraction k, with their real normals"""
    x2, y2 = x + w, y + h
    tl, tr, bl, br = recede(x, y, k), recede(x2, y, k), recede(x, y2, k), recede(x2, y2, k)
    if side:
        if x2 < VPX:
            with S.surf(n=(1, 0, 0), z=z - depth / 2, g=gloss, d=d): S.poly([(x2, y), tr, br, (x2, y2)], side)
        elif x > VPX:
            with S.surf(n=(-1, 0, 0), z=z - depth / 2, g=gloss, d=d): S.poly([(x, y), tl, bl, (x, y2)], side)
    if top:
        if y > VPY:
            with S.surf(n=(0, -1, 0), z=z - depth / 2, g=gloss, d=d): S.poly([(x, y), tl, tr, (x2, y)], top)
        elif y2 < VPY:
            with S.surf(n=(0, 1, 0), z=z - depth / 2, g=gloss, d=d): S.poly([(x, y2), bl, br, (x2, y2)], top)
    with S.surf(n=(0, 0, 1), z=z, g=gloss, d=d): S.rect(x, y, w, h, face)


def bevel_rect(x, y, w, h, c, z, r=2, g=0.15, nz=1.0):
    """a rounded-edge slab: the outer r pixels lean outward so they catch light from their side"""
    def nf(xs, ys):
        dl, dr, dt, db = xs - x, (x + w) - xs, ys - y, (y + h) - ys
        nx = np.where(dl < r, -(1 - dl / r), np.where(dr < r, (1 - dr / r), 0.0))
        ny = np.where(dt < r, -(1 - dt / r), np.where(db < r, (1 - db / r), 0.0))
        return np.stack([nx, ny, np.full_like(xs, nz)], 1)
    with S.surf(nf=nf, z=z, g=g): S.rect(x, y, w, h, c)


FONT = {"A": ["010", "101", "111", "101", "101"], "B": ["110", "101", "110", "101", "110"], "C": ["011", "100", "100", "100", "011"],
        "D": ["110", "101", "101", "101", "110"], "E": ["111", "100", "110", "100", "111"], "G": ["011", "100", "101", "101", "011"],
        "H": ["101", "101", "111", "101", "101"], "I": ["111", "010", "010", "010", "111"], "K": ["101", "101", "110", "101", "101"],
        "L": ["100", "100", "100", "100", "111"], "M": ["101", "111", "111", "101", "101"], "N": ["110", "101", "101", "101", "101"],
        "O": ["010", "101", "101", "101", "010"], "P": ["110", "101", "110", "100", "100"], "R": ["110", "101", "110", "101", "101"],
        "S": ["011", "100", "010", "001", "110"], "T": ["111", "010", "010", "010", "010"], "U": ["101", "101", "101", "101", "111"],
        "V": ["101", "101", "101", "101", "010"], "X": ["101", "101", "010", "101", "101"], "Y": ["101", "101", "010", "010", "010"],
        "Z": ["111", "001", "010", "100", "111"], "Q": ["010", "101", "101", "111", "011"], "J": ["111", "001", "001", "101", "010"],
        "F": ["111", "100", "110", "100", "100"], "W": ["101", "101", "101", "111", "101"], "'": ["010", "010", "000", "000", "000"],
        " ": ["000", "000", "000", "000", "000"], "1": ["010", "110", "010", "010", "111"], "2": ["111", "001", "111", "100", "111"],
        "3": ["111", "001", "011", "001", "111"], "9": ["111", "101", "111", "001", "111"], "0": ["111", "101", "101", "101", "111"],
        "&": ["010", "101", "010", "101", "011"]}


def text(x, y, s, c, scale=1, gap=1, space=None):
    cx = x
    with S.surf(d=False):
        for ch in s:
            if ch == " " and space is not None:
                cx += space * scale; continue
            for ry, row in enumerate(FONT.get(ch, FONT[" "])):
                for rx, b in enumerate(row):
                    if b == "1": S.rect(cx + rx * scale, y + ry * scale, scale, scale, c)
            cx += (3 + gap) * scale


def text_w(s, scale=1, gap=1, space=None):
    return sum((space if (ch == " " and space is not None) else 3 + gap) * scale for ch in s) - gap * scale


KY = ["........##..", "......#####.", "....#######.", "..##########", ".#########..", "##########.."]


def ky_mark(x, y, c):
    with S.surf(d=False):
        for ry, row in enumerate(KY):
            for rx, b in enumerate(row):
                if b == "#": S.px(x + rx, y + ry, c)


rng = np.random.default_rng(1993)
YY, XX = np.mgrid[0:H, 0:W]

# ============================================================ WALL: walnut paneling
with S.surf(n=(0, 0, 1), z=0.0):
    S.rect(0, 0, W, DESK_Y, "panel")
wall = S.m_rect(0, 0, W, DESK_Y)
PLANK = 17
plank_id = XX // PLANK
plank_tone = 0.86 + 0.22 * np.random.default_rng(7).random(W // PLANK + 2)[plank_id]
grain = (np.sin(XX * 0.9 + np.sin(YY * 0.045 + plank_id * 1.7) * 2.2 + plank_id) * 0.5 + 0.5)
streak = 0.92 + 0.10 * grain + 0.05 * (np.random.default_rng(8).random((H, W)) - 0.5)
S.tone(wall, plank_tone * streak)
groove = wall & (XX % PLANK == 0)
with S.surf(n=(0.6, 0, 0.8), z=0.0):
    S.paint(groove, "panel_g")
with S.surf(n=(-0.5, 0, 0.85), z=0.0):
    S.paint(wall & (XX % PLANK == 1), "panel_h")
# where the desk meets the wall: a little occlusion
S.shade(np.where(YY < DESK_Y, np.clip(1 - (DESK_Y - YY) / 7.0, 0, 1) * 0.55, 0), "wall")
S.shade(np.where(YY < 14, np.clip(1 - YY / 14.0, 0, 1) * 0.5, 0), "wall")                       # ceiling corner

# ============================================================ DESK: one solid slab of dark walnut, darker than the paneling
desk = S.m_rect(0, DESK_Y, W, EDGE_Y - DESK_Y)
with S.surf(n=(0, -1, 0), zf=zdesk, g=0.28):
    S.paint(desk, "desk")
# the grain runs the length of the top: lines of equal depth, so they crowd together toward the wall and open up toward us
v = 1.0 / np.maximum(YY - VPY, 1)
wave = np.sin(XX * 0.011 + 1.3) * 1.6 + np.sin(XX * 0.037 + v * 900) * 0.5
gr = np.sin(v * 7400 + wave) * 0.5 + 0.5
figure = 0.94 + 0.08 * np.sin(XX * 0.006 + np.sin(v * 2600) * 2.0)                 # slow light and dark across the slab
S.tone(desk, figure * (0.9 + 0.12 * gr))
streak = desk & (gr > 0.965) & (np.random.default_rng(11).random((H, W)) < 0.8)
with S.surf(n=(0, -1, 0), zf=zdesk, g=0.22):
    S.paint(streak, "desk_g")

# ============================================================ CORKBOARD (top left)
cbx, cby, cbw, cbh = 6, 8, 90, 62
box3d(cbx, cby, cbw, cbh, 0.012, "frame", "frame", "frame", z=3, depth=3)
bevel_rect(cbx, cby, cbw, cbh, "frame", z=3, r=2, g=0.25)
with S.surf(z=2.5):
    S.rect(cbx + 3, cby + 3, cbw - 6, cbh - 6, "cork")
cork = S.mat_mask("cork")
S.tone(cork, 0.82 + 0.3 * np.random.default_rng(5).random((H, W)))
S.shade((slice(cby + 3, cby + 6), slice(cbx + 3, cbx + cbw - 3), 0.35), "cork")                    # frame lip shadow
S.shade((slice(cby + 3, cby + cbh - 3), slice(cbx + 3, cbx + 5), 0.3), "cork")


def pinned(x, y, w, h, c, edge, pin):
    """a card pinned to the cork: soft shadow down-right, the card, a pushpin"""
    S.shade((slice(y + 2, y + h + 2), slice(x + 2, x + w + 2), 0.45), "cork")
    with S.surf(z=3.2):
        S.rect(x, y, w, h, c); S.frame(x, y, w, h, edge)
    with S.surf(nf=lambda xs, ys: np.stack([(xs - (x + w / 2)) / 3.0, (ys - (y - 1.5)) / 3.0, np.ones_like(xs)], 1), z=4.5, g=0.8):
        S.disc(int(x + w / 2), y - 1, 1.6, pin)


pinned(cbx + 4, cby + 6, 36, 48, "paper", "paper_d", "red")                                   # Princess Quest 3 cover
with S.surf(z=3.3, d=False):
    S.rect(cbx + 7, cby + 9, 30, 20, "pq_purple")
    S.rect(cbx + 15, cby + 21, 14, 4, "pq_gold"); S.hline(cbx + 15, cby + 24, 14, "amber")
    for i in (0, 6, 12): S.rect(cbx + 15 + i, cby + 15, 2, 6, "pq_gold")
    S.rect(cbx + 18, cby + 18, 2, 3, "pq_gold"); S.rect(cbx + 24, cby + 18, 2, 3, "pq_gold")
    S.px(cbx + 21, cby + 22, "red"); S.px(cbx + 16, cby + 14, "label"); S.px(cbx + 28, cby + 14, "label")
text(cbx + 6, cby + 32, "PRINCESS", "ink"); text(cbx + 6, cby + 39, "QUEST", "ink"); text(cbx + 30, cby + 39, "3", "red")
with S.surf(z=3.3): S.hline(cbx + 8, cby + 49, 28, "paper_d")
pinned(cbx + 44, cby + 8, 30, 24, "sticky", "sticky_d", "disk")                                # sticky note
with S.surf(z=3.3, d=False):
    for i in range(3): S.hline(cbx + 47, cby + 13 + i * 5, 18 + (i % 2) * 5, "sticky_d")
pinned(cbx + 46, cby + 36, 26, 22, "label", "paper_d", "red")                                 # photo
with S.surf(z=3.3, d=False):
    S.rect(cbx + 48, cby + 38, 22, 14, "sky1"); S.rect(cbx + 48, cby + 46, 22, 6, "pz_green")
    S.disc(cbx + 60, cby + 43, 3, "moon")
S.shade((slice(cby + 4, cby + cbh + 3), slice(cbx + cbw, cbx + cbw + 3), 0.5), lambda s: s.mat_mask("panel", "panel_g", "panel_h"))   # board on the wall

# ============================================================ TALL POSTER (right): HEVEY DEWIS. The boombox handle hides it below row 101.
tpx, tpy, tpw, tph = 396, 6, 72, 130
PX, PY, PW, PH = tpx + 2, tpy + 2, tpw - 4, tph - 4        # the print, inside a 2 px black frame

BIG = {"H": ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
       "E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
       "V": ["#...#", "#...#", "#...#", "#...#", ".#.#.", ".#.#.", "..#.."],
       "Y": ["#...#", "#...#", "#...#", ".#.#.", "..#..", "..#..", "..#.."],
       "D": ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
       "W": ["#...#", "#...#", "#...#", "#.#.#", "#.#.#", "##.##", "#...#"],
       "I": ["###", ".#.", ".#.", ".#.", ".#.", ".#.", "###"],
       "S": [".####", "#....", "#....", ".###.", "....#", "....#", "####."]}


def big_word(word, scale=2, gap=2, slant=5):
    """a word in the 5x7 display face, scaled, sheared right by 1 px every `slant` rows (top leans right)"""
    ws = [len(BIG[c][0]) for c in word]
    tw = sum(ws) * scale + gap * (len(word) - 1)
    rows = 7 * scale; m = np.zeros((rows, tw + rows // slant + 1), bool); x = 0
    for c, w_ in zip(word, ws):
        for ry, row in enumerate(BIG[c]):
            for rx, b_ in enumerate(row):
                if b_ == "#": m[ry * scale:(ry + 1) * scale, x + rx * scale:x + (rx + 1) * scale] = True
        x += w_ * scale + gap
    out = np.zeros_like(m)
    for r_ in range(rows):
        sh = (rows - 1 - r_) // slant
        out[r_, sh:] = m[r_, :m.shape[1] - sh]
    return out


def stamp(m, x, y):
    """a small bool sprite -> a full-frame mask at x, y"""
    full = np.zeros((H, W), bool); h_, w_ = m.shape
    full[y:y + h_, x:x + w_] = m
    return full


def thick(x0, y0, x1, y1, w=2):
    m = np.zeros((H, W), bool)
    for d in range(w):
        if abs(x1 - x0) >= abs(y1 - y0): m |= S.m_line(x0, y0 + d, x1, y1 + d)
        else: m |= S.m_line(x0 + d, y0, x1 + d, y1)
    return m


def poster_band():
    """HEVEY DEWIS AND THE REPORTERS: a tour poster. The name up top, the band backlit on stage below."""
    with S.surf(z=1.0, d=False): S.rect(PX, PY, PW, PH, "hd_bg")
    gcx, gcy = PX + PW / 2.0, PY + 78                                       # the stage light behind the singer
    ang = np.arctan2(YY - gcy, XX - gcx)
    rays = S.m_rect(PX, PY, PW, PH) & ((np.floor((ang + np.pi) / (2 * np.pi) * 30) % 2) == 0)
    with S.surf(z=1.0, d=False): S.paint(rays, "hd_ray")
    for r_, c_ in ((40, "hd_g1"), (31, "hd_g2"), (23, "hd_g3"), (15, "hd_g4"), (8, "hd_g5")):
        with S.surf(z=1.0, d=False): S.paint(S.m_ellipse(gcx, gcy, r_ * 1.25, r_) & S.m_rect(PX, PY, PW, PH), c_)
    # the band in silhouette: guitar left, the singer at a raked mic stand, bass right
    sil = np.zeros((H, W), bool); top = PY + 57
    HEADS = {"long": [".###.", "#####", "#####", "#####", "#####", "##.##", "##.##"],     # hair to the shoulders
             "short": [".###.", "#####", "#####", "#####", ".###.", ".###."],
             "mullet": [".###.", "#####", "#####", "#####", ".####", ".####", "..###"]}

    def sprite(rows, x, y):
        m = np.zeros((H, W), bool)
        for ry, row in enumerate(rows):
            for rx, ch_ in enumerate(row):
                if ch_ == "#": m[y + ry, x + rx] = True
        return m

    def body(cx_, t_, hair):
        m = sprite(HEADS[hair], cx_ - 2, t_)
        m |= S.m_rect(cx_ - 1, t_ + 5, 3, 2)                                                   # neck
        m |= S.m_poly([(cx_ - 5, t_ + 7), (cx_ + 6, t_ + 7), (cx_ + 4, t_ + 22), (cx_ - 3, t_ + 22)])    # shoulders to waist
        m |= S.m_rect(cx_ - 5, t_ + 8, 11, 2)                                                  # square shoulders
        m |= thick(cx_ - 3, t_ + 21, cx_ - 7, t_ + 46, 3) | thick(cx_ + 2, t_ + 21, cx_ + 5, t_ + 46, 3)  # legs apart
        return m
    gx, gt = PX + 12, top + 2                                                                  # guitarist
    sil |= body(gx, gt, "long")
    sil |= thick(gx + 3, gt + 19, gx - 10, gt + 9, 2) | S.m_rect(gx - 12, gt + 7, 2, 3)      # neck, headstock
    sil |= S.m_ellipse(gx + 4, gt + 19, 5, 3.4) | S.m_ellipse(gx + 2, gt + 22, 4, 2.6)          # body, at his hip
    sil |= thick(gx - 5, gt + 8, gx - 7, gt + 12, 2)                                           # fretting hand
    bx_, bt = PX + 56, top + 2                                                                 # bassist, mirrored
    sil |= body(bx_, bt, "mullet")
    sil |= thick(bx_ - 3, bt + 19, bx_ + 11, bt + 7, 2) | S.m_rect(bx_ + 11, bt + 4, 2, 4)
    sil |= S.m_ellipse(bx_ - 3, bt + 19, 5, 3.4) | S.m_ellipse(bx_ - 1, bt + 22, 4, 2.6)
    sil |= thick(bx_ + 6, bt + 8, bx_ + 8, bt + 11, 2)
    sx_, st = PX + 34, top                                                                     # the singer
    sil |= body(sx_, st, "short")
    sil |= thick(sx_ + 5, st + 8, sx_ + 8, st - 2, 2) | S.m_disc(sx_ + 8.6, st - 3.4, 1.7)    # fist up
    sil |= thick(sx_ - 4, st + 8, sx_ - 7, st + 13, 2)                                         # hand on the stand
    sil |= thick(sx_ - 11, st + 47, sx_ - 4, st + 4, 1) | S.m_rect(sx_ - 4, st + 3, 2, 2)      # the stand, raked to his mouth
    sil &= S.m_rect(PX, PY, PW, PH)
    rim = sil & ~np.roll(sil, 1, axis=0) & (YY < top + 12)                                    # backlight on heads, shoulders, raised arm
    with S.surf(z=1.0, d=False):
        S.paint(sil, "hd_sil"); S.paint(rim, "hd_rim")
    # the name: upright display face, three-step fill, a two-step extrusion down and right
    for word, y_ in (("HEVEY", PY + 4), ("DEWIS", PY + 21)):
        m = big_word(word, slant=99); x_ = int(PX + (PW - m.shape[1] - 2) / 2)
        with S.surf(z=1.0, d=False):
            S.paint(stamp(m, x_ + 2, y_ + 2), "hd_shadow"); S.paint(stamp(m, x_ + 1, y_ + 1), "hd_ext")
            for c_, r0, r1 in (("hd_y1", 0, 5), ("hd_y2", 5, 9), ("hd_y3", 9, 14)):
                mm = np.zeros_like(m); mm[r0:r1] = m[r0:r1]; S.paint(stamp(mm, x_, y_), c_)
    # AND THE REPORTERS, set as a newspaper nameplate
    ny = PY + 39
    with S.surf(z=1.0, d=False):
        S.rect(PX, ny, PW, 9, "paper"); S.hline(PX, ny, PW, "ink"); S.hline(PX, ny + 8, PW, "ink")
    line_ = "AND THE REPORTERS"
    text(PX + (PW - text_w(line_, space=2)) // 2, ny + 2, line_, "ink", space=2)


with S.surf(z=1.0):
    S.rect(tpx, tpy, tpw, tph, "ink")
poster_band()
S.shade((slice(tpy + 3, tpy + tph + 3), slice(tpx + tpw, tpx + tpw + 3), 0.45), lambda s: s.mat_mask("panel", "panel_g", "panel_h"))

# ============================================================ WALL POSTER behind the lamp: PROJECT ZOMBOID
WPX, WPY, WPW, WPH = 6, 76, 92, 100
with S.surf(z=1.0):
    S.rect(WPX, WPY, WPW, WPH, "ink")
    S.rect(WPX + 2, WPY + 2, WPW - 4, WPH - 4, "pz_green")
S.tone(S.m_rect(WPX + 2, WPY + 2, WPW - 4, 40), 0.75 + 0.5 * np.clip((WPY + 42 - YY) / 40.0, 0, 1))    # sky lighter toward the top
with S.surf(z=1.0, d=False):
    S.disc(WPX + 18, WPY + 20, 9, "moon"); S.disc(WPX + 21, WPY + 18, 7, "pz_green"); S.disc(WPX + 20, WPY + 19, 7, "moon")
    for (tx_, th_) in ((0, 22), (10, 30), (19, 18), (30, 34), (42, 26), (52, 38), (64, 24), (74, 30), (84, 16)):
        S.poly([(WPX + tx_, WPY + WPH - 38), (WPX + tx_ + 4, WPY + WPH - 38 - th_), (WPX + tx_ + 8, WPY + WPH - 38)], "pz_dark")
    S.rect(WPX + 2, WPY + WPH - 38, WPW - 4, 36, "pz_dark")
    fx_, fy_ = WPX + 54, WPY + WPH - 38
    S.rect(fx_ + 3, fy_ - 26, 4, 5, "pz_green2"); S.rect(fx_ + 2, fy_ - 21, 6, 11, "pz_green2"); S.rect(fx_ + 8, fy_ - 20, 8, 2, "pz_green2")
    S.rect(fx_ + 15, fy_ - 21, 2, 3, "pz_green2"); S.rect(fx_ + 1, fy_ - 10, 2, 10, "pz_green2"); S.rect(fx_ + 6, fy_ - 10, 2, 10, "pz_green2")
    S.px(fx_ + 4, fy_ - 24, "pz_dark")
text(WPX + 6, WPY + WPH - 34, "PROJECT", "pz_text", 3, 1); text(WPX + 6, WPY + WPH - 17, "ZOMBOID", "pz_text", 3, 1)
with S.surf(nf=None, z=2, g=0.7):
    for tk in ((WPX + 3, WPY + 3), (WPX + WPW - 5, WPY + 3), (WPX + 3, WPY + WPH - 5), (WPX + WPW - 5, WPY + WPH - 5)): S.rect(tk[0], tk[1], 2, 2, "lgray")

RIG = {
    "lamp": {"pos": (86, 116, 78), "dir": (0.05, 0.93, 0.36), "inner": 26, "outer": 58, "power": 3.1, "radius": 120,
             "col": (1.0, 0.80, 0.56), "halo": 0.55, "halo_radius": 75, "halo_col": (1.0, 0.76, 0.5)},
    "bounce": {"pos": (96, 206, 70), "col": (1.0, 0.72, 0.44), "power": 0.5, "radius": 95},
    "crt": {"rect": (120, 30, 240, 180), "z": 68, "col": (0.96, 0.95, 0.88), "power": 2.6, "radius": 170, "wash": 0.24, "wash_radius": 50},
    "moon": {"dir": (0.75, -0.55, 0.62), "col": (0.46, 0.56, 0.95), "power": 0.26, "x0": 160, "falloff": 1.3, "floor": 0.12},
    "ambient": (0.028, 0.029, 0.042), "fill": 0.05,
}

def simz_box_art(x0, y0, w, h, z):
    """THE SIMZ box front: the build-mode grid, a lot with its front walls cut away, and the new resident walking in"""
    with S.surf(z=z, d=False): S.rect(x0, y0, w, h, "simz_bg")
    grid = S.m_rect(x0, y0, w, h) & ((((XX - 2 * YY) % 16) < 2) | (((XX + 2 * YY) % 16) < 2))
    with S.surf(z=z, d=False): S.paint(grid, "simz_grid")
    N_ = 10; OX, OY = x0 + w // 2, y0 + 16

    def iso(i, j, k=0.0): return (OX + (i - j) * 2, OY + (i + j) - k * 2)

    def quad(c, pts, e=None):
        with S.surf(z=z + 0.1, d=False, e=e): S.poly([iso(*p) for p in pts], c)
    with S.surf(z=z + 0.05, d=False): S.paint(S.m_ellipse(OX, OY + N_ + 8, 16, 3) & S.m_rect(x0, y0, w, h), "simz_shadow")
    quad("dirt", [(N_, 0, 0), (N_, N_, 0), (N_, N_, -1), (N_, 0, -1)])
    quad("dirt_d", [(0, N_, 0), (N_, N_, 0), (N_, N_, -1), (0, N_, -1)])
    quad("grass", [(0, 0, 0), (N_, 0, 0), (N_, N_, 0), (0, N_, 0)])
    for (i, j) in ((1, 1), (3, 8), (8, 3), (6, 8), (9, 6)):
        x_, y_ = iso(i, j); S.px(int(x_), int(y_), "grass_d")
    quad("floor", [(1, 1, 0), (7, 1, 0), (7, 5, 0), (1, 5, 0)])
    quad("wall_l", [(1, 1, 0), (1, 5, 0), (1, 5, 4), (1, 1, 4)])
    quad("wall_r", [(1, 1, 0), (7, 1, 0), (7, 1, 4), (1, 1, 4)])
    quad("wall_top", [(1, 1, 4), (7, 1, 4), (7, 1, 4.5), (1, 1, 4.5)]); quad("wall_top", [(1, 1, 4), (1, 5, 4), (1, 5, 4.5), (1, 1, 4.5)])
    quad("window", [(3.5, 1, 1.5), (5.5, 1, 1.5), (5.5, 1, 3.2), (3.5, 1, 3.2)])
    quad("blanket", [(1.5, 2, 1), (3.5, 2, 1), (3.5, 4, 1), (1.5, 4, 1)]); quad("blanket_d", [(3.5, 2, 0), (3.5, 4, 0), (3.5, 4, 1), (3.5, 2, 1)])
    quad("label", [(1.5, 2, 1.1), (2.2, 2, 1.1), (2.2, 4, 1.1), (1.5, 4, 1.1)])
    quad("tv", [(5.5, 1.5, 0), (6.6, 1.5, 0), (6.6, 1.5, 1.8), (5.5, 1.5, 1.8)]); quad("tv", [(6.6, 1.5, 0), (6.6, 2.6, 0), (6.6, 2.6, 1.8), (6.6, 1.5, 1.8)])
    quad("tv_glow", [(6.6, 1.65, 0.45), (6.6, 2.45, 0.45), (6.6, 2.45, 1.5), (6.6, 1.65, 1.5)], e="#2a5a86")
    for k in range(0, N_ + 1, 2):                                                   # picket fence, broken where he came through
        for (i, j) in ((N_, k), (k, N_)):
            if (i, j) == (N_, 8): continue
            x_, y_ = iso(i, j)
            with S.surf(z=z + 0.2, d=False): S.rect(int(x_), int(y_) - 2, 1, 2, "label")
    mx_, my_ = iso(N_, 1)                                                           # mailbox, flag up
    with S.surf(z=z + 0.2, d=False):
        S.rect(int(mx_) - 1, int(my_) - 4, 1, 4, "frame"); S.rect(int(mx_) - 2, int(my_) - 6, 3, 2, "lgray"); S.px(int(mx_) + 1, int(my_) - 7, "red")
    ZOMB = [".gg...", ".gk...", ".ss...", "sssgg.", ".ss...", ".pp...", ".p.p.."]
    zx, zy = iso(8, 6); zx, zy = int(zx) - 2, int(zy) - 7
    cmap = {"g": "zskin", "k": "ink", "s": "zshirt", "p": "zpants"}
    with S.surf(z=z + 0.3, d=False):
        for ry, row in enumerate(ZOMB):
            for rx, ch_ in enumerate(row):
                if ch_ in cmap: S.px(zx + rx, zy + ry, cmap[ch_])


def build_objects():
    # ============================================================ ARCHITECT LAMP (left)
    BX, BY = 8, DESK_Y + 18
    EX, EY = 3, 98
    AX, AY = 48, 72
    HX, HY = 80, 110
    # base: heavy disc on the desk, a turned ring on top
    S.shade(0.6 * np.clip(1 - (((XX - BX - 3) / 30.0) ** 2 + ((YY - BY - 6) / 8.0) ** 2), 0, 1), "desk")
    with S.surf(n=(0, 0.25, 1), z=64, g=0.55):
        for yy in range(0, 6): S.ellipse(BX, BY + yy, 24, 6, "lamp_dark")
    with S.surf(nf=lambda xs, ys: np.stack([(xs - BX) / 40.0, -np.ones_like(xs), (ys - BY) / 12.0], 1), z=62, g=0.7):
        S.ellipse(BX, BY, 24, 6, "lamp_metal"); S.ellipse(BX, BY - 1, 21, 4, "lamp_metal")
    with S.surf(n=(0, -1, 0.3), z=62, g=0.5):
        S.ellipse(BX, BY, 21, 4, "lamp_dark"); S.ellipse(BX, BY - 1, 20, 3, "lamp_metal")
        S.ellipse(BX, BY, 8, 2, "lamp_dark")

    def rod(x0, y0, x1, y1, t, c, z, g=0.75):
        """a round bar: normals turn across its width"""
        dx, dy = x1 - x0, y1 - y0; L = math.hypot(dx, dy); px_, py_ = -dy / L, dx / L
        def nf(xs, ys):
            off = ((xs - x0) * px_ + (ys - y0) * py_) / (t / 2.0 + 0.5)
            off = np.clip(off, -1, 1)
            return np.stack([off * px_, off * py_, np.sqrt(np.clip(1 - off ** 2, 0.05, 1))], 1)
        m = np.zeros((H, W), bool)
        for o in np.linspace(-t / 2.0, t / 2.0, max(2, int(t * 2))):
            m |= S.m_line(x0 + px_ * o, y0 + py_ * o, x1 + px_ * o, y1 + py_ * o)
        with S.surf(nf=nf, z=z, g=g): S.paint(m, c)

    def joint(cx, cy, r, z):
        with S.surf(nf=lambda xs, ys: np.stack([(xs - cx) / (r + 1), (ys - cy) / (r + 1), np.ones_like(xs) * 0.8], 1), z=z, g=0.8):
            S.disc(cx, cy, r, "lamp_metal")
        with S.surf(z=z + 0.5, g=0.3): S.px(cx, cy, "lamp_dark")

    rod(BX, BY - 14, BX, BY, 6, "lamp_metal", 60)
    joint(BX, BY - 15, 4, 58)
    rod(BX - 9, BY - 23, EX - 7, EY + 1, 2, "lamp_dark", 54, 0.5)                                    # second rod of the parallelogram
    for k in range(6, 24, 2):                                                                      # springs
        t = k / 28.0; sx_ = int(BX + (EX - BX) * t); sy_ = int(BY - 15 + (EY - BY + 15) * t)
        with S.surf(n=(0, -0.6, 0.8), z=56, g=0.6): S.rect(sx_ - 7, sy_ - 1, 5, 1, "lamp_metal" if k % 4 else "lamp_dark")
    rod(BX, BY - 15, EX, EY, 4, "lamp_metal", 56)
    joint(EX, EY, 4, 56); joint(EX - 7, EY + 1, 3, 55)
    rod(EX, EY, AX, AY, 4, "lamp_metal", 62)
    joint(AX, AY, 4, 64)
    # shade: a cone from the pivot to the mouth; outside lit by the room, inside glowing
    ax, ay = HX - AX, HY - AY; L = math.hypot(ax, ay); ux, uy = ax / L, ay / L; nx_, ny_ = -uy, ux
    R0, R1 = 7, 24
    cone = [(AX + nx_ * R0, AY + ny_ * R0), (HX + nx_ * R1, HY + ny_ * R1), (HX - nx_ * R1, HY - ny_ * R1), (AX - nx_ * R0, AY - ny_ * R0)]
    def cone_n(xs, ys):
        along = ((xs - AX) * ux + (ys - AY) * uy) / L
        half = R0 + (R1 - R0) * np.clip(along, 0, 1)
        off = np.clip(((xs - AX) * nx_ + (ys - AY) * ny_) / np.maximum(half, 1), -1, 1)
        nz = np.sqrt(np.clip(1 - off ** 2, 0.05, 1))
        return np.stack([off * nx_ - 0.35 * ux, off * ny_ - 0.35 * uy, nz], 1)
    with S.surf(nf=cone_n, z=74, g=0.85):
        S.poly(cone, "lamp_metal")
    with S.surf(n=(-0.3, -0.5, 0.8), z=75, g=1.0, d=False):
        S.line(int(AX + nx_ * R0), int(AY + ny_ * R0), int(HX + nx_ * R1), int(HY + ny_ * R1), "lgray")       # rim highlight
    with S.surf(nf=cone_n, z=74, g=0.4):
        for k in range(4): S.px(int(AX + ux * (8 + k * 3) + nx_ * 3), int(AY + uy * (8 + k * 3) + ny_ * 3), "lamp_dark")   # vent slots
    def rot_ellipse_mask(cx, cy, ux_, uy_, rx, ry):
        pts = [(cx + ux_ * rx * math.cos(t) - uy_ * ry * math.sin(t), cy + uy_ * rx * math.cos(t) + ux_ * ry * math.sin(t)) for t in [k * math.pi / 16 for k in range(32)]]
        return S.m_poly(pts)
    with S.surf(n=(0.2, -0.2, 1), z=78, g=0.9):
        S.paint(rot_ellipse_mask(HX, HY, nx_, ny_, R1, 8), "lamp_metal")                                     # the rim
    with S.surf(n=(0, 0, 1), z=76, e="#c79a52", d=False):
        S.paint(rot_ellipse_mask(HX, HY, nx_, ny_, R1 - 1, 7), "lamp_in")                                    # inside the shade, lit
    with S.surf(n=(0, 0, 1), z=76, e="#f3d39a", d=False):
        S.paint(rot_ellipse_mask(HX, HY, nx_, ny_, R1 - 5, 4), "lamp_in")
    with S.surf(n=(0, 0, 1), z=77, e="#fff6e0", d=False):
        S.disc(HX + int(ux * 3), HY + int(uy * 3), 3, "bulb")
    mouth = rot_ellipse_mask(HX, HY, nx_, ny_, R1, 8)
    from scipy import ndimage as _ndi
    dist = _ndi.distance_transform_edt(~mouth)
    glow = np.clip(1 - dist / 9.0, 0, 1) ** 2 * (~mouth)
    S.E[...] += glow[..., None] * lin(hx("#4a3418"))[None, None, :]
    S.E_lamp[...] = S.E                                                                                       # everything emitted so far is the lamp
    with S.surf(n=(0, -1, 0), zf=zdesk, g=0.2):                                                               # cord behind the base
        S.line(BX - 24, BY + 2, BX - 32, BY + 9, "lamp_dark"); S.vline(BX - 32, BY + 9, 12, "lamp_dark")

    # ============================================================ FLOPPY CASE (left of the computer)
    fbx, fby, fbw, fbh = 28, 196, 80, 62
    K = 0.045; LH = 36
    S.shade(0.55 * np.clip(1 - (((XX - fbx - fbw / 2) / (fbw * 0.62)) ** 2 + ((YY - fby - fbh - 1) / 4.0) ** 2), 0, 1), "desk")
    box3d(fbx, fby + LH, fbw, fbh - LH, K, "beige", "beige_s", None, z=92, depth=40, gloss=0.25)
    with S.surf(z=92, g=0.2):
        S.hline(fbx, fby + fbh - 1, fbw, "beige_d")
        S.rect(fbx + fbw // 2 - 8, fby + LH + 10, 16, 6, "beige_s"); S.frame(fbx + fbw // 2 - 8, fby + LH + 10, 16, 6, "beige_d")   # latch
    # the smoked lid: tinted, glossy, the disks dim behind it
    box3d(fbx, fby, fbw, LH, K, "smoke", "smoke", "smoke", z=92, depth=40, gloss=0.9)
    with S.surf(z=91, g=0.6, d=True):
        for i in range(8):
            S.rect(fbx + 6 + i * 9, fby + 8, 7, 28, "disk"); S.rect(fbx + 8 + i * 9, fby + 13, 3, 3, "disk_l")
    behind = S.m_rect(fbx + 1, fby + 1, fbw - 2, LH - 1)
    S.tone(behind & S.mat_mask("disk", "disk_l"), 0.62)                                                       # seen through smoked plastic
    with S.surf(n=(0, 0, 1), z=93, g=0.9, d=False):
        S.hline(fbx, fby, fbw, "lgray"); S.hline(fbx, fby + LH - 1, fbw, "mgray")
    with S.surf(nf=lambda xs, ys: np.stack([(xs - fbx - fbw // 2) / 6.0, (ys - fby - 24) / 6.0, np.ones_like(xs)], 1), z=94, g=0.9):
        S.disc(fbx + fbw // 2, fby + 24, 5, "chrome")
    with S.surf(z=95, d=False): S.rect(fbx + fbw // 2, fby + 22, 1, 4, "ink"); S.px(fbx + fbw // 2, fby + 26, "ink")
    # a glint across the smoked lid
    with S.surf(z=93, d=False, g=1.0):
        for i in range(10): S.px(fbx + 10 + i, fby + 3 + i // 2, "mgray")

    # ============================================================ ORANGE SODA CAN (Oct 28 2026, was the cola)
    # Corn and an orange over ORANGE SODA, then the claim: 25% HIGHER FRUCTOSE CORN! Bigger than the cola (40 x 78, was
    # 34 x 54) so the claim reads at 1080p. Everything printed on it is drawn already wrapped: a line of type rides the
    # can's curve, its end letters 1 px higher where the can turns away.
    cx, cy, cw, ch = 17, 192, 40, 78
    S.shade(0.6 * np.clip(1 - (((XX - cx - cw / 2 - 2) / 26.0) ** 2 + ((YY - cy - ch - 1) / 5.0) ** 2), 0, 1), "desk")
    ccx = cx + cw / 2.0; r = cw / 2.0; bow = 4.7; lid_ry = 5.9         # a ring around the can drops by bow*cos(theta) toward us
    def can_n(xs, ys):
        t = np.clip((xs - ccx) / r, -1, 1)
        return np.stack([t, np.zeros_like(xs), np.sqrt(np.clip(1 - t ** 2, 0.02, 1))], 1)
    cols = np.arange(cx, cx + cw); th = np.arcsin(np.clip((cols + 0.5 - ccx) / r, -1, 1)); drop = bow * np.cos(th)
    def band(y0, h, mat, g_=0.75):
        m = np.zeros((H, W), bool)
        for x_, d_ in zip(cols, drop):
            m[int(round(y0 + d_)):int(round(y0 + d_ + h)), x_] = True
        with S.surf(nf=can_n, z=98, g=g_): S.paint(m, mat)
        return m
    band(cy - 1, ch + 1, "orange")
    with S.surf(nf=can_n, z=98, g=0.75): S.ellipse(ccx - 0.5, cy + ch, cw / 2.0, lid_ry, "orange", half="bottom")
    band(cy, 2, "chrome", 0.9)                                            # the neck
    band(cy + 17, 2, "orange_d", 0.6)
    band(cy + 19, 20, "label")
    band(cy + 39, ch - 39, "promo", 0.6)                                 # the claim's band, dark so its type reads

    art = {}                                                              # material -> pixels; a later piece covers an earlier one
    def put(piece):
        taken = {p for v in piece.values() for p in v}
        for k in art: art[k] = [p for p in art[k] if p not in taken]
        for k, v in piece.items(): art.setdefault(k, []).extend(v)
    def grid(rows, x0, y0, legend):
        out = {}
        for ry, row in enumerate(rows):
            for rx, c in enumerate(row):
                if c in legend: out.setdefault(legend[c], []).append((x0 + rx, y0 + ry))
        return out
    def orange_fruit(x0, y0, d):
        """a d x d orange: dark rind edge, lit upper left, shaded lower right, a glint"""
        out, c = {}, (d - 1) / 2.0
        inside = lambda i, j: (i - c) ** 2 + (j - c) ** 2 <= (d / 2.0) ** 2 - 0.3
        for j in range(d):
            for i in range(d):
                if not inside(i, j): continue
                rim = not all(inside(i + a, j + b) for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1)))
                m = "fruit_k" if rim else ("fruit_d" if (i - c) / c * 0.6 + (j - c) / c * 0.8 > 0.40 else "fruit")
                out.setdefault(m, []).append((x0 + i, y0 + j))
        glint = [(x0 + int(round(c)) + a, y0 + int(round(c)) + b) for a, b in ((-3, -4), (-2, -4), (-4, -3), (-4, -2))]
        out["fruit"] = [p for p in out["fruit"] if p not in glint]; out["fruit_h"] = glint
        return out
    def corn_ear(x0, y0, x1, y1, w):
        """an ear of corn from its base to its tip: kernels in a checker, lit along its upper left, a dark edge below,
        the tip rounded off"""
        out = {}
        L = math.hypot(x1 - x0, y1 - y0); ux, uy = (x1 - x0) / L, (y1 - y0) / L; nx, ny = -uy, ux
        if nx + ny > 0: nx, ny = -nx, -ny                                 # n: across the ear, toward the upper left
        for y in range(int(min(y0, y1) - w - 2), int(max(y0, y1) + w + 3)):
            for x in range(int(min(x0, x1) - w - 2), int(max(x0, x1) + w + 3)):
                px_, py_ = x + 0.5 - x0, y + 0.5 - y0
                t = px_ * ux + py_ * uy; s_ = px_ * nx + py_ * ny
                if t < -0.5 or t > L + 0.5: continue
                ww = w if t < L - 4 else w * max(0.0, 1 - ((t - (L - 4)) / 4.6) ** 2) ** 0.5
                if abs(s_) > ww: continue
                if abs(s_) > ww - 1.0: m = "corn_d" if s_ < 0 or t > L - 2 else "corn_l"
                elif s_ < -1.2: m = "corn_d" if (x + y) % 2 else "corn_l"
                else: m = "corn_l" if (x + y) % 2 == 0 else ("corn" if s_ < 1.2 else "corn_l")
                out.setdefault(m, []).append((x, y))
        return out
    LEAF = {"g": "leaf", "G": "leaf_d"}
    put(grid(["...G.", "..gG.", ".ggG.", "gggG.", "ggG..", "gG..."], cx + 18, cy + 6, LEAF))        # the husk, above
    put(grid(["gg.......", "gggg.....", ".gggGG...", "..GgggGG.", "....GGggG"], cx + 18, cy + 16, LEAF))   # and below
    put(corn_ear(cx + 12, cy + 19, cx + 30, cy + 8, 3.3))
    put(orange_fruit(cx + 6, cy + 8, 13))
    put(grid([".gg...", "gggG..", ".ggGG.", "....G."], cx + 10, cy + 4, LEAF))                      # the orange's leaf
    drawn = {p for v in art.values() for p in v}                          # a dusting of sugar around them
    put({"sugar": [(cx + a, cy + b) for a, b in ((5, 7), (23, 6), (32, 13), (35, 10), (33, 19), (36, 16), (28, 20),
                                                     (31, 8), (2, 15), (3, 20)) if (cx + a, cy + b) not in drawn]})

    SMALL = dict(FONT, N=["1001", "1101", "1011", "1001", "1001"], O=["111", "101", "101", "101", "111"], I=["1"] * 5,
                 **{"!": ["1", "1", "1", "0", "1"]})                       # the room's type: a full N, a square O, a thin I
    BIG = {"S": [".####", "#####", "##...", "##...", "####.", ".####", "...##", "...##", "#####", "####."],
           "O": [".####.", "######", "##..##", "##..##", "##..##", "##..##", "##..##", "##..##", "######", ".####."],
           "D": ["####.", "#####", "##.##", "##.##", "##.##", "##.##", "##.##", "##.##", "#####", "####."],
           "A": [".###.", "#####", "##.##", "##.##", "##.##", "#####", "#####", "##.##", "##.##", "##.##"],
           "2": [".###.", "#####", "##.##", "...##", "..###", ".###.", "###..", "##...", "#####", "#####"],
           "5": ["#####", "#####", "##...", "####.", "#####", "...##", "...##", "##.##", "#####", ".###."],
           "%": ["##..##", "##..##", "...##.", "...##.", "..##..", "..##..", ".##...", ".##...", "##..##", "##..##"]}
    def line(s_, y_front, font):
        """a line of type centred on the can, each letter riding the curve"""
        ws = [len(font[c][0]) for c in s_]
        x = int(round(ccx - (sum(ws) + len(ws) - 1) / 2.0)); out = []
        for c, gw in zip(s_, ws):
            dy = int(round(bow * math.cos(math.asin(np.clip((x + gw / 2.0 - ccx) / r, -1, 1))) - bow))
            for ry, row in enumerate(font[c]):
                for rx, b in enumerate(row):
                    if b in "1#": out.append((x + rx, y_front + dy + ry))
            x += gw + 1
        return out
    put({"orange_ink": line("ORANGE", cy + 26, SMALL) + line("SODA", cy + 32, BIG)})
    put({"claim_hi": line("25%", cy + 48, BIG)})
    put({"claim": line("HIGHER", cy + 59, SMALL) + line("FRUCTOSE", cy + 65, SMALL) + line("CORN!", cy + 71, SMALL)})
    for mat, pts in art.items():
        m = np.zeros((H, W), bool)
        for x, y in pts:
            if 0 <= x < W and 0 <= y < H: m[y, x] = True
        with S.surf(nf=can_n, z=98.5, g=0.75, d=False): S.paint(m, mat)
    with S.surf(n=(0, -1, 0.15), z=96, g=0.9):
        S.ellipse(ccx - 0.5, cy, cw / 2.0, lid_ry, "chrome"); S.ellipse(ccx - 0.5, cy, cw / 2.0 - 2, lid_ry - 1, "lgray")
    with S.surf(n=(0, -1, 0.3), z=96, g=0.5):
        S.rect(cx + 16, cy - 2, 9, 3, "mgray"); S.rect(cx + 18, cy - 2, 3, 1, "chrome")

    # ============================================================ BOOMBOX (back right)
    bbx, bby, bbw, bbh = 366, 110, 110, 80
    S.shade(0.55 * np.clip(1 - (((XX - bbx - bbw / 2) / 64.0) ** 2 + ((YY - bby - bbh - 1) / 5.0) ** 2), 0, 1), "desk")
    S.shade((slice(bby, bby + bbh + 2), slice(bbx - 6, bbx), 0.35), "wall")
    box3d(bbx, bby, bbw, bbh, 0.03, "bb", "bb_d", "bb_l", z=30, depth=26, gloss=0.35)
    bevel_rect(bbx, bby, bbw, bbh, "bb", z=30, r=2, g=0.35)
    rod(bbx + 14, bby - 7, bbx + bbw - 14, bby - 7, 3, "bb_l", 30, 0.6)                                   # carrying handle
    for hx_ in (bbx + 12, bbx + bbw - 15):
        bevel_rect(hx_, bby - 8, 4, 8, "bb_d", z=30, r=1, g=0.4)
    with S.surf(n=(0, 0, 1), z=28, g=0.9): S.rect(bbx + bbw - 16, bby - 34, 2, 26, "chrome")               # antenna
    for spx in (bbx + 5, bbx + bbw - 37):
        with S.surf(z=31, g=0.2):
            S.rect(spx, bby + 14, 32, 58, "grille"); S.frame(spx, bby + 14, 32, 58, "bb_d")
        grill = S.m_rect(spx + 1, bby + 15, 30, 56) & ((XX + YY) % 2 == 0)
        S.tone(grill, 1.9)
        cxs, cys = spx + 16, bby + 43
        def cone_dish(xs, ys, cxs=cxs, cys=cys):
            r = np.hypot(xs - cxs, ys - cys) / 11.0
            return np.stack([(xs - cxs) / 11.0 * -0.35, (ys - cys) / 11.0 * -0.35, np.ones_like(xs)], 1)
        with S.surf(nf=cone_dish, z=31, g=0.05):
            S.disc(cxs, cys, 10, "bb_d"); S.disc(cxs, cys, 6, "bb")
        with S.surf(n=(0, 0, 1), z=32, g=0.3): S.disc(cxs, cys, 2, "mgray")
    with S.surf(z=31, g=0.2):
        S.rect(bbx + 40, bby + 8, 30, 14, "tuner"); S.frame(bbx + 40, bby + 8, 30, 14, "bb_d")              # tuner window, backlit
    with S.surf(z=31, d=False):
        S.hline(bbx + 43, bby + 14, 24, "bb_d")
        for i in range(5): S.px(bbx + 44 + i * 5, bby + 11, "bb_d")
    tun = S.m_rect(bbx + 41, bby + 9, 28, 12)
    S.E[tun] += lin(hx("#3a2a12")) * 1.0
    with S.surf(z=31, d=False, e="#5a1408"): S.rect(bbx + 53, bby + 11, 1, 8, "needle")                    # the tuning needle (x 419)
    with S.surf(z=31, g=0.9):
        S.rect(bbx + 40, bby + 26, 30, 26, "smoke"); S.frame(bbx + 40, bby + 26, 30, 26, "bb_d")           # cassette door
        S.rect(bbx + 43, bby + 30, 24, 14, "amber"); S.rect(bbx + 45, bby + 31, 20, 2, "paper")
    with S.surf(z=31, g=0.6):
        S.disc(bbx + 49, bby + 37, 3, "bb_d"); S.disc(bbx + 61, bby + 37, 3, "bb_d")
    S.tone(S.m_rect(bbx + 41, bby + 27, 28, 24), 0.7)
    for i in range(6):
        bevel_rect(bbx + 40 + i * 5, bby + 58, 4, 8, "lgray", z=33, r=1, g=0.6)
        with S.surf(z=33): S.hline(bbx + 40 + i * 5, bby + 65, 4, "mgray")

    # ============================================================ GAME BOXES (front right)
    gbx, gby, gbw, gbh = 382, 168, 58, 82
    for n, (spx, colr) in enumerate(((442, "box_purple"), (456, "box_teal"))):
        box3d(spx, gby + 3, 13, gbh - 3, 0.012, colr, "black", "dgray", z=50, depth=20, gloss=0.3)
        with S.surf(z=50, d=False):
            S.frame(spx, gby + 3, 13, gbh - 3, "ink")
            for yy in range(gby + 14, gby + gbh - 16, 4): S.rect(spx + 5, yy, 3, 2, "paper")
            S.rect(spx + 3, gby + gbh - 13, 7, 6, "paper")
    S.shade(0.5 * np.clip(1 - (((XX - gbx - gbw / 2 - 20) / 50.0) ** 2 + ((YY - gby - gbh - 1) / 4.0) ** 2), 0, 1), "desk")
    box3d(gbx, gby, gbw, gbh, 0.012, "box_blue", "black", "dgray", z=56, depth=20, gloss=0.3)
    with S.surf(z=56, d=False):
        S.frame(gbx, gby, gbw, gbh, "ink")
    simz_box_art(gbx + 4, gby + 4, gbw - 8, 46, z=56)
    with S.surf(z=56, d=False):
        S.rect(gbx + 4, gby + 53, gbw - 8, 22, "paper")
        S.rect(gbx + 4, gby + gbh - 5, gbw - 8, 2, "label")
    text(gbx + 6, gby + 54, "THE", "ink")
    text(gbx + 6, gby + 60, "SIM", "navy", 2, 1); text(gbx + 30, gby + 60, "Z", "simz_gd", 2, 1)

    # ============================================================ DESKTOP CASE (front, runs off the bottom)
    csx, csy, csw, csh = 90, 238, 300, 44
    box3d(csx, csy, csw, csh, 0.06, "beige", "beige_s", "beige", z=100, depth=60, gloss=0.25)
    def case_n(xs, ys):
        r = 2.5
        dl, dr, dt = xs - csx, (csx + csw) - xs, ys - csy
        nx = np.where(dl < r, -(1 - dl / r), np.where(dr < r, (1 - dr / r), 0.0)) * 0.7 + 0.18 * ((xs - (csx + csw / 2)) / (csw / 2)) ** 3
        ny = np.where(dt < r, -(1 - dt / r), 0.0) * 0.7 - 0.06
        return np.stack([nx, ny, np.ones_like(xs)], 1)
    with S.surf(nf=case_n, z=100, g=0.25): S.rect(csx, csy, csw, csh, "beige")
    plastic = S.m_rect(csx, csy - 12, csw + 12, csh + 12) & S.mat_mask("beige")
    S.tone(plastic, 0.97 + 0.04 * np.random.default_rng(21).random((H, W)))
    ky_mark(csx + 10, csy + 6, "dgray"); text(csx + 24, csy + 7, "KI", "dgray")
    # power button (Quit in game): round, proud of the panel
    with S.surf(nf=lambda xs, ys: np.stack([(xs - 130) / 4.5, (ys - 247) / 4.5, np.ones_like(xs)], 1), z=102, g=0.6):
        S.disc(130, 247, 4, "beige_s")
    with S.surf(nf=lambda xs, ys: np.stack([(xs - 130) / 6.0, (ys - 247) / 6.0, np.ones_like(xs)], 1), z=103, g=0.7):
        S.disc(130, 247, 3, "beige_h")
    with S.surf(z=103, d=False):                                                                      # the power glyph: a broken ring, a bar
        for (x_, y_) in ((128, 246), (128, 247), (128, 248), (129, 249), (130, 249), (131, 249), (132, 248), (132, 247), (132, 246), (130, 245), (130, 246)):
            S.px(x_, y_, "dgray")
    with S.surf(z=101, d=False, e="#2bb02b"): S.rect(csx + 50, csy + 8, 3, 2, "led_g")                  # power light
    with S.surf(z=101, d=False, e="#e08a18"): S.rect(146, 246, 3, 2, "led_a")                          # hard disk light (lit)
    # reset button
    bevel_rect(csx + 10, csy + 18, 16, 10, "beige_s", z=100, r=1, g=0.3)
    bevel_rect(csx + 14, csy + 21, 8, 4, "beige_h", z=102, r=1, g=0.5)
    # sound and input jacks
    with S.surf(z=99, g=0.2):
        S.rect(csx + 36, csy + 17, 52, 12, "beige_s"); S.frame(csx + 36, csy + 17, 52, 12, "beige_d")
    for i, c in enumerate(("box_purple", "led_g", "box_teal", "red", "pq_gold")):
        pxc = csx + 42 + i * 10
        with S.surf(nf=lambda xs, ys, pxc=pxc: np.stack([(xs - pxc) / 4.0, (ys - csy - 23) / 4.0, np.ones_like(xs)], 1), z=100, g=0.5):
            S.disc(pxc, csy + 23, 3, c)
        with S.surf(z=99, d=False):
            S.px(pxc, csy + 23, "ink"); S.px(pxc - 1, csy + 23, "ink"); S.px(pxc, csy + 22, "ink")
    # vents
    with S.surf(z=99, d=False):
        for i in range(6): S.rect(csx + 100 + i * 6, csy + 20, 3, 7, "beige_s"); S.hline(csx + 100 + i * 6, csy + 20, 3, "beige_d")
    # the 5.25" drive
    dx, dy, dw, dh = csx + csw - 96, csy + 6, 84, 24
    bevel_rect(dx, dy, dw, dh, "beige_s", z=99, r=1, g=0.3)
    with S.surf(z=99, d=False):
        S.frame(dx, dy, dw, dh, "beige_d")
        S.rect(dx + 5, dy + 11, dw - 10, 3, "ink"); S.hline(dx + 5, dy + 14, dw - 10, "beige_d")
    bevel_rect(dx + dw - 24, dy + 4, 12, 16, "beige", z=101, r=1, g=0.4)
    bevel_rect(dx + dw - 20, dy + 6, 4, 12, "beige_d", z=102, r=1, g=0.4)
    with S.surf(z=101, d=False, e="#2bb02b"): S.rect(300, 262, 3, 2, "led_g")                           # floppy light (lit)

    # ============================================================ MONITOR (on the case)
    mx, my, mw, mh = 100, 10, 280, 224
    sx, sy, sw, sh = 120, 30, 240, 180
    # shadow of the monitor onto the case top
    S.shade((slice(my + mh, my + mh + 3), slice(mx + 4, mx + mw - 4), 0.6), lambda s: (s.C == s.idx["beige"]) & (s.N[..., 1] < -0.5))   # the monitor sitting on the case top
    shell = np.zeros((H, W), bool)
    m = np.zeros((H * 8, W * 8), np.uint8)
    from PIL import ImageDraw
    im = Image.new("L", (W * 8, H * 8), 0); ImageDraw.Draw(im).rounded_rectangle([mx * 8, my * 8, (mx + mw) * 8 - 1, (my + mh) * 8 - 1], radius=6 * 8, fill=255)
    shell = np.asarray(im.resize((W, H), Image.BOX)) >= 128
    def shell_n(xs, ys):
        r = 4.0
        dl, dr, dt, db = xs - mx, (mx + mw) - xs, ys - my, (my + mh) - ys
        nx = np.where(dl < r, -(1 - dl / r), np.where(dr < r, (1 - dr / r), 0.0))
        ny = np.where(dt < r, -(1 - dt / r), np.where(db < r, (1 - db / r), 0.0))
        px_ = (xs - (mx + mw / 2)) / (mw / 2); py_ = (ys - (my + mh / 2)) / (mh / 2)          # a slow bow across the face
        return np.stack([nx * 0.45 + 0.22 * px_ ** 3, ny * 0.6 + 0.22 * py_ ** 3, np.ones_like(xs)], 1)
    with S.surf(nf=shell_n, z=66, g=0.2):
        S.paint(shell, "beige")
    S.tone(shell, 0.97 + 0.04 * np.random.default_rng(22).random((H, W)))
    S.shade((slice(my, my + mh), slice(mx + mw, mx + mw + 5), 0.45), "wall")                         # monitor's shadow on the wall
    # the bezel: a sloped frame falling toward the glass (it faces the tube, so it catches the screen's light)
    bx, by, bw, bh = sx - 9, sy - 9, sw + 18, sh + 18
    def bezel_n(xs, ys):
        cxm, cym = sx + sw / 2, sy + sh / 2
        ix = np.where(xs < sx, 1.0, np.where(xs > sx + sw, -1.0, 0.0))
        iy = np.where(ys < sy, 1.0, np.where(ys > sy + sh, -1.0, 0.0))
        return np.stack([ix * 0.75, iy * 0.75, np.ones_like(xs)], 1)
    with S.surf(nf=bezel_n, z=67, g=0.3):
        S.rect(bx, by, bw, bh, "beige_s")
    with S.surf(nf=bezel_n, z=66, g=0.2):
        S.rect(bx + 3, by + 3, bw - 6, bh - 6, "dgray")
    with S.surf(n=(0, 0, 1), z=68, g=1.0, d=False):
        S.rect(sx - 3, sy - 3, sw + 6, sh + 6, "glass")
        S.rect(sx, sy, sw, sh, "glass")
    with S.surf(n=(0, 0, 1), z=68, g=0.0, d=False):
        S.hline(sx - 1, sy - 2, 70, "glass_r"); S.vline(sx - 2, sy - 1, 40, "glass_r")                       # the curve of the glass catching the room
    # chin: tiny maker's mark, power light, brightness / contrast wheels
    chy = my + mh - 16
    ky_mark(mx + 14, chy + 4, "dgray"); text(mx + 28, chy + 5, "KI", "dgray")
    with S.surf(z=67, d=False, e="#2bb02b"): S.rect(mx + mw - 24, chy + 6, 3, 2, "led_g")
    for i in range(2):
        bevel_rect(mx + mw - 52 + i * 12, chy + 3, 7, 9, "beige_s", z=67, r=1, g=0.4)
        with S.surf(z=67, d=False):
            for yy in range(chy + 4, chy + 11, 2): S.hline(mx + mw - 51 + i * 12, yy, 5, "beige_d")


def vignette():
    e = np.minimum(np.minimum(XX + 0.5, W - XX - 0.5), np.minimum(YY + 0.5, (H - YY - 0.5) * 3))
    S.AO[...] = np.maximum(S.AO, np.clip(1 - e / 14.0, 0, 1) ** 1.5 * 0.45)


def _hex(c): return "#%02x%02x%02x" % tuple(int(v) for v in c)


def _lua(name, hexc):
    return "%s = { r = 0x%s / 255, g = 0x%s / 255, b = 0x%s / 255 }" % (name, hexc[1:3], hexc[3:5], hexc[5:7])


if __name__ == "__main__":
    import argparse, json
    ap = argparse.ArgumentParser(description="ZeD-UI main menu desk: the picture and its overlay pieces")
    ap.add_argument("--to", default=".", help="folder to write the textures into")
    ap.add_argument("--refit", action="store_true", help="fit a fresh palette instead of the locked one")
    args = ap.parse_args(); out = args.to
    os.makedirs(out, exist_ok=True)
    build_objects(); vignette()
    lit = S.light(RIG)
    dim = S.light(RIG, lamp_scale=0.32)                              # the lamp dipping: the whole room dips with it
    # the two blinking lights, off: dark lens plastic, no glow, in the room's light
    C_lit, E_off = S.C.copy(), S.E.copy()
    for (x0, y0), m in (((146, 246), "led_off_a"), ((300, 262), "led_off_g")):
        E_off[y0:y0 + 2, x0:x0 + 3] = 0; S.C[y0:y0 + 2, x0:x0 + 3] = S.idx[m]
    leds_off = S.light(RIG, emit=E_off)
    S.C[...] = C_lit
    # the lit lights and the needle keep their exact colours: one pinned palette entry each, its mean
    PINS = [(146, 246, 3, 2), (300, 262, 3, 2), (140, 246, 3, 2), (356, 224, 3, 2), (419, 121, 1, 8)]
    pins = [srgb(lit[y0:y0 + h0, x0:x0 + w0].reshape(-1, 3).mean(0)) for x0, y0, w0, h0 in PINS]
    fresh = np.zeros((H, W), bool)
    if args.refit or not os.path.exists(LOCK):
        pal = pal_fresh = S.palette_for([lit, dim], pins=pins)
        json.dump({"palette": [[float(v) for v in c] for c in pal]}, open(os.path.join(out, "palette.json"), "w"))
    else:
        # the approved room's palette for every pixel; the fresh materials' pixels may also use their own entries
        pal = np.asarray(json.load(open(LOCK))["palette"], np.float32)
        fresh = np.isin(S.C, [S.idx[n] for n in FRESH])
        X = np.vstack([srgb(f)[fresh] for f in (lit, dim)])
        X = np.unique(np.round(X * 255).astype(int), axis=0).astype(np.float32) / 255
        pal_fresh = np.vstack([pal, S.kmeans(X, FRESH_SLOTS, iters=20) if len(X) > FRESH_SLOTS else X])

    def quantize(frame):
        img_, _ = S.quantize(frame, palette=pal)
        if fresh.any(): img_ = np.where(fresh[..., None], S.quantize(frame, palette=pal_fresh)[0], img_)
        return img_
    img, img_dim = quantize(lit), quantize(dim)
    # the dial without its needle: paint the tuner face where the needle was, light it, cut the 7 x 10 box
    C0, T0, E0 = S.C.copy(), S.T.copy(), S.E.copy()
    S.C[121:129, 419] = S.idx["tuner"]; S.E[121:129, 419] = S.E[121:129, 418]; S.T[121:129, 419] = S.T[121:129, 418]
    img_noneedle = quantize(S.light(RIG))
    S.C[...], S.T[...], S.E[...] = C0, T0, E0
    Image.fromarray(img).save(os.path.join(out, "desk.png"))
    Image.fromarray(img_dim).save(os.path.join(out, "desk_lampdim.png"))
    Image.fromarray(img_dim[92:128, 60:102]).save(os.path.join(out, "lamp_dim.png"))
    Image.fromarray(img_noneedle[120:130, 416:423]).save(os.path.join(out, "dial_clean.png"))
    # what the code paints: a light that is off (the room's light on the dark lamp, unquantised mean),
    # the needle (exactly the baked one), and the margins (the picture's edge columns, each side)
    off = lambda x0, y0: _hex(np.round(srgb(leds_off[y0:y0 + 2, x0:x0 + 3].reshape(-1, 3).mean(0)) * 255))
    info = {
        "HDD_OFF": off(146, 246), "FLOPPY_OFF": off(300, 262),
        "HDD_ON": _hex(img[246, 147]), "FLOPPY_ON": _hex(img[262, 301]),
        "NEEDLE_C": _hex(img[124, 419]),
        "WALL_L": _hex(np.median(img[20:180, 0], axis=0)), "WALL_R": _hex(np.median(img[20:180, W - 1], axis=0)),
        "DESK_L": _hex(np.median(img[186:270, 0], axis=0)), "DESK_R": _hex(np.median(img[186:270, W - 1], axis=0)),
        "colours": int(len(np.unique(img.reshape(-1, 3), axis=0))),
    }
    info["lua"] = [_lua("local HDD_OFF   ", info["HDD_OFF"]), _lua("local FLOPPY_OFF", info["FLOPPY_OFF"]),
                   _lua("local NEEDLE_C  ", info["NEEDLE_C"]),
                   _lua("local WALL_L    ", info["WALL_L"]), _lua("local WALL_R    ", info["WALL_R"]),
                   _lua("local DESK_L    ", info["DESK_L"]), _lua("local DESK_R    ", info["DESK_R"])]
    json.dump(info, open(os.path.join(out, "desk_info.json"), "w"), indent=1)
    print("\n".join(info["lua"]))
