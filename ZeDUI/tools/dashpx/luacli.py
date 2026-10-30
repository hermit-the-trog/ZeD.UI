"""luatest.py without lupa: the same runs (the real Lua, the game's API mocked) in a LuaJIT executable, its draw calls
read back over stdout and painted by luatest's Recorder. luatest.py uses this when `lupa` is not installed.

The executable: $LUAJIT, else the LuaJIT the VS Code Lua debugger ships (actboy168.lua-debug).
"""
import glob
import os
import subprocess

import designs as DZ
import luatest as LT


def luajit():
    exe = os.environ.get("LUAJIT")
    if exe and os.path.exists(exe): return exe
    pats = [os.path.expanduser("~/.vscode/extensions/actboy168.lua-debug-*/runtime/win32-x64/luajit/lua.exe"),
            os.path.expanduser("~/.vscode/extensions/actboy168.lua-debug-*/runtime/linux-x64/luajit/lua")]
    for p in pats:
        hits = sorted(glob.glob(p))
        if hits: return hits[-1]
    raise SystemExit("no LuaJIT: install lupa, or set LUAJIT to a LuaJIT executable")


_texts = None


def TEXTS():
    global _texts
    if _texts is None: _texts = LT.load_texts()
    return _texts


def lua_val(v):
    if v is None: return "nil"
    if isinstance(v, bool): return "true" if v else "false"
    if isinstance(v, (int, float)): return repr(v)
    if isinstance(v, str): return '"' + v.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'
    if isinstance(v, dict): return "{" + ", ".join(f"[{lua_val(k)}] = {lua_val(x)}" for k, x in v.items()) + "}"
    if isinstance(v, (list, tuple)): return "{" + ", ".join(lua_val(x) for x in v) + "}"
    raise TypeError(type(v))


DRIVER = r'''
local clock = 1000000
local REC = false
local OUT = {}
local function emit(s) OUT[#OUT + 1] = s end
py_now = function() return clock end
py_text = function(k)
    local key = tostring(k)
    if key:sub(1, 16) ~= "IGUI_VehicleName" then return CFG.texts[key] end
    if CFG.vname then return CFG.vname end
    return CFG.titles[key:sub(17)]
end
py_screen = function() return { CFG.sw, CFG.sh } end
py_scale = function() return CFG.k end
py_rect = function(x, y, w, h, a, r, g, b)
    if REC then emit(string.format("R %.3f %.3f %.3f %.3f %.5f %.5f %.5f %.5f", x, y, w, h, a, r, g, b)) end
end
py_tex = function(path, x, y, w, h, a, r, g, b)
    if REC then emit(string.format("T %s %.3f %.3f %.3f %.3f %.5f %.5f %.5f %.5f", path, x, y, w, h, a or 1, r or 1, g or 1, b or 1)) end
end
py_log = function() end
local function run_file(path, from, to)
    local f = assert(io.open(path, "rb")); local src = f:read("*a"); f:close()
    if from then src = src:gsub(from, to) end
    assert(loadstring(src, "@" .. path))()
end
'''

RUN = r'''
local S = CFG.state
S.radio = CFG.radio and true or false
if CFG.radio then
    local r = { kind = CFG.radio, on = S.radioOn or false, switchOn = S.radioOn or false, channel = 98400, volume = 0.6,
                presetIdx = 1, name = "KNOX TALK", signal = true, muted = false, micMuted = false, playing = false,
                presets = { { freq = 98400, name = "Knox Talk" } } }
    ZeD.RadioOps.read = function(part) return r end
end
local veh = make_vehicle(S)
local ply = make_player(veh)
getSpecificPlayer = function() return ply end
local dash = ZeD_Dashboard.new(ZeD_Dashboard, 0)
if S.meterOn then dash:_meterFlag(veh, true) end
for i = 1, CFG.frames do
    clock = clock + CFG.dt
    REC = (i == CFG.frames) and CFG.paint
    dash:prerender()
end
for _, h in ipairs(dash._hit) do emit(string.format("H %s %d %d %d %d %s", h.id, h.x, h.y, h.w, h.h, tostring(h.enabled))) end
local b = dash._badge or {}
emit("B " .. tostring(dash._designId) .. "|" .. tostring(b.make) .. "|" .. tostring(b.model) .. "|" .. tostring(b.unit) .. "|" .. tostring(b.brand) .. "|" .. tostring(b.tag))
if CFG.hints then
    FOCUS_WIN = dash
    local els = {}
    for _, e in ipairs(dash._elements) do els[#els + 1] = e end
    for i = 0, #els do
        FOCUS_EL = (i > 0) and els[i] or nil
        HINTS = {}
        dash:prerender()
        for _, h in ipairs(HINTS) do emit(string.format("N %d %s", h.w, h.s)) end
    end
end
if CFG.probe then
    local st = dash._st
    for _, key in ipairs(CFG.probe) do emit("P " .. key .. " " .. tostring(st[key])) end
end
io.write(table.concat(OUT, "\n"), "\n")
'''


