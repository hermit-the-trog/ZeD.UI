-- ZeDUI/tools/qa/zedqa_menu_desk_v4.lua  (Nov 1 2026, QA; HANDOFF_main_menu_book_20261101.md)
-- At the main menu: the v4 desk as the mod draws it, two screenshots at the run's size: mm_desk_v4_<W>x<H>.png lit,
-- then a lamp dim beat forced through MM._life.lamp (the odd beat is the dipped picture) and
-- mm_desk_v4_<W>x<H>_dim.png; the lamp's beats put back. Compare with tools/mainmenu/previews/main_menu_v4_4x.png.
-- grep "ZEDQA mdv"; DONE a few ticks after the second shot (OnFETick: the main menu has no OnTick).
local MM = ZeD and ZeD.MainMenu
local function say(s) print("ZEDQA mdv " .. tostring(s)) end
if not (MM and MM.root and MM._life) then say("FAIL no ZeD main menu (root " .. tostring(MM and MM.root) .. ", life " .. tostring(MM and MM._life) .. ")"); say("DONE"); return end
local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
local name = "mm_desk_v4_" .. sw .. "x" .. sh
local life = MM._life
local was = life.lamp
local n = 0
local function tick()
    n = n + 1
    if n == 2 then
        if life.lamp then life.lamp.beats = nil; life.lamp.nextAt = getTimestampMs() + 600000 end   -- lit, and no beat for the lit shot
        say("lamp lit (beats off) at " .. sw .. "x" .. sh .. " | ZeD menu closed " .. tostring(MM.ctx and MM.ctx.open == nil))
    end
    if n == 30 then pcall(function() getCore():TakeFullScreenshot(name .. ".png") end); say("shot " .. name) end
    if n == 34 then
        local t = getTimestampMs()
        life.lamp = { beats = { 600000, 600000 }, i = 1, beatEnd = t + 600000, nextAt = t + 1200000 }   -- beat 1 is odd: dipped
        say("lamp dim beat forced")
    end
    if n == 60 then pcall(function() getCore():TakeFullScreenshot(name .. "_dim.png") end); say("shot " .. name .. "_dim") end
    if n == 64 then
        life.lamp = was
        if life.lamp then life.lamp.beats = nil; life.lamp.nextAt = getTimestampMs() + 8000 end
        say("lamp put back")
    end
    if n >= 70 then Events.OnFETick.Remove(tick); say("DONE") end
end
Events.OnFETick.Add(tick)
