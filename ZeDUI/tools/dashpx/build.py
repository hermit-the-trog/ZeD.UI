"""Builds the dashboards: plate PNG, state sprites, the parts file, and previews of the live parts at a few states.
usage: python build.py [design ...]   (no names: all)"""
import copy
import json
import os
import sys
import time
import numpy as np
from PIL import Image, ImageDraw
try:
    from scipy import ndimage  # noqa: F401
except ImportError:          # no scipy here: the same calls in plain numpy (the radio faces in ../physpx ask for it by name)
    import ndi_np
    ndi_np.install_as_scipy()
import dashlib
from dashlib import Build, tab_sprite, TAB_SPRITES
from live import render_live, needle_pixels
import designs as DZ
import radios

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out")
os.makedirs(OUT, exist_ok=True)

STATES = {
    "off": dict(keysIn=False, keyPos=None, ashOpen=False, meterOn=False, hula=0, running=False, lights=False, speed_kmh=0, rpm=0, fuel=0.6, battery=0.8, heaterOn=False, heaterTemp=0, fan=0,
                gear="P", hour=10, minute=8),
    "keyon": dict(keysIn=True, keyPos="off", ashOpen=False, meterOn=False, hula=0, running=False, lights=False, speed_kmh=0, rpm=0, fuel=0.62, battery=0.9, heaterOn=False, heaterTemp=0,
                  fan=0, radio=None, radioOn=False, gear="P", anyLocked=False, hour=10, minute=8),
    "drive": dict(keysIn=True, keyPos="on", meterOn=True, hula=1, fare=12.80, fareExtra=0.5, running=True, lights=True, speed_kmh=72, rpm=2600, fuel=0.62, battery=0.9, heaterOn=True, heaterTemp=17,
                  fan=2, ac=False, radio="valutech", radioOn=True, radioFreq="98.4", gear="D", anyLocked=True, cruise=True,
                  lightbar=2, siren=1, hour=10, minute=8),
}


def badge_names(did):
    title, cabin, seed, fn, sub, unit, radio = DZ.DESIGNS[did]
    words = title.upper().split()
    make, model = (words[0], " ".join(words[1:])) if len(words) > 1 else (words[0], words[0])
    return {"badge_full": title.upper(), "badge_make": make, "badge_model": model, "badge_sub": sub or "", "badge_unit": unit or "",
            "radio": radio}


def cut_variant(base, img):
    a = np.array(base); b_ = np.array(img)
    diff = np.any(a != b_, axis=2)
    if not diff.any(): return None, None
    ys, xs = np.nonzero(diff)
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    sub = b_[y0:y1, x0:x1].copy()
    sub[~diff[y0:y1, x0:x1], 3] = 0
    return Image.fromarray(sub, "RGBA"), (int(x0), int(y0))


NEEDLE_STEPS = 60       # readings per needle sweep (the check below), end to end


def _part_pixels(p):
    """the plate pixels a live part (not a needle) draws on: its runs and halo, or its box"""
    px = set()
    for key in ("runs", "halo"):
        for (x, y, w) in p.get(key) or ():
            px.update((x + i, y) for i in range(w))
    if all(k in p for k in ("x", "y", "w", "h")):
        px.update((xx, yy) for yy in range(p["y"], p["y"] + p["h"]) for xx in range(p["x"], p["x"] + p["w"]))
    return px


def _own_hub(b, n):
    """a needle's own hub: the shroud the design registered at its pivot (Build.hub), else the dome on the pivot"""
    d = b.d
    m = np.zeros(d.solid.shape, bool)
    for (hx_, hy_, hm) in b.hubs:
        if abs(hx_ - n["cx"]) < 1.5 and abs(hy_ - n["cy"]) < 1.5: m |= hm
    if m.any(): return m
    x, y = int(n["cx"]), int(n["cy"])
    if not (0 <= x < dashlib.W and 0 <= y < dashlib.H) or not d.solid[y, x]: return m
    rh = max(float(n.get("hub") or 0), -float(n["r0"]) if n["r0"] < 0 else 0.0, 2.2) + 1.0
    disc = np.hypot(d.XX + 0.5 - n["cx"], d.YY + 0.5 - n["cy"]) <= rh
    return disc & d.solid & (d.mat == d.mat[y, x])


