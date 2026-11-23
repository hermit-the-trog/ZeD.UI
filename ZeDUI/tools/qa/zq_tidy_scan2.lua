-- ZeDUI/tools/qa/zq_tidy_scan2.lua  (Nov 23 2026, QA; tag zq_scan2): the brown dug patches that stayed after zq_tidy.
-- Changes nothing. For each square within 30 of the character: the floor sprite, the floor's attached sprites and
-- overlay, and every object's sprite, as one key; the rare keys (under 80 squares) are logged with a few positions.
local Q = RT.make("zq_scan2")
local S = { p = getPlayer(), R = 30 }
Q.step(2, function()
    local cell = getCell()
    local px, py, pz = math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())
    local keys, at = {}, {}
    for x = px - S.R, px + S.R do
        for y = py - S.R, py + S.R do
            local sq = cell:getGridSquare(x, y, pz)
            if sq then
                local parts = {}
                local fl = sq:getFloor()
                if fl then
                    parts[#parts + 1] = "F:" .. tostring(fl:getSprite() and fl:getSprite():getName())
                    pcall(function()
                        local a = fl:getAttachedAnimSprite()
                        for i = 0, (a and a:size() or 0) - 1 do
                            local s = a:get(i)
                            local nm = "?"
                            pcall(function() nm = s:getParentSprite():getName() end)
                            parts[#parts + 1] = "A:" .. tostring(nm)
                        end
                    end)
                    pcall(function() local ov = fl:getOverlaySprite(); if ov then parts[#parts + 1] = "O:" .. tostring(ov:getName()) end end)
                end
                local os = sq:getObjects()
                for i = 0, os:size() - 1 do
                    local o = os:get(i)
                    if o ~= fl then parts[#parts + 1] = "o:" .. tostring(o:getSprite() and o:getSprite():getName()) .. "/" .. tostring(o:getObjectName()) end
                end
                local k = table.concat(parts, " ")
                keys[k] = (keys[k] or 0) + 1
                at[k] = at[k] or {}
                if #at[k] < 4 then at[k][#at[k] + 1] = x .. "," .. y end
            end
        end
    end
    local list = {}
    for k, v in pairs(keys) do if v < 80 then list[#list + 1] = { k = k, v = v } end end
    table.sort(list, function(a, b) return a.v > b.v end)
    for i = 1, math.min(60, #list) do
        Q.say("NOTE " .. list[i].v .. "x " .. list[i].k .. " @ " .. table.concat(at[list[i].k], " "))
    end
    Q.check(true, "the rare squares were logged", #list .. " rare keys")
end)
Q.start()
