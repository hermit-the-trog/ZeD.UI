-- ZeDUI/tools/qa/mp_b6a_mute_off.lua  (Nov 6 2026, QA; beta 6a, a real second player): on the admin client: the mute off for bob. grep "ZEDQA amoff".
local function say(s) print("ZEDQA amoff " .. tostring(s)) end
local function pass(n, ok, d) say((ok and "PASS " or "FAIL ") .. n .. (d ~= nil and (" (" .. tostring(d) .. ")") or "")) end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local C = ZeD.Claims
add(500, function() ZeD.Admin.mute("bob", false, function(ok) say("answer " .. tostring(ok)) end) end)
add(4000, function() pass("the admin's list", ZeD.Admin.isMuted("bob") == false) end)
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
