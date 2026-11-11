-- ZeDUI/tools/qa/gallery_b11_away.lua  (Nov 11 2026, QA): moves the QA character about 70 squares from the QA home, to open
-- ground with no building, so pictures taken after the farm run (gallery_farm_ranch.lua leaves its hutch, plots, troughs and
-- animals at the home) do not show them. Tries four directions; the first with loaded, building-free floor wins.
-- grep "ZEDQA away".
local p = getPlayer()
local function say(s) print("ZEDQA away " .. tostring(s)) end
local x0, y0 = math.floor(p:getX()), math.floor(p:getY())
local OFFS = { { 70, 0 }, { -70, 0 }, { 0, 70 }, { 0, -70 }, { 110, 0 }, { -110, 0 } }
local k, wait, done = 0, 0, false
local function tick()
    wait = wait + 1
    if done then
        if wait > 60 then Events.OnTick.Remove(tick); say("DONE") end
        return
    end
    if wait == 1 then
        k = k + 1
        if k > #OFFS then say("ERR no open ground found; staying"); done = true; wait = 0; return end
        local x, y = x0 + OFFS[k][1], y0 + OFFS[k][2]
        p:setX(x + 0.5); p:setY(y + 0.5); p:setZ(0); p:setLastX(x + 0.5); p:setLastY(y + 0.5); p:setLastZ(0)
        return
    end
    if wait < 90 then return end
    local x, y = x0 + OFFS[k][1], y0 + OFFS[k][2]
    local cell = getCell()
    local ok, n = true, 0
    for dx = -12, 12, 3 do for dy = -12, 12, 3 do
        local sq = cell:getGridSquare(x + dx, y + dy, 0)
        if not sq or not sq:getFloor() then ok = false elseif sq:getBuilding() then ok = false else n = n + 1 end
    end end
    say(string.format("offset %d,%d: open %s (%d squares)", OFFS[k][1], OFFS[k][2], tostring(ok), n))
    if ok then
        pcall(function() p:setDir(IsoDirections.S) end)
        done = true; wait = 0
        return
    end
    wait = 0
end
Events.OnTick.Add(tick)
