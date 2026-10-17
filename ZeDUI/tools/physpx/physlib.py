"""The physical controls (ovens, microwaves, generators, the gas grill, the car props up close) in pixel art.

Same method as the dashboards (ZeDUI/tools/dashpx): a height field with a material per pixel, lit from above,
real height-field shadows, per-material colour ramps, no blending, no dithering. A plate is one fixed-size
picture (1 plate pixel = 1 screen pixel at 1080p, whole multiples above), centred where it sits; the game draws
the live parts on it (knob pointers, needles, clock hands, readouts, lamps, state sprites) from data.

This module is the shared kit: the Plate (records parts, click areas, state variants, and checks that every
legend and control sits on one flat surface and that no two legends collide), the build (the base picture, then
each state variant built the same way and cut down to the pixels it changes), and the parts these machines share
(dial scales, clock faces, jewel lamps, piano keys, membrane pads, mesh windows, outlets, breakers, gauges).
"""
import copy
import math
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "dashpx"))

from engine import Dash, Mask, RAMPS, hx, text_w, add_ramp, FONTS          # noqa: E402
from widgets import (knob, button, rocker, toggle, chrome_frame, window, glare, line_mask, rivet,  # noqa: E402
                     nameplate, gauge, seg_digit, icon_mask, icon_size, ICONS)
import dashlib                                                                # noqa: E402  (shared ramps: vfd, steel...)
from dashlib import runs_of, halo_of, PRINTED                                 # noqa: E402
from live import needle_pixels                                                # noqa: E402

Z_FACE = 4.0          # the panel's face; everything mounted on it sits `on=Z_FACE`

# ---- the machines' materials (enamels sampled from the game's own sprites)
for nm, base, kw in (
    ("enamel_mint", "#7f9e82", {}), ("enamel_red", "#9a3a36", {}), ("enamel_white", "#d9d8d0", {"light": 1.12}),
    ("enamel_almond", "#d6ccb4", {"light": 1.12}), ("enamel_black", "#2a2a2c", {}), ("olive_drab", "#59603e", {}),
    ("gen_red", "#b0352c", {}), ("gen_yellow", "#c8962e", {}), ("gen_blue", "#2f63b0", {}), ("bakelite", "#1d1a18", {}),
    ("cream", "#e6dcc0", {"light": 1.1}),
    ("ptr_red", "#7a1a12", {}),                    # the pointer line moulded into a knob (the game draws the same red)
    ("pad_panel", "#c4c3bb", {"light": 1.12}),     # a 1990 membrane panel, light warm grey
    ("pad_key", "#a9a8a0", {"light": 1.15}),       # its pads, a shade darker
    ("panel_black", "#2b2b2d", {}),                # a generator's painted steel panel
    ("decal_y", "#e2b52a", {}),                    # a warning sticker
):
    add_ramp(nm, base, **kw)
RAMPS["blackglass"] = [hx(c) for c in ("#030304", "#060607", "#0a0a0c", "#0f0f12", "#141418", "#1b1b20", "#25252b", "#33333b")]
RAMPS["jewel_off"] = [hx(c) for c in ("#2a1204", "#3a1906", "#4c2208", "#5e2c0b", "#71370f", "#874414", "#9e531a", "#b86522")]
RAMPS["jewel_red_off"] = [hx(c) for c in ("#2a0604", "#3a0906", "#4c0c08", "#5e100b", "#71150f", "#871b14", "#9e221a", "#b82c22")]
RAMPS["jewel_grn_off"] = [hx(c) for c in ("#04200c", "#062a10", "#083614", "#0b4219", "#0f4f1f", "#145d26", "#1a6c2e", "#227d38")]
RAMPS["ledwin"] = [hx(c) for c in ("#090203", "#0e0304", "#140405", "#1a0607", "#210809", "#2a0a0b", "#350d0e", "#421112")]
RAMPS["membrane"] = [hx(c) for c in ("#3c3a35", "#4b4943", "#5b5952", "#6c6a62", "#7e7c73", "#918f85", "#a4a298", "#b8b6ab")]
RAMPS["socket"] = [hx(c) for c in ("#1a1814", "#26231d", "#332f27", "#413c32", "#504a3e", "#605a4b", "#726b59", "#857d69")]
RAMPS["mesh"] = [hx(c) for c in ("#050505", "#080808", "#0c0c0c", "#101010", "#151515", "#1b1b1b", "#222222", "#2b2b2b")]
RAMPS["mesh_lit"] = [hx(c) for c in ("#0d0703", "#140b05", "#1b1007", "#23150a", "#2c1b0d", "#362110", "#412814", "#4d3019")]
RAMPS["hole"] = [hx(c) for c in ("#1c1a17", "#24221e", "#2d2a25", "#36332d", "#403c35", "#4a463e", "#555048", "#605a51")]
RAMPS["paint_g"] = [hx(c) for c in ("#06200e", "#0b3418", "#104a22", "#17612d", "#1f7a39", "#2a9447", "#3aae58", "#55c870")]
RAMPS["paint_b"] = [hx(c) for c in ("#06122a", "#0b1d42", "#10295c", "#173676", "#204590", "#2c56aa", "#3d6ac2", "#5684d8")]
RAMPS["glassline"] = [hx(c) for c in ("#1f2023", "#2a2b2f", "#36373c", "#43454b", "#53555c", "#64676e", "#787b83", "#8e9199")]
RAMPS["cord"] = [hx(c) for c in ("#070707", "#0c0c0d", "#121214", "#18181b", "#1f1f23", "#28282c", "#333338", "#414147")]
PRINTED.update({"paint_g", "paint_b", "ptr_red", "glassline"})

DOT = "-"          # no middle dots anywhere (director, Oct 16 2026): a printed separator is a hyphen


def rbox(d, x, y, w, h):
    m = np.zeros((d.H, d.W), bool); m[max(0, y):max(0, y + h), max(0, x):max(0, x + w)] = True; return m


def ring(d, cx, cy, r0, r1):
    rr = np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - cy); return (rr >= r0) & (rr <= r1)


def disc(d, cx, cy, r):
    return np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - cy) <= r


def font_h(font): return len(FONTS[font]["A"])


