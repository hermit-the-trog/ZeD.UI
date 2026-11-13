"""Interior color varieties (the director, Nov 12 2026): the same dashboards, the cabin color only. Plates only, for
review; the export (export_lua.py) builds every color in full. The ramps live in engine.py, the table in
designs.CABINS.
usage: python colors.py outdir [design ...]"""
import os, sys, time
import build as BD
import designs as DZ
import brands
from dashlib import Build

COLORS = DZ.CABINS       # (the review sheets' name for the table)


def plate(did, cabin):
    title, _, seed, fn, sub, unit, radio = DZ.DESIGNS[did]
    b = Build(did, cabin, seed=seed, title=title)
    fn(b)
    if did in DZ.BRANDS:
        model, tag = BD.brand_line(did)
        brands.finish(b, DZ.BRANDS[did]["maker"], model, tag, curvy=DZ.BRANDS[did].get("curvy", False))
    return b.d.render()

if __name__ == "__main__":
    out = sys.argv[1]; os.makedirs(out, exist_ok=True)
    for did in (sys.argv[2:] or list(COLORS)):
        for name, cab in COLORS[did]:
            t = time.time(); plate(did, cab).save(os.path.join(out, f"{did}__{cab}.png")); print(did, cab, f"{time.time()-t:.1f}s", flush=True)
