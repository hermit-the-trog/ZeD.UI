"""
make_survey_data.py -- build the "survey" layer for the ZeD paper map.

What this does, in plain words:
  The game ships a description of its world map (Muldraugh, KY) as text
  files: outlines of every building, road and body of water, plus a list of
  printed labels (town names, lake names). This script reads those files,
  works out a few things a paper road map shows (town sizes, landmark
  buildings, bridges, route shields, lakes) and writes them to one small
  Lua file the mod loads at run time, plus one picture (mask) per lake.

  Nothing here runs inside the game. Run it again whenever the game's map
  files change; it always produces the same output for the same input.

How to run (from the repository root):
  python ZeDUI/tools/map/make_survey_data.py [path-to-ProjectZomboid-folder]

  The argument is the game's install folder (the one holding "media").
  If left out, the usual Steam location on drive E: is tried.

Needs: Python 3 with numpy, Pillow, scipy and OpenCV (cv2).

Outputs (paths relative to the repository root):
  42/media/lua/client/ZeD/MapsSurveyData.lua
  42/media/textures/ZeD/map/lakes/lake_<i>.png
  ZeDUI/tools/map/survey_data_report.md

A note on units: the game measures the world in "squares" (one floor tile).
The map files split the world into 300 x 300 square "cells". In
worldmap.xml every point is written relative to its cell, so the real
world position is  cell number * 300 + local position.  In streets.xml and
worldmap-annotations.lua points are already in world squares.
"""

import math
import os
import re
import sys
import xml.etree.ElementTree as ET

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage
import cv2

# ---------------------------------------------------------------------------
# Settings. Everything a person might want to tune lives here.
# ---------------------------------------------------------------------------

DEFAULT_GAME = r"E:\Project Zomboid\steamapps\common\ProjectZomboid"
MAP_SUBFOLDER = os.path.join("media", "maps", "Muldraugh, KY")
CELL = 300          # squares per map cell
PX = 2              # squares per pixel for every raster (picture) we make

# Town size: count building outlines within this many squares of the label.
# 600 rather than 300: the Louisville label sits beside a park, so a 300
# circle catches only 141 of its buildings; at 600 it catches about 1000,
# while the next biggest town (West Point, Muldraugh) is about 450.
TOWN_RADIUS = 600
TOWN_SIZE_2_AT = 240    # this many buildings or more -> size 2
TOWN_SIZE_3_AT = 600    # more than this many -> size 3 (city)

# Landmark buildings: game "RoomTone" names grouped into map symbol kinds.
PLACE_GROUPS = {
    "gas":      ["Gas", "GasBurnt"],
    "police":   ["Police", "PoliceBurnt", "Sheriff"],
    "fire":     ["Firestation"],
    "hospital": ["Hospital", "Medical", "Nursinghome"],
    "pharmacy": ["Pharmacy"],
    "school":   ["School", "SchoolColege"],
    "church":   ["Church"],
    "grocery":  ["Grocery", "Generalstore", "Cornerstore", "Farmstore"],
    "lodging":  ["Motel", "Hotel", "Bedandbreakfast"],
    "post":     ["Post"],
    "airport":  ["Airport", "AirstripOffice", "Hanger"],
    "rail":     ["Trainstation", "TrainstationAbadoned"],
    "military": ["MilitaryHouse", "MilitaryTownhouse", "MilitaryTent",
                 "MilitaryTower", "MilitaryCommunications", "MilitaryBorder",
                 "MilitaryTrailer", "MilitaryApartments"],
    "prison":   ["Prison", "Detentioncenter"],
    "bank":     ["Bank"],
    "mechanic": ["Mechanic"],
    "guns":     ["Gunclub", "ShopHunting", "Shootingrange"],
    "library":  ["Library"],
}
PLACE_MERGE = 60    # same-kind points closer than this become one point

# Bridges: road types that count, and how close two bridge pieces must be
# to count as one bridge.
BRIDGE_ROADS = ("primary", "secondary", "tertiary")
BRIDGE_MIN_PIXELS = 3
BRIDGE_MERGE = 20
BRIDGE_DIR_RADIUS = 40  # squares of road around a bridge used to find its direction

# Route shields along numbered highways.
SHIELD_EVERY = 600
SHIELD_DEDUP = 400

