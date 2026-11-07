-- ZeDUI/tools/qa/mp_b7_role_setup.lua  (Nov 7 2026, QA; merge 1, the offline Player card, a real second player): on the admin
-- client. None of the game's own roles can change roles without seeing every account (moderator and admin have both), so a
-- server owner's role is made the game's way (addRole, setupRole, as its Roles list does): qa_nosee, the moderator's powers
-- without SeeNetworkUsers. An account that has never been on is made (/adduser carl), and bob is given the role
-- (/setaccesslevel). Then the admin, who has the power, opens carl's card as a check of the other side: not closed.
-- The test server's database is put back after the run. grep "ZEDQA rsu".
local function say(s) print("ZEDQA rsu " .. tostring(s)) end
local pass, fail = 0, 0
local function check(ok, what, d)
    if ok then pass = pass + 1 else fail = fail + 1 end
    say((ok and "PASS " or "FAIL ") .. what .. (d ~= nil and (" (" .. tostring(d) .. ")") or ""))
end
local M, AC, TC = ZeD.Admin, ZeD.AdminCards, ZeD.TicketCards
local NAME = "qa_nosee"
local function now() return getTimestampMs() end
local function roleNamed(n)
    local list = getRoles()
    for k = 0, list:size() - 1 do if list:get(k):getName() == n then return list:get(k) end end
    return nil
end
local plan, i, t0 = {}, 1, now()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
add(500, function()
    SendCommandToServer('/adduser "carl" "qa-third-account"')
    if not roleNamed(NAME) then addRole(NAME) end
end)
add(4000, function()
    local r, mod = roleNamed(NAME), roleNamed("moderator")
    say("role made: " .. tostring(r ~= nil) .. "; moderator " .. tostring(mod ~= nil))
    if not (r and mod) then return end
    local caps, all = {}, getCapabilities()
    for k = 0, all:size() - 1 do
        local c = all:get(k)
        caps[c] = mod:hasCapability(c) and c:name() ~= "SeeNetworkUsers"
    end
    setupRole(r, "QA: changes roles, cannot see every account", Color.new(0.6, 0.8, 1.0, 1.0), caps)
end)
add(4000, function()
    local r = roleNamed(NAME)
    check(r and r:hasCapability(Capability.ChangeAccessLevel) and not r:hasCapability(Capability.SeeNetworkUsers), "qa_nosee changes roles and cannot see every account")
    SendCommandToServer('/setaccesslevel "bob" "' .. NAME .. '"')
end)
add(3000, function()
    local b = getPlayerFromUsername("bob")
    say("bob's role as this client sees it: " .. tostring(b and b:getRole() and b:getRole():getName()))
    ZeD_WorldWindow.openTab(0, "admin")
end)
add(1000, function()
    local win = ZeD_WorldWindow.getWindow()
    AC.openPlayer(win, win._adminTab, "carl")
end)
add(4000, function()
    local v = M.cards.carl
    say("the admin's card for carl: " .. (v and string.format("on %s closed %s role %s", tostring(v.on), tostring(v.closed), tostring(v.role)) or "none"))
    check(v ~= nil and not v.closed, "the admin, who can see every account, gets carl's card open")
    pcall(function() getCore():TakeFullScreenshot("rsu_admin_carl.png") end)
    local win = ZeD_WorldWindow.getWindow()
    pcall(function() TC.back(win, win._adminTab) end)
    say(pass .. " passed, " .. fail .. " failed")
end)
local function drive()
    local stp = plan[i]
    if not stp then Events.OnTick.Remove(drive); return end
    if now() - t0 < stp.ms then return end
    t0 = now(); i = i + 1
    local ok, e = pcall(stp.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
    if i > #plan then say("DONE") end
end
Events.OnTick.Add(drive)
