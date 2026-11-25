-- ZeDUI/tools/qa/scrollbar_edge_sim.lua  (Nov 25 2026, Build; the director: "one consistent 1 pixel line on the edges")
--   LIVE   ZeD_ScrollbarState (cut from Molecules.lua): width and arrowH follow the token after a text-size or UI-scale
--          change unless a caller set them
--   EDGE   draw puts the bar's outline one hairline past its right, top and bottom, onto the frame's line; inRight /
--          inTop / inBottom opt a side out; over a grow box the bottom stays; the press area is unchanged
--   WIDTH  the odd bars are the standard 14u (Animals x3, the prompt, the Workshop folder list)
-- Run from the repo root:  lua51 ZeDUI/tools/qa/scrollbar_edge_sim.lua

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]scrollbar_edge_sim%.lua$", "")
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

local MOL = readFile(Z .. "Molecules.lua")
local src = cut(MOL, "ZeD_ScrollbarState = {}", "\nZeD.Molecules.ScrollbarState = ZeD_ScrollbarState")
check("found", src ~= nil)
local scale = 1
local function px(n) return math.floor(n * scale + 0.5) end
local C = { r = 0, g = 0, b = 0, a = 1 }
ZeD = { T = { sp = { scrollbarW = 14, scrollGripOff = 3, scrollGripMar = 6 }, px = px, borderS = C, surf4 = C, accent = C,
              accentBright = C, textDim = C, surf3 = C }, Molecules = {} }
local tracks, arrows = {}, {}
ZeD.Atoms = {
    drawScrollTrack = function(p, x, y, w, h) tracks[#tracks + 1] = { x = x, y = y, w = w, h = h } end,
    drawScrollArrow = function(p, x, y, size, dir) arrows[#arrows + 1] = { x = x, y = y, s = size, d = dir } end,
}
if src then
    local fn, e = loadstring(src, "sb")
    check("loads", fn ~= nil, e)
    if fn then fn() end
end
local SB = ZeD_ScrollbarState
local panel = { getMouseX = function() return -99 end, getMouseY = function() return -99 end,
                drawRect = function() end, drawRectBorder = function() end }

print("-- LIVE")
if SB then
    ZeD.T.sp.scrollbarW = 14
    local sb = SB:new()
    check("LIVE: a new bar reads the token", sb.width == 14 and sb.arrowH == 14)
    ZeD.T.sp.scrollbarW = 25   -- (Large text, a bigger UI scale)
    check("LIVE: after a size change it follows", sb.width == 25 and sb.arrowH == 25)
    sb.width = 10
    check("LIVE: a width a caller set stays", sb.width == 10 and sb.arrowH == 25)
    check("LIVE: methods still found", type(sb.draw) == "function" and type(sb.hitY) == "function")
end

print("-- EDGE")
if SB then
    ZeD.T.sp.scrollbarW = 14
    scale = 2
    local sb = SB:new()
    sb.x, sb.y, sb.height, sb.visible = 100, 50, 200, true
    tracks, arrows = {}, {}
    sb:draw(panel)
    local hl = px(1)
    check("EDGE: the up arrow starts a hairline above", arrows[1] and arrows[1].y == 50 - hl, arrows[1] and arrows[1].y)
    check("EDGE: the arrows a hairline wider (the right line on the frame's)", arrows[1] and arrows[1].s == 14 + hl)
    local t = tracks[1]
    check("EDGE: the track's right line on the frame's line", t and t.x + t.w - hl == 100 + 14, t and (t.x + t.w - hl))
    local dn = arrows[2]
    check("EDGE: the down arrow ends a hairline below", dn and dn.y + dn.s == 50 + 200 + hl, dn and (dn.y + dn.s))
    check("EDGE: the press area is the bar's own", sb:hitY(100 + 14, 60) == nil and sb:hitY(100, 50) == 0)
    sb.inRight, sb.inTop = true, true
    tracks, arrows = {}, {}
    sb:draw(panel)
    check("EDGE: inRight / inTop: drawn in its rect there", arrows[1].y == 50 and arrows[1].s == 14 and tracks[1].x + tracks[1].w == 114)
    sb.inRight, sb.inTop = nil, nil
    local edgeP = { getMouseX = panel.getMouseX, getMouseY = panel.getMouseY, drawRect = panel.drawRect, drawRectBorder = panel.drawRectBorder,
                    getWidth = function() return 114 end, getHeight = function() return 250 end }
    tracks, arrows = {}, {}
    sb:draw(edgeP)
    check("EDGE: at the panel's own edge nothing is drawn past it", tracks[1].x + tracks[1].w == 114 and arrows[2].y + arrows[2].s == 250 and arrows[1].y == 50 - px(1))
    sb.reserveBottom = 20
    tracks, arrows = {}, {}
    sb:draw(panel)
    check("EDGE: over a grow box the bottom stays", arrows[2].y + arrows[2].s == 50 + 200 - 20, arrows[2].y + arrows[2].s)
    scale = 1
end
check("EDGE: Messages' right edge opts out", has(readFile(Z .. "ZeD_MessagesWindow.lua"), "sb.inRight = true"))
check("EDGE: the item card over a tab at its right opts out", has(readFile(Z .. "ItemCard.lua"), 'self._sb.inRight = (self.overlayEdge == "right")'))

print("-- WIDTH")
local AN = readFile(Z .. "AnimalsTab.lua")
check("WIDTH: Animals has no narrowed bar", not has(AN, "scrollW - T.px(2)"))
check("WIDTH: the prompt's bar is 14u", has(readFile(Z .. "ZeD_Prompt.lua"), "g.sb = { x = w - padR - sbW, y = tbH + padT, w = sbW, h = viewH }"))
check("WIDTH: the Workshop folder list's bar is 14u", has(readFile(Z .. "ZeD_MainMenuWorkshop.lua"), '"ws:ftrack", x + w - T.px(1), vy, sbW, vh,'))

print("scrollbar_edge_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
