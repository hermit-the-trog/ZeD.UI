-- ZeDUI/tools/qa/zedqa_b9a_4.lua  (Nov 8 2026, hotfix 0.3.0-beta9a, fix 4): an item held in a drag holds both halves of
-- its window, and of the window it is carried to, open until the drop. The director's sequence with the mouse: the
-- Character window on Equip, both halves unpinned; the pointer looks through the inventory long enough for the Equip
-- drawer to roll in; an item is picked up there: the drawer comes back at once, and stays while the item is carried
-- over the list and the doll (4 s); the World window, rolled up meanwhile, comes down under the item and stays down until
-- the drop. Then the World window the same way (Maps, an item from its list to the Character window).
-- The REAL mouse (release_check_mouse.ps1: down, move, up), so run it with batch_b9a.ps1. grep "ZEDQA b9a4".
-- Screen size is read, never set. Pictures zqa_b9a4_<w>x<h>_<n>.png.
local TAG = "b9a4"
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
local H = ZeD.Halves
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
local keepPins, keepTabs = nil, {}
local function mid(panel) return math.floor(panel:getAbsoluteX() + panel:getWidth() / 2), math.floor(panel:getAbsoluteY() + panel:getHeight() / 2) end
local function rowOf(win, fullType)
    local c = win._mainContent
    for _, it in ipairs(c and c._flatItems or {}) do
        if it:getFullType() == fullType then
            local y = c._itemRenderYMap and c._itemRenderYMap[it]
            if not y then return nil end
            local x = (c._itemRenderXMap and c._itemRenderXMap[it]) or 0
            local cell = c._gridCell
            return it, math.floor(c:getAbsoluteX() + x + (cell and cell / 2 or 170)), math.floor(c:getAbsoluteY() + y + (cell and cell / 2 or ZeD.T.rowH / 2))
        end
    end
end
local function barMid(w) return math.floor(w:getAbsoluteX() + w:getWidth() / 2), math.floor(w:getAbsoluteY() + w:titleBarHeight() / 2) end
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
-- the window down and whole, both pins on (nothing rolls while the pointer travels), on its tab
local function stageDown(w, tab, isChar)
    H.setPin(w, "inv", true); H.setPin(w, "drawer", true)
    w:setWindowShaded(false)
    if w._rolled and ZeD.Curtain then ZeD.Curtain.finishUnroll(w) end
    if H.showAll then H.showAll(w) end
    if tab then if isChar then CWm.openTab(0, tab) else WWm.openTab(0, tab) end end
end

add(500, function()
    local t = p:getModData().ZeD_WinPinned
    if t then keepPins = {}; for k, v in pairs(t) do keepPins[k] = v end end
    if not CWm.isOpen() then CWm.toggleBothPaired(0) end
    keepTabs.c, keepTabs.w = CW()._activeTab, WW()._activeTab
    p:getInventory():AddItem("Base.Spoon")
    p:getCurrentSquare():AddWorldInventoryItem("Base.Nails", 0.5, 0.5, 0)
end)

