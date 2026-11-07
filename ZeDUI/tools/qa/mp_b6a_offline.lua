-- ZeDUI/tools/qa/mp_b6a_offline.lua  (Nov 6 2026, QA; beta 6a, a real second player): on bob's client, just back on the server: an invitation sent while he was away shows, then Accept makes him a member. grep "ZEDQA aof".
local function say(s) print("ZEDQA aof " .. tostring(s)) end
local function pass(n, ok, d) say((ok and "PASS " or "FAIL ") .. n .. (d ~= nil and (" (" .. tostring(d) .. ")") or "")) end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local C = ZeD.Claims
add(500, function() C.ask() end)
add(40000, function()
    pass("the invitation sent while offline shows", #C.invites == 1, #C.invites)
    if C.invites[1] then say("from " .. tostring(C.invites[1].host) .. ": " .. tostring(C.invites[1].name)); C.answer(C.invites[1], true) end
end)
add(9000, function() C.refresh() end)
add(3000, function()
    pass("Accept: bob holds the house", C.safe ~= nil or SafeHouse.hasSafehouse(getPlayer()) ~= nil, C.safe and C.safe.title)
    pass("no note left", #C.invites == 0, #C.invites)
end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
    if i > #plan then say("DONE") end
end
Events.OnTick.Add(drive)