# Lakes.
LAKE_OPEN = 4           # pixels; water narrower than ~2*4*2 = 16 squares is
                        # treated as a stream and cut away before judging shape
LAKE_COMPACT = 0.25     # area / circle-of-longest-span-area above this = lake
LAKE_BIG_AREA = 4000    # squares; or bigger than this ...
LAKE_BIG_ASPECT = 3.0   # ... and bounding box no longer than 3:1
LAKE_BIG_COMPACT = 0.12 # ... and not a bending river (Salt River is 0.06)
LAKE_MIN_AREA = 1000    # squares; ignore ponds smaller than this (about 32x32)
LAKE_MARGIN = 2         # pixels of empty border around each lake picture


# ---------------------------------------------------------------------------
# Step 1: read the game files.
# ---------------------------------------------------------------------------

def read_worldmap(path):
    """Read worldmap.xml into a list of features.

    Each feature is a dict: {"type": "Polygon", "rings": [ring, ...],
    "props": {name: value}}. A ring is a list of (x, y) world-square points.
    The first ring is the outline; any further rings are holes (islands in a
    lake, courtyards in a building)."""
    feats = []
    cells = []
    root = ET.parse(path).getroot()
    for cell in root.iter("cell"):
        cx, cy = int(cell.get("x")), int(cell.get("y"))
        cells.append((cx, cy))
        ox, oy = cx * CELL, cy * CELL
        for f in cell.iter("feature"):
            g = f.find("geometry")
            rings = []
            for c in g.iter("coordinates"):
                ring = [(ox + float(p.get("x")), oy + float(p.get("y")))
                        for p in c.iter("point")]
                if ring:
                    rings.append(ring)
            props = {p.get("name"): p.get("value") for p in f.iter("property")}
            feats.append({"type": g.get("type"), "rings": rings, "props": props})
    return feats, cells


def read_streets(path):
    """Read streets.xml: list of (name, [(x, y), ...]) in world squares."""
    out = []
    root = ET.parse(path).getroot()
    for s in root.iter("street"):
        pts = [(float(p.get("x")), float(p.get("y"))) for p in s.iter("point")]
        out.append((s.get("name") or "", pts))
    return out


LABEL_RE = re.compile(
    r'addUntranslatedText\(\s*"([^"]*)"\s*,\s*"([^"]*)"\s*,\s*(-?[\d.]+)\s*,\s*(-?[\d.]+)\s*\)')


def read_labels(path):
    """Read worldmap-annotations.lua: list of (text, style, x, y).
    Lines switched off with a Lua comment ("--") are skipped."""
    out = []
    with open(path, encoding="utf-8", errors="replace") as fh:
        for line in fh:
            code = line.split("--", 1)[0]
            m = LABEL_RE.search(code)
            if m:
                out.append((m.group(1), m.group(2), float(m.group(3)), float(m.group(4))))
    return out


# ---------------------------------------------------------------------------
# Small geometry helpers.
# ---------------------------------------------------------------------------

def ring_area_centroid(ring):
    """Area-weighted centre of a polygon outline (the 'balance point').
    Falls back to the plain average of the corners for degenerate shapes."""
    a = cx = cy = 0.0
    n = len(ring)
    for i in range(n):
        x0, y0 = ring[i]
        x1, y1 = ring[(i + 1) % n]
        cr = x0 * y1 - x1 * y0
        a += cr
        cx += (x0 + x1) * cr
        cy += (y0 + y1) * cr
    if abs(a) < 1e-9:
        return (sum(p[0] for p in ring) / n, sum(p[1] for p in ring) / n)
    return (cx / (3 * a), cy / (3 * a))


