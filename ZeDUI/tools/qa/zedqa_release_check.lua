-- ZeDUI/tools/qa/zedqa_release_check.lua  (Nov 2 2026, QA; punch list 70, the five-minute release check)
-- Part of every per-build pass. Run with release_check.ps1 (it starts the real-mouse helper, then zedqa_run.ps1 with
-- release_check.txt), in game at the test resolution. Five checks, PASS or FAIL each:
--   1. both windows open (the inventory key's own call, ZeD_CharacterWindow.toggleBothPaired)
--   2. an item moves: an apple carried goes to the floor through the game's own transfer and shows in the World
--      window's list; then it comes back the same way and shows in the Character window's list
--   3. (after 4, which scrolls the row into view) right-click on an inventory row opens the item menu: a REAL right-click (release_check_mouse.ps1 moves the
--      desktop cursor to the test item's row and presses the right button), the path that broke in t12 (punch list 1)
--   4. the controller: focus on the test item's row, A opens its card on the primary action, B goes back to the row
--   5. the watch reads the time: a worn watch shows (on the belt or in the corner) and its face reads the game's hour
--      and minute
-- Everything is put back. grep "ZEDQA rel"; shots zqa_rel_*.png. The real click: this script writes
-- Lua/zedqa_click.txt ("right x y", screen pixels) and waits for Lua/zedqa_click_done.txt (the helper writes it).
local function say(s) print("ZEDQA rel " .. tostring(s)) end
local p = getPlayer()
local pn = p and p:getPlayerNum() or 0
local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
local Focus = ZeD and ZeD.Input and ZeD.Input.Focus
local Det = ZeD and ZeD.Input and ZeD.Input.Detector
if not (p and CW and WW and Focus) then say("ERR ZeD's windows are not loaded"); say("DONE"); return end
local fails, passes = 0, 0
local results = {}
local function check(ok, what) if ok then passes = passes + 1; say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; results[#results + 1] = (ok and "PASS " or "FAIL ") .. what; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_rel_" .. n .. ".png") end) end
local function cw() return CW.getWindow() end
local function ww() return WW.getWindow() end
local inv = p:getInventory()
local apple, watch
local godWas = p:isGodMod()

-- an element of a window's focus ring whose item is the apple
local function appleRow(w, zoneName)
    for _, z in ipairs((w and w._focusRing) or {}) do
        if z.zone == zoneName then
            for i, e in ipairs(z.elements or {}) do if e.item == apple then return e, i, z end end
        end
    end
end
local function inList(w, zoneName) return appleRow(w, zoneName) ~= nil end
local menuFor = nil
local realCreate = ISInventoryPaneContextMenu.createMenu
ISInventoryPaneContextMenu.createMenu = function(player, isInInv, items, ...)
    menuFor = items
    return realCreate(player, isInInv, items, ...)
end
local function menuHas(it)
    for _, x in ipairs(menuFor or {}) do
        if x == it then return true end
        if type(x) == "table" and x.items then for _, y in ipairs(x.items) do if y == it then return true end end end
    end
    return false
end
local function ctxOpen()
    local m = getPlayerContextMenu(pn)
    local zm = m and m._zedMenu
    if zm then return zm:isVisible() and true or false, zm end
    return (m and m:isVisible()) and true or false, m
end

-- the real right-click: ask the helper, wait for its answer (or give up after 15 s)
local clickAsked, clickWait = nil, nil
local function askClick(x, y)
    local fw = getFileWriter("zedqa_click_done.txt", true, false); if fw then fw:write(""); fw:close() end
    local w = getFileWriter("zedqa_click.txt", true, false)
    if w then w:write("right " .. math.floor(x) .. " " .. math.floor(y) .. "\n"); w:close() end
    clickAsked, clickWait = getTimestampMs(), true
    say("asked the helper for a right-click at " .. math.floor(x) .. "," .. math.floor(y))
end
local function clickDone()
    local r = getFileReader("zedqa_click_done.txt", false)
    if not r then return false end
    local l = r:readLine(); r:close()
    return l ~= nil and l ~= ""
end

local Q, qi = {}, 1
local function step(k, fn) Q[#Q + 1] = { n = k, fn = fn } end

-- ---- 1. both windows
step(10, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if CW.isOpen() or WW.isOpen() then CW.toggleBothPaired(pn) end
end)
step(20, function()
    check(not CW.isOpen() and not WW.isOpen(), "the windows start shut")
    CW.toggleBothPaired(pn)
end)
-- (Nov 7 2026) the hover roll-up shades a window while the desktop mouse is away from it, and a shaded window drops its
-- rows from the focus ring: hold both down for the test, as zedqa_mp scripts do, and say whether either was rolled up
local function keepDown(w)
    if not w then return end
    local was = w.windowShaded == true
    w._autoShaded = false
    if w.setWindowShaded then w:setWindowShaded(false) end
    w._outSince = getTimestampMs() + 600000
    return was
end
step(40, function()
    check(CW.isOpen() and WW.isOpen() and cw():isVisible() and ww():isVisible(), "1: both windows open")
    say("rolled up before the hold: Character " .. tostring(keepDown(cw())) .. ", World " .. tostring(keepDown(ww())))
    -- (a thing the character does not carry, so its row is its own and not a stack's)
    for _, ft in ipairs({ "Base.Spiffo", "Base.Rubberducky", "Base.Doll", "Base.Yoyo", "Base.Pinecone", "Base.Apple" }) do
        if not inv:containsTypeRecurse(ft) then apple = inv:AddItem(ft); if apple then break end end
    end
    say("the test item: " .. tostring(apple and apple:getFullType()))
end)

-- ---- 2. an item moves: to the floor and back
step(40, function()
    check(inList(cw(), "charMainInv"), "2: the test item is in the Character window's list")
    local floor = ISInventoryPage.GetFloorContainer and ISInventoryPage.GetFloorContainer(pn)
    if not floor then
        local sq = p:getCurrentSquare()
        floor = sq and ISInventoryPage.GetFloorContainer and ISInventoryPage.GetFloorContainer(pn)
    end
    if floor then ISTimedActionQueue.add(ISInventoryTransferAction:new(p, apple, inv, floor)) else say("NOTE no floor container") end
end)
step(200, function()
    local onFloor = apple:getWorldItem() ~= nil or (apple:getContainer() and apple:getContainer() ~= inv)
    check(onFloor, "2: the test item went to the floor (the game's transfer)")
    check(inList(ww(), "worldMainInv"), "2: the World window lists it")
    if apple:getContainer() and apple:getContainer() ~= inv then
        ISTimedActionQueue.add(ISInventoryTransferAction:new(p, apple, apple:getContainer(), inv))
    end
end)
step(200, function()
    say("rolled up now: Character " .. tostring(cw().windowShaded == true) .. ", World " .. tostring(ww().windowShaded == true))
    keepDown(cw()); keepDown(ww())
    check(apple:getContainer() == inv, "2: it came back to the inventory")
    check(inList(cw(), "charMainInv"), "2: the Character window lists it again")
end)

-- ---- 4. the controller: A on the row, B back
step(20, function()
    local w = cw()
    if Det then Det.setLockedMode(Det.MODE_GAMEPAD) end
    Focus.claimFocus(w)
    local e, ei, z = appleRow(w, "charMainInv")
    if not e then check(false, "4: the test item's row is a controller stop"); return end
    for zi, zz in ipairs(w._focusRing or {}) do if zz == z then w._focusIdx = zi; z.focusedElementIdx = ei end end
    if e.onFocus then e.onFocus(w, e) end   -- (as a D-pad move does: the list follows the focus into view)
    local f = Focus.getFocusedElement(w)
    check(f and f.item == apple, "4: the controller's focus is on the test item's row")
end)
step(20, function()
    local w = cw()
    local f = Focus.getFocusedElement(w)
    if f and f.onActivate then f.onActivate(w, f) end   -- (A on a row: the element's own activate, as the pad's A runs it)
end)
step(30, function()
    local w = Focus.getFocusedWindow()
    local f = w and Focus.getFocusedElement(w)
    local z = w and Focus.getFocusedZone(w)
    say("4: after A: " .. tostring(z and z.zone) .. ":" .. tostring(f and f.id))
    check(z and tostring(z.zone):find("ItemCard", 1, true) ~= nil and tostring(f and f.id):find("^hverb_1") ~= nil,
        "4: A on the row opens its card, focus on its primary action (" .. tostring(z and z.zone) .. ":" .. tostring(f and f.id) .. ")")
    shot("4_card")
    Focus.dispatchJoypadDown(w, Joypad.BButton)
end)
step(30, function()
    local w = Focus.getFocusedWindow()
    local f = w and Focus.getFocusedElement(w)
    say("4: after B: " .. tostring(f and f.id))
    check(f and f.item == apple, "4: B goes back to the row")
    pcall(function() Focus.releaseFocus() end)
    if Det then Det.setLockedMode(Det.MODE_KBM); Det.setLockedMode(nil) end
end)

-- ---- 3. a real right-click on its row
local rowAt
step(10, function()
    local w = cw()
    local e = appleRow(w, "charMainInv")
    if not check(e ~= nil and type(e.x) == "number", "3: the test item's row has a place on screen") then return end
    local c = w._mainContent
    local ax, ay = c:getAbsoluteX(), c:getAbsoluteY()
    check(e.y >= 0 and e.y + (e.h or 20) <= c:getHeight(), "3: the row is in the list's view (y " .. math.floor(e.y) .. " of " .. math.floor(c:getHeight()) .. ")")
    local x, y = ax + e.x + math.min(60, math.floor((e.w or 100) / 3)), ay + e.y + math.floor((e.h or 20) / 2)
    rowAt = { x = x, y = y }
    say(string.format("3: row %s at %d,%d %dx%d in the window; the window at %d,%d", tostring(e.id), e.x, e.y, e.w or 0, e.h or 0, ax, ay))
    menuFor = nil
    askClick(x, y)
end)
-- (a step that repeats until the helper answers: check first, then act)
local function waitClick()
    if clickWait and not clickDone() and getTimestampMs() - clickAsked < 15000 then
        table.insert(Q, qi, { n = 5, fn = waitClick })
        return
    end
    local answered = clickDone()
    clickWait = nil
    check(answered, "3: the helper made the real right-click")
end
step(5, waitClick)
step(20, function()
    local open, m = ctxOpen()
    say("3: menu open " .. tostring(open) .. " (" .. tostring(m and m.Type) .. ")")
    check(open and menuHas(apple), "3: a real right-click on the row opens the item menu for that item (" .. tostring(menuFor and #menuFor) .. " items)")
    shot("3_menu")
    if m then pcall(function() if m.close then m:close() else m:setVisible(false) end end) end
    pcall(function() getPlayerContextMenu(pn):setVisible(false) end)
end)

-- ---- 5. the watch
step(10, function()
    watch = inv:AddItem("Base.WristWatch_Left_DigitalBlack")
    p:setWornItem(watch:getBodyLocation(), watch)
end)
step(60, function()
    local W = ZeD.Watch
    local corner = W and W.getInstance and W.getInstance()
    local onBelt = false
    local hud = ZeD.Belt and ZeD.Belt.getHUD and ZeD.Belt.getHUD()
    for _, b in ipairs((hud and hud._boxes) or {}) do if b.kind == "watch" then onBelt = true end end
    local shows = onBelt or (corner ~= nil and corner:getIsVisible())
    check(shows, "5: the worn watch shows (belt " .. tostring(onBelt) .. ", corner " .. tostring(corner ~= nil and corner:getIsVisible()) .. ")")
    local st = W and W.miniState and W.miniState(p, watch)
    local gt = getGameTime()
    check(st and st.hour == gt:getHour() and st.minute == gt:getMinutes(),
        string.format("5: its face reads the game's time (%s:%s, the game %02d:%02d)", tostring(st and st.hour), tostring(st and st.minute), gt:getHour(), gt:getMinutes()))
    shot("5_watch")
end)

-- put back
step(10, function()
    if watch then pcall(function() p:removeWornItem(watch) end); pcall(function() inv:Remove(watch) end) end
    ISInventoryPaneContextMenu.createMenu = realCreate
    if apple then pcall(function() if apple:getContainer() then apple:getContainer():Remove(apple) end end) end
    if CW.isOpen() then CW.toggleBothPaired(pn) end
    p:setGodMod(godWas)
    -- (the runner charges any line with FAIL in it, so a clean result says only PASS)
    if fails == 0 then say("RESULT PASS: all " .. passes .. " checks") else say("RESULT FAIL: " .. fails .. " of " .. (passes + fails) .. " checks") end
    for _, r in ipairs(results) do if r:sub(1, 4) == "FAIL" then say("  " .. r) end end
    say("DONE")
end)

local wait = nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
