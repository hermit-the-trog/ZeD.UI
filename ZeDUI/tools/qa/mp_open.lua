-- ZeDUI/tools/qa/mp_open.lua  (Nov 6 2026, QA): before a script that spawns a car on the local server: god mode, and open ground, since /addvehicle finds no room
-- beside a character indoors. A new character lands anywhere. grep "ZEDQA mop".
local function say(s) print("ZEDQA mop " .. tostring(s)) end
local p = getPlayer()
local me = p:getUsername()
local SPOTS = { { 10600, 9800 }, { 10605, 10000 }, { 10610, 10400 }, { 10590, 9400 }, { 10650, 9900 } }
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local done = false
add(300, function()
    SendCommandToServer('/godmod "' .. me .. '" -true')
    sendClientCommand(p, 'ZeDQA', 'god', {})
    pcall(function() p:setGodMod(true) end)
    -- (the /godmod command stopped taking on 42.22.2: the shim sets it on the server's object, and a tick keeps the character whole for the rest of the run)
    if not ZEDQA_KEEPWHOLE then
        local n = 0
        ZEDQA_KEEPWHOLE = function()
            n = n + 1
            if n % 60 ~= 0 then return end
            local q = getPlayer()
            if q then pcall(function() q:setGodMod(true); q:getBodyDamage():RestoreToFullHealth() end) end
        end
        Events.OnTick.Add(ZEDQA_KEEPWHOLE)
    end
end)
-- (a German run died on the spot: the command isn't sure to land the first time, so it goes again till the game says yes)
for n = 1, 5 do
    add(1500, function()
        if p:isGodMod() then return end
        say("god mode not on yet, try " .. n)
        SendCommandToServer('/godmod "' .. me .. '" -true')
    end)
end
add(1500, function() say((p:isGodMod() and "PASS" or "FAIL") .. " god mode on") end)
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
