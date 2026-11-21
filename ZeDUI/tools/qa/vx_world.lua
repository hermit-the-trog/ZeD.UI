-- ZeDUI/tools/qa/vx_world.lua  (Nov 21 2026, QA): the in-game proof of Build's fixes for the beast code sweep's
-- W28 W29 W30 W31 W32 W33 W34 (ZeDUI/qa/audits/2026-11-21_beast_code_sweep.md; the fixes: 27545ddeb and a4fc05567).
-- Built on rt_kit.lua (run it first, after zedqa_prelude.lua); grep "ZEDQA vx_wld". No pictures. About two minutes.
--
-- WHERE: the farm point (1635,14221, as zedqa_farm_spot.lua and bx_farm.lua): the nearest centre with an open 17 x 17
-- is found the same way and everything is staged inside it: two small animal zones (A west, B east, made with the
-- game's own zone maker, no fence), a cow in A, a hen in no zone, a hen house, a campfire (never lit).
--
-- WHAT EACH CHECK WOULD HAVE SHOWN ON THE OLD CODE
--   W29  a zone's page lights its zone on the ground. Left by the Butcher sub-tab, by the Loot tab of the World
--        window, or by closing the windows, the old code left the zones painted (isSeeDesignationZone stayed true).
--        One more way out is checked, the one the finding names and the fix does not cover: an animal that is in no
--        zone opened from the lit page (AT.showAnimal, what a hen house card's Info does).
--   W30  Rename open on zone A, then the Butcher sub-tab: the old code kept the box up over the Butcher page; zone B
--        opened next came up already in rename mode with A's name, and Save renamed B. Remove asked on A, then an
--        animal's row or zone B: the old code still asked "Remove the zone?" on the next page. Also checked: the
--        box after the World window's Loot tab is pressed mid-rename (the fix does not end the edit there).
--   W32  Save with a name another zone holds: the old code renamed, two zones shared a name and the tab lost one.
--        Reset: the old code offered "zone <place in the list + 1>", here a name zone A already holds.
--   W28  Create zone, then the Loot tab: the old code kept the world's right-click menu switched off and the zones
--        painted for as long as the window stayed on another tab. A press on the World window's title bar while
--        the drawing waits for its first corner: the old code took it as a corner under the window.
--   W31  an animal's page with stress above 10: the old code worked the stress line out on every drawn frame (about
--        180 times in 3 s at 60 frames) and each time looked up 961 squares one by one. Counted here: the workings
--        over 3 s of the page, and the squares one working asks the game for.
--   W33  Grab eggs with eggs in three boxes, stopped during the walk: the old code started a grab of the next box by
--        itself within a quarter second, from where the character stood, and still held the third box for later.
--        Then (two boxes) a grab let run, the character moved 4 tiles off while the first box is emptied: the old
--        code took the second box from there, with no walk.
--   W34  a campfire's card open for 6 s with the character still: the old code scanned every item in reach on
--        every refresh (about 24 scans); the fix promises one every 1.5 s. And each fuel's burn time: the old code
--        worked it out inside the sort, several times per fuel on every refresh.
-- Lines named "guard" (and "control", "stage") prove no fix: they pass on the old code too and are there to catch a
-- fix that breaks something (a free name refused, a stale fire card, a zombie miscounted, a press on open ground that
-- no longer starts a corner). Guards that cannot fail on any build print only when they fail.
--
-- EXPECTED ON TODAY'S BUILD (27545ddeb, a4fc05567): VERDICT FAIL 2, from the two ways out the fix does not cover:
--   W29 (d) AT.showAnimal from a lit zone page onto an animal in no zone: showAnimal sets the view itself before it
--           calls navigate, so navigate's unlight test never fires and zone A stays painted behind the animal's page.
--   W30     the Loot tab pressed mid-rename: the tick watcher ends a drawing and the highlight but never the edit, and
--           the box (a child of the window) is hidden only by the zone page's own render: it stays up with the focus.
-- Every other W28-W34 line is expected to PASS.
--
-- THE CHARACTER: god mode and invincible go on in the first step, before anything is staged, and a tick keeps them on
-- until the last step (as bx_farm.lua). The zombie is made only while both read on. The egg grabs give no Husbandry
-- XP: the game's addXp is swapped for a no-op while the hen house scene runs, and given back after it.
-- PUT BACK (from Q.mark, also when the time runs out or a step throws): the swapped functions (the pointer, the
-- counters, addXp) are given back first; the game's actions stopped, speed 1; a zone drawing ended, the world menu
-- on, the zone page's highlight off, the rename box and the remove question shut, the card shut; the zombie, the hen
-- house (eggs out first), the campfire, the animals and both zones taken away, anything new lying on the staged
-- ground swept; everything new on the character taken off (eggs, fuel), his hands as found; the Animals tab's view,
-- the World window's tab, both windows as found; the character home on the drag strip; healed, then checked (alive,
-- health 100, no wound, no fracture, not infected), and only then god mode, invincible and the instant-action cheat as
-- found. Not home or not whole: god mode and invincible are LEFT ON and the line says so.
-- No file is written.

if not RT then
    print("ZEDQA vx_wld ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA vx_wld VERDICT FAIL 1")
    print("ZEDQA vx_wld DONE")
    return
end

local Q = RT.make("vx_wld")
Q.maxMs = 290000   -- (under five minutes, then the queue jumps to the put-back)
local Z = ZeD or {}
local S = { off = {}, animals = {}, mine = {}, gone = {}, zones = {}, had = {}, stiff = {}, woPre = {}, swaps = {}, fake = {} }
local H = {}
S.p, S.pn = RT.p, RT.pn
S.FARM = { x = 1635, y = 14221 }
S.HALF, S.SEARCH = 8, 24
S.OC, S.AT, S.AP, S.SI = Z.ObjectCards, Z.AnimalsTab, Z.AnimalsAlertPoller, Z.AnimalsStressInference
S.WWm, S.CWm = ZeD_WorldWindow, ZeD_CharacterWindow
S.BLOCK = { "wall", "fenc", "door", "window", "gate", "roof", "location_", "fixtures_", "furniture_", "appliances_" }

-- ===================================================================== the queue's wrappers
-- a step of a scene: skipped when the run cannot go on (S.dead) or its scene could not be staged (S.off[sec])
local function step(n, sec, fn)
    Q.step(n, function()
        if S.dead or (sec and S.off[sec]) then return end
        fn()
    end)
end
-- wait up to ms of real time for cond(), then fn(ok); cond runs once every drawn frame
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
local function never() return false end

-- ===================================================================== helpers
function H.off(sec, why) S.off[sec] = true; Q.skip("the " .. sec .. " scene", why) end
-- ZeD code under test: a caught error is a FAIL line and the script goes on
function H.try(what, fn, a, b, c, d)
    if type(fn) ~= "function" then Q.check(false, what .. ": the function is there", type(fn)); return false, nil end
    local ok, r1, r2 = pcall(fn, a, b, c, d)
    if not ok then Q.check(false, what .. ": ran without an error", r1); return false, nil end
    return true, r1, r2
end
-- a function swapped for the run: its way back is kept, and every one is given back at the put-back
function H.unswap(key)
    local back = S.swaps[key]
    S.swaps[key] = nil
    if back then pcall(back) end
end
function H.unswapAll()
    for _, key in ipairs({ "mouse", "cell", "si", "scan", "dur", "refresh", "xp" }) do H.unswap(key) end
end
-- the egg grabs give the character no Husbandry XP while the hen house scene runs (the game's addXp, a global the
-- grab looks up each time, answers nothing); given back right after the scene and in the put-back
function H.noXp()
    if S.swaps.xp or addXp == nil then return end
    local real = addXp
    addXp = function() end
    S.swaps.xp = function() addXp = real end
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
function H.zoneOf(fid)
    local c = H.card()
    for _, z in ipairs(c and c._zones or {}) do if z.fid == fid then return z end end
    return nil
end
-- a card zone's action, as the mouse's release over it and the pad's A run it: ok, error words
function H.press(fid)
    local c, z = H.card(), H.zoneOf(fid)
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
function H.fresh() local t = H.t(); if t and S.OC then t._refreshT = S.OC.REFRESH end end
function H.close() if H.card() and S.WWm.closeObjectCard then pcall(S.WWm.closeObjectCard, S.pn) end end
function H.queue()
    local q = ISTimedActionQueue.queues and ISTimedActionQueue.queues[S.p]
    return q and q.queue or nil
