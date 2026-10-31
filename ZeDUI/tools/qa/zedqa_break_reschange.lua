-- ZeDUI/tools/qa/zedqa_break_reschange.lua  (Oct 31 2026, QA; break-it B3's re-check)
-- Both windows made far bigger than the screen and pushed half off it, then the game's OnResolutionChange
-- fired (the screen's own size, as a resolution change does): each window must end on the screen, no
-- taller than it, no wider. grep "ZEDQA brc".
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local function say(s) print("ZEDQA brc " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end end
if not (CWm.isOpen() and WWm.isOpen()) then CWm.toggleBothPaired(0) end
local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
local n = 0
local function f()
    n = n + 1
    if n == 5 then
        for _, w in ipairs({ CWm.getWindow(), WWm.getWindow() }) do
            w:setWidth(sw * 2); w:setHeight(sh * 2); w:setX(sw - 50); w:setY(sh - 50)
        end
        triggerEvent("OnResolutionChange", sw, sh, sw, sh)
    elseif n == 40 then
        Events.OnTick.Remove(f)
        for _, pair in ipairs({ { "Character", CWm.getWindow() }, { "World", WWm.getWindow() } }) do
            local w = pair[2]
            local x, y, ww, wh = w:getX(), w:getY(), w:getWidth(), w:getHeight()
            check(x >= 0 and y >= 0 and x + ww <= sw + 1 and y + wh <= sh + 1,
                string.format("%s window on the screen after a resolution change (%d,%d %dx%d on %dx%d)", pair[1], x, y, ww, wh, sw, sh))
        end
        pcall(ZeD_Window.resetLayout)
        say(fails == 0 and "all checks passed" or (fails .. " failed"))
        say("DONE")
    end
end
Events.OnTick.Add(f)
say("start")
