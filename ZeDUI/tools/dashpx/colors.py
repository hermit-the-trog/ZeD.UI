"""Interior colour varieties (the director, Nov 12 2026): the same dashboards, the cabin colour only.
usage: python colors.py outdir [design ...]"""
import os, sys, time
import build as BD
import designs as DZ
import brands
from dashlib import Build
from engine import add_ramp

for nm, base in {"v_army": "#4d5030", "v_moss": "#38472e", "v_maroon": "#532131", "v_grey": "#5d6064", "v_ltbrown": "#8a6a44",
                 "l_brown": "#7c4f2c", "l_red": "#7a2420", "l_black": "#242326",
                 "v_beige_d": "#7c6e56", "v_navy70": "#2a3442"}.items():   # the director, Nov 12: beige darker; the 70s navy darker
    add_ramp(nm, base)

S70 = [("moss green", "v_moss"), ("light brown", "v_ltbrown"), ("slate blue", "v_navy70")]
S80 = [("maroon", "v_maroon"), ("navy", "v_navy"), ("beige", "v_beige_d")]
S90 = [("beige", "v_beige_d"), ("gray", "v_grey"), ("black", "v_black")]
LUX = [("brown leather", "l_brown"), ("red leather", "l_red"), ("black leather", "l_black")]
BLK = [("black", "v_black")]
COLORS = {
    "wagon": [("brown", "v_walnut"), ("slate blue", "v_navy70"), ("army green", "v_army")],
    "cossette": LUX, "luxury": LUX,
    "dashelite": S90, "primani": S90, "suv": S90,
    "nyala": S70, "d6": S70, "bulldriver": S70, "rancher": S70,
    "horizon": S80, "dart": S80, "van": S80,
    "police": BLK, "taxi": BLK, "ambulance": BLK, "fire": BLK, "ranger": BLK,
}

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
