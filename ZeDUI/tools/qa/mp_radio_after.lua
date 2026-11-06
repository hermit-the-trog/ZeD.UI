-- ZeDUI/tools/qa/mp_radio_after.lua  (Nov 5 2026, QA): after a rejoin, the hand radio mp_radio.lua set: did the server keep
-- what the Radio tab's keys set? grep "ZEDQA mra".
local function say(s) print("ZEDQA mra " .. tostring(s)) end
local p = getPlayer()
local l, it = p:getInventory():getItems(), nil
for k = 0, l:size() - 1 do local x = l:get(k); if x:getFullType():find("WalkieTalkie3") then it = x end end
if not it then say("FAIL no radio after the rejoin"); say("DONE"); return end
local dd = it:getDeviceData()
local pw, ch, vo = dd:getIsTurnedOn(), dd:getChannel(), dd:getDeviceVolume()
say("after the rejoin: power " .. tostring(pw) .. ", channel " .. tostring(ch) .. ", volume " .. tostring(vo))
say((ch == 96400 and "PASS" or "FAIL") .. " the channel set by the Radio tab's key reached the server")
say((math.abs((vo or 0) - 0.25) < 0.01 and "PASS" or "FAIL") .. " the volume set by the Radio tab's key reached the server")
say((pw and "PASS" or "NOTE") .. " the power (the game turns a set off on a save in some cases)")
local n9 = 0; local function t9() n9 = n9 + 1; if n9 == 60 then Events.OnTick.Remove(t9); say("DONE") end end; Events.OnTick.Add(t9)
