-- ZeDUI/tools/qa/seg_bar_spread_sim.lua  (Nov 10 2026, Build; the fill bars' cells spread evenly)
-- QA's Mac run measured the Cond column: end cells 5 and 6 px beside 3 px middle ones at 1x, 9 beside 5 at 1.75x. The
-- director: "Keep 10, spread evenly". With no game running, the real Atoms.lua's drawSegBar (framed) paints each bar on
-- a pixel row, through the gap texture's path (seg.png's row: a gap lit, the cell clear, repeated) and through the
-- plain rects. For 5 and 10 cells, inside widths 20 to 400 px, gaps of 1 and 2 px, 0, 3 and all cells lit, it checks:
-- the right number of cells, every cell within a pixel of the others, the cells meeting the frame at both ends, and at
-- most seven draws a bar on the texture path.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/seg_bar_spread_sim.lua
local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]seg_bar_spread_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; if failed <= 20 then print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end end
end
local stub; stub = setmetatable({}, { __index = function() return stub end, __call = function() return stub end })
function require() end
ZeD = { T = { px = function(v) return v end, line = function(v) return v or 1 end, borderW = 1, borderS = { r = 0, g = 0, b = 0 },
              base = { r = 0.5, g = 0.5, b = 0.5 }, accent = { r = 1, g = 0, b = 0 } } }
setmetatable(_G, { __index = function() return stub end })
local f, err = loadfile(ROOT .. "42/media/lua/client/ZeD/Atoms.lua")
local ok, e = pcall(f or error, err)
setmetatable(_G, nil)
check("Atoms.lua loads on the stubs", f and ok, err or e)
local A = ZeD.Atoms
local row, draws = {}, 0
local jo = { DrawSubTextureRGBA = function(_, tex, sx, sy, sw, sh, x, y, w, h)
    draws = draws + 1
    local cellW = sy % 64 + 1; local gap = math.floor(sy / 64) + 1
    for t = 0, w - 1 do if t % (cellW + gap) < gap then row[x + t] = "g" end end end }
local panel = { drawRect = function(_, x, y, ww, h, a, r)
    draws = draws + 1
    for xx = x, x + ww - 1 do row[xx] = (r == 0.5 and "g") or (r == 1 and "L") or (r == 0 and "f") or "d" end end }
for _, texture in ipairs({ true, false }) do
    A.lineJo = texture and function() return jo end or nil
    A.lineTex = function() return {} end
    for _, n in ipairs({ 5, 10 }) do for w = 20, 400 do for _, gap in ipairs({ 1, 2 }) do for _, k in ipairs({ 0, 3, n }) do
        if w >= n * (1 + gap) then
            row, draws = {}, 0
            A.drawSegBar(panel, 0, 0, w + 2, 8, n, k, { r = 1, g = 0, b = 0 }, { r = 0.2, g = 0.2, b = 0.2 }, gap, { framed = true, exactH = true })
            local cells, cur, len = {}, nil, 0
            for xx = 1, w do local c = row[xx]; if c ~= cur then if cur and cur ~= "g" then cells[#cells + 1] = len end; cur, len = c, 0 end; len = len + 1 end
            if cur ~= "g" then cells[#cells + 1] = len end
            local mn, mx = 1e9, 0
            for _, c in ipairs(cells) do mn = math.min(mn, c); mx = math.max(mx, c) end
            local tag = ("%s n=%d w=%d gap=%d k=%d"):format(texture and "texture" or "rects", n, w, gap, k)
            check(tag .. ": " .. n .. " cells", #cells == n, #cells)
            check(tag .. ": within a pixel", mx - mn <= 1, mn .. ".." .. mx)
            check(tag .. ": meets the frame", row[1] ~= "g" and row[w] ~= "g")
            if texture then check(tag .. ": seven draws at most", draws <= 7, draws) end
        end
    end end end end
end
print("seg_bar_spread_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
