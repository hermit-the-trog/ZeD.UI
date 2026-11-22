-- ZeDUI/tools/qa/bxr_menus.lua  (Nov 21 2026, QA; tag bxrm): the beast day report's pictures of the menus, the
-- controller wheel and the hint strip (git a84ebecb1 b0e9fc66b 9053bdef9 58c20c461 2a00af40d). Pictures to
-- Zomboid/Screenshots/bxr_<name>.png (QA's runner moves them to Screenshots/beast_day_report/). Manifest
-- beast_report_menus.txt (the story stage, gallery_unload.lua, G1, hfr_common.lua). Style and theme as found.
--   B5-5_list_door               Context menu on List, a right-click on a door of the map: the heading reads "Door"
--   B5-5_list_window             the same on a window of the map: "Window" (with no window on the camera side of a
--                                building, a stove placed on the patch instead: B5-5_list_stove, "Stove")
--   B5-5_list_ground             the same on bare ground: "Ground"
--                                (all of them read "Item" before the fix. No sink: today's bx_context run reads
--                                "Ground" for a sink, fridge, bed, chair, crate, trash can and corpse, which is what
--                                B5-5 left undone, not its fix)
--   W15_strip_at_rest            Context menu on Strip, a right-click on a carried thing with 11 or more actions.
--                                The picture is the strip's third drawn frame, inside the 180 ms the old slide took:
--                                a strip that still slid would show its cells part way along; this one is at rest
--   W55_radio_open_no_hint       a walkie-talkie in the main hand, in the open: the hint strip shows nothing
--   B6-7_radio_station_more      the same radio in front of a crafting station: "Right-click More"
--   B7-3_wheel_sit_on_chair      the D-pad Down wheel's Sit ring, a chair two squares south west of him: "Sit on: <chair>"
--   B7-3_wheel_sleep_names_bed   sitting on a bed, the D-pad Left wheel's Sleep slice names the bed
-- The scene: an open patch by the story's smoking spot (in the open, on the camera side of the store), or a door or
-- window of the map on the camera side of a building. Nothing placed stands between him and the camera (it looks
-- from the south-east): a place to stand needs its squares two deep toward the camera open (no roof, canopy, room,
-- tree or car). A right-click menu opens to the right of him: he stands left of what he right-clicks, facing it.
-- While a menu is up, the pointer the game's Lua reads is parked off every menu (Mouse.setXY does not move it), so
-- no row or cell is lit by wherever the real pointer happens to rest; the same while the hint strip is pictured.
-- No controller is plugged in: the wheels open as gallery_v1_b_pad.lua opens them (ZeD's input mode locked to the
-- controller, ISDPadWheels.onDisplay*, else ZeD.DpadWheels.open) and a slice is pointed with ZeD.Wheel.qaPoint.
-- Each picture prints "ZEDQA bxrm SHOT <name> | what is in it" or "ZEDQA bxrm SKIP <name> | why".
-- What it puts back: the things given, his hands, the chair, bed, stove, door and station placed, the Context menu and
-- Hint strip settings, the input mode lock, the build cheat, tiredness and the last sleep hour, the opened stack, the
-- pointer the game reads, both windows where they were, game speed, the pair as found; he ends standing, alive and
-- whole. grep "ZEDQA bxrm".
local S = HFR and HFR.init and HFR.init("bxrm")
if not S then return end
S.DIR = "bxr_"
local Q = S.Q
local D, W, HS = ZeD.DpadWheels, ZeD.Wheel, ZeD.HintStrip
S.Det = ZeD.Input and ZeD.Input.Detector
S.Focus = ZeD.Input and ZeD.Input.Focus
S.objs, S.built, S.pic, S.stackWas = {}, {}, {}, {}
S.CHAIRS = { "furniture_seating_indoor_01_", "furniture_seating_outdoor_01_", "furniture_seating_indoor_02_" }
S.BEDS = { "furniture_bedding_01_" }
S.STOVES = { "appliances_cooking_01_0", "appliances_cooking_01_8" }
S.STATIONS = { "Base.Kiln_Small", "Base.Log_Table", "Base.Metalworkbench", "Base.Forge_Primitive_Forge" }
S.LONG = { "Base.Screwdriver", "Base.Pistol", "Base.Axe" }
S.RADIOS = { "Base.WalkieTalkie2", "Base.WalkieTalkie3", "Base.WalkieTalkie1", "Base.WalkieTalkie4", "Base.WalkieTalkie5" }

if not (D and D.H and W and HS and ZeD.Settings and ZeD.Settings.contextStyleOption and ZeD.ContextMenu and ZeD.ContextMenu.Registry) then
    Q.say("ERR ZeD's wheels, hint strip or context menu are not loaded")
    Q.start()
    return
end

-- ===================================================================== helpers
function S.shotOk(name, what, keepMenu) S.shot(name, keepMenu); S.pic[#S.pic + 1] = name; Q.say("SHOT " .. name .. " | " .. what) end
function S.skip(name, why) Q.notTaken(name, why); Q.say("SKIP " .. name .. " | " .. tostring(why)) end
-- time, not frames: cond asked every 100 ms (a UI update), at most ms; fn(true) when cond came true
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
function S.scr() return S.core:getScreenWidth(), S.core:getScreenHeight() end
function S.zoom()
    local z = 1
    pcall(function() z = S.core:getZoom(S.pn) end)
    if not z or z <= 0 then z = 1 end
    return z
end
function S.sqAt(x, y) return getCell():getGridSquare(x, y, 0) end
-- a bare square in the open (bxr_craft.lua's test)
function S.goodSq(sq)
    local good = false
    pcall(function()
        good = sq ~= nil and sq:getFloor() ~= nil and sq:isFree(false) and not sq:HasTree() and sq:isOutside()
            and sq:getRoom() == nil and sq:getObjects():size() <= 3 and sq:getWorldObjects():size() == 0
            and sq:getVehicleContainer() == nil and sq:getMovingObjects():size() == 0
    end)
    return good and sq or nil
end
-- the squares up to three deep on the camera side of (x, y), past its bare neighbours, in the band that is drawn over a
-- character standing on (x, y) (a car, tree or wall two squares out; a roof or a canopy over the pumps, drawn a floor
-- up, three out): open sky (no roof, canopy or room), no tree, no car
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
-- the open patch: every square from lo to hi round (x, y) bare
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
function S.screenOf(fx, fy) return S.fl(isoToScreenX(S.pn, fx, fy, 0)), S.fl(isoToScreenY(S.pn, fx, fy, 0)) end
-- the way from (x, y) to (tx, ty), as IsoDirections names it
function S.dirTo(x, y, tx, ty)
    local dx, dy = tx - x, ty - y
    local ax, ay = math.abs(dx), math.abs(dy)
    local ns = (dy < 0) and "N" or "S"
    local ew = (dx > 0) and "E" or "W"
    if ax <= ay * 0.42 then return ns end
    if ay <= ax * 0.42 then return ew end
    return ns .. ew
end
-- where to stand for a right-click at (fx, fy) on the thing at square (tx, ty): a bare square in the open with its
-- three camera-side neighbours bare and the band past them open (S.clearAhead), to the LEFT of the click on screen, so the menu
-- (it opens right and down from the click) is beside him and never on him
function S.standFor(fx, fy, tx, ty)
    local z = S.zoom()
    local need = 230 / z
    local ax, ay = isoToScreenX(S.pn, fx, fy, 0), isoToScreenY(S.pn, fx, fy, 0)
    local best, bs = nil, 1e9
    for dy = -5, 5 do
        for dx = -5, 5 do
            local x, y = tx + dx, ty + dy
            if not (dx == 0 and dy == 0) and S.goodSq(S.sqAt(x, y)) and S.goodSq(S.sqAt(x + 1, y + 1))
               and S.goodSq(S.sqAt(x + 1, y)) and S.goodSq(S.sqAt(x, y + 1)) then
                local gx = ax - isoToScreenX(S.pn, x + 0.5, y + 0.5, 0)
                local gy = ay - isoToScreenY(S.pn, x + 0.5, y + 0.5, 0)
                if gx >= need and gx <= need * 3 then
                    local sc = math.abs(gy + 150 / z) + gx * 0.5
                    if sc < bs and S.clearAhead(x, y) then best, bs = { x = x, y = y }, sc end
                end
            end
        end
    end
    return best
end
function S.over(x, y, w, h)
    local r = G1.charRect()
    return x < r.x1 and x + w > r.x0 and y < r.y1 and y + h > r.y0
end
function S.onScreen(x, y, w, h)
    local sw, sh = S.scr()
    return x >= -1 and y >= -1 and x + w <= sw + 1 and y + h <= sh + 1
end

-- ----- placed tiles
function S.removeObj(o)
    if not o then return end
    local sq = nil
    pcall(function() sq = o:getSquare() end)
    if sq then
        pcall(function() if sq:getObjects():contains(o) then sq:RemoveTileObject(o, false) end end)
        pcall(function() if sq:getObjects():contains(o) then sq:transmitRemoveItemFromSquare(o, false) end end)
    end
end
function S.removeAll()
    for _, o in ipairs(S.objs) do S.removeObj(o) end
    S.objs = {}
    for _, o in ipairs(S.built) do
        local sq = nil
        pcall(function() sq = o:getSquare() end)
        if sq then
            pcall(function() sq:transmitRemoveItemFromSquare(o) end)
            pcall(function() if o:getObjectIndex() >= 0 then sq:RemoveTileObject(o) end end)
        end
    end
    S.built = {}
end
function S.standing()
    local n = 0
    for _, o in ipairs(S.objs) do pcall(function() if o:getSquare() ~= nil and o:getSquare():getObjects():contains(o) then n = n + 1 end end) end
    for _, o in ipairs(S.built) do pcall(function() if o:getObjectIndex() >= 0 then n = n + 1 end end) end
    return n
end
-- a stove on a square (bx_context.lua's mkStove): the object and its sprite, or nil
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
            if on then S.objs[#S.objs + 1] = o; return o, name end
        end
    end
    return nil
end
-- the other tiles of a bed: each at its own place in the sprite's grid, on bare squares only
function S.restOfGrid(grid, spr, sq, name)
    local n = 0
    pcall(function()
        local bx, by = grid:getSpriteGridPosX(spr), grid:getSpriteGridPosY(spr)
        for gy = 0, grid:getHeight() - 1 do
            for gx = 0, grid:getWidth() - 1 do
                local s2 = grid:getSprite(gx, gy)
                local n2 = s2 and tostring(s2:getName()) or nil
                if n2 and n2 ~= name then
                    local q = S.goodSq(S.sqAt(sq:getX() + gx - bx, sq:getY() + gy - by))
                    if q then
                        local o2 = IsoObject.new(q, n2, nil, false)
                        q:AddTileObject(o2)
                        S.objs[#S.objs + 1] = o2
                        n = n + 1
                    end
                end
            end
        end
    end)
    return n
end
function S.seatName(o)
    local nm = nil
    pcall(function() nm = ISWorldObjectContextMenu.getMoveableDisplayName(o) end)
    return nm
end
-- a seat tile (a chair of one tile, or a bed with its other tiles): the first sprite the game has seat places for
-- and a name (bx_health.lua's X.place; a seat with no name reads "Sit on a seat" whatever the fix)
function S.placeSeat(prefixes, sq, wantBed)
    if not sq then return nil, "the square is not free" end
    for _, pre in ipairs(prefixes) do
        for i = 0, 63 do
            local name = pre .. i
            local spr = getSprite(name)
            local good = spr ~= nil
            local grid = nil
            if good then pcall(function() grid = spr:getSpriteGrid() end) end
            if good and not wantBed and grid ~= nil then good = false end
            if good and wantBed then
                good = false
                pcall(function() good = spr:getProperties():has("BedType") end)
            end
            if good then
                local o, n = nil, 0
                pcall(function() o = IsoObject.new(sq, name, nil, false) end)
                pcall(function() n = SeatingManager.getInstance():getTilePositionCount(o) end)
                if o and n > 0 and S.seatName(o) ~= nil then
                    sq:AddTileObject(o)
                    S.objs[#S.objs + 1] = o
                    local more = grid and S.restOfGrid(grid, spr, sq, name) or 0
                    return o, name .. ((more > 0) and (" and " .. more .. " more of its tiles") or "")
                end
            end
        end
    end
    return nil, "no sprite with seat places and a name"
end
function S.sitting()
    local s = false
    pcall(function() s = S.p:isSitOnGround() or S.p:isSittingOnFurniture() end)
    return s
end
function S.getUp()
    pcall(function() ISTimedActionQueue.clear(S.p) end)
    pcall(function()
        if S.p:isSitOnGround() or S.p:isSittingOnFurniture() then S.p:StopAllActionQueue(); S.p:setVariable("forceGetUp", true) end
    end)
end

-- ----- the right-click menus
-- (S.ctxOpt, not S.opt: hfr_common.lua's S.opt(id) is the ZeD setup lookup)
function S.ctxOpt() return ZeD.Settings.contextStyleOption end
function S.style(v) pcall(function() S.ctxOpt():setValue(v) end) end
function S.vmenu() return getPlayerContextMenu(S.pn) end
function S.menu() local v = S.vmenu(); return v and v._zedMenu or nil end
-- the pointer the game's Lua reads (Mouse.setXY does not move it): the click's place while a menu is made, then off
-- every menu (-9000) until it closes
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
function S.closeMenu()
    local m = S.menu()
    if m then pcall(m.close, m) end
    local v = S.vmenu()
    pcall(function() if v and not v._zedMenu and v.closeAll and v:isVisible() then v:closeAll() end end)
    S.mouseOff()
end
function S.menuSettled()
    if S.menu() then return true end
    local v = S.vmenu()
    if not v then return true end
    return v._zedFailed == true
end
-- one world right-click with Context menu on List: prep() gives { obj, fx, fy, tx, ty, how } (the thing, the click's
-- place in the world, its square), and may give st (where to stand), label and pic (another thing, another picture
-- name), floor (the ground itself), after (put back); or nil and why
function S.worldShot(name, label, prep)
    local t = {}
    Q.step(10, function()
        S.closeMenu()
        S.closePair()
        local ok, a, b = pcall(prep)
        if not (ok and a) then S.skip(name, ok and tostring(b) or ("its staging threw: " .. tostring(a))); return end
        t.pic, t.label = a.pic or name, a.label or label
        local st = a.st or S.standFor(a.fx, a.fy, a.tx, a.ty)
        if not st then
            S.skip(t.pic, "no bare square in the open, with open ground toward the camera, to the left of " .. t.label)
            if a.after then pcall(a.after) end
            return
        end
        t.T = a
        local face = S.dirTo(st.x + 0.5, st.y + 0.5, a.fx, a.fy)
        G1.tp({ st.x, st.y }, face)
        Q.say(t.pic .. ": " .. t.label .. " at " .. a.tx .. "," .. a.ty .. " (" .. tostring(a.how) .. "), he stands at " .. st.x .. "," .. st.y .. " facing " .. face)
    end)
    S.settle(function() return t.T ~= nil end)
    Q.step(3, function()
        if not t.T then return end
        S.style(2)
        local sx, sy = S.screenOf(t.T.fx, t.T.fy)
        S.mouseOn(sx, sy)
        local ok, e = pcall(function() return ISContextManager.getInstance().createWorldMenu(S.pn, t.T.obj, { t.T.obj }, sx, sy) end)
        if not ok then t.err = tostring(e) end
    end)
    -- the menu made: the pointer goes off every menu (a resting real pointer must not light a row)
    Q.waitFor(1, 300, function() return not t.T or t.err ~= nil or S.menuSettled() end, function() if t.T then S.mouseOn(-9000, -9000) end end)
    -- drawn: the list has drawn its rows (their hit zones); then three more frames
    Q.waitFor(1, 120, function()
        local m = S.menu()
        return not t.T or t.err ~= nil or m == nil or (m._levels and m._levels[1] and m._levels[1].w ~= nil and #(m._hitZones or {}) > 0)
    end, function() end)
    Q.step(3, function()
        if not t.T then return end
        local m = S.menu()
        if t.err or not m then
            local v = S.vmenu()
            S.skip(t.pic, t.err and ("the right-click threw: " .. t.err) or ("ZeD's menu did not open (the game's options: " .. tostring(v and v.options and #v.options) .. ")"))
            S.closeMenu()
            return
        end
        if m.Type ~= "ZeD_ContextList" then S.skip(t.pic, "the menu opened as " .. tostring(m.Type) .. ", not the list"); S.closeMenu(); return end
        local lv = m._levels[1]
        local head = "?"
        pcall(function() head = tostring(ZeD.ContextMenu.Registry.getTargetDisplay(m._ctx.target)) end)
        local rows = {}
        for _, d in ipairs(m._ctx.actions or {}) do if #rows < 6 then rows[#rows + 1] = tostring(d.name) end end
        local fault = ""
        if head == tostring(ZeD.tr("IGUI_Item")) then fault = " (FAULT: still \"Item\")"
        elseif not t.T.floor and head == tostring(ZeD.tr("IGUI_ContainerTitle_floor")) then fault = " (FAULT: it names the ground, not " .. t.label .. ")" end
        S.shotOk(t.pic, "a right-click on " .. t.label .. " (" .. tostring(t.T.how) .. "), Context menu on List: the heading reads \"" .. head .. "\""
            .. fault .. " (\"Item\" before the fix); rows: " .. table.concat(rows, ", ")
            .. "; the list at " .. S.fl(lv.x) .. "," .. S.fl(lv.y) .. " " .. S.fl(lv.w) .. "x" .. S.fl(lv.h)
            .. ", all on screen " .. tostring(S.onScreen(lv.x, lv.y, lv.w, lv.h))
            .. (S.over(lv.x, lv.y, lv.w, lv.h) and ", NOTE it lies over the character" or ", beside the character") .. "; no row lit (the pointer off the list)", true)
    end)
    Q.step(5, function() S.closeMenu(); if t.T and t.T.after then pcall(t.T.after) end end)
end
-- a door or window of the map whose own square is in the open and already seen (its wall is north or west of that
-- square, so he stands on the camera side of the building), with a place to stand left of it; the nearest to the
-- patch, a shut and whole one before an open, smashed or barricaded one. kind: "IsoDoor" or "IsoWindow" (a door a
-- player built is an IsoThumpable and is left out: its heading names its kind, not "Door")
function S.findOpening(kind, label)
    local s = STORY.site
    local best, bs = nil, 1e9
    for y = s.y0 - 20, s.y1 + 20 do
        for x = s.x0 - 20, s.x1 + 20 do
            local sq = S.sqAt(x, y)
            local n = 0
            if sq then pcall(function() if sq:isSeen(S.pn) and sq:isOutside() and sq:getRoom() == nil then n = sq:getObjects():size() end end) end
            for i = 0, n - 1 do
                pcall(function()
                    local o = sq:getObjects():get(i)
                    if not instanceof(o, kind) then return end
                    local north = o:isNorth() and true or false
                    local off, state = 0, "shut"
                    pcall(function() if o:IsOpen() then off, state = 40, "open" end end)
                    if kind == "IsoWindow" then
                        pcall(function() if o:isSmashed() or o:isDestroyed() then off, state = off + 200, "smashed" end end)
                        pcall(function() if o:isBarricaded() then off, state = off + 100, state .. ", barricaded" end end)
                    end
                    local sc = math.abs(x - S.c.x) + math.abs(y - S.c.y) + off
                    if sc >= bs then return end
                    local fx, fy = x + (north and 0.5 or 0.15), y + (north and 0.15 or 0.5)
                    local st = S.standFor(fx, fy, x, y)
                    if st then best, bs = { obj = o, fx = fx, fy = fy, tx = x, ty = y, st = st, how = label .. " of the map, " .. state }, sc end
                end)
            end
        end
    end
    return best
end

-- ----- the input mode ZeD reads
-- the lock as found: ZeD setup's Input lock, as Settings.lua applies it at load ("auto" is no lock); the save's
-- modData copy only when the setting cannot be read (it is written on a change, so it can be stale)
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
-- mode "kbm" (the mouse pictures: a menu anchors at the click, as a mouse player's does) or "gamepad" (the wheels);
-- nil or false puts back the lock found
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

-- ----- the wheels
function S.wheelSt() return D.state and D.state[S.pn] or nil end
function S.closeWheel()
    pcall(function()
        local st = S.wheelSt()
        if st then pcall(D.close, S.pn) end
        st = S.wheelSt()
        if st and st.menu and st.menu.undisplay then st.menu:undisplay() end
        if D.state then D.state[S.pn] = nil end
        local m = getPlayerRadialMenu(S.pn)
        if m and m:isReallyVisible() then m:undisplay() end
    end)
    W.qaPoint = nil
end
function S.toWheel()
    S.closeWheel()
    S.closeMenu()
    pcall(S.Focus.releaseFocus, S.pn)
    S.closePair()
    pcall(S.Focus.releaseFocus, S.pn)
    pcall(function() setJoypadFocus(S.pn, nil) end)
    if GAL_UNLOAD and GAL_UNLOAD.park then pcall(GAL_UNLOAD.park) end
end
function S.openWheel(dir, fn)
    pcall(function() ISDPadWheels[fn]({ player = S.pn, id = nil }) end)
    local st = S.wheelSt()
    if st and st.dir == dir then return true end
    local ok, e = pcall(D.open, dir, { player = S.pn, id = nil })
    if not ok then Q.say("ERR open " .. dir .. ": " .. tostring(e)) end
    st = S.wheelSt()
    return st ~= nil and st.dir == dir
end
function S.slices()
    local st = S.wheelSt()
    return (st and st.menu and st.menu.slices) or {}
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
-- the wheel is on screen with the slice pointed (ZeD_Wheel's update has run on it)
function S.wheelDrawn(i)
    local st = S.wheelSt()
    local m = st and st.menu
    local vis = false
    pcall(function() vis = m ~= nil and m:isReallyVisible() end)
    return vis and m._zedPoint == i
end

-- ----- the hint strip
function S.hintWords(list)
    local words = {}
    for _, pr in ipairs(list or {}) do words[#words + 1] = tostring(pr.glyph) .. " " .. tostring(pr.label) end
    return (#words > 0) and table.concat(words, " ; ") or "nothing"
end
function S.hintNow()
    local ok, out = pcall(HS.prompts, S.pn)
    return ok and out or nil
end
function S.hasMore(list)
    local word = tostring(ZeD.tr("UI_ZeD_Hint_More"))
    for _, pr in ipairs(list or {}) do if tostring(pr.label) == word then return true end end
    return false
end
-- the strip's rules have run since t0 and the game's own prompt is the held radio's
function S.hintFresh(t0)
    local st = HS._eval and HS._eval[S.pn]
    return st ~= nil and (st.at or 0) > t0 and ISButtonPrompt ~= nil and st.aFn ~= nil and st.aFn == ISButtonPrompt.openDeviceOptions
end
function S.findInfo(full)
    local infos = SpriteConfigManager.GetObjectInfoList()
    for i = 0, infos:size() - 1 do
        local info = infos:get(i)
        local parent = info:getScript() and info:getScript():getParent()
        if parent and tostring(parent:getScriptObjectFullType()) == full then return info end
    end
    return nil
end
function S.snapshot(cx, cy, r)
    local set = {}
    for y = cy - r, cy + r do
        for x = cx - r, cx + r do
            local sq = S.sqAt(x, y)
            if sq then
                local objs = sq:getObjects()
                for i = 0, objs:size() - 1 do set[objs:get(i)] = true end
            end
        end
    end
    return set
end
-- a crafting station built with the game's build code and the build cheat (hfr_devices.lua's way), north or west of
-- the patch's middle; the first kind the game would open a station window for. Returns the part to stand in front of
function S.buildStation()
    local why = "no station kind could be built"
    for _, full in ipairs(S.STATIONS) do
        local info = nil
        pcall(function() info = S.findInfo(full) end)
        if info then
            for _, o in ipairs({ { 0, -2 }, { -2, 0 }, { -2, -2 }, { 1, -2 }, { -2, 1 } }) do
                local x, y = S.c.x + o[1], S.c.y + o[2]
                local before = S.snapshot(x, y, 2)
                S.p:setBuildCheat(true)
                pcall(function()
                    local b = ISBuildIsoEntity:new(S.p, info, 1, ISInventoryPaneContextMenu.getContainers(S.p))
                    b.buildCheat = true
                    b.player = S.pn
                    local sq = S.sqAt(x, y)
                    b.sq = sq
                    if b:isValid(sq) then b:create(x, y, 0, false, nil) end
                end)
                S.p:setBuildCheat(S.was.cheat == true)
                local new = {}
                for obj in pairs(S.snapshot(x, y, 2)) do if not before[obj] then new[#new + 1] = obj; S.built[#S.built + 1] = obj end end
                local isNew = {}
                for _, obj in ipairs(new) do pcall(function() isNew[obj:getSquare():getX() .. "," .. obj:getSquare():getY()] = true end) end
                for _, obj in ipairs(new) do
                    local can = false
                    pcall(function() can = ISEntityUI.CanOpenWindowFor(S.p, obj:getMasterObject()) and true or false end)
                    if can then
                        local ox, oy = obj:getSquare():getX(), obj:getSquare():getY()
                        for _, f in ipairs({ { 0, 1, "N" }, { 1, 0, "W" } }) do
                            local sx, sy = ox + f[1], oy + f[2]
                            if not isNew[sx .. "," .. sy] and S.goodSq(S.sqAt(sx, sy)) then
                                return { obj = obj, x = sx, y = sy, dir = f[3], full = full }
                            end
                        end
                        why = full .. " was built, with no bare square south or east of it"
                    end
                end
                if #new > 0 then
                    if why == "no station kind could be built" then why = full .. " was built, but the game opens no station window for it" end
                    S.removeAll()
                    break
                end
            end
        end
    end
    return nil, why
end

-- ----- a row of the Character list (hfr_inv.lua's way: the kind's stack opened first)
function S.openStackOf(it)
    local c, ft = S.cc(), nil
    pcall(function() ft = it:getFullType() end)
    if not (c and ft) then return end
    c._expandedStacks = c._expandedStacks or {}
    if S.stackWas[ft] == nil then S.stackWas[ft] = c._expandedStacks[ft] or false end
    c._expandedStacks[ft] = true
    for _, cs in ipairs(c._colStates or {}) do cs.expandedStacks = cs.expandedStacks or c._expandedStacks; cs.expandedStacks[ft] = true end
end
function S.stacksBack()
    pcall(function()
        local c = S.cc()
        for ft, v in pairs(S.stackWas) do
            if c and c._expandedStacks then c._expandedStacks[ft] = (v ~= false) and v or nil end
            for _, cs in ipairs((c and c._colStates) or {}) do if cs.expandedStacks then cs.expandedStacks[ft] = (v ~= false) and v or nil end end
        end
    end)
    S.stackWas = {}
end
-- the strip's track: where it is drawn (o) and where it belongs (want), in px
function S.stripAt(m)
    local c = ZeD.T.ctx
    return { o = m._ctx.trackOriginX or 0, want = -(((m._ctx.firstVisible or 1) - 1) * (c.cellW + c.gap)) }
end

-- ===================================================================== start
Q.step(5, function()
    S.start0()
    if getGameSpeed() ~= 1 then pcall(setGameSpeed, 1) end
    S.was.style = S.ctxOpt():getValue()
    pcall(function() S.was.hint = ZeD.Settings.hintStripOption:getValue() end)
    pcall(function() S.was.cheat = S.p:isBuildCheat() end)
    S.was.h1, S.was.h2 = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem()
    pcall(function() S.was.fatigue = S.p:getStats():get(CharacterStat.FATIGUE) end)
    pcall(function() S.was.slept = S.p:getLastHourSleeped() end)
    -- the mouse's input mode for the right-click and hint strip pictures (a controller mode anchors a world menu on
    -- the character and marks its first row); the wheels lock the controller's later; put back as found at the end
    S.lock("kbm")
    local c = S.P.smoke or S.P.centre
    S.c = S.findPatch(c[1], c[2])
    if not S.c then
        Q.say("ERR no open patch within 14 squares of the smoking spot " .. c[1] .. "," .. c[2] .. ": every picture is skipped")
        return
    end
    S.home("SE")
    S.closePair()
    Q.say("the patch's middle " .. S.c.x .. "," .. S.c.y .. " (the smoking spot " .. c[1] .. "," .. c[2] .. "), bare from " .. S.c.lo .. " to 2 round it"
        .. " | Context menu setting " .. tostring(S.was.style) .. ", Hint strip setting " .. tostring(S.was.hint)
        .. " | load " .. ((GAL_UNLOAD and GAL_UNLOAD.line) and GAL_UNLOAD.line() or "?"))
end)
Q.zoomTo(1.0)
S.settle(function() return S.c ~= nil end)

-- ===================================================================== B5-5: the list's heading names the thing
S.worldShot("B5-5_list_door", "a door", function()
    if not S.c then return nil, "no open patch" end
    local d = S.findOpening("IsoDoor", "a door")
    if d then return d end
    -- none on the camera side of a building: a door stood up on the patch (said in the picture's line)
    local sq = S.goodSq(S.sqAt(S.c.x + 2, S.c.y - 2))
    local spr = getSprite("fixtures_doors_01_1")
    if not (sq and spr) then return nil, "no door of the map with open ground on its camera side, and none could be stood up" end
    local o = IsoDoor.new(getCell(), sq, spr, true)
    sq:AddSpecialObject(o)
    if o:getObjectIndex() < 0 then sq:AddTileObject(o) end
    S.objs[#S.objs + 1] = o
    return { obj = o, fx = sq:getX() + 0.5, fy = sq:getY() + 0.15, tx = sq:getX(), ty = sq:getY(),
             how = "NOTE a door stood up on the patch: no door of the map has open ground on its camera side",
             after = function() S.removeObj(o) end }
end)
S.worldShot("B5-5_list_window", "a window", function()
    if not S.c then return nil, "no open patch" end
    local w = S.findOpening("IsoWindow", "a window")
    if w then return w end
    -- none on the camera side of a building: a stove placed on the patch, its own picture name (said in its line)
    local sq = S.goodSq(S.sqAt(S.c.x + 2, S.c.y - 2))
    local o, name = nil, nil
    if sq then o, name = S.placeStove(sq) end
    if not o then return nil, "no window of the map with open ground on its camera side, and no stove could be placed on the patch" end
    return { obj = o, fx = sq:getX() + 0.5, fy = sq:getY() + 0.5, tx = sq:getX(), ty = sq:getY(), pic = "B5-5_list_stove", label = "a stove",
             how = "NOTE a stove placed on the patch (" .. tostring(name) .. "): no window of the map has open ground on its camera side",
             after = function() S.removeObj(o) end }
end)
S.worldShot("B5-5_list_ground", "bare ground", function()
    if not S.c then return nil, "no open patch" end
    local sq = S.goodSq(S.sqAt(S.c.x + 2, S.c.y - 2))
    local o = sq and sq:getFloor() or nil
    if not o then return nil, "the patch's square is not bare" end
    return { obj = o, fx = sq:getX() + 0.5, fy = sq:getY() + 0.5, tx = sq:getX(), ty = sq:getY(), floor = true, how = "open ground on the patch" }
end)
Q.step(5, function() S.closeMenu(); S.style(S.was.style) end)

-- ===================================================================== W15: a strip of 11 or more, at rest from its first frame
S.w15 = { name = "W15_strip_at_rest" }
Q.step(10, function()
    if not S.c then S.skip(S.w15.name, "no open patch"); S.w15.done = true; return end
    S.home("SE")
    S.openPair()
end)
S.settle(function() return S.c ~= nil end)
Q.step(30, function()
    if S.w15.done then return end
    -- the windows at their default places; where they stood is kept for the put-back
    S.was.pos = {}
    for k, w in pairs({ c = S.CW(), w = S.WW() }) do
        if w then S.was.pos[k] = { x = w:getX(), y = w:getY() } end
    end
    pcall(function() ZeD_Window.resetLayout() end)
    S.charTab("loot"); S.worldTab("loot")
end)
Q.still(10, function() if not S.w15.done then S.clearChar() end end)
for _, ft in ipairs(S.LONG) do
    local t = {}
    Q.step(5, function()
        if S.w15.done then return end
        S.closeMenu()
        t.it = S.add(ft)
        if not t.it then Q.say(S.w15.name .. ": " .. ft .. " could not be given"); return end
        S.seekPos = nil
        S.openStackOf(t.it)
    end)
    Q.waitFor(5, 600, function() return S.w15.done or not t.it or S.seekRow(S.cc(), t.it) end, function(ok)
        if S.w15.done or not t.it then return end
        local c = S.cc()
        local z = S.zone(c, t.it)
        local x, y = nil, nil
        if z then
            pcall(function() x = S.fl(c:getAbsoluteX() + z.x + math.min(z.w / 2, ZeD.T.px(110))); y = S.fl(c:getAbsoluteY() + z.y + z.h / 2) end)
        end
        local w = S.CW()
        t.onRow = x ~= nil
        if not x and w then x, y = S.fl(w:getX() + w:getWidth() / 3), S.fl(w:getY() + w:getHeight() / 2) end
        if not x then return end
        local sw, sh = S.scr()
        x, y = math.max(40, math.min(sw - 40, x)), math.max(40, math.min(sh - 40, y))
        S.style(1)
        t.x, t.y, t.first = x, y, nil
        S.mouseOn(x, y)
        t.openMs = getTimestampMs()
        local okM, e = pcall(ISInventoryPaneContextMenu.createMenu, S.pn, true, { t.it }, x, y)
        if not okM then t.err = tostring(e) end
        t.asked = true
    end)
    -- the menu made: the pointer goes off every menu (a resting real pointer must not take a cell); the track read
    -- if the strip has drawn already
    Q.waitFor(1, 300, function()
        if S.w15.done or not t.asked or t.err ~= nil then return true end
        local m = S.menu()
        if m then
            if not t.first and m._ctx and m._ctx.firstVisible and m._layoutCache and (m._layoutCache.stripW or 0) > 0 then
                t.first, t.firstMs = S.stripAt(m), getTimestampMs() - t.openMs
            end
            return true
        end
        return S.menuSettled()
    end, function() if t.asked then S.mouseOn(-9000, -9000) end end)
    -- the strip's first drawn frame read, then one more: the picture is its third drawn frame or so, inside the time
    -- the old slide took (T.ctx.animMs), when a strip that still slid would show its cells part way along
    Q.waitFor(1, 120, function()
        if S.w15.done or not t.asked or t.err then return true end
        local m = S.menu()
        if not (m and m.Type == "ZeD_ContextMenu" and m._ctx and m._ctx.truncating) then return true end
        if not (m._ctx.firstVisible and m._layoutCache and (m._layoutCache.stripW or 0) > 0) then return false end
        if not t.first then t.first, t.firstMs = S.stripAt(m), getTimestampMs() - t.openMs; return false end
        return true
    end, function()
        if S.w15.done or not t.asked then return end
        local m = S.menu()
        local n = (m and m._ctx and m._ctx.items) and #m._ctx.items or 0
        if t.err or not (t.first and m and m.Type == "ZeD_ContextMenu" and m._ctx.truncating and n >= 11) then
            Q.say(S.w15.name .. ": " .. ft .. " gives " .. tostring(m and m.Type) .. " with " .. n .. " actions" .. (t.err and (", " .. t.err) or "")
                .. (t.first and "" or ", no drawn strip read") .. ": the next thing is tried")
            S.closeMenu()
            return
        end
        local s, c = S.stripAt(m), m._layoutCache
        local ctx = ZeD.T.ctx
        local ext = ctx.gutter + ctx.chevW
        local x0, y0 = m:getX() + c.stripX - ext, m:getY() + c.stripY
        local sw, sh = c.stripW + ext * 2, c.stripH
        local nm = "?"
        pcall(function() nm = t.it:getDisplayName() end)
        local still = math.abs(t.first.o - t.first.want) <= 1 and math.abs(s.o - s.want) <= 1
        S.w15.done, t.shot = true, true
        S.shotOk(S.w15.name, "Context menu on Strip, a right-click on " .. nm .. (t.onRow and " on its row of the Character list" or " (NOTE its row was not found: opened over the Character window)")
            .. ": a strip of " .. n .. " actions, the picture taken " .. (getTimestampMs() - t.openMs) .. " ms after the right-click (the old slide took "
            .. tostring(ctx.animMs) .. " ms); read " .. tostring(t.firstMs) .. " ms after it, on its first drawn frame, the track stood at " .. t.first.o
            .. " px, its place " .. t.first.want .. " px; now at " .. s.o .. " px"
            .. (still and ": every cell in its place from the first frame" or " (FAULT: the track slid)")
            .. "; the strip with its arrows at " .. S.fl(x0) .. "," .. S.fl(y0) .. " " .. S.fl(sw) .. "x" .. S.fl(sh)
            .. ", all on screen " .. tostring(S.onScreen(x0, y0, sw, sh))
            .. (S.over(x0, y0, sw, sh) and ", NOTE it lies over the character" or ", beside the character"), true)
    end)
    -- after the picture: the track keeps to its place for 20 drawn frames
    Q.waitFor(1, 60, function()
        if not t.shot then return true end
        local m = S.menu()
        if not (m and m._ctx and m._ctx.open) then t.gone = true; return true end
        local s = S.stripAt(m)
        t.after = (t.after or 0) + 1
        if math.abs(s.o - s.want) > 1 then t.off = (t.off or 0) + 1 end
        return t.after >= 20
    end, function()
        if t.shot then
            Q.say(S.w15.name .. ": after the picture the track was off its place on " .. tostring(t.off or 0) .. " of " .. tostring(t.after or 0)
                .. " drawn frames" .. (t.gone and " (the strip closed early)" or ""))
        end
    end)
    Q.step(5, function() S.closeMenu() end)
end
Q.step(5, function()
    if not S.w15.done then S.skip(S.w15.name, "none of the things tried opened a strip of 11 or more actions") end
    S.closeMenu()
    S.style(S.was.style)
    S.stacksBack()
    S.takeMade()
end)

-- ===================================================================== W55 / B6-7: the hint strip and a held radio
S.hint = {}
Q.step(10, function()
    if not S.c then S.skip("W55_radio_open_no_hint", "no open patch"); S.skip("B6-7_radio_station_more", "no open patch"); return end
    S.closeMenu()
    S.closePair()
    S.home("SE")
    pcall(function() ZeD.Settings.hintStripOption:setValue(1) end)   -- Always
    for _, ft in ipairs(S.RADIOS) do if not S.hint.radio then S.hint.radio = S.add(ft) end end
    if not S.hint.radio then S.skip("W55_radio_open_no_hint", "no walkie-talkie could be given"); S.skip("B6-7_radio_station_more", "no walkie-talkie could be given"); return end
    pcall(function() S.p:setSecondaryHandItem(nil); S.p:setPrimaryHandItem(S.hint.radio) end)
    -- (the pointer the game's Lua reads off every HUD: a belt balloon under a resting real pointer hides the strip)
    S.mouseOn(-9000, -9000)
    S.hint.t0 = getTimestampMs() + 250
    S.hint.on = true
end)
S.settle(function() return S.hint.on == true end)
S.wait(4000, function() return not S.hint.on or S.hintFresh(S.hint.t0) end, function(ok)
    S.hint.staged = S.hint.on and ok
    if S.hint.on and not ok then
        local st = HS._eval and HS._eval[S.pn]
        S.skip("W55_radio_open_no_hint", "the game's prompt for the held radio is not Device Options (it says '" .. tostring(st and st.a)
            .. "'; a controller bound: " .. tostring(JoypadState.players[S.pn + 1] ~= nil) .. ")")
    end
end)
Q.step(4, function()
    if not S.hint.staged then return end
    local out = S.hintNow()
    local nm = "?"
    pcall(function() nm = S.hint.radio:getDisplayName() end)
    S.shotOk("W55_radio_open_no_hint", nm .. " in the main hand (its box on the belt), in the open with nothing in front of him, Hint strip on Always: the strip offers "
        .. S.hintWords(out) .. (S.hasMore(out) and " (FAULT: Right-click More is still shown)" or " (no Right-click More above the belt)"))
end)
Q.step(10, function()
    if not S.hint.on then return end
    local okB, st, why = pcall(S.buildStation)
    if not (okB and st) then S.skip("B6-7_radio_station_more", okB and tostring(why) or ("the build threw: " .. tostring(st))); return end
    S.hint.st = st
    G1.tp({ st.x, st.y }, st.dir)
    pcall(function() if S.p:getPrimaryHandItem() ~= S.hint.radio then S.p:setPrimaryHandItem(S.hint.radio) end end)
    S.hint.t1 = getTimestampMs() + 250
    Q.say("station " .. st.full .. " built, he stands at " .. st.x .. "," .. st.y .. " facing " .. st.dir)
end)
S.settle(function() return S.hint.st ~= nil end)
S.wait(5000, function() return not S.hint.st or (S.hintFresh(S.hint.t1) and S.hasMore(S.hintNow())) end, function(ok) S.hint.more = ok end)
Q.step(4, function()
    if not S.hint.st then return end
    local out = S.hintNow()
    local es = HS._eval and HS._eval[S.pn]
    if not S.hint.more then
        S.skip("B6-7_radio_station_more", "in front of " .. S.hint.st.full .. " the strip offers " .. S.hintWords(out)
            .. " (the game's prompt '" .. tostring(es and es.a) .. "', a station in front " .. tostring(es and es.station) .. ")")
        return
    end
    local nm, sn = "?", S.hint.st.full
    pcall(function() nm = S.hint.radio:getDisplayName() end)
    pcall(function() sn = tostring(S.hint.st.obj:getMasterObject():getEntityDisplayName()) end)
    S.shotOk("B6-7_radio_station_more", nm .. " in the main hand, facing a crafting station (" .. sn .. ") one square "
        .. ((S.hint.st.dir == "N") and "north" or "west") .. " of him: the strip offers " .. S.hintWords(out))
end)
Q.step(5, function()
    S.mouseOff()
    pcall(function() S.p:setPrimaryHandItem(S.was.h1); S.p:setSecondaryHandItem(S.was.h2) end)
    S.takeMade()
    S.removeAll()
    pcall(function() if S.was.hint then ZeD.Settings.hintStripOption:setValue(S.was.hint) end end)
    S.home("SE")
end)

-- ===================================================================== B7-3: the wheel names the chair and the bed
-- (the chair two squares south west, level with him on screen and clear of the wheel's cells; he faces it, so it is
-- in his view and not dimmed)
S.ch = {}
Q.step(10, function()
    if not S.c then S.skip("B7-3_wheel_sit_on_chair", "no open patch"); return end
    S.home("SW")
    local o, why = S.placeSeat(S.CHAIRS, S.goodSq(S.sqAt(S.c.x - 2, S.c.y + 2)), false)
    if not o then S.skip("B7-3_wheel_sit_on_chair", "a chair could not be placed: " .. tostring(why)); return end
    S.ch.o = o
    Q.say("chair placed two squares south west of him: " .. tostring(why))
    S.lock("gamepad")
    S.toWheel()
end)
S.settle(function() return S.ch.o ~= nil end)
Q.step(20, function()
    if not S.ch.o then return end
    S.toWheel()   -- (again: the lock to the controller can hand the pad to a window a frame later)
    local seat = nil
    pcall(function() seat = D.H.nearestSeat(S.p) end)
    S.ch.name = S.seatName(seat)
    S.ch.own = (seat == S.ch.o)
end)
Q.step(20, function()
    if not S.ch.o then return end
    if not S.openWheel("down", "onDisplayDown") then S.skip("B7-3_wheel_sit_on_chair", "the Here and now wheel did not open"); S.ch.o2 = true; return end
    local st, e = S.wheelSt(), nil
    for _, x in ipairs(st.path[1].entries or {}) do if x.sub == D.N.sit then e = x end end
    if not e or e.off then S.skip("B7-3_wheel_sit_on_chair", "the wheel's Sit slice is " .. tostring(e and e.off or "missing")); S.ch.o2 = true; return end
    pcall(D.enter, S.pn, e)
end)
Q.step(10, function()
    if not S.ch.o or S.ch.o2 then return end
    if #S.slices() >= 2 then W.qaPoint = 2 end
end)
Q.waitFor(1, 300, function() return not S.ch.o or S.ch.o2 or S.wheelDrawn(2) end, function() end)
Q.step(4, function()
    if not S.ch.o or S.ch.o2 then return end
    if not S.wheelDrawn(2) then S.skip("B7-3_wheel_sit_on_chair", "the Sit ring is not on screen with its seat slice pointed (slices " .. #S.slices() .. ")"); return end
    local text = S.sliceText(2)
    local named = S.ch.name ~= nil and tostring(S.slices()[2].text):find(tostring(S.ch.name), 1, true) ~= nil
    S.shotOk("B7-3_wheel_sit_on_chair", "a chair two squares south west of him (" .. tostring(S.ch.name) .. ", the wheel's nearest seat is the one placed: " .. tostring(S.ch.own)
        .. "), D-pad Down, Sit: the seat slice reads \"" .. text .. "\"" .. (named and " (\"Sit on a seat\" before the fix)" or " (FAULT: it does not name the chair)"))
end)
Q.step(10, function()
    S.closeWheel()
    if S.ch.o then S.removeObj(S.ch.o) end
end)

S.bd = {}
Q.step(15, function()
    if not S.c then S.skip("B7-3_wheel_sleep_names_bed", "no open patch"); return end
    S.home("SE")
    local o, why = S.placeSeat(S.BEDS, S.goodSq(S.sqAt(S.c.x - 2, S.c.y - 2)), true)
    if not o then S.skip("B7-3_wheel_sleep_names_bed", "a bed could not be placed: " .. tostring(why)); return end
    S.bd.o = o
    Q.say("bed placed north west of him: " .. tostring(why))
end)
Q.step(20, function()
    if not S.bd.o then return end
    local sl = nil
    pcall(function() sl = D.H.sitWheel(S.p, S.pn) end)
    local run = sl and sl[2] and sl[2].run
    if not run then S.skip("B7-3_wheel_sleep_names_bed", "the wheel's seat slice is off: " .. tostring(sl and sl[2] and sl[2].off)); S.bd.o2 = true; return end
    Q.say("the wheel's seat slice: " .. tostring(sl[2].name))
    local ok, e = pcall(run, S.p, S.pn)
    if not ok then S.skip("B7-3_wheel_sleep_names_bed", "the seat slice threw: " .. tostring(e)); S.bd.o2 = true end
end)
S.wait(15000, function() return not S.bd.o or S.bd.o2 or S.p:isSittingOnFurniture() end, function(ok)
    if not S.bd.o or S.bd.o2 then return end
    if not ok then S.skip("B7-3_wheel_sleep_names_bed", "the game did not sit him on the bed"); S.bd.o2 = true; S.getUp(); return end
    -- tired enough to sleep (under the Drowsy moodle's level), the last sleep long ago
    pcall(function() S.p:getStats():set(CharacterStat.FATIGUE, 0.45) end)
    pcall(function() S.p:setLastHourSleeped(math.floor(S.p:getHoursSurvived()) - 10) end)
    pcall(function() S.bd.name = S.seatName(S.p:getSitOnFurnitureObject()) end)
end)
S.wait(4000, function()
    if not S.bd.o or S.bd.o2 then return true end
    local ok, r = pcall(D.H.sleep, S.p, S.pn)
    return ok and r and r.run ~= nil
end, function(ok)
    if not S.bd.o or S.bd.o2 then return end
    if not ok then
        local _, r = pcall(D.H.sleep, S.p, S.pn)
        S.skip("B7-3_wheel_sleep_names_bed", "sitting on the bed, the Sleep slice stays off: " .. tostring(type(r) == "table" and r.off or r))
        S.bd.o2 = true
    end
end)
S.settle(function() return S.bd.o ~= nil and not S.bd.o2 end)
Q.step(10, function() if S.bd.o and not S.bd.o2 then S.lock("gamepad"); S.toWheel() end end)   -- (the lock too: the chair's picture may have been skipped before it)
Q.step(20, function()
    if not S.bd.o or S.bd.o2 then return end
    if not S.openWheel("left", "onDisplayLeft") then S.skip("B7-3_wheel_sleep_names_bed", "the Character wheel did not open"); S.bd.o2 = true; return end
    S.bd.i = S.sliceStarting(getText("ContextMenu_Sleep"))
    if not S.bd.i then S.skip("B7-3_wheel_sleep_names_bed", "no Sleep slice on the Character wheel"); S.bd.o2 = true; return end
    W.qaPoint = S.bd.i
end)
Q.waitFor(1, 300, function() return not S.bd.o or S.bd.o2 or S.wheelDrawn(S.bd.i) end, function() end)
Q.step(4, function()
    if not S.bd.o or S.bd.o2 then return end
    if not (S.p:isSittingOnFurniture() and S.wheelDrawn(S.bd.i)) then
        S.skip("B7-3_wheel_sleep_names_bed", "sitting " .. tostring(S.p:isSittingOnFurniture()) .. ", the wheel with its Sleep slice pointed " .. tostring(S.wheelDrawn(S.bd.i)))
        return
    end
    local text = S.sliceText(S.bd.i)
    local named = S.bd.name ~= nil and tostring(S.slices()[S.bd.i].text):find(tostring(S.bd.name), 1, true) ~= nil
    S.shotOk("B7-3_wheel_sleep_names_bed", "sitting on a bed (" .. tostring(S.bd.name) .. "), D-pad Left: the Sleep slice reads \"" .. text .. "\""
        .. (named and " (\"Sleep on Ground\" before the fix)" or " (FAULT: it does not name the bed)"))
end)
Q.step(10, function()
    S.closeWheel()
    S.lock(false)
    S.getUp()
end)
S.wait(9000, function() return not S.sitting() end, function(ok) if not ok then Q.say("note: he was still sitting after 9 s") end end)

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    S.closeMenu()
    S.closeWheel()
    S.lock(false)
    pcall(function() S.p:setBuildCheat(S.was.cheat == true) end)
    S.getUp()
end)
S.wait(9000, function() return not S.sitting() end, function(ok)
    if not ok then pcall(function() S.p:setSitOnGround(false) end) end
end)
Q.step(5, function()
    pcall(function() ISTimedActionQueue.clear(S.p) end)
    pcall(function() if S.p:getPrimaryHandItem() ~= S.was.h1 then S.p:setPrimaryHandItem(S.was.h1) end end)
    pcall(function() if S.p:getSecondaryHandItem() ~= S.was.h2 then S.p:setSecondaryHandItem(S.was.h2) end end)
    S.stacksBack()
    S.takeMade()
    S.removeAll()
    S.style(S.was.style)
    pcall(function() if S.was.hint then ZeD.Settings.hintStripOption:setValue(S.was.hint) end end)
    pcall(function() if S.was.fatigue then S.p:getStats():set(CharacterStat.FATIGUE, S.was.fatigue) end end)
    pcall(function() if S.was.slept then S.p:setLastHourSleeped(S.was.slept) end end)
    S.mouseOff()
    local mode, cheat = "?", "?"
    pcall(function() mode = tostring(S.Det.getMode(S.pn)) end)
    pcall(function() cheat = tostring(S.p:isBuildCheat()) end)
    Q.say("put back: things given taken away, hands as found, placed tiles still standing " .. S.standing()
        .. ", Context menu setting " .. tostring(S.ctxOpt():getValue()) .. " (found " .. tostring(S.was.style) .. "), Hint strip setting "
        .. tostring(ZeD.Settings.hintStripOption:getValue()) .. " (found " .. tostring(S.was.hint) .. "), input lock as found ("
        .. tostring(S.lockWas) .. "; ZeD reads " .. mode .. "), build cheat " .. cheat .. " (found " .. tostring(S.was.cheat) .. "), wheel pointer "
        .. tostring(W.qaPoint) .. ", mouse swap " .. tostring(S.mouseSwapped == true))
    G1.glassesBack(Q)
end)
Q.step(20, function()
    S.openPair()
    S.charTab("loot"); S.worldTab("loot")
end)
Q.step(30, function()
    -- the windows where they stood
    for k, w in pairs({ c = S.CW(), w = S.WW() }) do
        local was = S.was.pos and S.was.pos[k]
        if w and was then
            pcall(function()
                w:setX(was.x); w:setY(was.y)
                if w._anchorRightEdge ~= nil then w._anchorRightEdge = was.x + w:getWidth() end
            end)
        end
    end
    local hurt = false
    pcall(function() hurt = S.p:getBodyDamage():getOverallBodyHealth() < 99 end)
    if hurt then pcall(function() S.p:getBodyDamage():RestoreToFullHealth() end) end
    if S.P.stock then G1.tp(S.P.stock, "SE") end
    S.back0()
end)
Q.step(30, function()
    if not S.was.pairOpen then S.closePair() end
    pcall(function() Mouse.setCursorVisible(true) end)
    Q.say("put back: windows and game speed as found; sitting " .. tostring(S.sitting()) .. ", alive " .. tostring(not S.p:isDead())
        .. "; pictures taken: " .. ((#S.pic > 0) and table.concat(S.pic, ", ") or "none"))
end)
Q.start()
