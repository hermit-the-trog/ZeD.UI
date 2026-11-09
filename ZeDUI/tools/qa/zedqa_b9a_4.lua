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
local function req(s) local f = getFileWriter("zedqa_click.txt", true, false); f:write(s .. "\n"); f:close() end
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_" .. TAG .. "_" .. sw .. "x" .. sh .. "_" .. n .. ".png") end); say("shot " .. n) end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
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
    add(1500, function()
        for _, w in ipairs({ CW(), WW() }) do H.setPin(w, "inv", false); H.setPin(w, "drawer", false); w:setWindowShaded(false) end
        if which == "char" then CWm.openTab(0, tab) else WWm.openTab(0, tab) end
    end)
    add(800, function()
        local it, x, y = rowOf(S(), ft)
        if not check(it ~= nil, which .. ": the item's row is on screen") then return end
        sx, sy = x, y
        req("move " .. x .. " " .. y)   -- (looking through the list)
    end)
    add(3500, function()
        local s = S()
        check(H.foldedTab(s) == tab and not s._drawerOpen, which .. ": (staged) looking through the list 3.5 s, the drawer rolled in")
        check(T().windowShaded == true, which .. ": (staged) the other window rolled up meanwhile")
        shot(which .. "_1_rolled_in")
        if sx then req("down " .. sx .. " " .. sy) end
    end)
    add(700, function() if sx then req("move " .. (sx + 40) .. " " .. (sy + 30)) end end)
    add(700, function()
        local s = S()
        check(s._mainContent._drag:isActive(), which .. ": the item is held (the drag object is active)")
        check(s._drawerOpen and s._activeTab == tab and H.foldedTab(s) == nil, which .. ": the item picked up: the drawer is back on " .. tab)
        shot(which .. "_2_drawer_back")
    end)
    add(4000, function()
        local s = S()
        check(s._drawerOpen and not s._rolled and not s.windowShaded, which .. ": carried over its own list 4 s: both halves stay open")
        req("move " .. table.concat({ barMid(T()) }, " "))
    end)
    add(700, function()
        check(not T().windowShaded, which .. ": over the other window's rolled bar, it comes down")
        req("move " .. table.concat({ mid(T()._mainContent) }, " "))
    end)
    add(3000, function()
        local t, s = T(), S()
        check(not t.windowShaded and not t._rolled, which .. ": held over the other window's list 3 s, it stays down")
        check(s._drawerOpen and not s.windowShaded, which .. ": ... and the source window's drawer stays too")
        shot(which .. "_3_held_over_target")
        req("up " .. table.concat({ mid(t._mainContent) }, " "))
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
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then fail = fail + 1; say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
say("start")
