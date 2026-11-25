-- ZeDUI/tools/qa/bx_craft.lua  (Nov 21 2026, QA beast mode): craft, build, dismantle, whittle and tinker through ZeD,
-- fast and in odd orders. Needs zedqa_prelude.lua and rt_kit.lua first. grep "ZEDQA bx_crf".
--   CRAFT (World window, Crafting tab; CraftingTab.lua + CraftingCore.lua): the search field (nothing found, then the
--     stake), a row click opens the card, five more clicks leave it open and Escape shuts it (KISS #47), the Sort
--     list and a pin (right-click) open and
--     shut; Make Stake with the branch missing (Craft pressed: nothing queued, nothing counted), once, many (the
--     amount stepped past both ends, then a batch) with the tab switched and the windows shut and reopened mid-craft,
--     cancelled mid-craft, Craft pressed twice in one frame; Carve Spear with the stick taken away the frame Craft is
--     pressed, then carved; a speaker taken apart for its amplifier (Electrical, by hand) and the noise maker
--     (learned + Electrical 3 + a surface: ZeD's answer must be the game's, whichever it is).
--   BUILD (Building tab; BuildingTab.lua): Build pressed on a recipe the character cannot build (no cursor), then on
--     one it can (a crate or a wall frame when the skills allow, else the first buildable): the game's build cursor,
--     cancelled before placing, started and cancelled mid-build (nothing built, nothing used), then built to the end.
--   DISMANTLE (Furniture tab; FurnitureTab.lua): a chair from the game's furniture sprites beside the character,
--     Disassemble mode from the tab's strip, the target read, the chair gone while the tab shows it, then taken apart
--     by the game's own cursor action; leaving the tab ends the cursor.
-- After each act: ZeD's row / card / target against the game's own answer (HandcraftLogic, BuildLogic, the cursor),
-- the counts carried, every ZeD window on screen, and no error from ZeD's handlers (each called through pcall).
-- Timed actions run at x20 (ZEDQA_SPEED 3); walks at x1.
-- Puts back: everything carried that was not carried at the start (given, crafted, scrap yields), new things on the
-- floor nearby, what was built and placed, the cursor, the cheats found (build, instant actions, furniture), both
-- tabs' Show / Sort / category / search / card / pins, the craft and build counts, the hands, the stats and the
-- clock, health, game speed 1, the window pair and its tab, the character home.
-- NOT put back: skill XP earned by the crafts (Carving, Electrical, Woodwork: a few points each).
-- Safety: nothing here wounds the character, but god mode is made sure ON (and left ON, as the prelude leaves it) and
-- invincible is ON for the run (put back as found). The put-back heals first, in a step of its own, and the last step
-- (it runs even when the character was found dead) prints "put back: the character is healed" PASS / FAIL.
-- Nov 21, after the first run in game:
--   * "stake, no branch" never met a missing branch: the character carries other things Make Stake takes (a handle,
--     a plunger, ...), so the craft ran on one of his own. His own inputs are now set aside for the craft acts
--     (H.stashOwn, back by H.unstash at the end of the acts and again in the put-back), so the missing case is real
--     and the crafts use only what the script gave.
--   * "batch: the amount's most" was asked 3 frames after the branches arrived; ZeD asks the game again only when
--     it gathers the containers again (CraftingTab.lua gatherDetail: at most every 1.5 s). The check now waits for
--     the two to agree (7 s) and fails only when they never do.
--   * the game's own answers are asked with the containers the game's own craft and build windows use (the floor
--     and open containers too, as ZeD since commit 49039efdf), else the two would differ over a plank on the ground.
-- Nov 21, QA review of those changes:
--   * a heal resets every stat (BodyDamage.RestoreToFullHealth calls Stats.resetStats), so the last step's heal undid
--     the stats put-back: the stats are now put back after every heal, and the last step heals only when he is hurt.
--   * the game's list is asked from the game itself (ISInventoryPaneContextMenu.getContainers), not through ZeD's
--     CC.craftContainers, so a fault in ZeD's list cannot hide in the answer it is checked against.
--   * the batch wait stays (ZeD asks again every 1.2 to 1.5 s by design), but the most must agree within 3 s, not 7.
--   * the set-aside things go back in the put-back's first step, and the carried check fails on any not given back.
--   * "stake, no branch" says SKIP when the game still finds an input in reach; Build's FAIL says SKIP for the acts
--     behind it.

if not RT then
    print("ZEDQA bx_crf ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA bx_crf VERDICT FAIL 1")
    print("ZEDQA bx_crf DONE")
    return
end

local Q = RT.make("bx_crf")
Q.maxMs = 400000
local S = { built = {}, placed = {}, had = {}, floorHad = {}, cnt = {}, stats = {} }
local H = {}
S.p, S.pn = RT.p, RT.pn
S.CC = ZeD and ZeD.CraftingCore
S.CT = ZeD and ZeD.CraftingTab
S.BT = ZeD and ZeD.BuildingTab
S.FT = ZeD and ZeD.FurnitureTab
S.WW = ZeD_WorldWindow
S.STAKE, S.SPEAR, S.PART, S.NOISE = "MakeStake", "CarveSpear", "DismantleMiscElectronics", "MakeNoiseMaker"
S.BRANCH, S.STICK = "Base.TreeBranch2", "Base.LongStick"
-- what Make Stake takes besides a knife (recipes_carving.txt, craftRecipe MakeStake)
S.STAKE_IN = { "Base.TreeBranch2", "Base.Handle", "Base.LongStick_Broken", "Base.WoodenStick2", "Base.LongHandle_Broken", "Base.LongHandle", "Base.LongStick", "Base.Plunger" }
S.stash = {}
S.RING = { { 2, 0 }, { 0, 2 }, { -2, 0 }, { 0, -2 }, { 2, 2 }, { -2, 2 }, { 2, -2 }, { -2, -2 }, { 3, 0 }, { 0, 3 }, { -3, 0 }, { 0, -3 }, { 3, 2 }, { -3, -2 } }
-- (the stats put back after a heal, which resets every stat; the ones that hurt (pain, sickness, poison, ...) stay healed)
S.STATS = { "HUNGER", "THIRST", "FATIGUE", "BOREDOM", "STRESS", "ENDURANCE", "UNHAPPINESS", "PANIC", "MORALE", "SANITY", "ANGER",
    "DISCOMFORT", "IDLENESS", "WETNESS" }
S.dead = false

if not (S.p and S.CC and S.CT and S.BT and S.FT and S.WW) then
    Q.check(false, "the player and ZeD's Crafting, Building and Furniture tabs are loaded")
    Q.start()
    return
end

-- ===================================================================== helpers
function H.speed(n) if ZEDQA_SPEED then pcall(ZEDQA_SPEED, n) else pcall(setGameSpeed, n) end end
function H.queue()
    local q = nil
    pcall(function() q = ISTimedActionQueue.getTimedActionQueue(S.p) end)
    return (q and q.queue) or {}
end
function H.qlen() return #H.queue() end
function H.head() local a = H.queue()[1]; return a and tostring(a.Type) or "none" end
function H.qcount(ty) local n = 0; for _, a in ipairs(H.queue()) do if a.Type == ty then n = n + 1 end end; return n end
function H.stop() pcall(function() ISTimedActionQueue.clear(S.p) end) end
function H.drag() local d = nil; pcall(function() d = getCell():getDrag(S.pn) end); return d end
function H.noDrag() pcall(function() if getCell():getDrag(S.pn) then getCell():setDrag(nil, S.pn) end end) end
-- time, not frames: cond asked every 100 ms (a UI update), at most ms; fn(true) when cond came true
function H.wait(ms, cond, fn)
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
-- everything carried, bags in bags too
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
function H.all() local out = {}; pcall(H.walk, S.p:getInventory(), out, 0); return out end
function H.count(ft)
    local n = 0
    for _, it in ipairs(H.all()) do if it:getFullType() == ft then n = n + 1 end end
    return n
end
function H.giveN(ft, n)
    local got = 0
    for _ = 1, n do if RT.give(ft) then got = got + 1 end end
    return got
end
function H.takeOne(it)
    pcall(function() if S.p:getPrimaryHandItem() == it then S.p:setPrimaryHandItem(nil) end end)
    pcall(function() if S.p:getSecondaryHandItem() == it then S.p:setSecondaryHandItem(nil) end end)
    pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
end
function H.takeType(ft)
    local n = 0
    for _, it in ipairs(H.all()) do
        if it:getFullType() == ft and not S.had[it] then H.takeOne(it); n = n + 1 end
    end
    return n
end
function H.md(key, name)
    local v = 0
    pcall(function() local md = S.p:getModData(); v = (md[key] and md[key][name]) or 0 end)
    return v
end
-- the tabs
function H.cst() local w = RT.ww(); return w and w._craftState end
function H.bst() local w = RT.ww(); return w and w._buildState end
function H.showing(id) local s = false; pcall(function() s = S.WW.isTabShowing(id, S.pn) end); return s and true or false end
function H.tab(id)
    if RT.worldTab(id) then return true end
    local ok = pcall(S.WW.openTab, S.pn, id)
    return ok
end
-- a recipe's row as the tab last drew it (the tab's own cache: asking gatherData from here would blank the
-- selected row's detail until the next drawn frame). nil the frame after a craft starts (the cache is dropped).
function H.data(mod)
    local w = RT.ww()
    if not w then return nil end
    if mod == S.BT then return w._buildCache end
    return w._craftCache
end
function H.row(mod, name)
    local d = H.data(mod)
    return d and d.byName and d.byName[name] or nil
end
function H.zone(st, kind, id)
    local lg = st and st._listGeo
    for _, z in ipairs((st and st.zones) or {}) do
        if z.type == kind and (id == nil or z.id == id) and z.w > 0 and z.h > 0 then
            local inView = kind ~= "recipeRow" or lg == nil or (z.y >= lg.viewY and z.y + z.h <= lg.viewY + lg.viewH)
            if inView then return z end
        end
    end
    return nil
end
function H.click(mod, z, what, right)
    local fn = right and mod.onRightClick or mod.onClick
    local ok, err = pcall(fn, RT.ww(), z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
    if not ok then Q.check(false, what .. ": the click ran without an error", err) end
    return ok
end
function H.press(mod, st, kind, what)
    local z = H.zone(st, kind)
    if not z then return false end
    return H.click(mod, z, what)
end
-- a recipe's card opened as a click on its row does; from code when the row is out of view (said)
function H.open(mod, st, name, what)
    if not st then return false end
    if st.selected == name then return true end
    local z = H.zone(st, "recipeRow", name)
    if z then
        H.click(mod, z, what)
    else
        local ok, err = pcall(S.CC.openCraft, st, name)
        if not ok then Q.check(false, what .. ": the card opened without an error", err) end
        Q.say("note " .. what .. ": " .. name .. " has no row in view, its card is opened from code")
    end
    return st.selected == name
end
-- the containers the game's own craft and build windows use (ISHandCraftPanel, ISBuildPanel: the inventory, the bags,
-- the floor and the open loot containers), asked from the game itself, not through ZeD's CC.craftContainers (the code
-- under test); the carried list only when the game's inventory pages cannot be read
function H.conts()
    local list = nil
    pcall(function()
        if getPlayerInventory(S.pn) ~= nil and getPlayerLoot(S.pn) ~= nil then
            local l = ISInventoryPaneContextMenu.getContainers(S.p)
            if l and l:size() > 0 then list = l end
        end
    end)
    return list or S.CC.buildContainers(S.p)
