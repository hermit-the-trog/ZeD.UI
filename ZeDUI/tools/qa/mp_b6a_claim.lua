-- ZeDUI/tools/qa/mp_b6a_claim.lua  (Nov 6 2026, QA; beta 6a, a real second player): on the admin client: god mode, then claim a safehouse, the walk from mp_claims.lua. grep "ZEDQA acm".
local function say(s) print("ZEDQA acm " .. tostring(s)) end
local function pass(n, ok, d) say((ok and "PASS " or "FAIL ") .. n .. (d ~= nil and (" (" .. tostring(d) .. ")") or "")) end
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local C = ZeD.Claims
local p = getPlayer()
local function goTo(x, y) SendCommandToServer("/teleportto " .. tostring(x) .. "," .. tostring(y) .. ",0") end
local TRIED = {}
local function indoors(r)
    local cx, cy = math.floor(p:getX()), math.floor(p:getY())
    local cell = getCell()
    for d = 1, r do for dx = -d, d do for dy = -d, d do
        if math.abs(dx) == d or math.abs(dy) == d then
            local sq = cell:getGridSquare(cx + dx, cy + dy, 0)
            if sq and sq:getBuilding() and not SafeHouse.getSafeHouse(sq) and not TRIED[sq:getBuilding():getID()] then
                TRIED[sq:getBuilding():getID()] = true
                return cx + dx, cy + dy
            end
        end
    end end end
    return nil
end
local SPOTS = { { 10795, 10030 }, { 10737, 10234 }, { 10650, 10267 }, { 10815, 10037 }, { 11900, 6900 }, { 8100, 11500 }, { 6300, 5300 }, { 10300, 12700 } }
local spot, claimed
add(500, function() sendClientCommand(p, "ZeDQA", "god", {}); pcall(function() p:setGodMod(true) end); C.refresh() end)
add(3000, function() if C.safe then spot = 0; claimed = true; say("already holds " .. tostring(C.safe.title)) end end)
for n = 1, #SPOTS do
    add(500, function() if not spot then goTo(SPOTS[n][1], SPOTS[n][2]) end end)
    add(7000, function() end)
    for try = 1, 4 do
        add(300, function() if spot then return end; local x, y = indoors(40); if x then SendCommandToServer("/removezombies -remove true -radius 40"); goTo(x, y) end end)
        add(3500, function()
            if spot then return end
            C.claim = nil
            local a = C.claimCheck()
            if a and a.ok then spot = n; C.doClaim(function(ok) claimed = ok end) end
            if a and not a.ok then say("no claim: " .. table.concat(a.lines or {}, " | ")) end
        end)
    end
end
add(9000, function() pass("a safehouse held", claimed == true and C.safe ~= nil, C.safe and C.safe.title) end)
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
