-- ZeDUI/tools/qa/mp_b7_dash_bob.lua  (Nov 7 2026, QA; merge 2, the dash with two players): on bob's client. What reaches bob from
-- the dash's module (ZeDDash: "fig", the server's figures for the car he rides in) and what bob's own client sends on it
-- ("odo" is the driver's alone; "ask" is a passenger's as he sits down), counted by a listener of this script's own and a
-- wrap of ZeD.ServerPart.send, kept in the global ZEDQA_DC across runs. The phase is in Lua/zedqa_dash_phase.txt:
--   watch   bob outside the car while the admin drives off up the strip: nothing for him, nothing from him (45 s)
--   board   bob gets in a passenger seat the game's way (ISVehicleMenu.onEnter): his dash asks, the server answers with
--           its figures, and his copy of the car reads what the server holds
--   ride    the admin drives back down the strip with bob aboard and stops the engine: the figures reach bob as the
--           server takes them, bob sends nothing on, and after the engine-off send bob's copy is the server's, with
--           "another mod's" key (52 s)
-- grep "ZEDQA dbb".
local function say(s) print("ZEDQA dbb " .. tostring(s)) end
local pass, fail = 0, 0
local function check(ok, what, d)
    if ok then pass = pass + 1 else fail = fail + 1 end
    say((ok and "PASS " or "FAIL ") .. what .. (d ~= nil and (" (" .. tostring(d) .. ")") or ""))
end
local p = getPlayer()
local D = ZeD.Dashboard
local function now() return getTimestampMs() end
local r = getFileReader("zedqa_dash_phase.txt", false)
local PHASE = r and r:readLine() or "watch"
if r then r:close() end
PHASE = PHASE:match("%a+") or "watch"
local carId = nil
r = getFileReader("zedqa_dash_car.txt", false)
if r then carId = tonumber(r:readLine() or ""); r:close() end
if not ZEDQA_DC then
    ZEDQA_DC = { fig = 0, odo = 0, ask = 0, last = nil }
    Events.OnServerCommand.Add(function(m, c, a)
        if m == "ZeDDash" and c == "fig" then ZEDQA_DC.fig = ZEDQA_DC.fig + 1; ZEDQA_DC.last = a; ZEDQA_DC.lastAt = getTimestampMs() end
        if m == "ZeDQA" and c == "carread" then ZEDQA_DC.read = a end
    end)
    local S = ZeD.ServerPart
    local orig = S.send
    S.send = function(module, command, args)
        if module == "ZeDDash" then
            if command == "odo" then ZEDQA_DC.odo = ZEDQA_DC.odo + 1 end
            if command == "ask" then ZEDQA_DC.ask = ZEDQA_DC.ask + 1 end
        end
        return orig(module, command, args)
    end
end
local DC = ZEDQA_DC
local function carById()
    local it = getCell():getVehicles():iterator()
    while it:hasNext() do local v = it:next(); if v:getId() == carId then return v end end
    return nil
