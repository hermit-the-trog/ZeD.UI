"""Hand-wired boards: parts on perforated board joined with coloured insulated wire, painted the plates' way, plus
the router that lays the wire and the checker that reads the painted wiring back into nets.

THE BOARD. Holes every PITCH px (6: a 3 px wire passes between two soldered holes with a pixel clear on each side).
A hole is plated: a part's lead, a wire's end and a bus wire's tap may share one, soldered together on top as one
joint. Two neighbouring holes may also be joined by a solder bridge. Nothing else joins anything: insulated wire may
cross insulated wire, and may lie over an empty hole.

THE LATTICE the router walks: holes at even (a, b), the corners between four holes at odd (a, b), 3 px apart.
A wire runs hole to hole along a row or column of holes, corner to corner along the channel between rows, or
diagonally hole to corner. It may pass straight over an empty hole; it ends only on a hole.

THE CHECKER. (1) The wiring as recorded: union every hole a wire taps or a bridge joins; each part pin sits in a
hole; the resulting groups must be exactly the circuit's nets. (2) The wiring as painted: every wire, lead, bridge
and joint is painted into its own mask; a wire may touch only the joints it is soldered to, bare metal of two nets
may never touch, nothing may cover a joint that isn't its own, and no body may overlap another.
"""
import heapq
import math
from collections import defaultdict

import numpy as np

from physlib import Z_FACE, Mask, add_ramp, rbox, disc, screw, text_w, RAMPS, hx
from engine import edt

PITCH = 6
LW = 3                       # an insulated wire's width, px
WIRE_Z = 1.1

for nm, base, kw in (
    ("perf", "#b98f55", {}),                     # phenolic perforated board, a warm tan
    ("tin", "#c3c7cb", {"light": 1.2}),          # tinned leads and bus wire
    ("w_red", "#c3281f", {}), ("w_blk", "#2b2b30", {}), ("w_yel", "#d6b01c", {}), ("w_grn", "#2d8a3c", {}),
    ("w_blu", "#2c5cc4", {}), ("w_wht", "#dcd9cd", {"light": 1.1}), ("w_org", "#d8691c", {}), ("w_vio", "#7a48b2", {}),
    ("w_brn", "#7a4a22", {}), ("w_gry", "#8c8e92", {}),
    ("disc", "#c98a2e", {}),                     # ceramic disc capacitor
    ("disc_b", "#3c64b4", {}),                   # a blue dipped ceramic
    ("film_r", "#ad2a2c", {}),                   # a red box film capacitor
    ("film_g", "#3e7a3a", {}),                   # a green polyester 'greencap'
    ("elec_k", "#24242a", {}), ("elec_b", "#2a4f9e", {}),
    ("band_n", "#6a3a1c", {}), ("band_v", "#6e3a96", {}), ("band_e", "#808286", {}), ("band_g", "#b8902a", {}),
    ("band_w", "#e2e0d8", {"light": 1.05}), ("band_gr", "#2f7a34", {}), ("band_bl", "#2c56aa", {}),
    ("poly", "#d9d8cc", {"light": 1.08}),        # a polyvaricon's white plastic
    ("ribbon", "#9c9da0", {}),
):
    add_ramp(nm, base, **kw)
for nm, base, kw in (("resistor", "#d8c49a", {}), ("solder", "#b8bcc0", {"light": 1.2}), ("copper", "#b07a3a", {}),
                     ("tape", "#e6dcb8", {"light": 1.1}), ("pcb", "#2c5a2c", {})):
    if nm not in RAMPS: add_ramp(nm, base, **kw)

WIRE = {"red": "w_red", "black": "w_blk", "yellow": "w_yel", "green": "w_grn", "blue": "w_blu", "white": "w_wht",
        "orange": "w_org", "violet": "w_vio", "brown": "w_brn", "grey": "w_gry"}
BAND = {0: "paint_k", 1: "band_n", 2: "paint_r", 3: "paint_o", 4: "paint_y", 5: "band_gr", 6: "band_bl", 7: "band_v",
        8: "band_e", 9: "band_w"}


def ohms(value):
    """'22k' -> 22000, '4k7' -> 4700, '10R' -> 10, '1M' -> 1e6"""
    s = value.upper()
    for k, m in (("K", 1e3), ("M", 1e6), ("R", 1.0)):
        if k in s:
            a, _, b = s.partition(k)
            return float((a or "0") + "." + (b or "0")) * m
    return float(s)


def res_bands(value):
    """the four colour bands of a resistor value: two digits, the multiplier, gold"""
    v = ohms(value)
    e = int(math.floor(math.log10(v) + 1e-9)) - 1
    digits = int(round(v / 10 ** e))
    if digits >= 100: digits //= 10; e += 1
    d1, d2 = divmod(digits, 10)
    mult = {-1: "band_g", -2: "tin"}.get(e, BAND.get(e, "paint_k"))
    return [BAND[d1], BAND[d2], mult, "band_g"]


