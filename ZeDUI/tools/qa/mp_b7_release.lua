-- ZeDUI/tools/qa/mp_b7_release.lua  (Nov 7 2026, QA; merge 1, claims): on the admin client: step out of the building (the game will
-- not let anyone claim a building with someone else in it: "Occupied building"), then release the safehouse (bob's
-- mp_b7_reclaim.lua is already watching from inside to claim it the moment it is free). The server's ZeD log should read a
-- release, then bob's claim, as two lines. grep "ZEDQA arl".
local function say(s) print("ZEDQA arl " .. tostring(s)) end
local C = ZeD.Claims
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local hx, hy
add(500, function() C.refresh() end)
add(3000, function()
    local h = C.safe
    hx, hy = h and h.x, h and h.y
    local x, y = math.floor(getPlayer():getX()) + 45, math.floor(getPlayer():getY())
    say("the admin steps out to " .. x .. "," .. y)
    SendCommandToServer("/teleportto " .. x .. "," .. y .. ",0")
end)
add(9000, function()
    local h = C.safe
    say("releasing " .. tostring(h and h.title) .. " at " .. tostring(h and h.x) .. "," .. tostring(h and h.y) .. " (clock " .. getTimestampMs() .. ")")
    if h then C.release(h, function(ok) say("release done: " .. tostring(ok) .. " (clock " .. getTimestampMs() .. ")") end) end
end)
add(15000, function() C.refresh() end)
add(2000, function()
    say("after: admin holds " .. tostring(C.safe and C.safe.title))
    local b = getPlayerFromUsername("bob")
    say("bob " .. (b and string.format("at %d,%d", math.floor(b:getX()), math.floor(b:getY())) or "not seen") .. "; the house corner " .. tostring(hx) .. "," .. tostring(hy))
end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
    if i > #plan then say("DONE") end
end
Events.OnTick.Add(drive)
