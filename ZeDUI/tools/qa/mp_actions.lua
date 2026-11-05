-- ZeDUI/tools/qa/mp_actions.lua  (Nov 5 2026, QA; multiplayer): the open questions from the code read, on the
-- multiplayer client (zedqa_run.ps1 -Mp). grep "ZEDQA mpa".
--   speed   the watch's Start and Speed keys go through the game's speed controls (ZeD_Watch.lua _setSpeed): do the
--           controls exist on a client, and does Pause or Fast Forward change anything (the clock is the server's)
--   action  a ZeD timed action defined only on the client (ZeDOpenCardAction, ObjectCards.lua): does it run to its
--           perform() on a multiplayer client, or does the server refuse it
--   hand    ZeD's Unequip for a hand item empties the hand on the client only (EquipmentTab.lua, setPrimaryHandItem(nil));
--           a hammer is given (admin /additem), equipped with the game's action, then emptied ZeD's way. The rejoin
--           in mp_hand_after.lua shows what the server kept.
local function say(s) print("ZEDQA mpa " .. tostring(s)) end
local p = getPlayer()
local gt = getGameTime()
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local S = {}

-- speed
add(200, function()
    local sc = UIManager.getSpeedControls()
    S.sc = sc
    say("speed controls " .. tostring(sc ~= nil) .. (sc and (" speed " .. tostring(sc:getCurrentGameSpeed())) or "") .. " multiplier " .. tostring(gt:getMultiplier()))
    S.min0 = gt:getMinutes(); S.h0 = gt:getTimeOfDay()
    if sc then local ok, e = pcall(function() sc:ButtonClicked("Pause") end); say("Pause pressed " .. tostring(ok) .. " " .. tostring(e or "")) end
end)
add(4000, function()
    local sc = S.sc
    say(string.format("after Pause: speed %s, time of day %.4f -> %.4f (moved %s)", tostring(sc and sc:getCurrentGameSpeed()), S.h0, gt:getTimeOfDay(), tostring(gt:getTimeOfDay() ~= S.h0)))
    S.h1 = gt:getTimeOfDay()
    if sc then pcall(function() sc:ButtonClicked("Fast Forward x 2") end) end
end)
add(4000, function()
    local sc = S.sc
    say(string.format("after Fast Forward x 2: speed %s, multiplier %s, time moved %.4f h in 4 s", tostring(sc and sc:getCurrentGameSpeed()), tostring(gt:getMultiplier()), gt:getTimeOfDay() - S.h1))
    if sc then pcall(function() sc:ButtonClicked("Play") end) end
end)
-- a client-only ZeD timed action
add(1000, function()
    S.performed = false
    S.orig = ZeDOpenCardAction.perform
    ZeDOpenCardAction.perform = function(self) S.performed = true; say("ZeDOpenCardAction perform() ran on the client"); return S.orig(self) end
    local a = ZeDOpenCardAction:new(p, "zedqa-none", nil)
    ISTimedActionQueue.add(a)
    say("queued ZeDOpenCardAction")
end)
add(5000, function()
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    say("ZeDOpenCardAction performed " .. tostring(S.performed) .. ", queue left " .. tostring(q and q.queue and #q.queue))
    ZeDOpenCardAction.perform = S.orig
    pcall(function() ISTimedActionQueue.clear(p) end)
end)
-- hand
add(500, function()
    SendCommandToServer("/additem \"" .. p:getUsername() .. "\" \"Base.Hammer\"")
    say("asked the server for a hammer")
end)
add(4000, function()
    local h = p:getInventory():getFirstTypeRecurse("Hammer")
    say("hammer in inventory " .. tostring(h ~= nil))
    if h then ISTimedActionQueue.add(ISEquipWeaponAction:new(p, h, 50, true, false)) end
end)
add(5000, function()
    local h = p:getPrimaryHandItem()
    say("after the game's equip: main hand " .. tostring(h and h:getFullType()))
    if h then p:setPrimaryHandItem(nil); if p:getSecondaryHandItem() == h then p:setSecondaryHandItem(nil) end end
    say("ZeD's unequip (hand set empty on the client): main hand now " .. tostring(p:getPrimaryHandItem()))
end)
add(4000, function()
    say("4 s later: main hand " .. tostring(p:getPrimaryHandItem() and p:getPrimaryHandItem():getFullType()))
    say("DONE")
end)

local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
say("start")
