-- ZeDUI/tools/qa/zedqa_nested.lua  (Oct 29 2026)
-- With [B42] Nested Containers on (nested_mods.txt): a bag carried inside a worn
-- bag gets its own button and column in the Character window's container strip
-- (ModSupport/nm_nested_containers.lua through ZeD_CharacterWindow.addContainerProvider,
-- ExtraContainers.lua). With the mod off it says so and ends.
--   1. a satchel holding two things (nails, a bandage) goes into the worn backpack
--      (a school bag is worn for the run when nothing is worn on the back);
--   2. the strip lists the satchel: its name, its item count (2), right after the
--      backpack; the World window does not list it (it is on you);
--   3. the satchel's strip button is clicked (the strip's own press and release,
--      on the Loot tab: a column of its own), the column shows the satchel;
--      captured as zqa_nc_strip.png;
--   4. the nails move out to the main inventory through ZeD's own transfer
--      (ZeD.ContainerControls.moveItems, what the column's menus and buttons use):
--      the satchel then holds 1, the main inventory one more;
--   5. everything is put back: the column closed, the satchel and what it held
--      removed, a borrowed school bag taken off, the tab and the window pair as found.
-- Timed actions are instant for the run. Copy to Zomboid/Lua/zedqa.lua, bump
-- zedqa.go; grep "ZEDQA nc"; ends "ZEDQA nc DONE".
local p = getPlayer()
local pn = p:getPlayerNum()
local CT = ZeD.ContainerControls
local NC = ZeD.ModSupport and ZeD.ModSupport.nm_nested_containers
local function say(s) print("ZEDQA nc " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_nc_" .. n .. ".png") end) end
local function cw() return ZeD_CharacterWindow.getWindow() end
local function ww() return ZeD_WorldWindow.getWindow() end
local function sizeOf(inv) local it = inv and inv:getItems(); return it and it:size() or -1 end
local function queueEmpty()
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    return not q or not q.queue or #q.queue == 0
end

local back, borrowed, satchel, satInv, nails = nil, nil, nil, nil, nil
local mainBefore, mainStart, backStart = -1, -1, -1
local openedPair, oldTab, dead = false, nil, false

-- where an inventory sits in a window's list (index or nil)
local function indexIn(win, inv)
    for i, c in ipairs(win and win._containers or {}) do
        if c.inventory == inv then return i end
    end
    return nil
end
-- is the inventory one of the Loot tab's columns?
local function colOn(win, inv)
    local i = indexIn(win, inv)
    for _, j in ipairs(win and win._mcSelected or {}) do if j == i then return true end end
    return false
end
-- the Character window's tab, clicked on its tab strip as a press does
local function toTab(id)
    local w = cw()
    local s = w and w._tabStripPanel
    if not s or w._activeTab == id then return end
    for _, z in ipairs(s._hitZones or {}) do
        if z.id == "tab:" .. id then s:onMouseDown(z.x + 2, z.y + 2); return end
    end
end
-- clicks a container's strip button (press, then release where it was pressed)
local function clickStrip(inv)
    local w = cw()
    local s = w and w._containerStrip
    local i = indexIn(w, inv)
    if not (s and i) then return false end
    for _, z in ipairs(s._hitZones or {}) do
        if z.id == "cnt:" .. i then
            s:onMouseDown(z.x + 2, z.y + 2)
            s:onMouseUp(z.x + 2, z.y + 2)
            return true
        end
    end
    return false
end
-- the strip's list, by name and item count, in its order
local function stripText()
    local t = {}
    for i, c in ipairs(cw()._containers or {}) do
        t[#t + 1] = i .. "." .. tostring(c.name) .. "(" .. sizeOf(c.inventory) .. ")" .. (c.provider and "*" or "")
    end
    return table.concat(t, " ")
end
-- the biggest bag worn (a backpack rather than a fanny pack; worn, not held)
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
-- wears a school bag for the run (the gallery's way: its equip slot, if free)
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

local steps, si, wait
local TEARDOWN = 8   -- the first put-back step: an aborted run jumps there
local function abort(msg) say("ERR " .. msg); dead = true; si = TEARDOWN - 1 end

steps = {
    { 1, function()
        if not NC then say("mod off: no nested bags expected (ModSupport/nm_nested_containers did not load)"); say("DONE"); si = #steps + 1; return end
        local X = ZeD.ExtraContainers
        say("providers: char " .. #(X and X.char or {}) .. " world " .. #(X and X.world or {})
            .. " | mod options: depth " .. tostring(NC.option("nestedDepth")) .. " player nesting " .. tostring(NC.option("nesting_Player"))
            .. " filter " .. tostring(NC.option("playerFilter")) .. " loot nesting " .. tostring(NC.option("nesting_Loot")))
        if not NC.option("nesting_Player") or tonumber(NC.option("playerFilter")) == 2 then
            say("note: the mod's options leave bags inside worn bags out; the satchel should NOT show")
        end
        p:setGodMod(true)
        p:setTimedActionInstantCheat(true)
        if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn); openedPair = true end
        mainStart = sizeOf(p:getInventory())
        back = wornBag()
        if back then backStart = sizeOf(back:getInventory()) end
        if not back then
            back = borrowBag(); borrowed = back
            say("nothing worn on the back: a school bag worn for the run " .. tostring(back ~= nil))
        end
        if not back then abort("no worn bag and none could be worn") end
    end },
    { 10, function()
        oldTab = cw()._activeTab
        toTab("loot")
        -- 1. the satchel with two things, into the worn bag
        satchel = back:getInventory():AddItem("Base.Bag_Satchel")
        if not (satchel and satchel:IsInventoryContainer()) then abort("no satchel"); return end
        satInv = satchel:getInventory()
        nails = satInv:AddItem("Base.Nails")
        satInv:AddItem("Base.Bandage")
        say("worn bag " .. tostring(back:getName()) .. " holds " .. sizeOf(back:getInventory()) .. " | satchel holds " .. sizeOf(satInv)
            .. " | tab " .. tostring(oldTab) .. " -> " .. tostring(cw()._activeTab))
    end },
    -- 2. the strip lists it (the strip rebuilds its list every 30 frames)
    { 60, function()
        say("strip: " .. stripText())
        local w = cw()
        local i, bi = indexIn(w, satInv), indexIn(w, back:getInventory())
        local e = i and w._containers[i]
        if not e then say("FAIL the satchel has no button in the Character window's strip"); return end
        say(string.format("satchel at %d (worn bag at %s): name '%s', %d items, provider %s, parent %s",
            i, tostring(bi), tostring(e.name), sizeOf(e.inventory), tostring(e.provider), tostring(e.parentItem and e.parentItem:getName())))
        if e.name ~= satchel:getName() then say("FAIL the name is not the satchel's") end
        if sizeOf(e.inventory) ~= 2 then say("FAIL the item count is not 2") end
        -- it follows the worn bag: between the two only other bags carried in it (provided entries)
        local follows = bi ~= nil and i > bi
        for k = (bi or i) + 1, i - 1 do if not w._containers[k].provider then follows = false end end
        if not follows then say("FAIL the satchel does not follow the worn bag") end
        if indexIn(ww(), satInv) then say("FAIL the World window lists a bag on the character") end
        if e.name == satchel:getName() and sizeOf(e.inventory) == 2 then say("PASS the strip lists the satchel") end
    end },
    -- 3. open it: a click on its strip button
    { 5, function()
        if not indexIn(cw(), satInv) then return end
        local clicked = clickStrip(satInv)
        if not clicked then
            say("no hit zone for the satchel's button (scrolled out?): opened through ZeD_CharacterWindow.toggleColumn")
            ZeD_CharacterWindow.toggleColumn(satInv)
        end
    end },
    { 30, function()
        local w = cw()
        local content = w._mainContent
        local col = nil
        for k, cs in ipairs(content and content._colStates or {}) do
            if cs.inventory == satInv then col = k end
        end
        say("satchel column open " .. tostring(colOn(w, satInv)) .. " | column " .. tostring(col)
            .. " of " .. #(content and content._colStates or {}) .. " | columns " .. tostring(#(w._mcSelected or {})))
        if colOn(w, satInv) and col then say("PASS the satchel opens as a column") else say("FAIL the satchel's column did not open") end
        shot("strip")
    end },
    -- 4. one thing out through ZeD's transfer
    { 5, function()
        if not (nails and nails:getContainer() == satInv) then say("FAIL the nails are not in the satchel"); return end
        mainBefore = sizeOf(p:getInventory())
        CT.moveItems(p, { nails }, p:getInventory())
    end },
    { 40, function()
        local w = cw()
        local i = indexIn(w, satInv)
        say(string.format("after the move: satchel %d items (button shows %s), main inventory %d -> %d, nails in main %s",
            sizeOf(satInv), tostring(i and sizeOf(w._containers[i].inventory)), mainBefore, sizeOf(p:getInventory()),
            tostring(nails and nails:getContainer() == p:getInventory())))
        if sizeOf(satInv) == 1 and sizeOf(p:getInventory()) == mainBefore + 1 then say("PASS one item moved out")
        else say("FAIL the counts after the move") end
        if not colOn(w, satInv) then say("FAIL the column closed during the move") end
    end },
    -- 5. put everything back
    { 10, function()
        if satInv and colOn(cw(), satInv) then ZeD_CharacterWindow.toggleColumn(satInv) end
    end },
    { 10, function()
        if nails and nails:getContainer() then pcall(function() nails:getContainer():Remove(nails) end) end
        if satchel and satchel:getContainer() then pcall(function() satchel:getContainer():Remove(satchel) end) end
        if borrowed then
            pcall(function() p:removeWornItem(borrowed, false) end)
            pcall(function() if borrowed:getContainer() then borrowed:getContainer():Remove(borrowed) end end)
        end
        p:setTimedActionInstantCheat(false)
    end },
    { 40, function()
        if oldTab then toTab(oldTab) end
        local mainNow = sizeOf(p:getInventory())
        local backNow = (back and not borrowed) and sizeOf(back:getInventory()) or -1
        local listed = satInv ~= nil and indexIn(cw(), satInv) ~= nil
        say(string.format("restored: main inventory %d (was %d), worn bag %d (was %d), satchel still listed %s",
            mainNow, mainStart, backNow, backStart, tostring(listed)))
        if mainNow ~= mainStart or backNow ~= backStart or listed then say("FAIL not everything was put back") end
        if openedPair and ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
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
