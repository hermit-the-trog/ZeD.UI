-- ZeDUI/tools/qa/zedqa_tiyl_game.lua  (Nov 5 2026, QA; punch list 64): in the new world, what the pick gave: place, name,
-- occupation, traits, the mod's state; both windows open; pictures. grep "ZEDQA tyg".
local function say(s) print("ZEDQA tyg " .. tostring(s)) end
local p = getPlayer()
say(string.format("at %d,%d,%d, %s %s", p:getX(), p:getY(), p:getZ(), p:getDescriptor():getForename(), p:getDescriptor():getSurname()))
say("occupation " .. tostring(p:getDescriptor():getCharacterProfession()))
local tr = {}
pcall(function() local l = p:getCharacterTraits():getKnownTraits(); for k = 0, l:size() - 1 do tr[#tr + 1] = tostring(l:get(k)) end end)
say("traits: " .. table.concat(tr, ", "))
for k, v in pairs(p:getModData()) do if string.find(string.lower(tostring(k)), "tiyl") then say("modData " .. tostring(k) .. " = " .. tostring(v)) end end
local c = p:getVehicle()
say("in a vehicle: " .. tostring(c and c:getScriptName()))
local n = 0
local function t()
    n = n + 1
    if n == 120 then pcall(function() getCore():TakeFullScreenshot("tiyl_game_1.png") end); ZeD_CharacterWindow.toggleBothPaired(0) end
    if n == 300 then pcall(function() getCore():TakeFullScreenshot("tiyl_game_2.png") end); ZeD_CharacterWindow.toggleBothPaired(0); Events.OnTick.Remove(t); say("DONE") end
end
Events.OnTick.Add(t)
