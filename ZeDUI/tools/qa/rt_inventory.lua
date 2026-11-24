-- ZeDUI/tools/qa/rt_inventory.lua  (Nov 18 2026, QA): the release test's inventory (RELEASE_TEST.md, rt_inventory.lua).
-- The inventory in the Character window and the loot in the World window: InventoryRenderer.lua, GridLayout.lua,
-- InventoryFilter.lua, ContainerControls.lua, ZeD_BoxSelect.lua and the windows' own mouse handlers.
-- On the drag strip a crate is set beside the character (an IsoObject, as zedqa_onepath.lua made one) with planks,
-- beans (a stack of three), a saucepan, a crowbar, bandages and a rope in it; one pan-like thing is given to the bag.
--   1. sort: every key (name, category, condition, weight), each way, pressed on the list's own heading in both
--      windows; the rows must stand in the key's order (the renderer's rules, zedqa_sort_groups.lua's checks);
--   2. list and grid: every thing the container shows has a drawn row / cell (the rows' and cells' places stamped
--      by the renderer), a stack's row standing for its whole stack; the view button flips the view;
--   3. the filter: its button opens the bar, the typed text marks the rows that match (the rest dim), Clear and the
--      button put it away;
--   4. a stack: its row shows the total weight in brackets (zedqa_wt_bracket.lua), its triangle opens it, every
--      thing gets its own row under a header that keeps the total;
--   5. box select: a box drawn from the empty space over the rows selects every row it crosses;
--   6. moving: the pan dragged from the bag onto the World window's list and back (the windows' own press and
--      release handlers; the pointer's place is the one thing faked: the target list answers "the pointer is over
--      me"), then Move To from its right-click menu both ways (ZeD's Move To); each time the counts must agree once
--      the game's transfer action is done (the timed action queue empty);
--   7. the container buttons: Loot all (the World window), Transfer all (the Character window), To floor.
-- Everything is put back: the sorts, the views, the filter, the scroll, the columns, the tabs, the bag's own things,
-- the crate and what was in it, the floor. Timed actions run instant for the run (put back after).
-- Copy to Zomboid/Lua/ after rt_kit.lua; grep "ZEDQA rt_inv".
-- (Nov 23 2026, QA: the Loadouts split moves Loadouts, Restock and their switches to the add-on ZeD-GUI: Loadouts;
-- H.loadOpt() reads its ZeDLoadouts.loadoutsOption / restockOption where it is loaded, else ZeD.Settings' from
-- before the split. With neither, ZeD alone after the split, the restock pin is a SKIP.)

local Q = RT.make("rt_inv")
local S = { p = RT.p, pn = RT.pn, crateGiven = {}, scroll = {}, grid = {}, dead = false }
local H = {}
-- the table that holds the Loadouts and Restock switches: the add-on's ZeDLoadouts (since the split), else ZeD.Settings
function H.loadOpt()
    local LO = ZeDLoadouts
    if type(LO) == "table" and LO.loadoutsOption then return LO end
    return ZeD.Settings
end
local NIL = {}

-- a step that does nothing once the setup failed (the put-back steps use Q.step itself)
local function step(n, fn) Q.step(n, function() if S.dead then return end; fn() end) end
local function waitFor(n, max, cond, fn)
    Q.waitFor(n, max, function() if S.dead then return true end; return cond() end,
        function(ok) if S.dead then return end; fn(ok) end)
end

