-- ZeDUI/tools/qa/fold_slide_sim.lua  (Nov 10 2026, Build; punch list 126, the Character list slides when its drawer
-- folds at small sizes)
-- QA's staged Deck run (Nov 9): at 1280 x 800 (0.75) with Equip's full card open, the half-screen cap costs the window
-- 53 px and pins it 4 px past x 0. When the drawer folded (WindowHalves), the drawer's frame gave the 53 px back, so the
-- inventory list slid 57 px left under a resting pointer.
-- This sim cuts the Character window's width model (drawer._onPrerender, from "local prevEffW" to the inventory's base
-- width) out of the real ZeD_CharacterWindow.lua and runs it frame by frame on a stub window. It checks:
--   OPEN    the full card opening hits the cap: 53 px lost, the window pinned at x 0 with a 4 px push
--   FOLD    the drawer folding (foldTab set, the drawer closing over 12 frames): the list moves no more than the 4 px
--           push (it slid 57); the lost 53 stay owed; the inventory's base width isn't rewritten
--   UNFOLD  the drawer coming back: the window at the cap again, the list where it was before the fold
--   CLOSE   a fold that ends with the drawer shut (another tab): the 53 px are paid back at once, the inventory as wide
--           as before the card opened
--   PLAIN   with no fold, a drawer that closes gives the 53 back as it always did
--   OTHER   a fold that ends on another tab keeps its debt through the new drawer (the list stays put) and pays it as
--           that drawer closes, in step with its slide (the list eases home; it jumped 53 px in two frames: QA, test 4)
--   NARROW  at a screen where the full card would shift the window, it opens at ZeD.Scale.fitInvW's width (Scale.lua):
--           the full card fits beside it, nothing lost, no push, the list never moves (the director, Nov 11 2026)
--   SNAP    WindowHalves' instant fold (snapShut: the window back from rolled-up, drawer folded) pays the debt on purpose
-- Run from the repo root:  lua51 ZeDUI/tools/qa/fold_slide_sim.lua
-- It prints FAIL lines and a last line "fold_slide_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]fold_slide_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end

