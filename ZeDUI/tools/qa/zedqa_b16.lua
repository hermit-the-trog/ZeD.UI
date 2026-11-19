-- (Nov 19 2026, QA: OUT OF DATE since beta 21. This script sets the retired per-piece Simple switches, which nothing reads
-- now (one Style switch, ZeD.Settings.lookStyleOption, 1 Full, 2 Lite). Its Simple legs run against Full. Do not reuse as is.)
-- ZeDUI/tools/qa/zedqa_b16.lua  (Nov 15 2026, QA): beta 16's new pieces in the game, with pictures for the director.
-- The face pop-outs (an oven, a microwave, a TV placed beside the character, opened through FacePop.open, the way
-- a click or A at the machine opens them): the frameless face shows, B / the same machine again puts it away.
-- The speed note over the head: paused and at 3x. The seat picker's pop-out on the nearest car within 8 tiles
-- (Dashboard style; a car it can't lay out falls back to the window, printed, not failed).
-- Everything placed is taken away; the speed, the Devices row and the windows are put back.
-- grep "ZEDQA b16"; screenshots Screenshots/zqa_b16_*.png.
local p = getPlayer()
local pn = p:getPlayerNum()
local FP, F, B = ZeD.FacePop, ZeD.TwoWayFull, ZeD.Bubbles
local function say(s) print("ZEDQA b16 " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b16_" .. n .. ".png") end) end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
if not (FP and F) then say("ERR the pop-outs are not loaded"); say("DONE"); return end

-- the Devices row on Immersive for the run (faces pop out only there)
local S = ZeD.Settings
local simpleWas
pcall(function() simpleWas = S.devicesSimple() end)
local function setSimple(v)
    pcall(function()
        S.devicesStyleOption:setValue(v and 2 or 1)   -- (the Devices row: 1 Immersive, 2 Simple)
    end)
end

-- a machine on the square beside the character (zedqa_appliances.lua's way: in the square's list so power counts)
local placed = {}
local function sqBeside(dx, dy)
    return getCell():getGridSquare(math.floor(p:getX()) + dx, math.floor(p:getY()) + dy, math.floor(p:getZ()))
end
local function placeStove(sprite, dx, dy)
    local sq = sqBeside(dx, dy)
    if not sq then return nil end
    local obj = IsoStove.new(getCell(), sq, getSprite(sprite))
    pcall(function() obj:createContainersFromSpriteProperties() end)
    sq:AddSpecialObject(obj)
    if obj:getObjectIndex() < 0 then pcall(function() sq:AddTileObject(obj) end) end
    placed[#placed + 1] = obj
    return obj
end
local function placeTv(sprite, dx, dy)
    local sq = sqBeside(dx, dy)
    if not sq then return nil end
    local obj = IsoTelevision.new(getCell(), sq, getSprite(sprite))
    sq:AddTileObject(obj)
    placed[#placed + 1] = obj
    return obj
end

local stove, micro, tv
step(10, function()
    if simpleWas == true then setSimple(false) end
    check(FP.on(), "faces pop out (Devices on Immersive, safe mode off)")
    stove = placeStove("appliances_cooking_01_12", 2, 0)
    micro = placeStove("appliances_cooking_01_24", -2, 0)
    tv = placeTv("appliances_television_01_1", 0, 2)
    check(stove and micro and tv, "an oven, a microwave and a TV placed beside the character")
end)

-- one machine: open, picture, the same machine again puts it away
local function popOne(tag, getObj)
    step(30, function()
        local o = getObj()
        if not o then say("not run: no " .. tag); return end
        local ok = FP.open(p, o)
        check(ok, tag .. ": its face pops out")
    end)
    step(40, function()
        local v = F.get(pn)
        local o = getObj()
        check(v and v:isReallyVisible() and v.background == false, tag .. ": the pop-out shows, frameless")
        check(o and F.showingObj(pn, o), tag .. ": it shows this machine")
        shot(tag .. "_popout")
    end)
    step(10, function()
        local o = getObj()
        if o then FP.toggle(p, o) end
    end)
    step(10, function()
        local v = F.get(pn)
        check(not (v and v:isReallyVisible()), tag .. ": the same machine again puts it away")
    end)
end
popOne("oven", function() return stove end)
popOne("microwave", function() return micro end)
popOne("tv", function() return tv end)

-- a second machine opening replaces the first
step(10, function() if stove then FP.open(p, stove) end end)
step(20, function() if tv then FP.open(p, tv) end end)
step(20, function()
    check(tv and F.showingObj(pn, tv) and not F.showingObj(pn, stove), "another machine's pop-out replaces the first")
    F.close(pn)
end)

-- the speed note over the head
step(10, function() setGameSpeed(0) end)
step(40, function()
    local n = B and B._speedNote and B._speedNote[pn]
    check(n and n.speed ~= nil, "paused: a speed note over the head (" .. tostring(n and n.speed) .. ")")
    shot("speed_paused")
    setGameSpeed(3)
end)
step(40, function()
    local n = B and B._speedNote and B._speedNote[pn]
    check(n and n.speed ~= nil and n.speed ~= 0, "at 3x: the speed note shows the arrows (" .. tostring(n and n.speed) .. ")")
    shot("speed_3x")
    setGameSpeed(1)
end)
step(40, function()
    local n = B and B._speedNote and B._speedNote[pn]
    say("at normal speed the note reads " .. tostring(n and n.speed) .. " (expect it gone from over the head)")
    shot("speed_normal")
end)

-- the seat picker pop-out on the nearest car
local car
step(10, function()
    -- (the squares within 8 tiles, each asked for the car on it: the cell's vehicle list is not reachable from Lua here)
    local best, bd = nil, 64
    local px, py, pz = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    for dy = -8, 8 do for dx = -8, 8 do
        local sq = getCell():getGridSquare(px + dx, py + dy, pz)
        local v = sq and sq:getVehicleContainer()
        local d = dx * dx + dy * dy
        if v and d < bd then best, bd = v, d end
    end end
    car = best
    if not car then say("not run: the seat pop-out (no car within 8 tiles)"); return end
    local ok, opened = pcall(ZeD.Seats.popToggle, p, car)
    say("seat pop-out on " .. tostring(car:getScript() and car:getScript():getName()) .. " " .. math.floor(math.sqrt(bd)) .. " tiles away: " ..
        (ok and (opened and "opened" or "fell back to the window (the car can't be laid out)") or ("ERR " .. tostring(opened))))
end)
step(30, function()
    local sp = ZeD.Seats and ZeD.Seats.getPopout and ZeD.Seats.getPopout(pn)
    if car and sp and sp:isReallyVisible() then
        check(sp.background == false or sp.background == nil, "the seat pop-out shows the cabin")
        shot("seat_popout")
        sp:close()
    end
end)

-- put back
step(10, function()
    pcall(function() F.close(pn) end)
    for _, o in ipairs(placed) do
        pcall(function() local sq = o:getSquare(); if sq then sq:transmitRemoveItemFromSquare(o); sq:RemoveTileObject(o) end end)
    end
    if simpleWas == true then setSimple(true) end
    if getGameSpeed() ~= 1 then setGameSpeed(1) end
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

-- (stepped on each drawn frame: a paused game stops the tick)
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