-- ===================================================================== small helpers
function H.cc() local w = RT.cw(); return w and w._mainContent end
function H.wc() local w = RT.ww(); return w and w._mainContent end
function H.list(inv)
    local out = {}
    pcall(function()
        local it = inv:getItems()
        for i = 0, it:size() - 1 do out[#out + 1] = it:get(i) end
    end)
    return out
end
function H.size(inv) local n = -1; pcall(function() n = inv:getItems():size() end); return n end
function H.where(it) local c = nil; pcall(function() c = it:getContainer() end); return c end
function H.queueEmpty()
    local q = nil
    pcall(function() q = ISTimedActionQueue.getTimedActionQueue(S.p) end)
    return not q or not q.queue or #q.queue == 0
end
function H.held(it)
    local h = false
    pcall(function() h = it:isEquipped() or S.p:isEquipped(it) end)
    return h and true or false
end
function H.zone(c, id)
    for _, z in ipairs(c and c._hitZones or {}) do if z.id == id then return z end end
    return nil
end
function H.zoneStarts(c, pre)
    for _, z in ipairs(c and c._hitZones or {}) do
        if type(z.id) == "string" and string.sub(z.id, 1, #pre) == pre then return z end
    end
    return nil
end
-- a press and release in the middle of a zone, through the list's own mouse handlers
function H.click(c, z)
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    c:onMouseDown(x, y)
    c:onMouseUp(x, y)
end
-- scroll the list so item's row sits a third of the way down (zedqa_wt_bracket.lua's reveal)
function H.reveal(c, item)
    local s = c and c._scroll
    local y = c and c._itemRenderYMap and c._itemRenderYMap[item]
    if not (s and y) then return end
    if S.scroll[c] == nil then S.scroll[c] = s.scrollPos or 0 end
    if not (s.visible and s.barSizeRatio and s.barSizeRatio > 0 and s.barSizeRatio < 1) then return end
    local vis = s.height
    local range = vis / s.barSizeRatio - vis
    if range <= 0 then return end
    local logical = y - s.y + math.floor(s.scrollPos * range)
    s:setScrollPos(math.max(0, math.min(1, (logical - math.floor(vis / 3)) / range)))
end
function H.removeItem(it)
    pcall(function()
        local wo = it:getWorldItem()
        if wo then
            local sq = wo:getSquare()
            if sq then pcall(function() sq:transmitRemoveItemFromSquare(wo) end) end
            pcall(function() wo:removeFromWorld() end)
            pcall(function() wo:removeFromSquare() end)
        end
    end)
    pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
end

-- ===================================================================== what a list shows and draws
-- the things a list of inv shows: not hidden, and in the character's own inventory not worn or held unless ZeD setup's
-- "Worn and held things" lists them (Nov 22 2026, KISS #11, the director's pick: "In the list", the default, puts them
-- in a group of their own at the top; until K3 (0b366177e) they were never listed and this left them out always)
function H.wornListed()
    local IR = ZeD.InventoryRenderer
    local on = false
    pcall(function() on = IR.wornListed() and true or false end)
    return on
end
function H.expected(inv)
    local set, n = {}, 0
    local isP = inv == S.p:getInventory()
    local wornOn = isP and H.wornListed()
    for _, it in ipairs(H.list(inv)) do
        local hidden = false
        pcall(function() hidden = it:isHidden() end)
        if not hidden and (wornOn or not (isP and H.held(it))) then set[it] = true; n = n + 1 end
    end
    return set, n
end
-- every shown thing has a drawn row (list) or cell (grid): a closed stack's row stands for its whole stack
function H.drawn(c, grid)
    local exp, n = H.expected(c._inventory)
    local seen, covered, extra, unplaced, rows = {}, 0, 0, 0, 0
    local map = grid and c._itemRenderXMap or c._itemRenderYMap
    for _, it in ipairs(c._flatItems or {}) do
        rows = rows + 1
        if not (map and map[it]) then unplaced = unplaced + 1 end
        local st = c._stacks and c._stacks[it]
        local list = (st and st.items) or { it }
        for _, x in ipairs(list) do
            if exp[x] and not seen[x] then seen[x] = true; covered = covered + 1 else extra = extra + 1 end
        end
    end
    local ok = unplaced == 0 and covered == n and extra == 0 and rows > 0
    return ok, string.format("%d rows, %d of %d things drawn, %d rows with no place, %d extra", rows, covered, n, unplaced, extra)
end

-- ===================================================================== sort
-- the list's sort as asked, by its heading (a press on the key; a second press turns it round)
function H.sortTo(c, key, asc)
    local z = H.zone(c, "hdr:" .. key)
    if not z then return false, "no heading for " .. key end
    H.click(c, z)
    if not (c._sortCol == key and (c._sortAsc and true or false) == asc) then H.click(c, z) end
    local ok = c._sortCol == key and (c._sortAsc and true or false) == asc
    return ok, "sort " .. tostring(c._sortCol) .. " " .. tostring(c._sortAsc)
end
function H.wtOf(c, it)
    local st = c._stacks and c._stacks[it]
    if st and st.count > 1 and st.items then
        local t = 0
        for _, x in ipairs(st.items) do t = t + (x:getUnequippedWeight() or 0) end
        return t
    end
    return it:getUnequippedWeight() or 0
end
-- the rows (an open stack's own rows skipped) in the key's order: InventoryRenderer's sortItems and buildItemModel.
-- (Nov 22 2026, KISS #11; Nov 23: last, fix/wornlast: in the character's own list the worn and held group, catOf "zed:worn", stands last whichever
-- way the rest is sorted and is in the key's order among itself; the other rows start their own order after it)
function H.order(c, key, asc)
    local IR, IM = ZeD.InventoryRenderer, ZeD.ItemMeter
    local WK = IR.WORN_KEY
    local prev, pk, pnm = nil, nil, nil
    local n = 0
    local inWorn = nil
    for _, it in ipairs(c._flatItems or {}) do
        if not (c._childParent and c._childParent[it]) then
            n = n + 1
            local worn = (WK ~= nil and c._catOf ~= nil and c._catOf[it] == WK) and true or false
            -- (the director, Nov 23 2026, fix/wornlast: "Items in the inventory not worn or held should be above items worn or
            -- held ... Just like the vanilla game does it": the worn and held group now ends the list)
            if (not worn) and inWorn == true then return false, tostring(it:getName()) .. " (not worn) after the worn and held rows" end
            if inWorn == false and worn then prev = nil end
            inWorn = worn
            local k, nm = nil, it:getName() or ""
            if key == "name" then k = string.lower(nm)
            -- (Nov 22 2026: inside the worn and held group, Sort by Category orders the rows by each thing's own
            -- category, then name (buildItemModel: sortItems(groups[WORN_KEY], "cat")); their catOf is the group's key)
            elseif key == "cat" and worn then k = tostring(IR.catKey(it))
            elseif key == "cat" then k = tostring((c._catOf and c._catOf[it]) or IR.catKey(it))
            elseif key == "cond" then k = IM.sortKey(it)
            else k = H.wtOf(c, it) end
            if prev then
                local bad
                if key == "wt" then bad = (asc and k < pk - 0.0001) or ((not asc) and k > pk + 0.0001)
                else bad = (asc and k < pk) or ((not asc) and k > pk) end
                if not bad and key == "cat" and k == pk and nm < pnm then bad = true end
                if bad then return false, tostring(prev:getName()) .. " before " .. nm end
            end
            prev, pk, pnm = it, k, nm
        end
    end
    return n > 0, n .. " rows in order"
end

-- ===================================================================== drawn text (the weight bracket)
function H.capHook(c)
    if S.cap and S.cap.c == c then return end
    H.capUnhook()
    local cap = { c = c, had = rawget(c, "drawText"), list = {}, on = false }
    local base = c.drawText
    S.cap = cap
    c.drawText = function(self, s, x, y, r, g, b, a, font)
        if cap.on then cap.list[#cap.list + 1] = { s = tostring(s), x = x, y = y } end
        return base(self, s, x, y, r, g, b, a, font)
    end
end
function H.capUnhook()
    if S.cap then S.cap.c.drawText = S.cap.had; S.cap = nil end
end
-- the texts drawn on the row at y
function H.textsAt(y)
    local out = {}
    local rowH = ZeD.T.rowH
    for _, e in ipairs(S.cap and S.cap.list or {}) do
        if y and e.y >= y and e.y < y + rowH then out[#out + 1] = e.s end
    end
    return out
end
function H.hasText(list, a, b)
    for _, s in ipairs(list) do if s == a or s == b then return true end end
    return false
end

-- ===================================================================== the menu
function H.menu()
    local m = nil
    pcall(function() local v = getPlayerContextMenu(S.pn); m = v and v._zedMenu end)
    return m
end
function H.closeMenu()
    local m = H.menu()
    if m then pcall(function() m:close() end) end
end
function H.same(a, b) return a == b or string.lower(tostring(a)) == string.lower(tostring(b)) end
function H.names(defs)
    local t = {}
    for _, d in ipairs(defs or {}) do t[#t + 1] = tostring(d and d.name) end
    return table.concat(t, ", ")
end
-- choose each name in turn (a submenu, then its row) and confirm it, as the menu's click does
function H.pick(m, names)
    if m._levels then
        for depth, nm in ipairs(names) do
            local lv = m._levels[depth]
            if not lv then return false, "no level " .. depth end
            local ri, defs = nil, {}
            for k, r in ipairs(lv.rows or {}) do
                if r.def then defs[#defs + 1] = r.def; if not ri and H.same(r.def.name, nm) then ri = k end end
            end
            if not ri then return false, "no row " .. tostring(nm) .. " in: " .. H.names(defs) end
            lv.sel = ri
            m:confirm(depth)
        end
        return true, "picked"
    end
    for _, nm in ipairs(names) do
        local items = m._ctx.items or m:_currentItems()
        local idx = nil
        for i, d in ipairs(items) do if not idx and d and H.same(d.name, nm) then idx = i end end
        if not idx then return false, "no cell " .. tostring(nm) .. " in: " .. H.names(items) end
        m._ctx.selected = idx
        m:confirm()
    end
    return true, "picked"
end
function H.rightClick(c, item)
    local z = H.zone(c, item)
    if not z then return false end
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    c:onRightMouseDown(x, y)
    c:onRightMouseUp(x, y)
    return true
end

-- ===================================================================== drag
-- press on the row, past the drag threshold, released over dst (which answers that the pointer is over it)
function H.dragTo(src, item, dst)
    local z = H.zone(src, item)
    if not z then return false, "the row is not on screen" end
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    src._zedLastClick = nil   -- (never a double-click: that would be the quick use)
    src:onMouseDown(x, y)
    local d = src._drag
    if not (d and d:isPending()) then return false, "the press began no drag" end
    d:checkThreshold(d.startX + 40, d.startY + 40)
    if not d:isActive() then pcall(function() d:cancel() end); return false, "the drag did not start" end
    local had = rawget(dst, "isMouseOver")
    dst.isMouseOver = function() return true end
    local ok, err = pcall(function() src:onMouseUpOutside(x, y) end)
    dst.isMouseOver = had
    return ok, ok and "dropped" or tostring(err)
end

-- ===================================================================== the container buttons
function H.ccPress(c, id)
    local cc = c and c._cc
    for i, h in ipairs(cc and cc.hits or {}) do
        if h.spec and h.spec.id == id then
            if not h.spec.enabled then return false, tostring(h.spec.label) .. " is off" end
            local z = H.zone(c, "cc:" .. i)
            if z and z.w > 0 then
                c:onMouseDown(z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
                return true, tostring(h.spec.label)
            end
            -- (scrolled out of its ribbon: pressed as the controller's A presses it)
            ZeD.ContainerControls.press(c, i)
            return true, tostring(h.spec.label) .. " (by A)"
        end
    end
    return false, "no button " .. id
end
-- the bag's own things back in the bag (a Transfer all or a drop took them)
function H.restoreBag()
    local back = 0
    for _, it in ipairs(S.bagOrig or {}) do
        local c = H.where(it)
        if c ~= S.bag and not H.held(it) then
            H.removeItem(it)
            pcall(function() S.bag:AddItem(it) end)
            back = back + 1
        end
    end
    return back
end
function H.inCrate(list)
    local n = 0
    for _, it in ipairs(list) do if H.where(it) == S.crate then n = n + 1 end end
    return n
end

-- ===================================================================== setup
Q.step(1, function()
    S.pairWas = RT.isOpen()
    if ZEDQA_HOME then pcall(ZEDQA_HOME, "rt_inv") end
    RT.pairOpen()
    pcall(function() S.instWas = S.p:isTimedActionInstantCheat() end)
    S.handWas = { S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem() }
    pcall(function() S.p:setTimedActionInstantCheat(true) end)
end)
step(30, function()
    local cw, ww = RT.cw(), RT.ww()
    if not Q.check(cw ~= nil and ww ~= nil, "both windows are open") then S.dead = true; return end
    S.charTabWas, S.worldTabWas = cw._activeTab, ww._activeTab
    S.charCols, S.worldCols = {}, {}
    for _, j in ipairs(cw._mcSelected or {}) do local e = cw._containers[j]; if e then S.charCols[#S.charCols + 1] = e.inventory end end
    for _, j in ipairs(ww._mcSelected or {}) do local e = ww._containers[j]; if e then S.worldCols[#S.worldCols + 1] = e.inventory end end
    if #S.charCols > 0 then pcall(ZeD_CharacterWindow.closeColumns, cw) end
    if #S.worldCols > 0 then pcall(ZeD_WorldWindow.closeColumns, ww) end
    RT.charTab("loot")
    if not RT.worldTab("loot") then pcall(ZeD_WorldWindow.openTab, S.pn, "loot") end
end)
step(20, function()
    local cc, wc = H.cc(), H.wc()
    S.bag = cc and cc._inventory
    if not Q.check(S.bag ~= nil and S.bag == S.p:getInventory(), "the Character window lists the character's inventory",
        tostring(S.bag)) then S.dead = true; return end
    S.worldInvWas = wc and wc._inventory
    S.sortWas = { cc = { cc._sortCol, cc._sortAsc }, wc = { wc._sortCol, wc._sortAsc } }
    for _, c in ipairs({ cc, wc }) do if c._scroll then S.scroll[c] = c._scroll.scrollPos or 0 end end
    S.bagOrig = H.list(S.bag)
    -- the crate beside the character: the first open square round it
    local x, y, z = math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())
    for _, d in ipairs({ { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 } }) do
        if not S.crateObj then
            local sq = getCell():getGridSquare(x + d[1], y + d[2], z)
            local free = sq ~= nil
            if sq then pcall(function() free = sq:isFree(false) end) end
            if free then
                pcall(function()
                    local o = IsoObject.new(getCell(), sq, "carpentry_01_16")
                    o:createContainersFromSpriteProperties()
                    sq:AddTileObject(o)
                    S.crateObj = o
                    S.crate = o:getContainer()
                end)
            end
        end
    end
    if not Q.check(S.crate ~= nil, "a crate stands beside the character", tostring(S.crate)) then S.dead = true; return end
    pcall(function() S.crate:setExplored(true) end)
    for _, e in ipairs({ { "Base.Plank", 2 }, { "Base.TinnedBeans", 3 }, { "Base.Saucepan", 1 }, { "Base.Crowbar", 1 },
                         { "Base.Bandage", 2 }, { "Base.Rope", 1 } }) do
        for _ = 1, e[2] do
            local it = nil
            pcall(function() it = S.crate:AddItem(e[1]) end)
            if it then
                S.crateGiven[#S.crateGiven + 1] = it
                pcall(function() it:getModData().ZeDQA_spawned = true end)
                if e[1] == "Base.Crowbar" then
                    S.crowbar = it
                    pcall(function() it:setCondition(math.max(1, math.floor(it:getConditionMax() / 2))) end)
                end
            end
        end
    end
    -- the thing that moves: a kind the bag does not hold, so its row is its own
    local have = {}
    for _, it in ipairs(S.bagOrig) do have[it:getFullType()] = true end
    for _, ft in ipairs({ "Base.Pan", "Base.Kettle", "Base.RollingPin", "Base.Spatula", "Base.Ladle", "Base.Spoon" }) do
        if not S.mover and not have[ft] then S.mover = RT.give(ft) end
    end
    if not Q.check(S.mover ~= nil and #S.crateGiven == 10, "the things for the test were made",
        "crate " .. #S.crateGiven .. " of 10, mover " .. tostring(S.mover and S.mover:getFullType())) then S.dead = true; return end
    -- the grid choices of both containers, kept as found
    local st = S.p:getModData().ZeD_GridViews or {}
    S.p:getModData().ZeD_GridViews = st
    for _, inv in ipairs({ S.bag, S.crate }) do
        local key = ZeD.InventoryRenderer.containerKey(inv, S.p)
        if key then
            S.grid[key] = (st[key] == nil) and NIL or st[key]
            ZeD.InventoryRenderer.setGridKey(key, false, S.p)   -- (the list to start; the view button flips it below)
        end
    end
    ZeD_WorldWindow.selectContainer(S.crate, 200, S.pn)
end)
waitFor(10, 600, function()
    local wc = H.wc()
    return wc ~= nil and wc._inventory == S.crate and H.zone(wc, "hdr:name") ~= nil and #(wc._flatItems or {}) > 0
end, function(ok)
    local ww = RT.ww()
    local e = ww and ww._containers and ww._containers[ww._activeContainer]
    S.crateName = e and e.name
    if not Q.check(ok, "the World window shows the crate (selectContainer)", tostring(S.crateName)) then S.dead = true end
end)

-- ===================================================================== 1. sort, both windows, every key each way
for _, key in ipairs({ "name", "cat", "cond", "wt" }) do
    for _, asc in ipairs({ true, false }) do
        local tag = key .. (asc and " rising" or " falling")
        step(3, function()
            S.sortOk = {}
            S.sortOk.cc = { H.sortTo(H.cc(), key, asc) }
            S.sortOk.wc = { H.sortTo(H.wc(), key, asc) }
        end)
        step(4, function()
            for _, k in ipairs({ "cc", "wc" }) do
                local c = (k == "cc") and H.cc() or H.wc()
                local set = S.sortOk[k]
                local ok, why = H.order(c, key, asc)
                -- (Nov 18 2026, the first true Deck run: a narrow list shows only one extra column, Build's width rule
                -- drops Cat before Status, so there is no Category heading to press there; that is by design)
                if not set[1] and tostring(set[2]):find("no heading for", 1, true) then
                    Q.skip("Sort by " .. tag .. " from the heading (" .. ((k == "cc") and "bag" or "crate") .. ")",
                        "the list is too narrow for that column here (by design: " .. tostring(set[2]) .. ")")
                else
                Q.check(set[1] and ok, "Sort by " .. tag .. " from the heading puts the " .. ((k == "cc") and "bag's" or "crate's")
                    .. " rows in that order", tostring(set[2]) .. "; " .. tostring(why))
                end
            end
        end)
    end
end

-- ===================================================================== 2. list and grid draw every thing
step(3, function() H.sortTo(H.cc(), "name", true); H.sortTo(H.wc(), "name", true) end)
step(4, function()
    for _, k in ipairs({ "cc", "wc" }) do
        local c = (k == "cc") and H.cc() or H.wc()
        local ok, why = H.drawn(c, false)
        Q.check(ok and c._gridCell == nil, "the list draws every thing in the " .. ((k == "cc") and "bag" or "crate"), why)
    end
end)
-- (Nov 18 2026, the ledger's gap "list draws every item": the pad's rows, content._invRowItems, are the shown rows,
-- each row once (a closed stack is one row), each with its drawn place in _itemRenderYMap)
step(1, function()
    for _, k in ipairs({ "cc", "wc" }) do
        local c = (k == "cc") and H.cc() or H.wc()
        local rows = c._invRowItems or {}
        local seen, distinct, noY = {}, 0, 0
        for _, it in ipairs(c._flatItems or {}) do if not seen[it] then seen[it] = true; distinct = distinct + 1 end end
        for _, it in ipairs(rows) do if not (c._itemRenderYMap and c._itemRenderYMap[it]) then noY = noY + 1 end end
        Q.check(#rows > 0 and #rows == distinct and noY == 0,
            "the " .. ((k == "cc") and "bag's" or "crate's") .. " pad rows (_invRowItems) are its shown rows, one each, each drawn",
            #rows .. " pad rows, " .. distinct .. " shown rows, " .. noY .. " with no place")
    end
end)
step(2, function()
    for _, k in ipairs({ "cc", "wc" }) do
        local c = (k == "cc") and H.cc() or H.wc()
        local z = H.zoneStarts(c, "view:flip:")
        S[k .. "Flip"] = z ~= nil
        if z then H.click(c, z) end
    end
end)
step(6, function()
    for _, k in ipairs({ "cc", "wc" }) do
        local c = (k == "cc") and H.cc() or H.wc()
        local ok, why = H.drawn(c, true)
        Q.check(S[k .. "Flip"] and c._gridCell ~= nil and ok, "the view button turns the " .. ((k == "cc") and "bag" or "crate")
            .. " to the grid, and the grid draws every thing", "button " .. tostring(S[k .. "Flip"]) .. ", " .. why)
    end
end)
-- item-colored grid tiles (GridTint.lua): a vanilla item's icon gives a tile color and an icon not in the baked table
-- gives none. (Nov 20 2026, Cuts C: the tiles follow Style, tinted in Full and plain in Lite; the setup row is gone.)
-- Style is set by value only and put back.
function H.tintSet(v)
    local opt = ZeD.Settings.lookStyleOption
    pcall(function() opt:setValue(v) end)
end
step(1, function()
    local G, opt = ZeD.GridTint, ZeD.Settings and ZeD.Settings.lookStyleOption
    if not Q.check(G ~= nil and opt ~= nil, "item-colored tiles: GridTint and the Style setting are there") then return end
    S.tintWas = opt:getValue()
    local tex = nil
    pcall(function() tex = S.crowbar:getTex() end)
    S.fakeTex = { getName = function() return "ZeDQA_NoSuchIcon" end }
    H.tintSet(1)
    local on = ZeD.Settings.gridTint()
    local r, g, b = G.of(ZeD.T, tex)
    local r2 = G.of(ZeD.T, S.fakeTex)
    Q.check(on and r ~= nil and g ~= nil and b ~= nil and r2 == nil,
        "item-colored tiles in Full: the crowbar's icon gives a tile color, an unknown icon none",
        "switch " .. tostring(on) .. ", crowbar " .. tostring(r) .. "," .. tostring(g) .. "," .. tostring(b) .. ", unknown " .. tostring(r2))
    H.tintSet(2)
    local r3 = G.of(ZeD.T, tex)
    Q.check((not ZeD.Settings.gridTint()) and r3 == nil, "item-colored tiles in Lite: no tile is tinted", tostring(r3))
    H.tintSet(S.tintWas)
    G._cache[S.fakeTex] = nil
end)
step(2, function()
    for _, k in ipairs({ "cc", "wc" }) do
        local c = (k == "cc") and H.cc() or H.wc()
        local z = H.zoneStarts(c, "view:flip:")
        if z then H.click(c, z) end
    end
end)
step(6, function()
    for _, k in ipairs({ "cc", "wc" }) do
        local c = (k == "cc") and H.cc() or H.wc()
        local ok, why = H.drawn(c, false)
        Q.check(c._gridCell == nil and ok, "the view button turns the " .. ((k == "cc") and "bag" or "crate") .. " back to the list", why)
    end
    RT.bounds(Q, "the inventory lists")
end)

-- ===================================================================== 3. the filter (the crate)
S.query = "plank"
step(2, function()
    local wc = H.wc()
    local z = H.zoneStarts(wc, "view:filter:")
    if Q.check(z ~= nil, "the crate's heading has the Filter button") then H.click(wc, z) end
end)
step(6, function()
    local wc = H.wc()
    local F = wc._zedFilter
    S.F = F
    if not Q.check(F ~= nil and F.open == true, "the Filter button opens the bar") then return end
    -- typed into the bar's field (its every keystroke lands in onFilter)
    if F.field and F.field.onFilter then
        pcall(function() F.field.input:setText(S.query) end)
        F.field.onFilter(F.field, S.query)
    else
        ZeD.InvFilter.setQuery(F, S.query)
    end
end)
step(6, function()
    local wc = H.wc()
    local fr = wc._fres
    local hit, miss, wrong = 0, 0, {}
    for _, it in ipairs(wc._flatItems or {}) do
        local want = string.find(string.lower(it:getName() or ""), S.query, 1, true) ~= nil
        local got = (fr and fr.match[it]) and true or false
        if want then hit = hit + 1 else miss = miss + 1 end
        if want ~= got then wrong[#wrong + 1] = tostring(it:getName()) end
    end
    Q.check(fr ~= nil and hit > 0 and miss > 0 and #wrong == 0,
        "the filter \"" .. S.query .. "\" marks the rows whose name holds it and dims the rest",
        hit .. " match, " .. miss .. " dim" .. ((#wrong > 0) and ("; wrong: " .. table.concat(wrong, ", ")) or ""))
    RT.bounds(Q, "the filter bar open")
end)
step(2, function()
    local wc = H.wc()
    local z = H.zone(wc, "view:fbar:clear")
    S.clearZone = z ~= nil
    if z then H.click(wc, z) end
end)
step(4, function()
    local wc = H.wc()
    Q.check(S.clearZone and wc._fres == nil and not ZeD.InvFilter.active(S.F), "Clear shows every row again",
        "button " .. tostring(S.clearZone) .. ", text \"" .. tostring(S.F and S.F.q) .. "\"")
end)
-- a category chip (the bar's "view:fbar:chip:<category>"): the rows of that category match, the rest dim; the
-- filter is saved on the crate's key, a container with no place (the floor) keeps none, and the crate shown again
-- takes its filter back (InventoryFilter's sync); Clear takes it off the crate's key
S.chipPre = "view:fbar:chip:"
function H.catOf(c, it) return tostring((c._catOf and c._catOf[it]) or ZeD.InventoryRenderer.catKey(it)) end
step(2, function()
    local wc = H.wc()
    local z = H.zoneStarts(wc, S.chipPre)
    if not z then Q.skip("Filter: a category chip", "the bar shows no chip at this width"); return end
    S.chip = string.sub(z.id, #S.chipPre + 1)
    S.crateKey = ZeD.InventoryRenderer.containerKey(S.crate, S.p)
    H.click(wc, z)
end)
step(6, function()
    if not S.chip then return end
    local wc = H.wc()
    local fr = wc._fres
    local hit, miss, wrong = 0, 0, {}
    for _, it in ipairs(wc._flatItems or {}) do
        local want = H.catOf(wc, it) == S.chip
        local got = (fr and fr.match[it]) and true or false
        if want then hit = hit + 1 else miss = miss + 1 end
        if want ~= got then wrong[#wrong + 1] = tostring(it:getName()) end
    end
    Q.check(S.F.cats[S.chip] == true and fr ~= nil and hit > 0 and #wrong == 0,
        "the chip " .. S.chip .. " marks that category's rows and dims the rest",
        hit .. " match, " .. miss .. " dim" .. ((#wrong > 0) and ("; wrong: " .. table.concat(wrong, ", ")) or ""))
    local st = S.p:getModData().ZeD_Filters
    Q.check(st ~= nil and S.crateKey ~= nil and st[S.crateKey] == ZeD.InvFilter.encode(S.F),
        "the filter is saved on the crate's key", tostring(S.crateKey) .. " = " .. tostring(st and S.crateKey and st[S.crateKey]))
    local ww = RT.ww()
    for _, e in ipairs((ww and ww._containers) or {}) do
        if not S.floorInv and e.inventory then
            local ty = nil
            pcall(function() ty = e.inventory:getType() end)
            if e.isFloor or ty == "floor" then S.floorInv = e.inventory end
        end
    end
    if S.floorInv then pcall(ZeD_WorldWindow.selectContainer, S.floorInv, 60, S.pn) end
end)
waitFor(4, 300, function() return S.chip == nil or S.floorInv == nil or (H.wc() and H.wc()._inventory == S.floorInv) end, function(ok)
    if not S.chip then return end
    if not S.floorInv then Q.skip("Filter: the crate's filter comes back when it is shown again", "the World window lists no floor here"); return end
    Q.check(ok and not ZeD.InvFilter.active(S.F), "the floor shown: it keeps no filter (the bar empties)",
        "nCats " .. tostring(S.F.nCats) .. ", text \"" .. tostring(S.F.q) .. "\"")
    pcall(ZeD_WorldWindow.selectContainer, S.crate, 60, S.pn)
end)
waitFor(4, 300, function() return S.chip == nil or S.floorInv == nil or (H.wc() and H.wc()._inventory == S.crate and H.zone(H.wc(), "hdr:name") ~= nil) end, function(ok)
    if not (S.chip and S.floorInv) then return end
    Q.check(ok and S.F.open and S.F.cats[S.chip] == true, "the crate shown again takes its saved filter back (the chip on, the bar open)",
        "open " .. tostring(S.F.open) .. ", chip " .. tostring(S.F.cats[S.chip]))
end)
step(4, function()
    if not S.chip then return end
    local wc = H.wc()
    local z = H.zone(wc, "view:fbar:clear")
    if z then H.click(wc, z) else ZeD.InvFilter.clear(S.F) end
end)
step(4, function()
    if S.chip then
        local st = S.p:getModData().ZeD_Filters
        Q.check(not ZeD.InvFilter.active(S.F) and not (st and st[S.crateKey]), "Clear takes the chip off and the crate's saved filter with it",
            tostring(st and st[S.crateKey]))
    end
    local wc = H.wc()
    local z = H.zoneStarts(wc, "view:filter:")
    if z then H.click(wc, z) end
end)
step(4, function()
    Q.check(S.F ~= nil and not S.F.open, "the Filter button puts the bar away", tostring(S.F and S.F.open))
end)

-- ===================================================================== 4. a stack and its total weight (the crate's beans)
S.stackKey = "Base.TinnedBeans"
function H.beans()
    local wc = H.wc()
    local n, total = 0, 0
    for _, it in ipairs(H.list(S.crate)) do
        if it:getFullType() == S.stackKey then n = n + 1; total = total + (it:getUnequippedWeight() or 0) end
    end
    S.bracket1 = "(" .. string.format("%.1f", total) .. ")"
    S.bracket0 = "(" .. string.format("%.0f", total) .. ")"
    local rep = nil
    for _, it in ipairs(wc._flatItems or {}) do
        local st = wc._stacks and wc._stacks[it]
        if st and st.key == S.stackKey then rep = it end
    end
    return rep, n
end
step(2, function()
    local wc = H.wc()
    if wc._expandedStacks then wc._expandedStacks[S.stackKey] = nil end   -- (shut to start)
    H.sortTo(wc, "name", true)
    H.capHook(wc)
end)
step(3, function() S.cap.list = {}; S.cap.on = true end)
step(3, function()
    S.cap.on = false
    local wc = H.wc()
    local rep, n = H.beans()
    local y = rep and wc._itemRenderYMap and wc._itemRenderYMap[rep]
    local texts = H.textsAt(y)
    Q.check(rep ~= nil and n == 3 and H.hasText(texts, S.bracket1, S.bracket0),
        "the stack's row (three cans) shows its total weight in brackets " .. S.bracket1,
        "row " .. tostring(y ~= nil) .. "; drew: " .. table.concat(texts, " | "))
    local z = H.zone(wc, "stack:" .. S.stackKey)
    S.stackZone = z ~= nil
    if z then H.click(wc, z) end
end)
step(3, function() S.cap.list = {}; S.cap.on = true end)
step(3, function()
    S.cap.on = false
    local wc = H.wc()
    local hy = wc._itemRenderYMap and wc._itemRenderYMap["stackhead:" .. S.stackKey]
    local kids = 0
    for _, it in ipairs(wc._flatItems or {}) do
        local par = wc._childParent and wc._childParent[it]
        if par and par.key == S.stackKey and wc._itemRenderYMap[it] then kids = kids + 1 end
    end
    local texts = H.textsAt(hy)
    Q.check(S.stackZone and hy ~= nil and kids == 3, "the stack's triangle opens it: a row for each of the three cans",
        "triangle " .. tostring(S.stackZone) .. ", header " .. tostring(hy ~= nil) .. ", rows " .. kids)
    Q.check(H.hasText(texts, S.bracket1, S.bracket0), "the open stack's header keeps the total " .. S.bracket1,
        "drew: " .. table.concat(texts, " | "))
    local z = H.zone(wc, "stack:" .. S.stackKey)
    if z then H.click(wc, z) end
end)
step(3, function()
    local wc = H.wc()
    H.capUnhook()
    Q.check(not (wc._expandedStacks and wc._expandedStacks[S.stackKey]), "a press on the open stack's header shuts it")
end)

-- ===================================================================== 5. box select (the crate)
step(2, function()
    local wc = H.wc()
    local first, bottom = nil, nil
    for _, z in ipairs(wc._hitZones or {}) do
        if type(z.id) ~= "string" and type(z.id) ~= "number" then
            if not first or z.y < first.y then first = z end
            if not bottom or z.y + z.h > bottom then bottom = z.y + z.h end
        end
    end
    if not first then Q.check(false, "the crate's rows are on screen for a box"); return end
    local x = first.x + math.floor(first.w / 2)
    local yE = nil
    local yy = bottom + 3
    while not yE and yy < wc:getHeight() - 2 do
        if not wc:hitZoneAt(x, yy) then yE = yy end
        yy = yy + 3
    end
    if not yE then Q.skip("box select", "no empty space under the crate's rows at this screen size"); return end
    wc:onMouseDown(x, yE)
    if not Q.check(wc._box ~= nil, "a press on the list's empty space starts a box") then return end
    ZeD.BoxSelect.move(wc, x + 2, first.y + 2)
    wc:onMouseUp(x + 2, first.y + 2)
    local sel = wc._selectedItems or {}
    local n, all = 0, 0
    for _ in pairs(sel) do n = n + 1 end
    for _, it in ipairs(wc._flatItems or {}) do all = all + 1; if not sel[it] then n = -1000 end end
    Q.check(n == all and all > 0, "the box drawn up over the rows selects every row it crosses", n .. " of " .. all)
    for k in pairs(sel) do sel[k] = nil end
    wc._lastClickedItem = nil
    pcall(function() RT.ww()._updateDrawer() end)
end)
-- a double-click on the empty space selects every row (ZeD_BoxSelect.doubleEmpty, the list's zedSelectAll)
step(3, function()
    local wc = H.wc()
    local first, bottom = nil, nil
    for _, z in ipairs(wc._hitZones or {}) do
        if type(z.id) ~= "string" and type(z.id) ~= "number" then
            if not first or z.y < first.y then first = z end
            if not bottom or z.y + z.h > bottom then bottom = z.y + z.h end
        end
    end
    if not first then Q.check(false, "the crate's rows are on screen for a double-click"); return end
    local x, yE = first.x + math.floor(first.w / 2), nil
    local yy = bottom + 3
    while not yE and yy < wc:getHeight() - 2 do
        if not wc:hitZoneAt(x, yy) then yE = yy end
        yy = yy + 3
    end
    if not yE then Q.skip("double-click on empty space", "no empty space under the crate's rows at this screen size"); return end
    wc._emptyPress = nil   -- (the box's own press above was the first of a pair otherwise)
    wc:onMouseDown(x, yE)
    wc:onMouseUp(x, yE)
    wc:onMouseDown(x, yE)
    wc:onMouseUp(x, yE)
    local sel = wc._selectedItems or {}
    local n, all = 0, 0
    for _, it in ipairs(wc._flatItems or {}) do all = all + 1; if sel[it] then n = n + 1 end end
    Q.check(all > 0 and n == all, "a double-click on the list's empty space selects every row", n .. " of " .. all)
    for k in pairs(sel) do sel[k] = nil end
    wc._lastClickedItem = nil
    wc._padMarks = nil
    pcall(function() RT.ww()._updateDrawer() end)
end)

-- ===================================================================== 6. moving: drag, then Move To, both ways
function H.moveCheck(what, toCrate)
    local it = S.mover
    local inC, inB = H.where(it) == S.crate, H.where(it) == S.bag
    local nb, nc = H.size(S.bag), H.size(S.crate)
    local ok = (toCrate and inC and nb == S.nBag - 1 and nc == S.nCrate + 1)
        or ((not toCrate) and inB and nb == S.nBag + 1 and nc == S.nCrate - 1)
    Q.check(ok, what, string.format("in the crate %s, in the bag %s; bag %d (was %d), crate %d (was %d)",
        tostring(inC), tostring(inB), nb, S.nBag, nc, S.nCrate))
end
function H.counts() S.nBag, S.nCrate = H.size(S.bag), H.size(S.crate) end
step(2, function() H.reveal(H.cc(), S.mover) end)
step(4, function()
    H.counts()
    local ok, why = H.dragTo(H.cc(), S.mover, H.wc())
    Q.check(ok, "the pan's row drags from the bag and drops on the crate's list", why)
end)
waitFor(10, 900, H.queueEmpty, function()
    H.moveCheck("dragged into the crate: the pan is in the crate once the transfer is done, and the counts agree", true)
end)
step(4, function()
    H.counts()
    local ok, why = H.dragTo(H.wc(), S.mover, H.cc())
    Q.check(ok, "the pan's row drags from the crate and drops on the bag's list", why)
end)
waitFor(10, 900, H.queueEmpty, function()
    H.moveCheck("dragged back into the bag: the pan is in the bag and the counts agree", false)
end)
S.moveTo = getTextOrNull("ContextMenu_Move_To") or "Move To"
step(2, function() H.closeMenu(); H.reveal(H.cc(), S.mover) end)
step(4, function()
    H.counts()
    Q.check(H.rightClick(H.cc(), S.mover), "the pan's row in the bag takes a right-click")
end)
waitFor(2, 120, function() return H.menu() ~= nil end, function(ok)
    if not Q.check(ok, "the right-click opens ZeD's menu on the pan") then return end
    local okP, why = H.pick(H.menu(), { S.moveTo, S.crateName })
    if not Q.check(okP, "the menu's Move To lists the crate (" .. tostring(S.crateName) .. ") and runs it", why) then H.closeMenu() end
end)
waitFor(10, 900, function() return H.queueEmpty() and H.menu() == nil end, function()
    H.moveCheck("Move To the crate: the pan is in the crate and the counts agree", true)
end)
step(4, function()
    H.counts()
    Q.check(H.rightClick(H.wc(), S.mover), "the pan's row in the crate takes a right-click")
end)
waitFor(2, 120, function() return H.menu() ~= nil end, function(ok)
    if not Q.check(ok, "the right-click opens ZeD's menu on the pan in the crate") then return end
    local okP, why = H.pick(H.menu(), { S.moveTo, getTextOrNull("ContextMenu_MoveToInventory") or "Inventory" })
    if not Q.check(okP, "the menu's Move To lists Inventory and runs it", why) then H.closeMenu() end
end)
waitFor(10, 900, function() return H.queueEmpty() and H.menu() == nil end, function()
    H.moveCheck("Move To the inventory: the pan is back in the bag and the counts agree", false)
end)

-- ===================================================================== 6b. column resize (the bag's Weight divider)
-- (the press and the move go through the list's own handlers, which read the pointer's x from getMouseX: that one
-- reading is faked for the length of the call, as the drag above fakes "the pointer is over me")
function H.withGlobals(over, fn)
    local was = {}
    for k, v in pairs(over) do was[k] = _G[k]; _G[k] = v end
    local ok, err = pcall(fn)
    for k, v in pairs(was) do _G[k] = v end
    return ok, err
end
step(3, function()
    local cc = H.cc()
    local z = H.zone(cc, "div:wt")
    if not z then Q.skip("Column resize", "the bag's list has no Weight divider here (grid or side-by-side)"); return end
    local cw = cc._colWidths
    S.colWas = cw and cw.wt
    local d = ZeD.T.px(20)
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    S.mx = 1000
    local ok, err = H.withGlobals({ getMouseX = function() return S.mx end }, function()
        cc:onMouseDown(x, y)
        S.dragStarted = cc._colDrag ~= nil
        S.mx = 1000 - d
        cc:onMouseMove(-d, 0)
        cc:onMouseUp(x - d, y)
    end)
    local want = math.max(ZeD.T.px(30), math.min(math.floor(cc:getWidth() / 2), (S.colWas or 0) + d))
    Q.check(ok and S.dragStarted and cc._colDrag == nil and cc._colWidths.wt == want,
        "a drag on the Weight divider widens the column by the drag (the list's own press, move and release)",
        tostring(err or "") .. " was " .. tostring(S.colWas) .. ", now " .. tostring(cc._colWidths and cc._colWidths.wt) .. ", want " .. want)
end)
step(3, function()
    local cc = H.cc()
    if S.colWas == nil then return end
    local z = H.zone(cc, "hdr:wt")
    Q.check(z ~= nil and z.x >= 0 and z.x + z.w <= cc:getWidth() + 1, "the Weight heading stays inside the list after the resize",
        z and (math.floor(z.x) .. "+" .. math.floor(z.w) .. " in " .. math.floor(cc:getWidth())) or "no heading")
    cc._colWidths.wt = S.colWas
end)

-- ===================================================================== 6c. category headings fold (the crate)
-- (Sort by Category from its heading; on a list too narrow for the Category column, Build's width rule, the sort is
-- set as that heading sets it: the fold is the feature here, not the heading)
step(2, function()
    local wc = H.wc()
    local ok = H.sortTo(wc, "cat", true)
    if not ok then wc._sortCol, wc._sortAsc = "cat", true; Q.say("NOTE no Category heading at this width: Sort by Category set as its heading sets it") end
end)
function H.inCat(c, cat)
    local n = 0
    for _, it in ipairs(c._invRowItems or {}) do if H.catOf(c, it) == cat then n = n + 1 end end
    return n
end
step(4, function()
    local wc = H.wc()
    local z = H.zoneStarts(wc, "cat:")
    if not Q.check(z ~= nil, "Sort by Category draws the category headings") then return end
    S.foldCat = string.sub(z.id, 5)
    S.foldN = H.inCat(wc, S.foldCat)
    H.click(wc, z)
end)
step(4, function()
    if not S.foldCat then return end
    local wc = H.wc()
    local n = H.inCat(wc, S.foldCat)
    Q.check((wc._collapsedGroups or {})[S.foldCat] == true and S.foldN > 0 and n == 0,
        "a press on the heading " .. S.foldCat .. " folds it: its rows leave the list", "rows " .. S.foldN .. " -> " .. n)
    local z = H.zone(wc, "cat:" .. S.foldCat)
    if z then H.click(wc, z) end
end)
step(4, function()
    if not S.foldCat then return end
    local wc = H.wc()
    local n = H.inCat(wc, S.foldCat)
    Q.check(not (wc._collapsedGroups or {})[S.foldCat] and n == S.foldN, "a second press opens it: its rows come back", n .. " of " .. S.foldN)
    if not H.sortTo(wc, "name", true) then wc._sortCol, wc._sortAsc = "name", true end
end)

-- ===================================================================== 6d. select: click, Ctrl, Shift; the picked line (the crate)
-- (the list's own press reads Ctrl and Shift from isCtrlKeyDown / isShiftKeyDown: those two are faked for the call)
function H.clickMods(c, item, ctrl, shift)
    local z = H.zone(c, item)
    if not z then return false end
    c._zedLastClick = nil
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    local ok = H.withGlobals({ isCtrlKeyDown = function() return ctrl end, isShiftKeyDown = function() return shift end }, function()
        c:onMouseDown(x, y)
        c:onMouseUp(x, y)
    end)
    return ok
end
function H.selIs(c, want)
    local sel = c._selectedItems or {}
    local n, w, got = 0, 0, {}
    for it in pairs(sel) do n = n + 1; got[#got + 1] = tostring(it:getName()) end
    for _, it in ipairs(want) do w = w + 1; if not sel[it] then return false, table.concat(got, ", ") end end
    return n == w, table.concat(got, ", ")
end
step(3, function()
    local wc = H.wc()
    local r = wc._flatItems or {}
    if #r < 5 then Q.check(false, "the crate shows five rows to pick from", #r .. " rows"); return end
    S.r = { r[1], r[3], r[4], r[5] }
    local okC = H.clickMods(wc, S.r[1], false, false)
    local ok, got = H.selIs(wc, { S.r[1] })
    Q.check(okC and ok, "a click selects its row alone", got)
    okC = H.clickMods(wc, S.r[2], true, false)
    ok, got = H.selIs(wc, { S.r[1], S.r[2] })
    Q.check(okC and ok, "Ctrl-click adds a row", got)
    okC = H.clickMods(wc, S.r[4], false, true)
    ok, got = H.selIs(wc, { S.r[1], S.r[2], S.r[3], S.r[4] })
    Q.check(okC and ok, "Shift-click adds the run from the last row clicked", got)
    okC = H.clickMods(wc, S.r[2], true, false)
    ok, got = H.selIs(wc, { S.r[1], S.r[3], S.r[4] })
    Q.check(okC and ok, "Ctrl-click on a picked row takes it out", got)
end)
Q.waitMs(300)   -- (the picked line looks at the picks every 100 ms: InventoryPicked.CHECK_MS)
step(2, function()
    if not S.r then return end
    local wc = H.wc()
    local n, g = 0, 0
    for it in pairs(wc._selectedItems or {}) do
        local st = wc._stacks and wc._stacks[it]
        local list = (st and st.count and st.count > 1 and st.items) or { it }
        for _, x in ipairs(list) do n = n + 1; g = g + math.floor((x:getUnequippedWeight() or 0) * 1000 + 0.5) end
    end
    local total = ZeD.InventoryRenderer.shownCount(wc, S.crate, S.p) or 0
    local want = ZeD.tr(n == 1 and "UI_ZeD_Inv_PickedOne" or "UI_ZeD_Inv_PickedMany", n, total, string.format("%.1f", g / 1000))
    local got = RT.ww()._statusLine
    Q.check(got == want, "the picked line counts the picks (a closed stack's row is its whole stack) and their weight",
        "\"" .. tostring(got) .. "\", want \"" .. want .. "\"")
    local sel = wc._selectedItems or {}
    for k in pairs(sel) do sel[k] = nil end
    wc._lastClickedItem = nil
    wc._padMarks = nil
    pcall(function() RT.ww()._updateDrawer() end)
end)

-- ===================================================================== 6e. double-click: the quick use
-- in the crate a double-click brings the crowbar to the bag; in the bag (its stack opened, so the row is its own) a
-- double-click is the game's basic action: the crowbar in the hand. Then the hands as they were, the crowbar back.
function H.dbl(c, item)
    local z = H.zone(c, item)
    if not z then return false end
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    c._zedLastClick = nil
    c:onMouseDown(x, y)
    c:onMouseUp(x, y)
    c:onMouseDown(x, y)
    c:onMouseUp(x, y)
    return true
end
step(2, function()
    local cc = H.cc()
    cc._expandedStacks = cc._expandedStacks or {}
    S.cbStackWas = cc._expandedStacks["Base.Crowbar"]
    cc._expandedStacks["Base.Crowbar"] = true
    H.reveal(H.wc(), S.crowbar)
end)
step(4, function()
    Q.check(H.dbl(H.wc(), S.crowbar), "the crowbar's row in the crate takes a double-click")
end)
waitFor(5, 900, function() return H.queueEmpty() and H.where(S.crowbar) == S.bag end, function(ok)
    Q.check(ok, "a double-click in the crate brings the crowbar to the bag (the game's transfer)", tostring(H.where(S.crowbar)))
    H.reveal(H.cc(), S.crowbar)
end)
step(4, function()
    if H.where(S.crowbar) ~= S.bag then return end
    Q.check(H.dbl(H.cc(), S.crowbar), "the crowbar's row in the bag takes a double-click")
end)
waitFor(5, 900, function() return H.queueEmpty() and H.held(S.crowbar) end, function(ok)
    Q.check(ok, "a double-click in the bag is the game's basic action: the crowbar in the hand",
        tostring(S.p:getPrimaryHandItem() and S.p:getPrimaryHandItem():getName()))
    pcall(function() S.p:setPrimaryHandItem(S.handWas[1]) end)
    pcall(function() S.p:setSecondaryHandItem(S.handWas[2]) end)
    H.removeItem(S.crowbar)
    pcall(function() S.crate:AddItem(S.crowbar) end)
    local cc = H.cc()
    cc._expandedStacks["Base.Crowbar"] = S.cbStackWas
    for _, c in ipairs({ cc, H.wc() }) do
        local sel = c._selectedItems or {}
        for k in pairs(sel) do sel[k] = nil end
        c._lastClickedItem = nil
    end
    pcall(function() RT.cw()._updateDrawer(cc) end)
    pcall(function() RT.ww()._updateDrawer() end)
end)

-- ===================================================================== 6f. the pad on the bag: L3 sort, marks, B, X
-- (FocusManager's own presses: the input mode locked to the controller, the Character window holding the pad, as
-- rt_cards.lua does)
S.Fo = RT.focus()
function H.padOn(w)
    if not S.padIsOn then
        pcall(function() local md = S.p:getModData().ZeD_Gamepad; S.lockWas = md and md.inputModeLock end)
        pcall(function() ZeD.Input.Detector.setLockedMode("gamepad") end)
        S.padIsOn = true
    end
    if w and S.Fo and S.Fo.claimFocus then pcall(S.Fo.claimFocus, w) end
end
function H.padOff()
    if not S.padIsOn then return end
    S.padIsOn = nil
    for _, b in ipairs({ "A", "B", "X" }) do RT.pad(b, nil) end
    pcall(function() S.Fo.releaseFocus(S.pn) end)
    pcall(function()
        local Dt = ZeD.Input.Detector
        Dt.setLockedMode(nil)
        if S.lockWas == "kbm" or S.lockWas == "gamepad" then Dt.setLockedMode(S.lockWas) end
    end)
end
function H.focusItem(w, zone, item)
    local e = nil
    pcall(function() e = S.Fo.focusWhere(w, zone, function(el) return el.item == item end) end)
    return e
end
function H.focused(w)
    local e = nil
    pcall(function() e = S.Fo.getFocusedElement(w) end)
    return e
end
-- queue a tap (holdMs 0) or a hold of a pad button on window w (getW: a function giving w)
function H.queuePress(name, button, getW, holdMs)
    Q.step(1, function()
        local w = getW()
        if not w then return end
        RT.pad(name, true); RT.padDown(button, w)
    end)
    if holdMs and holdMs > 0 then Q.waitMs(holdMs) else Q.step(4, function() end) end
    Q.step(1, function() RT.pad(name, false) end)
    Q.step(4, function() RT.pad(name, nil) end)
end
step(2, function()
    H.padOn(RT.cw())
    H.sortTo(H.cc(), "name", true)
end)
-- L3: a second press turns the sort round, the next goes on to the next column (Category), A-Z first
step(3, function() RT.padDown(Joypad.LStickButton, RT.cw()) end)
step(3, function()
    local cc = H.cc()
    local okO, why = H.order(cc, "name", false)
    Q.check(cc._sortCol == "name" and cc._sortAsc == false and okO, "pad L3 on Name A-Z turns it to Z-A", tostring(cc._sortCol) .. " " .. tostring(cc._sortAsc) .. "; " .. why)
    RT.padDown(Joypad.LStickButton, RT.cw())
end)
step(3, function()
    local cc = H.cc()
    Q.check(cc._sortCol == "cat" and cc._sortAsc == true, "pad L3 again goes on to Category A-Z", tostring(cc._sortCol) .. " " .. tostring(cc._sortAsc))
    if not H.sortTo(cc, "name", true) then cc._sortCol, cc._sortAsc = "name", true end
    H.reveal(cc, S.mover)
end)
-- hold A on the pan's row marks it; with A still held a D-pad step paints the row it lands on; B clears the marks
-- and leaves the focus where it is
waitFor(4, 120, function() return H.focusItem(RT.cw(), "charMainInv", S.mover) ~= nil end, function(ok)
    S.markArmed = ok
    Q.check(ok, "pad: the focus lands on the pan's row (charMainInv)")
    local rows = H.cc()._invRowItems or {}
    local idx = 0
    for i, it in ipairs(rows) do if it == S.mover then idx = i end end
    S.paintDir = (idx > 0 and idx < #rows) and "down" or "up"
end)
Q.step(1, function() if S.markArmed then RT.pad("A", true); RT.padDown(Joypad.AButton, RT.cw()) end end)
Q.waitMs(600)
step(1, function()
    if not S.markArmed then return end
    local IR = ZeD.InventoryRenderer
    local sel = H.cc()._selectedItems or {}
    Q.check(IR.padMarkCount(RT.cw()) == 1 and sel[S.mover] == true, "pad: hold A on the pan's row marks it (one mark)",
        IR.padMarkCount(RT.cw()) .. " marked")
    RT.padDir(S.paintDir, RT.cw())
end)
step(3, function()
    if not S.markArmed then return end
    local IR = ZeD.InventoryRenderer
    local e = H.focused(RT.cw())
    local sel = H.cc()._selectedItems or {}
    Q.check(e ~= nil and e.item ~= nil and e.item ~= S.mover and sel[e.item] == true and IR.padMarkCount(RT.cw()) >= 2,
        "pad: with A held, D-pad " .. S.paintDir .. " paints the row it lands on", IR.padMarkCount(RT.cw()) .. " marked, on "
        .. tostring(e and e.item and e.item:getName()))
    RT.pad("A", false)
end)
step(4, function() RT.pad("A", nil) end)
step(2, function()
    if not S.markArmed then return end
    local e = H.focused(RT.cw())
    S.focusIdWas = e and e.id
    RT.padDown(Joypad.BButton, RT.cw())
end)
step(3, function()
    if not S.markArmed then return end
    local e = H.focused(RT.cw())
    Q.check(ZeD.InventoryRenderer.padMarkCount(RT.cw()) == 0 and e ~= nil and e.id == S.focusIdWas,
        "pad: B clears every mark and the focus stays where it was", tostring(S.focusIdWas) .. " -> " .. tostring(e and e.id))
end)
-- X tapped on a row moves it to the other window's container (the crate), and from the crate back to the bag
waitFor(2, 120, function() return H.focusItem(RT.cw(), "charMainInv", S.mover) ~= nil end, function(ok)
    S.xArmed = ok
    H.counts()
    Q.check(ok, "pad: the focus is on the pan's row for X")
end)
H.queuePress("X", Joypad.XButton, function() return S.xArmed and RT.cw() or nil end, 0)
waitFor(5, 900, function() return H.queueEmpty() and H.where(S.mover) == S.crate end, function()
    H.moveCheck("pad: X on the pan's row in the bag moves it to the crate, and the counts agree", true)
end)
step(4, function()
    H.counts()
    H.padOn(RT.ww())
    H.reveal(H.wc(), S.mover)
end)
waitFor(4, 120, function() return H.focusItem(RT.ww(), "worldMainInv", S.mover) ~= nil end, function(ok)
    S.xArmed = ok
    Q.check(ok, "pad: the focus lands on the pan's row in the crate (worldMainInv)")
end)
H.queuePress("X", Joypad.XButton, function() return S.xArmed and RT.ww() or nil end, 0)
waitFor(5, 900, function() return H.queueEmpty() and H.where(S.mover) == S.bag end, function()
    H.moveCheck("pad: X on the pan's row in the crate moves it back to the bag, and the counts agree", false)
end)
step(4, function()
    H.padOff()
    for _, c in ipairs({ H.cc(), H.wc() }) do
        local sel = c._selectedItems or {}
        for k in pairs(sel) do sel[k] = nil end
        c._lastClickedItem = nil
        c._padMarks = nil
    end
    pcall(function() RT.cw()._updateDrawer(H.cc()) end)
    pcall(function() RT.ww()._updateDrawer() end)
end)

-- ===================================================================== 7. the container buttons
step(4, function()
    -- (QA, Nov 22 2026, refit for branch listgrid 1916f88ab, the director's "Transfer buttons, always in the footer":
    -- the band's Take all ("take") is back and is the one pressed. view:lootall:<key> is now a Loot column's own foot,
    -- so it stands in only where the list is in Loot columns (content._colStates); a single list with no band Take
    -- all FAILS.)
    local wc = H.wc()
    local ok, why = H.ccPress(wc, "take")
    local cols = wc ~= nil and wc._colStates ~= nil and #wc._colStates > 0
    if not ok and why == "no button take" and cols then
        local z = H.zoneStarts(wc, "view:lootall:")
        if z and z.w > 0 then
            H.click(wc, z)
            ok, why = true, "the Loot column's foot Take all (" .. tostring(z.id) .. ")"
        else why = "no Take all in the band nor in the column's foot" end
    elseif not ok and why == "no button take" then
        why = "no Take all in the World band (a single list: the band holds it)"
    end
    Q.check(ok, "the crate's Loot all button presses (the band's; a Loot column's foot only in columns)", why)
end)
waitFor(10, 900, H.queueEmpty, function()
    -- (a thing the bag has no room for stays, as the game's transfer refuses it)
    local inBag, full, left = 0, 0, {}
    for _, it in ipairs(S.crateGiven) do
        if H.where(it) == S.bag then inBag = inBag + 1
        else
            local room = true
            pcall(function() room = S.bag:hasRoomFor(S.p, it) end)
            if room then left[#left + 1] = tostring(it:getName()) else full = full + 1 end
        end
    end
    Q.check(#left == 0 and inBag > 0, "Loot all takes everything from the crate into the bag (all the bag has room for)",
        inBag .. " of " .. #S.crateGiven .. " in the bag, " .. full .. " too heavy for it"
        .. ((#left > 0) and ("; left: " .. table.concat(left, ", ")) or ""))
end)
step(4, function()
    -- what Transfer all should move: ContainerControls' transferAllItems rule (nothing worn, held, favourite,
    -- on the hotbar or a key ring)
    S.xfer = {}
    local hot = nil
    pcall(function() hot = getPlayerHotbar(S.pn) end)
    for _, it in ipairs(H.list(S.bag)) do
        local keep = H.held(it)
        pcall(function() keep = keep or it:isFavorite() or (hot ~= nil and hot:isInHotbar(it)) end)
        pcall(function() keep = keep or it:isItemType(ItemType.KEY_RING) or it:hasTag(ItemTag.KEY_RING) end)
        if not keep then S.xfer[#S.xfer + 1] = it end
    end
    local ok, why = H.ccPress(H.cc(), "xfer")
    Q.check(ok, "the bag's Transfer all button presses", why)
end)
waitFor(10, 1800, H.queueEmpty, function()
    local moved, full, left = 0, 0, {}
    for _, it in ipairs(S.xfer) do
        if H.where(it) == S.crate then moved = moved + 1
        else
            local room = true
            pcall(function() room = S.crate:hasRoomFor(S.p, it) end)
            if not room then full = full + 1 else left[#left + 1] = tostring(it:getName()) end
        end
    end
    Q.check(#left == 0 and moved > 0,
        "Transfer all moves every thing it should into the crate (all the crate has room for)",
        moved .. " moved, " .. full .. " too big for what room was left" .. ((#left > 0) and ("; left: " .. table.concat(left, ", ")) or ""))
    Q.say("the bag's own things put back: " .. H.restoreBag())
    -- (the test's things that found no room go into the crate by hand, so To floor has all of them to drop)
    local byHand = 0
    for _, it in ipairs(S.crateGiven) do
        if H.where(it) ~= S.crate then H.removeItem(it); pcall(function() S.crate:AddItem(it) end); byHand = byHand + 1 end
    end
    if byHand > 0 then Q.say(byHand .. " of the test's things put in the crate by hand for To floor") end
end)
step(4, function()
    local ok, why = H.ccPress(H.wc(), "floor")
    Q.check(ok, "the crate's To floor button presses", why)
end)
waitFor(10, 900, H.queueEmpty, function()
    local onFloor = 0
    for _, it in ipairs(S.crateGiven) do
        local wo = nil
        pcall(function() wo = it:getWorldItem() end)
        if wo then onFloor = onFloor + 1 end
    end
    Q.check(onFloor == #S.crateGiven and H.inCrate(S.crateGiven) == 0, "To floor puts every thing in the crate on the floor",
        onFloor .. " of " .. #S.crateGiven .. " on the floor, " .. H.size(S.crate) .. " left in the crate")
end)

-- ===================================================================== 8. the ledger's rows (FEATURE_MAP.md, Check "rt_inv")
-- (Nov 18 2026, QA's ledger pass: a row is covered only by a check that measures it. These are the rows the ledger
-- gave this script that nothing above measured; each says what it measures. Put back by H.ledgerBack.)
function H.has(list, v) for _, x in ipairs(list or {}) do if x == v then return true end end; return false end
function H.cwC() local w = RT.cw(); return w and w._containers end
function H.inCw(inv) for _, c in ipairs(H.cwC() or {}) do if c.inventory == inv then return true end end; return false end
function H.pause(on)
    S.pausedByMe = on and true or nil
    local sp = on and 0 or 1
    pcall(function() UIManager.getSpeedControls():SetCurrentGameSpeed(sp) end)
    if ZEDQA_SPEED then pcall(ZEDQA_SPEED, sp) else pcall(setGameSpeed, sp) end
end

-- 8a. the Character window on a tab from code (Overrides/CharacterInfo.lua's openTab): the tab within 20 drawn
-- frames, its drawer open; with toggle a second call on the open tab folds it
step(2, function()
    RT.charTab("loot")
    S.ot1 = ZeD_CharacterWindow.openTab(S.pn, "skills")
end)
waitFor(1, 20, function() local w = RT.cw(); return w ~= nil and w._activeTab == "skills" and w._drawerMode == "tab" and w._drawerOpen == true end, function(ok)
    local w = RT.cw()
    Q.check(S.ot1 == true and ok, "openTab (Character window): on Skills within 20 frames, its drawer open",
        "returned " .. tostring(S.ot1) .. ", tab " .. tostring(w and w._activeTab) .. ", open " .. tostring(w and w._drawerOpen))
    S.ot2 = ZeD_CharacterWindow.openTab(S.pn, "skills", true)
end)
waitFor(1, 20, function() local w = RT.cw(); return w ~= nil and not (w._activeTab == "skills" and w._drawerOpen == true) end, function(ok)
    Q.check(S.ot2 == true and ok, "openTab (Character window) with toggle on the open tab folds it", tostring(RT.cw() and RT.cw()._activeTab))
    RT.charTab("loot")
end)
-- 8b. the game's Character window pages (ISCharacterInfoWindow:toggleView) land on ZeD's tabs; the game's stays hidden
step(4, function()
    S.ip = nil
    pcall(function() S.ip = getPlayerInfoPanel(S.pn) end)
    S.ipN0 = (ZeD.CharInfoRoute and ZeD.CharInfoRoute.count) or 0
    if S.ip then pcall(function() S.ip:toggleView(getText("IGUI_XP_Health")) end) end
end)
waitFor(1, 30, function() local w = RT.cw(); return S.ip == nil or (w ~= nil and w._activeTab == "health" and w._drawerOpen == true) end, function(ok)
    if not S.ip then Q.skip("the game's Health page goes to ZeD's Health tab", "the game made no Character info panel for this player"); return end
    local vis = true
    pcall(function() vis = S.ip:getIsVisible() end)
    local n1 = (ZeD.CharInfoRoute and ZeD.CharInfoRoute.count) or 0
    Q.check(ok and not vis and n1 > S.ipN0, "the game's Health page (toggleView) opens ZeD's Health tab, the game's window hidden",
        "tab " .. tostring(RT.cw() and RT.cw()._activeTab) .. ", game's window " .. tostring(vis) .. ", routed " .. S.ipN0 .. " -> " .. n1)
    RT.charTab("loot")
end)
-- 8c. the Loot columns from code (toggleColumn): a bag given, its column opens (one more in _mcSelected); any other
-- tab closes the columns
-- (the Character window lists a carried bag only when it is equipped: the bag is held in the second hand, and the
-- hand given back what it held before the bag goes)
step(4, function()
    S.colBag = RT.give("Base.Bag_Schoolbag")
    S.colInv = nil
    S.colHandWas = nil
    pcall(function() S.colHandWas = S.p:getSecondaryHandItem() end)
    if S.colBag then pcall(function() S.p:setSecondaryHandItem(S.colBag) end) end
    pcall(function() S.colInv = S.colBag:getInventory() end)
    pcall(function() RT.cw()._containersDirty = true end)
end)
waitFor(2, 300, function() return S.colInv == nil or H.inCw(S.colInv) end, function(ok)
    if not Q.check(ok and S.colInv ~= nil, "Loot columns: the given school bag is in the Character window's containers") then return end
    local w = RT.cw()
    S.colN0 = #(w._mcSelected or {})
    S.colOk = ZeD_CharacterWindow.toggleColumn(S.colInv, S.pn)
end)
step(4, function()
    if not S.colN0 then return end
    local w = RT.cw()
    local n = #(w._mcSelected or {})
    Q.check(S.colOk == true and n == S.colN0 + 1, "toggleColumn (Character window): the bag's column opens, one more column",
        S.colN0 .. " -> " .. n)
    RT.charTab("skills")
end)
step(6, function()
    if S.colN0 then
        local w = RT.cw()
        Q.check(#(w._mcSelected or {}) == 0, "another tab than Loot closes the Character window's columns", #(w._mcSelected or {}) .. " left")
    end
    RT.charTab("loot")
    if S.colBag then
        pcall(function() if S.p:getSecondaryHandItem() == S.colBag then S.p:setSecondaryHandItem(S.colHandWas) end end)
        H.removeItem(S.colBag)
    end
    S.colBag, S.colHandWas = nil, nil
    pcall(function() RT.cw()._containersDirty = true end)
end)
-- 8d. the World window: a tab from code (openTab), its Loot columns (toggleColumn on the crate), close and open again
step(4, function() S.wot = ZeD_WorldWindow.openTab(S.pn, "craft") end)
waitFor(1, 20, function() return ZeD_WorldWindow.isTabShowing("craft", S.pn) end, function(ok)
    Q.check(S.wot == true and ok, "openTab (World window): isTabShowing(craft) within 20 frames", "returned " .. tostring(S.wot))
    RT.worldTab("loot")
end)
step(6, function()
    local ww = RT.ww()
    S.wcolN0 = #(ww._mcSelected or {})
    S.wcolOk = ZeD_WorldWindow.toggleColumn(S.crate, S.pn)
end)
step(4, function()
    local ww = RT.ww()
    local n = #(ww._mcSelected or {})
    Q.check(S.wcolOk == true and n == S.wcolN0 + 1, "toggleColumn (World window): the crate's column opens, one more column", S.wcolN0 .. " -> " .. n)
    pcall(ZeD_WorldWindow.closeColumns, ww)
end)
step(4, function()
    local ww = RT.ww()
    Q.check(#(ww._mcSelected or {}) == 0, "closeColumns (World window): back to the one list", #(ww._mcSelected or {}) .. " left")
    pcall(ZeD_WorldWindow.close, S.pn)
end)
step(4, function()
    local open, win = true, 1
    pcall(function() open = ZeD_WorldWindow.isOpen(S.pn); win = ZeD_WorldWindow.getWindow(S.pn) end)
    Q.check(open == false and win == nil, "World window close: isOpen false and getWindow nil", "open " .. tostring(open) .. ", window " .. tostring(win ~= nil))
    pcall(ZeD_WorldWindow.open, S.pn)
end)
waitFor(2, 120, function() return ZeD_WorldWindow.isOpen(S.pn) and ZeD_WorldWindow.getWindow(S.pn) ~= nil end, function(ok)
    Q.check(ok, "World window open: isOpen true and the window is there again")
    RT.worldTab("loot")
end)
-- 8e. the Equip tab (list view): the Equipped heading folds the slot list; a right-click on a worn slot opens the
-- game's menu for it; the Find field dims the slots that do not match and hides none
step(4, function()
    local D = ZeD.EquipDoll
    S.eqView = D and D.view()
    if D and S.eqView ~= "list" then pcall(D.setView, "list") end
    S.eqTab = RT.charTab("equip")
end)
waitFor(4, 120, function() local w = RT.cw(); return w ~= nil and w._activeTab == "equip" and w._equipDefenseZone ~= nil end, function(ok)
    local w = RT.cw()
    S.eqOk = Q.check(ok, "the Equip tab opens on its list (for its own rows)", "tab " .. tostring(w and w._activeTab))
    if not S.eqOk then return end
    S.eqExp = w._equipListExpanded and true or false
    local dz = w._equipDefenseZone
    local x, y = dz.x + math.min(ZeD.T.px(12), math.floor(dz.w / 2)), dz.y + math.floor(dz.h / 2)
    pcall(w._drawerPanel.onMouseDown, w._drawerPanel, x, y)
    pcall(w._drawerPanel.onMouseUp, w._drawerPanel, x, y)
    Q.check((w._equipListExpanded and true or false) ~= S.eqExp, "the Equipped heading pressed folds or opens the slot list",
        tostring(S.eqExp) .. " -> " .. tostring(w._equipListExpanded))
    pcall(w._drawerPanel.onMouseDown, w._drawerPanel, x, y)
    pcall(w._drawerPanel.onMouseUp, w._drawerPanel, x, y)
    Q.check((w._equipListExpanded and true or false) == S.eqExp, "the Equipped heading pressed again is back as it was")
    w._equipListExpanded = true
end)
step(6, function()
    S.slotItem = nil
    if not S.eqOk then return end
    local w = RT.cw()
    local z = nil
    for _, sz in ipairs(w._equipSlotZones or {}) do if not z and sz.item then z = sz end end
    if not z then Q.skip("Right-click slot menu", "the character wears nothing to right-click"); return end
    S.slotItem = z.item
    H.closeMenu()
    pcall(w._drawerPanel.onRightMouseUp, w._drawerPanel, z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
end)
waitFor(2, 120, function() return S.slotItem == nil or H.menu() ~= nil end, function(ok)
    if not S.slotItem then return end
    local m = H.menu()
    local on = false
    for _, t in ipairs((m and m._ctx and type(m._ctx.target) == "table") and m._ctx.target or {}) do if t == S.slotItem then on = true end end
    Q.check(ok and on, "a right-click on a worn slot opens the game's menu on that thing (ZeD's menu)",
        "menu " .. tostring(m and m.Type) .. ", on it " .. tostring(on))
    H.closeMenu()
end)
step(4, function()
    S.fq = nil
    if not S.eqOk then return end
    local w = RT.cw()
    S.fz = {}
    for _, sz in ipairs(w._equipSlotZones or {}) do if sz.item then S.fz[#S.fz + 1] = { type = sz.type, item = sz.item } end end
    if #S.fz < 2 then Q.skip("Find (Equipment)", "fewer than two worn things to tell apart"); return end
    S.fq = string.lower(tostring(S.fz[1].item:getDisplayName()))
    ZeD.TabFind.setText(w, "equip", S.fq)
end)
step(6, function()
    if not S.fq then return end
    local w = RT.cw()
    local TF = ZeD.TabFind
    local dimmed, n = 0, 0
    for _, sz in ipairs(w._equipSlotZones or {}) do if sz.item then n = n + 1 end end
    for i = 2, #S.fz do if TF.equipOff(w, S.fz[i].type) then dimmed = dimmed + 1 end end
    Q.check(not TF.equipOff(w, S.fz[1].type) and dimmed > 0 and n == #S.fz,
        "Find (Equipment): the slot that matches stays lit, others dim, none hidden",
        "\"" .. S.fq .. "\": " .. dimmed .. " of " .. (#S.fz - 1) .. " others dimmed, " .. n .. " of " .. #S.fz .. " slots drawn")
    TF.clear(w, "equip")
end)
step(4, function()
    if not S.fq then return end
    local w = RT.cw()
    local lit = 0
    for _, z in ipairs(S.fz) do if not ZeD.TabFind.equipOff(w, z.type) then lit = lit + 1 end end
    Q.check(lit == #S.fz, "Find (Equipment) cleared: every slot lit again", lit .. " of " .. #S.fz)
end)
-- 8f. the Skills tab's Find field: a skill's name keeps its row lit and dims the rest
step(2, function()
    RT.charTab("skills")
    local w = RT.cw()
    S.skGrid = w and w._skillsGridExpanded
    if w then w._skillsGridExpanded = true end
end)
waitFor(4, 120, function() local w = RT.cw(); return w ~= nil and w._activeTab == "skills" and #(w._skillRowZones or {}) >= 2 end, function(ok)
    S.sq = nil
    if not Q.check(ok, "the Skills tab draws its skill rows (for Find)") then return end
    local w = RT.cw()
    S.skNames = {}
    for _, z in ipairs(w._skillRowZones) do if z.name then S.skNames[#S.skNames + 1] = tostring(z.name) end end
    S.sq = string.lower(S.skNames[1])
    ZeD.TabFind.setText(w, "skills", S.sq)
end)
step(6, function()
    if not S.sq then return end
    local w = RT.cw()
    local TF = ZeD.TabFind
    local dimmed, want = 0, 0
    for i = 2, #S.skNames do
        if not string.find(string.lower(S.skNames[i]), S.sq, 1, true) then
            want = want + 1
            if TF.skillOff(w, S.skNames[i]) then dimmed = dimmed + 1 end
        end
    end
    Q.check(not TF.skillOff(w, S.skNames[1]) and want > 0 and dimmed > 0, "Find (Skills): the skill typed stays lit, the others dim",
        "\"" .. S.sq .. "\": " .. dimmed .. " of " .. want .. " others dimmed")
    TF.clear(w, "skills")
end)
step(4, function()
    if not S.sq then return end
    Q.check(not ZeD.TabFind.skillOff(RT.cw(), S.skNames[2]), "Find (Skills) cleared: the rows are lit again")
    local w = RT.cw()
    if w and S.skGrid ~= nil then w._skillsGridExpanded = S.skGrid end
end)
-- 8g. the Identity tab: the license card in each forced form (IdentityTab's QA hooks qaStyle, qaLayout) draws that
-- form, on screen; the photo pressed swaps bust and full body, the wheel zooms the full body
step(2, function()
    S.idOk = RT.charTab("identity")
    ZeD.IdentityTab.qaStyle, ZeD.IdentityTab.qaLayout = "simple", "tall"
end)
waitFor(4, 120, function() local w = RT.cw(); return w ~= nil and w._activeTab == "identity" and w._idSimple == true and w._idTall == true end, function(ok)
    Q.check(ok, "License card: forced Simple and narrow, it draws Simple and narrow", "simple " .. tostring(RT.cw()._idSimple) .. ", tall " .. tostring(RT.cw()._idTall))
    RT.bounds(Q, "the license card, Simple and narrow")
    ZeD.IdentityTab.qaStyle, ZeD.IdentityTab.qaLayout = "immersive", "wide"
end)
waitFor(2, 120, function() local w = RT.cw(); return w ~= nil and w._idSimple == false and w._idTall == false end, function(ok)
    Q.check(ok, "License card: forced Immersive and wide, it draws Immersive and wide", "simple " .. tostring(RT.cw()._idSimple) .. ", tall " .. tostring(RT.cw()._idTall))
    RT.bounds(Q, "the license card, Immersive and wide")
    ZeD.IdentityTab.qaStyle, ZeD.IdentityTab.qaLayout = nil, nil
end)
function H.photoPress()
    local w = RT.cw()
    local m = w and w._identityModel
    if not m then return false end
    pcall(m.onMouseDown, m, 5, 5)
    pcall(m.onMouseUp, m, 5, 5)
    return true
end
step(4, function()
    local w = RT.cw()
    S.phWas = w._identityPhotoExpanded and true or false
    local pressed = H.photoPress()
    Q.check(pressed and (w._identityPhotoExpanded and true or false) ~= S.phWas, "Photo: a press on it swaps bust and full body",
        tostring(S.phWas) .. " -> " .. tostring(w._identityPhotoExpanded))
    if not w._identityPhotoExpanded then H.photoPress() end
end)
step(4, function()
    local w = RT.cw()
    local m = w._identityModel
    local z0 = w._identityCustomZoom or 0
    if m then pcall(m.onMouseWheel, m, 1) end
    Q.check(w._identityPhotoExpanded == true and (w._identityCustomZoom or 0) ~= z0, "Photo: on the full body the wheel zooms",
        tostring(z0) .. " -> " .. tostring(w._identityCustomZoom))
    if (w._identityPhotoExpanded and true or false) ~= S.phWas then H.photoPress() end
    w._identityCustomZoom = 0
    RT.charTab("loot")
end)
-- 8h. the tabs that show in context: Cooking with a pot (of water) and food on the player; Fishing with a rod in hand
step(4, function()
    local w = RT.cw()
    local s = w and w._cook
    if s then s.visAt = nil; s.scanAt = -1 end
    S.cookWas = ZeD.CookingTab.visible(w)
    S.cook = { RT.give("Base.Pot"), RT.give("Base.Carrots"), RT.give("Base.Potato") }
    pcall(function() local fc = S.cook[1]:getFluidContainer(); fc:addFluid(Fluid.Water, fc:getCapacity()) end)
    if s then s.visAt = nil; s.scanAt = -1 end
end)
waitFor(4, 300, function()
    local w = RT.cw()
    return w ~= nil and H.has(RT.tabs(RT.charStrip()), "cooking")
end, function(ok)
    Q.check(ok and ZeD.CookingTab.visible(RT.cw()), "a pot of water and food on the player: the Cooking tab is on the strip",
        table.concat(RT.tabs(RT.charStrip()), " "))
    for _, it in ipairs(S.cook) do H.removeItem(it) end
end)
waitFor(4, 300, function() return S.cookWas or not H.has(RT.tabs(RT.charStrip()), "cooking") end, function(ok)
    if S.cookWas then Q.say("NOTE the Cooking tab was on the strip before the pot: its going is not checked"); return end
    Q.check(ok, "the pot taken back: the Cooking tab leaves the strip")
end)
step(4, function()
    S.fishWas = ZeD.FishingLog.visible(S.p)
    S.rod = RT.give("Base.FishingRod")
    if S.rod then pcall(function() S.p:setPrimaryHandItem(S.rod) end) end
end)
waitFor(4, 300, function() return H.has(RT.tabs(RT.worldStrip()), "fishing") end, function(ok)
    Q.check(ok and ZeD.FishingLog.visible(S.p), "a fishing rod in the hand: the World window offers the Fishing tab",
        table.concat(RT.tabs(RT.worldStrip()), " "))
    pcall(function() S.p:setPrimaryHandItem(S.handWas[1]) end)
    if S.rod then H.removeItem(S.rod) end
end)
waitFor(4, 300, function() return S.fishWas or not H.has(RT.tabs(RT.worldStrip()), "fishing") end, function(ok)
    if S.fishWas then Q.say("NOTE water is near: the Fishing tab stays without the rod (its going is not checked)"); return end
    Q.check(ok, "the rod put away (no water near): the Fishing tab leaves the strip")
end)
-- 8i. Moodle notices (ZeD setup's switch, off by default): on, a moodle that comes on queues its notice, which shows
-- and leaves after its few seconds. Boredom is moved for it (put back, with god mode).
step(4, function()
    local Mo, St = ZeD.Moodles, ZeD.Settings
    S.mnOpt = St and St.moodleNoticesOption
    S.mnL = Mo and Mo.getLayer and Mo.getLayer(S.pn)
    if not (S.mnOpt and S.mnL) then S.mnSkip = true; Q.check(false, "Moodle notices: the switch and the moodles' layer are there"); return end
    S.mnWas = S.mnOpt:getValue()
    pcall(function() S.mnOpt:setValue(2) end)
    pcall(function() S.mnGod = S.p:isGodMod(); S.p:setGodMod(false) end)
    pcall(function() S.mnBored = S.p:getStats():get(CharacterStat.BOREDOM) end)
    -- (a moodle that goes away queues nothing: Bored is brought on, or moved a level while it stays on. Boredom runs
    -- 0..100 in B42: the stat's own maximum scales the levels)
    local top = 100
    pcall(function() local m = CharacterStat.BOREDOM:getMaximumValue(); if m and m > 0 then top = m end end)
    S.mnTo = ((S.mnBored or 0) < top * 0.5) and (top * 0.9) or (top * 0.3)
    pcall(function() S.p:getStats():set(CharacterStat.BOREDOM, S.mnTo) end)
end)
waitFor(4, 300, function() return S.mnSkip or H.has(S.mnL._notices, "BORED") end, function(ok)
    if S.mnSkip then return end
    Q.check(ok, "Moodle notices on: a moodle that changes queues its notice", "boredom " .. tostring(S.mnBored) .. " -> " .. S.mnTo
        .. "; queued: " .. table.concat(S.mnL._notices or {}, " "))
end)
waitFor(4, 1500, function() return S.mnSkip or #(S.mnL._notices or {}) == 0 end, function(ok)
    if S.mnSkip then return end
    Q.check(ok, "Moodle notices: the notice shows its few seconds and leaves", "left: " .. table.concat(S.mnL._notices or {}, " "))
    H.moodleBack()
end)
function H.moodleBack()
    if S.mnWas == nil then return end
    pcall(function() S.p:getStats():set(CharacterStat.BOREDOM, S.mnBored or 0) end)
    pcall(function() S.mnOpt:setValue(S.mnWas) end)
    pcall(function() S.p:setGodMod(S.mnGod and true or false) end)
    S.mnWas = nil
end
-- 8j. the paused notice: paused, with a window over the screen's middle, ZeD's balloon shows at the top, on screen;
-- playing again it goes
step(4, function()
    local W, Hh = getCore():getScreenWidth(), getCore():getScreenHeight()
    pcall(function()
        local pnl = ISPanel:new(math.floor(W / 2) - 60, math.floor(Hh / 2) - 60, 120, 120)
        pnl:initialise()
        pnl:addToUIManager()
        S.pnPanel = pnl
    end)
    H.pause(true)
end)
function H.noticeBox() return RT.find(function(t) return t.Type == "ZeD_PausedNoticeBox" end) end
waitFor(4, 120, function() return H.noticeBox() ~= nil end, function(ok)
    local b, e = H.noticeBox()
    local y = e and e:getY() or -1
    Q.check(ok and y >= 0 and y <= ZeD.T.px(40), "paused under a window: the Paused balloon shows at the top of the screen",
        "box " .. tostring(b ~= nil) .. " at y " .. tostring(y))
    RT.bounds(Q, "the paused balloon")
    if S.pnPanel then pcall(function() S.pnPanel:setVisible(false); S.pnPanel:removeFromUIManager() end); S.pnPanel = nil end
    H.pause(false)
end)
waitFor(2, 120, function() return H.noticeBox() == nil end, function(ok)
    Q.check(ok, "playing again, the Paused balloon goes")
end)
-- 8k. a controller nobody plays with (PadJoin.notice): a "Controller plugged in" note in Messages, no game list box
step(4, function()
    local PJ, MS = ZeD.PadJoin, ZeD.Messages
    if not (PJ and PJ.notice and MS) then Q.check(false, "PadJoin and Messages are loaded"); return end
    S.pjSrc = ZeD.tr("UI_ZeD_Pad_Source")
    S.pjHad = MS.sources[S.pjSrc] ~= nil
    pcall(PJ.notice, { id = 9 })
end)
step(4, function()
    local MS = ZeD.Messages
    if not (S.pjSrc and MS) then return end
    local s = MS.sources[S.pjSrc]
    local found = false
    for _, it in ipairs((s and s.items) or {}) do if it.k == "pad" and it.pad == "c9" then found = true end end
    local listed = false
    local mods = MS.list()
    for _, src in ipairs(mods or {}) do if src == s then listed = true end end
    local box = RT.find(function(t) return t.Type == "ISJoypadListBox" end)
    Q.check(found and listed and box == nil, "an unbound controller's press files \"Controller plugged in\" in Messages",
        "note " .. tostring(found) .. ", listed " .. tostring(listed) .. ", game list box " .. tostring(box ~= nil))
    H.pjBack()
end)
function H.pjBack()
    local MS = ZeD.Messages
    if not (S.pjSrc and MS) then return end
    local s = MS.sources[S.pjSrc]
    if s then for i = #s.items, 1, -1 do if s.items[i].pad == "c9" then table.remove(s.items, i) end end end
    if s and not S.pjHad and #s.items == 0 then MS.sources[S.pjSrc] = nil end
    S.pjSrc = nil
end
-- 8l. the Simple guide window (ZeD.Guide.openWindow): a topic's row pressed shows that topic; Next the one after it
step(4, function()
    S.gSpeed = getGameSpeed()
    S.gWin = nil
    pcall(function() S.gWin = ZeD.Guide.openWindow(S.pn) end)
end)
waitFor(3, 120, function() local w = S.gWin; return w == nil or (w:isReallyVisible() and #(w.flat or {}) >= 4) end, function(ok)
    local w = S.gWin
    if not Q.check(w ~= nil and ok, "the Simple guide window opens with its topics") then return end
    local t3, t4 = w.flat[3], w.flat[4]
    w:pressRow({ topic = t3 })
    Q.check(w.sel == t3.id, "the guide window: a topic's row pressed shows that topic", tostring(w.sel) .. ", want " .. tostring(t3.id))
    w:pressFoot({ id = "next" })
    Q.check(w.sel == t4.id, "the guide window: Next shows the topic after it", tostring(w.sel) .. ", want " .. tostring(t4.id))
    H.guideBack()
end)
function H.guideBack()
    if not S.gWin then return end
    pcall(function() if S.gWin:isReallyVisible() then S.gWin:close() end end)
    S.gWin = nil
    local sp = S.gSpeed or 1
    pcall(function() UIManager.getSpeedControls():SetCurrentGameSpeed(sp) end)
    if ZEDQA_SPEED then pcall(ZEDQA_SPEED, sp) else pcall(setGameSpeed, sp) end
end
-- 8m. the pinned restock to-do (ZeD_RestockPin): a loadout made for the test (ZeD.Lists, the Loadouts page's model)
-- asks for one thing the character lacks, which waits in the crate beside them; applied and restocked the Casual way
-- (ZeD_Restock.start), the to-do pins at the screen's left edge, on screen; the thing comes out of the crate into the
-- inventory (in reach: no walk), and once the list is done the pin goes. Put back: the list deleted, the applied
-- loadout, home, trip and run as found, the switches, the thing taken away.
step(4, function()
    local L, R, St = ZeD.Lists, ZeD.Restock, H.loadOpt()
    if not (L or (St and St.loadoutsOption)) then
        -- (ZeD alone after the split: Loadouts and Restock are the add-on's, and it is not loaded)
        Q.skip("restock: the to-do pins at the screen's left edge while it runs", "ZeD-GUI: Loadouts is not loaded: Restock is the add-on's since the split")
        return
    end
    if not (L and L.create and R and R.start and ZeD.RestockPin and St and St.loadoutsOption and St.restockOption) then
        Q.check(false, "restock: ZeD.Lists, ZeD.Restock, the pin and their switches are loaded"); return
    end
    local inv = S.p:getInventory()
    for _, ft in ipairs({ "Base.Twine", "Base.Screwdriver", "Base.Saw", "Base.Scissors", "Base.Hammer" }) do
        local have = true
        pcall(function() have = inv:getCountTypeRecurse(ft) > 0 end)
        if not S.rsType and not have then S.rsType = ft end
    end
    if not Q.check(S.rsType ~= nil, "restock: a kind of thing the character lacks is found") then return end
    local s = L.store(S.p)
    local a = R.applied(S.p)
    S.rs = { load = St.loadoutsOption:getValue(), mode = St.restockOption:getValue(), loadout = a.loadout, home = s.home,
        trip = s.trip, nextId = s.nextId, run = R.runs[S.pn] }
    pcall(function() St.loadoutsOption:setValue(2) end)
    pcall(function() St.restockOption:setValue(2) end)   -- (Casual)
    local l = L.create(S.p, "loadout", "zedqa restock")
    S.rs.id = l and l.id
    if l then L.addLine(S.p, l.id, { type = S.rsType, unit = "n", amount = 1 }) end
    pcall(function() S.rsItem = S.crate:AddItem(S.rsType) end)
    if not Q.check(l ~= nil and S.rsItem ~= nil, "restock: a loadout asks for a " .. S.rsType .. " the crate holds") then return end
    -- (Casual restock takes nothing past what the character can carry, and the steps before leave them loaded: what
    -- is loose in the inventory, not held, worn or on the belt, waits in the crate until the put-back)
    if not H.rsShed() then return end
    R.setLoadout(S.p, l.id)
    S.rsRun = R.start(S.p, "restock")
end)
function H.rsLoad()
    local load, most = 0, 0
    pcall(function() load, most = S.p:getInventoryWeight(), S.p:getMaxWeight() end)
    return load or 0, most or 0
end
function H.rsShed()
    local need = 0
    pcall(function() need = S.rsItem:getUnequippedWeight() or 0 end)
    local load0, most = H.rsLoad()
    S.rsShed = {}
    if load0 + need > most then
        local inv = S.p:getInventory()
        local loose = {}
        pcall(function()
            local items = inv:getItems()
            for i = 0, items:size() - 1 do loose[#loose + 1] = items:get(i) end
        end)
        for _, it in ipairs(loose) do
            local load = H.rsLoad()
            if load + need <= most then break end
            local keep = true
            pcall(function() keep = S.p:isEquipped(it) or (it:getAttachedSlot() or -1) > -1 end)
            if not keep then
                pcall(function() inv:Remove(it); S.crate:AddItem(it) end)
                if H.where(it) == S.crate then S.rsShed[#S.rsShed + 1] = it end
            end
        end
    end
    local load = H.rsLoad()
    if load + need > most then
        Q.skip("restock: the missing thing comes out of the crate to the character, the list done",
            string.format("the character carries %.2f of %.2f even with %d loose things set in the crate, the %s weighs %.2f",
                load, most, #S.rsShed, tostring(S.rsType), need))
        return false
    end
    return true
end
function H.rsUnshed()
    local inv = S.p:getInventory()
    for _, it in ipairs(S.rsShed or {}) do
        if H.where(it) == S.crate then pcall(function() S.crate:Remove(it); inv:AddItem(it) end) end
    end
    S.rsShed = nil
end
function H.pin() local P = ZeD.RestockPin; return P and P.panels and P.panels[S.pn] end
waitFor(4, 300, function() local pin = H.pin(); return S.rsRun == nil or (pin ~= nil and pin:isVisible()) end, function(ok)
    if not S.rsRun then return end
    local pin = H.pin()
    local x = pin and pin:getX() or -1
    Q.check(ok and x >= 0 and x < getCore():getScreenWidth() / 4, "restock: the to-do pins at the screen's left edge while it runs",
        "pin " .. tostring(pin ~= nil) .. " at x " .. tostring(x) .. ", mode " .. tostring(S.rsRun.mode))
    RT.bounds(Q, "the pinned restock to-do")
end)
waitFor(4, 1200, function()
    if not S.rsRun then return true end
    return S.rsRun.done == true and H.where(S.rsItem) ~= S.crate
end, function(ok)
    if not S.rsRun then return end
    local c = H.where(S.rsItem)
    Q.check(ok and c ~= nil and c:isInCharacterInventory(S.p), "restock: the missing thing comes out of the crate to the character, the list done",
        "done " .. tostring(S.rsRun.done) .. ", stopped " .. tostring(S.rsRun.stopped))
end)
waitFor(4, 900, function() return S.rsRun == nil or H.pin() == nil end, function(ok)
    if not S.rsRun then return end
    Q.check(ok, "restock: the list done, the pin goes after its last line")
    H.restockBack()
end)
function H.restockBack()
    if not S.rs then return end
    local L, R, St = ZeD.Lists, ZeD.Restock, H.loadOpt()
    pcall(function() if S.rsRun and not S.rsRun.done then R.stop(S.p, nil) end end)
    pcall(function() R.runs[S.pn] = S.rs.run end)
    pcall(function() ZeD.RestockPin.hide(S.pn) end)
    pcall(function() R.setLoadout(S.p, S.rs.loadout) end)
    pcall(function() if S.rs.id then L.delete(S.p, S.rs.id) end end)
    pcall(function() local s = L.store(S.p); s.home, s.trip, s.nextId = S.rs.home, S.rs.trip, S.rs.nextId end)
    pcall(function() St.loadoutsOption:setValue(S.rs.load) end)
    pcall(function() St.restockOption:setValue(S.rs.mode) end)
    if S.rsItem then H.removeItem(S.rsItem) end
    H.rsUnshed()
    S.rs, S.rsRun = nil, nil
end
function H.ledgerBack()
    H.restockBack()
    H.moodleBack()
    H.pjBack()
    H.guideBack()
    if S.pnPanel then pcall(function() S.pnPanel:setVisible(false); S.pnPanel:removeFromUIManager() end); S.pnPanel = nil end
    if S.pausedByMe then H.pause(false) end
    pcall(function() ZeD.IdentityTab.qaStyle, ZeD.IdentityTab.qaLayout = nil, nil end)
    pcall(function()
        local w = RT.cw()
        if S.fq then ZeD.TabFind.setText(w, "equip", "") end
        if S.sq then ZeD.TabFind.setText(w, "skills", "") end
        if S.skGrid ~= nil then w._skillsGridExpanded = S.skGrid end
    end)
    if S.eqView == "doll" then pcall(ZeD.EquipDoll.setView, "doll") end
    for _, it in ipairs(S.cook or {}) do H.removeItem(it) end
    if S.rod then H.removeItem(S.rod) end
    if S.colBag then H.removeItem(S.colBag) end
    pcall(function() if not ZeD_WorldWindow.isOpen(S.pn) then ZeD_WorldWindow.open(S.pn) end end)
end

-- ===================================================================== put back
Q.mark()
Q.step(2, function()
    H.ledgerBack()
    H.closeMenu()
    H.capUnhook()
    H.padOff()
    for _, b in ipairs({ "A", "B", "X" }) do RT.pad(b, nil) end
    -- (the filter, the column, the tiles switch and the crowbar's stack, as found: a run cut short leaves them)
    if S.F and S.F.open then pcall(ZeD.InvFilter.toggleOpen, S.F) end
    pcall(function() if S.crateKey then local st = S.p:getModData().ZeD_Filters; if st then st[S.crateKey] = nil end end end)
    pcall(function() if S.colWas then H.cc()._colWidths.wt = S.colWas end end)
    pcall(function() if S.tintWas then H.tintSet(S.tintWas) end end)
    pcall(function() if S.cbStackWas ~= nil or S.crowbar then H.cc()._expandedStacks["Base.Crowbar"] = S.cbStackWas end end)
    pcall(function() if S.handWas then S.p:setPrimaryHandItem(S.handWas[1]); S.p:setSecondaryHandItem(S.handWas[2]) end end)
    for _, c in ipairs({ H.cc(), H.wc() }) do
        if c then
            local sel = c._selectedItems or {}
            for k in pairs(sel) do sel[k] = nil end
            c._lastClickedItem = nil
            if c._expandedStacks then c._expandedStacks[S.stackKey] = nil end
        end
    end
    pcall(function() RT.cw()._updateDrawer(H.cc()) end)
    pcall(function() RT.ww()._updateDrawer() end)
    pcall(function() ISTimedActionQueue.clear(S.p) end)
    if S.bag then H.restoreBag() end
    for _, it in ipairs(S.crateGiven) do H.removeItem(it) end
    for _, it in ipairs(RT.given) do pcall(function() if it:getWorldItem() then H.removeItem(it) end end) end
    if S.crateObj then
        pcall(function()
            local sq = S.crateObj:getSquare()
            if sq then pcall(function() sq:transmitRemoveItemFromSquare(S.crateObj) end); sq:RemoveTileObject(S.crateObj) end
        end)
    end
    local st = S.p:getModData().ZeD_GridViews
    if st then for key, v in pairs(S.grid) do if v == NIL then st[key] = nil else st[key] = v end end end
    local cc, wc = H.cc(), H.wc()
    if S.sortWas and cc then cc._sortCol, cc._sortAsc = S.sortWas.cc[1], S.sortWas.cc[2] end
    if S.sortWas and wc then wc._sortCol, wc._sortAsc = S.sortWas.wc[1], S.sortWas.wc[2] end
    if S.worldInvWas and S.worldInvWas ~= S.crate then pcall(ZeD_WorldWindow.selectContainer, S.worldInvWas, 60, S.pn) end
    pcall(function() S.p:setTimedActionInstantCheat(S.instWas and true or false) end)
end)
Q.step(20, function()
    for c, pos in pairs(S.scroll) do pcall(function() c._scroll:setScrollPos(pos) end) end
    for _, inv in ipairs(S.charCols or {}) do pcall(ZeD_CharacterWindow.toggleColumn, inv, S.pn) end
    for _, inv in ipairs(S.worldCols or {}) do pcall(ZeD_WorldWindow.toggleColumn, inv, S.pn) end
    if S.charTabWas and S.charTabWas ~= "loot" then RT.charTab(S.charTabWas) end
    if S.worldTabWas and S.worldTabWas ~= "loot" then RT.worldTab(S.worldTabWas) end
    if S.bagOrig then
        local back = 0
        for _, it in ipairs(S.bagOrig) do if H.where(it) == S.bag then back = back + 1 end end
        Q.check(back == #S.bagOrig, "the bag holds all its own things again", back .. " of " .. #S.bagOrig)
    end
end)
Q.step(10, function()
    if S.pairWas == false then RT.pairShut() end
end)
Q.start()
