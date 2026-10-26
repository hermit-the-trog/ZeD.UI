-- ZeDUI/tools/qa/zedqa_desktop_uploader.lua  (Oct 25 2026)
-- The Mod Uploader icon on the ZeD OS desktop (director: "an icon on the desktop... Look like a FTP
-- program... named, Mod Uploader"; picked: the Mods folder with an up arrow). At the main menu:
-- the main window closed to the bare desktop; the icon is under Mods, above the Trash, its picture
-- in; a double click opens the Workshop window; on a controller Down from Mods selects it.
-- Run with zedqa_menu_mods_run.ps1 (main menu). Screenshots zqa_dku_*.png; grep "ZEDQA dku".
local MM = ZeD.MainMenu
local R = MM.root
local function say(s) print("ZEDQA dku " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_dku_" .. n .. ".png") end) end
local steps, t = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function cell(id) return R.icons and R.icons:find(id) end
local ms = MainScreen and MainScreen.instance
local offered = ms and ms.workshopOption and true or false

at(2, function() MM.showView("main") end)
at(20, function() R.win:close() end)
at(45, function()
    for _, c in ipairs(R.icons._cells or {}) do say(string.format("icon %s at %d,%d %dx%d", c.item.id, c.x, c.y, c.w, c.h)) end
    say("Steam offers the Workshop: " .. tostring(offered))
    local up, mods, trash = cell("uploader"), cell("mods"), cell("trash")
    if not offered then
        check(up == nil, "no Workshop here, so no icon")
        return
    end
    check(up ~= nil, "the Mod Uploader icon is on the desktop")
    if up and mods and trash then
        check(up.x == mods.x and up.y > mods.y + mods.h - 1, "it sits under Mods (" .. up.x .. "," .. up.y .. ")")
        check(up.y + up.h <= trash.y, "it is clear of the Trash")
    end
    local tex = Texture.getSharedTexture("media/textures/ZeD/mainmenu/icons/uploader.png")
    check(tex ~= nil and tex:getWidth() == 32, "its 32 x 32 picture is in")
    shot("1_desktop")
end)
at(46, function() if cell("uploader") then R.icons:click("uploader") end end)
at(48, function() say("selected " .. tostring(R.icons.focusId)); shot("2_selected"); R.icons._lastClick = nil end)
at(50, function() if cell("uploader") then R.icons:click("uploader") end end)
at(53, function() if cell("uploader") then R.icons:click("uploader") end end)   -- (inside the double-click time at any frame rate)
at(90, function()
    if not offered then return end
    check(MM.view == "workshop", "a double click opens the Workshop window (view " .. tostring(MM.view) .. ")")
    shot("3_workshop")
end)
at(95, function() MM.showView("desktop") end)
at(110, function()
    if not offered then return end
    MM.forceGamepad = true
    R.icons.focusId = "mods"
    R.icons:joyDir("down")
    check(R.icons.focusId == "uploader", "pad: Down from Mods selects it (" .. tostring(R.icons.focusId) .. ")")
end)
at(120, function() MM.forceGamepad = false; R.icons.focusId = nil; MM.showView("main") end)
at(135, function() say(fails == 0 and "all checks passed" or (fails .. " failed")); say("DONE") end)

local function tick()
    t = t + 1
    for _, s in ipairs(steps) do if s.n == t then local ok, e = pcall(s.fn); if not ok then fails = fails + 1; say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if t > 140 then Events.OnFETick.Remove(tick) end
end
Events.OnFETick.Add(tick)
say("start")
