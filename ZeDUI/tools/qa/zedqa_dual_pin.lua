-- ZeDUI/tools/qa/zedqa_dual_pin.lua  (QA; punch list 112, dual pinning, WindowHalves.lua): each half of the Character and
-- World windows rolls up and pins on its own. With the REAL mouse (release_check_mouse.ps1 through Lua/zedqa_click.txt),
-- as zedqa_autocollapse does. grep "ZEDQA dpn". Each check prints PASS or FAIL. Pictures zqa_dpn_<w>x<h>_<n>.png.
--   1  SETUP   both windows open: Character on Health, World on Maps; pins set: the World drawer pinned, the rest unpinned.
--              Logs where the four pins draw (Character: drawer's after the close box, inventory's before the window box;
--              World: containers' after the close box, drawer's before the window box)
--   2  MAPS    pointer to an empty corner, 3 s: the Character window rolled to its title bar, the World containers rolled
--              under their rod, the map still open (the director's example)
--   3  MAP     pointer over the map 3 s: the map stays, the containers stay rolled
--   4  ROD     pointer on the containers' rod: they come down
--   5  HALF    pointer on the drawer's part of the Character bar: the window down, the drawer open, the inventory rolled
--              under its rod; a real click on the drawer's pin pins it; away 3 s: the drawer stays, the inventory rolls
--   6  AIM     aiming with the pointer away: the unpinned halves roll, the pinned drawers stay open
--   7  RODPIN  a real click on the Character's inventory pin on its rod: pinned, and it comes down (pinning brings back)
--   8  TABS    a real click on the open tab still folds the drawer by hand; again opens it
--   2.2c       (hotfix beta 9a) the drawer pinned, the inventory rolled under its rod: an item held over the rod brings
--              the inventory down at once
--   2.6b       (hotfix beta 9a) both unpinned, the whole window rolled: resting on the inventory's part of the bar brings
--              back only the inventory (the drawer stays rolled in, on Health); on the drawer's part only the drawer
--   9  PAD     the pins are the title bar's stops (left to right), A toggles (onActivate, as the A tap fires it); the pad's
--              aiming escape (ZeD.Halves.aim) rolls only the unpinned halves; Y / a bumper (Focus.showWin) brings them down
-- Pins, tabs and windows are put back at the end.
local function say(s) print("ZEDQA dpn " .. tostring(s)) end
local core = getCore()
local sw, sh = core:getScreenWidth(), core:getScreenHeight()
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_dpn_" .. sw .. "x" .. sh .. "_" .. n .. ".png") end); say("shot " .. n) end
local pass, fail = 0, 0
local function check(ok, what) if ok then pass = pass + 1; say("PASS " .. what) else fail = fail + 1; say("FAIL " .. what) end end
local p = getPlayer()
local md = p:getModData()
local H = ZeD.Halves
local keepPins = nil   -- (every pin key: charInv, charTabs, worldInv, worldTabs and the older char, world)
if md.ZeD_WinPinned then keepPins = {}; for k, v in pairs(md.ZeD_WinPinned) do keepPins[k] = v end end
local function CW() return ZeD_CharacterWindow.getWindow() end
local function WW() return ZeD_WorldWindow.getWindow() end
local keepTabs = {}
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function waitFor(n, max, cond, fn) Q[#Q + 1] = { n = n, fn = fn, cond = cond, max = max } end
local function req(s)
    pcall(function() local fw = getFileWriter("zedqa_click_done.txt", true, false); fw:write(""); fw:close() end)
    pcall(function() local f = getFileWriter("zedqa_click.txt", true, false); f:write(s); f:close() end)
end
local function done() local r = getFileReader("zedqa_click_done.txt", false); local l = r and r:readLine(); if r then r:close() end; return l ~= nil and l:find("done", 1, true) ~= nil end
local function moveTo(x, y) req("move " .. math.floor(x) .. " " .. math.floor(y)) end
local function clickAt(x, y) req("left " .. math.floor(x) .. " " .. math.floor(y)) end
local function mouse() waitFor(5, 600, done, function() end) end
-- wait a number of milliseconds on the clock (getTimestampMs), not frames: the rest on a bar is timed on the clock
local function waitMs(ms, fn)
    local t0
    waitFor(0, 100000, function() t0 = t0 or getTimestampMs(); return getTimestampMs() - t0 >= ms end, fn)
end
-- the pointer by the globals the halves read (the real desktop cursor is read again every frame): nil puts them back
local realMX, realMY = getMouseX, getMouseY
local function pointerAt(x, y)
    if x then getMouseX = function() return x end; getMouseY = function() return y end else getMouseX, getMouseY = realMX, realMY end
end
local function rect(r) return r and string.format("%d,%d %dx%d", r.x, r.y, r.w, r.h) or "none" end
local function centre(win, r) return win:getAbsoluteX() + r.x + r.w / 2, win:getAbsoluteY() + r.y + r.h / 2 end
local function mapOpen(w) return w._activeTab == "maps" and w._drawerOpen and w._drawerMode == "tab" end
-- An Equip drag as the windows read it: the halves ask isActive, the window's render draws its ghost every frame (a
-- bare { isActive } threw "tried to call nil" in render on every frame it was held)
local function heldStub()
    return { isActive = function() return true end, isPending = function() return false end, drawGhost = function() end,
             updateGhostPos = function() end, cancel = function() end, items = {} }
end
-- The drawer's part of the Character window's rolled bar (screen x): a rolled bar splits evenly (the director:
-- "Split the bar evenly"), the drawer's half on the left, so a quarter of the way in, clear of its pin
-- Read from the live window (ZeD.Halves.split, where the halves meet on that bar): the same quarter on beta 10's
-- even split, and still the drawer's part on a build that splits a rolled bar elsewhere. (The fixed quarter failed on
-- the 9a stage, whose rolled bar gave a folded drawer only the tab strip's end: the run's one FAIL.)
local function drawerBarX(c)
    return c:getAbsoluteX() + math.floor(H.split(c) / 2)
