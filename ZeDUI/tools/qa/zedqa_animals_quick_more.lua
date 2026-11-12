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
local O = { opened = false }
local _p0 = getPlayer()
local HOME = { _p0:getX(), _p0:getY() }
   -- (16 squares west on the strip, clear of the farm animals; back at the end)

local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function waitFor(maxMs, cond, what)
    local tEnd
    plan[#plan + 1] = { ms = 0, wait = true, fn = function()
        tEnd = tEnd or (getTimestampMs() + maxMs)
        if cond() then say("waited for " .. what); tEnd = nil; return true end
        if getTimestampMs() > tEnd then say("gave up waiting for " .. what); tEnd = nil; return true end
        return false
    end }
end
local function breedOf(kind) local def = AnimalDefinitions.getDef(kind); return def and def:getBreeds():get(0) end
local function dropAll(full)
    local list = p:getInventory():getAllTypeRecurse(full)
    for k = list:size() - 1, 0, -1 do local it = list:get(k); local c = it:getContainer(); if c then c:Remove(it) end end
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
    for _, t in ipairs({ "Bucket", "BucketEmpty", "BucketForged", "BucketWood", "BucketLargeWood", "BucketCarved",
                         "SheepShears", "SheepElectricShears", "SheepShearsForged" }) do pcall(dropAll, t) end
    local px, py = math.floor(p:getX()) - 16, math.floor(p:getY())
    A.c1 = addAnimal(getCell(), px + 3, py + 2, 0, "cow", breedOf("cow"))
    A.c2 = addAnimal(getCell(), px + 4, py - 2, 0, "cow", breedOf("cow"))
    A.ewe = addAnimal(getCell(), px - 3, py + 2, 0, "ewe", breedOf("ewe"))
    A.hungry = addAnimal(getCell(), px - 4, py - 3, 0, "cow", breedOf("cow"))
    for _, c in ipairs({ A.c1, A.c2 }) do pcall(function() c:getData():setMaxMilkActual(6); c:getData():setMilkQuantity(8) end) end
    pcall(function() A.ewe:getData():setWoolQuantity(5, true) end)
    pcall(function() A.hungry:getStats():set(CharacterStat.HUNGER, 0.9) end)
    pcall(function() A.hungry:getData():setMilkQuantity(0) end)
    local ok, err = pcall(function() DesignationZoneAnimal.new(ZONE, px - 8, py - 8, 0, px + 8, py + 8, true) end)
    -- (a milking container the script's list missed would keep Milk live: find what the game would use and put it aside for the run)
    pcall(function()
        local okM, whyM, toolM = ZeD.AnimalsQuick.can("milk", p, A.c1)
        say("milk tool before: " .. tostring(okM) .. " " .. tostring(whyM) .. " " .. tostring(toolM and toolM.getFullType and toolM:getFullType()))
        if okM and toolM and toolM.getContainer and toolM:getContainer() then
            ASIDE = { item = toolM, cont = toolM:getContainer() }
            ASIDE.cont:Remove(toolM)
            ZeD.AnimalsQuick.forgetChecks()
            local ok2, why2 = ZeD.AnimalsQuick.can("milk", p, A.c1)
            say("milk tool put aside (" .. tostring(toolM:getFullType()) .. "); now " .. tostring(ok2) .. " " .. tostring(why2))
        end
    end)    say("animals " .. tostring(A.c1 ~= nil) .. tostring(A.c2 ~= nil) .. tostring(A.ewe ~= nil) .. tostring(A.hungry ~= nil) .. " zone ok=" .. tostring(ok) .. " " .. tostring(err or ""))
end)
add(1500, function()
    AP.refreshCache()
    if not CWm.isOpen() then O.opened = true; CWm.toggleBothPaired(0) end
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
    local want = ZeD.tr("UI_ZeD_Animals_NeedBucket")
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
    check(r ~= nil and r.why == ZeD.tr("UI_ZeD_Animals_NeedBucket"), "b the pad's focus on greyed Milk: the balloon asks at once with the reason", r and r.why)
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
    p:getInventory():AddItem("Base.Bucket"); p:getInventory():AddItem("Base.SheepShears")
    AQ.forgetChecks()
end)
add(1200, function()
    local b = bulk("milk")
    check(b ~= nil and not b.disabled, "c with a bucket, Milk (2) is live", b and tostring(b.disabled))
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
    end
    return false
end, "the two-cow milking run")
add(500, function()
    check(V.seen2, "d the run reached the second cow")
    check(V.seen2 and V.doneAtHandover == 1 and V.c1Milk == false, "d the second cow was handed over only when the first was done (done " .. tostring(V.doneAtHandover) .. ", first cow still has milk: " .. tostring(V.c1Milk) .. ")")
    check(not V.multi, "d never two milkings queued at once")
    check(AQ.last ~= nil and AQ.last.why == ZeD.tr("UI_ZeD_Animals_RunDone", 2, 2), "d the run ended Done 2 of 2", AQ.last and AQ.last.why)
    check(queueNames() == "", "d nothing left in the queue", queueNames())
end)

-- e  walking away mid-milking
add(300, function()
    for _, c in ipairs({ A.c1, A.c2 }) do pcall(function() c:getData():setMilkQuantity(8) end) end
    AQ.forgetChecks()
    AT.bulkPress(W(), "milkable")
end)
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
    check(queueNames() == "" and not ISTimedActionQueue.isPlayerDoingAction(p), "e nothing is left queued or running", queueNames())
    local held = {}
    for k, c in pairs({ c1 = A.c1, c2 = A.c2, ewe = A.ewe, hungry = A.hungry }) do
        local b = nil
        pcall(function() b = c:getBehavior() end)
        local blocked = nil
        if b then pcall(function() blocked = b:isBlockMovement() end) end
        if blocked == true then held[#held + 1] = k end
        say("animal " .. k .. " blockMovement " .. tostring(blocked))
    end
    check(#held == 0, "e no animal is held still", table.concat(held, ","))
    p:setX(O.px); p:setY(O.py); p:setLastX(O.px); p:setLastY(O.py)
    pcall(function() ISTimedActionQueue.clear(p) end)
    shot("6_after_walk_away")
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

-- the end: everything made taken away
add(2000, function()
    Det.setLockedMode(nil)
    pcall(O.undoReq); pcall(O.undoMouse)
    for _, t in ipairs({ "Bucket", "SheepShears" }) do pcall(dropAll, t) end
    for _, a in ipairs({ A.c1, A.c2, A.ewe, A.hungry }) do pcall(function() a:removeFromWorld(); a:removeFromSquare() end) end
    pcall(function() local z = DesignationZoneAnimal.getZoneByName(ZONE); if z then DesignationZoneAnimal.removeZone(z, true) end end)
    p:setGodMod(false)
    pcall(function() if ASIDE then ASIDE.cont:AddItem(ASIDE.item) end end)
    if O.opened then pcall(CWm.toggleBothPaired, 0) end
    say("fails " .. fails)
    say("DONE")
end)

local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if st.wait then
        local ok, done = pcall(st.fn)
        if not ok then say("ERR wait " .. i .. ": " .. tostring(done)); done = true end
        if done then i = i + 1; t0 = getTimestampMs() end
        return
    end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
say("start")
