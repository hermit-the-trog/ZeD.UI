-- ZeDUI/tools/qa/zedqa_trash_quit.lua  (Oct 16 2026)
-- At the main menu: EMPTY TRASH asks "Quit Project Zomboid?" in the Trash's
-- footer; CANCEL keeps everything; File > Quit from the desktop brings the main
-- window up to ask; then EMPTY TRASH + QUIT closes the game (the run ends there).
-- Copy to Zomboid/Lua/zedqa.lua, bump zedqa.go; grep "ZEDQA tq".
local MM = ZeD.MainMenu
local R = MM.root
local function say(s) print("ZEDQA tq " .. tostring(s)) end
local function shot(n) getCore():TakeFullScreenshot("zqa_tq_" .. n .. ".png") end
local function trash() for _, rv in ipairs(MM.views) do if rv.view == "trash" then return R[rv.field] end end end
local steps, t = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
at(2, function() MM.showView("desktop"); R.icons:open("trash") end)
at(20, function() trash():empty(); say("after EMPTY TRASH: confirm=" .. tostring(trash().confirm) .. " ask=" .. tostring(trash()._ask)) end)
at(35, function() shot("01_trash_asks") end)
at(40, function() trash():setConfirm(false); say("after CANCEL: confirm=" .. tostring(trash().confirm) .. " view=" .. tostring(MM.view)) end)
at(55, function() shot("02_trash_cancelled"); trash():close(); MM.act.askQuit(); say("File > Quit from the desktop: view=" .. tostring(MM.view) .. " main confirm=" .. tostring(R.win.confirm)) end)
at(75, function() shot("03_desktop_quit_asks"); R.win:setConfirm(false) end)
at(85, function() MM.showView("desktop"); R.icons:open("trash") end)
at(100, function() trash():empty() end)
at(110, function() say("pressing QUIT in the Trash"); MM.act.quit() end)
local function tick()
    t = t + 1
    for _, s in ipairs(steps) do if s.n == t then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if t > 130 then Events.OnFETick.Remove(tick) end
end
Events.OnFETick.Add(tick)
say("start")