def merge_points(points, dist):
    """Join points closer than `dist` into one point at their average.

    Works like this: walk the points in a fixed order; each point joins the
    first group whose current centre is within `dist`, otherwise it starts a
    new group. Then groups whose centres ended up within `dist` of each other
    are joined, repeated until nothing changes. Fixed order = same answer
    every run."""
    groups = []  # each: [sum_x, sum_y, count]
    for x, y in sorted(points):
        for g in groups:
            if math.hypot(g[0] / g[2] - x, g[1] / g[2] - y) <= dist:
                g[0] += x; g[1] += y; g[2] += 1
                break
        else:
            groups.append([x, y, 1])
    changed = True
    while changed:
        changed = False
        for i in range(len(groups)):
            for j in range(i + 1, len(groups)):
                a, b = groups[i], groups[j]
                if math.hypot(a[0] / a[2] - b[0] / b[2], a[1] / a[2] - b[1] / b[2]) <= dist:
                    a[0] += b[0]; a[1] += b[1]; a[2] += b[2]
                    del groups[j]
                    changed = True
                    break
            if changed:
                break
    return [(g[0] / g[2], g[1] / g[2], g[2]) for g in groups]


class Raster:
    """A black-and-white picture of the whole map at PX squares per pixel.
    Pixel (col, row) covers world squares starting at
    (x1 + col*PX, y1 + row*PX)."""

    def __init__(self, bounds):
        self.x1, self.y1, self.x2, self.y2 = bounds
        self.w = (self.x2 - self.x1) // PX
        self.h = (self.y2 - self.y1) // PX
        self.a = np.zeros((self.h, self.w), dtype=bool)

    def add_polygon(self, rings):
        """Paint one polygon (outline minus its holes) onto the picture.
        Each polygon is drawn on its own small scratch picture first so its
        holes only cut into itself, never into a neighbouring polygon."""
        outer = rings[0]
        xs = [(x - self.x1) / PX for x, _ in outer]
        ys = [(y - self.y1) / PX for _, y in outer]
        c0 = max(int(math.floor(min(xs))) - 1, 0)
        r0 = max(int(math.floor(min(ys))) - 1, 0)
        c1 = min(int(math.ceil(max(xs))) + 1, self.w)
        r1 = min(int(math.ceil(max(ys))) + 1, self.h)
        if c1 <= c0 or r1 <= r0:
            return
        img = Image.new("1", (c1 - c0, r1 - r0), 0)
        d = ImageDraw.Draw(img)
        for k, ring in enumerate(rings):
            pts = [((x - self.x1) / PX - c0, (y - self.y1) / PX - r0) for x, y in ring]
            if len(pts) >= 3:
                d.polygon(pts, fill=1 if k == 0 else 0)
        self.a[r0:r1, c0:c1] |= np.array(img, dtype=bool)

    def to_world(self, col, row):
        """Centre of a pixel, in world squares."""
        return (self.x1 + (col + 0.5) * PX, self.y1 + (row + 0.5) * PX)


# ---------------------------------------------------------------------------
# Step 2: towns.
# ---------------------------------------------------------------------------

def make_towns(labels, building_pts, report):
    towns = []
    bp = np.array(building_pts) if building_pts else np.zeros((0, 2))
    report.append("## Towns\n")
    report.append(f"Buildings counted within {TOWN_RADIUS} squares of each town label. "
                  f"Size 1 below {TOWN_SIZE_2_AT}, size 2 from {TOWN_SIZE_2_AT} to "
                  f"{TOWN_SIZE_3_AT}, size 3 above {TOWN_SIZE_3_AT}.\n")
    report.append("| label | x | y | buildings | size |")
    report.append("|---|---|---|---|---|")
    for text, style, x, y in labels:
        if style != "text-town":
            continue
        n = int(np.sum(np.hypot(bp[:, 0] - x, bp[:, 1] - y) <= TOWN_RADIUS)) if len(bp) else 0
        size = 1 if n < TOWN_SIZE_2_AT else (2 if n <= TOWN_SIZE_3_AT else 3)
        towns.append({"key": text, "x": round(x), "y": round(y), "size": size, "n": n})
        report.append(f"| {text} | {round(x)} | {round(y)} | {n} | {size} |")
    report.append("")
    return towns


# ---------------------------------------------------------------------------
# Step 3: landmark places.
# ---------------------------------------------------------------------------

