-- ZeDUI/tools/qa/ck_calls.lua  (Nov 25 2026, QA; tag ck_calls): the director's 6 design calls for the Character
-- window's Cooking tab, as Build made them (fix/cookcalls, b24d2c7ee, merged to main), each proved in the running game
-- with values, by the mouse and by the pad where the call has a press, with pictures of the new looks. Run after
-- zedqa_prelude.lua and rt_kit.lua (ck_calls.txt). grep "ZEDQA ck_calls". Helpers, staging and the put-back are
-- ck_tab.lua's (copied: the script stands alone).
-- How it drives the tab: a click is the tab's own handler at the zone's middle (ZeD.CookingTab.onClick); a hover is the
-- game's own pointer read (getMouseX / getMouseY, which ISUIElement:getMouseX reads) set over the row, with the input
-- locked to the mouse; the pad's presses go through FocusManager's QA hook and its own dispatch on the Character window
-- (RT.pad + RT.padDown, focus by focusWhere in charTabContent), the input locked to the controller. Every lock is put
-- back as found. What the tab draws is read as drawn: its panel's drawText (an instance watcher on the panel and the
-- window), its stat rows (ZeD.Molecules.drawStatRow), the help line's words (ZeD.Help.take) and the help line's prompts
-- (ZeD_Window._footerPrompts, the list the help line draws). The game's own answers are asked of the game: the made
-- dish's getHungerChange, the item card's own Hunger row for it, getItemsCanBeUse on the game's container list
-- (ISInventoryPaneContextMenu.getContainers), needToBeCooked and getMaxItems, isResultItem, the game's own add
-- (ISInventoryPaneContextMenu.onAddItemInEvoRecipe) run beside ZeD's Make, the containers the items sit in and the
-- game's queue; never ZeD's code under test (CK.dishHunger, whereOf, rowWhy, firstDish are not called).
-- His own things of the types used here, and every free base and dish of an evolved recipe he carries, are set aside
-- for the run, so every dish uses only what a case gave.
-- Cases (call n = the director's call; pictures ck_calls_<n>_<what>_<WxH>):
--   1 hunger   1a a sandwich of bread and one cooked steak (mouse): the dish pane's line drawn with the card's word
--              (UI_ZeD_Card_HungerReduction) and the card's "+n" format, reading 15; 1b a pot of water and one tomato,
--              Stew (pad): 12; 1c a rotten tomato at Cooking 7 (mouse; SKIP when the game offers none). Each then
--              made: the line read before Make against the made dish's own getHungerChange (-x*100, within 1) and the
--              made dish's item card Hunger row; the rows' "(n)" sum a NOTE (known gap). Make stores the dish
--              (ZeD_CookLast, call 6) by the mouse and by the pad. Picture 1_hunger
--   2 why      a Sandwich with a raw steak (the game lists it and refuses it: needToBeCooked) and carrots: the pad's
--              focus on the grey steak row: the help line's prompts hold the game's reason (ContextMenu_NeedCooked),
--              drawn, and no A (Select); A there plans nothing; a lit carrot row as the control (A shown, no reason).
--              The dish filled to the game's getMaxItems by the pad's A: the carrot row grey, the help line holds
--              "The dish is full", no A; A plans nothing more. The mouse: hover on the steak row and the full carrot
--              row: the help line's words are the same reasons (unchanged). Picture 2_padwhy
--   3 where    3a a tomato only in a crate beside him: the row's aside is the crate's word (the game's own container
--              title for its type), drawn dim beside the name; Make (mouse) brings that tomato from the crate first and
--              it goes in; the game's own add from the crate run beside it: the crate's tomato ends where the game's
--              does, nothing of the crate's left in his bags. 3b a tomato only on the floor: the aside "Floor"; Make by
--              the pad takes it. 3c one on him and one in the crate: no aside; Make (mouse) takes the carried one, the
--              crate's stays. Picture 3_where
--   4 made     4a a stew made by the game's own add (a pot of water and a tomato), a carrot on him: the tab lists Stew
--              with the made stew as its base (the game: isResultItem, and its list takes the carrot); Make (mouse)
--              puts the carrot into THAT stew (its extra items +1, no new stew), the Hunger line against it. 4b a pot
--              of soup (Soup2, base = result): Soup listed once, the soup its base once; Make by the pad: into that
--              soup (+1, no new soup, no new soup pot). 4c toast (Toast, base = result: the game's getEvolvedRecipes):
--              given (the toaster is a craft station; SKIP when the game lists nothing for it) and topped by the mouse.
--              Picture 4_madedish (the base list open on the made dish)
--   5 reach    a pot of water in a crate beside him, a tomato on him: the tab shows (the game's list for that pot takes
--              the tomato, on the game's container list), the base is the crate's pot; Make (mouse, then the pad
--              with a second pot): the pot's move to him is queued before the first add, and a move back to the crate
--              after; the stew ends where the game's own add (onAddItemInEvoRecipe, from the crate) leaves its stew,
--              and (the call's words) back in the crate
--   6 last     a pot of water and a tomato with no dish stored: the tab opens on Soup (the first rule); a Stew made by
--              the pad stores "Stew"; the dish cleared (and the tab's state made afresh): it opens on Stew; with no
--              Stew base in reach it falls back to the first rule; ZeD_CookLast put back as found
--   every case: no Lua error over it; put back exactly
-- Puts back: every thing given or made (the bags, the floor, the crate); every crate laid (named if left); the Cooking
-- skill level (XP drift a NOTE); the saved dishes and the last dish made (ZeD_CookDishes, ZeD_CookLast); the Cooking
-- tab's dish, base, plan, sort, count and scrolls; a bound station; the input lock, the pointer and its hover, the draw
-- watchers; game speed 1, the clock and his stats; the queue; the window pair, both windows' tabs and the layout; where
-- he stood. God mode and invincible are made sure on and left as found at the end.

if not (RT and RT.make) then
    print("ZEDQA ck_calls ERR rt_kit.lua did not run first")
    print("ZEDQA ck_calls VERDICT FAIL 1")
    print("ZEDQA ck_calls DONE")
    return
end
local Q = RT.make("ck_calls")
Q.maxMs = 1600000                    -- (the runner gives this script 1800 s: the put-back runs before that)
local S = { p = RT.p, pn = RT.pn, found = {}, back = {}, made = {}, caseMade = {}, objs = {}, stash = {},
            shots = {}, errs = 0, dead = false, xp = {}, stat = {}, drawn = {}, cookDrawn = {}, dt = {} }
local H = {}
local C = {}
S.CK = ZeD and ZeD.CookingTab
S.ST = ZeD and ZeD.Stations
S.IFP = ZeD and ZeD.ItemFactsPanel
S.F = RT.focus()
S.FT = { pot = "Base.Pot", bread = "Base.BreadSlices", tomato = "Base.Tomato", carrot = "Base.Carrots", steak = "Base.Steak",
         stew = "Base.PotOfStew", soup = "Base.PotOfSoup", soupNew = "Base.PotOfSoupRecipe", toast = "Base.Toast" }
S.CRATE = "carpentry_01_16"
S.NEAR = { { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }
S.STATS = { "HUNGER", "THIRST", "FATIGUE", "BOREDOM", "STRESS", "ENDURANCE", "UNHAPPINESS", "PANIC", "MORALE", "SANITY", "ANGER",
    "DISCOMFORT", "IDLENESS", "WETNESS", "FOOD_SICKNESS", "POISON", "SICKNESS" }
S.MD_LAST = "ZeD_CookLast"

if not (S.p and S.CK and S.ST and S.IFP and ZeD_CharacterWindow and ZeD.Molecules and ZeD.Help and ZeD_Window) then
    Q.check(false, "the player and ZeD's Cooking tab, stations, item facts, stat rows, help line and window are loaded")
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
function H.screen() local w, h = 0, 0; pcall(function() w, h = RT.core:getScreenWidth(), RT.core:getScreenHeight() end); return math.floor(w), math.floor(h) end
function H.sizeTag() local w, h = H.screen(); return w .. "x" .. h end
function H.zopt(id) local zo = nil; pcall(function() zo = PZAPI.ModOptions:getOptions("ZeD_UI") end); return zo and zo.dict and zo.dict[id] or nil end
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
function H.zcall(fn)
    local ok, err = pcall(fn)
    if not ok then S.errs = S.errs + 1; S.zerr = S.zerr or tostring(err) end
    return ok
end
function H.md() local md = nil; pcall(function() md = S.p:getModData() end); return md or {} end
function H.lastDish() local v = H.md()[S.MD_LAST]; return v end

-- ===================================================================== the timed-action queue
function H.queue() local q = nil; pcall(function() q = ISTimedActionQueue.getTimedActionQueue(S.p) end); return (q and q.queue) or {} end
function H.qlen() return #H.queue() end
function H.qkinds() local o = {}; for _, a in ipairs(H.queue()) do o[#o + 1] = tostring(a.Type) end; return H.list(o, 12) end
function H.qstop() pcall(function() ISTimedActionQueue.clear(S.p) end) end
-- the queue as it stands: each action's type, and a move's item and its two containers
function H.qcopy()
    local o = {}
    for _, a in ipairs(H.queue()) do o[#o + 1] = { ty = tostring(a.Type), item = a.item, src = a.srcContainer, dst = a.destContainer, a = a } end
    return o
end
function H.isAdd(e) return e.ty == "ZeD_CookAdd" or e.ty == "ISAddItemInRecipe" or e.ty == "ZeD_CookWait" end
function H.isMove(e) return e.item ~= nil and e.dst ~= nil and not H.isAdd(e) end

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
function H.extras(it) local n = 0; if H.isItem(it) then pcall(function() local l = it:getExtraItems(); n = l and l:size() or 0 end) end; return n end
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
-- the items of a type in his bags and in a container (the crate), as a set
function H.setOf(ft, inv)
    local set = {}
    for _, it in ipairs(H.all()) do if H.ft(it) == ft then set[it] = true end end
    if inv then
        pcall(function()
            local l = inv:getItems()
            for i = 0, l:size() - 1 do local it = l:get(i); if H.ft(it) == ft then set[it] = true end end
        end)
    end
    return set
end
function H.newOf(ft, inv, before)
    for it in pairs(H.setOf(ft, inv)) do if not (before and before[it]) then return it end end
    return nil
end
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
-- a pot of water, in his bags or in a container
function H.potWater(inv)
    local pot = inv and H.giveTo(inv, S.FT.pot) or H.give(S.FT.pot)
    if pot then pcall(function() local fc = pot:getFluidContainer(); fc:addFluid(Fluid.Water, fc:getCapacity()) end) end
    return pot
end
-- a food given in a state: rotten, fresh, cooked; nil when the state did not take
function H.food(ft, state, inv)
    local it = inv and H.giveTo(inv, ft) or H.give(ft)
    if not H.isFood(it) then return nil end
    local ok = true
    pcall(function()
        if state == "rotten" then it:setAge(it:getOffAgeMax() + 1); ok = it:isRotten()
        elseif state == "fresh" then it:setAge(0); ok = it:isFresh()
        elseif state == "cooked" then it:setCooked(true); ok = it:isCooked()
        end
    end)
    if not ok then return nil end
    return it
end
-- a food laid on the floor of a free square beside him
function H.layFloor(ft)
    local sq = H.firstFree(S.NEAR)
    if not sq then return nil end
    local it = nil
    pcall(function() it = sq:AddWorldInventoryItem(ft, 0.5, 0.5, 0) end)
    if H.isFood(it) then pcall(function() it:setAge(0) end) end
    return H.mark(it)
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

-- ===================================================================== skills
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
    S.xpLeftText = nil
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
function H.lvl() local l = 0; pcall(function() l = S.p:getPerkLevel(Perks.Cooking) end); return l end
function H.lvlSet(n)
    pcall(function()
        S.p:setPerkLevelDebug(Perks.Cooking, n)
        S.p:getXp():setXPToLevel(Perks.Cooking, n)
    end)
    return H.lvl() == n
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
    return list
end
function H.inConts(inv)
    local l = H.conts()
    local has = false
    pcall(function() has = l ~= nil and l:contains(inv) end)
    return has and true or false
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
function H.gameHas(r, base, it)
    for _, x in ipairs(H.gameList(r, base)) do if x == it then return true end end
    return false
end
function H.isResult(r, it) local v = false; pcall(function() v = r:isResultItem(it) and true or false end); return v end
function H.maxOf(r) local n = nil; pcall(function() n = r:getMaxItems() end); return n end
-- the game's own add (its right-click menu's): moves what is not carried, adds, moves it back
function H.gameAdd(r, base, used)
    if not (r and base and used) then return false end
    return pcall(ISInventoryPaneContextMenu.onAddItemInEvoRecipe, r, base, used, S.pn)
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
-- the game's own word for a container, as its loot window titles it (ISInventoryPage: IGUI_ContainerTitle_<type>)
function H.contWord(c)
    local w = nil
    pcall(function()
        local ty = tostring(c:getType())
        w = getTextOrNull("IGUI_ContainerTitle_" .. ty) or ty
    end)
    return w
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
-- a press on a zone: a click at its middle; scrolled out of its pane, as the controller's A presses it
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
    for _, g in ipairs((s and s.ingCache and s.ingCache.list) or {}) do
        o[#o + 1] = g.ft .. " x" .. tostring(g.n) .. (g.why and " grey" or "") .. (g.where and (" @" .. tostring(g.where)) or "")
    end
    return "dish " .. tostring(s and s.dish) .. "; rows " .. H.list(o, 12)
end
function H.dishesText() local s = H.cs(); return H.list((s and s.dishList) or {}, 16) end
function H.snapRow(ft)
    local s = H.cs()
    local g = s and s.ingCache and s.ingCache.byFt and s.ingCache.byFt[ft]
    if not g then return nil end
    local items = {}
    for _, it in ipairs(g.items or {}) do items[#items + 1] = it end
    return { name = g.name, use = g.use, n = g.n, why = g.why, where = g.where, id = g.id, items = items }
end
function H.rowId(ft) return "cook:ing:" .. ft end
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
-- queue: the dish picked from the Dish list by its name
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
function H.pickBase(T, label)
    H.step(2, function()
        T.baseI = nil
        if T.off then return end
        local want = T.baseIt
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
        local b = H.curBase()
        if not Q.check(T.baseIt == nil or (b ~= nil and b.item == T.baseIt), label .. ": the dish is planned in the base the case gave",
            "in " .. tostring(b and H.nm(b.item)) .. ", wanted " .. H.nm(T.baseIt)) then T.off = true end
    end)
end
-- queue: wait for rows of these types to be listed (T.off with the rows when not)
function H.waitRows(T, fts, label, skipWhy)
    H.wait(6000, function()
        if T.off then return true end
        for _, ft in ipairs(fts) do if H.czone(H.rowId(ft)) == nil then return false end end
        return true
    end, function(ok)
        if T.off then return end
        if not ok then
            if skipWhy then Q.skip(label, skipWhy .. ": " .. H.rowsText())
            else Q.check(false, label .. ": the rows " .. H.list(fts) .. " are listed", H.rowsText()) end
            T.off = true
        end
    end)
end

-- ===================================================================== the pad and the mouse
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
-- the input locked to the mouse (the tab's hover runs only off the controller)
function H.kbmOn()
    local Det = ZeD.Input and ZeD.Input.Detector
    if not (Det and Det.setLockedMode) then return false end
    if S.lockWas == nil then S.lockWas = H.lockFound() end
    pcall(function() S.F.releaseFocus(S.pn) end)
    pcall(Det.setLockedMode, "kbm")
    S.back.pad = true
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
-- queue: a press on a zone by the mouse (a click) or by the pad (the focus there, then A); id may be a function of
-- nothing, read when the press runs (a row known only at run time)
function H.press(T, id, how, label)
    local function idOf() if type(id) == "function" then return id() end; return id end
    if how == "pad" then
        H.step(2, function()
            T.pgo = nil
            if T.off or T.stop then return end
            T.pgo = H.padOn() and H.focusEl(idOf())
            if not T.pgo then Q.check(false, label .. ": the pad's focus lands on " .. tostring(idOf()), "on " .. tostring(H.focusedId())); T.stop = true end
        end)
        H.tapA(function() return T.pgo and not T.off and not T.stop end)
        H.step(3, function() end)
    else
        H.step(2, function() if not (T.off or T.stop) then H.cpress(idOf()) end end)
    end
end
-- the pointer over a zone of the tab: the game's pointer read (getMouseX / getMouseY) set so the tab's panel reads
-- the zone's middle (ISUIElement:getMouseX: getMouseX() - its scroll - its screen x)
function H.hoverOn(id)
    local z, s = H.czone(id), H.cs()
    local panel = s and s.panel
    if not (z and panel) then return false end
    local ax, ay, xs, ys = 0, 0, 0, 0
    if not pcall(function()
        ax, ay = panel:getAbsoluteX(), panel:getAbsoluteY()
        xs, ys = panel.javaObject:getXScroll(), panel.javaObject:getYScroll()
    end) then return false end
    local sx = z.x + math.floor(z.w / 2) + ax + xs
    local sy = z.y + math.floor(z.h / 2) + ay + ys
    if not S.hov then S.hov = { mx = getMouseX, my = getMouseY } end
    getMouseX = function() return sx end
    getMouseY = function() return sy end
    return true
end
function H.hoverOff()
    if S.hov then
        getMouseX, getMouseY = S.hov.mx, S.hov.my
        S.hov = nil
    end
end

-- ===================================================================== the draw and the words, watched (on for the run)
-- S.stat[label]: a stat row the tab drew last ({ v, t }); S.cookDrawn[text] / S.drawn[text]: when a text was last drawn
-- by the tab's panel / by the tab's panel or the Character window; S.help: the help line's words as taken last;
-- S.foot: the help line's prompts as the window last built them for its draw
function H.textHook(obj)
    if obj == nil or S.dt[obj] then return end
    local ok, had = pcall(rawget, obj, "drawText")
    if not ok then return end
    local orig = obj.drawText
    if type(orig) ~= "function" then return end
    local fn = function(me, str, ...)
        local s = tostring(str)
        local t = getTimestampMs()
        S.drawn[s] = t
        if S.inCook then S.cookDrawn[s] = t end
        return orig(me, str, ...)
    end
    if pcall(rawset, obj, "drawText", fn) then S.dt[obj] = { had = had, fn = fn } end
end
function H.textUnhook()
    for obj, e in pairs(S.dt) do
        pcall(function() if rawget(obj, "drawText") == e.fn then rawset(obj, "drawText", e.had) end end)
    end
    S.dt = {}
end
function H.wrapOn()
    if S.w0 then return end
    local W = { render = S.CK.render, stat = ZeD.Molecules.drawStatRow, take = ZeD.Help.take, foot = ZeD_Window._footerPrompts }
    S.w0 = W
    W.renderFn = function(panel, win, x, y, w, h)
        H.textHook(panel)
        S.inCook = true
        local ok, res = pcall(W.render, panel, win, x, y, w, h)
        S.inCook = false
        if not ok then S.tabErrs = (S.tabErrs or 0) + 1; S.tabErrLast = res; error(res, 0) end
        return res
    end
    W.statFn = function(panel, x, y, w, label, value, ...)
        if S.inCook then S.stat[tostring(label)] = { v = value, t = getTimestampMs() } end
        return W.stat(panel, x, y, w, label, value, ...)
    end
    W.takeFn = function(win, ...)
        local r = W.take(win, ...)
        if win ~= nil and win == RT.cw() then S.help = { v = r, t = getTimestampMs() } end
        return r
    end
    W.footFn = function(self, ...)
        local r = W.foot(self, ...)
        if self ~= nil and self == RT.cw() then
            local o = {}
            for _, p in ipairs(r or {}) do
                if type(p) == "string" then o[#o + 1] = { s = p }
                elseif type(p) == "table" then o[#o + 1] = { glyph = tostring(p.glyph), s = tostring(p.label or "") } end
            end
            S.foot = { list = o, t = getTimestampMs() }
        end
        return r
    end
    S.CK.render = W.renderFn
    ZeD.Molecules.drawStatRow = W.statFn
    ZeD.Help.take = W.takeFn
    if W.foot then ZeD_Window._footerPrompts = W.footFn end
    -- (the help line is drawn on the window's overlay, ZeD_Window._drawTop: its words are read there)
    local cw = RT.cw()
    H.textHook(cw)
    if cw then H.textHook(cw._zedOverlay) end
end
function H.wrapOff()
    local W = S.w0
    if not W then return end
    if S.CK.render == W.renderFn then S.CK.render = W.render end
    if ZeD.Molecules.drawStatRow == W.statFn then ZeD.Molecules.drawStatRow = W.stat end
    if ZeD.Help.take == W.takeFn then ZeD.Help.take = W.take end
    if W.foot and ZeD_Window._footerPrompts == W.footFn then ZeD_Window._footerPrompts = W.foot end
    H.textUnhook()
    S.w0 = nil
end
function H.wrapped()
    local W = S.w0
    if not W then return true end
    return S.CK.render == W.render and ZeD.Molecules.drawStatRow == W.stat and ZeD.Help.take == W.take
end
function H.fresh(r, ms) return r ~= nil and getTimestampMs() - (r.t or 0) <= (ms or 600) end
function H.seenAt(set, s, ms) local t = set[tostring(s)]; return t ~= nil and getTimestampMs() - t <= (ms or 600) end
-- the help line's prompts (fresh): their words, whether A is there, whether a plain text is there
function H.footText()
    local o = {}
    for _, p in ipairs((S.foot and S.foot.list) or {}) do o[#o + 1] = (p.glyph and ("(" .. p.glyph .. ") ") or "") .. p.s end
    return H.list(o)
end
function H.footHasA() for _, p in ipairs((S.foot and S.foot.list) or {}) do if p.glyph == "A" then return true end end; return false end
function H.footHas(s) for _, p in ipairs((S.foot and S.foot.list) or {}) do if p.glyph == nil and p.s == s then return true end end; return false end

-- ===================================================================== objects laid round him
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
function H.rmObj(c)
    if not (c and c.obj) then return end
    local o = c.obj
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
function H.crateClear(c) if c and c.inv then pcall(function() c.inv:removeAllItems() end) end end
-- new world items round him (anything not there at the start), taken away
function H.snapFloor(set)
    local f = S.found.pos
    local cx, cy, cz = math.floor(f and f.x or S.p:getX()), math.floor(f and f.y or S.p:getY()), math.floor(f and f.z or S.p:getZ())
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
-- where an item is now, in a word
function H.whereWord(it, crate)
    if H.gone(it) then return "used up" end
    local c = H.where(it)
    if crate and c == crate.inv then return "the crate" end
    if c == H.inv() then return "his bags" end
    if H.onFloor(it) or H.ctype(c) == "floor" then return "the floor" end
    return H.ctype(c)
end

-- ===================================================================== pictures
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

-- ===================================================================== a case's start and end
function H.tabReset()
    local s = H.cs()
    if s then s.plan, s.qty, s.popup, s.listScroll, s.dishScroll = {}, 1, nil, 0, 0 end
    H.rescan()
end
function H.caseStart()
    S.caseMade = {}
    S.caseObjs = #S.objs
    S.drawn, S.cookDrawn = {}, {}
    H.tabReset()
end
function H.legClean()
    H.speed(1)
    H.qstop()
    H.hoverOff()
    H.padOff()
    for _, it in ipairs(S.caseMade) do H.removeItem(it) end
    S.caseMade = {}
    H.sweepNew()
    H.tabReset()
    H.lootRefresh()
end
function H.caseClean()
    H.legClean()
    pcall(function() if S.boundByUs then S.ST.unbind(S.p); S.boundByUs = nil end end)
    for i = (S.caseObjs or 0) + 1, #S.objs do H.rmObj(S.objs[i]) end
    H.sweepFloor()
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
        if S.zerr then Q.check(false, label .. ": nothing ZeD ran for the case threw", S.zerr); S.zerr = nil end
        if (S.tabErrs or 0) > 0 then Q.check(false, label .. ": the Cooking tab drew without an error", S.tabErrs .. " errors, last " .. tostring(S.tabErrLast)); S.tabErrs = 0 end
        S.e0 = e1
    end)
end

-- ===================================================================== setup
function S.setup()
    Q.step(1, function()
        local f = S.found
        S.dead = S.p:isDead() and true or false
        if S.dead then Q.check(false, "setup: the character is alive (nothing is run on a dead one)"); return end
        if not (S.F and S.F.focusWhere and ISTimedActionQueue and ISAddItemInRecipe and getEvolvedRecipes and ISInventoryPaneContextMenu
            and ISInventoryPaneContextMenu.onAddItemInEvoRecipe) then
            S.dead = true
            Q.check(false, "setup: the pad's focus manager and the game's cooking code are loaded")
            return
        end
        S.err0 = H.errN()
        S.e0 = S.err0
        if ZEDQA_HOME then pcall(ZEDQA_HOME, "ck_calls") end
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
        f.last = md[S.MD_LAST]
        f.lvl = H.lvl()
        S.lockWas = H.lockFound()
        pcall(function() f.disorg = S.p:hasTrait(CharacterTrait.DISORGANIZED) and true or false end)
        H.xpSnap()
        pcall(function()
            local cur = S.ST.current(S.p)
            if cur then f.st = cur; S.ST.unbind(S.p); H.note("a station was bound: unbound for the run, bound again at the end") end
        end)
        RT.pairOpen()
        if ZEDQA_LAYOUT_SNAP then pcall(function() f.layout = ZEDQA_LAYOUT_SNAP() end) end
        local cw, ww = RT.cw(), RT.ww()
        f.ctab, f.wtab = cw and cw._activeTab, ww and ww._activeTab
        local s = cw and cw._cook
        if s then
            local pl = {}
            for i, e in ipairs(s.plan or {}) do pl[i] = { ft = e.ft, key = e.key, name = e.name, base = e.base, spice = e.spice } end
            local col = {}
            for k, v in pairs(s.collapsed or {}) do col[k] = v end
            f.cook = { dish = s.dish, baseIdx = s.baseIdx, plan = pl, sort = s.sort, qty = s.qty, ls = s.listScroll, ds = s.dishScroll, col = col }
        end
        f.recorded = true
        S.back.on = true
        H.wrapOn()
        S.hrWord = ZeD.tr("UI_ZeD_Card_HungerReduction")
        Q.say("found: at " .. math.floor(f.pos.x) .. "," .. math.floor(f.pos.y) .. ", input lock " .. tostring(S.lockWas) .. ", screen " .. H.sizeTag()
            .. ", Cooking " .. f.lvl .. ", saved dishes " .. tostring(f.dishesN) .. ", last dish " .. tostring(f.last) .. ", Disorganized "
            .. tostring(f.disorg) .. ", Character tab " .. tostring(f.ctab) .. ", the card's Hunger word " .. tostring(S.hrWord))
        if f.disorg then H.note("setup: he is Disorganized: the game puts nothing back after an add (ISCraftingUI.ReturnItemToContainer); call 5's move back is judged against the game") end
    end)
    H.step(2, function()
        -- his own things of the types used here, and every free base and dish of an evolved recipe he carries, set aside
        local set = {}
        for _, ft in pairs(S.FT) do set[ft] = true end
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
        for k, ft in pairs(S.FT) do if k ~= "toast" and not H.known(ft) then miss[#miss + 1] = k .. " " .. ft end end
        Q.check(#miss == 0, "setup: every item type the cases use is known to this game", "unknown: " .. H.list(miss))
    end)
    Q.waitMs(1500)
end

-- ===================================================================== 1. the Hunger line
-- queue: the dish pane's Hunger line read as drawn (T.line, T.lineN); checks the card's word and format
function C.readLine(T, L)
    Q.waitMs(700)
    H.wait(3000, function() return T.off or T.stop or H.fresh(S.stat[S.hrWord]) end, function(ok)
        if T.off or T.stop then return end
        local r = S.stat[S.hrWord]
        T.line = r and r.v
        T.lineN = T.line ~= nil and tonumber(string.match(tostring(T.line), "^%+(%d+)$")) or nil
        local rows, sum = {}, 0
        for _, e in ipairs(H.plan()) do
            if not e.spice then
                local g = H.snapRow(e.ft)
                local u = g and tonumber(g.use)
                rows[#rows + 1] = tostring(e.ft) .. " (" .. tostring(g and g.use) .. ")"
                sum = sum + (u or 0)
            end
        end
        T.rowSum = sum
        Q.check(ok and T.lineN ~= nil, L .. " (call 1): the dish pane draws the line under the card's word (" .. tostring(S.hrWord)
            .. ") in the card's format (\"+n\")", "drawn: " .. tostring(T.line) .. (ok and "" or " (no line drawn under that word)"))
        H.note(L .. " (call 1): the line " .. tostring(T.line) .. "; the rows' \"(n)\" " .. H.list(rows) .. " sum " .. sum
            .. (T.lineN and (T.lineN - sum ~= 0 and (" (the line is " .. (T.lineN - sum) .. " more: the base's own food and the known float gap)") or "") or ""))
    end)
end
-- after Make: the line against the made dish's own hunger and its item card's Hunger row
function C.judgeLine(T, L, dish)
    local dh = H.hunger(dish)
    local game = dh and (-dh * 100) or nil
    Q.check(T.lineN ~= nil and game ~= nil and math.abs(T.lineN - game) <= 1,
        L .. " (call 1): the line read before Make is the made dish's own hunger (getHungerChange as -x*100, within 1)",
        "the line " .. tostring(T.line) .. "; the made dish " .. H.ft(dish) .. " " .. (game and H.n1(game) or "?"))
    local card = H.fact(dish, S.hrWord)
    local cardN = card and tonumber(string.match(tostring(card), "^%+(%-?%d+)$")) or nil
    Q.check(cardN ~= nil and T.lineN ~= nil and math.abs(cardN - T.lineN) <= 1,
        L .. " (call 1): the made dish's item card reads the same row, word and figure (" .. tostring(S.hrWord) .. ")",
        "the card " .. tostring(card) .. "; the line " .. tostring(T.line))
end
-- spec: label, how, un, baseFt, ft (the row pressed), want (the call's figure or nil), lvl (Cooking for the leg), stage(T)
function C.hleg(spec)
    local T = { spec = spec, items = {} }
    local L = spec.label
    H.step(2, function()
        H.legClean()
        S.stat = {}
        if spec.lvl and not H.lvlSet(spec.lvl) then Q.skip(L, "Cooking could not be set to " .. spec.lvl); T.off = true; return end
        local ok, err = pcall(spec.stage, T)
        if not ok then T.skip = "the staging threw: " .. tostring(err) end
        if T.skip then Q.skip(L, T.skip); T.off = true; return end
        T.dishFt = H.dishFtOf(spec.un, spec.baseFt)
        T.r = H.gameRecipe(spec.un, spec.baseFt)
        if not (T.r and T.dishFt) then Q.skip(L, "the game has no " .. spec.un .. " made in " .. spec.baseFt); T.off = true; return end
        if spec.gameMust and not H.gameHas(T.r, T.baseIt, T.ing) then Q.skip(L, spec.gameMust); T.off = true; return end
        H.lootRefresh()
        H.rescan()
    end)
    H.toTab(T, L)
    H.pickDish(T, spec.un, L)
    H.pickBase(T, L)
    H.waitRows(T, { spec.ft }, L)
    H.press(T, H.rowId(spec.ft), spec.how, L)
    H.step(2, function()
        if T.off or T.stop then return end
        if not Q.check(H.planCount(spec.ft) == 1, L .. ": one press on the row (" .. spec.how .. ") puts one in the dish", "plan " .. H.planFts()) then T.stop = true end
    end)
    C.readLine(T, L)
    H.step(2, function()
        if T.off or T.stop or spec.want == nil then return end
        Q.check(T.lineN == spec.want, L .. " (call 1): the line reads " .. spec.want .. " as the call says", "drawn " .. tostring(T.line))
    end)
    if spec.shot then H.shot("ck_calls_1_hunger_" .. H.sizeTag(), spec.shot, function() return not (T.off or T.stop) and T.lineN ~= nil end) end
    H.press(T, "cook:make", spec.how, L)
    H.step(1, function() T.t0 = getTimestampMs(); T.q0 = H.qlen(); T.kinds = H.qkinds(); T.dish0 = H.count(T.dishFt or "?") end)
    H.wait(30000, function() return T.off or T.stop or (H.qlen() == 0 and getTimestampMs() - (T.t0 or 0) > 300) end, function(ok)
        H.padOff()
        if T.off or T.stop then return end
        local dish = H.newest(T.dishFt)
        if not Q.check(ok and dish ~= nil, L .. ": Make (" .. spec.how .. ") makes the dish", "queued " .. tostring(T.kinds) .. "; made " .. H.ft(dish)) then return end
        C.judgeLine(T, L, dish)
        local s = H.cs()
        Q.check(H.lastDish() == T.dishKey, L .. " (call 6): Make by the " .. spec.how .. " stores the dish (" .. S.MD_LAST .. ")",
            "stored " .. tostring(H.lastDish()) .. ", the dish " .. tostring(T.dishKey) .. " (tab on " .. tostring(s and s.dish) .. ")")
    end)
    H.step(2, function()
        H.legClean()
        if spec.lvl then H.xpBack() end
    end)
end
function C.c1()
    H.step(2, function() H.caseStart() end)
    C.hleg({ label = "1a sandwich, bread and a cooked steak (mouse)", how = "mouse", un = "Sandwich", baseFt = S.FT.bread, ft = S.FT.steak, want = 15,
        shot = "the dish pane's Hunger line, a sandwich of bread and one cooked steak",
        stage = function(T)
            T.baseIt = H.give(S.FT.bread)
            T.ing = H.food(S.FT.steak, "cooked")
            if not (T.baseIt and T.ing) then T.skip = "bread and a cooked steak could not be given" end
        end })
    C.hleg({ label = "1b stew, a pot of water and a tomato (pad)", how = "pad", un = "Stew", baseFt = S.FT.pot, ft = S.FT.tomato, want = 12,
        stage = function(T)
            T.baseIt = H.potWater()
            T.ing = H.food(S.FT.tomato, "fresh")
            if not (T.baseIt and T.ing) then T.skip = "a pot of water and a tomato could not be given" end
        end })
    C.hleg({ label = "1c stew, a rotten tomato at Cooking 7 (mouse)", how = "mouse", un = "Stew", baseFt = S.FT.pot, ft = S.FT.tomato, lvl = 7,
        gameMust = "the game's own list does not take a rotten tomato at Cooking 7 here",
        stage = function(T)
            T.baseIt = H.potWater()
            T.ing = H.food(S.FT.tomato, "rotten")
            if not (T.baseIt and T.ing) then T.skip = "a pot of water and a rotten tomato could not be given" end
        end })
    H.caseEnd("1 hunger")
end

-- ===================================================================== 2. a grey row's reason in the pad's help line
-- queue: the pad's focus on the row; the help line's prompts read as the window built them for its draw. whyKey: the
-- field of T holding the reason the row should show (T.why: the game's, T.full: the dish is full); want "why" or "lit"
function C.c2pad(T, id, whyKey, L, want)
    H.step(2, function()
        T.go = nil
        if T.off then return end
        T.go = H.padOn() and H.focusEl(id)
        if not Q.check(T.go, L .. ": the pad's focus lands on the row", "on " .. tostring(H.focusedId())) then return end
        S.foot = nil
    end)
    Q.waitMs(600)
    H.step(2, function()
        if T.off or not T.go then return end
        local fresh = H.fresh(S.foot)
        local why = T[whyKey]
        if want == "why" then
            Q.check(fresh and H.footHas(why), L .. " (call 2): the help line's prompts hold the game's reason, " .. tostring(why), "prompts: " .. H.footText())
            Q.check(H.seenAt(S.drawn, why), L .. " (call 2): the reason is drawn in the Character window", "the help line drew it: " .. tostring(H.seenAt(S.drawn, why)))
            Q.check(fresh and not H.footHasA(), L .. " (call 2): A (Select) is hidden on the grey row", "prompts: " .. H.footText())
        else
            Q.check(fresh and H.footHasA() and not H.footHas(why), L .. " (call 2): on a lit row A shows and no reason is added", "prompts: " .. H.footText())
        end
    end)
end
function C.c2()
    local T = {}
    local L = "2 why"
    H.step(2, function()
        H.caseStart()
        T.baseIt = H.give(S.FT.bread)
        T.steak = H.food(S.FT.steak, "fresh")
        T.carrots = {}
        for i = 1, 5 do T.carrots[i] = H.food(S.FT.carrot, "fresh") end
        if not (T.baseIt and T.steak and T.carrots[5]) then Q.skip(L, "bread, a raw steak and five carrots could not be given"); T.off = true; return end
        T.r = H.gameRecipe("Sandwich", S.FT.bread)
        if not T.r then Q.skip(L, "the game has no Sandwich made in bread"); T.off = true; return end
        T.why = getText("ContextMenu_NeedCooked")
        T.full = ZeD.tr("UI_ZeD_Cook_Full")
        T.max = H.maxOf(T.r)
        H.lootRefresh()
        H.rescan()
    end)
    H.toTab(T, L)
    H.pickDish(T, "Sandwich", L)
    H.pickBase(T, L)
    H.waitRows(T, { S.FT.steak, S.FT.carrot }, L)
    H.step(2, function()
        if T.off then return end
        -- the game's own answer: it lists the raw steak and refuses it (its menu's tooltip: ContextMenu_NeedCooked)
        T.gameRefuses = false
        pcall(function() T.gameRefuses = H.gameHas(T.r, T.baseIt, T.steak) and not T.r:needToBeCooked(T.steak) end)
        T.steakId = H.rowId(S.FT.steak)
        Q.check(T.gameRefuses and not H.lit(T.steakId), L .. ": the game lists the raw steak and refuses it (needToBeCooked), the tab's row is grey",
            "the game refuses " .. tostring(T.gameRefuses) .. ", the row " .. (H.lit(T.steakId) and "lit" or "grey"))
        if not T.gameRefuses then T.off = true end
    end)
    C.c2pad(T, H.rowId(S.FT.steak), "why", "2a the raw steak (pad)", "why")
    H.shot("ck_calls_2_padwhy_" .. H.sizeTag(), "the pad's focus on the grey raw steak row: the game's reason in the help line, no Select",
        function() return T.go == true and not T.off end)
    H.tapA(function() return T.go and not T.off end)
    H.step(4, function()
        if T.off or not T.go then return end
        Q.check(#H.plan() == 0, "2a the raw steak (pad): A on the grey row plans nothing", "plan " .. H.planFts())
    end)
    C.c2pad(T, H.rowId(S.FT.carrot), "why", "2a the carrot, the control (pad)", "lit")
    for _ = 1, 4 do H.press(T, H.rowId(S.FT.carrot), "pad", "2b filling the dish") end
    C.c2pad(T, H.rowId(S.FT.carrot), "full", "2b the full dish (pad)", "why")
    H.tapA(function() return T.go and not T.off end)
    H.step(4, function()
        if T.off then return end
        Q.check(H.planN() == T.max and not H.lit(H.rowId(S.FT.carrot)), "2b the full dish (pad): four A presses plan the game's limit (getMaxItems "
            .. tostring(T.max) .. "), the carrot row is grey and A on it plans no more", "plan " .. H.planFts())
    end)
    -- the mouse: hover, unchanged
    H.step(2, function()
        if T.off then return end
        H.padOff()
        T.kbm = H.kbmOn()
        S.help = nil
        T.hov = T.kbm and H.hoverOn(H.rowId(S.FT.steak))
        if not T.hov then Q.skip("2c the mouse's hover", "the pointer could not be set over the row") end
    end)
    Q.waitMs(600)
    H.step(2, function()
        if T.off or not T.hov then return end
        Q.check(H.fresh(S.help) and S.help.v == T.why, "2c the raw steak (mouse): the hover puts the game's reason in the help line, as before",
            "the help line: " .. tostring(S.help and S.help.v))
        S.help = nil
        T.hov = H.hoverOn(H.rowId(S.FT.carrot))
    end)
    Q.waitMs(600)
    H.step(2, function()
        if T.off or not T.hov then H.hoverOff(); return end
        Q.check(H.fresh(S.help) and S.help.v == T.full, "2c the full carrot row (mouse): the hover reads \"" .. tostring(T.full) .. "\" in the help line",
            "the help line: " .. tostring(S.help and S.help.v))
        H.hoverOff()
        H.padOff()
    end)
    H.caseEnd("2 why")
end

-- ===================================================================== 3. where a row's items are
function C.c3crate()
    local T = {}
    local L = "3a in the crate (mouse)"
    H.step(2, function()
        H.legClean()
        T.crate = S.crate
        if not T.crate then T.off = true; return end
        H.crateClear(T.crate)
        T.baseIt = H.potWater()
        T.tC = H.food(S.FT.tomato, "fresh", T.crate.inv)
        if not (T.baseIt and T.tC) then Q.skip(L, "a pot of water and the crate's tomato could not be given"); T.off = true; return end
        T.r = H.gameRecipe("Stew", S.FT.pot)
        T.word = H.contWord(T.crate.inv)
        H.lootRefresh()
        H.rescan()
    end)
    H.toTab(T, L)
    H.pickDish(T, "Stew", L)
    H.pickBase(T, L)
    H.waitRows(T, { S.FT.tomato }, L, "the crate's tomato is not offered (the crate is not in the game's container list here)")
    Q.waitMs(700)
    H.step(2, function()
        if T.off then return end
        local g = H.snapRow(S.FT.tomato)
        Q.check(H.where(T.tC) == T.crate.inv and H.gameHas(T.r, T.baseIt, T.tC), L .. ": the game's list takes the tomato, and it sits in the crate (none on him)",
            "in " .. H.whereWord(T.tC, T.crate))
        Q.check(g ~= nil and g.where == T.word, L .. " (call 3): the row names where its items are: the crate's own word (the game's container title, " .. tostring(T.word) .. ")",
            "the row says " .. tostring(g and g.where))
        Q.check(H.seenAt(S.cookDrawn, T.word, 800), L .. " (call 3): the aside \"" .. tostring(T.word) .. "\" is drawn in the tab", H.rowsText())
    end)
    H.shot("ck_calls_3_where_" .. H.sizeTag(), "a tomato only in the crate beside him: the row's dim aside names the crate", function() return not T.off end)
    H.press(T, H.rowId(S.FT.tomato), "mouse", L)
    H.press(T, "cook:make", "mouse", L)
    H.step(1, function()
        if T.off then return end
        T.q = H.qcopy()
        T.kinds = H.qkinds()
        T.t0 = getTimestampMs()
        T.h0 = H.hunger(T.tC)
    end)
    H.wait(40000, function() return T.off or (H.qlen() == 0 and getTimestampMs() - (T.t0 or 0) > 300) end, function(ok)
        if T.off then return end
        local fromCrate = false
        for _, e in ipairs(T.q or {}) do if H.isMove(e) and e.item == T.tC and e.src == T.crate.inv then fromCrate = true end end
        local now = H.hunger(T.tC)
        local went = H.gone(T.tC) or (T.h0 and now and math.abs(now - T.h0) > 0.0001)
        Q.check(ok and fromCrate and went, L .. ": Make takes the crate's tomato: it is moved from the crate to him and goes in",
            "queued " .. tostring(T.kinds) .. "; moved from the crate " .. tostring(fromCrate) .. "; the tomato now " .. H.whereWord(T.tC, T.crate))
        T.zedEnd = H.whereWord(T.tC, T.crate)
        -- the game's own add from the crate, beside it
        T.pot2 = H.potWater()
        T.tC2 = H.food(S.FT.tomato, "fresh", T.crate.inv)
        H.lootRefresh()
        T.gameGo = H.gameAdd(T.r, T.pot2, T.tC2)
        T.t1 = getTimestampMs()
        if not T.gameGo then Q.skip(L .. ": against the game's own add from the crate", "the game's add could not be queued") end
    end)
    H.wait(40000, function() return T.off or not T.gameGo or (H.qlen() == 0 and getTimestampMs() - (T.t1 or 0) > 300) end, function()
        if T.off or not T.gameGo then return end
        T.gameEnd = H.whereWord(T.tC2, T.crate)
        Q.check(T.zedEnd == T.gameEnd and T.zedEnd ~= "his bags", L .. " (call 3): the crate's tomato ends where the game's own add leaves its own (nothing of the crate's left in his bags)",
            "ZeD: " .. tostring(T.zedEnd) .. "; the game: " .. tostring(T.gameEnd))
    end)
    H.step(2, function() H.legClean(); H.crateClear(T.crate) end)
end
function C.c3floor()
    local T = {}
    local L = "3b on the floor (pad)"
    H.step(2, function()
        H.legClean()
        T.baseIt = H.potWater()
        T.tF = H.layFloor(S.FT.tomato)
        if not (T.baseIt and T.tF) then Q.skip(L, "no free square beside him took a tomato on the floor"); T.off = true; return end
        T.r = H.gameRecipe("Stew", S.FT.pot)
        T.word = getText("ContextMenu_Floor")
        H.lootRefresh()
        H.rescan()
    end)
    H.step(4, function() if not T.off then H.lootRefresh(); H.rescan() end end)
    H.toTab(T, L)
    H.pickDish(T, "Stew", L)
    H.pickBase(T, L)
    H.waitRows(T, { S.FT.tomato }, L, "the floor's tomato is not offered (the floor is not in the game's container list here)")
    Q.waitMs(700)
    H.step(2, function()
        if T.off then return end
        local g = H.snapRow(S.FT.tomato)
        Q.check(H.ctype(H.where(T.tF)) == "floor" and H.gameHas(T.r, T.baseIt, T.tF), L .. ": the game's list takes the tomato, and it lies on the floor (its container is the floor's)",
            "in " .. H.ctype(H.where(T.tF)))
        Q.check(g ~= nil and g.where == T.word and H.seenAt(S.cookDrawn, T.word, 800), L .. " (call 3): the row's aside is \"" .. tostring(T.word) .. "\", drawn",
            "the row says " .. tostring(g and g.where) .. ", drawn " .. tostring(H.seenAt(S.cookDrawn, T.word, 800)) .. "; the game's loot title for the floor "
            .. tostring(getTextOrNull("IGUI_ContainerTitle_floor")))
    end)
    H.press(T, H.rowId(S.FT.tomato), "pad", L)
    H.press(T, "cook:make", "pad", L)
    H.step(1, function() T.t0 = getTimestampMs(); T.h0 = H.hunger(T.tF); T.kinds = H.qkinds() end)
    H.wait(40000, function() return T.off or T.stop or (H.qlen() == 0 and getTimestampMs() - (T.t0 or 0) > 300) end, function(ok)
        H.padOff()
        if T.off or T.stop then return end
        local now = H.hunger(T.tF)
        local went = H.gone(T.tF) or (T.h0 and now and math.abs(now - T.h0) > 0.0001)
        Q.check(ok and went, L .. ": Make by the pad takes the floor's tomato", "queued " .. tostring(T.kinds) .. "; the tomato now " .. H.whereWord(T.tF))
    end)
    H.step(2, function() H.legClean() end)
end
function C.c3mine()
    local T = {}
    local L = "3c on him and in the crate (mouse)"
    H.step(2, function()
        H.legClean()
        T.crate = S.crate
        if not T.crate then T.off = true; return end
        H.crateClear(T.crate)
        T.baseIt = H.potWater()
        T.tH = H.food(S.FT.tomato, "fresh")
        T.tC = H.food(S.FT.tomato, "fresh", T.crate.inv)
        if not (T.baseIt and T.tH and T.tC) then Q.skip(L, "the pot and the two tomatoes could not be given"); T.off = true; return end
        T.word = H.contWord(T.crate.inv)
        T.inWord = getText("IGUI_Controller_Inventory")
        H.lootRefresh()
        H.rescan()
    end)
    H.toTab(T, L)
    H.pickDish(T, "Stew", L)
    H.pickBase(T, L)
    H.waitRows(T, { S.FT.tomato }, L)
    H.step(2, function() S.cookDrawn = {} end)
    Q.waitMs(800)
    H.step(2, function()
        if T.off then return end
        local g = H.snapRow(S.FT.tomato)
        Q.check(g ~= nil and g.n == 2 and g.where == nil, L .. " (call 3): one of the row's tomatoes is on him: the row has no aside",
            "the row x" .. tostring(g and g.n) .. ", says " .. tostring(g and g.where))
        Q.check(not H.seenAt(S.cookDrawn, T.word, 800) and not H.seenAt(S.cookDrawn, T.inWord, 800), L .. " (call 3): no aside is drawn",
            "drawn \"" .. tostring(T.word) .. "\" " .. tostring(H.seenAt(S.cookDrawn, T.word, 800)) .. ", \"" .. tostring(T.inWord) .. "\" " .. tostring(H.seenAt(S.cookDrawn, T.inWord, 800)))
    end)
    H.press(T, H.rowId(S.FT.tomato), "mouse", L)
    H.press(T, "cook:make", "mouse", L)
    H.step(1, function() T.t0 = getTimestampMs(); T.hH, T.hC = H.hunger(T.tH), H.hunger(T.tC) end)
    H.wait(40000, function() return T.off or (H.qlen() == 0 and getTimestampMs() - (T.t0 or 0) > 300) end, function(ok)
        if T.off then return end
        local nH = H.hunger(T.tH)
        local usedH = H.gone(T.tH) or (T.hH and nH and math.abs(nH - T.hH) > 0.0001)
        Q.check(ok and usedH and H.where(T.tC) == T.crate.inv, L .. ": Make takes the carried tomato, the crate's stays in the crate",
            "carried one " .. H.whereWord(T.tH, T.crate) .. ", the crate's " .. H.whereWord(T.tC, T.crate))
    end)
    H.step(2, function() H.legClean(); H.crateClear(T.crate) end)
end
function C.c3()
    H.step(2, function()
        H.caseStart()
        S.crate = H.mkCrate()
        if not S.crate then Q.skip("3 where (the crate legs)", "no free square beside him took a crate") end
    end)
    C.c3crate()
    C.c3floor()
    C.c3mine()
    H.step(2, function() S.crate = nil end)
    H.caseEnd("3 where")
end

-- ===================================================================== 4. dishes already made
-- queue: plan one of T.ft (read at run time) on the made dish T.dishIt (the base picked), read the line, Make by how,
-- judge: the ingredient went into THAT dish (its extra items +1, no new dish of its type, none of T.otherFt), the line
function C.c4add(T, L, how)
    H.wait(6000, function() return T.off or (T.ft ~= nil and H.czone(H.rowId(T.ft)) ~= nil) end, function(ok)
        if T.off then return end
        if not Q.check(ok, L .. ": the " .. tostring(T.ft) .. " row is listed", H.rowsText()) then T.off = true end
    end)
    H.press(T, function() return H.rowId(T.ft or "?") end, how, L)
    H.step(2, function()
        if T.off or T.stop then return end
        if not Q.check(H.planCount(T.ft) == 1, L .. ": one press (" .. how .. ") plans one " .. tostring(T.ft), "plan " .. H.planFts()) then T.stop = true end
    end)
    C.readLine(T, L)
    H.press(T, "cook:make", how, L)
    H.step(1, function()
        if T.off or T.stop then return end
        T.t0 = getTimestampMs()
        T.kinds = H.qkinds()
        T.ex0 = H.extras(T.dishIt)
        T.n0 = H.count(T.dishFt)
        T.other0 = T.otherFt and H.count(T.otherFt) or 0
    end)
    H.wait(40000, function() return T.off or T.stop or (H.qlen() == 0 and getTimestampMs() - (T.t0 or 0) > 300) end, function(ok)
        H.padOff()
        if T.off or T.stop then return end
        local ex1 = H.extras(T.dishIt)
        local n1 = H.count(T.dishFt)
        local other1 = T.otherFt and H.count(T.otherFt) or 0
        Q.check(ok and H.where(T.dishIt) == H.inv() and ex1 == T.ex0 + 1 and n1 == T.n0 and other1 == T.other0,
            L .. " (call 4): Make (" .. how .. ") puts the " .. tostring(T.ft) .. " into THAT dish: its ingredients one more, no new dish",
            "queued " .. tostring(T.kinds) .. "; its ingredients " .. T.ex0 .. " -> " .. ex1 .. "; " .. T.dishFt .. " " .. T.n0 .. " -> " .. n1
            .. (T.otherFt and ("; " .. T.otherFt .. " " .. T.other0 .. " -> " .. other1) or "") .. "; the dish in " .. H.whereWord(T.dishIt))
        C.judgeLine(T, L, T.dishIt)
    end)
end
-- the dish found in the tab's dish list, folded: one key carries this label, and the made dish is in its base list once
function C.c4listed(T, L, un)
    local s = H.cs()
    local lab = H.dishLabel(un)
    local n = 0
    for _, key in ipairs((s and s.dishList) or {}) do if H.dishLabel(key) == lab then n = n + 1 end end
    local seen = 0
    for _, o in ipairs((s and s.bases and s.dish and s.bases[s.dish]) or {}) do if o.item == T.dishIt then seen = seen + 1 end end
    Q.check(n == 1 and seen == 1, L .. " (call 4): " .. tostring(lab) .. " is one dish in the list, the made dish listed once as its base",
        n .. " dishes named " .. tostring(lab) .. ", the made dish " .. seen .. " time(s) in its base list; dishes " .. H.dishesText())
end
-- an ingredient the game's own list takes into T.dishIt: the recipe's possible items given one by one (no seasoning);
-- his own things of the type are set aside first. Sets T.ft, T.ing; returns how many types were tried
function C.c4pick(T)
    local tried = 0
    local poss = nil
    pcall(function() poss = T.r:getPossibleItems() end)
    if not poss then return tried end
    for i = 0, poss:size() - 1 do
        if T.ft or tried >= 10 then break end
        local ft = nil
        pcall(function() ft = H.fullType(poss:get(i):getFullType()) end)
        if ft and H.known(ft) then
            tried = tried + 1
            H.stashTypes({ [ft] = true })
            local it = H.give(ft)
            H.lootRefresh()
            local spice = false
            pcall(function() spice = it:isSpice() and true or false end)
            if it and not spice and H.gameHas(T.r, T.dishIt, it) then T.ft, T.ing = ft, it else H.removeItem(it) end
        end
    end
    return tried
end
function C.c4stew()
    local T = {}
    local L = "4a a stew the game made (mouse)"
    H.step(2, function()
        H.legClean()
        T.pot = H.potWater()
        T.tom = H.food(S.FT.tomato, "fresh")
        T.car = H.food(S.FT.carrot, "fresh")
        T.r = H.gameRecipe("Stew", S.FT.pot)
        T.dishFt = H.dishFtOf("Stew", S.FT.pot)
        if not (T.pot and T.tom and T.car and T.r and T.dishFt) then Q.skip(L, "a pot of water, a tomato, a carrot and the game's Stew could not be had"); T.off = true; return end
        T.before = H.setOf(T.dishFt)
        T.go = H.gameAdd(T.r, T.pot, T.tom)
        T.t0 = getTimestampMs()
        if not T.go then Q.skip(L, "the game's own add could not be queued"); T.off = true end
    end)
    H.wait(30000, function() return T.off or (H.qlen() == 0 and getTimestampMs() - (T.t0 or 0) > 300) end, function()
        if T.off then return end
        T.dishIt = H.newOf(T.dishFt, nil, T.before)
        if not T.dishIt then Q.skip(L, "the game's own add made no stew"); T.off = true; return end
        H.mark(T.dishIt)
        T.baseIt = T.dishIt
        T.ft = S.FT.carrot
        Q.check(H.isResult(T.r, T.dishIt) and H.extras(T.dishIt) < (H.maxOf(T.r) or 0) and H.gameHas(T.r, T.dishIt, T.car),
            L .. ": the game's stew is the Stew recipe's result with room left, and the game's own list takes the carrot into it",
            "ingredients " .. H.extras(T.dishIt) .. " of " .. tostring(H.maxOf(T.r)))
        H.lootRefresh()
        H.rescan()
    end)
    H.toTab(T, L)
    H.pickDish(T, "Stew", L)
    H.pickBase(T, L)
    H.step(2, function() if not T.off then C.c4listed(T, L, "Stew") end end)
    C.c4add(T, L, "mouse")
    H.step(2, function() H.legClean() end)
end
function C.c4soup()
    local T = {}
    local L = "4b a pot of soup, Soup2 (pad)"
    H.step(2, function()
        H.legClean()
        T.r = H.gameRecipe("Soup2", S.FT.soup)
        T.dishFt = S.FT.soup
        T.otherFt = S.FT.soupNew
        T.dishIt = H.give(S.FT.soup)
        T.baseIt = T.dishIt
        T.car = H.food(S.FT.carrot, "fresh")
        T.tom = H.food(S.FT.tomato, "fresh")
        if not (T.r and T.dishIt and T.car and T.tom) then Q.skip(L, "the game's Soup2 or a pot of soup could not be had"); T.off = true; return end
        if H.gameHas(T.r, T.dishIt, T.car) then T.ft = S.FT.carrot elseif H.gameHas(T.r, T.dishIt, T.tom) then T.ft = S.FT.tomato end
        if not T.ft then
            Q.skip(L, "the game's own list takes neither a carrot nor a tomato into the pot of soup here (ingredients " .. H.extras(T.dishIt) .. " of " .. tostring(H.maxOf(T.r)) .. ")")
            T.off = true
            return
        end
        Q.check(H.isResult(T.r, T.dishIt), L .. ": the pot of soup is Soup2's own result (base = result) and the game's own list takes a " .. T.ft .. " into it",
            "ingredients " .. H.extras(T.dishIt) .. " of " .. tostring(H.maxOf(T.r)))
        H.lootRefresh()
        H.rescan()
    end)
    H.toTab(T, L)
    H.pickDish(T, "Soup2", L)
    H.pickBase(T, L)
    H.step(2, function() if not T.off then C.c4listed(T, L, "Soup2") end end)
    H.step(2, function() if not T.off then H.cpress("cook:base") end end)
    H.shot("ck_calls_4_madedish_" .. H.sizeTag(), "the base list open on Soup: the pot of soup already made, listed as its base",
        function() local s = H.cs(); return not T.off and s ~= nil and s.popup == "base" end)
    H.step(2, function() local s = H.cs(); if s then s.popup = nil end end)
    C.c4add(T, L, "pad")
    H.step(2, function() H.legClean() end)
end
function C.c4toast()
    local T = {}
    local L = "4c toast (mouse)"
    H.step(2, function()
        H.legClean()
        T.r = H.gameRecipe("Toast", S.FT.toast)
        if not (T.r and H.known(S.FT.toast)) then Q.skip(L, "the game's getEvolvedRecipes has no Toast made on toast"); T.off = true; return end
        T.dishFt = S.FT.toast
        T.dishIt = H.give(S.FT.toast)
        T.baseIt = T.dishIt
        if not T.dishIt then Q.skip(L, "toast could not be given"); T.off = true; return end
        T.tried = C.c4pick(T)
        if not T.ft then Q.skip(L, "the game's own list takes none of the " .. T.tried .. " ingredients of the Toast recipe given into the toast"); T.off = true; return end
        H.note(L .. ": the toast is given, not toasted (the toaster is a craft station, not staged here); the game takes " .. T.ft .. " into it")
        H.rescan()
    end)
    H.toTab(T, L)
    H.pickDish(T, "Toast", L)
    H.pickBase(T, L)
    H.step(2, function() if not T.off then C.c4listed(T, L, "Toast") end end)
    C.c4add(T, L, "mouse")
    H.step(2, function() H.legClean() end)
end
function C.c4()
    H.step(2, function() H.caseStart() end)
    C.c4stew()
    C.c4soup()
    C.c4toast()
    H.caseEnd("4 made")
end

-- ===================================================================== 5. a base in reach, not carried
-- the queue's order at the press: the pot's move to him, the first add, the move back to the crate
function C.c5order(T, L)
    local mvIn, add, mvBack = nil, nil, nil
    for i, e in ipairs(T.q or {}) do
        if not mvIn and H.isMove(e) and e.item == T.pot and e.src == T.crate.inv then mvIn = i end
        if not add and H.isAdd(e) then add = i end
        if H.isMove(e) and e.item == T.pot and e.dst == T.crate.inv then mvBack = i end
    end
    Q.check(mvIn ~= nil and add ~= nil and mvIn < add, L .. " (call 5): Make moves the crate's pot to him before the first add",
        "queued " .. tostring(T.kinds) .. "; the pot's move at " .. tostring(mvIn) .. ", the first add at " .. tostring(add))
    if S.found.disorg then
        H.note(L .. ": he is Disorganized: the game queues no move back; the pot's move back at " .. tostring(mvBack))
    else
        Q.check(mvBack ~= nil and add ~= nil and mvBack > add, L .. " (call 5): and queues its move back to the crate after the adds, as the game's menu does",
            "the move back at " .. tostring(mvBack) .. " of " .. #(T.q or {}))
    end
end
-- one leg: a pot of water in the crate, a tomato on him; Make by how; then (once) the game's own add the same way
function C.c5leg(how, withGame)
    local T = {}
    local L = "5 a pot in the crate (" .. how .. ")"
    H.step(2, function()
        H.legClean()
        T.crate = S.crate
        if not T.crate then T.off = true; return end
        H.crateClear(T.crate)
        T.pot = H.potWater(T.crate.inv)
        T.baseIt = T.pot
        T.tom = H.food(S.FT.tomato, "fresh")
        T.r = H.gameRecipe("Stew", S.FT.pot)
        T.dishFt = H.dishFtOf("Stew", S.FT.pot)
        if not (T.pot and T.tom and T.r and T.dishFt) then Q.skip(L, "a pot of water in the crate and a tomato could not be given"); T.off = true; return end
        H.lootRefresh()
        H.rescan()
    end)
    H.step(4, function()
        if T.off then return end
        H.lootRefresh()
        local inReach = H.inConts(T.crate.inv)
        T.gameTakes = inReach and H.gameHas(T.r, T.pot, T.tom)
        if not Q.check(T.gameTakes, L .. ": the game's own list for the crate's pot (on its container list) takes the tomato",
            "the crate on the game's list " .. tostring(inReach)) then T.off = true end
    end)
    H.toTab(T, L)
    H.step(2, function()
        if T.off then return end
        Q.check(H.inStrip() and H.where(T.pot) == T.crate.inv, L .. " (call 5): the Cooking tab shows with no base on him (the pot is in the crate)", "in the strip " .. tostring(H.inStrip()))
    end)
    H.pickDish(T, "Stew", L)
    H.pickBase(T, L)
    H.step(2, function()
        if T.off then return end
        local b = H.curBase()
        Q.check(b ~= nil and b.item == T.pot and not b.mine, L .. " (call 5): the tab plans the Stew in the crate's pot", "base " .. H.nm(b and b.item) .. " carried " .. tostring(b and b.mine))
    end)
    H.waitRows(T, { S.FT.tomato }, L)
    H.press(T, H.rowId(S.FT.tomato), how, L)
    H.step(2, function() if not (T.off or T.stop) then T.before = H.setOf(T.dishFt, T.crate.inv) end end)
    H.press(T, "cook:make", how, L)
    H.step(1, function()
        if T.off or T.stop then return end
        T.q = H.qcopy()
        T.kinds = H.qkinds()
        T.t0 = getTimestampMs()
        C.c5order(T, L)
    end)
    H.wait(45000, function() return T.off or T.stop or (H.qlen() == 0 and getTimestampMs() - (T.t0 or 0) > 300) end, function(ok)
        H.padOff()
        if T.off or T.stop then return end
        T.stew = H.newOf(T.dishFt, T.crate.inv, T.before)
        T.zedEnd = T.stew and H.whereWord(T.stew, T.crate) or "none made"
        if T.stew then H.mark(T.stew) end
        Q.check(ok and T.stew ~= nil, L .. ": Make makes the stew from the crate's pot", "the stew " .. T.zedEnd .. "; the pot " .. H.whereWord(T.pot, T.crate))
        S.c5zed = S.c5zed or {}
        S.c5zed[#S.c5zed + 1] = { how = how, where = T.zedEnd }
    end)
    if withGame then
        H.step(2, function()
            if T.off then return end
            H.qstop()
            T.pot2 = H.potWater(T.crate.inv)
            T.tom2 = H.food(S.FT.tomato, "fresh")
            H.lootRefresh()
            T.before2 = H.setOf(T.dishFt, T.crate.inv)
            T.gameGo = H.gameAdd(T.r, T.pot2, T.tom2)
            T.t1 = getTimestampMs()
            T.kinds2 = H.qkinds()
            if not T.gameGo then Q.skip(L .. ": against the game's own add", "the game's add could not be queued") end
        end)
        H.wait(45000, function() return T.off or not T.gameGo or (H.qlen() == 0 and getTimestampMs() - (T.t1 or 0) > 300) end, function()
            if T.off or not T.gameGo then return end
            local st = H.newOf(T.dishFt, T.crate.inv, T.before2)
            if st then H.mark(st) end
            S.c5game = st and H.whereWord(st, T.crate) or "none made"
            H.note("5 the game's own add from the crate (" .. tostring(T.kinds2) .. "): its stew ends in " .. S.c5game .. "; the pot " .. H.whereWord(T.pot2, T.crate))
        end)
    end
    H.step(2, function() H.legClean(); H.crateClear(T.crate) end)
end
function C.c5()
    H.step(2, function()
        H.caseStart()
        S.c5zed, S.c5game = {}, nil
        S.crate = H.mkCrate()
        if not S.crate then Q.skip("5 reach", "no free square beside him took a crate") end
    end)
    C.c5leg("mouse", true)
    C.c5leg("pad", false)
    H.step(2, function()
        for _, z in ipairs(S.c5zed or {}) do
            -- (Nov 25 2026: the game's own add leaves the stew in his bags, its move back being for the pot the first add
            -- replaced; ZeD now puts the dish back where the base came from, fix/cookback ZeD_CookReturn: a NOTE, not a
            -- check, that ZeD and the game differ here)
            if S.c5game then
                H.note("5 (" .. z.how .. ") (call 5): ZeD's stew ends in " .. tostring(z.where) .. "; the game's own add from the crate leaves its stew in " .. tostring(S.c5game))
            end
            Q.check(z.where == "the crate", "5 (" .. z.how .. ") (call 5, its words): the stew ends back in the crate",
                "ZeD: " .. tostring(z.where) .. "; the game's own add: " .. tostring(S.c5game))
        end
        S.crate = nil
    end)
    H.caseEnd("5 reach")
end

-- ===================================================================== 6. the tab opens on the last dish made
-- queue: the tab's dish cleared (fresh: its whole state made afresh) and read on the next draws
function C.c6reopen(T, key, fresh)
    H.step(2, function()
        if T.off then return end
        local w, s = RT.cw(), H.cs()
        if fresh then
            if w then w._cook = nil end
        elseif s then
            s.dish, s.plan = nil, {}
        end
        H.rescan()
    end)
    H.wait(4000, function() local s = H.cs(); return T.off or (s ~= nil and s.dish ~= nil and H.drawn()) end, function(ok)
        if T.off then return end
        local s = H.cs()
        T[key] = s and s.dish
    end)
end
function C.c6()
    local T = {}
    local L = "6 last dish"
    H.step(2, function()
        H.caseStart()
        H.legClean()
        T.pot = H.potWater()
        T.t1 = H.food(S.FT.tomato, "fresh")
        T.t2 = H.food(S.FT.tomato, "fresh")
        T.dishFt = H.dishFtOf("Stew", S.FT.pot)
        if not (T.pot and T.t1 and T.t2 and T.dishFt) then Q.skip(L, "a pot of water and two tomatoes could not be given"); T.off = true; return end
        H.md()[S.MD_LAST] = nil
        T.soup, T.stew = H.dishLabel("Soup"), H.dishLabel("Stew")
        H.lootRefresh()
        H.rescan()
    end)
    H.toTab(T, L)
    C.c6reopen(T, "d0", false)
    H.step(2, function()
        if T.off then return end
        Q.check(T.d0 ~= nil and H.dishLabel(T.d0) == T.soup, L .. ": with no dish stored, a pot of water and a tomato open on " .. tostring(T.soup) .. " (the first rule; the call's \"before\")",
            "opened on " .. tostring(T.d0) .. "; dishes " .. H.dishesText())
    end)
    H.pickDish(T, "Stew", L)
    H.waitRows(T, { S.FT.tomato }, L)
    H.press(T, H.rowId(S.FT.tomato), "pad", L)
    H.press(T, "cook:make", "pad", L)
    H.step(1, function() T.t0 = getTimestampMs(); T.before = H.setOf(T.dishFt) end)
    H.wait(30000, function() return T.off or T.stop or (H.qlen() == 0 and getTimestampMs() - (T.t0 or 0) > 300) end, function(ok)
        H.padOff()
        if T.off or T.stop then return end
        Q.check(ok and H.newest(T.dishFt) ~= nil and H.lastDish() == T.dishKey, L .. " (call 6): a Stew made by the pad is stored (" .. S.MD_LAST .. ")",
            "stored " .. tostring(H.lastDish()) .. ", the dish " .. tostring(T.dishKey) .. ", made " .. H.ft(H.newest(T.dishFt)))
        T.pot2 = H.potWater()
        H.lootRefresh()
    end)
    C.c6reopen(T, "d1", false)
    H.step(2, function()
        if T.off or T.stop then return end
        Q.check(T.d1 == T.dishKey, L .. " (call 6): the dish cleared, a pot of water and a tomato in reach: the tab opens on Stew, not Soup", "opened on " .. tostring(T.d1))
    end)
    C.c6reopen(T, "d2", true)
    H.step(2, function()
        if T.off or T.stop then return end
        Q.check(T.d2 == T.dishKey, L .. " (call 6): the tab's state made afresh (as a new window): it opens on Stew", "opened on " .. tostring(T.d2))
    end)
    -- no Stew base in reach: the first rule
    H.step(2, function()
        if T.off or T.stop then return end
        H.qstop()
        for _, it in ipairs(S.caseMade) do H.removeItem(it) end
        S.caseMade = {}
        H.sweepNew()
        T.bread = H.give(S.FT.bread)
        T.car = H.food(S.FT.carrot, "fresh")
        H.lootRefresh()
        H.rescan()
    end)
    Q.waitMs(1200)
    C.c6reopen(T, "d3", false)
    H.step(2, function()
        if T.off or T.stop then return end
        -- (a pot in a cupboard of the QA house would still be a Stew base in reach: then the fallback is not staged)
        local s = H.cs()
        local stewBases = s and s.bases and s.bases[T.dishKey]
        if stewBases and #stewBases > 0 then
            Q.skip(L .. " (call 6): the fallback with no Stew base in reach", #stewBases .. " Stew base(s) still in reach here (the house's own), first " .. H.nm(stewBases[1].item))
        else
            Q.check(T.d3 ~= nil and T.d3 ~= T.dishKey, L .. " (call 6): with no Stew base in reach (bread and a carrot) the tab falls back to the first rule",
                "opened on " .. tostring(T.d3) .. "; stored " .. tostring(H.lastDish()))
        end
        H.md()[S.MD_LAST] = S.found.last
    end)
    H.caseEnd("6 last dish")
end

-- ===================================================================== put back
function H.putBack()
    if not S.back.on then return end
    S.back.on = nil
    local f = S.found
    H.speed(1)
    H.qstop()
    H.park(false)
    H.hoverOff()
    H.padOff()
    H.wrapOff()
    pcall(function() S.ST.unbind(S.p) end)
    for _, c in ipairs(S.objs) do H.rmObj(c) end
    for _, it in ipairs(S.made) do H.removeItem(it) end
    S.xpGrew, S.xpLeft = H.xpBack()
    if f.recorded then
        local md = S.p:getModData()
        if f.dishes then local t = {}; for i, d in ipairs(f.dishes) do t[i] = d end; md.ZeD_CookDishes = t else md.ZeD_CookDishes = nil end
        md[S.MD_LAST] = f.last
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
                    for i, e in ipairs(f.cook.plan) do pl[i] = { ft = e.ft, key = e.key, name = e.name, base = e.base, spice = e.spice } end
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
        if f.layout and ZEDQA_LAYOUT_BACK then pcall(ZEDQA_LAYOUT_BACK, f.layout, "ck_calls") end
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
        Q.check(#left == 0, "put back: every thing the run gave or made is gone (the bags, the floor, the crate)", #S.made .. " given; left " .. H.list(left, 8))
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
        Q.check(lvlLeft == 0 and H.lvl() == f.lvl, "put back: the skill levels as found (Cooking " .. tostring(f.lvl) .. ")", tostring(S.xpGrew) .. " skills changed, " .. lvlLeft .. " not at their level")
        local md = S.p:getModData()
        local nowN = (type(md.ZeD_CookDishes) == "table") and #md.ZeD_CookDishes or -1
        local same = nowN == (f.dishesN or -1)
        if same and f.dishes then for i, d in ipairs(f.dishes) do if md.ZeD_CookDishes[i] ~= d then same = false end end end
        Q.check(same and md[S.MD_LAST] == f.last, "put back: the saved dishes and the last dish made as found (" .. S.MD_LAST .. ")",
            nowN .. " saved now, " .. tostring(f.dishesN) .. " found; last " .. tostring(md[S.MD_LAST]) .. " (found " .. tostring(f.last) .. ")")
        local s = RT.cw() and RT.cw()._cook
        local wantSort = (f.cook and f.cook.sort) or "name"
        local wantN = (f.cook and #f.cook.plan) or 0
        Q.check(s == nil or (s.sort == wantSort and s.popup == nil and (#(s.plan or {}) == wantN or #(s.plan or {}) == 0)),
            "put back: the Cooking tab's sort, plan and lists as found", tostring(s and s.sort) .. ", " .. tostring(s and #(s.plan or {})) .. " planned (found "
            .. tostring(wantSort) .. ", " .. wantN .. "), a list open " .. tostring(s and s.popup))
        local dx, dy = math.abs(S.p:getX() - f.pos.x), math.abs(S.p:getY() - f.pos.y)
        Q.check(dx < 0.6 and dy < 0.6 and S.ST.current(S.p) == (f.st or nil) and H.qlen() == 0 and getGameSpeed() == 1,
            "put back: he stands where he stood, the station as found, no action queued, game speed 1", string.format("%.1f,%.1f off", dx, dy) .. ", " .. H.qkinds())
        Q.check(H.lockFound() == (S.lockWas or H.lockFound()) and S.parked == nil and S.hov == nil and S.w0 == nil and H.wrapped(),
            "put back: the input lock, the pointer, its hover and the draw watchers as found", "lock " .. H.lockFound() .. " (found " .. tostring(S.lockWas) .. ")")
        Q.check(S.errs == 0, "put back: nothing ZeD ran for this script threw", S.errs .. " caught" .. (S.zerr and (": " .. S.zerr) or ""))
        local e1 = H.errN()
        if S.err0 and e1 then Q.check(e1 == S.err0, "the Cooking calls run ran with no Lua error", (e1 - S.err0) .. " new")
        else Q.skip("the Cooking calls run's Lua error count", "the game's Lua error count cannot be read here") end
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
S.buildPutBack()
Q.start()
