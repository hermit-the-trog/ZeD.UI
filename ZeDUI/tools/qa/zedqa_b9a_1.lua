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
local function req(s) local f = getFileWriter("zedqa_click.txt", true, false); f:write(s .. "\n"); f:close() end
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_" .. TAG .. "_" .. sw .. "x" .. sh .. "_" .. n .. ".png") end); say("shot " .. n) end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
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
local function firstRow(win, want)
    local c = win._mainContent
    for _, it in ipairs(c and c._flatItems or {}) do
        if want and it:getFullType() ~= want then it = nil end
        local x, y = it and rowAt(win, it)
        if x then return it, x, y end
    end
end
local function inList(win) return mid(win._mainContent) end
local function inDrawer(win)
    local strip = win[win == CW() and "_tabStripPanel" or "_actionTabStrip"]
    local sx = strip:getAbsoluteX()
    local dx = (win == CW()) and (sx + strip:getWidth() + 120) or (sx - 120)
    return math.floor(dx), math.floor(win:getAbsoluteY() + win:getHeight() / 2)
end
local function onRod(win) local r = win._rod; return math.floor(r:getAbsoluteX() + r:getWidth() / 2), math.floor(r:getAbsoluteY() + win:titleBarHeight() / 2) end
local function onStrip(win)
    local strip = win[win == CW() and "_tabStripPanel" or "_actionTabStrip"]
    return math.floor(strip:getAbsoluteX() + strip:getWidth() / 2), math.floor(strip:getAbsoluteY() + strip:getHeight() / 2)
end

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
    local item
    add(1500, function()
        CWm.openTab(0, which == "char" and "equip" or "loot"); WWm.openTab(0, which == "world" and "maps" or "loot")
        -- the target: drawer pinned, inventory unpinned; the source window pinned whole (it stays open to drag from)
        if which == "char" then pins({ false, true }, { true, true }) else pins({ true, true }, { false, true }) end
        T():setWindowShaded(false); O():setWindowShaded(false)
        req("move " .. table.concat({ inDrawer(T()) }, " "))
    end)
    add(3200, function()
        local w = T()
        check(w._rolled == true and w._drawerOpen and w._activeTab == tab, which .. ": (staged) drawer pinned on " .. tab .. ", the inventory rolled under its rod")
        shot(which .. "_1_rolled")
        local it, x, y = firstRow(O(), which == "char" and "Base.Nails" or "Base.Spoon")
        item = it
        if not check(it ~= nil, which .. ": a row to drag in the other window's list") then return end
        say("press at " .. x .. "," .. y)
        req("down " .. x .. " " .. y)
    end)
    add(900, function() local _, x, y = firstRow(O(), which == "char" and "Base.Nails" or "Base.Spoon"); if x then req("move " .. (x + 40) .. " " .. (y + 30)) end end)
    add(900, function()
        check(O()._mainContent._drag:isActive(), which .. ": the item is held (the drag object is active)")
        req("move " .. table.concat({ onRod(T()) }, " "))
    end)
    add(700, function()
        local w = T()
        check(not w._rolled and not w._halves.inv.rolled, which .. ": held over the rod, the rolled inventory comes down at once (0.7 s)")
        check(w._drawerOpen, which .. ": ... the pinned drawer still open")
        shot(which .. "_2_down")
        req("move " .. table.concat({ inList(w) }, " "))
    end)
    add(2500, function()
        local w = T()
        check(not w._rolled and w._drawerOpen and not w.windowShaded, which .. ": held over its list 2.5 s, nothing rolls up")
        req("up " .. table.concat({ inList(w) }, " "))
    end)
    add(2500, function()
        local w = T()
        -- (the transfer is the game's timed action: into the inventory, or out of it onto the floor)
        local inInv = item and item:getContainer() == p:getInventory()
        check(item and ((which == "char" and inInv) or (which == "world" and not inInv)), which .. ": the drop landed in that list")
        shot(which .. "_3_dropped")
        -- now the other way round: the inventory pinned, the drawer rolled in
        if which == "char" then pins({ true, false }, { true, true }) else pins({ true, true }, { true, false }) end
        req("move " .. table.concat({ inList(w) }, " "))
    end)
    add(3200, function()
        local w = T()
        check(H.foldedTab(w) == tab and not w._drawerOpen, which .. ": (staged) inventory pinned, the drawer rolled in")
        check(w._activeTab == tab, which .. ": ... its tab still selected (no switch to Loot)")
        shot(which .. "_4_drawer_rolled")
        local _, x, y = firstRow(O(), which == "char" and "Base.Nails" or "Base.Spoon")
        if x then req("down " .. x .. " " .. y) end
    end)
    add(900, function() local _, x, y = firstRow(O(), which == "char" and "Base.Nails" or "Base.Spoon"); if x then req("move " .. (x + 40) .. " " .. (y + 30)) end end)
    add(900, function() req("move " .. table.concat({ onStrip(T()) }, " ")) end)
    add(700, function()
        local w = T()
        check(w._drawerOpen and H.foldedTab(w) == nil, which .. ": held over the tab strip, the drawer comes out at once (0.7 s)")
        shot(which .. "_5_drawer_out")
        local _, x, y = firstRow(O(), which == "char" and "Base.Nails" or "Base.Spoon")
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
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then fail = fail + 1; say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
say("start")
