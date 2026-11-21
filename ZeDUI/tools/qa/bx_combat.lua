-- ZeDUI/tools/qa/bx_combat.lua  (Nov 21 2026, QA beast day): shoot, reload, swing and kill with ZeD's windows open.
-- Built on rt_kit.lua (run zedqa_prelude.lua and rt_kit.lua first); grep "ZEDQA bx_cmb".
--
-- What it does, as a player would, on the drag strip:
--   pistol   an M9 given empty with two magazines and loose rounds; its card opened in the Character window by a click
--            on its row; held: the pouch says Empty. One magazine filled by hand, the other loaded through the game's
--            own action (ISLoadBulletsInMagazine), stopped part way, the tab switched to the Journal and back, then
--            loaded again. The game's own reload (BeginAutomaticReload: insert, rack).
--   aim      aiming with both windows pinned (they stay), then unpinned with the pointer away (both roll up at once,
--            under the 2 s they take without aim). A zombie is made 5 tiles ahead and shot through the game's own
--            attack hook (ISReloadWeaponAction.attackHook, what a click calls); aim let go, the windows come back.
--   jam      the pistol jammed: the pouch and the facts still read, ZeD's firearm wheel offers Unjam, a press on it
--            racks the gun. The magazine ejected (ISEjectMagazine). An empty gun's click.
--   shotgun  loaded shell by shell (stopped part way, the windows closed and opened again), shot at a zombie 4 tiles off.
--   rifle    a full magazine inserted, shot at a zombie 8 tiles off, racked by hand (the round comes back).
--   swaps    the hands changed every frame for a dozen frames; empty hands: no pouch.
--   broken   a broken bat (no pouch, facts read, a swing), a broken pistol held, then taken out of the game while its
--            card is open and it is in the hand: the pouch goes and the card lets go.
--   melee    a good bat: swings and shoves at a zombie one tile ahead.
--   kills    after each death: the game's count, ZeD's row (Firearm, Blunt), the total (game + fire), the Journal's
--            header, the Identity tab's figure and the rows adding up; the Journal and Identity tabs opened and measured.
-- After every act the belt's pouch (the HUD's own kept state, ZeD_Belt.lua) is checked against the gun (rounds in it,
-- chambered, loose rounds, magazines and their rounds, the count's words), ZeD.itemFacts and the facts panel against the
-- gun's count, and the open card's own model against it. RT.bounds on every scene.
-- A zombie the shots did not kill is finished with the game's own IsoZombie:Hit (as zedqa_kills_kind.lua does), said in
-- the log. A scene that cannot be staged is a SKIP with its reason.
-- Put back: aim, the pointer, the speed, the wheel, the hands, every zombie, corpse and blood splat made, everything
-- given (and every round, magazine or gun of those types that was not there before), the kill count and ZeD_Kills, the
-- pouch switch, unlimited ammo, the pins, the tabs, the windows, the list's stacks, health, panic and stress, blood on
-- the clothes, the experience earned, the character home.

if not RT then
    print("ZEDQA bx_cmb ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA bx_cmb VERDICT FAIL 1")
    print("ZEDQA bx_cmb DONE")
    return
end

local Q = RT.make("bx_cmb")
Q.maxMs = 400000
local S = { p = RT.p, pn = RT.pn, g = {}, zs = {}, tz = {}, had = {}, was = {}, fired = {}, byCat = {}, stackWas = {},
            kills = 0, pulls = 0, how = {} }
local H = {}
S.B = ZeD.Belt
S.K = ZeD.KillTracker
S.HV = ZeD.Halves
S.realMX, S.realMY = getMouseX, getMouseY

-- ===================================================================== small helpers
function H.now() return getTimestampMs() end
-- a method that may not be in this build: nil when it is not there (no error to log)
function H.call0(o, name)
    if o == nil then return nil end
    local f = o[name]
    if not f then return nil end
    return f(o)
end
function H.call1(o, name, a)
    if o == nil then return nil end
    local f = o[name]
    if not f then return nil end
    return f(o, a)
end
function H.speed(n) local f = ZEDQA_SPEED or setGameSpeed; pcall(f, n) end
-- wait on the clock: fn(ok) once cond() holds or ms have passed
function H.waitUntil(ms, cond, fn)
    local st = {}
    Q.waitFor(1, 100000, function()
        st.t = st.t or H.now()
        local ok, v = pcall(cond)
        st.ok = (ok and v) and true or false
        return st.ok or (H.now() - st.t >= ms)
    end, function() fn(st.ok) end)
end
function H.try(what, fn, a, b)
    local ok, r1, r2, r3 = pcall(fn, a, b)
    if not ok then Q.check(false, what .. ": ran without an error", r1); return false end
    return true, r1, r2, r3
end
function H.inv() return S.p:getInventory() end
function H.count(ft)
    local n = 0
    pcall(function() n = H.inv():getItemCountRecurse(ft) or 0 end)
    return n
end
-- the items of a type that were there before this script gave any (they stay at the end)
function H.note(ft)
    if not ft or S.had[ft] then return end
    local had = {}
    pcall(function()
        local l = H.inv():getAllTypeRecurse(ft)
        for i = 0, l:size() - 1 do had[l:get(i)] = true end
    end)
    S.had[ft] = had
end
function H.giveN(ft, n)
    local first = nil
    for _ = 1, n do
        local it = RT.give(ft)
        first = first or it
    end
    return first
end
-- a gun with its own rounds and magazines (read from the gun, not assumed)
function H.kit(name, ft, rounds, mags, both)
    H.note(ft)
    local gun = RT.give(ft)
    if not gun then return nil end
    local g = { name = name, gun = gun, ft = ft, both = both, mags = {} }
    local at = H.call0(gun, "getAmmoType")
    if type(at) == "string" then
        if at ~= "" then g.key = at end
    elseif at ~= nil then
        g.key = H.call0(at, "getItemKey")
    end
    g.mag = H.call0(gun, "getMagazineType")
    g.max = H.call0(gun, "getMaxAmmo") or 0
    if g.key and rounds > 0 then H.note(g.key); H.giveN(g.key, rounds) end
    if g.mag then
        H.note(g.mag)
        for i = 1, mags do g.mags[i] = RT.give(g.mag) end
    end
    S.g[name] = g
    return g
end
function H.hold(g)
    local it = g and g.gun or nil
    S.p:setPrimaryHandItem(it)
    S.p:setSecondaryHandItem((g and g.both) and it or nil)
end
function H.rounds(g)
    if not g then return -1 end
    return g.gun:getCurrentAmmoCount() + ((g.gun:isRoundChambered() == true) and 1 or 0)
end
function H.busy()
    local n = 0
    pcall(function()
        local q = ISTimedActionQueue.getTimedActionQueue(S.p)
        if q and q.queue then n = #q.queue end
    end)
    return n > 0
end
function H.stop() pcall(function() S.p:StopAllActionQueue() end) end
function H.dead(z) return z == nil or z:isDead() or z:getHealth() <= 0 end

-- ===================================================================== the pointer and the pins
function H.pointer(x, y)
    if x then
        getMouseX = function() return x end
        getMouseY = function() return y end
    else
        getMouseX, getMouseY = S.realMX, S.realMY
    end
end
-- a spot of the screen no ZeD window or pop-up covers
function H.inRoot(x, y)
    local W, Hs = RT.core:getScreenWidth(), RT.core:getScreenHeight()
    for _, r in ipairs(RT.roots()) do
        local vis = false
        pcall(function() vis = r.e:isVisible() end)
        if vis and RT.isZeD(r.t) then
            local rx, ry, rw, rh = r.e:getX(), r.e:getY(), r.e:getWidth(), r.e:getHeight()
            if not (rw >= W - 2 and rh >= Hs - 2) and x >= rx - 8 and y >= ry - 8 and x <= rx + rw + 8 and y <= ry + rh + 8 then return true end
        end
    end
    return false
end
function H.awaySpot()
    local W, Hs = RT.core:getScreenWidth(), RT.core:getScreenHeight()
    local c = { { 0.5, 0.42 }, { 0.5, 0.3 }, { 0.5, 0.55 }, { 0.42, 0.42 }, { 0.58, 0.42 }, { 0.5, 0.2 }, { 0.5, 0.66 } }
    for _, f in ipairs(c) do
        local x, y = math.floor(W * f[1]), math.floor(Hs * f[2])
        if not H.inRoot(x, y) then return x, y end
    end
    return math.floor(W / 2), math.floor(Hs * 0.42)
end
function H.wins()
    local out = {}
    local c, w = RT.cw(), RT.ww()
    if c then out[#out + 1] = c end
    if w then out[#out + 1] = w end
    return out
end
function H.pinAll(on)
    for _, win in ipairs(H.wins()) do
        if win._halves and S.HV and S.HV.setPin then pcall(S.HV.setPin, win, nil, on) else win.pinned = on end
    end
end
function H.rolled(win)
    if not win then return false end
    if win.windowShaded == true or win._rolled == true then return true end
    local r = false
    if S.HV and S.HV.anyRolled then pcall(function() r = S.HV.anyRolled(win) and true or false end) end
    return r
end
function H.showAll()
    for _, win in ipairs(H.wins()) do
        if win._halves and S.HV and S.HV.showAll then pcall(S.HV.showAll, win)
        elseif win.windowShaded and win.setWindowShaded then pcall(function() win:setWindowShaded(false) end) end
    end
end

-- ===================================================================== aim, zombies, the trigger
function H.aimTick()
    if S.aim and S.p and not S.p:isDead() then S.p:setIsAiming(true) end
end
function H.aimOn()
    S.aim = true
    H.call1(S.p, "setForceAim", true)
    S.p:setIsAiming(true)
end
function H.aimOff()
    S.aim = false
    H.call1(S.p, "setForceAim", false)
    H.call1(S.p, "setDoShove", false)
    S.p:setIsAiming(false)
end
function H.fwd()
    local v = H.call0(S.p, "getForwardDirection")
    local x, y = 1, 0
    if v then x, y = v:getX(), v:getY() end
    local l = math.sqrt(x * x + y * y)
    if l < 0.01 then return 1, 0 end
    return x / l, y / l
end
-- a harmless zombie made ahead of the character (the way the character faces now)
function H.spawnZ(slot, dist)
    S.tz[slot] = nil
    local dx, dy = H.fwd()
    local x, y = math.floor(S.p:getX() + dx * dist), math.floor(S.p:getY() + dy * dist)
    if not getCell():getGridSquare(x, y, 0) then return nil end
    local z = nil
    local list = addZombiesInOutfit(x, y, 0, 1, nil, 0)
    if list and list:size() > 0 then z = list:get(0) end
    if z then
        z:setUseless(true)
        S.zs[#S.zs + 1] = z
        S.tz[slot] = z
    end
    return z
end
-- the zombie put back on the line of fire when the character's facing moved (aim follows the real pointer)
function H.lineUp(z, dist)
    if H.dead(z) then return end
    local dx, dy = H.fwd()
    local vx, vy = z:getX() - S.p:getX(), z:getY() - S.p:getY()
    local l = math.sqrt(vx * vx + vy * vy)
    local dot = (l > 0.01) and ((vx * dx + vy * dy) / l) or 0
    if dot < 0.985 or math.abs(l - dist) > 1.6 then
        local x, y = S.p:getX() + dx * dist, S.p:getY() + dy * dist
        if getCell():getGridSquare(math.floor(x), math.floor(y), 0) then
            z:setX(x); z:setY(y); z:setLastX(x); z:setLastY(y)
        end
    end
end
function H.queueSpawn(slot, dist, label)
    Q.step(4, function()
        if S.p:isDead() then return end
        local ok, z = pcall(H.spawnZ, slot, dist)
        if not (ok and z) then Q.skip(label .. ": a zombie " .. dist .. " tiles ahead", "it could not be made there: " .. tostring(z)) end
    end)
    H.waitUntil(1200, function() local z = S.tz[slot]; return z ~= nil and z:getCurrentSquare() ~= nil end, function() end)
end
-- pulls of the trigger through the game's own attack hook (what a click calls), one at a time
function H.onePull(name, slot, dist, charge)
    Q.step(3, function()
        S.shot = nil
        local g, z = S.g[name], S.tz[slot]
        if not g or S.noFire or not S.aiming or H.dead(z) or S.p:isDead() then return end
        H.lineUp(z, dist)
        S.shot = { n0 = H.rounds(g) }
        S.pulls = S.pulls + 1
        local ok, err = pcall(ISReloadWeaponAction.attackHook, S.p, charge, g.gun)
        if not ok then
            S.shot = nil
            S.noFire = true
            Q.skip("live attacks", "the game's attack hook raised an error: " .. tostring(err))
        end
    end)
    H.waitUntil(1500, function()
        if S.shot == nil then return true end
        return H.rounds(S.g[name]) ~= S.shot.n0 or H.dead(S.tz[slot])
    end, function()
        if S.shot and H.rounds(S.g[name]) ~= S.shot.n0 then S.fired[name] = (S.fired[name] or 0) + 1 end
    end)
    H.waitUntil(2500, function() return S.shot == nil or (not S.p:isAttackStarted() and not H.busy()) end, function() end)
end
function H.queuePulls(name, slot, dist, n, charge)
    for _ = 1, n do H.onePull(name, slot, dist, charge) end
end
-- the zombie's end: shot dead, or finished with the game's own Hit (said in the log); the kill is expected under cat
function H.queueFinish(name, slot, cat, label)
    Q.step(3, function()
        local g, z = S.g[name], S.tz[slot]
        if not (g and z) then return end
        local how = H.dead(z) and "the attacks" or "the game's own Hit"
        for _ = 1, 40 do
            if H.dead(z) then break end
            pcall(function() z:Hit(g.gun, S.p, 3.0, false, 1.0) end)
        end
        if H.dead(z) then
            S.kills = S.kills + 1
            S.byCat[cat] = (S.byCat[cat] or 0) + 1
        end
        Q.say(label .. ": " .. tostring(S.fired[name] or 0) .. " of this scene's attacks took a round from the weapon, the zombie died by " .. how .. " (dead " .. tostring(H.dead(z)) .. ")")
    end)
end

-- ===================================================================== what ZeD shows against the game
function H.hud()
    local h = nil
    pcall(function() h = S.B.getHUD(S.pn) end)
    return h
end
function H.box(kind)
    local h = H.hud()
    for _, b in ipairs((h and h._boxes) or {}) do if b.kind == kind then return b end end
    return nil
end
function H.truth(g)
    local gun = g.gun
    local t = { inGun = gun:getCurrentAmmoCount(), ch = gun:isRoundChambered() == true, max = gun:getMaxAmmo(), loose = 0, mags = 0, magRounds = 0 }
    if g.key then t.loose = H.count(g.key) end
    if g.mag then
        pcall(function()
            local l = H.inv():getAllTypeRecurse(g.mag)
            t.mags = l:size()
            for i = 0, l:size() - 1 do t.magRounds = t.magRounds + (l:get(i):getCurrentAmmoCount() or 0) end
        end)
    end
    return t
end
-- nil when the pouch's own kept state (what the belt drew last) is the game's, else what differs
function H.beltDiff(g)
    local h = H.hud()
    local c = h and h._ammo
    local a = c and c.a
    if not a then return "no pouch state" end
    if c.gun ~= g.gun then return "the pouch is on another item" end
    local t = H.truth(g)
    local sum = 0
    for _, n in ipairs(a.mags or {}) do sum = sum + n end
    if a.inGun ~= t.inGun then return "in the gun " .. tostring(a.inGun) .. ", the game " .. tostring(t.inGun) end
    if (a.chambered == true) ~= t.ch then return "chambered " .. tostring(a.chambered) .. ", the game " .. tostring(t.ch) end
    if a.loose ~= t.loose then return "loose rounds " .. tostring(a.loose) .. ", the game " .. tostring(t.loose) end
    if #(a.mags or {}) ~= t.mags or sum ~= t.magRounds then
        return "magazines " .. #(a.mags or {}) .. " holding " .. sum .. ", the game " .. t.mags .. " holding " .. t.magRounds
    end
    return nil
end
function H.wordsOk(g)
    local h = H.hud()
    local c = h and h._ammo
    local a = c and c.a
    if not a then return false, "no pouch state" end
    local ok, count, s1, s2 = pcall(S.B.ammoWords, a)
    if not ok then return false, "ammoWords: " .. tostring(count) end
    local ok2, l1 = pcall(S.B.ammoLines, a)
    if not ok2 then return false, "ammoLines: " .. tostring(l1) end
    local t = H.truth(g)
    local want = tostring(t.inGun) .. (t.ch and "+1" or "")
    if t.inGun == 0 and not t.ch then want = ZeD.textCase(ZeD.tr("UI_ZeD_Belt_AmmoEmpty")) end
    return count == want, tostring(count) .. " (want " .. tostring(want) .. ") | " .. tostring(s1) .. " | " .. tostring(s2) .. " | " .. tostring(l1)
end
function H.factRow(panel, label)
    for _, grp in ipairs((panel and panel.groups) or {}) do
        for _, r in ipairs(grp.rows or {}) do if r.label == label then return r end end
    end
    return nil
end
function H.endsWith(s, tail) return type(s) == "string" and s:sub(-#tail) == tail end
function H.factsOk(g)
    local gun = g.gun
    local cur, max = gun:getCurrentAmmoCount(), gun:getMaxAmmo()
    local ok, stats = pcall(ZeD.itemFacts, gun)
    if not ok then return false, "itemFacts: " .. tostring(stats) end
    local v = nil
    for _, r in ipairs(type(stats) == "table" and stats or {}) do if r.label == "Ammo" then v = r.value end end
    local want = cur .. "/" .. max
    if v ~= want then return false, "itemFacts says " .. tostring(v) .. ", the gun " .. want end
    if not (ZeD.ItemFactsPanel and ZeD.ItemFactsPanel.factsFor) then return true, want .. " (no facts panel module)" end
    local ok2, panel = pcall(ZeD.ItemFactsPanel.factsFor, gun, S.pn)
    if not ok2 then return false, "factsFor: " .. tostring(panel) end
    local r = H.factRow(panel, getText("Tooltip_weapon_Ammo"))
    local want2 = string.format("%d / %d", cur, max)
    if not (r and H.endsWith(r.value, want2)) then return false, "the facts panel says " .. tostring(r and r.value) .. ", the gun " .. want2 end
    return true, want
end
function H.card() local w = RT.cw(); return w and w._itemCard end
function H.cardOn(item)
    local w = RT.cw()
    local c = w and w._itemCard
    return item ~= nil and w ~= nil and w._drawerItem == item and c ~= nil and c.item == item
end
-- nil when the open card's own model shows the gun's count
function H.cardDiff(g)
    local c = H.card()
    local m = c and c._model
    local r = m and H.factRow(m.facts, getText("Tooltip_weapon_Ammo"))
    local want = string.format("%d / %d", g.gun:getCurrentAmmoCount(), g.gun:getMaxAmmo())
    if r and H.endsWith(r.value, want) then return nil end
    return tostring(r and r.value) .. " (the gun " .. want .. ")"
end
-- queue: the pouch, its words, the facts and the open card against the gun
function H.checkAll(label, name)
    H.waitUntil(1500, function()
        local g = S.g[name]
        return g == nil or S.noBelt or H.beltDiff(g) == nil
    end, function()
        local g = S.g[name]
        if not g then Q.skip(label, "no " .. name .. " was given"); return end
        if S.noBelt then return end
        local d = H.beltDiff(g)
        if d == nil then S.beltSeen = true end
        if d == "no pouch state" and not S.beltSeen then S.noBelt = true end
        Q.check(d == nil, label .. ": the belt's pouch has the " .. name .. " as the game has it", d or ("rounds " .. H.rounds(g)))
        if d == nil then
            local ok, det = H.wordsOk(g)
            Q.check(ok, label .. ": the pouch's count reads right", det)
            Q.check(H.box("ammo") ~= nil, label .. ": the pouch is on the belt")
        end
    end)
    Q.step(1, function()
        local g = S.g[name]
        if not g then return end
        local ok, det = H.factsOk(g)
        Q.check(ok, label .. ": the item facts give the " .. name .. "'s rounds", det)
    end)
    H.waitUntil(1500, function()
        local g = S.g[name]
        return g == nil or not H.cardOn(g.gun) or H.cardDiff(g) == nil
    end, function()
        local g = S.g[name]
        if not g or not H.cardOn(g.gun) then return end
        local d = H.cardDiff(g)
        Q.check(d == nil, label .. ": the open card follows the " .. name .. "'s rounds", d)
    end)
end

-- ===================================================================== the card, by a click on the row
function H.content() local w = RT.cw(); return w and w._mainContent end
function H.rowZone(item)
    local c = H.content()
    for _, z in ipairs((c and c._hitZones) or {}) do if z.id == item then return z end end
    return nil
end
function H.seekRow(item)
    local c = H.content()
    if not c or item == nil then return false end
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
    c:onMouseDown(x, y)
    c:onMouseUp(x, y)
    return true
end
function H.openStacks()
    local c = H.content()
    if not c then return end
    c._expandedStacks = c._expandedStacks or {}
    if S.scrollWas == nil and c._scroll then S.scrollWas = c._scroll.scrollPos end
    for _, g in pairs(S.g) do
        if S.stackWas[g.ft] == nil then S.stackWas[g.ft] = c._expandedStacks[g.ft] or false end
        c._expandedStacks[g.ft] = true
    end
end
function H.queueCard(name, label)
    Q.step(2, function()
        S.seekPos = nil
        RT.charTab("loot")
        H.openStacks()
    end)
    Q.waitFor(3, 200, function() local g = S.g[name]; return g == nil or H.seekRow(g.gun) end, function()
        local g = S.g[name]
        if not g then return end
        if not H.rowZone(g.gun) then Q.skip(label .. ": the " .. name .. "'s card", "its row was not found in the Character window's list"); return end
        H.try(label .. ": a click on the " .. name .. "'s row", H.click, g.gun)
    end)
    H.waitUntil(1500, function() local g = S.g[name]; return g == nil or H.cardOn(g.gun) end, function()
        local g = S.g[name]
        if not g or not H.rowZone(g.gun) then return end
        Q.check(H.cardOn(g.gun), label .. ": a click on the " .. name .. "'s row opens its card")
        RT.bounds(Q, label .. ", the " .. name .. "'s card")
    end)
end
function H.closeCard()
    local w = RT.cw()
    local c = H.content()
    if not (w and c) then return end
    if w._drawerItem and w._updateDrawer then
        c._selectedItems = {}
        c._lastClickedItem = nil
        pcall(w._updateDrawer, c)
    end
end

-- ===================================================================== kills
function H.snap()
    local s = { explosion = 0, fire = 0, vehicle = 0, weapon = {}, engine = S.p:getZombieKills() }
    local ok, kd = pcall(S.K.data, S.p)
    if ok and type(kd) == "table" then
        s.explosion, s.fire, s.vehicle = tonumber(kd.explosion) or 0, tonumber(kd.fire) or 0, tonumber(kd.vehicle) or 0
        for k, v in pairs(kd.weapon or {}) do s.weapon[k] = tonumber(v) or 0 end
    else
        s.err = tostring(kd)
    end
    return s
end
function H.copy(t)
    if type(t) ~= "table" then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = H.copy(v) end
    return o
end
function H.totals(label)
    local s = H.snap()
    if s.err then Q.check(false, label .. ": KillTracker.data ran without an error", s.err); return end
    local ok, total = H.try(label .. ": KillTracker.total", S.K.total, S.p)
    if not ok then return end
    Q.check(total == s.engine + s.fire, label .. ": ZeD's total is the game's count plus fire kills", tostring(total) .. " against " .. s.engine .. " + " .. s.fire)
    local rows = s.explosion + s.fire + s.vehicle
    for _, v in pairs(s.weapon) do rows = rows + v end
    Q.check(rows == total, label .. ": the Journal's rows add up to the total", rows .. " against " .. tostring(total))
    local okJ, d = H.try(label .. ": the Journal's data", ZeD.JournalTab.gatherData, S.p)
    if okJ then Q.check(type(d) == "table" and d.totalKills == total, label .. ": the Journal's header is the total", tostring(type(d) == "table" and d.totalKills) .. " against " .. tostring(total)) end
    local okI, id = H.try(label .. ": the Identity tab's data", ZeD.IdentityTab.gatherData, S.p)
    if okI then Q.check(type(id) == "table" and tonumber(id.zKills) == total, label .. ": the Identity tab shows the total", tostring(type(id) == "table" and id.zKills) .. " against " .. tostring(total)) end
end
function H.checkKills(label, cat)
    H.waitUntil(4000, function()
        if S.p:getZombieKills() < S.k0.engine + S.kills then return false end
        local s = H.snap()
        return S.killsOff or (s.weapon[cat] or 0) - (S.k0.weapon[cat] or 0) >= (S.byCat[cat] or 0)
    end, function()
        local s = H.snap()
        if (S.byCat[cat] or 0) == 0 then Q.skip(label .. ": the kill's row", "no zombie died in this scene"); return end
        if S.killsOff or s.engine ~= S.k0.engine + S.kills then
            Q.skip(label .. ": the kill's row", "the game's own count moved by " .. (s.engine - S.k0.engine) .. " for " .. S.kills .. " deaths, so there is nothing to hold ZeD's rows to")
            S.killsOff = true
            H.totals(label)
            return
        end
        local got = (s.weapon[cat] or 0) - (S.k0.weapon[cat] or 0)
        Q.check(got == S.byCat[cat], label .. ": ZeD files the kill under " .. cat, "+" .. got .. ", wanted +" .. S.byCat[cat])
        Q.check(s.fire == S.k0.fire and s.explosion == S.k0.explosion and s.vehicle == S.k0.vehicle, label .. ": no fire, explosion or vehicle row moved",
            "fire " .. s.fire .. ", explosion " .. s.explosion .. ", vehicle " .. s.vehicle)
        H.totals(label)
    end)
end

-- ===================================================================== the firearm wheel
function H.wheel() local m = nil; pcall(function() m = getPlayerRadialMenu(S.pn) end); return m end
function H.wheelOpen()
    local f = ISFirearmRadialMenu:new(S.p)
    f:fillMenu()
    f:display()
end
function H.wheelShut()
    local m = H.wheel()
    if m and m.isReallyVisible and m:isReallyVisible() then pcall(function() m:undisplay() end) end
end
function H.towards(m, i)
    local n = #m.slices
    local _, _, r, cx, cy = ZeD.Wheel.geom(m)
    local a = math.rad(-90 + (i - 1) * 360 / math.max(n, 2))
    return cx + r * math.cos(a), cy + r * math.sin(a)
end
function H.sliceWith(m, text)
    for i, s in ipairs((m and m.slices) or {}) do
        if type(s.text) == "string" and s.text:find(text, 1, true) == 1 then return i, s end
    end
    return nil
end

-- ===================================================================== blood, experience, body (for the put-back)
function H.bloodParts()
    local out = {}
    pcall(function()
        local n = BloodBodyPartType.MAX:index()
        for i = 0, n - 1 do out[#out + 1] = BloodBodyPartType.FromIndex(i) end
    end)
    return out
end
function H.visuals()
    local out = {}
    pcall(function() out[#out + 1] = S.p:getHumanVisual() end)
    pcall(function()
        local worn = S.p:getWornItems()
        for i = 0, worn:size() - 1 do
            local it = worn:getItemByIndex(i)
            local v = H.call0(it, "getVisual")
            if v then out[#out + 1] = v end
        end
    end)
    return out
end
function H.bloodSnap()
    S.blood = {}
    local parts = H.bloodParts()
    for _, v in ipairs(H.visuals()) do
        local row = { v = v, b = {}, d = {} }
        pcall(function()
            for i, part in ipairs(parts) do row.b[i] = v:getBlood(part); row.d[i] = v:getDirt(part) end
        end)
        S.blood[#S.blood + 1] = row
    end
end
function H.bloodBack()
    local parts = H.bloodParts()
    for _, row in ipairs(S.blood or {}) do
        pcall(function()
            for i, part in ipairs(parts) do
                if row.b[i] ~= nil then row.v:setBlood(part, row.b[i]) end
                if row.d[i] ~= nil then row.v:setDirt(part, row.d[i]) end
            end
        end)
    end
    pcall(function() S.p:resetModelNextFrame() end)
end
function H.xpSnap()
    S.xp = {}
    pcall(function()
        local xp = S.p:getXp()
        for i = 0, PerkFactory.PerkList:size() - 1 do
            local perk = PerkFactory.PerkList:get(i)
            S.xp[#S.xp + 1] = { perk = perk, xp = xp:getXP(perk), lvl = S.p:getPerkLevel(perk) }
        end
    end)
end
function H.xpBack()
    local grew, left = 0, 0
    pcall(function()
        local xp = S.p:getXp()
        for _, r in ipairs(S.xp or {}) do
            local now = xp:getXP(r.perk)
            if now > r.xp + 0.001 then
                grew = grew + 1
                if xp.AddXPNoMultiplier then pcall(function() xp:AddXPNoMultiplier(r.perk, r.xp - now) end) end
                if math.abs(xp:getXP(r.perk) - r.xp) > 0.01 or S.p:getPerkLevel(r.perk) ~= r.lvl then left = left + 1 end
            end
        end
    end)
    Q.say("put back: experience grew in " .. grew .. " skills, " .. left .. " of them not back at the value found")
end
function H.statSnap()
    S.stat = {}
    if not CharacterStat then return end
    local st = S.p:getStats()
    for _, k in ipairs({ "PANIC", "STRESS", "ENDURANCE", "FATIGUE" }) do
        local cs = CharacterStat[k]
        if cs and st and st.get then pcall(function() S.stat[k] = st:get(cs) end) end
    end
end
function H.statBack()
    pcall(function() S.p:getBodyDamage():RestoreToFullHealth() end)
    if not CharacterStat then return end
    local st = S.p:getStats()
    for k, v in pairs(S.stat or {}) do
        local cs = CharacterStat[k]
        if cs and st and st.set then pcall(function() st:set(cs, v) end) end
    end
end

-- ===================================================================== the put-back's sweeps
function H.bodiesNear(r)
    local out = {}
    local px, py = math.floor(S.p:getX()), math.floor(S.p:getY())
    for x = px - r, px + r do
        for y = py - r, py + r do
            local sq = getCell():getGridSquare(x, y, 0)
            if sq then
                local l = sq:getStaticMovingObjects()
                for i = 0, l:size() - 1 do
                    local o = l:get(i)
                    if instanceof(o, "IsoDeadBody") then out[#out + 1] = { sq = sq, body = o } end
                end
            end
        end
    end
    return out
end
function H.sweepBodies()
    local n = 0
    local ok, list = pcall(H.bodiesNear, 14)
    for _, b in ipairs(ok and list or {}) do
        if not S.bodies0[b.body] then
            pcall(function() b.sq:removeCorpse(b.body, false) end)
            pcall(function() b.sq:removeBlood(false, false) end)
            n = n + 1
        end
    end
    return n
end
function H.sweepZombies()
    local n = 0
    for _, z in ipairs(S.zs) do
        pcall(function()
            if z:getCurrentSquare() ~= nil or not z:isDead() then
                z:removeFromWorld()
                z:removeFromSquare()
                n = n + 1
            end
        end)
    end
    return n
end
function H.sweepBlood()
    pcall(function()
        local px, py = math.floor(S.p:getX()), math.floor(S.p:getY())
        for x = px - 10, px + 10 do
            for y = py - 10, py + 10 do
                local sq = getCell():getGridSquare(x, y, 0)
                if sq then sq:removeBlood(false, false) end
            end
        end
    end)
end
-- every round, magazine and gun of the types used that was not there before (unloading makes new ones)
function H.sweepItems()
    local n = 0
    for ft, had in pairs(S.had) do
        pcall(function()
            local l = H.inv():getAllTypeRecurse(ft)
            local out = {}
            for i = 0, l:size() - 1 do
                local it = l:get(i)
                if not had[it] then out[#out + 1] = it end
            end
            for _, it in ipairs(out) do
                local c = it:getContainer()
                if c then c:Remove(it); n = n + 1 end
            end
        end)
    end
    return n
end
function H.floorSnap()
    S.floor0 = {}
    pcall(function()
        local px, py = math.floor(S.p:getX()), math.floor(S.p:getY())
        for x = px - 2, px + 2 do
            for y = py - 2, py + 2 do
                local sq = getCell():getGridSquare(x, y, 0)
                local l = sq and sq:getWorldObjects()
                for i = 0, (l and l:size() or 0) - 1 do S.floor0[l:get(i)] = true end
            end
        end
    end)
end
function H.sweepFloor()
    local n = 0
    pcall(function()
        local px, py = math.floor(S.p:getX()), math.floor(S.p:getY())
        for x = px - 2, px + 2 do
            for y = py - 2, py + 2 do
                local sq = getCell():getGridSquare(x, y, 0)
                local l = sq and sq:getWorldObjects()
                for i = (l and l:size() or 0) - 1, 0, -1 do
                    local wo = l:get(i)
                    local it = wo and wo:getItem()
                    if it and S.had[it:getFullType()] and not S.floor0[wo] then
                        sq:transmitRemoveItemFromSquare(wo)
                        n = n + 1
                    end
                end
            end
        end
    end)
    return n
end

-- ===================================================================== 1. set the scene
Q.step(5, function()
    if ZEDQA_HOME then pcall(ZEDQA_HOME, "bx_cmb") end
    H.speed(1)
    local p = S.p
    local W = S.was
    W.p1, W.p2 = p:getPrimaryHandItem(), p:getSecondaryHandItem()
    W.unlimited = H.call0(p, "isUnlimitedAmmo")
    W.open = RT.isOpen()
    W.engine = p:getZombieKills()
    W.kd = H.copy(p:getModData().ZeD_Kills)
    if ZeD.Settings and ZeD.Settings.ammoBoxOption then
        W.ammoBox = ZeD.Settings.ammoBoxOption:getValue()
        ZeD.Settings.ammoBoxOption:setValue(2)
    end
    local t = p:getModData().ZeD_WinPinned
    if type(t) == "table" then W.pins = H.copy(t) end
    if W.unlimited then H.call1(p, "setUnlimitedAmmo", false) end
    S.bodies0 = {}
    local ok, list = pcall(H.bodiesNear, 14)
    for _, b in ipairs(ok and list or {}) do S.bodies0[b.body] = true end
    H.bloodSnap(); H.xpSnap(); H.statSnap(); H.floorSnap()
    Events.OnTick.Add(H.aimTick)
    Q.say("scene: god mode " .. tostring(H.call0(p, "isGodMod")) .. ", unlimited ammo was " .. tostring(W.unlimited) .. ", kills " .. W.engine .. ", corpses already near " .. #(ok and list or {}))
end)
Q.step(3, function()
    Q.check(S.B ~= nil and S.B.ammo ~= nil and S.K ~= nil and S.K.total ~= nil and ZeD.itemFacts ~= nil, "the code under test is loaded (belt pouch, kill tracker, item facts)")
    H.kit("pistol", "Base.Pistol", 24, 2, false)
    H.kit("shotgun", "Base.Shotgun", 10, 0, true)
    H.kit("rifle", "Base.HuntingRifle", 8, 1, true)
    H.kit("pistol2", "Base.Pistol", 0, 0, false)
    H.kit("bat", "Base.BaseballBat", 0, 0, true)
    H.kit("bat2", "Base.BaseballBat", 0, 0, true)
    local names = {}
    for k, g in pairs(S.g) do names[#names + 1] = k .. " (rounds " .. tostring(g.key) .. ", magazine " .. tostring(g.mag) .. ", holds " .. tostring(g.max) .. ")" end
    Q.say("given: " .. table.concat(names, "; "))
    Q.check(S.g.pistol ~= nil and S.g.shotgun ~= nil and S.g.rifle ~= nil, "staging: a pistol, a shotgun and a rifle were given")
    RT.pairOpen()
end)
H.waitUntil(3000, function() return RT.cw() ~= nil and RT.ww() ~= nil and RT.isOpen() end, function(ok)
    Q.check(ok, "both windows are open")
    local c, w = RT.cw(), RT.ww()
    S.was.charTab, S.was.worldTab = c and c._activeTab, w and w._activeTab
    H.pinAll(true)
    S.k0 = H.snap()
    S.k0.engine = S.p:getZombieKills()
    RT.bounds(Q, "the scene set")
end)

-- ===================================================================== 2. the pistol: card, empty, magazines, reload
H.queueCard("pistol", "pistol")
Q.step(4, function() H.hold(S.g.pistol) end)
H.checkAll("pistol held empty, no magazine in it", "pistol")
Q.step(2, function()
    local g = S.g.pistol
    if not (g and g.mags[1]) then Q.skip("the magazines", "the pistol's magazine type was not given"); return end
    local m = g.mags[1]
    m:setCurrentAmmoCount(m:getMaxAmmo())
end)
H.checkAll("a full and an empty magazine carried", "pistol")
-- load the empty magazine through the game's own action, stop it part way, switch tabs, load it again
Q.step(2, function()
    local g = S.g.pistol
    local m = g and g.mags[2]
    if not m then return end
    H.speed(2)
    S.loadStarted = pcall(function() ISTimedActionQueue.add(ISLoadBulletsInMagazine:new(S.p, m, 6)) end)
end)
Q.waitMs(700)
Q.step(1, function()
    if not S.loadStarted then return end
    local okB, st = pcall(function() return ZeD.ActionBar and ZeD.ActionBar.state and ZeD.ActionBar.state(S.p, S.pn) end)
    Q.check(okB, "loading a magazine: ZeD's action bar reads the action without an error", okB and tostring(st and st.label) or st)
    RT.charTab("journal")
end)
Q.step(6, function()
    H.stop()
    RT.bounds(Q, "the Journal tab opened while a magazine was being loaded")
    RT.charTab("loot")
end)
H.checkAll("magazine loading stopped part way", "pistol")
Q.step(2, function()
    local g = S.g.pistol
    local m = g and g.mags[2]
    if not m then return end
    pcall(function() ISTimedActionQueue.add(ISLoadBulletsInMagazine:new(S.p, m, 6)) end)
end)
H.waitUntil(14000, function()
    local g = S.g.pistol
    local m = g and g.mags[2]
    return m == nil or (m:getCurrentAmmoCount() >= 6 and not H.busy())
end, function(ok)
    H.stop(); H.speed(1)
    local g = S.g.pistol
    local m = g and g.mags[2]
    if not m then return end
    Q.say("the second magazine holds " .. tostring(m:getCurrentAmmoCount()) .. " after the game's own loading (6 asked)")
    if not ok then Q.skip("loading a magazine to the end", "the game's action did not reach 6 rounds in 14 s") end
end)
H.checkAll("magazine loaded by the game's action", "pistol")
-- the game's own reload: the best magazine in, a round racked
Q.step(2, function()
    local g = S.g.pistol
    if not g then return end
    H.speed(2)
    pcall(ISReloadWeaponAction.BeginAutomaticReload, S.p, g.gun)
end)
H.waitUntil(12000, function()
    local g = S.g.pistol
    return g == nil or (g.gun:isContainsClip() and g.gun:isRoundChambered() and not H.busy())
end, function(ok)
    H.stop(); H.speed(1)
    local g = S.g.pistol
    if not g then return end
    if not ok then
        Q.skip("the pistol's reload through the game's own action", "no magazine in and a round chambered after 12 s (magazine in " .. tostring(g.gun:isContainsClip()) .. "); the gun is loaded by hand to go on")
        if not g.gun:isContainsClip() then
            g.gun:setContainsClip(true)
            g.gun:setCurrentAmmoCount(10)
            local m = g.mags[1]
            if m and m:getContainer() then m:getContainer():Remove(m) end
        end
        if g.gun:getCurrentAmmoCount() > 0 and not g.gun:isRoundChambered() then
            g.gun:setRoundChambered(true)
            g.gun:setCurrentAmmoCount(g.gun:getCurrentAmmoCount() - 1)
        end
    end
end)
H.checkAll("pistol reloaded", "pistol")

-- ===================================================================== 3. aim: pinned windows stay, unpinned roll at once
Q.step(4, function()
    local x, y = H.awaySpot()
    S.away = { x = x, y = y }
    H.pointer(x, y)
    H.aimOn()
end)
H.waitUntil(1500, function() return S.p:isAiming() end, function(ok)
    S.aiming = ok
    if not ok then Q.skip("aiming", "the character would not hold an aim from the script (setIsAiming); the aim and live-fire scenes are skipped") end
end)
Q.waitMs(700)
Q.step(1, function()
    if not S.aiming then return end
    local c, w = RT.cw(), RT.ww()
    Q.check(not H.rolled(c) and not H.rolled(w), "aiming with both windows pinned: they stay open", "Character rolled " .. tostring(H.rolled(c)) .. ", World rolled " .. tostring(H.rolled(w)))
    RT.bounds(Q, "aiming, the windows pinned")
    H.pinAll(false)
    S.tUnpin = H.now()
end)
H.waitUntil(1500, function() return not S.aiming or (H.rolled(RT.cw()) and H.rolled(RT.ww())) end, function(ok)
    if not S.aiming then return end
    local c, w = RT.cw(), RT.ww()
    Q.check(ok, "aiming, unpinned, the pointer away: both windows roll up at once (well under the 2 s they take without aim)",
        "after " .. (H.now() - (S.tUnpin or H.now())) .. " ms: Character rolled " .. tostring(H.rolled(c)) .. ", World rolled " .. tostring(H.rolled(w)))
    RT.bounds(Q, "aiming, the windows rolled")
end)
-- a zombie 5 tiles ahead, shot at with the windows rolled
H.queueSpawn(1, 5, "pistol")
H.queuePulls("pistol", 1, 5, 5, 0)
Q.step(2, function()
    if S.aiming and not S.noFire and (S.fired.pistol or 0) == 0 and S.pulls > 0 then
        S.noFire = true
        Q.skip("live fire", "after " .. S.pulls .. " pulls of the game's attack hook no round left the pistol (aiming " .. tostring(S.p:isAiming()) .. ", attack started " .. tostring(S.p:isAttackStarted()) .. "); the kills go through the game's own Hit instead")
    end
end)
H.queueFinish("pistol", 1, "Firearm", "pistol")
Q.step(4, function()
    H.aimOff()
    H.pinAll(true)
    H.showAll()
    local c = RT.cw()
    if c then H.pointer(c:getAbsoluteX() + math.floor(c:getWidth() / 2), c:getAbsoluteY() + math.floor(c:getHeight() / 2)) end
end)
H.waitUntil(2500, function() return not H.rolled(RT.cw()) and not H.rolled(RT.ww()) end, function(ok)
    Q.check(ok, "aim let go and the windows pinned: both come back", "Character rolled " .. tostring(H.rolled(RT.cw())) .. ", World rolled " .. tostring(H.rolled(RT.ww())))
    H.pointer(nil)
    RT.bounds(Q, "after the pistol's shots")
end)
H.checkAll("after the pistol's shots", "pistol")
H.checkKills("pistol kill", "Firearm")

-- ===================================================================== 4. a jam, the wheel, the magazine out, an empty click
Q.step(3, function()
    local g = S.g.pistol
    if not g then return end
    g.gun:setJammed(true)
    Q.say("NOTE the pistol is jammed now: ZeD's pouch, card and facts have no word for a jam (the game's tooltip says Jammed); only the firearm wheel offers Unjam")
end)
H.checkAll("pistol jammed", "pistol")
Q.step(2, function()
    if not S.g.pistol then return end
    S.wheelOk = H.try("the firearm wheel opened on a jammed pistol", H.wheelOpen)
end)
Q.step(12, function()
    local g = S.g.pistol
    local m = H.wheel()
    if not (g and S.wheelOk and m) then return end
    local i, s = H.sliceWith(m, getText("IGUI_FirearmRadial_Unjam"))
    Q.check(m:isReallyVisible(), "the firearm wheel is on screen for the jammed pistol", "drawn by ZeD " .. tostring(m._zed) .. ", slices " .. #(m.slices or {}))
    Q.check(i ~= nil and not ZeD.Wheel.isOff(s), "the wheel offers Unjam for the jammed pistol, and it can be chosen")
    RT.bounds(Q, "the firearm wheel")
    if not i then H.wheelShut(); return end
    H.speed(2)
    local ok, x, y = H.try("the wheel's own aim at Unjam", H.towards, m, i)
    if ok then H.try("a press on Unjam", function() m:onMouseDown(x, y) end) end
    S.unjamAsked = true
end)
H.waitUntil(7000, function() local g = S.g.pistol; return g == nil or not S.unjamAsked or (not g.gun:isJammed() and not H.busy()) end, function(ok)
    H.stop(); H.speed(1); H.wheelShut()
    local g = S.g.pistol
    if not g then return end
    if S.unjamAsked then Q.check(not g.gun:isJammed(), "Unjam chosen on ZeD's wheel clears the jam (the game's own rack)", "jammed " .. tostring(g.gun:isJammed())) end
    g.gun:setJammed(false)
    Q.check(not (H.wheel() and H.wheel():isReallyVisible()), "the wheel is gone after the choice")
end)
H.checkAll("pistol unjammed", "pistol")
-- the magazine out through the game's own action
Q.step(2, function()
    local g = S.g.pistol
    if not g then return end
    H.speed(2)
    pcall(function() ISTimedActionQueue.add(ISEjectMagazine:new(S.p, g.gun)) end)
end)
H.waitUntil(7000, function() local g = S.g.pistol; return g == nil or (not g.gun:isContainsClip() and not H.busy()) end, function(ok)
    H.stop(); H.speed(1)
    if S.g.pistol and not ok then Q.skip("the magazine ejected", "the game's eject did not finish in 7 s") end
end)
H.checkAll("magazine ejected", "pistol")
-- nothing in it at all: a click
Q.step(2, function()
    local g = S.g.pistol
    if not g then return end
    g.gun:setRoundChambered(false)
    g.gun:setCurrentAmmoCount(0)
    H.call1(g.gun, "setSpentRoundChambered", false)
    H.aimOn()
end)
Q.waitMs(400)
Q.step(1, function()
    local g = S.g.pistol
    if not g or not S.aiming or S.p:isDead() then return end
    local ok, err = pcall(ISReloadWeaponAction.attackHook, S.p, 0, g.gun)
    Q.say("an empty pistol's click: hook ok " .. tostring(ok) .. (ok and "" or (" " .. tostring(err))) .. ", weapon empty flag " .. tostring(H.call0(S.p, "isRangedWeaponEmpty")))
end)
Q.waitMs(600)
Q.step(1, function() H.aimOff() end)
H.checkAll("empty pistol clicked", "pistol")

-- ===================================================================== 5. the shotgun: shells one by one, stopped, windows shut and opened
Q.step(3, function() H.closeCard() end)
H.queueCard("shotgun", "shotgun")
Q.step(4, function() H.hold(S.g.shotgun) end)
H.checkAll("shotgun held empty", "shotgun")
Q.step(2, function()
    local g = S.g.shotgun
    if not g then return end
    H.speed(2)
    pcall(ISReloadWeaponAction.BeginAutomaticReload, S.p, g.gun)
end)
H.waitUntil(5000, function() local g = S.g.shotgun; return g == nil or g.gun:getCurrentAmmoCount() >= 2 end, function() end)
Q.step(1, function()
    H.stop()
    RT.pairShut()
end)
Q.step(8, function()
    Q.check(not RT.isOpen(), "the windows shut in the middle of a reload")
    RT.pairOpen()
end)
H.waitUntil(2500, function() return RT.isOpen() end, function(ok)
    Q.check(ok, "the windows open again after the stopped reload")
    H.pinAll(true)
    RT.bounds(Q, "the windows opened again in the middle of a reload")
end)
H.checkAll("shotgun reload stopped part way", "shotgun")
Q.step(2, function()
    local g = S.g.shotgun
    if not g then return end
    pcall(ISReloadWeaponAction.BeginAutomaticReload, S.p, g.gun)
end)
H.waitUntil(14000, function()
    local g = S.g.shotgun
    return g == nil or ((g.gun:getCurrentAmmoCount() >= g.gun:getMaxAmmo() or H.count(g.key) == 0) and not H.busy())
end, function(ok)
    H.stop(); H.speed(1)
    local g = S.g.shotgun
    if not g then return end
    Q.say("the shotgun holds " .. H.rounds(g) .. " of " .. tostring(g.gun:getMaxAmmo()) .. ", " .. H.count(g.key) .. " shells carried")
    if H.rounds(g) == 0 then
        Q.skip("the shotgun's reload through the game's own action", "no shell went in after 14 s; four are put in by hand to go on")
        g.gun:setCurrentAmmoCount(3); g.gun:setRoundChambered(true)
    elseif not g.gun:isRoundChambered() and g.gun:getCurrentAmmoCount() > 0 then
        g.gun:setRoundChambered(true)
        g.gun:setCurrentAmmoCount(g.gun:getCurrentAmmoCount() - 1)
    end
end)
H.checkAll("shotgun loaded", "shotgun")
-- shot at with the windows pinned open and the card on the gun
Q.step(3, function() if S.aiming then H.aimOn() end end)
Q.waitMs(500)
H.queueSpawn(2, 4, "shotgun")
H.queuePulls("shotgun", 2, 4, 3, 0)
H.queueFinish("shotgun", 2, "Firearm", "shotgun")
Q.step(3, function() H.aimOff(); H.stop() end)
H.checkAll("after the shotgun's shots", "shotgun")
H.checkKills("shotgun kill", "Firearm")

-- ===================================================================== 6. the rifle: a full magazine in, shots, racked by hand
Q.step(3, function()
    local g = S.g.rifle
    if not g then return end
    H.hold(g)
    local m = g.mags[1]
    if m then m:setCurrentAmmoCount(m:getMaxAmmo()) end
end)
H.checkAll("rifle held, a full magazine carried", "rifle")
Q.step(2, function()
    local g = S.g.rifle
    if not g then return end
    H.speed(2)
    pcall(ISReloadWeaponAction.BeginAutomaticReload, S.p, g.gun)
    RT.worldTab("loot")
end)
H.waitUntil(12000, function()
    local g = S.g.rifle
    return g == nil or (H.rounds(g) > 0 and g.gun:isRoundChambered() and not H.busy())
end, function(ok)
    H.stop(); H.speed(1)
    local g = S.g.rifle
    if not g then return end
    if not ok then
        Q.skip("the rifle's reload through the game's own action", "no round chambered after 12 s (rounds " .. H.rounds(g) .. "); loaded by hand to go on")
        if g.mag and not g.gun:isContainsClip() then
            g.gun:setContainsClip(true)
            local m = g.mags[1]
            if m and m:getContainer() then m:getContainer():Remove(m) end
        end
        g.gun:setCurrentAmmoCount(math.max(1, g.gun:getMaxAmmo() - 1)); g.gun:setRoundChambered(true)
    end
end)
H.checkAll("rifle loaded", "rifle")
Q.step(3, function() if S.aiming then H.aimOn() end end)
Q.waitMs(500)
H.queueSpawn(3, 8, "rifle")
H.queuePulls("rifle", 3, 8, 3, 0)
H.queueFinish("rifle", 3, "Firearm", "rifle")
Q.step(3, function() H.aimOff(); H.stop() end)
H.checkAll("after the rifle's shots", "rifle")
H.checkKills("rifle kill", "Firearm")
-- racked by hand, as the rack key does: the chambered round comes back to the inventory
Q.step(2, function()
    local g = S.g.rifle
    if not g then return end
    H.speed(2)
    pcall(ISReloadWeaponAction.OnPressRackButton, S.p, g.gun, false)
end)
Q.waitMs(400)
H.waitUntil(6000, function() return not H.busy() end, function() H.stop(); H.speed(1) end)
H.checkAll("rifle racked by hand", "rifle")

-- ===================================================================== 7. hands changed every frame; empty hands
for i = 1, 12 do
    Q.step(1, function()
        local order = { "pistol", "shotgun", "rifle", "bat2", "none", "pistol2" }
        local k = order[i - math.floor((i - 1) / #order) * #order]
        H.hold(k ~= "none" and S.g[k] or nil)
    end)
end
Q.step(1, function() H.hold(S.g.rifle) end)
H.checkAll("after a dozen hand changes, the rifle held", "rifle")
Q.step(1, function() H.hold(nil) end)
H.waitUntil(1500, function() return H.box("ammo") == nil end, function(ok)
    Q.check(ok, "empty hands: the pouch leaves the belt")
    RT.bounds(Q, "empty hands")
end)

-- ===================================================================== 8. broken things, and a gun that leaves the game in the hand
Q.step(3, function()
    local g = S.g.bat
    if not g then Q.skip("the broken bat", "no bat was given"); return end
    g.gun:setCondition(0)
    H.hold(g)
end)
Q.waitMs(500)
Q.step(1, function()
    local g = S.g.bat
    if not g then return end
    Q.check(H.box("ammo") == nil, "a broken bat in the hands: no pouch on the belt", "broken " .. tostring(g.gun:isBroken()))
    local ok, a = H.try("the belt's ammo reading on a bat", S.B.ammo, S.p)
    if ok then Q.check(a == nil, "a bat has no ammo state") end
    H.try("the item facts of a broken bat", ZeD.itemFacts, g.gun)
    if ZeD.ItemFactsPanel and ZeD.ItemFactsPanel.factsFor then H.try("the facts panel of a broken bat", ZeD.ItemFactsPanel.factsFor, g.gun, S.pn) end
    if S.aiming and not S.noFire and not S.p:isDead() then
        H.aimOn()
        pcall(ISReloadWeaponAction.attackHook, S.p, 1, g.gun)
    end
end)
Q.waitMs(900)
Q.step(1, function() H.aimOff(); H.closeCard() end)
Q.step(3, function()
    local g = S.g.pistol2
    if not g then return end
    g.gun:setContainsClip(true); g.gun:setCurrentAmmoCount(3); g.gun:setRoundChambered(true)
    g.gun:setCondition(0)
end)
H.queueCard("pistol2", "broken pistol")
Q.step(4, function() H.hold(S.g.pistol2) end)
H.checkAll("a broken pistol held, 3+1 in it", "pistol2")
Q.step(2, function()
    local g = S.g.pistol2
    if not g then return end
    S.gone = g.gun
    S.goneCard = H.cardOn(g.gun)
    -- the gun leaves the game while it is held and its card is open (used up, broken down, taken by a mod)
    S.p:setPrimaryHandItem(nil); S.p:setSecondaryHandItem(nil)
    local c = g.gun:getContainer()
    if c then c:Remove(g.gun) end
    S.g.pistol2 = nil
end)
H.waitUntil(2000, function() return H.box("ammo") == nil and not H.cardOn(S.gone) end, function()
    if not S.gone then return end
    Q.check(H.box("ammo") == nil, "the held gun taken out of the game: the pouch leaves the belt")
    local h = H.hud()
    local c = h and h._ammo
    Q.check(not (c and c.a and c.a.gun == S.gone), "the pouch keeps no state of the gun that is gone")
    if S.goneCard then
        Q.check(not H.cardOn(S.gone), "the card lets go of the gun that left the game", "drawer item still the gun: " .. tostring(RT.cw() and RT.cw()._drawerItem == S.gone))
    else
        Q.skip("the card lets go of the gun that left the game", "its card was not open")
    end
    RT.bounds(Q, "a held gun taken out of the game")
end)

-- ===================================================================== 9. melee: swings and shoves at a zombie one tile ahead
Q.step(3, function()
    H.closeCard()
    local g = S.g.bat2
    if not g then Q.skip("melee", "no bat was given"); return end
    H.hold(g)
    if S.aiming then H.aimOn() end
end)
Q.waitMs(500)
H.queueSpawn(4, 1.3, "bat")
H.queuePulls("bat2", 4, 1.3, 2, 1)
Q.step(2, function() if S.aiming and S.g.bat2 then H.call1(S.p, "setDoShove", true) end end)
H.queuePulls("bat2", 4, 1.3, 2, 0)
Q.step(2, function() H.call1(S.p, "setDoShove", false) end)
H.queuePulls("bat2", 4, 1.3, 2, 1)
H.queueFinish("bat2", 4, "Blunt", "bat")
Q.step(3, function()
    H.aimOff(); H.stop()
    Q.check(H.box("ammo") == nil, "a bat in the hands after the fight: still no pouch on the belt")
end)
H.checkKills("bat kill", "Blunt")

-- ===================================================================== 10. the Journal and Identity tabs after the fight
Q.step(3, function()
    Q.check(RT.charTab("journal"), "the Journal tab is on the strip")
end)
H.waitUntil(1500, function() local c = RT.cw(); return c ~= nil and c._activeTab == "journal" end, function(ok)
    Q.check(ok, "the Journal tab opens after the fight")
    RT.bounds(Q, "the Journal after the fight")
    H.totals("the Journal open")
    RT.charTab("identity")
end)
H.waitUntil(1500, function() local c = RT.cw(); return c ~= nil and c._activeTab == "identity" end, function(ok)
    Q.check(ok, "the Identity tab opens after the fight")
    RT.bounds(Q, "the Identity tab after the fight")
    H.totals("the Identity tab open")
end)

-- ===================================================================== the put-back
Q.mark()
Q.step(3, function()
    H.aimOff()
    H.pointer(nil)
    Events.OnTick.Remove(H.aimTick)
    H.stop(); H.speed(1); H.wheelShut()
    H.closeCard()
    local p = S.p
    local W = S.was
    pcall(function() p:setPrimaryHandItem(nil); p:setSecondaryHandItem(nil) end)
    Q.say("put back: zombies taken away " .. H.sweepZombies())
end)
Q.waitMs(2500)
Q.step(1, function()
    Q.say("put back: corpses taken away " .. H.sweepBodies())
    H.sweepBlood()
end)
Q.waitMs(1500)
Q.step(1, function()
    local p = S.p
    local W = S.was
    local nb = H.sweepBodies()
    local nz = H.sweepZombies()
    if nb + nz > 0 then Q.say("put back: a second pass took " .. nb .. " corpses and " .. nz .. " zombies") end
    local n = H.sweepItems() + H.sweepFloor()
    Q.say("put back: " .. n .. " guns, magazines and rounds taken out")
    pcall(function()
        if W.p1 and W.p1:getContainer() then p:setPrimaryHandItem(W.p1) end
        if W.p2 and W.p2:getContainer() then p:setSecondaryHandItem(W.p2) end
    end)
    -- the kills as they were
    pcall(function() p:setZombieKills(W.engine) end)
    p:getModData().ZeD_Kills = W.kd
    if W.ammoBox ~= nil and ZeD.Settings and ZeD.Settings.ammoBoxOption then pcall(function() ZeD.Settings.ammoBoxOption:setValue(W.ammoBox) end) end
    if W.unlimited then H.call1(p, "setUnlimitedAmmo", true) end
    H.bloodBack(); H.statBack(); H.xpBack()
end)
Q.step(2, function()
    local W = S.was
    -- the list's stacks and scroll, the pins, the tabs, the windows
    local c = H.content()
    if c and c._expandedStacks then
        for k, v in pairs(S.stackWas) do
            if v ~= false then c._expandedStacks[k] = v else c._expandedStacks[k] = nil end
        end
        if S.scrollWas and c._scroll and c._scroll.setScrollPos then pcall(function() c._scroll:setScrollPos(S.scrollWas) end) end
        c._selectedItems = {}
        c._lastClickedItem = nil
    end
    local md = S.p:getModData()
    md.ZeD_WinPinned = W.pins or {}
    local t = md.ZeD_WinPinned
    for _, pair in ipairs({ { RT.cw(), "char" }, { RT.ww(), "world" } }) do
        local win, k = pair[1], pair[2]
        if win and win._halves and S.HV and S.HV.setPin then
            local i, d = t[k .. "Inv"], t[k .. "Tabs"]
            if i == nil and d == nil then i, d = t[k] == true, t[k] == true end
            pcall(S.HV.setPin, win, "inv", i == true)
            pcall(S.HV.setPin, win, "drawer", d == true)
        end
    end
    H.showAll()
    if W.charTab then RT.charTab(W.charTab) end
    if W.worldTab then RT.worldTab(W.worldTab) end
end)
Q.step(6, function()
    local W = S.was
    if W.open then RT.pairOpen() else RT.pairShut() end
    if ZEDQA_HOME then pcall(ZEDQA_HOME, "bx_cmb") end
    local left = 0
    for ft, had in pairs(S.had) do
        local n0 = 0
        for _ in pairs(had) do n0 = n0 + 1 end
        left = left + math.max(0, H.count(ft) - n0)
    end
    local okB, bodies = pcall(H.bodiesNear, 14)
    local extra = 0
    for _, b in ipairs(okB and bodies or {}) do if not S.bodies0[b.body] then extra = extra + 1 end end
    Q.say("put back: kills " .. tostring(S.p:getZombieKills()) .. " (found " .. tostring(W.engine) .. "), things of the given types left over " .. left .. ", corpses left over " .. extra
        .. ", aiming " .. tostring(S.p:isAiming()) .. ", speed " .. tostring(getGameSpeed()))
    Q.say("pulls of the trigger and swings through the game's attack hook: " .. S.pulls .. "; deaths " .. S.kills)
end)
Q.start()
