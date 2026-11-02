-- ZeDUI/tools/qa/zedqa_move_to.lua  (Nov 2 2026, QA; punch list 47)
-- Moves the QA character to where the 720 full pass leaves it before sl (964,13078: the state lines of
-- 2026-11-02_pl47_state2_720.md), then waits 300 frames for the cells to load, as the prelude does after its move.
-- grep "ZEDQA mv".
local function say(s) print("ZEDQA mv " .. tostring(s)) end
local T = { x = 964.5, y = 13078.5, z = 0 }
local p = getPlayer()
if p:getVehicle() then p:getVehicle():exit(p) end
say("from " .. math.floor(p:getX()) .. "," .. math.floor(p:getY()) .. "," .. math.floor(p:getZ()))
p:setX(T.x); p:setY(T.y); p:setZ(T.z); p:setLastX(T.x); p:setLastY(T.y); p:setLastZ(T.z)
local frames = 0
local function onFrame()
    frames = frames + 1
    if frames < 300 then return end
    Events.OnRenderTick.Remove(onFrame)
    local sq = p:getCurrentSquare()
    say("at " .. math.floor(p:getX()) .. "," .. math.floor(p:getY()) .. "," .. math.floor(p:getZ()) .. " | room " .. tostring(sq and sq:getRoom() ~= nil)
        .. " | outside " .. tostring(sq and sq:isOutside()))
    say("DONE")
end
Events.OnRenderTick.Add(onFrame)
