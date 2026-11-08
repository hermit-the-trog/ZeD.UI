-- ZeDUI/tools/qa/zedqa_prelude2.lua (Nov 7 2026, QA): the prelude again under its own tag, for a manifest that needs the pair reopened mid-run (generated from zedqa_prelude.lua)
-- In game on the ZeD-QA save: the first line of the unattended regression
-- (zedqa_run.ps1, regression.txt). Opens the window pair if it is shut (the
-- suites need both windows), unpauses, turns on god mode (the QA character
-- once starved at speed), waits about 60 ticks for the windows to settle and
-- prints "ZEDQA pre2 DONE". If OnTick never ran (the game is still paused) it
-- says so as an ERR line, so the run reads WARN instead of timing out.
-- grep "ZEDQA pre".
local function say(s) print("ZEDQA pre2 " .. tostring(s)) end

-- (punch list 47, Nov 2 2026) the vehicle probe for the 1280x720 bisect: where the character stands, how wide
-- the loaded chunk grid is and what it covers, and whether a spawn square and its car lie inside it. The
-- vehicle scripts call it right after their spawn when it exists (a script run alone skips it). One line
-- each; grep "ZEDQA vp".
function ZEDQA_VPROBE(tag, sq, v)
    local ok, line = pcall(function()
        local pl, cell = getPlayer(), getCell()
        local cm = cell:getChunkMap(0)
        local wt = cm:getWidthInTiles()
        local px, py = pl:getX(), pl:getY()
        local out = string.format("ZEDQA vp %s player=%d,%d grid=%d chunks (%d tiles) loaded x %d-%d y %d-%d",
            tostring(tag), math.floor(px), math.floor(py), math.floor(wt / 8), wt,
            cm:getWorldXMinTiles(), cm:getWorldXMaxTiles(), cm:getWorldYMinTiles(), cm:getWorldYMaxTiles())
        if sq then
            local sx, sy = sq:getX(), sq:getY()
            out = out .. string.format(" sq=%d,%d dist=%.1f chunk=%s inMap=%s", sx, sy,
                math.sqrt((sx - px) ^ 2 + (sy - py) ^ 2), tostring(sq:getChunk() ~= nil), tostring(cell:isInChunkMap(sx, sy)))
        else
            out = out .. " sq=nil"
        end
        if v then
            out = out .. string.format(" car=%s at %.1f,%.1f dist=%.1f", tostring(v:getScriptName()), v:getX(), v:getY(),
                math.sqrt((v:getX() - px) ^ 2 + (v:getY() - py) ^ 2))
        else
            out = out .. " car=nil"
        end
        local vs = cell:getVehicles()
        return out .. " vehicles=" .. tostring(vs and vs:size())
    end)
    print(ok and line or ("ZEDQA vp " .. tostring(tag) .. " ERR " .. tostring(line)))
end
local p = getPlayer()
-- (Oct 27 2026, the director: the QA character stood in thick woods, with no open ground to
-- spawn things and the view often blocked, and runs drifted into night) every run starts on
-- Irvington Speedway's drag strip, open asphalt, in daylight. The save keeps the move.
local HOME = { x = 925.5, y = 13040.5, z = 0 }
local moved = false

-- (punch list 47, Nov 2 2026) the drag strip for every script that needs open ground. Scripts 57, 61 and 63
-- (cb, bg, ws) leave the character in the grandstand at about 964,13079; a car spawned beside it then stands
-- indoors and its physics never wakes (QA's moved-sl run at 720), and at 720 the grandstand's
-- west end (892) is outside the loaded grid, so rst's fixture is not found. The vehicle scripts and rst call
-- this first; it moves the character (out of any car) to the strip when it is elsewhere and says so.
-- Returns true when it moved. A script run without the prelude skips it.
function ZEDQA_HOME(tag)
    local pl = getPlayer()
    if not pl then return false end
    local car = pl:getVehicle()
    if car then car:exit(pl); triggerEvent("OnExitVehicle", pl) end
    if math.abs(pl:getX() - HOME.x) <= 3 and math.abs(pl:getY() - HOME.y) <= 3 and math.floor(pl:getZ()) == HOME.z then return false end
    print("ZEDQA home " .. tostring(tag) .. " moved from " .. math.floor(pl:getX()) .. "," .. math.floor(pl:getY()) .. "," .. math.floor(pl:getZ()) .. " to the drag strip")
    pl:setX(HOME.x); pl:setY(HOME.y); pl:setZ(HOME.z); pl:setLastX(HOME.x); pl:setLastY(HOME.y); pl:setLastZ(HOME.z)
    return true
end
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
