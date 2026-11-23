-- ZeDUI/tools/qa/figure_frame_sim.lua (Figure frame, the director, Nov 22 2026): "the skeleton needs to take up half of
-- the card. And it sits in a frame just like the vehicle and its parts sit in a frame taking up half a card."
-- Checks, on the real Molecules.lua source (figureFrame, figureZoneH, drawFigureFrame, layoutZoneA): the frame takes
-- the left half and the text the right half; the skeleton sits centered in the frame at a whole zoom (at least 1, at
-- most the art's zoom) at 4K (UI scale 1.75), 1080p (1.0) and 1280x800 (0.75), on the Health tab and the medical
-- card; a card too narrow for halves (the 220 drawer card) stacks the frame over the text; the frame is the Vehicle
-- tab's one-unit T.borderS line; the four places the skeleton sits use it; the old spacing tokens are gone.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/figure_frame_sim.lua
local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]figure_frame_sim%.lua$", "")
local CLIENT = ROOT .. "42/media/lua/client/ZeD/"
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end
local function readFile(p)
    local f = io.open(p, "rb"); if not f then return "" end
    local s = f:read("*a"); f:close(); return (string.gsub(s, "\r\n", "\n"))
end

local mol = readFile(CLIENT .. "Molecules.lua")
local a = mol:find("local FIG_FRAME_INSET", 1, true)
local b = a and mol:find("\n-- 11. STAT ROW", a, true)
check("the figure frame code is in Molecules.lua", a ~= nil and b ~= nil)

