-- ZeDUI/tools/qa/zedqa_headers_lang.lua  (Nov 5 2026, QA; 4ec5b4f4): the list headings at the right of their columns with
-- long words: the test language (every word bracketed), Condition on, then back. Sorted by weight so the mark shows.
-- Pictures zqa_hdl_normal.png, zqa_hdl_test.png. grep "ZEDQA hdl".
local function say(s) print("ZEDQA hdl " .. tostring(s)) end
local opt = ZeD.Settings.testLanguageOption
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
add(300, function()
    if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end
end)
add(2000, function()
    for _, w in ipairs({ ZeD_CharacterWindow.getWindow(), ZeD_WorldWindow.getWindow() }) do w._activeTab = "loot"; w._drawerMode = "tab"; w._drawerOpen = true end
end)
add(1500, function() pcall(function() getCore():TakeFullScreenshot("zqa_hdl_normal.png") end); opt:setValue(2) end)
add(1800, function()
    say("test language on: " .. tostring(ZeD.trTestOn()) .. ", Weight reads " .. tostring(ZeD.tr("UI_ZeD_Inv_ColWt")) .. ", Condition reads " .. tostring(ZeD.tr("UI_ZeD_Inv_ColCond")))
    pcall(function() getCore():TakeFullScreenshot("zqa_hdl_test.png") end)
    opt:setValue(1)
    pcall(function() PZAPI.ModOptions:save() end)
end)
add(1200, function() ZeD_CharacterWindow.toggleBothPaired(0); say("DONE") end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)); if i > #plan then say("DONE") end end
end
Events.OnTick.Add(drive)