def script(did, state, k=1, frames=40, dt=120, paint=True, hints=False, lua_after=None, probe=None):
    titles = {LT.SCRIPTS[d].replace("Base.", ""): DZ.DESIGNS[d][0] for d in DZ.ORDER}
    S = {k_: v for k_, v in state.items() if not isinstance(v, (dict, list)) and k_ not in ("radio", "vname", "gamepad")}
    S["script"] = state.get("script") or LT.SCRIPTS[did]
    cfg = dict(k=k, sw=1920 * k, sh=1080 * k, frames=frames, dt=dt, paint=paint, hints=hints, titles=titles,
               vname=state.get("vname"), radio=state.get("radio"), state=S, probe=probe, texts=TEXTS())
    zed = os.path.join(LT.MOD, "media", "lua", "client", "ZeD")
    parts = ["CFG = " + lua_val(cfg), DRIVER, LT.PRELUDE, f"run_file({lua_val(LT.TR_LUA)})"]
    for f in (os.path.join(zed, "PixelFonts.lua"), os.path.join(zed, "DashPx.lua"), os.path.join(LT.LUA_SRC, "ZeD_PixelParts.lua")):
        parts.append(f"run_file({lua_val(f)})")
    parts.append(f'run_file({lua_val(LT.RADIOOPS)}, "return O", "ZeD.RadioOps = O")')
    for f in ("ZeD_Plate.lua", "ZeD_Dashboard.lua"):
        if os.path.exists(os.path.join(LT.LUA_SRC, f)): parts.append(f"run_file({lua_val(os.path.join(LT.LUA_SRC, f))})")
    parts.append(LT.VEHICLE)
    if state.get("gamepad"):
        parts.append('ZeD.Input = ZeD.Input or {}; ZeD.Input.Detector = { getMode = function() return "gamepad" end }')
    if lua_after: parts.append(lua_after)
    parts.append(RUN)
    return "\n".join(parts)


def run(did, state, k=1, frames=40, dt=120, paint=True, hints=False, lua_after=None, probe=None):
    """-> (Recorder, hits, badge (design, make, model, unit), hint lines [(w, text)], probes {key: str})"""
    src = script(did, state, k, frames, dt, paint, hints, lua_after, probe)
    tmp = os.path.join(LT.HERE, "out", "luatest"); os.makedirs(tmp, exist_ok=True)
    path = os.path.join(tmp, "_run.lua")
    with open(path, "w", encoding="utf-8") as f: f.write(src)
    p = subprocess.run([luajit(), path], capture_output=True, text=True, encoding="utf-8", errors="replace")
    if p.returncode != 0: raise RuntimeError(f"{did}: LuaJIT failed\n{p.stderr[-3000:]}")
    rec = LT.Recorder(LT.dashlib.W * k, LT.dashlib.H * k)
    hits, badge, hint_lines, probes = [], None, [], {}
    for ln in p.stdout.splitlines():
        if ln.startswith("R "):
            x, y, w, h, a, r, g, b = (float(v) for v in ln[2:].split())
            rec.rect(x, y, w, h, a, r, g, b)
        elif ln.startswith("T "):
            path_, x, y, w, h, a, r, g, b = ln[2:].rsplit(" ", 8)
            rec.tex(path_, float(x), float(y), float(w), float(h), float(a), float(r), float(g), float(b))
        elif ln.startswith("H "):
            id_, x, y, w, h, en = ln[2:].split()
            hits.append((id_, int(x), int(y), int(w), int(h), en == "true"))
        elif ln.startswith("B "):
            badge = tuple(ln[2:].split("|"))
        elif ln.startswith("N "):
            w, s = ln[2:].split(" ", 1)
            hint_lines.append((int(w), s))
        elif ln.startswith("P "):
            key, v = (ln[2:].split(" ", 1) + [""])[:2]
            probes[key] = v
    return rec, hits, badge, hint_lines, probes


def hint_check(hint_w):
    worst, bad = (0, ""), []
    for did in DZ.ORDER:
        for ign in (dict(keysIn=False, running=False), dict(keysIn=True, running=False), dict(keysIn=True, running=True)):
            st = dict(LT.STATE_DRIVE); st.update(ign); st["radio"] = DZ.DESIGNS[did][6]; st["gamepad"] = True
            for ash in (False, True):
                st["ash"] = ash
                st["meterOn"] = ash
                _, _, _, lines, _ = run(did, st, k=1, frames=2, paint=False, hints=True, lua_after=LT.HINT_PROBE)
                for w, s in lines:
                    if w > worst[0]: worst = (w, s)
                    if w > hint_w: bad.append((did, w, s))
    return worst, bad


def badge_check():
    bad = []
    for script_, name, did, make, model, lead, mark, tag in LT.BADGE_CASES:
        st = dict(LT.STATE_DRIVE); st.update(script=script_, vname=name, radio=None)
        _, _, b, _, _ = run(did, st, k=1, frames=2, paint=False)
        unit = b[3]
        got = (b[0], b[1], b[2], unit.split(" ")[0], b[4], b[5])
        want = (did, make, model, lead or got[3], str(mark) if mark else "nil", tag)
        print(f"  {name:36s} -> {got[0]:10s} {got[1]:9s} {got[2]:14s} {got[4]:9s} {got[5]:4s} {unit}")
        if got != want: bad.append((name, got, want))
    return bad
