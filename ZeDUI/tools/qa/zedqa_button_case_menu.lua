-- ZeDUI/tools/qa/zedqa_button_case_menu.lua  (Oct 16 2026)
-- At the main menu: button words in sentence case. Prints ZeD.btnCase on a set
-- of labels (caps, initials, digits, the degree sign, mixed case left alone),
-- then shoots the main window, Load, New Game, Mods, Options, Server settings,
-- Host, Join and the Trash (with its quit question).
-- Copy to Zomboid/Lua/zedqa.lua, bump zedqa.go; grep "ZEDQA bc";
-- captures Screenshots/zqa_bc_*.png.
local MM = ZeD.MainMenu
local R = MM.root
local function say(s) print("ZEDQA bc " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_bc_" .. n .. ".png") end) end
local function viewWin(name) for _, rv in ipairs(MM.views) do if rv.view == name then return R[rv.field] end end end
local steps, t = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end

at(2, function()
    local cases = { "LOAD GAME", "NEW...", "MODS (12)", "OK", "EJECT CD", "+ CREATE ZONE", "TAKE ALL", "1/4", "ALL",
        string.char(176) .. "F", "USE ZED OS", "4WD ON", "SAME TYPE, ALL NEARBY", "q", "Q", "SHIFT", "Insert Propane Tank", "X" }
    for _, c in ipairs(cases) do say(string.format("%-24s -> %s", c, ZeD.btnCase(c))) end
end)
local views = { "main", "load", "newgame", "mods", "options", "srvset", "host", "join" }
for i, v in ipairs(views) do
    -- Mods opens the way its buttons open it (vanilla's model reloads its mods first; a bare showView lists none)
    at(10 + (i - 1) * 40, function() if v == "mods" then MM.act.mods() else MM.showView(v) end; say("view " .. tostring(MM.view)) end)
    at(10 + (i - 1) * 40 + 30, function() shot(string.format("%02d_%s", i, v)) end)
end
local tz = 10 + #views * 40
at(tz, function() MM.showView("desktop"); R.icons:open("trash") end)
at(tz + 15, function() local tw = viewWin("trash"); if tw then tw:empty() end end)
at(tz + 35, function() shot("09_trash_ask") end)
at(tz + 40, function() local tw = viewWin("trash"); if tw then tw:setConfirm(false); tw:close() end; MM.showView("main"); say("DONE") end)

local function tick()
    t = t + 1
    for _, s in ipairs(steps) do if s.n == t then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if t > tz + 60 then Events.OnFETick.Remove(tick) end
end
Events.OnFETick.Add(tick)
say("start")
