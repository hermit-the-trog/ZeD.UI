-- ZeDUI/tools/qa/bx_farm.lua  (Nov 21 2026, QA beast day): farm and ranch under stress, at the farm site.
-- Built on rt_kit.lua (run it first, after zedqa_prelude.lua); grep "ZEDQA bx_farm". No pictures. About four minutes.
--
-- WHERE: the character goes to the farm point (1635,14221, as zedqa_farm_spot.lua does), waits for the squares to
-- load, and the nearest centre with an open 17 x 17 (no tree, wall, fence, building piece or animal zone, one square of
-- margin) is found the same way. Everything is staged inside that square. The character comes home at the end.
--
-- FARM (ObjectCardFarm.lua, the card in the World window's drawer; plots 2, 3 and 4 squares east of the centre)
--   dig      a furrow dug by the game's own action and stopped half way (no furrow, nothing queued); then dug for real
--            (ISPlowAction) on plot 2; plots 1 and 3 are plowed by the farming system (no grass is cut there)
--   card     the plot's Info (ISFarmingMenu.onInfo, hooked) opens the card: Empty, only Sow, waiting with no seed; the
--            plots it lists are the plots the game has in reach
--   sow      ONE seed carried: its row, Sow, the plot is seeded and the card stays on it; the next plot then has no
--            seed row (the seed is used up); five seeds and Sow pressed twice in one frame; the row's count is the
--            game's count; both windows shut and opened with the card up
--   water    water set to 20: the card reads it, Water waits with no water carried; a full bottle: Water is live; the
--            watering started (real time), the Animals tab pressed mid-action, the action stopped; watered for real: the
--            card reads the new level; at 100 Water is gone; the bottle emptied while the card shows: Water waits again
--   fertilize the card's Fertilize runs the game's action
--   harvest  the plant grown to harvest (the farming system's own grow step, the debug way): Harvest is live and the
--            main verb; harvested: the card reads the plot's new state
--   uproot   a rotten plant: the tag, no Water, Dig up asks (Cancel keeps it, the second time Yes digs it up with the
--            game's ISShovelAction) and the card steps to a plot still there; < and > hammered 30 times; the last plots
--            taken away under the card: it closes when no plot is in reach
-- RANCH (AnimalsTab.lua, AnimalsQuick.lua, ObjectCardTrough.lua, ObjectCardHutch.lua)
--   zone     drawn with ZeD's own zone drawing (the controller's path): a 1 x 1 is refused, B backs out, the windows
--            shut mid-drawing hand the world menu back, a zone 57 wide is refused, then the 17 x 17 is made
--   animals  a cow, a ewe and a hen made in it: the zone's roster holds all three; sub-tabs flipped ten times, Back
--            pressed past the top
--   trough   a trough staged, opened from the Animals tab's own row code (AT.openStruct): Empty; filled with water (the
--            game's debug fill): the litres; Empty asks and empties; a feed bag added by its row; the trough taken away
--            under the card: the card closes
--   cow      the game's Info (AnimalContextMenu.onAnimalInfo, hooked) shows the cow in the Animals tab; petted (the
--            game's action) with the view up; Milk pressed twice and stopped twice (nothing left queued); milked for real
--            (game speed 2); Feed: greyed with no food, the picker opened and the carrot gone before the pick (nothing
--            starts), then fed for real
--   hen      picked up (the game's action) while its view is open, the roster agrees with the game; put down again
--            (the game's drop); the hen that comes back is found and counted
--   gone     the ewe ticked on the roster, its view opened, the ewe taken out of the world: the roster drops it by
--            itself, the view lets go of it, its tick goes, Milk and Walk to on it are refused without an error
--   hutch    a hen house with one hen: the card counts her; she is taken out under the card: the count follows; the
--            house taken away under the card: the card closes
--   remove   the zone's Remove asks, Cancel keeps the zone, Remove takes it and the page steps back to the overview
-- Every surface is measured with RT.bounds. ZeD code is called inside a pcall: a caught error is a FAIL line.
--
-- PUT BACK: the game's actions stopped, speed 1, the food picker and the card shut, a zone drawing ended; the hen house
-- (its hens first), the trough, every plot (and the squares' plowDay), every animal made (the hen that was put down
-- too), every zone made; anything new lying on the staged squares; everything new on the character taken away (seeds,
-- tools, the harvest, milk), the character's own seeds, fluid containers, fertilizer, feed and cow food (set aside at
-- the start) given back where they were; hands, god mode, the instant-action cheat, body stiffness, health; the
-- Animals tab's view, the World window's tab, both windows as found; the character home on the drag strip.
-- Known leftovers: the grass cut on plot 2 (one square: the game's dig and dig-up cut it) and any Farming or Husbandry
-- XP the game's own actions gave.

if not RT then
    print("ZEDQA bx_farm ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA bx_farm VERDICT FAIL 1")
    print("ZEDQA bx_farm DONE")
    return
end

local Q = RT.make("bx_farm")
Q.maxMs = 420000   -- (seven minutes, then the queue jumps to the put-back)
local Z = ZeD or {}
local S = { off = {}, plots = {}, plowDay = {}, animals = {}, mine = {}, gone = {}, zones = {}, taken = {}, had = {},
            pre = {}, stiff = {}, woPre = {}, kept = 0 }
local H = {}
S.p, S.pn = RT.p, RT.pn
S.FARM = { x = 1635, y = 14221 }
S.HALF, S.SEARCH = 8, 24
S.OC, S.AT, S.AQ, S.AP = Z.ObjectCards, Z.AnimalsTab, Z.AnimalsQuick, Z.AnimalsAlertPoller
S.WWm, S.CWm = ZeD_WorldWindow, ZeD_CharacterWindow
S.BLOCK = { "wall", "fenc", "door", "window", "gate", "roof", "location_", "fixtures_", "furniture_", "appliances_" }
S.SEED = "Base.CarrotSeed"

-- ===================================================================== the queue's wrappers
-- a step of a scene: skipped when the run cannot go on (S.dead) or its scene could not be staged (S.off[sec])
local function step(n, sec, fn)
    Q.step(n, function()
        if S.dead or (sec and S.off[sec]) then return end
        fn()
    end)
end
-- wait up to ms of real time for cond(), then fn(ok)
local function wait(ms, sec, cond, fn)
    local st = {}
    Q.waitFor(1, 200000, function()
        if S.dead or (sec and S.off[sec]) then return true end
        st.t = st.t or getTimestampMs()
        local okc, hit = pcall(cond)
        if okc and hit then st.ok = true; return true end
        return getTimestampMs() - st.t >= ms
    end, function()
        if S.dead or (sec and S.off[sec]) then return end
        fn(st.ok == true)
    end)
end
local function pause(ms) Q.waitMs(ms) end

-- ===================================================================== helpers
function H.off(sec, why) S.off[sec] = true; Q.skip("the " .. sec .. " scene", why) end
-- ZeD code under test: a caught error is a FAIL line and the script goes on
function H.try(what, fn, a, b, c, d)
    if type(fn) ~= "function" then Q.check(false, what .. ": the function is there", type(fn)); return false, nil end
    local ok, r1, r2 = pcall(fn, a, b, c, d)
    if not ok then Q.check(false, what .. ": ran without an error", r1); return false, nil end
    return true, r1, r2
end
function H.W() return RT.ww() end
function H.card()
    if S.WWm and S.WWm.getObjectCard then return S.WWm.getObjectCard(S.pn) end
    return nil
end
function H.e() local c = H.card(); return c and c.entry or nil end
function H.t() local e = H.e(); return e and e.t or nil end
function H.d() local t = H.t(); return t and t.d or nil end
function H.kind() local e = H.e(); return e and e.def and e.def.id or nil end
function H.zone(fid)
    local c = H.card()
    for _, z in ipairs(c and c._zones or {}) do if z.fid == fid then return z end end
    return nil
end
-- a zone's action, as the mouse's release over it and the pad's A run it: ok, error words
function H.press(fid)
    local c, z = H.card(), H.zone(fid)
    if not (c and z) then return false, "no zone " .. tostring(fid) end
    if not z.run then return false, "zone " .. tostring(fid) .. " has no action" end
    local ok, err = pcall(z.run, c, c:player())
    if not ok then return false, tostring(err) end
    return true, nil
end
function H.verb(id)
    local t = H.t()
    for _, v in ipairs(t and t.verbs or {}) do if v.id == id then return v end end
    return nil
end
function H.verbIds()
    local t, ids = H.t(), {}
    for _, v in ipairs(t and t.verbs or {}) do ids[#ids + 1] = tostring(v.id) end
    return table.concat(ids, ",")
end
function H.pill()
    local e = H.e()
    if not (e and e.t and e.t.d and e.def and e.def.pill) then return nil end
    local ok, s = pcall(e.def.pill, e.t)
    return ok and s or nil
end
function H.fresh() local t = H.t(); if t and S.OC then t._refreshT = S.OC.REFRESH end end
function H.close() if H.card() and S.WWm.closeObjectCard then pcall(S.WWm.closeObjectCard, S.pn) end end
-- the card is on screen and drawing (its prerender stamps the zones each frame)
function H.live()
    local w, c = H.W(), H.card()
    if not (w and c) then return false end
    local dr = w._itemDrawerPanel
    return (w:getIsVisible() and not w.windowShaded and (dr == nil or dr:getIsVisible()) and c:getIsVisible()) and true or false
end
function H.absent(fid) return H.live() and H.zone(fid) == nil end
function H.qn()
    local q = ISTimedActionQueue.queues and ISTimedActionQueue.queues[S.p]
    return q and q.queue and #q.queue or 0
end
function H.idle() return not ISTimedActionQueue.isPlayerDoingAction(S.p) and H.qn() == 0 end
function H.queued(typ) return ISTimedActionQueue.hasActionType(S.p, typ) == true end
function H.stop() pcall(function() ISTimedActionQueue.clear(S.p) end) end
function H.put(x, y)
    local p = S.p
    p:setX(x); p:setY(y); p:setZ(0); p:setLastX(x); p:setLastY(y); p:setLastZ(0)
end
function H.centre() if S.cx then H.put(S.cx + 0.5, S.cy + 0.5) end end
function H.instant(on) S.p:setTimedActionInstantCheat(on and true or false) end
function H.ff(on)
    local f = ZEDQA_SPEED or setGameSpeed
    if not f then return end
    local want = on and 2 or 1
    if getGameSpeed() ~= want then f(want) end
end
function H.sq(dx, dy) return getCell():getGridSquare(S.cx + dx, S.cy + dy, 0) end
function H.mark(o) if o then o:getModData().ZeDQA_spawned = true end end
function H.give(ft)
    local it = RT.give(ft)
    if not it then Q.say("could not give " .. tostring(ft)) end
    return it
end
function H.drop(it)
    if not it then return end
    local c = it:getContainer()
    if c then S.p:removeFromHands(it); c:Remove(it) end
end
function H.fill(it, full)
    local fc = it and it:getFluidContainer()
    if not fc then return end
    fc:Empty()
    if full then fc:addFluid(Fluid.Water, fc:getCapacity()) end
end
function H.count(ft) return S.p:getInventory():getAllTypeRecurse(ft):size() end
function H.objOn(sq, cls)
    if not sq then return nil end
    local objs = sq:getObjects()
    for k = 0, objs:size() - 1 do
        local o = objs:get(k)
        if instanceof(o, cls) then return o end
    end
    return nil
end
function H.near(a, b, tol) return type(a) == "number" and type(b) == "number" and math.abs(a - b) <= tol end

-- ---- both windows held down while the script reads them (an unpinned window rolls up 2 s after the pointer leaves
-- it, and a rolled-up card stops drawing and ticking: zedqa_cov_farmcards.lua, H.keepDown)
function H.hold(w)
    if not w then return end
    w._autoShaded = false
    if w.windowShaded then w:setWindowShaded(false) end
    w._outSince = getTimestampMs() + 600000
end
function H.keepTick()
    if not S.holdOn then return end
    H.hold(RT.ww())
    H.hold(RT.cw())
end

-- ---- the open ground (zedqa_farm_spot.lua's rules)
function H.blocked(cell, x, y)
    local s = cell:getGridSquare(x, y, 0)
    if not s then return "not loaded" end
    if s:getRoom() then return "indoors" end
    if s:HasTree() then return "a tree" end
    if not s:isFree(false) then return "not free" end
    local objs = s:getObjects()
    for i = 0, objs:size() - 1 do
        local spr = objs:get(i):getSprite()
        local nm = string.lower(tostring(spr and spr:getName() or ""))
        for _, w in ipairs(S.BLOCK) do if nm:find(w, 1, true) then return nm end end
    end
    return nil
end
function H.zoneOpen(cell, cx, cy)
    local half = S.HALF
    for dx = -half - 1, half + 1 do
        for dy = -half - 1, half + 1 do
            if DesignationZoneAnimal.getZone(cx + dx, cy + dy, 0) then return false end
            if math.abs(dx) <= half and math.abs(dy) <= half and H.blocked(cell, cx + dx, cy + dy) then return false end
        end
    end
    return true
end
function H.findSpot()
    local cell = getCell()
    local best, bestD = nil, nil
    for r = 0, S.SEARCH do
        for dx = -r, r do
            for dy = -r, r do
                if math.max(math.abs(dx), math.abs(dy)) == r then
                    local d = dx * dx + dy * dy
                    if (not bestD or d < bestD) and H.zoneOpen(cell, S.FARM.x + dx, S.FARM.y + dy) then
                        best, bestD = { S.FARM.x + dx, S.FARM.y + dy }, d
                    end
                end
            end
        end
        if best then break end
    end
    return best
end
function H.loaded()
    local cell = getCell()
    for _, o in ipairs({ { 12, 12 }, { -12, 12 }, { 12, -12 }, { -12, -12 }, { 0, 0 } }) do
        if not cell:getGridSquare(S.FARM.x + o[1], S.FARM.y + o[2], 0) then return false end
    end
    return true
end
-- every square of the staged ground (the 17 x 17 and one square round it)
function H.eachStaged(fn)
    if not S.cx then return end
    for dx = -S.HALF - 1, S.HALF + 1 do
        for dy = -S.HALF - 1, S.HALF + 1 do
            local sq = H.sq(dx, dy)
            if sq then fn(sq) end
        end
    end
end

-- ---- the farming system
function H.plantC(sq)
    if not (sq and CFarmingSystem and CFarmingSystem.instance) then return nil end
    return CFarmingSystem.instance:getLuaObjectOnSquare(sq)
end
function H.plantS(sq)
    if not (sq and SFarmingSystem and SFarmingSystem.instance) then return nil end
    return SFarmingSystem.instance:getLuaObjectOnSquare(sq)
end
function H.stateOf(sq) local c = H.plantC(sq); return c and c.state or nil end
function H.waterOf(sq) local lo = H.plantS(sq); return lo and lo.waterLvl or nil end
function H.setWater(sq, v)
    local lo = H.plantS(sq)
    if lo then lo.waterLvl = v; lo:saveData() end
end
function H.unplant(sq)
    local lo = H.plantS(sq)
    if lo then SFarmingSystem.instance:removePlant(lo); return true end
    return false
end
-- the plots the game has within the card's reach of the character (the card's own list must agree)
function H.plotsInReach()
    local n = 0
    local sq0 = S.p:getCurrentSquare()
    if not sq0 then return 0 end
    local r = (S.OC and S.OC.LEASH) or 6
    for y = sq0:getY() - r, sq0:getY() + r do
        for x = sq0:getX() - r, sq0:getX() + r do
            local pl = H.plantC(getCell():getGridSquare(x, y, sq0:getZ()))
            if pl and pl:getIsoObject() then n = n + 1 end
        end
    end
    return n
end
-- the plant grown to harvest with the farming system's own grow step (water, health and pests held good)
function H.grow(sq)
    local lo = H.plantS(sq)
    if not lo then return false end
    for _ = 1, 14 do
        if lo.state ~= "seeded" or lo:canHarvest() then break end
        lo.waterLvl = math.max(lo.waterNeeded or 0, 60)
        if lo.waterNeededMax and lo.waterLvl > lo.waterNeededMax then lo.waterLvl = lo.waterNeededMax end
        lo.mildewLvl, lo.aphidLvl, lo.fliesLvl, lo.slugsLvl = 0, 0, 0, 0
        lo.health = 100
        SFarmingSystem.instance:growPlant(lo, nil, true)
    end
    local spr = farming_vegetableconf.getSpriteName(lo)
    if spr then lo:setSpriteName(spr) end
    lo:saveData()
    return lo.state == "seeded" and lo:canHarvest() == true
end
function H.seedRow()
    local d = H.d()
    for i, r in ipairs(d and d.seeds or {}) do if r.seedName == S.SEED then return r, i end end
    return nil, nil
end
function H.openPlot(sq)
    local c = H.plantC(sq)
    if not c then return false end
    return H.try("the plot's Info (ISFarmingMenu.onInfo)", ISFarmingMenu.onInfo, nil, c, sq, S.p)
end
function H.onPlot(sq)
    local t = H.t()
    return H.kind() == "plant" and t ~= nil and t.sq == sq
end

-- ---- animals
function H.cellAnimals()
    local out = {}
    local list = getCell():getAnimals()
    local it = list and list:iterator()
    while it and it:hasNext() do
        local a = it:next()
        if a then out[#out + 1] = a end
    end
    return out
end
function H.inWorld(a)
    for _, x in ipairs(H.cellAnimals()) do if x == a then return true end end
    return false
end
function H.spawn(kind, dx, dy)
    local def = AnimalDefinitions.getDef(kind)
    local breed = def and def:getBreeds():get(0)
    if not breed then Q.say("no breed for " .. tostring(kind)); return nil end
    local a = addAnimal(getCell(), S.cx + dx, S.cy + dy, 0, kind, breed)
    if not a then Q.say("could not make a " .. tostring(kind)); return nil end
    H.mark(a)
    S.animals[#S.animals + 1] = a
    S.mine[a] = true
    a:setDebugStress(0)
    local b = a:getBehavior()
    if b then b:setBlockMovement(true) end
    return a
end
-- an animal out of the game, once: off the perch when it sits in a hen house, off the world and its square (never
-- remove(): zedqa_cov_farmcards.lua, H.takeAwayOut)
function H.takeAway(a)
    if not a or S.gone[a] then return false end
    S.gone[a] = true
    local h = a:getHutch()
    if h then h:removeAnimal(a) end
    if H.inWorld(a) then a:removeFromWorld(); a:removeFromSquare() end
    return true
end
function H.beside(a)
    if a then H.put(math.floor(a:getX()) + 1.5, math.floor(a:getY()) + 0.5) end
end
function H.zoneObj()
    if not S.zoneName then return nil end
    return DesignationZoneAnimal.getZoneByName(S.zoneName)
end
function H.zoneCount()
    local all = DesignationZoneAnimal.getAllZones()
    return all and all:size() or 0
end
function H.roster() return S.AP.getAnimalsInZone(S.zoneName, S.pn) or {} end
function H.inRoster(a)
    for _, x in ipairs(H.roster()) do if x == a then return true end end
    return false
end
-- the game's own count for the zone
function H.gameHas(a)
    local z = H.zoneObj()
    local conn = z and z:getAnimalsConnected()
    return conn ~= nil and conn:contains(a) == true
end
function H.gameZoneN()
    local z = H.zoneObj()
    local conn = z and z:getAnimalsConnected()
    return conn and conn:size() or 0
end
function H.st() local w = H.W(); return w and S.AT.getState(w) or nil end
function H.bulk(id)
    local w = H.W()
    for _, b in ipairs(w and w._animalsBulkBtns or {}) do if b.id == id then return b end end
    return nil
end
function H.rosterRow(a)
    local w = H.W()
    for _, rz in ipairs(w and w._animalsRosterZones or {}) do if rz.animal == a then return rz end end
    return nil
end
function H.animalsTab() return H.try("the World window's Animals tab (openTab)", S.WWm.openTab, S.pn, "animals") end
function H.zonePage()
    local w = H.W()
    if w and S.zoneName then H.try("the zone's page (AT.navigate)", S.AT.navigate, w, "zone", S.zoneName, nil) end
end
function H.heldAnimal()
    local it = S.p:getPrimaryHandItem()
    if it and instanceof(it, "AnimalInventoryItem") then return it end
    return nil
end
-- a game window ZeD should have taken: closed, and said
function H.stray(typ)
    local t = RT.find(function(x) return x.Type == typ end)
    if t then t:removeFromUIManager(); return true end
    return false
end

-- ---- the character's own things the game's actions would reach for, set aside (given back at the end)
function H.asideTest(it)
    local ft = it:getFullType()
    if S.SEEDS[ft] or ft == "Base.Fertilizer" or ft == "Base.CompostBag" or ft == "Base.AnimalFeedBag" or ft == "Base.Carrots" then return true end
    if it:hasTag(ItemTag.FERTILIZER) or it:hasTag(ItemTag.COMPOST) then return true end
    return it:getFluidContainer() ~= nil
end
function H.takeAside(list)
    for k = list:size() - 1, 0, -1 do
        local it = list:get(k)
        local keep = (it:IsClothing() and it:isEquipped()) or (it:getAttachedSlot() > -1)
        local c = it:getContainer()
        if keep or not c then
            S.kept = S.kept + 1
        else
            S.p:removeFromHands(it)
            c:Remove(it)
            S.taken[#S.taken + 1] = { item = it, cont = c }
        end
    end
end
function H.setAside()
    S.SEEDS = {}
    for _, props in pairs(farming_vegetableconf.props) do
        if type(props) == "table" then
            if props.seedName then S.SEEDS[props.seedName] = true end
            for _, s in ipairs(props.seedTypes or {}) do S.SEEDS[s] = true end
        end
    end
    H.takeAside(S.p:getInventory():getAllEvalRecurse(function(it) return H.asideTest(it) == true end))
end
function H.asideFood(animal)
    if not (animal and S.AQ.eats) then return end
    H.takeAside(S.p:getInventory():getAllEvalRecurse(function(it) return S.AQ.eats(animal, it) == true end))
end

-- ===================================================================== 0. the ledger, the windows, the farm
function H.ledger()
    local p = S.p
    if ZEDQA_HOME then pcall(ZEDQA_HOME, Q.tag) end
    S.home = { x = p:getX(), y = p:getY() }
    S.primary, S.secondary = p:getPrimaryHandItem(), p:getSecondaryHandItem()
    S.god = p:isGodMod() == true
    S.instant = p:isTimedActionInstantCheat() == true
    local parts = p:getBodyDamage():getBodyParts()
    for k = 0, parts:size() - 1 do S.stiff[k] = parts:get(k):getStiffness() end
    local all = p:getInventory():getAllEvalRecurse(function(it) return true end)
    for k = 0, all:size() - 1 do S.had[all:get(k)] = true end
    S.zones0 = H.zoneCount()
    S.staged = true
    p:setGodMod(true)
    H.setAside()
    Q.say("set aside " .. #S.taken .. " of the character's own things (kept, worn or on the belt: " .. S.kept .. ")")
end
Q.step(5, function()
    local world = getWorld() and getWorld():getWorld()
    if world ~= "ZeD-QA" then S.dead = true; Q.skip("the whole script", "not the ZeD-QA save: " .. tostring(world)); return end
    if not (S.OC and S.OC.kinds and S.AT and S.AQ and S.AP and S.WWm and S.CWm) then
        S.dead = true
        Q.check(false, "ZeD's Animals tab and object cards are loaded", "missing")
        return
    end
    if Z.Safe and Z.Safe.on and Z.Safe.on() then S.dead = true; Q.skip("the whole script", "ZeD is in safe mode: the game's own windows would open"); return end
    if not S.p or S.p:isDead() then S.dead = true; Q.skip("the whole script", "no living character"); return end
    H.ledger()
    S.opened = not RT.isOpen()
    RT.pairOpen()
    S.holdOn = true
    Events.OnTick.Add(H.keepTick)
end)
pause(900)
step(2, nil, function()
    local w = H.W()
    if not Q.check(w ~= nil and w:getIsVisible(), "the World window is open", tostring(w ~= nil)) then S.dead = true; return end
    S.tab0 = w._activeTab
    local st = S.AT.getState(w)
    S.at0 = { submode = st.submode, view = st.view, zoneName = st.zoneName, animalRef = st.animalRef, prevView = st.prevView }
    H.close()
    H.put(S.FARM.x + 0.5, S.FARM.y + 0.5)
    S.tFarm = getTimestampMs()
    Q.say("moved to the farm point " .. S.FARM.x .. "," .. S.FARM.y)
end)
wait(15000, nil, function() return getTimestampMs() - S.tFarm > 3000 and H.loaded() end, function(ok)
    if not ok then Q.say("the farm's squares were not all loaded after 15 s: the search goes on what is there") end
    local okF, best = pcall(H.findSpot)
    if not (okF and best) then
        Q.skip("the farm, ranch, trough and hutch scenes", "no open 17 x 17 within " .. S.SEARCH .. " squares of the farm point (" .. tostring(best) .. ")")
        S.off.farm, S.off.ranch, S.off.trough, S.off.hutch = true, true, true, true
        return
    end
    S.cx, S.cy = best[1], best[2]
    H.centre()
    Q.say("open ground: centre " .. S.cx .. "," .. S.cy)
end)
pause(1200)
step(2, nil, function()
    if not S.cx then return end
    H.eachStaged(function(sq)
        local wos = sq:getWorldObjects()
        for k = 0, wos:size() - 1 do S.woPre[wos:get(k)] = true end
    end)
    Q.check(S.p:getCurrentSquare() ~= nil and math.abs(S.p:getX() - (S.cx + 0.5)) < 1, "the character stands on the farm's open ground",
        math.floor(S.p:getX()) .. "," .. math.floor(S.p:getY()))
end)

-- ===================================================================== 1. FARM
-- 1a. a furrow started and stopped, then dug; three plots
step(5, "farm", function()
    if not (ISFarmingMenu and ISFarmingMenu._zed_onInfo and ISPlowAction and SFarmingSystem and SFarmingSystem.instance and CFarmingSystem) then
        H.off("farm", "ZeD's hook on the plot's Info (ISFarmingMenu.onInfo) or the farming system is missing"); return
    end
    S.P = { H.sq(2, 0), H.sq(3, 0), H.sq(4, 0) }
    for i = 1, 3 do
        if not S.P[i] or H.plantC(S.P[i]) then H.off("farm", "plot " .. i .. " is not free ground"); return end
        S.plots[i] = S.P[i]
        S.plowDay[i] = S.P[i]:getModData().plowDay
    end
    S.shovel = H.give("Base.Shovel")
    H.instant(false)
    ISTimedActionQueue.add(ISPlowAction:new(S.p, S.P[2], S.shovel))
end)
pause(700)
step(2, "farm", function()
    S.digBusy = not H.idle()
    H.stop()
end)
pause(400)
step(2, "farm", function()
    Q.check(S.digBusy, "the game's dig was under way before it was stopped", tostring(S.digBusy))
    Q.check(H.idle() and H.plantC(S.P[2]) == nil, "a dig stopped half way: no furrow, nothing queued", "queue " .. H.qn())
    H.instant(true)
    ISTimedActionQueue.add(ISPlowAction:new(S.p, S.P[2], S.shovel))
    SFarmingSystem.instance:plow(S.P[1])
    SFarmingSystem.instance:plow(S.P[3])
end)
wait(6000, "farm", function() return H.stateOf(S.P[2]) == "plow" and H.idle() end, function(ok)
    if not ok then
        H.stop()
        Q.skip("a furrow dug by the game's own action", "ISPlowAction did not finish in 6 s: plot 2 is plowed by the farming system")
        if not H.plantS(S.P[2]) then SFarmingSystem.instance:plow(S.P[2]) end
    end
end)
wait(3000, "farm", function() return H.stateOf(S.P[1]) == "plow" and H.stateOf(S.P[2]) == "plow" and H.stateOf(S.P[3]) == "plow" end, function(ok)
    if not ok then H.off("farm", "three plowed plots could not be staged"); return end
    H.openPlot(S.P[1])
end)
wait(4000, "farm", function() return H.kind() == "plant" end, function(ok)
    if not Q.check(ok and H.d() ~= nil, "farm: the plot's Info opens the farm card", tostring(H.kind())) then
        H.stray("ISFarmingInfo")
        H.off("farm", "the farm card did not open")
        return
    end
    local t, d, e = H.t(), H.d(), H.e()
    Q.check(d.plowed and H.pill() == Z.tr("UI_ZeD_Farm_PillEmpty"), "farm: a plowed plot is tagged Empty", tostring(H.pill()))
    local sow = H.verb("sow")
    Q.check(#t.verbs == 1 and sow ~= nil and sow.enabled == false, "farm: plowed with no seed carried: only Sow, waiting", H.verbIds())
    local n = H.plotsInReach()
    Q.check(e.list ~= nil and #e.list == n, "farm: the card lists the plots the game has in reach", tostring(e.list and #e.list) .. " vs " .. n)
    RT.bounds(Q, "the farm card")
    S.key1 = t.key
    H.give(S.SEED)
    H.fresh()
end)
-- 1b. one seed: sown, and gone from the next plot's card
pause(500)
step(2, "farm", function()
    local row, ri = H.seedRow()
    local sow = H.verb("sow")
    Q.check(row ~= nil and row.count == H.count(S.SEED), "farm: the one seed carried is a Sow row", tostring(row and row.count) .. " vs " .. H.count(S.SEED))
    Q.check(sow ~= nil and sow.enabled == true and sow.primary == true, "farm: with a seed, Sow is live and the main verb", H.verbIds())
    if not row then H.off("farm", "no seed row to sow from"); return end
    local ok, err = H.press("farm:sow:" .. ri)
    Q.check(ok, "farm: the seed row's Sow runs", err)
end)
wait(8000, "farm", function() return H.stateOf(S.P[1]) == "seeded" and H.idle() end, function(ok)
    Q.check(ok, "farm: Sow (the game's action) seeded the plot", tostring(H.stateOf(S.P[1])))
    if not ok then H.stop(); H.off("farm", "the plot was not seeded"); return end
    H.fresh()
end)
pause(500)
step(2, "farm", function()
    local t, d = H.t(), H.d()
    Q.check(H.kind() == "plant" and t ~= nil and t.key == S.key1 and d ~= nil and not d.plowed and d.state == "seeded",
        "farm: after sowing the card stays on the plot and reads it seeded", tostring(d and d.state))
    local ok, err = H.press("oc:next")
    Q.check(ok, "farm: > steps on", err)
end)
pause(600)
step(2, "farm", function()
    local t, d = H.t(), H.d()
    if not (t and d) then Q.check(false, "farm: the card is still open after >", tostring(H.kind())); H.off("farm", "the card closed"); return end
    Q.check(t.key ~= S.key1 and d.plowed, "farm: > shows another, plowed plot", tostring(t.key))
    local sow = H.verb("sow")
    Q.check(H.count(S.SEED) == 0 and #d.seeds == 0 and sow ~= nil and sow.enabled == false and H.absent("farm:sow:1"),
        "farm: the seed used up: no Sow row is left on the next plot, Sow waits", "rows " .. #d.seeds .. ", carried " .. H.count(S.SEED))
    for _ = 1, 5 do H.give(S.SEED) end
    H.fresh()
end)
-- 1c. five seeds, Sow pressed twice in one frame
pause(500)
step(2, "farm", function()
    local t = H.t()
    local row, ri = H.seedRow()
    if not (t and row) then Q.check(false, "farm: five seeds carried are a Sow row", tostring(row)); H.off("farm", "no seed row"); return end
    Q.check(row.count == H.count(S.SEED), "farm: the Sow row counts the seeds carried", row.count .. " vs " .. H.count(S.SEED))
    S.sq2 = t.sq
    local ok1, e1 = H.press("farm:sow:" .. ri)
    local ok2, e2 = H.press("farm:sow:" .. ri)
    Q.check(ok1 and ok2, "farm: Sow pressed twice in one frame runs twice without an error", tostring(e1 or e2))
end)
wait(8000, "farm", function() return H.stateOf(S.sq2) == "seeded" and H.idle() end, function(ok)
    Q.check(ok, "farm: after the double press the plot is seeded and nothing is left queued", tostring(H.stateOf(S.sq2)) .. ", queue " .. H.qn())
    if not ok then H.stop() end
    H.press("oc:next")
end)
pause(1300)
step(2, "farm", function()
    local d, e = H.d(), H.e()
    local row = H.seedRow()
    if d and d.plowed then
        Q.check((row and row.count or 0) == H.count(S.SEED), "farm: on the third plot the Sow row counts the seeds left", tostring(row and row.count) .. " vs " .. H.count(S.SEED))
    else
        Q.skip("the Sow row's count on the third plot", "> did not land on a plowed plot")
    end
    Q.check(e ~= nil and e.list ~= nil and #e.list == H.plotsInReach(), "farm: the card still lists the plots in reach", tostring(e and e.list and #e.list) .. " vs " .. H.plotsInReach())
    -- both windows shut and opened with the card up
    RT.pairShut()
end)
pause(500)
step(2, "farm", function() RT.pairOpen() end)
pause(900)
step(2, "farm", function()
    local c = H.card()
    Q.check(c == nil or (H.kind() == "plant" and H.t() ~= nil), "farm: both windows shut and opened: the card is closed or whole", tostring(H.kind()))
    RT.bounds(Q, "the windows opened again at the farm")
    H.setWater(S.P[1], 20)
    H.openPlot(S.P[1])
end)
-- 1d. water
wait(4000, "farm", function() return H.onPlot(S.P[1]) end, function(ok)
    Q.check(ok, "farm: the Info on the seeded plot opens its card again", tostring(H.kind()))
    if not ok then H.off("farm", "the card did not open on plot 1"); return end
    H.fresh()
end)
pause(500)
step(2, "farm", function()
    local d, w = H.d(), H.verb("water")
    local lvl = H.waterOf(S.P[1])
    Q.check(d ~= nil and H.near(d.water, lvl, 0.5), "farm: water set to 20: the card reads it", tostring(d and d.water) .. " vs " .. tostring(lvl))
    Q.check(w ~= nil and w.sensible ~= false and w.enabled == false, "farm: thirsty with no water carried: Water waits", tostring(w and w.enabled))
    S.bottle = H.give("Base.WaterBottle")
    H.fill(S.bottle, true)
    H.fresh()
end)
pause(500)
step(2, "farm", function()
    local w = H.verb("water")
    Q.check(w ~= nil and w.enabled == true, "farm: with a full bottle carried, Water is live", tostring(w and w.enabled))
    H.instant(false)
    local ok, err = H.press("oc:verb:water")
    Q.check(ok and H.queued("ISWaterPlantAction"), "farm: Water queues the game's watering", tostring(err))
end)
pause(700)
step(2, "farm", function() H.animalsTab() end)
pause(500)
step(2, "farm", function()
    Q.check(H.card() == nil or H.t() ~= nil, "farm: a tab pressed mid-watering leaves the card closed or whole", tostring(H.kind()))
    H.stop()
end)
pause(400)
step(2, "farm", function()
    Q.check(H.idle(), "farm: the watering stopped: nothing queued", "queue " .. H.qn())
    H.instant(true)
    H.setWater(S.P[1], 20)
    H.openPlot(S.P[1])
end)
wait(4000, "farm", function() return H.onPlot(S.P[1]) end, function(ok)
    Q.check(ok, "farm: the card opens again over the Animals tab", tostring(H.kind()))
    if not ok then H.off("farm", "the card did not open on plot 1"); return end
    H.fresh()
end)
pause(500)
step(2, "farm", function()
    S.water0 = H.waterOf(S.P[1]) or 20
    local ok, err = H.press("oc:verb:water")
    Q.check(ok, "farm: Water pressed", err)
end)
wait(8000, "farm", function() return (H.waterOf(S.P[1]) or 0) > S.water0 + 1 and H.idle() end, function(ok)
    Q.check(ok, "farm: Water (the game's action) raised the plot's water", tostring(S.water0) .. " -> " .. tostring(H.waterOf(S.P[1])))
    if not ok then H.stop() end
    H.fresh()
end)
pause(500)
step(2, "farm", function()
    local d = H.d()
    Q.check(d ~= nil and H.near(d.water, H.waterOf(S.P[1]), 0.5), "farm: the card reads the new water level", tostring(d and d.water) .. " vs " .. tostring(H.waterOf(S.P[1])))
    H.setWater(S.P[1], 100)
    H.fresh()
end)
pause(500)
step(2, "farm", function()
    local w = H.verb("water")
    Q.check(w ~= nil and w.sensible == false and H.absent("oc:verb:water"), "farm: water at 100: Water is gone", tostring(w and w.sensible))
    H.setWater(S.P[1], 20)
    H.fill(S.bottle, false)
    H.fresh()
end)
pause(500)
step(2, "farm", function()
    local w = H.verb("water")
    Q.check(w ~= nil and w.enabled == false, "farm: the bottle emptied while the card shows: Water waits again", tostring(w and w.enabled))
    H.fill(S.bottle, true)
    H.setWater(S.P[1], 80)
    S.fertItem = H.give("Base.Fertilizer")
    H.fresh()
end)
-- 1e. fertilize, grow, harvest
pause(500)
step(2, "farm", function()
    local f = H.verb("fert")
    local lo = H.plantS(S.P[1])
    if not (S.fertItem and f and lo) then Q.skip("Fertilize", "no fertilizer could be given or the verb is missing"); S.fert0 = nil; return end
    Q.check(f.enabled == true, "farm: with fertilizer carried, Fertilize is live", tostring(f.enabled))
    S.fert0 = lo.fertilizer or 0
    local ok, err = H.press("oc:verb:fert")
    Q.check(ok, "farm: Fertilize pressed", err)
end)
wait(8000, "farm", function()
    if not S.fert0 then return true end
    local lo = H.plantS(S.P[1])
    return lo ~= nil and (lo.fertilizer or 0) > S.fert0 and H.idle()
end, function(ok)
    if S.fert0 then
        local lo = H.plantS(S.P[1])
        Q.check(ok, "farm: Fertilize (the game's action) fertilized the plant", tostring(S.fert0) .. " -> " .. tostring(lo and lo.fertilizer))
    end
    if not ok then H.stop() end
    local okG, ripe = pcall(H.grow, S.P[1])
    S.ripe = okG and ripe == true
    if not okG then Q.say("the grow step threw: " .. tostring(ripe)) end
    H.fresh()
end)
pause(700)
step(2, "farm", function()
    local lo, v = H.plantS(S.P[1]), H.verb("harvest")
    local can = lo ~= nil and lo:canHarvest() == true
    Q.check(v ~= nil and (v.enabled == true) == can, "farm: Harvest is live exactly when the game says the plant can be harvested", tostring(v and v.enabled) .. " vs " .. tostring(can))
    if not (S.ripe and can and v) then Q.skip("the harvest", "the plant could not be grown to harvest (state " .. tostring(lo and lo.state) .. ")"); S.ripe = false; return end
    Q.check(v.primary == true, "farm: ripe: Harvest is the main verb", tostring(v.primary))
    S.veg0 = H.count("Base.Carrots")
    local ok, err = H.press("oc:verb:harvest")
    Q.check(ok and H.queued("ISHarvestPlantAction"), "farm: Harvest queues the game's harvest", tostring(err))
end)
wait(8000, "farm", function()
    if not S.ripe then return true end
    local lo = H.plantS(S.P[1])
    return lo ~= nil and not lo:canHarvest() and H.idle()
end, function(ok)
    if S.ripe then
        Q.check(ok, "farm: Harvest (the game's action) took the crop", "carrots " .. tostring(S.veg0) .. " -> " .. H.count("Base.Carrots"))
        if not ok then H.stop() end
    end
    H.fresh()
end)
pause(600)
step(2, "farm", function()
    local d, c = H.d(), H.plantC(S.P[1])
    Q.check(H.kind() == "plant" and d ~= nil and c ~= nil and d.state == c.state, "farm: the card reads the plot's state after the harvest", tostring(d and d.state) .. " vs " .. tostring(c and c.state))
    local v = H.verb("harvest")
    if S.ripe then Q.check(v == nil or v.sensible == false, "farm: harvested: Harvest is gone", tostring(v and v.sensible)) end
    -- the second plot rots
    local lo2 = H.plantS(S.sq2)
    if lo2 and lo2.state == "seeded" then lo2:rottenThis() end
    H.openPlot(S.sq2)
end)
-- 1f. a rotten plant, dug up; the browse arrows; the last plots gone
wait(4000, "farm", function() return H.onPlot(S.sq2) end, function(ok)
    Q.check(ok, "farm: the Info on the second plot moves the card there", tostring(H.kind()))
    if not ok then H.off("farm", "the card did not open on the second plot"); return end
    H.fresh()
end)
pause(500)
step(2, "farm", function()
    local d, w, dig = H.d(), H.verb("water"), H.verb("dig")
    Q.check(d ~= nil and d.state == "rotten" and H.pill() == Z.tr("Farming_Rotten"), "farm: a rotten plant is tagged Rotten", tostring(d and d.state) .. " " .. tostring(H.pill()))
    Q.check(w == nil or w.sensible == false, "farm: a rotten plant is not watered", tostring(w and w.sensible))
    Q.check(dig ~= nil and dig.enabled == true and dig.confirm == Z.tr("UI_ZeD_Farm_ConfirmClear", string.lower(tostring(d and d.name))),
        "farm: with a shovel, Dig up is live and asks to clear the dead plant", tostring(dig and dig.confirm))
    local ok, err = H.press("oc:verb:dig")
    Q.check(ok, "farm: Dig up pressed", err)
end)
pause(400)
step(2, "farm", function()
    local c = H.card()
    local cf = c and c._confirm
    Q.check(cf ~= nil and cf.danger == true, "farm: Dig up asks first", tostring(cf and cf.text))
    H.press("oc:confirm:no")
end)
pause(400)
step(2, "farm", function()
    local c = H.card()
    Q.check(c ~= nil and c._confirm == nil and H.plantC(S.sq2) ~= nil, "farm: the question's Cancel keeps the plant", tostring(H.stateOf(S.sq2)))
    H.press("oc:verb:dig")
end)
pause(400)
step(2, "farm", function()
    local t = H.t()
    S.goneKey = t and t.key
    local ok, err = H.press("oc:confirm:yes")
    Q.check(ok, "farm: the question's Dig up runs", err)
end)
wait(8000, "farm", function() return H.plantC(S.sq2) == nil and H.idle() end, function(ok)
    Q.check(ok, "farm: Dig up (the game's action) took the plant away", tostring(H.stateOf(S.sq2)))
    if not ok then H.stop(); H.unplant(S.sq2) end
end)
pause(1300)
step(2, "farm", function()
    local t, e = H.t(), H.e()
    Q.check(H.kind() == "plant" and t ~= nil and t.key ~= S.goneKey and H.live(), "farm: the plot dug up from under the card: it steps to one still there",
        tostring(H.kind()) .. " " .. tostring(t and t.key))
    Q.check(e ~= nil and e.list ~= nil and #e.list == H.plotsInReach(), "farm: the card's list is the plots left", tostring(e and e.list and #e.list) .. " vs " .. H.plotsInReach())
    -- the browse arrows, thirty presses in one frame
    local bad = nil
    for i = 1, 30 do
        local fid = (i - math.floor(i / 3) * 3 == 0) and "oc:prev" or "oc:next"
        local ok, err = H.press(fid)
        local e2 = H.e()
        if not ok then bad = bad or (fid .. ": " .. tostring(err)) end
        if not (e2 and e2.list and e2.idx and e2.idx >= 1 and e2.idx <= #e2.list and e2.t == e2.list[e2.idx]) then bad = bad or ("press " .. i .. ": idx " .. tostring(e2 and e2.idx)) end
    end
    Q.check(bad == nil, "farm: < and > pressed thirty times keep the card on a listed plot", bad)
    RT.bounds(Q, "the farm card after the dig-up")
    -- the last plots, from under the card
    for i = 1, 3 do H.unplant(S.P[i]) end
end)
pause(1500)
step(2, "farm", function()
    local n = H.plotsInReach()
    Q.check((H.card() == nil) == (n == 0), "farm: every plot taken away under the card: it closes when no plot is in reach", "card " .. tostring(H.kind()) .. ", plots in reach " .. n)
    H.close()
end)

-- ===================================================================== 2. RANCH
-- 2a. the zone, drawn with ZeD's own drawing
step(5, "ranch", function()
    H.stop(); H.close(); H.instant(true); H.centre()
    if not (S.AT.startZoneCreate and S.AT.gpConfirm and S.AT.gpMoveCursor and S.AT.gpCancel and DesignationZoneAnimal and AnimalDefinitions and addAnimal) then
        H.off("ranch", "the Animals tab's zone drawing or the game's animals are missing"); return
    end
    H.animalsTab()
end)
wait(4000, "ranch", function() local w = H.W(); return w ~= nil and w._activeTab == "animals" end, function(ok)
    if not Q.check(ok, "ranch: the World window shows the Animals tab", tostring(H.W() and H.W()._activeTab)) then H.off("ranch", "the Animals tab did not open"); return end
    local w = H.W()
    H.try("the sub-tab Ranch (AT.switchSubmode)", S.AT.switchSubmode, w, "ranch")
    H.try("New zone (AT.startZoneCreate)", S.AT.startZoneCreate, w)
    local zc = w._zoneCreate
    Q.check(zc ~= nil and zc.active == true and ISWorldObjectContextMenu.disableWorldMenu == true, "zone: the drawing starts and holds the world menu off", tostring(zc and zc.phase))
    -- a 1 x 1: the first corner, then A again on the same square
    H.try("A (AT.gpConfirm)", S.AT.gpConfirm, w)
    H.try("A (AT.gpConfirm)", S.AT.gpConfirm, w)
    Q.check(zc ~= nil and zc.phase == "drawing", "zone: a 1 x 1 is refused (the drawing goes on)", tostring(zc and zc.phase))
    H.try("B (AT.gpCancel)", S.AT.gpCancel, w)
    Q.check(zc ~= nil and zc.phase == "idle" and zc.startX == nil and zc.active == true, "zone: B takes the first corner back", tostring(zc and zc.phase))
    H.try("B (AT.gpCancel)", S.AT.gpCancel, w)
    Q.check(zc ~= nil and zc.active == false and ISWorldObjectContextMenu.disableWorldMenu == false, "zone: B again ends the drawing and hands the world menu back", tostring(ISWorldObjectContextMenu.disableWorldMenu))
    -- the windows shut mid-drawing
    H.try("New zone (AT.startZoneCreate)", S.AT.startZoneCreate, w)
    H.try("A (AT.gpConfirm)", S.AT.gpConfirm, w)
    RT.pairShut()
end)
pause(600)
step(2, "ranch", function()
    Q.check(ISWorldObjectContextMenu.disableWorldMenu == false and S.AT._zoneDrawWin == nil, "zone: both windows shut mid-drawing: the drawing ends, the world menu is back",
        "disableWorldMenu " .. tostring(ISWorldObjectContextMenu.disableWorldMenu))
    if S.AT.endZoneDraw then pcall(S.AT.endZoneDraw) end
    ISWorldObjectContextMenu.disableWorldMenu = false
    RT.pairOpen()
end)
pause(900)
step(2, "ranch", function() H.animalsTab() end)
wait(4000, "ranch", function() local w = H.W(); return w ~= nil and w._activeTab == "animals" end, function(ok)
    local w = H.W()
    if not (ok and w) then H.off("ranch", "the Animals tab did not open again"); return end
    S.zones1 = H.zoneCount()
    H.try("New zone (AT.startZoneCreate)", S.AT.startZoneCreate, w)
    local zc = w._zoneCreate
    if not (zc and zc.active) then H.off("ranch", "the zone drawing did not start"); return end
    S.zoneName = zc.name
    S.zones[#S.zones + 1] = zc.name
    H.try("the cursor to the first corner (AT.gpMoveCursor)", S.AT.gpMoveCursor, w, S.cx - S.HALF - (zc.cursorX or S.cx), S.cy - S.HALF - (zc.cursorY or S.cy))
    H.try("A (AT.gpConfirm)", S.AT.gpConfirm, w)
    H.try("the cursor to the far corner", S.AT.gpMoveCursor, w, 2 * S.HALF + 40, 2 * S.HALF)
    H.try("A (AT.gpConfirm)", S.AT.gpConfirm, w)
    Q.check(zc.phase == "drawing", "zone: a zone 57 squares wide is refused", tostring(zc.phase))
    H.try("the cursor back", S.AT.gpMoveCursor, w, -40, 0)
    H.try("A (AT.gpConfirm)", S.AT.gpConfirm, w)
    Q.check(zc.phase == "confirm", "zone: 17 x 17 is taken and asks to confirm", tostring(zc.phase))
    H.try("A (AT.gpConfirm)", S.AT.gpConfirm, w)
end)
pause(500)
step(2, "ranch", function()
    local w, z = H.W(), H.zoneObj()
    Q.check(z ~= nil and H.zoneCount() == S.zones1 + 1, "zone: ZeD's drawing made one zone, named " .. tostring(S.zoneName), "zones " .. tostring(S.zones1) .. " -> " .. H.zoneCount())
    Q.check(z == nil or (z:getX() == S.cx - S.HALF and z:getY() == S.cy - S.HALF), "zone: its corner is where the cursor put it", z and (z:getX() .. "," .. z:getY()))
    Q.check(w._zoneCreate.active == false and ISWorldObjectContextMenu.disableWorldMenu == false, "zone: made: the drawing is over, the world menu is back", tostring(w._zoneCreate.phase))
    Q.check(S.AP.getZoneSummary(S.zoneName, S.pn) ~= nil, "zone: the Animals tab knows the new zone at once", tostring(S.zoneName))
    if not z then
        S.zoneName = "BX Farm Pen"
        S.zones[#S.zones + 1] = S.zoneName
        DesignationZoneAnimal.new(S.zoneName, S.cx - S.HALF, S.cy - S.HALF, 0, S.cx + S.HALF + 1, S.cy + S.HALF + 1, true)
        S.AP.refreshCache(S.pn)
        if not H.zoneObj() then H.off("ranch", "no animal zone could be made"); return end
    end
    RT.bounds(Q, "the Animals tab with the new zone")
    -- 2b. the animals (the cell's animals as they are now, first: what is there at the end and was not is the script's)
    for _, a in ipairs(H.cellAnimals()) do S.pre[a] = true end
    S.cow, S.ewe, S.hen = H.spawn("cow", 3, 3), H.spawn("ewe", -3, 5), H.spawn("hen", 2, -3)
    if not (S.cow and S.ewe and S.hen) then H.off("ranch", "a cow, a ewe and a hen could not all be made"); return end
    S.cow:getData():setMaxMilkActual(6)
    S.cow:getData():setMilkQuantity(1.2)
    S.ewe:getData():setWoolQuantity(5, true)
    H.asideFood(S.cow)
end)
wait(10000, "ranch", function()
    S.poll = (S.poll or 0) + 1
    if S.poll - math.floor(S.poll / 30) * 30 == 0 then S.AP.refreshCache(S.pn) end
    return H.inRoster(S.cow) and H.inRoster(S.ewe) and H.inRoster(S.hen)
end, function(ok)
    Q.check(ok, "ranch: the zone's roster holds the cow, the ewe and the hen", #H.roster() .. " on the roster, the game counts " .. H.gameZoneN())
    Q.check(#H.roster() == H.gameZoneN(), "ranch: the roster's count is the game's count for the zone", #H.roster() .. " vs " .. H.gameZoneN())
    local w = H.W()
    -- sub-tabs flipped, the zone's page, Back past the top
    for i = 1, 10 do H.try("the sub-tabs (AT.switchSubmode)", S.AT.switchSubmode, w, (i - math.floor(i / 2) * 2 == 0) and "ranch" or "butcher") end
    H.zonePage()
    for _ = 1, 3 do H.try("Back (AT.navigateBack)", S.AT.navigateBack, w) end
    local st = H.st()
    Q.check(st.submode == "ranch" and st.view == "overview" and st.zoneName == nil, "ranch: Back pressed past the top stays on the overview", tostring(st.view))
    H.zonePage()
end)
pause(800)
step(2, "ranch", function()
    local w = H.W()
    local rows = 0
    for _, rz in ipairs(w._animalsRosterZones or {}) do if S.mine[rz.animal] then rows = rows + 1 end end
    Q.check(H.st().view == "zone" and rows >= 1 and #(w._animalsBulkBtns or {}) > 0, "ranch: the zone's page draws its roster and its band", rows .. " of the script's rows in view")
    RT.bounds(Q, "the zone's page")
end)

-- 2c. the trough
step(5, "trough", function()
    if S.off.ranch then S.off.trough = true; return end
    if not (SFeedingTroughSystem and SFeedingTroughSystem.instance and FeedingTroughDef and FeedingTroughDef.simple and S.AT.openStruct and ISFeedingTroughMenu) then
        H.off("trough", "the game's trough system or the Animals tab's row code is missing"); return
    end
    S.troughSq = H.sq(-3, 2)
    if not S.troughSq or H.objOn(S.troughSq, "IsoFeedingTrough") then H.off("trough", "no free square for a trough"); return end
    SFeedingTroughSystem.instance:addTrough(S.troughSq, FeedingTroughDef.simple, false, -1, -1)
    H.put(S.cx - 1.5, S.cy + 2.5)
end)
pause(800)
step(2, "trough", function()
    S.trough = H.objOn(S.troughSq, "IsoFeedingTrough")
    if not S.trough then H.off("trough", "the trough could not be staged"); return end
    H.try("the trough's row (AT.openStruct)", S.AT.openStruct, "trough", S.trough, S.pn)
end)
wait(5000, "trough", function() return H.kind() == "trough" end, function(ok)
    if not Q.check(ok and H.d() ~= nil, "trough: its row on the Animals tab opens the trough card", tostring(H.kind())) then H.stop(); H.off("trough", "the trough card did not open"); return end
    local d = H.d()
    Q.check(not d.hasFood and not d.hasWater and H.pill() == Z.tr("Fluid_Empty"), "trough: a new trough is tagged Empty", tostring(H.pill()))
    local gz = DesignationZoneAnimal.getZone(S.troughSq:getX(), S.troughSq:getY(), 0)
    Q.check(d.zoneName == (gz and gz:getName() or nil), "trough: the zone line names the zone the game puts it in", tostring(d.zoneName) .. " vs " .. tostring(gz and gz:getName()))
    RT.bounds(Q, "the trough card")
    ISFeedingTroughMenu.onAddWaterDebug(S.p, S.trough, Fluid.Water)
    H.fresh()
end)
pause(600)
step(2, "trough", function()
    local d = H.d()
    if not d then Q.check(false, "trough: the card is still open", tostring(H.kind())); H.off("trough", "the card closed"); return end
    local tw = S.trough:getWater()
    Q.check(d.hasWater and H.near(d.water, tw, math.max(0.05, 0.01 * tw)), "trough: filled: the card reads the water in it", tostring(d.water) .. " vs " .. tostring(tw))
    local food = H.verb("food")
    Q.check(H.pill() == Z.tr("Fluid_Name_Water") and food ~= nil and food.sensible == false, "trough: water in it: tagged Water, no Add food", tostring(H.pill()))
    local ok, err = H.press("oc:verb:empty")
    Q.check(ok, "trough: Empty pressed", err)
end)
pause(400)
step(2, "trough", function()
    local c = H.card()
    Q.check(c ~= nil and c._confirm ~= nil, "trough: Empty asks first", tostring(c and c._confirm and c._confirm.text))
    local ok, err = H.press("oc:confirm:yes")
    Q.check(ok, "trough: the question's Empty runs", err)
end)
wait(10000, "trough", function() return S.trough:getWater() < 0.01 and H.idle() end, function(ok)
    Q.check(ok, "trough: Empty (the game's action) emptied it", tostring(S.trough:getWater()))
    if not ok then H.stop(); ISFeedingTroughMenu.onRemoveWaterDebug(S.p, S.trough) end
    S.feedBag = H.give("Base.AnimalFeedBag")
    H.fresh()
end)
pause(700)
step(2, "trough", function()
    local d = H.d()
    if not d then Q.check(false, "trough: the card is still open after the emptying", tostring(H.kind())); H.off("trough", "the card closed"); return end
    Q.check(not d.hasWater, "trough: emptied: the card reads no water", tostring(d.water))
    local ri = nil
    for i, g in ipairs(d.feedRows or {}) do
        for _, it in ipairs(g.items or {}) do if it == S.feedBag then ri = i end end
    end
    if not ri then Q.skip("feed added by its row", "the feed bag given is not on the card's list (the trough takes none of it)"); S.fed = false; return end
    S.fed = true
    local ok, err = H.press("trough:feed:" .. ri)
    Q.check(ok, "trough: the feed row's Add runs", err)
end)
wait(8000, "trough", function()
    if not S.fed then return true end
    local c = S.trough:getContainer()
    return c ~= nil and c:getItems():size() > 0 and H.idle()
end, function(ok)
    if S.fed then
        Q.check(ok, "trough: Add (the game's transfer) put the feed in", "queue " .. H.qn())
        if not ok then H.stop() end
    end
    H.fresh()
end)
pause(600)
step(2, "trough", function()
    local d = H.d()
    local c = S.trough:getContainer()
    local has = c ~= nil and c:getItems():size() > 0
    Q.check(d ~= nil and (d.hasFood == true) == has, "trough: the card says feed is in it exactly when the game holds some", tostring(d and d.hasFood) .. " vs " .. tostring(has))
    -- the trough taken away under the card
    H.takeTrough()
end)
function H.takeTrough()
    if not S.troughSq then return end
    local lo = SFeedingTroughSystem.instance:getLuaObjectOnSquare(S.troughSq)
    if lo then lo:removeIsoObject() end
    local iso = H.objOn(S.troughSq, "IsoFeedingTrough")
    if iso then S.troughSq:transmitRemoveItemFromSquare(iso) end
end
pause(1300)
step(2, "trough", function()
    Q.check(H.objOn(S.troughSq, "IsoFeedingTrough") == nil, "trough: taken away", "still there")
    Q.check(H.card() == nil, "trough: taken away under the card: the card closes", tostring(H.kind()))
    H.close()
    H.try("the poller's refresh with the trough gone (AP.refreshCache)", S.AP.refreshCache, S.pn)
end)

-- 2d. the cow: Info, pet, milk, feed
step(5, "ranch", function()
    H.stop(); H.close()
    H.beside(S.cow)
    if not (AnimalContextMenu and AnimalContextMenu._zedInfoHooked) then Q.skip("the cow's Info", "ZeD's hook on AnimalContextMenu.onAnimalInfo is missing"); S.noInfo = true; return end
    H.try("the cow's Info (AnimalContextMenu.onAnimalInfo)", AnimalContextMenu.onAnimalInfo, S.cow, S.p)
end)
pause(700)
step(2, "ranch", function()
    local w, st = H.W(), H.st()
    if not S.noInfo then
        local stray = H.stray("ISAnimalUI")
        Q.check(not stray and w._activeTab == "animals" and st.view == "animal" and st.animalRef == S.cow, "cow: the game's Info shows the cow in the Animals tab", tostring(st.view) .. (stray and ", the game's window opened" or ""))
        RT.bounds(Q, "the cow's view")
    else
        H.try("the cow's view (AT.showAnimal)", S.AT.showAnimal, w, S.cow)
    end
    H.instant(true)
    AnimalContextMenu.onPetAnimal(S.cow, S.p)
end)
wait(8000, "ranch", function() return H.idle() end, function(ok)
    if not ok then H.stop() end
    local st = H.st()
    Q.check(st.view == "animal" and st.animalRef == S.cow, "cow: petted with its view up: the view stays on the cow", tostring(st.view) .. ", petting done " .. tostring(ok))
    -- Milk pressed twice, stopped twice
    H.instant(false)
    S.bucket = H.give("Base.Bucket")
    S.AQ.forgetChecks()
    local can, why = S.AQ.can("milk", S.p, S.cow)
    S.canMilk = can == true
    if not S.canMilk then Q.skip("the milking", "the game does not offer Milk for the cow (" .. tostring(why) .. ")"); return end
    local w = H.W()
    local _, r1 = H.try("Milk (AT.alertAct)", S.AT.alertAct, w, S.cow, "milk")
    local _, r2 = H.try("Milk again (AT.alertAct)", S.AT.alertAct, w, S.cow, "milk")
    Q.check(r1 == true and r2 == true and S.AQ.run ~= nil, "cow: Milk pressed twice starts one run", tostring(r1) .. " " .. tostring(r2))
    H.try("Stop (AQ.stop)", S.AQ.stop)
    H.try("Stop again (AQ.stop)", S.AQ.stop)
    Q.check(S.AQ.run == nil and H.qn() == 0, "cow: Stop pressed twice ends the run and leaves nothing queued", "queue " .. H.qn())
end)
pause(400)
step(2, "ranch", function()
    if not S.canMilk then return end
    S.milk0 = S.cow:getData():getMilkQuantity()
    S.AQ.forgetChecks()
    local _, r = H.try("Milk (AT.alertAct)", S.AT.alertAct, H.W(), S.cow, "milk")
    Q.check(r == true and S.AQ.run ~= nil, "cow: Milk starts a run", tostring(S.AQ.runStatus()))
end)
wait(35000, "ranch", function()
    if not S.canMilk then return true end
    H.ff(true)
    return S.AQ.run == nil and H.idle()
end, function(ok)
    H.ff(false)
    if not S.canMilk then return end
    local l = S.AQ.last
    local m1 = S.cow:getData():getMilkQuantity()
    Q.check(ok and l ~= nil and l.cause == "done", "cow: the milking run ended on its own, done", "ended " .. tostring(ok) .. ", cause " .. tostring(l and l.cause) .. ", " .. tostring(l and l.why))
    Q.check(m1 < S.milk0, "cow: the cow gave milk", tostring(S.milk0) .. " -> " .. tostring(m1))
    if not ok then H.try("Stop (AQ.stop)", S.AQ.stop); H.stop() end
end)
-- Feed: greyed, the carrot gone before the pick, then fed
step(5, "ranch", function()
    H.beside(S.cow)
    S.cow:getStats():set(CharacterStat.HUNGER, 0.9)
    S.AQ.forgetChecks()
    H.zonePage()
    H.try("the cow's tick (AT.toggleSelected)", S.AT.toggleSelected, H.W(), S.cow)
end)
pause(1000)
step(2, "ranch", function()
    local f = H.bulk("feed")
    Q.check(f ~= nil and f.disabled, "feed: the hungry cow ticked: Feed is in the band, greyed with nothing to eat carried", tostring(f and f.disabled))
    S.carrot = H.give("Base.Carrots")
    S.AQ.forgetChecks()
end)
pause(1000)
step(2, "ranch", function()
    local f = H.bulk("feed")
    S.canFeed = f ~= nil and not f.disabled
    if not Q.check(S.canFeed, "feed: with a carrot carried, Feed is live", tostring(f and f.disabled)) then return end
    H.try("Feed (AT.bulkPress)", S.AT.bulkPress, H.W(), "feed")
    local m = S.AT._feedMenu
    local rows = m and m._ctx and m._ctx.actions or {}
    Q.check(m ~= nil and m._ctx.open and #rows >= 1, "feed: the food picker opens", #rows .. " rows")
    RT.bounds(Q, "the food picker")
    -- the carrot gone while the picker shows it
    H.drop(S.carrot)
    if m then H.try("the picker's pick (confirm)", m.confirm, m) end
end)
pause(500)
step(2, "ranch", function()
    if not S.canFeed then return end
    local m = S.AT._feedMenu
    Q.check(S.AQ.run == nil and H.qn() == 0, "feed: the food gone before the pick: nothing starts, nothing queued", tostring(S.AQ.runStatus()))
    if m and m._ctx and m._ctx.open then H.try("the picker's close", m.close, m) end
    S.carrot = H.give("Base.Carrots")
    S.AQ.forgetChecks()
    if not S.AQ.isSelected(S.AT.getZoneViewState(H.W()).sel, S.cow) then H.try("the cow's tick (AT.toggleSelected)", S.AT.toggleSelected, H.W(), S.cow) end
end)
pause(1000)
step(2, "ranch", function()
    if not S.canFeed then return end
    S.hunger0 = S.cow:getStats():get(CharacterStat.HUNGER)
    local _, opened = H.try("Feed (AT.bulkPress)", S.AT.bulkPress, H.W(), "feed")
    local m = S.AT._feedMenu
    if not (opened and m) then Q.check(false, "feed: the picker opens again", tostring(opened)); S.canFeed = false; return end
    H.try("the picker's pick (confirm)", m.confirm, m)
    Q.check(S.AQ.run ~= nil and S.AQ.run.verb == "feed", "feed: picking the carrot starts a feeding run", tostring(S.AQ.runStatus()))
end)
wait(35000, "ranch", function()
    if not S.canFeed then return true end
    H.ff(true)
    return S.AQ.run == nil and H.idle()
end, function(ok)
    H.ff(false)
    if not S.canFeed then return end
    local l = S.AQ.last
    local h1 = S.cow:getStats():get(CharacterStat.HUNGER)
    Q.check(ok and l ~= nil and l.cause == "done", "feed: the feeding run ended on its own, done", "ended " .. tostring(ok) .. ", cause " .. tostring(l and l.cause) .. ", " .. tostring(l and l.why))
    Q.check(h1 < S.hunger0, "feed: the cow ate", tostring(S.hunger0) .. " -> " .. tostring(h1))
    if not ok then H.try("Stop (AQ.stop)", S.AQ.stop); H.stop() end
end)

-- 2e. the hen: picked up with its view open, put down again
step(5, "ranch", function()
    H.stop()
    H.instant(true)
    H.beside(S.hen)
    H.try("the hen's view (AT.showAnimal)", S.AT.showAnimal, H.W(), S.hen)
    AnimalContextMenu.onPickupAnimal(S.hen, S.p)
end)
wait(8000, "ranch", function() return H.heldAnimal() ~= nil and H.idle() end, function(ok)
    S.henItem = H.heldAnimal()
    if not ok or not S.henItem then H.stop(); Q.skip("the hen picked up and put down", "the game's pick-up did not put the hen in the hands in 8 s"); return end
    H.try("the poller's refresh with the hen in the hands (AP.refreshCache)", S.AP.refreshCache, S.pn)
    Q.check(H.inRoster(S.hen) == H.gameHas(S.hen), "hen: in the hands: the roster agrees with the game on whether she is in the zone", tostring(H.inRoster(S.hen)) .. " vs " .. tostring(H.gameHas(S.hen)))
    Q.check(#H.roster() == H.gameZoneN(), "hen: in the hands: the roster's count is the game's", #H.roster() .. " vs " .. H.gameZoneN())
end)
pause(700)
step(2, "ranch", function()
    if not S.henItem then return end
    RT.bounds(Q, "the hen's view with the hen in the hands")
    ISInventoryPaneContextMenu.onDropItems({ S.henItem }, S.pn)
end)
wait(8000, "ranch", function() return S.henItem == nil or (not S.p:getInventory():contains(S.henItem) and H.idle()) end, function(ok)
    if not S.henItem then return end
    if not ok then
        H.stop()
        Q.skip("the hen put down", "the game's drop did not put her down in 8 s: she is taken out of the hands")
        H.drop(S.henItem)
        S.gone[S.hen] = true
        return
    end
    -- the hen that came back: the game makes her again, so she is looked for among the animals that are new
    local back = 0
    for _, a in ipairs(H.cellAnimals()) do
        if not S.pre[a] and not S.gone[a] and (a == S.hen or not S.mine[a]) and a:getAnimalType() == "hen" then
            back = back + 1
            if not S.mine[a] then H.mark(a); S.mine[a] = true; S.animals[#S.animals + 1] = a; S.hen2 = a end
        end
    end
    Q.check(back == 1, "hen: put down: one hen is back in the world", back .. " found")
    H.try("the poller's refresh with the hen back (AP.refreshCache)", S.AP.refreshCache, S.pn)
end)
pause(800)
step(2, "ranch", function()
    if not S.henItem then return end
    S.AP.refreshCache(S.pn)
    Q.check(#H.roster() == H.gameZoneN(), "hen: put down: the roster's count is the game's", #H.roster() .. " vs " .. H.gameZoneN())
end)

-- 2f. the ewe gone while its view is open
step(5, "ranch", function()
    local w = H.W()
    H.centre()
    H.zonePage()
    S.AP.refreshCache(S.pn)
    H.try("the ewe's tick (AT.toggleSelected)", S.AT.toggleSelected, w, S.ewe)
    H.try("the ewe's view (AT.showAnimal)", S.AT.showAnimal, w, S.ewe)
end)
pause(700)
step(2, "ranch", function()
    local st = H.st()
    Q.check(st.view == "animal" and st.animalRef == S.ewe and H.inRoster(S.ewe), "gone: the ewe's view is open and she is on the roster", tostring(st.view))
    RT.bounds(Q, "the ewe's view")
    H.takeAway(S.ewe)
end)
wait(15000, "ranch", function() return not H.inRoster(S.ewe) end, function(ok)
    Q.check(ok, "gone: the roster drops an animal taken out of the world by itself (within 15 s)", "still on the roster: " .. tostring(H.inRoster(S.ewe)))
    local st = H.st()
    Q.check(not (st.view == "animal" and st.animalRef == S.ewe), "gone: the Animals tab lets go of the view of an animal that is gone", "view " .. tostring(st.view) .. ", still the ewe")
    S.AQ.forgetChecks()
    local okC, can = H.try("Milk asked of an animal that is gone (AQ.can)", S.AQ.can, "milk", S.p, S.ewe)
    Q.check(okC and can ~= true, "gone: Milk on an animal that is gone is refused", tostring(can))
    local okG, went = H.try("Walk to an animal that is gone (AT.alertAct)", S.AT.alertAct, H.W(), S.ewe, "goto")
    if okG and went == true then Q.say("Walk to on the gone ewe was taken (the walk goes where she stood)") end
    H.stop()
    S.AP.refreshCache(S.pn)
    H.zonePage()
end)
pause(900)
step(2, "ranch", function()
    local w = H.W()
    local sel = S.AT.getZoneViewState(w).sel
    Q.check(H.rosterRow(S.ewe) == nil, "gone: the zone's page draws no row for her", "a row is drawn")
    Q.check(not S.AQ.isSelected(sel, S.ewe), "gone: her tick is gone with her", "still ticked")
    RT.bounds(Q, "the zone's page with the ewe gone")
end)

-- 2g. the hen house
step(5, "hutch", function()
    if S.off.ranch then S.off.hutch = true; return end
    local def = HutchDefinitions and HutchDefinitions.hutchs and HutchDefinitions.hutchs.hutchhen
    if not (def and IsoHutch and ISHutchMenu and ISHutchMenu._zedCardHooked) then H.off("hutch", "the game's hen house or ZeD's hook on its Info is missing"); return end
    S.hutchSq = H.sq(-5, -4)
    for _, o in ipairs({ { 0, 0 }, { 1, 0 }, { 0, -1 }, { 1, -1 }, { 0, 1 } }) do
        local sq = H.sq(-5 + o[1], -4 + o[2])
        if not sq or not sq:isFree(false) or sq:getMovingObjects():size() > 0 then H.off("hutch", "no free ground for a hen house"); return end
    end
    local h = IsoHutch.new(S.hutchSq, true, def.baseSprite, def, nil)
    h:transmitCompleteItemToClients()
end)
pause(800)
step(2, "hutch", function()
    local h = H.objOn(S.hutchSq, "IsoHutch")
    h = h and (h:getHutch() or h)
    if not h then H.off("hutch", "the hen house could not be staged"); return end
    S.hutch = h
    if h:isOpen() then h:toggleDoor() end
    local def = AnimalDefinitions.getDef("hen")
    local a = addAnimal(getCell(), 0, 0, 0, "hen", def:getBreeds():get(0))
    if a then
        H.mark(a); S.mine[a] = true; S.animals[#S.animals + 1] = a; S.hutchHen = a
        a:getData():setPreferredHutchPosition(0)
        h:addAnimalInside(a)
    end
    local entry = h:getEntrySq() or S.hutchSq
    H.put(entry:getX() + 0.5, entry:getY() + 0.5)
    H.try("the hen house's Info (ISHutchMenu.onInfo)", ISHutchMenu.onInfo, h, S.p)
end)
wait(8000, "hutch", function() return H.kind() == "hutch" end, function(ok)
    if not Q.check(ok and H.d() ~= nil, "hutch: the hen house's Info opens the hutch card", tostring(H.kind())) then
        H.stop(); H.stray("ISHutchUI"); H.off("hutch", "the hutch card did not open"); return
    end
    local d = H.d()
    local n = S.hutch:getAnimalInside():size()
    Q.check(d.count == n and n >= 1, "hutch: the card counts the hen inside", tostring(d.count) .. " vs " .. n)
    Q.check(d.allClosed == (S.hutch:isAllDoorClosed() == true), "hutch: the card reads the doors as the game has them", tostring(d.allClosed))
    RT.bounds(Q, "the hutch card")
    -- the hen taken out under the card
    H.takeAway(S.hutchHen)
    H.fresh()
end)
pause(700)
step(2, "hutch", function()
    local d = H.d()
    local n = S.hutch:getAnimalInside():size()
    Q.check(d ~= nil and d.count == n, "hutch: the hen taken out under the card: the count follows", tostring(d and d.count) .. " vs " .. n)
    H.takeHutch()
end)
function H.takeHutch()
    local h = S.hutch
    if not h then return end
    for k = 0, h:getMaxAnimals() - 1 do
        local a = h:getAnimal(k)
        if a then h:removeAnimal(a); S.gone[a] = true end
    end
    for b = 0, h:getMaxNestBox() do
        local nb = h:getNestBox(b)
        for _ = 1, 12 do
            if not nb or nb:getEggsNb() <= 0 then break end
            nb:removeEgg(0)
        end
    end
    h:removeHutch()
    S.hutch = nil
end
pause(1300)
step(2, "hutch", function()
    Q.check(H.objOn(S.hutchSq, "IsoHutch") == nil, "hutch: taken away", "still there")
    Q.check(H.card() == nil, "hutch: taken away under the card: the card closes", tostring(H.kind()))
    H.close()
    H.try("the poller's refresh with the hen house gone (AP.refreshCache)", S.AP.refreshCache, S.pn)
end)

-- 2h. the zone removed through its own page, animals still in it
step(5, "ranch", function()
    H.stop(); H.close(); H.centre()
    H.animalsTab()
    H.zonePage()
end)
pause(700)
step(2, "ranch", function()
    local w = H.W()
    local _, r = H.try("Remove zone (AT.zoneAct)", S.AT.zoneAct, w, "remove")
    Q.check(r == true and w._animalsRemoveConfirm == true, "remove: Remove zone asks first", tostring(w._animalsRemoveConfirm))
end)
pause(400)
step(2, "ranch", function()
    local w = H.W()
    RT.bounds(Q, "the zone's remove question")
    H.try("the question's Cancel (AT.zoneAct)", S.AT.zoneAct, w, "no")
    Q.check(not w._animalsRemoveConfirm and H.zoneObj() ~= nil, "remove: Cancel keeps the zone", tostring(H.zoneObj() ~= nil))
    H.try("Remove zone (AT.zoneAct)", S.AT.zoneAct, w, "remove")
    H.try("the question's Remove (AT.zoneAct)", S.AT.zoneAct, w, "yes")
end)
pause(700)
step(2, "ranch", function()
    local st = H.st()
    Q.check(H.zoneObj() == nil and S.AP.getZoneSummary(S.zoneName, S.pn) == nil, "remove: Remove takes the zone away, on the Animals tab too", tostring(H.zoneObj() ~= nil))
    Q.check(st.view == "overview" and st.zoneName == nil, "remove: the page steps back to the overview", tostring(st.view))
    RT.bounds(Q, "the overview with the zone gone and its animals still there")
end)

-- ===================================================================== 3. PUT BACK
function H.backWorld()
    local n = { hutch = 0, trough = 0, plots = 0, animals = 0, zones = 0, swept = 0 }
    if S.hutch then if pcall(H.takeHutch) then n.hutch = 1 end end
    if S.troughSq and H.objOn(S.troughSq, "IsoFeedingTrough") then if pcall(H.takeTrough) then n.trough = 1 end end
    for i, sq in ipairs(S.plots) do
        if H.unplant(sq) then n.plots = n.plots + 1 end
        sq:getModData().plowDay = S.plowDay[i]
    end
    n.animals = H.backAnimals()
    for _, name in ipairs(S.zones) do
        for _ = 1, 3 do
            local z = DesignationZoneAnimal.getZoneByName(name)
            if z then DesignationZoneAnimal.removeZone(z, true); n.zones = n.zones + 1 end
        end
    end
    H.eachStaged(function(sq)
        local wos = sq:getWorldObjects()
        for k = wos:size() - 1, 0, -1 do
            local wo = wos:get(k)
            if not S.woPre[wo] then
                sq:transmitRemoveItemFromSquare(wo)
                wo:removeFromWorld(); wo:removeFromSquare()
                n.swept = n.swept + 1
            end
        end
    end)
    return n
end
-- the script's animals, and a hen that is new since the animals were made, stands on the staged ground and is in no
-- zone but the script's (the hen the game made again when she was put down, should her mark not have come with her)
function H.backAnimals()
    local n = 0
    for _, a in ipairs(S.animals) do if H.takeAway(a) then n = n + 1 end end
    if not S.cx then return n end
    for _, a in ipairs(H.cellAnimals()) do
        local md = a:getModData()
        local mineNow = S.mine[a] or (md ~= nil and md.ZeDQA_spawned == true)
        if not mineNow and S.cow and not S.pre[a] and a:getAnimalType() == "hen" and not a:isWild()
                and math.abs(a:getX() - S.cx) <= S.HALF + 6 and math.abs(a:getY() - S.cy) <= S.HALF + 6 then
            local dz = a:getDZone()
            local zn = dz and dz:getName()
            mineNow = zn == nil or zn == S.zoneName
        end
        if mineNow and not S.gone[a] then
            S.gone[a] = true
            a:removeFromWorld(); a:removeFromSquare()
            n = n + 1
        end
    end
    return n
end
function H.backItems()
    local p = S.p
    local swept, back = 0, 0
    local held = H.heldAnimal()
    if held then p:setPrimaryHandItem(nil); p:setSecondaryHandItem(nil) end
    local all = p:getInventory():getAllEvalRecurse(function(it) return true end)
    for k = all:size() - 1, 0, -1 do
        local it = all:get(k)
        if not S.had[it] then
            local c = it:getContainer()
            if c then p:removeFromHands(it); c:Remove(it); swept = swept + 1 end
        end
    end
    for _, t in ipairs(S.taken) do
        if not t.item:getContainer() then t.cont:AddItem(t.item); back = back + 1 end
    end
    if p:getPrimaryHandItem() ~= S.primary then p:setPrimaryHandItem(S.primary) end
    if p:getSecondaryHandItem() ~= S.secondary then p:setSecondaryHandItem(S.secondary) end
    return swept, back
end
function H.backBody()
    local p = S.p
    p:setTimedActionInstantCheat(S.instant == true)
    p:getBodyDamage():RestoreToFullHealth()
    local parts = p:getBodyDamage():getBodyParts()
    for k = 0, parts:size() - 1 do if S.stiff[k] then parts:get(k):setStiffness(S.stiff[k]) end end
    p:setSeeDesignationZone(false)
    p:setGodMod(S.god == true)
end
function H.backWindows()
    local w = H.W()
    local m = S.AT._feedMenu
    if m and m._ctx and m._ctx.open then pcall(m.close, m) end
    if S.AT.endZoneDraw then pcall(S.AT.endZoneDraw) end
    ISWorldObjectContextMenu.disableWorldMenu = false
    H.close()
    for _, typ in ipairs({ "ISAnimalUI", "ISFarmingInfo", "ISFeedingTroughUI", "ISHutchUI" }) do H.stray(typ) end
    getCell():setDrag(nil, S.pn)
    if w and S.at0 then
        w._animalsRemoveConfirm, w._animalsRenaming = false, false
        if w._animalsZoneState then w._animalsZoneState.sel = nil end
        local st = S.AT.getState(w)
        st.submode, st.view, st.zoneName, st.animalRef, st.prevView = S.at0.submode, S.at0.view, S.at0.zoneName, S.at0.animalRef, S.at0.prevView
    end
    if w and S.tab0 and w._activeTab ~= S.tab0 then pcall(S.WWm.openTab, S.pn, S.tab0) end
end
-- what the script staged and is still there
function H.leftovers()
    local left = {}
    if S.hutchSq and H.objOn(S.hutchSq, "IsoHutch") then left[#left + 1] = "the hen house" end
    if S.troughSq and H.objOn(S.troughSq, "IsoFeedingTrough") then left[#left + 1] = "the trough" end
    for i, sq in ipairs(S.plots) do if H.plantS(sq) or H.plantC(sq) then left[#left + 1] = "plot " .. i end end
    for _, a in ipairs(H.cellAnimals()) do
        local md = a:getModData()
        if S.mine[a] or (md ~= nil and md.ZeDQA_spawned == true) then left[#left + 1] = "a " .. tostring(a:getAnimalType()) end
    end
    for _, name in ipairs(S.zones) do if DesignationZoneAnimal.getZoneByName(name) then left[#left + 1] = "the zone " .. name end end
    if H.zoneCount() ~= S.zones0 then left[#left + 1] = "animal zones " .. tostring(S.zones0) .. " -> " .. H.zoneCount() end
    local all = S.p:getInventory():getAllEvalRecurse(function(it) return true end)
    for k = 0, all:size() - 1 do
        if not S.had[all:get(k)] then left[#left + 1] = "carried " .. tostring(all:get(k):getFullType()) end
    end
    for _, t in ipairs(S.taken) do
        if not t.item:getContainer() then left[#left + 1] = "not given back " .. tostring(t.item:getFullType()) end
    end
    return left
end

Q.mark()
Q.step(5, function()
    if not S.staged then return end
    H.ff(false)
    if S.AQ and S.AQ.stop then pcall(S.AQ.stop) end
    H.stop()
    local okW, e1 = pcall(H.backWindows)
    if not okW then Q.check(false, "put back: the windows", e1) end
end)
Q.step(10, function()
    if not S.staged then return end
    local okN, n = pcall(H.backWorld)
    if not okN then Q.check(false, "put back: the world", n); n = {} end
    local okI, swept, back = pcall(H.backItems)
    if not okI then Q.check(false, "put back: the character's things", swept) end
    local okB, e3 = pcall(H.backBody)
    if not okB then Q.check(false, "put back: the character's body and cheats", e3) end
    Q.say("put back: hen house " .. tostring(n.hutch) .. ", trough " .. tostring(n.trough) .. ", plots " .. tostring(n.plots) .. ", animals "
        .. tostring(n.animals) .. ", zones " .. tostring(n.zones) .. ", things lying on the staged ground " .. tostring(n.swept)
        .. "; new things taken off the character " .. tostring(swept) .. ", set aside and given back " .. tostring(back) .. " of " .. #S.taken)
end)
Q.waitMs(700)
Q.step(2, function()
    if not S.staged then return end
    local okL, left = pcall(H.leftovers)
    Q.check(okL and #left == 0, "put back: nothing staged is left at the farm or on the character", okL and table.concat(left, ", ") or tostring(left))
    Q.check(H.idle() and getGameSpeed() == 1 and S.AQ.run == nil, "put back: nothing queued, game speed 1, no run", "queue " .. H.qn() .. ", speed " .. tostring(getGameSpeed()))
    Q.check(ISWorldObjectContextMenu.disableWorldMenu ~= true, "put back: the world menu is on", tostring(ISWorldObjectContextMenu.disableWorldMenu))
    -- the windows' roll-up timers run again, the character home
    S.holdOn = false
    Events.OnTick.Remove(H.keepTick)
    for _, w in ipairs({ RT.ww() or false, RT.cw() or false }) do if w then w._outSince = nil end end
    if S.opened then RT.pairShut() end
    H.put(S.home.x, S.home.y)
    if ZEDQA_HOME then pcall(ZEDQA_HOME, Q.tag) end
end)
Q.waitMs(1500)
Q.step(2, function()
    if not S.staged then return end
    local p = S.p
    Q.check(math.abs(p:getX() - S.home.x) <= 3 and math.abs(p:getY() - S.home.y) <= 3, "put back: the character is home on the drag strip",
        math.floor(p:getX()) .. "," .. math.floor(p:getY()))
    Q.check(p:isGodMod() == S.god and p:isTimedActionInstantCheat() == S.instant, "put back: god mode and the instant-action cheat as found",
        tostring(p:isGodMod()) .. " " .. tostring(p:isTimedActionInstantCheat()))
    RT.bounds(Q, "the end")
end)
Q.start()
