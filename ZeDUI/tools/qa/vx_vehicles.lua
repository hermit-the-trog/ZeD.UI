-- ZeDUI/tools/qa/vx_vehicles.lua  (Nov 21 2026, QA): the in-game proof of Build's fixes for the beast code sweep's
-- car findings W20, W21 and W22 (ZeDUI/qa/audits/2026-11-21_beast_code_sweep.md; the fix is commit a4fc05567).
-- Built on rt_kit.lua (run it first) and the prelude's car helpers (zedqa_prelude.lua). grep "ZEDQA vx_veh".
--
-- One police car (Base.CarLightsPolice) on the drag strip, repaired, fuelled, its key in the bag, the character in
-- the driver's seat. The car never moves. Then:
--   W22  a modded car's name with a service word inside it ("92fordRanger", "87pontiacFirebird", "86dodgeRockstar")
--        gets a civilian dash and no fleet unit line; a word that is only part of a longer word after a game car's
--        name ("VanFirebird") is no livery either; the hospitality van is a van; the game's own service cars keep
--        their dashes. Asked of the dash's own picker, then shown on the dash itself: the car under the character is
--        given the modded name for a moment and the dash on screen is read, then the name is put back.
--        The old code: ranger, fire, police, taxi and ambulance dashes for those names, and "RANGER - UNIT nn".
--   W21  the seat pop-out: a press on its bare floor starts a drag (it takes the mouse), Esc closes it with the button
--        still held. It must let go of the mouse; opened again, a click on the ground 300 px away (the pointer then
--        moving 40 px before the button comes up) must close it and must not write its saved place. The old code: the
--        pop-out kept the mouse, so that click went to the pop-out, it stayed open, began a new drag from that far
--        point and the 40 px move saved a new place on the character.
--        (Esc goes through ZeD's Escape route, Seats.takeEscape, which ends in the same close(). The pop-out's own
--        onKeyPress also calls GameKeyboard.eatKeyPress: with no real key down that would swallow the next real Esc.)
--   W20  the ignition: with the key in and the engine off a right click, and then the pad's X, each take the key out
--        (controls: both verbs work in this run). The key goes back in, a click starts the engine, and WHILE THE
--        STARTER TURNS a right click on the ignition and the pad's X must both leave the key in; once it runs, the key
--        is still in the lock. The old code: the key came out mid-crank and the engine ran with an empty lock (a key
--        the right click pulled is put back so X meets a key; a key X pulls stays out, the finding's own picture).
-- None of the three is a speed fix, so nothing is counted over frames here.
-- Put back: the car's name, the pop-out closed and its saved place as found, the engine off, the Style, god mode and
-- invincible as found, the character out, the key taken back, the car removed. Nothing here can hurt the character;
-- god mode and invincible are on all the same while the car is there. No file is written.

if not RT then
    print("ZEDQA vx_veh ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA vx_veh VERDICT FAIL 1")
    print("ZEDQA vx_veh DONE")
    return
end

local Q = RT.make("vx_veh")
Q.maxMs = 300000   -- (5 minutes, then the put-back; the manifest's timeout is 420 s)
local S = {}
local H = {}
S.p, S.pn = RT.p, RT.pn
S.D = ZeD and ZeD.Dashboard
S.Seats = ZeD and ZeD.Seats
S.FAKE1 = "Base.92fordRanger"
S.FAKE2 = "Base.87pontiacFirebird"

-- ===================================================================== helpers
function H.inCar() return S.v ~= nil and S.p:getVehicle() == S.v end
function H.dash() local d = nil; pcall(function() d = S.D.getInstance(S.pn) end); return d end
function H.st() local d = H.dash(); return d and d._st end
function H.vis(o)
    local v = false
    if o then pcall(function() v = o:isReallyVisible() end) end
    return v and true or false
end
function H.keysIn() local k = false; pcall(function() k = S.v:isKeysInIgnition() end); return k and true or false end
function H.running() local k = false; pcall(function() k = S.v:isEngineRunning() end); return k and true or false end
function H.started() local k = false; pcall(function() k = S.v:isEngineStarted() end); return k and true or false end
function H.engState() local s = "?"; pcall(function() s = tostring(S.v:getEngineState()) end); return s end
function H.hitOf(d, id)
    for _, h in ipairs((d and d._hit) or {}) do if h.id == id then return h end end
    return nil
end
-- a left click on the dash's ignition (its hit), else fired as the click does (said so)
function H.ignition()
    local d = H.dash()
    if not d then return false end
    local h = H.hitOf(d, "ignition")
    if h then
        local ok = pcall(function() d:onMouseDown(h.x + math.floor(h.w / 2), h.y + math.floor(h.h / 2)) end)
        return ok
    end
    Q.say("NOTE the dash has no ignition hit this frame: fired as its click does")
    pcall(function() d:_fire("ignition", false) end)
    return true
end
-- a right click on the dash's ignition (its hit, the dash's own right-click handler). "hit": the handler took it,
-- "miss": no control under the point, "fired": no hit this frame, so fired as the right click does
function H.rightIgnition()
    local d = H.dash()
    if not d then return "no dash" end
    local h = H.hitOf(d, "ignition")
    if h then
        local took = false
        pcall(function() took = d:onRightMouseDown(h.x + math.floor(h.w / 2), h.y + math.floor(h.h / 2)) end)
        return took and "hit" or "miss"
    end
    pcall(function() d:_fire("ignition", true) end)
    return "fired"
end
-- the pad's X on the ignition: the focus element's own context verb (what FocusManager calls for X)
function H.padXIgnition()
    local d = H.dash()
    if not d then return "no dash" end
    for _, el in ipairs(d._elements or {}) do
        if el.id == "dash:ignition" then
            local ok = pcall(function() el.onContextMenu(d, el) end)
            return ok and "pressed" or "error"
        end
    end
    return "no element"
end
function H.popout() local w = nil; pcall(function() w = S.Seats.getPopout(S.pn) end); return w end
function H.chooser() local w = nil; pcall(function() w = S.Seats.get(S.pn) end); return w end
function H.captured(p)
    local c = nil
    pcall(function() c = p:isCapture() end)
    return c and true or false
end
function H.savedPlace()
    local s = nil
    pcall(function() s = S.p:getModData().ZeD_SeatPopout end)
    if type(s) == "table" then return string.format("%.1f,%.1f", tonumber(s.x) or -1, tonumber(s.y) or -1) end
    return "none"
end
function H.placeObj()
    local s = nil
    pcall(function() s = S.p:getModData().ZeD_SeatPopout end)
    return s
end
-- fn run with the pointer the game reads at x, y (screen px): Mouse.setXY does not move it, so getMouseX and
-- getMouseY are swapped for the call and put back at once (zedqa_pagelist_lib.lua S.wheelAt)
function H.atPointer(x, y, fn)
    local gx, gy = getMouseX, getMouseY
    getMouseX = function() return x end
    getMouseY = function() return y end
    local ok, err = pcall(fn)
    getMouseX, getMouseY = gx, gy
    if not ok then Q.say("NOTE a pop-out handler threw: " .. tostring(err)) end
    return ok
end
-- a point of the pop-out with no seat and no door cell under it (bare floor: a press there drags)
function H.barePoint(p)
    local w, h = p:getWidth(), p:getHeight()
    local y = 2
    while y < h - 1 do
        local x = 2
        while x < w - 1 do
            local hit = "?"
            pcall(function() hit = p:hitAt(x, y) end)
            if hit == nil then return x, y end
            x = x + 6
        end
        y = y + 6
    end
    return nil
end
function H.setStyleFull()
    local o = ZeD.Settings and ZeD.Settings.lookStyleOption
    if not o then return end
    if S.styleWas == nil then pcall(function() S.styleWas = o:getValue() end) end
    pcall(function() o:setValue(1) end)
end
function H.putStyle()
    local o = ZeD.Settings and ZeD.Settings.lookStyleOption
    if o and S.styleWas ~= nil then pcall(function() o:setValue(S.styleWas) end) end
    S.styleWas = nil
end
function H.lite()
    local l = false
    pcall(function() l = ZeD.Settings.lite() end)
    return l and true or false
end
function H.designId(name)
    local id, own = "?", nil
    local ok, err = pcall(function()
        local _, i, o = S.D._designFor(name)
        id, own = i, o
    end)
    if not ok then id = "error: " .. tostring(err) end
    return tostring(id), own
end
-- the badge lines the dash would paint for a car of this script name (a stand-in car object: it has no name of its
-- own in the game's tables, as a modded car without a translation, so the script name is read)
function H.badge(name)
    local b = nil
    local ok, err = pcall(function()
        local des, _, own = S.D._designFor(name)
        b = S.D._badges(des, {}, name, own)
    end)
    if not ok then Q.say("NOTE the badge lines for " .. tostring(name) .. " could not be read: " .. tostring(err)) end
    return b
end
function H.scriptName()
    local n = nil
    pcall(function() n = S.v:getScriptName() end)
    return n
end
function H.rename(name)
    local ok = pcall(function() S.v:setScriptName(name) end)
    return ok and H.scriptName() == name
end
function H.dashKeyName()
    local d = H.dash()
    return d and d._badgeKey and d._badgeKey.s or nil
end

-- ===================================================================== the car
Q.step(2, function()
    if not (S.D and S.Seats and S.D._designFor and S.D._badges) then
        S.failWhy = "ZeD's dash or seats are not loaded"
        return
    end
    if getGameSpeed() ~= 1 then pcall(ZEDQA_SPEED or setGameSpeed, 1) end
    if not (ZEDQA_CAR_WAIT and ZEDQA_CAR_PREP and ZEDQA_CAR_ENTER and ZEDQA_CAR_AWAY) then
        S.failWhy = "the prelude's car helpers are not loaded (zedqa_prelude.lua runs first)"
        return
    end
    -- (nothing here can hurt him, the car never moves; on all the same while the car is there)
    pcall(function() S.godWas = S.p:isGodMod() end)
    pcall(function() S.invWas = S.p:isInvincible() end)
    pcall(function() S.p:setGodMod(true) end)
    pcall(function() S.p:setInvincible(true) end)
    S.placeWas = nil
    pcall(function() S.placeWas = S.p:getModData().ZeD_SeatPopout end)
    S.placeWasText = H.savedPlace()
    S.placeRead = true
    H.setStyleFull()
    ZEDQA_CAR_WAIT("Base.CarLightsPolice", "vx_veh", function(v)
        S.v = v
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
Q.waitFor(10, 300, function() return not H.inCar() or (H.vis(H.dash()) and H.st() ~= nil) end, function(ok)
    if not H.inCar() then return end
    S.dashUp = Q.check(ok and H.vis(H.dash()), "ZeD's dash shows in the car", tostring(H.dash() and H.dash()._designId))
end)

-- ===================================================================== W22: a service word inside a modded name
Q.step(5, function()
    if not (S.D and S.D._designFor) then
        Q.check(false, "W22: the dash's picker can be asked", "ZeD.Dashboard._designFor is missing")
        return
    end
    if H.lite() then
        -- (Lite gives every car the one dash, so the picker would say nothing about names)
        Q.skip("W22: a modded car's name gets a civilian dash", "the Style could not be set to Full, and Lite gives every car one dash")
        S.noW22 = true
        return
    end
    -- modded names (no game car's name in front): a civilian dash, not the game's own family
    local modded = {
        { "Base.92fordRanger", "ranger" }, { "Base.87pontiacFirebird", "fire" }, { "Base.Spitfire", "fire" },
        { "Base.chryslerCrossfire", "fire" }, { "Base.86dodgeRockstar", "police" }, { "Base.85mercTaxicab", "taxi" },
        { "Base.90bmwRacer", "race" }, { "Base.hospitalShuttle", "ambulance" },
    }
    local bad, seen = {}, {}
    for _, m in ipairs(modded) do
        local id, own = H.designId(m[1])
        seen[#seen + 1] = m[1] .. " -> " .. id
        if id ~= "nyala" or own ~= false then bad[#bad + 1] = m[1] .. " -> " .. id .. (own and " (as the game's own car)" or "") end
    end
    Q.check(#bad == 0, "W22: a modded car whose name only contains fire, ranger, race, taxi, hosp or kst gets the civilian dash (old: the service dash)",
        (#bad == 0) and table.concat(seen, "; ") or ("wrong: " .. table.concat(bad, "; ")))
    -- a game car's name in front, the service word only part of a longer word: the family's own dash
    local part = { { "Base.VanFirebird", "van" }, { "Base.SUVSpitfire", "suv" }, { "Base.StepVan_SouthEasternHosp", "van" } }
    bad, seen = {}, {}
    for _, m in ipairs(part) do
        local id = H.designId(m[1])
        seen[#seen + 1] = m[1] .. " -> " .. id
        if id ~= m[2] then bad[#bad + 1] = m[1] .. " -> " .. id .. " (want " .. m[2] .. ")" end
    end
    Q.check(#bad == 0, "W22: a service word that is only part of a longer word is no livery, and the hospitality van is a van (old: fire, fire, ambulance)",
        (#bad == 0) and table.concat(seen, "; ") or ("wrong: " .. table.concat(bad, "; ")))
    -- the game's own service cars keep their dashes (the fix must not take them away)
    local own = {
        { "Base.CarLightsPolice", "police" }, { "Base.CarLightsRanger", "ranger" }, { "Base.PickUpTruckLightsRanger", "ranger" },
        { "Base.PickUpTruckLightsFire", "fire" }, { "Base.PickUpVanLightsFire", "fire" }, { "Base.CarTaxi", "taxi" },
        { "Base.CarTaxi2", "taxi" }, { "Base.VanAmbulance", "ambulance" }, { "Base.CarLightsKST", "police" },
        { "Base.CarLightsBulletinSheriff", "police" }, { "Base.CarLightsLouisvilleCounty", "police" },
        { "Base.CarLightsMuldraughPolice", "police" }, { "Base.ModernCarLightsCityLouisvillePD", "police" },
        { "Base.ModernCarLightsMeadeSheriff", "police" }, { "Base.ModernCarLightsWestPoint", "police" },
        { "Base.PickUpVanLightsLouisvilleCounty", "police" }, { "Base.PickUpVanLightsPolice", "police" },
        { "Base.PickUpVanLightsRanger", "ranger" }, { "Base.PickUpVanLightsStatePolice", "police" },
        { "Base.StepVan_LouisvilleSWAT", "police" }, { "Base.AmbulanceBurnt", "ambulance" },
        { "Base.NormalCarBurntPolice", "police" }, { "Base.TaxiBurnt", "taxi" }, { "Base.RaceCar12", "race" },
        { "Base.RaceCar34", "race" }, { "Base.RaceCar58", "race" }, { "Base.RaceCarBurnt", "race" },
    }
    bad = {}
    for _, m in ipairs(own) do
        local id = H.designId(m[1])
        if id ~= m[2] then bad[#bad + 1] = m[1] .. " -> " .. id .. " (want " .. m[2] .. ")" end
    end
    Q.check(#bad == 0, "W22: the game's own police, ranger, fire, taxi, ambulance and race cars keep their dashes",
        (#bad == 0) and (#own .. " names right") or ("wrong: " .. table.concat(bad, "; ")))
    -- (said, not counted: the name rule alone also gives a modded car that IS a service car, lightbar and all, the
    -- civilian dash, whose plate has no lightbar or siren keys; the audit's other hint, the lightbar, would keep it)
    Q.say("NOTE not counted: a modded police cruiser's name (Base.87chevyCapricePolice) gets the " .. H.designId("Base.87chevyCapricePolice")
        .. " dash (only the police, fire, ranger and ambulance plates carry lightbar and siren keys)")
    -- the fleet unit line
    local b = H.badge("Base.92fordRanger")
    local unit = tostring(b and b.unit)
    Q.check(b ~= nil and not unit:find("RANGER", 1, true), "W22: a modded Ford Ranger gets no RANGER unit line (old: RANGER - UNIT nn)",
        "unit line " .. unit .. ", livery '" .. tostring(b and b.livery) .. "', badge " .. tostring(b and b.full))
    b = H.badge("Base.VanFirebird")
    unit = tostring(b and b.unit)
    Q.check(b ~= nil and not unit:find("FIRE", 1, true), "W22: a van called Firebird gets no FIRE engine line (old: FIRE - ENGINE nn)", "unit line " .. unit)
    b = H.badge("Base.PickUpVanLightsFire")
    unit = tostring(b and b.unit)
    Q.check(b ~= nil and unit:find("FIRE", 1, true) ~= nil, "W22: the game's fire truck keeps its FIRE unit line", "unit line " .. unit)
    b = H.badge("Base.CarLightsRanger")
    unit = tostring(b and b.unit)
    Q.check(b ~= nil and unit:find("RANGER", 1, true) ~= nil, "W22: the game's ranger car keeps its RANGER unit line", "unit line " .. unit)
end)
-- the dash on screen: the car under the character carries a modded name for a moment
Q.step(5, function()
    if S.noW22 or not (H.inCar() and S.dashUp) then
        if not S.noW22 then Q.skip("W22: the dash on screen for a modded name", "no car or no dash") end
        S.noLive = true
        return
    end
    S.nameWas = H.scriptName()
    S.designWas = H.dash() and H.dash()._designId
    if not (S.nameWas and H.rename(S.FAKE1)) then
        Q.skip("W22: the dash on screen for a modded name", "the car's script name could not be changed")
        pcall(function() if S.nameWas then S.v:setScriptName(S.nameWas) end end)
        S.noLive = true
        return
    end
    S.renamed = true
end)
Q.waitFor(2, 240, function() return S.noLive or H.dashKeyName() == S.FAKE1 end, function(ok)
    if S.noLive then return end
    local d = H.dash()
    local id = tostring(d and d._designId)
    Q.check(ok and id == "nyala", "W22: the dash on screen for a car named 92fordRanger is the civilian one (old: the park ranger's)",
        "dash " .. id .. " (the police car's own was " .. tostring(S.designWas) .. ")")
    local pd = "?"
    pcall(function() pd = tostring((S.Seats.cabinPick(S.v))) end)
    Q.check(pd == "nyala", "W22: the seat pop-out's cabin for it is the civilian one (old: the ranger's)", "cabin of " .. pd)
    if not H.rename(S.FAKE2) then S.noLive2 = true end
end)
Q.waitFor(2, 240, function() return S.noLive or S.noLive2 or H.dashKeyName() == S.FAKE2 end, function(ok)
    if S.noLive then return end
    if not S.noLive2 then
        local d = H.dash()
        local id = tostring(d and d._designId)
        Q.check(ok and id == "nyala", "W22: the dash on screen for a car named 87pontiacFirebird is the civilian one (old: the fire engine's)", "dash " .. id)
    end
    pcall(function() S.v:setScriptName(S.nameWas) end)
    S.renamed = H.scriptName() ~= S.nameWas
end)
Q.waitFor(2, 240, function() return S.noLive or H.dashKeyName() == S.nameWas end, function(ok)
    if S.noLive then return end
    local d = H.dash()
    Q.check(ok and H.scriptName() == S.nameWas and d ~= nil and d._designId == S.designWas,
        "W22: the car's own name back, the police dash is back", "name " .. tostring(H.scriptName()) .. ", dash " .. tostring(d and d._designId))
end)

-- ===================================================================== W21: the seat pop-out closed mid-drag
Q.step(5, function()
    if not H.inCar() then Q.skip("W21: the seat pop-out closed mid-drag", "no car"); S.noPop = true; return end
    if getGameSpeed() ~= 1 then pcall(ZEDQA_SPEED or setGameSpeed, 1) end
    pcall(function() local w = H.popout(); if H.vis(w) then w:close() end end)
    pcall(ISVehicleMenu.onShowSeatUI, S.p, S.v)
end)
Q.waitFor(5, 300, function()
    local p = H.popout()
    return S.noPop or (H.vis(p) and p._g ~= nil) or H.vis(H.chooser())
end, function(ok)
    if S.noPop then return end
    local p = H.popout()
    if not (H.vis(p) and p._g ~= nil) then
        pcall(function() local w = H.chooser(); if H.vis(w) then w:close() end end)
        Q.check(false, "W21: the seat key opens the cabin pop-out for the police car", "pop-out " .. tostring(H.vis(p)) .. ", chooser " .. tostring(H.vis(H.chooser())))
        S.noPop = true
        return
    end
    S.pop = p
    local bx, by = H.barePoint(p)
    if not bx then
        Q.check(false, "W21: the pop-out has bare floor to press on", p:getWidth() .. "x" .. p:getHeight())
        S.noPop = true
        return
    end
    local capBefore = H.captured(p)
    -- the press on the bare floor (the pop-out's own mouse handler, as the press reaches it): a drag begins
    pcall(function() p:onMouseDown(bx, by) end)
    S.dragOn = p._drag ~= nil and H.captured(p)
    Q.check(S.dragOn and not capBefore, "W21: a press on the pop-out's bare floor starts a drag and takes the mouse",
        "at " .. bx .. "," .. by .. ": drag " .. tostring(p._drag ~= nil) .. ", holds the mouse " .. tostring(H.captured(p)) .. " (before " .. tostring(capBefore) .. ")")
    -- Esc with the button still held: ZeD's Escape route (the game's Esc handler asks ZeD.EscapeTakers: Seats.takeEscape,
    -- the pop-out's close()). (Not the pop-out's own onKeyPress: it also calls GameKeyboard.eatKeyPress, and with no
    -- real key down that flag would swallow the next real Esc of this session. Both routes end in the same close().)
    local took = false
    pcall(function() took = S.Seats.takeEscape() and true or false end)
    S.escHow = "ZeD's Escape route (Seats.takeEscape)"
    if not took then
        pcall(function() p:close() end)
        S.escHow = "close() (no Escape taker took it)"
    end
end)
Q.step(3, function()
    if S.noPop then return end
    local p = S.pop
    Q.check(not H.vis(p), "W21: Esc closes the pop-out mid-drag", "through " .. tostring(S.escHow) .. "; visible " .. tostring(H.vis(p)))
    Q.check(not H.captured(p), "W21: closed mid-drag, the pop-out lets go of the mouse (old: it kept it)", "holds the mouse " .. tostring(H.captured(p)))
    pcall(function() if H.vis(p) then p:close() end end)
    pcall(ISVehicleMenu.onShowSeatUI, S.p, S.v)
end)
Q.waitFor(5, 300, function()
    local p = H.popout()
    return S.noPop or (H.vis(p) and p._g ~= nil)
end, function(ok)
    if S.noPop then return end
    local p = H.popout()
    if not Q.check(ok and H.vis(p), "W21: the seat key opens the pop-out again") then S.noPop = true; return end
    S.pop = p
    local cap = H.captured(p)
    Q.check(not cap, "W21: opened again, the pop-out does not hold the mouse (old: it still did)", "holds the mouse " .. tostring(cap))
    -- a click on the ground 300 px beside it, the pointer moving 40 px before the button comes up, delivered the way
    -- the game's UIManager does (zombie.ui.UIManager: isOverElement counts a panel that holds the mouse as under the
    -- pointer): the press goes to the pop-out's onMouseDown if it holds the mouse, else it hears onMouseDownOutside;
    -- the move to onMouseMove if it holds the mouse, else onMouseMoveOutside (the pop-out's is the same function); the
    -- release to onMouseUp if it holds the mouse, else onMouseUpOutside. A closed pop-out is out of the UI and hears
    -- nothing. The pointer the handlers read (getMouseX / getMouseY) is the click's, swapped for each call.
    local sx = p:getX() - 300
    if sx < 10 then sx = p:getX() + p:getWidth() + 300 end
    local sy = p:getY() + math.floor(p:getHeight() / 2)
    local lx, ly = sx - p:getX(), sy - p:getY()
    S.placeBefore = H.placeObj()
    S.placeBeforeText = H.savedPlace()
    S.clickAs = cap and "the pop-out's own press (it holds the mouse)" or "a press outside"
    H.atPointer(sx, sy, function()
        if cap then p:onMouseDown(lx, ly) else p:onMouseDownOutside(lx, ly) end
    end)
    S.dragFar = p._drag ~= nil
    if H.vis(p) then
        H.atPointer(sx + 40, sy, function()
            if H.captured(p) then p:onMouseMove(40, 0) else p:onMouseMoveOutside(40, 0) end
        end)
        H.atPointer(sx + 40, sy, function()
            if H.captured(p) then p:onMouseUp(lx + 40, ly) else p:onMouseUpOutside(lx + 40, ly) end
        end)
    end
    S.clickAt = math.floor(sx) .. "," .. math.floor(sy)
end)
Q.step(3, function()
    if S.noPop then return end
    local p = S.pop
    Q.check(not H.vis(p), "W21: a click on the ground 300 px away closes the pop-out (old: it stayed and began a drag from there)",
        "click at " .. tostring(S.clickAt) .. " reached it as " .. tostring(S.clickAs) .. "; visible " .. tostring(H.vis(p)) .. ", a drag began " .. tostring(S.dragFar))
    Q.check(H.placeObj() == S.placeBefore, "W21: that click and the 40 px move do not write the pop-out's saved place (old: a new place was saved on the character)",
        "saved place " .. H.savedPlace() .. " (before the click " .. tostring(S.placeBeforeText) .. ", at the start " .. tostring(S.placeWasText) .. ")")
    pcall(function() p:setCapture(false) end)
    pcall(function() if H.vis(p) then p:close() end end)
end)

-- ===================================================================== W20: the key while the starter turns
Q.step(5, function()
    if not (H.inCar() and S.dashUp) then Q.skip("W20: the key stays in while the starter turns", "no car or no dash"); S.noIgn = true; return end
    if getGameSpeed() ~= 1 then pcall(ZEDQA_SPEED or setGameSpeed, 1) end
    if not H.keysIn() then H.ignition() end
end)
Q.waitFor(3, 300, function() local s = H.st(); return S.noIgn or (H.keysIn() and s ~= nil and s.keysIn == true) end, function(ok)
    if S.noIgn then return end
    if not Q.check(ok, "W20: a click on the ignition puts the key in", "key in " .. tostring(H.keysIn())) then S.noIgn = true; return end
    -- the control: engine off, a right click takes the key out (so the right click is live in this run)
    S.ctlHow = H.rightIgnition()
end)
Q.waitFor(3, 300, function() local s = H.st(); return S.noIgn or (not H.keysIn() and s ~= nil and s.keysIn == false) end, function(ok)
    if S.noIgn then return end
    S.rightLive = Q.check(ok, "W20: engine off, a right click on the ignition takes the key out (the right click works)",
        "right click " .. tostring(S.ctlHow) .. ", key in " .. tostring(H.keysIn()))
    if H.keysIn() then return end
    H.ignition()
end)
Q.waitFor(3, 300, function() local s = H.st(); return S.noIgn or (H.keysIn() and s ~= nil and s.keysIn == true) end, function(ok)
    if S.noIgn then return end
    if not Q.check(ok, "W20: a click puts the key back in", "key in " .. tostring(H.keysIn())) then S.noIgn = true; return end
    -- the second control: engine off, the pad's X on the ignition takes the key out (so X is live in this run and the
    -- crank check below cannot pass on a dead X)
    S.ctlPad = H.padXIgnition()
end)
Q.waitFor(3, 300, function() local s = H.st(); return S.noIgn or (not H.keysIn() and s ~= nil and s.keysIn == false) end, function(ok)
    if S.noIgn then return end
    S.padLive = Q.check(ok, "W20: engine off, the pad's X on the ignition takes the key out (X works)",
        "X " .. tostring(S.ctlPad) .. ", key in " .. tostring(H.keysIn()))
    if H.keysIn() then return end
    H.ignition()
end)
Q.waitFor(3, 300, function() local s = H.st(); return S.noIgn or (H.keysIn() and s ~= nil and s.keysIn == true) end, function(ok)
    if S.noIgn then return end
    if not Q.check(ok, "W20: a click puts the key back in again", "key in " .. tostring(H.keysIn())) then S.noIgn = true end
end)
Q.waitMs(400)
Q.step(1, function()
    if S.noIgn then return end
    S.t0 = getTimestampMs(); S.tries = 0
    H.ignition()   -- (key in, engine off: the game's own start)
end)
Q.waitFor(1, 3000, function()
    if S.noIgn or not H.inCar() then return true end
    local s = H.st()
    -- the starter turning, as the dash last read it and as the car says now: the right click and the pad's X, here
    if not S.crank and s and s.started and not s.running and H.started() and not H.running() then
        S.crank = { state = H.engState(), keyBefore = H.keysIn() }
        S.crank.how = H.rightIgnition()
        S.crank.keyAfterRight = H.keysIn()
        -- (the old code pulled it: put back, so the pad's X below meets a key in the lock)
        if S.crank.keyBefore and not S.crank.keyAfterRight then pcall(function() S.v:setKeysInIgnition(true) end) end
        S.crank.keyBeforePad = H.keysIn()
        S.crank.pad = H.padXIgnition()
        S.crank.keyAfterPad = H.keysIn()
        -- (a key X pulls stays out: the engine catches all the same, and 1.5 s on the old code shows the finding's own
        -- picture, the engine running with an empty lock; the put-back takes the key back from the bag)
        S.crank.stateAfter = H.engState()
    end
    if H.running() then return true end
    -- (a start that did not take: tried again, as a player turns the key again)
    if s and s.keysIn and not s.cranking and not H.started() and getTimestampMs() - S.t0 > 3000 and S.tries < 5 then
        S.tries = S.tries + 1
        S.t0 = getTimestampMs()
        H.ignition()
    end
    return false
end, function(ok)
    if S.noIgn then return end
    local c = S.crank
    if not c then
        Q.check(false, "W20: the starter was seen turning (engine started, not yet running)", "engine " .. H.engState() .. ", " .. tostring(S.tries) .. " retries")
    else
        Q.check(S.rightLive and c.keyBefore and c.keyAfterRight and (c.how == "hit" or c.how == "fired"), "W20: starter turning, a right click on the ignition leaves the key in (old: it came out)",
            "engine " .. tostring(c.state) .. ", right click " .. tostring(c.how) .. ", key in before " .. tostring(c.keyBefore) .. ", after " .. tostring(c.keyAfterRight)
            .. ", the right click live with the engine off " .. tostring(S.rightLive))
        Q.check(S.padLive and c.keyBeforePad and c.keyAfterPad and c.pad == "pressed", "W20: starter turning, the pad's X on the ignition leaves the key in (old: Remove key)",
            "X " .. tostring(c.pad) .. ", key in before " .. tostring(c.keyBeforePad) .. ", after " .. tostring(c.keyAfterPad) .. ", engine then " .. tostring(c.stateAfter)
            .. ", X live with the engine off " .. tostring(S.padLive))
    end
    S.ran = Q.check(H.running(), "W20: the engine catches and runs", "engine " .. H.engState() .. ", " .. tostring(S.tries) .. " retries")
end)
Q.waitMs(1500)
Q.step(1, function()
    if S.noIgn or not S.ran then return end
    Q.check(H.running() and H.keysIn(), "W20: 1.5 s on, the engine runs with the key in the lock (old: an empty lock)",
        "running " .. tostring(H.running()) .. ", key in " .. tostring(H.keysIn()))
    local s = H.st() or {}
    Q.check(s.running == true and s.keysIn == true, "W20: the dash reads it running with the key in", "running " .. tostring(s.running) .. ", key " .. tostring(s.keysIn))
    S.runHow = H.rightIgnition()
end)
Q.step(5, function()
    if S.noIgn or not S.ran then return end
    Q.check(H.running() and H.keysIn(), "W20: running, a right click on the ignition still leaves the key in", "right click " .. tostring(S.runHow) .. ", key in " .. tostring(H.keysIn()))
    H.ignition()   -- (running: the ignition shuts it off)
end)
Q.waitFor(5, 900, function() return S.noIgn or not S.ran or not (H.running() or H.started()) end, function(ok)
    if S.noIgn or not S.ran then return end
    Q.check(ok, "W20: a click on the ignition shuts the engine off", "engine " .. H.engState())
end)

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    -- (each line on its own: one that fails must not stop the next)
    pcall(function() if S.v and S.nameWas and S.v:getScriptName() ~= S.nameWas then S.v:setScriptName(S.nameWas) end end)
    pcall(function() local w = H.popout(); if w then w._drag = nil; w:setCapture(false) end end)
    pcall(function() local w = H.popout(); if H.vis(w) then w:close() end end)
    pcall(function() local w = H.chooser(); if H.vis(w) then w:close() end end)
    if S.placeRead then pcall(function() S.p:getModData().ZeD_SeatPopout = S.placeWas end) end
    pcall(function() S.p:StopAllActionQueue() end)
    pcall(function() if S.v and (S.v:isEngineRunning() or S.v:isEngineStarted()) then S.v:shutOff() end end)
    pcall(function() if S.v and S.v:isKeysInIgnition() then S.v:setKeysInIgnition(false) end end)
    H.putStyle()
end)
Q.step(10, function()
    if S.v and ZEDQA_CAR_AWAY then pcall(ZEDQA_CAR_AWAY, S.v, S.key) end
end)
Q.waitFor(5, 600, function()
    if not S.v then return true end
    local gone = true
    pcall(function()
        local it = getCell():getVehicles():iterator()
        while it:hasNext() do
            if it:next() == S.v then gone = false end
        end
    end)
    return gone and S.p:getVehicle() == nil
end, function(ok)
    if S.invWas ~= nil then pcall(function() S.p:setInvincible(S.invWas) end) end
    if S.godWas ~= nil then pcall(function() S.p:setGodMod(S.godWas) end) end
    if not S.v then return end
    local keyLeft = false
    pcall(function() keyLeft = S.key ~= nil and S.p:getInventory():contains(S.key) end)
    Q.check(ok and not keyLeft, "put back: the character out, the key taken back, the car removed", "gone " .. tostring(ok) .. ", key left " .. tostring(keyLeft))
    local dead, god = false, nil
    pcall(function() dead = S.p:isDead() end)
    pcall(function() god = S.p:isGodMod() end)
    Q.check(not dead and H.savedPlace() == S.placeWasText and (S.godWas == nil or god == S.godWas),
        "put back: the character well, the pop-out's saved place and god mode as found",
        "saved place " .. H.savedPlace() .. ", god mode " .. tostring(god) .. ", Lite " .. tostring(H.lite()))
end)
Q.start()
