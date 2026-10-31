-- ZeDUI/tools/qa/zedqa_capacity.lua  (Oct 29 2026)
-- With Container Capacity Indicator on (capacity_mods.txt): its fill bar on the
-- container strips' buttons (ModSupport/ContainerCapacityIndicator.lua through
-- ZeD_CharacterWindow.addStripDecorator / ZeD_WorldWindow.addStripDecorator,
-- StripDecorators.lua). With the mod off it says so and ends.
--   1. the worn bag (a school bag is worn for the run when nothing is worn on the
--      back) is filled to about 80 percent and the pickup's truck bed to about
--      20 percent (planks, beans, nails; the weights are read back);
--   2. each strip stamps the decorator for its buttons (win._stripDecorated): the
--      bag in the Character window's, the bed in the World window's, and the main
--      inventory and the floor too;
--   3. the support's own stamp (S.last) agrees with an independent
--      getCapacityWeight / getEffectiveCapacity, the bands are the mod's (amber
--      from 75 percent, green below), and the bars' lit segments follow the
--      fullness (Oct 30 2026: ten, whole tenths only; the bag seven or eight, the
--      bed one or two); captured as zqa_cci_strip.png;
--   4. the bag goes to about 97 percent: the red band (zqa_cci_strip_full.png);
--   5. everything is put back: what was added removed, a borrowed bag taken off,
--      a spawned pickup removed, the window pair as found.
-- Copy to Zomboid/Lua/zedqa.lua, bump zedqa.go; grep "ZEDQA cci"; ends
-- "ZEDQA cci DONE".
local p = getPlayer()
local pn = p:getPlayerNum()
local S = ZeD.ModSupport and ZeD.ModSupport.ContainerCapacityIndicator
local ID = "ContainerCapacityIndicator"
local function say(s) print("ZEDQA cci " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_cci_" .. n .. ".png") end) end
local function cw() return ZeD_CharacterWindow.getWindow() end
local function ww() return ZeD_WorldWindow.getWindow() end
local function queueEmpty()
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    return not q or not q.queue or #q.queue == 0
end
-- the mod's own number, worked out here a second time (not through the support file)
local function ratioOf(inv)
    local cap = inv:getEffectiveCapacity(p)
    if not cap or cap <= 0 then return nil end
    return math.max(0, math.min(inv:getCapacityWeight() / cap, 1))
end
local function fmt(r) return r and string.format("%.3f", r) or "nil" end
local function check(ok, msg) if not ok then say("FAIL " .. msg) end; return ok end
local function bandFor(r) return r >= 0.95 and "danger" or (r >= 0.75 and "warning" or "positive") end

-- the worn bag (the biggest), as in zedqa_nested.lua
local function wornBag()
    local best, cap = nil, -1
    local worn = p:getWornItems()
    for i = 0, worn:size() - 1 do
        local it = worn:get(i):getItem()
        if it and it:IsInventoryContainer() then
            local c = it:getInventory():getCapacity()
            if c > cap then best, cap = it, c end
        end
    end
    return best
end
local function borrowBag()
    local it = p:getInventory():AddItem("Base.Bag_Schoolbag")
    if not it then return nil end
    local loc = nil
    pcall(function() local ce = it:canBeEquipped(); if ce and ce ~= "" then loc = ce else loc = it:getBodyLocation() end end)
    local ok = loc and pcall(function() p:setWornItem(loc, it) end)
    if ok and p:isEquipped(it) then return it end
    p:getInventory():Remove(it)
    return nil
end

-- the pickup: the nearest of the loaded cell, else one spawned beside the character (removed at the end)
local spawned = {}
local function nearPickup()
    local best, bd
    local it = getCell():getVehicles():iterator()
    while it:hasNext() do
        local v = it:next()
        if v:getScriptName() == "Base.PickUpTruck" then
            local d = v:DistTo(p)
            if not bd or d < bd then best, bd = v, d end
        end
    end
    return best
end
local function spawnPickup()
    local sq = getCell():getGridSquare(math.floor(p:getX()) - 4, math.floor(p:getY()), math.floor(p:getZ()))
    if not sq then return nil end
    local ok, v = pcall(addVehicleDebug, "Base.PickUpTruck", IsoDirections.N, nil, sq)
    if ok and v then spawned[#spawned + 1] = v; return v end
    return nil
end

local given = {}   -- every item the run added
-- adds planks, then beans, then nails to `inv` while the ratio stays at or under `target`
-- (an item that would pass it is taken straight back out), so the ratio lands just under
local function fillTo(inv, target)
    for _, ft in ipairs({ "Base.Plank", "Base.TinnedBeans", "Base.Nails" }) do
        for _ = 1, 150 do
            local it = inv:AddItem(ft)
            if not it then break end
            local r = ratioOf(inv)
            if r and r > target then inv:Remove(it); break end
            given[#given + 1] = it
        end
    end
    return ratioOf(inv)
end

-- the segments the library's bar lights at `ratio` (Oct 30 2026: ten, one per whole tenth; worked
-- out here, not through ZeD.Atoms.fillSegsLit); `w` must hold ten distinct ones
local function litSegs(w, ratio)
    check(w >= ZeD.Atoms.fillBarMinW(), "a bar " .. tostring(w) .. " px wide is too short for ten segments")
    if ratio <= 0 then return 0 end
    if ratio >= 1 then return 10 end
    return math.floor(ratio * 10 + 1e-6)
end

local back, borrowed, pickup, bed, openedPair = nil, nil, nil, nil, false
local steps
local si, wait = 1, 0
local dead = false
local TEARDOWN = 9   -- the first put-back step: an aborted run jumps there
local function abort(msg) say("ERR " .. msg); dead = true; si = TEARDOWN - 1 end

steps = {
    { 1, function()
        if not S then say("mod off: no decorator expected (ModSupport/ContainerCapacityIndicator did not load)"); say("DONE"); si = #steps + 1; return end
        local D = ZeD.StripDecorators
        say("decorators: char " .. #(D and D.char or {}) .. " world " .. #(D and D.world or {}))
        p:setGodMod(true)
        if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn); openedPair = true end
        back = wornBag()
        if not back then
            back = borrowBag(); borrowed = back
            say("nothing worn on the back: a school bag worn for the run " .. tostring(back ~= nil))
        end
        if not back then abort("no worn bag and none could be worn"); return end
        pickup = nearPickup()
        if not pickup then
            pickup = spawnPickup()
            say("no pickup in the loaded cell; spawned one beside the character: " .. tostring(pickup ~= nil))
        end
        if not pickup then abort("no pickup in the loaded cell and the spawn failed") end
    end },
    -- a moment for a spawned pickup to settle, then the character steps onto its bed
    { 20, function()
        local part = pickup:getPartById("TruckBed") or pickup:getPartById("TruckBedOpen")
        local c = part and pickup:getAreaCenter(part:getArea())
        if not c then abort("no pickup truck bed to stand at"); return end
        p:teleportTo(c:getX(), c:getY(), 0)
        bed = part:getItemContainer()
        if not bed then abort("the truck bed has no container") end
    end },
    { 90, function()
        -- the bed in the World window's list?
        local found = false
        for _, c in ipairs(ww() and ww()._containers or {}) do if c.inventory == bed then found = true end end
        if not check(found, "the World window does not list the truck bed") then abort("no bed button to check"); return end
        say("start: bag " .. fmt(ratioOf(back:getInventory())) .. " bed " .. fmt(ratioOf(bed))
            .. " (capacity " .. tostring(back:getInventory():getEffectiveCapacity(p)) .. " / " .. tostring(bed:getEffectiveCapacity(p)) .. ")")
        local rBag = fillTo(back:getInventory(), 0.80)
        local rBed = fillTo(bed, 0.20)
        say("staged: bag " .. fmt(rBag) .. " bed " .. fmt(rBed))
        -- forget any earlier stamps, so a pass below means the strips drew it after the staging
        cw()._stripDecorated = {}
        ww()._stripDecorated = {}
        for k in pairs(S.last) do S.last[k] = nil end
    end },
    -- a few frames for both strips to draw
    { 30, function()
        local cs, ws = cw()._stripDecorated or {}, ww()._stripDecorated or {}
        local bagInv, mainInv = back:getInventory(), p:getInventory()
        local gotBag = cs[bagInv] and cs[bagInv][ID] or false
        local gotMain = cs[mainInv] and cs[mainInv][ID] or false
        local gotBed = ws[bed] and ws[bed][ID] or false
        check(gotBag, "the Character window's strip did not decorate the worn bag")
        check(gotMain, "the Character window's strip did not decorate the main inventory")
        check(gotBed, "the World window's strip did not decorate the truck bed")
        local floor = ZeD_WorldWindow.getFloorContainer and ZeD_WorldWindow.getFloorContainer()
        if floor and ratioOf(floor) then
            check(ws[floor] and ws[floor][ID], "the World window's strip did not decorate the floor")
        end
        say("decorated: bag " .. tostring(gotBag) .. " main " .. tostring(gotMain) .. " bed " .. tostring(gotBed))
        check(ZeD.StripDecorators.errors[ID] == nil, "the decorator threw: " .. tostring(ZeD.StripDecorators.errors[ID]))
    end },
    { 2, function()
        local now = getTimestampMs()
        local lb, ld = S.last[back:getInventory()], S.last[bed]
        if not (check(lb, "no bar record for the worn bag") and check(ld, "no bar record for the truck bed")) then return end
        local nb, nd = ratioOf(back:getInventory()), ratioOf(bed)
        check(math.abs(lb.ratio - nb) < 0.01, "bag ratio " .. fmt(lb.ratio) .. " is not the container's " .. fmt(nb))
        check(math.abs(ld.ratio - nd) < 0.01, "bed ratio " .. fmt(ld.ratio) .. " is not the container's " .. fmt(nd))
        check(now - lb.at < 1000 and now - ld.at < 1000, "a bar record is stale (the strip stopped drawing it)")
        check(lb.band == bandFor(nb), "bag band " .. lb.band .. " at " .. fmt(nb))
        check(ld.band == bandFor(nd), "bed band " .. ld.band .. " at " .. fmt(nd))
        local gBag, gBed = litSegs(lb.barW, lb.ratio), litSegs(ld.barW, ld.ratio)
        say(string.format("bag %s band %s bar %d lit %d | bed %s band %s bar %d lit %d",
            fmt(lb.ratio), lb.band, lb.barW, gBag, fmt(ld.ratio), ld.band, ld.barW, gBed))
        check(lb.band == "warning", "the 80 percent bag should be in the amber band, is " .. lb.band)
        check(ld.band == "positive", "the 20 percent bed should be in the green band, is " .. ld.band)
        check(gBag > gBed, "the fuller bar does not light more segments")
        check(gBag == ZeD.Atoms.fillSegsLit(lb.ratio) and gBed == ZeD.Atoms.fillSegsLit(ld.ratio),
            string.format("the library lights %d and %d, not %d and %d", ZeD.Atoms.fillSegsLit(lb.ratio), ZeD.Atoms.fillSegsLit(ld.ratio), gBag, gBed))
        -- (the bag about 80 percent, the bed about 20: seven or eight segments, one or two)
        check(gBag >= 7 and gBag <= 8 and gBed >= 1 and gBed <= 2,
            string.format("segments do not follow the fullness (lit %d vs %d)", gBag, gBed))
        shot("strip")
    end },
    -- the bag to nearly full: the red band
    { 5, function() say("bag filled on to " .. fmt(fillTo(back:getInventory(), 0.97))) end },
    { 30, function()
        local lb = S.last[back:getInventory()]
        local nb = ratioOf(back:getInventory())
        if not check(lb, "no bar record for the worn bag after the second fill") then return end
        check(math.abs(lb.ratio - nb) < 0.01, "bag ratio " .. fmt(lb.ratio) .. " is not the container's " .. fmt(nb))
        check(lb.band == "danger", "the 97 percent bag should be in the red band, is " .. lb.band)
        say("bag " .. fmt(lb.ratio) .. " band " .. lb.band)
        shot("strip_full")
    end },
    { 2, function() say("checks done") end },
    -- put everything back (TEARDOWN = this step's index)
    { 10, function()
        for _, it in ipairs(given) do pcall(function() if it:getContainer() then it:getContainer():Remove(it) end end) end
        given = {}
        if borrowed then
            pcall(function() p:removeWornItem(borrowed, false) end)
            pcall(function() if borrowed:getContainer() then borrowed:getContainer():Remove(borrowed) end end)
        end
        for _, v in ipairs(spawned) do pcall(function() v:permanentlyRemove() end) end
        spawned = {}
        if openedPair and ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
        say("DONE" .. (dead and " (aborted)" or ""))
    end },
}

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