def make_places(feats, report):
    tone_to_kind = {}
    for kind, tones in PLACE_GROUPS.items():
        for t in tones:
            tone_to_kind[t] = kind
    raw = {k: [] for k in PLACE_GROUPS}
    seen_tones = set()
    for f in feats:
        tone = f["props"].get("RoomTone")
        if f["type"] != "Polygon" or not f["rings"] or tone is None:
            continue
        seen_tones.add(tone)
        kind = tone_to_kind.get(tone)
        if kind:
            raw[kind].append(ring_area_centroid(f["rings"][0]))
    places = []
    report.append("## Places\n")
    report.append(f"Building outlines grouped by RoomTone; same-kind points within "
                  f"{PLACE_MERGE} squares merged.\n")
    report.append("| kind | outlines | after merge |")
    report.append("|---|---|---|")
    for kind in PLACE_GROUPS:
        merged = merge_points(raw[kind], PLACE_MERGE)
        for x, y, _ in merged:
            places.append({"kind": kind, "x": round(x), "y": round(y)})
        report.append(f"| {kind} | {len(raw[kind])} | {len(merged)} |")
    missing = sorted(t for t in tone_to_kind if t not in seen_tones)
    report.append("")
    report.append("RoomTones in the groups that this map does not use: "
                  + (", ".join(missing) if missing else "none") + "\n")
    places.sort(key=lambda p: (p["kind"], p["x"], p["y"]))
    return places


# ---------------------------------------------------------------------------
# Step 4: bridges.
# ---------------------------------------------------------------------------

def dry_road_ahead(water, roads, c, r, vx, vy, steps):
    """Walk from pixel (c, r) in direction (vx, vy); True if we reach a road
    pixel that is not water (with a 1-pixel allowance either side)."""
    for t in range(1, steps + 1):
        cc = int(round(c + vx * t)); rr = int(round(r + vy * t))
        if not (1 <= cc < roads.w - 1 and 1 <= rr < roads.h - 1):
            return False
        win_r = roads.a[rr - 1:rr + 2, cc - 1:cc + 2]
        win_w = water.a[rr - 1:rr + 2, cc - 1:cc + 2]
        if (win_r & ~win_w).any():
            return True
    return False


def make_bridges(water, feats, bounds, report):
    roads = Raster(bounds)
    for f in feats:
        if f["type"] == "Polygon" and f["rings"] and f["props"].get("highway") in BRIDGE_ROADS:
            roads.add_polygon(f["rings"])
    both = water.a & roads.a
    lab, n = ndimage.label(both, structure=np.ones((3, 3)))
    pieces = []
    dead_ends = []
    rad = int(BRIDGE_DIR_RADIUS / PX)
    for i, sl in enumerate(ndimage.find_objects(lab), start=1):
        if sl is None:
            continue
        rr, cc = np.nonzero(lab[sl] == i)
        if len(rr) < BRIDGE_MIN_PIXELS:
            continue
        r = rr.mean() + sl[0].start
        c = cc.mean() + sl[1].start
        # Direction: look at the road (not the water) around the bridge and
        # find the line the road pixels lie along (principal axis).
        r0, r1 = max(int(r) - rad, 0), min(int(r) + rad + 1, roads.h)
        c0, c1 = max(int(c) - rad, 0), min(int(c) + rad + 1, roads.w)
        yy, xx = np.nonzero(roads.a[r0:r1, c0:c1])
        yy = yy + r0 - r; xx = xx + c0 - c
        keep = np.hypot(xx, yy) <= rad
        xx, yy = xx[keep], yy[keep]
        if len(xx) >= 3:
            cov = np.cov(np.vstack([xx, yy]))
            vals, vecs = np.linalg.eigh(cov)
            vx, vy = vecs[:, 1]
            ang = math.degrees(math.atan2(vy, vx)) % 180.0
        else:
            vx, vy, ang = 1.0, 0.0, 0.0
        # A real bridge has dry road on BOTH ends. A road that just runs down
        # to a shore and stops (a boat ramp, a ferry landing) touches water
        # too, but only has road on one side; those are dropped here.
        if not (dry_road_ahead(water, roads, c, r, vx, vy, 200)
                and dry_road_ahead(water, roads, c, r, -vx, -vy, 200)):
            dead_ends.append(water.to_world(c, r))
            continue
        x, y = water.to_world(c, r)
        pieces.append((x, y, ang, len(rr)))
    # Merge pieces that belong to the same bridge.
    merged = []
    for x, y, ang, npx in sorted(pieces):
        for m in merged:
            if math.hypot(m["sx"] / m["w"] - x, m["sy"] / m["w"] - y) <= BRIDGE_MERGE:
                m["sx"] += x * npx; m["sy"] += y * npx; m["w"] += npx
                if npx > m["best"]:
                    m["best"], m["a"] = npx, ang
                break
        else:
            merged.append({"sx": x * npx, "sy": y * npx, "w": npx, "a": ang, "best": npx})
    bridges = [{"x": round(m["sx"] / m["w"]), "y": round(m["sy"] / m["w"]),
                "a": int(round(m["a"])) % 180} for m in merged]
    bridges.sort(key=lambda b: (b["x"], b["y"]))
    report.append("## Bridges\n")
    report.append(f"Road (primary/secondary/tertiary) over water=river, {PX} squares per "
                  f"pixel: {n} overlap pieces; {len(dead_ends)} dropped as roads that "
                  f"end at the water (no dry road on one side: "
                  + ", ".join(f"{round(x)},{round(y)}" for x, y in dead_ends) +
                  f"); {len(pieces)} kept of at least "
                  f"{BRIDGE_MIN_PIXELS} pixels, {len(bridges)} bridges after merging "
                  f"within {BRIDGE_MERGE} squares. Angle a: 0 = east-west, 90 = "
                  f"north-south (y grows southward, so 45 runs northwest to southeast).\n")
    return bridges


