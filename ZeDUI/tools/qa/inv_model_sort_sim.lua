-- ZeDUI/tools/qa/inv_model_sort_sim.lua  (Nov 7 2026, Build): the inventory list model's speed work (the performance
-- review's #4, ZeDUI/qa/REVIEW_PERF_20261107.md), with no game running.
--   ORDER    InventoryRenderer.lua's buildItemModel against the model as it was on Nov 7 2026 (its makeSorter,
--            heldByPlayer and buildItemModel, frozen below as OLD_SRC): a 300-thing container made for ties (the same
--            names in two cases, nameless things, the same weights, conditions, categories), stacks, hidden things,
--            worn and held things, a thing whose container says another. Every sort (name, category, condition,
--            weight) both ways; a mod's groups (as Better Folders) or none; no folds, or folds and open stacks; the
--            player's own list, a bag in it, another character's container, the loot side. The same categories, rows,
--            stacks, folds and order, ties included, and the same number of comparisons (table.sort makes the same
--            moves), with nothing asked of a thing inside a comparison.
--   REBUILD  itemModel: kept between frames; about once a second, each column on its own beat (three columns opened
--            together never rebuild on the same frame); at once when the count, weight, sort, folds or hands change;
--            within 500 ms of the game's OnContainerUpdate or a drop (a storm of events: about twice a second); a
--            player's clothes rebuild, a zombie's do not; the clock set back rebuilds once. The clock is past 2^31.
-- It prints the numbers (comparisons and asks, old -> new), FAIL lines and a last line
-- "inv_model_sort_sim: N checks, M failed", and exits 1 if any failed.
-- What it can't show: Kahlua's own table.sort (a different routine from Lua 5.1's; the same answer to every comparison
-- gives the same order under any one routine, and the game's is the same before and after) and how long a build takes
-- in the game (suite_perf.lua).
-- Run from the repo root:  lua51 ZeDUI/tools/qa/inv_model_sort_sim.lua   (or LuaJIT)

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]inv_model_sort_sim%.lua$", "")

