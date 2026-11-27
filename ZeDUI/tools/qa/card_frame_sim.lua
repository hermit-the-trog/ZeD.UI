-- ZeDUI/tools/qa/card_frame_sim.lua  (Nov 26 2026, Build; the director: an item card over a tab card has a border)
-- ZeD_ItemCard:drawOverlayEdge is cut from ItemCard.lua and run on a stub card: with overlayFrame it draws the 1 px
-- line on all four sides; with only overlayEdge, the one side as before; with neither, nothing. Both windows set
-- overlayFrame while the drawer shows a tab under the card.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/card_frame_sim.lua
local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]card_frame_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function read(rel)
    local f = io.open(ROOT .. rel, "rb"); if not f then return "" end
    local s = f:read("*a"):gsub("\r\n", "\n"); f:close(); return s
end
local src = read("42/media/lua/client/ZeD/ItemCard.lua")
local body = src:match("(function ZeD_ItemCard:drawOverlayEdge%(%).-\nend)\n")
check("drawOverlayEdge is found", body ~= nil)
ZeD = { T = { px = function(n) return n end, borderS = { r = 0.3, g = 0.3, b = 0.3, a = 1 } } }
ZeD_ItemCard = {}
assert(loadstring(body or ""))()
local function run(frame, edge)
    local rects = {}
    local card = { overlayFrame = frame, overlayEdge = edge,
                   getWidth = function() return 220 end, getHeight = function() return 400 end,
                   drawRect = function(_, x, y, w, h) rects[#rects + 1] = { x = x, y = y, w = w, h = h } end }
    ZeD_ItemCard.drawOverlayEdge(card)
    return rects
end
local r = run(true, "left")
check("over a tab: four sides", #r == 4, #r)
local top, bottom, left, right = false, false, false, false
for _, e in ipairs(r) do
    if e.y == 0 and e.h == 1 and e.w == 220 then top = true end
    if e.y == 399 and e.h == 1 then bottom = true end
    if e.x == 0 and e.w == 1 and e.h == 400 then left = true end
    if e.x == 219 and e.w == 1 then right = true end
end
check("the four are the card's own edges, 1 px", top and bottom and left and right)
r = run(nil, "right")
check("an edge alone: the one side, as before", #r == 1 and r[1].x == 219, #r)
r = run(nil, nil)
check("alone in the drawer: no line", #r == 0, #r)
for _, f in ipairs({ "ZeD_CharacterWindow.lua", "ZeD_WorldWindow.lua" }) do
    local s = read("42/media/lua/client/ZeD/" .. f)
    check(f .. " sets overlayFrame over a tab", s:find('card.overlayFrame = (win._drawerMode == "tab")', 1, true) ~= nil)
end
print("card_frame_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
