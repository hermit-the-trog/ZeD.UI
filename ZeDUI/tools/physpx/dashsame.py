"""Proves the dashboards draw exactly as before after their part drawing moved into the shared plate template.

Runs the real Lua twice under LuaJIT with the game mocked (ZeDUI/tools/dashpx/luatest.py's mocks): once the
dashboard as it is in the game (its own part drawing), once the dashboard on ZeD_Plate.lua. Every drawRect and
drawTextureScaled call of the last frame is recorded with all its arguments; the two call lists must be equal, call
for call, for every design in every state below (and so the pictures are equal pixel for pixel).
usage: python dashsame.py"""
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
DASH = os.path.join(HERE, "..", "dashpx")
sys.path.insert(0, DASH)
import lupa.luajit21 as lj          # noqa: E402
import luatest as LT                # noqa: E402
import designs as DZ                # noqa: E402

MOD_LUA = os.path.join(DASH, "out", "mod", "ZeD-UI", "42", "media", "lua", "client", "ZeD")
VARIANTS = {
    # the dashboard as it is live (dashpx/lua is byte-identical to the game's copies)
    "before": [os.path.join(DASH, "lua", "ZeD_PixelParts.lua"), os.path.join(HERE, "lua", "orig", "ZeD_Dashboard.lua")],
    # the dashboard on the template
    "after": [os.path.join(HERE, "lua", "ZeD_PixelParts.lua"), os.path.join(HERE, "lua", "ZeD_Plate.lua"),
              os.path.join(HERE, "lua", "ZeD_Dashboard.lua")],
}
RADIOOPS = os.path.join(HERE, "lua", "orig", "ZeD_RadioOps.lua")


class Log(LT.Recorder):
    def __init__(s, w, h):
        super().__init__(w, h); s.log = []

    def rect(s, x, y, w, h, a, r, g, b):
        s.log.append(("R", x, y, w, h, a, r, g, b)); super().rect(x, y, w, h, a, r, g, b)

    def tex(s, path, x, y, w, h, a):
        s.log.append(("T", path, x, y, w, h, a)); super().tex(path, x, y, w, h, a)


def run(variant, did, state, k=1, frames=6, dt=120, focus=None):
    L = lj.LuaRuntime(unpack_returned_tuples=True)
    g = L.globals()
    rec = Log(800 * k, 172 * k)
    clock = {"t": 1_000_000}
    g.py_now = lambda: clock["t"]
    titles = {LT.SCRIPTS[d].replace("Base.", ""): DZ.DESIGNS[d][0] for d in DZ.ORDER}
    g.py_text = lambda key: titles.get(str(key).replace("IGUI_VehicleName", ""), None)
    g.py_screen = lambda: L.table(1920 * k, 1080 * k)
    g.py_scale = lambda: float(k)
    g.py_rect = rec.rect
    g.py_tex = rec.tex
    g.py_log = lambda *a: None
    L.execute(LT.PRELUDE)
    for f in ("PixelFonts.lua", "DashPx.lua"):
        L.execute(open(os.path.join(MOD_LUA, f)).read())
    L.execute(open(RADIOOPS).read().replace("return O", "ZeD.RadioOps = O"))
    for f in VARIANTS[variant]:
        L.execute(open(f).read())
    L.execute(LT.VEHICLE)
    if state.get("gamepad"):
        L.execute(LT.HINT_PROBE)
    S = L.table_from({k_: v for k_, v in state.items() if not isinstance(v, (dict, list))})
    S.script = state.get("script") or LT.SCRIPTS[did]
    radio = state.get("radio")
    if radio:
        r = L.table_from({"kind": radio, "on": state.get("radioOn", False), "switchOn": state.get("radioOn", False), "channel": 98400,
                          "volume": 0.6, "presetIdx": state.get("presetIdx", 1), "name": "KNOX TALK", "signal": True,
                          "muted": state.get("muted", False), "micMuted": state.get("micMuted", False),
                          "playing": state.get("playing", False), "cdMs": 222000, "flash": state.get("flash"),
                          "scanning": state.get("scanning", False)})
        r.presets = L.table_from([L.table_from({"freq": 98400, "name": "Knox Talk"})])
        g.ZeD.RadioOps.read = lambda part: r
        S.radio = True
    else:
        S.radio = False
    veh = g.make_vehicle(S)
    ply = g.make_player(veh)
    g.getSpecificPlayer = lambda n: ply
    dash = g.ZeD_Dashboard.new(g.ZeD_Dashboard, 0)
    for i in range(frames):
        clock["t"] += dt
        rec.a[:] = 0
        rec.log = []
        dash.prerender(dash)
    if focus is not None:      # the gamepad's focus on the n-th control: one more frame with the cue drawn
        g.FOCUS_WIN = dash
        els = [dash._elements[i] for i in range(1, len(dash._elements) + 1)]
        if els:
            g.FOCUS_EL = els[focus % len(els)]
            clock["t"] += dt
            rec.a[:] = 0
            rec.log = []
            dash.prerender(dash)
    hits = [(h.id, h.x, h.y, h.w, h.h, h.enabled) for h in dash._hit.values()]
    return rec, hits