def needle_check(b):
    """every needle, swept through its whole travel, stays on its dial: on the face, on the face's print (a needle over
    a legend is allowed, real gauges do it) or on its own hub; and crosses no other needle's sweep and no other live
    part (a lamp, an LED, an odometer). A miss stops the export (Oct 29 2026: the D6's speedometer rose out of its bezel)"""
    d = b.d
    ok_mat = np.array([nm == "face" or nm in dashlib.PRINTED for nm in d.names], bool)
    needles = [p for p in b.parts if p["t"] == "needle"]
    others = {}
    for p in b.parts:
        if p["t"] == "needle": continue
        px = _part_pixels(p)
        if px: others.setdefault(f'{p["t"]} {p.get("src", p.get("sprite", p.get("role", "?")))}', set()).update(px)
    sweeps = []
    for n in needles:
        hub = _own_hub(b, n)
        top = 1.02 if n.get("peg") else 1.0
        off, seen = {}, set()
        for i in range(NEEDLE_STEPS + 1):
            f = top * i / NEEDLE_STEPS
            a = n["a0"] + (n["a1"] - n["a0"]) * f
            body, edge = needle_pixels(n["cx"], n["cy"], a, n["r0"], n["r1"], n.get("w", 2), n.get("hub", 0) or 0)
            px = body | edge
            seen |= px
            for (x, y) in px:
                if not (0 <= x < dashlib.W and 0 <= y < dashlib.H) or not d.solid[y, x]: what = "off the plate"
                elif ok_mat[d.mat[y, x]] or hub[y, x]: continue
                else: what = d.names[d.mat[y, x]]
                rd = off.setdefault(what, [0, set()]); rd[0] += 1; rd[1].add(round(f * n.get("max", 1), 2))
        for what, (cnt, vals) in off.items():
            b.warn(f"needle {n['src']} at {n['cx']},{n['cy']} leaves its face: {cnt} px over {what} at readings "
                   f"{min(vals):g}..{max(vals):g}")
        for k_, px in others.items():
            if seen & px: b.warn(f"needle {n['src']} at {n['cx']},{n['cy']} sweeps over the {k_}")
        sweeps.append((n, seen))
    for i, (n, s_) in enumerate(sweeps):
        for (m, t_) in sweeps[i + 1:]:
            if s_ & t_: b.warn(f"needles {n['src']} and {m['src']} cross ({len(s_ & t_)} px)")


def _rect_hits(mask, x, y, w, h):
    H_, W_ = mask.shape
    x0, y0, x1, y1 = max(0, int(x)), max(0, int(y)), min(W_, int(x + w)), min(H_, int(y + h))
    return x1 > x0 and y1 > y0 and bool(mask[y0:y1, x0:x1].any())


def mover_check(b):
    """Oct 29 2026: the key in each position, its ring and its fob (b.movers) sit over no printed legend or mark; and
    the column's shroud (b.shroud) is clear of every printed mark, live part, click area and the key"""
    for name, m in b.movers:
        for (ix, iy, iw, ih, what) in b.inks:
            if _rect_hits(m, ix, iy, iw, ih): b.warn(f"{what} at {ix},{iy} lies under {name}")
        if b.shroud is not None and (m & b.shroud).any(): b.warn(f"{name} reaches into the column's shroud")
    if b.shroud is None: return
    s = b.shroud
    for (ix, iy, iw, ih, what) in b.inks:
        if _rect_hits(s, ix, iy, iw, ih): b.warn(f"{what} at {ix},{iy} lies under the column's shroud")
    for h in b.hits:
        if _rect_hits(s, h["x"], h["y"], h["w"], h["h"]): b.warn(f"the {h['id']} click area reaches into the column's shroud")
    for p in b.parts:
        if p["t"] in ("needle", "sprite"): continue
        if any(0 <= y < s.shape[0] and 0 <= x < s.shape[1] and s[y, x] for (x, y) in _part_pixels(p)):
            b.warn(f"the {p['t']} {p.get('src', '?')} lies on the column's shroud")


