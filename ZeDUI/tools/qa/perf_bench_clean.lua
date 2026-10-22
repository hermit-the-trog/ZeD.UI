-- ZeDUI/tools/qa/perf_bench_clean.lua  (Oct 22 2026)
-- Clears what an earlier perf run left standing on the Valley Station lot (its teardown
-- did not run): every zombie in the cell, every car within 60 squares of GAL.spot, every
-- world item within 20 squares, and the character's worn kit and carried items. Run it
-- after gallery_v3_core.lua (needs GAL) and before gallery_v3_stage.lua, so the stage
-- starts from the same empty lot a first run does. "ZEDQA pbc ..." ending "ZEDQA pbc DONE".
local G = GAL
if not (G and G.spot and G.newSeq) then print("ZEDQA pbc ERR run gallery_v3_core.lua first"); print("ZEDQA pbc DONE"); return end
local S = G.newSeq("pbc", 240000)
local say = S.say
local p, inv, pn = G.p, G.inv, G.pn
local function rmZ(z)
    pcall(function() z:removeFromWorld() end)
    pcall(function() z:removeFromSquare() end)
end
local N = { z = 0, c = 0, w = 0, row = -20 }
S.step(2, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    pcall(function() ISTimedActionQueue.clear(p) end)
    local v = p:getVehicle()
    if v then pcall(function() v:exit(p) end); pcall(function() triggerEvent("OnExitVehicle", p) end) end
    G.tp(G.spot.px + 0.5, G.spot.py + 0.5, 0)
end)
S.step(20, function()
    local zs = {}
    local zl = getCell():getZombieList()
    for i = 0, zl:size() - 1 do zs[#zs + 1] = zl:get(i) end
    for _, z in ipairs(zs) do rmZ(z); N.z = N.z + 1 end
    local vs = {}
    local it = getCell():getVehicles():iterator()
    while it:hasNext() do
        local v = it:next()
        if math.abs(v:getX() - G.spot.px) <= 60 and math.abs(v:getY() - G.spot.py) <= 60 then vs[#vs + 1] = v end
    end
    for _, v in ipairs(vs) do if pcall(function() v:permanentlyRemove() end) then N.c = N.c + 1 end end
end)
-- world items: a row of squares a frame
S.poll(2, 2000, function()
    local y = G.spot.py + N.row
    for x = G.spot.px - 20, G.spot.px + 20 do
        local sq = G.sqAt(x, y)
        if sq then
            local list = {}
            pcall(function()
                local wo = sq:getWorldObjects()
                for i = 0, wo:size() - 1 do list[#list + 1] = wo:get(i) end
            end)
            for _, wi in ipairs(list) do
                if pcall(function() sq:transmitRemoveItemFromSquare(wi); wi:removeFromWorld(); wi:removeFromSquare() end) then N.w = N.w + 1 end
            end
        end
    end
    N.row = N.row + 1
    return N.row > 20
end)
S.step(10, function()
    pcall(function() p:setPrimaryHandItem(nil); p:setSecondaryHandItem(nil) end)
    local hb = getPlayerHotbar and getPlayerHotbar(pn)
    if hb then
        local now = {}
        for _, it in pairs(hb.attachedItems or {}) do now[#now + 1] = it end
        for _, it in ipairs(now) do pcall(function() hb:removeItem(it, false) end) end
    end
    local worn = {}
    pcall(function()
        local wi = p:getWornItems()
        for i = 0, wi:size() - 1 do worn[#worn + 1] = wi:get(i):getItem() end
    end)
    for _, it in ipairs(worn) do pcall(function() p:removeWornItem(it, false) end) end
    local items = {}
    local list = inv:getItems()
    for i = 0, list:size() - 1 do items[#items + 1] = list:get(i) end
    for _, it in ipairs(items) do pcall(function() inv:Remove(it) end) end
    pcall(function() triggerEvent("OnClothingUpdated", p) end)
    say(string.format("removed %d zombies, %d cars, %d ground things; kit off: %d worn, %d items | zombies left %d", N.z, N.c, N.w, #worn, #items, getCell():getZombieList():size()))
end)
S.start()
