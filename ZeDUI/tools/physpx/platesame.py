"""Proves the game draws every machine plate the way the previews show it: the real Lua (PixelFonts, ZeD_PixelParts,
ZeD_Plate, the exported PhysPx) runs under LuaJIT, its drawRect / drawTextureScaled calls are painted the way the
preview canvas paints, and the picture must equal preview.render_state's for the same exported data, pixel for pixel,
in every preview state of every plate (plus the extra states below), at 1x and 2x.
Without lupa the same Lua runs in a LuaJIT executable (the one the VS Code Lua debugger ships, or $LUAJIT) and its
draw calls come back over stdout.
usage: python platesame.py [plate id ...]"""
import math
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import export_phys as EX            # noqa: E402
import preview as PV                # noqa: E402
from plates import DESIGNS          # noqa: E402
try:
    import lupa.luajit21 as lj      # noqa: E402
except ImportError:
    lj = None                       # no lupa here: a LuaJIT executable runs the same (run_cli)

ROOT = os.path.join(HERE, "out", "mod", "ZeD-UI")          # the export lands here (the mod is left alone)
LUA_DIR = os.path.join(ROOT, "42", "media", "lua", "client", "ZeD")
# where the template and the atoms are (orgtest's rule: the mod's own in the repo, else a lua/ folder beside this)
_REPO = os.path.normpath(os.path.join(HERE, "..", "..", ".."))
if os.path.isdir(os.path.join(_REPO, "42", "media", "lua", "client", "ZeD")) and not os.path.isdir(os.path.join(HERE, "lua")):
    SRC = os.path.join(_REPO, "42", "media", "lua", "client", "ZeD")
else:
    SRC = os.path.join(HERE, "lua")

PRELUDE = r'''
-- Kahlua's strings are Java's (16-bit characters): string.char takes a code above 255 there, LuaJIT's does not, so
-- those go over as UTF-8 (the faces' accented and Cyrillic capitals, ZeD_PixelParts; dashpx/luatest.py does the same)
local char0 = string.char
string.char = function(...)
    local n = select("#", ...)
    local big = false
    for i = 1, n do if select(i, ...) > 255 then big = true end end
    if not big then return char0(...) end
    local out = {}
    for i = 1, n do
        local c = select(i, ...)
        if c < 128 then out[#out + 1] = char0(c)
        elseif c < 2048 then out[#out + 1] = char0(192 + math.floor(c / 64), 128 + c % 64)
        else out[#out + 1] = char0(224 + math.floor(c / 4096), 128 + math.floor(c / 64) % 64, 128 + c % 64) end
    end
    return table.concat(out)
end
Texture = { getSharedTexture = function(path, flags) return { path = path, flags = flags } end }
getTimestampMs = function() return 0 end
require = function() end
ZeD = {}
ZeD.tr = function(k) return k end
ZeD.trDefaults = function() end
ZeD.upper = function(s) return string.upper(s) end
'''


class Paint:
    """paints the calls the way preview.Canvas does (uint8 per call, a texture's opaque pixels pasted)"""
    def __init__(s, w, h):
        s.a = np.zeros((h, w, 4), np.uint8); s.cache = {}; s.missing = set()

    def rect(s, x, y, w, h, a, r, g, b):
        if w <= 0 or h <= 0: return
        x0, y0, x1, y1 = int(x), int(y), int(x + w), int(y + h)
        x0, y0 = max(0, x0), max(0, y0); x1, y1 = min(s.a.shape[1], x1), min(s.a.shape[0], y1)
        if x1 <= x0 or y1 <= y0: return
        c = np.array([round(r * 255), round(g * 255), round(b * 255)], np.float32)
        reg = s.a[y0:y1, x0:x1, :3].astype(np.float32)
        s.a[y0:y1, x0:x1, :3] = (reg * (1 - a) + c * a).astype(np.uint8)
        s.a[y0:y1, x0:x1, 3] = 255

    def tex(s, path, x, y, w, h, a):
        if path not in s.cache:
            fp = os.path.join(ROOT, "42", path)
            s.cache[path] = Image.open(fp).convert("RGBA") if os.path.exists(fp) else None
            if s.cache[path] is None: s.missing.add(path)
        im = s.cache[path]
        if im is None: return
        src = np.array(im.resize((int(w), int(h)), Image.NEAREST))
        x, y = int(x), int(y)
        sub = s.a[y:y + src.shape[0], x:x + src.shape[1]]
        m = src[:sub.shape[0], :sub.shape[1], 3] > 0
        sub[m] = src[:sub.shape[0], :sub.shape[1]][m]


def lua_files():
    return (os.path.join(LUA_DIR, "PixelFonts.lua"), os.path.join(SRC, "ZeD_PixelParts.lua"),
            os.path.join(SRC, "ZeD_RadioOps.lua"), os.path.join(SRC, "ZeD_Plate.lua"), os.path.join(LUA_DIR, "PhysPx.lua"))


