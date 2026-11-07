-- ZeDUI/tools/qa/mp_b7_dash_drive.lua  (Nov 7 2026, QA; merge 2, the dash with two players): on the admin client, at the wheel of
-- the car mp_b7_dash_stage.lua made. The drive of zedqa_dash_odo.lua (pushed by impulses, no keys pressed) for 22 s, then
-- braked to a stop: up the strip with bob outside, back down it (in reverse) once bob rides along. The car's own path is
-- summed square by square against what the admin's odometer counted; the server's figures are read (the shim's carread)
-- before and after. With a passenger: the server's figures read once stopped, then the engine off (ISShutOffVehicleEngine,
-- a coarse send) and read again, with "another mod's" key. grep "ZEDQA ddr".
local function say(s) print("ZEDQA ddr " .. tostring(s)) end
local pass, fail = 0, 0
local function check(ok, what, d)
    if ok then pass = pass + 1 else fail = fail + 1 end
    say((ok and "PASS " or "FAIL ") .. what .. (d ~= nil and (" (" .. tostring(d) .. ")") or ""))
end
local p = getPlayer()
local D = ZeD.Dashboard
local ans = {}
local function onCmd(m, c, a) if m == "ZeDQA" then ans[c] = a or {} end end
Events.OnServerCommand.Add(onCmd)
local function now() return getTimestampMs() end
local function st() local d = D.getInstance(); return d and d._st end
local car = p:getVehicle()
local rider = nil
if car then
    for s = 1, car:getMaxPassengers() - 1 do
        local c = car:getCharacter(s)
        if c and instanceof(c, "IsoPlayer") then rider = c end
    end
end
local SIGN = rider and -1 or 1
local function read(tag) ans.carread = nil; sendClientCommand(p, "ZeDQA", "carread", { veh = car:getId() }); return tag end
local fwd, zero = Vector3f.new(), Vector3f.new(0, 0, 0)
local Dr = { F = 50, at = 0, dist = 0, lx = nil, ly = nil, max = 0, log = 0 }
local R = {}
local plan, i, t0 = {}, 1, now()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function during(ms, fn) plan[#plan + 1] = { ms = ms, every = fn } end
add(300, function()
    if not car then say("ERR not in a car"); return end
    say("driver " .. tostring(car:isDriver(p)) .. ", engine " .. tostring(car:isEngineRunning()) .. ", rider " .. tostring(rider and rider:getUsername()) .. (SIGN < 0 and ", in reverse" or ", forward"))
    read()
end)
add(2500, function()
    local s, a = st(), ans.carread or {}
    R.odo0, R.trip0, R.srv0 = s and s.odo, s and s.trip, a.odo
    say(string.format("before: the dash odo %s trip %s; the server odo %s trip %s other %s", tostring(R.odo0), tostring(R.trip0), tostring(a.odo), tostring(a.trip), tostring(a.other)))
end)
local function push(brake)
    return function(ms)
        local s = st(); if not s or not car then return end
        pcall(function() car:setPhysicsActive(true) end)
        local ok = pcall(function() car:getForwardVector(fwd) end)
        if ok then
            local fx, fy, fz = fwd:x() * SIGN, fwd:y() * SIGN, fwd:z() * SIGN
            if brake then
                if (s.speed or 0) > 1 then pcall(function() car:addImpulse(Vector3f.new(-fx * Dr.F, -fy * Dr.F, -fz * Dr.F), zero) end) end
            elseif (s.speed or 0) < 30 then
                pcall(function() car:addImpulse(Vector3f.new(fx * Dr.F, fy * Dr.F, fz * Dr.F), zero) end)
            end
        end
        if not brake and ms - Dr.at >= 1000 then Dr.at = ms; if (s.speed or 0) < 5 then Dr.F = math.min(Dr.F * 2, 50000) end end
        local x, y = car:getX(), car:getY()
        if Dr.lx then Dr.dist = Dr.dist + math.sqrt((x - Dr.lx) ^ 2 + (y - Dr.ly) ^ 2) end
        Dr.lx, Dr.ly = x, y
        if (s.speed or 0) > Dr.max then Dr.max = s.speed end
        if ms - Dr.log >= 3000 then Dr.log = ms; say(string.format("t=%d kmh=%.1f path=%.1f odo=%.3f trip=%.3f", math.floor(ms / 1000), s.speed or -1, Dr.dist, s.odo or -1, s.trip or -1)) end
    end
end
during(22000, push(false))
during(7000, push(true))
add(3000, function()
    local s = st()
    local x, y = car:getX(), car:getY()
    if Dr.lx then Dr.dist = Dr.dist + math.sqrt((x - Dr.lx) ^ 2 + (y - Dr.ly) ^ 2) end
    local miles = Dr.dist / 1609.344
    local dOdo = (s.odo or 0) - (R.odo0 or 0)
    say(string.format("stopped at %.1f,%.1f: path %.1f squares = %.4f mi; the dash odo +%.4f, trip %.4f; top %.1f km/h", x, y, Dr.dist, miles, dOdo, s.trip or -1, Dr.max))
    check(miles > 0.02 and math.abs(dOdo - miles) <= math.max(0.01, miles * 0.12), "the driver's odometer counts the distance", string.format("%.0f%%", miles > 0 and dOdo / miles * 100 or 0))
    R.odo1, R.trip1 = s.odo, s.trip
    read()
end)
add(3000, function()
    local a = ans.carread or {}
    say(string.format("the server once stopped: odo %s trip %s show %s other %s driver %s", tostring(a.odo), tostring(a.odo and a.trip), tostring(a.show), tostring(a.other), tostring(a.driver)))
    check(a.odo ~= nil and math.abs(a.odo - R.odo1) <= 0.002, "the server took the driver's figures (the send as the car stops)", string.format("%s against %s", tostring(a.odo), tostring(R.odo1)))
    check(a.other == "kept on the server", "another mod's key in the server's copy is still there", a.other)
    if rider then ISTimedActionQueue.add(ISShutOffVehicleEngine:new(p)) end
end)
add(4000, function()
    if not rider then return end
    say("engine " .. tostring(car:isEngineRunning()))
    read()
end)
add(3000, function()
    if not rider then return end
    local a = ans.carread or {}
    say(string.format("the server after the engine off: odo %s trip %s other %s running %s", tostring(a.odo), tostring(a.trip), tostring(a.other), tostring(a.running)))
    check(a.running == false, "the engine is off")
    check(a.other == "kept on the server", "another mod's key survived both drives and the coarse send", a.other)
end)
add(300, function() Events.OnServerCommand.Remove(onCmd); say(pass .. " passed, " .. fail .. " failed") end)
local function drive()
    local stp = plan[i]
    if not stp then Events.OnTick.Remove(drive); return end
    local gone = now() - t0
    if stp.every then
        local ok, e = pcall(stp.every, gone)
        if not ok then say("ERR drive: " .. tostring(e)) end
    end
    if gone < stp.ms then return end
    t0 = now(); i = i + 1
    if stp.fn then
        local ok, e = pcall(stp.fn)
        if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
    end
    if i > #plan then say("DONE") end
end
Events.OnTick.Add(drive)
