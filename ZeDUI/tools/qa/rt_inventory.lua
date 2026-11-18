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

local Q = RT.make("rt_inv")
local S = { p = RT.p, pn = RT.pn, crateGiven = {}, scroll = {}, grid = {}, dead = false }
local H = {}
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
-- the things a list of inv shows: not hidden, and in the character's own inventory not worn or held
function H.expected(inv)
    local set, n = {}, 0
    local isP = inv == S.p:getInventory()
    for _, it in ipairs(H.list(inv)) do
        local hidden = false
        pcall(function() hidden = it:isHidden() end)
        if not hidden and not (isP and H.held(it)) then set[it] = true; n = n + 1 end
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
-- the rows (an open stack's own rows skipped) in the key's order: InventoryRenderer's sortItems and buildItemModel
function H.order(c, key, asc)
    local IR, IM = ZeD.InventoryRenderer, ZeD.ItemMeter
    local prev, pk, pnm = nil, nil, nil
    local n = 0
    for _, it in ipairs(c._flatItems or {}) do
        if not (c._childParent and c._childParent[it]) then
            n = n + 1
            local k, nm = nil, it:getName() or ""
            if key == "name" then k = string.lower(nm)
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
                if e[1] == "Base.Crowbar" then pcall(function() it:setCondition(math.max(1, math.floor(it:getConditionMax() / 2))) end) end
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
                Q.check(set[1] and ok, "Sort by " .. tag .. " from the heading puts the " .. ((k == "cc") and "bag's" or "crate's")
                    .. " rows in that order", tostring(set[2]) .. "; " .. tostring(why))
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

-- ===================================================================== 7. the container buttons
step(4, function()
    local ok, why = H.ccPress(H.wc(), "take")
    Q.check(ok, "the crate's Loot all button presses", why)
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

-- ===================================================================== put back
Q.mark()
Q.step(2, function()
    H.closeMenu()
    H.capUnhook()
    if S.F and S.F.open then pcall(ZeD.InvFilter.toggleOpen, S.F) end
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
