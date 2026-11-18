-- ZeDUI/tools/qa/gallery_v1_c1_end.lua  (Nov 17 2026, QA): the last of set c1's scripts in both runs (gallery_v1_c1_zed.txt,
-- gallery_v1_c1_van.txt), before gallery_reload.lua. Puts back what gallery_v1_c1_common.lua saved when it loaded:
-- the character's place (the QA home, via the same teleport) and facing, the grid power, invisible, god mode and
-- zombies-don't-attack, the game speed; then clears C1.was so the next run saves afresh. Waits for the home square to
-- load (at most about 50 s). grep "ZEDQA c1e".
if not (C1 and C1.was) then print("ZEDQA c1e nothing to put back (gallery_v1_c1_common.lua did not run)"); print("ZEDQA c1e DONE"); return end
local S = C1.make("c1e")
S.step(5, function()
    local W = C1.was
    C1.hold, C1.extraBoxes = nil, nil
    C1.closeMenus()
    pcall(function() ISTimedActionQueue.clear(C1.p) end)
    if C1.gridOn then C1.grid(false) end
    C1.tp(W.x, W.y, W.z)
    S.t0 = getTimestampMs()
end)
S.waitFor(5, 3000, function() return C1.sqAt(math.floor(C1.was.x), math.floor(C1.was.y), math.floor(C1.was.z)) ~= nil and getTimestampMs() - S.t0 > 6000 end, function(ok)
    local W = C1.was
    C1.tp(W.x, W.y, W.z)
    pcall(function() if W.dir then C1.p:setDir(W.dir) end end)
    pcall(function() C1.p:setInvisible(W.inv == true) end)
    pcall(function() C1.p:setGodMod(W.god == true) end)
    pcall(function() C1.p:setZombiesDontAttack(W.zda == true) end)
    pcall(function() if W.speed and W.speed > 0 then (ZEDQA_SPEED or setGameSpeed)(W.speed) end end)
    S.say(string.format("put back: the place %d,%d,%d%s, the grid power, the cheats, the speed", math.floor(W.x), math.floor(W.y), math.floor(W.z),
        ok and "" or " (the square was not loaded in time: placed anyway)"))
end)
S.step(5, function() C1.was, C1.here = nil, nil end)
S.start()
