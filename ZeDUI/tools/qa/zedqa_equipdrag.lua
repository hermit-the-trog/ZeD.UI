-- ZeDUI/tools/qa/zedqa_equipdrag.lua  (Oct 20 2026)
-- In game on the ZeD-QA save: the Equip tab's rows and doll slots as drag sources
-- (EquipmentTab.pressSlot / dragMove / dragRelease, handleDrop). Wears a cap and
-- a jacket and holds a hammer, then through the drawer's real mouse handlers:
--   a press released in place selects (the card), on a list row and a doll slot;
--   a press moved off the row is the drag (ghost, ISMouseDrag, the row dimmed);
--   a right press calls it off; a release over the Equip tab does nothing;
--   the cap and the hammer dropped on a bag leave the body and the hand by
--   vanilla's transfer; the jacket dropped on its own container does nothing;
--   the jacket dropped on the floor leaves by vanilla's drop, then comes back.
-- The mouse is faked (getMouseX / getMouseY are replaced for the run and put
-- back at the end); the drop targets are chosen by replacing ZeD.Curtain.dropTarget
-- and ZeD.Belt.takeDrop for the run. Everything is put back. Screenshots
-- zqa_eqd_*.png. grep "ZEDQA eqd"; PASS / FAIL lines, ERR for exceptions.
local p = getPlayer()
local pn = p:getPlayerNum()
local inv = p:getInventory()
local Doll = ZeD.EquipDoll
local ET = ZeD.EquipmentTab
local function say(s) print("ZEDQA eqd " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_eqd_" .. n .. ".png") end) end
local function check(name, ok, extra)
    say((ok and "PASS " or "FAIL ") .. name .. (extra and (" | " .. tostring(extra)) or ""))
end
local function cw() return ZeD_CharacterWindow.getWindow() end
local function tab(id)
    local w = cw(); local strip = w and w._tabStripPanel
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. id then if w._activeTab ~= id then strip:onMouseDown(z.x + 2, z.y + 2) end; return true end
    end
end

-- the fake mouse and the fake drop target, put back by restore()
local realMX, realMY, realMB = getMouseX, getMouseY, isMouseButtonDown
local mbDown = false   -- the faked left button (the drawer asks it before a pending press can become a drag)
local origDT, origTD = ZeD.Curtain.dropTarget, ZeD.Belt.takeDrop
local fx, fy = 0, 0
local stubDest = nil
local function restore()
    getMouseX, getMouseY, isMouseButtonDown = realMX, realMY, realMB
    ZeD.Curtain.dropTarget, ZeD.Belt.takeDrop = origDT, origTD
end
local function arm()
    getMouseX = function() return fx end
    getMouseY = function() return fy end
    isMouseButtonDown = function(b) if b == 0 then return mbDown end return realMB(b) end
    ZeD.Curtain.dropTarget = function() return stubDest end
    ZeD.Belt.takeDrop = function() return false end
end

-- the steps: {wait = n ticks, fn} or {cond, max, fn, label} (fn(true) when the condition came, fn(false) at timeout)
local q, qi, qt = {}, 1, 0
local function step(wait, fn) q[#q + 1] = { wait = wait, fn = fn } end
local function untilTrue(label, cond, max, fn) q[#q + 1] = { label = label, cond = cond, max = max, fn = fn } end

local origView = Doll.view()
local origListExp = nil
local cap, jacket, hammer, bag
local function drawer() return cw()._drawerPanel end
local function up() mbDown = false; drawer():onMouseUp(0, 0) end
local function zoneOf(t)
    for _, z in ipairs(cw()._equipSlotZones or {}) do if z.type == t then return z end end
end
local function d() return cw()._equipDrag end
local function queueN()
    local qq = ISTimedActionQueue.getTimedActionQueue(p)
    return qq and qq.queue and #qq.queue or 0
end
-- press on a slot's centre, then move away (the drag starts); returns the zone
local function pressAt(t)
    local z = zoneOf(t)
    if not z then say("FAIL no zone " .. t); return nil end
    fx, fy = drawer():getAbsoluteX() + z.x + math.floor(z.w / 2), drawer():getAbsoluteY() + z.y + math.floor(z.h / 2)
    mbDown = true
    drawer():onMouseDown(z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
    return z
end
local function startDrag(t)
    local z = pressAt(t)
    if not z then return nil end
    fx, fy = fx + 60, fy + 20
    drawer():onMouseMove(0, 0)
    return z
end
-- a release at the faked spot, away from the drawer (the screen's far corner)
local function releaseFar()
    fx, fy = getCore():getScreenWidth() - 3, getCore():getScreenHeight() - 3
    up()
end

step(2, function()
    arm()
    if not (cw() and cw():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(pn) end
end)
step(20, function()
    cap = inv:AddItem("Base.Hat_BaseballCapBlue"); p:setWornItem(cap:getBodyLocation(), cap)
    -- (a plain jacket: the padded one is the hood-up kind, which takes the hat's place on the body)
    jacket = inv:AddItem("Base.Jacket_Varsity"); p:setWornItem(jacket:getBodyLocation(), jacket)
    hammer = inv:AddItem("Base.Hammer"); p:setPrimaryHandItem(hammer)
    bag = inv:AddItem("Base.Bag_Schoolbag")
    triggerEvent("OnClothingUpdated", p)
    tab("equip")
    origListExp = cw()._equipListExpanded
    Doll.setView("list")
    cw()._equipListExpanded = true
end)
step(70, function()
    local ids = {}
    for _, z in ipairs(cw()._equipSlotZones or {}) do ids[#ids + 1] = z.type end
    say("list slots {" .. table.concat(ids, ",") .. "}")
    local wn = {}
    local wi = p:getWornItems()
    for i = 1, wi:size() do local w = wi:get(i - 1); wn[#wn + 1] = tostring(w:getLocation()) .. "=" .. tostring(w:getItem():getType()) end
    say("worn {" .. table.concat(wn, ",") .. "} cap " .. tostring(cap) .. " jacket " .. tostring(jacket) .. " pri " .. tostring(p:getPrimaryHandItem())
        .. " | tab " .. tostring(cw()._activeTab) .. " listExp " .. tostring(cw()._equipListExpanded) .. " view " .. tostring(Doll.view()))
    check("rows for cap, jacket, hammer", zoneOf("HAT") and zoneOf("OUT") and zoneOf("PRI"))
    shot(1)
end)

-- A. a plain click selects
step(5, function()
    pressAt("HAT")
    check("press waits (pending, nothing selected yet)", d():isPending() and cw()._equipSelected == nil)
    up()
    check("click selects the row", cw()._equipSelected == "HAT" and not d():isPending() and not d():isActive(), cw()._equipSelected)
end)
step(20, function() cw()._equipSelected = nil end)

-- B. a drag: ghost, ISMouseDrag, dim; the release over the Equip tab does nothing
step(10, function()
    startDrag("HAT")
    check("moved press is the drag", d():isActive() and cw()._equipSelected == nil)
    check("ISMouseDrag carries the item", ISMouseDrag.dragging ~= nil and ISMouseDrag.dragging[1] == cap)
    check("draggedItem names it", ET.draggedItem(cw()) == cap)
end)
step(4, function() shot(2) end)
step(2, function()
    local z = zoneOf("HAT")
    fx, fy = drawer():getAbsoluteX() + z.x + 6, drawer():getAbsoluteY() + z.y + 6
    up()
    check("release on the Equip tab: drag over, nothing queued, cap still worn",
        not d():isActive() and ISMouseDrag.dragging == nil and queueN() == 0 and p:isEquipped(cap) and cap:getContainer() == inv,
        "queue " .. queueN())
end)

-- C. a right press calls the drag off
step(10, function()
    startDrag("OUT")
    check("drag started on the jacket", d():isActive())
    mbDown = false; drawer():onRightMouseDown(0, 0)
    check("right press cancels it", not d():isActive() and ISMouseDrag.dragging == nil and cw()._equipSelected == nil)
end)

-- D. the doll: a click selects, a moved press drags, a right press cancels
step(10, function()
    Doll.setView("doll")
end)
step(50, function()
    local ids = {}
    for _, z in ipairs(cw()._equipSlotZones or {}) do ids[#ids + 1] = z.type end
    say("doll slots {" .. table.concat(ids, ",") .. "}")
    check("doll slots for the cap and the hammer", zoneOf("doll:head") and zoneOf("doll:main"))
    pressAt("doll:head")
    up()
    check("doll click selects the slot", cw()._equipSelected == "doll:head", cw()._equipSelected)
    cw()._equipSelected = nil
end)
step(20, function()
    startDrag("doll:head")
    check("doll slot drags", d():isActive() and ET.draggedItem(cw()) == cap)
end)
step(4, function() shot(3) end)
step(2, function()
    mbDown = false; drawer():onRightMouseDown(0, 0)
    check("doll drag cancelled", not d():isActive())
    Doll.setView("list")
end)
step(40, function() end)

-- E. the cap onto a bag: vanilla's transfer takes it off and in
step(5, function()
    stubDest = bag:getInventory()
    startDrag("HAT")
    releaseFar()
    check("cap release queued vanilla's transfer", queueN() > 0 and not d():isActive(), "queue " .. queueN())
end)
untilTrue("cap in the bag and off the head", function() return cap:getContainer() == bag:getInventory() and not p:isEquipped(cap) end, 600, function(ok)
    check("cap in the bag and off the head", ok)
end)

-- F. the hammer (the primary hand) onto the bag
step(10, function()
    startDrag("PRI")
    releaseFar()
    check("hammer release queued", queueN() > 0 or hammer:getContainer() == bag:getInventory(), "queue " .. queueN())
end)
untilTrue("hammer in the bag and out of the hand", function() return hammer:getContainer() == bag:getInventory() and p:getPrimaryHandItem() ~= hammer end, 600, function(ok)
    check("hammer in the bag and out of the hand", ok)
end)

-- G. the jacket onto its own container: the same place, nothing
step(10, function()
    stubDest = inv
    startDrag("OUT")
    releaseFar()
    check("jacket onto its own container does nothing", queueN() == 0 and p:isEquipped(jacket) and jacket:getContainer() == inv, "queue " .. queueN())
end)

-- H. the jacket to the floor: vanilla's drop
step(10, function()
    stubDest = ISInventoryPage.GetFloorContainer(pn)
    startDrag("OUT")
    releaseFar()
    check("floor release queued vanilla's drop", queueN() > 0, "queue " .. queueN())
end)
untilTrue("jacket on the floor and off the body", function()
    local c = jacket:getContainer()
    return c ~= nil and c:getType() == "floor" and not p:isEquipped(jacket) and jacket:getWorldItem() ~= nil
end, 900, function(ok)
    check("jacket on the floor and off the body", ok)
    shot(4)
    stubDest = nil
    if ok then ZeD_WorldWindow.transferFromFloor(p, jacket, inv) end
end)
untilTrue("jacket picked back up", function() return jacket:getContainer() == inv end, 900, function(ok)
    check("jacket picked back up", ok)
end)

-- Cleanup: runs on every way out (the last step, a step that threw, a timeout), each
-- part on its own so one failure leaves the rest done; safe to run twice.
local cleaned = false
local function cleanup()
    if cleaned then return end
    cleaned = true
    pcall(restore)
    pcall(function() ISTimedActionQueue.clear(p) end)
    pcall(function() stubDest = nil; mbDown = false; ET.dragCancel(cw(), drawer()) end)
    pcall(function() ISMouseDrag.dragging = nil end)
    local function drop(it)
        if not it then return end
        pcall(function() p:removeWornItem(it) end)
        pcall(function() if p:getPrimaryHandItem() == it then p:setPrimaryHandItem(nil) end end)
        pcall(function() if p:getSecondaryHandItem() == it then p:setSecondaryHandItem(nil) end end)
        pcall(function()   -- (an item left lying on the floor is a world object: off the square too)
            local wi = it:getWorldItem()
            if wi then
                local sq = wi:getSquare()
                if sq then sq:transmitRemoveItemFromSquare(wi) end
                wi:removeFromWorld()
            end
        end)
        pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
    end
    drop(jacket); drop(cap); drop(hammer); drop(bag)
    pcall(function() triggerEvent("OnClothingUpdated", p) end)
    pcall(function() Doll.setView(origView) end)
    pcall(function() if cw() then cw()._equipListExpanded = origListExp; cw()._equipSelected = nil end end)
end
step(10, function()
    cleanup()
    say("DONE")
end)

local done = false
local waited = 0
local function onTick()
    qt = qt + 1
    local s = q[qi]
    if s then
        local ok, e = pcall(function()
            if s.cond then
                waited = waited + 1
                if s.cond() then waited = 0; qi = qi + 1; s.fn(true)
                elseif waited > s.max then waited = 0; qi = qi + 1; s.fn(false) end
            else
                waited = waited + 1
                if waited >= s.wait then waited = 0; qi = qi + 1; s.fn() end
            end
        end)
        if not ok then say("ERR " .. qi .. " " .. tostring(e)) end
    end
    if (qi > #q or qt > 4500) and not done then
        done = true
        if qi <= #q then say("ERR timed out at step " .. qi) end
        cleanup()   -- (every way out: not only the last step)
        Events.OnTick.Remove(onTick)
    end
end
Events.OnTick.Add(onTick)
say("start")
