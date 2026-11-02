"""Two looks at the whole set for a review pass.

    py review_tools.py words <spreads dir> [ids]        every printed word, his notes and the sticky notes, as text
    py review_tools.py sheet <out dir> <sheet.png> [ids] the rendered spreads tiled at a third of their size"""
import json
import os
import sys

from PIL import Image, ImageDraw


def words(folder, only):
    for f in sorted(os.listdir(folder)):
        if not f.endswith(".json") or f.startswith("_"):
            continue
        sp = json.load(open(os.path.join(folder, f), encoding="utf-8"))
        if only and sp["id"] not in only:
            continue
        print("=" * 100)
        print("%02d %s  pages %s" % (sp["n"], sp["id"], sp.get("pages")))
        for side in ("left", "right"):
            pg = sp.get(side, {})
            print("-- %s (%s)  head: %s" % (side, pg.get("kind"), pg.get("head")))
            for b in pg.get("blocks", []):
                k = next(iter(b))
                v = b[k]
                if k == "table":
                    print("   TABLE %s %s | %s" % (v["label"], v["title"], " / ".join(v["head"])))
                    for r in v["rows"]:
                        print("      " + " | ".join(r))
                elif k == "list":
                    for i, it in enumerate(v):
                        print("   %s %s" % ("%d." % (i + 1) if b.get("numbered") else "*", it))
                elif k in ("gap", "at"):
                    continue
                else:
                    print("   %s: %s" % (k.upper(), v if isinstance(v, str) else " ".join(map(str, v))))
            for p in pg.get("prints", []):
                print("   [print %s box %s x%.2f at %s%s]" % (p["src"], p["box"], p["scale"], p["at"], " printed" if p.get("printed") else ""))
            for m in pg.get("marks", []):
                if "text" in m:
                    print("   {%s} %s%s" % (m.get("pen", "blu"), m["text"], "  -> arrow" if m.get("to") else ""))
                elif "circle" in m:
                    print("   {%s circle} %s" % (m.get("pen", "grn"), m["circle"]))
                elif "underline" in m:
                    print("   {%s underline} %s" % (m.get("pen", "blu"), m["underline"]))
            for s in pg.get("stickies", []) + ([pg["sticky"]] if pg.get("sticky") else []):
                print("   STICKY: %s" % s["text"])


def sheet(folder, out, only):
    files = [f for f in sorted(os.listdir(folder)) if f.endswith(".png")]
    if only:
        files = [f for f in files if any(f[3:-4] == i for i in only)]
    cols = 2
    tw, th = 640, 360
    rows = (len(files) + cols - 1) // cols
    im = Image.new("RGB", (cols * tw + (cols + 1) * 8, rows * (th + 22) + 8), (40, 40, 40))
    d = ImageDraw.Draw(im)
    for k, f in enumerate(files):
        t = Image.open(os.path.join(folder, f)).convert("RGB").resize((tw, th), Image.LANCZOS)
        x, y = 8 + (k % cols) * (tw + 8), 8 + (k // cols) * (th + 22)
        im.paste(t, (x, y + 16))
        d.text((x, y + 2), f, fill=(255, 255, 255))
    im.save(out)
    print("wrote", out, len(files), "spreads")


if __name__ == "__main__":
    if sys.argv[1] == "words":
        words(sys.argv[2], set(sys.argv[3].split(",")) if len(sys.argv) > 3 else set())
    else:
        sheet(sys.argv[2], sys.argv[3], set(sys.argv[4].split(",")) if len(sys.argv) > 4 else set())
