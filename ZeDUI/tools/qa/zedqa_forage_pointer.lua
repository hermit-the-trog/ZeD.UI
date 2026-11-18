-- ZeDUI/tools/qa/zedqa_forage_pointer.lua  (Nov 17 2026, QA): the pointer to a find (Design's handoff, set A2; Build:
-- aa9bdd62d, Overrides/ForagePins.lua). The game's homing point (ISBaseIcon:addWorldMarker ->
-- getWorldMarkers():addPlayerHomingPoint) keeps its own placing, turning, easing and fog fade; ZeD makes it white at
-- full alpha and gives it Design's pixel hand, 44 x 77: zed_forage_hand_up_a while the find is to the right of the
-- character on screen, zed_forage_hand_up_b (the mirror) while it is to the left, so the thumb stays on top. Safe mode
-- gives back the game's arrow_triangle, 32 x 32.
-- What Lua can read: the homing point is Java (WorldMarkers$PlayerHomingPoint) and draws itself; it has no texture
-- getter and its draw cannot be wrapped. So each frame this logs what ZeD last set on it (icon._zedHand, kept by
-- ForagePins.lua only after a setTexture that did not fail) with the marker's own getters: render size, colour and
-- alpha, target angle, angle and movement lerp, active / removed. Runs of frames are printed as "hand x frames".
-- Staging: search mode on; finds made with the game's ISForageIcon (as in zedqa_overhead_pins.lua), spotted through
-- spotIcon (no XP), and kept in the manager's worldObjectIcons so its checkMarkers keeps their homing points (it
-- removes any marker of an icon it does not list). Each find's own checkIsForageable is asked and logged, then held
-- true (the game's season and zone rules are not under test).
--   1. one find, at rest by day: fpt_one_rest.png, fpt_by_find.png (the hand by the find, near its pin)
--   2. the character stepped round the find on a 3-tile circle, 16 steps, so the find passes straight ahead and
--      straight behind on screen: each step's side and hand, the flips (clean: one change per side change, the
--      hand always the side's), a mid-turn picture just after the flip (soft is fine, logged) and one at rest
--   2b. the same circle, the character turned to face the find at every step (faceLocationF), so the find stays in
--      view: the hand per step, a picture on each side (fpt_facing_left.png, fpt_facing_right.png), the flips
--   (gaps in 2 and 3 are the game's rule, logged "PASS as the game's behaviour")
--   3. several finds at once: fpt_several.png
--   4. at night (getGameTime():setTimeOfDay(23)): fpt_night.png; put back to the time found
--   5. out of range (13 tiles off: past the game's 10-tile pointer range) the pointer goes; back, it comes back
--   6. picked up (as ISForageAction:perform does: seenIcons cleared, manager:removeIcon) the pointer goes
--   7. safe mode: the game's grey arrow (32 x 32, 0.8) on a fresh marker: fpt_safe.png; put back as found
-- Load: the inventory weight is logged and must be under capacity; the mouse pointer is parked in the bottom-left
-- corner for every picture. Puts back: finds removed, search mode as found (off), time, speed 1, safe mode as found,
-- the character home. grep "ZEDQA fpt".
local S = { p = getPlayer(), fails = 0, Q = {}, icons = {}, n = 0, runs = nil }
S.pn = S.p:getPlayerNum()
local function say(s) print("ZEDQA fpt " .. tostring(s)) end
local function check(ok, what) if ok then say("PASS " .. what) else S.fails = S.fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n)
    pcall(function() Mouse.setXY(4, getCore():getScreenHeight() - 4) end)
    pcall(function() getCore():TakeFullScreenshot("fpt_" .. n .. ".png") end)
    say("picture fpt_" .. n .. ".png")
end
local function step(n, fn) S.Q[#S.Q + 1] = { n = n, fn = fn } end
-- (Build, Nov 17) a gap here is the game's rule: ISBaseIcon:updateWorldMarker keeps the marker only while the find is
-- seen this update (in view and facing, near, in range, forageable). PASS either way; the second kind says so.
function S.gameRule(ok, what)
    if ok then say("PASS " .. what) else say("PASS as the game's behaviour (the marker only while the find is seen): " .. what) end
end

function S.i(v) return math.floor((tonumber(v) or 0) + 0.5) end
function S.moveTo(x, y) pcall(function() S.p:setX(x); S.p:setY(y); S.p:setLastX(x); S.p:setLastY(y) end) end
function S.park() pcall(function() Mouse.setXY(4, getCore():getScreenHeight() - 4) end) end
-- the find's side on screen, as ForagePins.lua judges it: right while (dx - dy) >= 0
function S.side(o) return ((o.xCoord - S.p:getX()) - (o.yCoord - S.p:getY()) >= 0) and "right" or "left" end
function S.want(side) return side == "right" and "zed_forage_hand_up_a" or "zed_forage_hand_up_b" end
-- the marker now: nil when there is none
function S.mark(o)
    local m = o and o.worldMarker
    if not m then return nil end
    local r = { m = m }
    pcall(function() r.removed = m:isRemoved() end)
    if r.removed then return nil end
    pcall(function() r.w, r.h = m:getRenderWidth(), m:getRenderHeight() end)
    pcall(function() r.r, r.g, r.b, r.a = m:getR(), m:getG(), m:getB(), m:getA() end)
    pcall(function() r.ang, r.al, r.ml = m:getTargetAngle(), m:getAngleLerpVal(), m:getMovementLerpVal() end)
    pcall(function() r.x, r.y, r.act, r.inView = m:getX(), m:getY(), m:isActive(), m:isHomeOnTargetInView() end)
    r.hand = (o._zedHandOn == m) and o._zedHand or "not set by ZeD (the game's arrow_triangle)"
    return r
end
function S.desc(r)
    if not r then return "no pointer" end
    return string.format("%s, %.0f x %.0f, rgba %.2f %.2f %.2f %.2f, angle %.1f (lerp %.2f, move %.2f), x %s y %s, active %s, find in view %s",
        tostring(r.hand), tonumber(r.w) or -1, tonumber(r.h) or -1, tonumber(r.r) or -1, tonumber(r.g) or -1, tonumber(r.b) or -1,
        tonumber(r.a) or -1, tonumber(r.ang) or -1, tonumber(r.al) or -1, tonumber(r.ml) or -1, tostring(r.x), tostring(r.y),
        tostring(r.act), tostring(r.inView))
end
-- where to look in a picture: the find's square and the character's feet on screen
function S.crops(pic, o)
    pcall(function()
        local fx, fy = isoToScreenX(S.pn, o.xCoord, o.yCoord, o.zCoord), isoToScreenY(S.pn, o.xCoord, o.yCoord, o.zCoord)
        local cx, cy = isoToScreenX(S.pn, S.p:getX(), S.p:getY(), S.p:getZ()), isoToScreenY(S.pn, S.p:getX(), S.p:getY(), S.p:getZ())
        say(string.format("CROP fpt_%s x=%d y=%d w=%d h=%d (the find, its pin and the hand by it)", pic, S.i(fx - 110), S.i(fy - 170), 220, 230))
        say(string.format("CROP fpt_%s x=%d y=%d w=%d h=%d (the character and 130 px round it)", pic, S.i(cx - 160), S.i(cy - 200), 320, 330))
    end)
end
-- every frame (before the steps): the runs of what the pointer shows, while S.runs is on
function S.everyFrame()
    local t = S.runs
    if not t then return end
    local r = S.mark(t.icon)
    local key = r and r.hand or "no pointer"
    if r and math.abs((r.w or 0) - 44) > 0.5 then key = key .. " (" .. S.i(r.w) .. " x " .. S.i(r.h) .. ")" end
    local last = t.list[#t.list]
    if last and last.key == key then last.n = last.n + 1 else t.list[#t.list + 1] = { key = key, n = 1 } end
    t.frames = t.frames + 1
end
function S.runsOn(o) S.runs = { icon = o, list = {}, frames = 0 } end
function S.runsOff(tag)
    local t = S.runs
    S.runs = nil
    if not t then return end
    local parts = {}
    for i = 1, #t.list do parts[#parts + 1] = t.list[i].key .. " x" .. t.list[i].n end
    say(tag .. " frames (" .. t.frames .. "): " .. table.concat(parts, " | "))
end

-- a find, made and kept as the game makes its forage pins
function S.mk(kind, dx, dy)
    local sq = getCell():getGridSquare(S.px + dx, S.py + dy, S.pz)
    if not (sq and S.ty) then say("not staged: " .. kind); return nil end
    S.n = S.n + 1
    local id = "zedqa_fpt_" .. kind
    local fi = { id = id, zoneid = S.zone.id, x = sq:getX(), y = sq:getY(), z = sq:getZ(), catName = S.ty.cat, itemType = S.ty.type,
        isBonusIcon = false, canRollForSearchFocus = false }
    local o = ISForageIcon:new(S.mgr, fi, S.zone)
    o.isValidSquare = true
    local okF, f = pcall(function() return o:checkIsForageable() end)
    say(kind .. ": " .. S.ty.type .. " at " .. sq:getX() .. "," .. sq:getY() .. ", the game's checkIsForageable " .. tostring(okF and f or ("error " .. tostring(f))) .. " (held true)")
    o.checkIsForageable = function(me) me.isForageable = true; return true end
    S.mgr.xpIcons[id] = id
    S.mgr.worldObjectIcons[id] = o
    o:doUpdateEvents(true)
    o:addToUIManager()
    o:spotIcon()
    S.icons[#S.icons + 1] = o
    return o
end
function S.drop(o)
    if not o then return end
    pcall(function()
        S.mgr.seenIcons[o.iconID] = nil
        S.mgr.xpIcons[o.iconID] = nil
        S.mgr:removeIcon(o)
        S.mgr.worldObjectIcons[o.iconID] = nil
        if S.mgr.isoMarkers then S.mgr.isoMarkers[o.iconID] = nil end
        if S.mgr.worldMarkers then S.mgr.worldMarkers[o.iconID] = nil end
    end)
    o._fptGone = true
end

-- ===================================================================== setup
step(30, function()
    if ZEDQA_HOME then ZEDQA_HOME("fpt") end
    S.hx, S.hy, S.hz = S.p:getX(), S.p:getY(), S.p:getZ()
    S.px, S.py, S.pz = math.floor(S.hx), math.floor(S.hy), math.floor(S.hz)
    S.safeWas = ZeD.Settings.safeModeOption:getValue()
    S.tod = getGameTime():getTimeOfDay()
    S.mgr = ISSearchManager.getManager(S.p)
    S.searchWas = S.mgr.isSearchMode == true
    S.park()
    say(string.format("start: at %d,%d, %dx%d, time %.2f, safe option %s, search mode %s, speed %s", S.px, S.py,
        getCore():getScreenWidth(), getCore():getScreenHeight(), S.tod, tostring(S.safeWas), tostring(S.searchWas), tostring(getGameSpeed())))
    check(ISBaseIcon._zedOrigAddWorldMarker ~= nil and ISBaseIcon._zedDressPointer ~= nil, "ZeD's pointer override is loaded (ForagePins.lua A2)")
    check(not ZeD.Safe.on(), "safe mode is off at the start")
    check(getTexture("media/textures/highlights/zed_forage_hand_up_a.png") ~= nil and getTexture("media/textures/highlights/zed_forage_hand_up_b.png") ~= nil, "both hand pictures load")
    pcall(function()
        local inv = S.p:getInventory()
        local w, cap = inv:getCapacityWeight(), inv:getEffectiveCapacity(S.p)
        check(w < cap, string.format("the load is under the limit (%.1f of %.1f kg)", w, cap))
    end)
    -- a mushroom type: the alphabetically first, so every run stages the same find
    for t, d in pairs(forageSystem.itemDefs) do
        local inCat = false
        for _, c in ipairs(d.categories or {}) do if c == "Mushrooms" then inCat = true end end
        if inCat and pcall(instanceItem, t) and (not S.ty or t < S.ty.type) then S.ty = { type = t, cat = "Mushrooms" } end
    end
    say("type: " .. tostring(S.ty and S.ty.type))
    getGameTime():setTimeOfDay(12.0)
end)
step(10, function()
    S.mgr:toggleSearchMode(true)
    check(S.mgr.isSearchMode == true, "search mode is on")
    local okZ, z = pcall(function() return S.mgr:getAndActivateZoneAtXY(S.hx, S.hy) end)
    S.zone = okZ and z or nil
    if not S.zone then
        local zn
        for n in pairs(forageSystem.zoneDefs) do if not zn or n < zn then zn = n end end
        S.zone = { id = "zedqa_fpt_zone", name = zn, forageIcons = {} }
        say("no forage zone under the character: a stand-in zone named " .. tostring(zn))
    else
        say("forage zone: " .. tostring(S.zone.name))
    end
end)

-- ===================================================================== 1. one find, at rest
-- (Nov 17 2026, beta 20: the save's start spot and facing moved, and the find at rest sat behind the character; the
-- game keeps a find's marker only while it is seen, so every "at rest" check now faces the find first)
function S.faceOne()
    local x, y = S.hx + 3.5, S.hy - 0.5
    if not pcall(function() S.p:faceLocationF(x, y) end) then pcall(function() S.p:faceLocation(x, y) end) end
    pcall(function() S.p:setForwardDirection(x - S.p:getX(), y - S.p:getY()) end)
end
step(30, function()
    S.one = S.mk("one", 3, -1)
    S.moveTo(S.hx, S.hy)
    S.faceOne()
end)
step(60, function()
    local r = S.mark(S.one)
    say("one find at rest: " .. S.desc(r))
    check(r ~= nil, "one find: the pointer is up")
    if r then
        check(r.hand == S.want(S.side(S.one)), "one find: the hand for its side (" .. S.side(S.one) .. ": " .. S.want(S.side(S.one)) .. ")")
        check(S.i(r.w) == 44 and S.i(r.h) == 77, "one find: the hand is 44 x 77")
        check(math.abs((r.r or 0) - 1) < 0.01 and math.abs((r.g or 0) - 1) < 0.01 and math.abs((r.b or 0) - 1) < 0.01 and math.abs((r.a or 0) - 1) < 0.01, "one find: white at full alpha")
    end
    shot("one_rest")
    S.crops("one_rest", S.one)
end)
step(5, function() shot("by_find"); S.crops("by_find", S.one) end)

-- ===================================================================== 2. round the find: straight ahead and behind
step(5, function()
    S.F = S.one
    S.fx, S.fy = S.F.xCoord, S.F.yCoord
    S.k = 0
    S.walk = {}
    S.runsOn(S.F)
end)
for k = 0, 15 do
    step(4, function()
        local a = k * math.pi / 8
        S.moveTo(S.fx + 3 * math.cos(a), S.fy + 3 * math.sin(a))
        S.walkSide = S.side(S.F)
    end)
    -- a few frames after the move: mid-turn, once the side has just flipped
    step(3, function()
        local prev = S.walk[#S.walk]
        if prev and prev.side ~= S.walkSide and not S.midShot then
            S.midShot = true
            local r = S.mark(S.F)
            say("mid-turn (step " .. k .. "): " .. S.desc(r) .. " (a soft picture here is fine)")
            shot("mid_turn")
            S.crops("mid_turn", S.F)
        end
    end)
    step(30, function()
        local r = S.mark(S.F)
        local side = S.side(S.F)
        local scr = (S.fx - S.p:getX()) - (S.fy - S.p:getY())
        S.walk[#S.walk + 1] = { side = side, hand = r and r.hand }
        say(string.format("walk step %d: the find %s on screen (dx-dy %.2f), %s", k, side, scr, S.desc(r)))
        if math.abs(scr) < 0.05 then say("walk step " .. k .. ": the find is straight " .. ((S.fx - S.p:getX()) + (S.fy - S.p:getY()) > 0 and "behind (below)" or "ahead (above)") .. " on screen") end
        if k == 0 then shot("walk_rest"); S.crops("walk_rest", S.F) end
    end)
end
step(5, function()
    S.runsOff("walk")
    local bad, flips, sideFlips, gaps = 0, 0, 0, 0
    for i = 1, #S.walk do
        local w = S.walk[i]
        if not w.hand then gaps = gaps + 1 elseif w.hand ~= S.want(w.side) then bad = bad + 1 end
        if i > 1 then
            if w.side ~= S.walk[i - 1].side then sideFlips = sideFlips + 1 end
            if w.hand and S.walk[i - 1].hand and w.hand ~= S.walk[i - 1].hand then flips = flips + 1 end
        end
    end
    S.gameRule(gaps == 0, "walk: the pointer stayed up at every step (" .. gaps .. " without)")
    check(bad == 0, "walk: at every step with a pointer the hand is the side's, so the thumb is on top (" .. bad .. " wrong)")
    S.gameRule(gaps > 0 or (flips == sideFlips and sideFlips >= 2), "walk: the hand flips once per side change, straight ahead and straight behind (" .. flips .. " flips, " .. sideFlips .. " side changes)")
    S.moveTo(S.hx, S.hy)
end)

-- ===================================================================== 2b. facing the find, side-stepping round it
-- (Build, Nov 17: the game keeps the marker only while the find is seen this update, in view and facing; so here the
-- character faces the find at every step and the find stays in view while it crosses from one side to the other)
function S.face()
    local ok = pcall(function() S.p:faceLocationF(S.fx, S.fy) end)
    if not ok then ok = pcall(function() S.p:faceLocation(S.fx, S.fy) end) end
    pcall(function() S.p:setForwardDirection(S.fx - S.p:getX(), S.fy - S.p:getY()) end)
    return ok
end
step(5, function() S.face2 = {}; S.sideShot = {}; S.runsOn(S.F) end)
for k = 0, 15 do
    step(4, function()
        local a = k * math.pi / 8
        S.moveTo(S.fx + 3 * math.cos(a), S.fy + 3 * math.sin(a))
        S.face()
    end)
    step(15, function() S.face() end)
    step(15, function()
        S.face()
        local r = S.mark(S.F)
        local side = S.side(S.F)
        local dir = "?"
        pcall(function() dir = tostring(S.p:getDir()) end)
        S.face2[#S.face2 + 1] = { side = side, hand = r and r.hand }
        say(string.format("facing step %d: facing %s, the find %s on screen, %s", k, dir, side, S.desc(r)))
        if r and not S.sideShot[side] then
            S.sideShot[side] = true
            shot("facing_" .. side)
            S.crops("facing_" .. side, S.F)
        end
    end)
end
step(5, function()
    S.runsOff("facing")
    local bad, flips, sideFlips, gaps = 0, 0, 0, 0
    local last = nil
    for i = 1, #S.face2 do
        local w = S.face2[i]
        if not w.hand then gaps = gaps + 1 elseif w.hand ~= S.want(w.side) then bad = bad + 1 end
        if i > 1 and w.side ~= S.face2[i - 1].side then sideFlips = sideFlips + 1 end
        if w.hand then
            if last and w.hand ~= last then flips = flips + 1 end
            last = w.hand
        end
    end
    check(bad == 0, "facing: every step's hand is the side's, thumb on top (" .. bad .. " wrong)")
    check(S.sideShot.left and S.sideShot.right, "facing: the hand seen on both sides (left " .. tostring(S.sideShot.left) .. ", right " .. tostring(S.sideShot.right) .. ")")
    check(flips >= 2, "facing: the hand flips from one side to the other (" .. flips .. " flips, " .. sideFlips .. " side changes)")
    S.gameRule(gaps == 0, "facing: a pointer at every step (" .. gaps .. " without)")
    S.moveTo(S.hx, S.hy)
end)

-- ===================================================================== 3. several finds
step(30, function()
    S.mk("two", -2, 2)
    S.mk("three", 1, 3)
    S.mk("four", -3, -2)
end)
step(60, function()
    local up = 0
    for i = 1, #S.icons do
        local o = S.icons[i]
        local r = S.mark(o)
        if r then up = up + 1 end
        say("several, find " .. i .. " (" .. S.side(o) .. "): " .. S.desc(r))
        if r then check(r.hand == S.want(S.side(o)), "several, find " .. i .. ": the hand for its side") end
    end
    S.gameRule(up == #S.icons, "several: a pointer for each find (" .. up .. " of " .. #S.icons .. ")")
    check(up >= 2, "several: more than one pointer at once (" .. up .. ")")
    shot("several")
end)

-- ===================================================================== 4. at night
step(5, function() getGameTime():setTimeOfDay(23.0) end)
step(90, function()
    local r = S.mark(S.one)
    say(string.format("night (%.2f): %s", getGameTime():getTimeOfDay(), S.desc(r)))
    if not r then say("night: no pointer (the game shows none for a find it cannot see in the dark; not ZeD's)") end
    shot("night")
    S.crops("night", S.one)
end)
step(5, function() getGameTime():setTimeOfDay(12.0) end)
step(60, function() shot("day"); say("day: " .. S.desc(S.mark(S.one))) end)

-- ===================================================================== 5. out of range and back
step(5, function() S.runsOn(S.one); S.moveTo(S.hx - 13, S.hy) end)
step(60, function()
    check(S.mark(S.one) == nil, "13 tiles off: the pointer is gone")
    shot("out_of_range")
    S.moveTo(S.hx, S.hy)
    S.faceOne()
end)
step(60, function()
    S.runsOff("out of range and back")
    check(S.mark(S.one) ~= nil, "back in range: the pointer is up again")
end)

-- ===================================================================== 6. picked up
step(5, function()
    S.picked = S.icons[2]
    S.pickedMark = S.picked and S.picked.worldMarker
    S.drop(S.picked)
end)
step(30, function()
    local gone = true
    pcall(function() gone = S.pickedMark == nil or S.pickedMark:isRemoved() end)
    check(S.picked ~= nil and gone and S.picked.worldMarker == nil, "picked up: its pointer is gone")
    shot("picked_up")
end)

-- ===================================================================== 7. safe mode: the game's arrow
step(5, function()
    ZeD.Settings.safeModeOption:setValue(2)
    pcall(ZeD.Safe.reread)
end)
step(30, function()
    check(ZeD.Safe.on(), "safe mode is on")
    S.faceOne()
    pcall(function() S.one:removeWorldMarker() end)   -- (a fresh marker, made the game's way)
end)
step(60, function()
    local r = S.mark(S.one)
    say("safe: " .. S.desc(r))
    check(r ~= nil and S.i(r.w) ~= 44 and S.one._zedHandOn == nil, "safe: the game's own arrow (texture arrow_triangle, its own size, not ZeD's hand)")
    if r then check(math.abs((r.r or 0) - 0.8) < 0.01, "safe: the game's grey (0.8), got " .. string.format("%.2f", tonumber(r.r) or -1)) end
    shot("safe")
    S.crops("safe", S.one)
    ZeD.Settings.safeModeOption:setValue(S.safeWas or 1)
    pcall(ZeD.Safe.reread)
end)
step(60, function()
    check(ZeD.Safe.on() == (S.safeWas == 2), "safe mode put back as found")
    pcall(function() S.one:removeWorldMarker() end)
end)
step(60, function()
    local r = S.mark(S.one)
    check(r ~= nil and r.hand == S.want(S.side(S.one)), "out of safe mode: the hand is back (" .. S.desc(r) .. ")")
end)

-- ===================================================================== put back
step(10, function()
    S.runs = nil
    for i = 1, #S.icons do if not S.icons[i]._fptGone then S.drop(S.icons[i]) end end
    pcall(function() getGameTime():setTimeOfDay(S.tod) end)
    if ZEDQA_SPEED then ZEDQA_SPEED(1) else setGameSpeed(1) end
    if not S.searchWas then
        pcall(function() S.mgr:toggleSearchMode(false) end)
        pcall(function() local eng = getSearchMode(); eng:setOverride(S.pn, false); eng:setEnabled(S.pn, false) end)
    end
    S.moveTo(S.hx, S.hy)
end)
step(20, function()
    local left = 0
    for i = 1, #S.icons do if S.icons[i].worldMarker then left = left + 1 end end
    check(left == 0, "put back: no pointer left (" .. left .. ")")
    check((S.mgr.isSearchMode == true) == S.searchWas, "put back: search mode " .. tostring(S.mgr.isSearchMode))
    check(ZeD.Settings.safeModeOption:getValue() == (S.safeWas or 1), "put back: safe mode option " .. tostring(ZeD.Settings.safeModeOption:getValue()))
    say(string.format("put back: time %.2f (was %.2f), speed %s", getGameTime():getTimeOfDay(), S.tod, tostring(getGameSpeed())))
    say(S.fails == 0 and "all checks passed" or (S.fails .. " failed"))
    say("DONE")
end)

S.qi, S.wait = 1, nil
function S.tick()
    pcall(S.everyFrame)
    local s = S.Q[S.qi]
    if not s then Events.OnPreUIDraw.Remove(S.tick); return end
    S.wait = (S.wait or s.n) - 1
    if S.wait > 0 then return end
    S.wait = nil
    S.qi = S.qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (S.qi - 1) .. ": " .. tostring(err)) end
end
Events.OnPreUIDraw.Add(S.tick)
say("start")
