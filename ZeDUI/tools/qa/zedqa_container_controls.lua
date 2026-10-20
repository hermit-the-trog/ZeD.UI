-- ZeDUI/tools/qa/zedqa_container_controls.lua  (Oct 16 2026)
-- In game on the ZeD-QA save: the container buttons (ContainerControls.lua).
-- Beside the pickup's truck bed with nails, planks, beans and screws in it and
-- some nails and a plank in the bag (timed actions instant for the run):
--   1. both rows and their buttons, logged and shot;
--   2. the controller on the World window's Same type: the rows it would take
--      are marked, the footer names the button;
--   3. Same type (take), Same type (back), Take all, Transfer all (back),
--      To floor, Take all from the floor, Transfer all (back): counts logged;
--   4. a campfire placed beside you: its own buttons (Light, Add fuel, Take
--      apart), Add fuel opens the fire card on its fuel list, Take apart
--      removes it (vanilla's own action).
-- Everything given is taken back; the bed keeps what it had.
-- Copy to Zomboid/Lua/zedqa.lua, bump zedqa.go; grep "ZEDQA ct";
-- captures Screenshots/zqa_ct_*.png.
local p = getPlayer()
local pn = p:getPlayerNum()
local CT = ZeD.ContainerControls
local function say(s) print("ZEDQA ct " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_ct_" .. n .. ".png") end) end
local pickup, bed, campLua, campInv
local given = {}
local before = {}

local function count(inv, ft)
    local n = 0
    local items = inv and inv:getItems()
    for i = 0, (items and items:size() or 0) - 1 do if items:get(i):getFullType() == ft then n = n + 1 end end
    return n
end
local function sizeOf(inv) local it = inv and inv:getItems(); return it and it:size() or -1 end
local function ww() return ZeD_WorldWindow.getWindow() end
local function wc() return ww()._mainContent end
local function cc() return ZeD_CharacterWindow.getWindow()._mainContent end
local function rowText(content)
    local c = content._cc
    if not c then return "(no row)" end
    local t = {}
    for _, s in ipairs(c.moves or {}) do t[#t + 1] = s.label .. (s.enabled and "" or "(off)") end
    if c.objs and #c.objs > 0 then t[#t + 1] = "|" end
    for _, s in ipairs(c.objs or {}) do t[#t + 1] = s.label .. (s.enabled and "" or "(off)") end
    return table.concat(t, ", ")
end
local function pressLabel(content, label)
    local L = content._cc and content._cc.layout
    for i, r in ipairs(L and L.rects or {}) do
        if r.label == label then CT.press(content, i); return true end
    end
    say("no button " .. label)
    return false
end
local function select(inv)
    local w = ww()
    for i, c in ipairs(w._containers or {}) do
        if c.inventory == inv then w._activeContainer = i; w._viewedContainer = nil; w._mainVisible = false; return true end
    end
    return false
end
local function counts(tag)
    say(string.format("%s: bag nails %d planks %d | bed nails %d planks %d beans %d, %d things | floor %d",
        tag, count(p:getInventory(), "Base.Nails"), count(p:getInventory(), "Base.Plank"),
        count(bed, "Base.Nails"), count(bed, "Base.Plank"), count(bed, "Base.TinnedBeans"), sizeOf(bed),
        sizeOf(ZeD_WorldWindow.getFloorContainer())))
end
local function queueEmpty()
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    return not q or not q.queue or #q.queue == 0
end

-- the pickup: the nearest of the loaded cell, else one spawned beside the character (removed at the end). The
-- character is left wherever the last run ended, so the QA save's own pickup is not always loaded.
local spawned = {}
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
local function removeSpawned()
    for _, v in ipairs(spawned) do pcall(function() v:permanentlyRemove() end) end
    spawned = {}
end
-- (forward declarations: abort jumps the run to its last step, the one that puts everything back)
local steps
local si, wait = 1, 0
local dead = false
local function abort(msg) say("ERR " .. msg); dead = true; si = #steps - 1 end
local openedPair, snapped = false, false

-- the run: each step waits for its minimum ticks and an empty action queue
steps = {
    { 1, function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
        p:setGodMod(true)
        p:setTimedActionInstantCheat(true)
        pickup = nearVehicle(function(v) return v:getScriptName() == "Base.PickUpTruck" end)
        if not pickup then
            pickup = spawnVehicle("Base.PickUpTruck", -4, 0)
            say("no pickup in the loaded cell; spawned one beside the character: " .. tostring(pickup ~= nil))
        end
        say("pickup " .. tostring(pickup ~= nil))
        if not pickup then abort("no pickup in the loaded cell and the spawn failed") end
    end },
    -- (a moment for a spawned pickup to settle before the character steps onto its bed)
    { 20, function()
        local part = pickup:getPartById("TruckBed") or pickup:getPartById("TruckBedOpen")
        local c = part and pickup:getAreaCenter(part:getArea())
        if not c then abort("no pickup truck bed to stand at"); return end
        p:teleportTo(c:getX(), c:getY(), 0)
        -- the pair open, so the World window lists the bed (a script before this one may have shut it)
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
        local function put(inv, ft, n) for _ = 1, n do local it = inv:AddItem(ft); if it then given[#given + 1] = it end end end
        put(bed, "Base.Nails", 3); put(bed, "Base.Plank", 4); put(bed, "Base.TinnedBeans", 2); put(bed, "Base.Screws", 2)
        put(p:getInventory(), "Base.Nails", 2); put(p:getInventory(), "Base.Plank", 1)
    end },
    { 40, function() say("bed selected " .. tostring(select(bed))) end },
    { 40, function()
        say("your row: " .. rowText(cc()))
        say("world row: " .. rowText(wc()))
        counts("start")
        shot("01_rows")
    end },
    -- the controller on the World window's Same type
    { 5, function()
        local F, D = ZeD.Input.Focus, ZeD.Input.Detector
        D.setLockedMode("gamepad")
        F.claimFocus(ww())
        for zi, z in ipairs(ww()._focusRing) do
            if z.zone == "worldCtl" then ww()._focusIdx = zi; z.focusedElementIdx = 2 end
        end
        local el = F.getFocusedElement(ww())
        say("focused " .. tostring(el and el.id) .. " prompt " .. tostring(el and el.promptA))
    end },
    { 30, function()
        local n = 0
        for _ in pairs(wc()._ccMarks or {}) do n = n + 1 end
        say("marked rows (things) " .. n)
        shot("02_pad_same_type")
    end },
    { 5, function() ZeD.Input.Detector.setLockedMode(nil); ZeD.Input.Focus.releaseFocus() end },
    -- the moves
    { 10, function() pressLabel(wc(), "Same type") end },
    { 30, function() counts("after Same type (take)") end },
    { 10, function() pressLabel(cc(), "Same type") end },
    { 30, function() counts("after Same type (back)") end },
    { 10, function() pressLabel(wc(), "Take all") end },
    { 30, function() counts("after Take all"); shot("03_after_take_all") end },
    { 10, function() pressLabel(cc(), "Transfer all") end },
    { 30, function() counts("after Transfer all") end },
    { 10, function() pressLabel(wc(), "To floor") end },
    { 40, function() counts("after To floor") end },
    { 10, function() say("floor selected " .. tostring(select(ZeD_WorldWindow.getFloorContainer()))) end },
    { 30, function() say("floor row: " .. rowText(wc())); shot("04_floor_row"); pressLabel(wc(), "Take all") end },
    { 30, function() counts("after Take all (floor)"); select(bed) end },
    { 30, function() pressLabel(cc(), "Transfer all") end },
    { 30, function() counts("after Transfer all (back to the bed)") end },
    -- a campfire beside you (any left by an earlier run goes first)
    { 10, function()
        for dx = 1, 2 do
            local old = getCell():getGridSquare(math.floor(p:getX()) + dx, math.floor(p:getY()), 0)
            local lo = old and SCampfireSystem.instance:getLuaObjectOnSquare(old)
            if lo then pcall(function() SCampfireSystem.instance:removeCampfire(lo) end) end
        end
        local sq = getCell():getGridSquare(math.floor(p:getX()) + 1, math.floor(p:getY()), 0)
        local ok, lua = pcall(function() return SCampfireSystem.instance:addCampfire(sq) end)
        campLua = ok and lua or nil
        say("campfire placed " .. tostring(campLua ~= nil) .. " " .. tostring(ok or lua))
    end },
    { 90, function()
        for _, c in ipairs(ww()._containers or {}) do
            if c.inventory and c.inventory:getType() == "campfire" then campInv = c.inventory end
        end
        say("campfire container " .. tostring(campInv ~= nil) .. " selected " .. tostring(campInv and select(campInv)))
    end },
    { 30, function() say("campfire row: " .. rowText(wc())); shot("05_campfire_row") end },
    { 5, function() pressLabel(wc(), "Add fuel") end },
    { 30, function()
        local w = ww()
        say("after Add fuel: object card " .. tostring(w._drawerObject ~= nil) .. " jump " .. tostring(w._objectCard and (w._objectCard._fid or w._objectCard._jumpTo)))
        shot("06_add_fuel_card")
    end },
    { 10, function() ZeD_WorldWindow.closeObjectCard(); select(campInv) end },
    { 30, function() pressLabel(wc(), "Take apart") end },
    { 60, function()
        local lua = CCampfireSystem.instance:getLuaObjectOnSquare(getCell():getGridSquare(math.floor(p:getX()) + 1, math.floor(p:getY()), 0))
        say("after Take apart: campfire still there " .. tostring(lua ~= nil))
    end },
    -- put everything back
    { 10, function()
        for _, it in ipairs(given) do pcall(function() if it:getContainer() then it:getContainer():Remove(it) end end) end
        local inv = p:getInventory()
        local extra = {}
        -- (an aborted run took no snapshot of the bag: it has nothing of its own to sort out)
        for i = 0, (snapped and inv:getItems():size() or 0) - 1 do local it = inv:getItems():get(i); if not before[it] then extra[#extra + 1] = it end end
        for _, it in ipairs(extra) do
            if before[it] == nil then pcall(function() inv:Remove(it) end) end
        end
        for it, where in pairs(before) do
            if where == "bed" and it:getContainer() ~= bed then pcall(function() if it:getContainer() then it:getContainer():Remove(it) end; bed:AddItem(it) end) end
            if where == "bag" and it:getContainer() ~= inv then pcall(function() if it:getContainer() then it:getContainer():Remove(it) end; inv:AddItem(it) end) end
        end
        p:setTimedActionInstantCheat(false)
        local csq = getCell():getGridSquare(math.floor(p:getX()) + 1, math.floor(p:getY()), 0)
        local clo = csq and SCampfireSystem.instance:getLuaObjectOnSquare(csq)
        if clo then pcall(function() SCampfireSystem.instance:removeCampfire(clo) end) end
        -- the pair back as it was found
        if openedPair and ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
        if snapped then counts("restored") end
        removeSpawned()
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
