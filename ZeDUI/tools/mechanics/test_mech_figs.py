"""Checks the Vehicle tab's car figures as installed (Car parts drawn, Nov 23 2026): the table and the textures agree,
the figure is no bigger than before (so the tab's zoom holds), every drawn part is its drawing, the side columns are
in order and mirrored, and the glass's wear is cracks cut inside the pane.

usage: py test_mech_figs.py [DIR]
  DIR: a stage (DIR/42/media/textures/ZeD/mech and DIR/42/media/lua/client/ZeD/MechFigs.lua) or a bake
  (DIR/textures and DIR/MechFigs.lua, as pixel_mech_figs.py writes it); none: the repo's installed art.
  Prints each failure and "N checks, M failed"; exits 1 when any failed."""
import os, re, sys
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, HERE)
import pixel_mech_figs as P

MAX_UNION = (147, 169)    # the biggest figure before the parts were drawn: the tab fits its zoom to this (whole zoom,
                          # 2 at 4K), so a bigger one would change every vehicle's size on screen
ROWS = P.ROWS             # the side columns' six rows, top to bottom
DRAWN = {"brake": P.BRAKE, "suspension": P.SPRING, "battery": P.BATTERY, "muffler": P.MUFFLER,
         "engine": P.ENGINE, "gastank": P.TANK}

n_checks, failures = 0, []


def check(ok, what):
    global n_checks
    n_checks += 1
    if not ok:
        failures.append(what)
        print("FAIL", what)


def paths(d):
    if d is None:
        return (os.path.join(REPO, "42", "media", "textures", "ZeD", "mech"),
                os.path.join(REPO, "42", "media", "lua", "client", "ZeD", "MechFigs.lua"))
    if os.path.isdir(os.path.join(d, "textures")):
        return os.path.join(d, "textures"), os.path.join(d, "MechFigs.lua")
    return (os.path.join(d, "42", "media", "textures", "ZeD", "mech"),
            os.path.join(d, "42", "media", "lua", "client", "ZeD", "MechFigs.lua"))