end

-- 1 SETUP
step(30, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end
    local c, w = CW(), WW()
    keepTabs.char, keepTabs.world = c._activeTab, w._activeTab
    check(c._halves ~= nil and w._halves ~= nil and H ~= nil, "both windows have halves (WindowHalves)")
    ZeD_CharacterWindow.openTab(0, "health")
    ZeD_WorldWindow.openTab(0, "maps")
end)
step(30, function()
    local c, w = CW(), WW()
    H.setPin(c, "inv", false); H.setPin(c, "drawer", false)
    H.setPin(w, "inv", false); H.setPin(w, "drawer", true)
    local t = md.ZeD_WinPinned
    check(t.worldTabs == true and t.worldInv == false and t.charInv == false and t.charTabs == false, "pins saved per half")
    check(mapOpen(w) and c._activeTab == "health" and c._drawerOpen, "Character on Health, World on Maps")
    say("Character pins: drawer (left) " .. rect(H.pinRect(c, "left")) .. ", inventory (right) " .. rect(H.pinRect(c, "right")) .. ", window box " .. rect(c:windowBoxRect()))
    say("World pins: containers (left) " .. rect(H.pinRect(w, "left")) .. ", drawer (right) " .. rect(H.pinRect(w, "right")) .. ", window box " .. rect(w:windowBoxRect()))
    local cl, cr = H.pinRect(c, "left"), H.pinRect(c, "right")
    check(cl and cr and cl.x < cr.x and cr.x + cr.w <= c:windowBoxRect().x, "Character: one pin at each end of the bar, the right one before the window box")
    shot("1_pins")
    moveTo(sw - 40, sh / 2)
end)
mouse()
-- 2 MAPS
step(200, function()
    local c, w = CW(), WW()
    check(c.windowShaded == true, "away 3 s: the Character window rolled to its title bar")
    check(w._rolled == true and not w.windowShaded, "away 3 s: the World containers rolled under their rod")
    check(mapOpen(w), "away 3 s: the map still open (pinned)")
    shot("2_maps_pinned")
    moveTo(w:getAbsoluteX() + w:getWidth() / 2, w:getAbsoluteY() + w:getHeight() / 2)
end)
mouse()
-- 2.2a QUICK  a pass across the rolled Character bar under 0.3 s leaves it rolled
step(10, function()
    local c = CW()
    check(c.windowShaded == true, "2.2a: the Character window is rolled before the sweep")
    local y = c:getAbsoluteY() + c:titleBarHeight() / 2
    pointerAt(c:getAbsoluteX() + 150, y)
end)
waitMs(120, function()
    pointerAt(sw - 40, sh - 40)
end)
waitMs(900, function()
    local c = CW()
    check(c.windowShaded == true, "2.2a: a 0.12 s pass over the rolled title bar leaves it rolled")
    pointerAt(nil)
end)
-- 3 MAP
step(200, function()
    local w = WW()
    check(mapOpen(w) and w._rolled == true, "pointer on the map 3 s: map open, the containers still rolled")
    local rod = w._rod
    if rod then moveTo(rod:getAbsoluteX() + rod:getWidth() / 2, rod:getAbsoluteY() + w:titleBarHeight() / 2) end
end)
mouse()
-- 4 ROD
waitMs(700, function()
    local w = WW()
    check(not w._rolled and mapOpen(w), "pointer on the containers' rod: they come down, the map open")
    shot("4_containers_down")
    local c = CW()
    moveTo(c:getAbsoluteX() + 150, c:getAbsoluteY() + c:titleBarHeight() / 2)
end)
mouse()
-- 5 HALF
waitMs(700, function()
    local c = CW()
    check(not c.windowShaded and c._drawerOpen, "the drawer's part of the Character bar: the window down, the drawer open")
    check(c._rolled == true, "... the inventory still rolled under its rod")
    shot("5_char_drawer_down")
    local r = H.pinRect(c, "left")
    if r then clickAt(centre(c, r)) end
end)
mouse()
step(20, function()
    local c = CW()
    check(H.isPinned(c, "drawer") and md.ZeD_WinPinned.charTabs == true, "a real click on the Character's left pin pins its drawer")
    moveTo(sw - 40, sh / 2)
end)
mouse()
step(200, function()
    local c = CW()
    check(not c.windowShaded and c._drawerOpen and c._rolled == true, "away 3 s: the pinned drawer stays, the inventory rolled")
    shot("5_char_drawer_pinned")
end)
-- 6 AIM
step(10, function()
    local c, w = CW(), WW()
    H.setPin(c, "inv", false)
    pcall(function() p:setIsAiming(true) end)
end)
step(15, function()
    local c, w = CW(), WW()
    check(c._drawerOpen and not c.windowShaded, "aiming: the Character's pinned drawer stays open")
    check(mapOpen(w) and not w.windowShaded, "aiming: the World's pinned map stays open")
    check(c._rolled == true and w._rolled == true, "aiming: both inventory sides rolled")
    pcall(function() p:setIsAiming(false) end)
    shot("6_aim")
end)
-- 7 RODPIN
step(20, function()
    local c = CW()
    local rod, r = c._rod, c._rod and c._rod._pinRect
    say("Character rod pin " .. rect(r))
    if rod and r then clickAt(rod:getAbsoluteX() + r.x + r.w / 2, rod:getAbsoluteY() + r.y + r.h / 2) end
end)
mouse()
step(60, function()
    local c = CW()
    check(H.isPinned(c, "inv"), "a real click on the pin on the Character's rod pins the inventory")
    check(not c._rolled, "... and the pinned inventory comes down")
    shot("7_rod_pin")
    -- the open tab in the strip
    local strip = c._tabStripPanel
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:health" then clickAt(strip:getAbsoluteX() + z.x + z.w / 2, strip:getAbsoluteY() + z.y + z.h / 2) end
    end
end)
mouse()
-- 8 TABS
step(30, function()
    local c = CW()
    check(not c._drawerOpen and c._activeTab == "loot", "a real click on the open tab still folds the drawer (pinned or not)")
    check(H.foldedTab(c) == nil, "... by hand: not the half's fold")
    ZeD_CharacterWindow.openTab(0, "health")
end)
-- 2.2b DRAG  an item dragged over a rolled title bar brings it down at once (no 0.3 s rest)
step(10, function()
    local c = CW()
    pcall(function() c:setWindowShaded(true) end)
    check(c.windowShaded == true, "2.2b: the Character window rolled for the drag test")
    c._equipDrag = heldStub()   -- an item held (as itemDragging reads it)
    pointerAt(c:getAbsoluteX() + 150, c:getAbsoluteY() + c:titleBarHeight() / 2)
end)
waitMs(250, function()
    local c = CW()
    check(not c.windowShaded, "2.2b: an item held over the rolled title bar brings the window down within 0.25 s")
    c._equipDrag = nil
    pointerAt(nil)
end)
-- 2.2c DRAG, ONE HALF  (hotfix beta 9a) the drawer pinned, the inventory rolled under its rod: an item held over the
-- rod brings the inventory down at once (only a whole rolled window did)
step(10, function()
    local c = CW()
    H.setPin(c, "drawer", true); H.setPin(c, "inv", false)
    pointerAt(c:getAbsoluteX() + 100, c:getAbsoluteY() + c:getHeight() / 2)   -- (in the drawer)
    c._halves.inv.rolled = true; H.drive(c)
end)
waitMs(800, function()
    local c = CW()
    check(c._rolled == true and c._drawerOpen and not c.windowShaded, "2.2c: (staged) drawer pinned, the inventory rolled under its rod")
    -- an item held from the World window: one from this window's own list brings its halves back by the rod's
    -- roll down (WindowHalves "mine"), which can run past 0.25 s; 2.2c is the drop from elsewhere, at once
    WW()._equipDrag = heldStub()
    local rod = c._rod
    if rod then pointerAt(rod:getAbsoluteX() + rod:getWidth() / 2, rod:getAbsoluteY() + c:titleBarHeight() / 2) end
end)
waitMs(250, function()
    local c = CW()
    check(not c._rolled and not c._halves.inv.rolled, "2.2c: an item held over the rod brings the inventory down within 0.25 s, the drawer pinned")
    check(c._drawerOpen, "2.2c: ... the pinned drawer still open")
    WW()._equipDrag = nil
end)
-- 2.6b REST, EACH HALF  (hotfix beta 9a) both unpinned, the whole window rolled: resting on each half's part of the
-- bar brings back only that half (the inventory's part: the drawer stays rolled in, on its tab)
step(10, function()
    local c = CW()
    H.setPin(c, "drawer", false); H.setPin(c, "inv", false)
    pcall(function() c:setWindowShaded(true) end)
    pointerAt(c:getAbsoluteX() + c:getWidth() * 0.8, c:getAbsoluteY() + c:titleBarHeight() / 2)
end)
waitMs(800, function()
    local c = CW()
    check(not c.windowShaded and not c._rolled and not c._drawerOpen and H.foldedTab(c) == "health",
        "2.6b: the inventory's part of the rolled bar: only the inventory comes back, the drawer still rolled in")
    check(c._activeTab == "health", "2.6b: ... the window still on Health (not Loot)")
    shot("2_6b_inventory_part")
    pcall(function() c:setWindowShaded(true) end)
    pointerAt(drawerBarX(c), c:getAbsoluteY() + c:titleBarHeight() / 2)
end)
waitMs(800, function()
    local c = CW()
    check(not c.windowShaded and c._drawerOpen and c._rolled == true, "2.6b: the drawer's part: only the drawer comes back, the inventory under its rod")
    shot("2_6b_drawer_part")
    pointerAt(nil)
    ZeD.Curtain.finishUnroll(c)
    H.setPin(c, "inv", true); H.setPin(c, "drawer", true)
end)
-- 9 PAD
step(30, function()
    local c, w = CW(), WW()
    check(c._drawerOpen, "Health open again")
    local zone
    for _, z in ipairs(c._focusRing or {}) do if z.zone == "charTitlePins" then zone = z end end
    local els = zone and zone.elements or {}
    say("pad stops: " .. #els .. " " .. tostring(els[1] and els[1].id) .. ", " .. tostring(els[2] and els[2].id))
    check(#els == 2 and els[1].id == "halfpin:drawer" and els[2].id == "halfpin:inv", "pad: the two pins are the bar's stops, left to right")
    local before = H.isPinned(c, "inv")
    if els[2] then els[2].onActivate(c, els[2]) end
    check(H.isPinned(c, "inv") ~= before, "pad: A on the inventory's pin toggles it")
    -- the pad's aiming escape: only the unpinned halves
    H.setPin(c, "inv", false); H.setPin(c, "drawer", true)
    H.aim(c); H.aim(w)
end)
step(40, function()
    local c, w = CW(), WW()
    check(c._drawerOpen and not c.windowShaded and c._rolled == true, "pad aim: the Character drawer (pinned) stays, its inventory rolls")
    check(mapOpen(w) and not w.windowShaded, "pad aim: the World map (pinned) stays")
    ZeD.Input.Focus.showWin(c); ZeD.Input.Focus.showWin(w)
end)
step(30, function()
    local c, w = CW(), WW()
    check(not c._rolled and not c.windowShaded and not w._rolled and not w.windowShaded, "Y / a bumper (showWin): both windows fully down")
    shot("9_pad_down")
    -- put back
    if keepPins then md.ZeD_WinPinned = keepPins else md.ZeD_WinPinned = {} end
    local t = md.ZeD_WinPinned
    for _, pair in ipairs({ { c, "char" }, { w, "world" } }) do
        local win, k = pair[1], pair[2]
        local i, d = t[k .. "Inv"], t[k .. "Tabs"]
        if i == nil and d == nil then i, d = t[k] == true, t[k] == true end
        H.setPin(win, "inv", i == true); H.setPin(win, "drawer", d == true)
    end
    if keepTabs.char and keepTabs.char ~= "loot" then ZeD_CharacterWindow.openTab(0, keepTabs.char) end
    if keepTabs.world and keepTabs.world ~= "loot" then ZeD_WorldWindow.openTab(0, keepTabs.world) end
    -- the rest of a regression expects open windows: both held open for the run's remainder (modData put back above)
    c.pinned, w.pinned = true, true
    say(string.format("RESULT %d pass, %d fail", pass, fail))
    say("DONE")
end)
local function tick()
    local q = Q[qi + 1]
    if not q then Events.OnTick.Remove(tick); return end
    wait = wait + 1
    if q.cond then
        if q.cond() or wait >= q.max then wait = 0; qi = qi + 1; local ok, e = pcall(q.fn); if not ok then say("ERR " .. tostring(e)) end end
        return
    end
    if wait < q.n then return end
    wait = 0
    qi = qi + 1
    local ok, err = pcall(q.fn)
    if not ok then fail = fail + 1; say("ERR step " .. qi .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
