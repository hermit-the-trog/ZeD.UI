-- ZeDUI/tools/qa/zedqa_b9a_2.lua  (Nov 8 2026, hotfix 0.3.0-beta9a, fix 2): a closed stack's row carries the whole
-- stack, as vanilla's drag does. The director's sequence with the mouse: six nails on the floor (one closed stack in
-- the World window's list) dragged into the Character window; that stack dragged from the Character list out onto the
-- floor (a release over the world); the same in the grid view; then the stack opened and one row of it dragged, which
-- moves only that one. The REAL mouse (release_check_mouse.ps1: down, move, up), so run it with batch_b9a.ps1.
-- grep "ZEDQA b9a2". Screen size is read, never set. Pictures zqa_b9a2_<w>x<h>_<n>.png.
local TAG = "b9a2"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local pass, fail = 0, 0
local function check(ok, s) if ok then pass = pass + 1 else fail = fail + 1 end; say((ok and "PASS " or "FAIL ") .. s); return ok end
if ZEDQA_HOME then ZEDQA_HOME(TAG) end
local p = getPlayer()
local core = getCore()
local sw, sh = core:getScreenWidth(), core:getScreenHeight()
say("screen " .. sw .. "x" .. sh)
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local function CW() return CWm.getWindow() end
local function WW() return WWm.getWindow() end
local IR = ZeD.InventoryRenderer
-- The real-mouse helper (release_check_mouse.ps1) takes ONE request at a time: it deletes zedqa_click.txt, acts
-- (down, move and up 250 ms each) and writes zedqa_click_done.txt. So, as zedqa_dual_pin's req and mouse(): clear the
-- done file, write the request, and the plan waits for "done" before it counts the next step's delay (drive below).
-- Back-to-back requests without the wait overwrote each other: drags never started and clicks were lost.
local pending, pendAt = nil, 0
local function req(s)
    pcall(function() local fw = getFileWriter("zedqa_click_done.txt", true, false); fw:write(""); fw:close() end)
    pcall(function() local f = getFileWriter("zedqa_click.txt", true, false); f:write(s); f:close() end)
    pending, pendAt = s, getTimestampMs()
end
local function done()
    local r = getFileReader("zedqa_click_done.txt", false)
    local l = r and r:readLine()
    if r then r:close() end
    return l ~= nil and l:find("done", 1, true) ~= nil
end
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_" .. TAG .. "_" .. sw .. "x" .. sh .. "_" .. n .. ".png") end); say("shot " .. n) end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
-- a step that runs once cond() is true, or after max ms (a timed action ending, a state settling)
local function addWhen(max, cond, fn) plan[#plan + 1] = { ms = max, cond = cond, fn = fn } end
local keepPins
local function mid(panel) return math.floor(panel:getAbsoluteX() + panel:getWidth() / 2), math.floor(panel:getAbsoluteY() + panel:getHeight() / 2) end
-- the screen point of a row (nth row of that type, 1 = the stack's own row), from the list's render map
local function rowOf(win, fullType, nth)
    local c = win._mainContent
    local n = 0
    for _, it in ipairs(c and c._flatItems or {}) do
        if it:getFullType() == fullType then
            n = n + 1
            if n == (nth or 1) then
                local y = c._itemRenderYMap and c._itemRenderYMap[it]
                if not y then return nil end
                local x = (c._itemRenderXMap and c._itemRenderXMap[it]) or 0
                local cell = c._gridCell
                return it, math.floor(c:getAbsoluteX() + x + (cell and cell / 2 or 170)), math.floor(c:getAbsoluteY() + y + (cell and cell / 2 or ZeD.T.rowH / 2))
            end
        end
    end
end
local function nailsHeld() return p:getInventory():getCountTypeRecurse("Base.Nails") end
-- Is the row really under its point (the list's own hit zone there is that thing)? A long list keeps rows past its
-- view: their render y is beyond the list, and a press there landed on another row or off the window.
local function rowShown(win, it)
    local c = win and win._mainContent
    local y = it and c and c._itemRenderYMap and c._itemRenderYMap[it]
    if not y or not c.hitZoneAt then return false end
    local x = (c._itemRenderXMap and c._itemRenderXMap[it]) or 0
    local cell = c._gridCell
    local lx, ly = x + (cell and cell / 2 or 170), y + (cell and cell / 2 or ZeD.T.rowH / 2)
    if ly < 0 or ly >= c:getHeight() then return false end
    local z = c:hitZoneAt(lx, ly)
    return z ~= nil and z.id == it
end
-- one wheel notch toward the row each call (an addWhen condition, once a frame): true once it shows
local function revealRow(win, it)
    if not it then return false end
    if rowShown(win, it) then return true end
    local c = win._mainContent
    local y = c._itemRenderYMap and c._itemRenderYMap[it] or 0
    if c._scroll and c._scroll.handleMouseWheel then c._scroll:handleMouseWheel((y < 0) and -1 or 1) end
    return false
end
-- a real click on a hit zone of a window's list (the stack's chevron), screen point or nil
local function zonePoint(win, id)
    local c = win and win._mainContent
    for _, z in ipairs(c and c._hitZones or {}) do
        if z.id == id then return math.floor(c:getAbsoluteX() + z.x + z.w / 2), math.floor(c:getAbsoluteY() + z.y + z.h / 2) end
    end
end
-- a point over the world, clear of both windows and the belt
local function worldPoint()
    local bot = math.max(CW():getAbsoluteY() + CW():getHeight(), WW():getAbsoluteY() + WW():getHeight())
    return math.floor(sw / 2), math.floor(math.min(bot + 60, sh - 200))
end
-- A real drag, each request answered before the next: press on the row, pull past the drag threshold in two short
-- moves, carry halfway, onto the target, release there. A row not on screen is a FAIL line and no drag.
local function drag(label, fromWin, fullType, nth, to)
    local sx, sy
    -- (the row scrolled into the list's view first: a long list keeps it below, and a press there lands elsewhere)
    addWhen(5000, function() local w = fromWin(); return w ~= nil and revealRow(w, (rowOf(w, fullType, nth))) end, function() end)
    add(300, function()
        sx, sy = nil, nil
        local w = fromWin()
        local it, x, y = nil, nil, nil
        if w then it, x, y = rowOf(w, fullType, nth) end
        if not check(it ~= nil and x ~= nil, label .. ": the row to drag is on screen") then return end
        sx, sy = x, y
        req("down " .. x .. " " .. y)
    end)
    add(150, function() if sx then req("move " .. (sx + 12) .. " " .. (sy + 10)) end end)
    add(150, function() if sx then req("move " .. (sx + 40) .. " " .. (sy + 30)) end end)
    add(250, function()
        if not sx then return end
        local w = fromWin()
        local c = w and w._mainContent
        check(c ~= nil and c._drag ~= nil and c._drag:isActive(), label .. ": the row is held (the drag object is active)")
        local x, y = to()
        if x then req("move " .. math.floor((sx + x) / 2) .. " " .. math.floor((sy + y) / 2)) end
    end)
    add(150, function() if sx then local x, y = to(); if x then req("move " .. x .. " " .. y) end end end)
    add(300, function() if sx then local x, y = to(); req("up " .. (x or sx) .. " " .. (y or sy)) end end)
end
-- wait for the count of nails held to reach a number (the moves are the game's timed actions), up to 9 s
local function heldReaches(f) return function() local okC, r = pcall(f); return okC and r end end

local before
add(500, function()
    local t = p:getModData().ZeD_WinPinned
    if t then keepPins = {}; for k, v in pairs(t) do keepPins[k] = v end end
    if not CWm.isOpen() then CWm.toggleBothPaired(0) end
    CW():setPinned(true); WW():setPinned(true)   -- (nothing rolls while the stacks move)
    CWm.openTab(0, "loot"); WWm.openTab(0, "loot")
    local sq = p:getCurrentSquare()
    for _ = 1, 6 do sq:AddWorldInventoryItem("Base.Nails", 0.5, 0.5, 0) end
end)
-- (both lists' nails stacks closed, by their chevrons, if a run before left one open)
for _, W in ipairs({ CW, WW }) do
    addWhen(3000, function() local it = rowOf(W(), "Base.Nails", 1); return it == nil or revealRow(W(), it) end, function()
        local x, y = zonePoint(W(), "stack:Base.Nails")
        if x and rowOf(W(), "Base.Nails", 2) then req("left " .. x .. " " .. y) end
    end)
end
add(1500, function()
    before = nailsHeld()
    say("nails held before: " .. before)
    shot("1_floor_stack")
end)
-- 1 the floor's closed stack into the Character list
drag("World to Character", WW, "Base.Nails", 1, function() return mid(CW()._mainContent) end)
addWhen(9000, heldReaches(function() return nailsHeld() - before >= 6 end), function()
    check(nailsHeld() - before >= 6, "a closed stack dragged from the World list: all six nails moved (" .. before .. " to " .. nailsHeld() .. ")")
    shot("2_in_inventory")
    before = nailsHeld()
end)
-- 2 that stack from the Character list out onto the floor
drag("Character to the floor", CW, "Base.Nails", 1, worldPoint)
addWhen(9000, heldReaches(function() return before - nailsHeld() >= 6 end), function()
    check(before - nailsHeld() >= 6, "a closed stack dragged out over the world: all six dropped (" .. before .. " to " .. nailsHeld() .. ")")
    shot("3_on_floor")
    -- 3 the grid: the floor's list as cells
    local inv = WW()._mainContent._inventory
    local key = IR.containerKey(inv, p)
    say("floor key " .. tostring(key))
    IR.setGridKey(key, true)
    before = nailsHeld()
end)
add(800, function() shot("4_grid") end)
drag("grid cell to Character", WW, "Base.Nails", 1, function() return mid(CW()._mainContent) end)
addWhen(9000, heldReaches(function() return nailsHeld() - before >= 6 end), function()
    check(nailsHeld() - before >= 6, "a grid cell (the grid opens no stacks): all six moved (" .. before .. " to " .. nailsHeld() .. ")")
    local inv = WW()._mainContent._inventory
    IR.setGridKey(IR.containerKey(inv, p), false)
    before = nailsHeld()
end)
-- 4 the stack opened in the Character list by its own chevron (a real click: setting the open stacks from the script
-- left the list's kept model closed, so the second row never showed): then one row of it moves one nail
addWhen(5000, function() return revealRow(CW(), (rowOf(CW(), "Base.Nails", 1))) end, function() end)
add(300, function()
    local x, y = zonePoint(CW(), "stack:Base.Nails")
    if check(x ~= nil, "the nails stack's chevron is on screen") then req("left " .. x .. " " .. y) end
end)
addWhen(3000, function() return rowOf(CW(), "Base.Nails", 2) ~= nil end, function()
    check(rowOf(CW(), "Base.Nails", 2) ~= nil, "the chevron opens the stack (a second nails row)")
    before = nailsHeld()
    shot("5_open_stack")
end)
drag("one row of an open stack", CW, "Base.Nails", 2, function() return mid(WW()._mainContent) end)
add(4000, function()
    check(before - nailsHeld() == 1, "an open stack's row moves only its own nail (" .. before .. " to " .. nailsHeld() .. ")")
    shot("6_one_moved")
end)
-- (the stack closed again by its chevron, as the run found it)
addWhen(5000, function() return revealRow(CW(), (rowOf(CW(), "Base.Nails", 1))) end, function()
    local x, y = zonePoint(CW(), "stack:Base.Nails")
    if x and rowOf(CW(), "Base.Nails", 2) then req("left " .. x .. " " .. y) end
end)
add(1000, function()
    if keepPins then
        p:getModData().ZeD_WinPinned = keepPins
        for _, pair in ipairs({ { CW(), "char" }, { WW(), "world" } }) do
            local win, k = pair[1], pair[2]
            local a, b = keepPins[k .. "Inv"], keepPins[k .. "Tabs"]
            if a == nil and b == nil then a, b = keepPins[k] == true, keepPins[k] == true end
            ZeD.Halves.setPin(win, "inv", a == true); ZeD.Halves.setPin(win, "drawer", b == true)
        end
    end
    say(string.format("RESULT %d pass, %d fail", pass, fail))
    say("DONE")
end)
local function drive()
    local now = getTimestampMs()
    if pending then
        if done() then
            pending = nil; t0 = now
        elseif now - pendAt > 8000 then
            fail = fail + 1; say("ERR the mouse helper never answered: " .. tostring(pending)); pending = nil; t0 = now
        else
            return
        end
    end
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if st.cond then
        local okC, met = pcall(st.cond)
        if not (okC and met) and now - t0 < st.ms then return end
    elseif now - t0 < st.ms then
        return
    end
    t0 = now; i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then fail = fail + 1; say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
say("start")
