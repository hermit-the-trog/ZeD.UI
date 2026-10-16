-- ZeDUI/tools/qa/zedqa_car_radio_vanilla.lua  (Oct 15 2026)
-- Before captures for the car radio mockup: vanilla's ISRadioWindow on a
-- car's radio part (the wheel's Device Options slice, ISVehicleMenu.
-- onSignalDevice) - off, on and tuned, with a CD in a radio that takes one -
-- and on a ham-radio van. Plain backdrops too. Fits a RadioRed into the
-- pickup if its radio is missing. Copy to Zomboid/Lua/zedqa.lua, bump
-- zedqa.go; grep "ZEDQA cr". A spawned van is removed at the end.

local p = getPlayer()
local function say(s) print("ZEDQA cr " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_cr_" .. n .. ".png") end) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function near(pred, maxD)
    local best, bd
    local it = getCell():getVehicles():iterator()
    while it:hasNext() do
        local v = it:next()
        if pred(v) then local d = v:DistTo(p); if d < maxD and (not bd or d < bd) then best, bd = v, d end end
    end
    return best
end
local pickup, police, ham
local spawned = {}
local function radioOf(v)
    local part = v and v:getPartById("Radio")
    return part, part and part:getInventoryItem(), part and part:getDeviceData()
end
local function describe(tag, v)
    local part, item, dd = radioOf(v)
    say(string.format("%s %s radio=%s dd=%s", tag, tostring(v and v:getScriptName()), tostring(item and item:getFullType()), tostring(dd)))
    if dd then
        local presets = {}
        pcall(function()
            local l = dd:getDevicePresets():getPresets()
            for i = 0, l:size() - 1 do presets[#presets + 1] = string.format("%.1f %s", l:get(i):getFrequency() / 1000, l:get(i):getName()) end
        end)
        say(string.format("   on=%s ch=%s vol=%s media=%s battery=%s twoWay=%s range=%s-%s presets=[%s]", tostring(dd:getIsTurnedOn()), tostring(dd:getChannel()),
            tostring(dd:getDeviceVolume()), tostring(dd:getMediaType()), tostring(dd:getIsBatteryPowered()), tostring(dd:getIsTwoWay()),
            tostring(dd:getMinChannelRange()), tostring(dd:getMaxChannelRange()), table.concat(presets, "; ")))
    end
end
local function enter(v)
    if not v then say("no vehicle"); return end
    if v:DistTo(p) > 12 then say("too far " .. v:DistTo(p)); return end
    v:enter(0, p); triggerEvent("OnEnterVehicle", p)
end
local function leave() local v = p:getVehicle(); if v then v:exit(p); triggerEvent("OnExitVehicle", p) end end
local function window() return ISRadioWindow.instances and ISRadioWindow.instances[0] end
local function winIso() return ISRadioWindow.instancesIso and ISRadioWindow.instancesIso[0] end
local function closeAll() for _, w in ipairs({ window(), winIso() }) do if w and w:isVisible() then w:close() end end end

at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    p:setGodMod(true)
    local clim = getClimateManager()
    for i = 0, clim:getFloatMax() - 1 do
        local v = clim:getClimateFloat(i); local n = tostring(v:getName()):lower()
        if n:find("fog") or n:find("precip") or n:find("cloud") then v:setEnableAdmin(true); v:setAdminValue(0) end
    end
    pickup = near(function(v) return v:getScriptName() == "Base.PickUpTruck" end, 25)
    police = near(function(v) return v:hasLightbar() end, 25)
    local sq = getCell():getGridSquare(math.floor(p:getX()) - 4, math.floor(p:getY()) + 6, 0)
    ham = sq and addVehicleDebug("Base.VanRadio", IsoDirections.N, nil, sq)
    if ham then spawned[#spawned + 1] = ham end
    describe("pickup", pickup); describe("police", police); describe("ham", ham)
    -- the pickup gets the red radio (it takes CDs) if it has none
    local part, item = radioOf(pickup)
    if part and not item then
        local ok, e = pcall(function() part:setInventoryItem(instanceItem("Base.RadioRed")); pickup:transmitPartItem(part) end)
        say("fitted RadioRed ok=" .. tostring(ok) .. " " .. tostring(e)); describe("pickup", pickup)
    end
end)
-- 1. the pickup: off, then on and tuned, then with a CD
at(30, function() enter(pickup) end)
at(70, function() shot("bg_pickup") end)
at(75, function() local part = radioOf(pickup); if part then ISVehicleMenu.onSignalDevice(p, part) end end)
at(95, function() local w = window() or winIso(); say("window " .. tostring(w and w:getX()) .. "," .. tostring(w and w:getY()) .. " " .. tostring(w and w:getWidth()) .. "x" .. tostring(w and w:getHeight())); shot("v01_pickup_off") end)
at(100, function() local _, _, dd = radioOf(pickup); if dd then dd:setIsTurnedOn(true); dd:setChannel(96800); dd:setDeviceVolume(0.6) end end)
at(130, function() describe("pickup on", pickup); shot("v02_pickup_on") end)
at(135, function()
    local _, _, dd = radioOf(pickup)
    if dd and dd:getMediaType() >= 0 then
        local cd = instanceItem("Base.Disc_Retail")
        local ok, e = pcall(function() dd:addMediaItem(cd) end)
        say("cd in ok=" .. tostring(ok) .. " " .. tostring(e))
    end
end)
at(160, function() shot("v03_pickup_cd") end)
at(165, function() closeAll(); local _, _, dd = radioOf(pickup); if dd then dd:setIsTurnedOn(false) end; leave() end)
-- 2. the ham-radio van
at(195, function() enter(ham) end)
at(240, function() local part = radioOf(ham); if part then ISVehicleMenu.onSignalDevice(p, part) end end)
at(255, function() local _, _, dd = radioOf(ham); if dd then dd:setIsTurnedOn(true) end end)
at(280, function() describe("ham on", ham); shot("v04_ham") end)
at(285, function() closeAll(); local _, _, dd = radioOf(ham); if dd then dd:setIsTurnedOn(false) end; leave() end)
-- 3. the sheriff car: the plain backdrop with its dash
at(315, function() enter(police) end)
at(360, function() shot("bg_police"); describe("police", police) end)
at(365, function() leave() end)
at(380, function() for _, v in ipairs(spawned) do pcall(function() v:permanentlyRemove() end) end; say("DONE") end)

local function t()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 400 then Events.OnTick.Remove(t) end
end
Events.OnTick.Add(t)
say("start")
