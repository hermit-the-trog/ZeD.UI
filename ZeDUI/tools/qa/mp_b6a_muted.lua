-- ZeDUI/tools/qa/mp_b6a_muted.lua  (Nov 6 2026, QA; beta 6a, a real second player): on bob's client, muted: plain chat and every chat stream refused, where beta 6 let the slash ones through. grep "ZEDQA amd".
local function say(s) print("ZEDQA amd " .. tostring(s)) end
local function pass(n, ok, d) say((ok and "PASS " or "FAIL ") .. n .. (d ~= nil and (" (" .. tostring(d) .. ")") or "")) end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local C = ZeD.Claims
add(4000, function()
    pass("bob reads himself muted", ZeD.Admin.isMuted(getPlayer():getUsername()))
    for _, t in ipairs({ "plain line", "/all hi", "/s hi", "/y hi", "/w zedqa hi", "/safehouse hi", "/roll 6" }) do
        local ok, why = ZeD.Chat.send(t)
        pass("refused: " .. t, ok == false and why == "muted", tostring(ok) .. "," .. tostring(why))
    end
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
