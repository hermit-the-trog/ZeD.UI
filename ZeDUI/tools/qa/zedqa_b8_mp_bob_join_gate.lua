-- ZeDUI/tools/qa/zedqa_b8_mp_bob_join_gate.lua / _silent.lua (one body; Nov 7 2026, QA; beta 8): on BOB's client, right after a fresh join while the admin's rules are on
-- (zedqa_b8_mp_rules_*.lua). Mode gate. Both: the community view says this player is asked, with two rules; the join screen is up.
-- gate: a ZeD command (the mail dial-in) is refused ("perm") before agreeing; then bob agrees through the screen's Yes (or the same call),
-- the same command is answered after, and the mail dials by itself the moment he agrees. silent: nothing is answered and the script ends;
-- the admin's script watches for the Kick. grep "ZEDQA b8bj" (gate) or "b8bs2" (silent).
local TAG = "b8bj"
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
local Cm, Ml, K = ZeD.Community, ZeD.Ml, ZeD.Tickets
local MODE = "gate"
local function prompts()
    local out = {}
    local ui = UIManager.getUI()
    for i = ui:size() - 1, 0, -1 do
        local t = nil
        pcall(function() t = ui:get(i):getTable() end)
        if type(t) == "table" and t.Type == "ZeD_Prompt" and not t._dead and t:isVisible() then out[#out + 1] = t end
    end
    return out
end
local ans, ans2
add(500, function()
    check(Cm.view ~= nil, "the community view reached bob")
    local v = Cm.view or {}
    check(v.ask == true, "bob is asked to agree", tostring(v.ask))
    check(v.rules and v.rules.n == 2, "two rules arrived", v.rules and v.rules.n)
end)
waitFor(25000, function() return #prompts() > 0 end, function(to)
    local ps = prompts()
    check(not to, "the join screen with the rules is up", #ps .. " prompt(s)")
    ticks(30, function() shot("rules_" .. MODE) end)
end)
if MODE == "gate" then
    add(500, function()
        K.requestOn(Ml.MOD, "p_dial", { mutes = { n = 0 } }, function(a) ans = a end)
    end)
    waitFor(15000, function() return ans ~= nil end, function(to)
        note("before agreeing: " .. tostring(ans and (tostring(ans.ok) .. "/" .. tostring(ans.err))))
        check(ans ~= nil and ans.ok ~= true and ans.err == "perm", "gate: a ZeD command is refused before agreeing (perm)", ans and tostring(ans.err) or "no answer")
        local ps = prompts()
        local pressed = false
        for _, q in ipairs(ps) do
            if q.yes then q:press(q.yes); pressed = true; break end
        end
        if not pressed then Cm.agree() end
        note("agreed through " .. (pressed and "the screen's button" or "ZeD.Community.agree"))
    end)
    add(4000, function()
        K.requestOn(Ml.MOD, "p_dial", { mutes = { n = 0 } }, function(a) ans2 = a end)
    end)
    waitFor(15000, function() return ans2 ~= nil end, function(to)
        note("after agreeing: " .. tostring(ans2 and (tostring(ans2.ok) .. "/" .. tostring(ans2.err))))
        check(ans2 ~= nil and (ans2.ok == true or ans2.err == "wait"), "gate: after agreeing the same command is answered", ans2 and (tostring(ans2.ok) .. "/" .. tostring(ans2.err)) or "no answer")
    end)
    waitFor(30000, function() return ZeD.Mail.state == "on" end, function(to)
        check(not to, "gate: the mail dialed in by itself once he agreed (S.onAgreed)", tostring(ZeD.Mail.state) .. "/" .. tostring(ZeD.Mail.why))
        ticks(20, function() shot("rules_agreed") end)
    end)
else
    add(500, function()
        note("silent: not answering; the server owes a Kick after five minutes")
    end)
end
Events.OnTick.Add(drive)
