-- ZeDUI/tools/qa/zedqa_plates_fill.lua  (Oct 30 2026, QA; from zedqa_plates_336.lua)
-- Punch list 3 and 2 (commit 8abb840): the machine faces fill their card at every UI scale. First, every
-- "<pid>@<W>" texture in PhysPx.widths loads (the "@" in the file name). Then at UI scale 0.75, 1.0, 1.25, 1.5,
-- 1.75 and 2.0 (ZeD.Scale.override, a layout reset each time), and at 0.64 (the narrow faces), for an oven, the
-- white and the chrome microwave, a generator and the grill (the plate test's checks and presses: the face drawn
-- is the widest that fits, inside the card, keypads / switch / tank / burner act), a civilian ham set placed
-- beside the character (World Radio tab: the face for the drawer, VOL powers it, TUNE moves the frequency) and a
-- walkie in the hand (Character Radio tab: the half card, VOL powers it); the generator and the grill cards with and without
-- their scrollbar pick the same face. The Radio tab is waited for by its real state (tab active, drawer at a card width and
-- still; the tab clicked again until it is), not a fixed count. Indoors with grid power, as the plate
-- test; everything made is taken away. Screenshots/zqa_pfill_<scale>_<what>.png; grep "ZEDQA pfill".
local p = getPlayer()
local pn = p:getPlayerNum()
local ST, SA = ZeD.Stations, ZeD.StationAppliance
local OC = ZeD.ObjectCards
local Sc = ZeD.Scale
local T = ZeD.T
local function say(s) print("ZEDQA pfill " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function WW() return ZeD_WorldWindow.getWindow() end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_pfill_" .. n .. ".png") end) end
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
    -- the face must fill the card (Oct 30 2026, HANDOFF_plates_fill_20261030.md): the widest of the plate's widths
    -- that fits at the whole zoom, or the narrow face when even the 336 one does not fit
    local room = eff - T.sp.scrollbarW
    local wantId, wantW = ZeD.Px.pickWidth(pid, room, k0)
    local wantDes = ZeD.PhysPx.plates[wantId]
    if not wantW then
        local mainDes = ZeD.PhysPx.plates[pid]
        if mainDes and mainDes.w * k0 > room and ZeD.PhysPx.narrow[pid] then wantId = ZeD.PhysPx.narrow[pid] end
        wantDes = ZeD.PhysPx.plates[wantId]
    end
    check(drawn ~= nil and drawn == wantId, tag .. ": the face that fills the card is drawn (want " .. tostring(wantId)
        .. ", drawn " .. tostring(drawn) .. ")")
    check(wantDes and wantDes.w * k0 <= room, tag .. ": it sits inside the card at the whole zoom ("
        .. tostring(wantDes and wantDes.w * k0) .. " of " .. room .. " px)")
    check(FORCED or (not narrowWant), tag .. ": at the run's own scale a full face is drawn, not the narrow one")
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
    -- the face that fills it (Oct 30 2026): the widest width that fits the card's plate room at the whole zoom
    local pid = (tag == "generator") and "gen_red" or "grill_propane"
    local _, wantId = ZeD.Px.pick(pid, c and c._plateRoom or 0)
    say(string.format("%s: plate room %d px, the face for it %s", tag, c and c._plateRoom or -1, tostring(wantId)))
    check(#fids > 0, tag .. ": the face has its controls")
end

-- The card with and without its scrollbar picks the same face (ObjectCards' card._plateRoom is the body's width less the
-- margins, whether or not the scrollbar takes its strip). The body height the card reads at the start of each frame is held
-- by a tick handler: first taller than the view (the scrollbar shows), then empty (it does not); the face's control zone
-- (the face's width times the zoom) is read each time and must match the natural one, and so must the plate room.
local forceBody = nil
local function forceTick()
    local c = WW() and WW()._objectCard
    if c and forceBody then c._bodyH = forceBody end
end
local function liveZoneSize(fid)
    local c = WW() and WW()._objectCard
    for _, z in ipairs((c and c._zones) or {}) do
        if z.fid == fid then return z.w, z.h, c.scroll and c.scroll.visible, c._plateRoom end
    end
    return nil
end
local function scrollbarFace(tag, fid)
    local base = {}
    step(10, function()
        base.w, base.h, base.vis, base.room = liveZoneSize(fid)
        say(string.format("%s: natural card: control %s x %s, scrollbar %s, plate room %s", tag, tostring(base.w), tostring(base.h), tostring(base.vis), tostring(base.room)))
        forceBody = 1000000
        Events.OnTick.Add(forceTick)
    end)
    step(6, function()
        local w, h, vis, room = liveZoneSize(fid)
        check(vis == true, tag .. ": with the body taller than the view the scrollbar shows")
        check(w ~= nil and w == base.w and h == base.h, tag .. ": with the scrollbar the same face (control " .. tostring(w) .. " x " .. tostring(h) .. ", natural " .. tostring(base.w) .. " x " .. tostring(base.h) .. ")")
        check(room ~= nil and room == base.room, tag .. ": with the scrollbar the same plate room (" .. tostring(room) .. ", natural " .. tostring(base.room) .. ")")
        forceBody = 0
    end)
    step(6, function()
        local w, h, vis, room = liveZoneSize(fid)
        check(vis == false, tag .. ": with an empty body no scrollbar")
        check(w ~= nil and w == base.w and h == base.h, tag .. ": without the scrollbar the same face (control " .. tostring(w) .. " x " .. tostring(h) .. ")")
        check(room ~= nil and room == base.room, tag .. ": without the scrollbar the same plate room (" .. tostring(room) .. ")")
        forceBody = nil
        Events.OnTick.Remove(forceTick)
    end)
end

local function objectPhase()
    backAtSpot()
    step(30, function() showTab("loot") end)   -- (the card opens over the Loot view, as a player meets it; over the Craft tab it hides behind the tab)
    step(5, function() openCard("generator", gen) end)
    step(60, function() cardFace("generator") end)
    step(200, function() shot(PH .. "_generator") end)
    scrollbarFace("generator", "gen:engine")
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
    scrollbarFace("grill", "bbq:tank")
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

-- ---- the "@" textures: every width of every plate loads
step(5, function()
    local X = ZeD.PhysPx
    local dir = (X and X.texdir) or "media/textures/ZeD/physpx/"
    local n, missing = 0, {}
    for _, t in pairs((X and X.widths) or {}) do
        for _, key in pairs(t) do
            n = n + 1
            if not ZeD.Px.tex(dir .. key .. ".png") then missing[#missing + 1] = key end
        end
    end
    table.sort(missing)
    check(n > 0 and #missing == 0, string.format("the width textures load: %d of %d (missing: %s)", n - #missing, n,
        #missing > 0 and table.concat(missing, " ", 1, math.min(#missing, 20)) or "none"))
end)

-- ---- a civilian ham set beside the character, a walkie in the hand
local ham, walkie, handWas
step(5, function()
    local here = p:getCurrentSquare()
    local x0, y0, z0 = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    for _, d in ipairs({ { -1, 1 }, { 1, 1 }, { -1, -1 }, { 1, -1 }, { 0, 1 }, { 0, -1 }, { 1, 0 }, { -1, 0 } }) do
        local sq = sqAt(x0 + d[1], y0 + d[2], z0)
        if not ham and sq and sq:isFree(false) and here and here:canReachTo(sq) then
            local it = instanceItem("Base.HamRadio1")
            local dv = it:getDeviceData()
            dv:setHasBattery(true); dv:setPower(0.8); dv:setIsTurnedOn(false); dv:setMicIsMuted(true)
            ham = IsoRadio.new(getCell(), sq, getSprite("appliances_com_01_0"))
            ham:setDeviceData(dv)
            sq:AddTileObject(ham)
            placed[#placed + 1] = ham
        end
    end
    walkie = p:getInventory():AddItem("Base.WalkieTalkie2")
    if walkie then
        added[#added + 1] = walkie
        pcall(function() local dv = walkie:getDeviceData(); dv:setHasBattery(true); dv:setPower(0.8); dv:setIsTurnedOn(false) end)
    end
    say("ham set placed " .. tostring(ham ~= nil) .. ", walkie " .. tostring(walkie ~= nil))
end)

local RT = ZeD.RadioTab
local function CW() return ZeD_CharacterWindow.getWindow() end
local function twOf(w) return w and w._radioTw end
local function hitOf(t, id) for _, h in ipairs((t and t.hits) or {}) do if h.id == id then return h end end end
local function firstHit(t, pat) for _, h in ipairs((t and t.hits) or {}) do if h.id:find(pat) then return h end end end
local function clickHit(w, h, side)
    local x = (side == "l" and h.x + 2) or (side == "r" and h.x + h.w - 3) or (h.x + math.floor(h.w / 2))
    RT.onClick(w, x, h.y + math.floor(h.h / 2))
end
local settleS = {}
local function settled(w)
    local e = math.floor(w and w._drawerEffW or -1)
    local s = settleS[w] or { v = -2, n = 0 }
    settleS[w] = s
    if e == s.v then s.n = s.n + 1 else s.v, s.n = e, 0 end
    return s.n >= 3 and e > 0
end
local function charTab(id)
    local w = CW()
    for _, z in ipairs(w and w._tabStripPanel and w._tabStripPanel._hitZones or {}) do
        if z.id == "tab:" .. id and w._activeTab ~= id then w._tabStripPanel:onMouseDown(z.x + 2, z.y + 2) end
    end
end
-- The Radio tab "ready", polled for the real state with a generous cap (the first run waited a fixed 20 + 5 + 200
-- frames, and at 1.5 the drawer was still at 0 px: the tab strip had not built its hit zones yet, so the one click
-- found nothing). Every ~15 polls the tab is clicked again while it is not the active one or its drawer is shut;
-- the set is picked; ready = the tab active, the drawer open at a card width (the half or the full card) and still for
-- three polls, the face up for that set.
local POLL_CAP = 1800
local pokeN = 0
local function cardWidthNow(w)
    local e = math.floor(w._drawerEffW or 0)
    local half, full = ZeD.T.px(220), ZeD.T.px(480)
    return e, (math.abs(e - half) <= 1 or math.abs(e - full) <= 1)
end
local function worldRadioReady(dev)
    local w = WW()
    if not w then return false end
    pokeN = pokeN + 1
    if (w._activeTab ~= "radio" or not w._drawerOpen) and pokeN % 15 == 1 then
        for _, z in ipairs(w._actionTabStrip and w._actionTabStrip._hitZones or {}) do
            if z.id == "tab:radio" then w._actionTabStrip:onMouseDown(z.x + 2, z.y + 2) end
        end
    end
    for i, r in ipairs(w._radios or {}) do if r.radioInstance == dev then w._radioIdx = i end end
    if w._activeTab ~= "radio" or not w._drawerOpen then return false end
    local t = twOf(w)
    if not (t and t.dev == dev) then return false end
    local _, atCard = cardWidthNow(w)
    return atCard and settled(w)
end
local function charRadioReady(dev)
    local w = CW()
    if not w then return false end
    pokeN = pokeN + 1
    if (w._activeTab ~= "radio" or not w._drawerOpen) and pokeN % 15 == 1 then charTab("radio") end
    if w._activeTab ~= "radio" or not w._drawerOpen then return false end
    local t = twOf(w)
    if not (t and t.dev == dev) then return false end
    local _, atCard = cardWidthNow(w)
    return atCard and settled(w)
end
local Z_f0
local function hamPhase()
    backAtSpot()
    step(5, function() if not (WW() and WW():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(pn) end; pokeN = 0 end)
    waitFor(5, POLL_CAP, function() return worldRadioReady(ham) end, function()
        local w, t = WW(), twOf(WW())
        check(w._activeTab == "radio" and w._drawerOpen == true, "ham: the Radio tab is open on the set (tab " .. tostring(w._activeTab) .. ", drawer " .. tostring(w._drawerEffW) .. " px)")
        local dw = math.floor(w._drawerEffW or 0)
        local k0 = ZeD.Px.k(root())
        local room = dw - ZeD.T.sp.scrollbarW
        local want, ww = ZeD.Px.pickWidth("ham_civilian", room, k0)
        if not ww then
            local base = ZeD.PhysPx.plates.ham_civilian
            want = (base.w * k0 > room and ZeD.PhysPx.plates.ham_civilian_n) and "ham_civilian_n" or "ham_civilian"
        end
        say(string.format("ham [%s, root %.2f, zoom %d]: tab %d px, drawn %s (zoom %s), want %s", PH, root(), k0, dw,
            tostring(t and t.pid), tostring(t and t.k), tostring(want)))
        check(t and t.pid == want, "ham: the face that fills the drawer is drawn (want " .. tostring(want) .. ", drawn " .. tostring(t and t.pid) .. ")")
        local des = t and ZeD.PhysPx.plates[t.pid]
        check(des and des.w * (t.k or k0) <= room, "ham: it sits inside the drawer (" .. tostring(des and des.w * (t.k or k0)) .. " of " .. room .. " px)")
        shot(PH .. "_ham")
        local vol = hitOf(t, "vol") or firstHit(t, "pwr") or firstHit(t, "power")
        if vol then clickHit(w, vol) end
    end)
    step(20, function()
        local dv = ham:getDeviceData()
        check(dv:getIsTurnedOn(), "ham: VOL / power turns it on")
        local t = twOf(WW())
        local tune = hitOf(t, "tune") or firstHit(t, "tune") or firstHit(t, "dial")
        Z_f0 = dv:getChannel()
        if tune then clickHit(WW(), tune, "r") else say("ham: no tuning control on the face (" .. tostring(t and #t.hits) .. " controls)") end
    end)
    step(20, function()
        local dv = ham:getDeviceData()
        check(dv:getChannel() ~= Z_f0, "ham: TUNE moves the frequency (" .. tostring(Z_f0) .. " -> " .. tostring(dv:getChannel()) .. ")")
        pcall(function() dv:setIsTurnedOn(false) end)
        showTab("loot")
    end)
end
local function walkiePhase()
    step(5, function()
        handWas = handWas or { p:getPrimaryHandItem() }
        p:setPrimaryHandItem(walkie)
        if not (CW() and CW():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(pn) end
    end)
    step(40, function()
        -- (director, Oct 30 2026: equipping a radio no longer switches the Character window to its Radio tab; the tab appears)
        local shown = false
        for _, z in ipairs(CW()._tabStripPanel and CW()._tabStripPanel._hitZones or {}) do if z.id == "tab:radio" then shown = true end end
        check(CW()._activeTab ~= "radio" and shown, "a radio in the hand: the Radio tab appears, the window stays on " .. tostring(CW()._activeTab))
        pokeN = 0
    end)
    waitFor(5, POLL_CAP, function() return charRadioReady(walkie) end, function()
        local w, t = CW(), twOf(CW())
        local dw = math.floor(w._drawerEffW or 0)
        say(string.format("walkie [%s, root %.2f]: tab %d px (half %d), drawn %s (zoom %s)", PH, root(), dw, ZeD.T.px(220), tostring(t and t.pid), tostring(t and t.k)))
        check(math.abs(dw - ZeD.T.px(220)) <= 1, "walkie: the tab is the half card (" .. dw .. " px, want " .. ZeD.T.px(220) .. ")")
        shot(PH .. "_walkie")
        local vol = hitOf(t, "vol")
        if vol then clickHit(w, vol) else say("walkie: no VOL on the face") end
    end)
    step(20, function()
        local on = false
        pcall(function() on = walkie:getDeviceData():getIsTurnedOn() end)
        check(on, "walkie: VOL turns it on")
        pcall(function() walkie:getDeviceData():setIsTurnedOn(false) end)
        charTab("loot")
    end)
end

-- ---- every scale; then 0.64, the narrow faces
local SCALES = { 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 0.64 }
for _, s in ipairs(SCALES) do
    step(10, function()
        stopActions()
        FORCED = (s < 0.7)
        Sc.override = s; Sc.refresh(); ZeD.applyTheme()
        PH = scaleName()
        say(string.format("phase %.2f: root %.2f", s, root()))
    end)
    step(60, function() pcall(ZeD_Window.resetLayout) end)
    step(60, function() end)
    stationPhase(PH)
    objectPhase()
    hamPhase()
    if s >= 0.7 then walkiePhase() end
end
step(5, function() if handWas then p:setPrimaryHandItem(handWas[1]) end end)

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
