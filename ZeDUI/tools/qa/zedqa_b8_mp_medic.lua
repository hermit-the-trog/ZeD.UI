-- ZeDUI/tools/qa/zedqa_b8_mp_medic.lua  (Nov 7 2026, QA; beta 8): on the ADMIN client, CHECK_trade_medic_20261107.md, the Medical check half, against
-- bob (zedqa_b8_mp_bob_medic.lua on bob's client, started first, with the wound and the Yes answers). Check 1 at First Aid as it is: the card,
-- the injury list without a severity word, no game health panel. Then First Aid 5 (the server's /addxp): the severity words and bob's pain,
-- the treatment menu, a bandage. Then the distance (3 tiles away), the World window shut mid-check, and the check in safe mode (the game's own
-- health panel, closed again). The admin must hold a bandage in the main inventory (zedqa_b8_mp_stage.lua). grep "ZEDQA b8md". Pictures:
-- zqa_b8_medic_*.png. Manual: hover and focus rows, split screen, the controller walk, the 4K and Deck pictures.
local TAG = "b8md"
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
local MC = ZeD.Medic
local p = getPlayer()
local me = p:getUsername()
local optS = ZeD.Settings and ZeD.Settings.safeModeOption
local wasSafe, t, bob
local function bobp() return getPlayerFromUsername("bob") end
local function cardT()
    local c = ZeD_WorldWindow.getObjectCard and ZeD_WorldWindow.getObjectCard()
    return c and c.entry and c.entry.t
end
local function handEntry(d)
    for _, en in ipairs(d and d.entries or {}) do
        if has(en.name, "hand") and has(en.name, "left") then return en end
    end
    return nil
end
local function condText(en)
    local o = {}
    for _, c in ipairs(en and en.conditions or {}) do o[#o + 1] = tostring(c.text or c.label or c.name or c.id) .. "/" .. tostring(c.severity) end
    return table.concat(o, "; ")
end
local function ask() ISWorldObjectContextMenu.onMedicalCheck({}, p, bobp()) end
local function menuNames()
    local m = getPlayerContextMenu(0)
    local names = {}
    for _, o in ipairs(m and m.options or {}) do names[#names + 1] = tostring(o.name) end
    return names, m
end

add(300, function()
    bob = bobp()
    check(bob ~= nil, "bob is on the server")
    check(MC.canOpen(p), "ZeD's medical card can open on the admin's World window")
    wasSafe = optS and optS:getValue() or 1
    note("the admin's First Aid level " .. tostring(p:getPerkLevel(Perks.Doctor)))
    pcall(function() ISTimedActionQueue.clear(p) end)
    ask()
end)
waitFor(60000, function() t = MC.current; return t ~= nil end, function(to)
    check(not to, "1: the check ran and ZeD's medical card opened", to and "no card in 60 s" or nil)
    check(ISMedicalCheckAction.getHealthWindowForPlayer(bobp()) == nil, "2: the game's health panel did not open")
    if not t then return end
    check(cardT() == t, "2: the card is in the World window's drawer")
    ticks(30, function() shot("medic_level0") end)
end)
add(1500, function()
    if not t then return end
    local d = t.d
    check(d ~= nil, "2: bob's body was read into the card")
    local en = handEntry(d)
    check(en ~= nil, "2: the left hand is in the injury list", en and en.name)
    if en then
        note("hand conditions at level " .. tostring(t.level) .. ": " .. condText(en))
        check(has(condText(en), "deep"), "2: it reads Deep wound", condText(en))
        if t.level < 5 then
            check(not has(condText(en), "severe") and not has(condText(en), "moderate"), "2: no severity word below First Aid 5")
            check(t.pain == nil, "2: no pain line below First Aid 5", t.pain)
        end
    end
    check(d and d.woundedCount ~= nil and d.woundedCount >= 1, "2: the summary counts an injured part", d and d.woundedCount)
    check(t.blocking == nil, "2: no red box near bob")
    pcall(ZeD_WorldWindow.closeObjectCard)
end)

-- ---- First Aid 5
add(800, function()
    SendCommandToServer('/addxp "' .. me .. '" Doctor=4000 -false')
end)
waitFor(20000, function() return p:getPerkLevel(Perks.Doctor) >= 5 end, function(to)
    note("First Aid now " .. tostring(p:getPerkLevel(Perks.Doctor)))
    check(not to, "3: the admin is First Aid 5 or better", p:getPerkLevel(Perks.Doctor))
    t = nil
    ask()
end)
waitFor(60000, function() t = MC.current; return t ~= nil end, function(to)
    check(not to, "3: the second check opened the card", to and "no card" or nil)
    if not t then return end
    ticks(40, function() shot("medic_level5") end)
end)
add(1500, function()
    if not t then return end
    local en = handEntry(t.d)
    if en then
        note("hand conditions at level " .. tostring(t.level) .. ": " .. condText(en))
        check(has(condText(en), "severe") or has(condText(en), "moderate") or has(condText(en), "mild"), "3: the severity word shows at First Aid 5", condText(en))
    else
        check(false, "3: the left hand is listed at First Aid 5")
    end
    note("bob's pain on the card: " .. tostring(t.pain))
end)

-- ---- treat: the game's menu, then its Bandage
add(500, function()
    if not t then return end
    local en = handEntry(t.d)
    if not (en and en.bodyPart) then check(false, "5: a part to treat"); return end
    local ok, e = pcall(ZeD.HealthTab.treat, t.patient, t.doctor, en.bodyPart, cardT() and ZeD_WorldWindow.getObjectCard(), 20, 20, t.blocking)
    check(ok, "5: the treatment menu opens for the left hand", e)
end)
add(800, function()
    local names, m = menuNames()
    note("the hand's menu: " .. table.concat(names, " | "))
    local bandage
    for _, o in ipairs(m and m.options or {}) do
        if has(o.name, "bandage") and not has(o.name, "remove") then bandage = o end
    end
    check(bandage ~= nil, "5: the menu offers Bandage", #names)
    check(#names >= 1, "5: the menu lists the game's treatments")
    ticks(20, function() shot("medic_menu") end)
    if bandage and bandage.onSelect then
        pcall(bandage.onSelect, bandage.target, bandage.param1, bandage.param2, bandage.param3, bandage.param4, bandage.param5, bandage.param6, bandage.param7)
        note("Bandage pressed")
    end
    pcall(function() m:hideAndChildren() end)
end)
waitFor(40000, function()
    local b = bobp()
    if not b then return false end
    local ok, v = pcall(function() return b:getBodyDamageRemote():getBodyPart(BodyPartType.Hand_L):bandaged() end)
    return ok and v == true
end, function(to)
    check(not to, "5: the hand shows Bandaged on the admin's copy of bob's body", to and "not within 40 s" or nil)
    ticks(60, function()
        local en = handEntry(t and t.d)
        note("hand after the bandage: " .. condText(en))
        check(en ~= nil and has(condText(en), "bandag"), "5: the row turns to Bandaged on the card", condText(en))
        shot("medic_bandaged")
    end)
end)
add(3000, function()
    local en = handEntry(t and t.d)
    if en and en.bodyPart then
        pcall(ZeD.HealthTab.treat, t.patient, t.doctor, en.bodyPart, ZeD_WorldWindow.getObjectCard(), 20, 20, t.blocking)
        local names, m = menuNames()
        local rem = false
        for _, nme in ipairs(names) do if has(nme, "remove") and has(nme, "bandage") then rem = true end end
        check(rem, "5: the menu now offers Remove bandage", table.concat(names, " | "))
        pcall(function() m:hideAndChildren() end)
    end
end)

-- ---- distance and the shut window
add(1500, function()
    if not t then return end
    local x, y, z = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    SendCommandToServer("/teleportto " .. (x + 3) .. "," .. y .. "," .. z)
end)
add(5000, function()
    if not t then return end
    local rolePower = safe(function() return p:getRole():hasCapability(Capability.CanMedicalCheat) end, false)
    if rolePower then
        check(MC.current == t and t.blocking ~= nil and has(t.blocking, "far"), "7: 3 tiles away the card stays with 'Too far away from bob!'", t.blocking)
        ticks(20, function() shot("medic_far") end)
    else
        check(MC.current ~= t, "7: without the role's power a step closes the card")
    end
    local x, y, z = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    SendCommandToServer("/teleportto " .. (x - 3) .. "," .. y .. "," .. z)
end)
add(5000, function()
    if not t then return end
    if MC.current == t then check(t.blocking == nil, "7: walking back clears the red box and fills the list again", t.blocking) end
    pcall(ZeD_WorldWindow.close)
end)
add(2500, function()
    check(MC.current == nil, "10: closing the World window ends the check (the card is gone)", MC.current and "still current" or nil)
    pcall(function() ZeD_WorldWindow.open(0) end)
end)
add(2500, function()
    check(cardT() == nil or cardT() ~= t, "10: the card stays gone when the window opens again")
end)

-- ---- safe mode: the game's own health panel
add(1000, function()
    if optS then pcall(function() optS:setValue(2) end) end
    t = nil
end)
add(2000, function()
    check(not MC.canOpen(p), "9: in safe mode ZeD's medical card steps aside")
    ask()
end)
waitFor(60000, function() return ISMedicalCheckAction.getHealthWindowForPlayer(bobp()) ~= nil end, function(to)
    check(not to, "9: the game's own health panel opened in safe mode", to and "no panel" or nil)
    check(MC.current == nil, "9: no ZeD card in safe mode")
    ticks(30, function() shot("medic_safe_mode") end)
end)
add(2000, function()
    local w = ISMedicalCheckAction.getHealthWindowForPlayer(bobp())
    if w then pcall(function() w:removeFromUIManager() end); ISMedicalCheckAction.HealthWindows[bobp()] = nil end
    pcall(function() p:stopReceivingBodyDamageUpdates(bobp()) end)
    if optS then pcall(function() optS:setValue(wasSafe or 1) end) end
    manual("4: hover a figure part or an injury row; the right column shows that part")
    manual("6: paused (single player), 8: split screen, the controller walk (A opens the menu, B closes), and 4K and Deck pictures")
end)
Events.OnTick.Add(drive)
