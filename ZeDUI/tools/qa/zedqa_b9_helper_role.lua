-- ZeDUI/tools/qa/zedqa_b9_helper_role.lua  (Nov 8 2026, QA; beta 9): on the ADMIN client, step 1 of the host helper's role restore.
-- b9_mod (a second client, a plain account) is on the server. This script gives b9_mod the gm role through ZeD's own admin call
-- (ZeD.Admin.setRole = a_role), shortens the 1 hour ban length on the server to 210 s (ZeDQA shortban), and bans b9_mod through ZeD (M.ban, h1).
-- The ban records the role (moderator) on the server. After DONE the runner quits this client, so no staff is online when the ban ends and the
-- helper must make UnBan and the restoring SetRole. grep "ZEDQA b9hr". The helper log and answers.txt are read by b9_helper_role_run.ps1.
local TAG = "b9hr"
local USER = "b9_mod"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local npass, nfail = 0, 0
local function check(ok, what, d)
    ok = ok and true or false
    if ok then npass = npass + 1 else nfail = nfail + 1 end
    say((ok and "PASS " or "FAIL ") .. what .. (d ~= nil and (" (" .. tostring(d) .. ")") or ""))
end
local function note(s) say("NOTE " .. tostring(s)) end
local plan, pi, pt = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function waitFor(maxMs, cond, fn) plan[#plan + 1] = { cond = cond, max = maxMs, fn = fn } end
local function drive()
    local st = plan[pi]
    if not st then return end
    local now = getTimestampMs()
    local timedOut = false
    if st.cond then
        if not st.started then st.started = now end
        local ok, v = pcall(st.cond)
        if not (ok and v) and now - st.started < st.max then return end
        timedOut = not (ok and v)
    elseif now - pt < st.ms then return end
    pt = now
    pi = pi + 1
    local ok, e = pcall(st.fn, timedOut)
    if not ok then nfail = nfail + 1; say("FAIL ERR step " .. (pi - 1) .. ": " .. tostring(e)) end
    if pi > #plan then
        say(npass .. " passed, " .. nfail .. " failed")
        say("DONE")
        Events.OnTick.Remove(drive)
    end
end
local M = ZeD.Admin
local p = getPlayer()
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
local watching, wn = true, 0
Events.OnTick.Add(function() wn = wn + 1; if watching and wn % 30 == 0 then pcall(M.watch) end end)
local ansRole, ansBan

add(500, function()
    check(getPlayerFromUsername(USER) ~= nil, USER .. " is on the server")
    check(M.live(), "ZeD's server part answers")
    check(M.can("ChangeAccessLevel"), "this admin may change roles")
    pcall(requestUsers)
    sendClientCommand(p, "ZeDQA", "nolimits", {})
    sendClientCommand(p, "ZeDQA", "shortban", { sec = 210 })
end)
add(3000, function()
    note(USER .. " in the game's list: " .. tostring(gameRole(USER)))
    M.setRole(USER, "gm", nil, function(a) ansRole = a end)
end)
waitFor(20000, function() return ansRole ~= nil end, function(to)
    check(not to and ansRole and ansRole.ok == true, "ZeD's role call was accepted", ansRole and (tostring(ansRole.ok) .. "/" .. tostring(ansRole.err)) or "no answer")
end)
add(500, function() pcall(requestUsers) end)
waitFor(60000, function() pcall(requestUsers); return gameRole(USER) == "gm" end, function(to)
    check(not to, USER .. " is a gm in the game's list", gameRole(USER))
end)
add(2000, function()
    M.ban(USER, "b9 QA helper role restore", "h1", false, function(a) ansBan = a end)
end)
waitFor(20000, function() return ansBan ~= nil end, function(to)
    check(not to and ansBan and ansBan.ok == true, "ZeD's timed ban was accepted", ansBan and (tostring(ansBan.ok) .. "/" .. tostring(ansBan.err)) or "no answer")
    if ansBan then note("ban answer id " .. tostring(ansBan.id) .. " untilT " .. tostring(ansBan.untilT) .. " now " .. tostring(getTimestamp())) end
end)
waitFor(20000, function() return M.banOf(USER) ~= nil end, function(to)
    local b = M.banOf(USER)
    check(not to and b ~= nil, "the ban shows as a row")
    if b and b.untilT then
        note("the row ends in " .. tostring(b.untilT - getTimestamp()) .. " s (the server clock)")
        check(b.untilT - getTimestamp() < 400, "the ban is short (about 210 s)", b.untilT - getTimestamp())
    end
end)
waitFor(90000, function() pcall(requestUsers); return gameRole(USER) == "banned" end, function(to)
    check(not to, "the game's own ban follows (role reads banned, made by the helper)", gameRole(USER))
end)
add(1000, function()
    watching = false
    note("the ban recorded role=gm on the server: read in the queue's SetRole line by the runner")
    say("BAN LIVE, this client quits next")
end)
Events.OnTick.Add(drive)
