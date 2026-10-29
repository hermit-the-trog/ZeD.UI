-- ZeDUI/tools/qa/zedqa_dropnloot.lua  (Oct 29 2026)
-- With Easy Drop'n'Loot on (dnl via dropnloot_mods.txt): its Transfer Category and
-- Loot Category buttons in ZeD's container buttons row (ModSupport/KADropnLoot.lua
-- through ZeD.ContainerControls.addProvider). The mod picks the categories to move
-- from what the OTHER container holds (not from a selected item), so the script sets
-- both containers up with known contents. With the mod off it says so and ends.
--   1. the Character window's row and the World window's row, logged by name, shot
--      (zqa_dnl_row.png); both buttons present, on the right side;
--   2. Transfer Category (Character row, clicked through the row's own press path):
--      your items of every category the truck bed holds go into the bed; a Food item
--      the bed has no kind of stays; nothing of a held category is left behind;
--   3. Loot Category (World row): the same the other way; afterwards the button is
--      disabled (nothing left that matches);
--   4. the same two on the floor (ZeD's floor path): only run when the floor holds
--      nothing of its own (so nothing foreign is ever moved);
--   5. everything given is taken back; the bed and your bag keep what they had.
-- Timed actions are instant for the run. Copy to Zomboid/Lua/zedqa.lua, bump
-- zedqa.go; grep "ZEDQA dnl"; captures Screenshots/zqa_dnl_*.png. Ends "ZEDQA dnl DONE".
local p = getPlayer()
local pn = p:getPlayerNum()
local CT = ZeD.ContainerControls
local KD = ZeD.ModSupport and ZeD.ModSupport.KADropnLoot
local function say(s) print("ZEDQA dnl " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_dnl_" .. n .. ".png") end) end
local pickup, bed
local given, before = {}, {}
local spawned = {}
local openedPair, snapped, dead = false, false, false

local function sizeOf(inv) local it = inv and inv:getItems(); return it and it:size() or -1 end
local function count(inv, ft)
    local n = 0
    local items = inv and inv:getItems()
    for i = 0, (items and items:size() or 0) - 1 do if items:get(i):getFullType() == ft then n = n + 1 end end
    return n
end
local function ww() return ZeD_WorldWindow.getWindow() end
local function wc() return ww()._mainContent end
local function cc() return ZeD_CharacterWindow.getWindow()._mainContent end
local function floorInv() return ZeD_WorldWindow.getFloorContainer() end
local function queueEmpty()
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    return not q or not q.queue or #q.queue == 0
end
-- the mod's category rule (display category, else the plain one)
local function cat(it)
    local c = it:getDisplayCategory()
    if c == nil then c = it:getCategory() end
    return c
end
local function catsOf(inv)
    local set, names = {}, {}
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local c = cat(items:get(i))
        if c ~= nil and not set[c] then set[c] = true; names[#names + 1] = tostring(c) end
    end
    return set, table.concat(names, ",")
end
-- items still in src of a category in cats that could have moved (not favourite, not held or worn)
local function leftBehind(src, cats)
    local n = 0
    local items = src:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        local c = cat(it)
        if c ~= nil and cats[c] and not it:isFavorite() and not p:isEquipped(it) then n = n + 1 end
    end
    return n
end
local function ids(list)
    local t = {}
    for _, s in ipairs(list or {}) do t[#t + 1] = tostring(s.id) .. (s.enabled and "" or "(off)") end
    return table.concat(t, ", ")
end
local function rowText(content)
    local c = content._cc
    if not c then return "(no row)" end
    return "moves [" .. ids(c.moves) .. "] own [" .. ids(c.objs) .. "]"
end
local function spec(content, id)
    local c = content._cc
    for _, s in ipairs(c and c.objs or {}) do if s.id == id then return s end end
    return nil
end
-- clicks a button the way a press on it does (CT.press with the hit's index)
local function press(content, key)
    local c = content._cc
    for i, h in ipairs(c and c.hits or {}) do
        if h.key == key then
            say("press " .. key .. " (enabled " .. tostring(h.enabled) .. ")")
            CT.press(content, i)
            return true
        end
    end
    say("FAIL no button " .. key .. " in the row")
    return false
end
local function select(inv)
    local w = ww()
    for i, c in ipairs(w._containers or {}) do
        if c.inventory == inv then w._activeContainer = i; w._viewedContainer = nil; w._mainVisible = false; return true end
    end
    return false
end
local function give(inv, ft, n)
    for _ = 1, n do local it = inv:AddItem(ft); if it then given[#given + 1] = it end end
end

-- pickup: the nearest in the loaded cell, else one spawned beside the character (removed at the end)
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
    if not sq then say("no square for " .. script); return nil end
    local ok, v = pcall(addVehicleDebug, script, IsoDirections.N, nil, sq)
    if ok and v then spawned[#spawned + 1] = v; return v end
    return nil
end

-- One move test. src/dest: the containers; srcContent: the window whose row holds the button;
-- id/key: the button's spec id. Logs the numbers and PASS/FAIL lines.
local pending = nil
local function startMove(tag, srcContent, id, src, dest)
    local s = spec(srcContent, id)
    local cats, names = catsOf(dest)
    pending = { tag = tag, src = src, dest = dest, cats = cats, srcN = sizeOf(src), destN = sizeOf(dest) }
    pending.expect = (KD and #KD.plan(p, src, dest)) or -1
    say(tag .. ": " .. tostring(id) .. " present " .. tostring(s ~= nil) .. " enabled " .. tostring(s and s.enabled)
        .. " | target holds [" .. names .. "] | should move " .. pending.expect)
    if not s then say("FAIL " .. tag .. ": button missing"); return false end
    if (pending.expect > 0) ~= (s.enabled == true) then say("FAIL " .. tag .. ": enabled does not match what would move") end
    return press(srcContent, id)
end
local function endMove()
    local m = pending
    if not m then return end
    local moved = m.srcN - sizeOf(m.src)
    local gain = sizeOf(m.dest) - m.destN
    local left = leftBehind(m.src, m.cats)
    say(string.format("%s: moved %d (expected %d), target gained %d, movable of a held category left behind %d",
        m.tag, moved, m.expect, gain, left))
    if moved ~= m.expect or gain ~= m.expect then say("FAIL " .. m.tag .. ": counts") end
    if left ~= 0 then say("FAIL " .. m.tag .. ": items of a held category were left behind") end
    if m.expect > 0 and moved == m.expect and gain == m.expect and left == 0 then say("PASS " .. m.tag) end
    pending = nil
end

local steps, si, wait
local function abort(msg) say("ERR " .. msg); dead = true; si = #steps - 1 end

steps = {
    { 1, function()
        if not KD then say("mod off: no Transfer / Loot Category buttons expected (ModSupport/KADropnLoot did not register)"); say("DONE"); si = #steps + 1; return end
        say("providers " .. #CT.providers .. " | mod functions: move " .. tostring(type(EDNL_moveItemsByCategories))
            .. " hideDrop " .. tostring(type(EDNL_isDropKeyHidden)) .. " hideLoot " .. tostring(type(EDNL_isLootKeyHidden)))
        p:setGodMod(true)
        p:setTimedActionInstantCheat(true)
        pickup = nearVehicle(function(v) return v:getScriptName() == "Base.PickUpTruck" end)
        if not pickup then
            pickup = spawnVehicle("Base.PickUpTruck", -4, 0)
            say("no pickup in the loaded cell; spawned one beside the character: " .. tostring(pickup ~= nil))
        end
        if not pickup then abort("no pickup and the spawn failed") end
    end },
    { 20, function()
        local part = pickup:getPartById("TruckBed") or pickup:getPartById("TruckBedOpen")
        local c = part and pickup:getAreaCenter(part:getArea())
        if not c then abort("no truck bed to stand at"); return end
        p:teleportTo(c:getX(), c:getY(), 0)
        if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn); openedPair = true end
    end },
    { 40, function()
        local part = pickup:getPartById("TruckBed") or pickup:getPartById("TruckBedOpen")
        bed = part:getItemContainer()
        if not bed then abort("the truck bed has no container"); return end
        if not ww() then abort("the World window is not open"); return end
        for i = 0, bed:getItems():size() - 1 do before[bed:getItems():get(i)] = "bed" end
        for i = 0, p:getInventory():getItems():size() - 1 do before[p:getInventory():getItems():get(i)] = "bag" end
        snapped = true
        if cc()._inventory ~= p:getInventory() then say("note: the Character window shows a bag, not the main inventory") end
        -- bed: screws (Material) and a bandage (Medical); you: nails and a plank (Material, will move),
        -- tinned beans (Food, the bed has none: stays)
        give(bed, "Base.Screws", 2); give(bed, "Base.Bandage", 1)
        give(p:getInventory(), "Base.Nails", 2); give(p:getInventory(), "Base.Plank", 1); give(p:getInventory(), "Base.TinnedBeans", 1)
    end },
    { 40, function()
        local ok = false
        for i, c in ipairs(ww()._containers or {}) do
            if c.inventory == bed then ww()._activeContainer = i; ww()._viewedContainer = nil; ww()._mainVisible = false; ok = true end
        end
        say("bed selected " .. tostring(ok))
    end },
    -- 1. the rows
    { 40, function()
        say("your row: " .. rowText(cc()))
        say("world row: " .. rowText(wc()))
        local a, b = spec(cc(), "dnl:transfer"), spec(wc(), "dnl:loot")
        say("Transfer Category in your row: " .. tostring(a ~= nil) .. (a and (" label '" .. a.label .. "' help '" .. tostring(a.help) .. "'") or ""))
        say("Loot Category in the World row: " .. tostring(b ~= nil) .. (b and (" label '" .. b.label .. "' help '" .. tostring(b.help) .. "'") or ""))
        if not a then say("FAIL Transfer Category is not in the Character window's row") end
        if not b then say("FAIL Loot Category is not in the World window's row") end
        if spec(wc(), "dnl:transfer") or spec(cc(), "dnl:loot") then say("FAIL a button is on the wrong side") end
        if a and b then say("PASS both buttons present") end
        shot("row")
    end },
    -- 2. Transfer Category: you -> the bed
    { 5, function() startMove("transfer", cc(), "dnl:transfer", p:getInventory(), bed) end },
    { 30, function()
        endMove()
        say(string.format("beans still with you %d, in the bed %d | nails in the bed %d, planks %d",
            count(p:getInventory(), "Base.TinnedBeans"), count(bed, "Base.TinnedBeans"), count(bed, "Base.Nails"), count(bed, "Base.Plank")))
        if count(bed, "Base.TinnedBeans") ~= 0 then say("FAIL food went into a bed that holds no food") end
        -- something of the bed's kind in your hands again, for the loot test
        give(p:getInventory(), "Base.Screws", 1)
    end },
    -- 3. Loot Category: the bed -> you
    { 40, function() startMove("loot", wc(), "dnl:loot", bed, p:getInventory()) end },
    { 30, function()
        endMove()
        local s = spec(wc(), "dnl:loot")
        say("Loot Category afterwards: enabled " .. tostring(s and s.enabled))
        if s and s.enabled then say("FAIL Loot Category stays enabled with nothing left to take") else say("PASS disabled with nothing to take") end
    end },
    -- 4. the floor
    { 10, function()
        local fl = floorInv()
        if not fl then say("SKIP floor: no floor container"); return end
        if sizeOf(fl) ~= 0 then say("SKIP floor: it holds " .. sizeOf(fl) .. " things of its own (nothing foreign is moved)"); return end
        -- two nails onto the floor
        local nails = {}
        local items = p:getInventory():getItems()
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            if it:getFullType() == "Base.Nails" and #nails < 2 and not it:isFavorite() then nails[#nails + 1] = it end
        end
        if #nails == 0 then say("SKIP floor: no nails to drop"); return end
        ISInventoryPaneContextMenu.onDropItems(nails, pn)
    end },
    { 40, function()
        local fl = floorInv()
        if not fl or sizeOf(fl) == 0 then say("floor stage skipped"); return end
        say("floor holds " .. sizeOf(fl) .. " after the drop; selected " .. tostring(select(fl)))
    end },
    { 40, function()
        local fl = floorInv()
        if not fl or sizeOf(fl) == 0 then return end
        say("world row on the floor: " .. rowText(wc()))
        startMove("loot from floor", wc(), "dnl:loot", fl, p:getInventory())
    end },
    { 40, function()
        local fl = floorInv()
        if not pending then return end
        endMove()
        say("floor now holds " .. sizeOf(fl))
        -- one nail back on the floor, then Transfer Category to the floor
        local items = p:getInventory():getItems()
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            if it:getFullType() == "Base.Nails" and not it:isFavorite() then ISInventoryPaneContextMenu.onDropItems({ it }, pn); break end
        end
    end },
    { 40, function()
        local fl = floorInv()
        if not fl or sizeOf(fl) == 0 then return end
        say("your row with the floor on show: " .. rowText(cc()))
        startMove("transfer to floor", cc(), "dnl:transfer", p:getInventory(), fl)
    end },
    { 50, function()
        local fl = floorInv()
        if not pending then return end
        endMove()
        -- the floor held only our things: everything on it comes back
        if fl and sizeOf(fl) > 0 then pcall(CT.takeAll, p, fl, p:getInventory()) end
    end },
    { 50, function()
        local fl = floorInv()
        say("floor after taking it all back: " .. tostring(fl and sizeOf(fl)))
        if fl and sizeOf(fl) ~= 0 then say("FAIL the floor still holds " .. sizeOf(fl)) end
    end },
    -- 5. put everything back
    { 10, function()
        for _, it in ipairs(given) do pcall(function() if it:getContainer() then it:getContainer():Remove(it) end end) end
        local inv = p:getInventory()
        local extra = {}
        for i = 0, (snapped and inv:getItems():size() or 0) - 1 do local it = inv:getItems():get(i); if not before[it] then extra[#extra + 1] = it end end
        for _, it in ipairs(extra) do pcall(function() inv:Remove(it) end) end
        for it, where in pairs(before) do
            if where == "bed" and it:getContainer() ~= bed then pcall(function() if it:getContainer() then it:getContainer():Remove(it) end; bed:AddItem(it) end) end
            if where == "bag" and it:getContainer() ~= inv then pcall(function() if it:getContainer() then it:getContainer():Remove(it) end; inv:AddItem(it) end) end
        end
        p:setTimedActionInstantCheat(false)
        if openedPair and ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
        for _, v in ipairs(spawned) do pcall(function() v:permanentlyRemove() end) end
        spawned = {}
        if snapped then say(string.format("restored: bag %d things, bed %d things", sizeOf(p:getInventory()), sizeOf(bed))) end
        say("DONE" .. (dead and " (aborted)" or ""))
    end },
}

si, wait = 1, 0
local function t()
    local s = steps[si]
    if not s then Events.OnTick.Remove(t); return end
    wait = wait + 1
    if wait >= s[1] and queueEmpty() then
        local ok, e = pcall(s[2])
        if not ok then say("ERR step " .. si .. " " .. tostring(e)) end
        si, wait = si + 1, 0
    end
end
Events.OnTick.Add(t)
say("start")
