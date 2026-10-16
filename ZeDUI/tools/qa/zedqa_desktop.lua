-- ZeDUI/tools/qa/zedqa_desktop.lua  (Oct 15 2026)
-- The ZeD OS desktop at the main menu (QA bridge at the main menu: copy to
-- Zomboid/Lua/zedqa.lua, bump zedqa.go; grep "ZEDQA DK"). Closes the Project
-- Zomboid window through its close box's handler, checks the desktop view and
-- the icons, opens the Trash, tries EMPTY TRASH, closes it, then walks the icons
-- with the D-pad and opens Project Zomboid with A. Screenshots each step.
local MM = ZeD.MainMenu
local R = MM.root
local function say(s) print("ZEDQA DK " .. tostring(s)) end
local function shot(n) getCore():TakeFullScreenshot("zqa_dk_" .. n .. ".png") end
local function vwin(view) for _, rv in ipairs(MM.views) do if rv.view == view then return R[rv.field] end end end
local steps, t = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end

at(2, function() MM.showView("main"); say("main window at " .. R.win:getX() .. "," .. R.win:getY() .. " " .. R.win:getWidth() .. "x" .. R.win:getHeight()) end)
at(20, function() shot("01_main_with_icons") end)
at(25, function() R.win:close(); say("after close: view=" .. tostring(MM.view) .. " main visible=" .. tostring(R.win:isVisible()) .. " active=" .. tostring(MM.activeWindow() == R.icons)) end)
at(45, function()
    for _, c in ipairs(R.icons._cells or {}) do say(string.format("icon %s at %d,%d %dx%d", c.item.id, c.x, c.y, c.w, c.h)) end
    shot("02_desktop")
end)
at(50, function() R.icons:click("trash") end)
at(60, function() say("selected=" .. tostring(R.icons.focusId)); shot("03_trash_selected") end)
at(65, function() R.icons:click("trash"); say("after second click: view=" .. tostring(MM.view)) end)
at(85, function() shot("04_trash_window") end)
at(90, function() vwin("trash"):empty() end)
at(105, function() say("note=" .. tostring(vwin("trash").note)); shot("05_trash_empty") end)
at(110, function() vwin("trash"):close(); say("trash closed: view=" .. tostring(MM.view)) end)
at(125, function() MM.forceGamepad = true; R.icons.focusId = "pz"; R.icons:joyDir("down"); say("down -> " .. tostring(R.icons.focusId)); R.icons:joyDir("down"); say("down -> " .. tostring(R.icons.focusId)) end)
at(140, function() shot("06_desktop_pad") end)
at(145, function() R.icons.focusId = "pz"; R.icons:joyA(); say("A on Project Zomboid: view=" .. tostring(MM.view)) end)
at(160, function() MM.forceGamepad = false; shot("07_back_to_main"); say("DONE") end)

local function tick()
    t = t + 1
    for _, s in ipairs(steps) do if s.n == t then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if t > 170 then Events.OnFETick.Remove(tick) end
end
Events.OnFETick.Add(tick)
say("start")
