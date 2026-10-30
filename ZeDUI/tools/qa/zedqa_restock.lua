-- ZeDUI/tools/qa/zedqa_restock.lua  (Oct 29 2026)
-- In game on the ZeD-QA save: the loadouts' Equip bar, to-do, restock and unpack
-- (handoff equip_doll_v4_loadouts, parts B4-B7, Part C's checks for them).
-- The fixture: the grandstand building beside the drag strip (the QA home). The
-- character goes to a clear square inside it; ZeD builds two crates beside it
-- (in reach), a small locker locked by a code (in reach) and a crate six squares
-- east (out of reach). Water and katanas already in the building are set aside
-- for the run (so the water line can only be filled at a tap and the katana is
-- only in the locked locker) and put back at the end.
--   * the bar (doll view): ready n of m, the ghosts of what's missing on the doll;
--   * the to-do's five states (on you, take, fill at a tap, ask, none);
--   * asked first before the last bandage in the building, the answer taken;
--   * Hardcore: the time on the button is the queued actions' total; takes and
--     wears; never takes from the locked locker (and real seconds per unit, logged);
--   * stops: a key, a zombie coming into view, getting hurt;
--   * Accessible: the route walk to the far crate and back; Casual: the pinned
--     list and the notice as the far crate comes into reach;
--   * the long trip: over the limit, the heaviest supply named, Make it N days fits;
--   * Unpack: loot to where its kind lives, a kind with no home asks once (kept),
--     leftovers packed, food about to spoil goes back;
--   * the pad: the Loadouts ring, A restocks in the to-do, B back to the bar.
-- Puts everything back (lists, setting, items, built things, the set-aside
-- things, the character home). Screenshots/zqa_rst_*.png. grep "ZEDQA rst".
local p = getPlayer()
local pn = p:getPlayerNum()
local L, R, EL = ZeD.Lists, ZeD.Restock, ZeD.EquipLoadout
local function say(s) print("ZEDQA rst " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_rst_" .. n .. ".png") end) end
local function cw() return ZeD_CharacterWindow.getWindow() end
local fails = 0
local function check(ok, what) if ok then say("ok   " .. what) else fails = fails + 1; say("FAIL " .. what) end end

-- ---------------------------------------------------------------------------
-- the step queue: wait n ticks, wait until, or wait for the windows to be still
-- ---------------------------------------------------------------------------
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function untilDo(cond, max, fn, what) Q[#Q + 1] = { cond = cond, max = max, fn = fn, what = what } end
local STILL, STILL_MAX = 30, 600
local function shape()
    local t = {}
    for _, w in ipairs({ ZeD_CharacterWindow.getWindow(), ZeD_WorldWindow.getWindow() }) do
        if w and w:isVisible() then
            local dp = w._drawerPanel
            t[#t + 1] = string.format("%d,%d,%d,%d,%d", w:getX(), w:getY(), w:getWidth(), math.floor(w._drawerEffW or 0), dp and dp:getWidth() or 0)
        end
    end
    return table.concat(t, ";")
end
local still = { last = nil, same = 0, waited = 0 }
local function stillStep(fn) Q[#Q + 1] = { still = true, fn = fn } end

-- ---------------------------------------------------------------------------
-- what the run changes, kept to put back
-- ---------------------------------------------------------------------------
local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = deepCopy(v) end
    return o
end
local md = p:getModData()
local savedLists = deepCopy(md.ZeD_Lists)
local restockWas = ZeD.Settings.restockOption:getValue()
local viewWas = ZeD.EquipDoll.view()
local HOME = { x = 925.5, y = 13040.5, z = 0 }
local before = {}          -- item ids on the character at the start
for _, it in ipairs(R.allOn(p)) do before[it:getID()] = true end
local wornBefore = {}
do local w = p:getWornItems(); for i = 0, w:size() - 1 do wornBefore[w:get(i):getItem()] = true end end
local mainWas, offWas = p:getPrimaryHandItem(), p:getSecondaryHandItem()
local made = {}            -- every item the run made (removed at the end, wherever it ended up)
local function give(cont, ft)
    local it = cont:AddItem(ft)
    if it then made[#made + 1] = it end
    return it
end
local built = {}           -- the crates and the locker
local stashed = {}         -- { cont, item } set aside

local S, F, crateA, crateB, locker, crateF, building
local axe, hat, hatLoc, screwdriver, bottle, katana, crowbar, bread
local loId, ofId, longId

-- ---------------------------------------------------------------------------
-- the fixture
-- ---------------------------------------------------------------------------
local function findInfo(full)
    local infos = SpriteConfigManager.GetObjectInfoList()
    for i = 0, infos:size() - 1 do
        local info = infos:get(i)
        local parent = info:getScript() and info:getScript():getParent()
        if parent and tostring(parent:getScriptObjectFullType()) == full then return info end
    end
end
local function build(full, sq)
    local info = findInfo(full)
    if not (info and sq) then say("no info / square for " .. full); return nil end
    local n0 = sq:getObjects():size()
    p:setBuildCheat(true)
    pcall(function()
        local b = ISBuildIsoEntity:new(p, info, 1, ISInventoryPaneContextMenu.getContainers(p))
        b.buildCheat = true; b.player = pn; b.sq = sq
        if b:isValid(sq) then b:create(sq:getX(), sq:getY(), sq:getZ(), false, nil) end
    end)
    p:setBuildCheat(false)
    local objs = sq:getObjects()
    for i = objs:size() - 1, 0, -1 do
        local o = objs:get(i)
        if o:getContainer() then
            if i >= n0 or not built[o] then built[#built + 1] = { sq = sq, o = o }; pcall(function() o:getContainer():setExplored(true) end); return o end
        end
    end
    say("build " .. full .. " made nothing at " .. sq:getX() .. "," .. sq:getY())
    return nil
end
local function clearSq(sq)
    if not (sq and sq:getBuilding() == building and sq:getRoom()) then return false end
    if not sq:isFree(false) then return false end
    return sq:getObjects():size() <= 1 and sq:getWorldObjects():size() == 0
end
local function moveTo(x, y, z)
    p:setX(x); p:setY(y); p:setZ(z); p:setLastX(x); p:setLastY(y); p:setLastZ(z)
end
local function srcOf(obj)
    for _, s in ipairs(R.scan(p, true).sources) do if s.obj == obj then return s end end
    return nil
end
local function rowOf(plan, pred) for _, r in ipairs(plan.rows) do if pred(r.line) then return r end end end
local function onYou(it) local c = it and it:getContainer(); return c ~= nil and c:isInCharacterInventory(p) end
local function lineFor(t)
    t.amount = t.amount or 1
    t.unit = t.unit or "n"
    t.place = t.place or "inv"
    t.rule = t.rule or "any"
    return t
end
-- the building's own things of a kind set aside (put back at the end)
local function stash(pred)
    local n = 0
    for _, s in ipairs(R.scan(p, true).sources) do
        if not s.floor and not s.vehicle then
            local items = s.cont:getItems()
            for i = items:size() - 1, 0, -1 do
                local it = items:get(i)
                if pred(it) then stashed[#stashed + 1] = { cont = s.cont, item = it }; s.cont:Remove(it); n = n + 1 end
            end
        end
    end
    return n
end
local function countIn(pred)
    local n = 0
    for _, s in ipairs(R.scan(p, true).sources) do
        if not s.floor then
            local items = s.cont:getItems()
            for i = 0, items:size() - 1 do if pred(items:get(i)) then n = n + 1 end end
        end
    end
    return n
end
local function putBackInto(cont, it)
    local c = it:getContainer()
    if c and c ~= cont then c:Remove(it) end
    if p:isEquippedClothing(it) then p:removeWornItem(it) end
    if p:getPrimaryHandItem() == it then p:setPrimaryHandItem(nil) end
    if p:getSecondaryHandItem() == it then p:setSecondaryHandItem(nil) end
    if not cont:contains(it) then cont:AddItem(it) end
end

-- ---------------------------------------------------------------------------
step(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    if not (cw() and cw():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(pn) end
    p:setGodMod(true)
    ISTimedActionQueue.clear(p)
    -- the clear square in the grandstand nearest its west door, with a clear corridor six squares east
    local cell = getCell()
    local b0 = cell:getGridSquare(892, 13040, 0)
    building = b0 and b0:getBuilding()
    if not building then
        for dx = 0, 12 do local sq = cell:getGridSquare(892 - dx, 13040, 0); if sq and sq:getBuilding() then building = sq:getBuilding(); break end end
    end
    if not building then say("ERR no grandstand building near 892,13040"); return end
    local d = building:getDef()
    local best, bd = nil, nil
    for y = d:getY() + 1, d:getY2() - 2 do
        for x = d:getX() + 1, d:getX2() - 8 do
            local sq = cell:getGridSquare(x, y, 0)
            if sq and clearSq(sq) then
                local ok = true
                for dy = -1, 1 do for dx = -1, 7 do
                    if ok and not clearSq(cell:getGridSquare(x + dx, y + dy, 0)) then ok = false end
                end end
                if ok then
                    local dist = math.abs(x - 892) + math.abs(y - 13040)
                    if not bd or dist < bd then best, bd = sq, dist end
                end
            end
        end
    end
    if not best then say("ERR no clear 9x3 floor in the grandstand"); return end
    S = best
    F = cell:getGridSquare(S:getX() + 6, S:getY(), 0)
    say(string.format("fixture: building %s, standing at %d,%d (%d from 892,13040)", R.bkey(building), S:getX(), S:getY(), bd))
    moveTo(S:getX() + 0.5, S:getY() + 0.5, 0)
end)

step(120, function()
    if not S then return end
    local cell = getCell()
    crateA = build("Base.Wood_Crate_Lvl1", cell:getGridSquare(S:getX() - 1, S:getY(), 0))
    crateB = build("Base.Wood_Crate_Lvl1", cell:getGridSquare(S:getX(), S:getY() - 1, 0))
    locker = build("Base.Metal_LockerSmall_Lvl1", cell:getGridSquare(S:getX(), S:getY() + 1, 0))
    crateF = build("Base.Wood_Crate_Lvl1", F)
    say("built: crateA " .. tostring(crateA ~= nil) .. " crateB " .. tostring(crateB ~= nil) .. " locker " .. tostring(locker ~= nil) .. " crateF " .. tostring(crateF ~= nil))
end)

step(20, function()
    if not (crateA and crateB and locker and crateF) then say("ERR the fixture is incomplete"); return end
    -- set aside the building's water and katanas
    local nw = stash(function(it) return L.waterIn(it) > 0 end)
    local nk = stash(function(it) return it:getFullType() == "Base.Katana" end)
    say("set aside: " .. nw .. " things holding water, " .. nk .. " katanas")
    local A, B = crateA:getContainer(), crateB:getContainer()
    axe = give(A, "Base.HandAxe")
    for _, c in ipairs({ { "Base.Hat_Fedora", "hat" }, { "Base.Hat_BaseballCap", "hat" }, { "Base.Necklace_Gold", "necklace" }, { "Base.Scarf_StripeBlackWhite", "scarf" } }) do
        local taken = false
        local w = p:getWornItems()
        for i = 0, w:size() - 1 do if L.normLoc(w:get(i):getLocation()) == c[2] then taken = true end end
        if not taken then hat = give(A, c[1]); hatLoc = L.normLoc(hat:getBodyLocation()) or c[2]; break end
    end
    give(A, "Base.Bandage"); give(A, "Base.Bandage")
    give(B, "Base.TinnedBeans")
    katana = give(locker:getContainer(), "Base.Katana")
    locker:setLockedByCode(319)
    crowbar = give(crateF:getContainer(), "Base.Crowbar")
    local inv = p:getInventory()
    screwdriver = give(inv, "Base.Screwdriver")
    bottle = give(inv, "Base.WaterBottle")
    pcall(function() bottle:getFluidContainer():Empty() end)
    say("stocked: hat " .. tostring(hat and hat:getFullType()) .. " at " .. tostring(hatLoc) .. ", locker locked " .. tostring(locker:isLockedToCharacter(p)))
    -- the lists (a clean store for the run; the character's own put back at the end)
    md.ZeD_Lists = nil
    R.forget(p)
    local nBand = countIn(function(it) return it:getFullType() == "Base.Bandage" end)
    local lo = L.create(p, "loadout", "QA restock")
    loId = lo.id
    L.addLine(p, loId, lineFor({ sec = "gear", place = "hand:main", rule = "this", type = "Base.HandAxe", itemId = axe:getID(), name = axe:getDisplayName() }))
    L.addLine(p, loId, lineFor({ sec = "gear", type = "Base.Screwdriver", name = screwdriver:getDisplayName() }))
    L.addLine(p, loId, lineFor({ sec = "supply", per = "fixed", type = "Base.Bandage", name = "Bandage", amount = nBand }))
    L.addLine(p, loId, lineFor({ sec = "supply", per = "fixed", kind = "water", unit = "l", type = "Base.WaterBottle", name = "Water", amount = 0.5 }))
    L.addLine(p, loId, lineFor({ sec = "gear", type = "Base.Katana", name = "Katana" }))
    L.addLine(p, loId, lineFor({ sec = "gear", rule = "this", type = "Base.Crowbar", itemId = crowbar:getID(), name = crowbar:getDisplayName() }))
    local of = L.create(p, "outfit", "QA outfit")
    ofId = of.id
    L.addLine(p, ofId, lineFor({ sec = "worn", place = "worn:" .. hatLoc, type = hat:getFullType(), name = hat:getDisplayName() }))
    R.setOutfit(p, ofId); R.setLoadout(p, loId); R.setDays(p, 1)
    say("bandages in the building: " .. nBand)
    -- the Equip tab, the doll view
    ZeD.EquipDoll.setView("doll")
    local w = cw()
    local strip = w._tabStripPanel
    if w._activeTab ~= "equip" then
        for _, z in ipairs(strip._hitZones or {}) do if z.id == "tab:equip" then strip:onMouseDown(z.x + 2, z.y + 2) end end
    end
end)

-- B4: the bar, ready n of m, the ghosts --------------------------------------
step(90, function()
    local w = cw()
    local s = EL.state(w)
    EL.plan(w, true)
    local ids = {}
    for _, z in ipairs(w._elZones or {}) do ids[#ids + 1] = z.id end
    say("bar zones: " .. table.concat(ids, ","))
    check(w._activeTab == "equip" and #ids >= 6, "the bar draws under Equipped")
    check(s.readyN == 1 and s.readyM == 6, "ready " .. tostring(s.readyN) .. " of " .. tostring(s.readyM) .. " (the screwdriver on you, of 6 lines)")
    check(s.wornN == 0 and s.wornM == 1, "outfit worn " .. tostring(s.wornN) .. " of " .. tostring(s.wornM))
    local g = w._equipDollGhosts or {}
    local gk = {}
    for k in pairs(g) do gk[#gk + 1] = k end
    say("ghosts: " .. table.concat(gk, ","))
    local hatSlot = ZeD.EquipDoll.slotForLoc(hatLoc, w._equipDollBands)
    check(g.main ~= nil, "a ghost in the main hand (the axe)")
    check(hatSlot ~= nil and g[hatSlot] ~= nil, "a ghost at " .. tostring(hatSlot) .. " (the " .. tostring(hatLoc) .. ")")
end)
stillStep(function() shot("01_bar_ghosts") end)

-- B4: the to-do's five states ---------------------------------------------
step(5, function()
    local w = cw()
    EL.openTodo(w)
end)
step(40, function()
    local w = cw()
    local plan = EL.plan(w, true)
    local st = {}
    for _, r in ipairs(plan.rows) do st[#st + 1] = (r.line.name or "?") .. "=" .. r.state .. "@" .. tostring(r.where) end
    say("states: " .. table.concat(st, " | "))
    local function is(pred, want, what) local r = rowOf(plan, pred); check(r and r.state == want, what .. ": " .. tostring(r and r.state)) end
    is(function(l) return l.type == "Base.Screwdriver" end, "on", "on you")
    is(function(l) return l.type == "Base.HandAxe" end, "take", "take from a container")
    is(function(l) return l.kind == "water" end, "fill", "fill at a tap")
    is(function(l) return l.type == "Base.Bandage" end, "ask", "ask first: the last bandages in the building")
    is(function(l) return l.type == "Base.Katana" end, "none", "none in the building (the katana is only in the locked locker)")
    local ax = rowOf(plan, function(l) return l.type == "Base.HandAxe" end)
    check(ax and ax.where and ax.picks[1] and ax.picks[1].src and ax.picks[1].src.obj == crateA, "the axe is taken from crate A (" .. tostring(ax and ax.where) .. ")")
    check(EL.todoOpen(w), "the to-do is open in the drawer")
    check((w._drawerPanel and w._drawerPanel:getWidth() or 0) <= ZeD.T.px(480) + 1, "the drawer stays the full card (" .. tostring(w._drawerPanel:getWidth()) .. " <= " .. ZeD.T.px(480) .. ")")
end)
stillStep(function() shot("02_todo") end)
step(5, function() EL.state(cw()).scroll:setScrollPos(1) end)
stillStep(function() shot("02b_todo_lines"); EL.state(cw()).scroll:setScrollPos(0) end)

-- the last bandage: asked first, in the band ----------------------------------
step(5, function()
    local w = cw()
    local plan = EL.plan(w, true)
    local r = rowOf(plan, function(l) return l.type == "Base.Bandage" end)
    local lo = L.get(p, loId)
    -- one fewer than the building holds: no question
    local ln = r.line
    local was = ln.amount
    ln.amount = was - 1
    local p2 = R.plan(p, { force = true })
    local r2 = rowOf(p2, function(l) return l.type == "Base.Bandage" end)
    check(r2 and r2.state == "take", "one bandage left behind: no question (" .. tostring(r2 and r2.state) .. ")")
    ln.amount = was
    L.gen = L.gen + 1
    -- the row pressed: the question in the band
    for _, z in ipairs(w._elZones or {}) do if z.id == "row:" .. r.key and z.fn then z.fn() end end
    check(EL.state(w).ask == r.key, "pressing the ask line puts the question in the band")
end)
stillStep(function() shot("03_ask_band") end)
step(5, function()
    local w = cw()
    local s = EL.state(w)
    local els = EL.focusables(w)
    local ids = {}
    for _, e in ipairs(els) do ids[#ids + 1] = e.id end
    check(#els == 2 and ids[1] == "el:ask:cancel", "the question's two answers are the only stops: " .. table.concat(ids, ","))
    local v = s.askRects and s.askRects.verb
    if v then EL.onClick(w, v.x + 2, v.y + 2) end
    local plan = EL.plan(w, true)
    local r = rowOf(plan, function(l) return l.type == "Base.Bandage" end)
    check(r and r.state == "take", "answered Take it: the bandages are to take (" .. tostring(r and r.state) .. ")")
end)

-- B5 Hardcore: the time on the button, the takes, never the locked locker -------
local hc = {}
step(5, function()
    ZeD.Settings.restockOption:setValue(1)
    check(R.mode() == "hardcore", "the setting: Hardcore")
    local w = cw()
    local plan = EL.plan(w, true)
    hc.secs = plan.secs
    local run = R.start(p, "restock")
    local u = 0
    for _, a in ipairs(run.acts) do u = u + R.units(a) end
    hc.qsecs = u * R.SEC_PER_UNIT
    hc.ms = getTimestampMs()
    hc.n = #run.acts
    local types = {}
    for _, a in ipairs(run.acts) do types[#types + 1] = tostring(a.Type) end
    say("hardcore queued " .. #run.acts .. ": " .. table.concat(types, ","))
    check(math.abs(hc.secs - hc.qsecs) < 0.05, string.format("the time on the button %s is the queued actions' %s", R.timeText(hc.secs), R.timeText(hc.qsecs)))
    check(hc.n > 0, "hardcore queued the takes in reach")
end)
untilDo(function() local r = R.runs[pn]; return r and r.done end, 1800, function()
    local real = (getTimestampMs() - hc.ms) / 1000
    say(string.format("hardcore ran %.1f s real for %.1f s estimated (%.2f real s per estimated s)", real, hc.qsecs, hc.qsecs > 0 and real / hc.qsecs or 0))
    check(p:getPrimaryHandItem() == axe, "the axe in the main hand")
    check(p:isEquippedClothing(hat), "the " .. tostring(hat and hat:getDisplayName()) .. " worn")
    check(katana:getContainer() == locker:getContainer(), "the katana is still in the locked locker")
    check(not onYou(crowbar), "the far crate's crowbar was not taken (not in reach)")
end, "the hardcore run to finish")
stillStep(function() shot("04_after_hardcore") end)

-- B5 stops: a key, a zombie in view, getting hurt (Accessible) -----------------
local function reset()
    ISTimedActionQueue.clear(p)
    putBackInto(crateA:getContainer(), axe)
    putBackInto(crateA:getContainer(), hat)
    putBackInto(crateF:getContainer(), crowbar)
    moveTo(S:getX() + 0.5, S:getY() + 0.5, 0)
    R.forget(p)
    L.gen = L.gen + 1
end
local zed
step(10, function()
    -- (the walks below keep to the fixture: the lines for the building's bandages, the tap and the katana go)
    local lo = L.get(p, loId)
    for i = #lo.lines, 1, -1 do
        local ln = lo.lines[i]
        if ln.type == "Base.Bandage" or ln.kind == "water" or ln.type == "Base.Katana" then L.removeLine(p, loId, ln.id) end
    end
    reset()
    ZeD.Settings.restockOption:setValue(3)
    R.start(p, "restock")
end)
step(30, function()
    -- (a real key code no game key is bound to: 0 matches every unbound key, the pause menu among them)
    triggerEvent("OnKeyPressed", 100)
end)
step(10, function()
    local run = R.runs[pn]
    check(run and run.done and run.stopped == "key", "a key stops the run (" .. tostring(run and run.stopped) .. ")")
    check(not ISTimedActionQueue.isPlayerDoingAction(p) and R.pending(p, run) == 0, "the queue is cancelled")
    reset()
    R.start(p, "restock")
end)
step(10, function()
    local zs = addZombiesInOutfit(S:getX() + 3, S:getY(), 0, 1, "Naked", 0)
    zed = zs and zs:size() > 0 and zs:get(0) or nil
    if zed then pcall(function() zed:setUseless(true) end) end
    say("zombie spawned " .. tostring(zed ~= nil))
end)
untilDo(function() local r = R.runs[pn]; return r and r.done end, 300, function()
    local run = R.runs[pn]
    check(run.stopped == "zombie", "a zombie coming into view stops the run (" .. tostring(run.stopped) .. ", visible " .. p:getStats():getNumVisibleZombies() .. ")")
    if zed then pcall(function() zed:removeFromWorld(); zed:removeFromSquare() end) end
end, "the zombie stop")
step(60, function()
    reset()
    R.start(p, "restock")
    R.runs[pn].z0 = 99   -- (the removed zombie may still be counted a moment)
end)
step(20, function()
    p:setGodMod(false)
    pcall(function() p:getBodyDamage():getBodyPart(BodyPartType.Hand_L):AddDamage(15) end)
    pcall(function() p:getBodyDamage():setOverallBodyHealth(p:getBodyDamage():getOverallBodyHealth() - 10) end)
end)
untilDo(function() local r = R.runs[pn]; return r and r.done end, 200, function()
    local run = R.runs[pn]
    check(run.stopped == "hurt", "getting hurt stops the run (" .. tostring(run.stopped) .. ")")
    pcall(function() p:getBodyDamage():RestoreToFullHealth() end)
    p:setGodMod(true)
end, "the hurt stop")

-- B5 Accessible: the route walk to the far crate and back ------------------------
local acc = {}
step(30, function()
    reset()
    acc.x, acc.y = p:getX(), p:getY()
    local run = R.start(p, "restock")
    acc.stops = run.stops and #run.stops or 0
    run.z0 = 99
    say("accessible: " .. acc.stops .. " stops, " .. #run.acts .. " actions")
    check(acc.stops >= 2, "the route goes to crate A and the far crate")
end)
step(90, function()
    local w = cw()
    local txt = EL.statusText(w)
    say("walking line: " .. tostring(txt))
    check(txt and txt:find(ZeD.tr("UI_ZeD_Restock_Walking", 1, 1, "x"):sub(1, 6), 1, true) ~= nil, "the pinned list says where it walks")
    check(ZeD.RestockPin.panels[pn] ~= nil, "the to-do is pinned at the screen edge")
    shot("05_pin_accessible")
end)
untilDo(function() local r = R.runs[pn]; return r and r.done end, 3000, function()
    local run = R.runs[pn]
    check(run.stopped == nil, "the walk finished (" .. tostring(run.stopped) .. ")")
    check(onYou(crowbar), "the far crate's crowbar taken on the walk")
    local d = math.abs(p:getX() - acc.x) + math.abs(p:getY() - acc.y)
    check(d < 2.5, string.format("back where it was pressed (%.1f squares off)", d))
    check(katana:getContainer() == locker:getContainer(), "the katana is still in the locked locker")
end, "the accessible walk")

-- B5 Casual: in reach now, then the far crate as it comes into reach -------------
local cas = {}
step(30, function()
    reset()
    ZeD.Settings.restockOption:setValue(2)
    local run = R.start(p, "restock")
    run.z0 = 99
end)
untilDo(function() return p:getPrimaryHandItem() == axe end, 900, function()
    check(not onYou(crowbar), "casual: the far crate's crowbar waits until it is in reach")
    check(ZeD.RestockPin.panels[pn] ~= nil, "casual: the to-do is pinned")
    moveTo(F:getX() - 0.5, F:getY() + 0.5, 0)   -- (beside the far crate)
end, "casual: the takes in reach")
untilDo(function() return onYou(crowbar) end, 900, function()
    local run = R.runs[pn]
    say("notice: " .. tostring(run.notice))
    check(run.notice and run.notice:find(crowbar:getDisplayName(), 1, true) ~= nil, "casual: a notice names the crowbar and where from")
    shot("06_pin_casual")
end, "casual: the far crate")
untilDo(function() local r = R.runs[pn]; return r and r.done end, 600, function()
    check(R.runs[pn].stopped == nil, "casual: done when the list is empty")
end, "casual: done")

-- B4 long trip: over the limit, the heaviest supply, Make it N days ------------
step(30, function()
    moveTo(S:getX() + 0.5, S:getY() + 0.5, 0)
    local lt = L.create(p, "loadout", "QA long haul")
    longId = lt.id
    local room = p:getMaxWeight() - p:getInventoryWeight()
    local perDay = math.max(1, math.floor(room / 3 * 2 + 0.5) / 2)
    L.addLine(p, longId, lineFor({ sec = "supply", per = "day", kind = "water", unit = "l", type = "Base.WaterBottle", name = "Water", amount = perDay }))
    L.addLine(p, longId, lineFor({ sec = "supply", per = "day", type = "Base.Bandage", name = "Bandage", amount = 1 }))
    L.addLine(p, longId, lineFor({ sec = "gear", type = "Base.Screwdriver", name = "Screwdriver" }))
    R.setLoadout(p, longId)
    R.setDays(p, 5)
    say(string.format("long haul: %.1f of %.1f carried, water %.1f L a day", p:getInventoryWeight(), p:getMaxWeight(), perDay))
    local w = cw()
    EL.openTodo(w)
end)
step(40, function()
    local w = cw()
    EL.plan(w, true)
    local s = EL.state(w)
    local ov = s.over
    check(ov ~= nil, "5 days is over the limit" .. (ov and string.format(" (by %.1f)", ov.over) or ""))
    check(ov and ov.heaviest and ov.heaviest.line.kind == "water", "the heaviest supply named: " .. tostring(ov and ov.heaviest and ov.heaviest.line.name))
    check(ov and ov.fits >= 1 and ov.fits < 5, "the most days that fit: " .. tostring(ov and ov.fits))
    local mk = nil
    for _, z in ipairs(w._elZones or {}) do if z.id == "makeit" then mk = z end end
    check(mk ~= nil, "Make it N days is offered")
end)
stillStep(function() shot("07_long_trip") end)
step(5, function() EL.state(cw()).scroll:setScrollPos(1) end)
stillStep(function() shot("07b_long_trip_table"); EL.state(cw()).scroll:setScrollPos(0) end)
step(5, function()
    local w = cw()
    for _, z in ipairs(w._elZones or {}) do if z.id == "makeit" and z.fn then z.fn() end end
    local _, _, days = R.current(p)
    local plan = EL.plan(w, true)
    check(days < 5 and EL.state(w).over == nil, "Make it " .. days .. " days fits")
end)

-- B6 Unpack ---------------------------------------------------------------------
local up = {}
step(10, function()
    R.setLoadout(p, loId)
    R.setDays(p, 1)
    local s = L.store(p)
    check(s.home and s.home.b == R.bkey(building), "home: the building where you last restocked (" .. tostring(s.home and s.home.b) .. ")")
    local inv = p:getInventory()
    bread = give(inv, "Base.Bread")
    pcall(function() bread:setAge(math.max(0, bread:getOffAge() - 1)) end)
    give(inv, "Base.Bandage")
    R.snapshotTrip(p)   -- what you left with
    -- the loot: tinned beans (the kitchen keeps food) and a kind the building has nowhere
    up.beans = { give(inv, "Base.TinnedBeans"), give(inv, "Base.TinnedBeans") }
    local scan = R.scan(p, true)
    for _, ft in ipairs({ "Base.GuitarAcoustic", "Base.Harmonica", "Base.Flute", "Base.Violin", "Base.Banjo", "Base.Saxophone",
                          "Base.Trowel", "Base.Plunger", "Base.Golfclub", "Base.BaseballBat", "Base.Rope", "Base.Saw" }) do
        local it = give(inv, ft)
        local cat = R.kindOf(it)
        local has = countIn(function(x) return R.kindOf(x) == cat end) > 0
        if not has then up.odd, up.cat = it, cat; break end
        inv:Remove(it)
    end
    say("loot: beans x2, odd " .. tostring(up.odd and up.odd:getFullType()) .. " (" .. tostring(up.cat) .. ")")
    check(R.homeNow(p), "back home with things from a trip: Unpack is offered")
    local w = cw()
    EL.openTodo(w)
end)
step(40, function()
    local w = cw()
    EL.plan(w, true)
    local u = EL.state(w).unpack
    local beans, odd, breadE, band = nil, nil, nil, nil
    for _, e in ipairs(u and u.loot or {}) do
        if e.item == up.beans[1] then beans = e end
        if e.item == up.odd then odd = e end
    end
    for _, e in ipairs(u and u.leftovers or {}) do
        if e.item == bread then breadE = e end
        if e.item:getFullType() == "Base.Bandage" then band = e end
    end
    check(beans and beans.state == "put" and beans.dest ~= nil, "loot goes where its kind lives: beans to " .. tostring(beans and beans.dest and beans.dest.name))
    check(odd and odd.state == "pick", "a kind with no home asks for a place (" .. tostring(odd and odd.state) .. ")")
    check(breadE and breadE.state == "put", "leftover food that spoils within 2 days goes back (" .. tostring(breadE and breadE.state) .. ")")
    check(band and band.state == "stay", "leftover supplies stay packed (" .. tostring(band and band.state) .. ")")
    check(#u.stays > 0, "stays on you: " .. table.concat(u.stays, ", "))
    local verb = nil
    for _, z in ipairs(w._elZones or {}) do if z.id == "v1" then verb = z end end
    check(verb ~= nil and verb.fn ~= nil, "the to-do's first button is Unpack, live")
end)
stillStep(function() shot("08_unpack") end)
step(5, function()
    -- the place picked once (crate A), kept for this building: a second of the kind goes there unasked
    R.setHome(p, up.cat, srcOf(crateA))
    local more = give(p:getInventory(), up.odd:getFullType())
    up.more = more
    local u = R.unpackPlan(p)
    local a, b2 = nil, nil
    for _, e in ipairs(u.loot) do
        if e.item == up.odd then a = e end
        if e.item == more then b2 = e end
    end
    check(a and a.state == "put" and a.dest and a.dest.obj == crateA, "the kind's place is kept: " .. tostring(a and a.dest and a.dest.name))
    check(b2 and b2.state == "put" and b2.dest and b2.dest.obj == crateA, "a second of that kind goes there without asking")
    ZeD.Settings.restockOption:setValue(1)
    local run = R.start(p, "unpack")
    run.z0 = 99
end)
untilDo(function() local r = R.runs[pn]; return r and r.done end, 900, function()
    check(up.odd:getContainer() == crateA:getContainer() and up.more:getContainer() == crateA:getContainer(), "unpack put both in crate A")
    check(onYou(screwdriver), "the gear stays on you")
end, "the unpack run")

-- B7 the pad: the Loadouts ring, A restocks, B back to the bar --------------------
step(10, function()
    local w = cw()
    EL.closeTodo(w)
    local DW = ZeD.DpadWheels
    local top = DW.B.character(p, pn)
    local ring = nil
    for _, e in ipairs(top) do if e.name == ZeD.tr("UI_ZeD_Wheel_Loadouts") then ring = e end end
    check(ring ~= nil and ring.off == nil, "the Character wheel has a live Loadouts ring")
    local subs = ring and ring.sub(p, pn) or {}
    local names = {}
    for _, e in ipairs(subs) do names[#names + 1] = e.name end
    check(#subs == #L.all(p, "loadout"), "one slice per loadout: " .. table.concat(names, ", "))
    ZeD.Settings.restockOption:setValue(2)   -- (Casual: the long haul has takes, so Restock is live)
    for _, e in ipairs(subs) do if e.name == "QA long haul" then e.run(p, pn) end end
end)
step(60, function()
    local w = cw()
    local _, lo = R.current(p)
    check(w._activeTab == "equip" and EL.todoOpen(w) and lo and lo.id == longId, "a slice sets the loadout and opens its to-do")
    local els = EL.focusables(w)
    local v1 = nil
    for _, e in ipairs(els) do if e.id == "el:v1" then v1 = e end end
    check(v1 ~= nil and v1.onActivate ~= nil and v1.onCancel ~= nil, "the to-do's Restock is a stop with A and B")
    local landed = (els._focusIdx and els[els._focusIdx] and els[els._focusIdx].id) or w._gpFocusedEquipSlot
    check(landed == "el:v1", "the focus lands on Restock (the primary): " .. tostring(landed))
    if v1 then v1.onActivate(w, v1) end
    check(R.runs[pn] and R.runs[pn].kind == "restock", "A restocks")
    R.stop(p, "user")
    if v1 then v1.onCancel(w, v1) end
    check(not EL.todoOpen(w), "B goes back")
end)
step(20, function()
    local w = cw()
    local els = {}
    EL.barFocusables(w, els)
    EL.land(w, els)
    local landed = (els._focusIdx and els[els._focusIdx] and els[els._focusIdx].id) or w._gpFocusedEquipSlot
    check(landed == "el:ready", "the focus is back on ready n of m (where the to-do came from): " .. tostring(landed))
end)

-- put back ---------------------------------------------------------------------
step(10, function()
    for _, run in pairs(R.runs) do run.done = true end
    ISTimedActionQueue.clear(p)
    if zed then pcall(function() zed:removeFromWorld(); zed:removeFromSquare() end) end
    -- the things the run made, wherever they are
    for _, it in ipairs(made) do
        pcall(function()
            if p:isEquippedClothing(it) then p:removeWornItem(it) end
            if p:getPrimaryHandItem() == it then p:setPrimaryHandItem(nil) end
            if p:getSecondaryHandItem() == it then p:setSecondaryHandItem(nil) end
            local c = it:getContainer()
            if c then c:Remove(it) end
            local wi = it:getWorldItem()
            if wi then wi:getSquare():transmitRemoveItemFromSquare(wi); wi:removeFromWorld() end
        end)
    end
    -- the character's own: hands as they were, nothing left off
    p:setPrimaryHandItem(mainWas); p:setSecondaryHandItem(offWas)
    for it in pairs(wornBefore) do if not p:isEquippedClothing(it) then pcall(function() p:setWornItem(it:getBodyLocation(), it) end) end end
    for _, b in ipairs(built) do pcall(function() b.sq:transmitRemoveItemFromSquare(b.o) end) end
    for _, s in ipairs(stashed) do pcall(function() s.cont:AddItem(s.item) end) end
    say("put back: " .. #made .. " made things removed, " .. #built .. " built things taken down, " .. #stashed .. " set-aside things returned")
    md.ZeD_Lists = savedLists
    L.gen = L.gen + 1
    R.touch()
    R.runs[pn] = nil
    ZeD.RestockPin.hide(pn)
    ZeD.Settings.restockOption:setValue(restockWas)
    ZeD.EquipDoll.setView(viewWas)
    local w = cw()
    if w then
        EL.closeTodo(w)
        w._activeTab = "loot"; w._drawerOpen = false
    end
    moveTo(HOME.x, HOME.y, HOME.z)
    local left = 0
    for _, it in ipairs(R.allOn(p)) do if not before[it:getID()] then left = left + 1 end end
    check(left == 0, "nothing the run made is left on the character (" .. left .. ")")
end)
step(60, function() say("DONE (" .. fails .. " failed)") end)

local function onTick()
    if qi >= #Q then Events.OnTick.Remove(onTick); return end
    local s = Q[qi + 1]
    if s.still then
        local sh = shape()
        if sh == still.last then still.same = still.same + 1 else still.same, still.last = 0, sh end
        still.waited = still.waited + 1
        if still.same < STILL and still.waited < STILL_MAX then return end
        if still.same < STILL then say("WARN the windows were still moving: captured anyway") end
        still.last, still.same, still.waited = nil, 0, 0
    elseif s.cond then
        wait = wait + 1
        local ok, r = pcall(s.cond)
        if not (ok and r) and wait < s.max then return end
        if not (ok and r) then fails = fails + 1; say("FAIL timed out waiting for " .. tostring(s.what)) end
        wait = 0
    else
        wait = wait + 1
        if wait < s.n then return end
        wait = 0
    end
    qi = qi + 1
    local ok, e = pcall(s.fn)
    if not ok then fails = fails + 1; say("ERR step " .. qi .. " " .. tostring(e)) end
end
Events.OnTick.Add(onTick)
say("start")
