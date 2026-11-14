-- ZeDUI/tools/qa/zedqa_farm_spot.lua  (Nov 13 2026, QA): the animals checks' farm field (the director's pick, 1625,14221; was 1568,14337).
-- Run after the prelude (which puts the character on the drag strip) and before zedqa_animals_restore / aq / aq2. The animal
-- scripts build their zone, 17 x 17 squares, round wherever the character stands, so this stands the character where that
-- zone is all open ground. It moves to the director's point, lets the cells load, then searches the squares within 24 of it
-- for the nearest centre whose 17 x 17 has nothing in the way: every square loaded, outdoors, free, no tree, and no wall,
-- fence, door, window or building piece on it (the director, Nov 13: the first zone ran through the barn and the character
-- walked round it to reach a cow). The character moves there and one picture is taken, zqa_farm_spot.png, for the director
-- to see before the animals run. No open centre found: the character stays on the point and an ERR line says so.
-- grep "ZEDQA farm".
local TAG = "farm"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local FARM = { x = 1635.5, y = 14221.5, z = 0 }   -- (the director: 10 squares further from the barn than their pick, 1625,14221)
local HALF, SEARCH = 8, 24
ZEDQA_FARM = FARM
local p = getPlayer()
if not p then say("ERR no player"); say("DONE"); return end
local function standAt(x, y)
    pcall(function() local car = p:getVehicle(); if car then car:exit(p); triggerEvent("OnExitVehicle", p) end end)
    p:setX(x); p:setY(y); p:setZ(0); p:setLastX(x); p:setLastY(y); p:setLastZ(0)
end
standAt(FARM.x, FARM.y)
pcall(function() local gt = getGameTime(); local h = gt:getTimeOfDay(); if h < 8 or h > 17 then gt:setTimeOfDay(11.0) end end)
say("moved to " .. FARM.x .. "," .. FARM.y)

local BLOCK = { "wall", "fenc", "door", "window", "gate", "roof", "location_", "fixtures_", "furniture_", "appliances_" }
-- one square: nil when open ground, else why not
local function blocked(cell, x, y)
    local s = cell:getGridSquare(x, y, 0)
    if not s then return "not loaded" end
    if s:getRoom() then return "indoors" end
    if s:HasTree() then return "a tree" end
    local free = true
    pcall(function() free = s:isFree(false) end)
    if not free then return "not free" end
    local why = nil
    pcall(function()
        local objs = s:getObjects()
        for i = 0, objs:size() - 1 do
            local o = objs:get(i)
            local nm = string.lower(tostring(o:getSprite() and o:getSprite():getName() or ""))
            for _, w in ipairs(BLOCK) do if nm:find(w, 1, true) then why = nm; break end end
            if why then break end
        end
    end)
    return why
end
-- (Build, Nov 13: where two animal zones cover one square the game counts the animal in the first it finds, the farm's,
-- so the test's zone must not touch a zone already there, its edge included: one square of margin round the zone)
local function farmZoneAt(x, y)
    local z = nil
    pcall(function() z = DesignationZoneAnimal and DesignationZoneAnimal.getZone(x, y, 0) end)
    return z
end
local function zoneOpen(cell, cx, cy)
    for dx = -HALF - 1, HALF + 1 do
        for dy = -HALF - 1, HALF + 1 do
            local z = farmZoneAt(cx + dx, cy + dy)
            if z then
                local nm = "?"
                pcall(function() nm = tostring(z:getName()) end)
                return false, "the animal zone '" .. nm .. "' at " .. (cx + dx) .. "," .. (cy + dy)
            end
            if math.abs(dx) <= HALF and math.abs(dy) <= HALF then
                local why = blocked(cell, cx + dx, cy + dy)
                if why then return false, why .. " at " .. (cx + dx) .. "," .. (cy + dy) end
            end
        end
    end
    return true
end

local frames = 0
local function look()
    frames = frames + 1
    if frames < 300 then return end
    Events.OnRenderTick.Remove(look)
    local cell = getCell()
    local fx, fy = math.floor(FARM.x), math.floor(FARM.y)
    local ok0, why0 = zoneOpen(cell, fx, fy)
    say("the director's point: zone open " .. tostring(ok0) .. (ok0 and "" or (" (" .. why0 .. ")")))
    local best, bestD = nil, nil
    for r = 0, SEARCH do
        for dx = -r, r do
            for dy = -r, r do
                if math.max(math.abs(dx), math.abs(dy)) == r then
                    local cx, cy = fx + dx, fy + dy
                    local d = dx * dx + dy * dy
                    if (not bestD or d < bestD) and zoneOpen(cell, cx, cy) then best, bestD = { cx, cy }, d end
                end
            end
        end
        if best then break end
    end
    if best then
        standAt(best[1] + 0.5, best[2] + 0.5)
        FARM.zone = { best[1] - HALF, best[2] - HALF, best[1] + HALF, best[2] + HALF }
        say(string.format("open zone centre %d,%d (%.0f squares from the point); the zone %d,%d to %d,%d",
            best[1], best[2], math.sqrt(bestD), best[1] - HALF, best[2] - HALF, best[1] + HALF, best[2] + HALF))
    else
        say("ERR no centre within " .. SEARCH .. " squares has an open 17 x 17: the character stays on the point")
    end
    local frames2 = 0
    local function snap()
        frames2 = frames2 + 1
        if frames2 < 120 then return end
        Events.OnRenderTick.Remove(snap)
        pcall(function() getCore():TakeFullScreenshot("zqa_farm_spot.png") end)
        say("DONE")
    end
    Events.OnRenderTick.Add(snap)
end
Events.OnRenderTick.Add(look)
