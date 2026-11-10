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
local src = f:read("*a"); f:close()
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
getCore = function() return { getScreenWidth = function() return SCREEN end } end
local FOLD = nil
ZeD = { Halves = { foldedTab = function() return FOLD end }, Curtain = { sync = function() end } }

local function newWin()
    local w = { x = 0, w = 0, _maxWinW = SCREEN / 2, _baseInvW = 372, _invDrawerOpen = true, _drawerOpen = false }
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