end
local function dist(v) return v and math.sqrt((v:getX() - p:getX()) ^ 2 + (v:getY() - p:getY()) ^ 2) or -1 end
local function mine(v) local md = v and v:getModData() or {}; return md.ZeD_odo, md.ZeD_trip, md.QA_otherMod end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("dbb_" .. n .. ".png") end) end
local base = { fig = DC.fig, odo = DC.odo, ask = DC.ask }
-- (bob's new character opens the survival guide on startup, over everything: closed, so the pictures show the dash)
if ZeD.GuideBook and ZeD.GuideBook.isOpen and ZeD.GuideBook.isOpen(0) then ZeD.GuideBook.close(0); print("ZEDQA dbb the guide was open: closed") end
say("phase " .. PHASE .. ", car " .. tostring(carId) .. ", counts so far fig " .. DC.fig .. " odo " .. DC.odo .. " ask " .. DC.ask)
local plan, i, t0 = {}, 1, now()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function addUntil(ms, cond, fn) plan[#plan + 1] = { ms = ms, cond = cond, fn = fn } end
if PHASE == "watch" then
    add(500, function() local v = carById(); say(string.format("bob outside, %.1f squares from the car; in a car: %s", dist(v), tostring(p:getVehicle() ~= nil))) end)
    for k = 1, 9 do add(5000, function() local v = carById(); local o = mine(v); say(string.format("t=%ds %.1f squares from the car; figures to me %d; my copy odo %s", k * 5, dist(v), DC.fig - base.fig, tostring(o))) end) end
    add(500, function()
        check(DC.fig - base.fig == 0, "a player outside the car is sent no figures while it drives", DC.fig - base.fig)
        check(DC.odo - base.odo == 0 and DC.ask - base.ask == 0, "and his client sends nothing on the dash's module", (DC.odo - base.odo) .. " odo, " .. (DC.ask - base.ask) .. " ask")
        check(D.getInstance() == nil or not D.getInstance():isVisible(), "no dash on his screen")
    end)
elseif PHASE == "board" then
    local v = nil
    addUntil(8000, function() v = carById(); return v ~= nil and dist(v) < 8 end, function()
        say(string.format("the car %.1f squares away", dist(v)))
        if v then ISVehicleMenu.onEnter(p, v, 1) end
    end)
    addUntil(20000, function() return v and p:getVehicle() == v end, function()
        if v and p:getVehicle() ~= v then
            for s = 2, v:getMaxPassengers() - 1 do if not v:isSeatOccupied(s) then ISVehicleMenu.onEnter(p, v, s); break end end
        end
    end)
    addUntil(20000, function() return v and p:getVehicle() == v end, function()
        say("in the car: " .. tostring(v and p:getVehicle() == v) .. ", seat " .. tostring(v and v:getSeat(p)) .. ", at the wheel " .. tostring(v and v:isDriver(p)))
    end)
    add(7000, function()
        sendClientCommand(p, "ZeDQA", "carread", { veh = carId }); DC.read = nil
    end)
    addUntil(5000, function() return DC.read ~= nil end, function()
        local a = DC.read or {}
        local o, t = mine(v)
        local d = D.getInstance()
        local s = d and d._st
        say(string.format("the server: odo %s trip %s; my copy: odo %s trip %s; my dash: shown %s odo %s trip %s", tostring(a.odo), tostring(a.trip), tostring(o), tostring(t), tostring(d and d:isVisible()), tostring(s and s.odo), tostring(s and s.trip)))
        check(DC.ask - base.ask >= 1, "his dash asks as he sits down", DC.ask - base.ask)
        check(DC.fig - base.fig >= 1, "the server answers him", DC.fig - base.fig)
        check(o ~= nil and a.odo ~= nil and math.abs(o - a.odo) < 0.001 and math.abs((t or 0) - (a.trip or 0)) < 0.001, "his copy reads the server's figures")
        check(s ~= nil and s.odo ~= nil and math.abs(s.odo - (a.odo or -1)) < 0.05, "his dash shows them", s and s.odo)
        check(DC.odo - base.odo == 0, "a passenger sends no figures", DC.odo - base.odo)
        shot("passenger_seated")
    end)
elseif PHASE == "ride" then
    local v = carById()
    add(500, function() say("riding: " .. tostring(v and p:getVehicle() == v)) end)
    for k = 1, 9 do add(5000, function() local o, t = mine(v); local s = D.getInstance() and D.getInstance()._st; say(string.format("t=%ds figures to me %d (last odo %s); my copy odo %s trip %s; my dash odo %s", k * 5, DC.fig - base.fig, tostring(DC.last and DC.last.odo), tostring(o), tostring(t), tostring(s and s.odo))) end) end
    add(7000, function() sendClientCommand(p, "ZeDQA", "carread", { veh = carId }); DC.read = nil end)
    addUntil(5000, function() return DC.read ~= nil end, function()
        local a = DC.read or {}
        local o, t, other = mine(v)
        say(string.format("the server: odo %s trip %s other %s running %s; my copy: odo %s trip %s other %s", tostring(a.odo), tostring(a.trip), tostring(a.other), tostring(a.running), tostring(o), tostring(t), tostring(other)))
        check(DC.fig - base.fig >= 1, "the figures reach the passenger while the car drives", DC.fig - base.fig)
        check(DC.odo - base.odo == 0, "the passenger sends nothing on", DC.odo - base.odo)
        check(o ~= nil and a.odo ~= nil and math.abs(o - a.odo) < 0.001 and math.abs((t or 0) - (a.trip or 0)) < 0.001, "after the engine off his copy is the server's")
        check(other == "kept on the server" and a.other == "kept on the server", "another mod's key: on the server, and on his copy after the engine-off send", tostring(a.other) .. " / " .. tostring(other))
        shot("passenger_after")
    end)
end
add(300, function() say(pass .. " passed, " .. fail .. " failed") end)
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
