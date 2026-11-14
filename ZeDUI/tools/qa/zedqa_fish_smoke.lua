-- ZeDUI/tools/qa/zedqa_fish_smoke.lua  (Nov 11 2026, QA; "I don't even know if people can fish right now")
local setGameSpeed = ZEDQA_SPEED or setGameSpeed   -- (Nov 13 2026: the prelude's speed sets the time multiplier too; see zedqa_prelude.lua)
-- A fishing smoke test, run as a player plays it, with ZeD on (zedqa_run.ps1 -Mode fullscreen4k -Manifest
-- zedqa_fish_smoke.txt) and with ZeD off (zedqa_mods_run.ps1 -ModList zedqa_fish_smoke_mods.txt -NoZeD -Mode
-- fullscreen4k -Manifest zedqa_fish_smoke.txt). Needs the real mouse (release_check_mouse.ps1) running beside the
-- game: the cast is a real left click on the water and the reel a real left button held. Without it the script
-- says so and stands in for the button (FALLBACK lines). grep "ZEDQA fsm". Pictures zqa_fsm_<on|off>_<n>.png.
--   1 gear     a fishing rod (its hook and line are the game's own, set when the rod is made) and worms; the rod
--              equipped through the game's equip action (ISInventoryPaneContextMenu.equipWeapon, as Equip Primary);
--              the bait put on through the rod's own context menu (Add Bait > Worm: the option's onSelect, which is
--              ISInventoryPaneContextMenu.addLure and its AIAttachLureAction); the rod has bait after
--   2 cast     to the shore found near 13903,4549 (the one with the most fish in front), facing the water; the aim
--              held (the right button's job: setIsAiming), the pointer moved onto the water, a real left click.
--              Every state change of the game's FishingManager is logged with the real and the game time
--   3 catch    the game sped up while the line waits (it drops back to normal itself on a bite); on a bite the
--              left button is held to reel while the line's tension is low and let go when it is high, until the
--              fish is landed (PickupFish) or the limit. A fish in the inventory and Fishing XP up
--   4 ZeD      (ZeD on only) the rod meter (ZeD.FishRod.draw) draws while the line is out; any ZeD log of a draw
--              error; the UI under the cast point
-- Everything spawned or caught is removed, the hands, place, speed, Fishing XP and the fishing mod data put back.
local TAG = "fsm"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local R = { pass = 0, fail = 0 }
local function check(ok, s) if ok then R.pass = R.pass + 1 else R.fail = R.fail + 1 end; say((ok and "PASS " or "FAIL ") .. s); return ok end
local p = getPlayer()
local pn = p:getPlayerNum()
local core = getCore()
local gt = getGameTime()
local sw, sh = core:getScreenWidth(), core:getScreenHeight()
local ZED = (ZeD ~= nil and ZeD.FishRod ~= nil and Fishing ~= nil and Fishing.ISTensionUI ~= nil and Fishing.ISTensionUI._zedOrigRender ~= nil)
local MODE = ZED and "on" or "off"
local T0 = getTimestampMs()
local function el() return string.format("%.1fs", (getTimestampMs() - T0) / 1000) end
local function clock() return string.format("%02d:%02d", gt:getHour(), gt:getMinutes()) end
local function shot(n)
    local nm = "zqa_fsm_" .. MODE .. "_" .. n .. ".png"
    pcall(function() core:TakeFullScreenshot(nm) end)
    say("shot " .. nm)
end
local okV, ver = pcall(function() return getCore():getVersion() end)
say("start; ZeD " .. MODE .. "; screen " .. sw .. "x" .. sh .. "; game " .. tostring(okV and ver or "?"))

-- ------------------------------------------------------------------ state to put back
local O = { ids = {}, md = {}, consoles = {} }
O.x, O.y, O.z = p:getX(), p:getY(), p:getZ()
O.h1, O.h2 = p:getPrimaryHandItem(), p:getSecondaryHandItem()
O.speed = getGameSpeed()
O.god = p:isGodMod()
O.xp = p:getXp():getXP(Perks.Fishing)
O.lvl = p:getPerkLevel(Perks.Fishing)
do
    local items = p:getInventory():getItems()
    for k = 0, items:size() - 1 do O.ids[items:get(k):getID()] = true end
    for key, v in pairs(p:getModData()) do
        local ks = tostring(key)
        if ks:find("fishing", 1, true) == 1 or ks:find("Fishing", 1, true) == 1 then
            if type(v) == "table" then local c = {}; for a, b in pairs(v) do c[a] = b end; O.md[ks] = c else O.md[ks] = v end
        end
    end
end
local S = { added = {}, undo = {} }
local function spawn(full)
    local it = p:getInventory():AddItem(full)
    if it then S.added[#S.added + 1] = it end
    return it
end
local function hookFn(tbl, name, wrap)
    local orig = tbl and tbl[name]
    if orig == nil then return false end
    tbl[name] = wrap(orig)
    S.undo[#S.undo + 1] = function() tbl[name] = orig end
    return true
end
local function newItems()
    local out = {}
    local items = p:getInventory():getItems()
    for k = 0, items:size() - 1 do
        local it = items:get(k)
        if not O.ids[it:getID()] then out[#out + 1] = it end
    end
    return out
end
local function queueEmpty()
    local q = ISTimedActionQueue.getTimedActionQueue(p)
    return not (q and q.queue and #q.queue > 0)
end

-- ------------------------------------------------------------------ the real mouse (release_check_mouse.ps1)
local MOUSE = { pending = false, sentAt = 0, cmd = "", dead = false, answered = 0, x = 0, y = 0, holding = false, lastRead = 0 }
local function mouseSend(cmd, x, y)
    x, y = math.floor(math.max(2, math.min(sw - 2, x))), math.floor(math.max(2, math.min(sh - 2, y)))
    pcall(function() local fw = getFileWriter("zedqa_click_done.txt", true, false); fw:write(""); fw:close() end)
    pcall(function() local f = getFileWriter("zedqa_click.txt", true, false); f:write(cmd .. " " .. x .. " " .. y); f:close() end)
    MOUSE.pending, MOUSE.sentAt, MOUSE.cmd, MOUSE.x, MOUSE.y = true, getTimestampMs(), cmd, x, y
end
-- true once the helper has answered the last request (or gave up on it)
local function mouseIdle()
    if not MOUSE.pending then return true end
    local now = getTimestampMs()
    if now - MOUSE.lastRead < 150 then return false end
    MOUSE.lastRead = now
    local l = nil
    pcall(function() local r = getFileReader("zedqa_click_done.txt", false); if r then l = r:readLine(); r:close() end end)
    if l and l:find("done", 1, true) then MOUSE.pending = false; MOUSE.answered = MOUSE.answered + 1; return true end
    if now - MOUSE.sentAt > 9000 then
        MOUSE.pending = false; MOUSE.dead = true
        say("ERR the mouse helper never answered '" .. MOUSE.cmd .. "': the button is stood in for from here (FALLBACK)")
        return true
    end
    return false
end

-- ------------------------------------------------------------------ the fishing manager
local F = { phase = "setup", rod = nil, worms = {}, last = nil, shore = nil, tx = 0, ty = 0 }
local function mgr() return Fishing and Fishing.ManagerInstances and Fishing.ManagerInstances[pn] or nil end
local function stateName(m)
    m = m or mgr()
    if not m then return "nomanager" end
    for k, v in pairs(m.states or {}) do if v == m.state then return k end end
    return "?"
end
local function lineInfo(m)
    local s = ""
    pcall(function()
        local r = m and m.fishingRod
        if not r then s = "rod object nil"; return end
        s = "bobber " .. tostring(r.bobber ~= nil) .. " spawnDelay " .. string.format("%.1f", tonumber(r.spawnBobberDelayTimer) or -1)
        if r.bobber then
            s = s .. " fish " .. tostring(r.bobber.fish ~= nil) .. string.format(" tension %.2f", r:getTension())
            if r.bobber.fish then s = s .. " size " .. tostring(r.bobber.fish.fishSizeLen) .. " trash " .. tostring(r.bobber.fish.isTrash) end
        end
    end)
    return s
end
local function speedInfo()
    local fps = "?"
    pcall(function() fps = string.format("%.0f", getAverageFPS()) end)
    return string.format("speed %s mult %.3f fps %s", tostring(getGameSpeed()), gt:getMultiplier(), fps)
end
local function hasLure() return F.rod ~= nil and F.rod:getModData().fishing_Lure ~= nil end

-- ------------------------------------------------------------------ the shore
local function isWater(sq)
    if not sq then return false end
    local ok, r = pcall(function() return sq:getProperties() and sq:getProperties():has(IsoFlagType.water) end)
    return (ok and r) and true or false
end
local DIRS = { { "S", 0, 1 }, { "E", 1, 0 }, { "W", -1, 0 }, { "N", 0, -1 } }
local function findShores(cx, cy, r)
    local cell, out = getCell(), {}
    for dx = -r, r, 2 do for dy = -r, r, 2 do
        local x, y = cx + dx, cy + dy
        local sq = cell:getGridSquare(x, y, 0)
        if sq and sq:getFloor() and not isWater(sq) and not sq:getBuilding() and not sq:getTree() then
            for _, d in ipairs(DIRS) do
                local run = 0
                for k = 1, 7 do
                    if isWater(cell:getGridSquare(x + d[2] * k, y + d[3] * k, 0)) then run = run + 1 else break end
                end
                if run >= 6 then
                    local tx, ty = x + d[2] * 5 + 0.5, y + d[3] * 5 + 0.5
                    local fish, nofish = -1, false
                    pcall(function() fish = FishSchoolManager.getInstance():getFishAbundance(tx, ty) end)
                    pcall(function() nofish = Fishing.isNoFishZone(tx, ty) end)
                    if not nofish then out[#out + 1] = { x = x, y = y, dir = d[1], dx = d[2], dy = d[3], fish = fish, tx = tx, ty = ty } end
                end
            end
        end
    end end
    return out
end

-- ------------------------------------------------------------------ the UI under a point
local function uiUnder(mx, my)
    local names = {}
    pcall(function()
        local u = UIManager.getUI()
        for k = 0, u:size() - 1 do
            local e = u:get(k)
            if e:isVisible() then
                local x, y, w, h = e:getX(), e:getY(), e:getWidth(), e:getHeight()
                if mx >= x and mx < x + w and my >= y and my < y + h then
                    local nm = e:getClass():getSimpleName()
                    pcall(function() local t = e:getTable(); if t and t.Type then nm = tostring(t.Type) end end)
                    names[#names + 1] = nm .. "@" .. math.floor(x) .. "," .. math.floor(y) .. " " .. math.floor(w) .. "x" .. math.floor(h)
                end
            end
        end
    end)
    return names
end

-- ------------------------------------------------------------------ ZeD's rod meter (ZeD on only)
local Z = { draws = 0, drawsTrue = 0, logs = {}, lineOutDraws = 0 }
if ZED then
    hookFn(ZeD.FishRod, "draw", function(orig) return function(self, ox, oy, k, t, ...)
        local a, b = orig(self, ox, oy, k, t, ...)
        Z.draws = Z.draws + 1
        if a then Z.drawsTrue = Z.drawsTrue + 1 end
        Z.lastT, Z.lastBox = t, { ox + self:getAbsoluteX(), oy + self:getAbsoluteY(), ZeD.FishRod.W * k, ZeD.FishRod.H * k }
        return a, b
    end end)
    hookFn(ZeD, "logOnce", function(orig) return function(key, msg, ...)
        Z.logs[#Z.logs + 1] = tostring(key) .. ": " .. tostring(msg)
        say("ZeD log " .. tostring(key) .. ": " .. tostring(msg))
        return orig(key, msg, ...)
    end end)
end

-- ------------------------------------------------------------------ the plan
local plan, pi, pt0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function addWhen(max, cond, fn) plan[#plan + 1] = { ms = max, cond = cond, fn = fn } end

add(300, function()
    if getGameSpeed() == 0 then setGameSpeed(1); say("the game was paused: speed 1") end
    p:setGodMod(true)
    -- the debug console off the screen (it is not the player's; it would sit under the pointer)
    pcall(function()
        local u = UIManager.getUI()
        for k = 0, u:size() - 1 do local e = u:get(k); if e:getClass():getSimpleName() == "UIDebugConsole" and e:isVisible() then e:setVisible(false); O.consoles[#O.consoles + 1] = e end end
    end)
    local cw, ww = nil, nil
    if ZED and ZeD_CharacterWindow and ZeD_WorldWindow then   -- (ZeD off: no probe, -debug logs even a caught error)
        pcall(function() cw = ZeD_CharacterWindow.getWindow(); ww = ZeD_WorldWindow.getWindow() end)
    end
    say("windows: character " .. tostring(cw and cw:isVisible()) .. ", world " .. tostring(ww and ww:isVisible()))
    say(string.format("fishing before: level %d xp %.1f; at %d,%d; %s", O.lvl, O.xp, math.floor(O.x), math.floor(O.y), clock()))
    say("manager before: " .. tostring(mgr() ~= nil) .. " state " .. stateName())
end)

-- 1. the gear
add(300, function()
    F.rod = spawn("Base.FishingRod")
    for k = 1, 6 do F.worms[#F.worms + 1] = spawn("Base.Worm") end
    local md = F.rod and F.rod:getModData() or {}
    say("rod " .. tostring(F.rod and F.rod:getFullType()) .. " hook " .. tostring(md.fishing_HookType) .. " line " .. tostring(md.fishing_LineType)
        .. " lure " .. tostring(md.fishing_Lure) .. "; worms " .. #F.worms .. " (" .. tostring(F.worms[1] and F.worms[1]:getFullType()) .. ")")
    check(F.rod ~= nil and md.fishing_HookType ~= nil and md.fishing_LineType ~= nil, "1 the rod has a hook and a line (" .. tostring(md.fishing_HookType) .. ", " .. tostring(md.fishing_LineType) .. ")")
    -- Equip Primary, as the inventory's context menu does it
    local two = false
    pcall(function() two = F.rod:isTwoHandWeapon() end)
    ISInventoryPaneContextMenu.equipWeapon(F.rod, true, two, pn)
    say("equip queued (two hands " .. tostring(two) .. ")")
end)
addWhen(15000, function() return queueEmpty() and p:getPrimaryHandItem() == F.rod end, function()
    check(p:getPrimaryHandItem() == F.rod, "1 the rod is in the primary hand by the equip action")
    local m = mgr()
    check(m ~= nil, "1 the game made its FishingManager for the rod (OnEquipPrimary); state " .. stateName(m))
end)
-- Add Bait, through the rod's context menu
add(300, function()
    local done = false
    local ok, e = pcall(function()
        local ctx = ISInventoryPaneContextMenu.createMenu(pn, true, { F.rod }, 400, 400)
        local o1 = ctx and ctx:getOptionFromName(F.rod:getDisplayName())
        local m1 = o1 and o1.subOption and ctx:getSubMenu(o1.subOption)
        local o2 = m1 and m1:getOptionFromName(getText("ContextMenu_Add_Bait"))
        local m2 = o2 and o2.subOption and ctx:getSubMenu(o2.subOption)
        local o3 = m2 and m2:getOptionFromName(F.worms[1]:getName())
        say("menu: rod option " .. tostring(o1 ~= nil) .. ", Add Bait " .. tostring(o2 ~= nil) .. ", " .. tostring(F.worms[1]:getName()) .. " " .. tostring(o3 ~= nil)
            .. (o3 and (" (onSelect is addLure: " .. tostring(o3.onSelect == ISInventoryPaneContextMenu.addLure) .. ")") or ""))
        if o3 then
            o3.onSelect(o3.target, o3.param1, o3.param2, o3.param3, o3.param4, o3.param5, o3.param6, o3.param7, o3.param8, o3.param9, o3.param10)
            done = true
        end
        pcall(function() ctx:closeAll() end)
        pcall(function() ctx:hideAndChildren() end)
    end)
    if not ok then say("ERR the context menu: " .. tostring(e)) end
    check(done, "1 Add Bait > " .. tostring(F.worms[1]:getName()) .. " found in the rod's context menu and chosen")
    if not done then ISInventoryPaneContextMenu.addLure(pn, F.rod, F.worms[1]); say("FALLBACK addLure called directly") end
end)
addWhen(20000, function() return queueEmpty() and hasLure() end, function()
    local md = F.rod:getModData()
    check(md.fishing_Lure ~= nil, "1 the rod has bait after the action: " .. tostring(md.fishing_Lure) .. " (" .. tostring(F.rod:getName()) .. ")")
    check(p:getPrimaryHandItem() == F.rod, "1 the rod is still in the primary hand after baiting")
end)

-- 2. the shore
add(200, function() p:setX(13903.5); p:setY(4549.5); p:setZ(0); p:setLastX(13903.5); p:setLastY(4549.5); p:setLastZ(0) end)
add(4000, function()
    local list = findShores(13903, 4549, 30)
    table.sort(list, function(a, b)
        if a.fish ~= b.fish then return a.fish > b.fish end
        return math.abs(a.x - 13903) + math.abs(a.y - 4549) < math.abs(b.x - 13903) + math.abs(b.y - 4549)
    end)
    say("shores found " .. #list .. (list[1] and string.format("; best %d,%d facing %s, fish in front %s", list[1].x, list[1].y, list[1].dir, tostring(list[1].fish)) or ""))
    F.shore = list[1]
    if not check(F.shore ~= nil, "2 a shore with water in front") then return end
    p:setX(F.shore.x + 0.5); p:setY(F.shore.y + 0.5); p:setLastX(F.shore.x + 0.5); p:setLastY(F.shore.y + 0.5)
    p:setDir(IsoDirections[F.shore.dir])
    F.tx, F.ty = F.shore.tx, F.shore.ty
end)
add(2500, function()
    if not F.shore then return end
    p:setDir(IsoDirections[F.shore.dir])
    F.phase = "aim"   -- the driver below takes it from here
    F.started = getTimestampMs()
    F.gh0 = gt:getWorldAgeHours()
    say(string.format("at %.1f,%.1f facing %s, target %.1f,%.1f; %s; %s", p:getX(), p:getY(), F.shore.dir, F.tx, F.ty, clock(), speedInfo()))
end)
-- 2-4 run in the driver; the plan waits for it
addWhen(16 * 60 * 1000, function() return F.phase == "end" or F.shore == nil end, function() end)

-- ------------------------------------------------------------------ cleanup
add(300, function()
    if MOUSE.holding then mouseSend("up", MOUSE.x, MOUSE.y); MOUSE.holding = false end
    F.phase = "off"
    pcall(function() p:setIsAiming(false) end)
    local m = mgr()
    if m then pcall(function() m:changeState("None") end) end
    pcall(function() ISTimedActionQueue.clear(p) end)
    setGameSpeed(O.speed > 0 and O.speed or 1)
end)
addWhen(10000, function() return mouseIdle() end, function()
    shot("9_after")
    for k = #S.undo, 1, -1 do pcall(S.undo[k]) end
    S.undo = {}
end)
add(1500, function()
    pcall(function() p:setPrimaryHandItem(O.h1); p:setSecondaryHandItem(O.h2) end)
    local gone = 0
    for _, it in ipairs(newItems()) do
        pcall(function() p:getInventory():Remove(it) end); gone = gone + 1
    end
    for _, it in ipairs(S.added) do pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    -- what fell to the floor (a dropped catch)
    pcall(function()
        local sq = p:getCurrentSquare()
        local objs = sq and sq:getWorldObjects()
        if objs then
            for k = objs:size() - 1, 0, -1 do
                local w = objs:get(k)
                local it = w:getItem()
                if it and not O.ids[it:getID()] then sq:transmitRemoveItemFromSquare(w); gone = gone + 1 end
            end
        end
    end)
    say("cleanup: " .. gone .. " new item(s) removed")
    p:setX(O.x); p:setY(O.y); p:setZ(O.z); p:setLastX(O.x); p:setLastY(O.y); p:setLastZ(O.z)
    p:setGodMod(O.god)
    -- Fishing XP and the fishing mod data back
    pcall(function() p:getXp():setXPToLevel(Perks.Fishing, O.lvl) end)
    pcall(function() local d = O.xp - p:getXp():getXP(Perks.Fishing); if d > 0 then p:getXp():AddXP(Perks.Fishing, d, false, false, false) end end)
    local md = p:getModData()
    local drop = {}
    for key, _ in pairs(md) do
        local ks = tostring(key)
        if (ks:find("fishing", 1, true) == 1 or ks:find("Fishing", 1, true) == 1) and O.md[ks] == nil then drop[#drop + 1] = key end
    end
    for _, key in ipairs(drop) do md[key] = nil end
    for ks, v in pairs(O.md) do md[ks] = v end
    for _, e in ipairs(O.consoles) do pcall(function() e:setVisible(true) end) end
    say(string.format("cleanup: fishing level %d xp %.1f (was %d, %.1f); speed %s", p:getPerkLevel(Perks.Fishing), p:getXp():getXP(Perks.Fishing), O.lvl, O.xp, tostring(getGameSpeed())))
end)
add(800, function()
    local left = #newItems()
    for _, it in ipairs(S.added) do if it:getContainer() then left = left + 1 end end
    check(left == 0, "cleanup: everything spawned or caught is gone (" .. left .. " left)")
    check(p:getPrimaryHandItem() == O.h1, "cleanup: the hands are as before")
    say(string.format("RESULT %d pass, %d fail", R.pass, R.fail))
    say("DONE")
end)

-- ------------------------------------------------------------------ the driver (steps 2-4)
local D = { aimTry = 0, aimAt = 0, castAt = 0, castClicked = false, waitAt = 0, fishAt = 0, pickupAt = 0, beat = 0, sample = 0,
            casts = 0, bites = 0, lost = 0, landed = 0, fishLanded = false, lineOutChecked = false, fightShot = false, outShot = false,
            fallbackCast = false, fallbackReel = false, castReal = false, rebaitAt = 0, tensMax = -9, uiWarned = {} }
local LIMIT_MS = 14 * 60 * 1000
local LIMIT_GH = 6

local function finish(why)
    if F.phase == "end" then return end
    say("fishing ends: " .. why .. string.format("; casts %d, bites %d, lost %d, landed %d; %.1f game hours, %s real", D.casts, D.bites, D.lost, D.landed, gt:getWorldAgeHours() - (F.gh0 or 0), el()))
    -- 3. the outcome
    local xp = p:getXp():getXP(Perks.Fishing)
    local caught = {}
    for _, it in ipairs(newItems()) do
        local wormish = false
        for _, w in ipairs(F.worms) do if w == it then wormish = true end end
        if not wormish and it ~= F.rod then caught[#caught + 1] = it:getFullType() .. (it:getModData().fishing_FishSize and (" size " .. tostring(it:getModData().fishing_FishSize)) or "") end
    end
    check(#caught > 0, "3 a catch reached the inventory: " .. (#caught > 0 and table.concat(caught, ", ") or "none"))
    check(D.fishLanded, "3 the catch is a fish (not trash)")
    check(xp > O.xp, string.format("3 Fishing XP rose: %.1f -> %.1f", O.xp, xp))
    if ZED then
        check(D.lineOutChecked, "4 the ZeD rod meter drew while the line was out (draws " .. Z.lineOutDraws .. ", all " .. Z.drawsTrue .. "/" .. Z.draws .. ")")
        check(#Z.logs == 0, "4 no ZeD draw error logged (" .. #Z.logs .. ")")
    end
    say("cast by the real click: " .. tostring(D.castReal) .. "; stand-ins used: cast " .. tostring(D.fallbackCast) .. ", reel " .. tostring(D.fallbackReel))
    F.phase = "end"
end

-- the aim: the pointer onto the target water square; getAimCoords reads the pointer 100 px lower
local function aimStep(now, m)
    if not mouseIdle() then return end
    if D.aimTry > 0 and now - D.aimAt < 400 then return end
    local ax, ay = Fishing.Utils.getAimCoords(p)
    local onWater = Fishing.Utils.isPlayerAimOnWater(p)
    local err = math.sqrt((ax - F.tx) ^ 2 + (ay - F.ty) ^ 2)
    if D.aimTry > 0 then
        say(string.format("aim try %d: pointer %d,%d (scaled %d,%d) -> aim %.1f,%.1f, %.1f from the target, on water %s, state %s",
            D.aimTry, getMouseX(), getMouseY(), getMouseXScaled(), getMouseYScaled(), ax, ay, err, tostring(onWater), stateName(m)))
    end
    if D.aimTry > 0 and ((err < 1.6 and onWater) or D.aimTry >= 6 or MOUSE.dead) then
        F.phase = "idle"; D.idleAt = now
        return
    end
    D.aimTry = D.aimTry + 1
    D.aimAt = now
    local sx, sy = isoToScreenX(pn, F.tx, F.ty, 0), isoToScreenY(pn, F.tx, F.ty, 0)
    local mx, my
    if D.aimTry == 1 then
        mx, my = sx, sy - 100
    else
        local asx, asy = isoToScreenX(pn, ax, ay, 0), isoToScreenY(pn, ax, ay, 0)
        mx, my = MOUSE.x + (sx - asx), MOUSE.y + (sy - asy)
    end
    mouseSend("move", mx, my)
end

local function lineOut(st) return st == "Wait" or st == "ReelIn" or st == "ReelOut" end

local function driveInner()
    if F.phase == "setup" or F.phase == "end" or F.phase == "off" then return end
    local now = getTimestampMs()
    local m = mgr()
    local st = stateName(m)
    -- every state change, with the real and the game time
    if st ~= F.last then
        say(string.format("STATE %s -> %s at %s (game %s); %s; %s; player state %s", tostring(F.last), st, el(), clock(), lineInfo(m), speedInfo(),
            tostring(p:getCurrentState() and p:getCurrentState():getClass():getSimpleName())))
        if st == "Cast" then D.casts = D.casts + 1; D.castAt = now end
        if st == "Wait" and F.last == "Cast" then D.waitAt = now; D.outShot = false end
        if st == "PickupFish" then D.pickupAt = now; D.pickShot = false end
        F.last = st
    end
    -- the aim held as the right button holds it (Wait and the reel states hold it themselves)
    if (st == "None" or st == "Idle" or st == "nomanager") and F.phase ~= "rebait" and queueEmpty() then pcall(function() p:setIsAiming(true) end) end
    -- the limit
    if now - (F.started or now) > LIMIT_MS then finish("real-time limit"); return end
    if gt:getWorldAgeHours() - (F.gh0 or 0) > LIMIT_GH then finish("game-time limit"); return end
    -- a sample every second while casting, every 20 s otherwise (the stall watch sees the log move)
    if st == "Cast" and now - D.sample > 1000 then D.sample = now; say("  cast: " .. lineInfo(m) .. "; " .. speedInfo()) end
    if now - D.beat > 20000 then
        D.beat = now
        say(string.format("  beat %s game %s: phase %s state %s; %s; %s; xp %.1f", el(), clock(), F.phase, st, lineInfo(m), speedInfo(), p:getXp():getXP(Perks.Fishing)))
    end

    if F.phase == "aim" then aimStep(now, m); return end

    if F.phase == "idle" then
        -- the manager goes None -> Idle once the aim is on water
        if st == "Idle" and mouseIdle() then
            local under = uiUnder(MOUSE.x, MOUSE.y)
            say("UI under the cast point " .. MOUSE.x .. "," .. MOUSE.y .. ": " .. (#under > 0 and table.concat(under, "; ") or "nothing"))
            local zedUnder = {}
            for _, n in ipairs(under) do if n:find("ZeD", 1, true) then zedUnder[#zedUnder + 1] = n end end
            if ZED then check(#zedUnder == 0, "4 no ZeD window over the cast point" .. (#zedUnder > 0 and (": " .. table.concat(zedUnder, "; ")) or "")) end
            if D.casts == 0 then shot("1_aim") end
            if MOUSE.dead then
                D.fallbackCast = true
                say("FALLBACK the cast button stood in for (Fishing.Utils.isCastButtonPressed true once)")
                local orig = Fishing.Utils.isCastButtonPressed
                Fishing.Utils.isCastButtonPressed = function(j) Fishing.Utils.isCastButtonPressed = orig; return true end
            else
                mouseSend("left", MOUSE.x, MOUSE.y)
            end
            D.clickAt = now
            F.phase = "casting"
        elseif now - (D.idleAt or now) > 10000 then
            say("ERR the manager never reached Idle (state " .. st .. ", aim on water " .. tostring(Fishing.Utils.isPlayerAimOnWater(p)) .. ", aiming " .. tostring(p:isAiming()) .. ")")
            finish("no Idle")
        end
        return
    end

    if F.phase == "casting" then
        if st == "Cast" or lineOut(st) then
            D.castReal = not D.fallbackCast
            check(true, "2 the click cast the line (Idle -> Cast" .. (D.fallbackCast and ", stand-in" or ", real left click") .. ")")
            F.phase = "line"
        elseif mouseIdle() and now - D.clickAt > 6000 then
            if not D.fallbackCast then
                say("the real click did not cast (state " .. st .. ", aim on water " .. tostring(Fishing.Utils.isPlayerAimOnWater(p)) .. ", mouse down now " .. tostring(isMouseButtonDown(0)) .. ")")
                check(false, "2 the real left click on the water cast the line")
                MOUSE.dead = true   -- the stand-in from here
                F.phase = "idle"; D.idleAt = now
            else
                finish("no cast even with the stand-in")
            end
        end
        return
    end

    if F.phase == "rebait" then
        if queueEmpty() and hasLure() then
            say("re-baited: " .. tostring(F.rod:getModData().fishing_Lure))
            p:setDir(IsoDirections[F.shore.dir])
            D.aimTry = 0; F.phase = "aim"
        elseif now - D.rebaitAt > 20000 then finish("re-bait never finished") end
        return
    end

    -- F.phase == "line": the line is out
    local rod = m and m.fishingRod
    local fish = rod and rod.bobber and rod.bobber.fish
    if lineOut(st) and rod and rod.bobber then
        -- 4: ZeD's meter while the line is out
        local vis = m.tensionUI and m.tensionUI:isVisible()
        if ZED and vis and Z.lastT ~= nil then Z.lineOutDraws = Z.lineOutDraws + 1 end
        if not D.lineOutChecked and now - D.waitAt > 2000 then
            check(vis == true, "4 the tension meter is shown while the line is out (" .. st .. ")")
            if ZED then
                D.lineOutChecked = Z.drawsTrue > 0 and m.tensionUI.zedTension ~= nil
                say(string.format("ZeD rod meter: draws %d (drawn %d), zedTension %s, safe mode %s, box %s", Z.draws, Z.drawsTrue, tostring(m.tensionUI.zedTension),
                    tostring(ZeD.Safe and ZeD.Safe.on and ZeD.Safe.on()), Z.lastBox and (math.floor(Z.lastBox[1]) .. "," .. math.floor(Z.lastBox[2]) .. " " .. math.floor(Z.lastBox[3]) .. "x" .. math.floor(Z.lastBox[4])) or "none"))
            else
                D.lineOutChecked = true
            end
        end
        if not D.outShot and now - D.waitAt > 3000 then D.outShot = true; shot("2_line_out_" .. D.casts) end
        -- fast-forward while nothing bites (the game drops to speed 1 itself on a bite)
        if not fish and not MOUSE.holding and getGameSpeed() < 3 and st == "Wait" then setGameSpeed(3); say("  speed 3 while the line waits") end
        if fish and not D.fishOn then
            D.fishOn = true; D.bites = D.bites + 1; D.fishAt = now
            if getGameSpeed() > 1 then setGameSpeed(1) end
            say(string.format("BITE %d at %s (game %s): %s", D.bites, el(), clock(), lineInfo(m)))
        elseif not fish and D.fishOn and st ~= "PickupFish" then
            D.fishOn = false; D.lost = D.lost + 1
            say("the fish got away: " .. lineInfo(m) .. "; lure " .. tostring(F.rod:getModData().fishing_Lure))
        end
        -- the reel: the left button held while the tension is low, let go when it is high
        local t = rod:getTension()
        if fish and t > D.tensMax then D.tensMax = t end
        local want = MOUSE.holding
        if fish then
            if t < 0.3 then want = true elseif t > 0.6 then want = false end
        else
            want = false
        end
        if MOUSE.dead and fish then
            if not D.fallbackReel then
                D.fallbackReel = true
                say("FALLBACK the reel button stood in for (the rod's isReel)")
            end
            rod.isReel = function(self) return MOUSE.holding end
            rod.isReleaseLine = function(self) return false end
        end
        if want ~= MOUSE.holding then
            if MOUSE.dead then
                MOUSE.holding = want
            elseif mouseIdle() then
                mouseSend(want and "down" or "up", MOUSE.x, MOUSE.y)
                MOUSE.holding = want
            end
        end
        if fish and st == "ReelIn" and not D.fightShot and now - D.fishAt > 1500 then D.fightShot = true; shot("3_fight") end
    end
    if st == "PickupFish" then
        if MOUSE.holding and mouseIdle() then mouseSend("up", MOUSE.x, MOUSE.y); MOUSE.holding = false end
        if not D.pickShot and now - D.pickupAt > 1500 then D.pickShot = true; shot("4_landed") end
    end
    -- the line is in again: a catch, a miss or a break
    if (st == "None" or st == "Idle") and now - D.castAt > 1500 and queueEmpty() then
        if MOUSE.holding and mouseIdle() then mouseSend("up", MOUSE.x, MOUSE.y); MOUSE.holding = false end
        if not mouseIdle() then return end
        if getGameSpeed() > 1 then setGameSpeed(1) end
        D.fishOn = false
        local got = nil
        for _, it in ipairs(newItems()) do
            local isWorm = false
            for _, w in ipairs(F.worms) do if w == it then isWorm = true end end
            if not isWorm and it ~= F.rod and not D.uiWarned[it:getID()] then
                D.uiWarned[it:getID()] = true
                got = it
                local md = it:getModData()
                local isFish = md.fishing_FishSize ~= nil or md.fishing_FishHandItem ~= nil
                D.landed = D.landed + 1
                if isFish then D.fishLanded = true end
                say(string.format("LANDED %s (%s) fish %s; xp %.1f", it:getFullType(), tostring(it:getName()), tostring(isFish), p:getXp():getXP(Perks.Fishing)))
            end
        end
        if D.fishLanded then finish("a fish landed"); return end
        if p:getPrimaryHandItem() ~= F.rod then finish("the rod is no longer in hand (" .. tostring(p:getPrimaryHandItem() and p:getPrimaryHandItem():getFullType()) .. ")"); return end
        -- again: re-bait if the bait is gone, then aim and cast
        say("line in without a fish (" .. st .. "); lure " .. tostring(F.rod:getModData().fishing_Lure) .. "; again")
        D.castAt = now
        if not hasLure() then
            local worm = nil
            for _, w in ipairs(F.worms) do if w:getContainer() == p:getInventory() then worm = w end end
            if not worm then finish("out of worms"); return end
            ISInventoryPaneContextMenu.addLure(pn, F.rod, worm)
            D.rebaitAt = now; F.phase = "rebait"
        else
            D.aimTry = 0; F.phase = "aim"
        end
    end
end
local function drive()
    local ok, e = pcall(driveInner)
    if not ok then
        R.fail = R.fail + 1
        say("ERR driver: " .. tostring(e))
        pcall(function() finish("driver error") end)
        F.phase = "end"
    end
end
Events.OnTick.Add(drive)

local function run()
    local now = getTimestampMs()
    local st = plan[pi]
    if not st then Events.OnTick.Remove(run); Events.OnTick.Remove(drive); return end
    if st.cond then
        local okC, met = pcall(st.cond)
        if not (okC and met) and now - pt0 < st.ms then return end
    elseif now - pt0 < st.ms then
        return
    end
    pt0 = now; pi = pi + 1
    local ok, e = pcall(st.fn)
    if not ok then R.fail = R.fail + 1; say("ERR step " .. (pi - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(run)