# ---------------------------------------------------------------------------
# Step 5: route shields.
# ---------------------------------------------------------------------------

ROUTE_PATTERNS = [
    (re.compile(r"\bKY-\s*(\d+[A-Z]?)\b"), "ky"),
    (re.compile(r"\bRoute\s*(\d+)\s*([A-Z]?)\b"), "us"),
    (re.compile(r"\bUS-?\s*(\d+[A-Z]?)\b"), "us"),
    (re.compile(r"\bI-\s*(\d+)\b"), "i"),
    (re.compile(r"\bInterstate\s*(\d+)\b"), "i"),
]


def route_of(name):
    for rx, t in ROUTE_PATTERNS:
        m = rx.search(name)
        if m:
            return t, "".join(g for g in m.groups() if g)
    return None


def point_along(pts, dist):
    """The point `dist` squares along a path of points."""
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        seg = math.hypot(x1 - x0, y1 - y0)
        if dist <= seg and seg > 0:
            t = dist / seg
            return (x0 + (x1 - x0) * t, y0 + (y1 - y0) * t)
        dist -= seg
    return pts[-1]


def make_shields(streets, report):
    digit_names = {}
    for name, _ in streets:
        if re.search(r"\d", name):
            digit_names[name] = digit_names.get(name, 0) + 1
    shields = []
    for name, pts in streets:
        r = route_of(name)
        if not r or len(pts) < 2:
            continue
        t, n = r
        length = sum(math.hypot(b[0] - a[0], b[1] - a[1]) for a, b in zip(pts, pts[1:]))
        k = max(1, int(length // SHIELD_EVERY))
        for i in range(k):
            x, y = point_along(pts, (i + 0.5) * length / k)
            if any(s["t"] == t and s["n"] == n and
                   math.hypot(s["x"] - x, s["y"] - y) < SHIELD_DEDUP for s in shields):
                continue
            shields.append({"t": t, "n": n, "x": round(x), "y": round(y)})
    shields.sort(key=lambda s: (s["t"], s["n"], s["x"], s["y"]))
    report.append("## Shields\n")
    report.append(f"One shield per {SHIELD_EVERY} squares of street (at least one, at the "
                  f"middle); same route within {SHIELD_DEDUP} squares dropped.\n")
    report.append("Every street name holding a digit (count of street pieces, route read):\n")
    for name in sorted(digit_names):
        r = route_of(name)
        report.append(f"- {name} ({digit_names[name]}) -> " + (f"{r[0]} {r[1]}" if r else "no route"))
    counts = {}
    for s in shields:
        counts[(s["t"], s["n"])] = counts.get((s["t"], s["n"]), 0) + 1
    report.append("")
    report.append("Shields per route: " + ", ".join(f"{t} {n}: {c}" for (t, n), c in sorted(counts.items())) + "\n")
    return shields


# ---------------------------------------------------------------------------
# Step 6: lakes.
# ---------------------------------------------------------------------------

def max_feret(rr, cc):
    """Longest straight distance across a shape (in pixels), measured on the
    outline of its convex hull."""
    pts = np.stack([cc, rr], axis=1).astype(np.float32)
    if len(pts) < 2:
        return 1.0
    hull = cv2.convexHull(pts).reshape(-1, 2)
    d = hull[:, None, :] - hull[None, :, :]
    return float(np.sqrt((d ** 2).sum(-1)).max()) + 1.0


def make_lakes(water, labels, out_dir, rel_tex_dir, report):
    # Thin streams joined to a lake would make the lake look long and thin,
    # so first "open" the water: shrink it by LAKE_OPEN pixels and grow it
    # back. Streams narrower than that vanish; real bodies of water keep their
    # shape. The opened shapes are judged; the final picture uses the real
    # water within reach of each opened shape.
    k = 2 * LAKE_OPEN + 1
    disk = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (k, k))
    opened = cv2.morphologyEx(water.a.astype(np.uint8), cv2.MORPH_OPEN, disk).astype(bool)
    lab, n = ndimage.label(opened, structure=np.ones((3, 3)))
    rows = []
    for i, sl in enumerate(ndimage.find_objects(lab), start=1):
        if sl is None:
            continue
        sub = lab[sl] == i
        rr, cc = np.nonzero(sub)
        area = len(rr) * PX * PX
        r0, r1, c0, c1 = sl[0].start, sl[0].stop, sl[1].start, sl[1].stop
        bw, bh = (c1 - c0) * PX, (r1 - r0) * PX
        aspect = max(bw, bh) / max(1, min(bw, bh))
        feret = max_feret(rr, cc) * PX
        compact = area / (math.pi * (feret / 2) ** 2)
        edge = r0 == 0 or c0 == 0 or r1 == water.h or c1 == water.w
        if edge:
            verdict = "edge"
        elif area < LAKE_MIN_AREA:
            verdict = "tiny"
        elif compact > LAKE_COMPACT or (area > LAKE_BIG_AREA and aspect < LAKE_BIG_ASPECT
                                          and compact > LAKE_BIG_COMPACT):
            verdict = "LAKE"
        else:
            verdict = "stream"
        rows.append({"i": i, "area": area, "sl": sl, "bw": bw, "bh": bh,
                     "aspect": aspect, "compact": compact, "verdict": verdict})
    rows.sort(key=lambda r: -r["area"])

    os.makedirs(out_dir, exist_ok=True)
    for fn in os.listdir(out_dir):  # clear old pictures so numbering stays clean
        if re.match(r"lake_\d+\.png$", fn):
            os.remove(os.path.join(out_dir, fn))

    # Lakes are numbered by position (north to south, then west to east) so
    # the numbers do not jump around when a threshold changes slightly.
    lake_rows = [r for r in rows if r["verdict"] == "LAKE"]
    lake_rows.sort(key=lambda r: (r["sl"][0].start, r["sl"][1].start))
    grow = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (k + 2, k + 2))
    water_labels = [(t, x, y) for t, s, x, y in labels if s.startswith("text-water")]
    lakes = []
    total_bytes = 0
    for idx, r in enumerate(lake_rows, start=1):
        sl = r["sl"]
        m = LAKE_MARGIN + LAKE_OPEN + 2
        r0 = max(sl[0].start - m, 0); r1 = min(sl[0].stop + m, water.h)
        c0 = max(sl[1].start - m, 0); c1 = min(sl[1].stop + m, water.w)
        core = (lab[r0:r1, c0:c1] == r["i"]).astype(np.uint8)
        reach = cv2.dilate(core, grow).astype(bool)
        mask = water.a[r0:r1, c0:c1] & reach
        rr, cc = np.nonzero(mask)
        # Crop to the lake itself plus a small empty margin.
        pr0 = max(rr.min() + r0 - LAKE_MARGIN, 0); pr1 = min(rr.max() + r0 + 1 + LAKE_MARGIN, water.h)
        pc0 = max(cc.min() + c0 - LAKE_MARGIN, 0); pc1 = min(cc.max() + c0 + 1 + LAKE_MARGIN, water.w)
        full = np.zeros((pr1 - pr0, pc1 - pc0), dtype=bool)
        full[rr + r0 - pr0, cc + c0 - pc0] = True
        rgba = np.zeros(full.shape + (4,), dtype=np.uint8)
        rgba[full] = (255, 255, 255, 255)
        fn = f"lake_{idx}.png"
        path = os.path.join(out_dir, fn)
        Image.fromarray(rgba, "RGBA").save(path, optimize=True)
        total_bytes += os.path.getsize(path)
        x1 = water.x1 + pc0 * PX; x2 = water.x1 + pc1 * PX
        y1 = water.y1 + pr0 * PX; y2 = water.y1 + pr1 * PX
        # Name: the closest water label that sits inside this lake's box.
        cx = water.x1 + (cc.mean() + c0 + 0.5) * PX
        cy = water.y1 + (rr.mean() + r0 + 0.5) * PX
        best = None
        for t, lx, ly in water_labels:
            if x1 <= lx <= x2 and y1 <= ly <= y2:
                d = math.hypot(lx - cx, ly - cy)
                if best is None or d < best[0]:
                    best = (d, t)
        lake = {"tex": rel_tex_dir + "/" + fn, "x1": x1, "y1": y1, "x2": x2, "y2": y2,
                "key": best[1] if best else None}
        r["lake"] = idx
        r["name"] = lake["key"]
        lakes.append(lake)

    report.append("## Lakes\n")
    report.append(f"All water=river polygons at {PX} squares per pixel; streams thinner than "
                  f"about {2 * LAKE_OPEN * PX} squares cut away first (opening, radius "
                  f"{LAKE_OPEN} px); 8-connected bodies. Lake = not touching the map edge, "
                  f"at least {LAKE_MIN_AREA} squares, and compactness > {LAKE_COMPACT} or "
                  f"(area > {LAKE_BIG_AREA} and box aspect < {LAKE_BIG_ASPECT} and compactness > "
                  f"{LAKE_BIG_COMPACT}). "
                  f"{len(rows)} bodies, {len(lakes)} lakes. Lake pictures total "
                  f"{total_bytes} bytes.\n")
    report.append("| rank | area | bbox (x1,y1 w x h) | aspect | compact | verdict | lake | name |")
    report.append("|---|---|---|---|---|---|---|---|")
    for rank, r in enumerate(rows[:40], start=1):
        sl = r["sl"]
        bx = water.x1 + sl[1].start * PX; by = water.y1 + sl[0].start * PX
        report.append(f"| {rank} | {r['area']} | {bx},{by} {r['bw']}x{r['bh']} | "
                      f"{r['aspect']:.1f} | {r['compact']:.2f} | {r['verdict']} | "
                      f"{r.get('lake', '')} | {r.get('name') or ''} |")
    report.append("")
    named = {l["key"] for l in lakes if l["key"]}
    unplaced = sorted({t for t, _, _ in water_labels} - named)
    report.append("Water labels not matched to any lake: " + (", ".join(unplaced) or "none") + "\n")
    return lakes, total_bytes


