-- ZeDUI/tools/qa/zq_tidy_scan.lua  (Nov 23 2026, QA; tag zq_scan): reads the QA character's surroundings before a
-- tidy (the director: "move Angel or clean up his area ... all those dead sheep and torn up grass"). Changes
-- nothing. Within 30 squares of the character, on his floor: the corpses (animal or zombie, with their type), the
-- live animals, the squares with blood, every object sprite name and every floor sprite name, counted, and the
-- items lying on the ground. Logged as NOTE lines; the tidy script is written from them.
local Q = RT.make("zq_scan")
local S = { p = getPlayer(), R = 30 }

function S.bump(t, k) k = tostring(k); t[k] = (t[k] or 0) + 1 end
function S.top(t, n)
    local list = {}
    for k, v in pairs(t) do list[#list + 1] = { k = k, v = v } end
    table.sort(list, function(a, b) return a.v > b.v end)
    local out = {}
    for i = 1, math.min(n, #list) do out[#out + 1] = list[i].k .. " x" .. list[i].v end
    return table.concat(out, "; ")
end

Q.step(2, function()
    local cell = getCell()
    local px, py, pz = math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())
    local corpses, animals, objs, floors, items = {}, {}, {}, {}, {}
    local blood, nSq, corpseAt = 0, 0, {}
    for x = px - S.R, px + S.R do
        for y = py - S.R, py + S.R do
            local sq = cell:getGridSquare(x, y, pz)
            if sq then
                nSq = nSq + 1
                local fl = sq:getFloor()
                if fl and fl:getSprite() then S.bump(floors, fl:getSprite():getName()) end
                local bodies = sq:getDeadBodys()
                for i = 0, (bodies and bodies:size() or 0) - 1 do
                    local b = bodies:get(i)
                    local kind = "zombie"
                    pcall(function() if b:isAnimal() then kind = "animal" end end)
                    pcall(function() if kind == "animal" then kind = "animal " .. tostring(b:getAnimalType()) end end)
                    S.bump(corpses, kind)
                    if #corpseAt < 12 then corpseAt[#corpseAt + 1] = kind .. "@" .. x .. "," .. y end
                end
                local os = sq:getObjects()
                for i = 0, os:size() - 1 do
                    local o = os:get(i)
                    if o ~= fl then
                        local nm = (o:getSprite() and o:getSprite():getName()) or ("[" .. tostring(o:getObjectName()) .. "]")
                        S.bump(objs, nm)
                    end
                end
                local mo = sq:getMovingObjects()
                for i = 0, (mo and mo:size() or 0) - 1 do
                    local m = mo:get(i)
                    if instanceof(m, "IsoAnimal") then
                        local t = "?"
                        pcall(function() t = m:getAnimalType() end)
                        S.bump(animals, t)
                    end
                end
                local wo = sq:getWorldObjects()
                for i = 0, (wo and wo:size() or 0) - 1 do
                    local it = wo:get(i):getItem()
                    if it then S.bump(items, it:getFullType()) end
                end
                local hasBlood = false
                pcall(function() hasBlood = sq:haveBlood() end)
                if hasBlood then blood = blood + 1 end
            end
        end
    end
    Q.say("NOTE where: the character at " .. px .. "," .. py .. "," .. pz .. "; " .. nSq .. " squares read (radius " .. S.R .. ")")
    Q.say("NOTE corpses: " .. S.top(corpses, 20))
    Q.say("NOTE corpses at: " .. table.concat(corpseAt, " "))
    Q.say("NOTE live animals: " .. S.top(animals, 20))
    Q.say("NOTE squares with blood: " .. blood)
    Q.say("NOTE floors: " .. S.top(floors, 30))
    Q.say("NOTE objects: " .. S.top(objs, 60))
    Q.say("NOTE items on the ground: " .. S.top(items, 40))
    Q.check(nSq > 0, "the area round the character was read", nSq .. " squares")
end)
Q.start()
