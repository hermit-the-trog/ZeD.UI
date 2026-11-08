-- ZeDUI/tools/qa/zedqa_b8_mp_kick.lua  (Nov 7 2026, QA; beta 8): on the ADMIN client, CHECK_mp_leftovers C1 step 3 and C17 step 1: kick bob through ZeD's Admin
-- (ZeD.Admin.kick, what the Player card's Kick button and the pause page's Kick lead to), with zedqa_b8_mp_bob_leave_kick.lua waiting on
-- bob's client. bob is the ONLY target. Checks the server part took it, the game's kick landed (bob is gone from the player list within
-- 40 s) and the admin is still on. Nothing to undo: a kick leaves no record to lift. grep "ZEDQA b8kk".
local TAG = "b8kk"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local npass, nfail = 0, 0
local function check(ok, what, d)
    ok = ok and true or false
    if ok then npass = npass + 1 else nfail = nfail + 1 end
    say((ok and "PASS " or "FAIL ") .. what .. (d ~= nil and (" (" .. tostring(d) .. ")") or ""))
end
local function note(s) say("NOTE " .. tostring(s)) end
local function manual(s) say("MANUAL " .. tostring(s)) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b8_" .. n .. ".png") end) end
local function safe(fn, d) local ok, v = pcall(fn); if ok and v ~= nil then return v end; return d end
local function has(s, w) return type(s) == "string" and w ~= nil and string.find(string.lower(s), string.lower(w), 1, true) ~= nil end
local function keepDown() pcall(function()
    for _, get in ipairs({ ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow, ZeD_WorldWindow and ZeD_WorldWindow.getWindow }) do
        local w = get and get()
        if w then w._autoShaded = false; if w.windowShaded and w.setWindowShaded then w:setWindowShaded(false) end; w._outSince = getTimestampMs() + 600000 end
    end
end) end
local plan, pi, pt = {}, 1, getTimestampMs()
local ins = nil
local function push(e) if ins then table.insert(plan, ins, e); ins = ins + 1 else plan[#plan + 1] = e end end
local function add(ms, fn) push({ ms = ms, fn = fn }) end
local function ticks(n, fn) push({ ticks = n, fn = fn }) end
local function waitFor(maxMs, cond, fn) push({ cond = cond, max = maxMs, fn = fn }) end
local function drive()
    local st = plan[pi]
    if not st then return end
    local now = getTimestampMs()
    local timedOut = false
    if st.ticks then
        st.ticks = st.ticks - 1
        if st.ticks > 0 then return end
    elseif st.cond then
        if not st.started then st.started = now end
        local ok, v = pcall(st.cond)
        if not (ok and v) and now - st.started < st.max then return end
        timedOut = not (ok and v)
    elseif now - pt < st.ms then return end
    pt = now
    pi = pi + 1
    keepDown()
    ins = pi
    local ok, e = pcall(st.fn, timedOut)
    ins = nil
    if not ok then nfail = nfail + 1; say("FAIL ERR step " .. (pi - 1) .. ": " .. tostring(e)) end
    if pi > #plan then
        say(npass .. " passed, " .. nfail .. " failed")
        say("DONE")
        Events.OnTick.Remove(drive)
    end
end
local M = ZeD.Admin
local p = getPlayer()
local ans
local function bobOn() return getPlayerFromUsername("bob") ~= nil end
add(500, function()
    check(bobOn(), "bob is on the server before the kick")
    check(M.can("KickUser"), "the admin may kick")
    M.kick("bob", "b8 QA kick check", function(a) ans = a end)
end)
waitFor(15000, function() return ans ~= nil end, function(to)
    check(not to and ans and ans.ok ~= false, "the kick was accepted", ans and (tostring(ans.ok) .. "/" .. tostring(ans.err)) or "no answer")
end)
waitFor(60000, function() return not bobOn() end, function(to)
    check(not to, "bob is gone from the player list", to and "still on after 60 s" or nil)
end)
add(500, function()
    check(isClient() and getPlayer() == p, "the admin is still on the server")
    manual("C17 1: bob's screen: the room, the monitor, the window 'Disconnected' with 'You were kicked from the server.' and the game's words in the dark slot (zedqa_b8_mp_bob_leave_kick.lua read the rest)")
end)
Events.OnTick.Add(drive)
