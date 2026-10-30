"""Read-only audit: every needle on every dash, swept 0..max. Reports what each needle crosses.
Run from ZeDUI/tools/dashpx:  py -3.14 C:\\Temp\\needle_audit.py"""
import sys, os, math, json
sys.path.insert(0, os.getcwd())
import numpy as np
import dashlib
from dashlib import Build, PRINTED
from live import needle_pixels
import designs as DZ

STEPS = 60
out = {}
for did in DZ.ORDER:
    title, cabin, seed, fn, sub, unit, radio = DZ.DESIGNS[did]
    b = Build(did, cabin, seed=seed, title=title); fn(b)
    d = b.d
    names = d.names
    needles = [p for p in b.parts if p["t"] == "needle"]
    # pixels owned by other live parts
    other = {}
    for p in b.parts:
        if p["t"] == "needle": continue
        px = set()
        for key in ("runs", "halo"):
            for (x, y, w) in p.get(key, []) or []:
                for i in range(w): px.add((x + i, y))
        if all(k in p for k in ("x", "y", "w", "h")):
            for yy in range(p["y"], p["y"] + p["h"]):
                for xx in range(p["x"], p["x"] + p["w"]): px.add((xx, yy))
        if px: other.setdefault(f'{p["t"]}:{p.get("src", p.get("sprite", "?"))}', set()).update(px)
    sweeps = []
    for n in needles:
        allpx = set(); rec = {"src": n["src"], "cx": n["cx"], "cy": n["cy"], "r0": n["r0"], "r1": n["r1"], "a0": n["a0"], "a1": n["a1"],
                             "print_hits": {}, "mats": {}, "parts": {}}
        # the material the pivot's face is made of: sample along the needle at mid-length at mid-travel
        for i in range(STEPS + 1):
            f = i / STEPS
            a = n["a0"] + (n["a1"] - n["a0"]) * f
            body, edge = needle_pixels(n["cx"], n["cy"], a, n["r0"], n["r1"], n.get("w", 2), n.get("hub", 0) or 0)
            px = body | edge
            allpx |= px
            for (x, y) in px:
                if not (0 <= x < d.W and 0 <= y < d.H):
                    rec["mats"]["OFFPLATE"] = rec["mats"].get("OFFPLATE", 0) + 1; continue
                m = d.mat[y, x]; nm = names[m] if m >= 0 else "none"
                if nm in PRINTED:
                    rec["print_hits"].setdefault(nm, set()).add(round(f * n["max"], 2))
                else:
                    rec["mats"][nm] = rec["mats"].get(nm, 0) + 1
            for k, opx in other.items():
                if px & opx: rec["parts"].setdefault(k, set()).add(round(f * n["max"], 2))
        rec["allpx"] = allpx
        sweeps.append(rec)
    # needle sweeps crossing each other
    for i, r in enumerate(sweeps):
        for j, s in enumerate(sweeps):
            if j <= i: continue
            ov = r["allpx"] & s["allpx"]
            if ov: r["parts"].setdefault("needle:" + s["src"], set()).add(f"{len(ov)} px")
    out[did] = sweeps

for did, sw in out.items():
    print(f"=== {did}")
    for r in sw:
        pr = {k: (min(v), max(v), len(v)) for k, v in r["print_hits"].items()}
        pa = {k: sorted(v)[:3] + (["..."] if len(v) > 3 else []) for k, v in r["parts"].items()}
        print(f'  {r["src"]:<10} pivot {r["cx"]},{r["cy"]} r {r["r0"]}..{r["r1"]} a {r["a0"]}..{r["a1"]}')
        print(f'     surfaces {r["mats"]}')
        if pr: print(f'     over print (value min,max,count of {STEPS+1}) {pr}')
        if pa: print(f'     over parts {pa}')
