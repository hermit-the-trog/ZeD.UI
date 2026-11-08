-- ZeDUI/tools/qa/zedqa_b8_mp_trade.lua  (Nov 7 2026, QA; beta 8): on the ADMIN client, CHECK_trade_medic_20261107.md, the Trade half, steps 1 to
-- 13, 15 and 16, against bob (zedqa_b8_mp_bob_trade.lua on bob's client, started first). The admin must hold what zedqa_b8_mp_stage.lua gave.
-- Trade 1: ask, waiting card, bob's Yes, the lists, add, the 20-item rule, seal, bob's change unseals, both seal, Accept. Trade 2: distance,
-- pinned (tab switch, shut window), Cancel. Trade 3: bob says No. Trade 4: the admin closes before bob answers. Trade 5: Yes, then safe mode
-- mid-trade ends it, and bob cancels in his own slot. Steps 14 and 17, the controller and the 4K/Deck pictures are manual.
-- grep "ZEDQA b8tr". Pictures: zqa_b8_trade_*.png.
local TAG = "b8tr"
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
local TR = ZeD.Trade
local p = getPlayer()
local s
local function bobp() return getPlayerFromUsername("bob") end
local function firstOf(t)
    local l = p:getInventory():getItems()
    for i = 0, l:size() - 1 do if l:get(i):getType() == t then return l:get(i) end end
    return nil
end
local function countOf(t)
    local n, l = 0, p:getInventory():getItems()
    for i = 0, l:size() - 1 do if l:get(i):getType() == t then n = n + 1 end end
    return n
end
local function cardT()
    local c = ZeD_WorldWindow.getObjectCard and ZeD_WorldWindow.getObjectCard()
    return c and c.entry and c.entry.t
end
local function labels(sess)
    local o = {}
    for _, g in ipairs(sess.groups) do o[#o + 1] = tostring(g.label) .. ":" .. #g.items end
    return table.concat(o, ", ")
end
local function groupOf(sess, w)
    for _, g in ipairs(sess.groups) do if has(g.label, w) then return g end end
    return nil
end
local function ask()
    local b = bobp()
    if b then ISWorldObjectContextMenu.onTrade({}, p, b) end
end
local wasSafe
local optS = ZeD.Settings and ZeD.Settings.safeModeOption

-- ---- trade 1
add(300, function()
    check(bobp() ~= nil, "bob is on the server")
    check(TR.canOpen(p), "ZeD's trade can open (World window is ZeD's, not safe mode)")
    wasSafe = optS and optS:getValue() or 1
    ask()
end)
waitFor(5000, function() return TR.get(p) ~= nil end, function(to)
    s = TR.get(p)
    check(s ~= nil, "1: Trade with bob opened ZeD's trade card", to and "timed out" or nil)
    if not s then return end
    check(cardT() ~= nil and cardT().s == s, "1: the card is in the World window's drawer")
    check(s.pending and has(s.blocking, "bob"), "1: the red box waits for bob's answer", s.blocking)
    local ok, why = s:canAccept()
    check(ok == false, "1: Accept deal is grayed", why)
    local ui = ISTradingUI and ISTradingUI.GetUIForPlayer(p)
    check(ui ~= nil and ui:isVisible(), "1: the game's guard is up (no inventory context menu while trading)")
    ticks(20, function() shot("trade_waiting") end)
end)
waitFor(90000, function() return s and s.open and s.blocking == nil and not s.pending end, function(to)
    check(not to and s ~= nil, "2: bob said Yes; the waiting box is gone", to and "no answer in 90 s" or nil)
end)
add(500, function()
    if not s then return end
    s:rebuild()
    note("groups: " .. labels(s))
    check(groupOf(s, "apple") ~= nil, "3: the apple is listed")
    check(groupOf(s, "nails") ~= nil, "3: nails are listed")
    check((groupOf(s, "ripped") or groupOf(s, "rag")) ~= nil, "3: the ripped sheets (Rag on 42.21) are listed")
    -- (Nov 8: the server keeps the admin's inventory between runs and the stage adds one jacket,
    -- knife and watch per run, so plain copies pile up; only the ONE worn, held or favorite copy
    -- must stay off the list. The old check wanted no "jacket" group at all, which fails as soon
    -- as a second, unworn jacket exists: 10 runs left 10 of each, 9 listed. So the worn, held
    -- and favorite objects are found by id and looked for in every group, and each type's
    -- listed count must be its main-inventory count less those.)
    local function idOf(it) return safe(function() return it:getID() end, nil) end
    local special, specialN = {}, {}
    local function mark(it, why)
        local id = it and idOf(it)
        if id == nil or special[id] then return end
        special[id] = why .. " " .. tostring(it:getType())
        specialN[it:getType()] = (specialN[it:getType()] or 0) + 1
    end
    pcall(function()
        local worn = p:getWornItems()
        for i = 0, worn:size() - 1 do mark(worn:get(i):getItem(), "worn") end
    end)
    mark(p:getPrimaryHandItem(), "held"); mark(p:getSecondaryHandItem(), "held")
    pcall(function()
        local l = p:getInventory():getItems()
        for i = 0, l:size() - 1 do if l:get(i):isFavorite() then mark(l:get(i), "favorite") end end
    end)
    local jw, kh, wf = false, false, false
    for _, why in pairs(special) do
        if why == "worn Jacket_Black" then jw = true end
        if why == "held HuntingKnife" then kh = true end
        if why == "favorite WristWatch_Left_DigitalBlack" then wf = true end
    end
    check(jw and kh and wf, "3: the stage left a worn jacket, a knife in hand and a favorite watch",
        "jacket " .. tostring(jw) .. ", knife " .. tostring(kh) .. ", watch " .. tostring(wf))
    local leaked = {}
    for _, g in ipairs(s.groups) do
        for _, it in ipairs(g.items) do
            local id = idOf(it)
            if id ~= nil and special[id] then leaked[#leaked + 1] = special[id] end
        end
    end
    check(#leaked == 0, "3: worn, held and favorite things are not listed", #leaked > 0 and table.concat(leaked, ", ") or nil)
    for _, t in ipairs({ { "Jacket_Black", "jacket" }, { "HuntingKnife", "knife" }, { "WristWatch_Left_DigitalBlack", "watch" } }) do
        local g = groupOf(s, t[2])
        local want = math.min(s:max(), countOf(t[1]) - (specialN[t[1]] or 0))
        local got = g and #g.items or 0
        check(got == want, "3: the " .. t[2] .. " copies listed are the main inventory's less the worn, held or favorite one",
            got .. " of " .. countOf(t[1]))
    end
    local b = groupOf(s, "bandage")
    check(b == nil or #b.items == countOf("Bandage"), "3: only the main inventory's bandage is listed, not the backpack's", b and #b.items)
    ticks(20, function() shot("trade_lists") end)
end)
add(1500, function()
    if not s then return end
    local apple = firstOf("Apple")
    check(apple ~= nil and s:addItem(apple), "4: the apple goes on the offer")
    local g = groupOf(s, "nails")
    if g then s:addGroup(g) end
    s:rebuild()
    check(#s.your >= 2, "4: the apple and the nails are on the offer", #s.your)
    ticks(20, function() shot("trade_offer") end)
end)
add(4000, function()
    if not s then return end
    -- 5: the 20-item rule: pencils up to the limit, the 21st is refused with the game's words
    local g = groupOf(s, "pencil")
    local refused = nil
    if g then
        for _, it in ipairs(g.items) do
            if #s.your >= s:max() then break end
            s:addItem(it)
        end
        s:rebuild()
        local g2 = groupOf(s, "pencil")
        local extra = g2 and g2.items[1]
        if extra then refused = s:addItem(extra) end
    end
    check(#s.your == s:max(), "5: the offer holds exactly 20 items", #s.your)
    check(refused == false, "5: the 21st Add is refused")
    check(s:flashText() ~= nil, "5: the card says why", s:flashText())
    -- an offered item that leaves the main inventory (a client-side move into the backpack) comes off the offer
    local off = s.your[#s.your]
    local bag = firstOf("Bag_Schoolbag")
    if off and bag and bag:getInventory() then
        local n0 = #s.your
        pcall(function() p:getInventory():Remove(off); bag:getInventory():AddItem(off) end)
        ticks(30, function()
            check(#s.your == n0 - 1 and not s:isOffered(off), "5: an offered thing moved into the backpack comes off the offer", #s.your)
            pcall(function() bag:getInventory():Remove(off); p:getInventory():AddItem(off) end)
        end)
    else
        note("5: no backpack to move an offered thing into")
    end
end)
add(3500, function()
    if not s then return end
    -- back to the apple and the nails only
    local drop = {}
    for _, it in ipairs(s.your) do if it:getType() ~= "Apple" and it:getType() ~= "Nails" then drop[#drop + 1] = it end end
    for _, it in ipairs(drop) do s:removeItem(it) end
    s:rebuild()
    check(#s.your >= 2 and #s.your <= 20, "5: the offer is back to the apple and the nails", #s.your)
end)
add(2500, function()
    if not s then return end
    s:setSealed(true)
    check(s.sealed, "6: Seal offer is ticked")
    local ok, why = s:canAccept()
    check(ok == false and has(why, "sealed"), "6: Accept deal stays grayed until both are sealed", why)
    ticks(20, function() shot("trade_sealed") end)
end)
waitFor(30000, function() return s and not s.sealed and #s.his >= 1 end, function(to)
    check(not to, "7: bob's added item unsealed the admin's offer", to and ("sealed " .. tostring(s and s.sealed) .. ", his " .. tostring(s and #s.his)) or nil)
    local log = s and s.log and s.log[#s.log]
    check(log ~= nil and has(log.message, "bob"), "7: the log lists bob's add", log and log.message)
    if s then s:setSealed(true) end
end)
waitFor(30000, function() return s and s.sealed and s.otherSealed end, function(to)
    check(not to, "8: both offers are sealed", to and "bob never sealed" or nil)
    if not s then return end
    local ok = s:canAccept()
    check(ok == true, "8: Accept deal is lit")
    ticks(20, function() shot("trade_ready") end)
end)
local before = {}
add(2000, function()
    if not s then return end
    before = { apple = countOf("Apple"), nails = countOf("Nails"), pop = countOf("Pop") }
    s:accept()
    check(not s.open, "8: Accept deal closes the card")
end)
waitFor(25000, function() return countOf("Nails") == 0 and countOf("Pop") >= 1 end, function(to)
    check(not to, "8: the items swapped in the admin's inventory (the server moved them)", string.format("apple %d->%d, nails %d->%d, pop %d->%d", before.apple or -1, countOf("Apple"), before.nails or -1, countOf("Nails"), before.pop or -1, countOf("Pop")))
    local ui = ISTradingUI and ISTradingUI.GetUIForPlayer(p)
    check(TR.get(p) == nil and not (ui and ui:isVisible()), "8: the guard is down after the deal")
end)

-- ---- trade 2: distance, pinned, cancel
add(1500, function() s = nil; ask() end)
waitFor(30000, function() s = TR.get(p); return s and s.open and s.blocking == nil and not s.pending end, function(to)
    check(not to and s ~= nil, "9: the second trade opened and bob answered", to and "no answer" or nil)
    if not s then return end
    local x, y, z = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    SendCommandToServer("/teleportto " .. (x + 4) .. "," .. y .. "," .. z)
end)
add(5000, function()
    if not s then return end
    check(s.blocking2 ~= nil and has(s.blocking2, "far"), "9: 'Too far away from bob!' once 4 tiles apart", s.blocking2)
    local ok = s:canAccept()
    check(ok == false, "9: every control but Close is grayed (Accept deal is)")
    ticks(20, function() shot("trade_far") end)
    local x, y, z = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    SendCommandToServer("/teleportto " .. (x - 4) .. "," .. y .. "," .. z)
end)
add(5000, function()
    if not s then return end
    check(s.blocking2 == nil, "9: the far box clears when the admin walks back", s.blocking2)
    -- 11: pinned. Another tab: the card comes straight back
    pcall(function() ZeD_WorldWindow.openTab(0, "loot") end)
end)
add(2500, function()
    if not s then return end
    check(s.open and cardT() ~= nil and cardT().s == s, "11: after the Loot tab the trade card is back at once")
    -- the World window shut: bob sees nothing change; the trade is still open
    pcall(ZeD_WorldWindow.close)
end)
add(2000, function()
    if not s then return end
    check(s.open and not ZeD_WorldWindow.isOpen(), "11: with the World window shut the trade is still open (bob is not told)")
    pcall(function() ZeD_WorldWindow.open(0) end)
end)
add(2500, function()
    if not s then return end
    check(ZeD_WorldWindow.isOpen() and cardT() ~= nil and cardT().s == s, "11: opening the window again shows the trade card")
    manual("11: an item card over the trade, a generator's Info card over it, and a shut window opening by itself when bob adds an item")
    s:cancel()
    check(not s.open, "10: Cancel closes the card")
end)

-- ---- trade 3: bob says No
add(2500, function() s = nil; ask() end)
waitFor(30000, function() s = TR.get(p); return s and s.blocking and has(s.blocking, "refused") end, function(to)
    check(not to, "12: bob said No: 'bob refused to trade with you.'", s and s.blocking or "no session")
    if s then
        check(s.released == true, "12: the guard let go at once")
        shot("trade_refused")
        s:cancel()
    end
end)

-- ---- trade 4: the admin closes before bob answers (bob's script reads that his prompt goes)
add(2500, function() s = nil; ask() end)
add(6000, function()
    s = TR.get(p)
    if s then s:cancel() end
    check(TR.get(p) == nil, "13: the admin closes the card before bob answers")
end)

-- ---- trade 5: Yes, then safe mode mid-trade
add(4000, function() s = nil; ask() end)
waitFor(30000, function() s = TR.get(p); return s and s.open and s.blocking == nil and not s.pending end, function(to)
    check(not to and s ~= nil, "15: the fifth trade opened and bob answered", to and "no answer" or nil)
    if optS then pcall(function() optS:setValue(2) end) end
end)
waitFor(10000, function() return TR.get(p) == nil end, function(to)
    check(not to, "15: safe mode on ends the ZeD trade as Cancel")
    local ui = ISTradingUI and ISTradingUI.GetUIForPlayer(p)
    check(not (ui and ui:isVisible()), "15: the admin can right-click and move items at once")
    if optS then pcall(function() optS:setValue(wasSafe or 1) end) end
    manual("14: Safe mode on, then Trade with bob: the game's own trading window on both sides")
    manual("16: bob's Cancel is read on bob's client (b8bt prints it)")
    manual("controller pass, 4K 1.75x and Deck pictures: look at zqa_b8_trade_*.png")
end)
Events.OnTick.Add(drive)
