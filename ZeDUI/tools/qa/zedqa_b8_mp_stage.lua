-- ZeDUI/tools/qa/zedqa_b8_mp_stage.lua  (Nov 7 2026, QA; beta 8, two real players): on the ADMIN client, before the trade and the
-- medical check. bob is brought to the admin (the server's /teleport), the admin is given the trade check's things from the server
-- (/additem: a client cannot make an item the server will move), the jacket is worn, the knife held, the watch marked favorite, a
-- bandage put in the backpack. bob is given a few things to offer (/additem). Prints what it found. grep "ZEDQA b8st".
local TAG = "b8st"
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
local p = getPlayer()
local me = p:getUsername()
local function give(ft, n) SendCommandToServer('/additem "' .. me .. '" "' .. ft .. '" ' .. tostring(n or 1)) end
local function inv() return p:getInventory() end
local function firstOf(t)
    local l = inv():getItems()
    for i = 0, l:size() - 1 do if l:get(i):getType() == t then return l:get(i) end end
    return nil
end
local function countOf(t)
    local n, l = 0, inv():getItems()
    for i = 0, l:size() - 1 do if l:get(i):getType() == t then n = n + 1 end end
    return n
end
local bag, bandages
add(300, function()
    check(isClient(), "this is a multiplayer client")
    note("the admin is " .. me .. ", First Aid level " .. tostring(safe(function() return p:getPerkLevel(Perks.Doctor) end, "?")))
    SendCommandToServer('/teleport "bob" "' .. me .. '"')
    SendCommandToServer('/godmod "' .. me .. '" -true')
    for _, ft in ipairs({ "Base.Apple", "Base.Bandage", "Base.RippedSheets", "Base.Bag_Schoolbag", "Base.HuntingKnife", "Base.Jacket_Black", "Base.WristWatch_Left_DigitalBlack" }) do give(ft, 1) end
    give("Base.Nails", 5)
    give("Base.Pencil", 22)
    give("Base.Bandage", 1)
    for _, ft in ipairs({ "Base.Pop", "Base.Banana", "Base.Spoon" }) do SendCommandToServer('/additem "bob" "' .. ft .. '" 1') end
end)
waitFor(15000, function() return firstOf("Apple") and firstOf("HuntingKnife") and firstOf("Bag_Schoolbag") and firstOf("WristWatch_Left_DigitalBlack") end, function(to)
    check(not to, "the server's items arrived on the admin client", to and "timed out" or nil)
    check(firstOf("Apple") ~= nil, "an apple")
    check(countOf("Nails") >= 1, "nails", countOf("Nails"))
    check(countOf("Pencil") >= 20, "pencils for the 20-item limit", countOf("Pencil"))
    local w = firstOf("WristWatch_Left_DigitalBlack")
    if w then w:setFavorite(true); check(w:isFavorite(), "the watch is marked favorite") end
    local j = firstOf("Jacket_Black")
    if j then pcall(function() ISTimedActionQueue.add(ISWearClothing:new(p, j, 50)) end) end
    local k = firstOf("HuntingKnife")
    if k then pcall(function() ISTimedActionQueue.add(ISEquipWeaponAction:new(p, k, 50, true, false)) end) end
    bag = firstOf("Bag_Schoolbag")
    if bag then pcall(function() ISTimedActionQueue.add(ISWearClothing:new(p, bag, 50)) end) end
end)
add(9000, function()
    local j = firstOf("Jacket_Black")
    check(j == nil or p:isEquippedClothing(j), "the jacket is worn")
    local k = firstOf("HuntingKnife")
    check(k == nil or p:isEquipped(k), "the knife is in hand")
    -- one bandage into the backpack (the game's transfer), one stays in the main inventory
    bag = firstOf("Bag_Schoolbag")
    local b = firstOf("Bandage")
    if bag and b and bag:getInventory() then
        pcall(function() ISTimedActionQueue.add(ISInventoryTransferAction:new(p, b, inv(), bag:getInventory())) end)
    else
        note("no backpack or bandage to move")
    end
end)
add(6000, function()
    bag = firstOf("Bag_Schoolbag")
    local inBag = 0
    if bag and bag:getInventory() then
        local l = bag:getInventory():getItems()
        for i = 0, l:size() - 1 do if l:get(i):getType() == "Bandage" then inBag = inBag + 1 end end
    end
    check(inBag >= 1, "a bandage sits in the backpack", inBag)
    check(countOf("Bandage") >= 1, "a bandage sits in the main inventory", countOf("Bandage"))
    local b = getPlayerFromUsername("bob")
    check(b ~= nil, "bob is on the server")
    if b then
        local d = math.max(math.abs(b:getX() - p:getX()), math.abs(b:getY() - p:getY()))
        check(d <= 3, "bob stands within 3 tiles of the admin", string.format("%.1f", d))
    end
    shot("stage")
end)
Events.OnTick.Add(drive)
