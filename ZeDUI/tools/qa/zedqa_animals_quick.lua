-- ZeDUI/tools/qa/zedqa_animals_quick.lua  (Nov 11 2026, Build): the Animals tab's quick actions and the roster's bulk
-- select in game, with real animals. QA save only (Saves/Sandbox/ZeD-QA), the character on open ground (the drag strip).
-- Copy to Zomboid/Lua/zedqa.lua, bump zedqa.go, grep console.txt for "ZEDQA aq". PASS / FAIL lines, ending DONE.
-- Screenshots/zqa_aq_*.png (take the set at 4K 1.75x and again at the Deck size; the script does not resize).
-- WEST squares west of the character the animals are made (0 here; the _far copy makes them 16 off, so the
-- first press walks up to an animal the game has not drawn yet).
--   1  a cow with 8 L of milk, a ram with 5 wool (a ram gives no milk, so its alert is Shear), a starving cow; a zone
--      "QA Quick" over them; every carried milk container (the game's rule: empty or holding this milk, a water
--      bottle too), shears and cow food set aside
--   2  the Ranch page: the cow's alert offers Milk greyed (the milk-container reason), the ram's Shear greyed
--      ("needs shears"), the starving cow's Walk to live
--   3  a bucket and sheep shears given: Milk and Shear live
--   4  Walk to: the game's walk is queued; Milk on the alert: the game's milking runs and the cow's milk goes down
--   5  the zone: All hungry ticks the starving cow, Clear, All milkable, X on a row (the ring's onContextMenu), the
--      band's Milk (n) starts a run ("Milking 1 of n"), it ends ("Done") or is stopped by Stop
--   5a milked dry: with 0 L in her the cow has no milk alert and All milkable skips her; 0.5 wool, no shear alert
--   5b Feed: the starving cow ticked, Feed greyed with nothing to eat; carrots (one in a bag) and a steak given, the
--      food picker lists Carrots only with "For 1 of 1 | 2 carried"; picking it runs the game's ISFeedAnimalFromHand
--      and the cow's hunger goes down; B on the picker closes it with nothing fed
--   6  the controller: the band's buttons and the alert rows are ring stops; A on All milkable lands on Clear
-- THE LEDGER: everything the script gives, takes or makes is written down and put back at the end, and at once on
-- an error: given items taken away, set-aside items given back to the container they came from, the animals and
-- the zone removed, god mode and the hands as they were. Its animals and items carry the mod-data mark
-- ZeDQA_spawned, which zedqa_animals_restore.lua looks for.
local WEST = 0
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
local HOME = { p:getX(), p:getY() }

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
local function spawn(kind, x, y)
    local a = addAnimal(getCell(), x, y, 0, kind, breedOf(kind))
    if a then mark(a); LG.animals[#LG.animals + 1] = a; pcall(function() a:setDebugStress(0) end) end
    return a
end
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
    pcall(function() p:setX(HOME[1]); p:setY(HOME[2]); p:setLastX(HOME[1]); p:setLastY(HOME[2]) end)
    pcall(function() AP.refreshCache() end)
    pcall(function() if LG.opened and CWm.isOpen() then CWm.toggleBothPaired(0) end end)
    say("restored (" .. tostring(why) .. "): given and taken back " .. gone .. ", set aside and given back " .. back .. " of "
        .. #LG.taken .. ", animals removed " .. freed .. " of " .. #LG.animals .. ", zones removed " .. zones)
end

local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
-- wait (checking every tick) until cond() or the time runs out, then go on
local function waitFor(maxMs, cond, what)
    local tEnd
    plan[#plan + 1] = { ms = 0, wait = true, fn = function()
        tEnd = tEnd or (getTimestampMs() + maxMs)
        if cond() then say("waited for " .. what); tEnd = nil; return true end
        if getTimestampMs() > tEnd then say("gave up waiting for " .. what); tEnd = nil; return true end
        return false
    end }
end

local function queueNames()
    local q = ISTimedActionQueue.queues[p]
    local t = {}
    for _, a in ipairs(q and q.queue or {}) do t[#t + 1] = tostring(a.Type) end
    return table.concat(t, ",")
end
local function idle() return not ISTimedActionQueue.isPlayerDoingAction(p) and queueNames() == "" end
-- the alert row of this animal offering this verb (an animal can have more than one alert)
local function alertOf(animal, verb)
    for _, az in ipairs(W()._animalsAlertZones or {}) do
        if az.animal == animal and (verb == nil or az.verb == verb) then return az end
    end
end
local function bulk(id)
    for _, b in ipairs(W()._animalsBulkBtns or {}) do if b.id == id then return b end end
end
local function ringEl(id)
    for _, z in ipairs(W()._focusRing or {}) do
        for _, e in ipairs(z.elements or {}) do if e.id == id then return e end end
    end
end
local function focusId() local e = Focus.getFocusedElement(W()); return e and e.id end

-- 1  the animals, the zone, the tools and the cow food set aside
add(300, function()
    p:setGodMod(true)
    local px, py = math.floor(p:getX()) - WEST, math.floor(p:getY())
    A.milk = spawn("cow", px + 3, py + 2)
    A.wool = spawn("ram", px - 3, py + 2)
    A.hungry = spawn("cow", px + 3, py - 3)
    pcall(function() A.milk:getData():setMaxMilkActual(6); A.milk:getData():setMilkQuantity(8) end)
    pcall(function() A.wool:getData():setWoolQuantity(5, true) end)
    pcall(function() A.hungry:getStats():set(CharacterStat.HUNGER, 0.9) end)
    pcall(function() A.hungry:getData():setMilkQuantity(0) end)
    local ok, err = makeZone(ZONE, px - 8, py - 8, px + 8, py + 8)
    -- (the game's milk rule takes any empty container or one holding this milk, in the main inventory)
    local mt = A.milk and A.milk:getData():getBreed():getMilkType()
    local nMilk = 0
    for _ = 1, 40 do
        local list = mt and p:getInventory():getAvailableFluidContainer(mt)
        if not list or list:isEmpty() then break end
        takeOne(list:get(0)); nMilk = nMilk + 1
    end
    for _, t in ipairs({ "SheepShears", "SheepElectricShears", "SheepShearsForged" }) do pcall(takeType, "Base." .. t) end
    local nFood = takeWhere(function(it) return AQ.eats(A.hungry, it) end)
    say("ram: canBeSheared " .. tostring(A.wool and A.wool:canBeSheared()) .. ", canBeMilked " .. tostring(A.wool and A.wool:canBeMilked())
        .. ", wool " .. tostring(A.wool and A.wool:getData():getWoolQuantity()) .. " of " .. tostring(A.wool and A.wool:getData():getMaxWool()))
    say("set aside: " .. nMilk .. " milk containers, " .. nFood .. " cow foods, shears; zone ok=" .. tostring(ok) .. " " .. tostring(err or ""))
end)
add(1500, function()
    AP.refreshCache()
    if not CWm.isOpen() then LG.opened = true; CWm.toggleBothPaired(0) end
end)
add(1500, function()
    local w = W(); w._activeTab = "animals"; w._drawerMode = "tab"; w._drawerOpen = true
    AT.getState(w).submode = "ranch"; AT.getState(w).view = "overview"
    if w._animalsOverviewState then w._animalsOverviewState.alertsExpanded = true end
end)

-- 2  greyed with the reason
add(1500, function()
    AQ.forgetChecks()
    local m, s, h = alertOf(A.milk, "milk"), alertOf(A.wool), alertOf(A.hungry)
    check(m ~= nil, "the milk cow's alert offers Milk", m and m.verb)
    check(m and m.btn and not m.btn.ok and m.btn.why == ZeD.tr("UI_ZeD_Animals_NeedMilkContainer"), "Milk greyed: the milk-container reason", m and m.btn and m.btn.why)
    check(s and s.verb == "shear", "the ram's alert offers Shear", s and s.verb)
    check(s and s.btn and not s.btn.ok and s.btn.why == ZeD.tr("UI_ZeD_Animals_NeedShears"), "Shear greyed: needs shears", s and s.btn and s.btn.why)
    check(h and h.verb == "goto" and h.btn.ok, "the starving cow's alert offers Walk to, live", h and h.verb)
    shot("1_greyed")
end)

-- 3  the tools
add(300, function()
    give("Base.Bucket")
    give("Base.SheepShears")
    AQ.forgetChecks()
end)
add(1000, function()
    local m, s = alertOf(A.milk, "milk"), alertOf(A.wool, "shear")
    check(m and m.btn.ok, "with a bucket, Milk is live", m and m.btn.why)
    check(s and s.btn.ok, "with shears, Shear is live", s and s.btn.why)
    shot("2_live")
end)

-- 4  Walk to, then Milk on the alert (the game's own actions; a far animal is walked up to first)
add(300, function()
    check(AT.alertAct(W(), A.hungry, "goto") == true, "Walk to pressed")
    say("queue after Walk to: " .. queueNames())
    check(queueNames():find("ISWalkToTimedAction") ~= nil, "the game's walk is queued")
end)
waitFor(30000, idle, "the walk")
add(300, function()
    A.milk0 = A.milk:getData():getMilkQuantity()
    check(AT.alertAct(W(), A.milk, "milk") == true, "Milk pressed on the alert")
    say("queue after Milk: " .. queueNames() .. (AQ.run and AQ.run.approach and " (walking up first)" or ""))
    check(queueNames():find("ISMilkAnimal") ~= nil or (AQ.run ~= nil and AQ.run.approach), "ISMilkAnimal is queued after the walk to its side (or the walk up comes first)")
end)
add(4000, function() shot("3_milking") end)
waitFor(90000, function() return AQ.run == nil and idle() end, "the milking")
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
    -- the ram's row by the controller's X (the ring stop's onContextMenu)
    local idx
    for k, rz in ipairs(w._animalsRosterZones or {}) do if rz.animal == A.wool then idx = k end end
    local el = idx and ringEl("animals:roster:" .. idx)
    check(el and el.onContextMenu ~= nil, "a roster row's stop has X")
    if el then el.onContextMenu(w, el) end
    check(AQ.isSelected(AT.getZoneViewState(w).sel, A.wool), "X ticked the ram")
end)
add(800, function()
    check(bulk("shear") and not bulk("shear").disabled, "the band offers Shear (1) for the ticked ram")
    shot("5_ram_ticked")
    pcall(function() A.wool:setDebugStress(0) end)
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
    check(A.wool:getData():getWoolQuantity() <= 1, "the ram is shorn", A.wool:getData():getWoolQuantity())
    shot("7_done")
end)
-- a run stopped by Stop: the milk cow again (it refills only slowly, so give it milk; the given bucket emptied,
-- it may be full from the first milking)
add(300, function()
    emptyGiven()
    AQ.forgetChecks()
    pcall(function() A.milk:getData():setMilkQuantity(6) end)
    AT.bulkPress(W(), "milkable")
end)
add(800, function()
    local b = bulk("milk")
    check(b and not b.disabled, "All milkable then Milk (n) is live", b and tostring(b.disabled))
    AT.bulkPress(W(), "milk")
end)
add(2500, function()
    shot("8_milking_run")
    check(AQ.run ~= nil, "a milking run is going", AQ.runStatus())
    AT.bulkPress(W(), "stop")
    check(AQ.run == nil and AQ.last and AQ.last.why ~= nil, "Stop ends it", AQ.last and AQ.last.why)
    check(queueNames() == "", "Stop leaves nothing queued", queueNames())
end)

-- 5a Milked dry: the cow holds milk (the alert is up and All milkable counts it), is milked down to nothing, and the
--    alert goes with it (the game's menu offers Milk only above 0.1 L); the ram's wool the same way (shear above 1).
--    The animals are the script's own and leave at the end, so only their numbers change here.
local function pollerHas(animal, kind)
    for _, a in ipairs(AP.getAlerts()) do
        if a.animal == animal and a.alertType == kind then return true end
    end
    return false
end
add(300, function()
    emptyGiven()
    AQ.forgetChecks()
    pcall(function() A.milk:getData():setMilkQuantity(3) end)
    pcall(function() A.wool:getData():setWoolQuantity(5, true) end)
    AP.refreshCache()
    check(pollerHas(A.milk, "ready_milk") or pollerHas(A.milk, "udder_urgent"), "with 3 L in her, the cow has a milk alert")
    check(pollerHas(A.wool, "ready_shear"), "with 5 wool on him, the ram has a shear alert")
    check(AQ.countWhere({ A.milk }, "milkable") == 1, "All milkable counts the cow with milk")
    pcall(function() A.milk:getData():setMilkQuantity(0) end)
    pcall(function() A.wool:getData():setWoolQuantity(0.5, true) end)
    AP.refreshCache()
end)
add(1200, function()
    check(not pollerHas(A.milk, "ready_milk") and not pollerHas(A.milk, "udder_urgent"), "milked dry: no milk alert",
        A.milk:getData():getMilkQuantity())
    check(not pollerHas(A.wool, "ready_shear"), "shorn: no shear alert", A.wool:getData():getWoolQuantity())
    check(alertOf(A.milk, "milk") == nil and alertOf(A.wool, "shear") == nil, "the Ranch page lists neither row")
    check(AQ.countWhere({ A.milk }, "milkable") == 0, "All milkable counts nothing: it agrees with the alerts")
    shot("8a_dry")
end)

-- 5b Feed: the starving cow ticked, Feed greyed with no food (the cow food was set aside at 1); carrots (one in a
--    bag) and a steak given: the picker offers Carrots only ("For 1 of 1 | 2 carried"); picking it runs the game's
--    feeding and the cow's hunger goes down
add(300, function()
    pcall(function() A.hungry:getStats():set(CharacterStat.HUNGER, 0.9) end)
    AQ.forgetChecks()
    AT.bulkPress(W(), "clear")
end)
add(500, function()
    AQ.toggle(AT.getZoneViewState(W()).sel, A.hungry)
end)
add(1000, function()
    local f = bulk("feed")
    check(f ~= nil and f.disabled, "Feed (1) is in the band, greyed with no food carried")
    shot("8b_feed_greyed")
    give("Base.Carrots")
    give("Base.Steak")
    local bag = give("Base.Bag_Schoolbag")
    pcall(function() give("Base.Carrots", bag:getItemContainer()) end)
    AQ.forgetChecks()
end)
add(1000, function()
    local f = bulk("feed")
    check(f ~= nil and not f.disabled, "with carrots carried (one in a bag), Feed is live")
    AT.bulkPress(W(), "feed")
    local m = AT._feedMenu
    local rows = m and m._ctx and m._ctx.actions or {}
    local names = {}
    for _, r in ipairs(rows) do names[#names + 1] = tostring(r.name) .. " [" .. tostring(r.note) .. "]" end
    say("picker rows: " .. table.concat(names, "; "))
    local carrotName = getItemNameFromFullType and getItemNameFromFullType("Base.Carrots")
    check(m ~= nil and m._ctx.open and #rows == 1, "the picker opens with one food (the steak is no cow food)", #rows)
    check(rows[1] and (carrotName == nil or tostring(rows[1].name):find(carrotName, 1, true) ~= nil)
        and rows[1].note == ZeD.tr("UI_ZeD_Animals_FeedNote", 1, 1, 2),
        "Carrots: for 1 of 1, 2 carried", rows[1] and (tostring(rows[1].name) .. " " .. tostring(rows[1].note)))
end)
add(800, function()
    shot("8c_feed_picker")
    A.hunger0 = A.hungry:getStats():get(CharacterStat.HUNGER)
    local m = AT._feedMenu
    -- A on the list's row (the list's own confirm, as the pad's A does)
    if m then m:confirm() end
    check(AQ.run ~= nil and AQ.run.verb == "feed", "picking Carrots started a feeding run", AQ.runStatus())
    say("queue after the pick: " .. queueNames())
end)
add(3000, function() shot("8d_feeding") end)
waitFor(60000, function() return AQ.run == nil end, "the feeding run")
add(500, function()
    local h1 = A.hungry:getStats():get(CharacterStat.HUNGER)
    check(AQ.last and AQ.last.why == ZeD.tr("UI_ZeD_Animals_RunDone", 1, 1), "the run ended Done 1 of 1", AQ.last and AQ.last.why)
    check(h1 < (A.hunger0 or 0), "the cow ate", string.format("%.2f -> %.2f", A.hunger0 or -1, h1))
end)
-- the picker on the pad: B closes it and leaves the band as it was
add(500, function()
    pcall(function() A.hungry:getStats():set(CharacterStat.HUNGER, 0.9) end)
    AQ.forgetChecks()
    AQ.toggle(AT.getZoneViewState(W()).sel, A.hungry)
end)
add(1000, function()
    AT.bulkPress(W(), "feed")
    local m = AT._feedMenu
    if m then m:onJoypadDown(Joypad.BButton) end
    check(m and not m._ctx.open and AQ.run == nil, "B on the picker closes it, nothing fed")
    AT.bulkPress(W(), "clear")
end)

-- 6  the controller: the stops and A
add(800, function()
    pcall(function() A.milk:getData():setMilkQuantity(6) end)
    Det.setLockedMode(Det.MODE_GAMEPAD)
    Focus.claimFocus(W())
end)
add(1200, function()
    local el = ringEl("animals:bulk:milkable")
    check(el and el.onActivate ~= nil, "All milkable is a ring stop with A")
    if el then el.onActivate(W(), el) end
end)
add(1200, function()
    check(ringEl("animals:bulk:clear") ~= nil, "A on All milkable: the band turned to Clear")
    check(focusId() == "animals:bulk:clear", "A on All milkable: the focus lands on Clear, which took its place", focusId())
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
end)

-- the end: everything put back
add(500, function()
    restore("the end")
    check(LG.done and idle(), "put back: nothing queued, the ledger spent")
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
    if not ok then
        -- a failed step ends the run: put everything back first
        say("ERR step " .. (i - 1) .. ": " .. tostring(e))
        Events.OnTick.Remove(drive)
        restore("an error")
        say("fails " .. (fails + 1))
        say("DONE")
    end
end
Events.OnTick.Add(drive)
say("start")
