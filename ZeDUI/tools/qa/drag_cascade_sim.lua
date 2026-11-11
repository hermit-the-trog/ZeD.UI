-- ZeDUI/tools/qa/drag_cascade_sim.lua  (Nov 11 2026)
-- The drag chip with several items (the director, Nov 11 2026: the dragged item's chip with up to two more chips
-- cascaded behind it). Runs ZeD_DragState's own functions, cut from Molecules.lua, on a panel that records its draws:
--   * one item: one chip, no cascade
--   * two items: one chip behind; three or more: two behind, never more (a stack of 200 nails too)
--   * the chips behind are other kinds first, then more of the same kind; never the front item itself
--   * the behind chips are drawn before the front chip (so they sit behind it), up and to the right, and dimmer
--   * the pick happens once, at the drag's start; cancel and complete clear it
-- Run: lua.exe ZeDUI/tools/qa/drag_cascade_sim.lua (from the repo root)

local function slurp(p) local f = assert(io.open(p, "rb")); local s = f:read("*a"); f:close(); return (s:gsub("\r", "")) end
local function cut(src, head)
    local a = assert(src:find(head, 1, true), head)
    local _, b = src:find("\nend\n", a, true)
    return src:sub(a, b)
end
local SRC = slurp("42/media/lua/client/ZeD/Molecules.lua")

local pass, fail = 0, 0
local function ok(c, name) if c then pass = pass + 1 else fail = fail + 1; print("FAIL " .. name) end end

-- the engine and ZeD pieces drawGhost reads
ZeD = { T = {}, TM = {} }
local T = ZeD.T
T.px = function(n) return n end
T.surf2 = { r = 0.2, g = 0.2, b = 0.2 }
T.accent = { r = 0.3, g = 0.6, b = 0.55 }
T.borderS = { r = 0.4, g = 0.4, b = 0.4 }
T.textSec = { r = 0.7, g = 0.7, b = 0.7 }
T.textDim = { r = 0.5, g = 0.5, b = 0.5 }
T.fontF3 = "f3"
ZeD.TM.MeasureStringY = function() return 10 end
ZeD.TM.MeasureStringX = function(_, _, s) return #s * 6 end
ISMouseDrag = {}

ZeD_DragState = {}
ZeD_DragState.__index = ZeD_DragState
ZeD_DragState.BEHIND_MAX = 2
for _, h in ipairs({ "function ZeD_DragState.pickBehind(", "function ZeD_DragState:beginPending(",
                     "function ZeD_DragState:activate()", "function ZeD_DragState:drawGhost(",
                     "function ZeD_DragState:cancel()", "function ZeD_DragState:complete()" }) do
    assert(loadstring(cut(SRC, h)))()
end

local function item(kind, n)
    return { kind = kind, n = n, tex = "tex_" .. kind .. "_" .. tostring(n),
             getFullType = function(self) return "Base." .. self.kind end,
             getTex = function(self) return self.tex end,
             getUnequippedWeight = function() return 0.1 end }
end
local P = { draws = {} }
function P:getAbsoluteX() return 0 end
function P:getAbsoluteY() return 0 end
function P:drawRect(x, y, w, h, a) self.draws[#self.draws + 1] = { k = "rect", x = x, y = y } end
function P:drawRectBorder(x, y, w, h, a, r, g, b) self.draws[#self.draws + 1] = { k = "border", x = x, y = y, r = r } end
function P:drawTextureScaledAspect(tex, x, y, w, h, a) self.draws[#self.draws + 1] = { k = "tex", tex = tex, x = x, y = y, a = a } end
function P:drawText(s, x, y) self.draws[#self.draws + 1] = { k = "text", s = s } end

local function drag(items, front)
    local d = setmetatable({}, ZeD_DragState)
    d:beginPending(items, front, 100, 100)
    d:activate()
    P.draws = {}
    d:drawGhost(P)
    local texs, boxes = {}, 0
    for _, e in ipairs(P.draws) do
        if e.k == "tex" then texs[#texs + 1] = e end
        if e.k == "rect" then boxes = boxes + 1 end
    end
    return d, texs, boxes
end

-- one item
local a = item("Axe", 1)
local d, texs, boxes = drag({ a }, a)
ok(boxes == 1 and #texs == 1 and #d.ghostBehind == 0, "ONE: one chip, no cascade")

-- two items of different kinds
local b = item("Nails", 1)
d, texs, boxes = drag({ a, b }, a)
ok(boxes == 2 and #texs == 2, "TWO: two chips")
ok(texs[1].tex == b.tex and texs[2].tex == a.tex, "TWO: the other item's chip is drawn first, the dragged item's last (in front)")
ok(texs[1].x > texs[2].x and texs[1].y < texs[2].y, "TWO: the chip behind sits up and to the right")
ok(texs[1].a < texs[2].a, "TWO: the chip behind is dimmer")

-- many of mixed kinds: other kinds first, at most two behind
local items = { a, item("Axe", 2), item("Axe", 3), item("Hammer", 1), item("Plank", 1), item("Rope", 1) }
d, texs, boxes = drag(items, a)
ok(boxes == 3 and #d.ghostBehind == 2, "MANY: three chips at most")
ok(d.ghostBehind[1].kind == "Hammer" and d.ghostBehind[2].kind == "Plank", "MANY: other kinds before more of the same kind")
local front = false
for _, it in ipairs(d.ghostBehind) do if it == a then front = true end end
ok(not front, "MANY: the front item is never behind itself")
local count = false
for _, e in ipairs(P.draws) do if e.k == "text" and e.s == "x6" then count = true end end
ok(count, "MANY: the front chip keeps the count (x6)")

-- a stack of one kind: still shows as several
local stack = {}
for i = 1, 200 do stack[i] = item("Nails", i) end
d, texs, boxes = drag(stack, stack[1])
ok(boxes == 3 and d.ghostBehind[1] ~= stack[1] and d.ghostBehind[2] ~= stack[1], "STACK: 200 of one kind show three chips")

-- picked once, cleared after
local before = d.ghostBehind
P.draws = {}
d:drawGhost(P)
ok(d.ghostBehind == before, "ONCE: drawing again reuses the pick")
d:cancel()
ok(d.ghostBehind == nil, "CLEAR: cancel clears the chips behind")
d = drag({ a, b }, a)
d:complete()
ok(d.ghostBehind == nil, "CLEAR: complete clears the chips behind")

print(string.format("drag_cascade_sim: %d pass, %d fail", pass, fail))
os.exit(fail == 0 and 0 or 1)