def build_one(did, verbose=True):
    title, cabin, seed, fn, sub, unit, radio = DZ.DESIGNS[did]
    t0 = time.time()
    b = Build(did, cabin, seed=seed, title=title)
    fn(b)
    base = b.d.render()
    sprites = {}
    for name, src, vfn, when in b.variants:
        d2 = copy.deepcopy(b.d)
        vfn(d2)
        img = d2.render()
        spr, at = cut_variant(base, img)
        if spr is None: b.warn(f"variant {name} changed nothing"); continue
        sprites[name] = spr
        b.part("sprite", src=src, when=when, sprite=name, x=at[0], y=at[1], w=spr.width, h=spr.height)
    for name, im in getattr(b, "extra", {}).items():     # hand-set sprites (round 6: the taxi's hula girl)
        sprites[name] = im
    for k in TAB_SPRITES:
        if any(p.get("sprite") == k for p in b.parts): sprites[k] = tab_sprite(k)
    # a lever tab or slider knob sweeps its whole travel: no printed legend or mark may lie under it anywhere
    for p in b.parts:
        if p["t"] != "tab" or p["sprite"] not in sprites: continue
        sw, sh = sprites[p["sprite"]].size
        rx0, ry0, rx1, ry1 = p["x0"], p["y"], p["x1"] + sw, p["y"] + sh
        for (ix, iy, iw, ih, what) in b.inks:
            if ix < rx1 and ix + iw > rx0 and iy < ry1 and iy + ih > ry0:
                b.warn(f"{what} at {ix},{iy} lies under the {p['src']} tab's travel ({rx0},{ry0} to {rx1},{ry1})")
    mover_check(b)
    needle_check(b)
    ddir = os.path.join(OUT, did); os.makedirs(ddir, exist_ok=True)
    base.save(os.path.join(ddir, f"dash_{did}.png"))
    for k, im in sprites.items(): im.save(os.path.join(ddir, f"{k}.png"))
    meta = {kk: vv for kk, vv in b.meta.items() if kk != "face_mask"}
    doc = {"id": did, "title": title, "cabin": cabin, "w": dashlib.W, "h": dashlib.H, "meta": meta, "parts": b.parts, "hits": b.hits,
           "sprites": {k: [im.width, im.height] for k, im in sprites.items()}}
    with open(os.path.join(ddir, f"dash_{did}.json"), "w") as f: json.dump(doc, f, separators=(",", ":"))
    return b, base, sprites, doc, time.time() - t0


DECALS = os.environ.get("ZED_DECALS", "/mnt/user-data/uploads/Project Zomboid/SteamApps/common/ProjectZomboid/media/textures/shirtdecals")
ASH_OPEN = {"taxi": 3, "d6": 2, "bulldriver": 3, "horizon": 1, "rancher": 2, "cossette": 1, "dart": 2}   # the previews' used trays


def preview(did, base, sprites, doc, heads=None, state="drive", k=1, extra=None, night=None):
    st = dict(STATES[state]); st.update(badge_names(did))
    if state == "drive": st["ashOpen"] = ASH_OPEN.get(did, 0)
    if did == "van" and state != "off":        # the previews' van is the Spiffo's
        p_ = os.path.join(DECALS, "Buisness_SpiffosDECAL.png")
        if os.path.exists(p_): st["sticker_im"] = Image.open(p_).convert("RGBA")
    if state in ("off", "keyon"): st["radioOn"] = False
    if extra: st.update(extra)
    return render_live(base, doc, st, k=k, sprites=sprites, heads=heads, night=night)


if __name__ == "__main__":
    names = sys.argv[1:] or DZ.ORDER
    heads = radios.build()
    blank = Image.open(os.path.join(radios.OUT, "hu_blank.png"))
    for did in names:
        b, base, sprites, doc, dt = build_one(did)
        sprites["hu_blank"] = blank
        for stn in ("off", "keyon", "drive"):
            for k in (1, 2):
                preview(did, base, sprites, doc, heads=heads, state=stn, k=k).save(os.path.join(OUT, did, f"live_{stn}_{k}x.png"))
        print(f"{did:10s} {dt:5.1f}s parts={len(doc['parts']):3d} hits={len(doc['hits']):2d} sprites={len(sprites)}")
        for w in b.warnings: print("   !", w)
