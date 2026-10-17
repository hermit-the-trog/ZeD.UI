"""The fitted radios' small faces for the dash slot (178 x 46), in the dashboards' pixel art, plus the blanking plate
for a slot with no radio. Each face hands the game its live parts: the display (drawn in pixel figures), the two knob
pointers, the buttons it can click. Kinds match ZeD_RadioOps.DISPLAY_KIND."""
import json
import math
import os
import zlib
import numpy as np
from engine import Dash, RAMPS, hx, add_ramp, text_w
from widgets import window, glare, knob, button, chrome_frame, rivet, line_mask
import dashlib
from dashlib import runs_of

W, H = dashlib.HU_W, dashlib.HU_H
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out", "radios")
os.makedirs(OUT, exist_ok=True)

add_ramp("olive", "#4a4f32")
add_ramp("hamgrey", "#5a5e60")
RAMPS["lcdlit"] = [hx(c) for c in ("#5f7034", "#6d7f3b", "#7a8d43", "#889c4b", "#95aa54", "#a3b85e", "#b0c56a", "#bed277")]
RAMPS["lcdgrey"] = [hx(c) for c in ("#5a6352", "#646e5b", "#6e7964", "#78836e", "#838e78", "#8e9983", "#99a48e", "#a5b09a")]

KINDS = {
    #            plate      knobs     display face  display style  colour      ghost       buttons      brand
    "premium":  ("blackp", "alu",    "vfd",        "seg",         "#62e6ff",  "#0d2a33",  "presets",   "PREMIUM TECHNOLOGIES"),
    "valutech": ("blackp", "blackp", "lens",       "seg",         "#ffb22e",  "#2a1a06",  "presets",   "VALUTECH"),
    "makeshift": ("steel", "blackp", "lcdlit",     "dot",         "#1f2a0c",  None,       "presets",   None),
    "ham":      ("hamgrey", "blackp", "lcdgrey",   "dot",         "#16190f",  None,       "channels",  "HAM"),
    "army":     ("olive",  "blackp", "ledglass",   "seg",         "#ff3a24",  "#2a0806",  "channels",  "U.S. ARMY"),
    "hammake":  ("steel",  "blackp", "lcdlit",     "dot",         "#1f2a0c",  None,       "channels",  None),
}
DISP = (36, 3, 106, 21)          # the display window
KN_L, KN_R, KN_Y, KN_R0 = 17, 161, 16, 9


