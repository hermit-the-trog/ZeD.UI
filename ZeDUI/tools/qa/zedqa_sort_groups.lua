-- ZeDUI/tools/qa/zedqa_sort_groups.lua  (Oct 21 2026)
-- In game on the ZeD-QA save: which sort keys group the inventory under category
-- headers. Only Sort by Category does; Name (A to Z, or Z to A reversed), Condition
-- and Weight are one flat list with no headers, in list and in grid.
-- About 24 mixed things in the character's bag and a worn pack, 20 in a pickup's
-- bed and 12 on the ground beside it. For each sort key (category, name, condition,
-- weight) x list / grid x single column / multi-container (the pack beside the bag;
-- the bed beside the ground), in BOTH windows at once, it logs: the number of
-- "cat:" header zones (must be > 0 only for category), whether the rows are in
-- order (name A-Z and Z-A, condition and weight rising, category then name), and
-- whether the pad's row focusables match the rows. Then, in the single list: a
-- category folded, Name (all rows back, no headers), Category again (still
-- folded), and a stack ("> Canned Beans x3") expanded in the flat list.
-- Everything is put back (sorts, grid choices, columns, folds, items, the pack).
-- A line with FAIL is a check that did not hold. grep "ZEDQA sg";
-- screenshots Screenshots/zqa_sg_<mode>_<view>_<key>[_rev].png (both windows each).
local p = getPlayer()
local pn = p:getPlayerNum()
local IR = ZeD.InventoryRenderer
local function say(s) print("ZEDQA sg " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_sg_" .. n .. ".png") end) end
local function cwin() return ZeD_CharacterWindow.getWindow() end
local function wwin() return ZeD_WorldWindow.getWindow() end

local given, floorItems, spawned = {}, {}, {}
local pickup, bed, pack
local bagBefore = 0
local sqWorld
local openedPair, started = false, false
local gridTouched, gridOld = {}, {}
local NIL = {}
local tot = {}          -- rows in the single list, per window (the unfolded count)
local fails = 0

local function fail(s) fails = fails + 1; say("FAIL " .. s) end

-- ---- items
local function put(inv, ft, n, tag)
    local made = 0
    for _ = 1, n or 1 do
        local ok, it = pcall(function() return inv:AddItem(ft) end)
        if ok and it then
            made = made + 1
            given[#given + 1] = it
            local mx = it:getConditionMax()
            if mx and mx > 1 then
                it:setCondition(math.max(1, math.floor(mx * (((#given * 37) % 90) + 10) / 100)))
            end
        else
            say("no item " .. ft)
        end
    end
    return made
end
local function putAll(inv, list)
    local n = 0
    for _, e in ipairs(list) do n = n + put(inv, e[1], e[2]) end
    return n
end
local LIST_BAG = {
    { "Base.WaterBottle" }, { "Base.TinnedBeans", 3 }, { "Base.Crisps" }, { "Base.BeefJerky" }, { "Base.Bandage", 2 },
    { "Base.Matches" }, { "Base.Rope" }, { "Base.Saw" }, { "Base.Nails" }, { "Base.DuctTape" }, { "Base.Battery" },
    { "Base.Apple", 2 }, { "Base.Chocolate" }, { "Base.Machete" }, { "Base.Book" }, { "Base.Hammer" },
    { "Base.Screwdriver" }, { "Base.Pencil" }, { "Base.Crowbar" },
}
local LIST_PACK = {
    { "Base.Bandage" }, { "Base.Disinfectant" }, { "Base.Lighter" }, { "Base.Notebook" }, { "Base.Peanuts" },
    { "Base.Wrench" }, { "Base.Pencil" }, { "Base.Hammer" },
}
local LIST_BED = {
    { "Base.Nails", 3 }, { "Base.Plank", 4 }, { "Base.TinnedBeans", 2 }, { "Base.Screws", 2 }, { "Base.PetrolCan" },
    { "Base.Toolbox" }, { "Base.Tarp" }, { "Base.Jack" }, { "Base.LugWrench" }, { "Base.TinnedSoup" },
    { "Base.CannedCorn" }, { "Base.Sledgehammer" },
}
local LIST_FLOOR = {
    { "Base.Plank", 2 }, { "Base.Axe" }, { "Base.Apple", 2 }, { "Base.Crisps" }, { "Base.Bandage" }, { "Base.Hammer" },
    { "Base.Rope" }, { "Base.TinnedSoup" }, { "Base.WaterBottle" },
}

-- ---- the pickup (the nearest in the loaded cell, else one spawned beside the character)
local function nearVehicle(pred)
    local best, bd
    local it = getCell():getVehicles():iterator()
    while it:hasNext() do
        local v = it:next()
        if pred(v) then local d = v:DistTo(p); if not bd or d < bd then best, bd = v, d end end
    end
    return best
end
local function spawnVehicle(script, dx, dy)
    local sq = getCell():getGridSquare(math.floor(p:getX()) + dx, math.floor(p:getY()) + dy, math.floor(p:getZ()))
    if not sq then return nil end
    local ok, v = pcall(addVehicleDebug, script, IsoDirections.N, nil, sq)
    if ok and v then spawned[#spawned + 1] = v; return v end
    return nil
end

-- ---- windows and columns
local function winOf(k) if k == "char" then return cwin() end return wwin() end
local function contentOf(k) local w = winOf(k); return w and w._mainContent end
local function colOn(win, inv)
    if not (win and inv) then return false end
    for i, c in ipairs(win._containers or {}) do
        if c.inventory == inv then
            for _, j in ipairs(win._mcSelected or {}) do if j == i then return true end end
            return false
        end
    end
    return false
end
local function mcInv(k) if k == "char" then return pack and pack:getInventory() end return bed end
local function toggleMc(k)
    if k == "char" then return ZeD_CharacterWindow.toggleColumn(mcInv(k)) end
    return ZeD_WorldWindow.toggleColumn(mcInv(k))
end
local function ensureMode(mode)
    local out = {}
    for _, k in ipairs({ "char", "world" }) do
        local want = (mode == "multi")
        local w = winOf(k)
        if w and mcInv(k) and colOn(w, mcInv(k)) ~= want then out[#out + 1] = k .. ":" .. tostring(toggleMc(k)) end
    end
    return table.concat(out, " ")
end
local function tabLoot()
    local w = cwin()
    local strip = w and w._tabStripPanel
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:loot" then if w._activeTab ~= "loot" then strip:onMouseDown(z.x + 2, z.y + 2) end; break end
    end
    pcall(function() ZeD_WorldWindow.openTab(pn, "loot") end)
end

-- ---- the sort and the grid choice
local function setSort(c, key, asc)
    c._sortCol, c._sortAsc = key, asc
    for _, cs in ipairs(c._colStates or {}) do cs.sortCol, cs.sortAsc = key, asc end
end
local function gridStore()
    local md = p:getModData()
    md.ZeD_GridViews = md.ZeD_GridViews or {}
    return md.ZeD_GridViews
end
local function setView(grid)
    local st = gridStore()
    local invs = { p:getInventory(), pack and pack:getInventory(), bed, ZeD_WorldWindow.getFloorContainer() }
    for i = 1, 4 do
        local inv = invs[i]
        local key = inv and IR.containerKey(inv, p)
        if key then
            if not gridTouched[key] then
                gridTouched[key] = true
                gridOld[key] = (st[key] == nil) and NIL or st[key]
            end
            IR.setGridKey(key, grid)
        end
    end
end

-- ---- reading a content: its columns, header zones, order, pad rows
local function cols(c)
    local out = {}
    if c._colStates and #c._colStates > 0 then
        for _, cs in ipairs(c._colStates) do
            out[#out + 1] = { items = cs.flatItems or {}, child = cs.childParent or {}, inv = cs.inventory, cs = cs }
        end
    else
        out[1] = { items = c._flatItems or {}, child = c._childParent or {}, inv = c._inventory }
    end
    return out
end
local function headerCount(c)
    local n = 0
    for _, z in ipairs(c._hitZones or {}) do
        if type(z.id) == "string" and z.id:sub(1, 4) == "cat:" then n = n + 1 end
    end
    return n
end
local function headerZone(c, cat)
    for _, z in ipairs(c._hitZones or {}) do
        if z.id == "cat:" .. cat then return true end
    end
    return false
end
local function nm(it) return string.lower(it:getName() or "") end
local function condPct(it)
    local mx = it:getConditionMax()
    if not mx or mx <= 0 then return -1 end
    return it:getCondition() / mx
end
-- true when the rows (stack children skipped) are in the key's order; else false + where
local function inOrder(col, key, asc)
    local prev
    for _, it in ipairs(col.items) do
        if not col.child[it] then
            if prev then
                local bad
                if key == "name" then
                    if asc then bad = nm(prev) > nm(it) else bad = nm(prev) < nm(it) end
                elseif key == "cond" then
                    bad = condPct(prev) > condPct(it)
                elseif key == "wt" then
                    bad = prev:getUnequippedWeight() > it:getUnequippedWeight()
                else
                    local a, b = IR.catKey(prev), IR.catKey(it)
                    bad = (a > b) or (a == b and nm(prev) > nm(it))
                end
                if bad then return false, prev:getName() .. " before " .. it:getName() end
            end
            prev = it
        end
    end
    return true
end
local function padRows(k)
    local w = winOf(k)
    local n, zones = 0, {}
    for _, z in ipairs(w and w._focusRing or {}) do   -- charMainInv / charMC1.., worldMainInv / worldMC1..
        local zn = tostring(z.zone)
        if zn == k .. "MainInv" or zn:sub(1, #k + 2) == k .. "MC" then
            local m = 0
            for _, e in ipairs(z.elements or {}) do if e.item then m = m + 1 end end
            n = n + m
            zones[#zones + 1] = zn .. "=" .. m
        end
    end
    return n, table.concat(zones, ",")
end

-- one state's line: both windows
local function check(mode, view, key, asc, wantCols)
    local tag = mode .. " " .. view .. " " .. key .. (asc and "" or " rev")
    for _, k in ipairs({ "char", "world" }) do
        local c = contentOf(k)
        if not c then fail(tag .. " " .. k .. ": no content") else
            local cl = cols(c)
            local rows, rr, orderMsg = 0, {}, nil
            for _, col in ipairs(cl) do
                rows = rows + #col.items
                rr[#rr + 1] = #col.items
                local ok, where = inOrder(col, key, asc)
                if not ok and not orderMsg then orderMsg = where end
            end
            local hdr = headerCount(c)
            local pad, padZones = padRows(k)
            local isGrid = c._gridCell ~= nil
            say(string.format("%s %s: columns %d rows %s headers %d order %s pad %d (%s) grid %s sort %s/%s",
                tag, k, #cl, table.concat(rr, "+"), hdr, orderMsg and ("BAD " .. orderMsg) or "ok", pad, padZones,
                tostring(isGrid), tostring(c._sortCol), tostring(c._sortAsc)))
            if (key == "cat") ~= (hdr > 0) then fail(tag .. " " .. k .. ": headers " .. hdr) end
            if key == "cat" and hdr < #cl then fail(tag .. " " .. k .. ": fewer headers than columns") end
            if orderMsg then fail(tag .. " " .. k .. ": order " .. orderMsg) end
            if isGrid ~= (view == "grid") then fail(tag .. " " .. k .. ": view is " .. tostring(isGrid)) end
            if wantCols and #cl ~= wantCols[k] then fail(tag .. " " .. k .. ": " .. #cl .. " columns, wanted " .. wantCols[k]) end
            if pad ~= rows then fail(tag .. " " .. k .. ": pad rows " .. pad .. " of " .. rows) end
            if mode == "single" and view == "list" and key == "cat" then tot[k] = rows end
            if rows == 0 then fail(tag .. " " .. k .. ": no rows") end
        end
    end
    shot(mode .. "_" .. view .. "_" .. key .. (asc and "" or "_rev"))
end

-- ---- the run: each step waits for its minimum ticks
local steps, si, wait = {}, 1, 0
local dead = false
local function step(n, fn) steps[#steps + 1] = { n, fn } end
local function abort(msg) say("ERR " .. msg); dead = true; si = #steps - 1 end

local KEYS = { "cat", "name", "cond", "wt" }
local function applyAll(key, asc)
    for _, k in ipairs({ "char", "world" }) do
        local c = contentOf(k)
        if c then setSort(c, key, asc) end
    end
end
local function stateSteps(mode, view, wantCols)
    for i, key in ipairs(KEYS) do
        step(8, function() applyAll(key, true) end)
        step(8, function() check(mode, view, key, true, wantCols) end)
    end
    step(8, function() applyAll("name", false) end)
    step(8, function() check(mode, view, "name", false, wantCols) end)
end

-- the fold: a category folded, Name shows every row with no headers, Category again keeps the fold
local foldCat = {}
local function foldTable(c)
    local cs = c._colStates and c._colStates[1]
    return cs and cs.collapsedGroups or c._collapsedGroups
end
local function foldSteps()
    step(8, function() applyAll("cat", true) end)
    step(8, function()
        for _, k in ipairs({ "char", "world" }) do
            local c = contentOf(k)
            local col = c and cols(c)[1]
            local first = col and col.items[1]
            if first then foldCat[k] = IR.catKey(first); foldTable(c)[foldCat[k]] = true end
        end
    end)
    step(10, function()
        for _, k in ipairs({ "char", "world" }) do
            local c = contentOf(k)
            local rows = #cols(c)[1].items
            say("fold " .. k .. ": " .. tostring(foldCat[k]) .. " folded, rows " .. rows .. " of " .. tostring(tot[k]) .. ", its header " .. tostring(headerZone(c, tostring(foldCat[k]))))
            if not (tot[k] and rows < tot[k]) then fail("fold " .. k .. ": folding hid no rows") end
            if not headerZone(c, tostring(foldCat[k])) then fail("fold " .. k .. ": no header for the folded category") end
            foldCat[k .. "rows"] = rows
        end
        shot("fold_cat")
    end)
    step(8, function() applyAll("name", true) end)
    step(10, function()
        for _, k in ipairs({ "char", "world" }) do
            local c = contentOf(k)
            local rows = #cols(c)[1].items
            say("fold " .. k .. " on Name: rows " .. rows .. " headers " .. headerCount(c))
            if rows ~= tot[k] then fail("fold " .. k .. ": Name shows " .. rows .. " rows, not all " .. tostring(tot[k])) end
            if headerCount(c) ~= 0 then fail("fold " .. k .. ": Name has headers") end
        end
        shot("fold_name")
    end)
    step(8, function() applyAll("cat", true) end)
    step(10, function()
        for _, k in ipairs({ "char", "world" }) do
            local c = contentOf(k)
            local rows = #cols(c)[1].items
            local kept = foldTable(c)[foldCat[k]] == true
            say("fold " .. k .. " back on Category: still folded " .. tostring(kept) .. " rows " .. rows)
            if not kept or rows ~= foldCat[k .. "rows"] then fail("fold " .. k .. ": the fold was not kept") end
            foldTable(c)[foldCat[k]] = nil
        end
        shot("fold_back")
    end)
end

-- a stack expanded in the flat list
local stackKey = {}
local function stackSteps()
    step(8, function() applyAll("name", true) end)
    step(8, function()
        for _, k in ipairs({ "char", "world" }) do
            local c = contentOf(k)
            local col = cols(c)[1]
            stackKey[k] = nil
            for _, it in ipairs(col.items) do
                local s = c._stacks and c._stacks[it]
                if s and s.count > 1 then stackKey[k] = s; break end
            end
            if not stackKey[k] then fail("stack " .. k .. ": no stack in the list") else
                local cs = c._colStates and c._colStates[1]
                local t = (cs and cs.expandedStacks) or c._expandedStacks
                t[stackKey[k].key] = true
            end
        end
    end)
    step(10, function()
        for _, k in ipairs({ "char", "world" }) do
            local s = stackKey[k]
            if s then
                local c = contentOf(k)
                local col = cols(c)[1]
                local rows = #col.items
                local at
                for i, it in ipairs(col.items) do if it == s.rep then at = i end end
                local adj = at ~= nil
                for j = 1, s.count - 1 do
                    local it = at and col.items[at + j]
                    if not (it and col.child[it]) then adj = false end
                end
                say("stack " .. k .. ": " .. tostring(s.key) .. " x" .. s.count .. " open, rows " .. rows .. " of " .. tostring(tot[k])
                    .. " (+" .. (s.count - 1) .. " expected), children follow " .. tostring(adj) .. ", headers " .. headerCount(c))
                if rows ~= tot[k] + s.count - 1 then fail("stack " .. k .. ": rows " .. rows) end
                if not adj then fail("stack " .. k .. ": children do not follow the stack") end
                local pad = padRows(k)
                if pad ~= rows then fail("stack " .. k .. ": pad rows " .. pad .. " of " .. rows) end
            end
        end
        shot("stack_open")
    end)
    step(8, function()
        for _, k in ipairs({ "char", "world" }) do
            local s = stackKey[k]
            if s then
                local c = contentOf(k)
                local cs = c._colStates and c._colStates[1]
                local t = (cs and cs.expandedStacks) or c._expandedStacks
                t[s.key] = nil
            end
        end
    end)
    step(8, function()
        for _, k in ipairs({ "char", "world" }) do
            local rows = #cols(contentOf(k))[1].items
            if rows ~= tot[k] then fail("stack " .. k .. ": " .. rows .. " rows after closing, not " .. tostring(tot[k])) end
        end
    end)
end

step(1, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    p:setGodMod(true)
    started = true
    pickup = nearVehicle(function(v) return v:getScriptName() == "Base.PickUpTruck" end)
    if not pickup then
        pickup = spawnVehicle("Base.PickUpTruck", -4, 0)
        say("no pickup in the loaded cell; spawned one beside the character: " .. tostring(pickup ~= nil))
    end
    if not pickup then abort("no pickup and the spawn failed") end
end)
step(20, function()
    local part = pickup:getPartById("TruckBed") or pickup:getPartById("TruckBedOpen")
    local c = part and pickup:getAreaCenter(part:getArea())
    if not c then abort("no truck bed to stand at"); return end
    p:teleportTo(c:getX(), c:getY(), 0)
    if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn); openedPair = true end
end)
step(40, function()
    local part = pickup:getPartById("TruckBed") or pickup:getPartById("TruckBedOpen")
    bed = part and part:getItemContainer()
    if not bed then abort("the truck bed has no container"); return end
    if not wwin() then abort("the World window is not open"); return end
    local inv = p:getInventory()
    bagBefore = inv:getItems():size()
    local nb = putAll(inv, LIST_BAG)
    pack = inv:AddItem("Base.Bag_ALICEpack")
    if not pack then abort("no pack"); return end
    given[#given + 1] = pack
    local loc
    pcall(function() local ce = pack:canBeEquipped(); if ce and ce ~= "" then loc = ce else loc = pack:getBodyLocation() end end)
    pcall(function() p:setWornItem(loc, pack) end)
    local worn = false
    pcall(function() worn = p:getWornItem(loc) == pack end)
    say("pack worn at " .. tostring(loc) .. ": " .. tostring(worn))
    if not worn then abort("the pack is not worn"); return end
    local np = putAll(pack:getInventory(), LIST_PACK)
    local nd = putAll(bed, LIST_BED)
    local sq = p:getCurrentSquare()
    sqWorld = sq
    local nf = 0
    for _, e in ipairs(LIST_FLOOR) do
        for _ = 1, e[2] or 1 do
            local ok, it = pcall(function() return sq:AddWorldInventoryItem(e[1], 0.5, 0.5, 0) end)
            if ok and it then
                nf = nf + 1; floorItems[#floorItems + 1] = it
                local mx = it:getConditionMax()
                if mx and mx > 1 then it:setCondition(math.max(1, math.floor(mx * (((nf * 53) % 80) + 15) / 100))) end
            else say("no floor item " .. e[1]) end
        end
    end
    say(string.format("given: bag %d, pack %d, bed %d, floor %d", nb, np, nd, nf))
    tabLoot()
end)
step(60, function()
    tabLoot()
    local fl = ZeD_WorldWindow.getFloorContainer()
    say("floor container things " .. tostring(fl and fl:getItems():size()) .. " | char window " .. tostring(cwin() and cwin():isVisible()) .. " world window " .. tostring(wwin() and wwin():isVisible()))
    say("columns at start: char " .. tostring(#(cwin()._mcSelected or {})) .. " world " .. tostring(#(wwin()._mcSelected or {})))
end)
-- single column: list then grid
step(10, function() say("mode single: " .. ensureMode("single")); setView(false) end)
step(30, function() end)
stateSteps("single", "list", { char = 1, world = 1 })
foldSteps()
stackSteps()
step(8, function() setView(true) end)
step(20, function() end)
stateSteps("single", "grid", { char = 1, world = 1 })
-- multi-container: the pack beside the bag, the bed beside the ground
step(8, function() setView(false); say("mode multi: " .. ensureMode("multi")) end)
step(40, function() local r = ensureMode("multi"); if r ~= "" then say("mode multi again: " .. r) end end)
step(30, function() end)
stateSteps("multi", "list", { char = 2, world = 2 })
step(8, function() setView(true) end)
step(20, function() end)
stateSteps("multi", "grid", { char = 2, world = 2 })

-- put everything back
step(8, function()
    for _, k in ipairs({ "char", "world" }) do
        local c = contentOf(k)
        if c then
            setSort(c, "name", true)
            for _, col in ipairs(cols(c)) do
                if col.cs then col.cs.collapsedGroups = {}; col.cs.expandedStacks = {} end
            end
            c._collapsedGroups = {}
            c._expandedStacks = {}
        end
    end
    say("columns off: " .. ensureMode("single"))
    local st = gridStore()
    for key in pairs(gridTouched) do
        if gridOld[key] == NIL then st[key] = nil else st[key] = gridOld[key] end
    end
end)
step(40, function()
    local r = ensureMode("single"); if r ~= "" then say("columns off again: " .. r) end
    for _, it in ipairs(floorItems) do
        pcall(function()
            local wo = it:getWorldItem()
            if wo then
                local sq = wo:getSquare()
                if sq then pcall(function() sq:transmitRemoveItemFromSquare(wo) end) end
                wo:removeFromWorld()
                wo:removeFromSquare()
            end
        end)
    end
    pcall(function() p:removeWornItem(pack) end)
    for _, it in ipairs(given) do pcall(function() local ct = it:getContainer(); if ct then ct:Remove(it) end end) end
    for _, v in ipairs(spawned) do pcall(function() v:permanentlyRemove() end) end
end)
step(70, function()
    local fl = ZeD_WorldWindow.getFloorContainer()
    if openedPair and ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    say("restored: bag things " .. p:getInventory():getItems():size() .. " (were " .. bagBefore .. "), bed " .. tostring(bed and bed:getItems():size())
        .. ", world things on the square " .. tostring(sqWorld and sqWorld:getWorldObjects():size()) .. ", floor container " .. tostring(fl and fl:getItems():size()))
    say((fails == 0 and "all checks held" or (fails .. " checks FAILED")) .. "; DONE" .. (dead and " (aborted)" or ""))
end)

local function t()
    local s = steps[si]
    if not s then Events.OnTick.Remove(t); return end
    wait = wait + 1
    if wait >= s[1] then
        local ok, e = pcall(s[2])
        if not ok then say("ERR step " .. si .. " " .. tostring(e)) end
        si, wait = si + 1, 0
    end
end
Events.OnTick.Add(t)
say("start")
