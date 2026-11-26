-- ZeDUI/tools/qa/bx_cook.lua  (Nov 21 2026, QA beast day): cook and eat, fast and in odd orders, with ZeD's windows open.
-- Run after zedqa_prelude.lua and rt_kit.lua. Tag "bx_cook"; grep "ZEDQA bx_cook". About 4 to 6 minutes.
--
-- The scene, all on the drag strip beside the character (nothing further than 3 tiles, one 12-tile step out and back):
--   a generator (power for the appliances), a 1956 knob range, a microwave, a fridge with its freezer, a rain
--   collector full of water and a campfire; food, a pot, a bowl, bread and a water bottle given to the character.
-- What is done, and after each act what ZeD shows is held against the game:
--   1 STOVE      bound in the Craft tab (Stations.open): the heat and timer knobs spun past both ends (clamps), ON
--                pressed three times, a steak left to cook and then burn on fast-forward (the item card's facts read
--                raw, cooked, burnt), the Loot pane opened on the oven mid-cook, the power cut and given back while it
--                is on, the Simple pop-out window opened and every control in it pressed once, then the stove
--                DESTROYED while bound, on and popped out (station let go, window closed, nothing left popped).
--   2 MICROWAVE  99:99 typed (clamps to an hour), paused, cleared, 1:30 typed and started, the timer left to run out
--                on fast-forward; the character stepped 12 tiles away while bound (the leash), the windows closed
--                while bound.
--   3 FRIDGE     fridge and freezer listed, the freezer shown in the Loot pane, a steak frozen on fast-forward, the
--                fridge DESTROYED while its freezer is the shown container (no stale list or pane).
--   4 ITEM CARDS a carrot gone rotten under its open card; an apple eaten a quarter, half (stopped part way), then
--                whole (the card must not stay on an eaten apple); a water bottle drunk a quarter, a half, emptied.
--   5 WATER      the game's Transfer liquid on the rain collector (ZeD's fluid card): the bottle picked as Into, half
--                poured, a full pour stopped, filled to the top (Pour goes off), Empty asked and cancelled, the bottle
--                taken from the bags and the collector DESTROYED while the card shows them.
--   6 CAMPFIRE   its fire card: Add fuel pressed and stopped at once, the fire fuelled and lit behind the card's back,
--                a steak on it on fast-forward, the campfire REMOVED while its card is open.
--   7 COOKING    the Cooking tab with a stew, a sandwich and a salad in reach: ingredients added and taken out two
--                frames apart, more than is carried, a frozen one, an ingredient gone from the bags, Make stopped at
--                once and made again, the tab left mid-make, a salad filled past its limit, saved and forgotten, the
--                base gone with the tab open.
-- Put back before DONE: every object placed or built and the campfire removed, every item not in the bags at the start
-- removed (a snapshot of item ids), the saved dishes, the devices look, both windows' tabs, the stats and nutrition,
-- the hands, game speed 1, the character home.
-- The character is never hurt: god mode and invincible are ON from the first step to the last (a stove left on with
-- burnt food and a lit campfire are beside him), the put-back heals him first and last, and a PASS or FAIL line says
-- he ends at full health with no wound, no infection and no fire on him; only then do god mode and invincible go
-- back to what was found (after a FAIL they stay on).
if not RT then
    print("ZEDQA bx_cook ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA bx_cook VERDICT FAIL 1")
    print("ZEDQA bx_cook DONE")
    return
end
if ZEDQA_HOME then ZEDQA_HOME("bx_cook") end

local Q = RT.make("bx_cook")
Q.maxMs = 400000   -- (8 minutes for the whole script: past 6 min 40 s the queue jumps to the put-back)
local S = { placed = {}, built = {}, used = {}, stackWas = {}, was = {} }
local H = {}
S.p, S.pn = RT.p, RT.pn
S.ST, S.SA, S.SP, S.CK, S.OC = ZeD.Stations, ZeD.StationAppliance, ZeD.StationPopout, ZeD.CookingTab, ZeD.ObjectCards
S.RING1 = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 1 }, { -1, -1 }, { 1, -1 }, { -1, 1 } }
S.RING2 = { { 2, 0 }, { -2, 0 }, { 0, 2 }, { 0, -2 }, { 2, 2 }, { -2, -2 }, { 2, -2 }, { -2, 2 }, { 3, 0 }, { -3, 0 } }
S.OV = { 0, 50, 100, 150, 200, 250, 300 }      -- the oven's stops (the game's ISOvenUI)
S.MW = { 50, 70, 90, 110, 130 }                -- the microwave's powers
S.STATS = { "HUNGER", "THIRST", "BOREDOM", "UNHAPPINESS", "STRESS", "FATIGUE", "ENDURANCE", "FOOD_SICKNESS", "POISON",
            "SICKNESS", "PAIN", "PANIC", "INTOXICATION" }

-- ===================================================================== helpers: the queue, speed, actions
function H.speed(n) if ZEDQA_SPEED then pcall(ZEDQA_SPEED, n) else pcall(setGameSpeed, n) end end
function H.idle()
    local busy = false
    pcall(function() busy = ISTimedActionQueue.isPlayerDoingAction(S.p) end)
    return not busy
end
function H.stop() pcall(function() S.p:StopAllActionQueue() end) end
-- queue: wait up to ms of real time for cond (an error in it counts as false), then fn(held)
function H.wait(ms, cond, fn)
    local st = {}
    local function safe() local ok, v = pcall(cond); return (ok and v) and true or false end
    Q.waitFor(2, 30000, function()
        st.t = st.t or getTimestampMs()
        return safe() or getTimestampMs() - st.t >= ms
    end, function() fn(safe()) end)
end
-- ZeD code under test: an error is a FAIL line, and the script goes on
function H.zed(what, fn)
    local ok, a, b = pcall(fn)
    if not ok then Q.check(false, what .. ": ran without an error", tostring(a)); return nil end
    return a, b
end
-- the same inside a loop: the first error is kept, H.noErr says it once
function H.zcall(fn)
    local ok, err = pcall(fn)
    if not ok and not S.zerr then S.zerr = tostring(err) end
    return ok
end
function H.noErr(label)
    local e = S.zerr
    S.zerr = nil
    return Q.check(e == nil, label .. ": ZeD's handlers ran without an error", e)
end
function H.nm(it)
    if it == nil then return "nil" end
    local n = nil
    -- (only an item has a display name: asked of a world object the game logs a Java error, even inside pcall)
    if instanceof(it, "InventoryItem") then pcall(function() n = it:getDisplayName() end)
    elseif instanceof(it, "IsoObject") then pcall(function() n = it:getObjectName() end) end
    return tostring(n or it)
end
function H.moveTo(x, y)
    local p = S.p
    p:setX(x); p:setY(y); p:setZ(S.hz); p:setLastX(x); p:setLastY(y); p:setLastZ(S.hz)
end
function H.near(list, v)
    local best, bd = 1, nil
    for i, x in ipairs(list) do
        local dd = math.abs(x - (v or 0))
        if not bd or dd < bd then best, bd = i, dd end
    end
    return best
end
function H.L(v)
    v = v or 0
    if v >= 100 then return string.format("%.0f L", v) end
    if v >= 10 then return string.format("%.1f L", v) end
    return string.format("%.2f L", v)
end

-- ===================================================================== helpers: the character
-- he is never hurt: god mode and invincible on (each call on its own, so one failing does not stop the other)
function H.safe()
    pcall(function() S.p:setGodMod(true) end)
    pcall(function() S.p:setInvincible(true) end)
end
function H.heal()
    pcall(function() if S.p:isOnFire() then S.p:StopBurning() end end)
    pcall(function() S.p:getBodyDamage():RestoreToFullHealth() end)
