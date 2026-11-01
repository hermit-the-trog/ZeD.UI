-- ZeDUI/tools/qa/gallery_nov1_radio.lua  (Nov 1 2026, QA)
-- The Workshop gallery retake (workshop/gallery/REVIEW_20261101.md, "Retakes" 8): page 35's car radio, g5_car_radio
-- (gallery_v5_five.lua's name, so shots.json keeps working). The t14 picture showed the station wagon's own ValuTech
-- FM set (Base.RadioBlack: gallery_v5_five.lua fits a radio only to a car that has none); the page's notes are about
-- the Premium Technologies CD receiver (Base.RadioRed, ZeD.RadioOps "premium"). Here the wagon's Radio part is fitted
-- with a Base.RadioRed for the shot (the way vanilla's install ends: Vehicles.InstallComplete.Radio) and its own set is
-- put back after. Then as gallery_v5_five.lua: in the driver's seat, the engine on, the radio on and tuned, the radio
-- up close (the vehicle wheel's Device Options: ISVehicleMenu.onSignalDevice). The prop's rect is logged.
-- In the mall lot: after gallery_v3_core.lua, gallery_v3_reveal.lua and gallery_v3_stage.lua (GAL.car, the wagon),
-- before gallery_v3_teardown.lua. "ZEDQA n1r ..." ending "ZEDQA n1r DONE".
local G = GAL
if not (G and G.spot and G.car and G.newSeq) then print("ZEDQA n1r ERR run gallery_v3_core.lua and gallery_v3_stage.lua first"); print("ZEDQA n1r DONE"); return end
if not (ZeD and ZeD.RadioOps and ZeD.CarRadio) then print("ZEDQA n1r ERR ZeD is not loaded"); print("ZEDQA n1r DONE"); return end
local S = G.newSeq("n1r", 420000)
local say = S.say
local p, pn = G.p, G.pn
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local RO, CR = ZeD.RadioOps, ZeD.CarRadio
local Z = { ok = true, why = "" }

function Z.kind(part)
    local st = nil
    pcall(function() st = RO.read(part) end)
    return st and st.kind or "?"
end
function Z.fit(v, part, item)
    part:setInventoryItem(item)
    -- (no set to put back: the part is left empty; vanilla's install would make one up)
    if not item then pcall(function() v:transmitPartItem(part) end); return end
    Vehicles.InstallComplete.Radio(v, part)
    pcall(function()
        local dd = part:getDeviceData()
        if dd and dd:getDevicePresets():getPresets():size() == 0 then dd:generatePresets() end
    end)
end

S.step(2, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    G.cleanLook()
    G.day()
    if CWm.isOpen() and WWm.isOpen() then CWm.toggleBothPaired(0)
    else
        if CWm.isOpen() then CWm.toggle(0) end
        if WWm.isOpen() then WWm.close() end
    end
    G.stand()
end)
S.zoomTo(1.0)
S.step(2, function()
    local v = G.car
    local d = 99
    pcall(function() d = v:DistTo(p) end)
    if d > 12 then Z.ok, Z.why = false, "car " .. d .. " away"; return end
    local part = v:getPartById("Radio")
    if not part then Z.ok, Z.why = false, "the car has no Radio part"; return end
    Z.part = part
    Z.old = part:getInventoryItem()
    Z.oldKind = Z.old and Z.kind(part) or "none"
    local ok, e = pcall(function() Z.fit(v, part, instanceItem("Base.RadioRed")) end)
    say(string.format("radio part: was %s (%s) | fitted Base.RadioRed %s, now %s", tostring(Z.old and Z.old:getFullType()),
        tostring(Z.oldKind), ok and "ok" or ("failed: " .. tostring(e)), Z.kind(part)))
    if not ok then Z.ok, Z.why = false, "could not fit the CD receiver" ; return end
    pcall(function() v:enter(0, p) end)
    Z.entered = p:getVehicle() ~= nil
    if Z.entered then pcall(function() triggerEvent("OnEnterVehicle", p) end) end
    if not Z.entered then Z.ok, Z.why = false, "could not get in" end
end)
S.step(30, function() if Z.entered then pcall(function() G.car:setKeysInIgnition(true) end) end end)
local ES = { tries = 0, last = -9999 }
S.poll(10, 1500, function()
    if not Z.entered then return true end
    local run = false
    pcall(function() run = G.car:isEngineRunning() end)
    if run then return true end
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    local busy = q and q.queue and #q.queue > 0
    if not busy and S.tick - ES.last > 120 and ES.tries < 5 then
        ES.tries = ES.tries + 1; ES.last = S.tick
        pcall(function() ISVehicleMenu.onStartEngine(p) end)
    end
    return false
end, function() say("note: the engine did not start") end)
S.step(60, function()
    local d = ZeD.Dashboard and ZeD.Dashboard.getInstance()
    if not (Z.entered and d and d._st) then return end
    if not d._st.radioOn then d:_fire("pwr", false) end
    local part = G.car:getPartById("Radio")
    if part then
        pcall(function() RO.setChannel(p, part, 101200) end)
        pcall(function() RO.run("SetVolume", p, part, 0.6) end)
    end
end)
S.step(90, function() end)
S.step(2, function()
    if not (Z.ok and Z.entered) then return end
    pcall(function() ISVehicleMenu.onSignalDevice(p, Z.part) end)
end)
S.step(60, function()
    local pr = CR.props and CR.props[pn]
    if Z.ok and Z.entered and pr and pr:isReallyVisible() then
        local st = nil
        pcall(function() st = RO.read(Z.part) end)
        say(string.format("radio: kind %s on %s channel %s", tostring(st and st.kind), tostring(st and st.on), tostring(st and st.channel)))
        S.shot("g5_car_radio")
        say(string.format("rect g5_car_radio prop %d %d %d %d", math.floor(pr:getAbsoluteX()), math.floor(pr:getAbsoluteY()),
            math.floor(pr:getWidth()), math.floor(pr:getHeight())))
    elseif Z.ok and Z.entered then S.err("g5_car_radio", "the radio did not come up")
    else S.err("g5_car_radio", Z.why) end
    pcall(function() CR.closeFor(pn) end)
end)
S.step(2, function()
    local d = ZeD.Dashboard and ZeD.Dashboard.getInstance()
    if Z.entered and d and d._st and d._st.radioOn then pcall(function() d:_fire("pwr", false) end) end
    pcall(function() if G.car:isEngineRunning() then G.car:shutOff() end end)
end)
S.step(30, function()
    local v = p:getVehicle()
    if v then pcall(function() v:exit(p) end); pcall(function() triggerEvent("OnExitVehicle", p) end) end
    Z.entered = false
end)
S.step(30, function()
    if Z.part then
        local ok = pcall(function() Z.fit(G.car, Z.part, Z.old) end)
        say(string.format("put back: the wagon's own radio %s (%s), now %s", tostring(Z.old and Z.old:getFullType()), ok and "ok" or "failed", Z.kind(Z.part)))
    end
end)
S.step(40, function() G.stand(); G.openTrunk(G.car); G.faceFront() end)
S.start()
