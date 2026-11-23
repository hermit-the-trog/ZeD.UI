"""The height chart behind the body figure, in its frame (the director, Nov 22 2026: "This needs to fit in a half card
width. Draw a diagram background. Very simple, just to fill in the empty white space on each side.", then "I like A,
but I think it should have old handwritten script identifying each part. This does not need to be legible. This is
very much just a hint at that." and, of the mock, "I like it.").

The ruler's half-foot lines run on out across the frame's margins either side of the figure, each foot stronger than
the half between. The floor runs right across under the feet. A word of old script (d_script.py) sits on a line beside
each part: the parts on the character's right side, the neck and the belly at the left; the rest at the right. Each
word sits on the free half-foot line nearest its part's middle, flush with its margin's outer edge, so its line runs in
toward the part. All of it is in the ruler's ink (white on the dark bases, near-black on Light), tinted by the theme
like the ruler.

ZeD_BodyFigure:drawChart draws it in the frame's margins, whatever their width, in six draws: the twelve lines a side
are one picture, a column of their rows stretched along the side; the floor is two rectangles, either side of the
ruler's own floor tick; the script is two pictures a sex, one a side, shown where that side's lines are long enough for
its widest word.

The script's pictures go over the lines. A stroke on its own line has less alpha, so the two together come to the
script's alpha, as one layer would; a word reads the same on its line as off it, as in the mock the director passed.

Exports (into media/textures/ZeD/body/):
  fig-chart-lines.png                               the lines' column, 1 x 272, white: each line's alpha on its row
  fig-notes-<s>-left.png, fig-notes-<s>-right.png   the script, white; each side's words flush with its outer edge
  _chart.lua.txt                                    ZeD_BodyFigure.lua's CHART table
usage: python d_chart.py [mod root]   (default: out/mod/ZeD-UI)"""
import os
import sys

import numpy as np
from PIL import Image

import d_skeleton as S
import d_script as DS

# the lines, in the ruler's ink (alpha, tinted like the ruler): a foot stronger than the half between, the floor
# strongest
FOOT_A, HALF_A, FLOOR_A = 0.20, 0.10, 0.30
MARGIN = 2              # art pixels clear of the frame's inside edge and of the canvas (the ruler's numbers at its left)
NOTE_A = 0.30           # the script's alpha (a side shows its words where its lines are long enough for the widest)
INK_DARK = (255, 255, 255)
INK_LIGHT = (24, 24, 26)                            # the ruler's ink on Light (d_skeleton.background)
# the parts whose words go at the left: the character's right side (the viewer's left), and the neck and the belly
LEFT = {"neck", "low-torso", "bicep-r", "wrist-r", "hand-r", "thigh-r", "ankle-r", "foot-r"}


def row_ft(ft):
    """the canvas row of a height, as the ruler marks it"""
    return int(round(S.FLOOR - ft * S.PX_FT))


ROWS = [row_ft(k / 2) for k in range(1, 13)]        # half a foot to 6 ft, the ruler's ticks above the floor
ALPHAS = [FOOT_A if k % 2 == 0 else HALF_A for k in range(1, 13)]


def lines_column():
    """the lines' picture's alpha, 272 x 1: each line's alpha on its row (as the picture stores it, in 255ths)"""
    a = np.zeros((S.FH, 1), np.float32)
    for y, v in zip(ROWS, ALPHAS):
        a[y, 0] = round(v * 255) / 255
    return a


def floor_gap():
    """the columns where the ruler's floor tick and rail stand on the floor's row. The floor line leaves them be:
    over the ruler it would darken its floor tick, and the mock shows the tick as the ruler draws it. The same for both
    sexes and bases, and nothing else is drawn on that row."""
    gaps = set()
    for sex in ("m", "f"):
        for light in (False, True):
            a = np.asarray(S.background(sex, light))[..., 3]
            xs = np.nonzero(a[S.FLOOR])[0]
            assert len(xs) and xs.max() - xs.min() + 1 == len(xs), (sex, light, xs)
            gaps.add((int(xs.min()), int(xs.max()) + 1))
    assert len(gaps) == 1, gaps
    return gaps.pop()


_BODIES = {}


def _body(sex):
    import d_wounds as WD                           # each part's flesh and its middle (d_wounds.Body)
    if sex not in _BODIES:
        _BODIES[sex] = WD.Body(sex)
    return _BODIES[sex]


def placements(sex):
    """each side's words: [(part, word alpha (h x w, strokes at 1.0), baseline row in the word, line row)], the parts
    from the top down. Each word takes the free half-foot line nearest a little under its part's middle."""
    body = _body(sex)
    out = {}
    for side in ("L", "R"):
        parts = [p for p in S.PARTS if (p in LEFT) == (side == "L")]
        parts.sort(key=lambda p: body.axis[p][0][1])
        free = set(ROWS)
        out[side] = []
        for p in parts:
            seed = sum(map(ord, p)) * 7 + (13 if sex == "f" else 0)    # a part keeps its word; hers differ from his
            w, base = DS.word(seed, letters=3 + seed % 3)
            want = body.axis[p][0][1] + 2                              # the word's foot a little under the middle
            row = min(free, key=lambda r: abs(r - want))
            free.discard(row)
            out[side].append((p, w, base, row))
    return out


