-- ZeDUI/tools/qa/rt_vehicles.lua  (Nov 18 2026, QA): the release test's car (ZeDUI/qa/RELEASE_TEST.md, the row
-- "rt_vehicles.lua"). Built on rt_kit.lua (run it first) and the prelude's car helpers (zedqa_prelude.lua:
-- ZEDQA_CAR_WAIT / _PREP / _ENTER / _AWAY). grep "ZEDQA rt_veh".
--
-- One police car (Base.CarLightsPolice: a lightbar and a radio) spawned on the drag strip beside the character,
-- repaired, fuelled, its key in the bag, the character in the driver's seat. Then:
--   dash     ZeD's dash (ZeD_Dashboard.lua) shows the car, its design (DashPx.lua) has its gauges and lamps; a click
--            on the ignition puts the key in: the bulb check lights the lamps; a second click starts the engine
--            (the game's own start): the dash reads it running, the rev needle up, the fuel needle on a full tank,
--            the bulb check over
--   radio    the wheel's Device Options (ISVehicleMenu.onSignalDevice, hooked) brings the radio up close
--            (ZeD_CarRadio.lua); a click on its power turns it on, a click on TUNE's right half moves the frequency;
--            put back as it was (tuned back, power as it was), then put away
--   seats    the seat key (ISVehicleMenu.onShowSeatUI, hooked) opens ZeD's seat chooser (or the cabin pop-out on
--            Immersive): it lists every seat of the car, the driver's seat yours
--   siren    the wheel's Lightbar (ISLightbarUITimedAction, hooked) brings the siren controller up close
--            (ZeD_SirenController.lua, its plate SirenPlate.lua / PhysPx): a click on LIGHTS 1 turns the bar on (the
--            dash's lightbar lamp follows), a click on OFF turns it off again
--   vehicle  the engine off by the dash's ignition, then the game's Vehicle Mechanics (ISVehicleMenu.onMechanic: the
--            character gets out and inspects the car) opens the World window's Vehicle tab (MechanicsTab.lua): it
--            lists the car's parts; a click on a row opens that part's card, a second click closes it
--   (Nov 18 2026, QA, the ledger's car gaps closed here:) the game's own dash stays hidden while ZeD's shows, and
--            ZeD's goes once the character is out; the dash's headlight switch flips the headlights and back; the seat
--            key opens the cabin pop-out (in Lite too), the chooser for a car the cabin cannot lay out; an animal trailer's Check
--            Animals (ISVehicleMenu.onCheckAnimalInside, hooked) opens the Vehicle tab on the trailer
-- Each surface is measured with RT.bounds. Put back: the radio and the lightbar as they were, the props closed, the
-- Style, the World window on Loot, the character out, the key taken back and the car and trailer removed
-- (ZEDQA_CAR_AWAY).

if not RT then
    print("ZEDQA rt_veh ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA rt_veh VERDICT FAIL 1")
    print("ZEDQA rt_veh DONE")
    return
end

local Q = RT.make("rt_veh")
local S = {}
local H = {}
S.p, S.pn = RT.p, RT.pn
S.D = ZeD.Dashboard
S.R = ZeD.CarRadio
S.O = ZeD.RadioOps
S.Seats = ZeD.Seats
S.Siren = ZeD.Siren
S.MT = ZeD.MechanicsTab

-- ===================================================================== helpers
function H.inCar() return S.v ~= nil and S.p:getVehicle() == S.v end
function H.dash() local d = nil; pcall(function() d = S.D.getInstance(S.pn) end); return d end
function H.st() local d = H.dash(); return d and d._st end
function H.vis(o)
    local v = false
    if o then pcall(function() v = o:isReallyVisible() end) end
    return v
end
-- a press on a control by its hit (local rect), as the mouse's press reaches the prop; dx: where across it (0..1)
function H.pressHit(panel, h, fx, up)
    if not (panel and h) then return false end
    local x = h.x + math.floor(h.w * (fx or 0.5))
    local y = h.y + math.floor(h.h / 2)
    panel:onMouseDown(x, y)
    if up then panel:onMouseUp(x, y) end
    return true
end
function H.hitOf(list, ids)
    for _, id in ipairs(ids) do
        for _, h in ipairs(list or {}) do if h.id == id then return h end end
    end
    return nil
end
function H.ids(list)
    local out = {}
    for _, h in ipairs(list or {}) do out[#out + 1] = tostring(h.id) end
    return table.concat(out, " ")
end
-- the dash's ignition, clicked (its hit), else fired as the click would (said so)
function H.ignition()
    local d = H.dash()
    if not d then return false end
    local h = H.hitOf(d._hit, { "ignition" })
    if h then return H.pressHit(d, h, 0.5, false) end
    Q.say("NOTE the dash has no ignition hit this frame (" .. H.ids(d._hit) .. "): fired as its click does")
    pcall(function() d:_fire("ignition", false) end)
    return true
end
function H.design()
    local d = H.dash()
    local id = d and d._designId
    local des = id and ZeD.DashPx and ZeD.DashPx.designs and ZeD.DashPx.designs[id]
    return id, des
end
function H.parts(des, t)
    local n = 0
    for _, pt in ipairs((des and des.parts) or {}) do if pt.t == t then n = n + 1 end end
    return n
end
function H.radioPart()
    local part = nil
    pcall(function() part = S.v:getPartById("Radio") end)
    if part then
        local ok = false
        pcall(function() ok = part:getInventoryItem() ~= nil and part:getDeviceData() ~= nil end)
        if not ok then part = nil end
    end
    return part
end
function H.radioRead()
    local st = nil
    if S.radioPart then pcall(function() st = S.O.read(S.radioPart) end) end
    return st
end
function H.radioProp() local r = nil; pcall(function() r = S.R.get(S.pn) end); return r end
function H.seatWin()
    local w = nil
    pcall(function() w = S.Seats.get(S.pn) end)
    if H.vis(w) then return w end
    pcall(function() w = S.Seats.getPopout(S.pn) end)
    if H.vis(w) then return w end
    return nil
end
function H.sirenProp() local r = nil; pcall(function() r = S.Siren.get(S.pn) end); return r end
function H.lightbar()
    local m = -1
    pcall(function() m = S.v:getLightbarLightsMode() end)
    return m
end
function H.headlights()
    local on = false
    pcall(function() on = S.v:getHeadlightsOn() end)
    return on and true or false
end
function H.chooser() local w = nil; pcall(function() w = S.Seats.get(S.pn) end); return w end
function H.popout() local w = nil; pcall(function() w = S.Seats.getPopout(S.pn) end); return w end
-- Style (ZeD setup, Look: 1 Full, 2 Lite; beta 21 retired the Dashboard row), the run's own kept to put back. The
-- value only: the option's onChange would also set the additions to Vanilla.
function H.setStyle(n)
    local o = ZeD.Settings and ZeD.Settings.lookStyleOption
    if not o then return end
    if S.styleWas == nil then pcall(function() S.styleWas = o:getValue() end) end
    pcall(function() o:setValue(n) end)
end
function H.putStyle()
    local o = ZeD.Settings and ZeD.Settings.lookStyleOption
    if o and S.styleWas ~= nil then pcall(function() o:setValue(S.styleWas) end) end
    S.styleWas = nil
    if S.popWas then S.Seats.popToggle = S.popWas; S.popWas = nil end
end
function H.ms() local w = RT.ww(); return w and S.MT.getState(w) end
function H.zone(id) local s = H.ms(); return s and s.byId and s.byId[id] end

-- ===================================================================== the car
Q.step(2, function()
    if getGameSpeed() <= 0 then pcall(setGameSpeed, 1) end
    if not (ZEDQA_CAR_WAIT and ZEDQA_CAR_PREP and ZEDQA_CAR_ENTER and ZEDQA_CAR_AWAY) then
        S.failWhy = "the prelude's car helpers are not loaded (zedqa_prelude.lua runs first)"
        return
    end
    S.pairWas = RT.isOpen()
    ZEDQA_CAR_WAIT("Base.CarLightsPolice", "rt_veh", function(v)
        S.v = v
        -- (repaired, fuelled and seated in the same tick, once it has a square, a chunk and its physics)
        S.key = ZEDQA_CAR_PREP(v)
        pcall(function() if v:isKeysInIgnition() then v:setKeysInIgnition(false) end end)
        local ok, why = ZEDQA_CAR_ENTER(v, 0)
        if not ok then S.failWhy = why end
        S.ready = true
    end, function(why) S.failWhy = why or "no ready car" end, 6000)
end)
Q.waitFor(5, 3600, function() return S.ready or S.failWhy ~= nil end, function(ok)
    Q.check(S.v ~= nil and H.inCar(), "a police car spawned beside the character, the character in the driver's seat", tostring(S.failWhy))
end)

-- ===================================================================== the dash
Q.waitFor(10, 300, function() return not H.inCar() or (H.vis(H.dash()) and H.st() ~= nil) end, function(ok)
    if not H.inCar() then return end
    local d = H.dash()
    Q.check(H.vis(d) and d.vehicle == S.v, "dash: ZeD's dash shows in the car")
    -- (Nov 18 2026, QA, the ledger: the game's own dash stays out of sight while ZeD's shows)
    local vd, vdVis = nil, false
    pcall(function() vd = getPlayerVehicleDashboard(S.pn) end)
    if vd then pcall(function() vdVis = vd:isVisible() end) end
    Q.check(not vdVis, "dash: the game's own dash is not shown beside ZeD's")
    local id, des = H.design()
    Q.check(id ~= nil and des ~= nil, "dash: it has a design for the car", tostring(id))
    Q.check(H.parts(des, "needle") > 0 or H.parts(des, "gauge") > 0, "dash: its design has gauges", H.parts(des, "needle") .. " needles")
    Q.check(H.parts(des, "lamp") > 0, "dash: its design has lamps", H.parts(des, "lamp") .. " lamps")
    RT.bounds(Q, "the dash")
end)
Q.step(5, function() if H.inCar() then H.ignition() end end)
Q.waitFor(5, 300, function() local s = H.st(); return not H.inCar() or (s and s.keysIn) end, function(ok)
    if not H.inCar() then return end
    local s = H.st() or {}
    Q.check(s.keysIn == true, "dash: a click on the ignition puts the key in")
    Q.check(s.check == true and s.genLamp == true and s.engLamp == true and s.oilLamp == true,
        "dash: key on, engine off: the bulb check lights the lamps", "check " .. tostring(s.check) .. ", battery " .. tostring(s.genLamp)
        .. ", engine " .. tostring(s.engLamp) .. ", oil " .. tostring(s.oilLamp))
end)
Q.waitMs(600)
Q.step(1, function() S.t0 = getTimestampMs(); S.tries = 0; if H.inCar() then H.ignition() end end)
Q.waitFor(5, 2400, function()
    if not H.inCar() then return true end
    local s = H.st()
    if s and s.running then return true end
    -- (a start that did not take: tried again, as a player turns the key again)
    if s and s.keysIn and not s.cranking and getTimestampMs() - S.t0 > 2500 and S.tries < 5 then
        S.tries = S.tries + 1
        S.t0 = getTimestampMs()
        H.ignition()
    end
    return false
end, function(ok)
    if not H.inCar() then return end
    Q.check(ok and H.st() and H.st().running, "dash: a second click on the ignition starts the engine (the game's start)", S.tries .. " retries")
end)
Q.waitMs(2500)
Q.step(1, function()
    if not H.inCar() then return end
    local s = H.st() or {}
    Q.check(s.running == true and (s.rpm or 0) > 0, "dash: running: the rev needle is up", string.format("rpm %.0f", s.rpm or 0))
    Q.check((s.fuel or 0) > 0.5, "dash: the fuel needle reads the full tank", string.format("fuel %.2f", s.fuel or 0))
    Q.check(s.check == false and s.oilLamp == false, "dash: running: the bulb check is over (oil lamp dark)", tostring(s.oilLamp))
    RT.bounds(Q, "the dash, engine running")
end)

-- ===================================================================== the headlights
-- (Nov 18 2026, QA, the ledger: the dash's headlight switch, its own hit, through the game's onToggleHeadlights)
Q.step(5, function()
    if not H.inCar() then return end
    S.lightsWas = H.headlights()
    local d = H.dash()
    local h = d and H.hitOf(d._hit, { "lights" })
    if not Q.check(h ~= nil, "dash: it has its headlight switch", d and H.ids(d._hit)) then S.noLights = true; return end
    H.pressHit(d, h, 0.5, false)
end)
Q.waitFor(5, 300, function() return S.noLights or not H.inCar() or H.headlights() ~= S.lightsWas end, function(ok)
    if S.noLights or not H.inCar() then return end
    Q.check(ok, "dash: a click on the headlight switch flips the headlights", tostring(S.lightsWas) .. " -> " .. tostring(H.headlights()))
    local d = H.dash()
    local h = d and H.hitOf(d._hit, { "lights" })
    if h then H.pressHit(d, h, 0.5, false) end
end)
Q.waitFor(5, 300, function() return S.noLights or not H.inCar() or H.headlights() == S.lightsWas end, function(ok)
    if S.noLights or not H.inCar() then return end
    Q.check(ok, "dash: a second click puts the headlights back", tostring(H.headlights()))
end)

-- ===================================================================== the radio
Q.step(5, function()
    if not H.inCar() then return end
    S.radioPart = H.radioPart()
    if not S.radioPart then Q.skip("the car radio", "this police car has no radio fitted"); return end
    local r = H.radioRead() or {}
    S.radioWas = { on = r.switchOn, channel = r.channel }
    Q.check(ISVehicleMenu._zedRadio ~= nil, "radio: ZeD's hook is on the wheel's Device Options")
    pcall(ISVehicleMenu.onSignalDevice, S.p, S.radioPart)
end)
Q.waitFor(5, 300, function()
    local pr = H.radioProp()
    return not S.radioPart or (H.vis(pr) and pr._hits ~= nil and #pr._hits > 0)
end, function(ok)
    if not S.radioPart then return end
    local pr = H.radioProp()
    Q.check(ok and H.vis(pr), "radio: Device Options brings the car radio up close", tostring(pr and pr.kind))
    RT.bounds(Q, "the car radio")
    -- its power: a click on PWR, else on VOL (VOL pushes for power on the sets without a PWR key)
    local r = H.radioRead() or {}
    if pr and not r.switchOn then
        local h = H.hitOf(pr._hits, { "pwr", "power", "vol" })
        Q.check(h ~= nil, "radio: it has a power control", H.ids(pr._hits))
        H.pressHit(pr, h, 0.5, true)
    end
end)
Q.waitFor(5, 300, function() local r = H.radioRead(); return not S.radioPart or (r and r.switchOn) end, function(ok)
    if not S.radioPart then return end
    local r = H.radioRead() or {}
    Q.check(r.switchOn == true, "radio: the click turns it on (the game's radio action)")
    if r.powered then Q.check(r.on == true, "radio: with the engine running it plays") end
    S.chBefore = r.channel
    local pr = H.radioProp()
    local h = pr and H.hitOf(pr._hits, { "tune", "dial" })
    Q.check(h ~= nil, "radio: it has a tuning knob", pr and H.ids(pr._hits))
    if h then H.pressHit(pr, h, 0.85, true) end
end)
Q.waitFor(5, 300, function() local r = H.radioRead(); return not S.radioPart or (r and r.channel ~= S.chBefore) end, function(ok)
    if not S.radioPart then return end
    local r = H.radioRead() or {}
    Q.check(ok, "radio: a click on TUNE's right half moves the frequency", tostring(S.chBefore) .. " -> " .. tostring(r.channel))
    -- tuned back: the left half
    local pr = H.radioProp()
    local h = pr and H.hitOf(pr._hits, { "tune", "dial" })
    if h then H.pressHit(pr, h, 0.15, true) end
end)
Q.waitFor(5, 300, function() local r = H.radioRead(); return not S.radioPart or (r and r.channel == S.radioWas.channel) end, function(ok)
    if not S.radioPart then return end
    Q.check(ok, "radio: TUNE's left half tunes it back", tostring((H.radioRead() or {}).channel))
    -- the power as it was
    local r = H.radioRead() or {}
    if r.switchOn and not S.radioWas.on then pcall(S.O.power, S.p, S.radioPart) end
end)
Q.step(10, function()
    if not S.radioPart then return end
    pcall(ISVehicleMenu.onSignalDevice, S.p, S.radioPart)   -- (the same route puts it away)
end)
Q.step(10, function()
    if not S.radioPart then return end
    Q.check(not H.vis(H.radioProp()), "radio: Device Options again puts it away")
end)

-- ===================================================================== the seat chooser
-- (Nov 19 2026, QA: beta 21 retired the plain dash, so the seat key opens the cabin pop-out in Full and Lite alike;
-- the chooser stays for a car the cabin cannot lay out as rows, ZeD_SeatChooser.lua S.toggle: that case is made here
-- by the pop-out declining (S.Seats.popToggle answering false, put back after). Then the pop-out in Lite. The run's
-- own Style put back after.)
Q.step(5, function()
    if not H.inCar() then return end
    Q.check(ISVehicleMenu._zedSeats ~= nil, "seats: ZeD's hook is on the seat key")
    if S.Seats.popToggle and not S.popWas then
        S.popWas = S.Seats.popToggle
        S.Seats.popToggle = function() return false end
    end
end)
Q.step(5, function()
    if not H.inCar() then return end
    pcall(ISVehicleMenu.onShowSeatUI, S.p, S.v)
end)
Q.waitFor(5, 300, function() local w = H.seatWin(); return not H.inCar() or (w ~= nil and w._seats ~= nil) end, function(ok)
    if not H.inCar() then return end
    local w = H.seatWin()
    Q.check(ok and w ~= nil and w == H.chooser(), "seats: a car the cabin cannot lay out gets ZeD's seat chooser", tostring(w and w.Type))
    local n = 0
    pcall(function() n = S.v:getMaxPassengers() end)
    local seats = (w and w._seats) or {}
    Q.check(n > 0 and #seats == n, "seats: it lists every seat of the car", #seats .. " of " .. n)
    local mine = seats[1] and seats[1].kind
    Q.check(mine == "you", "seats: the driver's seat is yours", tostring(mine))
    RT.bounds(Q, "the seat chooser")
    if w then pcall(function() w:close() end) end
end)
Q.step(10, function()
    if not H.inCar() then return end
    Q.check(H.seatWin() == nil, "seats: it closes")
    if S.popWas then S.Seats.popToggle = S.popWas; S.popWas = nil end
    H.setStyle(2)
end)
Q.step(5, function()
    if not H.inCar() then return end
    pcall(ISVehicleMenu.onShowSeatUI, S.p, S.v)
end)
Q.waitFor(5, 300, function() return not H.inCar() or H.vis(H.popout()) or H.vis(H.chooser()) end, function(ok)
    if not H.inCar() then return end
    Q.check(ok and H.vis(H.popout()) and not H.vis(H.chooser()), "seats: in Lite the seat key opens the cabin pop-out",
        "pop-out " .. tostring(H.vis(H.popout())) .. ", chooser " .. tostring(H.vis(H.chooser())))
    RT.bounds(Q, "the seat pop-out")
    pcall(function() local w = H.popout(); if H.vis(w) then w:close() end end)
    pcall(function() local w = H.chooser(); if H.vis(w) then w:close() end end)
end)
Q.step(10, function()
    if not H.inCar() then return end
    Q.check(not H.vis(H.popout()), "seats: the cabin pop-out closes")
    H.putStyle()
end)

-- ===================================================================== the siren
Q.step(5, function()
    if not H.inCar() then return end
    local hasBar = false
    pcall(function() hasBar = S.v:hasLightbar() end)
    Q.check(hasBar, "siren: the police car has a lightbar")
    if not hasBar then return end
    S.barWas = H.lightbar()
    pcall(function() S.sirenWas = S.v:getLightbarSirenMode() end)
    Q.check(ISLightbarUITimedAction and ISLightbarUITimedAction._zedSiren ~= nil, "siren: ZeD's hook is on the wheel's Lightbar")
    pcall(function() ISTimedActionQueue.add(ISLightbarUITimedAction:new(S.p)) end)
    S.sirenAsked = true
end)
Q.waitFor(5, 300, function()
    local pr = H.sirenProp()
    return not S.sirenAsked or (H.vis(pr) and pr._hits ~= nil and #pr._hits > 0)
end, function(ok)
    if not S.sirenAsked then return end
    local pr = H.sirenProp()
    Q.check(ok and H.vis(pr), "siren: the Lightbar brings the siren controller up close")
    Q.check(ZeD.SirenPlate ~= nil and ZeD.PhysPx and ZeD.PhysPx.plates and ZeD.PhysPx.plates.siren ~= nil, "siren: its plate is loaded (SirenPlate, PhysPx)")
    RT.bounds(Q, "the siren controller")
    local h = nil
    for _, hh in ipairs((pr and pr._hits) or {}) do if hh.group == "lights" and hh.mode == 1 and not hh.knob then h = hh end end
    Q.check(h ~= nil, "siren: LIGHTS has its 1 position", pr and H.ids(pr._hits))
    if h then H.pressHit(pr, h, 0.5, true) end
end)
Q.waitFor(5, 300, function() return not S.sirenAsked or H.lightbar() == 1 end, function(ok)
    if not S.sirenAsked then return end
    Q.check(ok, "siren: a click on LIGHTS 1 turns the bar on (the game's command)", tostring(H.lightbar()))
end)
Q.step(20, function()
    if not S.sirenAsked then return end
    local s = H.st() or {}
    Q.check(s.lbarLamp == true, "siren: the dash's lightbar lamp follows", tostring(s.lbarLamp))
    local pr = H.sirenProp()
    local h = nil
    for _, hh in ipairs((pr and pr._hits) or {}) do if hh.group == "lights" and hh.mode == (S.barWas or 0) and not hh.knob then h = hh end end
    if h then H.pressHit(pr, h, 0.5, true) end
end)
Q.waitFor(5, 300, function() return not S.sirenAsked or H.lightbar() == (S.barWas or 0) end, function(ok)
    if not S.sirenAsked then return end
    Q.check(ok, "siren: a click on its OFF puts the bar back", tostring(H.lightbar()))
    local pr = H.sirenProp()
    if pr then pcall(function() pr:close() end) end
end)

-- ===================================================================== the Vehicle tab
Q.step(10, function()
    if not H.inCar() then return end
    local s = H.st()
    if s and s.running then H.ignition() end   -- (running: the ignition shuts it off)
end)
Q.waitFor(5, 600, function() local s = H.st(); return not H.inCar() or (s and not s.running) end, function(ok)
    if not H.inCar() then return end
    Q.check(ok, "dash: a click on the ignition shuts the engine off")
    pcall(function() S.v:setKeysInIgnition(false) end)
end)
Q.step(10, function()
    if not S.v then return end
    S.mechAsked = true
    pcall(ISVehicleMenu.onMechanic, S.p, S.v)
end)
Q.waitFor(30, 3600, function()
    local w = RT.ww()
    return not S.mechAsked or (S.MT.isInspected(S.v) and w ~= nil and w._activeTab == "vehicle")
end, function(ok)
    if not S.mechAsked then return end
    Q.check(ok, "vehicle: the game's Vehicle Mechanics inspects the car and opens the World window's Vehicle tab")
end)
-- (Nov 18 2026, QA, the ledger: out of the car, the dash goes)
Q.waitFor(1, 300, function() return not S.mechAsked or (S.p:getVehicle() == nil and not H.vis(H.dash())) end, function(ok)
    if not S.mechAsked then return end
    Q.check(ok, "dash: out of the car, ZeD's dash is put away", "in a car " .. tostring(S.p:getVehicle() ~= nil) .. ", dash " .. tostring(H.vis(H.dash())))
end)
Q.step(30, function()
    if not S.mechAsked then return end
    local s = H.ms()
    local want = 0
    pcall(function()
        for i = 0, S.v:getPartCount() - 1 do
            local cat = S.v:getPartByIndex(i):getCategory() or "Other"
            if cat ~= "nodisplay" then want = want + 1 end
        end
    end)
    local got = (s and s.partsCache and s.partsCache.list and #s.partsCache.list) or 0
    Q.check(want > 0 and got == want, "vehicle: the tab lists the car's parts", got .. " of " .. want)
    Q.check(s and s.lastRows and #s.lastRows > 0, "vehicle: the parts' rows are drawn", s and s.lastRows and #s.lastRows)
    RT.bounds(Q, "the Vehicle tab")
    -- a row clicked (the window's click on the tab, at the row's middle)
    local z = s and s.lastRows and s.lastRows[1]
    S.row = z and z.part
    if z then pcall(S.MT.onClick, RT.ww(), z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)) end
end)
Q.step(20, function()
    if not S.row then return end
    local s = H.ms()
    Q.check(s and s.card == S.row, "vehicle: a click on a part's row opens its card", tostring(s and s.card) .. " (want " .. tostring(S.row) .. ")")
    local z = H.zone("mech:row:" .. S.row)
    if z then pcall(S.MT.onClick, RT.ww(), z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)) end
end)
Q.step(20, function()
    if not S.row then return end
    local s = H.ms()
    Q.check(s and s.card == nil, "vehicle: the same row again closes the card", tostring(s and s.card))
end)

-- ===================================================================== an animal trailer: Check Animals
-- (Nov 18 2026, QA, the ledger: the game's Check Animal(s) in Trailer, ISVehicleMenu.onCheckAnimalInside, hooked by
-- Overrides/TrailerAnimals.lua, opens the Vehicle tab on the trailer, scrolled to its animals. The prelude's helper
-- spawns it beside the character; it takes the police car away first, as the character is out of it now.)
Q.step(10, function()
    if not S.v then return end
    S.trAsked = true
    ZEDQA_CAR_WAIT("Base.Trailer_Livestock", "rt_veh", function(v) S.tr = v; S.trDone = true end,
        function(why) S.trWhy = why or "no trailer ready"; S.trDone = true end, 6000)
end)
Q.waitFor(5, 3600, function() return not S.trAsked or S.trDone end, function()
    if not S.trAsked then return end
    if not Q.check(S.tr ~= nil, "trailer: an animal trailer spawned beside the character", tostring(S.trWhy)) then return end
    Q.check(ISVehicleMenu._zedTrailerHooked == true, "trailer: ZeD's hook is on the game's Check Animals")
    pcall(ISVehicleMenu.onCheckAnimalInside, S.tr, S.p)
end)
Q.waitFor(10, 1800, function()
    if not S.tr then return true end
    local w = RT.ww()
    local s = H.ms()
    local cur = s and s.vehicles and s.vehicles[s.idx or 1]
    local id = -1
    pcall(function() id = S.tr:getId() end)
    return w ~= nil and w._activeTab == "vehicle" and cur ~= nil and cur.id == id
end, function(ok)
    if not S.tr then return end
    local isTr = false
    pcall(function() isTr = ZeD.MechTrailer.isTrailer(S.tr) end)
    local w = RT.ww()
    Q.check(ok and isTr, "trailer: Check Animals opens the Vehicle tab on the trailer's page", "tab " .. tostring(w and w._activeTab) .. ", trailer " .. tostring(isTr))
    RT.bounds(Q, "the trailer's page")
end)

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    pcall(function() local pr = H.radioProp(); if H.vis(pr) then pr:close() end end)
    pcall(function() local pr = H.sirenProp(); if H.vis(pr) then pr:close() end end)
    pcall(function() local w = H.seatWin(); if w then w:close() end end)
    if S.v then
        if S.radioPart and S.radioWas then
            local r = H.radioRead() or {}
            if r.switchOn and not S.radioWas.on then pcall(S.O.power, S.p, S.radioPart) end
        end
        if S.barWas and H.lightbar() ~= S.barWas then
            pcall(function() sendClientCommand(S.p, "vehicle", "setLightbarLightsMode", { mode = S.barWas }) end)
        end
        if S.sirenWas then
            local cur = -1
            pcall(function() cur = S.v:getLightbarSirenMode() end)
            if cur ~= S.sirenWas then pcall(function() sendClientCommand(S.p, "vehicle", "setLightbarSirenMode", { mode = S.sirenWas }) end) end
        end
    end
    pcall(function() S.p:StopAllActionQueue() end)
    pcall(function() local w = H.popout(); if H.vis(w) then w:close() end end)
    H.putStyle()
    RT.worldTab("loot")
end)
Q.step(10, function()
    if S.v then ZEDQA_CAR_AWAY(S.v, S.key) end
    if S.tr then ZEDQA_CAR_AWAY(S.tr) end
    if S.pairWas == false then RT.pairShut() end
end)
Q.waitFor(5, 600, function()
    if not S.v then return true end
    local gone = true
    pcall(function()
        local it = getCell():getVehicles():iterator()
        while it:hasNext() do
            local o = it:next()
            if o == S.v or (S.tr ~= nil and o == S.tr) then gone = false end
        end
    end)
    return gone and S.p:getVehicle() == nil
end, function(ok)
    if not S.v then return end
    local keyLeft = false
    pcall(function() keyLeft = S.key ~= nil and S.p:getInventory():contains(S.key) end)
    Q.check(ok and not keyLeft, "put back: the character out, the key taken back, the car removed")
end)
Q.start()
