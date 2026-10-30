"""The proof for rtv_plates: every radio, TV and laundry face at every width it ships at (and its narrow face) builds
with no placement warnings and has the same click areas and the same live parts (type and state) as its base face,
so one piece of wiring in Code drives every width. Run: python rtv_check.py"""
import sys
import rtv_plates as RP
import w_plates as WP
from physlib import build
from plates import DESIGNS


def sig(p):
    return (sorted(h["id"] for h in p.hits), sorted((q["t"], str(q.get("src")), str(q.get("kind"))) for q in p.parts))


def main():
    bad = 0
    for pid, fn, card, variants, base, *_ in RP.SPECS:
        D = DESIGNS[pid]
        p0, _, _ = build(D["fn"], D["variants"], **D.get("base", {}))
        s0 = sig(p0)
        keys = [(W, WP.WIDE[pid]) for W in WP.widths(pid)[1]]
        if pid in RP.NARROW: keys.append(("narrow", DESIGNS[RP.NARROW[pid]]["fn"]))
        for W, f in keys:
            p, _, _ = (build(f, variants, W=W, **base) if W != "narrow" else build(f, variants, **base))
            s = sig(p)
            ok = not p.warnings and s == s0
            if not ok:
                bad += 1
                print(f"{pid}@{W}: warnings {p.warnings}; hits/parts differ: {s != s0}")
                if s != s0:
                    print("   base hits", s0[0], "\n   this hits", s[0])
                    print("   parts only in base", sorted(set(s0[1]) - set(s[1])), "only here", sorted(set(s[1]) - set(s0[1])))
        print(f"{pid:16s} {len(keys) + 1} faces, {len(s0[0])} click areas, {len(s0[1])} live parts")
    print("all faces agree" if not bad else f"{bad} faces differ")
    return bad


if __name__ == "__main__":
    sys.exit(1 if main() else 0)
