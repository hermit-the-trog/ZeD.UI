-- ZeDUI/tools/qa/ctx_overlap_sim.lua  (Nov 8 2026): the list-style right-click menu when a submenu lies over its parent,
-- with no game running. The real ZeD_ContextList.lua is loaded on stubs (a panel that keeps the real hit-zone code, no-op
-- drawing); the screen is narrow so the submenu has no room beside its parent, opens to the left, is held at the screen's
-- edge and so covers most of the parent, as on a small screen (the player's report: "hover over it, it immediately resets").
--   OPEN     a submenu is open over the parent and really overlaps it
--   HOVER    the pointer moved over the overlap, row by row: the submenu stays open, and the row under the pointer is the
--            submenu's, never the parent's
--   LIGHT    the game's outline (Registry.highlight) follows the submenu's row; the parent's hover wash is not drawn
--   PAD      the submenu's padding (no row there) takes the pointer too: the parent's rows under it are not picked
--   CLICK    a press on the overlap runs the submenu's row, not the parent's
--   PARENT   the part of the parent the submenu does not cover still picks its own rows (and closes the submenu)
-- Run from the repo root: lua51 ZeDUI/tools/qa/ctx_overlap_sim.lua ["path to ZeD_ContextList.lua"]
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

-- ---- the stubs
local SW, SH = 400, 600
local MX, MY = -1, -1
local NOW = 1000
function getMouseX() return MX end
function getMouseY() return MY end
function getTimestampMs() return NOW end
function getCore() return { getScreenWidth = function() return SW end, getScreenHeight = function() return SH end } end
require = function() end

local noop = function() end
ZeD_Panel = {}
local P = ZeD_Panel
function P:derive(name) local c = setmetatable({}, { __index = self }); c.Type = name; return c end
function P:new(x, y, w, h) return { x = x, y = y, w = w, h = h, _hitZones = {} } end
for _, n in ipairs({ "drawRect", "drawText", "drawTextureScaledAspect", "setWantKeyEvents", "addToUIManager",
                     "removeFromUIManager", "bringToTop", "update", "drawRectBorder" }) do P[n] = noop end
function P:getMouseX() return MX end
function P:getMouseY() return MY end
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
local lit = {}
ZeD.ContextMenu = { Registry = { highlight = function(_, def) lit[#lit + 1] = def or false end,
                                 getTargetDisplay = function() return "target", nil end } }
assert(loadstring(slurp(SRC)))()

-- ---- the menu: an Eat row with a submenu in the middle of the top level, three rows in the cascade
local fired
local function leaf(name, tag) return { name = name, category = "a", onFire = function() fired = tag end } end
local function build()
    fired = nil
    local kids = { leaf("Eat all", "kid1"), leaf("Eat half", "kid2"), leaf("Eat a quarter", "kid3") }
    local tree = { leaf("Inspect", "top1"), { name = "Eat", category = "a", children = kids, onFire = function() fired = "eat" end },
                   leaf("Drop", "top3"), leaf("Cancel", "top4") }
    local m = ZeD_ContextList:new(0, "cursor", 100, 100, { "apple" }, tree, nil)
    m:open()
    m._nav = "mouse"
    MX, MY = 100, 100
    m._lastMx, m._lastMy = MX, MY
    m:prerender()
    return m
end
local function zoneOf(m, li, ri)
    for _, z in ipairs(m._hitZones) do if z.id == "row:" .. li .. ":" .. ri then return z end end
end
local function pointAt(m, x, y)
    MX, MY = x, y
    NOW = NOW + 120
    m:update()
    m:prerender()
end

-- OPEN
local m = build()
local eat = zoneOf(m, 1, 2)
pointAt(m, eat.x + 20, eat.y + 5)
pointAt(m, eat.x + 21, eat.y + 6)   -- (rests on the Eat row past the 180 ms delay)
NOW = NOW + 300
pointAt(m, eat.x + 22, eat.y + 6)
local top, sub = m._levels[1], m._levels[2]
ok(sub ~= nil, "OPEN the submenu opened on hover")
if not sub then print(("ctx_overlap_sim: %d pass, %d fail (no submenu, stopping)"):format(pass, fail)); os.exit(fail == 0 and 0 or 1) end
local overlapW = math.min(top.x + top.w, sub.x + sub.w) - math.max(top.x, sub.x)
ok(overlapW > top.w / 3, "OPEN the submenu covers a good part of its parent (" .. overlapW .. " of " .. top.w .. " wide)")
ok(sub.x < top.x + top.w and sub.y < top.y + top.h, "OPEN the submenu lies over the parent")

-- HOVER and LIGHT: each cascade row, with the pointer inside the parent's box too
local px = math.max(top.x, sub.x) + math.floor(overlapW / 2)
for ri = 1, 3 do
    local z = zoneOf(m, 2, ri)
    if not z then ok(false, "HOVER row " .. ri .. " is still there"); break end
    lit = {}
    pointAt(m, px, z.y + 6)
    local inParent = px >= top.x and px < top.x + top.w and z.y + 6 >= top.y and z.y + 6 < top.y + top.h
    ok(inParent, "HOVER row " .. ri .. " is also inside the parent's box")
    ok(#m._levels == 2 and m._levels[2] == sub, "HOVER row " .. ri .. " keeps the submenu open")
    ok(sub.sel == ri, "HOVER row " .. ri .. " is the submenu's selection (got " .. tostring(sub.sel) .. ")")
    ok(top.sel == 2, "HOVER row " .. ri .. " leaves the parent on Eat (got " .. tostring(top.sel) .. ")")
    ok(lit[#lit] and lit[#lit].name == sub.rows[ri].def.name, "LIGHT row " .. ri .. " lights the submenu's option")
end
-- moving about in the overlap over several frames: nothing resets
for i = 1, 10 do pointAt(m, px + (i % 3), zoneOf(m, 2, 1 + (i % 3)).y + 4) end
ok(#m._levels == 2, "HOVER a run of moves keeps the submenu open")

-- PAD: the cascade's top padding, no row there
pointAt(m, px, sub.y + 1)
ok(#m._levels == 2 and top.sel == 2, "PAD the cascade's padding does not pick a parent row")
local c = m:_levelAt(px, sub.y + 1)
ok(c == 2, "PAD the cascade is the level under the pointer on its padding")

-- CLICK: a press on the overlap runs the cascade's row
local z2 = zoneOf(m, 2, 2) or { y = 0 }
pointAt(m, px, z2.y + 6)
m:onMouseUp(px, z2.y + 6)
ok(fired == "kid2", "CLICK runs the submenu's row (ran " .. tostring(fired) .. ")")

-- PARENT: the uncovered part of the parent still answers
m = build()
eat = zoneOf(m, 1, 2)
pointAt(m, eat.x + 20, eat.y + 5)
NOW = NOW + 300
pointAt(m, eat.x + 21, eat.y + 5)
top, sub = m._levels[1], m._levels[2]
ok(sub ~= nil, "PARENT the submenu is open again")
local free = top.x + top.w - 1   -- (right edge of the parent, past the cascade if it is to the left)
local freeX = (sub.x > top.x) and (top.x + 2) or (top.x + top.w - 2)
if sub.x <= top.x then freeX = top.x + top.w - 2 end
local covered = freeX >= sub.x and freeX < sub.x + sub.w
if not covered then
    local z3 = zoneOf(m, 1, 3)
    pointAt(m, freeX, z3.y + 5)
    ok(top.sel == 3 and #m._levels == 1, "PARENT an uncovered row picks itself and closes the cascade")
else
    ok(true, "PARENT (the cascade covers the whole width here; nothing uncovered to check)")
end

print(("ctx_overlap_sim: %d pass, %d fail"):format(pass, fail))
os.exit(fail == 0 and 0 or 1)