class Board:
    """the perforated board on a plate: holes at (ox + PITCH*i, oy + PITCH*j), i < cols, j < rows"""

    def __init__(s, p, ox, oy, cols, rows):
        s.p, s.d = p, p.d
        s.ox, s.oy, s.cols, s.rows = ox, oy, cols, rows
        s.parts = {}                       # name -> dict(kind, pins {pin: key}, ...)
        s.pins_at = defaultdict(list)      # key -> ["U1.5", ...]
        s.wires = []                       # dict(color, nodes [(a, b) or edge], taps [key], bare)
        s.bridges = []                     # (key, key)
        s.keep = set()                     # lattice nodes no wire may use (bodies, leads)
        s.keep_seg = set()                 # lattice unit steps no wire may use
        s.used = set()                     # holes with something in them (joints)
        s.occ = {}                         # fine point -> list of (wire index, axis)
        s.diag = {}                        # unit square -> list of (wire index, slope)
        s.edges = {}                       # edge key -> pixel point off the board
        s.entry = {}                       # edge key -> the lattice node a wire reaches it from
        s.support = defaultdict(set)       # part -> holes its tabs are soldered to for support only
        s.masks = {"wire": {}, "lead": {}, "bridge": {}, "joint": {}, "body": {}}
        s.covered = set()                  # (key) holes a part's own body covers on purpose
        s.extra_joints = set()             # holes soldered for support only (a tab with nothing else)
        s.soft = False                     # True: a wire that can't be routed is recorded in `failed`, not raised
        s.failed = []

    # ------------------------------------------------------------------ geometry
    def px(s, key):
        """the pixel (index) of a hole (i, j) or of an edge point"""
        if key in s.edges: return s.edges[key]
        i, j = key
        return (s.ox + PITCH * i, s.oy + PITCH * j)

    def fc(s, key):
        x, y = s.px(key); return (x + 0.5, y + 0.5)

    def node_f(s, n):
        a, b = n
        return (s.ox + 3 * a + 0.5, s.oy + 3 * b + 0.5)

    def hole_of(s, x, y):
        i, j = (x - s.ox) / PITCH, (y - s.oy) / PITCH
        assert abs(i - round(i)) < 1e-6 and abs(j - round(j)) < 1e-6, f"({x},{y}) is not on a hole"
        return (int(round(i)), int(round(j)))

    # ------------------------------------------------------------------ records
    def add_part(s, name, kind, pins, **kw):
        assert name not in s.parts, name
        s.parts[name] = dict(kind=kind, pins=pins, **kw)
        for pin, key in pins.items():
            s.pins_at[key].append(f"{name}.{pin}")
            if key not in s.edges: s.used.add(key)
        return s.parts[name]

    def edge(s, name, x, y, entry):
        """a point off the board (a lead that leaves the plate): a wire to it is routed to the lattice node
        `entry` (a, b), then runs straight off to (x, y)"""
        key = ("edge", name)
        s.edges[key] = (x, y)
        s.entry[key] = tuple(entry)
        return key

    def keep_box(s, x0, y0, x1, y1, margin=1):
        """lattice nodes inside a pixel box (a body) are off limits to wire"""
        for a in range(0, 2 * s.cols - 1):
            for b in range(0, 2 * s.rows - 1):
                if (a + b) % 2: continue
                fx, fy = s.node_f((a, b))
                if x0 - margin - 1.5 <= fx <= x1 + margin + 1.5 and y0 - margin - 1.5 <= fy <= y1 + margin + 1.5:
                    s.keep.add((a, b))

    def keep_mask(s, m, grow=2):
        """lattice nodes within `grow` px of a painted body are off limits to wire"""
        from scipy import ndimage as ndi
        g = ndi.binary_dilation(m, iterations=grow) if grow else m
        H_, W_ = g.shape
        for a in range(0, 2 * s.cols - 1):
            for b in range(0, 2 * s.rows - 1):
                if (a + b) % 2: continue
                x, y = s.ox + 3 * a, s.oy + 3 * b
                if 0 <= x < W_ and 0 <= y < H_ and g[y, x]: s.keep.add((a, b))

    def keep_line(s, p0, p1, margin=1.0):
        """lattice nodes near a lead's line are off limits"""
        (x0, y0), (x1, y1) = p0, p1
        L = math.hypot(x1 - x0, y1 - y0) or 1.0
        for a in range(0, 2 * s.cols - 1):
            for b in range(0, 2 * s.rows - 1):
                if (a + b) % 2: continue
                fx, fy = s.node_f((a, b))
                t = max(0, min(1, ((fx - x0) * (x1 - x0) + (fy - y0) * (y1 - y0)) / (L * L)))
                dist = math.hypot(x0 + t * (x1 - x0) - fx, y0 + t * (y1 - y0) - fy)
                if dist < 1.5 + 0.5 + margin: s.keep.add((a, b))

    # ------------------------------------------------------------------ the router
    def _steps(s, n):
        a, b = n
        if a % 2 == 0:                                   # a hole: rows/columns of holes, diagonals to corners
            for da, db in ((2, 0), (-2, 0), (0, 2), (0, -2)): yield (a + da, b + db), (da, db)
            for da, db in ((1, 1), (1, -1), (-1, 1), (-1, -1)): yield (a + da, b + db), (da, db)
        else:                                            # a corner: channels, diagonals to holes
            for da, db in ((2, 0), (-2, 0), (0, 2), (0, -2)): yield (a + da, b + db), (da, db)
            for da, db in ((1, 1), (1, -1), (-1, 1), (-1, -1)): yield (a + da, b + db), (da, db)

    def _inside(s, n):
        a, b = n
        return 0 <= a <= 2 * (s.cols - 1) and 0 <= b <= 2 * (s.rows - 1)

    def _fine(s, n, d):
        """the fine points a step passes: an orthogonal step of 2 passes its midpoint"""
        a, b = n; da, db = d
        if abs(da) + abs(db) == 2 and (da == 0 or db == 0):
            return [(a + da // 2, b + db // 2)]
        return []

    def _can(s, frm, to, d, start, goal, wi):
        if not s._inside(to): return False
        if to in s.keep and to not in (start, goal): return False
        if (frm, to) in s.keep_seg or (to, frm) in s.keep_seg: return False
        a, b = to
        if a % 2 == 0 and to != goal and to != start and (a // 2, b // 2) in s.used:
            return False                                 # over a soldered hole: never
        axis = "h" if d[1] == 0 else ("v" if d[0] == 0 else None)
        ends_here = to == goal and to[0] % 2 == 0          # wires may share the hole they're soldered in
        for f in s._fine(frm, d) + ([] if ends_here else [to]):
            for (wj, ax) in s.occ.get(f, []):
                if wj == wi: return False
                if axis is None or ax is None or ax == axis: return False
        if axis is None:                                 # a diagonal: one per square, crossings allowed
            sq = (min(frm[0], to[0]), min(frm[1], to[1]))
            slope = d[0] * d[1]
            for (wj, sl) in s.diag.get(sq, []):
                if sl == slope or wj == wi: return False
        # a channel step (corner to corner) passes between two holes: both must be free
        if frm[0] % 2 == 1 and axis is not None:
            mid = (frm[0] + d[0] // 2, frm[1] + d[1] // 2)
            if axis == "h": side = [(mid[0], mid[1] - 1), (mid[0], mid[1] + 1)]
            else: side = [(mid[0] - 1, mid[1]), (mid[0] + 1, mid[1])]
            for h in side:
                if h in (start, goal): continue
                if (h[0] // 2, h[1] // 2) in s.used: return False
        return True

    def route(s, start, goal, wi, bend=2.5, diag_bend=1.0, cross=4.0, avoid=None):
        """A* from hole to hole over the lattice; returns the node list"""
        def hcost(n):
            fx, fy = s.node_f(n); gx, gy = s.node_f(goal)
            return math.hypot(gx - fx, gy - fy)
        openq = [(hcost(start), 0.0, start, None)]
        best = {(start, None): 0.0}
        came = {}
        while openq:
            f, g, n, d = heapq.heappop(openq)
            if n == goal:
                path = [n]; k = (n, d)
                while k in came:
                    k = came[k]; path.append(k[0])
                return path[::-1]
            if g > best.get((n, d), 1e18): continue
            crossing = n != start and any(wj != wi for (wj, _) in s.occ.get(n, []))
            for to, dd in s._steps(n):
                if crossing and dd != d: continue
                if not s._can(n, to, dd, start, goal, wi): continue
                fx, fy = s.node_f(n); tx, ty = s.node_f(to)
                c = math.hypot(tx - fx, ty - fy)
                if d is not None and dd != d:
                    turn = abs(math.atan2(dd[1], dd[0]) - math.atan2(d[1], d[0]))
                    turn = min(turn, 2 * math.pi - turn)
                    if turn > math.pi * 0.76: continue   # no hairpins
                    c += diag_bend if turn < math.pi * 0.3 else bend
                axis = "h" if dd[1] == 0 else ("v" if dd[0] == 0 else None)
                if any(s.occ.get(fp) for fp in s._fine(n, dd) + [to]): c += cross
                if axis is None:
                    sq = (min(n[0], to[0]), min(n[1], to[1]))
                    if s.diag.get(sq): c += cross
                if avoid and to in avoid: c += avoid[to]
                ng = g + c
                key = (to, dd)
                if ng < best.get(key, 1e18):
                    best[key] = ng; came[key] = (n, d)
                    heapq.heappush(openq, (ng + hcost(to), ng, to, dd))
        return None

    def _claim(s, nodes, wi):
        for n0, n1 in zip(nodes, nodes[1:]):
            d = (n1[0] - n0[0], n1[1] - n0[1])
            axis = "h" if d[1] == 0 else ("v" if d[0] == 0 else None)
            for f in s._fine(n0, d):
                s.occ.setdefault(f, []).append((wi, axis))
            if axis is None:
                sq = (min(n0[0], n1[0]), min(n0[1], n1[1]))
                s.diag.setdefault(sq, []).append((wi, d[0] * d[1]))
        for k, n in enumerate(nodes):
            ax = None
            if 0 < k < len(nodes) - 1:
                d0 = (n[0] - nodes[k - 1][0], n[1] - nodes[k - 1][1])
                d1 = (nodes[k + 1][0] - n[0], nodes[k + 1][1] - n[1])
                if d0 == d1 and (d0[0] == 0 or d0[1] == 0) and n[0] % 2 == 0 and (n[0] // 2, n[1] // 2) not in s.used:
                    ax = "h" if d0[1] == 0 else "v"
            s.occ.setdefault(n, []).append((wi, ax))

    def wire(s, color, *holes, path=None, bare=False, via=None, **kw):
        """an insulated wire from hole to hole (to hole ...), soldered at each; routed unless `path` (lattice nodes)
        is given. `via`: lattice nodes the route must pass, between the first two holes."""
        wi = len(s.wires)
        keys = list(holes)
        nodes = []
        if path is not None:
            nodes = [tuple(n) for n in path]
        else:
            for k0, k1 in zip(keys, keys[1:]):
                n0 = s.entry[k0] if k0 in s.edges else (2 * k0[0], 2 * k0[1])
                n1 = s.entry[k1] if k1 in s.edges else (2 * k1[0], 2 * k1[1])
                seg_targets = [n0] + [tuple(v) for v in (via or [])] + [n1] if not nodes else [n0, n1]
                part = []
                for t0, t1 in zip(seg_targets, seg_targets[1:]):
                    r = s.route(t0, t1, wi, **kw)
                    if r is None:
                        msg = f"no route for the {color} wire from {k0} to {k1} (leg {t0}->{t1})"
                        if s.soft: s.failed.append(msg); return None
                        raise RuntimeError(msg)
                    part = part + (r if not part else r[1:])
                nodes = nodes + (part if not nodes else part[1:])
                via = None
        for k in keys:
            if k not in s.edges: s.used.add(k)
        s._claim(nodes, wi)
        s.wires.append(dict(color=color, nodes=nodes, taps=keys, bare=bare))
        return wi

    def wire_off(s, color, hole, edge_key, path_px):
        """a wire from a hole off the edge of the plate along pixel points (no routing: it leaves the board)"""
        wi = len(s.wires)
        s.used.add(hole)
        s.wires.append(dict(color=color, nodes=None, px=path_px, taps=[hole, edge_key], bare=False))
        return wi

    def bridge(s, k0, k1):
        assert abs(k0[0] - k1[0]) + abs(k0[1] - k1[1]) == 1, f"a bridge joins neighbours only: {k0} {k1}"
        s.bridges.append((k0, k1)); s.used.add(k0); s.used.add(k1)
        n0, n1 = (2 * k0[0], 2 * k0[1]), (2 * k1[0], 2 * k1[1])
        s.keep.add(((n0[0] + n1[0]) // 2, (n0[1] + n1[1]) // 2))

    # ------------------------------------------------------------------ the checker, as recorded
    def nets(s):
        parent = {}

        def find(x):
            parent.setdefault(x, x)
            while parent[x] != x:
                parent[x] = parent[parent[x]]; x = parent[x]
            return x

        def union(x, y): parent[find(x)] = find(y)
        for w in s.wires:
            t = w["taps"]
            for k in t[1:]: union(t[0], k)
        for k0, k1 in s.bridges: union(k0, k1)
        groups = defaultdict(set)
        for key, pins in s.pins_at.items():
            for pn in pins: groups[find(key)].add(pn)
        return [g for g in groups.values()]

    def check_nets(s, netlist, open_=()):
        """the wiring as recorded against the circuit: returns a list of problems"""
        errs = []
        got = s.nets()
        want = {frozenset(v): k for k, v in netlist.items()}
        pin_net = {pn: n for n, pins in netlist.items() for pn in pins}
        seen = set()
        for g in got:
            fg = frozenset(g)
            names = {pin_net.get(pn, "(open)" if pn in open_ else "(unknown)") for pn in g}
            if len(names) > 1:
                errs.append(f"short: {sorted(names)} joined by {sorted(g)}")
                continue
            n = names.pop()
            if n in ("(open)",):
                if len(g) > 1: errs.append(f"open pin joined: {sorted(g)}")
                continue
            if n == "(unknown)": errs.append(f"pins not in the circuit: {sorted(g)}"); continue
            if fg != frozenset(netlist[n]):
                missing = sorted(set(netlist[n]) - g)
                errs.append(f"net {n} split: this group {sorted(g)} lacks {missing}")
            seen.add(n)
        for n in netlist:
            if n not in seen and not any(set(netlist[n]) <= g for g in got):
                errs.append(f"net {n} not wired")
        placed = {pn for g in got for pn in g}
        for pins in netlist.values():
            for pn in pins:
                if pn not in placed: errs.append(f"{pn} is not on the board")
        return errs

    # ------------------------------------------------------------------ painting
    def paint_board(s, x, y, w, h, mat="perf", r=2):
        d = s.d
        body = Mask(d.W, d.H).rrect(x, y, w, h, r).get()
        d.slab(body, Z_FACE, mat, bevel=1.2, polish=0.35)
        d.grain_pebble(body, 0.02, seed=17)
        s.board_mask = body
        # the holes: one dark pixel each
        s.hole_px = []
        for i in range(s.cols):
            for j in range(s.rows):
                hx_, hy = s.px((i, j))
                if body[hy, hx_]:
                    d.seam(rbox(d, hx_, hy, 1, 1), 0.55)
                    s.hole_px.append((hx_, hy))
        s.board_mat = d.mid(mat)
        return body

    def cover_holes(s):
        """a hole is a dark pixel on bare board only: wherever a part, lead, wire, joint, label or the display board
        lies over one, take its darkening away (the engine keeps darkening under later layers)"""
        d = s.d
        for (x, y) in s.hole_px:
            if d.mat[y, x] != s.board_mat:
                d.dark[y, x] = 0.0

    def _lead(s, name, p0, p1, w=1):
        d = s.d
        m = Mask(d.W, d.H).line([p0, p1], w, caps=False).get(0.45)
        d.slab(m, 0.5, "tin", bevel=0.5, polish=1.0, on="h")
        s.masks["lead"].setdefault(name, np.zeros_like(m))
        s.masks["lead"][name] |= m
        return m

    def _body(s, name, m):
        s.masks["body"][name] = s.masks["body"].get(name, np.zeros_like(m)) | m

    def paint_wires(s):
        d = s.d
        for wi, w in enumerate(s.wires):
            if w.get("nodes"):
                pts = [s.node_f(n) for n in w["nodes"]]
                if w["taps"][0] in s.edges: pts = [s.fc(w["taps"][0])] + pts
                if w["taps"][-1] in s.edges: pts = pts + [s.fc(w["taps"][-1])]
            else:
                pts = [(x + 0.5, y + 0.5) for (x, y) in w["px"]]
                k0 = w["taps"][0]
                pts = [s.fc(k0)] + pts
            if w["bare"]:
                m = Mask(d.W, d.H).line(pts, 1, caps=False).get(0.45)
                d.slab(m, 0.6, "tin", bevel=0.5, polish=1.0, on="h")
            else:
                m = Mask(d.W, d.H).line(pts, LW).get(0.5)
                if not w.get("nodes"):
                    m &= s.d.solid | True
                prev = d.h.copy()
                d.slab(m, WIRE_Z, WIRE[w["color"]], bevel=1.4, polish=0.55, on="h", power=0.6)
                # where it lies over an earlier wire, it rides up over it
                del prev
            s.masks["wire"][wi] = m

    def paint_joints(s):
        d = s.d
        for k0, k1 in s.bridges:
            (x0, y0), (x1, y1) = s.fc(k0), s.fc(k1)
            m = Mask(d.W, d.H).line([(x0, y0), (x1, y1)], 2.2).get(0.5)
            d.slab(m, 0.8, "solder", bevel=0.9, polish=1.0, on=Z_FACE + 0.2)
            s.masks["bridge"][(k0, k1)] = m
        for key in sorted(s.used | s.extra_joints, key=lambda k: (str(type(k[0])), k)):
            if key in s.edges: continue
            x, y = s.px(key)
            m = np.zeros((d.H, d.W), bool)
            m[y - 1:y + 2, x - 1:x + 2] = True
            base = float(d.h[y, x])
            d.dome(x + 0.5, y + 0.5, 1.75, 1.75, 0.9, "solder", polish=1.0, on=max(base, Z_FACE + 0.3))
            s.masks["joint"][key] = m

    # ------------------------------------------------------------------ the checker, as painted
    def check_paint(s):
        """touch tests over the painted masks; returns problems"""
        errs = []
        J = s.masks["joint"]
        H, W = s.d.H, s.d.W

        def grow(m):
            g = m.copy()
            g[1:, :] |= m[:-1, :]; g[:-1, :] |= m[1:, :]; g[:, 1:] |= m[:, :-1]; g[:, :-1] |= m[:, 1:]
            return g
        jg = {k: grow(m) for k, m in J.items()}
        # wires touch only their own joints
        for wi, m in s.masks["wire"].items():
            w = s.wires[wi]
            own = {k for k in w["taps"] if k not in s.edges}
            for k, g in jg.items():
                if (g & m).any() and k not in own:
                    errs.append(f"the {w['color']} wire {w['taps'][0]}->{w['taps'][-1]} touches the joint at {k} ({s.pins_at.get(k, [])})")
            for k in own:
                if k in J and not (jg[k] & m).any():
                    errs.append(f"the {w['color']} wire misses its joint at {k}")
            for name, b in s.masks["body"].items():
                if s.parts.get(name, {}).get("kind") == "ribbon": continue      # a cable may lie over wire
                if (b & m).any():
                    errs.append(f"the {w['color']} wire {w['taps'][0]}->{w['taps'][-1]} runs over {name}")
        # leads touch only their own joints; bodies cover nothing that isn't theirs
        pin_keys = {}
        for name, part in s.parts.items():
            pin_keys[name] = {k for k in part["pins"].values()} | s.support.get(name, set())
        for name, m in s.masks["lead"].items():
            for k, g in jg.items():
                if (g & m).any() and k not in pin_keys.get(name, set()):
                    errs.append(f"a lead of {name} touches the joint at {k} ({s.pins_at.get(k, [])})")
        for name, b in s.masks["body"].items():
            for k, m in J.items():
                if (b & m).any() and k not in pin_keys.get(name, set()) and k not in s.covered:
                    errs.append(f"{name}'s body covers the joint at {k}")
        names = list(s.masks["body"])
        for i, a in enumerate(names):
            for b_ in names[i + 1:]:
                if (s.masks["body"][a] & s.masks["body"][b_]).any():
                    errs.append(f"{a} and {b_} overlap")
        # bridges touch only their two joints
        for (k0, k1), m in s.masks["bridge"].items():
            for k, g in jg.items():
                if k in (k0, k1): continue
                if (g & m).any(): errs.append(f"the bridge {k0}-{k1} touches the joint at {k}")
        # joints of different holes never touch
        keys = list(J)
        for i, a in enumerate(keys):
            for b_ in keys[i + 1:]:
                if abs(a[0] - b_[0]) <= 1 and abs(a[1] - b_[1]) <= 1 and (jg[a] & J[b_]).any():
                    if (a, b_) not in s.bridges and (b_, a) not in s.bridges:
                        errs.append(f"joints {a} and {b_} touch")
        return errs


# ====================================================================== parts
def _axis(p0, p1):
    (x0, y0), (x1, y1) = p0, p1
    L = math.hypot(x1 - x0, y1 - y0)
    return (x1 - x0) / L, (y1 - y0) / L, L


def two_lead(B, name, k0, k1, style, value="", body_len=None, body_w=None, pins=("1", "2"), color=None, bands=None):
    """a two-lead part lying between two holes: its body centred between them, a lead to each hole"""
    d = B.d
    p0, p1 = B.fc(k0), B.fc(k1)
    ux, uy, L = _axis(p0, p1)
    cx, cy = (p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2
    S = {  # style: (length, width, height, material)
        "disc": (6.0, 4.0, 2.6, "disc"), "disc_b": (5.0, 4.0, 2.4, "disc_b"), "film": (10.0, 5.0, 3.0, "film_r"),
        "green": (9.0, 5.0, 2.6, "film_g"), "res": (12.0, 5.0, 2.4, "resistor"), "coil": (8.0, 6.0, 2.6, "copper"),
        "xtal": (16.0, 7.0, 2.4, "chrome"),
    }[style]
    bl = body_len or S[0]; bw = body_w or S[1]; z = S[2]; mat = color or S[3]
    a0 = (cx - ux * bl / 2, cy - uy * bl / 2); a1 = (cx + ux * bl / 2, cy + uy * bl / 2)
    assert L - bl >= 3.0, f"{name}: its body ({bl} px) leaves no lead between holes {L:.1f} px apart"
    for (p, e) in ((p0, a0), (p1, a1)):
        B._lead(name, p, e)
        B.keep_line(p, e, margin=0.5)
    # the body: a rounded slab along the axis
    nx, ny = -uy, ux
    if style in ("res",):
        pts = [(a0[0] + nx * bw / 2, a0[1] + ny * bw / 2), (a1[0] + nx * bw / 2, a1[1] + ny * bw / 2),
               (a1[0] - nx * bw / 2, a1[1] - ny * bw / 2), (a0[0] - nx * bw / 2, a0[1] - ny * bw / 2)]
        m = Mask(d.W, d.H).poly(pts).get(0.5)
        # a resistor is a round bar along its axis: a cylinder profile across it
        X, Y = d.XX + 0.5 - cx, d.YY + 0.5 - cy
        across = (X * nx + Y * ny) / (bw / 2)
        prof = np.sqrt(np.clip(1 - across ** 2, 0, 1)) * z
        along = np.abs(X * ux + Y * uy)
        prof = prof * np.clip((bl / 2 - along) / 1.2 + 0.6, 0.6, 1.0)
        d.h = np.where(m, Z_FACE + prof, d.h).astype(np.float32)
        d.mat[m] = d.mid(mat); d.solid |= m; d.polish[m] = 0.5; d.tex[m] = 0
        if bands:
            n = len(bands)
            for bi, bm in enumerate(bands):
                t = -bl / 2 + 2.2 + bi * ((bl - 4.4) / max(1, n - 1)) if bi < n - 1 else bl / 2 - 2.2
                if bi == n - 1: t = bl / 2 - 2.0
                bx, by = cx + ux * t, cy + uy * t
                band = Mask(d.W, d.H).line([(bx - nx * bw, by - ny * bw), (bx + nx * bw, by + ny * bw)], 1.0, caps=False).get(0.45) & m
                d.paint(band, bm)
    elif style == "coil":
        pts = [(a0[0] + nx * bw / 2, a0[1] + ny * bw / 2), (a1[0] + nx * bw / 2, a1[1] + ny * bw / 2),
               (a1[0] - nx * bw / 2, a1[1] - ny * bw / 2), (a0[0] - nx * bw / 2, a0[1] - ny * bw / 2)]
        m = Mask(d.W, d.H).poly(pts).get(0.5)
        X, Y = d.XX + 0.5 - cx, d.YY + 0.5 - cy
        along = X * ux + Y * uy
        across = (X * nx + Y * ny) / (bw / 2)
        turns = 0.5 + 0.5 * np.cos(along * 2 * math.pi / 2.0)
        prof = np.sqrt(np.clip(1 - across ** 2, 0, 1)) * z * (0.75 + 0.25 * turns)
        d.h = np.where(m, Z_FACE + prof, d.h).astype(np.float32)
        d.mat[m] = d.mid(mat); d.solid |= m; d.polish[m] = 0.9; d.tex[m] = 0
        gaps = m & (turns < 0.2)
        d.seam(gaps, 0.35)
    else:
        r = 1.6 if style in ("disc", "disc_b") else 0.8
        pts = [(a0[0] + nx * bw / 2, a0[1] + ny * bw / 2), (a1[0] + nx * bw / 2, a1[1] + ny * bw / 2),
               (a1[0] - nx * bw / 2, a1[1] - ny * bw / 2), (a0[0] - nx * bw / 2, a0[1] - ny * bw / 2)]
        m = Mask(d.W, d.H).poly(pts).get(0.5)
        d.slab(m, z, mat, bevel=r if style in ("disc", "disc_b") else 1.2, polish=0.6 if style != "xtal" else 1.0, on=Z_FACE)
    B._body(name, m)
    B.keep_mask(m, 2)
    B.add_part(name, style, {pins[0]: k0, pins[1]: k1}, value=value)
    return m


def resistor(B, name, k0, k1, value):
    return two_lead(B, name, k0, k1, "res", value, bands=res_bands(value))


def dip(B, name, k1, n, along=(1, 0), across=(0, -1), label="", rows_apart=3):
    """a DIP chip: pin 1 in hole k1, pins 1..n/2 stepping `along`, the other row `rows_apart` holes `across`"""
    d = B.d
    half = n // 2
    pins = {}
    for k in range(1, n + 1):
        if k <= half:
            i, j = k1[0] + along[0] * (k - 1), k1[1] + along[1] * (k - 1)
        else:
            i = k1[0] + across[0] * rows_apart + along[0] * (n - k)
            j = k1[1] + across[1] * rows_apart + along[1] * (n - k)
        pins[str(k)] = (i, j)
    xs = [B.px(k)[0] for k in pins.values()]; ys = [B.px(k)[1] for k in pins.values()]
    x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
    horiz = along[1] == 0
    # the body: inset 3 px from the pin rows, 2 px past the end pins
    if horiz:
        bx0, bx1, by0, by1 = x0 - 3, x1 + 4, y0 + 3, y1 - 2
    else:
        bx0, bx1, by0, by1 = x0 + 3, x1 - 2, y0 - 3, y1 + 4
    body = rbox(d, bx0, by0, bx1 - bx0, by1 - by0)
    d.slab(body, 2.0, "blackp", bevel=0.9, polish=0.55, on=Z_FACE)
    # the legs: from the body's edge to each hole
    for k, key in pins.items():
        px, py = B.px(key)
        if horiz:
            e = (px + 0.5, by0 - 0.0) if py < by0 else (px + 0.5, by1 + 0.0)
        else:
            e = (bx0 - 0.0, py + 0.5) if px < bx0 else (bx1 + 0.0, py + 0.5)
        lm = Mask(d.W, d.H).line([B.fc(key), e], 1.0, caps=False).get(0.45)
        d.slab(lm, 0.8, "tin", bevel=0.5, polish=1.0, on=Z_FACE)
        B.masks["lead"].setdefault(name, np.zeros_like(lm))
        B.masks["lead"][name] |= lm & ~body
    # the notch at pin 1's end, the pin-1 dot, the print
    p1x, p1y = B.px(k1)
    if horiz:
        nxp = bx0 if along[0] > 0 else bx1 - 1
        ny_ = (by0 + by1) // 2
        d.well(disc(d, nxp + 0.5, ny_, 1.6) & body, 0.8)
        d.well(disc(d, p1x + 0.5 + along[0] * 1, (by1 - 2.5) if p1y > by1 else (by0 + 2.5), 0.8) & body, 0.4)
        if label:
            tw = text_w(label)
            d.text(label, (bx0 + bx1) // 2 - tw // 2 + 1, ny_ - 2, "paint_c", flatlight=True)
    else:
        nyp = by0 if along[1] > 0 else by1 - 1
        nx_ = (bx0 + bx1) // 2
        d.well(disc(d, nx_, nyp + 0.5, 1.6) & body, 0.8)
        if label:
            for ci, ch in enumerate(label):
                d.text(ch, nx_ - 1, (by0 + by1) // 2 - len(label) * 3 + ci * 6, "paint_c", flatlight=True)
    B._body(name, body)
    B.keep_mask(body, 2)
    for key in pins.values():
        x, y = B.px(key)
        B.keep_line((x + 0.5, y + 0.5), (x + 0.5, y + 0.5), margin=0)
    B.add_part(name, "dip", pins, value=label)
    return pins


# ---------------------------------------------------------------------- more parts
def can(B, name, k_plus, k_minus, D=13.0, sleeve="elec_k"):
    """a radial electrolytic standing on the board, its two leads splayed out to holes either side of the can;
    the sleeve's light stripe faces the minus lead"""
    d = B.d
    p0, p1 = B.fc(k_plus), B.fc(k_minus)
    ux, uy, L = _axis(p0, p1)
    cx, cy = (p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2
    r = D / 2
    assert L - D >= 4.0, f"{name}: holes {L:.1f} px apart leave no lead either side of a {D} px can"
    for p, sgn in ((p0, -1), (p1, 1)):
        e = (cx + sgn * ux * (r - 0.5), cy + sgn * uy * (r - 0.5))
        B._lead(name, p, e)
        B.keep_line(p, e, margin=0.5)
    m = disc(d, cx, cy, r)
    d.slab(m, 5.0, sleeve, bevel=1.7, polish=0.55, on=Z_FACE)
    X, Y = d.XX + 0.5 - cx, d.YY + 0.5 - cy
    top = disc(d, cx, cy, r - 1.8)
    d.paint(top, "alu", polish=0.9)
    # the vent: a scored cross in the aluminium end
    for ang in (0.0, math.pi / 2):
        vx, vy = math.cos(ang), math.sin(ang)
        line = Mask(d.W, d.H).line([(cx - vx * (r - 3), cy - vy * (r - 3)), (cx + vx * (r - 3), cy + vy * (r - 3))], 0.9, caps=False).get(0.5)
        d.seam(line & top, 0.35)
    stripe = m & ~top & ((X * ux + Y * uy) > r * 0.25)
    d.paint(stripe, "band_e")
    B._body(name, m)
    B.keep_mask(m, 2)
    B.add_part(name, "ecap", {"+": k_plus, "-": k_minus})
    return m


def tabs(B, name, pts_keys, w=2.0):
    """solder tabs from a body's edge (pixel points) to holes"""
    d = B.d
    for (e, key) in pts_keys:
        m = Mask(d.W, d.H).line([B.fc(key), e], w, caps=False).get(0.5)
        d.slab(m, 0.7, "tin", bevel=0.6, polish=1.0, on=Z_FACE)
        B.masks["lead"].setdefault(name, np.zeros_like(m))
        B.masks["lead"][name] |= m
        B.keep_line(B.fc(key), e, margin=0.5)


def pot(B, name, cx, cy, r_can, lugs, knob_r, pid, ptr=True):
    """a volume control: a round steel can with three solder lugs down to holes (top, wiper, bottom), the knob on
    its shaft; the knob's pointer and the click area are the plate's (as before)"""
    from physlib import fluted_knob
    d = B.d
    p = B.p
    can_m = disc(d, cx, cy, r_can)
    d.slab(can_m, 2.2, "steel", bevel=1.3, polish=0.6, on=Z_FACE)
    d.grain_brushed(can_m, 0.04, seed=int(cx))
    edge_pts = []
    for key in lugs:
        kx, ky = B.fc(key)
        ang = math.atan2(ky - cy, kx - cx)
        edge_pts.append(((cx + math.cos(ang) * (r_can - 1), cy + math.sin(ang) * (r_can - 1)), key))
    tabs(B, name, edge_pts, w=2.0)
    fluted_knob(p, cx, cy, knob_r, on=Z_FACE + 2.2, z=4.0, mat="blackp", skirt=None, ridges=22, dome=0.6, check=False)
    if ptr:
        if pid == "vol":
            p.part("ptr", src="volF", cx=cx, cy=cy, r0=knob_r * 0.3, r1=knob_r * 0.8, a0=-225, a1=45, color="#e8e8e8", w=1)
        else:
            p.part("ptr", src="tuneF", cx=cx, cy=cy, r0=knob_r * 0.3, r1=knob_r * 0.8, a0=-90, a1=270, color="#e8e8e8", w=1)
    p.hit(pid, cx - knob_r, cy - knob_r, 2 * knob_r, 2 * knob_r, kind="turn")
    B._body(name, can_m)
    B.keep_mask(can_m, 2)
    B.add_part(name, "pot", {"1": lugs[0], "2": lugs[1], "3": lugs[2]})
    return can_m


def polyvaricon(B, name, cx, cy, size, pins, support, knob_r, pid):
    """a pocket radio's tuning capacitor: a square white plastic body with its two trimmers, solder tabs off its
    top edge to holes (`pins` {pin: hole} wired, `support` holes soldered only to hold it), the knob on its shaft"""
    from physlib import fluted_knob
    d = B.d
    p = B.p
    x0, y0 = cx - size / 2, cy - size / 2
    body = Mask(d.W, d.H).rrect(x0, y0, size, size, 2).get()
    d.slab(body, 3.4, "poly", bevel=1.5, polish=0.45, on=Z_FACE)
    # the two trimmer screws in the corners, the moulded ribs
    for (tx, ty) in ((x0 + 5, y0 + size - 5), (x0 + size - 5, y0 + size - 5)):
        d.dome(tx, ty, 2.4, 2.4, 0.8, "poly", polish=0.6, on=Z_FACE + 3.4)
        d.seam(rbox(d, int(tx - 1), int(ty), 3, 1), 0.4)
    for k in (3, size - 4):
        d.seam(rbox(d, int(x0 + 3), int(y0 + k), int(size - 6), 1) & body, 0.12)
    edge = []
    for key in list(pins.values()) + list(support):
        kx, ky = B.fc(key)
        ex = min(max(kx, x0 + 2), x0 + size - 2)
        ey = y0 + 1 if ky < y0 else (y0 + size - 1 if ky > y0 + size else ky)
        edge.append(((ex, ey), key))
    tabs(B, name, edge, w=2.0)
    for key in support:
        B.support[name].add(key); B.extra_joints.add(key); B.used.add(key)
    fluted_knob(p, cx, cy, knob_r, on=Z_FACE + 3.4, z=4.0, mat="blackp", skirt=None, ridges=22, dome=0.6, check=False)
    p.part("ptr", src="tuneF", cx=cx, cy=cy, r0=knob_r * 0.3, r1=knob_r * 0.8, a0=-90, a1=270, color="#e8e8e8", w=1)
    p.hit(pid, cx - knob_r, cy - knob_r, 2 * knob_r, 2 * knob_r, kind="turn")
    B._body(name, body)
    B.keep_mask(body, 2)
    B.add_part(name, "varcap", dict(pins))
    return body


def tape(p, x, y, w, h, text=None, ink="paint_k", angle_px=0):
    """a strip of masking tape on the board, a word on it in marker"""
    d = p.d
    m = Mask(d.W, d.H).poly([(x, y + angle_px), (x + w, y), (x + w, y + h), (x, y + h + angle_px)]).get()
    # tape bridges the board's holes (each a one-pixel dip): lift the ground under it to its neighbours' height first,
    # or every hole shows through the tape as a little shadow
    hp = np.pad(d.h, 1, mode="edge")
    near = np.max([hp[1 + dy:1 + dy + d.H, 1 + dx:1 + dx + d.W] for dy in (-1, 0, 1) for dx in (-1, 0, 1)], axis=0)
    d.h = np.where(m, np.maximum(d.h, near), d.h).astype(np.float32)
    d.slab(m, 0.4, "tape", bevel=0.4, polish=0.2, on="h")
    if text:
        p.label(text, int(x + w / 2), int(y + (h - 5) / 2 + angle_px / 2 + 0.5), ink, align="c", check=False, auto_ink=False)
    return m


def ribbon(B, name, p0, p1, n, ends):
    """a flat cable of n conductors (3 px each, the first one's red stripe) from p0 (off the display board) to p1,
    where conductors fan out to holes: ends {pin: (conductor index, hole)}; the rest are cut short"""
    d = B.d
    ux, uy, L = _axis(p0, p1)
    nx, ny = -uy, ux
    W_ = 3.0 * n
    pts = [(p0[0] + nx * W_ / 2, p0[1] + ny * W_ / 2), (p1[0] + nx * W_ / 2, p1[1] + ny * W_ / 2),
           (p1[0] - nx * W_ / 2, p1[1] - ny * W_ / 2), (p0[0] - nx * W_ / 2, p0[1] - ny * W_ / 2)]
    m = Mask(d.W, d.H).poly(pts).get(0.5)
    X, Y = d.XX + 0.5 - p0[0], d.YY + 0.5 - p0[1]
    across = X * nx + Y * ny + W_ / 2                   # 0 .. W_ across the cable
    ridge = 0.5 + 0.5 * np.cos((across % 3.0 - 1.5) / 1.5 * math.pi)
    prof = 0.9 + 0.5 * ridge
    d.h = np.where(m, d.h + prof, d.h).astype(np.float32)
    d.mat[m] = d.mid("ribbon"); d.solid |= m; d.polish[m] = 0.4; d.tex[m] = 0
    d.paint(m & (across < 3.0), "w_red")
    d.seam(m & (np.abs(across % 3.0) < 0.5) & (across > 1), 0.18)
    pins = {}
    for pin, (ci, key) in ends.items():
        off = -W_ / 2 + 1.5 + 3.0 * ci
        e = (p1[0] + nx * off, p1[1] + ny * off)
        lm = Mask(d.W, d.H).line([e, B.fc(key)], 2.6).get(0.5)
        d.slab(lm, 1.0, "w_red" if ci == 0 else "ribbon", bevel=1.0, polish=0.4, on="h")
        B.masks["lead"].setdefault(name, np.zeros_like(lm))
        B.masks["lead"][name] |= lm
        B.keep_line(e, B.fc(key), margin=0.5)
        pins[pin] = key
    B._body(name, m)
    B.add_part(name, "ribbon", pins)
    return m


def ribbon_paint(B, name, p0, p1, n, ends):
    """paint a ribbon registered earlier with add_part: a flat cable of n conductors from p0 to p1, the conductors
    in `ends` {pin: (index, hole)} carried on to their holes, the others cut short; the joints are soldered over"""
    from physlib import Z_FACE
    d = B.d
    ux, uy, L = _axis(p0, p1)
    nx, ny = -uy, ux
    W_ = 3.0 * n
    pts = [(p0[0] + nx * W_ / 2, p0[1] + ny * W_ / 2), (p1[0] + nx * W_ / 2, p1[1] + ny * W_ / 2),
           (p1[0] - nx * W_ / 2, p1[1] - ny * W_ / 2), (p0[0] - nx * W_ / 2, p0[1] - ny * W_ / 2)]
    m = Mask(d.W, d.H).poly(pts).get(0.5)
    X, Y = d.XX + 0.5 - p0[0], d.YY + 0.5 - p0[1]
    across = X * nx + Y * ny + W_ / 2
    ridge = 0.5 + 0.5 * np.cos((np.mod(across, 3.0) - 1.5) / 1.5 * math.pi)
    prof = 0.9 + 0.5 * ridge
    d.h = np.where(m, d.h + prof, d.h).astype(np.float32)
    d.mat[m] = d.mid("ribbon"); d.solid |= m; d.polish[m] = 0.4; d.tex[m] = 0
    d.paint(m & (across < 3.0), "w_red")
    d.seam(m & (np.mod(across, 3.0) < 0.6) & (across > 1), 0.18)
    tails = np.zeros_like(m)
    for pin, (ci, key) in ends.items():
        off = -W_ / 2 + 1.5 + 3.0 * ci
        e = (p1[0] + nx * off, p1[1] + ny * off)
        hx_, hy = B.fc(key)
        lm = Mask(d.W, d.H).line([e, (hx_, hy)], 2.6).get(0.5)
        d.slab(lm, 1.0, "w_red" if ci == 0 else "ribbon", bevel=1.0, polish=0.4, on="h")
        tails |= lm
    for pin, (ci, key) in ends.items():
        x, y = B.px(key)
        d.dome(x + 0.5, y + 0.5, 1.75, 1.75, 0.9, "solder", polish=1.0, on=float(d.h[y, x]))
    B.masks["lead"][name] = tails & ~np.zeros_like(m)
    B.masks["body"][name] = m
    return m


def to92(B, name, holes, side=-1, pins=("C", "B", "E")):
    """a TO-92 transistor: three holes in a row; the D-shaped body stands off to one side (side +1/-1 across the
    row), flat face toward the holes, its three legs bent down into them"""
    d = B.d
    pts = [B.fc(k) for k in holes]
    (x0, y0), (x2, y2) = pts[0], pts[2]
    ux, uy, L = _axis(pts[0], pts[2])
    nx, ny = -uy * side, ux * side
    mx, my = pts[1]
    cx, cy = mx + nx * 8.5, my + ny * 8.5
    X, Y = d.XX + 0.5 - cx, d.YY + 0.5 - cy
    rr = np.hypot(X, Y)
    toward = -(X * nx + Y * ny)                      # distance toward the holes from the body's centre
    body = (rr <= 5.6) & (toward <= 2.4)
    d.slab(body, 2.8, "blackp", bevel=1.3, polish=0.55, on=Z_FACE)
    flat_d = 2.4
    for k, p_ in zip(holes, pts):
        along = (p_[0] - mx) * ux + (p_[1] - my) * uy
        e = (cx - nx * flat_d + ux * along * 0.55, cy - ny * flat_d + uy * along * 0.55)
        B._lead(name, p_, e)
        B.keep_line(p_, e, margin=0.5)
    B._body(name, body)
    B.keep_mask(body, 2)
    B.add_part(name, "npn", {pins[0]: holes[0], pins[1]: holes[1], pins[2]: holes[2]})
    return body


def slug_coil(B, name, cx, cy, can, pins, knob_r, pid):
    """the tuning coil under DIAL: a small aluminium can whose slug the knob turns; four tabs out from under the
    knob to holes. The knob's pointer and click area are the plate's, as before."""
    from physlib import fluted_knob
    d, p = B.d, B.p
    x0, y0 = cx - can / 2, cy - can / 2
    body = Mask(d.W, d.H).rrect(x0, y0, can, can, 1.5).get()
    d.slab(body, 3.0, "alu", bevel=1.0, polish=0.8, on=Z_FACE)
    edge = []
    for key in pins.values():
        kx, ky = B.fc(key)
        ang = math.atan2(ky - cy, kx - cx)
        edge.append(((cx + math.cos(ang) * can * 0.45, cy + math.sin(ang) * can * 0.45), key))
    tabs(B, name, edge, w=2.0)
    disc_m = disc(d, cx, cy, knob_r + 1.5)
    fluted_knob(p, cx, cy, knob_r, on=Z_FACE + 3.0, z=4.4, mat="blackp", skirt=None, ridges=30, dome=0.8, check=False)
    p.part("ptr", src="tuneF", cx=cx, cy=cy, r0=knob_r * 0.3, r1=knob_r * 0.8, a0=-90, a1=270, color="#e8e8e8", w=1)
    p.hit(pid, cx - knob_r, cy - knob_r, 2 * knob_r, 2 * knob_r, kind="turn")
    B._body(name, disc_m)
    B.keep_mask(disc_m, 2)
    B.add_part(name, "rfxfmr", dict(pins))
    return body


def xfmr(B, name, x0, y0, w, h, pins):
    """a small speaker transformer: a laminated iron core round a red bobbin, its four leads to holes"""
    d = B.d
    core = Mask(d.W, d.H).rect(x0, y0, w, h).get()
    d.slab(core, 4.0, "steel", bevel=0.9, polish=0.5, on=Z_FACE)
    for k in range(2, h - 1, 2):
        d.seam(rbox(d, x0 + 1, y0 + k, w - 2, 1) & core, 0.22)
    bob = Mask(d.W, d.H).rect(x0 + w * 0.3, y0 - 1, w * 0.4, h + 2).get()
    d.slab(bob, 4.6, "film_r", bevel=0.9, polish=0.4, on=Z_FACE)
    edge = []
    for key in pins.values():
        kx, ky = B.fc(key)
        if kx < x0 or kx > x0 + w:                       # a tab off a side
            ex = x0 + 0.5 if kx < x0 else x0 + w - 0.5
            ey = min(max(ky, y0 + 1.5), y0 + h - 1.5)
        else:
            ex = min(max(kx, x0 + 1.5), x0 + w - 1.5)
            ey = y0 + 0.5 if ky < y0 else y0 + h - 0.5
        edge.append(((ex, ey), key))
    tabs(B, name, edge, w=1.4)
    m = core | bob
    B._body(name, m)
    B.keep_mask(m, 2)
    B.add_part(name, "afxfmr", dict(pins))
    return m


LATCH = (2.6, -3.6, 3.6)       # a latching switch's cap over its box's top: out, latched in (down in the box, its rim's
                               # shadow round it); the depth of the gap round the cap


def latch4(B, name, x0, y0, w, h, pins, cap, live, label="MIC", cap_w=None):
    """a four-pole latching push switch: a black box, its cap (the plate's click area `cap` = (id, x, y, w, h); drawn
    `cap_w` wide when that is wider, centred on it, so its legend fits), solder lugs off its top and bottom edges to
    holes. Out, the cap stands proud of the box; `live` (latched in), it sits down in its well below the box's top"""
    d, p = B.d, B.p
    body = Mask(d.W, d.H).rrect(x0, y0, w, h, 1).get()
    d.slab(body, 3.4, "blackp", bevel=1.0, polish=0.5, on=Z_FACE)
    cid, cx, cy, cw, ch = cap
    dw = max(cw, cap_w or cw)
    dx = cx - (dw - cw) // 2
    well = Mask(d.W, d.H).rect(dx - 1, cy - 1, dw + 2, ch + 2).get()
    d.well(well, LATCH[2], "blackp", bevel=0.6)
    cm = Mask(d.W, d.H).rrect(dx, cy, dw, ch, 1).get()
    top = Z_FACE + 3.4 + (LATCH[1] if live else LATCH[0])
    d.slab(cm, top, "pad_panel", bevel=0.9, polish=0.55)
    if label:
        tw = text_w(label)
        d.text(label, int(dx + dw / 2 - tw / 2 + 0.5), int(cy + ch / 2 - 2), "paint_k", flatlight=True)
    p.hit(cid, cx, cy, cw, ch)
    edge = []
    for key in pins.values():
        kx, ky = B.fc(key)
        ey = y0 + 0.5 if ky < y0 else y0 + h - 0.5
        edge.append(((kx, ey), key))
    tabs(B, name, edge, w=1.6)
    B._body(name, body)
    B.keep_mask(body, 2)
    return body


def to92_tri(B, name, c, b, e, pins=("C", "B", "E")):
    """a TO-92 with its legs formed in a triangle, the usual way onto perforated board: collector and emitter in
    holes two apart, the base in the hole between them one row back toward the body, the body further back.
    `c`, `e`: holes in one row or column two apart; `b`: the hole midway, one row back."""
    d = B.d
    pc, pe, pb = B.fc(c), B.fc(e), B.fc(b)
    mx, my = (pc[0] + pe[0]) / 2, (pc[1] + pe[1]) / 2
    bx, by = pb[0] - mx, pb[1] - my
    L = math.hypot(bx, by); nx, ny = bx / L, by / L               # toward the body
    ux, uy, _ = _axis(pc, pe)
    cx, cy = mx + nx * 13.0, my + ny * 13.0
    X, Y = d.XX + 0.5 - cx, d.YY + 0.5 - cy
    rr = np.hypot(X, Y)
    toward = -(X * nx + Y * ny)
    body = (rr <= 5.6) & (toward <= 2.2)
    d.slab(body, 2.8, "blackp", bevel=1.3, polish=0.55, on=Z_FACE)
    face = (cx - nx * 2.2, cy - ny * 2.2)
    for key, p_, along in ((c, pc, -1), (b, pb, 0), (e, pe, 1)):
        sgn = 1 if (p_[0] - mx) * ux + (p_[1] - my) * uy > 0 else (-1 if (p_[0] - mx) * ux + (p_[1] - my) * uy < 0 else 0)
        f = (face[0] + ux * sgn * 2.6, face[1] + uy * sgn * 2.6)
        B._lead(name, p_, f)
        B.keep_line(p_, f, margin=0.5)
    B._body(name, body)
    B.keep_mask(body, 2)
    B.add_part(name, "npn", {pins[0]: c, pins[1]: b, pins[2]: e})
    return body
