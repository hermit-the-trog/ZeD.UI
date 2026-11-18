"""ZeD overhead icons (the director, Nov 15 2026): the game's icons over the head (search mode, the car key, ...) in
ZeD's own art. One family with the overhead bubbles (ZeD_Bubbles, approved Oct 24): a small balloon with the bubbles'
stepped corners, 1-unit ink line, hard shadow and a tail to the head; the icon in it; a status square in its corner
where the answer is yes or no (a check or a cross, never colour alone). Design units; k = 2 at 4K as the bubbles.
(Nov 17 2026, the director: "Fix the sword handle and the bones. The bones need joints." The crossbones have a knobbed
joint at each end and cross behind the skull; the sword has a brass crossguard square to the blade, a wrapped grip and a
pommel. Drawn in fix_icons.py, pasted here. The noise icon is the director's twig, stepped on and snapping in half, a ! rising
from the snap and snap lines fanning out (twig.py, pasted here).)"""
import numpy as np
from PIL import Image

INK, FILL, PAPER = (10, 10, 10), (35, 37, 39), (232, 230, 224)
POS, NEG, WARN = (76, 194, 106), (222, 82, 72), (232, 168, 42)
SH = (0, 0, 0, 110)

PAL = {
    "k": INK, "w": PAPER, "W": (255, 255, 255), "g": (150, 152, 156), "G": (96, 98, 104), "d": (58, 60, 66),
    "h": (52, 53, 58), "H": (92, 94, 102), "m": (214, 218, 224), "M": (160, 165, 172), "n": (110, 114, 122),
    "b": (88, 128, 160), "B": (52, 84, 112), "y": (240, 196, 72), "Y": (196, 148, 40), "r": NEG, "e": POS,
    "o": (232, 134, 42), "c": (120, 186, 168), "C": (70, 134, 126), "s": (198, 168, 120), "S": (150, 118, 76),
    "R": (192, 28, 28),   # the light balloon's danger red (ZeD.Balloon.LIGHT.danger, C01C1C)
}

def sprite(rows, pal=PAL):
    h = len(rows); w = max(len(r) for r in rows)
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0)); px = im.load()
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch in pal: px[x, y] = (*pal[ch], 255)
    return im

