"""The six radios' faces for a dashboard's radio slot (178 x 46): each one its plate brought down to the slot, in the
same materials, with the same display, branding and controls (the makeshift sets on their perforated board with the
salvaged display board, the power rocker and, on the two-way, the latching talk/listen switch).

A head hands the dashboard its live parts in the head format ZeD_Plate.lua's headUnit reads:
  display  {x, y, w, h, style ("seg" | "dot"), color, ghost, kind}   the readout, drawn live
  knob     {id, cx, cy, r, ptr}                                      a knob's pointer and its click area
  button   {id, x, y, w, h}                                          a press
  lamp     {src, color, r (rect list), halo}                         lit while the set is on and r[src] is set
  sprite   {src, when, tex, x, y, w, h}                              a state picture (the rocker on, the switch in)
  tape     {x, y, pitch, first, n}                                   the ValuTech's preset names, written live
"""
import numpy as np

from physlib import *            # noqa: F401,F403
import wear as WR
import d_props as PR             # noqa: F401  (the radios' materials: pcb, tape, solder, the display glasses)
import handwire as H
from dashlib import runs_of, halo_of


def rects_of_runs(runs):
    """[[x, y, w], ...] -> flat [x, y, w, 1, ...] (a lamp is a few runs; the dashboard exporter merges them anyway)"""
    out = []
    for x, y, w in runs: out += [int(x), int(y), int(w), 1]
    return out

W, HH = 178, 46
DISP_W, DISP_H = 106, 21               # the display's window; the readout is drawn 2 px inside it (as before)
# the readout's colours by kind (the glass is the plate's)
INK = {"premium": ("#62e6ff", "#0d2a33"), "valutech": ("#ffb22e", "#2a1a06"), "makeshift": ("#1f2a0c", None),
       "ham": ("#16190f", None), "army": ("#ff3a24", "#2a0806"), "hammake": ("#1f2a0c", None)}


