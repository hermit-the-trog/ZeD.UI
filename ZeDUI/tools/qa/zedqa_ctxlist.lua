-- ZeDUI/tools/qa/zedqa_ctxlist.lua  (Oct 19 2026)
-- In game on the ZeD-QA save: the context menu as a list. Sets the option to
-- List, opens the menu on an apple (Eat has a submenu), logs its rows,
-- moves down, opens the submenu, captures both, backs out, closes; then the
-- option back to the strip and the strip opens. Screenshots zqa_cl_*.png.
-- grep "ZEDQA cl".
local p = getPlayer()
local function say(s) print("ZEDQA cl " .. tostring(s)) end
local opt = ZeD.Settings.contextStyleOption
local was = opt:getValue()
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local apple, menu
local function zm() local v = getPlayerContextMenu(0); return v and v._zedMenu end
at(2, function()
    if not (ZeD_CharacterWindow.getWindow() and ZeD_CharacterWindow.getWindow():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end
    apple = p:getInventory():AddItem("Base.Apple")
    opt:setValue(2)
end)
at(20, function() ISInventoryPaneContextMenu.createMenu(0, true, { apple }, 700, 300) end)
at(40, function()
    menu = zm()
    local lv = menu and menu._levels and menu._levels[1]
    local names = {}
    for _, r in ipairs(lv and lv.rows or {}) do names[#names + 1] = r.sep and "|" or tostring(r.def.name) end
    say("class " .. tostring(menu and menu.Type) .. " | rows: " .. table.concat(names, ", "))
end)
at(50, function() pcall(function() getCore():TakeFullScreenshot("zqa_cl_1.png") end) end)
at(60, function()
    -- the Eat row, then right (its submenu)
    local lv = menu._levels[1]
    for i, r in ipairs(lv.rows) do if r.def and tostring(r.def.name):find("Eat") then lv.sel = i end end
    menu:onJoypadDirRight()
    local sub = menu._levels[2]
    local names = {}
    for _, r in ipairs(sub and sub.rows or {}) do names[#names + 1] = r.sep and "|" or tostring(r.def.name) end
    say("levels " .. #menu._levels .. " | submenu: " .. table.concat(names, ", "))
end)
at(70, function() pcall(function() getCore():TakeFullScreenshot("zqa_cl_2.png") end) end)
at(80, function() menu:onJoypadDirDown(); say("down: sub sel " .. tostring(menu._levels[2] and menu._levels[2].sel)) end)
at(90, function() menu:onJoypadDown(Joypad.BButton); say("B: levels " .. #menu._levels) end)
at(100, function() menu:onJoypadDown(Joypad.BButton); say("B again: open " .. tostring(menu._ctx.open)) end)
-- the strip again
at(110, function() opt:setValue(1); ISInventoryPaneContextMenu.createMenu(0, true, { apple }, 700, 300) end)
at(130, function() local m = zm(); say("strip back: class " .. tostring(m and m.Type)); if m then m:close() end end)
at(140, function()
    p:getInventory():Remove(apple)
    opt:setValue(was)
    say("DONE")
end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 145 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start")