end
-- what is wrong with him now, in words (an empty list: nothing)
function H.hurt()
    local bad = {}
    local okH, err = pcall(function()
        local bd = S.p:getBodyDamage()
        if S.p:isDead() then bad[#bad + 1] = "dead" end
        if S.p:isOnFire() then bad[#bad + 1] = "on fire" end
        local overall = bd:getOverallBodyHealth()
        if overall < 99.9 then bad[#bad + 1] = string.format("health %.1f", overall) end
        if bd:IsInfected() or bd:IsFakeInfected() then bad[#bad + 1] = "infected" end
        local parts = bd:getBodyParts()
        for i = 0, parts:size() - 1 do
            local b = parts:get(i)
            if b:HasInjury() or b:bleeding() or b:scratched() or b:deepWounded() or b:bitten() or b:isCut() or b:getFractureTime() > 0
                or b:getBurnTime() > 0 or b:haveGlass() or b:haveBullet() or b:isInfectedWound() or b:IsInfected() or b:getHealth() < 99.9 then
                bad[#bad + 1] = tostring(b:getType())
            end
        end
    end)
    if not okH then bad[#bad + 1] = "the body could not be read: " .. tostring(err) end
    return bad
end
-- any fire left within 6 tiles of home put out, so none burns beside him after the script: food burnt in a stove
-- on grid power can start one (Food.update, IsoFireManager.StartFire). Only squares that have a fire are touched.
-- How many were put out.
function H.fireSweep()
    local n = 0
    if not (S.hx and S.hy and S.hz) then return n end
    for y = S.hy - 6, S.hy + 6 do
        for x = S.hx - 6, S.hx + 6 do
            pcall(function()
                local sq = getCell():getGridSquare(x, y, S.hz)
                if sq and sq:haveFire() then sq:stopFire(); n = n + 1 end
            end)
        end
    end
    return n
end
function H.statsSave()
    S.was.stats = {}
    local st = S.p:getStats()
    for _, n in ipairs(S.STATS) do
        local k = CharacterStat and CharacterStat[n]
        if k then pcall(function() S.was.stats[n] = st:get(k) end) end
    end
    pcall(function()
        local nu = S.p:getNutrition()
        S.was.nut = { cal = nu:getCalories(), carb = nu:getCarbohydrates(), lip = nu:getLipids(), pro = nu:getProteins(), w = nu:getWeight() }
    end)
end
function H.statsBack()
    local st = S.p:getStats()
    for n, v in pairs(S.was.stats or {}) do
        local k = CharacterStat and CharacterStat[n]
        if k and type(v) == "number" then pcall(function() st:set(k, v) end) end
    end
    local b = S.was.nut
    if b then
        pcall(function()
            local nu = S.p:getNutrition()
            nu:setCalories(b.cal); nu:setCarbohydrates(b.carb); nu:setLipids(b.lip); nu:setProteins(b.pro); nu:setWeight(b.w)
        end)
    end
end
function H.setStat(n, v)
    local k = CharacterStat and CharacterStat[n]
    if k then pcall(function() S.p:getStats():set(k, v) end) end
end
-- every item id in the bags now (the put-back removes whatever was not there at the start)
function H.invIds()
    local set, n = {}, 0
    local l = S.p:getInventory():getAllEvalRecurse(function() return true end)
    for i = 0, l:size() - 1 do set[l:get(i):getID()] = true; n = n + 1 end
    return set, n
end
function H.sweep()
    if not S.snap then return -1 end
    local gone = 0
    local l = S.p:getInventory():getAllEvalRecurse(function() return true end)
    for i = l:size() - 1, 0, -1 do
        local it = l:get(i)
        if not S.snap[it:getID()] then
            if S.p:getPrimaryHandItem() == it then S.p:setPrimaryHandItem(nil) end
            if S.p:getSecondaryHandItem() == it then S.p:setSecondaryHandItem(nil) end
            local c = it:getContainer()
            if c then c:Remove(it); gone = gone + 1 end
        end
    end
    return gone
end
function H.inBags(it)
    if not it then return false end
    local c = it:getContainer()
    return c ~= nil and S.p:getInventory():containsRecursive(it)
end
function H.takeOut(it)
    if not it then return end
    local c = it:getContainer()
    if c then c:Remove(it) end
end

-- ===================================================================== helpers: the world
function H.sq(dx, dy) return getCell():getGridSquare(S.hx + dx, S.hy + dy, S.hz) end
function H.sqKey(sq) return sq:getX() .. "," .. sq:getY() end
function H.freeSq(offsets)
    for _, o in ipairs(offsets) do
        local sq = H.sq(o[1], o[2])
        local free = false
        if sq and not S.used[H.sqKey(sq)] then
            pcall(function() free = sq:isFree(false) and not sq:HasTree() and sq:getVehicleContainer() == nil end)
        end
        if free then return sq end
    end
    return nil
end
function H.stoveAt(sq, tiles)
    if not sq then return nil end
    for _, name in ipairs(tiles) do
        local spr = getSprite(name)
        if spr then
            local o = nil
            pcall(function()
                o = IsoStove.new(getCell(), sq, spr)
                pcall(function() o:createContainersFromSpriteProperties() end)
                sq:AddSpecialObject(o)
                if o:getObjectIndex() < 0 then sq:AddTileObject(o) end
            end)
            if o then
                S.placed[#S.placed + 1] = o
                S.used[H.sqKey(sq)] = true
                return o, name
            end
        end
    end
    return nil
end
function H.tileObject(sq, sprites)
    if not sq then return nil end
    for _, name in ipairs(sprites) do
        if getSprite(name) then
            local o = IsoObject.new(sq, name, nil, false)
            sq:AddTileObject(o)
            pcall(function() o:createContainersFromSpriteProperties() end)
            if o:getContainer() then
                S.placed[#S.placed + 1] = o
                S.used[H.sqKey(sq)] = true
                return o
            end
            pcall(function() sq:transmitRemoveItemFromSquare(o) end)
        end
    end
    return nil
end
function H.removeObj(obj)
    if not obj then return end
    local sq = nil
    pcall(function() sq = obj:getSquare() end)
    if sq then
        pcall(function() sq:transmitRemoveItemFromSquare(obj) end)
        pcall(function() if obj:getObjectIndex() >= 0 then sq:RemoveTileObject(obj) end end)
    end
    pcall(function() if instanceof(obj, "IsoGenerator") then obj:remove() end end)
end
function H.inWorld(obj)
    if not obj then return false end
    local idx = -1
    pcall(function() idx = obj:getObjectIndex() end)
    return idx >= 0
end
-- an entity built with the game's build code (the build cheat), as rt_cards.lua builds its rain collector
function H.findInfo(full)
    local infos = SpriteConfigManager.GetObjectInfoList()
    for i = 0, infos:size() - 1 do
        local info = infos:get(i)
        local parent = info:getScript() and info:getScript():getParent()
        if parent and tostring(parent:getScriptObjectFullType()) == full then return info end
    end
    return nil
end
function H.objsAround(cx, cy, r)
    local set = {}
    for y = cy - r, cy + r do
        for x = cx - r, cx + r do
            local sq = getCell():getGridSquare(x, y, S.hz)
            if sq then
                local objs = sq:getObjects()
                for i = 0, objs:size() - 1 do set[objs:get(i)] = true end
            end
        end
    end
    return set
end
function H.buildAt(info, x, y)
    local before = H.objsAround(x, y, 2)
    -- (the build cheat goes back to what it was, not always off)
    local cheatWas = false
    pcall(function() cheatWas = S.p:isBuildCheat() end)
    S.p:setBuildCheat(true)
    local okB = pcall(function()
        local b = ISBuildIsoEntity:new(S.p, info, 1, ISInventoryPaneContextMenu.getContainers(S.p))
        b.buildCheat = true
        b.player = S.pn
        local sq = getCell():getGridSquare(x, y, S.hz)
        b.sq = sq
        if b:isValid(sq) then b:create(x, y, S.hz, false, nil) end
    end)
    S.p:setBuildCheat(cheatWas and true or false)
    local new = {}
    if okB then
        for obj in pairs(H.objsAround(x, y, 2)) do
            if not before[obj] then new[#new + 1] = obj; S.built[#S.built + 1] = obj end
        end
    end
    return new
end
function H.build(full, offsets)
    if not (ISBuildIsoEntity and SpriteConfigManager) then return nil, "the game's build code is not loaded" end
    local info = H.findInfo(full)
    if not info then return nil, "no entity info for " .. full end
    for _, o in ipairs(offsets) do
        local sq = H.sq(o[1], o[2])
        if sq and not S.used[H.sqKey(sq)] then
            local new = H.buildAt(info, S.hx + o[1], S.hy + o[2])
            if #new > 0 then S.used[H.sqKey(sq)] = true; return new end
        end
    end
    return nil, "no room to build " .. full
end
function H.campLua()
    if not (S.fireSq and CCampfireSystem and CCampfireSystem.instance) then return nil end
    local lo = nil
    pcall(function() lo = CCampfireSystem.instance:getLuaObjectOnSquare(S.fireSq) end)
    return lo
end
function H.campServer()
    if not (S.fireSq and SCampfireSystem and SCampfireSystem.instance) then return nil end
    local so = nil
    pcall(function() so = SCampfireSystem.instance:getLuaObjectOnSquare(S.fireSq) end)
    return so
end
function H.campIso()
    local lo = H.campLua()
    if not lo then return nil end
    local iso = nil
    pcall(function() iso = lo:getIsoObject() end)
    return iso
end

-- ===================================================================== helpers: appliances and stations
function H.powered(obj)
    if not obj then return false end
    local pw = false
    pcall(function() local c = obj:getContainer(); pw = c ~= nil and c:isPowered() end)
    return pw and true or false
end
function H.on(obj) local v = false; if obj then pcall(function() v = obj:Activated() end) end; return v and true or false end
function H.temp(obj) local v = -1; if obj then pcall(function() v = obj:getMaxTemperature() end) end; return v end
function H.timer(obj) local v = -1; if obj then pcall(function() v = obj:getTimer() end) end; return v end
function H.cur() return S.ST and S.ST.current(S.p) or nil end
function H.cst() local w = RT.ww(); return w and w._craftState end
function H.plate(pred)
    local st = H.cst()
    for _, z in ipairs((st and st.zones) or {}) do if z.type == "plate" and pred(z) then return z end end
    return nil
end
function H.craftZone(kind)
    local st = H.cst()
    for _, z in ipairs((st and st.zones) or {}) do if z.type == kind and z.w > 0 and z.h > 0 then return z end end
    return nil
end
function H.bound(obj)
    local st, w, cs = H.cur(), RT.ww(), H.cst()
    return obj ~= nil and st ~= nil and st.obj == obj and w ~= nil and w._activeTab == "craft" and cs ~= nil and #(cs.zones or {}) > 0
end
function H.clickAt(x, y) return H.zcall(function() ZeD.CraftingTab.onClick(RT.ww(), x, y) end) end
-- a knob turned n stops: through the tab's own click on the half of the knob where it is drawn, else the view's turn
function H.turnMany(id, dir, n)
    local st = H.cur()
    if not st then return end
    local _, pid = S.SA.plateFor(st)
    for _ = 1, n do
        local z = H.plate(function(x) return x.kind == "turn" and x.id == id end)
        if z then
            H.clickAt(dir > 0 and (z.x + z.w - 2) or (z.x + 1), z.y + math.floor(z.h / 2))
        else
            H.zcall(function() S.SA.turn(S.p, st, pid, id, dir) end)
        end
    end
end
-- the first of these keys the panel has, clicked; its id (nil: the panel has none of them)
function H.pressKey(ids)
    for _, id in ipairs(ids) do
        local z = H.plate(function(x) return x.id == id and x.kind ~= "turn" end)
        if z then
            H.clickAt(z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
            return id
        end
    end
    return nil
end
function H.press(id)
    local st = H.cur()
    if not st then return end
    local _, pid = S.SA.plateFor(st)
    H.zcall(function() S.SA.press(S.p, st, pid, id) end)
end
function H.plateState()
    local st = H.cur()
    if not st then return nil end
    local ok, ps = pcall(S.SA.plateState, st)
    if not ok then S.zerr = S.zerr or tostring(ps); return nil end
    return ps
end
-- what a microwave's glass must read: the time left as minutes and seconds
function H.mss(obj)
    local timer, run = H.timer(obj), 0
    pcall(function() run = obj:isRunningFor() end)
    local left = 0
    if timer > 0 then left = (run > 0) and math.max(0, timer - run) or timer end
    local s = math.ceil(left)
    local m = math.floor(s / 60)
    return string.format("%d:%02d", m, s - m * 60)
end
-- the bound station against the game: the band's words, the plate's lamps, switch and stop
function H.stateOK(label)
    local st = H.cur()
    if not st then return Q.check(false, label .. ": a station is bound", "none") end
    local obj = st.obj
    local pw, on, temp = H.powered(obj), H.on(obj), H.temp(obj)
    local words = H.zed(label .. " (Stations.stateText)", function() return (S.ST.stateText(st, S.p)) end)
    local want = (not pw) and ZeD.tr("UI_ZeD_Station_StateNoPower") or (on and getText("UI_On") or getText("UI_Off"))
    local ps = H.zed(label .. " (StationAppliance.plateState)", function() return S.SA.plateState(st) end)
    local lamps = ps ~= nil and ps.powered == pw and ps.switched == on and ps.on == (on and pw)
    local stop = false
    if ps and st.kind == "micro" then
        stop = ps.mwPower == H.near(S.MW, temp) and ps.cooking == (on and pw)
    elseif ps then
        stop = ps.ovenStop == H.near(S.OV, temp) - 1
    end
    return Q.check(words == want and lamps and stop, label .. ": the station's words, lamps and heat stop read as the game has them",
        "words " .. tostring(words) .. " (want " .. tostring(want) .. "), power " .. tostring(pw) .. ", on " .. tostring(on) .. ", heat " .. tostring(temp)
        .. "; plate powered " .. tostring(ps and ps.powered) .. ", switched " .. tostring(ps and ps.switched) .. ", lamp " .. tostring(ps and ps.on)
        .. ", stop " .. tostring(ps and (ps.ovenStop or ps.mwPower)))
end
function H.spWin() return S.SP and S.SP.get(S.pn) or nil end
function H.spUp()
    local w = H.spWin()
    local up = false
    if w then pcall(function() up = w:isReallyVisible() end) end
    return up and true or false
end

-- ===================================================================== helpers: the windows' lists and cards
function H.content() local w = RT.cw(); return w and w._mainContent end
function H.wcontent() local w = RT.ww(); return w and w._mainContent end
function H.inList(inv)
    local w = RT.ww()
    if not inv then return nil end
    for _, c in ipairs((w and w._containers) or {}) do if c.inventory == inv then return c end end
    return nil
end
function H.inPane(inv, item)
    local c = H.wcontent()
    if not (c and inv and item and c._inventory == inv) then return false end
    for _, it in ipairs(c._flatItems or {}) do if it == item then return true end end
    return false
end
function H.rowZone(item)
    local c = H.content()
    for _, z in ipairs((c and c._hitZones) or {}) do if z.id == item then return z end end
    return nil
end
function H.seekRow(item)
    local c = H.content()
    if not c then return false end
    if H.rowZone(item) then return true end
    local sc = c._scroll
    if sc and sc.setScrollPos then
        S.seekPos = (S.seekPos or -0.1) + 0.1
        if S.seekPos > 1.001 then S.seekPos = 0 end
        sc:setScrollPos(S.seekPos)
    end
    return false
end
function H.click(item)
    local c = H.content()
    local z = H.rowZone(item)
    if not (c and z) then return false end
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    H.zcall(function() c:onMouseDown(x, y); c:onMouseUp(x, y) end)
    return true
end
function H.card() local w = RT.cw(); return w and w._itemCard end
function H.cardOn(item)
    local w = RT.cw()
    local c = w and w._itemCard
    return item ~= nil and w ~= nil and w._drawerItem == item and c ~= nil and c.item == item
end
function H.factRow(panel, label)
    for _, g in ipairs((panel and panel.groups) or {}) do
        for _, r in ipairs(g.rows or {}) do if r.label == label then return r end end
    end
    return nil
end
function H.row(rows, label)
    for _, r in ipairs(rows or {}) do if r.label == label then return r end end
    return nil
end
function H.rowsText(panel)
    local out = {}
    for _, g in ipairs((panel and panel.groups) or {}) do
        for _, r in ipairs(g.rows or {}) do out[#out + 1] = tostring(r.label) .. "=" .. tostring(r.value) end
    end
    return table.concat(out, "; ")
end
-- the open card's kept model against a fresh read of the same item (nothing stale): facts and weight
function H.modelFresh(item)
    local c = H.card()
    local m = c and c._model
    if not (m and c.item == item) then return false, "the card holds no model for it" end
    local ok, now = pcall(ZeD.ItemFactsPanel.factsFor, item, S.pn)
    if not ok then return false, "factsFor: " .. tostring(now) end
    local a, b = H.rowsText(m.facts), H.rowsText(now)
    -- (Nov 21 2026, B8-1b, a9ac61c8c: the card weighs the item as the lists, the picked line and the game's tooltip do,
    -- getUnequippedWeight first: a bottle with its water, a gun with its magazine; this check followed the old bare weight)
    local wt = nil
    pcall(function() wt = item:getUnequippedWeight() end)
    if wt == nil then pcall(function() wt = item:getActualWeight() end) end
    wt = wt or 0
    local wr = H.row(m.stats, ZeD.tr("UI_ZeD_Weight"))
    local wantW = string.format("%.1f kg", wt)
    local good = a == b and wr ~= nil and wr.value == wantW
    return good, "card [" .. a .. "] weight " .. tostring(wr and wr.value) .. " | now [" .. b .. "] weight " .. wantW
end
-- queue: once the card has had a moment to follow, it must read as the game does
function H.queueFresh(key, label)
    H.wait(1500, function() return S[key] == nil or not H.cardOn(S[key]) or (H.modelFresh(S[key])) end, function()
        local it = S[key]
        if not (it and H.cardOn(it)) then return end
        local good, detail = H.modelFresh(it)
        Q.check(good, label .. ": the open item card reads as a fresh read of the item does", detail)
    end)
end
-- a food's Cooked and Fresh rows as the game has the food (ItemFactsPanel, what every item card shows)
function H.factsOK(item, label)
    if not item then return false end
    local panel = H.zed(label .. " (ItemFactsPanel.factsFor)", function() return ZeD.ItemFactsPanel.factsFor(item, S.pn) end)
    local burnt, cooked, raw, rotten, fresh = item:isBurnt(), item:isCooked(), item:isbDangerousUncooked(), item:isRotten(), item:isFresh()
    local want = burnt and getText("Tooltip_food_Burnt") or (cooked and getText("Tooltip_food_Cooked") or (raw and ZeD.tr("UI_ZeD_Card_Raw") or "-"))
    local wantF = rotten and getText("Tooltip_food_Rotten") or (fresh and getText("Tooltip_food_Fresh") or nil)
    local r = H.factRow(panel, getText("Tooltip_food_Cooked"))
    local fr = nil
    for _, g in ipairs((panel and panel.groups) or {}) do
        for _, x in ipairs(g.rows or {}) do if x.label == getText("Tooltip_food_Fresh") then fr = x end end
    end
    return Q.check(r ~= nil and r.value == want and (fr and fr.value or nil) == wantF, label .. ": the item card's facts read cooked and fresh as the game has them",
        "cooked row " .. tostring(r and r.value) .. " (want " .. tostring(want) .. "), fresh row " .. tostring(fr and fr.value) .. " (want " .. tostring(wantF) .. ")")
end
function H.queueCard(key, label)
    Q.step(3, function()
        S.seekPos = nil
        local it, c = S[key], H.content()
        if it and c then
            local ft = it:getFullType()
            c._expandedStacks = c._expandedStacks or {}
            if S.stackWas[ft] == nil then S.stackWas[ft] = c._expandedStacks[ft] or false end
            c._expandedStacks[ft] = true
        end
    end)
    Q.waitFor(2, 300, function() return S[key] ~= nil and H.seekRow(S[key]) end, function(ok)
        if not S[key] then return end
        if Q.check(ok, label .. ": its row is in the Character window's list", H.nm(S[key])) then H.click(S[key]) end
    end)
    H.wait(3000, function() return H.cardOn(S[key]) end, function(held)
        if not S[key] then return end
        Q.check(held, label .. ": a click on its row opens its item card", H.nm(H.card() and H.card().item))
        if held then RT.bounds(Q, label .. ": its item card") end
    end)
end
function H.ocard() return ZeD_WorldWindow.getObjectCard(S.pn) end
function H.entry() local c = H.ocard(); return c and c.entry end
function H.kind() local e = H.entry(); return e and e.def and e.def.id end
function H.closeCard() pcall(ZeD_WorldWindow.closeObjectCard, S.pn) end
function H.zoneFid(fid)
    local c = H.ocard()
    for _, z in ipairs((c and c._lastZones) or {}) do if z.fid == fid then return z end end
    for _, z in ipairs((c and c._zones) or {}) do if z.fid == fid then return z end end
    return nil
end
function H.runZone(fid)
    local z = H.zoneFid(fid)
    if not (z and z.run) then return false end
    H.zcall(function() z.run(H.ocard(), S.p) end)
    return true
end
function H.verb(id)
    local e = H.entry()
    for _, v in ipairs((e and e.t and e.t.verbs) or {}) do if v.id == id then return v end end
    return nil
end
function H.pressVerb(id)
    local c, v = H.ocard(), H.verb(id)
    if not (c and v) then return false end
    H.zcall(function() c:press(v) end)
    return true
end
function H.pill()
    local e = H.entry()
    if not (e and e.def and e.def.pill) then return nil end
    local ok, words = pcall(e.def.pill, e.t)
    return ok and words or nil
end
function H.fireD() local e = H.entry(); return (e and e.def and e.def.id == "fire" and e.t) and e.t.d or nil end
function H.fluidT() local e = H.entry(); return (e and e.def and e.def.id == "fluid") and e.t or nil end
-- the fluid card's rows against the game: each container's amount
function H.fluidRows()
    local t = H.fluidT()
    local d = t and t.d
    if not (d and d.rows) then return false, "no rows" end
    local bad, n = {}, 0
    for _, r in ipairs(d.rows) do
        n = n + 1
        local amt = r.fc and r.fc:getAmount() or -1
        if math.abs((r.amt or -9) - amt) > 0.006 then bad[#bad + 1] = tostring(r.name) .. " shows " .. tostring(r.amt) .. ", holds " .. tostring(amt) end
    end
    return #bad == 0 and n > 0, (#bad == 0) and (n .. " rows") or table.concat(bad, "; ")
end
function H.queueFluidRows(label)
    H.wait(1500, function() return not S.flArm or (H.fluidRows()) end, function()
        if not (S.flArm and H.fluidT()) then return end
        local good, detail = H.fluidRows()
        Q.check(good, label .. ": the fluid card's rows show what each container holds", detail)
    end)
end
function H.sideOwner(c)
    if not c then return nil end
    local o = nil
    pcall(function() o = c:getOwner() end)
    return o
end

-- ===================================================================== helpers: the Cooking tab
function H.cs() local w = RT.cw(); return w and w._cook end
function H.cookDrawn() local w, s = RT.cw(), H.cs(); return w ~= nil and w._activeTab == "cooking" and s ~= nil and #(s.zones or {}) > 0 end
function H.cookInStrip()
    for _, id in ipairs(RT.tabs(RT.charStrip())) do if id == "cooking" then return true end end
    return false
end
function H.plan() local s = H.cs(); return (s and s.plan) or {} end
function H.planFts() local o = {}; for _, e in ipairs(H.plan()) do o[#o + 1] = e.ft end; return table.concat(o, ", ") end
function H.planCount(ft) local n = 0; for _, e in ipairs(H.plan()) do if e.ft == ft then n = n + 1 end end; return n end
function H.czone(id) local s = H.cs(); return s and s.byId and s.byId[id] end
-- a press on a zone of the tab: a click at its middle; scrolled out of its pane, as the controller's A presses it
function H.cpress(id)
    local z, w = H.czone(id), RT.cw()
    if not (z and w) then return false end
    local mx, my = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    local c = z.clip
    if c and not (mx >= c.x and mx < c.x + c.w and my >= c.y and my < c.y + c.h) then
        H.zcall(z.fn)
    else
        H.zcall(function() S.CK.onClick(w, mx, my) end)
    end
    return true
end
function H.count(ft) local n = 0; pcall(function() n = S.p:getInventory():getCountTypeRecurse(ft) end); return n end
function H.curBase()
    local s = H.cs()
    local list = s and s.dish and s.bases and s.bases[s.dish]
    return list and list[s.baseIdx or 1] or nil
end
-- the tab's ingredient list against the game's own offer for the base (by kind of item)
function H.ingDiff()
    local s, b = H.cs(), H.curBase()
    if not (s and b) then return false, "no base for the dish " .. tostring(s and s.dish) end
    local game, n = {}, 0
    local ok = pcall(function()
        local l = b.recipe:getItemsCanBeUse(S.p, b.item, s.containers)
        for i = 0, l:size() - 1 do
            local it = l:get(i)
            if it ~= b.item then game[it:getFullType()] = true end
        end
    end)
    local tab = (s.ingCache and s.ingCache.item == b.item and s.ingCache.byFt) or {}
    local miss, extra = {}, {}
    for ft in pairs(game) do n = n + 1; if not tab[ft] then miss[#miss + 1] = ft end end
    for ft in pairs(tab) do if not game[ft] then extra[#extra + 1] = ft end end
    return ok and #miss == 0 and #extra == 0, n .. " kinds offered; not in the tab [" .. table.concat(miss, ", ") .. "]; only in the tab [" .. table.concat(extra, ", ") .. "]"
end
function H.queueIng(label)
    H.wait(3000, function() return not S.ckArm or (H.ingDiff()) end, function()
        if not S.ckArm then return end
        local good, detail = H.ingDiff()
        Q.check(good, label .. ": the tab lists the game's own offer for this base", detail)
    end)
end
-- the plan inside what is carried and inside the dish's limit
function H.planSane()
    local s, b = H.cs(), H.curBase()
    if not (s and b) then return false, "no base" end
    local byFt = (s.ingCache and s.ingCache.byFt) or {}
    local need, n, bad = {}, 0, {}
    for _, e in ipairs(s.plan) do
        need[e.ft] = (need[e.ft] or 0) + 1
        if not e.spice then n = n + 1 end
    end
    for ft, k in pairs(need) do
        local g = byFt[ft]
        if k > ((g and g.n) or 0) then bad[#bad + 1] = ft .. " x" .. k .. " of " .. tostring(g and g.n) end
    end
    local mx = 0
    pcall(function() mx = b.recipe:getMaxItems() end)
    return #bad == 0 and n <= mx, n .. " of " .. mx .. " ingredients; over what is carried [" .. table.concat(bad, ", ") .. "]"
end
-- the first ingredient row that can still go in, pressed (its full type, or nil)
function H.addAny(notFt)
    local s = H.cs()
    for _, g in ipairs((s and s.ingCache and s.ingCache.list) or {}) do
        local z = H.czone("cook:ing:" .. g.ft)
        if z and not z.disabled and g.ft ~= notFt then H.cpress("cook:ing:" .. g.ft); return g.ft end
    end
    return nil
end
function H.openCookTab()
    -- (the tab looks at the bags about once a second; the scan is asked for at once here, as zedqa_cook80.lua does)
    Q.step(4, function() local s = H.cs(); if s then s.scanAt, s.visAt, s.ingCache = -1, nil, nil end end)
    H.wait(8000, H.cookInStrip, function(held)
        if held and RT.cw()._activeTab ~= "cooking" then RT.charTab("cooking") end
    end)
    H.wait(6000, H.cookDrawn, function() end)
end
function H.pickDish(un)
    local label = (getTextOrNull and getTextOrNull("ContextMenu_EvolvedRecipe_" .. un)) or un
    Q.step(6, function() S.dishKey = nil; if S.ckArm then H.cpress("cook:dish") end end)
    Q.step(6, function()
        if not S.ckArm then return end
        local s = H.cs()
        for _, m in ipairs((s and s.dishGeo and s.dishGeo.modes) or {}) do
            if not S.dishKey and m.label == label and string.sub(m.id, 1, 5) == "dish:" then S.dishKey = string.sub(m.id, 6) end
        end
        if not (S.dishKey and H.cpress("cook:pop:dish:" .. S.dishKey)) then
            if s then s.popup = nil end
        end
    end)
    Q.step(6, function()
        if not S.ckArm then return end
        local s = H.cs()
        S.dishOK = S.dishKey ~= nil and s ~= nil and s.dish == S.dishKey
        if S.dishKey == nil then Q.skip("cooking: the Dish list picks " .. label, "the list has no " .. label .. " with what is carried")
        else Q.check(S.dishOK, "cooking: the Dish list picks " .. label, tostring(s and s.dish)) end
    end)
end
function H.dishes(ft)
    local out = {}
    pcall(function()
        local l = S.p:getInventory():getAllTypeRecurse(ft)
        for i = 0, l:size() - 1 do
            local ex = l:get(i):getExtraItems()
            out[#out + 1] = ex and ex:size() or 0
        end
    end)
    return out
end

-- ===================================================================== 0. setup
Q.step(30, function()
    -- (first of all: what god mode and invincible were, then both on until the last step)
    pcall(function() S.was.god = S.p:isGodMod() end)
    pcall(function() S.was.inv = S.p:isInvincible() end)
    H.safe()
    if getGameSpeed() ~= 1 then H.speed(1) end
    S.hx, S.hy, S.hz = math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())
    S.ok = S.ST ~= nil and S.SA ~= nil and S.SP ~= nil and S.CK ~= nil and S.OC ~= nil and ZeD.ItemFactsPanel ~= nil and ZeD.CraftingTab ~= nil
    Q.check(S.ok, "ZeD's station, appliance, pop-out, Cooking tab and card code is loaded")
    S.ok = S.ok and not S.p:isDead()
    S.was.pair = RT.isOpen()
    S.was.hands = { S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem() }
    if ZeD.Settings and ZeD.Settings.lookStyleOption then S.was.look = ZeD.Settings.lookStyleOption:getValue() end
    S.was.dishes = S.p:getModData().ZeD_CookDishes
    H.statsSave()
    local okS, snap, n = pcall(H.invIds)
    if okS then S.snap = snap end
    Q.say("start: home " .. S.hx .. "," .. S.hy .. "," .. S.hz .. ", " .. tostring(okS and n or "?") .. " items in the bags; god mode was "
        .. tostring(S.was.god) .. ", invincible " .. tostring(S.was.inv) .. ", both on for the script")
    H.stop()
    RT.pairOpen()
end)
Q.step(20, function()
    if not S.ok then return end
    local w = RT.cw()
    S.was.charTab = w and w._activeTab
    S.was.cookTab = H.cookInStrip()
    RT.worldTab("loot")
    local gsq = H.freeSq(S.RING2)
    if gsq then
        pcall(function()
            S.gen = IsoGenerator.new(instanceItem("Base.Generator"), getCell(), gsq)
            S.gen:setFuel(60); S.gen:setCondition(100); S.gen:setConnected(true); S.gen:setActivated(true)
        end)
        if S.gen then S.placed[#S.placed + 1] = S.gen; S.used[H.sqKey(gsq)] = true end
    end
    -- (a knob range: PhysPx oven_green, heat and timer knobs with ON and OFF keys; else the red one)
    S.stove, S.stoveTile = H.stoveAt(H.freeSq(S.RING1), { "appliances_cooking_01_0", "appliances_cooking_01_8" })
    S.micro = H.stoveAt(H.freeSq(S.RING1), { "appliances_cooking_01_24" })
    Q.check(S.gen ~= nil and S.stove ~= nil and S.micro ~= nil, "staged: a generator, a range and a microwave beside the character",
        "generator " .. tostring(S.gen ~= nil) .. ", range " .. tostring(S.stoveTile) .. ", microwave " .. tostring(S.micro ~= nil))
    pcall(function() RT.ww()._containersDirty = true end)
end)
H.wait(8000, function() return not S.ok or (H.powered(S.stove) and H.powered(S.micro)) end, function()
    if not S.ok then return end
    S.pw = H.powered(S.stove) and H.powered(S.micro)
    if not S.pw then
        Q.skip("the stove and microwave scenes", "the generator gave them no power (stove " .. tostring(H.powered(S.stove)) .. ", microwave " .. tostring(H.powered(S.micro)) .. ")")
        return
    end
    H.zed("Stations.open on the stove", function() return S.ST.open(S.p, S.stove) end)
end)

-- ===================================================================== 1. the stove
H.wait(6000, function() return not S.pw or (H.bound(S.stove) and H.plate(function() return true end) ~= nil) end, function()
    if not S.pw then return end
    S.stArm = Q.check(H.bound(S.stove) and H.plate(function() return true end) ~= nil, "stove: Stations.open binds it in the Craft tab, its controls drawn",
        "station " .. tostring(H.cur() and H.cur().kind) .. ", tab " .. tostring(RT.ww() and RT.ww()._activeTab))
    if not S.stArm then return end
    H.stateOK("stove: just opened")
    RT.bounds(Q, "the stove in the Craft tab")
end)
-- the knobs spun past both ends
Q.step(4, function()
    if not S.stArm then return end
    H.turnMany("heat", 1, 15)
    Q.check(H.temp(S.stove) == 300, "stove: the heat knob turned up 15 times stops at the top stop", H.temp(S.stove))
    H.turnMany("heat", -1, 20)
    Q.check(H.temp(S.stove) == 0, "stove: turned down 20 times it stops at off", H.temp(S.stove))
    H.turnMany("timer", 1, 25)
    Q.check(H.timer(S.stove) == 7200, "stove: the timer knob turned up 25 times stops at two hours", H.timer(S.stove))
    local ps = H.plateState()
    Q.check(ps ~= nil and ps.timerF == 1 and ps.timerOn == true, "stove: the plate's timer reads full", tostring(ps and ps.timerF))
    H.turnMany("timer", -1, 30)
    Q.check(H.timer(S.stove) == 0, "stove: turned down 30 times the timer is clear", H.timer(S.stove))
    H.noErr("stove: 90 knob turns")
    H.stateOK("stove: after the knobs")
end)
-- on, at the top heat; ON twice more
Q.step(4, function()
    if not S.stArm then return end
    H.turnMany("heat", 1, 15)
    S.onKey = H.pressKey({ "on", "onoff", "start", "bake" })
    -- (the view's toggle only with a station bound: with none, ZeD's toggle would be blamed for the script's nil)
    local st = H.cur()
    if not S.onKey and st then H.zcall(function() S.SA.toggle(S.p, st) end) end
end)
H.wait(4000, function() return not S.stArm or H.on(S.stove) end, function()
    if not S.stArm then return end
    Q.check(H.on(S.stove), "stove: its power key turns it on (the game's stove command)", tostring(S.onKey or "no key on this plate: the view's toggle"))
    H.stateOK("stove: on")
    if S.onKey == "on" then H.pressKey({ "on" }) end
end)
Q.step(3, function() if S.stArm and S.onKey == "on" then H.pressKey({ "on" }) end end)
Q.step(30, function()
    if not S.stArm then return end
    if S.onKey == "on" then Q.check(H.on(S.stove), "stove: ON pressed twice more, three frames apart, leaves it on") end
    H.noErr("stove: the power key")
end)
-- a steak in the oven; the Loot pane opened on the oven mid-cook
Q.step(4, function()
    if not (S.stArm and H.on(S.stove)) then return end
    S.stInv = S.stove:getContainer()
    if S.stInv then S.steak = S.stInv:AddItem("Base.Steak") end
    if not S.steak then Q.skip("stove: a steak cooked and burnt", "no Base.Steak could be put in the oven"); return end
    S.cookArm = true
    H.factsOK(S.steak, "steak: raw, just put in")
    RT.worldTab("loot")
    pcall(function() RT.ww()._containersDirty = true end)
    pcall(ZeD_WorldWindow.selectContainer, S.stInv, 60, S.pn)
    H.speed(3)
end)
H.wait(6000, function() return not S.cookArm or H.inPane(S.stInv, S.steak) end, function(held)
    if not S.cookArm then return end
    Q.check(held, "stove: the World window's Loot pane shows the oven with the steak in it", tostring(H.inList(S.stInv) ~= nil))
    local st = H.cur()
    Q.say("NOTE with the Craft tab left for Loot the stove is " .. ((st and st.obj == S.stove) and "still bound" or "let go"))
    H.zed("Stations.open on the stove again", function() return S.ST.open(S.p, S.stove) end)
end)
H.wait(40000, function() return not S.cookArm or S.steak:isCooked() or S.steak:isBurnt() end, function(held)
    if not S.cookArm then return end
    if held then
        -- (Nov 25 2026, ck_tab's K24: was Q.check(true, ...). The game's own state, read back: cooked by the oven's
        -- heat, its cooking time past its minutes to cook, the food hot, in the oven)
        local ct, tc, heat = S.steak:getCookingTime(), S.steak:getMinutesToCook(), S.steak:getHeat()
        Q.check((S.steak:isCooked() or S.steak:isBurnt()) and ct >= tc - 0.5 and heat > 1.6 and S.steak:getContainer() == S.stInv,
            "stove: the steak cooks on fast-forward (cooked by its time, hot, in the oven)",
            string.format("%.0f of %.0f minutes, heat %.2f, in the oven %s", ct, tc, heat, tostring(S.steak:getContainer() == S.stInv)))
    else
        Q.skip("stove: the steak cooks on fast-forward", string.format("after 40 s: %.1f of %.0f minutes, heat %.2f, oven at %.0f; set cooked by hand so the card checks run",
            S.steak:getCookingTime(), S.steak:getMinutesToCook(), S.steak:getHeat(), S.stove:getCurrentTemperature()))
        S.steak:setCooked(true)
    end
    H.factsOK(S.steak, "steak: cooked")
    H.stateOK("stove: cooking")
end)
H.wait(40000, function() return not S.cookArm or S.steak:isBurnt() end, function(held)
    if not S.cookArm then return end
    if held then
        -- (Nov 25 2026, ck_tab's K24: was Q.check(true, ...). Burnt by its time in the oven, not set by hand)
        local ct, tb = S.steak:getCookingTime(), S.steak:getMinutesToBurn()
        Q.check(S.steak:isBurnt() and ct >= tb - 0.5 and S.steak:getContainer() == S.stInv, "stove: left in, the steak burns (by its time, in the oven)",
            string.format("%.0f minutes, burns at %.0f, in the oven %s", ct, tb, tostring(S.steak:getContainer() == S.stInv)))
    else
        Q.skip("stove: left in, the steak burns", string.format("after 40 s more: %.1f of %.0f minutes; set burnt by hand", S.steak:getCookingTime(), S.steak:getMinutesToBurn()))
        S.steak:setBurnt(true)
    end
    H.speed(1)
    H.factsOK(S.steak, "steak: burnt")
    RT.bounds(Q, "the stove with a burnt steak")
end)
-- the power cut while it is on, and given back
Q.step(4, function() if S.stArm and S.gen then S.gen:setActivated(false) end end)
H.wait(6000, function() return not S.stArm or not H.powered(S.stove) end, function(held)
    if not S.stArm then return end
    if H.powered(S.stove) then
        Q.skip("stove: the power cut while it is on", "the stove still has power with the generator off (grid power here)")
    else
        H.stateOK("stove: the power cut while it is on")
        local t0, tm0 = H.temp(S.stove), H.timer(S.stove)
        H.turnMany("heat", -1, 3); H.turnMany("timer", 1, 3)
        Q.check(H.temp(S.stove) == t0 and H.timer(S.stove) == tm0, "stove: with no power its knobs change nothing", H.temp(S.stove) .. " / " .. H.timer(S.stove))
        H.noErr("stove: knobs with no power")
    end
    if S.gen then S.gen:setActivated(true) end
end)
H.wait(6000, function() return not S.stArm or H.powered(S.stove) end, function()
    if not S.stArm then return end
    Q.check(H.powered(S.stove), "stove: the generator on again gives the power back")
    H.stateOK("stove: the power back")
    -- (ZeD setup's Devices on Simple: the panel's button then opens the stove in its own window, StationPopout)
    if ZeD.Settings.lookStyleOption then ZeD.Settings.lookStyleOption:setValue(2) end
end)
-- its own window: every control pressed once; then the stove destroyed while bound and popped out
H.wait(4000, function() return not S.stArm or H.craftZone("popout") ~= nil end, function()
    if not S.stArm then return end
    local z = H.craftZone("popout")
    S.spArm = Q.check(z ~= nil, "pop-out: the stove's Simple panel has its pop-out button")
    if z then H.clickAt(z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)) end
end)
H.wait(3000, function() return not S.spArm or (H.spUp() and #H.spWin():controls() > 0) end, function()
    if not S.spArm then return end
    S.spArm = Q.check(H.spUp(), "pop-out: the button opens the stove in its own window")
    if not S.spArm then return end
    RT.bounds(Q, "the stove's own window")
    local w = H.spWin()
    local ctl = H.zed("pop-out controls", function() return w:controls() end) or {}
    for _, z in ipairs(ctl) do
        H.zcall(function() w:onMouseDown(z.x + math.floor(z.w / 2) + 1, z.y + math.floor(z.h / 2)) end)
    end
    Q.check(#ctl > 0, "pop-out: the window has the panel's controls, each pressed once", #ctl .. " controls")
    H.noErr("pop-out: every control pressed once")
end)
Q.step(30, function()
    if not S.spArm then return end
    H.stateOK("stove: after every control in its window")
    Q.say("NOTE the stove is destroyed now: bound, " .. (H.on(S.stove) and "on" or "off") .. ", its window open")
    H.takeOut(S.steak)
    H.removeObj(S.stove)
end)
H.wait(4000, function() return not S.spArm or (H.cur() == nil and not H.spUp()) end, function()
    if not S.spArm then return end
    Q.check(not H.inWorld(S.stove), "vanish: the stove is gone from the world")
    Q.check(H.cur() == nil, "vanish: a stove destroyed while bound lets the station go", tostring(H.cur() and H.cur().name))
    Q.check(not H.spUp(), "vanish: its own window closes with it")
    Q.check(S.SA.popped == nil or S.SA.popped[S.pn] == nil, "vanish: nothing is left marked as popped out")
    RT.bounds(Q, "after the stove vanished")
end)

-- ===================================================================== 2. the microwave
Q.step(10, function()
    if not (S.pw and S.micro) then return end
    Q.check(S.ST.classify(S.micro) == "micro", "microwave: the station code knows it for a microwave", tostring(S.ST.classify(S.micro)))
    H.zed("Stations.open on the microwave", function() return S.ST.open(S.p, S.micro) end)
end)
H.wait(6000, function() return not S.pw or H.bound(S.micro) end, function()
    if not (S.pw and S.micro) then return end
    S.mwArm = Q.check(H.bound(S.micro), "microwave: bound in the Craft tab, its panel drawn")
    if not S.mwArm then return end
    local _, pid = S.SA.plateFor(H.cur())
    local base = ZeD.Px and ZeD.Px.baseId and ZeD.Px.baseId(pid) or tostring(pid)
    S.mwKeys = base == "mw_white" or base == "mw_chrome"
    Q.say("microwave plate " .. tostring(pid) .. (S.mwKeys and " (a keypad)" or " (dials)"))
    H.stateOK("microwave: just opened")
    RT.bounds(Q, "the microwave in the Craft tab")
    S.mwFood = S.micro:getContainer():AddItem("Base.Steak")
    -- an hour, the most it takes: 99:99 typed on the pads, or the timer dial turned to its end
    if S.mwKeys then for _ = 1, 6 do H.press("d9") end else H.turnMany("timer", 1, 40) end
    H.press("start")
end)
H.wait(4000, function() return not S.mwArm or H.on(S.micro) end, function()
    if not S.mwArm then return end
    Q.check(H.on(S.micro), "microwave: START sets it going")
    Q.check(H.timer(S.micro) == 3600, "microwave: 99:99 typed (or the dial at its end) is an hour, no more", H.timer(S.micro))
    local ps = H.plateState()
    Q.check(ps ~= nil and ps.mwText == H.mss(S.micro), "microwave: its glass reads the time left", tostring(ps and ps.mwText) .. " (want " .. H.mss(S.micro) .. ")")
    H.stateOK("microwave: cooking")
    H.press(S.mwKeys and "stop" or "start")   -- (a keypad pauses; a dial one's key is the switch)
end)
H.wait(4000, function() return not S.mwArm or not H.on(S.micro) end, function()
    if not S.mwArm then return end
    Q.check(not H.on(S.micro), "microwave: STOP stops it")
    if S.mwKeys then Q.check(H.timer(S.micro) > 0, "microwave: paused, it keeps the time left", H.timer(S.micro)) end
    H.stateOK("microwave: stopped")
    if S.mwKeys then H.press("stop") else H.turnMany("timer", -1, 40) end
end)
Q.step(20, function()
    if not S.mwArm then return end
    Q.check(H.timer(S.micro) == 0, "microwave: STOP / CLEAR again (or the dial back) clears the timer", H.timer(S.micro))
    if S.mwKeys then
        H.press("d1"); H.press("d3"); H.press("d0")
        local ps = H.plateState()
        Q.check(ps ~= nil and ps.mwText == "1:30", "microwave: 1 3 0 typed reads 1:30 on the glass", tostring(ps and ps.mwText))
    else
        H.turnMany("timer", 1, 1)
    end
    H.press("start")
end)
H.wait(4000, function() return not S.mwArm or H.on(S.micro) end, function()
    if not S.mwArm then return end
    local want = S.mwKeys and 90 or 60
    S.mwRun = Q.check(H.on(S.micro) and H.timer(S.micro) == want, "microwave: started on a short timer", H.timer(S.micro) .. " s (want " .. want .. ")")
    H.noErr("microwave: its keys")
    if S.mwRun then H.speed(3) end
end)
H.wait(30000, function() return not S.mwRun or not H.on(S.micro) end, function(held)
    if not S.mwArm then return end
    H.speed(1)
    if not S.mwRun then return end
    if not held then
        Q.skip("microwave: the timer runs out and it stops", "still on after 30 s of fast-forward, timer " .. H.timer(S.micro))
        local st = H.cur()
        if st then H.zcall(function() S.SA.toggle(S.p, st, 0) end) end
        return
    end
    Q.check(true, "microwave: the timer runs out and the game stops it")
    H.stateOK("microwave: the timer ran out")
    local ps = H.plateState()
    Q.say("glass after the timer: " .. tostring(ps and ps.mwText) .. ", timer " .. H.timer(S.micro))
end)
-- the leash: 12 tiles away while bound; then the windows closed while bound
Q.step(10, function()
    if not S.mwArm then return end
    S.leashArm = H.cur() ~= nil
    if S.leashArm then H.moveTo(S.hx + 12.5, S.hy + 0.5) end
end)
H.wait(3000, function() return not S.leashArm or H.cur() == nil end, function()
    if not S.mwArm then return end
    if S.leashArm then Q.check(H.cur() == nil, "leash: 12 tiles from the microwave the station is let go", tostring(H.cur() and H.cur().dist)) end
    H.moveTo(S.hx + 0.5, S.hy + 0.5)
end)
Q.step(30, function()
    if not S.mwArm then return end
    Q.say("NOTE back beside the microwave the Craft tab is " .. (H.cur() and "bound again on its own" or "still on Hand"))
    H.zed("Stations.open on the microwave again", function() return S.ST.open(S.p, S.micro) end)
end)
H.wait(4000, function() return not S.mwArm or H.bound(S.micro) end, function()
    if not S.mwArm then return end
    S.shutArm = Q.check(H.bound(S.micro), "microwave: bound again after the walk")
    if S.shutArm then RT.pairShut() end
end)
H.wait(3000, function() return not S.shutArm or H.cur() == nil end, function()
    if S.shutArm then Q.check(H.cur() == nil, "both windows closed while bound: the station is let go") end
    RT.pairOpen()
end)
Q.step(30, function()
    if S.was.look ~= nil and ZeD.Settings.lookStyleOption then ZeD.Settings.lookStyleOption:setValue(S.was.look) end
    if S.micro and H.on(S.micro) then H.zcall(function() S.SA.toggle(S.p, { obj = S.micro, kind = "micro" }, 0) end) end
    H.takeOut(S.mwFood)
    pcall(S.ST.unbind, S.p)
    RT.worldTab("loot")
    RT.bounds(Q, "after the microwave")
end)

-- ===================================================================== 3. the fridge and its freezer
Q.step(10, function()
    if not S.ok then return end
    S.fridge = H.tileObject(H.freeSq(S.RING1), { "appliances_refrigeration_01_0", "appliances_refrigeration_01_4" })
    if not S.fridge then Q.skip("the fridge scenes", "no free square or no fridge tile"); return end
    S.frz = S.fridge:getContainerByType("freezer")
    S.frg = S.fridge:getContainerByType("fridge") or S.fridge:getContainer()
    if S.frg then S.milk = S.frg:AddItem("Base.Milk") end
    if S.frz then S.frzSteak = S.frz:AddItem("Base.Steak") end
    Q.check(S.frg ~= nil and S.frz ~= nil and S.frzSteak ~= nil, "fridge: placed beside the character, milk in the fridge and a steak in the freezer",
        "fridge " .. tostring(S.frg ~= nil) .. ", freezer " .. tostring(S.frz ~= nil))
    S.frArm = S.frz ~= nil and S.frzSteak ~= nil
    pcall(function() RT.ww()._containersDirty = true end)
end)
H.wait(6000, function() return not S.frArm or (H.inList(S.frz) ~= nil and H.inList(S.frg) ~= nil) end, function()
    if not S.frArm then return end
    Q.check(H.inList(S.frz) ~= nil and H.inList(S.frg) ~= nil, "fridge: the World window lists the fridge and the freezer, each its own container",
        tostring(H.inList(S.frg) and H.inList(S.frg).name) .. " / " .. tostring(H.inList(S.frz) and H.inList(S.frz).name))
    pcall(ZeD_WorldWindow.selectContainer, S.frz, 60, S.pn)
end)
H.wait(5000, function() return not S.frArm or H.inPane(S.frz, S.frzSteak) end, function(held)
    if not S.frArm then return end
    S.frShown = Q.check(held, "freezer: it opens in the Loot pane with the steak in it")
    RT.bounds(Q, "the freezer in the Loot pane")
    S.fz0 = S.frzSteak:getFreezingTime()
    Q.say("freezer powered " .. tostring(S.frz:isPowered()) .. ", steak freezing " .. string.format("%.1f", S.fz0))
    H.speed(3)
end)
-- (a full freeze is 4 game hours of freezer time (Food.updateFreezing), so the scene waits only for the freezing to
-- begin. In single player food in a container ages, freezes and thaws when it is asked to: the game's own list asks
-- every food it lists (ISInventoryPane.lua:2273, item:updateAge()). With ZeD's Loot pane showing the freezer the steak
-- must freeze as it does there; the script does not ask for it until the wait is over)
H.wait(12000, function() return not S.frArm or S.frzSteak:getFreezingTime() > (S.fz0 or 0) + 0.5 end, function(held)
    if not S.frArm then return end
    H.speed(1)
    local a = S.frzSteak:getFreezingTime()
    S.frzSteak:updateAge()
    local b = S.frzSteak:getFreezingTime()
    local label = "freezer: a steak in the powered freezer ZeD's Loot pane shows starts to freeze on fast-forward, as under the game's own list"
    if not S.frShown then
        -- (the pane never showed the freezer: that is the FAIL above, not this one)
        Q.skip(label, string.format("the Loot pane did not show the freezer; freezing %.1f, asked to age %.1f", a, b))
    elseif held then
        Q.check(true, label, string.format("freezing %.1f of 100", a))
    elseif b > a + 0.5 then
        Q.check(false, label, string.format("freezing %.1f of 100 after 12 s; asked to age as the game's list asks each food (updateAge) it reads %.1f at once", a, b))
    else
        Q.skip(label, string.format("the game itself did not start to freeze it (%.1f, asked to age %.1f; freezer powered %s)", a, b, tostring(S.frz:isPowered())))
    end
    -- (frozen through by hand for the card: the 4 hours are not waited for)
    S.frzSteak:setFreezingTime(100); S.frzSteak:setFrozen(true)
    H.factsOK(S.frzSteak, "steak: frozen")
    Q.say("NOTE the fridge is destroyed now, its freezer the container the Loot pane shows")
    H.takeOut(S.frzSteak); H.takeOut(S.milk)
    H.removeObj(S.fridge)
end)
H.wait(6000, function()
    local c = H.wcontent()
    return not S.frArm or (H.inList(S.frz) == nil and H.inList(S.frg) == nil and (c == nil or c._inventory ~= S.frz))
end, function()
    if not S.frArm then return end
    local c = H.wcontent()
    Q.check(H.inList(S.frz) == nil and H.inList(S.frg) == nil, "vanish: a destroyed fridge leaves the World window's container list within 6 s")
    Q.check(c == nil or c._inventory ~= S.frz, "vanish: the Loot pane does not go on showing the destroyed freezer", tostring(c and c._inventory and c._inventory:getType()))
    RT.bounds(Q, "after the fridge vanished")
end)

-- ===================================================================== 4. item cards: rot, eat, drink
Q.step(10, function()
    if not S.ok then return end
    RT.charTab("loot"); RT.worldTab("loot")
    S.carrot, S.apple, S.bottle = RT.give("Base.Carrots"), RT.give("Base.Apple"), RT.give("Base.WaterBottle")
    if S.bottle then
        local fc = S.bottle:getFluidContainer()
        S.bfc = fc
        if fc then fc:Empty(); fc:addFluid(Fluid.Water, fc:getCapacity()); S.bcap = fc:getCapacity() end
    end
    -- (hungry and thirsty for the scene, so eating and drinking are what a player would do; put back at the end)
    H.setStat("HUNGER", 0.5); H.setStat("THIRST", 0.5)
    local c = H.content()
    Q.check(S.carrot ~= nil and S.apple ~= nil and S.bottle ~= nil and S.bfc ~= nil and c ~= nil and c._inventory == S.p:getInventory(),
        "cards: a carrot, an apple and a full water bottle given, the Character window on its inventory list")
end)
H.queueCard("carrot", "carrot")
Q.step(4, function()
    if not H.cardOn(S.carrot) then return end
    H.factsOK(S.carrot, "carrot: fresh")
    S.carrot:setAge(S.carrot:getOffAgeMax() + 1)   -- gone off under the open card
    S.rotArm = S.carrot:isRotten()
    if not S.rotArm then Q.skip("carrot: gone rotten under its open card", "an age past its last day did not make it rotten") end
end)
H.queueFresh("carrot", "carrot: gone rotten while its card is open")
Q.step(2, function() if S.rotArm then H.factsOK(S.carrot, "carrot: rotten") end end)
-- the apple: a quarter, a half stopped part way, then all of it
H.queueCard("apple", "apple")
Q.step(4, function()
    S.eatArm = H.cardOn(S.apple)
    if not S.eatArm then return end
    S.h0 = S.apple:getHungerChange()
    H.speed(3)
    pcall(ISInventoryPaneContextMenu.onEatItems, { S.apple }, 0.25, S.pn)
end)
H.wait(15000, function() return not S.eatArm or (H.idle() and S.apple:getHungerChange() ~= S.h0) end, function(held)
    if not S.eatArm then return end
    H.speed(1)
    local h = S.apple:getHungerChange()
    if not held then
        Q.skip("eat: a quarter of the apple", "its hunger did not move in 15 s (" .. tostring(h) .. ")")
        H.stop(); S.eatArm = false
        return
    end
    Q.say("a quarter of the apple eaten: hunger " .. tostring(S.h0) .. " -> " .. tostring(h) .. " (the game's own sum)")
end)
H.queueFresh("apple", "apple: a quarter eaten")
Q.step(4, function()
    if not S.eatArm then return end
    S.h1 = S.apple:getHungerChange()
    pcall(ISInventoryPaneContextMenu.onEatItems, { S.apple }, 0.5, S.pn)
end)
Q.step(20, function() if S.eatArm then H.stop() end end)
Q.step(20, function()
    if not S.eatArm then return end
    Q.check(H.idle(), "eat: stopped part way, the character is idle")
    Q.say("the half stopped after 20 frames: hunger " .. tostring(S.h1) .. " -> " .. tostring(H.inBags(S.apple) and S.apple:getHungerChange() or "eaten"))
end)
H.queueFresh("apple", "apple: eating stopped part way")
Q.step(4, function()
    if not (S.eatArm and H.inBags(S.apple)) then return end
    H.speed(3)
    pcall(ISInventoryPaneContextMenu.onEatItems, { S.apple }, 1, S.pn)
end)
H.wait(15000, function() return not S.eatArm or (H.idle() and not H.inBags(S.apple)) end, function(held)
    if not S.eatArm then return end
    H.speed(1)
    S.appleGone = not H.inBags(S.apple)
    if not S.appleGone then Q.skip("eat: the rest of the apple", "still in the bags after 15 s"); H.stop() end
end)
H.wait(2500, function() return not S.appleGone or not H.cardOn(S.apple) end, function()
    if not S.appleGone then return end
    local w = RT.cw()
    Q.check(not H.cardOn(S.apple), "vanish: the apple eaten whole, its item card does not stay open on it", H.nm(w and w._drawerItem))
    RT.bounds(Q, "after the apple is eaten")
end)
-- the bottle: a quarter, a half, emptied on the ground
H.queueCard("bottle", "water bottle")
H.queueFresh("bottle", "water bottle: full")
function H.bottleOK(label)
    if not H.cardOn(S.bottle) then return end
    local m = H.card()._model
    local r = m and H.factRow(m.facts, ZeD.tr("UI_ZeD_Card_Amount"))
    local want = H.L(S.bfc:getAmount()) .. " / " .. H.L(S.bcap)
    if r then Q.check(r.value == want, label .. ": the card's Amount row", tostring(r.value) .. " (want " .. want .. ")")
    else Q.skip(label .. ": the card's Amount row", "the card's facts (" .. tostring(m and m.facts and m.facts._key) .. ") have no Amount row") end
    local k, f = nil, nil
    pcall(function() k, f = ZeD.ItemMeter.of(S.bottle) end)
    Q.check(k == "fluid" and type(f) == "number" and math.abs(f - S.bfc:getAmount() / S.bcap) < 0.002, label .. ": the list's bar is the water over the capacity",
        tostring(k) .. " " .. tostring(f))
end
function H.queueDrink(frac, wantLeft, label)
    Q.step(4, function()
        if not S.drinkArm then return end
        S.a0 = S.bfc:getAmount()
        H.speed(3)
        pcall(ISInventoryPaneContextMenu.onDrinkFluid, S.bottle, frac, S.p, nil, S.bottle)
    end)
    H.wait(15000, function() return not S.drinkArm or (H.idle() and S.bfc:getAmount() < S.a0 - 0.005) end, function(held)
        if not S.drinkArm then return end
        H.speed(1)
        local a = S.bfc:getAmount()
        if not held then Q.skip(label, "the bottle still holds " .. H.L(a) .. " after 15 s"); H.stop(); S.drinkArm = false; return end
        Q.say(label .. ": " .. H.L(S.a0) .. " -> " .. H.L(a) .. " (about " .. H.L(S.bcap * wantLeft) .. " by the game's sum)")
    end)
    H.queueFresh("bottle", label .. ", the card open")
    Q.step(2, function() if S.drinkArm then H.bottleOK(label) end end)
end
Q.step(2, function()
    S.drinkArm = H.cardOn(S.bottle) and S.bfc ~= nil
    if S.drinkArm then H.bottleOK("drink: a full bottle") end
end)
H.queueDrink(0.25, 0.75, "drink: a quarter drunk leaves three quarters")
H.queueDrink(0.5, 0.375, "drink: half of that drunk leaves three eighths")
Q.step(4, function()
    if not S.drinkArm then return end
    H.speed(3)
    pcall(ISFluidContainerMenu.emptyFluidContainer, S.p, S.bfc)
end)
H.wait(15000, function() return not S.drinkArm or (H.idle() and S.bfc:isEmpty()) end, function(held)
    if not S.drinkArm then return end
    H.speed(1)
    if not held then Q.skip("drink: the rest poured out", "the bottle still holds " .. H.L(S.bfc:getAmount())); H.stop(); return end
    Q.check(true, "drink: the rest poured out on the ground (the game's empty)")
end)
H.queueFresh("bottle", "water bottle: emptied")
Q.step(2, function() if S.drinkArm and S.bfc:isEmpty() then H.bottleOK("drink: an empty bottle") end end)

-- ===================================================================== 5. water: the rain collector and the fluid card
Q.step(10, function()
    if not (S.ok and S.bottle and S.bfc and H.inBags(S.bottle)) then Q.skip("the water scenes", "no water bottle in the bags"); return end
    H.stop()
    S.bfc:Empty()
    local spots = {}
    for _, o in ipairs(S.RING1) do spots[#spots + 1] = o end
    for _, o in ipairs({ { 2, 1 }, { -2, -1 }, { 1, 2 }, { -1, -2 } }) do spots[#spots + 1] = o end
    local objs, why = H.build("Base.RainCollector", spots)
    for _, o in ipairs(objs or {}) do
        local m = o
        pcall(function() m = o:getMasterObject() or o end)
        if not S.barrel then
            local fc = nil
            pcall(function() fc = m:getFluidContainer() end)
            if fc then
                fc:addFluid(Fluid.Water, fc:getCapacity())
                if fc:getAmount() > 0 then S.barrel, S.kfc = m, fc end
            end
        end
    end
    if not S.barrel then Q.skip("the water scenes", "no rain collector could be built and filled (" .. tostring(why) .. ")"); return end
    S.k0 = S.kfc:getAmount()
    Q.say("rain collector: " .. H.L(S.k0) .. " of " .. H.L(S.kfc:getCapacity()))
    -- the game's own Transfer liquid on it (ZeD's hook opens the fluid card at once)
    H.zed("the game's Transfer liquid on the rain collector", function() return ISWorldObjectContextMenu.onFluidTransfer(S.pn, S.kfc) end)
    S.flTry = true
end)
H.wait(5000, function() local t = H.fluidT(); return not S.flTry or (t ~= nil and t.d ~= nil) end, function()
    if not S.flTry then return end
    local t = H.fluidT()
    S.flArm = Q.check(t ~= nil and t.d ~= nil and t.from ~= nil, "water: the game's Transfer liquid on the rain collector opens ZeD's fluid card, the collector on the From side", tostring(H.kind()))
    if not S.flArm then return end
    RT.bounds(Q, "the fluid card")
    Q.check(ISWorldObjectContextMenu._zedFluidHooked == true, "water: ZeD's hook is on the game's Transfer liquid")
end)
H.queueFluidRows("water: the card just opened")
Q.step(4, function()
    if not S.flArm then return end
    local v = H.verb("pour")
    Q.check(v ~= nil and v.enabled ~= true, "water: with no Into side picked, Pour waits")
    S.intoFid = "fl:into:i" .. tostring(S.bottle:getID())
    if not H.runZone(S.intoFid) then
        Q.check(false, "water: the empty bottle's row has an Into button", S.intoFid)
        S.flArm = false
    end
end)
H.wait(2000, function() local t = H.fluidT(); return not S.flArm or (t ~= nil and t.into ~= nil and t.d ~= nil and t.d.can == true) end, function()
    if not S.flArm then return end
    local t = H.fluidT()
    local own = nil
    if t and t.into then pcall(function() own = t.into:getOwner() end) end
    S.flArm = Q.check(own == S.bottle and t.d.can == true and math.abs(t.d.max - S.bcap) < 0.011, "water: the bottle picked as Into, the pour sized to the bottle",
        "into " .. H.nm(own) .. ", most " .. tostring(t and t.d and t.d.max))
    if not S.flArm then return end
    H.runZone("fl:step:2")
    Q.check(math.abs((t.frac or 0) - 0.5) < 0.001, "water: the 1/2 step sets half", tostring(t.frac))
    H.pressVerb("pour")
end)
H.wait(25000, function() return not S.flArm or (H.idle() and S.bfc:getAmount() > 0.01) end, function(held)
    if not S.flArm then return end
    local a = S.bfc:getAmount()
    if not held then Q.skip("water: half a bottle poured from the collector", "the bottle holds " .. H.L(a) .. " after 25 s"); H.stop(); return end
    Q.check(math.abs(a - S.bcap * 0.5) <= 0.03, "water: Pour at 1/2 puts half a bottle in", H.L(a))
    Q.say("the collector gave " .. H.L(S.k0 - S.kfc:getAmount()) .. " (rain may top it up)")
end)
H.queueFluidRows("water: half a bottle poured")
-- the rest, stopped part way; then to the top
Q.step(4, function()
    if not S.flArm then return end
    H.runZone("fl:step:3")
    H.pressVerb("pour")
end)
Q.step(40, function()
    if not S.flArm then return end
    local t = H.fluidT()
    Q.say("mid-pour: pouring " .. tostring(t and t.d and t.d.pouring) .. ", Stop " .. tostring(H.zoneFid("fl:stop") ~= nil))
    if not H.runZone("fl:stop") then H.stop() end
end)
H.wait(4000, function() return not S.flArm or H.idle() end, function()
    if not S.flArm then return end
    Q.check(H.idle(), "water: Stop ends the pour")
    H.noErr("water: the pour and its stop")
end)
H.queueFluidRows("water: a pour stopped part way")
Q.step(4, function()
    if not S.flArm then return end
    H.runZone("fl:step:3")
    H.pressVerb("pour")
end)
H.wait(25000, function() return not S.flArm or (H.idle() and S.bfc:getAmount() >= S.bcap - 0.011) end, function(held)
    if not S.flArm then return end
    S.fullArm = held
    if not held then Q.skip("water: the bottle filled to the top", "it holds " .. H.L(S.bfc:getAmount()) .. " after 25 s"); H.stop() end
end)
H.wait(2000, function() local t = H.fluidT(); return not S.fullArm or (t ~= nil and t.d ~= nil and t.d.max <= 0) end, function()
    if not (S.flArm and S.fullArm) then return end
    local t, v = H.fluidT(), H.verb("pour")
    Q.check(t ~= nil and t.d.max <= 0 and v ~= nil and v.enabled ~= true, "water: a full bottle: nothing more to pour, Pour is off", tostring(t and t.d and t.d.max))
    -- Switch, then Empty asks first
    H.pressVerb("switch")
end)
H.queueFluidRows("water: the bottle full")
H.wait(2000, function() local v = H.verb("empty"); return not S.flArm or (v ~= nil and v.enabled == true) end, function(held)
    if not S.flArm then return end
    local t = H.fluidT()
    local own = nil
    if t and t.from then pcall(function() own = t.from:getOwner() end) end
    S.emptyArm = Q.check(held and own == S.bottle, "water: Switch puts the bottle on the From side, Empty offered", H.nm(own))
    if S.emptyArm then H.pressVerb("empty") end
end)
H.wait(2000, function() return not S.emptyArm or H.zoneFid("oc:confirm:no") ~= nil end, function(held)
    if not S.emptyArm then return end
    local c = H.ocard()
    Q.check(held and c ~= nil and c._confirm ~= nil, "water: Empty asks before it pours a bottle out")
    S.aAsk = S.bfc:getAmount()
    H.runZone("oc:confirm:no")
end)
Q.step(20, function()
    if not S.emptyArm then return end
    local c = H.ocard()
    Q.check(c ~= nil and c._confirm == nil and H.idle() and S.bfc:getAmount() == S.aAsk, "water: Cancel leaves the bottle as it was", H.L(S.bfc:getAmount()))
    H.noErr("water: the card's verbs")
    -- the bottle leaves the bags while the card shows it
    Q.say("NOTE the bottle is taken out of the bags now, the card showing it")
    H.takeOut(S.bottle)
end)
H.wait(2500, function()
    local t = H.fluidT()
    return not S.flArm or t == nil or (H.sideOwner(t.from) ~= S.bottle and H.sideOwner(t.into) ~= S.bottle and t.d ~= nil and t.d.can ~= true)
end, function()
    if not S.flArm then return end
    local t, v = H.fluidT(), H.verb("pour")
    if t == nil then Q.say("NOTE the fluid card closed when the bottle left the bags"); return end
    Q.check(H.sideOwner(t.from) ~= S.bottle and H.sideOwner(t.into) ~= S.bottle and (v == nil or v.enabled ~= true),
        "vanish: the bottle gone from the bags: its side of the card empties, Pour is off", "from " .. H.nm(H.sideOwner(t.from)) .. ", into " .. H.nm(H.sideOwner(t.into)))
    local stale = false
    for _, r in ipairs((t.d and t.d.rows) or {}) do if r.item == S.bottle then stale = true end end
    Q.check(not stale, "vanish: the card lists no row for the bottle that is gone")
end)
Q.step(10, function()
    if not S.flArm then return end
    S.flWas = H.fluidT() ~= nil
    Q.say("NOTE the rain collector is destroyed now, " .. (S.flWas and "its fluid card open" or "the card already closed"))
    for _, o in ipairs(S.built) do H.removeObj(o) end
end)
H.wait(4000, function() return not S.flArm or H.fluidT() == nil end, function()
    if not S.flArm then return end
    if S.flWas then Q.check(H.fluidT() == nil, "vanish: the rain collector destroyed: its fluid card closes", tostring(S.OC.closeWhy)) end
    local left = 0
    for _, o in ipairs(S.built) do if H.inWorld(o) then left = left + 1 end end
    Q.check(left == 0, "vanish: the rain collector is gone from the world", left .. " objects left")
    RT.bounds(Q, "after the rain collector vanished")
    H.closeCard()
end)

-- ===================================================================== 6. the campfire
Q.step(10, function()
    if not S.ok then return end
    local sq = H.freeSq(S.RING2)
    if not (sq and SCampfireSystem and SCampfireSystem.instance) then Q.skip("the campfire scenes", "no free square or no campfire system"); return end
    pcall(function() SCampfireSystem.instance:addCampfire(sq) end)
    S.fireSq = sq
    S.used[H.sqKey(sq)] = true
end)
H.wait(5000, function() return S.fireSq == nil or H.campIso() ~= nil end, function()
    if not S.fireSq then return end
    local iso = H.campIso()
    S.fireArm = Q.check(iso ~= nil, "campfire: made beside the character (the game's campfire system)")
    if S.fireArm then H.zed("ObjectCards.open on the campfire", function() return S.OC.open(S.p, "fire", iso) end) end
end)
H.wait(4000, function() return not S.fireArm or H.fireD() ~= nil end, function()
    if not S.fireArm then return end
    local d = H.fireD()
    S.fireArm = Q.check(d ~= nil, "campfire: its fire card opens", tostring(H.kind()))
    if not d then return end
    Q.check(d.fuel == 0 and d.lit == false and H.pill() == ZeD.tr("UI_ZeD_Fire_PillOut"), "campfire: new, the card reads no fuel, not lit, Out", tostring(d.fuel) .. " " .. tostring(d.lit) .. " " .. tostring(H.pill()))
    -- (the game's rule, ISCampingMenu.doLightFireOption: petrol and the notched plank need fuel in the fire; tinder with
    -- a lighter or matches does not, the tinder is the first fuel. So with no fuel Light is lit only for that pair)
    local v = H.verb("light")
    local fi = ISCampingMenu.getNearbyFuelInfo(S.p)
    local wantLight = #fi.starters > 0 and #fi.tinder > 0
    Q.check(v ~= nil and (v.enabled == true) == wantLight, "campfire: with no fuel in it, Light is lit only when a lighter or matches and tinder are in reach (the game's rule)",
        "Light " .. tostring(v and v.enabled) .. "; in reach " .. #fi.starters .. " fire starters, " .. #fi.tinder .. " kinds of tinder")
    RT.bounds(Q, "the fire card")
    RT.give("Base.Plank"); RT.give("Base.Plank")
end)
H.wait(4000, function() local z = H.zoneFid("fire:fuel:1"); return not S.fireArm or (z ~= nil and z.run ~= nil) end, function(held)
    if not S.fireArm then return end
    if not held then Q.skip("campfire: Add fuel pressed and stopped at once", "the card lists no fuel row for two planks"); return end
    S.fuelPressed = H.runZone("fire:fuel:1")
end)
Q.step(10, function() if S.fuelPressed then H.stop() end end)
Q.step(30, function()
    if not S.fireArm then return end
    H.moveTo(S.hx + 0.5, S.hy + 0.5)
    if S.fuelPressed then
        local d, lo = H.fireD(), H.campLua()
        Q.check(d ~= nil and H.idle(), "campfire: Add fuel stopped at once: the card stays open, the character idle")
        Q.say("fuel after the stopped add: card " .. tostring(d and d.fuel) .. ", fire " .. tostring(lo and lo.fuelAmt))
    end
    H.noErr("campfire: the fuel row")
    -- fuelled and lit behind the card's back (the fire's own server object, as the weather or another player changes it)
    local so = H.campServer()
    if so then pcall(function() so:addFuel(120); so:lightFire() end) end
end)
H.wait(6000, function() local d = H.fireD(); return not S.fireArm or (d ~= nil and d.lit == true and d.fuel > 0) end, function(held)
    if not S.fireArm then return end
    local so, d = H.campServer(), H.fireD()
    if not (so and so.isLit == true) then Q.skip("campfire: lit behind the card's back", "the fire's own lightFire did not light it"); return end
    S.litArm = true
    Q.check(held, "campfire: fuelled and lit behind the card's back, the card reads lit with fuel within 6 s", tostring(d and d.lit) .. ", fuel " .. tostring(d and d.fuel))
    Q.check(d ~= nil and math.abs(d.fuel - so.fuelAmt) <= 2, "campfire: the card's fuel is the fire's own", tostring(d and d.fuel) .. " vs " .. tostring(so.fuelAmt))
    Q.check(H.pill() ~= ZeD.tr("UI_ZeD_Fire_PillOut"), "campfire: lit, the card no longer says Out", tostring(H.pill()))
    local vo, vl = H.verb("out"), H.verb("light")
    Q.check(vo ~= nil and vo.enabled == true and (vl == nil or vl.enabled ~= true), "campfire: lit, Put out is offered and Light is not")
    local iso = H.campIso()
    local c = iso and iso:getContainer()
    if c then S.campFood = c:AddItem("Base.Steak") end
    H.speed(3)
end)
H.wait(15000, function() return not S.litArm or S.campFood == nil or S.campFood:getCookingTime() > 0 or S.campFood:isCooked() end, function(held)
    if not S.fireArm then return end
    H.speed(1)
    if not S.litArm then return end
    if S.campFood == nil then Q.skip("campfire: a steak cooks on it", "the campfire has no container for it")
    elseif held then
        -- (Nov 25 2026, ck_tab's K24: was Q.check(true, ...). The steak is in the fire's own container, the fire is lit
        -- by its own server object, and its cooking time has grown)
        local soL, isoL = H.campServer(), H.campIso()
        local inFire = isoL ~= nil and S.campFood:getContainer() == isoL:getContainer()
        Q.check(inFire and soL ~= nil and soL.isLit == true and (S.campFood:getCookingTime() > 0 or S.campFood:isCooked()),
            "campfire: a steak on the lit fire cooks on fast-forward (in the fire, the fire lit, its cooking time grown)",
            string.format("%.1f minutes, heat %.2f, in the fire %s, lit %s", S.campFood:getCookingTime(), S.campFood:getHeat(), tostring(inFire), tostring(soL and soL.isLit)))
    else Q.skip("campfire: a steak cooks on it", string.format("after 15 s: %.1f minutes, heat %.2f", S.campFood:getCookingTime(), S.campFood:getHeat())) end
    if S.campFood then H.factsOK(S.campFood, "steak on the campfire") end
    local so, d = H.campServer(), H.fireD()
    if so and d then Q.check(math.abs(d.fuel - so.fuelAmt) <= 3, "campfire: after the fast-forward the card's fuel is still the fire's own", tostring(d.fuel) .. " vs " .. tostring(so.fuelAmt)) end
    RT.bounds(Q, "the fire card, lit")
    Q.say("NOTE the campfire is removed now, lit, its card " .. (d and "open" or "closed"))
    S.fireCardWas = d ~= nil
    H.takeOut(S.campFood)
    if so then pcall(function() SCampfireSystem.instance:removeCampfire(so) end) end
end)
H.wait(5000, function() return not S.fireArm or (H.campLua() == nil and H.kind() ~= "fire") end, function()
    if not S.fireArm then return end
    Q.check(H.campLua() == nil, "vanish: the campfire is gone")
    if S.fireCardWas then Q.check(H.kind() ~= "fire", "vanish: a campfire removed while its card is open: the card closes", tostring(S.OC.closeWhy)) end
    RT.bounds(Q, "after the campfire vanished")
    H.closeCard()
end)

-- ===================================================================== 7. the Cooking tab
Q.step(10, function()
    if not S.ok then return end
    H.stop()
    S.p:getModData().ZeD_CookDishes = {}
    S.pot = RT.give("Base.Pot")
    if S.pot then pcall(function() local fc = S.pot:getFluidContainer(); fc:addFluid(Fluid.Water, fc:getCapacity()) end) end
    S.bread, S.bowl = RT.give("Base.BreadSlices"), RT.give("Base.Bowl")
    S.ckCarrot, S.fzCarrot, S.potato, S.cabbage = RT.give("Base.Carrots"), RT.give("Base.Carrots"), RT.give("Base.Potato"), RT.give("Base.Cabbage")
    for _, ft in ipairs({ "Base.Tomato", "Base.Lettuce", "Base.Ham", "Base.Cheese", "Base.Onion", "Base.BellPepper", "Base.Broccoli" }) do RT.give(ft) end
    if S.fzCarrot then S.fzCarrot:setFreezingTime(100); S.fzCarrot:setFrozen(true) end
    -- (the rotten carrot of the card scene is still in the bags: three carrots, one good, one frozen, one rotten)
    Q.check(S.pot ~= nil and S.bread ~= nil and S.bowl ~= nil and S.ckCarrot ~= nil and S.potato ~= nil and S.cabbage ~= nil,
        "cooking: a pot of water, bread slices, a bowl and vegetables given")
end)
H.openCookTab()
Q.step(10, function()
    if not S.ok then return end
    S.ckArm = Q.check(H.cookDrawn(), "cooking: with bases carried the Cooking tab is in the strip and opens", "in the strip " .. tostring(H.cookInStrip()))
    if not S.ckArm then return end
    local s = H.cs()
    Q.check(#(s.dishList or {}) >= 3, "cooking: a pot of water, bread and a bowl carried: three dishes or more offered", table.concat(s.dishList or {}, ", "))
    RT.bounds(Q, "the Cooking tab")
end)
H.pickDish("Stew")
H.queueIng("cooking: stew")
Q.step(4, function()
    S.stewArm = S.ckArm and S.dishOK
    if not S.stewArm then return end
    local s = H.cs()
    local g = s.ingCache and s.ingCache.byFt and s.ingCache.byFt["Base.Carrots"]
    Q.say("carrots in reach: counted " .. tostring(g and g.n) .. ", why " .. tostring(g and g.why) .. " (one good, one frozen, one rotten carried)")
    Q.check(g ~= nil and (g.n or 0) <= 2, "cooking: the frozen carrot is not counted as one to add", tostring(g and g.n))
    H.cpress("cook:ing:Base.Carrots")
end)
-- two frames apart: the same carrot again and again, then in and out
for _ = 1, 4 do Q.step(2, function() if S.stewArm then H.cpress("cook:ing:Base.Carrots") end end) end
Q.step(3, function()
    if not S.stewArm then return end
    local good, detail = H.planSane()
    Q.check(good, "cooking: a carrot pressed five times: no more go in than are carried", detail .. "; plan " .. H.planFts())
end)
Q.step(2, function() if S.stewArm then H.cpress("cook:ing:Base.Potato") end end)
Q.step(2, function() if S.stewArm then H.cpress("cook:plan:1") end end)
Q.step(2, function() if S.stewArm then H.cpress("cook:ing:Base.Cabbage") end end)
Q.step(2, function() if S.stewArm then H.cpress("cook:plan:1") end end)
Q.step(2, function() if S.stewArm then H.cpress("cook:plan:1") end end)
Q.step(2, function() if S.stewArm then H.cpress("cook:plan:1") end end)   -- (one press more than there are rows)
Q.step(3, function()
    if not S.stewArm then return end
    local good, detail = H.planSane()
    Q.check(good, "cooking: ingredients put in and taken out two frames apart keep the dish inside what is carried", detail .. "; plan " .. H.planFts())
    H.noErr("cooking: fast presses")
    local s = H.cs()
    if s then s.plan = {} end
end)
Q.step(3, function() if S.stewArm then H.cpress("cook:ing:Base.Carrots") end end)
Q.step(3, function() if S.stewArm then H.cpress("cook:ing:Base.Potato") end end)
Q.step(3, function() if S.stewArm then H.cpress("cook:ing:Base.Cabbage") end end)
Q.step(4, function()
    if not S.stewArm then return end
    S.stewArm = Q.check(H.planCount("Base.Carrots") == 1 and H.planCount("Base.Potato") == 1 and H.planCount("Base.Cabbage") == 1 and #H.plan() == 3,
        "cooking: a carrot, a potato and a cabbage in the stew", H.planFts())
    local z = H.czone("cook:make")
    Q.check(z ~= nil and not z.disabled, "cooking: Make is lit")
    -- the potato leaves the bags while it is in the dish (the tab looks again by itself, about once a second)
    H.takeOut(S.potato)
end)
H.wait(4000, function() local s, z = H.cs(), H.czone("cook:make"); return not S.stewArm or (s ~= nil and s.anyMissing and z ~= nil and z.disabled) end, function(held)
    if not S.stewArm then return end
    Q.check(held, "vanish: the potato gone from the bags: its row reads missing and Make waits, within 4 s", "missing " .. tostring(H.cs() and H.cs().anyMissing))
    local idx = nil
    for i, e in ipairs(H.plan()) do if e.ft == "Base.Potato" then idx = i end end
    if idx then H.cpress("cook:plan:" .. idx) end
end)
H.wait(3000, function() local z = H.czone("cook:make"); return not S.stewArm or (H.planCount("Base.Potato") == 0 and z ~= nil and not z.disabled) end, function(held)
    if not S.stewArm then return end
    S.stewArm = Q.check(held, "cooking: the missing potato taken out of the dish, Make is lit again", H.planFts())
    if S.stewArm then H.cpress("cook:make") end
end)
-- Make stopped at once
Q.step(8, function() if S.stewArm then H.stop() end end)
Q.step(40, function()
    if not S.stewArm then return end
    local st = H.dishes("Base.PotOfStew")
    Q.check(H.cookDrawn() and H.idle() and #st <= 1, "cooking: Make stopped after 8 frames: the tab still draws, no second dish begun",
        #st .. " stews, " .. H.count("Base.Pot") .. " pots, plan " .. H.planFts())
    H.noErr("cooking: Make and its stop")
    S.stewHalf = #st
end)
H.wait(3000, function() local z = H.czone("cook:make"); return not S.stewArm or (z ~= nil and not z.disabled) end, function(held)
    if not S.stewArm then return end
    if not held then
        local s = H.cs()
        Q.say("NOTE after the stopped Make the tab offers no Make: dish " .. tostring(s and s.dish) .. ", plan " .. H.planFts() .. ", missing " .. tostring(s and s.anyMissing))
        S.stewArm = false
        return
    end
    H.speed(3)
    H.cpress("cook:make")
end)
H.wait(20000, function() return not S.stewArm or (H.idle() and #H.dishes("Base.PotOfStew") >= 1 and H.dishes("Base.PotOfStew")[1] >= 2) end, function(held)
    if not S.ckArm then return end
    H.speed(1)
    if not S.stewArm then return end
    local st = H.dishes("Base.PotOfStew")
    Q.check(held and #st == 1, "cooking: Make after the stop: one pot of stew, the carrot and the cabbage in it",
        #st .. " stews holding " .. tostring(st[1]) .. ", " .. H.count("Base.Pot") .. " pots left")
    H.noErr("cooking: Make")
end)
-- a sandwich: Make, and the tab left three frames later
H.pickDish("Sandwich")
H.queueIng("cooking: sandwich")
Q.step(4, function()
    S.swArm = S.ckArm and S.dishOK
    if not S.swArm then return end
    S.sw1 = H.addAny(nil)
end)
Q.step(3, function() if S.swArm then S.sw2 = H.addAny(S.sw1) end end)
Q.step(6, function()
    if not S.swArm then return end
    local z = H.czone("cook:make")
    S.swArm = Q.check(#H.plan() >= 1 and z ~= nil and not z.disabled, "cooking: a sandwich of what the tab offers, Make lit", H.planFts())
    S.swN = #H.plan()
    if S.swArm then H.speed(3); H.cpress("cook:make") end
end)
Q.step(3, function() if S.swArm then RT.charTab("loot") end end)
H.wait(20000, function() return not S.swArm or (H.idle() and #H.dishes("Base.Sandwich") >= 1 and H.dishes("Base.Sandwich")[1] >= S.swN) end, function(held)
    if not S.ckArm then return end
    H.speed(1)
    if not S.swArm then return end
    local sw = H.dishes("Base.Sandwich")
    Q.check(held and #sw == 1, "cooking: the tab left three frames after Make: the sandwich is still made whole",
        #sw .. " sandwiches holding " .. tostring(sw[1]) .. " of " .. tostring(S.swN))
    Q.check(RT.cw() ~= nil and RT.cw()._activeTab ~= "cooking", "cooking: the window stayed on the tab the player went to", tostring(RT.cw() and RT.cw()._activeTab))
end)
H.openCookTab()
-- a salad filled past its limit, saved and forgotten, then its bowl gone
H.pickDish("Salad")
H.queueIng("cooking: salad")
Q.step(2, function() S.sdArm = S.ckArm and S.dishOK and H.cookDrawn() end)
for _ = 1, 10 do Q.step(2, function() if S.sdArm then H.addAny(nil) end end) end
Q.step(4, function()
    if not S.sdArm then return end
    local good, detail = H.planSane()
    Q.check(good and #H.plan() >= 1, "cooking: a salad pressed full, ten presses: inside its limit and what is carried", detail .. "; plan " .. H.planFts())
    H.noErr("cooking: the salad's presses")
    S.sdSave = H.cpress("cook:save")
end)
Q.step(6, function()
    if not S.sdArm then return end
    local l = S.p:getModData().ZeD_CookDishes or {}
    Q.check(S.sdSave and #l == 1 and H.czone("cook:forget") ~= nil, "cooking: Save keeps the dish and turns to Forget", #l .. " saved")
    H.cpress("cook:forget")
end)
Q.step(6, function()
    if not S.sdArm then return end
    local l = S.p:getModData().ZeD_CookDishes or {}
    Q.check(#l == 0, "cooking: Forget takes it off the list", #l .. " saved")
    RT.bounds(Q, "the Cooking tab with a salad planned")
    S.sdKey = H.cs() and H.cs().dish
    Q.say("NOTE the bowl is taken out of the bags now, the salad planned in it")
    H.takeOut(S.bowl)
end)
H.wait(4000, function()
    local s = H.cs()
    return not S.sdArm or s == nil or not H.cookDrawn() or (s.bases ~= nil and s.bases[S.sdKey] == nil and s.dish ~= S.sdKey)
end, function(held)
    if not S.sdArm then return end
    local s = H.cs()
    Q.check(held, "vanish: the bowl gone with its salad planned: the tab leaves that dish within 4 s", "dish " .. tostring(s and s.dish) .. ", plan " .. H.planFts())
    if s and H.cookDrawn() and s.dish ~= S.sdKey then Q.check(#H.plan() == 0, "vanish: the next dish starts with an empty plan", H.planFts()) end
    H.noErr("cooking: the base gone")
    -- every base gone: the tab goes
    H.takeOut(S.pot); H.takeOut(S.bread)
    pcall(function()
        local inv = S.p:getInventory()
        for _, ft in ipairs({ "Base.PotOfStew", "Base.Sandwich", "Base.Salad" }) do
            local l = inv:getAllTypeRecurse(ft)
            for i = l:size() - 1, 0, -1 do
                local it = l:get(i)
                if not S.snap or not S.snap[it:getID()] then H.takeOut(it) end
            end
        end
    end)
    S.goneArm = true
    if S.was.cookTab then
        S.goneArm = false
        Q.skip("vanish: every base gone, the tab goes", "the character's own bags put the Cooking tab up before the script gave anything")
    end
end)
H.wait(6000, function() return not S.goneArm or (not H.cookInStrip() and RT.cw() ~= nil and RT.cw()._activeTab ~= "cooking") end, function(held)
    if not S.goneArm then return end
    if not held then Q.say("NOTE dishes the tab still lists: " .. table.concat((H.cs() and H.cs().dishList) or {}, ", ")) end
    Q.check(held, "vanish: every base gone with the tab open: the tab leaves the strip and the window leaves it, within 6 s",
        "in the strip " .. tostring(H.cookInStrip()) .. ", on " .. tostring(RT.cw() and RT.cw()._activeTab))
    RT.bounds(Q, "after the Cooking tab went")
end)

-- ===================================================================== put back
Q.mark()
-- (the character first, in a step of its own: whatever threw or ran out of time before this, he is safe and healed)
Q.step(2, function()
    H.safe()
    H.heal()
end)
Q.step(5, function()
    pcall(H.speed, 1)
    H.stop()
    pcall(function() if H.spUp() then S.SP.close(S.p) end end)
    pcall(function()
        if S.was.look ~= nil and ZeD.Settings and ZeD.Settings.lookStyleOption then ZeD.Settings.lookStyleOption:setValue(S.was.look) end
    end)
    if S.ST then pcall(S.ST.unbind, S.p) end
    H.closeCard()
    if S.gen then pcall(function() S.gen:setActivated(false); S.gen:setConnected(false) end) end
    -- what is still in a placed thing, then the things themselves (each on its own: one of them may never have been made)
    pcall(H.takeOut, S.steak); pcall(H.takeOut, S.mwFood); pcall(H.takeOut, S.frzSteak); pcall(H.takeOut, S.milk); pcall(H.takeOut, S.campFood)
    for _, o in ipairs(S.placed) do pcall(H.removeObj, o) end
    for _, o in ipairs(S.built) do pcall(H.removeObj, o) end
    local so = H.campServer()
    if so then pcall(function() so:putOut(); SCampfireSystem.instance:removeCampfire(so) end) end
    pcall(function() RT.ww()._containersDirty = true end)
    -- the Cooking tab's own memory and the saved dishes
    pcall(function() S.p:getModData().ZeD_CookDishes = S.was.dishes end)
    local s = H.cs()
    if s then s.plan, s.popup, s.sort, s.qty = {}, nil, "name", 1 end
end)
Q.step(5, function()
    -- the bags: everything that was not there at the start
    local okW, gone = pcall(H.sweep)
    RT.takeBack()
    Q.say("put back: " .. tostring(okW and gone or "?") .. " items not in the bags at the start taken away")
    local c = H.content()
    if c then
        if c._expandedStacks then
            for k, v in pairs(S.stackWas) do c._expandedStacks[k] = (v ~= false) and v or nil end
        end
        c._selectedItems = {}
        c._lastClickedItem = nil
    end
    pcall(function()
        if S.was.hands then
            S.p:setPrimaryHandItem(S.was.hands[1])
            S.p:setSecondaryHandItem(S.was.hands[2])
        end
    end)
    H.heal()
    pcall(H.statsBack)   -- (the heal resets some stats: the values found win)
    if S.hx then pcall(H.moveTo, S.hx + 0.5, S.hy + 0.5) end
    if ZEDQA_HOME then pcall(ZEDQA_HOME, "bx_cook") end
    RT.worldTab("loot")
    if S.was.charTab and S.was.charTab ~= "cooking" then RT.charTab(S.was.charTab) else RT.charTab("loot") end
    if S.was.pair == false then RT.pairShut() end
end)
H.wait(6000, function() return H.campLua() == nil end, function(held)
    if S.fireSq then Q.check(held, "put back: the campfire is gone") end
    local left = 0
    for _, o in ipairs(S.placed) do if H.inWorld(o) then left = left + 1 end end
    for _, o in ipairs(S.built) do if H.inWorld(o) then left = left + 1 end end
    Q.check(left == 0, "put back: everything placed or built is taken away", left .. " left of " .. (#S.placed + #S.built))
    local extra = 0
    if S.snap then
        local okI, now = pcall(H.invIds)
        if okI then for id in pairs(now) do if not S.snap[id] then extra = extra + 1 end end end
    end
    Q.check(extra == 0, "put back: the bags hold only what they held at the start", extra .. " extra items")
    Q.check(getGameSpeed() == 1 and H.cur() == nil and not H.spUp() and H.idle(), "put back: game speed 1, no station bound, no pop-out, the character idle",
        "speed " .. tostring(getGameSpeed()))
    RT.bounds(Q, "the end")
end)
-- the character, last of all: healed, looked over, and only then god mode and invincible as they were found
Q.step(10, function()
    H.safe()
    local okF, fires = pcall(H.fireSweep)
    if not okF then fires = "? (" .. tostring(fires) .. ")" end
    H.heal()
    local bad = H.hurt()
    if #bad > 0 then
        H.heal()
        bad = H.hurt()
    end
    local well = Q.check(#bad == 0, "put back: the character is alive at full health, no wound on any part, no fracture, not infected, not on fire",
        #bad == 0 and "health 100" or table.concat(bad, ", "))
    pcall(H.statsBack)
    if well then
        if S.was.inv ~= nil then pcall(function() S.p:setInvincible(S.was.inv and true or false) end) end
        if S.was.god ~= nil then pcall(function() S.p:setGodMod(S.was.god and true or false) end) end
    end
    local g, iv = nil, nil
    pcall(function() g = S.p:isGodMod(); iv = S.p:isInvincible() end)
    Q.say("god mode " .. tostring(g) .. " (was " .. tostring(S.was.god) .. "), invincible " .. tostring(iv) .. " (was " .. tostring(S.was.inv) .. ")"
        .. (well and "" or ": both left ON, he is not well") .. "; fires put out near home: " .. tostring(fires))
end)
Q.start()
