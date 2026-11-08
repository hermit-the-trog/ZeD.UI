-- ZeDUI/tools/qa/zedqa_b8_mp_mail_offline_read.lua (one body, two files: _send and _read; Nov 7 2026, QA; beta 8): on the ADMIN client, the offline half of the mail check
-- (CHECK_desk_notes_mail_20261107.md "For QA in game" 5). Mode read.
--   send: bob is off the server (at his desk). The admin writes him "b8 offline letter"; the server holds it until bob dials in.
--   read: after bob's rejoin, the letter bob wrote AT THE DESK ("b8 from the desk", put in his Outbox at the main menu) has gone up at
--         his dial-in and come down here; it is removed from the admin's copy after being read.
-- grep "ZEDQA b8mos" (send) or "b8mor" (read).
local TAG = "b8mor"
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
if "read" == "send" then
    add(500, function()
        check(getPlayerFromUsername("bob") == nil, "bob is off the server")
        check(Ml.state == "on", "the admin is dialed in", tostring(Ml.state))
        local m, err = Ml.write("bob", "b8 offline letter", "Written while you were at the desk. The server keeps it until you dial in.")
        check(m ~= nil, "a letter for an offline player goes to the Outbox", err)
    end)
    waitFor(30000, function() local d = data(); return d and #d.outbox == 0 end, function(to)
        check(not to, "the server took it for later (Outbox empty)")
        local d = data()
        local b = box()
        if d and b then
            local drop = {}
            for _, m in ipairs(d.sent) do if m.subj == "b8 offline letter" then drop[#drop + 1] = m end end
            for _, m in ipairs(drop) do MS.remove(b, "sent", m) end
        end
    end)
else
    waitFor(240000, function() return inboxHas("b8 from the desk") ~= nil end, function(to)
        check(not to, "the letter written at the desk went up at bob's dial-in and came down here", to and "not within 4 minutes" or nil)
        local m = inboxHas("b8 from the desk")
        if m then
            check(m.from == "bob", "it names bob", m.from)
            check(has(m.text, "desk"), "the words came whole", m.text)
            local b = box()
            MS.remove(b, "inbox", m)
        end
        check(inboxHas("b8 from the desk") == nil, "the admin's copy has none of this run's letters left (restored)")
    end)
end
Events.OnTick.Add(drive)
