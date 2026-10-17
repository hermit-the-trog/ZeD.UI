"""The ovens and microwaves in the Craft tab, outside the game: each plate by its tile, each control's vanilla call,
the touch pads' sequences, the display and the line under the plate; a picture of each for review.
usage: python test_appliance.py"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import orgtest as OT          # noqa: E402

STATIONS = r'''
ZeD.Stations = {
    call = function(o, m, ...) if o == nil then return nil end; local f = o[m]; if not f then return nil end
        local ok, r = pcall(f, o, ...); if ok then return r end; return nil end,
    DOT = string.char(183),
    renderViewHeader = function(panel, win, x, y, w, state, st)
        panel:drawRect(x, y, w, 40, 1, 0.20, 0.20, 0.21)
        panel:drawText("STATION   " .. tostring(st.name), x + 8, y + 12, 0.9, 0.9, 0.9, 1, "F2")
        return 40
    end,
    focusedId = function(win) return FOCUS_ID end,
    followFocus = function() end, drawDropdownFor = function() end, viewHeaderClick = function() return false end,
    dropdownWheel = function() return true end, dropdownFocusables = function() return {} end,
    selectFocusable = function() return nil end, addLeaveCancel = function() end,
}
'''

TILES = {"oven_green": "appliances_cooking_01_1", "oven_red": "appliances_cooking_01_9", "oven_grey": "appliances_cooking_01_5",
         "oven_modern": "appliances_cooking_01_13", "oven_industrial": "appliances_cooking_01_21", "oven_large": "appliances_cooking_01_41",
         "fryer": "appliances_cooking_01_53", "mw_white": "appliances_cooking_01_24", "mw_chrome": "appliances_cooking_01_28"}


class View:
    def __init__(s, pid, celsius=False, hour=19, minute=42):
        s.o = OT.Org([], w=480, h=420)
        g = s.o.g
        s.o.lua(STATIONS)
        s.o.L.execute(open(os.path.join(OT.SRC, "StationAppliance.lua"), "rb").read())   # after the stations mock
        g.CELSIUS, g.HOUR, g.MINUTE = celsius, hour, minute
        micro = pid.startswith("mw_")
        s.stove = g.make_stove(TILES[pid], micro)
        s.st = s.o.L.table_from({"obj": s.stove, "kind": "micro" if micro else "oven", "key": "10,20,0:" + pid, "name": pid})
        s.state = s.o.L.table_from({"zones": s.o.L.table(), "scroll": g.make_scroll()})
        s.win = s.o.L.table_from({"_playerObj": s.o.L.table()})
        s.panel = g.make_panel(480, 420)
        s.SA = g.ZeD.StationAppliance
        s.pid = pid
        s.render()

    def render(s):
        s.o.new_paint(480, 420)
        s.SA.render(s.panel, s.win, 0, 0, 480, 420, s.state, s.st)

    def zones(s):
        return {z.id: z for z in s.state.zones.values() if z.type == "plate"}

    def click(s, id_, side=1, dt=200):
        z = s.zones()[id_]
        x = z.x + (z.w * 0.75 if side > 0 else z.w * 0.25)
        s.SA.onClick(s.win, s.state, s.st, x, z.y + z.h / 2)
        s.o.ms(dt); s.render()

    def wheel(s, id_, up=True):
        z = s.zones()[id_]
        s.SA.onMouseWheel(s.win, s.state, s.st, -1 if up else 1, z.x + z.w / 2, z.y + z.h / 2)
        s.render()

    def tick(s, sec):
        s.o.g.world_tick(sec); s.render()

    def ps(s): return s.SA.plateState(s.st)

    def line(s):
        t = [x[0] for x in s.o.paint.texts if not x[0].startswith("STATION") and not x[0].startswith("IN THE") and x[0] != "Empty"]
        return t[0] if t else None

    @property
    def stove(s): return s._stove

    @stove.setter
    def stove(s, v): s._stove = v

    def save(s, name):
        s.o.paint.image().save(os.path.join(HERE, "out", name))


FAILS = []


def check(what, got, want):
    ok = got == want
    print(("  ok   " if ok else "  FAIL ") + f"{what}: {got!r}" + ("" if ok else f" (want {want!r})"))
    if not ok: FAILS.append(what)


def dial_oven(pid, on_ids):
    v = View(pid)
    print(pid, "zones", sorted(v.zones()))
    check(f"{pid} unpowered line", v.line(), "OFF")
    for _ in range(4): v.wheel("heat", True)
    check(f"{pid} heat after 4 wheel clicks (C)", v.stove.temp, 200)
    check(f"{pid} pointer stop", v.ps().ovenStop, 4)
    v.click("timer", +1); v.click("timer", +1); v.click("timer", +1)
    check(f"{pid} timer 3 clicks right (s)", v.stove.timer, 180)
    v.click("timer", -1)
    check(f"{pid} timer back one (s)", v.stove.timer, 120)
    v.click(on_ids[0])
    check(f"{pid} on", bool(v.stove.active), True)
    check(f"{pid} lamp/switch", (v.ps().on, v.ps().switched), (True, True))
    check(f"{pid} line on", v.line(), "ON  \xb7  390\xb0F  \xb7  2 MIN LEFT")
    v.tick(61)
    check(f"{pid} a minute later", v.line(), "ON  \xb7  390\xb0F  \xb7  1 MIN LEFT")
    v.click("timer", +1)         # while it runs, the knob reads time left: 1 min -> the next stop, 2 min left
    check(f"{pid} timer while running: time left (s)", v.stove.timer - v.stove.isRunningFor(v.stove), 120)
    v.tick(125)
    check(f"{pid} timer up: off", (bool(v.stove.active), v.line()), (False, "OFF  \xb7  SET 390\xb0F"))
    v.click(on_ids[0])
    v.click(on_ids[-1])
    check(f"{pid} off again", bool(v.stove.active), False)
    v.stove.powered = False; v.render()
    check(f"{pid} no power: no controls", sorted(v.zones()), [])
    check(f"{pid} no power line", v.line(), "NO POWER")
    v.stove.powered = True; v.render()
    v.save(f"org_{pid}.png")
    return v


def grey():
    v = View("oven_grey")
    check("grey idle display: the clock", v.ps().vfdText, "7:42")
    v.click("bake")
    check("grey BAKE: on at 200 C", (bool(v.stove.active), v.stove.temp), (True, 200))
    check("grey shows the heat", (v.ps().vfdText, v.ps().unitF), ("390", True))
    v.click("up"); v.click("up")
    check("grey up up: 300 C", v.stove.temp, 300)
    v.click("up")
    check("grey stays at the top", v.stove.temp, 300)
    v.click("timer")
    check("grey TIMER shows the timer", v.ps().vfdText, "0:00")
    for _ in range(6): v.click("up")
    check("grey timer 6 stops up (min)", v.stove.timer / 60, 10)
    check("grey TIMER lamp", v.ps().timerOn, True)
    v.click("down")
    check("grey timer one down (min)", v.stove.timer / 60, 5)
    v.o.ms(7000); v.render()
    check("grey readout falls back to the heat", v.ps().vfdText, "570")
    v.click("broil")
    check("grey BROIL: the top heat", v.stove.temp, 300)
    v.click("clearoff")
    check("grey CLEAR/OFF: off, timer cleared", (bool(v.stove.active), v.stove.timer), (False, 0))
    check("grey back to the clock", v.ps().vfdText, "7:42")
    for _ in range(2): v.click("down")
    check("grey down while off and idle: nothing", (v.stove.temp, bool(v.stove.active)), (300, False))
    v.save("org_oven_grey.png")


def modern():
    v = View("oven_modern", celsius=True)
    v.click("bake"); v.click("d1"); v.click("d8"); v.click("d0")
    check("modern typed 180 C", v.ps().vfdText, "180")
    check("modern unit lamp C", (v.ps().unitC, v.ps().unitF), (True, False))
    v.click("start")
    check("modern START: on at the nearest stop", (bool(v.stove.active), v.stove.temp), (True, 200))
    check("modern shows the heat", v.ps().vfdText, "200")
    v.click("timer"); v.click("d4"); v.click("d5")
    check("modern timer typed", v.ps().vfdText, "0:45")
    v.click("start")
    check("modern timer set: 45 min left", v.stove.timer - v.stove.isRunningFor(v.stove), 45 * 60)
    v.click("timer"); v.click("d1"); v.click("d3"); v.click("d0"); v.click("start")
    check("modern timer 1:30", v.stove.timer - v.stove.isRunningFor(v.stove), 90 * 60)
    v.click("timer"); v.click("d9"); v.click("d0"); v.click("d0"); v.click("start")
    check("modern timer capped at 2:00", v.stove.timer - v.stove.isRunningFor(v.stove), 120 * 60)
    v.click("cancel")
    check("modern CANCEL: off, timer cleared", (bool(v.stove.active), v.stove.timer), (False, 0))
    v.click("d3"); v.click("d0"); v.click("d0")
    check("modern digits without BAKE type a heat", v.ps().vfdText, "300")
    v.o.ms(25000); v.render()
    check("modern an entry nobody starts is dropped", v.ps().vfdText, "7:42")
    v.o.g.CELSIUS = False
    v.click("bake"); v.click("d4"); v.click("d2"); v.click("d5"); v.click("start")
    check("modern 425 F lands on 200 C", v.stove.temp, 200)
    v.click("broil")
    check("modern BROIL", v.stove.temp, 300)
    v.save("org_oven_modern.png")


def mw_white():
    v = View("mw_white")
    check("microwave idle: the clock", v.ps().mwText, "7:42")
    v.click("d1"); v.click("d3"); v.click("d0")
    check("microwave typed 1:30", v.ps().mwText, "1:30")
    v.click("start")
    check("microwave cooks 90 s", (bool(v.stove.active), v.stove.timer), (True, 90))
    v.tick(43)
    check("microwave counts down", v.ps().mwText, "0:47")
    check("microwave line", v.line(), "COOKING  \xb7  LO  \xb7  0:47 LEFT")
    v.click("stop")
    check("microwave STOP pauses (47 s kept)", (bool(v.stove.active), v.stove.timer), (False, 47))
    check("microwave paused display", v.ps().mwText, "0:47")
    v.click("start")
    check("microwave START goes on", (bool(v.stove.active), v.stove.timer), (True, 47))
    v.tick(50)
    check("microwave done: off, the clock", (bool(v.stove.active), v.ps().mwText), (False, "7:42"))
    v.click("power")
    check("microwave POWER LEVEL from LO rounds to HI", v.stove.temp, 130)
    v.click("power"); v.click("power")
    check("microwave two levels down: MED", (v.stove.temp, v.ps().mwPower), (90, 3))
    v.click("timecook"); v.click("d5"); v.click("timecook"); v.click("d2"); v.click("d0"); v.click("d0"); v.click("start")
    check("microwave TIME COOK starts a fresh entry: 2:00", v.stove.timer, 120)
    v.click("stop"); v.click("stop")
    check("microwave STOP twice clears", (bool(v.stove.active), v.stove.timer), (False, 0))
    v.click("d9"); v.click("d9"); v.click("d9"); v.click("d9"); v.click("d9")
    check("microwave keeps the last four figures", v.ps().mwText, "99:99")
    v.click("start")
    check("microwave caps at an hour", v.stove.timer, 3600)
    v.save("org_mw_white.png")


def mw_chrome():
    v = View("mw_chrome")
    v.wheel("power", False); v.wheel("power", False)
    check("chrome power two stops down from LO stays LO", v.stove.temp, 50)
    for _ in range(3): v.wheel("power", True)
    check("chrome power three up: 110", (v.stove.temp, v.ps().mwPowerIdx), (110, 3))
    for _ in range(12): v.click("timer", +1)
    check("chrome timer 12 stops (min)", v.stove.timer / 60, 20)
    v.click("start")
    check("chrome START on", bool(v.stove.active), True)
    v.tick(600)
    check("chrome pointer at 10 min left", round(v.ps().timerF60, 3), round(600 / 3600, 3))
    v.click("start")
    check("chrome START again: off", bool(v.stove.active), False)
    v.save("org_mw_chrome.png")


def tiles():
    import lupa
    v = View("oven_green")
    for tile, want in (("appliances_cooking_01_2", "oven_green"), ("appliances_cooking_01_14", "oven_modern"),
                       ("appliances_cooking_01_55", "fryer"), ("modded_oven_7", "oven_modern"), ("appliances_cooking_01_25", "oven_modern")):
        st = v.o.L.table_from({"obj": v.o.g.make_stove(tile, False), "kind": "oven", "key": tile})
        _, pid = v.SA.plateFor(st)
        check(f"oven tile {tile}", pid, want)
    for tile, want in (("appliances_cooking_01_29", "mw_chrome"), ("appliances_cooking_01_3", "mw_white"), ("modded_mw", "mw_white")):
        st = v.o.L.table_from({"obj": v.o.g.make_stove(tile, True), "kind": "micro", "key": tile})
        _, pid = v.SA.plateFor(st)
        check(f"microwave tile {tile}", pid, want)


if __name__ == "__main__":
    tiles()
    dial_oven("oven_green", ["on", "off"])
    for pid in ("oven_red", "oven_industrial", "oven_large", "fryer"):
        dial_oven(pid, ["onoff", "onoff"])
    grey(); modern(); mw_white(); mw_chrome()
    print(f"{len(FAILS)} failed", FAILS)
    sys.exit(1 if FAILS else 0)
