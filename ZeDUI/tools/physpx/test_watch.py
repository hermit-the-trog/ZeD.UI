"""The watches, outside the game: the real ZeD_Watch over the shared plate template, a watch item mocked the way vanilla's
AlarmClockClothing behaves (full type, alarm set / hour / minute, digital or not). For every registered item the watch
must draw its plate exactly as the preview draws it for the same reading (pixel for pixel where the plate is opaque, a
hair of rounding allowed), at 1x and 2x, by day, at night, lit and while the alarm is being set. Then the controls: the
alarm, the set mode with its OFF notch, the speed and pause, the Timez light (three seconds), a changed watch closing the
setting, an unknown item borrowing a CaZio, and an addon's own registration.
usage: python test_watch.py"""
import math
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import orgtest as OT          # noqa: E402
import preview as PV          # noqa: E402
import export_phys as EX      # noqa: E402
from platesame import preview_parts   # noqa: E402

MOCKS = r'''
local function derive(base, name) local c = {}; c.__index = c; c.Type = name; setmetatable(c, { __index = base }); c.derive = derive; return c end
ZeD_Panel = { derive = derive }
ZeD_Panel.__index = ZeD_Panel
function ZeD_Panel:new(x, y, w, h) return setmetatable({ x = x, y = y, width = w, height = h }, ZeD_Panel) end
function ZeD_Panel:drawRect(x, y, w, h, a, r, g, b) py_rect(x, y, w, h, a, r, g, b) end
function ZeD_Panel:drawTextureScaled(t, x, y, w, h, a) py_tex(t.path, x, y, w, h, a) end
function ZeD_Panel:getWidth() return self.width end
function ZeD_Panel:getHeight() return self.height end
function ZeD_Panel:setWidth(v) self.width = v end
function ZeD_Panel:setHeight(v) self.height = v end
function ZeD_Panel:getX() return self.x end
function ZeD_Panel:getY() return self.y end
function ZeD_Panel:setX(v) self.x = v end
function ZeD_Panel:setY(v) self.y = v end
function ZeD_Panel:initialise() end
function ZeD_Panel:addToUIManager() end
function ZeD_Panel:setVisible() end
SPEED = 1
UIManager = { getClock = function() return nil end,
              getSpeedControls = function() return {
                  getCurrentGameSpeed = function() return SPEED end,
                  SetCurrentGameSpeed = function(_, n) SPEED = n end,
                  ButtonClicked = function(_, b) if b == "Pause" then SPEED = 0 elseif b == "Play" then SPEED = 1 end end,
                  getY = function() return -4000 end, isVisible = function() return false end } end }
getPlayerScreenLeft = function() return 0 end
getPlayerScreenTop = function() return 0 end
getPlayerScreenWidth = function() return 400 end
getPlayerScreenHeight = function() return 400 end
HOUR, MINUTE, SEC = 10, 58, 50
getGameTime = function() return { getHour = function() return HOUR end, getMinutes = function() return MINUTE end,
    getTimeOfDay = function() return HOUR + MINUTE / 60 + SEC / 3600 end,
    getDay = function() return 25 end, getMonth = function() return 6 end, getYear = function() return 1993 end } end
getClimateManager = function() return { getAirTemperatureForCharacter = function() return 21.4 end,
    getSeason = function() return { getDawn = function() return 6 end, getDusk = function() return 21 end } end } end
CLOCK24 = true
getCore = function() return { getOptionClock24Hour = function() return CLOCK24 end,
    getOptionTemperatureDisplayCelsius = function() return true end } end
WORN = nil
local function wornList()
    if not WORN then return { size = function() return 0 end } end
    local wi = { getItem = function() return WORN end, getLocation = function() return "LeftWrist" end }
    return { size = function() return 1 end, get = function(_, i) return wi end }
end
getSpecificPlayer = function() return { getWornItems = function() return wornList() end } end
function makeWatch(ft, digital)
    local w = { _cls = "AlarmClockClothing", ft = ft, armed = false, hr = 6, mn = 0, dig = digital }
    function w:getFullType() return self.ft end
    function w:isDigital() return self.dig end
    function w:isAlarmSet() return self.armed end
    function w:setAlarmSet(v) self.armed = v end
    function w:getHour() return self.hr end
    function w:setHour(v) self.hr = v end
    function w:getMinute() return self.mn end
    function w:setMinute(v) self.mn = v end
    return w
end
ZeD.Scale = { root = function() return SCALE end }
ISUIHandler = { allUIVisible = true }
local function ev() return { Add = function() end, Remove = function() end } end
Events = setmetatable({}, { __index = function(t, k) local e = ev(); rawset(t, k, e); return e end })
'''

