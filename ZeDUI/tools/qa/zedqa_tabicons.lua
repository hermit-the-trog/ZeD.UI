-- ZeDUI/tools/qa/zedqa_tabicons.lua  (Oct 19 2026)
-- Captures both tab strips with the Skills (Character) and Maps (World) tabs
-- active, the Animals tab idle beside them. Screenshot zqa_tabicons.png.
local function strip(w, s, id) for _, z in ipairs(s._hitZones or {}) do if z.id == "tab:" .. id then s:onMouseDown(z.x + 2, z.y + 2) end end end
local n = 0
local function t()
    n = n + 1
    if n == 2 then local cw = ZeD_CharacterWindow.getWindow(); if not (cw and cw:isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end end
    if n == 20 then
        local cw, ww = ZeD_CharacterWindow.getWindow(), ZeD_WorldWindow.getWindow()
        strip(cw, cw._tabStripPanel, "skills"); strip(ww, ww._actionTabStrip, "forage")
    end
    if n == 60 then pcall(function() getCore():TakeFullScreenshot("zqa_tabicons.png") end) end
    if n == 70 then
        local cw, ww = ZeD_CharacterWindow.getWindow(), ZeD_WorldWindow.getWindow()
        strip(cw, cw._tabStripPanel, "loot"); strip(ww, ww._actionTabStrip, "loot")
        print("ZEDQA ti DONE"); Events.OnTick.Remove(t)
    end
end
Events.OnTick.Add(t)
