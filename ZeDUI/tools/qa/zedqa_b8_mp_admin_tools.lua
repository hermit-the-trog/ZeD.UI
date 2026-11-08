-- ZeDUI/tools/qa/zedqa_b8_mp_admin_tools.lua  (Nov 7 2026, QA; beta 8): on the ADMIN client, CHECK_admin_tools_20261107.md against the real local server
-- (it needs only the admin, but bob on the server makes the Users rows richer). Users: the card, Find, Add user (b8_carl), the masked
-- password box, Set password, Delete (the account is gone again), the Bans card, a ban refused on yourself. Statistics: the numbers flow
-- while the card shows and stop about 2 s after it goes. PvP log: the card, the two server options (changed and put back). Climate: Apply
-- writes the admin values, Desaturation stays put when Precipitation goes off, everything put back as it was. Zones: a non-PvP zone added
-- and removed, the checks on a bad area, a safe zone for bob (released again). Server sandbox: two settings changed through ZeD's window,
-- Apply sends them, then put back. NEVER bans by IP: the admin and bob share 127.0.0.1. The timed bans are zedqa_b8_mp_bans.lua.
-- grep "ZEDQA b8at". Pictures: zqa_b8_at_*.png. Manual: the gray checks with a moderator, the controller, the map pick, storm triggers, a PvP
-- hit between two clients, the second admin's views.
local TAG = "b8at"
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
local AU, AT, AZ, AC, TC = ZeD.AdminUsers, ZeD.AdminTools, ZeD.AdminZones, ZeD.AdminCards, ZeD.TicketCards
local M = ZeD.Admin
local U, PU = AU._U, AU._P
local PT = AT._P
local Z, PZ = AZ._Z, AZ._P
local D = TC._D
local MM = ZeD.MainMenu
local p = getPlayer()
local function adminSt()
    local win = ZeD_WorldWindow.getWindow()
    return win, win and win._adminTab
end
local function openAdmin()
    if not ZeD_WorldWindow.getWindow() then ZeD_WorldWindow.open(0) end
    ZeD_WorldWindow.openTab(0, "admin")
end
local function cardKind()
    local _, st = adminSt()
    return st and st.card and st.card.kind
end
local function closeCard()
    local win, st = adminSt()
    if st then st.card = nil end
end