DRAW = r'''
function draw_plate(pid, st, k, rect, tex)
    local el = { drawRect = function(self, x, y, w, h, a, r, g, b) rect(x, y, w, h, a, r, g, b) end,
                 drawTextureScaled = function(self, t, x, y, w, h, a) tex(t.path, x, y, w, h, a) end }
    local PX = ZeD.PhysPx
    local des = PX.plates[pid]
    local cv = ZeD.Px.canvas(el, 0, 0, k)
    local ctx = { tex = function(name) return ZeD.Px.tex(PX.texdir .. name .. ".png") end, now = 0 }
    ZeD.Plate.draw(cv, des, st, ctx)
end
'''


def lua_runtime():
    L = lj.LuaRuntime(unpack_returned_tuples=True)
    L.execute(PRELUDE)
    for f in lua_files():
        L.execute(open(f, "rb").read())
    L.execute(DRAW)
    return L


# ---- without lupa: one LuaJIT run per plate, every state's calls printed (R rect / T texture), painted here
def luajit():
    import glob
    exe = os.environ.get("LUAJIT")
    if exe and os.path.exists(exe): return exe
    for pat in (os.path.expanduser("~/.vscode/extensions/actboy168.lua-debug-*/runtime/win32-x64/luajit/lua.exe"),
                os.path.expanduser("~/.vscode/extensions/actboy168.lua-debug-*/runtime/linux-x64/luajit/lua")):
        hits = sorted(glob.glob(pat))
        if hits: return hits[-1]
    raise SystemExit("no lupa and no LuaJIT: install lupa, or set LUAJIT to a LuaJIT executable")


def lua_val(v):
    if v is None: return "nil"
    if isinstance(v, (bool, np.bool_)): return "true" if v else "false"
    if isinstance(v, (float, np.floating)): return repr(float(v))
    if isinstance(v, (int, np.integer)): return str(int(v))
    if isinstance(v, str):
        # the game's strings are one byte a character (as to_lua below): escaped byte by byte
        b = v.encode("latin-1", "replace")
        return '"' + "".join(chr(c) if 32 <= c < 127 and chr(c) not in '"\\' else "\\%d" % c for c in b) + '"'
    if isinstance(v, dict): return "{" + ", ".join(f"[{lua_val(k)}] = {lua_val(x)}" for k, x in v.items() if x is not None) + "}"
    if isinstance(v, (list, tuple)): return "{" + ", ".join(lua_val(x) for x in v) + "}"
    raise TypeError(type(v))


def run_cli(pid, jobs):
    """jobs [(state index, k, state)] -> {(state index, k): the draw call lines}"""
    import subprocess
    import tempfile
    lines = [PRELUDE]
    for f in lua_files(): lines.append('dofile("' + f.replace(os.sep, "/") + '")')
    lines.append(DRAW)
    lines.append('local function R(x, y, w, h, a, r, g, b) io.write(string.format("R %.4f %.4f %.4f %.4f %.6f %.6f %.6f %.6f\\n", x, y, w, h, a, r, g, b)) end')
    lines.append('local function T(p, x, y, w, h, a) io.write(string.format("T %s %.4f %.4f %.4f %.4f %.6f\\n", p, x, y, w, h, a or 1)) end')
    for si, k, st in jobs:
        lines.append(f'io.write("B {si} {k}\\n"); draw_plate({lua_val(pid)}, {lua_val(st)}, {k}, R, T); io.write("E\\n")')
    fd, path = tempfile.mkstemp(suffix=".lua")
    with os.fdopen(fd, "w", encoding="latin-1") as fh: fh.write("\n".join(lines))
    try:
        out = subprocess.run([luajit(), path], capture_output=True, check=False)
    finally:
        os.unlink(path)
    if out.returncode != 0: raise SystemExit(f"{pid}: LuaJIT failed: {out.stderr.decode('latin-1')[-800:]}")
    res, cur = {}, None
    for ln in out.stdout.decode("latin-1").splitlines():
        if ln.startswith("B "):
            _, a, b = ln.split(); cur = res.setdefault((int(a), int(b)), [])
        elif ln == "E": cur = None
        elif cur is not None and ln[:2] in ("R ", "T "): cur.append(ln)
    return res


def to_lua(L, v):
    if isinstance(v, dict): return L.table_from({k: to_lua(L, x) for k, x in v.items() if x is not None})
    if isinstance(v, (list, tuple)): return L.table_from([to_lua(L, x) for x in v])
    # the game's strings are one byte a character (the degree sign is string.char(176)), so a reading's
    # non-ASCII letters go over as Latin-1 bytes, not UTF-8
    if isinstance(v, str) and any(ord(c) > 127 for c in v): return v.encode("latin-1")
    return v