def states():
    D = dict(LT.STATE_DRIVE)
    yield "drive", D
    yield "key on", {**D, "running": False, "rpm": 0, "speed_kmh": 0}
    yield "off", {**D, "running": False, "keysIn": False, "speed_kmh": 0, "rpm": 0, "radioOn": False}
    yield "passenger", {**D, "passenger": True}
    yield "low fuel, hot", {**D, "fuel": 0.05, "engineCond": 20, "battery": 0.1, "rpm": 7000}
    yield "heater A/C", {**D, "heaterTemp": -20, "lights": False, "cruise": False, "anyLocked": False}
    yield "radio off", {**D, "radioOn": False}
    yield "radio flash", {**D, "flash": "STORE 3", "presetIdx": 3}
    yield "radio scan muted", {**D, "scanning": True, "muted": True, "micMuted": True}
    yield "radio cd", {**D, "playing": True}


def main():
    bad = 0; n = 0
    for did in DZ.ORDER:
        own = DZ.DESIGNS[did][6]
        for name, st in states():
            st = dict(st)
            st["hasLightbar"] = did in ("police", "fire", "ranger", "ambulance")
            for radio in ([own] if name != "drive" else [own, None, "premium", "valutech", "makeshift", "ham", "army", "hammake"]):
                s2 = dict(st); s2["radio"] = radio
                for k in ((1, 2) if name == "drive" else (1,)):
                    a, ha = run("before", did, s2, k=k)
                    b, hb = run("after", did, s2, k=k)
                    n += 1
                    same = a.log == b.log and ha == hb and np.array_equal(a.a, b.a)
                    if not same:
                        bad += 1
                        first = next((i for i, (x, y) in enumerate(zip(a.log, b.log)) if x != y), min(len(a.log), len(b.log)))
                        print(f"DIFFERENT {did} {name} radio={radio} k={k}: calls {len(a.log)} vs {len(b.log)}, first difference at {first}")
                        print("   before:", a.log[first] if first < len(a.log) else None)
                        print("   after: ", b.log[first] if first < len(b.log) else None)
        # the gamepad's focus cue on a few controls
        for fi in (0, 3, 7):
            st = dict(LT.STATE_DRIVE); st["radio"] = own; st["gamepad"] = True
            st["hasLightbar"] = did in ("police", "fire", "ranger", "ambulance")
            a, ha = run("before", did, st, focus=fi)
            b, hb = run("after", did, st, focus=fi)
            n += 1
            if not (a.log == b.log and ha == hb):
                bad += 1
                print(f"DIFFERENT {did} focus {fi}")
        print(f"{did:10s} ok so far: {n - bad}/{n}")
    print(f"{n} runs, {bad} different")
    return bad


if __name__ == "__main__":
    sys.exit(1 if main() else 0)
