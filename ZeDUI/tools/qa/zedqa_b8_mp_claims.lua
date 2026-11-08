-- ZeDUI/tools/qa/zedqa_b8_mp_claims.lua  (Nov 7 2026, QA; beta 8): on the ADMIN client, CHECK_admin_player_claims_20261107.md against a real second player
-- (zedqa_b8_mp_bob_claims.lua on bob's client, started first). It walks buildings with bob in tow until bob holds a safehouse (and makes
-- a faction), then: C6, the stats card on bob (the edits are the card's own calls, ZeD.StatsCards._Y.DO: forename, weight, Cooking XP,
-- role, warning point, user log), C7, the inventory card (bob's things arrive, weapons first), C8, bob's safehouse and faction as staff
-- cards (rename each), and at the end bob's house is RELEASED and his faction DISBANDED (what this run made is undone), his name,
-- weight and role put back. The gates with a role lacking a capability, the foot's Save and Take buttons, a third account for Add
-- Player and change owner, the controller and the pictures at 4K and Deck are manual. grep "ZEDQA b8cl". Pictures: zqa_b8_cl_*.png.
local TAG = "b8cl"
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
local SC, M, C, AT = ZeD.StatsCards, ZeD.Admin, ZeD.Claims, ZeD.AdminTab
local Y = SC._Y
local p = getPlayer()
local me = p:getUsername()
local function goTo(x, y) SendCommandToServer("/teleportto " .. tostring(x) .. "," .. tostring(y) .. ",0") end
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
local TRIED = {}
local lastIn = nil
local function indoors(r)
    local cx, cy = math.floor(p:getX()), math.floor(p:getY())
    local cell = getCell()
    for d = 1, r do for dx = -d, d do for dy = -d, d do
        if math.abs(dx) == d or math.abs(dy) == d then
            local sq = cell:getGridSquare(cx + dx, cy + dy, 0)
            if sq and sq:getBuilding() and not SafeHouse.getSafeHouse(sq) and not TRIED[sq:getBuilding():getID()] then
                TRIED[sq:getBuilding():getID()] = true
                return cx + dx, cy + dy
            end
        end
    end end end
    return nil
end
local SPOTS = { { 10795, 10030 }, { 10737, 10234 }, { 10650, 10267 }, { 10815, 10037 }, { 11900, 6900 }, { 8100, 11500 }, { 6300, 5300 }, { 10300, 12700 } }
local found = false
local function adminSt()
    local win = ZeD_WorldWindow.getWindow()
    return win, win and win._adminTab
end
local function cardKind()
    local _, st = adminSt()
    return st and st.card and st.card.kind
end
local function openNext(what)
    local ok = AT.openNext(what, 0)
    return ok
end

-- ---- bob into a free building
add(500, function()
    pcall(function() sendClientCommand(p, "ZeDQA", "god", {}) end)
    pcall(function() p:setGodMod(true) end)
    check(bobHouse() ~= nil or getPlayerFromUsername("bob") ~= nil, "bob is on the server")
    if bobHouse() then found = true; note("bob already holds a safehouse") end
end)
for n = 1, #SPOTS do
    add(300, function() if not found then goTo(SPOTS[n][1], SPOTS[n][2]) end end)
    add(7000, function() end)
    for try = 1, 3 do
        add(300, function()
            if found then return end
            lastIn = nil
            local x, y = indoors(40)
            if x then
                SendCommandToServer("/removezombies -remove true -radius 40")
                goTo(x, y)
                lastIn = true
            end
        end)
        add(3000, function()
            if found or not lastIn then return end
            SendCommandToServer('/teleport "bob" "' .. me .. '"')
        end)
        add(10000, function()
            if found or not lastIn then return end
            if bobHouse() then found = true; note("bob claimed at spot " .. n) end
        end)
    end
end
add(500, function()
    check(found and bobHouse() ~= nil, "bob holds a safehouse (staged by walking buildings)")
    SendCommandToServer('/teleport "bob" "' .. me .. '"')
end)
waitFor(30000, function() return bobFaction() ~= nil end, function(to)
    if to then note("no faction for bob (the server's faction rules, or the game's hours rule); the faction half is skipped") end
    ZeD_WorldWindow.openTab(0, "admin")
end)

-- ---- C6: the stats card
local v, char, origFore, origWeight, origRole
add(2500, function()
    check(AT.visible(), "the Admin tab is there for this role")
    local ok = openNext({ kind = "pstats", user = "bob" })
    check(ok, "1: Check stats opens the stats card in the Admin tab")
end)
waitFor(8000, function() return cardKind() == "pstats" end, function(to)
    check(not to, "1: the pstats card is on the tab", cardKind())
    v = SC.read("bob")
    char = v.char
    check(char ~= nil, "bob is loaded on the admin client (the card can edit him)")
    if not char then return end
    origFore, origWeight, origRole = v.fore, v.weight, v.role
    note("bob: " .. tostring(v.display) .. " / " .. tostring(v.fore) .. " " .. tostring(v.sur) .. ", " .. tostring(v.profName) .. ", role " .. tostring(v.role) .. ", weight " .. tostring(v.weight))
    check(v.role == "user", "bob is a plain user", v.role)
    check(v.rankWhy == nil, "2: no rank reason against bob", v.rankWhy)
    check(#v.skills > 20, "2: the skills read", #v.skills)
    check(Y.why(v, "CanSeePlayersStats") == nil, "2: the edit gate is open for the admin", Y.why(v, "CanSeePlayersStats"))
    ticks(40, function() shot("cl_stats") end)
end)
add(1000, function()
    if not char then return end
    Y.DO.name(char, "Forename", "Qab")
    Y.DO.weight(char, 70)
    Y.DO.xp(char, Perks.Cooking, 50, false)
    Y.DO.role(char, "priority")
    Y.DO.warn("bob", "b8 stats check", 1)
end)
waitFor(15000, function() local l = M.logs and M.logs.bob; if not l then return false end; for _, e in ipairs(l) do if has(e.text, "b8 stats check") then return true end end; return false end, function(to)
    check(not to, "7: the warning point shows in bob's user log", to and "no log line" or nil)
    local l = M.logs and M.logs.bob or {}
    for _, e in ipairs(l) do if has(e.text, "b8 stats check") then Y.DO.removeLog("bob", e) end end
    Y.DO.addLog("bob", "b8 added log")
end)
add(5000, function()
    local l = M.logs and M.logs.bob or {}
    local has1, has2 = false, false
    for _, e in ipairs(l) do
        if has(e.text, "b8 stats check") then has1 = true end
        if has(e.text, "b8 added log") then has2 = true end
    end
    check(not has1, "7: Remove log took the warning's line away", tostring(has1))
    check(has2, "7: Add log put a line in", tostring(has2))
    for _, e in ipairs(l) do if has(e.text, "b8 added log") then Y.DO.removeLog("bob", e) end end
    if char then
        check(char:getDescriptor():getForename() == "Qab", "3: the forename shows on the admin's copy of bob", char:getDescriptor():getForename())
        check(char:getRole():getName() == "priority", "4: bob's role reads priority on the admin's copy", char:getRole():getName())
    end
end)
add(6000, function()
    if not char then return end
    -- put bob back
    Y.DO.name(char, "Forename", origFore or "Bob")
    if origWeight then Y.DO.weight(char, origWeight) end
    Y.DO.role(char, origRole or "user")
end)
add(5000, function()
    if not char then return end
    check(char:getDescriptor():getForename() == (origFore or "Bob"), "bob's forename is back", char:getDescriptor():getForename())
    check(char:getRole():getName() == (origRole or "user"), "bob's role is back", char:getRole():getName())
    manual("6, 8, 9: Add XP with multipliers, traits, the gates (a role without CanModifyPlayerStatsInThePlayerStatsUI, a role above), Save presses in the foot, Check your stats")
end)

-- ---- C7: the inventory card
add(1500, function()
    local win, st = adminSt()
    check(openNext({ kind = "pinv", user = "bob" }), "C7 1: the Inventory row opens the inventory card")
end)
waitFor(25000, function() return SC.inv and SC.inv.bob and #SC.inv.bob.rows > 0 end, function(to)
    check(not to, "C7 1: bob's things arrive", to and "no items in 25 s" or nil)
    local r = SC.inv and SC.inv.bob
    if r then
        local o = {}
        for i = 1, math.min(#r.rows, 6) do o[#o + 1] = r.rows[i].name .. (r.rows[i].weapon and " (weapon)" or "") end
        note(#r.rows .. " rows, first: " .. table.concat(o, ", "))
        local seenRest = false
        local ordered = true
        for _, row in ipairs(r.rows) do
            if row.weapon and not row.inInv and tonumber(row.parent) == -1 then
                if seenRest then ordered = false end
            else seenRest = true end
        end
        check(ordered, "C7 1: weapons come first")
    end
    ticks(40, function() shot("cl_inventory") end)
    manual("C7 2 to 4: pick a thing, Take, Remove (asks in the foot), Add item, your own inventory, bob logged off")
end)

-- ---- C8: bob's safehouse and faction as staff cards
local vh, vf
add(1500, function()
    local h = bobHouse()
    check(h ~= nil, "C8: bob's safehouse is in the game's list")
    if h then check(openNext({ kind = "osafe", obj = h }), "C8 1: Open on bob's safehouse opens its card in the Admin tab") end
end)
waitFor(10000, function() return cardKind() == "osafe" and C.other ~= nil end, function(to)
    check(not to, "C8 1: the staff card for bob's safehouse is up", cardKind())
    vh = C.other
    if not vh then return end
    check(vh.owner == "bob" and vh.other == true, "C8 1: bob is the owner, this is someone else's claim", vh.owner)
    check(vh.isOwner == false, "C8 1: the admin does not own it")
    ticks(40, function() shot("cl_osafe") end)
end)
local oldTitle
add(1000, function()
    if not vh then return end
    oldTitle = vh.title
    local done
    C.rename("QA b8 house", function(ok) done = ok; note("rename answered " .. tostring(ok)) end, vh)
end)
waitFor(25000, function() return C.other and C.other.title == "QA b8 house" end, function(to)
    check(not to, "C8 2: Rename shows on the card and reaches the game", C.other and C.other.title or "no card")
    check(isClient() and getPlayerFromUsername("bob") ~= nil, "C8 2: bob is still on the server (no kick)")
    if C.other and oldTitle then C.rename(oldTitle, nil, C.other) end
end)
add(6000, function()
    local f = bobFaction()
    if not f then note("no faction: C8 3 skipped"); return end
    check(openNext({ kind = "ofac", obj = f }), "C8 3: Open on bob's faction opens its card")
end)
waitFor(10000, function() return (not bobFaction()) or (cardKind() == "ofac" and C.other ~= nil and C.other.kind == "fac") end, function(to)
    if not bobFaction() then return end
    check(not to, "C8 3: the staff card for bob's faction is up", cardKind())
    vf = C.other
    if not vf then return end
    check(vf.owner == "bob" and vf.other == true, "C8 3: bob is the faction's owner", vf.owner)
    ticks(40, function() shot("cl_ofac") end)
    C.renameFaction("QA Crew b8x", function(ok) note("faction rename answered " .. tostring(ok)) end, vf)
end)
add(8000, function()
    local f = bobFaction()
    if f then check(f:getName() == "QA Crew b8x", "C8 3: Rename reached the game", f:getName()) end
end)

-- ---- undo: release the house, disband the faction
add(1000, function()
    if vf and bobFaction() then C.disband(function(ok) note("disband answered " .. tostring(ok)) end, vf) end
end)
add(8000, function()
    if vf then check(bobFaction() == nil, "C8 3: Disband removed bob's faction") end
    local h = bobHouse()
    if h then
        openNext({ kind = "osafe", obj = h })
    end
end)
waitFor(10000, function() return bobHouse() == nil or (cardKind() == "osafe" and C.other ~= nil) end, function(to)
    if bobHouse() and C.other then C.release(C.other, function(ok) note("release answered " .. tostring(ok)) end) end
end)
add(8000, function()
    check(bobHouse() == nil, "C8 2: Release took bob's safehouse away (restored)")
    manual("C8 2: Add Player, change owner and remove a member need a third account; C8 4 and 5: your own claims, a role without CanSetupSafehouses")
end)
Events.OnTick.Add(drive)
