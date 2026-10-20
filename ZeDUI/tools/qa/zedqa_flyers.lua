-- ZeDUI/tools/qa/zedqa_flyers.lua  (Oct 19 2026)
-- In game on the ZeD-QA save: the Maps tab marks only flyers the character has
-- read. Counts the read set, shoots the map with none, reads one flyer
-- (addReadPrintMedia), shoots again, then forgets it. zqa_fl_*.png. grep "ZEDQA fl".
local p = getPlayer()
local function say(s) print("ZEDQA fl " .. tostring(s)) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_fl_" .. n .. ".png") end) end
local pick
at(2, function()
    if not (ZeD_CharacterWindow.getWindow() and ZeD_CharacterWindow.getWindow():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end
    ZeD_WorldWindow.openTab(0, "maps")
    say("read pieces: " .. p:getReadPrintMedia():size())
    -- a piece with a location near Muldraugh's middle
    for id, d in pairs(PrintMediaDefinitions.MiscDetails) do
        local l = d.location1 and d.location1[1]
        if l and l.x1 > 10000 and l.x1 < 11500 and l.y1 > 9000 and l.y1 < 11000 then pick = id; break end
    end
    say("piece " .. tostring(pick))
end)
at(60, function()
    local mp = ZeD_WorldWindow.getWindow()._worldMapPanel
    if mp then mp.mapAPI:setZoom(13) end
end)
at(90, function() shot(1) end)
at(100, function() if pick then p:addReadPrintMedia(pick) end; say("read now: " .. p:getReadPrintMedia():size()) end)
at(140, function()
    local d = pick and PrintMediaDefinitions.MiscDetails[pick]
    local l = d and d.location1[1]
    local mp = ZeD_WorldWindow.getWindow()._worldMapPanel
    if mp and l then mp.mapAPI:centerOn((l.x1 + l.x2) / 2, (l.y1 + l.y2) / 2) end
end)
at(170, function() shot(2) end)
at(180, function()
    local ok = pcall(function() p:getReadPrintMedia():remove(pick) end)
    say("forgot " .. tostring(ok) .. " read " .. p:getReadPrintMedia():size())
    local mp = ZeD_WorldWindow.getWindow()._worldMapPanel
    if mp then mp.mapAPI:centerOn(p:getX(), p:getY()) end
    say("DONE")
end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 185 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
