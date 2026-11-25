-- ZeDUI/tools/qa/figure_scroll_cut_sim.lua  (Nov 25 2026, Build; the director: "Why does the avatar get smaller as you
-- scroll down in the paper doll equipment tab? Shouldn't it just scroll away?")
--   CUT    win._fitFigureCut (cut from ZeD_CharacterWindow): a frame partly scrolled out keeps the figure's scale
--          (world units a pixel), the element only the part showing, and the figure where the whole frame draws it
--   WIRED  the Equip doll and the Identity photo both place their model through it
-- Run from the repo root:  lua51 ZeDUI/tools/qa/figure_scroll_cut_sim.lua

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]figure_scroll_cut_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function readFile(p)
    local f = io.open(p, "rb")
    if not f then return "" end
    local s = f:read("*a"); f:close()
    return (s:gsub("\r\n", "\n"))
end
local function cut(src, from, to)
    local a = string.find(src, from, 1, true)
    if not a then return nil end
    local b = string.find(src, to, a, true)
    return b and string.sub(src, a, b + #to - 1) .. "\n" or nil
end
local function has(s, x) return string.find(s, x, 1, true) ~= nil end

local CW = readFile(Z .. "ZeD_CharacterWindow.lua")
local src = cut(CW, "    win._fitFigureCut = function(m, x, frameY, w, fullH, ct, cb, z0, yo0)", "\n    end\n")
check("CUT: found", src ~= nil)
ZeD = { T = { px = function(n) return n end } }
local win = {}
if src then
    local fn, e = loadstring("local win = ...\n" .. src, "cut")
    check("CUT: loads", fn ~= nil, e)
    if fn then fn(win) end
end
local S = math.sqrt(2048)
local function model()
    local m = {}
    function m:setX(v) self.x = v end
    function m:setY(v) self.y = v end
    function m:setWidth(v) self.w = v end
    function m:setHeight(v) self.h = v end
    function m:setZoom(v) self.z = v end
    function m:setYOffset(v) self.yo = v end
    return m
end
-- where a world point (the figure's y in world units, up) lands on screen, in px from the screen top:
-- the camera is 2 * (25 - z) / S world units tall, centred on the element, the figure moved by yo
local function screenY(m, worldY)
    local yo = (m.yo == 0) and -0.5 or m.yo
    local unitsTall = 2 * (25 - m.z) / S
    local pxPerUnit = m.h / unitsTall
    local centre = m.y + m.h / 2
    return centre - (worldY + yo) * pxPerUnit, pxPerUnit
end
if win._fitFigureCut then
    local whole = model()
    win._fitFigureCut(whole, 10, 100, 200, 400, 0, 0, 0, 0)
    check("CUT: unscrolled, as before (zoom 0, the game's own offset)", whole.y == 100 and whole.h == 400 and whole.z == 0 and whole.yo == 0)
    local headW, scaleW = screenY(whole, 0.9)
    local feetW = screenY(whole, 0)
    for _, c in ipairs({ { 80, 0 }, { 0, 120 }, { 150, 60 } }) do
        local m = model()
        local ok = win._fitFigureCut(m, 10, 100, 200, 400, c[1], c[2], 0, 0)
        local head, scale = screenY(m, 0.9)
        local feet = screenY(m, 0)
        local tag = "cut " .. c[1] .. "/" .. c[2]
        check("CUT: " .. tag .. ": shows", ok == true and m.y == 100 + c[1] and m.h == 400 - c[1] - c[2])
        check("CUT: " .. tag .. ": the same size (no shrinking)", math.abs(scale - scaleW) < 1e-6, scale .. " vs " .. scaleW)
        check("CUT: " .. tag .. ": the head and feet where the whole frame puts them", math.abs(head - headW) < 1e-6 and math.abs(feet - feetW) < 1e-6)
    end
    local b = model()
    win._fitFigureCut(b, 0, 0, 100, 160, 0, 0, 19, -0.875)
    local hB, sB = screenY(b, 1.6)
    local b2 = model()
    win._fitFigureCut(b2, 0, 0, 100, 160, 50, 0, 19, -0.875)
    local hB2, sB2 = screenY(b2, 1.6)
    check("CUT: the bust too", math.abs(sB - sB2) < 1e-6 and math.abs(hB - hB2) < 1e-6)
    check("CUT: a sliver hides", win._fitFigureCut(model(), 0, 0, 100, 160, 80, 76, 0, 0) == false)
end

print("-- WIRED")
check("WIRED: the Equip doll", has(CW, "win._fitFigureCut(model, T.px(TAB_STRIP_W) + ph.x, bY + ph.y, ph.w, ph.h,"))
check("WIRED: the Identity photo", has(CW, "win._fitFigureCut(identityModel, T.px(TAB_STRIP_W) + pr.x, win:getBodyY() + pr.y, pr.w, pr.h,"))
check("WIRED: no shrink left (the height set to the part showing with zoom 0)", not has(CW, "model:setHeight(bot - top)"))

print("figure_scroll_cut_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
