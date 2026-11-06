-- ZeDUI/tools/qa/mp_open.lua  (Nov 6 2026, QA): before a script that spawns a car on the local server: god mode, and open ground, since /addvehicle finds no room
-- beside a character indoors. A new character lands anywhere. grep "ZEDQA mop".
local function say(s) print("ZEDQA mop " .. tostring(s)) end
local p = getPlayer()
local me = p:getUsername()
local SPOTS = { { 10600, 9800 }, { 10605, 10000 }, { 10610, 10400 }, { 10590, 9400 }, { 10650, 9900 } }
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local done = false
add(300, function() SendCommandToServer('/godmod "' .. me .. '" -true') end)
for _, s in ipairs(SPOTS) do
    add(600, function() if not done then SendCommandToServer("/teleportto " .. s[1] .. "," .. s[2] .. ",0") end end)
    add(5000, function()
        if done then return end
        local sq = p:getCurrentSquare()
        local clear = sq ~= nil and sq:getBuilding() == nil and sq:isFree(false)
        say("at " .. math.floor(p:getX()) .. "," .. math.floor(p:getY()) .. ": outdoors and free " .. tostring(clear))
        if clear then done = true end
    end)
end
add(300, function() say((done and "PASS" or "FAIL") .. " open ground"); say("DONE") end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
