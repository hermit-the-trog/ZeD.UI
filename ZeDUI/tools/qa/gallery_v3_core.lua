-- ZeDUI/tools/qa/gallery_v3_core.lua  (Oct 21 2026)
-- Workshop gallery v3, part 1 of a set (core -> stage -> zed/vanilla scenes -> teardown).
-- Defines the global GAL (sequencer, shot, spot search, kit, props, zombies, restore list)
-- used by the other gallery_v3_*.lua scripts, then finds the spot: the Valley Station
-- mall parking lot (cells 54_22 / 54_23: x 13824-14079, y 5632-6143). It probes the
-- meta grid (rooms and zones, no loading needed) for the mall and its parking zones,
-- moves there, scans the loaded squares for an open asphalt box with cars around and
-- stands the character on it. Then one wide scout picture (g3_scout_wide.png).
-- ZeD-independent: also runs with ZeD off (the vanilla comparison run, ZeDQAShim).
-- The spot is fixed at 13935,5729 (found by the search on Oct 21); GAL_FORCE = { px, py }
-- above this header picks another, GAL_SEARCH = true runs the search again.
-- Nothing here is put back: gallery_v3_teardown.lua does that (GAL.R holds what was).
-- Output "ZEDQA g3c ..." ending "ZEDQA g3c DONE".
local TAG = "g3c"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local p = getPlayer()
if not p then say("ERR no player"); say("DONE"); return end

GAL = GAL or {}
local G = GAL
G.p = p
G.pn = p:getPlayerNum()
G.inv = p:getInventory()
G.core = getCore()
G.gt = getGameTime()
G.A = G.A or { worn = {}, cars = {}, world = {}, zombies = {}, near = {}, attached = {} }