ITEMS = [("Base.WristWatch_Left_DigitalBlack", "digital_black", True), ("Base.WristWatch_Right_DigitalDress", "digital_gold", True),
         ("Base.WristWatch_Left_DigitalRed", "timez_red", True), ("Base.WristWatch_Left_DigitalTimez", "timez_steel", True),
         ("Base.WristWatch_Right_DigitalTimez", "timez_steel", True),
         ("Base.WristWatch_Left_ClassicBlack", "classic_black", False), ("Base.WristWatch_Left_ClassicGold", "classic_gold", False),
         ("Base.WristWatch_Left_ClassicBrown", "timez_easy", False), ("Base.WristWatch_Right_ClassicMilitary", "timez_camper", False),
         ("Base.WristWatch_Left_Expensive", "expensive", False),
         ("SomeMod.WristWatch_Odd", "digital_black", True), ("SomeMod.WristWatch_OddDial", "classic_black", False)]
DIGITAL_PLATES = {"digital_black", "digital_gold", "timez_red", "timez_steel"}

FAILS = []
_PLATES = {}


def check(what, ok, detail=""):
    print(("  ok   " if ok else "  FAIL ") + what + ("" if ok else f"  {detail}"))
    if not ok: FAILS.append(what)


def plate(pid):
    if pid not in _PLATES:
        data, base, sprites = EX.build_plate(pid)
        _PLATES[pid] = (data, base, {k: v for k, v in sprites.items()})
    return _PLATES[pid]


def expected(pid, k, hour=10, minute=58, sec=50, armed=False, alarm_hour=6, speed=1, set_open=False, lit=False, bulb=False):
    """the preview's picture for the reading the watch should show"""
    data, base, sprites = plate(pid)
    day = 26
    rd = {"dateWin": str(day)}
    if set_open:
        rd.update(setTitle="ALARM" if armed else "ALARM OFF", setVal=f"{alarm_hour:02d}" if armed else "", setHint="-1H  +1H",
                  setText=f"AL {alarm_hour:02d}" if armed else "AL OFF")
    else:
        tod = hour + minute / 60 + sec / 3600
        rd.update(time=f"{hour:2d}:{minute:02d}", sec=f"{math.floor(tod * 3600) % 60:02d}", day="MO", date=str(day),
                  temp="21", tempUnit="°C")
        if speed == 0: rd["pause"] = "PAUSE"
        else: rd["speed"] = speed
        if armed: rd.update(alm="ALM", almTime=f"{alarm_hour}:00")
    tod = hour + minute / 60 + sec / 3600
    dark = (tod < 6 or tod >= 21) and not lit
    st = {"display": rd, "hour": hour, "minute": minute, "running": speed > 0, "alarmOn": armed, "setOpen": set_open,
          "lit": lit, "dark": dark, "bulb": bulb, "bulbDay": bulb and not dark, "bulbNight": bulb and dark}
    spr = {f"{n}": im for n, im in sprites.items()}
    return PV.render_state(base, preview_parts(data), spr, st, k=k)


def compare(what, got, want):
    g = np.array(got.convert("RGBA")).astype(int)
    w = np.array(want).astype(int)
    if g.shape != w.shape:
        check(what, False, f"size {g.shape} vs {w.shape}"); return
    m = w[..., 3] == 255
    d = np.abs(g[..., :3] - w[..., :3]).max(axis=2)
    bad = (d > 2) & m
    check(what, not bad.any(), f"{int(bad.sum())} px differ, first at {tuple(np.argwhere(bad)[0][::-1]) if bad.any() else ''}")


def world(scale):
    o = OT.Org([], w=400, h=400, scale=scale)
    o.lua(MOCKS)
    o.L.execute(open(os.path.join(OT.SRC, "ZeD_Watch.lua"), "rb").read())
    w = o.g.ZeD_Watch.new(o.g.ZeD_Watch, 0)
    return o, w


