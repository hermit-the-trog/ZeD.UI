-- ZeDUI/tools/qa/zedqa_b8_mp_bob_mail_offline.lua  (Nov 7 2026, QA; beta 8): on BOB's client, after the rejoin that follows zedqa_b8_mp_mail_offline_send.lua and the desk script (which put "b8 from the desk"
-- in bob's Outbox at the main menu). Checks, within 3 minutes of the dial-in: the admin's "b8 offline letter" came down (it was waiting
-- on the server), the desk letter went up (Outbox empty, the letter in Sent), the modem played once and the note went through
-- Messages. Removes this run's letters from bob's copy. grep "ZEDQA b8bmo".
local TAG = "b8bmo"
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
local Ml = ZeD.Mail
local MS = ZeD.MailStore
local function box() return Ml.box() end
local function data() local b = box(); return b and MS.load(b) or nil end
local function find(folder, subj)
    local d = data()
    for _, m in ipairs(d and d[folder] or {}) do if m.subj == subj then return m end end
    return nil
end
waitFor(120000, function() return Ml.state == "on" end, function(to)
    check(not to, "bob is dialed in again after the rejoin", tostring(Ml.state) .. "/" .. tostring(Ml.why))
    local b0 = box()
    local age = b0 and (getTimestamp() - (b0.t or 0)) or -1
    check(b0 ~= nil and age >= 0 and age < 240, "a new dial-in was made on this join (the mailbox dial time is recent)", tostring(age) .. " s ago")
    check(Ml.rang == true, "the modem handshake played on this join", tostring(Ml.rang))
    check(has(Ml.lastNote, "connecting"), "the Connecting note went through Messages", tostring(Ml.lastNote))
    local ok, playing = pcall(function() return getSoundManager():isPlayingUISound("ZeDModemDial") end)
    note("the modem sound playing right now: " .. tostring(ok and playing))
end)
waitFor(120000, function() return find("inbox", "b8 offline letter") ~= nil end, function(to)
    check(not to, "the letter written while bob was away came down on his dial-in", to and "not within 2 minutes" or nil)
    local m = find("inbox", "b8 offline letter")
    if m then check(has(m.text, "keeps it"), "the words came whole", m.text) end
end)
waitFor(120000, function() local d = data(); return d and #d.outbox == 0 end, function(to)
    check(not to, "the Outbox written at the desk went up on the join (empty now)")
    check(find("sent", "b8 from the desk") ~= nil, "the desk letter is in Sent", find("sent", "b8 from the desk") ~= nil)
    ticks(20, function() shot("mail_bob_after_join") end)
end)
add(2000, function()
    local d = data()
    local b = box()
    if d and b then
        local drop = {}
        for _, m in ipairs(d.inbox) do if m.subj == "b8 offline letter" then drop[#drop + 1] = m end end
        for _, m in ipairs(drop) do MS.remove(b, "inbox", m) end
        local sdrop = {}
        for _, m in ipairs(d.sent) do if m.subj == "b8 from the desk" then sdrop[#sdrop + 1] = m end end
        for _, m in ipairs(sdrop) do MS.remove(b, "sent", m) end
    end
end)
Events.OnTick.Add(drive)
