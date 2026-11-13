"""ZeDUI/workshop/controller_map/pixel_pad_v2.py  (Nov 12 2026)

The drawn controller of Options > Controls > Button map and test and of the quick wheel's Controller map, one drawing
for both windows. A port of drawPadBuffer in the approved mockup (ZeDUI/mockups/zed_controller_v1.html): the
200 x 136 art grid of the old controller_map.png, light from the top left (b0 rims up and left, b4 rims down and
right), 4 x 4 ordered dither for the shading, a hard black shadow down and right, a 1 px ink outline round the whole
silhouette, the Kentucky Instruments mark in the dark trim, no printed names (the labels carry them). The plastic is
the toned-down beige (the old controller map's beige x 0.80).

The game draws the 188 x 106 crop at (8, 21) at whole multiples only (k screen px to an art px, never smoothed), so
every file here is that crop, one art pixel to a texel, loaded with nearest filtering. Per variant (a button set and
where its left stick sits), in 42/media/textures/ZeD/pad/:

  zpad_<set>_<layout>.png         the resting pad (188 x 106)
  zpad_<set>_<layout>_parts.png   five 188 x 106 panels side by side (940 x 106), what the live test draws over it:
      0  under   the pad with the face buttons, View / Menu and the stick caps taken out (the wells empty); a held
                 button or a moved stick first covers its resting pixels with this
      1  caps    the two stick caps at rest with their shadows, clear elsewhere; a moved stick's cap is this moved
      2  shade   every part lit, at rest: white where the accent goes, gray 184 where the accent's dark dither goes
                 (accent x 0.72), gray 115 for the dark rims (x 0.45), clear elsewhere; drawn tinted with the accent
      3  light   the light rims of every lit part, white; drawn tinted with the accent mixed 38% toward white
      4  ink     the letters, PlayStation symbols and D-pad arrows of the lit parts, white; tinted with the ink that
                 sits on the accent
  A held part draws its own box of each panel: a face button or View / Menu its shade, light and ink 1 art px down
  and right (pressed, no shadow), after the under patch; a D-pad arm, a bumper in place; a trigger only its bottom
  round(pull x 7) rows of the 7 that show; a stick's cap moves by round(axis x (well radius - 9)), lit when clicked.

Variants: xbox with the left stick up top (as the real pad), PlayStation and Steam Deck in the house layout (D-pad up
top, both sticks in the middle), Nintendo with the left stick up top (as its Pro controller). The Deck and Nintendo
sets are ZeD_PadGlyphs' pictures on the drawing: dark discs with light letters; Nintendo's letters sit where its
pad has them (role A, the bottom button, reads B).

The shapes the mockup drew through the browser's canvas (the body's slab, lobes and bridge, the shoulders, View /
Menu: its staticMasks) are kept below as the browser drew them, row runs of art pixels. The canvas rasterizes its
curves partly by exact area and partly by sampling, so no plain rasterizer here lands on the same edge pixels; with
the browser's own masks the drawing matches the approved mockup pixel for pixel (checked in headless Edge for every
set, layout, plastic and lit state the mockup has). --capture redraws them from the mockup in headless Edge and
rewrites the block, for when the mockup's shapes change.

Run from the repo root (Pillow and numpy; the ComfyUI venv has both):
  python -I ZeDUI/workshop/controller_map/pixel_pad_v2.py            the game's files and the 4x previews here
  python -I ZeDUI/workshop/controller_map/pixel_pad_v2.py --check    also rebuild lit states from the written
                                                                     files the way the game draws them and compare
  python -I ZeDUI/workshop/controller_map/pixel_pad_v2.py --capture  first take the canvas shapes from the mockup
"""
import base64
import html as htmlmod
import json
import math
import os
import re
import subprocess
import sys
import tempfile

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
OUT = os.path.join(REPO, "42", "media", "textures", "ZeD", "pad")

GW, GH = 200, 136                 # the art grid
X0, Y0, CW, CH = 8, 21, 188, 106  # the crop the windows show
PANELS = ("under", "caps", "shade", "light", "ink")
SHADE_GRAY = {"base": 255, "dark": 184, "lo": 115}   # accent x 1, x 0.72, x 0.45 (the mockup's mixes toward black)
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def jsround(v):
    """Math.round: halves go up"""
    return int(math.floor(v + 0.5))


# ---- palettes --------------------------------------------------------------------------------------------------
BEIGE = dict(b0=(250, 245, 232), b1=(228, 220, 200), b2=(206, 197, 174), b3=(172, 162, 138), b4=(124, 115, 96),
             b5=(84, 77, 63))