local f = io.open(ROOT .. "42/media/lua/client/ZeD/ZeD_CharacterWindow.lua", "rb")
local src = f:read("*a"):gsub("\r\n", "\n"); f:close()   -- (the file may have CRLF line ends)
local a = src:find("        local prevEffW = win._prevEffW or effectiveW", 1, true)
local bTag = "                win._baseInvW = invW / (T.scale or 1)\n            end\n        end\n"
local b = src:find(bTag, a or 1, true)
check("the width model is found in ZeD_CharacterWindow.lua", a and b)
if not (a and b) then print("fold_slide_sim: " .. checks .. " checks, " .. failed .. " failed"); os.exit(1) end
local body = src:sub(a, b + #bTag - 1)
local chunk = "local win, effectiveW, T, TAB_STRIP_W, CONTAINER_STRIP_W = ...\n" .. body .. "\nreturn invW\n"
local frame, err = loadstring(chunk, "width model")
check("the width model compiles on its own", frame, err)
if not frame then print("fold_slide_sim: " .. checks .. " checks, " .. failed .. " failed"); os.exit(1) end

local SC = 0.75
local T = { px = function(v) return math.floor(v * SC + 0.5) end, scale = SC }
local SCREEN = 1280
getCore = function() return { getScreenWidth = function() return SCREEN end, getScreenHeight = function() return 800 end } end
local FOLD = nil
ZeD = { Halves = { foldedTab = function() return FOLD end }, Curtain = { sync = function() end } }
-- the screen a window lives on (ZeD.screenOf, the real one cut from Organisms.lua: the width model and snapShut read it)
do
    local fo = io.open(ROOT .. "42/media/lua/client/ZeD/Organisms.lua", "rb")
    local os2 = fo:read("*a"):gsub("\r\n", "\n"); fo:close()
    local fnSrc = os2:match("(function ZeD%.screenOf%(w%).-\nend)")
    check("ZeD.screenOf is found in Organisms.lua", fnSrc ~= nil)
    if fnSrc then assert(loadstring(fnSrc))() end
end

local function newWin()
    local w = { x = 0, w = 0, _maxWinW = SCREEN / 2, _baseInvW = 372, _invDrawerOpen = true, _drawerOpen = false,
                _activeTab = "equip", _drawerMode = "tab" }
    function w:getX() return self.x end
    function w:getWidth() return self.w end
    -- the engine keeps a top-level panel on screen: setX clamps at 0
    function w:setX(v) self.x = math.max(0, v) end
    function w:setWidth(v) self.w = v end
    -- the reset's place at 0.75: the window's right edge at 636, its width the strips and the inventory
    w.w = T.px(36) + T.px(372) + T.px(36)
    w.x = 636 - w.w
    w._anchorRightEdge = 636
    w._lastSetX = w.x
    return w
end
local function run(w, effW) return frame(w, effW, T, 36, 36) end
local function listX(w, effW) return w.x + T.px(36) + effW end      -- the inventory list's left edge on screen

local DRAWER = 360           -- Equip's full card at 0.75 (QA: 333 + 360 is 53 past the 640 cap)
local function open(w)
    w._drawerOpen = true
    local e = 0
    for i = 1, 12 do e = math.floor(DRAWER * i / 12); run(w, e) end
    run(w, DRAWER)
    return DRAWER
end

-- OPEN
local w = newWin()
local w0, x0 = w.w, w.x
local invBefore = run(w, 0)
open(w)
check("OPEN: the cap holds the window at half the screen", w.w == SCREEN / 2, w.w)
check("OPEN: 53 px lost to the cap", w._drawerCapLost == (w0 + DRAWER) - SCREEN / 2, w._drawerCapLost)
local listOpen = listX(w, DRAWER)

-- FOLD: the drawer closes over 12 frames with its tab kept (WindowHalves' fold)
FOLD = "equip"
w._drawerOpen = false
local minX, maxX = listOpen, listOpen
local base = w._baseInvW
for i = 11, 0, -1 do
    local e = math.floor(DRAWER * i / 12)
    run(w, e)
    local lx = listX(w, e)
    minX, maxX = math.min(minX, lx), math.max(maxX, lx)
end
for _ = 1, 3 do run(w, 0) end
-- (the window starts pinned at x 0, 4 px past its anchor: as the drawer narrows the push runs out and the right edge
-- comes back to the anchor, so the list moves those 4 px left, once. Holding them would move the anchor 4 px right for
-- good, the bug the push was made to stop. Before: 57 px.)
check("FOLD: the list moves no more than the 4 px push", listOpen - minX <= 4 and maxX - listOpen <= 0, ("%d to %d (open %d)"):format(minX, maxX, listOpen))
check("FOLD: the lost width stays owed", w._drawerCapLost == (w0 + DRAWER) - SCREEN / 2, w._drawerCapLost)
check("FOLD: the inventory's base width isn't rewritten", w._baseInvW == base, w._baseInvW)

-- UNFOLD
FOLD = nil
open(w)
check("UNFOLD: the window at the cap again", w.w == SCREEN / 2, w.w)
check("UNFOLD: the list where it was before the fold", listX(w, DRAWER) == listOpen, listX(w, DRAWER) - listOpen)
check("UNFOLD: still 53 owed for the real close", w._drawerCapLost == (w0 + DRAWER) - SCREEN / 2, w._drawerCapLost)

-- OTHER: fold, then another tab opens: the fold's debt rides through the new drawer and is paid as it closes, so the
-- list stays put while it opens (QA's Mac recheck, Nov 10 2026: paying it at once held the list 53 px left for ~10
-- frames), and the inventory is back to its own width once it closes (the old code left it 53 px narrow)
for _, HEALTH in ipairs({ 300, 360 }) do
    local tag = "OTHER (" .. HEALTH .. "): "
    local o = newWin()
    run(o, 0)
    local home = listX(o, 0)
    open(o)
    FOLD = "equip"; o._drawerOpen = false
    for i = 11, 0, -1 do run(o, math.floor(DRAWER * i / 12)) end
    run(o, 0)
    local folded = listX(o, 0)
    FOLD = nil; o._activeTab = "health"; o._drawerOpen = true
    local lo, hi = folded, folded
    for i = 1, 12 do local e = math.floor(HEALTH * i / 12); run(o, e); local lx = listX(o, e); lo = math.min(lo, lx); hi = math.max(hi, lx) end
    for _ = 1, 3 do run(o, HEALTH) end
    check(tag .. "while it opens the list moves no more than the 4 px push", folded - lo <= 4 and hi - folded <= 4, lo .. ".." .. hi .. " from " .. folded)
    check(tag .. "the debt is still owed while it is open", (o._drawerCapLost or 0) >= (w0 + DRAWER) - SCREEN / 2, o._drawerCapLost)
    o._drawerOpen = false
    -- (QA's Mac run, Nov 11 2026, on test 4: paid as fast as the drawer narrowed, the list jumped 53 px in the close's
    -- first two frames; now it eases home with the slide)
    local prev, step = listX(o, HEALTH), 0
    for i = 11, 0, -1 do
        local e = math.floor(HEALTH * i / 12)
        run(o, e)
        local lx = listX(o, e)
        step = math.max(step, math.abs(lx - prev)); prev = lx
    end
    run(o, 0); run(o, 0)
    -- (the first frame also lets go of the 4 px push at the screen's edge, as FOLD does: 4 plus one share)
    check(tag .. "as it closes the list eases home with the slide, no frame more than 9 px (it was 53 in two)", step <= 9, step)
    check(tag .. "and ends where it was before any card", listX(o, 0) == home, listX(o, 0) .. " vs " .. home)
    check(tag .. "closed, the inventory as wide as before any drawer", run(o, 0) == invBefore and o.x == x0, run(o, 0) .. " at " .. o.x)
    check(tag .. "and nothing owed", (o._drawerCapLost or 0) == 0, o._drawerCapLost)
end

-- SNAP: the instant fold (WindowHalves' snapShut: the whole window back from rolled-up with the drawer half staying
-- folded) pays the Character window's debt on purpose: the window reappears, no pointer rests on the list, and the
-- inventory gets its full width rather than a squeezed one (dual_pin_sim's CAP: 444 wide, not 160). QA's Mac run, Nov
-- 10 2026, read this as "the second fold": the list came back 53 px left of where it was before the roll-up.
do
    local f2 = io.open(ROOT .. "42/media/lua/client/ZeD/WindowHalves.lua", "rb")
    local hs = f2:read("*a"):gsub("\r\n", "\n"); f2:close()
    local a2 = hs:find("local function snapShut(win)", 1, true)
    local b2 = a2 and hs:find("\nend\n", a2, true)
    check("SNAP: snapShut is found in WindowHalves.lua", a2 and b2)
    if a2 and b2 then
        local fnSnap = loadstring(hs:sub(a2, b2 + 4) .. "\nreturn snapShut")()
        local o = newWin()
        run(o, 0); open(o)
        o._halves = { side = "left" }
        o.minimumWidth = 0
        o._drawerEffW = DRAWER
        fnSnap(o)
        check("SNAP: the window comes down at the inventory's full width, the debt paid", o.w == w0 and (o._drawerCapLost or 0) == 0, o.w .. " / " .. tostring(o._drawerCapLost))
        check("SNAP: on its right edge", o.x + o.w == 636, o.x)
    end
end

-- NARROW (the director, Nov 11 2026: "Make steam deck inventory narrower for those resolutions ... get rid of the
-- window shifting and changing"): ZeD.Scale.fitInvW, cut from the real Scale.lua, gives the inventory width the
-- window opens at here; opened at it, a full card fits beside it: nothing lost to the cap, no push at the screen's
-- edge, the list never moves, and the card closes back to the same place
do
    local fs = io.open(ROOT .. "42/media/lua/shared/ZeD/Scale.lua", "rb")
    local ss = fs:read("*a"):gsub("\r\n", "\n"); fs:close()
    local a3 = ss:find("S.INV_W_U, S.INV_MIN_U, S.FULL_CARD_U", 1, true)
    local b3 = a3 and ss:find("\nend\n", ss:find("function S.fitInvW", a3, true), true)
    check("NARROW: fitInvW is found in Scale.lua", a3 and b3)
    if a3 and b3 then
        local S = loadstring("local S = ...\n" .. ss:sub(a3, b3 + 4) .. "\nreturn S")({})
        local room = math.min(SCREEN / 2, SCREEN / 2 - T.px(5))
        local fitU = S.fitInvW(T, room, 72)
        check("NARROW: at 1280 x 800 (0.75) the inventory opens narrower: 296 units (222 px)", fitU == 296, fitU)
        local o = newWin()
        o._baseInvW = fitU
        o.w = T.px(36) + T.px(fitU) + T.px(36)
        o.x = 636 - o.w
        o._lastSetX = o.x
        local inv0 = run(o, 0)
        local home, x0n = listX(o, 0), o.x
        local lo, hi = home, home
        o._drawerOpen = true
        for i = 1, 12 do local e = math.floor(DRAWER * i / 12); run(o, e); local lx = listX(o, e); lo = math.min(lo, lx); hi = math.max(hi, lx) end
        run(o, DRAWER)
        check("NARROW: the full card open, nothing lost to the cap", (o._drawerCapLost or 0) == 0, o._drawerCapLost)
        check("NARROW: no push at the screen's edge (the window on its anchor)", (o._drawerCapPush or 0) == 0 and o.x >= 0, o.x)
        check("NARROW: the list never moves as it opens", lo == home and hi == home, lo .. ".." .. hi .. " from " .. home)
        check("NARROW: the inventory keeps its width beside it", run(o, DRAWER) == inv0, run(o, DRAWER) .. " vs " .. inv0)
        o._drawerOpen = false
        for i = 11, 0, -1 do local e = math.floor(DRAWER * i / 12); run(o, e); local lx = listX(o, e); lo = math.min(lo, lx); hi = math.max(hi, lx) end
        run(o, 0); run(o, 0)
        check("NARROW: closed, the window where it was and the list never moved", o.x == x0n and lo == home and hi == home, o.x .. " " .. lo .. ".." .. hi)
        -- where the usual width fits, nothing changes; where nothing fits, nothing changes
        local T1 = { px = function(v) return math.floor(v + 0.5) end, scale = 1 }
        check("NARROW: 1920 wide at 1x: the usual width", S.fitInvW(T1, 955, 72) == nil)
        check("NARROW: 1366 wide at 0.75: narrower too (it shifted there)", S.fitInvW(T, 679, 72) == 353, S.fitInvW(T, 679, 72))
        check("NARROW: 1280 wide at 1x (Large text): nothing fits at the minimum, the squeeze as before", S.fitInvW(T1, 635, 72) == nil)
    end
end

-- CLOSE: fold, then the fold ends with the drawer still shut
FOLD = "equip"; w._drawerOpen = false
for i = 11, 0, -1 do run(w, math.floor(DRAWER * i / 12)) end
run(w, 0)
FOLD = nil
run(w, 0); run(w, 0)
check("CLOSE: the owed width is paid back", (w._drawerCapLost or 0) == 0, w._drawerCapLost)
check("CLOSE: the window as wide as before the card", w.w == w0, ("%d vs %d"):format(w.w, w0))
check("CLOSE: and where it was", w.x == x0, ("%d vs %d"):format(w.x, x0))
check("CLOSE: the inventory as wide as before", run(w, 0) == invBefore, run(w, 0))

-- PLAIN: no fold, the drawer just closes
local p = newWin()
run(p, 0)
open(p)
p._drawerOpen = false
for i = 11, 0, -1 do run(p, math.floor(DRAWER * i / 12)) end
run(p, 0); run(p, 0)
check("PLAIN: the close gives the 53 back", (p._drawerCapLost or 0) == 0 and p.w == w0, ("%d vs %d"):format(p.w, w0))
check("PLAIN: the window back on its place", p.x == x0, ("%d vs %d"):format(p.x, x0))

print("fold_slide_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
