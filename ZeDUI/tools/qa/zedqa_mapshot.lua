-- ZeDUI/tools/qa/zedqa_mapshot.lua  (Oct 19 2026)
-- Reference shots for the curtains mockup: both windows, then the World
-- window's Maps tab open. zqa_ms_*.png. grep "ZEDQA ms".
local function say(s) print("ZEDQA ms " .. tostring(s)) end
local tick = 0
local function onTick()
    tick = tick + 1
    if tick == 2 then
        if not (ZeD_CharacterWindow.getWindow() and ZeD_CharacterWindow.getWindow():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end
    elseif tick == 40 then pcall(function() getCore():TakeFullScreenshot("zqa_ms_1.png") end)
    elseif tick == 50 then ZeD_WorldWindow.openTab(0, "maps")
    elseif tick == 110 then
        local w = ZeD_WorldWindow.getWindow()
        say("world " .. w:getX() .. "," .. w:getY() .. " " .. w:getWidth() .. "x" .. w:getHeight() .. " tab " .. tostring(w._activeTab))
        pcall(function() getCore():TakeFullScreenshot("zqa_ms_2.png") end)
        say("DONE"); Events.OnTick.Remove(onTick)
    end
end
Events.OnTick.Add(onTick)
say("start")
