-- ZeDUI/tools/qa/zedqa_farm_spot.lua  (Nov 13 2026, QA): the animals checks' farm field (the director's pick, 1568,14337).
-- Run after the prelude (which puts the character on the drag strip) and before zedqa_animals_restore / aq / aq2: it moves
-- the character to the field, waits for the cells to load, and reports the ground round it (indoors or not, the floor,
-- fences and walls within 8 squares, which the animal zone of 17 x 17 squares round the character would hold), then one
-- picture, zqa_farm_spot.png. The animal scripts build their zone round wherever the character stands.
-- grep "ZEDQA farm".
local TAG = "farm"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local FARM = { x = 1568.5, y = 14337.5, z = 0 }
ZEDQA_FARM = FARM
local p = getPlayer()
if not p then say("ERR no player"); say("DONE"); return end
pcall(function() local car = p:getVehicle(); if car then car:exit(p); triggerEvent("OnExitVehicle", p) end end)
p:setX(FARM.x); p:setY(FARM.y); p:setZ(FARM.z); p:setLastX(FARM.x); p:setLastY(FARM.y); p:setLastZ(FARM.z)
pcall(function() local gt = getGameTime(); local h = gt:getTimeOfDay(); if h < 8 or h > 17 then gt:setTimeOfDay(11.0) end end)
say("moved to " .. FARM.x .. "," .. FARM.y)
local frames = 0
local function look()
    frames = frames + 1
    if frames < 300 then return end
    Events.OnRenderTick.Remove(look)
    local cell = getCell()
    local cx, cy = math.floor(FARM.x), math.floor(FARM.y)
    local sq = cell:getGridSquare(cx, cy, 0)
    local floor = "?"
    pcall(function() floor = tostring(sq:getFloor():getSprite():getName()) end)
    say("here: loaded " .. tostring(sq ~= nil) .. ", indoors " .. tostring(sq and sq:getRoom() ~= nil) .. ", floor " .. floor)
    local fences, walls, indoor, missing, trees = 0, 0, 0, 0, 0
    for dx = -8, 8 do
        for dy = -8, 8 do
            local s = cell:getGridSquare(cx + dx, cy + dy, 0)
            if not s then missing = missing + 1
            else
                if s:getRoom() then indoor = indoor + 1 end
                if s:HasTree() then trees = trees + 1 end
                pcall(function()
                    local objs = s:getObjects()
                    for i = 0, objs:size() - 1 do
                        local nm = string.lower(tostring(objs:get(i):getSprite() and objs:get(i):getSprite():getName() or ""))
                        if nm:find("fencing", 1, true) or nm:find("fence", 1, true) then fences = fences + 1
                        elseif nm:find("walls_", 1, true) then walls = walls + 1 end
                    end
                end)
            end
        end
    end
    say("the zone's 17 x 17 squares: not loaded " .. missing .. ", indoors " .. indoor .. ", fence pieces " .. fences .. ", wall pieces " .. walls .. ", trees " .. trees)
    pcall(function() getCore():TakeFullScreenshot("zqa_farm_spot.png") end)
    say("DONE")
end
Events.OnRenderTick.Add(look)
