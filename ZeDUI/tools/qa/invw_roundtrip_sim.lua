-- ZeDUI/tools/qa/invw_roundtrip_sim.lua  (Nov 12 2026, Build, #150): a UI scale round trip must not leave the
-- inventory narrow. The width a screen's fit (ZeD.Scale.fitInvW) narrows the inventory to is saved as the width it
-- came from until the player resizes the window. Cuts the REAL persistence code of both windows (charStateOf ..
-- restoreCharState, worldStateOf .. restoreWorldState) and the real fitInvW and runs them on stubs; the toggles' open
-- math and the at-rest frame are copied from the files, and SRC checks the toggles still mark a fitted fresh open.
local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]invw_roundtrip_sim%.lua$", "")
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    print((ok and "ok   " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    if not ok then failed = failed + 1 end
end
local function slurp(p) local f = assert(io.open(ROOT .. p, "rb")); local s = f:read("*a"); f:close(); return (s:gsub("\r\n", "\n")) end
local function cut(src, a, b)
    local i = assert(src:find(a, 1, true), "start not found: " .. a)
    local j = assert(src:find(b, i, true), "end not found: " .. b)
    return src:sub(i, j - 1)
end

local SW, SH = 1920, 1080
local function makeT(sc) return { scale = sc, px = function(v) return math.floor(v * sc + 0.5) end } end
ZeD = { T = makeT(1.0), Halves = { foldedTab = function() return nil end } }
ZeD.screenOf = function() return SW, SH, 0, 0 end
getTimestampMs = function() return 0 end
ZeD_CharacterWindow, ZeD_WorldWindow = {}, {}

local ss = slurp("42/media/lua/shared/ZeD/Scale.lua")
local a3 = ss:find("S.INV_W_U, S.INV_MIN_U, S.FULL_CARD_U", 1, true)
local _, b3 = ss:find("\nend\n", (ss:find("function S.fitInvW", a3, true)), true)
ZeD.Scale = assert(loadstring("local S = ...\n" .. ss:sub(a3, b3) .. "\nreturn S"))({})

local cwSrc = slurp("42/media/lua/client/ZeD/ZeD_CharacterWindow.lua")
local wwSrc = slurp("42/media/lua/client/ZeD/ZeD_WorldWindow.lua")
local C = assert(loadstring("local TAB_STRIP_W, CONTAINER_STRIP_W = 36, 36\n" ..
    cut(cwSrc, "local function charStateOf(win)", "-- Per-tab drawer width") ..
    "\nreturn { save = saveCharState, restore = restoreCharState }"))()
local W = assert(loadstring("local CONTAINER_STRIP_W, ACTION_TAB_STRIP_W = 36, 36\n" ..
    cut(wwSrc, "local function worldStateOf(win)", "local function round(n, dp)") ..
    "\nreturn { save = saveWorldState, restore = restoreWorldState }"))()

-- SRC: the toggles mark a fresh open the fit narrowed (Character after _baseInvW = invW; World before its restore)
check("SRC: Character toggle marks a fitted fresh open as 372",
    cwSrc:find("if type(fitU) == \"number\" then win._fitInvW, win._fitFromInvW = fitU, 372 end", 1, true) ~= nil)
local wFit = wwSrc:find("if type(fitU) == \"number\" then win._fitInvW, win._fitFromInvW = fitU, 372 end", 1, true)
local wRes = wwSrc:find("    restoreWorldState(win, playerObj)", 1, true)
check("SRC: World toggle marks it before its restore", wFit ~= nil and wRes ~= nil and wFit < wRes)
check("SRC: Reset layout marks a fitted width the same way (Organisms.lua)",
    slurp("42/media/lua/client/ZeD/Organisms.lua"):find("w._fitInvW, w._fitFromInvW = fitted, fitted and 372 or nil", 1, true) ~= nil)

local md = {}
local player = { getModData = function() return md end }
local function newWin(x, y, w, h)
    local o = { x = x, y = y, w = w, h = h }
    function o:setX(v) self.x = v end
    function o:setY(v) self.y = v end
    function o:setWidth(v) self.w = v end
    function o:setHeight(v) self.h = v end
    function o:getX() return self.x end
    function o:getY() return self.y end
    function o:getWidth() return self.w end
    function o:getHeight() return self.h end
    return o
end
local function openChar()
    local T = ZeD.T
    local screenW, screenH, screenL, screenT = ZeD.screenOf(0)
    local maxWinW = math.floor(screenW * 0.5)
    local invW = 372
    local fitU = ZeD.Scale.fitInvW(T, math.min(maxWinW, math.floor(screenW / 2) - T.px(5)), 72)
    if type(fitU) == "number" then invW = fitU end
    local winW = math.min(T.px(36) + T.px(invW) + T.px(36), maxWinW)
    local win = newWin(screenL + math.floor(screenW / 2) - winW - T.px(5), screenT, winW, math.min(T.px(420), screenH - T.px(80)))
    win._maxWinW, win._playerObj, win._activeTab = maxWinW, player, "loot"
    win._baseInvW = invW
    if type(fitU) == "number" then win._fitInvW, win._fitFromInvW = fitU, 372 end
    win._anchorRightEdge = win:getX() + winW
    C.restore(win, player)
    return win
end
local function frameChar(win, dragTo)
    local T = ZeD.T
    if dragTo then win:setWidth(dragTo); win:setX(win._anchorRightEdge - dragTo); win._lastSetX = win:getX() end
    if win._lastSetX and win:getX() ~= win._lastSetX then win._anchorRightEdge = win._anchorRightEdge + (win:getX() - win._lastSetX) end
    if win:getWidth() > win._maxWinW then win:setWidth(win._maxWinW) end
    win._lastSetX = win:getX()
    win._anchorRightEdge = win:getX() + win:getWidth() - (win._drawerCapPush or 0)
    local invW = win:getWidth() - T.px(36) - T.px(36)
    if invW > 0 then
        local expectedW = T.px(36) + T.px(win._baseInvW or 372) + T.px(36)
        if win:getWidth() ~= expectedW then win._baseInvW = invW / (T.scale or 1) end
    end
end
local function openWorld()
    local T = ZeD.T
    local screenW, screenH, screenL, screenT = ZeD.screenOf(0)
    local maxWinW = math.floor(screenW * 0.5)
    local invW = 372
    local fitU = ZeD.Scale.fitInvW(T, math.min(maxWinW, screenW - (math.floor(screenW / 2) + T.px(5))), 72)
    if type(fitU) == "number" then invW = fitU end
    local winW = math.min(T.px(36) + T.px(invW) + T.px(36), maxWinW)
    local win = newWin(screenL + math.floor(screenW / 2) + T.px(5), screenT, winW, math.min(T.px(420), screenH - T.px(80)))
    win._maxWinW, win._playerObj = maxWinW, player
    if type(fitU) == "number" then win._fitInvW, win._fitFromInvW = fitU, 372 end
    W.restore(win, player)
    win._activeTab = win._activeTab or "loot"
    win._baseInvW = invW
    return win
end
local function frameWorld(win)
    local T = ZeD.T
    if win:getWidth() > win._maxWinW then win:setWidth(win._maxWinW) end
    local invW = win:getWidth() - T.px(36) - T.px(36)
    if invW > 0 then
        local expectedW = T.px(36) + T.px(win._baseInvW or 372) + T.px(36)
        if win:getWidth() ~= expectedW then win._baseInvW = invW / (T.scale or 1) end
    end
end
-- the scale change path (Scale.lua reopenWindowsIfOpen): close with the old scale (saves), new scale, reopen
local function cycle(sc, c, w, dragChar)
    for i = 1, 3 do frameChar(c, (i == 1) and dragChar or nil); frameWorld(w) end
    C.save(c); W.save(w)
    ZeD.T = makeT(sc)
    local c2, w2 = openChar(), openWorld()
    for _ = 1, 3 do frameChar(c2); frameWorld(w2) end
    return c2, w2
end
local function near(a, b) return math.abs(a - b) < 0.01 end

-- A: 1920 x 1080, 1.0 -> 1.25 -> 1.0
local c, w = openChar(), openWorld()
for _ = 1, 3 do frameChar(c); frameWorld(w) end
c, w = cycle(1.25, c, w)
check("A: at 1.25 the Character inventory is narrowed (216)", near(c._baseInvW, 216), c._baseInvW)
c, w = cycle(1.0, c, w)
check("A: back at 1.0 the Character inventory is 372 again", near(c._baseInvW, 372), c._baseInvW)
check("A: and its right edge is back at the spread's (955)", c.x + c.w == 955, c.x + c.w)
check("A: World 372", near(w._baseInvW, 372), w._baseInvW)
c, w = cycle(1.25, c, w)
check("A: 1.25 again: narrowed again, no drift (216)", near(c._baseInvW, 216) and c.x + c.w == 1194, c._baseInvW .. " right " .. (c.x + c.w))

-- B: Deck (1280 x 800, 0.75) with no saved state, then 1920 x 1080 at 1.0
md = {}
SW, SH = 1280, 800; ZeD.T = makeT(0.75)
c, w = openChar(), openWorld()
for _ = 1, 3 do frameChar(c); frameWorld(w) end
check("B: Deck: both 296", near(c._baseInvW, 296) and near(w._baseInvW, 296), c._baseInvW .. " / " .. w._baseInvW)
C.save(c); W.save(w)
SW, SH = 1920, 1080; ZeD.T = makeT(1.0)
c, w = openChar(), openWorld()
for _ = 1, 3 do frameChar(c); frameWorld(w) end
check("B: 1080p: World 372 again", near(w._baseInvW, 372), w._baseInvW)
check("B: 1080p: Character narrowed only by its own place (right edge 848, fit 296)", c.x + c.w == 848 and near(c._baseInvW, 296), (c.x + c.w) .. " / " .. c._baseInvW)
C.save(c)
check("B: 1080p: Character's save keeps the usual width (444)", near(md.ZeD_WinState.char.w, 444), md.ZeD_WinState.char.w)

-- C: a player's own width survives: at 1.0 drag the Character inventory to 300, go to 1.25 and back
md = {}
ZeD.T = makeT(1.0)
c, w = openChar(), openWorld()
for _ = 1, 3 do frameChar(c); frameWorld(w) end
c, w = cycle(1.25, c, w, 372)
check("C: the dragged 300 is narrowed at 1.25 (216)", near(c._baseInvW, 216), c._baseInvW)
c, w = cycle(1.0, c, w)
check("C: back at 1.0 the player's 300 comes back", near(c._baseInvW, 300), c._baseInvW)

-- D: a player's drag narrower than the fit is kept as theirs
md = {}
ZeD.T = makeT(1.0)
c, w = openChar(), openWorld()
for _ = 1, 3 do frameChar(c); frameWorld(w) end
c, w = cycle(1.25, c, w)
c, w = cycle(1.0, c, w, ZeD.T.px(36) + ZeD.T.px(205) + ZeD.T.px(36))
check("D: a drag to 205 at 1.25 is kept at 1.0", math.abs(c._baseInvW - 205) < 1, c._baseInvW)

-- E: Deck with Large text (0.8625): the fit's own rounding does not read as a drag
md = {}
SW, SH = 1280, 800; ZeD.T = makeT(0.75 * 1.15)
c, w = openChar(), openWorld()
for _ = 1, 3 do frameChar(c); frameWorld(w) end
C.save(c); W.save(w)
check("E: Deck Large: the saves keep the usual width (444)", near(md.ZeD_WinState.char.w, 444) and near(md.ZeD_WinState.world.w, 444),
    md.ZeD_WinState.char.w .. " / " .. md.ZeD_WinState.world.w)
-- F: 1366 x 768 Large: fresh open, then a restore of that save, the saves keep 444 each time
md = {}
SW, SH = 1366, 768; ZeD.T = makeT(0.75 * 1.15)
c, w = openChar(), openWorld()
for _ = 1, 3 do frameChar(c); frameWorld(w) end
check("F: 1366 Large: fresh open narrowed (Char / World)", c._baseInvW < 372 and w._baseInvW < 372, c._baseInvW .. " / " .. w._baseInvW)
C.save(c); W.save(w)
check("F: fresh open saves 444 / 444", near(md.ZeD_WinState.char.w, 444) and near(md.ZeD_WinState.world.w, 444), md.ZeD_WinState.char.w .. " / " .. md.ZeD_WinState.world.w)
c, w = openChar(), openWorld()
for _ = 1, 3 do frameChar(c); frameWorld(w) end
check("F: restored narrowed again", c._baseInvW < 372 and w._baseInvW < 372, c._baseInvW .. " / " .. w._baseInvW)
C.save(c); W.save(w)
check("F: restore saves 444 / 444", near(md.ZeD_WinState.char.w, 444) and near(md.ZeD_WinState.world.w, 444), md.ZeD_WinState.char.w .. " / " .. md.ZeD_WinState.world.w)
print("invw_roundtrip_sim: " .. checks .. " checks, " .. failed .. " failed")
