-- ZeDUI/tools/qa/zq_tidy.lua  (Nov 23 2026, QA; tag zq_tidy): tidies the QA character's home at the drag strip
-- (925,13040). The director: "either move Angel or clean up his area? It's really depressing seeing all those dead
-- sheep and torn up grass everywhere." Angel stays (the vehicle tests and the gallery's staging are built there).
-- zq_tidy_scan found, within 30 squares: 11 animal corpses (rams, ewes, a lamb, hens: left by the animal tests run
-- here before they moved to the farm on Nov 13), blood on 131 squares, 16 dead or trampled crop plots
-- (vegetation_farming_*), and junk on the ground (eggs, raw wool, dung, smashed bottles, broken glass, splinters,
-- empty cans). This removes those, within 30 squares on his floor, and leaves alone every item within 3 squares of
-- him (the ground list the tests and the gallery use), every other item, the furniture, fences and plants.
-- Pictures zq_tidy_before / zq_tidy_after with the windows shut (put back as found after).
-- Checks: no animal corpse, no bloody square, no dead or trampled plot and none of the junk left in the area.
local Q = RT.make("zq_tidy")
local S = { p = getPlayer(), R = 30, KEEP = 3 }
S.JUNK = { ["Base.Egg"] = true, ["Base.WoolRaw"] = true, ["Base.Dung_Cow"] = true, ["Base.Dung_Sheep"] = true,
           ["Base.SmashedBottle"] = true, ["Base.BrokenGlass"] = true, ["Base.Splinters"] = true,
           ["Base.TinCanEmpty"] = true }

function S.each(fn)
    local cell = getCell()
    local px, py, pz = math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())
    for x = px - S.R, px + S.R do
        for y = py - S.R, py + S.R do
            local sq = cell:getGridSquare(x, y, pz)
            if sq then fn(sq, math.max(math.abs(x - px), math.abs(y - py))) end
        end
    end
end
function S.isAnimalBody(b) local a = false; pcall(function() a = b:isAnimal() end); return a end
function S.isPlot(o)
    local nm = o and o:getSprite() and o:getSprite():getName() or ""
    return nm:find("vegetation_farming_trampled", 1, true) ~= nil or nm:find("vegetation_farming_dead", 1, true) ~= nil
end
function S.count()
    local c = { bodies = 0, blood = 0, plots = 0, junk = 0 }
    S.each(function(sq, d)
        local bs = sq:getDeadBodys()
        for i = 0, (bs and bs:size() or 0) - 1 do if S.isAnimalBody(bs:get(i)) then c.bodies = c.bodies + 1 end end
        local hb = false
        pcall(function() hb = sq:haveBlood() end)
        if hb then c.blood = c.blood + 1 end
        local os = sq:getObjects()
        for i = 0, os:size() - 1 do if S.isPlot(os:get(i)) then c.plots = c.plots + 1 end end
        if d > S.KEEP then
            local wo = sq:getWorldObjects()
            for i = 0, (wo and wo:size() or 0) - 1 do
                local it = wo:get(i):getItem()
                if it and S.JUNK[it:getFullType()] then c.junk = c.junk + 1 end
            end
        end
    end)
    return c
end
function S.text(c) return c.bodies .. " animal corpses, " .. c.blood .. " bloody squares, " .. c.plots .. " dead or trampled plots, " .. c.junk .. " junk items" end
function S.shot(name, what)
    Q.step(4, function()
        local file = name .. ".png"
        local ok, e = pcall(function() getCore():TakeFullScreenshot(file) end)
        if ok then Q.say("NOTE picture Zomboid/Screenshots/" .. file .. " | " .. what)
        else Q.say("NOTE the picture " .. name .. " was not taken: " .. tostring(e)) end
    end)
    Q.waitMs(1500)
end

Q.step(2, function()
    S.pair = RT.isOpen and RT.isOpen() or false
    if RT.pairShut then RT.pairShut() end
    S.c0 = S.count()
    Q.say("NOTE before: " .. S.text(S.c0))
end)
Q.waitMs(1500)
S.shot("zq_tidy_before", "the drag strip round Angel before the tidy")
Q.step(1, function()
    local removed = { bodies = 0, blood = 0, plots = 0, junk = 0 }
    S.each(function(sq, d)
        local bs = sq:getDeadBodys()
        for i = (bs and bs:size() or 0) - 1, 0, -1 do
            local b = bs:get(i)
            if S.isAnimalBody(b) then
                local ok = pcall(function() sq:removeCorpse(b, false) end)
                if not ok then pcall(function() b:removeFromWorld(); b:removeFromSquare() end) end
                removed.bodies = removed.bodies + 1
            end
        end
        local hb = false
        pcall(function() hb = sq:haveBlood() end)
        if hb then pcall(function() sq:removeBlood(false, false) end); removed.blood = removed.blood + 1 end
        local os = sq:getObjects()
        for i = os:size() - 1, 0, -1 do
            local o = os:get(i)
            if S.isPlot(o) then
                pcall(function() sq:transmitRemoveItemFromSquare(o) end)
                pcall(function() if o:getSquare() then sq:RemoveTileObject(o) end end)
                removed.plots = removed.plots + 1
            end
        end
        if d > S.KEEP then
            local wo = sq:getWorldObjects()
            for i = (wo and wo:size() or 0) - 1, 0, -1 do
                local w = wo:get(i)
                local it = w:getItem()
                if it and S.JUNK[it:getFullType()] then
                    pcall(function() sq:transmitRemoveItemFromSquare(w) end)
                    pcall(function() if w:getSquare() then w:removeFromWorld(); w:removeFromSquare() end end)
                    removed.junk = removed.junk + 1
                end
            end
        end
    end)
    Q.say("NOTE removed: " .. S.text(removed))
end)
Q.waitMs(1500)
Q.step(2, function()
    local c = S.count()
    Q.check(c.bodies == 0, "no animal corpse left round Angel", S.text(c))
    Q.check(c.blood == 0, "no bloody square left round Angel", S.text(c))
    Q.check(c.plots == 0, "no dead or trampled crop plot left round Angel", S.text(c))
    Q.check(c.junk == 0, "no eggs, wool, dung, broken glass or empty cans left round Angel (3 squares round him kept)", S.text(c))
end)
S.shot("zq_tidy_after", "the drag strip round Angel after the tidy")
Q.mark()
Q.step(2, function() if S.pair and RT.pairOpen then RT.pairOpen() end end)
Q.start()
