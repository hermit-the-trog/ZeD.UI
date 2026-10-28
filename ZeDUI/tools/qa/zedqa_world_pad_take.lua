-- ZeDUI/tools/qa/zedqa_world_pad_take.lua  (Oct 23 2026)
-- The director's first hands-on pad test of the World window: "hard to access
-- containers ... missing the selection ... the info cards do not land on the
-- action strip ... a simple take action is super difficult". The pad is
-- simulated (Focus.dispatchJoypadDir / dispatchJoypadDown, A = the focused
-- element's onActivate, the call the A resolver makes). With a crate built
-- beside the character (nails, a bandage, a hammer, an apple in it):
--   1. RB into the World window: a focused element exists and is lit;
--      the D-pad across from the Character window's right edge does the same
--   2. the containers: Left from a row lands on the container on show; Down
--      from the ground reaches the crate; A on the crate puts focus on its
--      first item; Left / Right go to the strip and back to the same row
--   3. A on a row opens its card with focus on the card's primary action;
--      Down then Up comes back to it; B goes back to the row
--   4. A on Nails, A on its Take: the nails reach the bag (vanilla transfer)
--   5. an object card (the crate's padlock card): focus on its first live
--      verb, A runs it, B closes the card and the focus is back in the list
--   6. the Character window: LB lands lit, Right to the strip and back, A on
--      a row opens the card on its primary action, A drops the nails
--      (vanilla's drop), B backs out of a card to its row, Left from the
--      World window's strip crosses back
--   7. every tab of both windows at the run's text size and at Large: the
--      tab's lowest control is reached with Down and is fully in view, and
--      the mouse wheel scrolls far enough to show it; the Health tab with six
--      wounds also shows all it drew
-- Everything made is taken away (crate, nails, padlock, wounds, text size).
-- Lines "PASS ..." / "FAIL ..."; grep "ZEDQA wpt".
local p = getPlayer()
local pn = p:getPlayerNum()
local Focus, Det = ZeD.Input.Focus, ZeD.Input.Detector
local function say(s) print("ZEDQA wpt " .. tostring(s)) end
local nPass, nFail = 0, 0
local function check(ok, what)
    if ok then nPass = nPass + 1; say("PASS " .. what) else nFail = nFail + 1; say("FAIL " .. what) end
    return ok
end
local function cw() return ZeD_CharacterWindow.getWindow() end
local function ww() return ZeD_WorldWindow.getWindow() end
local function fw() return Focus.getFocusedWindow() end
local function wname(w) return (w == cw() and "Char") or (w == ww() and "World") or tostring(w) end
local function cur()
    local w = fw(); local z = w and Focus.getFocusedZone(w); local e = w and Focus.getFocusedElement(w)
    return w, z, e
end
local function where(tag)
    local w, z, e = cur()
    say(tag .. ": " .. wname(w) .. " " .. tostring(z and z.zone) .. ":" .. tostring(e and e.id)
        .. ((e and e.item) and (" (" .. e.item:getName() .. ")") or ""))
end
-- lit: the element the paint code would light (a row is lit through its panel's _gpFocusedRowItem)
local function lit(w)
    local z = Focus.getFocusedZone(w); local e = Focus.getFocusedElement(w)
    if not (z and e and z.focusable) then return false end
    if z.zone:match("MainInv$") then
        local c = w._mainContent
        return e.item ~= nil and c ~= nil and c._gpFocusedRowItem == e.item
    end
    return true
end
local function dir(d) Focus.dispatchJoypadDir(fw(), d) end
local function btn(b) Focus.dispatchJoypadDown(fw(), b) end
local function A() local w, _, e = cur(); if e and e.onActivate then e.onActivate(w, e) end end
local function stripTab(w, strip, id)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. id then if w._activeTab ~= id then strip:onMouseDown(z.x + 2, z.y + 2) end; return true end
    end
end
local function tabsOf(strip)
    local out = {}
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if type(z.id) == "string" and z.id:sub(1, 4) == "tab:" then out[#out + 1] = z.id:sub(5) end
    end
    return out
end

-- the step queue: each step runs, then waits n ticks; a step may queue more right after itself
local Q, qi, waitT = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function insertNext(n, fn) table.insert(Q, qi + 1, { n = n, fn = fn }) end

-- the crate
local function findInfo(full)
    local infos = SpriteConfigManager.GetObjectInfoList()
    for i = 0, infos:size() - 1 do
        local info = infos:get(i)
        local parent = info:getScript() and info:getScript():getParent()
        if parent and tostring(parent:getScriptObjectFullType()) == full then return info end
    end
end
local MINE = { ["Base.Nails"] = true, ["Base.Bandage"] = true, ["Base.Hammer"] = true, ["Base.Apple"] = true, ["Base.TinnedBeans"] = true,
    ["Base.Eraser"] = true, ["Base.Tweezers"] = true, ["Base.Corkscrew"] = true }
-- (the test's own things: kinds the deep-run fixture never stocks, so each is
-- one row of its own, never a stack: an eraser stands for the nails (plain, so
-- its card leads with Take; scissors count as a weapon and lead with Equip), tweezers for
-- the bandage, a corkscrew for the hammer in the messages below)
local walk2 = 0
local function onlyMine(c)
    local items = c:getItems()
    for i = 0, items:size() - 1 do if not MINE[items:get(i):getFullType()] then return false end end
    return true
end
-- crates left by this script's own earlier runs (or its probes): only test things in them
local function sweepOldCrates()
    local px, py = math.floor(p:getX()), math.floor(p:getY())
    local n = 0
    for dy = -2, 2 do for dx = -2, 2 do
        local sq = getCell():getGridSquare(px + dx, py + dy, 0)
        local objs = sq and sq:getObjects()
        for i = (objs and objs:size() or 0) - 1, 0, -1 do
            local o = objs:get(i)
            if instanceof(o, "IsoThumpable") and tostring(o:getName()) == "Wood_Crate_Lvl1" and o:getContainer()
               and onlyMine(o:getContainer()) and not o:isLockedByPadlock() and (o:getLockedByCode() or 0) == 0 then
                o:getContainer():removeAllItems()
                sq:transmitRemoveItemFromSquare(o)
                n = n + 1
            end
        end
    end end
    if n > 0 then say("swept " .. n .. " old test crate(s)") end
end
local crate, crateInv
local function buildCrate()
    local info = findInfo("Base.Wood_Crate_Lvl1")
    if not info then return nil end
    local px, py = math.floor(p:getX()), math.floor(p:getY())
    for _, o in ipairs({ { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 }, { 1, 1 }, { -1, 1 } }) do
        local sq = getCell():getGridSquare(px + o[1], py + o[2], 0)
        if sq then
            p:setBuildCheat(true)
            local b = ISBuildIsoEntity:new(p, info, 1, ISInventoryPaneContextMenu.getContainers(p))
            b.buildCheat = true; b.player = pn; b.sq = sq
            local ok, valid = pcall(function() return b:isValid(sq) end)
            if ok and valid then pcall(function() b:create(px + o[1], py + o[2], 0, false, nil) end) end
            p:setBuildCheat(false)
            if ok and valid then return sq end
        end
    end
    return nil
end
local crateSq
local deepCrate = false   -- (the deep-run fixture's crate: only what this run adds is taken back)
local added = {}
local takenNails, padlock
local wounds = { "Hand_L", "ForeArm_R", "UpperLeg_L", "Foot_R", "Torso_Upper", "Head" }
local origSize = ZeD.currentSize

-- find a zone's element
local function elIn(w, zoneName, pred)
    for _, z in ipairs(w._focusRing or {}) do
        if z.zone == zoneName then
            for i, e in ipairs(z.elements or {}) do if pred(e, i) then return e, i, z end end
        end
    end
end
local function rowOf(w, zoneName, fullType)
    return elIn(w, zoneName, function(e) return e.item ~= nil and e.item:getFullType() == fullType end)
end
-- the focus ring in a line (when a row is not found): each zone, focusable or not, its count
local function ringSay(w)
    local out = {}
    for _, z in ipairs(w and w._focusRing or {}) do
        out[#out + 1] = tostring(z.zone) .. (z.focusable and "" or "(off)") .. "=" .. #(z.elements or {})
    end
    return table.concat(out, " ") .. "; card " .. tostring(w and (w._drawerItem ~= nil or w._drawerObject ~= nil))
end

-- ---------------------------------------------------------------- setup
step(20, function()
    Det.setLockedMode(Det.MODE_GAMEPAD)
    if not (cw() and cw():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(pn) end
    -- nothing to attack or block the character (the QA save's cell has strays)
    local zl = getCell():getZombieList()
    local nz = zl:size()
    for i = nz - 1, 0, -1 do
        local z = zl:get(i)
        if z then pcall(function() z:removeFromWorld() end); pcall(function() z:removeFromSquare() end) end
    end
    p:setGodMod(true); p:setInvisible(true)
    pcall(function() p:getBodyDamage():RestoreToFullHealth() end)
    say("scene: " .. nz .. " zombies removed, save " .. tostring(getWorld():getWorld()))
    sweepOldCrates()
end)
step(75, function()   -- (the World window's list looks for containers every 30 frames)
    -- the deep-run scene's crate when the save has one (zedqa_deep_run.lua),
    -- else one built for the run
    local px0, py0 = math.floor(p:getX()), math.floor(p:getY())
    for dy = -1, 1 do for dx = -1, 1 do
        local sq = getCell():getGridSquare(px0 + dx, py0 + dy, 0)
        local objs = sq and sq:getObjects()
        for i = 0, (objs and objs:size() or 0) - 1 do
            local o = objs:get(i)
            local t
            pcall(function() t = o:getModData().ZeDDeepRun end)
            if t == "near_crate" then crate, crateSq, deepCrate = o, sq, true end
        end
    end end
    if not crate then
        crateSq = buildCrate()
        local objs = crateSq and crateSq:getObjects()
        for i = 0, (objs and objs:size() or 0) - 1 do
            local o = objs:get(i)
            if instanceof(o, "IsoThumpable") and o:getContainer() then crate = o end
        end
    end
    crateInv = crate and crate:getContainer()
    if not check(crateInv ~= nil, deepCrate and "the deep run's crate is beside the character" or "a crate was built beside the character") then return end
    for _, t in ipairs({ "Base.Eraser", "Base.Tweezers", "Base.Corkscrew", "Base.Apple" }) do added[#added + 1] = crateInv:AddItem(t) end
    stripTab(cw(), cw()._tabStripPanel, "loot"); stripTab(ww(), ww()._actionTabStrip, "loot")
end)
-- the ground on show in the World window (so the crate is the next container down)
step(60, function()
    local w = ww()
    local floor = elIn(w, "worldContainerStrip", function(e) local c = w._containers[e.containerIdx]; return c and c.isFloor end)
    local cr = elIn(w, "worldContainerStrip", function(e) return e.inventory == crateInv end)
    local names = {}
    for i, c in ipairs(w._containers or {}) do names[#names + 1] = i .. ":" .. tostring(c.name) .. ((c.inventory == crateInv) and "(ours)" or "") end
    local stops = {}
    for _, z in ipairs(w._focusRing or {}) do
        if z.zone == "worldContainerStrip" then
            for _, e in ipairs(z.elements or {}) do stops[#stops + 1] = tostring(e.id) .. "@" .. math.floor(e.y) end
        end
    end
    say("containers " .. table.concat(names, ", ") .. " | stops " .. table.concat(stops, ", "))
    check(cr ~= nil, "the crate has a stop in the World window's container strip (stops follow the list)")
    if floor then floor.onActivate(w, floor) end
    Focus.claimFocus(cw())
    Focus.focusWhere(cw(), "charMainInv", function(e) return e.item ~= nil end)
end)

-- ---------------------------------------------------------------- 1. into the World window
step(10, function() btn(Joypad.RBumper) end)
step(10, function()
    local w = fw(); where("1 after RB")
    check(w == ww() and lit(w), "RB lands in the World window on a lit element")
    btn(Joypad.LBumper)
end)
step(10, function()
    -- the D-pad across: from the Character window's container strip, Right
    local c = cw()
    Focus.focusWhere(c, "charContainerStrip", function() return true end)
    where("1 on the Character window's strip")
    dir("right")
end)
step(10, function()
    local w = fw(); where("1 Right from the Character window's right edge")
    check(w == ww() and lit(w), "the D-pad across from the Character window lands in the World window, lit")
end)

-- ---------------------------------------------------------------- 2. the containers
step(5, function()
    local w = ww()
    -- from a row of the list (the ground's, when it has any), Left reaches the
    -- strip on the container on show (the ground)
    -- (the ground may be bare: then from the buttons under the list, Left, Left)
    if not Focus.focusWhere(w, "worldMainInv", function(x) return x.item ~= nil end) then
        Focus.focusWhere(w, "worldCtl", function() return true end)
    end
    for _ = 1, 4 do
        local _, z = cur()
        if z and z.zone == "worldContainerStrip" then break end
        dir("left")
    end
    local _, z2, e2 = cur(); where("2 strip")
    local c = e2 and w._containers[e2.containerIdx]
    check(z2 and z2.zone == "worldContainerStrip" and c and c.isFloor, "on the strip, focus is on the container on show (the ground)")
    -- Down walks the containers under the ground, one per press, to the crate
    -- (with the deep-run scene there are several before it)
    local presses = 0
    for _ = 1, 10 do
        local _, z3, e3 = cur()
        if z3 and z3.zone == "worldContainerStrip" and e3 and e3.inventory == crateInv then break end
        dir("down"); presses = presses + 1
    end
    walk2 = presses
end)
step(5, function()
    local _, z, e = cur(); where("2 Down x" .. tostring(walk2))
    check(z and z.zone == "worldContainerStrip" and e and e.inventory == crateInv, "Down from the ground reaches the crate (" .. tostring(walk2) .. " presses)")
    A()
end)
step(30, function()
    local w, z, e = cur(); where("2 after A on the crate")
    check(z and z.zone == "worldMainInv" and e and e.item and e.item:getContainer() == crateInv and lit(w),
        "A on the crate puts focus on its first item, lit")
    local first = e and e.id
    dir("left")
    local _, z2, e2 = cur(); where("2 Left")
    check(z2 and z2.zone == "worldContainerStrip" and e2 and e2.inventory == crateInv, "Left from the list lands on the crate (the container on show)")
    dir("right")
    local _, z3, e3 = cur(); where("2 Right")
    check(z3 and z3.zone == "worldMainInv" and e3 and e3.id == first, "Right goes back to the same row")
    -- a row further down: Left still lands on the container on show
    local row = rowOf(w, "worldMainInv", "Base.Apple") or rowOf(w, "worldMainInv", "Base.Corkscrew")
    Focus.focusWhere(w, "worldMainInv", function(x) return x == row end)
    dir("left")
    local _, z4, e4 = cur(); where("2 Left from a lower row")
    check(z4 and z4.zone == "worldContainerStrip" and e4 and e4.inventory == crateInv, "Left from a lower row lands on the crate too")
    dir("right")
    local _, _, e5 = cur()
    check(e5 == row, "and Right goes back to that row")
end)

-- ---------------------------------------------------------------- 3. a card: primary action, Down / Up, B
local function cardPrimaryCheck(w, zoneName, tag)
    local _, z, e = cur()
    local card = w._itemCard
    local hi = e and e.id and tonumber(tostring(e.id):match("^hverb_(%d+)$") or "")
    local v = hi and card and card._lastHeaderVerbs and card._lastHeaderVerbs[hi]
    where(tag)
    check(z and z.zone == zoneName and e and e.isPrimary and v ~= nil,
        tag .. ": focus is on the card's primary action (" .. tostring(v and v.id) .. ")")
    return v and v.id
end
step(20, function()   -- (the card draws before its buttons exist: about 8 ticks at 4K)
    local w = ww()
    local row = rowOf(w, "worldMainInv", "Base.Tweezers")
    Focus.focusWhere(w, "worldMainInv", function(x) return x == row end)
    A()
    -- (diagnostic, Oct 27 2026: ticks and drawn frames from A until the card's zone has its
    -- buttons and until focus is in it; the check below looks 20 ticks after A)
    local t, f, zoneAt, focusAt, lastSig = 0, 0, nil, nil, nil
    local function onFrame() f = f + 1 end
    local function watch()
        t = t + 1
        local z = nil
        for _, zz in ipairs(w._focusRing or {}) do if zz.zone == "worldItemCard" then z = zz end end
        if not zoneAt and z and z.focusable and z.elements and #z.elements > 0 then zoneAt = t .. " ticks, " .. f .. " frames" end
        local fz = Focus.getFocusedZone(w)
        if not focusAt and fz and fz.zone == "worldItemCard" then focusAt = t .. " ticks, " .. f .. " frames" end
        if t >= 60 or (zoneAt and focusAt) then
            Events.OnTick.Remove(watch); Events.OnRenderTick.Remove(onFrame)
            say("3 timing: card buttons ready after " .. tostring(zoneAt) .. "; focus in the card after " .. tostring(focusAt) .. " (watched " .. t .. " ticks, " .. f .. " frames)")
        end
    end
    Events.OnTick.Add(watch); Events.OnRenderTick.Add(onFrame)
end)
step(20, function()
    local w = ww()
    cardPrimaryCheck(w, "worldItemCard", "3 A on the bandage")
    local _, _, prim = cur()
    dir("down")
    local _, z1, e1 = cur(); where("3 Down in the card")
    check(z1 and z1.zone == "worldItemCard" and e1 ~= prim, "Down moves to the card's next control")
    dir("up")
    local _, z2, e2 = cur(); where("3 Up")
    check(z2 and z2.zone == "worldItemCard" and e2 and e2.isPrimary, "Up from inside the card is back on the primary action in one press")
    btn(Joypad.BButton)
end)
step(10, function()
    local w, z, e = cur(); where("3 after B")
    check(z and z.zone == "worldMainInv" and e and e.item and e.item:getFullType() == "Base.Tweezers" and w._drawerItem == nil and lit(w),
        "B closes the card and focus is back on the bandage row, lit")
end)

-- ---------------------------------------------------------------- 4. Take
step(20, function()
    local w = ww()
    local row = rowOf(w, "worldMainInv", "Base.Eraser")
    takenNails = row and row.item
    Focus.focusWhere(w, "worldMainInv", function(x) return x == row end)
    A()
end)
step(20, function()
    local id = cardPrimaryCheck(ww(), "worldItemCard", "4 A on the nails")
    check(id == "TAKE", "the nails' card offers Take as its primary action")
    A()   -- the primary action
end)
local takeWait = 0
local function waitTake()
    takeWait = takeWait + 1
    local inBag = takenNails and takenNails:getContainer() == p:getInventory()
    if inBag or takeWait > 60 then
        check(inBag, "A on Take moved the nails into the bag (vanilla's transfer, " .. (takeWait * 10) .. " ticks)")
        where("4 after the take")
        return
    end
    insertNext(10, waitTake)
end
step(10, waitTake)

-- ---------------------------------------------------------------- 5. an object card
step(5, function()
    local w = ww()
    -- close an item card still showing (the list takes its room back on the next frames:
    -- at 1080p the card hides it), then a row, then the padlock card on the crate
    local cnt = w._mainContent
    if cnt and w._drawerItem then cnt._selectedItems = {}; cnt._lastClickedItem = nil; w._updateDrawer() end
end)
step(10, function()
    local w = ww()
    local row = elIn(w, "worldMainInv", function(e) return e.item ~= nil end)
    Focus.focusWhere(w, "worldMainInv", function(x) return x == row end)
    if not row then say("5 no row in the World window's list: " .. ringSay(w)) end
    where("5 before the padlock card")
    padlock = p:getInventory():AddItem("Base.CombinationPadlock")
    ZeD.ObjectCardLock.openFor(p, crate, false)
end)
step(30, function()
    local w, z, e = cur(); where("5 the padlock card")
    local oc = w._objectCard
    local entry = oc and oc.entry
    local want
    for i, v in ipairs(entry and entry.t and entry.t.verbs or {}) do
        if v.primary and v.enabled ~= false then want = "oc:verb:" .. tostring(v.id or i); break end
    end
    if not want then
        for i, v in ipairs(entry and entry.t and entry.t.verbs or {}) do
            if v.enabled ~= false then want = "oc:verb:" .. tostring(v.id or i); break end
        end
    end
    check(z and z.zone == "worldItemCard" and e and e.id == want, "the object card opens with focus on its main live verb (" .. tostring(want) .. ")")
    A()
end)
step(15, function()
    local w = ww(); local oc = w._objectCard
    local t = oc and oc.entry and oc.entry.t
    check(t and t.setting == true, "A on it ran the verb (the padlock's code wheel shows)")
    btn(Joypad.BButton)
end)
step(15, function()
    local w, z, e = cur(); where("5 after B")
    check(w._drawerObject == nil and z and z.zone == "worldMainInv" and lit(w), "B closes the object card and focus is back in the list, lit")
    if padlock then p:getInventory():Remove(padlock); padlock = nil end
end)

-- ---------------------------------------------------------------- 6. the Character window
step(5, function()
    local w = ww()
    Focus.focusWhere(w, "worldContainerStrip", function(e) return e.inventory == crateInv end)
    dir("left")   -- the World window's left edge: across to the Character window
end)
step(10, function()
    local w = fw(); where("6 Left from the World window's strip")
    check(w == cw() and lit(w), "the D-pad across from the World window lands in the Character window, lit")
    btn(Joypad.RBumper)
end)
step(5, function() btn(Joypad.LBumper) end)
step(20, function()
    local w = fw(); where("6 LB")
    check(w == cw() and lit(w), "LB lands in the Character window on a lit element")
    local row = rowOf(w, "charMainInv", "Base.Eraser")
    Focus.focusWhere(w, "charMainInv", function(x) return x == row end)
    dir("right")
    local _, z, e = cur(); where("6 Right")
    local want = w._viewedContainer or w._activeContainer
    check(z and z.zone == "charContainerStrip" and e and e.containerIdx == want, "Right from a row lands on the bag on show")
    dir("left")
    local _, z2, e2 = cur()
    check(z2 and z2.zone == "charMainInv" and e2 == row, "Left goes back to the same row")
    A()
end)
step(20, function()
    local id = cardPrimaryCheck(cw(), "charItemCard", "6 A on the nails")
    dir("down"); dir("up")
    local _, _, e = cur()
    check(e and e.isPrimary, "Down then Up in the Character window's card is back on its primary action")
    say("6 primary is " .. tostring(id) .. "; A runs it")
    A()
end)
local dropWait = 0
local function waitDrop()
    dropWait = dropWait + 1
    local gone = takenNails and takenNails:getContainer() ~= p:getInventory()
    if gone or dropWait > 60 then
        check(gone, "A on the card's primary action (Drop) moved the nails out of the bag (" .. (dropWait * 10) .. " ticks)")
        return
    end
    insertNext(10, waitDrop)
end
step(10, waitDrop)
step(10, function()
    local w = cw()
    local cnt = w._mainContent
    if cnt and w._drawerItem then cnt._selectedItems = {}; cnt._lastClickedItem = nil; w._updateDrawer(cnt) end
end)
step(20, function()
    local w = cw()
    -- a single thing, not a stack (A on a stack opens the stack, not a card)
    local row = elIn(w, "charMainInv", function(e)
        local s = w._mainContent and w._mainContent._stacks and w._mainContent._stacks[e.item]
        return e.item ~= nil and not (s and s.count > 1)
    end)
    Focus.focusWhere(w, "charMainInv", function(x) return x == row end)
    A()
end)
step(20, function()
    cardPrimaryCheck(cw(), "charItemCard", "6 A on a row")
    local _, _, e0 = cur()
    btn(Joypad.BButton)
    local w, z, e = cur(); where("6 after B")
    check(z and z.zone == "charMainInv" and e and e.item and w._drawerItem == nil, "B on the Character window's card goes back to the row")
end)

-- ---------------------------------------------------------------- 8. focus returns to the start (director's rule 1)
-- X (context menu) then B: back on the same row
local walk = {}
step(10, function()
    local w = ww()
    Focus.claimFocus(w)
    local row = rowOf(w, "worldMainInv", "Base.Corkscrew")
    Focus.focusWhere(w, "worldMainInv", function(x) return x == row end)
    if not row then say("8 no corkscrew row in the World window's list: " .. ringSay(w)) end
    walk.ctxRow = row and row.item
    if row and row.onContextMenu then row.onContextMenu(w, row) end
end)
step(20, function()
    local vm = getPlayerContextMenu and getPlayerContextMenu(pn)
    local zm = vm and vm._zedMenu
    check(zm ~= nil, "8 X on a row opens the context menu")
    if zm and zm.onJoypadDown then zm:onJoypadDown(Joypad.BButton) elseif vm then vm:setVisible(false) end
end)
step(10, function()
    local w, z, e = cur(); where("8 after the menu's B")
    check(w == ww() and z and z.zone == "worldMainInv" and e and e.item == walk.ctxRow and lit(w), "8 the menu closed: focus is back on the same row, lit")
end)
-- hold A (vanilla's double-click: the hammer to the bag): focus stays in the list, on a neighbour
step(5, function()
    local w = ww()
    local row = rowOf(w, "worldMainInv", "Base.Corkscrew")
    walk.moved = row and row.item
    Focus.focusWhere(w, "worldMainInv", function(x) return x == row end)
    if row and row.onHoldActivate then row.onHoldActivate(w, row) end
end)
local holdWait = 0
local function waitHold()
    holdWait = holdWait + 1
    local moved = walk.moved and walk.moved:getContainer() ~= crateInv
    if moved or holdWait > 60 then
        local w, z, e = cur(); where("8 after hold A")
        check(moved, "8 hold A moved the hammer out of the crate")
        insertNext(20, function()
            local w2, z2, e2 = cur(); where("8 a moment later")
            check(w2 == ww() and z2 and (z2.zone == "worldMainInv" or z2.zone == "worldCtl") and e2 and lit(w2),
                "8 after the transfer focus is on a neighbour in the same panel, lit")
            if walk.moved and walk.moved:getContainer() then walk.moved:getContainer():Remove(walk.moved) end
        end)
        return
    end
    insertNext(10, waitHold)
end
step(10, waitHold)
-- the belt: not by accident from a window; out with one press
step(30, function()
    local B = ZeD.Belt
    local hud = B and B._hud
    if not (hud and hud._drawn) then say("8 the belt is not drawn: skipped"); return end
    local w = cw()
    Focus.claimFocus(w)
    -- a Left that reached the game while a window holds the pad (a prompt let the focus go)
    ISDPadWheels.onDisplayLeft({ player = 0, id = 0 })
    check(hud._gp == nil and fw() == w, "8 a stray Left with a window open stays in the window (no way into the belt)")
    Focus.releaseFocus()
    -- (Oct 23 2026: D-pad Left is the Character wheel now, DPAD_WHEELS_SPEC; the
    -- belt is entered through its own call below, its ways out are the same)
    ISDPadWheels.onDisplayLeft({ player = 0, id = 0 })
    local DW = ZeD.DpadWheels
    check(hud._gp == nil and DW and DW.state[0] ~= nil and DW.state[0].dir == "left", "8 with the windows put away, Left opens the Character wheel (not the belt)")
    if DW and DW.state[0] then DW.close(0) end
    B.focus(0)
    if hud._gp then
        hud:onJoypadDown(Joypad.BButton)
        check(hud._gp == nil, "8 B leaves the belt in one press")
    end
    B.focus(0)
    if hud._gp then
        hud._gp.idx = #hud._boxes
        hud:onJoypadDirRight()
        check(hud._gp == nil, "8 Right past the belt's last box leaves it")
    end
    B.focus(0)
    if hud._gp then
        hud:onJoypadDirDown()
        check(hud._gp == nil, "8 Down (the screen's edge) leaves the belt")
    end
    if hud._gp then hud:_leavePad() end
    Focus.claimFocus(cw())
end)

-- ---------------------------------------------------------------- 7. every tab: the bottom, by pad and by wheel
local tabList, ti, sizes, si = {}, 0, { origSize, "large" }, 1
local function woundsOn(on)
    local bd = p:getBodyDamage()
    for _, n in ipairs(wounds) do
        local bp = bd:getBodyPart(BodyPartType.FromString(n))
        if bp then
            pcall(function() bp:setScratched(on, true) end)
            pcall(function() bp:setCut(on) end)
            if not on then pcall(function() bp:setScratchTime(0); bp:setCutTime(0); bp:setBleedingTime(0); bp:setBleeding(false) end) end
        end
    end
end
local function contentZone(w) return (w == cw()) and "charTabContent" or "worldTabContent" end
local function bottomOf(e) return (e.y or 0) + (e.h or 0) end
local function lowest(w)
    local best
    for _, z in ipairs(w._focusRing or {}) do
        if z.zone == contentZone(w) and z.focusable then
            for _, e in ipairs(z.elements or {}) do
                if type(e.y) == "number" and (not best or bottomOf(e) > bottomOf(best)) then best = e end
            end
        end
    end
    return best
end
-- the lowest control overlapping e across (its column)
local function lowestInColumn(w, e)
    local best
    for _, z in ipairs(w._focusRing or {}) do
        if z.zone == contentZone(w) and z.focusable then
            for _, x in ipairs(z.elements or {}) do
                if type(x.y) == "number" and (x.x or 0) < (e.x or 0) + (e.w or 0) and (x.x or 0) + (x.w or 0) > (e.x or 0)
                   and (not best or bottomOf(x) > bottomOf(best)) then best = x end
            end
        end
    end
    return best
end
local function auditTab(done)
    local item = tabList[ti]
    if not item then return end
    local w, id = item.w, item.id
    local tag = string.format("7 %s %s %s", wname(w), id, tostring(sizes[si]))
    local zn = contentZone(w)
    local low = lowest(w)
    if not low then say(tag .. ": no controls in the tab"); insertNext(5, done); return end
    -- the pad: from the tab's first control, Down until it leaves the tab
    Focus.claimFocus(w)
    local first = elIn(w, zn, function(e) return not e.isDisclosure end) or elIn(w, zn, function() return true end)
    Focus.focusWhere(w, zn, function(e) return e == first end)
    walk = { w = w, zn = zn, tag = tag, presses = 0, last = first and first.id, same = 0, done = done }
    local function press()
        local _, z, e = cur()
        if walk.presses >= 45 or not z or z.zone ~= walk.zn or walk.same >= 2 then
            -- back on the last control reached in the tab, let the scroll follow it, then look
            local lastId = walk.last
            Focus.focusWhere(walk.w, walk.zn, function(x) return x.id == lastId end)
            insertNext(15, function()
                local ww2 = walk.w
                local dp = ww2._drawerPanel
                local e2 = elIn(ww2, walk.zn, function(x) return x.id == lastId end)
                -- the lowest control of the column the walk ended in: Down stays in its
                -- column, a two-column tab's other column is reached with Right (Health at
                -- Large text: the exercise buttons end a few px below the figure's feet)
                local lo = e2 and lowestInColumn(ww2, e2) or lowest(ww2)
                local inView = e2 and e2.y >= 0 and bottomOf(e2) <= dp:getHeight() + 1
                local isLowest = e2 and lo and bottomOf(e2) >= bottomOf(lo) - 2
                check(inView and isLowest, string.format("%s pad: Down reaches the lowest control of its column %s and it is in view (bottom %s of %d)",
                    walk.tag, tostring(lastId), tostring(e2 and math.floor(bottomOf(e2))), dp:getHeight()))
                -- the wheel: all the way down
                for _ = 1, 60 do pcall(dp.onMouseWheel, dp, 1) end
                insertNext(15, function()
                    local lo2 = lowest(ww2)
                    check(lo2 and bottomOf(lo2) <= dp:getHeight() + 1 and lo2.y >= 0,
                        string.format("%s wheel: the lowest control %s is in view at the bottom (bottom %s of %d)",
                            walk.tag, tostring(lo2 and lo2.id), tostring(lo2 and math.floor(bottomOf(lo2))), dp:getHeight()))
                    if ww2 == cw() and ww2._activeTab == "health" then
                        local sc = ww2._healthScroll
                        -- at the end of the scroll, what was drawn ends inside the view
                        local shown = sc and (not sc.visible or (sc.scrollPos >= 0.999))
                        local span = (sc and sc.visible and sc.barSizeRatio and sc.barSizeRatio > 0) and (sc.height / sc.barSizeRatio) or 0
                        check(shown and (ww2._healthDrawnH or 0) > 0 and (not sc.visible or span + 1 >= (ww2._healthDrawnH or 0)),
                            string.format("%s Health: scrolled to the end, drawn %d px in a %d px view", walk.tag,
                                math.floor(ww2._healthDrawnH or 0), math.floor(sc and sc.height or 0)))
                    end
                    for _ = 1, 60 do pcall(dp.onMouseWheel, dp, -1) end
                    insertNext(5, walk.done)   -- (the next tab, once this one is done)
                end)
            end)
            return
        end
        if e and e.id == walk.last then walk.same = walk.same + 1 else walk.same = 0 end
        if e and z.zone == walk.zn then walk.last = e.id end
        walk.presses = walk.presses + 1
        dir("down")
        insertNext(3, press)
    end
    insertNext(3, press)
end
local function nextTab()
    ti = ti + 1
    local item = tabList[ti]
    if not item then
        if si < #sizes then
            si = si + 1
            ZeD.applyTheme(nil, nil, sizes[si])
            ti = 0
            insertNext(40, nextTab)
        end
        return
    end
    local strip = (item.w == cw()) and cw()._tabStripPanel or ww()._actionTabStrip
    stripTab(item.w, strip, item.id)
    insertNext(90, function() auditTab(nextTab) end)   -- (the drawer's open animation done)
end
step(10, function()
    woundsOn(true)
    for _, id in ipairs(tabsOf(cw()._tabStripPanel)) do if id ~= "loot" then tabList[#tabList + 1] = { w = cw(), id = id } end end
    for _, id in ipairs(tabsOf(ww()._actionTabStrip)) do if id ~= "loot" then tabList[#tabList + 1] = { w = ww(), id = id } end end
    say("7 tabs: " .. #tabList .. " at " .. tostring(origSize) .. " and large")
    nextTab()
end)

-- ---------------------------------------------------------------- put back
step(10, function()
    ZeD.applyTheme(nil, nil, origSize)
    woundsOn(false)
    stripTab(cw(), cw()._tabStripPanel, "loot"); stripTab(ww(), ww()._actionTabStrip, "loot")
    -- the nails (dropped on the ground) and the crate
    if takenNails then
        local wio = takenNails.getWorldItem and takenNails:getWorldItem()
        if wio and wio:getSquare() then pcall(function() wio:getSquare():transmitRemoveItemFromSquare(wio) end) end
        local c = takenNails:getContainer()
        if c then pcall(function() c:Remove(takenNails) end) end
    end
    if padlock then p:getInventory():Remove(padlock) end
    if deepCrate then
        -- the fixture's crate stays: only what this run put in comes out (wherever it went)
        for _, it in ipairs(added) do
            local c = it and it:getContainer()
            if c then pcall(function() c:Remove(it) end) end
            local wio = it and it.getWorldItem and it:getWorldItem()
            if wio and wio:getSquare() then pcall(function() wio:getSquare():transmitRemoveItemFromSquare(wio) end) end
        end
    elseif crate and crate:getSquare() then
        crate:getContainer():removeAllItems()
        crate:getSquare():transmitRemoveItemFromSquare(crate)
    end
end)
step(10, function()
    local w = ww()
    local cr = w and elIn(w, "worldContainerStrip", function(e) return e.inventory == crateInv end)
    local still = false
    local objs = crateSq and crateSq:getObjects()
    for i = 0, (objs and objs:size() or 0) - 1 do if objs:get(i) == crate then still = true end end
    say("cleanup: " .. (deepCrate and "the deep run's crate kept, this run's things out" or ("crate gone " .. tostring(not still))) .. ", size " .. tostring(ZeD.currentSize))
    Det.setLockedMode(Det.MODE_KBM); Det.setLockedMode(nil)
    say(nPass .. " passed, " .. nFail .. " failed")
    say("DONE")
end)

local function onTick()
    if waitT > 0 then waitT = waitT - 1; return end
    qi = qi + 1
    local s = Q[qi]
    if not s then Events.OnTick.Remove(onTick); return end
    local ok, e = pcall(s.fn)
    if not ok then say("ERR step " .. qi .. " " .. tostring(e)) end
    waitT = s.n
end
Events.OnTick.Add(onTick)
say("start")
