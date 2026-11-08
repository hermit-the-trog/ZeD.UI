-- ZeDUI/tools/qa/zedqa_b8_mp_helper.lua  (Nov 7 2026, QA; beta 8): on the ADMIN client, the host helper of ZeDUI/server_helper/README.md (E22 to E24, E21 by reading) in the SECOND session of
-- batch_b8_mp.ps1: the server was started with RCONPort and RCONPassword in its settings and the sandbox option Host Helper (RCON) on,
-- and zed_rcon_helper.py runs beside it (the batch checks the files, the port and the helper's own log). bob must be on the server with
-- zedqa_b8_mp_bob_leave_ban.lua waiting. What the admin client sees: with the helper alive the server makes the game's calls through
-- RCON, so this staff client is NOT asked to make them (no a_owed Ban, Kick, UnBan or VoiceBan within the helper's 30 s).
--   1. a 1-hour ban on bob (ZeD): bob is gone and his role reads banned, and this client was asked for nothing
--   2. bob muted while off the server (the server's list)
--   3. ZeD's Unban: the role is lifted by the helper, again no call to this client; prints BOB MAY JOIN
--   4. after bob's rejoin (the batch): the voice ban owed at his join is made by the helper, not by this client
--   5. the admin unmutes bob; every ban and mute made here is gone at the end
-- grep "ZEDQA b8hp". The helper's log, the queue and answers files and the RCON port are read by the batch, not here.
local TAG = "b8hp"
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
    if module == Adm.MOD and command == "a_owed" and type(args) == "table" then owed[#owed + 1] = { act = tostring(args.act), target = tostring(args.target), at = getTimestampMs() } end
end
Events.OnServerCommand.Add(tap)
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
local function bobOn() return getPlayerFromUsername("bob") ~= nil end
local function owedList()
    local o = {}
    for _, e in ipairs(owed) do o[#o + 1] = e.act .. ":" .. e.target end
    return table.concat(o, ", ")
end
local t0, ans, ans2, ans3

add(500, function()
    check(bobOn(), "bob is on the server")
    check(M.live(), "ZeD's server part answers")
    pcall(requestUsers)
end)
add(3000, function()
    owed = {}
    t0 = getTimestampMs()
    M.ban("bob", "b8 helper timed ban", "h1", false, function(a) ans = a end)
end)
waitFor(15000, function() return ans ~= nil end, function(to)
    check(not to and ans and ans.ok == true, "1: the ban was accepted", ans and (tostring(ans.ok) .. "/" .. tostring(ans.err)) or "no answer")
end)
waitFor(60000, function() return gameRole("bob") == "banned" end, function(to)
    local secs = math.floor((getTimestampMs() - t0) / 1000)
    check(not to, "1: the game's ban was made (role banned) within " .. secs .. " s", gameRole("bob"))
    check(secs < 29, "1: it landed inside the helper's 30 s, before any staff client would be asked", secs)
end)
waitFor(60000, function() return not bobOn() end, function(to)
    check(not to, "1: bob is gone", to and "still on" or nil)
    note("calls owed to this client so far: [" .. owedList() .. "]")
    local n = 0
    for _, e in ipairs(owed) do if e.act == "Ban" or e.act == "Kick" then n = n + 1 end end
    check(n == 0, "1: this staff client was not asked to make the ban or the kick (the helper did)", n)
end)
add(2000, function()
    ans2 = nil
    M.mute("bob", true, function(a) ans2 = a end, false)
end)
waitFor(15000, function() return ans2 ~= nil end, function(to)
    check(not to and ans2 and ans2.ok ~= false, "2: bob is muted while off the server", ans2 and (tostring(ans2.ok) .. "/" .. tostring(ans2.err)) or "no answer")
end)
add(1000, function()
    local row = M.banOf("bob")
    check(row ~= nil, "3: the ban row is there to lift")
    owed = {}
    t0 = getTimestampMs()
    if row then M.unban(row, function(a) ans3 = a end) end
end)
waitFor(15000, function() return ans3 ~= nil end, function(to)
    check(not to and ans3 and ans3.ok ~= false, "3: ZeD's Unban was accepted", ans3 and (tostring(ans3.ok) .. "/" .. tostring(ans3.err)) or "no answer")
end)
waitFor(90000, function() return gameRole("bob") ~= "banned" end, function(to)
    local secs = math.floor((getTimestampMs() - t0) / 1000)
    check(not to, "3: the helper lifted the game's ban within " .. secs .. " s", gameRole("bob"))
    local n = 0
    for _, e in ipairs(owed) do if e.act == "UnBan" or e.act == "UnBanIPOnly" or e.act == "UnBanSteamID" then n = n + 1 end end
    check(n == 0, "3: this staff client was not asked to make the unban", n)
    owed = {}
    say("BOB MAY JOIN")
end)
waitFor(600000, bobOn, function(to)
    check(not to, "4: bob rejoined after the lift", to and "not within 10 minutes" or nil)
end)
add(45000, function()
    local n = 0
    for _, e in ipairs(owed) do if e.act == "VoiceBan" then n = n + 1 end end
    note("calls owed to this client after the join: [" .. owedList() .. "]")
    check(n == 0, "4: the voice ban at the join was not asked of this staff client (the helper made it)", n)
    ans = nil
    M.mute("bob", false, function(a) ans = a end)
end)
waitFor(15000, function() return ans ~= nil end, function(to)
    check(not to and ans and ans.ok ~= false, "5: the unmute was accepted", ans and (tostring(ans.ok) .. "/" .. tostring(ans.err)) or "no answer")
end)
waitFor(20000, function() return not M.isMuted("bob") end, function(to)
    check(not to, "5: bob is off the mute list (restored)", to and "still muted" or nil)
end)
add(500, function()
    local b = M.banOf("bob")
    if b then M.unban(b, function() end) end
    if gameRole("bob") == "banned" then SendCommandToServer('/unbanuser "bob"') end
    watching = false
    Events.OnTick.Remove(watch)
    Events.OnServerCommand.Remove(tap)
end)
add(6000, function()
    check(M.banOf("bob") == nil and gameRole("bob") ~= "banned" and not M.isMuted("bob"), "end: no ban and no mute on bob is left (restored)", tostring(gameRole("bob")))
    manual("E24: -Drconlo=true reaching System.getProperty (this kit's server launcher cannot add the flag; netstat on the RCON port after a real start)")
    manual("E21: NetworkUser.new():isSteamIdBanned(sid) from server Lua needs a Steam server (BanSteamID, then read the ZeD server log)")
    manual("E25, E26 (the look in game of the join rules in safe mode, and a ban lifted in the game's own Users window) are looks, not scripts")
end)
Events.OnTick.Add(drive)
