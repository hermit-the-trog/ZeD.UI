"""The Workshop gallery, set as spreads from the used copy of "Bitchin' znix Programs".

Every slide comes from the gallery's own shot list (ZeDUI/workshop/shots/shots.json): the same screenshots, crops
and callouts that make_shots.py lays out. This script lets make_shots.py do the layout (where each crop sits, where
each callout goes so it covers nothing), then sets the result as a page spread instead of a ZeD window:

  * the book open on the desk, in pixel art at 4x (page_px.py)
  * one plain heading, the slide's title, and the caption printed as the opening line
  * the crops printed as figures, crisp
  * each callout written in ballpoint where make_shots put it, with an arrow to its point; a callout that lands on
    a picture, or any callout on a full-scene photo, is written on a sticky note stuck there
  * the gutter's shadow over everything, then the folded corner and the glass ring

Run (from the repo root, or anywhere with --root):
    python book_shots.py ZeDUI/workshop/shots/shots.json [--only id1,id2] [--out DIR]
      --zomboid DIR   where the shot list's C:/Users/danie/Zomboid paths really are (default: as written)
      --fonts DIR     ChicagoFLF.ttf, FiraSans-Regular/SemiBold.ttf, FiraMono-Bold.ttf (make_shots.py's fonts)
"""
import argparse
import copy
import json
import math
import os
import shutil
import sys
import tempfile

from PIL import Image, ImageChops, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import page_px as pp   # noqa: E402

ZOMBOID_AS_WRITTEN = "C:/Users/danie/Zomboid"
OW, OH, S = pp.OW, pp.OH, pp.S


def load_make_shots(release_dir, fonts):
    """Import make_shots.py with its fonts found in `fonts` (it looks in WINDIR/Fonts)."""
    tmp = tempfile.mkdtemp(prefix="zedfonts_")
    os.makedirs(os.path.join(tmp, "Fonts"))
    for f in os.listdir(fonts):
        if f.lower().endswith((".ttf", ".otf")):
            shutil.copy(os.path.join(fonts, f), os.path.join(tmp, "Fonts", f))
    os.environ["WINDIR"] = tmp
    sys.path.insert(0, release_dir)
    import make_shots as ms
    return ms


def apply_notes(shot, notes):
    """book_notes.json: swap a callout's words for the kernel guy's, and pick his ink."""
    for n in notes.get(shot["id"], []):
        if "title" in n:                                   # a heading kept to the bare name
            shot["title"] = n["title"]
            continue
        for b in shot.get("balloons", []):
            if b.get("text") == n["match"]:
                b["text"] = n["text"]; b["pen"] = n.get("pen", "blu")
                for k in ("at", "maxw", "side"):          # where it goes, when the longer words need a new spot
                    if k in n: b[k] = n[k]
    return shot


def fix_paths(shot, zomboid):
    s = copy.deepcopy(shot)
    def fx(p):
        return p.replace(ZOMBOID_AS_WRITTEN, zomboid) if (p and zomboid and p.startswith(ZOMBOID_AS_WRITTEN)) else p
    s["src"] = fx(s["src"])
    for c in s.get("crops", []):
        if c.get("src"): c["src"] = fx(c["src"])
    return s


def layout(ms, shot, screens, patches=()):
    """Run make_shots' render with its drawing replaced by recording: returns (figure layer, balloons, places)."""
    rec = {"balloons": [], "frames": []}
    paper = pp.C["pg0"]
    saved = (ms.backdrop, ms.title_band, ms.caption_band, ms.framed, ms.draw_balloon, ms.draw_pin)
    ms.backdrop = lambda: Image.new("RGB", (ms.W, ms.H), paper)
    ms.title_band = lambda *a, **k: None
    ms.caption_band = lambda *a, **k: None
    def framed(im, tile, x, y):
        im.paste(tile, (x, y)); rec["frames"].append((x, y, tile.size[0], tile.size[1]))
    ms.framed = framed
    ms.draw_balloon = lambda canvas, b: rec["balloons"].append(dict(b))
    ms.draw_pin = lambda *a, **k: None
    try:
        out = ms.render(shot, screens, shot.get("n", 0), False, False, patches)   # patches hide the debug corner
    finally:
        (ms.backdrop, ms.title_band, ms.caption_band, ms.framed, ms.draw_balloon, ms.draw_pin) = saved
    return out, rec