ICON = {
"key": [
    ".kkkkkk..........",
    "kgwwwwgk.........",
    "kwggggGkkkkkkkkk.",
    "kwgkkgGkmmmmmmmmk",
    "kggkkgGkMMMMMMMMk",
    "kggggGGkMMMMMMMnk",
    "kGGGGGGkkMkkMkMk.",
    ".kkkkkk..kk.k.k..",
],
"eye": [
    "....kkkkkkkk....",
    "..kkwwwwwwwwkk..",
    ".kwwwwkkkkwwwwk.",
    "kwwwwkbbBBkwwwwk",
    "kwwwkbWbkBBkwwwk",
    "kwwwkbbkkBBkwwwk",
    "kwwwwkBBBBkwwwwk",
    ".kwwwwkkkkwwwwk.",
    "..kkwwwwwwwwkk..",
    "....kkkkkkkk....",
],
"eye_shut": [
    "................",
    "................",
    "................",
    "ww............ww",
    "..ww........ww..",
    "....wwwwwwww....",
    "...w..w..w..w...",
    "..w...w..w...w..",
    "................",
    "................",
],
"skull": [
    "...kk........kk...",
    "..kwwk......kwwk..",
    ".kkwwk......kwwkk.",
    "kwwwwk......kwwwwk",
    "kwwkwwkkkkkkwwkwwk",
    ".kk.kkwwwwwwkk.kk.",
    "....kwwwwwwwwk....",
    "....kwrrwwrrwk....",
    "....kwrrwwrrwk....",
    "....kwwwkkwwwk....",
    ".....kwwwwwwk.....",
    ".....kkwkkwkk.....",
    ".kk.kwkkkkkkwk.kk.",
    "kwwkwwk....kwwkwwk",
    "kwwwwk......kwwwwk",
    ".kkwwk......kwwkk.",
    "..kwwk......kwwk..",
    "...kk........kk...",
],
"speaker": [
    ".....k.........",
    "....kwk....w...",
    "...kwwk.....w..",
    "kkkwwwk..w...w.",
    "kwwwwwk...w..w.",
    "kwwwwwk...w..w.",
    "kkkwwwk..w...w.",
    "...kwwk.....w..",
    "....kwk....w...",
    ".....k.........",
],
"speaker_mute": [
    ".....k.........",
    "....kwk........",
    "...kwwk........",
    "kkkwwwk........",
    "kwwwwwk........",
    "kwwwwwk........",
    "kkkwwwk........",
    "...kwwk........",
    "....kwk........",
    ".....k.........",
],
# ---- the new ones (concepts)
"padlock": [
    "....kkkkkk....",
    "...kgggggk....",
    "..kgkkkkgk....",
    "..kgk..kgk....",
    "..kgk..kgk....",
    "kkkkkkkkkkkk..",
    "kyyyyyyyyyyk..",
    "kyyYkkkYyyyk..",
    "kyyYkkkYyyyk..",
    "kyyyYkYyyyyk..",
    "kyyyYkYyyyyk..",
    "kYYYYYYYYYYk..",
    "kkkkkkkkkkkk..",
],
"hotwire": [
    "......k.......",
    ".....kyk......",
    "....kyyk......",
    "...kyyyyyk....",
    ".....kyyk.....",
    ".....kyk......",
    "......k.......",
    "kkkkkk..kkkkkk",
    "rrrrSS..SSeeee",
    "kkkkkk..kkkkkk",
],
"noise": [
    "......................",
    "..........RR..........",
    "..........RR..........",
    "..........RR..........",
    ".....k....RR....k.....",
    "......k...RR...k......",
    ".......k..RR..k...k...",
    ".kk..............kskk.",
    "ksskk.....RR....kskssk",
    "kSSsskk......k.kkssSSk",
    ".kkSSsskk...kwkssSSkk.",
    "...kkSSswk..kwsSSkk...",
    ".....kkSwk..kwSkk.....",
    ".......kwk...kk.......",
    "........k.............",
],
"ammo_empty": [
    "..kk..",
    ".kyyk.",
    "kyyyyk",
    "kYyyYk",
    "kkkkkk",
    "kssssk",
    "kSsssk",
    "kSsssk",
    "kSsssk",
    "kSsssk",
    "kSSSSk",
    "kkkkkk",
],
"blade_crack": [
    "...............k.",
    ".............kkmk",
    "............kMmk.",
    "...........kMmk..",
    "..........kMnk...",
    ".........kMkk....",
    "........kMmk.....",
    "...kk..kMmk......",
    "..kYykkMmk.......",
    "...kYyMmk........",
    "....kYyk.........",
    "...kSsYyk........",
    "..ksSkkYyk.......",
    ".kSsk..kk........",
    "kyyk.............",
    "yYYk.............",
    "kYk..............",
],
"water_bad": [
    ".....k.....",
    "....kck....",
    "...kccck...",
    "..kccccck..",
    ".kcWcccCck.",
    ".kcccccCck.",
    "kccccccCCck",
    "kccccccCCck",
    "kcccccCCCck",
    ".kcccCCCck.",
    "..kkCCCkk..",
    "....kkk....",
],
"typing": [
    "..............",
    "..............",
    "kkk..kkk..kkk.",
    "kwk..kwk..kwk.",
    "kkk..kkk..kkk.",
],
"spotted": [
    "kkk",
    "kok",
    "kok",
    "kok",
    "kok",
    "kok",
    "kkk",
    "...",
    "kkk",
    "kok",
    "kkk",
],
}

CHECK = ["....w", "...ww", "w.ww.", "www..", ".w..."]
CROSS = ["w...w", ".w.w.", "..w..", ".w.w.", "w...w"]
BANG = [".w.", ".w.", ".w.", "...", ".w."]

def stepped(w, h, steps=(2, 1)):
    m = np.ones((h, w), bool)
    for j, s in enumerate(steps):
        m[j, :s] = m[j, w - s:] = False
        m[h - 1 - j, :s] = m[h - 1 - j, w - s:] = False
    return m

