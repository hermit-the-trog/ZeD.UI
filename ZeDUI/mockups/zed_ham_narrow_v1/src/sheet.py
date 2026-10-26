"""review sheets for the narrow ham sets: python sheet.py   (writes ../narrow_hams_2x.png and ../wide_vs_narrow.png)"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import d_ham_narrow as HN    # noqa: E402  (puts ZeDUI/tools/physpx on the path)
import physlib               # noqa: E402
import preview as PV         # noqa: E402
import d_walkie as DW        # noqa: E402

OUT = os.path.normpath(os.path.join(HERE, ".."))
WIDE_FN = {"ham_civilian": DW.ham_civ, "ham_army": DW.ham_army, "ham_makeshift": DW.ham_make}


def render(fn, kind, kw, on=True):
    p, base, spr = physlib.build(fn, [("mic_live", "micLive", True, {"mic_live": True})] if fn in (HN.ham_make_n, DW.ham_make) else [])
    for w in p.warnings: print("  !", p.id, w)
    return p, PV.render_state(base, p.parts, spr, DW.state(kind, on, **kw))


def faces(k=2):
    out = []
    for pid, (fn, kind, kw) in HN.MODELS.items():
        p, im = render(fn, kind, kw)
        print(pid, p.W, "x", p.H, len(p.hits), "hits:", " ".join(h["id"] for h in p.hits))
        wide = WIDE_FN[HN.WIDE[pid]]()
        missing = sorted({h["id"] for h in wide.hits} - {h["id"] for h in p.hits})
        if missing: print("  ! missing controls of the wide set:", missing)
        out.append((pid, p, im, PV.scale(im, k)))
    return out


def sheet(items, name, k=2):
    pad = 16
    W = sum(f.width + pad for *_, f in items) + pad
    H = max(f.height for *_, f in items) + 2 * pad + 14
    s = Image.new("RGBA", (W, H), (30, 30, 32, 255)); d = ImageDraw.Draw(s); x = pad
    for pid, p, im, f in items:
        s.alpha_composite(f, (x, pad)); d.text((x, H - pad - 8), pid, fill=(170, 170, 170)); x += f.width + pad
    s.save(os.path.join(OUT, name))
    return s


def wide_vs_narrow(items, k=1):
    """each set wide (as built) beside its narrow face, at 1x, the same scale"""
    rows = []
    for pid, p, im, f in items:
        fn, kind, kw = HN.MODELS[pid]
        wp, wim = render(WIDE_FN[HN.WIDE[pid]], kind, kw)
        rows.append((pid, wim, im))
    pad = 12
    W = max(w.width + n.width for _, w, n in rows) + 3 * pad
    H = sum(max(w.height, n.height) + pad for _, w, n in rows) + pad
    s = Image.new("RGBA", (W, H), (30, 30, 32, 255)); y = pad
    for pid, w, n in rows:
        s.alpha_composite(w, (pad, y)); s.alpha_composite(n, (2 * pad + w.width, y)); y += max(w.height, n.height) + pad
    s = PV.scale(s, 2)
    s.save(os.path.join(OUT, "wide_vs_narrow.png"))
    return s


if __name__ == "__main__":
    items = faces()
    sheet(items, "narrow_hams_2x.png")
    wide_vs_narrow(items)
    for pid, p, im, f in items: im.save(os.path.join(OUT, pid + "_1x.png"))
    print("ok")
