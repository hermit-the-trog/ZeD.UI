-- ZeDUI/tools/qa/vx_crafting.lua  (Nov 21 2026, QA): the in-game proof of Build's fixes for the beast sweep's
-- crafting findings W23 W24 W25 W27 (commit 49039efdf). Needs zedqa_prelude.lua and rt_kit.lua first.
-- grep "ZEDQA vx_crf". Manifest: vx_crafting.lua | vx_crf | timeout=420
--   W27 (the recipe list's re-sort): CC.filterAndSort on a made-up list, the reads of each row's sort key counted
--       (400 and 1200 rows, in name order and in reverse name order) and 2000 plain rows timed; then the real
--       Show All list read for its order (a guard) and timed (said, not scored).
--       The old code: an insertion sort, two key reads for every pair of rows out of order (some 660,000 at 1200).
--   W24 (required rows show the real amount): a slot with alternatives that takes 2 or more items, its
--       alternatives list read (each type's have/need, drawn by Molecules.drawAltRow); then one plank short of a
--       recipe that takes 3 or more planks, the card's plank row read (have / need), then the last plank given.
--       The old code: need 1 on every row and in the list, so "2/1" in green for a recipe that takes 3.
--   W23 (chosen ingredients on an any-surface recipe): a table set beside the character, Drill Plank (plank, log or
--       large branch + a screwdriver, AnySurfaceCraft), the type the game would NOT take by itself chosen in the
--       alternatives list by clicks, Craft pressed, then what was queued and which type was used.
--       The old code: the choice was dropped (no surface given to the check) and the automatic craft ran instead.
--       The bench from 4 tiles away is a SKIP here: no workbench stands at the drag strip.
--   W25 (the floor counts): a branch and a knife on the floor at his feet, his own Make Stake things set aside, Make
--       Stake on the Crafting tab (row, card count, Craft, the moves in and the knife's way back); planks and nails
--       on the floor, the Building tab (row, card count, Build starts the game's cursor; nothing is placed).
--       The old code: only what is carried counted, so both rows said Missing and Craft / Build did nothing.
-- Puts back: god mode and invincible as found, healed, his own things set aside, everything carried that was not
-- carried at the start, new things on the floor nearby, the table, the cursor, the queue, both tabs' Show / Sort /
-- category / search / card, the craft and build counts, the hands, a bound station, game speed 1, the window pair
-- and its tab, the character home.
-- NOT put back: a few points of Carving XP from the crafts.
-- Skeptic review, Nov 21 2026 (read against 49039efdf~1; not yet run in game):
--   * W23: ZeD's list asks the game with no table (CraftingTab.lua:574-576 builds its HandcraftLogic with no
--     surface; the game then refuses every any-surface recipe), so Drill Plank reads Missing beside a table and
--     Craft is dimmed. The first draft waited for the row to read ready, so it never reached Craft: the W23 proof
--     never ran. Now the gap is its own scored line, and Craft is pressed (the press runs on a dimmed button too:
--     CC.onClick does not look at the dim). The queued craft is read the frame of the press.
--   * W24: the alternatives list DOES draw each type's "have/need" (Molecules.drawAltRow); the draft only said the
--     number. Plank slots take one type (no list to open), so a slot with alternatives is found for it.
--   * W25: the character carries things Make Stake takes (bx_craft's first run), so the draft's craft act always
--     SKIPped; his own Make Stake things are now set aside for the act. "The knife back on the floor" passed on the
--     old code too (the knife never moved): it is scored only when the game's own pick takes the floor's knife,
--     with the move in and the way back read from the queue at Craft.
--   * the counts are read from the game's own container list (what ZeD counts since 49039efdf), not from what is
--     carried; outputs dropped at his feet (a full inventory) count as made.
--   * things put on the floor are left to ZeD's own floor refresh (the World window strip refills vanilla's floor
--     container, which the game's list reads), as after a real drop; the draft forced ISInventoryPage.dirtyUI(),
--     which a drop never does and which would hide a fault in that refresh. dirtyUI runs in the put-back only.

if not RT then
    print("ZEDQA vx_crf ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA vx_crf VERDICT FAIL 1")
    print("ZEDQA vx_crf DONE")
    return
end

local Q = RT.make("vx_crf")
Q.maxMs = 300000
local S = { placed = {}, had = {}, floorHad = {}, cnt = {}, reads = 0, stash = {} }
local H = {}
S.p, S.pn = RT.p, RT.pn
S.CC = ZeD and ZeD.CraftingCore
S.CT = ZeD and ZeD.CraftingTab
S.BT = ZeD and ZeD.BuildingTab
S.WW = ZeD_WorldWindow
S.STAKE, S.DRILL = "MakeStake", "DrillPlank"
S.PLANK, S.BIGBRANCH, S.BRANCH, S.KNIFE = "Base.Plank", "Base.LargeBranch", "Base.TreeBranch2", "Base.HuntingKnife"
S.NEAR = { { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }
S.TABLES = { "furniture_tables_high_01_16", "furniture_tables_high_01_0", "furniture_tables_high_01_8", "furniture_tables_high_01_24",
    "furniture_tables_high_01_32", "furniture_tables_high_01_40", "furniture_tables_low_01_0", "furniture_tables_low_01_8" }
S.dead = false

if not (S.p and S.CC and S.CT and S.BT and S.WW) then
    Q.check(false, "the player and ZeD's Crafting and Building tabs are loaded")
    Q.start()
    return
end

-- ===================================================================== helpers
function H.queue()
    local q = nil
    pcall(function() q = ISTimedActionQueue.getTimedActionQueue(S.p) end)
    return (q and q.queue) or {}
end
function H.qlen() return #H.queue() end
function H.head() local a = H.queue()[1]; return a and tostring(a.Type) or "none" end
function H.qcount(ty) local n = 0; for _, a in ipairs(H.queue()) do if a.Type == ty then n = n + 1 end end; return n end
function H.stop() pcall(function() ISTimedActionQueue.clear(S.p) end) end
function H.drag() local d = nil; pcall(function() d = getCell():getDrag(S.pn) end); return d end
function H.noDrag() pcall(function() if getCell():getDrag(S.pn) then getCell():setDrag(nil, S.pn) end end) end
function H.speed(n) if ZEDQA_SPEED then pcall(ZEDQA_SPEED, n) else pcall(setGameSpeed, n) end end
-- time, not frames: cond asked every 100 ms (a UI update), at most ms; fn(true) when cond came true
function H.wait(ms, cond, fn)
    local st = {}
    Q.waitFor(1, 400000, function()
        local now = getTimestampMs()
        st.t = st.t or now
        if st.last and now - st.last < 100 then return false end
        st.last = now
        local ok, r = pcall(cond)
        if ok and r then st.ok = true; return true end
        return now - st.t >= ms
    end, function() fn(st.ok == true) end)
end
-- everything carried, bags in bags too
function H.walk(inv, out, depth)
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        out[#out + 1] = it
        if depth < 4 and instanceof(it, "InventoryContainer") then
            local sub = nil
            pcall(function() sub = it:getInventory() end)
            if sub then H.walk(sub, out, depth + 1) end
        end
    end
end
function H.all() local out = {}; pcall(H.walk, S.p:getInventory(), out, 0); return out end
function H.count(ft)
    local n = 0
    for _, it in ipairs(H.all()) do if it:getFullType() == ft then n = n + 1 end end
    return n
end
function H.takeOne(it)
    pcall(function() if S.p:getPrimaryHandItem() == it then S.p:setPrimaryHandItem(nil) end end)
    pcall(function() if S.p:getSecondaryHandItem() == it then S.p:setSecondaryHandItem(nil) end end)
    pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
end
function H.md(key, name)
    local v = 0
    pcall(function() local md = S.p:getModData(); v = (md[key] and md[key][name]) or 0 end)
    return v
end
-- the tabs
function H.cst() local w = RT.ww(); return w and w._craftState end
function H.bst() local w = RT.ww(); return w and w._buildState end
function H.stOf(mod) if mod == S.BT then return H.bst() end; return H.cst() end
function H.showing(id) local s = false; pcall(function() s = S.WW.isTabShowing(id, S.pn) end); return s and true or false end
function H.tab(id)
    if RT.worldTab(id) then return true end
    local ok = pcall(S.WW.openTab, S.pn, id)
    return ok
end
-- a recipe's row as the tab last drew it (the tab's own cache)
function H.data(mod)
    local w = RT.ww()
    if not w then return nil end
    if mod == S.BT then return w._buildCache end
    return w._craftCache
end
function H.row(mod, name)
    local d = H.data(mod)
    return d and d.byName and d.byName[name] or nil
end
function H.zone(st, kind, pred)
    for _, z in ipairs((st and st.zones) or {}) do
        if z.type == kind and z.w > 0 and z.h > 0 and (pred == nil or pred(z)) then return z end
    end
    return nil
end
function H.click(mod, z, what)
    local ok, err = pcall(mod.onClick, RT.ww(), z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
    if not ok then Q.check(false, what .. ": the click ran without an error", err) end
    return ok
end
-- a recipe's card opened as a click on its row does; from code when the row is out of view (said)
function H.open(mod, name, what)
    local st = H.stOf(mod)
    if not st then return false end
    if st.selected == name then return true end
    local z = H.zone(st, "recipeRow", function(zz) return zz.id == name end)
    local lg = st._listGeo
    if z and lg and not (z.y >= lg.viewY and z.y + z.h <= lg.viewY + lg.viewH) then z = nil end
    if z then
        H.click(mod, z, what)
    else
        local ok, err = pcall(S.CC.openCraft, st, name)
        if not ok then Q.check(false, what .. ": the card opened without an error", err) end
        Q.say("note " .. what .. ": " .. name .. " has no row in view, its card is opened from code")
    end
    return st.selected == name
end
function H.shut(mod)
    local st = H.stOf(mod)
    pcall(function() if st and st.altSlotName then S.CC.exitAltMode(st) end end)
    pcall(function() if st and st.selected then S.CC.closeCraft(st) end end)
end
function H.zedCan(rd) return (rd ~= nil and rd.status == "craftable" and rd.canStart ~= false) and true or false end
-- the two container lists: what is carried (all the old code looked at) and the game's own list for its craft and
-- build windows (carried, the floor, the open loot containers: what ZeD counts since 49039efdf)
function H.carried() return S.CC.buildContainers(S.p) end
function H.gameList()
    local l = nil
    pcall(function() l = ISInventoryPaneContextMenu.getContainers(S.p) end)
    return l
end
function H.listHas(list, it)
    local has = false
    pcall(function()
        for i = 0, list:size() - 1 do
            if list:get(i):contains(it) then has = true end
        end
    end)
    return has
end
-- how many things of the set (full type -> true) a container list holds
function H.listCount(list, set)
    local n = 0
    pcall(function()
        for i = 0, list:size() - 1 do
            local items = list:get(i):getItems()
            for j = 0, items:size() - 1 do
                local it = items:get(j)
                if it and set[it:getFullType()] then n = n + 1 end
            end
        end
    end)
    return n
end
function H.recipe(name)
    local sm = getScriptManager()
    return sm:getCraftRecipe(name) or sm:getCraftRecipe("Base." .. name)
end
-- the game's own answer for a hand recipe from a container list (nil: it would not answer)
function H.handCan(name, list, surf)
    local can = nil
    pcall(function()
        local l = HandcraftLogic.new(S.p, nil, surf)
        l:setContainers(list)
        l:setRecipe(H.recipe(name))
        can = l:canPerformCurrentRecipe() and true or false
    end)
    return can
end
-- the things the game takes when it fills the recipe by itself (item -> true; empty when it would not)
function H.gameUses(name, list, surf)
    local out = {}
    pcall(function()
        local l = HandcraftLogic.new(S.p, nil, surf)
        l:setContainers(list)
        l:setRecipe(H.recipe(name))
        if not l:canPerformCurrentRecipe() then return end
        local items = l:getRecipeData():getAllInputItems()
        for i = 0, items:size() - 1 do out[items:get(i)] = true end
    end)
    return out
end
-- which type of the set the game takes when it fills the recipe by itself (nil: none, or no answer)
function H.autoType(name, list, surf, set)
    local ft = nil
    for it in pairs(H.gameUses(name, list, surf)) do
        local t = nil
        pcall(function() t = it:getFullType() end)
        if t and set[t] then ft = t end
    end
    return ft
end
function H.newBuildLogic()
    local l = nil
    pcall(function() l = BuildLogic.new(S.p, nil, nil) end)
    return l
end
function H.buildCanWith(l, rd, list)
    local can = nil
    pcall(function()
        l:setRecipe(rd.entry.recipe)
        l:setContainers(list)
        can = l:canPerformCurrentRecipe() and true or false
    end)
    return can
end
function H.buildCan(rd, list)
    local l = H.newBuildLogic()
    if not l then return nil end
    return H.buildCanWith(l, rd, list)
end
-- the floor
function H.snapFloor(set)
    local cx, cy, cz = math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())
    for y = cy - 6, cy + 6 do
        for x = cx - 6, cx + 6 do
            local sq = getCell():getGridSquare(x, y, cz)
            local wos = sq and sq:getWorldObjects()
            for i = 0, (wos and wos:size() or 0) - 1 do set[wos:get(i)] = true end
        end
    end
end
-- things of a type lying on the floor nearby
function H.floorCount(ft)
    local now, n = {}, 0
    H.snapFloor(now)
    for wo in pairs(now) do
        local t = nil
        pcall(function() t = wo:getItem():getFullType() end)
        if t == ft then n = n + 1 end
    end
    return n
end
-- made: carried, or dropped at his feet when the inventory is full (the game's Actions.addOrDropItem)
function H.made(ft) return H.count(ft) + H.floorCount(ft) end
-- a thing put on the floor at his feet (the game's own call for a dropped item), then the lists told to look again
function H.drop(ft, ox, oy)
    local it = nil
    pcall(function() it = S.p:getCurrentSquare():AddWorldInventoryItem(ft, ox, oy, 0.0) end)
    return it
end
-- (the floor list the game's craft and build lists read is vanilla's floor container, hidden with its page under
-- ZeD and refilled by ZeD's World window strip, ZeD_WorldWindow.lua buildWorldContainers: every 500 ms, 200 ms after
-- OnContainerUpdate marks it dirty. A real drop does no more than that, so the staging does no more either: a forced
-- ISInventoryPage.dirtyUI() would hide a fault in ZeD's own refresh.)
function H.floorChanged()
    pcall(function() local w = RT.ww(); if w then w._containersDirty = true end end)
end
function H.pagesDirty()
    pcall(function() ISInventoryPage.dirtyUI() end)
    H.floorChanged()
end
function H.onFloor(it)
    local on = false
    pcall(function() on = it:getWorldItem() ~= nil end)
    return on
end
function H.carries(it)
    local has = false
    pcall(function() has = S.p:getInventory():containsRecursive(it) end)
    return has and true or false
end
function H.removeObj(obj)
    local sq = nil
    pcall(function() sq = obj:getSquare() end)
    if not sq then return end
    pcall(function() sq:transmitRemoveItemFromSquare(obj) end)
    pcall(function() if obj:getObjectIndex() >= 0 then sq:RemoveTileObject(obj) end end)
end
function H.freeSq(dx, dy)
    local sq = getCell():getGridSquare(math.floor(S.p:getX()) + dx, math.floor(S.p:getY()) + dy, math.floor(S.p:getZ()))
    local good = false
    pcall(function()
        good = sq ~= nil and sq:getFloor() ~= nil and sq:isFree(false) and not sq:HasTree()
            and sq:getObjects():size() <= 1 and sq:getWorldObjects():size() == 0 and sq:getVehicleContainer() == nil
    end)
    return good and sq or nil
end
-- (reqCollapsed: a folded Required section draws no slot rows, so no slot can be clicked; it is opened for the run)
function H.keepState(st) return { show = st.show, showAll = st.showAll, sort = st.sort, cat = st.activeCat, search = st.search or "", req = st.reqCollapsed } end
function H.putState(st, k)
    if not (st and k) then return end
    pcall(function() if st.altSlotName then S.CC.exitAltMode(st) end end)
    pcall(function() if st.selected then S.CC.closeCraft(st) end end)
    st.show, st.showAll, st.sort, st.activeCat = k.show, k.showAll, k.sort, k.cat
    st.search, st.qty, st.filterDirty, st.reqCollapsed = k.search or "", 1, true, k.req and true or false
    st.sortMenuOpen, st.showMenuOpen, st.catDropdownOpen = false, false, false
end
-- the character's own things that fit a recipe's inputs, set aside for one act (not one worn, held or on the belt).
-- H.unstash gives them back to the containers they were in; the put-back runs it again.
function H.stashFor(rd)
    local want, kept = {}, 0
    for _, inp in ipairs((rd and rd.entry and rd.entry.inputDefs) or {}) do
        for ft in pairs(inp.validTypes or {}) do want[ft] = true end
    end
    for _, it in ipairs(H.all()) do
        if want[it:getFullType()] then
            local c, free = nil, false
            pcall(function()
                c = it:getContainer()
                free = it:getAttachedSlot() == -1 and not it:isEquipped()
                    and S.p:getPrimaryHandItem() ~= it and S.p:getSecondaryHandItem() ~= it
            end)
            if c and free and pcall(function() c:Remove(it) end) then
                S.stash[#S.stash + 1] = { it = it, c = c }
            else
                kept = kept + 1
            end
        end
    end
    return #S.stash, kept
end
function H.unstash()
    local lost = 0
    for _, s in ipairs(S.stash) do
        pcall(function() if s.it:getContainer() == nil then s.c:AddItem(s.it) end end)
        local back = false
        pcall(function() back = s.it:getContainer() ~= nil end)
        if not back then lost = lost + 1 end
    end
    S.stash = {}
    return lost
end
-- the moves queued for one thing: into his main inventory, and back to the floor
function H.moves(item)
    local into, back = false, false
    local inv = S.p:getInventory()
    for _, a in ipairs(H.queue()) do
        if a.Type == "ISInventoryTransferAction" and a.item == item then
            if a.destContainer == inv then into = true end
            local ty = nil
            pcall(function() ty = a.destContainer:getType() end)
            if ty == "floor" then back = true end
        end
    end
    return into, back
end
function H.craftAction()
    for _, a in ipairs(H.queue()) do if a.Type == "ISHandcraftAction" then return a end end
    return nil
end
function H.weightNote()
    local w, cap = nil, nil
    pcall(function() local inv = S.p:getInventory(); w = inv:getCapacityWeight(); cap = inv:getEffectiveCapacity(S.p) end)
    return "carried weight " .. tostring(w) .. " of " .. tostring(cap)
end

-- ===================================================================== setup
Q.step(2, function()
    S.dead = S.p:isDead() and true or false
    if S.dead then Q.check(false, "the character is alive (nothing is run on a dead one)"); return end
    if ZEDQA_HOME then ZEDQA_HOME("vx_crf") end
    -- nothing here should hurt him, but nothing may: god mode and invincible for the whole run
    pcall(function() S.godWas = S.p:isGodMod() and true or false end)
    pcall(function() S.invWas = S.p:isInvincible() and true or false end)
    pcall(function() S.p:setGodMod(true) end)
    pcall(function() S.p:setInvincible(true) end)
    H.speed(1)
    H.stop()
    H.noDrag()
    S.types = {}
    for _, it in ipairs(H.all()) do
        S.had[it] = true
        local ft = it:getFullType()
        S.types[ft] = (S.types[ft] or 0) + 1
    end
    H.snapFloor(S.floorHad)
    S.handWas = { S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem() }
    pcall(function() S.instWas = S.p:isTimedActionInstantCheat(); S.p:setTimedActionInstantCheat(false) end)
    pcall(function() S.bcWas = S.p:isBuildCheat(); S.p:setBuildCheat(false) end)
    local md = S.p:getModData()
    for _, key in ipairs({ "ZeD_CraftCounts", "ZeD_BuildCounts" }) do
        if md[key] then
            local copy = {}
            for k, v in pairs(md[key]) do copy[k] = v end
            S.cnt[key] = copy
        end
    end
    S.pairWas = RT.isOpen()
    RT.pairOpen()
    pcall(function()
        local cur = ZeD.Stations and ZeD.Stations.current(S.p)
        if cur then
            S.stWas = cur
            ZeD.Stations.unbind(S.p)
            Q.say("note a station was bound: unbound for the run (the hand's recipes), bound again at the end")
        end
    end)
    Q.say("setup: god mode " .. tostring(S.p:isGodMod()) .. ", invincible " .. tostring(S.p:isInvincible()) .. ", " .. H.weightNote())
end)

-- ===================================================================== W27: the re-sort, counted and timed
-- A made-up list through the tab's own filter and sort. Each row keeps its sort key behind a counter (the key is
-- written and read through the row's metatable), so the work is counted, not timed: the same on any machine.
S.mt = {
    __index = function(t, k)
        if k == "_sortKey" then S.reads = S.reads + 1; return t._k end
        return nil
    end,
    __newindex = function(t, k, v)
        -- (the sort writes no other new field on a row; _k is a field the row already has, so this is a plain write)
        if k == "_sortKey" then t._k = v end
    end,
}
S.STAT = { "craftable", "missing", "locked", "unlocked" }
-- n rows over twelve sort keys (four statuses, three missing counts), every tenth row a twin of the one before
-- (same name and key: the order of twins must be kept). reverse: the names run backwards.
function H.synth(n, counted, reverse)
    local rows = {}
    for i = 1, n do
        local k = reverse and (n + 1 - i) or i
        local twin = (k - math.floor(k / 10) * 10) == 0
        local no = twin and (k - 1) or k
        local rd = {
            entry = { name = "vx" .. i, displayName = string.format("Vx %05d", no), category = "vx", inputDefs = {}, outputDefs = {}, needLearn = false },
            status = S.STAT[(no - math.floor(no / 4) * 4) + 1], missingCount = no - math.floor(no / 3) * 3,
            learned = true, hasSkill = true, seq = i, _k = 0,
        }
        if counted then setmetatable(rd, S.mt) end
        rows[i] = rd
    end
    return rows
end
function H.keyOf(rd) return rawget(rd, "_sortKey") or rd._k end
function H.sortRun(rows)
    local state = { activeCat = "all", search = "", pins = {}, sort = "craftable", show = "all", showAll = true }
    local out = nil
    local t0 = getTimestampMs()
    local ok, err = pcall(function() out = S.CC.filterAndSort({ recipes = rows }, state, { prefix = "craft", countKey = "ZeD_CraftCounts" }, nil) end)
    return out, getTimestampMs() - t0, (not ok) and tostring(err) or nil
end
-- in order (key, then name), twins in their list order, nothing lost. Returns ok and what was wrong.
function H.inOrder(out, n)
    if not out then return false, "no list came back" end
    if #out ~= n then return false, #out .. " rows of " .. n end
    for i = 2, #out do
        local a, b = out[i - 1], out[i]
        local ka, kb = H.keyOf(a), H.keyOf(b)
        if ka > kb then return false, "row " .. i .. ": key " .. tostring(kb) .. " after " .. tostring(ka) end
        if ka == kb then
            local na, nb = a.entry.displayName, b.entry.displayName
            if na > nb then return false, "row " .. i .. ": " .. nb .. " after " .. na end
            if na == nb and a.seq and b.seq and a.seq > b.seq then return false, "row " .. i .. ": twins of " .. na .. " swapped" end
        end
    end
    return true, #out .. " rows"
end
function H.counted(n, reverse)
    local rows = H.synth(n, true, reverse)
    S.reads = 0
    local out, ms, err = H.sortRun(rows)
    local reads = S.reads
    local ok, seen = H.inOrder(out, n)
    return { reads = reads, ms = ms, ok = ok, seen = err or seen }
end
Q.step(3, function()
    if S.dead then return end
    -- the counter itself first: one read, one count
    local probe = setmetatable({ _k = 7 }, S.mt)
    S.reads = 0
    local v = probe._sortKey
    probe._sortKey = 9
    local works = (v == 7 and S.reads == 1 and probe._k == 9)
    if not works then
        Q.skip("W27 re-sort, counted", "the row counter did not count here (read " .. tostring(v) .. ", " .. tostring(S.reads) .. " reads); the timed check below still runs")
        return
    end
    local a1, a2 = H.counted(400, false), H.counted(1200, false)
    -- (a guard: the order holds on the old code too)
    Q.check(a1.ok and a2.ok, "W27 re-sort, a list in name order: sorted by status then name, twins kept in order, nothing lost", a1.seen .. " / " .. a2.seen)
    -- the fix: one pass into buckets, about one key read a row. The old insertion sort read a key twice for every
    -- pair of rows out of order: some 660,000 reads at 1200 rows.
    Q.check(a2.reads <= 8 * 1200, "W27 re-sort, 1200 rows in name order: no more than 8 key reads a row (the old sort: some 660,000)",
        a2.reads .. " reads at 1200 rows, " .. a1.reads .. " at 400 (" .. a2.ms .. " ms, " .. a1.ms .. " ms)")
    Q.check(a2.reads <= 4 * math.max(1, a1.reads), "W27 re-sort: three times the rows cost about three times the reads, not nine times",
        a1.reads .. " -> " .. a2.reads)
    local b1, b2 = H.counted(400, true), H.counted(1200, true)
    local cap = math.floor(6 * 1200 * math.log(1200) / math.log(2))
    Q.check(b1.ok and b2.ok, "W27 re-sort, a list NOT in name order (a station's own list): sorted by status then name, twins kept in order", b1.seen .. " / " .. b2.seen)
    Q.check(b2.reads <= cap, "W27 re-sort, 1200 rows in reverse name order: within 6 * n * log2(n) key reads (the old sort: some 780,000)",
        b2.reads .. " reads at 1200 rows (cap " .. cap .. "), " .. b1.reads .. " at 400 (" .. b2.ms .. " ms, " .. b1.ms .. " ms)")
end)
Q.step(3, function()
    if S.dead then return end
    -- plain rows, timed: the best of three (a pause for the collector must not count)
    local best, seen, okAll = nil, "", true
    for _ = 1, 3 do
        local rows = H.synth(2000, false, false)
        local out, ms, err = H.sortRun(rows)
        local ok, what = H.inOrder(out, 2000)
        if not ok then okAll = false; seen = err or what end
        if best == nil or ms < best then best = ms end
    end
    Q.check(okAll and best <= 60, "W27 re-sort, 2000 rows filtered and sorted in one go: under 60 ms (the old sort: some 900,000 moves, a few hundred ms)",
        tostring(best) .. " ms, the best of three" .. (okAll and "" or (" / " .. seen)))
end)

-- ===================================================================== the Crafting tab, Show All
Q.step(10, function()
    if S.dead then return end
    local w = RT.ww()
    S.tabWas = w and w._activeTab
    H.tab("craft")
end)
H.wait(8000, function() return S.dead or (H.showing("craft") and H.cst() ~= nil and H.data(S.CT) ~= nil and H.cst().filteredCache ~= nil) end, function(ok)
    if S.dead then return end
    S.craftOk = Q.check(ok, "the World window's Crafting tab opens with its list", tostring(H.showing("craft")))
    local st = H.cst()
    if not (S.craftOk and st) then S.craftOk = false; return end
    S.cKeep = H.keepState(st)
    pcall(S.CC.setShow, st, "all")
    st.sort, st.activeCat, st.search, st.filterDirty, st.reqCollapsed = "craftable", "all", "", true, false
end)
H.wait(4000, function() return not S.craftOk or (H.cst().filterDirty == false and #(H.cst().filteredCache or {}) > 50) end, function(ok)
    if not S.craftOk then return end
    local st, d, w = H.cst(), H.data(S.CT), RT.ww()
    local n = #(st.filteredCache or {})
    local good, seen = H.inOrder(st.filteredCache, n)
    -- (a guard: the real rows keep their order under the new sort; the old sort gave the same order)
    Q.check(ok and good, "W27, the real list (Show: All, sorted by craftable): the rows the player sees are in status then name order", seen)
    -- the real list sorted again five times, as a Craft press or a status flip does: the time is said, not scored
    local best = nil
    for _ = 1, 5 do
        local t0 = getTimestampMs()
        pcall(function() S.CC.filterAndSort(d, st, { prefix = "craft", countKey = "ZeD_CraftCounts" }, w) end)
        local ms = getTimestampMs() - t0
        if best == nil or ms < best then best = ms end
    end
    Q.say("note W27: the real list, " .. n .. " rows of " .. #(d.recipes or {}) .. ", filters and sorts in " .. tostring(best) .. " ms (the best of five)")
    RT.bounds(Q, "the Crafting tab, Show All")
end)

-- ===================================================================== W24: the alternatives list's amount
-- A Craft slot that offers alternatives and takes 2 or more whole items (the game's own amount; a slot counted in
-- uses keeps 1 in ZeD by design). Plank slots take one type: they open no list. The list draws "have/need" for
-- each type (Molecules.drawAltRow), so the need it holds is what the player reads.
function H.findAltSlot(mod)
    local d = H.data(mod)
    for _, rd in ipairs((d and d.recipes) or {}) do
        local e = rd.entry
        for idx, inp in ipairs((e and e.inputDefs) or {}) do
            if (inp.altCount or 0) > 0 and inp.inputRef and not inp.isTool and not inp.isKeep then
                -- (ZeD's own rule, CC.prebakeInputs, in its order: counted in uses first; any error leaves amt 0)
                local amt = 0
                pcall(function()
                    local r = inp.inputRef
                    if r:getResourceType() ~= ResourceType.Item then return end
                    local uses = false
                    if not r:isItemCount() then
                        local pos = r:getPossibleInputItems()
                        for j = 0, pos:size() - 1 do
                            if pos:get(j):isItemType(ItemType.DRAINABLE) then uses = true end
                        end
                    end
                    if not uses then amt = r:getIntAmount() end
                end)
                if amt >= 2 and amt <= 12 then
                    return { name = e.name, idx = idx, amount = amt }
                end
            end
        end
    end
    return nil
end
Q.step(3, function()
    if not S.craftOk then return end
    S.alt = H.findAltSlot(S.CT)
    if not S.alt then
        Q.skip("W24 the alternatives list reads the slot's amount", "no Craft recipe here has a slot with alternatives that takes 2 or more whole items")
        return
    end
    Q.say("W24 alternatives: " .. S.alt.name .. ", slot " .. S.alt.idx .. " takes " .. S.alt.amount .. " (the game's own number)")
    S.alt.open = H.open(S.CT, S.alt.name, "W24 alternatives")
end)
H.wait(8000, function()
    if not (S.alt and S.alt.open) then return true end
    return H.zone(H.cst(), "slotAlt", function(z) return z.idx == S.alt.idx end) ~= nil
end, function(ok)
    if not S.alt then return end
    if not S.alt.open then Q.check(false, "W24 alternatives: the recipe's card opens", S.alt.name); S.alt = nil; return end
    local st = H.cst()
    local z = H.zone(st, "slotAlt", function(zz) return zz.idx == S.alt.idx end)
    if not (ok and z) then Q.check(false, "W24 alternatives: the card draws the slot's row with its alternatives", "slot " .. S.alt.idx); H.shut(S.CT); S.alt = nil; return end
    H.click(S.CT, z, "W24 the slot's row")
    local alts = st.altItems
    local n, bad, seen = 0, 0, ""
    for _, grp in ipairs({ (alts and alts.owned) or {}, (alts and alts.other) or {} }) do
        for _, a in ipairs(grp) do
            n = n + 1
            if a.need ~= S.alt.amount then bad = bad + 1 end
            if n <= 3 then seen = seen .. tostring(a.fullType) .. " " .. tostring(a.have) .. "/" .. tostring(a.need) .. "; " end
        end
    end
    -- the old list: need 1 on every type. (49039efdf reads inputDef.amount in CC.enumerateAlts, but the row's click
    -- hands it the card's ingredient row, which has need and no amount: CraftingCore.lua:3001, :3526)
    Q.check(alts ~= nil and n > 0 and bad == 0, "W24: the alternatives list opened from the slot's row reads each type against the slot's real amount (the old list: N/1)",
        n .. " types, " .. bad .. " with another need; " .. seen .. "the slot takes " .. S.alt.amount)
    H.shut(S.CT)
end)

-- ===================================================================== W24: the card's rows show the real amount
-- a recipe that takes 3 or more planks in one slot: the amount asked of the game's own input (not of ZeD's row)
function H.findAmount(mod)
    local d = H.data(mod)
    local fallback = nil
    for _, rd in ipairs((d and d.recipes) or {}) do
        local e = rd.entry
        for idx, inp in ipairs((e and e.inputDefs) or {}) do
            if inp.validTypes and inp.validTypes[S.PLANK] and inp.inputRef and not inp.isTool and not inp.isKeep then
                local amt = 0
                pcall(function()
                    if inp.inputRef:getResourceType() == ResourceType.Item then amt = inp.inputRef:getIntAmount() end
                end)
                if amt >= 3 and amt <= 12 then
                    local c = { mod = mod, name = e.name, idx = idx, amount = amt, set = inp.validTypes }
                    if rd.status ~= "locked" then return c end
                    fallback = fallback or c
                end
            end
        end
    end
    return fallback
end
Q.step(3, function()
    if not S.craftOk then return end
    S.a = H.findAmount(S.CT)
    if not S.a then H.tab("build") end
end)
H.wait(8000, function() return not S.craftOk or S.a ~= nil or (H.showing("build") and H.bst() ~= nil and H.data(S.BT) ~= nil) end, function()
    if not S.craftOk then return end
    if not S.a then
        local st = H.bst()
        if st then
            if not S.bKeep then S.bKeep = H.keepState(st) end
            pcall(S.CC.setShow, st, "all")
            st.search, st.filterDirty = "", true
        end
        S.a = H.findAmount(S.BT)
    end
    if not S.a then Q.skip("W24 the card's rows show the real amount", "no Craft or Build recipe here takes 3 or more planks in one slot"); return end
    -- what ZeD's row counts: the game's own list (carried, the floor, the open containers)
    local own = H.listCount(H.gameList() or H.carried(), S.a.set)
    if own >= S.a.amount then
        Q.skip("W24 the card's rows show the real amount", own .. " of what the slot takes are in reach already (" .. S.a.amount .. " needed)")
        S.a = nil
        return
    end
    for _ = 1, (S.a.amount - 1) - own do RT.give(S.PLANK) end
    S.a.have = H.listCount(H.gameList() or H.carried(), S.a.set)
    S.a.tabName = (S.a.mod == S.BT) and "Building" or "Crafting"
    Q.say("W24: " .. S.a.tabName .. " tab, " .. S.a.name .. ", slot " .. S.a.idx .. " takes " .. S.a.amount .. " (the game's own number); in reach " .. S.a.have)
    S.a.open = H.open(S.a.mod, S.a.name, "W24")
end)
function H.aRow()
    local rd = S.a and H.row(S.a.mod, S.a.name)
    return rd, rd and rd.ingredients and rd.ingredients[S.a.idx] or nil
end
H.wait(8000, function()
    if not (S.a and S.a.open) then return true end
    local _, ing = H.aRow()
    return ing ~= nil and ing.have >= S.a.have
end, function(ok)
    if not S.a then return end
    if not S.a.open then Q.check(false, "W24: the recipe's card opens", S.a.name); S.a = nil; return end
    local rd, ing = H.aRow()
    if not (ok and ing) then Q.check(false, "W24: the card lists the plank row with what is in reach", "have " .. tostring(ing and ing.have) .. ", in reach " .. S.a.have); S.a = nil; return end
    -- the old code: need 1 on every row, so this row read "<have>/1" with the green square
    Q.check(ing.need == S.a.amount, "W24: one plank short, the card's plank row asks for the recipe's real amount (the old card: need 1)",
        "the row reads " .. tostring(ing.have) .. "/" .. tostring(ing.need) .. ", the game's amount " .. S.a.amount)
    Q.check(ing.have < ing.need and (rd.missingCount or 0) >= 1, "W24: one plank short, the row is drawn as missing and the card counts it (the old card: met, in green)",
        tostring(ing.have) .. "/" .. tostring(ing.need) .. ", rows missing " .. tostring(rd.missingCount))
    -- (a guard: the status is the game's own answer on both the old code and the new)
    Q.check(not H.zedCan(rd), "W24: one plank short, the recipe is not offered as ready", tostring(rd.status))
    RT.give(S.PLANK)
    S.a.full = true
    H.floorChanged()
end)
H.wait(8000, function()
    if not (S.a and S.a.full) then return true end
    local _, ing = H.aRow()
    return ing ~= nil and ing.have >= S.a.amount
end, function(ok)
    if not (S.a and S.a.full) then return end
    local _, ing = H.aRow()
    Q.check(ok and ing ~= nil and ing.need == S.a.amount and ing.have >= ing.need, "W24: the last plank given, the row reads as met",
        tostring(ing and ing.have) .. "/" .. tostring(ing and ing.need))
    RT.bounds(Q, "the card, W24")
    H.shut(S.a.mod)
end)
Q.step(2, function() pcall(RT.takeBack) end)   -- (the planks given go: the next acts count planks)

-- ===================================================================== W23: a chosen ingredient, an any-surface recipe
Q.step(3, function()
    if not S.craftOk then return end
    if not H.showing("craft") then H.tab("craft") end
end)
H.wait(6000, function() return not S.craftOk or (H.showing("craft") and H.data(S.CT) ~= nil) end, function()
    if not S.craftOk then return end
    S.d = { set = {} }
    S.d.set[S.PLANK], S.d.set[S.BIGBRANCH] = true, true
    local rd = H.row(S.CT, S.DRILL)
    if not rd then Q.skip("W23 a chosen ingredient on an any-surface recipe", "the Crafting tab does not list " .. S.DRILL); S.d = nil; return end
    if not rd.entry.needSurface then Q.skip("W23 a chosen ingredient on an any-surface recipe", S.DRILL .. " is no any-surface recipe in this build"); S.d = nil; return end
    -- a table beside him: the first table sprite the game itself takes as a crafting surface
    for _, d in ipairs(S.NEAR) do
        local sq = (not S.d.table) and H.freeSq(d[1], d[2]) or nil
        if sq then
            for _, name in ipairs(S.TABLES) do
                if not S.d.table then
                    local o = nil
                    pcall(function() o = IsoObject.new(getCell(), sq, name); sq:AddTileObject(o) end)
                    local takes = false
                    if o then pcall(function() takes = S.p:canUseAsGenericCraftingSurface(o) and true or false end) end
                    if o and takes then
                        S.d.table, S.d.sprite, S.tableObj = o, name, o
                        S.placed[#S.placed + 1] = o
                    elseif o then
                        H.removeObj(o)
                    end
                end
            end
        end
    end
    local surf = nil
    pcall(function() surf = ISEntityUI.FindCraftSurface(S.p, 2) end)
    if not (S.d.table and surf) then
        Q.skip("W23 a chosen ingredient on an any-surface recipe", "no table the game takes as a crafting surface could be set beside the character (table " .. tostring(S.d.sprite) .. ", found " .. tostring(surf ~= nil) .. ")")
        S.d = nil
        return
    end
    S.d.surf = surf
    RT.give("Base.Screwdriver")
    RT.give(S.PLANK)
    RT.give(S.BIGBRANCH)
    H.floorChanged()
    S.d.open = H.open(S.CT, S.DRILL, "W23")
    Q.say("W23: table " .. S.d.sprite .. " beside the character; a screwdriver, a plank and a large branch given")
end)
function H.plankSlot(st)
    return H.zone(st, "slotAlt", function(z) return z.inputDef and z.inputDef.validTypes and z.inputDef.validTypes[S.PLANK] end)
end
-- the card drawn with its rows once the game's scan has answered (not "unlocked"). Not "until ready": ZeD's list
-- asks the game with no table, so the row may never read ready (scored on its own below)
H.wait(8000, function()
    if not (S.d and S.d.open) then return true end
    local rd, st = H.row(S.CT, S.DRILL), H.cst()
    return rd ~= nil and rd.ingredients ~= nil and rd.status ~= "unlocked" and st.selected == S.DRILL
        and H.plankSlot(st) ~= nil and H.zone(st, "action_build") ~= nil
end, function(ok)
    if not S.d then return end
    if not S.d.open then Q.check(false, "W23: the recipe's card opens", S.DRILL); S.d = nil; return end
    local rd, st = H.row(S.CT, S.DRILL), H.cst()
    if not Q.check(ok, "W23: by the table, Drill Plank's card shows its plank row (with alternatives) and the Craft button", tostring(rd and rd.status)) then S.d = nil; return end
    local list = H.gameList() or H.carried()
    local g = H.handCan(S.DRILL, list, S.d.surf)
    if g ~= true then Q.skip("W23 a chosen ingredient on an any-surface recipe", "the game itself would not start " .. S.DRILL .. " at this table (" .. tostring(g) .. ")"); S.d = nil; return end
    -- a gap Build's W23 fix leaves (not the chosen-ingredients path): the list's own check, the one that lights Craft
    Q.check(H.zedCan(rd), "W23: beside the table, with everything carried, the row says ready and Craft is lit, as the game would start it (the list asks with no table: CraftingTab.lua:574)",
        "ZeD " .. tostring(rd.status) .. " / canStart " .. tostring(rd.canStart) .. ", the game with the table " .. tostring(g))
    if not H.zedCan(rd) then Q.say("note W23: Craft is pressed though it is dimmed (the press still runs: CC.onClick does not look at the dim)") end
    -- the type the game takes when left alone, and the other one: that one is chosen
    S.d.auto = H.autoType(S.DRILL, list, S.d.surf, S.d.set)
    S.d.pick = (S.d.auto == S.BIGBRANCH) and S.PLANK or S.BIGBRANCH
    S.d.other = (S.d.pick == S.PLANK) and S.BIGBRANCH or S.PLANK
    if not S.d.auto then Q.say("note W23: the game's own pick could not be read; " .. S.d.pick .. " is chosen, so the type check below may not tell old from new") end
    local z = H.plankSlot(st)
    S.d.idx = z.idx
    H.click(S.CT, z, "W23 the plank row")
    S.d.alt = Q.check(st.altSlotName ~= nil and st.altItems ~= nil, "W23: a click on the plank row opens its alternatives", tostring(st.altSlotName))
    Q.say("W23: left alone the game takes " .. tostring(S.d.auto) .. "; choosing " .. S.d.pick)
end)
H.wait(4000, function()
    return not (S.d and S.d.alt) or H.zone(H.cst(), "altPick", function(z) return z.id == S.d.pick end) ~= nil
end, function(ok)
    if not (S.d and S.d.alt) then return end
    local st = H.cst()
    local z = H.zone(st, "altPick", function(zz) return zz.id == S.d.pick end)
    if not (ok and z) then Q.check(false, "W23: the alternatives list offers " .. S.d.pick .. " to choose", "no row for it"); S.d.alt = false; return end
    H.click(S.CT, z, "W23 the alternative")
    local chosen = nil
    pcall(function() chosen = S.CC.pickFor(st, S.DRILL, S.d.idx) end)
    S.d.chosen = Q.check(chosen == S.d.pick, "W23: a click on the alternative chooses it for the slot", tostring(chosen))
end)
H.wait(3000, function() return not (S.d and S.d.chosen) or H.zone(H.cst(), "action_build") ~= nil end, function(ok)
    if not (S.d and S.d.chosen) then return end
    local z = H.zone(H.cst(), "action_build")
    if not (ok and z) then Q.check(false, "W23: the card's Craft button is drawn"); return end
    S.d.pickWas, S.d.otherWas, S.d.outWas = H.count(S.d.pick), H.count(S.d.other), H.made("Base.PercedWood")
    H.click(S.CT, z, "W23 Craft")
    S.d.queued = H.qcount("ISHandcraftAction")
    -- (a guard: the old code queued one craft too, the automatic one)
    S.d.run = Q.check(S.d.queued == 1, "W23: Craft queues one craft", "queued " .. S.d.queued .. ", queue " .. H.head())
    -- the old code: the choice was dropped and the automatic craft (no manual inputs) went in its place
    local a = H.craftAction()
    local manual = a ~= nil and a.manualInputs ~= nil
    local atTable = a ~= nil and a.isoObject == S.d.surf
    Q.check(manual and atTable, "W23: the queued craft is built from the chosen ingredients, at the table (the old code: the automatic craft, no manual inputs)",
        "manual inputs " .. tostring(manual) .. ", at the table " .. tostring(atTable))
end)
H.wait(40000, function() return not (S.d and S.d.run) or (H.qlen() == 0 and H.made("Base.PercedWood") > S.d.outWas) end, function(ok)
    if not (S.d and S.d.run) then return end
    local usedPick, usedOther = S.d.pickWas - H.count(S.d.pick), S.d.otherWas - H.count(S.d.other)
    local made = H.made("Base.PercedWood") - S.d.outWas
    Q.check(ok and made == 1, "W23: the craft runs to its end at the table", "made " .. made .. ", queue " .. H.head())
    -- the old code: the choice was dropped without a word and the game's own pick was used
    Q.check(usedPick == 1 and usedOther == 0, "W23: the craft used the chosen type and left the other (the old code used the game's own pick)",
        "chosen " .. S.d.pick .. ": " .. usedPick .. " used; " .. S.d.other .. ": " .. usedOther .. " used; the game's own pick was " .. tostring(S.d.auto))
    if H.qlen() > 0 then H.stop() end
    RT.bounds(Q, "the card, W23")
end)
Q.step(2, function()
    if S.craftOk then H.shut(S.CT) end
    for _, o in ipairs(S.placed) do pcall(H.removeObj, o) end
    S.placed = {}
    pcall(RT.takeBack)
    Q.skip("W23 a chosen ingredient at a bench from 4 tiles away", "no workbench stands at the drag strip and none is set up by this script; the far-bench branch of the fix is not proven here")
end)

-- ===================================================================== W25: the floor counts (Crafting tab)
Q.step(4, function()
    if not S.craftOk then return end
    if not H.showing("craft") then H.tab("craft") end
    S.f = {}
    local rd = H.row(S.CT, S.STAKE)
    if not rd then Q.skip("W25 a craft from the floor", "the Crafting tab does not list " .. S.STAKE); S.f = nil; return end
    -- his own things Make Stake takes, set aside for the act: carried, they make it without the floor (bx_craft's
    -- first run), and the old code would have said ready too
    S.f.aside, S.f.kept = H.stashFor(rd)
    S.f.branch = H.drop(S.BRANCH, 0.35, 0.35)
    S.f.knife = H.drop(S.KNIFE, 0.65, 0.65)
    if not (S.f.branch and S.f.knife) then Q.skip("W25 a craft from the floor", "the branch and the knife could not be put on the floor"); S.f = nil; return end
    H.floorChanged()
    -- with what is carried alone (all the old code looked at) the game would not start it
    S.f.carriedCan = H.handCan(S.STAKE, H.carried(), nil)
    Q.say("W25: " .. S.f.aside .. " of his own things Make Stake takes set aside (" .. S.f.kept .. " worn, held or on the belt stay); " .. H.weightNote())
    if S.f.carriedCan ~= false then
        Q.skip("W25 a craft from the floor", "the game would start Make Stake from what he carries (" .. tostring(S.f.carriedCan) .. "): worn or held things fit it")
        S.f = nil
        return
    end
    S.f.open = H.open(S.CT, S.STAKE, "W25 craft")
    S.f.stakes, S.f.cnt = H.made("Base.Stake"), H.md("ZeD_CraftCounts", S.STAKE)
end)
H.wait(9000, function()
    if not (S.f and S.f.open) then return true end
    return H.zedCan(H.row(S.CT, S.STAKE)) and H.zone(H.cst(), "action_build") ~= nil
end, function(ok)
    if not S.f then return end
    if not S.f.open then Q.check(false, "W25: the recipe's card opens", S.STAKE); S.f = nil; return end
    local rd, st = H.row(S.CT, S.STAKE), H.cst()
    local list = H.gameList()
    local sees = list ~= nil and H.listHas(list, S.f.branch) and H.listHas(list, S.f.knife)
    -- (a guard on the game, not on ZeD: ZeD's list is this one since 49039efdf)
    Q.check(sees, "W25: the game's own container list (the one its craft window uses) holds the branch and the knife on the floor",
        "branch " .. tostring(list ~= nil and H.listHas(list, S.f.branch)) .. ", knife " .. tostring(list ~= nil and H.listHas(list, S.f.knife)))
    local g = list and H.handCan(S.STAKE, list, nil)
    -- the old code: only what is carried counted, so the row said Missing
    Q.check(ok and H.zedCan(rd), "W25: a branch and a knife on the floor at his feet, Make Stake's row says ready (the old code: Missing)",
        "ZeD " .. tostring(rd and rd.status) .. " / canStart " .. tostring(rd and rd.canStart) .. ", the game from its own list " .. tostring(g) .. ", from what is carried " .. tostring(S.f.carriedCan))
    local have = nil
    for _, ing in ipairs((rd and rd.ingredients) or {}) do
        if ing.validTypes and ing.validTypes[S.BRANCH] then have = ing.have end
    end
    Q.check(have ~= nil and have >= 1, "W25: the card's branch row counts the one on the floor (the old card: 0)", "have " .. tostring(have))
    local z = H.zone(st, "action_build")
    if not z then Q.check(false, "W25: the card's Craft button is drawn"); S.f.open = false; return end
    -- which of the floor's two the game's own pick takes (a knife he wears or holds may come before the floor's)
    local uses = list and H.gameUses(S.STAKE, list, nil) or {}
    S.f.useKnife, S.f.useBranch = uses[S.f.knife] == true, uses[S.f.branch] == true
    pcall(function() S.f.fromFloor = H.recipe(S.STAKE):isCanBeDoneFromFloor() and true or false end)
    H.click(S.CT, z, "W25 Craft")
    S.f.crafts = H.qcount("ISHandcraftAction")
    S.f.run = Q.check(S.f.crafts == 1, "W25: Craft queues the craft from the floor (the old code: nothing)",
        "crafts " .. S.f.crafts .. ", moves queued with it " .. H.qcount("ISInventoryTransferAction") .. ", queue head " .. H.head())
    local kIn, kBack = H.moves(S.f.knife)
    local bIn = H.moves(S.f.branch)
    if not S.f.run then return end
    if S.f.fromFloor then
        Q.skip("W25: the floor's things move in first and the knife is queued back", "Make Stake can be made from the floor in this build: nothing is moved")
    elseif not (S.f.useKnife or S.f.useBranch) then
        Q.skip("W25: the floor's things move in first and the knife is queued back", "the game's own pick takes neither the floor's branch nor its knife")
    else
        -- as the game's craft window does (ISWidgetHandCraftControl:startHandcraft): in before, the kept tool back after
        Q.check((not S.f.useBranch or bIn) and (not S.f.useKnife or (kIn and kBack)),
            "W25: Craft moves the floor's things into his inventory first and queues the knife's way back, as the game's craft window does",
            "branch in " .. tostring(bIn) .. " (taken " .. tostring(S.f.useBranch) .. "); knife in " .. tostring(kIn) .. ", back " .. tostring(kBack) .. " (taken " .. tostring(S.f.useKnife) .. ")")
    end
end)
H.wait(50000, function() return not (S.f and S.f.run) or (H.qlen() == 0 and H.made("Base.Stake") > S.f.stakes) end, function(ok)
    if not (S.f and S.f.run) then return end
    local made = H.made("Base.Stake") - S.f.stakes
    local branchLeft = H.onFloor(S.f.branch) or H.carries(S.f.branch)
    if S.f.useBranch then
        Q.check(ok and made == 1 and not branchLeft, "W25: the craft runs to its end, one stake made, the floor's branch used",
            "made " .. made .. ", the branch still there " .. tostring(branchLeft) .. ", queue " .. H.head())
    else
        Q.check(ok and made == 1, "W25: the craft runs to its end, one stake made", "made " .. made .. " (the game's pick took a branch of his he wears or holds), queue " .. H.head())
    end
    Q.check(H.md("ZeD_CraftCounts", S.STAKE) - S.f.cnt == 1, "W25: the craft is counted once", H.md("ZeD_CraftCounts", S.STAKE) - S.f.cnt)
    -- the kept tool goes back where it was, as the game's craft window puts it back (a Disorganized character does not)
    local messy = false
    pcall(function() messy = S.p:hasTrait(CharacterTrait.DISORGANIZED) and true or false end)
    if messy then
        Q.skip("W25: the knife goes back to the floor", "the character is Disorganized: the game does not put things back for him")
    elseif S.f.fromFloor or not S.f.useKnife then
        Q.skip("W25: the knife goes back to the floor", S.f.fromFloor and "made from the floor: the knife never moved" or "the game's pick took a knife he wears or holds, not the floor's")
    else
        local carriedNow = H.carries(S.f.knife)
        Q.check(H.onFloor(S.f.knife) and not carriedNow, "W25: after the craft the floor's knife is back on the floor, not left in his inventory",
            "on the floor " .. tostring(H.onFloor(S.f.knife)) .. ", carried " .. tostring(carriedNow))
    end
    if H.qlen() > 0 then H.stop() end
    RT.bounds(Q, "the card, W25")
    H.shut(S.CT)
end)
Q.step(2, function()
    if #S.stash == 0 then return end
    local n = #S.stash
    local lost = H.unstash()
    Q.check(lost == 0, "W25: his own things set aside for the craft are back where they were", n .. " set aside, " .. lost .. " not back")
end)

-- ===================================================================== W25: the floor counts (Building tab)
Q.step(4, function()
    if S.dead then return end
    S.g = { planks = {}, nails = {} }
    -- (the planks and tools given for the checks above go first: the build's wood is on the floor only)
    pcall(H.stop)
    pcall(RT.takeBack)
    RT.give("Base.Hammer")
    RT.give("Base.Saw")
    for i = 1, 8 do
        local a = H.drop(S.PLANK, 0.2 + 0.07 * i, 0.3)
        local b = H.drop("Base.Nails", 0.2 + 0.07 * i, 0.7)
        if a then S.g.planks[#S.g.planks + 1] = a end
        if b then S.g.nails[#S.g.nails + 1] = b end
    end
    H.floorChanged()
    H.tab("build")
end)
H.wait(8000, function() return S.dead or (H.showing("build") and H.bst() ~= nil and H.data(S.BT) ~= nil and H.bst().filteredCache ~= nil) end, function(ok)
    if S.dead then return end
    S.buildOk = Q.check(ok, "the World window's Building tab opens with its list", tostring(H.showing("build")))
    if not S.buildOk then return end
    local st = H.bst()
    if not S.bKeep then S.bKeep = H.keepState(st) end
    pcall(S.CC.setShow, st, "all")
    st.search, st.filterDirty = "", true
    S.g.t0 = getTimestampMs()
end)
-- a recipe the game would build with the floor's planks and nails and would not from what is carried alone (asked
-- of the game's own build logic, not of ZeD's rows; one logic for each list)
function H.findBuild(list)
    local d = H.data(S.BT)
    local lf, lc = H.newBuildLogic(), H.newBuildLogic()
    if not (lf and lc) then return nil, 0 end
    local carried = H.carried()
    local tried = 0
    for _, rd in ipairs((d and d.recipes) or {}) do
        local wood = false
        for _, inp in ipairs((rd.entry and rd.entry.inputDefs) or {}) do
            if inp.validTypes and (inp.validTypes[S.PLANK] or inp.validTypes["Base.Nails"]) then wood = true end
        end
        if wood and tried < 120 then
            tried = tried + 1
            if H.buildCanWith(lf, rd, list) == true and H.buildCanWith(lc, rd, carried) == false then return rd.entry.name, tried end
        end
    end
    return nil, tried
end
H.wait(6000, function()
    if not S.buildOk then return true end
    local list = H.gameList()
    return (list ~= nil and #S.g.planks > 0 and H.listHas(list, S.g.planks[1])) or getTimestampMs() - S.g.t0 > 5000
end, function()
    if not S.buildOk then return end
    local list = H.gameList()
    local sees = list ~= nil and #S.g.planks > 0 and H.listHas(list, S.g.planks[1]) and #S.g.nails > 0 and H.listHas(list, S.g.nails[1])
    S.g.sees = Q.check(sees, "W25: the game's own container list holds the planks and nails on the floor", #S.g.planks .. " planks and " .. #S.g.nails .. " nails put down")
    if not sees then return end
    local tried = 0
    S.g.name, tried = H.findBuild(list)
    if not S.g.name then
        Q.skip("W25 a build from the floor", "of " .. tried .. " plank or nail recipes the game would build none from 8 planks, 8 nails, a hammer and a saw (Carpentry " .. tostring(S.p:getPerkLevel(Perks.Woodwork)) .. ")")
        return
    end
    Q.say("W25: the game would build " .. S.g.name .. " from the floor and not from what is carried")
    S.g.open = H.open(S.BT, S.g.name, "W25 build")
end)
H.wait(9000, function()
    if not (S.g and S.g.open) then return true end
    local rd = H.row(S.BT, S.g.name)
    return rd ~= nil and rd.status == "craftable" and rd.ingredients ~= nil and H.zone(H.bst(), "action_build") ~= nil
end, function(ok)
    if not (S.g and S.g.name) then return end
    if not S.g.open then Q.check(false, "W25: the build recipe's card opens", S.g.name); return end
    local rd, st = H.row(S.BT, S.g.name), H.bst()
    -- the old code: only what is carried counted, so the row said Missing and Build did nothing
    Q.check(ok and rd ~= nil and rd.status == "craftable", "W25: planks and nails on the floor at his feet, the build's row says ready (the old code: Missing)",
        "ZeD " .. tostring(rd and rd.status) .. ", the game from its own list " .. tostring(rd and H.buildCan(rd, H.gameList())) .. ", from what is carried " .. tostring(rd and H.buildCan(rd, H.carried())))
    local have, carriedOf = nil, 0
    for _, ing in ipairs((rd and rd.ingredients) or {}) do
        if have == nil and ing.validTypes and ing.validTypes[S.PLANK] and not ing.isTool then
            have, carriedOf = ing.have, H.listCount(H.carried(), ing.validTypes)
        end
    end
    if have ~= nil then
        Q.check(have >= carriedOf + #S.g.planks, "W25: the card's plank row counts the planks on the floor (the old card: only the carried ones)",
            "have " .. tostring(have) .. ", carried " .. carriedOf .. ", on the floor " .. #S.g.planks)
    else
        Q.say("note W25: " .. S.g.name .. " has no plank row of its own (nails only); the count is not read")
    end
    local z = H.zone(st, "action_build")
    if not z then Q.check(false, "W25: the card's Build button is drawn"); return end
    H.noDrag()
    local cnt = H.md("ZeD_BuildCounts", S.g.name)
    local okc, err = pcall(S.BT.onClick, RT.ww(), z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
    local d = H.drag()
    Q.check(okc and d ~= nil and d.Type == "ISBuildIsoEntity", "W25: Build starts the game's build cursor from the floor's materials (the old code: nothing)",
        okc and (tostring(d and d.Type) .. ", count +" .. (H.md("ZeD_BuildCounts", S.g.name) - cnt)) or tostring(err))
    -- nothing is placed: the cursor is let go
    H.noDrag()
    RT.bounds(Q, "the card, W25 build")
    H.shut(S.BT)
end)

-- ===================================================================== put back
Q.mark()
function H.putCounts()
    local md = S.p:getModData()
    for _, key in ipairs({ "ZeD_CraftCounts", "ZeD_BuildCounts" }) do
        local was = S.cnt[key]
        if was then
            local t = {}
            for k, v in pairs(was) do t[k] = v end
            md[key] = t
        else
            md[key] = nil
        end
    end
    local w = RT.ww()
    if w then w._craftCache, w._buildCache = nil, nil end
end
-- the character's own things a craft used in place of a given one: one new item of the type for each that is short
-- (run after H.unstash, or his own things set aside would be made twice)
function H.refill()
    local now, made, short = {}, 0, 0
    for _, it in ipairs(H.all()) do
        local ft = it:getFullType()
        now[ft] = (now[ft] or 0) + 1
    end
    for ft, was in pairs(S.types or {}) do
        for _ = 1, was - (now[ft] or 0) do
            local it = nil
            pcall(function() it = S.p:getInventory():AddItem(ft) end)
            if it then S.had[it] = true; made = made + 1 else short = short + 1 end
        end
    end
    return made, short
end
function H.sweep()
    local n = 0
    for _, it in ipairs(H.all()) do
        if not S.had[it] then H.takeOne(it); n = n + 1 end
    end
    local now = {}
    H.snapFloor(now)
    for wo in pairs(now) do
        if not S.floorHad[wo] then
            pcall(function()
                local sq = wo:getSquare()
                if sq then sq:transmitRemoveItemFromSquare(wo) end
            end)
            pcall(function() wo:removeFromWorld() end)
            pcall(function() wo:removeFromSquare() end)
            n = n + 1
        end
    end
    return n
end
-- (every line of the put-back stands alone: one that throws does not stop the next)
Q.step(3, function()
    pcall(H.speed, 1)
    pcall(H.stop)
    pcall(H.noDrag)
    if S.dead then return end
    pcall(function() if #S.stash > 0 then S.stashLost = H.unstash() end end)
    for _, o in ipairs(S.placed) do pcall(H.removeObj, o) end
    S.placed = {}
    pcall(function() if S.cKeep then H.putState(H.cst(), S.cKeep) end end)
    pcall(function() if S.bKeep then H.putState(H.bst(), S.bKeep) end end)
    pcall(H.putCounts)
    pcall(function() S.p:setTimedActionInstantCheat(S.instWas and true or false) end)
    pcall(function() S.p:setBuildCheat(S.bcWas and true or false) end)
    pcall(RT.pairOpen)
end)
Q.step(10, function()
    if S.dead then return end
    pcall(H.tab, (S.tabWas and S.tabWas ~= "craft" and S.tabWas ~= "build") and S.tabWas or "loot")
end)
Q.step(20, function()
    if S.dead then return end
    pcall(H.stop)
    pcall(function() if #S.stash > 0 then S.stashLost = (S.stashLost or 0) + H.unstash() end end)
    pcall(function() S.swept = H.sweep() end)
    pcall(RT.takeBack)
    pcall(function() S.refilled, S.short = H.refill() end)
    pcall(function()
        local a, b = S.handWas[1], S.handWas[2]
        S.p:setPrimaryHandItem((a and S.p:getInventory():containsRecursive(a)) and a or nil)
        S.p:setSecondaryHandItem((b and S.p:getInventory():containsRecursive(b)) and b or nil)
    end)
    -- healed while god mode is still on (RestoreToFullHealth takes no argument), then the two switches as found
    pcall(function() S.p:getBodyDamage():RestoreToFullHealth() end)
    pcall(H.pagesDirty)
    pcall(function() if ZEDQA_HOME then ZEDQA_HOME("vx_crf") end end)
    pcall(function() if S.stWas then ZeD.Stations.bind(S.p, S.stWas) end end)
    pcall(function() S.p:setInvincible(S.invWas and true or false) end)
    pcall(function() S.p:setGodMod(S.godWas and true or false) end)
    pcall(function() if S.pairWas == false then RT.pairShut() end end)
end)
Q.step(10, function()
    if S.dead then return end
    local left = 0
    for _, it in ipairs(H.all()) do if not S.had[it] then left = left + 1 end end
    local now, floor = {}, 0
    H.snapFloor(now)
    for wo in pairs(now) do if not S.floorHad[wo] then floor = floor + 1 end end
    Q.check(left == 0 and floor == 0 and (S.short or 0) == 0, "put back: the character carries what he carried at the start, nothing new on the floor",
        tostring(S.swept) .. " taken away, " .. tostring(S.refilled) .. " of his own used things given again (" .. tostring(S.short)
        .. " could not be), " .. left .. " carried and " .. floor .. " on the floor left; set aside and not back " .. tostring(S.stashLost or 0))
    -- (the table this script set down, by the object: not any table of the same sprite that stood there before)
    local stood = 0
    pcall(function() if S.tableObj and S.tableObj:getSquare() ~= nil and S.tableObj:getObjectIndex() >= 0 then stood = 1 end end)
    Q.check(stood == 0 and H.drag() == nil and H.qlen() == 0, "put back: no table, no cursor, no action left",
        stood .. " / " .. tostring(H.drag() and H.drag().Type) .. " / " .. H.head())
    local hurt, alive = false, not S.p:isDead()
    pcall(function() hurt = S.p:getBodyDamage():getOverallBodyHealth() < 99 end)
    Q.check(alive and not hurt and S.p:isGodMod() == (S.godWas and true or false) and S.p:isInvincible() == (S.invWas and true or false),
        "put back: the character is alive and whole, god mode and invincible as found",
        "alive " .. tostring(alive) .. ", hurt " .. tostring(hurt) .. ", god " .. tostring(S.p:isGodMod()) .. ", invincible " .. tostring(S.p:isInvincible()))
    local st = H.cst()
    Q.check(getGameSpeed() == 1 and (st == nil or st.selected == nil), "put back: game speed 1, the Crafting tab's card shut",
        tostring(getGameSpeed()) .. " / " .. tostring(st and st.selected))
    RT.bounds(Q, "the end")
end)
Q.start()
