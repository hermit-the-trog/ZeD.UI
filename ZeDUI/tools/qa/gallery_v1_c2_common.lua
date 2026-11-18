-- ZeDUI/tools/qa/gallery_v1_c2_common.lua  (Nov 17 2026, QA): shared helpers for the ZeD-GUI 1.0 gallery "lived-in"
-- retakes, second batch (chapters 32, 34, 37, 38, 42, 47, 48, 50, 53, 54; HANDOFF_design_gallery_v1_20261117.md).
-- Run once in gallery_v1_c2.txt after gallery_unload.lua, before gallery_v1_c2_house / _street / _garage.lua.
-- Defines the global C2:
--   C2.make(tag)       a step queue on Events.OnPreUIDraw (zedqa_b19_pad.lua's queue with waitFor and still): Q.step,
--                      Q.waitFor, Q.still, Q.mark (the put-back starts here; a run too long jumps to it), Q.start (ends
--                      with "ZEDQA <tag> DONE"); every line said is "ZEDQA <tag> ..."
--   C2.shot(Q, name, o) the gallery rule (invisible off, god mode off, zombies-don't-attack on, debug console hidden),
--                      menus closed unless o.menu, the pointer parked and hidden unless o.pointer (a hover shot), then
--                      TakeFullScreenshot, the load line (GAL_UNLOAD), any container over its limit ("Overflow"), and
--                      every window's box with "COVERS the character" for any box over the character
--   C2.sides(Q)        THE NEW RULE: the Character window to the left edge, the World window to the right edge (sizes
--                      kept), so the character and the place stay clear in the middle; C2.top(Q, el, label) puts a
--                      prompt or pop-up along the top (else to a side) clear of the character
--   C2.scan / C2.house / C2.street / C2.driveway   the places, found at run time round the Fossoil, West Point
--                      (47_27.lotheader, rooms "fossoil" 12052-12069 x 7117-7126, gallery_story_stage.lua's site):
--                      a furnished house (a bedroom and a living room or kitchen, the nearest to the store), the street
--                      in front of the store (outdoors, paved, on the camera side), a driveway by a garage (else by a
--                      house, else the store's forecourt)
--   C2.carSpawn(Q, script, getFp, onReady, onFail)   a car on a checked 3 x 7 footprint (outdoors, free, no tree, no car), ready
--                      by ZEDQA_CAR_READY (zedqa_prelude.lua); the character is outdoors beside it first
--   C2.power / C2.lights / C2.clim / C2.give: changes kept and put back by C2.back
-- Kahlua: no next(), ASCII only, one table, risky calls in pcall. grep "ZEDQA gv1c".
C2 = C2 or {}
C2.p = getPlayer()
C2.pn = C2.p:getPlayerNum()
C2.core = getCore()
C2.STORE = { x0 = 12052, y0 = 7117, x1 = 12069, y1 = 7126, cx = 12060, cy = 7121 }
C2.PAVED = { "street", "road", "asphalt", "blacktop", "pavement", "concrete", "sidewalk", "parking", "floors_exterior" }
C2.HOUSE_ROOMS = { bedroom = true, livingroom = true, kitchen = true, diningroom = true, bathroom = true, hall = true }
function C2.log(s) print("ZEDQA gv1c " .. tostring(s)) end

-- ===================================================================== the queue (zedqa_b19_pad.lua's, OnPreUIDraw)
function C2.make(tag)
    local Q = { tag = tag, list = {}, qi = 1, wait = nil, t0 = getTimestampMs(), maxMs = 1350000, nOk = 0, nErr = 0, v = {} }
    function Q.say(s) print("ZEDQA " .. Q.tag .. " " .. tostring(s)) end
    function Q.step(n, fn) Q.list[#Q.list + 1] = { n = n, fn = fn } end
    -- after n frames, every frame until cond() (at most max frames), then fn(ok)
    function Q.waitFor(n, max, cond, fn) Q.list[#Q.list + 1] = { n = n, fn = fn, cond = cond, max = max } end
    -- the windows the same for 30 frames (at most 900), then fn
    function Q.still(n, fn)
        local st = { last = nil, same = 0 }
        Q.waitFor(n, 900, function()
            local s = C2.shape()
            if s == st.last then st.same = st.same + 1 else st.last, st.same = s, 0 end
            return st.same >= 30
        end, fn or function() end)
    end
    -- wait ms of real time
    function Q.waitMs(ms)
        local st = { t = nil }
        Q.waitFor(1, math.floor(ms / 3) + 900, function()
            st.t = st.t or getTimestampMs()
            return getTimestampMs() - st.t >= ms
        end, function() end)
    end
    function Q.notTaken(name, why) Q.nErr = Q.nErr + 1; Q.say("not taken: " .. name .. " (" .. tostring(why) .. ")") end
    function Q.mark() Q.backAt = #Q.list + 1 end
    function Q.tick()
        local s = Q.list[Q.qi]
        if not s then Events.OnPreUIDraw.Remove(Q.tick); return end
        if Q.backAt and Q.qi < Q.backAt and getTimestampMs() - Q.t0 > Q.maxMs then
            Q.say("ERR ran too long at step " .. Q.qi .. ": jumping to the put-back")
            Q.qi = Q.backAt
            Q.wait = nil
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
    function Q.start()
        Q.step(2, function() Q.say(string.format("end: %d shots, %d not taken or failed", Q.nOk, Q.nErr)); Q.say("DONE") end)
        Events.OnPreUIDraw.Add(Q.tick)
        Q.say("start (" .. #Q.list .. " steps)")
    end
    return Q
end

-- ===================================================================== windows
function C2.cw() local w = nil; pcall(function() w = ZeD_CharacterWindow.getWindow(C2.pn) end); return w end
function C2.ww() local w = nil; pcall(function() w = ZeD_WorldWindow.getWindow(C2.pn) end); return w end
function C2.isOpen() local o = false; pcall(function() o = ZeD_CharacterWindow.isOpen(C2.pn) end); return o end
function C2.pairOpen() if not C2.isOpen() then pcall(ZeD_CharacterWindow.toggleBothPaired, C2.pn) end end
function C2.pairShut() if C2.isOpen() then pcall(ZeD_CharacterWindow.toggleBothPaired, C2.pn) end end
function C2.goTab(win, strip, tab)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. tab then
            if win._activeTab ~= tab or (tab ~= "loot" and win._drawerOpen == false) then strip:onMouseDown(z.x + 2, z.y + 2) end
            return true
        end
    end
    return false
end
function C2.charTab(id) local w = C2.cw(); return (w and C2.goTab(w, w._tabStripPanel, id)) and true or false end
function C2.worldTab(id) local w = C2.ww(); return (w and C2.goTab(w, w._actionTabStrip, id)) and true or false end
function C2.margin() local m = 24; pcall(function() m = ZeD.T.px(12) end); return m end
-- the window places as found (put back by C2.winsBack)
function C2.snapWins()
    if C2.winsWas then return end
    C2.winsWas = {}
    if ZEDQA_LAYOUT_SNAP then pcall(function() C2.layoutSnap = ZEDQA_LAYOUT_SNAP() end) end
    for _, e in ipairs({ { "c", C2.cw() }, { "w", C2.ww() } }) do
        if e[2] then C2.winsWas[e[1]] = { x = e[2]:getX(), y = e[2]:getY(), a = e[2]._anchorRightEdge } end
    end
end
function C2.winsBack(Q)
    if ZEDQA_LAYOUT_BACK and C2.layoutSnap then pcall(ZEDQA_LAYOUT_BACK, C2.layoutSnap, Q and Q.tag or "gv1c") end
    for _, e in ipairs({ { "c", C2.cw() }, { "w", C2.ww() } }) do
        local was = C2.winsWas and C2.winsWas[e[1]]
        if e[2] and was then
            pcall(function() e[2]:setX(was.x); e[2]:setY(was.y); e[2]._anchorRightEdge = was.a end)
        end
    end
    C2.winsWas, C2.layoutSnap = nil, nil
end
-- THE NEW RULE: Character at the left edge, World at the right edge; the middle (the character, the place) clear
function C2.sides(Q)
    C2.snapWins()
    local W, m = C2.core:getScreenWidth(), C2.margin()
    local c, w = C2.cw(), C2.ww()
    if c and c:isVisible() then
        pcall(function() c:setX(m); c._anchorRightEdge = m + c:getWidth() end)
    end
    if w and w:isVisible() then
        pcall(function() w:setX(W - m - w:getWidth()) end)
    end
end
-- an element (a prompt, the reader, a pop-up) along the top, centred; to the left edge if it would still cover the
-- character; logged
function C2.top(Q, el, label)
    if not el then return end
    local W, m = C2.core:getScreenWidth(), C2.margin()
    local r = C2.charRect()
    pcall(function()
        el:setX(math.floor((W - el:getWidth()) / 2))
        el:setY(m)
        if el:getY() + el:getHeight() > r.y0 then el:setX(m) end
    end)
    pcall(function() Q.say(string.format("placed %s at %d,%d (%dx%d)%s", tostring(label), el:getX(), el:getY(), el:getWidth(), el:getHeight(),
        C2.coversEl(el) and " - still COVERS the character" or "")) end)
end
function C2.side(Q, el, side, label)
    if not el then return end
    local W, m = C2.core:getScreenWidth(), C2.margin()
    pcall(function()
        el:setX((side == "right") and (W - m - el:getWidth()) or m)
        Q.say(string.format("placed %s at the %s edge, x %d (%dx%d)", tostring(label), tostring(side), el:getX(), el:getWidth(), el:getHeight()))
    end)
end
-- before a shot: the windows to the sides, held still for 30 frames, to the sides again (a drawer that opened since
-- may have moved the Character window's left edge, which is anchored on its right)
function C2.ready(Q)
    Q.step(2, function() C2.sides(Q) end)
    Q.still(10, function() C2.sides(Q) end)
    Q.step(5, function() end)
end
function C2.shape()
    local t = {}
    for _, e in ipairs({ C2.cw(), C2.ww() }) do
        pcall(function() if e and e:isVisible() then t[#t + 1] = string.format("%d,%d,%d,%d,%d", e:getX(), e:getY(), e:getWidth(), e:getHeight(), math.floor(e._drawerEffW or 0)) end end)
    end
    return table.concat(t, ";")
end

-- ===================================================================== the character on the screen, the boxes
function C2.charRect()
    local W, H = C2.core:getScreenWidth(), C2.core:getScreenHeight()
    local r = { x = W / 2, y = H / 2 }
    pcall(function()
        local sx = isoToScreenX(C2.pn, C2.p:getX(), C2.p:getY(), C2.p:getZ())
        local sy = isoToScreenY(C2.pn, C2.p:getX(), C2.p:getY(), C2.p:getZ())
        if sx and sy then r.x, r.y = sx, sy end
    end)
    local z = 1
    pcall(function() z = C2.core:getZoom(C2.pn) end)
    if not z or z <= 0 then z = 1 end
    r.x0, r.x1 = math.floor(r.x - 160 / z), math.floor(r.x + 160 / z)
    r.y0, r.y1 = math.floor(r.y - 360 / z), math.floor(r.y + 60 / z)
    return r
end
function C2.coversEl(el)
    local hit = false
    pcall(function()
        if not el:isVisible() then return end
        local r = C2.charRect()
        local x, y = el:getAbsoluteX(), el:getAbsoluteY()
        hit = x < r.x1 and x + el:getWidth() > r.x0 and y < r.y1 and y + el:getHeight() > r.y0
    end)
    return hit
end
-- every visible window this run draws (and the extras the script names: { { "label", element }, ... })
function C2.boxes(Q, name, extra)
    local r = C2.charRect()
    Q.say(string.format("box %s character %d,%d-%d,%d", name, r.x0, r.y0, r.x1, r.y1))
    local list = { { "char", C2.cw() }, { "world", C2.ww() } }
    pcall(function() local L = ZeD.Moodles.getLayer(C2.pn); if L then list[#list + 1] = { "moodles", L, true } end end)
    pcall(function() local h = ZeD.Belt.getHUD(); if h then list[#list + 1] = { "belt", h, true } end end)
    pcall(function() local m = getPlayerContextMenu(C2.pn); if m and m._zedMenu then list[#list + 1] = { "menu", m._zedMenu } end end)
    for _, e in ipairs(extra or {}) do list[#list + 1] = e end
    for _, e in ipairs(list) do
        local w = e[2]
        local vis = false
        pcall(function() vis = w ~= nil and w:isVisible() and w:getWidth() > 0 end)
        if vis then
            pcall(function()
                local x, y = w:getAbsoluteX(), w:getAbsoluteY()
                Q.say(string.format("box %s %s %d,%d-%d,%d%s", name, e[1], x, y, x + w:getWidth(), y + w:getHeight(),
                    (not e[3] and C2.coversEl(w)) and " COVERS the character" or ""))
            end)
        end
    end
end

-- ===================================================================== the gallery rule, the pointer, the load
function C2.rule()
    pcall(function() C2.p:setInvisible(false) end)
    pcall(function() C2.p:setGodMod(false) end)
    pcall(function() C2.p:setZombiesDontAttack(true) end)
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do
            local e = ui:get(i)
            if e:getClass():getSimpleName() == "UIDebugConsole" and e:isVisible() then e:setVisible(false) end
        end
    end)
end
function C2.closeMenus()
    pcall(function() local m = getPlayerContextMenu(C2.pn); if m and m._zedMenu then m._zedMenu:close() end end)
    pcall(function() local m = getPlayerContextMenu(C2.pn); if m and m:isVisible() then m:closeAll() end end)
end
function C2.hidePointer()
    pcall(function() Mouse.setXY(4, C2.core:getScreenHeight() - 4) end)
    pcall(function() Mouse.setCursorVisible(false) end)
end
-- a hover shot: gallery_unload.lua's every-frame hide paused, the pointer shown; C2.pointerOff() puts the hide back
function C2.pointerOn()
    local U = GAL_UNLOAD
    if U and U.watch and not C2.unlPaused then pcall(function() Events.OnPreUIDraw.Remove(U.watch) end); C2.unlPaused = true end
    pcall(function() Mouse.setCursorVisible(true) end)
end
function C2.pointerOff()
    local U = GAL_UNLOAD
    if C2.unlPaused and U and U.watch then pcall(function() Events.OnPreUIDraw.Add(U.watch) end) end
    C2.unlPaused = nil
    pcall(function() Mouse.setCursorVisible(false) end)
end
function C2.pointAt(x, y) pcall(function() Mouse.setXY(math.floor(x), math.floor(y)) end) end
function C2.loadLine() return (GAL_UNLOAD and GAL_UNLOAD.line) and GAL_UNLOAD.line() or "(gallery_unload.lua did not run)" end
-- the inventory and every bag worn or held: over its limit is a "No room" Overflow strip in the picture
function C2.overflow()
    local out = {}
    pcall(function()
        local inv = C2.p:getInventory()
        local list = { { "inventory", inv } }
        local items = inv:getItems()
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            if instanceof(it, "InventoryContainer") and C2.p:isEquipped(it) then list[#list + 1] = { it:getName(), it:getInventory() } end
        end
        for _, e in ipairs(list) do
            local wt, cap = 0, 0
            pcall(function() wt = e[2]:getCapacityWeight(); cap = e[2]:getEffectiveCapacity(C2.p) end)
            if cap > 0 and wt > cap then out[#out + 1] = string.format("%s %.1f of %d", tostring(e[1]), wt, cap) end
        end
    end)
    return out
end
function C2.shot(Q, name, o)
    o = o or {}
    C2.rule()
    if not o.menu then C2.closeMenus() end
    if o.pointer then C2.pointerOn() else C2.hidePointer() end
    local ok, e = pcall(function() C2.core:TakeFullScreenshot(name .. ".png") end)
    if ok then Q.nOk = Q.nOk + 1; Q.say("shot " .. name .. (o.pointer and " (pointer shown: the hover is the point)" or ""))
    else Q.nErr = Q.nErr + 1; Q.say("ERR shot " .. name .. ": " .. tostring(e)) end
    Q.say("load " .. name .. ": " .. C2.loadLine())
    local ov = C2.overflow()
    Q.say("overflow " .. name .. ": " .. ((#ov == 0) and "none" or ("OVER " .. table.concat(ov, "; "))))
    Q.say(string.format("where %s: %d,%d,%d %s", name, math.floor(C2.p:getX()), math.floor(C2.p:getY()), math.floor(C2.p:getZ()), tostring(C2.placeName)))
    C2.boxes(Q, name, o.extra)
    if o.pointer then C2.pointerOff() end
end

-- ===================================================================== squares and places
function C2.sq(x, y, z) return getCell():getGridSquare(x, y, z or 0) end
function C2.tp(x, y, z)
    pcall(function() C2.p:teleportTo(x, y, z or 0) end)
    pcall(function() C2.p:setX(x); C2.p:setY(y); C2.p:setZ(z or 0); C2.p:setLastX(x); C2.p:setLastY(y); C2.p:setLastZ(z or 0) end)
end
function C2.tpSq(q) if q then C2.tp(q[1] + 0.5, q[2] + 0.5, 0) end end
function C2.face(dir) pcall(function() if not C2.p:getVehicle() then C2.p:setDir(IsoDirections[dir or "SE"]) end end) end
-- the squares round x, y loaded out to r (each corner and the middle)
function C2.loaded(x, y, r)
    for _, d in ipairs({ { 0, 0 }, { r, r }, { -r, r }, { r, -r }, { -r, -r } }) do
        local sq = C2.sq(x + d[1], y + d[2], 0)
        local ok = false
        pcall(function() ok = sq ~= nil and sq:getChunk() ~= nil end)
        if not ok then return false end
    end
    return true
end
function C2.free(sq)
    local ok = false
    pcall(function() ok = sq ~= nil and sq:isFree(false) and not sq:getVehicleContainer() and not sq:HasTree() end)
    return ok
end
function C2.floorName(sq)
    local nm = ""
    pcall(function() local f = sq:getFloor(); nm = string.lower(tostring(f and f:getSprite() and f:getSprite():getName() or "")) end)
    return nm
end
function C2.paved(sq)
    local nm = C2.floorName(sq)
    for _, w in ipairs(C2.PAVED) do if string.find(nm, w, 1, true) then return true end end
    return false
end
function C2.roomName(sq)
    local n = nil
    pcall(function() local r = sq:getRoom(); if r then n = string.lower(tostring(r:getName())) end end)
    return n
end
function C2.inStore(x, y) local s = C2.STORE; return x >= s.x0 and x <= s.x1 and y >= s.y0 and y <= s.y1 end
-- every room square round cx, cy out to r, grouped by building: B[i] = { b = building, rooms = { name = { {x,y}, ... } },
-- d = distance of its nearest square to the store }
function C2.scan(cx, cy, r)
    local B, byKey = {}, {}
    for dy = -r, r do
        for dx = -r, r do
            local x, y = cx + dx, cy + dy
            local sq = C2.sq(x, y, 0)
            local nm = sq and C2.roomName(sq)
            if nm and not C2.inStore(x, y) then
                local bld, key = nil, nil
                pcall(function() bld = sq:getBuilding(); key = tostring(bld) end)
                if key then
                    local e = byKey[key]
                    if not e then e = { b = bld, rooms = {}, d = 1e9, key = key }; byKey[key] = e; B[#B + 1] = e end
                    e.rooms[nm] = e.rooms[nm] or {}
                    if C2.free(sq) then e.rooms[nm][#e.rooms[nm] + 1] = { x, y } end
                    local d = math.abs(x - C2.STORE.cx) + math.abs(y - C2.STORE.cy)
                    if d < e.d then e.d = d end
                end
            end
        end
    end
    return B
end
-- a free square of a room with the most free neighbours in the same room (a clear spot to stand, not a doorway)
function C2.spotIn(list, name)
    local best, bn = nil, -1
    local seen = {}
    for _, q in ipairs(list or {}) do seen[q[1] .. "," .. q[2]] = true end
    for _, q in ipairs(list or {}) do
        local n = 0
        for dy = -1, 1 do for dx = -1, 1 do if (dx ~= 0 or dy ~= 0) and seen[(q[1] + dx) .. "," .. (q[2] + dy)] then n = n + 1 end end end
        if n > bn then best, bn = q, n end
    end
    if best then return { best[1], best[2], room = name, n = bn } end
    return nil
end
-- the furnished house: the building nearest the store with a bedroom and a living room or kitchen (both with room to
-- stand); its spots: bed (the bedroom) and living (the living room, else the kitchen, else the dining room)
function C2.house(Q, B)
    local best = nil
    for _, e in ipairs(B) do
        local R = e.rooms
        local bed = R.bedroom and #R.bedroom >= 4
        local liv = (R.livingroom and #R.livingroom >= 6) or (R.kitchen and #R.kitchen >= 6) or (R.diningroom and #R.diningroom >= 6)
        local nameOk = true
        for nm in pairs(R) do if not C2.HOUSE_ROOMS[nm] and nm ~= "garage" and nm ~= "garagestorage" and nm ~= "laundry" and nm ~= "storage" then nameOk = false end end
        if bed and liv and nameOk and (not best or e.d < best.d) then best = e end
    end
    if not best then return nil end
    local R = best.rooms
    local H = { e = best }
    H.bed = C2.spotIn(R.bedroom, "bedroom")
    if R.livingroom and #R.livingroom >= 6 then H.living = C2.spotIn(R.livingroom, "livingroom")
    elseif R.kitchen and #R.kitchen >= 6 then H.living = C2.spotIn(R.kitchen, "kitchen")
    else H.living = C2.spotIn(R.diningroom, "diningroom") end
    local names = {}
    for nm, l in pairs(R) do names[#names + 1] = nm .. "(" .. #l .. ")" end
    Q.say(string.format("house: %d squares from the store; rooms %s; bed spot %d,%d; living spot %d,%d (%s)", best.d, table.concat(names, " "),
        H.bed[1], H.bed[2], H.living[1], H.living[2], tostring(H.living.room)))
    return H
end
-- the street in front of the store: outdoors, free, paved, 3 to 9 squares out, on the camera side (the larger x + y),
-- clear of cars and pumps round it (the 3 x 3 free)
function C2.street(Q)
    local s = C2.STORE
    local best, bs = nil, -1e9
    for y = s.y0 - 9, s.y1 + 9 do
        for x = s.x0 - 9, s.x1 + 9 do
            local sq = C2.sq(x, y, 0)
            local out = false
            pcall(function() out = sq ~= nil and sq:isOutside() end)
            if out and C2.free(sq) and C2.paved(sq) then
                local dOut = math.max(s.x0 - x, x - s.x1, s.y0 - y, y - s.y1)
                local clear = true
                for dy = -1, 1 do for dx = -1, 1 do if not C2.free(C2.sq(x + dx, y + dy, 0)) then clear = false end end end
                if dOut >= 3 and clear then
                    local sc = x + y - math.abs(x - s.cx) * 0.6
                    if sc > bs then best, bs = { x, y }, sc end
                end
            end
        end
    end
    if best then Q.say(string.format("street spot %d,%d (%s)", best[1], best[2], C2.floorName(C2.sq(best[1], best[2], 0)))) end
    return best
end
-- a car's footprint, facing north, centred on cx, cy: 3 wide, 7 long; outdoors, free, no tree, no car within 3;
-- returns ok, the paved count of 5 floor checks, why
function C2.footprint(cx, cy)
    for dy = -3, 3 do
        for dx = -1, 1 do
            local sq = C2.sq(cx + dx, cy + dy, 0)
            if not sq then return false, 0, "not loaded" end
            local bad = nil
            pcall(function()
                if sq:getChunk() == nil then bad = "no chunk"
                elseif not sq:isFree(false) then bad = "not free"
                elseif sq:HasTree() then bad = "a tree"
                elseif sq:getVehicleContainer() then bad = "a car"
                elseif sq:getRoom() ~= nil or not sq:isOutside() then bad = "indoors" end
            end)
            if bad then return false, 0, bad .. " at " .. (cx + dx) .. "," .. (cy + dy) end
        end
    end
    local busy = false
    pcall(function()
        local it = getCell():getVehicles():iterator()
        while it:hasNext() do
            local o = it:next()
            if math.abs(o:getX() - (cx + 0.5)) < 4 and math.abs(o:getY() - (cy + 0.5)) < 6 then busy = true end
        end
    end)
    if busy then return false, 0, "another car near" end
    local n = 0
    for _, o in ipairs({ { 0, 0 }, { 0, -3 }, { 0, 3 }, { -1, 0 }, { 1, 0 } }) do if C2.paved(C2.sq(cx + o[1], cy + o[2], 0)) then n = n + 1 end end
    -- the character's spot beside it (east) must be free too
    if not C2.free(C2.sq(cx + 2, cy, 0)) then return false, n, "no room beside it" end
    return true, n, nil
end
-- footprints round a set of squares (2 to 7 squares from any), best first: more paved, then nearer
function C2.footprintsNear(squares, minPaved)
    local out, seen = {}, {}
    for _, q in ipairs(squares) do
        for dy = -7, 7, 1 do
            for dx = -6, 6, 1 do
                local cx, cy = q[1] + dx, q[2] + dy
                local k = cx .. "," .. cy
                if not seen[k] then
                    seen[k] = true
                    local ok, n = C2.footprint(cx, cy)
                    if ok and n >= (minPaved or 0) then out[#out + 1] = { cx, cy, paved = n, d = math.abs(dx) + math.abs(dy) } end
                end
            end
        end
        if #out >= 40 then break end
    end
    table.sort(out, function(a, b) if a.paved ~= b.paved then return a.paved > b.paved end return a.d < b.d end)
    return out
end
-- the driveway: footprints by a garage room (a building's "garage"), else by the house, else on the street
function C2.driveway(Q, B, H, street)
    local gar = {}
    for _, e in ipairs(B) do
        for nm, l in pairs(e.rooms) do
            if string.find(nm, "garage", 1, true) and #l >= 2 then gar[#gar + 1] = { e = e, l = l, nm = nm } end
        end
    end
    table.sort(gar, function(a, b) return a.e.d < b.e.d end)
    for i, g in ipairs(gar) do
        if i <= 4 then
            local f = C2.footprintsNear(g.l, 3)
            if #f > 0 then
                Q.say(string.format("driveway by a %s %d squares from the store: car at %d,%d (%d of 5 paved)", g.nm, g.e.d, f[1][1], f[1][2], f[1].paved))
                return f[1], "a driveway by a " .. g.nm
            end
        end
    end
    Q.say("no driveway by a garage (" .. #gar .. " garages seen); trying by the house")
    if H then
        local sqs = {}
        for _, l in pairs(H.e.rooms) do for _, q in ipairs(l) do sqs[#sqs + 1] = q end end
        local f = C2.footprintsNear(sqs, 3)
        if #f > 0 then
            Q.say(string.format("driveway by the house: car at %d,%d (%d of 5 paved)", f[1][1], f[1][2], f[1].paved))
            return f[1], "a driveway by the house"
        end
    end
    if street then
        local f = C2.footprintsNear({ street }, 4)
        if #f > 0 then
            Q.say(string.format("no driveway: the car on the street by the store at %d,%d", f[1][1], f[1][2]))
            return f[1], "the street by the Fossoil"
        end
    end
    return nil, "no clear footprint for a car anywhere near"
end

-- ===================================================================== the car (zedqa_prelude.lua's checks, my spot)
-- spawn on getFp() ({cx, cy}, asked when the step runs), the character beside it first (outdoors: a car spawned by a
-- character indoors never wakes); onReady(v) once ZEDQA_CAR_READY, onFail(why) after about 10 s
function C2.carSpawn(Q, script, getFp, onReady, onFail)
    Q.step(2, function()
        C2.car = nil
        Q.v.fp = getFp()
        if not (Q.v.fp and ZEDQA_CAR_READY and ZEDQA_CAR_AWAY) then
            Q.v.carWhy = Q.v.fp and "no ZEDQA_CAR_READY (run zedqa_prelude.lua first)" or "no spot for the car"
            return
        end
        Q.v.carWhy = nil
        C2.tp(Q.v.fp[1] + 2.5, Q.v.fp[2] + 0.5, 0)
        C2.face("W")
    end)
    Q.step(60, function()
        if Q.v.carWhy then return end
        local ok, v = pcall(addVehicleDebug, script, IsoDirections.N, nil, C2.sq(Q.v.fp[1], Q.v.fp[2], 0))
        if ok and v then
            C2.car = v
            Q.v.carT0 = getTimestampMs()
            Q.say(string.format("car %s spawned at %d,%d", script, Q.v.fp[1], Q.v.fp[2]))
        else Q.v.carWhy = "addVehicleDebug gave no car for " .. tostring(script) end
    end)
    Q.waitFor(5, 600, function()
        if Q.v.carWhy or not C2.car then return true end
        local r = false
        pcall(function() r = ZEDQA_CAR_READY(C2.car) end)
        return r
    end, function(ok)
        if not Q.v.carWhy and not ok then
            Q.v.carWhy = "the car never got ready (no physics seen in 10 s)"
            pcall(ZEDQA_CAR_AWAY, C2.car); C2.car = nil
        end
        if Q.v.carWhy then Q.say("ERR car: " .. Q.v.carWhy); if onFail then pcall(onFail, Q.v.carWhy) end; return end
        Q.say("car ready")
        if onReady then local okR, e = pcall(onReady, C2.car); if not okR then Q.say("ERR car onReady: " .. tostring(e)) end end
    end)
end

-- ===================================================================== light, power, weather, things given
function C2.power(on)
    local so = getSandboxOptions()
    local e, w = so and so:getOptionByName("ElecShutModifier"), so and so:getOptionByName("WaterShutModifier")
    if on then
        if not C2.powerWas then C2.powerWas = { e = e and e:getValue(), w = w and w:getValue(), hydro = getWorld():isHydroPowerOn() } end
        if e then pcall(function() e:setValue(99999) end) end
        if w then pcall(function() w:setValue(99999) end) end
        pcall(function() so:toLua() end)
        pcall(function() getWorld():setHydroPowerOn(true) end)
    elseif C2.powerWas then
        if e and C2.powerWas.e then pcall(function() e:setValue(C2.powerWas.e) end) end
        if w and C2.powerWas.w then pcall(function() w:setValue(C2.powerWas.w) end) end
        pcall(function() so:toLua() end)
        pcall(function() getWorld():setHydroPowerOn(C2.powerWas.hydro) end)
        C2.powerWas = nil
    end
end
-- the light switches in the house's rooms on (the ones switched kept, switched off again by C2.back)
function C2.lights(Q, H)
    C2.switched = C2.switched or {}
    if not H then return end
    local n = 0
    for _, l in pairs(H.e.rooms) do
        for _, q in ipairs(l) do
            for dy = -1, 1 do for dx = -1, 1 do
                local sq = C2.sq(q[1] + dx, q[2] + dy, 0)
                pcall(function()
                    local objs = sq:getObjects()
                    for i = 0, objs:size() - 1 do
                        local o = objs:get(i)
                        if instanceof(o, "IsoLightSwitch") and not o:isActivated() then
                            local dup = false
                            for _, s in ipairs(C2.switched) do if s == o then dup = true end end
                            if not dup then
                                o:setActive(true)
                                if o:isActivated() then C2.switched[#C2.switched + 1] = o; n = n + 1 end
                            end
                        end
                    end
                end)
            end end
        end
    end
    Q.say("light switches turned on: " .. n)
end
function C2.clim(vals)
    C2.climWas = C2.climWas or {}
    local cm = getClimateManager()
    for i = 0, cm:getFloatMax() - 1 do
        local v = cm:getClimateFloat(i)
        local want = vals[tostring(v:getName())]
        if want ~= nil then
            local seen = false
            for _, c in ipairs(C2.climWas) do if c.v == v then seen = true end end
            if not seen then C2.climWas[#C2.climWas + 1] = { v = v, en = v:isEnableAdmin(), val = v:getAdminValue() } end
            pcall(function() v:setEnableAdmin(true); v:setAdminValue(want) end)
        end
    end
end
function C2.climBack()
    for _, c in ipairs(C2.climWas or {}) do pcall(function() c.v:setAdminValue(c.val); c.v:setEnableAdmin(c.en) end) end
    C2.climWas = {}
end
function C2.give(ft)
    C2.given = C2.given or {}
    local it = nil
    pcall(function() it = C2.p:getInventory():AddItem(ft) end)
    if it then C2.given[#C2.given + 1] = it end
    return it
end
function C2.takeBack()
    local n = 0
    for _, it in ipairs(C2.given or {}) do
        pcall(function() local c = it:getContainer(); if c then c:Remove(it); n = n + 1 end end)
    end
    C2.given = {}
    return n
end
-- where the run began (the QA home): kept once per script, put back by C2.back
function C2.save(Q)
    C2.was = { x = C2.p:getX(), y = C2.p:getY(), z = C2.p:getZ(), tod = getGameTime():getTimeOfDay(), speed = getGameSpeed(),
               prim = C2.p:getPrimaryHandItem(), sec = C2.p:getSecondaryHandItem(), open = C2.isOpen() }
    pcall(function() C2.was.zda = C2.p:isZombiesDontAttack() end)
    Q.say(string.format("start at %d,%d,%d | %s | look %s %s", math.floor(C2.was.x), math.floor(C2.was.y), math.floor(C2.was.z),
        C2.loadLine(), tostring(ZeD and ZeD.currentBase), tostring(ZeD and ZeD.currentAccent)))
end
function C2.back(Q)
    local W = C2.was or {}
    C2.closeMenus()
    pcall(function() ISTimedActionQueue.clear(C2.p) end)
    pcall(function() C2.p:setPrimaryHandItem(W.prim); C2.p:setSecondaryHandItem(W.sec) end)
    local n = C2.takeBack()
    for _, o in ipairs(C2.switched or {}) do pcall(function() o:setActive(false) end) end
    local nl = #(C2.switched or {})
    C2.switched = {}
    C2.power(false)
    C2.climBack()
    pcall(function() C2.charTab("loot"); C2.worldTab("loot") end)
    C2.winsBack(Q)
    if W.open ~= nil and W.open ~= C2.isOpen() then pcall(ZeD_CharacterWindow.toggleBothPaired, C2.pn) end
    if W.x then C2.tp(W.x, W.y, W.z) end
    if W.tod then pcall(function() getGameTime():setTimeOfDay(W.tod) end) end
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    C2.rule()
    C2.placeName = nil
    Q.say(string.format("put back: %d things given taken away, %d light switches off, power and weather as they were, windows, place %d,%d",
        n, nl, math.floor(C2.p:getX()), math.floor(C2.p:getY())))
end
-- the trip to West Point: the store's middle, then the squares round it loaded (at most about 20 s)
function C2.goWestPoint(Q)
    Q.step(2, function()
        if C2.p:getVehicle() then pcall(function() C2.p:getVehicle():exit(C2.p); triggerEvent("OnExitVehicle", C2.p) end) end
        C2.tp(C2.STORE.cx + 0.5, C2.STORE.y1 + 6.5, 0)
        Q.say("to West Point: the Fossoil's street")
    end)
    Q.waitFor(30, 1200, function() return C2.loaded(C2.STORE.cx, C2.STORE.cy, 40) end, function(ok)
        Q.say("West Point loaded round the store: " .. tostring(ok))
    end)
    Q.step(120, function() end)
end

C2.log("helpers ready | ZeD " .. tostring(ZeD ~= nil and ZeD_CharacterWindow ~= nil) .. " | prelude car helpers " .. tostring(ZEDQA_CAR_READY ~= nil)
    .. " | load " .. C2.loadLine())
C2.k = 0
function C2.later()
    C2.k = C2.k + 1
    if C2.k < 10 then return end
    Events.OnTick.Remove(C2.later)
    C2.log("DONE")
end
Events.OnTick.Add(C2.later)
