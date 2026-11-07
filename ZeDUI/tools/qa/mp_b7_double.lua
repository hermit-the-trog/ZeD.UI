-- ZeDUI/tools/qa/mp_b7_double.lua  (Nov 7 2026, QA; merge 1, claims): on the admin client: bob's invitation shows as a note; Accept
-- twice in a row, as a held pad button or a double click sends it. The second must come back "wait" and send nothing: no kick,
-- and the admin joins once. grep "ZEDQA adb".
local function say(s) print("ZEDQA adb " .. tostring(s)) end
local function pass(n, ok, d) say((ok and "PASS " or "FAIL ") .. n .. (d ~= nil and (" (" .. tostring(d) .. ")") or "")) end
local C = ZeD.Claims
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local r1, r2
add(500, function() C.ask() end)
add(20000, function()
    local inv = C.invites[1]
    pass("bob's invitation shows", inv ~= nil, #C.invites)
    if not inv then return end
    C.answer(inv, true, function(ok, why) r1 = { ok = ok, why = why } end)
    C.answer(inv, true, function(ok, why) r2 = { ok = ok, why = why }; say("second Accept answered: ok " .. tostring(ok) .. ", why " .. tostring(why)) end)
    say("the wait message reads: " .. tostring(ZeD.tr("UI_ZeD_Cl_AnswerWait")))
end)
add(12000, function() C.refresh() end)
add(3000, function()
    pass("the second Accept says to wait", r2 ~= nil and r2.ok == false and r2.why == "wait", r2 and (tostring(r2.ok) .. "/" .. tostring(r2.why)))
    pass("the first Accept joins", r1 ~= nil and r1.ok == true, r1 and tostring(r1.ok))
    pass("still on the server (no kick)", getPlayer() ~= nil and isClient(), tostring(isClient()))
    say("member of " .. tostring(C.safe and C.safe.title))
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