-- The model as it was on Nov 7 2026 (InventoryRenderer.lua at 7f17686e), the reference: do not edit
local OLD_SRC = [==[
local function getCondPct(item)
    local mx = item:getConditionMax()
    if not mx or mx <= 0 then return -1 end
    return item:getCondition() / mx
end

local function makeSorter(col, asc)
    if col == "name" then
        if asc then
            return function(a, b) return string.lower(a:getName() or "") < string.lower(b:getName() or "") end
        else
            return function(a, b) return string.lower(a:getName() or "") > string.lower(b:getName() or "") end
        end
    elseif col == "cat" then
        if asc then
            return function(a, b)
                local ca, cb = ZeD.InventoryRenderer.catKey(a), ZeD.InventoryRenderer.catKey(b)
                if ca ~= cb then return ca < cb end
                return (a:getName() or "") < (b:getName() or "")
            end
        else
            return function(a, b)
                local ca, cb = ZeD.InventoryRenderer.catKey(a), ZeD.InventoryRenderer.catKey(b)
                if ca ~= cb then return ca > cb end
                return (a:getName() or "") < (b:getName() or "")
            end
        end
    elseif col == "cond" then
        if asc then
            return function(a, b)
                local ca, cb = getCondPct(a), getCondPct(b)
                if ca ~= cb then return ca < cb end
                return (a:getName() or "") < (b:getName() or "")
            end
        else
            return function(a, b)
                local ca, cb = getCondPct(a), getCondPct(b)
                if ca ~= cb then return ca > cb end
                return (a:getName() or "") < (b:getName() or "")
            end
        end
    else -- "wt"
        if asc then
            return function(a, b)
                local wa, wb = a:getUnequippedWeight(), b:getUnequippedWeight()
                if wa ~= wb then return wa < wb end
                return (a:getName() or "") < (b:getName() or "")
            end
        else
            return function(a, b)
                local wa, wb = a:getUnequippedWeight(), b:getUnequippedWeight()
                if wa ~= wb then return wa > wb end
                return (a:getName() or "") < (b:getName() or "")
            end
        end
    end
end

-- equipped or worn by the player (hidden from their own list: the Equip tab shows them)
local function heldByPlayer(playerObj, item)
    local okE, eq = pcall(function() return item:isEquipped() end)
    if okE and eq then return true end
    local okP, peq = pcall(function() return playerObj:isEquipped(item) end)
    return okP and peq or false
end

local function buildItemModel(inv, playerObj, isPlayerInv, sortCol, sortAsc, collapsed, expandedStacks)
    local groups, catOrder, flatItems = {}, {}, {}
    local catOf = {}   -- item -> its category key (the rows draw it every frame)
    local items = inv and inv:getItems()
    -- a mod's gate (ContainerGates.lua): only the things it lets show (a search's finds so far)
    local gate = ZeD.ContainerGates.get(inv, playerObj)
    if items then
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item and not item:isHidden() and not (isPlayerInv and heldByPlayer(playerObj, item))
               and (not gate or ZeD.ContainerGates.keeps(gate, item)) then
                -- a mod's group first (ContainerGroups.lua: a folder the player filed it in), else its category
                local cat = ZeD.ContainerGroups.groupOf(item, inv, playerObj, isPlayerInv) or ZeD.InventoryRenderer.catKey(item)
                catOf[item] = cat
                if not groups[cat] then
                    groups[cat] = {}
                    catOrder[#catOrder + 1] = cat
                end
                groups[cat][#groups[cat] + 1] = item
            end
        end
    end
    -- a mod's groups listed even with nothing in them (ContainerGroups.lua: a folder with
    -- nothing filed yet is a group row of its own, count 0, as an empty container); the
    -- grouped view only (the other sorts are one flat list)
    if sortCol == "cat" then
        for _, key in ipairs(ZeD.ContainerGroups.keys(inv, playerObj, isPlayerInv)) do
            if not groups[key] then
                groups[key] = {}
                catOrder[#catOrder + 1] = key
            end
        end
    end

    local sorter    = makeSorter(sortCol, sortAsc)
    local useGroups = (sortCol == "cat")   -- only Sort by Category has category headers; the rest is one flat list
    local stacks = {}          -- rep item -> stack info
    local childParent = {}     -- child item -> stack info

    -- Build one stack per (cat, fullType); emit representative + optional
    -- children into flatItems in render order. Expanded stacks show their
    -- child rows indented beneath the header. Vanilla PZ UX.
    local function emitStacks(itemList)
        local byType = {}
        local ordered = {}
        for _, item in ipairs(itemList) do
            local ft = item.getFullType and item:getFullType() or tostring(item)
            if not byType[ft] then
                byType[ft] = { rep = item, items = { item }, count = 1, key = ft }
                ordered[#ordered + 1] = byType[ft]
            else
                local s = byType[ft]
                s.items[#s.items + 1] = item
                s.count = s.count + 1
            end
        end
        -- sorted by weight, a stack goes by its total, the number its row shows (as vanilla's inventory sorts)
        if sortCol == "wt" then
            for _, s in ipairs(ordered) do s.wt = stackWeight(s) end
            table.sort(ordered, function(a, b)
                if a.wt ~= b.wt then if sortAsc then return a.wt < b.wt end return a.wt > b.wt end
                return (a.rep:getName() or "") < (b.rep:getName() or "")
            end)
        end
        for _, s in ipairs(ordered) do
            flatItems[#flatItems + 1] = s.rep
            stacks[s.rep] = s
            if s.count > 1 and expandedStacks[s.key] then
                for ci = 2, #s.items do
                    flatItems[#flatItems + 1] = s.items[ci]
                    childParent[s.items[ci]] = s
                end
            end
        end
    end

    -- S100: stacked per-category iteration list for the useGroups draw path.
    -- The draw loop iterates per-cat; without this the original unstacked
    -- groups[cat] would be used, bypassing stacking entirely.
    local stackedGroups = {}
    local catRowCount = {}  -- cat -> rendered row count (stacks + expanded children)
    if useGroups then
        -- (a mod's ranked groups first, ContainerGroups.lua; then the categories, either way)
        ZeD.ContainerGroups.sortKeys(catOrder, not (sortCol == "cat" and not sortAsc))
        for _, cat in ipairs(catOrder) do
            table.sort(groups[cat], sorter)
            if not (collapsed and collapsed[cat]) then
                local before = #flatItems
                emitStacks(groups[cat])
                catRowCount[cat] = #flatItems - before
                -- Snapshot the stacked rows for this category so the draw
                -- loop can iterate per-cat without using the unstacked source.
                local catRows = {}
                for i = before + 1, #flatItems do
                    catRows[#catRows + 1] = flatItems[i]
                end
                stackedGroups[cat] = catRows
            else
                catRowCount[cat] = 0
                stackedGroups[cat] = {}
            end
        end
    else
        -- Non-grouped (sortCol = cond/wt): stack across all items.
        local all = {}
        for _, cat in ipairs(catOrder) do
            for _, item in ipairs(groups[cat]) do
                all[#all + 1] = item
            end
        end
        table.sort(all, sorter)
        emitStacks(all)
    end

    return {
        groups = groups, catOrder = catOrder, flatItems = flatItems, useGroups = useGroups,
        stacks = stacks, childParent = childParent, stackedGroups = stackedGroups,
        catRowCount = catRowCount, catOf = catOf,
    }
end

]==]

-- ---------------------------------------------------------------------------
-- THE STUBS
-- ---------------------------------------------------------------------------
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

-- every ask of an item counts; inside a comparison it counts twice over (inCmp)
local GETS, CMP_GETS, CMPS = 0, 0, 0
local inCmp = false
local function got() GETS = GETS + 1; if inCmp then CMP_GETS = CMP_GETS + 1 end end

local origSort = table.sort
table.sort = function(t, f)
    if not f then return origSort(t) end
    return origSort(t, function(a, b)
        CMPS = CMPS + 1
        local was = inCmp
        inCmp = true
        local r = f(a, b)
        inCmp = was
        return r
    end)
end

local function list(t)
    return { size = function() return #t end, get = function(_, i) return t[i + 1] end }
end

-- the game's clock, set by the checks
local NOW = 1762500000000   -- (Nov 2025 in ms: past 2^31, as the real clock is)
getTimestampMs = function() return NOW end
local HANDLERS = {}
Events = {
    OnContainerUpdate = { Add = function(f) HANDLERS.container = f end },
    OnClothingUpdated = { Add = function(f) HANDLERS.clothing = f end },
}
instanceof = function(o, cls) return type(o) == "table" and o._class == cls end

ZeD = ZeD or {}
ZeD.InventoryRenderer = {}
-- (the COND / AMT column's sort reads ItemMeter since Nov 11 2026, punch list 152: what the bar shows, not always the
-- condition; item_meter_sim checks that rule. Here the old condition rule stands in, so ORDER still compares the
-- model's plumbing against the frozen reference)
ZeD.ItemMeter = { sortKey = function(item)
    local mx = item:getConditionMax()
    if not mx or mx <= 0 then return -1 end
    return item:getCondition() / mx
end }
function ZeD.InventoryRenderer.catKey(item)   -- (the file's own, as it is)
    local dc = item:getDisplayCategory()
    if dc and dc ~= "" then return dc end
    return item:getCategory() or "Other"
end
ZeD.ContainerGates = { get = function() return nil end, keeps = function() return true end }
-- a groups provider (as Better Folders): some things filed in two folders, one more folder empty
local PROVIDER = false
ZeD.ContainerGroups = {
    groupOf = function(item, inv, p, isP)
        if not (PROVIDER and isP) then return nil end
        if item.id % 7 == 0 then return "vif:0:Tools" end
        if item.id % 11 == 0 then return "vif:0:Food" end
        return nil
    end,
    keys = function(inv, p, isP)
        if not (PROVIDER and isP) then return {} end
        return { "vif:0:Tools", "vif:0:Food", "vif:0:Empty" }
    end,
    sortKeys = function(keys, asc)
        origSort(keys, function(a, b)
            local fa, fb = a:sub(1, 4) == "vif:", b:sub(1, 4) == "vif:"
            if fa ~= fb then return fa end
            if asc then return a < b end
            return a > b
        end)
    end,
    sig = function() return PROVIDER end,
}
stackWeight = function(stackInfo)   -- (the file's own, as it is)
    local total = 0
    for _, si in ipairs(stackInfo.items) do total = total + (si:getUnequippedWeight() or 0) end
    return total
end

-- ---------------------------------------------------------------------------
-- THE CONTAINER: 300 things, made for ties (the same names in two cases, the
-- same weights, conditions, categories), stacks, hidden things, worn and held
-- things, a stale one (its container says another)
-- ---------------------------------------------------------------------------
local NAMES = { "Apple", "apple", "Axe", "Bandage", "bandage", "Can Opener", "Duct Tape", "Hammer", "Lighter",
                "Nails", "Pencil", "Rope", "Saw", "Screwdriver", "Socks", "Spoon", "Tin of Beans", "Water Bottle",
                "Wrench", "Zippo", "", "T-Shirt", "Jeans", "Belt", "Watch" }
local CATS = { "Food", "Tool", "Clothing", "Medical", "Junk", "Literature", "Container", "Weapon" }
local WTS = { 0.1, 0.2, 0.5, 1.0, 1.5, 0.1, 0.5 }

local player = { _class = "IsoPlayer", worn = {} }
local main = {}
local items = {}
local function mkItem(id, inv)
    local nm = NAMES[(id * 7) % #NAMES + 1]
    local it = { id = id, inv = inv }
    local cat = CATS[(id * 3) % #CATS + 1]
    local dc = (id % 5 == 0) and "" or cat
    local cmax = (id % 13 == 0) and 0 or 100
    local cond = (id % 4) * 25
    local wt = WTS[(id * 5) % #WTS + 1]
    local ft = "Base." .. nm:gsub("%W", "") .. ((id % 3 == 0) and "B" or "")
    function it:getName() got(); if id % 17 == 0 then return nil end return nm end
    function it:getDisplayCategory() got(); return dc end
    function it:getCategory() got(); return cat end
    function it:getConditionMax() got(); return cmax end
    function it:getCondition() got(); return cond end
    function it:getUnequippedWeight() got(); return wt end
    function it:getFullType() got(); return ft end
    function it:isHidden() got(); return id % 29 == 0 end
    function it:getContainer() got(); return it.stale or it.inv end
    -- item:isEquipped(): the character whose container holds it (IsoGameCharacter.isEquipped)
    function it:isEquipped()
        got()
        local c = it.stale or it.inv
        local par = c and c.parent
        if par and par.isEquipped then return par:isEquipped(it) end
        return false
    end
    return it
end
local function makeInv(parent, n, base)
    local inv = { parent = parent, things = {} }
    function inv:getItems() return list(self.things) end
    function inv:getParent() return self.parent end
    function inv:getCapacityWeight() return #self.things end
    for i = 1, n do
        local it = mkItem(base + i, inv)
        inv.things[#inv.things + 1] = it
        items[#items + 1] = it
    end
    return inv
end
function player:isEquipped(item)
    for _, w in ipairs(self.worn) do if w == item then return true end end
    return item == self.ph or item == self.sh
end
function player:getWornItems()
    local w = self.worn
    return { size = function() return #w end, get = function(_, i) local x = w[i + 1]; return { getItem = function() return x end } end }
end
function player:getPrimaryHandItem() return self.ph end
function player:getSecondaryHandItem() return self.sh end
function player:isLocalPlayer() return true end
function player:getInventory() return main end

main = makeInv(player, 300, 0)
local T = main.things
player.worn = { T[3], T[40], T[41], T[200] }
player.ph, player.sh = T[77], T[150]
T[260].stale = { parent = { isEquipped = function(_, it) return true end } }   -- its container says another (held there)
T[261].stale = { parent = nil }                                                 -- its container says another (held nowhere)
player.worn[#player.worn + 1] = T[261]                                          -- (but the player wears it)

local bag = makeInv(nil, 300, 1000)                  -- a bag in the inventory: its parent is nothing
player.worn[#player.worn + 1] = bag.things[5]        -- (one of its things worn all the same)
local other = { _class = "IsoZombie", isEquipped = function(_, it) return it.id % 9 == 0 end }
local held = makeInv(other, 300, 2000)               -- another character's: held by them, asked per item

-- ---------------------------------------------------------------------------
-- LOAD: the reference (the model of Nov 7 2026, frozen above) and the file's
-- ---------------------------------------------------------------------------
local oldChunk = assert(loadstring(OLD_SRC .. "\nreturn buildItemModel", "old_model"))
local oldBuild = oldChunk()

local f = assert(io.open(ROOT .. "42/media/lua/client/ZeD/InventoryRenderer.lua", "rb"))
local src = f:read("*a"); f:close()
local a = src:find("local MODEL_REFRESH_MS", 1, true)
local b = src:find("-- ROW PARTS", 1, true)
check("the list model cut from InventoryRenderer.lua", a ~= nil and b ~= nil)
local newChunk = assert(loadstring(src:sub(a, b - 1) .. "\nreturn itemModel, buildItemModel", "new_model"))
local itemModel, newBuild = newChunk()
check("dirtyModels is there", type(ZeD.InventoryRenderer.dirtyModels) == "function")
check("the container event hooked", HANDLERS.container == ZeD.InventoryRenderer.dirtyModels)

-- ---------------------------------------------------------------------------
-- SAME ORDER: every sort, both ways, grouped and flat, a mod's groups or none,
-- folds and open stacks, the player's own, a bag, another character's
-- ---------------------------------------------------------------------------
local function ids(t)
    local o = {}
    for i, it in ipairs(t or {}) do o[i] = type(it) == "table" and tostring(it.id or it) or tostring(it) end
    return table.concat(o, ",")
end
local function sameModel(mo, mn)
    if ids(mo.catOrder) ~= ids(mn.catOrder) then return false, "catOrder" end
    if ids(mo.flatItems) ~= ids(mn.flatItems) then return false, "flatItems" end
    if mo.useGroups ~= mn.useGroups then return false, "useGroups" end
    for _, c in ipairs(mo.catOrder) do
        if ids(mo.groups[c]) ~= ids(mn.groups[c]) then return false, "groups " .. c end
        if ids(mo.stackedGroups[c]) ~= ids(mn.stackedGroups[c]) then return false, "stackedGroups " .. c end
        if mo.catRowCount[c] ~= mn.catRowCount[c] then return false, "catRowCount " .. c end
    end
    for it, s in pairs(mo.stacks) do
        local s2 = mn.stacks[it]
        if not s2 or s2.count ~= s.count or s2.key ~= s.key or ids(s2.items) ~= ids(s.items) then return false, "stack " .. it.id end
    end
    for it in pairs(mn.stacks) do if not mo.stacks[it] then return false, "extra stack" end end
    for it, s in pairs(mo.childParent) do if mn.childParent[it] == nil then return false, "child" end end
    for it, c in pairs(mo.catOf) do if mn.catOf[it] ~= c then return false, "catOf" end end
    return true
end

local SORTS = { "name", "cat", "cond", "wt" }
local INVS = { { "the player's own", main, true }, { "a bag", bag, true }, { "another's", held, true },
               { "loot", main, false } }
local FOLDS = { { "no folds", {}, {} }, { "folds and open stacks", { Food = true, ["vif:0:Food"] = true },
                { ["Base.Apple"] = true, ["Base.Hammer"] = true, ["Base.SocksB"] = true } } }
local runs, totO, totN, cmpO, cmpN, cgO, cgN = 0, 0, 0, 0, 0, 0, 0
local per = {}
for _, prov in ipairs({ false, true }) do
    PROVIDER = prov
    for _, iv in ipairs(INVS) do
        for _, fo in ipairs(FOLDS) do
            for _, col in ipairs(SORTS) do
                for _, asc in ipairs({ true, false }) do
                    GETS, CMP_GETS, CMPS = 0, 0, 0
                    local mo = oldBuild(iv[2], player, iv[3], col, asc, fo[2], fo[3])
                    local g1, cg1, c1 = GETS, CMP_GETS, CMPS
                    GETS, CMP_GETS, CMPS = 0, 0, 0
                    local mn = newBuild(iv[2], player, iv[3], col, asc, fo[2], fo[3])
                    local g2, cg2, c2 = GETS, CMP_GETS, CMPS
                    local ok, why = sameModel(mo, mn)
                    local tag = (prov and "groups" or "no groups") .. " | " .. iv[1] .. " | " .. fo[1] .. " | " .. col .. (asc and " A-Z" or " Z-A")
                    check("same model: " .. tag, ok, why)
                    check("same comparisons: " .. tag, c1 == c2, c1 .. " vs " .. c2)
                    check("no asks inside a comparison: " .. tag, cg2 == 0, cg2)
                    runs = runs + 1
                    totO, totN, cmpO, cmpN, cgO, cgN = totO + g1, totN + g2, cmpO + c1, cmpN + c2, cgO + cg1, cgN + cg2
                    if not prov and iv[1] == "the player's own" and fo[1] == "no folds" and asc then
                        per[#per + 1] = string.format("  %-4s A-Z: comparisons %5d -> %5d | asks in comparisons %5d -> %d | asks per build %5d -> %4d",
                            col, c1, c2, cg1, cg2, g1, g2)
                    end
                end
            end
        end
    end
end
check("the hidden things are out", (function()
    local m = newBuild(main, player, true, "name", true, {}, {})
    for _, it in ipairs(m.flatItems) do if it.id % 29 == 0 then return false end end
    return true
end)())
check("worn and held things out of the player's own list, in loot", (function()
    PROVIDER = false
    local m = newBuild(main, player, true, "wt", true, {}, {})
    local mm = newBuild(main, player, false, "wt", true, {}, {})
    local function has(model, it)
        for _, x in ipairs(model.flatItems) do if x == it then return true end end
        for _, s in pairs(model.stacks) do for _, x in ipairs(s.items) do if x == it then return true end end end
        return false
    end
    return not has(m, T[3]) and not has(m, T[77]) and not has(m, T[150]) and not has(m, T[260]) and not has(m, T[261])
       and has(mm, T[3]) and has(mm, T[77])
end)())

-- ---------------------------------------------------------------------------
-- WHEN IT REBUILDS: about once a second, each column on its own beat; at once
-- on a change of what it is built from; within MODEL_EVENT_MS of an event
-- ---------------------------------------------------------------------------
PROVIDER = false
local colA, colB, colC = {}, {}, {}
local function draw(col, inv, sortCol, asc, folds)
    local before = GETS
    local m = itemModel(col, inv, player, inv == main, sortCol or "name", asc ~= false, folds or {}, {})
    return m, GETS > before + 0   -- (a build asks the items; a kept model asks nothing of them)
end
NOW = 1762500000000
local m1, b1 = draw(colA, main)
local m2, b2 = draw(colA, main)
check("first draw builds", b1)
check("the next frame keeps it", not b2 and m1 == m2)
-- a whole minute of 60 fps with three columns opened together: rebuilds per column, rebuilds together
local nA, nB, nC, together = 0, 0, 0, 0
draw(colB, bag); draw(colC, held)
for frame = 1, 3600 do
    NOW = NOW + 16.6667
    local _, ra = draw(colA, main)
    local _, rb = draw(colB, bag)
    local _, rc = draw(colC, held)
    if ra then nA = nA + 1 end
    if rb then nB = nB + 1 end
    if rc then nC = nC + 1 end
    if (ra and rb) or (ra and rc) or (rb and rc) then together = together + 1 end
end
check("about once a second (a minute: 58-61 builds a column)", nA >= 58 and nA <= 61 and nB >= 58 and nB <= 61 and nC >= 58 and nC <= 61, nA .. "/" .. nB .. "/" .. nC)
check("the columns never rebuild on the same frame", together == 0, together)
local timing = string.format("  a minute at 60 fps, three columns: %d / %d / %d builds (every 30 frames before: 120 each, all on the same frames)", nA, nB, nC)
-- a change of what it is built from: at once
local sz = #main.things
main.things[#main.things + 1] = mkItem(5000, main)
local _, rN = draw(colA, main)
check("an item more: rebuilt on that frame", rN)
table.remove(main.things)
draw(colA, main)
NOW = NOW + 16
local _, rS = draw(colA, main, "wt")
check("the sort changed: rebuilt on that frame", rS)
NOW = NOW + 16
local _, rF = draw(colA, main, "wt", true, { Food = true })
check("a fold: rebuilt on that frame", rF)
player.ph = T[78]
NOW = NOW + 16
local _, rH = draw(colA, main, "wt", true, { Food = true })
check("a hand changed: rebuilt on that frame", rH)
player.ph = T[77]
draw(colA, main, "wt", true, { Food = true })
-- an event (the game's OnContainerUpdate, a drop): rebuilt within MODEL_EVENT_MS of the last build
local F2 = { Food = true, Junk = true }
NOW = NOW + 16
local _, rF2 = draw(colA, main, "wt", true, F2)   -- (a fold: a build now)
check("another fold: rebuilt on that frame", rF2)
local tBuilt = NOW
HANDLERS.container()
local waited, rebuilt = 0, false
for i = 1, 40 do
    NOW = NOW + 16
    local _, r = draw(colA, main, "wt", true, F2)
    if r then rebuilt = true; waited = NOW - tBuilt; break end
end
check("after an event: rebuilt within 500 ms of the last build", rebuilt and waited <= 516, waited)
-- right after a build an event waits; a storm of events every frame rebuilds at most twice a second
local storm = 0
for i = 1, 60 do
    NOW = NOW + 16.6667
    HANDLERS.container()
    local _, r = draw(colA, main, "wt", true, F2)
    if r then storm = storm + 1 end
end
check("an event every frame for a second: 1-3 rebuilds", storm >= 1 and storm <= 3, storm)
-- a zombie dressing: nothing; the player: a rebuild
local zed = { _class = "IsoZombie" }
NOW = NOW + 16
local _, rF3 = draw(colA, main, "wt", true, { Food = true })   -- (a fold: a build now)
NOW = NOW + 520
HANDLERS.clothing(zed)
local _, rz = draw(colA, main, "wt", true, { Food = true })
check("a zombie's clothes: no rebuild", rF3 and not rz)
HANDLERS.clothing(player)
local _, rp = draw(colA, main, "wt", true, { Food = true })
check("the player's clothes: a rebuild", rp)
-- the clock set back: rebuilt, then kept again
NOW = NOW - 3600000
local _, rb1 = draw(colA, main, "wt", true, { Food = true })
NOW = NOW + 16
local _, rb2 = draw(colA, main, "wt", true, { Food = true })
check("the clock set back: rebuilt once, then kept", rb1 and not rb2)

table.sort = origSort
print("inv_model_sort_sim: " .. runs .. " builds compared old vs new (300 things a container)")
print(string.format("  all runs: comparisons %d -> %d | asks inside comparisons %d -> %d | asks in all %d -> %d",
    cmpO, cmpN, cgO, cgN, totO, totN))
for _, l in ipairs(per) do print(l) end
print(timing)
print("inv_model_sort_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
