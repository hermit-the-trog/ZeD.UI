-- ZeDUI/tools/qa/zedqa_mods_open.lua  (Oct 16 2026)
-- At the main menu: the Mods screen opened the way its buttons open it
-- (MM.act.mods -> MM.openMods: vanilla's model reloads its mods first) shows
-- the mods; opened bare (MM.showView("mods"), what earlier QA scripts did) it
-- showed "0 of 0 on". Logs the counts both ways and shoots the real one, then
-- the main window (its "Sandbox | map" line, the pipe separator).
-- Copy to Zomboid/Lua/zedqa.lua, bump zedqa.go; grep "ZEDQA mo".
local MM = ZeD.MainMenu
local R = MM.root
local function say(s) print("ZEDQA mo " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_mo_" .. n .. ".png") end) end
local steps, t = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function counts(tag)
    local w = R.modsWin
    local all, on = w:counts()
    w._cnt = nil
    all, on = w:counts()
    say(string.format("%s: view %s, %d mods, %d on", tag, tostring(MM.view), all, on))
end
at(2, function() MM.showView("main"); shot("01_main") end)
at(10, function() MM.showView("mods") end)
at(30, function() counts("bare showView") end)
at(35, function() MM.showView("main") end)
at(45, function() say("delay " .. tostring(MainScreen and MainScreen.instance and MainScreen.instance.delay)); MM.act.mods() end)
at(75, function() counts("through the button"); shot("02_mods") end)
at(80, function() MM.showView("main"); say("DONE") end)
local function tick()
    t = t + 1
    for _, s in ipairs(steps) do if s.n == t then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if t > 90 then Events.OnFETick.Remove(tick) end
end
Events.OnFETick.Add(tick)
say("start")
