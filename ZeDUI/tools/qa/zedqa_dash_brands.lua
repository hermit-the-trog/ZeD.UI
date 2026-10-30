-- ZeD QA (Oct 29 2026): the maker's mark on the console (HANDOFF_dash_brands_20261029.md). Staging as
-- zedqa_dash_keys_edge.lua: a fresh car beside the character on the drag strip, never a car from elsewhere.
--   per car: the windows' layout reset, the car seated, the key in (OFF); the dash's design and its mark (st.brand) are
--   checked against the car's maker, the mark's sprite and its model line are logged, and a shot is taken.
--   The 13 civilian dashes with their own cars; the Chevalier Step Van on the Valuline's dash (the Chevalier mark, STEP
--   VAN under it); a modded car's name ("Ford Bronco") on the Nyala's dash: the game ships no car outside its own
--   families, so the name is put in through the game's own text lookup while the dash's real badge builder
--   (D._badges) works out the car again, as for a modded script: the plaque. Then the Dash Elite and the Cossette at
--   full night (D.qaNight), lights on.
--   A parked car that moves (> 3 km/h) fell through the ground: that car is rejected (ERR), not judged.
-- Screenshots: Zomboid/Screenshots/zqa_dbr_<case>.png; each shot logs the dash's screen rect and k. Leaves no car, no key
-- and the windows reset. grep "ZEDQA dbr".
local p = getPlayer(); local D = ZeD.Dashboard
local TAG = "dbr"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
if getGameSpeed() == 0 then setGameSpeed(1) end
local errs = 0
local function err(s) errs = errs + 1; say("ERR " .. s) end

