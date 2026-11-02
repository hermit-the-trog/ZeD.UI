"""narrow faces: render beside the 336 face, and check: 200 wide, same click areas and live parts as the 336 face"""
import sys
from PIL import Image, ImageDraw, ImageFont
from physlib import build
import preview as PV
from plates import DESIGNS
import mock_sheet as MS
import m_narrow as MN

NARROW = {}
for k in ("oven_green", "oven_red", "oven_grey", "oven_modern", "oven_industrial", "fryer"):
    fn = {"oven_green": MN.green_range_n, "oven_red": MN.red_range_n, "oven_grey": MN.grey_range_n,
          "oven_modern": MN.modern_range_n, "oven_industrial": MN.industrial_range_n, "fryer": MN.fryer_n}[k]
    NARROW[k] = fn
NARROW["oven_large"] = MN.convection_oven_n
NARROW["mw_white"] = MN.mw_white_n
NARROW["mw_chrome"] = MN.mw_chrome_n
for k in ("gen_red", "gen_yellow", "gen_blue", "gen_old", "grill_propane", "ham_civilian", "ham_army", "ham_makeshift"):
    if hasattr(MN, k + "_n"): NARROW[k] = getattr(MN, k + "_n")


def check(pid):
    D = DESIGNS[pid]
    pw, *_ = build(MS.MOCK[pid], D["variants"], **D.get("base", {}))
    pn, *_ = build(NARROW[pid], D["variants"], **D.get("base", {}))
    msgs = []
    if pn.W != 200: msgs.append(f"width {pn.W}")
    h = lambda p: sorted((x["id"], x["kind"], x["needs"]) for x in p.hits)
    q = lambda p: sorted((x["t"], str(x.get("src"))) for x in p.parts)
    if h(pw) != h(pn): msgs.append(f"click areas differ: {set(h(pw)) ^ set(h(pn))}")
    if q(pw) != q(pn): msgs.append(f"live parts differ: {set(q(pw)) ^ set(q(pn))}")
    for x in pn.hits:
        if x["w"] < 10 or x["h"] < 10: msgs.append(f"small hit {x['id']}")
        if x["x"] < 0 or x["y"] < 0 or x["x"] + x["w"] > pn.W or x["y"] + x["h"] > pn.H: msgs.append(f"hit {x['id']} outside")
    msgs += ["warning: " + w for w in pn.warnings]
    return pn, msgs


def render(pid, k=2):
    D = DESIGNS[pid]
    p, base, spr = build(NARROW[pid], D["variants"], **D.get("base", {}))
    return PV.scale(PV.render_state(base, p.parts, spr, D["states"][-1]), k)


if __name__ == "__main__":
    ids = sys.argv[2:] or list(NARROW)
    F = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 15)
    ims = []
    for pid in ids:
        pn, msgs = check(pid)
        print(f"{pid:16s} {pn.W}x{pn.H} " + ("OK" if not msgs else ""))
        for m in msgs: print("    ", m)
        ims.append((pid, render(pid)))
    cols = min(4, len(ims)); cw = 420
    rows = [ims[i:i + cols] for i in range(0, len(ims), cols)]
    H = sum(max(i.height for _, i in r) + 30 for r in rows)
    s = Image.new("RGBA", (cols * cw + 10, H), (23, 23, 25, 255)); dr = ImageDraw.Draw(s); y = 0
    for r in rows:
        x = 10
        for pid, im in r:
            dr.text((x, y + 6), pid + " (narrow)", font=F, fill=(255, 214, 120)); s.alpha_composite(im, (x, y + 26)); x += cw
        y += max(i.height for _, i in r) + 30
    s.save(sys.argv[1])
