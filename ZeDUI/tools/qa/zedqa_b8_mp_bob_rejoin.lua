-- ZeDUI/tools/qa/zedqa_b8_mp_bob_rejoin.lua  (Nov 7 2026, QA; beta 8): on BOB's client at the main menu (after the kicked screen's Exit): connect to the local test server
-- again as bob, exactly as mp_client2.ps1 -Start does it (ConnectToServer:connect with the password in Lua/zedqa_mp.txt). It does not
-- wait for the world: the batch waits for the bridge to arm in game, or reads the console if the server refuses him (a ban).
-- grep "ZEDQA b8br".
local TAG = "b8br"
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
        Events.OnFETick.Remove(drive)
    end
end
add(300, function()
    local r = getFileReader("zedqa_mp.txt", false)
    local u, pw = "bob", nil
    if r then
        local l = r:readLine()
        while l do
            local k, v = l:match("^(%w+)=(.*)$")
            if k == "password" then pw = v elseif k == "user" then u = v end
            l = r:readLine()
        end
        r:close()
    end
    check(pw ~= nil, "bob's login file is there", u)
    if not pw then return end
    note("connecting as " .. u)
    local ok, e = pcall(function() ConnectToServer.instance:connect(MainScreen.instance, "", u, pw, "127.0.0.1", "127.0.0.1", "16261", "", false, true, 1) end)
    check(ok, "the connect call went out", e)
end)
Events.OnFETick.Add(drive)
