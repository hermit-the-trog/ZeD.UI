"""The no-watch speed keys up close, outside the game: the real ZeD_Watch over the shared plate template with no watch
worn. The tape deck keys draw (the plate and the pressed key's picture for the game's speed), each key is a click area,
and a click sets the game's speed through vanilla's speed controls. Pictures at 1x and 2x for review.
usage: python test_watchkeys.py"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import orgtest as OT          # noqa: E402

MOCKS = r'''
local function derive(base, name) local c = {}; c.__index = c; c.Type = name; setmetatable(c, { __index = base }); c.derive = derive; return c end
ZeD_Panel = { derive = derive }
ZeD_Panel.__index = ZeD_Panel
function ZeD_Panel:new(x, y, w, h) return setmetatable({ x = x, y = y, width = w, height = h }, ZeD_Panel) end
function ZeD_Panel:drawRect(x, y, w, h, a, r, g, b) py_rect(x, y, w, h, a, r, g, b) end
function ZeD_Panel:drawTextureScaled(t, x, y, w, h, a) py_tex(t.path, x, y, w, h, a) end
function ZeD_Panel:drawTextureScaledAspect(t, x, y, w, h, a) py_tex(t.path, x, y, w, h, a) end
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
getPlayerScreenHeight = function() return 200 end
getSpecificPlayer = function() return { getWornItems = function() return { size = function() return 0 end } end } end
getGameTime = function() return { getHour = function() return 10 end, getMinutes = function() return 8 end, getDay = function() return 0 end,
    getMonth = function() return 6 end, getYear = function() return 1993 end } end
getClimateManager = function() error("no climate in the test") end
getSoundManager = function() return { playUISound = function() end } end
instanceof = function() return false end
ZeD.Scale = { root = function() return SCALE end }
ISUIHandler = { allUIVisible = true }
local function ev() return { Add = function() end, Remove = function() end } end
Events = setmetatable({}, { __index = function(t, k) local e = ev(); rawset(t, k, e); return e end })
'''

FAILS = []


def check(what, got, want):
    ok = got == want
    print(("  ok   " if ok else "  FAIL ") + f"{what}: {got!r}" + ("" if ok else f" (want {want!r})"))
    if not ok: FAILS.append(what)


def run(scale):
    o = OT.Org([], w=400, h=200, scale=scale)
    o.lua(MOCKS)
    o.L.execute(open(os.path.join(OT.SRC, "ZeD_Watch.lua"), "rb").read())
    w = o.g.ZeD_Watch.new(o.g.ZeD_Watch, 0)
    shots = []
    for sp in (0, 1, 2, 3):
        o.g.SPEED = sp
        o.new_paint(400, 200)
        w.prerender(w)
        drawn = sorted(p.split("/")[-1] for p in o.paint.cache)
        check(f"{scale}x speed {sp} pictures", drawn, sorted(["speed_keys.png", f"speed_keys_speed{sp}.png"]))
        shots.append(o.paint.image().crop((0, 0, int(w.width), int(w.height))))
    k = int(scale)
    check(f"{scale}x size", (w.width, w.height), (114 * k, 26 * k))
    ids = [h.id for h in w._hit.values()]
    check(f"{scale}x keys", ids, ["speed0", "speed1", "speed2", "speed3"])
    # click the middle of each key: the game speed follows
    for h in list(w._hit.values()):
        w.onMouseDown(w, h.x + h.w // 2, h.y + h.h // 2)
        check(f"{scale}x click {h.id}", o.g.SPEED, int(h.id[-1]))
    return shots


if __name__ == "__main__":
    from PIL import Image
    rows = [run(1.0), run(2.0)]
    W = sum(i.width + 8 for i in rows[1]); H = rows[0][0].height + rows[1][0].height + 24
    sheet = Image.new("RGBA", (W + 8, H), (70, 90, 70, 255))
    x = 8
    for i in rows[1]: sheet.alpha_composite(i, (x, 8)); x += i.width + 8
    x = 8
    for i in rows[0]: sheet.alpha_composite(i, (x, rows[1][0].height + 16)); x += i.width + 8
    sheet.save(os.path.join(HERE, "out", "nowatch", "keys_live.png"))
    print(f"{len(FAILS)} failed", FAILS)
    sys.exit(1 if FAILS else 0)
