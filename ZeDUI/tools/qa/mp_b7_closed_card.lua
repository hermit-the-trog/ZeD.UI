-- ZeDUI/tools/qa/mp_b7_closed_card.lua  (Nov 7 2026, QA; merge 1, the offline Player card, a real second player): on bob's client,
-- bob in qa_nosee (mp_b7_role_setup.lua: may change roles, cannot see every account). His Player card for an account that
-- is off must be closed the same way whether the name is a real account (carl, never on) or no account at all (nobody_qa):
-- status, profession and skills name the power it takes, the role box names it too, never "user", and is grayed with that
-- reason; pressing it opens no pick. Then the role change itself, sent past the card (ZeD.Admin.setRole), must come back
-- refused by the server ("perm") for both names, the same answer. grep "ZEDQA bcc".
local function say(s) print("ZEDQA bcc " .. tostring(s)) end
local pass, fail = 0, 0
local function check(ok, what, d)
    if ok then pass = pass + 1 else fail = fail + 1 end
    say((ok and "PASS " or "FAIL ") .. what .. (d ~= nil and (" (" .. tostring(d) .. ")") or ""))
end
local p = getPlayer()
local M, AC, TC, S = ZeD.Admin, ZeD.AdminCards, ZeD.TicketCards, ZeD.ServerPart
local NAME = "qa_nosee"
local function now() return getTimestampMs() end
local function roleName() local r = p:getRole(); return r and r:getName() end
local function win() return ZeD_WorldWindow.getWindow() end
local function stops() return ZeD.AdminTab.buildFocusables(win()) or {} end
local function stopOf(id) for _, e in ipairs(stops()) do if e.id == id then return e end end return nil end
local seen = {}
local plan, i, t0 = {}, 1, now()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function addUntil(ms, cond, fn) plan[#plan + 1] = { ms = ms, cond = cond, fn = fn } end
addUntil(20000, function() return roleName() == NAME end, function()
    say("bob's role: " .. tostring(roleName()))
    if roleName() ~= NAME then
        -- (the game didn't pass /setaccesslevel on to this client: the shim sets the server's object, and this client's the same)
        sendClientCommand(p, "ZeDQA", "role", { name = NAME })
        local list = getRoles()
        for k = 0, list:size() - 1 do if list:get(k):getName() == NAME then p:setRole(list:get(k)) end end
        say("set through the shim: " .. tostring(roleName()))
    end
    S.hello()
end)
addUntil(15000, function() return M.live() end, function()
    say(string.format("the tools: live %s; ChangeAccessLevel %s, SeeNetworkUsers %s, CanSeePlayersStats %s", tostring(M.live()), tostring(M.can("ChangeAccessLevel")), tostring(M.can("SeeNetworkUsers")), tostring(M.can("CanSeePlayersStats"))))
    check(M.can("ChangeAccessLevel") and not M.can("SeeNetworkUsers"), "bob may change roles and cannot see every account")
    -- (bob's new character opens the survival guide on startup, over everything: closed, so the pictures show the card)
    if ZeD.GuideBook and ZeD.GuideBook.isOpen and ZeD.GuideBook.isOpen(0) then ZeD.GuideBook.close(0); say("the guide was open: closed") end
    ZeD_WorldWindow.openTab(0, "admin")
end)
-- (each card asked for, and each answer, logged: the rerun's question is whether the server answers the second name)
if not ZEDQA_CCLOG then
    ZEDQA_CCLOG = true
    local orig = S.send
    S.send = function(m, c, a)
        if c == "a_card" or c == "a_role" then print("ZEDQA bcc   sent " .. tostring(c) .. " for " .. tostring(a and a.user) .. " (live " .. tostring(M.live()) .. ")") end
        return orig(m, c, a)
    end
    Events.OnServerCommand.Add(function(m, c, a)
        if c == "a_card" then print("ZEDQA bcc   heard a_card for " .. tostring(a and a.user) .. ", closed " .. tostring(a and a.closed)) end
        if c == "t_ack" and a and a.ok == false then print("ZEDQA bcc   heard a refusal: " .. tostring(a.err)) end
    end)
end
-- (the World window rolls up when the mouse is away from it, the hover close: held down while the cards are read, as a
-- player's mouse over it would)
local function keepDown()
    local w = ZeD_WorldWindow.getWindow()
    if w and w.windowShaded then w._autoShaded = false; w:setWindowShaded(false) end
    if w then w._outSince = getTimestampMs() + 1000 end
end
Events.OnTick.Add(keepDown)
local function look(user)
    add(3000, function() ZeD_WorldWindow.openTab(0, "admin"); local w = win(); local st = w._adminTab; st.card = nil; say(user .. ": opening, live " .. tostring(M.live())); AC.openPlayer(w, st, user) end)
    addUntil(10000, function() return M.cards[user] ~= nil end, function() say(user .. ": the card's answer came " .. tostring(M.cards[user] ~= nil)) end)
    add(1500, function()
        local v = M.cards[user]
        local netWhy = M.why("SeeNetworkUsers")
        local t = TC.qaState(win()._adminTab)
        local roleBox, status, nWhy, noSkills, loading, user_ = nil, nil, 0, false, false, false
        for _, it in ipairs(t.items or {}) do
            if it.text == netWhy then nWhy = nWhy + 1 end
            if it.k == "fact" and it.label == ZeD.tr("UI_ZeD_Adm_Role") then roleBox = it.c end
            if it.k == "fact" and it.label == ZeD.tr("UI_ZeD_Adm_Status") then status = it.value end
            if it.text == ZeD.tr("UI_ZeD_Adm_NoSkills") then noSkills = true end
            if it.text == ZeD.tr("UI_ZeD_Tk_Loading") then loading = true end
        end
        local w0 = win()
        say(string.format("the window: shown %s, rolled up %s, the Admin tab showing %s, items %d", tostring(w0:isVisible()), tostring(w0.windowShaded), tostring(ZeD_WorldWindow.isTabShowing("admin")), #(t.items or {})))
        local e = stopOf("tk:role")
        local why = e and e.tkWhy and e.tkWhy() or nil
        seen[user] = { closed = v and v.closed, role = roleBox and roleBox.text, status = status, nWhy = nWhy, why = why, ban = v and v.banId }
        say(string.format('%s: closed %s; role box "%s"; status "%s"; the power named %d times; role stop reason "%s"', user, tostring(v and v.closed), tostring(roleBox and roleBox.text), tostring(status), nWhy, tostring(why)))
        check(v and v.closed == true, user .. ": the server keeps the card closed")
        check(roleBox ~= nil and roleBox.text == netWhy, user .. ": the role box names the power, never \"user\"")
        check(status == netWhy, user .. ": the status names it too, not \"never seen\"")
        check(nWhy >= 2 and not noSkills and not loading, user .. ": profession and skills name it, never \"no skill\" or \"loading\"", nWhy)
        check(why == netWhy, user .. ": the role box is grayed with that reason")
        if e and e.onActivate then pcall(function() e.onActivate(win()) end) end
        check(t.popup == nil, user .. ": pressing it opens no pick")
        pcall(function() getCore():TakeFullScreenshot("bcc_" .. user .. ".png") end)
    end)
    add(300, function()
        if not M.live() then say("ERR the tools went off: no role change sent (it would go to the game's own call)"); return end
        seen[user].ans = nil
        M.setRole(user, "user", {}, function(a) seen[user].ans = a end)
    end)
    addUntil(6000, function() return seen[user].ans ~= nil end, function()
        local a = seen[user].ans or {}
        say(user .. ": the server's answer to a role change: ok " .. tostring(a.ok) .. ", " .. tostring(a.err))
        check(a.ok == false and a.err == "perm", user .. ": the server refuses it (perm)", a.err)
    end)
end
look("nobody_qa")
look("carl")
add(500, function()
    local a, b = seen.carl or {}, seen.nobody_qa or {}
    check(a.closed == b.closed and a.role == b.role and a.status == b.status and a.why == b.why and a.ban == b.ban and
        (a.ans and a.ans.err) == (b.ans and b.ans.err), "a real account and no account read exactly the same")
    local w = win(); pcall(function() TC.back(w, w._adminTab) end)
    Events.OnTick.Remove(keepDown)
    say(pass .. " passed, " .. fail .. " failed")
end)
local function drive()
    local stp = plan[i]
    if not stp then Events.OnTick.Remove(drive); return end
    local gone = now() - t0
    if stp.cond then
        local ok, c = pcall(stp.cond)
        if not (ok and c) and gone < stp.ms then return end
    elseif gone < stp.ms then return end
    t0 = now(); i = i + 1
    local ok, e = pcall(stp.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
    if i > #plan then say("DONE") end
end
Events.OnTick.Add(drive)
