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

print(string.format("error_box_sim: %d checks, %d failed", checks, failed))
os.exit(failed == 0 and 0 or 1)