local Q, qi = {}, 1
local function step(f) Q[#Q + 1] = f end
local function now() return getTimestampMs() end
local function waitMs(ms) local t0 = nil; step(function() t0 = t0 or now(); if now() - t0 >= ms then t0 = nil; return true end end) end
local function waitFor(cond, ms, onTimeout)
    local t0 = nil
    step(function()
        t0 = t0 or now()
        if cond() then t0 = nil; return true end
        if now() - t0 >= ms then t0 = nil; if onTimeout then onTimeout() end; return true end
    end)
end
local function act(f) step(function() f(); return true end) end

local function dash() return D.getInstance() end
local function st() local d = dash(); return d and d._st end
local function click(id)
    local d = dash(); if not d then return false end
    for _, hr in ipairs(d._hit or {}) do
        if hr.id == id then return d:onMouseDown(hr.x + math.floor(hr.w / 2), hr.y + math.floor(hr.h / 2)) and true or false end
    end
    return false
end
local function resetWindows() pcall(function() ZeD_Window.resetLayout() end) end
local function fuel(v, f) pcall(function() local g = v:getPartById("GasTank"); g:setContainerContentAmount(g:getContainerCapacity() * f) end) end

-- the mark's sprite and model line on this dash for this brand, as the data lists them
local function partsFor(d, brand)
    local des = ZeD.DashPx.designs[d._designId]
    local spr, line = "-", "-"
    for _, q in ipairs(des and des.parts or {}) do
        if q.src == "brand" and q.when == brand then
            if q.t == "sprite" then spr = string.format("%s@%d,%d %dx%d tex=%s", q.sprite, q.x, q.y, q.w, q.h, tostring(ZeD.Px.tex("media/textures/ZeD/dashpx/" .. q.sprite .. ".png") ~= nil))
            elseif q.t == "badge" then line = string.format("%s@%d,%d w%d %s", q.role, q.x, q.y, q.w, q.align or "c") end
        end
    end
    return spr, line
end
local function shot(n, wantDesign, wantBrand)
    local d = dash(); if not d then err(n .. " no dash"); return end
    local x, y, w, h = -1, -1, -1, -1
    pcall(function() x, y, w, h = d:getAbsoluteX(), d:getAbsoluteY(), d:getWidth(), d:getHeight() end)
    local s, b = d._st or {}, d._badge or {}
    local spr, line = partsFor(d, s.brand)
    say(string.format("shot %s design=%s brand=%s make=%s model=%s tag=%s rect=%d,%d,%d,%d k=%s sprite=%s line=%s", n,
        tostring(d._designId), tostring(s.brand), tostring(b.make), tostring(b.model), tostring(b.tag), x, y, w, h, tostring(d._s), spr, line))
    if d._designId ~= wantDesign then err(n .. " design " .. tostring(d._designId) .. ", want " .. wantDesign) end
    if s.brand ~= wantBrand then err(n .. " mark " .. tostring(s.brand) .. ", want " .. wantBrand) end
    if spr == "-" then err(n .. " no sprite for the mark " .. tostring(s.brand) .. " on " .. tostring(d._designId)) end
    pcall(function() getCore():TakeFullScreenshot("zqa_" .. TAG .. "_" .. n .. ".png") end)
end

-- staging, as zedqa_dash_keys_edge.lua: a fresh car on a free loaded square beside the character, seated only once it has
-- a square and a chunk and has held them READY_HOLD_MS
local OFFS = { { 5, 2 }, { 5, -3 }, { -5, 2 }, { 2, 5 }, { -4, -4 }, { 6, 6 }, { -6, 0 } }
local MAXD = 12
local cur, curKey, tries, rot = nil, nil, 0, 0
local function carReady(v)
    local sq, chunk, dist = nil, nil, 999
    pcall(function() sq = v:getSquare() end)
    local okC = pcall(function() chunk = v:getChunk() end)
    if not okC and sq then pcall(function() chunk = sq:getChunk() end) end
    pcall(function() dist = v:DistTo(p) end)
    return sq ~= nil and chunk ~= nil and dist <= MAXD
end
local READY_HOLD_MS = 1500
local readySince = nil
local function carSettled(v)
    local removed = false; pcall(function() removed = v:isRemovedFromWorld() end)
    if removed or not carReady(v) then readySince = nil; return false end
    readySince = readySince or getTimestampMs()
    return getTimestampMs() - readySince >= READY_HOLD_MS
end
local function spawn(script)
    while tries < #OFFS do
        tries = tries + 1
        local o = (tries <= 4) and OFFS[(rot + tries - 1) % 4 + 1] or OFFS[tries]
        local sq = getCell():getGridSquare(math.floor(p:getX()) + o[1], math.floor(p:getY()) + o[2], math.floor(p:getZ()))
        local free = false
        if sq then pcall(function() free = sq:isFree(false) and not sq:HasTree() and not sq:getVehicleContainer() end) end
        if sq and free then
            local v = addVehicleDebug(script, IsoDirections.N, nil, sq)
            if v then cur = v; return true end
        end
    end
    return false
end
local pending = nil
local function clean()
    if pending and p:getVehicle() ~= pending then pcall(function() pending:permanentlyRemove() end); pending = nil end
end
local function leave()
    local v = p:getVehicle(); if v then pcall(function() v:exit(p) end); triggerEvent("OnExitVehicle", p) end
    if cur then
        if p:getVehicle() == cur then pending = cur else pcall(function() cur:permanentlyRemove() end) end
    end
    if curKey then pcall(function() p:getInventory():Remove(curKey) end) end
    cur, curKey = nil, nil
end
local function stage(n, script)
    local failed = false
    act(function() leave() end)
    waitMs(1500)
    act(function()
        resetWindows()
        tries = 0; rot = rot + 1; failed = false
        if not spawn(script) then failed = true; err(n .. " spawn failed " .. script) end
    end)
    act(function() readySince = nil end)
    waitFor(function() return failed or not cur or carSettled(cur) end, 5000, function()
        if cur then pcall(function() cur:permanentlyRemove() end); cur = nil end
        if not spawn(script) then failed = true; err(n .. " no ready car " .. script) end
    end)
    act(function()
        if failed or not cur then return end
        local v = cur
        pcall(function() v:repair() end)
        fuel(v, 1)
        readySince = nil
    end)
    waitFor(function() return failed or (cur and carSettled(cur)) end, 8000)
    act(function()
        if failed or not cur then return end
        local v = cur
        if not carSettled(v) then err(n .. " car not settled at the seat step; not entered"); failed = true; return end
        pcall(function() if v:isKeysInIgnition() then v:setKeysInIgnition(false) end end)
        pcall(function() curKey = p:getInventory():AddItem(v:createVehicleKey()) end)
        pcall(function() v:enter(0, p) end)
        if p:getVehicle() then triggerEvent("OnEnterVehicle", p) else err(n .. " could not enter " .. script); failed = true end
    end)
    waitMs(800)
    act(function() resetWindows() end)
    waitMs(700)
    return function() return not failed and cur ~= nil and p:getVehicle() == cur end
end

-- a modded car's name on a game car: the game's text lookup gives the name, the dash's own badge builder works the car
-- out again as a modded script (not one of the game's families)
local function asModded(name, designId, script)
    local d = dash(); if not (d and cur) then err("modded: no dash"); return end
    local gt = getTextOrNull
    getTextOrNull = function(k, ...) if tostring(k):sub(1, 16) == "IGUI_VehicleName" then return name end; return gt(k, ...) end
    local ok, b = pcall(D._badges, ZeD.DashPx.designs[designId], cur, script, false)
    getTextOrNull = gt
    if not ok then err("modded: " .. tostring(b)); return end
    d._badge = b       -- (kept for this car: the dash works its badges out again only for another car or language)
end

-- name, script, the dash it gets, the mark it gets
local CARS = {
    { "luxury", "Base.CarLuxury", "luxury", "mercia" },
    { "nyala", "Base.CarNormal", "nyala", "chevalier" },
    { "cossette", "Base.SportsCar", "cossette", "chevalier" },
    { "d6", "Base.PickUpTruck", "d6", "chevalier" },
    { "dashelite", "Base.ModernCar", "dashelite", "dash" },
    { "primani", "Base.ModernCar02", "primani", "chevalier" },
    { "dart", "Base.SmallCar", "dart", "chevalier" },
    { "horizon", "Base.SmallCar02", "horizon", "masterson" },
    { "wagon", "Base.CarStationWagon", "wagon", "chevalier" },
    { "suv", "Base.SUV", "suv", "franklin" },
    { "van", "Base.Van", "van", "franklin" },
    { "bulldriver", "Base.PickUpVan", "bulldriver", "dash" },
    { "rancher", "Base.OffRoad", "rancher", "dash" },
    { "stepvan", "Base.StepVan", "van", "chevalier" },
    { "modded", "Base.CarNormal", "nyala", "plaque", modded = { "Ford Bronco", "Base.FordBronco" } },
    { "dashelite_night", "Base.ModernCar", "dashelite", "dash", night = true },
    { "cossette_night", "Base.SportsCar", "cossette", "chevalier", night = true },
}
local ONLY = ZeD_QA_DBR_ONLY; ZeD_QA_DBR_ONLY = nil      -- (a set of case names, to rerun a few)
act(function() D.qaNight = nil; D.qaLit = nil end)
for _, e in ipairs(CARS) do
    local n, script, wantDesign, wantBrand = e[1], e[2], e[3], e[4]
    if not ONLY or ONLY[n] then
        local ok = stage(n, script)
        local moving = false
        act(function()
            if not ok() then return end
            if e.night then D.qaNight = 1; D.qaLit = true else D.qaNight = nil; D.qaLit = nil end
            click("ignition")                 -- the key in, at OFF
            if e.modded then asModded(e.modded[1], wantDesign, e.modded[2]) end
        end)
        waitMs(1500)
        act(function()
            if not ok() then return end
            local s = st() or {}
            if (tonumber(s.speed) or 0) > 3 then
                moving = true; err(n .. " parked car moving at " .. tostring(s.speed) .. " km/h (fell through the ground?): rejected")
                return
            end
            shot(n, wantDesign, wantBrand)
        end)
        waitMs(600)
    end
end

act(function()
    leave()
    D.qaNight = nil; D.qaLit = nil
    resetWindows()
end)
waitMs(1000)
act(function() clean(); say(errs == 0 and "PASS" or ("errors " .. errs)); say("DONE") end)

local function tick()
    clean()
    local f = Q[qi]
    if not f then Events.OnTick.Remove(tick); return end
    local ok, done = pcall(f)
    if not ok then say("step error: " .. tostring(done)); qi = qi + 1; return end
    if done then qi = qi + 1 end
end
Events.OnTick.Add(tick)
