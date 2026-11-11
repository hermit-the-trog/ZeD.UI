-- ZeDUI/tools/qa/belt_ring_sim.lua  (Nov 11 2026, Build): the belt's hand rings in segments
-- The director, Nov 11 2026: "segmented bar on primary and secondary circle status bar." The rings round the main
-- and off hand now show a condition in the status bar's five cells (rounded up: ZeD.Atoms.statusSegsLit, its status
-- colour) and a fixed colour's meter (a liquid's) in the fill bar's ten, with a hairline gap in the well's colour
-- between each two, cut like a pie (the director: "you divide a ring like a pie or a clock from the center to the
-- edge ... You don't draw a grid"): each pixel the cell its middle's angle falls in, each gap along a radius.
-- This sim cuts the round drawing and condRing out of the real ZeD_Belt.lua, draws a 56-unit hand ring on a stub
-- panel that paints every rectangle into a pixel grid (no pictures: the rows the pictures are made of), and reads
-- each pixel of the ring's band by its angle from twelve, clockwise:
--   LIT    the lit cells are exactly the first k of n (k as the strips light them), in the status colour: no lit
--          pixel past the k-th boundary's angle, by any margin
--   WHOLE  each lit cell is lit over its span (but for its gap)
--   GAP    a gap in the well's colour at every cell boundary, twelve included
--   RADIAL each gap lies along its radius (every gap pixel within half a hairline of it) and runs the band's depth,
--          inner edge to outer (a square cut across the ring, the first try, fails both)
--   DARK   the cells not lit are the dark cells' colour, none before the k-th boundary
-- at 1x, 1.75x and 2x, and on High contrast's two-unit frames.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/belt_ring_sim.lua
-- It prints FAIL lines and a last line "belt_ring_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]belt_ring_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end

local f = io.open(ROOT .. "42/media/lua/client/ZeD/ZeD_Belt.lua", "rb")
local src = f:read("*a"); f:close()
local a = src:find("local ROUND_DIR", 1, true)
local b = a and src:find("function ZeD_BeltHUD:_drawStrap()", a, true)
local c = b and src:find("local RING_IN, RING_T", b, true)
local d = c and src:find("B._condRing = condRing", c, true)
check("the round drawing and condRing are found in ZeD_Belt.lua", a and b and c and d)
if not (a and b and c and d) then print("belt_ring_sim: " .. checks .. " checks, " .. failed .. " failed"); os.exit(1) end
local chunk = "local B, getTexture, Texture = ...\n" .. src:sub(a, b - 1) .. "\n" .. src:sub(c, d + #"B._condRing = condRing") .. "\nreturn condRing"
local fn, err = loadstring(chunk, "ring")
check("they compile on their own", fn, err)
if not fn then print("belt_ring_sim: " .. checks .. " checks, " .. failed .. " failed"); os.exit(1) end
local condRing = fn({}, function() return nil end, { getSharedTexture = function() return nil end })

local function color(name) return { name = name, r = 0, g = 0, b = 0, a = 1 } end
local function tokens(sc, hc)
    local hair = math.max(1, math.floor(sc + 0.5))
    return { px = function(v) return math.floor(v * sc + 0.5) end, line = function(n) return n * hair end, hair = hair,
             borderW = hc and 2 or 1, base = color("base"), surf3 = color("dark"), borderS = color("frame"),
             positive = color("green"), warning = color("yellow"), danger = color("red"), info = color("blue") }
end
ZeD = { Atoms = { STATUS_SEGS = 5, FILL_SEGS = 10 } }
-- (the real rules, as Atoms.lua has them)
function ZeD.Atoms.statusSegsLit(p) if p <= 0 then return 0 end if p >= 1 then return 5 end return math.max(1, math.ceil(p * 5 - 1e-6)) end
function ZeD.Atoms.fillSegsLit(p, n) n = n or 10; if p <= 0 then return 0 end if p >= 1 then return n end return math.floor(p * n + 1e-6) end
function ZeD.Atoms.statusColor(p)
    local T, lit = ZeD.T, ZeD.Atoms.statusSegsLit(p)
    if lit >= 4 then return T.positive end
    if lit >= 2 then return T.warning end
    return T.danger
end

-- paint, then read the band (the pixels painted in a cell's or the well's colour) by angle
local function draw(sc, hc, f, fixed)
    local T = tokens(sc, hc)
    ZeD.T = T
    local grid = {}
    local p = { drawRect = function(_, x, y, w, h, al, r, g, bb)
                    for yy = y, y + h - 1 do for xx = x, x + w - 1 do grid[yy * 4096 + xx] = r end end
                end,
                drawSubTexture = function() error("no pictures here") end }
    -- (drawRect's colour arguments are the colour table's r, g, b: the stub colours carry their name in r)
    for _, k in ipairs({ "base", "surf3", "borderS", "positive", "warning", "danger", "info" }) do T[k].r = T[k].name end
    local s = T.px(56)
    condRing(p, { x = 0, y = 0, w = s, h = s }, f, T, fixed and T.info or nil)
    return grid, s, T
end
local function angleOf(x, y, s)
    local dx, dy = x + 0.5 - s / 2, y + 0.5 - s / 2
    local deg = math.deg(math.atan2(dx, -dy))
    if deg < 0 then deg = deg + 360 end
    return deg
end

local CASES = {
    { 0, false, 0 }, { 0.05, false, 1 }, { 0.2, false, 1 }, { 0.21, false, 2 }, { 0.55, false, 3 }, { 0.6, false, 3 },
    { 0.92, false, 5 }, { 1, false, 5 }, { 0.65, true, 6 }, { 0.05, true, 0 }, { 1, true, 10 },
}
local TOL = 1e-6   -- degrees: none (a pie's cut: a pixel is the cell its middle falls in)
for _, sc in ipairs({ { 1, false }, { 1.75, false }, { 2, false }, { 1, true } }) do
    for _, cs in ipairs(CASES) do
        local fval, fixed, k = cs[1], cs[2], cs[3]
        local n = fixed and 10 or 5
        local tag = ("%sx%s f=%.2f%s: "):format(sc[1], sc[2] and " HC" or "", fval, fixed and " (a liquid's)" or "")
        local grid, s, T = draw(sc[1], sc[2], fval, fixed)
        local g = T.hair
        local litName = fixed and "blue" or (k >= 4 and "green" or (k >= 2 and "yellow" or "red"))
        local lit, cnt, wrongColor, gapAt = {}, {}, nil, {}
        for j = 0, n - 1 do lit[j], cnt[j] = 0, 0 end
        local strayLit, strayDark = 0, 0
        local offRadius, rmin, rmax = 0, {}, {}
        for key, nm in pairs(grid) do
            local x, y = key % 4096, math.floor(key / 4096)
            local ang = angleOf(x, y, s)
            local j = math.floor(ang / (360 / n)) % n
            if nm == "base" or nm == "dark" or nm == "green" or nm == "yellow" or nm == "red" or nm == "blue" then
                cnt[j] = cnt[j] + 1
                if nm == "base" then
                    -- (the middle as roundShape draws it: floor(s / 2) across, s / 2 down)
                    local dx, dy = x + 0.5 - math.floor(s / 2), y + 0.5 - s / 2
                    local best, bj = nil, nil
                    for jb = 0, n - 1 do
                        local th = math.rad(jb * 360 / n)
                        local ux, uy = math.sin(th), -math.cos(th)
                        if dx * ux + dy * uy > 0 then
                            local off = math.abs(dx * uy - dy * ux)
                            if not best or off < best then best, bj = off, jb end
                        end
                    end
                    if bj then
                        gapAt[bj] = true
                        local r = math.sqrt(dx * dx + dy * dy)
                        rmin[bj] = math.min(rmin[bj] or 1e9, r); rmax[bj] = math.max(rmax[bj] or 0, r)
                    end
                    if not best or best > g / 2 + 1e-6 then offRadius = offRadius + 1 end
                elseif nm ~= "dark" then
                    if nm ~= litName then wrongColor = nm end
                    -- (past the k-th boundary by more than the tolerance: lit where it shouldn't be)
                    local past = ang - k * 360 / n
                    if k < n and past > TOL and ang < 360 - TOL then strayLit = strayLit + 1 end
                    lit[j] = lit[j] + 1
                else
                    local before = k * 360 / n - ang
                    if before > TOL then strayDark = strayDark + 1 end
                end
            end
        end
        check(tag .. "LIT only the first " .. k .. " of " .. n .. " cells", strayLit == 0, strayLit .. " stray")
        check(tag .. "LIT in the right colour", wrongColor == nil, wrongColor)
        local whole = true
        for j = 0, k - 1 do if lit[j] < cnt[j] * 0.6 then whole = false end end
        check(tag .. "WHOLE each lit cell lit across its span", whole)
        check(tag .. "DARK the rest dark (none of the first k)", strayDark == 0, strayDark)
        local gaps = 0
        for jb = 0, n - 1 do if gapAt[jb] then gaps = gaps + 1 end end
        check(tag .. "GAP at all " .. n .. " boundaries", gaps == n, gaps)
        check(tag .. "RADIAL every gap pixel on its radius", offRadius == 0, offRadius)
        local deep = true
        local ft = T.line(6) - 2 * T.line(T.borderW)
        for jb = 0, n - 1 do if not (rmin[jb] and rmax[jb] - rmin[jb] >= ft - 1.5) then deep = false end end
        check(tag .. "RADIAL every gap runs the band's depth", deep)
    end
end

print("belt_ring_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
