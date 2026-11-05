-- ZeDUI/tools/qa/zedqa_loot_click.lua  (Nov 5 2026, QA; FAIV's bug report, fix 7e1a49c2): a left click on a world
-- container goes through the game's own handler (ISObjectClickHandler.onObjectLeftMouseButtonDown, as the engine calls
-- it); ZeD's watcher must show it in the World window and never the game's loot page. grep "ZEDQA lck".
--   a  both windows closed, next to a container: the World window opens on it, the game's page hidden
--   b  the World window open on another container: it switches to the clicked one
--   c  the World window rolled up (unpinned): it rolls down on the container, then rolls up again with the pointer away
--   e  aiming: nothing opens
--   t  a vehicle trunk opened the game's way: the World window shows the trunk
-- Also: (h) the game's pages were hidden and the World window shut at world start (read from the log before the test).
-- Each check prints PASS or FAIL. The pins and windows are put back as the QA save keeps them.
local function say(s) print("ZEDQA lck " .. tostring(s)) end
if ZEDQA_HOME then ZEDQA_HOME("lck") end
local p = getPlayer()
local md = p:getModData()
local keepPins = md.ZeD_WinPinned and { char = md.ZeD_WinPinned.char, world = md.ZeD_WinPinned.world } or nil
local function WW() return ZeD_WorldWindow.getWindow() end
local function vlVisible() local vl = getPlayerLoot(0); return vl ~= nil and vl:getIsVisible() end
local function selInv() local w = WW(); local c = w and w._containers and w._containers[w._activeContainer or 0]; return c and c.inventory end
local function check(tag, ok, detail) say((ok and "PASS " or "FAIL ") .. tag .. (detail and (": " .. detail) or "")) end
local function invName(inv) if not inv then return "nil" end; local o = inv:getParent(); return tostring(inv:getType()) .. (o and (" at " .. o:getX() .. "," .. o:getY()) or "") end

