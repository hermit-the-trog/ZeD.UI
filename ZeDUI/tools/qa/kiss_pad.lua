-- ZeDUI/tools/qa/kiss_pad.lua  (Nov 22 2026, QA; tag kssp): the KISS audit's pictures, CONTROLLER part. The KISS audit
-- (Keep It Super Simple) ranked the places where ZeD-GUI costs a time-poor new player extra steps; the director makes
-- each design call from a report page, and each call needs one honest in-game picture of the friction as a player
-- meets it today. Pictures to Zomboid/Screenshots/kiss_<name>.png (kiss_pics_run.ps1 -Part pad moves them to
-- Screenshots/kiss_report/<name>.png). Manifest kiss_pics_pad.txt (the story stage at the West Point Fossoil,
-- gallery_unload.lua, G1, hfr_common.lua), 4K full screen. Style, theme and every other look setting as the staging
-- left them: no picture here is about a ZeD setting, so none is changed (the Style in use is said in 18's line).
--   08_pad_y_own_bags        on a pad Y lands in his own bags, not on the crate in front of him: he stands at the
--                            store's own counter, food put in it, both windows closed and the Floor the World window's
--                            last container; one Y: both windows up, the pad's mark on the Character window's first
--                            row, the World window on the Floor (the counter one button on its strip, not shown)
--   14_pad_switch_pops       a pad press after the mouse pops both windows open: both closed, ZeD on the mouse, then
--                            the switch to the controller: both open, the pad's mark on the first inventory row, he
--                            out in the open
--   15_crafting_opens_stove  Crafting opens the stove: a stove placed beside him, planks and a hammer carried; the World
--                            wheel (D-pad Right), Craft and build, then Crafting, each pointed and taken through the
--                            wheel's own commit (the stick's let-go, A with Hold or Toggle): the World window on its
--                            Craft tab bound to the stove (the stove's panel), not his recipes
--   18_pad_to_floor          Loot all sits under the last row, next to To floor: a fridge placed beside him, beyond him
--                            from the camera, with ten foods (ten rows), the World window on it, the pad's focus walked
--                            down past the last row into the buttons under the list and onto To floor (a walk that
--                            stops anywhere else is a SKIP)
--   20_pad_social_in_car     the car's wheel moved off D-pad Up: a pickup spawned on the open patch, he in its driver's
--                            seat, D-pad Up: ZeD's Social wheel (gestures, Shout) over the driver's seat, nothing pointed
--   21_pad_char_wheel        swapping weapons takes one more flick than the game: a bat and an axe carried, D-pad
--                            Left's Character wheel open, Weapons one slice of the ring (pointed, so its balloon names
--                            it) and no weapon on the ring itself
-- How it stages: no controller is plugged in. ZeD's input mode is locked to the controller (ZeD.Input.Detector
-- .setLockedMode, as bxr_menus.lua and gallery_v1_b_pad.lua do) and each press goes through ZeD's own handler for it:
-- the Y through FocusManager's own poll, its QA hook holding the button (Focus.qaButton); the switch from the mouse
-- through the detector's own switchMode (the lock's branch of its tick) and the ZeD_InputModeChanged event it fires;
-- the D-pad wheels through ISDPadWheels.onDisplay* (what the D-pad press calls), a slice pointed with ZeD.Wheel.qaPoint
-- and taken by the wheel's own commit (ZeD.WheelGesture.commit: the stick's let-go, A with Hold or Toggle); D-pad Down
-- and Right in a window
-- through Focus.dispatchJoypadDir (where the pad's D-pad reaches a ZeD window). The pointer the game's Lua reads is
-- parked off every window for the whole run (getMouseX / getMouseY swapped before any pad mark shows: Mouse.setXY does
-- not move it) and the real one is hidden; a window over him goes to the screen's edge for its picture (said in its
-- line) and back after. 08 at the store's own counter (else a crate placed on the patch); the rest on the open patch
-- by the story's smoking spot (bxr_menus.lua's S.findPatch), the stove, the fridge and the pickup placed there (never
-- the cars parked at the pumps). Every container food goes into is marked explored first (the World window fills an
-- unexplored one with loot). Before each picture it waits out the debug build's red error box (no new Lua error for
-- 3.6 s) and, as bxr_inv.lua's S.notesRead does, marks any unread Messages note read and dismisses an error balloon
-- (nothing is taken out of Messages; the read mark is not put back). Each picture prints "ZEDQA kssp SHOT <name> |
-- what is in it" or "ZEDQA kssp SKIP <name> | why".
-- What it puts back: the counter's own things and its explored mark, the stove, fridge or crate placed and the food
-- in them, the pickup (he out of it first, its removal ticks later), the things given (planks, hammer, bat, axe), his
-- hands, the Stations binding, the wheels shut and ZeD.Wheel.qaPoint, the pad's Y hook, the input mode lock and the
-- mode the detector read at the start, the pad's aim hold, the pointer the game reads, the zoom, the windows' places,
-- the tabs (Loot) and the pair open or shut as found, the pad's holder as found, the game speed, the error watch and the mode
-- listener; he ends on the square he was found on, standing, alive, whole and out of any car. grep "ZEDQA kssp".
local S = HFR and HFR.init and HFR.init("kssp")
if not S then return end
S.DIR = "kiss_"
local Q = S.Q
S.D, S.W, S.G, S.ST = ZeD.DpadWheels, ZeD.Wheel, ZeD.WheelGesture, ZeD.Stations
S.Det = ZeD.Input and ZeD.Input.Detector
S.Focus = ZeD.Input and ZeD.Input.Focus
S.objs, S.boxes, S.taken, S.modeLog = {}, {}, {}, {}
S.was.pos = {}
S.STOVES = { "appliances_cooking_01_0", "appliances_cooking_01_8" }
-- (the fridge-freezer's tiles: 0 and 4 face south, 1 and 5 east, as bxr_inv.lua places them)
S.FRIDGE_N = { "appliances_refrigeration_01_0", "appliances_refrigeration_01_4" }
S.FRIDGE_W = { "appliances_refrigeration_01_1", "appliances_refrigeration_01_5" }
S.CRATE = "carpentry_01_16"
-- (every one checked in media/scripts/generated/items/food.txt, module Base, ItemType base:food)
S.FOOD_COUNTER = { "Base.Bread", "Base.Cheese", "Base.TinnedBeans", "Base.Apple", "Base.Crisps" }
S.FOOD_FRIDGE = { "Base.Cheese", "Base.Butter", "Base.Ham", "Base.Salami", "Base.Egg", "Base.Steak", "Base.Lettuce",
                  "Base.Tomato", "Base.Carrots", "Base.Yoghurt" }

if not (S.D and S.D.open and S.D.state and S.D.H and S.W and S.W.isOff and S.G and S.G.commit and S.ST and S.ST.nearby
        and S.ST.current and S.ST.unbind and S.Det and S.Det.setLockedMode and S.Det.getMode and S.Focus and S.Focus.qaButton
        and S.Focus._st and S.Focus.dispatchJoypadDir and S.Focus.focusWhere and S.Focus.claimFocus and S.Focus.getFocusedZone
        and S.WWm and S.WWm.selectContainer and S.WWm.getFloorContainer and S.WWm.isTabShowing and S.CWm
        and S.CWm.ensureBothOpenForGamepad and S.Focus.getFocusedWindow and S.Focus.getFocusedElement and S.Focus.releaseFocus
        and S.Focus.cuesVisible) then
    Q.say("ERR ZeD's wheels, pad focus, input detector, stations or windows are not loaded as this script expects")
    Q.start()
    return
end

-- ===================================================================== helpers
-- (bxr_inv.lua's error watch: the debug build's red ERROR box is drawn for three seconds after every error and is no
-- UI element; a picture waits until no new error has come for 3.6 s)
S.errN, S.errAt = nil, -100000
function S.errWatch()
    local n = nil
    if getLuaDebuggerErrorCount then n = getLuaDebuggerErrorCount() end
    if n ~= nil and n ~= S.errN then
        if S.errN ~= nil then S.errAt = getTimestampMs() end
        S.errN = n
    end
end
function S.quiet() S.errWatch(); return getTimestampMs() - S.errAt > 3600 end
Events.OnPreUIDraw.Add(S.errWatch)
-- (bxr_inv.lua's S.notesRead: no unread error note on the belt in a picture; nothing is taken out of Messages)
function S.notesRead()
    local M = ZeD.Messages
    if not (M and M.unread and M.markAllRead) then return end
    if M.readErrors then pcall(M.readErrors) end
    local un, err = nil, nil
    pcall(function() un, err = M.unread() end)
    if (un or 0) > 0 then pcall(M.markAllRead) end
    local gone = 0
    if M.toasts and M.dropToast then
        for i = #M.toasts, 1, -1 do
            local t = M.toasts[i]
            if t and t.kind == "crit" then pcall(M.dropToast, t); gone = gone + 1 end
        end
    end
    if (un or 0) > 0 or gone > 0 then
        Q.say("note: before the picture " .. tostring(un) .. " unread message(s) marked read (an error among them " .. tostring(err)
            .. "), " .. gone .. " error balloon(s) dismissed")
    end
end
function S.pic(name, what)
    S.notesRead()
    if not S.quiet() then
        Q.say("NOTE " .. name .. ": a Lua error came " .. tostring(getTimestampMs() - S.errAt) .. " ms before the picture: the game's red ERROR box may be in it")
    end
    S.shot(name)
    S.taken[#S.taken + 1] = name
    Q.say("SHOT " .. name .. " | " .. tostring(what))
end
function S.skip(name, why) Q.notTaken(name, why); Q.say("SKIP " .. name .. " | " .. tostring(why)) end
-- the windows the same for 30 drawn frames and no new error for 3.6 s (at most 900 frames), then fn
function S.still(n, fn)
    local st = { same = 0 }
    Q.waitFor(n, 900, function()
        local s = G1.shape()
        if s == st.last then st.same = st.same + 1 else st.last, st.same = s, 0 end
        return st.same >= 30 and S.quiet()
    end, fn)
end
-- time, not frames (bxr_menus.lua): cond asked every 100 ms, at most ms; fn(true) when cond came true
function S.wait(ms, cond, fn)
    local st = {}
    Q.waitFor(1, 400000, function()
        local now = getTimestampMs()
        st.t = st.t or now
        if st.last and now - st.last < 100 then return false end
        st.last = now
        local ok, r = pcall(cond)
        if ok and r then st.ok = true; return true end
        return now - st.t >= ms
    end, function() fn(st.ok == true) end)
end
-- the camera has stopped after a move: his place on screen the same for 20 drawn frames (at most 900)
function S.settle(on)
    local st = { same = 0 }
    Q.waitFor(5, 900, function()
        if on and not on() then return true end
        if S.p:getCurrentSquare() == nil then return false end
        local v = math.floor(isoToScreenX(S.pn, S.p:getX(), S.p:getY(), 0)) .. "," .. math.floor(isoToScreenY(S.pn, S.p:getX(), S.p:getY(), 0))
        if v == st.last then st.same = st.same + 1 else st.last, st.same = v, 0 end
        return st.same >= 20
    end, function() end)
end
function S.fl(v) return math.floor(tonumber(v) or 0) end
function S.zoom()
    local z = 1
    pcall(function() z = S.core:getZoom(S.pn) end)
    if not z or z <= 0 then z = 1 end
    return z
end
function S.sqAt(x, y) return getCell():getGridSquare(x, y, 0) end
function S.nm(it)
    if it == nil then return "?" end
    local n = nil
    pcall(function() n = it:getDisplayName() end)
    return tostring(n or "?")
end
-- ----- the open patch (bxr_menus.lua's: a bare square in the open, the band toward the camera open)
function S.goodSq(sq)
    local good = false
    pcall(function()
        good = sq ~= nil and sq:getFloor() ~= nil and sq:isFree(false) and not sq:HasTree() and sq:isOutside()
            and sq:getRoom() == nil and sq:getObjects():size() <= 3 and sq:getWorldObjects():size() == 0
            and sq:getVehicleContainer() == nil and sq:getMovingObjects():size() == 0
    end)
    return good and sq or nil
end
S.AHEAD = { { 2, 0 }, { 0, 2 }, { 2, 1 }, { 1, 2 }, { 2, 2 }, { 3, 1 }, { 1, 3 }, { 3, 2 }, { 2, 3 }, { 3, 3 } }
function S.clearAhead(x, y)
    for _, o in ipairs(S.AHEAD) do
        local sq = S.sqAt(x + o[1], y + o[2])
        local ok = false
        if sq then
            pcall(function() ok = sq:isOutside() and sq:getRoom() == nil and not sq:HasTree() and sq:getVehicleContainer() == nil end)
        end
        if not ok then return false end
    end
    return true
end
function S.patchAt(x, y, lo, hi)
    for dy = lo, hi do
        for dx = lo, hi do
            if not S.goodSq(S.sqAt(x + dx, y + dy)) then return false end
        end
    end
    return true
end
function S.findPatch(cx, cy)
    for _, r in ipairs({ { -3, 2 }, { -2, 2 } }) do
        local best, bs = nil, 1e9
        for dy = -14, 14 do
            for dx = -14, 14 do
                local sc = math.abs(dx) + math.abs(dy) - (dx + dy) * 0.25
                if sc < bs and S.patchAt(cx + dx, cy + dy, r[1], r[2]) and S.clearAhead(cx + dx, cy + dy) then best, bs = { x = cx + dx, y = cy + dy, lo = r[1] }, sc end
            end
        end
        if best then return best end
    end
    return nil
end
function S.home(dir) if S.c then G1.tp({ S.c.x, S.c.y }, dir or "SE") end end
-- the camera's zoom to get() (nil: left as it is), a quarter step a frame as G1's Q.zoomTo (bxr_menus.lua)
function S.zoomDyn(get)
    local st = {}
    Q.waitFor(2, 1200, function()
        if st.left == nil then
            local z = get()
            st.left = z and math.floor((S.core:getZoom(S.pn) - z) / 0.25 + 0.5) or 0
            st.moved = st.left ~= 0
        end
        if st.left == 0 then return true end
        S.core:doZoomScroll(S.pn, (st.left > 0) and -1 or 1)
        st.left = (st.left > 0) and (st.left - 1) or (st.left + 1)
        return st.left == 0
    end, function() end)
    Q.waitFor(1, 200, function()
        if not st.moved then return true end
        st.n = (st.n or 0) + 1
        return st.n >= 100
    end, function() if st.moved then Q.say("zoom " .. tostring(S.core:getZoom(S.pn))) end end)
end

-- ----- the store's counter (08): the story's own first (STORY.P.counter, gallery_story_stage.lua's plan), then the
-- store's other counters (STORY.F.counters). He stands on the square beside it toward the camera (east of it, facing
-- west; else south of it, facing north): store floor, free, that reaches the counter. Pass 1: the six squares toward
-- the camera of him bare store floor (bxr_inv.lua's FRONT6: nothing drawn in front of him); pass 2: the three next to
-- him free
S.FRONT6 = { { 1, 0 }, { 0, 1 }, { 1, 1 }, { 2, 1 }, { 1, 2 }, { 2, 2 } }
-- (the store's room, as the story's STORY.inRoom reads it: inside the site's box and a room named fossoil; read here
-- with every call that can give nil tested first)
function S.inStore(x, y)
    local s = STORY and STORY.site
    if not (s and x >= s.x0 and x <= s.x1 and y >= s.y0 and y <= s.y1) then return false end
    local sq = S.sqAt(x, y)
    local room = sq and sq:getRoom() or nil
    local name = nil
    if room then pcall(function() name = room:getName() end) end
    return name ~= nil and string.find(string.lower(tostring(name)), "fossoil", 1, true) ~= nil
end
function S.storeFree(x, y)
    local q = S.sqAt(x, y)
    if not q then return false end
    local ok = false
    pcall(function() ok = q:isFree(false) and q:getVehicleContainer() == nil end)
    return ok == true
end
-- (and no body on it: bxr_menus.lua's floor test reads the static moving objects too, a corpse among them; the
-- zombies near the store are taken away at the start, and he may stand on one of these squares while it is asked)
function S.storeBare(x, y)
    if not (S.inStore(x, y) and S.storeFree(x, y)) then return false end
    local q = S.sqAt(x, y)
    local n, w, m = 9, 9, 9
    pcall(function() n = q:getObjects():size(); w = q:getWorldObjects():size() end)
    pcall(function() m = q:getStaticMovingObjects():size() end)
    return n <= 1 and w == 0 and m == 0
end
function S.standOk(x, y, e, pass)
    local here, there = S.sqAt(x, y), S.sqAt(e.x, e.y)
    if not (here and there and S.inStore(x, y) and S.storeFree(x, y)) then return false end
    local reach = false
    pcall(function() reach = here:canReachTo(there) end)
    if not reach then return false end
    for k, d in ipairs(S.FRONT6) do
        if pass == 1 and not S.storeBare(x + d[1], y + d[2]) then return false end
        if pass == 2 and k <= 3 and not S.storeFree(x + d[1], y + d[2]) then return false end
    end
    return true
end
function S.counterSpot()
    local F, pc = (STORY and STORY.F) or {}, S.P.counter
    local list = {}
    for _, e in ipairs(F.counters or {}) do
        if e.inv then
            if pc and e.x == pc[1] and e.y == pc[2] then table.insert(list, 1, e) else list[#list + 1] = e end
        end
    end
    for pass = 1, 2 do
        for _, e in ipairs(list) do
            for _, f in ipairs({ { 1, 0, "W", "east" }, { 0, 1, "N", "south" } }) do
                if S.standOk(e.x + f[1], e.y + f[2], e, pass) then
                    return { e = e, x = e.x + f[1], y = e.y + f[2], face = f[3], side = f[4], pass = pass,
                             own = pc ~= nil and e.x == pc[1] and e.y == pc[2] }
                end
            end
        end
    end
    return nil
end

-- ----- placed tiles (bxr_menus.lua / bxr_inv.lua / bxr_craft.lua), every one kept in S.objs and taken off at the end
function S.removeObj(o)
    if not o then return end
    local sq = nil
    pcall(function() sq = o:getSquare() end)
    if sq then
        pcall(function() if sq:getObjects():contains(o) then sq:RemoveTileObject(o) end end)
        pcall(function() if sq:getObjects():contains(o) then sq:transmitRemoveItemFromSquare(o) end end)
    end
end
function S.removeAll()
    for _, o in ipairs(S.objs) do S.removeObj(o) end
    S.objs = {}
end
function S.standing()
    local n = 0
    for _, o in ipairs(S.objs) do pcall(function() if o:getSquare() ~= nil and o:getSquare():getObjects():contains(o) then n = n + 1 end end) end
    return n
end
-- every container of a placed thing explored: the World window fills an unexplored one with loot as it lists it
-- (ZeD_WorldWindow.lua:2987-2994)
function S.explore(o)
    local n = 0
    pcall(function() n = o:getContainerCount() end)
    for ci = 0, n - 1 do
        pcall(function() local c = o:getContainerByIndex(ci); if c then c:setExplored(true) end end)
    end
end
-- a stove (bxr_menus.lua's S.placeStove: IsoStove.new(cell, square, sprite)); ZeD.Stations takes it for an oven
function S.placeStove(sq)
    for _, name in ipairs(S.STOVES) do
        local spr = getSprite(name)
        if spr then
            local o = nil
            pcall(function()
                o = IsoStove.new(getCell(), sq, spr)
                pcall(function() o:createContainersFromSpriteProperties() end)
                sq:AddSpecialObject(o)
                if o:getObjectIndex() < 0 then sq:AddTileObject(o) end
            end)
            local on = false
            pcall(function() on = o ~= nil and sq:getObjects():contains(o) end)
            if on then S.objs[#S.objs + 1] = o; S.explore(o); return o, name end
        end
    end
    return nil
end
-- a fridge-freezer (bxr_inv.lua's way: IsoObject.new(square, sprite, nil, false)); its fridge container
function S.placeFridge(sq, names)
    for _, name in ipairs(names) do
        if getSprite(name) then
            local o, inv = nil, nil
            pcall(function()
                o = IsoObject.new(sq, name, nil, false)
                sq:AddTileObject(o)
                o:createContainersFromSpriteProperties()
            end)
            if o then
                pcall(function() inv = o:getContainerByType("fridge") end)
                if not inv then pcall(function() inv = o:getContainer() end) end
                if inv then S.objs[#S.objs + 1] = o; S.explore(o); return o, inv, name end
                S.removeObj(o)
            end
        end
    end
    return nil
end
-- a wooden crate (bxr_craft.lua's S.setCrate: IsoObject.new(cell, square, "carpentry_01_16"))
function S.placeCrate(sq)
    local o, inv = nil, nil
    pcall(function()
        o = IsoObject.new(getCell(), sq, S.CRATE)
        o:createContainersFromSpriteProperties()
        sq:AddTileObject(o)
    end)
    if o then pcall(function() inv = o:getContainer() end) end
    if o and not inv then S.removeObj(o); return nil end
    if o then S.objs[#S.objs + 1] = o; S.explore(o) end
    return o, inv
end
-- food into a container for a picture: what it held set aside (kept, put back by S.boxBack), the container marked
-- explored (its own mark kept), the food put in
function S.fillBox(inv, foods)
    if not inv then return nil end
    local b = { inv = inv, was = {}, added = {} }
    pcall(function() b.explored = inv:isExplored() and true or false end)
    pcall(function() inv:setExplored(true) end)
    pcall(function()
        local items = inv:getItems()
        for i = 0, items:size() - 1 do b.was[#b.was + 1] = items:get(i) end
    end)
    for _, it in ipairs(b.was) do pcall(function() inv:Remove(it) end) end
    for _, ft in ipairs(foods) do
        local it = nil
        pcall(function() it = inv:AddItem(ft) end)
        if it then b.added[#b.added + 1] = it end
    end
    S.boxes[#S.boxes + 1] = b
    return b
end
function S.boxBack(b)
    if not b or b.back then return end
    b.back = true
    for _, it in ipairs(b.added) do pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    for _, it in ipairs(b.was) do pcall(function() b.inv:AddItem(it) end) end
    if b.explored == false then pcall(function() b.inv:setExplored(false) end) end
end
function S.boxesBack() for _, b in ipairs(S.boxes) do S.boxBack(b) end end
function S.boxWords(b)
    local t = {}
    for _, it in ipairs((b and b.added) or {}) do t[#t + 1] = S.nm(it) end
    return table.concat(t, ", ")
end

-- ----- the pointer the game's Lua reads (bxr_menus.lua): Mouse.setXY does not move it, so it is swapped
function S.mouseOn(x, y)
    S.fx, S.fy = x, y
    if S.mouseSwapped then return end
    S.realMX, S.realMY = getMouseX, getMouseY
    S.mouseSwapped = true
    getMouseX = function() return S.fx end
    getMouseY = function() return S.fy end
end
function S.mouseOff()
    if not S.mouseSwapped then return end
    getMouseX, getMouseY = S.realMX, S.realMY
    S.mouseSwapped = false
end

-- ----- the input mode ZeD reads (bxr_menus.lua): the lock as found is ZeD setup's Input lock ("auto": none)
function S.lockFound()
    local key = nil
    pcall(function()
        local o = S.opt("inputModeLock")
        local keys = ZeD.Settings.inputLockKeys
        if o and keys then key = keys[o:getValue() or 1] end
    end)
    if key == nil then pcall(function() local md = S.p:getModData().ZeD_Gamepad; key = md and md.inputModeLock end) end
    return key or "auto"
end
-- mode "kbm" or "gamepad" (InputModeDetector.lua:358 setLockedMode; its tick's lock branch, 274-281, makes the
-- switch through switchMode, 239, and fires ZeD_InputModeChanged); nil or false puts back the lock found
function S.lock(mode)
    pcall(function()
        if S.lockWas == nil then S.lockWas = S.lockFound() end
        if mode then
            S.Det.setLockedMode(mode)
            S.locked = true
            return
        end
        if not S.locked then return end
        S.locked = false
        S.Det.setLockedMode(nil)
        if S.lockWas == "kbm" or S.lockWas == "gamepad" then S.Det.setLockedMode(S.lockWas) end
    end)
end
function S.modeNow() local m = "?"; pcall(function() m = tostring(S.Det.getMode(S.pn)) end); return m end
-- every switch the detector makes, as ZeD's own listeners hear it (Events.ZeD_InputModeChanged)
function S.modeHeard(newMode, oldMode)
    S.modeLog[#S.modeLog + 1] = { t = getTimestampMs(), new = tostring(newMode), old = tostring(oldMode) }
end
function S.modeSince(t0, mode)
    for _, e in ipairs(S.modeLog) do if e.t >= t0 and e.new == mode then return e end end
    return nil
end

-- ----- the windows
function S.pairOpenNow() return S.CWm.isOpen(S.pn) and S.WWm.isOpen(S.pn) end
function S.pairShutNow() return not S.CWm.isOpen(S.pn) and not S.WWm.isOpen(S.pn) end
function S.holder()
    local fw = S.Focus.getFocusedWindow(S.pn)
    if not fw then return "game (no window holds the pad)" end
    return tostring(fw._zedLabel or fw.Type or "a") .. " window"
end
-- a window over him to the screen's edge (G1.clear, logged); its place first kept for S.posBack
function S.aside()
    local moved = {}
    for _, k in ipairs({ "c", "w" }) do
        local win = (k == "c") and S.CW() or S.WW()
        if win and win:isVisible() and G1.covers(win) then
            if not S.was.pos[k] then S.was.pos[k] = { x = win:getX(), y = win:getY(), a = win._anchorRightEdge } end
            G1.clear(Q, win, (k == "c") and "left" or "right", (k == "c") and "the Character window" or "the World window")
            moved[#moved + 1] = (k == "c") and "the Character window to the left edge" or "the World window to the right edge"
        end
    end
    return (#moved > 0) and ("; NOTE moved aside for the picture, it covered him: " .. table.concat(moved, ", ")) or ""
end
function S.posBack()
    for _, k in ipairs({ "c", "w" }) do
        local win = (k == "c") and S.CW() or S.WW()
        local was = S.was.pos[k]
        if win and was and (win:getX() ~= was.x or win:getY() ~= was.y) then
            pcall(function()
                win:setX(was.x)
                win:setY(was.y)
                if win._anchorRightEdge ~= nil then win._anchorRightEdge = was.a or (was.x + win:getWidth()) end
            end)
        end
    end
end
-- the windows shut, the wheel shut, the pad let go, the real pointer parked where no UI element covers it
-- (bxr_menus.lua's S.toWheel)
function S.shut()
    S.closeWheel()
    pcall(S.Focus.releaseFocus, S.pn)
    S.closePair()
    pcall(S.Focus.releaseFocus, S.pn)
    pcall(function() setJoypadFocus(S.pn, nil) end)
    if GAL_UNLOAD and GAL_UNLOAD.park then pcall(GAL_UNLOAD.park) end
end
-- what the pad's focus is on in a window: its zone, the element, the list's rows (elements carrying .item) and which
-- of them it is (row; nil off the rows)
function S.focusInfo(win)
    local out = { zone = "none", idx = 0, first = nil, n = 0, name = "?" }
    local z = win and S.Focus.getFocusedZone(win)
    if not z then return out end
    out.zone = tostring(z.zone)
    out.idx = z.focusedElementIdx or 1
    for i, e in ipairs(z.elements or {}) do
        if e.item then
            out.n = out.n + 1
            if not out.first then out.first = i end
            if i == out.idx then out.row = out.n end
        end
    end
    local el = z.elements and z.elements[out.idx]
    out.el = el
    if el and el.item then out.name = S.nm(el.item) elseif el then out.name = tostring(el.promptA or el.ccKey or el.id) end
    return out
end
function S.zoneOf(win, name)
    for _, z in ipairs((win and win._focusRing) or {}) do if z.zone == name then return z end end
    return nil
end
function S.rowsIn(win, name)
    local z = S.zoneOf(win, name)
    local n = 0
    for _, e in ipairs((z and z.elements) or {}) do if e.item then n = n + 1 end end
    return n
end
-- the World window's container on show
function S.activeCnt()
    local w = S.WW()
    if not (w and w._containers and w._activeContainer) then return nil end
    return w._containers[w._activeContainer]
end
function S.onFloor() local c = S.activeCnt(); return c ~= nil and c.isFloor == true end
function S.activeName() local c = S.activeCnt(); return c and tostring(c.name) or "nothing" end
function S.listsInv(inv)
    local w = S.WW()
    for _, c in ipairs((w and w._containers) or {}) do if inv and c.inventory == inv then return true end end
    return false
end
function S.showsInv(inv) local c = S.wc(); return inv ~= nil and c ~= nil and c._inventory == inv end
function S.floorCount()
    local f = S.WWm.getFloorContainer(S.pn)
    local n = 0
    if f then pcall(function() n = f:getItems():size() end) end
    return n
end
function S.styleWord() return (ZeD.Settings and ZeD.Settings.lite and ZeD.Settings.lite()) and "Lite" or "Full" end
-- the buttons under the World window's list as the pad reaches them (ContainerControls.lua:1176 CT.syncFocus: zone
-- worldCtl, one stop a button, in the band's order, ccKey take / same / floor for the moves, promptA its words)
function S.bandWords(w)
    local z = S.zoneOf(w, "worldCtl")
    local t = {}
    for _, e in ipairs((z and z.elements) or {}) do t[#t + 1] = tostring(e.promptA or e.ccKey) end
    return (#t > 0) and table.concat(t, " | ") or "nothing"
end
function S.floorWay(w)
    local z = S.zoneOf(w, "worldCtl")
    if not (z and S.Focus.getFocusedZone(w) == z) then return nil end
    local cur, fl = z.focusedElementIdx or 1, nil
    for i, e in ipairs(z.elements or {}) do if e.ccKey == "floor" then fl = i end end
    if not fl or fl == cur then return nil end
    return (fl > cur) and "right" or "left"
end
function S.lootAllFrom(w)
    local z = S.zoneOf(w, "worldCtl")
    local ti, fi = nil, nil
    for i, e in ipairs((z and z.elements) or {}) do
        if e.ccKey == "take" then ti = i elseif e.ccKey == "floor" then fi = i end
    end
    if not (ti and fi) then return "not both in the band" end
    local d = fi - ti
    if d == 1 then return "the button right beside it, on its left" end
    if d == -1 then return "the button right beside it, on its right" end
    return "Loot all " .. math.abs(d) .. " buttons " .. ((d > 0) and "left" or "right") .. " of it"
end
function S.stationWords()
    local cur = nil
    pcall(function() cur = S.ST.current(S.p) end)
    if not cur then return "no station (by hand)" end
    return tostring(cur.name) .. ", a station of kind " .. tostring(cur.kind)
end

-- ----- the wheels (bxr_menus.lua)
function S.wheelSt() return S.D.state and S.D.state[S.pn] or nil end
function S.closeWheel()
    pcall(function()
        local st = S.wheelSt()
        if st then pcall(S.D.close, S.pn) end
        st = S.wheelSt()
        if st and st.menu and st.menu.undisplay then st.menu:undisplay() end
        if S.D.state then S.D.state[S.pn] = nil end
        local m = getPlayerRadialMenu(S.pn)
        if m and m:isReallyVisible() then m:undisplay() end
    end)
    S.W.qaPoint = nil
end
-- a wheel opened as the D-pad press opens it (ISDPadWheels.onDisplay*: ZeD_DpadWheels.lua:406-425 puts ZeD's in
-- place of the game's, the same functions JoyPadSetup.lua's D-pad presses call); if the press's guards keep it shut,
-- ZeD's own opener (ZeD_DpadWheels.lua:382 D.open) as the press would call it, and S.how says so
function S.openWheel(dir, fn)
    pcall(function() ISDPadWheels[fn]({ player = S.pn, id = nil }) end)
    local st = S.wheelSt()
    if st and st.dir == dir then S.how = "ISDPadWheels." .. fn .. ", the D-pad press's own call"; return true end
    local ok, e = pcall(S.D.open, dir, { player = S.pn, id = nil })
    if not ok then Q.say("ERR open " .. dir .. ": " .. tostring(e)) end
    S.how = "ZeD.DpadWheels.open (the press's own call left it shut)"
    st = S.wheelSt()
    return st ~= nil and st.dir == dir
end
function S.slices()
    local st = S.wheelSt()
    return (st and st.menu and st.menu.slices) or {}
end
function S.firstLine(s)
    local t = tostring(s or "")
    local i = string.find(t, "\n", 1, true)
    if i then return string.sub(t, 1, i - 1) end
    return t
end
function S.sliceText(i)
    local s = S.slices()[i]
    return s and (string.gsub(tostring(s.text), "\n", " / ")) or "?"
end
function S.sliceStarting(word)
    for i, s in ipairs(S.slices()) do
        if tostring(s.text or ""):sub(1, #word) == word then return i end
    end
    return nil
end
function S.ringWords()
    local t = {}
    for _, s in ipairs(S.slices()) do
        local off = false
        pcall(function() off = S.W.isOff(s) and true or false end)
        t[#t + 1] = S.firstLine(s.text) .. (off and " (off)" or "")
    end
    return table.concat(t, ", ")
end
function S.crumb()
    local st = S.wheelSt()
    local lv = st and st.path and st.path[#st.path]
    return lv and tostring(lv.title) or "?"
end
-- the wheel is on screen with slice i pointed (-1: none); ZeD_Wheel.lua:463 W.update takes ZeD.Wheel.qaPoint
function S.wheelDrawn(i)
    local st = S.wheelSt()
    local m = st and st.menu
    local vis = false
    pcall(function() vis = m ~= nil and m:isReallyVisible() end)
    return vis and m._zedPoint == i
end
-- slice i taken as A takes it on the wheel: ZeD_WheelGesture.lua:273 G.commit, the wheel's own accept (viaButton): a
-- slice with its own ring opens it in place (ZeD_DpadWheels.lua:307 D.enter), any other closes the wheel and runs it
-- (347 D.take)
function S.accept(i)
    local st = S.wheelSt()
    if not (st and st.menu and i) then return false end
    local ok, e = pcall(S.G.commit, S.pn, st, i, true)
    if not ok then Q.say("ERR the wheel's accept: " .. tostring(e)) end
    return ok
end

-- ----- the pickup (20): a bare 3 x 7 footprint on or by the patch, not his square, no car within reach of it
S.CAR_AT = { { 3, 0 }, { -3, -1 }, { 0, -5 }, { 5, 0 }, { -5, 0 }, { 0, 5 }, { 5, -4 }, { -5, 4 } }
function S.carClear(cx, cy)
    for dy = -3, 3 do
        for dx = -1, 1 do
            local sq = S.sqAt(cx + dx, cy + dy)
            local ok = false
            if sq then
                pcall(function() ok = sq:isFree(false) and not sq:HasTree() and sq:getVehicleContainer() == nil and sq:getRoom() == nil and sq:isOutside() end)
            end
            if not ok then return false end
        end
    end
    -- (IsoCell.getVehicles is a Set: walked with its iterator, as zedqa_prelude.lua does)
    local near = false
    pcall(function()
        local it = getCell():getVehicles():iterator()
        while it:hasNext() do
            local v = it:next()
            if v and math.abs(v:getX() - (cx + 0.5)) < 4.5 and math.abs(v:getY() - (cy + 0.5)) < 7 then near = true end
        end
    end)
    return not near and S.clearAhead(cx, cy)
end
-- the listed places first; else the nearest clear footprint within 10 squares of the patch's middle whose 3 x 7 is
-- not his own square
function S.carSpot()
    for _, o in ipairs(S.CAR_AT) do
        local x, y = S.c.x + o[1], S.c.y + o[2]
        if S.carClear(x, y) then return S.sqAt(x, y) end
    end
    local best, bd = nil, 1e9
    for dy = -10, 10 do
        for dx = -10, 10 do
            local d = math.abs(dx) + math.abs(dy)
            local mine = math.abs(dx) <= 1 and math.abs(dy) <= 3
            if d >= 3 and d < bd and not mine and S.carClear(S.c.x + dx, S.c.y + dy) then best, bd = { S.c.x + dx, S.c.y + dy }, d end
        end
    end
    return best and S.sqAt(best[1], best[2]) or nil
end
-- (zedqa_prelude.lua:344 ZEDQA_CAR_READY: a square, a chunk, its physics seen awake once, within 25 squares)
function S.carReady(v)
    if not v then return false end
    if ZEDQA_CAR_READY then local ok, r = pcall(ZEDQA_CAR_READY, v); return ok and r == true end
    local ok, r = pcall(function() return v:getSquare() ~= nil and v:isPhysicsActive() end)
    return ok and r == true
end
-- the driver's seat, as beta21_report.lua:476 seats him (zedqa_prelude.lua:368 ZEDQA_CAR_ENTER refuses a car that is
-- not ready or is far: seating one drops the game to the main menu)
function S.carIn(v)
    if ZEDQA_CAR_ENTER then
        local okc, ok, why = pcall(ZEDQA_CAR_ENTER, v, 0)
        if not okc then return false, tostring(ok) end
        return ok == true, why
    end
    if not S.carReady(v) then return false, "the car is not ready" end
    pcall(function() v:enter(0, S.p); triggerEvent("OnEnterVehicle", S.p) end)
    return S.p:getVehicle() == v, "entered directly"
end
function S.carLive(v)
    if not v then return false end
    local live = false
    pcall(function()
        local it = getCell():getVehicles():iterator()
        while it:hasNext() do if it:next() == v then live = true end end
    end)
    return live
end
-- out of the car, and the car away ticks later (zedqa_prelude.lua:394 ZEDQA_CAR_AWAY: removing it in the tick of the
-- exit is a NullPointerException and the main menu; its sweep removes it two ticks on, with him out). Without the
-- prelude, S.carGone removes it itself, half a second after the exit, once (a second removal is never made)
function S.carAway(t)
    local v = t and t.car
    if not v or t.going then return end
    t.going = true
    t.awayAt = getTimestampMs()
    if ZEDQA_CAR_AWAY then pcall(ZEDQA_CAR_AWAY, v, nil); return end
    t.manual = true
    if S.p:getVehicle() == v then pcall(function() v:exit(S.p); triggerEvent("OnExitVehicle", S.p) end) end
end
function S.carGone(t)
    local v = t and t.car
    if not v then return true end
    if t.manual and not t.removed and S.p:getVehicle() ~= v and getTimestampMs() - (t.awayAt or 0) > 500 and S.carLive(v) then
        t.removed = true
        pcall(function() v:permanentlyRemove() end)
    end
    return not S.carLive(v)
end

-- ===================================================================== start
Q.step(5, function()
    S.was.at = { S.fl(S.p:getX()), S.fl(S.p:getY()) }
    S.start0()
    if getGameSpeed() ~= 1 then pcall(setGameSpeed, 1) end
    S.was.zoom = S.zoom()
    S.was.h1, S.was.h2 = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem()
    S.was.mode = S.modeNow()
    S.was.lock = S.lockFound()
    -- (which of the pair held the pad as found: put back at the end)
    do
        local fw = S.Focus.getFocusedWindow(S.pn)
        S.was.focus = (fw == nil) and "none" or ((fw == S.CW()) and "char" or ((fw == S.WW()) and "world" or "other"))
        S.was.focusWin = fw
    end
    pcall(function() S.was.ignoreAim = S.p:isJoypadIgnoreAimUntilCentered() end)
    if Events.ZeD_InputModeChanged then Events.ZeD_InputModeChanged.Add(S.modeHeard); S.heard = true end
    -- the pointer the game's Lua reads off every window for the whole run, set before any pad mark shows: the marks'
    -- own watch (FocusManager.lua:409 _watchCueMouse) takes a move of it for the mouse in use and hides them
    S.mouseOn(-9000, -9000)
    -- the mouse first: every picture's input mode is set from a known one
    S.lock("kbm")
    local c = S.P.smoke or S.P.centre
    S.c = S.findPatch(c[1], c[2])
    Q.say("found at " .. S.was.at[1] .. "," .. S.was.at[2] .. ", ZeD read the input as " .. tostring(S.was.mode) .. ", Input lock "
        .. tostring(S.was.lock) .. ", zoom " .. tostring(S.was.zoom) .. ", Style " .. S.styleWord() .. ", the pair open " .. tostring(S.was.pairOpen)
        .. " | the open patch " .. (S.c and (S.c.x .. "," .. S.c.y .. " (the smoking spot " .. c[1] .. "," .. c[2] .. ")") or "NOT FOUND: 14 to 21 are skipped")
        .. " | the story's counter " .. (S.P.counter and (S.P.counter[1] .. "," .. S.P.counter[2]) or "none")
        .. " | load " .. ((GAL_UNLOAD and GAL_UNLOAD.line) and GAL_UNLOAD.line() or "?"))
end)
Q.zoomTo(1.0)

-- ===================================================================== 08: Y lands in his own bags
S.p08 = { name = "08_pad_y_own_bags" }
Q.step(10, function()
    local t = S.p08
    S.shut()
    local spot = S.counterSpot()
    if spot then
        t.box = S.fillBox(spot.e.inv, S.FOOD_COUNTER)
        t.inv, t.what = spot.e.inv, "counter"
        t.where = "inside the store, at " .. (spot.own and "the story's own counter" or "one of the store's counters") .. " (" .. tostring(spot.e.t)
            .. " at " .. spot.e.x .. "," .. spot.e.y .. "), food put in it (" .. S.boxWords(t.box) .. "), he on the square " .. spot.side
            .. " of it facing it" .. ((spot.pass == 1) and ", the six squares toward the camera of him bare floor" or " (NOTE: no counter has the six squares toward the camera of him bare: check for things in front of him)")
        G1.tp({ spot.x, spot.y }, spot.face)
    elseif S.c then
        -- (no counter with a square for him: a crate on the patch, west of him)
        local sq = S.goodSq(S.sqAt(S.c.x - 1, S.c.y))
        local o, inv = nil, nil
        if sq then o, inv = S.placeCrate(sq) end
        if inv then
            t.box = S.fillBox(inv, S.FOOD_COUNTER)
            t.inv, t.what = inv, "crate"
            t.where = "NOTE on the open patch: no counter of the store has a free square on its camera side; a crate placed west of him, food put in it ("
                .. S.boxWords(t.box) .. "), he facing it"
            G1.tp({ S.c.x, S.c.y }, "W")
        end
    end
    if not (t.box and #t.box.added > 0) then
        S.skip(t.name, "no counter with a free square on its camera side, and no crate with food could be placed on the patch")
        t.off = true
        return
    end
    Q.say("08: " .. t.where)
end)
S.settle(function() return not S.p08.off end)
-- the controller: ZeD's input mode locked to it. The switch to it opens the pair by itself (14's friction): the
-- pair is shut again below, before the Y
Q.step(5, function() if not S.p08.off then S.lock("gamepad") end end)
S.wait(3000, function() return S.p08.off or S.pairOpenNow() end, function(ok)
    if S.p08.off then return end
    if not ok then S.openPair() end
end)
-- the Floor the World window's last container, as a player who looked at the floor before would have it
-- (ZeD_WorldWindow.lua:3556 getFloorContainer, 6332 selectContainer: the Loot pane on it, as a click on its button)
Q.step(10, function()
    local t = S.p08
    if t.off then return end
    local floor = S.WWm.getFloorContainer(S.pn)
    if floor then pcall(S.WWm.selectContainer, floor, 60, S.pn) end
end)
Q.step(20, function()
    local t = S.p08
    if t.off then return end
    t.floorBefore = S.onFloor() and "the Floor on show before they shut" or ("NOTE " .. S.activeName() .. " on show before they shut, not the Floor")
    S.shut()
end)
S.wait(3000, function() return S.p08.off or (S.pairShutNow() and S.Focus.getFocusedWindow(S.pn) == nil) end, function(ok)
    if S.p08.off then return end
    if not ok then S.skip(S.p08.name, "the pair did not shut before the Y"); S.p08.off = true end
end)
-- one Y, as ZeD reads the pad's Y with no window holding it: FocusManager.lua:2822-2856 _holdTicks arms the tap on the
-- press and fires _handleYTap (2407) on the release; the pad is QA's hook, Focus.qaButton (2751), on a rig with no
-- pad bound. Let go as soon as the press is armed, well inside the 400 ms hold (a hold closes every window)
Q.step(20, function()
    local t = S.p08
    if t.off then return end
    t.y0 = getTimestampMs()
    S.Focus.qaButton("Y", true, S.pn)
    S.qaY = true
end)
Q.waitFor(1, 120, function()
    if S.p08.off then return true end
    local s = S.Focus._st[S.pn]
    return s ~= nil and s.yHeld == true
end, function(ok)
    local t = S.p08
    if t.off then return end
    t.armed = ok
    S.Focus.qaButton("Y", false, S.pn)
    t.yMs = getTimestampMs() - (t.y0 or getTimestampMs())
end)
S.wait(4000, function() return S.p08.off or (S.pairOpenNow() and S.Focus.getFocusedWindow(S.pn) == S.CW()) end, function(ok)
    if S.qaY then S.Focus.qaButton("Y", nil, S.pn); S.qaY = nil end   -- (the pad's Y handed back)
    S.p08.open = ok
end)
S.still(10, function() if not S.p08.off and S.p08.open then S.p08.aside = S.aside() end end)
S.still(5, function()
    local t = S.p08
    if t.off then return end
    if not t.open then
        S.skip(t.name, "one Y did not bring the pair up with the pad on the Character window (the press armed " .. tostring(t.armed)
            .. ", ZeD reads " .. S.modeNow() .. ", the pad on the " .. S.holder() .. ", the pair open " .. tostring(S.pairOpenNow()) .. ")")
        return
    end
    local fi = S.focusInfo(S.CW())
    local first = fi.zone == "charMainInv" and fi.first ~= nil and fi.idx == fi.first
    S.pic(t.name, t.where .. "; both windows shut, " .. tostring(t.floorBefore) .. "; one Y as ZeD reads the pad's Y (its own poll, the press held"
        .. " through its QA button hook, no pad plugged in; a tap, let go " .. tostring(t.yMs) .. " ms after the press): both windows up, the pad's mark on the Character window's "
        .. (first and "first row" or ("NOTE row " .. tostring(fi.idx) .. " of zone " .. fi.zone .. ", not the first row"))
        .. " (" .. fi.name .. ", " .. fi.n .. " rows in his bags' list), marks showing " .. tostring(S.Focus.cuesVisible(S.pn))
        .. "; the World window on " .. (S.onFloor() and ("the Floor (" .. S.floorCount() .. " things on it)") or ("NOTE " .. S.activeName() .. ", not the Floor"))
        .. ", the " .. tostring(t.what) .. " in front of him " .. (S.listsInv(t.inv) and "one button on its strip, its food not shown" or "NOTE not on its strip")
        .. tostring(t.aside or ""))
end)
Q.step(10, function()
    S.posBack()
    S.shut()
    S.boxBack(S.p08.box)
    S.removeAll()
end)

-- ===================================================================== 14: a pad press after the mouse pops both open
S.p14 = { name = "14_pad_switch_pops" }
Q.step(10, function()
    local t = S.p14
    if not S.c then S.skip(t.name, "no open patch near the store"); t.off = true; return end
    S.shut()
    S.home("SE")
    -- the mouse: ZeD's input mode on the mouse and keyboard, as a click or a key sets it
    t.k0 = getTimestampMs()
    S.lock("kbm")
end)
S.settle(function() return not S.p14.off end)
S.wait(3000, function() return S.p14.off or (S.modeSince(S.p14.k0, "kbm") ~= nil and S.pairShutNow()) end, function(ok)
    local t = S.p14
    if t.off then return end
    S.shut()
    local e = S.modeSince(t.k0, "kbm")
    t.kbm = e and (e.old .. " -> " .. e.new) or ("no switch heard, ZeD reads " .. S.modeNow())
end)
-- (the detector's cooldown between two switches is 200 ms: InputModeDetector.lua:246)
S.wait(600, function() return S.p14.off end, function() end)
-- the switch to the controller, as a pad press after the mouse makes it: the lock's branch of the detector's tick
-- (InputModeDetector.lua:274-281) runs switchMode (239), the switch a pad press makes on the same tick (292-298), and
-- its ZeD_InputModeChanged event reaches FocusManager.lua:3273 _onModeChanged, which opens the pair
-- (ZeD_CharacterWindow.lua:7539 ensureBothOpenForGamepad; the Character window claims the pad as it opens, 4541)
Q.step(5, function()
    local t = S.p14
    if t.off then return end
    t.g0 = getTimestampMs()
    S.lock("gamepad")
end)
S.wait(4000, function()
    local t = S.p14
    return t.off or (S.modeSince(t.g0, "gamepad") ~= nil and S.pairOpenNow() and S.Focus.getFocusedWindow(S.pn) == S.CW())
end, function(ok)
    local t = S.p14
    if t.off then return end
    t.open = ok
    local e = S.modeSince(t.g0, "gamepad")
    t.switch = e and (e.old .. " -> " .. e.new .. ", heard " .. (e.t - t.g0) .. " ms after the lock") or "NOTE no switch heard"
end)
S.still(10, function() if not S.p14.off and S.p14.open then S.p14.aside = S.aside() end end)
S.still(5, function()
    local t = S.p14
    if t.off then return end
    if not t.open then
        S.skip(t.name, "the switch to the controller did not pop the pair open with the pad on the Character window (" .. tostring(t.switch)
            .. ", the pair open " .. tostring(S.pairOpenNow()) .. ", the pad on the " .. S.holder() .. ")")
        return
    end
    local fi = S.focusInfo(S.CW())
    local first = fi.zone == "charMainInv" and fi.first ~= nil and fi.idx == fi.first
    S.pic(t.name, "he out in the open on the patch by the smoking spot (" .. S.c.x .. "," .. S.c.y .. "), facing the camera; both windows shut and ZeD on the mouse ("
        .. tostring(t.kbm) .. "); then the input detector's own switch to the controller, the one a pad press after the mouse makes"
        .. " (set off here through its lock, no pad plugged in: " .. tostring(t.switch) .. "): both windows popped open, the pad's mark on the Character window's "
        .. (first and "first inventory row" or ("NOTE row " .. tostring(fi.idx) .. " of zone " .. fi.zone .. ", not the first inventory row"))
        .. " (" .. fi.name .. ", " .. fi.n .. " rows), marks showing " .. tostring(S.Focus.cuesVisible(S.pn)) .. "; the World window on "
        .. S.activeName() .. tostring(t.aside or ""))
end)
Q.step(10, function()
    S.posBack()
    S.shut()
end)

-- ===================================================================== 15: Crafting opens the stove
S.p15 = { name = "15_crafting_opens_stove" }
Q.step(10, function()
    local t = S.p15
    if not S.c then S.skip(t.name, "no open patch near the store"); t.off = true; return end
    S.shut()
    S.home("SE")
    -- the stove beside him: west of him, else north (behind him from the camera)
    for _, o in ipairs({ { -1, 0, "west" }, { 0, -1, "north" }, { -1, -1, "north west" } }) do
        if not t.obj then
            local sq = S.goodSq(S.sqAt(S.c.x + o[1], S.c.y + o[2]))
            if sq then t.obj, t.sprite = S.placeStove(sq); t.side = o[3] end
        end
    end
    if not t.obj then S.skip(t.name, "no stove could be placed beside him on the patch"); t.off = true; return end
    t.planks = 0
    for _ = 1, 2 do if S.add("Base.Plank") then t.planks = t.planks + 1 end end
    t.hammer = S.add("Base.Hammer")
    Q.say("15: a stove (" .. tostring(t.sprite) .. ") placed " .. t.side .. " of him on the patch; " .. t.planks .. " planks and a hammer "
        .. tostring(t.hammer ~= nil) .. " given")
end)
S.settle(function() return not S.p15.off end)
Q.step(20, function()
    local t = S.p15
    if t.off then return end
    -- the station ZeD finds in reach (Stations.lua:253 ST.nearby; an IsoStove is an oven, 91-94, in reach at 3, 33):
    -- the World wheel's Crafting slice names it and opens it (ZeD_DpadWheels.lua:1089-1100 Wd.craft)
    local list = {}
    pcall(function() list = S.ST.nearby(S.p, true) or {} end)
    local st = list[1]
    t.stName = st and (tostring(st.name) .. ", " .. tostring(st.kind) .. ", " .. string.format("%.1f", st.dist or 0) .. " squares") or "none"
    t.ours = st ~= nil and st.obj == t.obj
    S.lock("gamepad")
    S.shut()
end)
Q.step(20, function()
    local t = S.p15
    if t.off then return end
    S.shut()   -- (again: the lock to the controller can hand the pad to a window a frame later)
    if not S.openWheel("right", "onDisplayRight") then S.skip(t.name, "the World wheel (D-pad Right) did not open"); t.off = true; return end
    t.how = S.how
    -- (ZeD_DpadWheels.lua:1142: the World wheel's Craft and build slice, its own ring Wd.craft)
    t.i = S.sliceStarting(ZeD.tr("UI_ZeD_Wheel_CraftBuild"))
    if not t.i then S.skip(t.name, "no Craft and build slice on the World wheel (" .. S.ringWords() .. ")"); t.off = true; S.closeWheel(); return end
    S.W.qaPoint = t.i
end)
Q.waitFor(1, 300, function() return S.p15.off or S.wheelDrawn(S.p15.i) end, function() end)
Q.step(15, function()
    local t = S.p15
    if t.off then return end
    t.outer = S.sliceText(t.i)
    t.topRing = S.ringWords()
    S.accept(t.i)
    t.j = S.sliceStarting(getText("IGUI_CraftingWindow_Title"))
    if not t.j then S.skip(t.name, "Craft and build's ring has no Crafting slice (" .. S.ringWords() .. ")"); t.off = true; S.closeWheel(); return end
    S.W.qaPoint = t.j
end)
Q.waitFor(1, 300, function() return S.p15.off or S.wheelDrawn(S.p15.j) end, function() end)
Q.step(15, function()
    local t = S.p15
    if t.off then return end
    t.inner = S.sliceText(t.j)
    t.ring = S.ringWords()
    t.crumb = S.crumb()
    -- (Crafting's run with a station in reach, ZeD_DpadWheels.lua:1096-1099: the pair opened for the pad, then
    -- Stations.lua:507 ST.open binds the station and opens the World window's Craft tab on it)
    S.accept(t.j)
    S.W.qaPoint = nil
end)
S.wait(6000, function()
    local t = S.p15
    if t.off then return true end
    local cur = nil
    pcall(function() cur = S.ST.current(S.p) end)
    return S.WWm.isTabShowing("craft", S.pn) and cur ~= nil and cur.obj == t.obj
end, function(ok) S.p15.bound = ok end)
S.still(10, function() if not S.p15.off and S.p15.bound then S.p15.aside = S.aside() end end)
S.still(5, function()
    local t = S.p15
    if t.off then return end
    if not t.bound then
        S.skip(t.name, "Crafting did not open the World window on the stove (its Craft tab showing " .. tostring(S.WWm.isTabShowing("craft", S.pn))
            .. ", bound to " .. S.stationWords() .. "; the nearest station in reach " .. tostring(t.stName) .. ", the stove placed " .. tostring(t.ours)
            .. "; the Crafting slice read \"" .. tostring(t.inner) .. "\")")
        return
    end
    S.pic(t.name, "a stove placed " .. t.side .. " of him on the open patch (" .. tostring(t.sprite) .. "), " .. tostring(t.planks) .. " planks and a hammer carried; "
        .. "the World wheel (D-pad Right, " .. tostring(t.how) .. "), its \"" .. tostring(t.outer) .. "\" slice pointed and taken through the wheel's own"
        .. " commit (what the stick's let-go does, A with Hold or Toggle), then on its ring "
        .. tostring(t.crumb) .. " (" .. tostring(t.ring) .. ") \"" .. tostring(t.inner) .. "\" pointed and taken: the World window on its Craft tab bound to the stove ("
        .. S.stationWords() .. "), the stove's panel instead of his recipes; the pad on the " .. S.holder() .. tostring(t.aside or ""))
end)
Q.step(10, function()
    S.closeWheel()
    pcall(S.ST.unbind, S.p)
    S.worldTab("loot")
end)
Q.step(10, function()
    S.posBack()
    S.shut()
    S.removeAll()
    S.takeMade()
end)

-- ===================================================================== 18: To floor beside Loot all, under the last row
S.p18 = { name = "18_pad_to_floor", path = {} }
Q.step(10, function()
    local t = S.p18
    if not S.c then S.skip(t.name, "no open patch near the store"); t.off = true; return end
    -- (the controller's mode, as 15 left it; set again should 14 and 15 both have been skipped)
    S.lock("gamepad")
    S.shut()
    -- the fridge beside him, beyond him from the camera: north of him (its door to the south, to him), else west of him
    -- (its door to the east); he faces it, as a player looting it does
    local sq = S.goodSq(S.sqAt(S.c.x, S.c.y - 1))
    if sq then t.obj, t.inv, t.sprite = S.placeFridge(sq, S.FRIDGE_N); t.face, t.side = "N", "north" end
    if not t.obj then
        sq = S.goodSq(S.sqAt(S.c.x - 1, S.c.y))
        if sq then t.obj, t.inv, t.sprite = S.placeFridge(sq, S.FRIDGE_W); t.face, t.side = "W", "west" end
    end
    t.what = "fridge"
    if not t.obj then
        -- (no fridge tile: a crate, the other thing the call names)
        sq = S.goodSq(S.sqAt(S.c.x, S.c.y - 1))
        t.face, t.side = "N", "north"
        if not sq then sq = S.goodSq(S.sqAt(S.c.x - 1, S.c.y)); t.face, t.side = "W", "west" end
        if sq then t.obj, t.inv = S.placeCrate(sq); t.sprite, t.what = S.CRATE, "crate" end
    end
    if not (t.obj and t.inv) then S.skip(t.name, "no fridge or crate could be placed beside him on the patch"); t.off = true; return end
    t.box = S.fillBox(t.inv, S.FOOD_FRIDGE)
    if #t.box.added < 8 then S.skip(t.name, "only " .. #t.box.added .. " foods went into the " .. t.what); t.off = true; return end
    G1.tp({ S.c.x, S.c.y }, t.face)
    Q.say("18: a " .. t.what .. " (" .. tostring(t.sprite) .. ") placed " .. t.side .. " of him on the patch, " .. #t.box.added .. " foods in it: " .. S.boxWords(t.box))
end)
S.settle(function() return not S.p18.off end)
Q.step(10, function() if not S.p18.off then S.openPair() end end)
S.wait(3000, function() return S.p18.off or S.pairOpenNow() end, function(ok)
    local t = S.p18
    if t.off then return end
    if not ok then S.skip(t.name, "the pair did not open"); t.off = true; return end
    pcall(S.WWm.selectContainer, t.inv, 120, S.pn)
end)
-- (the list's rows a pad can stop on: zone worldMainInv's elements that carry an item)
S.wait(5000, function()
    local t = S.p18
    return t.off or (S.showsInv(t.inv) and S.rowsIn(S.WW(), "worldMainInv") >= 1)
end, function(ok)
    local t = S.p18
    if t.off then return end
    if not ok then S.skip(t.name, "the World window does not show the " .. t.what .. "'s food (on " .. S.activeName() .. ")"); t.off = true end
end)
S.still(5, function()
    local t = S.p18
    if t.off then return end
    t.rows = S.rowsIn(S.WW(), "worldMainInv")
    -- the pad on the World window, on its list's first row (FocusManager.lua:587 claimFocus, as the wheels' World
    -- slices hand it over, ZeD_DpadWheels.lua:738; 1072 focusWhere)
    pcall(S.Focus.claimFocus, S.WW())
    t.first = S.Focus.focusWhere(S.WW(), "worldMainInv", function(e) return e.item ~= nil end)
    if not t.first then S.skip(t.name, "the pad could not be put on the World window's first row"); t.off = true end
end)
-- D-pad Down, a press every 8 drawn frames, as the pad's D-pad reaches the window (FocusManager.lua:2697
-- dispatchJoypadDir), until the focus leaves the list for the buttons under it (zone worldCtl)
Q.waitFor(10, 3000, function()
    local t = S.p18
    if t.off then return true end
    local w = S.WW()
    if not w then return true end
    local z = S.Focus.getFocusedZone(w)
    if z and z.zone == "worldCtl" then return true end
    t.tick = (t.tick or 0) + 1
    if t.tick < 8 then return false end
    t.tick = 0
    if (t.downs or 0) >= 24 then return true end
    t.downs = (t.downs or 0) + 1
    -- (the row this press starts from, of how many: the press that leaves the list must start on the last one)
    local fi = S.focusInfo(w)
    t.preRow, t.preRows = fi.row, fi.n
    S.Focus.dispatchJoypadDir(w, "down", { player = S.pn })
    return false
end, function()
    local t = S.p18
    if t.off then return end
    t.tick = 0
    local fi = S.focusInfo(S.WW())
    t.landWord = fi.name
    if fi.zone ~= "worldCtl" then
        S.skip(t.name, "D-pad Down x" .. tostring(t.downs) .. " from the first row never left the list for the buttons under it (the focus on " .. fi.zone .. ", " .. fi.name .. ")")
        t.off = true
    end
end)
-- then along the buttons to To floor, the way the D-pad walks them (Left / Right walk the ribbon: CT.syncFocus's walkLR)
Q.waitFor(5, 1500, function()
    local t = S.p18
    if t.off then return true end
    local w = S.WW()
    local el = w and S.Focus.getFocusedElement(w)
    if el and el.ccKey == "floor" then return true end
    t.tick = (t.tick or 0) + 1
    if t.tick < 8 then return false end
    t.tick = 0
    if #t.path >= 6 then return true end
    local dir = S.floorWay(w)
    if not dir then return true end
    t.path[#t.path + 1] = dir
    S.Focus.dispatchJoypadDir(w, dir, { player = S.pn })
    return false
end, function() end)
S.still(10, function() if not S.p18.off then S.p18.aside = S.aside() end end)
S.still(5, function()
    local t = S.p18
    if t.off then return end
    local w = S.WW()
    local fi = S.focusInfo(w)
    local onIt = fi.zone == "worldCtl" and fi.el ~= nil and fi.el.ccKey == "floor"
    -- (the picture is the highlight on To floor: anywhere else it is not staged, so not taken)
    if not onIt then
        S.skip(t.name, "the walk along the buttons under the list did not reach To floor (the highlight on " .. tostring(fi.name) .. " in zone "
            .. fi.zone .. ", the buttons " .. S.bandWords(w) .. ", walked " .. table.concat(t.path, " ") .. ")")
        return
    end
    local walk = ""
    if #t.path > 0 then walk = "; then " .. t.path[1] .. " x" .. #t.path .. ((#t.path > 1 and t.path[1] ~= t.path[#t.path]) and " (both ways)" or "") .. " along them" end
    S.pic(t.name, "a " .. t.what .. " placed " .. t.side .. " of him on the open patch (" .. tostring(t.sprite) .. "), " .. #t.box.added .. " foods in it, the World window on it ("
        .. tostring(t.rows) .. " rows); the pad on the World window's first row, then D-pad Down x" .. tostring(t.downs) .. " as the pad's D-pad reaches the window:"
        .. " the last press left " .. ((t.preRow ~= nil and t.preRow == t.preRows) and "the last row" or ("NOTE row " .. tostring(t.preRow) .. ", not the last"))
        .. " (of " .. tostring(t.preRows) .. ") for the buttons under the list, onto " .. tostring(t.landWord) .. walk
        .. "; the buttons under the list read " .. S.bandWords(w) .. " (Style " .. S.styleWord() .. "); "
        .. "the highlight on To floor (\"" .. tostring(fi.name) .. "\"), " .. S.lootAllFrom(w)
        .. "; marks showing " .. tostring(S.Focus.cuesVisible(S.pn)) .. tostring(t.aside or ""))
end)
Q.step(10, function()
    pcall(S.Focus.releaseFocus, S.pn)
    S.posBack()
    S.shut()
    S.boxBack(S.p18.box)
    S.removeAll()
end)

-- ===================================================================== 20: D-pad Up in the car is the Social wheel
S.p20 = { name = "20_pad_social_in_car" }
Q.step(10, function()
    local t = S.p20
    if not S.c then S.skip(t.name, "no open patch near the store"); t.off = true; return end
    -- (the controller's mode well before the wheel: a switch to it opens the pair a tick later, shut again below)
    S.lock("gamepad")
    S.shut()
    S.home("SE")
    local sq = S.carSpot()
    if not sq then S.skip(t.name, "no bare 3 x 7 footprint on or by the patch, clear of the parked cars"); t.off = true; return end
    -- (beta21_report.lua:463's spawn: addVehicleDebug(script, IsoDirections.N, nil, square))
    for _, script in ipairs({ "Base.PickUpTruck", "Base.CarNormal" }) do
        if not t.car then
            pcall(function() t.car = addVehicleDebug(script, IsoDirections.N, nil, sq) end)
            if t.car then t.script = script end
        end
    end
    if not t.car then S.skip(t.name, "no car could be spawned at " .. sq:getX() .. "," .. sq:getY()); t.off = true; return end
    t.at = sq:getX() .. "," .. sq:getY()
    t.t0 = getTimestampMs()
    Q.say("20: " .. tostring(t.script) .. " spawned at " .. t.at .. ", facing north")
end)
Q.waitFor(5, 1800, function()
    local t = S.p20
    return t.off or S.carReady(t.car) or getTimestampMs() - (t.t0 or 0) > 8000
end, function()
    local t = S.p20
    if t.off then return end
    if not S.carReady(t.car) then S.skip(t.name, "the car was not ready in 8 s (its physics never woke)"); t.off = true; S.carAway(t); return end
    local ok, why = S.carIn(t.car)
    if not ok then S.skip(t.name, "he could not be seated at the wheel: " .. tostring(why)); t.off = true; S.carAway(t); return end
end)
S.settle(function() return not S.p20.off end)
-- (ZeD's dash comes up as he sits at the wheel)
S.wait(1500, function() return S.p20.off end, function() end)
Q.step(10, function()
    local t = S.p20
    if t.off then return end
    S.lock("gamepad")
    S.shut()
    -- nothing pointed: the wheel as D-pad Up opens it (and no slice lit by where the real pointer rests)
    S.W.qaPoint = -1
    -- (the game's own D-pad Up: JoyPadSetup.lua:691 calls ISDPadWheels.onDisplayUp, which in a car is the car's wheel,
    -- ISDPadWheels.lua:94-102; ZeD's in its place opens the Social wheel, ZeD_DpadWheels.lua:1170 D.B.social)
    if not S.openWheel("up", "onDisplayUp") then S.skip(t.name, "the Social wheel (D-pad Up) did not open"); t.off = true; S.W.qaPoint = nil; return end
    t.how = S.how
end)
Q.waitFor(1, 300, function() return S.p20.off or S.wheelDrawn(-1) end, function() end)
Q.waitFor(10, 600, function() return S.p20.off or S.quiet() end, function()
    local t = S.p20
    if t.off then return end
    if not S.wheelDrawn(-1) then S.skip(t.name, "the Social wheel is not on screen"); return end
    local seat, inCar = -1, false
    pcall(function() seat = t.car:getSeat(S.p) end)
    pcall(function() inCar = S.p:getVehicle() == t.car end)
    S.pic(t.name, "a pickup (" .. tostring(t.script) .. ") spawned on the open patch at " .. tostring(t.at) .. ", facing north, he in its driver's seat (in the car "
        .. tostring(inCar) .. ", seat " .. tostring(seat) .. "); D-pad Up as the pad opens it (" .. tostring(t.how) .. "; the game's own D-pad Up in a car is the car's wheel):"
        .. " ZeD's " .. S.crumb() .. " wheel, nothing pointed, " .. #S.slices() .. " slices: " .. S.ringWords()
        .. "; the car's own wheel is the World wheel's Vehicle slice (D-pad Right) now")
end)
Q.step(10, function()
    S.closeWheel()
    S.carAway(S.p20)
end)
S.wait(4000, function() return S.carGone(S.p20) end, function(ok)
    local t = S.p20
    if t.car then Q.say("20: he out of the car " .. tostring(S.p:getVehicle() == nil) .. ", the car taken away " .. tostring(ok)) end
    if S.p:getVehicle() == nil then S.home("SE") end
end)
S.settle(function() return S.c ~= nil end)

-- ===================================================================== 21: Weapons one slice of the Character wheel
S.p21 = { name = "21_pad_char_wheel" }
Q.step(10, function()
    local t = S.p21
    if not S.c then S.skip(t.name, "no open patch near the store"); t.off = true; return end
    -- (the controller's mode well before the wheel, as in 20)
    S.lock("gamepad")
    S.shut()
    S.home("SE")
    t.bat = S.add("Base.BaseballBat")
    t.axe = S.add("Base.Axe")
    if not (t.bat and t.axe) then S.skip(t.name, "the bat or the axe could not be given"); t.off = true; return end
end)
S.settle(function() return not S.p21.off end)
Q.step(20, function()
    local t = S.p21
    if t.off then return end
    S.lock("gamepad")
    S.shut()
    S.W.qaPoint = -1
    if not S.openWheel("left", "onDisplayLeft") then S.skip(t.name, "the Character wheel (D-pad Left) did not open"); t.off = true; S.W.qaPoint = nil; return end
    t.how = S.how
    -- (ZeD_DpadWheels.lua:1021: the Character wheel's Weapons slice, its own ring C.weapons)
    t.i = S.sliceStarting(ZeD.tr("UI_ZeD_Wheel_Weapons"))
    if not t.i then S.skip(t.name, "no Weapons slice on the Character wheel (" .. S.ringWords() .. ")"); t.off = true; S.closeWheel(); return end
    S.W.qaPoint = t.i
end)
Q.waitFor(1, 300, function() return S.p21.off or S.wheelDrawn(S.p21.i) end, function() end)
Q.waitFor(10, 600, function() return S.p21.off or S.quiet() end, function()
    local t = S.p21
    if t.off then return end
    if not S.wheelDrawn(t.i) then S.skip(t.name, "the Character wheel is not on screen with Weapons pointed"); return end
    local names = { S.nm(t.bat), S.nm(t.axe) }
    local onRing = {}
    for _, s in ipairs(S.slices()) do
        local tx = tostring(s.text or "")
        for _, n in ipairs(names) do
            if n ~= "?" and string.find(tx, n, 1, true) then onRing[#onRing + 1] = n end
        end
    end
    local inner = 0
    pcall(function() inner = #S.D.H.weapons(S.p) end)
    S.pic(t.name, "the bat (" .. names[1] .. ") and the axe (" .. names[2] .. ") carried in his inventory, neither in his hands; D-pad Left as the pad opens it ("
        .. tostring(t.how) .. "): the " .. S.crumb() .. " wheel's first ring, " .. #S.slices() .. " slices: " .. S.ringWords() .. "; Weapons one slice of them (slice "
        .. t.i .. ", pointed so its balloon names it, \"" .. S.sliceText(t.i) .. "\")"
        .. ((#onRing == 0) and (", no weapon on the ring itself: the " .. inner .. " kinds he carries are one more flick in, on Weapons' own ring")
            or (" (NOTE on the first ring: " .. table.concat(onRing, ", ") .. ")")))
end)
Q.step(10, function()
    S.closeWheel()
    S.takeMade()
end)

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    S.closeWheel()
    if S.qaY then pcall(S.Focus.qaButton, "Y", nil, S.pn); S.qaY = nil end
    pcall(S.ST.unbind, S.p)
    S.carAway(S.p20)
end)
S.wait(4000, function() return S.carGone(S.p20) end, function(ok)
    if S.p20.car and not ok then Q.say("ERR the pickup is still in the cell (he in it " .. tostring(S.p:getVehicle() ~= nil) .. ")") end
end)
Q.step(5, function()
    pcall(function() if S.p:getVehicle() then local v = S.p:getVehicle(); v:exit(S.p); triggerEvent("OnExitVehicle", S.p) end end)
    S.boxesBack()
    S.removeAll()
    S.takeMade()
    pcall(function() if S.p:getPrimaryHandItem() ~= S.was.h1 then S.p:setPrimaryHandItem(S.was.h1) end end)
    pcall(function() if S.p:getSecondaryHandItem() ~= S.was.h2 then S.p:setSecondaryHandItem(S.was.h2) end end)
    pcall(S.Focus.releaseFocus, S.pn)
    -- the mode the detector read at the start (it keeps its last switch when the lock comes off): the mouse's, unless
    -- it was the controller's
    S.endK0 = getTimestampMs()
    if S.was.mode ~= "gamepad" then S.lock("kbm") end
end)
S.wait(1500, function() return S.was.mode == "gamepad" or S.modeSince(S.endK0, "kbm") ~= nil end, function() end)
Q.step(5, function()
    S.lock(false)
    pcall(function() if S.was.ignoreAim ~= nil then S.p:setJoypadIgnoreAimUntilCentered(S.was.ignoreAim == true) end end)
    S.mouseOff()
    if S.heard and Events.ZeD_InputModeChanged then Events.ZeD_InputModeChanged.Remove(S.modeHeard); S.heard = nil end
end)
S.zoomDyn(function() return S.was.zoom end)
Q.step(20, function() S.openPair() end)
-- (the tabs once both windows have drawn: a tab strip stamps its buttons as it draws, so a window opened this frame
-- has none to press yet)
Q.step(20, function() S.charTab("loot"); S.worldTab("loot") end)
Q.step(30, function()
    S.posBack()
    local hurt = false
    pcall(function() hurt = S.p:getBodyDamage():getOverallBodyHealth() < 99 end)
    if hurt then pcall(function() S.p:getBodyDamage():RestoreToFullHealth() end) end
    if S.was.at then G1.tp(S.was.at, "SE") end
    S.back0()
    G1.glassesBack(Q)
end)
Q.step(30, function()
    if not S.was.pairOpen then S.closePair() end
    -- the pad's holder as found: the Character or the World window (open again), another window still registered, or none
    local want = (S.was.focus == "char") and S.CW() or ((S.was.focus == "world") and S.WW() or nil)
    if S.was.focus == "other" and S.Focus.isRegistered and S.Focus.isRegistered(S.was.focusWin) then want = S.was.focusWin end
    if want then pcall(S.Focus.claimFocus, want) else pcall(S.Focus.releaseFocus, S.pn) end
    Events.OnPreUIDraw.Remove(S.errWatch)
    pcall(function() Mouse.setCursorVisible(true) end)
    local seated = false
    pcall(function() seated = S.p:isSitOnGround() or S.p:isSittingOnFurniture() end)
    Q.say("put back: placed things still standing " .. S.standing() .. ", the pickup in the cell " .. tostring(S.carLive(S.p20.car))
        .. ", in a car " .. tostring(S.p:getVehicle() ~= nil) .. ", sitting " .. tostring(seated) .. ", alive " .. tostring(not S.p:isDead())
        .. ", input lock as found (" .. tostring(S.lockWas) .. "; ZeD reads " .. S.modeNow() .. ", read " .. tostring(S.was.mode) .. " at the start)"
        .. ", the Y hook " .. tostring(S.qaY == true) .. ", wheel pointer " .. tostring(S.W.qaPoint) .. ", the Stations binding " .. S.stationWords()
        .. ", the pointer swap " .. tostring(S.mouseSwapped == true) .. ", zoom " .. tostring(S.zoom()) .. " (found " .. tostring(S.was.zoom) .. ")"
        .. ", the pair open " .. tostring(S.pairOpenNow()) .. " (found " .. tostring(S.was.pairOpen) .. "), the pad held by the " .. S.holder()
        .. " (found: " .. tostring(S.was.focus) .. "), at " .. S.fl(S.p:getX()) .. "," .. S.fl(S.p:getY())
        .. " | pictures taken: " .. ((#S.taken > 0) and table.concat(S.taken, ", ") or "none"))
end)
Q.start()
