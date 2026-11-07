-- ZeDUI/tools/qa/zedqa_dash_odo_reload.lua  (Nov 7 2026, QA; punch list 92): after zedqa_dash_odo.lua and a quit and
-- relaunch. Finds the Dash Elite it left by the strip (Zomboid/Lua/zedqa_odo_persist.txt: key, odometer, trip, TRIP
-- showing, where), reads the car's ZeD_odo / ZeD_trip / ZeD_odoTrip against what was written before the quit, sits in it
-- with the key in for a picture, then removes the car. grep "ZEDQA dor".
local function say(s) print("ZEDQA dor " .. tostring(s)) end
local p = getPlayer()
local D = ZeD.Dashboard
local pass, fail = 0, 0
local function check(ok, what) if ok then pass = pass + 1; say("PASS " .. what) else fail = fail + 1; say("FAIL " .. what) end end
local rec
pcall(function()
    local r = getFileReader("zedqa_odo_persist.txt", false)
    local line = r and r:readLine()
    if r then r:close() end
    local k, o, t, sh, x, y = tostring(line):match("^(%S+) (%S+) (%S+) (%S+) (%S+) (%S+)")
    if k then rec = { key = tonumber(k), odo = tonumber(o), trip = tonumber(t), show = sh == "true", x = tonumber(x), y = tonumber(y) } end
end)
local home = { x = p:getX(), y = p:getY(), z = p:getZ() }
local car, key
local Q, qi, t0 = {}, 1, nil
local function step(ms, fn) Q[#Q + 1] = { ms = ms, fn = fn } end
local function tp(x, y) p:teleportTo(x, y, 0); pcall(function() p:setX(x); p:setY(y); p:setZ(0); p:setLastX(x); p:setLastY(y); p:setLastZ(0) end) end
step(100, function()
    if not rec then say("ERR no zedqa_odo_persist.txt record"); return end
    say(string.format("before the quit: key %s odo %s trip %s TRIP showing %s at %d,%d", tostring(rec.key), tostring(rec.odo), tostring(rec.trip), tostring(rec.show), rec.x, rec.y))
    tp(rec.x + 3.5, rec.y + 0.5)
end)
step(8000, function()
    if not rec then return end
    local it = getCell():getVehicles():iterator()
    while it:hasNext() do local v = it:next(); local k = nil; pcall(function() k = v:getKeyId() end); if k == rec.key then car = v end end
    check(car ~= nil, "the car kept before the quit is there")
    if not car then return end
    local md = car:getModData()
    say(string.format("after the relaunch: ZeD_odo %s ZeD_trip %s ZeD_odoTrip %s", tostring(md.ZeD_odo), tostring(md.ZeD_trip), tostring(md.ZeD_odoTrip)))
    check(math.abs((tonumber(md.ZeD_odo) or -1) - (rec.odo or -2)) < 0.01, "the odometer is kept (" .. tostring(md.ZeD_odo) .. ", was " .. tostring(rec.odo) .. ")")
    check(math.abs((tonumber(md.ZeD_trip) or -1) - (rec.trip or -2)) < 0.01, "the trip is kept (" .. tostring(md.ZeD_trip) .. ", was " .. tostring(rec.trip) .. ")")
    check((md.ZeD_odoTrip == true) == rec.show, "the window's ODO / TRIP is kept (" .. tostring(md.ZeD_odoTrip) .. ")")
    pcall(function() key = p:getInventory():AddItem(car:createVehicleKey()) end)
    pcall(function() car:enter(0, p) end)
    if p:getVehicle() then triggerEvent("OnEnterVehicle", p) end
end)
step(1500, function()
    local d = D.getInstance()
    if not (car and d) then return end
    for _, hr in ipairs(d._hit or {}) do if hr.id == "ignition" then d:onMouseDown(hr.x + math.floor(hr.w / 2), hr.y + math.floor(hr.h / 2)) end end
end)
step(1500, function()
    local d = D.getInstance()
    local s = d and d._st
    if s then
        say(string.format("seated, key in: the dash reads odo %s trip %s TRIP %s", tostring(s.odo), tostring(s.trip), tostring(s.odoTrip)))
        check(math.abs((s.odo or -1) - (rec.odo or -2)) < 0.01, "the dash shows the kept odometer")
    end
    pcall(function() getCore():TakeFullScreenshot("zqa_dor_reloaded.png") end)
end)
step(1000, function()
    local v = p:getVehicle()
    if v then pcall(function() v:exit(p) end); triggerEvent("OnExitVehicle", p) end
    if car then pcall(function() car:permanentlyRemove() end) end
    if key then pcall(function() p:getInventory():Remove(key) end) end
    tp(home.x, home.y)
end)
step(4000, function() say(pass .. " passed, " .. fail .. " failed"); say("DONE") end)
local function tick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    t0 = t0 or getTimestampMs()
    if getTimestampMs() - t0 < s.ms then return end
    t0 = nil; qi = qi + 1
    local ok, e = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. " " .. tostring(e)) end
end
say("start")
Events.OnTick.Add(tick)
