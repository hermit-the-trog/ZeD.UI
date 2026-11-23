-- ZeDUI/tools/qa/belt_keys_dash_sim.lua  (QA 4K, Nov 22 2026): the driver's speed keys (the belt's keysOnly panel)
-- drew inside the dash's rect (keys at 2360..2555, y 2065; dash 1120,1804 1600x356). With no game running, the real
-- B.keysClearOfDash is cut out of ZeD_Belt.lua and checked on the 4K numbers: with a dash up the keys' rect stands
-- above the dash's top with the gap and their x is unchanged; with no dash, or a dash that is clear, nothing moves.
-- It also checks _prerender asks it only for the keys-only panel, from the dash's top edge.
-- What it can't show: the game's draw (QA: seated as the driver at 4K, the five keys above the dash, clickable).
-- Run from the repo root: lua51 ZeDUI/tools/qa/belt_keys_dash_sim.lua

local function slurp(p) local f = assert(io.open(p, "rb")); local s = f:read("*a"); f:close(); return (s:gsub("\r", "")) end
local function cut(src, head)
    local a = assert(src:find(head, 1, true), head)
    local _, b = src:find("\nend\n", a, true)
    return src:sub(a, b)
end
local pass, fail = 0, 0
local function ok(c, name) if c then pass = pass + 1 else fail = fail + 1; print("FAIL " .. name) end end

local src = slurp("42/media/lua/client/ZeD/ZeD_Belt.lua")
B = {}
assert(loadstring(cut(src, "function B.keysClearOfDash(")))()

-- the 4K belt panel: home at sx 1600, sy 2040; five speed keys at x 760..955 in the panel (2360..2555 on screen),
-- y 25 (2065 on screen), 36 tall; other boxes lower in the panel that keysOnly does not draw
local SX, SY, GAP = 1600, 2040, 6
local boxes = { { kind = "slot", x = 0, y = 60, w = 80, h = 80 } }
for n = 1, 5 do boxes[#boxes + 1] = { kind = "speed", n = n, x = 760 + (n - 1) * 40, y = 25, w = 35, h = 36 } end
local DASH = { x = 1120, y = 1804, w = 1600, h = 356 }

local function keysRect(sy)
    local x0, y0, x1, y1 = nil, nil, nil, nil
    for _, b in ipairs(boxes) do
        if b.kind == "speed" then
            x0 = math.min(x0 or 1e9, SX + b.x); y0 = math.min(y0 or 1e9, sy + b.y)
            x1 = math.max(x1 or -1e9, SX + b.x + b.w); y1 = math.max(y1 or -1e9, sy + b.y + b.h)
        end
    end
    return x0, y0, x1, y1
end
local function overlaps(ax0, ay0, ax1, ay1, r) return ax0 < r.x + r.w and ax1 > r.x and ay0 < r.y + r.h and ay1 > r.y end

local x0, y0, x1, y1 = keysRect(SY)
ok(x0 == 2360 and x1 == 2555 and y0 == 2065, "the stub keys sit where QA saw them")
ok(overlaps(x0, y0, x1, y1, DASH), "at home the keys overlap the dash (the fault)")

-- a dash up: lifted above its top with the gap
local sy = B.keysClearOfDash(boxes, SY, DASH.y, GAP)
local nx0, ny0, nx1, ny1 = keysRect(sy)
ok(ny1 <= DASH.y - GAP, "with the dash up the keys' bottom stands the gap above the dash's top")
ok(ny1 == DASH.y - GAP, "just above it, not further")
ok(not overlaps(nx0, ny0, nx1, ny1, DASH), "the keys never overlap the dash")
ok(nx0 == x0 and nx1 == x1, "the keys' x is unchanged")
for _, b in ipairs(boxes) do
    if b.kind == "speed" then ok(b.x == 760 + (b.n - 1) * 40, "the boxes are not moved inside the panel (hits follow)") end
end

-- no dash: home
ok(B.keysClearOfDash(boxes, SY, nil, GAP) == SY, "no dash: the keys stay home")
-- a dash whose top is below the keys already: home
ok(B.keysClearOfDash(boxes, SY, 2200, GAP) == SY, "a dash clear below the keys: the keys stay home")
-- no speed keys in the layout: home
ok(B.keysClearOfDash({ boxes[1] }, SY, DASH.y, GAP) == SY, "no speed keys: nothing moves")

-- the wiring: _prerender lifts only the keys-only panel, from the visible dash's top
local pr = cut(src, "function ZeD_BeltHUD:_prerender(")
local a = pr:find("if keysOnly then", 1, true)
local c = pr:find("sy = B.keysClearOfDash(self._boxes, sy, dash:getY(), T.px(6))", 1, true)
ok(a ~= nil and c ~= nil and a < c, "_prerender lifts sy for the keys-only panel")
ok(pr:find("dash:getIsVisible() and dash.vehicle", 1, true) ~= nil, "only a dash that is up counts")
-- (QA: the first frame's dash stands at 0,0 before its _layout) no lift until the dash sits flush on the screen's bottom
local lo = pr:find("local laidOut = dash and math.abs(dash:getY() + dash:getHeight() - (getPlayerScreenTop(pn) + getPlayerScreenHeight(pn))) <= 1", 1, true)
ok(lo ~= nil and c ~= nil and lo < c and pr:find("if dash and laidOut and", 1, true) ~= nil, "no lift until the dash is laid out (flush on the screen's bottom)")
local home = pr:find("self._homeX, self._homeY = sx, sy", 1, true)
ok(c ~= nil and home ~= nil and c < home, "the lifted top becomes the panel's home (visibilityTick keeps it)")

print(string.format("belt_keys_dash_sim: %d checks, %d failed", pass + fail, fail))
if fail > 0 then os.exit(1) end
