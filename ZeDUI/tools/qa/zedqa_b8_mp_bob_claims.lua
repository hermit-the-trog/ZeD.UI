-- ZeDUI/tools/qa/zedqa_b8_mp_bob_claims.lua  (Nov 7 2026, QA; beta 8): on BOB's client, the plain player the admin's stats and claim cards act on
-- (zedqa_b8_mp_claims.lua, started after this). It claims a safehouse the moment the admin has brought it into a free building (the
-- admin script walks buildings and brings bob), makes a faction, and then only WATCHES, printing every change of its own name, role,
-- weight, Cooking XP, safehouse title and faction name, and its warning points are the admin's to add. After the admin releases the house
-- and disbands the faction it reports what it saw. Runs about 7 minutes at most. grep "ZEDQA b8bc".
local TAG = "b8bc"
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
local C = ZeD.Claims
local p = getPlayer()
local claimed, tried, facTried, tClaim = false, false, false, nil
local seen = {}
local first = {}
local function watch(key, val)
    val = tostring(val)
    if first[key] == nil then first[key] = val end
    if seen[key] ~= val then
        seen[key] = val
        seen[key .. "#"] = (seen[key .. "#"] or 0) + 1
        note(key .. " = " .. val)
    end
end
local function house() return SafeHouse.hasSafehouse(p) end
local finished = false
local n = 0
local function onTick()
    n = n + 1
    if n % 30 ~= 0 then return end
    local ok, e = pcall(function()
        local now = getTimestampMs()
        if not claimed then
            if not tried then
                C.claim = nil
                local okc, a = pcall(C.claimCheck)
                if okc and a and a.ok then
                    tried = true
                    note("free building: claiming")
                    C.doClaim(function(r)
                        note("claim done: " .. tostring(r))
                        if not r then tried = false end
                    end)
                end
            end
            if house() then claimed, tClaim = true, now end
        else
            if not facTried and C.canCreateFaction() then
                facTried = true
                C.createFaction("QA Crew b8", function(r) note("faction made: " .. tostring(r)) end)
            end
            if tClaim and now - tClaim > 400000 then finished = true end
        end
        local d = p:getDescriptor()
        watch("forename", d:getForename())
        watch("surname", d:getSurname())
        watch("role", safe(function() return p:getRole():getName() end, "?"))
        watch("weight", safe(function() return math.floor(p:getNutrition():getWeight()) end, "?"))
        watch("cooking xp", safe(function() return math.floor(p:getXp():getXP(Perks.Cooking)) end, "?"))
        local h = house()
        watch("safehouse", h and h:getTitle() or "none")
        local f = Faction.getPlayerFaction(p)
        watch("faction", f and f:getName() or "none")
        if claimed and h == nil and seen["safehouse#"] and seen["safehouse#"] >= 2 and (f == nil) and seen["faction#"] and seen["faction#"] >= 2 then finished = true end
    end)
    if not ok then say("FAIL ERR watch: " .. tostring(e)); nfail = nfail + 1 end
end
Events.OnTick.Add(onTick)
note("waiting in " .. math.floor(p:getX()) .. "," .. math.floor(p:getY()) .. " for the admin to bring bob to a free building")
waitFor(900000, function() return finished end, function(to)
    Events.OnTick.Remove(onTick)
    check(claimed, "bob held a safehouse of his own", seen["safehouse"])
    check((seen["forename#"] or 0) >= 2 and seen["forename"] == first["forename"], "6: bob's forename changed while the admin saved it, and came back", tostring(first["forename"]) .. " -> " .. tostring(seen["forename"]))
    check((seen["role#"] or 0) >= 2 and seen["role"] == first["role"], "6: bob's role changed through the stats card and came back", tostring(first["role"]) .. " -> " .. tostring(seen["role"]))
    check((seen["weight#"] or 0) >= 2, "6: bob's weight changed", seen["weight#"])
    check((seen["cooking xp#"] or 0) >= 2, "6: bob's Cooking XP rose", seen["cooking xp"])
    check(seen["safehouse#"] ~= nil and seen["safehouse#"] >= 3, "C8: bob's safehouse was renamed by the admin, then released", seen["safehouse#"])
    check(seen["faction#"] ~= nil and seen["faction#"] >= 2, "C8: bob's faction was renamed by the admin and disbanded", seen["faction#"])
    check(isClient() and getPlayer() ~= nil, "C8: bob is still on the server (the staff actions kicked nobody)")
end)
Events.OnTick.Add(drive)