end
function H.qn() local q = H.queue(); return q and #q or 0 end
function H.qTypes()
    local out = {}
    for _, a in ipairs(H.queue() or {}) do out[#out + 1] = tostring(a.Type) end
    return table.concat(out, ",")
end
function H.idle() return not ISTimedActionQueue.isPlayerDoingAction(S.p) and H.qn() == 0 end
function H.stop() pcall(function() ISTimedActionQueue.clear(S.p) end) end
function H.put(x, y)
    local p = S.p
    p:setX(x); p:setY(y); p:setZ(0); p:setLastX(x); p:setLastY(y); p:setLastZ(0)
end
function H.putOn(sq) if sq then H.put(sq:getX() + 0.5, sq:getY() + 0.5) end end
function H.centre() if S.cx then H.put(S.cx + 0.5, S.cy + 0.5) end end
function H.sq(dx, dy) return getCell():getGridSquare(S.cx + dx, S.cy + dy, 0) end
function H.mark(o) if o then o:getModData().ZeDQA_spawned = true end end
function H.objOn(sq, cls)
    if not sq then return nil end
    local objs = sq:getObjects()
    for k = 0, objs:size() - 1 do
        local o = objs:get(k)
        if instanceof(o, cls) then return o end
    end
    return nil
end
function H.openSq(sq)
    return sq ~= nil and sq:isFree(false) and not sq:HasTree() and sq:getMovingObjects():size() == 0
end
-- how far the character stands from a square's middle (the longer of the two sides)
function H.distTo(sq)
    return math.max(math.abs(S.p:getX() - (sq:getX() + 0.5)), math.abs(S.p:getY() - (sq:getY() + 0.5)))
end

-- ---- both windows held down while the script reads them (an unpinned window rolls up 2 s after the pointer leaves
-- it, and a rolled-up tab or card stops drawing and ticking: bx_farm.lua, H.hold)
function H.hold(w)
    if not w then return end
    w._autoShaded = false
    if w.windowShaded then w:setWindowShaded(false) end
    w._outSince = getTimestampMs() + 600000
end
function H.keepTick()
    -- (god mode and invincible stay on for the whole run, whatever turns them off)
    if S.guard then pcall(H.safe) end
    if not S.holdOn then return end
    H.hold(RT.ww())
    H.hold(RT.cw())
end

-- ---- the character's body: never hurt during the run, healed at the end (bx_farm.lua's H.safe, H.heal, H.hurt)
function H.safe()
    local p = S.p
    if p:isDead() then return end
    if not p:isGodMod() then p:setGodMod(true) end
    if not p:isInvincible() then p:setInvincible(true) end
end
function H.heal()
    local bd = S.p:getBodyDamage()
    bd:RestoreToFullHealth()
    local parts = bd:getBodyParts()
    for k = 0, parts:size() - 1 do
        local b = parts:get(k)
        if b:HasInjury() or b:getFractureTime() > 0 then b:RestoreToFullHealth(); b:setFractureTime(0) end
    end
    if bd:getOverallBodyHealth() < 100 then bd:setOverallBodyHealth(100) end
