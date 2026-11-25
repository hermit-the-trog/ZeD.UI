-- ZeDUI/tools/qa/cr_tab.lua  (Nov 25 2026, QA; tag cr_tab): the World window's Crafting tab, the whole gamut, in the
-- style of the Equipment and Thermal sweeps (eq_tab.lua, th_tab.lua). Its spec is the map
-- ZeDUI/qa/audits/2026-11-25_map_crafting.md (section 5's suspicions C1-C24 and its staging list). Run after
-- zedqa_prelude.lua and rt_kit.lua (cb.txt). grep "ZEDQA cr_tab". Each suspicion is proved or cleared with values:
-- PASS when ZeD does what the game does, FAIL with the evidence when it does not; where the map says the game's own
-- path has the same gap (C2, C8's window close, C9's moves) both are run and the pair is a NOTE (or a check that ZeD
-- loses no more than the game).
-- How it drives the tab: a click is the tab's own handler where the click lands (ZeD.CraftingTab.onClick at the zone's
-- middle, bx_craft's way), a right-click the same (onRightClick); the pad's presses go through FocusManager's QA hook
-- and its own dispatch (RT.pad + RT.padDown / RT.padDir on the World window, eq_tab's way), the input mode locked to
-- the controller and put back as found. The game's own answers are asked of the game itself (HandcraftLogic on the
-- game's own container list, ISInventoryPaneContextMenu.getContainers), never through ZeD's code under test. Crafts run
-- at x20 (ZEDQA_SPEED 3) while a craft is at the head of the queue, x1 otherwise (walks); instant actions are off.
-- The character's own things the recipes used here take (branches, knives, planks, screwdrivers, clay, sandbags,
-- bread, sticks) are set aside for the run, so every craft uses only what the case gave.
-- Cases (C<n> = the map's suspicion):
--   1 list     Category picked from its list (every row then of that category); search by name, then by an input's
--              name (C20 NOTE: ZeD's results against the recipes that take it); C18: a recipe the game holds as a
--              favourite (BaseCraftingLogic's mod data key) must show among ZeD's pinned recipes (FAIL), a ZeD pin
--              seen by the game (NOTE), the 9th pin drops the oldest silently (NOTE); Show Ready (every row ready),
--              Known (no locked row), All (more); C3: a recipe the game lets through with its literature at hand
--              (the game's own validity, getCachedRecipeInfo:isValid, with the item carried) must not read locked;
--              a recipe one skill level short reads locked, at the level it does not; a recipe learned while the tab
--              is open turns learned (then forgotten again)
--   2 counts   C4: Make Stake with one plain, favourite, held, broken branch; a favourite and a plain; the knife
--              favourite, broken, dull; Rip Clothing with a worn T-shirt; Slice Bread with fresh and rotten bread at a
--              table: Craft lit exactly when the game would start the craft, and the card's have count is what the
--              game would take (getPossibleCraftCount). NOTE: the card never says a tool may degrade
--   3 which    C5: a favourite branch given before a plain one, Craft as found and with the branch type chosen in the
--              alternatives list: the branch used is the one the game's own logic picks; a worn-down knife given
--              before a good one: the knife used is the game's pick (both named)
--   4 twice    C1: one branch, Craft pressed, then again while the craft runs: nothing more is queued (the game grays
--              its Craft while a craft runs); if a second is queued, whether it runs its whole time for nothing.
--              C2: a batch of 3 with a branch taken away mid-way, by ZeD and by the game's own batch
--              (ISEntityUI.HandcraftStartMultiple): the crafts that run their time for nothing, both NOTEd, and ZeD's
--              no more than the game's. C19 NOTE: the use count per press
--   5 batch    C7: materials for 3, 5 and 12 stakes: the band's most is the game's Max, Max sets it, what is made is
--              what was shown; a batch above the game's count refused whole as the game's own start refuses it (and
--              no message, NOTE); the branch type chosen covering 1 of the 3 the band offers: what is made is what
--              was shown (FAIL otherwise)
--   6 places   C10: a branch on the floor, in a crate, in a corpse: the game's list holds it with him standing still
--              (NOTE), the card counts it, Craft makes the stake from it; the crate's knife goes back to the crate
--              (as the game's window sends kept things back); C9: Drill Plank at a table with its plank and
--              screwdriver in a crate and the walk failing: no craft queued, and the screwdriver sent back to the
--              crate as the game's window does when its walk fails (FAIL otherwise)
--   7 grayed   C6: Craft grayed (no branch; a recipe not learned): a click and pad A on it queue and count nothing
--   8 bench    C11: Drill Plank with a table 1 square away (ZeD against the game's window, which looks 1 square) and 2
--              squares away (what Craft does); C8: a pottery wheel (bench) laid and bound as the world menu binds it:
--              the list is the wheel's recipes, Make Ceramic Teacup ZeD against the game, a batch of 2 with the World
--              window shut mid-batch (made, NOTE: the game's window lets go on close too), the lock let go on window
--              close, on walking away and on pad B; a kiln or forge SKIP (why said)
--   9 pad      every stop of the tab a known kind with its A; A on a row opens the card with the pad on Craft (C14
--              NOTE on a grayed recipe); the amount by A on + - Max (or the one box); A on the search opens the pad
--              keyboard (or gives the box the caret); C12: the Category list past its 14th row by the pad; C13: B on
--              the card with no station leaves the card as found and must not cancel the running craft (the game's B
--              shuts its window and the craft goes on); B in the alternatives (NOTE)
--   10 layout  the full card (480) and the half card (220) and Large text: every stamped zone inside the tab's
--              rectangle, every ZeD window on screen; pictures cr_* of the list, the card and the alternatives in Dark,
--              Light and High contrast (a person judges them)
--   every case: no Lua error over it; put back exactly
-- Puts back: every thing given, every thing crafted from them (the inventory and the floor around him swept of
-- anything that was not there), his own set-aside things; the laid table, crates, corpse and the pottery wheel
-- (removed as color_tabs removes its objects, and a check names any left); skills set and recipes learned; the game
-- favourite key; ZeD's pins and use counts; the debug cheats (ISBuildMenu.cheat, ISMoveableDefinitions.cheat, his
-- BuildCheat, instant actions); a bound station; the tab's Show, Sort, category, search, folds, picks, card and
-- scroll; the theme, the text size, the input lock, the window width cap and layout; game speed 1, the clock, his
-- stats and invincible (god mode is made sure on and left on, as bx_craft leaves it); where he stood and faced; the
-- World window's tab and the pair as found.
-- NOT put back: skill XP the crafts award (Carving, Pottery: a few points; said at the end).

if not RT then
    print("ZEDQA cr_tab ERR rt_kit.lua did not run first")
    print("ZEDQA cr_tab VERDICT FAIL 1")
    print("ZEDQA cr_tab DONE")
    return
end
local Q = RT.make("cr_tab")
Q.maxMs = 2200000                    -- (the runner gives this script 2400 s: the put-back runs before that)
local S = { p = RT.p, pn = RT.pn, found = {}, back = {}, made = {}, caseMade = {}, objs = {}, bodies = {}, stash = {},
            shots = {}, errs = 0, dead = false, learned = {}, perks = {}, fav = {} }
local H = {}
S.CC = ZeD and ZeD.CraftingCore
S.CT = ZeD and ZeD.CraftingTab
S.ST = ZeD and ZeD.Stations
S.WW = ZeD_WorldWindow
S.F = RT.focus()
S.R = { stake = "MakeStake", spear = "CarveSpear", drill = "DrillPlank", rip = "RipClothing", slice = "SliceBread", cup = "MakeCeramicTeacup" }
S.KIND = {
    branch = { "Base.TreeBranch2" }, stick = { "Base.WoodenStick2", "Base.Handle" },
    knife = { "Base.HuntingKnife", "Base.KitchenKnife" }, plank = { "Base.Plank" }, driver = { "Base.Screwdriver" },
    tee = { "Base.Tshirt_DefaultTEXTURE_TINT", "Base.Tshirt_White", "Base.Tshirt_DefaultDECAL" }, bread = { "Base.Bread" },
    clay = { "Base.Clay" }, sandbag = { "Base.Sandbag" },
}
S.OUT = { stake = "Base.Stake", drill = "Base.PercedWood", cup = "Base.CeramicTeacupUnfired" }
S.TABLES = { "furniture_tables_high_01_16", "furniture_tables_high_01_0", "furniture_tables_high_01_8", "furniture_tables_high_01_24",
    "furniture_tables_high_01_32", "furniture_tables_high_01_40", "furniture_tables_low_01_0", "furniture_tables_low_01_8" }
S.CRATE = "carpentry_01_16"
S.WHEEL = "Base.Pottery_Wheel"
S.NEAR = { { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }
S.FAR2 = { { 2, 0 }, { 0, 2 }, { -2, 0 }, { 0, -2 }, { 2, 1 }, { 1, 2 }, { -2, 1 }, { -1, 2 }, { 2, -1 }, { -1, -2 } }
S.WHEEL_AT = { { 2, 0 }, { 0, 2 }, { -2, 0 }, { 0, -2 }, { 3, 0 }, { 2, 2 }, { -3, 0 }, { -2, -2 } }
S.THEMES = { { key = "dark", word = "Dark" }, { key = "light", word = "Light" }, { key = "hicon", word = "High contrast" } }
S.PERK_SKIP = { Fitness = true, Strength = true }
S.STATS = { "HUNGER", "THIRST", "FATIGUE", "BOREDOM", "STRESS", "ENDURANCE", "UNHAPPINESS", "PANIC", "MORALE", "SANITY", "ANGER",
    "DISCOMFORT", "IDLENESS", "WETNESS" }

if not (S.p and S.CC and S.CT and S.ST and S.WW) then
    Q.check(false, "the player and ZeD's Crafting tab and stations are loaded")
    Q.start()
    return
end
S.orig = { render = S.CC.render, walk = ISEntityUI and ISEntityUI.WalkToEntity }

-- ===================================================================== small helpers
function H.errN() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function H.step(n, fn) Q.step(n, function() if S.dead then return end; fn() end) end
function H.noop() end
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
-- a Java method called only when the object has it (Stations.call's way: a missing method is never called)
function H.call(o, m, ...)
    if o == nil then return nil end
    local f = o[m]
    if not f then return nil end
    local ok, r = pcall(f, o, ...)
    if ok then return r end
    return nil
end
function H.has(o, m) return o ~= nil and o[m] ~= nil end
function H.list(t) local o = {}; for _, v in ipairs(t or {}) do o[#o + 1] = tostring(v) end; return (#o > 0) and table.concat(o, ", ") or "none" end
function H.n(x) if type(x) ~= "number" then return tostring(x) end; return tostring(math.floor(x + 0.5)) end
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
-- fields set on objects for the length of fn (list of { object, key, value }), always put back
function H.withFields(list, fn)
    local saved = {}
    for _, e in ipairs(list) do saved[#saved + 1] = { e[1], e[2], e[1][e[2]] }; e[1][e[2]] = e[3] end
    local ok, err = pcall(fn)
    for i = #saved, 1, -1 do local s = saved[i]; s[1][s[2]] = s[3] end
    return ok, err
end

-- ===================================================================== the timed-action queue
function H.queue() local q = nil; pcall(function() q = ISTimedActionQueue.getTimedActionQueue(S.p) end); return (q and q.queue) or {} end
function H.qlen() return #H.queue() end
function H.head() local a = H.queue()[1]; return a and tostring(a.Type) or "none" end
function H.qcount(ty) local n = 0; for _, a in ipairs(H.queue()) do if a.Type == ty then n = n + 1 end end; return n end
function H.qkinds() local o = {}; for _, a in ipairs(H.queue()) do o[#o + 1] = tostring(a.Type) end; return H.list(o) end
function H.qstop() pcall(function() ISTimedActionQueue.clear(S.p) end) end
-- a watch of the queue, every drawn frame: each action at the head, how long it was there, how far it got (its job
-- delta), and how many of ft were made while it was there. H.watchTick returns true once the queue is empty.
function H.watchNew(ft) return { ft = ft, c0 = H.count(ft), acts = {}, order = {}, cur = nil, t0 = getTimestampMs() } end
function H.watchTick(W)
    if not W then return true end
    local q = H.queue()
    local a = q[1]
    local now = getTimestampMs()
    if a ~= W.cur then
        local cnt = H.count(W.ft)
        if W.cur then local r = W.acts[W.cur]; r.made = cnt - r.c; r.ms = now - r.t end
        W.cur = a
        if a and not W.acts[a] then
            W.acts[a] = { c = cnt, t = now, d = 0, kind = tostring(a.Type), made = 0, ms = 0 }
            W.order[#W.order + 1] = a
        end
        -- (crafts at x20; walks and moves at x1: the game drops a walk above speed 2)
        H.speed((a and a.Type == "ISHandcraftAction") and 3 or 1)
    end
    if a then
        local r = W.acts[a]
        local d = nil
        pcall(function() d = a:getJobDelta() end)
        if type(d) == "number" and d > r.d then r.d = d end
        if W.onTick then pcall(W.onTick, W, a) end
    end
    return #q == 0
end
-- the crafts the watch saw: how many made something, how many ran (nearly) to their end for nothing, and a line
function H.watchSum(W)
    local out = { made = 0, empty = 0, crafts = 0, text = "" }
    if not W then return out end
    local lines = {}
    for _, a in ipairs(W.order) do
        local r = W.acts[a]
        if r.kind == "ISHandcraftAction" then
            out.crafts = out.crafts + 1
            out.made = out.made + math.max(0, r.made or 0)
            if (r.made or 0) <= 0 and r.d >= 0.9 then out.empty = out.empty + 1 end
            lines[#lines + 1] = "craft " .. out.crafts .. " " .. H.n(r.ms) .. " ms to " .. H.n(r.d * 100) .. " %, made " .. tostring(r.made)
        end
    end
    out.made = math.max(out.made, H.count(W.ft) - W.c0)
    out.text = (#lines > 0) and table.concat(lines, "; ") or "no craft ran"
    return out
end

-- ===================================================================== things
function H.isItem(it) return it ~= nil and instanceof(it, "InventoryItem") end
function H.ft(it) local s = "?"; if H.isItem(it) then pcall(function() s = tostring(it:getFullType()) end) end; return s end
function H.nm(it) local s = "nothing"; if H.isItem(it) then pcall(function() s = tostring(it:getDisplayName()) end) end; return s end
function H.where(it) local c = nil; if H.isItem(it) then pcall(function() c = it:getContainer() end) end; return c end
function H.ctype(c) local t = "none"; if c then pcall(function() t = tostring(c:getType()) end) end; return t end
function H.onFloor(it) local wo = nil; if H.isItem(it) then pcall(function() wo = it:getWorldItem() end) end; return wo ~= nil end
function H.gone(it) return H.where(it) == nil and not H.onFloor(it) end
function H.inv() return S.p:getInventory() end
function H.known(ft) local ok = false; if ft then pcall(function() ok = getScriptManager():FindItem(ft) ~= nil end) end; return ok end
function H.kind(k) for _, ft in ipairs(S.KIND[k] or {}) do if H.known(ft) then return ft end end; return nil end
-- everything carried, bags in bags too (bx_craft's)
function H.walk(inv, out, depth)
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        out[#out + 1] = it
        if depth < 4 and instanceof(it, "InventoryContainer") then
            local sub = nil
            pcall(function() sub = it:getInventory() end)
            if sub then H.walk(sub, out, depth + 1) end
        end
    end
end
function H.all() local out = {}; pcall(H.walk, H.inv(), out, 0); return out end
function H.count(ft) local n = 0; for _, it in ipairs(H.all()) do if H.ft(it) == ft then n = n + 1 end end; return n end
function H.mark(it)
    if not H.isItem(it) then return nil end
    pcall(function() it:getModData().ZeDQA_spawned = true end)
    S.made[#S.made + 1] = it
    S.caseMade[#S.caseMade + 1] = it
    return it
end
function H.give(ft)
    if not ft then return nil end
    local it = nil
    pcall(function() it = H.inv():AddItem(ft) end)
    return H.mark(it)
end
function H.giveK(k) return H.give(H.kind(k)) end
function H.giveN(ft, n) local out = {}; for _ = 1, n do local it = H.give(ft); if it then out[#out + 1] = it end end; return out end
function H.loose(it)
    if not H.isItem(it) then return end
    pcall(function() if S.p:getPrimaryHandItem() == it then S.p:setPrimaryHandItem(nil) end end)
    pcall(function() if S.p:getSecondaryHandItem() == it then S.p:setSecondaryHandItem(nil) end end)
    pcall(function() if S.p:isEquippedClothing(it) then S.p:removeWornItem(it) end end)
end
-- a thing out of the world: hands, worn, the floor, its container (color_tabs' way)
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
-- a thing put on the floor of sq (the game's own call for a dropped thing)
function H.drop(ft, sq, ox, oy)
    local it = nil
    if not (ft and sq) then return nil end
    pcall(function() it = sq:AddWorldInventoryItem(ft, ox or 0.5, oy or 0.5, 0.0) end)
    return H.mark(it)
end
function H.cond(it) local c, m = "?", "?"; pcall(function() c, m = it:getCondition(), it:getConditionMax() end); return tostring(c) .. "/" .. tostring(m) end
function H.md(name) local v = 0; pcall(function() local m = S.p:getModData().ZeD_CraftCounts; v = (m and m[name]) or 0 end); return v end
function H.wornList()
    local out = {}
    pcall(function()
        local wi = S.p:getWornItems()
        for i = 0, wi:size() - 1 do local w = wi:get(i); out[#out + 1] = { loc = w:getLocation(), item = w:getItem() } end
    end)
    return out
end
function H.isWorn(it) local w = false; if H.isItem(it) then pcall(function() w = S.p:isEquippedClothing(it) end) end; return w and true or false end
-- his own clothes worn again where a case wore something over them
function H.wornBack()
    for _, e in ipairs(S.found.worn or {}) do
        if not H.isWorn(e.item) and H.where(e.item) ~= nil and not H.onFloor(e.item) then
            pcall(function() S.p:setWornItem(e.loc, e.item) end)
        end
    end
    pcall(function() triggerEvent("OnClothingUpdated", S.p) end)
end

-- ===================================================================== his own inputs set aside, and given back
function H.stashTypes(set)
    local kept = 0
    for _, it in ipairs(H.all()) do
        if set[H.ft(it)] and not S.found.stashed[it] then
            local c, free = nil, false
            pcall(function()
                c = it:getContainer()
                free = it:getAttachedSlot() == -1 and not it:isEquipped() and not S.p:isEquippedClothing(it)
                    and S.p:getPrimaryHandItem() ~= it and S.p:getSecondaryHandItem() ~= it
            end)
            if c and free and pcall(function() c:Remove(it) end) then
                S.stash[#S.stash + 1] = { it = it, c = c }
                S.found.stashed[it] = true
            else
                kept = kept + 1
            end
        end
    end
    return #S.stash, kept
end
function H.unstash()
    local lost = 0
    for _, s in ipairs(S.stash) do
        pcall(function() if s.it:getContainer() == nil then s.c:AddItem(s.it) end end)
        if H.where(s.it) == nil then lost = lost + 1 end
    end
    S.stash = {}
    return lost
end

-- ===================================================================== the game's own answers
-- the containers the game's own craft window uses (its inventory pages' list), asked of the game itself
function H.conts()
    local list = nil
    pcall(function()
        if getPlayerInventory(S.pn) ~= nil and getPlayerLoot(S.pn) ~= nil then
            local l = ISInventoryPaneContextMenu.getContainers(S.p)
            if l and l:size() > 0 then list = l end
        end
    end)
    if not list then pcall(function() list = S.CC.buildContainers(S.p) end) end
    return list
end
function H.listHolds(c)
    local has = false
    pcall(function() local l = H.conts(); for i = 0, l:size() - 1 do if l:get(i) == c then has = true end end end)
    return has
end
-- which of the game's containers hold the thing ("" when none); one the main inventory does not hold, of the
-- thing's type, counts too (the loot page's floor holds the floor's things as its own list)
function H.listWhere(it)
    local out = {}
    local ft = H.ft(it)
    pcall(function()
        local l = H.conts()
        local main = H.inv()
        for i = 0, l:size() - 1 do
            local c = l:get(i)
            local has = c:getItems():contains(it)
            if not has and c ~= main then
                local items = c:getItems()
                for j = 0, items:size() - 1 do if not has and items:get(j):getFullType() == ft then has = true end end
            end
            if has then out[#out + 1] = H.ctype(c) end
        end
    end)
    return table.concat(out, "+")
end
-- the game's loot list read afresh, as a turn or a step makes the hidden loot page read it (vx10's)
function H.lootRefresh()
    pcall(function() local lp = getPlayerLoot(S.pn); if lp and lp.refreshBackpacks then lp:refreshBackpacks() end end)
    pcall(function() triggerEvent("OnContainerUpdate") end)
    pcall(function() local w = RT.ww(); if w then w._containersDirty = true end end)
end
function H.recipe(name)
    local r = nil
    pcall(function() local sm = getScriptManager(); r = sm:getCraftRecipe(name) or sm:getCraftRecipe("Base." .. name) end)
    return r
end
-- a HandcraftLogic as the game's craft window makes it: the bench (or a surface), the game's containers, the recipe
function H.logic(name, surf, bench)
    local l = nil
    pcall(function()
        l = HandcraftLogic.new(S.p, bench and bench.comp or nil, (bench and bench.obj) or surf or nil)
        l:setContainers(H.conts())
        l:setRecipe(H.recipe(name))
    end)
    return l
end
function H.gameCan(name, surf, bench)
    local can = nil
    local l = H.logic(name, surf, bench)
    if l then pcall(function() can = l:canPerformCurrentRecipe() and true or false end) end
    return can
end
-- the most the game would make (flag true: as ZeD's start asks it; false: what the game's own Max button sets)
function H.gameMost(name, surf, bench, flag)
    local most = nil
    local l = H.logic(name, surf, bench)
    if l then pcall(function() l:canPerformCurrentRecipe(); most = l:getPossibleCraftCount(flag and true or false) end) end
    return most
end
-- the things the game's own logic would use for one craft (a set), after its check
function H.gameUses(name, surf, bench)
    local set, can = {}, nil
    local l = H.logic(name, surf, bench)
    if l then
        pcall(function()
            can = l:canPerformCurrentRecipe() and true or false
            local items = l:getRecipeData():getAllInputItems()
            for i = 0, items:size() - 1 do set[items:get(i)] = true end
        end)
    end
    return set, can
end
-- the game's own validity for a recipe (known, skills, the recipe-at-hand benefit): getCachedRecipeInfo:isValid
function H.gameValid(name)
    local v = nil
    pcall(function()
        local r = H.recipe(name)
        local l = HandcraftLogic.new(S.p, nil, nil)
        l:setContainers(H.conts())
        local list = ArrayList.new()
        list:add(r)
        l:setRecipes(list)
        local info = l:getCachedRecipeInfo(r)
        if info then v = info:isValid() and true or false end
    end)
    return v
end
function H.surf(r) local o = nil; pcall(function() o = ISEntityUI.FindCraftSurface(S.p, r) end); return o end

-- ===================================================================== the tab
function H.cst() local w = RT.ww(); return w and w._craftState end
function H.data() local w = RT.ww(); return w and w._craftCache end
function H.row(name) local d = H.data(); return d and d.byName and d.byName[name] or nil end
function H.entry(name)
    local rd = H.row(name)
    if rd then return rd.entry end
    local d = H.data()
    for _, e in ipairs((d and d.flatRecipes) or {}) do if e.name == name then return e end end
    return nil
end
function H.showing() local s = false; pcall(function() s = S.WW.isTabShowing("craft", S.pn) end); return s and true or false end
function H.tab(id) if RT.worldTab(id) then return true end; return pcall(S.WW.openTab, S.pn, id) and true or false end
function H.inView(z)
    local st = H.cst()
    local g = st and st._listGeo
    return g == nil or z == nil or (z.y >= g.viewY and z.y + z.h <= g.viewY + g.viewH)
end
-- the zone of a kind (and id) drawn this frame; a list row only when it is in the list's view
function H.zone(kind, id)
    local st = H.cst()
    for _, z in ipairs((st and st.zones) or {}) do
        if z.type == kind and (id == nil or z.id == id) and (z.w or 0) > 0 and (z.h or 0) > 0 then
            if (kind ~= "recipeRow" and kind ~= "sectionHeader") or H.inView(z) then return z end
        end
    end
    return nil
end
function H.zoneAny(kind) local st = H.cst(); for _, z in ipairs((st and st.zones) or {}) do if z.type == kind then return z end end; return nil end
function H.clickXY(x, y, what)
    local ok, err = pcall(S.CT.onClick, RT.ww(), x, y)
    if not ok then S.errs = S.errs + 1; Q.check(false, tostring(what) .. ": the click ran without an error", err) end
    return ok
end
function H.click(z, what) if not z then return false end; return H.clickXY(z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2), what) end
function H.rclick(z, what)
    if not z then return false end
    local ok, err = pcall(S.CT.onRightClick, RT.ww(), z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
    if not ok then S.errs = S.errs + 1; Q.check(false, tostring(what) .. ": the right-click ran without an error", err) end
    return ok
end
function H.press(kind, what) local z = H.zone(kind); if not z then return false end; return H.click(z, what) end
-- a recipe's card opened as a click on its row does; from code, said, when its row is out of the list's view
function H.open(name, what)
    local st = H.cst()
    if not st then return false end
    pcall(function() if st.altSlotName then S.CC.exitAltMode(st) end end)
    if st.selected == name then return true end
    local z = H.zone("recipeRow", name)
    if z then
        H.click(z, what)
    else
        local ok, err = pcall(S.CC.openCraft, st, name)
        if not ok then Q.check(false, tostring(what) .. ": the card opened without an error", err) end
        Q.say("note " .. tostring(what) .. ": " .. tostring(name) .. " has no row in view, its card is opened from code")
    end
    return st.selected == name
end
function H.shut()
    local st = H.cst()
    if not st then return end
    pcall(function() if st.altSlotName then S.CC.exitAltMode(st) end end)
    pcall(function() if st.selected then S.CC.closeCraft(st) end end)
end
-- the search: the field and the tab's state set together (vx10's way: the field's poll then sees no change)
function H.setSearch(text)
    local st = H.cst()
    pcall(function() local f = RT.ww()._craftSearch; f.input:setText(text); f._lastText = text end)
    if st then st.search, st.filterDirty = text, true end
end
function H.inFiltered(name) local st = H.cst(); for _, rd in ipairs((st and st.filteredCache) or {}) do if rd.entry.name == name then return true end end; return false end
-- Craft lit, as the band lights it (CraftingCore drawBandActions)
function H.zedCan(rd) return rd ~= nil and rd.status == "craftable" and rd.learned ~= false and (rd.maxBatchQty or 1) > 0 and rd.canStart ~= false end
function H.rowText(name)
    local rd = H.row(name)
    if not rd then return "no row for " .. tostring(name) end
    return tostring(rd.status) .. ", learned " .. tostring(rd.learned) .. ", skill " .. tostring(rd.hasSkill) .. ", start " .. tostring(rd.canStart)
        .. ", most " .. tostring(rd.maxBatchQty)
end
-- the input slot of a recipe that takes this full type (its index in the catalog's input list)
function H.slotOf(name, ft)
    local e = H.entry(name)
    for i, d in ipairs((e and e.inputDefs) or {}) do if d.validTypes and d.validTypes[ft] then return i, d end end
    return nil, nil
end
function H.have(name, idx)
    local rd = H.row(name)
    local g = rd and rd.ingredients and idx and rd.ingredients[idx]
    if not g then return nil, nil end
    return g.have, g.need
end
function H.cardText(name)
    local rd = H.row(name)
    local o = {}
    for _, g in ipairs((rd and rd.ingredients) or {}) do o[#o + 1] = tostring(g.name) .. " " .. tostring(g.have) .. "/" .. tostring(g.need) end
    return H.list(o)
end
-- the card's counts and the list's answer gathered again after t0 (the containers every 1.5 s, the game's scan set in
-- full after t0: a change its signature cannot see waits for its 6 s full set), the card open on name
function H.fresh(t0, name)
    local w, st, rd = RT.ww(), H.cst(), H.row(name)
    if not (w and st and rd and st.selected == name and rd.ingredients) then return false end
    return ((w._craftContainerAt or 0) - 1500) >= t0 and (w._craftLogicFullAt or 0) >= t0
end
function H.keepState(st)
    local pk = {}
    for k, v in pairs(st.picks or {}) do pk[k] = v end
    return { show = st.show, showAll = st.showAll, sort = st.sort, cat = st.activeCat, req = st.reqCollapsed, out = st.outCollapsed,
        all = st.allCollapsed, pinC = st.pinnedCollapsed, freqC = st.freqCollapsed, owned = st.ownedOnly, search = st.search or "",
        sel = st.selected, picks = pk, qty = st.qty, scroll = (st.scroll and st.scroll.scrollPos) or 0 }
end
function H.putState(st, k)
    if not (st and k) then return end
    H.shut()
    st.show, st.showAll, st.sort, st.activeCat = k.show, k.showAll, k.sort, k.cat
    st.reqCollapsed, st.outCollapsed, st.allCollapsed = k.req, k.out, k.all
    st.pinnedCollapsed, st.freqCollapsed, st.ownedOnly = k.pinC, k.freqC, k.owned
    st.sortMenuOpen, st.showMenuOpen, st.catDropdownOpen, st.stDropdownOpen = false, false, false, false
    H.setSearch(k.search or "")
    if k.sel then pcall(S.CC.openCraft, st, k.sel); st.picks = k.picks or {}; st.qty = k.qty or 1 end
    st.filterDirty = true
    if st.scroll then pcall(function() st.scroll:setScrollPos(k.scroll or 0) end) end
end
-- every frame the tab's own rectangle (CraftingCore.render's x, y, w, h for the Craft tab), watched while on
function H.spyOn()
    if S.spy then return end
    local sp = { orig = S.CC.render }
    sp.fn = function(panel, win, x, y, w, h, state, config, data)
        if config and config.prefix == "craft" then sp.r = { x = x, y = y, w = w, h = h } end
        return sp.orig(panel, win, x, y, w, h, state, config, data)
    end
    S.CC.render = sp.fn
    S.spy = sp
end
function H.spyOff() local sp = S.spy; if sp and S.CC.render == sp.fn then S.CC.render = sp.orig end; S.spy = nil end

-- ===================================================================== objects laid round him (color_tabs' and vx10's)
function H.sqAt(dx, dy)
    local sq = nil
    pcall(function() sq = getCell():getGridSquare(math.floor(S.p:getX()) + dx, math.floor(S.p:getY()) + dy, math.floor(S.p:getZ())) end)
    return sq
end
-- a square beside him: a floor, free, no tree, no other object or thing on it, no car, in reach
function H.freeSq(dx, dy)
    local sq = H.sqAt(dx, dy)
    local good = false
    pcall(function()
        good = sq ~= nil and sq:getFloor() ~= nil and sq:isFree(false) and not sq:HasTree()
            and sq:getObjects():size() <= 1 and sq:getWorldObjects():size() == 0 and sq:getVehicleContainer() == nil
    end)
    if good then pcall(function() good = S.p:getCurrentSquare():canReachTo(sq) and true or false end) end
    return good and sq or nil
end
function H.used(sq) for _, c in ipairs(S.objs) do if c.sq == sq then return true end end; return false end
function H.layObj(sq, sprite, what)
    local o = nil
    pcall(function() o = IsoObject.new(getCell(), sq, sprite) end)
    if not o then return nil end
    pcall(function() o:createContainersFromSpriteProperties() end)
    pcall(function() sq:AddTileObject(o) end)
    local c = { obj = o, sq = sq, what = what .. " (" .. sprite .. " at " .. sq:getX() .. "," .. sq:getY() .. ")" }
    S.objs[#S.objs + 1] = c
    return c
end
function H.rmObj(c)
    if not (c and c.obj) then return end
    local o = c.obj
    for _, sq in ipairs({ (function() local q = nil; pcall(function() q = o:getSquare() end); return q end)(), c.sq }) do
        if sq then
            pcall(function() sq:transmitRemoveItemFromSquare(o) end)
            pcall(function() sq:RemoveTileObject(o) end)
            pcall(function() sq:getObjects():remove(o) end)
            pcall(function() sq:getSpecialObjects():remove(o) end)
            pcall(function() sq:RecalcProperties() end)
        end
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
-- a table on the first free square of the ring that the game takes as a crafting surface
function H.mkTable(ring)
    for _, d in ipairs(ring) do
        local sq = H.freeSq(d[1], d[2])
        if sq and not H.used(sq) then
            for _, name in ipairs(S.TABLES) do
                local c = H.layObj(sq, name, "a table")
                if c then
                    local takes = false
                    pcall(function() takes = S.p:canUseAsGenericCraftingSurface(c.obj) and true or false end)
                    if takes then c.d = d; return c end
                    H.rmObj(c)
                end
            end
        end
    end
    return nil
end
-- a crate beside him, its container explored
function H.mkCrate()
    for _, d in ipairs(S.NEAR) do
        local sq = H.freeSq(d[1], d[2])
        if sq and not H.used(sq) then
            local c = H.layObj(sq, S.CRATE, "a crate")
            local inv = nil
            if c then pcall(function() inv = c.obj:getContainer() end) end
            if inv then
                pcall(function() inv:setExplored(true) end)
                c.inv = inv
                return c
            end
            if c then H.rmObj(c) end
        end
    end
    return nil
end
function H.dirTo(sq)
    local d = "N"
    pcall(function()
        local dx, dy = sq:getX() - math.floor(S.p:getX()), sq:getY() - math.floor(S.p:getY())
        local s = ((dy < 0) and "N" or ((dy > 0) and "S" or "")) .. ((dx > 0) and "E" or ((dx < 0) and "W" or ""))
        if s ~= "" then d = s end
    end)
    return IsoDirections[d]
end
-- every object on the squares round him (r tiles), as a set
function H.snapObjs(r)
    local set = {}
    local cx, cy, cz = math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())
    for y = cy - r, cy + r do
        for x = cx - r, cx + r do
            local sq = getCell():getGridSquare(x, y, cz)
            local objs = sq and sq:getObjects()
            for i = 0, (objs and objs:size() or 0) - 1 do set[objs:get(i)] = true end
        end
    end
    return set
end
-- the pottery wheel built where it fits, as zedqa_stations builds its stations (ISBuildIsoEntity, the build cheat on
-- for the build alone); every new object it made is kept for the put-back
function H.findInfo(full)
    local found = nil
    pcall(function()
        local infos = SpriteConfigManager.GetObjectInfoList()
        for i = 0, infos:size() - 1 do
            local info = infos:get(i)
            local parent = info:getScript() and info:getScript():getParent()
            if not found and parent and tostring(parent:getScriptObjectFullType()) == full then found = info end
        end
    end)
    return found
end
function H.spawnWheel()
    local info = H.findInfo(S.WHEEL)
    if not info then return nil, "the game has no build info for " .. S.WHEEL end
    local px, py = math.floor(S.p:getX()), math.floor(S.p:getY())
    local before = H.snapObjs(5)
    local made = false
    for _, o in ipairs(S.WHEEL_AT) do
        if not made then
            pcall(function() S.p:setBuildCheat(true) end)
            pcall(function()
                local b = ISBuildIsoEntity:new(S.p, info, 1, ISInventoryPaneContextMenu.getContainers(S.p))
                b.buildCheat = true
                b.player = S.pn
                local sq = getCell():getGridSquare(px + o[1], py + o[2], 0)
                b.sq = sq
                if sq and b:isValid(sq) then
                    b:create(px + o[1], py + o[2], 0, false, nil)
                    made = true
                end
            end)
            pcall(function() S.p:setBuildCheat(false) end)
        end
    end
    local master = nil
    for o in pairs(H.snapObjs(5)) do
        if not before[o] then
            local sq = nil
            pcall(function() sq = o:getSquare() end)
            S.objs[#S.objs + 1] = { obj = o, sq = sq, what = "the pottery wheel's tile" }
            local kind = nil
            pcall(function() kind = S.ST.classify(o) end)
            if kind == "bench" then master = o end
        end
    end
    if not master then return nil, made and "built, but no bench object found round him" or "no square round him took the wheel" end
    return master
end
-- a body on sq from a fresh zombie (lv_move's mkCorpse, the body left on the ground); its container
function H.mkBody(sq)
    local z, body = nil, nil
    local ok, err = pcall(function() z = createZombie(sq:getX() + 0.5, sq:getY() + 0.5, sq:getZ(), nil, 0, IsoDirections.S) end)
    if not (ok and z) then return nil, "no zombie could be made: " .. tostring(err) end
    pcall(function() body = IsoDeadBody.new(z, false, false) end)
    if not body then pcall(function() body = IsoDeadBody.new(z, false) end) end
    pcall(function() z:removeFromWorld() end)
    pcall(function() z:removeFromSquare() end)
    if not body then return nil, "no body could be made from the zombie" end
    S.bodies[#S.bodies + 1] = body
    local inv = nil
    pcall(function() inv = body:getContainer() end)
    if not inv then return nil, "the body has no container" end
    return body, inv
end
function H.rmBody(b)
    pcall(function() local inv = b:getContainer(); if inv then inv:removeAllItems() end end)
    pcall(function() local sq = b:getSquare(); if sq then sq:removeCorpse(b, false) end end)
    pcall(function() b:removeFromWorld() end)
    pcall(function() b:removeFromSquare() end)
end
function H.bodyLeft(b) local left = false; pcall(function() local sq = b:getSquare(); left = sq ~= nil and sq:getDeadBodys():contains(b) end); return left end
-- new world items round him (anything not there at the start), taken away
function H.snapFloor(set)
    local cx, cy, cz = math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())
    for y = cy - 8, cy + 8 do
        for x = cx - 8, cx + 8 do
            local sq = getCell():getGridSquare(x, y, cz)
            local wos = sq and sq:getWorldObjects()
            for i = 0, (wos and wos:size() or 0) - 1 do set[wos:get(i)] = true end
        end
    end
end
function H.sweepFloor()
    local now, n = {}, 0
    H.snapFloor(now)
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
-- anything carried that was not carried at the start (crafted things, things a case gave), taken away
function H.sweepNew()
    local n = 0
    for _, it in ipairs(H.all()) do
        if not S.found.inv0[it] then H.removeItem(it); n = n + 1 end
    end
    return n
end

-- ===================================================================== the pad (eq_tab's, on the World window)
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
    if not (Det and Det.setLockedMode) then return false end
    if S.lockWas == nil then S.lockWas = H.lockFound() end
    pcall(Det.setLockedMode, "gamepad")
    S.back.pad = true
    local w = RT.ww()
    if w and S.F and S.F.claimFocus then pcall(S.F.claimFocus, w) end
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
-- the stops of the World window's tab (its focus ring's worldTabContent zone)
function H.stops()
    local w = RT.ww()
    for _, z in ipairs((w and w._focusRing) or {}) do if z.zone == "worldTabContent" then return z.elements or {} end end
    return {}
end
function H.stopById(id) for _, e in ipairs(H.stops()) do if e.id == id then return e end end; return nil end
function H.focusedId()
    local el = nil
    pcall(function() el = S.F.getFocusedElement(RT.ww()) end)
    return el and el.id or nil
end
function H.focusWhere(pred)
    local w = RT.ww()
    if not (w and S.F and S.F.focusWhere) then return nil end
    pcall(S.F.claimFocus, w)
    local e = nil
    pcall(function() e = S.F.focusWhere(w, "worldTabContent", pred) end)
    return e
end
function H.focusEl(id) return H.focusWhere(function(e) return e.id == id end) ~= nil end
function H.focusPre(pre) return H.focusWhere(function(e) return string.sub(tostring(e.id), 1, #pre) == pre end) end
-- a tap queued: the QA hook holds the button, FocusManager's dispatch takes the press on the World window, up after
-- 4 frames, then the hook lets go (nothing is pressed when gate says no)
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

-- ===================================================================== theme, text size, pictures (eq_tab's)
function H.theme(key)
    local o = H.zopt("baseTheme")
    local i = nil
    for k, v in ipairs(ZeD.Settings.baseKeys or {}) do if v == key then i = k end end
    if o and i then pcall(function() o:setValue(i) end) end
    pcall(ZeD.applyTheme, key, nil, nil)
    S.back.theme = true
end
function H.themeBack()
    if not S.back.theme then return end
    S.back.theme = nil
    local o = H.zopt("baseTheme")
    if o and S.found.baseIdx then pcall(function() o:setValue(S.found.baseIdx) end) end
    pcall(ZeD.applyTheme, S.found.base, nil, nil)
end
function H.sizeSet(key)
    local o = H.zopt("textSize")
    local i = nil
    for k, v in ipairs(ZeD.Settings.sizeKeys or {}) do if v == key then i = k end end
    if o and i then pcall(function() o:setValue(i) end) end
    pcall(ZeD.applyTheme, nil, nil, key)
    S.back.size = true
end
function H.sizeBack()
    if not S.back.size then return end
    S.back.size = nil
    local o = H.zopt("textSize")
    if o and S.found.sizeIdx then pcall(function() o:setValue(S.found.sizeIdx) end) end
    pcall(ZeD.applyTheme, nil, nil, S.found.size)
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
function H.shot(name, what)
    Q.step(1, function() if not S.dead then H.park(true) end end)
    Q.step(4, function()
        if S.dead then H.park(false); return end
        local file = name .. ".png"
        local ok, e = pcall(function() getCore():TakeFullScreenshot(file) end)
        if ok then S.shots[#S.shots + 1] = file; Q.say("NOTE picture Zomboid/Screenshots/" .. file .. " | " .. what)
        else Q.say("NOTE the picture " .. name .. " was not taken: " .. tostring(e)) end
        H.park(false)
    end)
    Q.waitMs(1200)
end

-- ===================================================================== a case's start and end
function H.caseStart()
    S.caseMade = {}
    S.caseObjs = #S.objs
    S.caseBodies = #S.bodies
    local st = H.cst()
    if st then H.shut(); H.setSearch(""); pcall(S.CC.setShow, st, "all"); st.activeCat = "all"; st.filterDirty = true end
end
function H.caseClean()
    H.speed(1)
    H.qstop()
    H.padOff()
    H.spyOff()
    pcall(function() if S.orig.walk then ISEntityUI.WalkToEntity = S.orig.walk end end)
    pcall(function() S.ST.unbind(S.p) end)
    H.shut()
    local st = H.cst()
    if st then
        H.setSearch("")
        st.catDropdownOpen, st.sortMenuOpen, st.showMenuOpen, st.stDropdownOpen = false, false, false, false
        st.activeCat, st.qty, st.picks = "all", 1, {}
        st.filterDirty = true
    end
    for _, it in ipairs(S.caseMade) do H.removeItem(it) end
    S.caseMade = {}
    for i = (S.caseObjs or 0) + 1, #S.objs do H.rmObj(S.objs[i]) end
    for i = (S.caseBodies or 0) + 1, #S.bodies do H.rmBody(S.bodies[i]) end
    H.sweepNew()
    H.sweepFloor()
    H.wornBack()
    pcall(function() S.p:setPrimaryHandItem(S.found.hands.p) end)
    pcall(function() S.p:setSecondaryHandItem(S.found.hands.s) end)
    H.home()
    H.lootRefresh()
end
function H.caseEnd(label)
    H.step(2, function() H.caseClean() end)
    H.step(10, function()
        local e1 = H.errN()
        Q.check(S.e0 == nil or e1 == nil or e1 == S.e0, label .. ": no Lua error over the case",
            (S.e0 and e1) and ((e1 - S.e0) .. " new") or "the count cannot be read")
        S.e0 = e1
    end)
end
-- queue: the Crafting tab showing its recipe rows (T.off when it does not)
function H.toTab(T, label)
    H.step(2, function() if not RT.isOpen() then RT.pairOpen() end end)
    H.step(10, function() H.tab("craft") end)
    H.wait(6000, function() return H.showing() and H.cst() ~= nil and H.zoneAny("recipeRow") ~= nil end, function(ok)
        if not Q.check(ok, label .. ": the Crafting tab shows its recipe rows", "showing " .. tostring(H.showing())) then T.off = true end
    end)
end
-- queue: a recipe's card opened once its things are staged (stage(T) gives them; it sets T.skip with why to skip),
-- then the card's counts and the game's scan caught up with them (at most 9 s): T.ready
function H.stageOpen(T, name, label, stage)
    H.step(2, function()
        T.ready = nil
        if T.off then return end
        if stage then
            local ok, err = pcall(stage, T)
            if not ok then T.skip = "the staging threw: " .. tostring(err) end
        end
        if T.skip then Q.skip(label, T.skip); T.off = true; return end
        H.lootRefresh()
        T.go = H.open(name, label)
        T.t0 = getTimestampMs()
        if not T.go then Q.check(false, label .. ": its card opens", "the card: " .. tostring(H.cst() and H.cst().selected)); T.off = true end
    end)
    H.wait(9000, function() return T.off or H.fresh(T.t0, name) end, function(ok)
        if T.off then return end
        T.ready = ok
        if not ok then Q.say("NOTE " .. label .. ": the card's counts and the game's scan did not catch up in 9 s (read as they stand)") end
    end)
end

-- ===================================================================== setup
function S.setup()
    Q.step(1, function()
        local f = S.found
        S.dead = S.p:isDead() and true or false
        if S.dead then Q.check(false, "setup: the character is alive (nothing is run on a dead one)"); return end
        if not (S.F and S.F.focusWhere and ISEntityUI and HandcraftLogic and ISTimedActionQueue) then
            S.dead = true
            Q.check(false, "setup: the pad's focus manager and the game's crafting logic are loaded")
            return
        end
        S.err0 = H.errN()
        S.e0 = S.err0
        if ZEDQA_HOME then pcall(ZEDQA_HOME, "cr_tab") end
        H.speed(1)
        H.qstop()
        f.pos = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
        pcall(function() f.dir = S.p:getDir() end)
        f.pair = RT.isOpen()
        f.hands = { p = S.p:getPrimaryHandItem(), s = S.p:getSecondaryHandItem() }
        f.worn = H.wornList()
        f.inv0, f.types, f.stashed, f.floor0 = {}, {}, {}, {}
        for _, it in ipairs(H.all()) do
            f.inv0[it] = true
            local ft = H.ft(it)
            f.types[ft] = (f.types[ft] or 0) + 1
        end
        H.snapFloor(f.floor0)
        -- (the crafts run at x20: the clock and his stats are put back as bx_craft puts them back)
        pcall(function() f.tod = getGameTime():getTimeOfDay() end)
        f.stats = {}
        pcall(function()
            local stt = S.p:getStats()
            for _, k in ipairs(S.STATS) do pcall(function() f.stats[k] = stt:get(CharacterStat[k]) end) end
        end)
        pcall(function() f.inst = S.p:isTimedActionInstantCheat(); S.p:setTimedActionInstantCheat(false) end)
        pcall(function() f.bc = S.p:isBuildCheat(); S.p:setBuildCheat(false) end)
        pcall(function() f.bm = ISBuildMenu.cheat; ISBuildMenu.cheat = false end)
        pcall(function() f.mdc = ISMoveableDefinitions.cheat; ISMoveableDefinitions.cheat = false end)
        pcall(function() if not S.p:isGodMod() then S.p:setGodMod(true); Q.say("note god mode was off: turned on and left on") end end)
        pcall(function() f.invinc = S.p:isInvincible() and true or false; S.p:setInvincible(true) end)
        local md = S.p:getModData()
        f.mdKeys = {}
        for _, key in ipairs({ "ZeD_CraftPins", "ZeD_CraftCounts" }) do
            local copy = nil
            if md[key] then copy = {}; for k, v in pairs(md[key]) do copy[k] = v end end
            f.mdKeys[key] = { v = copy }
        end
        f.base, f.baseIdx = ZeD.currentBase, H.optVal(H.zopt("baseTheme"))
        f.size, f.sizeIdx = ZeD.currentSize, H.optVal(H.zopt("textSize"))
        S.lockWas = H.lockFound()
        pcall(function()
            local cur = S.ST.current(S.p)
            if cur then f.st = cur; S.ST.unbind(S.p); Q.say("note a station was bound: unbound for the run, bound again at the end") end
        end)
        RT.pairOpen()
        if ZEDQA_LAYOUT_SNAP then pcall(function() f.layout = ZEDQA_LAYOUT_SNAP() end) end
        f.recorded = true
        S.back.on = true
        Q.say("found: at " .. math.floor(f.pos.x) .. "," .. math.floor(f.pos.y) .. ", " .. #f.worn .. " worn, theme " .. tostring(f.base)
            .. ", text " .. tostring(f.size) .. ", input lock " .. tostring(S.lockWas) .. ", screen " .. H.sizeTag()
            .. ", instant " .. tostring(f.inst) .. ", build cheat " .. tostring(f.bc) .. "/" .. tostring(f.bm))
    end)
    H.step(15, function() local w = RT.ww(); S.found.tab = w and w._activeTab; H.tab("craft") end)
    H.wait(8000, function() return H.showing() and H.cst() ~= nil and H.zoneAny("recipeRow") ~= nil end, function(ok)
        if not Q.check(ok, "setup: the World window's Crafting tab opens with recipe rows", "showing " .. tostring(H.showing())) then S.dead = true; return end
        local st = H.cst()
        S.found.keep = H.keepState(st)
        H.shut()
        H.setSearch("")
        pcall(S.CC.setShow, st, "all")
        st.activeCat, st.filterDirty = "all", true
        -- his own inputs of the recipes crafted here, set aside (the crafts then use only what a case gives)
        local set = {}
        for _, nm in ipairs({ S.R.stake, S.R.spear, S.R.drill, S.R.slice, S.R.cup }) do
            local e = H.entry(nm)
            if not e then Q.say("note setup: the catalog has no " .. nm) end
            for _, d in ipairs((e and e.inputDefs) or {}) do for ft in pairs(d.validTypes or {}) do set[ft] = true end end
        end
        local aside, kept = H.stashTypes(set)
        Q.say("note setup: " .. aside .. " of his own things the recipes take are set aside" .. (kept > 0 and (", " .. kept .. " worn, held or on the belt stay") or ""))
        Q.check(S.stakeKnife ~= nil and S.stakeBranch ~= nil, "setup: a knife and a tree branch are items this game knows", tostring(S.stakeKnife) .. ", " .. tostring(S.stakeBranch))
    end)
end

-- ===================================================================== 1. the recipe list
function S.case1cats(T)
    H.step(2, function()
        if T.off then return end
        local st = H.cst()
        T.ncat = #(st.categoryList or {})
        T.dd = H.press("catDropdown", "1 Category")
        if not T.dd then Q.skip("1 Category: a category picked from its list", "the header draws no Category select") end
    end)
    H.step(6, function()
        if not T.dd then return end
        local st = H.cst()
        local geo, cat = st._ddGeo, (st.categoryList or {})[2]
        if not (st.catDropdownOpen and geo and cat) then T.dd = false; Q.check(false, "1 Category: a click on Category opens its list", "open " .. tostring(st.catDropdownOpen)); return end
        T.catId = cat.id
        local rowH = ZeD.T.px(20)
        H.clickXY(geo.x + 4, geo.y + rowH + math.floor(rowH / 2), "1 Category row")
    end)
    H.wait(3000, function() local st = H.cst(); return not T.dd or (st.activeCat == T.catId and st.filterDirty == false) end, function(ok)
        if not T.dd then return end
        local st = H.cst()
        local bad, n = 0, 0
        for _, rd in ipairs(st.filteredCache or {}) do
            n = n + 1
            if string.lower(tostring(rd.entry.category)) ~= T.catId then bad = bad + 1 end
        end
        Q.check(ok and n > 0 and bad == 0, "1 Category: a category picked from its list leaves only its recipes",
            "the category " .. tostring(T.catId) .. " of " .. T.ncat .. ": " .. n .. " rows, " .. bad .. " of another category")
        st.activeCat, st.filterDirty = "all", true
    end)
end
function S.case1search(T)
    H.step(4, function()
        if T.off then return end
        local e = H.entry(S.R.stake)
        T.word = e and string.lower(tostring(e.displayName)) or "stake"
        H.setSearch(T.word)
    end)
    H.wait(3000, function() local st = H.cst(); return T.off or (st.search == T.word and st.filterDirty == false) end, function(ok)
        if T.off then return end
        local st = H.cst()
        Q.check(ok and H.inFiltered(S.R.stake), "1 search: Make Stake's own name finds it", tostring(T.word) .. ": " .. #(st.filteredCache or {}) .. " rows")
        -- C20: the branch's name, as "craft with this item" puts it in: ZeD's results against the recipes that take it
        T.bword = "branch"
        pcall(function() T.bword = string.lower(tostring(getScriptManager():FindItem(S.stakeBranch):getDisplayName())) end)
        H.setSearch(T.bword)
    end)
    H.wait(3000, function() local st = H.cst(); return T.off or (st.search == T.bword and st.filterDirty == false) end, function()
        if T.off then return end
        local st = H.cst()
        local takes, locked, other = 0, 0, 0
        for _, rd in ipairs(st.filteredCache or {}) do
            local uses = false
            for _, d in ipairs(rd.entry.inputDefs or {}) do if d.validTypes and d.validTypes[S.stakeBranch] then uses = true end end
            if uses then takes = takes + 1 else other = other + 1 end
            if rd.status == "locked" then locked = locked + 1 end
        end
        Q.say("NOTE 1 search (C20): \"" .. tostring(T.bword) .. "\" lists " .. #(st.filteredCache or {}) .. " recipes: " .. takes
            .. " take a tree branch (the game's own filter by input name lists those), " .. other .. " match by output, category or another input; "
            .. locked .. " of them locked (a search shows them whatever Show says)")
        H.setSearch("")
    end)
end
function S.case1pins(T)
    H.step(4, function()
        if T.off then return end
        local w = RT.ww()
        T.pins0 = #(w._craftPins or {})
        -- C18: the game's own favourite on Carve Spear, as its crafting window's star sets it
        local r = H.recipe(S.R.spear)
        pcall(function() T.favKey = BaseCraftingLogic.getFavouriteModDataString(r) end)
        if not T.favKey then Q.skip("1 pins (C18): the game's favourite in ZeD's list", "the game's favourite key cannot be read"); return end
        local md = S.p:getModData()
        if S.fav[T.favKey] == nil then S.fav[T.favKey] = { v = md[T.favKey] } end
        md[T.favKey] = true
        T.gameFav = H.call(r, "isFavourite", S.p)
        T.pinnedBefore = S.CC.isPinned(w, S.R.spear, "_craftPins")
        H.cst().filterDirty = true
    end)
    Q.waitMs(2500)
    H.step(2, function()
        if T.off or not T.favKey then return end
        local w, st = RT.ww(), H.cst()
        local inPinned = false
        for _, sec in ipairs(st._sections or {}) do
            if sec.id == "pinned" then for _, rd in ipairs(sec.items or {}) do if rd.entry.name == S.R.spear then inPinned = true end end end
        end
        Q.check(T.pinnedBefore or S.CC.isPinned(w, S.R.spear, "_craftPins") or inPinned,
            "1 pins (C18): a recipe the game holds as a favourite shows among ZeD's pinned recipes",
            "the game's own isFavourite " .. tostring(T.gameFav) .. "; ZeD pinned " .. tostring(S.CC.isPinned(w, S.R.spear, "_craftPins")) .. ", in the Pinned group " .. tostring(inPinned))
        S.p:getModData()[T.favKey] = S.fav[T.favKey].v
        -- a ZeD pin by right-click on Make Stake's row, then what the game sees
        T.stakeWasPinned = S.CC.isPinned(w, S.R.stake, "_craftPins")
        local z = H.zone("recipeRow", S.R.stake)
        if z then H.rclick(z, "1 pins") else pcall(S.CC.togglePin, w, S.R.stake, "ZeD_CraftPins", "_craftPins", "filterDirty"); Q.say("note 1 pins: Make Stake's row is out of view: pinned from code") end
        local fk = nil
        pcall(function() fk = BaseCraftingLogic.getFavouriteModDataString(H.recipe(S.R.stake)) end)
        Q.say("NOTE 1 pins (C18): Make Stake pinned in ZeD (" .. tostring(S.CC.isPinned(w, S.R.stake, "_craftPins")) .. "); the game's own favourite for it: "
            .. tostring(fk and S.p:getModData()[fk]) .. " (ZeD's pins are its own list; the game's item menus list its favourites first)")
        -- the 9th pin: the oldest goes, silently
        local names = {}
        for _, e in ipairs((H.data() and H.data().flatRecipes) or {}) do
            if #names < 9 and not S.CC.isPinned(w, e.name, "_craftPins") then names[#names + 1] = e.name end
        end
        for _, nm in ipairs(names) do pcall(S.CC.togglePin, w, nm, "ZeD_CraftPins", "_craftPins", "filterDirty") end
        local now = w._craftPins or {}
        local kept = 0
        for _, nm in ipairs(names) do if S.CC.isPinned(w, nm, "_craftPins") then kept = kept + 1 end end
        Q.say("NOTE 1 pins: 9 recipes pinned (from code) on " .. T.pins0 .. " found: " .. #now .. " pinned (the most is " .. tostring(S.CC.MAX_PINS)
            .. "), " .. (9 - kept) .. " of the 9 dropped with no word; the oldest pins go first")
        -- ZeD's pins as found (the mod data copy and the window's list)
        H.pinsBack()
        H.cst().filterDirty = true
    end)
end
function H.pinsBack()
    local md = S.p:getModData()
    local was = S.found.mdKeys and S.found.mdKeys.ZeD_CraftPins
    if was then
        if was.v then local t = {}; for k, v in pairs(was.v) do t[k] = v end; md.ZeD_CraftPins = t else md.ZeD_CraftPins = nil end
    end
    local w = RT.ww()
    if w then pcall(S.CC.loadPins, w, "ZeD_CraftPins", "_craftPins") end
    local st = H.cst()
    if st and w then st.pins = w._craftPins or {}; st.filterDirty = true end
end
function H.showCheck(T, mode, label)
    H.step(2, function() if not T.off then pcall(S.CC.setShow, H.cst(), mode) end end)
    H.wait(3000, function() local st = H.cst(); return T.off or (st.show == mode and st.filterDirty == false) end, function(ok)
        if T.off then return end
        local st = H.cst()
        local pins = {}
        for _, nm in ipairs(st.pins or {}) do pins[nm] = true end
        local n, bad, ex = 0, 0, nil
        for _, rd in ipairs(st.filteredCache or {}) do
            n = n + 1
            local nm = rd.entry.name
            if not pins[nm] and nm ~= st.selected then
                local wrong = false
                if mode == "ready" then wrong = rd.status ~= "craftable" end
                if mode == "known" then wrong = (rd.entry.needLearn and rd.learned == false) or rd.hasSkill == false end
                if wrong then bad = bad + 1; ex = ex or (nm .. " " .. tostring(rd.status)) end
            end
        end
        T["n_" .. mode] = n
        if mode == "all" then
            Q.check(ok and n >= (T.n_known or 0) and n >= (T.n_ready or 0), label, n .. " rows (Known " .. tostring(T.n_known) .. ", Ready " .. tostring(T.n_ready) .. ")")
        else
            Q.check(ok and bad == 0, label, n .. " rows, " .. bad .. " that do not belong" .. (ex and (" (" .. ex .. ")") or ""))
        end
    end)
end
-- C3: a recipe whose literature the game counts as at hand
function H.findAtHand()
    local teach = {}
    local all, n = nil, 0
    pcall(function() all = getScriptManager():getAllItems(); n = all:size() end)
    for i = 0, n - 1 do
        local si = nil
        pcall(function() si = all:get(i) end)
        local list = si and H.call(si, "getTeachedRecipes")
        if list then
            local ft = H.call(si, "getFullName")
            pcall(function()
                for j = 0, list:size() - 1 do local r = tostring(list:get(j)); if teach[r] == nil then teach[r] = ft end end
            end)
        end
    end
    local tries = 0
    for _, e in ipairs((H.data() and H.data().flatRecipes) or {}) do
        local lit = teach[e.name]
        if lit and tries < 30 and not e.stationInfo and not e.needSurface and e.recipe then
            local skilled, known = true, true
            pcall(function() skilled = e.recipe:characterHasRequiredSkills(S.p) and true or false end)
            pcall(function() known = (not e.needLearn) or S.p:isRecipeKnown(e.recipe, true) end)
            if not skilled or not known then
                tries = tries + 1
                local it = H.give(lit)
                local can = it and H.call(e.recipe, "couldBenefitFromRecipeAtHand", S.p)
                if can == true then return e, it, skilled, known end
                H.removeItem(it)
            end
        end
    end
    return nil, nil, nil, tries
end
function S.case1hand(T)
    H.step(2, function()
        if T.off then return end
        if not H.has(H.recipe(S.R.stake), "couldBenefitFromRecipeAtHand") then Q.skip("1 at hand (C3)", "the game's recipes have no recipe-at-hand check here"); return end
        local e, it, skilled, known = H.findAtHand()
        if not e then Q.skip("1 at hand (C3)", "no recipe the game lets through with its literature carried was found (" .. tostring(known) .. " tried)"); return end
        T.hand = { e = e, it = it, why = (skilled and "" or "short of skill ") .. (known and "" or "not learned") }
        Q.say("NOTE 1 at hand (C3): " .. e.name .. " (" .. T.hand.why .. "), with " .. H.ft(it) .. " carried")
        T.handT0 = getTimestampMs()
    end)
    Q.waitMs(2600)
    H.step(2, function()
        if T.off or not T.hand then return end
        local e = T.hand.e
        local rd = H.row(e.name)
        local gv = H.gameValid(e.name)
        if gv == nil then Q.skip("1 at hand (C3): ZeD's row against the game's validity", "the game's crafting logic gave no answer"); return end
        Q.check(rd ~= nil and ((rd.status ~= "locked") == gv), "1 at hand (C3): with its literature carried the row is locked exactly when the game holds the recipe back",
            "the game's validity " .. tostring(gv) .. "; ZeD " .. H.rowText(e.name))
        H.removeItem(T.hand.it)
    end)
end
-- a hand recipe with one skill, levels 1 to 5, no learning, no station or surface
function H.findSkilled()
    for _, e in ipairs((H.data() and H.data().flatRecipes) or {}) do
        local sd = e.skillDefs or {}
        if #sd == 1 and sd[1].required >= 1 and sd[1].required <= 5 and not e.needLearn and not e.stationInfo and not e.needSurface
            and not S.PERK_SKIP[sd[1].name] then
            local perk = S.CC.getPerkType(sd[1].name)
            if perk and perk ~= Perks.None then return e, perk, sd[1].required end
        end
    end
    return nil
end
function H.setPerk(perk, lv)
    if S.perks[perk] == nil then
        local was, xp = 0, nil
        pcall(function() was = S.p:getPerkLevel(perk) end)
        pcall(function() xp = S.p:getXp():getXP(perk) end)
        S.perks[perk] = { lv = was, xp = xp }
    end
    pcall(function() S.p:setPerkLevelDebug(perk, lv) end)
    local w = RT.ww()
    if w then w._craftCache = nil end
    local st = H.cst()
    if st then st.filterDirty = true end
end
function H.perksBack()
    for perk, v in pairs(S.perks) do
        pcall(function() S.p:setPerkLevelDebug(perk, v.lv) end)
        pcall(function() S.p:getXp():setXPToLevel(perk, v.lv) end)
        local xp = nil
        pcall(function() xp = S.p:getXp():getXP(perk) end)
        Q.say("note put back: " .. tostring(perk) .. " level " .. tostring(v.lv) .. ", XP " .. tostring(v.xp) .. " found, " .. tostring(xp) .. " now")
    end
    S.perks = {}
    local w = RT.ww()
    if w then w._craftCache = nil end
end
function S.case1skill(T)
    H.step(2, function()
        if T.off then return end
        local e, perk, need = H.findSkilled()
        if not e then Q.skip("1 skill: below and at its level", "no hand recipe with one skill of level 1 to 5"); return end
        T.sk = { e = e, perk = perk, need = need }
        H.setPerk(perk, need - 1)
    end)
    H.wait(4000, function() local rd = T.sk and H.row(T.sk.e.name); return not T.sk or (rd ~= nil and rd.status == "locked") end, function(ok)
        if not T.sk then return end
        Q.check(ok, "1 skill: " .. T.sk.e.name .. " with " .. tostring(T.sk.perk) .. " one level short reads locked", H.rowText(T.sk.e.name))
        H.setPerk(T.sk.perk, T.sk.need)
    end)
    H.wait(4000, function() local rd = T.sk and H.row(T.sk.e.name); return not T.sk or (rd ~= nil and rd.status ~= "locked") end, function(ok)
        if not T.sk then return end
        local skilled = nil
        pcall(function() skilled = T.sk.e.recipe:characterHasRequiredSkills(S.p) and true or false end)
        Q.check(ok and skilled == true, "1 skill: at the level the row is no longer locked, as the game's own skill check says", H.rowText(T.sk.e.name) .. "; the game's check " .. tostring(skilled))
        H.perksBack()
    end)
end
-- a must-learn recipe he does not know, needing no skill he lacks, no station or surface, that the list shows (with
-- See Not Known Recipes off the game's list, and ZeD's, hide it)
function H.findUnlearned()
    for _, rd in ipairs((H.data() and H.data().recipes) or {}) do
        local e = rd.entry
        if e.needLearn and not e.stationInfo and not e.needSurface and e.recipe then
            local known, skilled = true, false
            pcall(function() known = S.p:isRecipeKnown(e.recipe, true) and true or false end)
            pcall(function() skilled = e.recipe:characterHasRequiredSkills(S.p) and true or false end)
            if not known and skilled then return e end
        end
    end
    return nil
end
function H.forget(name)
    pcall(function() S.p:getKnownRecipes():remove(name) end)
    local w = RT.ww()
    if w then w._craftCache = nil end
end
function S.case1learn(T)
    H.step(2, function()
        if T.off then return end
        local e = H.findUnlearned()
        if not e then Q.skip("1 learn: a recipe learned with the tab open", "no must-learn recipe he lacks with no skill short is listed (See Not Known Recipes may be off)"); return end
        T.le = e
        H.open(e.name, "1 learn")
        S.learned[e.name] = true
        pcall(function() S.p:learnRecipe(e.name) end)
    end)
    H.wait(4000, function() local rd = T.le and H.row(T.le.name); return not T.le or (rd ~= nil and rd.learned == true and rd.status ~= "locked") end, function(ok)
        if not T.le then return end
        Q.check(ok, "1 learn: " .. T.le.name .. " learned while the tab is open turns learned on its row within 4 s", H.rowText(T.le.name))
        H.forget(T.le.name)
        S.learned[T.le.name] = nil
    end)
    H.wait(4000, function() local rd = T.le and H.row(T.le.name); return not T.le or rd == nil or rd.learned == false end, function(ok)
        if not T.le then return end
        local known = true
        pcall(function() known = S.p:isRecipeKnown(T.le.recipe, true) and true or false end)
        Q.check(ok and not known, "1 learn: forgotten again (put back), the row reads not learned", H.rowText(T.le.name) .. ", known " .. tostring(known))
        H.shut()
    end)
end
function S.case1()
    local T = {}
    H.step(2, function() H.caseStart() end)
    H.toTab(T, "1 list")
    S.case1cats(T)
    S.case1search(T)
    S.case1pins(T)
    H.step(2, function() if not T.off then H.shut() end end)
    H.showCheck(T, "ready", "1 Show Ready: every row is ready to craft (pins and the open card aside)")
    H.showCheck(T, "known", "1 Show Known: no row is locked or short of skill (pins and the open card aside)")
    H.showCheck(T, "all", "1 Show All: lists at least what Known and Ready list")
    S.case1hand(T)
    S.case1skill(T)
    S.case1learn(T)
    H.caseEnd("1 list")
end

-- ===================================================================== 2. the card's counts against the game (C4)
-- spec: label, name, slotFt (the slot compared), tool (the slot is a kept tool: the game's count is 1 or 0), surf
-- (an any-surface recipe: the table laid in the case), stage(T) gives the things (T.skip says why it cannot)
function H.c4(spec)
    local T = { label = spec.label }
    H.stageOpen(T, spec.name, spec.label, spec.stage)
    H.step(2, function()
        if T.off then return end
        local rd = H.row(spec.name)
        local surf = spec.surf and H.surf(2) or nil
        local g = H.gameCan(spec.name, surf)
        local most = H.gameMost(spec.name, surf, nil, true)
        local idx = H.slotOf(spec.name, spec.slotFt)
        local have = H.have(spec.name, idx)
        local gameN = most
        if spec.tool and most ~= nil then gameN = (most > 0) and 1 or 0 end
        local d = "ZeD " .. H.rowText(spec.name) .. "; card " .. H.cardText(spec.name) .. "; the game can " .. tostring(g) .. ", most " .. tostring(most)
        if g == nil then Q.skip(spec.label .. ": against the game", "the game's crafting logic gave no answer"); return end
        Q.check(H.zedCan(rd) == g, spec.label .. ": Craft is lit exactly when the game would start the craft", d)
        Q.check(have ~= nil and gameN ~= nil and have == gameN, spec.label .. ": the card's have count is what the game would take (C4)",
            "slot " .. tostring(idx) .. " have " .. tostring(have) .. ", the game would take " .. tostring(gameN) .. "; " .. d)
    end)
    H.step(2, function()
        for _, it in ipairs(T.items or {}) do H.removeItem(it) end
        H.wornBack()
        pcall(function() S.p:setPrimaryHandItem(S.found.hands.p) end)
    end)
end
function H.with(T, it) T.items = T.items or {}; T.items[#T.items + 1] = it; return it end
function H.stakeStage(T, fn)
    local k = H.with(T, H.give(S.stakeKnife))
    if not k then T.skip = "no knife could be given"; return end
    T.knife = k
    fn(T, k)
end
function S.case2()
    local T = {}
    H.step(2, function() H.caseStart() end)
    H.toTab(T, "2 counts")
    H.step(2, function() if not T.off then Q.say("NOTE 2 counts (C4): the card names no tool flag (may degrade, sharpness, not worn) as the game's input tooltip does (ISWidgetInput)") end end)
    local B = S.stakeBranch or "Base.TreeBranch2"
    local specs = {
        { label = "2 counts, one plain branch", fn = function(T2) H.with(T2, H.give(B)) end },
        { label = "2 counts, one favourite branch", fn = function(T2)
            local b = H.with(T2, H.give(B)); H.call(b, "setFavorite", true)
            if H.call(b, "isFavorite") ~= true then T2.skip = "the branch cannot be made a favourite" end end },
        { label = "2 counts, one branch held in the hand", fn = function(T2)
            local b = H.with(T2, H.give(B)); pcall(function() S.p:setPrimaryHandItem(b) end)
            if S.p:getPrimaryHandItem() ~= b then T2.skip = "the branch could not be put in his hand" end end },
        { label = "2 counts, one broken branch", fn = function(T2)
            local b = H.with(T2, H.give(B)); H.call(b, "setCondition", 0)
            if H.call(b, "isBroken") ~= true then T2.skip = "a tree branch has no condition to break (" .. H.cond(b) .. ")" end end },
        { label = "2 counts, a favourite branch and a plain one", fn = function(T2)
            local b = H.with(T2, H.give(B)); H.call(b, "setFavorite", true); H.with(T2, H.give(B)) end },
        { label = "2 counts, the knife a favourite", tool = true, fn = function(T2, k)
            H.with(T2, H.give(B)); H.call(k, "setFavorite", true)
            if H.call(k, "isFavorite") ~= true then T2.skip = "the knife cannot be made a favourite" end end },
        { label = "2 counts, the knife broken", tool = true, fn = function(T2, k)
            H.with(T2, H.give(B)); H.call(k, "setCondition", 0)
            if H.call(k, "isBroken") ~= true then T2.skip = "the knife does not read broken at condition 0" end end },
        { label = "2 counts, the knife dull", tool = true, fn = function(T2, k)
            H.with(T2, H.give(B))
            if not H.has(k, "setSharpness") then T2.skip = "the knife has no sharpness in this build"; return end
            H.call(k, "setSharpness", 0.0)
            local s = H.call(k, "getSharpness")
            if not (type(s) == "number" and s <= 0.01) then T2.skip = "the knife's sharpness did not go to 0 (" .. tostring(s) .. ")" end end },
    }
    for _, sp in ipairs(specs) do
        H.c4({ label = sp.label, name = S.R.stake, slotFt = sp.tool and S.stakeKnife or B, tool = sp.tool,
            stage = function(T2) H.stakeStage(T2, sp.fn) end })
    end
    -- a worn T-shirt (and whatever cotton he wears himself) for Rip Clothing
    H.c4({ label = "2 counts, Rip Clothing with a T-shirt worn", name = S.R.rip, slotFt = H.kind("tee") or "Base.Tshirt_DefaultTEXTURE_TINT",
        stage = function(T2)
            local ft = H.kind("tee")
            if not (ft and H.slotOf(S.R.rip, ft)) then T2.skip = "no T-shirt the recipe takes is known here"; return end
            local t = H.with(T2, H.give(ft))
            local loc = nil
            pcall(function() loc = t:getBodyLocation() end)
            if loc then pcall(function() S.p:setWornItem(loc, t) end) end
            pcall(function() triggerEvent("OnClothingUpdated", S.p) end)
            if not H.isWorn(t) then T2.skip = "the T-shirt could not be worn" end
        end })
    -- fresh, then rotten bread at a table (Slice Bread is made on a surface)
    H.step(2, function()
        if T.off then return end
        T.table = H.mkTable(S.NEAR)
        if not T.table then Q.say("NOTE 2 counts: no table could be laid beside him: Slice Bread is skipped") end
    end)
    local function breadStage(rotten)
        return function(T2)
            if not T.table then T2.skip = "no table beside him"; return end
            local k = H.with(T2, H.give(S.stakeKnife))
            local b = H.with(T2, H.give(H.kind("bread")))
            if not (k and b) then T2.skip = "no knife or bread could be given"; return end
            if rotten then
                local off = H.call(b, "getOffAgeMax")
                if type(off) == "number" then H.call(b, "setAge", off + 2) end
                if H.call(b, "isRotten") ~= true then T2.skip = "the bread does not read rotten (age " .. tostring(H.call(b, "getAge")) .. ")" end
            elseif H.gameCan(S.R.slice, H.surf(2)) ~= true then
                T2.skip = "the game will not slice fresh bread here (" .. H.ft(b) .. "): the rotten case has no baseline"
                T.noBread = true
            end
            if rotten and T.noBread then T2.skip = "no baseline: the game would not slice the fresh bread" end
        end
    end
    H.c4({ label = "2 counts, Slice Bread with fresh bread", name = S.R.slice, slotFt = H.kind("bread") or "Base.Bread", surf = true, stage = breadStage(false) })
    H.c4({ label = "2 counts, Slice Bread with rotten bread", name = S.R.slice, slotFt = H.kind("bread") or "Base.Bread", surf = true, stage = breadStage(true) })
    H.caseEnd("2 counts")
end

-- ===================================================================== 3. which item a craft takes (C5)
-- the type chosen for a slot as a player chooses it: the slot's alternatives opened, the type's row, Back
function H.choose(T, name, ft, label)
    H.step(3, function()
        if T.off then return end
        local idx = H.slotOf(name, ft)
        T.idx = idx
        if not idx then T.off = true; Q.check(false, label .. ": " .. name .. " has a slot that takes " .. tostring(ft)); return end
        local z = nil
        for _, x in ipairs(H.cst().zones or {}) do if x.type == "slotAlt" and x.idx == idx then z = x end end
        T.altBy = "mouse"
        if z then H.click(z, label .. ", the slot's alternatives") end
        if not H.cst().altSlotName then
            T.altBy = "code"
            pcall(S.CC.togglePick, H.cst(), name, idx, ft)
            Q.say("note " .. label .. ": the slot's alternatives did not open by a click: the type is chosen from code")
        end
    end)
    H.step(4, function()
        if T.off or T.altBy == "code" then return end
        local z = nil
        for _, x in ipairs(H.cst().zones or {}) do if x.type == "altPick" and x.id == ft then z = x end end
        if z then H.click(z, label .. ", the type's row") else T.altBy = "code"; pcall(S.CC.togglePick, H.cst(), name, T.idx, ft); Q.say("note " .. label .. ": the type's row is not drawn: chosen from code") end
    end)
    H.step(4, function()
        if T.off then return end
        if H.cst().altSlotName then
            if not H.press("altStrip_back", label .. ", Back") then pcall(S.CC.exitAltMode, H.cst()) end
        end
        T.picked = S.CC.pickFor(H.cst(), name, T.idx)
        Q.check(T.picked == ft, label .. ": the branch type is chosen for its slot (" .. T.altBy .. ")", tostring(T.picked))
    end)
end
-- queue: Craft pressed and watched to the end; T.W, T.sum
function H.craftWatch(T, label, ms, onTick)
    H.step(2, function()
        if T.off then return end
        T.W = H.watchNew(T.out or S.OUT.stake)
        T.W.onTick = onTick
        T.pressed = H.press("action_build", label)
        T.queued = H.qcount("ISHandcraftAction")
        if not T.pressed then Q.check(false, label .. ": Craft is drawn on the card", H.rowText(T.name or S.R.stake)) end
    end)
    H.wait(ms or 40000, function() return T.off or not T.W or H.watchTick(T.W) end, function(ok)
        H.speed(1)
        if T.off or not T.W then return end
        T.sum = H.watchSum(T.W)
        T.done = ok
        if not ok then H.qstop() end
    end)
end
function H.usedOf(T, a)
    local it = a and a.items
    if not it then return end
    for _, x in ipairs(T.watchFor or {}) do
        local has = false
        pcall(function() has = it:contains(x) end)
        if has then T.usedSeen = T.usedSeen or {}; T.usedSeen[x] = true end
    end
end
function H.whichOf(set, a, b, na, nb)
    if set[a] and not set[b] then return na end
    if set[b] and not set[a] then return nb end
    if set[a] and set[b] then return "both" end
    return "neither"
end
function S.case3branch(chosen)
    local T = { name = S.R.stake }
    local label = chosen and "3 which, the branch type chosen" or "3 which, as found"
    H.stageOpen(T, S.R.stake, label, function(T2)
        T2.k = H.give(S.stakeKnife)
        T2.fav = H.give(S.stakeBranch)                -- (the favourite first: the containers' order offers it first)
        T2.plain = H.give(S.stakeBranch)
        if not (T2.k and T2.fav and T2.plain) then T2.skip = "a knife and two branches could not be given"; return end
        H.call(T2.fav, "setFavorite", true)
    end)
    H.step(2, function()
        if T.off then return end
        local set, can = H.gameUses(S.R.stake)
        T.game = H.whichOf(set, T.fav, T.plain, "the favourite", "the plain one")
        T.gameCan = can
    end)
    if chosen then H.choose(T, S.R.stake, S.stakeBranch, label) end
    H.craftWatch(T, label, 40000)
    H.step(2, function()
        if T.off then return end
        local used = H.whichOf({ [T.fav] = H.gone(T.fav), [T.plain] = H.gone(T.plain) }, T.fav, T.plain, "the favourite", "the plain one")
        Q.check(T.sum and T.sum.made == 1 and used == T.game, label .. " (C5): the craft uses the branch the game's own logic picks",
            "used " .. used .. ", the game picks " .. tostring(T.game) .. " (it can " .. tostring(T.gameCan) .. "), made " .. tostring(T.sum and T.sum.made)
            .. "; " .. tostring(T.sum and T.sum.text))
        H.shut()
        for _, it in ipairs({ T.k, T.fav, T.plain }) do H.removeItem(it) end
        H.sweepNew()
    end)
end
function S.case3tool()
    local T = { name = S.R.stake }
    local label = "3 which, a worn-down knife and a good one"
    H.stageOpen(T, S.R.stake, label, function(T2)
        T2.worn = H.give(S.stakeKnife)               -- (the worn one first: the containers' order offers it first)
        T2.good = H.give(S.stakeKnife)
        T2.b = H.give(S.stakeBranch)
        if not (T2.worn and T2.good and T2.b) then T2.skip = "two knives and a branch could not be given"; return end
        H.call(T2.worn, "setCondition", 1)
        T2.watchFor = { T2.worn, T2.good }
        T2.c0 = { w = H.cond(T2.worn), g = H.cond(T2.good) }
    end)
    H.step(2, function()
        if T.off then return end
        local set = H.gameUses(S.R.stake)
        T.game = H.whichOf(set, T.worn, T.good, "the worn-down knife", "the good knife")
    end)
    H.craftWatch(T, label, 40000, function(W, a) H.usedOf(T, a) end)
    H.step(2, function()
        if T.off then return end
        local used = H.whichOf(T.usedSeen or {}, T.worn, T.good, "the worn-down knife", "the good knife")
        Q.check(T.sum and T.sum.made == 1 and used == T.game, label .. " (C5): the craft uses the knife the game's own logic picks",
            "used " .. used .. ", the game picks " .. tostring(T.game) .. "; conditions " .. T.c0.w .. " -> " .. H.cond(T.worn) .. " and "
            .. T.c0.g .. " -> " .. H.cond(T.good) .. "; " .. tostring(T.sum and T.sum.text))
        H.shut()
        for _, it in ipairs({ T.worn, T.good, T.b }) do H.removeItem(it) end
        H.sweepNew()
    end)
end
function S.case3()
    local T = {}
    H.step(2, function() H.caseStart() end)
    H.toTab(T, "3 which")
    S.case3branch(false)
    S.case3branch(true)
    S.case3tool()
    H.caseEnd("3 which")
end

-- ===================================================================== 4. Craft twice with materials for one (C1); a batch losing an input (C2)
function S.case4twice()
    local T = { name = S.R.stake }
    H.stageOpen(T, S.R.stake, "4 twice", function(T2)
        if not (H.give(S.stakeKnife) and H.give(S.stakeBranch)) then T2.skip = "a knife and a branch could not be given" end
    end)
    H.step(2, function()
        if T.off then return end
        if not Q.check(H.zedCan(H.row(S.R.stake)) and H.zone("action_build") ~= nil, "4 twice: one branch and a knife make Make Stake ready", H.rowText(S.R.stake)) then T.off = true; return end
        T.c0 = H.md(S.R.stake)
        T.W = H.watchNew(S.OUT.stake)
        H.press("action_build", "4 twice, the first press")
        T.q1 = H.qcount("ISHandcraftAction")
    end)
    -- (the first craft queued and started, at x1 so it is still running: Craft pressed again, as a second click does)
    H.step(8, function()
        if T.off then return end
        H.watchTick(T.W)
        T.lit = H.zedCan(H.row(S.R.stake))
        T.z2 = H.zone("action_build") ~= nil
        H.press("action_build", "4 twice, the second press")
        T.q2 = H.qcount("ISHandcraftAction")
    end)
    H.wait(60000, function() return T.off or H.watchTick(T.W) end, function(ok)
        H.speed(1)
        if T.off then return end
        local s = H.watchSum(T.W)
        Q.check(T.q2 <= T.q1, "4 twice (C1): Craft pressed again while its craft runs queues nothing more (the game grays its Craft while a craft runs)",
            "queued " .. tostring(T.q1) .. " after the first press, " .. tostring(T.q2) .. " after the second; Craft lit between " .. tostring(T.lit)
            .. ", its zone drawn " .. tostring(T.z2) .. "; " .. s.text)
        if (T.q2 or 0) > (T.q1 or 0) then
            Q.check(s.empty == 0, "4 twice (C1): the second craft does not run its whole time for nothing", s.empty .. " ran for nothing; " .. s.text)
        end
        Q.say("NOTE 4 twice (C19): " .. (H.md(S.R.stake) - T.c0) .. " added to ZeD's use count for " .. s.made .. " made (one per press, not per craft)")
        if not ok then H.qstop() end
        H.shut()
        for _, it in ipairs(S.caseMade) do H.removeItem(it) end
        H.sweepNew()
    end)
end
-- a branch the running craft does not hold, taken away once the first stake is made
function H.takeMid(T, a)
    if T.taken or H.count(S.OUT.stake) - T.W.c0 < 1 then return end
    if not (a and a.Type == "ISHandcraftAction" and a.items) then return end
    for _, b in ipairs(T.bs or {}) do
        local inUse = false
        pcall(function() inUse = a.items:contains(b) end)
        if not T.taken and not inUse and H.where(b) ~= nil then
            H.removeItem(b)
            T.taken = getTimestampMs()
        end
    end
end
function S.case4batch(T, who)
    local label = "4 batch (C2), " .. who
    H.step(2, function()
        T[who], T.skipB = nil, nil
        if T.off then return end
        T.k = H.give(S.stakeKnife)
        T.bs = H.giveN(S.stakeBranch, 3)
        if not (T.k and #T.bs == 3) then Q.skip(label, "a knife and 3 branches could not be given"); T.skipB = true; return end
        if who == "ZeD" then T.go = H.open(S.R.stake, label) end
        T.t0 = getTimestampMs()
    end)
    H.wait(9000, function()
        if T.off or T.skipB then return true end
        if who == "the game" then return H.gameMost(S.R.stake, nil, nil, true) == 3 end
        return H.fresh(T.t0, S.R.stake) and (H.row(S.R.stake).maxBatchQty or 1) >= 3
    end, function(ok)
        if T.off or T.skipB then return end
        T.W = H.watchNew(S.OUT.stake)
        T.W.onTick = function(W, a) H.takeMid(T, a) end
        T.taken = nil
        if who == "ZeD" then
            H.cst().qty = 3
            H.press("action_build", label)
        else
            local l = H.logic(S.R.stake)
            local acts = nil
            pcall(function() l:canPerformCurrentRecipe(); acts = ISEntityUI.HandcraftStartMultiple(S.p, l, false, 3, true) end)
            T.gameActs = acts and #acts or 0
        end
        T.q = H.qcount("ISHandcraftAction")
    end)
    H.wait(90000, function() return T.off or T.skipB or H.watchTick(T.W) end, function(ok)
        H.speed(1)
        if T.off or T.skipB then return end
        local s = H.watchSum(T.W)
        T[who] = s
        Q.say("NOTE " .. label .. ": a batch of 3 queued " .. T.q .. ", one branch taken away after the first stake (" .. tostring(T.taken ~= nil)
            .. "): made " .. s.made .. ", " .. s.empty .. " ran their whole time for nothing; " .. s.text)
        if not ok then H.qstop() end
        for _, b in ipairs(T.bs or {}) do H.removeItem(b) end
        H.removeItem(T.k)
        H.sweepNew()
    end)
end
function S.case4()
    local T = {}
    H.step(2, function() H.caseStart() end)
    H.toTab(T, "4 twice")
    S.case4twice()
    S.case4batch(T, "ZeD")
    S.case4batch(T, "the game")
    H.step(2, function()
        if T.off then return end
        local z, g = T["ZeD"], T["the game"]
        if not (z and g) then Q.skip("4 batch (C2): ZeD against the game", "one of the two batches did not run"); return end
        Q.check(z.empty <= g.empty, "4 batch (C2): a batch losing an input mid-way loses no more crafts' time in ZeD than in the game's own batch",
            "ZeD " .. z.empty .. " empty of " .. z.crafts .. " (made " .. z.made .. "), the game " .. g.empty .. " empty of " .. g.crafts .. " (made " .. g.made .. ")")
    end)
    H.caseEnd("4 twice")
end

-- ===================================================================== 5. batch counts (C7)
function S.case5n(n)
    local T = { name = S.R.stake }
    local label = "5 batch of " .. n
    H.step(2, function()
        if T.off then return end
        T.k = H.give(S.stakeKnife)
        T.bs = H.giveN(S.stakeBranch, n)
        if not (T.k and #T.bs == n) then Q.skip(label, "a knife and " .. n .. " branches could not be given"); T.off = true; return end
        T.go = H.open(S.R.stake, label)
        T.t0 = getTimestampMs()
    end)
    H.wait(10000, function()
        if T.off then return true end
        local rd = H.row(S.R.stake)
        if not (H.fresh(T.t0, S.R.stake) and H.zedCan(rd)) then return false end
        local g = H.gameMost(S.R.stake, nil, nil, false)
        return g ~= nil and g == (rd.maxBatchQty or 1)
    end, function(ok)
        if T.off then return end
        local rd, st = H.row(S.R.stake), H.cst()
        T.zmax = rd and rd.maxBatchQty or 1
        local gF, gT = H.gameMost(S.R.stake, nil, nil, false), H.gameMost(S.R.stake, nil, nil, true)
        Q.check(ok and T.zmax == gF, label .. " (C7): the band's most is what the game's own Max sets", "ZeD " .. tostring(T.zmax) .. ", the game's Max " .. tostring(gF) .. " (its start's count " .. tostring(gT) .. ")")
        local okM = H.press("action_max", label .. ", Max")
        T.shown = st.qty
        Q.check(okM and st.qty == T.zmax, label .. ": Max sets the amount to the most", "Max drawn " .. tostring(okM) .. ", the amount " .. tostring(st.qty))
    end)
    H.craftWatch(T, label, n * 12000 + 20000)
    H.step(2, function()
        if T.off then return end
        local s = T.sum or { made = 0, text = "no watch" }
        local broke = H.call(T.k, "isBroken") == true or H.gone(T.k)
        if broke then
            Q.skip(label .. ": what is made is the amount shown", "the knife broke mid-batch (C2 shows what then runs): shown " .. tostring(T.shown) .. ", made " .. s.made .. "; " .. s.text)
        else
            Q.check(T.queued == T.shown and s.made == T.shown, label .. " (C7): what is made is the amount shown",
                "shown " .. tostring(T.shown) .. ", queued " .. tostring(T.queued) .. ", made " .. s.made .. "; the knife " .. H.cond(T.k) .. "; " .. s.text)
        end
        H.shut()
        H.removeItem(T.k)
        for _, b in ipairs(T.bs or {}) do H.removeItem(b) end
        H.sweepNew()
    end)
end
-- a batch above the game's count: refused whole, as the game's own start refuses it
function S.case5over()
    local T = { name = S.R.stake }
    local label = "5 batch above the count"
    H.stageOpen(T, S.R.stake, label, function(T2)
        T2.k = H.give(S.stakeKnife)
        T2.bs = H.giveN(S.stakeBranch, 3)
        if not (T2.k and #T2.bs == 3) then T2.skip = "a knife and 3 branches could not be given" end
    end)
    H.step(2, function()
        if T.off then return end
        local st = H.cst()
        H.press("action_max", label)
        T.amount = st.qty
        H.removeItem(T.bs[3])                       -- (taken the frame Craft is pressed: the band still offers 3)
        local c0 = H.md(S.R.stake)
        H.press("action_build", label)
        T.q = H.qcount("ISHandcraftAction")
        T.counted = H.md(S.R.stake) - c0
        T.after = st.qty
        local l = H.logic(S.R.stake)
        local acts = "?"
        pcall(function() l:canPerformCurrentRecipe(); local a = ISEntityUI.HandcraftStartMultiple(S.p, l, false, T.amount, false); acts = a and #a or "refused" end)
        T.game = acts
    end)
    H.step(4, function()
        if T.off then return end
        Q.check(T.q == 0 and T.counted == 0 and T.game == "refused", label .. " (C7): a batch of " .. tostring(T.amount) .. " with materials for 2 is refused whole, as the game's own start refuses it",
            "ZeD queued " .. tostring(T.q) .. " (counted " .. tostring(T.counted) .. "), the game's start " .. tostring(T.game))
        Q.say("NOTE " .. label .. " (C7): no message is given; the amount went from " .. tostring(T.amount) .. " to " .. tostring(T.after))
        H.qstop()
        H.shut()
    end)
end
-- the branch type chosen covering 1 of the 3 the band offers
function S.case5pick()
    local T = { name = S.R.stake }
    local label = "5 batch with a chosen type"
    H.stageOpen(T, S.R.stake, label, function(T2)
        local stick = H.kind("stick")
        T2.k = H.give(S.stakeKnife)
        T2.b = H.give(S.stakeBranch)
        T2.s = stick and H.giveN(stick, 2) or {}
        if not (stick and T2.k and T2.b and #T2.s == 2 and H.slotOf(S.R.stake, stick)) then T2.skip = "a knife, a branch and two sticks Make Stake takes could not be given" end
    end)
    H.choose(T, S.R.stake, S.stakeBranch, label)
    H.step(10, function()
        if T.off then return end
        local st = H.cst()
        if not H.press("action_max", label) then Q.say("note " .. label .. ": no Max drawn (the most is " .. tostring(st._maxQty) .. ")") end
        T.shown = st.qty
    end)
    H.craftWatch(T, label, 50000)
    H.step(2, function()
        if T.off then return end
        local s = T.sum or { made = 0, text = "no watch" }
        Q.check(s.made == T.shown, label .. " (C7): with one branch chosen the amount offered is what is made (the game's own Max counts the chosen items)",
            "offered " .. tostring(T.shown) .. ", queued " .. tostring(T.queued) .. ", made " .. s.made .. " (no word said); " .. s.text)
        H.shut()
    end)
end
function S.case5()
    local T = {}
    H.step(2, function() H.caseStart() end)
    H.toTab(T, "5 batch")
    for _, n in ipairs({ 3, 5, 12 }) do S.case5n(n) end
    S.case5over()
    S.case5pick()
    H.caseEnd("5 batch")
end

-- ===================================================================== 6. inputs from the floor, a crate, a corpse (C9, C10)
-- the place's container seen in the game's list (with him standing still for 2 s, then read afresh): T.still, T.seen
function H.inList(T, label)
    H.wait(2000, function() return T.off or H.listWhere(T.b) ~= "" end, function(ok)
        if T.off then return end
        T.still = ok
        if not ok then H.lootRefresh() end
    end)
    H.wait(3000, function() return T.off or H.listWhere(T.b) ~= "" end, function(ok)
        if T.off then return end
        T.seen = ok
        Q.say("NOTE " .. label .. " (C10): the game's list holds the branch (" .. H.listWhere(T.b) .. ") " .. (T.still and "with him standing still" or (ok and "once read afresh (a turn or a step)" or "not even read afresh")))
        if not ok then T.off = true; Q.skip(label, "the game's list never held the place") end
    end)
end
function S.case6place(where)
    local T = { name = S.R.stake }
    local label = "6 from " .. where
    H.step(2, function()
        if T.off then return end
        local sq = S.p:getCurrentSquare()
        if where == "the floor" then
            T.k = H.give(S.stakeKnife)
            T.b = H.drop(S.stakeBranch, sq, 0.4, 0.6)
        elseif where == "a crate" then
            T.crate = H.mkCrate()
            if T.crate then
                pcall(function() T.k = H.mark(T.crate.inv:AddItem(S.stakeKnife)) end)
                pcall(function() T.b = H.mark(T.crate.inv:AddItem(S.stakeBranch)) end)
                pcall(function() triggerEvent("OnContainerUpdate") end)
            end
        else
            local bsq = nil
            for _, d in ipairs(S.NEAR) do bsq = bsq or H.freeSq(d[1], d[2]) end
            local body, inv = nil, nil
            if bsq then body, inv = H.mkBody(bsq) end
            if body and inv then
                T.k = H.give(S.stakeKnife)
                pcall(function() T.b = H.mark(inv:AddItem(S.stakeBranch)) end)
                T.body = inv
            else
                T.why = inv or "no free square for the body"
            end
        end
        if not (T.k and T.b) then T.off = true; Q.skip(label, T.why or "the place and its things could not be staged") end
    end)
    H.inList(T, label)
    H.step(2, function()
        if T.off then return end
        T.home = H.where(T.b)
        T.go = H.open(S.R.stake, label)
        T.t0 = getTimestampMs()
    end)
    H.wait(9000, function() return T.off or H.fresh(T.t0, S.R.stake) end, function()
        if T.off then return end
        local have = H.have(S.R.stake, (H.slotOf(S.R.stake, S.stakeBranch)))
        local g = H.gameCan(S.R.stake)
        Q.check(have == 1 and H.zedCan(H.row(S.R.stake)) == g and g == true, label .. ": the card counts the branch and Craft is lit as the game would start it",
            "have " .. tostring(have) .. ", " .. H.rowText(S.R.stake) .. ", the game can " .. tostring(g))
        Q.say("NOTE " .. label .. " (C10): the card does not say where the branch is (" .. H.ctype(T.home) .. ")")
    end)
    H.craftWatch(T, label, 40000)
    H.step(2, function()
        if T.off then return end
        local s = T.sum or { made = 0, text = "no watch" }
        Q.check(s.made == 1 and H.gone(T.b), label .. ": Craft makes the stake from the branch there", "made " .. s.made .. ", the branch " .. (H.gone(T.b) and "used" or ("still in " .. H.ctype(H.where(T.b)))) .. "; " .. s.text)
        if where == "a crate" then
            local kc = H.where(T.k)
            Q.check(T.crate ~= nil and kc == T.crate.inv, label .. ": the knife (kept) goes back to the crate it came from, as the game's craft window sends kept things back",
                "the knife in " .. H.ctype(kc))
        else
            Q.say("NOTE " .. label .. ": the knife ends in " .. H.ctype(H.where(T.k)))
        end
        H.shut()
    end)
end
-- C9: the walk fails (the game's walk refused, ISEntityUI.WalkToEntity answering false for the press)
function S.case6walk()
    local T = { name = S.R.drill, out = S.OUT.drill }
    local label = "6 the walk fails (C9)"
    H.step(2, function()
        if T.off then return end
        local r = H.recipe(S.R.drill)
        if H.call(r, "isCanBeDoneFromFloor") == true then T.off = true; Q.skip(label, "Drill Plank takes its inputs where they are (nothing is moved)"); return end
        T.table = H.mkTable(S.NEAR)
        T.crate = T.table and H.mkCrate()
        if T.crate then
            pcall(function() T.p = H.mark(T.crate.inv:AddItem(H.kind("plank"))) end)
            pcall(function() T.d = H.mark(T.crate.inv:AddItem(H.kind("driver"))) end)
            T.b = T.p
        end
        if not (T.table and T.crate and T.p and T.d) then T.off = true; Q.skip(label, "a table and a crate with a plank and a screwdriver could not be laid") end
    end)
    H.inList(T, label)
    H.stageOpen(T, S.R.drill, label, nil)
    H.step(2, function()
        if T.off then return end
        if not Q.check(H.zedCan(H.row(S.R.drill)), label .. ": Drill Plank is ready at the table with its things in the crate", H.rowText(S.R.drill) .. "; card " .. H.cardText(S.R.drill)) then T.off = true; return end
        H.withFields({ { ISEntityUI, "WalkToEntity", function() return false end } }, function()
            H.press("action_build", label)
        end)
        T.crafts = H.qcount("ISHandcraftAction")
        T.kinds = H.qkinds()
    end)
    H.wait(15000, function() return T.off or H.qlen() == 0 end, function()
        if T.off then return end
        Q.check(T.crafts == 0, label .. ": no craft is queued when the walk fails", "queued " .. tostring(T.kinds))
        Q.check(H.where(T.d) == T.crate.inv, label .. ": the screwdriver (kept) goes back to the crate, as the game's window sends kept things back when its walk fails",
            "the queue was " .. tostring(T.kinds) .. "; the screwdriver now in " .. H.ctype(H.where(T.d)) .. ", the plank in " .. H.ctype(H.where(T.p)))
        Q.say("NOTE " .. label .. ": the plank (used by a craft) is in " .. H.ctype(H.where(T.p)) .. " after the walk failed (the game's window moves it too)")
        H.qstop()
        H.shut()
    end)
end
function S.case6()
    local T = {}
    H.step(2, function() H.caseStart() end)
    H.toTab(T, "6 places")
    for _, w in ipairs({ "the floor", "a crate", "a corpse" }) do
        S.case6place(w)
        H.step(2, function() H.caseClean() end)
        H.toTab(T, "6 places")
    end
    S.case6walk()
    H.caseEnd("6 places")
end

-- ===================================================================== 7. a grayed Craft takes a press (C6)
function H.grayPress(T, label, how)
    H.step(2, function()
        if T.off then return end
        local rd = H.row(T.name)
        T.gray = not H.zedCan(rd)
        T.c0, T.q0 = H.md(T.name), H.qlen()
        if not Q.check(T.gray and H.zone("action_build") ~= nil, label .. ": Craft is drawn grayed", H.rowText(T.name)) then T.skipP = true; return end
        if how == "mouse" then H.press("action_build", label) end
        if how == "pad" then T.f = H.padOn() and H.focusEl("craft:actBuild") end
    end)
    if how == "pad" then H.tapA(function() return T.f and not T.skipP end) end
    H.step(6, function()
        if T.off or T.skipP then return end
        if how == "pad" and not T.f then Q.check(false, label .. ": the pad's focus lands on Craft", "on " .. tostring(H.focusedId())); H.padOff(); return end
        Q.check(H.qlen() == T.q0 and H.md(T.name) == T.c0, label .. " (C6): a press on the grayed Craft queues and counts nothing",
            "queue " .. H.qkinds() .. ", counted " .. (H.md(T.name) - T.c0))
        H.qstop()
        H.padOff()
    end)
end
function S.case7()
    local T = {}
    H.step(2, function() H.caseStart() end)
    H.toTab(T, "7 grayed")
    local A = { name = S.R.stake }
    H.stageOpen(A, S.R.stake, "7 grayed, no branch", function(T2)
        if not H.give(S.stakeKnife) then T2.skip = "no knife could be given" end
    end)
    H.grayPress(A, "7 grayed, no branch, a click", "mouse")
    H.grayPress(A, "7 grayed, no branch, pad A", "pad")
    local L = {}
    H.step(2, function()
        local e = H.findUnlearned()
        if not e then L.off = true; Q.skip("7 grayed, a recipe not learned", "no must-learn recipe he lacks is listed (See Not Known Recipes may be off)"); return end
        L.name = e.name
    end)
    H.step(2, function() if not L.off then L.go = H.open(L.name, "7 grayed, not learned"); L.t0 = getTimestampMs() end end)
    H.wait(6000, function() return L.off or H.fresh(L.t0, L.name) end, H.noop)
    H.grayPress(L, "7 grayed, not learned, a click", "mouse")
    H.grayPress(L, "7 grayed, not learned, pad A", "pad")
    H.caseEnd("7 grayed")
end

-- ===================================================================== 8. bench and table (C8, C11)
function S.case8table(dist)
    local T = { name = S.R.drill, out = S.OUT.drill }
    local label = "8 a table " .. dist .. (dist == 1 and " square away" or " squares away")
    H.stageOpen(T, S.R.drill, label, function(T2)
        T2.table = H.mkTable(dist == 1 and S.NEAR or S.FAR2)
        if not T2.table then T2.skip = "no table could be laid " .. dist .. " away"; return end
        if not (H.give(H.kind("plank")) and H.give(H.kind("driver"))) then T2.skip = "no plank and screwdriver could be given" end
    end)
    H.step(2, function()
        if T.off then return end
        local rd = H.row(S.R.drill)
        T.win = H.gameCan(S.R.drill, H.surf(1))      -- (the game's craft window looks 1 square: ISEntityUI.OpenHandcraftWindow)
        T.menu = H.gameCan(S.R.drill, H.surf(2))     -- (its item menu's direct craft looks 2)
        T.zed = H.zedCan(rd)
        local d = "ZeD " .. H.rowText(S.R.drill) .. "; the game's window " .. tostring(T.win) .. ", its item menu " .. tostring(T.menu)
        if dist == 1 then
            Q.check(T.zed == T.win, label .. " (C11): Drill Plank is ready exactly as the game's craft window finds the table", d)
            T.off = true
        else
            Q.say("NOTE " .. label .. " (C11): " .. d)
            if not T.zed then T.off = true end
        end
    end)
    H.craftWatch(T, label, 30000)
    H.step(2, function()
        if T.off or dist == 1 then return end
        local s = T.sum or { made = 0, empty = 0, text = "no watch" }
        if s.made >= 1 then
            Q.say("NOTE " .. label .. " (C11): ZeD reads Drill Plank ready and Craft makes it (its 2 squares are the item menu's; the game's window looks 1): " .. s.text)
        else
            Q.check(false, label .. " (C11): ZeD reads Drill Plank ready, so Craft must make it", "queued " .. tostring(T.queued) .. ", made 0; " .. s.text)
        end
    end)
    H.step(2, function() H.shut(); H.qstop(); H.caseClean() end)
end
function S.case8wheel(T)
    H.step(2, function()
        if T.off then return end
        if not (H.known(H.kind("clay")) and H.known(H.kind("sandbag"))) then T.noW = "clay or sandbags are not items this game knows"; return end
        local m, why = H.spawnWheel()
        if not m then T.noW = why; return end
        T.wheel = m
        pcall(function() ISEntityUI.OpenWindow(S.p, m) end)      -- (the world menu's station option: ZeD binds and opens the tab)
    end)
    H.wait(4000, function() local cur = S.ST.current(S.p); return T.noW ~= nil or T.off or (cur ~= nil and cur.obj == T.wheel and H.showing()) end, function(ok)
        if T.off then return end
        if T.noW then T.wOff = true; Q.skip("8 bench: the pottery wheel", T.noW); return end
        local cur = S.ST.current(S.p)
        if not Q.check(ok, "8 bench: the pottery wheel opened from the world (ISEntityUI.OpenWindow) binds the Crafting tab to it",
            "bound " .. tostring(cur and cur.name) .. ", the lock " .. tostring(H.call(T.wheel, "getUsingPlayer") == S.p)) then T.wOff = true; return end
        local set = S.ST.recipeSet(cur)
        local data = H.data()
        local n, out = 0, 0
        for _, rd in ipairs((data and data.recipes) or {}) do n = n + 1; if not set[rd.entry.name] then out = out + 1 end end
        Q.check(n > 0 and out == 0 and set[S.R.cup] == true, "8 bench: the list is the wheel's recipes only", n .. " rows, " .. out .. " not the wheel's; the teacup " .. tostring(set[S.R.cup]))
        T.clay = H.giveN(H.kind("clay"), 2)
        T.bags = H.giveN(H.kind("sandbag"), 2)
        T.go = H.open(S.R.cup, "8 bench")
        T.t0 = getTimestampMs()
    end)
    H.wait(9000, function() return T.off or T.wOff or H.fresh(T.t0, S.R.cup) end, function()
        if T.off or T.wOff then return end
        local bench = S.ST.current(S.p)
        local g = H.gameCan(S.R.cup, nil, bench)
        local rd = H.row(S.R.cup)
        Q.check(g ~= nil and H.zedCan(rd) == g, "8 bench: Make Ceramic Teacup at the wheel is ready exactly as the game would start it", H.rowText(S.R.cup) .. "; the game " .. tostring(g))
        if not H.zedCan(rd) then T.wOff = true; return end
        T.W = H.watchNew(S.OUT.cup)
        H.cst().qty = math.min(2, rd.maxBatchQty or 1)
        T.want = H.cst().qty
        H.press("action_build", "8 bench")
        T.q = H.qcount("ISHandcraftAction")
        T.shutAt = nil
    end)
    -- the World window shut once the first teacup is made (mid-batch)
    H.wait(60000, function()
        if T.off or T.wOff then return true end
        local done = H.watchTick(T.W)
        if not T.shutAt and H.count(S.OUT.cup) - T.W.c0 >= 1 and H.qcount("ISHandcraftAction") > 0 then
            T.shutAt = getTimestampMs()
            pcall(function() S.WW.close(S.pn) end)
            if S.WW.isOpen(S.pn) then RT.pairShut() end
        end
        return done
    end, function(ok)
        H.speed(1)
        if T.off or T.wOff then return end
        local s = H.watchSum(T.W)
        Q.say("NOTE 8 bench (C8): a batch of " .. tostring(T.want) .. " (queued " .. tostring(T.q) .. ") with the World window shut "
            .. (T.shutAt and "after the first" or "never (the batch ended first)") .. ": made " .. s.made .. "; " .. s.text
            .. " (the game's own station window lets go of the bench on close too, ISBaseEntityWindow.close)")
        if not ok then H.qstop() end
        -- (a batch of one never shut it: shut now, the lock checked the same)
        if not T.shutAt then
            T.shutAt = getTimestampMs()
            pcall(function() S.WW.close(S.pn) end)
            if S.WW.isOpen(S.pn) then RT.pairShut() end
        end
    end)
    H.wait(2000, function() return T.off or T.wOff or (S.ST.current(S.p) == nil and H.call(T.wheel, "getUsingPlayer") == nil) end, function(ok)
        if T.off or T.wOff then return end
        Q.check(ok, "8 bench (C8): the World window shut lets go of the wheel (the bench free, the tab back to Hand)",
            "bound " .. tostring(S.ST.current(S.p) ~= nil) .. ", the lock " .. tostring(H.call(T.wheel, "getUsingPlayer")))
        RT.pairOpen()
        pcall(S.WW.openTab, S.pn, "craft")
    end)
end
function H.rebind(T, label)
    H.step(10, function()
        if T.off or T.wOff then return end
        RT.pairOpen()
        pcall(function() ISEntityUI.OpenWindow(S.p, T.wheel) end)
    end)
    H.wait(4000, function() local cur = S.ST.current(S.p); return T.off or T.wOff or (cur ~= nil and cur.obj == T.wheel) end, function(ok)
        if T.off or T.wOff then return end
        T.bound = ok
        if not ok then Q.skip(label, "the wheel could not be bound again") end
    end)
end
function S.case8release(T)
    -- walking away past the leash
    H.rebind(T, "8 bench, walked away")
    H.step(2, function()
        if T.off or T.wOff or not T.bound then return end
        H.goTo(S.found.pos.x + 9, S.found.pos.y, S.found.pos.z)
    end)
    H.wait(3000, function() return T.off or T.wOff or not T.bound or S.ST.current(S.p) == nil end, function(ok)
        if T.off or T.wOff or not T.bound then return end
        Q.check(ok and H.call(T.wheel, "getUsingPlayer") == nil, "8 bench (C8): walking 9 tiles away lets go of the wheel", "bound " .. tostring(S.ST.current(S.p) ~= nil))
        H.home()
    end)
    -- B on the pad, on a stop of the tab with no B of its own
    H.rebind(T, "8 bench, pad B")
    H.step(10, function()
        if T.off or T.wOff or not T.bound then return end
        T.f = H.padOn() and H.focusPre("craft:row:") ~= nil
        T.fid = H.focusedId()
    end)
    H.tapB(function() return T.f end)
    H.wait(2000, function() return T.off or T.wOff or not T.f or S.ST.current(S.p) == nil end, function(ok)
        if T.off or T.wOff or not T.bound then return end
        if not T.f then Q.check(false, "8 bench: the pad's focus lands on a recipe row", "on " .. tostring(H.focusedId())); H.padOff(); return end
        Q.check(ok and H.call(T.wheel, "getUsingPlayer") == nil, "8 bench (C8, C13): pad B on a recipe row lets go of the wheel (the tab back to Hand)", "on " .. tostring(T.fid))
        H.padOff()
    end)
end
function S.case8()
    local T = {}
    H.step(2, function() H.caseStart() end)
    H.toTab(T, "8 bench")
    S.case8table(1)
    H.toTab(T, "8 bench")
    S.case8table(2)
    H.toTab(T, "8 bench")
    S.case8wheel(T)
    S.case8release(T)
    H.step(2, function()
        Q.skip("8 bench: a kiln or a forge", "their recipes need fuel lit and the heat the game's own fire cycle makes over in-game hours; the QA run cannot stage a lit kiln or forge in its time, so the pottery wheel stands in as the bench")
    end)
    H.step(2, function()
        H.caseClean()
        local left = {}
        for _, c in ipairs(S.objs) do if H.objLeft(c) then left[#left + 1] = c.what end end
        Q.check(#left == 0, "8 bench: every table and the pottery wheel laid are gone again", H.list(left))
    end)
    H.caseEnd("8 bench")
end

-- ===================================================================== 9. the pad
S.STOP_KINDS = { "craft:stDrop", "craft:catDrop", "craft:search", "craft:section:", "craft:row:", "craft:icon", "craft:stUse", "craft:card:",
    "craft:slotAlt:", "craft:altBack", "craft:altOwned", "craft:altPick:", "craft:actDec", "craft:actInc", "craft:actMax", "craft:actBuild",
    "craft:actQty", "craft:sortMenu", "craft:showMenu" }
function H.stopKind(id)
    id = tostring(id)
    for _, k in ipairs(S.STOP_KINDS) do if string.sub(id, 1, #k) == k then return k end end
    return nil
end
function S.case9stops(T)
    H.stageOpen(T, S.R.stake, "9 pad", function(T2)
        if not (H.give(S.stakeKnife) and #H.giveN(S.stakeBranch, 3) == 3) then T2.skip = "a knife and 3 branches could not be given" end
    end)
    H.step(10, function()
        if T.off then return end
        T.on = H.padOn()
        local unknown, noA, kinds, n = {}, {}, {}, 0
        for _, e in ipairs(H.stops()) do
            n = n + 1
            local k = H.stopKind(e.id)
            if not k then unknown[#unknown + 1] = tostring(e.id) else kinds[k] = (kinds[k] or 0) + 1 end
            if not e.onActivate then noA[#noA + 1] = tostring(e.id) end
        end
        local seen = {}
        for _, k in ipairs(S.STOP_KINDS) do if kinds[k] then seen[#seen + 1] = k .. " " .. kinds[k] end end
        Q.check(n > 0 and #unknown == 0 and #noA == 0, "9 pad: every stop of the tab is a known kind and takes A", n .. " stops; unknown " .. H.list(unknown) .. "; no A " .. H.list(noA))
        Q.say("NOTE 9 pad: the stops with the card open: " .. H.list(seen))
        T.aRow = H.focusEl("craft:row:" .. S.R.spear) or H.focusEl("craft:row:" .. S.R.stake)
        T.aName = (H.focusedId() == "craft:row:" .. S.R.spear) and S.R.spear or S.R.stake
    end)
    -- A on a row: its card opens and the pad goes to Craft, also when Craft is grayed (C14: Carve Spear, no stick)
    H.tapA(function() return T.aRow end)
    H.wait(3000, function() return not T.aRow or (H.cst().selected == T.aName and H.focusedId() == "craft:actBuild") end, function(ok)
        if not T.aRow then Q.skip("9 pad: A on a row", "no recipe row could take the focus"); return end
        Q.check(H.cst().selected == T.aName, "9 pad: A on a recipe row opens its card", tostring(H.cst().selected))
        Q.say("NOTE 9 pad (C14): after A the pad is on " .. tostring(H.focusedId()) .. "; " .. T.aName .. " reads " .. H.rowText(T.aName)
            .. (H.zedCan(H.row(T.aName)) and "" or " (Craft grayed: a second A presses a grayed Craft, case 7)"))
        H.open(S.R.stake, "9 pad")
    end)
    -- the amount by the pad: + then Max then - (or the one box)
    H.step(20, function()
        if T.off then return end
        H.cst().qty = 1
        T.single = H.stopById("craft:actQty") ~= nil
        T.fInc = H.focusEl(T.single and "craft:actQty" or "craft:actInc")
    end)
    H.tapA(function() return T.fInc end)
    H.step(4, function()
        if T.off then return end
        Q.check(T.fInc and H.cst().qty == 2, "9 pad: A on " .. (T.single and "the amount box" or "+") .. " steps the amount to 2", "the amount " .. tostring(H.cst().qty))
        T.fMax = (not T.single) and H.focusEl("craft:actMax")
    end)
    H.tapA(function() return T.fMax end)
    H.step(4, function()
        if T.off or T.single then return end
        local st = H.cst()
        Q.check(T.fMax and st.qty == st._maxQty, "9 pad: A on Max sets the most", tostring(st.qty) .. " of " .. tostring(st._maxQty))
        T.fDec = H.focusEl("craft:actDec")
        T.qMax = st.qty
    end)
    H.tapA(function() return T.fDec end)
    H.step(4, function()
        if T.off or T.single then return end
        Q.check(T.fDec and H.cst().qty == (T.qMax or 0) - 1, "9 pad: A on - steps the amount down", tostring(H.cst().qty))
        H.cst().qty = 1
    end)
end
function S.case9search(T)
    H.step(4, function() if not T.off then T.fS = H.focusEl("craft:search") end end)
    H.tapA(function() return T.fS end)
    H.step(6, function()
        if T.off then return end
        if not T.fS then Q.check(false, "9 pad: the search is a stop", "no craft:search"); return end
        local kb = ZeD.Keyboard and ZeD.Keyboard.isVisible and ZeD.Keyboard.isVisible()
        local caret = false
        pcall(function() caret = RT.ww()._craftSearch.input:isFocused() end)
        Q.check(kb or caret, "9 pad: A on the search opens the pad keyboard on it (or gives it the caret where no pad is plugged in)",
            "keyboard " .. tostring(kb) .. ", caret " .. tostring(caret))
        pcall(function() if ZeD.Keyboard and ZeD.Keyboard.hide then ZeD.Keyboard.hide() end end)
        pcall(function() RT.ww()._craftSearch.input:unfocus() end)
        H.setSearch("")
    end)
end
-- C12: the Category list past its 14th row by the pad
function S.case9cats(T)
    H.step(4, function()
        if T.off then return end
        H.shut()
        T.ncat = #(H.cst().categoryList or {})
        T.fC = H.focusEl("craft:catDrop")
    end)
    H.tapA(function() return T.fC end)
    H.step(6, function()
        if T.off then return end
        local st = H.cst()
        if not (T.fC and st.catDropdownOpen) then Q.check(false, "9 pad: A on Category opens its list", "open " .. tostring(st.catDropdownOpen)); T.cOff = true; return end
        local rows = 0
        for _, e in ipairs(H.stops()) do if string.sub(tostring(e.id), 1, 10) == "craft:cat:" then rows = rows + 1; T.lastCat = e.id end end
        T.rows0 = rows
        if T.lastCat then H.focusEl(T.lastCat) end
        T.maxScroll, T.reached = 0, {}
    end)
    for _ = 1, 24 do
        H.step(2, function()
            if T.off or T.cOff then return end
            RT.padDir("down", RT.ww())
        end)
        H.step(3, function()
            if T.off or T.cOff then return end
            local st = H.cst()
            T.maxScroll = math.max(T.maxScroll, st.catDropdownScroll or 0)
            local id = H.focusedId()
            if id then T.reached[id] = true end
        end)
    end
    H.step(2, function()
        if T.off or T.cOff then return end
        local st = H.cst()
        local beyond = 0
        for i = 15, #(st.categoryList or {}) do if T.reached["craft:cat:" .. tostring(st.categoryList[i].id)] then beyond = beyond + 1 end end
        if T.ncat <= 14 then
            Q.say("NOTE 9 pad (C12): " .. T.ncat .. " categories, all in the list's 14 rows")
        else
            Q.check(beyond > 0 or T.maxScroll > 0, "9 pad (C12): the pad reaches the categories past the list's 14th row",
                T.ncat .. " categories, " .. T.rows0 .. " stops in the open list; D-pad Down 24 times: the list scrolled to " .. T.maxScroll .. ", " .. beyond .. " rows past the 14th reached")
        end
    end)
    H.tapB(function() return not T.cOff and H.cst().catDropdownOpen end)
    H.step(4, function()
        if T.off then return end
        local st = H.cst()
        Q.check(not st.catDropdownOpen, "9 pad: B shuts the Category list", tostring(st.catDropdownOpen))
        st.catDropdownOpen, st.catDropdownScroll, st.activeCat, st.filterDirty = false, 0, "all", true
    end)
end
-- C13: B with no station: on the card; with a craft running; in the alternatives
function S.case9b(T)
    H.step(4, function()
        if T.off then return end
        H.open(S.R.stake, "9 pad B")
    end)
    H.step(20, function()
        if T.off then return end
        T.fCard = H.focusEl("craft:card:req")
        T.sel0 = H.cst().selected
    end)
    H.tapB(function() return T.fCard end)
    H.step(6, function()
        if T.off then return end
        Q.say("NOTE 9 pad (C13): B on the card's Required head with no station: the card " .. ((H.cst().selected == T.sel0) and "stays open" or "shut")
            .. ", the pad on " .. tostring(H.focusedId()) .. " (KISS #47: Escape shuts the card)")
        H.open(S.R.stake, "9 pad B")
        -- a craft running at x1, then B on the Required head
        T.W = H.watchNew(S.OUT.stake)
        T.cPress = H.press("action_build", "9 pad B, Craft")
    end)
    H.wait(4000, function() return T.off or not T.cPress or H.head() == "ISHandcraftAction" end, function(ok)
        if T.off then return end
        H.speed(1)
        T.running = ok and T.cPress
        T.fCard2 = T.running and H.focusEl("craft:card:req")
    end)
    H.tapB(function() return T.fCard2 end)
    H.step(8, function()
        if T.off then return end
        if not T.running then Q.skip("9 pad (C13): B while a craft runs", "no craft started"); return end
        Q.check(H.head() == "ISHandcraftAction", "9 pad (C13): B on the card with no station leaves the running craft going (the game's B shuts its window and the craft goes on)",
            "the queue after B " .. H.qkinds())
    end)
    H.wait(40000, function() return T.off or H.watchTick(T.W) end, function() H.speed(1); H.qstop() end)
    -- in the alternatives
    H.step(4, function()
        if T.off then return end
        H.open(S.R.stake, "9 pad B")
        local idx = H.slotOf(S.R.stake, S.stakeBranch)
        T.fAlt = idx ~= nil and H.focusPre("craft:slotAlt:") ~= nil
    end)
    H.tapA(function() return T.fAlt end)
    H.step(6, function()
        if T.off then return end
        T.inAlt = H.cst().altSlotName ~= nil
        if T.inAlt then T.fPick = H.focusPre("craft:altPick:") ~= nil or H.focusEl("craft:altBack") end
    end)
    H.tapB(function() return T.inAlt and T.fPick end)
    H.step(6, function()
        if T.off then return end
        if not T.inAlt then Q.skip("9 pad: B in the alternatives", "A on the slot opened no alternatives"); return end
        Q.say("NOTE 9 pad (C13): B in the alternatives " .. (H.cst().altSlotName and "leaves the list open (only Back leaves it)" or "goes back to the card") .. ", the pad on " .. tostring(H.focusedId()))
        pcall(S.CC.exitAltMode, H.cst())
    end)
end
function S.case9()
    local T = {}
    H.step(2, function() H.caseStart() end)
    H.toTab(T, "9 pad")
    S.case9stops(T)
    S.case9search(T)
    S.case9cats(T)
    S.case9b(T)
    H.step(2, function() H.padOff() end)
    H.caseEnd("9 pad")
end

-- ===================================================================== 10. layout and pictures
function H.zonesInside(label)
    local r = S.spy and S.spy.r
    local st = H.cst()
    if not (r and st) then Q.skip(label .. ": every zone inside the tab", "the tab's rectangle was not read"); return end
    local bad, n = {}, 0
    for _, z in ipairs(st.zones or {}) do
        local skip = (z.type == "recipeRow" or z.type == "recipeStar" or z.type == "sectionHeader") and not H.inView(z)
        if not skip and (z.w or 0) > 0 then
            n = n + 1
            if z.x < r.x - 1 or z.x + z.w > r.x + r.w + 1 then
                if #bad < 5 then bad[#bad + 1] = tostring(z.type) .. " " .. math.floor(z.x) .. "+" .. math.floor(z.w) end
            end
        end
    end
    Q.check(#bad == 0, label .. ": every drawn zone lies inside the tab (" .. math.floor(r.x) .. "+" .. math.floor(r.w) .. " px)", n .. " zones; out: " .. H.list(bad))
    RT.bounds(Q, label)
end
function H.cardShot(tag, what)
    H.step(2, function() H.open(S.R.stake, "10 pictures") end)
    Q.waitMs(900)
    H.shot("cr_card_" .. tag, what .. ": the list split with Make Stake's card (3 branches and a knife carried), the band's amount and Craft")
end
function S.case10()
    local T = {}
    H.step(2, function() H.caseStart() end)
    H.toTab(T, "10 layout")
    H.step(2, function()
        if T.off then return end
        H.giveN(S.stakeBranch, 3)
        H.give(S.stakeKnife)
        H.spyOn()
        H.shut()
    end)
    Q.waitMs(900)
    H.step(2, function()
        if T.off then return end
        local w = RT.ww()
        T.full = math.abs((w._drawerEffW or 0) - ZeD.T.px(480)) <= 1
        Q.check(T.full, "10 layout: the Crafting tab is the full card (480)", math.floor(w._drawerEffW or 0) .. " px, " .. ZeD.T.px(480) .. " wanted")
    end)
    for i, th in ipairs(S.THEMES) do
        H.step(2, function() if not T.off then H.theme(th.key); H.shut() end end)
        Q.waitMs(700)
        if i == 1 then H.shot("cr_list_" .. th.key .. "_" .. H.sizeTag(), th.word .. ": the recipe list alone, Show All") end
        H.cardShot(th.key .. "_" .. H.sizeTag(), th.word)
        if i == 1 then
            H.step(2, function() H.zonesInside("10 layout, the full card") end)
            H.step(2, function()
                local idx = H.slotOf(S.R.stake, S.stakeBranch)
                local z = nil
                for _, x in ipairs(H.cst().zones or {}) do if x.type == "slotAlt" and x.idx == idx then z = x end end
                if z then H.click(z, "10 pictures, the alternatives") end
            end)
            Q.waitMs(700)
            H.shot("cr_alts_" .. th.key .. "_" .. H.sizeTag(), th.word .. ": the branch slot's alternatives (Owned and Other)")
            H.step(2, function() pcall(S.CC.exitAltMode, H.cst()) end)
        end
    end
    H.step(2, function() H.themeBack() end)
    -- Large text
    H.step(2, function() if not T.off then H.sizeSet("large") end end)
    Q.waitMs(1200)
    H.cardShot("large_" .. H.sizeTag(), "Large text")
    H.step(2, function() H.zonesInside("10 layout, Large text") end)
    H.step(2, function() H.sizeBack() end)
    -- the half card: the World window's width cap held in (eq_tab's way)
    H.step(2, function()
        if T.off then return end
        H.shut()
        local w = RT.ww()
        if w then
            if S.back.maxW == nil then S.back.maxW = { v = w._maxWinW } end
            S.layoutTouched = true
            w._maxWinW = ZeD.T.px(700)
        end
        T.hs = { last = -1, n = 0 }
    end)
    H.wait(4000, function()
        if T.off then return true end
        local w = RT.ww()
        local e = math.floor((w and w._drawerEffW) or 0)
        if e == T.hs.last then T.hs.n = T.hs.n + 1 else T.hs.last, T.hs.n = e, 0 end
        return T.hs.n >= 6 and math.abs(e - ZeD.T.px(220)) <= 1
    end, function(ok)
        if T.off then return end
        T.half = ok
        if not ok then Q.skip("10 layout: the half card (220)", "the World window would not hold the half card here (the drawer is " .. math.floor(RT.ww()._drawerEffW or 0) .. " px)") end
    end)
    H.step(2, function() if T.half then H.open(S.R.stake, "10 the half card") end end)
    Q.waitMs(900)
    H.step(2, function() if T.half then H.zonesInside("10 layout, the half card (220)") end end)
    H.step(2, function() if T.half then H.shot("cr_half_" .. H.sizeTag(), "the half card (220): the Crafting tab with Make Stake's card") end end)
    H.step(2, function() H.halfBack() end)
    Q.waitMs(900)
    H.step(2, function()
        Q.check(#S.shots >= 6, "10 pictures: the list, the card and the alternatives in Dark, the card in Light, High contrast and Large text were taken (a person judges them)", H.list(S.shots))
        H.spyOff()
    end)
    H.caseEnd("10 layout")
end
function H.halfBack()
    if not S.back.maxW then return end
    local w = RT.ww()
    if w then w._maxWinW = S.back.maxW.v end
    S.back.maxW = nil
end

-- ===================================================================== put back
function H.putBack()
    if not S.back.on then return end
    S.back.on = nil
    local f = S.found
    H.speed(1)
    H.qstop()
    H.park(false)
    H.spyOff()
    H.padOff()
    H.themeBack()
    H.sizeBack()
    H.halfBack()
    pcall(function() if S.orig.walk then ISEntityUI.WalkToEntity = S.orig.walk end end)
    pcall(function() if S.orig.render and S.CC.render ~= S.orig.render then S.CC.render = S.orig.render end end)
    pcall(function() S.ST.unbind(S.p) end)
    for _, c in ipairs(S.objs) do H.rmObj(c) end
    for _, b in ipairs(S.bodies) do H.rmBody(b) end
    for _, it in ipairs(S.made) do H.removeItem(it) end
    for nm in pairs(S.learned) do H.forget(nm) end
    S.learned = {}
    H.perksBack()
    local md = S.p:getModData()
    for k, v in pairs(S.fav) do md[k] = v.v end
    if f.recorded then
        for key, v in pairs(f.mdKeys or {}) do
            if v.v then local t = {}; for k2, v2 in pairs(v.v) do t[k2] = v2 end; md[key] = t else md[key] = nil end
        end
        local w = RT.ww()
        if w then pcall(S.CC.loadPins, w, "ZeD_CraftPins", "_craftPins"); w._craftCache = nil end
        pcall(function() S.p:setTimedActionInstantCheat(f.inst and true or false) end)
        pcall(function() S.p:setBuildCheat(f.bc and true or false) end)
        pcall(function() ISBuildMenu.cheat = f.bm end)
        pcall(function() ISMoveableDefinitions.cheat = f.mdc end)
        pcall(function() if f.tod then getGameTime():setTimeOfDay(f.tod) end end)
        pcall(function()
            local stt = S.p:getStats()
            for k, v in pairs(f.stats or {}) do pcall(function() stt:set(CharacterStat[k], v) end) end
        end)
        pcall(function() if f.invinc ~= nil then S.p:setInvincible(f.invinc) end end)
    end
end
function S.buildPutBack()
    Q.mark()
    Q.step(2, function()
        H.putBack()
        RT.pairOpen()
    end)
    Q.step(10, function()
        local f = S.found
        if not f.recorded then return end
        S.swept = H.sweepNew()
        S.lost = H.unstash()
        -- (his own things a craft used in place of a given one: one new of the type for each that is short)
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
        H.wornBack()
        pcall(function() S.p:setPrimaryHandItem(f.hands.p) end)
        pcall(function() S.p:setSecondaryHandItem(f.hands.s) end)
        H.home()
        if S.layoutTouched and f.layout and ZEDQA_LAYOUT_BACK then pcall(ZEDQA_LAYOUT_BACK, f.layout, "cr_tab") end
        H.lootRefresh()
        -- (a station bound again resets the tab's category and card on its next drawn frame: bound first, the tab's
        -- choices set after it)
        if f.st then pcall(function() S.ST.bind(S.p, f.st) end) end
        pcall(S.WW.openTab, S.pn, "craft")
    end)
    Q.step(20, function()
        local f = S.found
        if not f.recorded then return end
        local st = H.cst()
        if st and f.keep then H.putState(st, f.keep) end
        H.tab(f.tab or "loot")
    end)
    Q.step(20, function()
        local f = S.found
        if not f.recorded then Q.skip("put back", "nothing was staged"); return end
        local left = {}
        for _, it in ipairs(S.made) do if not H.gone(it) and #left < 5 then left[#left + 1] = H.ft(it) end end
        Q.check(#left == 0, "put back: every thing the run gave is gone (inventory, floor, crates, the corpse)", H.list(left))
        local extra = {}
        for _, it in ipairs(H.all()) do if not f.inv0[it] and #extra < 5 then extra[#extra + 1] = H.ft(it) end end
        Q.check(#extra == 0 and (S.lost or 0) == 0, "put back: he carries what he carried (nothing crafted left, his set-aside things back)",
            "new " .. H.list(extra) .. "; " .. tostring(S.swept) .. " swept, " .. tostring(S.floorSwept) .. " off the floor, " .. tostring(S.refilled)
            .. " of his own used things given again, " .. tostring(S.lost) .. " set-aside things not given back")
        local objs = {}
        for _, c in ipairs(S.objs) do if H.objLeft(c) then objs[#objs + 1] = c.what end end
        for _, b in ipairs(S.bodies) do if H.bodyLeft(b) then objs[#objs + 1] = "the corpse" end end
        Q.check(#objs == 0, "put back: every object laid is gone (tables, crates, the pottery wheel, the corpse)", H.list(objs))
        local inst, bc = nil, nil
        pcall(function() inst, bc = S.p:isTimedActionInstantCheat(), S.p:isBuildCheat() end)
        Q.check((inst and true or false) == (f.inst and true or false) and (bc and true or false) == (f.bc and true or false)
            and ISBuildMenu.cheat == f.bm and ISMoveableDefinitions.cheat == f.mdc,
            "put back: the cheats as found (instant actions, his BuildCheat, ISBuildMenu.cheat, ISMoveableDefinitions.cheat)",
            tostring(inst) .. ", " .. tostring(bc) .. ", " .. tostring(ISBuildMenu.cheat) .. ", " .. tostring(ISMoveableDefinitions.cheat))
        local md = S.p:getModData()
        local favOk = true
        for k, v in pairs(S.fav) do if md[k] ~= v.v then favOk = false end end
        local known = {}
        for nm in pairs(S.learned) do known[#known + 1] = nm end
        Q.check(favOk and #known == 0, "put back: the game's favourite key and the recipes he knows as found", "learned left: " .. H.list(known))
        local dx, dy = math.abs(S.p:getX() - f.pos.x), math.abs(S.p:getY() - f.pos.y)
        local w = RT.ww()
        Q.check(dx < 0.6 and dy < 0.6 and S.ST.current(S.p) == (f.st or nil) and H.qlen() == 0 and getGameSpeed() == 1,
            "put back: he stands where he stood, the station as found, no action queued, game speed 1", string.format("%.1f,%.1f off", dx, dy) .. ", " .. H.qkinds())
        Q.check(ZeD.currentBase == f.base and ZeD.currentSize == f.size and H.lockFound() == (S.lockWas or H.lockFound()) and S.spy == nil
            and S.parked == nil and S.back.maxW == nil and S.CC.render == S.orig.render and (not ISEntityUI or ISEntityUI.WalkToEntity == S.orig.walk),
            "put back: the theme, the text size, the input lock, the width cap, the pointer and ZeD's draw and the game's walk as found",
            tostring(ZeD.currentBase) .. ", " .. tostring(ZeD.currentSize) .. ", lock " .. H.lockFound())
        local st = H.cst()
        local k = f.keep or {}
        Q.check(st == nil or (st.selected == k.sel and (st.search or "") == (k.search or "") and st.activeCat == k.cat and st.sort == k.sort),
            "put back: the Crafting tab's card, search, category and Sort as found", tostring(st and st.selected) .. ", " .. tostring(st and st.search) .. ", " .. tostring(st and st.activeCat))
        Q.check(S.errs == 0, "put back: nothing ZeD ran for this script threw", S.errs .. " caught")
        local e1 = H.errN()
        if S.err0 and e1 then Q.check(e1 == S.err0, "the Crafting tab run ran with no Lua error", (e1 - S.err0) .. " new")
        else Q.skip("the Crafting tab run's Lua error count", "the game's Lua error count cannot be read here") end
        Q.say("NOTE put back: skill XP the crafts awarded (Carving, Pottery) is not taken back")
    end)
    Q.step(10, function()
        local f = S.found
        if f.pair == false and RT.isOpen() then RT.pairShut() end
    end)
end

-- ===================================================================== the run
-- (the knife and branch types the cases queue with are known when the queue is built; setup checks them)
S.stakeKnife, S.stakeBranch = H.kind("knife"), H.kind("branch")
function S.build()
    S.setup()
    S.case1()
    S.case2()
    S.case3()
    S.case4()
    S.case5()
    S.case6()
    S.case7()
    S.case8()
    S.case9()
    S.case10()
end
S.build()
S.buildPutBack()
Q.start()
