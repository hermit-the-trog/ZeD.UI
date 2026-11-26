-- ZeDUI/tools/qa/ck_tab.lua  (Nov 25 2026, QA; tag ck_tab): the Character window's Cooking tab, the gamut sweep, in
-- the style of the Crafting sweep (cr_tab.lua) and the call checks (cb_calls.lua). Its spec is the map
-- ZeDUI/qa/audits/2026-11-25_map_cooking.md (section 5's suspicions K1-K24 and its staging list). Run after
-- zedqa_prelude.lua and rt_kit.lua (ck.txt). grep "ZEDQA ck_tab". Each suspicion the QA world can stage is proved or
-- cleared with values: PASS when ZeD does what the game does, FAIL with the evidence when it does not; where the game's
-- own path has the same gap (K5's moves back, K13's heat test) both are run and the pair is a NOTE or a check that ZeD
-- does no worse than the game.
-- How it drives the tab: a click is the tab's own handler at the zone's middle (ZeD.CookingTab.onClick, bx_cook's
-- way; a zone scrolled out of its pane is pressed as the pad's A presses it); the pad's presses go through
-- FocusManager's QA hook and its own dispatch on the Character window (RT.pad + RT.padDown, focus by focusWhere in
-- charTabContent), the input mode locked to the controller and put back as found. The game's answers are asked of the
-- game itself: getItemsCanBeUse on the game's own container list (ISInventoryPaneContextMenu.getContainers), the
-- evolved-recipe menu's own rules (getRealEvolvedItemUse, its one option per type and number, its frozen and
-- needToBeCooked refusals, its herbalist naming from ISInventoryPane), the game's own add (ISAddItemInRecipe and
-- onAddItemInEvoRecipe), the game's tooltip measured (ObjectTooltip, measure only) and the item's own getters; never
-- ZeD's code under test.
-- His own things of the types used here, and every free base of an evolved recipe he carries, are set aside for the
-- run, so every dish uses only what a case gave.
-- Cases (K<n> = the map's suspicion):
--   1 picks    K1: Make with a rotten, a stale and a fresh tomato in a stew (mouse), a rotten and a fresh one (pad): the
--              tomato that went in against the best option the game's own menu offers (it lists rotten and fresh as
--              their own options), and the row's number against that tomato's own; a poisoned and a clean carrot
--              (mouse), a favorite and a plain tomato (pad): against the game's one option (NOTE: neither tells them
--              apart, neither skips a favorite). K2: a raw and a cooked steak for a Sandwich (mouse), a frozen and a
--              half-frozen carrot (pad): the row lit exactly when the game offers an item of the type, and the one
--              that went in the one the game takes. K16 NOTE: the tab's Hunger total against the made dish
--   2 poison   K3: a poisonous and a safe berry in a fruit salad, the character without and then with Herbalist: the
--              tab's row name against the game's own naming (ISInventoryPane's rule), one row or two; the item card's
--              Sickness risk against the game's own tooltip, measured for the poisoned and the clean berry (a card
--              showing poison the game's tooltip does not show him is a FAIL); Make by the pad (NOTE which went in)
--   3 pad B    K5: Make by the pad with a tomato from a crate, B while the first add runs: the queue empties (as the
--              game's B), what is made, where the crate's tomato is; the game's own menu add (onAddItemInEvoRecipe) from
--              the crate stopped the same way: ZeD leaves no more out of the crate than the game
--   4 starts   K7 and K6: 5 tomatoes planned on a pasta pot (5), the base switched to a saucepan (4): Make lit or not,
--              then pressed: what is queued, made and said. K9: Make pressed twice (mouse, two frames apart; pad A A):
--              the adds queued, the dishes made, the tomatoes used, any word said
--   5 season   K8: Stew and Soup: the tab's seasoning on the empty pot against the game's; one carrot added by the
--              game's own action, then the game's seasoning for the dish against what the tab offers (FAIL when the
--              game seasons it and the tab cannot); Sandwich (CanAddSpicesEmpty) as the control, Salt added by the pad
--   6 half     K11: the full card, then the drawer held in (the width cap, et_calls' way) to the half card (220): the
--              dish pane's width, the plan rows (Remove) and the Hunger row drawn, inside the tab; Remove by the mouse
--              and the pad there. Pictures ck_half_<WxH> (found text and Large)
--   7 heat     K12: a steak on a lit campfire (its fire card) and in a powered range at 100 and 300 (bound in the Craft
--              tab): ZeD's "min left" against the food's own cooking time over the game clock. K13: the hot steak taken
--              out into the bags, its item card opened: COOKING shown exactly when the game's own inventory pane shows
--              it (its heat test), and (NOTE) whether its cooking time still grows off the heat
--   8 fuel     K14: a gas range after the gas shutoff (SKIP: the QA world has no gas shutoff to set, the sandbox keys
--              said); a propane grill with a full and a half tank: the card's tank gauge against the tank's own share
--   9 facts    K17: a tomato and a packaged food, Nutritionist off and on: the card's calories, protein, fat and carbs
--              against the food's own getters, and against what the game's tooltip shows (measured with and without
--              the trait); the item card opened by the mouse reads as its facts say
--   10 layout  the tab with a stew planned in Dark, Light and High contrast and Large text, the made stew's item card:
--              every zone inside the tab, every ZeD window on screen; pictures ck_tab_*, ck_large_*, ck_card_*
--   every case: no Lua error over it; put back exactly
-- Puts back: every thing given or made (the bags, the floor, the crate, the oven, the fire, the grill); every object
-- laid (the crate, the generator, the range, the campfire, the propane grill: named if left) and any fire near home put
-- out; his traits (Nutritionist, Herbalist) and the Herbalist recipe as found; the skill levels (XP drift a NOTE); the
-- saved dishes; the Cooking tab's dish, base, plan, sort, count and scrolls; a bound station; the theme, the text size,
-- the input lock, the width cap, the pointer, the draw watchers; game speed 1, the clock and his stats; the queue; the
-- window pair, both windows' tabs and the layout; where he stood. God mode and invincible are made sure on and left
-- as found at the end (on for the run: a lit fire and a hot range are beside him).

if not (RT and RT.make) then
    print("ZEDQA ck_tab ERR rt_kit.lua did not run first")
    print("ZEDQA ck_tab VERDICT FAIL 1")
    print("ZEDQA ck_tab DONE")
    return
end
local Q = RT.make("ck_tab")
Q.maxMs = 2200000                    -- (the runner gives this script 2400 s: the put-back runs before that)
local S = { p = RT.p, pn = RT.pn, found = {}, back = {}, made = {}, caseMade = {}, objs = {}, fires = {}, stash = {},
            shots = {}, errs = 0, dead = false, xp = {}, halo = {}, trSeen = {}, trKeys = {} }
local H = {}
local C = {}
S.CK = ZeD and ZeD.CookingTab
S.ST = ZeD and ZeD.Stations
S.OC = ZeD and ZeD.ObjectCards
S.IFP = ZeD and ZeD.ItemFactsPanel
S.IAM = ZeD and ZeD.ItemActionManager
S.F = RT.focus()
S.FT = { pot = "Base.Pot", bread = "Base.BreadSlices", bowl = "Base.Bowl", tomato = "Base.Tomato", carrot = "Base.Carrots",
         steak = "Base.Steak", salt = "Base.Salt", pepper = "Base.Pepper", berry = "Base.BerryGeneric1",
         pastaPot = "Base.WaterPotPasta", pastaPan = "Base.WaterSaucepanPasta" }
S.PACKED = { "Base.Crisps", "Base.Chocolate", "Base.TinnedBeans", "Base.Crackers" }
S.CRATE = "carpentry_01_16"
S.STOVES = { "appliances_cooking_01_0", "appliances_cooking_01_8" }
S.BBQ = "appliances_cooking_01_37"
S.NEAR = { { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }
S.RING2 = { { 2, 0 }, { -2, 0 }, { 0, 2 }, { 0, -2 }, { 2, 2 }, { -2, -2 }, { 2, -2 }, { -2, 2 }, { 3, 0 }, { -3, 0 } }
S.THEMES = { { key = "dark", word = "Dark" }, { key = "light", word = "Light" }, { key = "hicon", word = "High contrast" } }
S.TRAITS = { "NUTRITIONIST", "NUTRITIONIST2", "HERBALIST", "HERBALIST_PROF" }
S.STATS = { "HUNGER", "THIRST", "FATIGUE", "BOREDOM", "STRESS", "ENDURANCE", "UNHAPPINESS", "PANIC", "MORALE", "SANITY", "ANGER",
    "DISCOMFORT", "IDLENESS", "WETNESS", "FOOD_SICKNESS", "POISON", "SICKNESS" }
S.MIN_KEYS = { "UI_ZeD_ObjCard_MinLeft", "UI_ZeD_Appliance_MinShort", "UI_ZeD_ItemAct_MinutesShort" }
for _, k in ipairs(S.MIN_KEYS) do S.trKeys[k] = true end

if not (S.p and S.CK and S.ST and S.OC and S.IFP and S.IAM and ZeD_CharacterWindow) then
    Q.check(false, "the player and ZeD's Cooking tab, stations, object cards, item facts and item actions are loaded")
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
function H.call(o, m, ...)
    if o == nil then return nil end
    local f = o[m]
    if not f then return nil end
    local ok, r = pcall(f, o, ...)
    if ok then return r end
    return nil
end
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
function H.fullType(s)
    s = tostring(s or "")
    if not string.find(s, ".", 1, true) then s = "Base." .. s end
    return s
end
function H.worldMin() local m = 0; pcall(function() m = getGameTime():getWorldAgeHours() * 60 end); return m end
function H.zcall(fn)
    local ok, err = pcall(fn)
    if not ok then S.errs = S.errs + 1; S.zerr = S.zerr or tostring(err) end
    return ok
end

-- ===================================================================== the timed-action queue
function H.queue() local q = nil; pcall(function() q = ISTimedActionQueue.getTimedActionQueue(S.p) end); return (q and q.queue) or {} end
function H.qlen() return #H.queue() end
function H.head() local a = H.queue()[1]; return a and tostring(a.Type) or "none" end
function H.qcount(ty) local n = 0; for _, a in ipairs(H.queue()) do if a.Type == ty then n = n + 1 end end; return n end
function H.qadds() return H.qcount("ZeD_CookAdd") + H.qcount("ISAddItemInRecipe") + H.qcount("ZeD_CookWait") end
function H.qkinds() local o = {}; for _, a in ipairs(H.queue()) do o[#o + 1] = tostring(a.Type) end; return H.list(o, 12) end
function H.qstop() pcall(function() ISTimedActionQueue.clear(S.p) end) end

-- ===================================================================== things
function H.isItem(it) local ok = false; if it ~= nil then pcall(function() ok = instanceof(it, "InventoryItem") end) end; return ok end
function H.isFood(it) local ok = false; if it ~= nil then pcall(function() ok = instanceof(it, "Food") end) end; return ok end
function H.ft(it) local s = "?"; if H.isItem(it) then pcall(function() s = tostring(it:getFullType()) end) end; return s end
function H.nm(it) local s = "nothing"; if H.isItem(it) then pcall(function() s = tostring(it:getDisplayName()) end) end; return s end
function H.where(it) local c = nil; if H.isItem(it) then pcall(function() c = it:getContainer() end) end; return c end
function H.ctype(c) local t = "none"; if c then pcall(function() t = tostring(c:getType()) end) end; return t end
function H.onFloor(it) local wo = nil; if H.isItem(it) then pcall(function() wo = it:getWorldItem() end) end; return wo ~= nil end
function H.gone(it) return H.where(it) == nil and not H.onFloor(it) end
function H.inv() return S.p:getInventory() end
function H.known(ft) local ok = false; if ft then pcall(function() ok = getScriptManager():FindItem(ft) ~= nil end) end; return ok end
function H.hunger(it) local h = nil; if H.isFood(it) then pcall(function() h = it:getHungerChange() end) end; return h end
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
function H.newest(ft) local last = nil; for _, it in ipairs(H.all()) do if H.ft(it) == ft and not S.found.inv0[it] then last = it end end; return last end
function H.mark(it)
    if not H.isItem(it) then return nil end
    pcall(function() it:getModData().ZeDQA_spawned = true end)
    S.made[#S.made + 1] = it
    S.caseMade[#S.caseMade + 1] = it
    return it
end
function H.give(ft) if not ft then return nil end; local it = nil; pcall(function() it = H.inv():AddItem(ft) end); return H.mark(it) end
function H.giveTo(inv, ft) local it = nil; if inv and ft then pcall(function() it = inv:AddItem(ft) end) end; return H.mark(it) end
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
function H.potWater(ft)
    local pot = H.give(ft or S.FT.pot)
    if pot then pcall(function() local fc = pot:getFluidContainer(); fc:addFluid(Fluid.Water, fc:getCapacity()) end) end
    return pot
end
-- a food given in a state: rotten, stale, fresh, cooked, frozen, half (half frozen), poison, fav; nil when the
-- state did not take
function H.food(ft, state, inv)
    local it = inv and H.giveTo(inv, ft) or H.give(ft)
    if not H.isFood(it) then return nil end
    local ok = true
    pcall(function()
        if state == "rotten" then it:setAge(it:getOffAgeMax() + 1); ok = it:isRotten()
        elseif state == "stale" then it:setAge((it:getOffAge() + it:getOffAgeMax()) / 2); ok = (not it:isFresh()) and not it:isRotten()
        elseif state == "fresh" then it:setAge(0); ok = it:isFresh()
        elseif state == "cooked" then it:setCooked(true); ok = it:isCooked()
        elseif state == "frozen" then it:setFreezingTime(100); it:setFrozen(true); ok = it:isFrozen()
        elseif state == "half" then it:setFreezingTime(50); it:setFrozen(false); ok = not it:isFrozen()
        elseif state == "poison" then it:setPoisonPower(10); ok = it:getPoisonPower() > 0
        elseif state == "fav" then it:setFavorite(true); ok = it:isFavorite()
        end
    end)
    if not ok then return nil end
    return it
end
function H.state(it)
    local o = {}
    pcall(function()
        if it:isRotten() then o[#o + 1] = "rotten" elseif it:isFresh() then o[#o + 1] = "fresh" else o[#o + 1] = "stale" end
        if it:isCooked() then o[#o + 1] = "cooked" end
        if it:isFrozen() then o[#o + 1] = "frozen" elseif (it:getFreezingTime() or 0) > 0 then o[#o + 1] = "half-frozen" end
        if (it:getPoisonPower() or 0) > 0 then o[#o + 1] = "poison " .. tostring(it:getPoisonPower()) end
        if it:isFavorite() then o[#o + 1] = "favorite" end
    end)
    return table.concat(o, " ")
end

-- ===================================================================== his own things set aside, and given back
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

-- ===================================================================== skills, traits, Herbalist
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
function H.hasTrait(key)
    local has = false
    pcall(function() local ct = CharacterTrait[key]; if ct then has = S.p:hasTrait(ct) and true or false end end)
    return has
end
function H.traitSet(key, on)
    pcall(function()
        local ct = CharacterTrait[key]
        if not ct then return end
        if on and not S.p:hasTrait(ct) then S.p:getCharacterTraits():add(ct) end
        if not on and S.p:hasTrait(ct) then S.p:getCharacterTraits():remove(ct) end
    end)
end
function H.herbKnown() local k = false; pcall(function() k = S.p:isRecipeActuallyKnown("Herbalist") and true or false end); return k end
function H.herbRecipe() local k = false; pcall(function() k = S.p:getKnownRecipes():contains("Herbalist") and true or false end); return k end
function H.herbSet(on)
    if on then
        pcall(function() S.p:learnRecipe("Herbalist") end)
    else
        H.traitSet("HERBALIST", false)
        H.traitSet("HERBALIST_PROF", false)
        pcall(function() S.p:getKnownRecipes():remove("Herbalist") end)
    end
end
function H.traitsBack()
    local f = S.found
    if not f.traits then return end
    for _, k in ipairs(S.TRAITS) do H.traitSet(k, f.traits[k] == true) end
    local has = H.herbRecipe()
    if f.herbRecipe and not has then pcall(function() S.p:learnRecipe("Herbalist") end) end
    if not f.herbRecipe and has then pcall(function() S.p:getKnownRecipes():remove("Herbalist") end) end
end
function H.traitsAsFound()
    local f, bad = S.found, {}
    for _, k in ipairs(S.TRAITS) do if H.hasTrait(k) ~= (f.traits and f.traits[k] == true) then bad[#bad + 1] = k end end
    if H.herbRecipe() ~= (f.herbRecipe == true) then bad[#bad + 1] = "the Herbalist recipe" end
    if H.herbKnown() ~= (f.herbKnown == true) then bad[#bad + 1] = "Herbalist known" end
    return #bad == 0, H.list(bad)
end

-- ===================================================================== the game's own answers
function H.conts()
    local list = nil
    pcall(function()
        if getPlayerInventory(S.pn) ~= nil and getPlayerLoot(S.pn) ~= nil then
            local l = ISInventoryPaneContextMenu.getContainers(S.p)
            if l and l:size() > 0 then list = l end
        end
    end)
    if not list then pcall(function() list = ZeD.CraftingCore.buildContainers(S.p) end) end
    return list
end
function H.lootRefresh()
    pcall(function() local lp = getPlayerLoot(S.pn); if lp and lp.refreshBackpacks then lp:refreshBackpacks() end end)
    pcall(function() triggerEvent("OnContainerUpdate") end)
    pcall(function() local w = RT.ww(); if w then w._containersDirty = true end end)
end
-- the game's evolved recipe of this name made in this base
function H.gameRecipe(un, baseFt)
    local found = nil
    pcall(function()
        local l = getEvolvedRecipes()
        for i = 0, l:size() - 1 do
            local r = l:get(i)
            if not found and tostring(r:getUntranslatedName()) == un and H.fullType(r:getBaseItem()) == baseFt then found = r end
        end
    end)
    return found
end
function H.dishFtOf(un, baseFt) local r = H.gameRecipe(un, baseFt); local ft = nil; if r then pcall(function() ft = H.fullType(r:getFullResultItem()) end) end; return ft end
function H.dishLabel(un) local l = nil; pcall(function() l = getTextOrNull("ContextMenu_EvolvedRecipe_" .. un) end); return l or un end
function H.lvl() local l = 0; pcall(function() l = S.p:getPerkLevel(Perks.Cooking) end); return l end
function H.useOf(it, r) local u = nil; pcall(function() u = ISInventoryPaneContextMenu.getRealEvolvedItemUse(it, r, H.lvl()) end); return u end
-- the game's list for the base (the base itself left out), in its order
function H.gameList(r, base)
    local out = {}
    pcall(function()
        local l = r:getItemsCanBeUse(S.p, base, H.conts())
        for i = 0, l:size() - 1 do local it = l:get(i); if it ~= base then out[#out + 1] = it end end
    end)
    return out
end
function H.isSpice(it)
    local sp = false
    pcall(function() if instanceof(it, "Food") then sp = it:isSpice() else sp = it:getScriptItem():isSpice() end end)
    return sp and true or false
end
-- the game's menu for the base (ISInventoryPaneContextMenu.doEvorecipeMenu and addItemInEvoRecipe): one option per
-- type and number (a type's option skipped when its number is the type's last), each refused when frozen in a dish
-- that takes no frozen food or not cooked where it must be. ft: only that type (nil: every type)
function H.gameOpts(r, base, ft)
    local out, last = {}, {}
    if not (r and base) then return out end
    for _, it in ipairs(H.gameList(r, base)) do
        local spice = H.isSpice(it)
        local use, keep = nil, true
        if H.isFood(it) and not spice then
            use = H.useOf(it, r)
            local ty = nil
            pcall(function() ty = it:getType() end)
            if ty and last[ty] ~= nil and last[ty] == use then keep = false else if ty then last[ty] = use end end
        end
        if keep and (ft == nil or H.ft(it) == ft) then
            local avail = true
            pcall(function()
                if instanceof(it, "Food") and it:isFrozen() and not r:isAllowFrozenItem() then avail = false end
                if not r:needToBeCooked(it) then avail = false end
            end)
            out[#out + 1] = { item = it, use = use, avail = avail, spice = spice }
        end
    end
    return out
end
function H.optsText(opts)
    local o = {}
    for _, x in ipairs(opts or {}) do o[#o + 1] = H.ft(x.item) .. " " .. H.state(x.item) .. " (" .. tostring(x.use) .. ")" .. (x.avail and "" or " refused") end
    return H.list(o)
end
function H.bestOpt(opts)
    local best = nil
    for _, o in ipairs(opts or {}) do
        if o.avail and type(o.use) == "number" and (best == nil or o.use > best.use) then best = o end
    end
    return best
end
-- the game's name for an item as its inventory names it for him (ISInventoryPane's herbalist rule; read only, the
-- item is not renamed)
function H.gameName(it)
    local nm = H.nm(it)
    pcall(function()
        nm = it:getName(S.p)
        if it:IsFood() and it:getHerbalistType() and it:getHerbalistType() ~= "" then
            local ht = it:getHerbalistType()
            if S.p:isRecipeActuallyKnown("Herbalist") then
                if ht == "Berry" then nm = (it:getPoisonPower() > 0) and getText("IGUI_PoisonousBerry") or getText("IGUI_Berry") end
                if ht == "Mushroom" then nm = (it:getPoisonPower() > 0) and getText("IGUI_PoisonousMushroom") or getText("IGUI_Mushroom") end
            else
                if ht == "Berry" then nm = getText("IGUI_UnknownBerry") end
                if ht == "Mushroom" then nm = getText("IGUI_UnknownMushroom") end
            end
        end
    end)
    return tostring(nm)
end
-- the game's own item tooltip, measured (ISToolTipInv's measure pass): its height in px
function H.tipH(it)
    local h = nil
    pcall(function()
        local tt = ObjectTooltip.new()
        pcall(function() tt:setCharacter(S.p) end)
        tt:setX(0); tt:setY(0); tt:setWidth(50)
        tt:setMeasureOnly(true)
        it:DoTooltip(tt)
        tt:setMeasureOnly(false)
        h = tt:getHeight()
    end)
    return h
end
-- a row of the item card's facts (what every item card shows), by its label
function H.fact(it, label)
    local panel = nil
    local ok, err = pcall(function() panel = S.IFP.factsFor(it, S.pn) end)
    if not ok then S.errs = S.errs + 1; S.zerr = S.zerr or tostring(err) end
    for _, g in ipairs((panel and panel.groups) or {}) do
        for _, r in ipairs(g.rows or {}) do if r.label == label then return r.value end end
    end
    return nil
end

-- ===================================================================== the Cooking tab
function H.cs() local w = RT.cw(); return w and w._cook end
function H.drawn() local w, s = RT.cw(), H.cs(); return w ~= nil and w._activeTab == "cooking" and w._drawerMode == "tab" and s ~= nil and #(s.zones or {}) > 0 end
function H.inStrip() for _, id in ipairs(RT.tabs(RT.charStrip())) do if id == "cooking" then return true end end; return false end
function H.czone(id) local s = H.cs(); return s and s.byId and s.byId[id] or nil end
function H.lit(id) local z = H.czone(id); return z ~= nil and not z.disabled end
function H.plan() local s = H.cs(); return (s and s.plan) or {} end
function H.planFts() local o = {}; for _, e in ipairs(H.plan()) do o[#o + 1] = e.ft .. (e.spice and " (seasoning)" or "") end; return H.list(o) end
function H.planCount(ft) local n = 0; for _, e in ipairs(H.plan()) do if e.ft == ft then n = n + 1 end end; return n end
function H.planN() local n = 0; for _, e in ipairs(H.plan()) do if not e.spice then n = n + 1 end end; return n end
function H.curBase()
    local s = H.cs()
    local list = s and s.dish and s.bases and s.bases[s.dish]
    if not list or #list == 0 then return nil end
    return list[s.baseIdx or 1] or list[1]
end
function H.rescan() local s = H.cs(); if s then s.scanAt, s.visAt, s.ingCache = -1, nil, nil end end
-- a press on a zone: a click at its middle; scrolled out of its pane, as the controller's A presses it (bx_cook's)
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
function H.rowsText()
    local o = {}
    local s = H.cs()
    for _, g in ipairs((s and s.ingCache and s.ingCache.list) or {}) do o[#o + 1] = g.ft .. " x" .. tostring(g.n) .. (g.why and " grey" or "") end
    return "dish " .. tostring(s and s.dish) .. "; rows " .. H.list(o, 12)
end
function H.dishesText() local s = H.cs(); return H.list((s and s.dishList) or {}, 12) end
function H.snapRow(ft)
    local s = H.cs()
    local g = s and s.ingCache and s.ingCache.byFt and s.ingCache.byFt[ft]
    if not g then return nil end
    local items = {}
    for _, it in ipairs(g.items or {}) do items[#items + 1] = it end
    return { name = g.name, use = g.use, n = g.n, why = g.why, spice = g.spice, items = items, kind = g.kind }
end
function H.spiceRows()
    local o = {}
    local s = H.cs()
    for _, g in ipairs((s and s.ingCache and s.ingCache.list) or {}) do if g.spice then o[g.ft] = true end end
    return o
end
function H.setText(set) local o = {}; for k in pairs(set or {}) do o[#o + 1] = k end; table.sort(o); return H.list(o) end
function H.sameSet(a, b)
    for k in pairs(a or {}) do if not (b and b[k]) then return false end end
    for k in pairs(b or {}) do if not (a and a[k]) then return false end end
    return true
end
-- queue: the Cooking tab drawing (T.off when it does not)
function H.toTab(T, label)
    H.step(2, function()
        if T.off then return end
        RT.pairOpen()
        H.rescan()
    end)
    H.wait(8000, function() return T.off or H.inStrip() end, function(ok)
        if T.off then return end
        local w = RT.cw()
        if ok and w and w._drawerMode == "item" then pcall(ZeD_CharacterWindow.openTab, S.pn, "loot") end
    end)
    H.step(3, function() if not T.off and H.inStrip() then pcall(ZeD_CharacterWindow.openTab, S.pn, "cooking") end end)
    H.wait(6000, function() return T.off or H.drawn() end, function(ok)
        if T.off then return end
        if not Q.check(ok, label .. ": the Cooking tab is in the strip and draws", "in the strip " .. tostring(H.inStrip()) .. ", tab "
            .. tostring(RT.cw() and RT.cw()._activeTab)) then T.off = true end
    end)
end
-- queue: the dish picked from the Dish list by its name (bx_cook's)
function H.pickDish(T, un, label)
    H.step(2, function()
        T.dishKey = nil
        if T.off then return end
        local s = H.cs()
        if s then s.popup = nil end
        T.want = H.dishLabel(un)
        H.cpress("cook:dish")
    end)
    H.step(4, function()
        if T.off then return end
        local s = H.cs()
        for _, m in ipairs((s and s.dishGeo and s.dishGeo.modes) or {}) do
            if not T.dishKey and m.label == T.want and string.sub(m.id, 1, 5) == "dish:" then T.dishKey = string.sub(m.id, 6) end
        end
        if not (T.dishKey and H.cpress("cook:pop:dish:" .. T.dishKey)) then if s then s.popup = nil end end
    end)
    H.step(4, function()
        if T.off then return end
        local s = H.cs()
        if not Q.check(T.dishKey ~= nil and s ~= nil and s.dish == T.dishKey, label .. ": the Dish list picks " .. tostring(T.want),
            "dish " .. tostring(s and s.dish) .. "; offered " .. H.dishesText()) then T.off = true end
    end)
end
-- queue: the base T.baseIt picked from the base list when the tab is on another
function H.pickBase(T, label, which)
    H.step(2, function()
        T.baseI = nil
        if T.off then return end
        local want = which and T[which] or T.baseIt
        local s, b = H.cs(), H.curBase()
        if not (s and want) or (b and b.item == want) then return end
        for i, o in ipairs((s.bases and s.bases[s.dish]) or {}) do if o.item == want then T.baseI = i end end
        if T.baseI then H.cpress("cook:base") end
    end)
    H.step(4, function()
        if T.off or not T.baseI then return end
        if not H.cpress("cook:pop:base:" .. T.baseI) then local s = H.cs(); if s then s.popup = nil end end
    end)
    H.step(4, function()
        if T.off then return end
        local want = which and T[which] or T.baseIt
        local b = H.curBase()
        if not Q.check(want == nil or (b ~= nil and b.item == want), label .. ": the dish is planned in the base the case gave",
            "in " .. tostring(b and H.nm(b.item)) .. ", wanted " .. H.nm(want)) then T.off = true end
    end)
end

-- ===================================================================== the pad (et_calls' and cr_tab's, on the Character window)
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
    local w = RT.cw()
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
function H.focusedId() local el = nil; pcall(function() el = S.F.getFocusedElement(RT.cw()) end); return el and el.id or nil end
function H.focusEl(id)
    local w = RT.cw()
    if not (w and S.F and S.F.focusWhere and id) then return false end
    pcall(S.F.claimFocus, w)
    local e = nil
    pcall(function() e = S.F.focusWhere(w, "charTabContent", function(el) return el.id == id end) end)
    return e ~= nil
end
-- a tap queued on the Character window: down through the QA hook and FocusManager's dispatch, up 4 frames later,
-- then the hook lets go (nothing is pressed when gate says no)
function H.tap(name, joy, gate)
    local st = {}
    H.step(1, function()
        local w = RT.cw()
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

-- ===================================================================== the draw and the words, watched (on for the run)
-- S.ckRect: the Cooking tab's rectangle as the window draws it; S.hungerSeen: the tab's Hunger row as drawn last;
-- S.trSeen[key]: the minutes a cooking reading drew last; S.tankSeen: the propane gauge's share as drawn last;
-- S.halo: the words over his head
function H.wrapOn()
    if S.w0 then return end
    local W = { render = S.CK.render, stat = ZeD.Molecules.drawStatRow, tr = ZeD.tr,
                plate = ZeD.Plate and ZeD.Plate.draw, prow = ZeD.ObjectCardPlain and ZeD.ObjectCardPlain.row }
    S.w0 = W
    W.hungerWord = getText("Tooltip_food_Hunger")
    W.renderFn = function(panel, win, x, y, w, h)
        S.ckRect = { x = x, y = y, w = w, h = h, t = getTimestampMs() }
        S.inCook = true
        local ok, res = pcall(W.render, panel, win, x, y, w, h)
        S.inCook = false
        if not ok then S.tabErrs = (S.tabErrs or 0) + 1; S.tabErrLast = res; error(res, 0) end
        return res
    end
    W.statFn = function(panel, x, y, w, label, value, ...)
        if S.inCook and label == W.hungerWord then S.hungerSeen = { v = value, x = x, w = w, t = getTimestampMs() } end
        return W.stat(panel, x, y, w, label, value, ...)
    end
    W.trFn = function(key, ...)
        if S.trKeys[key] then
            local a = ...
            S.trSeen[key] = { v = a, t = getTimestampMs() }
        end
        return W.tr(key, ...)
    end
    W.plateFn = function(cv, des, st, ...)
        if type(st) == "table" and st.tankF ~= nil then S.tankSeen = { v = st.tankF, t = getTimestampMs() } end
        return W.plate(cv, des, st, ...)
    end
    W.tankWord = ZeD.tr("UI_ZeD_Fire_Tank")
    W.prowFn = function(card, x, y, w, r, ...)
        if type(r) == "table" and r.shareLabel ~= nil and r.shareLabel == W.tankWord then S.tankSeen = { v = r.share, t = getTimestampMs() } end
        return W.prow(card, x, y, w, r, ...)
    end
    S.CK.render = W.renderFn
    ZeD.Molecules.drawStatRow = W.statFn
    ZeD.tr = W.trFn
    if W.plate then ZeD.Plate.draw = W.plateFn end
    if W.prow then ZeD.ObjectCardPlain.row = W.prowFn end
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
end
function H.wrapOff()
    local W = S.w0
    if not W then return end
    if S.CK.render == W.renderFn then S.CK.render = W.render end
    if ZeD.Molecules.drawStatRow == W.statFn then ZeD.Molecules.drawStatRow = W.stat end
    if ZeD.tr == W.trFn then ZeD.tr = W.tr end
    if W.plate and ZeD.Plate.draw == W.plateFn then ZeD.Plate.draw = W.plate end
    if W.prow and ZeD.ObjectCardPlain.row == W.prowFn then ZeD.ObjectCardPlain.row = W.prow end
    for k, e in pairs(W.halo or {}) do if HaloTextHelper[k] == e.fn then HaloTextHelper[k] = e.orig end end
    S.w0 = nil
end
function H.wrapped()
    local W = S.w0
    if not W then return true end
    return S.CK.render == W.render and ZeD.tr == W.tr and ZeD.Molecules.drawStatRow == W.stat
end
function H.seen(key, ms) local r = S.trSeen[key]; if r and getTimestampMs() - r.t <= (ms or 1000) then return r.v end; return nil end
function H.saidSince(t0)
    local o = {}
    for _, h in ipairs(S.halo) do if h.t >= (t0 or 0) then o[#o + 1] = h.text end end
    return o
end

-- ===================================================================== objects laid round him (cr_tab's and bx_cook's)
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
function H.used(sq) for _, c in ipairs(S.objs) do if c.sq == sq then return true end end; for _, f in ipairs(S.fires) do if f.sq == sq then return true end end; return false end
function H.firstFree(ring) for _, d in ipairs(ring) do local sq = H.freeSq(d[1], d[2]); if sq and not H.used(sq) then return sq end end; return nil end
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
function H.mkGen(sq)
    local g = nil
    pcall(function()
        g = IsoGenerator.new(instanceItem("Base.Generator"), getCell(), sq)
        g:setFuel(60); g:setCondition(100); g:setConnected(true); g:setActivated(true)
    end)
    if not g then return nil end
    return H.keepObj(g, sq, "the generator at " .. sq:getX() .. "," .. sq:getY(), "gen")
end
function H.mkStove(sq)
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
            if o then return H.keepObj(o, sq, "the range (" .. name .. " at " .. sq:getX() .. "," .. sq:getY() .. ")", "stove") end
        end
    end
    return nil
end
function H.mkBBQ(sq)
    local o = nil
    pcall(function() o = IsoBarbecue.new(getCell(), sq, getSprite(S.BBQ)); sq:AddTileObject(o) end)
    if not o then return nil end
    return H.keepObj(o, sq, "the propane grill (" .. S.BBQ .. " at " .. sq:getX() .. "," .. sq:getY() .. ")", "bbq")
end
function H.rmObj(c)
    if not (c and c.obj) then return end
    local o = c.obj
    pcall(function() if c.kind == "gen" then o:setActivated(false); o:setConnected(false) end end)
    pcall(function() if c.kind == "stove" and o:Activated() then o:Toggle() end end)
    pcall(function() local ct = o:getContainer(); if ct then ct:removeAllItems() end end)
    local sq = c.sq
    pcall(function() sq = o:getSquare() or c.sq end)
    if sq then
        pcall(function() sq:transmitRemoveItemFromSquare(o) end)
        pcall(function() if o:getObjectIndex() >= 0 then sq:RemoveTileObject(o) end end)
        pcall(function() sq:getObjects():remove(o) end)
        pcall(function() sq:getSpecialObjects():remove(o) end)
        pcall(function() sq:RecalcProperties() end)
    end
    pcall(function() if c.kind == "gen" then o:remove() end end)
    pcall(function() o:removeFromWorld() end)
    pcall(function() o:removeFromSquare() end)
    c.removed = true
end
function H.objLeft(c)
    if not (c and c.obj) then return false end
    local left = false
    pcall(function() left = c.sq:getObjects():contains(c.obj) end)
    if not left then pcall(function() local sq = c.obj:getSquare(); left = sq ~= nil and sq:getObjects():contains(c.obj) end) end
    return left
end
function H.powered(o) local pw = false; pcall(function() local c = o:getContainer(); pw = c ~= nil and c:isPowered() end); return pw and true or false end
-- the campfire (bx_cook's: the game's campfire system)
function H.mkFire(sq)
    if not (sq and SCampfireSystem and SCampfireSystem.instance) then return nil end
    pcall(function() SCampfireSystem.instance:addCampfire(sq) end)
    local f = { sq = sq }
    S.fires[#S.fires + 1] = f
    return f
end
function H.fireLua(f) local lo = nil; if f and CCampfireSystem and CCampfireSystem.instance then pcall(function() lo = CCampfireSystem.instance:getLuaObjectOnSquare(f.sq) end) end; return lo end
function H.fireServer(f) local so = nil; if f and SCampfireSystem and SCampfireSystem.instance then pcall(function() so = SCampfireSystem.instance:getLuaObjectOnSquare(f.sq) end) end; return so end
function H.fireIso(f) local lo = H.fireLua(f); local iso = nil; if lo then pcall(function() iso = lo:getIsoObject() end) end; return iso end
function H.rmFire(f)
    local iso = H.fireIso(f)
    pcall(function() local c = iso and iso:getContainer(); if c then c:removeAllItems() end end)
    local so = H.fireServer(f)
    if so then pcall(function() so:putOut() end); pcall(function() SCampfireSystem.instance:removeCampfire(so) end) end
    f.removed = true
end
-- any fire within 6 tiles of where he stood put out (bx_cook's: burnt food in a powered range can start one)
function H.fireSweep()
    local n = 0
    local f = S.found.pos
    if not f then return n end
    local cx, cy, cz = math.floor(f.x), math.floor(f.y), math.floor(f.z)
    for y = cy - 6, cy + 6 do
        for x = cx - 6, cx + 6 do
            pcall(function()
                local sq = getCell():getGridSquare(x, y, cz)
                if sq and sq:haveFire() then sq:stopFire(); n = n + 1 end
            end)
        end
    end
    return n
end
-- new world items round him (anything not there at the start), taken away
function H.snapFloor(set)
    local cx, cy, cz = math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())
    for y = cy - 6, cy + 6 do
        for x = cx - 6, cx + 6 do
            local sq = getCell():getGridSquare(x, y, cz)
            local wos = sq and sq:getWorldObjects()
            for i = 0, (wos and wos:size() or 0) - 1 do set[wos:get(i)] = true end
        end
    end
end
function H.sweepFloor()
    local now, n = {}, 0
    pcall(H.snapFloor, now)
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
function H.sweepNew()
    local n = 0
    for _, it in ipairs(H.all()) do if not S.found.inv0[it] then H.removeItem(it); n = n + 1 end end
    return n
end

-- ===================================================================== the Character window's list and item card (bx_cook's)
function H.content() local w = RT.cw(); return w and w._mainContent end
function H.rowZone(item)
    local c = H.content()
    for _, z in ipairs((c and c._hitZones) or {}) do if z.id == item then return z end end
    return nil
end
function H.seekRow(item, T)
    local c = H.content()
    if not c then return false end
    if H.rowZone(item) then return true end
    local sc = c._scroll
    if sc and sc.setScrollPos then
        T.seekPos = (T.seekPos or -0.1) + 0.1
        if T.seekPos > 1.001 then T.seekPos = 0 end
        pcall(function() sc:setScrollPos(T.seekPos) end)
    end
    return false
end
function H.clickRow(item)
    local c = H.content()
    local z = H.rowZone(item)
    if not (c and z) then return false end
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    H.zcall(function() c:onMouseDown(x, y); c:onMouseUp(x, y) end)
    return true
end
function H.cardOn(item)
    local w = RT.cw()
    local c = w and w._itemCard
    return item ~= nil and w ~= nil and w._drawerItem == item and c ~= nil and c.item == item
end
-- queue: the item card of T[key] opened by a click on its row (T[key .. "Card"] true when it shows)
function H.openCard(T, key, label)
    H.step(3, function()
        T.seekPos = nil
        local it, c = T[key], H.content()
        if T.off or not (it and c) then return end
        local ft = H.ft(it)
        c._expandedStacks = c._expandedStacks or {}
        S.stackWas = S.stackWas or {}
        if S.stackWas[ft] == nil then S.stackWas[ft] = c._expandedStacks[ft] or false end
        c._expandedStacks[ft] = true
    end)
    H.wait(5000, function() return T.off or T[key] == nil or H.seekRow(T[key], T) end, function(ok)
        if T.off or T[key] == nil then return end
        if Q.check(ok, label .. ": its row is in the Character window's list", H.nm(T[key])) then H.clickRow(T[key]) end
    end)
    H.wait(3000, function() return T.off or T[key] == nil or H.cardOn(T[key]) end, function(ok)
        if T.off or T[key] == nil then return end
        T[key .. "Card"] = Q.check(ok, label .. ": a click on its row opens its item card", "the card shows " .. H.nm(RT.cw() and RT.cw()._drawerItem))
    end)
end
function H.cardShut()
    local w = RT.cw()
    if w and w._drawerItem then pcall(ZeD_CharacterWindow.openTab, S.pn, "loot") end
end

-- ===================================================================== theme, text size, pictures (cr_tab's)
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
-- the drawer held in to the half card (et_calls' way: the window's width cap made too narrow for the full card)
function H.isHalf() local w = RT.cw(); return w ~= nil and math.abs((w._drawerEffW or 0) - ZeD.T.px(220)) <= 1 end
function H.isFull() local w = RT.cw(); return w ~= nil and math.abs((w._drawerEffW or 0) - ZeD.T.px(480)) <= 1 end
function H.halfOn(T)
    H.step(2, function()
        T.half = nil
        if T.off then return end
        local w = RT.cw()
        if not H.isHalf() and w then
            if S.back.maxW == nil then S.back.maxW = { v = w._maxWinW } end
            S.layoutTouched = true
            w._maxWinW = ZeD.T.px(620)
        end
        T.hs = { last = -1, n = 0 }
    end)
    H.wait(5000, function()
        if T.off then return true end
        local w = RT.cw()
        local e = math.floor((w and w._drawerEffW) or 0)
        if e == T.hs.last then T.hs.n = T.hs.n + 1 else T.hs.last, T.hs.n = e, 0 end
        return T.hs.n >= 6 and H.isHalf()
    end, function(ok)
        if T.off then return end
        T.half = ok
        if not ok then Q.skip("the half card (220)", "the Character window would not hold the half card here (the drawer is " .. math.floor(RT.cw()._drawerEffW or 0) .. " px)") end
    end)
end
function H.halfBack()
    if not S.back.maxW then return end
    local w = RT.cw()
    if w then w._maxWinW = S.back.maxW.v end
    S.back.maxW = nil
end

-- ===================================================================== a case's start and end
function H.tabReset()
    local s = H.cs()
    if s then s.plan, s.qty, s.popup, s.listScroll, s.dishScroll = {}, 1, nil, 0, 0 end
    H.rescan()
end
function H.caseStart()
    S.caseMade = {}
    S.caseObjs = #S.objs
    S.caseFires = #S.fires
    S.halo = {}
    H.tabReset()
end
function H.legClean()
    H.speed(1)
    H.qstop()
    H.padOff()
    for _, it in ipairs(S.caseMade) do H.removeItem(it) end
    S.caseMade = {}
    H.sweepNew()
    H.tabReset()
    H.lootRefresh()
end
function H.caseClean()
    H.legClean()
    H.halfBack()
    H.themeBack()
    H.sizeBack()
    H.cardShut()
    pcall(function() if S.boundByUs then S.ST.unbind(S.p); S.boundByUs = nil end end)
    pcall(function() ZeD_WorldWindow.closeObjectCard(S.pn) end)
    for i = (S.caseObjs or 0) + 1, #S.objs do H.rmObj(S.objs[i]) end
    for i = (S.caseFires or 0) + 1, #S.fires do H.rmFire(S.fires[i]) end
    H.fireSweep()
    H.sweepFloor()
    pcall(function() S.p:setPrimaryHandItem(S.found.hands.p) end)
    pcall(function() S.p:setSecondaryHandItem(S.found.hands.s) end)
    H.traitsBack()
    H.home()
    H.lootRefresh()
end
function H.caseEnd(label)
    H.step(2, function() H.caseClean() end)
    H.step(10, function()
        local e1 = H.errN()
        Q.check(S.e0 == nil or e1 == nil or e1 == S.e0, label .. ": no Lua error over the case",
            (S.e0 and e1) and ((e1 - S.e0) .. " new") or "the count cannot be read")
        if S.zerr then Q.check(false, label .. ": nothing ZeD ran for the case threw", S.zerr); S.zerr = nil end
        S.e0 = e1
    end)
end

-- ===================================================================== setup
function S.setup()
    Q.step(1, function()
        local f = S.found
        S.dead = S.p:isDead() and true or false
        if S.dead then Q.check(false, "setup: the character is alive (nothing is run on a dead one)"); return end
        if not (S.F and S.F.focusWhere and ISTimedActionQueue and ISAddItemInRecipe and getEvolvedRecipes) then
            S.dead = true
            Q.check(false, "setup: the pad's focus manager and the game's cooking code are loaded")
            return
        end
        S.err0 = H.errN()
        S.e0 = S.err0
        if ZEDQA_HOME then pcall(ZEDQA_HOME, "ck_tab") end
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
        pcall(H.snapFloor, f.floor0)
        pcall(function() f.tod = getGameTime():getTimeOfDay() end)
        f.stats = {}
        pcall(function()
            local stt = S.p:getStats()
            for _, k in ipairs(S.STATS) do pcall(function() f.stats[k] = stt:get(CharacterStat[k]) end) end
        end)
        pcall(function() f.inst = S.p:isTimedActionInstantCheat(); S.p:setTimedActionInstantCheat(false) end)
        pcall(function() f.god = S.p:isGodMod() and true or false; S.p:setGodMod(true) end)
        pcall(function() f.invinc = S.p:isInvincible() and true or false; S.p:setInvincible(true) end)
        local md = S.p:getModData()
        f.dishes = nil
        if type(md.ZeD_CookDishes) == "table" then
            f.dishes = {}
            for i, d in ipairs(md.ZeD_CookDishes) do f.dishes[i] = d end
        end
        f.dishesN = f.dishes and #f.dishes or -1
        f.base, f.baseIdx = ZeD.currentBase, H.optVal(H.zopt("baseTheme"))
        f.size, f.sizeIdx = ZeD.currentSize, H.optVal(H.zopt("textSize"))
        S.lockWas = H.lockFound()
        f.traits = {}
        for _, k in ipairs(S.TRAITS) do f.traits[k] = H.hasTrait(k) end
        f.herbRecipe, f.herbKnown = H.herbRecipe(), H.herbKnown()
        H.xpSnap()
        pcall(function()
            local cur = S.ST.current(S.p)
            if cur then f.st = cur; S.ST.unbind(S.p); H.note("a station was bound: unbound for the run, bound again at the end") end
        end)
        RT.pairOpen()
        if ZEDQA_LAYOUT_SNAP then pcall(function() f.layout = ZEDQA_LAYOUT_SNAP() end) end
        local cw, ww = RT.cw(), RT.ww()
        f.ctab, f.wtab = cw and cw._activeTab, ww and ww._activeTab
        f.maxW = cw and cw._maxWinW
        local s = cw and cw._cook
        if s then
            local pl = {}
            for i, e in ipairs(s.plan or {}) do pl[i] = { ft = e.ft, name = e.name, spice = e.spice } end
            local col = {}
            for k, v in pairs(s.collapsed or {}) do col[k] = v end
            f.cook = { dish = s.dish, baseIdx = s.baseIdx, plan = pl, sort = s.sort, qty = s.qty, ls = s.listScroll, ds = s.dishScroll, col = col }
        end
        f.recorded = true
        S.back.on = true
        H.wrapOn()
        Q.say("found: at " .. math.floor(f.pos.x) .. "," .. math.floor(f.pos.y) .. ", theme " .. tostring(f.base) .. ", text " .. tostring(f.size)
            .. ", input lock " .. tostring(S.lockWas) .. ", screen " .. H.sizeTag() .. ", Cooking " .. H.lvl() .. ", traits "
            .. (f.traits.NUTRITIONIST and "Nutritionist " or "") .. (f.traits.NUTRITIONIST2 and "Nutritionist(prof) " or "")
            .. (f.traits.HERBALIST and "Herbalist " or "") .. (f.traits.HERBALIST_PROF and "Herbalist(prof) " or "")
            .. "| Herbalist known " .. tostring(f.herbKnown) .. ", saved dishes " .. tostring(f.dishesN) .. ", Character tab " .. tostring(f.ctab))
    end)
    H.step(2, function()
        -- his own things of the types used here, and every free base of an evolved recipe he carries, set aside
        local set = {}
        for _, ft in pairs(S.FT) do set[ft] = true end
        for _, ft in ipairs(S.PACKED) do set[ft] = true end
        pcall(function()
            local l = getEvolvedRecipes()
            for i = 0, l:size() - 1 do
                local r = l:get(i)
                set[H.fullType(r:getBaseItem())] = true
                set[H.fullType(r:getFullResultItem())] = true
            end
        end)
        local aside, kept = H.stashTypes(set)
        H.note("setup: " .. aside .. " of his own things (ingredients used here, dish bases, dishes) are set aside"
            .. (kept > 0 and (", " .. kept .. " worn, held or on the belt stay") or ""))
        H.tabReset()
        H.lootRefresh()
        local miss = {}
        for k, ft in pairs(S.FT) do if not H.known(ft) then miss[#miss + 1] = k .. " " .. ft end end
        Q.check(#miss == 0, "setup: every item type the cases use is known to this game", "unknown: " .. H.list(miss))
    end)
    Q.waitMs(1500)
end

-- ===================================================================== 1. which item Make takes (K1, K2)
-- spec: label, how ("mouse" or "pad"), un (the dish), baseFt, ft (the row pressed), stage(T) (gives the base as
-- T.baseIt and the tracked items as T.items = { { it, tag } }; T.skip with why), rowJudge(T) (optional, at the row),
-- judge(T) (after Make)
function C.leg(spec)
    local T = { spec = spec }
    local L = spec.label
    H.step(2, function()
        H.legClean()
        T.items = {}
        S.hungerSeen = nil
        local ok, err = pcall(spec.stage, T)
        if not ok then T.skip = "the staging threw: " .. tostring(err) end
        if T.skip then Q.skip(L, T.skip); T.off = true; return end
        T.dishFt = H.dishFtOf(spec.un, spec.baseFt)
        T.r = H.gameRecipe(spec.un, spec.baseFt)
        if not (T.r and T.dishFt) then Q.skip(L, "the game has no " .. spec.un .. " made in " .. spec.baseFt); T.off = true; return end
        H.lootRefresh()
        H.rescan()
    end)
    H.toTab(T, L)
    H.pickDish(T, spec.un, L)
    H.pickBase(T, L)
    H.wait(6000, function() return T.off or H.czone("cook:ing:" .. spec.ft) ~= nil end, function(ok)
        if T.off then return end
        if not Q.check(ok, L .. ": the " .. spec.ft .. " row is listed", H.rowsText()) then T.off = true; return end
        T.g = H.snapRow(spec.ft)
        T.opts = H.gameOpts(T.r, T.baseIt, spec.ft)
        T.lit = H.lit("cook:ing:" .. spec.ft)
        for _, e in ipairs(T.items) do e.h0 = H.hunger(e.it); e.use = H.useOf(e.it, T.r) end
        T.dish0 = H.count(T.dishFt)
        H.note(L .. ": the row " .. tostring(T.g and T.g.name) .. " (" .. tostring(T.g and T.g.use) .. ") x" .. tostring(T.g and T.g.n)
            .. (T.lit and " lit" or " grey") .. (T.g and T.g.why and (", " .. T.g.why) or "") .. "; the game's options " .. H.optsText(T.opts))
        if spec.rowJudge then spec.rowJudge(T) end
    end)
    if spec.how == "pad" then
        H.step(2, function()
            if T.off or T.stop then return end
            T.go = H.padOn() and H.focusEl("cook:ing:" .. spec.ft)
            if not Q.check(T.go, L .. ": the pad's focus lands on the row", "on " .. tostring(H.focusedId())) then T.stop = true end
        end)
        H.tapA(function() return T.go and not T.off and not T.stop end)
    else
        H.step(2, function() if not (T.off or T.stop) then H.cpress("cook:ing:" .. spec.ft) end end)
    end
    H.wait(2500, function() return T.off or T.stop or H.planCount(spec.ft) >= 1 end, function(ok)
        if T.off or T.stop then return end
        if not Q.check(ok and H.planCount(spec.ft) == 1, L .. ": one press on the row puts one in the dish", "plan " .. H.planFts()) then T.stop = true end
    end)
    if spec.how == "pad" then
        H.step(2, function()
            if T.off or T.stop then return end
            T.go2 = H.focusEl("cook:make")
            if not Q.check(T.go2, L .. ": the pad's focus lands on Make", "on " .. tostring(H.focusedId())) then T.stop = true end
        end)
        H.tapA(function() return T.go2 and not T.off and not T.stop end)
    else
        H.step(2, function() if not (T.off or T.stop) then H.cpress("cook:make") end end)
    end
    H.step(1, function() T.t0 = getTimestampMs(); T.q0 = H.qlen(); T.kinds = H.qkinds() end)
    H.wait(30000, function() return T.off or T.stop or (H.qlen() == 0 and getTimestampMs() - (T.t0 or 0) > 300) end, function(ok)
        H.padOff()
        if T.off or T.stop then return end
        T.used = {}
        local o = {}
        for _, e in ipairs(T.items) do
            local now = H.hunger(e.it)
            local used = H.gone(e.it) or H.where(e.it) ~= H.inv() or (e.h0 ~= nil and now ~= nil and math.abs(now - e.h0) > 0.0001)
            if used then T.used[#T.used + 1] = e; o[#o + 1] = e.tag end
        end
        T.usedText = H.list(o)
        T.made = H.count(T.dishFt) - (T.dish0 or 0)
        Q.check(ok and (T.q0 or 0) > 0 and T.made >= 1, L .. ": Make queues its adds and makes the dish",
            "queued " .. tostring(T.kinds) .. "; made " .. tostring(T.made) .. " " .. tostring(T.dishFt) .. "; went in: " .. T.usedText)
        -- K16: the tab's Hunger total against the made dish
        local dish = H.newest(T.dishFt)
        local dh = H.hunger(dish)
        H.note(L .. " (K16): the tab's Hunger total read " .. tostring(S.hungerSeen and S.hungerSeen.v) .. "; the made dish's hunger reduction "
            .. (dh and H.n1(-dh * 100) or "?") .. " (the game's own getHungerChange)")
        spec.judge(T)
    end)
    H.step(2, function() H.legClean() end)
end
-- the item that went in against the best option the game's own menu offers for the type
function C.judgeBest(what)
    return function(T)
        local L = T.spec.label
        local best = H.bestOpt(T.opts)
        local u = T.used[1]
        Q.check(#T.used == 1, L .. ": exactly one " .. what .. " went in", "went in: " .. T.usedText)
        if best then
            Q.check(u ~= nil and u.use == best.use, L .. " (K1): Make put in the " .. what .. " the game's own menu offers at its best number (the game lists each state as its own option; the tab has one row)",
                "went in: " .. T.usedText .. " (" .. tostring(u and u.use) .. "); the game's options: " .. H.optsText(T.opts))
        else
            Q.skip(L .. " (K1): the " .. what .. " against the game's best option", "the game offers none here: " .. H.optsText(T.opts))
        end
        Q.check(u ~= nil and T.g ~= nil and T.g.use == u.use, L .. " (K1): the row's number is the game's number for the " .. what .. " that went in",
            "the row (" .. tostring(T.g and T.g.use) .. "), went in " .. T.usedText .. " (" .. tostring(u and u.use) .. ")")
    end
end
-- the same, and a NOTE of the tagged one (poison, favorite): the game's menu offers one option for the two
function C.judgeSame(what, tag)
    return function(T)
        C.judgeBest(what)(T)
        local L = T.spec.label
        local tagged = false
        for _, e in ipairs(T.used) do if e.tag == tag then tagged = true end end
        local n = 0
        for _, o in ipairs(T.opts) do if o.avail then n = n + 1 end end
        H.note(L .. ": the " .. tag .. " " .. what .. " went in: " .. tostring(tagged) .. "; the game's own menu offers " .. n
            .. " option(s) for the two (neither tells the " .. tag .. " one apart" .. (tag == "favorite" and ", neither skips it" or "") .. ")")
    end
end
-- K2, row by row: each tracked item is judged on its own by the game's own rules (in getItemsCanBeUse, frozen
-- allowed or not, needToBeCooked). An item the game takes sits in a lit row; one it refuses sits in no lit row and
-- a grey row of its type says why. The game's right-click menu shows one option per type and number, so a raw and
-- a cooked steak of the same number show as one option there (the first, refused); the tab lists each state as its
-- own row, which is right (Build and QA agreed Nov 25: do not copy the menu's merge).
function H.gameHas(r, base, it)
    for _, x in ipairs(H.gameList(r, base)) do if x == it then return true end end
    return false
end
function H.gameTakes(r, base, it)
    if not H.gameHas(r, base, it) then return false end
    local ok = true
    pcall(function()
        if instanceof(it, "Food") and it:isFrozen() and not r:isAllowFrozenItem() then ok = false end
        if not r:needToBeCooked(it) then ok = false end
    end)
    return ok
end
function H.rowOf(it)
    local s = H.cs()
    for _, g in ipairs((s and s.ingCache and s.ingCache.list) or {}) do
        for _, x in ipairs(g.items or {}) do if x == it then return g end end
    end
    return nil
end
function H.greyRows(ft)
    local o = {}
    local s = H.cs()
    for _, g in ipairs((s and s.ingCache and s.ingCache.list) or {}) do
        if g.ft == ft and g.why then o[#o + 1] = g end
    end
    return o
end
function C.rowGame(what)
    return function(T)
        local L = T.spec.label
        local ft = T.spec.ft
        local anyTaken = false
        for _, e in ipairs(T.items) do
            local takes = H.gameTakes(T.r, T.baseIt, e.it)
            local g = H.rowOf(e.it)
            local rowLit = g ~= nil and g.id ~= nil and H.lit(g.id)
            if takes then
                anyTaken = true
                Q.check(rowLit, L .. " (K2): the " .. e.tag .. " one, which the game takes, sits in a lit row",
                    "its row " .. tostring(g and g.id) .. " " .. (rowLit and "lit" or "grey or none") .. (g and g.why and (" (" .. g.why .. ")") or ""))
            elseif H.gameHas(T.r, T.baseIt, e.it) then
                -- the game lists it and refuses it: the tab greys a row and says why
                local greys = H.greyRows(ft)
                local why = {}
                for _, x in ipairs(greys) do why[#why + 1] = tostring(x.name) .. ": " .. tostring(x.why) end
                Q.check(not rowLit and #greys >= 1, L .. " (K2): the " .. e.tag .. " one, which the game lists and refuses, sits in no lit row and a grey row says why",
                    "its row " .. tostring(g and g.id) .. (rowLit and " lit" or "") .. "; grey rows " .. H.list(why))
            else
                -- the game does not list it at all (its own menu never shows it): the tab need only keep it out of a lit row
                Q.check(not rowLit, L .. " (K2): the " .. e.tag .. " one, which the game does not list, sits in no lit row",
                    "its row " .. tostring(g and g.id) .. (rowLit and " lit" or " none"))
            end
        end
        T.gameAvail = anyTaken
        Q.check(T.lit == anyTaken, L .. " (K2): the type's first row is lit exactly when the game takes " .. what,
            "the row " .. (T.lit and "lit" or "grey") .. (T.g and T.g.why and (" (" .. T.g.why .. ")") or "") .. "; the game's menu options: " .. H.optsText(T.opts))
        if not T.lit then T.stop = true; H.note(L .. ": the row is grey, Make is not pressed") end
    end
end
function C.judgeTag(what, tag)
    return function(T)
        local L = T.spec.label
        local u = T.used[1]
        Q.check(#T.used == 1 and u ~= nil and u.tag == tag, L .. " (K2): the " .. tag .. " " .. what .. " went in, the one the game takes",
            "went in: " .. T.usedText)
    end
end
function C.track(T, it, tag) if not it then T.skip = T.skip or ("the " .. tag .. " item could not be made"); return end; T.items[#T.items + 1] = { it = it, tag = tag } end
function C.c1()
    H.step(2, function() H.caseStart() end)
    C.leg({ label = "1a tomatoes (mouse)", how = "mouse", un = "Stew", baseFt = S.FT.pot, ft = S.FT.tomato,
        stage = function(T)
            T.baseIt = H.potWater()
            C.track(T, H.food(S.FT.tomato, "rotten"), "rotten")
            C.track(T, H.food(S.FT.tomato, "stale"), "stale")
            C.track(T, H.food(S.FT.tomato, "fresh"), "fresh")
        end, judge = C.judgeBest("tomato") })
    C.leg({ label = "1b tomatoes (pad)", how = "pad", un = "Stew", baseFt = S.FT.pot, ft = S.FT.tomato,
        stage = function(T)
            T.baseIt = H.potWater()
            C.track(T, H.food(S.FT.tomato, "rotten"), "rotten")
            C.track(T, H.food(S.FT.tomato, "fresh"), "fresh")
        end, judge = C.judgeBest("tomato") })
    C.leg({ label = "1c poisoned carrot (mouse)", how = "mouse", un = "Stew", baseFt = S.FT.pot, ft = S.FT.carrot,
        stage = function(T)
            T.baseIt = H.potWater()
            C.track(T, H.food(S.FT.carrot, "poison"), "poisoned")
            C.track(T, H.food(S.FT.carrot, "fresh"), "clean")
        end, judge = C.judgeSame("carrot", "poisoned") })
    C.leg({ label = "1d favorite tomato (pad)", how = "pad", un = "Stew", baseFt = S.FT.pot, ft = S.FT.tomato,
        stage = function(T)
            T.baseIt = H.potWater()
            C.track(T, H.food(S.FT.tomato, "fav"), "favorite")
            C.track(T, H.food(S.FT.tomato, "fresh"), "plain")
        end, judge = C.judgeSame("tomato", "favorite") })
    C.leg({ label = "1e raw and cooked steak, Sandwich (mouse)", how = "mouse", un = "Sandwich", baseFt = S.FT.bread, ft = S.FT.steak,
        stage = function(T)
            T.baseIt = H.give(S.FT.bread)
            C.track(T, H.food(S.FT.steak, "fresh"), "raw")
            C.track(T, H.food(S.FT.steak, "cooked"), "cooked")
        end, rowJudge = C.rowGame("the cooked steak"), judge = C.judgeTag("steak", "cooked") })
    C.leg({ label = "1f frozen and half-frozen carrot, Sandwich (pad)", how = "pad", un = "Sandwich", baseFt = S.FT.bread, ft = S.FT.carrot,
        stage = function(T)
            T.baseIt = H.give(S.FT.bread)
            C.track(T, H.food(S.FT.carrot, "frozen"), "frozen")
            C.track(T, H.food(S.FT.carrot, "half"), "half-frozen")
        end, rowJudge = C.rowGame("the half-frozen carrot"), judge = C.judgeTag("carrot", "half-frozen") })
    H.caseEnd("1 picks")
end

-- ===================================================================== 2. poison: the names and the card (K3)
function C.c2names(T, who)
    local L = "2 K3 (" .. who .. ")"
    local s = H.cs()
    local rows = 0
    for _, g in ipairs((s and s.ingCache and s.ingCache.list) or {}) do if g.ft == S.FT.berry then rows = rows + 1 end end
    local g = H.snapRow(S.FT.berry)
    local nP, nC = H.gameName(T.bP), H.gameName(T.bC)
    T[who] = { rows = rows, name = g and g.name, nP = nP, nC = nC }
    if nP == nC then
        Q.check(g ~= nil and g.name == nP, L .. ": the tab names the berries as the game's inventory names them for him",
            "the tab " .. tostring(g and g.name) .. "; the game " .. nP .. " (both)")
    else
        Q.check(rows >= 2, L .. ": the game names the poisonous and the safe berry apart, the tab tells them apart too (K1 picks either from one row)",
            rows .. " row(s) named " .. tostring(g and g.name) .. "; the game: " .. nP .. " / " .. nC)
    end
    -- the item card's poison against the game's own tooltip (measured, the same character)
    local riskP, riskC = H.fact(T.bP, ZeD.tr("UI_ZeD_Card_SicknessRisk")), H.fact(T.bC, ZeD.tr("UI_ZeD_Card_SicknessRisk"))
    local hP, hC = H.tipH(T.bP), H.tipH(T.bC)
    if hP == nil or hC == nil then
        Q.skip(L .. ": the card's poison against the game's tooltip", "the game's tooltip could not be measured")
    elseif hP == hC then
        Q.check(riskP == riskC, L .. ": the item card shows no poison the game's own tooltip does not show him (it is " .. H.n1(hP) .. " px for both berries)",
            "the card's Sickness risk: poisoned " .. tostring(riskP) .. ", clean " .. tostring(riskC))
    else
        H.note(L .. ": the game's tooltip differs for the poisoned berry (" .. H.n1(hP) .. " px, clean " .. H.n1(hC) .. " px): it shows him something; the card's Sickness risk "
            .. tostring(riskP) .. " / " .. tostring(riskC))
    end
    H.note(L .. ": the card prints the poison power " .. tostring(riskP) .. " as a percent (K17; poison power is not a percent)")
end
function C.c2()
    local T = { items = {} }
    H.step(2, function()
        H.caseStart()
        T.baseIt = H.give(S.FT.bowl)
        T.bP = H.food(S.FT.berry, "poison")
        T.bC = H.food(S.FT.berry, "fresh")
        if not (T.baseIt and T.bP and T.bC) then Q.skip("2 poison", "a bowl and two berries could not be given"); T.off = true; return end
        T.items = { { it = T.bP, tag = "poisonous" }, { it = T.bC, tag = "safe" } }
        H.herbSet(false)
        T.knew = H.herbKnown()
        if T.knew then H.note("2: he still knows berries with Herbalist taken off (a trait or a recipe the script cannot take): the 'without' half is read as it stands") end
        H.lootRefresh()
        H.rescan()
    end)
    H.toTab(T, "2 poison")
    H.pickDish(T, "FruitSalad", "2 poison")
    H.pickBase(T, "2 poison")
    H.wait(6000, function() return T.off or H.czone("cook:ing:" .. S.FT.berry) ~= nil end, function(ok)
        if T.off then return end
        if not Q.check(ok, "2 poison: the berries' row is listed", H.rowsText()) then T.off = true; return end
        if not T.knew then C.c2names(T, "without Herbalist") end
        H.herbSet(true)
        H.rescan()
    end)
    Q.waitMs(1500)
    H.wait(4000, function() return T.off or H.herbKnown() end, function(ok)
        if T.off then return end
        if not ok then Q.skip("2 K3 (with Herbalist)", "the Herbalist recipe did not take"); return end
        H.rescan()
    end)
    Q.waitMs(1500)
    H.step(2, function()
        if T.off or not H.herbKnown() then return end
        C.c2names(T, "with Herbalist")
        T.r = H.gameRecipe("FruitSalad", S.FT.bowl)
        for _, e in ipairs(T.items) do e.h0 = H.hunger(e.it) end
        T.go = H.padOn() and H.focusEl("cook:ing:" .. S.FT.berry)
        Q.check(T.go, "2 poison (pad): the pad's focus lands on the berries' row", "on " .. tostring(H.focusedId()))
    end)
    H.tapA(function() return T.go and not T.off end)
    H.step(4, function()
        if T.off or not T.go then return end
        T.go2 = H.planCount(S.FT.berry) == 1 and H.focusEl("cook:make")
        Q.check(T.go2, "2 poison (pad): A on the row puts one berry in, the focus on Make", "plan " .. H.planFts() .. ", on " .. tostring(H.focusedId()))
    end)
    H.tapA(function() return T.go2 and not T.off end)
    H.step(1, function() T.t0 = getTimestampMs() end)
    H.wait(30000, function() return T.off or not T.go2 or (H.qlen() == 0 and getTimestampMs() - (T.t0 or 0) > 300) end, function(ok)
        H.padOff()
        if T.off or not T.go2 then return end
        local o = {}
        for _, e in ipairs(T.items) do
            local now = H.hunger(e.it)
            if H.gone(e.it) or H.where(e.it) ~= H.inv() or (e.h0 and now and math.abs(now - e.h0) > 0.0001) then o[#o + 1] = e.tag end
        end
        local opts = H.gameOpts(T.r, T.baseIt, S.FT.berry)
        Q.check(#o == 1, "2 poison (pad): Make by the pad puts one berry in", "went in: " .. H.list(o))
        H.note("2 K1/K3: the " .. H.list(o) .. " berry went in by Make; the game's own menu offers " .. #opts .. " option(s) for the two ("
            .. H.optsText(opts) .. "), named for him " .. H.gameName(T.bP) .. " / " .. H.gameName(T.bC))
    end)
    H.caseEnd("2 poison")
end

-- ===================================================================== 3. pad B during Make (K5)
function C.where(it, crate)
    if H.gone(it) then return "used up" end
    local c = H.where(it)
    if crate and c == crate.inv then return "the crate" end
    if c == H.inv() then return "his bags" end
    return H.ctype(c)
end
function C.c3()
    local T = {}
    H.step(2, function()
        H.caseStart()
        T.crate = H.mkCrate()
        if not T.crate then Q.skip("3 pad B (K5)", "no free square beside him took a crate"); T.off = true; return end
        T.baseIt = H.potWater()
        T.tCrate = H.food(S.FT.tomato, "fresh", T.crate.inv)
        T.carrot = H.food(S.FT.carrot, "fresh")
        if not (T.baseIt and T.tCrate and T.carrot) then Q.skip("3 pad B (K5)", "the pot, the crate's tomato or the carrot could not be given"); T.off = true; return end
        H.lootRefresh()
        H.rescan()
    end)
    H.toTab(T, "3 pad B")
    H.pickDish(T, "Stew", "3 pad B")
    H.pickBase(T, "3 pad B")
    H.wait(6000, function() return T.off or (H.czone("cook:ing:" .. S.FT.tomato) ~= nil and H.czone("cook:ing:" .. S.FT.carrot) ~= nil) end, function(ok)
        if T.off then return end
        if not ok then Q.skip("3 pad B (K5)", "the crate's tomato is not offered (the crate is not in the game's container list here): " .. H.rowsText()); T.off = true; return end
        T.go = H.padOn() and H.focusEl("cook:ing:" .. S.FT.tomato)
        Q.check(T.go, "3 pad B: the pad's focus lands on the tomato (in the crate)", "on " .. tostring(H.focusedId()))
    end)
    H.tapA(function() return T.go and not T.off end)
    H.step(4, function() if not T.off and T.go then T.go = H.focusEl("cook:ing:" .. S.FT.carrot) end end)
    H.tapA(function() return T.go and not T.off end)
    H.step(4, function()
        if T.off or not T.go then return end
        T.go = H.planCount(S.FT.tomato) == 1 and H.planCount(S.FT.carrot) == 1 and H.focusEl("cook:make")
        Q.check(T.go, "3 pad B: A, A put the tomato and the carrot in, the focus on Make", "plan " .. H.planFts() .. ", on " .. tostring(H.focusedId()))
    end)
    H.tapA(function() return T.go and not T.off end)
    H.step(1, function() if T.go and not T.off then T.kinds0 = H.qkinds(); H.note("3 pad B: Make queued " .. T.kinds0) end end)
    H.wait(12000, function() return T.off or not T.go or H.head() == "ZeD_CookAdd" end, function(ok)
        if T.off or not T.go then return end
        T.armB = ok and H.focusEl("cook:make")
        if not ok then Q.skip("3 pad B (K5): B while an add runs", "no add came to the head of the queue in 12 s (" .. H.qkinds() .. ")") end
    end)
    H.tapB(function() return T.armB and not T.off end)
    H.step(10, function()
        if T.off or not T.armB then return end
        H.padOff()
        Q.check(H.qlen() == 0, "3 pad B (K5): B with no list open stops Make: the queue empties (the game's B stops the action and its queue)",
            "left " .. H.qkinds())
        T.zedWhere = C.where(T.tCrate, T.crate)
        T.zedOut = (T.zedWhere == "his bags") and 1 or 0
        H.note("3 pad B (K5): after B the crate's tomato is in " .. T.zedWhere .. ", the carrot " .. C.where(T.carrot) .. ", the pot now "
            .. H.ft(T.baseIt) .. "; the rest of the dish and the move back to the crate went with the queue")
        Q.check(H.drawn(), "3 pad B: the tab still draws after B", "tab " .. tostring(RT.cw() and RT.cw()._activeTab))
        -- the game's own menu, from the crate, stopped the same way
        T.tCrate2 = H.food(S.FT.tomato, "fresh", T.crate.inv)
        T.pot2 = (H.ft(T.baseIt) == S.FT.pot and H.where(T.baseIt) == H.inv()) and T.baseIt or H.potWater()
        T.r = H.gameRecipe("Stew", S.FT.pot)
        H.lootRefresh()
        T.gameGo = T.tCrate2 ~= nil and T.pot2 ~= nil and T.r ~= nil
            and pcall(ISInventoryPaneContextMenu.onAddItemInEvoRecipe, T.r, T.pot2, T.tCrate2, S.pn)
        if T.gameGo then H.note("3 the game's own add from the crate queued " .. H.qkinds()) end
    end)
    H.wait(12000, function() return T.off or not T.gameGo or H.head() == "ISAddItemInRecipe" end, function(ok)
        if T.off or not T.gameGo then return end
        if not ok then T.gameGo = false; Q.skip("3 pad B (K5): the game's own path stopped the same way", "its add never came to the head (" .. H.qkinds() .. ")"); return end
        pcall(stopDoingActionThatCanBeCancelled, S.p)
    end)
    H.step(10, function()
        if T.off or not T.gameGo then return end
        T.gameWhere = C.where(T.tCrate2, T.crate)
        T.gameOut = (T.gameWhere == "his bags") and 1 or 0
        H.note("3 pad B: the game's own add stopped by the game's B (stopDoingActionThatCanBeCancelled): its tomato is in " .. T.gameWhere .. ", the queue " .. H.qkinds())
        Q.check(T.zedOut <= T.gameOut, "3 pad B (K5): after B, ZeD's Make leaves no more out of the crate than the game's own menu does",
            "ZeD: the crate's tomato in " .. tostring(T.zedWhere) .. "; the game: in " .. tostring(T.gameWhere))
    end)
    H.caseEnd("3 pad B")
end

-- ===================================================================== 4. failed starts (K6, K7, K9)
function C.c4limit()
    local T = {}
    H.step(2, function()
        H.legClean()
        T.potIt = H.give(S.FT.pastaPot)
        T.panIt = H.give(S.FT.pastaPan)
        T.baseIt = T.potIt
        for _ = 1, 6 do H.food(S.FT.tomato, "fresh") end
        T.lPot, T.lPan = H.dishLabel("PastaPot"), H.dishLabel("PastaPan")
        if not (T.potIt and T.panIt) then Q.skip("4 K7", "a pasta pot and a saucepan of pasta water could not be given"); T.off = true; return end
        if T.lPot ~= T.lPan then Q.skip("4 K7", "the game names the pasta pot's and the saucepan's dishes apart here (" .. T.lPot .. " / " .. T.lPan .. "): one is never the other's base"); T.off = true; return end
        T.rPot, T.rPan = H.gameRecipe("PastaPot", S.FT.pastaPot), H.gameRecipe("PastaPan", S.FT.pastaPan)
        H.lootRefresh()
        H.rescan()
    end)
    H.toTab(T, "4 K7")
    H.pickDish(T, "PastaPot", "4 K7")
    H.pickBase(T, "4 K7", "potIt")
    H.wait(6000, function() return T.off or H.czone("cook:ing:" .. S.FT.tomato) ~= nil end, function(ok)
        if T.off then return end
        if not Q.check(ok, "4 K7: the tomato row is listed for the pasta pot", H.rowsText()) then T.off = true end
    end)
    for _ = 1, 5 do H.step(3, function() if not T.off then H.cpress("cook:ing:" .. S.FT.tomato) end end) end
    H.step(3, function()
        if T.off then return end
        T.maxPot = nil
        pcall(function() T.maxPot = T.rPot:getMaxItems() end)
        if not Q.check(H.planN() == 5, "4 K7: five tomatoes planned on the pasta pot (it takes " .. tostring(T.maxPot) .. ")", "plan " .. H.planFts()) then T.off = true end
    end)
    H.pickBase(T, "4 K7", "panIt")
    H.step(4, function()
        if T.off then return end
        pcall(function() T.maxPan = T.rPan:getMaxItems() end)
        T.n = H.planN()
        T.lit = H.lit("cook:make")
        Q.check(not (T.lit and T.n > (T.maxPan or 99)), "4 K7: with " .. T.n .. " planned on a saucepan that takes " .. tostring(T.maxPan) .. ", Make is not lit (the game's own menu takes no more than that)",
            "Make " .. (T.lit and "lit" or "grey") .. ", plan " .. H.planFts())
        if T.lit then
            T.pan0 = H.ft(T.panIt)
            T.dishFt = H.dishFtOf("PastaPan", S.FT.pastaPan)
            T.dish0 = H.count(T.dishFt)
            T.t0 = getTimestampMs()
            H.cpress("cook:make")
            T.adds = H.qadds()
            T.kinds = H.qkinds()
            T.maxQ = H.qlen()
        end
    end)
    H.wait(45000, function()
        if T.off or not T.lit then return true end
        local n = H.qlen()
        if n > (T.maxQ or 0) then T.maxQ = n end
        return n == 0 and getTimestampMs() - (T.t0 or 0) > 300
    end, function(ok)
        if T.off or not T.lit then return end
        local dish = H.newest(T.dishFt)
        local ex = 0
        pcall(function() local l = dish:getExtraItems(); ex = l and l:size() or 0 end)
        local said = H.saidSince(T.t0)
        H.note("4 K6/K7: Make queued " .. tostring(T.adds) .. " adds (" .. tostring(T.kinds) .. "); made " .. (H.count(T.dishFt) - (T.dish0 or 0))
            .. " " .. tostring(T.dishFt) .. " holding " .. ex .. " of " .. T.n .. " planned; tomatoes left " .. H.count(S.FT.tomato) .. "; words " .. H.list(said))
        Q.check(ex >= T.n or #said > 0, "4 K6: what Make leaves out of the dish is said (a refused start clears the queue silently)",
            "planned " .. T.n .. ", in the dish " .. ex .. ", words: " .. H.list(said))
    end)
    H.step(2, function() H.legClean() end)
end
function C.c4twice(how)
    local T = {}
    local L = "4 K9 Make twice (" .. how .. ")"
    H.step(2, function()
        H.legClean()
        T.baseIt = H.potWater()
        T.t1 = H.food(S.FT.tomato, "fresh")
        T.t2 = H.food(S.FT.tomato, "fresh")
        T.dishFt = H.dishFtOf("Stew", S.FT.pot)
        if not (T.baseIt and T.t1 and T.t2 and T.dishFt) then Q.skip(L, "a pot and two tomatoes could not be given"); T.off = true; return end
        H.lootRefresh()
        H.rescan()
    end)
    H.toTab(T, L)
    H.pickDish(T, "Stew", L)
    H.pickBase(T, L)
    H.wait(6000, function() return T.off or H.czone("cook:ing:" .. S.FT.tomato) ~= nil end, function(ok)
        if T.off then return end
        if not Q.check(ok, L .. ": the tomato row is listed", H.rowsText()) then T.off = true; return end
        H.cpress("cook:ing:" .. S.FT.tomato)
    end)
    H.step(3, function()
        if T.off then return end
        if not Q.check(H.planCount(S.FT.tomato) == 1 and H.lit("cook:make"), L .. ": one tomato planned, Make lit", "plan " .. H.planFts()) then T.off = true; return end
        T.dish0 = H.count(T.dishFt)
        T.t0 = getTimestampMs()
        if how == "pad" then
            T.go = H.padOn() and H.focusEl("cook:make")
            Q.check(T.go, L .. ": the pad's focus lands on Make", "on " .. tostring(H.focusedId()))
        else
            H.cpress("cook:make")
        end
    end)
    if how == "pad" then
        H.tapA(function() return T.go and not T.off end)
        H.tapA(function() return T.go and not T.off and H.focusEl("cook:make") end)
    else
        H.step(2, function() if not T.off then T.lit2 = H.lit("cook:make"); H.cpress("cook:make") end end)
    end
    H.step(1, function()
        if T.off then return end
        T.adds = H.qadds()
        T.kinds = H.qkinds()
        Q.check(T.adds <= 1, L .. ": Make pressed twice queues the dish once (the game's own menu shuts on the first press)",
            T.adds .. " adds queued: " .. T.kinds .. (T.lit2 ~= nil and ("; Make " .. (T.lit2 and "still lit" or "grey") .. " at the second press") or ""))
    end)
    H.wait(40000, function() return T.off or (H.qlen() == 0 and getTimestampMs() - (T.t0 or 0) > 300) end, function()
        H.padOff()
        if T.off then return end
        local dishes = {}
        for _, it in ipairs(H.all()) do
            if H.ft(it) == T.dishFt and not S.found.inv0[it] then
                local ex = 0
                pcall(function() local l = it:getExtraItems(); ex = l and l:size() or 0 end)
                dishes[#dishes + 1] = ex
            end
        end
        local said = H.saidSince(T.t0)
        local used = 0
        for _, it in ipairs({ T.t1, T.t2 }) do if H.gone(it) then used = used + 1 end end
        H.note(L .. " (K6/K9): made " .. #dishes .. " stew(s) holding " .. H.list(dishes) .. "; tomatoes used " .. used .. " of 2; words " .. H.list(said))
        Q.check(#dishes == 1 and used <= 1, L .. ": one stew of one tomato, as planned", #dishes .. " stews holding " .. H.list(dishes) .. ", " .. used .. " tomatoes used")
    end)
    H.step(2, function() H.legClean() end)
end
function C.c4()
    H.step(2, function() H.caseStart() end)
    C.c4limit()
    C.c4twice("mouse")
    C.c4twice("pad")
    H.caseEnd("4 starts")
end

-- ===================================================================== 5. seasoning (K8)
function C.c5dish(un)
    local T = {}
    local L = "5 K8 " .. un
    H.step(2, function()
        H.legClean()
        T.baseIt = H.potWater()
        T.c1 = H.food(S.FT.carrot, "fresh")
        H.food(S.FT.carrot, "fresh")
        H.give(S.FT.salt)
        H.give(S.FT.pepper)
        T.r = H.gameRecipe(un, S.FT.pot)
        T.dishFt = H.dishFtOf(un, S.FT.pot)
        if not (T.baseIt and T.c1 and T.r) then Q.skip(L, "the pot, the carrot or the game's recipe is missing"); T.off = true; return end
        H.lootRefresh()
        H.rescan()
    end)
    H.toTab(T, L)
    H.pickDish(T, un, L)
    H.pickBase(T, L)
    H.wait(6000, function() return T.off or H.czone("cook:ing:" .. S.FT.carrot) ~= nil end, function(ok)
        if T.off then return end
        if not Q.check(ok, L .. ": the carrot row is listed", H.rowsText()) then T.off = true; return end
        T.zed0 = H.spiceRows()
        local game0 = {}
        for _, o in ipairs(H.gameOpts(T.r, T.baseIt, nil)) do if o.spice then game0[H.ft(o.item)] = true end end
        Q.check(H.sameSet(T.zed0, game0), L .. ": on the empty pot the tab's seasoning is the game's",
            "the tab " .. H.setText(T.zed0) .. "; the game " .. H.setText(game0))
        -- one carrot in by the game's own action, then the game's seasoning for the dish
        T.t0 = getTimestampMs()
        T.go = pcall(function() ISTimedActionQueue.add(ISAddItemInRecipe:new(S.p, T.r, T.baseIt, T.c1)) end)
    end)
    H.wait(20000, function() return T.off or not T.go or (H.qlen() == 0 and getTimestampMs() - (T.t0 or 0) > 300) end, function()
        if T.off or not T.go then return end
        T.dish = H.newest(T.dishFt)
        if not T.dish then Q.skip(L .. ": the game's seasoning after the first ingredient", "the game's own add made no " .. tostring(T.dishFt)); T.off = true; return end
        H.rescan()
    end)
    Q.waitMs(1500)
    H.step(2, function()
        if T.off then return end
        local game1 = {}
        for _, it in ipairs(H.gameList(T.r, T.dish)) do if H.isSpice(it) then game1[H.ft(it)] = true end end
        local s = H.cs()
        T.zed1 = {}
        if s and s.dish == T.dishKey then T.zed1 = H.spiceRows() end
        local dl = H.dishesText()
        local any = false
        for _ in pairs(game1) do any = true end
        Q.check((not any) or H.sameSet(game1, T.zed1), L .. ": the seasoning the game offers the dish after its first ingredient is offered by the tab too",
            "the game: " .. H.setText(game1) .. "; the tab: " .. H.setText(T.zed1) .. " (dishes offered: " .. dl .. "; the tab starts dishes from scratch only, asked of the empty pot)")
    end)
    H.step(2, function() H.legClean() end)
end
function C.c5control()
    local T = {}
    local L = "5 K8 Sandwich (control, pad)"
    H.step(2, function()
        H.legClean()
        T.baseIt = H.give(S.FT.bread)
        H.food(S.FT.carrot, "fresh")
        H.give(S.FT.salt)
        H.give(S.FT.pepper)
        T.r = H.gameRecipe("Sandwich", S.FT.bread)
        if not (T.baseIt and T.r) then Q.skip(L, "bread slices or the game's recipe is missing"); T.off = true; return end
        H.lootRefresh()
        H.rescan()
    end)
    H.toTab(T, L)
    H.pickDish(T, "Sandwich", L)
    H.pickBase(T, L)
    H.wait(6000, function() return T.off or H.czone("cook:ing:" .. S.FT.salt) ~= nil end, function(ok)
        if T.off then return end
        local zed, game = H.spiceRows(), {}
        for _, o in ipairs(H.gameOpts(T.r, T.baseIt, nil)) do if o.spice then game[H.ft(o.item)] = true end end
        Q.check(ok and H.sameSet(zed, game), L .. ": empty bread slices take seasoning (CanAddSpicesEmpty): the tab's seasoning is the game's",
            "the tab " .. H.setText(zed) .. "; the game " .. H.setText(game))
        if not ok then T.off = true; return end
        T.go = H.padOn() and H.focusEl("cook:ing:" .. S.FT.salt)
        Q.check(T.go, L .. ": the pad's focus lands on Salt", "on " .. tostring(H.focusedId()))
    end)
    H.tapA(function() return T.go and not T.off end)
    H.step(4, function()
        H.padOff()
        if T.off or not T.go then return end
        local sp = false
        for _, e in ipairs(H.plan()) do if e.ft == S.FT.salt and e.spice then sp = true end end
        Q.check(sp and H.planN() == 0, L .. ": A on Salt puts it under Seasoning (it does not count toward the limit)", "plan " .. H.planFts())
    end)
    H.step(2, function() H.legClean() end)
end
function C.c5()
    H.step(2, function() H.caseStart() end)
    C.c5dish("Stew")
    C.c5dish("Soup")
    C.c5control()
    H.caseEnd("5 seasoning")
end

-- ===================================================================== 6. the half card (K11)
function C.c6look(T, label)
    local r = S.ckRect
    local s = H.cs()
    if not (r and s and getTimestampMs() - r.t < 1000) then Q.skip(label, "the tab's rectangle was not read"); return end
    -- (the pane's real width: since Build's K11 fix the 220 card stacks the list over the dish pane, each full width
    -- (CK.layout); measured from the layout the tab drew, the fixed 240u list only when it has none)
    local lay = nil
    pcall(function() lay = ZeD.CookingTab.layout(r.x, r.y, r.w, r.h or ZeD.T.px(400)) end)
    local listW = ZeD.T.px((ZeD.CraftingCore and ZeD.CraftingCore.PANE_W_SPLIT) or 240)
    local rw = r.w - listW - ZeD.T.px(1)
    if type(lay) == "table" and lay.dish and lay.list then listW, rw = lay.list.w, lay.dish.w end
    local bad, plans = {}, 0
    for _, z in ipairs(s.zones or {}) do
        if z.planRow then
            plans = plans + 1
            if (z.w or 0) <= 0 or z.x < r.x - 1 or z.x + z.w > r.x + r.w + 1 then bad[#bad + 1] = z.id .. " " .. math.floor(z.x) .. "+" .. math.floor(z.w or 0) end
        end
    end
    local hs = S.hungerSeen
    local hungerOK = hs ~= nil and getTimestampMs() - hs.t < 1000 and (hs.w or 0) > 0 and hs.x >= r.x - 1 and hs.x + hs.w <= r.x + r.w + 1
    Q.check(rw > 0, label .. ": the dish pane has room (its width is positive)", "the tab " .. math.floor(r.w) .. " px, the list " .. listW .. " px, the dish pane " .. math.floor(rw) .. " px")
    Q.check(plans == H.planN() and #bad == 0, label .. ": every planned row (Remove) draws inside the tab", plans .. " rows stamped for " .. H.planN() .. " planned; out " .. H.list(bad))
    Q.check(hungerOK, label .. ": the Hunger row draws inside the tab", hs and (math.floor(hs.x) .. "+" .. math.floor(hs.w or 0) .. " px, " .. (getTimestampMs() - hs.t) .. " ms ago") or "never drawn")
    local mk = H.czone("cook:make")
    H.note(label .. ": Make " .. (mk and ((mk.disabled and "grey" or "lit") .. " at " .. math.floor(mk.x) .. "+" .. math.floor(mk.w)) or "not drawn"))
    RT.bounds(Q, label)
end
function C.c6()
    local T = {}
    H.step(2, function()
        H.caseStart()
        T.baseIt = H.potWater()
        H.food(S.FT.tomato, "fresh")
        H.food(S.FT.carrot, "fresh")
        H.lootRefresh()
        H.rescan()
    end)
    H.toTab(T, "6 half")
    H.pickDish(T, "Stew", "6 half")
    H.pickBase(T, "6 half")
    H.wait(6000, function() return T.off or (H.czone("cook:ing:" .. S.FT.tomato) ~= nil and H.czone("cook:ing:" .. S.FT.carrot) ~= nil) end, function(ok)
        if T.off then return end
        if not Q.check(ok, "6 half: the tomato and carrot rows are listed", H.rowsText()) then T.off = true; return end
        H.cpress("cook:ing:" .. S.FT.tomato)
    end)
    H.step(3, function() if not T.off then H.cpress("cook:ing:" .. S.FT.carrot) end end)
    Q.waitMs(800)
    H.step(2, function()
        if T.off then return end
        if H.isFull() then C.c6look(T, "6 K11 the full card (480)")
        else H.note("6: the Cooking tab stands at " .. math.floor(RT.cw()._drawerEffW or 0) .. " px here, not the full card") end
    end)
    H.halfOn(T)
    Q.waitMs(800)
    H.step(2, function() if not T.off and T.half then C.c6look(T, "6 K11 the half card (220)") end end)
    H.shot("ck_half_" .. H.sizeTag(), "the half card (220): the Cooking tab with a tomato and a carrot planned in a stew", function() return T.half == true end)
    -- Remove at the half card, by the mouse, then by the pad
    H.step(2, function()
        if T.off or not T.half then return end
        T.n0 = H.planN()
        local z = H.czone("cook:plan:1")
        T.mz = z and (z.w or 0) > 0
        if T.mz then H.cpress("cook:plan:1") end
    end)
    H.step(3, function()
        if T.off or not T.half then return end
        Q.check(T.mz and H.planN() == T.n0 - 1, "6 K11 the half card: a click on a planned row takes it out (Remove)", "row drawn " .. tostring(T.mz) .. ", plan " .. H.planFts())
        T.go = H.padOn() and H.focusEl("cook:plan:1")
        T.n1 = H.planN()
        Q.check(T.go, "6 K11 the half card: the pad's focus lands on the planned row", "on " .. tostring(H.focusedId()))
    end)
    H.tapA(function() return T.go and T.half and not T.off end)
    H.step(4, function()
        H.padOff()
        if T.off or not T.half or not T.go then return end
        Q.check(H.planN() == (T.n1 or 0) - 1, "6 K11 the half card: A on a planned row takes it out (Remove)", "plan " .. H.planFts())
        H.cpress("cook:ing:" .. S.FT.tomato)
    end)
    H.step(3, function() if not T.off and T.half then H.sizeSet("large") end end)
    Q.waitMs(1500)
    H.step(2, function() if not T.off and T.half then C.c6look(T, "6 K11 the half card, Large text") end end)
    H.shot("ck_half_large_" .. H.sizeTag(), "the half card (220), Large text, a tomato planned", function() return T.half == true end)
    H.step(2, function() H.sizeBack(); H.halfBack() end)
    Q.waitMs(1000)
    H.caseEnd("6 half")
end

-- ===================================================================== 7. cooking state (K12, K13)
function H.cookRead(it)
    local o = { m = H.worldMin() }
    pcall(function()
        o.ct = it:getCookingTime(); o.toCook = it:getMinutesToCook(); o.toBurn = it:getMinutesToBurn()
        o.heat = it:getHeat(); o.cooked = it:isCooked(); o.burnt = it:isBurnt(); o.frozen = it:isFrozen()
    end)
    return o
end
function H.cookText(o) return "cooking time " .. H.n1(o.ct) .. " of " .. H.n1(o.toCook) .. " (burns at " .. H.n1(o.toBurn) .. "), heat " .. H.n2(o.heat) end
-- queue: ZeD's minutes left (the key it draws them with) against the food's own cooking time over the game clock
function C.rate(T, label, key, food)
    H.wait(45000, function()
        if T.off or T.noHeat then return true end
        local it = food()
        local o = it and H.cookRead(it)
        return o ~= nil and (o.heat or 0) > 1.6 and (o.ct or 0) > 0 and H.seen(key, 1500) ~= nil
    end, function(ok)
        if T.off or T.noHeat then return end
        local it = food()
        T.r0 = it and H.cookRead(it)
        T.z0 = H.seen(key, 1500)
        if not ok then
            T.rateOff = true
            Q.skip(label, "the food did not heat with ZeD's minutes drawn in 45 s on fast-forward (" .. (T.r0 and H.cookText(T.r0) or "no food") .. ", ZeD drew "
                .. tostring(T.z0) .. ")")
        end
    end)
    -- the truth: the game minutes the food really takes from that moment to its next mark (cooked, or burnt once
    -- cooked), on the game clock; ZeD's number must land within 20 percent of it (3 minutes at the least). The
    -- cooking time does not grow one per game minute (the heat speeds it), so a straight count was never the test.
    H.step(1, function()
        if T.off or T.noHeat or T.rateOff or not T.r0 then return end
        T.toBurnLeg = (T.r0.cooked or (type(T.r0.ct) == "number" and type(T.r0.toCook) == "number" and T.r0.ct >= T.r0.toCook)) and true or false
        T.mid = nil
    end)
    H.wait(120000, function()
        if T.off or T.noHeat or T.rateOff or not T.r0 then return true end
        local r = H.cookRead(food())
        if not T.mid and r.m - T.r0.m >= 8 then T.mid = r; T.zmid = H.seen(key, 1500) end
        if T.toBurnLeg then return r.burnt == true end
        return r.cooked == true or (type(r.ct) == "number" and type(r.toCook) == "number" and r.ct >= r.toCook)
    end, function(ok)
        if T.off or T.noHeat or T.rateOff or not T.r0 then T.rateOff = nil; return end
        local r1 = H.cookRead(food())
        if not (type(r1.ct) == "number" and type(T.r0.ct) == "number" and type(T.r0.toCook) == "number" and type(T.r0.toBurn) == "number") then
            Q.skip(label, "the food's cooking time could not be read"); return
        end
        local mark = T.toBurnLeg and "burnt" or "cooked"
        if not ok then
            Q.skip(label, "the food was not " .. mark .. " in 120 s on fast-forward (" .. H.cookText(r1) .. " after " .. H.n1(r1.m - T.r0.m) .. " game minutes)")
            return
        end
        local real = r1.m - T.r0.m
        local z = tonumber(T.z0)
        local slope = T.mid and ((T.mid.ct - T.r0.ct) / (T.mid.m - T.r0.m)) or nil
        Q.check(z ~= nil and math.abs(z - real) <= math.max(3, 0.2 * real), label .. ": ZeD's '" .. tostring(T.z0) .. " min left' is within 20 percent of the game minutes the food really took to be " .. mark,
            H.cookText(T.r0) .. "; " .. mark .. " after " .. H.n1(real) .. " game minutes; ZeD said " .. tostring(T.z0) .. " m"
            .. (slope and ("; the first 8 minutes grew " .. H.n2(slope) .. " a minute") or ""))
        if T.mid then
            H.note(label .. ": 8 minutes in, ZeD said " .. tostring(T.zmid) .. " m and the food took " .. H.n1(r1.m - T.mid.m) .. " more")
        end
    end)
end
function C.c7fire()
    local T = {}
    H.step(2, function()
        H.legClean()
        local sq = H.firstFree(S.RING2)
        T.f = sq and H.mkFire(sq)
        if not T.f then Q.skip("7 K12 campfire", "no free square or no campfire system"); T.off = true end
    end)
    H.wait(5000, function() return T.off or H.fireIso(T.f) ~= nil end, function(ok)
        if T.off then return end
        if not ok then Q.skip("7 K12 campfire", "the campfire system made no fire object"); T.off = true; return end
        local so = H.fireServer(T.f)
        if so then pcall(function() so:addFuel(240); so:lightFire() end) end
        local c = nil
        pcall(function() c = H.fireIso(T.f):getContainer() end)
        T.steak = c and H.giveTo(c, S.FT.steak)
        if not T.steak then Q.skip("7 K12 campfire", "the campfire has no container for a steak"); T.off = true; return end
        H.zcall(function() S.OC.open(S.p, "fire", H.fireIso(T.f)) end)
        H.speed(3)
    end)
    C.rate(T, "7 K12 campfire (the fire card's On the fire row)", "UI_ZeD_ObjCard_MinLeft", function() return T.steak end)
    H.step(2, function() H.speed(1); pcall(function() ZeD_WorldWindow.closeObjectCard(S.pn) end) end)
end
function C.c7stove()
    local T = {}
    H.step(2, function()
        H.legClean()
        local gsq = H.firstFree(S.RING2)
        T.gen = gsq and H.mkGen(gsq)
        local ssq = H.firstFree(S.NEAR)
        T.stove = ssq and H.mkStove(ssq)
        if not (T.gen and T.stove) then Q.skip("7 K12 range", "no room for a generator and a range beside him"); T.off = true; return end
        H.lootRefresh()
    end)
    H.wait(8000, function() return T.off or H.powered(T.stove.obj) end, function(ok)
        if T.off then return end
        if not ok then Q.skip("7 K12 range", "the generator gave the range no power"); T.off = true; return end
        local o = T.stove.obj
        pcall(function() o:setMaxTemperature(100) end)
        pcall(function() if not o:Activated() then o:Toggle() end end)
        T.steak = H.giveTo(o:getContainer(), S.FT.steak)
        H.zcall(function() S.ST.open(S.p, o) end)
        S.boundByUs = true
        H.speed(3)
    end)
    C.rate(T, "7 K12 range at 100 (the Craft tab's In the oven row)", "UI_ZeD_Appliance_MinShort", function() return T.steak end)
    H.step(2, function()
        if T.off then return end
        pcall(function() T.stove.obj:setMaxTemperature(300) end)
        T.steak2 = H.giveTo(T.stove.obj:getContainer(), S.FT.steak)
    end)
    C.rate(T, "7 K12 range at 300 (the Craft tab's In the oven row)", "UI_ZeD_Appliance_MinShort", function() return T.steak2 end)
    -- K13: the hot steak taken out into the bags, its item card opened
    H.step(2, function()
        H.speed(1)
        if T.off then Q.skip("7 K13 a hot dish off the heat", "no hot steak: the range was not staged"); return end
        T.hot = (T.steak2 and H.cookRead(T.steak2).heat or 0) > 1.6 and T.steak2 or T.steak
        local it = T.hot
        if not it then T.off = true; return end
        pcall(function() it:getContainer():Remove(it) end)
        pcall(function() H.inv():AddItem(it) end)
        if H.where(it) ~= H.inv() then Q.skip("7 K13", "the hot steak could not be taken into his bags"); T.off = true; return end
        pcall(function() S.ST.unbind(S.p) end)
        S.boundByUs = nil
        T.card = it
    end)
    H.openCard(T, "card", "7 K13 the hot steak off the heat")
    Q.waitMs(1200)
    H.step(2, function()
        if T.off or not T.cardCard then return end
        local it = T.card
        local o = H.cookRead(it)
        local game = false
        pcall(function() game = it:isIsCookable() and not it:isFrozen() and it:getHeat() > 1.6 end)
        local act = S.IAM.getActiveAction(it)
        local zed = act ~= nil and act.kind == "cooking"
        Q.check(zed == game, "7 K13: off the heat, the item card reads COOKING exactly when the game's own inventory pane does (cookable, not frozen, heat above 1.6)",
            "the card " .. (zed and (tostring(act.label) .. " " .. tostring(act.timeStr)) or "no cooking band") .. "; the game's pane " .. (game and "Cooking/Burning" or "nothing") .. "; " .. H.cookText(o))
        T.k0 = o
        H.speed(3)
    end)
    H.wait(20000, function() return T.off or not T.cardCard or H.worldMin() - T.k0.m >= 6 end, function()
        H.speed(1)
        if T.off or not T.cardCard then return end
        local o = H.cookRead(T.card)
        local act = S.IAM.getActiveAction(T.card)
        H.note("7 K13: off the heat for " .. H.n1(o.m - T.k0.m) .. " game minutes the cooking time went " .. H.n1(T.k0.ct) .. " -> " .. H.n1(o.ct)
            .. " (heat " .. H.n2(T.k0.heat) .. " -> " .. H.n2(o.heat) .. "); the card now " .. (act and (tostring(act.label) .. " " .. tostring(act.timeStr)) or "no band")
            .. ((o.toBurn or 0) <= (o.toCook or 0) and "; burns no later than it cooks: the burn span reads 1 (K13's 0 min)" or ""))
        H.cardShut()
    end)
end
function C.c7()
    H.step(2, function() H.caseStart() end)
    C.c7fire()
    C.c7stove()
    H.caseEnd("7 heat")
end

-- ===================================================================== 8. appliances (K14)
function C.c8tank(T, delta)
    local o = T.bbq and T.bbq.obj
    if not o then return false end
    local tank = nil
    pcall(function() o:removePropaneTank() end)
    pcall(function() tank = instanceItem("Base.PropaneTank") end)
    if not tank then return false end
    pcall(function() tank:setUsedDelta(delta) end)
    pcall(function() tank:setCurrentUsesFloat(delta) end)
    pcall(function() o:setPropaneTank(tank) end)
    T.tank = tank
    local d = nil
    pcall(function() d = tank:getCurrentUsesFloat() end)
    T.delta = d or delta
    S.tankSeen = nil
    return true
end
function C.c8read(T, label)
    H.wait(5000, function()
        if T.off then return true end
        local c = ZeD_WorldWindow.getObjectCard(S.pn)
        local d = c and c.entry and c.entry.t and c.entry.t.d
        local fuel = H.call(T.bbq.obj, "getFuelAmount") or -1
        return T.off or (d ~= nil and math.abs((d.fuel or -9) - fuel) <= 1 and S.tankSeen ~= nil and getTimestampMs() - S.tankSeen.t < 800)
    end, function(ok)
        if T.off then return end
        local fuel = H.call(T.bbq.obj, "getFuelAmount")
        local g = S.tankSeen and S.tankSeen.v
        if not ok or g == nil then Q.skip(label, "the card's tank gauge was not drawn in 5 s (fuel " .. tostring(fuel) .. ")"); return end
        local words = "?"
        pcall(function() words = getText("IGUI_BBQ_FuelAmount", ISCampingMenu.timeString(fuel)) end)
        Q.check(math.abs(g - T.delta) <= 0.05, label .. ": the card's tank gauge reads the tank's own share",
            "the gauge " .. H.n2(g) .. "; the tank " .. H.n2(T.delta) .. "; the grill's fuel " .. H.n1(fuel) .. " min (the game says \"" .. words .. "\"; the card's full mark is 1200 min)")
    end)
end
function C.c8()
    local T = {}
    H.step(2, function()
        H.caseStart()
        -- a gas range after the gas shutoff: the world has no gas shutoff to set
        local keys = {}
        pcall(function() for k, v in pairs(SandboxVars or {}) do if type(k) == "string" and string.find(string.lower(k), "gas", 1, true) then keys[#keys + 1] = k .. "=" .. tostring(v) end end end)
        table.sort(keys)
        Q.skip("8 K14 a gas range after the gas shutoff", "the QA world has no gas shutoff to set (B42's sandbox keys with gas in them: " .. H.list(keys) .. "; ElecShut is the power alone)")
        local sq = H.firstFree(S.RING2)
        T.bbq = sq and H.mkBBQ(sq)
        local isP = T.bbq and H.call(T.bbq.obj, "isPropaneBBQ")
        if not isP then Q.skip("8 K14 propane grill", "no propane grill could be laid (" .. tostring(T.bbq ~= nil) .. ")"); T.off = true; return end
        if not C.c8tank(T, 1.0) then Q.skip("8 K14 propane grill", "no propane tank could be put in"); T.off = true; return end
        H.zcall(function() S.OC.open(S.p, "fire", T.bbq.obj) end)
    end)
    C.c8read(T, "8 K14 propane grill, a full tank")
    H.step(2, function() if not T.off then C.c8tank(T, 0.5) end end)
    C.c8read(T, "8 K14 propane grill, a half tank")
    H.step(2, function() pcall(function() ZeD_WorldWindow.closeObjectCard(S.pn) end) end)
    H.caseEnd("8 fuel")
end

-- ===================================================================== 9. nutrition against the traits (K17)
S.MACROS = { { key = "Tooltip_food_Calories", get = "getCalories", fmt = "%d" }, { key = "Tooltip_food_Prots", get = "getProteins", fmt = "%d g" },
             { key = "Tooltip_food_Fat", get = "getLipids", fmt = "%d g" }, { key = "Tooltip_food_Carbs", get = "getCarbohydrates", fmt = "%d g" } }
function C.macros(it)
    local o, bad = {}, {}
    for _, m in ipairs(S.MACROS) do
        local v = H.fact(it, getText(m.key))
        local own = H.call(it, m.get)
        local want = own and string.format(m.fmt, math.floor(own + 0.5)) or "-"
        o[#o + 1] = getText(m.key) .. " " .. tostring(v)
        if v ~= want then bad[#bad + 1] = getText(m.key) .. " " .. tostring(v) .. " (the food's own " .. want .. ")" end
        if m.key == "Tooltip_food_Calories" then o.cal = v end
    end
    return o, bad
end
function C.nutri(on)
    if on then H.traitSet("NUTRITIONIST", true)
    else H.traitSet("NUTRITIONIST", false); H.traitSet("NUTRITIONIST2", false) end
end
function C.c9()
    local T = {}
    H.step(2, function()
        H.caseStart()
        T.tom = H.food(S.FT.tomato, "fresh")
        for _, ft in ipairs(S.PACKED) do
            if not T.pk and H.known(ft) then
                local it = H.give(ft)
                if it and H.call(it, "isPackaged") == true then T.pk = it elseif it then H.removeItem(it) end
            end
        end
        if not T.tom then Q.skip("9 K17", "no tomato could be given"); T.off = true; return end
        C.nutri(false)
    end)
    H.step(4, function()
        if T.off then return end
        T.offH, T.pkOff = H.tipH(T.tom), T.pk and H.tipH(T.pk)
        T.offRows = C.macros(T.tom)
        C.nutri(true)
    end)
    H.step(4, function()
        if T.off then return end
        local nOn = H.hasTrait("NUTRITIONIST")
        T.onH, T.pkOn = H.tipH(T.tom), T.pk and H.tipH(T.pk)
        local onRows, bad = C.macros(T.tom)
        Q.check(nOn and #bad == 0, "9 K17 (Nutritionist): the card's calories, protein, fat and carbs are the food's own", nOn and (H.list(onRows) .. "; off " .. H.list(bad)) or "the trait did not take")
        if T.onH == nil or T.offH == nil then
            Q.skip("9 K17: the card against the game's tooltip", "the game's tooltip could not be measured")
        elseif T.onH > T.offH then
            Q.check(T.offRows.cal == nil or T.offRows.cal == "-", "9 K17 (no Nutritionist): the card hides the calories the game's tooltip hides without the trait",
                "the game's tooltip " .. H.n1(T.offH) .. " px without, " .. H.n1(T.onH) .. " px with; the card without: " .. H.list(T.offRows))
        else
            H.note("9 K17: the game's tooltip for a tomato is " .. H.n1(T.offH) .. " px without Nutritionist and " .. H.n1(T.onH) .. " px with: it shows the same either way; the card shows " .. H.list(T.offRows))
        end
        if T.pk then H.note("9 K17 packaged " .. H.ft(T.pk) .. ": the game's tooltip " .. H.n1(T.pkOff) .. " px without, " .. H.n1(T.pkOn) .. " px with") end
        C.nutri(false)
    end)
    -- the item card itself, opened by the mouse, the trait off: it reads as its facts say
    H.openCard(T, "tom", "9 K17 the tomato's card")
    Q.waitMs(800)
    H.step(2, function()
        if T.off or not T.tomCard then return end
        local c = RT.cw() and RT.cw()._itemCard
        local m = c and c._model
        local card = nil
        for _, g in ipairs((m and m.facts and m.facts.groups) or {}) do
            for _, r in ipairs(g.rows or {}) do if r.label == getText("Tooltip_food_Calories") then card = r.value end end
        end
        local now = H.fact(T.tom, getText("Tooltip_food_Calories"))
        -- (without the trait both are hidden now, the game's rule: equal, nil and nil, is the pass)
        Q.check(card == now, "9 K17: the open item card's Calories row is its facts' (no Nutritionist: both hidden, as the game)", "the card " .. tostring(card) .. ", the facts " .. tostring(now))
        H.cardShut()
        H.traitsBack()
    end)
    H.caseEnd("9 facts")
end

-- ===================================================================== 10. layout and pictures
function C.zonesInside(label)
    local r = S.ckRect
    local s = H.cs()
    if not (r and s and getTimestampMs() - r.t < 1000) then Q.skip(label .. ": every zone inside the tab", "the tab's rectangle was not read"); return end
    local bad, n = {}, 0
    for _, z in ipairs(s.zones or {}) do
        local c = z.clip
        local hidden = c and (z.y + z.h <= c.y or z.y >= c.y + c.h)
        if not hidden and (z.w or 0) > 0 then
            n = n + 1
            if z.x < r.x - 1 or z.x + z.w > r.x + r.w + 1 then if #bad < 6 then bad[#bad + 1] = tostring(z.id) .. " " .. math.floor(z.x) .. "+" .. math.floor(z.w) end end
        end
    end
    Q.check(#bad == 0, label .. ": every drawn zone lies inside the tab (" .. math.floor(r.x) .. "+" .. math.floor(r.w) .. " px)", n .. " zones; out: " .. H.list(bad))
    RT.bounds(Q, label)
end
function C.c10()
    local T = {}
    H.step(2, function()
        H.caseStart()
        T.baseIt = H.potWater()
        H.food(S.FT.tomato, "fresh")
        H.food(S.FT.carrot, "fresh")
        H.lootRefresh()
        H.rescan()
    end)
    H.toTab(T, "10 layout")
    H.pickDish(T, "Stew", "10 layout")
    H.pickBase(T, "10 layout")
    H.wait(6000, function() return T.off or (H.czone("cook:ing:" .. S.FT.tomato) ~= nil and H.czone("cook:ing:" .. S.FT.carrot) ~= nil) end, function(ok)
        if T.off then return end
        if not Q.check(ok, "10 layout: the tomato and carrot rows are listed", H.rowsText()) then T.off = true; return end
        H.cpress("cook:ing:" .. S.FT.tomato)
    end)
    H.step(3, function() if not T.off then H.cpress("cook:ing:" .. S.FT.carrot) end end)
    for i, th in ipairs(S.THEMES) do
        H.step(2, function() if not T.off then H.theme(th.key) end end)
        Q.waitMs(900)
        if i == 1 then H.step(2, function() if not T.off then C.zonesInside("10 layout, " .. th.word) end end) end
        H.shot("ck_tab_" .. th.key .. "_" .. H.sizeTag(), th.word .. ": the Cooking tab, a stew of a tomato and a carrot planned", function() return not T.off end)
    end
    H.step(2, function() H.themeBack() end)
    H.step(2, function() if not T.off then H.sizeSet("large") end end)
    Q.waitMs(1500)
    H.step(2, function() if not T.off then C.zonesInside("10 layout, Large text") end end)
    H.shot("ck_large_" .. H.sizeTag(), "Large text: the Cooking tab, a stew planned", function() return not T.off end)
    H.step(2, function() H.sizeBack() end)
    Q.waitMs(1000)
    -- the made stew's item card
    H.step(2, function()
        if T.off then return end
        T.dishFt = H.dishFtOf("Stew", S.FT.pot)
        T.t0 = getTimestampMs()
        H.cpress("cook:make")
    end)
    H.wait(30000, function() return T.off or (H.qlen() == 0 and getTimestampMs() - (T.t0 or 0) > 300) end, function()
        if T.off then return end
        T.dish = H.newest(T.dishFt)
        if not Q.check(T.dish ~= nil, "10 layout: Make made the stew for its card", H.ft(T.dish)) then T.off = true end
    end)
    H.openCard(T, "dish", "10 layout, the made stew")
    Q.waitMs(900)
    H.step(2, function() if not T.off and T.dishCard then RT.bounds(Q, "10 layout, the made stew's item card") end end)
    H.shot("ck_card_" .. H.sizeTag(), "Dark: the made stew's item card (its food facts)", function() return T.dishCard == true end)
    H.step(2, function()
        H.cardShut()
        Q.check(#S.shots >= 5, "10 pictures: the tab in Dark, Light, High contrast and Large text and the stew's card were taken (a person judges them)", H.list(S.shots))
    end)
    H.caseEnd("10 layout")
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
    H.themeBack()
    H.sizeBack()
    H.halfBack()
    H.wrapOff()
    H.cardShut()
    pcall(function() S.ST.unbind(S.p) end)
    pcall(function() ZeD_WorldWindow.closeObjectCard(S.pn) end)
    for _, c in ipairs(S.objs) do H.rmObj(c) end
    for _, fr in ipairs(S.fires) do H.rmFire(fr) end
    for _, it in ipairs(S.made) do H.removeItem(it) end
    S.fireSwept = H.fireSweep()
    H.traitsBack()
    S.xpGrew, S.xpLeft = H.xpBack()
    if f.recorded then
        local md = S.p:getModData()
        if f.dishes then local t = {}; for i, d in ipairs(f.dishes) do t[i] = d end; md.ZeD_CookDishes = t else md.ZeD_CookDishes = nil end
        pcall(function() S.p:setTimedActionInstantCheat(f.inst and true or false) end)
        pcall(function() if f.tod then getGameTime():setTimeOfDay(f.tod) end end)
        pcall(function()
            local stt = S.p:getStats()
            for k, v in pairs(f.stats or {}) do pcall(function() stt:set(CharacterStat[k], v) end) end
        end)
        local w = RT.cw()
        if w then
            if f.cook then
                local s = w._cook
                if s then
                    local pl = {}
                    for i, e in ipairs(f.cook.plan) do pl[i] = { ft = e.ft, name = e.name, spice = e.spice } end
                    s.dish, s.baseIdx, s.plan, s.sort, s.qty = f.cook.dish, f.cook.baseIdx, pl, f.cook.sort, f.cook.qty
                    s.listScroll, s.dishScroll, s.collapsed, s.popup = f.cook.ls, f.cook.ds, f.cook.col, nil
                    s.scanAt, s.visAt, s.ingCache = -1, nil, nil
                end
            else
                w._cook = nil
            end
        end
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
        pcall(function()
            local a, b = f.hands.p, f.hands.s
            S.p:setPrimaryHandItem((a and S.p:getInventory():containsRecursive(a)) and a or nil)
            S.p:setSecondaryHandItem((b and S.p:getInventory():containsRecursive(b)) and b or nil)
        end)
        H.home()
        if S.layoutTouched and f.layout and ZEDQA_LAYOUT_BACK then pcall(ZEDQA_LAYOUT_BACK, f.layout, "ck_tab") end
        local w = RT.cw()
        if w then w._maxWinW = f.maxW end
        H.lootRefresh()
        if f.st then pcall(function() S.ST.bind(S.p, f.st) end) end
    end)
    Q.step(20, function()
        local f = S.found
        if not f.recorded then return end
        pcall(ZeD_CharacterWindow.openTab, S.pn, (f.ctab and f.ctab ~= "cooking") and f.ctab or "loot")
        if f.ctab == "cooking" then pcall(ZeD_CharacterWindow.openTab, S.pn, "cooking") end
        RT.worldTab(f.wtab or "loot")
    end)
    Q.step(20, function()
        local f = S.found
        if not f.recorded then Q.skip("put back", "nothing was staged"); return end
        local left = {}
        for _, it in ipairs(S.made) do if not H.gone(it) then left[#left + 1] = H.ft(it) end end
        Q.check(#left == 0, "put back: every thing the run gave is gone (the bags, the floor, the crate, the oven, the fire, the grill)", #S.made .. " given; left " .. H.list(left, 8))
        local extra = {}
        for _, it in ipairs(H.all()) do if not f.inv0[it] then extra[#extra + 1] = H.ft(it) end end
        Q.check(#extra == 0 and (S.lost or 0) == 0, "put back: he carries what he carried (nothing made left, his set-aside things back)",
            "new " .. H.list(extra, 8) .. "; " .. tostring(S.swept) .. " swept, " .. tostring(S.floorSwept) .. " off the floor, " .. tostring(S.refilled)
            .. " of his own used things given again, " .. tostring(S.lost) .. " set-aside things not given back")
        local objs = {}
        for _, c in ipairs(S.objs) do if H.objLeft(c) then objs[#objs + 1] = c.what end end
        for _, fr in ipairs(S.fires) do if H.fireLua(fr) ~= nil then objs[#objs + 1] = "the campfire at " .. fr.sq:getX() .. "," .. fr.sq:getY() end end
        Q.check(#objs == 0, "put back: every object laid is gone (the crate, the generator, the range, the campfire, the propane grill)",
            #S.objs .. " laid, " .. #S.fires .. " fires; left " .. H.list(objs) .. "; fires put out near home " .. tostring(S.fireSwept))
        local tok, tbad = H.traitsAsFound()
        Q.check(tok, "put back: his traits (Nutritionist, Herbalist) and the Herbalist recipe as found", "not as found: " .. tbad)
        local lvlLeft = 0
        pcall(function() for _, r in ipairs(S.xp) do if S.p:getPerkLevel(r.perk) ~= r.lvl then lvlLeft = lvlLeft + 1 end end end)
        if S.xpLeftText then H.note("put back: XP drift left (levels checked): " .. S.xpLeftText) end
        Q.check(lvlLeft == 0, "put back: the skill levels as found", tostring(S.xpGrew) .. " skills changed, " .. lvlLeft .. " not at their level")
        local md = S.p:getModData()
        local nowN = (type(md.ZeD_CookDishes) == "table") and #md.ZeD_CookDishes or -1
        local same = nowN == (f.dishesN or -1)
        if same and f.dishes then for i, d in ipairs(f.dishes) do if md.ZeD_CookDishes[i] ~= d then same = false end end end
        Q.check(same, "put back: the saved dishes as found", nowN .. " now, " .. tostring(f.dishesN) .. " found")
        -- (the tab makes its state afresh on its next look when none was found: an empty plan, sorted by name; it also
        -- empties a plan itself when the dish's base is out of reach)
        local s = RT.cw() and RT.cw()._cook
        local wantSort = (f.cook and f.cook.sort) or "name"
        local wantN = (f.cook and #f.cook.plan) or 0
        Q.check(s == nil or (s.sort == wantSort and s.popup == nil and (#(s.plan or {}) == wantN or #(s.plan or {}) == 0)),
            "put back: the Cooking tab's sort, plan and lists as found", tostring(s and s.sort) .. ", " .. tostring(s and #(s.plan or {})) .. " planned (found "
            .. tostring(wantSort) .. ", " .. wantN .. "), a list open " .. tostring(s and s.popup))
        if s and wantN > 0 and #(s.plan or {}) == 0 then H.note("put back: the found plan of " .. wantN .. " was emptied by the tab (its dish's base is not in reach)") end
        local dx, dy = math.abs(S.p:getX() - f.pos.x), math.abs(S.p:getY() - f.pos.y)
        Q.check(dx < 0.6 and dy < 0.6 and S.ST.current(S.p) == (f.st or nil) and H.qlen() == 0 and getGameSpeed() == 1,
            "put back: he stands where he stood, the station as found, no action queued, game speed 1", string.format("%.1f,%.1f off", dx, dy) .. ", " .. H.qkinds())
        local w = RT.cw()
        Q.check(ZeD.currentBase == f.base and ZeD.currentSize == f.size and H.lockFound() == (S.lockWas or H.lockFound()) and S.parked == nil
            and S.back.maxW == nil and S.w0 == nil and (w == nil or w._maxWinW == f.maxW),
            "put back: the theme, the text size, the input lock, the width cap, the pointer and the draw watchers as found",
            tostring(ZeD.currentBase) .. ", " .. tostring(ZeD.currentSize) .. ", lock " .. H.lockFound() .. ", width cap " .. tostring(w and w._maxWinW))
        Q.check(S.errs == 0, "put back: nothing ZeD ran for this script threw", S.errs .. " caught" .. (S.zerr and (": " .. S.zerr) or ""))
        local e1 = H.errN()
        if S.err0 and e1 then Q.check(e1 == S.err0, "the Cooking tab run ran with no Lua error", (e1 - S.err0) .. " new")
        else Q.skip("the Cooking tab run's Lua error count", "the game's Lua error count cannot be read here") end
        H.note("put back: Cooking XP the adds awarded is set back as far as the game lets Lua set it (drift above, if any)")
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
C.c6()
C.c7()
C.c8()
C.c9()
C.c10()
S.buildPutBack()
Q.start()
