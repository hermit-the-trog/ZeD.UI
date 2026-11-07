-- ZeDUI/tools/qa/mp_b6a_unmuted.lua  (Nov 6 2026, QA; beta 6a, a real second player): on bob's client: the mute lifted, chat goes again. grep "ZEDQA aum".
local function say(s) print("ZEDQA aum " .. tostring(s)) end
local function pass(n, ok, d) say((ok and "PASS " or "FAIL ") .. n .. (d ~= nil and (" (" .. tostring(d) .. ")") or "")) end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local C = ZeD.Claims
add(4000, function()
    pass("bob reads himself clear", not ZeD.Admin.isMuted(getPlayer():getUsername()))
    local ok, why = ZeD.Chat.send("/all back again")
    pass("/all goes", ok == true, tostring(ok) .. "," .. tostring(why))
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