# ---------------------------------------------------------------------------
# Step 7: write the Lua file.
# ---------------------------------------------------------------------------

def lua_str(s):
    s = s.encode("ascii", "replace").decode("ascii")
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def write_lua(path, data, game_dir_note):
    L = []
    L.append("-- MapsSurveyData.lua")
    L.append("-- GENERATED FILE. Do not edit by hand.")
    L.append("-- Made by ZeDUI/tools/map/make_survey_data.py from the game's build 42 map files:")
    L.append("--   " + game_dir_note + "/worldmap.xml")
    L.append("--   " + game_dir_note + "/streets.xml")
    L.append("--   " + game_dir_note + "/worldmap-annotations.lua")
    L.append("-- Coordinates are world squares. Re-run the script to refresh.")
    L.append("")
    L.append("ZeD = ZeD or {}")
    L.append("ZeD.MapsSurveyData = {")
    b = data["bounds"]
    L.append(f"  bounds = {{ {b[0]}, {b[1]}, {b[2]}, {b[3]} }},")
    L.append("  towns = {")
    for t in data["towns"]:
        L.append(f"    {{ key = {lua_str(t['key'])}, x = {t['x']}, y = {t['y']}, size = {t['size']} }},")
    L.append("  },")
    L.append("  places = {")
    for p in data["places"]:
        L.append(f"    {{ kind = {lua_str(p['kind'])}, x = {p['x']}, y = {p['y']} }},")
    L.append("  },")
    L.append("  bridges = {")
    for br in data["bridges"]:
        L.append(f"    {{ x = {br['x']}, y = {br['y']}, a = {br['a']} }},")
    L.append("  },")
    L.append("  shields = {")
    for s in data["shields"]:
        L.append(f"    {{ t = {lua_str(s['t'])}, n = {lua_str(s['n'])}, x = {s['x']}, y = {s['y']} }},")
    L.append("  },")
    L.append("  lakes = {")
    for k in data["lakes"]:
        key = f", key = {lua_str(k['key'])}" if k["key"] else ""
        L.append(f"    {{ tex = {lua_str(k['tex'])}, x1 = {k['x1']}, y1 = {k['y1']}, "
                 f"x2 = {k['x2']}, y2 = {k['y2']}{key} }},")
    L.append("  },")
    L.append("}")
    text = "\n".join(L) + "\n"
    with open(path, "w", encoding="ascii", newline="\n") as fh:
        fh.write(text)


