-- ZeDUI/tools/qa/mp_b7_fetch_bob.lua  (Nov 7 2026, QA): on the admin client, standing in its safehouse: bob brought to the admin (the
-- server's /teleport), so bob stands in the same building. grep "ZEDQA fbb".
local function say(s) print("ZEDQA fbb " .. tostring(s)) end
local C = ZeD.Claims
local me = getPlayer():getUsername()
local n = 0
local function tick()
    n = n + 1
    if n == 10 then
        C.refresh()
        SendCommandToServer('/teleport "bob" "' .. me .. '"')
        say("bob sent to " .. me .. " at " .. math.floor(getPlayer():getX()) .. "," .. math.floor(getPlayer():getY()))
    end
    if n == 300 then
        local b = getPlayerFromUsername("bob")
        say("house " .. tostring(C.safe and C.safe.title) .. "; bob " .. (b and string.format("at %d,%d", math.floor(b:getX()), math.floor(b:getY())) or "not seen"))
        say("DONE")
        Events.OnTick.Remove(tick)
    end
end
Events.OnTick.Add(tick)