def preview_parts(data):
    """the exported parts in the preview's shape (rect lists back to runs)"""
    def runs(r): return [(r[i], r[i + 1] + j, r[i + 2]) for i in range(0, len(r), 4) for j in range(r[i + 3])]
    out = []
    for p in data["parts"]:
        q = dict(p)
        if "r" in q: q["runs"] = runs(q.pop("r"))
        if "halo" in q: q["halo"] = runs(q["halo"])
        if q["t"] == "bars": q["bars"] = [runs(b) for b in q["bars"]]
        if q["t"] == "sprite": q["sprite"] = q["sprite"]
        out.append(q)
    return out


def extra_states(pid):
    """states the previews do not show, so every live part is seen lit and unlit"""
    D = DESIGNS[pid]
    sts = [dict(s) for s in D["states"]]
    if pid.startswith("radio_"):
        import d_props as PR
        kind = pid.split("_", 1)[1]
        s = dict(sts[-1]); s["display"] = PR.display_reading(kind, on=True, freq="101.2" if kind in ("premium", "valutech", "makeshift") else "098.400",
                                                            name="A very long station name that marches", preset=5, tag="SCAN", cd=False, has_media=True)
        sts.append(s)
        if kind == "premium":
            s = dict(sts[-1]); s["display"] = PR.display_reading(kind, on=True, cd=True, elapsed="12:07", title="Moldy Peaches"); sts.append(s)
    if pid == "siren":
        for m in range(4): sts.append(dict(lightsMode=m, sirenMode=3 - m, lightsOn=m > 0, sirenOn=m < 3))
    if pid.startswith("oven_") or pid == "fryer":
        import d_ovens as O
        for t in (0, 50, 250, 300): sts.append(O.state(t, 120, True, 11, 59, celsius=bool(t % 100), vfdText="1:59", timerOn=True, unitC=True))
    if pid.startswith("gen_"):
        import d_gen as G
        sts.append(G.state(True, True, 0.05, condition=0.1, load=1.0)); sts.append(G.state(False, False, 1.0, condition=0.2))
    if pid.startswith("mw_"):
        import d_micro as M
        sts.append(M.state("60:00", 0, True, minutes=60)); sts.append(M.state("0:05", 2, False, powered=False))
    if pid.startswith("walkie_") or pid.startswith("ham_"):
        import d_walkie as DW
        _, kind, kw = DW.MODELS[pid]
        kw = {**kw, "name": "A very long channel name that marches", "mic_live": not kw.get("mic_live", False)}
        sts.append(DW.state(kind, True, **kw))                                       # the talk state flipped, a long name
        sts.append(DW.state(kind, True, **{**kw, "ac": True, "vol": 6, "ch": 10}))   # on the grid, full volume
        sts.append(DW.state(kind, True, dark=True, **kw))                            # at night: a LAMP set's glass goes dark
        sts.append(DW.state(kind, True, dark=True, lamp=True, **kw))                 # ... until LAMP lights it
        sts.append(DW.state(kind, False, dark=True))
    return sts


def main(only=None):
    data, pictures = EX.export(ROOT, only)
    L = lua_runtime() if lj else None
    g = L.globals() if L else None
    bad = 0; n = 0
    for pid in (only or DESIGNS):
        d = data["plates"][pid]
        base, sprites = pictures[pid]
        parts = preview_parts(d)
        states = []
        for st in extra_states(pid):
            st = {k: v for k, v in st.items() if k != "tapeNames"}       # the tape's handwriting is the game's font, not pixels
            if not st.get("display"): st.pop("display", None)
            states.append(st)
        cli = None if L else run_cli(pid, [(si, k, st) for si, st in enumerate(states) for k in (1, 2)])
        for si, st in enumerate(states):
            for k in (1, 2):
                want = np.array(PV.render_state(base, parts, sprites, st, k=k))
                pa = Paint(d["w"] * k, d["h"] * k)
                if L: g.draw_plate(pid, to_lua(L, st), k, pa.rect, pa.tex)
                else:
                    for ln in cli.get((si, k), []):
                        f = ln.split()
                        if f[0] == "R": pa.rect(*[float(x) for x in f[1:]])
                        else: pa.tex(f[1], *[float(x) for x in f[2:]])
                got = pa.a
                for im in (got, want): im[im[..., 3] == 0] = 0      # a clear pixel's colour does not matter
                n += 1
                if pa.missing: print("  missing textures", pa.missing)
                diff = np.any(got != want, axis=2)
                if diff.any():
                    bad += 1
                    ys, xs = np.nonzero(diff)
                    print(f"DIFFERENT {pid} state {si} k={k}: {int(diff.sum())} px, first at {xs[0]},{ys[0]} got {got[ys[0], xs[0]]} want {want[ys[0], xs[0]]}")
                    Image.fromarray(np.concatenate([got, want], axis=0)).save(os.path.join(HERE, "out", f"_diff_{pid}_{si}_{k}.png"))
        print(f"{pid:16s} ok so far {n - bad}/{n}")
    print(f"{n} pictures, {bad} different")
    return bad


if __name__ == "__main__":
    sys.exit(1 if main(sys.argv[1:] or None) else 0)
