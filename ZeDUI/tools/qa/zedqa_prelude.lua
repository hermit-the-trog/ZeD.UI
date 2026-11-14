-- ZeDUI/tools/qa/zedqa_prelude.lua  (Oct 19 2026)
-- In game on the ZeD-QA save: the first line of the unattended regression
-- (zedqa_run.ps1, regression.txt). Opens the window pair if it is shut (the
-- suites need both windows), unpauses, turns on god mode (the QA character
-- once starved at speed), waits about 60 ticks for the windows to settle and
-- prints "ZEDQA pre DONE". If OnTick never ran (the game is still paused) it
-- says so as an ERR line, so the run reads WARN instead of timing out.
-- grep "ZEDQA pre".
-- Nov 12 2026 (test cleanup, phase 2): it also puts every ZeD window at its default layout with the console
-- closed, and defines the shared helpers the scripts call: ZEDQA_HOME, ZEDQA_LAYOUT_* (the window rule) and
-- ZEDQA_CAR_* (one car spawn on the strip's marked stretch).
local function say(s) print("ZEDQA pre " .. tostring(s)) end

-- Nov 8 2026: the windows let their controller stops wait while the mouse is in use (Focus.stopsMayWait);
-- QA scripts read w._focusRing directly, so keep them fresh every frame. Set it to nil to test the waiting itself.
ZEDQA_FRESH_STOPS = true

-- (Nov 13 2026, Build and the director: "It didn't look like things were in fast forward". setGameSpeed only moves the speed
-- index; the game's time multiplier stayed 1, so a script's fast-forward ran at normal speed. The game's own buttons set
-- both. ZEDQA_SPEED(n) does what its buttons do: 0 paused, 1 x1, 2 x5, 3 x20, 4 x40, and logs the true multiplier the first
-- time a fast speed takes. Scripts that speed up shadow setGameSpeed with it ("local setGameSpeed = ZEDQA_SPEED or
-- setGameSpeed"). Walks still run at speed 2 or less: the game drops a walk above game speed 2.)
local ZEDQA_MULT = { [0] = 1, [1] = 1, [2] = 5, [3] = 20, [4] = 40 }
local realSetGameSpeed = setGameSpeed
function ZEDQA_SPEED(n)
    if not realSetGameSpeed then return end
    realSetGameSpeed(n)
    pcall(function() getGameTime():setMultiplier(ZEDQA_MULT[n] or 1) end)
    if (n or 0) > 1 and not ZEDQA_SPEED_SAID then
        ZEDQA_SPEED_SAID = true
        local tm = "?"
        pcall(function() tm = tostring(getGameTime():getTrueMultiplier()) end)
        print("ZEDQA ff speed " .. tostring(n) .. ": time multiplier " .. tostring(ZEDQA_MULT[n]) .. ", true multiplier " .. tm)
    end
end

-- (punch list 47, Nov 2 2026) the vehicle probe for the 1280x720 bisect: where the character stands, how wide
-- the loaded chunk grid is and what it covers, and whether a spawn square and its car lie inside it. The
-- vehicle scripts call it right after their spawn when it exists (a script run alone skips it). One line
-- each; grep "ZEDQA vp".
function ZEDQA_VPROBE(tag, sq, v)
    local ok, line = pcall(function()
        local pl, cell = getPlayer(), getCell()
        local cm = cell:getChunkMap(0)
        local wt = cm:getWidthInTiles()
        local px, py = pl:getX(), pl:getY()
        local out = string.format("ZEDQA vp %s player=%d,%d grid=%d chunks (%d tiles) loaded x %d-%d y %d-%d",
            tostring(tag), math.floor(px), math.floor(py), math.floor(wt / 8), wt,
            cm:getWorldXMinTiles(), cm:getWorldXMaxTiles(), cm:getWorldYMinTiles(), cm:getWorldYMaxTiles())
        if sq then
            local sx, sy = sq:getX(), sq:getY()
            out = out .. string.format(" sq=%d,%d dist=%.1f chunk=%s inMap=%s", sx, sy,
                math.sqrt((sx - px) ^ 2 + (sy - py) ^ 2), tostring(sq:getChunk() ~= nil), tostring(cell:isInChunkMap(sx, sy)))
        else
            out = out .. " sq=nil"
        end
        if v then
            out = out .. string.format(" car=%s at %.1f,%.1f dist=%.1f", tostring(v:getScriptName()), v:getX(), v:getY(),
                math.sqrt((v:getX() - px) ^ 2 + (v:getY() - py) ^ 2))
        else
            out = out .. " car=nil"
        end
        local vs = cell:getVehicles()
        return out .. " vehicles=" .. tostring(vs and vs:size())
    end)
    print(ok and line or ("ZEDQA vp " .. tostring(tag) .. " ERR " .. tostring(line)))
end
-- ============================================================================
-- (Nov 12 2026, test cleanup plan rule 5 and amendment 8: the window rule) The run starts from the default window
-- layout with the console closed, and a script that moves, folds, pins or resizes a window puts the layout back
-- when it ends, on an error too. The helpers, used by this prelude and by the scripts:
--   ZEDQA_LAYOUT_DEFAULT(tag)   the console, the guide, Messages and the studio closed; both windows at the default
--                               spread through the mod's own ZeD_Window.resetLayout (unrolled, unfolded, on Loot,
--                               drawers shut); both pinned (what zedqa_pin_windows.lua did); the bag as a list
--   local snap = ZEDQA_LAYOUT_SNAP()        each window's place, size, rolled state and pins
--   ZEDQA_LAYOUT_BACK(snap, tag)            puts that back; never throws; with no snap it is ZEDQA_LAYOUT_DEFAULT
--   ZEDQA_LAYOUT_IS_DEFAULT()               true when both windows stand where this prelude left them
-- A script run without the prelude finds them nil: call them as "if ZEDQA_LAYOUT_BACK then ... end".
-- ============================================================================
local QA_KEYS = { "char", "world" }
local function qaWin(k)
    if k == "char" then return ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow() or nil end
    return ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow() or nil
end
local function pinHalves(w, inv, drawer)
    if not w then return end
    if w._halves and ZeD.Halves and ZeD.Halves.setPin then
        ZeD.Halves.setPin(w, "inv", inv); ZeD.Halves.setPin(w, "drawer", drawer)
    elseif w.setPinned then w:setPinned(inv and drawer)
    else w.pinned = (inv and drawer) and true or false end
end

function ZEDQA_LAYOUT_SNAP()
    local snap = {}
    for _, k in ipairs(QA_KEYS) do
        local w = qaWin(k)
        if w then
            local h = w._halves
            local pi, pd = w.pinned == true, w.pinned == true
            if h then pi, pd = (h.inv and h.inv.pinned == true) or false, (h.drawer and h.drawer.pinned == true) or false end
            snap[k] = { x = w:getX(), y = w:getY(), w = w:getWidth(), h = w:getHeight(), rolled = w._rolled and true or false,
                        pinInv = pi, pinDrawer = pd }
        end
    end
    return snap
end

function ZEDQA_LAYOUT_DEFAULT(tag)
    local notes = {}
    pcall(function()
        if ZeD.DebugConsole and ZeD.DebugConsole.isOpen and ZeD.DebugConsole.isOpen() then ZeD.DebugConsole.close(); notes[#notes + 1] = "console closed" end
    end)
    pcall(function()
        local jc = UIManager.getDebugConsole()
        if jc and jc:isVisible() then jc:setVisible(false); notes[#notes + 1] = "game console closed" end
    end)
    pcall(function() if ZeD.GuideBook and ZeD.GuideBook.isOpen and ZeD.GuideBook.isOpen(0) then ZeD.GuideBook.close(0); notes[#notes + 1] = "guide book closed" end end)
    pcall(function() if ZeD.Studio and ZeD.Studio.isOpen and ZeD.Studio.isOpen() then ZeD.Studio.close(); notes[#notes + 1] = "studio closed" end end)
    for _, name in ipairs({ "Guide", "MessagesWindow" }) do
        pcall(function()
            local t = ZeD[name]
            local pn = getPlayer() and getPlayer():getPlayerNum() or 0
            local win = t and ((t.get and t.get(pn)) or (t.windows and t.windows[pn]))   -- (a shut window is left shut: never ZeD.Guide.toggle)
            if win and win:isVisible() then win:close(); notes[#notes + 1] = name .. " closed" end
        end)
    end
    local ok, e = pcall(function()
        if not (ZeD_Window and ZeD_Window.resetLayout) then error("ZeD_Window.resetLayout is missing") end
        ZeD_Window.resetLayout()
    end)
    if not ok then print("ZEDQA layout " .. tostring(tag) .. " ERR reset: " .. tostring(e)) end
    pcall(function()
        local md = getPlayer():getModData()
        md.ZeD_WinPinned = md.ZeD_WinPinned or {}
        md.ZeD_WinPinned.char, md.ZeD_WinPinned.world = true, true
    end)
    for _, k in ipairs(QA_KEYS) do
        local w = qaWin(k)
        if w then pcall(function() pinHalves(w, true, true); if w.windowShaded then w:setWindowShaded(false) end end) end
    end
    pcall(function()
        local IR = ZeD.InventoryRenderer
        local pl = getPlayer()
        local key = IR and IR.containerKey and pl and IR.containerKey(pl:getInventory(), pl)
        if key and IR.isGridKey(key) then IR.setGridKey(key, false); notes[#notes + 1] = "bag back to a list" end
    end)
    if tag then print("ZEDQA layout " .. tostring(tag) .. " default" .. (#notes > 0 and (" (" .. table.concat(notes, ", ") .. ")") or "")) end
    return ok
end

function ZEDQA_LAYOUT_BACK(snap, tag)
    local ok, e = pcall(function()
        -- first the mod's own reset (unrolls, unfolds, Loot, drawers shut), then whatever the snapshot had that differs
        ZEDQA_LAYOUT_DEFAULT(nil)
        if type(snap) ~= "table" then return end
        for _, k in ipairs(QA_KEYS) do
            local w, s = qaWin(k), snap[k]
            if w and s then
                if not s.rolled then
                    if w:getWidth() ~= s.w then w:setWidth(s.w) end
                    if w:getHeight() ~= s.h then w:setHeight(s.h) end
                end
                if w:getX() ~= s.x then w:setX(s.x) end
                if w:getY() ~= s.y then w:setY(s.y) end
                pinHalves(w, s.pinInv, s.pinDrawer)
                if s.rolled and ZeD.Curtain and ZeD.Curtain.roll then ZeD.Curtain.roll(w) end
            end
        end
    end)
    if tag then print("ZEDQA layout " .. tostring(tag) .. (ok and " put back" or (" ERR put back: " .. tostring(e)))) end
    return ok
end

function ZEDQA_LAYOUT_IS_DEFAULT()
    local d = ZEDQA_LAYOUT_DEF
    if type(d) ~= "table" then return false end
    for _, k in ipairs(QA_KEYS) do
        local w, s = qaWin(k), d[k]
        if not (w and s) then return false end
        if w._rolled or w:getX() ~= s.x or w:getY() ~= s.y or w:getWidth() ~= s.w or w:getHeight() ~= s.h then return false end
    end
    return true
end

local p = getPlayer()
-- (Oct 27 2026, the director: the QA character stood in thick woods, with no open ground to
-- spawn things and the view often blocked, and runs drifted into night) every run starts on
-- Irvington Speedway's drag strip, open asphalt, in daylight. The save keeps the move.
local HOME = { x = 925.5, y = 13040.5, z = 0 }
local moved = false

-- (punch list 47, Nov 2 2026) the drag strip for every script that needs open ground. Scripts 57, 61 and 63
-- (cb, bg, ws) leave the character in the grandstand at about 964,13079; a car spawned beside it then stands
-- indoors and its physics never wakes (QA's moved-sl run at 720), and at 720 the grandstand's
-- west end (892) is outside the loaded grid, so rst's fixture is not found. The vehicle scripts and rst call
-- this first; it moves the character (out of any car) to the strip when it is elsewhere and says so.
-- Returns true when it moved. A script run without the prelude skips it.
function ZEDQA_HOME(tag)
    local pl = getPlayer()
    if not pl then return false end
    local car = pl:getVehicle()
    if car then car:exit(pl); triggerEvent("OnExitVehicle", pl) end
    if math.abs(pl:getX() - HOME.x) <= 3 and math.abs(pl:getY() - HOME.y) <= 3 and math.floor(pl:getZ()) == HOME.z then return false end
    print("ZEDQA home " .. tostring(tag) .. " moved from " .. math.floor(pl:getX()) .. "," .. math.floor(pl:getY()) .. "," .. math.floor(pl:getZ()) .. " to the drag strip")
    pl:setX(HOME.x); pl:setY(HOME.y); pl:setZ(HOME.z); pl:setLastX(HOME.x); pl:setLastY(HOME.y); pl:setLastZ(HOME.z)
    return true
end
-- ============================================================================
-- (Nov 12 2026, test cleanup plan rule 7) ONE copy of the car staging. Ten scripts each carried their own "find a
-- free square, spawn, wait for the physics, seat the driver" block with a one-tile check, and every timing fix had to
-- be made in each. The helper spawns on the marked stretch of the drag strip: ten candidate spots round the home square, each taken only on a road or pavement floor
-- (925,13040), all on the open asphalt between the grandstands (x 875-893 and 964-977), never the grandstand.
--   local v, why = ZEDQA_CAR_SPAWN(script, tag [, dir])   a car facing north on the next clear spot, or nil and why.
--                                   The WHOLE footprint is checked (3 x 7 tiles: loaded, outdoors, free, no tree, no
--                                   car on it or within 3 tiles), not one tile. Spots are taken in turn, because a
--                                   square a car was just removed from gives the next car no physics.
--   ZEDQA_CAR_READY(v)              true once the car has a square, a chunk and its physics was seen awake once
--                                   (isPhysicsActive means "awake": it goes off again when the car rests), and it
--                                   stands within 25 tiles of the character. Poll it every few ticks.
--   ZEDQA_CAR_WAIT(script, tag, onReady, onFail [, capMs])   spawn and wait: onReady(v) when ready; a car not ready
--                                   in capMs (default 4000) is taken away and the next spot tried; onFail(why) when
--                                   no spot gave a ready car.
--   local key = ZEDQA_CAR_PREP(v)   repaired, tank and battery full, its key in the character's inventory
--   ZEDQA_CAR_ENTER(v [, seat])     seats the character; REFUSES (false, why) a car that is not ready or is more than
--                                   25 tiles away: seating a far or sleeping car drops the game to the main menu
--   ZEDQA_CAR_AWAY(v [, key])       the character out, the key out of the inventory, the car removed. The removal
--                                   waits for a later tick with the character out of the car (42.22: removing it
--                                   in the tick of the exit is a NullPointerException and the main menu).
-- A script run without the prelude finds these nil and must say so as an ERR line.
-- ============================================================================
local CAR_SPOTS = { { 5, 2 }, { 5, -3 }, { -5, 2 }, { 2, 5 }, { -4, -4 }, { 6, 6 }, { -6, 0 }, { -8, 3 }, { -8, -3 }, { -3, 7 }, { -8, -10 }, { -15, -3 }, { -8, -16 } }   -- from home; a car faces north
-- (Nov 12 2026, the first main run: only spot 9, 917,13037, passed the floor check, so spots 11 to 13 are more
-- candidates beside it. The floor check still judges each one.)
-- (Nov 12 2026) the floor under a car must be road or pavement: the first smoke run put a car on grass beside a shed at
-- 930,13042. The coordinates of the asphalt are NOT yet established from the repo (nothing on record names them), so
-- each spot is judged by the floor sprite of five tiles (the middle, both ends, both sides): a name with street, road,
-- asphalt, blacktop or pavement in it passes (blends_street_* are the game's road tiles). A spot that fails says so
-- with the sprite name, and the next spot is tried. Spots 8 to 10 are extra candidates to the west.
local function carFloorName(sq)
    local nm = ""
    pcall(function() local f = sq:getFloor(); nm = string.lower(tostring(f and f:getSprite() and f:getSprite():getName() or "")) end)
    return nm
end
local function carFloorRoad(nm)
    for _, w in ipairs({ "street", "road", "asphalt", "blacktop", "pavement" }) do
        if string.find(nm, w, 1, true) then return true end
    end
    return false
end
local CAR_FLOOR = { { 0, 0 }, { 0, -3 }, { 0, 3 }, { -1, 0 }, { 1, 0 } }
local CAR_NEAR = 25
local carNext, carSeen, carGone = 0, {}, {}
ZEDQA_CAR_KEEP = {}   -- a script that wants two cars at once sets ZEDQA_CAR_KEEP[v] = true on the first, nil after
local function carDist(v, pl)
    local dx, dy = v:getX() - pl:getX(), v:getY() - pl:getY()
    return math.sqrt(dx * dx + dy * dy)
end
local function carSpotClear(cx, cy)
    local cell = getCell()
    for dy = -3, 3 do
        for dx = -1, 1 do
            local sq = cell:getGridSquare(cx + dx, cy + dy, 0)
            if not sq then return false, "a square of the footprint is not loaded" end
            local ok, bad = pcall(function()
                if sq:getChunk() == nil then return "no chunk" end
                if not sq:isFree(false) then return "not free" end
                if sq:HasTree() then return "a tree" end
                if sq:getVehicleContainer() then return "a car on it" end
                if sq:getRoom() ~= nil then return "indoors" end
                return nil
            end)
            if not ok then return false, "the footprint could not be read" end
            if bad then return false, bad .. " at " .. (cx + dx) .. "," .. (cy + dy) end
        end
    end
    for _, o in ipairs(CAR_FLOOR) do
        local nm = carFloorName(cell:getGridSquare(cx + o[1], cy + o[2], 0))
        if not carFloorRoad(nm) then return false, "the floor is not road or pavement (" .. (nm == "" and "no floor" or nm) .. ") at " .. (cx + o[1]) .. "," .. (cy + o[2]) end
    end
    local busy = false
    pcall(function()
        local it = cell:getVehicles():iterator()
        while it:hasNext() do
            local o = it:next()
            if math.abs(o:getX() - (cx + 0.5)) < 3.5 and math.abs(o:getY() - (cy + 0.5)) < 5.5 then busy = true end
        end
    end)
    if busy then return false, "another car within 3 tiles" end
    return true
end

function ZEDQA_CAR_SPAWN(script, tag, dir)
    local pl = getPlayer()
    if not pl then return nil, "no player" end
    -- (the character on the strip first: a car spawned beside a character indoors never wakes)
    if pl:getVehicle() == nil and (math.abs(pl:getX() - HOME.x) > 12 or math.abs(pl:getY() - HOME.y) > 12 or math.floor(pl:getZ()) ~= HOME.z) then
        ZEDQA_HOME(tag)
    end
    local hx, hy = math.floor(HOME.x), math.floor(HOME.y)
    local why = "no spot tried"
    -- (Nov 12 2026: a car an earlier script spawned here and never took away sat on the one good spot and refused every
    -- later spawn, 14 in one run. A car this helper spawned, with the character not in it and not already on its way
    -- out, is taken away before the spots are judged. Cars the helper did not spawn are left alone.)
    local old = {}
    for ov in pairs(carSeen) do
        local going = false
        for _, g in ipairs(carGone) do if g.v == ov then going = true end end
        if not going and pl:getVehicle() ~= ov and not ZEDQA_CAR_KEEP[ov] then old[#old + 1] = ov end
    end
    -- (a script may have removed its car itself: only a car still in the cell is taken away, the rest are forgotten)
    local live = {}
    pcall(function() local it = getCell():getVehicles():iterator(); while it:hasNext() do live[it:next()] = true end end)
    for _, ov in ipairs(old) do
        carSeen[ov] = nil
        if live[ov] then
            pcall(function() ov:permanentlyRemove() end)
            print("ZEDQA car " .. tostring(tag) .. " took away a car an earlier spawn left behind")
        end
    end
    for _ = 1, #CAR_SPOTS do
        carNext = carNext + 1
        if carNext > #CAR_SPOTS then carNext = 1 end
        local o = CAR_SPOTS[carNext]
        local cx, cy = hx + o[1], hy + o[2]
        local clear, w = carSpotClear(cx, cy)
        if clear then
            local sq = getCell():getGridSquare(cx, cy, 0)
            local okV, v = pcall(addVehicleDebug, script, dir or IsoDirections.N, nil, sq)
            if ZEDQA_VPROBE then ZEDQA_VPROBE(tag, sq, okV and v or nil) end
            if okV and v then
                carSeen[v] = false
                print("ZEDQA car " .. tostring(tag) .. " " .. tostring(script) .. " spawned on spot " .. carNext .. " (" .. cx .. "," .. cy .. ")")
                return v, sq
            end
            why = "addVehicleDebug gave no car for " .. tostring(script)
        else
            why = "spot " .. carNext .. " (" .. cx .. "," .. cy .. "): " .. tostring(w)
        end
    end
    print("ZEDQA car " .. tostring(tag) .. " spawn failed " .. tostring(script) .. ": " .. why)
    return nil, why
end

function ZEDQA_CAR_READY(v)
    if not v then return false end
    local pl = getPlayer()
    local sq, chunk, phys = nil, nil, false
    pcall(function() sq = v:getSquare() end)
    local okC = pcall(function() chunk = v:getChunk() end)
    if not okC and sq then pcall(function() chunk = sq:getChunk() end) end
    pcall(function() phys = v:isPhysicsActive() end)
    if phys == true then carSeen[v] = true end
    return sq ~= nil and chunk ~= nil and carSeen[v] == true and pl ~= nil and carDist(v, pl) <= CAR_NEAR
end

function ZEDQA_CAR_PREP(v)
    local key
    pcall(function() v:repair() end)
    pcall(function() local g = v:getPartById("GasTank"); g:setContainerContentAmount(g:getContainerCapacity()) end)
    pcall(function()
        local b = v:getPartById("Battery"); local it = b and b:getInventoryItem()
        if it then pcall(function() it:setCurrentUsesFloat(1.0) end); pcall(function() it:setUsedDelta(1.0) end) end
    end)
    pcall(function() key = getPlayer():getInventory():AddItem(v:createVehicleKey()) end)
    return key
end

function ZEDQA_CAR_ENTER(v, seat)
    local pl = getPlayer()
    if not (v and pl) then return false, "no car" end
    if carDist(v, pl) > CAR_NEAR then return false, "the car is more than " .. CAR_NEAR .. " tiles away (never enter a far car)" end
    if not ZEDQA_CAR_READY(v) then return false, "the car is not ready (no square, no chunk or its physics never woke)" end
    v:enter(seat or 0, pl); triggerEvent("OnEnterVehicle", pl)
    if pl:getVehicle() ~= v then return false, "the character is not in the car after enter" end
    return true
end

local carSweepOn = false
local function carSweep()
    local pl = getPlayer()
    local left = {}
    for _, g in ipairs(carGone) do
        g.ticks = g.ticks + 1
        if g.ticks >= 2 and not (pl and pl:getVehicle() == g.v) then
            pcall(function() g.v:permanentlyRemove() end)
            carSeen[g.v] = nil
        else
            left[#left + 1] = g
        end
    end
    carGone = left
    if #carGone == 0 then Events.OnTick.Remove(carSweep); carSweepOn = false end
end
function ZEDQA_CAR_AWAY(v, key)
    local pl = getPlayer()
    if pl and v and pl:getVehicle() == v then pcall(function() v:exit(pl); triggerEvent("OnExitVehicle", pl) end) end
    if key and pl then pcall(function() pl:getInventory():Remove(key) end) end
    if not v then return end
    carGone[#carGone + 1] = { v = v, ticks = 0 }
    if not carSweepOn then carSweepOn = true; Events.OnTick.Add(carSweep) end
end

function ZEDQA_CAR_WAIT(script, tag, onReady, onFail, capMs)
    capMs = capMs or 4000
    local tries, v, t0, why = 0, nil, 0, nil
    local started, nextTry = getTimestampMs(), 0
    local function poll()
        if not v then
            if getTimestampMs() < nextTry then return end
            -- (no clear spot yet: the strip may still be loading after a move; asked again for up to 10 s)
            if tries >= #CAR_SPOTS or (why and getTimestampMs() - started > 10000 and tries == 0) then
                Events.OnTick.Remove(poll)
                if onFail then pcall(onFail, why or "no ready car on any spot") end
                return
            end
            local nv, w = ZEDQA_CAR_SPAWN(script, tag)
            if nv then v, tries, t0 = nv, tries + 1, getTimestampMs()
            else
                why = w
                if tries > 0 then tries = #CAR_SPOTS else nextTry = getTimestampMs() + 500 end
            end
            return
        end
        if ZEDQA_CAR_READY(v) then
            Events.OnTick.Remove(poll)
            local okR, e = pcall(onReady, v)
            if not okR then print("ZEDQA car " .. tostring(tag) .. " ERR in onReady: " .. tostring(e)) end
            return
        end
        if getTimestampMs() - t0 > capMs then
            why = "car not ready in " .. capMs .. " ms"
            print("ZEDQA car " .. tostring(tag) .. " " .. why .. "; taken away, next spot")
            ZEDQA_CAR_AWAY(v); v = nil
        end
    end
    Events.OnTick.Add(poll)
end

local ok, e = pcall(function()
    if getGameSpeed and getGameSpeed() == 0 then ZEDQA_SPEED(1) end
    if p then p:setGodMod(true) end
    if p and p:getVehicle() then p:getVehicle():exit(p) end
    if p and (math.abs(p:getX() - HOME.x) > 3 or math.abs(p:getY() - HOME.y) > 3 or math.floor(p:getZ()) ~= HOME.z) then
        say(string.format("moved from %d,%d,%d to the drag strip", math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())))
        p:setX(HOME.x); p:setY(HOME.y); p:setZ(HOME.z); p:setLastX(HOME.x); p:setLastY(HOME.y); p:setLastZ(HOME.z)
        moved = true
    end
    local gt = getGameTime()
    local hour = gt:getTimeOfDay()
    if hour < 8 or hour > 17 then gt:setTimeOfDay(11.0); say(string.format("clock %.2f -> 11.00 (daylight)", hour)) end
    -- (Nov 12 2026) ZeD's Lua console follows the game's console flag, and a saved position left it open at the bottom
    -- left of every capture: close it. The console scripts (zedqa_console_*.lua, zedqa_b8_console.lua) set the flag themselves.
    local okC = pcall(function()
        local jc = UIManager.getDebugConsole()
        if jc and jc:isVisible() then jc:setVisible(false); say("the Lua console was open: closed") end
    end)
    if not okC then say("no debug console to close") end
    -- (and a speed left above 1 by an earlier script)
    if getGameSpeed and getGameSpeed() > 1 then ZEDQA_SPEED(1); say("speed was above 1: set to 1") end
    local cw = ZeD_CharacterWindow.getWindow()
    if not (cw and cw:isVisible()) then ZeD_CharacterWindow.toggleBothPaired(0) end
end)
if not ok then say("ERR setup " .. tostring(e)) end
-- counted on OnRenderTick (it runs even while paused); OnTick is counted
-- beside it to tell a paused game from a running one
local frames, ticks = 0, 0
local function onTick() ticks = ticks + 1 end
local function onFrame()
    frames = frames + 1
    if frames < (moved and 300 or 60) then return end   -- (after the move: the strip's cells load)
    if ticks < 60 and frames < 600 then return end
    Events.OnRenderTick.Remove(onFrame)
    Events.OnTick.Remove(onTick)
    local cw, ww = ZeD_CharacterWindow.getWindow(), ZeD_WorldWindow.getWindow()
    say("char " .. tostring(cw and cw:isVisible()) .. " world " .. tostring(ww and ww:isVisible())
        .. " speed " .. tostring(getGameSpeed and getGameSpeed()) .. " ticks " .. ticks .. " frames " .. frames)
    if ticks == 0 then say("ERR OnTick never ran: the game is paused") end
    -- (Oct 25 2026) search mode off: its overlay blurs everything outside a ring round the
    -- character, and the gallery's reshoot came out soft with it on
    local sm = p and ISSearchManager and ISSearchManager.getManager and ISSearchManager.getManager(p)
    if sm and sm.isSearchMode then pcall(function() sm:toggleSearchMode(false) end); say("search mode was on: turned off") end
    local okE, eng = pcall(getSearchMode)
    if okE and eng and p then
        local pn = p:getPlayerNum()
        local en, ov = eng:isEnabled(pn), eng:isOverride(pn)
        say(string.format("search overlay: enabled %s, override %s, manager %s", tostring(en), tostring(ov), tostring(sm and sm.isSearchMode)))
        if en or ov then pcall(function() eng:setOverride(pn, false); eng:setEnabled(pn, false) end); say("search overlay turned off") end
    end
    -- (Nov 12 2026, the window rule) the pair is open by now: every window to its default layout, pinned, on Loot,
    -- the console closed (zedqa_pin_windows.lua and zedqa_loot_tabs.lua are this step now). The layout this leaves
    -- is kept as ZEDQA_LAYOUT_DEF for ZEDQA_LAYOUT_IS_DEFAULT.
    if not ZEDQA_LAYOUT_DEFAULT("pre") then say("ERR the windows could not be put at their default layout") end
    ZEDQA_LAYOUT_DEF = ZEDQA_LAYOUT_SNAP()
    for _, k in ipairs(QA_KEYS) do
        local s = ZEDQA_LAYOUT_DEF[k]
        if s then say(string.format("layout %s %d,%d %dx%d rolled %s pinned %s/%s", k, s.x, s.y, s.w, s.h, tostring(s.rolled), tostring(s.pinInv), tostring(s.pinDrawer)))
        else say("ERR layout: no " .. k .. " window to place") end
    end
    -- which copy of ZeD the game loaded (zedqa_staged_ver.lua's line): no ZeD_UI mod info is an ERR
    local okV, mi = pcall(function() return getModInfoByID("ZeD_UI") end)
    if okV and mi then say("ZeD version=" .. tostring(mi:getModVersion()) .. " dir=" .. tostring(mi:getDir()))
    else say("ERR no mod info for ZeD_UI: which copy is loaded is not known") end
    cw, ww = ZeD_CharacterWindow.getWindow(), ZeD_WorldWindow.getWindow()
    say("tabs: Character " .. tostring(cw and cw._activeTab) .. " | World " .. tostring(ww and ww._activeTab))
    say("DONE")
end
Events.OnTick.Add(onTick)
Events.OnRenderTick.Add(onFrame)
say("start")
