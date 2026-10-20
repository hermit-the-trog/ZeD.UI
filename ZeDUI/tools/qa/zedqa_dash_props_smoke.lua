-- ZeDUI/tools/qa/zedqa_dash_props_smoke.lua  (Oct 16 2026)
-- After the v5 dash art was deleted: the v6 dash, the radio up close and the
-- siren controller still draw. Enters the pickup (radio), then the sheriff car
-- (radio + siren), screenshots each; the character steps beside each car first
-- (a far car's physics are not loaded). Copy to Zomboid/Lua/zedqa.lua, bump
-- zedqa.go; grep "ZEDQA sm".
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA sm " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_sm_" .. n .. ".png") end) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function near(pred)
    local best, bd
    local it = getCell():getVehicles():iterator()
    while it:hasNext() do local v = it:next(); if pred(v) then local d = v:DistTo(p); if not bd or d < bd then best, bd = v, d end end end
    return best
end
local function beside(v) if v then p:teleportTo(v:getX() + 2.5, v:getY(), 0) end end
local pickup, police
-- cars spawned beside the character when the QA save's own are not loaded (the character is left wherever the
-- last run ended); removed at the end
local spawned = {}
local dead = false
local finalAt = nil
-- (an abort skips the other steps and jumps the tick counter to just before the final one)
local function abort(msg) say("ERR " .. msg); dead = true; if finalAt then tick = finalAt - 2 end end
local function final(n, fn) finalAt = n; steps[#steps + 1] = { n = n, fn = fn, final = true } end   -- runs even after an abort
local function spawn(script, dx, dy)
    local sq = getCell():getGridSquare(math.floor(p:getX()) + dx, math.floor(p:getY()) + dy, math.floor(p:getZ()))
    if not sq then say("no square for " .. script); return nil end
    local ok, v = pcall(addVehicleDebug, script, IsoDirections.N, nil, sq)
    if ok and v then spawned[#spawned + 1] = v; say("spawned " .. script .. " beside the character"); return v end
    return nil
end
-- vanilla's install of a radio item into the part when the car has none (a spawned one)
local function ensureRadio(v, ft)
    local part = v and v:getPartById("Radio")
    if not part or part:getInventoryItem() then return end
    pcall(function()
        part:setInventoryItem(instanceItem(ft))
        Vehicles.InstallComplete.Radio(v, part)
        local dd = part:getDeviceData()
        if dd:getDevicePresets():getPresets():size() == 0 then dd:generatePresets() end
    end)
end
local function enter(v)
    if not v then return end
    if v:DistTo(p) > 6 then say("too far to get in: " .. string.format("%.1f", v:DistTo(p))); return end
    v:enter(0, p); triggerEvent("OnEnterVehicle", p)
end
local function leave() local v = p:getVehicle(); if v then v:exit(p); triggerEvent("OnExitVehicle", p) end end
at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    p:setGodMod(true)
    pickup = near(function(v) return v:getScriptName() == "Base.PickUpTruck" end)
    police = near(function(v) return v:hasLightbar() end)
    if not pickup then pickup = spawn("Base.PickUpTruck", -4, 0) end
    if not police then police = spawn("Base.CarLightsPolice", 4, 0) end
    say("pickup=" .. tostring(pickup ~= nil) .. " police=" .. tostring(police ~= nil))
    if not (pickup and police) then abort("no " .. (pickup and "police car with a lightbar" or "pickup") .. " in the loaded cell and the spawn failed") end
end)
-- (a spawned car gets a moment to settle before the character goes to it)
at(15, function()
    ensureRadio(pickup, "Base.RadioRed"); ensureRadio(police, "Base.HamRadio1")
    beside(pickup)
end)
at(25, function() enter(pickup) end)
at(65, function() local d = ZeD.Dashboard.getInstance(); say("dash visible=" .. tostring(d and d:isVisible()) .. " design=" .. tostring(d and d._designId)); ISVehicleMenu.onSignalDevice(p, pickup:getPartById("Radio")) end)
at(85, function() local r = ZeD.CarRadio.props[pn]; say("radio up=" .. tostring(r and r:isReallyVisible())); shot("01_pickup_radio") end)
at(90, function() ZeD.CarRadio.takeEscape(); leave() end)
at(95, function() beside(police) end)
at(115, function() enter(police) end)
at(155, function() ZeD.Siren.toggle(p) end)
at(175, function() local s = ZeD.Siren.props[pn]; local d = ZeD.Dashboard.getInstance(); say("siren up=" .. tostring(s and s:isReallyVisible()) .. " dash design=" .. tostring(d and d._designId)); shot("02_police_siren") end)
at(180, function() ZeD.Siren.takeEscape(); ISVehicleMenu.onSignalDevice(p, police:getPartById("Radio")) end)
at(200, function() local r = ZeD.CarRadio.props[pn]; say("ham radio up=" .. tostring(r and r:isReallyVisible())); shot("03_police_radio") end)
final(205, function()
    ZeD.CarRadio.takeEscape(); leave()
    for _, v in ipairs(spawned) do pcall(function() v:permanentlyRemove() end) end
    spawned = {}
    say("DONE" .. (dead and " (aborted)" or ""))
end)
local function t()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick and (s.final or not dead) then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 215 then Events.OnTick.Remove(t) end
end
Events.OnTick.Add(t)
say("start")
