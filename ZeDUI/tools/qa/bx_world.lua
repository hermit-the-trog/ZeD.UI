-- ZeDUI/tools/qa/bx_world.lua  (Nov 21 2026, QA beast day; tag bx_wld): turn things on and use the world, fast and in
-- odd orders, with ZeD's windows open. Built on rt_kit.lua (the global RT); run after zedqa_prelude.lua and rt_kit.lua.
-- grep "ZEDQA bx_wld".
--
-- AT HOME (the drag strip):
--   generator   ZeD's power card (ObjectCardPower.lua) on a generator set down two squares off: a press on the dead
--               switch; Connect on the card; the engine switch on; both windows closed and opened while it runs; every
--               World tab pressed in one frame; five presses on the switch in one frame; the tank emptied while it
--               runs; Add on a petrol can's row; the generator taken out of the world while its card shows. The Lights
--               wheel's generator slice (ZeD_DpadWheels.lua) is read beside the card each time.
--   emote wheel the game's emote wheel drawn ZeD's way (Overrides/Wheels.lua, ZeD_Wheel.lua): opened twice in one frame,
--               a click on a group, a click on an emote (the game's emote runs), a click in the dead middle, the
--               windows closed and opened under it.
--   sit, sneak  the Sit wheel's slices: sit on the ground, crouch pressed while sitting, the windows closed and opened,
--               get up; the crouch slice five times in one frame; auto-walk on and off in one frame.
--   reader      a newspaper read to the end opens ZeD's reader (ZeD_Reader.lua): six view switches, ten zooms in,
--               fourteen out, the wheel at both ends, the newspaper taken away while open; a flyer read while the
--               reader is up; Escape. A skill book: the action bar names the read, the windows closed and opened
--               mid-read, the read stopped. A magazine taken out of the bags mid-read.
-- IN THE NEAREST BUILDING (rooms within 40 tiles of home; doors, windows, switches, a toilet and water looked for
-- within 46, because the one known toilet, in the grandstand, is 43 tiles off; the character comes back):
--   TV, radio   a TV and a house radio beside the character on the grid: the World window's Radio tab lists both; the
--               TV's power, CH up, thirty volume-ups and forty volume-downs in one frame, three power presses in one
--               frame, the grid cut while it plays; the radio's power; the TV taken away while its face shows, then
--               the radio.
--   stove       a range beside the character: in the Loot list, bound in the Craft tab (Stations.lua), its switch
--               turned five times in one frame, taken out of the world while bound.
--   light       the Lights wheel's Room lights slice beside a switch: with power it flips the switch and follows it,
--               four presses in one frame; with the power cut it is off with its reason.
--   door        ZeD's menu on it; opened and closed, six uses in one frame; a plank nailed across it; ZeD's menu on
--               the barricaded door; the game's walk-and-use cut short at once.
--   window      ZeD's menu on it; opened and closed, five uses in one frame; curtains (a sheet hung when it has none)
--               used five times; smashed; climbed through.
--   toilet      ZeD's menu on it; the Sit wheel's seat slice sits the character on the nearest seat, Get up.
--   wash        a dirty T-shirt washed at the nearest water (the game's own action); washed again and taken out of
--               the bags mid-wash.
--   fence       a low fence climbed with the windows open.
-- After each act the checks compare what ZeD shows (the card's own data, the tab's list, the wheel's slices, the
-- action bar's state) with the game, and RT.bounds measures every ZeD surface.
-- Not here: the sprint and walk toggles (the game's keys; ZeD's own part, the Run button's sneak, is
-- zedqa_run_sneak.lua) and the padlock card (ObjectCardLock.lua needs a built crate; rt_cards.lua has the lock rows).
-- Put back: everything set down is taken away (generator, TV, radio, stove, plank, sheet), the door, window, curtains
-- and light switch as found, broken glass swept, the grid as found, every item the run gave or the game handed over
-- taken out of the main inventory, the hands as found, the character healed, standing, not crouched, at home, the
-- instant-action cheat as found, game speed 1, both windows on Loot and open or shut as found.
-- The character: god mode and invincible are ON from the first line to the last step (the smashed window scratches
-- whoever climbs it, and the noise calls zombies); a building's alarm is switched off before the run goes in and back
-- on once the game has him home. The last step heals him, reads the body back from the game and prints "put back: the
-- character is alive and healed" as a PASS or FAIL; god mode and invincible go back as found only when he is whole
-- and home. Each piece of the put-back runs on its own, so an error in one never skips the heal.

if not RT then
    print("ZEDQA bx_wld FAIL the kit (rt_kit.lua) is not loaded")
    print("ZEDQA bx_wld VERDICT FAIL 1")
    print("ZEDQA bx_wld DONE")
    return
end
if ZEDQA_HOME then pcall(ZEDQA_HOME, "bx_wld") end
local Q = RT.make("bx_wld")
Q.maxMs = 390000                      -- (the whole run fits 8 minutes: past 6.5 the queue jumps to the put-back)
local p, pn = RT.p, RT.pn
local S = { placed = {}, R = 46, ROOM_R = 40 }
local H = {}
S.RING2 = { { 2, 0 }, { -2, 0 }, { 0, 2 }, { 0, -2 }, { 2, 2 }, { -2, -2 }, { 2, -2 }, { -2, 2 }, { 3, 0 }, { -3, 0 } }
S.RING1 = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }
S.STAND = { { 0, 0 }, { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
if not p or p:isDead() then
    Q.step(2, function() Q.check(false, "a living character to test with") end)
    Q.start()
    return
end
-- (Nov 21 2026, QA, the preflight: the run goes into a building 40 tiles off, smashes a window and climbs through the
-- broken glass (the game scratches whoever does), and its noise calls zombies. God mode and invincible go ON here,
-- before the first step, whatever the script before left, and stay on to the very end; the put-back heals him, says
-- so in a PASS / FAIL line, and only then puts the two cheats back as found.)
S.alarms = {}
pcall(function() S.godWas = p:isGodMod() and true or false end)
pcall(function() S.invWas = p:isInvincible() and true or false end)
pcall(function() p:setGodMod(true) end)
pcall(function() p:setInvincible(true) end)

-- ===================================================================== helpers
-- god mode and invincible on (called again at every move and at the put-back: nothing may switch them off mid-run)
function H.guard()
    pcall(function() if not p:isGodMod() then p:setGodMod(true) end end)
    pcall(function() if not p:isInvincible() then p:setInvincible(true) end end)
end
-- every wound off every part, then the game's own full heal (each call on its own, with the game's argument counts,
-- so one refused call never stops the rest)
function H.healAll()
    local bd = nil
    pcall(function() bd = p:getBodyDamage() end)
    if not bd then return end
    local parts = nil
    pcall(function() parts = bd:getBodyParts() end)
    for i = 0, (parts and parts:size() or 0) - 1 do
        local b = parts:get(i)
        pcall(function() b:setHaveGlass(false) end)
        pcall(function() b:setHaveBullet(false, 0) end)
        pcall(function() b:SetBitten(false) end)
        pcall(function() b:SetInfected(false) end)
        pcall(function() b:setInfectedWound(false) end)
        pcall(function() b:setFractureTime(0) end)
        pcall(function() b:setBurnTime(0) end)
        pcall(function() b:RestoreToFullHealth() end)
    end
    pcall(function() bd:RestoreToFullHealth() end)
end
-- what is still wrong with the body, in words ("" when he is whole)
function H.hurt()
    local bad = {}
    local okD, dead = pcall(function() return p:isDead() end)
    if not okD or dead then bad[#bad + 1] = "dead" end
    local ok, err = pcall(function()
        local bd = p:getBodyDamage()
        if bd:getOverallBodyHealth() < 99.5 then bad[#bad + 1] = "health " .. tostring(bd:getOverallBodyHealth()) end
        if bd:IsInfected() then bad[#bad + 1] = "infected" end
        local parts = bd:getBodyParts()
        for i = 0, parts:size() - 1 do
            local b = parts:get(i)
            if b:scratched() or b:isCut() or b:deepWounded() or b:bitten() or b:bleeding() or b:getFractureTime() > 0 or b:getBurnTime() > 0
                or b:haveGlass() or b:haveBullet() or b:isInfectedWound() or b:IsInfected() then
                bad[#bad + 1] = "a wound on part " .. i
            end
        end
    end)
    if not ok then bad[#bad + 1] = "the body could not be read (" .. tostring(err) .. ")" end
    return table.concat(bad, ", ")
end
-- a house alarm rings at a window opened or smashed and at a step inside, and calls every zombie around: the
-- building's alarm is switched off before the run touches it, and back on at the put-back
function H.disarm(sq)
    pcall(function()
        local b = sq and sq:getBuilding()
        local def = b and b:getDef()
        if def and def:isAlarmed() then
            def:setAlarmed(false)
            S.alarms[#S.alarms + 1] = def
            Q.say("NOTE the alarm of the building at " .. sq:getX() .. "," .. sq:getY() .. " is off for the run, back on at the put-back")
        end
    end)
end
-- a wait in real time: every frame until cond() holds or ms have passed, then fn(held)
function H.wait(ms, cond, fn)
    local st = {}
    Q.waitFor(1, 1000000, function()
        st.t = st.t or getTimestampMs()
        local ok, v = pcall(cond)
        if ok and v then st.ok = true; return true end
        return getTimestampMs() - st.t >= ms
    end, function() fn(st.ok == true) end)
end
-- ZeD code under test: an error it throws is a FAIL line, and the script goes on
function H.try(what, fn, ...)
    if type(fn) ~= "function" then Q.check(false, what .. ": the function is there"); return false end
    local ok, r = pcall(fn, ...)
    if not ok then Q.check(false, what .. " ran without an error", tostring(r)) end
    return ok, r
end
function H.errN()
    if not getLuaDebuggerErrorCount then return nil end
    local ok, n = pcall(getLuaDebuggerErrorCount)
    return ok and n or nil
end
function H.begin(name) S.sceneErr = H.errN(); Q.say("scene: " .. name) end
function H.fin(name)
    local n = H.errN()
    if n ~= nil and S.sceneErr ~= nil and n > S.sceneErr then
        Q.say("NOTE " .. name .. ": " .. (n - S.sceneErr) .. " Lua errors were logged during this scene (console.txt has them)")
    end
    RT.bounds(Q, "the end of " .. name)
end
function H.errMark() S.em = H.errN() end
function H.errCheck(label)
    local n = H.errN()
    if n == nil or S.em == nil then return end
    Q.check(n == S.em, label .. ": no Lua error logged", (n - S.em) .. " new")
end
function H.sq(x, y, z) return getCell():getGridSquare(x, y, z) end
function H.freeSq(x, y, z)
    local sq = H.sq(x, y, z)
    if sq and sq:isFree(false) and sq:getVehicleContainer() == nil then return sq end
    return nil
end
function H.freeNear(offsets)
    local px, py, pz = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    for _, o in ipairs(offsets) do
        local sq = H.freeSq(px + o[1], py + o[2], pz)
        if sq and not sq:HasTree() then return sq end
    end
    return nil
end
function H.moveTo(x, y, z)
    H.guard()
    H.disarm(H.sq(math.floor(x), math.floor(y), math.floor(z)))
    pcall(function() p:teleportTo(x, y, z) end)
    p:setX(x); p:setY(y); p:setZ(z); p:setLastX(x); p:setLastY(y); p:setLastZ(z)
    S.moved = true
    S.at = { x = math.floor(x), y = math.floor(y) }
end
function H.moveToSq(sq) H.moveTo(sq:getX() + 0.5, sq:getY() + 0.5, sq:getZ()) end
-- after a move: the game has the character on the square he was sent to (no blind wait), 1.5 s at most
function H.arrive()
    H.wait(1500, function()
        local sq = p:getCurrentSquare()
        return S.at == nil or (sq ~= nil and sq:getX() == S.at.x and sq:getY() == S.at.y)
    end, function() end)
end
-- a free square to stand on: the square itself, else one beside it (inRoom: in the same room)
function H.standBy(sq, inRoom)
    if not sq then return nil end
    local room = sq:getRoom()
    for _, o in ipairs(S.STAND) do
        local n = H.freeSq(sq:getX() + o[1], sq:getY() + o[2], sq:getZ())
        if n and (not inRoom or (n:getRoom() ~= nil and n:getRoom() == room)) then return n end
    end
    return nil
end
function H.queue()
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    return q and q.queue or {}
end
function H.queueEmpty() return #H.queue() == 0 end
function H.queueHas(pat)
    for _, a in ipairs(H.queue()) do if string.find(tostring(a.Type), pat, 1, true) then return true end end
    return false
end
function H.queueTypes()
    local t = {}
    for _, a in ipairs(H.queue()) do t[#t + 1] = tostring(a.Type) end
    return (#t > 0) and table.concat(t, " ") or "nothing queued"
end
function H.stop() pcall(function() p:StopAllActionQueue() end); pcall(function() ISTimedActionQueue.clear(p) end) end
function H.cheat(on) pcall(function() p:setTimedActionInstantCheat(on and true or false) end) end
-- the action bar's state for the character (ZeD_ActionBar.lua), nil when it shows nothing
function H.ab()
    local AB = ZeD.ActionBar
    if not (AB and AB.state) then return nil end
    local ok, st = pcall(AB.state, p, pn)
    return ok and st or nil
end
function H.abWork() local st = H.ab(); return st ~= nil and st.phase == "work" end
function H.removeObj(obj)
    if not obj then return end
    local sq = obj:getSquare()
    if sq then
        pcall(function() sq:transmitRemoveItemFromSquare(obj) end)
        pcall(function() if obj:getObjectIndex() >= 0 then sq:RemoveTileObject(obj) end end)
    end
    if instanceof(obj, "IsoGenerator") then pcall(function() if obj:getObjectIndex() >= 0 then obj:remove() end end) end
end
function H.giveFirst(list)
    for _, ft in ipairs(list) do
        local it = RT.give(ft)
        if it then return it end
    end
    return nil
end
-- the main inventory as found, and everything in it that was not there then taken out
function H.snapInv()
    S.inv0 = {}
    local items = p:getInventory():getItems()
    for i = 0, items:size() - 1 do S.inv0[items:get(i)] = true end
end
function H.sweepInv()
    if not S.inv0 then return 0 end
    local inv = p:getInventory()
    local items = inv:getItems()
    local extra = {}
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if not S.inv0[it] then extra[#extra + 1] = it end
    end
    for _, it in ipairs(extra) do
        if p:getPrimaryHandItem() == it then p:setPrimaryHandItem(nil) end
        if p:getSecondaryHandItem() == it then p:setSecondaryHandItem(nil) end
        pcall(function() inv:Remove(it) end)
    end
    return #extra
end
function H.newItems()
    if not S.inv0 then return 0 end
    local items = p:getInventory():getItems()
    local n = 0
    for i = 0, items:size() - 1 do if not S.inv0[items:get(i)] then n = n + 1 end end
    return n
end
function H.standUp()
    pcall(function() p:setVariable("forceGetUp", true) end)
    pcall(function() p:setSitOnGround(false) end)
end

-- ---- ZeD's surfaces
function H.ocard() local c = nil; pcall(function() c = ZeD_WorldWindow.getObjectCard(pn) end); return c end
function H.entry() local c = H.ocard(); return c and c.entry or nil end
function H.kind() local e = H.entry(); return e and e.def and e.def.id or nil end
function H.cardD(kind)
    local e = H.entry()
    if e and e.def and e.def.id == kind and e.t then return e.t.d end
    return nil
end
function H.closeCard() pcall(function() ZeD_WorldWindow.closeObjectCard(pn) end) end
function H.pill(e)
    if not (e and e.def and e.def.pill) then return nil end
    local ok, words = pcall(e.def.pill, e.t)
    return ok and words or nil
end
function H.zoneFid(fid)
    local c = H.ocard()
    if not c then return nil end
    for _, z in ipairs(c._lastZones or {}) do if z.fid == fid then return z end end
    for _, z in ipairs(c._zones or {}) do if z.fid == fid then return z end end
    return nil
end
function H.verb(id)
    local e = H.entry()
    for _, v in ipairs((e and e.t and e.t.verbs) or {}) do if v.id == id then return v end end
    return nil
end
function H.wwUp() local w = RT.ww(); return w ~= nil and w:isVisible() end
function H.inList(inv)
    local w = RT.ww()
    if not (w and inv) then return nil end
    for _, c in ipairs(w._containers or {}) do if c.inventory == inv then return c end end
    return nil
end
function H.DW() return ZeD.DpadWheels end
function H.lights()
    local D = H.DW()
    if not (D and D.H and D.H.lights) then return {} end
    local ok, sl = pcall(D.H.lights, p, pn)
    if not ok then Q.check(false, "the Lights wheel's slices built without an error", tostring(sl)); return {} end
    return sl or {}
end
function H.sits()
    local D = H.DW()
    if not (D and D.H and D.H.sitWheel) then return {} end
    local ok, sl = pcall(D.H.sitWheel, p, pn)
    if not ok then Q.check(false, "the Sit wheel's slices built without an error", tostring(sl)); return {} end
    return sl or {}
end
function H.take(e)
    local D = H.DW()
    if not (D and D.take and e) then return false end
    return H.try("a wheel slice (" .. tostring(e.name or e.icon) .. ")", D.take, pn, e)
end
function H.menu()
    local v = getPlayerContextMenu(pn)
    return v and v._zedMenu or nil
end
function H.menuCount(m)
    local lv = m._levels and m._levels[1]
    if lv then return #(lv.rows or {}) end
    return #((m._ctx and m._ctx.items) or {})
end
function H.closeMenu()
    local m = H.menu()
    if m then pcall(function() m:close() end) end
    local v = getPlayerContextMenu(pn)
    if v and v.closeAll and v:isVisible() then pcall(function() v:closeAll() end) end
end
-- ZeD's menu on a world object: the game's own menu builder (ZeD's hook on it), the menu a frame later
function H.worldMenu(label, getObj)
    Q.step(3, function()
        H.closeMenu()
        local obj = getObj()
        S.menuArm = obj ~= nil
        if not obj then return end
        local mx, my = math.floor(RT.core:getScreenWidth() * 0.45), math.floor(RT.core:getScreenHeight() * 0.4)
        S.menuArm = H.try(label .. ": the menu on it", ISWorldObjectContextMenu.createMenu, pn, { obj }, mx, my, false)
    end)
    H.wait(1200, function() return not S.menuArm or H.menu() ~= nil end, function()
        if not S.menuArm then return end
        local m = H.menu()
        if m then
            Q.check(H.menuCount(m) > 0, label .. ": ZeD's menu opens on it with its entries", H.menuCount(m) .. " entries")
            RT.bounds(Q, label .. ", its menu")
        else
            Q.say("NOTE " .. label .. ": the game offers nothing on it from here, no menu opened")
        end
        H.closeMenu()
    end)
end

-- ===================================================================== 0. setup
Q.step(5, function()
    S.home = { x = p:getX(), y = p:getY(), z = p:getZ() }
    S.prim, S.sec = p:getPrimaryHandItem(), p:getSecondaryHandItem()
    S.pairWas = RT.isOpen()
    S.sneakWas = p:isSneaking()
    S.cheatWas = p:isTimedActionInstantCheat()
    H.snapInv()
    if getGameSpeed() ~= 1 then
        if ZEDQA_SPEED then ZEDQA_SPEED(1) else setGameSpeed(1) end
    end
    H.stop()
    RT.pairOpen()
    local OC, DW = ZeD.ObjectCards, ZeD.DpadWheels
    Q.check(OC ~= nil and OC.kinds ~= nil and OC.kinds.generator ~= nil and DW ~= nil and DW.H ~= nil and ZeD.Wheel ~= nil
        and ZeD.Reader ~= nil and ZeD.RadioTab ~= nil and ZeD.Rtv ~= nil and ZeD.Stations ~= nil and ZeD.ActionBar ~= nil,
        "the modules under test are loaded (ObjectCards, DpadWheels, Wheel, Reader, RadioTab, Rtv, Stations, ActionBar)")
end)
Q.step(10, function()
    RT.worldTab("loot")
    H.closeCard()
    Q.check(H.wwUp(), "both windows are open to start with")
end)

-- ===================================================================== 1. the generator through ZeD's power card
function H.genOn() return S.gen ~= nil and S.gen:isActivated() end
function H.genConn() return S.gen ~= nil and S.gen:isConnected() end
function H.genFuel() return S.gen and S.gen:getFuel() or 0 end
function H.genInfo() if S.gen then pcall(ISWorldObjectContextMenu.onInfoGenerator, nil, S.gen, pn) end end
-- the engine switch pressed: its zone's run as a click fires it, else the power verb's
function H.genSwitch()
    local z = H.zoneFid("gen:engine")
    if z and z.run then return H.try("generator: the engine switch", z.run, H.ocard(), p) end
    local v, e = H.verb("power"), H.entry()
    if v and v.run and v.enabled and e then return H.try("generator: Turn on / off", v.run, p, e.t, H.ocard()) end
    return false
end
function H.genSlice() return H.lights()[2] end
Q.step(8, function()
    H.begin("generator")
    local sq = H.freeNear(S.RING2)
    if sq then
        pcall(function()
            S.gen = IsoGenerator.new(instanceItem("Base.Generator"), getCell(), sq)
            S.gen:setConnected(false); S.gen:setFuel(40); S.gen:setCondition(100)
        end)
    end
    if S.gen then S.placed[#S.placed + 1] = S.gen end
    S.can = RT.give("Base.PetrolCan")
    if S.can then
        local fc = S.can:getFluidContainer()
        if fc and fc:getAmount() <= 0 then pcall(function() fc:addFluid(Fluid.Petrol, fc:getCapacity()) end) end
    end
    H.cheat(true)
    if not S.gen then Q.skip("generator: every check on the power card", "no free square two squares from the character for it"); return end
    Q.check(ISWorldObjectContextMenu._zed_onInfoGenerator == true, "generator: ZeD's hook is on the game's Info")
    H.genInfo()
end)
H.wait(4000, function() return S.gen == nil or H.cardD("generator") ~= nil end, function(ok)
    if not S.gen then return end
    local e = H.entry()
    S.genCard = Q.check(ok and e ~= nil and e.t.obj == S.gen, "generator: the game's Info opens ZeD's power card on it", tostring(H.kind()))
    if not S.genCard then return end
    local d = e.t.d
    Q.check(d.on == false and d.conn == false, "generator: the card reads it off and not connected", "on " .. tostring(d.on) .. ", connected " .. tostring(d.conn))
    Q.check(math.abs((d.fuel or -1) - H.genFuel()) < 0.01, "generator: the card reads the fuel the game has", tostring(d.fuel) .. " vs " .. tostring(H.genFuel()))
    local v = H.verb("power")
    Q.check(not (v and v.enabled), "generator: not connected, the card does not offer Turn on")
    local sl = H.genSlice()
    Q.check(sl ~= nil and sl.run == nil and sl.off ~= nil, "generator: not connected, the Lights wheel's generator slice is off with its reason", tostring(sl and sl.off))
    RT.bounds(Q, "the power card")
    H.genSwitch()                     -- (a press on the dead switch)
end)
Q.step(30, function()
    if not S.genCard then return end
    Q.check(not H.genOn(), "generator: a press on its switch while not connected starts nothing")
    local v, e = H.verb("plug"), H.entry()
    if v and v.enabled and v.run and e then
        S.plugVia = "card"
        H.try("generator: Connect on the card", v.run, p, e.t, H.ocard())
    else
        S.plugVia = "direct"
        Q.skip("generator: Connect pressed on the card", "the card does not offer it to this character (the game wants Electrical 3 or the generator magazine); connected for the test")
        pcall(function() S.gen:setConnected(true) end)
    end
end)
H.wait(8000, function() return not S.genCard or H.genConn() end, function(ok)
    if not S.genCard then return end
    if S.plugVia == "card" then Q.check(ok, "generator: Connect on the card connects it (the game's own action)", H.queueTypes()) end
    if not ok then pcall(function() S.gen:setConnected(true) end) end
    H.stop()
    H.genInfo()
end)
H.wait(3000, function() local d = H.cardD("generator"); return not S.genCard or (d ~= nil and d.conn == true) end, function(ok)
    if not S.genCard then return end
    Q.check(ok, "generator: the card reads it connected")
    S.genArm = H.genSwitch() and true or false
    Q.check(S.genArm, "generator: connected with fuel, the engine switch is live")
end)
H.wait(8000, function() return not S.genArm or H.genOn() end, function(ok)
    if not S.genArm then return end
    Q.check(ok, "generator: the engine switch starts it (the game's own action)", H.queueTypes())
    if not ok then pcall(function() S.gen:setActivated(true) end) end
    H.stop()
    H.genInfo()
end)
H.wait(3000, function() local d = H.cardD("generator"); return not S.genArm or (d ~= nil and d.on == true) end, function(ok)
    if not S.genArm then return end
    local pill = H.pill(H.entry())
    Q.check(ok and pill ~= nil and pill ~= ZeD.tr("UI_Off"), "generator: running, the card reads it on", tostring(pill))
    local sl = H.genSlice()
    Q.check(sl ~= nil and sl.run ~= nil and sl.detail == getText("ContextMenu_Turn_Off"), "generator: running, the wheel's generator slice offers Turn off", tostring(sl and sl.detail))
    RT.bounds(Q, "the power card, running")
    RT.pairShut()
end)
Q.step(12, function() RT.pairOpen() end)
H.wait(3000, H.wwUp, function(ok)
    Q.check(ok, "generator: both windows closed and opened again while it runs")
    -- every tab of the strip pressed in one frame, Loot last
    for _, id in ipairs(RT.tabs(RT.worldStrip())) do if id ~= "loot" then RT.worldTab(id) end end
    RT.worldTab("loot")
end)
H.wait(2500, function() local w = RT.ww(); return w ~= nil and w._activeTab == "loot" end, function(ok)
    local w = RT.ww()
    Q.check(ok, "every World tab pressed in one frame, Loot last: the window ends on Loot", tostring(w and w._activeTab))
    RT.bounds(Q, "after the tab storm")
    if S.genArm then
        Q.check(H.genOn(), "generator: still running after the windows closed and the tabs changed")
        H.genInfo()
    end
end)
H.wait(3000, function() local d = H.cardD("generator"); return not S.genArm or (d ~= nil and d.on == H.genOn()) end, function(ok)
    if not S.genArm then return end
    Q.check(ok, "generator: its card opened again reads it as the game has it", "game on " .. tostring(H.genOn()))
    for _ = 1, 5 do H.genSwitch() end
end)
H.wait(10000, function() return not S.genArm or H.queueEmpty() end, function(ok)
    if not S.genArm then return end
    Q.check(ok, "generator: five presses on the switch in one frame, the queue runs dry", H.queueTypes())
    H.stop()
    H.genInfo()
end)
H.wait(3000, function() local d = H.cardD("generator"); return not S.genArm or (d ~= nil and d.on == H.genOn()) end, function(ok)
    if not S.genArm then return end
    Q.check(ok, "generator: after the five presses the card and the game agree", "game on " .. tostring(H.genOn()))
    pcall(function() S.gen:setFuel(5); S.gen:setActivated(true) end)
end)
Q.step(20, function()
    if not S.genArm then return end
    pcall(function() S.gen:setFuel(0) end)
    H.genInfo()
end)
H.wait(5000, function() return not S.genArm or not H.genOn() end, function(ok)
    if not S.genArm then return end
    if ok then
        Q.check(true, "generator: the tank emptied while it runs, the game stops it")
    else
        Q.skip("generator: runs dry and stops by itself", "the game kept it running 5 s on an empty tank (it stops it on its own clock); stopped for the test")
        pcall(function() S.gen:setActivated(false) end)
    end
end)
H.wait(3000, function() local d = H.cardD("generator"); return not S.genArm or (d ~= nil and d.fuel == 0 and d.on == false) end, function(ok)
    if not S.genArm then return end
    local v = H.verb("power")
    Q.check(ok and not (v and v.enabled), "generator: out of fuel, the card reads 0 and off and does not offer Turn on", "power verb on " .. tostring(v and v.enabled))
    local sl = H.genSlice()
    Q.check(sl ~= nil and sl.run == nil and sl.off ~= nil, "generator: out of fuel, the wheel's generator slice is off with its reason", tostring(sl and sl.off))
end)
H.wait(3000, function() return not S.genArm or H.zoneFid("gen:can:1") ~= nil end, function(ok)
    S.fuelArm = false
    if not S.genArm then return end
    if not S.can then Q.skip("generator: Add on a petrol can's row", "no petrol can could be given"); return end
    local z = H.zoneFid("gen:can:1")
    if not Q.check(ok and z ~= nil and z.run ~= nil, "generator: empty and off, the card lists the petrol can carried with its Add button") then return end
    RT.bounds(Q, "the power card with its can row")
    S.fuelArm = H.try("generator: Add on the can's row", z.run, H.ocard(), p) and true or false
end)
H.wait(12000, function() return not S.fuelArm or (H.genFuel() > 0 and H.queueEmpty()) end, function(ok)
    if not S.fuelArm then return end
    Q.check(H.genFuel() > 0, "generator: Add on the can pours petrol in (the game's own action)", H.queueTypes())
    H.stop()
    H.genInfo()
end)
H.wait(3000, function() local d = H.cardD("generator"); return not S.fuelArm or (d ~= nil and math.abs((d.fuel or 0) - H.genFuel()) < 0.01) end, function(ok)
    if S.fuelArm then Q.check(ok and H.genFuel() > 0, "generator: the card reads the fuel poured in", tostring(H.genFuel())) end
    if not S.gen then return end
    pcall(function() S.gen:setActivated(false) end)
    H.genInfo()
end)
Q.step(15, function()
    if not S.gen then return end
    S.vanArm = H.kind() == "generator"
    H.errMark()
    H.removeObj(S.gen)
end)
H.wait(3000, function() return not S.vanArm or H.entry() == nil end, function(ok)
    if S.gen then
        if S.vanArm then
            Q.check(ok, "generator: taken out of the world while its card shows, the card closes", tostring(H.kind()))
            H.errCheck("generator: taken away while its card shows")
        end
        local sl = H.genSlice()
        Q.check(sl ~= nil and sl.run == nil, "generator: gone, the wheel's generator slice has nothing to run", tostring(sl and (sl.off or sl.detail)))
    end
    H.closeCard()
    H.stop()
    H.cheat(false)
    H.fin("the generator")
end)

-- ===================================================================== 2. the emote wheel
-- the point on the ring a slice sits at, in the wheel's own pixels (ZeD_Wheel.lua W.sliceAt, turned round)
function H.sliceXY(m, i)
    local _, _, r, cx, cy = ZeD.Wheel.geom(m)
    local step = 360 / math.max(#m.slices, 2)
    local a = math.rad((i - 1) * step - 90)
    return cx + r * math.cos(a), cy + r * math.sin(a)
end
function H.wheelUp() return S.wh ~= nil and S.wh:isReallyVisible() end
function H.openEmotes() return pcall(function() ISEmoteRadialMenu:new(p):fillMenu() end) end
function H.emoteBack()
    if S.emoteOrig then ISEmoteRadialMenu.emote = S.emoteOrig; S.emoteOrig = nil end
    if S.wh and S.wh:isReallyVisible() then pcall(function() S.wh:undisplay() end) end
end
Q.step(8, function()
    H.begin("emote wheel")
    S.wh = getPlayerRadialMenu(pn)
    -- (the game's emote, wrapped for the run so a click's emote can be read; put back by H.emoteBack)
    S.emoteOrig = ISEmoteRadialMenu.emote
    ISEmoteRadialMenu.emote = function(self, e) S.emoteRan = e; return S.emoteOrig(self, e) end
    H.openEmotes()
    H.openEmotes()
end)
H.wait(3000, H.wheelUp, function(ok)
    local m = S.wh
    S.whArm = Q.check(ok and m ~= nil and m._zed == true and #(m.slices or {}) > 0, "emote wheel: opened twice in one frame, it shows drawn ZeD's way with its slices",
        "zed " .. tostring(m and m._zed) .. ", " .. tostring(m and m.slices and #m.slices) .. " slices")
    if not S.whArm then return end
    RT.bounds(Q, "the emote wheel")
    S.subI = nil
    for i, s in ipairs(m.slices) do if not S.subI and ZeD.Wheel.hasSub(s) then S.subI = i end end
    if not S.subI then Q.skip("emote wheel: a click on a group", "the wheel has no group slice here"); return end
    S.n0 = #m.slices
    local x, y = H.sliceXY(m, S.subI)
    H.try("emote wheel: a click towards a group", m.onMouseDown, m, x, y)
end)
H.wait(3000, function() return not (S.whArm and S.subI) or H.wheelUp() end, function(ok)
    if not (S.whArm and S.subI) then return end
    local m = S.wh
    S.emI = nil
    -- (a group's wheel is told from the first wheel by the game's Back slice: the first wheel has quick emotes too)
    local back = false
    for i, s in ipairs(m.slices or {}) do
        if not S.emI and s.command and s.command[1] == ISEmoteRadialMenu.emote then S.emI = i end
        if s.command and s.command[1] == ISEmoteRadialMenu.fillMenu and s.command[3] == nil then back = true end
    end
    if not Q.check(ok and S.emI ~= nil and back, "emote wheel: a click on a group fills the wheel with that group's emotes and the game's Back",
        #(m.slices or {}) .. " slices, Back " .. tostring(back)) then S.emI = nil; return end
    RT.bounds(Q, "the emote group")
    S.emoteRan = nil
    local x, y = H.sliceXY(m, S.emI)
    H.try("emote wheel: a click towards an emote", m.onMouseDown, m, x, y)
end)
Q.step(6, function()
    if not (S.whArm and S.emI) then return end
    Q.check(S.emoteRan ~= nil and not H.wheelUp(), "emote wheel: a click on an emote plays it (the game's own emote) and the wheel goes", tostring(S.emoteRan))
end)
Q.step(4, function()
    if not S.whArm then return end
    S.emoteRan = nil
    H.openEmotes()
end)
H.wait(3000, function() return not S.whArm or H.wheelUp() end, function(ok)
    if not S.whArm then return end
    local m = S.wh
    local _, _, _, cx, cy = ZeD.Wheel.geom(m)
    H.try("emote wheel: a click in the dead middle", m.onMouseDown, m, cx, cy)
    Q.check(ok and not H.wheelUp() and S.emoteRan == nil, "emote wheel: a click in its dead middle closes it and runs nothing", tostring(S.emoteRan))
    H.openEmotes()
    RT.pairShut()
end)
Q.step(10, function() RT.pairOpen() end)
H.wait(3000, H.wwUp, function(ok)
    if S.whArm then
        Q.check(ok, "emote wheel: both windows closed and opened under the wheel")
        RT.bounds(Q, "the emote wheel over the windows")
    end
    H.emoteBack()
    H.fin("the emote wheel")
end)

-- ===================================================================== 3. sit on the ground, sneak, auto-walk
Q.step(8, function()
    H.begin("sit and sneak")
    H.stop()
    p:setSneaking(false)
    local sl = H.sits()
    S.sitArm = sl[1] ~= nil and sl[1].run ~= nil
    Q.check(S.sitArm and sl[1].name == getText("ContextMenu_SitGround"), "sit: standing, the Sit wheel's first slice reads Sit on ground", tostring(sl[1] and sl[1].name))
    if S.sitArm then H.take(sl[1]) end
end)
H.wait(6000, function() return not S.sitArm or p:isSitOnGround() end, function(ok)
    if not S.sitArm then return end
    if not Q.check(ok, "sit: the slice sits the character on the ground") then S.sitArm = false; return end
    local sl = H.sits()
    Q.check(sl[1] ~= nil and sl[1].name == ZeD.tr("UI_ZeD_Wheel_GetUp"), "sit: sitting, the first slice now reads Get up", tostring(sl[1] and sl[1].name))
    -- crouch pressed while sitting, then both windows closed
    local D = H.DW()
    local okC, c = pcall(D.H.crouch, p)
    if okC and c then H.take(c) end
    RT.pairShut()
end)
Q.step(10, function() RT.pairOpen() end)
H.wait(3000, H.wwUp, function()
    if not S.sitArm then return end
    RT.bounds(Q, "sitting, the windows opened again")
    local sl = H.sits()
    if sl[1] and sl[1].run then H.take(sl[1]) end
end)
H.wait(7000, function() return not S.sitArm or not p:isSitOnGround() end, function(ok)
    if S.sitArm then
        Q.check(ok, "sit: Get up stands the character up")
        if not ok then H.standUp() end
    end
    p:setSneaking(false)
end)
Q.step(10, function()
    local D = H.DW()
    if not (D and D.H and D.H.crouch and D.H.autoWalk) then Q.check(false, "sneak: the wheel's crouch and auto-walk slices are there"); return end
    for _ = 1, 5 do
        local okC, c = pcall(D.H.crouch, p)
        if okC and c then H.take(c) end
    end
    local _, c = pcall(D.H.crouch, p)
    Q.check(p:isSneaking() == true and type(c) == "table" and c.detail == getText("UI_On"),
        "sneak: five presses of the crouch slice in one frame leave the character crouched, the slice reads On", tostring(type(c) == "table" and c.detail))
    if type(c) == "table" then H.take(c) end
    local _, c2 = pcall(D.H.crouch, p)
    Q.check(p:isSneaking() == false and type(c2) == "table" and c2.detail == getText("UI_Off"), "sneak: one more press stands them up, the slice reads Off",
        tostring(type(c2) == "table" and c2.detail))
    -- auto-walk on and off in one frame
    local _, a = pcall(D.H.autoWalk, p)
    if type(a) == "table" then H.take(a) end
    local _, a2 = pcall(D.H.autoWalk, p)
    if type(a2) == "table" then H.take(a2) end
    local _, a3 = pcall(D.H.autoWalk, p)
    Q.check(p:isAutoWalk() == false and type(a3) == "table" and a3.detail == getText("UI_Off"), "auto-walk: on and off in one frame, it is off and the slice reads Off",
        tostring(type(a3) == "table" and a3.detail))
    p:setAutoWalk(false)
    H.fin("sit and sneak")
end)

-- ===================================================================== 4. the reader, a book, a magazine
function H.media(id)
    return { id = string.lower(id), title = "Print_Media_" .. id .. "_title", info = "Print_Media_" .. id .. "_info", text = "Print_Text_" .. id .. "_info" }
end
function H.reader() return ZeD.Reader.get(pn) end
function H.readerUp() local r = H.reader(); return r ~= nil and r:isReallyVisible() end
function H.printItem(ft, id)
    local it = RT.give(ft)
    if it then
        it:getModData().printMedia = H.media(id)
        it:setName(getText("Print_Media_" .. id .. "_title"))
    end
    return it
end
function H.readerStorm(r)
    for i = 1, 6 do H.try("reader: Paper and Words switched", r.setView, r, (i - math.floor(i / 2) * 2 == 1) and "words" or "paper") end
    for _ = 1, 10 do H.try("reader: zoomed in past its last step", r.zoom, r, 1) end
    for _ = 1, 14 do H.try("reader: zoomed out past its first step", r.zoom, r, -1) end
    for _ = 1, 12 do H.try("reader: the wheel turned up", r.onMouseWheel, r, -1) end
    for _ = 1, 12 do H.try("reader: the wheel turned down", r.onMouseWheel, r, 1) end
    H.try("reader: Words", r.setView, r, "words")
    for _ = 1, 30 do H.try("reader: the wheel turned down in Words", r.onMouseWheel, r, 1) end
    for _ = 1, 40 do H.try("reader: the wheel turned up in Words", r.onMouseWheel, r, -1) end
end
Q.step(8, function()
    H.begin("reader")
    H.stop()
    S.rdArm = false
    if p:tooDarkToRead() then Q.skip("reader: a newspaper and a flyer read", "it is too dark to read here"); return end
    S.news = H.printItem("Base.Newspaper", "KnoxKnews_July1")
    S.flier = H.printItem("Base.Flier", "UStoreItMuldraugh")
    if not (S.news and S.flier) then Q.skip("reader: a newspaper and a flyer read", "the newspaper or the flyer could not be given"); return end
    S.rdArm = true
    H.cheat(true)
    ISTimedActionQueue.add(ISReadABook:new(p, S.news))
end)
H.wait(6000, function() return not S.rdArm or H.readerUp() end, function(ok)
    if not S.rdArm then return end
    local r = H.reader()
    if not Q.check(ok and r ~= nil and r.mode == "print" and r.item == S.news, "reader: the newspaper read to the end opens in ZeD's reader", H.queueTypes()) then
        S.rdArm = false
        return
    end
    RT.bounds(Q, "the reader on the newspaper")
    H.readerStorm(r)
    Q.check(H.readerUp(), "reader: still up after the view, zoom and wheel storm")
end)
Q.step(10, function()
    if not S.rdArm then return end
    RT.bounds(Q, "the reader after the storm")
    H.errMark()
    pcall(function() p:getInventory():Remove(S.news) end)
end)
Q.step(30, function()
    if not S.rdArm then return end
    H.errCheck("reader: the newspaper taken out of the bags while it is open")
    Q.say("the reader with its paper gone: showing " .. tostring(H.readerUp()))
    ISTimedActionQueue.add(ISReadABook:new(p, S.flier))
end)
H.wait(6000, function() local r = H.reader(); return not S.rdArm or (r ~= nil and r:isReallyVisible() and r.item == S.flier) end, function(ok)
    if not S.rdArm then return end
    local r = H.reader()
    Q.check(ok, "reader: a flyer read while the reader is up puts the flyer on it", tostring(r and r.item == S.flier))
    RT.bounds(Q, "the reader on the flyer")
    if r and r:isReallyVisible() then H.try("reader: Escape", r.onKeyPress, r, Keyboard.KEY_ESCAPE) end
end)
Q.step(8, function()
    if S.rdArm then Q.check(not H.readerUp(), "reader: Escape closes it") end
    local r = H.reader()
    if r and r:isReallyVisible() then pcall(function() r:close() end) end
    H.cheat(false)
    H.stop()
    S.book = H.giveFirst({ "Base.BookCarpentry1", "Base.BookCooking1", "Base.BookFishing1" })
    if not S.book then Q.skip("book: read with the action bar up", "no skill book could be given"); return end
    H.try("book: the game's Read on it", ISInventoryPaneContextMenu.readItem, S.book, pn)
end)
H.wait(4000, function() return S.book == nil or H.abWork() end, function(ok)
    S.bkArm = false
    if not S.book then return end
    if not ok and not H.queueHas("ISReadABook") then
        Q.skip("book: read with the action bar up", "the game did not keep the Read (" .. H.queueTypes() .. ")")
        return
    end
    local st = H.ab()
    S.bkArm = Q.check(ok and st ~= nil and type(st.label) == "string" and st.label ~= "", "book: while it is read ZeD's action bar names the job",
        st and (tostring(st.label) .. " / " .. tostring(st.item)) or "no state")
    RT.charTab("health")
    RT.pairShut()
end)
Q.step(10, function() RT.pairOpen() end)
H.wait(3000, H.wwUp, function()
    if not S.bkArm then H.stop(); return end
    Q.check(H.queueHas("ISReadABook"), "book: a tab change and both windows closed and opened mid-read, the read goes on", H.queueTypes())
    RT.bounds(Q, "the windows opened again mid-read")
    H.stop()
end)
H.wait(2500, function() return H.ab() == nil end, function(ok)
    if S.bkArm then Q.check(ok and H.queueEmpty(), "book: the read stopped, the action bar's job ends", H.queueTypes()) end
    RT.charTab("loot")
    S.mag = H.giveFirst({ "Base.MagazineCrossword", "Base.Magazine", "Base.HottieZ" })
    if not S.mag then Q.skip("magazine: taken out of the bags mid-read", "no magazine could be given"); return end
    H.try("magazine: the game's Read on it", ISInventoryPaneContextMenu.readItem, S.mag, pn)
end)
H.wait(4000, function() return S.mag == nil or H.abWork() end, function(ok)
    S.magArm = false
    if not S.mag then return end
    if not ok then
        Q.skip("magazine: taken out of the bags mid-read", "its read did not start within 4 s (" .. H.queueTypes() .. ")")
        H.stop()
        return
    end
    S.magArm = true
    H.errMark()
    pcall(function() p:getInventory():Remove(S.mag) end)
end)
H.wait(5000, function() return not S.magArm or H.ab() == nil end, function(ok)
    if S.magArm then
        Q.check(ok, "magazine: taken out of the bags mid-read, the action bar's job ends", H.queueTypes())
        H.errCheck("magazine: taken away mid-read")
    end
    H.stop()
    H.fin("the reader")
end)

-- ===================================================================== 5. the building: what is in reach
function H.isToilet(o)
    local sp = o:getSprite()
    local nm = sp and sp:getName() or ""
    local pr = o:getProperties()
    local cn = pr and pr:get("CustomName") or ""
    return string.find(string.lower(tostring(cn)), "toilet", 1, true) ~= nil or string.find(string.lower(tostring(nm)), "toilet", 1, true) ~= nil
end
function H.goodWindow(o, sq)
    if o:isSmashed() or o:isBarricaded() or o:isGlassRemoved() or o:isInvincible() then return false end
    local opp = o:getOppositeSquare()
    return sq:isFree(false) and opp ~= nil and opp:isFree(false)
end
function H.goodFence(o, sq)
    if not o:isHoppable() or o:isTallHoppable() or sq:getRoom() ~= nil then return false end
    local north = sq:has(IsoFlagType.HoppableN)
    if not north and not sq:has(IsoFlagType.HoppableW) then return false end
    -- (the far square is the one across THIS fence: a north fence with its far square taken is no fence to climb,
    -- never the west square in its place)
    local to = nil
    if north then to = H.freeSq(sq:getX(), sq:getY() - 1, 0) else to = H.freeSq(sq:getX() - 1, sq:getY(), 0) end
    if not (to and to:getRoom() == nil and H.freeSq(sq:getX(), sq:getY(), 0)) then return false end
    S.fenceFrom, S.fenceTo, S.fenceDir = sq, to, north and IsoDirections.N or IsoDirections.W
    return true
end
function H.classify(o, sq)
    local room = sq:getRoom()
    if instanceof(o, "IsoDoor") then
        if not S.door and not o:isBarricaded() then S.door = o end
    elseif instanceof(o, "IsoWindow") then
        if not S.window and H.goodWindow(o, sq) then S.window = o end
    elseif instanceof(o, "IsoCurtain") then
        return
    elseif instanceof(o, "IsoLightSwitch") then
        if not S.light and room ~= nil then S.light = o end
    else
        if not S.toilet and room ~= nil and H.isToilet(o) then S.toilet = o end
        if not S.water and room ~= nil and o:hasWater() and o:getFluidAmount() > 0 then S.water = o end
        if not S.fence and H.goodFence(o, sq) then S.fence = o end
    end
end
function H.scanSq(x, y)
    local sq = H.sq(x, y, 0)
    if not sq then return end
    local objs = sq:getObjects()
    if objs:size() < 2 then return end
    -- (one odd object that refuses a question must not end the whole search: the building scenes all hang on it)
    for i = 0, objs:size() - 1 do pcall(H.classify, objs:get(i), sq) end
end
-- the squares r tiles out, nearest first, so the first of each kind found is the nearest
function H.scanRing(cx, cy, r)
    if r == 0 then H.scanSq(cx, cy); return end
    for d = -r, r do H.scanSq(cx + d, cy - r); H.scanSq(cx + d, cy + r) end
    for d = -r + 1, r - 1 do H.scanSq(cx - r, cy + d); H.scanSq(cx + r, cy + d) end
end
function H.roomRing(x, y, z)
    local here = H.freeSq(x, y, z)
    local out = {}
    if not (here and here:getRoom()) then return out end
    for _, d in ipairs(S.RING1) do
        local n = H.freeSq(x + d[1], y + d[2], z)
        if n and n:getRoom() ~= nil and here:canReachTo(n) then out[#out + 1] = n end
    end
    return out
end
function H.findSpot(cx, cy, cz, rad)
    for r = 0, rad do
        for dy = -r, r do
            for dx = -r, r do
                if math.abs(dx) == r or math.abs(dy) == r then
                    local ring = H.roomRing(cx + dx, cy + dy, cz)
                    if #ring >= 2 then return { x = cx + dx + 0.5, y = cy + dy + 0.5, z = cz, ring = ring } end
                end
            end
        end
    end
    return nil
end
function H.setGrid(on)
    if S.elec then pcall(function() S.elec:setValue(on and 99999 or 0); S.so:toLua() end) end
    pcall(function() getWorld():setHydroPowerOn(on and true or false) end)
end
function H.gridBack()
    if not S.gridTouched then return end
    if S.elec and S.elecWas ~= nil then pcall(function() S.elec:setValue(S.elecWas); S.so:toLua() end) end
    if S.hydroWas ~= nil then pcall(function() getWorld():setHydroPowerOn(S.hydroWas) end) end
    S.gridTouched = false
end
-- a door or a window stands between two squares: the alarm of the building on either side
function H.disarmAt(o)
    pcall(function() H.disarm(o:getSquare()) end)
    pcall(function() H.disarm(o:getOppositeSquare()) end)
end
function H.where(o)
    if not o then return "none" end
    local sq = o:getSquare()
    return sq and (sq:getX() .. "," .. sq:getY()) or "no square"
end
Q.step(8, function()
    H.begin("the building")
    local hx, hy = math.floor(S.home.x), math.floor(S.home.y)
    for r = 0, S.R do H.scanRing(hx, hy, r) end
    S.spot = H.findSpot(hx, hy, 0, S.ROOM_R)
    Q.say("found from home: room spot " .. (S.spot and (math.floor(S.spot.x) .. "," .. math.floor(S.spot.y)) or "none") .. ", door " .. H.where(S.door)
        .. ", window " .. H.where(S.window) .. ", switch " .. H.where(S.light) .. ", toilet " .. H.where(S.toilet) .. ", water " .. H.where(S.water)
        .. ", fence " .. H.where(S.fence))
    pcall(function() S.so = getSandboxOptions(); S.elec = S.so:getOptionByName("ElecShutModifier"); S.elecWas = S.elec:getValue() end)
    pcall(function() S.hydroWas = getWorld():isHydroPowerOn() end)
    S.gridTouched = true
    H.setGrid(true)
end)

-- ===================================================================== 6. a TV and a house radio in the Radio tab
function H.tw(w) return w and w._radioTw or nil end
function H.hit(t, id)
    for _, h in ipairs((t and t.hits) or {}) do if h.id == id then return h end end
    return nil
end
function H.click(id, side)
    local w = RT.ww()
    local h = H.hit(H.tw(w), id)
    if not h then return false end
    local x = (side == "l" and h.x + 2) or (side == "r" and h.x + h.w - 3) or (h.x + math.floor(h.w / 2))
    return H.try("the Radio tab's click on " .. id, ZeD.RadioTab.onClick, w, x, h.y + math.floor(h.h / 2)) and true or false
end
function H.clickPower() return H.click("power") or H.click("volpwr") end
function H.volPress(dir)
    local t = H.tw(RT.ww())
    if H.hit(t, dir > 0 and "volup" or "voldn") then return H.click(dir > 0 and "volup" or "voldn") end
    if H.hit(t, "vol") then return H.click("vol", dir > 0 and "r" or "l") end
    return false
end
function H.dd(dev) return dev and dev:getDeviceData() or nil end
function H.on(dev) local d = H.dd(dev); return d ~= nil and d:getIsTurnedOn() end
function H.chan(dev) local d = H.dd(dev); return d and d:getChannel() or -1 end
function H.vol(dev) local d = H.dd(dev); return d and d:getDeviceVolume() or -1 end
function H.radioIdx(dev)
    local w = RT.ww()
    for i, r in ipairs((w and w._radios) or {}) do if r.radioInstance == dev then return i end end
    return nil
end
function H.pick(dev)
    local i = H.radioIdx(dev)
    if i then H.try("the Radio tab's pick", ZeD.RadioTab.selectRadio, RT.ww(), i) end
end
function H.faceOn(dev)
    local t = H.tw(RT.ww())
    return t ~= nil and t.dev == dev and (H.hit(t, "power") ~= nil or H.hit(t, "volpwr") ~= nil)
end
function H.read(dev)
    local ok, st = pcall(ZeD.Rtv.read, dev)
    return ok and st or nil
end
function H.placeSet(tv, spr, sq)
    if not (sq and getSprite(spr)) then return nil end
    local obj = nil
    if tv then obj = IsoTelevision.new(getCell(), sq, getSprite(spr)) else obj = IsoRadio.new(getCell(), sq, getSprite(spr)) end
    sq:AddTileObject(obj)
    S.placed[#S.placed + 1] = obj
    local d = obj:getDeviceData()
    if d then d:setIsTurnedOn(false); d:setDeviceVolume(0.5) end
    return obj
end
Q.step(5, function()
    H.begin("TV and radio")
    S.tvArm = false
    if not S.spot then
        Q.skip("TV, radio and stove in a room", "no free room square with two free squares beside it within " .. S.ROOM_R .. " tiles of home")
        return
    end
    H.moveTo(S.spot.x, S.spot.y, S.spot.z)
    S.tvArm = true
end)
H.arrive()
Q.step(3, function()
    if not S.tvArm then return end
    RT.pairOpen()
    S.tv = H.placeSet(true, "appliances_television_01_5", S.spot.ring[1])
    S.radio = H.placeSet(false, "appliances_radio_01_9", S.spot.ring[2])
    if not Q.check(S.tv ~= nil and S.radio ~= nil, "TV and radio: a TV and a house radio set down beside the character, in a room") then S.tvArm = false end
end)
H.wait(5000, function() return not S.tvArm or (H.radioIdx(S.tv) ~= nil and H.radioIdx(S.radio) ~= nil) end, function(ok)
    if not S.tvArm then return end
    Q.check(ok, "TV and radio: the World window's Radio list has both")
    Q.check(RT.worldTab("radio"), "TV and radio: the Radio tab opens from the strip")
end)
Q.step(6, function() if S.tvArm then H.pick(S.tv) end end)
H.wait(4000, function() return not S.tvArm or H.faceOn(S.tv) end, function(ok)
    S.tvPow = false
    if not S.tvArm then return end
    if not Q.check(ok, "TV: picked in the Radio tab, its face draws with its power key") then return end
    RT.bounds(Q, "the TV's face")
    local st = H.read(S.tv)
    if not (st and st.grid == true) then
        Q.skip("TV: power, channel and volume", "the room has no grid power, even with the grid turned on for the test")
        return
    end
    S.tvPow = H.clickPower()
end)
H.wait(3000, function() return not S.tvPow or H.on(S.tv) end, function(ok)
    if not S.tvPow then return end
    Q.check(ok, "TV: a click on power turns it on")
    local stops = ZeD.Rtv.stops and ZeD.Rtv.stops() or nil
    if stops and stops[1] and ZeD.RadioOps and ZeD.RadioOps.setChannel then pcall(ZeD.RadioOps.setChannel, p, S.tv, stops[1].freq) end
end)
Q.step(8, function()
    if not S.tvPow then return end
    S.ch0 = H.chan(S.tv)
    S.chArm = H.click("chup")
    if not S.chArm then Q.skip("TV: CH up", "this face has no CH up key") end
end)
H.wait(2500, function() return not (S.tvPow and S.chArm) or H.chan(S.tv) ~= S.ch0 end, function(ok)
    if not S.tvPow then return end
    if S.chArm then Q.check(ok, "TV: CH up moves the channel", tostring(S.ch0) .. " -> " .. tostring(H.chan(S.tv))) end
    S.v0 = H.vol(S.tv)
    S.volArm = H.volPress(1)
    for _ = 1, 29 do H.volPress(1) end
    if not S.volArm then Q.skip("TV: the volume mashed", "this face has no volume control") end
end)
H.wait(1200, function() return not (S.tvPow and S.volArm) or H.vol(S.tv) > S.v0 end, function() end)
Q.step(2, function()
    if not (S.tvPow and S.volArm) then return end
    S.vTop = H.vol(S.tv)
    Q.check(S.vTop > S.v0 and S.vTop <= 1.0001, "TV: thirty volume-ups in one frame raise the volume and never past full", tostring(S.v0) .. " -> " .. tostring(S.vTop))
    for _ = 1, 40 do H.volPress(-1) end
end)
H.wait(1200, function() return not (S.tvPow and S.volArm) or H.vol(S.tv) < S.vTop end, function() end)
Q.step(2, function()
    if not S.tvPow then return end
    if S.volArm then
        local v = H.vol(S.tv)
        Q.check(v >= -0.0001 and v < S.vTop, "TV: forty volume-downs in one frame lower it and never under zero", tostring(S.vTop) .. " -> " .. tostring(v))
    end
    RT.bounds(Q, "the TV's face after the volume storm")
    S.on0 = H.on(S.tv)
    for _ = 1, 3 do H.clickPower() end
end)
H.wait(3000, function() return not S.tvPow or (H.queueEmpty() and H.on(S.tv) ~= S.on0) end, function(ok)
    if not S.tvPow then return end
    Q.check(ok, "TV: three presses on power in one frame leave it " .. (S.on0 and "off" or "on"), "on " .. tostring(H.on(S.tv)))
    -- the grid cut while it plays
    local d = H.dd(S.tv)
    if d then d:setIsTurnedOn(true) end
    H.setGrid(false)
end)
H.wait(3000, function() if not S.tvPow then return true end; local st = H.read(S.tv); return st ~= nil and st.grid == false end, function(ok)
    if S.tvPow then
        if ok then
            local st = H.read(S.tv)
            Q.check(st ~= nil and st.on == false, "TV: the grid cut while it plays, ZeD reads the set as off (no power)", "switch " .. tostring(st and st.switchOn))
            RT.bounds(Q, "the TV's face with the power cut")
        else
            Q.skip("TV: the grid cut while it plays", "the room kept its power 3 s after the grid was turned off")
        end
    end
    H.setGrid(true)
    if S.tvArm then H.pick(S.radio) end
end)
H.wait(4000, function() return not S.tvArm or H.faceOn(S.radio) end, function(ok)
    S.rdPow = false
    if not S.tvArm then return end
    if not Q.check(ok, "radio: picked in the Radio tab, its face draws with its power control") then return end
    RT.bounds(Q, "the house radio's face")
    local st = H.read(S.radio)
    if not (st and st.powered) then Q.skip("radio: power", "the house radio has no power here"); return end
    S.rdPow = H.clickPower()
end)
H.wait(3000, function() return not S.rdPow or H.on(S.radio) end, function(ok)
    if S.rdPow then Q.check(ok, "radio: a click on power turns it on") end
    if S.tvArm then H.pick(S.tv) end
end)
Q.step(10, function()
    if not S.tvArm then return end
    H.errMark()
    H.removeObj(S.tv)
end)
H.wait(4000, function() return not S.tvArm or H.radioIdx(S.tv) == nil end, function(ok)
    if not S.tvArm then return end
    local t = H.tw(RT.ww())
    Q.check(ok and not (t ~= nil and t.dev == S.tv), "TV: taken out of the world while its face shows, the Radio tab drops it", "still listed " .. tostring(H.radioIdx(S.tv) ~= nil))
    H.errCheck("TV: taken away while its face shows")
    RT.bounds(Q, "the Radio tab after the TV went")
    H.removeObj(S.radio)
end)
H.wait(4000, function() return not S.tvArm or H.radioIdx(S.radio) == nil end, function(ok)
    if S.tvArm then
        Q.check(ok and H.wwUp(), "radio: the last set gone too, the Radio list has neither and the window stays up")
        RT.bounds(Q, "the Radio tab with no set of ours")
    end
    RT.worldTab("loot")
    H.fin("TV and radio")
end)

-- ===================================================================== 7. a stove: the Loot list and the Craft tab's station
function H.stState(label)
    local ST = ZeD.Stations
    local st = ST.current(p)
    if not (st and st.obj == S.stove) then Q.check(false, "stove: " .. label .. ", it is still the bound station"); return end
    local ok, words = pcall(ST.stateText, st, p)
    local pw = S.stInv ~= nil and S.stInv:isPowered()
    local want = (not pw) and ZeD.tr("UI_ZeD_Station_StateNoPower") or getText(S.stove:Activated() and "UI_On" or "UI_Off")
    Q.check(ok and words == want, "stove: " .. label .. ", the station's state reads " .. tostring(want), tostring(words))
end
Q.step(8, function()
    H.begin("stove")
    S.stArm = false
    if not S.spot then return end
    if not S.tvArm then Q.skip("stove: every check", "the TV and the radio could not be set down in the room, so the room was not used"); return end
    local sq, tile = S.spot.ring[1], nil
    for _, name in ipairs({ "appliances_cooking_01_0", "appliances_cooking_01_8", "appliances_cooking_01_12" }) do
        if not tile and getSprite(name) then tile = name end
    end
    if not (sq and tile and sq:isFree(false)) then Q.skip("stove: every check", "no range tile or no free square beside the character"); return end
    S.stove = IsoStove.new(getCell(), sq, getSprite(tile))
    pcall(function() S.stove:createContainersFromSpriteProperties() end)
    sq:AddSpecialObject(S.stove)
    if S.stove:getObjectIndex() < 0 then sq:AddTileObject(S.stove) end
    S.placed[#S.placed + 1] = S.stove
    S.stInv = S.stove:getContainer()
    S.stArm = Q.check(S.stInv ~= nil, "stove: a range set down beside the character", tile)
end)
H.wait(5000, function() return not S.stArm or H.inList(S.stInv) ~= nil end, function(ok)
    if not S.stArm then return end
    Q.check(ok, "stove: the World window's container list has it")
    S.stove:Toggle()
    H.try("stove: ZeD's station route", ZeD.Stations.open, p, S.stove)
end)
H.wait(4000, function() if not S.stArm then return true end; local st = ZeD.Stations.current(p); return st ~= nil and st.obj == S.stove end, function(ok)
    if not S.stArm then return end
    if not Q.check(ok, "stove: opened, it is the Craft tab's station") then S.stArm = false; return end
    H.stState("its switch turned once")
    for _ = 1, 5 do S.stove:Toggle() end
end)
Q.step(20, function()
    if not S.stArm then return end
    H.stState("its switch turned five more times in one frame")
    RT.bounds(Q, "the Craft tab on the stove")
    H.errMark()
    H.removeObj(S.stove)
end)
H.wait(4000, function()
    if not S.stArm then return true end
    local st = ZeD.Stations.current(p)
    return (st == nil or st.obj ~= S.stove) and H.inList(S.stInv) == nil
end, function(ok)
    if S.stArm then
        local st = ZeD.Stations.current(p)
        Q.check(st == nil or st.obj ~= S.stove, "stove: taken out of the world while bound, the Craft tab lets it go")
        Q.check(H.inList(S.stInv) == nil, "stove: and its container leaves the World window's list")
        H.errCheck("stove: taken away while bound")
        RT.bounds(Q, "the Craft tab after the stove went")
    end
    pcall(ZeD.Stations.unbind, p)
    RT.worldTab("loot")
    H.fin("the stove")
end)

-- ===================================================================== 8. a light switch, with and without power
function H.lightWord(on) return getText(on and "ContextMenu_Turn_Off" or "ContextMenu_Turn_On") end
Q.step(8, function()
    H.begin("light switch")
    S.ltArm = false
    if not S.light then Q.skip("light switch: the Lights wheel's Room lights slice", "no light switch in a room within " .. S.R .. " tiles of home"); return end
    local sq = H.standBy(S.light:getSquare(), true)
    if not sq then Q.skip("light switch: the Lights wheel's Room lights slice", "no free room square at the switch"); return end
    H.moveToSq(sq)
    S.ltArm = true
end)
H.arrive()
Q.step(3, function()
    if not S.ltArm then return end
    RT.pairOpen()
    local okS, sw = pcall(H.DW().H.switchInReach, p)
    S.sw = okS and sw or nil
    if not S.sw then
        Q.skip("light switch: the Lights wheel's Room lights slice", "ZeD finds no powered switch in reach from the square at it")
        S.ltArm = false
        return
    end
    S.swWas = S.sw:isActivated()
    local sl = H.lights()[1]
    Q.check(sl ~= nil and sl.run ~= nil and sl.detail == H.lightWord(S.swWas), "light switch: with power, the Room lights slice offers " .. H.lightWord(S.swWas), tostring(sl and (sl.detail or sl.off)))
    if sl and sl.run then H.take(sl) end
end)
H.wait(3000, function() return not S.ltArm or S.sw:isActivated() ~= S.swWas end, function(ok)
    if not S.ltArm then return end
    if not ok and not S.sw:canSwitchLight() then
        Q.skip("light switch: flipped by the slice", "the game will not switch this light (no bulb in it, or no power to it)")
        H.stop()
        S.ltArm = false
        return
    end
    Q.check(ok, "light switch: the slice flips the switch (the game's own action)", H.queueTypes())
    local sl = H.lights()[1]
    Q.check(sl ~= nil and sl.detail == H.lightWord(S.sw:isActivated()), "light switch: the slice follows the switch", tostring(sl and sl.detail))
    for _ = 1, 4 do
        local s2 = H.lights()[1]
        if s2 and s2.run then H.take(s2) end
    end
end)
H.wait(4000, function() return not S.ltArm or H.queueEmpty() end, function(ok)
    if not S.ltArm then return end
    local sl = H.lights()[1]
    Q.check(ok and sl ~= nil and sl.detail == H.lightWord(S.sw:isActivated()), "light switch: four more presses in one frame, the slice still tells the switch's state",
        tostring(sl and sl.detail) .. ", switch on " .. tostring(S.sw:isActivated()))
    RT.bounds(Q, "after the light switch storm")
    H.setGrid(false)
end)
Q.step(20, function()
    if not S.ltArm then return end
    local sq = p:getCurrentSquare()
    if sq and sq:haveElectricity() then
        Q.skip("light switch: with the power cut", "a generator powers this square")
    else
        local sl = H.lights()[1]
        Q.check(sl ~= nil and sl.run == nil and sl.off ~= nil, "light switch: with the power cut, the Room lights slice is off with its reason", tostring(sl and (sl.off or sl.detail)))
    end
    H.setGrid(true)
end)
Q.step(10, function()
    if S.ltArm and S.sw:isActivated() ~= S.swWas then pcall(function() S.sw:toggle() end) end
    H.stop()
    H.fin("the light switch")
end)

-- ===================================================================== 9. a door
function H.unbarricade()
    local b = S.barr
    S.barr = nil
    if not b then return end
    for _ = 1, 4 do
        if b:getNumPlanks() > 0 then pcall(function() b:removePlank(nil) end) end
    end
    if b:getObjectIndex() >= 0 then H.removeObj(b) end
end
function H.doorBack()
    H.unbarricade()
    local d, was = S.door, S.doorWas
    if not (d and was) then return end
    S.doorWas = nil
    pcall(function() d:setLockedByKey(false); d:setLocked(false) end)
    if d:IsOpen() ~= was.open then pcall(function() d:ToggleDoorSilent() end) end
    pcall(function() d:setLocked(was.locked); d:setLockedByKey(was.key) end)
    S.doorOk = d:IsOpen() == was.open
end
Q.step(8, function()
    H.begin("door")
    S.drArm = false
    if not S.door then Q.skip("door: every check", "no door within " .. S.R .. " tiles of home"); return end
    local sq = H.standBy(S.door:getSquare(), false)
    if not sq then Q.skip("door: every check", "no free square at the door"); return end
    local d = S.door
    S.doorWas = { open = d:IsOpen(), locked = d:isLocked(), key = d:isLockedByKey() }
    H.disarmAt(d)
    H.moveToSq(sq)
    S.drArm = true
end)
H.arrive()
H.worldMenu("door", function() return S.drArm and S.door or nil end)
Q.step(3, function()
    if not S.drArm then return end
    RT.pairOpen()
    local d = S.door
    d:setLockedByKey(false); d:setLocked(false)
    S.d0 = d:IsOpen()
    d:ToggleDoor(p)
end)
Q.step(20, function()
    if not S.drArm then return end
    local d = S.door
    if d:IsOpen() ~= S.d0 then
        Q.check(true, "door: unlocked, a use on it " .. (S.d0 and "closes" or "opens") .. " it")
    else
        Q.skip("door: opened and closed", "the game refused the use from this square")
    end
    for _ = 1, 6 do d:ToggleDoor(p) end
end)
Q.step(20, function()
    if not S.drArm then return end
    RT.bounds(Q, "after six uses of the door in one frame")
    if S.door:IsOpen() then S.door:ToggleDoor(p) end
end)
Q.step(15, function()
    if not S.drArm then return end
    local d = S.door
    if d:IsOpen() then Q.skip("door: a plank nailed across it", "the door would not close"); return end
    local b = IsoBarricade.AddBarricadeToObject(d, p)
    if not b then Q.skip("door: a plank nailed across it", "the game gave no barricade for this door from this side"); return end
    S.barr = b
    b:addPlank(p, instanceItem("Base.Plank"))
    Q.check(d:isBarricaded(), "door: a plank nailed across it, the game reads it barricaded")
    d:ToggleDoor(p)
end)
Q.step(15, function()
    if not (S.drArm and S.barr) then return end
    Q.check(not S.door:IsOpen(), "door: barricaded, a use on it leaves it shut")
end)
H.worldMenu("barricaded door", function() return (S.drArm and S.barr) and S.door or nil end)
Q.step(3, function()
    H.unbarricade()
    if not S.drArm then return end
    Q.check(not S.door:isBarricaded(), "door: the plank pried off, the game reads it clear")
    -- the game's walk-and-use, cut short at once
    pcall(ISWorldObjectContextMenu.onOpenCloseDoor, nil, S.door, pn)
end)
Q.step(2, function() if S.drArm then H.stop() end end)
H.wait(2500, function() return not S.drArm or (H.ab() == nil and H.queueEmpty()) end, function(ok)
    if S.drArm then Q.check(ok, "door: the walk-and-use cut short at once, nothing left queued and the action bar clear", H.queueTypes()) end
    H.doorBack()
    H.fin("the door")
end)

-- ===================================================================== 10. a window and its curtains
function H.sweepGlass(sq)
    if not sq then return end
    local g = sq:getBrokenGlass()
    if g then pcall(function() sq:transmitRemoveItemFromSquare(g) end) end
end
function H.curtainBack()
    local c = S.cur
    S.cur = nil
    if not c then return end
    if S.sheetAdded then
        pcall(function() c:removeSheet(p) end)
        S.sheetAdded = false
    elseif S.cur0 ~= nil and c:IsOpen() ~= S.cur0 then
        pcall(function() c:ToggleDoor(p) end)
    end
end
function H.windowBack()
    H.curtainBack()
    local w, was = S.window, S.winWas
    if not (w and was) then return end
    S.winWas = nil
    if w:isSmashed() ~= was.smashed then pcall(function() w:setSmashed(was.smashed) end) end
    if w:isGlassRemoved() ~= was.glass then pcall(function() w:setGlassRemoved(was.glass) end) end
    pcall(function() w:setHealth(was.hp) end)
    pcall(function() w:setIsLocked(false); w:setPermaLocked(false) end)
    if not w:isSmashed() and w:IsOpen() ~= was.open then pcall(function() w:ToggleWindow(p) end) end
    if not w:isSmashed() and was.spr and w:getSprite() ~= was.spr and w:IsOpen() == was.open then pcall(function() w:setSprite(was.spr) end) end
    pcall(function() w:setIsLocked(was.locked); w:setPermaLocked(was.perma) end)
    H.sweepGlass(w:getSquare())
    H.sweepGlass(w:getOppositeSquare())
    S.winOk = w:isSmashed() == was.smashed and w:IsOpen() == was.open
end
Q.step(8, function()
    H.begin("window")
    S.wnArm = false
    if not S.window then Q.skip("window and curtains: every check", "no whole window with free squares on both sides within " .. S.R .. " tiles of home"); return end
    local w = S.window
    local sq = w:getIndoorSquare() or w:getSquare()
    if not (sq and sq:isFree(false)) then sq = w:getSquare() end
    if not (sq and sq:isFree(false)) then Q.skip("window and curtains: every check", "no free square at the window"); return end
    S.winWas = { open = w:IsOpen(), locked = w:isLocked(), perma = w:isPermaLocked(), smashed = w:isSmashed(), glass = w:isGlassRemoved(),
                 hp = w:getHealth(), spr = w:getSprite() }
    H.disarmAt(w)
    H.moveToSq(sq)
    S.wnArm = true
end)
H.arrive()
H.worldMenu("window", function() return S.wnArm and S.window or nil end)
Q.step(3, function()
    if not S.wnArm then return end
    RT.pairOpen()
    local w = S.window
    w:setIsLocked(false); w:setPermaLocked(false)
    S.w0 = w:IsOpen()
    w:ToggleWindow(p)
end)
Q.step(20, function()
    if not S.wnArm then return end
    local w = S.window
    if w:IsOpen() ~= S.w0 then
        Q.check(true, "window: unlocked, a use on it " .. (S.w0 and "closes" or "opens") .. " it")
    else
        Q.skip("window: opened and closed", "the game refused the use from this square")
    end
    for _ = 1, 5 do w:ToggleWindow(p) end
end)
Q.step(20, function()
    if not S.wnArm then return end
    RT.bounds(Q, "after five uses of the window in one frame")
    local w = S.window
    local c = w:HasCurtains()
    if not c then
        S.sheet = RT.give("Base.Sheet")
        if S.sheet then pcall(function() w:addSheet(p) end) end
        c = w:HasCurtains()
        S.sheetAdded = c ~= nil
    end
    S.cur = c
    if not c then Q.skip("curtains: used five times", "this window has none and the game hung no sheet on it from this side"); return end
    S.cur0 = c:IsOpen()
    c:ToggleDoor(p)
end)
Q.step(15, function()
    if not (S.wnArm and S.cur) then return end
    local c = S.cur
    if c:IsOpen() ~= S.cur0 then
        Q.check(true, "curtains: a use on them " .. (S.cur0 and "closes" or "opens") .. " them" .. (S.sheetAdded and " (a sheet hung for the test)" or ""))
    else
        Q.skip("curtains: opened and closed", "the game refused the use from this square")
    end
    for _ = 1, 4 do c:ToggleDoor(p) end
end)
H.worldMenu("curtains", function() return S.wnArm and S.cur or nil end)
Q.step(3, function()
    if not S.wnArm then return end
    RT.bounds(Q, "after the curtains")
    H.curtainBack()
    local w = S.window
    if w:IsOpen() then w:ToggleWindow(p) end
    w:smashWindow()
end)
Q.step(15, function()
    if not S.wnArm then return end
    local w = S.window
    S.smashed = Q.check(w:isSmashed(), "window: smashed, the game reads it broken")
    S.climbFrom = p:getCurrentSquare()
    if S.smashed then pcall(ISWorldObjectContextMenu.onClimbThroughWindow, nil, w, pn) end
end)
H.wait(7000, function()
    if not (S.wnArm and S.smashed) then return true end
    return p:getCurrentSquare() ~= S.climbFrom and not p:isClimbing() and H.queueEmpty()
end, function(ok)
    if S.wnArm and S.smashed then
        if ok then
            Q.check(H.ab() == nil, "window: climbed through the broken window with the windows open, the action bar is clear after", H.queueTypes())
            RT.bounds(Q, "after the climb through the window")
        else
            Q.skip("window: climbed through", "the character did not get through in 7 s (" .. H.queueTypes() .. ")")
        end
    end
    H.stop()
    H.windowBack()
    H.healAll()
    H.fin("the window")
end)

-- ===================================================================== 11. a toilet, a seat, a wash
Q.step(8, function()
    H.begin("toilet and seat")
    S.toArm = false
    if not S.toilet then Q.skip("toilet: ZeD's menu on it and the seat slice", "no toilet in a room within " .. S.R .. " tiles of home"); return end
    local sq = H.standBy(S.toilet:getSquare(), true)
    if not sq then Q.skip("toilet: ZeD's menu on it and the seat slice", "no free room square at the toilet"); return end
    H.moveToSq(sq)
    S.toArm = true
end)
H.arrive()
H.worldMenu("toilet", function() return S.toArm and S.toilet or nil end)
Q.step(3, function()
    S.seatArm = false
    if not S.toArm then return end
    RT.pairOpen()
    local sl = H.sits()
    if not (sl[2] and sl[2].run) then
        Q.skip("seat: the Sit wheel's seat slice", "ZeD finds no free seat within 3 tiles of the toilet (" .. tostring(sl[2] and sl[2].off) .. ")")
        return
    end
    S.seatArm = true
    H.take(sl[2])
end)
H.wait(8000, function() return not S.seatArm or p:isSittingOnFurniture() end, function(ok)
    if not S.seatArm then return end
    if not ok then
        Q.skip("seat: sat down by the wheel's slice", "the game's Rest did not seat the character in 8 s (" .. H.queueTypes() .. ")")
        H.stop()
        S.seatArm = false
        return
    end
    local sl = H.sits()
    Q.check(sl[1] ~= nil and sl[1].name == ZeD.tr("UI_ZeD_Wheel_GetUp"), "seat: seated by the wheel's seat slice, its first slice now reads Get up", tostring(sl[1] and sl[1].name))
    RT.bounds(Q, "seated, the windows open")
    if sl[1] and sl[1].run then H.take(sl[1]) end
end)
H.wait(7000, function() return not S.seatArm or not p:isSittingOnFurniture() end, function(ok)
    if S.seatArm then
        Q.check(ok, "seat: Get up stands the character up")
        if not ok then
            H.standUp()
            pcall(function() p:setSitOnFurnitureObject(nil); p:setSittingOnFurniture(false) end)
        end
    end
    H.stop()
    H.fin("the toilet and the seat")
end)
function H.dirt() return S.shirt and S.shirt:getDirtiness() or 0 end
function H.washNow() pcall(ISWorldObjectContextMenu.onWashClothing, p, S.water, nil, nil, S.shirt) end
Q.step(8, function()
    H.begin("wash")
    S.waArm = false
    if not S.water then Q.skip("wash: a dirty T-shirt washed", "nothing holding water in a room within " .. S.R .. " tiles of home"); return end
    local sq = H.standBy(S.water:getSquare(), true)
    if not sq then Q.skip("wash: a dirty T-shirt washed", "no free room square at the water"); return end
    S.shirt = RT.give("Base.Tshirt_DefaultTEXTURE")
    if not S.shirt then Q.skip("wash: a dirty T-shirt washed", "the T-shirt could not be given"); return end
    S.shirt:setDirtiness(60)
    H.moveToSq(sq)
    S.waArm = true
end)
H.arrive()
Q.step(3, function()
    if not S.waArm then return end
    RT.pairOpen()
    H.cheat(true)
    H.washNow()
end)
H.wait(8000, function() return not S.waArm or (H.dirt() <= 0 and H.queueEmpty()) end, function(ok)
    if not S.waArm then return end
    H.cheat(false)
    if ok then
        Q.check(H.ab() == nil, "wash: the T-shirt washed clean (the game's own action), the action bar is clear after")
    else
        Q.skip("wash: the T-shirt washed clean", "the game did not finish the wash in 8 s (" .. H.queueTypes() .. ", dirt " .. tostring(H.dirt()) .. ")")
    end
    H.stop()
    S.shirt:setDirtiness(60)
    H.washNow()
end)
H.wait(5000, function() return not S.waArm or (H.abWork() and H.queueHas("ISWashClothing")) end, function(ok)
    S.wa2 = false
    if not S.waArm then return end
    if not ok then
        Q.skip("wash: the T-shirt taken out of the bags mid-wash", "the second wash did not start within 5 s (" .. H.queueTypes() .. ")")
        H.stop()
        return
    end
    local st = H.ab()
    Q.check(st ~= nil and type(st.label) == "string" and st.label ~= "", "wash: while it washes ZeD's action bar names the job", st and (tostring(st.label) .. " / " .. tostring(st.item)) or "no state")
    S.wa2 = true
    H.errMark()
    pcall(function() p:getInventory():Remove(S.shirt) end)
end)
H.wait(5000, function() return not S.wa2 or H.ab() == nil end, function(ok)
    if S.wa2 then
        Q.check(ok, "wash: the T-shirt taken out of the bags mid-wash, the action bar's job ends", H.queueTypes())
        H.errCheck("wash: the T-shirt taken away mid-wash")
        RT.bounds(Q, "after the wash")
    end
    H.stop()
    H.fin("the wash")
end)

-- ===================================================================== 12. a low fence
Q.step(8, function()
    H.begin("fence")
    S.fnArm = false
    if not S.fence then Q.skip("fence: climbed with the windows open", "no low fence outdoors with free squares on both sides within " .. S.R .. " tiles of home"); return end
    H.moveToSq(S.fenceFrom)
    S.fnArm = true
end)
H.arrive()
Q.step(3, function()
    if not S.fnArm then return end
    RT.pairOpen()
    if S.fence:getObjectIndex() < 0 then S.fnArm = false; Q.skip("fence: climbed with the windows open", "the fence is no longer there"); return end
    ISTimedActionQueue.add(ISClimbOverFence:new(p, S.fence, S.fenceDir))
end)
H.wait(6000, function() return not S.fnArm or (p:getCurrentSquare() == S.fenceTo and not p:isClimbing()) end, function(ok)
    if S.fnArm then
        if ok then
            Q.check(H.ab() == nil and H.queueEmpty(), "fence: climbed over with the windows open, nothing left queued and the action bar clear", H.queueTypes())
            RT.bounds(Q, "after the fence")
        else
            Q.skip("fence: climbed over", "the character did not land on the far square in 6 s (" .. H.queueTypes() .. ")")
        end
    end
    H.stop()
    H.fin("the fence")
end)

-- ===================================================================== put back
Q.mark()
-- one piece of the put-back: an error in it is a FAIL line and the next piece still runs
function H.back(what, fn)
    local ok, err = pcall(fn)
    if not ok then Q.check(false, "put back: " .. what .. " ran without an error", tostring(err)) end
end
-- the building alarms switched off for the run, back on. (Nov 21 2026, QA review: only once the game has him home.
-- The game rings a building's alarm for a character whose current square is in one of its rooms, and that square
-- moves only on the game's update after a move: re-armed in the same frame as the trip home, the building he stood
-- in would ring at once and call zombies. A building the game still has him in stays off, with a NOTE.)
function H.alarmsBack()
    local here = nil
    pcall(function() local sq = p:getCurrentSquare(); local b = sq and sq:getBuilding(); here = b and b:getDef() or nil end)
    for _, def in ipairs(S.alarms or {}) do
        if here ~= nil and def == here then
            Q.say("NOTE the alarm of the building the character still stands in is left off")
        else
            pcall(function() def:setAlarmed(true) end)
        end
    end
    S.alarms = {}
end
-- (the body first, in a step of its own: whatever a scene left and whatever the pieces below do, he is guarded and
-- healed before anything else is touched)
Q.step(5, function()
    H.guard()
    H.healAll()
end)
Q.step(2, function()
    H.back("the queue, the cheat and the speed", function()
        H.stop()
        H.cheat(S.cheatWas)
        if ZEDQA_SPEED then ZEDQA_SPEED(1) else setGameSpeed(1) end
    end)
    H.back("the emote wheel", H.emoteBack)
    H.back("the menu and the card", function() H.closeMenu(); H.closeCard() end)
    pcall(function() local r = ZeD.Reader.get(pn); if r and r:isReallyVisible() then r:close() end end)
    pcall(function() ZeD.Stations.unbind(p) end)
    H.back("the door", H.doorBack)
    H.back("the window and its curtains", H.windowBack)
    H.back("the light switch", function()
        if S.sw and S.swWas ~= nil and S.sw:isActivated() ~= S.swWas then
            H.setGrid(true)
            S.sw:toggle()
        end
    end)
    -- (a generator still running, when the run jumped here, is stopped and unplugged before it leaves the world)
    pcall(function() if S.gen and S.gen:getObjectIndex() >= 0 then S.gen:setActivated(false); S.gen:setConnected(false) end end)
    for _, o in ipairs(S.placed) do H.back("a thing set down taken away", function() H.removeObj(o) end) end
    H.back("the grid", H.gridBack)
    -- (the alarms go back on later, once the game has him home: H.alarmsBack)
    H.back("the stance", function()
        H.standUp()
        pcall(function() p:setSitOnFurnitureObject(nil); p:setSittingOnFurniture(false) end)
        p:setAutoWalk(false)
        p:setSneaking(S.sneakWas and true or false)
    end)
    H.healAll()
    if S.home then H.back("the way home", function() H.moveTo(S.home.x, S.home.y, S.home.z) end) end
end)
Q.step(5, function()
    if S.prim ~= nil and S.inv0 and not S.inv0[S.prim] then S.prim = nil end
    if S.sec ~= nil and S.inv0 and not S.inv0[S.sec] then S.sec = nil end
    H.back("the things given", function() S.swept = H.sweepInv() end)
    RT.takeBack()
    pcall(function() p:setPrimaryHandItem(S.prim); p:setSecondaryHandItem(S.sec) end)
    Q.say("put back: " .. tostring(S.swept) .. " things the run gave or the game handed over taken out of the main inventory")
end)
-- (the game has him on the home square, his current square moved there: no blind wait, 4 s at most)
H.wait(4000, function()
    if not S.home then return true end
    local sq = p:getCurrentSquare()
    return sq ~= nil and sq:getX() == math.floor(S.home.x) and sq:getY() == math.floor(S.home.y)
end, function()
    if ZEDQA_HOME then pcall(ZEDQA_HOME, "bx_wld") end
    RT.pairOpen()
    RT.charTab("loot")
    RT.worldTab("loot")
end)
Q.step(10, function()
    if S.pairWas == false then RT.pairShut() end
    H.back("the building alarms", H.alarmsBack)
    H.back("the checks on the world", function()
        local hx, hy = math.floor(S.home and S.home.x or 0), math.floor(S.home and S.home.y or 0)
        Q.check(math.abs(p:getX() - (hx + 0.5)) <= 3 and math.abs(p:getY() - (hy + 0.5)) <= 3, "put back: the character is home", math.floor(p:getX()) .. "," .. math.floor(p:getY()))
        Q.check(p:getPrimaryHandItem() == S.prim and p:getSecondaryHandItem() == S.sec, "put back: the hands hold what they held")
        Q.check(H.newItems() == 0, "put back: nothing the run gave is left in the main inventory", H.newItems() .. " left")
        local left = 0
        for _, o in ipairs(S.placed) do if o:getObjectIndex() >= 0 then left = left + 1 end end
        Q.check(left == 0, "put back: everything set down is taken away (generator, TV, radio, stove)", left .. " left")
        if S.doorOk ~= nil then Q.check(S.doorOk and not S.door:isBarricaded(), "put back: the door is as it was found, no plank on it") end
        if S.winOk ~= nil then Q.check(S.winOk, "put back: the window is whole and as it was found", "smashed " .. tostring(S.window:isSmashed())) end
        Q.check(not p:isSitOnGround() and not p:isSittingOnFurniture() and p:isSneaking() == (S.sneakWas and true or false) and H.queueEmpty(),
            "put back: the character stands, crouched or not as found, with nothing queued")
        Q.check(getGameSpeed() == 1, "put back: game speed 1", tostring(getGameSpeed()))
    end)
end)
-- the body last, in a step of its own (it runs whatever the steps before did): healed once more, read back from the
-- game, said in a PASS / FAIL line; god mode and invincible go back as found only when he is whole and home, and stay
-- ON when he is not
Q.step(5, function()
    H.guard()
    H.healAll()
    local bad = H.hurt()
    local whole = Q.check(bad == "", "put back: the character is alive and healed (health 100, no wound on any part, no fracture, not infected)", (bad == "") and "whole" or bad)
    -- (and home: away from it, near where the run's noise may have called zombies, the two stay ON as well)
    local home = false
    pcall(function()
        home = S.home == nil or (math.abs(p:getX() - (math.floor(S.home.x) + 0.5)) <= 3 and math.abs(p:getY() - (math.floor(S.home.y) + 0.5)) <= 3)
    end)
    local backOk = whole and home
    if backOk then
        if S.invWas ~= nil then pcall(function() p:setInvincible(S.invWas) end) end
        if S.godWas ~= nil then pcall(function() p:setGodMod(S.godWas) end) end
    end
    local god, inv = nil, nil
    pcall(function() god = p:isGodMod() end)
    pcall(function() inv = p:isInvincible() end)
    if backOk then
        Q.check((S.godWas == nil or god == S.godWas) and (S.invWas == nil or inv == S.invWas), "put back: god mode and invincible as found",
            "god mode " .. tostring(god) .. " (was " .. tostring(S.godWas) .. "), invincible " .. tostring(inv) .. " (was " .. tostring(S.invWas) .. ")")
    else
        Q.say("NOTE god mode and invincible are left ON because the character is " .. (whole and "not home" or "not whole") .. ": god mode "
            .. tostring(god) .. ", invincible " .. tostring(inv))
    end
end)
Q.start()
