"""ZeDUI/tools/qa/padmap.py  (Oct 23 2026)

The pad map's second half (the first is zedqa_padmap.lua, in game). For every
capture Zomboid/Lua/zqa_pm_<name>.json + Screenshots/zqa_pm_<name>.png it
draws the window with each stop numbered and its moves, works out the move a
player would expect from what is on screen, and lists where the real move
(the focus manager's own dispatch, run dry in game) differs.

The expected move, by the director's rules (Oct 23 2026):
  * visual direction: the nearest stop that way, a stop lined up with this
    one (spans overlapping across the move) before one off to the side;
  * a clear destination: entering a tab column or a container column lands
    on the tab / container on show; entering the item list from the side
    lands on the row focus last had (any row of the list counts);
  * Left / Right with nothing more that way in the window go on to the
    other window when it sits that way;
  * no press that does nothing while something lies that way.
Stops with their own D-pad handler (a card's buttons, the map's cursor, grid
scroll areas) are listed as "own" and not compared (their handler runs
first; zedqa_world_pad_take.lua checks the card's).

Usage: py padmap.py [out_dir]   (default ZeDUI/qa/padmap)
Writes <name>.png overlays (the window, half size) and index.md.
"""
import json, os, sys, glob
from PIL import Image, ImageDraw, ImageFont

ZOMBOID = os.path.expanduser(r"~\Zomboid")
LUA = os.path.join(ZOMBOID, "Lua")
SHOTS = os.path.join(ZOMBOID, "Screenshots")
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.normpath(os.path.join(HERE, "..", "..", "qa", "padmap"))
SCALE = 0.5

def along_ok(f, t, d):
    fcx, fcy = f["x"] + f["w"] / 2, f["y"] + f["h"] / 2
    tcx, tcy = t["x"] + t["w"] / 2, t["y"] + t["h"] / 2
    if d == "left": return fcx - tcx > 0.5
    if d == "right": return tcx - fcx > 0.5
    if d == "up": return fcy - tcy > 0.5
    return tcy - fcy > 0.5

def cost(f, t, d):
    horiz = d in ("left", "right")
    if horiz:
        gap = (t["x"] - (f["x"] + f["w"])) if d == "right" else (f["x"] - (t["x"] + t["w"]))
        apart = max(t["y"] - (f["y"] + f["h"]), f["y"] - (t["y"] + t["h"]))
        cross = abs((t["y"] + t["h"] / 2) - (f["y"] + f["h"] / 2))
    else:
        gap = (t["y"] - (f["y"] + f["h"])) if d == "down" else (f["y"] - (t["y"] + t["h"]))
        apart = max(t["x"] - (f["x"] + f["w"]), f["x"] - (t["x"] + t["w"]))
        cross = abs((t["x"] + t["w"] / 2) - (f["x"] + f["w"] / 2))
        if (t["x"] + t["w"] / 2) < (f["x"] + f["w"] / 2): cross *= 0.5   # between equals, the left one (reading order)
    tier = 0 if apart <= -2 else 1
    return tier, max(0, gap) + max(0, apart) * 2 + cross * 0.05

def panel(zone):
    for suf, p in (("TabBar", "tabs"), ("TabContent", "drawer"), ("MainInv", "list"), ("Ctl", "list"),
                   ("ItemCard", "card"), ("ContainerStrip", "strip")):
        if zone.endswith(suf): return p
    if zone[:-1].endswith("MC") or "MC" in zone: return "list"
    return zone

def gap_of(f, t, d):
    if d == "right": return t["x"] - (f["x"] + f["w"])
    if d == "left": return f["x"] - (t["x"] + t["w"])
    if d == "down": return t["y"] - (f["y"] + f["h"])
    return f["y"] - (t["y"] + t["h"])

