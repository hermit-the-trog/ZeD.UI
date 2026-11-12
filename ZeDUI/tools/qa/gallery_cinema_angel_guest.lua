-- ZeDUI/tools/qa/gallery_cinema_angel_guest.lua  (Nov 11 2026, QA; the gallery's closing break): on each OTHER player's
-- client (mp_client2.ps1 -Slot n -Run). Waits until the admin (Angel, user zedqa) is beside it (the admin's /teleport,
-- gallery_cinema_angel_gather.lua), then stands a step or two in front of him (its own place by its user name) and keeps
-- facing him. Prints DONE once placed; the facing goes on for ten minutes. grep "ZEDQA cagu".
local function say(s) print("ZEDQA cagu " .. tostring(s)) end
local p = getPlayer()
local me = p and p:getUsername() or "?"
local SPOT = { bob = { -1, 2 }, carl = { 1, 2 }, dave = { 2, 0 }, erin = { -2, 1 } }
local off = SPOT[me] or { 0, 2 }
local admin, placed, n, t0 = nil, false, 0, getTimestampMs()
A_SPOT = nil
pcall(function() SendCommandToServer('/godmod "' .. me .. '" -true') end)
local function find()
    local l = getOnlinePlayers()
    for i = 0, l:size() - 1 do
        local o = l:get(i)
        if o ~= p and tostring(o:getUsername()) == "zedqa" then return o end
    end
    return nil
end
local function tick()
    n = n + 1
    if n % 15 ~= 0 then return end
    local ok, e = pcall(function()
        admin = find() or admin
        if not admin then
            if n % 300 == 0 then say("waiting for the admin") end
            return
        end
        local ax, ay = admin:getX(), admin:getY()
        if not placed then
            if math.abs(ax - p:getX()) > 4 or math.abs(ay - p:getY()) > 4 then
                if n % 300 == 0 then say(string.format("admin at %.0f,%.0f, me at %.0f,%.0f: waiting for the teleport", ax, ay, p:getX(), p:getY())) end
                return
            end
            local x, y = math.floor(ax) + off[1] + 0.5, math.floor(ay) + off[2] + 0.5
            p:setX(x); p:setY(y); p:setLastX(x); p:setLastY(y)
            placed = true
            A_SPOT = { x = x, y = y, t = getTimestampMs() }
            say(string.format("%s placed at %.1f,%.1f, the admin at %.1f,%.1f", me, x, y, ax, ay))
            say("DONE")
        end
        -- (Nov 12 2026) the server's teleport can land after the first placing (bob stood on Angel's square in the
        -- first retake): the spot held for the first two minutes after placing
        if placed and A_SPOT and getTimestampMs() - A_SPOT.t < 120000 and (math.abs(p:getX() - A_SPOT.x) > 0.6 or math.abs(p:getY() - A_SPOT.y) > 0.6) then
            p:setX(A_SPOT.x); p:setY(A_SPOT.y); p:setLastX(A_SPOT.x); p:setLastY(A_SPOT.y)
            say(string.format("%s put back on its spot %.1f,%.1f", me, A_SPOT.x, A_SPOT.y))
        end
        p:faceLocation(ax, ay)
    end)
    if not ok then say("ERR " .. tostring(e)) end
    if getTimestampMs() - t0 > 900000 then Events.OnTick.Remove(tick) end
end
Events.OnTick.Add(tick)
say("start as " .. tostring(me))
