-- ZeDUI/tools/qa/zedqa_b8_mp_mail.lua  (Nov 7 2026, QA; beta 8): on the ADMIN client, CHECK_desk_notes_mail_20261107.md "For QA in game" 5, the mail with two real players, live half
-- (zedqa_b8_mp_bob_mail.lua on bob's client, started first). The admin is dialed in (the modem played once this connection, the
-- "Connecting..." note went through Messages), writes bob a letter, bob's reply comes down at once, a letter to nobody comes back as
-- returned mail, and the letters this run made are removed from the admin's copy at the end. The server keeps nothing: a handed-over
-- letter is forgotten. The offline half (a letter for bob while he is at the desk, his Outbox going up at the next join) is
-- zedqa_b8_mp_mail_offline.lua. Manual: the sound itself (turn the UI volume up), Report on a received letter, Mute hiding a sender's
-- letters, 10 letters of 2,000 characters in one batch. grep "ZEDQA b8ml".
local TAG = "b8ml"
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
local Msgs = ZeD.Messages
local p = getPlayer()
local me = p:getUsername()
local function box() return Ml.box() end
local function data() local b = box(); return b and MS.load(b) or nil end
local function inboxHas(subj)
    local d = data()
    for _, m in ipairs(d and d.inbox or {}) do if m.subj == subj then return m end end
    return nil
end
local function outboxN() local d = data(); return d and #d.outbox or -1 end
local function sentHas(subj)
    local d = data()
    for _, m in ipairs(d and d.sent or {}) do if m.subj == subj then return m end end
    return nil
end

add(500, function()
    check(Ml.live(), "the server keeps mail (the hello said so)")
    check(box() ~= nil, "the admin's mailbox on this computer exists")
end)
waitFor(60000, function() return Ml.state == "on" end, function(to)
    check(not to, "5: the admin dialed in on joining (state on)", tostring(Ml.state) .. "/" .. tostring(Ml.why))
    check(Ml.rang == true, "5: the modem handshake played once this connection", tostring(Ml.rang))
    check(has(Ml.lastNote, "connecting"), "5: the connecting note went through Messages", tostring(Ml.lastNote))
    local ok, playing = pcall(function() return getSoundManager():isPlayingUISound("ZeDModemDial") end)
    note("the modem sound playing right now: " .. tostring(ok and playing))
    local name = ZeD.tr("UI_ZeD_Mail_Title")
    local s = Msgs and Msgs.sources and Msgs.sources[name]
    check(s ~= nil and #s.items >= 1, "5: Messages keeps an item under Mail's name", s and #s.items)
end)
add(500, function()
    local m, err = Ml.write("bob", "b8 hello", "Hello bob, this is the admin. The words of this letter are plain.")
    check(m ~= nil, "5: a letter written in game goes to the Outbox and on its way", err)
end)
waitFor(30000, function() return outboxN() == 0 and sentHas("b8 hello") ~= nil end, function(to)
    check(not to, "5: the server took it: Outbox empty, the letter in Sent", "outbox " .. outboxN())
end)
waitFor(60000, function() return inboxHas("b8 re: hello") ~= nil end, function(to)
    check(not to, "5: bob's reply came down at once while both are on", to and "no reply in 60 s" or nil)
    local m = inboxHas("b8 re: hello")
    if m then
        check(m.from == "bob", "5: the sender is the player the server saw (bob)", m.from)
        check(m.read == false, "5: it arrives unread")
        check(has(m.text, "reply"), "5: the words came whole", m.text)
        local b = box()
        check(MS.unread(b) >= 1, "5: the mailbox counts it unread", MS.unread(b))
    end
    ticks(20, function() shot("mail_live") end)
end)
add(500, function()
    local m = Ml.write("nobody_b8_x", "b8 to nobody", "This goes to a name the server has never seen.")
    check(m ~= nil, "5: a letter to an unknown name is accepted into the Outbox")
end)
waitFor(30000, function()
    local d = data()
    if not d or #d.outbox ~= 0 then return false end
    for _, x in ipairs(d.inbox) do if x.returned and x.subj == "b8 to nobody" then return true end end
    return false
end, function(to)
    check(not to, "5: it came back to the Inbox as returned mail and left the Outbox", to and "not returned" or nil)
end)
add(1500, function()
    -- the letters this run made go from the admin's copy
    local d = data()
    local b = box()
    if d and b then
        local drop = {}
        for _, m in ipairs(d.inbox) do if m.subj == "b8 re: hello" or m.subj == "b8 to nobody" then drop[#drop + 1] = m end end
        for _, m in ipairs(drop) do MS.remove(b, "inbox", m) end
        local sdrop = {}
        for _, m in ipairs(d.sent) do if m.subj == "b8 hello" then sdrop[#sdrop + 1] = m end end
        for _, m in ipairs(sdrop) do MS.remove(b, "sent", m) end
    end
    check(inboxHas("b8 re: hello") == nil and sentHas("b8 hello") == nil, "the admin's copy has none of this run's letters left (restored)")
end)
Events.OnTick.Add(drive)
