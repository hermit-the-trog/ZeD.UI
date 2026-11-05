-- ZeDUI/tools/qa/gallery_tower_probe.lua  (Nov 4 2026, QA; the cinema scenes): where are Louisville's tallest
-- buildings? Teleports through downtown Louisville in a grid, lets the cells load, and for each stop scans the squares
-- around for the highest floor (a square with a floor at z). Prints the best spots. grep "ZEDQA twp".
-- God mode keeps the character safe (the shot saves have no zombies anyway).
local function say(s) print("ZEDQA twp " .. tostring(s)) end
local p = getPlayer()
local home = { p:getX(), p:getY(), p:getZ() }
local stops = {}
for x = 12300, 13900, 200 do for y = 1100, 3100, 200 do stops[#stops + 1] = { x, y } end end
local best = {}
local i, wait = 0, 0
local function scan(cx, cy)
    local cell = getCell()
    local top = { z = -1 }
    for dx = -60, 60, 3 do for dy = -60, 60, 3 do
        local x, y = cx + dx, cy + dy
        for z = 31, 3, -1 do
            local sq = cell:getGridSquare(x, y, z)
            if sq and sq:getFloor() then
                if z > top.z then top = { z = z, x = x, y = y } end
                break
            end
        end
    end end
    return top
end
local function tick()
    if wait > 0 then wait = wait - 1; return end
    if i > 0 then
        local s = stops[i]
        local t = scan(s[1], s[2])
        if t.z >= 6 then best[#best + 1] = t; say(string.format("stop %d,%d: top floor z %d at %d,%d", s[1], s[2], t.z, t.x, t.y)) end
    end
    i = i + 1
    local s = stops[i]
    if not s then
        Events.OnTick.Remove(tick)
        table.sort(best, function(a, b) return a.z > b.z end)
        for k = 1, math.min(8, #best) do local b = best[k]; say(string.format("BEST %d: z %d at %d,%d", k, b.z, b.x, b.y)) end
        p:setX(home[1]); p:setY(home[2]); p:setZ(home[3]); p:setLastX(home[1]); p:setLastY(home[2]); p:setLastZ(home[3])
        say("DONE")
        return
    end
    p:setX(s[1] + 0.5); p:setY(s[2] + 0.5); p:setZ(0); p:setLastX(s[1] + 0.5); p:setLastY(s[2] + 0.5); p:setLastZ(0)
    wait = 90
end
pcall(function() p:setGodMod(true) end)
Events.OnTick.Add(tick)
say("start: " .. #stops .. " stops")
