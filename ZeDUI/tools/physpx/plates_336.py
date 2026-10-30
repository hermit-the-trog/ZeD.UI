"""The 336 px machine plates and their 200 px narrow faces (PLATE_SIZES_SPEC.md, design session Oct 29 2026), laid
over the registry in plates.py without editing it: importing this replaces the 17 machine plates' designs with the
re-laid ones (m_ovens / m_more / m_ham, the game's own brands from m_brands) and registers a narrow face for each
(`<plate>_n`, m_narrow; the ham sets' existing narrow faces are replaced by the updated ones).

NARROW: every machine plate -> its narrow face, for the template to pick where the full card is narrower than the
main face at the plates' whole zoom (the smallest settings only: fixed UI scale 0.5, or Auto at 720/800 with the 16 px
font). Exported into PhysPx.lua as `narrow` by export_336.py; the ham sets keep their twoway.narrow entries too.

To fold in for good: move the functions into d_ovens / d_micro / d_gen / d_grill / d_walkie, point plates.py at them,
add the narrow registrations there, and the `narrow` table to export_phys.py; then this file and export_336.py go."""
from plates import DESIGNS, reg
import m_ovens as MO
import m_more as MM
import m_ham as MH
import m_narrow as MN

MAIN = {"oven_green": MO.green_range, "oven_red": MO.red_range, "oven_grey": MO.grey_range, "oven_modern": MO.modern_range,
        "oven_industrial": MO.industrial_range, "oven_large": MO.convection_oven, "fryer": MO.fryer,
        "mw_white": MM.mw_white, "mw_chrome": MM.mw_chrome,
        "gen_red": MM.gen_red, "gen_yellow": MM.gen_yellow, "gen_blue": MM.gen_blue, "gen_old": MM.gen_old,
        "grill_propane": MM.grill_propane,
        "ham_civilian": MH.ham_civ, "ham_army": MH.ham_army, "ham_makeshift": MH.ham_make}
NARROW_FN = {"oven_green": MN.green_range_n, "oven_red": MN.red_range_n, "oven_grey": MN.grey_range_n,
             "oven_modern": MN.modern_range_n, "oven_industrial": MN.industrial_range_n, "oven_large": MN.convection_oven_n,
             "fryer": MN.fryer_n, "mw_white": MN.mw_white_n, "mw_chrome": MN.mw_chrome_n,
             "gen_red": MN.gen_red_n, "gen_yellow": MN.gen_yellow_n, "gen_blue": MN.gen_blue_n, "gen_old": MN.gen_old_n,
             "grill_propane": MN.grill_propane_n,
             "ham_civilian": MN.ham_civilian_n, "ham_army": MN.ham_army_n, "ham_makeshift": MN.ham_makeshift_n}
TITLES = {"mw_chrome": "Chrome microwave, 1988", "grill_propane": "Propane grill (Hector Lopez), 1993",
          "gen_red": "Red generator (Lectromax), 1988", "gen_yellow": "Yellow contractor's generator (Premium Technologies)",
          "gen_blue": "Blue compact generator (ValuTech), 1991"}
NARROW = {pid: pid + "_n" for pid in MAIN}

for pid, fn in MAIN.items():
    D = DESIGNS[pid]
    D["fn"] = fn
    if pid in TITLES: D["title"] = TITLES[pid]
for pid, fn in NARROW_FN.items():
    D = DESIGNS[pid]
    nid = pid + "_n"
    old = DESIGNS.get(nid)
    reg(nid, fn, D["variants"], D["states"], (old or D)["title"] if old else D["title"] + " (narrow)",
        (old["uses"] if old else D["uses"] + " (narrow)"), base=D.get("base"), post=D.get("post"))
