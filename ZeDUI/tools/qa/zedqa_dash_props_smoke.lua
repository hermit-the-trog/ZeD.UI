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
    say("pickup=" .. tostring(pickup ~= nil) .. " police=" .. tostring(police ~= nil))
    beside(pickup)
end)
at(10, function() enter(pickup) end)
at(50, function() local d = ZeD.Dashboard.getInstance(); say("dash visible=" .. tostring(d and d:isVisible()) .. " design=" .. tostring(d and d._designId)); ISVehicleMenu.onSignalDevice(p, pickup:getPartById("Radio")) end)
at(70, function() local r = ZeD.CarRadio.props[pn]; say("radio up=" .. tostring(r and r:isReallyVisible())); shot("01_pickup_radio") end)
at(75, function() ZeD.CarRadio.takeEscape(); leave() end)
at(80, function() beside(police) end)
at(100, function() enter(police) end)
at(140, function() ZeD.Siren.toggle(p) end)
at(160, function() local s = ZeD.Siren.props[pn]; local d = ZeD.Dashboard.getInstance(); say("siren up=" .. tostring(s and s:isReallyVisible()) .. " dash design=" .. tostring(d and d._designId)); shot("02_police_siren") end)
at(165, function() ZeD.Siren.takeEscape(); ISVehicleMenu.onSignalDevice(p, police:getPartById("Radio")) end)
at(185, function() local r = ZeD.CarRadio.props[pn]; say("ham radio up=" .. tostring(r and r:isReallyVisible())); shot("03_police_radio") end)
at(190, function() ZeD.CarRadio.takeEscape(); leave(); say("DONE") end)
local function t()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 200 then Events.OnTick.Remove(t) end
end
Events.OnTick.Add(t)
say("start")