PLASTICS = {
    "toned": {k: tuple(jsround(c * 0.80) for c in v) for k, v in BEIGE.items()},
    "beige": BEIGE,
    "graphite": dict(b0=(148, 148, 146), b1=(92, 92, 90), b2=(78, 78, 76), b3=(64, 64, 62), b4=(46, 46, 45),
                     b5=(32, 32, 31)),
}
INK, BLACK = (20, 20, 20), (0, 0, 0)
WHITE = (255, 255, 255)
XCOL = {"A": [(31, 122, 98), (18, 78, 62), (72, 170, 140), WHITE], "B": [(200, 32, 42), (132, 16, 24), (232, 84, 76), WHITE],
        "X": [(68, 136, 204), (40, 88, 150), (130, 180, 230), WHITE], "Y": [(204, 170, 34), (150, 120, 20), (240, 214, 110), INK]}
PSDISC = dict(base=(43, 43, 46), dark=(30, 30, 32), hi=(92, 92, 96), lo=(12, 12, 12))


def hexc(h):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


PSSYM = {"A": ("cross", hexc("7C9BF2")), "B": ("circ", hexc("F0505E")), "X": ("sq", hexc("EE8FD0")), "Y": ("tri", hexc("2FBF8F"))}
LETTER_DARK_DISC = (236, 236, 236)                  # ZeD_PadGlyphs' Deck and Nintendo letters
NIN_LETTER = {"A": "B", "B": "A", "X": "Y", "Y": "X"}   # the letter Nintendo prints in each place

F57 = {"A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
       "B": ["11110", "10001", "11110", "10001", "10001", "10001", "11110"],
       "X": ["10001", "10001", "01010", "00100", "01010", "10001", "10001"],
       "Y": ["10001", "10001", "01010", "00100", "00100", "00100", "00100"]}
SYM = {"tri": ["...X...", "..X.X..", "..X.X..", ".X...X.", ".X...X.", "XXXXXXX"],
       "circ": ["..XXX..", ".X...X.", "X.....X", "X.....X", "X.....X", ".X...X.", "..XXX.."],
       "cross": ["XX...XX", ".XX.XX.", "..XXX..", "...X...", "..XXX..", ".XX.XX.", "XX...XX"],
       "sq": ["XXXXXXX", "X.....X", "X.....X", "X.....X", "X.....X", "X.....X", "XXXXXXX"]}
KY = ["........##..", "......#####.", "....#######.", "..##########", ".#########..", "##########.."]
KI_K = ["101", "101", "110", "101", "101"]
KI_I = ["111", "010", "010", "010", "111"]


def accent_pal(accent_hex, theme):
    """the lit parts' colors, as the mockup mixes them from the accent"""
    a = hexc(accent_hex)

    def mix(b, t):
        return tuple(jsround(v + (b[i] - v) * t) for i, v in enumerate(a))
    return dict(base=a, dark=mix((0, 0, 0), .28), hi=mix((255, 255, 255), .38), lo=mix((0, 0, 0), .55),
                on=hexc("F2F0EC" if theme == "light" else "0C0C0C"))


# a palette of markers: every lit pixel says which tone it is (the parts panels are built from these)
MARK = dict(base=(255, 0, 0), dark=(0, 255, 0), hi=(0, 0, 255), lo=(255, 255, 0), on=(255, 0, 255))
MARK_TONE = {v: k for k, v in MARK.items()}


# ---- masks: a boolean grid the size of the art --------------------------------------------------------------------
def mk():
    return np.zeros((GH, GW), dtype=bool)


def bbox(m):
    ys, xs = np.nonzero(m)
    if len(xs) == 0:
        return (GW, GH, -1, -1)
    return (int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max()))


def inM(m, x, y):
    return 0 <= x < GW and 0 <= y < GH and bool(m[y, x])


def m_disc(cx, cy, r):
    m = mk()
    R = (r + .5) * (r + .5) - .3
    for y in range(cy - r - 1, cy + r + 2):
        for x in range(cx - r - 1, cx + r + 2):
            if (x - cx) ** 2 + (y - cy) ** 2 <= R and 0 <= x < GW and 0 <= y < GH:
                m[y, x] = True
    return m


def m_ring(cx, cy, r):
    m = mk()
    for y in range(cy - r - 1, cy + r + 2):
        for x in range(cx - r - 1, cx + r + 2):
            d = math.sqrt((x - cx) ** 2 + (y - cy) ** 2)
            if abs(d - r) < .5 and 0 <= x < GW and 0 <= y < GH:
                m[y, x] = True
    return m


def m_rects(rs):
    m = mk()
    for (x0, y0, x1, y1) in rs:
        m[max(0, y0):y1 + 1, max(0, x0):x1 + 1] = True
    return m


