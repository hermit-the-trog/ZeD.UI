-- ZeDUI/tools/qa/zedqa_break_edges.lua  (Oct 31 2026, QA; the director: "Try to break things.")
-- Edge cases, each followed by a few frames of drawing (the runner counts the game's own errors):
--   1. 300 different things in the character's bag: list and grid, scrolled to the bottom, every sort
--   2. a 200-letter name on an item: its row and its card
--   3. a broken item (condition 0), a rotten food, a full and an empty water bottle: their cards
--   4. an empty bag on the ground: picked in the World window, its card
--   5. the item whose card is open taken away (removed from the bag) while the card shows
--   6. the bag on the ground whose column is open taken away while the World window shows it
--   7. an action running (reading) while the tabs are walked and a card opens
--   8. the character's bag emptied to nothing: list and grid
-- Everything given is taken away and the character's things put back. Shots zqa_bedg_*.png.
-- grep "ZEDQA bedg".
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local p = getPlayer(); local pn = p:getPlayerNum(); local inv = p:getInventory()
local function say(s) print("ZEDQA bedg " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_bedg_" .. n .. ".png") end) end
local function CW() return CWm.getWindow() end
local function WW() return WWm.getWindow() end
local function tabsOf(strip) local out = {}; for _, z in ipairs((strip and strip._hitZones) or {}) do if type(z.id) == "string" and z.id:sub(1, 4) == "tab:" then out[#out + 1] = z end end; return out end
local function tab(win, stripKey, id) local s = win and win[stripKey]; for _, z in ipairs(tabsOf(s)) do if z.id == "tab:" .. id and win._activeTab ~= id then s:onMouseDown(z.x + 2, z.y + 2) end end end
local function select(item)
    local c = CW(); local cp = c and c._mainContent
    if not cp then return end
    local sel = cp._selectedItems or {}
    for k in pairs(sel) do sel[k] = nil end
    if item then sel[item] = true end
    cp._selectedItems, cp._lastClickedItem = sel, item
    pcall(function() c._updateDrawer(cp) end)
end
local function tripped() local ok, v = pcall(function() return ZeD.Safe.on() end); return ok and v == true end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end end
local function alive(label) check(not tripped() and CWm.isOpen(), label .. ": ZeD still in charge, the windows open") end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local added = {}
local function give(ft) local ok, it = pcall(function() return inv:AddItem(ft) end); if ok and it then added[#added + 1] = it end; return ok and it or nil end
local moved = {}   -- the character's own things set aside for part 8

step(5, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not (CWm.isOpen() and WWm.isOpen()) then CWm.toggleBothPaired(pn) end
    tab(CW(), "_tabStripPanel", "loot"); tab(WW(), "_actionTabStrip", "loot")
end)
-- 1. 300 different things
step(5, function()
    local all = getScriptManager():getAllItems()
    local n = 0
    for i = 0, all:size() - 1 do
        local si = all:get(i)
        local ok, hidden = pcall(function() return si:isHidden() end)
        local ok2, w = pcall(function() return si:getActualWeight() end)
        if ok and not hidden and ok2 and w and w < 0.3 and n < 300 then
            local it = give(si:getFullName())
            if it then n = n + 1 end
        end
        if n >= 300 then break end
    end
    say("given " .. n .. " different things")
end)
step(40, function() shot("300_list") end)
step(5, function()
    local IR = ZeD.InventoryRenderer
    if IR and IR.setGridKey then IR.setGridKey("player", true) end
end)
step(40, function() shot("300_grid") end)
step(5, function()
    local c = CW(); local cp = c and c._mainContent
    for _ = 1, 400 do pcall(function() cp:onMouseWheel(1) end) end
end)
step(30, function() shot("300_grid_bottom") ; local IR = ZeD.InventoryRenderer; if IR and IR.setGridKey then IR.setGridKey("player", false) end end)
step(5, function() local cp = CW()._mainContent; for _ = 1, 400 do pcall(function() cp:onMouseWheel(1) end) end end)
step(30, function() shot("300_list_bottom") end)
for _, key in ipairs({ "name", "cat", "cond", "wt", "name" }) do
    step(10, function()
        local cp = CW()._mainContent
        cp._sortCol = key; cp._sortAsc = not cp._sortAsc
        for _, cs in ipairs(cp._colStates or {}) do cs.sortCol, cs.sortAsc = key, cp._sortAsc end
    end)
end
step(20, function() alive("300 things, list, grid, the bottom, every sort") end)
-- 2. a 200-letter name
step(5, function()
    local it = give("Base.Hammer")
    if it then
        pcall(function() it:setName(string.rep("Extremely long hammer name ", 8)) end)
        pcall(function() it:setCustomName(true) end)
        select(it)
    end
end)
step(40, function() shot("long_name_card"); alive("a 200-letter name: its row and card") end)
-- 3. broken, rotten, full and empty
local odd = {}
step(5, function()
    local a = give("Base.Axe"); if a then pcall(function() a:setCondition(0) end); pcall(function() a:setBroken(true) end); odd[#odd + 1] = a end
    local f = give("Base.Apple"); if f then pcall(function() f:setAge(999) end); odd[#odd + 1] = f end
    local b = give("Base.WaterBottle"); if b then odd[#odd + 1] = b end
    local e = give("Base.WaterBottleEmpty") or give("Base.EmptyWaterBottle"); if e then odd[#odd + 1] = e end
end)
for i = 1, 4 do step(25, function() if odd[i] then select(odd[i]); shot("odd_" .. i) end end) end
step(10, function() select(nil); alive("broken, rotten, full and empty cards") end)
-- 4. an empty bag on the ground, picked in the World window
local groundBag
step(5, function()
    local ok, it = pcall(function() return p:getCurrentSquare():AddWorldInventoryItem("Base.Bag_DuffelBag", 0.5, 0.5, 0) end)
    groundBag = ok and it or nil
end)
step(40, function()
    if groundBag then pcall(function() WWm.selectContainer(groundBag:getInventory(), 120) end) end
end)
step(40, function() shot("empty_bag_ground"); alive("an empty bag on the ground, picked") end)
-- 5. the item whose card is open, taken away while the card shows
local victim
step(5, function() victim = give("Base.Screwdriver"); if victim then select(victim) end end)
step(30, function() if victim then pcall(function() inv:Remove(victim) end) end end)
step(40, function() shot("card_item_gone"); alive("the open card's item taken away") end)
-- 6. the ground bag whose column shows, taken away
step(5, function()
    if groundBag then
        local wo = groundBag:getWorldItem()
        if wo then pcall(function() wo:getSquare():transmitRemoveItemFromSquare(wo); wo:removeFromWorld(); wo:removeFromSquare() end) end
    end
end)
step(60, function() shot("ground_bag_gone"); alive("the World window's open bag taken away") end)
-- 7. an action running while the tabs are walked and a card opens
step(5, function()
    local book = give("Base.Book")
    if book then pcall(function() ISTimedActionQueue.add(ISReadABook:new(p, book, 300)) end) end
end)
for _, id in ipairs({ "equip", "health", "thermal", "identity", "journal", "skills", "loot" }) do step(8, function() tab(CW(), "_tabStripPanel", id) end) end
for _, id in ipairs({ "craft", "build", "furniture", "maps", "forage", "loot" }) do step(8, function() tab(WW(), "_actionTabStrip", id) end) end
step(5, function() if odd[1] then select(odd[1]) end end)
step(30, function() shot("reading_card"); select(nil); pcall(function() ISTimedActionQueue.clear(p) end); alive("tabs and a card while reading") end)
-- 8. the bag emptied to nothing
step(5, function()
    local items = inv:getItems()
    for i = items:size() - 1, 0, -1 do
        local it = items:get(i)
        if not (p:isEquipped(it) or p:isEquippedClothing(it)) then moved[#moved + 1] = it; pcall(function() inv:Remove(it) end) end
    end
    say("set aside " .. #moved)
end)
step(40, function() shot("empty_list"); local IR = ZeD.InventoryRenderer; if IR and IR.setGridKey then IR.setGridKey("player", true) end end)
step(40, function() shot("empty_grid"); local IR = ZeD.InventoryRenderer; if IR and IR.setGridKey then IR.setGridKey("player", false) end; alive("an empty bag, list and grid") end)
-- put back: the character's own things back, everything given taken away
step(5, function()
    local given = {}
    for _, it in ipairs(added) do given[it] = true end
    local back = 0
    for _, it in ipairs(moved) do if not given[it] then pcall(function() inv:AddItem(it) end); back = back + 1 end end
    for _, it in ipairs(added) do local c = it:getContainer(); if c then pcall(function() c:Remove(it) end) end end
    say("put back " .. back .. ", taken away " .. #added)
    select(nil)
end)
step(20, function() say(fails == 0 and "all checks passed" or (fails .. " failed")); say("DONE") end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