def expected(e, els, d, data):
    """The move the screen suggests, by the house rules the director set:
    Up / Down stay in the panel while it has something that way; Left / Right
    go to the next panel when nothing in this one is level; a move never jumps
    over a nearer panel; landing in a column lands on what it shows."""
    cands = [t for t in els if t is not e and along_ok(e, t, d)]
    if not cands:
        if d in ("left", "right") and data.get("other"):
            o, r = data["other"], data["rect"]
            if (d == "right" and o["x"] > r["x"]) or (d == "left" and o["x"] < r["x"]):
                return ("window", None)
        return (None, None)
    pe = panel(e["zone"])
    if d in ("up", "down"):
        samez = [t for t in cands if t["zone"] == e["zone"]]
        same = [t for t in cands if panel(t["zone"]) == pe]
        pool = samez or same or cands
        best = min(pool, key=lambda t: cost(e, t, d))
    else:
        best = min(cands, key=lambda t: cost(e, t, d))
        if cost(e, best, d)[0] == 1 and panel(best["zone"]) == pe:
            others = [t for t in cands if panel(t["zone"]) != pe]
            if others: best = min(others, key=lambda t: cost(e, t, d))
        if panel(best["zone"]) != pe:
            # the nearest panel that way, not one further off
            near = {}
            for t in cands:
                p = panel(t["zone"])
                if p != pe:
                    near[p] = min(near.get(p, 1e9), max(0, gap_of(e, t, d)))
            np = min(near, key=lambda p: near[p])
            if np != panel(best["zone"]) and near[np] < max(0, gap_of(e, best, d)):
                best = min([t for t in cands if panel(t["zone"]) == np], key=lambda t: cost(e, t, d))
    z = best["zone"]
    if z != e["zone"]:
        if z.endswith("TabBar") or z.endswith("ContainerStrip"):
            act = [t for t in els if t["zone"] == z and t.get("active")]
            if act: return (z, act[0]["id"])
        if z.endswith("MainInv") and d in ("left", "right"):
            return (z, "*row")
        prim = [t for t in els if t["zone"] == z and t.get("primary")]
        if prim: return (z, prim[0]["id"])
    return (z, best["id"])

def matches(exp, act):
    ez, eid = exp
    az, aid = act.get("zone"), act.get("id")
    if ez is None: return az is None
    if ez == "window": return az == "window"
    if eid == "*row": return az == ez
    return ez == az and eid == aid

def font(sz):
    for f in ("consola.ttf", "arial.ttf"):
        try: return ImageFont.truetype(f, sz)
        except Exception: pass
    return ImageFont.load_default()

def short(m):
    if not m or not m.get("zone"): return "-"
    z = m["zone"].replace("char", "").replace("world", "")
    return z + ":" + str(m.get("id"))

