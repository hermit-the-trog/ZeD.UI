-- ZeDUI/tools/qa/zedqa_b9a_5.lua  (Nov 8 2026, hotfix 0.3.0-beta9a, fix 5): a baseball bat dropped on the Equip tab's
-- Back goes on the back, by the game's own attach (ISHotbar:attachItem, the timed ISAttachItemHotbar). The director's
-- sequence with the mouse, three ways: the bat dragged from the Character list onto the doll's Back slot; from the World
-- window's floor list onto the Back box under the doll; and, in the list view, onto the Back row under the belt
-- heading. Each time the bat must end up attached to the hotbar's Back slot. The view, the belt and the windows are put
-- back. The REAL mouse (release_check_mouse.ps1: down, move, up), so run it with batch_b9a.ps1. grep "ZEDQA b9a5".
-- Screen size is read, never set. Pictures zqa_b9a5_<w>x<h>_<n>.png.
local TAG = "b9a5"
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
local B, D = ZeD.Belt, ZeD.EquipDoll
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
local keepPins, keepTab, keepView, keepHeld
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
local function backIndex()
    for _, s in ipairs(B.slots(0)) do if s.slot and s.slot.slotType == "Back" then return s.i end end
end
local function onBack()
    local s = B.slots(0)[backIndex() or 1]
    return s and s.item or nil
end
-- the screen point of a rect stamped in a panel
local function at(panel, r) return math.floor(panel:getAbsoluteX() + r.x + r.w / 2), math.floor(panel:getAbsoluteY() + r.y + r.h / 2) end
local function dollBack()
    local c = CW()
    for _, r in ipairs(c._equipDollAll or {}) do if r.id == "back" then return at(c._equipDollPanel, r) end end
end
local function backBox()   -- the Back box under the doll, or the Back row of the list (empty belt slots)
    local c = CW()
    local bi = backIndex()
    for _, z in ipairs(c._equipBeltZones or {}) do if z.i == bi then return at(c._equipPanel, z) end end
end
-- a real drag of a bat's row onto a point
-- Each request is answered before the next (the helper's one-at-a-time handshake): press on the row, pull past the
-- drag threshold in two short moves, carry halfway, onto the target, release there. The attach is the game's timed
-- action (ISAttachItemHotbar, after a transfer out of a bag or off the floor): the check waits for the hotbar's own
-- attached item, up to 10 s, never for a field the script sets.
local function isBat(b) return b ~= nil and b:getFullType() == "Base.BaseballBat" end
local function dragBat(label, fromWin, target)
    local sx, sy, held
    add(900, function()
        sx, sy, held = nil, nil, false
        local it, x, y = nil, nil, nil
        if fromWin() then it, x, y = rowOf(fromWin(), "Base.BaseballBat") end
        if not check(it ~= nil and x ~= nil, label .. ": the bat's row is on screen") then return end
        sx, sy = x, y
        req("down " .. x .. " " .. y)
    end)
    add(150, function() if sx then req("move " .. (sx + 12) .. " " .. (sy + 10)) end end)
    add(150, function() if sx then req("move " .. (sx + 40) .. " " .. (sy + 30)) end end)
    add(300, function()
        if not sx then return end
        local c = fromWin() and fromWin()._mainContent
        held = check(c ~= nil and c._drag:isActive(), label .. ": the bat is held (the drag object is active)")
        local x, y = target()
        if not check(x ~= nil, label .. ": the target is on screen") then return end
        req("move " .. math.floor((sx + x) / 2) .. " " .. math.floor((sy + y) / 2))
    end)
    add(150, function() if sx then local x, y = target(); if x then req("move " .. x .. " " .. y) end end end)
    add(300, function()
        if not sx then return end
        local x, y = target()
        say(label .. ": released at " .. tostring(x) .. "," .. tostring(y) .. " (the game sees the pointer at " .. getMouseX() .. "," .. getMouseY() .. ")")
        req("up " .. (x or sx) .. " " .. (y or sy))
    end)
    addWhen(10000, function() return isBat(onBack()) end, function()
        local b = onBack()
        if held then
            check(isBat(b), label .. ": the bat is attached to the back (" .. tostring(b and b:getFullType()) .. ")")
        else
            say(label .. ": (no drag, so no attach to check)")
        end
        shot(label:gsub("[^%w]", "_"))
    end)
    add(300, function() local b = onBack(); if b then B.detach(0, b) end end)
    addWhen(6000, function() return onBack() == nil end, function() check(onBack() == nil, label .. ": (put back) the back is empty again") end)
    add(800, function() end)   -- (the list shows the bat again)
end

add(500, function()
    local t = p:getModData().ZeD_WinPinned
    if t then keepPins = {}; for k, v in pairs(t) do keepPins[k] = v end end
    if not CWm.isOpen() then CWm.toggleBothPaired(0) end
    keepTab, keepView = CW()._activeTab, D.view()
    CW():setPinned(true); WW():setPinned(true)
    local b = onBack()
    if b then B.detach(0, b) end   -- (the back starts empty)
    p:getInventory():AddItem("Base.BaseballBat")
    CWm.openTab(0, "equip")
    WWm.openTab(0, "loot")
    D.setView("doll")
end)
add(3500, function()
    check(onBack() == nil, "(staged) the back is empty, the Equip tab on the doll")
    shot("1_doll")
end)
dragBat("inventory to the doll's Back", CW, dollBack)
add(500, function()
    -- the bat onto the floor for the World window's turn
    local it = rowOf(CW(), "Base.BaseballBat")
    if it then ISInventoryPaneContextMenu.dropItem(it, 0) end
end)
-- (the drop is the game's timed action: wait until no bat is in the inventory, up to 6 s, then let the floor list show it)
addWhen(6000, function() return p:getInventory():getCountTypeRecurse("Base.BaseballBat") == 0 end, function() end)
add(1200, function() end)
dragBat("floor to the Back box under the doll", WW, backBox)
add(500, function()
    D.setView("list")
    local c = CW()
    keepHeld = c._equipExpanded and c._equipExpanded.held
    if c._equipExpanded then c._equipExpanded.held = true end   -- (the belt's empty slots show with the group open)
end)
add(1200, function() shot("2_list") end)
dragBat("inventory to the Back row of the list", CW, backBox)
add(800, function()
    local c = CW()
    if c._equipExpanded then c._equipExpanded.held = keepHeld end
    if keepView then D.setView(keepView) end
    if keepPins then
        p:getModData().ZeD_WinPinned = keepPins
        for _, pair in ipairs({ { CW(), "char" }, { WW(), "world" } }) do
            local win, k = pair[1], pair[2]
            local a, b = keepPins[k .. "Inv"], keepPins[k .. "Tabs"]
            if a == nil and b == nil then a, b = keepPins[k] == true, keepPins[k] == true end
            ZeD.Halves.setPin(win, "inv", a == true); ZeD.Halves.setPin(win, "drawer", b == true)
        end
    end
    if keepTab and keepTab ~= "equip" then CWm.openTab(0, keepTab) end
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
