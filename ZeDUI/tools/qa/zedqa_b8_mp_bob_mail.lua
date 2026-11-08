-- ZeDUI/tools/qa/zedqa_b8_mp_bob_mail.lua  (Nov 7 2026, QA; beta 8): on BOB's client, the other side of zedqa_b8_mp_mail.lua (start it first; it waits up to 4 minutes). bob is dialed in,
-- the admin's letter "b8 hello" arrives and is kept on this computer, bob answers it with "b8 re: hello", and the letters of the run are
-- removed from bob's copy. grep "ZEDQA b8bml".
local TAG = "b8bml"
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
local function inboxHas(subj)
    local d = data()
    for _, m in ipairs(d and d.inbox or {}) do if m.subj == subj then return m end end
    return nil
end
local from
add(500, function()
    check(Ml.live(), "bob: the server keeps mail")
end)
waitFor(60000, function() return Ml.state == "on" end, function(to)
    check(not to, "bob dialed in (state on)", tostring(Ml.state) .. "/" .. tostring(Ml.why))
    check(Ml.rang == true, "bob: the modem handshake played once", tostring(Ml.rang))
end)
waitFor(180000, function() return inboxHas("b8 hello") ~= nil end, function(to)
    check(not to, "5: the admin's letter came down to bob", to and "no letter in 3 minutes" or nil)
    local m = inboxHas("b8 hello")
    if not m then return end
    from = m.from
    check(m.from ~= "" and m.from ~= nil, "5: it names the sender", m.from)
    check(m.read == false, "5: it is unread")
    check(has(m.text, "plain"), "5: the words came whole", m.text)
    local note = ZeD.Messages and ZeD.Messages.sources and ZeD.Messages.sources[ZeD.tr("UI_ZeD_Mail_Title")]
    check(note ~= nil, "5: a note sits in Messages under Mail's name")
    ticks(20, function() shot("mail_bob_inbox") end)
    local r, err = Ml.write(from, "b8 re: hello", "A reply from bob, word for word.")
    check(r ~= nil, "5: bob's reply goes to the Outbox", err)
end)
waitFor(30000, function() local d = data(); return d and #d.outbox == 0 end, function(to)
    check(not to, "5: bob's Outbox emptied (the server took the reply)")
end)
add(3000, function()
    local d = data()
    local b = box()
    if d and b then
        local drop = {}
        for _, m in ipairs(d.inbox) do if m.subj == "b8 hello" then drop[#drop + 1] = m end end
        for _, m in ipairs(drop) do MS.remove(b, "inbox", m) end
        local sdrop = {}
        for _, m in ipairs(d.sent) do if m.subj == "b8 re: hello" then sdrop[#sdrop + 1] = m end end
        for _, m in ipairs(sdrop) do MS.remove(b, "sent", m) end
    end
end)
Events.OnTick.Add(drive)
