-- (Nov 20 2026, QA: OUT OF DATE since beta 21. This script sets one or more of the retired per-piece Simple switches,
-- which nothing reads now (one Style switch: ZeD.Settings.lookStyleOption, 1 Full, 2 Lite). A Simple leg runs against
-- Full; a Full pick is a no-op. To reuse it, set lookStyleOption instead (the value only). Not in the release test.)
-- ZeDUI/tools/qa/gallery_v1_c2_garage.lua  (Nov 17 2026, QA): ZeD-GUI 1.0 gallery, lived-in retakes with a car in a
-- driveway in West Point: the nearest garage to the Fossoil with a clear paved 3 x 7 footprint beside it (else beside the
-- furnished house, else the street by the store; C2.driveway, logged). The character stays outdoors beside the car; it
-- is entered only through ZEDQA_CAR_ENTER (ready, within 25 squares: never a far car). Same content and names as today:
--   50 The Vehicle Tab   zqa_m79_<w>x<h>_2_hover_row, zqa_m79_<w>x<h>_6_card_brake_step   (zedqa_mech79.lua: a sedan,
--        its key, jack, lug wrench, wrench and screwdriver; Mechanics 3; Basic Mechanics learned by reading Laine's
--        Auto Manual when not known; the front left tire off; the game's Vehicle Mechanics; the first row in view under
--        the REAL pointer (release_check_mouse.ps1 "move": a script-set pointer makes no hover on 42.22), the part lit,
--        the pointer shown; then Mechanics 4 and the rear left brake's card with its step before (the tire first))
--        (today's two live in Screenshots/gallery_beta2; these land in Screenshots: the collect step moves them)
--   54 The Car Radio     g5_car_radio   (gallery_b19_b.lua: in the driver's seat, engine running, the Full dashboard,
--        the Premium CD receiver (Base.RadioRed) fitted, on, 101.2, volume 0.6, opened up close)
-- THE NEW RULE: the World window at the right edge (the Character window at the left), the car pop-up along the top;
-- the character and the car clear in the middle. Every shot logs the load line, any container over its limit and every
-- window's box. Needs zedqa_prelude.lua (ZEDQA_CAR_*) and the real-mouse helper: run the manifest with
-- release_check.ps1 -Manifest gallery_v1_c2.txt. Puts back: the car (taken away), its key and the tools, Mechanics,
-- the recipe and the read book as they were, the dashboard row, the windows, the character at the QA home.
-- Run after gallery_v1_c2_common.lua. grep "ZEDQA gv1g".
if not (C2 and C2.make and ZeD and ZeD_WorldWindow) then print("ZEDQA gv1g ERR run gallery_v1_c2_common.lua first (and ZeD on)"); print("ZEDQA gv1g DONE"); return end
local S = C2.make("gv1g")
S.maxMs = 1650000
S.v.p, S.v.pn = C2.p, C2.pn
S.v.MT = ZeD.MechanicsTab
S.v.sw, S.v.sh = C2.core:getScreenWidth(), C2.core:getScreenHeight()
S.v.N1 = "zqa_m79_" .. S.v.sw .. "x" .. S.v.sh .. "_2_hover_row"
S.v.N2 = "zqa_m79_" .. S.v.sw .. "x" .. S.v.sh .. "_6_card_brake_step"
function S.v.W() return C2.ww() end
function S.v.S() local w = C2.ww(); return w and S.v.MT and S.v.MT.getState(w) end
function S.v.zone(id) local s = S.v.S(); return s and s.byId and s.byId[id] end
-- a click at the zone's middle, as the World window passes it (a row out of view is pressed directly)
function S.v.press(z)
    local w = C2.ww(); if not (z and w) then return end
    local cx, cy = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    local c = z.clip
    if c and not (cx >= c.x and cx < c.x + c.w and cy >= c.y and cy < c.y + c.h) then S.say("(" .. z.id .. " is out of view: pressed directly)"); z.fn(); return end
    S.v.MT.onClick(w, cx, cy)
end

-- ===================================================================== the driveway
S.step(5, function()
    C2.save(S)
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    C2.rule()
    S.v.mechWas = S.v.p:getPerkLevel(Perks.Mechanics)
    S.v.dashWas = ZeD.Settings.dashStyleOption and ZeD.Settings.dashStyleOption:getValue()
end)
C2.goWestPoint(S)
S.step(2, function()
    S.v.B = C2.scan(C2.STORE.cx, C2.STORE.cy, 70)
    S.v.H = C2.house(S, S.v.B)
    S.v.street = C2.street(S)
    S.v.fp, S.v.where = C2.driveway(S, S.v.B, S.v.H, S.v.street)
    if not S.v.fp then S.say("ERR " .. tostring(S.v.where)) end
    C2.placeName = S.v.where
    pcall(function() getGameTime():setTimeOfDay(11.0) end)
end)
C2.carSpawn(S, "Base.CarNormal", function() return S.v.fp end, function(v)
    S.v.car = v
    C2.given = C2.given or {}
    pcall(function() local k = S.v.p:getInventory():AddItem(v:createVehicleKey()); if k then C2.given[#C2.given + 1] = k; S.v.key = k end end)
    for _, t in ipairs({ "Base.Jack", "Base.LugWrench", "Base.Wrench", "Base.Screwdriver" }) do C2.give(t) end
    S.v.p:setPerkLevelDebug(Perks.Mechanics, 3)
    local rb = S.v.p:getAlreadyReadBook()
    S.v.knewRecipe = true
    pcall(function() S.v.knewRecipe = S.v.p:isRecipeActuallyKnown("Basic Mechanics") end)
    S.v.readWas = rb:contains("Base.MechanicMag1")
    if S.v.readWas and not S.v.knewRecipe then
        while rb:contains("Base.MechanicMag1") do rb:remove("Base.MechanicMag1") end
        S.v.readWas = false
    end
    S.say("before: Basic Mechanics known " .. tostring(S.v.knewRecipe) .. ", magazine read " .. tostring(S.v.readWas) .. ", Mechanics " .. S.v.mechWas .. " -> 3")
    if not S.v.knewRecipe then
        local mag = C2.give("Base.MechanicMag1")
        if mag then ISTimedActionQueue.add(ISReadABook:new(S.v.p, mag, 150)) end
    end
end, function(why) S.v.carWhy = why end)

-- ===================================================================== 50 The Vehicle Tab
S.waitFor(30, 3600, function()
    if not S.v.car then return true end
    local k = false; pcall(function() k = S.v.p:isRecipeActuallyKnown("Basic Mechanics") end)
    return k and not ISTimedActionQueue.isPlayerDoingAction(S.v.p)
end, function()
    if not S.v.car then return end
    local k = false; pcall(function() k = S.v.p:isRecipeActuallyKnown("Basic Mechanics") end)
    S.say("Basic Mechanics known: " .. tostring(k))
end)
S.step(30, function()
    if not S.v.car then return end
    local tire = S.v.car:getPartById("TireFrontLeft")
    if tire then pcall(function() tire:setInventoryItem(nil); S.v.car:transmitPartItem(tire) end) end
    S.say("front left tire off: " .. tostring(tire and tire:getInventoryItem() == nil))
    C2.pairOpen()
end)
S.step(60, function() if S.v.car and S.v.MT then ISVehicleMenu.onMechanic(S.v.p, S.v.car) end end)
S.waitFor(30, 3600, function()
    if not (S.v.car and S.v.MT) then return true end
    local w = C2.ww()
    return S.v.MT.isInspected(S.v.car) and w ~= nil and w._activeTab == "vehicle"
end, function(ok)
    if S.v.car and S.v.MT and not ok then S.v.vtWhy = "the Vehicle tab did not come up" end
    if not (S.v.car and S.v.MT) then S.v.vtWhy = S.v.carWhy or "no car or no Vehicle tab" end
end)
C2.ready(S)
-- the hover: the first row in view, under the real pointer
S.step(10, function()
    if S.v.vtWhy then return end
    local s, w = S.v.S(), C2.ww()
    local z = nil
    for _, r in ipairs(s and s.lastRows or {}) do
        local c, cy = r.clip, r.y + math.floor(r.h / 2)
        if not z and (not c or (cy >= c.y and cy < c.y + c.h)) then z = r end
    end
    if not (z and w and s.panel) then S.v.hovWhy = "no row in view"; return end
    S.v.hovered = z.part
    C2.pointerOn()
    S.v.hx = math.floor(s.panel:getAbsoluteX() + z.x + 20)
    S.v.hy = math.floor(s.panel:getAbsoluteY() + z.y + z.h / 2)
    pcall(function() local fw = getFileWriter("zedqa_click_done.txt", true, false); fw:write(""); fw:close() end)
    pcall(function() local f = getFileWriter("zedqa_click.txt", true, false); f:write("move " .. S.v.hx .. " " .. S.v.hy); f:close() end)
    S.say("hover: the real pointer to " .. S.v.hx .. "," .. S.v.hy .. " on the row " .. tostring(z.part))
end)
S.waitFor(10, 600, function()
    if S.v.vtWhy or S.v.hovWhy then return true end
    local l = nil
    pcall(function() local r = getFileReader("zedqa_click_done.txt", false); l = r and r:readLine(); if r then r:close() end end)
    return l ~= nil and l:find("done", 1, true) ~= nil
end, function(ok) if not ok and not (S.v.vtWhy or S.v.hovWhy) then S.say("note: the real-mouse helper did not answer (run with release_check.ps1)") end end)
S.step(30, function()
    if S.v.vtWhy or S.v.hovWhy then S.notTaken(S.v.N1, S.v.vtWhy or S.v.hovWhy); C2.pointerOff(); return end
    local s = S.v.S()
    S.say("hover: lit " .. tostring(s and s.hl) .. " (wanted " .. tostring(S.v.hovered) .. "), card " .. tostring(s and s.card))
    if not (s and s.hl ~= nil and s.hl == S.v.hovered) then S.notTaken(S.v.N1, "the hovered row's part is not lit"); C2.pointerOff(); return end
    C2.shot(S, S.v.N1, { pointer = true })
end)
-- the brake's card: Mechanics 4 (as the beta 2 picture), the rear left brake, its step before
S.step(10, function()
    C2.pointerOff()
    C2.hidePointer()
    if S.v.vtWhy then return end
    S.v.p:setPerkLevelDebug(Perks.Mechanics, 4)
    S.v.press(S.v.zone("mech:row:BrakeRearLeft"))
end)
S.step(30, function() end)
C2.ready(S)
S.step(5, function()
    if S.v.vtWhy then S.notTaken(S.v.N2, S.v.vtWhy); return end
    local s = S.v.S()
    if not (s and s.card == "BrakeRearLeft" and S.v.zone("mech:step")) then S.notTaken(S.v.N2, "the brake's card or its step before is not up (card " .. tostring(s and s.card) .. ")"); return end
    C2.shot(S, S.v.N2)
end)
S.step(10, function() if not S.v.vtWhy then local s = S.v.S(); if s and s.card then S.v.press(S.v.zone("mech:row:" .. s.card)) end end end)

-- ===================================================================== 54 The Car Radio (gallery_b19_b.lua)
S.step(20, function()
    if not S.v.car then return end
    C2.pairShut()
    pcall(function() ZeD.Settings.dashStyleOption:setValue(1) end)
    pcall(function() ZEDQA_CAR_PREP(S.v.car) end)   -- (repaired, tank and battery full; its key is already given)
end)
S.waitMs(1500)
S.step(5, function()
    if not S.v.car then S.v.crWhy = S.v.carWhy or "no car"; return end
    C2.tp(S.v.car:getX() + 2.5, S.v.car:getY() + 0.5, 0)
end)
S.step(30, function()
    if S.v.crWhy then return end
    local ok, why = ZEDQA_CAR_ENTER(S.v.car, 0)
    if not ok then S.v.crWhy = "not entered: " .. tostring(why); return end
    S.v.inside = true
end)
S.step(20, function() if S.v.inside then pcall(function() S.v.car:setKeysInIgnition(true) end); S.v.eng = { t = 0, tries = 0 } end end)
S.waitFor(10, 1500, function()
    if not S.v.inside then return true end
    S.v.eng.t = S.v.eng.t + 1
    local run = false
    pcall(function() run = S.v.car:isEngineRunning() end)
    if run then return true end
    local q = ISTimedActionQueue.getTimedActionQueue(S.v.p)
    if not (q and q.queue and #q.queue > 0) and S.v.eng.t % 120 == 1 and S.v.eng.tries < 5 then
        S.v.eng.tries = S.v.eng.tries + 1
        pcall(function() ISVehicleMenu.onStartEngine(S.v.p) end)
    end
    return false
end, function() if S.v.inside then local r = false; pcall(function() r = S.v.car:isEngineRunning() end); S.say("engine running " .. tostring(r)) end end)
S.step(20, function()
    local d = ZeD.Dashboard and ZeD.Dashboard.getInstance()
    if S.v.inside and d and d._st then
        if not d._st.lights then pcall(function() d:_fire("lights", false) end) end
    end
end)
S.step(30, function()
    if not S.v.inside then return end
    local v = S.v.car
    local part = v:getPartById("Radio")
    if not part then S.v.crWhy = "the sedan has no Radio part"; return end
    S.v.part = part
    local ok, e = pcall(function()
        part:setInventoryItem(instanceItem("Base.RadioRed"))
        Vehicles.InstallComplete.Radio(v, part)
        local dd = part:getDeviceData()
        if dd and dd:getDevicePresets():getPresets():size() == 0 then dd:generatePresets() end
    end)
    if not ok then S.v.crWhy = "could not fit the CD receiver: " .. tostring(e) end
end)
S.step(60, function()
    if not S.v.inside or S.v.crWhy then return end
    local d = ZeD.Dashboard and ZeD.Dashboard.getInstance()
    if d and d._st and not d._st.radioOn then pcall(function() d:_fire("pwr", false) end) end
    pcall(function() ZeD.RadioOps.setChannel(S.v.p, S.v.part, 101200) end)
    pcall(function() ZeD.RadioOps.run("SetVolume", S.v.p, S.v.part, 0.6) end)
end)
S.step(90, function() if S.v.inside and not S.v.crWhy then pcall(function() ISVehicleMenu.onSignalDevice(S.v.p, S.v.part) end) end end)
S.step(30, function()
    if not S.v.inside or S.v.crWhy then return end
    local CR = ZeD.CarRadio
    local pr = CR and CR.props and CR.props[S.v.pn]
    if pr and pr:isReallyVisible() then
        S.v.prop = pr
        if C2.coversEl(pr) then C2.top(S, pr, "the car radio") end
    end
end)
S.step(30, function()
    if not S.v.inside then S.notTaken("g5_car_radio", S.v.crWhy or "not in the car"); return end
    if S.v.crWhy then S.notTaken("g5_car_radio", S.v.crWhy); return end
    if not (S.v.prop and S.v.prop:isReallyVisible()) then S.notTaken("g5_car_radio", "the car radio did not come up"); return end
    local d = ZeD.Dashboard and ZeD.Dashboard.getInstance()
    C2.shot(S, "g5_car_radio", { extra = { { "car radio", S.v.prop }, { "dash", d } } })
end)
S.step(10, function()
    pcall(function() ZeD.CarRadio.closeFor(S.v.pn) end)
    local d = ZeD.Dashboard and ZeD.Dashboard.getInstance()
    if S.v.inside and d and d._st and d._st.radioOn then pcall(function() d:_fire("pwr", false) end) end
    pcall(function() if S.v.car and S.v.car:isEngineRunning() then S.v.car:shutOff() end end)
end)

-- ===================================================================== put back
S.mark()
S.step(30, function()
    pcall(function() ZeD.CarRadio.closeFor(S.v.pn) end)
    C2.pointerOff()
    if S.v.car or C2.car then
        local v = S.v.car or C2.car
        pcall(function() if v:isEngineRunning() then v:shutOff() end end)
        if ZEDQA_CAR_AWAY then ZEDQA_CAR_AWAY(v, nil) else pcall(function() v:permanentlyRemove() end) end
        S.v.car, C2.car = nil, nil
    end
    pcall(function() S.v.p:setPerkLevelDebug(Perks.Mechanics, S.v.mechWas) end)
    if S.v.knewRecipe == false then pcall(function() S.v.p:getKnownRecipes():remove("Basic Mechanics") end) end
    if S.v.readWas == false then pcall(function() local rb = S.v.p:getAlreadyReadBook(); while rb:contains("Base.MechanicMag1") do rb:remove("Base.MechanicMag1") end end) end
    if S.v.dashWas then pcall(function() ZeD.Settings.dashStyleOption:setValue(S.v.dashWas) end) end
    local kn = false; pcall(function() kn = S.v.p:isRecipeActuallyKnown("Basic Mechanics") end)
    S.say("car taken away; Mechanics " .. tostring(S.v.p:getPerkLevel(Perks.Mechanics)) .. "; Basic Mechanics known " .. tostring(kn))
end)
S.step(30, function() C2.back(S) end)
S.step(30, function() end)
S.start()
