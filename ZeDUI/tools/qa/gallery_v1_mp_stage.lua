-- ZeDUI/tools/qa/gallery_v1_mp_stage.lua  (Nov 17 2026, QA; ZeD-GUI 1.0 gallery, picture 75 "Playing on a Server"): on
-- the ADMIN client (gallery_v1_mp.txt), before the other players come. The old server pictures (mps_01 ... mps_11, Nov 5)
-- were taken seconds after a /teleportto: the map around the new spot had not streamed in yet, so half the screen was
-- black with only the squares by the character drawn. This stage:
--   1. daytime: the server's own clock to 11:00 (the shim's ZeDQA.time; the clients follow the server's clock, a
--      client-side setTimeOfDay is overwritten) and fed and rested (the shim's ZeDQA.fresh) so no moodle shows
--   2. the admin to a lit street in Muldraugh (the Sunstar motel strip on the main road, open ground, mp_open.lua's
--      first spot), the next spot if that square is inside a building or blocked
--   3. waits until the map is loaded around it: every square on rings 10, 25 and 40 squares out exists on the client,
--      three checks in a row, then ten seconds more for the lighting
-- grep "ZEDQA g1mst".
G1ST = {}
local G = G1ST
G.p = getPlayer()
G.SPOTS = { { 10600, 9800 }, { 10605, 10000 }, { 10610, 10400 } }
G.RINGS = { 10, 25, 40 }
function G.say(s) print("ZEDQA g1mst " .. tostring(s)) end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
-- poll: fn every n frames until it returns true, at most max times
local function poll(n, max, fn) Q[#Q + 1] = { n = n, fn = fn, poll = true, max = max, tries = 0 } end

function G.near(x, y) return math.abs(G.p:getX() - x) < 3 and math.abs(G.p:getY() - y) < 3 end
function G.loaded()
    local cell = getCell()
    local px, py = math.floor(G.p:getX()), math.floor(G.p:getY())
    local miss = 0
    for _, r in ipairs(G.RINGS) do
        for k = 0, 15 do
            local a = k * math.pi / 8
            local sq = nil
            pcall(function() sq = cell:getGridSquare(px + math.floor(r * math.cos(a)), py + math.floor(r * math.sin(a)), 0) end)
            if not sq then miss = miss + 1 end
        end
    end
    return miss
end

step(10, function()
    pcall(function() sendClientCommand(G.p, "ZeDQA", "time", { h = 11.0 }) end)
    pcall(function() sendClientCommand(G.p, "ZeDQA", "fresh", {}) end)
    G.say(string.format("asked the server for 11:00 (client reads %.2f) and a fresh character", getGameTime():getTimeOfDay()))
end)
G.si = 1
G.placed = false
-- (each spot's steps made by a function with i as its argument, not inside the loop body)
local function addSpot(i)
    step(10, function()
        if G.placed then return end
        local s = G.SPOTS[i]
        G.si = i
        pcall(function() SendCommandToServer("/teleportto " .. s[1] .. "," .. s[2] .. ",0") end)
        G.say("teleport to " .. s[1] .. "," .. s[2])
    end)
    -- arrived (up to 15 s), then the square is checked
    poll(30, 30, function()
        if G.placed then return true end
        local s = G.SPOTS[i]
        return G.near(s[1], s[2])
    end)
    step(60, function()
        if G.placed then return end
        local sq = G.p:getCurrentSquare()
        local open = false
        pcall(function() open = sq ~= nil and sq:getBuilding() == nil and sq:isFree(false) end)
        if open then G.placed = true end
        G.say(string.format("at %d,%d: open ground %s", math.floor(G.p:getX()), math.floor(G.p:getY()), tostring(open)))
    end)
end
for i = 1, #G.SPOTS do addSpot(i) end
step(5, function() if not G.placed then G.say("FAIL no open spot; staying at the last one") end end)
-- the map around the spot: three clean checks in a row, up to 2 minutes
G.clean = 0
poll(60, 120, function()
    local miss = G.loaded()
    if miss == 0 then G.clean = G.clean + 1 else G.clean = 0 end
    if miss > 0 then G.say("squares not loaded yet on the rings: " .. miss) end
    return G.clean >= 3
end)
step(600, function()
    local miss = G.loaded()
    G.say((miss == 0 and "PASS" or "FAIL") .. string.format(" map loaded around %d,%d (%d of 48 ring squares missing) | time %.2f",
        math.floor(G.p:getX()), math.floor(G.p:getY()), miss, getGameTime():getTimeOfDay()))
    G1_SPOT = { x = math.floor(G.p:getX()), y = math.floor(G.p:getY()) }
    G.say("DONE")
end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    local ok, r = pcall(s.fn)
    if not ok then G.say("ERR step " .. qi .. ": " .. tostring(r)) end
    if s.poll and ok and not r then
        s.tries = s.tries + 1
        if s.tries < s.max then return end
        G.say("poll at step " .. qi .. " gave up after " .. s.tries .. " tries")
    end
    qi = qi + 1
end
Events.OnTick.Add(tick)
G.say("start as " .. tostring(G.p:getUsername()))