local function turn(which)
    local function S() return which == "char" and CW() or WW() end   -- the window the item is picked up in
    local function T() return which == "char" and WW() or CW() end   -- the window it is carried to
    local tab = which == "char" and "equip" or "maps"
    local ft = which == "char" and "Base.Spoon" or "Base.Nails"
    local sx, sy
    -- The staging: both windows down and whole with their pins on, the item's row scrolled into view, the pointer
    -- on it, and only then every pin off. (Unpinned first, the source window rolled up before the pointer arrived.)
    add(1500, function()
        stageDown(T(), nil, which ~= "char")
        stageDown(S(), tab, which == "char")
    end)
    addWhen(5000, function() return S() ~= nil and revealRow(S(), (rowOf(S(), ft))) end, function() end)
    local held = false
    add(300, function()
        sx, sy = nil, nil
        local it, x, y = nil, nil, nil
        if S() then it, x, y = rowOf(S(), ft) end
        if not check(it ~= nil and x ~= nil and rowShown(S(), it), which .. ": the item's row is on screen") then return end
        sx, sy = x, y
        req("move " .. x .. " " .. y)   -- (looking through the list)
    end)
    add(300, function()
        for _, w in ipairs({ CW(), WW() }) do H.setPin(w, "inv", false); H.setPin(w, "drawer", false) end
    end)
    -- (the drawer folds 2 s after the pointer leaves it; the other window rolls 2 s after: wait on both, up to 6 s)
    -- (and the fold finished: foldedTab is set as the fold starts, and at Deck size the list slides ~57 px over the next
    -- quarter second as the window takes back what the half-screen cap cost it; a press then lands on nothing)
    local lastX
    addWhen(6000, function()
        local s, t = S(), T()
        if not (H.foldedTab(s) == tab and t and t.windowShaded == true and (s._drawerEffW or 0) <= 0) then lastX = nil; return false end
        local x = s._mainContent and s._mainContent:getAbsoluteX()
        local still = (lastX ~= nil and x == lastX)
        lastX = x
        return still
    end, function()
        local s = S()
        check(H.foldedTab(s) == tab and not s._drawerOpen, which .. ": (staged) looking through the list, the drawer rolled in")
        check(T().windowShaded == true, which .. ": (staged) the other window rolled up meanwhile")
        shot(which .. "_1_rolled_in")
        -- the press again on the row as it is now (each request answered before the next)
        local it, x, y = rowOf(s, ft)
        if it and x then sx, sy = x, y end
        -- (the Deck's char turn pressed over no row: say where the row is now and what lies under that point)
        local c = s._mainContent
        local zz = sx and c and c.hitZoneAt and c:hitZoneAt(sx - c:getAbsoluteX(), sy - c:getAbsoluteY())
        say(which .. ": the press point " .. tostring(sx) .. "," .. tostring(sy) .. " (row found " .. tostring(it ~= nil)
            .. ", list " .. (c and (c:getAbsoluteX() .. "," .. c:getAbsoluteY() .. " " .. c:getWidth() .. "x" .. c:getHeight()) or "-")
            .. ") over " .. tostring(zz and (type(zz.id) == "string" and zz.id or (zz.id and zz.id.getFullType and zz.id:getFullType()))))
        if sx then req("down " .. sx .. " " .. sy) end
    end)
    add(100, function()
        -- (what the press did, for a drag that does not start: the Deck run's char turn held nothing)
        local s = S()
        local c = s and s._mainContent
        local d = c and c._drag
        local lx, ly = getMouseX() - c:getAbsoluteX(), getMouseY() - c:getAbsoluteY()
        local z = c.hitZoneAt and c:hitZoneAt(lx, ly)
        say(which .. ": after the press: pending " .. tostring(d and d.isPending and d:isPending()) .. ", card " .. tostring(s._drawerItem ~= nil)
            .. ", tab " .. tostring(s._activeTab) .. ", the pointer at " .. getMouseX() .. "," .. getMouseY() .. " over "
            .. tostring(z and (type(z.id) == "string" and z.id or (z.id and z.id.getFullType and z.id:getFullType()))) .. ", the list at "
            .. c:getAbsoluteX() .. "," .. c:getAbsoluteY())
        if sx then req("move " .. (sx + 12) .. " " .. (sy + 10)) end
    end)
    add(150, function() if sx then req("move " .. (sx + 40) .. " " .. (sy + 30)) end end)
    add(150, function() if sx then req("move " .. (sx + 80) .. " " .. (sy + 60)) end end)   -- (well past any threshold)
    add(400, function()
        if not sx then return end
        local s = S()
        held = check(s._mainContent._drag:isActive(), which .. ": the item is held (the drag object is active)")
        if held then check(s._drawerOpen and s._activeTab == tab and H.foldedTab(s) == nil, which .. ": the item picked up: the drawer is back on " .. tab) end
        shot(which .. "_2_drawer_back")
    end)
    add(4000, function()
        local s = S()
        if held then check(s._drawerOpen and not s._rolled and not s.windowShaded, which .. ": carried over its own list 4 s: both halves stay open") end
        local t = T()
        if t then req("move " .. table.concat({ barMid(t) }, " ")) end
    end)
    add(700, function()
        if held then check(not T().windowShaded, which .. ": over the other window's rolled bar, it comes down") end
        local t = T()
        if t and t._mainContent then req("move " .. table.concat({ mid(t._mainContent) }, " ")) end
    end)
    add(3000, function()
        local t, s = T(), S()
        if held then
            check(not t.windowShaded and not t._rolled, which .. ": held over the other window's list 3 s, it stays down")
            check(s._drawerOpen and not s.windowShaded, which .. ": ... and the source window's drawer stays too")
        end
        shot(which .. "_3_held_over_target")
        local x, y = mid(t._mainContent)
        req("up " .. x .. " " .. y)
    end)
    add(2500, function() shot(which .. "_4_dropped") end)
end
turn("char")
turn("world")

add(1000, function()
    if keepPins then
        p:getModData().ZeD_WinPinned = keepPins
        for _, pair in ipairs({ { CW(), "char" }, { WW(), "world" } }) do
            local win, k = pair[1], pair[2]
            local a, b = keepPins[k .. "Inv"], keepPins[k .. "Tabs"]
            if a == nil and b == nil then a, b = keepPins[k] == true, keepPins[k] == true end
            H.setPin(win, "inv", a == true); H.setPin(win, "drawer", b == true)
        end
    end
    CW():setWindowShaded(false); WW():setWindowShaded(false)
    if keepTabs.c and keepTabs.c ~= "loot" then CWm.openTab(0, keepTabs.c) end
    if keepTabs.w and keepTabs.w ~= "loot" then WWm.openTab(0, keepTabs.w) end
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