def face(kind):
    plate, kmat, dface, dstyle, col, ghost, btns, brand = KINDS[kind]
    d = Dash(W, H, seed=zlib.crc32(kind.encode()) % 997)   # a stable seed: hash() of a str changes every run
    m = np.ones((H, W), bool)
    d.flat(m, 0.0, plate, polish=0.35)
    if plate in ("blackp",): d.grain_brushed(m, 0.03, seed=4)
    elif plate == "steel": d.tex[m & (d.rng.random((H, W)) > 0.55)] += 0.05
    else: d.grain_pebble(m, 0.04, seed=6)
    edge = np.zeros((H, W), bool); edge[0, :] = edge[-1, :] = True; edge[:, 0] = edge[:, -1] = True
    d.seam(edge, 0.35)
    parts = []
    if kind == "premium":
        chrome_frame(d, 1, 1, W - 2, H - 2, 0.0, t=1, r=0, z=0.8)
    if plate == "steel":
        for (x, y) in ((4, 4), (W - 5, 4), (4, H - 5), (W - 5, H - 5)): rivet(d, x, y, on=0.0)
    # display
    dx, dy, dw, dh = DISP
    win = window(d, dx, dy, dw, dh, 1.2, bezel="blackp" if kind != "premium" else "chrome", face=dface, r=1, bezel_t=1, on=0.0, lens=False)
    if dface in ("vfd", "lens", "ledglass"): glare(d, win, slope=-0.5, width=6, offset=0.7, amount=0.04)
    parts.append({"t": "display", "x": dx + 2, "y": dy + 2, "w": dw - 4, "h": dh - 4, "style": dstyle, "color": col, "ghost": ghost,
                  "kind": kind})
    # knobs: volume (push for power) and tune / channel
    for (cx, lab, pid) in ((KN_L, "VOL", "vol"), (KN_R, "CH" if btns == "channels" else "TUNE", "tune")):
        knob(d, cx, KN_Y, KN_R0, mat=kmat, on=0.0, z=3.4, knurl=True, skirt=1.0 if kind == "premium" else None)
        d.text(lab, cx, 30, "paint_w", align="c")
        parts.append({"t": "knob", "id": pid, "cx": cx, "cy": KN_Y, "r": KN_R0,
                      "ptr": "#202226" if kmat == "alu" else "#e8e8e8"})
    # buttons
    by = 27
    if btns == "presets":
        for i in range(6):
            bx = dx + i * 18
            button(d, bx, by, 16, 9, str(i + 1), mat="alu" if kind == "premium" else "blackp", on=0.0, z=1.4, r=1,
                   lab_mat="blackp" if kind == "premium" else "paint_w")
            parts.append({"t": "button", "id": f"preset{i + 1}", "x": bx, "y": by, "w": 16, "h": 9})
    else:
        for i, (lab, pid) in enumerate((("CH-", "chdn"), ("CH+", "chup"), ("MIC", "mic"))):
            bx = dx + i * 36
            button(d, bx, by, 34, 9, lab, mat="blackp", on=0.0, z=1.4, r=1)
            parts.append({"t": "button", "id": pid, "x": bx, "y": by, "w": 34, "h": 9})
    if brand:
        d.text(brand, dx + dw // 2, 38, "paint_c" if kind != "army" else "paint_y", align="c")
    else:
        # the handmade ones: a strip of label tape
        t = "RADIO" if kind == "makeshift" else "HAM"
        dashlib_dymo(d, t, dx + dw // 2, 38)
    img = d.render(outline=False)
    return img, parts


def dashlib_dymo(d, t, x, y):
    w = text_w(t) + 6
    x -= w // 2
    tape = np.zeros((d.H, d.W), bool); tape[y:y + 6, x:x + w] = True
    d.slab(tape, 0.5, "dymo", bevel=0.5, polish=0.8, on=0.0)
    m = d.text(t, x + 3, y + 1, "paint_w")
    d.h[m] += 0.4


def blank():
    """no radio fitted: a blanking plate with a coin tray"""
    d = Dash(W, H, seed=5)
    m = np.ones((H, W), bool)
    d.flat(m, 0.0, "blackp", polish=0.3); d.grain_pebble(m, 0.04, seed=2)
    tray = np.zeros((H, W), bool); tray[12:34, 30:148] = True
    d.well(tray, 3.0, "rubber", bevel=2.0)
    for x in (8, W - 9): d.dome(x, H // 2, 2.0, 2.0, 1.0, "blackp", polish=0.8, on=0.0); d.seam(np.zeros((H, W), bool), 0)
    return d.render(outline=False)


def build():
    """the six faces, drawn as their plates brought down to the slot (ZeDUI/tools/physpx/d_heads.py): kind -> (picture,
    parts, {state picture name: picture}). face() above is the first, plainer set, kept for reference."""
    import sys
    sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "physpx"))
    import d_heads as DH
    heads = {}
    for k in KINDS:
        img, parts, sprites, warns = DH.build(k)
        if warns: raise SystemExit(f"head {k}: " + "; ".join(warns))
        img.save(os.path.join(OUT, f"dhead_{k}.png"))
        for nm, im in sprites.items(): im.save(os.path.join(OUT, f"{nm}.png"))
        heads[k] = (img, parts, sprites)
    blank().save(os.path.join(OUT, "hu_blank.png"))
    with open(os.path.join(OUT, "dheads.json"), "w") as f:
        json.dump({k: v[1] for k, v in heads.items()}, f, separators=(",", ":"))
    return heads


if __name__ == "__main__":
    build()
    print("ok")
