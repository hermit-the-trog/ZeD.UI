-- ZeDUI/tools/qa/gallery_v1_b_fish.lua  (Nov 17 2026, QA): the ZeD-GUI 1.0 gallery's picture 59 Fishing: the World
-- window's Fishing tab, rod in hand, the line cast AT WATER (beta 19's was cast on mowed grass). Needs
-- gallery_v1_b_lib.lua first.
--   g1_59_fishing   the line out in the water (the game's Wait state), the Fishing tab showing, the window pair at
--                   its default places (the character and the water clear between them; logged)
-- The water: a dry square with open water at least 6 squares straight ahead (GV1.findShore: the square's flag
-- IsoFlagType.water), looked for round West Point first (lived-in), then the shore zedqa_fishing_tab_live.lua fishes
-- at (13913,4555), then the QA home. The gear as the game gives it: a Base.FishingRod (hook and line on it) equipped
-- by the equip action, a worm put on by the game's Add Bait (ISInventoryPaneContextMenu.addLure).
-- No mouse helper here: the aim is the game's aim point stood in for (Fishing.Utils.getAimCoords answers the water
-- square 5 ahead for this character, as the game's controller aim answers a square along the facing); the cast is
-- the game's cast button stood in for once (Fishing.Utils.isCastButtonPressed true for one call), as
-- zedqa_fishing_tab_live.lua does without its helper. No fast-forward; nothing waits for a bite.
-- Puts back: the line in (the tab's stop, the manager to None), aiming off, the hands as they were, the rod, worms
-- and anything caught out, the place. grep "ZEDQA g1bf".
local S = GV1 and GV1.new("g1bf")
if not S then print("ZEDQA g1bf ERR run gallery_v1_b_lib.lua first"); print("ZEDQA g1bf DONE"); return end
S.L = GV1
S.CW, S.WW = ZeD_CharacterWindow, ZeD_WorldWindow
S.FT = ZeD.FishingTab
S.PLACES = {
    { x = 11700, y = 6620, name = "West Point, north" },
    { x = 12050, y = 6560, name = "West Point, north east" },
    { x = 12350, y = 6850, name = "West Point, east" },
    { x = 11150, y = 6950, name = "West Point, west" },
    { x = 11600, y = 7350, name = "West Point, south" },
    { x = 13913, y = 4555, name = "the shore of zedqa_fishing_tab_live.lua" },
    { x = 925, y = 13040, name = "the QA home" },
}
function S.mgr() return Fishing and Fishing.ManagerInstances and Fishing.ManagerInstances[S.pn] or nil end
function S.state()
    local m = S.mgr()
    if not m then return "nomanager" end
    for k, v in pairs(m.states or {}) do if v == m.state then return k end end
    return "?"
end
function S.queueEmpty()
    local q = ISTimedActionQueue.getTimedActionQueue(S.p)
    return not (q and q.queue and #q.queue > 0)
end
function S.pairOpen() if not S.CW.isOpen(S.pn) then pcall(S.CW.toggleBothPaired, S.pn) end end

S.step(10, function()
    S.home = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
    S.h1, S.h2 = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem()
    S.L.keepCheats(S)
    if ZEDQA_SPEED then ZEDQA_SPEED(1) elseif getGameSpeed() ~= 1 then setGameSpeed(1) end
    S.L.cheats(S); S.L.console()
    S.ids = {}
    pcall(function() local items = S.inv:getItems(); for k = 0, items:size() - 1 do S.ids[items:get(k):getID()] = true end end)
end)
S.L.tryPlaces(S, S.PLACES, S.L.findShore, "shore")
S.step(5, function()
    local f = S.shore
    if not f then S.say("ERR no shore with open water found at any place"); return end
    S.L.moveTo(S, f.x + 0.5, f.y + 0.5, 0)
    pcall(function() S.p:setDir(IsoDirections[f.dir]) end)
    S.say(string.format("at the shore %d,%d (%s) facing %s, the target %.1f,%.1f, fish in front %s", f.x, f.y, f.place, f.dir, f.tx, f.ty, tostring(f.fish)))
end)
-- the gear
S.step(60, function()
    if not S.shore then return end
    S.rod = S.L.give(S, "Base.FishingRod")
    S.worm = S.L.give(S, "Base.Worm")
    S.L.give(S, "Base.Worm")
    if not S.rod then S.say("ERR no rod"); return end
    local two = false
    pcall(function() two = S.rod:isTwoHandWeapon() end)
    ISInventoryPaneContextMenu.equipWeapon(S.rod, true, two, S.pn)
    S.t = 0
end)
S.step(10, function()
    if not S.rod then return end
    S.t = S.t + 1
    if not (S.queueEmpty() and S.p:getPrimaryHandItem() == S.rod) and S.t < 150 then return true end
    S.say("rod in hand " .. tostring(S.p:getPrimaryHandItem() == S.rod) .. ", manager " .. S.state())
    pcall(function() ISInventoryPaneContextMenu.addLure(S.pn, S.rod, S.worm) end)
    S.t = 0
end)
S.step(10, function()
    if not S.rod then return end
    S.t = S.t + 1
    if not (S.queueEmpty() and S.rod:getModData().fishing_Lure ~= nil) and S.t < 200 then return true end
    S.say("bait " .. tostring(S.rod:getModData().fishing_Lure))
    pcall(function() S.p:setDir(IsoDirections[S.shore.dir]) end)
    S.pairOpen()
end)
-- the aim: the game's own aim point stood in for (Fishing.Utils.getAimCoords answers the water square ahead for this
-- character, as the game's controller aim answers a square along the facing; the pointer is not used: Mouse.setXY did
-- not hold in the first run and the aim stayed on the bank). It stays in place until the put back, so the cast and
-- the line read the same point. The aim itself (the right button) is held every frame while None or Idle.
S.step(30, function()
    if not S.rod then return end
    S.aimWas = Fishing.Utils.getAimCoords
    Fishing.Utils.getAimCoords = function(pl, len)
        if pl == S.p and S.shore then return S.shore.tx, S.shore.ty end
        return S.aimWas(pl, len)
    end
    S.aiming = true
    S.every = function()
        if not S.aiming then return end
        local st = S.state()
        if st == "None" or st == "Idle" or st == "nomanager" then S.p:setIsAiming(true) end
    end
    S.tries = 0
end)
S.step(20, function()   -- (up to about 4 s for the game's None -> Idle: aiming, on water)
    if not S.rod then return end
    S.tries = S.tries + 1
    local f = S.shore
    local ax, ay = Fishing.Utils.getAimCoords(S.p)
    local on = Fishing.Utils.isPlayerAimOnWater(S.p)
    local cs = "?"
    pcall(function() cs = tostring(S.p:getCurrentState() and S.p:getCurrentState():getClass():getSimpleName()) end)
    if S.tries == 1 or S.tries % 3 == 0 or S.state() == "Idle" then
        S.say(string.format("aim %d: %.1f,%.1f (target %.1f,%.1f), on water %s, aiming %s, state %s, player state %s",
            S.tries, ax, ay, f.tx, f.ty, tostring(on), tostring(S.p:isAiming()), S.state(), cs))
    end
    if S.state() == "Idle" or S.tries >= 12 then return end
    return true
end)
-- the cast: the game's cast button stood in for once
S.step(10, function()
    if not S.rod then return end
    if S.state() ~= "Idle" then S.say("ERR the manager is not Idle (" .. S.state() .. "): the cast may not go") end
    S.castWas = Fishing.Utils.isCastButtonPressed
    Fishing.Utils.isCastButtonPressed = function(j)
        Fishing.Utils.isCastButtonPressed = S.castWas
        return true
    end
    S.t = 0
end)
S.step(10, function()
    if not S.rod then return end
    S.t = S.t + 1
    local st = S.state()
    if st ~= "Wait" and S.t < 120 then return true end
    if Fishing.Utils.isCastButtonPressed ~= S.castWas then Fishing.Utils.isCastButtonPressed = S.castWas end
    S.say("after the cast: state " .. st .. " (" .. S.t .. " polls)")
    S.cast = (st == "Wait" or st == "ReelIn" or st == "ReelOut")
    if not S.cast then S.L.notTaken(S, "g1_59_fishing", "the line did not go out (state " .. st .. ")") end
end)
S.step(150, function()   -- (the line settles; the tab comes up by itself on the cast)
    if not S.cast then return end
    local showing = S.WW.isTabShowing("fishing", S.pn)
    if not showing then pcall(S.WW.openTab, S.pn, "fishing") end
    S.say("the Fishing tab came up by itself " .. tostring(showing) .. "; state " .. S.state())
end)
S.step(40, function() if S.cast then S.L.shot(S, "g1_59_fishing") end end)

-- ===================================================================== put back
S.step(10, function()
    S.aiming = false
    S.every = nil
    if S.castWas then Fishing.Utils.isCastButtonPressed = S.castWas end
    if S.aimWas then Fishing.Utils.getAimCoords = S.aimWas; S.aimWas = nil end
    pcall(function() S.FT.stopFishing(S.p) end)
    pcall(function() local m = S.mgr(); if m then m:changeState("None") end end)
    pcall(function() S.p:setIsAiming(false) end)
    pcall(function() ISTimedActionQueue.clear(S.p) end)
    if GAL_UNLOAD and GAL_UNLOAD.park then GAL_UNLOAD.park() end
end)
S.step(60, function()
    pcall(function() S.p:setPrimaryHandItem(S.h1); S.p:setSecondaryHandItem(S.h2) end)
    S.L.takeBack(S)
    local gone = 0
    pcall(function()
        local items = S.inv:getItems()
        for k = items:size() - 1, 0, -1 do
            local it = items:get(k)
            if not S.ids[it:getID()] then S.inv:Remove(it); gone = gone + 1 end
        end
    end)
    pcall(S.WW.openTab, S.pn, "loot")
    S.L.moveTo(S, S.home.x, S.home.y, S.home.z)
    S.L.putCheats(S)
    S.L.summary(S)
    S.say("put back: the line in, aiming off, the hands, rod and worms out (" .. gone .. " other new things out), the place")
    S.L.done(S)
end)
S.L.run(S)
