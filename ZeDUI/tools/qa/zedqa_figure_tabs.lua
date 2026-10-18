-- ZeDUI/tools/qa/zedqa_figure_tabs.lua  (Oct 17 2026)
-- The body figure where players see it: the Character window's Health, Thermal
-- and Equip tabs, each captured. grep "ZEDQA ft"; Screenshots/zqa_ft_*.png.
local pn = 0
local function say(s) print("ZEDQA ft " .. tostring(s)) end
local function cw() return ZeD_CharacterWindow.getWindow() end
local function tab(id)
    local w = cw(); local strip = w and w._tabStripPanel
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. id then if w._activeTab ~= id then strip:onMouseDown(z.x + 2, z.y + 2) end; return true end
    end
end
local steps, t = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
at(2, function()
    local u = UIManager.getUI()
    for i = 0, u:size() - 1 do local e = u:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    if not (cw() and cw():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(pn) end
end)
at(10, function() tab("health") end)
at(50, function() getCore():TakeFullScreenshot("zqa_ft_health.png") end)
at(55, function() tab("thermal") end)
at(95, function() getCore():TakeFullScreenshot("zqa_ft_thermal.png") end)
at(100, function() tab("equip") end)
at(140, function() getCore():TakeFullScreenshot("zqa_ft_equip.png") end)
at(145, function() tab("loot"); say("DONE") end)
local function tick()
    t = t + 1
    for _, s in ipairs(steps) do if s.n == t then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if t > 150 then Events.OnTick.Remove(tick) end
end
Events.OnTick.Add(tick)
say("start")