def worn_text(d, t, x, y, mat, wear=0.0, seed=0, font="35", align="l", scale=1):
    """printed text; with `wear`, some of its pixels are rubbed back to the surface under them (a faint stain
    of ink left), in small clusters, the way print wears where fingers go"""
    prev = d.mat.copy()
    m = d.text(t, x, y, mat, font=font, align=align, flatlight=True, scale=scale)
    if wear > 0 and m.any():
        import wear as WR
        n = WR._noise((d.H, d.W), seed, 0.8)
        sel = m & (n < wear)
        d.mat[sel] = prev[sel]
        d.dark[sel] += 0.14
    return m


class Plate:
    """one machine's control plate: the art, its live parts, its click areas, its state variants"""

    def __init__(s, pid, w, h, seed=7, title=""):
        s.id = pid; s.title = title
        s.d = Dash(w, h, seed=seed)
        s.W, s.H = w, h
        s.parts = []; s.hits = []; s.warnings = []; s.meta = {}; s.inks = []

    # ---- records
    def part(s, t, **kw):
        kw = {"t": t, **kw}; s.parts.append(kw); return kw

    def hit(s, id_, x, y, w, h, needs=None, kind="press"):
        """a click area; kind: press (A presses it), turn (the D-pad turns it), look (no focus: part of the look)"""
        s.hits.append({"id": id_, "x": int(x), "y": int(y), "w": int(w), "h": int(h), "needs": needs, "kind": kind})

    def lamp(s, mask, src, color, halo=True):
        p = s.part("lamp", src=src, color=color, runs=runs_of(mask))
        if halo:
            hm = halo_of(mask, s.d.solid)
            if hm.any(): p["halo"] = runs_of(hm)
        return p

    def warn(s, msg): s.warnings.append(msg)

    def ink_rect(s, x, y, w, h, what, gap=1):
        """a printed legend or mark: it may not touch another one (gap px clear)"""
        x, y, w, h = int(x), int(y), int(w), int(h)
        for (ix, iy, iw, ih, iwhat) in s.inks:
            if x - gap < ix + iw and ix < x + w + gap and y - gap < iy + ih and iy < y + h + gap:
                s.warn(f"{what} at {x},{y} {w}x{h} touches {iwhat} at {ix},{iy}")
        s.inks.append((x, y, w, h, what))

    def ink_mask(s, mask, what, gap=1):
        """a printed mark of any shape: registered row by row, so a legend may sit inside a ring's bounding box"""
        runs = runs_of(mask)
        mine = [(x, y, w, 1) for x, y, w in runs]
        for (x, y, w, h) in mine:
            for (ix, iy, iw, ih, iwhat) in s.inks:
                if x - gap < ix + iw and ix < x + w + gap and y - gap < iy + ih and iy < y + h + gap:
                    s.warn(f"{what} touches {iwhat} at {ix},{iy}"); break
        for (x, y, w, h) in mine: s.inks.append((x, y, w, h, what))

    def check_flat_mask(s, mask, what, tol=0.8):
        d = s.d
        if not (d.solid[mask]).all(): s.warn(f"{what}: hangs off the plate"); return False
        hh = d.h[mask]
        names = {d.names[m] for m in np.unique(d.mat[mask]).tolist()} - PRINTED
        if hh.max() - hh.min() > tol or len(names) > 1:
            s.warn(f"{what}: crosses surfaces (h {hh.min():.1f}..{hh.max():.1f}, {sorted(names)})"); return False
        return True

    # ---- the flat-surface check (as the dashboards')
    def check_flat(s, x, y, w, h, what, tol=0.8):
        d = s.d
        x0, y0 = max(0, int(math.floor(x))), max(0, int(math.floor(y)))
        x1, y1 = min(s.W, int(math.ceil(x + w))), min(s.H, int(math.ceil(y + h)))
        if x1 <= x0 or y1 <= y0: s.warn(f"{what}: off the plate"); return False
        if not d.solid[y0:y1, x0:x1].all(): s.warn(f"{what} at {x0},{y0} {x1 - x0}x{y1 - y0}: hangs off the plate"); return False
        hh = d.h[y0:y1, x0:x1]
        names = {d.names[m] for m in np.unique(d.mat[y0:y1, x0:x1]).tolist()} - PRINTED
        if hh.max() - hh.min() > tol or len(names) > 1:
            s.warn(f"{what} at {x0},{y0} {x1 - x0}x{y1 - y0}: crosses surfaces (h {hh.min():.1f}..{hh.max():.1f}, {sorted(names)})")
            return False
        return True

    def ink_for(s, x, y, w, h, mat):
        d = s.d
        reg = d.mat[max(0, int(y)):max(0, int(y)) + max(1, int(h)), max(0, int(x)):max(0, int(x)) + max(1, int(w))]
        names = [d.names[m] for m in np.unique(reg).tolist() if m >= 0 and d.names[m] not in PRINTED]
        if not names: return mat
        r, g, b = RAMPS[names[0]][4]
        lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
        if lum > 0.42 and mat in ("paint_w", "paint_c"): return "paint_k"
        return mat

    def label(s, t, x, y, mat="paint_w", align="l", font="35", scale=1, check=True, flatlight=True, auto_ink=True, wear=0.0, seed=0):
        w = text_w(t, font, 1, scale); hgt = font_h(font) * scale
        x0 = x - w // 2 if align == "c" else (x - w if align == "r" else x)
        if check: s.check_flat(x0, y, w, hgt, f"label '{t}'")
        s.ink_rect(x0, y, w, hgt, f"label '{t}'")
        if auto_ink: mat = s.ink_for(x0, y, w, hgt, mat)
        if wear > 0: return worn_text(s.d, t, x, y, mat, wear=wear, seed=seed or (x * 31 + y), font=font, align=align, scale=scale)
        return s.d.text(t, x, y, mat, font=font, align=align, flatlight=flatlight, scale=scale)


# ------------------------------------------------------------------ the build: base, state variants, sprites
def cut_variant(base, img):
    a = np.array(base); b_ = np.array(img)
    diff = np.any(a != b_, axis=2)
    if not diff.any(): return None, None
    ys, xs = np.nonzero(diff)
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    sub = b_[y0:y1, x0:x1].copy()
    sub[~diff[y0:y1, x0:x1], 3] = 0
    return Image.fromarray(sub, "RGBA"), (int(x0), int(y0))