end
-- what is wrong with the body, in words ("" when he is whole)
function H.hurt()
    local p = S.p
    local bad = {}
    if p:isDead() then bad[#bad + 1] = "dead" end
    local bd = p:getBodyDamage()
    local hp = bd:getOverallBodyHealth()
    if hp < 99.5 then bad[#bad + 1] = "health " .. tostring(hp) end
    if bd:IsInfected() then bad[#bad + 1] = "infected" end
    local parts = bd:getBodyParts()
    for k = 0, parts:size() - 1 do
        local b = parts:get(k)
        if b:HasInjury() then bad[#bad + 1] = "a wound on part " .. k end
        if b:getFractureTime() > 0 then bad[#bad + 1] = "a fracture on part " .. k end
    end
    return table.concat(bad, ", ")
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
function H.eachStaged(fn)
    if not S.cx then return end
    for dx = -S.HALF - 1, S.HALF + 1 do
        for dy = -S.HALF - 1, S.HALF + 1 do
            local sq = H.sq(dx, dy)
            if sq then fn(sq) end
        end
    end
end

-- ---- zones (kept by their objects: a name can change under the script on the old code)
function H.zoneList()
    local out = {}
    local all = DesignationZoneAnimal.getAllZones()
    if all then for i = 0, all:size() - 1 do out[#out + 1] = all:get(i) end end
    return out
end
function H.zoneCount() return #H.zoneList() end
function H.zoneLives(z)
    for _, x in ipairs(H.zoneList()) do if x == z then return true end end
    return false
end
function H.indexOfZone(z)
    for i, x in ipairs(H.zoneList()) do if x == z then return i - 1 end end
    return nil
end
-- how many zones carry a name, and one of them that is not `but`
function H.named(name, but)
    local n, other = 0, nil
    for _, x in ipairs(H.zoneList()) do
        if x:getName() == name then
            n = n + 1
            if x ~= but then other = x end
        end
    end
    return n, other
end
function H.autoName(n) return Z.tr("UI_ZeD_Animals_ZoneAutoName", n) end

-- ---- the Animals tab
function H.st() local w = H.W(); return w and S.AT.getState(w) or nil end
function H.animalsTab() return H.try("the World window's Animals tab (openTab)", S.WWm.openTab, S.pn, "animals") end
function H.onAnimals() local w = H.W(); return w ~= nil and w._activeTab == "animals" end
function H.overview()
    local w = H.W()
    if w then H.try("the sub-tab Ranch (AT.switchSubmode)", S.AT.switchSubmode, w, "ranch") end
end
function H.zonePage(z)
    local w = H.W()
    if not (w and z) then return end
    H.overview()
    H.try("the zone's page (AT.navigate)", S.AT.navigate, w, "zone", z:getName(), nil)
end
-- the zones are painted on the ground for the character (what the zone page's highlight switches on)
function H.painted() return S.p:isSeeDesignationZone() == true end
function H.lit() local w = H.W(); return H.painted() and w ~= nil and w._animalsZoneLit ~= nil end
function H.boxUp()
    local w = H.W()
    local e = w and w._animalsRenameEntry
    return e ~= nil and e:getIsVisible() == true
end
function H.boxText()
    local w = H.W()
    local e = w and w._animalsRenameEntry
    return e and tostring(e:getText()) or nil
end
function H.act(id)
    local w = H.W()
    local ok, r = pcall(S.AT.zoneAct, w, id)
    if not ok then Q.check(false, "the zone page's " .. id .. " (AT.zoneAct): ran without an error", r); return nil end
    return r
end
-- an edit left open by a check that failed: shut, so the next check starts clean
function H.editOff()
    local w = H.W()
    if not w then return end
    w._animalsRenaming, w._animalsRemoveConfirm, w._animalsZoneFrom = false, false, nil
    local e = w._animalsRenameEntry
    if e then e:setVisible(false); e:unfocus() end
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
function H.takeAway(a)
    if not a or S.gone[a] then return false end
    S.gone[a] = true
    local h = a:getHutch()
    if h then h:removeAnimal(a) end
    if H.inWorld(a) then a:removeFromWorld(); a:removeFromSquare() end
    return true
end
function H.stress(a, v)
    a:setDebugStress(v)
    if a:getStress() <= 10 then a:changeStress(v) end
    return a:getStress()
end
-- the zombies within r squares of an animal, counted the old way (every square's moving objects): the script's own
-- count, to hold the stress line against
function H.walkZ(a, r)
    local sq = a:getCurrentSquare()
    if not sq then return 0 end
    local n, cell = 0, getCell()
    for x = sq:getX() - r, sq:getX() + r do
        for y = sq:getY() - r, sq:getY() + r do
            local gs = cell:getGridSquare(x, y, sq:getZ())
            local mo = gs and gs:getMovingObjects()
            if mo then
                for i = 0, mo:size() - 1 do
                    if instanceof(mo:get(i), "IsoZombie") then n = n + 1 end
                end
            end
        end
    end
    return n
end
function H.zombieOff()
    local z = S.zombie
    S.zombie = nil
    if z then z:removeFromWorld(); z:removeFromSquare() end
end

-- ---- the pointer the game's Lua reads (Mouse.setXY does not move it: zedqa_pagelist_lib.lua, S.wheelAt): for a
-- few frames getMouseX, getMouseY and the left button answer what the script says
function H.mouseFake(x, y, down)
    if not S.swaps.mouse then
        local gx, gy, gd = getMouseX, getMouseY, isMouseButtonDown
        getMouseX = function() return S.fake.x end
        getMouseY = function() return S.fake.y end
        isMouseButtonDown = function(b)
            if b == 0 then return S.fake.down == true end
            return gd(b)
        end
        S.swaps.mouse = function() getMouseX, getMouseY, isMouseButtonDown = gx, gy, gd end
    end
    S.fake.x, S.fake.y, S.fake.down = x, y, down
end
function H.inWin(w, x, y)
    if not (w and w:getIsVisible()) then return false end
    local ax, ay = w:getAbsoluteX(), w:getAbsoluteY()
    return x >= ax and y >= ay and x < ax + w:getWidth() and y < ay + w:getHeight()
end
function H.sqAt(x, y)
    return getCell():getGridSquare(screenToIsoX(0, x, y, 0), screenToIsoY(0, x, y, 0), 0)
end
-- a point of the screen off both ZeD windows with a loaded square under it
function H.groundPoint()
    local W, Hh = RT.core:getScreenWidth(), RT.core:getScreenHeight()
    for _, fy in ipairs({ 0.5, 0.62, 0.4, 0.75, 0.3 }) do
        for _, fx in ipairs({ 0.5, 0.4, 0.6, 0.3, 0.7, 0.2, 0.8 }) do
            local x, y = math.floor(W * fx), math.floor(Hh * fy)
            if not H.inWin(RT.ww(), x, y) and not H.inWin(RT.cw(), x, y) and H.sqAt(x, y) then return x, y end
        end
    end
    return nil, nil
end

-- ---- the hen house
function H.eggs(i)
    local nb = S.hutch and S.hutch:getNestBox(i)
    return nb and nb:getEggsNb() or 0
end
function H.fillEggs(i, n)
    local nb = S.hutch:getNestBox(i)
    for _ = 1, 12 do
        if nb:getEggsNb() >= n then break end
        nb:addEgg(instanceItem("Base.Egg"))
    end
end
function H.emptyBox(i)
    local nb = S.hutch and S.hutch:getNestBox(i)
    for _ = 1, 12 do
        if not nb or nb:getEggsNb() <= 0 then break end
        nb:removeEgg(0)
    end
end
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
function H.first() local q = H.queue(); return q and q[1] or nil end

-- ---- the campfire
function H.campLua(sq)
    local lo = nil
    pcall(function() lo = CCampfireSystem.instance:getLuaObjectOnSquare(sq) end)
    return lo
end
function H.takeFire()
    if not S.cfSq then return false end
    local so = SCampfireSystem.instance:getLuaObjectOnSquare(S.cfSq)
    if so then SCampfireSystem.instance:removeCampfire(so); return true end
    return false
end
function H.fuelRow(ft)
    local d = H.d()
    for _, r in ipairs(d and d.fuelRows or {}) do if r.fullType == ft then return r end end
    return nil
end

-- ===================================================================== 0. the ledger, the windows, the farm
function H.ledger()
    local p = S.p
    if ZEDQA_HOME then pcall(ZEDQA_HOME, Q.tag) end
    S.home = { x = p:getX(), y = p:getY() }
    S.primary, S.secondary = p:getPrimaryHandItem(), p:getSecondaryHandItem()
    S.god = p:isGodMod() == true
    S.inv = p:isInvincible() == true
    S.instant = p:isTimedActionInstantCheat() == true
    -- nothing may hurt him: god mode and invincible on before anything else, and kept on every tick until he is home
    -- and healed (H.keepTick, S.guard; the last step gives them back as found)
    p:setGodMod(true)
    p:setInvincible(true)
    S.guard = true
    Events.OnTick.Add(H.keepTick)
    S.see0 = p:isSeeDesignationZone() == true
    local parts = p:getBodyDamage():getBodyParts()
    for k = 0, parts:size() - 1 do S.stiff[k] = parts:get(k):getStiffness() end
    local all = p:getInventory():getAllEvalRecurse(function(it) return true end)
    for k = 0, all:size() - 1 do S.had[all:get(k)] = true end
    S.zones0 = H.zoneCount()
    S.staged = true
    p:setTimedActionInstantCheat(false)   -- (the egg checks need the game's real walk and grab)
    -- (empty hands: the hen house's grabs would queue an unequip first; given back at the end)
    if S.primary then p:setPrimaryHandItem(nil) end
    if S.secondary then p:setSecondaryHandItem(nil) end
    if S.see0 then p:setSeeDesignationZone(false) end
end
Q.step(5, function()
    local world = getWorld() and getWorld():getWorld()
    if world ~= "ZeD-QA" then S.dead = true; Q.skip("the whole script", "not the ZeD-QA save: " .. tostring(world)); return end
    if not (S.OC and S.OC.kinds and S.AT and S.AP and S.SI and S.WWm and S.CWm) then
        S.dead = true
        Q.check(false, "ZeD's Animals tab, its stress reading and the object cards are loaded", "missing")
        return
    end
    if Z.Safe and Z.Safe.on and Z.Safe.on() then S.dead = true; Q.skip("the whole script", "ZeD is in safe mode: the game's own windows would open"); return end
    if not S.p or S.p:isDead() then S.dead = true; Q.skip("the whole script", "no living character"); return end
    if not (S.AT.startZoneCreate and S.AT.navigate and S.AT.switchSubmode and S.AT.zoneAct and S.AT.showAnimal and S.AT.endZoneDraw
            and DesignationZoneAnimal and AnimalDefinitions and addAnimal) then
        S.dead = true
        Q.check(false, "the Animals tab's page, zone and drawing functions and the game's animals are there", "missing")
        return
    end
    -- (a ledger that threw: nothing is staged and nothing is run; the last step still heals and puts the cheats back)
    local okL, eL = pcall(H.ledger)
    if not okL then S.dead = true; Q.check(false, "the ledger of what is there was written", eL); return end
    local safeOn = S.p:isGodMod() and S.p:isInvincible()
    Q.check(safeOn, "god mode and invincible are on for the run", tostring(S.p:isGodMod()) .. " " .. tostring(S.p:isInvincible()))
    -- (without both he is not taken to the farm: nothing is staged or run, and the put-back still runs)
    if not safeOn then S.dead = true; return end
    if ZEDQA_SPEED then pcall(ZEDQA_SPEED, 1) elseif getGameSpeed() ~= 1 then setGameSpeed(1) end
    S.opened = not RT.isOpen()
    RT.pairOpen()
    S.holdOn = true
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
        S.dead = true
        Q.skip("every scene", "no open 17 x 17 within " .. S.SEARCH .. " squares of the farm point (" .. tostring(best) .. ")")
        return
    end
    S.cx, S.cy = best[1], best[2]
    H.centre()
    Q.say("open ground: centre " .. S.cx .. "," .. S.cy)
end)
pause(1200)
step(2, nil, function()
    H.eachStaged(function(sq)
        local wos = sq:getWorldObjects()
        for k = 0, wos:size() - 1 do S.woPre[wos:get(k)] = true end
    end)
    Q.check(S.p:getCurrentSquare() ~= nil and math.abs(S.p:getX() - (S.cx + 0.5)) < 1, "the character stands on the farm's open ground",
        math.floor(S.p:getX()) .. "," .. math.floor(S.p:getY()))
    -- two zones with the game's own maker (no fence), three squares of open ground between them
    local zA = DesignationZoneAnimal.new("VX pen A", S.cx - 8, S.cy - 8, 0, S.cx - 2, S.cy - 2, true)
    S.zones[#S.zones + 1] = zA
    local zB = DesignationZoneAnimal.new("VX pen B", S.cx + 3, S.cy - 8, 0, S.cx + 9, S.cy - 2, true)
    S.zones[#S.zones + 1] = zB
    S.zA, S.zB = zA, zB
    -- (W32's Reset: the old code offered "zone <B's place in the list + 1>"; zone A takes that very name, unless
    -- another zone of the save has it already, so the old offer is a taken name either way)
    local iB = H.indexOfZone(zB)
    if iB then
        S.oldOffer = H.autoName(iB + 1)
        local n = H.named(S.oldOffer, nil)
        if n == 0 then zA:setName(S.oldOffer) end
        local n2, other = H.named(S.oldOffer, zB)
        S.resetArmed = n2 >= 1 and other ~= nil
    end
    S.nameA, S.nameB = zA:getName(), zB:getName()
    S.AP.refreshCache(S.pn)
    S.cow = H.spawn("cow", -5, -5)       -- (in zone A)
    S.hen = H.spawn("hen", 0, -5)        -- (between the zones: in no zone)
    Q.say("zones: A '" .. tostring(S.nameA) .. "', B '" .. tostring(S.nameB) .. "' (the old Reset would offer '" .. tostring(S.oldOffer)
        .. "', taken: " .. tostring(S.resetArmed) .. "); cow " .. tostring(S.cow ~= nil) .. ", hen " .. tostring(S.hen ~= nil))
    if not (H.zoneLives(zA) and H.zoneLives(zB) and S.AP.getZoneSummary(S.nameA, S.pn) and S.AP.getZoneSummary(S.nameB, S.pn)) then
        H.off("zones", "two animal zones could not be made at the farm")
        return
    end
    H.animalsTab()
end)
wait(4000, "zones", H.onAnimals, function(ok)
    if not Q.check(ok, "the World window shows the Animals tab", tostring(H.W() and H.W()._activeTab)) then H.off("zones", "the Animals tab did not open") end
end)

-- ===================================================================== 1. W29: the zone page's ground highlight
step(3, "zones", function() H.zonePage(S.zA) end)
wait(3000, "zones", H.lit, function(ok)
    S.litOk = ok
    if not ok then
        Q.skip("W29: every way out of the lit zone page", "zone A's page never lit its zone (painted " .. tostring(H.painted()) .. ", view " .. tostring(H.st() and H.st().view) .. ")")
        return
    end
    -- (a) the Butcher sub-tab
    H.try("the sub-tab Butcher (AT.switchSubmode)", S.AT.switchSubmode, H.W(), "butcher")
end)
pause(300)
step(2, "zones", function()
    if not S.litOk then return end
    Q.check(not H.painted(), "W29: the zone page left by the Butcher sub-tab: the zones are no longer painted on the ground",
        "isSeeDesignationZone " .. tostring(H.painted()))
    S.p:setSeeDesignationZone(false)
    H.zonePage(S.zA)
end)
wait(3000, "zones", H.lit, function(ok)
    if not S.litOk then return end
    S.litB = ok
    if not ok then Q.skip("W29: the zone page left by the Loot tab", "the page did not light again"); return end
    -- (b) another tab of the World window, by its strip (as a click)
    S.tabOk = RT.worldTab("loot")
end)
wait(1500, "zones", function() return S.litB and not H.painted() end, function()
    if not (S.litOk and S.litB) then return end
    local w = H.W()
    Q.check(S.tabOk and w._activeTab == "loot" and not H.painted(), "W29: the zone page left by the World window's Loot tab: the zones are no longer painted",
        "tab " .. tostring(w._activeTab) .. ", isSeeDesignationZone " .. tostring(H.painted()))
    S.p:setSeeDesignationZone(false)
    H.animalsTab()
end)
wait(4000, "zones", H.onAnimals, function() H.zonePage(S.zA) end)
wait(3000, "zones", H.lit, function(ok)
    if not S.litOk then return end
    S.litC = ok
    if not ok then Q.skip("W29: the zone page left by closing the windows", "the page did not light again"); return end
    -- (c) both windows closed
    RT.pairShut()
end)
wait(1500, "zones", function() return S.litC and not H.painted() end, function()
    if not (S.litOk and S.litC) then return end
    Q.check(H.W() == nil and not H.painted(), "W29: the windows closed on a lit zone page: the zones are no longer painted",
        "World window open " .. tostring(H.W() ~= nil) .. ", isSeeDesignationZone " .. tostring(H.painted()))
    S.p:setSeeDesignationZone(false)
end)
step(2, "zones", function() RT.pairOpen() end)
pause(900)
step(2, "zones", function() H.animalsTab() end)
wait(4000, "zones", H.onAnimals, function(ok)
    if not ok then H.off("zones", "the Animals tab did not open again after the windows were closed"); return end
    H.zonePage(S.zA)
end)
wait(3000, "zones", H.lit, function(ok)
    if not S.litOk then return end
    S.litD = ok and S.hen ~= nil
    if not S.litD then Q.skip("W29: an animal in no zone opened from the lit page", "the page did not light again, or no hen"); return end
    -- (d) an animal that is in no zone, opened the way a hen house card's Info opens it
    H.try("an animal's page (AT.showAnimal)", S.AT.showAnimal, H.W(), S.hen)
end)
pause(500)
step(2, "zones", function()
    if not (S.litOk and S.litD) then return end
    local st = H.st()
    if st.zoneName ~= nil then
        Q.skip("W29: an animal in no zone opened from the lit page", "the tab counts the hen in the zone '" .. tostring(st.zoneName) .. "'")
    else
        Q.check(st.view == "animal" and not H.painted(),
            "W29: an animal in no zone opened from a lit zone page (AT.showAnimal: a hen house card's Info, the game's animal Info): zone A is no longer painted",
            "view " .. tostring(st.view) .. ", isSeeDesignationZone " .. tostring(H.painted()))
    end
    S.p:setSeeDesignationZone(false)
    H.overview()
end)

-- ===================================================================== 2. W30: the rename box and the remove question
step(3, "zones", function()
    H.editOff()
    H.zonePage(S.zA)
end)
pause(300)
step(2, "zones", function()
    local w = H.W()
    S.renOk = H.act("rename") == true and w._animalsRenaming == true
    if not S.renOk then Q.check(false, "W30: Rename on zone A opens the box", "renaming " .. tostring(w._animalsRenaming)) end
end)
pause(300)
step(2, "zones", function()
    if not S.renOk then return end
    local w = H.W()
    S.boxA = H.boxText()
    if not Q.check(H.boxUp() and S.boxA == S.nameA, "W30: Rename on zone A shows the box with A's name", tostring(S.boxA)) then S.renOk = false; H.editOff(); return end
    H.try("the sub-tab Butcher (AT.switchSubmode)", S.AT.switchSubmode, w, "butcher")
end)
pause(300)
step(2, "zones", function()
    if not S.renOk then return end
    local w = H.W()
    Q.check(not H.boxUp() and not w._animalsRenaming, "W30: the Butcher sub-tab pressed mid-rename: the box is gone",
        "box showing " .. tostring(H.boxUp()) .. ", renaming " .. tostring(w._animalsRenaming))
    H.zonePage(S.zB)
end)
pause(400)
step(2, "zones", function()
    if not S.renOk then return end
    local w = H.W()
    local st = H.st()
    Q.check(st.view == "zone" and st.zoneName == S.nameB and not w._animalsRenaming and not H.boxUp(),
        "W30: zone B opened next is not in rename mode", "view " .. tostring(st.view) .. ", renaming " .. tostring(w._animalsRenaming)
        .. ", box showing " .. tostring(H.boxUp()) .. " holding '" .. tostring(H.boxText()) .. "'")
    -- Save pressed now (where the old code's Save button stood): nothing may be renamed
    local r = H.act("save")
    Q.check(r == false and S.zB:getName() == S.nameB, "W30: Save pressed on zone B's page renames nothing",
        "Save answered " .. tostring(r) .. ", zone B is named '" .. tostring(S.zB:getName()) .. "'")
    if S.zB:getName() ~= S.nameB then S.zB:setName(S.nameB); S.AP.refreshCache(S.pn) end
    H.editOff()
    H.zonePage(S.zA)
end)
pause(300)
step(2, "zones", function()
    local w = H.W()
    S.remOk = H.act("remove") == true and w._animalsRemoveConfirm == true
    if not S.remOk then Q.check(false, "W30: Remove zone on zone A asks first", "asking " .. tostring(w._animalsRemoveConfirm)); return end
    -- a roster row's click: the cow's page
    H.try("an animal's row (AT.navigate)", S.AT.navigate, w, "animal", nil, S.cow)
end)
pause(300)
step(2, "zones", function()
    if not S.remOk then return end
    local w = H.W()
    S.remAnimal = w._animalsRemoveConfirm
    H.try("Back (AT.navigateBack)", S.AT.navigateBack, w)
    H.editOff()
    H.act("remove")
    S.remAgain = w._animalsRemoveConfirm == true
    -- zone B opened while A's question is up
    H.zonePage(S.zB)
end)
pause(400)
step(2, "zones", function()
    if not S.remOk then return end
    local w = H.W()
    local st = H.st()
    Q.check(not S.remAnimal, "W30: an animal's row pressed while Remove asks: the question is dropped", "still asking " .. tostring(S.remAnimal))
    Q.check(S.remAgain and st.zoneName == S.nameB and not w._animalsRemoveConfirm, "W30: zone B opened while zone A's Remove asks: B's page does not ask",
        "asked on A " .. tostring(S.remAgain) .. ", page " .. tostring(st.zoneName) .. ", asking " .. tostring(w._animalsRemoveConfirm))
    -- (a guard, not a proof: the script never answers Yes, so both zones must still be there on any build; it
    -- prints only when one is gone)
    if not (H.zoneLives(S.zA) and H.zoneLives(S.zB)) then
        Q.check(false, "W30 guard: both zones are still there (nothing was confirmed)", H.zoneCount() .. " zones")
    end
    H.editOff()
    -- the World window's Loot tab pressed mid-rename (the finding's "World window tab switch")
    H.zonePage(S.zA)
end)
pause(300)
step(2, "zones", function()
    S.renTab = H.act("rename") == true
end)
pause(300)
step(2, "zones", function()
    S.renTab = S.renTab and H.boxUp()
    if not S.renTab then Q.skip("W30: the Loot tab pressed mid-rename", "the rename box did not open"); return end
    S.tabOk = RT.worldTab("loot")
end)
pause(700)
step(2, "zones", function()
    if S.renTab then
        local w = H.W()
        Q.check(S.tabOk and w._activeTab == "loot" and not H.boxUp(), "W30: the Loot tab pressed mid-rename: no rename box is left over the Loot tab",
            "tab " .. tostring(w._activeTab) .. ", box showing " .. tostring(H.boxUp()) .. ", renaming " .. tostring(w._animalsRenaming))
    end
    H.editOff()
    H.animalsTab()
end)
wait(4000, "zones", H.onAnimals, function(ok)
    if not ok then H.off("zones", "the Animals tab did not come back"); return end
    H.editOff()
    -- ================================================================= 3. W32: a taken name, and Reset's offer
    H.zonePage(S.zB)
end)
pause(300)
step(2, "zones", function() S.r32 = H.act("rename") == true end)
pause(300)
step(2, "zones", function()
    local w = H.W()
    if not (S.r32 and w._animalsRenameEntry) then Q.check(false, "W32: Rename on zone B opens the box", tostring(S.r32)); S.r32 = false; return end
    -- Reset first: the name it offers
    H.act("reset")
    local offer = H.boxText()
    local _, other = H.named(offer, S.zB)
    Q.check(offer ~= nil and offer ~= "" and other == nil, "W32: Reset offers a name no other zone holds",
        "offered '" .. tostring(offer) .. "', held by another zone " .. tostring(other ~= nil) .. " (the old offer '" .. tostring(S.oldOffer) .. "' was taken: " .. tostring(S.resetArmed) .. ")")
    -- zone A's exact name typed and saved
    w._animalsRenameEntry:setText(S.nameA)
    H.act("save")
end)
pause(400)
step(2, "zones", function()
    if not S.r32 then return end
    local w = H.W()
    local n = H.named(S.nameA, nil)
    Q.check(S.zB:getName() == S.nameB and n == 1, "W32: Save with zone A's name is refused: zone B keeps its name, one zone is named '" .. tostring(S.nameA) .. "'",
        "zone B '" .. tostring(S.zB:getName()) .. "', zones named '" .. tostring(S.nameA) .. "': " .. n)
    Q.check(w._animalsRenaming == true and H.boxUp(), "W32: the box stays open after the refusal (the player can type another name)",
        "renaming " .. tostring(w._animalsRenaming) .. ", box showing " .. tostring(H.boxUp()))
    -- the tab's by-name table as that Save left it, read BEFORE anything is put right (the old code renamed B to A's
    -- name, so one name held both zones and B's summary was gone; read after the put-right it passed on any build)
    pcall(S.AP.refreshCache, S.pn)
    local sA, sB = S.AP.getZoneSummary(S.nameA, S.pn), S.AP.getZoneSummary(S.nameB, S.pn)
    Q.check(sA ~= nil and sB ~= nil, "W32: after that Save the Animals tab still has a summary for both zones",
        "'" .. tostring(S.nameA) .. "' " .. tostring(sA ~= nil) .. ", '" .. tostring(S.nameB) .. "' " .. tostring(sB ~= nil))
    -- put right (the old code's rename), then zone B's own page again: the old Save also moved the page to A's name
    if S.zB:getName() ~= S.nameB then S.zB:setName(S.nameB) end
    pcall(S.AP.refreshCache, S.pn)
    H.editOff()
    H.zonePage(S.zB)
end)
pause(300)
step(2, "zones", function()
    if not S.r32 then return end
    -- (a guard for the fix: a free name must still be saved)
    S.r32b = H.act("rename") == true
end)
pause(300)
step(2, "zones", function()
    if not S.r32 then return end
    local w = H.W()
    local st = H.st()
    if not (S.r32b and w and st and w._animalsRenameEntry and H.boxUp() and st.zoneName == S.nameB) then
        Q.check(false, "W32 guard: Rename on zone B opens the box again", "rename " .. tostring(S.r32b) .. ", page '" .. tostring(st and st.zoneName) .. "'")
        S.r32b = false
        return
    end
    w._animalsRenameEntry:setText("VX pen C")
    H.act("save")
end)
pause(300)
step(2, "zones", function()
    if S.r32 and S.r32b then
        Q.check(S.zB:getName() == "VX pen C", "W32 guard: Save with a free name still renames the zone", "zone B '" .. tostring(S.zB:getName()) .. "'")
    end
    S.nameB = S.zB:getName()
    pcall(S.AP.refreshCache, S.pn)
    H.editOff()
    H.overview()
end)

-- ===================================================================== 4. W28: a zone drawing left half-done
step(3, "zones", function()
    S.p:setSeeDesignationZone(false)
    local w = H.W()
    H.try("Create zone (AT.startZoneCreate)", S.AT.startZoneCreate, w)
    local zc = w._zoneCreate
    S.drawOk = zc ~= nil and zc.active == true and ISWorldObjectContextMenu.disableWorldMenu == true and H.painted()
    if not Q.check(S.drawOk, "W28 stage: Create zone starts the drawing (world menu held off, zones painted)",
        "active " .. tostring(zc and zc.active) .. ", disableWorldMenu " .. tostring(ISWorldObjectContextMenu.disableWorldMenu)) then return end
    S.tabOk = RT.worldTab("loot")
end)
wait(1500, "zones", function() return ISWorldObjectContextMenu.disableWorldMenu ~= true end, function()
    if not S.drawOk then return end
    local w = H.W()
    local zc = w._zoneCreate
    Q.check(S.tabOk and w._activeTab == "loot" and ISWorldObjectContextMenu.disableWorldMenu ~= true and not H.painted(),
        "W28: the Loot tab pressed mid-drawing: the world's right-click menu is back and the zones are no longer painted",
        "tab " .. tostring(w._activeTab) .. ", disableWorldMenu " .. tostring(ISWorldObjectContextMenu.disableWorldMenu) .. ", isSeeDesignationZone " .. tostring(H.painted()))
    Q.check(zc.active ~= true and S.AT._zoneDrawWin == nil, "W28: the drawing itself is over", "active " .. tostring(zc.active) .. ", phase " .. tostring(zc.phase))
    pcall(S.AT.endZoneDraw)
    ISWorldObjectContextMenu.disableWorldMenu = false
    S.p:setSeeDesignationZone(false)
    H.animalsTab()
end)
wait(4000, "zones", H.onAnimals, function(ok)
    if not ok then H.off("zones", "the Animals tab did not come back"); return end
    -- the title bar is not a corner: first a press on open ground (the drawing must still answer the mouse)
    local w = H.W()
    H.overview()
    H.try("Create zone (AT.startZoneCreate)", S.AT.startZoneCreate, w)
    S.gx, S.gy = H.groundPoint()
    -- (the middle of the title bar, half its height down)
    local tbH = (w.titleBarHeight and w:titleBarHeight()) or 12
    S.tx, S.ty = math.floor(w:getAbsoluteX() + w:getWidth() / 2), math.floor(w:getAbsoluteY() + tbH / 2)
    S.titleSq = H.sqAt(S.tx, S.ty) ~= nil
    local zc = w._zoneCreate
    S.mouseOk = zc ~= nil and zc.active == true and S.gx ~= nil and S.titleSq
    if not S.mouseOk then
        Q.skip("W28: a press on the title bar is not a corner", "no test point (open ground point " .. tostring(S.gx) .. ", a square under the title bar " .. tostring(S.titleSq) .. ")")
        return
    end
    H.mouseFake(S.gx, S.gy, false)
end)
step(4, "zones", function() if S.mouseOk then H.mouseFake(S.gx, S.gy, true) end end)
step(5, "zones", function()
    if not S.mouseOk then return end
    local zc = H.W()._zoneCreate
    S.ctl = zc.phase == "drawing" and zc.startX ~= nil
    S.ctlSeen = tostring(zc.phase)
    H.mouseFake(S.gx, S.gy, false)
end)
step(5, "zones", function()
    if not S.mouseOk then return end
    local zc = H.W()._zoneCreate
    Q.check(S.ctl and zc.phase == "idle", "W28 control: a press on open ground still starts a corner (a 1 x 1 is dropped on release)",
        "pressed: " .. tostring(S.ctlSeen) .. ", released: " .. tostring(zc.phase))
    if zc.phase ~= "idle" then zc.phase, zc.startX, zc.startY, zc.endX, zc.endY = "idle", nil, nil, nil, nil end
    H.mouseFake(S.tx, S.ty, false)
end)
step(4, "zones", function() if S.mouseOk then H.mouseFake(S.tx, S.ty, true) end end)
step(5, "zones", function()
    if not S.mouseOk then return end
    local zc = H.W()._zoneCreate
    if S.ctl then
        Q.check(zc.active == true and zc.phase == "idle" and zc.startX == nil, "W28: a press on the World window's title bar is not taken as a zone corner",
            "phase " .. tostring(zc.phase) .. ", corner " .. tostring(zc.startX) .. "," .. tostring(zc.startY))
    else
        Q.skip("W28: a press on the title bar is not a corner", "the drawing did not answer the staged press on open ground either")
    end
    H.mouseFake(S.tx, S.ty, false)
end)
step(4, "zones", function()
    H.unswap("mouse")
    pcall(S.AT.endZoneDraw)
    -- (the script ends its own drawing here, so this is no proof of the fix: it prints only when the end fails)
    if ISWorldObjectContextMenu.disableWorldMenu == true then
        Q.check(false, "W28 scene put back: the drawing the script started is ended and the world menu is on", "disableWorldMenu still true")
    end
    ISWorldObjectContextMenu.disableWorldMenu = false
    S.p:setSeeDesignationZone(false)
end)
Q.step(1, function() H.unswap("mouse") end)

-- ===================================================================== 5. W31: a stressed animal's page
step(3, "zones", function()
    if not S.cow then Q.skip("W31: the stressed animal's page", "no cow could be made"); S.noCow = true; return end
    local w = H.W()
    H.zonePage(S.zA)
    H.try("the cow's row (AT.navigate)", S.AT.navigate, w, "animal", nil, S.cow)
    S.stress = H.stress(S.cow, 60)
    -- every working of the stress line is counted from here
    local real = S.SI.inferSources
    S.siCalls, S.siFrames = 0, 0
    S.SI.inferSources = function(a, p)
        S.siCalls = S.siCalls + 1
        return real(a, p)
    end
    S.swaps.si = function() S.SI.inferSources = real end
end)
pause(400)   -- (the page's first frames: its first working is not in the count)
step(1, "zones", function() if not S.noCow then S.siCalls, S.siFrames, S.siT = 0, 0, getTimestampMs() end end)
wait(3000, "zones", function()
    if S.noCow then return true end
    S.siFrames = S.siFrames + 1
    if S.cow:getStress() <= 10 then S.cow:setDebugStress(60) end
    return false
end, function()
    if S.noCow then return end
    local ms = getTimestampMs() - S.siT
    local st = H.st()
    local stress = S.cow:getStress()
    H.unswap("si")
    if st.view ~= "animal" or stress <= 10 then
        Q.skip("W31: the stress line's workings per second", "the cow's page with stress above 10 could not be staged (view " .. tostring(st.view) .. ", stress " .. tostring(stress) .. ")")
    elseif S.siFrames < 20 then
        Q.skip("W31: the stress line's workings per second", "only " .. S.siFrames .. " frames were drawn in " .. ms .. " ms")
    else
        -- (the fix: about one a second; the old code: one on every drawn frame)
        Q.check(S.siCalls <= 5, "W31: a stressed animal's page works its stress line out about once a second, not on every frame",
            S.siCalls .. " workings over " .. S.siFrames .. " frames in " .. ms .. " ms (stress " .. math.floor(stress) .. ")")
    end
    -- one working: what it asks the game's map for (the old code: 961 squares one by one)
    local realCell = getCell
    local cell = realCell()
    local n = { sq = 0, list = 0, other = 0 }
    local proxy = {}
    function proxy.getGridSquare(_, x, y, z) n.sq = n.sq + 1; return cell:getGridSquare(x, y, z) end
    function proxy.getZombieList(_) n.list = n.list + 1; return cell:getZombieList() end
    setmetatable(proxy, { __index = function(_, k)
        return function(_, ...)
            n.other = n.other + 1
            local f = cell[k]
            return f(cell, ...)
        end
    end })
    S.swaps.cell = function() getCell = realCell end
    getCell = function() return proxy end
    local okS, list = pcall(S.SI.inferSources, S.cow, S.p)
    H.unswap("cell")
    if not okS then
        Q.check(false, "W31: one working of the stress line ran without an error", list)
    else
        Q.check(n.sq <= 4, "W31: one working of the stress line looks up no squares one by one",
            "squares asked for: " .. n.sq .. ", the zombie list read " .. n.list .. " time(s), other map calls " .. n.other)
    end
    -- a zombie staged 7 squares west of the cow (it cannot move or bite; the character is 12 squares off, in god
    -- mode and invincible): the line must still count it. (A guard for the fix, not a proof: the old square walk
    -- counted right too; this catches a faster count that counts wrong.)
    S.walk0 = H.walkZ(S.cow, 15)
    local csq = S.cow:getCurrentSquare()
    local zsq = csq and getCell():getGridSquare(csq:getX() - 7, csq:getY(), 0)
    if S.p:isGodMod() and S.p:isInvincible() and zsq and zsq:isFree(false) then
        local zl = addZombiesInOutfit(zsq:getX(), zsq:getY(), 0, 1, nil, 0)
        if zl and zl:size() > 0 then
            S.zombie = zl:get(0)
            S.zombie:setUseless(true)
        end
    end
end)
wait(1500, "zones", function() return S.noCow or S.zombie == nil or H.walkZ(S.cow, 15) > (S.walk0 or 0) end, function()
    if S.noCow then return end
    local seen = H.walkZ(S.cow, 15)
    if S.zombie == nil or seen < 1 then
        pcall(H.zombieOff)
        Q.skip("W31 guard: the stress line still counts a zombie near the animal", "a zombie could not be staged near the cow (seen " .. seen .. ")")
    else
        local okS, list = pcall(S.SI.inferSources, S.cow, S.p)
        pcall(H.zombieOff)
        local want = (seen == 1) and Z.tr("UI_ZeD_Animals_StressZombie") or Z.tr("UI_ZeD_Animals_StressZombies", seen)
        local found = false
        for _, s in ipairs(okS and list or {}) do if s == want then found = true end end
        if okS and not found and #list >= 3 then
            Q.skip("W31 guard: the stress line still counts a zombie near the animal", "the line is capped at three causes: " .. table.concat(list, ", "))
        else
            Q.check(okS and found, "W31 guard: the stress line still counts the zombies near the animal (" .. seen .. " within 15 squares, counted square by square)",
                okS and table.concat(list, ", ") or tostring(list))
        end
    end
    S.cow:setDebugStress(0)
    H.overview()
end)
Q.step(1, function() H.unswap("si"); H.unswap("cell"); pcall(H.zombieOff) end)

-- ===================================================================== 6. W33: the egg chain
step(5, "hutch", function()
    H.stop(); H.close(); H.centre()
    local def = HutchDefinitions and HutchDefinitions.hutchs and HutchDefinitions.hutchs.hutchhen
    if not (def and IsoHutch and ISHutchMenu and ISHutchMenu._zedCardHooked and ISHutchGrabEgg) then
        H.off("hutch", "the game's hen house or ZeD's hook on its Info is missing"); return
    end
    S.hutchSq = H.sq(-5, 4)
    for _, o in ipairs({ { 0, 0 }, { 1, 0 }, { 0, -1 }, { 1, -1 }, { 0, 1 } }) do
        if not H.openSq(H.sq(-5 + o[1], 4 + o[2])) then H.off("hutch", "no free ground for a hen house"); return end
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
    if h:getMaxNestBox() < 2 or not h:getNestBox(0) or not h:getNestBox(1) or not h:getNestBox(2) then H.off("hutch", "the hen house has fewer than three nest boxes"); return end
    if not h:isEggHatchDoorOpen() then h:toggleEggHatchDoor() end
    -- (the first run takes three boxes: the old code restarted the second box by itself and still held the third
    -- for later; the second box holds 4 eggs, so that restarted grab is still going at the 2 s mark and the third box
    -- is still waiting then. With two boxes the "forgotten" line passed on the old code too.)
    H.fillEggs(0, 3)
    H.fillEggs(1, 4)
    H.fillEggs(2, 2)
    S.entry = h:getEntrySq() or S.hutchSq
    -- where the character starts from: 4 squares from the entry square (inside the card's 5), the open spot
    -- farthest from the hen house
    local best, bestD = nil, -1
    for _, o in ipairs({ { 4, 0 }, { -4, 0 }, { 0, 4 }, { 0, -4 } }) do
        local sq = getCell():getGridSquare(S.entry:getX() + o[1], S.entry:getY() + o[2], 0)
        if H.openSq(sq) then
            local d = math.max(math.abs(sq:getX() - S.hutchSq:getX()), math.abs(sq:getY() - S.hutchSq:getY()))
            if d > bestD then best, bestD = sq, d end
        end
    end
    if not best then H.off("hutch", "no open square 4 from the hen house's entry"); return end
    S.far = best
    H.putOn(S.far)
    H.try("the hen house's Info (ISHutchMenu.onInfo)", ISHutchMenu.onInfo, h, S.p)
end)
wait(8000, "hutch", function() return H.kind() == "hutch" and H.d() ~= nil end, function(ok)
    if not ok then
        local t = RT.find(function(x) return x.Type == "ISHutchUI" end)
        if t then t:removeFromUIManager() end
        H.off("hutch", "the hutch card did not open"); return
    end
    H.fresh()
end)
pause(500)
step(2, "hutch", function()
    local d, eggs = H.d(), H.verb("eggs")
    if not (d and #d.free >= 3 and eggs and eggs.enabled ~= false) then
        H.off("hutch", "the card does not offer Grab eggs for three boxes (free boxes " .. tostring(d and #d.free) .. ")"); return
    end
    S.e0, S.e1, S.e2 = H.eggs(0), H.eggs(1), H.eggs(2)
    S.distStart = H.distTo(S.entry)
    -- (no Husbandry XP from the grabs: H.noXp, given back after the scene)
    H.noXp()
    local ok, err = H.press("oc:verb:eggs")
    if not ok then Q.check(false, "W33: Grab eggs runs", err); H.off("hutch", "Grab eggs could not be pressed") end
end)
pause(350)
step(1, "hutch", function()
    -- stopped during the walk, as a tap on a move key stops it (the queue is cleared)
    local t = H.t()
    S.walking = ISTimedActionQueue.hasActionType(S.p, "ISWalkToTimedAction") == true and H.eggs(0) == S.e0
    S.chainLen = t and t.eggChain and #t.eggChain or 0
    S.qBefore = H.qTypes()
    H.stop()
    S.tStop, S.restartAt, S.restartQ = getTimestampMs(), nil, nil
end)
wait(2000, "hutch", function()
    if not S.restartAt and not H.idle() then
        S.restartAt = getTimestampMs() - S.tStop
        S.restartQ = H.qTypes()
        S.restartDist = H.distTo(S.entry)
    end
    return false
end, function()
    local t = H.t()
    local left = t and t.eggChain and #t.eggChain or 0
    local eggsNow = H.eggs(0) .. "/" .. H.eggs(1) .. "/" .. H.eggs(2)
    if not (S.walking and S.chainLen >= 1) then
        Q.skip("W33: Grab eggs stopped during the walk does not start again", "the stop did not land in the walk with a box still waiting (queue '" .. tostring(S.qBefore) .. "', boxes waiting " .. S.chainLen .. ")")
    else
        Q.check(S.restartAt == nil and H.eggs(0) == S.e0 and H.eggs(1) == S.e1 and H.eggs(2) == S.e2,
            "W33: Grab eggs stopped during the walk: nothing starts by itself in the next 2 s and no egg is taken",
            S.restartAt and ("an action started by itself after " .. S.restartAt .. " ms (" .. tostring(S.restartQ) .. "), " .. string.format("%.1f", S.restartDist or -1) .. " squares from the entry; eggs "
                .. eggsNow .. " of " .. S.e0 .. "/" .. S.e1 .. "/" .. S.e2) or ("idle; eggs " .. eggsNow))
        if S.chainLen >= 2 then
            Q.check(left == 0, "W33: the boxes still waiting are forgotten after the stop", left .. " of " .. S.chainLen .. " still waiting")
        else
            Q.skip("W33: the boxes still waiting are forgotten after the stop", "only " .. S.chainLen .. " box waited (with one, the old code's restart emptied the list too)")
        end
    end
    -- the second run (two boxes): let it grab, and move the character away while the first box is being emptied
    H.stop()
    H.emptyBox(2)
    H.fillEggs(0, 3)
    H.fillEggs(1, 2)
    S.e0, S.e1 = H.eggs(0), H.eggs(1)
    H.putOn(S.far)
    H.fresh()
end)
pause(600)
step(2, "hutch", function()
    local d = H.d()
    if not (H.kind() == "hutch" and d and #d.free >= 2) then S.noRun2 = true; Q.skip("W33: the next box is walked to", "the card lost its two boxes (free " .. tostring(d and #d.free) .. ")"); return end
    local ok, err = H.press("oc:verb:eggs")
    if not ok then S.noRun2 = true; Q.check(false, "W33: Grab eggs runs a second time", err) end
end)
wait(12000, "hutch", function()
    if S.noRun2 then return true end
    local a = H.first()
    return a ~= nil and a.Type == "ISHutchGrabEgg" and H.eggs(0) < S.e0
end, function(ok)
    if S.noRun2 then return end
    if not ok then
        S.noRun2 = true
        H.stop()
        Q.skip("W33: the next box is walked to", "the first grab did not start within 12 s (queue '" .. H.qTypes() .. "', box 1 eggs " .. H.eggs(0) .. ")")
        return
    end
    -- the first egg is out and the grab goes on: the character is set 4 squares off, the action untouched
    S.grabDist = H.distTo(S.entry)
    H.putOn(S.far)
    S.d1, S.sawWalk = nil, false
end)
wait(25000, "hutch", function()
    if S.noRun2 then return true end
    if ISTimedActionQueue.hasActionType(S.p, "ISWalkToTimedAction") == true then S.sawWalk = true end
    if not S.d1 and H.eggs(1) < S.e1 then S.d1 = H.distTo(S.entry) end
    -- (the first grab dropped by the move, should the game do that: no need to wait the whole time)
    if H.idle() and H.eggs(0) > 0 then
        S.idleAt = S.idleAt or getTimestampMs()
        if getTimestampMs() - S.idleAt > 3000 then return true end
    else
        S.idleAt = nil
    end
    return H.eggs(0) == 0 and H.eggs(1) == 0 and H.idle()
end, function(ok)
    if S.noRun2 then return end
    if H.eggs(0) > 0 then
        H.stop()
        Q.skip("W33: the next box is walked to", "the first grab did not finish after the character was moved (box 1 still holds " .. H.eggs(0) .. ")")
        return
    end
    Q.check(ok and S.d1 ~= nil and S.d1 <= 2.3 and S.sawWalk,
        "W33: the next box is grabbed from the hen house's entry, after the walk back (the character was set 4 squares off)",
        (S.d1 and string.format("its first egg left the box with the character %.1f squares from the entry", S.d1) or "box 2 was never grabbed")
            .. ", a walk was queued " .. tostring(S.sawWalk) .. ", eggs left " .. H.eggs(0) .. "/" .. H.eggs(1)
            .. string.format(" (the first box was being grabbed %.1f squares from the entry)", S.grabDist or -1))
    H.stop()
end)
step(2, "hutch", function()
    H.stop(); H.close()
    pcall(H.takeHutch)
end)
-- (the grabs are over, whatever happened above: addXp back)
Q.step(1, function() H.unswap("xp") end)

-- ===================================================================== 7. W34: the fire card's fuel scan
step(5, "fire", function()
    H.stop(); H.close()
    if not (SCampfireSystem and SCampfireSystem.instance and CCampfireSystem and ISCampingMenu and ISCampingMenu._zed_onDisplayInfo) then
        H.off("fire", "the game's campfire system or ZeD's hook on the campfire's Info is missing"); return
    end
    local sq, stand = H.sq(4, 4), H.sq(2, 4)
    if not (H.openSq(sq) and H.openSq(stand) and H.openSq(H.sq(1, 4))) then H.off("fire", "no free ground for a campfire"); return end
    H.putOn(stand)
    S.fireStand = stand
    local ok, err = pcall(function() SCampfireSystem.instance:addCampfire(sq) end)
    S.cfSq = sq
    if not ok then H.off("fire", "the game's campfire system refused: " .. tostring(err)) end
end)
wait(8000, "fire", function()
    local lo = H.campLua(S.cfSq)
    return lo ~= nil and lo:getIsoObject() ~= nil
end, function(ok)
    if not ok then H.off("fire", "the campfire never came into the world"); return end
    -- four kinds of fuel carried (what could not be given is left out; the counts below read what the game finds)
    for _, ft in ipairs({ "Base.Plank", "Base.Plank", "Base.Twigs", "Base.Book", "Base.Newspaper" }) do RT.give(ft) end
    local lo = H.campLua(S.cfSq)
    H.try("the campfire's Info (ZeD's hook)", ISCampingMenu.onDisplayInfo, nil, S.p, lo:getIsoObject(), lo)
end)
wait(5000, "fire", function() local t = H.t(); return H.kind() == "fire" and t ~= nil and t.kind == "campfire" and t.d ~= nil end, function(ok)
    if not ok then H.off("fire", "the fire card did not open on the campfire (" .. tostring(H.kind()) .. ")"); return end
    local e = H.e()
    local def, t = e.def, e.t
    S.fireT = t
    S.scan, S.refresh, S.durNow, S.durOver, S.durLast, S.boundLast, S.inRefresh = 0, 0, 0, 0, 0, 0, false
    -- the game's scan of everything in reach, counted
    local realScan = ISCampingMenu.getNearbyFuelInfo
    ISCampingMenu.getNearbyFuelInfo = function(p)
        S.scan = S.scan + 1
        local info = realScan(p)
        S.lastInfo = info
        return info
    end
    S.swaps.scan = function() ISCampingMenu.getNearbyFuelInfo = realScan end
    -- a fuel's burn time worked out, counted per refresh of the card
    local realDur = ISCampingMenu.getFuelDurationForItem
    ISCampingMenu.getFuelDurationForItem = function(it)
        if S.inRefresh then S.durNow = S.durNow + 1 end
        return realDur(it)
    end
    S.swaps.dur = function() ISCampingMenu.getFuelDurationForItem = realDur end
    -- the card's own refresh, counted (and the burn-time workings of each one held against the fuels listed:
    -- one per fuel, and one per tinder row of the Light list)
    local realRefresh = def.refresh
    def.refresh = function(tt, player)
        if tt ~= S.fireT then return realRefresh(tt, player) end
        S.durNow, S.inRefresh = 0, true
        local okR, err = pcall(realRefresh, tt, player)
        S.inRefresh = false
        S.refresh = S.refresh + 1
        local info = tt._fuelInfo or S.lastInfo
        local bound = 0
        if info then
            bound = #(info.fuelList or {})
            -- (the Light list works out one per tinder row, only with a fire starter in reach and the fire out)
            if info.starters and info.starters[1] and not (tt.d and tt.d.lit) then bound = bound + #(info.tinder or {}) end
        end
        S.durLast, S.boundLast, S.kinds = S.durNow, bound, info and #(info.fuelList or {}) or 0
        if S.durNow > bound then S.durOver = S.durOver + 1 end
        if not okR then error(err) end
    end
    S.swaps.refresh = function() def.refresh = realRefresh end
    S.fireT0 = getTimestampMs()
end)
wait(6000, "fire", never, function()
    local ms = getTimestampMs() - S.fireT0
    S.fireLive = S.refresh >= 10 and H.t() == S.fireT
    if not S.fireLive then
        Q.skip("W34: the fire card's fuel scans", "the card refreshed only " .. S.refresh .. " times in " .. ms .. " ms (it was not drawing)")
        return
    end
    -- (the fix: one scan every 1.5 s, so 4 or 5 in 6 s; the old code: one on every refresh, about 24)
    Q.check(S.scan >= 2 and S.scan <= 6, "W34: with the character still, the fire card scans what is in reach about every 1.5 s, not on every refresh",
        S.scan .. " scans over " .. S.refresh .. " refreshes in " .. ms .. " ms")
    if S.kinds >= 2 then
        Q.check(S.durOver == 0, "W34: each fuel's burn time is worked out once per refresh, not inside the sort",
            S.durOver .. " of " .. S.refresh .. " refreshes went over; the last one: " .. S.durLast .. " workings for " .. S.kinds .. " fuels (" .. S.boundLast .. " with the tinder rows)")
    else
        Q.skip("W34: each fuel's burn time is worked out once per refresh", "fewer than two kinds of fuel in reach (" .. tostring(S.kinds) .. ")")
    end
    -- the card must not go stale: a step to the next square is rescanned at the next refresh. (Guards for the slower
    -- clock, not proofs: the old code rescanned on every refresh and passed these too.)
    S.scan0 = S.scan
    H.putOn(H.sq(1, 4))
end)
wait(1200, "fire", function() return not S.fireLive or S.scan > S.scan0 end, function(ok)
    if not S.fireLive then return end
    Q.check(ok and H.t() == S.fireT, "W34 guard: a step to another square is rescanned at once (the card does not go stale)", (S.scan - S.scan0) .. " new scans, card open " .. tostring(H.t() == S.fireT))
    -- and fuel that turns up is listed within two refreshes of the 1.5 s clock
    S.hadLog = H.fuelRow("Base.Log") ~= nil
    S.log = RT.give("Base.Log")
end)
wait(2600, "fire", function() return not S.fireLive or S.hadLog or S.log == nil or H.fuelRow("Base.Log") ~= nil end, function(ok)
    if not S.fireLive then return end
    if S.hadLog or S.log == nil then
        Q.skip("W34 guard: fuel that turns up is listed within 2 s", S.hadLog and "a log was in reach already" or "a log could not be given")
    else
        Q.check(ok and H.fuelRow("Base.Log") ~= nil, "W34 guard: fuel that turns up is listed within 2 s", "a log row " .. tostring(H.fuelRow("Base.Log") ~= nil))
    end
end)
Q.step(2, function()
    H.unswap("refresh"); H.unswap("dur"); H.unswap("scan")
end)

-- ===================================================================== 8. PUT BACK
function H.backWindows()
    local w = H.W()
    pcall(S.AT.endZoneDraw)
    ISWorldObjectContextMenu.disableWorldMenu = false
    H.editOff()
    H.close()
    local stray = RT.find(function(x) return x.Type == "ISHutchUI" or x.Type == "ISAnimalUI" end)
    if stray then stray:removeFromUIManager() end
    getCell():setDrag(nil, S.pn)
    -- (the zone page's ground highlight, ended the way ZeD ends it when the page is left; the old code has no such
    -- helper, and H.backBody puts the paint back as found either way)
    if w and S.AT._unlightZone then pcall(S.AT._unlightZone, w) end
    if w and S.at0 then
        if w._animalsZoneState then w._animalsZoneState.sel = nil end
        local st = S.AT.getState(w)
        st.submode, st.view, st.zoneName, st.animalRef, st.prevView = S.at0.submode, S.at0.view, S.at0.zoneName, S.at0.animalRef, S.at0.prevView
        w._animalsZoneLit = nil
    end
    if w and S.tab0 and w._activeTab ~= S.tab0 then pcall(S.WWm.openTab, S.pn, S.tab0) end
end
function H.backWorld()
    local n = { zombie = 0, hutch = 0, fire = 0, animals = 0, zones = 0, swept = 0 }
    if S.zombie then if pcall(H.zombieOff) then n.zombie = 1 end end
    if S.hutch then if pcall(H.takeHutch) then n.hutch = 1 end end
    local okF, took = pcall(H.takeFire)
    if okF and took then n.fire = 1 end
    for _, a in ipairs(S.animals) do
        local okA, did = pcall(H.takeAway, a)
        if okA and did then n.animals = n.animals + 1 end
    end
    for _, z in ipairs(S.zones) do
        if H.zoneLives(z) then
            DesignationZoneAnimal.removeZone(z, true)
            n.zones = n.zones + 1
        end
    end
    pcall(S.AP.refreshCache, S.pn)
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
function H.backItems()
    local p = S.p
    local swept = 0
    local all = p:getInventory():getAllEvalRecurse(function(it) return true end)
    for k = all:size() - 1, 0, -1 do
        local it = all:get(k)
        if not S.had[it] then
            local c = it:getContainer()
            if c then p:removeFromHands(it); c:Remove(it); swept = swept + 1 end
        end
    end
    if p:getPrimaryHandItem() ~= S.primary then p:setPrimaryHandItem(S.primary) end
    if p:getSecondaryHandItem() ~= S.secondary then p:setSecondaryHandItem(S.secondary) end
    return swept
end
-- the body, while god mode and invincible are still on: each line on its own, so one that fails stops nothing
-- (god mode and invincible go back as found only in the last step, once he is home and whole: H.backCheats)
function H.backBody()
    local p = S.p
    local bad = {}
    local function go(what, fn) local ok, err = pcall(fn); if not ok then bad[#bad + 1] = what .. ": " .. tostring(err) end end
    go("god mode held", H.safe)
    go("heal", H.heal)
    go("stiffness", function()
        local parts = p:getBodyDamage():getBodyParts()
        for k = 0, parts:size() - 1 do if S.stiff[k] then parts:get(k):setStiffness(S.stiff[k]) end end
    end)
    go("zone paint", function() p:resetSelectedZonesForHighlight(); p:setSeeDesignationZone(S.see0 == true) end)
    go("instant actions", function() p:setTimedActionInstantCheat(S.instant == true) end)
    return bad
end
function H.backCheats()
    local p = S.p
    S.guard = false
    Events.OnTick.Remove(H.keepTick)
    p:setInvincible(S.inv == true)
    p:setGodMod(S.god == true)
end
function H.leftovers()
    local left = {}
    if S.zombie then left[#left + 1] = "the zombie" end
    if S.hutchSq and H.objOn(S.hutchSq, "IsoHutch") then left[#left + 1] = "the hen house" end
    if S.cfSq and H.campLua(S.cfSq) then left[#left + 1] = "the campfire" end
    for _, a in ipairs(H.cellAnimals()) do
        local md = a:getModData()
        if S.mine[a] or (md ~= nil and md.ZeDQA_spawned == true) then left[#left + 1] = "a " .. tostring(a:getAnimalType()) end
    end
    for _, z in ipairs(S.zones) do if H.zoneLives(z) then left[#left + 1] = "the zone " .. tostring(z:getName()) end end
    if H.zoneCount() ~= S.zones0 then left[#left + 1] = "animal zones " .. tostring(S.zones0) .. " -> " .. H.zoneCount() end
    local all = S.p:getInventory():getAllEvalRecurse(function(it) return true end)
    for k = 0, all:size() - 1 do
        if not S.had[all:get(k)] then left[#left + 1] = "carried " .. tostring(all:get(k):getFullType()) end
    end
    return left
end

Q.mark()
Q.step(5, function()
    H.unswapAll()
    if not S.staged then return end
    if ZEDQA_SPEED then pcall(ZEDQA_SPEED, 1) elseif getGameSpeed() ~= 1 then pcall(setGameSpeed, 1) end
    H.stop()
    local okW, e1 = pcall(H.backWindows)
    if not okW then Q.check(false, "put back: the windows", e1) end
end)
Q.step(10, function()
    if not S.staged then return end
    local okN, n = pcall(H.backWorld)
    if not okN then Q.check(false, "put back: the world", n); n = {} end
    local okI, swept = pcall(H.backItems)
    if not okI then Q.check(false, "put back: the character's things", swept) end
    Q.say("put back: zombie " .. tostring(n.zombie) .. ", hen house " .. tostring(n.hutch) .. ", campfire " .. tostring(n.fire) .. ", animals " .. tostring(n.animals)
        .. ", zones " .. tostring(n.zones) .. ", things lying on the staged ground " .. tostring(n.swept) .. "; new things taken off the character " .. tostring(swept))
end)
Q.waitMs(700)
Q.step(2, function()
    if not S.staged then return end
    -- (a second pass: whatever the first could not take while something was still settling)
    pcall(H.backWorld)
    pcall(H.backItems)
    -- (a check that throws must not keep him from going home: they run in a pcall)
    local okQ, eQ = pcall(function()
        local okL, left = pcall(H.leftovers)
        Q.check(okL and #left == 0, "put back: nothing staged is left at the farm or on the character", okL and table.concat(left, ", ") or tostring(left))
        Q.check(H.idle() and getGameSpeed() == 1, "put back: nothing queued, game speed 1", "queue " .. H.qn() .. ", speed " .. tostring(getGameSpeed()))
        Q.check(ISWorldObjectContextMenu.disableWorldMenu ~= true, "put back: the world menu is on", tostring(ISWorldObjectContextMenu.disableWorldMenu))
    end)
    if not okQ then Q.check(false, "put back: the leftovers, the queue, the speed and the world menu could be read", eQ) end
    -- the windows' roll-up timers run again, the character home (the tick still holds god mode and invincible)
    S.holdOn = false
    for _, w in ipairs({ RT.ww() or false, RT.cw() or false }) do if w then w._outSince = nil end end
    if S.opened then pcall(RT.pairShut) end
    H.put(S.home.x, S.home.y)
    if ZEDQA_HOME then pcall(ZEDQA_HOME, Q.tag) end
end)
Q.waitMs(1500)
Q.step(2, function()
    if not (S.staged or S.guard) then return end
    local p = S.p
    local home = S.home ~= nil and math.abs(p:getX() - S.home.x) <= 3 and math.abs(p:getY() - S.home.y) <= 3
    Q.check(home, "put back: the character is home on the drag strip", math.floor(p:getX()) .. "," .. math.floor(p:getY()))
    -- the body while god mode and invincible are still on: healed, stiffness, zone paint, instant actions as found
    local okB, bad = pcall(H.backBody)
    if not (okB and #bad == 0) then Q.check(false, "put back: the heal, the stiffness, the zone paint and the instant-action cheat", okB and table.concat(bad, "; ") or tostring(bad)) end
    -- still hurt: healed again (a heal clears the stiffness just set as found, so only when needed)
    local okP, pre = pcall(H.hurt)
    if not okP or pre ~= "" then
        Q.say("still hurt after the put-back's heal (" .. tostring(pre) .. "): healed again")
        local okH, eH = pcall(H.heal)
        if not okH then Q.say("the heal threw: " .. tostring(eH)); pcall(function() p:getBodyDamage():RestoreToFullHealth() end) end
    end
    local okS, hurt = pcall(H.hurt)
    if home and okS and hurt == "" then
        local okC, eC = pcall(H.backCheats)
        if not okC then Q.check(false, "put back: god mode and invincible", eC) end
    else
        -- (not home, or not whole: he keeps god mode and invincible, the safe way to be left; the tick stops here so
        -- it cannot fight a later script that sets the two itself)
        pcall(H.safe)
        S.guard = false
        pcall(Events.OnTick.Remove, H.keepTick)
        Q.say("god mode and invincible are LEFT ON: the character is not home or not whole")
    end
    Q.check(okS and hurt == "", "put back: the character is alive and healed (health 100, no wound, no fracture, not infected)",
        okS and (hurt == "" and "whole" or hurt) or tostring(hurt))
    Q.check(p:isGodMod() == S.god and p:isInvincible() == S.inv and p:isTimedActionInstantCheat() == (S.instant == true)
            and p:isSeeDesignationZone() == (S.see0 == true),
        "put back: god mode, invincible, instant actions and the zone paint read as found",
        tostring(p:isGodMod()) .. " " .. tostring(p:isInvincible()) .. " " .. tostring(p:isTimedActionInstantCheat()) .. " " .. tostring(p:isSeeDesignationZone()))
    Q.check(getMouseX ~= nil and getCell ~= nil and S.swaps.mouse == nil and S.swaps.cell == nil and S.swaps.si == nil
            and S.swaps.scan == nil and S.swaps.dur == nil and S.swaps.refresh == nil and S.swaps.xp == nil,
        "put back: every function the script swapped is given back", "one is still swapped")
    RT.bounds(Q, "the end")
end)
Q.start()