-- containers nearby: world objects with a container, on the character's floor, two of them if we can
local cands = {}
do
    local cell = getCell()
    local px, py, pz = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    for r = 1, 40 do
        for dx = -r, r do for dy = -r, r do
            if math.abs(dx) == r or math.abs(dy) == r then
                local sq = cell:getGridSquare(px + dx, py + dy, pz)
                if sq then
                    local objs = sq:getObjects()
                    for i = 0, objs:size() - 1 do
                        local o = objs:get(i)
                        if o:getContainer() and not instanceof(o, "IsoDeadBody") and #cands < 2 then
                            local adj = AdjacentFreeTileFinder.Find(sq, p)
                            if adj then cands[#cands + 1] = { obj = o, adj = adj } end
                        end
                    end
                end
            end
        end end
        if #cands >= 2 then break end
    end
end
say("containers found " .. #cands .. ": " .. (cands[1] and invName(cands[1].obj:getContainer()) or "-") .. " / " .. (cands[2] and invName(cands[2].obj:getContainer()) or "-"))
if #cands == 0 then say("ERR no container near the character"); say("DONE"); return end

local function standBy(c) local s = c.adj; p:setX(s:getX() + 0.5); p:setY(s:getY() + 0.5); p:setLastX(s:getX() + 0.5); p:setLastY(s:getY() + 0.5) end
local function click(c) ISObjectClickHandler.onObjectLeftMouseButtonDown(c.obj, 0, 0); ISObjectClickHandler.onObjectLeftMouseButtonUp(c.obj, 0, 0) end
local function closeAll()
    if ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggle(0) end
    if ZeD_WorldWindow.isOpen() then ZeD_WorldWindow.close() end
end

local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
-- a
add(300, function() closeAll(); standBy(cands[1]) end)
add(1500, function() check("a setup", not ZeD_WorldWindow.isOpen() and not vlVisible(), "World open " .. tostring(ZeD_WorldWindow.isOpen())); click(cands[1]) end)
add(1500, function()
    local want = cands[1].obj:getContainer()
    check("a closed -> click", ZeD_WorldWindow.isOpen() and not vlVisible() and selInv() == want,
        "World open " .. tostring(ZeD_WorldWindow.isOpen()) .. ", game page " .. tostring(vlVisible()) .. ", shows " .. invName(selInv()))
end)
-- b
add(300, function()
    if not cands[2] then say("b skipped: one container only"); return end
    standBy(cands[2])
end)
add(2500, function() if cands[2] then say("b before the click: World shows " .. invName(selInv())); click(cands[2]) end end)
add(1500, function()
    if not cands[2] then return end
    local want = cands[2].obj:getContainer()
    check("b open on another -> click", selInv() == want and not vlVisible(), "shows " .. invName(selInv()) .. ", wanted " .. invName(want))
end)
-- c
add(300, function()
    local w = WW()
    if w.setPinned then w:setPinned(false) end
    md.ZeD_WinPinned = md.ZeD_WinPinned or {}; md.ZeD_WinPinned.world = false
    w._autoShaded = true; w:setWindowShaded(true)
    standBy(cands[1])
end)
add(800, function() check("c setup rolled", WW().windowShaded == true); click(cands[1]) end)
add(800, function()
    local w = WW()
    check("c rolled -> click", w.windowShaded ~= true and selInv() == cands[1].obj:getContainer() and not vlVisible(),
        "rolled " .. tostring(w.windowShaded) .. ", shows " .. invName(selInv()) .. ", game page " .. tostring(vlVisible()))
end)
add(4500, function()
    -- the pointer is wherever the runner left it (not over the window: the screen centre is the world)
    check("c rolls up again", WW().windowShaded == true, "rolled after 4.5 s: " .. tostring(WW().windowShaded) .. " (mouse " .. getMouseX() .. "," .. getMouseY() .. ")")
end)
-- e
add(300, function() closeAll(); standBy(cands[1]) end)
add(1500, function() p:setIsAiming(true); say("e before the click: World open " .. tostring(ZeD_WorldWindow.isOpen()) .. ", aiming " .. tostring(p:isAiming())); click(cands[1]); say("e right after: game page " .. tostring(vlVisible())) end)
add(1200, function()
    check("e aiming -> nothing", not ZeD_WorldWindow.isOpen() and not vlVisible(), "World open " .. tostring(ZeD_WorldWindow.isOpen()) .. ", game page " .. tostring(vlVisible()))
    p:setIsAiming(false)
end)
-- t: the nearest car's trunk opened the game's way
add(300, function()
    local best, bd
    local it = getCell():getVehicles():iterator()
    while it:hasNext() do local v = it:next(); local d = (v:getX() - p:getX()) ^ 2 + (v:getY() - p:getY()) ^ 2; if not bd or d < bd then best, bd = v, d end end
    closeAll()
    T_CAR = best
    if not best then say("t skipped: no car"); return end
    local part = best:getPartById("TruckBed") or best:getPartById("TrunkDoor")
    T_PART = best:getPartById("TruckBed")
    local door = best:getPartById("TrunkDoor") or best:getPartById("DoorRear")
    say("car " .. tostring(best:getScriptName()) .. ", trunk " .. tostring(T_PART ~= nil) .. ", door " .. tostring(door and door:getId()))
    if door and door:getDoor() then
        ISVehicleMenu.onOpenDoor(p, door)
    elseif T_PART then
        ISTimedActionQueue.add(ISOpenVehicleDoor:new(p, best, T_PART))
    end
end)
add(6000, function() if T_CAR then say("t: queue busy " .. tostring(ISTimedActionQueue.isPlayerDoingAction(p)) .. ", game page " .. tostring(vlVisible())) end end)
add(9000, function()
    if not T_CAR then return end
    local want = T_PART and T_PART:getItemContainer()
    check("t trunk opened", ZeD_WorldWindow.isOpen() and not vlVisible() and (not want or selInv() == want),
        "World open " .. tostring(ZeD_WorldWindow.isOpen()) .. ", shows " .. invName(selInv()) .. ", game page " .. tostring(vlVisible()))
end)
add(500, function()
    md.ZeD_WinPinned = keepPins or { char = true, world = true }
    if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end
    local w = WW(); if w and w.setPinned then w:setPinned(md.ZeD_WinPinned.world == true) end
    if w and w.windowShaded then w:setWindowShaded(false) end
    if ZEDQA_HOME then ZEDQA_HOME("lck") end
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
say("start")