def badge(icon, status=None, dim=False, w=None, h=None, tail=True):
    """the balloon: body (w x h, ink line, fill), its tail centred under it, the icon centred, a status square
    (9 x 9, ink line) hanging off its bottom right corner"""
    ic = sprite(ICON[icon]) if isinstance(icon, str) else icon
    if dim:
        a = np.asarray(ic).astype(float); g = a[..., :3].mean(-1, keepdims=True); a[..., :3] = g * 0.55 + 18
        ic = Image.fromarray(a.astype(np.uint8), "RGBA")
    bw = w or max(22, ic.width + 8); bh = h or max(20, ic.height + 8)
    th = 4 if tail else 0
    S = 2                                                     # the shadow's offset
    CW, CH = bw + S + 4, bh + th + S + 4
    canvas = np.zeros((CH, CW, 4), np.uint8)
    body = np.zeros((CH, CW), bool); body[:bh, :bw] = stepped(bw, bh)
    if tail:
        cx = bw // 2
        for j in range(th + 1):
            hw = max(0, 3 - j)
            body[bh - 1 + j, cx - hw: cx + hw + 1] = True
    shadow = np.zeros_like(body); shadow[S:, S:] = body[:-S, :-S]
    canvas[shadow] = SH
    inner = body.copy()
    # the ink line: the body's edge
    e = body & ~(np.roll(body, 1, 0) & np.roll(body, -1, 0) & np.roll(body, 1, 1) & np.roll(body, -1, 1))
    canvas[body] = (*FILL, 255); canvas[e] = (*INK, 255)
    img = Image.fromarray(canvas, "RGBA")
    img.alpha_composite(ic, ((bw - ic.width) // 2, (bh - ic.height) // 2))
    if status:
        sq = np.zeros((9, 9, 4), np.uint8); sq[:] = (*INK, 255)
        sq[1:8, 1:8] = (*{"yes": POS, "no": NEG, "warn": WARN}[status], 255)
        g = {"yes": CHECK, "no": CROSS, "warn": BANG}[status]
        gx = (9 - len(g[0])) // 2
        for y, r in enumerate(g):
            for x, ch in enumerate(r):
                if ch == "w": sq[2 + y, gx + x] = (255, 255, 255, 255)
        # its shadow, then it
        sx, sy = bw - 6, bh - 7
        shm = Image.new("RGBA", (9, 9), SH)
        img.alpha_composite(shm, (sx + 2, sy + 2)); img.alpha_composite(Image.fromarray(sq, "RGBA"), (sx, sy))
    return img

def arrow(up):
    """the XP arrows beside the game's +5 Carpentry: a triangle, ink line, green up / red down, 9 x 7 in 13 x 13"""
    rows = ["....k....", "...kek...", "..keeek..", ".keeeeek.", "keeeeeeek", "kkkkkkkkk"] if up else \
           ["kkkkkkkkk", "krrrrrrrk", ".krrrrrk.", "..krrrk..", "...krk...", "....k...."]
    im = Image.new("RGBA", (13, 13), (0, 0, 0, 0)); im.alpha_composite(sprite(rows), (2, 3)); return im

SET = {
    # the game's own, redrawn
    "CarKey": dict(icon="key", status="yes"), "CarKey_none": dict(icon="key", status="no", dim=True),
    "eyeconOn": dict(icon="eye"), "eyeconOff": dict(icon="eye_shut"),
    "Skull": dict(icon="skull", tail=False), "voiceon": dict(icon="speaker"), "voicemuted": dict(icon="speaker_mute", status="no"),
    # new
    "door_key": dict(icon="padlock", status="yes"), "door_nokey": dict(icon="padlock", status="no"),
    "hotwire": dict(icon="hotwire", status="yes"), "noise": dict(icon="noise"),
    "gun_empty": dict(icon="ammo_empty", status="no"), "gun_jammed": dict(icon="ammo_empty", status="warn"),
    "weapon_breaking": dict(icon="blade_crack", status="warn"), "water_tainted": dict(icon="water_bad", status="no"),
    "typing": dict(icon="typing"), "spotted": dict(icon="spotted", w=14, h=20),
}
if __name__ == "__main__":
    out = {}
    for n, kw in SET.items():
        im = badge(**kw); im.save(f"art/overhead/{n}.png"); out[n] = im.size
    arrow(True).save("art/overhead/ArrowUp.png"); arrow(False).save("art/overhead/ArrowDown.png")
    print(out)