def build(design, variants=(), env="room", **base_kw):
    """design(**kw) -> Plate. The base picture is design(**base_kw); each variant (name, src, when, kw) is the design
    built again with kw on top and cut down to the pixels that differ: the game draws it over the plate when the
    state `src` equals `when`. Sprites go first in the part list, so live parts (pointers, needles) draw over them."""
    p = design(**base_kw)
    base = p.d.render(chrome_env=env)
    sprites = {}; sparts = []
    for name, src, when, kw in variants:
        q = design(**{**base_kw, **kw})
        img = q.d.render(chrome_env=env)
        spr, at = cut_variant(base, img)
        if spr is None: p.warn(f"variant {name} changed nothing"); continue
        if q.hits != p.hits: p.warn(f"variant {name} moved a click area")
        sprites[name] = spr
        sparts.append({"t": "sprite", "src": src, "when": when, "sprite": name, "x": at[0], "y": at[1], "w": spr.width, "h": spr.height})
    p.parts = sparts + p.parts
    return p, base, sprites


# ------------------------------------------------------------------ dials and faces
def place_label(cx, cy, a, r_edge, w, h):
    """the top-left of a w x h legend whose nearest edge sits r_edge from (cx, cy) in direction a (degrees, y down)"""
    ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
    ext = abs(ca) * w / 2 + abs(sa) * h / 2
    mx, my = cx + ca * (r_edge + ext), cy + sa * (r_edge + ext)
    return int(round(mx - w / 2)), int(round(my - h / 2))


def scale_ring(p, cx, cy, r_in, angles, labels=None, minor_angles=(), tick=2, minor_tick=1, mat="paint_k", gap=2,
               lab_mat=None, font="35", red_from=None, wear=0.0):
    """a printed scale around a knob: major ticks at `angles` (degrees, y down), minor ticks at `minor_angles`,
    legends beyond the ticks (their near edge `gap` px out), each checked flat and clear of every other legend"""
    d = p.d
    def tick_at(a, l, m):
        ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
        lm = line_mask(d, cx + ca * r_in, cy + sa * r_in, cx + ca * (r_in + l), cy + sa * (r_in + l), 1.0)
        d.paint(lm & d.solid, m, flatlight=True)
        ys, xs = np.nonzero(lm)
        return xs, ys
    for i, a in enumerate(angles):
        tick_at(a, tick, "paint_r" if (red_from is not None and i >= red_from) else mat)
    for a in minor_angles:
        tick_at(a, minor_tick, mat)
    boxes = []
    if labels:
        fh = font_h(font)
        for a, t in zip(angles, labels):
            if not t: continue
            w = text_w(t, font)
            x0, y0 = place_label(cx, cy, a, r_in + tick + gap, w, fh)
            p.check_flat(x0, y0, w, fh, f"dial '{t}'")
            p.ink_rect(x0, y0, w, fh, f"dial '{t}' at {cx},{cy}")
            worn_text(d, t, x0, y0, lab_mat or mat, wear=wear, seed=int(cx * 7 + cy * 13 + a), font=font)
            boxes.append((x0, y0, w, fh))
    return boxes


def wedge_arc(p, cx, cy, r_in, a_from, a_to, w_from, w_to, mat="paint_k", what="flame scale"):
    """a printed tapering arc (a gas knob's flame-size scale): w_from px thick at a_from, thinning to w_to at a_to"""
    d = p.d
    rr = np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - cy)
    ang = np.degrees(np.arctan2(d.YY + 0.5 - cy, d.XX + 0.5 - cx))
    lo, hi = min(a_from, a_to), max(a_from, a_to)
    a = ang.copy()
    a[a < lo - 1e-6] += 360
    t = np.clip((a - a_from) / (a_to - a_from), 0, 1)
    inside = (a >= lo) & (a <= hi)
    wdt = w_from + (w_to - w_from) * t
    m = inside & (rr >= r_in) & (rr <= r_in + wdt)
    p.check_flat_mask(m, f"{what} at {cx},{cy}")
    p.ink_mask(m, f"{what} at {cx},{cy}")
    d.paint(m, mat, flatlight=True)
    return m


def fluted_knob(p, cx, cy, r, on=Z_FACE, z=3.6, mat="cream", skirt=2.2, skirt_mat="chrome", ridges=14, check=True, dome=0.0):
    """a round knob: a fluted cap (bakelite or plastic) on an optional bright skirt; its top is flat for a pointer"""
    d = p.d
    pad = (skirt or 0) + 1
    if check: p.check_flat(cx - r - pad, cy - r - pad, 2 * (r + pad), 2 * (r + pad), f"knob at {cx},{cy}")
    if skirt:
        d.torus(cx, cy, r - 0.5, r + skirt, 1.4, skirt_mat, polish=1.0, on=on)
    rr = np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - cy)
    ang = np.arctan2(d.YY + 0.5 - cy, d.XX + 0.5 - cx)
    flute = 0.55 * (np.cos(ang * ridges) > 0.2)
    m = rr <= r
    top = z + dome * np.clip(1 - (rr / max(1.0, r - 2.0)) ** 2, 0, 1)
    prof = np.where(rr <= r - 2.0, top, z * np.clip((r - rr) / 2.0, 0, 1) ** 0.5) - np.where(rr > r - 2.6, flute, 0)
    d.h = np.where(m, on + prof, d.h).astype(np.float32)
    d.mat[m] = d.mid(mat); d.solid |= m; d.polish[m] = 0.7; d.tex[m] = 0
    return {"cx": cx, "cy": cy, "r": r, "top": m & (rr <= r - 2.0)}


def baked_pointer(p, kn, a, r0, r1, mat="ptr_red", w=1):
    """a pointer moulded into a knob that never turns (look-only knobs): the same pixels the game would draw"""
    d = p.d
    body, edge = needle_pixels(kn["cx"], kn["cy"], a, r0, r1, w)
    m = np.zeros((d.H, d.W), bool)
    for (x, y) in body | edge:
        if 0 <= y < d.H and 0 <= x < d.W: m[y, x] = True
    d.paint(m & kn["top"], mat, flatlight=True)


