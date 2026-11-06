-- ZeDUI/tools/qa/mp_extras_two.lua  (Nov 6 2026, QA): the second player in mp_extras.lua's run: a plain player, by the first player's
-- claimed truck. grep "ZEDQA mx2". The game's real refusals: a timed action the server answers false, the engine, a tow, a swing.
-- Each PROBE is what the sims can't settle. Bring bob to the truck first: /teleportplayer "bob" "admin" on the first client.
--   pwsh -File ZeDUI/tools/qa/mp_client2.ps1 -Run ZeDUI/tools/qa/mp_extras_two.lua -Tag mx2
-- After it: bob must still be on the server (no kick, no suspicion in *_DebugLog-server.txt), and the ZeD log holds "refused: parts"
-- and "refused: drive" lines.
local function say(s) print("ZEDQA mx2 " .. tostring(s)) end
local p = getPlayer()
local E = ZeD.Extras

local function nearest()
    local best, bd = nil, 999
    local it = getCell():getVehicles():iterator()
    while it:hasNext() do
        local v = it:next()
        local dx, dy = v:getX() - p:getX(), v:getY() - p:getY()
        local d = math.sqrt(dx * dx + dy * dy)
        if d < bd then best, bd = v, d end
    end
    return best, bd
end

local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local part

add(1000, function()
    local v, d = nearest()
    say("nearest vehicle " .. tostring(v and v:getScriptName()) .. ", " .. tostring(d) .. " tiles; extras " .. tostring(E.set and ZeD.Ex.summary(E.set)))
    if v then
        E.car(v)
        part = v:getPartById("Battery") or v:getPartById("GasTank")
    end
end)
add(1500, function()
    local v = nearest()
    local view = v and E.cars[v:getId()] and E.cars[v:getId()].view
    say("the car's view: owner " .. tostring(view and view.owner) .. ", mine " .. tostring(view and view.mine))
    say("the Vehicle tab would gray it for " .. tostring(v and E.partsBlock(v)))
    if part then
        -- past the gray, as a modified client would: the server's refusal is the point
        ISTimedActionQueue.add(ISUninstallVehiclePart:new(p, part, 50))
        say("PROBE an uninstall sent, past the gray")
    end
end)
add(10000, function()
    say("PROBE the part after the wait: " .. tostring(part and part:getInventoryItem() ~= nil) .. " (true: the server refused it)")
    say("PROBE the action is gone from the queue: " .. tostring(not (ISTimedActionQueue.hasAction and p:hasTimedActions())))
    local v = nearest()
    if v then ISVehicleMenu.onEnter(p, v, 0) end
end)
add(5000, function()
    local v = p:getVehicle()
    say("PROBE in the driver's seat (the game has no hook to stop it): " .. tostring(v ~= nil and v:isDriver(p)))
    if v then ISTimedActionQueue.add(ISStartVehicleEngine:new(p)) end
end)
add(4000, function()
    local v = p:getVehicle()
    say("PROBE the engine after the attempt: " .. tostring(v and v:isEngineRunning()) .. " (false: refused)")
    say("TODO: start the truck on the first client, get out, get in here: the engine must stop within 2 seconds")
    say("TODO: hitch it to a car here: the link must come straight off")
    say("TODO: in another player's safehouse, swing an axe at a door: its health must not fall (OnWeaponHitThumpable on the server)")
    say("DONE")
end)

local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
