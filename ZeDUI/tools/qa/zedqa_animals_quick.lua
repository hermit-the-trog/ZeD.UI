-- ZeDUI/tools/qa/zedqa_animals_quick.lua  (Nov 11 2026, Build): the Animals tab's quick actions and the roster's bulk
-- select in game, with real animals. QA save only (Saves/Sandbox/ZeD-QA), the character on open ground (the drag strip).
-- Copy to Zomboid/Lua/zedqa.lua, bump zedqa.go, grep console.txt for "ZEDQA aq". PASS / FAIL lines, ending DONE.
-- Screenshots/zqa_aq_*.png (take the set at 4K 1.75x and again at the Deck size; the script does not resize).
--   1  a cow with 8 L of milk, an ewe with 5 wool, a starving cow; a zone "QA Quick" over them; no bucket, no shears
--   2  the Ranch page: the cow's alert offers Milk greyed ("needs a bucket"), the ewe's Shear greyed ("needs shears"),
--      the starving cow's Walk to live
--   3  a bucket and sheep shears given: Milk and Shear live
--   4  Walk to: the game's walk is queued; Milk on the alert: the game's milking runs and the cow's milk goes down
--   5  the zone: All hungry ticks the starving cow, Clear, All milkable, X on a row (the ring's onContextMenu), the
--      band's Milk (n) starts a run ("Milking 1 of n"), it ends ("Done") or is stopped by Stop
--   6  the controller: the band's buttons and the alert rows are ring stops; A on a stop presses it
local function say(s) print("ZEDQA aq " .. tostring(s)) end
local fails = 0
local function check(ok, what, extra) if not ok then fails = fails + 1 end; say((ok and "PASS " or "FAIL ") .. what .. (extra ~= nil and (" | " .. tostring(extra)) or "")) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_aq_" .. n .. ".png") end) end
local p = getPlayer()
local Focus, Det = ZeD.Input.Focus, ZeD.Input.Detector
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local AT, AQ, AP = ZeD.AnimalsTab, ZeD.AnimalsQuick, ZeD.AnimalsAlertPoller
local function W() return WWm.getWindow() end
local ZONE = "QA Quick"
local A = {}   -- the animals: milk, wool, hungry

local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
-- wait (checking every 250 ms) until cond() or the time runs out, then go on
local function waitFor(maxMs, cond, what)
    local tEnd
    plan[#plan + 1] = { ms = 0, wait = true, fn = function()
        tEnd = tEnd or (getTimestampMs() + maxMs)
        if cond() then say("waited for " .. what); tEnd = nil; return true end
        if getTimestampMs() > tEnd then say("gave up waiting for " .. what); tEnd = nil; return true end
        return false
    end }
end

local function breedOf(kind)
    local def = AnimalDefinitions.getDef(kind)
    return def and def:getBreeds():get(0)
end
local function dropAll(full)
    local inv = p:getInventory()
    local list = inv:getAllTypeRecurse(full)
    for k = list:size() - 1, 0, -1 do
        local it = list:get(k)
        local c = it:getContainer()
        if c then c:Remove(it) end
    end
end
local function queueNames()
    local q = ISTimedActionQueue.queues[p]
    local t = {}
    for _, a in ipairs(q and q.queue or {}) do t[#t + 1] = tostring(a.Type) end
    return table.concat(t, ",")
end
local function alertOf(animal)
    for _, az in ipairs(W()._animalsAlertZones or {}) do if az.animal == animal then return az end end
end
local function bulk(id)
    for _, b in ipairs(W()._animalsBulkBtns or {}) do if b.id == id then return b end end
end
local function ringEl(id)
    for _, z in ipairs(W()._focusRing or {}) do
        for _, e in ipairs(z.elements or {}) do if e.id == id then return e end end
    end
end

-- 1  the animals, the zone, the tools taken away
add(300, function()
    p:setGodMod(true)
    for _, t in ipairs({ "Bucket", "BucketEmpty", "BucketForged", "BucketWood", "BucketLargeWood", "BucketCarved",
                         "SheepShears", "SheepElectricShears", "SheepShearsForged" }) do
        pcall(dropAll, t)
    end
    local px, py = math.floor(p:getX()), math.floor(p:getY())
    A.milk = addAnimal(getCell(), px + 3, py + 2, 0, "cow", breedOf("cow"))
    A.wool = addAnimal(getCell(), px - 3, py + 2, 0, "ewe", breedOf("ewe"))
    A.hungry = addAnimal(getCell(), px + 3, py - 3, 0, "cow", breedOf("cow"))
    pcall(function() A.milk:getData():setMaxMilkActual(6); A.milk:getData():setMilkQuantity(8) end)
    pcall(function() A.wool:getData():setWoolQuantity(5, true) end)
    pcall(function() A.hungry:getStats():set(CharacterStat.HUNGER, 0.9) end)
    pcall(function() A.hungry:getData():setMilkQuantity(0) end)
    local ok, err = pcall(function() DesignationZoneAnimal.new(ZONE, px - 8, py - 8, 0, px + 8, py + 8, true) end)
    say("animals milk=" .. tostring(A.milk ~= nil) .. " wool=" .. tostring(A.wool ~= nil) .. " hungry=" .. tostring(A.hungry ~= nil)
        .. " zone ok=" .. tostring(ok) .. " " .. tostring(err or ""))
end)
add(1500, function()
    AP.refreshCache()
    if not CWm.isOpen() then CWm.toggleBothPaired(0) end
end)
add(1500, function()
    local w = W(); w._activeTab = "animals"; w._drawerMode = "tab"; w._drawerOpen = true
    AT.getState(w).submode = "ranch"; AT.getState(w).view = "overview"
    if w._animalsOverviewState then w._animalsOverviewState.alertsExpanded = true end
end)

-- 2  greyed with the reason
add(1500, function()
    AQ.forgetChecks()
    local m, s, h = alertOf(A.milk), alertOf(A.wool), alertOf(A.hungry)
    check(m and m.verb == "milk", "the milk cow's alert offers Milk", m and m.verb)
    check(m and m.btn and not m.btn.ok and m.btn.why == ZeD.tr("UI_ZeD_Animals_NeedBucket"), "Milk greyed: needs a bucket", m and m.btn and m.btn.why)
    check(s and s.verb == "shear", "the ewe's alert offers Shear", s and s.verb)
    check(s and s.btn and not s.btn.ok and s.btn.why == ZeD.tr("UI_ZeD_Animals_NeedShears"), "Shear greyed: needs shears", s and s.btn and s.btn.why)
    check(h and h.verb == "goto" and h.btn.ok, "the starving cow's alert offers Walk to, live", h and h.verb)
    shot("1_greyed")
end)

-- 3  the tools
add(300, function()
    p:getInventory():AddItem("Base.Bucket")
    p:getInventory():AddItem("Base.SheepShears")
    AQ.forgetChecks()
end)
add(1000, function()
    local m, s = alertOf(A.milk), alertOf(A.wool)
    check(m and m.btn.ok, "with a bucket, Milk is live", m and m.btn.why)
    check(s and s.btn.ok, "with shears, Shear is live", s and s.btn.why)
    shot("2_live")
end)

-- 4  Walk to, then Milk on the alert (the game's own actions)
add(300, function()
    check(AT.alertAct(W(), A.hungry, "goto") == true, "Walk to pressed")
    say("queue after Walk to: " .. queueNames())
    check(queueNames():find("ISWalkToTimedAction") ~= nil, "the game's walk is queued")
end)
waitFor(20000, function() return not ISTimedActionQueue.isPlayerDoingAction(p) and queueNames() == "" end, "the walk")
add(300, function()
    A.milk0 = A.milk:getData():getMilkQuantity()
    check(AT.alertAct(W(), A.milk, "milk") == true, "Milk pressed on the alert")
    say("queue after Milk: " .. queueNames())
    check(queueNames():find("ISMilkAnimal") ~= nil, "ISMilkAnimal is queued after the walk to its side")
end)
add(4000, function() shot("3_milking") end)
waitFor(60000, function() return not ISTimedActionQueue.isPlayerDoingAction(p) and queueNames() == "" end, "the milking")
add(300, function()
    local m1 = A.milk:getData():getMilkQuantity()
    check(m1 < A.milk0, "the cow gave milk", string.format("%.2f -> %.2f", A.milk0, m1))
end)

-- 5  the zone: picks, ticks, the band's run
add(300, function()
    AP.refreshCache()
    AT.navigate(W(), "zone", ZONE, nil)
end)
add(1200, function()
    local w = W()
    check(bulk("hungry") and not bulk("hungry").disabled, "All hungry is live (a starving cow)")
    AT.bulkPress(w, "hungry")
    local sel = AT.getZoneViewState(w).sel
    check(sel and AQ.isSelected(sel, A.hungry) and not AQ.isSelected(sel, A.wool), "All hungry ticks the starving cow only")
end)
add(800, function()
    shot("4_hungry")
    check(bulk("clear") ~= nil, "with ticks the band offers Clear")
    AT.bulkPress(W(), "clear")
end)
add(800, function()
    local w = W()
    -- the ewe's row by the controller's X (the ring stop's onContextMenu)
    local idx
    for k, rz in ipairs(w._animalsRosterZones or {}) do if rz.animal == A.wool then idx = k end end
    local el = idx and ringEl("animals:roster:" .. idx)
    check(el and el.onContextMenu ~= nil, "a roster row's stop has X")
    if el then el.onContextMenu(w, el) end
    check(AQ.isSelected(AT.getZoneViewState(w).sel, A.wool), "X ticked the ewe")
end)
add(800, function()
    check(bulk("shear") and not bulk("shear").disabled, "the band offers Shear (1) for the ticked ewe")
    shot("5_ewe_ticked")
    AT.bulkPress(W(), "shear")
    check(AQ.run ~= nil and AQ.run.verb == "shear", "Shear started a run", AQ.runStatus())
end)
add(1500, function()
    check(bulk("stop") ~= nil, "during the run the band offers Stop", AQ.runStatus())
    shot("6_shearing")
end)
waitFor(90000, function() return AQ.run == nil end, "the shearing run")
add(500, function()
    check(AQ.last and AQ.last.why == ZeD.tr("UI_ZeD_Animals_RunDone", 1, 1), "the run ended Done 1 of 1", AQ.last and AQ.last.why)
    check(A.wool:getData():getWoolQuantity() <= 1, "the ewe is shorn", A.wool:getData():getWoolQuantity())
    shot("7_done")
end)
-- a run stopped by Stop: the milk cow again (it refills only slowly, so give it milk)
add(300, function()
    pcall(function() A.milk:getData():setMilkQuantity(6) end)
    AT.bulkPress(W(), "milkable")
end)
add(800, function()
    check(bulk("milk") and not bulk("milk").disabled, "All milkable then Milk (n) is live")
    AT.bulkPress(W(), "milk")
end)
add(2500, function()
    shot("8_milking_run")
    check(AQ.run ~= nil, "a milking run is going", AQ.runStatus())
    AT.bulkPress(W(), "stop")
    check(AQ.run == nil and AQ.last and AQ.last.why ~= nil, "Stop ends it", AQ.last and AQ.last.why)
end)

-- 6  the controller: the stops and A
add(800, function()
    Det.setLockedMode(Det.MODE_GAMEPAD)
    Focus.claimFocus(W())
end)
add(1200, function()
    local el = ringEl("animals:bulk:milkable")
    check(el and el.onActivate ~= nil, "All milkable is a ring stop with A")
    if el then el.onActivate(W(), el) end
end)
add(1200, function()
    check(ringEl("animals:bulk:clear") ~= nil, "A on All milkable: the band turned to Clear (and the focus should be on it)")
    local live = Focus.liveElement and Focus.liveElement(W())
    say("focus now on " .. tostring(live and live.id))
    shot("9_pad_band")
    AT.bulkPress(W(), "clear")
    AT.navigateBack(W())
end)
add(1500, function()
    local found
    for _, z in ipairs(W()._focusRing or {}) do
        for _, e in ipairs(z.elements or {}) do if e.isAlertRow and e.onActivate then found = true end end
    end
    check(found, "the alert rows are stops with A")
    shot("10_pad_alerts")
    Det.setLockedMode(nil)
    CWm.toggleBothPaired(0)
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
