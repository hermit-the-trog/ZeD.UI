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
local function req(s) local f = getFileWriter("zedqa_click.txt", true, false); f:write(s .. "\n"); f:close() end
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_" .. TAG .. "_" .. sw .. "x" .. sh .. "_" .. n .. ".png") end); say("shot " .. n) end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
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
-- a point over the world, clear of both windows and the belt
local function worldPoint()
    local bot = math.max(CW():getAbsoluteY() + CW():getHeight(), WW():getAbsoluteY() + WW():getHeight())
    return math.floor(sw / 2), math.floor(math.min(bot + 60, sh - 200))
end
-- a real drag: press on a row, pull past the threshold, carry, release
local function drag(label, fromWin, fullType, nth, to)
    local sx, sy
    add(800, function()
        local it, x, y = rowOf(fromWin(), fullType, nth)
        if not check(it ~= nil, label .. ": the row to drag is on screen") then return end
        sx, sy = x, y
        req("down " .. x .. " " .. y)
    end)
    add(700, function() if sx then req("move " .. (sx + 40) .. " " .. (sy + 30)) end end)
    add(700, function()
        local c = fromWin()._mainContent
        check(c._drag:isActive(), label .. ": the row is held (the drag object is active)")
        local x, y = to()
        req("move " .. x .. " " .. y)
    end)
    add(900, function() local x, y = to(); req("up " .. x .. " " .. y) end)
end

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
add(1500, function()
    local wc, cc = WW()._mainContent, CW()._mainContent
    if wc._expandedStacks then wc._expandedStacks["Base.Nails"] = nil end
    if cc._expandedStacks then cc._expandedStacks["Base.Nails"] = nil end
    before = nailsHeld()
    say("nails held before: " .. before)
    shot("1_floor_stack")
end)
-- 1 the floor's closed stack into the Character list
drag("World to Character", WW, "Base.Nails", 1, function() return mid(CW()._mainContent) end)
add(7000, function()
    check(nailsHeld() - before >= 6, "a closed stack dragged from the World list: all six nails moved (" .. before .. " to " .. nailsHeld() .. ")")
    shot("2_in_inventory")
    before = nailsHeld()
end)
-- 2 that stack from the Character list out onto the floor
drag("Character to the floor", CW, "Base.Nails", 1, worldPoint)
add(7000, function()
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
add(7000, function()
    check(nailsHeld() - before >= 6, "a grid cell (the grid opens no stacks): all six moved (" .. before .. " to " .. nailsHeld() .. ")")
    local inv = WW()._mainContent._inventory
    IR.setGridKey(IR.containerKey(inv, p), false)
    -- 4 the stack opened in the Character list: one row of it moves one nail
    local cc = CW()._mainContent
    cc._expandedStacks = cc._expandedStacks or {}
    cc._expandedStacks["Base.Nails"] = true
    if IR.dirtyModels then IR.dirtyModels() end
    before = nailsHeld()
end)
add(800, function() shot("5_open_stack") end)
drag("one row of an open stack", CW, "Base.Nails", 2, function() return mid(WW()._mainContent) end)
add(4000, function()
    check(before - nailsHeld() == 1, "an open stack's row moves only its own nail (" .. before .. " to " .. nailsHeld() .. ")")
    shot("6_one_moved")
    CW()._mainContent._expandedStacks["Base.Nails"] = nil
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
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then fail = fail + 1; say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
say("start")
