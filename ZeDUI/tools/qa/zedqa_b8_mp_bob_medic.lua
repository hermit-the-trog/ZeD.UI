-- ZeDUI/tools/qa/zedqa_b8_mp_bob_medic.lua  (Nov 7 2026, QA; beta 8): on BOB's client, the patient for zedqa_b8_mp_medic.lua (start this first; it
-- waits up to 8 minutes). It gives bob a deep wound on the left hand, answers Yes to the admin's medical check requests (three of them: the
-- plain check, the check at First Aid 5, the check in safe mode), and reads that the admin's bandage reached bob's own hand. Puts bob's body
-- back to full health at the end. grep "ZEDQA b8bm".
local TAG = "b8bm"
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
local bd = p:getBodyDamage()
local part = bd:getBodyPart(BodyPartType.Hand_L)
local reqN, finished, seenBandage = 0, false, false
local function prompts()
    local out = {}
    local ui = UIManager.getUI()
    for i = ui:size() - 1, 0, -1 do
        local t = nil
        pcall(function() t = ui:get(i):getTable() end)
        if type(t) == "table" and t.Type == "ZeD_Prompt" and t.requester ~= nil and t.target ~= nil and t.yes and not t._dead then out[#out + 1] = t end
    end
    return out
end
add(500, function()
    pcall(function() part:generateDeepWound() end)
    check(part:HasInjury() or part:isDeepWounded(), "bob has a deep wound on the left hand", tostring(part:isDeepWounded()))
    note("bob's left hand: bandaged " .. tostring(part:bandaged()) .. ", deep wound " .. tostring(part:isDeepWounded()))
end)
local n = 0
local function onTick()
    n = n + 1
    if n % 10 ~= 0 then return end
    local ok, e = pcall(function()
        local ps = prompts()
        if #ps > 0 and not ps[1]._seenB8 then
            local q = ps[1]
            q._seenB8 = true
            reqN = reqN + 1
            check(true, "1: bob's prompt asks for a medical check, request " .. reqN, tostring(q.requester:getDisplayName()))
            shot("medic_prompt_" .. reqN)
            q:press(q.yes)
        end
        if part:bandaged() and not seenBandage then
            seenBandage = true
            check(true, "5: the admin's bandage reached bob's own left hand")
            shot("medic_bob_bandaged")
        end
        if reqN >= 3 and n % 600 == 0 then finished = true end
    end)
    if not ok then say("FAIL ERR react: " .. tostring(e)); nfail = nfail + 1 end
end
Events.OnTick.Add(onTick)
waitFor(480000, function() return finished end, function(to)
    Events.OnTick.Remove(onTick)
    check(reqN >= 3, "bob answered all three medical check requests", reqN)
    check(seenBandage, "5: bob's hand showed the bandage")
    pcall(function() bd:RestoreToFullHealth() end)
    note("bob's body put back to full health")
end)
Events.OnTick.Add(drive)
