-- ZeDUI/tools/qa/mp_extras.lua  (Nov 6 2026, QA): multiplayer Phase 6, the server extras, on the local server.
-- grep "ZEDQA mex", then the server's logs in C:\Users\danie\Zomboid\zedqa_mp\Logs (*_ZeD.txt: "admin | server extras", "vehicle |",
-- "safehouse |", "container |"). A line "no ISxxx in this game" there means a class the wraps expect has gone.
--   pwsh -File ZeDUI/tools/qa/mp_server.ps1 -Start -Mods "ZeD_UI;ZeDQAShim"     (the shim carries ZeDQA.role)
--   pwsh -File ZeDUI/tools/qa/zedqa_run.ps1 -Mp -Manifest ZeDUI/tools/qa/mp_extras.txt
--   pwsh -File ZeDUI/tools/qa/mp_client2.ps1 -Start                              (the second player, bob, for the refusals)
--   pwsh -File ZeDUI/tools/qa/mp_client2.ps1 -Run ZeDUI/tools/qa/mp_extras_two.lua -Tag mx2
-- It drives ZeD.Extras, and the server answers. This client is the owner: it turns every extra on, spawns a truck and claims it, and
-- leaves it for bob. mp_extras_two.lua is bob, who tries to take a part, start the engine and hit a door. PROBE lines are what only
-- the game can settle: read them against MP_SERVER_PART_DESIGN.md's last section. extras_sim.lua proves the logic without the game;
-- mp_extras_cards.lua takes the pictures. Run this once with every extra off first (ZEDQA_EX_OFF_ONLY, below) to read the off state.
local function say(s) print("ZEDQA mex " .. tostring(s)) end
local function pass(name, ok, detail)
    say((ok and "PASS " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
end
local p = getPlayer()
local me = p:getUsername()
local E, Ex, S = ZeD.Extras, ZeD.Ex, ZeD.ServerPart

local got = {}
local function tap(module, command, args)
    if module == Ex.MOD then got[#got + 1] = { c = command, a = args or {} } end
end
Events.OnServerCommand.Add(tap)
local function last(cmd)
    for i = #got, 1, -1 do if got[i].c == cmd then return got[i].a end end
    return nil
end
local function nolimits() sendClientCommand(p, "ZeDQA", "nolimits", {}) end

-- the nearest vehicle the game has loaded
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
local ans = {}
local function keep(name) return function(a) ans[name] = a end end

add(3000, function()
    pass("the link is up", S.available())
    pass("the hello carried the extras", E.set ~= nil)
    say("settings: " .. Ex.summary(E.set))
    pass("off, if nobody has saved here yet", Ex.nOn(E.set) == 0, Ex.nOn(E.set))
    pass("no client wrap yet", E.logArmed == nil or E.set.cl.on)
    local v = nearest()
    pass("the Vehicle tab asks nothing while off", E.set.vc.on or (v == nil) or E.car(v) == nil)
    E.claim(v or { getId = function() return 0 end }, keep("offClaim"))
end)
add(1500, function()
    pass("a claim with claims off", E.set.vc.on or (ans.offClaim and ans.offClaim.err == "off"), ans.offClaim and ans.offClaim.err)
    if ZEDQA_EX_OFF_ONLY then
        say("DONE")
        return
    end
    local set = Ex.clean(E.set)
    set.vc.on, set.vc.tow, set.vc.per, set.sp.on, set.tp.on, set.cl.on = true, true, 2, true, true, true
    nolimits()
    E.save(set, keep("save"))
end)
add(2000, function()
    pass("the owner saves", ans.save and ans.save.ok == true, ans.save and ans.save.err)
    pass("the server's answer comes to every client", last("x_set") ~= nil)
    pass("every extra on", E.set and Ex.nOn(E.set) == 4)
    pass("the client's wrap went on for the log", E.logArmed == true)
    SendCommandToServer("/addvehicle \"Base.PickUpTruck\"")
end)
add(4000, function()
    local v, d = nearest()
    pass("a truck by me", v ~= nil and d < Ex.L.REACH_TILES, d)
    if not v then return end
    E.claim(v, keep("claim"))
    say("PROBE sql id on this client: " .. tostring(v:getSqlId()) .. " (the server's is what counts; the log's claim line and a restart say more)")
end)
add(1500, function()
    pass("claimed", ans.claim and ans.claim.ok == true, ans.claim and ans.claim.err)
    local v = nearest()
    if v then E.car(v) end
end)
add(1000, function()
    local a = last("x_veh")
    pass("the car's view", a ~= nil and a.mine == true and a.owner == me)
    say("view: key " .. tostring(a and a.key) .. ", " .. tostring(a and a.n) .. " of " .. tostring(a and a.per))
    E.mineRows = nil
    E.mine()
end)
add(1500, function()
    pass("my claims", E.mineRows ~= nil and #E.mineRows >= 1)
    local r = E.mineRows and E.mineRows[1]
    if r then say("row: " .. tostring(r.name) .. " at " .. tostring(r.x) .. " x " .. tostring(r.y)) end
    pass("the row's name reads", r ~= nil and r.name ~= nil and (getTextOrNull("IGUI_VehicleName" .. r.name) ~= nil), r and r.name)
    nolimits()
    ans.x, ans.y = math.floor(p:getX()) + 6, math.floor(p:getY())
    E.goTo(ans.x, ans.y, keep("tp"))
end)
add(4000, function()
    pass("the map's teleport went through", ans.tp and ans.tp.ok == true, ans.tp and ans.tp.err)
    local dx = math.abs(p:getX() - ans.x)
    say("PROBE the teleport landed " .. tostring(dx) .. " tiles from the click, on floor " .. tostring(p:getZ()) .. " (the game's /teleportto with z 0)")
    say("TODO: stand in a safehouse, take from a crate, and read the container line in the ZeD log within 4 seconds")
    say("TODO: run mp_extras_two.lua on the second client now; this client's truck stays claimed")
    say("TODO: /save, restart the server, and claim with this client again: the answer must be 'taken' (the sql id outlives a restart)")
    Events.OnServerCommand.Remove(tap)
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
