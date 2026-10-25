-- ZeD QA (Oct 24 2026): dashboards round 6, after a reload. zedqa_dash_r6_parts.lua left two Nyalas beside the
-- character (one tray untouched, one clicked) and wrote their key numbers and trays to Zomboid/Lua/zedqa_r6_persist.txt;
-- the game was quit (saved) and loaded again. Each car is found by its key number, the character sits in it, and its tray
-- must read as before. Both cars are removed after. grep "ZEDQA r6r".
local p = getPlayer(); local D = ZeD.Dashboard
local TAG = "r6r"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
if getGameSpeed() == 0 then setGameSpeed(1) end
local errs = 0
local function err(s) errs = errs + 1; say("ERR " .. s) end

local Q, qi = {}, 1
local function step(f) Q[#Q + 1] = f end
local function now() return getTimestampMs() end
local function waitMs(ms) local t0 = nil; step(function() t0 = t0 or now(); if now() - t0 >= ms then t0 = nil; return true end end) end
local function act(f) step(function() f(); return true end) end
local function waitFor(cond, ms, onTimeout)
    local t0 = nil
    step(function()
        t0 = t0 or now()
        if cond() then t0 = nil; return true end
        if now() - t0 >= ms then t0 = nil; if onTimeout then onTimeout() end; return true end
    end)
end

ZeDQA_R6_NoKeep = true   -- (zedqa_dash_r6_parts.lua after this in the same game keeps no cars)
-- test cars earlier runs left in the save (their keys; Oct 24 runs whose keep step failed or whose list was lost)
local LEFTOVER_KEYS = { [32702477] = true, [13773838] = true, [56640713] = true }
local want = {}
do
    local r = getFileReader("zedqa_r6_persist.txt", false)
    if r then
        local line = r:readLine()
        while line do
            local which, key, open, level, x, y = line:match("^(%S+) (%S+) (%S+) (%S+) ?(%-?%d*) ?(%-?%d*)")
            if which then want[#want + 1] = { which = which, key = tonumber(key), open = open == "true", level = tonumber(level), x = tonumber(x), y = tonumber(y) } end
            line = r:readLine()
        end
        r:close()
    end
end
if #want == 0 then err("no zedqa_r6_persist.txt (run zedqa_dash_r6_parts.lua first)") end

local function findCar(key)
    local it = getCell():getVehicles():iterator()
    while it:hasNext() do
        local v = it:next()
        if v:getKeyId() == key then return v end
    end
    return nil
end

-- open ground (director, Oct 24 2026: "You are spawning cars in the forest with rocks all over. Go to a large parking
-- lot or the drag strip"): the Irvington Speedway's drag strip. Where the character stood is kept in its modData
-- (ZeDDashR6Home) and it goes back there at the end, so the other QA scripts find it where they expect.
local SITE = { x = 925, y = 13040 }   -- mid-strip, between the two grandstands (x 875-893 and 964-977)
local pmd = p:getModData()
pmd.ZeDDashR6Home = pmd.ZeDDashR6Home or { x = p:getX(), y = p:getY(), z = p:getZ() }
local function tp(x, y, z)
    p:teleportTo(x, y, z or 0)
    pcall(function() p:setX(x); p:setY(y); p:setZ(z or 0); p:setLastX(x); p:setLastY(y); p:setLastZ(z or 0) end)
end
-- the squares round a point are loaded (a square and its chunk 8 squares out every way)
local function loadedAround(x, y)
    for _, o in ipairs({ { 0, 0 }, { 8, 0 }, { -8, 0 }, { 0, 8 }, { 0, -8 } }) do
        local sq = getCell():getGridSquare(math.floor(x) + o[1], math.floor(y) + o[2], 0)
        if not sq then return false end
        local ch = nil; pcall(function() ch = sq:getChunk() end)
        if not ch then return false end
    end
    return true
end
local function goSite()
    act(function() tp(SITE.x + 0.5, SITE.y + 0.5, 0) end)
    waitFor(function() return loadedAround(SITE.x, SITE.y) end, 40000, function() err("the speedway never loaded round the character") end)
    waitMs(3000)
    act(function()
        say(string.format("at the speedway %d,%d (home %d,%d)", math.floor(p:getX()), math.floor(p:getY()), math.floor(pmd.ZeDDashR6Home.x), math.floor(pmd.ZeDDashR6Home.y)))
        pcall(function() getCore():TakeFullScreenshot("zqa_" .. TAG .. "_site.png") end)
    end)
end
local function goHome()
    act(function() local h = pmd.ZeDDashR6Home; if h then tp(h.x, h.y, h.z) end end)
    waitFor(function() local h = pmd.ZeDDashR6Home; return not h or loadedAround(h.x, h.y) end, 40000)
    act(function() pmd.ZeDDashR6Home = nil; say(string.format("back home %d,%d", math.floor(p:getX()), math.floor(p:getY()))) end)
end
goSite()
-- (the cars were parked where the list says: go there and let it load, or they are not in the cell)
if want[1] and want[1].x then
    act(function() tp(want[1].x + 2.5, want[1].y + 2.5, 0) end)
    waitFor(function() return loadedAround(want[1].x, want[1].y) end, 40000, function() err("the cars' place never loaded") end)
    waitMs(3000)
end

local found = 0
for _, w in ipairs(want) do
    local car = nil
    act(function()
        car = findCar(w.key)
        if not car then err(w.which .. " car with key " .. tostring(w.key) .. " not found after the reload"); return end
        found = found + 1
        pcall(function() car:enter(0, p) end)
        if p:getVehicle() == car then triggerEvent("OnEnterVehicle", p) else err(w.which .. " could not enter") end
    end)
    waitMs(600)
    act(function()
        if not car then return end
        local d = D.getInstance()
        local s = d and d._st
        local md = tostring(car:getModData().ZeD_ash)
        say(string.format("%s key=%s after reload: open=%s level=%s md=%s (before: open=%s level=%s)", w.which, tostring(w.key),
            tostring(s and s.ashIsOpen), tostring(s and s.ashOpen), md, tostring(w.open), tostring(w.level)))
        if not s or s.ashIsOpen ~= w.open or s.ashOpen ~= w.level then err(w.which .. " tray changed across the reload") end
        pcall(function() getCore():TakeFullScreenshot("zqa_r6r_" .. w.which .. ".png") end)
    end)
    waitMs(300)
    act(function()
        if not car then return end
        pcall(function() car:exit(p) end); triggerEvent("OnExitVehicle", p)
        pcall(function() car:permanentlyRemove() end)
    end)
    waitMs(300)
end
-- leftovers: the listed keys, and any Nyala left on the strip (the speedway's own race cars are left alone)
local function sweep(where, nyalasToo)
    act(function()
        local it = getCell():getVehicles():iterator()   -- (the list's get() is not callable from Lua; its iterator is)
        local gone = {}
        while it:hasNext() do
            local v = it:next()
            if v then
                local k, sn, d = nil, "", 999
                pcall(function() k = v:getKeyId() end)
                pcall(function() sn = tostring(v:getScriptName()) end)
                pcall(function() d = math.max(math.abs(v:getX() - SITE.x), math.abs(v:getY() - SITE.y)) end)
                if (k and LEFTOVER_KEYS[k]) or (nyalasToo and sn == "Base.CarNormal" and d <= 140) then gone[#gone + 1] = { v, k, sn } end
            end
        end
        for _, g in ipairs(gone) do
            say(string.format("removed a leftover test car (%s): %s key %s", where, g[3], tostring(g[2])))
            pcall(function() g[1]:permanentlyRemove() end)
        end
    end)
end
sweep("speedway", true)
act(function()
    -- checked and removed: the list is done (kept when a car was not found, for another look)
    if found == #want then local w = getFileWriter("zedqa_r6_persist.txt", true, false); w:write(""); w:close() end
end)
goHome()
sweep("home", false)
act(function() say("errors=" .. errs); say("DONE") end)

local function tick()
    if not Q[qi] then Events.OnTick.Remove(tick); return end
    local ok_, r = pcall(Q[qi])
    if not ok_ then say("step error: " .. tostring(r)); r = true end
    if r then qi = qi + 1 end
end
Events.OnTick.Add(tick)
