-- ZeDUI/tools/qa/zedqa_menu_case.lua  (Oct 16 2026)
-- At the main menu: the menu bar's menus and a screen's pop-up menu in
-- sentence case. Opens the ZeD, File and Multiplayer menus in turn, then Load
-- Game's More menu, and shoots each. Copy to Zomboid/Lua/zedqa.lua, bump
-- zedqa.go; grep "ZEDQA mc"; captures Screenshots/zqa_mc_*.png.
local MM = ZeD.MainMenu
local R = MM.root
local function say(s) print("ZEDQA mc " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_mc_" .. n .. ".png") end) end
local steps, t = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
at(2, function() MM.showView("main") end)
for i, key in ipairs({ "zed", "file", "mp", "settings" }) do
    at(10 + (i - 1) * 25, function()
        MM.ctx.open = key
        local labels = {}
        for _, it in ipairs(MM.menuItems(key)) do if type(it) == "table" and it.text then labels[#labels + 1] = it.text end end
        say(key .. ": " .. table.concat(labels, " | "))
    end)
    at(10 + (i - 1) * 25 + 18, function() shot(string.format("%02d_%s", i, key)) end)
end
at(115, function() MM.ctx.open = nil; MM.showView("load") end)
at(140, function() if R.loadWin and R.loadWin.openMore then R.loadWin:openMore() end end)
at(160, function() shot("05_load_more"); MM.ctx.open = nil; MM.showView("main"); say("DONE") end)
local function tick()
    t = t + 1
    for _, s in ipairs(steps) do if s.n == t then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if t > 170 then Events.OnFETick.Remove(tick) end
end
Events.OnFETick.Add(tick)
say("start")
