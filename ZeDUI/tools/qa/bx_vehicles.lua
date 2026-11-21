-- ZeDUI/tools/qa/bx_vehicles.lua  (Nov 21 2026, QA beast day): the cars, stressed. Built on rt_kit.lua (run it first)
-- and the prelude's car helpers (zedqa_prelude.lua: ZEDQA_HOME, ZEDQA_CAR_WAIT / _PREP / _ENTER / _READY).
-- grep "ZEDQA bx_veh".
--
-- One police car (Base.CarLightsPolice) on the drag strip, repaired and fuelled, its key taken away. Then, fast and
-- in odd orders, with ZeD's dash and the window pair up:
--   no key    the dash reads no key; three fast clicks on the ignition start nothing
--   hotwire   Electricity and Mechanics raised (put back after); the game's hotwire action, interrupted once, then run
--             to its end (again when the game's own dice fail); the dash reads hotwired; a click on the ignition starts it
--   controls  the dash's headlight switch twice; the horn held (the game's own, the dash goes on reading); the dash's
--             lightbar and siren switches; the radio from the dash: power, TUNE by left and right click, the set up
--             close and away three times in a row
--   seats     the seat key four times in a row (open, shut, open, shut); a move to the passenger seat through ZeD's
--             seat window: the dash is read-only there (the ignition and the lights do nothing); back to the wheel
--             through the window; out by the game's Exit (the dash goes); the game's Enter as passenger interrupted,
--             then run; over to the driver's seat
--   crash     a second car across the strip 14 tiles ahead; the police car is given real speed by
--             BaseVehicle.addImpulse every frame (else by the cruise control), ZeD's dash read while it moves, and
--             runs into the car. The game never damages the car of a driver in god mode, so the police car's front
--             parts' conditions are set by hand, said with SKIP. Then the dash's part readings against the game, the
--             engine off, the game's Vehicle Mechanics: every part's condition in the Vehicle tab against the game,
--             the worst part's card
--   injury    every wound the game holds must be in ZeD's Health list; god mode keeps the crash from wounding, so one
--             scratch is put on the left forearm (god mode off for a second, then healed) and looked for
--   removed   the crashed car removed from the world while its Vehicle tab, a part's card and ZeD's seat window are
--             open: the inspection ends, the tab drops the car, the card and the seat window close, nothing throws
--   on foot   a sprint (the game's auto-walk, forced to a sprint) into the second car, into a wall and into a low
--             fence built for it on the strip; after each: both windows up, the Health list right, everything on screen
-- Put back: healed first, the walk off, the props closed, the built wall and fence removed, the two skills and the
-- stats as found, both cars removed (the second one looked for by its key number where it stood), the tabs as found,
-- the character home on the strip; last, the character read alive and healed (a PASS / FAIL line) and only then god
-- mode and invincible as found.
-- The character's safety (Nov 21 2026, preflight): god mode AND invincible are turned on in the first step and stay on
-- for the whole run; a watch on every tick (H.guard) turns them on again and heals a body under 60, until the last
-- step. God mode is the real shield: under it BodyDamage.Update heals the whole body every tick, and the crash, falls
-- and hits skip him (javap, 42.22). Invincible is on because the rule asks for it, but nothing in the game reads it for
-- the player in 42.22 (only its own getter and IsoAnimal), so it shields nothing. The first step reads god mode back:
-- off (a game not in debug mode refuses it), nothing that can hurt him is staged. The one staged scratch takes god mode
-- off for a second, on foot, nothing queued and no zombie within 10 tiles, then heals; a check says so. The game's
-- BaseVehicle.crash is never called (with the character at the wheel and god mode off it would wound him).

if not RT then
    print("ZEDQA bx_veh ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA bx_veh VERDICT FAIL 1")
    print("ZEDQA bx_veh DONE")
    return
end

local Q = RT.make("bx_veh")
Q.maxMs = 400000   -- (the budget is 8 minutes: past 6:40 the run jumps to the put-back)
local S = {}
local H = {}
S.p, S.pn = RT.p, RT.pn
S.D = ZeD.Dashboard
S.R = ZeD.CarRadio
S.O = ZeD.RadioOps
S.Seats = ZeD.Seats
S.MT = ZeD.MechanicsTab
S.HT = ZeD.HealthTab
S.cars = {}     -- every car this script spawned
S.built = {}    -- every wall or fence piece it built
S.sp = {}       -- the sprints
S.clock = {}

-- ===================================================================== helpers
function H.over(key, ms)
    local t = getTimestampMs()
    if not S.clock[key] then S.clock[key] = t end
    return t - S.clock[key] >= ms
end
-- ZeD's code under test, called so a throw becomes a FAIL and the run goes on
function H.zed(what, fn, a, b, c, d)
    local ok, r = pcall(fn, a, b, c, d)
    if not ok then Q.check(false, what .. ": ZeD's code ran without an error", tostring(r)); return false, nil end
    return true, r
end
function H.has(o, name) return o ~= nil and o[name] ~= nil end
function H.inCar() return S.v ~= nil and S.p:getVehicle() == S.v end
function H.seat()
    local n = -1
    pcall(function() if S.p:getVehicle() == S.v then n = S.v:getSeat(S.p) end end)
    return n
end
function H.canDrive() return H.inCar() and H.seat() == 0 end
function H.dash() local d = nil; pcall(function() d = S.D.getInstance(S.pn) end); return d end
function H.st() local d = H.dash(); return d and d._st end
function H.vis(o)
    local v = false
    if o then pcall(function() v = o:isReallyVisible() end) end
    return v
end
function H.pressHit(panel, h, fx, up)
    if not (panel and h) then return false end
    local x = h.x + math.floor(h.w * (fx or 0.5))
    local y = h.y + math.floor(h.h / 2)
    local ok, e = pcall(function()
        panel:onMouseDown(x, y)
        if up then panel:onMouseUp(x, y) end
    end)
    if not ok then Q.check(false, "a click on " .. tostring(h.id) .. ": ZeD's code ran without an error", tostring(e)) end
    return ok
end
function H.rightHit(panel, h, fx)
    if not (panel and h and panel.onRightMouseDown) then return false end
    local x = h.x + math.floor(h.w * (fx or 0.5))
    local y = h.y + math.floor(h.h / 2)
    local ok, e = pcall(function() panel:onRightMouseDown(x, y) end)
    if not ok then Q.check(false, "a right click on " .. tostring(h.id) .. ": ZeD's code ran without an error", tostring(e)) end
    return ok
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
function H.dashHit(ids) local d = H.dash(); return d and H.hitOf(d._hit, ids), d end
-- the dash's ignition, clicked (its hit), else fired as the click would
function H.ignition()
    local h, d = H.dashHit({ "ignition" })
    if not d then return false end
    if h then return H.pressHit(d, h, 0.5, false) end
    local ok, e = pcall(function() d:_fire("ignition", false) end)
    if not ok then Q.check(false, "the ignition: ZeD's code ran without an error", tostring(e)) end
    return true
end
function H.running() local r = false; pcall(function() r = S.v:isEngineRunning() end); return r and true or false end
function H.hotwired() local r = false; pcall(function() r = S.v:isHotwired() end); return r and true or false end
function H.headlights() local on = false; pcall(function() on = S.v:getHeadlightsOn() end); return on and true or false end
function H.lightbar() local m = -1; pcall(function() m = S.v:getLightbarLightsMode() end); return m end
function H.siren() local m = -1; pcall(function() m = S.v:getLightbarSirenMode() end); return m end
function H.busy() local b = false; pcall(function() b = ISTimedActionQueue.isPlayerDoingAction(S.p) end); return b and true or false end
function H.stopActions()
    pcall(function() ISTimedActionQueue.clear(S.p) end)
    pcall(function() S.p:StopAllActionQueue() end)
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
function H.seatKey(car)
    local ok, e = pcall(ISVehicleMenu.onShowSeatUI, S.p, car or S.v)
    if not ok then Q.check(false, "the seat key: ZeD's code ran without an error", tostring(e)) end
end
function H.ms() local w = RT.ww(); return w and S.MT.getState(w) end
function H.zone(id) local s = H.ms(); return s and s.byId and s.byId[id] end
function H.inspected()
    local w = RT.ww()
    local i = false
    pcall(function() i = S.MT.isInspected(S.v) end)
    return i and w ~= nil and w._activeTab == "vehicle"
end
function H.live(v)
    local found = false
    if not v then return false end
    pcall(function()
        local it = getCell():getVehicles():iterator()
        while it:hasNext() do if it:next() == v then found = true end end
    end)
    return found
end
function H.findKey(keyId)
    local got = nil
    pcall(function()
        local it = getCell():getVehicles():iterator()
        while it:hasNext() do
            local o = it:next()
            if o:getKeyId() == keyId then got = o end
        end
    end)
    return got
end
function H.dist(v)
    local d = 999
    pcall(function() local dx, dy = v:getX() - S.p:getX(), v:getY() - S.p:getY(); d = math.sqrt(dx * dx + dy * dy) end)
    return d
end
function H.speed(v)
    local s = 0
    pcall(function() s = math.abs(v:getCurrentSpeedKmHour()) end)
    return s
end
-- a part's condition as the dash reads it: nil when the car has no such part or its item is not fitted
function H.partCond(id)
    local c = nil
    pcall(function()
        local part = S.v:getPartById(id)
        if not part then return end
        local it = part:getItemType()
        if it ~= nil and not it:isEmpty() and part:getInventoryItem() == nil then return end
        c = part:getCondition()
    end)
    return c
end
function H.condSum(v)
    local total = 0
    pcall(function()
        for i = 0, v:getPartCount() - 1 do
            local part = v:getPartByIndex(i)
            local it = part:getItemType()
            if not (it ~= nil and not it:isEmpty() and part:getInventoryItem() == nil) then total = total + part:getCondition() end
        end
    end)
    return total
end
-- a square that is loaded, outdoors and free, no tree and no car on it
function H.clearAt(x, y)
    local ok = false
    pcall(function()
        local sq = getCell():getGridSquare(x, y, 0)
        ok = sq ~= nil and sq:getChunk() ~= nil and sq:isFree(false) and not sq:HasTree()
            and sq:getVehicleContainer() == nil and sq:getRoom() == nil
    end)
    return ok
end
function H.boxClear(x0, y0, x1, y1)
    for y = y0, y1 do
        for x = x0, x1 do if not H.clearAt(x, y) then return false end end
    end
    return true
end
function H.carNear(x, y, r)
    local near = false
    pcall(function()
        local it = getCell():getVehicles():iterator()
        while it:hasNext() do
            local o = it:next()
            if math.abs(o:getX() - x) < r and math.abs(o:getY() - y) < r then near = true end
        end
    end)
    return near
end
function H.loaded(x, y)
    for _, o in ipairs({ { 0, 0 }, { 8, 0 }, { -8, 0 }, { 0, 8 }, { 0, -8 } }) do
        local sq = getCell():getGridSquare(math.floor(x) + o[1], math.floor(y) + o[2], 0)
        local ch = nil
        if sq then pcall(function() ch = sq:getChunk() end) end
        if not ch then return false end
    end
    return true
end
function H.tp(x, y)
    pcall(function()
        local p = S.p
        p:setX(x); p:setY(y); p:setZ(0); p:setLastX(x); p:setLastY(y); p:setLastZ(0)
    end)
end
function H.exitNow()
    pcall(function()
        local car = S.p:getVehicle()
        if car then car:exit(S.p); triggerEvent("OnExitVehicle", S.p) end
    end)
end
function H.statsKeep()
    S.stats = {}
    pcall(function()
        local st = S.p:getStats()
        for _, k in ipairs({ "ENDURANCE", "FATIGUE", "PANIC", "STRESS", "PAIN" }) do
            if CharacterStat[k] then S.stats[k] = st:get(CharacterStat[k]) end
        end
    end)
end
-- the full heal: every part by the game's own BodyPart.RestoreToFullHealth, then the body's (it clears every wound,
-- fracture, burn, bandage and infection and resets the stats, which are then put back as found). Every call is one
-- the game has with this number of arguments (javap, 42.22), each in its own pcall: one that throws stops nothing.
function H.heal()
    pcall(function()
        local parts = S.p:getBodyDamage():getBodyParts()
        for i = 0, parts:size() - 1 do
            local bp = parts:get(i)
            pcall(function() bp:RestoreToFullHealth() end)
        end
    end)
    pcall(function() S.p:getBodyDamage():RestoreToFullHealth() end)
    pcall(function() S.p:getBodyDamage():setInfected(false) end)
    pcall(function() S.p:getBodyDamage():setOverallBodyHealth(100) end)
    pcall(function()
        local st = S.p:getStats()
        for k, v in pairs(S.stats or {}) do st:set(CharacterStat[k], v) end
    end)
end
-- what is wrong with the character now, in words; an empty list is alive and healed
function H.hurt()
    local bad = {}
    local okR = pcall(function()
        if S.p:isDead() then bad[#bad + 1] = "dead" end
        local bd = S.p:getBodyDamage()
        local overall = bd:getOverallBodyHealth()
        if overall < 99.5 then bad[#bad + 1] = string.format("health %.1f", overall) end
        if bd:IsInfected() then bad[#bad + 1] = "infected" end
        local parts = bd:getBodyParts()
        for i = 0, parts:size() - 1 do
            local bp = parts:get(i)
            if H.wounded(bp) then
                bad[#bad + 1] = tostring(bp:getType()) .. (bp:getFractureTime() > 0 and " fractured" or " wounded")
            elseif bp:isInfectedWound() then
                bad[#bad + 1] = tostring(bp:getType()) .. " infected wound"
            end
        end
    end)
    if not okR then bad[#bad + 1] = "the body could not be read" end
    return bad
end
-- god mode and invincible ON (the whole run; the one staged scratch takes god mode off for a second). Only god mode
-- shields him: the game reads invincible for no player in 42.22.
function H.safeOn()
    pcall(function() S.p:setInvincible(true) end)
    pcall(function() S.p:setGodMod(true) end)
end
function H.godBack()
    S.godOff, S.godOffAt = nil, nil
    H.safeOn()
end
-- a watch on every tick until the put-back's last step: god mode or invincible found off is turned on again, a god
-- mode left off past 4 seconds (a step that threw) is healed and turned on, a body under 60 is healed. It is never
-- taken off before the last step, so a throw anywhere leaves the character guarded.
function H.guard()
    if S.done then Events.OnTick.Remove(H.guard); return end
    pcall(function()
        local p = S.p
        if p:isDead() then return end
        if S.godOff then
            if getTimestampMs() - (S.godOffAt or 0) > 4000 then
                H.heal(); H.godBack()
                S.guardSaid = (S.guardSaid or 0) + 1
                if S.guardSaid <= 3 then Q.say("NOTE the guard: god mode was off for more than 4 s, healed and turned on") end
            elseif not p:isInvincible() then p:setInvincible(true) end
        elseif not p:isGodMod() or not p:isInvincible() then
            H.safeOn()
        end
        if p:getBodyDamage():getOverallBodyHealth() < 60 then
            H.heal()
            S.guardHeals = (S.guardHeals or 0) + 1
            if S.guardHeals <= 3 then Q.say("NOTE the guard: the body was under 60, healed") end
        end
    end)
end
-- the nearest live zombie within r tiles (nil: none); ok false when the list could not be read
function H.zombieNear(r)
    local near = nil
    local ok = pcall(function()
        local zl = getCell():getZombieList()
        local px, py = S.p:getX(), S.p:getY()
        for i = 0, zl:size() - 1 do
            local z = zl:get(i)
            if z and not z:isDead() then
                local dx, dy = z:getX() - px, z:getY() - py
                local d = math.sqrt(dx * dx + dy * dy)
                if d < r and (near == nil or d < near) then near = d end
            end
        end
    end)
    return ok, near
end

-- ---- the Health list against the game
function H.wounded(bp)
    local w = false
    pcall(function()
        w = bp:scratched() or bp:isCut() or bp:deepWounded() or bp:bitten() or bp:bleeding()
            or bp:getFractureTime() > 0 or bp:getBurnTime() > 0 or bp:haveGlass() or bp:haveBullet()
    end)
    return w and true or false
end
function H.woundCheck(label)
    local okD, data = H.zed("the Health list (" .. label .. ")", S.HT.gatherData, S.p)
    if not (okD and data) then return 0, nil end
    local missed, n = {}, 0
    pcall(function()
        local parts = S.p:getBodyDamage():getBodyParts()
        for i = 0, parts:size() - 1 do
            local bp = parts:get(i)
            if H.wounded(bp) then
                n = n + 1
                local found = false
                for _, e in ipairs(data.entries or {}) do
                    if e.bodyPart == bp and #e.conditions > 0 then found = true end
                end
                if not found then missed[#missed + 1] = tostring(bp:getType()) end
            end
        end
    end)
    Q.check(#missed == 0, "health (" .. label .. "): every wound the game holds is in ZeD's injury list",
        n .. " wounded part(s) in the game, " .. tostring(data.woundedCount) .. " in ZeD's list"
        .. (#missed > 0 and (", missing " .. table.concat(missed, ", ")) or ""))
    return n, data
end

-- ---- the car pushed (BaseVehicle.addImpulse: x, up, y) and the cruise control
function H.push(L, sign)
    local ok = pcall(function()
        local z = sign * L.mass * L.mag
        local imp, rel = nil, nil
        local okN = pcall(function() imp = Vector3f.new(0, 0, z); rel = Vector3f.new(0, 0, 0) end)
        if not (okN and imp and rel) then
            imp = Vector3f.new(); imp:set(0, 0, z)
            rel = Vector3f.new()
        end
        S.v:addImpulse(imp, rel)
    end)
    if L.impOk == nil then
        L.impOk = ok
        if not ok then Q.say("NOTE BaseVehicle.addImpulse could not be called from Lua") end
    end
end
function H.cruise(on)
    pcall(function()
        if on then S.v:setRegulatorSpeed(120); S.v:setRegulator(true)
        elseif S.v:isRegulator() then S.v:setRegulator(false) end
    end)
end
function H.driveImpulse(L, sp, t)
    local gone = math.abs(S.v:getY() - L.y0) + math.abs(S.v:getX() - L.x0)
    if sp >= 90 or t > 3500 or gone > 30 or not L.canPush then
        L.tc = getTimestampMs()
        if L.max >= 15 then L.phase = "coast" else L.phase = "cruise"; H.cruise(true) end
        return
    end
    -- (it starts small, half a metre a second each frame, for a game that scales the push up; no speed after a
    -- while: the push is too small for this game, doubled every six frames up to 128)
    if L.frames > 8 and L.max < 5 and L.mag < 128 and L.frames - (L.grewAt or 0) >= 6 then
        L.mag = L.mag * 2
        L.grewAt = L.frames
    end
    H.push(L, -1)
end
function H.driveCoast(L, sp)
    local tc = getTimestampMs() - L.tc
    local y = S.v:getY()
    local dy = y - (L.py or y)
    L.py = y
    -- (a car that hit nothing is slowed by the same push, against its travel along the strip; at once when it is
    -- more than 30 tiles from where it started, so it stays on loaded ground)
    local far = math.abs(y - L.y0) + math.abs(S.v:getX() - L.x0)
    if (tc > 1500 or far > 30) and sp > 6 and L.impOk and L.canPush then
        local keep = L.mag
        L.mag = keep * 0.4
        if dy < -0.02 then H.push(L, 1) elseif dy > 0.02 then H.push(L, -1) end
        L.mag = keep
    end
    return (sp < 2 and tc > 800) or tc > 7000
end
function H.drive()
    local L = S.L
    if not (L and H.inCar()) then return true end
    local t = getTimestampMs() - L.t0
    local sp = H.speed(S.v)
    if sp > L.max then L.max = sp end
    L.frames = L.frames + 1
    local s = H.st()
    if s then
        if (s.speed or 0) > L.dashMax then L.dashMax = s.speed end
        if sp > 20 and math.abs((s.speed or 0) - sp) < 25 then L.dashAgree = true end
        if L.phase == "cruise" and s.cruise then L.cruiseSeen = true end
    end
    if L.phase == "impulse" then
        H.driveImpulse(L, sp, t)
    elseif L.phase == "cruise" then
        if sp >= 60 or getTimestampMs() - L.tc > 6500 then H.cruise(false); L.phase = "coast"; L.tc = getTimestampMs() end
    else
        return H.driveCoast(L, sp)
    end
    return false
end
-- the driven car not damaged by the hit: the front parts' conditions by hand. (The game shields the car of a driver
-- in god mode: BaseVehicle.addDamageFront, addDamageRear and damageHeadlight return at once for him, so neither a real
-- hit nor BaseVehicle.crash damages the police car while god mode is on, and god mode stays on. BaseVehicle.crash is
-- never called here: it also runs damagePlayers, which wounds the character at the wheel whenever god mode is off.)
function H.fakeCrash()
    for _, pr in ipairs({ { "Engine", 22 }, { "EngineDoor", 10 }, { "HeadlightLeft", 0 }, { "HeadlightRight", 35 },
                          { "Windshield", 15 }, { "TireFrontLeft", 30 }, { "Battery", 45 } }) do
        pcall(function()
            local part = S.v:getPartById(pr[1])
            if part then part:setCondition(pr[2]); S.v:transmitPartCondition(part) end
        end)
    end
    S.crashHow = "the front parts' conditions set by hand"
end
function H.afterDrive()
    local L = S.L
    if not L then
        if S.noDrive then Q.skip("the high-speed crash", S.noDrive) end
        return
    end
    H.cruise(false)
    local dx, dy = S.v:getX() - L.x0, S.v:getY() - L.y0
    Q.say(string.format("NOTE crash run: top speed %.0f km/h (the dash's top %.0f), moved %.1f tiles, addImpulse usable %s, push %.0f m/s a frame, cruise lamp seen %s",
        L.max, L.dashMax, math.sqrt(dx * dx + dy * dy), tostring(L.impOk), L.mag, tostring(L.cruiseSeen)))
    local dmgV, dmgT = S.sumV0 - H.condSum(S.v), 0
    if S.t and H.live(S.t) then
        dmgT = S.sumT0 - H.condSum(S.t)
        pcall(function() S.tx, S.ty = S.t:getX(), S.t:getY() end)
    end
    if L.max >= 20 then
        Q.check(true, "crash: the car was given real speed", string.format("%.0f km/h", L.max))
        Q.check(L.dashAgree == true, "crash: ZeD's dash read the car's speed while it moved", string.format("dash top %.0f, game top %.0f", L.dashMax, L.max))
    else
        Q.skip("a run at real speed", string.format("neither BaseVehicle.addImpulse nor the cruise control moved the car (top %.0f km/h)", L.max))
    end
    Q.say(string.format("NOTE crash damage by the game: the police car %.0f condition points, the car it hit %.0f", dmgV, dmgT))
    if L.max >= 20 and dmgT > 0 then
        Q.check(true, "crash: the hit damaged the car that was hit (the game's own crash)", string.format("%.0f condition points lost", dmgT))
    end
    if L.max >= 20 and dmgV > 0 then
        Q.check(true, "crash: the hit damaged the police car (the game's own crash)", string.format("%.0f condition points lost", dmgV))
        S.crashHow = "a real hit"
        return
    end
    -- (the readings after the crash need a damaged car: the police car's front is damaged by hand)
    H.fakeCrash()
    Q.skip("damage to the police car from a real hit", (L.max >= 20 and "the game does not damage the car of a driver in god mode, and god mode stays on"
        or "the car never got up to speed") .. "; damaged instead by " .. tostring(S.crashHow))
end
function H.dashAgrees()
    local s = H.st()
    if not s then return false end
    local eng = 100
    pcall(function() eng = S.v:getPartById("Engine"):getCondition() end)
    return s.engineCond == eng and s.hlL == H.partCond("HeadlightLeft") and s.hlR == H.partCond("HeadlightRight")
        and s.battCond == H.partCond("Battery") and (s.running and true or false) == H.running()
end

-- ---- on foot: the game's auto-walk, forced to a sprint
function H.walk(ix, iy, on)
    local p = S.p
    if not (H.has(p, "setAutoWalk") and H.has(p, "setAutoWalkDirection")) then return false end
    local ok = pcall(function()
        if on then
            p:setAutoWalkDirection(Vector2.new(ix, iy))
            p:setAutoWalk(true)
            if H.has(p, "setForceSprint") then p:setForceSprint(true) end
            p:setSprinting(true)
        else
            p:setAutoWalk(false)
            if H.has(p, "setForceSprint") then p:setForceSprint(false) end
            p:setSprinting(false)
            p:setRunning(false)
        end
    end)
    return ok
end
function H.stateName()
    local n = ""
    pcall(function()
        if H.has(S.p, "getCurrentStateName") then n = tostring(S.p:getCurrentStateName()) else n = tostring(S.p:getCurrentState()) end
    end)
    return n
end
function H.down()
    local n = H.stateName()
    for _, w in ipairs({ "Fall", "Bump", "Collide", "GetUp", "Climb", "Knock", "OnGround" }) do
        if string.find(n, w, 1, true) then return true end
    end
    return false
end
function H.sprintGo(key)
    local c = S.sp[key]
    if not c then return end
    c.x0, c.y0 = S.p:getX(), S.p:getY()
    c.ix, c.iy = c.dx, c.dy
    c.far, c.still, c.seen = 0, 0, {}
    c.walkOk = H.walk(c.ix, c.iy, true)
    c.t0 = getTimestampMs()
end
-- the walk's direction is given in the world's frame; when the character heads elsewhere the input is turned by
-- the error once and the run starts over
function H.sprintFix(c, mx, my)
    c.fixed = true
    local len = math.sqrt(mx * mx + my * my)
    if len < 0.2 then return end
    local ax, ay = mx / len, my / len
    local cs, sn = ax * c.dx + ay * c.dy, ax * c.dy - ay * c.dx
    if cs > 0.94 then return end
    c.ix, c.iy = c.dx * cs - c.dy * sn, c.dx * sn + c.dy * cs
    c.turned = string.format("cos %.2f sin %.2f", cs, sn)
    H.walk(0, 0, false)
    H.tp(c.sx, c.sy)
    c.x0, c.y0, c.far, c.still = c.sx, c.sy, 0, 0
    c.restart = getTimestampMs() + 400
end
function H.sprintTick(key)
    local c = S.sp[key]
    if not (c and c.t0) or not c.walkOk then return true end
    local now = getTimestampMs()
    if c.restart then
        if now >= c.restart then c.restart = nil; c.t0 = now; H.walk(c.ix, c.iy, true) end
        return false
    end
    local t = now - c.t0
    local x, y = S.p:getX(), S.p:getY()
    local mx, my = x - c.x0, y - c.y0
    local along = mx * c.dx + my * c.dy
    if along > c.far then c.far = along end
    pcall(function() if S.p:isSprinting() then c.sprinted = true end end)
    local n = H.stateName()
    if n ~= "" then c.seen[n] = true end
    if not c.fixed and t > 700 then H.sprintFix(c, mx, my); return false end
    if t > 700 then
        if math.abs(x - (c.lx or x)) + math.abs(y - (c.ly or y)) < 0.004 then c.still = c.still + 1 else c.still = 0 end
    end
    c.lx, c.ly = x, y
    if c.still > 20 and c.far > 1 then return true end
    if along > c.len + 4 then return true end
    return t > 5000
end
function H.fakeFall()
    pcall(function()
        S.p:setBumpType("stagger")
        S.p:setVariable("BumpDone", false)
        S.p:setVariable("BumpFall", true)
        S.p:setVariable("BumpFallType", "pushedFront")
    end)
end
function H.sprintEnd(key, label)
    local c = S.sp[key]
    if not (c and c.t0) then return end
    H.walk(0, 0, false)
    local seen = {}
    for n in pairs(c.seen) do seen[#seen + 1] = n end
    Q.say(string.format("NOTE %s: ran %.1f of %.1f tiles, sprinting seen %s, input turned %s, states: %s", label, c.far, c.len,
        tostring(c.sprinted), tostring(c.turned), table.concat(seen, " ")))
    if c.far < 1 then
        Q.skip(label .. ": a real sprint", "the game's auto-walk did not move the character (setAutoWalk usable: " .. tostring(c.walkOk) .. "); a fall staged instead by the game's bump variables")
        H.fakeFall()
        return
    end
    if c.block and c.far >= c.len + 0.3 then
        Q.skip(label .. ": the hit itself", "the character got past what was staged (" .. string.format("%.1f", c.far) .. " tiles): no hit to look at")
    end
    c.ran = true
end
function H.afterHit(key, label)
    local c = S.sp[key]
    if not (c and c.t0) then return end
    Q.check(RT.isOpen() and H.vis(RT.cw()) and H.vis(RT.ww()), label .. ": both ZeD windows are still up")
    H.woundCheck(label)
    RT.bounds(Q, label)
end
function H.queueSprint(key, label)
    Q.step(30, function() H.sprintGo(key) end)
    Q.waitFor(1, 3000, function() return H.over("run_" .. key, 9000) or H.sprintTick(key) end, function() H.sprintEnd(key, label) end)
    Q.waitFor(20, 1200, function() return H.over("up_" .. key, 5000) or not H.down() end, function() H.afterHit(key, label) end)
end

-- ---- a wall or a fence across a lane on the strip (three pieces on the west edge of three squares)
function H.lane()
    local hx, hy = 925, 13040
    for _, o in ipairs({ { -3, 4 }, { -3, -5 }, { 3, 8 }, { -10, 6 }, { 4, -8 }, { 0, 10 }, { 0, -10 }, { -12, -8 }, { 8, 4 } }) do
        local wx, wy = hx + o[1], hy + o[2]
        if H.boxClear(wx - 3, wy - 1, wx + 8, wy + 1) and not H.carNear(wx + 2, wy, 9) then return { wx = wx, wy = wy } end
    end
    return nil
end
function H.build(sprite, hop)
    local n = 0
    for dy = -1, 1 do
        local sq = getCell():getGridSquare(S.site.wx, S.site.wy + dy, 0)
        local obj = nil
        if sq then
            pcall(function() obj = IsoThumpable.new(getCell(), sq, sprite, nil, false, nil) end)
            if obj then
                S.built[#S.built + 1] = { sq = sq, obj = obj }
                local ok = pcall(function()
                    if hop then obj:setIsHoppable(true) else obj:setCanPassThrough(false) end
                    sq:AddSpecialObject(obj)
                    sq:RecalcAllWithNeighbours(true)
                end)
                if ok then n = n + 1 end
            end
        end
    end
    return n
end
function H.onSquare(b)
    local on = false
    pcall(function() on = b.sq:getObjects():contains(b.obj) or b.sq:getSpecialObjects():contains(b.obj) end)
    return on
end
function H.unbuild()
    local left = 0
    for _, b in ipairs(S.built) do
        pcall(function() b.sq:transmitRemoveItemFromSquare(b.obj) end)
        if H.onSquare(b) then pcall(function() b.sq:RemoveTileObject(b.obj) end) end
        if H.onSquare(b) then pcall(function() b.sq:getSpecialObjects():remove(b.obj); b.sq:getObjects():remove(b.obj) end) end
        pcall(function() b.sq:RecalcAllWithNeighbours(true) end)
        if H.onSquare(b) then left = left + 1 end
    end
    S.built = {}
    S.builtLeft = (S.builtLeft or 0) + left
    return left
end
function H.stageBarrier(key, sprite, hop, what)
    if not S.site then return end
    local n = H.build(sprite, hop)
    if n < 3 then
        Q.skip("a sprint into " .. what, "only " .. n .. " of 3 pieces could be built (IsoThumpable.new, sprite " .. sprite .. ")")
        H.unbuild()
        return
    end
    S.sp[key] = { sx = S.site.wx + 6.5, sy = S.site.wy + 0.5, dx = -1, dy = 0, len = 6.5, block = not hop }
    H.tp(S.sp[key].sx, S.sp[key].sy)
end

-- ===================================================================== the car, its key taken away
Q.step(2, function()
    if getGameSpeed() <= 0 then pcall(setGameSpeed, 1) end
    -- first of all, before anything can throw: what is found, then god mode and invincible on and the watch started
    pcall(function() S.godWas = S.p:isGodMod() end)
    pcall(function() S.invWas = S.p:isInvincible() end)
    H.statsKeep()
    if S.p:isDead() then S.failWhy = "the character is dead"; return end
    H.safeOn()
    -- (one watch at a time: a watch an earlier push of this script left on is taken off first)
    if ZEDQA_BXVEH_GUARD then pcall(function() Events.OnTick.Remove(ZEDQA_BXVEH_GUARD) end) end
    ZEDQA_BXVEH_GUARD = H.guard
    Events.OnTick.Add(H.guard)
    S.guardOn = true
    -- read back: a game not in debug mode refuses god mode (Role.hasCapability), and then nothing that can hurt him runs
    local godOn = false
    pcall(function() godOn = S.p:isGodMod() end)
    Q.say("NOTE found: god mode " .. tostring(S.godWas) .. ", invincible " .. tostring(S.invWas) .. "; now god mode " .. tostring(godOn) .. " for the run")
    if not godOn then
        S.unsafe = true
        S.failWhy = "god mode could not be turned on (is the game in debug mode?): no car, no crash, no sprint"
        return
    end
    if not (ZEDQA_HOME and ZEDQA_CAR_WAIT and ZEDQA_CAR_PREP and ZEDQA_CAR_ENTER and ZEDQA_CAR_READY) then
        S.failWhy = "the prelude's car helpers are not loaded (zedqa_prelude.lua runs first)"
        return
    end
    ZEDQA_HOME("bx_veh")
    S.pairWas = RT.isOpen()
    S.elecWas, S.mechWas = S.p:getPerkLevel(Perks.Electricity), S.p:getPerkLevel(Perks.Mechanics)
    local cw, ww = RT.cw(), RT.ww()
    S.charTabWas, S.worldTabWas = cw and cw._activeTab, ww and ww._activeTab
    RT.pairOpen()
    ZEDQA_CAR_WAIT("Base.CarLightsPolice", "bx_veh", function(v)
        S.v = v
        S.cars[#S.cars + 1] = v
        ZEDQA_CAR_KEEP[v] = true
        -- (repaired, fuelled and seated in the same tick; the key made by the helper is taken away again)
        S.key = ZEDQA_CAR_PREP(v)
        if S.key then pcall(function() S.p:getInventory():Remove(S.key) end) end
        pcall(function() if v:isKeysInIgnition() then v:setKeysInIgnition(false) end end)
        if H.has(v, "setKeyIsOnDoor") then pcall(function() v:setKeyIsOnDoor(false) end) end
        pcall(function() if v:isHotwired() then v:setHotwired(false) end end)
        local ok, why = ZEDQA_CAR_ENTER(v, 0)
        if not ok then S.failWhy = why end
        S.ready = true
    end, function(why) S.failWhy = why or "no ready car" end, 6000)
end)
Q.waitFor(5, 3600, function() return S.ready or S.failWhy ~= nil or H.over("car", 40000) end, function()
    Q.check(S.v ~= nil and H.inCar(), "a police car spawned beside the character, the character at the wheel, no key", tostring(S.failWhy))
end)

-- ===================================================================== no key
Q.waitFor(10, 600, function() local s = H.st(); return not H.inCar() or H.over("nokey", 5000) or (H.vis(H.dash()) and s ~= nil and s.hasKey ~= nil) end, function()
    if not H.inCar() then return end
    local d, s = H.dash(), H.st() or {}
    Q.check(H.vis(d) and d.vehicle == S.v, "no key: ZeD's dash shows in the car")
    Q.check(s.hasKey == false and s.keysIn == false and s.hotwired == false, "no key: the dash reads no key, an empty ignition, not hotwired",
        "has key " .. tostring(s.hasKey) .. ", in " .. tostring(s.keysIn) .. ", hotwired " .. tostring(s.hotwired))
    RT.bounds(Q, "the dash, no key")
    for _ = 1, 3 do H.ignition() end
end)
Q.waitMs(800)
Q.step(1, function()
    if not H.inCar() then return end
    local s = H.st() or {}
    Q.check(not H.running() and s.keysIn == false and not s.running and not s.cranking, "no key: three fast clicks on the ignition start nothing",
        "running " .. tostring(H.running()) .. ", key in " .. tostring(s.keysIn) .. ", busy " .. tostring(H.busy()))
    -- the skill given, then the game's hotwire, interrupted
    pcall(function() S.p:setPerkLevelDebug(Perks.Electricity, 6); S.p:setPerkLevelDebug(Perks.Mechanics, 6) end)
    S.perks = true
    pcall(ISVehicleMenu.onHotwire, S.p)
end)
Q.waitMs(500)
Q.step(1, function()
    if not H.inCar() then return end
    Q.say("NOTE hotwire under way before the interrupt: " .. tostring(H.busy()))
    H.stopActions()
end)
Q.waitMs(500)
Q.step(1, function()
    if not H.inCar() then return end
    local s = H.st() or {}
    Q.check(not H.hotwired() and s.hotwired == false and H.vis(H.dash()), "hotwire: interrupted, the car is not hotwired and the dash says so",
        "game " .. tostring(H.hotwired()) .. ", dash " .. tostring(s.hotwired))
    S.hwTries, S.hwT = 0, 0
end)
Q.waitFor(2, 3600, function()
    if not H.inCar() or H.hotwired() or H.over("hw", 35000) then return true end
    if not H.busy() and getTimestampMs() - S.hwT > 600 then
        if S.hwTries >= 5 then return true end
        S.hwTries = S.hwTries + 1
        S.hwT = getTimestampMs()
        pcall(ISVehicleMenu.onHotwire, S.p)
    end
    return false
end, function()
    if not H.inCar() then return end
    if H.hotwired() then
        Q.check(true, "hotwire: the game's hotwire action took", tostring(S.hwTries) .. " tries")
    else
        H.stopActions()
        Q.skip("a hotwire by the game's own action", "it did not take in " .. tostring(S.hwTries) .. " tries: set by BaseVehicle.setHotwired")
        -- (a failed try can break the wiring for good, BaseVehicle.tryHotwire: mended first)
        pcall(function() S.v:setHotwiredBroken(false) end)
        pcall(function() S.v:setHotwired(true) end)
    end
end)
Q.waitFor(5, 300, function() local s = H.st(); return not H.inCar() or H.over("hwdash", 3000) or (s and s.hotwired == true) end, function()
    if not H.inCar() then return end
    local s = H.st() or {}
    Q.check(s.hotwired == true and s.keysIn == false, "hotwire: the dash reads the car hotwired, no key in", "hotwired " .. tostring(s.hotwired) .. ", key in " .. tostring(s.keysIn))
    S.t0, S.tries = getTimestampMs(), 0
    H.ignition()
end)
Q.waitFor(5, 3600, function()
    if not H.inCar() or H.over("start", 25000) then return true end
    local s = H.st()
    if s and s.running then return true end
    if s and not s.cranking and not H.busy() and getTimestampMs() - S.t0 > 2500 and S.tries < 6 then
        S.tries = S.tries + 1
        S.t0 = getTimestampMs()
        H.ignition()
    end
    return false
end, function()
    if not H.inCar() then return end
    local s = H.st() or {}
    Q.check(s.running == true and H.running(), "hotwire: a click on the dash's ignition starts the hotwired engine", tostring(S.tries) .. " more tries")
    RT.bounds(Q, "the dash, hotwired and running")
end)

-- ===================================================================== lights, horn, lightbar, siren
Q.step(5, function()
    if not H.inCar() then return end
    S.lightsWas = H.headlights()
    local h, d = H.dashHit({ "lights" })
    if not h then Q.skip("the dash's headlight switch", "no such control on this dash: " .. H.ids(d and d._hit)); S.noLights = true; return end
    H.pressHit(d, h, 0.5, false)
end)
Q.waitFor(3, 300, function() return S.noLights or not H.inCar() or H.over("l1", 3000) or H.headlights() ~= S.lightsWas end, function()
    if S.noLights or not H.inCar() then return end
    Q.check(H.headlights() ~= S.lightsWas, "lights: a click on the dash's switch flips the headlights", tostring(S.lightsWas) .. " -> " .. tostring(H.headlights()))
    local h, d = H.dashHit({ "lights" })
    if h then H.pressHit(d, h, 0.5, false) end
end)
Q.waitFor(3, 300, function() return S.noLights or not H.inCar() or H.over("l2", 3000) or H.headlights() == S.lightsWas end, function()
    if S.noLights or not H.inCar() then return end
    local s = H.st() or {}
    Q.check(H.headlights() == S.lightsWas, "lights: a second click puts them back", tostring(H.headlights()))
    Q.check((s.lights and true or false) == H.headlights(), "lights: the dash reads the switch as the game has it", tostring(s.lights))
end)
-- the horn held (the game's own; the dash has no horn)
Q.step(3, function() if H.inCar() then S.hornOn = pcall(ISVehicleMenu.onHornStart, S.p) end end)
Q.waitMs(450)
Q.step(1, function()
    if not H.inCar() then return end
    local snd = "not readable"
    if H.has(S.v, "isHornSounding") then pcall(function() snd = tostring(S.v:isHornSounding()) end) end
    local s = H.st() or {}
    Q.check(H.vis(H.dash()) and s.running == true, "horn: with the horn held the dash goes on reading the car", "horn sounding " .. snd)
    pcall(ISVehicleMenu.onHornStop, S.p)
    S.hornOn = nil
    -- the lightbar from the dash
    S.barWas, S.sirWas = H.lightbar(), H.siren()
    local h, d = H.dashHit({ "lbar" })
    if not h then Q.skip("the dash's lightbar switch", "no such control on this dash: " .. H.ids(d and d._hit)); S.noBar = true; return end
    H.pressHit(d, h, 0.5, false)
end)
Q.waitFor(3, 300, function() return S.noBar or not H.inCar() or H.over("bar", 3000) or H.lightbar() ~= S.barWas end, function()
    if S.noBar or not H.inCar() then return end
    local want = S.barWas + 1
    if want > 3 then want = 0 end
    Q.check(H.lightbar() == want, "lightbar: a click on the dash's switch steps the bar's lights", tostring(S.barWas) .. " -> " .. tostring(H.lightbar()))
end)
Q.waitMs(400)
Q.step(1, function()
    if not H.inCar() then return end
    if not S.noBar then
        local s = H.st() or {}
        Q.check(s.lightbarMode == H.lightbar() and (s.lbarLamp and true or false) == (H.lightbar() > 0), "lightbar: the dash's lamp follows the bar",
            "dash " .. tostring(s.lightbarMode) .. " lamp " .. tostring(s.lbarLamp) .. ", game " .. tostring(H.lightbar()))
    end
    local h, d = H.dashHit({ "siren" })
    if not h then Q.skip("the dash's siren switch", "no such control on this dash: " .. H.ids(d and d._hit)); S.noSiren = true; return end
    H.pressHit(d, h, 0.5, false)
end)
Q.waitFor(3, 300, function() return S.noSiren or not H.inCar() or H.over("sir", 3000) or H.siren() ~= S.sirWas end, function()
    if not H.inCar() then return end
    if not S.noSiren then
        local want = S.sirWas + 1
        if want > 3 then want = 0 end
        Q.check(H.siren() == want, "siren: a click on the dash's switch steps the siren", tostring(S.sirWas) .. " -> " .. tostring(H.siren()))
    end
    -- both back as found (the game's own commands)
    pcall(function() sendClientCommand(S.p, "vehicle", "setLightbarSirenMode", { mode = S.sirWas or 0 }) end)
    pcall(function() sendClientCommand(S.p, "vehicle", "setLightbarLightsMode", { mode = S.barWas or 0 }) end)
end)
Q.waitFor(3, 300, function() return not H.inCar() or H.over("barback", 3000) or (H.siren() == (S.sirWas or 0) and H.lightbar() == (S.barWas or 0)) end, function()
    if not H.inCar() then return end
    local s = H.st() or {}
    Q.check(H.siren() == (S.sirWas or 0) and H.lightbar() == (S.barWas or 0), "lightbar and siren back as found", H.lightbar() .. " / " .. H.siren())
    RT.bounds(Q, "the dash after the switches")
end)

-- ===================================================================== the radio from the dash
Q.step(5, function()
    if not H.inCar() then return end
    S.radioPart = H.radioPart()
    if not S.radioPart then Q.skip("the car radio from the dash", "this police car has no radio fitted"); return end
    local r = H.radioRead() or {}
    S.radioWas = { on = r.switchOn, channel = r.channel }
    local h, d = H.dashHit({ "pwr", "vol" })
    if not h then
        Q.skip("the radio's power from the dash", "no power control on this dash: " .. H.ids(d and d._hit))
        if not r.switchOn then pcall(S.O.power, S.p, S.radioPart) end
        return
    end
    S.dashPwr = true
    if not r.switchOn then H.pressHit(d, h, 0.5, false) end
end)
Q.waitFor(5, 600, function() local r = H.radioRead(); return not S.radioPart or not H.inCar() or H.over("rpwr", 5000) or (r and r.switchOn) end, function()
    if not (S.radioPart and H.inCar()) then return end
    local r = H.radioRead() or {}
    if S.dashPwr then Q.check(r.switchOn == true, "radio: a click on the dash's power turns the set on") end
    S.chBefore = r.channel
    local h, d = H.dashHit({ "tune" })
    if not h then Q.skip("the radio's TUNE from the dash", "no tuning knob on this dash: " .. H.ids(d and d._hit)); S.noTune = true; return end
    H.pressHit(d, h, 0.5, false)
end)
Q.waitFor(5, 600, function() local r = H.radioRead(); return not S.radioPart or S.noTune or not H.inCar() or H.over("rt1", 4000) or (r and r.channel ~= S.chBefore) end, function()
    if not (S.radioPart and H.inCar()) or S.noTune then return end
    local r, s = H.radioRead() or {}, H.st() or {}
    Q.check(r.channel ~= S.chBefore, "radio: a click on the dash's TUNE moves the frequency", tostring(S.chBefore) .. " -> " .. tostring(r.channel))
    Q.check((s.radioSwitch and true or false) == (r.switchOn and true or false), "radio: the dash reads the set's switch as the game has it")
    local h, d = H.dashHit({ "tune" })
    if h then H.rightHit(d, h, 0.5) end
end)
Q.waitFor(5, 600, function() local r = H.radioRead(); return not S.radioPart or S.noTune or not H.inCar() or H.over("rt2", 4000) or (r and r.channel == S.chBefore) end, function()
    if not (S.radioPart and H.inCar()) or S.noTune then return end
    Q.check((H.radioRead() or {}).channel == S.chBefore, "radio: a right click on TUNE tunes it back", tostring((H.radioRead() or {}).channel))
end)
-- the set up close and away, three times in a row, ending away
Q.step(5, function() if S.radioPart and H.inCar() then H.zed("the radio up close", S.R.toggle, S.p, S.radioPart) end end)
Q.waitFor(5, 300, function() return not S.radioPart or not H.inCar() or H.over("rup", 3000) or H.vis(H.radioProp()) end, function()
    if not (S.radioPart and H.inCar()) then return end
    Q.check(H.vis(H.radioProp()), "radio: the set comes up close")
    RT.bounds(Q, "the car radio up close")
    H.zed("the radio put away", S.R.toggle, S.p, S.radioPart)
end)
Q.step(3, function() if S.radioPart and H.inCar() then H.zed("the radio up close again", S.R.toggle, S.p, S.radioPart) end end)
Q.step(3, function() if S.radioPart and H.inCar() then H.zed("the radio put away again", S.R.toggle, S.p, S.radioPart) end end)
Q.step(10, function()
    if not (S.radioPart and H.inCar()) then return end
    Q.check(not H.vis(H.radioProp()), "radio: up, away, up, away in a row leaves it away")
    local r = H.radioRead() or {}
    if r.switchOn and not S.radioWas.on then pcall(S.O.power, S.p, S.radioPart) end
end)

-- ===================================================================== seats
Q.step(10, function() if H.inCar() then H.seatKey() end end)
Q.step(3, function() if H.inCar() then H.seatKey() end end)
Q.step(3, function() if H.inCar() then H.seatKey() end end)
Q.step(3, function() if H.inCar() then H.seatKey() end end)
Q.step(10, function()
    if not H.inCar() then return end
    Q.check(H.seatWin() == nil, "seats: the seat key four times in a row leaves ZeD's seat window shut")
    H.seatKey()
end)
Q.waitFor(5, 300, function() local w = H.seatWin(); return not H.inCar() or H.over("sw0", 3000) or (w ~= nil and w._seats ~= nil) end, function()
    if not H.inCar() then return end
    local w = H.seatWin()
    if not Q.check(w ~= nil and w._seats ~= nil, "seats: the seat key opens ZeD's seat window", tostring(w and w.Type)) then return end
    local n = 0
    pcall(function() n = S.v:getMaxPassengers() end)
    Q.check(#w._seats == n and w._seats[1] ~= nil and w._seats[1].kind == "you", "seats: every seat listed, the driver's seat yours", #w._seats .. " of " .. n .. ", seat 1 " .. tostring(w._seats[1] and w._seats[1].kind))
    RT.bounds(Q, "the seat window")
    H.zed("seats: the passenger seat picked", function() w:useSeat(1) end)
end)
Q.waitFor(5, 1800, function() return not H.inCar() or H.seat() == 1 or H.over("to1", 10000) end, function()
    if not H.inCar() then return end
    Q.check(H.seat() == 1, "seats: a pick in ZeD's seat window moves the character to the passenger seat", "seat " .. H.seat())
    Q.check(H.seatWin() == nil, "seats: the pick shuts the seat window")
end)
Q.waitFor(5, 300, function() local d = H.dash(); return H.seat() ~= 1 or H.over("pd", 3000) or (H.vis(d) and d._driver == false) end, function()
    if H.seat() ~= 1 then return end
    local d = H.dash()
    Q.check(H.vis(d) and d._driver == false and d.vehicle == S.v, "passenger: ZeD's dash stays up, read-only", "driver " .. tostring(d and d._driver))
    local okC, can = H.zed("passenger: canTakePad", S.D.canTakePad, S.p)
    if okC then Q.check(can == false, "passenger: the controller cannot take the dash") end
    S.lightsP, S.runP = H.headlights(), H.running()
    H.ignition()
    pcall(function() d:_fire("ignition", false); d:_fire("lights", false) end)
end)
Q.waitMs(1200)
Q.step(1, function()
    if H.seat() ~= 1 then return end
    -- (against what the engine and the lights were on arrival in the seat, not against "running")
    Q.check(H.running() == S.runP and H.headlights() == S.lightsP, "passenger: clicks on the dash's ignition and lights do nothing",
        "running " .. tostring(S.runP) .. " -> " .. tostring(H.running()) .. ", lights " .. tostring(S.lightsP) .. " -> " .. tostring(H.headlights()) .. ", busy " .. tostring(H.busy()))
    RT.bounds(Q, "the dash from the passenger seat")
    H.seatKey()
end)
Q.waitFor(5, 300, function() local w = H.seatWin(); return H.seat() ~= 1 or H.over("sw1", 3000) or (w ~= nil and w._seats ~= nil) end, function()
    if H.seat() ~= 1 then return end
    local w = H.seatWin()
    if not Q.check(w ~= nil and w._seats ~= nil, "seats: the seat key opens the seat window from the passenger seat") then return end
    Q.check(w._playerSeat == 1 and w._seats[2] and w._seats[2].kind == "you", "seats: the passenger seat is yours now",
        "seat " .. tostring(w._playerSeat) .. ", seat 2 " .. tostring(w._seats[2] and w._seats[2].kind) .. ", seat 1 " .. tostring(w._seats[1] and w._seats[1].kind))
    H.zed("seats: the driver's seat picked", function() w:useSeat(0) end)
end)
Q.waitFor(5, 1800, function() return not H.inCar() or H.seat() == 0 or H.over("to0", 10000) end, function()
    if not H.inCar() then return end
    Q.check(H.seat() == 0, "seats: a pick moves the character back to the wheel", "seat " .. H.seat())
end)
Q.waitFor(5, 300, function() local d = H.dash(); return H.seat() ~= 0 or H.over("dd", 3000) or (H.vis(d) and d._driver == true) end, function()
    if H.seat() ~= 0 then return end
    local d = H.dash()
    Q.check(H.vis(d) and d._driver == true, "seats: back at the wheel the dash is the driver's again", tostring(d and d._driver))
    -- out by the game's own Exit, the engine left running
    pcall(ISVehicleMenu.onExit, S.p)
end)
Q.waitFor(5, 1800, function() return S.p:getVehicle() == nil or H.over("exit", 8000) end, function()
    if not S.v then return end
    if S.p:getVehicle() ~= nil then
        Q.skip("out of the car by the game's Exit", "still seated after 8 s: taken out directly")
        H.stopActions()
        H.exitNow()
    end
end)
Q.waitFor(3, 300, function() return not S.v or H.over("dgone", 3000) or (S.p:getVehicle() == nil and not H.vis(H.dash())) end, function()
    if not S.v then return end
    Q.check(S.p:getVehicle() == nil and not H.vis(H.dash()), "exit: out of the car, ZeD's dash is put away", "dash " .. tostring(H.vis(H.dash())))
    Q.say("NOTE the hotwired engine after the exit: running " .. tostring(H.running()))
    -- in as passenger by the game's own Enter, interrupted
    pcall(ISVehicleMenu.onEnter, S.p, S.v, 1)
end)
Q.waitMs(350)
Q.step(1, function() if S.v and S.p:getVehicle() == nil then H.stopActions(); S.enterCut = true end end)
Q.waitMs(600)
Q.step(1, function()
    if not S.v then return end
    if S.enterCut and S.p:getVehicle() == nil then
        Q.check(not H.vis(H.dash()), "enter: interrupted on the way in, no dash shows")
    else
        Q.say("NOTE the character was seated before the interrupt could land")
    end
    if S.p:getVehicle() == nil then pcall(ISVehicleMenu.onEnter, S.p, S.v, 1) end
end)
Q.waitFor(5, 3000, function() return not S.v or H.inCar() or H.over("enter", 12000) end, function()
    if not S.v then return end
    if not H.inCar() then
        H.stopActions()
        local ok, why = ZEDQA_CAR_ENTER(S.v, 1)
        Q.skip("into the passenger seat by the game's Enter", "not seated after 12 s: seated directly (" .. tostring(ok) .. " " .. tostring(why) .. ")")
    end
end)
Q.waitFor(5, 300, function() local d = H.dash(); return not H.inCar() or H.over("pd2", 3000) or (H.vis(d) and d._driver == false) end, function()
    if not H.inCar() then Q.check(false, "enter: the character is in the car as a passenger"); return end
    local d = H.dash()
    Q.check(H.seat() == 1 and H.vis(d) and d._driver == false, "enter: in as a passenger, the dash shows read-only", "seat " .. H.seat() .. ", driver " .. tostring(d and d._driver))
    pcall(ISVehicleMenu.onSwitchSeat, S.p, 0)
end)
Q.waitFor(5, 1800, function() return not H.inCar() or H.seat() == 0 or H.over("to0b", 9000) end, function()
    if not S.v then return end
    if H.seat() ~= 0 then
        Q.skip("over to the wheel by the game's switch", "seat " .. H.seat() .. " after 9 s: seated directly")
        H.stopActions()
        H.exitNow()
        S.reseat = true
    end
end)
Q.step(20, function()
    if S.reseat then
        local ok, why = ZEDQA_CAR_ENTER(S.v, 0)
        if not ok then Q.say("NOTE the character could not be put at the wheel: " .. tostring(why)) end
    end
end)

-- ===================================================================== the crash
Q.waitFor(10, 300, function() local d = H.dash(); return not H.canDrive() or H.over("cd", 3000) or (H.vis(d) and d._driver == true) end, function()
    if not H.canDrive() then S.noDrive = "the character is not at the wheel"; return end
    -- a second car across the strip, 14 tiles ahead (the police car faces north)
    local vx, vy = math.floor(S.v:getX()), math.floor(S.v:getY())
    local spot = nil
    for _, dy in ipairs({ -14, -12, -16, -10 }) do
        if not spot and H.boxClear(vx - 3, vy + dy - 2, vx + 3, vy + dy + 2) and H.boxClear(vx - 1, vy + dy + 3, vx + 1, vy - 4) then spot = vy + dy end
    end
    if not spot then Q.say("NOTE no clear ground for a second car ahead: the car is sent down the strip with nothing staged in its way"); return end
    local t = nil
    pcall(function() t = addVehicleDebug("Base.CarNormal", IsoDirections.E, nil, getCell():getGridSquare(vx, spot, 0)) end)
    if not t then Q.say("NOTE the second car did not spawn"); return end
    S.t = t
    S.cars[#S.cars + 1] = t
    ZEDQA_CAR_KEEP[t] = true
    pcall(function() S.tKey = t:getKeyId(); S.tx, S.ty = t:getX(), t:getY() end)
end)
Q.waitFor(3, 900, function() return not S.t or ZEDQA_CAR_READY(S.t) or H.over("tready", 5000) end, function()
    if S.t then Q.say("NOTE the second car: ready " .. tostring(ZEDQA_CAR_READY(S.t)) .. ", " .. string.format("%.1f", H.dist(S.t)) .. " tiles ahead") end
    if H.canDrive() and not H.running() then S.t0 = getTimestampMs(); H.ignition() end
    RT.worldTab("vehicle")
end)
Q.waitFor(5, 900, function() return not H.canDrive() or H.running() or H.over("run2", 9000) end, function() end)
Q.step(3, function()
    if not H.canDrive() then S.noDrive = S.noDrive or "the character is not at the wheel"; return end
    S.sumV0 = H.condSum(S.v)
    S.sumT0 = S.t and H.condSum(S.t) or 0
    local L = { t0 = getTimestampMs(), max = 0, dashMax = 0, frames = 0, mag = 0.5, phase = "impulse", mass = 0, x0 = S.v:getX(), y0 = S.v:getY() }
    if H.has(S.v, "getMass") then pcall(function() L.mass = S.v:getMass() end) end
    if not L.mass or L.mass <= 0 then pcall(function() L.mass = S.v:getScript():getMass() end) end
    if not L.mass or L.mass <= 0 then L.mass = 1000 end
    L.canPush = H.has(S.v, "addImpulse") and Vector3f ~= nil
    if not L.canPush then Q.say("NOTE BaseVehicle.addImpulse or Vector3f is not open to Lua: the cruise control is tried") end
    S.L = L
end)
Q.waitFor(1, 3600, function() return H.over("drive", 20000) or H.drive() end, H.afterDrive)
Q.waitFor(10, 300, function() return not H.inCar() or H.over("agree", 2500) or H.dashAgrees() end, function()
    if not H.inCar() then return end
    local s = H.st() or {}
    local eng = 100
    pcall(function() eng = S.v:getPartById("Engine"):getCondition() end)
    Q.check(H.vis(H.dash()), "after the crash: ZeD's dash still shows")
    Q.check(s.engineCond == eng, "after the crash: the dash reads the engine's condition", tostring(s.engineCond) .. " / " .. tostring(eng))
    Q.check(s.hlL == H.partCond("HeadlightLeft") and s.hlR == H.partCond("HeadlightRight"), "after the crash: the dash reads both headlights' conditions",
        tostring(s.hlL) .. " " .. tostring(s.hlR) .. " / " .. tostring(H.partCond("HeadlightLeft")) .. " " .. tostring(H.partCond("HeadlightRight")))
    Q.check(s.battCond == H.partCond("Battery"), "after the crash: the dash reads the battery's condition", tostring(s.battCond) .. " / " .. tostring(H.partCond("Battery")))
    Q.check((s.running and true or false) == H.running(), "after the crash: the dash reads the engine running or stopped as the game has it", tostring(s.running) .. " / " .. tostring(H.running()))
    RT.bounds(Q, "the dash after the crash")
    if H.running() then H.ignition() end
end)
Q.waitFor(5, 900, function() return not H.inCar() or not H.running() or H.over("off", 7000) end, function()
    if not H.inCar() then return end
    Q.check(not H.running(), "after the crash: the engine is off (a click on the ignition where it still ran)")
    if H.running() and H.has(S.v, "shutOff") then pcall(function() S.v:shutOff() end) end
end)

-- ===================================================================== the Vehicle tab on the wreck
Q.waitFor(5, 600, function() return not S.v or H.speed(S.v) < 1 or H.over("still", 6000) end, function()
    if not (S.v and H.live(S.v)) then return end
    S.mechAsked = true
    pcall(ISVehicleMenu.onMechanic, S.p, S.v)
end)
Q.waitFor(10, 3600, function() return not S.mechAsked or H.inspected() or H.over("mech", 14000) end, function()
    if not S.mechAsked or H.inspected() then return end
    Q.skip("the game's own walk to the hood", "no inspection after 14 s (the wreck may be in the way): opened as the action's end does")
    H.stopActions()
    H.exitNow()
    S.mechDirect = true
end)
Q.step(20, function() if S.mechDirect and S.v then H.zed("the Vehicle tab opened on the car", S.MT.openFromAction, S.p, S.v) end end)
Q.waitFor(5, 300, function() return not S.mechAsked or H.inspected() or H.over("mech2", 4000) end, function()
    if not S.mechAsked then return end
    Q.check(H.inspected(), "Vehicle tab: the wreck inspected, the World window on its Vehicle tab")
end)
Q.step(30, function()
    if not (S.mechAsked and H.inspected()) then return end
    local s = H.ms()
    local cur = s and s.vehicles and s.vehicles[s.idx or 1]
    Q.check(cur ~= nil and cur.vehicle == S.v, "Vehicle tab: its page is the crashed car's")
    local list = (s and s.partsCache and s.partsCache.list) or {}
    local bad, worst = {}, nil
    for _, m in ipairs(list) do
        local want = nil
        pcall(function() want = m.missing and 0 or m.part:getCondition() end)
        if want ~= m.cond then bad[#bad + 1] = tostring(m.id) .. " " .. tostring(m.cond) .. "/" .. tostring(want) end
        if not m.missing and (worst == nil or m.cond < worst.cond) then worst = m end
    end
    Q.check(#list > 0 and #bad == 0, "Vehicle tab: every part's condition is the game's after the crash", #list .. " parts" .. (#bad > 0 and (", wrong: " .. table.concat(bad, ", ")) or ""))
    Q.check(s and s.lastRows and #s.lastRows > 0, "Vehicle tab: the parts' rows are drawn", s and s.lastRows and #s.lastRows)
    RT.bounds(Q, "the Vehicle tab on the wreck")
    S.card = worst and worst.id
    local z = S.card and H.zone("mech:row:" .. S.card)
    if z then H.zed("a click on the worst part's row", z.fn) else S.card = nil end
    Q.say("NOTE the worst part: " .. tostring(S.card) .. " at " .. tostring(worst and worst.cond))
end)
Q.step(20, function()
    if not (S.mechAsked and S.card) then return end
    local s = H.ms()
    Q.check(s and s.card == S.card, "Vehicle tab: the worst part's row opens its card", tostring(s and s.card) .. " (want " .. tostring(S.card) .. ")")
    RT.bounds(Q, "the wrecked part's card")
end)

-- ===================================================================== the injury shown
Q.step(5, function()
    if S.p:isDead() then return end
    local n = H.woundCheck("after the crash")
    local godNow = nil
    pcall(function() godNow = S.p:isGodMod() end)
    Q.say("NOTE wounds from the crash itself: " .. tostring(n) .. " (god mode " .. tostring(godNow) .. ")")
    -- one scratch, as a crash gives (under god mode the body heals every tick, so god mode goes off for about a
    -- second): only on foot, with nothing queued, god mode able to come back and no zombie within 10 tiles, as nothing
    -- else here can hurt him in that second. The watch turns god mode on again if the next steps never come.
    -- (Invincible is set too, as the rule asks; the game reads it for no player in 42.22.)
    local why = nil
    if S.p:getVehicle() ~= nil then why = "the character is still in the car: the scratch is staged on foot only"
    elseif S.unsafe then why = "god mode could not be turned on for the run: no scratch staged"
    else
        local okZ, zd = H.zombieNear(10)
        if not okZ then why = "the zombies near could not be read: god mode stays on, no scratch staged"
        elseif zd then why = string.format("a zombie %.1f tiles away: god mode stays on, no scratch staged", zd) end
    end
    if why then Q.skip("the crash injury in the Health tab", why); return end
    H.stopActions()
    pcall(function() S.p:setInvincible(true) end)
    pcall(function()
        local bp = S.p:getBodyDamage():getBodyPart(BodyPartType.ForeArm_L)
        S.godOff, S.godOffAt = true, getTimestampMs()
        S.p:setGodMod(false)
        bp:setScratched(true, true)
        S.inj = bp
        S.scratchStaged = true
    end)
    if not S.inj then H.godBack() end
    RT.charTab("health")
end)
Q.waitMs(900)
Q.step(1, function()
    local has = false
    if S.inj then pcall(function() has = S.inj:scratched() end) end
    if not S.inj then
        -- (nothing was staged: said above)
    elseif not has then
        Q.skip("the crash injury in the Health tab", "the staged scratch did not hold")
    else
        local n, data = H.woundCheck("a scratch on the left forearm")
        local cw = RT.cw()
        Q.check(cw ~= nil and cw._activeTab == "health", "health: the Character window is on its Health tab", tostring(cw and cw._activeTab))
        Q.check(data ~= nil and (data.woundedCount or 0) >= 1, "health: ZeD counts the wounded part", tostring(data and data.woundedCount))
        RT.bounds(Q, "the Health tab with the injury")
    end
    H.heal()
    H.godBack()
    S.inj = nil
end)
Q.step(10, function()
    local bad = H.hurt()
    local god = false
    pcall(function() god = S.p:isGodMod() end)
    if not god and not S.unsafe then bad[#bad + 1] = "god mode off" end
    Q.check(#bad == 0, S.scratchStaged and "health: the staged scratch is healed, god mode on again" or "health: the character is unhurt after the crash",
        (#bad > 0) and table.concat(bad, ", ") or nil)
    if #bad > 0 then H.heal(); H.godBack() end
end)

-- ===================================================================== the car removed while ZeD shows it
Q.step(10, function()
    if not (S.v and H.live(S.v)) or S.p:getVehicle() ~= nil then return end
    if H.dist(S.v) < 5.5 then H.seatKey(S.v) end
end)
Q.waitMs(500)
Q.step(1, function()
    if not (S.v and H.live(S.v)) then return end
    if S.p:getVehicle() ~= nil then Q.skip("a car removed while its Vehicle tab is open", "the character is still in a car"); return end
    local s, win = H.ms(), RT.ww()
    Q.say("NOTE before the removal: inspected " .. tostring(H.inspected()) .. ", card " .. tostring(s and s.card) .. ", seat window "
        .. tostring(H.seatWin() ~= nil) .. ", tab " .. tostring(win and win._activeTab))
    if S.hornOn and H.has(S.v, "onHornStop") then pcall(function() S.v:onHornStop() end) end
    H.stopActions()   -- (no action of the game's left queued on a car about to go)
    ZEDQA_CAR_KEEP[S.v] = nil
    S.rmDone = pcall(function() S.v:permanentlyRemove() end)
    -- in the same tick, on what ZeD still holds from the last frame
    local z = s and s.lastRows and s.lastRows[1]
    if win and z then H.zed("a click on a row of the car just removed", S.MT.onClick, win, z.x + 2, z.y + 2) end
    if win then
        H.zed("the tab's refresh with the car just removed", S.MT.refresh, win)
        H.zed("the tab's controller stops with the car just removed", S.MT.buildFocusables, win)
    end
end)
Q.waitMs(1500)
Q.step(1, function()
    if not S.rmDone then return end
    local s, win = H.ms(), RT.ww()
    Q.check(not H.live(S.v), "removed: the car is gone from the world")
    local okI, insp = H.zed("removed: isInspected on the car that is gone", S.MT.isInspected, S.v)
    if okI then Q.check(insp == false, "removed with its Vehicle tab open: the inspection ended", tostring(insp)) end
    local listed = false
    for _, e in ipairs((s and s.vehicles) or {}) do if e.vehicle == S.v then listed = true end end
    Q.check(not listed, "removed: the Vehicle tab no longer lists the car")
    Q.check(s ~= nil and s.card == nil, "removed: the part's card closed", tostring(s and s.card))
    Q.check(H.seatWin() == nil, "removed: ZeD's seat window for the car closed")
    Q.check(not H.vis(H.dash()), "removed: no dash shows")
    Q.check(win ~= nil and H.vis(win), "removed: the World window stays up")
    Q.say("NOTE after the removal: World tab " .. tostring(win and win._activeTab) .. ", tabs offered: " .. table.concat(RT.tabs(RT.worldStrip()), " "))
    RT.bounds(Q, "after the car was removed")
end)

-- ===================================================================== on foot: into the second car
Q.step(10, function()
    H.stopActions()
    if S.p:getVehicle() ~= nil then H.exitNow() end
    if not (S.tKey and S.tx) then Q.skip("a sprint on foot into a car", "no second car was spawned"); return end
    if not H.loaded(S.tx, S.ty) then Q.skip("a sprint on foot into a car", "the second car's ground is not loaded from here"); return end
    if S.t and not H.live(S.t) then S.t = H.findKey(S.tKey); if S.t then S.cars[#S.cars + 1] = S.t end end
    if not S.t then Q.skip("a sprint on foot into a car", "the second car is not in the world any more"); return end
    local cx, cy = S.t:getX(), S.t:getY()
    S.tx, S.ty = cx, cy
    local pick = nil
    for _, d in ipairs({ { 0, -1 }, { 0, 1 }, { 1, 0 }, { -1, 0 } }) do
        local sx, sy = math.floor(cx - d[1] * 8), math.floor(cy - d[2] * 8)
        local okLane = true
        for i = 0, 4 do if not H.clearAt(sx + d[1] * i, sy + d[2] * i) then okLane = false end end
        if not pick and okLane then pick = { sx + 0.5, sy + 0.5 } end
    end
    if not pick then Q.skip("a sprint on foot into a car", "no clear run of 5 tiles to the second car from any side"); return end
    local dx, dy = cx - pick[1], cy - pick[2]
    local len = math.sqrt(dx * dx + dy * dy)
    S.sp.car = { sx = pick[1], sy = pick[2], dx = dx / len, dy = dy / len, len = len, block = true }
    H.tp(pick[1], pick[2])
end)
H.queueSprint("car", "sprint into a car")
Q.step(10, function()
    -- the second car taken away where it stands (the character is on foot)
    if S.t and H.live(S.t) and S.p:getVehicle() == nil then
        ZEDQA_CAR_KEEP[S.t] = nil
        if pcall(function() S.t:permanentlyRemove() end) then S.tRemoved = true end
    end
end)

-- ===================================================================== on foot: into a wall, into a fence
Q.step(10, function()
    S.moved = ZEDQA_HOME and ZEDQA_HOME("bx_veh") or false
end)
Q.waitFor(5, 1800, function() return H.over("homeMax", 15000) or (H.loaded(925, 13040) and (not S.moved or H.over("home", 3000))) end, function()
    if S.unsafe then Q.skip("sprints into a wall and a fence", "god mode could not be turned on for the run"); return end
    S.site = H.lane()
    if not S.site then Q.skip("sprints into a wall and a fence", "no clear lane of open ground 12 x 3 near home"); return end
    H.stageBarrier("wall", "walls_exterior_wooden_01_40", false, "a wall")
end)
H.queueSprint("wall", "sprint into a wall")
Q.step(10, function()
    local left = H.unbuild()
    if S.sp.wall then Q.check(left == 0, "the staged wall is taken down", left .. " piece(s) left") end
    H.stageBarrier("fence", "carpentry_02_48", true, "a low fence")
end)
H.queueSprint("fence", "sprint into a low fence")
Q.step(10, function()
    local c = S.sp.fence
    if c and c.ran then Q.say("NOTE the fence: the character " .. ((c.far > c.len + 0.3) and "went over it" or "stopped at it")) end
    local left = H.unbuild()
    if c then Q.check(left == 0, "the staged fence is taken down", left .. " piece(s) left") end
end)

-- ===================================================================== put back
Q.mark()
-- the character first, in a step of its own: healed, god mode and invincible on (they go back as found only in the
-- last step, once the body is read healed). Each line below is its own pcall: one that throws stops none of the rest.
Q.step(5, function()
    H.heal()
    H.godBack()
    S.inj = nil
end)
Q.step(2, function()
    pcall(H.walk, 0, 0, false)
    pcall(H.stopActions)
    pcall(function() local pr = H.radioProp(); if H.vis(pr) then pr:close() end end)
    pcall(function() local w = H.seatWin(); if w then w:close() end end)
    pcall(function()
        if S.v and H.live(S.v) then
            H.cruise(false)
            if H.has(S.v, "onHornStop") then S.v:onHornStop() end
        end
    end)
    pcall(H.exitNow)
    pcall(H.unbuild)
    if S.perks then
        pcall(function() S.p:setPerkLevelDebug(Perks.Electricity, S.elecWas); S.p:setPerkLevelDebug(Perks.Mechanics, S.mechWas) end)
    end
    if S.key then pcall(function() S.p:getInventory():Remove(S.key) end) end
    if ZEDQA_SPEED then pcall(ZEDQA_SPEED, 1) else pcall(setGameSpeed, 1) end
    H.heal()
end)
Q.step(20, function()
    -- every car still in the world, the character out of it since the last step
    for _, c in ipairs(S.cars) do
        if ZEDQA_CAR_KEEP then ZEDQA_CAR_KEEP[c] = nil end
        if H.live(c) and S.p:getVehicle() ~= c then
            pcall(function() c:permanentlyRemove() end)
            if c == S.t then S.tRemoved = true end
        end
    end
    -- the second car, when it stands outside the loaded ground: the character goes to it
    local t = S.tKey and H.findKey(S.tKey)
    if t and S.p:getVehicle() ~= t then pcall(function() t:permanentlyRemove() end); S.tRemoved = true end
    S.chase = S.tKey ~= nil and S.tx ~= nil and not S.tRemoved and not H.loaded(S.tx, S.ty)
    if S.chase then H.tp(math.floor(S.tx) + 4.5, math.floor(S.ty) + 0.5) end
end)
Q.waitFor(5, 1800, function() return not S.chase or H.over("chaseMax", 14000) or (H.loaded(S.tx, S.ty) and H.over("chase", 2500)) end, function()
    if not S.chase then return end
    local t = H.findKey(S.tKey)
    Q.say("NOTE the second car looked for where it stood: " .. (t and "found, removed" or "not there (already gone)"))
    if t then pcall(function() t:permanentlyRemove() end) end
end)
Q.step(10, function()
    if ZEDQA_HOME then pcall(ZEDQA_HOME, "bx_veh") end
    if S.charTabWas then pcall(RT.charTab, S.charTabWas) end
    pcall(RT.worldTab, S.worldTabWas or "loot")
    if S.pairWas == false then pcall(RT.pairShut) end
end)
Q.waitFor(10, 900, function()
    if H.over("gone", 8000) then return true end
    for _, c in ipairs(S.cars) do if H.live(c) then return false end end
    return S.p:getVehicle() == nil
end, function()
    local left = 0
    for _, c in ipairs(S.cars) do if H.live(c) then left = left + 1 end end
    if S.tKey and H.findKey(S.tKey) then left = left + 1 end
    local keyLeft = false
    pcall(function() keyLeft = S.key ~= nil and S.p:getInventory():contains(S.key) end)
    Q.check(left == 0 and S.p:getVehicle() == nil and not keyLeft, "put back: every car removed, the character on foot, no key kept", left .. " car(s) left")
    if S.elecWas ~= nil then
        Q.check(S.p:getPerkLevel(Perks.Electricity) == S.elecWas and S.p:getPerkLevel(Perks.Mechanics) == S.mechWas, "put back: Electricity and Mechanics as found",
            S.p:getPerkLevel(Perks.Electricity) .. " / " .. S.p:getPerkLevel(Perks.Mechanics))
    end
    Q.check(#S.built == 0 and (S.builtLeft or 0) == 0, "put back: nothing built is left on the strip")
    Q.check(math.abs(S.p:getX() - 925.5) <= 3 and math.abs(S.p:getY() - 13040.5) <= 3, "put back: the character is home on the strip",
        math.floor(S.p:getX()) .. "," .. math.floor(S.p:getY()))
    Q.check(getGameSpeed() == 1, "put back: game speed 1", tostring(getGameSpeed()))
end)
-- the character last: read healed, and only then god mode and invincible as found. Read hurt: healed once more and
-- read again, and god mode and invincible are LEFT ON whatever was found (said in the FAIL line).
Q.step(10, function()
    local bad = H.hurt()
    S.hurt1 = bad
    if #bad > 0 then H.safeOn(); H.heal() end
end)
Q.step(10, function()
    -- the watch ends here, first, so a throw below cannot leave it on: a watch left on would hold god mode on through
    -- the next scripts (god mode itself stays on from the put-back's first step until the body reads healed)
    S.done = true
    pcall(function() Events.OnTick.Remove(H.guard) end)
    if ZEDQA_BXVEH_GUARD == H.guard then ZEDQA_BXVEH_GUARD = nil end
    local first = S.hurt1 or {}
    local bad = H.hurt()
    local overall = -1
    pcall(function() overall = S.p:getBodyDamage():getOverallBodyHealth() end)
    Q.check(#first == 0 and #bad == 0, "put back: the character is alive and healed (health 100, no wound and no fracture on any part, not infected)",
        string.format("health %.1f", overall) .. (#first > 0 and ("; found at the put-back: " .. table.concat(first, ", ")) or "")
        .. (#bad > 0 and ("; STILL after a second heal: " .. table.concat(bad, ", ") .. "; god mode and invincible are left ON") or ""))
    if (S.guardHeals or 0) > 0 or (S.guardSaid or 0) > 0 then
        Q.say("NOTE the guard stepped in during the run: " .. tostring(S.guardHeals or 0) .. " heal(s), " .. tostring(S.guardSaid or 0) .. " god mode left off")
    end
    -- god mode and invincible as found only for a healed character
    if #bad == 0 then
        if S.invWas ~= nil then pcall(function() S.p:setInvincible(S.invWas) end) end
        if S.godWas ~= nil then pcall(function() S.p:setGodMod(S.godWas) end) end
    else
        H.safeOn()
    end
    local god, inv = nil, nil
    pcall(function() god = S.p:isGodMod() end)
    pcall(function() inv = S.p:isInvincible() end)
    Q.check(#bad == 0 and (S.godWas == nil or god == S.godWas) and (S.invWas == nil or inv == S.invWas), "put back: god mode and invincible as found",
        "god mode " .. tostring(god) .. " (found " .. tostring(S.godWas) .. "), invincible " .. tostring(inv) .. " (found " .. tostring(S.invWas) .. ")")
end)
Q.start()
