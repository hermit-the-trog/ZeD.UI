-- ZeDUI/tools/qa/zedqa_b8_mp_bob_leave_kick.lua / _ban.lua (one body, two files; Nov 7 2026, QA; beta 8): on BOB's client, started before the admin kicks
-- (or bans) him. Waits up to 150 s for ZeD's "Disconnected" desk screen (ZeD.LeftScreen), then reads it: the kind (kick expected),
-- the head words, the game's words in the slot, the appeal line for a ban and none for a kick, the window inside the screen (at
-- 4K and the Deck alike), the game's own screen kept out of sight for its two calls. Then Exit goes to the main menu: the desk comes back
-- and the next script (zedqa_b8_mp_bob_desk.lua) runs there. grep "ZEDQA b8bl" (the kick file) or "b8bq" (the ban file).
local TAG = "b8bl"
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
        Events.OnTick.Remove(drive); if Events.OnFETick then Events.OnFETick.Remove(drive) end
    end
end
local LS, A2 = ZeD.LeftScreen, ZeD.Admin
local seenAt
local function up() return LS.win ~= nil end
waitFor(150000, up, function(to)
    check(not to, "C17: the desk's Disconnected screen came up on bob's client", to and "no screen in 150 s" or nil)
    if to then return end
    local w = LS.win
    local info = w.info or {}
    note("kind " .. tostring(info.kind) .. ", reason '" .. tostring(info.reason) .. "', appeal '" .. tostring(info.appeal) .. "'")
    check(info.kind == "kick", "C17: the screen knows this is a kick", info.kind)
    local head, below = LS.lines(info)
    note("head: " .. tostring(head) .. " | below: " .. table.concat(below, " / "))
    if "kick" == "kick" then
        check(has(head, "kick"), "C17 1: it says You were kicked", head)
        check(#below == 0, "C17 1: no appeal line for a kick", #below)
    else
        check(has(head, "ban"), "C17 2: it says You were banned", head)
    end
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    check(w:getX() >= 0 and w:getY() >= 0 and w:getX() + w:getWidth() <= sw and w:getY() + w:getHeight() <= sh, "C17 4: the window sits inside the screen", string.format("%dx%d at %d,%d on %dx%d", w:getWidth(), w:getHeight(), w:getX(), w:getY(), sw, sh))
    check(LS.game == nil or not LS.game:isVisible(), "C17: the game's own screen is out of sight, kept for its two calls", tostring(LS.game ~= nil))
    if w._slot then
        local slotMid = w:getY() + w._slot.y + math.floor(w._slot.h / 2)
        check(math.abs(slotMid - math.floor(sh / 2)) <= math.floor(sh / 20), "C17 4: the dark slot sits at the middle of the screen, where the engine draws its line", slotMid .. " vs " .. math.floor(sh / 2))
    end
    ticks(40, function() shot("leave_kick") end)
end)
add(2500, function()
    if not LS.win then return end
    manual("C17 1, 2: read the engine's own line inside the dark slot in the picture zqa_b8_leave_kick.png; 4K and Deck, Normal and Large text; Quit to desktop and the pad (A on Exit, B moves to Quit)")
    pcall(LS.exit)
end)
Events.OnTick.Add(drive)
-- (Nov 8 QA) after the kick or the ban the game is on the front end, where OnTick does not run: the script went quiet there and the batch waited for nothing. OnFETick carries it on.
if Events.OnFETick then Events.OnFETick.Add(drive) end
