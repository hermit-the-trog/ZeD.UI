"""The contents spread, after the title (the 1.0 book, Nov 17 2026; Design's handoff, HANDOFF_design_gallery_v1).

The publisher's printed contents: the Introduction, then each part with its chapters, a dotted leader to the page the
chapter starts on. The parts come from the order list (v1_plan/order_v2.json: "parts", each a title and its spread ids
in reading order); every chapter's number, title and first page are read from the spreads themselves, so the
contents cannot drift from the book. The first chapter of the first part, when it is the Introduction ("hero"), is
set on its own ahead of the parts, as the book places it.
usage: python contents_spread.py <order.json> <spreads folder> [out.png]"""
import json
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import page_px as pp   # noqa: E402
import spread as S     # noqa: E402

INTRO = "hero"
SIZE = 10                 # the chapter lines, as the copyright page sets its small print
TOP_Y = {"left": 250, "right": 150}
FOOT_Y = 1010


def chapters(folder):
    out = {}
    for f in os.listdir(folder):
        if f.endswith(".json") and f[0].isdigit():
            sp = json.load(open(os.path.join(folder, f), encoding="utf-8"))
            title = [b["chapter"][1] for b in sp["left"]["blocks"] if "chapter" in b][0]
            out[sp["id"]] = (sp["n"], title, sp["pages"][0])
    return out


def lines(order, chs):
    """The contents as lines: ("part", title) or ("ch", number, title, page)."""
    L = []
    parts = order["parts"]
    first = parts[0]["chapters"]
    if first and first[0] == INTRO:
        L.append(("ch",) + chs[INTRO])
    for k, p in enumerate(parts, 1):
        L.append(("part", "Part %d" % k, p["title"]))
        for cid in p["chapters"]:
            if cid != INTRO:
                L.append(("ch",) + chs[cid])
    return L


def leader(canvas, x0, x1, base):
    """Dots from the end of a title to the page number, spaced as a typesetter's leader."""
    step = S.F(S.SERIF, SIZE).getlength(". ") * 2
    x = x0 + 10
    while x < x1 - 12:
        S.put_tok(canvas, ".", S.SERIF, SIZE, x, base)
        x += step


def main(order_path, folder, out):
    order = json.load(open(order_path, encoding="utf-8"))
    L = lines(order, chapters(folder))
    # one lead for both pages, so the list fills them evenly: a part's head takes two lines' room
    room = (FOOT_Y - TOP_Y["left"]) + (FOOT_Y - TOP_Y["right"])
    units = sum(2.0 if ln[0] == "part" else 1.0 for ln in L)
    lead = max(20, min(30, int(room / units)))
    canvas = pp.art_layer(1)[0].resize((S.OW, S.OH), Image.NEAREST).convert("RGB")
    d = ImageDraw.Draw(canvas)
    for side in ("left", "right"):
        S.running_head(canvas, d, side, "", "Contents" if side == "right" else "Bitchin' znix Programs - Doidbros & Buzzlord")
    c0, c1 = S.column("left")
    S.put_tok(canvas, "Contents", S.SANS_B, 22, c0, S.TOP + 158)
    S.rule(d, c0, c1, S.TOP + 182, 4)
    side, y = "left", TOP_Y["left"]
    nw = S.F(S.SANS_B, SIZE).getlength("00") * 2 + 24          # the chapter number's column
    for ln in L:
        need = lead * (2 if ln[0] == "part" else 1)
        if y + need > FOOT_Y and side == "left":
            side, y = "right", TOP_Y["right"]
        c0, c1 = S.column(side)
        if ln[0] == "part":
            y += int(lead * 0.6)
            S.put_tok(canvas, ln[1], S.SANS_B, 11, c0, y)
            S.put_tok(canvas, ln[2], S.SANS_B, 11, c0 + S.F(S.SANS_B, 11).getlength(ln[1]) * 2 + 24, y)
            y += int(lead * 1.4)
        else:
            n, title, page = ln[1:]
            S.put_tok(canvas, str(n), S.SANS_B, SIZE, c0 + nw - 24 - S.F(S.SANS_B, SIZE).getlength(str(n)) * 2, y)
            S.put_tok(canvas, title, S.SERIF, SIZE, c0 + nw, y)
            pg = str(page)
            pw = S.F(S.SERIF, SIZE).getlength(pg) * 2
            S.put_tok(canvas, pg, S.SERIF, SIZE, c1 - pw, y)
            leader(canvas, c0 + nw + S.F(S.SERIF, SIZE).getlength(title) * 2, c1 - pw - 8, y)
            y += lead
    if y > FOOT_Y + lead:
        print("CHECK contents: the list runs past the foot of the right page (to y %d)" % y)
    S.gutter(canvas)
    canvas.save(out)
    print("wrote", out, "(%d lines, lead %d)" % (len(L), lead))


if __name__ == "__main__":
    a = sys.argv[1:]
    main(a[0], a[1], a[2] if len(a) > 2 else os.path.join(HERE, "out_spread", "00d_contents.png"))
