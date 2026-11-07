-- ZeDUI/tools/qa/mp_b7_reclaim.lua  (Nov 7 2026, QA; merge 1, claims): on bob's client, standing in the admin's safehouse: claim it
-- the moment the game lets him (the admin releases it, mp_b7_release.lua), within 90 s. grep "ZEDQA brc".
local function say(s) print("ZEDQA brc " .. tostring(s)) end
local C = ZeD.Claims
local t0, last, done_ = getTimestampMs(), 0, false
local function tick()
    local now = getTimestampMs()
    if done_ then return end
    if now - t0 > 90000 then say("no claim in 90 s"); say("DONE"); done_ = true; Events.OnTick.Remove(tick); return end
    if now - last < 250 then return end
    last = now
    C.claim = nil
    local ok, a = pcall(C.claimCheck)
    if ok and a and a.ok then
        say("free: claiming (clock " .. now .. ")")
        C.doClaim(function(r) say("claim done: " .. tostring(r) .. " (clock " .. getTimestampMs() .. ")"); say("DONE") end)
        done_ = true
        Events.OnTick.Remove(tick)
    end
end
say("watching from " .. math.floor(getPlayer():getX()) .. "," .. math.floor(getPlayer():getY()))
Events.OnTick.Add(tick)