def main():
    tex_dir, mf = paths(sys.argv[1] if len(sys.argv) > 1 else None)
    src = open(mf, encoding="utf-8").read()
    head, _, tail = src.partition("unions")
    rect = r'\["([A-Za-z0-9_]+)"\] = \{ x = (\d+), y = (\d+), w = (\d+), h = (\d+)'
    layers = {k: tuple(map(int, v)) for k, *v in re.findall(rect, head)}
    unions = {k: tuple(map(int, v)) for k, *v in re.findall(rect, tail)}
    check(len(layers) > 0 and len(unions) > 0, "MechFigs.lua has its layers and its unions")

    def img(name):
        p = os.path.join(tex_dir, "zm_" + name + ".png")
        return np.asarray(Image.open(p).convert("RGBA")) if os.path.exists(p) else None

    # 1. every layer's texture (and a part's rim and two wear overlays) is there, the table's size
    for key, (x, y, w, h) in sorted(layers.items()):
        names = [key] if key.endswith("_base") else [key, key + "_rim", key + "_wear1", key + "_wear2"]
        for n in names:
            a = img(n)
            check(a is not None, f"zm_{n}.png is there")
            if a is not None:
                check(a.shape[:2] == (h, w), f"zm_{n}.png is {w} x {h} as the table says (it is {a.shape[1]} x {a.shape[0]})")

    # 2. the figure is no bigger than before, so the tab's zoom holds
    mw, mh = max(u[2] for u in unions.values()), max(u[3] for u in unions.values())
    check((mw, mh) == MAX_UNION, f"the biggest figure is {MAX_UNION[0]} x {MAX_UNION[1]} (it is {mw} x {mh})")
    for p, (ux, uy, uw, uh) in unions.items():
        for key, (x, y, w, h) in layers.items():
            if key.startswith(p):
                check(ux <= x and uy <= y and x + w <= ux + uw and y + h <= uy + uh, f"{key} lies inside its union")

    # 3. every drawn part is its drawing (the same picture for every body, left and right)
    for key in sorted(layers):
        body, part = key.split("_", 1)
        kind = part.split("_")[0] if part.split("_")[0] in DRAWN else part
        if kind not in DRAWN: continue
        a = img(key)
        if a is None: continue
        t, m = P.sprite(DRAWN[kind])
        check(a.shape[:2] == m.shape and np.array_equal(a[..., 3] > 0, m), f"{key} is the {kind} drawing")
        if a.shape[:2] == m.shape:
            check(np.array_equal(a[..., 0][m], np.clip(t, 0, 255).astype(np.uint8)[m]), f"{key} has the drawing's tones")

    # 4. the side columns: six rows top to bottom, none touching the next, each row's two parts on one line, and the
    #    two columns mirrored about the car
    bodies = sorted({k.split("_", 1)[0] for k in layers})
    # (QA, Nov 23 2026) a trailer's left and right pairs stand at one height: its springs and brakes row by row
    for b in bodies:
        if b + "_engine" in layers: continue
        for pos in ("front", "rear"):
            for part in ("suspension", "brake"):
                l, r = layers.get(f"{b}_{part}_{pos}_left"), layers.get(f"{b}_{part}_{pos}_right")
                if l and r:
                    check(l[1] == r[1], f"{b}: {part} {pos} left and right on one line ({l[1]} / {r[1]})")
    for b in bodies:
        if b + "_engine" not in layers: continue                  # (the trailers keep the game's layout)
        base = layers[b + "_base"]
        cx0, cx1 = base[0], base[0] + base[2]
        last = None
        for pair in ROWS:
            rs = [layers.get(f"{b}_{n}") for n in pair]
            rs = [r for r in rs if r]
            if not rs: continue
            top, bot = min(r[1] for r in rs), max(r[1] + r[3] for r in rs)
            mids = [r[1] + r[3] / 2.0 for r in rs]
            check(max(mids) - min(mids) <= 1.0, f"{b}: {pair[0]} and {pair[1]} sit on one line")
            if last is not None:
                check(top - last >= 2, f"{b}: {pair[0]} is clear of the row above ({top - last} rows)")
            last = bot
        lc = [layers[f"{b}_{l}"] for l, r in ROWS if f"{b}_{l}" in layers]
        rc = [layers[f"{b}_{r}"] for l, r in ROWS if f"{b}_{r}" in layers]
        lmid = np.mean([r[0] + r[2] / 2.0 for r in lc]); rmid = np.mean([r[0] + r[2] / 2.0 for r in rc])
        lcol, rcol = {round(r[0] + r[2] / 2.0) for r in lc}, {round(r[0] + r[2] / 2.0) for r in rc}
        check(max(lcol) - min(lcol) <= 1 and max(rcol) - min(rcol) <= 1, f"{b}: each column's parts share its centre")
        check(abs((cx0 - lmid) - (rmid - cx1)) <= 1.5, f"{b}: the two columns stand as far off the car")

    # 5. the glass: the wear is cracks, cut inside the pane (a cut, its lit lip, the strike), more of it when red
    cut_c, lip_c, chip_c = (np.array(c, np.uint8) for c in (P.CRACK, P.CRACK_LIP, P.CHIP))
    for key in sorted(layers):
        if "_window_" not in key: continue
        pane = img(key)
        if pane is None: continue
        m = pane[..., 3] > 0
        inner = (m & ndi.binary_erosion(m)) if min(m.shape) >= 3 else m
        counts = []
        for k in (1, 2):
            wv = img(f"{key}_wear{k}")
            if wv is None: continue
            on = wv[..., 3] > 0
            rgb = wv[..., :3]
            cut = on & np.all(rgb == cut_c, axis=2)
            lip = on & np.all(rgb == lip_c, axis=2)
            chip = on & np.all(rgb == chip_c, axis=2)
            check(not (on & ~(cut | lip | chip)).any(), f"{key}_wear{k} holds only the crack's three tones")
            check(not (on & ~inner).any(), f"{key}_wear{k} stays inside the pane, off its outline")
            check(chip.sum() <= 1, f"{key}_wear{k} has one strike at most")
            # a crack is a line: no 2 x 2 block of cut, but round the strike
            blk = cut[:-1, :-1] & cut[1:, :-1] & cut[:-1, 1:] & cut[1:, 1:]
            # (the tool lets the strike's own ring of pixels close a block: any block with a pixel next to the strike)
            nx = ndi.binary_dilation(chip, structure=np.ones((3, 3), bool)) if chip.any() else np.zeros_like(chip)
            near = nx[:-1, :-1] | nx[1:, :-1] | nx[:-1, 1:] | nx[1:, 1:]
            check(not (blk & ~near).any(), f"{key}_wear{k}: the cracks are lines, not blots")
            counts.append(int(cut.sum()))
        if len(counts) == 2 and inner.sum() >= 6:
            check(counts[1] > 0, f"{key}: red glass is cracked")
            check(counts[1] >= counts[0], f"{key}: red glass is cracked at least as much as yellow ({counts})")

    print(f"{n_checks} checks, {len(failures)} failed")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
