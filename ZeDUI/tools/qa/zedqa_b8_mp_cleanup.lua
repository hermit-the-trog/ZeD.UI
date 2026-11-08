-- ZeDUI/tools/qa/zedqa_b8_mp_cleanup.lua  (Nov 7 2026, QA; beta 8): on the ADMIN client, the safety net at the end of batch_b8_mp.ps1 (and by hand after a run that stopped half way): puts back on the local
-- test server everything the b8 multiplayer scripts change, whatever step they stopped at. bob's ban row in ZeD and in the game, bob's
-- mute, bob's safehouse and faction, the QA zones, and the join rules if they still read "B8 rule" (ask off, no rules). Idempotent: with
-- nothing to put back it prints PASS lines and nothing is sent. Never bans or kicks anyone. grep "ZEDQA b8cu".
local TAG = "b8cu"
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
local Cm = ZeD.Community
local C = ZeD.Claims
local watching, wn = true, 0
local function watch()
    wn = wn + 1
    if watching and wn % 30 == 0 then pcall(M.watch) end
end
Events.OnTick.Add(watch)
local function gameRole(name)
    local r
    pcall(function()
        local l = getUsers()
        for i = 0, l:size() - 1 do
            if l:get(i):getUsername() == name then r = l:get(i):getRole():getName() end
        end
    end)
    return r
end
local function bobHouse()
    local l = SafeHouse.getSafehouseList()
    for i = 0, l:size() - 1 do if l:get(i):getOwner() == "bob" then return l:get(i) end end
    return nil
end
local function bobFaction()
    local l = Faction.getFactions()
    for i = 0, l:size() - 1 do if l:get(i):getOwner() == "bob" then return l:get(i) end end
    return nil
end
add(1000, function()
    pcall(requestUsers)
    pcall(Cm.get)
end)
add(3000, function()
    local b = M.banOf("bob")
    if b then
        note("a ban on bob was left: lifting it through ZeD")
        M.unban(b, function() end)
    end
    if gameRole("bob") == "banned" then
        note("bob is banned in the game: /unbanuser")
        SendCommandToServer('/unbanuser "bob"')
    end
    if M.isMuted("bob") then
        note("bob is muted: unmuting")
        M.mute("bob", false, function() end)
    end
    local h = bobHouse()
    if h then note("bob's safehouse is left: releasing"); pcall(sendSafehouseRelease, h) end
    local f = bobFaction()
    if f then note("bob's faction is left: disbanding"); pcall(sendFactionDisband, f) end
    for _, t in ipairs({ "QA b8 zone", "QA b8 zone 2" }) do pcall(NonPvpZone.removeNonPvpZone, t) end
    local l = SafeHouse.getSafehouseList()
    for i = l:size() - 1, 0, -1 do
        if l:get(i):getTitle() == "QA b8 safe" then pcall(sendSafehouseRelease, l:get(i)) end
    end
    local v = Cm.view
    if v and v.rules and v.rules.n >= 1 and has(v.rules[1].text, "B8 rule") then
        note("the B8 rules are still on: putting the join rules back off")
        Cm.save({ motd = v.motd or "", appeal = v.appeal or "", ask = false, reask = false, base = v.base, rules = { n = 0 } }, function() end)
    end
end)
add(12000, function()
    pcall(requestUsers)
end)
add(3000, function()
    check(M.banOf("bob") == nil, "no ZeD ban row on bob is left", tostring(M.banOf("bob") ~= nil))
    check(gameRole("bob") ~= "banned", "bob is not banned in the game", tostring(gameRole("bob")))
    check(not M.isMuted("bob"), "bob is not muted")
    check(bobHouse() == nil and bobFaction() == nil, "bob holds no safehouse and no faction")
    local v = Cm.view
    check(not (v and v.rules and v.rules.n >= 1 and has(v.rules[1].text, "B8 rule")), "no B8 rules are left on the join screen")
    watching = false
    Events.OnTick.Remove(watch)
end)
Events.OnTick.Add(drive)
