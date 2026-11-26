-- ZeDUI/tools/qa/mt_tab.lua  (Nov 26 2026, QA; tag mt_tab): the World window's Vehicle (Mechanics) tab, the gamut
-- sweep, in the style of the Cooking and Crafting sweeps (ck_tab.lua, cr_tab.lua) with the car staging of
-- bx_vehicles.lua. Its spec is the map ZeDUI/qa/audits/2026-11-26_map_mechanics.md (section 5's suspicions M1-M18,
-- section 3's states, section 4's gaps). Run after zedqa_prelude.lua and rt_kit.lua (mt.txt). grep "ZEDQA mt_tab".
-- Each suspicion single player can stage is proved or cleared with values: PASS when ZeD does what the game does,
-- FAIL with the evidence when it does not; where the game's own path has the same gap (M9's stop mid-chain) both are
-- run and the pair is a check that ZeD does no worse than the game, plus a NOTE.
-- How it drives the tab: a click is the tab's own handler at the zone's middle (ZeD.MechanicsTab.onClick, the World
-- window's way); a zone that cannot be clicked where it is drawn (scrolled out of its column, or no width at the half
-- card) is pressed as the pad's A presses it, said once. The pad's presses go through FocusManager's QA hook and its own
-- dispatch on the World window (RT.pad + RT.padDown, focus by focusWhere in worldTabContent), the input mode locked to
-- the controller and put back as found. The game's answers are asked of the game itself: the part's condition and the
-- item on or off it (VehiclePart), the engine at 0, the materials (FixingManager's countUses) and the item's repaired
-- count (getHaveBeenRepaired), the game's own checks (canInstallPart, canUninstallPart, Vehicles.lua's tests,
-- ISVehicleMechanics' menu conditions, the fixer rules of ISInventoryPaneContextMenu, VehicleUtils.calculate-
-- InstallationSuccess and the rolls in ISInstallVehiclePart / ISUninstallVehiclePart), the game's queue
-- (ISTimedActionQueue) and the game's event (OnMechanicActionDone); never ZeD's code under test. What the tab drew is
-- read from the draw itself (the words the tab panel drew this frame, the footer's buttons, the question, the NEEDS
-- lines), each by its own place so two rows never stand for one another.
-- The cars: ZEDQA_HOME first (the Irvington drag strip, 925.5,13040.5), a sedan (Base.CarNormal) by the prelude's one
-- spawn (ZEDQA_CAR_WAIT: the physics seen awake once, then repaired, fuelled, battery full and its key in his bag in the
-- same tick, ZEDQA_CAR_PREP), a second sedan 5 or 6 tiles beside it (addVehicleDebug on a real square, its physics
-- latched by ZEDQA_CAR_READY, then prepared in that tick), later a livestock trailer. Every car within about 20 tiles of
-- home. Each case starts from the cars repaired, every door and window shut, the looks ended.
-- Cases (M<n> = the map's suspicion; mouse and pad where the verb has a press):
--   1 M1   Take engine parts on a 90% engine: the pad's A asks first with the focus on No and A on No takes nothing;
--          the mouse's Yes runs the game's action: the engine's condition after it (the game sets 0) against the
--          question's words and the game's own tooltip (Tooltip_vehicle_TakeEnginePartsWarning)
--   2 M2   a second press while the chain is queued: Repair twice by the mouse and by the pad (A A) on a part at 40
--          with materials for two (the repairs queued, the game's repaired count and the materials spent); Uninstall
--          the battery twice by the mouse during the walk (the band during the walk, the uninstalls queued, the hood
--          shut at the end); Install a battery twice by the pad (the installs queued, the hood shut at the end)
--   3 M3   Install's pick: a tire off the car, two spares of one type and one condition (one in his bag, one in a
--          crate), the crate's row picked (mouse, then pad on the other side), then a third spare (90) brought near:
--          the tire the game put on against the one picked; the tie's order over 30 frames. Pictures mt_full_<WxH>
--          (the overview) and mt_install_<WxH> (a part card with its install picks)
--   4 M4   Repair on a part at 100% with materials: the footer's main (accent) verb; pressed by the mouse and by the
--          pad: the materials the game spent, the repaired count, the condition gained
--   5 M5   the pad's A on a row, then A again: a 60% tire with a pump, jack and lug wrench (what the game queued
--          against the card's main verb); the Engine at 50 with engine parts (the question it asks). Picture
--          mt_pad_<WxH> (the pad's mark on a verb)
--   6 M6   (run last) seated: a verb pressed from the driver's seat of a parked car (the game's menu refuses a seated
--          player, ISVehicleMechanics.doPartContextMenu), Open window on the second car's window while he sits in the
--          first, Uninstall pressed while driving on the cruise control (the game's own regulator; SKIP with the speed
--          when it gives under 15 km/h): what the press queued (ISStopVehicle, the exit, the walk)
--   7 M7   a look (the game's walk and look at Mechanics 0, timed), the Loot tab as to fetch the jack from the trunk,
--          back to the Vehicle tab: still looked at (the game's mechanic flag, the hood), else the time to look again
--   8 M8   the half card (220): the drawer held in by the World window's width cap (cr_tab's way) at 1280x800 (a FAIL
--          when it cannot be held there; a NOTE at other sizes): the right column's width, the list inside the tab,
--          a tire's install picks inside the tab, the footer's buttons against the card's verbs; Install from the
--          footer with the picks unseen (which spare the game put on); the pad's A on a row there. Picture
--          mt_half_<WxH>
--   9 M9   the battery's uninstall chain (its screwdriver brought from a crate) stopped while the uninstall runs: by
--          the pad's B with nothing open on the tab, by the band's Cancel (mouse), and the game's own path (its
--          handler, then its own stop) as the baseline: the queue, the hood, the screwdriver (in hand, in the bags)
--   10 M10 the NEEDS rows against the game's own checks (hidden actions "all" where a grey verb must show): the
--          battery with the engine running; a profession put on the muffler's uninstall table (a modded car, put
--          back); a brake missing under its tire (the game's InstallTest ignores requireUninstalled, the brake then
--          installed with the tire on); a fixer short of its uses (the game's menu, its getRequiredItems); a door the
--          game repairs only off the car (Tooltip_RepairableUninstalled); Install with no spare near, folded and all
--   11 M11 the pad's X on a row: the game's part menu, where it opens with the pointer hidden, then B; X and
--          right-click while paused (the game's menu returns at speed 0); seated (SKIP in a debug game: the game opens
--          its menu seated there)
--   12 M12 paused (game speed 0): Inflate by the mouse and the pad, Smash and its Yes: what the game's queue holds
--          (cleared before the game runs again; the window and the pressure checked untouched)
--   13 M13 a tire taken off the car inside the tab's cache time and Uninstall pressed (what the game did, what was
--          said, how soon the card shows it missing); two cars of one model: their tabs' names as he steps between
--          them; two cars looked at (the game's mechanic flag on each); a car driven off by another player (SKIP: MP)
--   14 M14 claims and a server's flash (SKIP: a server and a second player); single player: the game's
--          OnMechanicActionDone after an install against the tab's Done flash
--   15 M15 a livestock trailer: the game's Check Animals in reach (no walk queued), its parts wait for Inspect, the
--          pinned trailer kept at 5.5 tiles and dropped at 7; the hitch and unhitch SKIP (the game's hitch needs the
--          trailer backed to a car's hitch point)
--   16 M16 Overall against the game's recalculGeneralCondition (two places) and its nodisplay parts; a part with an
--          item type and no install table (SKIP when the car has none); the failure share shown beside the success
--          bar against the game's odds of damage for an uninstall and an install at Mechanics 0; the worn count at 60
--          and 61 against the rows' color bands
--   17 M17 the words: the step-before words in the run's language (other languages: SKIP, a game started in each; a
--          NOTE of which UI.json files carry the keys, read through the game's mod file reader); the Smash question's
--          part name against the game's; the NotNow line (M10); the flash's words (the game's Done, ZeD's Failed)
--   M18 is test drift (FEATURE_MAP rows, zedqa_mech79's guarded presses of a question that no longer comes): no case.
--   every case: no Lua error over it; put back exactly
-- Puts back: every car spawned (the prelude's removal, a tick after he is out), every thing given or made (the bags,
-- the floor, the crates), the muffler's table, his Mechanics and every other skill level (XP drift a NOTE), the
-- Basic Mechanics recipe as found, the traits (none changed: checked), his hands, the hidden-actions setting, the
-- Vehicle tab's sort and folds, the World window's tab and width cap (the drawer and the half card), the Character
-- window's tab, the layout, the pad lock, the pointer, the theme and the text size (not changed: checked), the draw
-- watchers and the event listener, the game's hidden mechanics window's car, the debug mechanics cheat, instant
-- actions, game speed 1, the clock, where he stood, god mode and invincible as found (on for the run: a car drives).

if not (RT and RT.make) then
    print("ZEDQA mt_tab ERR rt_kit.lua did not run first")
    print("ZEDQA mt_tab VERDICT FAIL 1")
    print("ZEDQA mt_tab DONE")
    return
end
local Q = RT.make("mt_tab")
Q.maxMs = 2200000                    -- (the runner gives this script 2400 s: the put-back runs before that)
local S = { p = RT.p, pn = RT.pn, found = {}, back = {}, made = {}, caseMade = {}, objs = {}, shots = {}, errs = 0,
            dead = false, xp = {}, halo = {}, mad = {}, cars = {}, keep = {}, pt = {}, texts = {}, said = {} }
local H = {}
local C = {}
S.MT = ZeD and ZeD.MechanicsTab
S.F = RT.focus()
S.CRATE = "carpentry_01_16"
S.NEAR = { { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }
S.TOOLS = { "Base.Jack", "Base.LugWrench", "Base.Wrench", "Base.Screwdriver", "Base.TirePump" }
S.MATS = { "Base.Screws", "Base.SheetMetal", "Base.SmallSheetMetal", "Base.BlowTorch", "Base.EngineParts", "Base.CarBattery" }
S.RECIPES = { "Basic Mechanics", "Intermediate Mechanics" }
S.TRAITS = { "MECHANICS", "MECHANICS2", "HANDY" }
S.VERB_ACT = { ISInflateTire = "inflate", ISDeflateTire = "deflate", ISUninstallVehiclePart = "uninstall",
               ISInstallVehiclePart = "install", ISFixVehiclePartAction = "fix", ISRepairEngine = "repairEngine",
               ISTakeEngineParts = "takeParts", ISSmashWindow = "smash", ISOpenCloseVehicleWindow = "openWindow" }

if not (S.p and S.MT and ZeD_WorldWindow and ZeD.Molecules) then
    Q.check(false, "the player, ZeD's Vehicle tab and the World window are loaded")
    Q.start()
    return
end

-- ===================================================================== small helpers
function H.errN() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function H.step(n, fn) Q.step(n, function() if S.dead then return end; fn() end) end
function H.note(s) Q.say("NOTE " .. tostring(s)) end
-- time, not frames: cond asked every drawn frame until it holds, at most ms; fn(ok)
function H.wait(ms, cond, fn)
    local st = {}
    Q.waitFor(1, 4000000, function()
        if S.dead then return true end
        local now = getTimestampMs()
        st.t = st.t or now
        local ok, r = pcall(cond)
        if ok and r then st.ok = true; return true end
        return now - st.t >= ms
    end, function() if S.dead then return end; fn(st.ok == true) end)
end
function H.speed(n) if ZEDQA_SPEED then pcall(ZEDQA_SPEED, n) else pcall(setGameSpeed, n) end end
function H.list(t, max)
    local o = {}
    for i, v in ipairs(t or {}) do
        if max and i > max then o[#o + 1] = "..."; break end
        o[#o + 1] = tostring(v)
    end
    return (#o > 0) and table.concat(o, ", ") or "none"
end
function H.n1(x) if type(x) ~= "number" then return tostring(x) end; return string.format("%.1f", x) end
function H.n2(x) if type(x) ~= "number" then return tostring(x) end; return string.format("%.2f", x) end
function H.screen() local w, h = 0, 0; pcall(function() w, h = RT.core:getScreenWidth(), RT.core:getScreenHeight() end); return math.floor(w), math.floor(h) end
function H.sizeTag() local w, h = H.screen(); return w .. "x" .. h end
function H.zopt(id) local zo = nil; pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end); return zo and zo.dict and zo.dict[id] or nil end
function H.optVal(o) local v = nil; if o then pcall(function() v = o:getValue() end) end; return v end
function H.goTo(x, y, z)
    pcall(function()
        S.p:setX(x); S.p:setY(y); S.p:setZ(z)
        S.p:setLastX(x); S.p:setLastY(y); S.p:setLastZ(z)
    end)
end
function H.home() local f = S.found; if f.pos then H.goTo(f.pos.x, f.pos.y, f.pos.z) end; if f.dir then pcall(function() S.p:setDir(f.dir) end) end end
function H.zcall(fn)
    local ok, err = pcall(fn)
    if not ok then S.errs = S.errs + 1; S.zerr = S.zerr or tostring(err) end
    return ok
end
function H.has(s, sub) return type(s) == "string" and type(sub) == "string" and sub ~= "" and string.find(s, sub, 1, true) ~= nil end
function H.cased(s) local o = tostring(s or ""); pcall(function() o = ZeD.textCase(o) end); return o end
function H.lang() local l = "?"; pcall(function() l = tostring(Translator.getLanguage():name()) end); return l end
function H.debug() local d = false; pcall(function() d = isDebugEnabled() and true or false end); return d end

-- ===================================================================== the timed-action queue (the game's)
function H.queue() local q = nil; pcall(function() q = ISTimedActionQueue.getTimedActionQueue(S.p) end); return (q and q.queue) or {} end
function H.qlen() return #H.queue() end
function H.head() local a = H.queue()[1]; return a and tostring(a.Type) or "none" end
function H.qcount(ty) local n = 0; for _, a in ipairs(H.queue()) do if a.Type == ty then n = n + 1 end end; return n end
function H.qkinds() local o = {}; for _, a in ipairs(H.queue()) do o[#o + 1] = tostring(a.Type) end; return H.list(o, 14) end
function H.qstop() pcall(function() ISTimedActionQueue.clear(S.p) end) end
-- the first vehicle verb the game's queue holds (by its timed action), nil when none
function H.qverb()
    for _, a in ipairs(H.queue()) do
        local v = S.VERB_ACT[tostring(a.Type)]
        if v then return v, tostring(a.Type) end
    end
    return nil, nil
end
-- queue: wait for the game's queue to empty (speed 2: the walks still run there), at most ms
function H.waitQ(T, ms)
    H.step(1, function()
        if T.off then return end
        T.qt0 = getTimestampMs()
        T.kinds = T.kinds or H.qkinds()
        H.speed(2)
    end)
    H.wait(ms, function() return T.off or (H.qlen() == 0 and getTimestampMs() - (T.qt0 or 0) > 500) end, function(ok)
        H.speed(1)
        if T.off then return end
        T.qDone = ok
        if not ok then H.note(T.L .. ": the game's queue did not empty in " .. ms .. " ms (" .. H.qkinds() .. "): cleared"); H.qstop() end
    end)
end

-- ===================================================================== things
function H.isItem(it) local ok = false; if it ~= nil then pcall(function() ok = instanceof(it, "InventoryItem") end) end; return ok end
function H.ft(it) local s = "?"; if H.isItem(it) then pcall(function() s = tostring(it:getFullType()) end) end; return s end
function H.nm(it) local s = "nothing"; if H.isItem(it) then pcall(function() s = tostring(it:getDisplayName()) end) end; return s end
function H.where(it) local c = nil; if H.isItem(it) then pcall(function() c = it:getContainer() end) end; return c end
function H.ctype(c) local t = "none"; if c then pcall(function() t = tostring(c:getType()) end) end; return t end
function H.icond(it) local c = nil; if H.isItem(it) then pcall(function() c = it:getCondition() end) end; return c end
function H.inv() return S.p:getInventory() end
function H.known(ft) local ok = false; if ft then pcall(function() ok = getScriptManager():FindItem(ft) ~= nil end) end; return ok end
function H.walkInv(inv, out, depth)
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        out[#out + 1] = it
        if depth < 4 and instanceof(it, "InventoryContainer") then
            local sub = nil
            pcall(function() sub = it:getInventory() end)
            if sub then H.walkInv(sub, out, depth + 1) end
        end
    end
end
function H.all() local out = {}; pcall(H.walkInv, H.inv(), out, 0); return out end
function H.count(ft) local n = 0; for _, it in ipairs(H.all()) do if H.ft(it) == ft then n = n + 1 end end; return n end
function H.mark(it)
    if not H.isItem(it) then return nil end
    pcall(function() it:getModData().ZeDQA_spawned = true end)
    S.made[#S.made + 1] = it
    S.caseMade[#S.caseMade + 1] = it
    return it
end
function H.give(ft) if not ft then return nil end; local it = nil; pcall(function() it = H.inv():AddItem(ft) end); return H.mark(it) end
function H.giveTo(inv, ft) local it = nil; if inv and ft then pcall(function() it = inv:AddItem(ft) end) end; return H.mark(it) end
-- a thing kept for the whole run (the car keys): never swept between cases, taken away at the end
function H.keep(it)
    if not H.isItem(it) then return end
    pcall(function() it:getModData().ZeDQA_spawned = true end)
    S.keep[it] = true
    S.made[#S.made + 1] = it
end
function H.loose(it)
    if not H.isItem(it) then return end
    pcall(function() if S.p:getPrimaryHandItem() == it then S.p:setPrimaryHandItem(nil) end end)
    pcall(function() if S.p:getSecondaryHandItem() == it then S.p:setSecondaryHandItem(nil) end end)
end
function H.removeItem(it)
    if not H.isItem(it) then return end
    H.loose(it)
    pcall(function()
        local wo = it:getWorldItem()
        if wo then
            local sq = wo:getSquare()
            if sq then pcall(function() sq:transmitRemoveItemFromSquare(wo) end) end
            pcall(function() wo:removeFromWorld() end)
            pcall(function() wo:removeFromSquare() end)
            pcall(function() it:setWorldItem(nil) end)
        end
    end)
    pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
end
function H.gone(it) return H.where(it) == nil end
function H.sweepNew()
    local n = 0
    for _, it in ipairs(H.all()) do
        if not S.found.inv0[it] and not S.keep[it] then H.removeItem(it); n = n + 1 end
    end
    return n
end
function H.hands()
    local f = S.found
    if not f.hands then return end
    pcall(function()
        local a, b = f.hands.p, f.hands.s
        S.p:setPrimaryHandItem((a and S.p:getInventory():containsRecursive(a)) and a or nil)
        S.p:setSecondaryHandItem((b and S.p:getInventory():containsRecursive(b)) and b or nil)
    end)
end
-- his own things of the types the cases use are set aside, so the game's handlers take only what a case gave
function H.stashTypes(set)
    local kept = 0
    for _, it in ipairs(H.all()) do
        if set[H.ft(it)] and S.found.inv0[it] and not S.found.stashed[it] then
            local c, free = nil, false
            pcall(function()
                c = it:getContainer()
                free = it:getAttachedSlot() == -1 and not it:isEquipped() and not S.p:isEquippedClothing(it)
                    and S.p:getPrimaryHandItem() ~= it and S.p:getSecondaryHandItem() ~= it
            end)
            if c and free and pcall(function() c:Remove(it) end) then
                S.stash = S.stash or {}
                S.stash[#S.stash + 1] = { it = it, c = c }
                S.found.stashed[it] = true
            else
                kept = kept + 1
            end
        end
    end
    return #(S.stash or {}), kept
end
function H.unstash()
    local lost = 0
    for _, s in ipairs(S.stash or {}) do
        pcall(function() if s.it:getContainer() == nil then s.c:AddItem(s.it) end end)
        if H.where(s.it) == nil then lost = lost + 1 end
    end
    S.stash = {}
    return lost
end

-- ===================================================================== skills, recipes, traits
function H.xpSnap()
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
        for _, r in ipairs(S.xp) do
            if math.abs(xp:getXP(r.perk) - r.xp) > 0.001 or S.p:getPerkLevel(r.perk) ~= r.lvl then
                grew = grew + 1
                pcall(function()
                    S.p:setPerkLevelDebug(r.perk, r.lvl)
                    xp:setXPToLevel(r.perk, r.lvl)
                    local now = xp:getXP(r.perk)
                    if math.abs(r.xp - now) > 0.001 then xp:AddXPNoMultiplier(r.perk, r.xp - now) end
                end)
                local nx, nl = xp:getXP(r.perk), S.p:getPerkLevel(r.perk)
                if math.abs(nx - r.xp) > 0.01 or nl ~= r.lvl then
                    left = left + 1
                    S.xpLeftText = (S.xpLeftText or "") .. tostring(r.perk) .. " level " .. tostring(nl) .. " (found " .. tostring(r.lvl) .. ") xp "
                        .. string.format("%.2f", nx) .. " (found " .. string.format("%.2f", r.xp) .. "); "
                end
            end
        end
    end)
    pcall(function() SyncXp(S.p) end)
    return grew, left
end
function H.mech(n) pcall(function() S.p:setPerkLevelDebug(Perks.Mechanics, n) end) end
function H.mechLvl() local l = 0; pcall(function() l = S.p:getPerkLevel(Perks.Mechanics) end); return l end
function H.perkSet(name, n) pcall(function() S.p:setPerkLevelDebug(Perks.FromString(name), n) end) end
function H.recipeKnown(r) local k = false; pcall(function() k = S.p:isRecipeActuallyKnown(r) and true or false end); return k end
function H.recipeInList(r) local k = false; pcall(function() k = S.p:getKnownRecipes():contains(r) and true or false end); return k end
function H.learn(r) if not H.recipeKnown(r) then pcall(function() S.p:learnRecipe(r) end) end end
function H.recipesBack()
    for _, r in ipairs(S.RECIPES) do
        local was = S.found.recipes and S.found.recipes[r]
        local now = H.recipeInList(r)
        if was == false and now then pcall(function() S.p:getKnownRecipes():remove(r) end) end
        if was == true and not now then pcall(function() S.p:learnRecipe(r) end) end
    end
end
function H.hasTrait(key)
    local has = false
    pcall(function() local ct = CharacterTrait[key]; if ct then has = S.p:hasTrait(ct) and true or false end end)
    return has
end

-- ===================================================================== cars (the game's own state)
function H.live(v)
    local found = false
    if not v then return false end
    pcall(function()
        local it = getCell():getVehicles():iterator()
        while it:hasNext() do if it:next() == v then found = true end end
    end)
    return found
end
function H.dist(v)
    local d = 999
    pcall(function() local dx, dy = v:getX() - S.p:getX(), v:getY() - S.p:getY(); d = math.sqrt(dx * dx + dy * dy) end)
    return d
end
function H.part(v, id) local p = nil; if v then pcall(function() p = v:getPartById(id) end) end; return p end
function H.cond(v, id) local c = nil; pcall(function() c = H.part(v, id):getCondition() end); return c end
function H.item(v, id) local it = nil; pcall(function() it = H.part(v, id):getInventoryItem() end); return it end
function H.setCond(v, id, c)
    pcall(function()
        local part = H.part(v, id)
        part:setCondition(c)
        pcall(function() local it = part:getInventoryItem(); if it then it:setCondition(c) end end)
        v:transmitPartCondition(part)
    end)
end
-- the part's item taken off by hand (staging): the item handed back, in no container
function H.takeItem(v, id)
    local it = nil
    pcall(function()
        local part = H.part(v, id)
        it = part:getInventoryItem()
        if it then part:setInventoryItem(nil); v:transmitPartItem(part) end
    end)
    return it
end
function H.doorOpen(v, id) local o = false; pcall(function() o = H.part(v, id):getDoor():isOpen() and true or false end); return o end
function H.hoodOpen(v) return H.doorOpen(v, "EngineDoor") end
function H.setDoor(v, id, open) pcall(function() H.part(v, id):getDoor():setOpen(open) end) end
function H.running(v) local r = false; pcall(function() r = v:isEngineRunning() and true or false end); return r end
function H.kmh(v) local s = 0; pcall(function() s = math.abs(v:getCurrentSpeedKmHour()) end); return s end
function H.mechFlag(v) local f = nil; pcall(function() f = v:isMechanicUIOpen() and true or false end); return f end
function H.carNear(x, y, r)
    local near = false
    pcall(function()
        local it = getCell():getVehicles():iterator()
        while it:hasNext() do
            local o = it:next()
            if math.abs(o:getX() - x) < r and math.abs(o:getY() - y) < r then near = true end
        end
    end)
    return near
end
function H.clearAt(x, y)
    local ok = false
    pcall(function()
        local sq = getCell():getGridSquare(x, y, 0)
        ok = sq ~= nil and sq:getChunk() ~= nil and sq:isFree(false) and not sq:HasTree()
            and sq:getVehicleContainer() == nil and sq:getRoom() == nil
    end)
    return ok
end
function H.boxClear(x0, y0, x1, y1)
    for y = y0, y1 do
        for x = x0, x1 do if not H.clearAt(x, y) then return false end end
    end
    return true
end
-- the full type each part held at the spawn, so a part a case emptied is filled again
function H.ptypes(v)
    local t = {}
    pcall(function()
        for i = 0, v:getPartCount() - 1 do
            local part = v:getPartByIndex(i)
            local it = part:getInventoryItem()
            if it then t[part:getId()] = it:getFullType() end
        end
    end)
    S.pt[v] = t
end
function H.fillMissing(v)
    local t = S.pt[v] or {}
    pcall(function()
        for i = 0, v:getPartCount() - 1 do
            local part = v:getPartByIndex(i)
            local ft = t[part:getId()]
            if ft and part:getInventoryItem() == nil then
                pcall(function()
                    local it = instanceItem(ft)
                    if it then part:setInventoryItem(it); v:transmitPartItem(part) end
                end)
            end
        end
    end)
end
-- a car made whole again for the next case: every part on and at 100, the tank and the battery full, tires full, every
-- door and window shut, the engine off (when he is not in it), the cruise control off
function H.fix(v)
    if not (v and H.live(v)) then return end
    H.fillMissing(v)
    pcall(function() v:repair() end)
    pcall(function() local g = v:getPartById("GasTank"); g:setContainerContentAmount(g:getContainerCapacity()) end)
    pcall(function() local b = v:getPartById("Battery"); local it = b and b:getInventoryItem(); if it then it:setCurrentUsesFloat(1.0) end end)
    pcall(function() if v:isRegulator() then v:setRegulator(false) end end)
    pcall(function() if v:isEngineRunning() and S.p:getVehicle() ~= v then v:shutOff() end end)
    local n = 0
    pcall(function() n = v:getPartCount() end)
    for i = 0, n - 1 do
        pcall(function()
            local part = v:getPartByIndex(i)
            local d = part:getDoor()
            if d and d:isOpen() then d:setOpen(false) end
            local w = part:getWindow()
            if w and w:isOpenable() and w:isOpen() then w:setOpen(false) end
            if part:isContainer() and part:getContainerContentType() == "Air" and part:getInventoryItem() then
                part:setContainerContentAmount(part:getContainerCapacity())
            end
        end)
    end
end

-- ===================================================================== objects laid round him (ck_tab's crate)
function H.sqAt(dx, dy)
    local sq = nil
    pcall(function() sq = getCell():getGridSquare(math.floor(S.p:getX()) + dx, math.floor(S.p:getY()) + dy, math.floor(S.p:getZ())) end)
    return sq
end
function H.freeSq(dx, dy)
    local sq = H.sqAt(dx, dy)
    local good = false
    pcall(function()
        good = sq ~= nil and sq:getFloor() ~= nil and sq:isFree(false) and not sq:HasTree()
            and sq:getObjects():size() <= 1 and sq:getWorldObjects():size() == 0 and sq:getVehicleContainer() == nil
    end)
    return good and sq or nil
end
function H.used(sq) for _, c in ipairs(S.objs) do if c.sq == sq and not c.removed then return true end end; return false end
function H.keepObj(o, sq, what, kind) local c = { obj = o, sq = sq, what = what, kind = kind }; S.objs[#S.objs + 1] = c; return c end
function H.mkCrate()
    for _, d in ipairs(S.NEAR) do
        local sq = H.freeSq(d[1], d[2])
        if sq and not H.used(sq) then
            local o = nil
            pcall(function() o = IsoObject.new(getCell(), sq, S.CRATE) end)
            if o then
                pcall(function() o:createContainersFromSpriteProperties() end)
                pcall(function() sq:AddTileObject(o) end)
                local c = H.keepObj(o, sq, "a crate (" .. S.CRATE .. " at " .. sq:getX() .. "," .. sq:getY() .. ")", "tile")
                pcall(function() c.inv = o:getContainer() end)
                if c.inv then pcall(function() c.inv:setExplored(true) end); return c end
                H.rmObj(c)
            end
        end
    end
    return nil
end
function H.rmObj(c)
    if not (c and c.obj) or c.removed then return end
    local o = c.obj
    pcall(function() local ct = o:getContainer(); if ct then ct:removeAllItems() end end)
    local sq = c.sq
    pcall(function() sq = o:getSquare() or c.sq end)
    if sq then
        pcall(function() sq:transmitRemoveItemFromSquare(o) end)
        pcall(function() if o:getObjectIndex() >= 0 then sq:RemoveTileObject(o) end end)
        pcall(function() sq:getObjects():remove(o) end)
        pcall(function() sq:RecalcProperties() end)
    end
    pcall(function() o:removeFromWorld() end)
    pcall(function() o:removeFromSquare() end)
    c.removed = true
end
function H.objLeft(c)
    if not (c and c.obj) then return false end
    local left = false
    pcall(function() left = c.sq:getObjects():contains(c.obj) end)
    return left
end
function H.lootRefresh()
    pcall(function() local lp = getPlayerLoot(S.pn); if lp and lp.refreshBackpacks then lp:refreshBackpacks() end end)
    pcall(function() triggerEvent("OnContainerUpdate") end)
    pcall(function() local w = RT.ww(); if w then w._containersDirty = true end end)
end
-- new world items round him (anything not there at the start), taken away
function H.snapFloor(set, cx, cy, cz)
    for y = cy - 8, cy + 8 do
        for x = cx - 8, cx + 8 do
            local sq = getCell():getGridSquare(x, y, cz)
            local wos = sq and sq:getWorldObjects()
            for i = 0, (wos and wos:size() or 0) - 1 do set[wos:get(i)] = true end
        end
    end
end
-- the ground snapped at the start (home, then round each car as it came): only there is anything new taken away
function H.snapAt(x, y)
    S.floorAt = S.floorAt or {}
    local c = { x = math.floor(x), y = math.floor(y), z = 0 }
    S.floorAt[#S.floorAt + 1] = c
    pcall(H.snapFloor, S.found.floor0, c.x, c.y, c.z)
end
function H.sweepFloor()
    local now, n = {}, 0
    for _, c in ipairs(S.floorAt or {}) do pcall(H.snapFloor, now, c.x, c.y, c.z) end
    for wo in pairs(now) do
        if not S.found.floor0[wo] then
            pcall(function() local sq = wo:getSquare(); if sq then sq:transmitRemoveItemFromSquare(wo) end end)
            pcall(function() wo:removeFromWorld() end)
            pcall(function() wo:removeFromSquare() end)
            n = n + 1
        end
    end
    return n
end

-- ===================================================================== the Vehicle tab (read from its draw)
function H.ms() local w = RT.ww(); return w and w._mech end
function H.z(id) local s = H.ms(); return s and s.byId and s.byId[id] or nil end
function H.lit(id) local z = H.z(id); return z ~= nil and not z.disabled end
function H.onTab() local w = RT.ww(); return w ~= nil and w._activeTab == "vehicle" end
function H.insp(v) local i = false; pcall(function() i = S.MT.isInspected(v) and true or false end); return i end
function H.curV() local s = H.ms(); local e = s and s.vehicles and s.vehicles[s.idx or 1]; return e and e.vehicle or nil end
function H.listed(v) local s = H.ms(); for _, e in ipairs((s and s.vehicles) or {}) do if e.vehicle == v then return true end end; return false end
function H.ids(pre)
    local o = {}
    local s = H.ms()
    for _, z in ipairs((s and s.zones) or {}) do
        if pre == nil or string.sub(tostring(z.id), 1, #pre) == pre then o[#o + 1] = tostring(z.id) .. (z.disabled and "(grey)" or "") end
    end
    return o
end
function H.tabText()
    local w, s = RT.ww(), H.ms()
    local v = H.curV()
    return "World tab " .. tostring(w and w._activeTab) .. ", shown car " .. tostring(v and v:getId()) .. " looked at " .. tostring(v and H.insp(v))
        .. ", card " .. tostring(s and s.card) .. ", " .. #((s and s.zones) or {}) .. " zones"
end
-- what the tab drew in the last frame: { s, x, y }; texts inside a zone's rows (its y range, its x span)
function H.textsIn(z)
    local o = {}
    if not z then return o end
    for _, t in ipairs(S.texts or {}) do
        if t.y >= z.y - 1 and t.y < z.y + z.h and (z.w <= 0 or (t.x >= z.x - 2 and t.x <= z.x + z.w + 2)) then o[#o + 1] = t.s end
    end
    return o
end
function H.drew(sub) for _, t in ipairs(S.texts or {}) do if H.has(t.s, sub) then return t end end; return nil end
function H.drewExact(s) for _, t in ipairs(S.texts or {}) do if t.s == s then return t end end; return nil end
-- the value the tab drew on the same line as a label (drawLabelValue's right side)
function H.valueBeside(label)
    local lt = H.drewExact(label)
    if not lt then return nil end
    local best = nil
    for _, t in ipairs(S.texts or {}) do
        if t ~= lt and math.abs(t.y - lt.y) <= 3 and t.x > lt.x and (best == nil or t.x > best.x) then best = t end
    end
    return best and best.s or nil
end
function H.textsLike(sub, max) local o = {}; for _, t in ipairs(S.texts or {}) do if H.has(t.s, sub) then o[#o + 1] = t.s end end; return H.list(o, max or 8) end
-- the footer's buttons as drawn: { label, id, variant, disabled }; its main (accent) verb
function H.footText()
    local o = {}
    for _, b in ipairs(S.band or {}) do o[#o + 1] = tostring(b.id) .. (b.variant == "primary" and "*" or "") .. (b.disabled and "(grey)" or "") end
    return H.list(o)
end
function H.mainVerb() for _, b in ipairs(S.band or {}) do if b.variant == "primary" then return b.id end end; return nil end
-- a press on a zone: a click at its middle through the tab's own handler; where it cannot be clicked (no width at
-- the half card, or scrolled out of its column) it is pressed as the pad's A presses it, said once per zone
function H.click(id, what)
    local w, s = RT.ww(), H.ms()
    local z = s and s.byId and s.byId[id]
    if not (w and z) then return false end
    local mx, my = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    local c = z.clip
    local inClip = (not c) or (mx >= c.x and mx < c.x + c.w and my >= c.y and my < c.y + c.h)
    if (z.w or 0) <= 0 or (z.h or 0) <= 0 or not inClip then
        if not S.said[id] then
            S.said[id] = true
            H.note(tostring(what) .. ": " .. id .. " cannot be clicked where it is drawn (" .. math.floor(z.x) .. "+" .. math.floor(z.w) .. " px): pressed as the pad's A presses it")
        end
        H.zcall(z.fn)
    else
        H.zcall(function() S.MT.onClick(w, mx, my) end)
    end
    return true
end
function H.rclick(id)
    local w, z = RT.ww(), H.z(id)
    if not (w and z) then return false end
    H.zcall(function() S.MT.onRightClick(w, z.x + math.floor(math.max(z.w, 2) / 2), z.y + math.floor(z.h / 2)) end)
    return true
end
-- the car the tab shows: the tab for v pressed when another is shown
function H.showCar(v)
    local s = H.ms()
    if not s then return false end
    for i, e in ipairs(s.vehicles or {}) do
        if e.vehicle == v and s.idx ~= i then
            if not H.click("mech:veh:" .. i, "the car's tab") then H.zcall(function() S.MT.vehicleTabFn(s, i)() end) end
        end
    end
    return H.curV() == v
end
function H.lookedAt(v)
    if not (v and H.onTab() and H.insp(v)) then return false end
    if H.curV() ~= v then H.showCar(v); return false end
    local s = H.ms()
    return s ~= nil and #(s.zones or {}) > 0
end
-- queue: the car T[key] looked at the game's way (its own walk and look, ISVehicleMenu.onMechanic) and shown on the
-- tab; when it is already looked at the tab only shows it. 40 s, then the tab opened as the look's end opens it.
-- optional: no such car skips only this look (T.skipLook), not the case
function H.lookQ(T, key, optional)
    key = key or "v"
    H.step(2, function()
        T.skipLook = nil
        if T.off then return end
        local v = T[key]
        if not (v and H.live(v)) then
            if optional then T.skipLook = true; return end
            T.off = true; Q.skip(T.L, "no car for the case"); return
        end
        RT.pairOpen()
        T.lookT0 = getTimestampMs()
        if H.insp(v) and H.onTab() then return end
        H.speed(2)
        pcall(ISVehicleMenu.onMechanic, S.p, v)
    end)
    H.wait(40000, function() return T.off or T.skipLook or H.lookedAt(T[key]) end, function(ok)
        H.speed(1)
        if T.off or T.skipLook then return end
        T.lookMs = getTimestampMs() - (T.lookT0 or 0)
        if not ok then
            H.qstop()
            H.note(T.L .. ": the game's walk and look did not end in 40 s (" .. H.tabText() .. "): the tab opened as the look's end opens it")
            H.zcall(function() S.MT.openFromAction(S.p, T[key], nil) end)
        end
    end)
    H.wait(5000, function() return T.off or T.skipLook or H.lookedAt(T[key]) end, function(ok)
        if T.off or T.skipLook then return end
        if not Q.check(ok, T.L .. ": the car is looked at and the Vehicle tab shows it", H.tabText()) then T.off = true end
    end)
end
-- queue: the part's card opened by a click on its row (id: a part id, or T's key holding one; unless: a key of T that,
-- when set, skips this card)
function H.cardQ(T, id, unless)
    H.step(2, function()
        T.skipCard = nil
        if T.off then return end
        if unless and T[unless] then T.skipCard = true; return end
        T.cardId = T[id] or id
        local s = H.ms()
        if not s then return end
        s.sortOpen, s.confirm = nil, nil
        s.collapsed = {}
        T.rowClicked = nil
    end)
    -- (the row is clicked once it is drawn: a folded section draws it a frame after the folds are opened)
    H.wait(3000, function()
        local s = H.ms()
        if T.off or T.skipCard then return true end
        if s and s.card ~= T.cardId and not T.rowClicked and H.z("mech:row:" .. T.cardId) then
            T.rowClicked = true
            H.click("mech:row:" .. T.cardId, T.L)
        end
        return s ~= nil and s.card == T.cardId and H.z("mech:row:" .. T.cardId) ~= nil
    end, function(ok)
        if T.off or T.skipCard then return end
        if not Q.check(ok, T.L .. ": a click on the " .. tostring(T.cardId) .. " row opens its card", "card " .. tostring(H.ms() and H.ms().card)
            .. "; rows " .. H.list(H.ids("mech:row:"), 30)) then T.off = true end
    end)
end
function H.toLoot() local w = RT.ww(); if w and w._activeTab ~= "loot" then RT.worldTab("loot") end end

-- ===================================================================== the pad (cr_tab's, on the World window)
function H.lockFound()
    local key = nil
    pcall(function()
        local o = H.zopt("inputModeLock")
        local keys = ZeD.Settings.inputLockKeys
        if o and keys then key = keys[o:getValue() or 1] end
    end)
    if key == nil then pcall(function() local md = S.p:getModData().ZeD_Gamepad; key = md and md.inputModeLock end) end
    return key or "auto"
end
function H.padOn()
    local Det = ZeD.Input and ZeD.Input.Detector
    if not (Det and Det.setLockedMode and S.F) then return false end
    if S.lockWas == nil then S.lockWas = H.lockFound() end
    pcall(Det.setLockedMode, "gamepad")
    S.back.pad = true
    local w = RT.ww()
    if w and S.F.claimFocus then pcall(S.F.claimFocus, w) end
    return true
end
function H.padOff()
    if not S.back.pad then return end
    S.back.pad = nil
    for _, b in ipairs({ "A", "B", "X", "Y" }) do RT.pad(b, nil) end
    pcall(function() S.F.releaseFocus(S.pn) end)
    local Det = ZeD.Input and ZeD.Input.Detector
    pcall(function()
        Det.setLockedMode(nil)
        if S.lockWas == "kbm" or S.lockWas == "gamepad" then Det.setLockedMode(S.lockWas) end
    end)
end
function H.stops()
    local w = RT.ww()
    for _, z in ipairs((w and w._focusRing) or {}) do if z.zone == "worldTabContent" then return z.elements or {} end end
    return {}
end
function H.stopIds() local o = {}; for _, e in ipairs(H.stops()) do o[#o + 1] = tostring(e.id) end; return H.list(o, 20) end
function H.focusedId() local el = nil; pcall(function() el = S.F.getFocusedElement(RT.ww()) end); return el and el.id or nil end
function H.focusEl(id)
    local w = RT.ww()
    if not (w and S.F and S.F.focusWhere and id) then return false end
    pcall(S.F.claimFocus, w)
    local e = nil
    pcall(function() e = S.F.focusWhere(w, "worldTabContent", function(el) return el.id == id end) end)
    return e ~= nil
end
-- a tap queued on the World window: down through the QA hook and FocusManager's dispatch, up 4 frames later, then the
-- hook lets go (nothing is pressed when gate says no)
function H.tap(name, joy, gate)
    local st = {}
    H.step(1, function()
        local w = RT.ww()
        if not w then return end
        if gate and not gate() then return end
        st.on = true
        RT.pad(name, true)
        if joy then RT.padDown(Joypad[joy], w) end
    end)
    H.step(4, function() if st.on then RT.pad(name, false) end end)
    H.step(4, function() if st.on then RT.pad(name, nil) end end)
end
function H.tapA(gate) H.tap("A", "AButton", gate) end
function H.tapB(gate) H.tap("B", "BButton", gate) end
function H.tapX(gate) H.tap("X", "XButton", gate) end

-- ===================================================================== the draw and the words, watched (on for the run)
-- S.mtRect: the tab's rectangle as the window draws it; S.texts: every word the tab panel drew last frame; S.band:
-- the footer's buttons; S.qNow / S.qLast: the footer's question; S.needs: the NEEDS lines; S.halo: words over his
-- head; S.mad: the game's OnMechanicActionDone for him; S.flashSeen: the Done or Failed band words seen
function H.wrapOn()
    if S.w0 then return end
    local W = { render = S.MT.render, qb = ZeD.Molecules.drawQuestionBand, nl = ZeD.Molecules.drawNeedsLine, band = ZeD.Molecules.drawBand }
    S.w0 = W
    W.renderFn = function(panel, win, x, y, w, h)
        S.mtRect = { x = x, y = y, w = w, h = h, t = getTimestampMs() }
        local rec, needs = {}, {}
        S.recNeeds, S.qFrame, S.bandFrame = needs, nil, nil
        local ownD, ownR = nil, nil
        pcall(function() ownD = rawget(panel, "drawText"); ownR = rawget(panel, "drawTextRight") end)
        local baseD, baseR = panel.drawText, panel.drawTextRight
        if baseD then panel.drawText = function(self, text, tx, ty, ...) rec[#rec + 1] = { s = tostring(text), x = tx or 0, y = ty or 0 }; return baseD(self, text, tx, ty, ...) end end
        if baseR then panel.drawTextRight = function(self, text, tx, ty, ...) rec[#rec + 1] = { s = tostring(text), x = tx or 0, y = ty or 0, right = true }; return baseR(self, text, tx, ty, ...) end end
        S.inMT = true
        local ok, res = pcall(W.render, panel, win, x, y, w, h)
        S.inMT = false
        panel.drawText = ownD
        panel.drawTextRight = ownR
        S.texts, S.needs, S.band = rec, needs, S.bandFrame
        S.qNow = S.qFrame
        if S.qFrame then S.qLast = S.qFrame end
        for _, t in ipairs(rec) do if t.s == S.doneWord or t.s == S.failWord then S.flashSeen = t.s end end
        -- (the flash is drawn by Atoms.drawProgressBand, not the panel's drawText: read the tab's own flash while it
        -- is up, win._mech.flash { ok, untilMs }, as the frame draws it)
        pcall(function()
            local f = win and win._mech and win._mech.flash
            if f and getTimestampMs() < (f.untilMs or 0) then S.flashSeen = f.ok and S.doneWord or S.failWord end
        end)
        if not ok then S.tabErrs = (S.tabErrs or 0) + 1; S.tabErrLast = res; error(res, 0) end
        return res
    end
    W.qbFn = function(panel, x, y, w, question, verb, opts, ...)
        if S.inMT then S.qFrame = tostring(question) end
        return W.qb(panel, x, y, w, question, verb, opts, ...)
    end
    W.nlFn = function(panel, x, y, w, text, ...)
        if S.inMT and S.recNeeds then S.recNeeds[#S.recNeeds + 1] = tostring(text) end
        return W.nl(panel, x, y, w, text, ...)
    end
    W.bandFn = function(panel, x, y, w, spec, ...)
        if S.inMT and type(spec) == "table" and type(spec.buttons) == "table" then
            local o = {}
            for _, b in ipairs(spec.buttons) do o[#o + 1] = { label = b.label, id = b.id, variant = b.variant, disabled = b.disabled, verb = b.verb } end
            S.bandFrame = o
        end
        return W.band(panel, x, y, w, spec, ...)
    end
    S.MT.render = W.renderFn
    ZeD.Molecules.drawQuestionBand = W.qbFn
    ZeD.Molecules.drawNeedsLine = W.nlFn
    ZeD.Molecules.drawBand = W.bandFn
    W.halo = {}
    if HaloTextHelper then
        for _, k in ipairs({ "addText", "addBadText", "addGoodText" }) do
            local orig = HaloTextHelper[k]
            if orig then
                local fn = function(pl, text, ...)
                    S.halo[#S.halo + 1] = { text = tostring(text), t = getTimestampMs() }
                    return orig(pl, text, ...)
                end
                W.halo[k] = { orig = orig, fn = fn }
                HaloTextHelper[k] = fn
            end
        end
    end
    S.madFn = function(chr, success)
        if chr == S.p then S.mad[#S.mad + 1] = { ok = success and true or false, t = getTimestampMs() } end
    end
    pcall(function() Events.OnMechanicActionDone.Add(S.madFn) end)
end
function H.wrapOff()
    local W = S.w0
    if not W then return end
    if S.MT.render == W.renderFn then S.MT.render = W.render end
    if ZeD.Molecules.drawQuestionBand == W.qbFn then ZeD.Molecules.drawQuestionBand = W.qb end
    if ZeD.Molecules.drawNeedsLine == W.nlFn then ZeD.Molecules.drawNeedsLine = W.nl end
    if ZeD.Molecules.drawBand == W.bandFn then ZeD.Molecules.drawBand = W.band end
    for k, e in pairs(W.halo or {}) do if HaloTextHelper[k] == e.fn then HaloTextHelper[k] = e.orig end end
    if S.madFn then pcall(function() Events.OnMechanicActionDone.Remove(S.madFn) end); S.madFn = nil end
    S.w0 = nil
end
function H.wrapped()
    local W = S.w0
    if not W then return true end
    return S.MT.render == W.render and ZeD.Molecules.drawBand == W.band
end
function H.saidSince(t0)
    local o = {}
    for _, h in ipairs(S.halo) do if h.t >= (t0 or 0) then o[#o + 1] = h.text end end
    return o
end

-- ===================================================================== settings, pointer, pictures, the half card
function H.hidden(key)
    local o = ZeD.Settings and ZeD.Settings.hiddenActionsOption
    local i = nil
    for k, v in ipairs((ZeD.Settings and ZeD.Settings.hiddenActionsKeys) or {}) do if v == key then i = k end end
    if o and i then pcall(function() o:setValue(i) end); S.back.hidden = true end
end
function H.hiddenNow() local v = "?"; pcall(function() v = ZeD.Settings.hiddenActions() end); return v end
function H.hiddenBack()
    if not S.back.hidden then return end
    S.back.hidden = nil
    local o = ZeD.Settings and ZeD.Settings.hiddenActionsOption
    if o and S.found.hiddenIdx then pcall(function() o:setValue(S.found.hiddenIdx) end) end
end
function H.park(on)
    if on then
        if not S.parked then
            S.parked = { mx = getMouseX, my = getMouseY }
            getMouseX = function() return -9000 end
            getMouseY = function() return -9000 end
        end
        pcall(function() Mouse.setCursorVisible(false) end)
        return
    end
    if S.parked then
        getMouseX, getMouseY = S.parked.mx, S.parked.my
        S.parked = nil
        pcall(function() Mouse.setCursorVisible(true) end)
    end
end
function H.shot(name, what, gate)
    Q.step(1, function() if not S.dead and (gate == nil or gate()) then H.park(true) end end)
    Q.step(4, function()
        if S.dead or not (gate == nil or gate()) then H.park(false); return end
        local file = name .. ".png"
        local ok, e = pcall(function() getCore():TakeFullScreenshot(file) end)
        if ok then S.shots[#S.shots + 1] = file; H.note("picture Zomboid/Screenshots/" .. file .. " | " .. what)
        else H.note("the picture " .. name .. " was not taken: " .. tostring(e)) end
        H.park(false)
    end)
    Q.waitMs(1200)
end
function H.drawerW() local w = RT.ww(); return math.floor((w and w._drawerEffW) or 0) end
function H.isHalf() local w = RT.ww(); return w ~= nil and math.abs((w._drawerEffW or 0) - ZeD.T.px(220)) <= 1 end
function H.isFull() local w = RT.ww(); return w ~= nil and math.abs((w._drawerEffW or 0) - ZeD.T.px(480)) <= 1 end
-- queue: the drawer held in to the half card (cr_tab's way: the World window's width cap made too narrow for the full
-- card); T.half true when it holds
function H.halfOn(T)
    H.step(2, function()
        T.half = nil
        if T.off then return end
        local w = RT.ww()
        if w and not H.isHalf() then
            if S.back.maxW == nil then S.back.maxW = { v = w._maxWinW } end
            S.layoutTouched = true
            w._maxWinW = ZeD.T.px(700)
        end
        T.hs = { last = -1, n = 0 }
    end)
    H.wait(5000, function()
        if T.off then return true end
        local e = H.drawerW()
        if e == T.hs.last then T.hs.n = T.hs.n + 1 else T.hs.last, T.hs.n = e, 0 end
        return T.hs.n >= 6 and H.isHalf()
    end, function(ok)
        if T.off then return end
        T.half = ok
    end)
end
function H.halfBack()
    if not S.back.maxW then return end
    local w = RT.ww()
    if w then w._maxWinW = S.back.maxW.v end
    S.back.maxW = nil
end

-- ===================================================================== a case's start and end
-- stand beside the car on the side away from the second car (west by default)
function H.atCar(v)
    if not (v and H.live(v)) then return end
    local side = -1
    if S.vB and S.vB ~= v and H.live(S.vB) and S.vB:getX() < v:getX() then side = 1 end
    if S.vB == v and S.vA and H.live(S.vA) and S.vA:getX() < v:getX() then side = 1 end
    H.goTo(v:getX() + side * 2.6, v:getY() + 0.5, 0)
end
function H.legClean()
    H.speed(1)
    H.qstop()
    H.padOff()
    H.park(false)
    H.tblBack()
    local s = H.ms()
    if s then s.confirm, s.sortOpen, s.card = nil, nil, nil end
    -- (the Loot tab ends every look, and queues the hood shut at the hood: the queue is cleared again below)
    H.toLoot()
    H.qstop()
    pcall(function() if S.p:getVehicle() then local car = S.p:getVehicle(); car:exit(S.p); triggerEvent("OnExitVehicle", S.p) end end)
    for _, it in ipairs(S.caseMade) do H.removeItem(it) end
    S.caseMade = {}
    H.sweepNew()
    H.sweepFloor()
    for i = (S.caseObjs or 0) + 1, #S.objs do H.rmObj(S.objs[i]) end
    S.caseObjs = #S.objs
    H.fix(S.vA)
    H.fix(S.vB)
    H.hands()
    H.lootRefresh()
end
function H.caseStart(T)
    S.caseMade = {}
    S.halo = {}
    S.qLast = nil
    T.mad0 = #S.mad
    H.legClean()
    H.hidden("folded")
    H.mech(10)
    T.v = T.v or S.vA
    if not (T.v and H.live(T.v)) then T.off = true; Q.skip(T.L, S.noCar or "no car"); return false end
    H.atCar(T.v)
    T.t0case = getTimestampMs()
    return true
end
function H.caseEnd(label)
    H.step(2, function()
        H.legClean()
        H.hiddenBack()
        H.halfBack()
        H.home()
    end)
    H.step(10, function()
        local e1 = H.errN()
        Q.check(S.e0 == nil or e1 == nil or e1 == S.e0, label .. ": no Lua error over the case",
            (S.e0 and e1) and ((e1 - S.e0) .. " new") or "the count cannot be read")
        if S.zerr then Q.check(false, label .. ": nothing ZeD ran for the case threw", S.zerr); S.zerr = nil end
        S.e0 = e1
    end)
end

-- ===================================================================== setup and the cars
function S.setup()
    Q.step(1, function()
        local f = S.found
        S.dead = S.p:isDead() and true or false
        if S.dead then Q.check(false, "setup: the character is alive (nothing is run on a dead one)"); return end
        if not (S.F and S.F.focusWhere and ISTimedActionQueue and ISVehicleMenu and ISVehiclePartMenu and ISVehicleMechanics and VehicleUtils) then
            S.dead = true
            Q.check(false, "setup: the pad's focus manager and the game's vehicle code are loaded")
            return
        end
        S.err0 = H.errN()
        S.e0 = S.err0
        if ZEDQA_HOME then pcall(ZEDQA_HOME, "mt_tab") end
        H.speed(1)
        H.qstop()
        f.pos = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
        pcall(function() f.dir = S.p:getDir() end)
        f.pair = RT.isOpen()
        f.hands = { p = S.p:getPrimaryHandItem(), s = S.p:getSecondaryHandItem() }
        f.inv0, f.types, f.stashed, f.floor0 = {}, {}, {}, {}
        for _, it in ipairs(H.all()) do
            f.inv0[it] = true
            local ft = H.ft(it)
            f.types[ft] = (f.types[ft] or 0) + 1
        end
        H.snapAt(f.pos.x, f.pos.y)
        pcall(function() f.tod = getGameTime():getTimeOfDay() end)
        pcall(function() f.inst = S.p:isTimedActionInstantCheat(); S.p:setTimedActionInstantCheat(false) end)
        pcall(function() f.god = S.p:isGodMod() and true or false; S.p:setGodMod(true) end)
        pcall(function() f.invinc = S.p:isInvincible() and true or false; S.p:setInvincible(true) end)
        f.cheat = ISVehicleMechanics.cheat
        ISVehicleMechanics.cheat = false
        pcall(function() f.anywhere = getCore():getDebug() and getDebugOptions():getBoolean("Cheat.Vehicle.MechanicsAnywhere") end)
        f.recipes = {}
        for _, r in ipairs(S.RECIPES) do f.recipes[r] = H.recipeInList(r) end
        f.traits = {}
        for _, k in ipairs(S.TRAITS) do f.traits[k] = H.hasTrait(k) end
        f.base, f.size = ZeD.currentBase, ZeD.currentSize
        f.hiddenIdx = H.optVal(ZeD.Settings and ZeD.Settings.hiddenActionsOption)
        S.lockWas = H.lockFound()
        H.xpSnap()
        f.mech = H.mechLvl()
        pcall(function() local ui = getPlayerMechanicsUI(S.pn); f.mui = { ui = ui, vehicle = ui.vehicle, chr = ui.chr } end)
        RT.pairOpen()
        if ZEDQA_LAYOUT_SNAP then pcall(function() f.layout = ZEDQA_LAYOUT_SNAP() end) end
        local cw, ww = RT.cw(), RT.ww()
        f.ctab, f.wtab = cw and cw._activeTab, ww and ww._activeTab
        f.maxW = ww and ww._maxWinW
        local s = ww and ww._mech
        if s then
            local col = {}
            for k, v in pairs(s.collapsed or {}) do col[k] = v end
            f.mstate = { sort = s.sort, collapsed = col }
            s.sort, s.collapsed = "area", {}
        end
        S.doneWord = getText("UI_mods_Done")
        S.failWord = H.cased(ZeD.tr("UI_ZeD_Veh_Failed"))
        f.recorded = true
        S.back.on = true
        H.wrapOn()
        Q.say("found: at " .. math.floor(f.pos.x) .. "," .. math.floor(f.pos.y) .. ", screen " .. H.sizeTag() .. ", language " .. H.lang()
            .. ", debug " .. tostring(H.debug()) .. ", Mechanics " .. f.mech .. ", hidden actions " .. H.hiddenNow() .. ", input lock " .. tostring(S.lockWas)
            .. ", World tab " .. tostring(f.wtab) .. ", drawer " .. H.drawerW() .. " px, the debug mechanics-anywhere cheat " .. tostring(f.anywhere))
        if f.anywhere then H.note("setup: the game's debug option Cheat.Vehicle.MechanicsAnywhere is on: the game's look takes no walk and 1 tick here") end
        local set = {}
        for _, ft in ipairs(S.TOOLS) do set[ft] = true end
        for _, ft in ipairs(S.MATS) do set[ft] = true end
        local aside, kept = H.stashTypes(set)
        H.note("setup: " .. aside .. " of his own tools and materials of the types used here are set aside" .. (kept > 0 and (", " .. kept .. " worn or held stay") or ""))
        local miss = {}
        for _, ft in ipairs(S.TOOLS) do if not H.known(ft) then miss[#miss + 1] = ft end end
        Q.check(#miss == 0, "setup: every tool type the cases use is known to this game", "unknown: " .. H.list(miss))
    end)
    -- the first car: the prelude's one spawn on the strip (the physics latched, then repaired, fuelled, its key in his
    -- bag in that same tick)
    H.step(2, function()
        if not (ZEDQA_CAR_WAIT and ZEDQA_CAR_PREP and ZEDQA_CAR_READY and ZEDQA_CAR_ENTER and ZEDQA_CAR_AWAY) then
            S.noCar = "the prelude's car helpers are not loaded (zedqa_prelude.lua runs first)"
            return
        end
        ZEDQA_CAR_WAIT("Base.CarNormal", "mt_tab", function(v)
            S.vA = v
            S.cars[#S.cars + 1] = v
            ZEDQA_CAR_KEEP[v] = true
            H.keep(ZEDQA_CAR_PREP(v))
            H.ptypes(v)
            H.snapAt(v:getX(), v:getY())
            S.readyA = true
        end, function(why) S.noCar = why or "no ready car" end, 6000)
    end)
    H.wait(45000, function() return S.readyA or S.noCar ~= nil end, function()
        if not Q.check(S.vA ~= nil, "setup: a sedan spawned on the strip beside him, repaired, its key in his bag", tostring(S.noCar)) then S.noCar = S.noCar or "no car in 45 s" end
        if S.vA then
            local d = H.dist(S.vA)
            Q.say("NOTE the sedan at " .. math.floor(S.vA:getX()) .. "," .. math.floor(S.vA:getY()) .. ", " .. H.n1(d) .. " tiles from him; Mechanics repair level "
                .. tostring(S.vA:getScript():getEngineRepairLevel()))
            if d > 45 then H.note("setup: the car stands more than 45 tiles away") end
        end
    end)
    -- the second car, 5 or 6 tiles beside the first, facing the same way
    H.step(2, function()
        if not S.vA then return end
        local ax, ay = math.floor(S.vA:getX()), math.floor(S.vA:getY())
        for _, dx in ipairs({ 5, -5, 6, -6 }) do
            if not S.bSq and H.boxClear(ax + dx - 1, ay - 3, ax + dx + 1, ay + 3) and not H.carNear(ax + dx + 0.5, ay + 0.5, 3) then
                S.bSq = getCell():getGridSquare(ax + dx, ay, 0)
            end
        end
        if not S.bSq then S.noB = "no clear ground beside the first car"; return end
        local okV, v = pcall(addVehicleDebug, "Base.CarNormal", IsoDirections.N, nil, S.bSq)
        if not (okV and v) then S.noB = "addVehicleDebug gave no second car"; return end
        S.vB0 = v
        S.cars[#S.cars + 1] = v
        if ZEDQA_CAR_KEEP then ZEDQA_CAR_KEEP[v] = true end
    end)
    H.wait(8000, function() return S.noB ~= nil or not S.vA or (S.vB0 ~= nil and ZEDQA_CAR_READY(S.vB0)) end, function(ok)
        if not S.vA then return end
        if S.noB then H.note("setup: no second car (" .. S.noB .. "): its legs are skipped"); return end
        if not ok then S.noB = "the second car's physics never woke in 8 s"; H.note("setup: " .. S.noB); return end
        S.vB = S.vB0
        H.keep(ZEDQA_CAR_PREP(S.vB))
        H.ptypes(S.vB)
        H.snapAt(S.vB:getX(), S.vB:getY())
        Q.say("NOTE the second sedan at " .. math.floor(S.vB:getX()) .. "," .. math.floor(S.vB:getY()) .. ", " .. H.n1(H.dist(S.vB)) .. " tiles from him")
    end)
    H.step(2, function()
        -- his own spares of the types these cars take are set aside too
        local set = {}
        for _, t in pairs(S.pt[S.vA] or {}) do set[t] = true end
        local aside = H.stashTypes(set)
        if aside > 0 then H.note("setup: his own car parts of these cars' types set aside (" .. aside .. " things in all)") end
        H.legClean()
    end)
    Q.waitMs(1000)
end

-- ===================================================================== 1. Take engine parts (M1)
function C.c1()
    local T = { L = "1 M1 Take engine parts" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        if not H.part(T.v, "Engine") then T.off = true; Q.skip(T.L, "the car has no engine part"); return end
        H.setCond(T.v, "Engine", 90)
        H.give("Base.Wrench")
        T.warn = getText("Tooltip_vehicle_TakeEnginePartsWarning")
        T.lvl = T.v:getScript():getEngineRepairLevel()
    end)
    H.lookQ(T)
    H.cardQ(T, "Engine")
    -- the pad: A on Take engine parts asks first, the focus on No; A on No takes nothing
    H.step(3, function()
        if T.off then return end
        T.go = H.padOn() and H.focusEl("mech:verb:takeParts")
        Q.check(T.go, T.L .. " (pad): the pad's focus lands on Take engine parts", "on " .. tostring(H.focusedId()) .. "; stops " .. H.stopIds())
    end)
    H.tapA(function() return T.go and not T.off end)
    Q.waitMs(500)
    H.step(2, function()
        if T.off or not T.go then return end
        local s = H.ms()
        Q.check(s ~= nil and s.confirm == "takeParts" and H.focusedId() == "mech:confirm:no", T.L .. " (pad): A on Take engine parts asks first, the focus on No",
            "asking " .. tostring(s and s.confirm) .. ", focus " .. tostring(H.focusedId()) .. ", the question: " .. tostring(S.qNow))
    end)
    H.tapA(function() return T.go and not T.off and H.focusedId() == "mech:confirm:no" end)
    Q.waitMs(500)
    H.step(2, function()
        H.padOff()
        if T.off or not T.go then return end
        Q.check(H.qlen() == 0 and H.cond(T.v, "Engine") == 90, T.L .. " (pad): A on No takes nothing (the game's queue empty, the engine at 90)",
            H.qkinds() .. ", engine " .. tostring(H.cond(T.v, "Engine")))
    end)
    -- the mouse: Take engine parts, then Yes
    H.step(3, function() if not T.off then S.qLast = nil; H.click("mech:verb:takeParts", T.L) end end)
    H.wait(2500, function() return T.off or H.z("mech:confirm:yes") ~= nil end, function(ok)
        if T.off then return end
        T.q = S.qLast
        if not Q.check(ok, T.L .. ": a click on Take engine parts asks in the footer", "the question " .. tostring(T.q) .. "; footer " .. H.footText()) then T.off = true; return end
        T.parts0 = H.count("Base.EngineParts")
        H.click("mech:confirm:yes", T.L)
    end)
    H.step(2, function() if not T.off then T.kinds = H.qkinds() end end)
    H.waitQ(T, 90000)
    H.step(2, function()
        if T.off then return end
        local c = H.cond(T.v, "Engine")
        local q = tostring(T.q or "")
        local says0 = H.has(q, "0")
        Q.check(c ~= nil and c < 90, T.L .. ": Yes runs the game's own Take engine parts", "engine " .. tostring(c) .. "; the game queued " .. tostring(T.kinds))
        Q.check(not (c == 0 and not says0), T.L .. " (M1): the question says what the game does to the engine",
            "the question: \"" .. q .. "\"; the game set the engine to " .. tostring(c) .. " (its own tooltip says \"" .. tostring(T.warn) .. "\")")
        H.note(T.L .. ": engine parts the game gave " .. (H.count("Base.EngineParts") - (T.parts0 or 0)) .. " at Mechanics " .. H.mechLvl() .. " (the car's repair level " .. tostring(T.lvl) .. ")")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== 2. a second press (M2)
-- a part the game repairs on the car (its item has fixes, repairMechanic) and one recipe row: wantShort picks a
-- fixer that takes more than one use, else one that needs Mechanics only. T.pid, T.fixing, T.fixer
function C.fixFind(T, wantShort)
    T.pid, T.fixing, T.fixer = nil, nil, nil
    pcall(function()
        for _, id in ipairs({ "TrunkDoor", "EngineDoor" }) do
            local part = H.part(T.v, id)
            local item = part and part:getInventoryItem()
            if not T.pid and item and part:getScriptPart():isRepairMechanic() then
                local fixes = FixingManager.getFixes(item)
                for fi = 0, fixes:size() - 1 do
                    local fixing = fixes:get(fi)
                    for xi = 0, fixing:getFixers():size() - 1 do
                        local fixer = fixing:getFixers():get(xi)
                        local mechOnly = true
                        local sk = fixer:getFixerSkills()
                        if sk then for k = 0, sk:size() - 1 do if sk:get(k):getSkillName() ~= "Mechanics" then mechOnly = false end end end
                        local want = (wantShort and fixer:getNumberOfUse() > 1) or (not wantShort and mechOnly)
                        if want and not T.pid then T.pid, T.fi, T.xi, T.fixing, T.fixer = id, fi, xi, fixing, fixer end
                    end
                end
            end
        end
    end)
    return T.pid ~= nil
end
function H.fixItem(T) return H.item(T.v, T.pid) end
function H.usesX(T) local n = 0; pcall(function() n = T.fixing:countUses(S.p, T.fixer, H.fixItem(T)) end); return n end
function H.usesG(T) local n = 0; pcall(function() local g = T.fixing:getGlobalItem(); if g then n = T.fixing:countUses(S.p, g, nil) end end); return n end
function H.repaired(T) local n = nil; pcall(function() n = H.fixItem(T):getHaveBeenRepaired() end); return n end
-- materials for reps repairs by that row (the global item and the fixer, by the game's own count), its skills met
function C.fixGive(T, reps, fixerUses)
    pcall(function()
        local mod = T.fixing:getModule():getName()
        T.xFt = mod .. "." .. T.fixer:getFixerName()
        T.xN = T.fixer:getNumberOfUse()
        local g = T.fixing:getGlobalItem()
        if g then T.gFt = mod .. "." .. g:getFixerName(); T.gN = g:getNumberOfUse() end
        local sk = T.fixer:getFixerSkills()
        if sk then for k = 0, sk:size() - 1 do H.perkSet(sk:get(k):getSkillName(), math.max(sk:get(k):getSkillLevel(), H.mechLvl())) end end
    end)
    local want = fixerUses or ((T.xN or 1) * reps)
    local guard = 0
    while T.xFt and guard < 40 and H.usesX(T) < want do H.give(T.xFt); guard = guard + 1 end
    guard = 0
    while T.gFt and guard < 60 and H.usesG(T) < (T.gN or 1) * reps do H.give(T.gFt); guard = guard + 1 end
end
function H.fixSnap(T) return { rep = H.repaired(T), x = H.usesX(T), g = H.usesG(T), c = H.cond(T.v, T.pid) } end
function H.fixDelta(T, a)
    local b = H.fixSnap(T)
    return "repaired count +" .. tostring((b.rep or 0) - (a.rep or 0)) .. " (the game's getHaveBeenRepaired), " .. tostring(T.xFt) .. " uses spent "
        .. tostring((a.x or 0) - (b.x or 0)) .. ", " .. tostring(T.gFt) .. " uses spent " .. tostring((a.g or 0) - (b.g or 0)) .. ", condition "
        .. tostring(a.c) .. " -> " .. tostring(b.c), b
end
function C.c2fix(how)
    local T = { L = "2 M2 Repair pressed twice (" .. how .. ")" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        if not C.fixFind(T, false) then T.off = true; Q.skip(T.L, "no part of this car is repaired on the car with a Mechanics-only recipe"); return end
        H.setCond(T.v, T.pid, 40)
        C.fixGive(T, 2)
    end)
    H.lookQ(T)
    H.cardQ(T, "pid")
    H.step(3, function()
        if T.off then return end
        T.a = H.fixSnap(T)
        if not Q.check(H.lit("mech:verb:fix"), T.L .. ": Repair is lit on the " .. T.pid .. " card", "footer " .. H.footText()) then T.off = true; return end
        if how == "pad" then
            T.go = H.padOn() and H.focusEl("mech:verb:fix")
            if not Q.check(T.go, T.L .. ": the pad's focus lands on Repair", "on " .. tostring(H.focusedId())) then T.off = true end
        else
            H.click("mech:verb:fix", T.L)
        end
    end)
    if how == "pad" then
        H.tapA(function() return T.go and not T.off end)
        H.step(2, function() if not T.off then T.k1 = H.qkinds() end end)
        H.tapA(function() return T.go and not T.off end)
    else
        H.step(2, function() if not T.off then T.k1 = H.qkinds(); H.click("mech:verb:fix", T.L) end end)
    end
    H.step(3, function()
        H.padOff()
        if T.off then return end
        T.nFix = H.qcount("ISFixVehiclePartAction")
        T.kinds = H.qkinds()
    end)
    H.waitQ(T, 60000)
    H.step(2, function()
        if T.off then return end
        local d, b = H.fixDelta(T, T.a)
        local reps = (b.rep or 0) - (T.a.rep or 0)
        Q.check(T.nFix <= 1 and reps <= 1, T.L .. " (M2): a second press while the first repair is queued queues no second repair",
            "after the first press the game's queue held " .. tostring(T.k1) .. "; after the second " .. T.nFix .. " repairs (" .. tostring(T.kinds) .. "); " .. d)
    end)
    H.caseEnd(T.L)
end
-- the battery: Uninstall twice by the mouse during the walk, or Install twice by the pad
function C.c2batt(verb)
    local T = { L = "2 M2 " .. (verb == "install" and "Install a battery pressed twice (pad)" or "Uninstall the battery pressed twice (mouse)") }
    local act = (verb == "install") and "ISInstallVehiclePart" or "ISUninstallVehiclePart"
    H.step(2, function()
        if not H.caseStart(T) then return end
        if not H.item(T.v, "Battery") then T.off = true; Q.skip(T.L, "the car has no battery"); return end
        H.give("Base.Screwdriver")
        if verb == "install" then
            local it = H.takeItem(T.v, "Battery")
            T.bft = H.ft(it)
            local a = H.give(T.bft)
            local b = H.give(T.bft)
            pcall(function() a:setCurrentUsesFloat(0.9); b:setCurrentUsesFloat(0.9) end)
        end
    end)
    H.lookQ(T)
    -- (the look opens the hood; it is shut again, so each chain opens and shuts it)
    H.step(2, function() if not T.off then H.setDoor(T.v, "EngineDoor", false) end end)
    H.cardQ(T, "Battery")
    H.step(3, function()
        if T.off then return end
        if not Q.check(H.lit("mech:verb:" .. verb), T.L .. ": " .. verb .. " is lit on the battery's card", "footer " .. H.footText()) then T.off = true; return end
        H.atCar(T.v)   -- (a few tiles from the hood, so the chain starts with a walk)
        if verb == "install" then
            T.go = H.padOn() and H.focusEl("mech:verb:install")
            if not Q.check(T.go, T.L .. ": the pad's focus lands on Install", "on " .. tostring(H.focusedId())) then T.off = true end
        end
    end)
    if verb == "install" then
        H.tapA(function() return T.go and not T.off end)
        H.step(2, function() if not T.off then T.k1 = H.qkinds(); T.head1 = H.head() end end)
        H.tapA(function() return T.go and not T.off end)
    else
        H.step(2, function() if not T.off then H.click("mech:verb:uninstall", T.L) end end)
        H.step(3, function()
            if T.off then return end
            T.k1, T.head1 = H.qkinds(), H.head()
            -- the band during the walk: no job shown, the verb still lit
            T.bandWalk = "the head of the queue " .. T.head1 .. ", the band's Cancel " .. tostring(H.z("mech:cancel") ~= nil) .. ", Uninstall lit " .. tostring(H.lit("mech:verb:uninstall"))
            H.click("mech:verb:uninstall", T.L)
        end)
    end
    H.step(3, function()
        H.padOff()
        if T.off then return end
        T.n = H.qcount(act)
        T.kinds = H.qkinds()
        T.hood0 = H.hoodOpen(T.v)
    end)
    H.waitQ(T, 90000)
    H.step(3, function()
        if T.off then return end
        local on = H.item(T.v, "Battery") ~= nil
        Q.check(T.n <= 1, T.L .. " (M2): a second press while the chain runs queues no second " .. verb,
            "after the first press the game's queue held " .. tostring(T.k1) .. "; after the second " .. T.n .. " " .. act .. " (" .. tostring(T.kinds) .. ")")
        if T.bandWalk then H.note(T.L .. ": during the walk: " .. T.bandWalk) end
        Q.check(not H.hoodOpen(T.v), T.L .. " (M2): after the chain(s) the hood is shut, as one chain leaves it",
            "the hood open " .. tostring(H.hoodOpen(T.v)) .. "; the battery on " .. tostring(on) .. "; the game's events " .. (#S.mad - (T.mad0 or #S.mad)))
    end)
    H.caseEnd(T.L)
end
function C.c2()
    C.c2fix("mouse")
    C.c2fix("pad")
    C.c2batt("uninstall")
    C.c2batt("install")
end

-- ===================================================================== 3. Install's pick (M3)
-- the owned pick rows as drawn: for each mech:pick:i the words in it, and whether it says his bag
function H.picks()
    local o = {}
    local inv = getText("IGUI_Controller_Inventory")
    for i = 1, 8 do
        local z = H.z("mech:pick:" .. i)
        if z then
            local tx = H.textsIn(z)
            local bag = false
            for _, s in ipairs(tx) do if H.has(s, inv) then bag = true end end
            o[#o + 1] = { i = i, words = table.concat(tx, " / "), bag = bag }
        end
    end
    return o
end
function H.picksText() local o = {}; for _, r in ipairs(H.picks()) do o[#o + 1] = r.i .. ": " .. r.words end; return H.list(o) end
function C.c3leg(how, pid)
    local T = { L = "3 M3 Install's pick (" .. how .. ", " .. pid .. ")", pid = pid }
    H.step(2, function()
        if not H.caseStart(T) then return end
        T.mad0 = #S.mad
        local it = H.takeItem(T.v, pid)
        T.tft = H.ft(it)
        if not it then T.off = true; Q.skip(T.L, "the car has no " .. pid); return end
        H.give("Base.Jack")
        H.give("Base.LugWrench")
    end)
    H.lookQ(T)
    H.step(2, function()
        if T.off then return end
        T.crate = H.mkCrate()
        if not T.crate then T.off = true; Q.skip(T.L, "no free square beside him for the crate"); return end
        -- (Nov 26 2026: with his own things on him, two spares in his bags and the crate's coming over, he carried 52.4 of
        -- 50 and the game's move of the crate's tire failed its start, which clears the whole queue: Install did nothing.
        -- His own free things are set aside for this leg (put back at the end), so the crate's spare fits)
        do
            local set = {}
            for _, it in ipairs(H.all()) do if S.found.inv0[it] then set[H.ft(it)] = true end end
            H.stashTypes(set)
            local w, cap = nil, nil
            pcall(function() w, cap = S.p:getInventory():getCapacityWeight(), S.p:getMaxWeight() end)
            H.note(T.L .. ": his own free things set aside for the leg; he carries " .. tostring(w) .. " of " .. tostring(cap))
        end
        T.a = H.give(T.tft)
        T.b = H.giveTo(T.crate.inv, T.tft)
        pcall(function() T.a:setCondition(70); T.b:setCondition(70) end)
        H.lootRefresh()
    end)
    Q.waitMs(1500)
    if how == "mouse" then H.shot("mt_full_" .. H.sizeTag(), "the full card's overview: the car figure and the summary, " .. pid .. " missing", function() return not T.off end) end
    H.cardQ(T, "pid")
    H.wait(3000, function() return T.off or (H.z("mech:pick:1") ~= nil and H.z("mech:pick:2") ~= nil) end, function(ok)
        if T.off then return end
        if not Q.check(ok, T.L .. ": two pick rows for the two spares in reach", "picks " .. H.picksText() .. "; footer " .. H.footText()) then T.off = true; return end
        T.order = {}
    end)
    -- the tie's order, frame by frame (two spares of one type and one condition)
    for _ = 1, 30 do
        H.step(1, function()
            if T.off then return end
            for _, r in ipairs(H.picks()) do if not r.bag then T.order[#T.order + 1] = r.i end end
        end)
    end
    if how == "mouse" then H.shot("mt_install_" .. H.sizeTag(), "a tire's card with its install picks (one spare in his bag, one in a crate)", function() return not T.off end) end
    H.step(2, function()
        if T.off then return end
        local swaps = 0
        for i = 2, #T.order do if T.order[i] ~= T.order[i - 1] then swaps = swaps + 1 end end
        H.note(T.L .. ": over 30 frames the crate's spare stood at row(s) " .. H.list(T.order, 6) .. " (" .. swaps .. " swaps)")
        for _, r in ipairs(H.picks()) do if not r.bag then T.crateRow = r.i end end
        if not Q.check(T.crateRow ~= nil, T.L .. ": a pick row says the crate", H.picksText()) then T.off = true; return end
        if how == "pad" then
            T.go = H.padOn() and H.focusEl("mech:pick:" .. T.crateRow)
            if not Q.check(T.go, T.L .. ": the pad's focus lands on the crate's pick", "on " .. tostring(H.focusedId())) then T.off = true end
        else
            H.click("mech:pick:" .. T.crateRow, T.L)
        end
    end)
    if how == "pad" then H.tapA(function() return T.go and not T.off end) end
    H.step(3, function()
        if T.off then return end
        local s = H.ms()
        Q.check(s ~= nil and s.pick == T.crateRow, T.L .. ": the crate's spare is picked", "pick " .. tostring(s and s.pick) .. " (row " .. T.crateRow .. ")")
        -- a third spare brought near after the pick (a better one, in his bag)
        T.c = H.give(T.tft)
        pcall(function() T.c:setCondition(90) end)
        H.lootRefresh()
    end)
    Q.waitMs(1500)
    H.step(2, function()
        if T.off then return end
        T.after = H.picksText()
        -- (for Build, Nov 26 2026: Install queued nothing after a pick on ec6c95c19; the tab's own state at the press)
        local ms = H.ms()
        H.note(T.L .. ": at the press, s.pick " .. tostring(ms and ms.pick) .. ", s.pickItem " .. H.nm(ms and ms.pickItem)
            .. (ms and ms.pickItem == T.b and " (the crate's 70)" or (ms and ms.pickItem == T.a and " (the bag's 70)" or (ms and ms.pickItem == T.c and " (the bag's 90)" or "")))
            .. ", s.queued " .. tostring(ms and ms.queued and #ms.queued or 0) .. ", the game's queue " .. H.qkinds())
        if how == "pad" then
            T.go2 = H.focusEl("mech:verb:install")
            Q.check(T.go2, T.L .. ": the pad's focus lands on Install", "on " .. tostring(H.focusedId()))
        else
            H.click("mech:verb:install", T.L)
        end
    end)
    if how == "pad" then H.tapA(function() return T.go2 and not T.off end) end
    H.step(3, function() H.padOff(); if not T.off then T.kinds = H.qkinds() end end)
    H.waitQ(T, 90000)
    H.step(3, function()
        if T.off then return end
        local on = H.item(T.v, pid)
        local which = (on == T.b and "the crate's 70 (picked)") or (on == T.a and "the bag's 70") or (on == T.c and "the bag's 90 (brought after the pick)") or H.nm(on)
        Q.check(on ~= nil and on == T.b, T.L .. " (M3): Install puts on the spare picked, whatever came near after",
            "the game put on: " .. which .. "; the rows after the third spare came: " .. tostring(T.after) .. "; the game queued " .. tostring(T.kinds))
        T.flashOk = #S.mad > (T.mad0 or 0)
        if T.flashOk then S.madSeenAt = S.madSeenAt or getTimestampMs() end
    end)
    H.caseEnd(T.L)
end
function C.c3()
    C.c3leg("mouse", "TireFrontLeft")
    C.c3leg("pad", "TireFrontRight")
end

-- ===================================================================== 4. Repair at 100% (M4)
function C.c4leg(how)
    local T = { L = "4 M4 Repair at 100% (" .. how .. ")" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        if not C.fixFind(T, false) then T.off = true; Q.skip(T.L, "no part of this car is repaired on the car with a Mechanics-only recipe"); return end
        H.setCond(T.v, T.pid, 100)
        C.fixGive(T, 1)
    end)
    H.lookQ(T)
    H.cardQ(T, "pid")
    H.step(4, function()
        if T.off then return end
        T.a = H.fixSnap(T)
        T.main = H.mainVerb()
        -- the game's menu offers Repair at any condition (ISVehicleMechanics.doPartContextMenu: repairMechanic and fixes)
        local offered = false
        pcall(function() offered = H.part(T.v, T.pid):getScriptPart():isRepairMechanic() and not FixingManager.getFixes(H.fixItem(T)):isEmpty() end)
        Q.check(T.main ~= "fix", T.L .. " (M4): a part at 100% does not get Repair as its main (accent) verb",
            "main " .. tostring(T.main) .. "; footer " .. H.footText() .. "; the game's menu offers Repair here too: " .. tostring(offered) .. " (not as its main)")
        if not H.lit("mech:verb:fix") then T.off = true; Q.skip(T.L .. ": the repair at 100%", "Repair is not lit (" .. H.footText() .. ")"); return end
        if how == "pad" then
            T.go = H.padOn() and H.focusEl("mech:verb:fix")
            Q.check(T.go, T.L .. ": the pad's focus lands on Repair", "on " .. tostring(H.focusedId()))
        else
            H.click("mech:verb:fix", T.L)
        end
    end)
    if how == "pad" then H.tapA(function() return T.go and not T.off end) end
    H.step(3, function() H.padOff(); if not T.off then T.kinds = H.qkinds() end end)
    H.waitQ(T, 60000)
    H.step(2, function()
        if T.off then return end
        local d, b = H.fixDelta(T, T.a)
        local spent = ((T.a.x or 0) - (b.x or 0)) + ((T.a.g or 0) - (b.g or 0))
        local gained = (b.c or 0) - (T.a.c or 0)
        Q.check(not (spent > 0 and gained <= 0), T.L .. " (M4): a repair pressed at 100% spends nothing for nothing", d .. "; the game queued " .. tostring(T.kinds))
    end)
    H.caseEnd(T.L)
end
function C.c4()
    C.c4leg("mouse")
    C.c4leg("pad")
end

-- ===================================================================== 5. A then A on a row (M5)
function C.c5leg(pid)
    local T = { L = "5 M5 A A on " .. pid, pid = pid }
    H.step(2, function()
        if not H.caseStart(T) then return end
        if pid == "Engine" then
            H.setCond(T.v, "Engine", 50)
            H.give("Base.Wrench")
            for _ = 1, 3 do H.give("Base.EngineParts") end
        else
            H.setCond(T.v, pid, 60)
            pcall(function() local part = H.part(T.v, pid); part:setContainerContentAmount(part:getContainerCapacity() - 8) end)
            for _, ft in ipairs({ "Base.TirePump", "Base.Jack", "Base.LugWrench" }) do H.give(ft) end
        end
        T.air0 = nil
        pcall(function() T.air0 = H.part(T.v, pid):getContainerContentAmount() end)
    end)
    H.lookQ(T)
    H.step(3, function()
        if T.off then return end
        local s = H.ms()
        if s then s.card, s.collapsed = nil, {} end
        T.go = H.padOn() and H.focusEl("mech:row:" .. pid)
        if not Q.check(T.go, T.L .. ": the pad's focus lands on the row", "on " .. tostring(H.focusedId()) .. "; stops " .. H.stopIds()) then T.off = true end
    end)
    H.tapA(function() return T.go and not T.off end)
    Q.waitMs(700)
    H.step(2, function()
        if T.off then return end
        local s = H.ms()
        T.f1 = H.focusedId()
        T.main = H.mainVerb()
        T.foot = H.footText()
        Q.check(s ~= nil and s.card == pid, T.L .. ": A on the row opens its card", "card " .. tostring(s and s.card))
    end)
    if pid ~= "Engine" then H.shot("mt_pad_" .. H.sizeTag(), "the pad's mark on a verb: A on a 60% tire's row opened its card", function() return not T.off end) end
    H.tapA(function() return T.go and not T.off end)
    H.step(3, function()
        H.padOff()
        if T.off then return end
        local s = H.ms()
        T.asked = s and s.confirm
        T.ran, T.act = H.qverb()
        T.kinds = H.qkinds()
        H.qstop()
        local ran = T.ran or (T.asked and ("the question for " .. T.asked)) or "nothing"
        Q.check((T.ran ~= nil and T.ran == T.main) or (T.ran == nil and T.asked == nil and T.main == nil), T.L .. " (M5): A then A on a row runs the card's main verb",
            "focus after the first A: " .. tostring(T.f1) .. "; the main (accent) verb " .. tostring(T.main) .. "; footer " .. tostring(T.foot) .. "; the second A ran " .. ran .. " (the game's queue: " .. T.kinds .. ")")
        if T.asked then if s then s.confirm = nil end end
    end)
    Q.waitMs(400)
    H.step(2, function()
        if T.off then return end
        local c = H.cond(T.v, pid)
        local air = nil
        pcall(function() air = H.part(T.v, pid):getContainerContentAmount() end)
        Q.check(c == (pid == "Engine" and 50 or 60) and (T.air0 == nil or air == nil or math.abs(air - T.air0) < 0.5), T.L .. ": the queue cleared at once left the part as it was",
            "condition " .. tostring(c) .. ", air " .. H.n1(air) .. " (was " .. H.n1(T.air0) .. ")")
    end)
    H.caseEnd(T.L)
end
function C.c5()
    C.c5leg("TireFrontRight")
    C.c5leg("Engine")
end

-- ===================================================================== 6. seated and driving (M6), run last
function H.enter(v, seat)
    if not (ZEDQA_CAR_ENTER and v and H.live(v)) then return false, "no car or no prelude" end
    local ok, why = false, nil
    local okC, e = pcall(function() ok, why = ZEDQA_CAR_ENTER(v, seat or 0) end)
    if not okC then return false, tostring(e) end
    return ok, why
end
-- the game's rule for its own part menu (ISVehicleMechanics.doPartContextMenu): no menu for a seated player who is not
-- staff on a server (a debug game lets it through; said with the result)
function H.gameRefusesSeated()
    local staff = false
    pcall(function() staff = isClient() and (isAdmin() or getAccessLevel() == "moderator") end)
    return S.p:getVehicle() ~= nil and not staff
end
function C.c6()
    local T = { L = "6 M6 seated" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        H.give("Base.Jack")
        H.give("Base.LugWrench")
        T.vB = S.vB
    end)
    -- the second car looked at on foot first (so its tab stays while he sits in the first)
    H.step(2, function() if not T.off and T.vB then H.atCar(T.vB) end end)
    H.lookQ(T, "vB", true)
    H.step(2, function() if not T.off then H.atCar(T.v) end end)
    H.lookQ(T)
    H.step(3, function()
        if T.off then return end
        local ok, why = H.enter(T.v, 0)
        if not Q.check(ok, T.L .. ": he sits at the wheel of the looked-at car (the prelude's guarded enter)", tostring(why)) then T.off = true end
    end)
    Q.waitMs(1200)
    -- a: a verb from the driver's seat of a parked car
    H.step(2, function() if not T.off then H.showCar(T.v) end end)
    H.cardQ(T, "TireFrontLeft")
    H.step(3, function()
        if T.off then return end
        T.lit = H.lit("mech:verb:uninstall")
        T.ref = H.gameRefusesSeated()
        H.click("mech:verb:uninstall", T.L)
    end)
    H.step(2, function()
        if T.off then return end
        T.n, T.k = H.qlen(), H.qkinds()
        H.qstop()
        Q.check(not T.ref or T.n == 0, T.L .. " (M6): seated, a verb queues nothing (the game's part menu refuses a seated player, ISVehicleMechanics:212)",
            "Uninstall lit " .. tostring(T.lit) .. "; the press queued " .. T.k .. "; the game refuses here " .. tostring(T.ref) .. " (debug game " .. tostring(H.debug()) .. ": its menu lets debug through)")
    end)
    Q.waitMs(600)
    H.step(2, function()
        if T.off then return end
        if S.p:getVehicle() ~= T.v then
            local ok = H.enter(T.v, 0)
            if not ok then T.off = true; Q.skip(T.L .. ": the window and driving legs", "he is out of the car and could not sit again") end
        end
    end)
    -- b: Open window on the second car's window while he sits in the first
    H.step(3, function()
        if T.off then return end
        if not (T.vB and H.live(T.vB) and H.listed(T.vB)) then T.noB = true; Q.skip(T.L .. ": Open window on another car", S.noB or "the second car is not on the tab from his seat"); return end
        H.showCar(T.vB)
    end)
    H.cardQ(T, "WindowFrontLeft", "noB")
    H.step(3, function()
        if T.off or T.noB then return end
        T.offered = H.z("mech:verb:openWindow") ~= nil
        T.wOpen0 = false
        pcall(function() T.wOpen0 = H.part(T.vB, "WindowFrontLeft"):getWindow():isOpen() end)
        if T.offered then H.click("mech:verb:openWindow", T.L) end
    end)
    H.step(3, function() if not (T.off or T.noB) then T.kw = H.qkinds() end end)
    H.wait(8000, function() return T.off or T.noB or not T.offered or H.qlen() == 0 end, function()
        if T.off or T.noB then return end
        local open = false
        pcall(function() open = H.part(T.vB, "WindowFrontLeft"):getWindow():isOpen() end)
        local out = S.p:getVehicle() ~= T.v
        Q.check(not T.offered, T.L .. " (M6): Open window is not offered on a car he does not sit in",
            "offered " .. tostring(T.offered) .. "; the press queued " .. tostring(T.kw) .. "; he left his car " .. tostring(out) .. "; the other car's window opened " .. tostring(open) .. " (was " .. tostring(T.wOpen0) .. ")")
        H.qstop()
        pcall(function() H.part(T.vB, "WindowFrontLeft"):getWindow():setOpen(false) end)
        if out then
            local ok = H.enter(T.v, 0)
            if not ok then T.off = true; Q.skip(T.L .. ": the driving leg", "he could not sit again after the window press") end
        end
    end)
    -- c: Uninstall pressed while driving on the cruise control
    C.c6drive(T)
    H.caseEnd(T.L)
end
function C.c6drive(T)
    H.step(3, function()
        if T.off then return end
        H.showCar(T.v)
        local s = H.ms()
        if s then s.card = nil end
        pcall(ISVehicleMenu.onStartEngine, S.p)
    end)
    H.wait(10000, function() return T.off or H.running(T.v) end, function(ok)
        if T.off then return end
        if not ok then pcall(function() T.v:engineDoRunning() end) end
        if not H.running(T.v) then T.noDrive = "the engine would not start (the game's start and engineDoRunning)"; return end
        H.qstop()
    end)
    H.cardQ(T, "TireFrontLeft", "noDrive")
    H.step(2, function()
        if T.off or T.noDrive then return end
        T.x0, T.y0 = T.v:getX(), T.v:getY()
        local ok = pcall(function() T.v:setRegulatorSpeed(40); T.v:setRegulator(true) end)
        if not ok then T.noDrive = "the cruise control (setRegulator) is not open to Lua" end
    end)
    H.wait(10000, function()
        if T.off or T.noDrive then return true end
        local far = math.abs(T.v:getX() - T.x0) + math.abs(T.v:getY() - T.y0)
        return H.kmh(T.v) >= 25 or far > 18
    end, function()
        if T.off then return end
        T.sp = H.kmh(T.v)
        if T.noDrive or T.sp < 15 then
            pcall(function() T.v:setRegulator(false) end)
            Q.skip(T.L .. ": Uninstall pressed while driving", T.noDrive or ("the game's cruise control gave " .. H.n1(T.sp) .. " km/h in 10 s"))
            T.noDrive = T.noDrive or "slow"
            return
        end
        T.ref = H.gameRefusesSeated()
        H.click("mech:verb:uninstall", T.L)
        T.kd = H.qkinds()
        T.n = H.qlen()
        pcall(function() T.v:setRegulator(false) end)
    end)
    -- the game's queue runs its own stop (ISStopVehicle brakes); everything after it is cleared once the car stands
    H.wait(12000, function()
        if T.off or T.noDrive then return true end
        pcall(function() T.v:setForceBrake() end)
        return H.kmh(T.v) < 1 or H.head() ~= "ISStopVehicle"
    end, function()
        if T.off or T.noDrive then return end
        H.qstop()
        local first = string.sub(tostring(T.kd), 1, 13) == "ISStopVehicle"
        Q.check(not T.ref or T.n == 0, T.L .. " (M6): at speed, a verb queues nothing (the game's part menu refuses a seated player)",
            "at " .. H.n1(T.sp) .. " km/h the press queued " .. tostring(T.kd) .. "; the game's stop first " .. tostring(first) .. "; the car now at " .. H.n1(H.kmh(T.v)) .. " km/h")
    end)
    H.wait(8000, function() return T.off or T.noDrive or H.kmh(T.v) < 1 end, function()
        pcall(function() T.v:setRegulator(false) end)
        pcall(function() if S.p:getVehicle() then local car = S.p:getVehicle(); car:exit(S.p); triggerEvent("OnExitVehicle", S.p) end end)
        pcall(function() T.v:shutOff() end)
    end)
end

-- ===================================================================== 7. leaving the tab ends the look (M7)
function C.c7()
    local T = { L = "7 M7 the Loot tab and back" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        H.mech(0)
        T.maxT = nil
        pcall(function() T.maxT = 200 - (H.mechLvl() * (200 / 15)) end)
    end)
    H.lookQ(T)
    H.step(2, function()
        if T.off then return end
        T.look1 = T.lookMs
        T.flag1, T.hood1 = H.mechFlag(T.v), H.hoodOpen(T.v)
        H.toLoot()
        T.tl = getTimestampMs()
    end)
    Q.waitMs(1500)
    H.step(2, function()
        if T.off then return end
        T.flag2, T.hoodQ, T.insp2 = H.mechFlag(T.v), H.qcount("ISCloseVehicleDoor"), H.insp(T.v)
        RT.worldTab("vehicle")
    end)
    Q.waitMs(900)
    H.step(2, function()
        if T.off then return end
        T.insp3 = H.insp(T.v)
        T.notWord = H.drew(H.cased(ZeD.tr("UI_ZeD_Veh_NotInspected"))) ~= nil or H.drew(ZeD.tr("UI_ZeD_Veh_NotInspected")) ~= nil
        Q.check(T.insp3, T.L .. " (M7): a trip to the Loot tab and back keeps the look (the game's window stays up while the inventory is used)",
            "first look " .. tostring(T.look1) .. " ms at Mechanics " .. H.mechLvl() .. " (the game's look " .. H.n1(T.maxT) .. " units); the game's mechanic flag " .. tostring(T.flag1)
            .. " -> " .. tostring(T.flag2) .. " in Loot, the hood open " .. tostring(T.hood1) .. ", its shut queued " .. tostring(T.hoodQ) .. "; back on the tab: looked at "
            .. tostring(T.insp3) .. ", Not inspected drawn " .. tostring(T.notWord))
        if not T.insp3 then H.qstop(); T.t1 = getTimestampMs(); if not H.click("mech:inspect", T.L) then pcall(ISVehicleMenu.onMechanic, S.p, T.v) end; H.speed(2) end
    end)
    H.wait(40000, function() return T.off or T.insp3 or H.lookedAt(T.v) end, function(ok)
        H.speed(1)
        if T.off or T.insp3 then return end
        H.note(T.L .. ": to work on the car again after the Loot tab: " .. (ok and ((getTimestampMs() - T.t1) .. " ms") or "no look in 40 s") .. " of walk and look (game speed 2), the hood shut behind him meanwhile")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== 8. the half card (M8)
function H.ctxVisRaw(c) local v = nil; pcall(function() v = c:getIsVisible() end); return v end
function C.c8look(T, label)
    local r = S.mtRect
    local s = H.ms()
    if not (r and s and getTimestampMs() - r.t < 1000) then Q.skip(label, "the tab's rectangle was not read"); return end
    local listW = ZeD.T.px((ZeD.CraftingCore and ZeD.CraftingCore.PANE_W_SPLIT) or 240)
    local rw = math.floor(r.w - listW - ZeD.T.px(1))
    -- (fix/mechanics, Nov 26 2026: MT.layout stacks the list over the right pane when the room beside the list is short,
    -- as CK.layout does; the panes are read from it, not from the fixed list)
    local lay = nil
    pcall(function() lay = ZeD.MechanicsTab.layout(r.x or 0, r.y or 0, r.w, r.h or ZeD.T.px(400)) end)
    local how = "side by side"
    if type(lay) == "table" and lay.list and lay.right then
        listW, rw = math.floor(lay.list.w), math.floor(lay.right.w)
        if lay.stacked then how = "stacked" end
    end
    Q.check(rw > 0, label .. " (M8): the right column has room (" .. how .. ")", "the tab " .. math.floor(r.w) .. " px, the list " .. listW .. " px, the right pane " .. rw .. " px")
    local out, n = {}, 0
    for _, z in ipairs(s.zones or {}) do
        local id = tostring(z.id)
        if string.sub(id, 1, 9) == "mech:row:" or string.sub(id, 1, 10) == "mech:pick:" or string.sub(id, 1, 9) == "mech:fix:" or id == "mech:step" then
            n = n + 1
            if (z.w or 0) <= 0 or z.x < r.x - 1 or z.x + z.w > r.x + r.w + 1 then if #out < 6 then out[#out + 1] = id .. " " .. math.floor(z.x) .. "+" .. math.floor(z.w or 0) end end
        end
    end
    Q.check(#out == 0, label .. " (M8): the rows, picks and the step button draw inside the tab (" .. math.floor(r.x) .. "+" .. math.floor(r.w) .. " px)", n .. " zones; out: " .. H.list(out))
    RT.bounds(Q, label)
end
function C.c8()
    local T = { L = "8 M8 the half card" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        local it = H.takeItem(T.v, "TireRearLeft")
        T.tft = H.ft(it)
        if not it then T.off = true; Q.skip(T.L, "the car has no rear left tire"); return end
        H.give("Base.Jack")
        H.give("Base.LugWrench")
    end)
    H.lookQ(T)
    H.step(2, function()
        if T.off then return end
        T.crate = H.mkCrate()
        T.a = H.give(T.tft)
        pcall(function() T.a:setCondition(60) end)
        if T.crate then T.b = H.giveTo(T.crate.inv, T.tft); pcall(function() T.b:setCondition(80) end) end
        H.lootRefresh()
        T.full0 = H.isFull()
        H.note(T.L .. ": before the hold the drawer is " .. H.drawerW() .. " px (full card " .. ZeD.T.px(480) .. ", half " .. ZeD.T.px(220) .. ")")
    end)
    H.halfOn(T)
    H.step(2, function()
        if T.off then return end
        local sw = H.screen()
        if not T.half then
            local w = RT.ww()
            if sw <= 1400 then Q.check(false, T.L .. " (M8): the World window holds the half card at " .. H.sizeTag(), "the drawer is " .. H.drawerW() .. " px; the inventory drawer open "
                .. tostring(w and w._invDrawerOpen) .. ", Loot columns " .. tostring(w and #(w._mcSelected or {})))
            else H.note(T.L .. ": the half card could not be forced at " .. H.sizeTag() .. " (the drawer is " .. H.drawerW() .. " px): its checks run at 1280x800") end
            T.off = true
            return
        end
        C.c8look(T, T.L .. ", the overview")
    end)
    H.shot("mt_half_" .. H.sizeTag(), "the half card (220): the Vehicle tab held in, the overview", function() return T.half == true end)
    H.cardQ(T, "TireRearLeft")
    Q.waitMs(1000)
    H.step(2, function()
        if T.off then return end
        C.c8look(T, T.L .. ", the tire's card with its install picks")
        local verbs = 0
        for _, b in ipairs(S.band or {}) do if b.verb then verbs = verbs + 1 end end
        H.note(T.L .. ": the footer draws " .. verbs .. " verb button(s): " .. H.footText() .. "; the picks drawn " .. H.picksText())
        T.kinds = nil
        H.click("mech:verb:install", T.L)
    end)
    H.step(3, function() if not T.off then T.kinds = H.qkinds() end end)
    H.waitQ(T, 90000)
    H.step(2, function()
        if T.off then return end
        local on = H.item(T.v, "TireRearLeft")
        local which = (on == T.b and "the crate's 80 (the best: pick 1, unseen)") or (on == T.a and "the bag's 60") or H.nm(on)
        H.note(T.L .. ": Install from the footer at the half card put on " .. which .. "; the game queued " .. tostring(T.kinds))
        Q.check(on ~= nil, T.L .. ": the footer's Install works at the half card", which)
    end)
    -- the pad's A on a row at the half card
    H.step(2, function()
        if T.off then return end
        local s = H.ms()
        if s then s.card = nil end
        T.go = H.padOn() and H.focusEl("mech:row:Battery")
        Q.check(T.go, T.L .. " (pad): the focus lands on a row at the half card", "on " .. tostring(H.focusedId()))
    end)
    H.tapA(function() return T.go and not T.off end)
    Q.waitMs(700)
    H.step(2, function()
        if T.off or not T.go then H.padOff(); return end
        local s = H.ms()
        Q.check(s ~= nil and s.card == "Battery", T.L .. " (pad): A opens the battery's card at the half card", "card " .. tostring(s and s.card) .. ", focus " .. tostring(H.focusedId()))
        H.note(T.L .. " (pad): the focus after A: " .. tostring(H.focusedId()) .. " (" .. H.footText() .. ")")
        H.padOff()
        H.halfBack()
    end)
    Q.waitMs(1000)
    H.caseEnd(T.L)
end

-- ===================================================================== 9. B and Cancel mid-chain (M9)
function C.c9leg(how)
    local T = { L = "9 M9 the chain stopped (" .. how .. ")" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        if not H.item(T.v, "Battery") then T.off = true; Q.skip(T.L, "the car has no battery"); return end
        H.mech(0)   -- (the battery's uninstall at Mechanics 0 takes 100 units: time to stop it while it runs)
    end)
    H.lookQ(T)
    H.step(2, function()
        if T.off then return end
        H.setDoor(T.v, "EngineDoor", false)
        T.crate = H.mkCrate()
        if not T.crate then T.off = true; Q.skip(T.L, "no free square for the crate"); return end
        T.sd = H.giveTo(T.crate.inv, "Base.Screwdriver")
        H.lootRefresh()
    end)
    Q.waitMs(1000)
    if how ~= "game" then H.cardQ(T, "Battery") end
    H.step(3, function()
        if T.off then return end
        if how == "game" then
            pcall(ISVehiclePartMenu.onUninstallPart, S.p, H.part(T.v, "Battery"))
        else
            H.click("mech:verb:uninstall", T.L)
        end
        T.k0 = H.qkinds()
    end)
    -- (B with nothing open: the card is shut first, so the pad's B has no card to close)
    if how == "B" then H.step(2, function() if not T.off then H.click("mech:row:Battery", T.L) end end) end
    H.wait(30000, function() return T.off or H.head() == "ISUninstallVehiclePart" or H.qlen() == 0 end, function(ok)
        if T.off then return end
        T.running = H.head() == "ISUninstallVehiclePart"
        if not Q.check(T.running, T.L .. ": the chain reaches the uninstall (the game's queue)", "queued " .. tostring(T.k0) .. "; now " .. H.qkinds()) then T.off = true; return end
        if how == "B" then
            local s = H.ms()
            T.go = H.padOn() and H.focusEl("mech:row:Battery")
            T.cardOpen = s and s.card
        elseif how == "cancel" then
            T.cancelDrawn = H.z("mech:cancel") ~= nil
            H.click("mech:cancel", T.L)
        else
            pcall(stopDoingActionThatCanBeCancelled, S.p)
        end
    end)
    if how == "B" then H.tapB(function() return T.go and not T.off end) end
    Q.waitMs(600)
    H.step(2, function()
        H.padOff()
        if T.off then return end
        local w = RT.ww()
        local r = {
            q = H.qlen(), kinds = H.qkinds(), hood = H.hoodOpen(T.v), hand = H.ft(S.p:getPrimaryHandItem()),
            sdIn = H.ctype(H.where(T.sd)), batt = H.item(T.v, "Battery") ~= nil, tab = w and w._activeTab,
        }
        S.c9 = S.c9 or {}
        S.c9[how] = r
        H.note(T.L .. ": after the stop: the game's queue " .. r.kinds .. ", the hood open " .. tostring(r.hood) .. ", in his hand " .. r.hand .. ", the screwdriver in "
            .. r.sdIn .. ", the battery on " .. tostring(r.batt) .. ", the World tab " .. tostring(r.tab) .. (how == "B" and (", a card open " .. tostring(T.cardOpen)) or "")
            .. (how == "cancel" and (", the band's Cancel drawn " .. tostring(T.cancelDrawn)) or ""))
        if how ~= "game" then
            local g = S.c9.game
            Q.check(r.q == 0, T.L .. " (M9): the stop empties the game's queue (the whole chain goes, as the game's own stop)", r.kinds)
            if g then
                Q.check((not r.hood or g.hood) and (r.sdIn == g.sdIn), T.L .. " (M9): ZeD's stop leaves the car and the tools no worse than the game's own stop",
                    "ZeD: hood open " .. tostring(r.hood) .. ", screwdriver in " .. r.sdIn .. "; the game's: hood open " .. tostring(g.hood) .. ", screwdriver in " .. g.sdIn)
            else
                Q.skip(T.L .. ": against the game's own stop", "the game's leg did not run")
            end
            if how == "B" then
                Q.check(r.tab == "vehicle", T.L .. ": B with nothing open stops the job and leaves the tab up (MT:2457's comment says B leaves the tab)", "World tab " .. tostring(r.tab))
            end
        end
    end)
    H.caseEnd(T.L)
end
function C.c9()
    C.c9leg("game")
    C.c9leg("B")
    C.c9leg("cancel")
end

-- ===================================================================== 10. NEEDS rows against the game's checks (M10)
function H.needsText() return H.list(S.needs or {}, 8) end
function H.notNowFor(verbKey) return ZeD.tr("UI_ZeD_Veh_NotNow", ZeD.tr(verbKey)) end
function H.needsHas(sub) for _, l in ipairs(S.needs or {}) do if H.has(l, sub) then return l end end; return nil end
-- a. the battery with the engine running
function C.c10batt()
    local T = { L = "10a M10 the battery, the engine running" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        H.hidden("all")
        H.give("Base.Screwdriver")
    end)
    H.lookQ(T)
    H.step(2, function()
        if T.off then return end
        local ok, why = H.enter(T.v, 0)
        if not ok then T.off = true; Q.skip(T.L, "he could not sit in the car to start it (" .. tostring(why) .. ")"); return end
        pcall(ISVehicleMenu.onStartEngine, S.p)
    end)
    H.wait(10000, function() return T.off or H.running(T.v) end, function(ok)
        if T.off then return end
        if not ok then pcall(function() T.v:engineDoRunning() end) end
        H.qstop()
        pcall(function() local car = S.p:getVehicle(); if car then car:exit(S.p); triggerEvent("OnExitVehicle", S.p) end end)
    end)
    Q.waitMs(1500)
    H.step(2, function()
        if T.off then return end
        if not H.running(T.v) then T.off = true; Q.skip(T.L, "the engine did not keep running with him out of the car"); return end
        RT.worldTab("vehicle")
    end)
    H.lookQ(T)
    H.cardQ(T, "Battery")
    Q.waitMs(500)
    H.step(2, function()
        if T.off then return end
        local game = nil
        pcall(function() game = T.v:canUninstallPart(S.p, H.part(T.v, "Battery")) end)
        local nn = H.notNowFor("IGUI_Uninstall")
        local bare = H.needsHas(nn)
        Q.check(game == false, T.L .. ": the game refuses the battery's uninstall with the engine running (canUninstallPart, Vehicles.UninstallTest.Battery)", tostring(game))
        Q.check(not H.lit("mech:verb:uninstall"), T.L .. ": Uninstall is grey on the card", H.footText())
        Q.check(bare == nil, T.L .. " (M10): the NEEDS line names the game's reason (the engine running)", "the NEEDS lines drawn: " .. H.needsText())
        S.notNowSeen = bare
    end)
    H.step(2, function() pcall(function() T.v:shutOff() end) end)
    H.caseEnd(T.L)
end
-- b. a profession in the muffler's uninstall table (a modded car's table; put back at once)
-- (Nov 26 2026, the first run: the game's own VehicleUtils.testProfession throws on every profession string in this
-- build, "expected argument of type CharacterProfession, got String", and each throw is a Lua error in the log. No
-- string can be staged, so the case SKIPs without asking the game)
function C.profTry()
    return nil
end
function H.tblBack()
    local b = S.back.tbl
    if not b then return end
    pcall(function() b.kv.professions = b.was end)
    S.back.tbl = nil
end
function C.c10prof()
    local T = { L = "10b M10 a profession in a part's table" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        H.hidden("all")
        for _, ft in ipairs({ "Base.Wrench", "Base.Screwdriver", "Base.Jack", "Base.LugWrench" }) do H.give(ft) end
        H.learn("Basic Mechanics")
        local part = H.part(T.v, "Muffler")
        local kv = part and part:getTable("uninstall")
        if not (kv and part:getInventoryItem()) then T.off = true; Q.skip(T.L, "the car has no muffler with an uninstall table"); return end
        local pr = C.profTry()
        if not pr then T.off = true; Q.skip(T.L, "the game's testProfession throws on any profession string in this build (it wants a CharacterProfession), so no part table can name one"); return end
        T.pr = pr
        S.back.tbl = { kv = kv, was = kv.professions }
        kv.professions = pr
    end)
    H.lookQ(T)
    H.cardQ(T, "Muffler")
    Q.waitMs(500)
    H.step(2, function()
        if T.off then H.tblBack(); return end
        local game = nil
        pcall(function() game = T.v:canUninstallPart(S.p, H.part(T.v, "Muffler")) end)
        local bare = H.needsHas(H.notNowFor("IGUI_Uninstall"))
        Q.check(game == false, T.L .. ": the game refuses the uninstall for the profession (" .. T.pr .. ")", tostring(game))
        Q.check(bare == nil, T.L .. " (M10): the NEEDS line names the missing profession", "the NEEDS lines drawn: " .. H.needsText() .. "; footer " .. H.footText())
        H.tblBack()
    end)
    H.caseEnd(T.L)
end
-- c. a brake missing under its tire: the game's InstallTest ignores requireUninstalled
function C.c10brake()
    local T = { L = "10c M10 a brake missing, its tire on" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        H.give("Base.Jack")
        H.give("Base.Wrench")
        H.learn("Basic Mechanics")
        local it = H.takeItem(T.v, "BrakeFrontLeft")
        if not it then T.off = true; Q.skip(T.L, "the car has no front left brake"); return end
        pcall(function() H.inv():AddItem(it) end)
        H.mark(it)
    end)
    H.lookQ(T)
    H.cardQ(T, "BrakeFrontLeft")
    Q.waitMs(500)
    H.step(2, function()
        if T.off then return end
        local game = nil
        pcall(function() game = T.v:canInstallPart(S.p, H.part(T.v, "BrakeFrontLeft")) end)
        T.step = H.z("mech:step") ~= nil
        T.stepWords = H.drew(ZeD.tr("UI_ZeD_Veh_TakeOffFirst")) ~= nil
        T.lit = H.lit("mech:verb:install")
        H.note(T.L .. ": the game's canInstallPart " .. tostring(game) .. "; Install lit " .. tostring(T.lit) .. "; the step before drawn " .. tostring(T.step) .. " (\"" .. ZeD.tr("UI_ZeD_Veh_TakeOffFirst") .. "\" " .. tostring(T.stepWords) .. ")")
        Q.check(not (game == true and T.step), T.L .. " (M10): the card asks for no step the game does not need",
            "the game installs with the tire on (canInstallPart " .. tostring(game) .. ") but the card says take the tire off first; Install lit " .. tostring(T.lit))
        if T.lit then H.click("mech:verb:install", T.L) end
    end)
    H.waitQ(T, 60000)
    H.step(2, function()
        if T.off then return end
        H.note(T.L .. ": Install pressed with the tire on: the brake on " .. tostring(H.item(T.v, "BrakeFrontLeft") ~= nil) .. ", the tire on " .. tostring(H.item(T.v, "TireFrontLeft") ~= nil) .. " (the game's own result)")
    end)
    H.caseEnd(T.L)
end
-- d. a fixer short of its uses; f. a door the game repairs only off the car
function C.c10fix()
    local T = { L = "10d M10 a fixer short of its uses" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        if not C.fixFind(T, true) then T.off = true; Q.skip(T.L, "no recipe row on this car takes more than one use of its fixer"); return end
        H.hidden("all")   -- (Repair greyed must stay on the card for its recipe rows to draw)
        H.setCond(T.v, T.pid, 40)
        C.fixGive(T, 1, 1)
        H.note(T.L .. ": " .. T.pid .. ", recipe " .. tostring(T.fi) .. " row " .. tostring(T.xi) .. ": " .. tostring(T.xFt) .. " " .. H.usesX(T) .. "/" .. tostring(T.xN) .. ", " .. tostring(T.gFt) .. " " .. H.usesG(T) .. "/" .. tostring(T.gN))
    end)
    H.lookQ(T)
    H.cardQ(T, "pid")
    H.step(3, function()
        if T.off then return end
        local s = H.ms()
        if s then s.verb = "fix" end
    end)
    Q.waitMs(500)
    H.step(2, function()
        if T.off then return end
        -- the game: the row's sub-option is grey only for a missing fixer, a missing global item or a low skill
        -- (ISInventoryPaneContextMenu.buildFixingMenu, addFixerSubOption); its press does nothing when getRequiredItems
        -- is nil (onFix)
        local item = H.fixItem(T)
        local have, glob, req = nil, true, nil
        pcall(function() have = T.fixing:haveThisFixer(S.p, T.fixer, item) end)
        pcall(function() if T.fixing:getGlobalItem() then glob = T.fixing:haveGlobalItem(S.p) ~= nil end end)
        pcall(function() req = T.fixing:getRequiredItems(S.p, T.fixer, item) end)
        T.gameGrey = (have == nil) or not glob
        T.gameDoes = req ~= nil
        -- ZeD's row: a click on a grey row does not pick it (its press keeps the pick unless the row is ok); read at
        -- once, before the next draw puts the pick back on a lit row
        local rowId, fr, idx = nil, 0, 0
        for i = 1, 12 do if H.z("mech:fix:" .. i) then fr = fr + 1 end end
        pcall(function()
            local fixes = FixingManager.getFixes(item)
            for fi = 0, fixes:size() - 1 do
                for xi = 0, fixes:get(fi):getFixers():size() - 1 do
                    idx = idx + 1
                    if fi == T.fi and xi == T.xi then rowId = idx end
                end
            end
        end)
        T.row, T.fr = rowId, fr
        T.words = rowId and table.concat(H.textsIn(H.z("mech:fix:" .. rowId)), " / ") or "no row"
        local s = H.ms()
        if not (s and rowId and H.z("mech:fix:" .. rowId)) then Q.skip(T.L, "the recipe row was not drawn (" .. fr .. " rows; " .. H.footText() .. ")"); return end
        s.fixPick = 99
        H.click("mech:fix:" .. rowId, T.L)
        local picked = s.fixPick == rowId
        H.note(T.L .. ": the game's menu shows the row " .. (T.gameGrey and "grey" or "lit") .. " and its press " .. (T.gameDoes and "repairs" or "does nothing (getRequiredItems nil)")
            .. "; ZeD's row " .. tostring(rowId) .. " of " .. fr .. " " .. (picked and "picks (lit)" or "does not pick (grey)") .. ": " .. T.words)
        Q.check(picked == T.gameDoes, T.L .. " (M10): ZeD's repair row is lit exactly when the game's press would repair",
            "ZeD lit " .. tostring(picked) .. "; the game's press repairs " .. tostring(T.gameDoes) .. " (its menu shows it " .. (T.gameGrey and "grey" or "lit") .. ")")
    end)
    H.caseEnd(T.L)
end
function C.c10door()
    local T = { L = "10f M10 a part repaired only off the car" }
    H.step(2, function() H.caseStart(T) end)
    H.lookQ(T)
    H.cardQ(T, "DoorFrontLeft")
    Q.waitMs(500)
    H.step(2, function()
        if T.off then return end
        local says = false
        pcall(function()
            local part = H.part(T.v, "DoorFrontLeft")
            local item = part:getInventoryItem()
            says = item ~= nil and not part:getScriptPart():isRepairMechanic() and not FixingManager.getFixes(item):isEmpty()
        end)
        local word = getText("Tooltip_RepairableUninstalled")
        if not says then Q.skip(T.L, "the game does not call this door repairable once uninstalled"); return end
        Q.check(H.drew(word) ~= nil, T.L .. " (M10): the card says what the game says (\"" .. word .. "\")", "footer " .. H.footText() .. "; NEEDS " .. H.needsText())
    end)
    H.caseEnd(T.L)
end
-- g. Install with no spare in reach, folded and all
function C.c10none()
    local T = { L = "10g M10 Install with no spare near" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        local it = H.takeItem(T.v, "TireRearRight")
        if not it then T.off = true; Q.skip(T.L, "the car has no rear right tire"); return end
        T.names = {}
        pcall(function()
            local ty = H.part(T.v, "TireRearRight"):getItemType()
            for i = 0, ty:size() - 1 do T.names[#T.names + 1] = getItemName(ty:get(i)) end
        end)
        H.give("Base.Jack")
        H.give("Base.LugWrench")
    end)
    H.lookQ(T)
    H.cardQ(T, "TireRearRight")
    Q.waitMs(500)
    H.step(2, function()
        if T.off then return end
        T.folded = 0
        for _, n in ipairs(T.names) do if H.drew(string.sub(tostring(n), 1, 10)) then T.folded = T.folded + 1 end end
        T.foot1 = H.footText()
        H.hidden("all")
    end)
    Q.waitMs(600)
    H.step(2, function()
        if T.off then return end
        local all = 0
        for _, n in ipairs(T.names) do if H.drew(string.sub(tostring(n), 1, 10)) then all = all + 1 end end
        Q.check(T.folded > 0, T.L .. " (M10): with hidden actions folded the card names the types that fit (the game lists them under Install)",
            T.folded .. " of " .. #T.names .. " named folded (footer " .. tostring(T.foot1) .. "); with all: " .. all .. " named (footer " .. H.footText() .. "); the game's types " .. H.list(T.names))
    end)
    H.caseEnd(T.L)
end
function C.c10()
    C.c10batt()
    C.c10prof()
    C.c10brake()
    C.c10fix()
    C.c10door()
    C.c10none()
end

-- ===================================================================== 11. the game's part menu on a pad (M11)
function H.ctx() local c = nil; pcall(function() c = getPlayerMechanicsUI(S.pn).context end); return c end
function H.ctxVis() local c = H.ctx(); local v = false; if c then pcall(function() v = c:isVisible() and true or false end) end; return v end
function H.ctxShut() local c = H.ctx(); if c then pcall(function() c:setVisible(false) end) end end
function C.c11()
    local T = { L = "11 M11 X and the game's part menu" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        H.give("Base.Jack")
        H.give("Base.LugWrench")
        H.ctxShut()
    end)
    H.lookQ(T)
    H.step(3, function()
        if T.off then return end
        local s = H.ms()
        if s then s.card = nil end
        H.park(true)   -- (the pointer hidden, as on a pad)
        T.go = H.padOn() and H.focusEl("mech:row:TireFrontLeft")
        if not Q.check(T.go, T.L .. ": the pad's focus lands on the tire's row", "on " .. tostring(H.focusedId())) then T.off = true end
    end)
    H.tapX(function() return T.go and not T.off end)
    Q.waitMs(600)
    H.step(2, function()
        if T.off then return end
        local c = H.ctx()
        local z, s = H.z("mech:row:TireFrontLeft"), H.ms()
        local ax, ay = 0, 0
        pcall(function() ax, ay = s.panel:getAbsoluteX() + z.x, s.panel:getAbsoluteY() + z.y end)
        local cx, cy, n = -1, -1, 0
        pcall(function() cx, cy, n = c:getX(), c:getY(), c.numOptions or 0 end)
        -- (ZeD draws the game's menus itself, Overrides/ContextMenu.lua: its own menu (c._zedMenu) at the menu's anchor
        -- (c._zedAnchorX/Y), the game's ISContextMenu parked off screen. Where the player sees it is ZeD's menu)
        local zx, zy, axA, ayA = nil, nil, nil, nil
        pcall(function() axA, ayA = c._zedAnchorX, c._zedAnchorY end)
        pcall(function() if c._zedMenu then zx, zy = c._zedMenu:getX(), c._zedMenu:getY() end end)
        local vx, vy = cx, cy
        if zx ~= nil then cx, cy = zx, zy end
        local sw, sh = H.screen()
        local onScreen = cx >= 0 and cy >= 0 and cx < sw and cy < sh
        local near = math.abs(cx - ax) < ZeD.T.px(480) and math.abs(cy - ay) < ZeD.T.px(300)
        T.vis = H.ctxVis()
        Q.check(T.vis, T.L .. " (M11): X on a row opens the game's part menu", "visible " .. tostring(T.vis) .. ", " .. tostring(n) .. " options")
        Q.check(T.vis and onScreen and near, T.L .. " (M11): with the pointer hidden the menu opens on screen by the focused row",
            "the shown menu at " .. math.floor(cx) .. "," .. math.floor(cy) .. " (ZeD's menu " .. tostring(zx) .. "," .. tostring(zy) .. ", its anchor " .. tostring(axA) .. "," .. tostring(ayA)
            .. ", the game's parked menu " .. tostring(vx) .. "," .. tostring(vy) .. "; visible " .. tostring(H.ctxVisRaw(c)) .. ", _zedSpawned " .. tostring(c and c._zedSpawned)
            .. ", _zedFailed " .. tostring(c and c._zedFailed) .. "); the row at " .. math.floor(ax) .. "," .. math.floor(ay) .. "; screen " .. sw .. "x" .. sh)
        local jp = nil
        pcall(function() jp = JoypadState.players[S.pn + 1] end)
        H.note(T.L .. ": a pad joined to the game " .. tostring(jp ~= nil) .. " (the game hands its menu the pad's focus only with one)")
    end)
    H.tapB(function() return T.go and not T.off end)
    Q.waitMs(600)
    H.step(2, function()
        if T.off then return end
        Q.check(not H.ctxVis() and H.focusedId() == "mech:row:TireFrontLeft", T.L .. " (M11): B shuts the game's menu and the focus is back on the row",
            "the menu visible " .. tostring(H.ctxVis()) .. ", the focus on " .. tostring(H.focusedId()))
        H.ctxShut()
        H.padOff()
        H.park(false)
        -- paused: right-click and X on a part (the game's menu returns at speed 0)
        H.speed(0)
        T.t0 = getTimestampMs()
        H.rclick("mech:row:TireFrontLeft")
    end)
    H.step(4, function()
        if T.off then return end
        T.pVis = H.ctxVis()
        T.pSaid = H.saidSince(T.t0)
        H.ctxShut()
        H.speed(1)
        Q.check(T.pVis or #T.pSaid > 0, T.L .. " (M11): paused, a right-click on a part shows the menu or says why not",
            "the menu visible " .. tostring(T.pVis) .. ", words " .. H.list(T.pSaid) .. " (the game's menu returns at speed 0, ISVehicleMechanics:209)")
        if H.debug() then Q.skip(T.L .. ": X seated", "a debug game opens the game's menu for a seated player (ISVehicleMechanics:212)") end
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== 12. paused (M12)
function C.c12()
    local T = { L = "12 M12 verbs while paused" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        H.give("Base.TirePump")
        pcall(function() local part = H.part(T.v, "TireFrontLeft"); part:setContainerContentAmount(part:getContainerCapacity() - 10) end)
        pcall(function() T.air0 = H.part(T.v, "TireFrontLeft"):getContainerContentAmount() end)
    end)
    H.lookQ(T)
    H.cardQ(T, "TireFrontLeft")
    H.step(3, function()
        if T.off then return end
        if not H.lit("mech:verb:inflate") then T.off = true; Q.skip(T.L, "Inflate is not lit (" .. H.footText() .. ")"); return end
        H.speed(0)
        T.spd = getGameSpeed()
    end)
    H.step(3, function() if not T.off then H.click("mech:verb:inflate", T.L) end end)
    H.step(3, function()
        if T.off then return end
        T.n1, T.k1 = H.qlen(), H.qkinds()
        H.qstop()
        T.go = H.padOn() and H.focusEl("mech:verb:inflate")
    end)
    H.tapA(function() return T.go and not T.off end)
    H.step(4, function()
        if T.off then return end
        T.n2, T.k2 = H.qlen(), H.qkinds()
        H.qstop()
        H.padOff()
    end)
    H.cardQ(T, "WindowFrontLeft")
    H.step(3, function() if not T.off then H.click("mech:verb:smash", T.L) end end)
    H.step(3, function() if not T.off then T.asked = H.z("mech:confirm:yes") ~= nil; H.click("mech:confirm:yes", T.L) end end)
    H.step(3, function()
        if T.off then return end
        T.n3, T.k3 = H.qlen(), H.qkinds()
        H.qstop()
        H.speed(1)
    end)
    Q.waitMs(1500)
    H.step(2, function()
        H.speed(1)
        if T.off then return end
        -- (a pad press the paused game held back could fire once it runs again: said, and cleared)
        if H.qlen() > 0 then H.note(T.L .. ": after the game ran again its queue held " .. H.qkinds() .. " (a press held back while paused): cleared"); H.qstop() end
        local broken, air = nil, nil
        pcall(function() broken = H.part(T.v, "WindowFrontLeft"):getWindow():isDestroyed() end)
        pcall(function() air = H.part(T.v, "TireFrontLeft"):getContainerContentAmount() end)
        Q.check(T.n1 == 0, T.L .. " (M12): paused, Inflate by the mouse queues nothing (the game's part menu refuses at speed 0)", "game speed " .. tostring(T.spd) .. "; queued " .. tostring(T.k1))
        Q.check(T.n2 == 0, T.L .. " (M12): paused, the pad's A on Inflate queues nothing", "pad focus " .. tostring(T.go) .. "; queued " .. tostring(T.k2))
        Q.check(T.n3 == 0, T.L .. " (M12): paused, Smash's Yes queues nothing", "asked " .. tostring(T.asked) .. "; queued " .. tostring(T.k3))
        Q.check(broken == false and air ~= nil and T.air0 ~= nil and math.abs(air - T.air0) < 0.5, T.L .. ": the queue cleared before the game ran left the window and the tire untouched",
            "window smashed " .. tostring(broken) .. ", air " .. H.n1(air) .. " (was " .. H.n1(T.air0) .. ")")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== 13. a car that changes while open (M13)
function C.c13gone()
    local T = { L = "13a M13 a part gone inside the cache time" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        H.give("Base.Jack")
        H.give("Base.LugWrench")
    end)
    H.lookQ(T)
    H.cardQ(T, "TireRearLeft")
    H.step(3, function()
        if T.off then return end
        if not H.lit("mech:verb:uninstall") then T.off = true; Q.skip(T.L, "Uninstall is not lit (" .. H.footText() .. ")"); return end
        T.inv0 = H.count(H.ft(H.item(T.v, "TireRearLeft")))
        T.tft = H.ft(H.item(T.v, "TireRearLeft"))
        -- taken off as another player would; Uninstall pressed in the same frame (the parts read every 250 ms)
        H.takeItem(T.v, "TireRearLeft")
        T.t0 = getTimestampMs()
        H.click("mech:verb:uninstall", T.L)
        T.k = H.qkinds()
    end)
    H.wait(1500, function()
        if T.off then return true end
        local s = H.ms()
        local m = s and s.partById and s.partById.TireRearLeft
        return m ~= nil and m.missing == true
    end, function(ok)
        if T.off then return end
        T.redraw = ok and (getTimestampMs() - T.t0) or nil
    end)
    H.waitQ(T, 30000)
    H.step(2, function()
        if T.off then return end
        local said = H.saidSince(T.t0)
        H.note(T.L .. ": the press on the part already gone queued " .. tostring(T.k) .. "; the queue ended with nothing installed or taken (tires of the type in his bags " .. H.count(T.tft) .. ", was " .. tostring(T.inv0) .. ")")
        Q.check(T.redraw ~= nil and T.redraw <= 400, T.L .. ": the card shows the part missing within the tab's read time", tostring(T.redraw) .. " ms")
        Q.check(#said > 0 or string.find(tostring(T.k), "ISUninstallVehiclePart", 1, true) == nil, T.L .. " (M13): a press on a part already gone is refused or the player is told",
            "queued " .. tostring(T.k) .. "; words said " .. H.list(said))
    end)
    H.caseEnd(T.L)
end
function H.tabLabels()
    local s = H.ms()
    local o = {}
    local ok, items = pcall(S.MT.vehicleTabItems, (s and s.vehicles) or {})
    if not ok then return o end
    for i, it in ipairs(items or {}) do
        local e = s.vehicles[i]
        o[#o + 1] = { label = tostring(it.label), id = e and e.id, v = e and e.vehicle }
    end
    return o
end
function H.labelOf(list, v) for _, x in ipairs(list) do if x.v == v then return x.label end end; return nil end
function C.c13two()
    local T = { L = "13b M13 two cars of one model" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        if not (S.vB and H.live(S.vB)) then T.off = true; Q.skip(T.L, S.noB or "no second car"); return end
        T.mid = (S.vA:getX() + S.vB:getX()) / 2
        T.y = S.vA:getY() + 0.5
        T.sideA = (S.vA:getX() < S.vB:getX()) and -1 or 1
        H.goTo(T.mid + T.sideA * 0.4, T.y, 0)
        RT.pairOpen()
    end)
    Q.waitMs(1600)
    H.step(2, function()
        if T.off then return end
        RT.worldTab("vehicle")
        T.l1 = H.tabLabels()
        T.shown1 = H.curV()
    end)
    Q.waitMs(400)
    H.step(2, function()
        if T.off then return end
        H.goTo(T.mid - T.sideA * 0.4, T.y, 0)
    end)
    Q.waitMs(1600)
    H.step(2, function()
        if T.off then return end
        T.l2 = H.tabLabels()
        T.shown2 = H.curV()
        local a1, a2 = H.labelOf(T.l1, S.vA), H.labelOf(T.l2, S.vA)
        local b1, b2 = H.labelOf(T.l1, S.vB), H.labelOf(T.l2, S.vB)
        local txt = "nearer the first: first " .. tostring(a1) .. ", second " .. tostring(b1) .. "; nearer the second: first " .. tostring(a2) .. ", second " .. tostring(b2)
        if not (a1 and b1 and a2 and b2) then Q.skip(T.L, "both cars were not on the tab at both places (" .. txt .. ")"); return end
        Q.check(a1 == a2 and b1 == b2, T.L .. " (M13): a car's tab keeps its name as he steps between two cars of one model", txt)
        Q.check(T.shown1 == T.shown2, T.L .. ": the shown car stays the same car", tostring(T.shown1 and T.shown1:getId()) .. " -> " .. tostring(T.shown2 and T.shown2:getId()))
    end)
    H.caseEnd(T.L)
end
function C.c13both()
    local T = { L = "13c M13 two cars looked at" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        if not (S.vB and H.live(S.vB)) then T.off = true; Q.skip(T.L, S.noB or "no second car"); return end
        T.vB = S.vB
    end)
    H.lookQ(T)
    H.step(2, function() if not T.off then H.atCar(T.vB) end end)
    H.lookQ(T, "vB")
    H.step(3, function()
        if T.off then return end
        local fa, fb = H.mechFlag(T.v), H.mechFlag(T.vB)
        local ia, ib = H.insp(T.v), H.insp(T.vB)
        if fa == nil then Q.skip(T.L, "the game's mechanic flag (isMechanicUIOpen) cannot be read"); return end
        Q.check(not (fa and fb), T.L .. " (M13): one car at a time carries the game's mechanic flag (the game's window holds one car)",
            "the first car: flag " .. tostring(fa) .. ", looked at " .. tostring(ia) .. "; the second: flag " .. tostring(fb) .. ", looked at " .. tostring(ib))
        Q.skip(T.L .. ": what the flag does to a car another player gets into", "needs a second player (multiplayer)")
        Q.skip("13d M13 a car driven off by another player within six tiles", "needs a second player to drive it (multiplayer)")
    end)
    H.caseEnd(T.L)
end
function C.c13()
    C.c13gone()
    C.c13two()
    C.c13both()
end

-- ===================================================================== 14. multiplayer (M14)
function C.c14()
    H.step(2, function()
        Q.skip("14 M14 claims: Install, Repair, Smash and Deflate on another's claimed car", "needs a server with vehicle claims on and a second player")
        Q.skip("14 M14 the flash after a server-side install, a part taken by another player", "needs a server and a second player")
        local pb = nil
        pcall(function() pb = ZeD.Extras and ZeD.Extras.partsBlock and ZeD.Extras.partsBlock(S.vA) end)
        H.note("14 M14 single player: the claims' block on the car is " .. tostring(pb) .. " (no claims off a server)")
        Q.check(#S.mad > 0 and S.flashSeen ~= nil, "14 M14 single player: after the installs the game's OnMechanicActionDone fired and the tab flashed its band",
            #S.mad .. " game events; the band's words seen (lower case): " .. string.lower(tostring(S.flashSeen)))
    end)
end

-- ===================================================================== 15. trailers (M15)
function C.c15()
    local T = { L = "15 M15 a livestock trailer" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        H.home()
        local hx, hy = math.floor(S.p:getX()), math.floor(S.p:getY())
        for _, o in ipairs({ { 0, -6 }, { 0, 6 }, { -6, 0 }, { 6, 0 }, { -4, -6 }, { 4, 6 } }) do
            local x, y = hx + o[1], hy + o[2]
            if not T.sq and H.boxClear(x - 1, y - 3, x + 1, y + 3) and not H.carNear(x + 0.5, y + 0.5, 4) then T.sq = getCell():getGridSquare(x, y, 0) end
        end
        if not T.sq then T.off = true; Q.skip(T.L, "no clear ground for a trailer near home"); return end
        local okV, tr = pcall(addVehicleDebug, "Base.Trailer_Livestock", IsoDirections.N, nil, T.sq)
        if not (okV and tr) then T.off = true; Q.skip(T.L, "addVehicleDebug gave no livestock trailer"); return end
        T.tr = tr
        S.cars[#S.cars + 1] = tr
        if ZEDQA_CAR_KEEP then ZEDQA_CAR_KEEP[tr] = true end
    end)
    H.wait(8000, function() return T.off or (ZEDQA_CAR_READY and ZEDQA_CAR_READY(T.tr)) end, function(ok)
        if T.off then return end
        if not ok then H.note(T.L .. ": the trailer's physics never showed awake in 8 s (it is not entered: the checks go on)") end
        H.goTo(T.tr:getX() + 2.5, T.tr:getY() + 0.5, 0)
        RT.pairOpen()
    end)
    Q.waitMs(1200)
    H.step(2, function()
        if T.off then return end
        H.qstop()
        T.inReach = false
        pcall(function() T.inReach = S.MT.inReach(S.p, T.tr) end)
        pcall(ISVehicleMenu.onCheckAnimalInside, T.tr, S.p)
        T.k = H.qkinds()
        T.n = H.qlen()
    end)
    H.wait(4000, function() return T.off or (H.onTab() and H.curV() == T.tr) end, function(ok)
        if T.off then return end
        Q.check(ok, T.L .. ": the game's Check Animals opens the Vehicle tab on the trailer", H.tabText())
        Q.check(T.n == 0, T.L .. " (M15): Check Animals in reach queues no walk", "in reach " .. tostring(T.inReach) .. "; queued " .. tostring(T.k))
        Q.check(not H.insp(T.tr) and H.z("mech:inspect") ~= nil, T.L .. " (M15): the trailer is pinned, not looked at: its parts wait for Inspect",
            "looked at " .. tostring(H.insp(T.tr)) .. ", Inspect drawn " .. tostring(H.z("mech:inspect") ~= nil))
        H.goTo(T.tr:getX() + 5.5, T.tr:getY(), 0)
    end)
    Q.waitMs(2000)
    H.step(2, function()
        if T.off then return end
        T.d55, T.at55 = H.dist(T.tr), H.listed(T.tr)
        H.goTo(T.tr:getX() + 7.2, T.tr:getY(), 0)
    end)
    Q.waitMs(2000)
    H.step(2, function()
        if T.off then return end
        local d7, at7 = H.dist(T.tr), H.listed(T.tr)
        Q.check(T.at55 and not at7, T.L .. " (M15): the pinned trailer stays on the tab to six tiles and drops past it",
            "at " .. H.n1(T.d55) .. " tiles listed " .. tostring(T.at55) .. "; at " .. H.n1(d7) .. " tiles listed " .. tostring(at7))
        Q.skip(T.L .. ": an unhitched trailer drops from its car's pair", "the game's hitch (ISAttachTrailerToVehicle) needs the trailer backed to a car's hitch point: not staged on the strip")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== 16. readings (M16)
function C.c16overall()
    local T = { L = "16a M16 Overall" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        H.setCond(T.v, "Engine", 73)
        H.setCond(T.v, "TrunkDoor", 41)
        H.setCond(T.v, "TireFrontLeft", 88)
        H.setCond(T.v, "HeadlightLeft", 7)
    end)
    H.lookQ(T)
    Q.waitMs(500)
    H.step(2, function()
        if T.off then return end
        local g = nil
        pcall(function()
            local ui = getPlayerMechanicsUI(S.pn)
            local was = ui.vehicle
            ui.vehicle = T.v
            ui:recalculGeneralCondition()
            g = ui.generalCondition
            ui.vehicle = was
        end)
        local shown = H.valueBeside(H.cased(ZeD.tr("UI_ZeD_Veh_Overall"))) or H.valueBeside(ZeD.tr("UI_ZeD_Veh_Overall"))
        local nod, nodSum, missing = 0, 0, 0
        pcall(function()
            for i = 0, T.v:getPartCount() - 1 do
                local part = T.v:getPartByIndex(i)
                if part:getCategory() == "nodisplay" then nod = nod + 1; nodSum = nodSum + part:getCondition() end
                local it = part:getItemType()
                if it and not it:isEmpty() and not part:getInventoryItem() then missing = missing + 1 end
            end
        end)
        if g == nil then Q.skip(T.L, "the game's recalculGeneralCondition could not be run on its hidden window"); return end
        local want = tostring(math.floor(g + 0.5)) .. "%"
        Q.check(shown == want, T.L .. ": Overall reads the game's general condition, rounded to a whole number", "drawn " .. tostring(shown) .. "; the game's " .. H.n2(g) .. " (two places)")
        H.note(T.L .. ": both count " .. nod .. " nodisplay part(s) (their conditions sum " .. nodSum .. ") and " .. missing .. " item-less part(s) as 0, which the list does not show")
    end)
    H.caseEnd(T.L)
end
function C.c16noTable()
    H.step(2, function()
        local found = nil
        pcall(function()
            for i = 0, S.vA:getPartCount() - 1 do
                local part = S.vA:getPartByIndex(i)
                local it = part:getItemType()
                if not found and it and not it:isEmpty() and part:getTable("install") == nil and part:getCategory() ~= "nodisplay" then found = part:getId() end
            end
        end)
        if not found then Q.skip("16b M16 a part with an item type and no install table", "this car has none (a modded car's part)")
        else H.note("16b M16 " .. found .. " has an item type and no install table: with its item gone the row reads its condition, Overall 0 (not staged: emptying it has no game path)") end
    end)
end
-- c. the failure share against the game's odds of damage (uninstall: any failure damages; install: the second roll)
function C.c16fail(verb)
    local T = { L = "16c M16 the failure share (" .. verb .. ")" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        H.give("Base.Jack")
        H.give("Base.LugWrench")
        if verb == "install" then
            local it = H.takeItem(T.v, "TireFrontLeft")
            T.spare = H.give(H.ft(it))
        end
        H.mech(0)
    end)
    H.lookQ(T)
    H.cardQ(T, "TireFrontLeft")
    Q.waitMs(600)
    H.step(2, function()
        if T.off then return end
        local s = H.ms()
        if s then s.verb = verb end
    end)
    Q.waitMs(500)
    H.step(2, function()
        if T.off then return end
        local part = H.part(T.v, "TireFrontLeft")
        local own, inst = nil, nil
        pcall(function() own = part:getTable(verb).skills; inst = part:getTable("install").skills end)
        local sc, fc = VehicleUtils.calculateInstallationSuccess(own, S.p)
        local si, fi = VehicleUtils.calculateInstallationSuccess(inst, S.p)
        local odds = (verb == "uninstall") and (100 - si) or math.floor((100 - si) * fi / 100 + 0.5)
        local shownText = H.cased(ZeD.tr("UI_ZeD_Veh_FailurePct", tostring(fc) .. "%"))
        local drawn = H.drewExact(shownText) ~= nil or H.drew(tostring(fc) .. "%") ~= nil
        if not drawn then Q.skip(T.L, "the failure share was not drawn (" .. H.textsLike("%") .. ")"); return end
        Q.check(fc == odds, T.L .. " (M16): the failure share shown is the game's odds of damaging the part",
            "shown " .. fc .. "% beside success " .. sc .. "%; the game rolls " .. si .. "% success and then " .. (verb == "uninstall" and "damages on any failure" or ("damages at " .. fi .. "% of the failures"))
            .. " (ISUninstallVehiclePart / ISInstallVehiclePart): " .. odds .. "% at Mechanics " .. H.mechLvl())
    end)
    H.caseEnd(T.L)
end
function C.c16worn()
    local T = { L = "16d M16 worn at 60" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        H.setCond(T.v, "TrunkDoor", 60)
    end)
    H.lookQ(T)
    Q.waitMs(500)
    H.step(2, function()
        if T.off then return end
        local miss, worn = 0, 0
        pcall(function()
            for i = 0, T.v:getPartCount() - 1 do
                local part = T.v:getPartByIndex(i)
                if part:getCategory() ~= "nodisplay" then
                    local it = part:getItemType()
                    local m = it and not it:isEmpty() and part:getInventoryItem() == nil and part:getTable("install") ~= nil
                    local w = part:getWindow()
                    if m or (w and w:isDestroyed()) then miss = miss + 1 elseif part:getCondition() <= 60 then worn = worn + 1 end
                end
            end
        end)
        local line = ZeD.tr("UI_ZeD_Veh_MissingWorn", miss, worn)
        local drawn = H.drew(line)
        local s60, s61 = nil, nil
        pcall(function() s60, s61 = ZeD.Atoms.statusSegsLit(0.60), ZeD.Atoms.statusSegsLit(0.61) end)
        Q.check(drawn ~= nil, T.L .. ": the summary's line counts the part at 60 as worn (by the game's conditions)", "want \"" .. line .. "\"; drawn " .. H.textsLike(tostring(worn), 4))
        Q.check(s60 ~= nil and s60 <= 3 and s61 >= 4, T.L .. " (M16): worn (60 or less) and the rows' color bands agree at 60 and 61", "segments lit at 60: " .. tostring(s60) .. ", at 61: " .. tostring(s61) .. " (4 or 5 lit is green)")
    end)
    H.caseEnd(T.L)
end
function C.c16()
    C.c16overall()
    C.c16noTable()
    C.c16fail("uninstall")
    C.c16fail("install")
    C.c16worn()
end

-- ===================================================================== 17. words (M17)
function C.langFiles()
    local have, read = {}, 0
    for _, L in ipairs({ "EN", "DE", "ES", "FR", "RU", "JP", "IT", "PL", "PTBR", "CN" }) do
        local found = false
        for _, path in ipairs({ "media/lua/shared/Translate/" .. L .. "/UI.json", "42/media/lua/shared/Translate/" .. L .. "/UI.json" }) do
            local r = nil
            pcall(function() r = getModFileReader("ZeD_UI", path, false) end)
            if r and not found then
                found = true
                read = read + 1
                local k = false
                pcall(function()
                    local ln = r:readLine()
                    while ln do
                        if string.find(ln, "UI_ZeD_Veh_TakeOffFirst", 1, true) then k = true end
                        ln = r:readLine()
                    end
                end)
                pcall(function() r:close() end)
                have[#have + 1] = L .. (k and " yes" or " NO")
            end
        end
    end
    return read, H.list(have)
end
function C.c17()
    local T = { L = "17 M17 the words" }
    H.step(2, function()
        if not H.caseStart(T) then return end
        H.give("Base.Jack")
        H.give("Base.Wrench")
        H.learn("Basic Mechanics")
    end)
    H.lookQ(T)
    H.cardQ(T, "BrakeFrontLeft")
    Q.waitMs(500)
    H.step(2, function()
        if T.off then return end
        local lang = H.lang()
        local w = ZeD.tr("UI_ZeD_Veh_TakeOffFirst")
        Q.check(H.drew(w) ~= nil, T.L .. ": the step before's words draw in the run's language (" .. lang .. ")", "\"" .. w .. "\"")
        if lang == "EN" then Q.skip(T.L .. " (M17): the step before's words in the other languages", "the run is in EN: each language needs a game started in it") end
        local read, have = C.langFiles()
        if read > 0 then H.note(T.L .. ": UI_ZeD_Veh_TakeOffFirst in ZeD's UI.json, read through the game's mod file reader: " .. have)
        else H.note(T.L .. ": ZeD's UI.json files could not be read through getModFileReader here") end
    end)
    H.cardQ(T, "WindowFrontLeft")
    H.step(3, function() if not T.off then S.qLast = nil; H.click("mech:verb:smash", T.L) end end)
    H.wait(2000, function() return T.off or S.qLast ~= nil end, function(ok)
        if T.off then return end
        local q = tostring(S.qLast)
        local name = getText("IGUI_VehiclePartWindowFrontLeft")
        local asIs = H.has(q, name)
        local lower = H.has(q, string.lower(name))
        local lang = H.lang()
        H.note(T.L .. ": the Smash question \"" .. q .. "\"; the game's part name \"" .. name .. "\" (as written " .. tostring(asIs) .. ", lower case " .. tostring(lower) .. ")")
        if lang == "DE" then Q.check(asIs, T.L .. " (M17): the Smash question keeps the game's part name as the game writes it (German nouns)", q)
        else Q.skip(T.L .. " (M17): the Smash question's lower case in a language that capitalizes nouns", "the run is in " .. lang) end
        H.click("mech:confirm:no", T.L)
        Q.check(S.notNowSeen == nil, T.L .. " (M17): no NEEDS line reads \"" .. H.notNowFor("IGUI_Uninstall") .. "\" without a reason (see 10a)", tostring(S.notNowSeen))
        H.note(T.L .. ": the flash's words seen this run (lower case): " .. string.lower(tostring(S.flashSeen)) .. " (Done is the game's UI_mods_Done \"" .. string.lower(tostring(S.doneWord)) .. "\" in capitals, Failed is ZeD's \"" .. tostring(S.failWord) .. "\")")
    end)
    H.caseEnd(T.L)
end

-- ===================================================================== put back
function H.putBack()
    if not S.back.on then return end
    S.back.on = nil
    local f = S.found
    H.speed(1)
    H.qstop()
    H.park(false)
    H.padOff()
    H.ctxShut()
    H.tblBack()
    H.hiddenBack()
    H.halfBack()
    H.wrapOff()
    H.toLoot()
    H.qstop()
    pcall(function() if S.p:getVehicle() then local car = S.p:getVehicle(); car:exit(S.p); triggerEvent("OnExitVehicle", S.p) end end)
    for _, v in ipairs(S.cars) do pcall(function() v:setRegulator(false) end) end
    for _, c in ipairs(S.objs) do H.rmObj(c) end
    for _, it in ipairs(S.made) do H.removeItem(it) end
    H.recipesBack()
    S.xpGrew, S.xpLeft = H.xpBack()
    ISVehicleMechanics.cheat = f.cheat
    if f.mui and f.mui.ui then pcall(function() f.mui.ui.vehicle = f.mui.vehicle; f.mui.ui.chr = f.mui.chr end) end
    if f.recorded then
        pcall(function() S.p:setTimedActionInstantCheat(f.inst and true or false) end)
        pcall(function() if f.tod then getGameTime():setTimeOfDay(f.tod) end end)
        local s = H.ms()
        if s and f.mstate then
            s.sort, s.collapsed = f.mstate.sort, f.mstate.collapsed
            s.card, s.confirm, s.sortOpen, s.verb = nil, nil, nil, nil
        end
    end
end
function S.buildPutBack()
    Q.mark()
    Q.step(2, function()
        H.putBack()
        H.home()
    end)
    -- the cars: the prelude's removal, a tick after he is out (removing one in the tick of the exit drops the game)
    Q.step(6, function()
        for _, v in ipairs(S.cars) do
            if ZEDQA_CAR_KEEP then ZEDQA_CAR_KEEP[v] = nil end
            if ZEDQA_CAR_AWAY then pcall(ZEDQA_CAR_AWAY, v) else pcall(function() v:permanentlyRemove() end) end
        end
    end)
    Q.waitMs(1500)
    Q.step(10, function()
        local f = S.found
        if not f.recorded then return end
        S.swept = H.sweepNew()
        S.lost = H.unstash()
        local now, n = {}, 0
        for _, it in ipairs(H.all()) do local ft = H.ft(it); now[ft] = (now[ft] or 0) + 1 end
        for ft, was in pairs(f.types or {}) do
            for _ = 1, was - (now[ft] or 0) do
                local it = nil
                pcall(function() it = H.inv():AddItem(ft) end)
                if it then f.inv0[it] = true; n = n + 1 end
            end
        end
        S.refilled = n
        S.floorSwept = H.sweepFloor()
        H.hands()
        H.home()
        if S.layoutTouched and f.layout and ZEDQA_LAYOUT_BACK then pcall(ZEDQA_LAYOUT_BACK, f.layout, "mt_tab") end
        local w = RT.ww()
        if w then w._maxWinW = f.maxW end
        H.lootRefresh()
    end)
    Q.step(20, function()
        local f = S.found
        if not f.recorded then return end
        pcall(ZeD_CharacterWindow.openTab, S.pn, f.ctab or "loot")
        if f.wtab and f.wtab ~= "vehicle" then RT.worldTab(f.wtab) else RT.worldTab("loot") end
    end)
    Q.step(20, function()
        local f = S.found
        if not f.recorded then Q.skip("put back", "nothing was staged"); return end
        local carsLeft = 0
        for _, v in ipairs(S.cars) do if H.live(v) then carsLeft = carsLeft + 1 end end
        Q.check(carsLeft == 0, "put back: every car the run spawned is gone (the two sedans, the trailer)", #S.cars .. " spawned, " .. carsLeft .. " left")
        local left = {}
        for _, it in ipairs(S.made) do if not H.gone(it) then left[#left + 1] = H.ft(it) end end
        Q.check(#left == 0, "put back: every thing the run gave is gone (the bags, the floor, the crates)", #S.made .. " given; left " .. H.list(left, 8))
        local extra = {}
        for _, it in ipairs(H.all()) do if not f.inv0[it] then extra[#extra + 1] = H.ft(it) end end
        Q.check(#extra == 0 and (S.lost or 0) == 0, "put back: he carries what he carried (nothing made left, his set-aside things back)",
            "new " .. H.list(extra, 8) .. "; " .. tostring(S.swept) .. " swept, " .. tostring(S.floorSwept) .. " off the floor, " .. tostring(S.refilled)
            .. " of his own used things given again, " .. tostring(S.lost) .. " set-aside things not given back")
        local objs = {}
        for _, c in ipairs(S.objs) do if H.objLeft(c) then objs[#objs + 1] = c.what end end
        Q.check(#objs == 0, "put back: every crate laid is gone", #S.objs .. " laid; left " .. H.list(objs))
        local lvlLeft = 0
        pcall(function() for _, r in ipairs(S.xp) do if S.p:getPerkLevel(r.perk) ~= r.lvl then lvlLeft = lvlLeft + 1 end end end)
        if S.xpLeftText then H.note("put back: XP drift left (levels checked): " .. S.xpLeftText) end
        Q.check(lvlLeft == 0 and H.mechLvl() == f.mech, "put back: Mechanics and every skill level as found", tostring(S.xpGrew) .. " skills changed, " .. lvlLeft .. " not at their level; Mechanics " .. H.mechLvl() .. " (found " .. tostring(f.mech) .. ")")
        local rbad, tbad = {}, {}
        for _, r in ipairs(S.RECIPES) do if H.recipeInList(r) ~= (f.recipes[r] == true) then rbad[#rbad + 1] = r end end
        for _, k in ipairs(S.TRAITS) do if H.hasTrait(k) ~= (f.traits[k] == true) then tbad[#tbad + 1] = k end end
        Q.check(#rbad == 0 and #tbad == 0, "put back: the mechanics recipes and his traits as found", "recipes " .. H.list(rbad) .. "; traits " .. H.list(tbad))
        local tbl = S.back.tbl == nil
        local s = H.ms()
        local ms = s == nil or f.mstate == nil or (s.sort == f.mstate.sort and s.card == nil and s.confirm == nil)
        Q.check(tbl and ms and H.optVal(ZeD.Settings and ZeD.Settings.hiddenActionsOption) == f.hiddenIdx and ISVehicleMechanics.cheat == f.cheat,
            "put back: the muffler's table, the Vehicle tab's sort and card, the hidden-actions setting and the debug mechanics cheat as found",
            "table " .. tostring(tbl) .. ", sort " .. tostring(s and s.sort) .. ", hidden " .. H.hiddenNow() .. ", cheat " .. tostring(ISVehicleMechanics.cheat))
        local dx, dy = math.abs(S.p:getX() - f.pos.x), math.abs(S.p:getY() - f.pos.y)
        Q.check(dx < 0.6 and dy < 0.6 and S.p:getVehicle() == nil and H.qlen() == 0 and getGameSpeed() == 1,
            "put back: he stands where he stood, on foot, no action queued, game speed 1", string.format("%.1f,%.1f off", dx, dy) .. ", " .. H.qkinds())
        local w = RT.ww()
        Q.check(ZeD.currentBase == f.base and ZeD.currentSize == f.size and H.lockFound() == (S.lockWas or H.lockFound()) and S.parked == nil
            and S.back.maxW == nil and S.w0 == nil and (w == nil or w._maxWinW == f.maxW) and H.wrapped(),
            "put back: the theme, the text size, the input lock, the width cap, the pointer and the draw watchers as found",
            tostring(ZeD.currentBase) .. ", " .. tostring(ZeD.currentSize) .. ", lock " .. H.lockFound() .. ", width cap " .. tostring(w and w._maxWinW))
        Q.check(S.errs == 0, "put back: nothing ZeD ran for this script threw", S.errs .. " caught" .. (S.zerr and (": " .. S.zerr) or ""))
        if S.tabErrs then Q.check(false, "the Vehicle tab drew without an error", S.tabErrs .. " times; last " .. tostring(S.tabErrLast)) end
        local e1 = H.errN()
        if S.err0 and e1 then Q.check(e1 == S.err0, "the Vehicle tab run ran with no Lua error", (e1 - S.err0) .. " new")
        else Q.skip("the Vehicle tab run's Lua error count", "the game's Lua error count cannot be read here") end
        H.note("M18 is test drift (FEATURE_MAP rows 269-270, 605-606, 1280; zedqa_mech79's guarded presses of mech:confirm:yes after Uninstall and Install, which no longer ask): no in-game case")
    end)
    Q.step(10, function()
        local f = S.found
        if f.pair == false and RT.isOpen() then RT.pairShut() end
        if f.recorded then
            pcall(function() if f.invinc ~= nil then S.p:setInvincible(f.invinc) end end)
            pcall(function() if f.god ~= nil then S.p:setGodMod(f.god) end end)
        end
    end)
end

-- ===================================================================== the run
S.setup()
C.c1()
C.c2()
C.c3()
C.c4()
C.c5()
C.c7()
C.c8()
C.c9()
C.c10()
C.c11()
C.c12()
C.c13()
C.c16()
C.c17()
C.c15()
C.c14()
C.c6()
S.buildPutBack()
Q.start()
