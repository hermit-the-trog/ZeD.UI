-- ZeDUI/tools/qa/mp_b6a_stats.lua  (Nov 6 2026, QA; beta 6a, a real second player): on the admin client, beside bob: Check stats on his Player card opens the game's stats window. grep "ZEDQA ast".
local function say(s) print("ZEDQA ast " .. tostring(s)) end
local function pass(n, ok, d) say((ok and "PASS " or "FAIL ") .. n .. (d ~= nil and (" (" .. tostring(d) .. ")") or "")) end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local C = ZeD.Claims
local WWm = ZeD_WorldWindow
local function W() return WWm.getWindow() end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b6a_stats_" .. n .. ".png") end) end
add(500, function() SendCommandToServer('/teleportto "bob"') end)
add(5000, function() say("bob seen: " .. tostring(getPlayerFromUsername("bob") ~= nil)); WWm.openTab(0, "admin") end)
add(2000, function() ZeD.AdminCards.openPlayer(W(), W()._adminTab, "bob") end)
add(2500, function()
    shot("1_card")
    local D = ZeD.TicketCards._D
    say("stats entry: " .. tostring(D and D.statsWindow ~= nil))
    D.statsWindow(W(), "bob")
end)
add(2500, function()
    pass("the game's stats window is open", ISPlayerStatsUI.instance ~= nil)
    shot("2_stats")
    pcall(function() ISPlayerStatsUI.instance:close() end)
end)
add(1000, function() WWm.openTab(0, "loot") end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
    if i > #plan then say("DONE") end
end
Events.OnTick.Add(drive)