# ---- the canvas shapes, as the browser drew them --------------------------------------------------------------------
# One string per shape: rows "y:x0-x1 x0-x1" (inclusive art pixel runs) joined by ";". --capture rewrites the block.
# >>> captured canvas masks
CANVAS_MASKS = {
    "body": (
        "38:32-168;39:29-171;40:26-174;41:24-176;42:23-177;43:21-179;44:20-180;45:19-181;46:18-182;47:17-183;"
        "48:16-184;49:15-185;50:15-185;51:14-186;52:14-186;53:13-187;54:13-187;55:13-187;56:12-188;57:12-188;"
        "58:12-188;59:11-189;60:11-189;61:11-189;62:11-189;63:11-189;64:11-189;65:11-189;66:11-189;67:11-189;"
        "68:11-189;69:11-189;70:11-189;71:11-189;72:11-189;73:11-189;74:11-189;75:11-189;76:11-189;77:11-189;"
        "78:11-189;79:11-189;80:11-189;81:11-189;82:11-189;83:12-188;84:12-188;85:12-188;86:12-188;87:12-188;"
        "88:12-188;89:12-188;90:12-188;91:12-188;92:12-188;93:13-187;94:13-187;95:13-187;96:13-187;97:14-186;"
        "98:14-186;99:14-186;100:15-185;101:15-185;102:16-184;103:16-184;104:17-183;105:17-183;106:18-182;"
        "107:19-181;108:19-181;109:20-180;110:21-179;111:22-178;112:23-177;113:24-176;114:26-82 118-174;"
        "115:27-77 123-173;116:29-75 125-171;117:31-73 127-169;118:33-71 129-167;119:36-68 132-164;"
        "120:40-64 136-160;121:48-56 144-152"
    ),
    "trigL": (
        "24:38-55;25:36-57;26:35-58;27:35-58;28:34-59;29:34-59;30:34-59;31:34-59;32:34-59;33:34-59;34:34-59;"
        "35:34-59;36:34-59;37:35-58;38:35-58;39:36-57;40:38-55"
    ),
    "trigR": (
        "24:145-162;25:143-164;26:142-165;27:142-165;28:141-166;29:141-166;30:141-166;31:141-166;32:141-166;"
        "33:141-166;34:141-166;35:141-166;36:141-166;37:142-165;38:142-165;39:143-164;40:145-162"
    ),
    "bumpL": (
        "31:33-73;32:31-75;33:31-75;34:30-76;35:30-76;36:30-76;37:30-76;38:31-75;39:31-75;40:33-73"
    ),
    "bumpR": (
        "31:127-167;32:125-169;33:125-169;34:124-170;35:124-170;36:124-170;37:124-170;38:125-169;39:125-169;"
        "40:127-167"
    ),
    "SEL": (
        "65:80-88;66:79-89;67:79-89;68:79-89;69:80-88"
    ),
    "START": (
        "65:112-120;66:111-121;67:111-121;68:111-121;69:112-120"
    ),
}
# <<< captured canvas masks
CANVAS_NAMES = ("body", "trigL", "trigR", "bumpL", "bumpR", "SEL", "START")


def rle_encode(m):
    rows = []
    for y in range(GH):
        xs = np.nonzero(m[y])[0].tolist()
        if not xs:
            continue
        runs, start, prev = [], xs[0], xs[0]
        for x in xs[1:]:
            if x != prev + 1:
                runs.append((start, prev))
                start = x
            prev = x
        runs.append((start, prev))
        rows.append("%d:%s" % (y, " ".join("%d-%d" % r for r in runs)))
    return ";".join(rows)


def rle_decode(s):
    m = mk()
    for row in s.split(";"):
        y, runs = row.split(":")
        for r in runs.split():
            x0, x1 = r.split("-")
            m[int(y), int(x0):int(x1) + 1] = True
    return m


_STATIC = {}


def static_masks():
    if not _STATIC:
        if not CANVAS_MASKS:
            sys.exit("no canvas masks yet: run with --capture (needs Microsoft Edge)")
        for k in CANVAS_NAMES:
            _STATIC[k] = rle_decode(CANVAS_MASKS[k])
    return _STATIC


