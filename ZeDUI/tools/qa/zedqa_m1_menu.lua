-- ZeDUI/tools/qa/zedqa_m1_menu.lua  (Nov 7 2026, QA; the next beta's merge 1, a60a0399): the main menu's two fixes.
--   1. the version ZeD's menu shows (MM.zedVersion, the Z note and About) against the mod.info the game loaded
--   2. the Mods screen: ZeD-GUI turned off with its own row takes ZeD picks off with it; turned on again, picks come back.
--      Off again, then Undo changes: both back as the screen opened. With a mod that is not installed on the list, Undo
--      changes and Load after run without an error.
-- Run with zedqa_menu_mods_run.ps1 -ModList m1_menu_mods.txt (ZeD picks on, and a mod id that is not installed).
-- Leaves through Discard changes; the runner puts default.txt back. grep "ZEDQA m1m".
local MM = ZeD.MainMenu
local function say(s) print("ZEDQA m1m " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_m1m_" .. n .. ".png") end) end
local pass, fail = 0, 0
local function check(ok, what) if ok then pass = pass + 1; say("PASS " .. what) else fail = fail + 1; say("FAIL " .. what) end end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function W() return MM.root and MM.root.modsWin end
local function model() return ModSelector.instance.model end
local function jlist(l) local t = {}; if l then for i = 0, l:size() - 1 do t[#t + 1] = l:get(i) end end; return t end
local HELPER = ZeD.ModPicks and ZeD.ModPicks.HELPER or "ZeD_Picks"
local function on(id) local m = model(); local d = m and m.mods[id]; return d ~= nil and d.isActive == true end
local function state() return "ZeD-GUI " .. tostring(on("ZeD_UI")) .. ", picks " .. tostring(on(HELPER)) end

at(2, function()
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    local mi = getModInfoByID("ZeD_UI")
    local file = mi and tostring(mi:getModVersion())
    say("mod.info loaded from " .. tostring(mi and mi:getDir()) .. ": " .. tostring(file) .. "; the menu shows " .. tostring(MM.zedVersion()))
    check(file ~= nil and MM.zedVersion() == file, "the menu's ZeD version is the loaded mod.info's (" .. tostring(MM.zedVersion()) .. ")")
    check(not tostring(MM.zedVersion()):find("1242300k", 1, true), "the menu no longer shows 0.1.1242300k")
end)
at(6, function() shot("00_menu") end)
at(10, function() MM.openMods() end)
at(30, function()
    local w, m = W(), model()
    if w.find and w.find:isFocused() then w.find:unfocus() end
    local act = jlist(getActivatedMods())
    say("activated at start: " .. table.concat(act, ", ") .. "; " .. state())
    say("picks installed " .. tostring(m.mods[HELPER] ~= nil))
    shot("01_open")
end)
-- 2. ZeD-GUI off with its row, picks go with it
at(36, function()
    local w, m = W(), model()
    local d = m.mods["ZeD_UI"]
    local ok, e = pcall(w.toggle, w, d)
    say("ZeD-GUI off: " .. tostring(ok) .. (ok and "" or (" " .. tostring(e))) .. "; " .. state())
    check(not on("ZeD_UI") and not on(HELPER), "ZeD-GUI off takes ZeD picks off with it (" .. state() .. ")")
end)
at(42, function() shot("02_off") end)
at(46, function()
    local w, m = W(), model()
    local ok, e = pcall(w.toggle, w, m.mods["ZeD_UI"])
    say("ZeD-GUI on: " .. tostring(ok) .. (ok and "" or (" " .. tostring(e))) .. "; " .. state())
    check(on("ZeD_UI") and on(HELPER), "ZeD-GUI on again brings ZeD picks back (" .. state() .. ")")
end)
at(52, function() shot("03_on_again") end)
-- a mod that is not installed, named in the load order the screen reads (the list can still name one: a profile, a
-- save's list, a mod removed since), then off again and Undo changes, then Load after
at(56, function()
    local w, m = W(), model()
    local ok, e = pcall(function() m:getActiveMods():setModActive("QA_NotInstalled_Mod", true) end)
    local ids = jlist(m:getActiveMods():getMods())
    say("named a mod that is not installed: " .. tostring(ok) .. (ok and "" or (" " .. tostring(e))) .. "; the list: " .. table.concat(ids, ", "))
    check(table.concat(ids, ","):find("QA_NotInstalled_Mod", 1, true) ~= nil, "the load order names a mod that is not installed")
    pcall(w.toggle, w, m.mods["ZeD_UI"])
    say("off again: " .. state())
    local ok2, e2 = pcall(w.revert, w)
    say("Undo changes: " .. tostring(ok2) .. (ok2 and "" or (" " .. tostring(e2))) .. "; " .. state())
    check(ok2 and on("ZeD_UI") and on(HELPER), "Undo changes runs with that mod named and puts both back as the screen opened (" .. state() .. ")")
end)
at(62, function() shot("04_undo") end)
at(66, function()
    local w, m = W(), model()
    pcall(function() m:getActiveMods():setModActive("QA_NotInstalled_Mod", true) end)
    say("the list names: " .. table.concat(jlist(m:getActiveMods():getMods()), ", "))
    local ok, e = pcall(w.loadAfter, w, HELPER, "ZeD_UI")
    say("Load after: " .. tostring(ok) .. (ok and "" or (" " .. tostring(e))))
    check(ok, "Load after runs without an error with a mod that is not installed named")
    say("order after: " .. table.concat(jlist(m:getActiveMods():getMods()), ", "))
end)
at(72, function()
    local w = W()
    -- (Undo changes again, then Back with nothing changed: the screen closes without a write that reloads the mods)
    pcall(w.revert, w)
    local ok, e = pcall(w.back, w)
    say("leave (Undo changes, Back): " .. tostring(ok) .. (ok and "" or (" " .. tostring(e))) .. "; view " .. tostring(MM.view))
end)
at(90, function()
    say(string.format("view=%s; %d passed, %d failed", tostring(MM.view), pass, fail))
    say("DONE")
end)
local function t()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then fail = fail + 1; say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 100 then Events.OnFETick.Remove(t) end
end
Events.OnFETick.Add(t)
say("start")