def clock_face(p, cx, cy, r, face="cream", bezel="chrome", numerals=("12", "3", "6", "9"), on=Z_FACE, depth=1.5, mat="paint_k"):
    """a round clock: chrome bezel, a face, hour marks; the game draws the hands (part 'clock')"""
    d = p.d
    fm = disc(d, cx, cy, r)
    d.h[fm] = on - depth; d.mat[fm] = d.mid(face); d.solid |= fm; d.polish[fm] = 0.2; d.tex[fm] = 0
    d.torus(cx, cy, r - 0.3, r + 2.6, 2.2, bezel, polish=1.0, on=on)
    for k in range(12):
        a = -90 + k * 30
        ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
        big = k % 3 == 0
        if big and numerals: continue
        lm = line_mask(d, cx + ca * (r - 1.6), cy + sa * (r - 1.6), cx + ca * (r - (3.4 if big else 2.4)), cy + sa * (r - (3.4 if big else 2.4)), 1.0)
        d.paint(lm & fm, mat, flatlight=True)
    if numerals:
        for k, t in enumerate(numerals):
            a = -90 + k * 90
            nr = r - 5.5
            x = cx + math.cos(math.radians(a)) * nr; y = cy + math.sin(math.radians(a)) * nr
            d.text(t, int(round(x)) + (1 if t == "12" else 0), int(round(y - 2.5)), mat, align="c", flatlight=True)
    glare(d, fm, slope=-0.6, width=max(3, r // 3), offset=0.22, amount=0.07)
    d.dome(cx, cy, 1.6, 1.6, 1.0, "chrome", polish=1.0, on=on - depth)
    return {"cx": cx, "cy": cy, "rh": r * 0.5, "rm": r * 0.78}


def jewel(p, cx, cy, r, off="jewel_off", bezel="chrome", on=Z_FACE):
    """a faceted pilot-lamp jewel in a bright cup; the game lights it (part 'lamp')"""
    d = p.d
    p.check_flat(cx - r - 3, cy - r - 3, 2 * r + 6, 2 * r + 6, f"jewel at {cx},{cy}")
    d.torus(cx, cy, r - 0.2, r + 1.8, 1.8, bezel, polish=1.0, on=on)
    m = d.dome(cx, cy, r, r, 2.2, off, polish=1.0, on=on)
    ang = np.degrees(np.arctan2(d.YY + 0.5 - cy, d.XX + 0.5 - cx))
    d.tex[m & ((np.floor((ang + 22.5) / 45) % 2) == 0)] += 0.10
    return m


def window_glass(p, x, y, w, h, face="vfd", bezel="chrome", depth=1.8, on=Z_FACE, r=1, bezel_t=2, lens=True):
    """a recessed display window: its bezel lip, the glass (`face`) and the glass's one glare band"""
    p.check_flat(x - 1, y - 1, w + 2, h + 2, f"window at {x},{y}")
    return window(p.d, x, y, w, h, depth, face=face, bezel=bezel, r=r, bezel_t=bezel_t, on=on, lens=lens)


def piano_keys(p, x, y, labels, kw, kh, pressed, mat="cream", lab_mat="paint_k", on=Z_FACE, frame="chrome", font="35", mats=None,
               gap=1):
    """a row of interlocked push keys in a bright surround: the pressed one sits down in the well, the rest stand
    proud (pressing one releases the others). Returns each key's rect (the click areas)."""
    d = p.d
    n = len(labels)
    W = n * kw + (n - 1) * gap
    p.check_flat(x - 3, y - 3, W + 6, kh + 6, f"keys at {x},{y}")
    if frame: chrome_frame(d, x - 2, y - 2, W + 4, kh + 4, on, t=2, mat=frame, z=1.6)
    d.flat(rbox(d, x, y, W, kh), on - 1.5, "blackp", polish=0.2)
    rects = []
    fh = font_h(font)
    for i, t in enumerate(labels):
        kx = x + i * (kw + gap)
        down = (i == pressed) if not isinstance(pressed, (set, list, tuple)) else (i in pressed)
        m = Mask(d.W, d.H).rrect(kx, y, kw, kh, 1).get()
        d.slab(m, 0.9 if down else 3.0, (mats[i] if mats else mat), bevel=1.1, polish=0.55, on=on - 1.5)
        if t:
            d.text(t, kx + kw // 2, y + (kh - fh) // 2, lab_mat, align="c", font=font, flatlight=True)
        rects.append((kx, y, kw, kh))
    return rects


def membrane_pad(p, x, y, w, h, label=None, mat="pad_key", lab_mat="paint_k", on=Z_FACE, font="35", label2=None, frame_mat=None,
                 wear=0.0):
    """a 1990 touch pad: a printed key on a flat membrane, embossed a hair; the legend printed on it"""
    d = p.d
    p.check_flat(x - 1, y - 1, w + 2, h + 2, f"pad {label}")
    m = Mask(d.W, d.H).rrect(x, y, w, h, 1).get()
    d.slab(m, 0.7, mat, bevel=1.0, polish=0.35, on=on)
    if frame_mat:
        edge = m & ~ndi.binary_erosion(m, iterations=1)
        d.paint(edge, frame_mat, flatlight=True)
    fh = font_h(font)
    sd = x * 17 + y * 5
    if label and label2:
        worn_text(d, label, x + w // 2, y + (h - 2 * fh - 1) // 2, lab_mat, wear=wear, seed=sd, align="c", font=font)
        worn_text(d, label2, x + w // 2, y + (h - 2 * fh - 1) // 2 + fh + 1, lab_mat, wear=wear, seed=sd + 1, align="c", font=font)
    elif label:
        worn_text(d, label, x + w // 2, y + (h - fh) // 2, lab_mat, wear=wear, seed=sd, align="c", font=font)
    return (x, y, w, h)


def mesh_window(p, x, y, w, h, r=3, on=Z_FACE, depth=2.0, bezel="enamel_white", lit=False, crop_left=False):
    """a microwave door's window: dark glass over a perforated screen (a staggered grid of holes); `lit` shows the
    oven lamp behind it (the holes glow, brightest in the middle). Returns the window's mask."""
    d = p.d
    xx0 = x - (r + 2 if crop_left else 0)
    inner = Mask(d.W, d.H).rrect(xx0, y, w + (x - xx0), h, r).get()
    d.h[inner] = on - depth; d.mat[inner] = d.mid("mesh"); d.solid |= inner; d.polish[inner] = 0.1; d.tex[inner] = 0
    yy, xx = d.YY - y, d.XX - x
    holes = inner & (yy % 2 == 0) & (((xx + (yy // 2 % 2)) % 2) == 0)
    # keep a clear margin of sheet round the edge of the screen
    rim = ndi.binary_erosion(inner, iterations=3)
    holes &= rim
    if lit:
        cx, cy = x + w / 2, y + h / 2
        u = np.hypot((d.XX + 0.5 - cx) / (w / 2), (d.YY + 0.5 - cy) / (h / 2))
        for lo, hi, col in ((0.0, 0.62, "#ffe2a0"), (0.62, 0.86, "#f4bd66"), (0.86, 1.01, "#cf8e44"), (1.01, 9, "#9a5e2a")):
            d.glow(holes & (u >= lo) & (u < hi), col)
        sheet = inner & ~holes
        d.mat[sheet] = d.mid("mesh_lit")
    else:
        d.paint(holes, "hole", flatlight=True)
    glare(d, inner, slope=-0.9, width=max(6, w // 14), offset=0.30, amount=0.09)
    return inner


def outlet_duplex(p, cx, cy, on=Z_FACE, mat="socket", plate_mat="steel", w=22, h=30):
    """a NEMA 5-15 duplex receptacle: the wall plate, two faces, two slots and a ground hole each.
    Returns the upper face's centre (where a plug goes)."""
    d = p.d
    x, y = int(cx - w // 2), int(cy - h // 2)
    p.check_flat(x - 1, y - 1, w + 2, h + 2, f"outlet at {cx},{cy}")
    plate = Mask(d.W, d.H).rrect(x, y, w, h, 2).get()
    d.slab(plate, 1.2, plate_mat, bevel=1.0, polish=0.6, on=on)
    faces = []
    for fy in (y + 3, y + h - 13):
        face = Mask(d.W, d.H).rrect(x + 3, fy, w - 6, 10, 3).get()
        d.slab(face, 1.6, mat, bevel=1.0, polish=0.5, on=on + 1.2)
        for sx, sh in ((x + 7, 4), (x + w - 9, 3)):
            d.well(rbox(d, sx, fy + 2, 1, sh), 1.2, "blackp", bevel=0.4)
        d.well(Mask(d.W, d.H).ellipse(cx, fy + 8, 1.2, 1.0).get(), 1.2, "blackp", bevel=0.4)
        faces.append((x + 3, fy, w - 6, 10))
    screw(p, cx, cy, on=on + 1.2, mat="steel")
    return faces


def plug(p, face, on=Z_FACE, cord_to=None, mat="cord"):
    """a heavy cord's plug pushed into an outlet face; the cord drops to `cord_to` (y) and off the plate"""
    d = p.d
    fx, fy, fw, fh = face
    body = Mask(d.W, d.H).rrect(fx - 1, fy - 1, fw + 2, fh + 3, 3).get()
    d.slab(body, 4.2, mat, bevel=2.0, polish=0.5, on=on + 1.2)
    # grip ribs across the plug's face
    for k in range(3):
        d.seam(rbox(d, fx + 2, fy + 2 + k * 3, fw - 4, 1) & body, 0.35)
    # the strain relief and the cord
    cx = fx + fw // 2
    relief = Mask(d.W, d.H).rrect(cx - 3, fy + fh + 1, 6, 5, 1).get()
    d.slab(relief, 3.6, mat, bevel=1.5, polish=0.5, on=on)
    if cord_to:
        d.cyl(cx - 2, fy + fh + 5, 4, cord_to - (fy + fh + 5), 3.0, mat, axis="v", polish=0.6, on=on)
    return body


def screw(p, cx, cy, on=Z_FACE, mat="chrome", slot=True):
    d = p.d
    m = d.dome(cx, cy, 1.9, 1.9, 1.1, mat, polish=1.0, on=on)
    if slot:
        d.seam(rbox(d, int(cx - 1), int(cy), 3, 1) & m, 0.45)
    return m


def burner_icon(p, x, y, which, mat="paint_k"):
    """the four-burner position diagram printed under a burner knob: `which` in LF, LR, RF, RR"""
    d = p.d
    pos = {"LR": (0, 0), "RR": (4, 0), "LF": (0, 4), "RF": (4, 4)}
    for k, (ox, oy) in pos.items():
        m = rbox(d, x + ox, y + oy, 3, 3)
        if k != which: m &= ~rbox(d, x + ox + 1, y + oy + 1, 1, 1)
        d.paint(m, mat, flatlight=True)
    p.check_flat(x, y, 7, 7, f"burner diagram {which}")
    p.ink_rect(x, y, 7, 7, f"burner diagram {which}")


def breaker(p, cx, cy, on=Z_FACE, mat="blackp"):
    """a push-to-reset breaker: a black boot in a steel collar"""
    d = p.d
    p.check_flat(cx - 6, cy - 6, 12, 12, f"breaker at {cx},{cy}")
    d.torus(cx, cy, 3.6, 5.2, 1.4, "steel", polish=0.8, on=on)
    d.dome(cx, cy, 3.6, 3.6, 3.2, mat, polish=0.4, on=on, power=0.6)
    return {"cx": cx, "cy": cy}


def binding_post(p, cx, cy, mat, on=Z_FACE):
    """a DC terminal: a coloured insulated cap on a hex nut"""
    d = p.d
    p.check_flat(cx - 5, cy - 5, 10, 10, f"terminal at {cx},{cy}")
    d.dome(cx, cy, 4.4, 4.4, 1.2, "steel", polish=0.8, on=on, power=0.3)
    d.dome(cx, cy, 3.2, 3.2, 3.4, mat, polish=0.8, on=on, power=0.5)
    return {"cx": cx, "cy": cy}


def rocker_switch(p, x, y, w, h, on_top_pressed, on=Z_FACE, mat="blackp", bezel_mat="blackp", lift=2.4):
    """a big panel rocker in its bezel: the pressed half sits down in the bezel, the other half stands proud and
    shades it (light from above: a raised top half throws its shadow on the bottom half)"""
    d = p.d
    p.check_flat(x - 3, y - 3, w + 6, h + 6, f"rocker at {x},{y}")
    bez = Mask(d.W, d.H).rrect(x - 2, y - 2, w + 4, h + 4, 2).get()
    d.slab(bez, 1.0, bezel_mat, bevel=1.0, polish=0.5, on=on)
    m = Mask(d.W, d.H).rrect(x, y, w, h, 1).get()
    d.slab(m, 0.6, mat, bevel=0.8, polish=0.35, on=on + 0.4)
    yy = d.YY + 0.5 - y
    half = h / 2.0
    if on_top_pressed:      # the bottom half stands: rising from the middle to its far edge
        t = np.clip((yy - half) / half, 0, 1)
    else:                   # the top half stands
        t = np.clip((half - yy) / half, 0, 1)
    d.h[m] += (lift * (0.35 + 0.65 * t) * (t > 0)).astype(np.float32)[m]
    # the hinge line across the middle
    d.seam(rbox(d, x + 1, y + h // 2, w - 2, 1) & m, 0.3)
    return m


def tube_frame(p, x, y, w, h, r, thick, mat="steel", on=Z_FACE, z=3.0):
    """a bent tube frame round a machine (a portable generator's roll cage): a round section all the way round"""
    from engine import edt
    d = p.d
    outer = Mask(d.W, d.H).rrect(x, y, w, h, r).get()
    inner = Mask(d.W, d.H).rrect(x + thick, y + thick, w - 2 * thick, h - 2 * thick, max(0, r - thick)).get()
    m = outer & ~inner
    e = edt(m)
    half = thick / 2.0
    t = np.clip(1.0 - e / half, 0, 1)
    prof = np.sqrt(np.clip(1 - t ** 2, 0, 1)) * z
    d.h = np.where(m, on + prof, d.h).astype(np.float32)
    d.mat[m] = d.mid(mat); d.solid |= m; d.polish[m] = 0.8; d.tex[m] = 0
    return m


def wing_nut(p, cx, cy, on=Z_FACE, mat="steel"):
    """a ground terminal: a stud with a wing nut"""
    d = p.d
    p.check_flat(cx - 7, cy - 4, 14, 8, f"wing nut at {cx},{cy}")
    d.dome(cx, cy, 2.6, 2.6, 2.4, mat, polish=0.9, on=on)
    for sx in (-1, 1):
        wing = Mask(d.W, d.H).ellipse(cx + sx * 4.5, cy, 2.6, 1.8).get()
        d.slab(wing, 1.6, mat, bevel=0.8, polish=0.9, on=on)
    d.dome(cx, cy, 1.4, 1.4, 3.2, mat, polish=1.0, on=on)


def fuel_gauge(p, cx, cy, r, on=Z_FACE, face="cream", bezel="chrome", a0=225, a1=315, label="FUEL"):
    """a small tank gauge: a round face, the pointer pivoting low on it and swinging E (left) to F (right) over a
    short arc, the letters below the arc's ends. Returns the live needle's anchor (part 'needle')."""
    d = p.d
    p.check_flat(cx - r - 3, cy - r - 3, 2 * r + 6, 2 * r + 6, f"gauge at {cx},{cy}")
    fm = disc(d, cx, cy, r)
    d.h[fm] = on - 1.6; d.mat[fm] = d.mid(face); d.solid |= fm; d.polish[fm] = 0.15; d.tex[fm] = 0
    d.torus(cx, cy, r - 0.3, r + 2.6, 2.2, bezel, polish=1.0, on=on)
    pvx, pvy = cx, cy + r * 0.38
    arc_r = r * 0.80
    for i in range(5):
        a = a0 + (a1 - a0) * i / 4
        ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
        l = 3.0 if i % 2 == 0 else 2.0
        lm = line_mask(d, pvx + ca * (arc_r - l), pvy + sa * (arc_r - l), pvx + ca * arc_r, pvy + sa * arc_r, 1.0)
        d.paint(lm & fm, "paint_r" if i == 0 else "paint_k", flatlight=True)
    ca0, sa0 = math.cos(math.radians(a0)), math.sin(math.radians(a0))
    ca1, sa1 = math.cos(math.radians(a1)), math.sin(math.radians(a1))
    ex, ey = pvx + ca0 * arc_r, pvy + sa0 * arc_r
    fx, fy = pvx + ca1 * arc_r, pvy + sa1 * arc_r
    d.text("E", int(round(ex)) - 1, int(round(ey)) + 3, "paint_r", align="c", flatlight=True)
    d.text("F", int(round(fx)) + 1, int(round(fy)) + 3, "paint_k", align="c", flatlight=True)
    if label:
        d.text(label, cx, int(round(pvy)) + 4, "paint_k", align="c", flatlight=True)
    glare(d, fm, slope=-0.6, width=max(3, r // 3), offset=0.22, amount=0.07)
    d.dome(pvx, pvy, 2.2, 2.2, 1.4, "blackp", polish=0.9, on=on - 1.6)
    return {"cx": pvx, "cy": pvy, "r0": -2, "r1": arc_r - 1, "a0": a0, "a1": a1}


def louvers(p, x, y, w, h, n, on=Z_FACE, depth=2.0):
    """a row of vertical slots pressed into a housing"""
    d = p.d
    pitch = (w - 4) / n
    for i in range(n):
        sx = int(x + 2 + i * pitch)
        m = Mask(d.W, d.H).rrect(sx, y, max(2, int(pitch) - 3), h, 1).get()
        d.well(m, depth, "blackp", bevel=0.8)


def sticker(p, x, y, w, h, head, lines=3, mat="decal_y", ink="paint_k"):
    """a printed warning label: a header word and a few lines of small print (too small to read, like the real thing)"""
    d = p.d
    p.check_flat(x, y, w, h, f"sticker {head}")
    m = rbox(d, x, y, w, h)
    d.slab(m, 0.25, mat, bevel=0.5, polish=0.3, on="h")
    d.text(head, x + w // 2, y + 2, ink, align="c", flatlight=True)
    rr = np.random.default_rng(len(head) * 31 + w)
    for i in range(lines):
        ly = y + 9 + i * 3
        if ly + 1 > y + h - 2: break
        lw = int((w - 6) * (0.65 + 0.35 * rr.random()))
        d.paint(rbox(d, x + 3, ly, lw, 1), ink, flatlight=True)
    p.ink_rect(x, y, w, h, f"sticker {head}")


# ------------------------------------------------------------------ more parts (the full set)
def insert_knob(p, cx, cy, r, on=Z_FACE, cap="bakelite", insert="chrome", skirt=None, ridges=16, dome=0.6, insert_r=None):
    """a 60s knob: a fluted black cap with a bright disc set in its face (the game draws the pointer over it)"""
    kn = fluted_knob(p, cx, cy, r, on=on, z=3.6, mat=cap, skirt=skirt, ridges=ridges, dome=dome)
    ir = insert_r or max(2.0, r * 0.45)
    p.d.dome(cx, cy, ir, ir, 0.9, insert, polish=1.0, on=on + 3.6 + dome * 0.5)
    return kn


def knurled_knob(p, cx, cy, r, on=Z_FACE, mat="blackp", z=4.4, ridges=30, skirt=None, skirt_mat="steel"):
    """a big commercial knob: black, finely knurled round its edge, a flat top for the pointer"""
    return fluted_knob(p, cx, cy, r, on=on, z=z, mat=mat, skirt=skirt, skirt_mat=skirt_mat, ridges=ridges, dome=0.4)


def bat_toggle(p, cx, cy, up, on=Z_FACE, guard=False):
    """an aircraft bat toggle on its nut (up = on); with `guard`, two bright wire guards stand either side"""
    d = p.d
    p.check_flat(cx - 6, cy - 13, 12, 26, f"toggle at {cx},{cy}")
    if guard:
        for gx in (cx - 6, cx + 5):
            d.cyl(gx, cy - 12, 2, 24, 3.2, "chrome", axis="v", polish=1.0, on=on)
    toggle(d, cx, cy, up=up, on=on)
    return {"cx": cx, "cy": cy}


def lamp_text(p, t, x, y, src, color, off="ledoff", align="l", font="35"):
    """a legend printed dark on a display's glass that lights when `src` is set (COOK, BAKE, TIMER...)"""
    m = p.d.text(t, x, y, off, align=align, font=font, flatlight=True)
    p.lamp(m, src, color, halo=False)
    ys, xs = np.nonzero(m)
    if len(xs): p.ink_rect(xs.min(), ys.min(), xs.max() - xs.min() + 1, ys.max() - ys.min() + 1, f"lamp legend '{t}'")
    return m


def glass_panel(p, x, y, w, h, on=Z_FACE, r=2, mat="blackglass", glare_at=0.22, frame=None):
    """a black glass control panel: flat, polished, one broad glare band and a thin one beside it"""
    d = p.d
    m = Mask(d.W, d.H).rrect(x, y, w, h, r).get()
    d.flat(m, on, mat, polish=0.9)
    if frame: chrome_frame(d, x - 1, y - 1, w + 2, h + 2, on - 0.6, t=1, mat=frame, z=1.0)
    return m


def screw_head(p, cx, cy, on=Z_FACE, mat="steel"):
    return screw(p, cx, cy, on=on, mat=mat)


def data_plate(p, x, y, w, h, lines, on=Z_FACE, mat="alu", ink="paint_k", rivets=True, title=None):
    """a riveted maker's or data plate: a thin metal plate, rivets in its corners, stamped lines of small print"""
    d = p.d
    p.check_flat(x - 1, y - 1, w + 2, h + 2, f"data plate at {x},{y}")
    m = Mask(d.W, d.H).rrect(x, y, w, h, 1).get()
    d.slab(m, 0.6, mat, bevel=0.6, polish=0.6, on=on)
    yy = y + 3
    if title:
        d.text(title, x + w // 2, yy, ink, align="c", flatlight=True); yy += 7
    for ln in lines:
        if yy + 5 > y + h - 2: break
        d.text(ln, x + 5, yy, ink, flatlight=True); yy += 7
    if rivets:
        for (rx, ry) in ((x + 2.5, y + 2.5), (x + w - 2.5, y + 2.5), (x + 2.5, y + h - 2.5), (x + w - 2.5, y + h - 2.5)):
            d.dome(rx, ry, 1.4, 1.4, 1.0, mat, polish=1.0, on=on + 0.6)
    p.ink_rect(x, y, w, h, f"data plate at {x},{y}")
    return m


def arrow_icon(p, cx, cy, up=True, mat="paint_w", w=7, h=4):
    """a filled triangle (an UP or DOWN pad's arrow)"""
    d = p.d
    if up: pts = [(cx - w / 2, cy + h / 2), (cx + w / 2, cy + h / 2), (cx, cy - h / 2)]
    else: pts = [(cx - w / 2, cy - h / 2), (cx + w / 2, cy - h / 2), (cx, cy + h / 2)]
    m = Mask(d.W, d.H).poly(pts).get(0.45)
    d.paint(m, mat, flatlight=True)
    return m


def glass_pad(p, x, y, w, h, label=None, ink="paint_w", outline="glassline", font="35", label2=None, icon=None):
    """a touch pad printed on black glass: a thin outline, its legend (or an arrow); flat, it is all glass"""
    d = p.d
    m = Mask(d.W, d.H).rrect(x, y, w, h, 2).get()
    edge = m & ~ndi.binary_erosion(m, iterations=1)
    d.paint(edge, outline, flatlight=True)
    fh = font_h(font)
    if icon == "up": arrow_icon(p, x + w / 2, y + h / 2, True, ink)
    elif icon == "down": arrow_icon(p, x + w / 2, y + h / 2, False, ink)
    elif label and label2:
        d.text(label, x + w // 2, y + (h - 2 * fh - 1) // 2, ink, align="c", font=font, flatlight=True)
        d.text(label2, x + w // 2, y + (h - 2 * fh - 1) // 2 + fh + 1, ink, align="c", font=font, flatlight=True)
    elif label:
        d.text(label, x + w // 2, y + (h - fh) // 2, ink, align="c", font=font, flatlight=True)
    p.ink_rect(x, y, w, h, f"glass pad {label or icon}")
    return (x, y, w, h)


def twist_lock(p, cx, cy, r=11, on=Z_FACE, mat="socket", plate_mat="steel"):
    """a locking receptacle (120/240 volt, 30 amp): a round face in a square plate, four curved slots on a circle"""
    d = p.d
    s = r + 4
    p.check_flat(cx - s - 1, cy - s - 1, 2 * s + 2, 2 * s + 2, f"locking outlet at {cx},{cy}")
    plate = Mask(d.W, d.H).rrect(cx - s, cy - s, 2 * s, 2 * s, 2).get()
    d.slab(plate, 1.2, plate_mat, bevel=1.0, polish=0.6, on=on)
    d.dome(cx, cy, r, r, 1.8, mat, polish=0.5, on=on + 1.2, power=0.25)
    rr = np.hypot(d.XX + 0.5 - cx, d.YY + 0.5 - cy)
    ang = np.degrees(np.arctan2(d.YY + 0.5 - cy, d.XX + 0.5 - cx)) % 360
    for a0 in (20, 110, 200, 290):
        sl = (rr >= r * 0.48) & (rr <= r * 0.68) & (((ang - a0) % 360) < 34)
        d.well(sl, 1.0, "blackp", bevel=0.4)
    d.well(disc(d, cx, cy + r * 0.15, 1.2), 1.0, "blackp", bevel=0.4)
    for sx, sy in ((cx - s + 3, cy - s + 3), (cx + s - 4, cy + s - 4)):
        screw(p, sx, sy, on=on + 1.2, mat="steel")
    return {"cx": cx, "cy": cy, "r": r}


def twist_plug(p, cx, cy, r=12, on=Z_FACE, cord_to=None, mat="cord"):
    """a locking plug turned home in its receptacle; its cord drops off the plate"""
    d = p.d
    body = disc(d, cx, cy, r)
    d.slab(body, 4.6, mat, bevel=2.4, polish=0.5, on=on + 1.2)
    ang = np.degrees(np.arctan2(d.YY + 0.5 - cy, d.XX + 0.5 - cx))
    rim = ring(d, cx, cy, r - 2.2, r - 0.6)
    d.seam(rim & ((np.floor(ang / 20) % 2) == 0), 0.3)
    if cord_to:
        relief = Mask(d.W, d.H).rrect(cx - 4, cy + r - 2, 8, 7, 2).get()
        d.slab(relief, 4.0, mat, bevel=1.6, polish=0.5, on=on)
        d.cyl(cx - 3, cy + r + 4, 6, cord_to - (cy + r + 4), 3.4, mat, axis="v", polish=0.6, on=on)
    return body


def outlet_cover(p, cx, cy, w=22, h=30, on=Z_FACE, mat="rubber", label=None):
    """a duplex outlet behind its hinged rubber weather cover (closed): a soft lid, the hinge across its top"""
    d = p.d
    x, y = int(cx - w // 2), int(cy - h // 2)
    p.check_flat(x - 1, y - 1, w + 2, h + 2, f"covered outlet at {cx},{cy}")
    frame = Mask(d.W, d.H).rrect(x, y, w, h, 2).get()
    d.slab(frame, 1.2, "steel", bevel=1.0, polish=0.5, on=on)
    lid = Mask(d.W, d.H).rrect(x + 2, y + 5, w - 4, h - 7, 3).get()
    d.slab(lid, 2.6, mat, bevel=2.0, polish=0.3, on=on + 1.2)
    d.cyl(x + 3, y + 2, w - 6, 3, 1.6, mat, axis="h", polish=0.3, on=on + 1.2)
    if label:
        m = d.text(label, cx, y + h // 2, "paint_k", align="c", flatlight=True)
        d.h[m] -= 0.2
    return frame


def rect_meter(p, x, y, w, h, labels, a0, a1, on=Z_FACE, case="blackp", face="cream", ink="paint_k", title=None, red_from=None):
    """a panel meter: a black case, a white face with an arc scale across its top, the figures above the ticks,
    the unit under the arc; the needle pivots low in the face. Returns the live needle's anchor (part 'needle')."""
    d = p.d
    p.check_flat(x - 1, y - 1, w + 2, h + 2, f"meter at {x},{y}")
    cs = Mask(d.W, d.H).rrect(x, y, w, h, 2).get()
    d.slab(cs, 2.0, case, bevel=1.2, polish=0.6, on=on)
    fx, fy, fw, fh = x + 4, y + 4, w - 8, h - 8
    fm = rbox(d, fx, fy, fw, fh)
    d.h[fm] = on + 1.0; d.mat[fm] = d.mid(face); d.solid |= fm; d.polish[fm] = 0.2; d.tex[fm] = 0
    pvx, pvy = x + w / 2, fy + fh - 2
    R = fh - 10
    n = len(labels)
    for i in range(n):
        a = a0 + (a1 - a0) * i / (n - 1)
        ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
        red = red_from is not None and i >= red_from
        lm = line_mask(d, pvx + ca * (R - 3), pvy + sa * (R - 3), pvx + ca * R, pvy + sa * R, 1.0)
        d.paint(lm & fm, "paint_r" if red else ink, flatlight=True)
        if i < n - 1:
            for k in (1,):
                am = a + (a1 - a0) / (n - 1) * k / 2
                cm, sm = math.cos(math.radians(am)), math.sin(math.radians(am))
                lm2 = line_mask(d, pvx + cm * (R - 1.5), pvy + sm * (R - 1.5), pvx + cm * R, pvy + sm * R, 1.0)
                d.paint(lm2 & fm, ink, flatlight=True)
        t = labels[i]
        if t:
            tw = text_w(t)
            lx = pvx + ca * (R + 4); ly = pvy + sa * (R + 4)
            x0 = int(round(lx - tw / 2)); x0 = max(fx + 1, min(fx + fw - 1 - tw, x0))
            y0 = int(round(ly - 2.5)); y0 = max(fy + 1, y0)
            d.text(t, x0, y0, "paint_r" if red else ink, flatlight=True)
    if title:
        d.text(title, int(pvx), int(pvy - R + 5), ink, align="c", flatlight=True)
    glare(d, fm, slope=-0.6, width=max(3, fw // 6), offset=0.25, amount=0.06)
    d.dome(pvx, pvy, 1.8, 1.8, 1.2, "blackp", polish=0.9, on=on + 1.0)
    return {"cx": pvx, "cy": pvy, "r0": -2, "r1": R - 1, "a0": a0, "a1": a1}


def round_meter(p, cx, cy, r, labels, a0=135, a1=405, on=Z_FACE, title=None):
    """a 60s military round meter: a black bakelite case, a black face, white scale; returns the needle anchor"""
    d = p.d
    p.check_flat(cx - r - 4, cy - r - 4, 2 * r + 8, 2 * r + 8, f"round meter at {cx},{cy}")
    d.slab(disc(d, cx, cy, r + 3), 1.8, "bakelite", bevel=1.6, polish=0.7, on=on)
    major = list(range(len(labels)))
    an = gauge(d, cx, cy, r, a0, a1, major, minor=1, labels=labels, bezel=None, face="face", depth=0.8, on=on + 1.8,
               tick_mat="paint_w", num_mat="paint_w", num_r=r - 8, label=title, label_y=cy + r * 0.42, lab_mat="paint_w", hub=2.0)
    return an


def terminal_board(p, x, y, labels, on=Z_FACE, pitch=20):
    """load terminals: a black insulating board, a stud and wing nut per lead, the lead's name over it"""
    d = p.d
    w = pitch * len(labels) + 6
    p.check_flat(x - 1, y - 1, w + 2, 30, f"terminal board at {x},{y}")
    board = Mask(d.W, d.H).rrect(x, y, w, 28, 2).get()
    d.slab(board, 1.6, "bakelite", bevel=1.0, polish=0.5, on=on)
    studs = []
    for i, t in enumerate(labels):
        sx = x + 3 + pitch // 2 + i * pitch
        d.text(t, sx, y + 3, "paint_w", align="c", flatlight=True)
        wing_nut(p, sx, y + 18, on=on + 1.6)
        studs.append((sx, y + 18))
    return studs
