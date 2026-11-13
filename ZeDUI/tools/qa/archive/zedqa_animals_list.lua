-- ZeDUI/tools/qa/zedqa_animals_list.lua  (Nov 5 2026, QA; after 4ec5b4f4, the poller reads cell:getAnimals()): after
-- zedqa_animals.lua built the hen house, the poller's cache against a count by the old walk of the squares (75 around the
-- player, the same floor), the time of one refresh, and the Animals tab showing. Picture zqa_anl_tab.png. grep "ZEDQA anl".
local function say(s) print("ZEDQA anl " .. tostring(s)) end
local p = getPlayer()
local AP = ZeD.AnimalsAlertPoller
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
add(4000, function()
    local cell, sq = getCell(), p:getCurrentSquare()
    local n, wild = 0, 0
    local s0 = getTimestampMs()
    for x = sq:getX() - 75, sq:getX() + 75 do for y = sq:getY() - 75, sq:getY() + 75 do
        local gs = cell:getGridSquare(x, y, sq:getZ())
        if gs then
            local m = gs:getMovingObjects()
            for k = 0, m:size() - 1 do if instanceof(m:get(k), "IsoAnimal") then n = n + 1 end end
        end
    end end
    say("the old walk: " .. n .. " animals in " .. (getTimestampMs() - s0) .. " ms")
    local s1 = getTimestampMs()
    AP.refreshCache()
    local d = getTimestampMs() - s1
    local all = AP.getAllAnimals()
    say("the poller: " .. #all .. " animals, one refresh " .. d .. " ms, zones " .. #AP.getZoneList() .. ", alerts " .. #AP.getAlerts())
    say((#all == n and "PASS" or "CHECK") .. " the poller's count against the walk")
    say((d <= 8 and "PASS" or "FAIL") .. " a refresh stays under 8 ms")
    local names = {}
    for sp, c in pairs(AP.getTotals().speciesCounts or {}) do names[#names + 1] = tostring(sp) .. " x" .. tostring(c) end
    say("species: " .. table.concat(names, ", "))
    if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end
end)
add(2000, function()
    local w = ZeD_WorldWindow.getWindow()
    w._activeTab = "animals"; w._drawerMode = "tab"; w._drawerOpen = true
end)
add(2500, function()
    pcall(function() getCore():TakeFullScreenshot("zqa_anl_tab.png") end)
    ZeD_CharacterWindow.toggleBothPaired(0)
    say("DONE")
end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)); if i > #plan then say("DONE") end end
end
Events.OnTick.Add(drive)
