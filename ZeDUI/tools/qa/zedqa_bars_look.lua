-- ZeDUI/tools/qa/zedqa_bars_look.lua  (Oct 30 2026, QA)
-- Punch list 22, the segmented bars, in game: shots of every place with bars (Skills, the Equip list
-- and doll, Health, Thermal, a pen's animal food and water), then the speed: ms per tick with the
-- World window's Ground list empty, with 400 tools on the ground (a condition bar each), and while
-- that list scrolls a step every tick, against the same with the list still. Everything put on the
-- ground and the pen are taken away. Screenshots/zqa_bars_*.png; grep "ZEDQA bars".
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA bars " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_bars_" .. n .. ".png") end) end
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local function CW() return CWm.getWindow() end
local function WW() return WWm.getWindow() end
local function goTab(win, strip, id)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. id and win._activeTab ~= id then strip:onMouseDown(z.x + 2, z.y + 2) end
    end
end
local function charTab(id) local w = CW(); if w then goTab(w, w._tabStripPanel, id) end end
local function worldTab(id) local w = WW(); if w then goTab(w, w._actionTabStrip, id) end end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
-- after n frames, every frame until cond() holds (at most max frames), then fn
local function waitFor(n, max, cond, fn) Q[#Q + 1] = { n = n, fn = fn, cond = cond, max = max } end
local viewWas = ZeD.EquipDoll.view()
local tmp = { items = {} }

step(5, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not (CWm.isOpen() and WWm.isOpen()) then CWm.toggleBothPaired(pn) end
end)
-- the looks
local function look(name, fn, settle)
    step(5, function() pcall(fn) end)
    step(settle or 45, function() shot(name) end)
end
look("skills", function() worldTab("loot"); charTab("skills") end)
look("equip_list", function() ZeD.EquipDoll.setView("list"); charTab("equip") end)
look("equip_doll", function() ZeD.EquipDoll.setView("doll") end)
step(2, function() ZeD.EquipDoll.setView(viewWas) end)
look("health", function() charTab("health") end)
look("thermal", function() charTab("thermal") end)
step(5, function()
    charTab("loot")
    local px, py = math.floor(p:getX()), math.floor(p:getY())
    pcall(function() DesignationZoneAnimal.new("QA Bars Pen", px - 4, py - 4, 0, px + 4, py + 4, true) end)
    pcall(function()
        local breed = AnimalDefinitions.getDef("hen"):getBreeds():get(0)
        tmp.hen = addAnimal(getCell(), px + 2, py - 2, 0, "hen", breed)
        tmp.hen:addToWorld()
    end)
end)
-- (the pen registers a few frames later: wait for it, and for the hen inside it)
waitFor(10, 600, function()
    pcall(function() tmp.zone = DesignationZoneAnimal.getZoneByName("QA Bars Pen") end)
    local inside = false
    pcall(function() inside = tmp.zone and tmp.hen and tmp.zone:getAnimalsConnected():contains(tmp.hen) end)
    return tmp.zone ~= nil and tmp.hen ~= nil and (inside or (tmp.zone.isStillStreamed and tmp.zone:isStillStreamed()))
end, function()
    say("pen " .. tostring(tmp.zone ~= nil) .. ", hen " .. tostring(tmp.hen ~= nil))
end)
step(30, function()
    worldTab("animals")
    local w = WW()
    w._animalsState = w._animalsState or { submode = "ranch" }
    local st = w._animalsState
    st.submode = "ranch"; st.prevView = "overview"; st.view = "zone"; st.zoneName = "QA Bars Pen"
end)
step(60, function() shot("animals_zone") end)
step(5, function()
    local st = WW()._animalsState
    if st then st.view = "overview"; st.zoneName = nil end
    pcall(function() if tmp.hen then tmp.hen:removeFromWorld(); tmp.hen:removeFromSquare() end end)
    pcall(function() if tmp.zone then DesignationZoneAnimal.removeZone(tmp.zone, true) end end)
    worldTab("loot")
end)

-- the speed: 180-tick windows after 30 settle frames (suite_perf's measure)
local M = {}
local function measure(label, each)
    step(1, function() M = { n = 0, label = label, max = 0, last = getTimestampMs() } end)
    for _ = 1, 210 do
        step(1, function()
            local now = getTimestampMs()
            M.n = M.n + 1
            if M.n > 30 then local dt = now - M.last; if dt > M.max then M.max = dt end end
            if M.n == 30 then M.t0 = now end
            M.last = now
            if each then pcall(each) end
        end)
    end
    step(1, function() say(string.format("speed %-28s avg %.2f ms/tick, max %d ms", M.label, (M.last - M.t0) / 180, M.max)) end)
end
step(30, function() worldTab("loot") end)
measure("ground, empty")
-- (400 different kinds, each with a condition bar, so the list has 400 rows: one kind stacks into one row)
local KINDS = {}
pcall(function()
    local all = getScriptManager():getAllItems()
    for i = 0, all:size() - 1 do
        local si = all:get(i)
        local ok, cm = pcall(function() return si:getConditionMax() end)
        if ok and cm and cm > 1 and not si:isHidden() then KINDS[#KINDS + 1] = si:getFullName() end
        if #KINDS >= 400 then break end
    end
end)
step(5, function()
    local sq = p:getCurrentSquare()
    say("kinds with a condition: " .. #KINDS)
    for i = 1, 400 do
        local ok, it = pcall(function() return sq:AddWorldInventoryItem(KINDS[((i - 1) % #KINDS) + 1], ZombRandFloat(0.1, 0.9), ZombRandFloat(0.1, 0.9), 0) end)
        if ok and it then
            pcall(function() it:setCondition(ZombRand(1, it:getConditionMax() + 1)) end)
            tmp.items[#tmp.items + 1] = it
        end
    end
    say("on the ground: " .. #tmp.items .. " things, rows in the Ground list " .. tostring(#((WW()._mainContent or {})._rows or {})))
end)
step(120, function() shot("ground_400") end)
measure("ground, 400 tools, still")
local dir, k = 1, 0
measure("ground, 400 tools, scrolling", function()
    local c = WW()._mainContent
    k = k + 1
    if k % 60 == 0 then dir = -dir end
    c:onMouseWheel(dir)
end)
step(2, function() shot("ground_400_scrolled") end)
step(5, function()
    local n = 0
    for _, it in ipairs(tmp.items) do
        pcall(function()
            local wo = it:getWorldItem()
            if wo then wo:getSquare():transmitRemoveItemFromSquare(wo); wo:removeFromWorld(); wo:removeFromSquare(); n = n + 1 end
        end)
    end
    say("taken away: " .. n)
end)
step(30, function() say("DONE") end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    if s.cond then
        s.left = (s.left or s.max) - 1
        local ok, done = pcall(s.cond)
        if not (ok and done) and s.left > 0 then wait = 1; return end
        if not (ok and done) then say("WARN step " .. qi .. ": waited " .. s.max .. " frames, the condition never held") end
    end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