-- ---- Users
add(300, function()
    openAdmin()
    check(M.can("SeeNetworkUsers"), "the admin may see every account")
end)
add(1500, function()
    local win, st = adminSt()
    check(st ~= nil, "the Admin tab has its state")
    if not st then return end
    AU.qaOpen(win, st, "users")
end)
waitFor(10000, function() U.read(); return #U.rows > 0 end, function(to)
    check(not to, "1: the Users card lists accounts", #U.rows)
    check(cardKind() == "users", "1: the card on the tab is the users card", cardKind())
    check(U.rows[1] and U.rows[1].on == true, "1: online accounts come first", U.rows[1] and U.rows[1].user)
    local o = {}
    for i = 1, math.min(5, #U.rows) do o[#o + 1] = U.rows[i].user .. "/" .. tostring(U.rows[i].role) .. (U.rows[i].on and "/on" or "/off") end
    note("rows: " .. table.concat(o, ", "))
    check(#U.find("bob") >= 0, "2: Find by a name answers", #U.find("bob"))
    check(#U.find("admin") >= 1, "2: Find by a role answers", #U.find("admin"))
    check(#U.find("", true) <= #U.rows, "2: Online only keeps the online accounts")
    ticks(40, function() shot("at_users") end)
end)
add(500, function()
    U.add("b8_carl")
end)
waitFor(25000, function() U.read(); return U.row("b8_carl") ~= nil end, function(to)
    check(not to, "3: Add user: b8_carl shows in the list within seconds", to and "not listed in 25 s" or nil)
end)
add(500, function()
    local win, st = adminSt()
    if not (st and U.row("b8_carl")) then return end
    AU.qaOpen(win, st, "user", "b8_carl")
    check(cardKind() == "user", "5: the account card opens", cardKind())
    local card = st.card
    card.open = "pass"
    U.bump()
end)
add(2500, function()
    local win, st = adminSt()
    if not (st and st.card and st.card.kind == "user") then return end
    local inner = D.fieldInner(D.fieldOf(win, "upass"))
    check(inner ~= nil and inner._zedMasked == true, "5: the password box stars what is typed (setMasked took)", inner and tostring(inner._zedMasked))
    D.setField(win, "upass", "qa-b8-pass")
    ticks(25, function() shot("at_password") end)
end)
add(1200, function()
    local r = U.row("b8_carl")
    if not r then return end
    check(PU.whyAccount(r) == nil, "5: nothing blocks the admin from changing this account", PU.whyAccount(r))
    check(U.setPassword("b8_carl", "qa-b8-pass") == true, "5: Set password goes to the game")
    manual("5: log in as b8_carl with the new password; reset password and TOTP are the foot's asks")
end)
add(2500, function()
    local r = U.row("b8_carl")
    if not r then return end
    local self = U.row(p:getUsername())
    if self then check(PU.whyBan(self, "banip") ~= nil, "5: a ban on yourself is gray with the game's words", PU.whyBan(self, "banip")) end
    U.act("del", r)
end)
waitFor(25000, function() U.read(); return U.row("b8_carl") == nil end, function(to)
    check(not to, "5: Delete took the account away (restored)", to and "still listed" or nil)
end)
add(500, function()
    local win, st = adminSt()
    if st then AC.qaOpen(win, st, "bans") end
end)
add(2000, function()
    check(cardKind() == "bans", "4: the Bans card opens", cardKind())
    ticks(25, function() shot("at_bans") end)
    closeCard()
end)

-- ---- Statistics
add(800, function()
    local win, st = adminSt()
    if st then AT.qaOpen(win, st, "statistics") end
end)
add(3500, function()
    check(cardKind() == "stats", "S: the statistics card opens", cardKind())
    check(PT.statsOn == true, "S: the game's statistics are switched on while the card shows")
    local sec = PT.STATS and PT.STATS[1]
    if sec then
        local lt, rt = PT.readTable(sec.lfn), PT.readTable(sec.rfn)
        local row = sec.rows[1][1]
        note("first table, first row " .. tostring(row) .. ": client " .. tostring(PT.statOf(lt, row)) .. ", server " .. tostring(PT.statOf(rt, row)))
        check(lt ~= nil, "S: the client's table is readable")
        check(rt ~= nil, "S: the server's table has arrived", rt and "yes" or "nil")
    end
    ticks(30, function() shot("at_statistics") end)
end)
add(1500, function()
    closeCard()
    ZeD_WorldWindow.openTab(0, "loot")
end)
add(4500, function()
    check(PT.statsOn ~= true, "S: about 2 s after the card goes the numbers are switched off", tostring(PT.statsOn))
    openAdmin()
end)

-- ---- PvP log
add(1500, function()
    local win, st = adminSt()
    if st then AT.qaOpen(win, st, "pvplog") end
end)
add(3500, function()
    check(cardKind() == "pvplog", "P: the PvP log card opens", cardKind())
    check(M.can("PVPLogTool") == true, "P: the admin has the PVP log tool")
    check(type(PT.events) == "table", "P: the log reads as a list", #PT.events)
    local o = safe(function() return getServerOptions():getBoolean("PVPLogToolChat") end, nil)
    PT.origChat = o
    note("PVPLogToolChat is " .. tostring(o))
    SendCommandToServer('/changeoption PVPLogToolChat "' .. tostring(not o) .. '"')
    ticks(25, function() shot("at_pvplog") end)
end)
add(4000, function()
    local o = safe(function() return getServerOptions():getBoolean("PVPLogToolChat") end, nil)
    check(PT.origChat ~= nil and o == (not PT.origChat), "P: the option changed on the server and the client sees it", tostring(o))
    SendCommandToServer('/changeoption PVPLogToolChat "' .. tostring(PT.origChat) .. '"')
end)
add(4000, function()
    local o = safe(function() return getServerOptions():getBoolean("PVPLogToolChat") end, nil)
    check(o == PT.origChat, "P: the option is put back", tostring(o))
    manual("P: a hit or a kill between two clients with PvP on shows a line within about 10 s; Go there; Clear asks first")
    closeCard()
end)

-- ---- Climate
local orig
add(800, function()
    local win, st = adminSt()
    if st then AT.qaOpen(win, st, "climate") end
end)
add(2500, function()
    check(cardKind() == "climate", "C: the climate card opens", cardKind())
    orig = PT.readClimate()
    check(orig ~= nil, "C: the game's admin values read")
    ticks(30, function() shot("at_climate") end)
end)
add(800, function()
    if not orig then return end
    local d = PT.copy(orig)
    d.fog.on, d.fog.v = true, 0.6
    d.clouds.on, d.clouds.v = true, 0.7
    d.desat.on, d.desat.v = true, 0.3
    d.precip.on, d.precip.v, d.precip.snow = true, 0.4, false
    check(PT.applyClimate(d), "C: Apply writes the admin values")
end)
add(3000, function()
    if not orig then return end
    local now = PT.readClimate()
    check(now ~= nil and now.fog.on and math.abs(now.fog.v - 0.6) < 0.02, "C: fog reads back 0.6", now and now.fog.v)
    check(now ~= nil and now.clouds.on and math.abs(now.clouds.v - 0.7) < 0.02, "C: clouds read back 0.7", now and now.clouds.v)
    -- the game's bug ZeD does not copy: Precipitation off must not turn the Desaturation override off
    local d = PT.copy(now)
    d.precip.on = false
    PT.applyClimate(d)
end)
add(3000, function()
    if not orig then return end
    local now = PT.readClimate()
    check(now ~= nil and now.precip.on == false, "C: Precipitation is off")
    check(now ~= nil and now.desat.on == true, "C: Desaturation stays put when Precipitation is unticked", now and tostring(now.desat.on))
    PT.applyClimate(orig)
end)
add(3000, function()
    if not orig then return end
    local now = PT.readClimate()
    check(now ~= nil and PT.same(now.fog, orig.fog) and PT.same(now.clouds, orig.clouds) and PT.same(now.desat, orig.desat), "C: the server's weather is put back as it was")
    manual("C: Stop current weather, Trigger storm, tropical, blizzard, Generate; a second admin sees the same values; X is Apply on a pad")
    closeCard()
end)

-- ---- Zones
local zx, zy
add(800, function()
    local win, st = adminSt()
    if st then AZ.qaOpen(win, st, "nonpvp") end
    zx, zy = math.floor(p:getX()), math.floor(p:getY())
end)
add(1500, function()
    local win, st = adminSt()
    check(cardKind() == "zones", "Z: the zones card opens", cardKind())
    if not (st and st.card) then return end
    check(st.card.add == "nonpvp", "Z: it starts on adding a non-PvP zone", st.card.add)
    D.setField(win, "zname", "QA b8 zone")
    AZ.qaArea(st, zx + 2, zy + 2, zx + 2, zy + 2)
end)
add(800, function()
    local win, st = adminSt()
    if not (st and st.card) then return end
    check(PZ.addWhy(win, st.card) ~= nil, "Z: a one-square area is refused with the card's reason", PZ.addWhy(win, st.card))
    AZ.qaArea(st, zx + 2, zy + 2, zx + 8, zy + 8)
end)
add(800, function()
    local win, st = adminSt()
    if not (st and st.card) then return end
    check(PZ.addWhy(win, st.card) == nil, "Z: a free area of 7 by 7 can be added", PZ.addWhy(win, st.card))
    ticks(25, function() shot("at_zone_add") end)
end)
add(1200, function()
    local win, st = adminSt()
    if not (st and st.card) then return end
    local n = Z.norm(st.card.area)
    local ok, err = pcall(function() NonPvpZone.addNonPvpZone("QA b8 zone", n.x1, n.y1, n.x2, n.y2) end)
    check(ok, "Z: the game's call adds the zone", err)
end)
waitFor(15000, function() for _, z in ipairs(Z.zones()) do if z.title == "QA b8 zone" then return true end end; return false end, function(to)
    check(not to, "Z: the zone is in the game's list", to and "not within 15 s" or nil)
end)
add(1500, function()
    local win, st = adminSt()
    if not (st and st.card) then return end
    check(Z.titleTaken("nonpvp", "QA b8 zone"), "Z: the name is taken now")
    st.card.add = "nonpvp"
    D.setField(win, "zname", "QA b8 zone 2")
    AZ.qaArea(st, zx + 4, zy + 4, zx + 10, zy + 10)
end)
add(800, function()
    local win, st = adminSt()
    if not (st and st.card) then return end
    check(PZ.addWhy(win, st.card) ~= nil, "Z: an area that overlaps a zone is refused", PZ.addWhy(win, st.card))
    pcall(function() NonPvpZone.removeNonPvpZone("QA b8 zone") end)
end)
waitFor(15000, function() return not Z.titleTaken("nonpvp", "QA b8 zone") end, function(to)
    check(not to, "Z: Remove took the zone away (restored)", to and "still listed" or nil)
end)
add(800, function()
    local win, st = adminSt()
    if not st then return end
    AZ.qaOpen(win, st, "safe")
    zx, zy = math.floor(p:getX()), math.floor(p:getY())
end)
add(1500, function()
    local win, st = adminSt()
    if not (st and st.card) then return end
    check(st.card.add == "safe", "Z: the safe zone starts on adding", st.card.add)
    D.setField(win, "zname", "QA b8 safe")
    D.setField(win, "zowner", "bob")
    AZ.qaArea(st, zx + 14, zy + 14, zx + 20, zy + 20)
end)
add(800, function()
    local win, st = adminSt()
    if not (st and st.card) then return end
    local why = PZ.addWhy(win, st.card)
    check(why == nil, "Z: the safe zone for bob can be added (he is online, no overlap)", why)
    if why == nil then
        local n = Z.norm(st.card.area)
        pcall(function() sendSafezoneClaim("bob", n.x1, n.y1, n.w, n.h, "QA b8 safe") end)
    end
end)
waitFor(15000, function() for _, h in ipairs(Z.safes()) do if h.title == "QA b8 safe" then return true end end; return false end, function(to)
    check(not to, "Z: the safe zone claimed an area for bob and shows in the safehouse list", to and "not within 15 s" or nil)
    local l = SafeHouse.getSafehouseList()
    for i = 0, l:size() - 1 do
        if l:get(i):getTitle() == "QA b8 safe" then pcall(sendSafehouseRelease, l:get(i)) end
    end
end)
waitFor(15000, function() return not Z.titleTaken("safe", "QA b8 safe") end, function(to)
    check(not to, "Z: the safe zone is released again (restored)", to and "still listed" or nil)
    manual("Z: See zone on ground, Pick on the map (drag, or hold A), Corner here, the map tint while the card is open, the world map off")
    closeCard()
end)

-- ---- the server's sandbox window
local names = { "MultiHitZombies", "StarterKit" }
local w, before, sent = nil, {}, nil
add(1000, function()
    check(isClient(), "SB: this is a server session")
    local so = getSandboxOptions()
    for _, n in ipairs(names) do
        local o = so:getOptionByName(n)
        before[n] = o and o:getValueAsString() or nil
    end
    note("before: " .. tostring(before.MultiHitZombies) .. " / " .. tostring(before.StarterKit))
    local ok = ZeD.SandboxIG.openServer()
    check(ok ~= false, "SB: More tools > Sandbox options opens ZeD's window", ok)
end)
waitFor(12000, function() return MM.pauseSandbox ~= nil and MM.pauseSandbox:isVisible() and MM.pauseSandbox.server == true end, function(to)
    w = MM.pauseSandbox
    check(not to and w ~= nil, "SB: the pause screen shows the sandbox window for the server", to and "not shown" or nil)
    if not w then return end
    w.serverSent = function(rows) sent = rows end
    pcall(function() w:load() end)
    local r1, r2 = w.ctls and w.ctls[names[1]], w.ctls and w.ctls[names[2]]
    check(r1 ~= nil and r2 ~= nil, "SB: both settings are rows in the window", tostring(r1 ~= nil) .. "/" .. tostring(r2 ~= nil))
    if r1 and r2 then
        local function flip(r, n)
            local was = before[n] == "true"
            w:setRowValue(r, was and "false" or "true")
        end
        flip(r1, names[1]); flip(r2, names[2])
        w:refreshDiff(true)
        local c = 0
        for _ in pairs(w.diff or {}) do c = c + 1 end
        check(c == 2, "SB: two changes are waiting", c)
        ticks(30, function() shot("at_sandbox") end)
    end
end)
add(1200, function()
    if not w then return end
    pcall(function() w:applyNow() end)
end)
add(3000, function()
    check(sent ~= nil and #sent == 2, "SB: Apply sent 2 changes to the server", sent and #sent or "nothing sent")
    check(w and w._note ~= nil, "SB: the strip says what was sent", w and w._note)
end)
waitFor(20000, function()
    local o = getSandboxOptions():getOptionByName(names[1])
    return o and o:getValueAsString() ~= before[names[1]]
end, function(to)
    local o = getSandboxOptions():getOptionByName(names[1])
    check(not to, "SB: the server's copy came back with the new value", o and o:getValueAsString())
end)
add(800, function()
    if not w then return end
    -- put both back and send again
    pcall(function() w:load() end)
    for _, n in ipairs(names) do
        local r = w.ctls and w.ctls[n]
        if r and before[n] then w:setRowValue(r, before[n]) end
    end
    w:refreshDiff(true)
    pcall(function() w:applyNow() end)
end)
waitFor(20000, function()
    local o = getSandboxOptions():getOptionByName(names[1])
    return o and o:getValueAsString() == before[names[1]]
end, function(to)
    check(not to, "SB: the settings are put back on the server", to and "not within 20 s" or nil)
    w.serverSent = nil
    pcall(function() w:back() end)
end)
add(1500, function()
    pcall(function() if MM.act and MM.act.resume then MM.act.resume() end end)
    manual("SB: a moderator without SandboxOptions sees More tools > Sandbox gray; fixed settings stay locked; a second client sees the values in See server options")
    closeCard()
end)
Events.OnTick.Add(drive)
