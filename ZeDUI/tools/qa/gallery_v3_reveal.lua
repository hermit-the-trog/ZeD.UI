-- ZeDUI/tools/qa/gallery_v3_reveal.lua  (Oct 21 2026)
-- Workshop gallery v3, after gallery_v3_core.lua: a tour round GAL.spot so the squares
-- around have been seen (unseen squares draw black): stops 12 and 26 squares out in
-- eight directions, a full turn at each, then back on the spot facing the camera.
-- With GAL_SCOUT = true it then shuts the ZeD windows (if any) and takes two scout
-- pictures (g3_scout2_wide / g3_scout2_mid). "ZEDQA g3r ... DONE".
local G = GAL
if not (G and G.spot and G.newSeq) then print("ZEDQA g3r ERR no GAL spot"); print("ZEDQA g3r DONE"); return end
local S = G.newSeq("g3r", 300000)
local p = G.p
local DIRS = { "N", "NE", "E", "SE", "S", "SW", "W", "NW" }
local function nearOut(x, y)
    for r = 0, 6 do
        for dy = -r, r do
            for dx = -r, r do
                if math.max(math.abs(dx), math.abs(dy)) == r then
                    local q = G.sqAt(x + dx, y + dy)
                    if q and q:isOutside() and q:isFree(false) and not q:getVehicleContainer() then return x + dx, y + dy end
                end
            end
        end
    end
    return nil
end
local stops = {}
for _, d in ipairs({ 12, 26 }) do
    for _, o in ipairs({ { 0, -1 }, { 1, -1 }, { 1, 0 }, { 1, 1 }, { 0, 1 }, { -1, 1 }, { -1, 0 }, { -1, -1 } }) do
        stops[#stops + 1] = { o[1] * d, o[2] * d }
    end
end
S.step(2, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    G.cleanLook()
    G.day()
end)
for _, o in ipairs(stops) do
    S.step(2, function()
        local x, y = nearOut(G.spot.px + o[1], G.spot.py + o[2])
        if x then G.tp(x + 0.5, y + 0.5, 0) end
    end)
    for _, d in ipairs(DIRS) do
        S.step(4, function() pcall(function() p:setDir(IsoDirections[d]) end) end)
    end
    S.step(6, function() end)
end
S.step(2, function() G.tp(G.spot.px + 0.5, G.spot.py + 0.5, 0) end)
for _, d in ipairs(DIRS) do
    S.step(8, function() pcall(function() p:setDir(IsoDirections[d]) end) end)
end
S.step(20, function() G.faceFront(); S.say("toured: " .. #stops .. " stops") end)
if GAL_SCOUT then
    S.step(2, function()
        if ZeD_CharacterWindow and ZeD_CharacterWindow.isOpen() and ZeD_WorldWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end
    end)
    S.zoomTo(1.75)
    S.step(30, function() G.faceFront(); S.shot("g3_scout2_wide") end)
    S.zoomTo(1.0)
    S.step(30, function() S.shot("g3_scout2_mid") end)
end
S.start()
