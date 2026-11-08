-- ZeDUI/tools/qa/zedqa_b8_mp_bob_trade.lua  (Nov 7 2026, QA; beta 8): on BOB's client, the other side of zedqa_b8_mp_trade.lua. Start it
-- first (it waits up to 7 minutes). It answers the admin's five requests in order as the check lists them (Yes, Yes, No, no answer at all,
-- Yes) and plays bob: after the first Yes it adds a Pop when the admin has sealed (that unseals the admin), then seals when the admin seals
-- again; on the second trade it waits for the admin to cancel and reads the words; on the fifth it waits 20 s and cancels itself. Reports
-- what bob's card and inventory show. grep "ZEDQA b8bt".
local TAG = "b8bt"
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
local TR = ZeD.Trade
local answers = { "yes", "yes", "no", "gone", "yes" }
local reqN, s, finished = 0, nil, false
local st = { added = false, sealedBack = false, firstDone = false, goneWatch = nil, t5 = nil, readClosed = false, t1At = 0 }
local function prompts()
    local out = {}
    local ui = UIManager.getUI()
    for i = ui:size() - 1, 0, -1 do
        local t = nil
        pcall(function() t = ui:get(i):getTable() end)
        if type(t) == "table" and t.Type == "ZeD_Prompt" and t.requester ~= nil and t.yes and t.target == nil and not t._dead then out[#out + 1] = t end
    end
    return out
end
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
local function now() return getTimestampMs() end
local lastLog = ""
local function logCard()
    if not s then return end
    local line = string.format("his %d your %d sealed %s otherSealed %s block %s", #s.his, #s.your, tostring(s.sealed), tostring(s.otherSealed), tostring(s.blocking))
    if line ~= lastLog then lastLog = line; note("bob's card: " .. line) end
end
local function react()
    local ps = prompts()
    if #ps > 0 and ps[1] ~= st.goneWatch and not st.handling then
        local q = ps[1]
        reqN = reqN + 1
        local what = answers[reqN] or "no"
        note("request " .. reqN .. " from " .. tostring(q.requester:getDisplayName()) .. ": " .. what)
        check(q.requester:getDisplayName() ~= nil, "bob's prompt names the admin (request " .. reqN .. ")")
        shot("trade_prompt_" .. reqN)
        if what == "yes" then
            q:press(q.yes)
            st.handling = true
        elseif what == "no" then
            q:press(q.no)
            st.handling = false
        else
            st.goneWatch = q
        end
        return
    end
    if st.goneWatch and (st.goneWatch._dead or not st.goneWatch:isVisible()) then
        check(true, "13: bob's prompt went away by itself when the admin closed first")
        st.goneWatch = nil
    end
    s = TR.get(p)
    if not s then
        if st.handling and st.opened then
            st.handling = false
            st.opened = false
            note("bob's trade " .. reqN .. " is over; items: apple " .. countOf("Apple") .. ", nails " .. countOf("Nails") .. ", pop " .. countOf("Pop"))
            if reqN == 1 then
                check(countOf("Apple") >= 1, "8: bob has the admin's apple after the deal", countOf("Apple"))
                check(countOf("Nails") >= 1, "8: bob has the admin's nails after the deal", countOf("Nails"))
                note("8: bob has " .. countOf("Pop") .. " pop left (the admin side checks that the pop arrived there; bob may have started with more than one)")
                st.firstDone = true
            end
        end
        return
    end
    st.opened = true
    logCard()
    local c = ZeD_WorldWindow.getObjectCard and ZeD_WorldWindow.getObjectCard()
    if reqN == 1 then
        if not st.shown then
            st.shown = true
            check(s.blocking == nil, "2: bob's card has no waiting box", s.blocking)
            check(c ~= nil and c.entry and c.entry.t and c.entry.t.s == s, "2: bob's World window opened on the trade card")
            shot("trade_bob_open")
            -- bob's own offer starts empty; the admin's offer arrives under "his"
        end
        if #s.his >= 2 and not st.sawHis then
            st.sawHis = true
            check(true, "4: the admin's offer shows on bob's card, read only", #s.his)
            local log = s.log and s.log[#s.log]
            check(log ~= nil and has(log.message, "added"), "4: the line and the Trade Log say what was added", log and log.message)
            shot("trade_bob_his")
        end
        if s.otherSealed and #s.your == 0 and not st.added then
            st.added = true
            check(true, "6: bob sees that the admin sealed")
            local pop = firstOf("Pop")
            if pop then s:addItem(pop); s:rebuild() end
            check(#s.your == 1, "7: bob's added Pop is on his offer", #s.your)
        end
        if st.added and s.otherSealed and not s.sealed and #s.your >= 1 and not st.sealedBack then
            st.sealedBack = true
            s:setSealed(true)
            check(s.sealed, "8: bob seals his offer")
        end
    end
    if reqN == 2 and s.blocking and has(s.blocking, "closed") and not st.readClosed then
        st.readClosed = true
        check(true, "10: bob's card says the admin closed their trading window", s.blocking)
        shot("trade_bob_closed")
        s:finish()   -- (his card closed on his side, no word to the admin, so the next request finds bob free)
    end
    if reqN == 2 and not st.sawFar and s.blocking2 then
        st.sawFar = true
        check(has(s.blocking2, "far"), "9: bob's card also says too far away", s.blocking2)
    end
    if reqN == 5 then
        st.t5 = st.t5 or now()
        if now() - st.t5 > 20000 and s.open then
            s:cancel()
            check(not s.open, "16: bob cancels; his card closes")
            finished = true
        end
    end
end
local n = 0
local function onTick()
    n = n + 1
    if n % 10 ~= 0 then return end
    local ok, e = pcall(react)
    if not ok then say("FAIL ERR react: " .. tostring(e)); nfail = nfail + 1 end
end
Events.OnTick.Add(onTick)
waitFor(420000, function() return finished end, function(to)
    Events.OnTick.Remove(onTick)
    check(not to, "all five requests were answered", "requests seen " .. reqN)
    check(st.firstDone, "the first trade completed on bob's side")
end)
Events.OnTick.Add(drive)