def notes(sex):
    """each side's picture: {side: (alpha h x w in 0..1, top row, width, height)}. Left: the words flush left; right:
    flush right. A stroke on a line of the chart carries (NOTE_A - a) / (1 - a) / NOTE_A of the script's alpha, so
    over the line a (drawn first, as its picture stores it) it comes to NOTE_A."""
    col = lines_column()[:, 0]
    line_a = {y: float(col[y]) for y in ROWS}
    line_a[S.FLOOR] = FLOOR_A
    out = {}
    for side, words in placements(sex).items():
        top = min(row - base for _, _, base, row in words)
        bot = max(row - base + w.shape[0] for _, w, base, row in words)
        wid = max(w.shape[1] for _, w, _, _ in words)
        a = np.zeros((bot - top, wid), np.float32)
        for _, w, base, row in words:
            y0 = row - base - top
            x0 = 0 if side == "L" else wid - w.shape[1]
            sub = a[y0:y0 + w.shape[0], x0:x0 + w.shape[1]]
            np.maximum(sub, w, out=sub)
        for r in range(a.shape[0]):
            la = line_a.get(top + r)
            if la is not None:
                a[r] *= max(0.0, NOTE_A - la) / (1.0 - la) / NOTE_A
        out["left" if side == "L" else "right"] = (a, top, wid, bot - top)
    return out


def approved(sex, sideL, sideR):
    """the chart as the mock the director passed lays it out (one layer of alpha, the lines and the words combined
    by the larger), over the frame's inside: sideL art pixels, the canvas (FW), sideR. drawChart must come to this."""
    W_ = sideL + S.FW + sideR
    a = np.zeros((S.FH, W_), np.float32)
    left = slice(MARGIN, max(MARGIN, sideL - MARGIN))
    right = slice(sideL + S.FW + MARGIN, W_ - MARGIN)
    for y, v in zip(ROWS, ALPHAS):
        a[y, left] = v
        a[y, right] = v
    a[S.FLOOR, MARGIN:W_ - MARGIN] = np.maximum(a[S.FLOOR, MARGIN:W_ - MARGIN], FLOOR_A)
    g0, g1 = floor_gap()
    c0, c1 = max(0, sideL + g0), max(0, sideL + g1)
    a[S.FLOOR, c0:c1] = 0.0                            # the ruler's floor tick: the figure's own there
    for side, words in placements(sex).items():
        line = (sideL if side == "L" else sideR) - 2 * MARGIN   # the side's lines' length
        if max(w.shape[1] for _, w, _, _ in words) > line:
            continue                                   # lines too short for its words: the side keeps its lines
        for _, w, base, row in words:
            h_, ww = w.shape
            x0 = MARGIN if side == "L" else W_ - MARGIN - ww
            sub = a[row - base:row - base + h_, x0:x0 + ww]
            np.maximum(sub, w * NOTE_A, out=sub)
    return a


def lua_table():
    """ZeD_BodyFigure.lua's CHART table"""
    g0, g1 = floor_gap()
    n = {sex: notes(sex) for sex in ("m", "f")}

    def f(v):
        return f"{v:.2f}"
    out = ["local CHART = {   -- generated by d_chart.py, in canvas (art) pixels",
           "    -- the half-foot lines are in their picture (fig-chart-lines.png, a column stretched along each side),",
           "    -- on rows " + ", ".join(str(r) for r in ROWS) + " (half a foot up to 6 ft, each foot stronger)",
           "    -- the floor under the soles: its row, its alpha, and the columns the ruler's own floor tick takes",
           f"    floor = {S.FLOOR}, floorA = {f(FLOOR_A)}, floorGap = {{ {g0}, {g1} }},",
           "    -- the art pixels the lines keep clear of the frame's line and of the canvas; the script's alpha",
           f"    margin = {MARGIN}, noteA = {f(NOTE_A)},",
           "    -- the ruler's ink on the dark bases and on Light (tinted by the theme)",
           "    inkDark = { 1, 1, 1 }, inkLight = { %d / 255, %d / 255, %d / 255 }," % INK_LIGHT,
           "    -- each side's script picture (fig-notes-<s>-<side>.png): its top row and its size",
           "    notes = {"]
    for sex in ("m", "f"):
        L_, R_ = n[sex]["left"], n[sex]["right"]
        out.append(f"        {sex} = {{ left = {{ y = {L_[1]}, w = {L_[2]}, h = {L_[3]} }}, "
                   f"right = {{ y = {R_[1]}, w = {R_[2]}, h = {R_[3]} }} }},")
    out += ["    },", "}"]
    return "\n".join(out) + "\n"


def export(root):
    """the five pictures and the table into root/42/media/textures/ZeD/body/; returns {sex: notes(sex)}"""
    d = os.path.join(root, "42", "media", "textures", "ZeD", "body")
    os.makedirs(d, exist_ok=True)
    col = np.zeros((S.FH, 1, 4), np.uint8)
    col[..., :3] = 255
    col[..., 3] = np.round(lines_column() * 255).astype(np.uint8)
    Image.fromarray(col, "RGBA").save(os.path.join(d, "fig-chart-lines.png"))
    made = {}
    for sex in ("m", "f"):
        made[sex] = notes(sex)
        for side, (a, _, _, _) in made[sex].items():
            img = np.zeros(a.shape + (4,), np.uint8)
            img[..., :3] = 255
            img[..., 3] = np.clip(np.round(a * 255), 0, 255).astype(np.uint8)
            Image.fromarray(img, "RGBA").save(os.path.join(d, f"fig-notes-{sex}-{side}.png"))
    with open(os.path.join(d, "_chart.lua.txt"), "w", newline="\n") as fh:
        fh.write(lua_table())
    return made


if __name__ == "__main__":
    root = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "out", "mod",
                                                                "ZeD-UI")
    export(root)
    print(lua_table())
