-- ZeDUI/tools/qa/zedqa_b8_mp_bans.lua  (Nov 7 2026, QA; beta 8): on the ADMIN client, the multiplayer rules of MP_SERVER_PART_DESIGN.md (E-chapter, "timed bans as
-- the game's ban" and "the game's unban wins") against bob, who must be on the server with zedqa_b8_mp_bob_leave_ban.lua waiting. Only
-- bob is ever banned, only by name, never by IP (the admin shares his address), and every ban made here is lifted again before the
-- script ends (the last step unbans through ZeD and, if a ban is still held, through the game).
--   Part 1: a 1-hour ban through ZeD (M.ban, len h1): ZeD's row with its end time, the game's own ban follows from the server (bob's role
--           in the game's user list reads banned), bob is told to leave and is gone, he cannot come back (the batch makes bob try, and
--           this script waits 45 s for him not to appear), then ZeD's Unban: the row goes, the game's ban is lifted (role back to user).
--   Part 2: bob (rejoined by the batch) is banned again, then the GAME's own /unbanuser is typed: ZeD's row must close by itself, nothing
--           lifted by ZeD (E26's look at the game's user list).
-- The owed calls the admin client was asked to make are counted (tap on a_owed). grep "ZEDQA b8bn".
local TAG = "b8bn"
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
local Adm = ZeD.Adm
local M = ZeD.Admin
local owed = {}
local function tap(module, command, args)
    if module == Adm.MOD and command == "a_owed" and type(args) == "table" then owed[#owed + 1] = tostring(args.act) .. ":" .. tostring(args.target) end
end
Events.OnServerCommand.Add(tap)
local watching = true
local wn = 0
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
local function bobOn() return getPlayerFromUsername("bob") ~= nil end
local ans1, ans2

-- ---- part 1
add(500, function()
    check(bobOn(), "bob is on the server before the ban")
    check(M.live(), "ZeD's server part answers (bans are ZeD's)")
    check(M.can("BanUnbanUser"), "the admin may ban")
    pcall(requestUsers)
end)
add(3000, function()
    check(gameRole("bob") == "user" or gameRole("bob") == nil, "bob is a plain user in the game's list", gameRole("bob"))
    M.ban("bob", "b8 QA timed ban", "h1", false, function(a) ans1 = a end)
end)
waitFor(15000, function() return ans1 ~= nil end, function(to)
    check(not to and ans1 and ans1.ok == true, "1: the ban was accepted by the server part", ans1 and (tostring(ans1.ok) .. "/" .. tostring(ans1.err)) or "no answer")
end)
waitFor(20000, function() return M.banOf("bob") ~= nil end, function(to)
    local b = M.banOf("bob")
    check(not to and b ~= nil, "1: ZeD's Bans list holds a row for bob", to and "none" or nil)
    if b then
        local left = (b.untilT or 0) - getTimestamp()
        note("the row: id " .. tostring(b.id) .. ", ends in " .. tostring(left) .. " s, reason '" .. tostring(b.reason) .. "', banIp " .. tostring(b.banIp))
        check(b.untilT ~= nil and left > 3300 and left < 3700, "1: it is a timed ban of about an hour", left)
        check(not b.banIp, "1: no IP ban (a timed ban never carries one)")
    end
end)
waitFor(90000, function() return gameRole("bob") == "banned" end, function(to)
    check(not to, "1: the game's own ban follows from the server (bob's role reads banned in the game's list)", gameRole("bob"))
    local s = {}
    for _, o in ipairs(owed) do s[#s + 1] = o end
    note("calls owed to this client: " .. table.concat(s, ", "))
end)
waitFor(60000, function() return not bobOn() end, function(to)
    check(not to, "1: bob was told to leave and is gone", to and "still on" or nil)
end)
-- bob tries to come back during this wait (the batch starts his join attempt)
waitFor(45000, function() return bobOn() end, function(to)
    check(to, "1: bob could not come back while banned (45 s watched)", to and "stayed out" or "bob got in")
end)
local row1
add(500, function()
    row1 = M.banOf("bob")
    check(row1 ~= nil, "2: the ban row is still there to lift")
    if row1 then M.unban(row1, function(a) ans2 = a end) end
end)
waitFor(20000, function() return ans2 ~= nil end, function(to)
    check(not to and ans2 and ans2.ok ~= false, "2: ZeD's Unban was accepted", ans2 and (tostring(ans2.ok) .. "/" .. tostring(ans2.err)) or "no answer")
end)
waitFor(30000, function() return M.banOf("bob") == nil end, function(to)
    check(not to, "2: the row left the Bans list", to and "still listed" or nil)
end)
waitFor(120000, function() local r = gameRole("bob"); return r ~= "banned" end, function(to)
    check(not to, "2: the game's ban was lifted (bob's role is " .. tostring(gameRole("bob")) .. ")", to and "still banned in the game" or nil)
    manual("2: bob rejoins now (the batch does it); the Bans card's rows and the Unban button's ask are a look")
end)

-- ---- part 2: wait for bob to be back on, then the game's unban wins
waitFor(300000, function() return bobOn() end, function(to)
    check(not to, "3: bob rejoined after the lift", to and "not back in 5 minutes" or nil)
    if to then return end
    ans1 = nil
    add(30000, function()
        M.ban("bob", "b8 QA timed ban 2", "h1", false, function(a) ans1 = a end)
    end)
end)
waitFor(20000, function() return M.banOf("bob") ~= nil end, function(to)
    check(not to, "3: the second ban shows as a row", to and "none" or nil)
end)
waitFor(90000, function() return gameRole("bob") == "banned" end, function(to)
    check(not to, "3: the game holds the second ban", gameRole("bob"))
    -- the game's own window / command lifts it, ZeD is not asked
    SendCommandToServer('/unbanuser "bob"')
    note("typed the game's /unbanuser for bob")
end)
waitFor(240000, function() return M.banOf("bob") == nil end, function(to)
    check(not to, "3: ZeD's row closed by itself after the game's unban (the game's unban wins)", to and "row still held after 240 s" or nil)
    note("role after: " .. tostring(gameRole("bob")))
    check(gameRole("bob") ~= "banned", "3: bob is not banned in the game", gameRole("bob"))
end)

-- ---- always: nothing left banned
add(500, function()
    local b = M.banOf("bob")
    if b then M.unban(b, function() end) end
    if gameRole("bob") == "banned" then SendCommandToServer('/unbanuser "bob"') end
    watching = false
    Events.OnTick.Remove(watch)
    Events.OnServerCommand.Remove(tap)
end)
add(6000, function()
    check(M.banOf("bob") == nil and gameRole("bob") ~= "banned", "end: no ban on bob is left (restored)", tostring(gameRole("bob")))
end)
Events.OnTick.Add(drive)
