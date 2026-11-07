-- ZeDUI/tools/qa/mp_b7_safe_join.lua  (Nov 7 2026, QA; merge 1, claims, a real second player): on bob's client, with the admin's
-- invitation waiting (mp_b6a_invite.lua). Bob presses Accept in ZeD's note; in that same moment safe mode goes on (the
-- player's own Safe mode switch, ZeD.Settings.safeModeOption) and a second invitation to a safehouse arrives while the yes
-- is still on its way. Two of them, raised through the game's own event:
--   A  ZeD's note takes it: it must wait as a note, not go to the game's pop-up, until the yes lands
--   B  ZeD's note fails (C.onSafeInvite made to throw for that one call): the game's pop-up must wait too (C.runLate)
-- Without the fix the game's pop-up would show at once (bob has no safehouse yet), and a press on it is the kick.
-- Checked: no game invitation pop-up at any moment, the join lands, no note left, bob still on the server 15 s later.
-- Safe mode is put back to Off at the end. grep "ZEDQA bsj".
local function say(s) print("ZEDQA bsj " .. tostring(s)) end
local pass, fail = 0, 0
local function check(ok, what, d)
    if ok then pass = pass + 1 else fail = fail + 1 end
    say((ok and "PASS " or "FAIL ") .. what .. (d ~= nil and (" (" .. tostring(d) .. ")") or ""))
end
local C = ZeD.Claims
local opt = ZeD.Settings and ZeD.Settings.safeModeOption
local function now() return getTimestampMs() end
local function hasHouse() return SafeHouse.hasSafehouse(getPlayer()) ~= nil end
-- the game's invitation pop-ups: its own table of them (ISSafehouseUI.inviteDialogs, filled by its handler) and any modal
-- on screen that carries its invitation text
local modalSeen, modalWhen = false, nil
local function scanModals()
    local any = false
    for _, d in pairs(ISSafehouseUI and ISSafehouseUI.inviteDialogs or {}) do
        if d then any = true end
    end
    if any and not modalSeen then modalSeen, modalWhen = true, now() end
end
Events.OnTick.Add(scanModals)

local plan, i, t0 = {}, 1, now()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local inv, answeredAt, landed, landedOk, heldDuring, lateN = nil, nil, nil, nil, nil, nil
add(500, function() C.ask(); say("safe mode " .. tostring(ZeD.Safe.on("windows")) .. ", bob has a house " .. tostring(hasHouse())) end)
add(6000, function()
    inv = nil
    for _, it in ipairs(C.invites) do if it.kind == "safe" then inv = it end end
    check(inv ~= nil, "the admin's invitation is a note in ZeD", inv and inv.host)
    if not inv then return end
    check(opt ~= nil, "the Safe mode switch is there")
    -- the press, then in the same moment safe mode on and two more invitations to a safehouse arriving
    answeredAt = now()
    C.answer(inv, true, function(ok, why) landed, landedOk = now(), ok; say("the yes: " .. tostring(ok) .. " " .. tostring(why) .. " after " .. (now() - answeredAt) .. " ms") end)
    pcall(function() opt:setValue(2) end)
    ZeD.Safe.reread()
    say("safe mode now " .. tostring(ZeD.Safe.on("windows")) .. "; bob has a house " .. tostring(hasHouse()))
    -- A: ZeD's note takes it
    triggerEvent("ReceiveSafehouseInvite", inv.obj, inv.host, inv.user)
    heldDuring = #C.invites
    say("A raised: notes " .. heldDuring .. ", a game pop-up " .. tostring(modalSeen))
    -- B: ZeD's note fails, so the game's handler is the one that must wait
    local was = C.onSafeInvite
    C.onSafeInvite = function() error("QA: the note fails for this one") end
    triggerEvent("ReceiveSafehouseInvite", inv.obj, inv.host, inv.user)
    C.onSafeInvite = was
    scanModals()
    say("B raised: a game pop-up " .. tostring(modalSeen) .. "; bob has a house " .. tostring(hasHouse()))
    check(not hasHouse(), "both arrived while the yes was still on its way (no house yet)")
    check(heldDuring >= 1, "A waits as a note while the yes is on its way, not as the game's pop-up", heldDuring)
end)
add(9000, function()
    C.refresh()
    check(landed ~= nil and landedOk == true, "the yes landed: bob joined the house", landed and (landed - answeredAt) .. " ms")
    check(hasHouse(), "bob holds the house")
end)
add(3000, function()
    scanModals()
    check(not modalSeen, "no game invitation pop-up at any moment (the second answer, the kick, never offered)", modalWhen and (modalWhen - answeredAt) .. " ms after the press")
    check(#C.invites == 0, "the held note is gone once the yes landed (the game's handler dropped it: bob has a house)", #C.invites)
end)
add(15000, function()
    local p = getPlayer()
    check(p ~= nil and isClient() and hasHouse(), "bob still on the server 25 s later, still a member")
end)
add(500, function()
    pcall(function() opt:setValue(1) end)
    ZeD.Safe.reread()
    say("safe mode put back: " .. tostring(ZeD.Safe.on("windows")))
    Events.OnTick.Remove(scanModals)
    say(pass .. " passed, " .. fail .. " failed")
end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if now() - t0 < st.ms then return end
    t0 = now(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
    if i > #plan then say("DONE") end
end
Events.OnTick.Add(drive)
