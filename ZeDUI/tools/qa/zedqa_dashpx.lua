-- ZeD QA (Oct 16 2026): the pixel-art dashboards (v6) live, one vehicle at a time beside the player.
-- spawn, repair, fuel, battery, key, enter, key in (screenshot: the bulb check), start, radio + heater +
-- headlights (+ lightbar, no siren), screenshot (Zomboid/Screenshots/zqa_dashpx_<tag>.png), print the
-- dashboard's screen rect and badge, leave, remove. The van is the Spiffo's van (the sticker shows); five livery
-- cars after the 19 check the badges against the game's names (a missing script just logs 'spawn failed'). grep "ZEDQA dpx".
if ZEDQA_HOME then ZEDQA_HOME("dpx") end   -- (punch list 47: open ground first; an earlier script can leave the character indoors)
local p = getPlayer(); local D = ZeD.Dashboard
local LIST = {
    { "01_luxury", "Base.CarLuxury" }, { "02_nyala", "Base.CarNormal" }, { "03_cossette", "Base.SportsCar" },
    { "04_police", "Base.CarLightsPolice" }, { "05_d6", "Base.PickUpTruck" }, { "06_dashelite", "Base.ModernCar" },
    { "07_primani", "Base.ModernCar02" }, { "08_dart", "Base.SmallCar" }, { "09_horizon", "Base.SmallCar02" },
    { "10_wagon", "Base.CarStationWagon" }, { "11_suv", "Base.SUV" }, { "12_van", "Base.VanSpiffo" },
    { "13_bulldriver", "Base.PickUpVan" }, { "14_rancher", "Base.OffRoad" }, { "15_taxi", "Base.CarTaxi" },
    { "16_ambulance", "Base.VanAmbulance" }, { "17_fire", "Base.PickUpTruckLightsFire" }, { "18_ranger", "Base.CarLightsRanger" },
    { "19_race", "Base.RaceCar12" },
    -- the badges read the game's own name for the car: a livery never reaches the maker's badge
    { "20_knoxvan", "Base.Van_KnoxDisti" }, { "21_fossoild6", "Base.PickUpTruckLightsFossoil" },
    { "22_wreckednyala", "Base.CarNormalSmashedFront" }, { "23_meadesheriff", "Base.ModernCarLightsMeadeSheriff" },
    { "24_lcpd", "Base.CarLightsLouisvilleCounty" },
}
local function say(s) print("ZEDQA dpx " .. tostring(s)) end
-- (Nov 12 2026, test cleanup) This is the one 19-car pass: zedqa_dash19.lua ran the same 19 cars with fewer
-- readings and is archived. Each car now has real checks (seated, the key in, the engine running, a dash of a
-- known design drawn wholly on the screen), so a car can fail. The smoke run takes ONE car from it:
-- zedqa_dash_one.lua, run right before, sets ZEDQA_DASH_ONE to a tag of LIST for the next run of this script only.
local nPass, nFail = 0, 0
local function check(ok, what) if ok then nPass = nPass + 1; say("PASS " .. what) else nFail = nFail + 1; say("FAIL " .. what) end end
if type(ZEDQA_DASH_ONE) == "string" then
    local one = {}
    for _, e in ipairs(LIST) do if e[1] == ZEDQA_DASH_ONE then one[#one + 1] = e end end
    say("one car only: " .. ZEDQA_DASH_ONE .. " (" .. #one .. " of " .. #LIST .. ")")
    if #one == 0 then say("FAIL no car in the list is tagged " .. ZEDQA_DASH_ONE) end
    LIST = one
end
ZEDQA_DASH_ONE = nil
if getGameSpeed() == 0 then setGameSpeed(1) end
local steps = {}; local function at(n, f) steps[#steps + 1] = { n = n, f = f } end
local cur, curKey = nil, nil
-- (42.22: removing the car in the same tick as the exit leaves the engine updating a seated player in
-- a car with no physics, a NullPointerException that drops the game to the main menu; the car is
-- removed by the tick loop once the player is out of it)
local pending = nil
local function clean()
    if pending and p:getVehicle() ~= pending then pcall(function() pending:permanentlyRemove() end); pending = nil end
end
local function leave()
    local v = p:getVehicle(); if v then v:exit(p); triggerEvent("OnExitVehicle", p) end
    if cur then
        if p:getVehicle() == cur then pending = cur else pcall(function() cur:permanentlyRemove() end) end
    end
    if curKey then pcall(function() p:getInventory():Remove(curKey) end) end
    cur, curKey = nil, nil
end
-- (42.22, Oct 28 2026: the character is seated only once the car has a square, a chunk and live physics;
-- entering in the spawn's own tick leaves the engine updating a seated player in a car with no physics,
-- a NullPointerException that drops the game to the main menu, as zedqa_dashnight.lua found on Oct 22)
-- (a square a car was just removed from gives the next car no physics: the next free square is tried, as
-- zedqa_dashnight.lua does)
local OFFS = { { 5, 2 }, { 5, -3 }, { -5, 2 }, { 2, 5 }, { -4, -4 }, { 6, 6 }, { -6, 0 } }
local function carReady(v)
    -- (Nov 12 2026: the shared rule, zedqa_prelude.lua: a square, a chunk, its physics seen awake once, near the character)
    return ZEDQA_CAR_READY ~= nil and ZEDQA_CAR_READY(v)
end
local t = 10
at(t, leave)
t = t + 20
for _, e in ipairs(LIST) do
    local tag, script = e[1], e[2]
    local entered = false
    local tries, since = 0, 0
    local function attempt()
        since = 0
        -- (Nov 12 2026, test cleanup rule 7: the one shared car spawn in zedqa_prelude.lua; it checks the whole footprint
        -- on the strip's marked spots and takes the spots in turn)
        if not ZEDQA_CAR_SPAWN then say("ERR needs zedqa_prelude.lua first (ZEDQA_CAR_SPAWN)"); return false end
        local v = ZEDQA_CAR_SPAWN(script, "dpx")
        if v then cur = v; return true end
        return false
    end
    at(t, function()
        entered, tries = false, 0
        clean()
        if not attempt() then say("ERR " .. tag .. " spawn failed " .. script .. " (no loaded free square beside the character)") end
    end)
    for pt = t + 3, t + 90, 3 do
        at(pt, function()
            if entered or not cur then return end
            since = since + 3
            if not carReady(cur) then
                if since >= 36 then
                    say(tag .. " car not ready in 36 ticks; removed, next square")
                    pcall(function() cur:permanentlyRemove() end); cur = nil
                    if not attempt() then say("ERR " .. tag .. " spawn failed " .. script .. " (no ready car on any square beside the character)") end
                end
                return
            end
            local v = cur
            pcall(function() v:repair() end)
            pcall(function() local g = v:getPartById("GasTank"); g:setContainerContentAmount(g:getContainerCapacity()) end)
            pcall(function()
                local b = v:getPartById("Battery"); local it = b and b:getInventoryItem()
                if it then pcall(function() it:setCurrentUsesFloat(1.0) end); pcall(function() it:setUsedDelta(1.0) end) end
            end)
            pcall(function() curKey = p:getInventory():AddItem(v:createVehicleKey()) end)
            -- (the game's own OnEnterVehicle handlers assume the character is seated: a car that cannot be entered,
            -- like the wrecked Nyala, whose seat the game refuses, must not fire the event, and its row must not
            -- report the dashboard left over from the car before)
            local okEnter = false; pcall(function() okEnter = v:enter(0, p) end)
            entered = p:getVehicle() ~= nil
            if not entered then
                local seat = false; pcall(function() seat = v:isSeatInstalled(0) end)
                say(tag .. " could not enter " .. script .. " (enter=" .. tostring(okEnter) .. " seat0 installed=" .. tostring(seat) .. ")")
                cur = nil   -- (no further tries)
                return
            end
            triggerEvent("OnEnterVehicle", p)
        end)
    end
    at(t + 93, function() if cur and not entered then say("ERR " .. tag .. " car not ready in 90 ticks (not entered)") end end)
    at(t + 100, function() if cur and entered then pcall(function() cur:setKeysInIgnition(true) end) end end)
    at(t + 120, function() if entered then pcall(function() getCore():TakeFullScreenshot("zqa_dashpx_" .. tag .. "_keyon.png") end) end end)
    at(t + 135, function()
        if not cur or not entered then return end
        pcall(function() ISVehicleMenu.onStartEngine(p) end)
        local d = D.getInstance(); if not (d and d._st) then say(tag .. " no dashboard"); return end
        if not d._st.radioOn then d:_fire("pwr", false) end
        if not d._st.heaterOn then d:_fire("heat", false) end
        if not d._st.lights then d:_fire("lights", false) end
        local lb = false; pcall(function() lb = cur:hasLightbar() end)
        if lb then d:_fire("lbar", false) end
    end)
    at(t + 335, function()
        if not entered then
            -- (the wrecked Nyala cannot be entered by design; any other car that was not entered did not get its checks)
            if tag ~= "22_wreckednyala" then check(false, tag .. ": the character got into the car") end
            return
        end
        local d = D.getInstance()
        pcall(function() getCore():TakeFullScreenshot("zqa_dashpx_" .. tag .. ".png") end)
        local x, y, w, h = -1, -1, -1, -1
        pcall(function() x, y, w, h = d:getAbsoluteX(), d:getAbsoluteY(), d:getWidth(), d:getHeight() end)
        local run = false; pcall(function() run = cur:isEngineRunning() end)
        local b = d and d._badge or {}
        say(string.format("%s design=%s rect=%d,%d,%d,%d k=%s running=%s radio=%s/%s heat=%s lights=%s name=%s livery=%s make=%s model=%s unit=%s hits=%d screen=%dx%d",
            tag, tostring(d and d._designId), x, y, w, h, tostring(d and d._s), tostring(run), tostring(d and d._st and d._st.radioOn),
            tostring(d and d._st and d._st.radio and d._st.radio.kind), tostring(d and d._st and d._st.heaterOn),
            tostring(d and d._st and d._st.lights), tostring(b.name), tostring(b.livery), tostring(b.make), tostring(b.model),
            tostring(b.unit), #(d and d._hit or {}), getCore():getScreenWidth(), getCore():getScreenHeight()))
        local keyIn = false; pcall(function() keyIn = cur:isKeysInIgnition() end)
        check(p:getVehicle() == cur, tag .. ": the character is in the car")
        check(keyIn, tag .. ": the key is in the ignition")
        check(run, tag .. ": the engine is running")
        check(d ~= nil and d._designId ~= nil, tag .. ": the dash has a design (" .. tostring(d and d._designId) .. ")")
        check(d ~= nil and w > 0 and h > 0 and x >= 0 and y >= 0 and x + w <= getCore():getScreenWidth() and y + h <= getCore():getScreenHeight(),
            string.format("%s: the dash is drawn wholly on the screen (%d,%d %dx%d)", tag, x, y, w, h))
    end)
    at(t + 360, leave)
    t = t + 380
end
at(t, function() clean(); say(nPass .. " passed, " .. nFail .. " failed"); say("DONE") end)
local n, i = 0, 1
local function tick()
    n = n + 1
    clean()
    while steps[i] and steps[i].n <= n do
        local ok, err = pcall(steps[i].f); if not ok then say("step error: " .. tostring(err)) end
        i = i + 1
    end
    if not steps[i] then Events.OnTick.Remove(tick) end
end
Events.OnTick.Add(tick)
