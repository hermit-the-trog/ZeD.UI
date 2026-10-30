"""checks every mockup face: 336 wide, same click areas and live parts as today's plate, click areas >= 10x10 and
inside the plate, live parts >= 1 px from the edge, no build warnings"""
import sys
from physlib import build
from plates import DESIGNS
import mock_sheet as MS

def bbox(pt):
    if "runs" in pt:
        xs=[]; ys=[]
        for x, y, w in pt["runs"]:
            ys.append(y); xs += [x, x + w - 1]
        return min(xs), min(ys), max(xs), max(ys)
    if "cx" in pt and "r1" in pt:
        r = max(abs(pt.get("r1",0)), abs(pt.get("r0",0)))
        return pt["cx"]-r, pt["cy"]-r, pt["cx"]+r, pt["cy"]+r
    if "x" in pt and "y" in pt:
        return pt["x"], pt["y"], pt["x"]+pt.get("w",0), pt["y"]+pt.get("h",0)
    return None

bad = 0
for pid, fn in MS.MOCK.items():
    D = DESIGNS[pid]
    po, *_ = build(D["fn"], D["variants"], **D.get("base", {}))
    pn, *_ = build(fn, D["variants"], **D.get("base", {}))
    msgs = []
    if pn.W != 336: msgs.append(f"width {pn.W}")
    ho = sorted((h["id"], h["kind"], h["needs"]) for h in po.hits); hn = sorted((h["id"], h["kind"], h["needs"]) for h in pn.hits)
    if ho != hn: msgs.append(f"click areas differ: {set(ho)^set(hn)}")
    po_parts = sorted((p["t"], str(p.get("src"))) for p in po.parts); pn_parts = sorted((p["t"], str(p.get("src"))) for p in pn.parts)
    if po_parts != pn_parts: msgs.append(f"live parts differ: {set(po_parts)^set(pn_parts)}")
    for h in pn.hits:
        if h["w"] < 10 or h["h"] < 10: msgs.append(f"small hit {h['id']} {h['w']}x{h['h']}")
        if h["x"] < 0 or h["y"] < 0 or h["x"]+h["w"] > pn.W or h["y"]+h["h"] > pn.H:
            msgs.append(f"hit {h['id']} outside plate ({h['x']},{h['y']},{h['w']},{h['h']})")
    def edgey(p):
        out = set()
        for pt in p.parts:
            b = bbox(pt)
            if b and (b[0] < 1 or b[1] < 1 or b[2] > p.W - 2 or b[3] > p.H - 2):
                out.add((pt["t"], str(pt.get("src"))))
        return out
    for t in sorted(edgey(pn) - edgey(po)):
        msgs.append(f"part {t} at the edge (not on today's plate)")
    msgs += ["warning: " + w for w in pn.warnings]
    print(f"{pid:16s} {pn.W}x{pn.H}  " + ("OK" if not msgs else ""))
    for m in msgs: print("    ", m)
