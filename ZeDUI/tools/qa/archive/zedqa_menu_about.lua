-- ZeDUI/tools/qa/zedqa_menu_about.lua  (Nov 1 2026, QA; HANDOFF_main_menu_book_20261101.md)
-- At the main menu: the ZeD menu pulled down (its About paragraph grew a third in t15) and a screenshot
-- mm_about_<W>x<H>.png; PASS when the menu's drop ends inside the monitor's glass (MM.layout's tube rect),
-- FAIL with the numbers otherwise. Run through zedqa_menu_about_run.ps1 at 1280x720 and 1280x800.
-- grep "ZEDQA mab"; DONE a few ticks after the shot (OnFETick: the main menu has no OnTick).
local MM = ZeD and ZeD.MainMenu
local function say(s) print("ZEDQA mab " .. tostring(s)) end
if not (MM and MM.root and MM.root.drop and MM.layout) then say("FAIL no ZeD main menu (root " .. tostring(MM and MM.root) .. ")"); say("DONE"); return end
local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
local n, shot = 0, false
local function tick()
    n = n + 1
    if n == 2 then MM.ctx.open = "zed"; say("the ZeD menu opened at " .. sw .. "x" .. sh) end
    if n == 40 and not shot then
        shot = true
        local d, L = MM.root.drop, MM.layout()
        local dx, dy, dw, dh = d:getX(), d:getY(), d:getWidth(), d:getHeight()
        local gx, gy, gw, gh = L.tx, L.ty, L.tw, L.th
        local inside = d:isVisible() and dx >= gx and dy >= gy and dx + dw <= gx + gw and dy + dh <= gy + gh
        say(string.format("drop %d,%d %dx%d (bottom %d) | glass %d,%d %dx%d (bottom %d) | scale %s | visible %s",
            dx, dy, dw, dh, dy + dh, gx, gy, gw, gh, gy + gh, tostring(L.s), tostring(d:isVisible())))
        say((inside and "PASS" or "FAIL") .. " the ZeD menu ends inside the monitor's glass at " .. sw .. "x" .. sh
            .. (inside and "" or string.format(" (over by %d px at the bottom, %d px at the right)", math.max(0, dy + dh - (gy + gh)), math.max(0, dx + dw - (gx + gw)))))
        pcall(function() getCore():TakeFullScreenshot("mm_about_" .. sw .. "x" .. sh .. ".png") end)
        say("shot mm_about_" .. sw .. "x" .. sh)
    end
    if n == 50 then MM.ctx.open = nil end
    if n >= 56 then Events.OnFETick.Remove(tick); say("DONE") end
end
Events.OnFETick.Add(tick)