class Head:
    """a head under construction: its Plate and the live parts it hands the dashboard"""
    def __init__(s, kind, seed):
        s.kind = kind
        s.p = Plate(f"dhead_{kind}", W, HH, seed=seed, title=f"{kind} head")
        s.d = s.p.d
        s.parts = []

    # ------------------------------------------------------------------ the pieces
    def display(s, x, y, bezel="blackp", bezel_t=1):
        dk = PR.DISPLAY_KIND[s.kind]
        window_glass(s.p, x, y, DISP_W, DISP_H, face=PR.DISPLAY_FACE[dk], bezel=bezel, depth=1.4, on=Z_FACE, r=1,
                     bezel_t=bezel_t, lens=dk in ("vfd", "amber", "led"))
        col, ghost = INK[s.kind]
        s.parts.append({"t": "display", "x": x + 2, "y": y + 2, "w": DISP_W - 4, "h": DISP_H - 4,
                        "style": "seg" if dk in ("vfd", "amber", "led") else "dot", "color": col, "ghost": ghost, "kind": s.kind})

    def knob(s, pid, cx, cy, r, mat="blackp", skirt=None, ptr="#e8e8e8", label=None, label_y=None, lab_mat="paint_w",
             on=Z_FACE, ridges=16):
        fluted_knob(s.p, cx, cy, r, on=on, z=3.2, mat=mat, skirt=skirt, skirt_mat="chrome", ridges=ridges, dome=0.6, check=False)
        s.parts.append({"t": "knob", "id": pid, "cx": cx, "cy": cy, "r": r, "ptr": ptr})
        if label: s.d.text(label, cx, label_y, lab_mat, align="c", flatlight=True)

    def key(s, pid, x, y, w, h, label=None, mat="blackp", lab_mat="paint_w", icon=None, wear=0.0):
        d = s.d
        m = Mask(W, HH).rrect(x, y, w, h, 1).get()
        d.slab(m, 1.4, mat, bevel=0.8, polish=0.5, on=Z_FACE)
        cx, cy = x + w / 2, y + h / 2
        if icon == "eject":
            arrow_icon(s.p, cx, cy - 1, True, lab_mat, w=5, h=3)
            d.paint(rbox(d, int(cx - 2), int(cy + 1.5), 5, 1), lab_mat, flatlight=True)
        elif icon == "play":
            tri = Mask(W, HH).poly([(cx - 5, cy - 2.5), (cx - 5, cy + 2.5), (cx - 1, cy)]).get(0.45)
            d.paint(tri, lab_mat, flatlight=True)
            d.paint(rbox(d, int(cx + 1), int(cy - 2), 4, 5), lab_mat, flatlight=True)
        elif icon in ("up", "down"):
            d.text(label, int(cx - 3), int(y + (h - 5) // 2), lab_mat, align="c", flatlight=True)
            arrow_icon(s.p, cx + 5, cy, icon == "up", lab_mat, w=5, h=3)
        elif label:
            worn_text(d, label, int(cx), y + (h - 5) // 2, lab_mat, wear=wear, seed=x * 3 + y, align="c")
        s.button(pid, x, y, w, h)

    def button(s, pid, x, y, w, h):
        s.parts.append({"t": "button", "id": pid, "x": x, "y": y, "w": w, "h": h})

    def lamp(s, cx, cy, r, src="micMuted", color="#ff3a2e", on=Z_FACE):
        d = s.d
        d.dome(cx, cy, r, r, 1.0, "jewel_red_off", polish=0.9, on=on)
        m = disc(d, cx, cy, r - 0.2)
        part = {"t": "lamp", "src": src, "color": color, "r": rects_of_runs(runs_of(m))}
        hm = halo_of(m, d.solid)
        if hm.any(): part["halo"] = rects_of_runs(runs_of(hm))
        s.parts.append(part)

    def tact(s, pid, x, y, w, h, on, label=None, lab_y=None):
        """a tact switch on the salvaged display board"""
        d = s.d
        d.slab(rbox(d, x, y, w, h), 1.2, "steel", bevel=0.5, polish=0.6, on=on)
        d.dome(x + w / 2, y + h / 2, w * 0.3, h * 0.3, 1.2, "blackp", polish=0.6, on=on + 1.2)
        if label: d.text(label, int(x + w / 2), lab_y if lab_y is not None else y + h + 2, "paint_w", align="c", flatlight=True)
        s.button(pid, x, y, w, h)

    def rocker(s, x, y, w, h, on_state):
        rocker_switch(s.p, x + 1, y + 1, w - 2, h - 2, on_state, on=Z_FACE, mat="paint_r", bezel_mat="blackp", lift=1.4)
        s.button("pwr", x, y, w, h)

    # ------------------------------------------------------------------ the makeshift sets' board
    def perfboard(s):
        """phenolic perforated board edge to edge, its holes on a 3 px pitch (the slot shows it smaller)"""
        d = s.d
        body = Mask(W, HH).rrect(0, 0, W, HH, 2).get()
        d.slab(body, Z_FACE, "perf", bevel=1.0, polish=0.35)
        d.grain_pebble(body, 0.02, seed=17)
        s.holes = []
        for y in range(3, HH - 2, 3):
            for x in range(3, W - 2, 3):
                d.seam(rbox(d, x, y, 1, 1), 0.5)
                s.holes.append((x, y))
        s.perf_mat = d.mid("perf")

    def cover_holes(s):
        d = s.d
        for (x, y) in s.holes:
            if d.mat[y, x] != s.perf_mat: d.dark[y, x] = 0.0

    def salvaged(s, x0, y0, x1, y1, notch=None):
        """the salvaged display board on its spacers: a green board, four screws"""
        d = s.d
        body = Mask(W, HH).rrect(x0, y0, x1 - x0, y1 - y0, 1).get()
        if notch:
            nx0, ny0, nx1 = notch
            body &= ~Mask(W, HH).rect(nx0, ny0, nx1 - nx0, y1 - ny0 + 2).get()
        z = Z_FACE + 2.0
        d.slab(body, z, "pcb", bevel=0.8, polish=0.55)
        d.grain_pebble(body, 0.03, seed=3)
        for (sx, sy) in ((x0 + 3, y0 + 3), (x1 - 4, y0 + 3), (x0 + 3, y1 - 4), (x1 - 4, y1 - 4)):
            d.dome(sx, sy, 1.4, 1.4, 0.8, "steel", polish=1.0, on=z)
        return z

    def wire(s, pts, mat, w=1.6):
        """an insulated wire lying on the board"""
        d = s.d
        m = Mask(W, HH).line(pts, w).get(0.45)
        d.slab(m, 0.9, mat, bevel=0.8, polish=0.7, on="h")
        for (x, y) in (pts[0], pts[-1]):
            d.dome(x + 0.5, y + 0.5, 1.0, 1.0, 0.6, "solder", polish=1.0, on=Z_FACE + 0.2)

    def resistor(s, x, y, bands, vertical=False):
        d = s.d
        if vertical:
            d.cyl(x, y - 1, 1, 9, 0.4, "solder", axis="v", polish=0.9, on=Z_FACE)
            d.cyl(x - 1, y + 1, 3, 5, 1.6, "resistor", axis="v", polish=0.5, on=Z_FACE)
            for i, b in enumerate(bands): d.paint(rbox(d, x - 1, y + 2 + i, 3, 1), b, flatlight=False)
        else:
            d.cyl(x - 1, y, 9, 1, 0.4, "solder", axis="h", polish=0.9, on=Z_FACE)
            d.cyl(x + 1, y - 1, 5, 3, 1.6, "resistor", axis="h", polish=0.5, on=Z_FACE)
            for i, b in enumerate(bands): d.paint(rbox(d, x + 2 + i, y - 1, 1, 3), b, flatlight=False)

    def chip(s, x, y, w, h, label=None):
        d = s.d
        d.slab(Mask(W, HH).rrect(x, y, w, h, 1).get(), 1.4, "blackp", bevel=0.6, polish=0.5, on=Z_FACE)
        for k in range(1, w - 1, 2):
            for yy in (y - 1, y + h):
                d.flat(rbox(d, x + k, yy, 1, 1), Z_FACE + 0.3, "solder", polish=0.9)
        if label: d.text(label, x + w // 2, y + (h - 5) // 2, "paint_w", align="c", flatlight=True)

    def transistor(s, cx, cy):
        d = s.d
        d.slab(disc(d, cx, cy, 2.2) & (d.YY + 0.5 <= cy + 1.0), 1.8, "blackp", bevel=0.8, polish=0.55, on=Z_FACE)

    def cap(s, cx, cy, mat="paint_b"):
        s.d.dome(cx, cy, 1.6, 1.6, 1.4, mat, polish=0.8, on=Z_FACE)

    def tape(s, x, y, w, h, text=None, angle_px=0):
        H.tape(s.p, x, y, w, h, text, angle_px=angle_px)

    def finish(s, grime=0.22, seed=1, scuff_mat=None):
        d = s.d
        if grime: WR.grime(d, d.solid, amount=grime, seed=seed)
        if scuff_mat: WR.scuffs(d, WR.mat_mask(d, scuff_mat), 0.001, seed=seed + 1, amount=0.10)


def _brand(h, text, x, y, mat="paint_c", align="l", font="35"):
    h.d.text(text, x, y, mat, align=align, font=font, flatlight=True)


# =================================================================================== the six
def premium(worn=True):
    h = Head("premium", 81)
    PR.plate_body(h.p, "blackp", grain="brushed", seed=82, r=2)
    _brand(h, "PREMIUM TECHNOLOGIES", 89, 2, align="c")
    h.display(36, 8, bezel="chrome")
    h.knob("vol", 17, 17, 9, mat="alu", skirt=0.8, ptr="#202226", label="VOL", label_y=29)
    h.knob("tune", 161, 17, 9, mat="alu", skirt=0.8, ptr="#202226", label="TUNE", label_y=29)
    # the CD slot under the display, its eject beside it
    d = h.d
    d.slab(Mask(W, HH).rrect(40, 30, 78, 4, 1).get(), 0.8, "chrome", bevel=0.6, polish=1.0, on=Z_FACE)
    d.well(Mask(W, HH).rect(42, 31, 74, 2).get(), 2.0, "rubber", bevel=0.4)
    h.button("slot", 40, 30, 78, 4)
    h.key("eject", 121, 29, 21, 6, icon="eject")
    used = {1: 0.18, 2: 0.14}
    for i in range(6):
        h.key(f"preset{i + 1}", 6 + i * 13, 37, 12, 7, str(i + 1), wear=used.get(i + 1, 0) if worn else 0)
    h.key("scan", 85, 37, 21, 7, "SCAN")
    h.key("seek", 107, 37, 21, 7, "SEEK")
    h.key("mute", 129, 37, 21, 7, "MUTE")
    h.key("play", 152, 37, 20, 7, icon="play")
    if worn: h.finish(0.26, 83, "blackp")
    return h


def valutech(worn=True):
    h = Head("valutech", 85)
    PR.plate_body(h.p, "blackp", grain="pebble", seed=86, edge=None, r=2)
    _brand(h, "VALUTECH", 18, 3, mat="paint_w", align="c")
    _brand(h, "FM", 18, 10, align="c")
    h.display(36, 2)
    h.key("mute", 146, 3, 26, 8, "MUTE")
    h.key("seek", 146, 13, 26, 8, "SEEK")
    used = {1: 0.2, 2: 0.15, 4: 0.1}
    for i in range(6):
        h.key(f"preset{i + 1}", 29 + i * 20, 25, 18, 8, str(i + 1), wear=used.get(i + 1, 0) if worn else 0)
    h.knob("vol", 15, 30, 8, label="VOL", label_y=40)
    h.knob("tune", 163, 30, 8, label="TUNE", label_y=40)
    # the masking tape under the presets; the names are written on it live
    d = h.d
    tape = Mask(W, HH).poly([(28, 35), (147, 34), (147, 43), (28, 44)]).get()
    d.slab(tape, 0.4, "tape", bevel=0.4, polish=0.2, on=Z_FACE)
    h.parts.append({"t": "tape", "x": 29, "y": 37, "pitch": 20, "first": 29 + 9, "n": 6, "w": 18, "color": "#2a3a8a"})
    if worn: h.finish(0.26, 87, "blackp")
    return h


def ham(worn=True):
    h = Head("ham", 92)
    PR.plate_body(h.p, "blackp", grain="pebble", seed=93, edge=None, r=2)
    _brand(h, "PREMIUM TECHNOLOGIES - TWO-WAY", 36, 2)
    d = h.d
    for i in range(3):                                     # the speaker grille
        d.well(Mask(W, HH).rrect(4 + i * 3, 6, 1, 34, 0).get(), 1.6, "rubber", bevel=0.4)
    h.knob("vol", 22, 18, 8, label="VOL", label_y=30)
    h.display(36, 8)
    for i, (pid, lab, icon) in enumerate((("chup", "CH", "up"), ("chdn", "CH", "down"), ("mem", "MEM", None), ("mic", "MIC", None),
                                          ("mute", "MUTE", None))):
        h.key(pid, 36 + i * 21, 32, 20, 8, lab, icon=icon, wear=0.12 if (worn and pid == "mic") else 0)
    h.lamp(144, 36, 2.0)
    h.knob("tune", 161, 19, 12, skirt=0.8, ridges=22, label="DIAL", label_y=35)
    if worn: h.finish(0.26, 94, "blackp")
    return h


def army(worn=True):
    h = Head("army", 96)
    PR.plate_body(h.p, "olive", grain="pebble", seed=97, edge=None, r=2)
    for (x, y) in ((3, 3), (W - 4, 3), (3, HH - 4), (W - 4, HH - 4)):
        screw(h.p, x, y, on=Z_FACE, mat="olive")
    _brand(h, "US ARMY COMM. - RADIO SET", 36, 2)
    h.knob("vol", 18, 20, 9, label="VOL", label_y=32)
    h.display(36, 8)
    for i, (pid, lab, icon) in enumerate((("chup", "CH", "up"), ("chdn", "CH", "down"), ("mem", "MEM", None), ("mic", "MIC", None),
                                          ("mute", "MUTE", None))):
        h.key(pid, 36 + i * 21, 32, 20, 8, lab, icon=icon, wear=0.14 if (worn and pid in ("mic", "mem")) else 0)
    h.lamp(144, 36, 2.0)
    h.knob("tune", 161, 19, 12, ridges=22, label="FREQ", label_y=35)
    if worn:
        d = h.d
        ol = WR.mat_mask(d, "olive")
        WR.grime(d, d.solid, amount=0.30, seed=98)
        WR.chips(d, WR.face(d, Z_FACE, ol), 0.006, seed=99, near=2.0, mat="steel")
        WR.scuffs(d, ol, 0.0015, seed=100, amount=0.12)
    return h


def _pot(h, cx, cy, r):
    """the makeshift sets' volume control: a steel can on the board, its knob on the shaft"""
    h.d.slab(disc(h.d, cx, cy, r + 2), 1.2, "steel", bevel=0.8, polish=0.6, on=Z_FACE)
    h.knob("vol", cx, cy, r, on=Z_FACE + 1.2, ridges=14, label=None)


def makeshift(switch_on=False, worn=True):
    h = Head("makeshift", 89)
    h.perfboard()
    d = h.d
    # bits on the board first, wires between them, then the salvaged board over the middle
    h.chip(152, 37, 22, 5, None)                           # the TDA7000
    for k, x in enumerate((151, 155, 159)): h.cap(x, 43, "paint_o" if k % 2 else "paint_b")
    h.resistor(168, 42, ("paint_r", "paint_k", "paint_o"))
    h.wire([(26, 15), (30, 15)], "w_red", w=1.4)
    h.wire([(3, 44), (29, 44)], "w_blk", w=1.4)
    h.wire([(148, 30), (150, 33), (150, 36)], "w_red", w=1.4)
    z = h.salvaged(30, 1, 148, 45)
    h.display(36, 3)
    for i in range(6):
        h.tact(f"preset{i + 1}", 38 + i * 15, 29, 9, 8, z, str(i + 1), lab_y=39)
    h.tact("seek", 130, 29, 9, 8, z)
    d.text("SEEK", 134, 39, "paint_w", align="c", flatlight=True)
    h.tape(3, 1, 22, 6, "PWR")
    h.rocker(6, 10, 16, 9, switch_on)
    _pot(h, 14, 28, 6)
    h.tape(3, 37, 22, 6, "VOL")
    # the tuning capacitor under TUNE: its white square body, the knob on its shaft
    d.slab(Mask(W, HH).rrect(151, 2, 23, 23, 1).get(), 2.0, "poly", bevel=0.8, polish=0.5, on=Z_FACE)
    h.knob("tune", 162, 13, 8, on=Z_FACE + 2.0, ridges=14, label=None)
    h.tape(151, 27, 23, 7, "TUNE")
    h.cover_holes()
    if worn: h.finish(0.20, 91)
    return h


def hammake(switch_on=False, mic_live=False, worn=True):
    h = Head("hammake", 101)
    h.perfboard()
    d = h.d
    for cx in (152, 158, 164): h.transistor(cx, 43)
    h.resistor(167, 44, ("paint_y", "band_v", "paint_k"))
    h.wire([(26, 15), (30, 15)], "w_red", w=1.4)
    h.wire([(148, 5), (175, 5)], "w_yel", w=1.4)
    h.wire([(148, 8), (174, 8), (174, 14)], "w_wht", w=1.4)
    h.wire([(3, 44), (29, 44)], "w_blk", w=1.4)
    h.wire([(110, 45), (148, 45)], "w_vio", w=1.2)
    z = h.salvaged(30, 1, 148, 45, notch=(89, 30, 109))
    h.display(36, 2)
    d.text("HAM TX/RX", 37, 25, "paint_w", flatlight=True)
    for pid, lab, x in (("chup", "CH+", 39), ("chdn", "CH-", 57), ("mem", "MEM", 75), ("mute", "MUTE", 115)):
        h.tact(pid, x, 31, 9, 7, z, lab, lab_y=39)
    h.lamp(138, 34, 1.8, on=z)
    # the talk/listen switch in the notch: latched in while the microphone is live
    H.latch4(_BoardShim(h), "SW1", 90, 30, 18, 15, {}, ("mic", 92, 32, 13, 11), mic_live, label="MIC", cap_w=15)
    h.button("mic", 92, 32, 13, 11)
    h.tape(3, 1, 22, 6, "PWR")
    h.rocker(6, 10, 16, 9, switch_on)
    _pot(h, 14, 28, 6)
    h.tape(3, 37, 22, 6, "VOL")
    # the tuning coil's can under DIAL, its knob on the slug
    d.slab(Mask(W, HH).rrect(152, 11, 21, 21, 1).get(), 1.6, "steel", bevel=0.8, polish=0.6, on=Z_FACE)
    h.knob("tune", 162, 21, 9, on=Z_FACE + 1.6, ridges=18, label=None)
    h.tape(151, 33, 23, 6, "DIAL")
    h.cover_holes()
    if worn: h.finish(0.22, 103)
    return h


class _BoardShim:
    """just enough of a hand-wired Board for H.latch4 on a head (no lugs to route; its click area is the head's)"""
    def __init__(s, h):
        s.d, s.p = h.d, _NoHit(h.p)
        s.masks = {"body": {}, "lead": {}}

    def fc(s, key): return key

    def _body(s, name, m): pass

    def keep_mask(s, m, margin): pass


class _NoHit:
    def __init__(s, p): s._p = p

    def __getattr__(s, k): return getattr(s._p, k)

    def hit(s, *a, **k): pass


HEADS = {"premium": premium, "valutech": valutech, "makeshift": makeshift, "ham": ham, "army": army, "hammake": hammake}
# state pictures: (name, the radio's field, the value it shows at, the design's keyword)
VARIANTS = {"makeshift": [("switch_on", "switchOn", True, {"switch_on": True})],
            "hammake": [("switch_on", "switchOn", True, {"switch_on": True}), ("mic_live", "micLive", True, {"mic_live": True})]}


def build(kind, env="room"):
    """-> (base picture, parts, {sprite name: picture}, warnings)"""
    fn = HEADS[kind]
    h = fn()
    base = h.d.render(chrome_env=env)
    sprites = {}; sparts = []
    for name, src, when, kw in VARIANTS.get(kind, []):
        q = fn(**kw)
        spr, at = cut_variant(base, q.d.render(chrome_env=env))
        if spr is None: h.p.warn(f"variant {name} changed nothing"); continue
        tex = f"dhead_{kind}_{name}"
        sprites[tex] = spr
        sparts.append({"t": "sprite", "src": src, "when": when, "tex": tex, "x": at[0], "y": at[1], "w": spr.width, "h": spr.height})
    return base, sparts + h.parts, sprites, h.p.warnings


if __name__ == "__main__":
    import os
    from PIL import Image
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out", "heads")
    os.makedirs(out, exist_ok=True)
    k = 5
    rows = []
    for kind in HEADS:
        base, parts, sprites, warns = build(kind)
        base.save(os.path.join(out, f"dhead_{kind}.png"))
        on = base.copy()
        for nm, im in sprites.items():
            sp = [q for q in parts if q.get("tex") == nm][0]
            on.alpha_composite(im, (sp["x"], sp["y"]))
        rows.append((kind, base, on))
        print(kind, "parts", len(parts), "sprites", list(sprites), "warnings", warns)
    sheet = Image.new("RGBA", (W * k * 2 + 30, (HH * k + 10) * len(rows) + 10), (28, 28, 30, 255))
    for i, (kind, b, o) in enumerate(rows):
        sheet.alpha_composite(b.resize((W * k, HH * k), 0), (10, 10 + i * (HH * k + 10)))
        sheet.alpha_composite(o.resize((W * k, HH * k), 0), (20 + W * k, 10 + i * (HH * k + 10)))
    sheet.save(os.path.join(out, "heads_sheet.png"))
