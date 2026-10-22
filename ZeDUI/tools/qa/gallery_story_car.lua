-- ZeDUI/tools/qa/gallery_story_car.lua  (Oct 21 2026)
-- Story gallery retake helper: after gallery_story_stage.lua (STORY up). The car moved to a
-- pump: the old one removed, placements beside every pump tried (the stage's relaxed search,
-- copied here so a stage that is already up gets it) until vanilla's pump finder sees a pump
-- from the gas tank and the tank's square is free; the tank at 6 %, a key carried.
-- "ZEDQA stc ..." ending "ZEDQA stc DONE".
local ST = STORY
if not (ST and ST.ready and ST.newSeq) then print("ZEDQA stc ERR run gallery_story_stage.lua first"); print("ZEDQA stc DONE"); return end
local S = ST.newSeq("stc", 300000)
local say = S.say
local p = ST.p
local C = { ci = 0 }
function ST.carCandidates()
    -- every pump, the nearest to the store first; the car beside it lengthwise, its body's line
    -- (5 squares) and the squares either side of its middle clear (the pump islands' kerbs and
    -- the canopy posts leave no 7 x 3 box free)
    local P = ST.P
    local out, pumps = {}, {}
    for _, e in ipairs(ST.F.pumps) do pumps[#pumps + 1] = e end
    local c = P.centre
    table.sort(pumps, function(u, v) return math.abs(u.x - c[1]) + math.abs(u.y - c[2]) < math.abs(v.x - c[1]) + math.abs(v.y - c[2]) end)
    local seen = {}
    for _, e in ipairs(pumps) do
        for _, o in ipairs({ { 0, 2, "E" }, { 0, -2, "E" }, { 0, 2, "W" }, { 0, -2, "W" }, { 2, 0, "N" }, { -2, 0, "N" }, { 2, 0, "S" }, { -2, 0, "S" },
                             { 1, 2, "E" }, { -1, 2, "W" }, { 2, 1, "N" }, { 2, -1, "S" }, { 0, 3, "E" }, { 3, 0, "N" }, { 0, -3, "W" }, { -3, 0, "S" } }) do
            local x, y, d = e.x + o[1], e.y + o[2], o[3]
            local k = x .. "," .. y .. d
            local clear = not seen[k]
            seen[k] = true
            local cells = { { -2, 0 }, { -1, 0 }, { 0, 0 }, { 1, 0 }, { 2, 0 }, { 0, -1 }, { 0, 1 } }
            for _, q in ipairs(cells) do
                local qx, qy = x + q[1], y + q[2]
                if d == "N" or d == "S" then qx, qy = x + q[2], y + q[1] end
                local sq = ST.sqAt(qx, qy)
                if not (sq and ST.free(sq)) then clear = false end
            end
            if clear then out[#out + 1] = { x = x, y = y, dir = d } end
        end
    end
    return out
end
S.step(2, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if p:getVehicle() then pcall(function() p:getVehicle():exit(p) end); pcall(function() triggerEvent("OnExitVehicle", p) end) end
    if ST.car then ST.removeCar(ST.car); ST.car = nil end
    if ST.carKey then pcall(function() ST.inv:Remove(ST.carKey) end); ST.carKey = nil end
    ST.tpSq(ST.P.pump and ST.outNear(ST.P.pump.x, ST.P.pump.y, 4) or ST.P.centre)
    C.cands = ST.carCandidates()
    say("car placements to try: " .. #C.cands)
end)
S.poll(30, 4000, function()
    if C.car then
        C.wait = C.wait - 1
        if C.wait > 0 then return false end
        local v, pump = C.car, nil
        pcall(function() pump = ISVehiclePartMenu.getNearbyFuelPump(v) end)
        local tank = v:getPartById("GasTank")
        local ac = nil
        pcall(function() ac = v:getAreaCenter(tank:getArea()) end)
        local acFree = ac and ST.free(ST.sqAt(math.floor(ac:getX()), math.floor(ac:getY())))
        if pump and acFree then
            ST.car = v
            say(string.format("car %s at %.1f,%.1f facing %s: the pump finder sees %d,%d | tank area %.1f,%.1f", v:getScriptName(),
                v:getX(), v:getY(), C.cand.dir, pump:getSquare():getX(), pump:getSquare():getY(), ac:getX(), ac:getY()))
            return true
        end
        ST.removeCar(v)
        C.car = nil
        return false
    end
    C.ci = C.ci + 1
    C.cand = C.cands and C.cands[C.ci]
    if not C.cand then return true end
    C.car = ST.spawnCar("Base.CarStationWagon", IsoDirections[C.cand.dir], C.cand.x, C.cand.y)
    C.wait = 40
    return false
end)
S.step(5, function()
    local v = ST.car
    if not v then S.err("car", "no placement (" .. tostring(C.ci) .. " tried) let the pump finder reach a pump"); return end
    pcall(function() v:repair() end)
    pcall(function() local g = v:getPartById("GasTank"); g:setContainerContentAmount(g:getContainerCapacity() * 0.06); v:transmitPartModData(g) end)
    pcall(function() ST.carKey = ST.inv:AddItem(v:createVehicleKey()) end)
    say("placements tried " .. C.ci .. " | car fuel " .. tostring(v:getPartById("GasTank"):getContainerContentAmount()))
end)
S.start()
