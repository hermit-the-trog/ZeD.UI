-- ZeDUI/tools/qa/zedqa_toilet.lua  (Nov 17 2026, QA): the director's report: invisible and in god mode, outside a
-- building with every door locked, pointed at a toilet inside, the A "Rest" put the character through the wall onto it.
-- Is it the game's or ZeD's? Runs with ZeD on (its bridge) and with ZeD off (ZeDQAShim's bridge): no ZeD call here.
-- Finds the nearest toilet inside a room within 80 tiles, locks that building's doors (put back after), stands the
-- character outside on the nearest outdoor square, invisible and in god mode, and runs the game's own A action for a
-- seat (ContextualActionHandlers.SleepInBed, which is ISWorldObjectContextMenu.onRest, the "Rest" the A prompt runs).
-- Prints where the character ends: sitting on it, inside the room, which doors opened. grep "ZEDQA toil".
-- Pictures: Screenshots/zqa_toil_<zed|vanilla>_*.png. Puts back: doors, position, invisible / god mode, standing up.
local p = getPlayer()
local pn = p:getPlayerNum()
local tag = (ZeD and ZeD.Input) and "zed" or "vanilla"
local function say(s) print("ZEDQA toil " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_toil_" .. tag .. "_" .. n .. ".png") end) end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local S = { doors = {} }

local function isToilet(o)
    local ok, r = pcall(function()
        local sp = o:getSprite(); local nm = sp and sp:getName() or ""
        local pr = o:getProperties(); local cn = pr and pr:get("CustomName") or ""
        return (tostring(cn):lower():find("toilet") ~= nil) or (tostring(nm):lower():find("toilet") ~= nil)
    end)
    return ok and r
end

step(10, function()
    say("start, ZeD " .. tag .. ", at " .. math.floor(p:getX()) .. "," .. math.floor(p:getY()))
    S.home = { x = p:getX(), y = p:getY(), z = p:getZ() }
    S.inv, S.god = p:isInvisible(), p:isGodMod()
    local cell = getCell()
    local px, py = math.floor(p:getX()), math.floor(p:getY())
    local best, bd
    for r = 0, 80 do
        for dx = -r, r do for dy = -r, r do
            if math.max(math.abs(dx), math.abs(dy)) == r then
                local sq = cell:getGridSquare(px + dx, py + dy, 0)
                if sq and sq:getRoom() then
                    local objs = sq:getObjects()
                    for i = 0, objs:size() - 1 do
                        local o = objs:get(i)
                        if isToilet(o) then best, bd = o, r; break end
                    end
                end
            end
            if best then break end
        end if best then break end end
        if best then break end
    end
    S.toilet = best
    if not best then say("not run: no toilet inside a room within 80 tiles"); return end
    local tsq = best:getSquare()
    S.room = tsq:getRoom()
    say("toilet " .. tostring(best:getSprite() and best:getSprite():getName()) .. " at " .. tsq:getX() .. "," .. tsq:getY() .. ", room " .. tostring(S.room and S.room:getName()))
    -- lock every door of the building within 20 tiles of the toilet
    local b = tsq:getBuilding()
    for dx = -20, 20 do for dy = -20, 20 do
        local sq = cell:getGridSquare(tsq:getX() + dx, tsq:getY() + dy, 0)
        if sq then
            local sp = sq:getSpecialObjects()
            for i = 0, sp:size() - 1 do
                local o = sp:get(i)
                if instanceof(o, "IsoDoor") or (instanceof(o, "IsoThumpable") and o:isDoor()) then
                    S.doors[#S.doors + 1] = { o = o, open = o:IsOpen(), locked = o:isLocked(), key = o:isLockedByKey() }
                    pcall(function() if o:IsOpen() then o:ToggleDoorSilent() end end)
                    pcall(function() o:setLocked(true) end)
                    pcall(function() o:setLockedByKey(true) end)
                end
            end
        end
    end end
    say("doors locked: " .. #S.doors)
    -- the nearest outdoor square to the toilet
    local out, od
    for dx = -12, 12 do for dy = -12, 12 do
        local sq = cell:getGridSquare(tsq:getX() + dx, tsq:getY() + dy, 0)
        if sq and not sq:getRoom() and sq:isFree(false) then
            local d = dx * dx + dy * dy
            if not od or d < od then out, od = sq, d end
        end
    end end
    if not out then say("not run: no outdoor square near it"); S.toilet = nil; return end
    p:setX(out:getX() + 0.5); p:setY(out:getY() + 0.5); p:setZ(0); p:setLastX(out:getX() + 0.5); p:setLastY(out:getY() + 0.5)
    p:setInvisible(true); p:setGodMod(true)
    say("stood outside at " .. out:getX() .. "," .. out:getY() .. " (" .. string.format("%.1f", math.sqrt(od)) .. " tiles from the toilet), invisible, god mode")
end)
step(30, function()
    if not S.toilet then return end
    shot("1_outside")
    -- the A action for a seat, as the game runs it
    local ok, err = pcall(function() ContextualActionHandlers.SleepInBed("SleepInBed", p, S.toilet) end)
    say("A Rest sent: ok " .. tostring(ok) .. " " .. tostring(err or ""))
end)
for i = 1, 6 do
    step(100, function()
        if not S.toilet then return end
        local sq = p:getCurrentSquare()
        local q = ISTimedActionQueue.getTimedActionQueue(p)
        local names = {}
        pcall(function() for _, a in ipairs(q.queue) do names[#names + 1] = tostring(a.Type) end end)
        say(string.format("t%d: at %d,%d in room %s, sitting %s, queue %s", i, sq and sq:getX() or -1, sq and sq:getY() or -1,
            tostring(sq and sq:getRoom() and sq:getRoom():getName()), tostring(p:isSittingOnFurniture()), table.concat(names, ">")))
    end)
end
step(10, function()
    if not S.toilet then return end
    shot("2_after")
    local sq = p:getCurrentSquare()
    local inside = sq and sq:getRoom() ~= nil
    local opened = 0
    for _, d in ipairs(S.doors) do if d.o:IsOpen() then opened = opened + 1 end end
    local seat = p:isSittingOnFurniture() and p:getSitOnFurnitureObject() == S.toilet
    say("RESULT ZeD " .. tag .. ": sitting on the toilet " .. tostring(seat) .. ", inside " .. tostring(inside) .. ", doors opened " .. opened .. " of " .. #S.doors)
end)
step(10, function()
    pcall(function() ISTimedActionQueue.clear(p) end)
    pcall(function() p:setSitOnFurnitureObject(nil); p:setSittingOnFurniture(false) end)
    pcall(function() p:setVariable("SitOnFurniture", false) end)
    for _, d in ipairs(S.doors) do
        pcall(function() d.o:setLockedByKey(d.key) end)
        pcall(function() d.o:setLocked(d.locked) end)
        pcall(function() if d.o:IsOpen() ~= d.open then d.o:ToggleDoorSilent() end end)
    end
    if S.home then p:setX(S.home.x); p:setY(S.home.y); p:setZ(S.home.z); p:setLastX(S.home.x); p:setLastY(S.home.y) end
    p:setInvisible(S.inv and true or false); p:setGodMod(S.god and true or false)
    say("put back")
    say("DONE")
end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnPreUIDraw.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnPreUIDraw.Add(tick)
say("start")
