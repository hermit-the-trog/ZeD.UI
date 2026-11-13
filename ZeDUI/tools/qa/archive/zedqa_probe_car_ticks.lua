-- ZeDUI/tools/qa/zedqa_probe_car_ticks.lua  (Nov 1 2026, QA; the 720 vehicle cluster, Build's tick-vs-time reading)
-- One car (Base.CarNormal) spawned beside the character; at ticks 0, 30, 60, 90, 120, 180, 300 a print of the wall
-- time since tick 0 (getTimestampMs) next to the car's state (square, chunk, distance, physics awake), the same
-- reading zedqa_dash_green.lua makes before it seats the character. Run at 1280x720, 1280x800 and 4K: if 90 ticks is
-- a fraction of a second at 720 and several seconds at 4K, the scripts' tick waits are the cause. The car is removed
-- after. A print, not a pass / fail. grep "ZEDQA pct".
local p = getPlayer()
local function say(s) print("ZEDQA pct " .. tostring(s)) end
local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
local OFFS = { { 5, 2 }, { 5, -3 }, { -5, 2 }, { 2, 5 }, { -4, -4 }, { 6, 6 }, { -6, 0 } }
local car = nil
for _, o in ipairs(OFFS) do
    if car then break end
    local sq = getCell():getGridSquare(math.floor(p:getX()) + o[1], math.floor(p:getY()) + o[2], math.floor(p:getZ()))
    local free = false
    if sq then pcall(function() free = sq:isFree(false) and not sq:HasTree() and not sq:getVehicleContainer() end) end
    if sq and free then pcall(function() car = addVehicleDebug("Base.CarNormal", IsoDirections.N, nil, sq) end) end
end
if not car then say("ERR no free square for the car"); say("DONE"); return end
local function state()
    local sq, chunk, dist, phys = nil, nil, -1, nil
    pcall(function() sq = car:getSquare() end)
    local okC = pcall(function() chunk = car:getChunk() end)
    if not okC and sq then pcall(function() chunk = sq:getChunk() end) end
    pcall(function() dist = car:DistTo(p) end)
    pcall(function() phys = car:isPhysicsActive() end)
    return string.format("square %s, chunk %s, %.1f away, physics %s", tostring(sq ~= nil), tostring(chunk ~= nil), dist, tostring(phys))
end
local t0, n, firstPhys = getTimestampMs(), 0, nil
say(string.format("screen %dx%d | car spawned | tick 0 at 0 ms | %s", sw, sh, state()))
local MARKS = { [30] = true, [60] = true, [90] = true, [120] = true, [180] = true, [300] = true }
local function tick()
    n = n + 1
    local ms = getTimestampMs() - t0
    if not firstPhys then
        local phys = nil
        pcall(function() phys = car:isPhysicsActive() end)
        if phys then firstPhys = n; say(string.format("physics first awake at tick %d, %d ms", n, ms)) end
    end
    if MARKS[n] then say(string.format("tick %d at %d ms (%.1f ms a tick) | %s", n, ms, ms / n, state())) end
    if n >= 300 then
        Events.OnTick.Remove(tick)
        say(string.format("summary: screen %dx%d | 90 ticks = %s ms | physics first awake at tick %s", sw, sh, "see above", tostring(firstPhys)))
        pcall(function() car:permanentlyRemove() end)
        say("car removed | DONE")
    end
end
Events.OnTick.Add(tick)