end
-- what of these types the game's containers hold, and where ("" when none)
function H.inReach(types)
    local want, out = {}, {}
    for _, ft in ipairs(types) do want[ft] = true end
    pcall(function()
        local cs = H.conts()
        for i = 0, cs:size() - 1 do
            local c = cs:get(i)
            local items = c:getItems()
            for j = 0, items:size() - 1 do
                local ft = items:get(j):getFullType()
                if want[ft] then out[#out + 1] = ft .. " in " .. tostring(c:getType()) end
            end
        end
    end)
    return table.concat(out, ", ")
end
-- the character's own things Make Stake takes, set aside for the craft acts (not one worn, held or on the belt)
function H.stashOwn()
    local want, kept = {}, 0
    for _, ft in ipairs(S.STAKE_IN) do want[ft] = true end
    for _, it in ipairs(H.all()) do
        if want[it:getFullType()] then
            local c, free = nil, false
            pcall(function() c = it:getContainer(); free = it:getAttachedSlot() == -1 and not it:isEquipped() end)
            if c and free and pcall(function() c:Remove(it) end) then
                S.stash[#S.stash + 1] = { it = it, c = c }
            else
                kept = kept + 1
            end
        end
    end
    return #S.stash, kept
end
-- ... and given back to the containers they were in. Returns how many could not be.
function H.unstash()
    local lost = 0
    for _, s in ipairs(S.stash) do
        pcall(function() if s.it:getContainer() == nil then s.c:AddItem(s.it) end end)
        local back = false
        pcall(function() back = s.it:getContainer() ~= nil end)
        if not back then lost = lost + 1 end
    end
    S.stash = {}
    return lost
end
-- health: what is wrong with the character ("" when healed: alive, health 100, no wound, fracture or infection)
function H.hurt()
    local bad = {}
    local dead = true
    pcall(function() dead = S.p:isDead() and true or false end)
    if dead then bad[#bad + 1] = "dead" end
    local ok = pcall(function()
        local bd = S.p:getBodyDamage()
        local h = bd:getOverallBodyHealth()
        if h < 99.9 then bad[#bad + 1] = "health " .. tostring(h) end
        if bd:IsInfected() or bd:isInfected() then bad[#bad + 1] = "infected" end
        local parts = bd:getBodyParts()
        for i = 0, parts:size() - 1 do
            local bp = parts:get(i)
            local nm = "part " .. i
            pcall(function() nm = tostring(bp:getType()) end)
            if bp:getFractureTime() > 0 then bad[#bad + 1] = "fracture on " .. nm end
            if bp:HasInjury() or bp:bleeding() or bp:bitten() or bp:scratched() or bp:deepWounded() or bp:isCut()
                or bp:isBurnt() or bp:haveBullet() or bp:haveGlass() or bp:IsInfected() then
                bad[#bad + 1] = "wound on " .. nm
            end
        end
    end)
    if not ok then bad[#bad + 1] = "the body could not be read" end
    return table.concat(bad, ", ")
end
-- (RestoreToFullHealth also calls Stats.resetStats, every stat to its default: put the stats back after it, H.putStats)
function H.heal()
    local dead = true
    pcall(function() dead = S.p:isDead() and true or false end)
    if dead then return end
    pcall(function() S.p:getBodyDamage():RestoreToFullHealth() end)
    pcall(function()
        local bd = S.p:getBodyDamage()
        if bd:IsInfected() or bd:isInfected() then bd:setInfected(false); bd:setIsFakeInfected(false) end
    end)
end
-- the stats as they were at the start (hunger, thirst, fatigue, ...: S.STATS)
function H.putStats()
    pcall(function()
        local stt = S.p:getStats()
        for k, v in pairs(S.stats) do pcall(function() stt:set(CharacterStat[k], v) end) end
    end)
end
-- the game's own answer for a hand recipe with what is carried (nil: it would not answer)
function H.gameCan(name)
    local can = nil
    pcall(function()
        local sm = getScriptManager()
        local r = sm:getCraftRecipe(name) or sm:getCraftRecipe("Base." .. name)
        local surf = nil
        pcall(function() if r:isAnySurfaceCraft() then surf = ISEntityUI.FindCraftSurface(S.p, 2) end end)
        local l = HandcraftLogic.new(S.p, nil, surf)
        l:setContainers(H.conts())
        l:setRecipe(r)
        can = l:canPerformCurrentRecipe() and true or false
    end)
    return can
end
function H.gameMost(name)
    local most = nil
    pcall(function()
        local sm = getScriptManager()
        local r = sm:getCraftRecipe(name) or sm:getCraftRecipe("Base." .. name)
        local l = HandcraftLogic.new(S.p, nil, nil)
        l:setContainers(H.conts())
        l:setRecipe(r)
        most = l:getPossibleCraftCount(true)
    end)
    return most
end
function H.gameCanBuild(rd)
    local can = nil
    pcall(function()
        local l = BuildLogic.new(S.p, nil, nil)
        l:setRecipe(rd.entry.recipe)
        l:setContainers(H.conts())
        can = l:canPerformCurrentRecipe() and true or false
    end)
    return can
end
function H.zedCan(rd) return (rd ~= nil and rd.status == "craftable" and rd.canStart ~= false) and true or false end
function H.settled(rd) return rd ~= nil and rd.status ~= "unlocked" end
-- ZeD's row against the game: a locked row must be one the game holds back (not learned or short of skill),
-- any other row must say craftable exactly when the game would start the craft
function H.agree(rd, name, label)
    if not rd then return Q.check(false, label .. ": the recipe has a row", name) end
    if rd.status == "locked" then
        local known, skilled = true, true
        pcall(function() if rd.entry.needLearn then known = S.p:isRecipeKnown(rd.entry.recipe) and true or false end end)
        pcall(function() skilled = rd.entry.recipe:characterHasRequiredSkills(S.p) and true or false end)
        return Q.check(not known or not skilled, label .. ": a locked row is one the game holds back (not learned or short of skill)",
            "known " .. tostring(known) .. ", skilled " .. tostring(skilled))
    end
    local g = H.gameCan(name)
    if g == nil then Q.skip(label .. ": the row matches the game", "the game's crafting logic gave no answer"); return true end
    return Q.check(H.zedCan(rd) == g, label .. ": the row says craftable exactly when the game would start it",
        "ZeD " .. tostring(rd.status) .. " / canStart " .. tostring(rd.canStart) .. ", the game " .. tostring(g))
end

-- ===================================================================== a craft, start to end
-- spec: name, label, give {fullType...}, out (the full type made), must (true: it has to be craftable once given),
-- missing (the recipe's input types: the act is the input missing, said as a SKIP when the game still finds one)
function H.make(spec)
    local T = {}
    Q.step(3, function()
        if S.dead or not S.craftOk then return end
        for _, ft in ipairs(spec.give or {}) do RT.give(ft) end
        T.open = H.row(S.CT, spec.name) ~= nil and H.open(S.CT, H.cst(), spec.name, spec.label)
        T.outWas, T.cntWas = H.count(spec.out), H.md("ZeD_CraftCounts", spec.name)
    end)
    H.wait(7000, function()
        if not T.open then return true end
        local rd = H.row(S.CT, spec.name)
        if not H.settled(rd) or not H.zone(H.cst(), "action_build") then return false end
        return (not spec.must) or H.zedCan(rd)
    end, function()
        if S.dead or not S.craftOk then return end
        local rd = H.row(S.CT, spec.name)
        if not (T.open and rd) then Q.skip(spec.label, "the Crafting tab does not list " .. spec.name .. " for this character"); return end
        T.run = true
        H.agree(rd, spec.name, spec.label)
        if spec.must then Q.check(H.zedCan(rd), spec.label .. ": with the ingredients given the recipe is craftable", tostring(rd.status)) end
        T.go = H.gameCan(spec.name) == true
        if spec.missing and T.go then
            local where = H.inReach(spec.missing)
            Q.skip(spec.label .. ": Craft with the input missing", "the game still finds one in reach: "
                .. (where ~= "" and where or "none of the recipe's inputs seen in the game's containers"))
        end
        H.speed(3)
        if not H.press(S.CT, H.cst(), "action_build", spec.label) then Q.check(false, spec.label .. ": the card's Craft button is drawn") end
        T.queued = H.qcount("ISHandcraftAction")
    end)
    Q.waitMs(500)
    H.wait(30000, function() return not T.run or (H.qlen() == 0 and (not T.go or H.count(spec.out) > T.outWas)) end, function(ok)
        H.speed(1)
        if not T.run then return end
        local made, cnt = H.count(spec.out) - T.outWas, H.md("ZeD_CraftCounts", spec.name) - T.cntWas
        if T.go then
            Q.check(ok and made == 1, spec.label .. ": Craft makes one " .. spec.out, "made " .. made .. ", queued " .. tostring(T.queued) .. ", queue now " .. H.head())
            Q.check(cnt == 1, spec.label .. ": the craft is counted once", cnt)
        else
            Q.check(T.queued == 0 and made == 0, spec.label .. ": Craft on a recipe the game refuses queues and makes nothing",
                "queued " .. tostring(T.queued) .. ", made " .. made)
            Q.check(cnt == 0, spec.label .. ": a refused craft is not counted", cnt)
        end
        if H.qlen() > 0 then H.stop() end
        RT.bounds(Q, spec.label)
    end)
    H.wait(6000, function()
        if not T.run then return true end
        local rd = H.row(S.CT, spec.name)
        return H.settled(rd) and (rd.status == "locked" or H.zedCan(rd) == H.gameCan(spec.name))
    end, function()
        if not T.run then return end
        H.agree(H.row(S.CT, spec.name), spec.name, spec.label .. ", after")
        local st = H.cst()
        Q.check(st ~= nil and st.selected == spec.name, spec.label .. ": the card stays on its recipe after the craft", tostring(st and st.selected))
    end)
end

-- ===================================================================== setup
function H.snapFloor(set)
    local cx, cy = math.floor(S.p:getX()), math.floor(S.p:getY())
    for y = cy - 6, cy + 6 do
        for x = cx - 6, cx + 6 do
            local sq = getCell():getGridSquare(x, y, 0)
            local wos = sq and sq:getWorldObjects()
            for i = 0, (wos and wos:size() or 0) - 1 do set[wos:get(i)] = true end
        end
    end
end
function H.keepState(st)
    return { show = st.show, showAll = st.showAll, sort = st.sort, cat = st.activeCat }
end
function H.putState(st, k)
    if not (st and k) then return end
    pcall(function() if st.selected then S.CC.closeCraft(st) end end)
    st.show, st.showAll, st.sort, st.activeCat = k.show, k.showAll, k.sort, k.cat
    st.search, st.qty, st.filterDirty = "", 1, true
    st.sortMenuOpen, st.showMenuOpen, st.catDropdownOpen = false, false, false
end
Q.step(2, function()
    S.dead = S.p:isDead() and true or false
    if S.dead then Q.check(false, "the character is alive (nothing is run on a dead one)"); return end
    if ZEDQA_HOME then ZEDQA_HOME("bx_crf") end
    H.speed(1)
    H.stop()
    H.noDrag()
    S.types = {}
    for _, it in ipairs(H.all()) do
        S.had[it] = true
        local ft = it:getFullType()
        S.types[ft] = (S.types[ft] or 0) + 1
    end
    H.snapFloor(S.floorHad)
    S.handWas = { S.p:getPrimaryHandItem(), S.p:getSecondaryHandItem() }
    local stt = S.p:getStats()
    for _, k in ipairs(S.STATS) do pcall(function() S.stats[k] = stt:get(CharacterStat[k]) end) end
    pcall(function() S.tod = getGameTime():getTimeOfDay() end)
    -- (nothing here wounds, but nothing may: god mode ON and left ON, invincible ON until the put-back)
    pcall(function() if not S.p:isGodMod() then S.p:setGodMod(true); Q.say("note god mode was off: turned on and left on") end end)
    pcall(function() S.invWas = S.p:isInvincible() and true or false; S.p:setInvincible(true) end)
    pcall(function() S.instWas = S.p:isTimedActionInstantCheat(); S.p:setTimedActionInstantCheat(false) end)
    pcall(function() S.bcWas = S.p:isBuildCheat(); S.p:setBuildCheat(false) end)
    pcall(function() S.bmWas = ISBuildMenu.cheat; ISBuildMenu.cheat = false end)
    pcall(function() S.mdWas = ISMoveableDefinitions.cheat; ISMoveableDefinitions.cheat = false end)
    local md = S.p:getModData()
    for _, key in ipairs({ "ZeD_CraftCounts", "ZeD_BuildCounts", "ZeD_CraftPins", "ZeD_BuildPins" }) do
        if md[key] then
            local copy = {}
            for k, v in pairs(md[key]) do copy[k] = v end
            S.cnt[key] = copy
        end
    end
    S.pairWas = RT.isOpen()
    RT.pairOpen()
    pcall(function()
        local cur = ZeD.Stations and ZeD.Stations.current(S.p)
        if cur then ZeD.Stations.unbind(S.p); Q.say("note a station was bound: unbound for the run (the hand's recipes)") end
    end)
    local aside, kept = H.stashOwn()
    Q.say("note " .. aside .. " of the character's own things Make Stake takes are set aside for the craft acts"
        .. (kept > 0 and (", " .. kept .. " worn, held or on the belt stay (the no-branch craft may then run on one)") or ""))
    S.knife = RT.give("Base.HuntingKnife")
    Q.check(S.knife ~= nil, "a hunting knife is given (no branch yet)")
end)
Q.step(15, function()
    if S.dead then return end
    local w = RT.ww()
    S.tabWas = w and w._activeTab
    H.tab("craft")
end)
H.wait(8000, function() return S.dead or (H.showing("craft") and H.cst() ~= nil and H.zone(H.cst(), "recipeRow") ~= nil) end, function(ok)
    if S.dead then return end
    S.craftOk = Q.check(ok, "the World window's Crafting tab opens with recipe rows", tostring(H.showing("craft")))
    local st = H.cst()
    if not (S.craftOk and st) then S.craftOk = false; return end
    S.cKeep = H.keepState(st)
    pcall(S.CC.setShow, st, "all")
    RT.bounds(Q, "the Crafting tab")
end)

-- ===================================================================== the search field
function H.typeSearch(field, text)
    local ok, err = pcall(function() field.input:setText(text) end)
    if not ok then Q.check(false, "the search field takes typed text", err) end
    return ok
end
function H.inFiltered(st, name)
    for _, rd in ipairs((st and st.filteredCache) or {}) do if rd.entry.name == name then return true end end
    return false
end
Q.step(5, function()
    if not S.craftOk then return end
    local w = RT.ww()
    S.rowsAll = #((H.cst() and H.cst().filteredCache) or {})
    S.typed = w and w._craftSearch and H.typeSearch(w._craftSearch, "zzqxj")
end)
H.wait(3000, function() return not S.typed or (H.cst().search == "zzqxj" and H.cst().filterDirty == false) end, function(ok)
    if not S.craftOk then return end
    if not S.typed then Q.skip("search: nothing found", "the Crafting tab has no search field"); return end
    local st = H.cst()
    Q.check(ok and #(st.filteredCache or {}) == 0 and H.zone(st, "recipeRow") == nil, "search: text no recipe has leaves an empty list",
        tostring(st.search) .. ": " .. #(st.filteredCache or {}) .. " rows of " .. tostring(S.rowsAll))
    Q.check(st.selected == nil, "search: no card is open over the empty list", tostring(st.selected))
    local rd = H.row(S.CT, S.STAKE)
    S.stakeWord = rd and string.lower(tostring(rd.entry.displayName)) or "stake"
    H.typeSearch(RT.ww()._craftSearch, S.stakeWord)
end)
H.wait(3000, function() return not S.typed or (H.cst().search == S.stakeWord and H.inFiltered(H.cst(), S.STAKE)) end, function(ok)
    if not (S.craftOk and S.typed) then return end
    local st = H.cst()
    local n = #(st.filteredCache or {})
    Q.check(ok, "search: the stake's own name finds Make Stake", tostring(S.stakeWord) .. ": " .. n .. " rows")
    Q.check(n >= 1 and n < (S.rowsAll or 0), "search: the list is narrowed (fewer rows than everything)", n .. " of " .. tostring(S.rowsAll))
end)
-- the row: a click opens the card, five more leave it open, Escape shuts it, the pin by right-click, the Sort list
-- (Nov 25 2026, KISS #47: a second click on the open row no longer shuts its card, so a double-click does not shut
-- what the first click opened; another row or Escape closes it, CraftingCore.handleRecipeClick and CC.takeEscape.
-- This check expected the old toggle, open, shut, ..., and failed on the current code. Neither a click on an empty
-- spot nor the pad's B shuts the card in the current code: Escape is the shut checked here.)
H.wait(3000, function() return not S.craftOk or H.zone(H.cst(), "recipeRow", S.STAKE) ~= nil end, function(ok)
    if not S.craftOk then return end
    local st = H.cst()
    local z = H.zone(st, "recipeRow", S.STAKE)
    if not z then Q.skip("row: clicks on the open row keep the card", "Make Stake has no row in view"); S.rowOpen = false; return end
    H.click(S.CT, z, "row")
    Q.check(st.selected == S.STAKE and st.splitTarget == 1, "row: a click on Make Stake opens its card", tostring(st.selected))
    for _ = 1, 5 do H.click(S.CT, z, "row") end
    S.rowOpen = Q.check(st.selected == S.STAKE and st.splitTarget == 1, "row: five more clicks on the same spot leave the card open (KISS #47)", tostring(st.selected))
end)
-- (Escape takes the card only once it has been drawn open: CC.takeEscape asks for a draw in the last half second)
Q.step(6, function()
    if not (S.craftOk and S.rowOpen) then return end
    local st = H.cst()
    local okE, took = pcall(S.CC.takeEscape)
    Q.check(okE and took == true and st.selected == nil and st.splitTarget == 0, "row: Escape shuts the open card (KISS #47, CC.takeEscape)",
        "taken " .. tostring(took) .. ", the card " .. tostring(st.selected))
    if st.selected then pcall(S.CC.closeCraft, st) end
end)
H.wait(3000, function() return not S.craftOk or (H.cst().splitFrac or 0) <= 0.01 and H.zone(H.cst(), "recipeRow", S.STAKE) ~= nil end, function()
    if not S.craftOk then return end
    local st = H.cst()
    local z = H.zone(st, "recipeRow", S.STAKE)
    if not z then Q.skip("pin: a right-click on the row", "Make Stake has no row in view"); return end
    local w = RT.ww()
    local was = S.CC.isPinned(w, S.STAKE, "_craftPins")
    H.click(S.CT, z, "pin", true)
    local now = S.CC.isPinned(w, S.STAKE, "_craftPins")
    local saved = false
    for _, nm in ipairs(S.p:getModData().ZeD_CraftPins or {}) do if nm == S.STAKE then saved = true end end
    Q.check(now ~= was and saved == now, "pin: a right-click on the row pins (or unpins) it and saves it with the character",
        "was " .. tostring(was) .. ", now " .. tostring(now) .. ", saved " .. tostring(saved))
end)
Q.step(6, function()
    if not S.craftOk then return end
    local st, w = H.cst(), RT.ww()
    -- (the pin back: the row may have moved to the Pinned section, so from code)
    pcall(function() if S.CC.isPinned(w, S.STAKE, "_craftPins") then S.CC.togglePin(w, S.STAKE, "ZeD_CraftPins", "_craftPins", "filterDirty"); st.filterDirty = true end end)
    if H.press(S.CT, st, "sortMenu", "Sort") then
        Q.check(st.sortMenuOpen == true, "Sort: a click on the band's Sort opens its list", tostring(st.sortMenuOpen))
        S.sortOpen = true
    else
        Q.skip("Sort: its list opens and shuts", "the band draws no Sort box here")
    end
end)
Q.step(6, function()
    if not (S.craftOk and S.sortOpen) then return end
    local st = H.cst()
    RT.bounds(Q, "the Sort list open")
    local ok, err = pcall(S.CT.onClick, RT.ww(), 1, 1)
    Q.check(ok and st.sortMenuOpen == false and st.selected == nil, "Sort: a click away shuts the list and does nothing else",
        ok and (tostring(st.sortMenuOpen) .. " / " .. tostring(st.selected)) or err)
end)
-- the search emptied as a player does (the field's text deleted): the whole list is back
Q.step(3, function()
    if not (S.craftOk and S.typed) then return end
    H.typeSearch(RT.ww()._craftSearch, "")
end)
H.wait(3000, function() return not (S.craftOk and S.typed) or (H.cst().search == "" and H.cst().filterDirty == false and H.row(S.CT, S.STAKE) ~= nil) end, function(ok)
    if not (S.craftOk and S.typed) then return end
    local st = H.cst()
    local n = #(st.filteredCache or {})
    Q.check(ok and n == S.rowsAll, "search: emptied, the whole list is back", n .. " of " .. tostring(S.rowsAll))
    if st.search ~= "" then st.search, st.filterDirty = "", true end
end)

-- ===================================================================== whittle: the stake, missing then once
H.make({ name = S.STAKE, label = "stake, no branch", out = "Base.Stake", must = false, missing = S.STAKE_IN })
H.make({ name = S.STAKE, label = "stake, one branch", give = { S.BRANCH }, out = "Base.Stake", must = true })

-- ===================================================================== many: the amount's ends, a batch, tabs and windows mid-craft
Q.step(3, function()
    if not S.craftOk then return end
    S.m = { got = H.giveN(S.BRANCH, 4), stakes = H.count("Base.Stake"), cnt = H.md("ZeD_CraftCounts", S.STAKE), t0 = getTimestampMs() }
    S.m.open = H.open(S.CT, H.cst(), S.STAKE, "batch")
end)
-- (ZeD asks the game for the amount's most again when the row's answer changes, at each list scan (every 1.2 s) and
-- each container gather (every 1.5 s): the wait is for the row craftable AND the most caught up with the branches
-- just given, and the check wants that within 3 s, twice ZeD's own interval)
H.wait(7000, function()
    if not (S.m and S.m.open) then return true end
    local rd = H.row(S.CT, S.STAKE)
    if not (H.zedCan(rd) and H.zone(H.cst(), "action_build") ~= nil) then return false end
    if not rd.entry.allowBatch then return true end
    local g = H.gameMost(S.STAKE)
    if g ~= nil and g ~= (rd.maxBatchQty or 1) then return false end
    S.m.inMs = getTimestampMs() - S.m.t0
    return true
end, function()
    if not (S.craftOk and S.m and S.m.open) then return end
    local st, rd = H.cst(), H.row(S.CT, S.STAKE)
    local can = H.zedCan(rd) and H.zone(st, "action_build") ~= nil
    if not Q.check(can, "batch: with four branches Make Stake is craftable", tostring(rd and rd.status)) then S.m.open = false; return end
    local max = rd.maxBatchQty or 1
    if rd.entry.allowBatch then
        local g = H.gameMost(S.STAKE)
        if g == nil then
            Q.skip("batch: the amount's most is the game's own count", "the game's crafting logic gave no count")
        else
            Q.check(g == max and S.m.inMs ~= nil and S.m.inMs <= 3000,
                "batch: the amount's most is the game's own count within 3 s of the branches arriving (ZeD asks again every 1.2 to 1.5 s)",
                "ZeD " .. tostring(max) .. ", the game " .. tostring(g) .. ", branches " .. H.count(S.BRANCH) .. ", agreed after "
                .. (S.m.inMs and (S.m.inMs .. " ms") or "more than 7 s"))
        end
    end
    if H.zone(st, "action_inc") and H.zone(st, "action_dec") then
        for _ = 1, 12 do H.press(S.CT, st, "action_inc", "amount +") end
        Q.check(st.qty == math.max(1, math.min(max, 13)), "batch: + pressed twelve times stops at the most", st.qty .. " of " .. max)
        for _ = 1, 20 do H.press(S.CT, st, "action_dec", "amount -") end
        Q.check(st.qty == 1, "batch: - pressed twenty times stops at 1", st.qty)
        S.m.want = math.max(1, math.min(3, max))
        for _ = 2, S.m.want do H.press(S.CT, st, "action_inc", "amount +") end
        Q.check(st.qty == S.m.want, "batch: the amount reads what was stepped to", st.qty .. " / " .. S.m.want)
    else
        S.m.want = 1
        Q.skip("batch: the amount's + and -", "the band draws no stepper for this recipe")
    end
    H.speed(3)
    H.press(S.CT, st, "action_build", "batch")
    S.m.queued = H.qcount("ISHandcraftAction")
    Q.check(S.m.queued == S.m.want and st.qty == 1, "batch: Craft queues one action per stake and the amount goes back to 1",
        "queued " .. S.m.queued .. " of " .. S.m.want .. ", amount " .. tostring(st.qty))
    S.m.run = true
end)
Q.step(2, function() if S.m and S.m.run then H.tab("build") end end)
Q.step(4, function() if S.m and S.m.run then H.tab("loot") end end)
Q.step(4, function() if S.m and S.m.run then RT.pairShut() end end)
Q.waitMs(400)
Q.step(1, function() if S.m and S.m.run then RT.pairOpen() end end)
Q.step(12, function() if S.m and S.m.run then H.tab("craft") end end)
H.wait(45000, function() return not (S.m and S.m.run) or (H.qlen() == 0 and H.showing("craft") and H.data(S.CT) ~= nil) end, function(ok)
    H.speed(1)
    if not (S.m and S.m.run) then return end
    local made = H.count("Base.Stake") - S.m.stakes
    Q.check(made == S.m.want, "batch: the queued crafts run on through a tab switch and the windows shut and reopened", "made " .. made .. " of " .. S.m.want)
    Q.check(H.md("ZeD_CraftCounts", S.STAKE) - S.m.cnt == 1, "batch: one press is counted once", H.md("ZeD_CraftCounts", S.STAKE) - S.m.cnt)
    local st = H.cst()
    Q.check(ok and st ~= nil and (st.selected == nil or H.row(S.CT, st.selected) ~= nil), "batch: the Crafting tab is back with a card that still has its recipe",
        tostring(H.showing("craft")) .. " / " .. tostring(st and st.selected))
    if H.qlen() > 0 then H.stop() end
    RT.bounds(Q, "the Crafting tab after the batch")
end)

-- ===================================================================== cancel mid-craft, then Craft twice in one frame
Q.step(3, function()
    if not S.craftOk then return end
    S.c = {}
    if H.count(S.BRANCH) < 2 then H.giveN(S.BRANCH, 2) end
    S.c.open = H.open(S.CT, H.cst(), S.STAKE, "cancel")
end)
H.wait(7000, function() return not (S.c and S.c.open) or (H.zedCan(H.row(S.CT, S.STAKE)) and H.zone(H.cst(), "action_build") ~= nil) end, function(ok)
    if not (S.c and S.c.open) then return end
    if not ok then Q.skip("cancel: a craft stopped mid-way", "Make Stake did not turn craftable"); S.c.open = false; return end
    S.c.stakes, S.c.branches = H.count("Base.Stake"), H.count(S.BRANCH)
    H.speed(1)
    H.press(S.CT, H.cst(), "action_build", "cancel")
end)
H.wait(4000, function() return not (S.c and S.c.open) or H.head() == "ISHandcraftAction" end, function(ok)
    if not (S.c and S.c.open) then return end
    S.c.started = Q.check(ok, "cancel: the craft is running", H.head())
end)
Q.waitMs(350)
Q.step(1, function() if S.c and S.c.started then H.stop() end end)
Q.waitMs(700)
H.wait(6000, function() return not (S.c and S.c.started) or H.zedCan(H.row(S.CT, S.STAKE)) == H.gameCan(S.STAKE) end, function()
    if not (S.c and S.c.started) then return end
    Q.check(H.qlen() == 0 and H.count("Base.Stake") == S.c.stakes and H.count(S.BRANCH) == S.c.branches,
        "cancel: a craft stopped mid-way makes nothing and uses nothing",
        "stakes " .. H.count("Base.Stake") .. "/" .. S.c.stakes .. ", branches " .. H.count(S.BRANCH) .. "/" .. S.c.branches .. ", queue " .. H.head())
    H.agree(H.row(S.CT, S.STAKE), S.STAKE, "cancel")
    local st = H.cst()
    Q.check(st.selected == S.STAKE and H.zone(st, "action_build") ~= nil, "cancel: the card and its Craft button are still there", tostring(st.selected))
    -- twice in one frame (a double click)
    S.c.left, S.c.stakes = H.count(S.BRANCH), H.count("Base.Stake")
    H.speed(3)
    H.press(S.CT, st, "action_build", "double press")
    H.press(S.CT, st, "action_build", "double press")
    S.c.twice = true
end)
Q.waitMs(500)
H.wait(40000, function() return not (S.c and S.c.twice) or H.qlen() == 0 end, function(ok)
    H.speed(1)
    if not (S.c and S.c.twice) then return end
    local made, want = H.count("Base.Stake") - S.c.stakes, math.min(2, S.c.left)
    Q.check(ok and made == want, "double press: Craft pressed twice in one frame makes one stake per branch there was, no more",
        "made " .. made .. ", branches there were " .. S.c.left)
    if H.qlen() > 0 then H.stop() end
end)

-- ===================================================================== the stick gone the frame Craft is pressed, then the spear
Q.step(3, function()
    if not S.craftOk then return end
    S.v = { stick = RT.give(S.STICK) }
    S.v.open = S.v.stick ~= nil and H.open(S.CT, H.cst(), S.SPEAR, "vanish")
end)
H.wait(7000, function() return not (S.v and S.v.open) or (H.zedCan(H.row(S.CT, S.SPEAR)) and H.zone(H.cst(), "action_build") ~= nil) end, function(ok)
    if not (S.craftOk and S.v) then return end
    if not (S.v.open and ok) then Q.skip("vanish: the stick taken as Craft is pressed", "Carve Spear did not open craftable"); S.v.open = false; return end
    H.takeOne(S.v.stick)
    if H.gameCan(S.SPEAR) ~= false then
        Q.skip("vanish: the stick taken as Craft is pressed", "the character carries another stick the recipe takes")
        S.v.open = false
        return
    end
    S.v.spears, S.v.cnt = H.count("Base.SpearCrafted"), H.md("ZeD_CraftCounts", S.SPEAR)
    H.speed(3)
    H.press(S.CT, H.cst(), "action_build", "vanish")
    S.v.queued = H.qcount("ISHandcraftAction")
end)
Q.waitMs(600)
H.wait(20000, function()
    if not (S.v and S.v.open) then return true end
    local rd = H.row(S.CT, S.SPEAR)
    return H.qlen() == 0 and rd ~= nil and not H.zedCan(rd)
end, function(ok)
    H.speed(1)
    if not (S.v and S.v.open) then return end
    Q.check(S.v.queued == 0 and H.count("Base.SpearCrafted") == S.v.spears and H.md("ZeD_CraftCounts", S.SPEAR) == S.v.cnt,
        "vanish: Craft pressed the frame its stick was taken queues, makes and counts nothing",
        "queued " .. tostring(S.v.queued) .. ", spears " .. H.count("Base.SpearCrafted") .. "/" .. S.v.spears)
    local rd, st = H.row(S.CT, S.SPEAR), H.cst()
    Q.check(ok and rd ~= nil and not H.zedCan(rd), "vanish: the row stops saying craftable once the stick is gone (nothing stale)", tostring(rd and rd.status))
    Q.check(st.selected == S.SPEAR and rd ~= nil and (rd.missingCount or 0) >= 1, "vanish: the open card stays and counts the stick missing",
        tostring(st.selected) .. ", missing " .. tostring(rd and rd.missingCount))
    if H.qlen() > 0 then H.stop() end
end)
H.make({ name = S.SPEAR, label = "spear", give = { S.STICK }, out = "Base.SpearCrafted", must = true })

-- ===================================================================== tinker: a part by hand, then the noise maker
H.make({ name = S.PART, label = "speaker apart", give = { "Base.Screwdriver", "Base.Speaker" }, out = "Base.Amplifier", must = true })
Q.step(2, function() if S.craftOk then H.giveN("Base.ElectronicsScrap", 7) end end)
H.make({ name = S.NOISE, label = "noise maker", give = { "Base.Amplifier", "Base.Pliers" }, out = "Base.NoiseTrap", must = false })
Q.step(3, function()
    if not S.craftOk then return end
    local st = H.cst()
    pcall(function() RT.ww()._craftSearch:clear() end)
    H.putState(st, S.cKeep)
    S.cKeep = nil
end)
-- the character's own stake inputs back where they were (the craft acts are over; again in the put-back if this did not run)
Q.step(2, function()
    if #S.stash == 0 then return end
    H.stop()
    S.stashLost = (S.stashLost or 0) + H.unstash()
end)

-- ===================================================================== the Building tab
function H.snapObjs(cx, cy, r)
    local set = {}
    for y = cy - r, cy + r do
        for x = cx - r, cx + r do
            local sq = getCell():getGridSquare(x, y, 0)
            local objs = sq and sq:getObjects()
            for i = 0, (objs and objs:size() or 0) - 1 do set[objs:get(i)] = true end
        end
    end
    return set
end
function H.newObjs(before, cx, cy, r)
    local out = {}
    for o in pairs(H.snapObjs(cx, cy, r)) do if not before[o] then out[#out + 1] = o end end
    return out
end
function H.removeObj(obj)
    local sq = nil
    pcall(function() sq = obj:getSquare() end)
    if not sq then return end
    pcall(function() sq:transmitRemoveItemFromSquare(obj) end)
    pcall(function() if obj:getObjectIndex() >= 0 then sq:RemoveTileObject(obj) end end)
end
function H.freeSq(dx, dy)
    local sq = getCell():getGridSquare(math.floor(S.p:getX()) + dx, math.floor(S.p:getY()) + dy, 0)
    local good = false
    pcall(function()
        good = sq ~= nil and sq:getFloor() ~= nil and sq:isFree(false) and not sq:HasTree()
            and sq:getObjects():size() <= 1 and sq:getWorldObjects():size() == 0 and sq:getVehicleContainer() == nil
    end)
    return good and sq or nil
end
-- a tile the game's build cursor takes
function H.buildSq(cur)
    for _, d in ipairs(S.RING) do
        local sq = H.freeSq(d[1], d[2])
        local ok, v = false, false
        if sq then ok, v = pcall(cur.isValid, cur, sq) end
        if ok and v then return sq end
    end
    return nil
end
-- the recipe to build (a crate, a wall frame, else the first buildable that is no floor, stairs or roof) and one the
-- character cannot build
function H.pickBuild()
    local d = H.data(S.BT)
    local can, crate, frame, miss, lock = nil, nil, nil, nil, nil
    for _, rd in ipairs((d and d.recipes) or {}) do
        local nm = string.lower(tostring(rd.entry and rd.entry.displayName or "") .. " " .. tostring(rd.entry and rd.entry.name or ""))
        if rd.status == "craftable" then
            local odd = nm:find("floor", 1, true) or nm:find("stair", 1, true) or nm:find("roof", 1, true)
            if not odd then
                can = can or rd
                if not crate and nm:find("crate", 1, true) then crate = rd end
                if not frame and nm:find("frame", 1, true) then frame = rd end
            end
        elseif rd.status == "missing" then
            miss = miss or rd
        elseif rd.status == "locked" then
            lock = lock or rd
        end
    end
    local pick = crate or frame or can
    return pick and pick.entry.name, miss and miss.entry.name, lock and lock.entry.name
end
function H.bPress(label)
    local st = H.bst()
    local z = H.zone(st, "action_build")
    if not z then return false end
    local ok, err = pcall(S.BT.onClick, RT.ww(), z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
    if not ok then Q.check(false, label .. ": the Build button ran without an error", err) end
    return ok
end
Q.step(3, function()
    if S.dead then return end
    RT.give("Base.Hammer"); RT.give("Base.Saw")
    S.b = { planks = H.giveN("Base.Plank", 8), nails = H.giveN("Base.Nails", 8) }
    H.tab("build")
end)
H.wait(8000, function() return S.dead or (H.showing("build") and H.bst() ~= nil and H.bst().filteredCache ~= nil) end, function(ok)
    if S.dead then return end
    S.buildOk = Q.check(ok, "the World window's Building tab opens", tostring(H.showing("build")))
    if not S.buildOk then return end
    S.bKeep = H.keepState(H.bst())
    pcall(S.CC.setShow, H.bst(), "all")
    S.b.t0 = getTimestampMs()
    RT.bounds(Q, "the Building tab")
end)
H.wait(9000, function()
    if not S.buildOk then return true end
    local pick, miss = H.pickBuild()
    return (pick ~= nil and miss ~= nil) or getTimestampMs() - S.b.t0 > 5000
end, function()
    if not S.buildOk then return end
    S.b.pick, S.b.miss, S.b.lock = H.pickBuild()
    Q.say("build: to build " .. tostring(S.b.pick) .. ", missing materials " .. tostring(S.b.miss) .. ", locked " .. tostring(S.b.lock)
        .. " (Carpentry " .. tostring(S.p:getPerkLevel(Perks.Woodwork)) .. ", planks " .. S.b.planks .. ", nails " .. S.b.nails .. ")")
end)
-- Build pressed on a recipe the character cannot build (key: "miss" materials missing, "lock" short of skill):
-- no cursor, nothing counted. The button is drawn disabled but its zone still takes the press.
function H.refuse(key, label)
    local T = {}
    Q.step(3, function()
        if not (S.buildOk and S.b[key]) then return end
        T.name = S.b[key]
        T.open = H.open(S.BT, H.bst(), T.name, label)
    end)
    H.wait(4000, function() return not T.open or (H.zone(H.bst(), "action_build") ~= nil and H.row(S.BT, T.name) ~= nil) end, function(ok)
        if not S.buildOk then return end
        if not (T.open and ok) then Q.skip(label .. ": Build starts no cursor", "no such recipe listed, or its card drew no Build button"); return end
        local rd = H.row(S.BT, T.name)
        local g = H.gameCanBuild(rd)
        local cnt = H.md("ZeD_BuildCounts", T.name)
        H.noDrag()
        H.bPress(label)
        local d = H.drag()
        Q.check(d == nil and H.md("ZeD_BuildCounts", T.name) == cnt, label .. ": Build on " .. T.name .. " starts no cursor and counts nothing",
            "row " .. tostring(rd.status) .. ", the game's materials check " .. tostring(g) .. ", cursor " .. tostring(d and d.Type))
        if key == "miss" then
            Q.check(g ~= true, label .. ": a row that says missing is one the game would not build", "the game " .. tostring(g))
        end
        H.noDrag()
    end)
end
H.refuse("miss", "build, materials missing")
H.refuse("lock", "build, short of skill")
Q.step(3, function()
    if not S.buildOk then return end
    if not S.b.pick then
        Q.skip("build: a crate or a wall frame built", "nothing is buildable with a hammer, a saw, planks and nails at Carpentry " .. tostring(S.p:getPerkLevel(Perks.Woodwork)))
        return
    end
    S.b.open = H.open(S.BT, H.bst(), S.b.pick, "build")
end)
H.wait(4000, function() return not (S.b and S.b.open) or (H.zone(H.bst(), "action_build") ~= nil and H.settled(H.row(S.BT, S.b.pick))) end, function(ok)
    if not (S.buildOk and S.b.open) then return end
    local rd = H.row(S.BT, S.b.pick)
    local g = rd and H.gameCanBuild(rd)
    Q.check(ok and rd ~= nil and (rd.status == "craftable") == (g == true), "build: the row says buildable exactly when the game would build it",
        "ZeD " .. tostring(rd and rd.status) .. ", the game " .. tostring(g))
    local cnt = H.md("ZeD_BuildCounts", S.b.pick)
    H.bPress("build")
    local d = H.drag()
    S.b.cur = (d and d.Type == "ISBuildIsoEntity") and d or nil
    if not Q.check(S.b.cur ~= nil and H.md("ZeD_BuildCounts", S.b.pick) == cnt + 1, "build: Build starts the game's build cursor and is counted once",
        tostring(d and d.Type) .. ", count +" .. (H.md("ZeD_BuildCounts", S.b.pick) - cnt)) then
        S.b.open = false
        Q.skip("build: cancelled before placing, cancelled mid-build, built to the end", "Build started no cursor for " .. tostring(S.b.pick))
        return
    end
    S.b.sq = H.buildSq(S.b.cur)
    if not S.b.sq then Q.skip("build: placed beside the character", "the cursor takes none of the tiles around"); S.b.open = false; H.noDrag(); return end
    -- cancelled before placing (a right-click): the cursor goes, the card stays, Build starts a new one
    H.noDrag()
    local st = H.bst()
    H.bPress("build again")
    local d2 = H.drag()
    Q.check(st.selected == S.b.pick and d2 ~= nil and d2 ~= S.b.cur and d2.Type == "ISBuildIsoEntity",
        "build: after the cursor is cancelled the card stays and Build starts a new cursor", tostring(st.selected) .. ", " .. tostring(d2 and d2.Type))
    S.b.cur = d2
end)
-- placed, then cancelled mid-build
function H.place(label)
    local cur, sq = S.b.cur, S.b.sq
    S.b.before = H.snapObjs(sq:getX(), sq:getY(), 2)
    S.b.planksWas, S.b.nailsWas = H.count("Base.Plank"), H.count("Base.Nails")
    H.speed(1)
    local ok, err = pcall(function()
        if cur:isValid(sq) then cur:tryBuild(sq:getX(), sq:getY(), sq:getZ()) end
    end)
    if not ok then Q.check(false, label .. ": the game's cursor placed it without an error", err) end
    return ok and H.qlen() > 0
end
Q.step(4, function()
    if not (S.b and S.b.open and S.b.cur) then return end
    S.b.placed = H.place("build cancel")
    if not S.b.placed then Q.skip("build cancel: a build stopped mid-way", "the game's cursor queued nothing for the tile (no way to walk there)") end
end)
H.wait(15000, function() return not (S.b and S.b.placed) or H.head() == "ISBuildAction" or H.qlen() == 0 end, function()
    if not (S.b and S.b.placed) then return end
    S.b.building = H.head() == "ISBuildAction"
    if not S.b.building then Q.skip("build cancel: a build stopped mid-way", "the walk to the tile did not end in the build action (" .. H.head() .. ")"); H.stop() end
end)
Q.waitMs(400)
Q.step(1, function() if S.b and S.b.building then H.stop() end end)
Q.waitMs(700)
Q.step(1, function()
    if not (S.b and S.b.building) then return end
    local new = H.newObjs(S.b.before, S.b.sq:getX(), S.b.sq:getY(), 2)
    for _, o in ipairs(new) do S.built[#S.built + 1] = o end
    Q.check(#new == 0 and H.count("Base.Plank") == S.b.planksWas and H.count("Base.Nails") == S.b.nailsWas and H.qlen() == 0,
        "build cancel: a build stopped mid-way builds nothing and uses nothing",
        #new .. " new objects, planks " .. H.count("Base.Plank") .. "/" .. S.b.planksWas .. ", nails " .. H.count("Base.Nails") .. "/" .. S.b.nailsWas)
    local rd = H.row(S.BT, S.b.pick)
    Q.check(rd ~= nil and (rd.status == "craftable") == (H.gameCanBuild(rd) == true), "build cancel: the row still matches the game", tostring(rd and rd.status))
end)
-- the full build: a new cursor (the placed one blocks itself)
Q.step(20, function()
    if not (S.b and S.b.open and S.b.sq) then return end
    H.stop()
    H.noDrag()
    H.bPress("build to the end")
    local d = H.drag()
    S.b.cur = (d and d.Type == "ISBuildIsoEntity") and d or nil
    S.b.sq = S.b.cur and H.buildSq(S.b.cur) or nil
    S.b.full = S.b.cur ~= nil and S.b.sq ~= nil and H.place("build")
    if not S.b.full then Q.skip("build: built to the end", "no new cursor, or it queued nothing for the tile") end
end)
H.wait(15000, function() return not (S.b and S.b.full) or H.head() == "ISBuildAction" or H.qlen() == 0 end, function()
    if not (S.b and S.b.full) then return end
    if H.head() == "ISBuildAction" then H.speed(3) else S.b.full = false; Q.skip("build: built to the end", "the walk to the tile did not end in the build action (" .. H.head() .. ")"); H.stop() end
end)
H.wait(45000, function() return not (S.b and S.b.full) or H.qlen() == 0 end, function(ok)
    H.speed(1)
    if not (S.b and S.b.full) then return end
    local new = H.newObjs(S.b.before, S.b.sq:getX(), S.b.sq:getY(), 2)
    for _, o in ipairs(new) do S.built[#S.built + 1] = o end
    Q.check(ok and #new >= 1, "build: the build runs to its end and the thing stands on the tile", #new .. " new objects, queue " .. H.head())
    Q.check(#new == 0 or H.count("Base.Plank") < S.b.planksWas or H.count("Base.Nails") < S.b.nailsWas, "build: the materials are used",
        "planks " .. H.count("Base.Plank") .. "/" .. S.b.planksWas .. ", nails " .. H.count("Base.Nails") .. "/" .. S.b.nailsWas)
    if H.qlen() > 0 then H.stop() end
    H.noDrag()
    RT.bounds(Q, "the Building tab after the build")
end)
H.wait(6000, function()
    if not (S.b and S.b.full) then return true end
    local rd = H.row(S.BT, S.b.pick)
    return rd ~= nil and (rd.status == "craftable") == (H.gameCanBuild(rd) == true)
end, function(ok)
    if S.b and S.b.full then
        local rd = H.row(S.BT, S.b.pick)
        Q.check(ok, "build: after the build the row matches the game again (nothing stale)", tostring(rd and rd.status) .. ", the game " .. tostring(rd and H.gameCanBuild(rd)))
    end
    for _, o in ipairs(S.built) do H.removeObj(o) end
    S.built = {}
    H.noDrag()
    if S.buildOk then
        pcall(function() RT.ww()._buildSearch:clear() end)
        H.putState(H.bst(), S.bKeep)
        S.bKeep = nil
    end
end)

-- ===================================================================== dismantle: the Furniture tab
-- a one-tile piece from the game's furniture sprites that its scrap table takes apart (one that wants tools first)
function H.pieceOk(name)
    local spr = getSprite(name)
    if not spr then return nil end
    local mp = ISMoveableSpriteProps.new(spr)
    if not (mp and mp.isMoveable and mp.sprite) or mp.isMultiSprite or mp.type ~= "Object" or mp.isoType ~= "IsoObject" then return nil end
    if mp.isTable or mp.isTableTop or mp.isWaterCollector then return nil end
    local defs = ISMoveableDefinitions:getInstance()
    if not (mp.canScrap and mp.material and defs.isScrapDefinitionValid(mp.material)) then return nil end
    local def = defs.getScrapDefinition(mp.material)
    local t1, t2 = (def and def.tools) or {}, (def and def.tools2) or {}
    return { name = name, mp = mp, t1 = t1[1], t2 = t2[1], rank = (mp.scrapUseTool and (t1[1] or t2[1])) and 2 or 1 }
end
function H.piece()
    local best = nil
    for _, fam in ipairs({ "furniture_seating_indoor_01_", "furniture_seating_indoor_02_", "furniture_seating_indoor_03_", "furniture_seating_outdoor_01_" }) do
        for i = 0, 63 do
            local ok, pc = pcall(H.pieceOk, fam .. i)
            if ok and pc and (not best or pc.rank > best.rank) then best = pc end
            if best and best.rank == 2 then return best end
        end
    end
    return best
end
function H.pieceOn(sq, name)
    local objs = sq and sq:getObjects()
    for i = 0, (objs and objs:size() or 0) - 1 do
        local o = objs:get(i)
        local nm = nil
        pcall(function() nm = o:getSprite():getName() end)
        if nm == name then return o end
    end
    return nil
end
function H.putPiece()
    local o = nil
    pcall(function()
        o = IsoObject.new(getCell(), S.f.sq, S.f.pc.name)
        S.f.sq:AddTileObject(o)
    end)
    if o then S.placed[#S.placed + 1] = o end
    return o
end
function H.fcur() return S.FT.cursorOf(S.pn) end
-- the target read again from scratch, as the pointer coming to rest on the tile: off it and back
function H.read(sq)
    local cur = H.fcur()
    if not cur then return nil end
    local here = S.p:getCurrentSquare()
    local ok, err = pcall(function()
        if here and here ~= sq then
            cur._zedHold = { on = true, sq = here, rest = here, cur = here, since = getTimestampMs() }
            cur:isValid(here)
        end
        cur._zedHold = { on = true, sq = sq, rest = sq, cur = sq, since = getTimestampMs() }
        cur:isValid(sq)
    end)
    if not ok then Q.check(false, "furniture: the cursor read the tile without an error", err) end
    return S.FT.cap[S.pn], cur
end
function H.reads(c, sq, name) return (c ~= nil and c.mp ~= nil and c.sq == sq and c.mp.spriteName == name) and true or false end
Q.step(3, function()
    if S.dead then return end
    S.f = {}
    local ok, pc = pcall(H.piece)
    S.f.pc = ok and pc or nil
    for _, d in ipairs(S.RING) do S.f.sq = S.f.sq or H.freeSq(d[1], d[2]) end
    if not (S.f.pc and S.f.sq) then Q.skip("furniture: a chair taken apart", S.f.pc and "no free tile beside the character" or "no furniture sprite the game's scrap table takes"); S.f = nil; return end
    S.f.obj = H.putPiece()
    if not S.f.obj then Q.skip("furniture: a chair taken apart", "the piece could not be placed"); S.f = nil; return end
    if S.f.pc.t1 then RT.give(S.f.pc.t1) end
    if S.f.pc.t2 then RT.give(S.f.pc.t2) end
    Q.say("furniture: " .. S.f.pc.name .. " (" .. tostring(S.f.pc.mp.name) .. ", " .. tostring(S.f.pc.mp.material) .. ") on " .. S.f.sq:getX() .. "," .. S.f.sq:getY()
        .. ", tools " .. tostring(S.f.pc.t1) .. " / " .. tostring(S.f.pc.t2))
    H.tab("furniture")
end)
H.wait(6000, function() return not S.f or (H.showing("furniture") and H.fcur() ~= nil) end, function(ok)
    if not S.f then return end
    if not Q.check(ok and S.FT.state.active == true, "furniture: opening the Furniture tab starts the game's furniture cursor",
        tostring(H.showing("furniture")) .. " / " .. tostring(H.fcur() ~= nil) .. " / " .. tostring(S.FT.state.active)) then S.f.dead = true; return end
    RT.bounds(Q, "the Furniture tab")
    local w = RT.ww()
    local z = nil
    for _, x in ipairs((w and w._fur and w._fur.zones) or {}) do if x.id == "fur:mode:scrap" then z = x end end
    if z then
        local okC, err = pcall(S.FT.onClick, w, z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
        if not okC then Q.check(false, "furniture: the Disassemble tab's click ran without an error", err) end
    else
        Q.say("note furniture: the strip shows no Disassemble tab in view, the mode is set from code")
        pcall(S.FT.setMode, S.pn, "scrap")
    end
end)
H.wait(4000, function() return not S.f or S.f.dead or (ISMoveableCursor.mode[S.pn] == "scrap" and S.FT.state.mode == "scrap") end, function(ok)
    if not S.f or S.f.dead then return end
    Q.check(ok, "furniture: Disassemble on the strip switches the game's cursor", tostring(ISMoveableCursor.mode[S.pn]) .. " / " .. tostring(S.FT.state.mode))
    local c, cur = H.read(S.f.sq)
    Q.check(H.reads(c, S.f.sq, S.f.pc.name), "furniture: the tab's target is the chair on its tile", tostring(c and c.mp and c.mp.spriteName))
    Q.check(c ~= nil and cur ~= nil and c.canCreate == ((cur.canCreate and true) or false), "furniture: the tab's can / cannot is the cursor's own",
        tostring(c and c.canCreate) .. " / " .. tostring(cur and cur.canCreate))
    S.f.can = c ~= nil and c.canCreate == true
    -- the chair gone while the tab shows it
    H.removeObj(S.f.obj)
    local c2 = H.read(S.f.sq)
    Q.check(not H.reads(c2, S.f.sq, S.f.pc.name), "furniture: with the chair gone the tab no longer shows it as the target (nothing stale)",
        tostring(c2 and c2.mp and c2.mp.spriteName))
    S.f.obj = H.putPiece()
end)
Q.step(20, function()
    if not S.f or S.f.dead then return end
    RT.bounds(Q, "the Furniture tab on Disassemble")
    local c, cur = H.read(S.f.sq)
    if not (S.f.obj and S.f.can and cur and H.reads(c, S.f.sq, S.f.pc.name) and c.canCreate) then
        Q.skip("furniture: the chair taken apart", "the game's cursor says it cannot be taken apart here (tools or skill): " .. tostring(c and c.canCreate))
        return
    end
    H.speed(1)
    local sq = S.f.sq
    local ok, err = pcall(function() cur:create(sq:getX(), sq:getY(), sq:getZ(), false, nil) end)
    if not ok then Q.check(false, "furniture: the cursor's own action started without an error", err); return end
    S.f.run = H.qlen() > 0
    if not S.f.run then Q.skip("furniture: the chair taken apart", "the game's cursor queued nothing (no way to walk to the tile)") end
end)
H.wait(15000, function() return not (S.f and S.f.run) or H.head() == "ISMoveablesAction" or H.qlen() == 0 end, function()
    if not (S.f and S.f.run) then return end
    if H.head() == "ISMoveablesAction" then H.speed(3) end
end)
H.wait(50000, function() return not (S.f and S.f.run) or (H.qlen() == 0 and H.pieceOn(S.f.sq, S.f.pc.name) == nil) or (H.qlen() == 0 and H.head() == "none") end, function()
    H.speed(1)
    if not (S.f and S.f.run) then return end
    local gone = H.pieceOn(S.f.sq, S.f.pc.name) == nil
    Q.check(gone, "furniture: the chair is taken apart by the game's own cursor action", "queue " .. H.head())
    if H.qlen() > 0 then H.stop() end
    if H.fcur() then
        local c = H.read(S.f.sq)
        Q.check(not gone or not H.reads(c, S.f.sq, S.f.pc.name), "furniture: the tab's target is no longer the chair", tostring(c and c.mp and c.mp.spriteName))
    end
    RT.bounds(Q, "the Furniture tab after the chair came apart")
end)
Q.step(10, function() if S.f and not S.f.dead then H.tab("loot") end end)
H.wait(5000, function() return not S.f or S.f.dead or (H.fcur() == nil and S.FT.state.active ~= true) end, function(ok)
    if not S.f or S.f.dead then return end
    Q.check(ok and not H.showing("furniture"), "furniture: leaving the tab ends the game's furniture cursor",
        "cursor " .. tostring(H.fcur() ~= nil) .. ", active " .. tostring(S.FT.state.active))
end)

-- ===================================================================== put back
Q.mark()
-- healed first, in a step of its own: whatever threw before, or throws after, he does not stay hurt; the stats as
-- found again (the heal resets them all), and his own set-aside things back where they were (a run cut short jumps here)
Q.step(2, function()
    H.speed(1)
    H.heal()
    H.putStats()
    if #S.stash > 0 then H.stop(); S.stashLost = (S.stashLost or 0) + H.unstash() end
end)
function H.putCounts()
    local md = S.p:getModData()
    for _, key in ipairs({ "ZeD_CraftCounts", "ZeD_BuildCounts", "ZeD_CraftPins", "ZeD_BuildPins" }) do
        local was = S.cnt[key]
        if was then
            local t = {}
            for k, v in pairs(was) do t[k] = v end
            md[key] = t
        else
            md[key] = nil
        end
    end
    local w = RT.ww()
    if w then
        pcall(S.CC.loadPins, w, "ZeD_CraftPins", "_craftPins")
        pcall(S.CC.loadPins, w, "ZeD_BuildPins", "_buildPins")
        w._craftCache, w._buildCache = nil, nil
    end
end
-- the character's own things a craft used in place of a given one (the game takes whichever it finds first):
-- one new item of the type for each that is short, in the main inventory. Returns how many, and how many are still short.
function H.refill()
    local now, made, short = {}, 0, 0
    for _, it in ipairs(H.all()) do
        local ft = it:getFullType()
        now[ft] = (now[ft] or 0) + 1
    end
    for ft, was in pairs(S.types or {}) do
        for _ = 1, was - (now[ft] or 0) do
            local it = nil
            pcall(function() it = S.p:getInventory():AddItem(ft) end)
            if it then S.had[it] = true; made = made + 1 else short = short + 1 end
        end
    end
    return made, short
end
function H.sweep()
    local n = 0
    for _, it in ipairs(H.all()) do
        if not S.had[it] then H.takeOne(it); n = n + 1 end
    end
    local now = {}
    H.snapFloor(now)
    for wo in pairs(now) do
        if not S.floorHad[wo] then
            pcall(function()
                local sq = wo:getSquare()
                if sq then sq:transmitRemoveItemFromSquare(wo) end
            end)
            pcall(function() wo:removeFromWorld() end)
            pcall(function() wo:removeFromSquare() end)
            n = n + 1
        end
    end
    return n
end
Q.step(3, function()
    H.speed(1)
    H.stop()
    H.noDrag()
    if S.dead then return end
    for _, o in ipairs(S.built) do H.removeObj(o) end
    for _, o in ipairs(S.placed) do H.removeObj(o) end
    S.built, S.placed = {}, {}
    pcall(function() RT.ww()._craftSearch:clear() end)
    pcall(function() RT.ww()._buildSearch:clear() end)
    if S.cKeep then H.putState(H.cst(), S.cKeep) end
    if S.bKeep then H.putState(H.bst(), S.bKeep) end
    pcall(H.putCounts)
    pcall(function() S.p:setTimedActionInstantCheat(S.instWas and true or false) end)
    pcall(function() S.p:setBuildCheat(S.bcWas and true or false) end)
    pcall(function() ISBuildMenu.cheat = S.bmWas end)
    pcall(function() ISMoveableDefinitions.cheat = S.mdWas end)
    RT.pairOpen()
end)
Q.step(10, function()
    if S.dead then return end
    H.tab((S.tabWas and S.tabWas ~= "furniture" and S.tabWas ~= "craft" and S.tabWas ~= "build") and S.tabWas or "loot")
end)
Q.step(20, function()
    if S.dead then return end
    S.swept = H.sweep()
    RT.takeBack()
    if #S.stash > 0 then S.stashLost = (S.stashLost or 0) + H.unstash() end
    S.refilled, S.short = H.refill()
    pcall(function()
        local a, b = S.handWas[1], S.handWas[2]
        S.p:setPrimaryHandItem((a and S.p:getInventory():containsRecursive(a)) and a or nil)
        S.p:setSecondaryHandItem((b and S.p:getInventory():containsRecursive(b)) and b or nil)
    end)
    H.heal()
    H.putStats()
    pcall(function() if S.tod then getGameTime():setTimeOfDay(S.tod) end end)
    pcall(function() local w = RT.ww(); if w then w._containersDirty = true end end)
    if ZEDQA_HOME then ZEDQA_HOME("bx_crf") end
    if S.pairWas == false then RT.pairShut() end
end)
Q.step(10, function()
    if S.dead then return end
    local left = 0
    for _, it in ipairs(H.all()) do if not S.had[it] then left = left + 1 end end
    local now, floor = {}, 0
    H.snapFloor(now)
    for wo in pairs(now) do if not S.floorHad[wo] then floor = floor + 1 end end
    local notBack = (S.stashLost or 0) + #S.stash
    Q.check(left == 0 and floor == 0 and (S.short or 0) == 0 and notBack == 0, "put back: the character carries what it carried at the start, nothing new on the floor",
        tostring(S.swept) .. " taken away, " .. tostring(S.refilled) .. " of the character's own used things given again (" .. tostring(S.short)
        .. " could not be), " .. left .. " carried and " .. floor .. " on the floor left, " .. notBack .. " set-aside things not given back")
    local stood = 0
    if S.f and S.f.pc and S.f.sq and H.pieceOn(S.f.sq, S.f.pc.name) then stood = stood + 1 end
    Q.check(stood == 0 and H.drag() == nil and H.qlen() == 0, "put back: no chair, no cursor, no action left",
        stood .. " / " .. tostring(H.drag() and H.drag().Type) .. " / " .. H.head())
    local st = H.cst()
    Q.check(getGameSpeed() == 1 and (st == nil or (st.selected == nil and (st.search or "") == "")), "put back: game speed 1, the Crafting tab's card shut and its search empty",
        tostring(getGameSpeed()) .. " / " .. tostring(st and st.selected) .. " / " .. tostring(st and st.search))
    RT.bounds(Q, "the end")
end)
-- the last word, whatever happened before (it runs for a character found dead too, and says so). Healed again only
-- when something is wrong: a heal resets every stat, so the stats are put back after it.
Q.step(3, function()
    local was = H.hurt()
    if was ~= "" then H.heal(); H.putStats() end
    local bad = H.hurt()
    Q.check(bad == "", "put back: the character is healed (alive, health 100, no wound, no fracture, not infected)",
        (bad == "" and "healed" or bad) .. ((was ~= "" and was ~= bad) and (" (before this step's heal: " .. was .. ")") or ""))
    pcall(function() if S.invWas ~= nil then S.p:setInvincible(S.invWas) end end)
    local god, inv = nil, nil
    pcall(function() god, inv = S.p:isGodMod(), S.p:isInvincible() end)
    Q.say("note god mode " .. tostring(god) .. " (left on), invincible " .. tostring(inv) .. " (as found)")
end)
Q.start()
