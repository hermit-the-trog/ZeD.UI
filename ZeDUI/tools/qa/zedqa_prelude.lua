-- ZeDUI/tools/qa/zedqa_prelude.lua  (Oct 19 2026)
-- In game on the ZeD-QA save: the first line of the unattended regression
-- (zedqa_run.ps1, regression.txt). Opens the window pair if it is shut (the
-- suites need both windows), unpauses, turns on god mode (the QA character
-- once starved at speed), waits about 60 ticks for the windows to settle and
-- prints "ZEDQA pre DONE". If OnTick never ran (the game is still paused) it
-- says so as an ERR line, so the run reads WARN instead of timing out.
-- grep "ZEDQA pre".
local function say(s) print("ZEDQA pre " .. tostring(s)) end
local p = getPlayer()
-- (Oct 27 2026, the director: the QA character stood in thick woods, with no open ground to
-- spawn things and the view often blocked, and runs drifted into night) every run starts on
-- Irvington Speedway's drag strip, open asphalt, in daylight. The save keeps the move.
local HOME = { x = 925.5, y = 13040.5, z = 0 }
local moved = false
local ok, e = pcall(function()
    if getGameSpeed and getGameSpeed() == 0 and setGameSpeed then setGameSpeed(1) end
    if p then p:setGodMod(true) end
    if p and p:getVehicle() then p:getVehicle():exit(p) end
    if p and (math.abs(p:getX() - HOME.x) > 3 or math.abs(p:getY() - HOME.y) > 3 or math.floor(p:getZ()) ~= HOME.z) then
        say(string.format("moved from %d,%d,%d to the drag strip", math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())))
        p:setX(HOME.x); p:setY(HOME.y); p:setZ(HOME.z); p:setLastX(HOME.x); p:setLastY(HOME.y); p:setLastZ(HOME.z)
        moved = true
    end
    local gt = getGameTime()
    local hour = gt:getTimeOfDay()
    if hour < 8 or hour > 17 then gt:setTimeOfDay(11.0); say(string.format("clock %.2f -> 11.00 (daylight)", hour)) end
    local cw = ZeD_CharacterWindow.getWindow()
    if not (cw and cw:isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end
end)
if not ok then say("ERR setup " .. tostring(e)) end
-- counted on OnRenderTick (it runs even while paused); OnTick is counted
-- beside it to tell a paused game from a running one
local frames, ticks = 0, 0
local function onTick() ticks = ticks + 1 end
local function onFrame()
    frames = frames + 1
    if frames < (moved and 300 or 60) then return end   -- (after the move: the strip's cells load)
    if ticks < 60 and frames < 600 then return end
    Events.OnRenderTick.Remove(onFrame)
    Events.OnTick.Remove(onTick)
    local cw, ww = ZeD_CharacterWindow.getWindow(), ZeD_WorldWindow.getWindow()
    say("char " .. tostring(cw and cw:isVisible()) .. " world " .. tostring(ww and ww:isVisible())
        .. " speed " .. tostring(getGameSpeed and getGameSpeed()) .. " ticks " .. ticks .. " frames " .. frames)
    if ticks == 0 then say("ERR OnTick never ran: the game is paused") end
    -- (Oct 25 2026) search mode off: its overlay blurs everything outside a ring round the
    -- character, and the gallery's reshoot came out soft with it on
    local sm = p and ISSearchManager and ISSearchManager.getManager and ISSearchManager.getManager(p)
    if sm and sm.isSearchMode then pcall(function() sm:toggleSearchMode(false) end); say("search mode was on: turned off") end
    local okE, eng = pcall(getSearchMode)
    if okE and eng and p then
        local pn = p:getPlayerNum()
        local en, ov = eng:isEnabled(pn), eng:isOverride(pn)
        say(string.format("search overlay: enabled %s, override %s, manager %s", tostring(en), tostring(ov), tostring(sm and sm.isSearchMode)))
        if en or ov then pcall(function() eng:setOverride(pn, false); eng:setEnabled(pn, false) end); say("search overlay turned off") end
    end
    say("DONE")
end
Events.OnTick.Add(onTick)
Events.OnRenderTick.Add(onFrame)
say("start")