# ---------------------------------------------------------------------------
# Main: run every step in order.
# ---------------------------------------------------------------------------

def main():
    game = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_GAME
    mapdir = os.path.join(game, MAP_SUBFOLDER)
    here = os.path.dirname(os.path.abspath(__file__))
    repo = os.path.normpath(os.path.join(here, "..", "..", ".."))
    lua_out = os.path.join(repo, "42", "media", "lua", "client", "ZeD", "MapsSurveyData.lua")
    tex_rel = "media/textures/ZeD/map/lakes"
    tex_out = os.path.join(repo, "42", *tex_rel.split("/"))
    report_out = os.path.join(here, "survey_data_report.md")

    print("Reading", mapdir)
    feats, cells = read_worldmap(os.path.join(mapdir, "worldmap.xml"))
    streets = read_streets(os.path.join(mapdir, "streets.xml"))
    labels = read_labels(os.path.join(mapdir, "worldmap-annotations.lua"))

    # The area the map covers: from the first cell's corner to the far
    # corner of the last cell.
    xs = [c[0] for c in cells]; ys = [c[1] for c in cells]
    bounds = (min(xs) * CELL, min(ys) * CELL, (max(xs) + 1) * CELL, (max(ys) + 1) * CELL)

    report = ["# ZeD map survey data report", "",
              "Generated by make_survey_data.py. Map folder: media/maps/Muldraugh, KY.", "",
              f"Read {len(cells)} cells, {len(feats)} features, {len(streets)} streets, "
              f"{len(labels)} labels. Bounds (world squares): {bounds}.", ""]
    types = {}
    for f in feats:
        types[f["type"]] = types.get(f["type"], 0) + 1
    report.append("Geometry types: " + ", ".join(f"{k} {v}" for k, v in sorted(types.items()))
                  + " (only Polygons are used).\n")

    building_pts = [ring_area_centroid(f["rings"][0]) for f in feats
                    if f["type"] == "Polygon" and f["rings"] and "building" in f["props"]]
    towns = make_towns(labels, building_pts, report)
    places = make_places(feats, report)

    print("Drawing water ...")
    water = Raster(bounds)
    for f in feats:
        if f["type"] == "Polygon" and f["rings"] and f["props"].get("water") == "river":
            water.add_polygon(f["rings"])
    bridges = make_bridges(water, feats, bounds, report)
    shields = make_shields(streets, report)
    lakes, png_bytes = make_lakes(water, labels, tex_out, tex_rel, report)

    data = {"bounds": bounds, "towns": towns, "places": places, "bridges": bridges,
            "shields": shields, "lakes": lakes}
    write_lua(lua_out, data, "media/maps/Muldraugh, KY")

    summary = (f"## Summary\n\ntowns {len(towns)}, places {len(places)}, bridges "
               f"{len(bridges)}, shields {len(shields)}, lakes {len(lakes)} "
               f"(lake PNGs {png_bytes} bytes).\n")
    report.insert(6, summary)
    text = "\n".join(report) + "\n"
    with open(report_out, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(text)
    print(text)
    print("Wrote", lua_out)
    print("Wrote", report_out)


if __name__ == "__main__":
    main()
