-- ZeDUI/tools/qa/zedqa_drag_real.lua  (Nov 6 2026, QA; FAIV's second report): the real mouse, press, carry, hold and release, with no script faking the pointer. An item
-- in the World window's list is dragged onto the rolled-up Character window: over its title bar it rolls down, and the drop on its list lands. The presses go through
-- release_check_mouse.ps1 (down, move, up), so run it with batch_drag.ps1. grep "ZEDQA drg". Pictures: zqa_drg_*.png.
local function say(s) print("ZEDQA drg " .. tostring(s)) end
local function check(ok, s) say((ok and "PASS " or "FAIL ") .. s); return ok end
if ZEDQA_HOME then ZEDQA_HOME("drg") end
local p = getPlayer()
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local CW, WW = CWm.getWindow, WWm.getWindow
local function req(s) local f = getFileWriter("zedqa_click.txt", true, false); f:write(s .. "\n"); f:close() end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_drg_" .. n .. ".png") end) end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local keepPins
local item, startX, startY
local function nails() return p:getInventory():getItems():size() end   -- (any item: the top row of the list is what's carried)
local before = 0
local function worldRow()
    local w = WW()
    for _, z in ipairs(w._focusRing or {}) do
        if tostring(z.zone):find("MainInv", 1, true) then
            for _, e in ipairs(z.elements or {}) do
                if tostring(e.id):find("invrow", 1, true) and type(e.x) == "number" then return e end
            end
        end
    end
    return nil
end
local function titleOf(win) return math.floor(win:getAbsoluteX() + win:getWidth() / 2), math.floor(win:getAbsoluteY() + win:titleBarHeight() / 2) end

add(500, function()
    keepPins = p:getModData().ZeD_WinPinned
    if not CWm.isOpen() then CWm.toggleBothPaired(0) end
end)
add(1500, function()
    local sq = p:getCurrentSquare()
    sq:AddWorldInventoryItem("Base.Nails", 0.5, 0.5, 0)
    before = nails()
    local c, w = CW(), WW()
    c:setPinned(false); w:setPinned(true)   -- (the World window pinned: FAIV's case is the Character window rolled; unpinned, the World window rolls up too)
    c:setWindowShaded(false); w:setWindowShaded(false)
    if c._activeTab ~= "loot" then CWm.openTab(0, "loot") end
    if w._activeTab ~= "loot" then WWm.openTab(0, "loot") end
end)
add(1500, function()
    local c = CW()
    pcall(ZeD.Input.Focus.claimFocus, WW())
    c._autoShaded = true
    c:setWindowShaded(true)
    check(c.windowShaded == true, "the Character window is rolled up")
    shot("1_rolled")
end)
add(1200, function()
    local w = WW()
    local e = worldRow()
    if not check(e ~= nil, "a row in the World window's list") then return end
    local cc = w._mainContent
    startX = math.floor(cc:getAbsoluteX() + e.x + 170)   -- (on the name: the row's left end holds a stack's arrow)
    startY = math.floor(cc:getAbsoluteY() + e.y + (e.h or 20) / 2)
    say("press at " .. startX .. "," .. startY)
    req("down " .. startX .. " " .. startY)
end)
add(1800, function() if startX then req("move " .. (startX - 60) .. " " .. (startY + 30)) end end)
add(1500, function()
    local x, y = titleOf(CW())
    say("carried to the title bar at " .. x .. "," .. y)
    req("move " .. x .. " " .. y)
end)
add(4000, function()
    local c = CW()
    check(c.windowShaded ~= true, "held over the title bar, the rolled window rolls down")
    shot("2_over_title")
    local cc = c._mainContent
    req("move " .. math.floor(cc:getAbsoluteX() + cc:getWidth() / 2) .. " " .. math.floor(cc:getAbsoluteY() + cc:getHeight() / 2))
end)
add(2000, function()
    check(CW().windowShaded ~= true, "still down over its list, the item held")
    shot("3_over_list")
    local cc = CW()._mainContent
    req("up " .. math.floor(cc:getAbsoluteX() + cc:getWidth() / 2) .. " " .. math.floor(cc:getAbsoluteY() + cc:getHeight() / 2))
end)
add(4500, function()
    check(nails() > before, "the drop landed: the item is in the inventory (" .. before .. " to " .. nails() .. ")")
    shot("4_dropped")
end)
add(500, function()
    if keepPins then
        local c, w = CW(), WW()
        c.pinned, w.pinned = keepPins.char == true, keepPins.world == true
    end
    CW():setWindowShaded(false)
    say("DONE")
end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
