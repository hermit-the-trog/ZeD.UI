-- ZeDUI/tools/qa/bx_fire.lua  (Nov 21 2026, QA "beast mode"): burn and extinguish on the drag strip's open asphalt.
-- Run after zedqa_prelude.lua and rt_kit.lua; grep "ZEDQA bx_fire". No pictures; every check prints PASS or FAIL.
--
-- CAMPFIRE (ObjectCardFire.lua through ObjectCards.lua, opened the game's way: ISCampingMenu.onDisplayInfo, hooked)
--   a campfire made beside the character (the game's campfire system); its card reads no fuel, not lit, Out; Put out
--   pressed on a dead fire queues nothing; planks, paper and matches given; Add fuel (the card's own row) started and
--   stopped at once; Add pressed three times in one frame; Add with the World window's tab switched away and back in
--   the middle; the fire filled to the sandbox maximum (Add fuel goes away, every row reads full); Light with paper;
--   Add on the lit fire with both windows shut and opened again in the middle; the character moved 10 tiles away (the
--   card closes past its leash) and back; Put out pressed twice in one frame; Take apart asked and cancelled, then
--   asked and confirmed: the campfire goes while its card shows, and the card closes.
--   After every act the card's fuel, lit and state word are compared with the game's own campfire object (the
--   server's copy, which the client's is read from).
-- WORLD FIRE (the game's IsoFireManager.StartFire on a square 3 tiles away)
--   while it burns: the game's window check on the flame answers no with no error, ZeD's fire card refuses a plain
--   flame and does not list it as a fire to browse, every tab of both windows is opened in turn, more fire started
--   beside it (the fire's reach is counted), the windows measured. Put out the player's way (the game's extinguish
--   cursor, ISWorldObjectContextMenu.onRemoveFire, then its own create: equip + ISPutOutFire): with a fire
--   extinguisher (its card open in the Character window), with a dirt bag on its last use (used up while its card
--   shows: no card may stay on an item that is gone), with a bucket of water (the character set alight first, with
--   god mode on, so the water puts out the character and the square together).
-- BURN (HealthTab.lua): god mode off and invincible on for this part (god mode heals a wound at once); a burn that
--   needs cleaning set on the left forearm (what the game's own debug toggle sets); ZeD's Health tab lists it; the
--   part's menu through ZeD's own click (HealthTab._onPartClicked) offers the game's Clean Burn and Bandage; Clean
--   Burn started and stopped; started again with the tab switched away and back in the middle; Bandage; the tab hides
--   the burn under the bandage as the game's panel does; a menu left open while the body heals, then picked.
-- PUT BACK: the print watch off, the menu shut, the actions stopped, the cursor dropped, the card closed, game speed
--   1; the character not burning, every fire in a 15-tile radius of home out (each square checked), the campfire
--   gone, the floors in a 5-tile radius as found; the body healed, the stats, god mode, invincible and the clothing's
--   condition as found; everything given (and the campfire's stones, the emptied sandbag) taken away, the hands, the
--   tabs and the windows as found; the character home. No ZeD option is changed.
-- SAFETY (Nov 21 2026, the preflight; the same rule as bx_health.lua): the character must never die or stay hurt.
--   God mode and invincible are put ON at the first step and stay on through the campfire and the fire scenes (the
--   prelude's god mode is not relied on; when the game refuses it, outside -debug, nothing is lit and the run goes
--   straight to the put-back). God mode goes off only for the burn scenes, and only once no fire is left within 15
--   tiles and no zombie is within 20. A guard runs on EVERY game tick (H.safety, Events.OnTick, not the step queue: it
--   keeps running when a step throws): with god mode meant to be on it puts it back on (and stops the run if it
--   cannot); in the burn scenes anything but the staged burn (a bite, a scratch, bleeding, a fracture, fire on the
--   character, health under 35, a zombie within 12 tiles) puts god mode on, heals and jumps to the put-back; it
--   keeps the fire to the squares the script lit (a square the fire spread to is put out); and when the put-back did
--   not finish in time it heals, leaves god mode ON and prints the healed PASS or FAIL line. The put-back heals first,
--   then PROVES the body whole (health 100, no wound on any part, no fracture, not infected, alive) with a PASS or
--   FAIL line while god mode is still on; god mode and invincible go back as found only for a healed body.

if not RT then
    print("ZEDQA bx_fire ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA bx_fire VERDICT FAIL 1")
    print("ZEDQA bx_fire DONE")
    return
end
if not (ZeD and ZeD.ObjectCards and ZeD.HealthTab and ZeD_WorldWindow and ZeD_CharacterWindow) then
    print("ZEDQA bx_fire ERR ZeD is not loaded (ObjectCards, HealthTab or the windows are missing)")
    print("ZEDQA bx_fire VERDICT FAIL 1")
    print("ZEDQA bx_fire DONE")
    return
end

local Q = RT.make("bx_fire")
Q.maxMs = 400000   -- (the whole script has 8 minutes: past 6 min 40 s it jumps to the put-back)
local S = { p = RT.p, pn = RT.pn, inv0 = {}, cnt0 = {}, errs = {}, floors = {}, stats = {}, worn = {}, was = {} }
local H = {}
local OC = ZeD.ObjectCards
local HT = ZeD.HealthTab
local setSpeed = ZEDQA_SPEED or setGameSpeed
S.RING2 = { { 2, 0 }, { -2, 0 }, { 0, 2 }, { 0, -2 }, { 2, 2 }, { -2, -2 }, { 2, -2 }, { -2, 2 } }
S.FIRE = { { 0, -4 }, { 4, 0 }, { -4, 0 }, { 0, 4 }, { 4, -4 }, { -4, 4 } }
S.STATS = { "PANIC", "STRESS", "PAIN", "FATIGUE", "ENDURANCE", "HUNGER", "THIRST", "BOREDOM", "UNHAPPINESS", "WETNESS", "SICKNESS", "FOOD_SICKNESS" }
S.BYPRODUCT = { ["Base.Stone2"] = true, ["Base.EmptySandbag"] = true, ["Base.BandageDirty"] = true }
S.FIG = "Left Forearm"

-- ===================================================================== helpers: the queue
-- wait at most ms for cond (an error in it counts as "not yet"), then fn(true or false)
function H.wait(ms, cond, fn)
    local st = {}
    Q.waitFor(2, 1000000, function()
        st.t = st.t or getTimestampMs()
        local ok, r = pcall(cond)
        if ok and r then st.ok = true; return true end
        return getTimestampMs() - st.t >= ms
    end, function() fn(st.ok == true) end)
end
-- ZeD code under test, called so that an error becomes a FAIL line and the script goes on
function H.try(what, fn, a, b, c, d, e)
    local ok, r = pcall(fn, a, b, c, d, e)
    if not ok then Q.check(false, what .. ": no error", tostring(r)) end
    return ok, r
end
function H.qn()
    local n = 0
    pcall(function()
        local q = ISTimedActionQueue.getTimedActionQueue(S.p)
        n = (q and q.queue) and #q.queue or 0
    end)
    return n
end
function H.stopActions() pcall(function() S.p:StopAllActionQueue() end) end
function H.alive() local dead = true; pcall(function() dead = S.p:isDead() end); return not dead end

-- ===================================================================== helpers: ZeD's own lines that say "failed"
-- (ObjectCards.lua catches a verb's or a refresh's error and only prints it: the runner would never see it)
function H.spyOn()
    if S.print0 then return end
    S.print0 = print
    print = function(...)
        local a = ...
        if type(a) == "string" and a:find("[ZeD", 1, true) and (a:find("failed", 1, true) or a:find("rror", 1, true) or a:find("attempt", 1, true)) then
            S.errs[#S.errs + 1] = a
        end
        return S.print0(...)
    end
end
function H.spyOff()
    if S.print0 then print = S.print0; S.print0 = nil end
end

-- ===================================================================== helpers: squares, fire
function H.sq(dx, dy) return getCell():getGridSquare(S.hx + dx, S.hy + dy, 0) end
function H.freeSq(offsets)
    for _, o in ipairs(offsets) do
        local sq = H.sq(o[1], o[2])
        local free = false
        if sq and sq ~= S.cfSq then
            pcall(function() free = sq:isFree(false) and not sq:HasTree() and sq:getVehicleContainer() == nil and sq:isOutside() end)
        end
        if free then return sq end
    end
    return nil
end
function H.place(x, y)
    pcall(function()
        local p = S.p
        p:setX(x); p:setY(y); p:setZ(0); p:setLastX(x); p:setLastY(y); p:setLastZ(0)
    end)
end
function H.placeOn(sq) if sq then H.place(sq:getX() + 0.5, sq:getY() + 0.5) end end
function H.goHome() H.place(S.hx + 0.5, S.hy + 0.5) end
function H.burning(sq)
    local b = false
    pcall(function() b = sq:has(IsoFlagType.burning) end)
    return b
end
-- the flame on a square (the game's IsoFire that is not a campfire's or a fireplace's)
function H.flame(sq)
    local f = nil
    pcall(function()
        local objs = sq:getObjects()
        for i = 0, objs:size() - 1 do
            local o = objs:get(i)
            if f == nil and instanceof(o, "IsoFire") and not o:isPermanent() then f = o end
        end
    end)
    return f
end
-- anything of fire on a square: the burning flag or any IsoFire (flame, smoke, a campfire's)
function H.hot(sq)
    local hot = false
    pcall(function()
        if sq:has(IsoFlagType.burning) then hot = true end
        local objs = sq:getObjects()
        for i = 0, objs:size() - 1 do
            if instanceof(objs:get(i), "IsoFire") then hot = true end
        end
    end)
    return hot
end
function H.douse(sq)
    pcall(function() sq:stopFire() end)
    pcall(function() sq:transmitStopFire() end)
    pcall(function() IsoFireManager.RemoveAllOn(sq) end)
end
function H.scan(r, fix)
    local n, cell = 0, getCell()
    for dx = -r, r do
        for dy = -r, r do
            local sq = cell:getGridSquare(S.hx + dx, S.hy + dy, 0)
            if sq and H.hot(sq) then
                n = n + 1
                if fix then H.douse(sq) end
            end
        end
    end
    return n
end
function H.startFire(sq)
    return pcall(function() IsoFireManager.StartFire(getCell(), sq, true, 100, 2000) end)
end
function H.floorKey(sq)
    local k = "?"
    pcall(function() k = tostring(sq:getFloor():getSprite():getName()) .. "|" .. sq:getObjects():size() end)
    return k
end
function H.floorName(k) return (tostring(k):match("^(.-)|")) or "" end
function H.floorsSnap()
    for dx = -5, 5 do
        for dy = -5, 5 do
            local sq = H.sq(dx, dy)
            if sq then S.floors[#S.floors + 1] = { sq = sq, k = H.floorKey(sq) } end
        end
    end
end
-- floors as found: a floor the fire charred gets its own sprite back; returns how many still differ
function H.floorsBack()
    local diff, fixed, first = 0, 0, nil
    for _, f in ipairs(S.floors) do
        if H.floorKey(f.sq) ~= f.k then
            if H.floorName(H.floorKey(f.sq)) ~= H.floorName(f.k) then
                pcall(function() f.sq:getFloor():setSprite(getSprite(H.floorName(f.k))) end)
                pcall(function() f.sq:RecalcProperties() end)
                fixed = fixed + 1
            end
            if H.floorKey(f.sq) ~= f.k then
                diff = diff + 1
                first = first or (f.sq:getX() .. "," .. f.sq:getY() .. " " .. f.k .. " -> " .. H.floorKey(f.sq))
            end
        end
    end
    return diff, fixed, first
end

-- ===================================================================== helpers: the inventory
function H.invItems()
    local out = {}
    pcall(function()
        local items = S.p:getInventory():getItems()
        for i = 0, items:size() - 1 do out[#out + 1] = items:get(i) end
    end)
    return out
end
function H.invSnap()
    for _, it in ipairs(H.invItems()) do
        local ft = it:getFullType()
        S.inv0[it] = true
        S.cnt0[ft] = (S.cnt0[ft] or 0) + 1
    end
end
function H.give(ft)
    local it = nil
    pcall(function() it = S.p:getInventory():AddItem(ft) end)
    if it then pcall(function() it:getModData().ZeDQA_spawned = true end) end
    return it
end
function H.mine(it)
    local m = false
    pcall(function() m = it:getModData().ZeDQA_spawned == true end)
    return m or S.BYPRODUCT[it:getFullType()] == true
end
function H.has(it)
    local h = false
    pcall(function() h = it ~= nil and S.p:getInventory():contains(it) end)
    return h
end
function H.drop(it)
    pcall(function() if S.p:getPrimaryHandItem() == it then S.p:setPrimaryHandItem(nil) end end)
    pcall(function() if S.p:getSecondaryHandItem() == it then S.p:setSecondaryHandItem(nil) end end)
    pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
end
-- everything this script brought is taken away. The game's add fuel takes "the first plank it finds": when it burnt
-- one of the character's own, one of the given ones stays in its place, so each type's count ends as found.
function H.settle()
    local have, fresh, gone, kept = {}, {}, 0, 0
    for _, it in ipairs(H.invItems()) do
        local ft = it:getFullType()
        if S.inv0[it] then have[ft] = (have[ft] or 0) + 1 elseif H.mine(it) then fresh[#fresh + 1] = it end
    end
    for _, it in ipairs(fresh) do
        local ft = it:getFullType()
        if (have[ft] or 0) < (S.cnt0[ft] or 0) then
            have[ft] = (have[ft] or 0) + 1
            kept = kept + 1
        else
            H.drop(it)
            gone = gone + 1
        end
    end
    return gone, kept
end
function H.left()
    local n = 0
    for _, it in ipairs(H.invItems()) do
        if not S.inv0[it] and H.mine(it) then n = n + 1 end
    end
    return n
end
function H.count(ft)
    local n = 0
    for _, it in ipairs(H.invItems()) do if it:getFullType() == ft then n = n + 1 end end
    return n
end
function H.uses(it)
    local u = -1
    pcall(function() u = it:getCurrentUses() end)
    return u
end

-- ===================================================================== helpers: the Character window's list and card
function H.content() local w = RT.cw(); return w and w._mainContent end
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
    local ok = H.try("a click on a row of the Character window's list", function() c:onMouseDown(x, y); c:onMouseUp(x, y) end)
    return ok
end
function H.cardOn(item)
    local w = RT.cw()
    local c = w and w._itemCard
    return item ~= nil and w ~= nil and w._drawerItem == item and c ~= nil and c.item == item
end
-- queue: the item's row found (the list scrolled if need be) and clicked; S[flag] says whether its card opened
function H.qCard(key, flag, label)
    Q.step(2, function() S.seekPos = nil; S[flag] = false; RT.charTab("loot") end)
    H.wait(4000, function() return S[key] == nil or H.seekRow(S[key]) end, function(ok)
        if S[key] == nil then return end
        if not ok then Q.skip(label .. ": its card in the Character window", "its row was not found in the list"); return end
        H.click(S[key])
    end)
    H.wait(2000, function() return S[key] == nil or H.cardOn(S[key]) end, function(ok)
        if S[key] == nil then return end
        S[flag] = ok and H.cardOn(S[key])
        Q.say(label .. ": its card open in the Character window: " .. tostring(S[flag]))
    end)
end

-- ===================================================================== helpers: the object card
function H.ocard() local c = nil; pcall(function() c = ZeD_WorldWindow.getObjectCard(S.pn) end); return c end
function H.entry() local c = H.ocard(); return c and c.entry end
function H.closeCard() pcall(function() ZeD_WorldWindow.closeObjectCard(S.pn) end) end
function H.pill(e)
    if not (e and e.def and e.def.pill) then return nil end
    local ok, words = pcall(e.def.pill, e.t)
    return ok and words or nil
end
function H.zoneFid(fid)
    local c = H.ocard()
    for _, z in ipairs((c and c._lastZones) or {}) do if z.fid == fid then return z end end
    for _, z in ipairs((c and c._zones) or {}) do if z.fid == fid then return z end end
    return nil
end
function H.verb(id)
    local e = H.entry()
    for _, v in ipairs((e and e.t and e.t.verbs) or {}) do if v.id == id then return v end end
    return nil
end
-- a zone pressed as a click presses it
function H.run(fid, what)
    local z = H.zoneFid(fid)
    if not (z and z.run) then return false end
    local ok = H.try(what, z.run, H.ocard(), S.p)
    return ok
end
function H.campLua(sq)
    local lo = nil
    pcall(function() lo = CCampfireSystem.instance:getLuaObjectOnSquare(sq) end)
    return lo
end
function H.fireInfo()
    local lo = S.cfSq and H.campLua(S.cfSq)
    local iso = lo and lo:getIsoObject()
    if iso then H.try("the campfire's Info (ZeD's hook)", ISCampingMenu.onDisplayInfo, nil, S.p, iso, lo) end
end
function H.fireD()
    local e = H.entry()
    return (e and e.def and e.def.id == "fire" and e.t) and e.t.d or nil
end
-- what the game holds for the campfire: the server's own object (fuel in minutes, lit)
function H.srv()
    local so = nil
    pcall(function() so = SCampfireSystem.instance:getLuaObjectOnSquare(S.cfSq) end)
    return so
end
function H.game()
    local so = H.srv()
    if not so then return nil, nil end
    return so.fuelAmt or 0, so.isLit == true
end
function H.fuelFid(ft)
    local d = H.fireD()
    for i, r in ipairs((d and d.fuelRows) or {}) do
        if r.fullType == ft then return "fire:fuel:" .. i, r end
    end
    return nil
end
function H.lightFid(ft)
    local d = H.fireD()
    for i, r in ipairs((d and d.lightRows) or {}) do
        if r.method == "tinder" and r.tinderType == ft and r.enabled ~= false then return "fire:light:" .. i, r end
    end
    return nil
end
function H.plankReady()
    local fid = H.fuelFid("Base.Plank")
    local z = fid and H.zoneFid(fid)
    return z ~= nil and z.run ~= nil
end
function H.addPlank(what)
    local fid = H.fuelFid("Base.Plank")
    return fid ~= nil and H.run(fid, what)
end
-- queue: the card (opened again if it closed) must read what the game holds
function H.qSync(label)
    Q.step(2, function()
        if not S.cfOk then return end
        if not H.fireD() then H.fireInfo() end
        local e = H.entry()
        if e and e.t then e.t._refreshT = 1000 end
    end)
    H.wait(4000, function()
        if not S.cfOk then return true end
        local d = H.fireD()
        local fuel, lit = H.game()
        return d ~= nil and fuel ~= nil and math.abs(d.fuel - fuel) <= 3 and d.lit == lit
    end, function(ok)
        if not S.cfOk then return end
        local d = H.fireD()
        local fuel, lit = H.game()
        Q.check(ok, label .. ": the card reads what the game holds (fuel, lit)",
            "card " .. tostring(d and d.fuel) .. " " .. tostring(d and d.lit) .. ", game " .. tostring(fuel) .. " " .. tostring(lit))
        if d then
            local pill = H.pill(H.entry())
            Q.check((pill == ZeD.tr("UI_ZeD_Fire_PillOut")) == (not d.lit), label .. ": the card's state word agrees (Out only when not lit)", tostring(pill))
        end
    end)
end
function H.qIdle(ms, label)
    H.wait(ms, function() return (not S.cfOk) or H.qn() == 0 end, function(ok)
        if not S.cfOk then return end
        if not ok then
            Q.check(false, label .. ": the game's actions finish", H.qn() .. " still queued")
            H.stopActions()
        end
    end)
end

-- ===================================================================== helpers: health
function H.bp() return S.p:getBodyDamage():getBodyPart(BodyPartType.ForeArm_L) end
function H.keepUp() pcall(function() S.p:getBodyDamage():setOverallBodyHealth(100) end) end
function H.hasBurn(data)
    local burn = ZeD.tr("UI_ZeD_Health_Burn")
    for _, c in ipairs((data and data.condsByFigureName and data.condsByFigureName[S.FIG]) or {}) do
        if tostring(c.label):find(burn, 1, true) then return true end
    end
    return false
end
function H.model() local ok, d = pcall(HT.gatherData, S.p); return ok and d or nil end
function H.cache() local w = RT.cw(); return w and w._healthCache end
function H.menu() return getPlayerContextMenu(S.pn) end
function H.menuNames()
    local t = {}
    local m = H.menu()
    for _, o in ipairs((m and m.options) or {}) do t[#t + 1] = tostring(o.name) end
    return t
end
function H.hideMenu() local m = H.menu(); if m then pcall(function() m:hideAndChildren() end) end end
function H.fire1(o) return pcall(o.onSelect, o.target, o.param1, o.param2, o.param3, o.param4, o.param5, o.param6) end
-- a menu entry picked by its words (its first live sub entry when it opens a sub menu)
function H.pick(text)
    local m = H.menu()
    for _, o in ipairs((m and m.options) or {}) do
        if tostring(o.name) == text then
            if o.onSelect then return H.fire1(o) end
            local sm = nil
            pcall(function() sm = m:getSubMenu(o.subOption) end)
            for _, so in ipairs((sm and sm.options) or {}) do
                if so.onSelect and not so.notAvailable then return H.fire1(so) end
            end
            return false, "the sub menu has no live entry"
        end
    end
    return false, "no such entry"
end
function H.partClick()
    H.hideMenu()
    local ok = H.try("ZeD's click on the forearm (HealthTab._onPartClicked)", HT._onPartClicked, RT.cw(), S.FIG, nil, 10, 10)
    return ok
end
-- (each call its own pcall: one wrong call must not stop the rest. The part's and the body's RestoreToFullHealth, no
-- arguments, are what heal; the setters before them are a second belt.)
function H.healPart(bp)
    pcall(function() bp:setBurnTime(0) end)
    pcall(function() bp:setNeedBurnWash(false) end)
    pcall(function() bp:setBandaged(false, 0) end)
    pcall(function() bp:setAdditionalPain(0) end)
    pcall(function() bp:setFractureTime(0) end)
    pcall(function() bp:SetBitten(false) end)
    pcall(function() bp:SetInfected(false) end)
    pcall(function() bp:setInfectedWound(false) end)
    pcall(function() bp:RestoreToFullHealth() end)
    pcall(function() bp:SetHealth(100) end)
end
-- NOTE the body's full heal also resets every stat (hunger, thirst...): the put-back sets the stats as found after it
function H.healAll()
    pcall(function() S.p:StopBurning() end)
    pcall(function()
        local parts = S.p:getBodyDamage():getBodyParts()
        for i = 0, parts:size() - 1 do H.healPart(parts:get(i)) end
    end)
    pcall(function() S.p:getBodyDamage():RestoreToFullHealth() end)
    pcall(function() S.p:getBodyDamage():setInfected(false) end)
    pcall(function() S.p:getBodyDamage():setIsFakeInfected(false) end)
    pcall(function() S.p:getBodyDamage():setInfectionTime(-1) end)
    pcall(function() S.p:getStats():set(CharacterStat.ZOMBIE_INFECTION, 0) end)
end
-- is the body whole? true, or false and what is wrong (alive, not burning, health, every part's wounds, infection)
function H.bodyClean()
    if not H.alive() then return false, "DEAD" end
    local bad = {}
    local okAll = pcall(function()
        local bd = S.p:getBodyDamage()
        local h = bd:getOverallBodyHealth()
        if h < 99 then bad[#bad + 1] = string.format("health %.1f", h) end
        if bd:isInfected() then bad[#bad + 1] = "infected" end
        if S.p:isOnFire() then bad[#bad + 1] = "burning" end
        local parts = bd:getBodyParts()
        for i = 0, parts:size() - 1 do
            local b = parts:get(i)
            local w = {}
            if b:getFractureTime() > 0 then w[#w + 1] = "fracture" end
            if b:bitten() then w[#w + 1] = "bite" end
            if b:scratched() then w[#w + 1] = "scratch" end
            if b:isCut() then w[#w + 1] = "cut" end
            if b:deepWounded() then w[#w + 1] = "deep wound" end
            if b:bleeding() then w[#w + 1] = "bleeding" end
            if b:haveBullet() then w[#w + 1] = "bullet" end
            if b:haveGlass() then w[#w + 1] = "glass" end
            if b:getBurnTime() > 0 then w[#w + 1] = "burn" end
            if b:isInfectedWound() then w[#w + 1] = "infected wound" end
            if b:IsInfected() then w[#w + 1] = "infection" end
            if b:bandaged() then w[#w + 1] = "bandage" end
            if b:getHealth() < 99 then w[#w + 1] = string.format("health %.1f", b:getHealth()) end
            if #w > 0 then bad[#bad + 1] = tostring(b:getType()) .. ": " .. table.concat(w, "+") end
        end
    end)
    if not okAll then bad[#bad + 1] = "the body could not be read" end
    if #bad > 0 then return false, table.concat(bad, "; ") end
    return true, "health 100, no wound, no fracture, not infected"
end
-- stop the run and go to the put-back (the step queue's own jump; safe from inside a step and from the guard)
function H.bail(why)
    if S.bailed then return end
    S.bailed = true
    Q.check(false, "the run went on to its end", "stopped, on to the put-back: " .. tostring(why))
    if Q.backAt and Q.qi < Q.backAt then Q.qi = Q.backAt; Q.wait = nil end
end
-- the burn scenes are over (or cannot go on): the body healed, god mode back ON
function H.burnEnd()
    H.stopActions()
    H.healAll()
    S.godOff = false
    pcall(function() S.p:setGodMod(true) end)
end
-- what, other than the staged burn on the left forearm, is wrong with the body (nil: nothing)
function H.strayHurt()
    local p = S.p
    local bd = p:getBodyDamage()
    if p:isOnFire() then return "the character caught fire" end
    if bd:isInfected() then return "infected" end
    local h = bd:getOverallBodyHealth()
    if h < 35 then return "health fell to " .. string.format("%.1f", h) end
    local parts = bd:getBodyParts()
    for i = 0, parts:size() - 1 do
        local b = parts:get(i)
        if b:bitten() or b:scratched() or b:isCut() or b:deepWounded() or b:bleeding() or b:getFractureTime() > 0
            or b:haveBullet() or b:haveGlass() then
            return "a wound the script did not stage on " .. tostring(b:getType())
        end
        if b:getBurnTime() > 0 and b:getType() ~= BodyPartType.ForeArm_L then return "a burn on " .. tostring(b:getType()) end
    end
    return nil
end
-- living zombies within r tiles of the character (the QA save has zombies off, so any one is a stray)
function H.zombiesNear(r)
    local n = 0
    pcall(function()
        local l = getCell():getZombieList()
        local px, py = S.p:getX(), S.p:getY()
        for i = 0, l:size() - 1 do
            local z = l:get(i)
            if z and not z:isDead() and math.abs(z:getX() - px) <= r and math.abs(z:getY() - py) <= r then n = n + 1 end
        end
    end)
    return n
end
-- fire kept to the squares the script lit: any other square with fire within 9 tiles of the fire is put out
-- (the campfire's square is left alone only while the campfire stands: once it is gone, fire there is a stray too)
function H.contain()
    local n, cell = 0, getCell()
    local fx, fy = S.fSq:getX(), S.fSq:getY()
    local m1, m2 = S.fMore and S.fMore[1], S.fMore and S.fMore[2]
    local cf = (S.cfSq and H.campLua(S.cfSq)) and S.cfSq or nil
    for dx = -9, 9 do
        for dy = -9, 9 do
            local sq = cell:getGridSquare(fx + dx, fy + dy, 0)
            if sq and sq ~= S.fSq and sq ~= m1 and sq ~= m2 and sq ~= cf and H.hot(sq) then
                H.douse(sq)
                n = n + 1
            end
        end
    end
    return n
end
-- THE GUARD, on every game tick from the first step to the end of the put-back (see SAFETY at the top)
function H.safety()
    if not S.live then return end
    local ok, err = pcall(function()
        local p = S.p
        if p:isDead() then
            if not S.deadSaid then
                S.deadSaid = true
                Q.check(false, "the character is alive", "DEAD during the run: restore the QA save from its backup")
                H.bail("the character died")
            end
            return
        end
        if S.godOff then
            -- the burn scenes: only the staged burn may be on the body, and his health stays up
            local bd = p:getBodyDamage()
            if bd:getOverallBodyHealth() < 75 then
                local parts = bd:getBodyParts()
                for i = 0, parts:size() - 1 do parts:get(i):SetHealth(100) end
                S.topUps = (S.topUps or 0) + 1
            end
            local why = H.strayHurt()
            -- (zombies are the one harm a tick-late guard cannot undo: several at once drag him down in one blow, and
            -- only god mode stops that. Any zombie within 12 tiles ends the burn scenes; looked for every 10 ticks.)
            S.zT = (S.zT or 0) + 1
            if not why and S.zT >= 10 then
                S.zT = 0
                local nz = H.zombiesNear(12)
                if nz > 0 then why = nz .. " zombie(s) within 12 tiles" end
            end
            if why then
                S.godOff = false
                p:setGodMod(true)
                H.healAll()
                S.hSkip = true
                H.bail(why .. " in the burn scenes: god mode ON, healed")
            end
        elseif not p:isGodMod() then
            p:setGodMod(true)
            S.regod = (S.regod or 0) + 1
            -- (outside -debug the game may refuse: setGodMod then leaves it OFF. Nothing that can hurt him goes on.)
            if not p:isGodMod() then H.bail("god mode went off and could not be put back on") end
        end
        if S.fSq and not S.fireDone then
            S.keepT = (S.keepT or 0) + 1
            if S.keepT >= 20 then
                S.keepT = 0
                S.strays = (S.strays or 0) + H.contain()
            end
        end
        -- the queue never came to the end of the put-back: heal here
        if getTimestampMs() - Q.t0 > Q.maxMs + 60000 then
            S.live = false
            S.godOff = false
            H.healAll()
            p:setGodMod(true)
            p:setInvincible(true)
            Q.say("ERR the put-back did not finish in time: the guard healed the character and left god mode ON")
            Events.OnTick.Remove(H.safety)
            pcall(H.scan, 15, true)
            H.spyOff()
            -- (the put-back's own proof never ran: the same PASS or FAIL line here)
            local healed, state = H.bodyClean()
            Q.check(healed, "put back (by the guard, the queue never got there): the character is alive and healed", state)
        end
    end)
    if not ok and not S.guardErrSaid then
        S.guardErrSaid = true
        Q.say("ERR the guard threw: " .. tostring(err))
        S.godOff = false
        pcall(function() S.p:setGodMod(true) end)
        H.bail("the guard threw, god mode ON")
    end
end
function H.burnsLeft()
    local n = 0
    pcall(function()
        local parts = S.p:getBodyDamage():getBodyParts()
        for i = 0, parts:size() - 1 do
            local bp = parts:get(i)
            if bp:getBurnTime() > 0 or bp:bandaged() then n = n + 1 end
        end
    end)
    return n
end
function H.statsSnap()
    for _, name in ipairs(S.STATS) do
        pcall(function()
            local cs = CharacterStat[name]
            if cs then S.stats[name] = S.p:getStats():get(cs) end
        end)
    end
end
function H.statsBack()
    for name, v in pairs(S.stats) do
        pcall(function() S.p:getStats():set(CharacterStat[name], v) end)
    end
end
function H.wornSnap()
    pcall(function()
        local worn = S.p:getWornItems()
        for i = 0, worn:size() - 1 do
            local it = worn:get(i):getItem()
            S.worn[#S.worn + 1] = { it = it, c = it:getCondition() }
        end
    end)
end
function H.wornBack()
    local changed = 0
    for _, w in ipairs(S.worn) do
        pcall(function()
            if w.it:getCondition() ~= w.c then changed = changed + 1; w.it:setCondition(w.c) end
        end)
    end
    local n = -1
    pcall(function() n = S.p:getWornItems():size() end)
    return changed, n
end

-- ===================================================================== helpers: both windows' tabs, one by one
function H.tabPlan()
    local out = {}
    for _, id in ipairs(RT.tabs(RT.worldStrip())) do out[#out + 1] = { fn = RT.worldTab, id = id } end
    for _, id in ipairs(RT.tabs(RT.charStrip())) do out[#out + 1] = { fn = RT.charTab, id = id } end
    return out
end
function H.qCycle(label, skipKey)
    local st = { i = 0, f = 0, n = 0 }
    Q.waitFor(2, 100000, function()
        if S[skipKey] then return true end
        st.list = st.list or H.tabPlan()
        st.f = st.f + 1
        if st.f < 6 then return false end
        st.f, st.i = 0, st.i + 1
        local t = st.list[st.i]
        if not t then return true end
        local ok, err = pcall(t.fn, t.id)
        if ok then st.n = st.n + 1 else st.err = tostring(t.id) .. ": " .. tostring(err) end
        return false
    end, function()
        if S[skipKey] then return end
        Q.check(st.err == nil and st.n > 0, label .. ": every tab of both windows opened in turn", st.err or (st.n .. " tabs"))
        RT.worldTab("loot")
        RT.charTab("loot")
        local cw, ww = RT.cw(), RT.ww()
        Q.check(cw ~= nil and ww ~= nil and RT.isOpen(), label .. ": both windows are still open after it")
        RT.bounds(Q, label .. ", after the tabs")
    end)
end

-- ===================================================================== helpers: the game's extinguish cursor
-- the player's path: the menu's handler raises the cursor, the cursor's own create (a click on the square) equips
-- the thing and queues the game's ISPutOutFire on the 2 x 2 squares from (x, y)
function H.extinguish(item, x, y, label)
    local flame = H.flame(getCell():getGridSquare(x, y, 0)) or H.flame(S.fSq)
    local ok = pcall(ISWorldObjectContextMenu.onRemoveFire, nil, flame, item, S.p)
    local cur = nil
    pcall(function() cur = getCell():getDrag(S.pn) end)
    if not (ok and cur and cur.create) then
        pcall(function() cur = ISExtinguishCursor:new(S.p, item) end)
        Q.say(label .. ": the menu's handler raised no cursor (" .. tostring(ok) .. "); the cursor made directly")
    end
    if not (cur and cur.create) then return false end
    RT.bounds(Q, label .. ", the extinguish cursor up")
    local ok2, err = pcall(cur.create, cur, x, y, 0, false, nil)
    pcall(function() getCell():setDrag(nil, S.pn) end)
    if not ok2 then Q.say(label .. ": the game's cursor did not start the action: " .. tostring(err)) end
    return ok2
end
function H.standBy(f)
    for _, o in ipairs({ { -1, 0 }, { 0, -1 } }) do
        local sq = getCell():getGridSquare(f:getX() + o[1], f:getY() + o[2], 0)
        local free = false
        pcall(function() free = sq ~= nil and sq:isFree(false) and not H.burning(sq) end)
        if free then return sq end
    end
    return nil
end
-- an outcome that is the game's alone (nothing of ZeD's in it): PASS when it happened, else a SKIP said plainly
function H.gameDid(ok, what, detail)
    if ok then return Q.check(true, what, detail) end
    Q.skip(what, "the game did not do it: " .. tostring(detail))
    return false
end
-- the character must never die of the fire: below 60 the fire is taken off and the body restored
function H.fireGuard()
    pcall(function()
        local bd = S.p:getBodyDamage()
        if bd:getOverallBodyHealth() < 60 then
            S.p:StopBurning()
            bd:RestoreToFullHealth()
            S.guarded = true
        end
    end)
end
function H.reignite()
    if not H.burning(S.fSq) then
        H.startFire(S.fSq)
        S.restarts = (S.restarts or 0) + 1
    end
end

-- ===================================================================== 0. as found
Q.step(5, function()
    -- SAFETY first, before anything can throw: as found read, then god mode and invincible ON, the guard on every tick
    pcall(function() S.was.god = S.p:isGodMod() end)
    pcall(function() S.was.inv = S.p:isInvincible() end)
    pcall(function() S.p:setGodMod(true) end)
    pcall(function() S.p:setInvincible(true) end)
    S.live = true
    Events.OnTick.Add(H.safety)
    local godOn = false
    pcall(function() godOn = S.p:isGodMod() end)
    Q.check(godOn, "god mode is ON for the campfire and the fire scenes (invincible too)", "was " .. tostring(S.was.god))
    if ZEDQA_HOME then ZEDQA_HOME("bx_fire") else Q.say("NOTE the prelude did not run (no ZEDQA_HOME): the character stays where it stands") end
    S.hx, S.hy = math.floor(S.p:getX()), math.floor(S.p:getY())
    H.stopActions()
    H.spyOn()
    H.invSnap()
    H.statsSnap()
    H.wornSnap()
    H.floorsSnap()
    local was = S.was
    pcall(function() was.hand1, was.hand2 = S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem() end)
    pcall(function() was.speed = getGameSpeed() end)
    was.open = RT.isOpen()
    S.pre = H.scan(15, false)
    local inst = nil
    pcall(function() inst = S.p:isTimedActionInstant() end)
    Q.say("as found: home " .. S.hx .. "," .. S.hy .. ", god mode " .. tostring(was.god) .. ", windows open " .. tostring(was.open)
        .. ", fire within 15 tiles " .. S.pre .. ", timed actions instant " .. tostring(inst))
    Q.check(H.alive(), "the character is alive at the start")
    if getGameSpeed() ~= 1 then setSpeed(1) end
    RT.pairOpen()
    -- (the game's setGodMod puts god mode OFF for a player without the right to it, outside -debug: then no fire is
    -- lit and no burn is set, straight to the put-back)
    if not godOn then H.bail("god mode could not be put on: no campfire, no fire, no burn") end
end)
H.wait(3000, function() return RT.isOpen() and RT.cw() ~= nil and RT.ww() ~= nil end, function(ok)
    Q.check(ok, "both ZeD windows open")
    local cw, ww = RT.cw(), RT.ww()
    S.was.ctab, S.was.wtab = cw and cw._activeTab, ww and ww._activeTab
    RT.worldTab("loot")
    RT.bounds(Q, "the start")
end)

-- ===================================================================== 1. the campfire
Q.step(5, function()
    local sq = H.freeSq(S.RING2)
    if not sq then Q.skip("the campfire scenes", "no free outdoor square two tiles from home"); return end
    local ok, err = pcall(function() SCampfireSystem.instance:addCampfire(sq) end)
    S.cfSq = sq
    if not ok then Q.skip("the campfire scenes", "the game's campfire system refused: " .. tostring(err)) end
end)
H.wait(8000, function()
    local lo = S.cfSq and H.campLua(S.cfSq)
    return S.cfSq == nil or (lo ~= nil and lo:getIsoObject() ~= nil)
end, function(ok)
    if not S.cfSq then return end
    S.cfOk = ok and H.srv() ~= nil
    if not S.cfOk then Q.skip("the campfire scenes", "the campfire never came into the world"); return end
    Q.check(ISCampingMenu._zed_onDisplayInfo == true, "campfire: ZeD's hook is on the campfire's Info")
    H.fireInfo()
end)
H.wait(4000, function() return (not S.cfOk) or H.fireD() ~= nil end, function(ok)
    if not S.cfOk then return end
    local e = H.entry()
    Q.check(ok and e ~= nil and e.t.kind == "campfire", "campfire: its Info opens ZeD's fire card", tostring(e and e.t and e.t.kind))
    local d = H.fireD()
    if not d then return end
    Q.check(d.fuel == 0 and d.lit == false, "campfire: new, it reads no fuel and not lit", tostring(d.fuel) .. " " .. tostring(d.lit))
    local out = H.verb("out")
    Q.check(out ~= nil and out.enabled == false and out.sensible == false, "campfire: a dead fire offers no Put out",
        tostring(out and out.enabled) .. " " .. tostring(out and out.sensible))
    local light = H.verb("light")
    local ways = 0
    for _, r in ipairs(d.lightRows) do if r.enabled ~= false then ways = ways + 1 end end
    Q.check(light ~= nil and (light.enabled == true) == (ways > 0), "campfire: Light is offered only with something to light it with",
        tostring(light and light.enabled) .. ", " .. ways .. " ways")
    -- Put out pressed anyway (a click that lands as the fire dies): nothing is queued
    local n0 = H.qn()
    if out then H.try("Put out pressed on a dead fire", H.ocard().press, H.ocard(), out) end
    Q.check(H.qn() == n0, "campfire: Put out pressed on a dead fire queues nothing", H.qn() .. " queued")
    RT.bounds(Q, "the campfire's card, new")
end)
H.qSync("campfire, new")

-- fuel given; Add started and stopped at once
Q.step(4, function()
    if not S.cfOk then return end
    S.planks = { H.give("Base.Plank"), H.give("Base.Plank"), H.give("Base.Plank"), H.give("Base.Plank") }
    S.paper = { H.give("Base.SheetPaper2"), H.give("Base.SheetPaper2"), H.give("Base.SheetPaper2") }
    S.matches = H.give("Base.Matches")
    setSpeed(2)
    local e = H.entry()
    if e and e.t then e.t._refreshT = 1000 end
end)
H.wait(5000, function() return (not S.cfOk) or H.plankReady() end, function(ok)
    if not S.cfOk then return end
    S.addArm = Q.check(ok, "campfire: with planks carried, the card lists them to add")
    if not S.addArm then return end
    local d = H.fireD()
    local info = ISCampingMenu.getNearbyFuelInfo(S.p)
    Q.check(#d.fuelRows == #(info.fuelList or {}), "campfire: the card lists as many kinds of fuel as the game finds", #d.fuelRows .. " vs " .. #(info.fuelList or {}))
    S.fuel0 = H.game()
    H.addPlank("Add fuel (a plank)")
end)
Q.step(6, function()
    if not S.addArm then return end
    Q.say("campfire: Add fuel stopped after six frames (" .. H.qn() .. " queued)")
    H.stopActions()
end)
Q.waitMs(800)
H.qSync("campfire, Add fuel stopped at once")

-- Add pressed three times in one frame
Q.step(2, function()
    if not S.addArm then return end
    S.fuel1 = H.game()
    local n = 0
    for _ = 1, 3 do if H.addPlank("Add fuel pressed three times in one frame") then n = n + 1 end end
    Q.say("campfire: Add fuel pressed " .. n .. " times in one frame, " .. H.qn() .. " queued")
end)
H.qIdle(30000, "campfire, Add fuel three times")
Q.step(2, function()
    if not S.addArm then return end
    local fuel = H.game()
    Q.check(fuel ~= nil and fuel > (S.fuel1 or 0), "campfire: Add fuel adds fuel time (the game's add fuel)", tostring(S.fuel1) .. " -> " .. tostring(fuel))
    Q.check(fuel ~= nil and fuel <= (getCampingFuelMax and getCampingFuelMax() or 100000) + 1, "campfire: three presses do not fill it past the game's maximum", tostring(fuel))
end)
H.qSync("campfire, Add fuel three times")

-- Add with the World window's tab switched away and back in the middle
Q.step(2, function()
    if not S.addArm then return end
    -- (the planks counted in the inventory, not read off the card: since beast W34 the card's fuel rows are up to
    -- 1.5 s old, so a row can still show for a plank that has just burnt)
    if H.count("Base.Plank") == 0 or not H.fuelFid("Base.Plank") then S.planks[#S.planks + 1] = H.give("Base.Plank") end
    pcall(function() H.srv():setFuel(60) end)   -- (an hour of fuel: room for the plank under the game's maximum)
end)
H.wait(3000, function() return (not S.addArm) or H.plankReady() end, function(ok)
    if not S.addArm then return end
    if not ok then Q.skip("campfire: Add fuel with the tab switched in the middle", "no plank row on the card"); return end
    S.fuel2 = H.game()
    H.addPlank("Add fuel before the tab switch")
end)
Q.step(5, function()
    if not S.addArm then return end
    local other = nil
    for _, id in ipairs(RT.tabs(RT.worldStrip())) do if other == nil and id ~= "loot" then other = id end end
    S.otherTab = other
    if other then H.try("the World window's tab switched in the middle of Add fuel", RT.worldTab, other) end
end)
Q.step(25, function()
    if not S.addArm then return end
    H.try("the World window back on Loot", RT.worldTab, "loot")
end)
H.qIdle(30000, "campfire, Add fuel over a tab switch")
Q.step(2, function()
    if not (S.addArm and S.fuel2) then return end
    local fuel = H.game()
    Q.check(fuel ~= nil and fuel > S.fuel2, "campfire: Add fuel still lands with the tab switched to " .. tostring(S.otherTab) .. " and back", tostring(S.fuel2) .. " -> " .. tostring(fuel))
    local ww = RT.ww()
    Q.check(ww ~= nil and ww._activeTab == "loot", "campfire: the World window is back on Loot", tostring(ww and ww._activeTab))
end)
H.qSync("campfire, after the tab switch")

-- full: the game's maximum
Q.step(2, function()
    if not S.cfOk then return end
    S.max = (getCampingFuelMax and getCampingFuelMax()) or 480
    S.fuelKeep = H.game()
    pcall(function() H.srv():setFuel(S.max) end)
end)
H.qSync("campfire, filled to the maximum")
Q.step(2, function()
    if not S.cfOk then return end
    local d = H.fireD()
    local v = H.verb("fuel")
    if not (d and v) then Q.check(false, "campfire: the card is open on the full fire"); return end
    Q.check(v.sensible == false, "campfire: a full fire offers no Add fuel", "fuel " .. tostring(d.fuel) .. " of " .. tostring(d.max))
    local fits = 0
    for _, r in ipairs(d.fuelRows) do if r.fits then fits = fits + 1 end end
    Q.check(fits == 0, "campfire: full, every fuel row reads full (none can be added)", fits .. " of " .. #d.fuelRows .. " still offered")
    RT.bounds(Q, "the campfire's card, full")
    pcall(function() H.srv():setFuel(math.min(S.fuelKeep or 120, 120)) end)
end)
H.qSync("campfire, back to two hours or less")

-- Light with paper
H.wait(5000, function() return (not S.cfOk) or H.lightFid("Base.SheetPaper2") ~= nil end, function(ok)
    if not S.cfOk then return end
    S.lightArm = Q.check(ok, "campfire: with matches and paper, the card offers Light with the paper")
    if S.lightArm then H.run(H.lightFid("Base.SheetPaper2"), "Light with paper") end
end)
H.wait(30000, function() local _, lit = H.game(); return (not S.lightArm) or lit == true end, function(ok)
    if not S.lightArm then return end
    S.lit = Q.check(ok, "campfire: Light lights it (the game's light)")
    H.stopActions()
end)
H.qSync("campfire, lit")
Q.step(2, function()
    if not S.lit then return end
    local light, out = H.verb("light"), H.verb("out")
    Q.check(light ~= nil and light.sensible == false, "campfire: burning, Light is gone")
    Q.check(out ~= nil and out.enabled == true, "campfire: burning, Put out is offered")
    local flame = nil
    pcall(function()
        local objs = S.cfSq:getObjects()
        for i = 0, objs:size() - 1 do if flame == nil and instanceof(objs:get(i), "IsoFire") then flame = objs:get(i) end end
    end)
    if flame == nil then Q.skip("campfire: the lit fire's flame asked for a window", "no IsoFire on its square"); return end
    local ok, r = pcall(ISEntityUI.CanOpenWindowFor, S.p, flame)
    Q.check(ok and r == false, "campfire: the game's window check on the flame answers no, with no error", tostring(ok) .. " " .. tostring(r))
end)

-- lit: Add with both windows shut and opened again in the middle
Q.step(2, function()
    if not S.lit then return end
    if H.count("Base.Plank") == 0 or not H.fuelFid("Base.Plank") then S.planks[#S.planks + 1] = H.give("Base.Plank") end
    pcall(function() H.srv():setFuel(60) end)   -- (an hour of fuel: room for the plank under the game's maximum)
    local e = H.entry()
    if e and e.t then e.t._refreshT = 1000 end
end)
H.wait(3000, function() return (not S.lit) or H.plankReady() end, function(ok)
    if not S.lit then return end
    if not ok then Q.skip("campfire: Add fuel with the windows shut in the middle", "no plank row on the card"); return end
    S.fuel3 = H.game()
    H.addPlank("Add fuel on the lit fire")
end)
Q.step(5, function()
    if not S.lit then return end
    H.try("both windows shut in the middle of Add fuel", RT.pairShut)
end)
Q.step(30, function()
    if not S.lit then return end
    H.try("both windows opened again", RT.pairOpen)
end)
H.qIdle(30000, "campfire, Add fuel over a close and reopen")
H.wait(3000, function() return (not S.lit) or (RT.isOpen() and RT.ww() ~= nil) end, function(ok)
    if not S.lit then return end
    Q.check(ok, "campfire: both windows are open again after the close and reopen")
    if S.fuel3 then
        local fuel = H.game()
        Q.check(fuel ~= nil and fuel > S.fuel3, "campfire: the lit fire took the plank with the windows shut", tostring(S.fuel3) .. " -> " .. tostring(fuel))
    end
    RT.bounds(Q, "after the close and reopen")
end)
H.qSync("campfire, lit, after the close and reopen")

-- the leash: ten tiles away the card closes; back, it opens again on the same fire
Q.step(2, function()
    if not S.cfOk then return end
    H.stopActions()
    if not H.fireD() then H.fireInfo() end
    local dx = (S.cfSq:getX() >= S.hx) and -10 or 10
    local far = H.sq(dx, 0)
    local free = false
    pcall(function() free = far ~= nil and far:isFree(false) and far:getVehicleContainer() == nil end)
    S.far = free and far or nil
end)
H.wait(2000, function() return (not S.cfOk) or S.far == nil or H.fireD() ~= nil end, function(ok)
    if not S.cfOk then return end
    if not S.far then Q.skip("campfire: the card's leash", "the square ten tiles along the strip is not free"); return end
    if not ok then Q.skip("campfire: the card's leash", "the card was not open to begin with"); S.far = nil; return end
    H.placeOn(S.far)
end)
H.wait(4000, function() return (not S.cfOk) or S.far == nil or H.ocard() == nil end, function(ok)
    if not (S.cfOk and S.far) then return end
    Q.check(ok, "campfire: ten tiles away, the card closes (its leash)", tostring(OC.closeWhy))
    Q.check(RT.ww() ~= nil and RT.isOpen(), "campfire: the World window itself stays open")
    H.goHome()
end)
Q.waitMs(400)
H.qSync("campfire, back from ten tiles away")

-- Put out, pressed twice in one frame
Q.step(2, function()
    if not S.lit then return end
    local a = H.run("oc:verb:out", "Put out")
    local b = H.run("oc:verb:out", "Put out, a second press in the same frame")
    S.outArm = Q.check(a, "campfire: the card's Put out can be pressed (oc:verb:out)", tostring(a) .. " " .. tostring(b))
end)
H.wait(25000, function() local _, lit = H.game(); return (not S.outArm) or lit == false end, function(ok)
    if not S.outArm then return end
    Q.check(ok, "campfire: Put out puts it out (the game's put-out action)")
end)
H.qIdle(8000, "campfire, Put out twice")
H.qSync("campfire, put out")

-- Take apart: asked and cancelled, then asked and confirmed; the fire goes while its card shows
Q.step(2, function()
    if not S.cfOk then return end
    setSpeed(1)
    if not H.fireD() then H.fireInfo() end
end)
H.wait(3000, function() return (not S.cfOk) or H.zoneFid("oc:verb:take") ~= nil end, function(ok)
    if not S.cfOk then return end
    S.takeArm = Q.check(ok, "campfire: the card offers Take apart")
    if S.takeArm then H.run("oc:verb:take", "Take apart") end
end)
H.wait(3000, function() return (not S.takeArm) or H.zoneFid("oc:confirm:no") ~= nil end, function(ok)
    if not S.takeArm then return end
    local c = H.ocard()
    Q.check(ok and c ~= nil and c._confirm ~= nil, "campfire: Take apart asks first (a question at the card's foot)")
    Q.check(H.qn() == 0, "campfire: nothing is queued while it asks", H.qn() .. " queued")
    RT.bounds(Q, "the campfire's card, asking")
    H.run("oc:confirm:no", "the question's Cancel")
    Q.check(c ~= nil and c._confirm == nil and H.campLua(S.cfSq) ~= nil, "campfire: Cancel drops the question and the campfire stays")
end)
Q.step(4, function()
    if not S.takeArm then return end
    H.run("oc:verb:take", "Take apart, again")
end)
H.wait(3000, function() return (not S.takeArm) or H.zoneFid("oc:confirm:yes") ~= nil end, function(ok)
    if not S.takeArm then return end
    if not ok then Q.check(false, "campfire: the question shows a second time"); S.takeArm = false; return end
    H.run("oc:confirm:yes", "the question's Take apart")
end)
H.wait(20000, function() return (not S.takeArm) or H.campLua(S.cfSq) == nil end, function(ok)
    if not S.takeArm then return end
    S.taken = Q.check(ok, "campfire: confirmed, the game takes the campfire apart")
end)
H.wait(3000, function() return (not S.taken) or H.ocard() == nil end, function(ok)
    if not S.taken then return end
    Q.check(ok, "campfire: its card closes when the campfire is gone (nothing stale)", tostring(OC.closeWhy))
    Q.check(RT.ww() ~= nil and RT.isOpen(), "campfire: the World window stays open after its card's fire went")
    RT.bounds(Q, "after the campfire went")
end)
Q.step(2, function()
    setSpeed(1)
    H.stopActions()
    H.closeCard()
end)

-- ===================================================================== 2. a fire on a square
Q.step(4, function()
    H.goHome()
    local sq = H.freeSq(S.FIRE)
    if not sq then S.wSkip = true; Q.skip("the world fire scenes", "no free outdoor square four tiles from home"); return end
    S.fSq = sq
    RT.worldTab("loot")
    local ok, err = H.startFire(sq)
    if not ok then S.wSkip = true; Q.skip("the world fire scenes", "the game's StartFire refused: " .. tostring(err)) end
end)
H.wait(5000, function() return S.wSkip or H.burning(S.fSq) end, function(ok)
    if S.wSkip then return end
    if not ok then S.wSkip = true; Q.skip("the world fire scenes", "the square did not catch fire on the asphalt"); return end
    Q.say("fire: burning at " .. S.fSq:getX() .. "," .. S.fSq:getY())
    local flame = H.flame(S.fSq)
    S.oldFlame = flame
    if flame then
        local ok1, r = pcall(ISEntityUI.CanOpenWindowFor, S.p, flame)
        Q.check(ok1 and r == false, "fire: the game's window check on a flame four tiles away answers no, with no error", tostring(ok1) .. " " .. tostring(r))
        local ok2, opened = H.try("ZeD's fire card asked to open on a plain flame", OC.open, S.p, "fire", flame)
        Q.check(ok2 and opened == false and H.ocard() == nil, "fire: ZeD's fire card does not open on a plain flame", tostring(opened))
        H.closeCard()
    else
        Q.skip("fire: the flame asked for a window and a card", "no IsoFire object on the burning square")
    end
    local ok3, list = H.try("the fire card's list of fires in reach, beside a burning square", OC.kinds.fire.nearby, S.p)
    local onIt = 0
    for _, t in ipairs((ok3 and list) or {}) do if t.sq == S.fSq then onIt = onIt + 1 end end
    Q.check(ok3 and onIt == 0, "fire: a burning square is not listed as a fire to tend", onIt .. " listed")
    RT.bounds(Q, "a fire burning four tiles away")
end)
H.qCycle("fire burning", "wSkip")
-- more fire beside it, and the fire's reach counted
Q.step(4, function()
    if S.wSkip then return end
    H.reignite()
    S.fMore = {}
    for _, o in ipairs({ { 1, 0 }, { 0, 1 } }) do
        local sq = getCell():getGridSquare(S.fSq:getX() + o[1], S.fSq:getY() + o[2], 0)
        local free = false
        pcall(function() free = sq ~= nil and sq:isFree(false) and sq:getVehicleContainer() == nil end)
        if free then H.startFire(sq); S.fMore[#S.fMore + 1] = sq end
    end
end)
Q.waitMs(2500)
Q.step(2, function()
    if S.wSkip then return end
    local n = H.scan(8, false)
    Q.say("fire: " .. n .. " squares with fire within 8 tiles after 2.5 s (three were lit; more means the fire spread on its own; "
        .. tostring(S.strays or 0) .. " squares it spread to were put out by the guard so far)")
    Q.check(n >= 1, "fire: it still burns while ZeD's windows are open", n .. " squares")
    Q.check(RT.cw() ~= nil and RT.ww() ~= nil and RT.isOpen(), "fire: both windows are open beside the burning squares")
    S.ext = H.give("Base.Extinguisher")
end)

-- the extinguisher, its card open
H.qCard("ext", "extCard", "extinguisher")
Q.step(4, function()
    if S.wSkip then return end
    if not (S.ext and FireFighting.isExtinguisher(S.ext)) then S.extSkip = true; Q.skip("fire: put out with an extinguisher", "the game gave no usable Base.Extinguisher"); return end
    H.reignite()
    local stand = H.standBy(S.fSq)
    if stand then H.placeOn(stand) end
    S.uses0 = H.uses(S.ext)
    S.hot0 = 0
    for _, sq in ipairs({ S.fSq, S.fMore[1], S.fMore[2] }) do if H.burning(sq) then S.hot0 = S.hot0 + 1 end end
    S.extGo = H.extinguish(S.ext, S.fSq:getX(), S.fSq:getY(), "extinguisher")
    if not S.extGo then S.extSkip = true; Q.skip("fire: put out with an extinguisher", "the game's extinguish cursor could not be driven") end
end)
-- (the game's ISPutOutFire stops after the first square an extinguisher or a bag puts out: only water goes on to the
-- next square. So the first square, the fire's own, is the one that must be out.)
H.wait(20000, function()
    return S.wSkip or S.extSkip or (H.qn() == 0 and not H.burning(S.fSq))
end, function(ok)
    if S.wSkip or S.extSkip then return end
    local used = S.uses0 - H.uses(S.ext)
    local still = 0
    for _, sq in ipairs(S.fMore) do if H.burning(sq) then still = still + 1 end end
    H.gameDid(ok and (used >= 1 or S.hot0 == 0), "fire: the extinguisher puts the fire's square out (the game's cursor and ISPutOutFire)",
        S.hot0 .. " were burning, " .. used .. " uses spent, " .. still .. " beside it still burning, queue " .. H.qn())
    if S.extCard then
        Q.check(H.cardOn(S.ext) or not H.has(S.ext), "fire: the extinguisher's card stays on the extinguisher through its use")
    end
    Q.say("fire: the extinguisher in the hand after the game's equip: " .. tostring(S.p:getPrimaryHandItem() == S.ext))
    Q.check(RT.cw() ~= nil and RT.ww() ~= nil and RT.isOpen(), "fire: both windows are open after the extinguisher")
    RT.bounds(Q, "after the extinguisher")
    if S.oldFlame then
        local ok2, opened = H.try("ZeD's fire card asked to open on a flame that is gone", OC.open, S.p, "fire", S.oldFlame)
        Q.check(ok2 and opened == false, "fire: a flame that was put out opens no card", tostring(opened))
    end
    H.stopActions()
end)

-- a dirt bag on its last use: used up while its card shows
Q.step(4, function()
    if S.wSkip then return end
    S.bag = H.give("Base.Dirtbag")
    if not S.bag then return end
    pcall(function() S.bag:setCurrentUses(1) end)
    if H.uses(S.bag) ~= 1 then pcall(function() S.bag:setUsedDelta(S.bag:getUseDelta()) end) end
    Q.say("dirt bag: " .. H.uses(S.bag) .. " use left")
end)
H.qCard("bag", "bagCard", "dirt bag")
Q.step(4, function()
    if S.wSkip then return end
    if not (S.bag and FireFighting.isExtinguisher(S.bag)) then S.bagSkip = true; Q.skip("fire: put out with a dirt bag", "the game gave no usable Base.Dirtbag"); return end
    for _, sq in ipairs(S.fMore) do H.douse(sq) end
    H.reignite()
    local stand = H.standBy(S.fSq)
    if stand then H.placeOn(stand) end
    S.bagUses0 = H.uses(S.bag)
    S.bagGo = H.extinguish(S.bag, S.fSq:getX(), S.fSq:getY(), "dirt bag")
    if not S.bagGo then S.bagSkip = true; Q.skip("fire: put out with a dirt bag", "the game's extinguish cursor could not be driven") end
end)
H.wait(20000, function() return S.wSkip or S.bagSkip or (H.qn() == 0 and not H.burning(S.fSq)) end, function(ok)
    if S.wSkip or S.bagSkip then return end
    H.gameDid(ok, "fire: the dirt bag puts the square out (the game's cursor and ISPutOutFire)", "queue " .. H.qn() .. ", burning " .. tostring(H.burning(S.fSq)))
    S.bagGone = not H.has(S.bag)
    Q.say("dirt bag: had " .. tostring(S.bagUses0) .. " use, in the inventory now: " .. tostring(not S.bagGone))
end)
H.wait(3000, function() return S.wSkip or S.bagSkip or not (S.bagGone and H.cardOn(S.bag)) end, function(ok)
    if S.wSkip or S.bagSkip then return end
    if not S.bagGone then Q.skip("fire: no card stays on a used-up dirt bag", "the bag was not used up (the fire may have died first)"); return end
    if not S.bagCard then Q.skip("fire: no card stays on a used-up dirt bag", "its card was not open when it was used"); return end
    local w = RT.cw()
    Q.check(ok, "fire: the Character window's card does not stay on a dirt bag that was used up", tostring(w and w._drawerItem))
    Q.check(H.rowZone(S.bag) == nil, "fire: the list has no row left for the used-up dirt bag")
    RT.bounds(Q, "after the dirt bag was used up")
end)

-- water, with the character alight (god mode on): the Health tab open
Q.step(4, function()
    if S.wSkip then return end
    H.stopActions()
    RT.charTab("health")
    S.bucket = H.give("Base.Bucket")
    pcall(function()
        local fc = S.bucket:getFluidContainer()
        fc:Empty()
        fc:addFluid(Fluid.Water, fc:getCapacity())
    end)
    if not (S.bucket and FireFighting.isExtinguisher(S.bucket)) then S.watSkip = true; Q.skip("fire: put out with water", "a Base.Bucket filled with water is not a fire-fighting item for the game"); return end
    H.reignite()
    S.stand = H.standBy(S.fSq)
    if S.stand then H.placeOn(S.stand) end
    S.water0 = FireFighting.getWaterUsesInteger(S.bucket)
    local god = false
    pcall(function() god = S.p:isGodMod() end)
    if god and H.alive() then pcall(function() S.p:SetOnFire() end) else Q.skip("fire: the character set alight", "god mode is off: not safe to burn the character") end
end)
H.wait(700, function() H.fireGuard(); return false end, function() end)
Q.step(2, function()
    if S.wSkip or S.watSkip then return end
    local on = false
    pcall(function() on = S.p:isOnFire() end)
    S.wasOnFire = on
    Q.say("fire: the character is burning: " .. tostring(on) .. " (god mode on; the game may refuse to light a god)")
    Q.check(H.alive(), "fire: the character is alive while burning under god mode")
    local ok, d = H.try("ZeD's Health data read while the character burns", HT.gatherData, S.p)
    Q.check(ok and type(d) == "table" and d.overall ~= nil, "fire: ZeD's Health tab reads the body while the character burns", tostring(d and d.overall))
    RT.bounds(Q, "the character burning, Health open")
    local x, y = math.floor(S.p:getX()), math.floor(S.p:getY())
    S.watGo = H.extinguish(S.bucket, x, y, "water")
    if not S.watGo then S.watSkip = true; Q.skip("fire: put out with water", "the game's extinguish cursor could not be driven") end
end)
H.wait(20000, function()
    H.fireGuard()
    if S.wSkip or S.watSkip then return true end
    return H.qn() == 0 and not S.p:isOnFire() and not H.burning(S.fSq)
end, function(ok)
    local stillOn = false
    pcall(function() stillOn = S.p:isOnFire() end)
    pcall(function() if stillOn then S.p:StopBurning() end end)
    if S.wSkip or S.watSkip then return end
    local now = FireFighting.getWaterUsesInteger(S.bucket)
    H.gameDid(ok and now < S.water0, "fire: water puts out the character and the square beside (the game's cursor and ISPutOutFire)",
        "was burning " .. tostring(S.wasOnFire) .. ", still burning " .. tostring(stillOn) .. ", square burning " .. tostring(H.burning(S.fSq))
        .. ", water " .. tostring(S.water0) .. " -> " .. tostring(now) .. " uses, queue " .. H.qn())
    Q.check(H.alive(), "fire: the character is alive after the fire")
    Q.check(not S.guarded, "fire: god mode kept the burning character's health up (the guard never had to step in)")
    Q.check(RT.cw() ~= nil and RT.ww() ~= nil and RT.isOpen(), "fire: both windows are open after the character burned")
    RT.bounds(Q, "after the water")
end)
Q.step(2, function()
    H.stopActions()
    pcall(function() getCell():setDrag(nil, S.pn) end)
    pcall(function() S.p:StopBurning() end)
    S.afterFire = H.scan(15, true)
    S.fireDone = true
    Q.say("fire: " .. S.afterFire .. " squares still had fire or smoke after the three ways; put out directly ("
        .. tostring(S.strays or 0) .. " squares the fire spread to were put out by the guard during the scenes)")
    -- the campfire, when Take apart did not take it: no fire of any kind may be left when god mode goes off
    pcall(function()
        local so = S.cfSq and SCampfireSystem.instance:getLuaObjectOnSquare(S.cfSq)
        if so then SCampfireSystem.instance:removeCampfire(so) end
    end)
    H.goHome()
end)

-- ===================================================================== 3. a burn, treated in the Health tab
Q.step(6, function()
    if not H.alive() then S.hSkip = true; Q.skip("the burn scenes", "the character is not alive"); return end
    -- god mode goes off for these scenes (it heals a wound at once): only with no fire left anywhere near and no
    -- zombie about
    local hot, onFire = H.scan(15, true), true
    pcall(function() onFire = S.p:isOnFire() end)
    local zeds = H.zombiesNear(20)
    if hot > 0 or onFire or zeds > 0 then
        S.hSkip = true
        Q.skip("the burn scenes", "god mode must go off for them and it was not safe (" .. hot .. " squares with fire, the character burning "
            .. tostring(onFire) .. ", " .. zeds .. " zombies within 20 tiles)")
        return
    end
    RT.pairOpen()
    RT.charTab("health")
    H.healAll()
    S.godOff = true
    pcall(function() S.p:setInvincible(true) end)
    pcall(function() S.p:setGodMod(false) end)
    S.band = { H.give("Base.Bandage"), H.give("Base.Bandage") }
    pcall(function()
        local bp = H.bp()
        bp:setBurnTime(50)
        bp:setNeedBurnWash(true)
        S.hGo = bp:getBurnTime() > 0
    end)
    setSpeed(2)
    if not S.hGo then S.hSkip = true; H.burnEnd(); Q.skip("the burn scenes", "the game did not keep the burn on the forearm") end
end)
H.wait(4000, function() H.keepUp(); return S.hSkip or H.hasBurn(H.cache()) end, function(ok)
    if S.hSkip then return end
    local w = RT.cw()
    Q.check(w ~= nil and w._activeTab == "health", "burn: the Character window is on Health", tostring(w and w._activeTab))
    Q.check(H.hasBurn(H.model()), "burn: ZeD's Health data names the burn on the left forearm")
    Q.check(ok, "burn: the open Health tab shows it within four seconds (its own data)")
    local d = H.model()
    Q.check(d ~= nil and d.woundedCount >= 1, "burn: the tab counts a wounded part", tostring(d and d.woundedCount))
    RT.bounds(Q, "Health with a burn")
    H.partClick()
end)
Q.step(4, function()
    if S.hSkip then return end
    local names = table.concat(H.menuNames(), ", ")
    S.cleanText, S.bandText = getText("ContextMenu_Clean_Burn"), getText("ContextMenu_Bandage")
    Q.check(names:find(S.cleanText, 1, true) ~= nil, "burn: the forearm's menu offers the game's Clean Burn", names)
    Q.check(names:find(S.bandText, 1, true) ~= nil, "burn: and the game's Bandage", names)
    local ok, err = H.pick(S.cleanText)
    H.hideMenu()
    S.cleanArm = Q.check(ok, "burn: Clean Burn picked from the menu", tostring(err))
end)
-- stopped at once
Q.step(8, function()
    if not S.cleanArm then return end
    Q.say("burn: Clean Burn stopped after eight frames (" .. H.qn() .. " queued, needs cleaning " .. tostring(H.bp():isNeedBurnWash()) .. ")")
    H.stopActions()
end)
Q.waitMs(600)
Q.step(2, function()
    if not S.cleanArm then return end
    H.keepUp()
    Q.check(H.hasBurn(H.model()) == (H.bp():getBurnTime() > 0 and not H.bp():bandaged()), "burn: after the stop, ZeD still agrees with the game about the burn")
    S.stillDirty = H.bp():isNeedBurnWash()
    if not S.stillDirty then Q.say("burn: the cleaning finished before the stop (instant actions)"); return end
    H.partClick()
end)
Q.step(4, function()
    if not (S.cleanArm and S.stillDirty) then return end
    local ok, err = H.pick(S.cleanText)
    H.hideMenu()
    Q.check(ok, "burn: Clean Burn picked a second time", tostring(err))
end)
-- the tab switched away and back in the middle
Q.step(10, function()
    if not (S.cleanArm and S.stillDirty) then return end
    H.try("the Character window's tab switched in the middle of the cleaning", RT.charTab, "loot")
end)
Q.step(25, function()
    if not (S.cleanArm and S.stillDirty) then return end
    H.try("the Character window back on Health", RT.charTab, "health")
end)
H.wait(30000, function() H.keepUp(); return (not S.cleanArm) or not H.bp():isNeedBurnWash() end, function(ok)
    if S.hSkip then return end
    if S.cleanArm then
        Q.check(ok, "burn: the game cleans the burn (ISCleanBurn, started from ZeD's Health tab)")
        H.stopActions()
        local w = RT.cw()
        Q.check(w ~= nil and w._activeTab == "health", "burn: the Character window is back on Health", tostring(w and w._activeTab))
        Q.check(H.hasBurn(H.model()), "burn: cleaned but not bandaged, the tab still lists the burn")
    end
    RT.charTab("health")
    H.partClick()
end)
Q.step(4, function()
    if S.hSkip then return end
    local names = table.concat(H.menuNames(), ", ")
    if S.cleanArm and not H.bp():isNeedBurnWash() then
        Q.check(names:find(S.cleanText, 1, true) == nil, "burn: cleaned, the menu no longer offers Clean Burn", names)
    end
    local ok, err = H.pick(S.bandText)
    H.hideMenu()
    S.bandArm = Q.check(ok, "burn: Bandage picked from the menu", tostring(err))
end)
H.wait(30000, function() H.keepUp(); return (not S.bandArm) or H.bp():bandaged() end, function(ok)
    if not S.bandArm then return end
    S.banded = Q.check(ok, "burn: the game bandages the forearm (started from ZeD's Health tab)")
    H.stopActions()
end)
H.wait(3000, function() H.keepUp(); return (not S.banded) or not H.hasBurn(H.cache()) end, function(ok)
    if not S.banded then return end
    Q.check(ok, "burn: under the bandage the open tab no longer lists the burn (as the game's panel)")
    local d = H.model()
    local conds = d and d.condsByFigureName and d.condsByFigureName[S.FIG]
    Q.check(conds ~= nil and #conds >= 1, "burn: the tab shows the forearm's bandage", tostring(conds and #conds))
    RT.bounds(Q, "Health with the burn bandaged")
    -- a menu left open while the body heals, then picked
    H.partClick()
end)
Q.step(4, function()
    if S.hSkip then return end
    S.staleNames = H.menuNames()
    H.healAll()
end)
Q.waitMs(500)
Q.step(2, function()
    if S.hSkip then return end
    -- (only the treatments: under -debug the menu also holds the game's cheats, which must not be picked)
    local tried, bad = 0, nil
    local treat = { [getText("ContextMenu_Remove_Bandage")] = true, [S.bandText or "?"] = true, [S.cleanText or "?"] = true }
    for _, name in ipairs(S.staleNames or {}) do
        if treat[name] then
            tried = tried + 1
            local ok, err = H.pick(name)
            if not ok and err ~= "no such entry" and err ~= "the sub menu has no live entry" then bad = name .. ": " .. tostring(err) end
        end
    end
    H.hideMenu()
    Q.check(bad == nil, "burn: entries of a menu left open are picked after the body healed, with no error", bad or (tried .. " picked"))
end)
Q.waitMs(800)
Q.step(2, function()
    if not S.hSkip then
        H.stopActions()
        H.keepUp()
        local d = H.model()
        Q.check(d ~= nil and not H.hasBurn(d), "burn: healed, ZeD's Health data lists no burn on the forearm")
        Q.check(H.alive(), "burn: the character is alive at the end of the burn scenes")
    end
    -- the burn scenes are over: healed, god mode back ON at once (the put-back does it again)
    H.burnEnd()
end)

-- ===================================================================== put back
Q.mark()
Q.step(2, function()
    H.spyOff()
    -- the body first, before anything else can throw: not burning, healed, god mode and invincible ON
    S.godOff = false
    pcall(function() S.p:StopBurning() end)
    H.healAll()
    pcall(function() S.p:setGodMod(true) end)
    pcall(function() S.p:setInvincible(true) end)
    H.hideMenu()
    H.stopActions()
    pcall(function() getCell():setDrag(nil, S.pn) end)
    H.closeCard()
    pcall(setSpeed, 1)
    -- the campfire, when Take apart did not take it
    pcall(function()
        local so = S.cfSq and SCampfireSystem.instance:getLuaObjectOnSquare(S.cfSq)
        if so then SCampfireSystem.instance:removeCampfire(so) end
    end)
    S.fireDone = true
    S.doused = H.scan(15, true)
end)
Q.step(6, function()
    H.healAll()
    S.wornChanged, S.wornN = H.wornBack()
    S.gone, S.kept = H.settle()
    pcall(function()
        local h1, h2 = S.was.hand1, S.was.hand2
        S.p:setPrimaryHandItem((h1 and H.has(h1)) and h1 or nil)
        S.p:setSecondaryHandItem((h2 and H.has(h2)) and h2 or nil)
    end)
    S.floorDiff, S.floorFixed, S.floorFirst = H.floorsBack()
    if ZEDQA_HOME then ZEDQA_HOME("bx_fire") end
    H.goHome()
end)
Q.step(6, function()
    RT.pairOpen()
    if S.was.wtab then RT.worldTab(S.was.wtab) end
    if S.was.ctab then RT.charTab(S.was.ctab) end
end)
Q.waitMs(1500)
-- healed again (the steps above may have run a game update), then PROVED, while god mode is still ON; god mode and
-- invincible go back as found only for a healed body, and the guard is taken off only now
Q.step(2, function() H.healAll() end)
H.wait(4000, function() return (H.bodyClean()) end, function()
    local ok, why = H.bodyClean()
    if not ok and H.alive() then
        H.healAll()
        ok, why = H.bodyClean()
    end
    S.healed = ok
    Q.check(ok, "put back: the character is alive and healed (health 100, no wound on any part, no fracture, not infected)", why)
    Q.say("the guard: god mode put back on " .. tostring(S.regod or 0) .. " time(s), health topped up " .. tostring(S.topUps or 0)
        .. " time(s), " .. tostring(S.strays or 0) .. " squares the fire spread to put out")
    if S.healed then
        if S.was.inv ~= nil then pcall(function() S.p:setInvincible(S.was.inv) end) end
        pcall(function() S.p:setGodMod(S.was.god and true or false) end)
        -- (the stats after the heal and after god mode: both reset every one of them)
        H.statsBack()
    else
        pcall(function() S.p:setInvincible(true) end)
        pcall(function() S.p:setGodMod(true) end)
        Q.say("ERR the body is not whole: god mode and invincible are left ON")
    end
    S.live = false
    Events.OnTick.Remove(H.safety)
end)
Q.step(2, function()
    if S.was.open == false then RT.pairShut() end
    Q.say("put back: " .. tostring(S.doused) .. " squares doused at the end, " .. tostring(S.gone) .. " things taken away, " .. tostring(S.kept)
        .. " kept in place of the character's own that the game burnt, " .. tostring(S.floorFixed) .. " floors given their sprite back, "
        .. tostring(S.wornChanged) .. " worn things' condition restored, the fire restarted " .. tostring(S.restarts or 0) .. " times")
    local left = H.scan(15, false)
    Q.check(left == 0, "put back: no fire on any square within 15 tiles of home", left .. " squares")
    Q.check(S.cfSq == nil or H.campLua(S.cfSq) == nil, "put back: the campfire is gone")
    Q.check(S.floorDiff == 0, "put back: the floors within 5 tiles are as found", tostring(S.floorFirst))
    local onFire = true
    pcall(function() onFire = S.p:isOnFire() end)
    Q.check(H.alive() and not onFire, "put back: the character is alive and not burning")
    Q.check(H.burnsLeft() == 0, "put back: no burn and no bandage left on the body", H.burnsLeft() .. " parts")
    local overall = 0
    pcall(function() overall = S.p:getBodyDamage():getOverallBodyHealth() end)
    Q.check(overall >= 99, "put back: the body is healed", tostring(overall))
    Q.check(S.p:isGodMod() == (S.was.god and true or false), "put back: god mode as found", tostring(S.p:isGodMod()))
    Q.check(H.left() == 0, "put back: everything given is taken away", H.left() .. " left")
    Q.check(S.wornN == #S.worn, "put back: the character wears as many things as at the start", tostring(S.wornN) .. " vs " .. #S.worn)
    Q.check(getGameSpeed() == 1, "put back: game speed 1", tostring(getGameSpeed()))
    Q.check(math.abs(S.p:getX() - (S.hx + 0.5)) <= 3 and math.abs(S.p:getY() - (S.hy + 0.5)) <= 3, "put back: the character is home",
        math.floor(S.p:getX()) .. "," .. math.floor(S.p:getY()))
    Q.check(H.qn() == 0, "put back: no action left queued", H.qn() .. " queued")
    Q.check(#S.errs == 0, "ZeD printed no \"failed\" or error line of its own during the run", #S.errs .. ": " .. tostring(S.errs[1]) .. " / " .. tostring(S.errs[2]))
    RT.bounds(Q, "the end")
end)
Q.start()
