-- ZeDUI/tools/qa/zedqa_b8a_password.lua  (Nov 8 2026, hotfix beta 8a): on the ADMIN client against the local server,
-- the Users card's Set password sends what was typed. Beta 8's fault: the card read the masked box with getText, which
-- answers with stars, so the account's password became "*****". This script adds a test account (b8a_dora), opens its
-- card's password box, types into it, presses Set password through the card's own button, and records what reaches the
-- game's networkUserAction (the call still goes through). The account is deleted again at the end.
-- grep "ZEDQA b8apw". Pictures: zqa_b8a_pw_*.png. Manual: before the delete step, a second client can log in as
-- b8a_dora with the password below (set KEEP = true to keep the account for that, then delete it from the card).
local TAG = "b8apw"
local USER, PASS = "b8a_dora", "qa-b8a-Pass1"
local KEEP = false
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local npass, nfail = 0, 0
local function check(ok, what, d)
    ok = ok and true or false
    if ok then npass = npass + 1 else nfail = nfail + 1 end
    say((ok and "PASS " or "FAIL ") .. what .. (d ~= nil and (" (" .. tostring(d) .. ")") or ""))
    return ok
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b8a_pw_" .. n .. ".png") end) end

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

local AU, TC, M = ZeD.AdminUsers, ZeD.TicketCards, ZeD.Admin
if not (isClient() and AU and TC and M and ZeD.AdminTab) then say("ERR on a server client with ZeD's Admin tab only"); say("DONE"); return end
local U, PU, D = AU._U, AU._P, TC._D
local function adminSt()
    local win = ZeD_WorldWindow.getWindow()
    return win, win and win._adminTab
end
local function stop(id)
    local win = adminSt()
    for _, e in ipairs(win and ZeD.AdminTab.buildFocusables(win) or {}) do if e.id == id then return e end end
    return nil
end

add(300, function()
    if not ZeD_WorldWindow.getWindow() then ZeD_WorldWindow.open(0) end
    ZeD_WorldWindow.openTab(0, "admin")
    check(M.can("ModifyNetworkUsers") or M.can("SeeNetworkUsers"), "the admin may change accounts")
end)
add(1500, function()
    local win, st = adminSt()
    if check(st ~= nil, "the Admin tab has its state") then AU.qaOpen(win, st, "users") end
end)
waitFor(10000, function() U.read(); return #U.rows > 0 end, function(to)
    check(not to, "the Users card lists accounts", #U.rows)
    if not U.row(USER) then U.add(USER) end
end)
waitFor(25000, function() U.read(); return U.row(USER) ~= nil end, function(to)
    check(not to, "the test account " .. USER .. " is there")
end)
add(500, function()
    local win, st = adminSt()
    if not (st and U.row(USER)) then return end
    AU.qaOpen(win, st, "user", USER)
    check(st.card and st.card.kind == "user", "the account card opens")
    st.card.open = "pass"
    U.bump()
end)
add(2000, function()
    local win = adminSt()
    local inner = D.fieldInner(D.fieldOf(win, "upass"))
    check(inner ~= nil and inner:isMasked(), "the password box is masked")
    D.setField(win, "upass", PASS)
end)
add(800, function()
    local win = adminSt()
    local inner = D.fieldInner(D.fieldOf(win, "upass"))
    local shown = inner and inner:getText() or ""
    check(shown ~= PASS, "the box itself shows stars, not the words", shown)
    check(D.fieldText(win, "upass") == PASS, "the card reads the typed words", D.fieldText(win, "upass"))
    shot("typed")
end)
-- press Set password through the card's own button, recording what reaches the game
local sent = nil
add(500, function()
    local e = stop("tk:upset")
    if not check(e ~= nil and not e.disabled, "the Set password button is live") then return end
    local real = networkUserAction
    networkUserAction = function(action, user, arg, ...)
        if action == "SetPassword" then sent = { user = user, arg = arg } end
        return real(action, user, arg, ...)
    end
    local win = adminSt()
    local ok, err = pcall(e.onActivate, win, e)
    networkUserAction = real
    check(ok, "the press runs", err)
end)
add(1000, function()
    check(sent ~= nil and sent.user == USER, "Set password called the game for " .. USER, sent and sent.user)
    check(sent ~= nil and sent.arg == PASS, "what was sent is the typed password, not stars", sent and sent.arg)
    shot("sent")
end)
add(1500, function()
    if KEEP then say("MANUAL log in as " .. USER .. " with " .. PASS .. " from a second client, then delete the account"); return end
    local r = U.row(USER)
    if r then U.act("del", r) end
end)
waitFor(25000, function() if KEEP then return true end; U.read(); return U.row(USER) == nil end, function(to)
    check(not to, "the test account is deleted again")
    local _, st = adminSt()
    if st then st.card = nil end
end)
Events.OnTick.Add(drive)
say("start")
