-- ZeDUI/tools/qa/mp_b7_dash_stage.lua  (Nov 7 2026, QA; merge 2, the dash with two players): on the admin client. To the drag
-- strip (925,13040), bob brought alongside, a car made by the server facing north (the shim's carspawn; /addvehicle as a
-- fallback), made ready there (carprep: repaired, fuel, battery, hotwired, and "another mod's" key written into the
-- server's copy of its mod data only), the admin into the driver's seat the game's way (ISVehicleMenu.onEnter) and the
-- engine started the game's way (ISStartVehicleEngine). The car's id goes to Lua/zedqa_dash_car.txt. grep "ZEDQA dsg".
local function say(s) print("ZEDQA dsg " .. tostring(s)) end
local p = getPlayer()
local D = ZeD.Dashboard
local SITE = { x = 925, y = 13040 }
local ans = {}
local function onCmd(m, c, a) if m == "ZeDQA" then ans[c] = a or {} end end
Events.OnServerCommand.Add(onCmd)
local function now() return getTimestampMs() end
local function st() local d = D.getInstance(); return d and d._st end
local car = nil
local function findCar(maxd)
    local best, bd = nil, maxd or 15
    local it = getCell():getVehicles():iterator()
    while it:hasNext() do
        local v = it:next()
        local d = math.sqrt((v:getX() - p:getX()) ^ 2 + (v:getY() - p:getY()) ^ 2)
        if d < bd then best, bd = v, d end
    end
    return best, bd
end
local plan, i, t0 = {}, 1, now()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function addUntil(ms, cond, fn) plan[#plan + 1] = { ms = ms, cond = cond, fn = fn } end
add(500, function()
    say("from " .. math.floor(p:getX()) .. "," .. math.floor(p:getY()))
    SendCommandToServer("/teleportto " .. SITE.x .. "," .. SITE.y .. ",0")
end)
addUntil(30000, function() return math.abs(p:getX() - SITE.x) < 3 and getCell():getGridSquare(SITE.x + 6, SITE.y, 0) ~= nil end, function()
    say("at " .. math.floor(p:getX()) .. "," .. math.floor(p:getY()))
    SendCommandToServer('/teleport "bob" "' .. p:getUsername() .. '"')
    -- (zombies are off on this server; the car goes six squares east, facing up the strip)
    sendClientCommand(p, "ZeDQA", "carspawn", { x = SITE.x + 5, y = SITE.y, z = 0, script = "Base.CarNormal" })
end)
addUntil(8000, function() return ans.carspawn ~= nil end, function()
    local a = ans.carspawn or {}
    say("carspawn: " .. tostring(a.ok) .. " id " .. tostring(a.veh))
    if not a.ok then SendCommandToServer('/addvehicle "Base.CarNormal"'); say("fell back to /addvehicle") end
end)
addUntil(10000, function() car = findCar(15); return car ~= nil end, function()
    if not car then say("ERR no car by me"); return end
    local fx, fy = 0, 0
    pcall(function() local f = Vector3f.new(); car:getForwardVector(f); fx, fy = f:x(), f:y() end)
    say(string.format("car %d at %.1f,%.1f, forward %.2f,%.2f", car:getId(), car:getX(), car:getY(), fx, fy))
    sendClientCommand(p, "ZeDQA", "carprep", { veh = car:getId() })
    local w = getFileWriter("zedqa_dash_car.txt", true, false); if w then w:write(tostring(car:getId())); w:close() end
end)
addUntil(8000, function() return ans.carprep ~= nil end, function()
    local a = ans.carprep or {}
    say("carprep: " .. tostring(a.ok) .. ", hotwired " .. tostring(a.hot))
end)
add(2500, function() if car then ISVehicleMenu.onEnter(p, car, 0) end end)
addUntil(20000, function() return car and p:getVehicle() == car end, function()
    say("in the driver's seat: " .. tostring(car and p:getVehicle() == car and car:isDriver(p)))
end)
add(1500, function() ISTimedActionQueue.add(ISStartVehicleEngine:new(p)) end)
addUntil(6000, function() return car and car:isEngineRunning() end, function()
    if not car:isEngineRunning() then ISTimedActionQueue.add(ISStartVehicleEngine:new(p)) end
end)
addUntil(12000, function() return car and car:isEngineRunning() end, function()
    local s = st()
    say("engine running " .. tostring(car and car:isEngineRunning()) .. "; dash shown " .. tostring(D.getInstance() and D.getInstance():isVisible()) ..
        "; odo " .. tostring(s and s.odo) .. " trip " .. tostring(s and s.trip))
    local b = getPlayerFromUsername("bob")
    say("bob " .. (b and string.format("at %.1f squares from the car", math.sqrt((b:getX() - car:getX()) ^ 2 + (b:getY() - car:getY()) ^ 2)) or "not seen"))
end)
add(500, function() Events.OnServerCommand.Remove(onCmd) end)
local function drive()
    local stp = plan[i]
    if not stp then Events.OnTick.Remove(drive); return end
    local gone = now() - t0
    if stp.cond then
        local ok, c = pcall(stp.cond)
        if not (ok and c) and gone < stp.ms then return end
    elseif gone < stp.ms then return end
    t0 = now(); i = i + 1
    local ok, e = pcall(stp.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
    if i > #plan then say("DONE") end
end
Events.OnTick.Add(drive)
