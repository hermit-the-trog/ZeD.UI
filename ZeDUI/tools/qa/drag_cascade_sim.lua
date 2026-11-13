-- ZeDUI/tools/qa/drag_cascade_sim.lua  (Nov 11 2026)
-- The drag chip with several items (the director, Nov 11 2026: the dragged item's chip with up to two more chips
-- cascaded behind it). Runs ZeD_DragState's own functions, cut from Molecules.lua, on a panel that records its draws:
--   * one item: one chip, no cascade
--   * two items: one chip behind; three or more: two behind, never more (a stack of 200 nails too)
--   * the chips behind are other kinds first, then more of the same kind; never the front item itself
--   * the behind chips are drawn before the front chip (so they sit behind it), up and to the right, and dimmer
--   * the pick happens once, at the drag's start; cancel and complete clear it
--   * a stack's row (Nov 12 2026): the windows drag rows, and a closed stack's row (or a grid cell) carries the whole
--     stack (InventoryRenderer.dragItems, cut from the file): the chip counts and cascades what the rows carry
--     ("Nails x50", three chips), the drag's items stay the rows; an open stack's head row is one thing; every drag
--     start in the Character and World windows (and the F6 bench) passes what its rows carry
--   * a long count: past 999 the count reads 999+, and the weight gives way when the two would meet
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
function P:drawText(s, x, y) self.draws[#self.draws + 1] = { k = "text", s = s, x = x } end

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

-- A stack's row (Nov 12 2026, review): the windows drag the ROWS (a closed stack's row is its first item; a grid cell
-- is always the whole stack), and the drop moves what InventoryRenderer.dragItems makes of them. The chip counts and
-- cascades those things, so "Nails x50" drags as x50 with chips behind, while the rows stay the rows (the doll and
-- the belt take one thing).
local IRSRC = slurp("42/media/lua/client/ZeD/InventoryRenderer.lua")
ZeD.InventoryRenderer = { isGridKey = function(k) return k == "grid" end }
local dragItems = assert(loadstring("local function containerKeyOf(inv) return inv and inv.key end\n"
    .. cut(IRSRC, "local function dragItems(") .. "return dragItems\n"))()
local function stackOf(kind, n, key)
    local s = { count = n, items = {}, key = key or ("Base." .. kind) }
    for i = 1, n do s.items[i] = item(kind, i) end
    s.rep = s.items[1]
    return s
end
local function content(key, stacks, open)
    local c = { _stacks = {}, _expandedStacks = open or {}, _inventory = { key = key } }
    for _, s in ipairs(stacks) do c._stacks[s.rep] = s end
    return c
end
local function countText()
    for _, e in ipairs(P.draws) do if e.k == "text" and e.s:sub(1, 1) == "x" then return e.s end end
    return nil
end
local function dragRows(c, rows, front)
    local dd = setmetatable({}, ZeD_DragState)
    dd:beginPending(rows, front, 100, 100, dragItems(c, rows, c._inventory))
    dd:activate()
    P.draws = {}
    dd:drawGhost(P)
    local nb = 0
    for _, e in ipairs(P.draws) do if e.k == "rect" then nb = nb + 1 end end
    return dd, nb
end

local nails = stackOf("Nails", 50)
local c1 = content("list", { nails })
d, boxes = dragRows(c1, { nails.rep }, nails.rep)
ok(d.ghostCount == 50, "STACK ROW: a closed stack's row counts its 50 nails (" .. tostring(d.ghostCount) .. ")")
ok(boxes == 3 and #d.ghostBehind == 2, "STACK ROW: two chips behind the front chip")
ok(countText() == "x50", "STACK ROW: the front chip reads x50 (" .. tostring(countText()) .. ")")
ok(#d.items == 1 and d.items[1] == nails.rep, "STACK ROW: the drag's items stay the one row (the doll and the belt take one)")

local c2 = content("grid", { nails }, { [nails.key] = true })
d, boxes = dragRows(c2, { nails.rep }, nails.rep)
ok(d.ghostCount == 50 and boxes == 3, "GRID CELL: a cell is the whole stack, even one opened in the list")

local c3 = content("list", { nails }, { [nails.key] = true })
d, boxes = dragRows(c3, { nails.rep }, nails.rep)
ok(d.ghostCount == 1 and boxes == 1 and countText() == nil, "OPEN STACK: its head row carries one nail: one chip, no count")

local planks, rope = stackOf("Plank", 50), stackOf("Rope", 50)
local c4 = content("list", { nails, planks, rope })
d, boxes = dragRows(c4, { nails.rep, planks.rep, rope.rep }, nails.rep)
ok(d.ghostCount == 150 and countText() == "x150", "THREE STACKS: three closed stacks of 50 read x150 (" .. tostring(countText()) .. ")")
ok(d.ghostBehind[1].kind == "Plank" and d.ghostBehind[2].kind == "Rope", "THREE STACKS: the other kinds behind")

-- A long count (Nov 12 2026, review): a crate of 1000+ nails dragged as one row. The count and the weight share the
-- 58u chip's foot (count from the left, weight right-aligned): the count caps at 999+ and the weight gives way
-- when the two would meet, so they never draw over each other.
local function weightText()
    for _, e in ipairs(P.draws) do if e.k == "text" and e.s:sub(1, 1) ~= "x" then return e end end
    return nil
end
local function footClear()
    local q, w = nil, weightText()
    for _, e in ipairs(P.draws) do if e.k == "text" and e.s:sub(1, 1) == "x" then q = e end end
    if not (q and w) then return true end
    return q.x + ZeD.TM:MeasureStringX(T.fontF3, q.s) < w.x
end
d, boxes = dragRows(c1, { nails.rep }, nails.rep)
ok(weightText() ~= nil and footClear(), "SHORT COUNT: x50 keeps the weight beside it, clear of it")
local crate = stackOf("Nails", 1200)
d, boxes = dragRows(content("list", { crate }), { crate.rep }, crate.rep)
ok(d.ghostCount == 1200 and countText() == "x999+", "LONG COUNT: 1200 nails read x999+ (" .. tostring(countText()) .. ")")
ok(footClear(), "LONG COUNT: the count and the weight never overlap")
ok(weightText() == nil, "LONG COUNT: the weight gives way to the count")

-- every press in the windows (and the F6 bench) hands beginPending what the rows carry
for _, f in ipairs({ "ZeD_CharacterWindow.lua", "ZeD_WorldWindow.lua", "TestInventory.lua" }) do
    local src = slurp("42/media/lua/client/ZeD/" .. f)
    local n, carried, at = 0, 0, 1
    while true do
        local a = src:find("self._drag:beginPending(", at, true)
        if not a then break end
        n = n + 1
        local depth, i = 0, a + #"self._drag:beginPending"
        repeat
            local ch = src:sub(i, i)
            if ch == "(" then depth = depth + 1 elseif ch == ")" then depth = depth - 1 end
            i = i + 1
        until depth == 0 or i > #src
        if src:sub(a, i):find("ZeD.InventoryRenderer.dragItems(self, ", 1, true) then carried = carried + 1 end
        at = i
    end
    ok(n == 4 and carried == 4, f .. ": all " .. n .. " drag starts pass what the rows carry (" .. carried .. ")")
end

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
