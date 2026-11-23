-- ZeDUI/tools/qa/error_box_sim.lua  (Nov 22 2026, Error box, the director), no game running.
-- ZeD_ErrorBox.lua over fakes:
--   HIDE    when the clip that hides the game's red box runs: in game only, never in safe mode or with the "Error
--           box" tick, not while the game's FPS graph is up, not with "Lock cursor to window" on and the offscreen UI
--           off; the clip is a stencil rect on the Java element, set and never cleared; the handler goes last in
--           OnPostUIDraw (added again at the game's start)
--   COUNT   what counts as new: an unread line 1, each error entry filed 1 more (the game's count rising, not its raw
--           number of entries), the notes over his head never
--   SHOW    the notice shows for SHOW_MS after a rise, stays while anything is unread or a balloon is up, hides itself
--           after; a fall (a line read) starts nothing; safe mode and no character hide it
--   CLICK   a click on the notice opens Messages (the belt's note did before)
--   PLACE   the bottom right corner; left of the game's box while that is given back; the balloons' anchor
--   MARK    the marker (Error marker, Nov 22 2026): the slide's positions over time, the notice lifted by the marker's
--           height, the hold stretched by repeat errors, red for ZeD's own and gray for others', none for notes, in
--           safe mode, with the game's box given back or with no character; a click opens Messages
-- Run from the repo root:  lua51 ZeDUI/tools/qa/error_box_sim.lua
-- It prints FAIL lines and a last line "error_box_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]error_box_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end

local NOW = 100000
function getTimestampMs() return NOW end
print = (function(p) return function(s) if not tostring(s):find("^%[ZeD%]") then p(s) end end end)(print)
function require() end

-- the game's events: lists in order, Add and Remove
local function event()
    local e = { list = {} }
    function e.Add(f) e.list[#e.list + 1] = f end
    function e.Remove(f)
        for i = #e.list, 1, -1 do if e.list[i] == f then table.remove(e.list, i) end end
    end
    return e
end
Events = { OnPostUIDraw = event(), OnPreUIDraw = event(), OnGameStart = event(), OnTick = event() }
local function fire(name) local l = {}; for i, f in ipairs(Events[name].list) do l[i] = f end; for _, f in ipairs(l) do f() end end

local INGAME, LOCK, FBO = true, false, true
function isIngameState() return INGAME end
local SW, SH = 1920, 1080
function getCore()
    return { getScreenWidth = function() return SW end, getScreenHeight = function() return SH end,
             getOptionLockCursorToWindow = function() return LOCK end, getOptionUIFBO = function() return FBO end }
end
local PLAYER = {}
function getPlayer() return PLAYER end
function getPlayerScreenLeft() return 0 end
function getPlayerScreenTop() return 0 end
function getPlayerScreenWidth() return SW end
function getPlayerScreenHeight() return SH end
function getTexture() return false end

-- the Java element the clip is set on
local stencil = {}
ISUIElement = {}
function ISUIElement:new(x, y, w, h)
    local o = { x = x, y = y, w = w, h = h }
    function o:initialise() end
    function o:instantiate()
        self.javaObject = { setStencilRect = function(_, a, b, c, d) stencil[#stencil + 1] = { a, b, c, d } end,
                            clearStencilRect = function() stencil.cleared = true end }
    end
    return o
end

-- a panel class enough for the notice
ZeD_Panel = {}
function ZeD_Panel:derive(name)
    local c = {}
    setmetatable(c, { __index = self })
    c.Type = name
    return c
end
function ZeD_Panel:new(x, y, w, h)
    local o = { x = x, y = y, width = w, height = h, visible = true }
    return o
end
function ZeD_Panel:initialise() end
function ZeD_Panel:addToUIManager() self.onList = true end
function ZeD_Panel:setAlwaysOnTop() end
function ZeD_Panel:setVisible(v) self.visible = v end
function ZeD_Panel:getIsVisible() return self.visible end
function ZeD_Panel:setX(v) self.x = v end
function ZeD_Panel:setY(v) self.y = v end
function ZeD_Panel:setWidth(v) self.width = v end
function ZeD_Panel:setHeight(v) self.height = v end
function ZeD_Panel:getX() return self.x end
function ZeD_Panel:getY() return self.y end
function ZeD_Panel:getWidth() return self.width end

local SAFE, PIECE = false, false
local opened, sounds = 0, 0
ZeD = {
    tr = function(k) return k end,
    T = { px = function(v) return v end },
    Safe = { on = function(name) if SAFE then return true end if name == "errorbox" then return PIECE end return false end },
    uiSound = function() sounds = sounds + 1 end,
}
ZeD.Messages = { sources = {}, toasts = {}, open = function() opened = opened + 1 end }
local M = ZeD.Messages
function M.unread()
    local n = 0
    for _, s in pairs(M.sources) do for _, it in ipairs(s.items) do if not it.read then n = n + 1 end end end
    return n
end

assert(loadfile(Z .. "ZeD_ErrorBox.lua"))()
local E = ZeD.ErrorBox
check("ZeD_ErrorBox.lua loads", type(E) == "table" and type(E.postDraw) == "function")

-- ---------------------------------------------------------------------------
-- HIDE
-- ---------------------------------------------------------------------------
check("HIDE in game: on", E.hideWanted() == true)
INGAME = false
check("HIDE the main menu (not the game state): off", E.hideWanted() == false)
E.postDraw()
check("HIDE the main menu: no clip set", #stencil == 0)
INGAME = true
SAFE = true
check("HIDE safe mode: off", E.hideWanted() == false)
SAFE = false
PIECE = true
check("HIDE the Error box tick (the game's own box): off", E.hideWanted() == false)
PIECE = false
ISFPS = { start = true }
check("HIDE the FPS graph up: off (it draws after the UI)", E.hideWanted() == false)
ISFPS.start = false
LOCK, FBO = true, false
check("HIDE the game's own pointer drawn after the box (locked cursor, offscreen UI off): off", E.hideWanted() == false)
FBO = true
check("HIDE locked cursor with the offscreen UI on: on", E.hideWanted() == true)
LOCK = false
E.off = true
check("HIDE QA's switch: off", E.hideWanted() == false)
E.off = false
E.postDraw()
check("HIDE the clip: one stencil rect on the Java element", #stencil == 1 and stencil[1][3] == 1 and stencil[1][4] == 1, #stencil)
check("HIDE the clip's element sits off the screen", E._clip and E._clip.x < 0 and E._clip.y < 0)
check("HIDE the clip is never cleared", stencil.cleared == nil)
check("HIDE the clip's element never goes on the UI list", E._clip and not E._clip.onList)

-- last in line: a handler of another file added after this one at load is moved behind at the game's start
local later = function() end
Events.OnPostUIDraw.Add(later)
fire("OnGameStart")
local pl = Events.OnPostUIDraw.list
check("HIDE the game's start: the clip's handler is the last OnPostUIDraw", #pl == 2 and pl[1] == later and pl[2] ~= later, #pl)
local late2 = function() end
Events.OnPostUIDraw.Add(late2)
fire("OnTick")
pl = Events.OnPostUIDraw.list
check("HIDE the first tick after: last again (a mod that added its own at the game's start)", pl[#pl] ~= late2 and pl[#pl - 1] == late2)
check("HIDE the first tick's re-add runs once", #Events.OnTick.list == 0, #Events.OnTick.list)

-- ---------------------------------------------------------------------------
-- COUNT
-- ---------------------------------------------------------------------------
check("COUNT nothing kept: 0", E.arrivals() == 0)
M.sources.Halo = { kind = "halo", items = { { read = true }, { read = true } } }
check("COUNT the notes over his head never count", E.arrivals() == 0)
M.sources.ModA = { kind = "mods", items = { { read = false } } }
check("COUNT an unread note: 1", E.arrivals() == 1)
local errItem = { read = false, count = 1 }
M.sources.TheGame = { kind = "err", items = { errItem } }
check("COUNT a new error line with one entry: 1 + 1", E.arrivals() == 3, E.arrivals())
errItem.count = 2
check("COUNT another entry on the same line: one more", E.arrivals() == 4, E.arrivals())
errItem.read = true
check("COUNT the line read: one less (the entries stay counted)", E.arrivals() == 3, E.arrivals())

-- ---------------------------------------------------------------------------
-- SHOW
-- ---------------------------------------------------------------------------
M.sources = { Halo = { kind = "halo", items = { { read = true } } } }
E._until, E._seen = 0, 0
E.install()
local el = E._note
check("SHOW the notice made, on the UI list, hidden", el and el.onList and el.visible == false)
E.frame()
check("SHOW nothing new: hidden", el.visible == false)
errItem = { read = false, count = 1 }
M.sources.TheGame = { kind = "err", items = { errItem } }
E.frame()
check("SHOW a new error: shown", el.visible == true)
errItem.read = true
NOW = NOW + E.SHOW_MS - 1
E.frame()
check("SHOW read at once: still up for the few seconds", el.visible == true)
NOW = NOW + 2
E.frame()
check("SHOW after SHOW_MS with nothing unread: hidden", el.visible == false)
errItem.count = 2
E.frame()
check("SHOW the same error again (the count rose): shown", el.visible == true)
NOW = NOW + E.SHOW_MS + 1
E.frame()
check("SHOW ... and hidden after", el.visible == false)
M.sources.ModA = { kind = "mods", items = { { read = false } } }
E.frame()
NOW = NOW + E.SHOW_MS * 5
E.frame()
check("SHOW something unread: stays up", el.visible == true)
M.sources.ModA.items[1].read = true
E.frame()
check("SHOW read, long after it came: hidden at once", el.visible == false)
M.sources.ModA = nil
E.frame()
check("SHOW a fall (a line deleted) starts nothing", el.visible == false)
M.toasts = { { head = "x" } }
E.frame()
check("SHOW a balloon of Messages up: the notice it comes out of shows", el.visible == true)
M.toasts = {}
E.frame()
check("SHOW the balloon gone: hidden", el.visible == false)
E.showFor(500)
E.frame()
check("SHOW showFor (the tour's Guide step): shown", el.visible == true)
NOW = NOW + 501
E.frame()
check("SHOW showFor ends", el.visible == false)
M.sources.ModB = { kind = "mods", items = { { read = false } } }
SAFE = true
E.frame()
check("SHOW safe mode: hidden", el.visible == false)
SAFE = false
PLAYER = nil
E.frame()
check("SHOW no character: hidden", el.visible == false)
PLAYER = {}
E.frame()
check("SHOW back: shown", el.visible == true)

-- ---------------------------------------------------------------------------
-- PLACE
-- ---------------------------------------------------------------------------
check("PLACE the bottom right corner, EDGE_U in", el.x == SW - E.NOTE_U - E.EDGE_U and el.y == SH - E.NOTE_U - E.EDGE_U
    and el.width == E.NOTE_U, tostring(el.x) .. "," .. tostring(el.y))
local ax, ay = E.anchor(0)
check("PLACE the balloons out of its top middle", ax == el.x + E.NOTE_U / 2 and ay == el.y, tostring(ax) .. "," .. tostring(ay))
PIECE = true
E.frame()
check("PLACE the game's box given back: the notice left of it", el.x == SW - E.NOTE_U - E.EDGE_U - E.GAME_BOX_W, el.x)
PIECE = false
E.frame()
el.visible = false
check("PLACE hidden: no anchor (the balloons use their fallbacks)", E.anchor(0) == nil)
E.frame()

-- ---------------------------------------------------------------------------
-- CLICK
-- ---------------------------------------------------------------------------
opened = 0
local consumed = ZeD_ErrorNotice.onMouseDown(el, 5, 5)
check("CLICK the notice: Messages opens, with the button sound", opened == 1 and sounds >= 1 and consumed == true)
check("CLICK the pad from the belt: player one only, while it shows", E.padReach(0) == true and E.padReach(1) == false)
el.visible = false
check("CLICK hidden: no pad stop", E.padReach(0) == false)

-- ---------------------------------------------------------------------------
-- MARK  the marker (Error marker, the director, Nov 22 2026): a box the notice's width rises from the screen's bottom
--       edge when a new error is filed, lifts the notice, holds HOLD_MS and slides back down; linear, RISE_MS up and
--       FALL_MS down; more errors while it is up stretch the hold; red for ZeD's own, gray for others'; none for notes,
--       in safe mode, with the game's box given back or with no character
-- ---------------------------------------------------------------------------
local drawn = {}
function ZeD_Panel:drawRect(x, y, w, h, a, r, g, b) drawn[#drawn + 1] = { r = r, g = g, b = b } end
function ZeD_Panel:drawRectBorder() end
function ZeD_Panel:drawText() end
function ZeD_Panel:isMouseOver() return false end
local backs = 0
function ZeD_Panel:backMost() backs = backs + 1 end
ZeD.TM = { getFontHeight = function() return 14 end, MeasureStringX = function(_, f, s) return #s * 7 end }
ZeD.T.danger = { r = 0.9, g = 0.1, b = 0.1 }
ZeD.T.textDim = { r = 0.5, g = 0.5, b = 0.5 }
ZeD.T.borderS = { r = 0.2, g = 0.2, b = 0.2 }
ZeD.T.hover = { r = 1, g = 1, b = 1, a = 0.2 }
ZeD.T.fontF1, ZeD.T.fontF5 = "F1", "F5"

M.sources = { Halo = { kind = "halo", items = { { read = true } } } }
M.toasts = {}
E._note = nil
E._marker = nil
E._mk = { phase = nil, p = 0, t = 0, holdEnd = 0, count = 0, kind = nil }
E.install()
el = E._note
local mk = E._marker
local REST = SH - E.NOTE_U - E.EDGE_U
local MW, MH = E.markSize()
local D = MH + E.EDGE_U   -- (how far the marker's top travels)
check("MARK made at the game's start: hidden, on the UI list, not always on top, at the back", mk and mk.visible == false
    and mk.onList and backs >= 1)
check("MARK size: the notice's width, two lines of the badge's font high", MW == E.NOTE_U and MH == 14 * 2 + 6, MW .. "x" .. MH)
check("MARK the timings: 0.5 s up, 3 s held, 0.5 s down", E.RISE_MS == 500 and E.HOLD_MS == 3000 and E.FALL_MS == 500)
E.frame()
check("MARK nothing new: hidden", mk.visible == false)

local T0 = NOW
local zedErr = { read = false, count = 1 }
M.sources["ZeD-GUI"] = { kind = "err", items = { zedErr } }
backs = 0
E.frame()
check("MARK a new ZeD error: shown, starting at the screen's bottom edge", mk.visible == true and mk.y == SH and E._mk.phase == "up", mk.y)
check("MARK ... at the notice's x and width", mk.x == el.x and mk.width == el.width, tostring(mk.x) .. "," .. tostring(el.x))
check("MARK ... sent to the back of the UI list as it starts (under the hint strip)", backs == 1, backs)
check("MARK ... red (ZeD's own)", E._mk.kind == "ours" and E._mk.count == 1)
drawn = {}
ZeD_ErrorMarker.prerender(mk)
check("MARK ZeD's own: drawn in the danger red", drawn[1] and drawn[1].r == ZeD.T.danger.r and drawn[1].g == ZeD.T.danger.g)

local function at(ms) NOW = T0 + ms; E.frame() end
at(100)
check("MARK 0.1 s: a fifth of the way up (linear)", mk.y == SH - math.floor(D * 0.2 + 0.5), mk.y)
check("MARK 0.1 s: below the notice's bottom, the notice not moved yet", el.y == REST, el.y)
at(250)
check("MARK 0.25 s: half way up", mk.y == SH - math.floor(D * 0.5 + 0.5), mk.y)
check("MARK 0.25 s: the notice rides on its top", el.y == mk.y - E.NOTE_U and el.y < REST, el.y)
at(500)
check("MARK 0.5 s: at the top, EDGE_U above the bottom", mk.y == SH - D and E._mk.phase == "hold", mk.y)
check("MARK 0.5 s: the notice lifted by the marker's height", el.y == REST - MH, el.y)
at(3499)
check("MARK 3.499 s: still held", mk.y == SH - D and el.y == REST - MH)
at(3750)
check("MARK 3.75 s: half way down", E._mk.phase == "down" and mk.y == SH - math.floor(D * 0.5 + 0.5), mk.y)
check("MARK 3.75 s: the notice comes down with it", el.y == mk.y - E.NOTE_U, el.y)
at(4000)
check("MARK 4 s: gone, the notice back in its place", mk.visible == false and E._mk.phase == nil and el.y == REST, el.y)
check("MARK gone: its count cleared", E._mk.count == 0 and E._mk.kind == nil)

-- another mod's error: gray; repeats while it is up stretch the hold, never start the slide again
T0 = NOW + 10000
at(0)
local modErr = { read = false, count = 1 }
M.sources.ModX = { kind = "err", items = { modErr } }
at(0)
check("MARK another mod's error: shown, gray", mk.visible == true and E._mk.kind == "others")
drawn = {}
ZeD_ErrorMarker.prerender(mk)
check("MARK others': drawn in the badge's gray", drawn[1] and drawn[1].r == ZeD.T.textDim.r)
at(500)
modErr.count = 2
at(2000)
check("MARK a repeat while held: no new slide, the count up", E._mk.phase == "hold" and E._mk.p == 1 and E._mk.count == 2)
at(3600)
check("MARK the hold runs on from the repeat (would have fallen at 3.5 s)", E._mk.phase == "hold" and mk.y == SH - D)
at(4999)
check("MARK ... up to 3 s after the repeat", E._mk.phase == "hold")
at(5250)
check("MARK ... then down", E._mk.phase == "down" and mk.y == SH - math.floor(D * 0.5 + 0.5), mk.y)
modErr.count = 3
at(5250)
check("MARK a new one while falling: back up from where it is, no jump", E._mk.phase == "up" and mk.y == SH - math.floor(D * 0.5 + 0.5), mk.y)
at(5500)
check("MARK ... at the top again a quarter second later", E._mk.phase == "hold" and mk.y == SH - D, mk.y)
zedErr.count = 2
at(5600)
check("MARK one of ZeD's own in the same run: red from then on", E._mk.kind == "ours" and E._mk.count == 4, E._mk.count)
at(9100)
check("MARK all down at last", mk.visible == false and el.y == REST)

-- notes: no marker (the badge only)
T0 = NOW + 10000
M.sources.ModN = { kind = "mods", items = { { read = false } } }
at(0)
check("MARK a note: the notice shows, no marker", el.visible == true and mk.visible == false and E._mk.phase == nil)

-- never in safe mode, with the game's box given back, with no character
SAFE = true
modErr.count = 4
at(100)
check("MARK safe mode: none", mk.visible == false)
SAFE = false
at(200)
check("MARK safe mode off: the error filed in it starts nothing", mk.visible == false)
PIECE = true
modErr.count = 5
at(300)
check("MARK the game's box given back: none (the game's own box shows)", mk.visible == false)
PIECE = false
PLAYER = nil
modErr.count = 6
at(400)
check("MARK no character: none", mk.visible == false)
PLAYER = {}
modErr.count = 7
at(500)
check("MARK back: a new error shows it", mk.visible == true)
SAFE = true
at(600)
check("MARK safe mode while it is up: gone at once", mk.visible == false and E._mk.phase == nil)
SAFE = false

-- a click on the marker opens Messages
opened = 0
check("MARK a click: Messages opens", ZeD_ErrorMarker.onMouseDown(mk, 3, 3) == true and opened == 1)

print(string.format("error_box_sim: %d checks, %d failed", checks, failed))
os.exit(failed == 0 and 0 or 1)
