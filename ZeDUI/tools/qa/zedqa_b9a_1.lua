-- ZeDUI/tools/qa/zedqa_b9a_1.lua  (Nov 8 2026, hotfix 0.3.0-beta9a, fix 1): an item dragged over a rolled half brings
-- that half down at once, whatever the other half's pin. The director's sequence at 4K with the mouse: the Character
-- window on Equip with its drawer pinned, its inventory side unpinned and rolled under its rod; an item dragged from
-- the World window over the rod. Then the World window the same way (mirrored: its containers' rod on its left), and
-- each window with its inventory pinned and its drawer rolled in: an item held over the tab strip brings the drawer out.
-- The REAL mouse (release_check_mouse.ps1: down, move, up), so run it with batch_b9a.ps1. grep "ZEDQA b9a1".
-- Screen size is read, never set. Pictures zqa_b9a1_<w>x<h>_<n>.png. Pins and tabs are put back at the end.
local TAG = "b9a1"
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
local function pins(c, w)   -- { inv, drawer } per window
    H.setPin(CW(), "inv", c[1]); H.setPin(CW(), "drawer", c[2])
    H.setPin(WW(), "inv", w[1]); H.setPin(WW(), "drawer", w[2])
end
local function mid(panel) return math.floor(panel:getAbsoluteX() + panel:getWidth() / 2), math.floor(panel:getAbsoluteY() + panel:getHeight() / 2) end
-- the screen point of an item's row in a window's list (the list's own render map; on the name, past a stack's arrow)
local function rowAt(win, item)
    local c = win._mainContent
    local y = c and c._itemRenderYMap and c._itemRenderYMap[item]
    if not y then return nil end
    local x = (c._itemRenderXMap and c._itemRenderXMap[item]) or 0
    local cell = c._gridCell
    return math.floor(c:getAbsoluteX() + x + (cell and cell / 2 or 170)), math.floor(c:getAbsoluteY() + y + (cell and cell / 2 or ZeD.T.rowH / 2))
end
-- the first row of that type: the item and its screen point, or nil (every lookup guarded: a window or a list that
-- isn't there yet is a FAIL line, never a Lua error)
local function firstRow(win, want)
    local c = win and win._mainContent
    for _, it in ipairs(c and c._flatItems or {}) do
        if not want or it:getFullType() == want then
            local x, y = rowAt(win, it)
            if x then return it, x, y end
        end
    end
    return nil
end
local function inList(win) if win and win._mainContent then return mid(win._mainContent) end end
local function stripOf(win) return win and win[win == CW() and "_tabStripPanel" or "_actionTabStrip"] end
local function inDrawer(win)
    local strip = stripOf(win)
    if not strip then return nil end
    local sx = strip:getAbsoluteX()
    local dx = (win == CW()) and (sx + strip:getWidth() + 120) or (sx - 120)
    return math.floor(dx), math.floor(win:getAbsoluteY() + win:getHeight() / 2)
end
local function onRod(win)
    local r = win and win._rolled and win._rod
    if not (r and r:isVisible()) then return nil end
    return math.floor(r:getAbsoluteX() + r:getWidth() / 2), math.floor(r:getAbsoluteY() + win:titleBarHeight() / 2)
end
local function onStrip(win)
    local strip = stripOf(win)
    if not strip then return nil end
    return math.floor(strip:getAbsoluteX() + strip:getWidth() / 2), math.floor(strip:getAbsoluteY() + strip:getHeight() / 2)
end
local function moveTo(what, x, y)   -- (the point last: a call there keeps both its values)
    if not x then check(false, tostring(what) .. " is on screen"); return false end
    req("move " .. x .. " " .. y)
    return true
end
-- A real drag, each request answered before the next: press on the row, pull past the drag threshold in two short
-- moves, carry halfway, then onto the target. from() and to() give screen points (nil: a FAIL line, the drag skipped);
-- held() is read once the item is carried. Returns a function: did the drag start.
local function dragTo(label, from, to, held)
    local sx, sy, ok
    add(300, function()
        sx, sy = from()
        ok = check(sx ~= nil, label .. ": the row to drag is on screen")
        if ok then req("down " .. sx .. " " .. sy) end
    end)
    add(150, function() if ok then req("move " .. (sx + 12) .. " " .. (sy + 10)) end end)
    add(150, function() if ok then req("move " .. (sx + 40) .. " " .. (sy + 30)) end end)
    add(250, function()
        if not ok then return end
        check(held(), label .. ": the item is held (the drag object is active)")
        local tx, ty = to()
        if not tx then ok = check(false, label .. ": the target is on screen"); return end
        req("move " .. math.floor((sx + tx) / 2) .. " " .. math.floor((sy + ty) / 2))
    end)
    add(150, function()
        if not ok then return end
        local tx, ty = to()
        if tx then req("move " .. tx .. " " .. ty) end
    end)
    return function() return ok end
end
local function dragOf(w) local c = w and w._mainContent; return c and c._drag and c._drag:isActive() or false end

add(500, function()
    local t = p:getModData().ZeD_WinPinned
    if t then keepPins = {}; for k, v in pairs(t) do keepPins[k] = v end end
    if not CWm.isOpen() then CWm.toggleBothPaired(0) end
    keepTabs.c, keepTabs.w = CW()._activeTab, WW()._activeTab
    -- things to carry: nails on the floor (the World list), a spoon in the inventory (the Character list)
    p:getCurrentSquare():AddWorldInventoryItem("Base.Nails", 0.5, 0.5, 0)
    p:getInventory():AddItem("Base.Spoon")
end)

-- one window's turn: the target window rolls its unpinned half, an item from the other window is dragged over it
local function turn(which)
    local function T() return which == "char" and CW() or WW() end
    local function O() return which == "char" and WW() or CW() end
    local tab = which == "char" and "equip" or "maps"
    local ft = which == "char" and "Base.Nails" or "Base.Spoon"
    local item, started
    local function src() local it, x, y = firstRow(O(), ft); item = it or item; return x, y end
    add(1500, function()
        CWm.openTab(0, which == "char" and "equip" or "loot"); WWm.openTab(0, which == "world" and "maps" or "loot")
        -- the target: drawer pinned, inventory unpinned; the source window pinned whole (it stays open to drag from)
        if which == "char" then pins({ false, true }, { true, true }) else pins({ true, true }, { false, true }) end
        T():setWindowShaded(false); O():setWindowShaded(false)
    end)
    add(500, function() moveTo(which .. ": the target's drawer", inDrawer(T())) end)
    -- (the inventory rolls 2 s after the pointer leaves it: wait on its state, up to 5 s)
    addWhen(5000, function() local w = T(); return w and w._rolled == true end, function()
        local w = T()
        check(w and w._rolled == true and w._drawerOpen and w._activeTab == tab, which .. ": (staged) drawer pinned on " .. tab .. ", the inventory rolled under its rod")
        shot(which .. "_1_rolled")
    end)
    started = dragTo(which .. " to the rod", src, function() return onRod(T()) end, function() return dragOf(O()) end)
    add(700, function()
        local w = T()
        if not started() then return end
        check(not w._rolled and not w._halves.inv.rolled, which .. ": held over the rod, the rolled inventory comes down at once (0.7 s)")
        check(w._drawerOpen, which .. ": ... the pinned drawer still open")
        shot(which .. "_2_down")
        moveTo(which .. ": the target's list", inList(w))
    end)
    add(2500, function()
        local w = T()
        if started() then check(not w._rolled and w._drawerOpen and not w.windowShaded, which .. ": held over its list 2.5 s, nothing rolls up") end
        local x, y = inList(w)
        req("up " .. (x or 10) .. " " .. (y or 10))
    end)
    -- (the transfer is the game's timed action: into the inventory, or out of it onto the floor)
    local function landed() local inInv = item and item:getContainer() == p:getInventory(); return item ~= nil and ((which == "char" and inInv) or (which == "world" and not inInv)) end
    addWhen(5000, landed, function()
        if started() then check(landed(), which .. ": the drop landed in that list") end
        shot(which .. "_3_dropped")
        -- now the other way round: the inventory pinned, the drawer rolled in
        if which == "char" then pins({ true, false }, { true, true }) else pins({ true, true }, { true, false }) end
        moveTo(which .. ": the target's list", inList(T()))
    end)
    addWhen(5000, function() return H.foldedTab(T()) == tab end, function()
        local w = T()
        check(H.foldedTab(w) == tab and not w._drawerOpen, which .. ": (staged) inventory pinned, the drawer rolled in")
        check(w._activeTab == tab, which .. ": ... its tab still selected (no switch to Loot)")
        shot(which .. "_4_drawer_rolled")
        -- (a fresh thing to carry: the first one moved with the first drag)
        if which == "world" then p:getInventory():AddItem("Base.Spoon") else p:getCurrentSquare():AddWorldInventoryItem("Base.Nails", 0.5, 0.5, 0) end
    end)
    add(1200, function() end)   -- (the lists pick the new thing up)
    local started2 = dragTo(which .. " to the tab strip", src, function() return onStrip(T()) end, function() return dragOf(O()) end)
    add(700, function()
        local w = T()
        if started2() then check(w._drawerOpen and H.foldedTab(w) == nil, which .. ": held over the tab strip, the drawer comes out at once (0.7 s)") end
        shot(which .. "_5_drawer_out")
        local x, y = src()
        req("up " .. (x or 10) .. " " .. (y or 10))   -- (back over its own list: no move)
    end)
end
turn("char")
turn("world")

add(1500, function()
    if keepPins then
        p:getModData().ZeD_WinPinned = keepPins
        for _, pair in ipairs({ { CW(), "char" }, { WW(), "world" } }) do
            local win, k = pair[1], pair[2]
            local a, b = keepPins[k .. "Inv"], keepPins[k .. "Tabs"]
            if a == nil and b == nil then a, b = keepPins[k] == true, keepPins[k] == true end
            H.setPin(win, "inv", a == true); H.setPin(win, "drawer", b == true)
        end
    end
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
