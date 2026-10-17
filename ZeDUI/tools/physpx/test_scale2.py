"""Every organism at a whole multiple of 2 (a 4K screen): the plate drawn at k = 2, its controls where its pixels are."""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import orgtest as OT
import test_appliance as TA
import test_props as TP

FAILS = []
def check(what, got, want):
    ok = got == want
    print(("  ok   " if ok else "  FAIL ") + f"{what}: {got!r}" + ("" if ok else f" (want {want!r})"))
    if not ok: FAILS.append(what)

# the appliance view in a 960 wide Craft tab
class View2(TA.View):
    def __init__(s, pid):
        s.o = OT.Org([], w=960, h=760, scale=2.0)
        g = s.o.g
        s.o.lua(TA.STATIONS)
        s.o.L.execute(open(os.path.join(OT.SRC, "StationAppliance.lua"), "rb").read())
        g.CELSIUS, g.HOUR, g.MINUTE = False, 19, 42
        micro = pid.startswith("mw_")
        s.stove = g.make_stove(TA.TILES[pid], micro)
        s.st = s.o.L.table_from({"obj": s.stove, "kind": "micro" if micro else "oven", "key": "k2:" + pid, "name": pid})
        s.state = s.o.L.table_from({"zones": s.o.L.table(), "scroll": g.make_scroll()})
        s.win = s.o.L.table_from({"_playerObj": s.o.L.table()})
        s.panel = g.make_panel(960, 760)
        s.SA = g.ZeD.StationAppliance
        s.pid = pid
        s.render()
    def render(s):
        s.o.new_paint(960, 760)
        s.SA.render(s.panel, s.win, 0, 0, 960, 760, s.state, s.st)

v = View2("mw_white")
z = v.zones()["d1"]
check("4K: the 1 key is 42 x 13 plate px at k = 2", (z.w, z.h), (84, 26))
v.click("d4"); v.click("d5"); v.click("start")
check("4K: typed 45 s and started", (bool(v.stove.active), v.stove.timer), (True, 45))
v.save("org_mw_white_k2.png")
tex = [p for p in v.o.paint.cache if "physpx" in p]
check("4K: plate texture", sorted(t.split("/")[-1] for t in tex)[0], "mw_white.png")

o = OT.Org([], w=1000, h=300, scale=2.0)
o.lua(TP.PANEL)
o.L.execute(open(os.path.join(OT.SRC, "ZeD_CarRadio.lua"), "rb").read())
part, dd, chr, veh = o.g.make_radio("Base.RadioRed", o.L.table_from({"on": True, "channel": 98400, "presets": o.L.table()}))
R = o.g.ZeD.CarRadio
R.toggle(chr, part)
prop = R.props[0]
o.new_paint(1000, 300); prop.prerender(prop)
check("4K: the radio is 960 x 300", (prop.width, prop.height), (960, 300))
x, y, h = TP.centre(prop, "p1")
check("4K: preset 1 at 2x", (h.x, h.y, h.w, h.h), (192, 220, 44, 34))
o.paint.image().save(os.path.join(HERE, "out", "org_radio_premium_k2.png"))
print(f"{len(FAILS)} failed", FAILS)
sys.exit(1 if FAILS else 0)
