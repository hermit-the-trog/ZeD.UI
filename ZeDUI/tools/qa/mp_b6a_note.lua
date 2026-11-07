-- ZeDUI/tools/qa/mp_b6a_note.lua  (Nov 6 2026, QA; beta 6a, a real second player): on bob's client: the invitation's note stands past two 30 s server replies, where beta 6's vanished in 6 to 36 s; then Decline. grep "ZEDQA anb".
local function say(s) print("ZEDQA anb " .. tostring(s)) end
local function pass(n, ok, d) say((ok and "PASS " or "FAIL ") .. n .. (d ~= nil and (" (" .. tostring(d) .. ")") or "")) end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local C = ZeD.Claims
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b6a_note_" .. n .. ".png") end) end
local function n() return #C.invites end
add(3000, function() pass("the note is up", n() == 1, n()); shot("1") end)
add(20000, function() pass("at 23 s", n() == 1, n()) end)
add(25000, function() pass("at 48 s", n() == 1, n()) end)
add(32000, function() pass("at 80 s", n() == 1, n()); shot("2"); if C.invites[1] then C.answer(C.invites[1], false) end end)
add(6000, function() pass("Decline clears it", n() == 0, n()) end)
add(35000, function() pass("it stays declined past a server reply", n() == 0, n()) end)
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