def note_lines(b, maxw):
    lines = []
    if b.get("head"):
        lines.append(("head", b["head"]))
    for ln in pp.wrap(b.get("text", ""), pp.BALL, 15, maxw):
        lines.append(("body", ln))
    return lines


def render(ms, shot, screens, out_path, patches=(), jpg_dir=None):
    kind = shot.get("kind", "feature")
    lay, rec = layout(ms, shot, screens, patches)
    if lay is None:
        return False
    seed = shot.get("n", 1) * 97
    side = "right" if shot.get("n", 1) % 2 else "left"      # a right-hand page, then a left-hand page
    art, geom = pp.art_layer_close(seed, side)
    PX0, PX1, PY0, PY1, G = geom
    canvas = art.resize((OW, OH), Image.NEAREST).convert("RGB")
    d = ImageDraw.Draw(canvas)
    prn, ink, pen = pp.C["ink"], pp.C["blu"], pp.C["red"]      # blue writes, red points

    if kind == "ingame":
        s = 0.84
        ox, oy = (PX0 + PX1) * S / 2 - ms.W * s / 2, PY0 * S + 30
        photo = lay.resize((round(ms.W * s), round(ms.H * s)), Image.LANCZOS)
        canvas.paste(photo, (round(ox), round(oy)))
        d.rectangle((round(ox) - 2, round(oy) - 2, round(ox) + photo.width + 1, round(oy) + photo.height + 1), outline=prn, width=2)
        if shot.get("caption"):
            m = pp.mask2(shot["caption"], pp.SERIF, 12)
            pp.put(canvas, m, (OW - m.width) / 2, oy + photo.height + 16, prn)
        fig_mask = Image.new("L", (OW, OH), 0)
        ImageDraw.Draw(fig_mask).rectangle((ox, oy, ox + photo.width, oy + photo.height), fill=255)
    else:
        s = 0.88
        ox, oy = round((PX0 + PX1) * S / 2 - ms.W * s / 2), 92
        # the heading and the caption, top of the page
        L0, L1 = PX0 * S + 70, PX0 * S + 70 + 900
        top = PY0 * S + 30
        hm = pp.mask2(shot.get("title", ""), pp.SERIF_B, 24)
        pp.put(canvas, hm, L0, top, prn)
        y = top + hm.height + 14
        for ln in pp.wrap(shot.get("caption", ""), pp.SERIF, 12, L1 - L0) if shot.get("caption") else []:
            m = pp.mask2(ln, pp.SERIF, 12); pp.put(canvas, m, L0, y, prn); y += 30
        # the figures: everything make_shots drew that isn't the page
        diff = ImageChops.difference(lay, Image.new("RGB", lay.size, pp.C["pg0"])).convert("L").point(lambda v: 255 if v > 6 else 0)
        diff = diff.filter(ImageFilter.MaxFilter(3))
        lw, lh = round(ms.W * s), round(ms.H * s)
        layer = lay.resize((lw, lh), Image.LANCZOS); mask = diff.resize((lw, lh), Image.LANCZOS)
        canvas.paste(layer, (ox, oy), mask)
        for (x, y_, w, h) in rec["frames"]:
            x0, y0 = ox + x * s, oy + y_ * s
            d.rectangle((round(x0) - 2, round(y0) - 2, round(x0 + w * s) + 1, round(y0 + h * s) + 1), outline=prn, width=2)
        fig_mask = Image.new("L", (OW, OH), 0); fig_mask.paste(mask, (ox, oy))

    # the gutter's shadow, over the print too
    gx = PX0 * S if side == "right" else PX1 * S
    px = canvas.load()
    for x in (range(gx, gx + 70) if side == "right" else range(gx - 70, gx)):
        k = 1 - 0.25 * (1 - abs(x - gx) / 70) ** 2
        for y in range(PY0 * S, PY1 * S):
            o = px[x, y]; px[x, y] = (int(o[0] * k), int(o[1] * k), int(o[2] * k))

    # the notes
    fm = fig_mask.load()
    boxes = []                                                                # (box, what) for the checks below
    for b in rec["balloons"]:
        r = b["rect"]
        x0, y0, x1, y1 = ox + r[0] * s, oy + r[1] * s, ox + r[2] * s, oy + r[3] * s
        ax, ay = ox + b["anchor"][0] * s, oy + b["anchor"][1] * s
        if kind != "ingame":                                                  # keep the writing off the pictures
            row = [fm[int(min(OW - 1, max(0, xx))), int(min(OH - 1, max(0, yy)))] for yy in (y0 + 10, (y0 + y1) / 2, y1 - 10) for xx in range(int(x0), int(x1), 4)]
            cols = list(range(int(x0), int(x1), 4)); n = len(cols)
            hit = [any(row[k + n * j] for j in range(3)) for k in range(n)]
            if any(hit) and not all(hit):
                first = hit.index(True); last = n - 1 - hit[::-1].index(True)
                if first > n - 1 - last: x1 = cols[first] - 18          # the picture is on the note's right
                else: x0 = cols[last] + 18                               # on its left
        on_pic = kind == "ingame" or (x1 - x0) < 200 or any(fm[int(min(OW - 1, max(0, xx))), int(min(OH - 1, max(0, yy)))] for xx in (x0 + 6, (x0 + x1) / 2, x1 - 6) for yy in (y0 + 6, (y0 + y1) / 2, y1 - 6))
        maxw = x1 - x0 - (28 if on_pic else 0)
        lines = note_lines(b, maxw)
        lh = 34
        hgt = len(lines) * lh + (8 if b.get("head") else 0)
        cx, cy = x0 + (14 if on_pic else 0), y0 + (12 if on_pic else 0)
        if on_pic:                                                            # a sticky note, stuck on
            nw, nh = maxw + 28, hgt + 24
            sh = (int(cx - 14 + 6), int(cy - 12 + 8))
            d.rectangle((sh[0], sh[1], sh[0] + nw, sh[1] + nh), fill=(0, 0, 0))
            d.rectangle((cx - 14, cy - 12, cx - 14 + nw, cy - 12 + nh), fill=(222, 202, 104))
            d.rectangle((cx - 14, cy - 12, cx - 14 + nw, cy - 12 + 10), fill=(204, 184, 88))
        yy = cy; wmax = 0
        for k, (role, ln) in enumerate(lines):
            m = pp.mask2(ln, pp.BALL, 16 if role == "head" else 15)
            wmax = max(wmax, m.width)
            pp.put(canvas, m, cx, yy + (k % 2), pp.C[b.get("pen", "blu")])
            if role == "head":
                pp.ink_line(d, [(cx, yy + m.height + 4), (cx + m.width, yy + m.height + 2)], pp.C[b.get("pen", "blu")])
                yy += 8
            yy += lh
        # the arrow: from the edge of what was written (or of the sticky note) nearest its point, stopping short
        if on_pic:
            x0, y0, x1, y1 = cx - 14, cy - 12, cx - 14 + nw, cy - 12 + nh
        else:
            x0, y0, x1, y1 = cx - 4, cy - 4, cx + wmax + 4, yy - 4
            over = sum(1 for xx in range(int(x0), int(x1), 6) for yy_ in range(int(y0), int(y1), 6)
                       if 0 <= xx < OW and 0 <= yy_ < OH and fm[xx, yy_])
            if over > 6:
                print("  CHECK %s: note '%s' is written over a picture" % (shot["id"], b.get("text", "")[:30]))
        boxes.append(((x0, y0, x1, y1), b.get("text", "")[:30], (ax, ay)))
        bx = min(max(ax, x0), x1); by = min(max(ay, y0), y1)
        if x0 < ax < x1 and y0 < ay < y1:
            continue
        if bx in (x0, x1): bx += -12 if bx == x0 else 12
        if by in (y0, y1): by += -10 if by == y0 else 10
        dist = math.hypot(ax - bx, ay - by)
        if dist < 24:
            continue
        ex, ey = ax - (ax - bx) / dist * 14, ay - (ay - by) / dist * 14
        pp.arrow(d, (bx, by), (ex, ey), pen if on_pic or fm[int(min(OW - 1, ex)), int(min(OH - 1, ey))] else ink, bend=0.15)

    # checks: notes on notes, and notes covering another note's point
    for i, (ra, ta, pa) in enumerate(boxes):
        for j, (rb, tb, pb) in enumerate(boxes):
            if j > i and ra[0] < rb[2] and rb[0] < ra[2] and ra[1] < rb[3] and rb[1] < ra[3]:
                print("  CHECK %s: notes overlap: '%s' / '%s'" % (shot["id"], ta, tb))
            if j != i and ra[0] < pb[0] < ra[2] and ra[1] < pb[1] < ra[3]:
                print("  CHECK %s: note '%s' covers the point of '%s'" % (shot["id"], ta, tb))

    # the wear on top: the folded corner
    before = art.copy(); top_art = art.copy(); pp.overlay_art(top_art, geom, seed)
    chg = ImageChops.difference(before, top_art).convert("L").point(lambda v: 255 if v else 0).resize((OW, OH), Image.NEAREST)
    big = top_art.resize((OW, OH), Image.NEAREST)
    ear = Image.new("L", (OW, OH), 0)
    if side == "right": ImageDraw.Draw(ear).rectangle(((PX1 - 14) * S, (PY1 - 14) * S, OW, OH), fill=255)
    else: ImageDraw.Draw(ear).rectangle((0, (PY1 - 14) * S, (PX0 + 14) * S, OH), fill=255)
    canvas.paste(big, (0, 0), ImageChops.multiply(chg, ear))
    ring = ImageChops.subtract(chg, ear)
    tint = Image.blend(canvas, Image.new("RGB", (OW, OH), pp.C["ring"]), 0.2)
    canvas.paste(tint, (0, 0), ring)
    canvas.save(out_path)
    if jpg_dir:
        ms.save_jpg(canvas, os.path.join(jpg_dir, os.path.basename(out_path)[:-4] + ".jpg"))
    return True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("shots")
    ap.add_argument("--only", default="")
    ap.add_argument("--out", default=os.path.join(HERE, "out"))
    ap.add_argument("--zomboid", default="")
    ap.add_argument("--screens", default="")
    ap.add_argument("--fonts", default="")
    ap.add_argument("--release", default="")
    ap.add_argument("--jpg", default="", help="also write the upload copies here: JPEG under Steam's 1 MB")
    a = ap.parse_args()
    spec = json.load(open(a.shots, encoding="utf-8"))
    repo = os.path.abspath(os.path.join(os.path.dirname(a.shots), "..", "..", ".."))
    release = a.release or os.path.join(repo, "ZeDUI", "tools", "release")
    fonts = a.fonts or os.path.join(repo, "zed_backups", "fonts_for_desc")
    ms = load_make_shots(release, fonts)
    screens = a.screens or spec["screens"]
    if a.zomboid: screens = screens.replace(ZOMBOID_AS_WRITTEN, a.zomboid)
    os.makedirs(a.out, exist_ok=True)
    if a.jpg:
        os.makedirs(a.jpg, exist_ok=True)
        cover = os.path.join(HERE, "znix_01_cover.png")
        if os.path.exists(cover):                                             # the cover goes first
            ms.save_jpg(Image.open(cover).convert("RGB"), os.path.join(a.jpg, "00_cover.jpg"))
    only = set(x for x in a.only.split(",") if x)
    np_ = os.path.join(HERE, "book_notes.json")
    notes = json.load(open(np_, encoding="utf-8")) if os.path.exists(np_) else {}
    for shot in spec["shots"]:
        if only and shot["id"] not in only:
            continue
        sh = apply_notes(fix_paths(shot, a.zomboid), notes)
        name = "%02d_%s.png" % (shot["n"], shot["id"])
        ok = render(ms, sh, screens, os.path.join(a.out, name),
                    shot.get("patches", spec.get("patches", ())), a.jpg or None)
        print(("wrote " if ok else "skipped ") + name)


if __name__ == "__main__":
    main()
