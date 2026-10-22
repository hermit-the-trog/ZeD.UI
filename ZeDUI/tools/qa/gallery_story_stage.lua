-- ZeDUI/tools/qa/gallery_story_stage.lua  (Oct 21 2026)
-- Story gallery, part 1 of 3 (stage -> gallery_story_shots.lua -> gallery_story_teardown.lua).
-- The story: the character pumped gas at a Fossoil before the outbreak and is getting the
-- store running again. This script moves the character to the Fossoil, dresses the
-- gallery_v3 kit, gives the story's profession, traits and skills, puts out the props and
-- seeds the flyer, the journal entry and the map note. Everything changed is kept in
-- STORY.R / STORY.A for the teardown (gallery_story_teardown.lua puts all of it back).
--
-- The site: the Fossoil nearest the Valley Station mall lot, from the map data
-- (media/maps/Muldraugh, KY/49_25.lotheader: room "fossoil" 12687,6515 4x2 + 12687,6517
-- 7x10, "gasstorage" 12691,6515 3x2), on the road between West Point and Valley Station,
-- about 1470 squares south west of the lot. The director picked the West Point Fossoil
-- (47_27.lotheader, rooms "fossoil" 12052-12069 x 7117-7126: the station the Fossoil (West
-- Point) flyer is for, so the flyer pin, the map note and the store agree); it is the
-- default. STORY_SITE = "valley" above this header uses the 49_25 one.
-- The shelves, counters, pumps and windows are found at run time (scan of the loaded
-- squares) and printed; STORY_AT = { stock = {x,y}, clerk = {x,y}, queueDir = {dx,dy},
-- pump = {x,y}, win = {x,y}, blood = {x,y}, smoke = {x,y} } overrides any of them.
--
-- The character (director, Oct 21 2026): profession Mechanics (the game has no gas station
-- attendant; Mechanics is the closest real job, a service station hand, and it explains the
-- tire change), traits Smoker, Speed Demon, Strong, Dextrous, Fast Reader (positive 15
-- points) against Prone to Illness, Hearty Appetite, Slow Healer, Pacifist and the
-- profession's -4 (15 points): a 0-point character. Skills from the real profession and
-- trait boosts (Mechanics 4, Metalworking 1, Strength 5+4, Fitness 5), a little progress.
-- "ZEDQA sts ..." ending "ZEDQA sts DONE". Takes one scout picture, story_00_scout.png.
local p = getPlayer()
if not p then print("ZEDQA sts ERR no player"); print("ZEDQA sts DONE"); return end
if STORY and STORY.R then print("ZEDQA sts ERR a story stage is still up: run gallery_story_teardown.lua first"); print("ZEDQA sts DONE"); return end

STORY = {}
local ST = STORY
ST.p = p
ST.pn = p:getPlayerNum()
ST.inv = p:getInventory()
ST.core = getCore()
ST.gt = getGameTime()
ST.A = { worn = {}, cars = {}, world = {}, zombies = {}, queue = {}, native = {}, blood = {}, lights = {}, pumps = {} }
ST.SITES = {
    valley = { name = "Fossoil between West Point and Valley Station", x0 = 12687, y0 = 6515, x1 = 12693, y1 = 6526, flyer = "Fossoil2" },
    westpoint = { name = "Fossoil, West Point", x0 = 12052, y0 = 7117, x1 = 12069, y1 = 7126, flyer = "Fossoil2" },
}
ST.site = ST.SITES[STORY_SITE or "westpoint"] or ST.SITES.westpoint
ST.AT = STORY_AT or {}
ST.JOURNAL = "back to Fossoil tmrw. get it running. pumps first if theres any juice left, board up the front, clean up the mess. prob still smokes in the back"
ST.NOTE = "fossoil. my old pumps"

-- ---------------------------------------------------------------------------
-- The sequencer (as gallery_v3_core.lua): S.step(after, fn) runs fn once, `after`
-- frames after the step before; S.poll(after, max, fn, onTimeout) every frame until
-- true. Driven from OnRenderTick. The last step prints "<tag> DONE".
-- ---------------------------------------------------------------------------
function ST.newSeq(tag, maxMs)
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
    function S.zoomTo(z)
        local left = nil
        S.waitMs(700)
        S.poll(20, 1200, function()
            if left == nil then left = math.floor((ST.core:getZoom(0) - z) / 0.25 + 0.5) end
            if left == 0 then return true end
            ST.core:doZoomScroll(0, (left > 0) and -1 or 1)
            left = (left > 0) and (left - 1) or (left + 1)
            return left == 0
        end)
        S.waitMs(1600)
        S.step(2, function() S.say("zoom " .. tostring(ST.core:getZoom(0))) end)
    end
    function S.shot(name)
        local ok, e = pcall(function() ST.core:TakeFullScreenshot(name .. ".png") end)
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
-- Squares, look, light, weather (as gallery_v3_core.lua)
-- ---------------------------------------------------------------------------
function ST.sqAt(x, y, z) return getCell():getGridSquare(x, y, z or 0) end
function ST.tp(x, y, z)
    p:teleportTo(x, y, z or 0)
    pcall(function() p:setX(x); p:setY(y); p:setZ(z or 0); p:setLastX(x); p:setLastY(y); p:setLastZ(z or 0) end)
end
function ST.tpSq(q) if q then ST.tp(q[1] + 0.5, q[2] + 0.5, 0) end end
function ST.spriteName(o)
    local n = ""
    pcall(function() n = tostring(o:getSprite():getName()) end)
    return n
end
function ST.free(sq)
    if not sq then return false end
    local ok = false
    pcall(function() ok = sq:isFree(false) and not sq:getVehicleContainer() end)
    return ok
end
function ST.saveWas()
    local R = { x = p:getX(), y = p:getY(), z = p:getZ(), zoom = ST.core:getZoom(0), tod = ST.gt:getTimeOfDay(),
                speed = getGameSpeed(), clim = {}, hidden = {}, dda = false, god = false }
    pcall(function() R.dda = p:isZombiesDontAttack() end)
    pcall(function() R.god = p:isGodMod() end)
    pcall(function()
        local o = getDebugOptions()
        R.dbgVision = o:getBoolean("FBORenderChunk.RenderVisionPolygon")
        R.dbgHigh = o:getBoolean("Terrain.RenderTiles.RenderContainerHighlight")
        R.dbgSee = o:getBoolean("Cheat.Player.SeeEveryone")
        R.dbgArea = o:getBoolean("Vehicle.Render.Area")
    end)
    ST.R = R