def frame(o, w):
    o.new_paint(400, 400)
    w.prerender(w)
    return o.paint.image().crop((0, 0, int(w.width), int(w.height)))


def wear(o, ft, dig):
    o.g.WORN = o.g.makeWatch(ft, dig)
    return o.g.WORN


def click(o, w, id_):
    for h in list(w._hit.values()):
        if h.id == id_:
            w.onMouseDown(w, h.x + h.w // 2, h.y + h.h // 2); return True
    return False


def ids(w): return sorted(h.id for h in w._hit.values())


def run(scale):
    k = int(scale)
    o, w = world(scale)
    shots = []
    # every item: its plate, its size, its picture by day
    for ft, pid, dig in ITEMS:
        wear(o, ft, dig)
        o.g.HOUR, o.g.MINUTE, o.g.SPEED = 10, 58, 1
        img = frame(o, w)
        data = plate(pid)[0]
        check(f"{scale}x {ft} -> {pid} size", (w.width, w.height) == (data["w"] * k, data["h"] * k), f"{(w.width, w.height)}")
        compare(f"{scale}x {ft} by day", img, expected(pid, k))
        if ft.startswith("Base.") and "Right" not in ft: shots.append(img)
    # the night, the setting, the light, per plate
    for ft, pid, dig in ITEMS[:10]:
        if "Right" in ft and pid == "timez_steel": continue
        item = wear(o, ft, dig)
        o.g.HOUR, o.g.MINUTE = 23, 41
        compare(f"{scale}x {pid} at night", frame(o, w), expected(pid, k, hour=23, minute=41))
        item.armed, item.hr = True, 7
        compare(f"{scale}x {pid} at night, alarm set", frame(o, w), expected(pid, k, hour=23, minute=41, armed=True, alarm_hour=7))
        o.g.HOUR, o.g.MINUTE = 10, 58
        opener = "set" if pid in ("digital_black", "digital_gold", "timez_red", "timez_steel", "classic_black", "classic_gold") else "crown"
        frame(o, w)
        check(f"{scale}x {pid} opens the setting with {opener}", click(o, w, opener) and w._setOpen)
        compare(f"{scale}x {pid} setting", frame(o, w), expected(pid, k, armed=True, alarm_hour=7, set_open=True))
        check(f"{scale}x {pid} set areas while setting", "setup" in ids(w) and "setdn" in ids(w), ids(w))
        click(o, w, opener); frame(o, w)
        check(f"{scale}x {pid} set areas gone after", "setup" not in ids(w), ids(w))
        item.armed = False
        if pid.startswith("timez_"):
            check(f"{scale}x {pid} has the light", "light" in ids(w), ids(w))
            o.g.HOUR, o.g.MINUTE = 2, 15
            frame(o, w); click(o, w, "light")
            compare(f"{scale}x {pid} lit at night", frame(o, w), expected(pid, k, hour=2, minute=15, lit=True))
            o.ms(3100)
            compare(f"{scale}x {pid} dark again after 3 s", frame(o, w), expected(pid, k, hour=2, minute=15))
            o.g.HOUR, o.g.MINUTE = 10, 58
        elif pid.startswith("digital_") or pid.startswith("classic_"):
            # a CaZio's bulb (Oct 21 2026): the night stays, the bulb's picture goes over it, by day a faint tint
            check(f"{scale}x {pid} has the light", "light" in ids(w), ids(w))
            o.g.HOUR, o.g.MINUTE = 2, 15
            frame(o, w); click(o, w, "light")
            compare(f"{scale}x {pid} bulb at night", frame(o, w), expected(pid, k, hour=2, minute=15, bulb=True))
            o.ms(3100)
            compare(f"{scale}x {pid} dark again after 3 s", frame(o, w), expected(pid, k, hour=2, minute=15))
            o.g.HOUR, o.g.MINUTE = 10, 58
            frame(o, w); click(o, w, "light")
            compare(f"{scale}x {pid} bulb by day", frame(o, w), expected(pid, k, bulb=True))
            o.ms(3100)
        else:
            check(f"{scale}x {pid} has no light", "light" not in ids(w), ids(w))
    # the controls on a CaZio digital
    item = wear(o, "Base.WristWatch_Left_DigitalBlack", True)
    frame(o, w)
    click(o, w, "alarm"); check(f"{scale}x ALARM arms", item.armed is True)
    click(o, w, "alarm"); check(f"{scale}x ALARM disarms", item.armed is False)
    frame(o, w); click(o, w, "set"); frame(o, w)
    click(o, w, "setup"); check(f"{scale}x + from OFF arms at 0", item.armed and item.hr == 0, (item.armed, item.hr))
    click(o, w, "setdn"); check(f"{scale}x - from 0 is OFF", item.armed is False, (item.armed, item.hr))
    click(o, w, "setdn"); check(f"{scale}x - from OFF arms at 23", item.armed and item.hr == 23, (item.armed, item.hr))
    click(o, w, "setup"); check(f"{scale}x + from 23 is OFF", item.armed is False)
    click(o, w, "setup"); click(o, w, "setup"); check(f"{scale}x + + from OFF is 1", item.armed and item.hr == 1, (item.armed, item.hr))
    click(o, w, "alarm"); check(f"{scale}x ALARM closes the setting", not w._setOpen)
    frame(o, w)
    o.g.SPEED = 1; click(o, w, "speed"); check(f"{scale}x SPEED steps to 2", o.g.SPEED == 2)
    click(o, w, "speed"); click(o, w, "speed"); check(f"{scale}x SPEED wraps to 1", o.g.SPEED == 1)
    click(o, w, "start"); check(f"{scale}x START pauses", o.g.SPEED == 0)
    compare(f"{scale}x paused readout", frame(o, w), expected("digital_black", k, armed=True, alarm_hour=1, speed=0))
    click(o, w, "start"); check(f"{scale}x START runs again at the last speed", o.g.SPEED == 1)
    # a changed watch closes the setting and puts the light out
    frame(o, w); click(o, w, "set"); check(f"{scale}x setting open", w._setOpen)
    wear(o, "Base.WristWatch_Left_DigitalRed", True); frame(o, w)
    check(f"{scale}x another watch closes the setting", not w._setOpen)
    # an addon's own watch: its registration, its plate data (here a copy of the camper's under its own id)
    o.lua('''
        local des = {}
        for k, v in pairs(ZeD.PhysPx.plates.timez_camper) do des[k] = v end
        ZeD.Watch.register { plate = "addon_camper", items = { "Addon.WristWatch_Left_Field" }, design = des,
                             texdir = ZeD.PhysPx.texdir }
    ''')
    wear(o, "Addon.WristWatch_Left_Field", False)
    compare(f"{scale}x an addon's registered watch", frame(o, w), expected("timez_camper", k))
    # 12-hour clock: P in the afternoon
    o.g.CLOCK24 = False
    wear(o, "Base.WristWatch_Left_DigitalBlack", True)
    o.g.HOUR, o.g.MINUTE = 15, 7
    frame(o, w)
    rd = w._st.display
    check(f"{scale}x 12-hour time", rd.time == " 3:07" and rd.pm == "P", (rd.time, rd.pm))
    o.g.CLOCK24 = True
    # no watch: the tape deck keys
    o.g.WORN = None
    frame(o, w)
    check(f"{scale}x no watch: the speed keys", ids(w) == ["speed0", "speed1", "speed2", "speed3"], ids(w))
    return shots


if __name__ == "__main__":
    rows = [run(1.0), run(2.0)]
    W = sum(i.width + 8 for i in rows[1]) + 8
    sheet = Image.new("RGBA", (W, rows[1][0].height + rows[0][0].height + 24), (70, 90, 70, 255))
    x = 8
    for i in rows[1]: sheet.alpha_composite(i, (x, 8)); x += i.width + 8
    x = 8
    for i in rows[0]: sheet.alpha_composite(i, (x, rows[1][0].height + 16)); x += i.width + 8
    os.makedirs(os.path.join(HERE, "out", "watch"), exist_ok=True)
    sheet.save(os.path.join(HERE, "out", "watch", "watch_live.png"))
    print(f"{len(FAILS)} failed", FAILS)
    sys.exit(1 if FAILS else 0)
