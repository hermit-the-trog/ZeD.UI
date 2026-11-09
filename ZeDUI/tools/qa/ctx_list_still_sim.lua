-- ZeDUI/tools/qa/ctx_list_still_sim.lua  (Nov 8 2026): the list-style right-click menu opens a row's submenu when the
-- pointer rests on it perfectly still, with no game running. QA's in-game script (zedqa_ctx_overlap.lua) logged "a pointer
-- perfectly still on Eat: submenu NOT opened" after commit 8cb7f8ca. The real ZeD_ContextList.lua is loaded on stubs; the
-- game runs a panel's update() only every 100 ms (UIManager.doTick), the frames every 16 ms, and the clock is the game's.
--   STILL    the pointer goes to another row, then onto Eat and stays still: the submenu opens within 180 ms + one update
--   KEY      the same with a key the menu does not use pressed during the rest (a modifier, the QA bridge's keys): it
--            still opens (it waited for the next pointer move before)
--   PADKEY   the menu's own keys still take the selection: Down then a still pointer does not open the pointed row's submenu
--   NOROW    a pointer resting off the rows opens nothing
-- Run from the repo root: lua51 ZeDUI/tools/qa/ctx_list_still_sim.lua ["path to ZeD_ContextList.lua"]
local SRC = arg and arg[1] or "42/media/lua/client/ZeD/ZeD_ContextList.lua"
local PANEL = "42/media/lua/client/ZeD/ZeD_Panel.lua"

local function slurp(p) local f = assert(io.open(p, "rb")); local s = f:read("*a"); f:close(); return (s:gsub("\r", "")) end
local function cut(src, head)
    local a = assert(src:find(head, 1, true), head)
    local _, b = src:find("\nend\n", a, true)
    return src:sub(a, b)
end
local pass, fail = 0, 0
local function ok(c, name) if c then pass = pass + 1 else fail = fail + 1; print("FAIL " .. name) end end

-- ---- the stubs (as ctx_overlap_sim.lua)
local SW, SH = 1920, 1080
local MX, MY = -1, -1
local NOW = 1000
function getMouseX() return MX end
function getMouseY() return MY end
function getTimestampMs() return NOW end
function getCore() return { getScreenWidth = function() return SW end, getScreenHeight = function() return SH end } end
require = function() end
Keyboard = { KEY_UP = 200, KEY_DOWN = 208, KEY_LEFT = 203, KEY_RIGHT = 205, KEY_RETURN = 28, KEY_ESCAPE = 1, KEY_LSHIFT = 42 }
local noop = function() end
ZeD_Panel = {}
local P = ZeD_Panel
function P:derive(name) local c = setmetatable({}, { __index = self }); c.Type = name; return c end
function P:new(x, y, w, h) return { x = x, y = y, w = w, h = h, _hitZones = {} } end
for _, n in ipairs({ "drawRect", "drawText", "drawTextureScaledAspect", "setWantKeyEvents", "addToUIManager",
                     "removeFromUIManager", "bringToTop", "update", "drawRectBorder" }) do P[n] = noop end
function P:getMouseX() return MX end
function P:getMouseY() return MY end
function P:getAbsoluteX() return 0 end
function P:getAbsoluteY() return 0 end
local panelSrc = slurp(PANEL)
for _, head in ipairs({ "function ZeD_Panel:hitTest(", "function ZeD_Panel:hitZoneAt(",
                        "function ZeD_Panel:clearHitZones(", "function ZeD_Panel:addHitZone(" }) do
    assert(loadstring(cut(panelSrc, head)))()
end
local COLOR = { r = 1, g = 1, b = 1, a = 1 }
ZeD = {}
ZeD.T = setmetatable({ px = function(v) return v end, hair = 1, fontF1 = 1, fontF2 = 2, fontF1H = 10, fontF2H = 10,
                       selectionA = 0.3, disabledAlpha = 0.5, checkboxSz = 10 },
                     { __index = function() return COLOR end })
ZeD.TM = { MeasureStringX = function(_, _, s) return #tostring(s) * 6 end, getFontHeight = function() return 10 end }
ZeD.Atoms = setmetatable({ truncateText = function(_, s) return s end, textCase = function(s) return s end,
                           hoverReady = function() return false end },
                         { __index = function() return noop end })
ZeD.Focus = { mark = function() return false end, drawOverlay = noop }
ZeD.ContextMenu = { Registry = { highlight = noop, getTargetDisplay = function() return "target", nil end } }
assert(loadstring(slurp(SRC)))()

-- ---- the menu: QA's apple at the right edge (Eat, a rule, Debug with a submenu, Drop), opened by the mouse
local function leaf(name) return { name = name, category = "a", onFire = noop } end
local function build()
    local eatKids = { leaf("All"), leaf("1/2"), leaf("1/4") }
    local dbgKids = { leaf("Dbg 1"), leaf("Dbg 2") }
    local tree = { { name = "Eat", category = "a", children = eatKids }, { name = "Debug", category = "b", children = dbgKids },
                   leaf("Place Item"), leaf("Drop") }
    MX, MY = SW - 52, 360
    local m = ZeD_ContextList:new(0, "cursor", MX, MY, { "apple" }, tree, nil)
    m:open()
    m:prerender()
    return m
end
local function zoneOf(m, li, ri)
    for _, z in ipairs(m._hitZones) do if z.id == "row:" .. li .. ":" .. ri then return z end end
end
-- the game: a frame every 16 ms (prerender), a UI update every 100 ms
local nextUpdate = 0
local function run(m, ms)
    local stop = NOW + ms
    while NOW < stop do
        NOW = NOW + 16
        if NOW >= nextUpdate then m:update(); nextUpdate = NOW + 100 end
        m:prerender()
    end
end
local function center(z) return z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2) end

-- STILL
local m = build()
run(m, 300)
local dbg, eat = zoneOf(m, 1, 3), zoneOf(m, 1, 1)
MX, MY = center(dbg); run(m, 100)
MX, MY = center(eat); run(m, 400)
ok(m._levels[2] ~= nil and m._levels[2].items[1].name == "All", "STILL the pointer still on Eat opens Eat's submenu")

-- KEY: a key the menu does not use, pressed while the pointer rests
m = build()
run(m, 300)
dbg, eat = zoneOf(m, 1, 3), zoneOf(m, 1, 1)
MX, MY = center(dbg); run(m, 100)
MX, MY = center(eat); run(m, 50)
m:onKeyPress(Keyboard.KEY_LSHIFT)
run(m, 400)
ok(m._levels[2] ~= nil and m._levels[2].items[1].name == "All", "KEY a key the menu ignores does not stop the still pointer opening Eat")
ok(m._nav == "mouse", "KEY the mouse keeps the selection (nav " .. tostring(m._nav) .. ")")

-- PADKEY: the menu's own key moves the selection; the still pointer then opens nothing under it
m = build()
run(m, 300)
dbg, eat = zoneOf(m, 1, 3), zoneOf(m, 1, 1)
MX, MY = center(dbg); run(m, 100)
MX, MY = center(eat); run(m, 50)
m:onKeyPress(Keyboard.KEY_DOWN)
run(m, 400)
ok(m._levels[2] == nil, "PADKEY after Down the pointer's row does not open (the keyboard has the selection)")
ok(m._nav == "key", "PADKEY the menu's own key hands it the selection")

-- NOROW: resting on the heading opens nothing
m = build()
run(m, 300)
MX, MY = m._levels[1].x + 10, m._levels[1].y + 6
run(m, 400)
ok(m._levels[2] == nil, "NOROW a pointer resting on the heading opens nothing")

print(string.format("ctx_list_still_sim: %d pass, %d fail", pass, fail))
os.exit(fail == 0 and 0 or 1)