EDGE = (r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe", r"C:\Program Files\Microsoft\Edge\Application\msedge.exe")
CAPTURE_JS = r"""
<script>
(function () {
  function b64(u8) { let s = ""; for (let i = 0; i < u8.length; i += 0x8000) s += String.fromCharCode.apply(null, u8.subarray(i, i + 0x8000)); return btoa(s); }
  const M = staticMasks(), out = {};
  for (const k of %s) out[k] = b64(new Uint8Array(M[k].buffer.slice(0)));
  const pre = document.createElement("pre"); pre.id = "zedmasks"; pre.textContent = JSON.stringify(out); document.body.appendChild(pre);
})();
</script>
"""


def capture():
    """the mockup's staticMasks() as headless Edge draws them, written into the block above"""
    mockup = os.path.join(REPO, "ZeDUI", "mockups", "zed_controller_v1.html")
    edge = next((e for e in EDGE if os.path.exists(e)), None)
    if not edge:
        sys.exit("--capture needs Microsoft Edge")
    page = open(mockup, encoding="utf-8").read()
    i = page.rfind("</body>")
    tmp = tempfile.mkdtemp()
    path = os.path.join(tmp, "masks.html")
    with open(path, "w", encoding="utf-8") as f:
        f.write(page[:i] + CAPTURE_JS % json.dumps(list(CANVAS_NAMES)) + page[i:])
    dom = subprocess.run([edge, "--headless", "--disable-gpu", "--no-first-run", "--user-data-dir=" + os.path.join(tmp, "profile"),
                          "--virtual-time-budget=8000", "--dump-dom", "file:///" + path.replace("\\", "/")],
                         capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=180).stdout
    m = re.search(r'<pre id="zedmasks">(.*?)</pre>', dom, re.S)
    if not m:
        sys.exit("--capture: the mockup gave no masks")
    data = json.loads(htmlmod.unescape(m.group(1)))
    lines = ["CANVAS_MASKS = {"]
    for k in CANVAS_NAMES:
        mask = np.frombuffer(base64.b64decode(data[k]), dtype=np.uint8).reshape(GH, GW) > 0
        enc = rle_encode(mask)
        lines.append('    "%s": (' % k)
        chunk = ""
        for part in enc.split(";"):
            piece = part + ";"
            if len(chunk) + len(piece) > 104:
                lines.append('        "%s"' % chunk)
                chunk = ""
            chunk += piece
        lines.append('        "%s"' % chunk.rstrip(";"))
        lines.append("    ),")
        CANVAS_MASKS[k] = enc
    lines.append("}")
    src_path = os.path.abspath(__file__)
    src = open(src_path, encoding="utf-8").read()
    a = src.index("# >>> captured canvas masks\n") + len("# >>> captured canvas masks\n")
    b = src.index("# <<< captured canvas masks")
    with open(src_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(src[:a] + "\n".join(lines) + "\n" + src[b:])
    _STATIC.clear()
    print("captured", ", ".join(CANVAS_NAMES), "from the mockup")


# ---- where the parts sit ------------------------------------------------------------------------------------------
def geo(layout):
    """house: the D-pad in the left lobe, both sticks in the middle; stickup: the left stick in the lobe, the D-pad
    where the left stick was"""
    off = layout == "stickup"
    return dict(off=off, dpad=(84, 93) if off else (50, 71), ls=(50, 71, 15) if off else (84, 92, 13), rs=(116, 92, 13),
                face=(150, 71), btn={"Y": (150, 59), "A": (150, 83), "X": (138, 71), "B": (162, 71)})


# ---- drawing --------------------------------------------------------------------------------------------------------
class Pad:
    def __init__(self):
        self.buf = np.zeros((GH, GW, 4), dtype=np.uint8)

    def put(self, x, y, c):
        if 0 <= x < GW and 0 <= y < GH:
            self.buf[y, x, 0:3] = c
            self.buf[y, x, 3] = 255

    def shade(self, m, base, dark, t0, t1, y0, y1, hi, lo, lo2=None, clip=None, dx=0, dy=0):
        """fill a mask: base dithered toward dark from t0 (top) to t1 (bottom); a light rim where the pixel above or
        to the left is outside, a dark rim where the pixel below or to the right is"""
        bx0, by0, bx1, by1 = bbox(m)
        for y in range(by0, by1 + 1):
            for x in range(bx0, bx1 + 1):
                if not m[y, x] or (clip and not clip(x, y)):
                    continue
                f = (y - y0) / max(1, y1 - y0)
                t = t0 + (t1 - t0) * min(1.0, max(0.0, f))
                c = dark if (BAYER[y & 3][x & 3] + .5) / 16 < t else base
                rim = False
                if not inM(m, x, y - 1) or not inM(m, x - 1, y):
                    c, rim = hi, True
                if not inM(m, x, y + 1) or not inM(m, x + 1, y):
                    c, rim = lo, True
                if lo2 is not None and not rim and (not inM(m, x, y + 2) or not inM(m, x + 2, y)):
                    c = lo2
                self.put(x + dx, y + dy, c)

    def hard_shadow(self, m, dx, dy):
        bx0, by0, bx1, by1 = bbox(m)
        for y in range(by0, by1 + 1):
            for x in range(bx0, bx1 + 1):
                if m[y, x] and not inM(m, x + dx, y + dy):
                    self.put(x + dx, y + dy, BLACK)

    def well(self, m, base, C):
        """a recessed well: darker rim up and left (the shadow inside), a light lip down and right"""
        bx0, by0, bx1, by1 = bbox(m)
        for y in range(by0, by1 + 1):
            for x in range(bx0, bx1 + 1):
                if not m[y, x]:
                    continue
                c = base
                if not inM(m, x, y - 1) or not inM(m, x - 1, y):
                    c = C["b4"]
                elif not inM(m, x, y - 2) or not inM(m, x - 2, y):
                    c = C["b3"]
                if not inM(m, x, y + 1) or not inM(m, x + 1, y):
                    c = C["b0"]
                self.put(x, y, c)

    def stamp(self, rows, x0, y0, c):
        for j, r in enumerate(rows):
            for i, ch in enumerate(r):
                if ch in "1X#":
                    self.put(x0 + i, y0 + j, c)

    def outline(self):
        """one ink pixel round everything"""
        a = self.buf[:, :, 3] > 0
        near = np.zeros_like(a)
        near[:, 1:] |= a[:, :-1]
        near[:, :-1] |= a[:, 1:]
        near[1:, :] |= a[:-1, :]
        near[:-1, :] |= a[1:, :]
        ring = near & ~a
        self.buf[ring, 0:3] = INK
        self.buf[ring, 3] = 255


ARMS = ("DU", "DD", "DL", "DR")


def arm_rects(dx, dy):
    return {"DU": (dx - 4, dy - 13, dx + 4, dy - 5), "DD": (dx - 4, dy + 5, dx + 4, dy + 13),
            "DL": (dx - 13, dy - 4, dx - 5, dy + 4), "DR": (dx + 5, dy - 4, dx + 13, dy + 4)}


def face_look(set_, r):
    """a face button at rest: (base, dark, hi, lo, glyph rows, glyph x, glyph color)"""
    if set_ == "xbox":
        c = XCOL[r]
        return c[0], c[1], c[2], c[1], F57[r], 2, c[3]
    if set_ == "ps":
        sym, col = PSSYM[r]
        return PSDISC["base"], PSDISC["dark"], PSDISC["hi"], PSDISC["lo"], SYM[sym], 3, col
    letter = NIN_LETTER[r] if set_ == "nin" else r
    return PSDISC["base"], PSDISC["dark"], PSDISC["hi"], PSDISC["lo"], F57[letter], 2, LETTER_DARK_DISC


def draw_pad(st, set_, layout, plastic, AC, skip=(), press=True):
    """the whole drawing for one moment of input; st: { b: {role: held}, ls: (x, y), rs: (x, y), lt, rt }. skip:
    leave out "face" (the face buttons), "keys" (View / Menu), "caps" (the stick caps) or "body" (all but the
    caps). press=False draws a held face button or key lit where it rests (the parts panels)"""
    p = Pad()
    sink = 1 if press else 0
    M, C, G = static_masks(), PLASTICS[plastic], geo(layout)
    b = st.get("b", {})
    if "body" not in skip:
        # shoulders: the trigger, then the bumper over it
        for side in ("L", "R"):
            T, B = M["trig" + side], M["bump" + side]
            pull = st.get("lt" if side == "L" else "rt", 0)
            p.hard_shadow(T, 2, 2)
            p.shade(T, C["b4"], C["b5"], 0, .35, 24, 40, C["b3"], INK)
            if pull > .02:
                n = max(1, jsround(pull * 7))
                p.shade(T, AC["base"], AC["dark"], 0, .35, 24, 40, AC["hi"], AC["lo"], None, lambda x, y, n=n: y >= 31 - n)
            p.hard_shadow(B, 2, 2)
            if b.get(side + "B"):
                p.shade(B, AC["base"], AC["dark"], 0, .45, 31, 40, AC["hi"], AC["lo"], AC["dark"])
            else:
                p.shade(B, C["b2"], C["b3"], 0, .45, 31, 40, C["b0"], C["b4"], C["b3"])
        # the body
        p.hard_shadow(M["body"], 3, 3)
        p.shade(M["body"], C["b1"], C["b2"], .05, .75, 38, 150, C["b0"], C["b4"], C["b3"])
        # the maker's mark: Kentucky Instruments, the state then KI, in the dark trim
        p.stamp(KY, 90, 49, C["b5"])
        p.stamp(KI_K, 104, 50, C["b5"])
        p.stamp(KI_I, 108, 50, C["b5"])
        # the D-pad: a well, the cross, each arm with a pressed-in arrow; a held arm in the accent
        dx, dy = G["dpad"]
        p.well(m_disc(dx, dy, 17), C["b2"], C)
        cross = m_rects([(dx - 4, dy - 13, dx + 4, dy + 13), (dx - 13, dy - 4, dx + 13, dy + 4)])
        p.hard_shadow(cross, 1, 1)
        p.shade(cross, C["b5"], C["b5"], 0, 0, 0, 1, C["b4"], INK)
        for a, r in arm_rects(dx, dy).items():
            if b.get(a):
                p.shade(cross, AC["base"], AC["base"], 0, 0, 0, 1, AC["hi"], AC["lo"], None,
                        lambda x, y, r=r: r[0] <= x <= r[2] and r[1] <= y <= r[3])
        for (a, ax, ay, vx, vy) in (("DU", 0, -10, 0, 1), ("DD", 0, 10, 0, -1), ("DL", -10, 0, 1, 0), ("DR", 10, 0, -1, 0)):
            tx, ty = dx + ax, dy + ay
            c = AC["on"] if b.get(a) else C["b3"]
            for k in range(3):
                for s in range(-k, k + 1):
                    if vx == 0:
                        p.put(tx + s, ty + k * vy, c)
                    else:
                        p.put(tx + k * vx, ty + s, c)
        p.put(dx, dy, C["b4"])
        # the face buttons' well
        p.well(m_disc(G["face"][0], G["face"][1], 21), C["b2"], C)
    if "body" not in skip and "face" not in skip:
        for r in ("Y", "X", "B", "A"):
            cx, cy = G["btn"][r]
            m = m_disc(cx, cy, 6)
            on = bool(b.get(r))
            d = sink if on else 0
            base, dark, hi, lo, rows, gx, gc = face_look(set_, r)
            if not on:
                p.hard_shadow(m, 1, 1)
            if on:
                p.shade(m, AC["base"], AC["dark"], 0, .5, cy - 6, cy + 6, AC["hi"], AC["lo"], None, None, d, d)
            else:
                p.shade(m, base, dark, 0, .5, cy - 6, cy + 6, hi, lo)
            p.stamp(rows, cx - gx + d, cy - 3 + d, AC["on"] if on else gc)
    if "body" not in skip and "keys" not in skip:
        # View / Menu (Create / Options): small dark keys
        for r in ("SEL", "START"):
            m = M[r]
            on = bool(b.get(r))
            if not on:
                p.hard_shadow(m, 1, 1)
            if on:
                p.shade(m, AC["base"], AC["base"], 0, 0, 0, 1, AC["hi"], AC["lo"], None, None, sink, sink)
            else:
                p.shade(m, C["b4"], C["b4"], 0, 0, 0, 1, C["b3"], C["b5"])
    # the sticks: a well, the cap where the stick points, a click lights the cap
    for sid in ("LS", "RS"):
        cx, cy, wr = G["ls"] if sid == "LS" else G["rs"]
        v = st.get("ls" if sid == "LS" else "rs", (0, 0))
        on = bool(b.get("L3" if sid == "LS" else "R3"))
        if "body" not in skip:
            p.well(m_disc(cx, cy, wr), C["b3"], C)
        if "caps" in skip:
            continue
        maxo = wr - 9
        x, y = cx + jsround(v[0] * maxo), cy + jsround(v[1] * maxo)
        cap = m_disc(x, y, 9)
        p.hard_shadow(cap, 1, 1)
        if on:
            p.shade(cap, AC["base"], AC["dark"], 0, .5, y - 9, y + 9, AC["hi"], AC["lo"])
        else:
            p.shade(cap, C["b5"], C["b5"], 0, 0, y - 9, y + 9, C["b4"], INK)
        ring = m_ring(x, y, 5)
        rx0, ry0, rx1, ry1 = bbox(ring)
        for yy in range(ry0, ry1 + 1):
            for xx in range(rx0, rx1 + 1):
                if ring[yy, xx]:
                    even = (xx + yy) % 2 == 0
                    p.put(xx, yy, (AC["dark"] if on else C["b4"]) if even else (AC["lo"] if on else C["b5"]))
        for (gx, gy) in ((-4, -6), (-5, -5), (-6, -4)):
            p.put(x + gx, y + gy, AC["hi"] if on else C["b3"])
    if "body" not in skip:
        p.outline()
    return p.buf


REST = dict(b={}, ls=(0, 0), rs=(0, 0), lt=0, rt=0)
ALL_LIT = dict(b={k: True for k in ("A", "B", "X", "Y", "LB", "RB", "SEL", "START", "DU", "DD", "DL", "DR", "L3", "R3")},
               ls=(0, 0), rs=(0, 0), lt=1, rt=1)


def lit_tones(set_, layout):
    """the tone of every lit pixel that shows: the whole pad drawn with everything held (the triggers full, nothing
    pressed in) in marker colors, so what the body covers of a bumper, or a bumper of a trigger, stays covered;
    '' where nothing lit shows"""
    buf = draw_pad(ALL_LIT, set_, layout, "toned", MARK, press=False)
    tones = np.full((GH, GW), "", dtype=object)
    for yy in range(GH):
        for xx in range(GW):
            t = MARK_TONE.get(tuple(int(v) for v in buf[yy, xx, 0:3])) if buf[yy, xx, 3] else None
            if t:
                tones[yy, xx] = t
    return tones


def crop(buf):
    return buf[Y0:Y0 + CH, X0:X0 + CW]


def parts_atlas(set_, layout, plastic):
    """the five panels side by side (see the top of this file)"""
    under = draw_pad(REST, set_, layout, plastic, accent_pal("#47A18C", "dark"), skip=("face", "keys", "caps"))
    caps = draw_pad(REST, set_, layout, plastic, accent_pal("#47A18C", "dark"), skip=("body",))
    tones = lit_tones(set_, layout)
    shade = np.zeros((GH, GW, 4), dtype=np.uint8)
    light = np.zeros((GH, GW, 4), dtype=np.uint8)
    ink = np.zeros((GH, GW, 4), dtype=np.uint8)
    for yy in range(GH):
        for xx in range(GW):
            t = tones[yy, xx]
            if t in SHADE_GRAY:
                g = SHADE_GRAY[t]
                shade[yy, xx] = (g, g, g, 255)
            elif t == "hi":
                light[yy, xx] = (255, 255, 255, 255)
            elif t == "on":
                ink[yy, xx] = (255, 255, 255, 255)
    return np.concatenate([crop(under), crop(caps), crop(shade), crop(light), crop(ink)], axis=1)


# the variants the game draws: the glyph set, and where its left stick sits
VARIANTS = [("xbox", "stickup"), ("ps", "house"), ("deck", "house"), ("nin", "stickup")]
PREVIEWS = VARIANTS + [("xbox", "house")]


def save_png(arr, path):
    Image.fromarray(arr, "RGBA").save(path, optimize=True)


def write_all():
    os.makedirs(OUT, exist_ok=True)
    for set_, layout in VARIANTS:
        rest = draw_pad(REST, set_, layout, "toned", accent_pal("#47A18C", "dark"))
        save_png(np.ascontiguousarray(crop(rest)), os.path.join(OUT, "zpad_%s_%s.png" % (set_, layout)))
        save_png(np.ascontiguousarray(parts_atlas(set_, layout, "toned")), os.path.join(OUT, "zpad_%s_%s_parts.png" % (set_, layout)))
        print("written zpad_%s_%s.png and _parts.png" % (set_, layout))
    # for review: every set and layout at 4x, resting and with everything lit in PZ Teal
    for set_, layout in PREVIEWS:
        rest = crop(draw_pad(REST, set_, layout, "toned", accent_pal("#47A18C", "dark")))
        lit = crop(draw_pad(ALL_LIT, set_, layout, "toned", accent_pal("#47A18C", "dark")))
        sheet = np.concatenate([rest, np.zeros((CH, 8, 4), dtype=np.uint8), lit], axis=1)
        im = Image.fromarray(np.ascontiguousarray(sheet), "RGBA")
        im.resize((im.width * 4, im.height * 4), Image.NEAREST).save(
            os.path.join(HERE, "pad_v2_%s_%s_4x.png" % (set_, layout)), optimize=True)
    print("previews written to", HERE)


# ---- the check: lit states rebuilt from the written files the way the game draws them ---------------------------------
def compose(set_, layout, st, theme_accent):
    """the game's plan (ZeD_PadFigure.draw): the resting pad, the under patches of what moved, then each lit part's
    boxes of shade, light and ink (tinted), a moved cap from the caps panel"""
    accent_hex, theme = theme_accent
    rest = np.array(Image.open(os.path.join(OUT, "zpad_%s_%s.png" % (set_, layout))).convert("RGBA")).astype(np.float64)
    parts = np.array(Image.open(os.path.join(OUT, "zpad_%s_%s_parts.png" % (set_, layout))).convert("RGBA")).astype(np.float64)
    P = {name: parts[:, i * CW:(i + 1) * CW] for i, name in enumerate(PANELS)}
    AC = accent_pal(accent_hex, theme)
    a = np.array(AC["base"], dtype=np.float64) / 255.0
    hi = a + (1 - a) * .38
    on = np.array(AC["on"], dtype=np.float64) / 255.0
    out = rest.copy()
    G = geo(layout)
    b = st.get("b", {})

    def blit(panel, box, ox=0, oy=0, mul=None):
        x0, y0, x1, y1 = box
        src = P[panel][y0 - Y0:y1 - Y0 + 1, x0 - X0:x1 - X0 + 1]
        dst = out[y0 - Y0 + oy:y1 - Y0 + 1 + oy, x0 - X0 + ox:x1 - X0 + 1 + ox]
        alpha = src[..., 3:4] / 255.0
        col = src[..., :3] if mul is None else np.round(src[..., :3] * mul)
        dst[..., :3] = np.round(col * alpha + dst[..., :3] * (1 - alpha))
        dst[..., 3:4] = np.maximum(dst[..., 3:4], src[..., 3:4])

    def lit(box, ox=0, oy=0, inked=True):
        blit("shade", box, ox, oy, a)
        blit("light", box, ox, oy, hi)
        if inked:
            blit("ink", box, ox, oy, on)
    pressed = [r for r in ("A", "B", "X", "Y") if b.get(r)]
    keys = {"SEL": (79, 65, 89, 69), "START": (111, 65, 121, 69)}
    for r in pressed:
        cx, cy = G["btn"][r]
        blit("under", (cx - 6, cy - 6, cx + 7, cy + 7))
    for r, bx in keys.items():
        if b.get(r):
            blit("under", (bx[0], bx[1], bx[2] + 1, bx[3] + 1))
    caps = {}
    for sid in ("LS", "RS"):
        cx, cy, wr = G["ls"] if sid == "LS" else G["rs"]
        v = st.get("ls" if sid == "LS" else "rs", (0, 0))
        ox, oy = jsround(v[0] * (wr - 9)), jsround(v[1] * (wr - 9))
        caps[sid] = (cx, cy, ox, oy, bool(b.get("L3" if sid == "LS" else "R3")))
        if ox or oy:
            blit("under", (cx - 9, cy - 9, cx + 10, cy + 10))
    for r in pressed:
        cx, cy = G["btn"][r]
        lit((cx - 6, cy - 6, cx + 6, cy + 6), 1, 1)
    for r, bx in keys.items():
        if b.get(r):
            lit(bx, 1, 1, False)
    for a_, r in arm_rects(*G["dpad"]).items():
        if b.get(a_):
            lit(r)
    for side, bx in (("L", (30, 31, 76, 40)), ("R", (124, 31, 170, 40))):
        if b.get(side + "B"):
            lit(bx, inked=False)
    for side, bx in (("L", (34, 24, 59, 30)), ("R", (141, 24, 166, 30))):
        pull = st.get("lt" if side == "L" else "rt", 0)
        if pull > .02:
            n = max(1, jsround(pull * 7))
            lit((bx[0], 31 - n, bx[2], 30), inked=False)
    for sid, (cx, cy, ox, oy, on_) in caps.items():
        if ox or oy:
            blit("caps", (cx - 9, cy - 9, cx + 10, cy + 10), ox, oy)
        if on_:
            lit((cx - 9, cy - 9, cx + 9, cy + 9), ox, oy, False)
    return out.astype(np.uint8)


def check():
    """rebuild lit states from the files and compare with the drawing itself (moved caps excluded: the game moves the
    cap's own sprite, so its dither and ring keep their phase where the drawing redraws them)"""
    states = {
        "all": ALL_LIT,
        "one": dict(b={"A": True, "DL": True, "RB": True}, ls=(0, 0), rs=(0, 0), lt=0, rt=0),
        "pull": dict(b={"SEL": True, "L3": True}, ls=(0, 0), rs=(0, 0), lt=.5, rt=.03),
    }
    worst, bad = 0, 0
    for set_, layout in VARIANTS:
        for accent in (("#47A18C", "dark"), ("#7A5010", "light"), ("#D4922A", "dark")):
            for name, st in states.items():
                want = crop(draw_pad(st, set_, layout, "toned", accent_pal(*accent))).astype(np.int32)
                got = compose(set_, layout, st, accent).astype(np.int32)
                diff = np.abs(want - got).max(axis=2)
                worst = max(worst, int(diff.max()))
                if diff.max() > 1:
                    bad += 1
                    ys, xs = np.nonzero(diff > 1)
                    print("  differs:", set_, layout, accent, name, "at", list(zip((xs + X0).tolist(), (ys + Y0).tolist()))[:8])
    # a moved stick: everything but the cap's own box matches
    st = dict(b={"R3": True}, ls=(1, 0), rs=(0, -1), lt=0, rt=0)
    for set_, layout in VARIANTS:
        want = crop(draw_pad(st, set_, layout, "toned", accent_pal("#47A18C", "dark"))).astype(np.int32)
        got = compose(set_, layout, st, ("#47A18C", "dark")).astype(np.int32)
        diff = np.abs(want - got).max(axis=2) > 1
        G = geo(layout)
        for sid, v in (("LS", (1, 0)), ("RS", (0, -1))):
            cx, cy, wr = G["ls"] if sid == "LS" else G["rs"]
            x, y = cx + jsround(v[0] * (wr - 9)), cy + jsround(v[1] * (wr - 9))
            diff[y - 9 - Y0:y + 10 - Y0 + 1, x - 9 - X0:x + 10 - X0 + 1] = False
        if diff.any():
            bad += 1
            ys, xs = np.nonzero(diff)
            print("  moved stick differs outside its cap:", set_, layout, list(zip((xs + X0).tolist(), (ys + Y0).tolist()))[:8])
    print("check: %s (largest channel difference %d, tint rounding allows 1)" % ("PASS" if bad == 0 else "FAIL", worst))
    return bad == 0


if __name__ == "__main__":
    if "--capture" in sys.argv:
        capture()
    write_all()
    if "--check" in sys.argv:
        sys.exit(0 if check() else 1)
