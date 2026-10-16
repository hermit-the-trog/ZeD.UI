-- ZeDUI/tools/qa/zedqa_mod_conflicts.lua  (Oct 16 2026)
-- At the main menu, with the two test mods on (ZeDQA_TestA and ZeDQA_TestB
-- both ship media/lua/client/ZeDQATest/Shared.lua and both define the item
-- Base.ZeDQAWidget): the Mods screen finds both conflicts, tags the rows,
-- lists them on the Conflicts tab and explains them in the detail pane with
-- the fix. Then the real Workshop tab. Shoots each; grep "ZEDQA cf".
local MM = ZeD.MainMenu
local R = MM.root
local MS = ZeD.ModScan
local function say(s) print("ZEDQA cf " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_cf_" .. n .. ".png") end) end
local steps, t = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function w() return R.modsWin end
at(2, function() MM.act.mods() end)
at(40, function()
    say("scan done " .. tostring(MS.res.done) .. " A " .. MS.count("ZeDQA_TestA") .. " B " .. MS.count("ZeDQA_TestB"))
    w().sel = "ZeDQA_TestA"; w().dscroll = 0
end)
at(50, function() shot("01_testA") end)
at(55, function() w().dscroll = 400 end)
at(62, function() shot("02_testA_scrolled") end)
at(66, function() w().filter = "conflicts"; w().scroll = 0; w().sel = "ZeDQA_TestB"; w().dscroll = 0 end)
at(75, function() shot("03_conflicts_tab_B") end)
at(80, function()
    local s = {}
    for _, b in ipairs(w()._specs) do if b.id:sub(1, 3) == "cf:" then s[#s + 1] = b.id .. "=" .. tostring(b.text) end end
    say("conflict buttons on B: " .. table.concat(s, ", "))
    w().filter = "ws"; w().scroll = 0; w().dscroll = 0
end)
at(110, function()
    say("ws subscribed " .. tostring(MS.ws.subscribed) .. " items " .. #MS.ws.order .. " steamOff " .. tostring(MS.ws.steamOff))
    for _, it in ipairs(MS.ws.order) do say("  ws " .. it.id .. " | " .. it.title .. " | " .. it.state .. " | " .. it.updated .. " | " .. it.size .. " | " .. it.children) end
    shot("04_workshop_tab")
end)
at(115, function() w().filter = "all"; say("DONE") end)
local function tick()
    t = t + 1
    for _, s in ipairs(steps) do if s.n == t then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if t > 120 then Events.OnFETick.Remove(tick) end
end
Events.OnFETick.Add(tick)
say("start")
