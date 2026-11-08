-- ZeDUI/tools/qa/zedqa_b8_mp_rules_gate.lua / _kick.lua (one body; Nov 7 2026, QA; beta 8): on the ADMIN client, the join rules of MP_SERVER_PART_DESIGN.md (E-chapter, "join rules
-- gate and kick"). Mode kick. The admin turns "ask at joining" on with two rules (ZeD.Community.save), prints RULES SET, and waits for bob to
-- JOIN (the batch kicks him off the earlier session first and rejoins him; bob has to be a fresh join to be asked). gate: bob's script
-- (zedqa_b8_mp_bob_join_gate.lua) sees the screen, is refused a ZeD command, agrees and is let in; this script then waits 150 s and restores.
-- kick: bob (zedqa_b8_mp_bob_join_silent.lua) does not answer; the server's walk owes a Kick after Cm.L.ASKED_MS (5 minutes) and this
-- admin client, a staff client, makes it: bob is gone within about 6 minutes (the batch runs this mode only with -Slow). The rules,
-- the ask and the news are put back as they were at the end either way. grep "ZEDQA b8ru" (gate) or "b8rk" (kick).
local TAG = "b8rk"
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
local Cm = ZeD.Community
local AdmM = ZeD.Admin
local voiceN = 0
local function tap(module, command, args)
    if module == ZeD.Adm.MOD and command == "a_owed" and type(args) == "table" and args.act == "VoiceBan" then voiceN = voiceN + 1 end
end
Events.OnServerCommand.Add(tap)
local orig
local ans
local MODE = "kick"
local function bobOn() return getPlayerFromUsername("bob") ~= nil end
local function copyRules(v)
    local r = { n = 0 }
    for i = 1, (v and v.rules and v.rules.n or 0) do
        r.n = r.n + 1
        r[r.n] = { id = v.rules[i].id, text = v.rules[i].text }
    end
    return r
end
local function sameAsOrig()
    local v = Cm.view
    if not (v and orig) then return false end
    if (v.ask == true) ~= (orig.ask == true) then return false end
    if (v.rules and v.rules.n or 0) ~= (orig.rules and orig.rules.n or 0) then return false end
    return (v.motd or "") == (orig.motd or "") and (v.appeal or "") == (orig.appeal or "")
end
add(500, function()
    Cm.get()
end)
waitFor(10000, function() return Cm.view ~= nil end, function(to)
    check(not to, "the admin holds the community view", to and "none" or nil)
    if not Cm.view then return end
    local v = Cm.view
    orig = { motd = v.motd, appeal = v.appeal, ask = v.ask, reask = v.reask, base = v.base, rules = copyRules(v) }
    note("before: ask " .. tostring(v.ask) .. ", " .. tostring(orig.rules.n) .. " rules, motd '" .. tostring(v.motd) .. "'")
    check(Cm.canRules(), "the admin may write the rules")
    local d = { motd = orig.motd or "", appeal = orig.appeal or "", ask = true, reask = false, base = orig.base,
        rules = { n = 2, { text = "B8 rule one: be kind to the other survivors." }, { text = "B8 rule two: no griefing the farms." } } }
    Cm.save(d, function(a) ans = a end)
end)
waitFor(15000, function() return ans ~= nil end, function(to)
    check(not to and ans and ans.ok ~= false, "the rules were saved with ask on", ans and (tostring(ans.ok) .. "/" .. tostring(ans.err)) or "no answer")
end)
waitFor(10000, function() return Cm.view and Cm.view.ask == true and Cm.view.rules and Cm.view.rules.n == 2 end, function(to)
    check(not to, "the admin's view shows two rules and ask on", to and "not seen" or nil)
    say("RULES SET")
end)
-- bob joins fresh
waitFor(900000, bobOn, function(to)
    check(not to, "bob joined after the rules were set", to and "not in 15 minutes" or nil)
    note("bob is on; mode " .. MODE)
end)
if MODE == "gate" then
    add(150000, function()
        check(bobOn(), "gate: bob is still on after agreeing (a kick is for the unanswered)")
    end)
else
    waitFor(420000, function() return not bobOn() end, function(to)
        check(not to, "kick: the unanswered rules cost bob his place (the Kick was owed to this staff client and made)", to and "still on after 7 minutes" or nil)
    end)
end
-- the offline mute (zedqa_b8_mp_mute_set.lua) is owed as a voice ban at this join
add(500, function()
    if AdmM.isMuted("bob") then
        check(voiceN >= 1, "E27: the voice ban for an offline mute was owed to this staff client when bob joined", voiceN)
    else
        note("bob is not muted: the voice-ban part is skipped")
    end
    Events.OnServerCommand.Remove(tap)
end)
-- put the rules back
add(500, function()
    ans = nil
    if orig then Cm.save(orig, function(a) ans = a end) end
end)
waitFor(15000, function() return ans ~= nil end, function(to)
    check(not to and ans and ans.ok ~= false, "the rules are put back", ans and (tostring(ans.ok) .. "/" .. tostring(ans.err)) or "no answer")
end)
waitFor(10000, sameAsOrig, function(to)
    check(not to, "the admin's view matches what it was (restored)", to and "differs" or nil)
end)
Events.OnTick.Add(drive)
