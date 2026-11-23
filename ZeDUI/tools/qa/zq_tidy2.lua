-- ZeDUI/tools/qa/zq_tidy2.lua  (Nov 23 2026, QA; tag zq_tidy2): the dug patches left in the field east of the drag
-- strip after zq_tidy (the director: "torn up grass everywhere"). zq_tidy_scan2 showed them as grass floors
-- (blends_natural_01_*) carrying attached dirt sprites (blends_natural_01_87 and stacks of 41/42/45/46) in the open
-- field, where untouched grass carries none. This clears the attached sprites on grass floors in the field only: from
-- x 921 (east of the road's edge) to 30 squares east of the character, 30 squares north and south, his floor. The
-- road, its edges, the fence line and every object are left alone. Pictures zq_tidy2_before / zq_tidy2_after.
-- Check: no grass floor in the field still carries an attached sprite.
local Q = RT.make("zq_tidy2")
local S = { p = getPlayer(), R = 30, X0 = 921 }

function S.each(fn)
    local cell = getCell()
    local px, py, pz = math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())
    for x = math.max(S.X0, px - S.R), px + S.R do
        for y = py - S.R, py + S.R do
            local sq = cell:getGridSquare(x, y, pz)
            if sq then fn(sq) end
        end
    end
end
function S.grassWithDirt(sq)
    local fl = sq:getFloor()
    if not fl then return nil end
    local nm = fl:getSprite() and fl:getSprite():getName() or ""
    if nm:find("blends_natural_01_", 1, true) ~= 1 then return nil end
    local n = 0
    pcall(function() local a = fl:getAttachedAnimSprite(); n = a and a:size() or 0 end)
    if n > 0 then return fl end
    return nil
end
function S.count() local c = 0; S.each(function(sq) if S.grassWithDirt(sq) then c = c + 1 end end); return c end
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
    S.pair = RT.isOpen()
    RT.pairShut()
    S.c0 = S.count()
    Q.say("NOTE before: " .. S.c0 .. " grass squares with dirt on them in the field")
end)
Q.waitMs(1500)
S.shot("zq_tidy2_before", "the field east of the drag strip before the dug patches are cleared")
Q.step(1, function()
    local n = 0
    S.each(function(sq)
        local fl = S.grassWithDirt(sq)
        if fl then
            pcall(function() fl:clearAttachedAnimSprite() end)
            pcall(function() sq:RecalcAllWithNeighbours(true) end)
            n = n + 1
        end
    end)
    Q.say("NOTE cleared: " .. n .. " squares")
end)
Q.waitMs(1500)
Q.step(2, function()
    local c = S.count()
    Q.check(c == 0, "no grass square in the field still carries dirt", c .. " left of " .. tostring(S.c0))
end)
S.shot("zq_tidy2_after", "the field east of the drag strip after the dug patches are cleared")
Q.mark()
Q.step(2, function() if S.pair then RT.pairOpen() end end)
Q.start()
