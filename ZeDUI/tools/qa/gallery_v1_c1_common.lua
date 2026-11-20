-- ZeDUI/tools/qa/gallery_v1_c1_common.lua  (Nov 17 2026, QA): shared helpers for the ZeD-GUI 1.0 gallery's "lived-in"
-- retakes, set c1 (the director, Nov 17: retake each chapter somewhere lived-in, in West Point near the Fossoil; the
-- window to one side or along the top, the character and the place uncovered beside it). Chapters 11, 18, 19, 20, 22,
-- 24, 27, 29, 30 and 31, under today's file names. Runs in BOTH runs (gallery_v1_c1_zed.txt with ZeD on,
-- gallery_v1_c1_van.txt with ZeD off): it never calls ZeD unless ZeD is loaded. Run after gallery_unload.lua.
-- Defines the global C1:
--   C1.make(tag)          a step queue on Events.OnPreUIDraw: Q.step(n, fn), Q.waitFor(n, max, cond, fn),
--                         Q.still(n, fn) (every window the same for 30 frames, C1.hold run every frame first),
--                         Q.zoomTo(z), Q.shot(name [, how]), Q.notTaken(name, why), Q.start() (ends "DONE");
--                         say lines "ZEDQA <tag> ..."
--   Q.shot(name, how)     the gallery rule first (invisible off, god mode off, zombies-don't-attack on, the debug
--                         console hidden, menus closed unless how.keepMenu, the pointer parked and hidden unless
--                         how.pointer; how.stay hides it without moving it), the weight check (not taken over the character's limit), the picture
--                         (Zomboid/Screenshots/<name>.png), then the load line and every visible window's box
--   C1.go(Q, key)         the character to a place (C1.PLACES), the world loaded round it, a free square there
--                         with room to stand, facing the camera; zombies within 30 squares taken out of the world
--                         (counted in the log; the QA save only)
--   C1.side(Q, list)      windows to one side: each { label, win, side } goes to the left or right edge (or "top")
--   C1.pairSide()         ZeD's two windows: both on the left when they fit beside the character, else the
--                         Character window on the left edge and the World window on the right edge
--   C1.hold               a function run every frame by the queue (keeps a window where C1.side put it)
--   C1.grid(on)           the grid power on (indoor places lit) and back
-- The places (read from the map's lot headers 46_26 to 47_28, Muldraugh, KY; level 0 rooms):
--   kitchen   the house at 12021-12033, 7078-7090: kitchen 12028-12030 x 7078-7082 beside the living room
--             12023-12032 x 7078-7088 (two bedrooms, a bathroom); about 50 squares north west of the Fossoil
--   living    the same house's living room
--   street    West Point's main street, on the walk outside the cafe (11958-11970 x 6872-6890), the post office,
--             the tool store and the grocery across the road (fronts on y 6908)
--   grocery   inside the grocery on the main street (11979-11991 x 6909-6926)
-- C1.was (the place, the grid power, the cheats, the zoom) is saved here once and put back by gallery_v1_c1_end.lua.
-- ASCII only; no next(); state kept in C1 and each queue's table. grep "ZEDQA c1c".
C1 = C1 or {}
C1.p = getPlayer()
C1.pn = C1.p:getPlayerNum()
C1.core = getCore()
C1.zed = (ZeD and ZeD_CharacterWindow and ZeD_WorldWindow) and true or false
function C1.log(s) print("ZEDQA c1c " .. tostring(s)) end

C1.PLACES = {
    kitchen = { name = "the kitchen of the house at 12021-12033,7078-7090 (West Point)", ax = 12029, ay = 7080, room = "kitchen", r = 6, dir = "SE" },
    living = { name = "the living room of the house at 12021-12033,7078-7090 (West Point)", ax = 12026, ay = 7081, room = "livingroom", r = 8, dir = "SE" },
    street = { name = "West Point's main street, outside the cafe, the shops across the road", ax = 11966, ay = 6895, outdoor = true, r = 10, dir = "SE" },
    grocery = { name = "inside the grocery on West Point's main street", ax = 11985, ay = 6913, room = "grocery", r = 8, dir = "SE" },
}

-- ===================================================================== what is put back at the end (gallery_v1_c1_end.lua)
if not C1.was then
    C1.was = { x = C1.p:getX(), y = C1.p:getY(), z = C1.p:getZ(), speed = getGameSpeed() }
    pcall(function() C1.was.dir = C1.p:getDir() end)
    pcall(function() C1.was.inv = C1.p:isInvisible() end)
    pcall(function() C1.was.god = C1.p:isGodMod() end)
    pcall(function() C1.was.zda = C1.p:isZombiesDontAttack() end)
    pcall(function() C1.was.zoom = C1.core:getZoom(C1.pn) end)
    pcall(function() C1.was.hydro = getWorld():isHydroPowerOn() end)
end

-- ===================================================================== the queue
function C1.make(tag)
    local Q = { tag = tag, list = {}, qi = 1, wait = nil, nOk = 0, nErr = 0, t0 = getTimestampMs(), maxMs = 1500000 }
    function Q.say(s) print("ZEDQA " .. Q.tag .. " " .. tostring(s)) end
    function Q.step(n, fn) Q.list[#Q.list + 1] = { n = n, fn = fn } end
    -- after n frames, every frame until cond() (at most max frames), then fn(ok)
    function Q.waitFor(n, max, cond, fn) Q.list[#Q.list + 1] = { n = n, fn = fn, cond = cond, max = max } end
    function Q.still(n, fn)
        local st = { last = nil, same = 0 }
        Q.waitFor(n, 900, function()
            local s = C1.shape()
            if s == st.last then st.same = st.same + 1 else st.last, st.same = s, 0 end
            return st.same >= 30
        end, fn)
    end
    function Q.zoomTo(z)
        local st = { left = nil }
        Q.step(40, function() end)
        Q.waitFor(20, 1200, function()
            if st.left == nil then st.left = math.floor((C1.core:getZoom(C1.pn) - z) / 0.25 + 0.5) end
            if st.left == 0 then return true end
            C1.core:doZoomScroll(C1.pn, (st.left > 0) and -1 or 1)
            st.left = (st.left > 0) and (st.left - 1) or (st.left + 1)
            return st.left == 0
        end, function() end)
        Q.step(100, function() Q.say("zoom " .. tostring(C1.core:getZoom(C1.pn))) end)
    end
    -- how: { keepMenu = true } the picture is the menu; { pointer = true } the hover is the point (pointer shown)
    function Q.shot(name, how)
        how = how or {}
        C1.rule()
        if not how.keepMenu then C1.closeMenus() end
        -- how.stay: hidden where it is, not moved (a pointer move turns the controller's focus cues off)
        if how.pointer then C1.pointerShown(true)
        elseif how.stay then pcall(function() Mouse.setCursorVisible(false) end)
        else C1.pointerHidden() end
        local load = (GAL_UNLOAD and GAL_UNLOAD.line) and GAL_UNLOAD.line() or "(gallery_unload.lua did not run)"
        if C1.over() then
            Q.notTaken(name, "over the character's weight limit: " .. load)
            if how.pointer then C1.pointerShown(false) end
            return
        end
        local ok, e = pcall(function() C1.core:TakeFullScreenshot(name .. ".png") end)
        if ok then Q.nOk = Q.nOk + 1; Q.say("shot " .. name .. " at " .. tostring(C1.here)) else Q.nErr = Q.nErr + 1; Q.say("ERR shot " .. name .. ": " .. tostring(e)) end
        Q.say("load " .. name .. ": " .. load)
        C1.boxes(Q, name)
        if how.pointer then C1.pointerShown(false) end
    end
    function Q.notTaken(name, why) Q.nErr = Q.nErr + 1; Q.say("not taken: " .. name .. " (" .. tostring(why) .. ")") end
    function Q.tick()
        if C1.hold then pcall(C1.hold) end
        local s = Q.list[Q.qi]
        if not s then Events.OnPreUIDraw.Remove(Q.tick); return end
        if Q.qi < #Q.list and Q.backAt and Q.qi < Q.backAt and getTimestampMs() - Q.t0 > Q.maxMs then
            Q.say("ERR ran too long at step " .. Q.qi .. ": jumping to the put-back")
            Q.qi, Q.wait = Q.backAt, nil
            return
        end
        if not s.started then
            Q.wait = (Q.wait or s.n) - 1
            if Q.wait > 0 then return end
            Q.wait = nil
            s.started = true
        end
        local res = true
        if s.cond then
            s.left = (s.left or s.max) - 1
            local okc, done = pcall(s.cond)
            res = (okc and done) and true or false
            if not res and s.left > 0 then return end
            if not res then Q.say("note: step " .. Q.qi .. " waited " .. s.max .. " frames, went on") end
        end
        Q.qi = Q.qi + 1
        local ok, err = pcall(s.fn, res)
        if not ok then Q.say("ERR step " .. (Q.qi - 1) .. ": " .. tostring(err)) end
    end
    -- the put-back starts here (a run that takes too long jumps to it)
    function Q.mark() Q.backAt = #Q.list + 1 end
    function Q.start()
        Q.step(2, function()
            C1.hold = nil
            Q.say(string.format("end: %d shots, %d not taken or failed", Q.nOk, Q.nErr))
            Q.say("DONE")
        end)
        Events.OnPreUIDraw.Add(Q.tick)
        Q.say("start (" .. #Q.list .. " steps)")
    end
    return Q
end

-- ===================================================================== the gallery rule
function C1.rule()
    pcall(function() C1.p:setInvisible(false) end)
    pcall(function() C1.p:setGodMod(false) end)
    pcall(function() C1.p:setZombiesDontAttack(true) end)
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do
            local e = ui:get(i)
            if e:getClass():getSimpleName() == "UIDebugConsole" and e:isVisible() then e:setVisible(false) end
        end
    end)
    pcall(function()
        local o = getDebugOptions()
        o:setBoolean("FBORenderChunk.RenderVisionPolygon", false)
        o:setBoolean("Terrain.RenderTiles.RenderContainerHighlight", false)
        o:setBoolean("Vehicle.Render.Area", false)
    end)
end
function C1.closeMenus()
    pcall(function() local m = getPlayerContextMenu(C1.pn); if m and m._zedMenu then m._zedMenu:close() end end)
    pcall(function() local m = getPlayerContextMenu(C1.pn); if m and m:isVisible() then m:closeAll() end end)
end
-- the pointer parked where no UI element covers it (gallery_unload.lua's park), and hidden
function C1.pointerHidden()
    if GAL_UNLOAD and GAL_UNLOAD.park then pcall(GAL_UNLOAD.park)
    else pcall(function() Mouse.setXY(4, C1.core:getScreenHeight() - 4) end) end
    pcall(function() Mouse.setCursorVisible(false) end)
end
-- the pointer shown for a hover picture: gallery_unload.lua's every-frame hide is paused, then put back
function C1.pointerShown(on)
    local U = GAL_UNLOAD
    if on then
        if U and U.watch and U.watching then Events.OnPreUIDraw.Remove(U.watch); C1.watchPaused = true end
        pcall(function() Mouse.setCursorVisible(true) end)
        return
    end
    if C1.watchPaused and U and U.watch and U.watching then Events.OnPreUIDraw.Add(U.watch) end
    C1.watchPaused = nil
    pcall(function() Mouse.setCursorVisible(false) end)
end
-- the character's load over its limit (every container shown within its limit: the character's inventory is the one
-- that gallery_unload.lua trims; the bags worn are kept by the game within theirs)
function C1.over()
    local U = GAL_UNLOAD
    local w = (U and U.weight) and U.weight() or nil
    if not w then pcall(function() w = C1.p:getInventory():getCapacityWeight() end) end
    local max = 20
    pcall(function() max = C1.p:getMaxWeight() end)
    return (w or 0) > max
end

-- ===================================================================== the character on the screen, the boxes
-- a rect round the figure (zoom 1 at 4K: about 320 x 420 px, generous), as gallery_v1_a_common.lua's
function C1.charRect()
    local W, H = C1.core:getScreenWidth(), C1.core:getScreenHeight()
    local r = { x = W / 2, y = H / 2 }
    pcall(function()
        local sx = isoToScreenX(C1.pn, C1.p:getX(), C1.p:getY(), C1.p:getZ())
        local sy = isoToScreenY(C1.pn, C1.p:getX(), C1.p:getY(), C1.p:getZ())
        if sx and sy then r.x, r.y = sx, sy end
    end)
    local z = 1
    pcall(function() z = C1.core:getZoom(C1.pn) end)
    if not z or z <= 0 then z = 1 end
    r.x0, r.x1 = math.floor(r.x - 160 / z), math.floor(r.x + 160 / z)
    r.y0, r.y1 = math.floor(r.y - 360 / z), math.floor(r.y + 60 / z)
    return r
end
function C1.covers(x, y, w, h)
    local r = C1.charRect()
    return x < r.x1 and x + w > r.x0 and y < r.y1 and y + h > r.y0
end
function C1.box1(Q, name, label, e, W, H)
    local x, y, w, h = math.floor(e:getAbsoluteX()), math.floor(e:getAbsoluteY()), math.floor(e:getWidth()), math.floor(e:getHeight())
    local full = w >= W * 0.9 and h >= H * 0.9
    local note = ""
    if full then note = " (full-screen layer)" elseif C1.covers(x, y, w, h) then note = " COVERS the character" end
    Q.say(string.format("box %s %s %d,%d-%d,%d%s", name, tostring(label), x, y, x + w, y + h, note))
end
function C1.typeOf(e)
    local t = "?"
    pcall(function() t = e:getClass():getSimpleName() end)
    pcall(function() local tb = e:getTable(); if tb and tb.Type then t = tostring(tb.Type) end end)
    return t
end
-- every visible top-level UI element (8 px or more), then the extra windows named (children of a full-screen layer)
function C1.boxes(Q, name)
    local r = C1.charRect()
    local W, H = C1.core:getScreenWidth(), C1.core:getScreenHeight()
    Q.say(string.format("box %s character %d,%d-%d,%d (zoom %s)", name, r.x0, r.y0, r.x1, r.y1, tostring(C1.core:getZoom(C1.pn))))
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do
            local e = ui:get(i)
            if e:isVisible() and e:getWidth() >= 8 and e:getHeight() >= 8 and e:getClass():getSimpleName() ~= "UIDebugConsole" then
                C1.box1(Q, name, C1.typeOf(e), e, W, H)
            end
        end
    end)
    for _, x in ipairs(C1.extraBoxes or {}) do
        pcall(function() local w = x[2](); if w and w:isVisible() then C1.box1(Q, name, x[1], w, W, H) end end)
    end
end
-- what Q.still compares: the ZeD pair, the vanilla pages, the extra windows
function C1.shape()
    local t = {}
    local list = {}
    if C1.zed then
        list[#list + 1] = ZeD_CharacterWindow.getWindow()
        list[#list + 1] = ZeD_WorldWindow.getWindow()
    end
    pcall(function() list[#list + 1] = getPlayerInventory(C1.pn) end)
    pcall(function() list[#list + 1] = getPlayerLoot(C1.pn) end)
    for _, x in ipairs(C1.extraBoxes or {}) do pcall(function() list[#list + 1] = x[2]() end) end
    for _, w in ipairs(list) do
        pcall(function()
            if w and w:isVisible() then t[#t + 1] = string.format("%d,%d,%d,%d,%d", math.floor(w:getX()), math.floor(w:getY()), math.floor(w:getWidth()), math.floor(w:getHeight()), math.floor(w._drawerEffW or 0)) end
        end)
    end
    return table.concat(t, ";")
end

-- ===================================================================== windows to one side
function C1.margin()
    local m = 24
    pcall(function() if ZeD and ZeD.T and ZeD.T.px then m = ZeD.T.px(12) end end)
    return m
end
-- list: { { label, win, "left" | "right" | "top" }, ... } in order; windows on the same side are packed
function C1.side(Q, list)
    local W = C1.core:getScreenWidth()
    local m = C1.margin()
    local at = { left = m, right = W - m, top = m }
    for _, e in ipairs(list) do
        local win, side = e[2], e[3]
        if win and win:isVisible() then
            local x0, y0 = math.floor(win:getX()), math.floor(win:getY())
            if side == "right" then win:setX(at.right - win:getWidth()); at.right = at.right - win:getWidth() - m
            elseif side == "top" then win:setY(at.top); at.top = at.top + win:getHeight() + m
            else win:setX(at.left); at.left = at.left + win:getWidth() + m end
            if win._anchorRightEdge ~= nil then win._anchorRightEdge = win:getX() + win:getWidth() end
            if Q and (x0 ~= math.floor(win:getX()) or y0 ~= math.floor(win:getY())) then
                Q.say(string.format("moved %s from %d,%d to %d,%d (%s side)", tostring(e[1]), x0, y0, math.floor(win:getX()), math.floor(win:getY()), tostring(side)))
            end
        end
    end
end
-- ZeD's pair: both on the left when they fit left of the character, else Character left, World right
function C1.pairSide(Q)
    if not C1.zed then return end
    local c, w = ZeD_CharacterWindow.getWindow(), ZeD_WorldWindow.getWindow()
    local m = C1.margin()
    local r = C1.charRect()
    local cw = (c and c:isVisible()) and c:getWidth() or 0
    local ww = (w and w:isVisible()) and w:getWidth() or 0
    if m + cw + m + ww + m <= r.x0 then C1.side(Q, { { "char", c, "left" }, { "world", w, "left" } })
    else C1.side(Q, { { "char", c, "left" }, { "world", w, "right" } }) end
end

-- ===================================================================== places
function C1.sqAt(x, y, z) return getCell():getGridSquare(x, y, z or 0) end
function C1.roomName(sq)
    local n = nil
    pcall(function() local r = sq:getRoom(); if r then n = r:getName() end end)
    return n
end
-- the square fits the place: in the room named, or outdoors with no room
function C1.fits(P, sq)
    if not sq then return false end
    local ok = false
    pcall(function() ok = sq:isFree(false) and not sq:getVehicleContainer() end)
    if not ok then return false end
    if P.outdoor then
        local out = false
        pcall(function() out = sq:isOutside() and sq:getRoom() == nil and sq:getFloor() ~= nil end)
        return out
    end
    return C1.roomName(sq) == P.room
end
C1.SIDES = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
-- the nearest square to the anchor that fits, with 3 of its 4 sides fitting too (room to stand, not against a counter)
function C1.findSpot(P)
    for r = 0, P.r do
        for dy = -r, r do
            for dx = -r, r do
                if math.abs(dx) == r or math.abs(dy) == r then
                    local x, y = P.ax + dx, P.ay + dy
                    if C1.fits(P, C1.sqAt(x, y, 0)) then
                        local n = 0
                        for _, d in ipairs(C1.SIDES) do if C1.fits(P, C1.sqAt(x + d[1], y + d[2], 0)) then n = n + 1 end end
                        if n >= 3 then return { x = x, y = y } end
                    end
                end
            end
        end
    end
    return nil
end
function C1.tp(x, y, z)
    pcall(function() C1.p:teleportTo(x, y, z or 0) end)
    pcall(function() C1.p:setX(x); C1.p:setY(y); C1.p:setZ(z or 0); C1.p:setLastX(x); C1.p:setLastY(y); C1.p:setLastZ(z or 0) end)
end
function C1.face(dir) pcall(function() if not C1.p:getVehicle() then C1.p:setDir(IsoDirections[dir or "SE"]) end end) end
function C1.clearZombies(x, y, rad)
    local rm = {}
    pcall(function()
        local zs = getCell():getZombieList()
        for i = 0, zs:size() - 1 do
            local z = zs:get(i)
            if math.abs(z:getX() - x) <= rad and math.abs(z:getY() - y) <= rad then rm[#rm + 1] = z end
        end
    end)
    for _, z in ipairs(rm) do pcall(function() z:removeFromWorld(); z:removeFromSquare() end) end
    return #rm
end
function C1.floorName(sq)
    local n = "?"
    pcall(function() n = tostring(sq:getFloor():getSprite():getName()) end)
    return n
end
-- the character to the place: far away, the world is given 8 s to stream in once the anchor's square exists
function C1.go(Q, key)
    local P = C1.PLACES[key]
    Q.step(5, function()
        C1.closeMenus()
        pcall(function() local car = C1.p:getVehicle(); if car then car:exit(C1.p) end end)
        local far = math.abs(C1.p:getX() - P.ax) > 40 or math.abs(C1.p:getY() - P.ay) > 40 or math.floor(C1.p:getZ()) ~= 0
        C1.goT0 = far and getTimestampMs() or nil
        if far then
            Q.say(string.format("to %s: from %d,%d", key, math.floor(C1.p:getX()), math.floor(C1.p:getY())))
            C1.tp(P.ax + 0.5, P.ay + 0.5, 0)
        end
    end)
    Q.waitFor(5, 3000, function()
        if not C1.goT0 then return true end
        return C1.sqAt(P.ax, P.ay, 0) ~= nil and getTimestampMs() - C1.goT0 > 8000
    end, function()
        local s = C1.findSpot(P)
        if not s then
            Q.say("ERR " .. key .. ": no free square with room to stand near " .. P.ax .. "," .. P.ay .. " (room " .. tostring(P.room) .. "); standing at the anchor")
            s = { x = P.ax, y = P.ay }
        end
        C1.tp(s.x + 0.5, s.y + 0.5, 0)
        C1.face(P.dir)
        local n = C1.clearZombies(s.x, s.y, 30)
        local sq = C1.sqAt(s.x, s.y, 0)
        C1.here = key .. " " .. s.x .. "," .. s.y
        Q.say(string.format("place %s: %s | square %d,%d room %s floor %s | %d zombies within 30 squares taken out of the world",
            key, P.name, s.x, s.y, tostring(C1.roomName(sq)), C1.floorName(sq), n))
    end)
    C1.waitMap(Q, key)
    C1.reveal(Q, key)
    Q.step(10, function()
        C1.face(P.dir)
        C1.rule()
        pcall(function() Q.say("grid power here " .. tostring(C1.p:getCurrentSquare():hasGridPower())) end)
    end)
end

-- the map loaded round the character (gallery_v1_mp_stage.lua's check): every square on rings 10, 25 and 40 squares
-- out exists (16 each), three clean checks a second apart, then 4 s more; at most about 2 minutes
C1.RINGS = { 10, 25, 40 }
function C1.ringMiss()
    local px, py = math.floor(C1.p:getX()), math.floor(C1.p:getY())
    local miss = 0
    for _, r in ipairs(C1.RINGS) do
        for k = 0, 15 do
            local a = k * math.pi / 8
            if not C1.sqAt(px + math.floor(r * math.cos(a)), py + math.floor(r * math.sin(a)), 0) then miss = miss + 1 end
        end
    end
    return miss
end
function C1.waitMap(Q, label)
    local st = { clean = 0, last = 0, t = nil }
    Q.waitFor(5, 7200, function()
        local now = getTimestampMs()
        if st.t then return now - st.t >= 4000 end
        if now - st.last < 1000 then return false end
        st.last = now
        local miss = C1.ringMiss()
        if miss == 0 then st.clean = st.clean + 1 else st.clean = 0 end
        if st.clean >= 3 then st.t = now end
        return false
    end, function(ok)
        local miss = C1.ringMiss()
        Q.say(string.format("%s map loaded round %d,%d: %s (%d of 48 ring squares missing) | time %.2f", tostring(label),
            math.floor(C1.p:getX()), math.floor(C1.p:getY()), (miss == 0 and ok) and "PASS" or "FAIL", miss, getGameTime():getTimeOfDay()))
    end)
end

-- the squares round the spot SEEN (the game draws squares the character never saw black, loaded or not): the tour of
-- gallery_v3_reveal.lua round the character's spot: stops 12 and 26 squares out in eight directions (the nearest free
-- outdoor square to each), a full turn at each, then back on the spot facing the camera. The unseen squares within 30
-- (sq:isSeen) are counted before and after, as the check that the frame will have no black.
C1.DIRS = { "N", "NE", "E", "SE", "S", "SW", "W", "NW" }
function C1.nearOut(x, y)
    for r = 0, 6 do
        for dy = -r, r do
            for dx = -r, r do
                if math.max(math.abs(dx), math.abs(dy)) == r then
                    local q = C1.sqAt(x + dx, y + dy, 0)
                    local ok = false
                    if q then pcall(function() ok = q:isOutside() and q:isFree(false) and not q:getVehicleContainer() end) end
                    if ok then return x + dx, y + dy end
                end
            end
        end
    end
    return nil
end
function C1.unseen(rad)
    local px, py = math.floor(C1.p:getX()), math.floor(C1.p:getY())
    local n, all = 0, 0
    local ok = pcall(function()
        for dy = -rad, rad, 2 do
            for dx = -rad, rad, 2 do
                local q = C1.sqAt(px + dx, py + dy, 0)
                if q then all = all + 1; if not q:isSeen(C1.pn) then n = n + 1 end end
            end
        end
    end)
    if not ok then return "unknown (no isSeen)" end
    return n .. " of " .. all
end
function C1.reveal(Q, label)
    local st = {}
    Q.step(2, function()
        st.home = { x = C1.p:getX(), y = C1.p:getY(), z = C1.p:getZ() }
        Q.say(tostring(label) .. " reveal: unseen squares within 30 before the tour " .. C1.unseen(30))
    end)
    for _, d in ipairs({ 12, 26 }) do
        for _, o in ipairs({ { 0, -1 }, { 1, -1 }, { 1, 0 }, { 1, 1 }, { 0, 1 }, { -1, 1 }, { -1, 0 }, { -1, -1 } }) do
            Q.step(2, function()
                local x, y = C1.nearOut(math.floor(st.home.x) + o[1] * d, math.floor(st.home.y) + o[2] * d)
                if x then C1.tp(x + 0.5, y + 0.5, 0) end
            end)
            for _, dn in ipairs(C1.DIRS) do Q.step(4, function() C1.face(dn) end) end
            Q.step(6, function() end)
        end
    end
    Q.step(2, function() C1.tp(st.home.x, st.home.y, st.home.z) end)
    for _, dn in ipairs(C1.DIRS) do Q.step(8, function() C1.face(dn) end) end
    Q.step(20, function()
        C1.face("SE")
        Q.say(tostring(label) .. " reveal: unseen squares within 30 after the tour " .. C1.unseen(30))
    end)
end

-- the load under to kg for a set of shots: the heaviest loose things (not worn, held, on the belt) set aside out of the
-- inventory (gallery_b19_a.lua's lightenTo), then put back by C1.lightenBack
function C1.lightenTo(Q, to)
    C1.aside = C1.aside or {}
    pcall(function()
        local inv = C1.p:getInventory()
        local loose = {}
        local items = inv:getItems()
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            local keep = C1.p:isEquipped(it) or C1.p:isEquippedClothing(it) or C1.p:isHandItem(it) or (it:getAttachedSlot() and it:getAttachedSlot() > -1)
            if not keep then loose[#loose + 1] = it end
        end
        table.sort(loose, function(a, b) return a:getUnequippedWeight() > b:getUnequippedWeight() end)
        local W = (GAL_UNLOAD and GAL_UNLOAD.weight) and GAL_UNLOAD.weight() or inv:getCapacityWeight()
        for _, it in ipairs(loose) do
            if W <= to then break end
            W = W - it:getUnequippedWeight()
            inv:Remove(it)
            C1.aside[#C1.aside + 1] = it
        end
    end)
    Q.say(string.format("set aside %d things; load now %s", #C1.aside, (GAL_UNLOAD and GAL_UNLOAD.line) and GAL_UNLOAD.line() or "?"))
end
function C1.lightenBack(Q)
    local inv = C1.p:getInventory()
    for _, it in ipairs(C1.aside or {}) do pcall(function() inv:AddItem(it) end) end
    if Q then Q.say("put back " .. #(C1.aside or {}) .. " things set aside") end
    C1.aside = {}
end

-- the grid power on (the house and the store lit) and back (as gallery_b19_a.lua's S.grid)
function C1.grid(on)
    local W = C1.was
    pcall(function()
        if W.so == nil then
            W.so = getSandboxOptions()
            W.elec = W.so:getOptionByName("ElecShutModifier")
            W.watr = W.so:getOptionByName("WaterShutModifier")
            W.elecWas, W.watrWas = W.elec and W.elec:getValue(), W.watr and W.watr:getValue()
        end
    end)
    pcall(function() if W.elec then W.elec:setValue(on and 99999 or W.elecWas); W.so:toLua() end end)
    pcall(function() if W.watr then W.watr:setValue(on and 99999 or W.watrWas); W.so:toLua() end end)
    pcall(function() getWorld():setHydroPowerOn(on and true or (W.hydro == true)) end)
    C1.gridOn = on and true or nil
end

-- a thing put on the floor beside the character, and taken away again
function C1.drop(ft, dx, dy)
    local it = nil
    pcall(function()
        local sq = C1.sqAt(math.floor(C1.p:getX()) + dx, math.floor(C1.p:getY()) + dy, math.floor(C1.p:getZ()))
        it = sq:AddWorldInventoryItem(ft, 0.5, 0.5, 0)
    end)
    if it then C1.ground = C1.ground or {}; C1.ground[#C1.ground + 1] = it end
    return it
end
function C1.groundBack()
    for _, it in ipairs(C1.ground or {}) do
        pcall(function()
            local wi = it:getWorldItem()
            if wi then wi:getSquare():transmitRemoveItemFromSquare(wi); wi:removeFromWorld(); wi:removeFromSquare() end
        end)
    end
    C1.ground = nil
end

C1.log("helpers ready | ZeD loaded " .. tostring(C1.zed) .. " | start " .. math.floor(C1.was.x) .. "," .. math.floor(C1.was.y)
    .. " | load " .. ((GAL_UNLOAD and GAL_UNLOAD.line) and GAL_UNLOAD.line() or "(no unload)"))
C1.k = 0
function C1.later()
    C1.k = C1.k + 1
    if C1.k < 10 then return end
    Events.OnTick.Remove(C1.later)
    C1.log("DONE")
end
Events.OnTick.Add(C1.later)
