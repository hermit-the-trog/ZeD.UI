-- ZeDUI/tools/qa/zedqa_b8_mp_mute_set.lua / _after.lua (one body; Nov 7 2026, QA; beta 8): on the ADMIN client, the offline voice mute of MP_SERVER_PART_DESIGN.md (E27). Mode after.
--   set:   bob is OFF the server. The admin mutes him (ZeD.Admin.mute with here = false: the game's /voiceban finds only a player who is
--          on, so the server's list is the mute and the game is not asked). The mute shows on the admin's list.
--          The voice ban he then owes is checked by zedqa_b8_mp_rules_gate.lua, at bob's next join.
--   after: the voice ban lasts ONE connection (the game holds it by online ID). The admin kicks bob, bob rejoins (the batch) and the
--          server owes the voice ban again at that join (an a_owed VoiceBan to this staff client), then the admin unmutes him (the
--          game's /voiceban -false with him on) and the list is clear. Only bob is kicked, and the mute is cleared at the end.
-- Whether bob's microphone is really cut cannot be seen from a script: the voice test is manual. grep "ZEDQA b8mus" (set) or "b8mua" (after).
local TAG = "b8mua"
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
local voiceN = 0
local function tap(module, command, args)
    if module == ZeD.Adm.MOD and command == "a_owed" and type(args) == "table" and args.act == "VoiceBan" then voiceN = voiceN + 1 end
end
Events.OnServerCommand.Add(tap)
local watching, wn = true, 0
local function watch()
    wn = wn + 1
    if watching and wn % 30 == 0 then pcall(M.watch) end
end
Events.OnTick.Add(watch)
local function bobOn() return getPlayerFromUsername("bob") ~= nil end
local ans
if "after" == "set" then
    add(500, function()
        check(not bobOn(), "bob is off the server")
        M.mute("bob", true, function(a) ans = a end, false)
    end)
    waitFor(15000, function() return ans ~= nil end, function(to)
        check(not to and ans and ans.ok ~= false, "the server took the mute for an offline player", ans and (tostring(ans.ok) .. "/" .. tostring(ans.err)) or "no answer")
    end)
    waitFor(20000, function() return M.isMuted("bob") end, function(to)
        check(not to, "bob shows as muted on the admin's list", to and "not on the list" or nil)
        check(M.muted("bob") == true, "the Player card would read Muted")
        manual("E27: the game's voice ban is NOT made while he is off (nothing to find); at his next join it is owed (see zedqa_b8_mp_rules_gate.lua)")
    end)
    add(500, function()
        watching = false
        Events.OnTick.Remove(watch)
        Events.OnServerCommand.Remove(tap)
    end)
else
    local kicked
    add(500, function()
        check(bobOn(), "bob is on the server before the second connection")
        check(M.isMuted("bob"), "bob is still muted on the list")
        say("KICKING BOB")
        M.kick("bob", "b8 mute reconnect", function(a) kicked = a end)
    end)
    waitFor(60000, function() return not bobOn() end, function(to)
        check(not to, "bob was kicked and is off", to and "still on" or nil)
        voiceN = 0
        say("BOB MAY JOIN AGAIN")
    end)
    waitFor(900000, bobOn, function(to)
        check(not to, "bob rejoined", to and "not within 15 minutes" or nil)
    end)
    waitFor(120000, function() return voiceN >= 1 end, function(to)
        check(not to, "E27: the voice ban was owed again at the new connection (it lasts one connection)", voiceN)
    end)
    add(1500, function()
        ans = nil
        M.mute("bob", false, function(a) ans = a end)
    end)
    waitFor(15000, function() return ans ~= nil end, function(to)
        check(not to and ans and ans.ok ~= false, "the unmute was accepted", ans and (tostring(ans.ok) .. "/" .. tostring(ans.err)) or "no answer")
    end)
    waitFor(20000, function() return not M.isMuted("bob") end, function(to)
        check(not to, "bob is off the mute list (restored)", to and "still muted" or nil)
        watching = false
        Events.OnTick.Remove(watch)
        Events.OnServerCommand.Remove(tap)
        manual("E27: with a second microphone, a muted bob is not heard on his first or second connection; a third player given his freed online ID is heard")
    end)
end
Events.OnTick.Add(drive)