def run():
    os.makedirs(OUT, exist_ok=True)
    rows, total_mis, total_moves = [], 0, 0
    blank = []
    for old in glob.glob(os.path.join(OUT, "*.png")): os.remove(old)   # (a capture left out this time leaves no stale picture)
    detail = []
    for jp in sorted(glob.glob(os.path.join(LUA, "zqa_pm_*.json"))):
        name = os.path.basename(jp)[7:-5]
        data = json.load(open(jp, encoding="utf-8"))
        shot = os.path.join(SHOTS, "zqa_pm_" + name + ".png")
        if data.get("window") == "Belt":
            boxes = data["boxes"]
            dead = [b for b in boxes if any(v == str(b["n"]) for v in b["moves"].values())]
            rows.append((name, len(boxes), 4 * len(boxes), len(dead), "belt: every press moves or leaves" if not dead else "belt: presses that do nothing"))
            if os.path.exists(shot):
                im = Image.open(shot).convert("RGB")
                x0 = int(min(b["x"] for b in boxes)) - 40; y0 = int(min(b["y"] for b in boxes)) - 40
                x1 = int(max(b["x"] + b["w"] for b in boxes)) + 40; y1 = int(max(b["y"] + b["h"] for b in boxes)) + 40
                crop = im.crop((x0, y0, x1, y1))
                if crop.convert("L").getextrema()[1] < 8: blank.append(name)
                crop.save(os.path.join(OUT, name + "_clean.png"))
                dr = ImageDraw.Draw(crop); fn = font(26)
                for b in boxes:
                    bx, by = b["x"] - x0, b["y"] - y0
                    dr.rectangle([bx, by, bx + b["w"], by + b["h"]], outline=(255, 210, 0), width=1)
                    dr.text((bx + 4, by + 2), str(b["n"]), fill=(255, 210, 0), font=fn)
                crop.save(os.path.join(OUT, name + ".png"))
            lines = ["| # | kind | up | down | left | right |", "|---|---|---|---|---|---|"]
            for b in boxes:
                m = b["moves"]
                lines.append(f"| {b['n']} | {b['kind']} | {m['up']} | {m['down']} | {m['left']} | {m['right']} |")
            detail.append((name, lines))
            continue
        els = data["els"]
        mis_lines = ["| # | stop | dir | real move | expected |", "|---|---|---|---|---|"]
        mis = 0; moves = 0
        for e in els:
            for d in ("up", "down", "left", "right"):
                act = e["moves"][d]
                if e.get("own"): continue
                moves += 1
                exp = expected(e, els, d, data)
                if not matches(exp, act):
                    mis += 1
                    es = "-" if exp[0] is None else (exp[0] if exp[1] is None else exp[0].replace("char", "").replace("world", "") + ":" + str(exp[1]))
                    mis_lines.append(f"| {e['n']} | {e['zone']}:{e['id']} | {d} | {short(act)} ({act.get('pass')}) | {es} |")
        total_mis += mis; total_moves += moves
        own = sum(1 for e in els if e.get("own"))
        rows.append((name, len(els), moves, mis, data.get("note", "") + (f"; {own} stops with their own D-pad" if own else "")))
        detail.append((name, mis_lines if mis else ["(no mismatches)"]))
        if os.path.exists(shot):
            im = Image.open(shot).convert("RGB")
            r = data["rect"]
            x0, y0 = max(0, int(r["x"])), max(0, int(r["y"]))
            crop = im.crop((x0, y0, int(r["x"] + r["w"]), int(r["y"] + r["h"])))
            if crop.convert("L").getextrema()[1] < 8:
                blank.append(name)   # (the game was not drawing: minimised or behind another window)
            crop.save(os.path.join(OUT, name + "_clean.png"))   # the panel as the game drew it
            dr = ImageDraw.Draw(crop, "RGBA"); fn = font(26)
            bad = set()
            for line in mis_lines[2:]:
                bad.add(int(line.split("|")[1]))
            for e in els:
                ex, ey = e["x"] + r["x"] - x0, e["y"] + r["y"] - y0
                col = (255, 60, 60, 255) if e["n"] in bad else ((120, 200, 255, 255) if e.get("own") else (255, 210, 0, 255))
                dr.rectangle([ex, ey, ex + e["w"], ey + e["h"]], outline=col, width=1)
                # the number on a small tag outside the box's top-left corner (above
                # it; left of it when the box touches the top), so the box's own
                # text stays readable
                label = str(e["n"])
                tw, th = int(dr.textlength(label, font=fn)) + 8, 30
                tx, ty = ex - tw, ey - th
                if ty < 0: tx, ty = ex - tw, ey
                if tx < 0: tx = 0
                dr.rectangle([tx, ty, tx + tw, ty + th], fill=(0, 0, 0, 200), outline=col, width=1)
                dr.text((tx + 4, ty), label, fill=col, font=fn)
            crop.save(os.path.join(OUT, name + ".png"))
    with open(os.path.join(OUT, "index.md"), "w", encoding="utf-8") as f:
        f.write("# Pad map\n\nEach capture comes twice: `<name>.png` is the window as the game drew it with every controller stop outlined and numbered (yellow; red = a move that differs from what the screen suggests; blue = a stop with its own D-pad handling), `<name>_clean.png` the same window without the marks. The tables list each differing move: the real move (from the game's own dispatch) and the expected one.\n\n")
        f.write(f"Moves compared: {total_moves}; differing: {total_mis}.\n\n")
        if blank: f.write("Blank screenshots (the game was not on screen when they were taken): " + ", ".join(blank) + "\n\n")
        f.write("| capture | clean | stops | moves | differing | note |\n|---|---|---|---|---|---|\n")
        for r in rows: f.write(f"| [{r[0]}]({r[0]}.png) | [clean]({r[0]}_clean.png) | {r[1]} | {r[2]} | {r[3]} | {r[4]} |\n")
        for name, lines in detail:
            f.write(f"\n## {name}\n\n![{name}]({name}.png)\n\n[without the marks]({name}_clean.png)\n\n" + "\n".join(lines) + "\n")
    print(f"{len(rows)} captures, {total_moves} moves, {total_mis} differing, {len(blank)} blank -> {OUT}")

if __name__ == "__main__":
    run()