-- ---------------------------------------------------------------------------
-- The sequencer: S.step(after, fn) runs fn once, `after` frames after the step
-- before it; S.poll(after, max, fn, onTimeout) runs fn every frame until true.
-- Driven from OnRenderTick (the pause menu stops OnTick). S.start() prints the
-- start; the last step prints "<tag> DONE".
-- ---------------------------------------------------------------------------
function G.newSeq(tag, maxMs)
    local S = { tag = tag, queue = {}, qi = 1, tick = 0, lastDone = 0, nOk = 0, nErr = 0 }
    function S.say(s) print("ZEDQA " .. tag .. " " .. tostring(s)) end
    function S.step(after, fn) S.queue[#S.queue + 1] = { after = after, fn = fn } end
    function S.poll(after, max, fn, onTimeout) S.queue[#S.queue + 1] = { after = after, fn = fn, max = max, timeout = onTimeout } end
    function S.waitMs(ms)
        local t0 = nil
        S.poll(0, math.floor(ms / 3) + 900, function()
            t0 = t0 or getTimestampMs()
            return getTimestampMs() - t0 >= ms
        end)
    end
    -- the zoom eases between levels: read once settled, turned into wheel steps (0.25 a level at 4K)
    function S.zoomTo(z)
        local left = nil
        S.waitMs(700)
        S.poll(20, 1200, function()
            if left == nil then left = math.floor((G.core:getZoom(0) - z) / 0.25 + 0.5) end
            if left == 0 then return true end
            G.core:doZoomScroll(0, (left > 0) and -1 or 1)
            left = (left > 0) and (left - 1) or (left + 1)
            return left == 0
        end)
        S.waitMs(1600)
        S.step(2, function() S.say("zoom " .. tostring(G.core:getZoom(0))) end)
    end
    function S.shot(name)
        local f = name .. ".png"
        local ok, e = pcall(function() G.core:TakeFullScreenshot(f) end)
        if ok then S.nOk = S.nOk + 1; S.say("shot " .. name .. " ok")
        else S.nErr = S.nErr + 1; S.say("ERR shot " .. name .. ": " .. tostring(e)) end
    end
    function S.err(name, why) S.nErr = S.nErr + 1; S.say("ERR " .. tostring(name) .. ": " .. tostring(why)) end
    function S.start()
        local startMs = getTimestampMs()
        local limit = maxMs or 600000
        S.step(2, function() S.say(string.format("end: %d shots ok, %d errors", S.nOk, S.nErr)); S.say("DONE") end)
        local fin = #S.queue
        local function onFrame()
            S.tick = S.tick + 1
            local s = S.queue[S.qi]
            if not s then Events.OnRenderTick.Remove(onFrame); return end
            if S.qi < fin and getTimestampMs() - startMs > limit then
                S.say("ERR ran too long at step " .. S.qi .. ": jumping to the end")
                S.qi = fin; S.lastDone = S.tick
                return
            end
            if not s.startTick then
                if S.tick - S.lastDone < s.after then return end
                s.startTick = S.tick
            end
            local done = true
            local ok, r = pcall(s.fn)
            if not ok then
                S.say("ERR step " .. S.qi .. " " .. tostring(r))
            elseif s.max then
                done = r == true
                if not done and S.tick - s.startTick >= s.max then
                    if s.timeout then pcall(s.timeout) end
                    S.say("note: step " .. S.qi .. " timed out")
                    done = true
                end
            end
            if done then S.lastDone = S.tick; S.qi = S.qi + 1 end
        end
        Events.OnRenderTick.Add(onFrame)
        S.say("start (" .. #S.queue .. " steps)")
    end
    return S
end

-- ---------------------------------------------------------------------------
-- Squares
-- ---------------------------------------------------------------------------
function G.sqAt(x, y) return getCell():getGridSquare(x, y, 0) end
function G.tp(x, y, z)
    p:teleportTo(x, y, z or 0)
    pcall(function() p:setX(x); p:setY(y); p:setZ(z or 0); p:setLastX(x); p:setLastY(y); p:setLastZ(z or 0) end)
end
local function spriteName(o)
    local n = ""
    pcall(function() n = tostring(o:getSprite():getName()) end)
    return n
end
G.spriteName = spriteName
-- open asphalt: outside, a street-type floor, nothing standing on it (markings and blends allowed)
function G.isLot(sq)
    if not sq or not sq:isOutside() then return false end
    local floor = sq:getFloor()
    if not floor then return false end
    if not spriteName(floor):find("street", 1, true) then return false end
    local free = false
    pcall(function() free = sq:isFree(false) and not sq:HasTree() and not sq:getVehicleContainer() end)
    if not free then return false end
    local objs = sq:getObjects()
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if o ~= floor then
            local n = spriteName(o)
            if not (n:find("street", 1, true) or n:find("blends_", 1, true) or n:find("floors_", 1, true)
                    or n:find("vegetation_groundcover", 1, true) or n:find("trafficline", 1, true)) then return false end
        end
    end
    local solid = false
    pcall(function() solid = sq:isSolid() or sq:isSolidTrans() end)
    return not solid
end
-- the nearest lot square to x, y (ring search), avoiding the reserved box
function G.nearLot(x, y, maxR)
    for r = 0, maxR or 6 do
        for dy = -r, r do
            for dx = -r, r do
                if math.max(math.abs(dx), math.abs(dy)) == r then
                    local qx, qy = x + dx, y + dy
                    if not G.reserved(qx, qy) and G.isLot(G.sqAt(qx, qy)) then return qx, qy end
                end
            end
        end
    end
    return nil
end
-- the box kept clear round the character and the car (G.spot set)
function G.reserved(x, y)
    local s = G.spot
    if not s then return false end
    return x >= s.px - 3 and x <= s.px + 8 and y >= s.py - 3 and y <= s.py + 3
end
function G.vehiclesNear(x, y, r)
    local n = 0
    pcall(function()
        local it = getCell():getVehicles():iterator()
        while it:hasNext() do
            local v = it:next()
            if math.abs(v:getX() - x) <= r and math.abs(v:getY() - y) <= r then n = n + 1 end
        end
    end)
    return n
end

-- ---------------------------------------------------------------------------
-- Look and light: the console hidden, no vision cone, no container outline, day, clear sky
-- ---------------------------------------------------------------------------
G.R = G.R or nil
function G.saveWas()
    if G.R then return end
    local R = { x = p:getX(), y = p:getY(), z = p:getZ(), zoom = G.core:getZoom(0), tod = G.gt:getTimeOfDay(),
                speed = getGameSpeed(), clim = {}, hidden = {}, dda = false }
    pcall(function() R.dda = p:isZombiesDontAttack() end)
    pcall(function()
        local o = getDebugOptions()
        R.dbgVision = o:getBoolean("FBORenderChunk.RenderVisionPolygon")
        R.dbgHigh = o:getBoolean("Terrain.RenderTiles.RenderContainerHighlight")
        R.dbgSee = o:getBoolean("Cheat.Player.SeeEveryone")
        R.dbgArea = o:getBoolean("Vehicle.Render.Area")
    end)
    G.R = R
end
function G.cleanLook()
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do
            local e = ui:get(i)
            if e:getClass():getSimpleName() == "UIDebugConsole" and e:isVisible() then e:setVisible(false); G.R.hidden[#G.R.hidden + 1] = e end
        end
    end)
    pcall(function()
        local o = getDebugOptions()
        o:setBoolean("FBORenderChunk.RenderVisionPolygon", false)
        o:setBoolean("Terrain.RenderTiles.RenderContainerHighlight", false)
    end)
    -- zombies behind the character are drawn too (the vision cone would hide them)
    pcall(function() getDebugOptions():setBoolean("Cheat.Player.SeeEveryone", true) end)
    pcall(function() getDebugOptions():setBoolean("Vehicle.Render.Area", false) end)
    pcall(function() p:setZombiesDontAttack(true) end)
    pcall(function() p:setGodMod(true) end)
    if Mouse and Mouse.setXY then pcall(function() Mouse.setXY(math.floor(G.core:getScreenWidth() / 2), math.floor(G.core:getScreenHeight() - 6)) end) end
end
function G.climSet(vals)
    local cm = getClimateManager()
    for i = 0, cm:getFloatMax() - 1 do
        local v = cm:getClimateFloat(i)
        local n = tostring(v:getName())
        local want = vals[n]
        if want == nil then
            local l = n:lower()
            if vals._clear and (l:find("fog", 1, true) or l:find("precip", 1, true) or l:find("cloud", 1, true)) then want = 0 end
        end
        if want ~= nil then
            local seen = false
            for _, c in ipairs(G.R.clim) do if c.v == v then seen = true end end
            if not seen then G.R.clim[#G.R.clim + 1] = { v = v, en = v:isEnableAdmin(), val = v:getAdminValue() } end
            v:setEnableAdmin(true)
            v:setAdminValue(want)
        end
    end
end
function G.day()
    G.gt:setTimeOfDay(10.0)
    G.climSet({ _clear = true })
end
function G.night()
    G.gt:setTimeOfDay(22.0)
    G.climSet({ _clear = true, NIGHT_STRENGTH = 1.0, DAYLIGHT_STRENGTH = 0.0, GLOBAL_LIGHT_INTENSITY = 0.0, AMBIENT = 0.12 })
end
function G.dayAgain()
    -- the night values dropped (back to what they were), the day and the clear sky kept
    for _, c in ipairs(G.R.clim) do
        local n = tostring(c.v:getName())
        if n == "NIGHT_STRENGTH" or n == "DAYLIGHT_STRENGTH" or n == "GLOBAL_LIGHT_INTENSITY" or n == "AMBIENT" then
            pcall(function() c.v:setAdminValue(c.val); c.v:setEnableAdmin(c.en) end)
        end
    end
    G.gt:setTimeOfDay(10.0)
end
-- the character on its spot: the exact point stage chose (fx, fy) or the square's centre
function G.stand()
    local s = G.spot
    G.tp(s.fx or (s.px + 0.5), s.fy or (s.py + 0.5), 0)
end
function G.faceFront()pcall(function() if not p:getVehicle() then p:setDir(IsoDirections.SE) end end) end

-- ===========================================================================
-- THE SEARCH
-- ===========================================================================
local S = G.newSeq(TAG, 420000)
local F = { names = {}, mall = nil, park = {}, best = nil, row = 0, anchors = {}, ai = 0 }
local PX0, PX1, PY0, PY1, STEP = 13500, 14400, 5300, 6250, 4

S.step(2, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    G.saveWas()
    G.cleanLook()
    say(string.format("start at %d,%d zoom %s | ZeD %s", math.floor(p:getX()), math.floor(p:getY()), tostring(G.core:getZoom(0)), tostring(ZeD ~= nil)))
    -- the spot the Oct 21 scout found (Valley Station mall, east lot; checked by eye), so the ZeD
    -- and the vanilla runs stand on the same square; GAL_SEARCH = true searches again
    local force = GAL_FORCE or ((not GAL_SEARCH) and { px = 13935, py = 5729 }) or nil
    if force then
        G.spot = { px = force.px, py = force.py, forced = true }
        say("forced spot " .. force.px .. "," .. force.py)
    end
    F.row = PY0
end)
-- A. the meta grid: rooms (names) and zones (types), a row a frame
S.poll(2, 2000, function()
    if G.spot then return true end
    local mg = getWorld():getMetaGrid()
    local y = F.row
    for x = PX0, PX1, STEP do
        local rd = nil
        pcall(function() rd = mg:getRoomAt(x, y, 0) end)
        if rd then
            local n = tostring(rd:getName())
            F.names[n] = (F.names[n] or 0) + 1
            if n:lower():find("mall", 1, true) then
                local m = F.mall or { x0 = x, x1 = x, y0 = y, y1 = y, n = 0 }
                m.x0 = math.min(m.x0, x); m.x1 = math.max(m.x1, x); m.y0 = math.min(m.y0, y); m.y1 = math.max(m.y1, y); m.n = m.n + 1
                F.mall = m
            end
        end
        pcall(function()
            local zs = mg:getZonesAt(x, y, 0)
            for i = 0, zs:size() - 1 do
                local t = tostring(zs:get(i):getType())
                F.names["zone:" .. t] = (F.names["zone:" .. t] or 0) + 1
                local l = t:lower()
                if l:find("park", 1, true) then F.park[#F.park + 1] = { x, y } end
            end
        end)
    end
    F.row = F.row + STEP
    return F.row > PY1
end)
S.step(2, function()
    if G.spot then return end
    local list = {}
    for n, c in pairs(F.names) do list[#list + 1] = { n, c } end
    table.sort(list, function(a, b) return a[2] > b[2] end)
    local top = {}
    for i = 1, math.min(40, #list) do top[#top + 1] = list[i][1] .. "=" .. list[i][2] end
    say("meta: " .. table.concat(top, " "))
    local m = F.mall
    if m then say(string.format("mall rooms: x %d-%d y %d-%d (%d probes)", m.x0, m.x1, m.y0, m.y1, m.n)) else say("note: no room named mall") end
    say("parking zone probes: " .. #F.park)
    -- anchors: parking probes nearest the mall first (clustered every 24 squares), then round the mall
    local cx, cy = 13950, 5760
    if m then cx, cy = math.floor((m.x0 + m.x1) / 2), math.floor((m.y0 + m.y1) / 2) end
    local cl = {}
    for _, q in ipairs(F.park) do
        local k = math.floor(q[1] / 24) .. ":" .. math.floor(q[2] / 24)
        local c = cl[k] or { x = 0, y = 0, n = 0 }
        c.x = c.x + q[1]; c.y = c.y + q[2]; c.n = c.n + 1
        cl[k] = c
    end
    local cand = {}
    for _, c in pairs(cl) do
        if c.n >= 4 then
            local x, y = math.floor(c.x / c.n), math.floor(c.y / c.n)
            local d = math.abs(x - cx) + math.abs(y - cy)
            if d < 260 then cand[#cand + 1] = { x, y, c.n, d } end
        end
    end
    table.sort(cand, function(a, b) return (a[4] - a[3] * 2) < (b[4] - b[3] * 2) end)
    for i = 1, math.min(4, #cand) do F.anchors[#F.anchors + 1] = { cand[i][1], cand[i][2], "parking zone (" .. cand[i][3] .. " probes, " .. cand[i][4] .. " from the mall)" } end
    if m then
        F.anchors[#F.anchors + 1] = { cx, m.y1 + 30, "south of the mall" }
        F.anchors[#F.anchors + 1] = { m.x1 + 30, cy, "east of the mall" }
        F.anchors[#F.anchors + 1] = { cx, m.y0 - 30, "north of the mall" }
        F.anchors[#F.anchors + 1] = { m.x0 - 30, cy, "west of the mall" }
    else
        F.anchors[#F.anchors + 1] = { cx, cy, "cell centre" }
    end
    local a = {}
    for _, q in ipairs(F.anchors) do a[#a + 1] = q[1] .. "," .. q[2] .. " " .. q[3] end
    say("anchors: " .. table.concat(a, " | "))
end)
-- B. each anchor: move, wait for the cell, score every square (a box of lot round it, cars near)
local B = { ph = "next", t0 = 0, row = 0, grid = nil, a = nil }
local R = 48
local function lotAt(x, y)
    local g = B.grid
    local k = (y - B.a[2] + R) * (2 * R + 1) + (x - B.a[1] + R)
    return g[k] == true
end
S.poll(2, 20000, function()
    if G.spot and G.spot.forced then return true end
    local now = getTimestampMs()
    if B.ph == "next" then
        F.ai = F.ai + 1
        B.a = F.anchors[F.ai]
        if not B.a or F.ai > 6 then return true end
        G.tp(B.a[1] + 0.5, B.a[2] + 0.5, 0)
        B.t0 = now; B.ph = "load"; B.grid = {}; B.row = -R
        say("moving to " .. B.a[3] .. " (" .. B.a[1] .. "," .. B.a[2] .. ")")
    elseif B.ph == "load" then
        if G.sqAt(B.a[1], B.a[2]) and now - B.t0 >= 9000 then B.ph = "grid"
        elseif now - B.t0 > 40000 then say("note: no load at " .. B.a[1] .. "," .. B.a[2]); B.ph = "next" end
    elseif B.ph == "grid" then
        local y = B.a[2] + B.row
        for x = B.a[1] - R, B.a[1] + R do
            if G.isLot(G.sqAt(x, y)) then B.grid[(B.row + R) * (2 * R + 1) + (x - B.a[1] + R)] = true end
        end
        B.row = B.row + 1
        if B.row > R then B.ph = "score"; B.row = -R + 6 end
    elseif B.ph == "score" then
        -- the box: x px-4..px+9, y py-4..py+4 all lot (the character, the car east of it, the bag, near zombies)
        local py = B.a[2] + B.row
        for px = B.a[1] - R + 6, B.a[1] + R - 10 do
            local ok = true
            for dy = -4, 4 do
                for dx = -4, 9 do
                    if not lotAt(px + dx, py + dy) then ok = false; break end
                end
                if not ok then break end
            end
            if ok then
                local lot = 0
                for dy = -14, 14, 2 do
                    for dx = -14, 14, 2 do
                        local gx, gy = px + dx, py + dy
                        if math.abs(gx - B.a[1]) <= R and math.abs(gy - B.a[2]) <= R and lotAt(gx, gy) then lot = lot + 1 end
                    end
                end
                local cars = G.vehiclesNear(px, py, 22)
                -- a building behind (up the screen, north west) for the background
                local behind = 0
                for d = 6, 30, 3 do
                    local q = G.sqAt(px - d, py - d)
                    if q and not q:isOutside() then behind = behind + 1 end
                end
                local score = lot + cars * 6 + math.min(behind, 4) * 5
                if not F.best or score > F.best.score then
                    F.best = { px = px, py = py, score = score, lot = lot, cars = cars, behind = behind, note = B.a[3] }
                end
            end
        end
        B.row = B.row + 1
        if B.row > R - 6 then B.ph = "next" end
    end
    return false
end)
S.step(2, function()
    if not G.spot then
        if F.best then
            G.spot = { px = F.best.px, py = F.best.py }
            say(string.format("spot %d,%d | %s | score %d lot %d cars %d building behind %d",
                F.best.px, F.best.py, F.best.note, F.best.score, F.best.lot, F.best.cars, F.best.behind))
        else
            say("ERR no open asphalt box found at any anchor")
            return
        end
    end
    G.tp(G.spot.px + 0.5, G.spot.py + 0.5, 0)
end)
S.waitMs(9000)
S.step(2, function()
    if not G.spot then return end
    G.day()
    G.faceFront()
    local sq = p:getCurrentSquare()
    local fl = sq and sq:getFloor()
    say(string.format("standing at %d,%d floor %s outside %s | cars within 22: %d | zombies in the cell %d",
        math.floor(p:getX()), math.floor(p:getY()), fl and spriteName(fl) or "?", tostring(sq and sq:isOutside()),
        G.vehiclesNear(p:getX(), p:getY(), 22), getCell():getZombieList():size()))
    -- floor sprites around (what a lot is made of here)
    local h = {}
    for dy = -12, 12, 3 do
        for dx = -12, 12, 3 do
            local q = G.sqAt(G.spot.px + dx, G.spot.py + dy)
            local f = q and q:getFloor()
            local n = f and spriteName(f):gsub("_%d+$", "") or "none"
            h[n] = (h[n] or 0) + 1
        end
    end
    local t = {}
    for n, c in pairs(h) do t[#t + 1] = n .. "=" .. c end
    say("floors round the spot: " .. table.concat(t, " "))
end)
S.zoomTo(1.75)
S.step(30, function() if G.spot then S.shot("g3_scout_wide") end end)
S.zoomTo(1.0)
S.step(30, function() if G.spot then S.shot("g3_scout_mid") end end)
S.start()