-- the frame's line, as drawn
local FRAMES = {}
ZeD = { Molecules = {}, Atoms = { frame = function(p, x, y, w, h, c, al, t) FRAMES[#FRAMES + 1] = { x = x, y = y, w = w, h = h, c = c, t = t } end } }
local BORDER_S = { r = 0.5, g = 0.5, b = 0.5, a = 1 }
-- the look at a UI scale: T.px rounds design units to whole px (Tokens.lua), T.art the nearest whole zoom (Scale.lua),
-- the figure's box the canvas (106 x 254: the measure stops at the head, Nov 23 2026) at T.art
local function look(sc)
    local art = math.max(1, math.floor(sc + 0.5 + 1e-6))
    ZeD.T = { px = function(u) return math.floor(u * sc + 0.5) end, art = art, borderS = BORDER_S,
              sp = { figureW = 106 * art, figureH = 254 * art, scrollbarW = math.floor(14 * sc + 0.5) } }
    return ZeD.T
end
look(1)
local fn = a and b and loadstring("local TAB_HEADER_PAD, TAB_COL_GAP = 8, 10\n" .. mol:sub(a, b), "=Molecules.lua (figure frame)")
check("the figure frame code compiles", fn ~= nil)
if not fn then print(string.format("figure_frame_sim: %d checks, %d failed", checks, failed)); os.exit(1) end
fn()
local M = ZeD.Molecules

-- one layout's invariants: halves (or stacked), a whole zoom that fits, centered in the frame
local function sane(name, L, x, w)
    local T = ZeD.T
    check(name .. ": a whole zoom, at least 1, at most the art's", L.zoom == math.floor(L.zoom) and L.zoom >= 1 and L.zoom <= T.art, L.zoom)
    check(name .. ": the figure is the canvas at that zoom", L.figW == 106 * L.zoom and L.figH == 254 * L.zoom, L.figW .. "x" .. L.figH)
    check(name .. ": the figure inside the frame", L.figX >= L.frameX and L.figX + L.figW <= L.frameX + L.frameW
        and L.figY >= L.frameY and L.figY + L.figH <= L.frameY + L.frameH)
    local left, right = L.figX - L.frameX, (L.frameX + L.frameW) - (L.figX + L.figW)
    check(name .. ": centered across the frame", math.abs(left - right) <= 1, left .. " / " .. right)
    check(name .. ": the frame starts at the span's left", L.frameX == x)
    if L.two then
        check(name .. ": the frame is the left half", math.abs(L.frameW - L.rightW) <= 1, L.frameW .. " / " .. L.rightW)
        check(name .. ": the text the right half, to the span's right edge", L.rightX > L.frameX + L.frameW and L.rightX + L.rightW == x + w)
        check(name .. ": the text beside the frame, at its top", L.rightY == L.frameY)
    else
        check(name .. ": stacked, the frame the whole width", L.frameW == w)
        check(name .. ": stacked, the text under the frame, full width", L.rightY > L.frameY + L.frameH and L.rightX == x and L.rightW == w)
    end
end

-- the three screens QA plays: 4K at 1.75, 1080p at 1.0, 1280x800 at 0.75
local SCREENS = { { "4K (1.75)", 1.75 }, { "1080p (1.0)", 1.0 }, { "1280x800 (0.75)", 0.75 } }
local REPORT = {}
for _, sc in ipairs(SCREENS) do
    local T = look(sc[2])
    -- the Health tab: the card's 480 less the scroll bar (layoutZoneA takes the 8-unit pads off each side)
    local hw = T.px(480) - T.sp.scrollbarW
    local H = M.layoutZoneA(0, 0, hw)
    sane("Health " .. sc[1], H, T.px(8), hw - T.px(8) * 2)
    check("Health " .. sc[1] .. ": halves", H.two == true)
    check("Health " .. sc[1] .. ": the figure at the art's zoom", H.zoom == T.art, H.zoom)
    -- the medical card: ObjectCards hands the body the card less 10-unit pads; a full 336 card and the 220 drawer card
    local m336 = T.px(336) - T.px(10) * 2
    local m220 = T.px(220) - T.px(10) * 2
    local C = M.figureFrame(T.px(10), 0, m336)
    local D = M.figureFrame(T.px(10), 0, m220)
    sane("medic 336 " .. sc[1], C, T.px(10), m336)
    sane("medic 220 " .. sc[1], D, T.px(10), m220)
    check("medic 220 " .. sc[1] .. ": too narrow for halves, stacked", D.two == false)
    REPORT[#REPORT + 1] = string.format("  %-16s Health %s zoom %d (frame %dx%d, text %d) | medic 336 %s zoom %d | medic 220 %s zoom %d",
        sc[1], H.two and "halves" or "stacked", H.zoom, H.frameW, H.frameH, H.rightW,
        C.two and "halves" or "stacked", C.zoom, D.two and "halves" or "stacked", D.zoom)
end
-- the expected picture: 4K 2x, 1080p and 1280x800 1x; the full medical card in halves at 4K and 1080p
look(1.75)
check("4K: the Health figure at 2x", M.layoutZoneA(0, 0, ZeD.T.px(480) - ZeD.T.sp.scrollbarW).zoom == 2)
check("4K: the 336 medical card in halves at 2x", M.figureFrame(0, 0, ZeD.T.px(316)).two and M.figureFrame(0, 0, ZeD.T.px(316)).zoom == 2)
look(1)
check("1080p: the Health figure at 1x, text 220 wide at 466", M.layoutZoneA(0, 0, 466).zoom == 1 and M.layoutZoneA(0, 0, 466).rightW == 220)
check("1080p: the 336 medical card in halves", M.figureFrame(0, 0, 316).two == true)
-- a span far too narrow for even 1x: still 1x, never below (the frame overhangs rather than blur the art)
local tiny = M.figureFrame(0, 0, 60)
check("a tiny span: stacked, still 1x", tiny.two == false and tiny.zoom == 1, tiny.zoom)

-- the zone's height: beside, the taller of the frame and the text; stacked, the frame, the gap and the text
local L = M.layoutZoneA(0, 0, 466)
check("figureZoneH beside: a short text is the frame's height", M.figureZoneH(L, 10) == L.frameH)
check("figureZoneH beside: a tall text is its own height", M.figureZoneH(L, L.frameH + 50) == L.frameH + 50)
local S = M.figureFrame(0, 0, 200)
check("figureZoneH stacked: frame, gap and text", M.figureZoneH(S, 40) == S.rightY + 40)

-- the frame: the Vehicle tab pane's one-unit T.borderS line around the frame's rect
FRAMES = {}
M.drawFigureFrame({}, L)
local f = FRAMES[1]
check("the frame is drawn once, on the frame's rect", #FRAMES == 1 and f.x == L.frameX and f.y == L.frameY and f.w == L.frameW and f.h == L.frameH)
check("the frame's line is T.borderS, one unit thick", f and f.c == BORDER_S and f.t == ZeD.T.px(1))

-- the four places the skeleton sits beside text use it; the old spacing tokens are gone
local function src(n) return readFile(CLIENT .. n) end
local health, thermal, equip, medic = src("HealthTab.lua"), src("ThermalTab.lua"), src("EquipmentTab.lua"), src("ObjectCardMedic.lua")
check("Health draws the frame and the figure at the layout's size", health:find("M.drawFigureFrame(panel, layout)", 1, true)
    and health:find("layout.figX, layout.figY, layout.figW, layout.figH", 1, true))
check("Health measures with figureZoneH", health:find("ZeD.Molecules.figureZoneH(L, rightH)", 1, true) ~= nil)
check("Thermal draws the frame and the figure at the layout's size", thermal:find("M.drawFigureFrame(panel, layout)", 1, true)
    and thermal:find("layout.figX, layout.figY, layout.figW, layout.figH", 1, true))
check("Thermal measures with figureZoneH", thermal:find("M.figureZoneH(M.layoutZoneA(", 1, true) ~= nil)
check("Equipment's defense draws the frame and the figure at the layout's size", equip:find("M.drawFigureFrame(panel, layout)", 1, true)
    and equip:find("layout.figX, layout.figY, layout.figW, layout.figH", 1, true))
check("the medical card lays out with figureFrame and draws the frame", medic:find("ZeD.Molecules.figureFrame(x, y, w)", 1, true)
    and medic:find("ZeD.Molecules.drawFigureFrame(card, L)", 1, true) and medic:find("fig:drawAt(card, L.figX, L.figY, L.figW, L.figH)", 1, true))
local tok = readFile(ROOT .. "42/media/lua/shared/ZeD/Tokens.lua")
local all = tok .. mol .. health .. thermal .. equip .. medic
check("the old spacing tokens are gone (figureGap, figureTextMax, setFigureSpacing)",
    not all:find("T.sp.figureGap", 1, true) and not all:find("figureTextMax", 1, true) and not all:find("setFigureSpacing", 1, true))

print("figure frame, per screen:")
for _, line in ipairs(REPORT) do print(line) end
print(string.format("figure_frame_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