end
function ST.cleanLook()
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do
            local e = ui:get(i)
            if e:getClass():getSimpleName() == "UIDebugConsole" and e:isVisible() then e:setVisible(false); ST.R.hidden[#ST.R.hidden + 1] = e end
        end
    end)
    pcall(function()
        local o = getDebugOptions()
        o:setBoolean("FBORenderChunk.RenderVisionPolygon", false)
        o:setBoolean("Terrain.RenderTiles.RenderContainerHighlight", false)
        o:setBoolean("Cheat.Player.SeeEveryone", true)
        o:setBoolean("Vehicle.Render.Area", false)
    end)
    pcall(function() p:setZombiesDontAttack(true) end)
    pcall(function() p:setGodMod(true) end)
end
function ST.parkMouse()
    if Mouse and Mouse.setXY then pcall(function() Mouse.setXY(math.floor(ST.core:getScreenWidth() / 2), math.floor(ST.core:getScreenHeight() - 6)) end) end
end
function ST.climSet(vals)
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
            for _, c in ipairs(ST.R.clim) do if c.v == v then seen = true end end
            if not seen then ST.R.clim[#ST.R.clim + 1] = { v = v, en = v:isEnableAdmin(), val = v:getAdminValue() } end
            v:setEnableAdmin(true)
            v:setAdminValue(want)
        end
    end
end
-- daylight at an hour (10:00-16:00 for the day beats), clear sky
function ST.day(h)
    for _, c in ipairs(ST.R.clim) do
        local n = tostring(c.v:getName())
        if n == "NIGHT_STRENGTH" or n == "DAYLIGHT_STRENGTH" or n == "GLOBAL_LIGHT_INTENSITY" or n == "AMBIENT" then
            pcall(function() c.v:setAdminValue(c.val); c.v:setEnableAdmin(c.en) end)
        end
    end
    ST.gt:setTimeOfDay(h or 10.0)
    ST.climSet({ _clear = true })
end
function ST.night()
    ST.gt:setTimeOfDay(22.0)
    ST.climSet({ _clear = true, NIGHT_STRENGTH = 1.0, DAYLIGHT_STRENGTH = 0.0, GLOBAL_LIGHT_INTENSITY = 0.0, AMBIENT = 0.12 })
end
function ST.face(dir) pcall(function() if not p:getVehicle() then p:setDir(IsoDirections[dir or "SE"]) end end) end
function ST.exists(ft)
    local ok, it = pcall(function() return getScriptManager():FindItem(ft) end)
    return ok and it ~= nil
end
function ST.add(ft, container)
    if not ST.exists(ft) then return nil end
    local it = nil
    pcall(function() it = (container or ST.inv):AddItem(ft) end)
    return it
end
function ST.find(ft, container)
    local items = (container or ST.inv):getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it:getFullType() == ft then return it end
    end
    return nil
end
-- the running timed action, its type and its progress
function ST.action()
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    local a = q and q.queue and q.queue[1]
    if not a then return nil, nil, 0, 0 end
    local d = 0
    pcall(function() d = a:getJobDelta() end)
    local same = 0
    for _, b in ipairs(q.queue) do if b.Type == a.Type then same = same + 1 end end
    return a, a.Type, d, same
end
function ST.clearActions() pcall(function() ISTimedActionQueue.clear(p) end) end

-- ===========================================================================
-- THE SITE SCAN (the loaded squares round the Fossoil room)
-- ===========================================================================
-- in the store: inside the site's box and in a room named fossoil (not the gas storage beside it)
function ST.inRoom(x, y)
    local s = ST.site
    if not (x >= s.x0 and x <= s.x1 and y >= s.y0 and y <= s.y1) then return false end
    local name = nil
    pcall(function() name = tostring(ST.sqAt(x, y):getRoom():getName()) end)
    return name ~= nil and name:lower():find("fossoil", 1, true) ~= nil
end
function ST.contType(o)
    local t = nil
    pcall(function() local c = o:getContainer(); if c then t = tostring(c:getType()) end end)
    return t
end
function ST.isPump(o)
    local yes = false
    pcall(function() local pr = o:getSprite():getProperties(); yes = pr:has("fuelAmount") or (pr:get("fuelAmount") ~= nil) end)
    return yes
end
function ST.scan()
    local s = ST.site
    local F = { shelves = {}, counters = {}, other = {}, pumps = {}, windows = {}, floor = {}, smashed = 0, barred = 0, types = {} }
    for y = s.y0 - 1, s.y1 + 1 do
        for x = s.x0 - 1, s.x1 + 1 do
            local sq = ST.sqAt(x, y)
            if sq then
                local objs = sq:getObjects()
                for i = 0, objs:size() - 1 do
                    local o = objs:get(i)
                    if instanceof(o, "IsoWindow") then
                        F.windows[#F.windows + 1] = { o = o, x = x, y = y }
                        if o:isSmashed() then F.smashed = F.smashed + 1 end
                        if o:isBarricaded() then F.barred = F.barred + 1 end
                    end
                    if ST.inRoom(x, y) then
                        local t = ST.contType(o)
                        if t then
                            F.types[t] = (F.types[t] or 0) + 1
                            local l = t:lower()
                            local e = { o = o, x = x, y = y, t = t, inv = o:getContainer() }
                            if l:find("shel", 1, true) then F.shelves[#F.shelves + 1] = e
                            elseif l:find("counter", 1, true) then F.counters[#F.counters + 1] = e
                            else F.other[#F.other + 1] = e end
                        end
                    end
                end
                if ST.inRoom(x, y) and ST.free(sq) then F.floor[#F.floor + 1] = { x, y } end
            end
        end
    end
    for y = s.y0 - 30, s.y1 + 30 do
        for x = s.x0 - 30, s.x1 + 30 do
            local sq = ST.sqAt(x, y)
            if sq then
                local objs = sq:getObjects()
                for i = 0, objs:size() - 1 do
                    local o = objs:get(i)
                    if ST.isPump(o) then F.pumps[#F.pumps + 1] = { o = o, x = x, y = y, sprite = ST.spriteName(o) } end
                end
            end
        end
    end
    ST.F = F
    return F
end
-- free outdoor squares next to (x, y), the nearest first
function ST.outNear(x, y, rmax, avoid)
    for r = 1, rmax or 4 do
        for dy = -r, r do
            for dx = -r, r do
                if math.max(math.abs(dx), math.abs(dy)) == r then
                    local q = ST.sqAt(x + dx, y + dy)
                    if q and q:isOutside() and ST.free(q) and not (avoid and avoid(x + dx, y + dy)) then return { x + dx, y + dy } end
                end
            end
        end
    end
    return nil
end
-- the positions every beat uses (printed; STORY_AT overrides)
function ST.plan(say)
    local F, s, AT = ST.F, ST.site, ST.AT
    local P = {}
    local cx, cy = math.floor((s.x0 + s.x1) / 2), math.floor((s.y0 + s.y1) / 2)
    P.centre = { cx, cy }
    -- stocking: the floor square with the most shelf containers in its 3x3 (World window's reach)
    local best, bestN = nil, -1
    for _, q in ipairs(F.floor) do
        local n, seen = 0, {}
        for _, e in ipairs(F.shelves) do
            if math.abs(e.x - q[1]) <= 1 and math.abs(e.y - q[2]) <= 1 and not seen[e.o] then
                local ok = false
                pcall(function() ok = ST.sqAt(q[1], q[2]):canReachTo(ST.sqAt(e.x, e.y)) or (e.x == q[1] and e.y == q[2]) end)
                if ok then n = n + 1; seen[e.o] = true end
            end
        end
        if n > bestN then best, bestN = q, n end
    end
    P.stock = AT.stock or best or P.centre
    say(string.format("stock spot %d,%d with %d shelf containers in reach", P.stock[1], P.stock[2], math.max(bestN, 0)))
    -- the counter: clerk on the short side, the queue along the long side
    local DIRS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
    local function run(x, y, d)
        local n = 0
        for k = 1, 8 do
            local q = ST.sqAt(x + d[1] * k, y + d[2] * k)
            if not (q and ST.inRoom(x + d[1] * k, y + d[2] * k) and ST.free(q)) then break end
            n = n + 1
        end
        return n
    end
    local cb = nil
    for _, e in ipairs(F.counters) do
        for _, d in ipairs(DIRS) do
            local front, back = run(e.x, e.y, d), run(e.x, e.y, { -d[1], -d[2] })
            if front >= 3 and back >= 1 then
                local sc = front - back
                if not cb or sc > cb.sc then cb = { sc = sc, c = { e.x, e.y }, d = d } end
            end
        end
    end
    if AT.clerk then
        P.clerk = AT.clerk
        P.queueDir = AT.queueDir or { 0, 1 }
        P.counter = { P.clerk[1] + P.queueDir[1], P.clerk[2] + P.queueDir[2] }
    elseif cb then
        P.counter = cb.c
        P.queueDir = cb.d
        P.clerk = { cb.c[1] - cb.d[1], cb.c[2] - cb.d[2] }
    else
        P.counter, P.queueDir, P.clerk = P.centre, { 0, 1 }, P.centre
        say("note: no counter with room for a queue found; using the room centre")
    end
    say(string.format("counter %d,%d clerk %d,%d queue toward %d,%d", P.counter[1], P.counter[2], P.clerk[1], P.clerk[2], P.queueDir[1], P.queueDir[2]))
    -- the pump nearest the store's centre
    local pb, pd = nil, 1e9
    for _, e in ipairs(F.pumps) do
        local d = math.abs(e.x - cx) + math.abs(e.y - cy)
        if d < pd then pb, pd = e, d end
    end
    if AT.pump then
        for _, e in ipairs(F.pumps) do if e.x == AT.pump[1] and e.y == AT.pump[2] then pb = e end end
    end
    P.pump = pb
    if pb then say(string.format("pump %d,%d (%s), %d pump squares round the store", pb.x, pb.y, pb.sprite, #F.pumps))
    else say("ERR no fuel pump found within 30 squares of the store") end
    -- the window to barricade: from outside, on the camera side (the larger x + y), not yet barricaded
    local wb, ws = nil, -1e9
    for _, e in ipairs(F.windows) do
        local o = e.o
        local outSq = nil
        pcall(function()
            local nx, ny = e.x, e.y
            if o:getNorth() then ny = e.y - 1 else nx = e.x - 1 end
            local a, b = ST.sqAt(e.x, e.y), ST.sqAt(nx, ny)
            if a and a:isOutside() then outSq = { e.x, e.y } elseif b and b:isOutside() then outSq = { nx, ny } end
        end)
        local ok = outSq and ST.free(ST.sqAt(outSq[1], outSq[2])) and not o:isBarricaded() and not o:isSmashed()
        pcall(function() ok = ok and o:isBarricadeAllowed() end)
        if AT.win and e.x == AT.win[1] and e.y == AT.win[2] then ok = outSq ~= nil; e.force = true end
        if ok then
            local sc = outSq[1] + outSq[2] + (e.force and 1e6 or 0)
            if sc > ws then wb, ws = { o = o, x = e.x, y = e.y, out = outSq }, sc end
        end
    end
    P.win = wb
    if wb then say(string.format("window %d,%d, barricaded from %d,%d", wb.x, wb.y, wb.out[1], wb.out[2]))
    else say("ERR no window that can be barricaded from outside") end
    say(string.format("windows %d (smashed %d, barricaded %d) | shelves %d counters %d other containers %d | free floor %d",
        #F.windows, F.smashed, F.barred, #F.shelves, #F.counters, #F.other, #F.floor))
    local tt = {}
    for t, n in pairs(F.types) do tt[#tt + 1] = t .. "=" .. n end
    say("container types: " .. table.concat(tt, " "))
    -- blood: a free floor square off the stock spot and the counter, near the room centre
    local bb, bd = nil, 1e9
    for _, q in ipairs(F.floor) do
        local d = math.abs(q[1] - cx) + math.abs(q[2] - cy)
        local busy = (q[1] == P.stock[1] and q[2] == P.stock[2]) or (q[1] == P.clerk[1] and q[2] == P.clerk[2])
        if not busy and d < bd then bb, bd = q, d end
    end
    P.blood = AT.blood or bb or P.centre
    say(string.format("blood %d,%d", P.blood[1], P.blood[2]))
    -- smoking: outside the store, away from the pumps (4+ squares), on the camera side
    local sb, sbs = nil, -1e9
    for y = s.y0 - 4, s.y1 + 4 do
        for x = s.x0 - 4, s.x1 + 4 do
            local q = ST.sqAt(x, y)
            if q and q:isOutside() and ST.free(q) and not ST.inRoom(x, y) then
                local far = true
                for _, e in ipairs(F.pumps) do if math.abs(e.x - x) + math.abs(e.y - y) < 5 then far = false end end
                local sc = x + y - (math.abs(x - cx) + math.abs(y - cy)) * 0.5
                if far and sc > sbs then sb, sbs = { x, y }, sc end
            end
        end
    end
    P.smoke = AT.smoke or sb or P.centre
    say(string.format("smoke spot %d,%d", P.smoke[1], P.smoke[2]))
    ST.P = P
    return P
end

-- ===========================================================================
-- THE CHARACTER: kit (as gallery_v3_stage.lua), profession, traits, skills
-- ===========================================================================
ST.KIT = {
    wear = {
        { "Base.Tshirt_DefaultTEXTURE_TINT", "Base.Tshirt_DefaultTEXTURE" },
        { "Base.Shirt_Lumberjack", "Base.Shirt_Denim" },
        { "Base.Jacket_ArmyOliveDrab", "Base.Jacket_Black" },
        { "Base.Vest_Hunting_Khaki", "Base.Vest_BulletCivilian" },
        { "Base.Trousers_Denim", "Base.Trousers_JeanBaggy" },
        { "Base.Socks_Heavy", "Base.Socks_Ankle" },
        { "Base.Shoes_ArmyBoots", "Base.Shoes_HikingBoots" },
        { "Base.Gloves_LeatherGlovesBlack", "Base.Gloves_LeatherGloves" },
        { "Base.Hat_BaseballCapGreen", "Base.Hat_BaseballCap" },
        { "Base.Belt2" },
        { "Base.HolsterSimple_Black", "Base.HolsterSimple" },
        { "Base.Kneepad_Left_Tactical" }, { "Base.Kneepad_Right_Tactical" },
        { "Base.WristWatch_Left_DigitalBlack" },
        { "Base.Glasses_Aviators" },
        { "Base.Bag_ALICEpack_Army", "Base.Bag_ALICEpack" },
        { "Base.Bag_ChestRig" },
        { "Base.Bag_FannyPackBack" },
        { "Base.Bag_Satchel_Leather", "Base.Bag_Satchel" },
    },
    belt = { { "Base.HuntingKnife" }, { "Base.Hammer" } },
    holster = { "Base.Pistol" },
    back = { "Base.Shotgun", "Base.Axe" },
    bags = {
        -- the backpack: the stock for the shelves
        back = { "Base.Pop", "Base.Pop", "Base.Pop2", "Base.Pop3", "Base.Crisps", "Base.Crisps2", "Base.Crisps3", "Base.Chocolate",
                 "Base.CandyPackage", "Base.MintCandy", "Base.Gum", "Base.CigaretteCarton", "Base.WaterBottle" },
        webbing = { "Base.Bandage", "Base.Disinfectant", "Base.Bullets9mmBox" },
        fannypackback = { "Base.Lighter", "Base.Pencil" },
        satchel = { "Base.Notebook", "Base.Peanuts" },
    },
    -- main inventory: the tools and props of the beats
    loose = { "Base.Plank", "Base.Plank", "Base.Plank", "Base.Nails", "Base.Nails", "Base.Nails", "Base.Nails", "Base.Nails", "Base.Nails",
              "Base.Hammer", "Base.Bleach", "Base.DishCloth", "Base.Jack", "Base.LugWrench", "Base.PetrolCan",
              "Base.CigarettePack", "Base.CigaretteSingle", "Base.CigaretteSingle", "Base.Lighter" },
}
ST.PROF = "MECHANICS"
ST.TRAITS = { "SMOKER", "SPEED_DEMON", "STRONG", "DEXTROUS", "FAST_READER", "PRONE_TO_ILLNESS", "HEARTY_APPETITE", "SLOW_HEALER", "PACIFIST" }
-- levels (from the real boosts: Fitness and Strength start at 5, Strong +4, Mechanics prof 4 and 1) + part-way progress
ST.SKILLS = { { "Strength", 9, 0.2 }, { "Fitness", 5, 0.55 }, { "Mechanics", 4, 0.45 }, { "MetalWelding", 1, 0.3 } }
ST.BOOSTS = { Strength = 3, Mechanics = 3, MetalWelding = 1 }

function ST.putAside(say)
    local R = ST.R
    R.prim, R.sec = p:getPrimaryHandItem(), p:getSecondaryHandItem()
    R.hot = {}
    local hb = getPlayerHotbar and getPlayerHotbar(ST.pn)
    if hb then
        for i, it in pairs(hb.attachedItems or {}) do R.hot[#R.hot + 1] = { i = i, it = it } end
        for _, h in ipairs(R.hot) do pcall(function() hb:removeItem(h.it, false) end) end
    end
    R.worn = {}
    pcall(function()
        local wi = p:getWornItems()
        for i = 0, wi:size() - 1 do R.worn[#R.worn + 1] = { it = wi:get(i):getItem(), loc = wi:get(i):getLocation() } end
    end)
    pcall(function() p:setPrimaryHandItem(nil); p:setSecondaryHandItem(nil) end)
    for _, w in ipairs(R.worn) do pcall(function() p:removeWornItem(w.it, false) end) end
    R.items = {}
    local items = ST.inv:getItems()
    for i = 0, items:size() - 1 do R.items[#R.items + 1] = items:get(i) end
    for _, it in ipairs(R.items) do pcall(function() ST.inv:Remove(it) end) end
    R.aside = true
    pcall(function() triggerEvent("OnClothingUpdated", p) end)
    say(string.format("aside: %d worn, %d on the belt, %d items", #R.worn, #R.hot, #R.items))
end
function ST.locOf(it)
    local loc = nil
    pcall(function()
        local ce = it:canBeEquipped()
        if instanceof(it, "InventoryContainer") and ce and ce ~= "" then loc = ce else loc = it:getBodyLocation() end
    end)
    return loc
end
function ST.wearOne(cands)
    for _, ft in ipairs(cands) do
        local it = ST.add(ft)
        if it then
            local loc = ST.locOf(it)
            local busy = true
            if loc and loc ~= "" then pcall(function() busy = p:getWornItem(loc) ~= nil end) end
            if not busy then
                local ok = pcall(function() p:setWornItem(loc, it) end)
                local on = false
                pcall(function() on = p:getWornItem(loc) == it end)
                if ok and on then ST.A.worn[#ST.A.worn + 1] = it; return it end
            end
            ST.inv:Remove(it)
        end
    end
    return nil
end
function ST.attach(cands, want)
    local hb = getPlayerHotbar and getPlayerHotbar(ST.pn)
    if not hb then return nil end
    pcall(function() hb:refresh() end)
    for _, ft in ipairs(cands) do
        local it = ST.add(ft)
        if it then
            for i, slot in ipairs(hb.availableSlot or {}) do
                if not hb.attachedItems[i] then
                    local att = nil
                    pcall(function() att = slot.def.attachments[it:getAttachmentType()] end)
                    local typ = tostring(slot.def and slot.def.type or ""):lower()
                    local kind = (typ:find("back", 1, true) and "back") or (typ:find("holster", 1, true) and "holster") or "belt"
                    if att and kind == want then
                        local ok = pcall(function() hb:attachItem(it, att, i, slot.def, false) end)
                        if ok and hb.attachedItems[i] == it then return it, typ end
                    end
                end
            end
            ST.inv:Remove(it)
        end
    end
    return nil
end
function ST.fill(container, list)
    local n = 0
    for _, ft in ipairs(list) do if ST.add(ft, container) then n = n + 1 end end
    return n
end
function ST.dress(say)
    local K = ST.KIT
    local worn, miss = {}, {}
    for _, c in ipairs(K.wear) do
        local it = ST.wearOne(c)
        if it then worn[#worn + 1] = it:getFullType():gsub("^Base%.", "") else miss[#miss + 1] = c[1] end
    end
    pcall(function() triggerEvent("OnClothingUpdated", p) end)
    say("worn: " .. table.concat(worn, " "))
    if #miss > 0 then say("note: not worn: " .. table.concat(miss, " ")) end
    ST.bags = {}
    for _, it in ipairs(ST.A.worn) do
        if instanceof(it, "InventoryContainer") then
            local loc = tostring(ST.locOf(it)):lower():gsub("^.*:", "")
            for key, list in pairs(K.bags) do
                if loc == key then
                    ST.bags[key] = it
                    say("bag " .. key .. " (" .. it:getFullType() .. "): " .. ST.fill(it:getInventory(), list) .. " things")
                end
            end
        end
    end
    local n = ST.fill(ST.inv, K.loose)
    say("loose: " .. n .. "/" .. #K.loose)
    -- the gas can empty (it is filled at the pump), the bleach full
    pcall(function() ST.find("Base.PetrolCan"):getFluidContainer():Empty() end)
    local got = {}
    for _, b in ipairs(K.belt) do
        local it, typ = ST.attach(b, "belt")
        got[#got + 1] = it and (it:getType() .. "@" .. tostring(typ)) or ("none:" .. b[1])
    end
    local h, ht = ST.attach(K.holster, "holster")
    got[#got + 1] = h and (h:getType() .. "@" .. tostring(ht)) or "holster:none"
    local bk, bt = ST.attach(K.back, "back")
    got[#got + 1] = bk and (bk:getType() .. "@" .. tostring(bt)) or "back:none"
    say("belt: " .. table.concat(got, " "))
end
-- the flyer: a real Base.Flier carrying the Fossoil print media (vanilla's modData shape)
function ST.flyer()
    local id = ST.site.flyer
    local f = ST.add("Base.Flier")
    if not f then return nil end
    local md = f:getModData()
    md.printMedia = { id = string.lower(id), title = "Print_Media_" .. id .. "_title", info = "Print_Media_" .. id .. "_info", text = "Print_Text_" .. id .. "_info" }
    md.literatureTitle = md.printMedia.title
    pcall(function() f:setName(getText("IGUI_Newspaper_Name", f:getDisplayName(), getText(md.printMedia.title))) end)
    ST.flyerItem = f
    return f
end

-- profession, traits, skills: kept to put back, then the story's
function ST.perkList()
    local out = {}
    pcall(function()
        for i = 0, PerkFactory.PerkList:size() - 1 do out[#out + 1] = PerkFactory.PerkList:get(i) end
    end)
    return out
end
function ST.snapCharacter(say)
    local R = ST.R
    local desc = p:getDescriptor()
    R.prof = desc:getCharacterProfession()
    R.descBoost = {}
    -- (a Java Set cannot be iterated from Kahlua: the map through transformIntoKahluaTable,
    -- the traits through the definitions list)
    pcall(function()
        for k, v in pairs(transformIntoKahluaTable(desc:getXPBoostMap())) do R.descBoost[#R.descBoost + 1] = { k, v } end
    end)
    R.traits = {}
    pcall(function()
        local ct = p:getCharacterTraits()
        local defs = CharacterTraitDefinition.getTraits()
        for i = 0, defs:size() - 1 do
            local t = defs:get(i):getType()
            R.traits[#R.traits + 1] = { t, ct:get(t) }
        end
    end)
    R.perks = {}
    local xp = p:getXp()
    for _, perk in ipairs(ST.perkList()) do
        pcall(function() R.perks[#R.perks + 1] = { perk = perk, lvl = p:getPerkLevel(perk), xp = xp:getXP(perk), boost = xp:getPerkBoost(perk) } end)
    end
    R.stats = {}
    for _, k in ipairs({ "STRESS", "UNHAPPINESS", "NICOTINE_WITHDRAWAL", "HUNGER", "THIRST", "FOOD_SICKNESS", "BOREDOM", "FATIGUE", "ENDURANCE", "PANIC" }) do
        pcall(function() local cs = CharacterStat[k]; R.stats[#R.stats + 1] = { cs, p:getStats():get(cs) } end)
    end
    pcall(function() R.lastSmoke = p:getTimeSinceLastSmoke() end)
    local on = 0
    for _, t in ipairs(R.traits) do if t[2] then on = on + 1 end end
    say(string.format("character was: profession %s, %d traits on, %d perks kept", tostring(R.prof), on, #R.perks))
end
function ST.makeCharacter(say)
    local desc = p:getDescriptor()
    local prof = CharacterProfession[ST.PROF]
    local def = CharacterProfessionDefinition.getCharacterProfessionDefinition(prof)
    desc:setCharacterProfession(prof)
    pcall(function() desc:getXPBoostMap():clear() end)
    desc:setProfessionSkills(def)
    -- every trait off, then the profession's granted ones and the story's
    local ct = p:getCharacterTraits()
    for _, t in ipairs(ST.R.traits) do pcall(function() ct:set(t[1], false) end) end
    local names = {}
    pcall(function()
        local g = def:getGrantedTraits()
        for i = 0, g:size() - 1 do ct:add(g:get(i)); names[#names + 1] = tostring(g:get(i)) end
    end)
    for _, k in ipairs(ST.TRAITS) do
        local t = CharacterTrait[k]
        if t then ct:add(t); names[#names + 1] = k else say("ERR no CharacterTrait." .. k) end
    end
    -- skills: every perk to 0 (Fitness and Strength to 5), then the story's levels and progress
    local xp = p:getXp()
    for _, perk in ipairs(ST.perkList()) do
        pcall(function()
            local base = (perk == Perks.Fitness or perk == Perks.Strength) and 5 or 0
            p:setPerkLevelDebug(perk, base)
            xp:setXPToLevel(perk, base)
            xp:setPerkBoost(perk, 0)
        end)
    end
    local lv = {}
    for _, s in ipairs(ST.SKILLS) do
        local perk = Perks[s[1]]
        local ok = perk and pcall(function()
            p:setPerkLevelDebug(perk, s[2])
            xp:setXPToLevel(perk, s[2])
            local pk = PerkFactory.getPerk(perk)
            local span = pk:getTotalXpForLevel(s[2] + 1) - pk:getTotalXpForLevel(s[2])
            xp:AddXPNoMultiplier(perk, span * s[3])
        end)
        lv[#lv + 1] = s[1] .. "=" .. tostring(p:getPerkLevel(perk)) .. (ok and "" or "(ERR)")
    end
    for name, b in pairs(ST.BOOSTS) do pcall(function() xp:setPerkBoost(Perks[name], b) end) end
    pcall(function() SyncXp(p) end)
    say("profession " .. tostring(desc:getCharacterProfession()) .. " | traits " .. table.concat(names, " ") .. " | skills " .. table.concat(lv, " "))
end

-- ===========================================================================
-- THE WORLD: power, pump, car, zombies, seeds
-- ===========================================================================
function ST.sandbox(name, value)
    local so = getSandboxOptions()
    local o = so:getOptionByName(name)
    if not o then return false end
    ST.R.sandbox = ST.R.sandbox or {}
    if ST.R.sandbox[name] == nil then ST.R.sandbox[name] = o:getValue() end
    o:setValue(value)
    pcall(function() so:toLua() end)
    return true
end
function ST.power(say)
    local ok = ST.sandbox("ElecShutModifier", 99999)
    local P = ST.P
    local sq = P.pump and ST.sqAt(P.pump.x, P.pump.y)
    local gp, np = false, false
    pcall(function() gp = sq:hasGridPower() end)
    pcall(function() np = sq:isNoPower() end)
    say(string.format("power: option set %s | pump square grid power %s, no-power zone %s", tostring(ok), tostring(gp), tostring(np)))
end
-- every pump square: its raw modData fuel kept (nil = never read), then 500 units
function ST.fuelPumps(say)
    local n = 0
    for _, e in ipairs(ST.F.pumps) do
        local raw = nil
        pcall(function() raw = e.o:getModData().fuelAmount end)
        ST.A.pumps[#ST.A.pumps + 1] = { o = e.o, raw = raw }
        if pcall(function() e.o:setPipedFuelAmount(500) end) then n = n + 1 end
    end
    local now = -1
    pcall(function() now = ST.P.pump.o:getPipedFuelAmount() end)
    say("pumps filled: " .. n .. " | the pump reads " .. tostring(now))
end
function ST.spawnCar(script, dir, x, y)
    local sq = ST.sqAt(x, y)
    if not sq then return nil end
    local ok, v = pcall(addVehicleDebug, script, dir, 0, sq)
    if ok and v then ST.A.cars[#ST.A.cars + 1] = v; return v end
    return nil
end
function ST.removeCar(v)
    for i, c in ipairs(ST.A.cars) do if c == v then table.remove(ST.A.cars, i); break end end
    pcall(function() v:permanentlyRemove() end)
end
-- car placements to try round the pump: the long side beside the pump island
function ST.carCandidates()
    -- every pump, the nearest to the store first; the car beside it lengthwise, its body's line
    -- (5 squares) and the squares either side of its middle clear (the pump islands' kerbs and
    -- the canopy posts leave no 7 x 3 box free)
    local P = ST.P
    local out, pumps = {}, {}
    for _, e in ipairs(ST.F.pumps) do pumps[#pumps + 1] = e end
    local c = P.centre
    table.sort(pumps, function(u, v) return math.abs(u.x - c[1]) + math.abs(u.y - c[2]) < math.abs(v.x - c[1]) + math.abs(v.y - c[2]) end)
    local seen = {}
    for _, e in ipairs(pumps) do
        for _, o in ipairs({ { 0, 2, "E" }, { 0, -2, "E" }, { 0, 2, "W" }, { 0, -2, "W" }, { 2, 0, "N" }, { -2, 0, "N" }, { 2, 0, "S" }, { -2, 0, "S" },
                             { 1, 2, "E" }, { -1, 2, "W" }, { 2, 1, "N" }, { 2, -1, "S" }, { 0, 3, "E" }, { 3, 0, "N" }, { 0, -3, "W" }, { -3, 0, "S" } }) do
            local x, y, d = e.x + o[1], e.y + o[2], o[3]
            local k = x .. "," .. y .. d
            local clear = not seen[k]
            seen[k] = true
            local cells = { { -2, 0 }, { -1, 0 }, { 0, 0 }, { 1, 0 }, { 2, 0 }, { 0, -1 }, { 0, 1 } }
            for _, q in ipairs(cells) do
                local qx, qy = x + q[1], y + q[2]
                if d == "N" or d == "S" then qx, qy = x + q[2], y + q[1] end
                local sq = ST.sqAt(qx, qy)
                if not (sq and ST.free(sq)) then clear = false end
            end
            if clear then out[#out + 1] = { x = x, y = y, dir = d } end
        end
    end
    return out
end
-- native zombies near the store: made useless (put back by the teardown)
function ST.calmNatives(say)
    local n = 0
    pcall(function()
        local l = getCell():getZombieList()
        for i = 0, l:size() - 1 do
            local z = l:get(i)
            if math.abs(z:getX() - ST.P.centre[1]) < 60 and math.abs(z:getY() - ST.P.centre[2]) < 60 then
                ST.A.native[#ST.A.native + 1] = { z = z, was = z:isUseless() }
                z:setUseless(true)
                n = n + 1
            end
        end
    end)
    say("native zombies near the store made useless: " .. n)
end
function ST.zombie(x, y, fx, fy, outfit)
    local z = nil
    pcall(function()
        local l = addZombiesInOutfit(x, y, 0, 1, outfit, 50)
        if l and l:size() > 0 then z = l:get(0) end
    end)
    if not z then return nil end
    pcall(function() z:setUseless(true) end)
    pcall(function() z:clearAggroList() end)
    pcall(function() z:faceLocation(fx or x, fy or y) end)
    return z
end
function ST.removeZombie(z)
    pcall(function() z:removeFromWorld() end)
    pcall(function() z:removeFromSquare() end)
end
-- passive zombies round the forecourt (8-18 squares out)
function ST.outsideZombies(say)
    local c = ST.P.centre
    local spots = { { -12, -6 }, { -9, 10 }, { 12, -9 }, { 14, 6 }, { -16, 2 }, { 4, 15 }, { 9, 13 } }
    for _, o in ipairs(spots) do
        local q = ST.outNear(c[1] + o[1], c[2] + o[2], 4)
        if q then
            local z = ST.zombie(q[1], q[2], c[1], c[2])
            if z then ST.A.zombies[#ST.A.zombies + 1] = z end
        end
    end
    say("passive zombies outside: " .. #ST.A.zombies)
end
-- the customer queue in front of the counter (beat 10)
function ST.queueZombies(on)
    for _, z in ipairs(ST.A.queue) do ST.removeZombie(z) end
    ST.A.queue = {}
    if not on then return 0 end
    local P = ST.P
    for k = 1, 3 do
        local x, y = P.counter[1] + P.queueDir[1] * k, P.counter[2] + P.queueDir[2] * k
        if ST.free(ST.sqAt(x, y)) then
            local z = ST.zombie(x, y, P.counter[1], P.counter[2])
            if z then ST.A.queue[#ST.A.queue + 1] = z end
        end
    end
    return #ST.A.queue
end
-- blood on the floor: only squares with none before (the teardown cleans exactly these)
function ST.blood(say)
    local b = ST.P.blood
    local n = 0
    for _, o in ipairs({ { 0, 0 }, { 1, 0 }, { 0, 1 } }) do
        local sq = ST.sqAt(b[1] + o[1], b[2] + o[2])
        local had = true
        pcall(function() had = sq:haveBlood() or sq:haveStains() end)
        if sq and not had and ST.inRoom(b[1] + o[1], b[2] + o[2]) then
            pcall(function() addBloodSplat(sq, 18) end)
            ST.A.blood[#ST.A.blood + 1] = sq
            n = n + 1
        end
    end
    local seen = false
    pcall(function() seen = ST.sqAt(b[1], b[2]):haveStains() end)
    local opt = -1
    pcall(function() opt = getCore():getOptionBloodDecals() end)
    say(string.format("blood on %d squares | stains read back %s | blood decals option %s", n, tostring(seen), tostring(opt)))
end
-- the store's lights (night): switches in the building's rooms, the ones off before kept
function ST.lights(on)
    local n = 0
    if on then
        pcall(function()
            local rooms = ST.sqAt(ST.P.centre[1], ST.P.centre[2]):getBuilding():getDef():getRooms()
            for i = 0, rooms:size() - 1 do
                local r = rooms:get(i):getIsoRoom()
                local ls = r and r:getLightSwitches()
                for j = 0, (ls and ls:size() or 0) - 1 do
                    local sw = ls:get(j)
                    if not sw:isActivated() then
                        if pcall(function() sw:setActive(true) end) and sw:isActivated() then ST.A.lights[#ST.A.lights + 1] = sw; n = n + 1 end
                    end
                end
            end
        end)
    else
        for _, sw in ipairs(ST.A.lights) do if pcall(function() sw:setActive(false) end) then n = n + 1 end end
        ST.A.lights = {}
    end
    return n
end
-- seeds: the flyer read, the journal entry, the map note and star at the store
function ST.seed(say)
    local R = ST.R
    local id = string.lower(ST.site.flyer)
    R.flyerWasRead = p:isPrintMediaRead(id)
    if not R.flyerWasRead then p:addReadPrintMedia(id) end
    local cw = ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow()
    if cw and ZeD.JournalReaders and ZeD.JournalReaders.addLogEntry then
        ZeD.JournalReaders.addLogEntry(cw, ST.JOURNAL, nil)
        R.journal = true
    else
        say("ERR no Character window for the journal entry")
    end
    local c = ST.P.centre
    if ZeD.MapNotes then
        R.note = ZeD.MapNotes.addNote(ST.NOTE, c[1] + 0.5, c[2] - 6, 4)
        R.star = ZeD.MapNotes.addSymbol("Star", c[1] + 0.5, c[2] + 0.5, 4)
    end
    say(string.format("seeds: flyer %s read (was %s) | journal %s | note %s star %s", id, tostring(R.flyerWasRead),
        tostring(R.journal), tostring(R.note ~= nil), tostring(R.star ~= nil)))
end
-- ZeD's options and theme kept (in memory changes only; the teardown puts these back)
function ST.snapZeD()
    local R = ST.R
    R.zed = { base = ZeD.currentBase, accent = ZeD.currentAccent, size = ZeD.currentSize, opts = {} }
    pcall(function()
        local d = PZAPI.ModOptions:getOptions("ZeD_UI").dict
        for _, id in ipairs({ "baseTheme", "accentColor", "textSize", "charAccent", "worldAccent", "contextStyle", "actionBar",
                              "watchPlace", "moodlePlace", "inventoryView", "equipView" }) do
            if d[id] then R.zed.opts[id] = d[id]:getValue() end
        end
    end)
    pcall(function() R.zed.mapStyle = p:getModData().ZeD_MapStyle end)
    pcall(function() R.zed.cAcc = ZeD_CharacterWindow.getWindow()._accentKey end)
    pcall(function() R.zed.wAcc = ZeD_WorldWindow.getWindow()._accentKey end)
end

-- ===========================================================================
-- THE STAGE
-- ===========================================================================
local S = ST.newSeq("sts", 420000)
local say = S.say
local C = { tour = {}, ti = 0, cands = nil, ci = 0, car = nil, t0 = 0 }
S.step(2, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    ST.saveWas()
    ST.cleanLook()
    ST.parkMouse()
    ST.day(10.0)
    if ZeD then ST.snapZeD() end
    say(string.format("start at %d,%d | site: %s | ZeD %s", math.floor(p:getX()), math.floor(p:getY()), ST.site.name, tostring(ZeD ~= nil)))
    local s = ST.site
    ST.tp(math.floor((s.x0 + s.x1) / 2) + 0.5, math.floor((s.y0 + s.y1) / 2) + 0.5, 0)
    C.t0 = getTimestampMs()
end)
-- the cell loaded, then 9 s more
S.poll(5, 6000, function()
    local s = ST.site
    return ST.sqAt(s.x0, s.y0) ~= nil and ST.sqAt(s.x1, s.y1) ~= nil and getTimestampMs() - C.t0 > 9000
end, function() say("ERR the store's squares did not load") end)
S.step(2, function()
    local s = ST.site
    local sq = ST.sqAt(math.floor((s.x0 + s.x1) / 2), math.floor((s.y0 + s.y1) / 2))
    local room, bld = "?", false
    pcall(function() room = tostring(sq:getRoom():getName()) end)
    pcall(function() bld = sq:getBuilding() ~= nil end)
    say(string.format("at the store: room %s, building %s", room, tostring(bld)))
    ST.scan()
    ST.plan(say)
end)
-- a tour round the store so the squares have been seen (unseen squares draw black)
S.step(2, function()
    local c = ST.P.centre
    for _, d in ipairs({ 9, 18 }) do
        for _, o in ipairs({ { 0, -1 }, { 1, -1 }, { 1, 0 }, { 1, 1 }, { 0, 1 }, { -1, 1 }, { -1, 0 }, { -1, -1 } }) do
            C.tour[#C.tour + 1] = { c[1] + o[1] * d, c[2] + o[2] * d }
        end
    end
    C.tour[#C.tour + 1] = c
end)
S.poll(2, 4000, function()
    if not C.cur then
        C.ti = C.ti + 1
        local t = C.tour[C.ti]
        if not t then return true end
        local q = ST.outNear(t[1], t[2], 6) or t
        ST.tpSq(q)
        C.cur, C.dirI, C.wait = q, 0, 6
        return false
    end
    C.wait = C.wait - 1
    if C.wait > 0 then return false end
    C.dirI = C.dirI + 1
    local dirs = { "N", "NE", "E", "SE", "S", "SW", "W", "NW" }
    if C.dirI > #dirs then C.cur = nil; return false end
    pcall(function() p:setDir(IsoDirections[dirs[C.dirI]]) end)
    C.wait = 4
    return false
end)
S.step(2, function()
    ST.tpSq(ST.P.centre)
    ST.putAside(say)
end)
S.step(10, function() ST.dress(say); ST.flyer() end)
S.step(10, function() ST.snapCharacter(say); ST.makeCharacter(say) end)
S.step(10, function() ST.power(say); ST.fuelPumps(say) end)
-- the car beside the pump: try placements until vanilla's own pump finder sees the pump from the gas tank
S.step(5, function() C.cands = ST.carCandidates(); say("car placements to try: " .. #C.cands) end)
S.poll(5, 3000, function()
    if C.car then
        C.wait = C.wait - 1
        if C.wait > 0 then return false end
        local v, pump = C.car, nil
        pcall(function() pump = ISVehiclePartMenu.getNearbyFuelPump(v) end)
        local inArea = false
        local tank = v:getPartById("GasTank")
        local ac = nil
        pcall(function() ac = v:getAreaCenter(tank:getArea()) end)
        local acFree = ac and ST.free(ST.sqAt(math.floor(ac:getX()), math.floor(ac:getY())))
        if pump and acFree then
            ST.car = v
            say(string.format("car %s at %d,%d facing %s: the pump finder sees %d,%d | tank area %.1f,%.1f", v:getScriptName(),
                math.floor(v:getX()), math.floor(v:getY()), C.cand.dir, pump:getSquare():getX(), pump:getSquare():getY(), ac:getX(), ac:getY()))
            return true
        end
        say(string.format("note: placement %d (%d,%d %s) no good: pump %s, tank area free %s", C.ci, C.cand.x, C.cand.y, C.cand.dir, tostring(pump ~= nil), tostring(acFree)))
        ST.removeCar(v)
        C.car = nil
        return false
    end
    C.ci = C.ci + 1
    C.cand = C.cands and C.cands[C.ci]
    if not C.cand then return true end
    C.car = ST.spawnCar("Base.CarStationWagon", IsoDirections[C.cand.dir], C.cand.x, C.cand.y) or ST.spawnCar("Base.CarNormal", IsoDirections[C.cand.dir], C.cand.x, C.cand.y)
    C.wait = 40
    return false
end)
S.step(5, function()
    local v = ST.car
    if not v then
        say("ERR no car placement reached the pump: the car goes on the first clear square near the pump")
        local q = ST.P.pump and ST.outNear(ST.P.pump.x, ST.P.pump.y + 3, 6)
        if q then ST.car = ST.spawnCar("Base.CarStationWagon", IsoDirections.E, q[1], q[2]) end
        v = ST.car
        if not v then return end
    end
    pcall(function() v:repair() end)
    pcall(function() local g = v:getPartById("GasTank"); g:setContainerContentAmount(g:getContainerCapacity() * 0.06); v:transmitPartModData(g) end)
    pcall(function() ST.carKey = ST.inv:AddItem(v:createVehicleKey()) end)
    local g = v:getPartById("GasTank")
    say(string.format("car fuel %.1f / %.1f", g:getContainerContentAmount(), g:getContainerCapacity()))
end)
S.step(5, function() ST.calmNatives(say); ST.outsideZombies(say); ST.blood(say) end)
S.step(5, function() if ZeD then ST.seed(say) end end)
S.step(30, function()
    ST.tpSq(ST.P.smoke)
    ST.face("SE")
    if ZeD_CharacterWindow and ZeD_CharacterWindow.isOpen() and ZeD_WorldWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end
end)
S.zoomTo(1.5)
S.step(40, function() ST.face("SE"); S.shot("story_00_scout") end)
S.step(2, function()
    ST.ready = true
    say(string.format("staged: car %s | zombies %d outside | blood %d | carried %d", tostring(ST.car ~= nil), #ST.A.zombies, #ST.A.blood, ST.inv:getItems():size()))
end)
S.start()
