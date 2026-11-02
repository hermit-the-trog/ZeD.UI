"""The layout desk: a window onto the spreads while they are being laid out (Nov 1 2026).

Every time spread.py draws a spread it calls stamp() here, which leaves in <out>/_watch/:
  <name>.js                  stamp({...}): title, pages, when it was drawn, its CHECK lines, and every earlier draft
  <name>.thumb.jpg           a small copy for the contact sheet
  drafts/<name>__<time>.jpg  this draft, so the page can replay how the spread was laid out

Open watch.html (in this folder) in a browser and leave it open: it looks for new stamps every two seconds.
_watch/ ignores itself in git. Stamping never stops a render: any trouble is printed and skipped.

  py watch.py out_spread      stamp the PNGs there that have no stamp yet (one draft each, dated by the file)
"""
import json
import os
import sys
import time

from PIL import Image

DRAFT_W, THUMB_W = 1280, 480


def _title(sp):
    for side in ("left", "right"):
        for b in (sp.get(side) or {}).get("blocks") or []:
            if isinstance(b, dict) and "chapter" in b:
                c = b["chapter"]
                return str(c[-1]) if isinstance(c, list) else str(c)
    return str((sp.get("right") or {}).get("head") or "")


def _replace(tmp, path):
    for _ in range(40):                      # the browser may be reading the old one this very moment
        try:
            os.replace(tmp, path)
            return
        except PermissionError:
            time.sleep(0.05)
    os.remove(tmp)


def _jpg(im, w, path, q):
    tmp = path + ".tmp.jpg"
    im.resize((w, w * im.height // im.width), Image.LANCZOS).save(tmp, quality=q)
    _replace(tmp, path)


def _old(path):
    try:
        with open(path, encoding="utf-8") as fh:
            s = fh.read().strip()
        return json.loads(s[len("stamp("):s.rindex(")")])
    except Exception:  # noqa: BLE001  (no stamp yet, or one being written)
        return {}


def stamp(png, sp=None, checks=(), t=None):
    """Leave the stamp for one spread just written to png (sp: its spread json; checks: the CHECK lines)."""
    try:
        out, fname = os.path.split(os.path.abspath(png))
        name = os.path.splitext(fname)[0]
        wd = os.path.join(out, "_watch")
        dd = os.path.join(wd, "drafts")
        os.makedirs(dd, exist_ok=True)
        gi = os.path.join(wd, ".gitignore")
        if not os.path.exists(gi):
            with open(gi, "w") as fh:
                fh.write("*\n")
        t = time.time() if t is None else t
        tag = time.strftime("%Y%m%d_%H%M%S", time.localtime(t)) + "_%03d" % int(t % 1 * 1000)
        draft = "%s__%s.jpg" % (name, tag)
        im = Image.open(png).convert("RGB")
        _jpg(im, DRAFT_W, os.path.join(dd, draft), 82)
        _jpg(im, THUMB_W, os.path.join(wd, name + ".thumb.jpg"), 84)
        sp = sp or {}
        js = os.path.join(wd, name + ".js")
        history = [h for h in _old(js).get("history", []) if h.get("f") and os.path.isfile(os.path.join(dd, h["f"]))]
        history.append({"t": round(t, 3), "f": draft, "checks": None if checks is None else [str(c) for c in checks]})
        n = sp.get("n")
        if n is None and name[:2].isdigit():
            n = int(name[:2])
        info = {"name": name, "id": sp.get("id", name[3:]), "n": n, "title": _title(sp), "pages": sp.get("pages"),
                "t": round(t, 3), "checks": history[-1]["checks"], "history": history}
        tmp = js + ".tmp"
        with open(tmp, "w", encoding="utf-8") as fh:
            fh.write("stamp(%s);\n" % json.dumps(info, ensure_ascii=False))
        _replace(tmp, js)
    except Exception as e:  # noqa: BLE001
        print("  (watch: %s)" % e)


def backfill(out, spreads=None):
    """Stamp every PNG in out that has none yet, using the spread jsons in spreads (default: ../spreads)."""
    spreads = spreads or os.path.join(os.path.dirname(os.path.abspath(out)), "spreads")
    for f in sorted(os.listdir(out)):
        name, ext = os.path.splitext(f)
        if ext.lower() != ".png" or os.path.exists(os.path.join(out, "_watch", name + ".js")):
            continue
        sp = {}
        j = os.path.join(spreads, name + ".json")
        if os.path.exists(j):
            with open(j, encoding="utf-8") as fh:
                sp = json.load(fh)
        png = os.path.join(out, f)
        stamp(png, sp, None, os.path.getmtime(png))
        print("stamped", f)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    backfill(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)
