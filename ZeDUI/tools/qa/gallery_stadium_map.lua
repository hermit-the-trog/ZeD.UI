-- ZeDUI/tools/qa/gallery_stadium_map.lua  (Nov 4 2026, QA; the cinema breaks): a coarse map of the blocks around the
-- stadium's changing rooms (12954,1543), one character per 4x4 squares: # a room, + a building without a room
-- (stands, roofs), " natural ground (grass, dirt), = street or pavement, . other floor, space nothing loaded.
-- Prints rows "ZEDQA stm <y> <row>". grep "ZEDQA stm".
local function say(s) print("ZEDQA stm " .. tostring(s)) end
local p = getPlayer()
pcall(function() p:setGodMod(true); p:setInvisible(true) end)
local X0, X1, Y0, Y1, ST = 12780, 13140, 1400, 1760, 4
local grid = {}
local stops = {}
for x = X0 + 60, X1, 120 do for y = Y0 + 60, Y1, 120 do stops[#stops + 1] = { x, y } end end
local function mark(cx, cy)
    local cell = getCell()
    for gx = X0, X1, ST do for gy = Y0, Y1, ST do
        if math.abs(gx - cx) <= 70 and math.abs(gy - cy) <= 70 then
            local sq = cell:getGridSquare(gx, gy, 0)
            local ch = nil
            if sq then
                local fl = sq:getFloor()
                local nm = string.lower(tostring(fl and fl:getSprite() and fl:getSprite():getName() or ""))
                if sq:getRoom() then ch = "#"
                elseif sq:getBuilding() then ch = "+"
                elseif nm:find("natural", 1, true) or nm:find("grass", 1, true) or nm:find("dirt", 1, true) then ch = '"'
                elseif nm:find("street", 1, true) or nm:find("pave", 1, true) or nm:find("sidewalk", 1, true) then ch = "="
                elseif fl then ch = "." end
            end
            if ch then grid[gx .. "," .. gy] = ch end
        end
    end end
end
local i, wait = 0, 0
local function tick()
    if wait > 0 then wait = wait - 1; return end
    if i > 0 then mark(stops[i][1], stops[i][2]) end
    i = i + 1
    if not stops[i] then
        Events.OnTick.Remove(tick)
        for gy = Y0, Y1, ST do
            local row = {}
            for gx = X0, X1, ST do row[#row + 1] = grid[gx .. "," .. gy] or " " end
            say(gy .. " " .. table.concat(row))
        end
        say("DONE")
        return
    end
    p:setX(stops[i][1] + 0.5); p:setY(stops[i][2] + 0.5); p:setZ(0); p:setLastX(stops[i][1] + 0.5); p:setLastY(stops[i][2] + 0.5); p:setLastZ(0)
    wait = 120
end
Events.OnTick.Add(tick)
say("start x " .. X0 .. "-" .. X1 .. " step " .. ST)
