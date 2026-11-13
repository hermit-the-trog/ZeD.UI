-- ZeDUI/tools/qa/zedqa_animals_quick_more.lua  (Nov 11 2026, QA, punch list 169): the checks zedqa_animals_quick.lua leaves out.
-- QA save only (Saves/Sandbox/ZeD-QA), the character on open ground. grep console.txt for "ZEDQA aq2". Pictures zqa_aq2_*.png.
-- Run at 4K 1.75x, at the Deck (1280x800, Auto) and in German (options.ini language=DE) at 4K; each run also switches to Large text.
--   a  two milk cows, an ewe and a hungry cow, a zone over them, no bucket and no shears
--   b  greyed buttons say why: with the pointer (ZeD.Atoms.mouseIn answered true for the button: the pointer is stood in for)
--      and with the pad (focus on the stop): the balloon is asked for with the reason, at once for the pad
--   c  the pad: A on All milkable puts the focus on Clear; A on Clear on All hungry; A on Milk (n) on Stop
--   d  a milking run over two cows: the second is handed to the game only when the first is done
--   e  a run with the player walked away mid-milking: it stops, nothing left queued, no animal held still
--   f  the band at the zone view: All hungry, All milkable, Rename and Remove zone in one row, at the run's text size and at Large
-- THE LEDGER: everything the script gives, takes or makes is written down and put back at the end, and at once on an error
-- (given items taken away, set-aside items given back where they were, animals and zone removed, god mode and hands as they
-- were). Its animals and items carry the mod-data mark ZeDQA_spawned, which zedqa_animals_restore.lua looks for.
local function say(s) print("ZEDQA aq2 " .. tostring(s)) end
local fails = 0
local function check(ok, what, extra) if not ok then fails = fails + 1 end; say((ok and "PASS " or "FAIL ") .. what .. (extra ~= nil and (" | " .. tostring(extra)) or "")) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_aq2_" .. n .. ".png") end) end
local p = getPlayer()
local Focus, Det = ZeD.Input.Focus, ZeD.Input.Detector
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local AT, AQ, AP = ZeD.AnimalsTab, ZeD.AnimalsQuick, ZeD.AnimalsAlertPoller
local function W() return WWm.getWindow() end
local ZONE = "QA Quick2"
local A = {}
local O = {}
local HOME = { p:getX(), p:getY() }
   -- (16 squares west on the strip, clear of the farm animals; back at the end)

-- FAST-FORWARD (Nov 12 2026). The game's walk actions are valid only at speed 2 or below (WalkToTimedAction:isValid: getGameSpeed() <= 2),
-- so a walk queued at speed 3 is cut at once, and the game's own option puts the speed back to 1 whenever an action ends. A fast wait
-- therefore sets the speed again every tick: 3 while only a non-walk action runs, 2 while the queue is empty or holds a walk; and a
-- hook on ISTimedActionQueue.add drops the speed to 2 at the moment a walk is queued (AQ hands the walk over between two ticks).
-- Speed is 1 again when the wait ends, when the script ends and on an error (restore).
local FF = { add = ISTimedActionQueue.add, on = false, c2 = 0, c3 = 0, t0 = 0 }
ISTimedActionQueue.add = function(action, ...)
    if FF.on and action and tostring(action.Type):find("Walk", 1, true) and getGameSpeed() > 2 then setGameSpeed(2) end
    return FF.add(action, ...)
end
local function ffSpeed()
    local q = ISTimedActionQueue.queues[getPlayer()]
    local walk, n = false, 0
    for _, a in ipairs(q and q.queue or {}) do n = n + 1; if tostring(a.Type):find("Walk", 1, true) then walk = true end end
    local want = (n == 0 or walk) and 2 or 3
    if getGameSpeed() ~= want then setGameSpeed(want) end
    if want == 3 then FF.c3 = FF.c3 + 1 else FF.c2 = FF.c2 + 1 end
end

-- THE LEDGER ------------------------------------------------------------------------------------------------------
local MARK = "ZeDQA_spawned"
local LG = { added = {}, taken = {}, animals = {}, zones = {}, done = false, god = false,
             primary = p:getPrimaryHandItem(), secondary = p:getSecondaryHandItem(), opened = false }
