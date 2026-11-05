-- ZeDUI/tools/qa/gallery_stadium_probe.lua  (Nov 4 2026, QA; the cinema breaks): where is Louisville's baseball field?
-- Visits map cell 50_5 (x 12800-13055, y 1280-1535) in a 3x3 grid, lists the room names it finds (both the room's own
-- name and its definition's) with their middle squares, and the biggest open area. grep "ZEDQA stp".
local function say(s) print("ZEDQA stp " .. tostring(s)) end
local p = getPlayer()
pcall(function() p:setGodMod(true); p:setInvisible(true) end)
local stops = {}
for x = 12830, 13030, 100 do for y = 1310, 1510, 100 do stops[#stops + 1] = { x, y } end end
local rooms = {}
local i, wait = 0, 0
local function scan(cx, cy)
    local cell = getCell()
    for dx = -60, 60, 2 do for dy = -60, 60, 2 do
        local sq = cell:getGridSquare(cx + dx, cy + dy, 0)
        local room = sq and sq:getRoom()
        if room then
            local n1 = tostring(room:getName())
            local n2 = "?"
            pcall(function() n2 = tostring(room:getRoomDef():getName()) end)
            local k = n1 .. "/" .. n2
            local r = rooms[k] or { n = 0, x = 0, y = 0 }
            r.n, r.x, r.y = r.n + 1, r.x + cx + dx, r.y + cy + dy
            rooms[k] = r
        end
    end end
end
local function tick()
    if wait > 0 then wait = wait - 1; return end
    if i > 0 then scan(stops[i][1], stops[i][2]) end
    i = i + 1
    if not stops[i] then
        Events.OnTick.Remove(tick)
        for k, r in pairs(rooms) do
            if k:lower():find("base") or k:lower():find("stad") or k:lower():find("ball") or r.n > 400 then
                say(string.format("room %s: %d squares, middle %d,%d", k, r.n, math.floor(r.x / r.n), math.floor(r.y / r.n)))
            end
        end
        local all = 0; for _ in pairs(rooms) do all = all + 1 end
        say("rooms seen: " .. all)
        say("DONE")
        return
    end
    p:setX(stops[i][1] + 0.5); p:setY(stops[i][2] + 0.5); p:setZ(0); p:setLastX(stops[i][1] + 0.5); p:setLastY(stops[i][2] + 0.5); p:setLastZ(0)
    wait = 120
end
Events.OnTick.Add(tick)
say("start")
