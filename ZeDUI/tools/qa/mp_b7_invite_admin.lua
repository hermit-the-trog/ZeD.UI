-- ZeDUI/tools/qa/mp_b7_invite_admin.lua  (Nov 7 2026, QA; merge 1, claims): on bob's client, now holding the house: invite the
-- admin (the one account on the server other than bob). grep "ZEDQA bia".
local function say(s) print("ZEDQA bia " .. tostring(s)) end
local C = ZeD.Claims
local n = 0
local function tick()
    n = n + 1
    if n == 10 then C.refresh() end
    if n == 200 then
        local who
        local list = getOnlinePlayers()
        for k = 0, list:size() - 1 do local u = list:get(k):getUsername(); if u ~= "bob" then who = u end end
        say("bob holds " .. tostring(C.safe and C.safe.title) .. "; inviting " .. tostring(who))
        if who and C.safe then C.invite("safe", who) end
    end
    if n == 500 then say("DONE"); Events.OnTick.Remove(tick) end
end
Events.OnTick.Add(tick)
