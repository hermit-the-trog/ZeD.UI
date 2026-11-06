-- ZeDUI/tools/qa/mp_radio.lua  (Nov 5 2026, QA; MP_CHECK_20261105.md's open item): the Radio tab's keys on a server. They
-- change a set directly, not through the game's timed action. A hand radio from the server (/additem), in the hand; then
-- power, channel and volume the Radio tab's way, then the same three through ZeD.RadioOps (the game's action code). What
-- the client reads is printed and kept in Lua/zedqa_mp_radio.txt; mp_radio_after.lua reads the set again after a rejoin,
-- which is what the server held. grep "ZEDQA mrd".
local function say(s) print("ZEDQA mrd " .. tostring(s)) end
local p = getPlayer()
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function findRadio()
    local l = p:getInventory():getItems()
    for k = 0, l:size() - 1 do local it = l:get(k); if it:getFullType() == "Base.WalkieTalkie3" or it:getFullType() == "Radio.WalkieTalkie3" then return it end end
end
add(300, function()
    if not findRadio() then SendCommandToServer('/additem "' .. p:getUsername() .. '" "Base.WalkieTalkie3" 1') end
end)
add(2500, function()
    local it = findRadio()
    say("radio in the bag: " .. tostring(it and it:getFullType()))
    if it then ISTimedActionQueue.add(ISEquipWeaponAction:new(p, it, 50, true)) end
end)
add(2500, function()
    local it = findRadio()
    if not it then say("ERR no radio"); return end
    local dd = it:getDeviceData()
    say("before: power " .. tostring(dd:getIsTurnedOn()) .. ", channel " .. tostring(dd:getChannel()) .. ", volume " .. tostring(dd:getDeviceVolume()))
    if dd:getIsTurnedOn() then dd:setIsTurnedOn(false) end
    dd:setIsTurnedOn(true)            -- the Radio tab's _powerToggle
    dd:setChannel(96400)              -- its _channelStep / _presetApply
    dd:setDeviceVolume(0.25)          -- its _volStep
    say("the Radio tab's way: power " .. tostring(dd:getIsTurnedOn()) .. ", channel " .. tostring(dd:getChannel()) .. ", volume " .. tostring(dd:getDeviceVolume()))
    local w = getFileWriter("zedqa_mp_radio.txt", true, false)
    w:write("96400 0.25\n"); w:close()
end)
add(1500, function()
    pcall(function() p:Say("radio check") end)
    say("DONE")
end)
local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)); say("DONE") end
end
Events.OnTick.Add(drive)