pcall(function() LG.god = p:isGodMod() == true end)
local function mark(o) pcall(function() o:getModData()[MARK] = true end) end
local function give(full, cont)
    local it = (cont or p:getInventory()):AddItem(full)
    if it then mark(it); LG.added[#LG.added + 1] = it end
    return it
end
local function takeOne(it)
    local c = it and it:getContainer()
    if not c then return end
    pcall(function() p:removeFromHands(it) end)
    c:Remove(it)
    LG.taken[#LG.taken + 1] = { item = it, cont = c }
end
local function takeType(full)
    local list = p:getInventory():getAllTypeRecurse(full)
    for k = list:size() - 1, 0, -1 do takeOne(list:get(k)) end
end
-- everything carried that passes test(item), the bags too
local function takeWhere(test)
    local list = p:getInventory():getAllEvalRecurse(function(it) return test(it) == true end)
    for k = list:size() - 1, 0, -1 do takeOne(list:get(k)) end
    return list:size()
end
local function breedOf(kind)
    local def = AnimalDefinitions.getDef(kind)
    return def and def:getBreeds():get(0)
end
-- A square for an animal near (x, y): open floor with a free square beside it the character can walk to. The drag
-- strip has rails, a trailer and fences; a cow made where nothing beside it is free can never be milked (the game's
-- walk to its side fails and the milking ends at once).
local function openSquare(x, y)
    for r = 0, 5 do
        for dy = -r, r do
            for dx = -r, r do
                if math.max(math.abs(dx), math.abs(dy)) == r then
                    local ok, good = pcall(function()
                        local sq = getCell():getGridSquare(x + dx, y + dy, 0)
                        return sq ~= nil and sq:isFree(false) and AdjacentFreeTileFinder.Find(sq, p) ~= nil
                    end)
                    if ok and good then return x + dx, y + dy end
                end
            end
        end
    end
    say("no open square near " .. x .. "," .. y .. ": the animal goes there anyway")
    return x, y
end
local function spawn(kind, x, y)
    local sx, sy = openSquare(x, y)
    local a = addAnimal(getCell(), sx, sy, 0, kind, breedOf(kind))
    if a then mark(a); LG.animals[#LG.animals + 1] = a; pcall(function() a:setDebugStress(0) end) end
    say("made a " .. kind .. " at " .. sx .. "," .. sy .. (a and "" or " (failed)"))
    return a
end
-- the stops are read straight from w._focusRing: keep them fresh while the mouse is the input (put back at the end)
LG.freshWas = ZEDQA_FRESH_STOPS
ZEDQA_FRESH_STOPS = true
local function makeZone(name, x1, y1, x2, y2)
    LG.zones[#LG.zones + 1] = name
    return pcall(function() DesignationZoneAnimal.new(name, x1, y1, 0, x2, y2, true) end)
end
local function emptyGiven()
    for _, it in ipairs(LG.added) do pcall(function() local fc = it:getFluidContainer(); if fc then fc:Empty() end end) end
end
local function restore(why)
    if LG.done then return end
    LG.done = true
    FF.on = false
    pcall(function() ISTimedActionQueue.add = FF.add end)
    pcall(function() if setGameSpeed then setGameSpeed(1) end end)   -- (fast-forward off, also on an error)
    pcall(function() AQ.stop() end)
    pcall(function() ISTimedActionQueue.clear(p) end)
    pcall(function() local m = AT._feedMenu; if m then m:close() end end)
    pcall(function() Det.setLockedMode(nil) end)
    local gone, back, freed, zones = 0, 0, 0, 0
    -- (newest first: the carrot in the bag goes before the bag)
    for k = #LG.added, 1, -1 do
        local it = LG.added[k]
        pcall(function()
            local c = it:getContainer()
            if c then pcall(function() p:removeFromHands(it) end); c:Remove(it); gone = gone + 1 end
        end)
    end
    for _, t in ipairs(LG.taken) do
        pcall(function() if not t.item:getContainer() then t.cont:AddItem(t.item); back = back + 1 end end)
    end
    for _, a in ipairs(LG.animals) do pcall(function() a:removeFromWorld(); a:removeFromSquare(); freed = freed + 1 end) end
    for _, name in ipairs(LG.zones) do
        for _ = 1, 4 do
            pcall(function() local z = DesignationZoneAnimal.getZoneByName(name); if z then DesignationZoneAnimal.removeZone(z, true); zones = zones + 1 end end)
        end
    end
    pcall(function() if LG.primary and p:getInventory():contains(LG.primary) then p:setPrimaryHandItem(LG.primary) end end)
    pcall(function() if LG.secondary and p:getInventory():contains(LG.secondary) then p:setSecondaryHandItem(LG.secondary) end end)
    pcall(function() p:setGodMod(LG.god) end)
    ZEDQA_FRESH_STOPS = LG.freshWas
    pcall(function() p:setX(HOME[1]); p:setY(HOME[2]); p:setLastX(HOME[1]); p:setLastY(HOME[2]) end)
    pcall(function() AP.refreshCache() end)
    pcall(function() if LG.opened and CWm.isOpen() then CWm.toggleBothPaired(0) end end)
    say("restored (" .. tostring(why) .. "): given and taken back " .. gone .. ", set aside and given back " .. back .. " of "
        .. #LG.taken .. ", animals removed " .. freed .. " of " .. #LG.animals .. ", zones removed " .. zones)
end


local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
-- Fast-forward (Nov 12 2026): a wait for a timed action runs at the game's speed 3 ("faster") while it waits and is back at 1
-- when it ends (done, timed out, or the step failed: drive() and restore() also set 1). The cap maxMs stays real time and
-- generous. Checks about real-time behavior (e: the player walked off mid-action) and the shots stay at speed 1.
local function setSpeed(n) pcall(function() if setGameSpeed then setGameSpeed(n) end end) end
local function waitFor(maxMs, cond, what, fast)
    local tEnd
    plan[#plan + 1] = { ms = 0, wait = true, fn = function()
        if not tEnd then tEnd = getTimestampMs() + maxMs; FF.on = fast == true; FF.c2, FF.c3, FF.t0 = 0, 0, getTimestampMs() end
        if cond() then say("waited for " .. what .. (fast and string.format(" (%d s; ticks at speed 2: %d, at 3: %d)", (getTimestampMs() - FF.t0) / 1000, FF.c2, FF.c3) or "")); tEnd = nil; FF.on = false; setSpeed(1); return true end
        if getTimestampMs() > tEnd then say("gave up waiting for " .. what); tEnd = nil; FF.on = false; setSpeed(1); return true end
        if FF.on then pcall(ffSpeed) end
        return false
    end }
end
local function queueNames()
    local q = ISTimedActionQueue.queues[p]
    local t = {}
    for _, a in ipairs(q and q.queue or {}) do t[#t + 1] = tostring(a.Type) end
    return table.concat(t, ",")
end
local function bulk(id) for _, b in ipairs(W()._animalsBulkBtns or {}) do if b.id == id then return b end end end
local function ringFind(id)
    for _, z in ipairs(W()._focusRing or {}) do
        for _, e in ipairs(z.elements or {}) do if e.id == id then return z, e end end
    end
end
local function focusId() local e = Focus.getFocusedElement(W()); return e and e.id end
local function focusOn(id)
    local z = ringFind(id)
    if z then Focus.focusWhere(W(), z.zone, function(e) return e.id == id end) end
end
local function sel() return AT.getZoneViewState(W()).sel end

-- the balloon requests: what the band asked to show, with its words
local Req = { log = {} }
do
    local At = ZeD.Atoms
    local orig = At.requestDetailCard
    At.requestDetailCard = function(win, key, card, panel, rect, opts)
        Req.log[#Req.log + 1] = { key = tostring(key), why = card and card._why, now = opts and opts.now or false }
        return orig(win, key, card, panel, rect, opts)
    end
    O.undoReq = function() At.requestDetailCard = orig end
    local mi = At.mouseIn
    Req.mouseOn = nil
    At.mouseIn = function(panel, x, y, w, h)
        local r = Req.mouseOn
        if r and x == r.x and y == r.y and w == r.w and h == r.h then return true end
        return mi(panel, x, y, w, h)
    end
    O.undoMouse = function() At.mouseIn = mi end
end
local function reqFor(key, now)
    for k = #Req.log, 1, -1 do
        local r = Req.log[k]
        if r.key == key and r.why ~= nil and (now == nil or r.now == now) then return r end
    end
end

-- f: the band's fit, at the run's text size
local function fit(tag)
    local w = W()
    local ids = { "hungry", "milkable" }
    local rects, names = {}, {}
    for _, id in ipairs(ids) do local b = bulk(id); if b then rects[#rects + 1] = b; names[#names + 1] = id end end
    if w._animalsZoneRenameBtn then rects[#rects + 1] = w._animalsZoneRenameBtn; names[#names + 1] = "rename" end
    if w._animalsZoneRemoveBtn then rects[#rects + 1] = w._animalsZoneRemoveBtn; names[#names + 1] = "remove" end
    local parts, sameRow, noOverlap, inside = {}, true, true, true
    local ww = w:getWidth()
    for k, r in ipairs(rects) do
        parts[#parts + 1] = string.format("%s %d,%d %dx%d", names[k], r.x, r.y, r.w, r.h)
        if math.abs(r.y - rects[1].y) > 4 then sameRow = false end
        if r.x + r.w > ww then inside = false end
        for m = k + 1, #rects do
            local s = rects[m]
            if r.x < s.x + s.w and s.x < r.x + r.w and r.y < s.y + s.h and s.y < r.y + r.h then noOverlap = false end
        end
    end
    say("band (" .. tag .. "): " .. table.concat(parts, "; ") .. "; window width " .. ww)
    check(#rects == 4, "f " .. tag .. ": All hungry, All milkable, Rename and Remove zone are all in the band", table.concat(names, ","))
    check(sameRow and noOverlap and inside, "f " .. tag .. ": they sit in one row, apart, inside the window")
end

-- a  the animals
add(4000, function()
    p:setGodMod(true)
    for _, t in ipairs({ "SheepShears", "SheepElectricShears", "SheepShearsForged" }) do pcall(takeType, "Base." .. t) end
    local px, py = math.floor(p:getX()) - 16, math.floor(p:getY())
    A.c1 = spawn("cow", px + 3, py + 2)
    A.c2 = spawn("cow", px + 4, py - 2)
    for _, c in ipairs({ A.c1, A.c2 }) do O[c] = { c:getX(), c:getY() } end
    -- (a ram, not an ewe: an ewe gives milk too and would join All milkable)
    A.ewe = spawn("ram", px - 3, py + 2)
    A.hungry = spawn("cow", px - 4, py - 3)
    -- (4 L each: both fit the one 10 L bucket, so the run can milk both dry)
    for _, c in ipairs({ A.c1, A.c2 }) do pcall(function() c:getData():setMaxMilkActual(6); c:getData():setMilkQuantity(4) end) end
    pcall(function() A.ewe:getData():setWoolQuantity(5, true) end)
    pcall(function() A.hungry:getStats():set(CharacterStat.HUNGER, 0.9) end)
    pcall(function() A.hungry:getData():setMilkQuantity(0) end)
    local ok, err = makeZone(ZONE, px - 8, py - 8, px + 8, py + 8)
    -- (the game's milk rule takes any empty container or one holding this milk, in the main inventory: all set aside)
    local mt = A.c1 and A.c1:getData():getBreed():getMilkType()
    local nMilk = 0
    for _ = 1, 40 do
        local list = mt and p:getInventory():getAvailableFluidContainer(mt)
        if not list or list:isEmpty() then break end
        takeOne(list:get(0)); nMilk = nMilk + 1
    end
    AQ.forgetChecks()
    say("milk containers set aside: " .. nMilk)
    say("animals " .. tostring(A.c1 ~= nil) .. tostring(A.c2 ~= nil) .. tostring(A.ewe ~= nil) .. tostring(A.hungry ~= nil) .. " zone ok=" .. tostring(ok) .. " " .. tostring(err or ""))
end)
add(1500, function()
    AP.refreshCache()
    if not CWm.isOpen() then LG.opened = true; CWm.toggleBothPaired(0) end
end)
add(1500, function()
    local w = W(); w._activeTab = "animals"; w._drawerMode = "tab"; w._drawerOpen = true
    AT.getState(w).submode = "ranch"; AT.getState(w).view = "overview"
    AP.refreshCache()
    AT.navigate(w, "zone", ZONE, nil)
end)
add(1200, function() fit("zone view, nothing ticked, normal text"); shot("1_band_normal") end)

-- b  greyed with the reason: pointer and pad
add(300, function() AT.bulkPress(W(), "milkable") end)
add(1200, function()
    local b = bulk("milk")
    check(b ~= nil and b.disabled == true, "b with two milk cows ticked and no bucket, Milk (2) is greyed", b and tostring(b.disabled))
    if b then Req.mouseOn = { x = b.x, y = b.y, w = b.w, h = b.h } end
    Req.log = {}
end)
add(1200, function()
    local r = reqFor("animals:bulk:milk", false)
    local want = ZeD.tr("UI_ZeD_Animals_NeedMilkContainer")
    check(r ~= nil and r.why == want, "b the pointer on greyed Milk: the balloon asks to show '" .. tostring(want) .. "'", r and r.why)
    shot("2_hover_why")
    Req.mouseOn = nil; Req.log = {}
    Det.setLockedMode(Det.MODE_GAMEPAD)
    Focus.claimFocus(W())
end)
add(900, function() focusOn("animals:bulk:milk") end)
add(1200, function()
    local r = reqFor("animals:bulk:milk", true)
    check(focusId() == "animals:bulk:milk", "b the pad's focus is on greyed Milk", focusId())
    check(r ~= nil and r.why == ZeD.tr("UI_ZeD_Animals_NeedMilkContainer"), "b the pad's focus on greyed Milk: the balloon asks at once with the reason", r and r.why)
    shot("3_pad_why")
    local z, e = ringFind("animals:bulk:milk")
    check(e ~= nil and e.onActivate ~= nil, "b the greyed button is still a stop (A on it does nothing)")
    if e and e.onActivate then pcall(e.onActivate, W(), e) end
    check(AQ.run == nil, "b A on the greyed Milk starts nothing")
end)

-- c  the pad: focus follows the band
add(300, function() focusOn("animals:bulk:clear") end)
add(600, function()
    local z, e = ringFind("animals:bulk:clear")
    check(e ~= nil, "c with ticks, Clear is a stop")
    if e and e.onActivate then e.onActivate(W(), e) end   -- Clear -> the picks band
end)
add(1500, function()
    check(focusId() == "animals:bulk:hungry", "c A on Clear: the focus lands on All hungry, which takes its place", focusId())
    focusOn("animals:bulk:milkable")
end)
add(600, function()
    local z, e = ringFind("animals:bulk:milkable")
    if e and e.onActivate then e.onActivate(W(), e) end
end)
add(1500, function()
    check(focusId() == "animals:bulk:clear", "c A on All milkable: the focus lands on Clear", focusId())
    shot("4_pad_after_milkable")
    give("Base.Bucket"); give("Base.SheepShears")
    AQ.forgetChecks()
end)
add(1200, function()
    local b = bulk("milk")
    check(b ~= nil and not b.disabled, "c with a bucket, Milk (2) is live", b and (tostring(b.disabled) .. " " .. tostring(b.why)))
    focusOn("animals:bulk:milk")
end)
add(500, function()
    local z, e = ringFind("animals:bulk:milk")
    if e and e.onActivate then e.onActivate(W(), e) end
end)
add(1500, function()
    check(AQ.run ~= nil and AQ.run.verb == "milk", "c A on Milk (2) starts the run", AQ.runStatus())
    check(focusId() == "animals:bulk:stop", "c A on Milk: the focus lands on Stop, which takes its place", focusId())
    shot("5_pad_run")
end)

-- d  the hand-over: the second cow only when the first is done
local V = { maxI2WhileC1 = false, multi = false, samples = 0, doneAtHandover = nil, seen2 = false }
waitFor(120000, function()
    local r = AQ.run
    V.samples = V.samples + 1
    if not r then return true end
    local q = queueNames()
    local _, n = q:gsub("ISMilkAnimal", "")
    if n > 1 then V.multi = true end
    if r.i == 2 and not V.seen2 then
        V.seen2 = true
        V.doneAtHandover = r.done
        V.c1Milk = AQ.hasMilk(A.c1)
        -- (the game makes milk with game time: at speed 3 a cow just milked dry can read a hair above the 0.1 L the game
        -- counts as "has milk" a tick later, so the first cow is judged by what is left in her, a quarter litre at most)
        V.c1Q = A.c1:getData():getMilkQuantity()
    end
    return false
end, "the two-cow milking run", true)
add(500, function()
    check(V.seen2, "d the run reached the second cow")
    check(V.seen2 and V.doneAtHandover == 1 and (V.c1Milk == false or (V.c1Q or 9) < 0.25), "d the second cow was handed over only when the first was done (done " .. tostring(V.doneAtHandover) .. ", first cow still has milk: " .. tostring(V.c1Milk) .. ", " .. string.format("%.2f", V.c1Q or -1) .. " L left)")
    check(not V.multi, "d never two milkings queued at once")
    say("d the run ended: " .. tostring(AQ.last and AQ.last.why) .. " | cause " .. tostring(AQ.last and AQ.last.cause))
    check(AQ.last ~= nil and AQ.last.why == ZeD.tr("UI_ZeD_Animals_RunDone", 2, 2), "d the run ended Done 2 of 2", AQ.last and AQ.last.why)
    check(queueNames() == "", "d nothing left in the queue", queueNames())
end)

-- (the cows graze and wander while the game runs fast: put them back on their squares before a run that needs them in the zone)
local function cowsHome()
    for _, c in ipairs({ A.c1, A.c2 }) do
        local h = O[c]
        if h then pcall(function() c:setX(h[1]); c:setY(h[2]); c:setLastX(h[1]); c:setLastY(h[2]) end) end
    end
end
-- e  walking away mid-milking. Kept at speed 1 on purpose: it is about real-time behavior (the run's reaction to the player
--    being moved off while the milking is under way).
add(300, function()
    emptyGiven()
    cowsHome()
    for _, c in ipairs({ A.c1, A.c2 }) do pcall(function() c:getData():setMilkQuantity(4) end) end
    AQ.forgetChecks()
    if bulk("clear") then AT.bulkPress(W(), "clear") end
end)
add(900, function() AT.bulkPress(W(), "milkable") end)
add(900, function() AT.bulkPress(W(), "milk") end)
waitFor(30000, function() return AQ.run ~= nil and queueNames():find("ISMilkAnimal") ~= nil end, "the milking to start")
add(1500, function()
    E = { q = queueNames(), status = AQ.runStatus() }
    say("walking away from: " .. tostring(E.q) .. " / " .. tostring(E.status))
    O.px, O.py = p:getX(), p:getY()
    local nx, ny = O.px + 16, O.py + 16
    p:setX(nx); p:setY(ny); p:setLastX(nx); p:setLastY(ny)
end)
waitFor(20000, function() return AQ.run == nil end, "the run to stop after the walk")
add(1500, function()
    check(AQ.run == nil, "e walking away: the run is over")
    check(AQ.last ~= nil and AQ.last.verb == "milk", "e it says how it ended", AQ.last and AQ.last.why)
    check(AQ.last ~= nil and AQ.last.cause == "away", "e it ended because the player was moved off", AQ.last and AQ.last.cause)
    check(queueNames() == "" and not ISTimedActionQueue.isPlayerDoingAction(p), "e nothing is left queued or running", queueNames())
    local held = {}
    for k, c in pairs({ c1 = A.c1, c2 = A.c2, ewe = A.ewe, hungry = A.hungry }) do
        local b = nil
        pcall(function() b = c:getBehavior() end)
        -- (the behaviour has no getter for its hold, and a call to one that is not there is what logged "Object
        -- tried to call nil" four times: read the field, as the game's debug object viewer does; outside -debug
        -- the field reads are not there and this says nil)
        local blocked = nil
        if b and getNumClassFields and getClassField and getClassFieldVal then
            pcall(function()
                for f = 0, getNumClassFields(b) - 1 do
                    local fld = getClassField(b, f)
                    if tostring(fld):find("blockMovement", 1, true) then blocked = getClassFieldVal(b, fld) end
                end
            end)
        end
        if blocked == true then held[#held + 1] = k end
        say("animal " .. k .. " blockMovement " .. tostring(blocked))
    end
    check(#held == 0, "e no animal is held still", table.concat(held, ","))
    p:setX(O.px); p:setY(O.py); p:setLastX(O.px); p:setLastY(O.py)
    pcall(function() ISTimedActionQueue.clear(p) end)
    shot("6_after_walk_away")
end)

-- g  a full bucket (Build's request, Nov 12 2026): two milkable cows (4 L each) and the one bucket with room for 5 L: the first
--    cow fits, the second only partly, so the run ends "Bucket full: milked 1 of 2." and not Done. The words by the translated key.
--    (The bucket is the one this script gave, so zedqa_animals_restore.lua takes it away at the end: every given item carries
--    the ZeDQA_spawned mark; the other milk containers were set aside at a.)
local G = {}
add(300, function() pcall(function() AQ.stop() end); if bulk("clear") then AT.bulkPress(W(), "clear") end end)
add(900, function()
    emptyGiven()
    cowsHome()
    for _, c in ipairs({ A.c1, A.c2 }) do pcall(function() c:getData():setMilkQuantity(4) end) end
    AQ.forgetChecks()
    for _, it in ipairs(LG.added) do if it:getFullType() == "Base.Bucket" then G.bk = it end end
    local fc = G.bk and G.bk:getFluidContainer()
    local ok, err = pcall(function()
        local mt = A.c1:getData():getBreed():getMilkType()
        fc:Empty(); fc:addFluid(mt, math.max(0, fc:getCapacity() - 5))
    end)
    say("g bucket filled to " .. tostring(fc and fc:getAmount()) .. " of " .. tostring(fc and fc:getCapacity()) .. " ok=" .. tostring(ok) .. " " .. tostring(err or ""))
    AT.bulkPress(W(), "milkable")
end)
add(900, function() AT.bulkPress(W(), "milk") end)
waitFor(120000, function() return AQ.run == nil end, "the bucket-full run", true)
add(500, function()
    local fc = G.bk and G.bk:getFluidContainer()
    local want = ZeD.tr("UI_ZeD_Animals_RunFull", G.bk and G.bk:getDisplayName(), 1, 2)
    local done = ZeD.tr("UI_ZeD_Animals_RunDone", 2, 2)
    say("g the run ended: " .. tostring(AQ.last and AQ.last.why) .. " | cause " .. tostring(AQ.last and AQ.last.cause) .. " | want " .. tostring(want))
    check(AQ.last ~= nil and AQ.last.why == want, "g the run ends Bucket full: milked 1 of 2 (the translated key)", AQ.last and AQ.last.why)
    check(AQ.last ~= nil and AQ.last.why ~= done and AQ.last.cause ~= "done", "g it does not end Done", AQ.last and AQ.last.cause)
    check(fc ~= nil and fc:isFull(), "g the bucket is full")
    check(queueNames() == "", "g nothing left in the queue", queueNames())
    if bulk("clear") then AT.bulkPress(W(), "clear") end
end)

-- f  the band at Large text
add(800, function()
    pcall(function() AQ.stop() end)
    local zs = sel()
    AT.bulkPress(W(), "clear")
    local w = W()
    AT.navigate(w, "zone", ZONE, nil)
end)
add(1200, function() fit("zone view, normal text, again") end)
add(300, function()
    local opts = PZAPI and PZAPI.ModOptions and PZAPI.ModOptions:getOptions("ZeD_UI")
    local o = opts and opts:getOption("textSize")
    check(o ~= nil, "f the text size option is there")
    if o then pcall(function() O.size = o:getValue(); o:setValue(2); if o.onChangeApply then o:onChangeApply(2) else ZeD.Settings.reapplyFromOptions() end end) end
    say("text size now " .. tostring(ZeD.currentSize))
end)
add(2500, function() fit("zone view, Large text"); shot("7_band_large") end)
add(300, function()
    local opts = PZAPI and PZAPI.ModOptions and PZAPI.ModOptions:getOptions("ZeD_UI")
    local o = opts and opts:getOption("textSize")
    if o and O.size ~= nil then pcall(function() o:setValue(O.size); if o.onChangeApply then o:onChangeApply(O.size) else ZeD.Settings.reapplyFromOptions() end end) end
end)

-- the end: everything put back
add(2000, function()
    pcall(O.undoReq); pcall(O.undoMouse)
    restore("the end")
    say("fails " .. fails)
    say("DONE")
end)

local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if st.wait then
        local ok, done = pcall(st.fn)
        if not ok then say("ERR wait " .. i .. ": " .. tostring(done)); done = true; pcall(function() if setGameSpeed then setGameSpeed(1) end end) end
        if done then i = i + 1; t0 = getTimestampMs() end
        return
    end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then
        -- a failed step ends the run: put everything back first
        say("ERR step " .. (i - 1) .. ": " .. tostring(e))
        Events.OnTick.Remove(drive)
        pcall(O.undoReq); pcall(O.undoMouse)
        restore("an error")
        say("fails " .. (fails + 1))
        say("DONE")
    end
end
Events.OnTick.Add(drive)
say("start")
