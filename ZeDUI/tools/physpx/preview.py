"""Previews: what the game will draw on a plate for a given state. Mirrors the Lua (ZeD.Px, as the dashboards
use it) step for step: every live part is rects on the art grid, k screen px per art px, nothing smoothed."""
import math
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "dashpx"))
from live import Canvas, needle_pixels, pixels_to_runs, shade, draw_text, seg_rects, SEGS   # noqa: E402

SEG_ORDER = "abcdefg"


def digits(cv, txt, x, y, cw, ch, pitch, t, color, ghost=None, align="r", n=None):
    """ZeD.Px.digits: n cells (right-aligned unless align == 'l'); '.' rides on the figure before it, ':' takes
    a narrow cell of its own (t + 2 wide); `ghost` draws the unlit segments of the figure cells and the pad cells"""
    cells = []
    for s in str(txt):
        if s == "." and cells: cells[-1]["dot"] = True
        elif s == ":": cells.append({"s": ":", "colon": True})
        else: cells.append({"s": s})
    n = n or len(cells)
    cells = cells[-n:]
    pad = n - len(cells)
    xx = x
    if align != "l":
        for _ in range(pad):
            if ghost:
                for sg in SEG_ORDER:
                    a, b, w, h = seg_rects(xx, y, cw, ch, t)[sg]; cv.rect(a, b, w, h, ghost)
            xx += pitch
    for c in cells:
        if c.get("colon"):
            cv.rect(xx, y + int(ch * 0.3), t, t, color); cv.rect(xx, y + int(ch * 0.7) - t + 1, t, t, color)
            xx += t + 2
            continue
        lit = SEGS.get(c["s"], "")
        rs = seg_rects(xx, y, cw, ch, t)
        for sg in SEG_ORDER:
            a, b, w, h = rs[sg]
            if sg in lit: cv.rect(a, b, w, h, color)
            elif ghost: cv.rect(a, b, w, h, ghost)
        if c.get("dot"): cv.rect(xx + cw + max(0, (pitch - cw - t) // 2), y + ch - t, t, t, color)
        xx += pitch


def _text57(cv, t, x, y, color, font="57", align="l"):
    return draw_text(cv, t, x, y, color, font, 1, align)


def marquee(s, n, now_ms=0):
    """ZeD.Plate.marquee: a line too long for its room marches left a character every 320 ms"""
    s = str(s or "")
    if len(s) <= n: return s
    loop = s + "   "
    k = (now_ms // 320) % len(loop)
    return (loop + loop)[k:k + n]


def text_w(t, font="57"):
    from engine import FONTS
    f = FONTS[font]
    return sum(len(f.get(c, f.get(c.upper(), f[" "]))[0]) + 1 for c in t) - 1


class ZoneCanvas:
    """a watch's bulb on a negative display: the figure colour's rects take each step's colour left of its edge (x from
    the display's left edge), split where a rect crosses an edge; other colours (the ghost) pass untouched"""
    def __init__(s, cv, x0, zones, col):
        s.cv, s.x0, s.zones, s.col = cv, x0, zones, col

    def rect(s, x, y, w, h, color, alpha=1.0):
        if color != s.col or w <= 0: return s.cv.rect(x, y, w, h, color, alpha)
        cx, right = x, x + w
        for z in s.zones:
            edge = s.x0 + z["x"]
            if cx >= right: return
            if cx < edge:
                e = min(edge, right)
                s.cv.rect(cx, y, e - cx, h, z["c"], alpha)
                cx = e
        if cx < right: s.cv.rect(cx, y, right - cx, h, color, alpha)

    def runs(s, runs, color, alpha=1.0, dx=0, dy=0):
        for x, y, w in runs: s.rect(x + dx, y + dy, w, 1, color, alpha)


def radio_display(cv, p, rd, now_ms=0, zones=None):
    """ZeD.Plate's radioDisplay: the radio's readout in pixel figures, field by field (seven-segment numbers, the
    5 x 7 letters, character cells, signal bars, the CD's triangle)"""
    ox, oy = p["x"], p["y"]
    col, ghost = p["color"], p.get("ghost")
    if zones: cv = ZoneCanvas(cv, ox, zones, col)
    for f in p["fields"]:
        if f.get("when") and not rd.get(f["when"]): continue
        t = f["t"]
        if t == "seg":
            v = rd.get(f["src"])
            v = "" if v is None else str(v)
            if not v: continue
            right = f.get("align", "r") == "r"
            digits(cv, v, ox + f["x"] - (f["n"] * f["pitch"] if right else 0), oy + f["y"], f["cw"], f["ch"], f["pitch"],
                   f.get("st", 1), col, ghost if f.get("ghost") else None, "r" if right else "l", f["n"])
        elif t == "text":
            v = rd.get(f["src"])
            v = "" if v is None else str(v)
            if not v: continue
            if f.get("w"):
                n = max(1, (f["w"] + 1) // 6)
                v = marquee(v, n, now_ms) if f.get("marquee") else v[:n]
            _text57(cv, v, ox + f["x"], oy + f["y"], col, f.get("font", "57"), f.get("align", "l"))
        elif t == "cells":
            v = rd.get(f["src"])
            v = "" if v is None else str(v)
            if f.get("marquee"): v = marquee(v, f["cols"], now_ms)
            for i in range(f["cols"]):
                cx = ox + f["x"] + i * f["pitch"]
                if ghost: cv.rect(cx, oy + f["y"], 5, 7, ghost)
                if i < len(v) and v[i] != " ":
                    _text57(cv, v[i], cx + (5 - text_w(v[i])) // 2, oy + f["y"], col)
        elif t == "bars":
            lit = int(rd.get(f["src"], 0) or 0)
            for i in range(f["n"]):
                bh = f["h0"] + i * f["dh"]
                c = col if i < lit else ghost
                if c: cv.rect(ox + f["x"] + i * (f["bw"] + f["gap"]), oy + f["y"] - bh, f["bw"], bh, c)
        elif t == "tri":
            sz = f["size"]
            mid = int(math.floor(sz * 0.6))
            for i in range(sz):
                hh = int(math.floor((sz - i) * 0.6))
                cv.rect(ox + f["x"] + i, oy + f["y"] + mid - hh, 1, max(1, hh * 2), col)


def render_state(base, parts, sprites, st, k=1, now_ms=0):
    cv = Canvas(base, k)
    for p in parts:
        t = p["t"]
        # a watch in the dark: a part's "night" colours while the state is dark, its "lit" colours under the light
        if st.get("lit") and "lit" in p: p = {**p, **p["lit"]}
        elif st.get("dark") and "night" in p: p = {**p, **p["night"]}
        if t == "sprite":
            if st.get(p["src"]) == p.get("when", True) and p["sprite"] in sprites:
                cv.sprite(sprites[p["sprite"]], p["x"], p["y"])
        elif t == "ptr":
            if "angles" in p:
                i = int(st.get(p["src"], 0)); a = p["angles"][max(0, min(len(p["angles"]) - 1, i))]
            else:
                v = max(0.0, min(1.0, float(st.get(p["src"], 0)))); a = p["a0"] + (p["a1"] - p["a0"]) * v
            body, edge = needle_pixels(p["cx"], p["cy"], a, p["r0"], p["r1"], p.get("w", 1))
            cv.runs(pixels_to_runs(body | edge), p["color"])
        elif t == "needle":
            v = max(0.0, min(1.0, float(st.get(p["src"], 0)))); a = p["a0"] + (p["a1"] - p["a0"]) * v
            body, edge = needle_pixels(p["cx"], p["cy"], a, p["r0"], p["r1"], p.get("w", 2), hub=p.get("hub", 0))
            allp = body | edge
            cv.runs(pixels_to_runs([(x + 1, y + 2) for (x, y) in allp]), (0, 0, 0), 0.45)
            cv.runs(pixels_to_runs(edge), shade(p["color"], 0.55))
            cv.runs(pixels_to_runs(body), p["color"])
        elif t == "clock":
            hr, mn = st.get("hour", 10), st.get("minute", 8)
            am = mn * 6 - 90; ah = (hr % 12) * 30 + mn * 0.5 - 90
            for a, rr, w in ((ah, p["rh"], 2), (am, p["rm"], 1)):
                body, edge = needle_pixels(p["cx"], p["cy"], a, 0, rr, w, hub=1.5)
                cv.runs(pixels_to_runs(body | edge), p["color"])
        elif t == "lamp":
            if st.get(p["src"]):
                if p.get("halo"): cv.runs(p["halo"], p["color"], 0.30)
                cv.runs(p["runs"], p["color"])
        elif t == "digits":
            if not st.get("power") and not p.get("always"): continue
            v = st.get(p["src"], 0)
            txt = v if isinstance(v, str) else str(int(math.floor((v or 0) + 0.5)))
            digits(cv, txt, p["x"], p["y"], p["cw"], p["ch"], p["pitch"], p.get("st", 1), p["color"], p.get("ghost"),
                   p.get("align", "r"), p.get("n"))
        elif t == "bars":
            v = max(0.0, min(1.0, float(st.get(p["src"], 0)) / float(p.get("max", 1)))) if st.get("power") else 0.0
            n = int(math.floor(v * len(p["bars"]) + 0.5))
            for runs in p["bars"][:n]: cv.runs(runs, p["color"])
        elif t == "radioDisplay":
            rd = st.get("display") or None
            zones = (p.get("bulbNight") if st.get("dark") else p.get("bulbDay")) if st.get("bulb") else None
            if rd: radio_display(cv, p, rd, now_ms, zones)
            elif p.get("style") in ("char", "lcd"): cv.rect(p["x"], p["y"], p["w"], p["h"], (0, 0, 0), 0.45)   # the backlight out
        elif t == "rangeText":
            if st.get("range"): _text57(cv, st["range"], p["x"], p["y"], p["color"], "35", "c")
        elif t == "slotDisc":
            if st.get("hasMedia"): cv.rect(p["x"], p["y"], p["w"], 1, p["color"])
        elif t == "tape":
            for i, nm in enumerate(st.get("tapeNames") or []):
                if nm: _text57(cv, nm, p["first"] + 1 + i * p["pitch"], p["y"] + 5, "#1d2d7a", "35")
    return cv.image()


def scale(img, k): return img.resize((img.width * k, img.height * k), Image.NEAREST)
