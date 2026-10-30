-- ZeDUI/tools/qa/zedqa_plates_336.lua  (Oct 29 2026)
-- The machine plates at 336 px and their 200 px narrow faces (ZeDUI/HANDOFF_plates_336_20261029.md), in game.
-- At the run's UI scale (1.75 at 4K: the main face at 2x inside the 480 card) and at a forced 0.5 (the narrow
-- face), after a layout reset, for one oven (modern range), one microwave (white), the chrome microwave, one
-- generator and one grill. For each: which face is drawn and at what zoom, that it sits inside its card, then
-- a few presses that must act:
--   oven: BAKE 1 7 5 START (it heats and runs), TIMER 0 3 0 START (the timer is set), CANCEL (off)
--   microwaves: TIMECOOK 1 0 0 START (it runs a minute), STOP twice (off); the chrome one takes the white one's keypad
--   generator: the engine switch (it starts, then stops)
--   grill: the tank part (a tank goes in), the burner knob (it lights)
-- The character goes indoors for the grid power (as zedqa_appliances.lua does) and comes back; everything made is
-- taken away. Screenshots/zqa_p336_<scale>_<what>.png; grep "ZEDQA p336".
local p = getPlayer()
local pn = p:getPlayerNum()
local ST, SA = ZeD.Stations, ZeD.StationAppliance
local OC = ZeD.ObjectCards
local Sc = ZeD.Scale
local T = ZeD.T
local function say(s) print("ZEDQA p336 " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function WW() return ZeD_WorldWindow.getWindow() end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_p336_" .. n .. ".png") end) end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
-- after n frames, every frame until cond() is true (at most max frames), then fn
local function waitFor(n, max, cond, fn) Q[#Q + 1] = { n = n, fn = fn, cond = cond, max = max } end
if not (ST and SA and OC) then say("ERR the station or object card modules are not loaded"); say("DONE"); return end

-- ---- indoors, with grid power (zedqa_appliances.lua's staging)
local function sqAt(x, y, z) return getCell():getGridSquare(x, y, z) end
local function freeSq(x, y, z)
    local sq = sqAt(x, y, z)
    local ok = false
    if sq then pcall(function() ok = sq:isFree(false) and not sq:getVehicleContainer() end) end
    return ok and sq or nil
end
local function powerable(x, y, z)
    local sq = freeSq(x, y, z)
    if not sq then return nil end
    if sq:getRoom() then return sq end
    for _, d in ipairs({ { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } }) do
        local n = sqAt(x + d[1], y + d[2], z)
        if n and n:getRoom() then return sq end
    end
    return nil
end
-- a spot with free squares 2 either side and 2 above and below, the sides powerable
local function findSpot(cx, cy, cz, R)
    for r = 0, R do
        for dy = -r, r do
            for dx = -r, r do
                if math.abs(dx) == r or math.abs(dy) == r then
                    local x, y = cx + dx, cy + dy
                    if freeSq(x, y, cz) and powerable(x - 2, y, cz) and powerable(x + 2, y, cz) and freeSq(x, y - 2, cz) and freeSq(x, y + 2, cz)
                        and freeSq(x + 2, y + 2, cz) then return { x = x + 0.5, y = y + 0.5, z = cz } end
                end
            end
        end
    end
    return nil
end
local STORE = { x0 = 12052, y0 = 7117, x1 = 12069, y1 = 7126 }   -- the Fossoil at West Point
local home = { x = p:getX(), y = p:getY(), z = p:getZ() }
local spot = findSpot(math.floor(home.x), math.floor(home.y), math.floor(home.z), 45)
local travelled, t0 = false, 0
local function moveTo(x, y, z)
    p:teleportTo(x, y, z)
    pcall(function() p:setX(x); p:setY(y); p:setZ(z); p:setLastX(x); p:setLastY(y); p:setLastZ(z) end)
end
local placed, added = {}, {}
local function placeStove(sprite, dx, dy)
    local sq = sqAt(math.floor(p:getX()) + dx, math.floor(p:getY()) + dy, math.floor(p:getZ()))
    if not sq then return nil end
    local obj = IsoStove.new(getCell(), sq, getSprite(sprite))
    pcall(function() obj:createContainersFromSpriteProperties() end)
    sq:AddSpecialObject(obj)
    if obj:getObjectIndex() < 0 then pcall(function() sq:AddTileObject(obj) end) end
    placed[#placed + 1] = obj
    return obj
end

local so = getSandboxOptions()
local elec = so and so:getOptionByName("ElecShutModifier")
local elecWas = elec and elec:getValue()
local hydroWas = getWorld():isHydroPowerOn()
local winsWere = ZeD_CharacterWindow.isOpen()
local stove, micro, chrome, gen, bbq
-- (the vanilla actions behind the generator and the grill: the cheat makes them instant, so a slow frame rate at 4K does not
-- decide whether a press has finished; put back at the end)
local instantWas = false
pcall(function() instantWas = p:isTimedActionInstantCheat() end)

step(10, function()
    if elec then elec:setValue(99999); pcall(function() so:toLua() end) end
    getWorld():setHydroPowerOn(true)
    pcall(function() p:setTimedActionInstantCheat(true) end)
    if ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    if not spot then
        travelled, t0 = true, getTimestampMs()
        say(string.format("no room in reach of %d,%d: to the Fossoil at West Point", math.floor(home.x), math.floor(home.y)))
        moveTo(math.floor((STORE.x0 + STORE.x1) / 2) + 0.5, math.floor((STORE.y0 + STORE.y1) / 2) + 0.5, 0)
    end
end)
waitFor(5, 3000, function()
    return not travelled or (sqAt(STORE.x0, STORE.y0, 0) ~= nil and sqAt(STORE.x1, STORE.y1, 0) ~= nil and getTimestampMs() - t0 > 9000)
end, function()
    if travelled then spot = findSpot(math.floor((STORE.x0 + STORE.x1) / 2), math.floor((STORE.y0 + STORE.y1) / 2), 0, 12) end
    say(spot and string.format("indoors at %d,%d", math.floor(spot.x), math.floor(spot.y)) or "ERR no powered floor with room for the set")
    if spot then moveTo(spot.x, spot.y, spot.z) end
end)
step(30, function()
    stove = placeStove("appliances_cooking_01_12", 2, 0)
    micro = placeStove("appliances_cooking_01_24", -2, 0)
    chrome = placeStove("appliances_cooking_01_28", 0, 2)
    -- a generator and a propane grill (tiles from the game's own tests), with a tank for the grill
    local gsq = sqAt(math.floor(p:getX()), math.floor(p:getY()) - 2, math.floor(p:getZ()))
    if gsq then
        pcall(function()
            gen = IsoGenerator.new(instanceItem("Base.Generator"), getCell(), gsq)
            gen:setConnected(true); gen:setFuel(60); gen:setCondition(90)
            placed[#placed + 1] = gen
        end)
    end
    local bsq = sqAt(math.floor(p:getX()) + 2, math.floor(p:getY()) + 2, math.floor(p:getZ()))
    if bsq then
        pcall(function()
            bbq = IsoBarbecue.new(getCell(), bsq, getSprite("appliances_cooking_01_37"))
            bsq:AddTileObject(bbq)
            placed[#placed + 1] = bbq
        end)
    end
    local tank = p:getInventory():AddItem("Base.PropaneTank")
    if tank then added[#added + 1] = tank end
    say(string.format("placed: oven %s, microwave %s, chrome %s, generator %s, grill %s", tostring(stove ~= nil), tostring(micro ~= nil),
        tostring(chrome ~= nil), tostring(gen ~= nil), tostring(bbq ~= nil)))
    pcall(function() Mouse.setXY(20, 20) end)
end)

-- ---- what one phase does, at the scale in force
-- the phase's name carries the real root scale (scale175, scale100, scale050); FORCED: the 0.5 phase
local PH, FORCED = "x", false
local function root() return (Sc and Sc.root and Sc.root()) or 1 end
local function scaleName() return string.format("scale%03d", math.floor(root() * 100 + 0.5)) end
local function actionBusy()
    local ok, busy = pcall(function() return ISTimedActionQueue.isPlayerDoingAction(p) end)
    return ok and busy and true or false
end
-- (the generator's, the tank's and the burner's vanilla actions can still be walking the character when a phase
-- ends: a character pulled away from the oven drops its station, as it should. Clear them before the next face.)
local function stopActions()
    pcall(function() ISTimedActionQueue.clear(p) end)
end
local function craftZones() local w = WW(); return (w and w._craftState and w._craftState.zones) or {} end
local function zoneById(id)
    for _, z in ipairs(craftZones()) do if z.type == "plate" and z.id == id then return z end end
end
-- a press on the plate's control through the tab's own click path
local function press(id, tag)
    local z = zoneById(id)
    if not z then
        local cur = ST.current(p)
        say(string.format("FAIL %s: no control %s on the face (station bound %s, character at %.1f,%.1f, an action running %s, plate zones %d)", tag, id,
            tostring(cur ~= nil), p:getX(), p:getY(), tostring(actionBusy()), #craftZones()))
        fails = fails + 1; return false
    end
    SA.onClick(WW(), WW()._craftState, ST.current(p), z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
    return true
end
local function seq(tag, ids)
    for _, id in ipairs(ids) do step(8, function() press(id, tag) end) end
end
local function faceChecks(tag, obj)
    local w = WW()
    local st = ST.current(p)
    check(st and st.obj == obj, tag .. ": the station is the one opened")
    if not st then return end
    local des, pid = SA.plateFor(st)
    local zs, drawn = craftZones(), nil
    for _, z in ipairs(zs) do if z.type == "plate" then drawn = z.pid; break end end
    local eff = math.floor(w._drawerEffW or 0)
    local T = ZeD.T   -- (read now: a UI scale change gives the game a new token table)
    local half, full = T.px(220), T.px(480)
    local k0 = ZeD.Px.k(root())
    local ids = {}
    for _, z in ipairs(zs) do if z.type == "plate" then ids[#ids + 1] = z.id end end
    local narrowWant = drawn and drawn:sub(-2) == "_n"
    say(string.format("%s [%s, root %.2f, zoom %d]: plate %s, drawn %s, tab %d px (half %d, full %d); controls %s", tag, PH, root(), k0, tostring(pid),
        tostring(drawn), eff, half, full, table.concat(ids, " ")))
    check(math.abs(eff - half) <= 1 or math.abs(eff - full) <= 1, tag .. ": the tab is the half card or the full card")
    check(#ids > 0, tag .. ": the face has its controls (" .. #ids .. ")")
    -- the face must sit inside the card: the main face at its zoom, or the narrow face when that does not fit
    local mainDes = ZeD.PhysPx.plates[pid]
    local fits = mainDes and (mainDes.w * k0 <= eff - T.sp.scrollbarW)
    check(drawn ~= nil and ((drawn == pid) == (fits and true or false)), tag .. ": " .. (fits and "the main face fits at the whole zoom, and is drawn" or "the main face does not fit, the narrow face is drawn") .. " (" .. tostring(drawn) .. ")")
    check(FORCED or (not narrowWant), tag .. ": at the run's own scale the main face is drawn")
    return des
end

-- (getObj: the appliance is made in a step that runs later than this queue is built)
local function openStation(tag, getObj)
    step(10, function() local obj = getObj(); check(obj and ST.open(p, obj), tag .. " opens in the Craft tab") end)
    step(90, function() end)
end
local function after(f) step(40, f) end

-- (the generator's and the grill's actions walk the character up to them: back to the spot before the stations, which
-- Stations.lua lets go of once the character is out of reach)
local function backAtSpot()
    step(5, function() stopActions() end)
    step(5, function() if spot then moveTo(spot.x, spot.y, spot.z) end end)
    step(20, function() end)
end
-- the World window's action tab: the tab strip's own click
local function showTab(id)
    local w = WW()
    if not w then return end
    for _, z in ipairs(w._actionTabStrip and w._actionTabStrip._hitZones or {}) do
        if z.id == "tab:" .. id and w._activeTab ~= id then w._actionTabStrip:onMouseDown(z.x + 2, z.y + 2) end
    end
end
local function stationPhase(label)
    backAtSpot()
    step(30, function() showTab("craft") end)
    -- the oven: BAKE 1 7 5 START, then TIMER 0 3 0 START, then CANCEL
    openStation("oven", function() return stove end)
    after(function() faceChecks("oven", stove); shot(PH .. "_oven") end)
    seq("oven", { "bake", "d1", "d7", "d5", "start" })
    step(40, function()
        check(stove:Activated() and (stove:getMaxTemperature() or 0) > 0, "oven: BAKE 175 START heats it and runs it (on " .. tostring(stove:Activated()) .. ", " .. tostring(stove:getMaxTemperature()) .. ")")
    end)
    seq("oven", { "timer", "d0", "d3", "d0", "start" })
    step(40, function() check((stove:getTimer() or 0) > 0, "oven: TIMER 0:30 START sets the timer (" .. tostring(stove:getTimer()) .. ")") end)
    seq("oven", { "cancel" })
    step(40, function() check(not stove:Activated(), "oven: CANCEL turns it off") end)
    -- the white microwave
    openStation("microwave", function() return micro end)
    after(function() faceChecks("microwave", micro); shot(PH .. "_microwave") end)
    seq("microwave", { "timecook", "d1", "d0", "d0", "start" })
    step(40, function()
        check(micro:Activated() and (micro:getTimer() or 0) > 0, "microwave: TIMECOOK 1:00 START runs it (on " .. tostring(micro:Activated()) .. ", timer " .. tostring(micro:getTimer()) .. ")")
    end)
    seq("microwave", { "stop", "stop" })
    step(40, function() check(not micro:Activated(), "microwave: STOP twice turns it off") end)
    -- the chrome microwave: the white one's keypad
    openStation("chrome microwave", function() return chrome end)
    after(function() faceChecks("chrome microwave", chrome); shot(PH .. "_chrome") end)
    seq("chrome microwave", { "timecook", "d1", "d0", "d0", "start" })
    step(40, function()
        check(chrome:Activated() and (chrome:getTimer() or 0) > 0, "chrome microwave: TIMECOOK 1:00 START runs it (on " .. tostring(chrome:Activated()) .. ", timer " .. tostring(chrome:getTimer()) .. ")")
    end)
    seq("chrome microwave", { "stop", "stop" })
    step(40, function() check(not chrome:Activated(), "chrome microwave: STOP twice turns it off") end)
    step(5, function() pcall(function() ST.unbind(p) end) end)
end

-- an object card (generator, grill): the card's zones by id, run through the card's own handler
local function cardZone(fid)
    local c = WW() and WW()._objectCard
    for _, z in ipairs((c and (c._lastZones or c._zones)) or {}) do if z.fid == fid then return z, c end end
end
-- (the engine switch, the burner and the tank are vanilla timed actions: the character walks up and does them, which takes
-- a while; a press has acted once the thing changed: confirmed by the state itself, not by the action being queued)
local actionSeen = false
-- what the character's action queue holds, for a press whose action did not finish
local function queueDump()
    local out = {}
    pcall(function()
        local q = ISTimedActionQueue.getTimedActionQueue(p)
        for i, a in ipairs(q.queue or {}) do
            local valid, jd, started = nil, nil, nil
            pcall(function() valid = a:isValid() end)
            pcall(function() jd = a.action and a.action:getJobDelta() end)
            pcall(function() started = a.action ~= nil end)
            out[#out + 1] = string.format("%s(valid %s, started %s, delta %s, maxTime %s)", tostring(a.Type), tostring(valid), tostring(started), tostring(jd), tostring(a.maxTime))
        end
    end)
    local st = ""
    pcall(function() st = string.format(" anim %s, turning %s, speed %s", tostring(p:getActionStateName()), tostring(p:shouldBeTurning()), tostring(getGameTime():getMultiplier())) end)
    return "[" .. table.concat(out, "; ") .. "]" .. st
end
local function cardRun(fid, tag)
    local z, c = cardZone(fid)
    if not (z and z.run) then say("FAIL " .. tag .. ": no live control " .. fid .. " on the card"); fails = fails + 1; return false end
    actionSeen = false
    z.run(c, p)
    actionSeen = actionBusy()
    return true
end
-- the condition for a press that starts a timed action: the state, or the action seen queued
local function acted(stateFn)
    if actionBusy() then actionSeen = true end
    return stateFn() and true or false
end
local function openCard(kindId, obj)
    local def = OC.kinds[kindId]
    local ok, list = pcall(def.nearby, p)
    local t
    for _, c in ipairs(ok and list or {}) do if c.obj == obj then t = c end end
    if not t then say("FAIL the " .. kindId .. " card: nothing of the kind found beside the character"); fails = fails + 1; return false end
    return ZeD_WorldWindow.openObjectCard(pn, { def = def, t = t })
end
local function cardFace(tag)
    local T = ZeD.T
    local c = WW() and WW()._objectCard
    local zs = (c and (c._lastZones or c._zones)) or {}
    local fids = {}
    for _, z in ipairs(zs) do if z.fid and (z.fid:sub(1, 4) == "gen:" or z.fid:sub(1, 4) == "bbq:") then fids[#fids + 1] = z.fid end end
    say(string.format("%s [%s, root %.2f]: card %d px wide; controls %s", tag, PH, root(), c and c:getWidth() or -1, table.concat(fids, " ")))
    check(c and math.abs(c:getWidth() - T.px(480)) <= 1, tag .. ": the card is the full card")
    check(#fids > 0, tag .. ": the face has its controls")
end

local function objectPhase()
    backAtSpot()
    step(30, function() showTab("loot") end)   -- (the card opens over the Loot view, as a player meets it; over the Craft tab it hides behind the tab)
    step(5, function() openCard("generator", gen) end)
    step(60, function() cardFace("generator") end)
    step(200, function() shot(PH .. "_generator") end)
    step(5, function() cardRun("gen:engine", "generator") end)
    waitFor(10, 3000, function() return acted(function() return gen:isActivated() end) end, function()
        check(gen:isActivated(), "generator: the engine switch starts it (" .. (gen:isActivated() and "it runs" or "the start was queued and never finished") .. ")")
    end)
    step(40, function() cardRun("gen:engine", "generator") end)
    waitFor(10, 3000, function() return acted(function() return not gen:isActivated() end) end, function()
        check(not gen:isActivated(), "generator: the engine switch stops it")
        if ZeD_WorldWindow.closeObjectCard then ZeD_WorldWindow.closeObjectCard() end
    end)
    -- the grill from a known start: nothing queued, not lit, no tank in the cart, one tank in the bag (the vanilla actions
    -- of the other phase's presses must not decide this phase)
    step(5, function()
        stopActions()
        pcall(function() bbq:setLit(false) end)
        pcall(function() if bbq:hasPropaneTank() then bbq:removePropaneTank() end end)
        pcall(function() bbq:setFuelAmount(0) end)
        local inv = p:getInventory()
        if not inv:containsType("PropaneTank") then local tank = inv:AddItem("Base.PropaneTank"); if tank then added[#added + 1] = tank end end
    end)
    step(20, function() openCard("fire", bbq) end)
    step(60, function() cardFace("grill") end)
    step(200, function() shot(PH .. "_grill") end)
    step(5, function() cardRun("bbq:tank", "grill") end)
    waitFor(10, 3000, function() return acted(function() return bbq:hasPropaneTank() end) end, function()
        if not bbq:hasPropaneTank() then say("grill: tank not in: queue " .. queueDump()) end
        check(bbq:hasPropaneTank(), "grill: the tank part puts a tank in")
    end)
    -- (a new tank holds no gas in this save's items: give the cart some, so the knob has something to light)
    step(60, function() pcall(function() bbq:setFuelAmount(20) end) end)
    step(60, function()
        say(string.format("grill: before the burner knob: fuel %s, hasFuel %s, tank %s, lit %s, an action running %s, character at %.1f,%.1f (grill %d,%d)",
            tostring(bbq:getFuelAmount()), tostring(bbq:hasFuel()), tostring(bbq:hasPropaneTank()), tostring(bbq:isLit()), tostring(actionBusy()),
            p:getX(), p:getY(), bbq:getSquare():getX(), bbq:getSquare():getY()))
        cardRun("bbq:burner", "grill")
    end)
    waitFor(10, 3000, function() return acted(function() return bbq:isLit() end) end, function()
        if not bbq:isLit() then say(string.format("grill: not lit: fuel %s, hasFuel %s, tank %s, an action running %s, character at %.1f,%.1f", tostring(bbq:getFuelAmount()), tostring(bbq:hasFuel()), tostring(bbq:hasPropaneTank()), tostring(actionBusy()), p:getX(), p:getY())) end
        check(bbq:isLit(), "grill: the burner knob lights it (" .. (bbq:isLit() and "lit" or "the light was queued and never finished") .. ")")
        if bbq:isLit() then pcall(function() bbq:setLit(false) end) end
        if ZeD_WorldWindow.closeObjectCard then ZeD_WorldWindow.closeObjectCard() end
    end)
end

-- ---- phase A: the run's own scale; phase B: 0.5
step(5, function() FORCED = false; PH = scaleName(); say(string.format("phase A: root %.2f (the run's own scale)", root())) end)
step(5, function() pcall(ZeD_Window.resetLayout) end)
stationPhase("A")
objectPhase()
step(10, function()
    stopActions()
    FORCED = true
    Sc.override = 0.5; Sc.refresh(); ZeD.applyTheme()
    PH = scaleName()
    say(string.format("phase B: forced root %.2f", root()))
end)
step(60, function() pcall(ZeD_Window.resetLayout) end)
step(60, function() end)
stationPhase("B")
objectPhase()

step(20, function()
    Sc.override = nil; Sc.refresh(); ZeD.applyTheme()
    pcall(function() ST.unbind(p) end)
    pcall(function() if ZeD_WorldWindow.closeObjectCard then ZeD_WorldWindow.closeObjectCard() end end)
    if elec and elecWas ~= nil then elec:setValue(elecWas); pcall(function() so:toLua() end) end
    getWorld():setHydroPowerOn(hydroWas)
    pcall(function() p:setTimedActionInstantCheat(instantWas) end)
    for _, obj in ipairs(placed) do
        local sq = obj:getSquare()
        if sq then pcall(function() sq:transmitRemoveItemFromSquare(obj) end) end
        pcall(function() if instanceof(obj, "IsoGenerator") then obj:remove() end end)
    end
    for _, it in ipairs(added) do local c = it:getContainer(); if c then pcall(function() c:Remove(it) end) end end
    local w = WW()
    if w then
        for _, z in ipairs(w._actionTabStrip and w._actionTabStrip._hitZones or {}) do
            if z.id == "tab:loot" and w._activeTab ~= "loot" then w._actionTabStrip:onMouseDown(z.x + 2, z.y + 2) end
        end
    end
    if winsWere and not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    if spot or travelled then moveTo(home.x, home.y, home.z); t0 = getTimestampMs() end
    say("cleanup done: " .. #placed .. " things removed")
end)
waitFor(5, 3000, function()
    return not travelled or (sqAt(math.floor(home.x), math.floor(home.y), math.floor(home.z)) ~= nil and getTimestampMs() - t0 > 3000)
end, function()
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    if s.cond then
        s.left = (s.left or s.max) - 1
        local ok, done = pcall(s.cond)
        if not (ok and done) and s.left > 0 then wait = 1; return end
        if not (ok and done) then say("WARN step " .. qi .. ": waited " .. s.max .. " frames, the condition never held") end
    end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
