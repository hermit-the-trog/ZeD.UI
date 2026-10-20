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
local ok, e = pcall(function()
    if getGameSpeed and getGameSpeed() == 0 and setGameSpeed then setGameSpeed(1) end
    if p then p:setGodMod(true) end
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
    if frames < 60 then return end
    if ticks < 60 and frames < 600 then return end
    Events.OnRenderTick.Remove(onFrame)
    Events.OnTick.Remove(onTick)
    local cw, ww = ZeD_CharacterWindow.getWindow(), ZeD_WorldWindow.getWindow()
    say("char " .. tostring(cw and cw:isVisible()) .. " world " .. tostring(ww and ww:isVisible())
        .. " speed " .. tostring(getGameSpeed and getGameSpeed()) .. " ticks " .. ticks .. " frames " .. frames)
    if ticks == 0 then say("ERR OnTick never ran: the game is paused") end
    say("DONE")
end
Events.OnTick.Add(onTick)
Events.OnRenderTick.Add(onFrame)
say("start")
