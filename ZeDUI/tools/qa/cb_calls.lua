-- ZeDUI/tools/qa/cb_calls.lua  (Nov 25 2026, QA; tag cb_calls): the director's 7 design calls for the World window's
-- Crafting and Build tabs ("1 on all", Nov 25 2026), as Build made them (feat/cbcalls, 1abae271c, merged to main),
-- each proved in the running game with values, by the mouse and by the pad, with pictures of the new looks. Run after
-- zedqa_prelude.lua and rt_kit.lua (cb_calls.txt). grep "ZEDQA cb_calls". Helpers, staging and the put-back are
-- cr_tab.lua's and bd_tab.lua's (copied: the script stands alone).
-- How it drives the tabs: a click is the tab's own handler where the click lands (ZeD.CraftingTab.onClick /
-- ZeD.BuildingTab.onClick at the zone's middle), a right-click the same; the pad's presses go through FocusManager's
-- QA hook and its own dispatch (RT.pad + RT.padDown on the World window), the input mode locked to the controller and
-- put back as found. Placing a build is the game's own DoTileBuilding with the cursor's build flag set, as a click's
-- release does (bd_tab's). The game's own answers are asked of the game (HandcraftLogic and BuildLogic on the game's
-- container list, the queue, getJobDelta, CraftRecipeManager.hasPlayerRequiredSkill, the input scripts' own checks in
-- the order ISWidgetInput.lua:401-471 asks them), never through ZeD's code under test. The debug cheats (instant
-- actions, BuildCheat, ISBuildMenu.cheat) are off for the run; crafts run at x5 or x20 where a case says, walks at x1.
-- His own things the recipes here take are set aside for the run and his hands emptied, so every craft and build uses
-- only what a case gives.
-- Cases (call n = the director's call; pictures cb_calls_<n>_<what>_<theme>_<WxH>, theme dark / light / hc):
--   1 items    Make Stake with a knife (worn to half), two tree branches (one worn where a branch has a condition) and a
--              wooden stick: the branch type chosen in the alternatives opens one row per branch in reach, each row's
--              uses or condition the game's own (and a drainable's uses read through IsDrainable / getCurrentUsesFloat);
--              a click on a row chooses that very branch (state.itemPicks); both chosen, then one: Max follows them (2,
--              then 1) and the slot row names the first chosen and counts them; the stick's type chosen clears the
--              branches (all chosen items one type); the branch the game's own logic would NOT take is chosen, Craft:
--              that branch is used, the other branch and the stick are not. Then by the pad: A on the type row clears
--              and chooses, A on craft:altItem:<id> chooses a new branch, B leaves the list; the branch carried off out
--              of reach, A on Craft: refused (nothing queued, the other branch kept) with the game's words
--              (IGUI_CraftingWindow_Error_Inputs). Pictures 1_itemrows. Also: the slot row after the craft still counting
--              the chosen branch it used up (a check)
--   2 band     a batch of 3 stakes (Max, Craft by the mouse): the accent band draws over the card with the recipe's name,
--              its share is the running craft's own getJobDelta and rises; X (zone craftCancel) in the second craft:
--              no craft left, the queue empty (the game's stop resets it), nothing more made, the branches not used
--              kept, Craft lit again. A batch of 6 by the pad: pictures 2_band while it runs, then A on craft:craftCancel
--              empties the queue. X during a walk: Drill Plank at a table 2 squares off with its things in a crate
--              (the moves and the walk come first), by the mouse; Make Ceramic Teacup at a pottery wheel 2-3 squares off,
--              by the pad: the band shows at 0 before the craft, X takes ZeD's crafts out and the walk (or move) goes
--              on, nothing is made
--   3 notes    CC.inputNotes for every input of every Craft recipe against the game's own tooltip checks (its order, its
--              keys, its keep rule; NOTE the duplicates the game prints and the consumed inputs whose notes the card
--              does not draw); Make Stake's card: the knife row's notes (MayDegrade, IsNotDull) drawn under it, dim, in
--              the small font, wrapped; still drawn with the pad's focus on that row. Pictures 3_toolnotes
--   4 pins     Craft and Build: 10 recipes pinned past what was found (8 from code as a right-click does, the 9th by a
--              right-click on its row, the 10th by the pad's X): all 10 kept, none of the found pins dropped, all in the
--              Pinned group; NOTE the game's favourite flags (C18). Pins and flags put back as found
--   5 double   Build: two clicks on the cross's row inside 300 ms start the build cursor (counted once); two clicks 600
--              ms apart do not; the pad's A then A does; a double-click on a row that cannot be built starts nothing
--   6 skill    a fresh Build tab opens on Show: All; Carpentry set to 0: every row short of skill carries the game's skill
--              name and level ("Carpentry 3", the first skill CraftRecipeManager.hasPlayerRequiredSkill says is short),
--              no other row a tag; the crate's row draws the tag in the danger color (Molecules.drawRecipeRow and
--              Atoms.drawTag watched), the border still danger with the pad's focus on it. Pictures 6_skilltag
--   7 build    the rugged cross: the branch-or-stick and long-stick-or-sapling slots, the types the game's own logic would
--              NOT take (in the crate beside him) chosen, the first by the mouse, the second by the pad (A, A, then B
--              leaves the list and the card stays): no item rows on the Build list (picks by type); Build: the cursor's
--              own logic holds the chosen items, the cross placed 2 squares off stands, the chosen ones used (moved to
--              him before the walk), the carried ones kept; Build again with the chosen types gone, by the pad: no
--              cursor, the game's words; B on the card closes it. Planks: SKIP when no build slot takes planks with a
--              second type (the card offers no list on a one-type slot). Pictures 7_picklist
--   every case: no Lua error over it; everything it gave, crafted, laid or built is gone after it (a check names any)
-- Puts back: every thing given or made (inventory, crates, floor), every object laid or built (named if left), his own
-- set-aside things and his hands, the skill levels (XP drift a NOTE), the cheats, the clock and his stats, ZeD's craft and
-- build pins and counts and the game's favourite flags, the found Build tab state, both tabs' Show, Sort, category,
-- search, picks and card, a bound station, the theme, the input lock, the pointer, the draw watchers, the window pair, its
-- tab and layout, where he stood. God mode is made sure on and left on (as cr_tab leaves it).
-- NOT put back: XP the crafts and builds award beyond what the game lets Lua set back exactly (a NOTE at the end).

if not (RT and RT.make) then
    print("ZEDQA cb_calls ERR rt_kit.lua did not run first")
    print("ZEDQA cb_calls VERDICT FAIL 1")
    print("ZEDQA cb_calls DONE")
    return
end
local Q = RT.make("cb_calls")
Q.maxMs = 1620000                    -- (the runner gives this script 1800 s: the put-back runs before that)
local S = { p = RT.p, pn = RT.pn, found = {}, back = {}, made = {}, caseMade = {}, objs = {}, built = {}, stash = {},
            shots = {}, errs = 0, tabErrs = 0, dead = false, fav = {}, xp = {}, halo = {}, slotSeen = {}, rowSeen = {},
            rowTagC = {}, cards = {}, bandLog = {} }
local H = {}
local C = {}
S.CC = ZeD and ZeD.CraftingCore
S.CT = ZeD and ZeD.CraftingTab
S.BT = ZeD and ZeD.BuildingTab
S.ST = ZeD and ZeD.Stations
S.WW = ZeD_WorldWindow
S.F = RT.focus()
S.TB = {
    craft = { key = "_craftState", cache = "_craftCache", search = "_craftSearch", mod = S.CT, pins = "_craftPins", pinKey = "ZeD_CraftPins" },
    build = { key = "_buildState", cache = "_buildCache", search = "_buildSearch", mod = S.BT, pins = "_buildPins", pinKey = "ZeD_BuildPins" },
}
S.R = { stake = "MakeStake", drill = "DrillPlank", cup = "MakeCeramicTeacup" }
S.OUT = { stake = "Base.Stake", drill = "Base.PercedWood", cup = "Base.CeramicTeacupUnfired" }
S.KIND = {
    branch = { "Base.TreeBranch2" }, stick = { "Base.WoodenStick2" }, knife = { "Base.HuntingKnife", "Base.KitchenKnife" },
    plank = { "Base.Plank" }, driver = { "Base.Screwdriver" }, clay = { "Base.Clay" }, sandbag = { "Base.Sandbag" },
    drain = { "Base.DuctTape", "Base.Glue", "Base.Thread", "Base.Twine" },
}
-- the build recipes (the game's name; by words when a build names them otherwise: bd_tab's)
S.BR = { cross = { name = "RuggedCross", words = { "cross" } }, crate = { name = "Wood_Crate_Lvl1", words = { "crate" } } }
-- his own building things set aside (bd_tab's list; hammers by their tag)
S.OWN = { "Base.TreeBranch2", "Base.WoodenStick2", "Base.LongStick", "Base.Sapling", "Base.RippedSheets",
          "Base.RippedSheetsDirty", "Base.Twine", "Base.Rope", "Base.SheetRope", "Base.Plank", "Base.Nails",
          "Base.NailsBox", "Base.Hammer", "Base.HammerStone", "Base.BallPeenHammer", "Base.ClubHammer" }
S.TABLES = { "furniture_tables_high_01_16", "furniture_tables_high_01_0", "furniture_tables_high_01_8", "furniture_tables_high_01_24",
    "furniture_tables_high_01_32", "furniture_tables_high_01_40", "furniture_tables_low_01_0", "furniture_tables_low_01_8" }
S.CRATE = "carpentry_01_16"
S.WHEEL = "Base.Pottery_Wheel"
S.NEAR = { { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }
S.FAR2 = { { 2, 0 }, { 0, 2 }, { -2, 0 }, { 0, -2 }, { 2, 1 }, { 1, 2 }, { -2, 1 }, { -1, 2 }, { 2, -1 }, { -1, -2 },
           -- (3 off as well: at the drag strip the 2-off ring was all taken in the first run)
           { 3, 0 }, { 0, 3 }, { -3, 0 }, { 0, -3 }, { 3, 1 }, { 1, 3 }, { -3, 1 }, { 1, -3 }, { 3, -1 }, { -1, 3 } }
S.RING2 = { { 2, 0 }, { 0, 2 }, { -2, 0 }, { 0, -2 }, { 2, 2 }, { -2, 2 }, { 2, -2 }, { -2, -2 }, { 2, 1 }, { 1, 2 }, { -2, 1 }, { 1, -2 },
            { 3, 0 }, { 0, 3 }, { -3, 0 }, { 0, -3 }, { 3, 2 }, { 2, 3 }, { -3, 2 }, { 2, -3 } }
S.WHEEL_AT = { { 2, 0 }, { 0, 2 }, { -2, 0 }, { 0, -2 }, { 3, 0 }, { 2, 2 }, { -3, 0 }, { -2, -2 } }
S.THEMES = { { key = "dark", tag = "dark", word = "Dark" }, { key = "light", tag = "light", word = "Light" },
             { key = "hicon", tag = "hc", word = "High contrast" } }
S.STATS = { "HUNGER", "THIRST", "FATIGUE", "BOREDOM", "STRESS", "ENDURANCE", "UNHAPPINESS", "PANIC", "MORALE", "SANITY", "ANGER",
    "DISCOMFORT", "IDLENESS", "WETNESS" }
-- the game's input tooltip, as ISWidgetInput.lua:401-471 asks it: { the input script's check, the game's key, only for
-- a kept item }, in the game's own order (typed from the game's file, not from ZeD's table)
S.GAME_NOTES = {
    { "isSharpenable", "IGUI_CraftingWindow_IsSharpenable" }, { "mayDegrade", "IGUI_CraftingWindow_MayDegrade", true },
    { "mayDegradeLight", "IGUI_CraftingWindow_MayDegradeLight", true }, { "mayDegradeVeryLight", "IGUI_CraftingWindow_MayDegradeLight", true },
    { "sharpnessCheck", "IGUI_CraftingWindow_SharpnessCheck", true }, { "mayDegradeHeavy", "IGUI_CraftingWindow_MayDegradeHeavy", true },
    { "isNotDull", "IGUI_CraftingWindow_IsNotDull" }, { "isWorn", "IGUI_CraftingWindow_IsWorn" }, { "isNotWorn", "IGUI_CraftingWindow_IsNotWorn" },
    { "isFull", "IGUI_CraftingWindow_IsFull" }, { "isEmpty", "IGUI_CraftingWindow_IsEmpty" }, { "notFull", "IGUI_CraftingWindow_NotFull" },
    { "notEmpty", "IGUI_CraftingWindow_NotEmpty" }, { "isDamaged", "IGUI_CraftingWindow_IsDamaged" }, { "isUndamaged", "IGUI_CraftingWindow_IsUndamaged" },
    { "allowFrozenItem", "IGUI_CraftingWindow_AllowFrozenItem" }, { "dontAllowFrozenItem", "IGUI_CraftingWindow_DontAllowFrozenItem" },
    { "allowRottenItem", "IGUI_CraftingWindow_AllowRottenItem" }, { "allowDestroyedItem", "IGUI_CraftingWindow_AllowDestroyedItem" },
    { "isEmptyContainer", "IGUI_CraftingWindow_IsEmptyContainer" }, { "isWholeFoodItem", "IGUI_CraftingWindow_IsWholeFoodItem" },
    { "isUncookedFoodItem", "IGUI_CraftingWindow_IsUncookedFoodItem" }, { "isCookedFoodItem", "IGUI_CraftingWindow_IsCookedFoodItem" },
    { "isHeadPart", "IGUI_CraftingWindow_IsHeadPart" },
}

if not (S.p and S.CC and S.CT and S.BT and S.ST and S.WW and S.F) then
    Q.check(false, "the player, ZeD's Crafting and Building tabs, stations, the World window and FocusManager are loaded")
    Q.start()
    return
end
S.orig = { walk = ISEntityUI and ISEntityUI.WalkToEntity }

-- ===================================================================== small helpers
function H.errN() local n = nil; pcall(function() n = getLuaDebuggerErrorCount() end); return n end
function H.step(n, fn) Q.step(n, function() if S.dead then return end; fn() end) end
function H.noop() end
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
-- a Java or Lua method called only when the object has it: nil when missing or when it throws
function H.call(o, m, ...)
    if o == nil then return nil end
    local f = o[m]
    if not f then return nil end
    local ok, r = pcall(f, o, ...)
    if ok then return r end
    return nil
end
function H.list(t, max)
    max = max or 8
    local o = {}
    for i = 1, math.min(#(t or {}), max) do o[#o + 1] = tostring(t[i]) end
    local s = table.concat(o, ", ")
    if #(t or {}) > max then s = s .. " (+" .. (#t - max) .. " more)" end
    return (s ~= "") and s or "none"
end
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
function H.sameColor(a, b)
    if a == nil or b == nil then return false end
    if a == b then return true end
    local same = false
    pcall(function() same = math.abs(a.r - b.r) < 0.01 and math.abs(a.g - b.g) < 0.01 and math.abs(a.b - b.b) < 0.01 end)
    return same
end

-- ===================================================================== the timed-action queue
function H.queue() local q = nil; pcall(function() q = ISTimedActionQueue.getTimedActionQueue(S.p) end); return (q and q.queue) or {} end
function H.qlen() return #H.queue() end
function H.head() local a = H.queue()[1]; return a and tostring(a.Type) or "none" end
function H.qcount(ty) local n = 0; for _, a in ipairs(H.queue()) do if a.Type == ty then n = n + 1 end end; return n end
function H.qkinds() local o = {}; for _, a in ipairs(H.queue()) do o[#o + 1] = tostring(a.Type) end; return H.list(o, 10) end
function H.qhas(a) for _, x in ipairs(H.queue()) do if x == a then return true end end; return false end
function H.qstop() pcall(function() ISTimedActionQueue.clear(S.p) end) end
function H.delta(a) local d = nil; if a then pcall(function() d = a:getJobDelta() end) end; return d end
-- a craft watched to its end every drawn frame: crafts at x20, walks and moves at x1 (cr_tab's)
function H.watchNew(ft) return { ft = ft, c0 = H.count(ft), cur = nil, crafts = 0 } end
function H.watchTick(W)
    if not W then return true end
    local a = H.queue()[1]
    if a ~= W.cur then
        W.cur = a
        if a and a.Type == "ISHandcraftAction" then W.crafts = W.crafts + 1 end
        H.speed((a and a.Type == "ISHandcraftAction") and 3 or 1)
    end
    if W.onTick and a then pcall(W.onTick, W, a) end
    return a == nil
end

-- ===================================================================== things
function H.isItem(it) local ok = false; if it ~= nil then pcall(function() ok = instanceof(it, "InventoryItem") end) end; return ok end
function H.ft(it) local s = "?"; if H.isItem(it) then pcall(function() s = tostring(it:getFullType()) end) end; return s end
function H.nm(it) local s = "nothing"; if H.isItem(it) then pcall(function() s = tostring(it:getDisplayName()) end) end; return s end
function H.id(it) local s = nil; if H.isItem(it) then pcall(function() s = it:getID() end) end; return tostring(s) end
function H.where(it) local c = nil; if H.isItem(it) then pcall(function() c = it:getContainer() end) end; return c end
function H.ctype(c) local t = "none"; if c then pcall(function() t = tostring(c:getType()) end) end; return t end
function H.onFloor(it) local wo = nil; if H.isItem(it) then pcall(function() wo = it:getWorldItem() end) end; return wo ~= nil end
function H.gone(it) return H.where(it) == nil and not H.onFloor(it) end
function H.inv() return S.p:getInventory() end
function H.carried(it) local c = H.where(it); return c ~= nil and c == H.inv() end
function H.known(ft) local ok = false; if ft then pcall(function() ok = getScriptManager():FindItem(ft) ~= nil end) end; return ok end
function H.kind(k) for _, ft in ipairs(S.KIND[k] or {}) do if H.known(ft) then return ft end end; return nil end
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
function H.give(ft)
    if not ft then return nil end
    local it = nil
    pcall(function() it = H.inv():AddItem(ft) end)
    return H.mark(it)
end
function H.giveN(ft, n) local out = {}; for _ = 1, n do local it = H.give(ft); if it then out[#out + 1] = it end end; return out end
function H.giveTo(inv, ft) local it = nil; if inv and ft then pcall(function() it = inv:AddItem(ft) end) end; return H.mark(it) end
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
function H.cond(it) local c, m = "?", "?"; pcall(function() c, m = it:getCondition(), it:getConditionMax() end); return tostring(c) .. "/" .. tostring(m) end
-- worn to half its condition, where it has one (true when it took)
function H.halfCond(it)
    local mx = H.call(it, "getConditionMax")
    if type(mx) ~= "number" or mx < 2 then return false end
    H.call(it, "setCondition", math.floor(mx / 2))
    return H.call(it, "getCondition") == math.floor(mx / 2)
end
-- an item row's state in the game's own numbers: the share of uses left of a drainable, else the condition when worn
function H.detailWant(it)
    local s = ""
    pcall(function()
        if it:IsDrainable() then s = tostring(math.floor(it:getCurrentUsesFloat() * 100 + 0.5)) .. "%"; return end
        local mx, c = it:getConditionMax(), it:getCondition()
        if mx and mx > 0 and c < mx then s = tostring(c) .. "/" .. tostring(mx) end
    end)
    return s
end
function H.md(key, name) local v = 0; pcall(function() local m = S.p:getModData()[key]; v = (m and m[name]) or 0 end); return v end

-- ===================================================================== his own things set aside, and given back
function H.isHammer(it)
    local yes = false
    pcall(function() if ItemTag and ItemTag.HAMMER then yes = it:hasTag(ItemTag.HAMMER) and true or false end end)
    return yes
end
function H.stashTypes(set)
    local kept = 0
    for _, it in ipairs(H.all()) do
        if (set[H.ft(it)] or H.isHammer(it)) and not S.found.stashed[it] then
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

-- ===================================================================== skills (bd_tab's: every perk's level and XP kept)
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
                local nx, nl2 = xp:getXP(r.perk), S.p:getPerkLevel(r.perk)
                if math.abs(nx - r.xp) > 0.01 or nl2 ~= r.lvl then
                    left = left + 1
                    S.xpLeftText = (S.xpLeftText or "") .. tostring(r.perk) .. " level " .. tostring(nl2) .. " (found " .. tostring(r.lvl) .. ") xp "
                        .. string.format("%.2f", nx) .. " (found " .. string.format("%.2f", r.xp) .. "); "
                end
            end
        end
    end)
    pcall(function() SyncXp(S.p) end)
    return grew, left
end
function H.level(perkKey) local v = nil; local pk = Perks and Perks[perkKey]; if pk then pcall(function() v = S.p:getPerkLevel(pk) end) end; return v end
function H.setLevel(perkKey, lvl) local pk = Perks and Perks[perkKey]; if pk then pcall(function() S.p:setPerkLevelDebug(pk, lvl) end) end end
-- a perk back to the level found (the XP is set back in full at the end)
function H.levelBack(perkKey)
    local pk = Perks and Perks[perkKey]
    for _, r in ipairs(S.xp) do if r.perk == pk then pcall(function() S.p:setPerkLevelDebug(pk, r.lvl) end) end end
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
    if not list then pcall(function() list = S.CC.craftContainers(S.p) end) end
    return list
end
function H.lootRefresh()
    pcall(function() local lp = getPlayerLoot(S.pn); if lp and lp.refreshBackpacks then lp:refreshBackpacks() end end)
    pcall(function() local ip = getPlayerInventory(S.pn); if ip and ip.refreshBackpacks then ip:refreshBackpacks() end end)
    pcall(function() triggerEvent("OnContainerUpdate") end)
    local w = RT.ww()
    if w then w._containersDirty = true; w._buildContainerAt = nil; w._buildTypeCache = nil end
end
function H.recipe(name)
    local r = nil
    pcall(function() local sm = getScriptManager(); r = sm:getCraftRecipe(name) or sm:getCraftRecipe("Base." .. name) end)
    return r
end
-- a HandcraftLogic as the game's craft window makes it
function H.logic(name, bench)
    local l = nil
    pcall(function()
        l = HandcraftLogic.new(S.p, bench and bench.comp or nil, bench and bench.obj or nil)
        l:setContainers(H.conts())
        l:setRecipe(H.recipe(name))
    end)
    return l
end
function H.gameMost(name, flag)
    local most = nil
    local l = H.logic(name)
    if l then pcall(function() l:canPerformCurrentRecipe(); most = l:getPossibleCraftCount(flag and true or false) end) end
    return most
end
-- the things the game's own logic would use for one craft (a set)
function H.gameUses(name)
    local set = {}
    local l = H.logic(name)
    if l then
        pcall(function()
            l:canPerformCurrentRecipe()
            local items = l:getRecipeData():getAllInputItems()
            for i = 0, items:size() - 1 do set[items:get(i)] = true end
        end)
    end
    return set
end
-- a BuildLogic set up as the game's build panel sets its up (bd_tab's)
function H.bLogic(entry)
    local l = nil
    if not (entry and entry.recipe) then return nil end
    pcall(function()
        local g = BuildLogic.new(S.p, nil, nil)
        g:setRecipes(g:getAllBuildableRecipes())
        g:setRecipe(entry.recipe)
        g:setContainers(H.conts())
        l = g
    end)
    return l
end
function H.bUses(entry)
    local set = {}
    local l = H.bLogic(entry)
    if l then
        pcall(function()
            l:canPerformCurrentRecipe()
            local items = l:getRecipeData():getAllInputItems()
            for i = 0, items:size() - 1 do set[items:get(i)] = true end
        end)
    end
    return set
end
-- the first required skill the game says he is short of, in the game's own words for its name and level
function H.gameSkillTag(entry)
    local out = nil
    pcall(function()
        local r = entry.recipe
        for i = 0, r:getRequiredSkillCount() - 1 do
            local rs = r:getRequiredSkill(i)
            if out == nil and not CraftRecipeManager.hasPlayerRequiredSkill(rs, S.p) then
                out = tostring(rs:getPerk():getName()) .. " " .. tostring(rs:getLevel())
            end
        end
    end)
    return out
end
-- the game's input tooltip notes for an input script, in its order (dupes kept), and the same with each key once
function H.gameNotes(script)
    local all, once, seen = {}, {}, {}
    if not script then return all, once end
    local keep = false
    pcall(function() keep = script:isKeep() and true or false end)
    for _, n in ipairs(S.GAME_NOTES) do
        local on = false
        pcall(function() on = script[n[1]](script) and true or false end)
        if on and (keep or not n[3]) then
            local text = getText(n[2]) or n[2]
            text = string.gsub(text, "%s*<[bB][rR]>%s*", " ")
            all[#all + 1] = text
            if not seen[n[2]] then seen[n[2]] = true; once[#once + 1] = text end
        end
    end
    return all, once
end

-- ===================================================================== the tabs (tb: "craft" or "build")
function H.st(tb) local w = RT.ww(); return w and w[S.TB[tb].key] or nil end
function H.dat(tb) local w = RT.ww(); return w and w[S.TB[tb].cache] or nil end
function H.row(tb, name) local d = H.dat(tb); return (d and d.byName and name) and d.byName[name] or nil end
function H.entry(tb, name)
    local rd = H.row(tb, name)
    if rd then return rd.entry end
    local d = H.dat(tb)
    for _, e in ipairs((d and d.flatRecipes) or {}) do if e.name == name then return e end end
    return nil
end
function H.showing(tb) local s = false; pcall(function() s = S.WW.isTabShowing(tb, S.pn) end); return s and true or false end
function H.tab(id) if RT.worldTab(id) then return true end; return pcall(S.WW.openTab, S.pn, id) and true or false end
function H.inView(tb, z)
    local st = H.st(tb)
    local g = st and st._listGeo
    return g == nil or z == nil or (z.y >= g.viewY and z.y + z.h <= g.viewY + g.viewH)
end
function H.zone(tb, kind, id)
    local st = H.st(tb)
    for _, z in ipairs((st and st.zones) or {}) do
        if z.type == kind and (id == nil or tostring(z.id) == tostring(id)) and (z.w or 0) > 0 and (z.h or 0) > 0 then
            if (kind ~= "recipeRow" and kind ~= "sectionHeader") or H.inView(tb, z) then return z end
        end
    end
    return nil
end
function H.zones(tb, kind)
    local out = {}
    local st = H.st(tb)
    for _, z in ipairs((st and st.zones) or {}) do if z.type == kind and (z.w or 0) > 0 then out[#out + 1] = z end end
    return out
end
function H.zoneAny(tb, kind) local st = H.st(tb); for _, z in ipairs((st and st.zones) or {}) do if z.type == kind then return z end end; return nil end
function H.slotZone(tb, idx) for _, z in ipairs(H.zones(tb, "slotAlt")) do if z.idx == idx then return z end end; return nil end
function H.itemZone(it) for _, z in ipairs(H.zones("craft", "altItem")) do if z.item == it then return z end end; return nil end
function H.clickXY(tb, x, y, what)
    local ok, err = pcall(S.TB[tb].mod.onClick, RT.ww(), x, y)
    if not ok then S.errs = S.errs + 1; Q.check(false, tostring(what) .. ": the click ran without an error", err) end
    return ok
end
function H.click(tb, z, what) if not z then return false end; return H.clickXY(tb, z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2), what) end
function H.rclick(tb, z, what)
    if not z then return false end
    local ok, err = pcall(S.TB[tb].mod.onRightClick, RT.ww(), z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
    if not ok then S.errs = S.errs + 1; Q.check(false, tostring(what) .. ": the right-click ran without an error", err) end
    return ok
end
function H.press(tb, kind, what) local z = H.zone(tb, kind); if not z then return false end; return H.click(tb, z, what) end
function H.open(tb, name, what)
    local st = H.st(tb)
    if not (st and name) then return false end
    pcall(function() if st.altSlotName then S.CC.exitAltMode(st) end end)
    if st.selected == name then return true end
    local z = H.zone(tb, "recipeRow", name)
    if z then
        H.click(tb, z, what)
    else
        local ok, err = pcall(S.CC.openCraft, st, name)
        if not ok then Q.check(false, tostring(what) .. ": the card opened without an error", err) end
        Q.say("note " .. tostring(what) .. ": " .. tostring(name) .. " has no row in view, its card is opened from code")
    end
    return st.selected == name
end
function H.shut(tb)
    local st = H.st(tb)
    if not st then return end
    pcall(function() if st.altSlotName then S.CC.exitAltMode(st) end end)
    pcall(function() if st.selected then S.CC.closeCraft(st) end end)
end
function H.setSearch(tb, text)
    local w, st = RT.ww(), H.st(tb)
    pcall(function() local f = w[S.TB[tb].search]; f.input:setText(text); f._lastText = text end)
    if st then st.search, st.filterDirty = text, true end
end
function H.slotOf(tb, name, ft)
    local e = H.entry(tb, name)
    for i, d in ipairs((e and e.inputDefs) or {}) do if d.validTypes and d.validTypes[ft] then return i, d end end
    return nil, nil
end
function H.ingName(tb, name, idx) local rd = H.row(tb, name); local g = rd and rd.ingredients and rd.ingredients[idx]; return g and g.name or nil end
-- Craft lit, as the band lights it (cr_tab's)
function H.zedCan(rd) return rd ~= nil and rd.status == "craftable" and rd.learned ~= false and (rd.maxBatchQty or 1) > 0 and rd.canStart ~= false end
function H.rowText(tb, name)
    local rd = H.row(tb, name)
    if not rd then return "no row for " .. tostring(name) end
    return tostring(rd.status) .. ", learned " .. tostring(rd.learned) .. ", skill " .. tostring(rd.hasSkill) .. ", most " .. tostring(rd.maxBatchQty)
end
function H.cardDrawn(tb, name)
    local st = H.st(tb)
    return st ~= nil and st.selected == name and st._cardDrawnAt ~= nil and getTimestampMs() - st._cardDrawnAt < 500
end
-- the card's counts caught up with what was staged after t0 (the Craft tab: its containers and the game's scan, cr_tab's
-- read; the Build tab: 1.6 s on, its card drawn and its row settled, bd_tab's)
function H.fresh(tb, t0, name)
    local w, st, rd = RT.ww(), H.st(tb), H.row(tb, name)
    if not (w and st and rd and st.selected == name and rd.ingredients) then return false end
    if tb == "craft" then return ((w._craftContainerAt or 0) - 1500) >= t0 and (w._craftLogicFullAt or 0) >= t0 end
    return getTimestampMs() - t0 >= 1600 and H.cardDrawn(tb, name) and rd.status ~= "unlocked"
end
-- ZeD's name for a build recipe (the game's name, else the first whose name and words fit: bd_tab's)
function H.rname(key)
    local r = S.BR[key]
    if not r then return nil end
    if r.found ~= nil then return r.found or nil end
    local d = H.dat("build")
    if not (d and d.byName and #(d.recipes or {}) > 0) then return nil end
    if d.byName[r.name] then r.found = r.name; return r.name end
    for nm, rd in pairs(d.byName) do
        local txt = string.lower(tostring(rd.entry and rd.entry.displayName or "") .. " " .. tostring(nm))
        local all = true
        for _, w in ipairs(r.words) do if not string.find(txt, w, 1, true) then all = false end end
        if all and (r.pred == nil or r.pred(rd.entry)) then r.found = nm; return nm end
    end
    r.found = false
    return nil
end
S.BR.crate.pred = function(e) return (e.requiredLevel or 0) > 0 and not e.needLearn end

-- ===================================================================== objects laid round him (cr_tab's and bd_tab's)
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
function H.rmObjRaw(o, sq0)
    if not o then return end
    local sq = sq0
    pcall(function() sq = o:getSquare() or sq0 end)
    if sq then
        pcall(function() sq:transmitRemoveItemFromSquare(o) end)
        pcall(function() if o:getObjectIndex() >= 0 then sq:RemoveTileObject(o) end end)
        pcall(function() sq:getObjects():remove(o) end)
        pcall(function() sq:getSpecialObjects():remove(o) end)
        pcall(function() sq:RecalcProperties() end)
    end
    pcall(function() o:removeFromWorld() end)
    pcall(function() o:removeFromSquare() end)
end
function H.rmObj(c) if c and c.obj then H.rmObjRaw(c.obj, c.sq); c.removed = true end end
function H.objOn(o) local on = false; pcall(function() local sq = o:getSquare(); on = sq ~= nil and sq:getObjects():contains(o) end); return on end
function H.objLeft(c)
    if not (c and c.obj) then return false end
    local left = false
    pcall(function() left = c.sq:getObjects():contains(c.obj) end)
    return left or H.objOn(c.obj)
end
function H.objName(o) local n = "?"; pcall(function() n = o:getSprite():getName() end); return tostring(n) end
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
-- a clear square two away (a build's spot), not one laid on
function H.clearSq()
    for _, d in ipairs(S.RING2) do
        local sq = H.freeSq(d[1], d[2])
        if sq and not H.used(sq) then return sq end
    end
    return nil
end
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
function H.newObjs(before, r)
    local out = {}
    for o in pairs(H.snapObjs(r)) do
        local wi = false
        pcall(function() wi = instanceof(o, "IsoWorldInventoryObject") end)
        if not before[o] and not wi then out[#out + 1] = o end
    end
    return out
end
-- the pottery wheel built where it fits (cr_tab's spawnWheel); every new object kept for the put-back
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
-- new world items round him (anything not there at the start), taken away
function H.snapFloor(set)
    local cx, cy, cz = math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())
    for y = cy - 10, cy + 10 do
        for x = cx - 10, cx + 10 do
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
function H.sweepNew()
    local n = 0
    for _, it in ipairs(H.all()) do if not S.found.inv0[it] then H.removeItem(it); n = n + 1 end end
    return n
end

-- ===================================================================== the build cursor (bd_tab's)
function H.drag() local d = nil; pcall(function() d = getCell():getDrag(S.pn) end); return d end
function H.noDrag() pcall(function() if getCell():getDrag(S.pn) then getCell():setDrag(nil, S.pn) end end) end
function H.dragType(d) if d == nil then return "none" end; return tostring(d.Type) end
function H.isBuildCur(d) return d ~= nil and d.Type == "ISBuildIsoEntity" end
function H.placeAt(cur, sq, label)
    local ok, err = pcall(function()
        cur.square = sq
        cur.isLeftDown = false
        cur.canBeBuild = cur:isValid(sq) and true or false
        cur.build = true
        DoTileBuilding(cur, false, sq:getX(), sq:getY(), sq:getZ(), sq)
    end)
    if not ok then Q.check(false, tostring(label) .. ": the placement (the game's DoTileBuilding) ran without an error", err) end
    return ok
end
-- after a placement: walks at x1, the build action at x20, until the queue is empty; T.new the objects that stand after
function H.runBuild(T, ms)
    H.wait(ms or 45000, function()
        if not T.go then return true end
        local a = H.queue()[1]
        if a and a.Type == "ISBuildAction" then
            if T.lastAct ~= a then T.lastAct = a; T.acts = (T.acts or 0) + 1 end
            if T.inReach == nil and T.watch then T.inReach = T.watch() end
            H.speed(3)
        else
            H.speed(1)
        end
        return H.qlen() == 0
    end, function(ok)
        H.speed(1)
        if not T.go then return end
        T.done = ok
        T.new = H.newObjs(T.before or {}, 10)
        for _, o in ipairs(T.new) do S.built[#S.built + 1] = o end
        if not ok then H.qstop() end
    end)
end

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
function H.stops()
    local w = RT.ww()
    for _, z in ipairs((w and w._focusRing) or {}) do if z.zone == "worldTabContent" then return z.elements or {} end end
    return {}
end
function H.stopById(id) for _, e in ipairs(H.stops()) do if e.id == id then return e end end; return nil end
function H.focusedId() local el = nil; pcall(function() el = S.F.getFocusedElement(RT.ww()) end); return el and el.id or nil end
function H.focusWhere(pred)
    local w = RT.ww()
    if not (w and S.F and S.F.focusWhere) then return nil end
    pcall(S.F.claimFocus, w)
    local e = nil
    pcall(function() e = S.F.focusWhere(w, "worldTabContent", pred) end)
    return e
end
function H.focusEl(id) return H.focusWhere(function(e) return e.id == id end) ~= nil end
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
function H.tapX(gate) H.tap("X", "XButton", gate) end
-- a value given as itself, or as a function asked when the step runs (ids and names a case learns as it runs)
function H.v(x) if type(x) == "function" then return x() end; return x end
-- the stop id comes into the ring (it rebuilds as the tab's shape changes), then the focus goes on it: T[key]
function H.focusOn(T, key, id, ms)
    H.wait(ms or 2500, function() return T.off or H.stopById(H.v(id)) ~= nil end, function()
        if T.off then return end
        T[key] = H.focusEl(H.v(id))
    end)
end

-- ===================================================================== theme, pictures (cr_tab's)
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
    local st = {}
    Q.step(1, function() st.go = (not S.dead) and (gate == nil or gate()); if st.go then H.park(true) end end)
    Q.step(4, function()
        if not st.go then return end
        local file = name .. ".png"
        local ok, e = pcall(function() getCore():TakeFullScreenshot(file) end)
        if ok then S.shots[#S.shots + 1] = file; H.note("picture Zomboid/Screenshots/" .. file .. " | " .. what)
        else H.note("the picture " .. name .. " was not taken: " .. tostring(e)) end
        H.park(false)
    end)
    Q.waitMs(900)
end
-- the look in Dark, Light and High contrast, the theme put back after
function H.themeShots(n, what, desc, gate)
    for _, th in ipairs(S.THEMES) do
        H.step(1, function() if gate == nil or gate() then H.theme(th.key) end end)
        Q.waitMs(600)
        H.shot("cb_calls_" .. n .. "_" .. what .. "_" .. th.tag .. "_" .. H.sizeTag(), th.word .. ": " .. desc, gate)
    end
    H.step(1, function() H.themeBack() end)
    Q.waitMs(300)
end

-- ===================================================================== the draw, watched (on for the run)
-- S.slotSeen[name]: a card's slot row as drawn last (its words and have count); S.rowSeen[name] and S.rowTagC[name]: a
-- recipe row's tag and the tag's colour as drawn last; S.cards[prefix]: the card's drawn words; S.bandSeen: the
-- progress band for the recipe watched (S.bandWant); S.halo: the character's bad-text words
function H.wrapOn()
    if S.w0 then return end
    local W = { slot = ZeD.Molecules.drawSlotRow, rrow = ZeD.Molecules.drawRecipeRow, tag = ZeD.Atoms.drawTag,
                band = ZeD.Atoms.drawProgressBand, card = S.CC.renderCraftCard, halo = HaloTextHelper and HaloTextHelper.addBadText }
    S.w0 = W
    W.slotFn = function(panel, x, y, w, data, ...)
        if type(data) == "table" and data.name ~= nil then
            S.slotSeen[tostring(data.name)] = { disp = data.displayName, have = data.have, need = data.need, t = getTimestampMs() }
        end
        return W.slot(panel, x, y, w, data, ...)
    end
    W.rrowFn = function(panel, x, y, w, data, ...)
        local nm = (type(data) == "table") and data.name or nil
        if nm then S.rowTagC[nm] = nil end
        S.inRow = nm
        local ok, r1, r2 = pcall(W.rrow, panel, x, y, w, data, ...)
        S.inRow = nil
        if nm then S.rowSeen[nm] = { tag = data.tag, danger = data.tagDanger, t = getTimestampMs(), c = S.rowTagC[nm] } end
        if not ok then error(r1, 0) end
        return r1, r2
    end
    W.tagFn = function(panel, x, y, text, color, opts)
        if S.inRow then S.rowTagC[S.inRow] = { text = text, color = color, tc = opts and opts.textColor or nil } end
        return W.tag(panel, x, y, text, color, opts)
    end
    W.bandFn = function(panel, x, y, w, mode, label, percent, ...)
        if S.bandWant and label == S.bandWant then
            S.bandSeen = { label = label, pct = percent, mode = mode, t = getTimestampMs() }
            if #S.bandLog < 4000 then S.bandLog[#S.bandLog + 1] = percent end
        end
        return W.band(panel, x, y, w, mode, label, percent, ...)
    end
    W.cardFn = function(panel, x, y, w, h, state, config, rd, playerObj)
        if not (config and (config.prefix == "craft" or config.prefix == "build")) then return W.card(panel, x, y, w, h, state, config, rd, playerObj) end
        local rec = { name = rd and rd.entry and rd.entry.name or nil, texts = {}, t = getTimestampMs(), x = x, y = y, w = w, h = h }
        local own = rawget(panel, "drawText")
        local bd = panel.drawText
        if bd then
            panel.drawText = function(self, s, tx, ty, r, g, b, a, font)
                rec.texts[#rec.texts + 1] = { s = s, x = tx, y = ty, r = r, g = g, b = b, font = font }
                return bd(self, s, tx, ty, r, g, b, a, font)
            end
        end
        local ok, res = pcall(W.card, panel, x, y, w, h, state, config, rd, playerObj)
        rawset(panel, "drawText", own)
        S.cards[config.prefix] = rec
        if not ok then S.tabErrs = S.tabErrs + 1; S.tabErrLast = res; error(res, 0) end
        return res
    end
    W.haloFn = function(pl, text, ...)
        S.halo[#S.halo + 1] = { text = tostring(text), t = getTimestampMs() }
        return W.halo(pl, text, ...)
    end
    ZeD.Molecules.drawSlotRow, ZeD.Molecules.drawRecipeRow = W.slotFn, W.rrowFn
    ZeD.Atoms.drawTag, ZeD.Atoms.drawProgressBand = W.tagFn, W.bandFn
    S.CC.renderCraftCard = W.cardFn
    if W.halo then HaloTextHelper.addBadText = W.haloFn end
end
function H.wrapOff()
    local W = S.w0
    if not W then return end
    if ZeD.Molecules.drawSlotRow == W.slotFn then ZeD.Molecules.drawSlotRow = W.slot end
    if ZeD.Molecules.drawRecipeRow == W.rrowFn then ZeD.Molecules.drawRecipeRow = W.rrow end
    if ZeD.Atoms.drawTag == W.tagFn then ZeD.Atoms.drawTag = W.tag end
    if ZeD.Atoms.drawProgressBand == W.bandFn then ZeD.Atoms.drawProgressBand = W.band end
    if S.CC.renderCraftCard == W.cardFn then S.CC.renderCraftCard = W.card end
    if W.halo and HaloTextHelper.addBadText == W.haloFn then HaloTextHelper.addBadText = W.halo end
    S.w0 = nil
end
function H.fresh2(rec) return rec ~= nil and getTimestampMs() - (rec.t or 0) < 700 end
-- the character said the game's words for chosen inputs that no longer cover the recipe
function H.saidInputs()
    local want = getText("IGUI_CraftingWindow_Error_Inputs")
    for _, h in ipairs(S.halo) do if h.text == want then return true, want end end
    local o = {}
    for _, h in ipairs(S.halo) do o[#o + 1] = h.text end
    return false, want, H.list(o)
end

-- ===================================================================== a case's start and end
function H.caseStart(label)
    H.step(2, function()
        S.caseMade = {}
        S.caseObjs = #S.objs
        S.caseBuilt = #S.built
        S.te0 = S.tabErrs
        S.halo = {}
        S.bandWant, S.bandSeen, S.bandLog = nil, nil, {}
        for _, tb in ipairs({ "craft", "build" }) do
            local st = H.st(tb)
            if st then
                H.shut(tb)
                H.setSearch(tb, "")
                pcall(S.CC.setShow, st, "all")
                st.activeCat, st.picks, st.itemPicks, st.qty, st.filterDirty = "all", {}, {}, 1, true
                -- (the card's Required rows unfolded and the list's Owned and Other both shown: the slot rows, the
                -- notes and the alternatives draw; the found folds are put back at the end)
                st.reqCollapsed, st.ownedOnly = false, false
            end
        end
        Q.say("case " .. label)
    end)
end
-- everything the case made, gave, laid or built taken away; returns the names of what was left before the sweep
function H.caseClean()
    H.speed(1)
    H.qstop()
    H.noDrag()
    H.padOff()
    H.park(false)
    pcall(function() if S.orig.walk then ISEntityUI.WalkToEntity = S.orig.walk end end)
    pcall(function() S.ST.unbind(S.p) end)
    for _, tb in ipairs({ "craft", "build" }) do
        local st = H.st(tb)
        H.shut(tb)
        if st then
            H.setSearch(tb, "")
            st.catDropdownOpen, st.sortMenuOpen, st.showMenuOpen, st.stDropdownOpen = false, false, false, false
            st.activeCat, st.qty, st.picks, st.itemPicks = "all", 1, {}, {}
            st.filterDirty = true
        end
    end
    pcall(function() local w = RT.ww(); if w then w._craftQueued, w._craftQueuedRecipe = nil, nil end end)
    for _, it in ipairs(S.caseMade) do H.removeItem(it) end
    for i = (S.caseObjs or 0) + 1, #S.objs do H.rmObj(S.objs[i]) end
    for i = (S.caseBuilt or 0) + 1, #S.built do H.rmObjRaw(S.built[i]) end
    H.home()
    local swept = H.sweepNew()
    local floor = H.sweepFloor()
    -- (anything built round him that the case did not track: named, then taken away)
    local stray = {}
    for _, o in ipairs(H.newObjs(S.found.objs0 or {}, 10)) do
        local mine = false
        for _, c in ipairs(S.objs) do if c.obj == o and not c.removed then mine = true end end
        if not mine then stray[#stray + 1] = H.objName(o); H.rmObjRaw(o) end
    end
    H.lootRefresh()
    return swept, floor, stray
end
function H.caseEnd(label)
    H.step(2, function()
        local made, objs, built = S.caseMade, {}, {}
        for i = (S.caseObjs or 0) + 1, #S.objs do objs[#objs + 1] = S.objs[i] end
        for i = (S.caseBuilt or 0) + 1, #S.built do built[#built + 1] = S.built[i] end
        local swept, floor, stray = H.caseClean()
        local left = {}
        for _, it in ipairs(made) do if not H.gone(it) then left[#left + 1] = H.ft(it) end end
        for _, c in ipairs(objs) do if H.objLeft(c) then left[#left + 1] = c.what end end
        for _, o in ipairs(built) do if H.objOn(o) then left[#left + 1] = "built " .. H.objName(o) end end
        for _, s in ipairs(stray) do left[#left + 1] = "untracked " .. s end
        local extra = {}
        for _, it in ipairs(H.all()) do if not S.found.inv0[it] then extra[#extra + 1] = H.ft(it) end end
        for _, s in ipairs(extra) do left[#left + 1] = "carried " .. s end
        Q.check(#left == 0, label .. ": everything the case gave, crafted, laid or built is gone after it",
            #made .. " given, " .. #objs .. " laid, " .. #built .. " built; " .. swept .. " crafted things swept from him, " .. floor
            .. " off the floor; left: " .. H.list(left))
        S.caseMade = {}
    end)
    H.step(10, function()
        local e1 = H.errN()
        local te = S.tabErrs - (S.te0 or 0)
        Q.check((S.e0 == nil or e1 == nil or e1 == S.e0) and te == 0, label .. ": no Lua error over the case",
            ((S.e0 and e1) and ((e1 - S.e0) .. " new") or "the count cannot be read") .. ", the card's own " .. te
            .. (te > 0 and (" (" .. tostring(S.tabErrLast) .. ")") or ""))
        S.e0 = e1
    end)
end
-- queue: the tab showing its recipe rows (T.off when it does not)
function H.toTab(tb, T, label)
    H.step(2, function() if not RT.isOpen() then RT.pairOpen() end end)
    H.step(6, function() H.tab(tb) end)
    H.wait(6000, function() return H.showing(tb) and H.st(tb) ~= nil and H.zoneAny(tb, "recipeRow") ~= nil end, function(ok)
        if not Q.check(ok, label .. ": the " .. tb .. " tab shows its recipe rows (staging)", "showing " .. tostring(H.showing(tb))) then T.off = true end
    end)
end
-- queue: a recipe's card opened once its things are staged (stage(T) gives them; T.skip says why it cannot), then the
-- card caught up (at most 9 s): T.ready. name: the recipe, or a function giving it when the step runs
function H.stageOpen(tb, T, name, label, stage)
    H.step(2, function()
        T.ready = nil
        if T.off then return end
        if stage then
            local ok, err = pcall(stage, T)
            if not ok then T.skip = "the staging threw: " .. tostring(err) end
        end
        if T.skip then Q.skip(label, T.skip); T.off = true; return end
        H.lootRefresh()
        T.go = H.open(tb, H.v(name), label)
        T.t0 = getTimestampMs()
        if not T.go then Q.check(false, label .. ": its card opens", "the card: " .. tostring(H.st(tb) and H.st(tb).selected)); T.off = true end
    end)
    H.wait(9000, function() return T.off or H.fresh(tb, T.t0, H.v(name)) end, function(ok)
        if T.off then return end
        T.ready = ok
        if not ok then H.note(label .. ": the card's counts did not catch up in 9 s (read as they stand)") end
    end)
end

-- ===================================================================== setup
function S.setup()
    Q.step(1, function()
        local f = S.found
        S.dead = S.p:isDead() and true or false
        if S.dead then Q.check(false, "setup: the character is alive (nothing is run on a dead one)"); return end
        if not (S.F.focusWhere and ISEntityUI and HandcraftLogic and BuildLogic and ISTimedActionQueue and CraftRecipeManager) then
            S.dead = true
            Q.check(false, "setup: the pad's focus manager and the game's crafting and build logic are loaded")
            return
        end
        S.err0 = H.errN()
        S.e0 = S.err0
        if ZEDQA_HOME then pcall(ZEDQA_HOME, "cb_calls") end
        H.speed(1)
        H.qstop()
        H.noDrag()
        f.pos = { x = S.p:getX(), y = S.p:getY(), z = S.p:getZ() }
        pcall(function() f.dir = S.p:getDir() end)
        f.pair = RT.isOpen()
        f.hands = { p = S.p:getPrimaryHandItem(), s = S.p:getSecondaryHandItem() }
        pcall(function() S.p:setPrimaryHandItem(nil); S.p:setSecondaryHandItem(nil) end)
        f.inv0, f.types, f.stashed, f.floor0 = {}, {}, {}, {}
        for _, it in ipairs(H.all()) do
            f.inv0[it] = true
            local ft = H.ft(it)
            f.types[ft] = (f.types[ft] or 0) + 1
        end
        H.snapFloor(f.floor0)
        f.objs0 = H.snapObjs(10)
        pcall(function() f.tod = getGameTime():getTimeOfDay() end)
        f.stats = {}
        pcall(function()
            local stt = S.p:getStats()
            for _, k in ipairs(S.STATS) do pcall(function() f.stats[k] = stt:get(CharacterStat[k]) end) end
        end)
        pcall(function() f.inst = S.p:isTimedActionInstantCheat(); S.p:setTimedActionInstantCheat(false) end)
        pcall(function() f.bc = S.p:isBuildCheat(); S.p:setBuildCheat(false) end)
        pcall(function() f.bm = ISBuildMenu.cheat; ISBuildMenu.cheat = false end)
        pcall(function() if not S.p:isGodMod() then S.p:setGodMod(true); H.note("god mode was off: turned on and left on") end end)
        pcall(function() f.invinc = S.p:isInvincible() and true or false; S.p:setInvincible(true) end)
        H.xpSnap()
        local md = S.p:getModData()
        f.mdKeys = {}
        for _, key in ipairs({ "ZeD_CraftPins", "ZeD_CraftCounts", "ZeD_BuildPins", "ZeD_BuildCounts" }) do
            local copy = nil
            if md[key] then copy = {}; for k, v in pairs(md[key]) do copy[k] = v end end
            f.mdKeys[key] = { v = copy }
        end
        f.base, f.baseIdx = ZeD.currentBase, H.optVal(H.zopt("baseTheme"))
        S.lockWas = H.lockFound()
        pcall(function()
            local cur = S.ST.current(S.p)
            if cur then f.st = cur; S.ST.unbind(S.p); H.note("a station was bound: unbound for the run, bound again at the end") end
        end)
        RT.pairOpen()
        if ZEDQA_LAYOUT_SNAP then pcall(function() f.layout = ZEDQA_LAYOUT_SNAP() end) end
        H.wrapOn()
        f.recorded = true
        S.back.on = true
        Q.say("found: at " .. math.floor(f.pos.x) .. "," .. math.floor(f.pos.y) .. ", theme " .. tostring(f.base) .. ", input lock "
            .. tostring(S.lockWas) .. ", screen " .. H.sizeTag() .. ", instant " .. tostring(f.inst) .. ", build cheat " .. tostring(f.bc)
            .. "/" .. tostring(f.bm) .. ", Carpentry " .. tostring(H.level("Woodwork")))
    end)
    H.step(15, function() local w = RT.ww(); S.found.tab = w and w._activeTab; H.tab("craft") end)
    H.wait(8000, function() return H.showing("craft") and H.st("craft") ~= nil and H.zoneAny("craft", "recipeRow") ~= nil end, function(ok)
        if not Q.check(ok, "setup: the World window's Crafting tab opens with recipe rows", "showing " .. tostring(H.showing("craft"))) then S.dead = true; return end
        local st = H.st("craft")
        S.found.ckeep = H.keepState(st)
        H.shut("craft")
        H.setSearch("craft", "")
        pcall(S.CC.setShow, st, "all")
        st.activeCat, st.filterDirty = "all", true
        -- his own inputs of the recipes crafted here, and his building things, set aside
        local set = {}
        for _, ft in ipairs(S.OWN) do set[ft] = true end
        for _, nm in ipairs({ S.R.stake, S.R.drill, S.R.cup }) do
            local e = H.entry("craft", nm)
            if not e then H.note("setup: the catalog has no " .. nm) end
            for _, d in ipairs((e and e.inputDefs) or {}) do for ft in pairs(d.validTypes or {}) do set[ft] = true end end
        end
        local aside, kept = H.stashTypes(set)
        H.note("setup: " .. aside .. " of his own things the recipes take are set aside" .. (kept > 0 and (", " .. kept .. " worn or on the belt stay") or ""))
        Q.check(S.stakeKnife ~= nil and S.stakeBranch ~= nil, "setup: a knife and a tree branch are items this game knows", tostring(S.stakeKnife) .. ", " .. tostring(S.stakeBranch))
    end)
    H.step(10, function() H.tab("build") end)
    H.wait(10000, function() local d = H.dat("build"); return H.showing("build") and H.st("build") ~= nil and d ~= nil and #(d.recipes or {}) > 0 end, function(ok)
        if not Q.check(ok, "setup: the World window's Building tab opens with its rows", "showing " .. tostring(H.showing("build"))) then S.dead = true; return end
        local st = H.st("build")
        S.found.bstate = st
        S.found.bkeep = H.keepState(st)
        H.shut("build")
        H.setSearch("build", "")
        pcall(S.CC.setShow, st, "all")
        st.activeCat, st.filterDirty = "all", true
        Q.say("setup: build recipes cross " .. tostring(H.rname("cross")) .. ", crate " .. tostring(H.rname("crate")) .. "; "
            .. #(H.dat("build").recipes or {}) .. " build rows")
    end)
end
function H.keepState(st)
    local pk = {}
    for k, v in pairs(st.picks or {}) do pk[k] = v end
    return { show = st.show, showAll = st.showAll, sort = st.sort, cat = st.activeCat, search = st.search or "", sel = st.selected,
        picks = pk, qty = st.qty, req = st.reqCollapsed, out = st.outCollapsed, owned = st.ownedOnly }
end
function H.putState(tb, st, k)
    if not (st and k) then return end
    H.shut(tb)
    st.show, st.showAll, st.sort, st.activeCat = k.show, k.showAll, k.sort, k.cat
    st.reqCollapsed, st.outCollapsed, st.ownedOnly = k.req, k.out, k.owned
    st.sortMenuOpen, st.showMenuOpen, st.catDropdownOpen, st.stDropdownOpen = false, false, false, false
    st.itemPicks = {}
    H.setSearch(tb, k.search or "")
    if k.sel then pcall(S.CC.openCraft, st, k.sel); st.picks = k.picks or {}; st.qty = k.qty or 1 else st.picks = k.picks or {} end
    st.filterDirty = true
end

-- ===================================================================== 1. exact items (call 1)
function C.c1()
    local T = { name = S.R.stake }
    local L = "1 items"
    H.caseStart(L)
    H.toTab("craft", T, L)
    H.stageOpen("craft", T, S.R.stake, L, function(T2)
        T2.k = H.give(S.stakeKnife)
        T2.b1 = H.give(S.stakeBranch)
        T2.b2 = H.give(S.stakeBranch)
        local stick = H.kind("stick")
        T2.s = stick and H.give(stick) or nil
        if not (T2.k and T2.b1 and T2.b2) then T2.skip = "a knife and two tree branches could not be given"; return end
        T2.kHalf = H.halfCond(T2.k)
        T2.bHalf = H.halfCond(T2.b2)
        T2.stickT = stick
    end)
    H.step(2, function()
        if T.off then return end
        T.idx = H.slotOf("craft", S.R.stake, S.stakeBranch)
        T.ing = H.ingName("craft", S.R.stake, T.idx)
        local set = H.gameUses(S.R.stake)
        T.game = (set[T.b1] and "the first branch") or (set[T.b2] and "the second branch") or ((T.s and set[T.s]) and "the stick") or "none read"
        -- (the branch the game's own logic would not take is the one chosen)
        T.target = set[T.b1] and T.b2 or T.b1
        T.other = (T.target == T.b1) and T.b2 or T.b1
        T.gMost = H.gameMost(S.R.stake, false)
        H.note(L .. ": the game's own logic takes " .. T.game .. "; the knife " .. H.cond(T.k) .. " (worn to half " .. tostring(T.kHalf)
            .. "), the branches " .. H.cond(T.b1) .. " and " .. H.cond(T.b2) .. " (a branch worn to half " .. tostring(T.bHalf)
            .. "); the game's Max with nothing chosen " .. tostring(T.gMost))
        local z = T.idx and H.slotZone("craft", T.idx)
        if not z then Q.check(false, L .. ": Make Stake's branch slot opens an alternatives list", "slot " .. tostring(T.idx)); T.off = true; return end
        H.click("craft", z, L .. ", the branch slot")
    end)
    H.step(3, function()
        if T.off then return end
        local st = H.st("craft")
        local z = H.zone("craft", "altPick", S.stakeBranch)
        if not (st.altSlotName and z) then Q.check(false, L .. ": the branch slot's list shows the tree branch type", "open " .. tostring(st.altSlotName)); T.off = true; return end
        H.click("craft", z, L .. ", the tree branch type")
    end)
    H.step(4, function()
        if T.off then return end
        local rows = H.zones("craft", "altItem")
        local seen, bad = {}, {}
        for _, z in ipairs(rows) do
            seen[z.item] = true
            local want, got = H.detailWant(z.item), S.CC.itemDetail(z.item)
            if want ~= got then bad[#bad + 1] = H.nm(z.item) .. " ZeD \"" .. tostring(got) .. "\", the game's \"" .. want .. "\"" end
        end
        Q.check(#rows == 2 and seen[T.b1] and seen[T.b2], L .. ": the chosen type opens one row per tree branch in reach (CC.drawAltItemRow)",
            #rows .. " item rows; the first branch " .. tostring(seen[T.b1] == true) .. ", the second " .. tostring(seen[T.b2] == true))
        Q.check(#bad == 0 and #rows > 0, L .. ": each item row's uses or condition is the game's own (getCondition / getConditionMax)",
            "rows " .. #rows .. "; " .. H.list(bad) .. "; the worn branch reads \"" .. S.CC.itemDetail(T.b2) .. "\"")
        local zt = H.itemZone(T.target)
        if zt then H.click("craft", zt, L .. ", the chosen branch's row") else Q.check(false, L .. ": the branch to choose has a row", "none") end
    end)
    H.step(3, function()
        if T.off then return end
        local st = H.st("craft")
        local l = S.CC.itemPicksFor(st, S.R.stake, T.idx)
        Q.check(l ~= nil and #l == 1 and l[1] == T.target and S.CC.pickFor(st, S.R.stake, T.idx) == S.stakeBranch,
            L .. ": a click on an item row chooses that very branch (state.itemPicks)", tostring(l and #l) .. " chosen, the type " .. tostring(S.CC.pickFor(st, S.R.stake, T.idx)))
        -- a drainable's row: IsDrainable / getCurrentUsesFloat run in the game (Build's unproven read)
        local d = H.give(H.kind("drain"))
        if d then
            H.call(d, "setCurrentUsesFloat", 0.4)
            local isD = H.call(d, "IsDrainable")
            local want, got = H.detailWant(d), S.CC.itemDetail(d)
            if isD == true then
                Q.check(got ~= "" and got == want, L .. ": a drainable's row reads its uses left (IsDrainable and getCurrentUsesFloat run in the game)",
                    H.ft(d) .. ": ZeD \"" .. got .. "\", the game's uses " .. H.n2(H.call(d, "getCurrentUsesFloat")) .. " (\"" .. want .. "\")")
            else
                Q.skip(L .. ": a drainable's row", H.ft(d) .. " does not read as drainable here")
            end
            H.removeItem(d)
        else
            Q.skip(L .. ": a drainable's row", "no drainable item is known here")
        end
    end)
    H.themeShots(1, "itemrows", "Make Stake's branch slot list: the tree branch type chosen, its two branches as rows, the chosen one marked, condition at the right",
        function() return not T.off end)
    -- both chosen: the slot counts 2 and Max follows; one again: 1
    H.step(2, function() if not T.off then H.click("craft", H.itemZone(T.other), L .. ", the other branch's row") end end)
    H.wait(5000, function() local rd = H.row("craft", S.R.stake); return T.off or (rd and rd.maxBatchQty == 2) end, function(ok)
        if T.off then return end
        local st, rd = H.st("craft"), H.row("craft", S.R.stake)
        local l = S.CC.itemPicksFor(st, S.R.stake, T.idx)
        local sr = S.slotSeen[tostring(T.ing)]
        T.two = { most = rd.maxBatchQty, n = l and #l, have = sr and sr.have }
        H.click("craft", H.itemZone(T.other), L .. ", the other branch again")
    end)
    H.wait(5000, function() local rd = H.row("craft", S.R.stake); return T.off or (rd and rd.maxBatchQty == 1) end, function(ok)
        if T.off then return end
        local st, rd = H.st("craft"), H.row("craft", S.R.stake)
        local l = S.CC.itemPicksFor(st, S.R.stake, T.idx)
        local sr = S.slotSeen[tostring(T.ing)]
        local want = tostring(T.ing) .. ": " .. H.nm(T.target)
        Q.check(T.two.n == 2 and T.two.most == 2 and ok and rd.maxBatchQty == 1 and l and #l == 1,
            L .. ": Max follows the chosen items (CC.pickSig): 2 with both chosen, 1 with one", "both: " .. tostring(T.two.n) .. " chosen, most "
            .. tostring(T.two.most) .. "; one: most " .. tostring(rd.maxBatchQty) .. " (the game's own Max with nothing chosen " .. tostring(T.gMost) .. ")")
        Q.check(H.fresh2(sr) and sr.disp == want and sr.have == 1 and T.two.have == 2,
            L .. ": the slot row names the first chosen item and counts the chosen ones", "drawn \"" .. tostring(sr and sr.disp) .. "\" have "
            .. tostring(sr and sr.have) .. " (with both: " .. tostring(T.two.have) .. "); wanted \"" .. want .. "\" 1")
    end)
    -- one type: the stick's type chosen clears the branches; a stick chosen; the branch type again, the target again
    H.step(2, function()
        if T.off then return end
        T.st0 = T.stickT and T.s and H.zone("craft", "altPick", T.stickT)
        if T.st0 then H.click("craft", T.st0, L .. ", the stick type") else Q.skip(L .. ": all chosen items one type", "no wooden stick type in the list") end
    end)
    H.step(3, function()
        if T.off or not T.st0 then return end
        local st = H.st("craft")
        T.afterType = S.CC.itemPicksFor(st, S.R.stake, T.idx)
        local zs = H.itemZone(T.s)
        if zs then H.click("craft", zs, L .. ", the stick's row") end
    end)
    H.step(3, function()
        if T.off or not T.st0 then return end
        local st = H.st("craft")
        local l = S.CC.itemPicksFor(st, S.R.stake, T.idx) or {}
        local mixed = false
        for _, it in ipairs(l) do if H.ft(it) ~= T.stickT then mixed = true end end
        Q.check(T.afterType == nil and #l == 1 and l[1] == T.s and not mixed, L .. ": all chosen items of a slot are one type (another type chosen clears the branches)",
            "after the stick type: " .. tostring(T.afterType and #T.afterType) .. " chosen; after the stick's row: " .. #l .. " chosen, mixed " .. tostring(mixed))
        H.click("craft", H.zone("craft", "altPick", S.stakeBranch), L .. ", the branch type again")
    end)
    H.step(3, function() if not T.off and T.st0 then H.click("craft", H.itemZone(T.target), L .. ", the chosen branch again") end end)
    H.step(3, function()
        if T.off then return end
        local st = H.st("craft")
        local l = S.CC.itemPicksFor(st, S.R.stake, T.idx)
        if not (l and #l == 1 and l[1] == T.target) then Q.check(false, L .. ": the chosen branch chosen again", tostring(l and #l)); T.off = true; return end
        if not H.press("craft", "altStrip_back", L .. ", Back") then pcall(S.CC.exitAltMode, st) end
    end)
    -- Craft: the chosen branch is used, the other branch and the stick are not
    H.step(4, function()
        if T.off then return end
        T.W = H.watchNew(S.OUT.stake)
        T.pressed = H.press("craft", "action_build", L .. ", Craft")
        if not T.pressed then Q.check(false, L .. ": Craft is drawn", H.rowText("craft", S.R.stake)); T.off = true end
    end)
    H.wait(40000, function() return T.off or H.watchTick(T.W) end, function(ok)
        H.speed(1)
        if T.off then return end
        local made = H.count(S.OUT.stake) - T.W.c0
        Q.check(made == 1 and H.gone(T.target) and not H.gone(T.other) and (T.s == nil or not H.gone(T.s)) and not H.gone(T.k),
            L .. " (call 1): the craft uses the very branch chosen, not the other branch the game's own logic would take",
            "made " .. made .. "; the chosen " .. (H.gone(T.target) and "used" or "still there") .. ", the other " .. (H.gone(T.other) and "USED" or "kept")
            .. ", the stick " .. (T.s and (H.gone(T.s) and "USED" or "kept") or "none") .. "; the game took " .. T.game)
        if not ok then H.qstop() end
        T.t1 = getTimestampMs()
    end)
    -- the slot row after the craft: the chosen branch is used up
    H.wait(4000, function() local sr = S.slotSeen[tostring(T.ing)]; return T.off or (sr ~= nil and sr.t > (T.t1 or 0) + 1500) end, function()
        if T.off then return end
        local st = H.st("craft")
        local l = S.CC.itemPicksFor(st, S.R.stake, T.idx) or {}
        local reach = 0
        for _, it in ipairs(l) do if H.where(it) ~= nil then reach = reach + 1 end end
        local sr = S.slotSeen[tostring(T.ing)]
        Q.check(sr ~= nil and sr.have == reach, L .. ": after the craft the slot row no longer counts the chosen branch it used up",
            "chosen " .. #l .. " (in reach " .. reach .. "); the row reads \"" .. tostring(sr and sr.disp) .. "\" have " .. tostring(sr and sr.have)
            .. "/" .. tostring(sr and sr.need) .. "; Craft " .. (H.zedCan(H.row("craft", S.R.stake)) and "lit" or "gray")
            .. " (CraftingCore.lua:3936-3944 counts #itemPicks with no reach check)")
    end)
    -- by the pad: the type row cleared and chosen again, a new branch chosen by A on its row, B leaves the list
    H.step(2, function()
        if T.off then return end
        T.b3 = H.give(S.stakeBranch)
        H.lootRefresh()
        H.padOn()
    end)
    H.focusOn(T, "fSlot", function() return "craft:slotAlt:" .. tostring(T.ing) end)
    H.tapA(function() return T.fSlot end)
    H.focusOn(T, "fType", "craft:altPick:" .. tostring(S.stakeBranch))
    H.tapA(function() return T.fType end)
    H.step(4, function()
        if T.off then return end
        local st = H.st("craft")
        T.cleared = st.altSlotName ~= nil and S.CC.pickFor(st, S.R.stake, T.idx) == nil and S.CC.itemPicksFor(st, S.R.stake, T.idx) == nil
    end)
    H.focusOn(T, "fType2", "craft:altPick:" .. tostring(S.stakeBranch))
    H.tapA(function() return T.fType2 end)
    H.step(4, function() T.b3id = "craft:altItem:" .. H.id(T.b3) end)
    H.wait(2500, function() return T.off or H.stopById(T.b3id) ~= nil end, function() if not T.off then T.fItem = H.focusEl(T.b3id) end end)
    H.tapA(function() return T.fItem end)
    H.step(4, function()
        if T.off then return end
        local st = H.st("craft")
        local l = S.CC.itemPicksFor(st, S.R.stake, T.idx)
        Q.check(T.fSlot and T.cleared and T.fItem and l ~= nil and #l == 1 and l[1] == T.b3,
            L .. ", pad: A on the type row clears the choice, A again chooses the type, A on craft:altItem:<id> chooses that branch",
            "focus slot " .. tostring(T.fSlot) .. ", cleared " .. tostring(T.cleared) .. ", the item stop " .. tostring(T.fItem) .. "; chosen " .. tostring(l and #l)
            .. ", on " .. tostring(H.focusedId()))
    end)
    H.tapB(function() return not T.off and H.st("craft").altSlotName ~= nil end)
    H.step(4, function()
        if T.off then return end
        local st = H.st("craft")
        Q.check(st.altSlotName == nil and st.selected == S.R.stake, L .. ", pad: B leaves the alternatives list, the card stays", tostring(st.altSlotName) .. ", card " .. tostring(st.selected))
        -- the chosen branch carried off out of reach (dropped 9 squares away), the other branch still carried
        H.removeItem(T.b3)
        local far = H.sqAt(9, 0) or H.sqAt(0, 9)
        if far then pcall(function() far:AddWorldInventoryItem(T.b3, 0.5, 0.5, 0) end) end
        H.lootRefresh()
        S.halo = {}
        T.q0 = H.qcount("ISHandcraftAction")
    end)
    H.focusOn(T, "fCraft", "craft:actBuild")
    H.tapA(function() return T.fCraft end)
    H.step(8, function()
        if T.off then return end
        local said, want, heard = H.saidInputs()
        Q.check(T.fCraft and H.qcount("ISHandcraftAction") == T.q0 and H.carried(T.other),
            L .. ", pad: A on Craft with the chosen branch out of reach is refused (nothing queued, the other branch carried is not used)",
            "focus " .. tostring(T.fCraft) .. "; queue " .. H.qkinds() .. "; the other branch " .. (H.carried(T.other) and "carried" or "gone")
            .. "; the chosen branch " .. (H.onFloor(T.b3) and "on the floor 9 squares off" or "out of the world"))
        Q.check(said, L .. ": the refusal is in the game's words (IGUI_CraftingWindow_Error_Inputs)", "wanted \"" .. tostring(want) .. "\"; said " .. tostring(heard))
        H.padOff()
    end)
    H.caseEnd(L)
end

-- ===================================================================== 2. the progress band (call 2)
function C.c2stake(T, L, n)
    H.stageOpen("craft", T, S.R.stake, L, function(T2)
        T2.k = H.give(S.stakeKnife)
        T2.bs = H.giveN(S.stakeBranch, n)
        if not (T2.k and #T2.bs == n) then T2.skip = "a knife and " .. n .. " branches could not be given" end
    end)
    H.wait(8000, function() local rd = H.row("craft", S.R.stake); return T.off or (rd and H.zedCan(rd) and (rd.maxBatchQty or 1) >= 3) end, function(ok)
        if T.off then return end
        if not ok then Q.skip(L, "Make Stake never read ready for a batch (" .. H.rowText("craft", S.R.stake) .. ")"); T.off = true; return end
        local e = H.entry("craft", S.R.stake)
        S.bandWant = e and e.displayName or S.R.stake
        S.bandSeen, S.bandLog = nil, {}
        T.c0 = H.count(S.OUT.stake)
    end)
end
function C.c2mouse()
    local T = {}
    local L = "2 band, mouse"
    C.c2stake(T, L, 3)
    H.step(2, function()
        if T.off then return end
        local st = H.st("craft")
        H.press("craft", "action_max", L .. ", Max")
        T.qty = st.qty
        H.press("craft", "action_build", L .. ", Craft")
        T.q = H.qcount("ISHandcraftAction")
        T.p1 = {}
    end)
    -- the band on and rising in the first craft; X once the second craft is a quarter done
    H.wait(150000, function()
        if T.off then return true end
        local st, w = H.st("craft"), RT.ww()
        local a = H.queue()[1]
        local isCraft = a ~= nil and a.Type == "ISHandcraftAction"
        H.speed(isCraft and 2 or 1)
        local made = H.count(S.OUT.stake) - T.c0
        if st._progOn then T.on = (T.on or 0) + 1 end
        local bs = S.bandSeen
        if isCraft and H.fresh2(bs) then
            local d = H.delta(a)
            if type(d) == "number" and type(bs.pct) == "number" then
                T.gap = math.max(T.gap or 0, math.abs(d - bs.pct))
                if made == 0 then T.lo = math.min(T.lo or 1, bs.pct); T.hi = math.max(T.hi or 0, bs.pct) end
            end
        end
        if not T.xAt and isCraft and made >= 1 then
            local d = H.delta(a)
            local z = H.zone("craft", "craftCancel")
            if type(d) == "number" and d >= 0.25 and z then
                T.xAt, T.madeAt, T.qAt, T.pctAt, T.zoneOk = getTimestampMs(), made, H.qcount("ISHandcraftAction"), d, true
                H.click("craft", z, L .. ", X")
            end
        end
        return T.xAt ~= nil or H.qlen() == 0
    end, function(ok)
        H.speed(1)
        if T.off then return end
        Q.check((T.on or 0) > 0 and T.lo ~= nil, L .. " (call 2): the accent band draws over the card while the recipe's craft runs, named for it",
            "seen on " .. tostring(T.on) .. " frames; the band's word \"" .. tostring(S.bandWant) .. "\", mode " .. tostring(S.bandSeen and S.bandSeen.mode))
        Q.check(T.lo ~= nil and T.hi - T.lo >= 0.3 and (T.gap or 1) <= 0.1, L .. ": the band's share is the running craft's own (getJobDelta) and rises",
            "first craft " .. H.n2(T.lo) .. " to " .. H.n2(T.hi) .. "; the most it was off the game's job delta " .. H.n2(T.gap))
        if not T.xAt then Q.skip(L .. ": X in the second craft", "the batch ended before X could be pressed (" .. H.qkinds() .. ")"); T.off = true end
    end)
    Q.waitMs(2500)
    H.step(2, function()
        if T.off then return end
        local st, w, rd = H.st("craft"), RT.ww(), H.row("craft", S.R.stake)
        local made = H.count(S.OUT.stake) - T.c0
        local left = 0
        for _, b in ipairs(T.bs or {}) do if not H.gone(b) then left = left + 1 end end
        Q.check(H.qcount("ISHandcraftAction") == 0 and H.qlen() == 0, L .. " (call 2): X stops the running craft and the game drops the queue behind it, the batch's rest included",
            "batch " .. tostring(T.qty) .. " (queued " .. tostring(T.q) .. "); at X " .. tostring(T.qAt) .. " crafts queued, the running one " .. H.n2(T.pctAt)
            .. " done; after: " .. H.qkinds())
        Q.check(made == T.madeAt and left == (#(T.bs or {}) - made), L .. ": nothing more is made after X, and the branches not used are kept",
            "made " .. made .. " (at X " .. tostring(T.madeAt) .. "), branches left " .. left .. " of " .. #(T.bs or {}))
        Q.check(not st._progOn and w._craftQueued == nil and H.zone("craft", "craftCancel") == nil and rd and not rd.busy,
            L .. ": the band goes and Craft is lit again", "band " .. tostring(st._progOn) .. ", queued list " .. tostring(w._craftQueued) .. ", busy " .. tostring(rd and rd.busy))
    end)
    H.step(2, function() H.shut("craft"); for _, it in ipairs(S.caseMade) do H.removeItem(it) end; H.sweepNew() end)
end
function C.c2pad()
    local T = {}
    local L = "2 band, pad"
    C.c2stake(T, L, 6)
    H.step(2, function() if not T.off then H.padOn() end end)
    H.focusOn(T, "fMax", "craft:actMax")
    H.tapA(function() return T.fMax end)
    H.step(4, function()
        if T.off or T.fMax then return end
        -- (a band short of room has the one amount box and no Max: the most set from code, said)
        local rd = H.row("craft", S.R.stake)
        H.st("craft").qty = (rd and rd.maxBatchQty) or 6
        H.note(L .. ": no Max stop on the band (" .. tostring(H.stopById("craft:actQty") ~= nil and "the one amount box" or "none") .. "): the amount set from code")
    end)
    H.focusOn(T, "fCraft", "craft:actBuild")
    H.step(1, function() if not T.off then T.qty = H.st("craft").qty end end)
    H.tapA(function() return T.fCraft end)
    H.wait(20000, function()
        if T.off then return true end
        local a = H.queue()[1]
        local d = (a and a.Type == "ISHandcraftAction") and H.delta(a) or nil
        H.speed(1)
        return H.st("craft")._progOn and type(d) == "number" and d > 0.05
    end, function(ok)
        if T.off then return end
        T.run = ok
        if not ok then Q.check(false, L .. ": A on Craft starts the batch and the band shows", "the amount " .. tostring(T.qty) .. "; queue " .. H.qkinds()); T.off = true end
    end)
    H.themeShots(2, "band", "the progress band over Make Stake's card while a batch of " .. "6 runs (its X is Cancel)", function() return not T.off and T.run and H.st("craft")._progOn end)
    H.focusOn(T, "fX", "craft:craftCancel")
    H.step(1, function() if not T.off then T.qAt = H.qcount("ISHandcraftAction"); T.madeAt = H.count(S.OUT.stake) - (T.c0 or 0) end end)
    H.tapA(function() return T.fX end)
    Q.waitMs(1500)
    H.step(2, function()
        if T.off then return end
        if not T.fX then
            if (T.qAt or 0) == 0 then Q.skip(L .. ": A on craft:craftCancel", "the batch ended during the pictures (" .. tostring(T.madeAt) .. " made)")
            else Q.check(false, L .. ": the band's X is a pad stop (craft:craftCancel)", tostring(T.qAt) .. " crafts queued, on " .. tostring(H.focusedId())) end
            H.padOff()
            return
        end
        Q.check(H.qcount("ISHandcraftAction") == 0 and H.qlen() == 0 and not H.st("craft")._progOn,
            L .. " (call 2): A on craft:craftCancel stops the craft and the queue empties", "at A " .. tostring(T.qAt) .. " crafts queued, " .. tostring(T.madeAt)
            .. " made; after: " .. H.qkinds() .. ", band " .. tostring(H.st("craft")._progOn))
        H.padOff()
    end)
    H.step(2, function() H.shut("craft"); for _, it in ipairs(S.caseMade) do H.removeItem(it) end; H.sweepNew() end)
end
-- X while the walk (or the moves) before the craft still run: by the mouse at a table, by the pad at a pottery wheel
function C.c2walk(kind)
    local T = {}
    local L = "2 band, X during the walk to " .. (kind == "table" and "a table" or "a pottery wheel")
    local name = (kind == "table") and S.R.drill or S.R.cup
    local out = (kind == "table") and S.OUT.drill or S.OUT.cup
    H.step(2, function()
        if kind == "table" then
            T.table = H.mkTable(S.FAR2)
            if not T.table then T.why = "no table could be laid 2 squares off"; return end
            T.crate = H.mkCrate()
            local plank, driver = H.kind("plank"), H.kind("driver")
            if T.crate then
                T.p = H.giveTo(T.crate.inv, plank)
                T.d = H.giveTo(T.crate.inv, driver)
            else
                T.p, T.d = H.give(plank), H.give(driver)
            end
            if not (T.p and T.d) then T.why = "no plank and screwdriver could be given" end
        else
            if not (H.kind("clay") and H.kind("sandbag")) then T.why = "clay or sandbags are not items this game knows"; return end
            local m, why = H.spawnWheel()
            if not m then T.why = why; return end
            T.wheel = m
            pcall(function() ISEntityUI.OpenWindow(S.p, m) end)
            H.giveN(H.kind("clay"), 2)
            H.giveN(H.kind("sandbag"), 2)
        end
    end)
    H.wait(4000, function()
        if T.why then return true end
        if kind == "table" then return true end
        local cur = S.ST.current(S.p)
        return cur ~= nil and cur.obj == T.wheel
    end, function(ok)
        if T.why then Q.skip(L, T.why); T.off = true; return end
        if not ok then Q.skip(L, "the pottery wheel could not be bound (ISEntityUI.OpenWindow)"); T.off = true end
    end)
    H.step(10, function() if not T.off then H.tab("craft") end end)
    H.stageOpen("craft", T, name, L, nil)
    H.step(2, function()
        if T.off then return end
        if not H.zedCan(H.row("craft", name)) then Q.skip(L, name .. " is not ready here (" .. H.rowText("craft", name) .. ")"); T.off = true; return end
        local e = H.entry("craft", name)
        S.bandWant = e and e.displayName or name
        S.bandSeen = nil
        T.c0 = H.count(out)
        if kind == "table" then
            H.press("craft", "action_build", L .. ", Craft")
        else
            H.padOn()
        end
    end)
    if kind ~= "table" then
        H.focusOn(T, "fCraft", "craft:actBuild")
        H.tapA(function() return T.fCraft end)
    end
    H.step(2, function()
        if T.off then return end
        local a = H.queue()[1]
        T.headObj = a
        T.headKind = H.head()
        T.crafts = H.qcount("ISHandcraftAction")
        local _, pct = S.CC.craftProgress(RT.ww(), S.p)
        T.pct = pct
        T.bandPct = H.fresh2(S.bandSeen) and S.bandSeen.pct or nil
        T.walkFirst = a ~= nil and a.Type ~= "ISHandcraftAction"
        if kind == "table" then
            local z = H.zone("craft", "craftCancel")
            T.zX = z ~= nil
            T.walkAtX = T.walkFirst
            if z and T.walkFirst then H.click("craft", z, L .. ", X") end
        end
    end)
    if kind ~= "table" then
        H.focusOn(T, "fX", "craft:craftCancel", 1500)
        -- (what heads the queue as the pad's A goes down: the press lands 4 frames on, at its release)
        H.tapA(function()
            if not (T.fX and T.walkFirst) then return false end
            local a = H.queue()[1]
            T.headObj, T.headKind = a, H.head()
            T.walkAtX = a ~= nil and a.Type ~= "ISHandcraftAction"
            return true
        end)
    end
    H.step(3, function()
        if T.off then return end
        if not T.walkFirst then
            Q.skip(L, "no walk or move came before the craft (" .. tostring(T.headKind) .. ", " .. tostring(T.crafts) .. " crafts queued)")
            return
        end
        if kind ~= "table" and not T.fX then
            Q.check(false, L .. ", pad: the band's X is a pad stop while the walk runs (craft:craftCancel)", "on " .. tostring(H.focusedId()) .. "; queue " .. H.qkinds())
            return
        end
        if not T.walkAtX then
            Q.skip(L .. ": X during the walk", "the walk had ended before the pad's A on X (" .. tostring(T.headKind) .. ")")
            return
        end
        Q.check(T.crafts >= 1 and T.pct == 0 and (T.bandPct == nil or T.bandPct == 0), L .. " (call 2): the band shows at 0 while the "
            .. string.lower(tostring(T.headKind)) .. " runs before the craft", "queue " .. tostring(T.headKind) .. " first, " .. tostring(T.crafts) .. " craft(s); the share "
            .. tostring(T.pct) .. ", drawn " .. tostring(T.bandPct) .. "; the X " .. (kind == "table" and tostring(T.zX) or ("pad stop " .. tostring(T.fX))))
        Q.check(H.qcount("ISHandcraftAction") == 0 and (T.headObj == nil or H.qhas(T.headObj) or H.qlen() == 0),
            L .. " (call 2): X takes ZeD's waiting crafts out and the " .. string.lower(tostring(T.headKind)) .. " goes on",
            "after X: " .. H.qkinds())
    end)
    H.wait(20000, function() H.speed(1); return T.off or H.qlen() == 0 end, function()
        if T.off or not T.walkAtX then return end
        Q.check(H.count(out) == T.c0, L .. ": nothing is made after X", (H.count(out) - T.c0) .. " made")
        if kind == "table" then
            H.note(L .. ": after X the plank is in " .. H.ctype(H.where(T.p)) .. ", the screwdriver in " .. H.ctype(H.where(T.d))
                .. " (the moves before the craft stand; the game's own cancel leaves them too)")
        end
    end)
    H.step(2, function() H.padOff(); pcall(function() S.ST.unbind(S.p) end); H.shut("craft"); H.qstop() end)
end
function C.c2()
    local T = {}
    local L = "2 band"
    H.caseStart(L)
    H.toTab("craft", T, L)
    C.c2mouse()
    C.c2pad()
    C.c2walk("table")
    H.step(2, function() H.caseClean() end)
    H.toTab("craft", T, L)
    C.c2walk("wheel")
    H.caseEnd(L)
end

-- ===================================================================== 3. the tool notes (call 3)
function C.c3()
    local T = { name = S.R.stake }
    local L = "3 notes"
    H.caseStart(L)
    H.toTab("craft", T, L)
    -- every input of every Craft recipe: ZeD's notes against the game's own tooltip checks
    H.step(2, function()
        if T.off then return end
        local d = H.dat("craft")
        local n, bad, dup, hidden = 0, {}, {}, {}
        for _, e in ipairs((d and d.flatRecipes) or {}) do
            for _, def in ipairs(e.inputDefs or {}) do
                if def.inputRef then
                    n = n + 1
                    local all, once = H.gameNotes(def.inputRef)
                    local z = S.CC.inputNotes(def) or {}
                    local same = #z == #once
                    for i = 1, #once do if z[i] ~= once[i] then same = false end end
                    if not same then bad[#bad + 1] = e.name .. "/" .. tostring(def.name) .. " ZeD [" .. table.concat(z, " | ") .. "] game [" .. table.concat(once, " | ") .. "]" end
                    if #all > #once then dup[#dup + 1] = e.name .. "/" .. tostring(def.name) end
                    if #once > 0 and not (def.isTool or def.isKeep) then hidden[#hidden + 1] = e.name .. "/" .. tostring(def.name) .. " (" .. table.concat(once, " | ") .. ")" end
                end
            end
        end
        Q.check(n > 0 and #bad == 0, L .. " (call 3): every Craft input's notes are the game's own tooltip checks, in its order and words (CC.inputNotes)",
            n .. " inputs read; differ: " .. H.list(bad, 5))
        H.note(L .. ": " .. #dup .. " inputs the game's tooltip names the same line twice (MayDegradeLight and MayDegradeVeryLight), once on ZeD's card: " .. H.list(dup, 4))
        H.note(L .. ": " .. #hidden .. " consumed inputs have notes in the game's tooltip that ZeD's card does not draw (it draws them under tool and kept rows only): " .. H.list(hidden, 5))
    end)
    H.stageOpen("craft", T, S.R.stake, L, function(T2)
        T2.k = H.give(S.stakeKnife)
        T2.b = H.give(S.stakeBranch)
        if not (T2.k and T2.b) then T2.skip = "a knife and a branch could not be given" end
    end)
    H.wait(3000, function() local c = S.cards.craft; return T.off or (H.fresh2(c) and c.name == S.R.stake) end, function(ok)
        if T.off then return end
        T.kidx = H.slotOf("craft", S.R.stake, S.stakeKnife)
        local e = H.entry("craft", S.R.stake)
        T.def = T.kidx and e.inputDefs[T.kidx]
        T.kname = H.ingName("craft", S.R.stake, T.kidx)
        local _, once = H.gameNotes(T.def and T.def.inputRef)
        T.want = once
        C.c3drawn(T, L .. ", mouse (the card opened by its row)")
    end)
    H.themeShots(3, "toolnotes", "Make Stake's card: the knife's row with the game's notes under it (may be damaged, must not be dull)", function() return not T.off end)
    H.step(2, function() if not T.off then H.padOn() end end)
    H.focusOn(T, "fK", function() return "craft:slotAlt:" .. tostring(T.kname) end)
    H.step(8, function()
        if T.off then return end
        if not T.fK then Q.check(false, L .. ", pad: the knife's row is a pad stop", "craft:slotAlt:" .. tostring(T.kname) .. "; on " .. tostring(H.focusedId())); H.padOff(); return end
        C.c3drawn(T, L .. ", pad (the focus on the knife's row)")
        H.padOff()
    end)
    H.caseEnd(L)
end
function C.c3drawn(T, label)
    local c = S.cards.craft
    local lines = T.def and T.def._noteLines or {}
    local dim = ZeD.T.textDim
    local miss = {}
    for _, line in ipairs(lines) do
        local hit = false
        for _, t in ipairs((c and c.texts) or {}) do
            if t.s == line and t.font == ZeD.T.fontF5 and math.abs((t.r or 0) - dim.r) < 0.01 and math.abs((t.g or 0) - dim.g) < 0.01 then hit = true end
        end
        if not hit then miss[#miss + 1] = line end
    end
    local joined = table.concat(lines, " ")
    local all = table.concat(T.want or {}, " ")
    Q.check(#lines > 0 and #miss == 0 and string.gsub(joined, "%s+", "") == string.gsub(all, "%s+", ""),
        label .. " (call 3): the knife's notes are drawn under its row in the game's words, dim and small, wrapped",
        "the game's notes \"" .. all .. "\"; " .. #lines .. " lines drawn \"" .. joined .. "\"; not drawn dim in the small font: " .. H.list(miss))
end

-- ===================================================================== 4. no pin cap (call 4)
function C.pins(tb)
    local T = {}
    local L = "4 pins, " .. ((tb == "craft") and "Craft" or "Build")
    local stateKey, pinKey = S.TB[tb].pins, S.TB[tb].pinKey
    H.toTab(tb, T, L)
    H.step(2, function()
        if T.off then return end
        local w, d = RT.ww(), H.dat(tb)
        T.p0 = {}
        for _, nm in ipairs(w[stateKey] or {}) do T.p0[#T.p0 + 1] = nm end
        T.names = {}
        for _, e in ipairs((d and d.flatRecipes) or {}) do
            if #T.names < 10 and not S.CC.isPinned(w, e.name, stateKey) then T.names[#T.names + 1] = e.name end
        end
        if #T.names < 10 then Q.skip(L, "fewer than 10 recipes are left unpinned"); T.off = true; return end
        -- (the game's favourite flags a Craft pin sets, kept to be put back: C18)
        local md = S.p:getModData()
        for _, nm in ipairs(T.names) do
            local k = nil
            pcall(function() k = BaseCraftingLogic.getFavouriteModDataString(nm) end)
            if k and S.fav[k] == nil then S.fav[k] = { v = md[k] } end
        end
        for i = 1, 8 do pcall(S.CC.togglePin, w, T.names[i], pinKey, stateKey, "filterDirty") end
        H.st(tb).filterDirty = true
        H.note(L .. ": " .. #T.p0 .. " pins found; 8 more pinned from code (as a right-click on the row does), the 9th and 10th by a right-click and the pad's X")
        local e9 = H.entry(tb, T.names[9])
        H.setSearch(tb, e9 and e9.displayName or T.names[9])
    end)
    H.wait(4000, function() return T.off or H.zone(tb, "recipeRow", T.names[9]) ~= nil end, function(ok)
        if T.off then return end
        T.r9 = ok and H.rclick(tb, H.zone(tb, "recipeRow", T.names[9]), L .. ", the 9th")
        if not ok then pcall(S.CC.togglePin, RT.ww(), T.names[9], pinKey, stateKey, "filterDirty"); H.note(L .. ": the 9th's row was not in view: pinned from code") end
        local e10 = H.entry(tb, T.names[10])
        H.setSearch(tb, e10 and e10.displayName or T.names[10])
    end)
    H.wait(4000, function() return T.off or H.zone(tb, "recipeRow", T.names[10]) ~= nil end, function(ok)
        if T.off then return end
        T.z10 = ok
        H.padOn()
    end)
    -- (a few frames for the pad's stops to be built for the list as it now stands: the focus ring is made while the
    -- tab draws, so the row's stop is not there in the frame the pad comes on)
    Q.waitMs(400)
    H.wait(3000, function()
        if T.off or not T.z10 then return true end
        T.f10 = H.focusEl(tb .. ":row:" .. T.names[10])
        return T.f10
    end, function()
        if T.off then return end
        -- what Build asked for: the focused stop, whether it takes X, and the pins before the press
        local e = nil
        pcall(function() e = S.F.liveElement(RT.ww()) end)
        T.pinsBefore = #(RT.ww()[stateKey] or {})
        H.note(L .. ": before the pad's X the focus is on " .. tostring(e and e.id) .. ", onContextMenu " .. tostring(e and e.onContextMenu ~= nil)
            .. ", " .. T.pinsBefore .. " pinned")
    end)
    H.tapX(function() return T.f10 end)
    H.step(2, function()
        if T.off then return end
        H.note(L .. ": after the pad's X (the QA hook's press and release through FocusManager), " .. #(RT.ww()[stateKey] or {}) .. " pinned (before "
            .. tostring(T.pinsBefore) .. "), the 10th pinned " .. tostring(S.CC.isPinned(RT.ww(), T.names[10], stateKey)))
    end)
    H.step(6, function()
        if T.off then return end
        H.setSearch(tb, "")
        H.st(tb).filterDirty = true
    end)
    Q.waitMs(600)
    H.step(2, function()
        if T.off then return end
        local w, st = RT.ww(), H.st(tb)
        local lost, notPinned = {}, {}
        for _, nm in ipairs(T.p0) do if not S.CC.isPinned(w, nm, stateKey) then lost[#lost + 1] = nm end end
        for _, nm in ipairs(T.names) do if not S.CC.isPinned(w, nm, stateKey) then notPinned[#notPinned + 1] = nm end end
        local inGroup = {}
        for _, sec in ipairs(st._sections or {}) do
            if sec.id == "pinned" then for _, rd in ipairs(sec.items or {}) do inGroup[rd.entry.name] = true end end
        end
        local outGroup = {}
        for _, nm in ipairs(T.names) do if not inGroup[nm] then outGroup[#outGroup + 1] = nm end end
        Q.check(T.r9 and T.f10 and #lost == 0 and #notPinned == 0 and #(w[stateKey] or {}) == #T.p0 + 10,
            L .. " (call 4): no cap: 10 pins past the " .. #T.p0 .. " found are all kept, none dropped (the 9th by a right-click, the 10th by the pad's X)",
            #(w[stateKey] or {}) .. " pinned; the 9th's right-click " .. tostring(T.r9) .. ", the pad on the 10th " .. tostring(T.f10) .. "; not pinned "
            .. H.list(notPinned) .. "; found pins dropped " .. H.list(lost))
        Q.check(#outGroup == 0, L .. ": all of them are in the Pinned group", "missing from it: " .. H.list(outGroup))
        if tb == "craft" then
            local md, flags = S.p:getModData(), 0
            for _, nm in ipairs(T.names) do
                local k = nil
                pcall(function() k = BaseCraftingLogic.getFavouriteModDataString(nm) end)
                if k and md[k] == true then flags = flags + 1 end
            end
            H.note(L .. " (C18): " .. flags .. " of the 10 carry the game's favourite flag")
        end
        H.padOff()
        H.pinsBack(tb)
    end)
end
function H.pinsBack(tb)
    local md = S.p:getModData()
    local key, stateKey = S.TB[tb].pinKey, S.TB[tb].pins
    local was = S.found.mdKeys and S.found.mdKeys[key]
    if was then
        if was.v then local t = {}; for k, v in pairs(was.v) do t[k] = v end; md[key] = t else md[key] = nil end
    end
    if tb == "craft" then for k, v in pairs(S.fav) do md[k] = v.v end end
    local w = RT.ww()
    if w then pcall(S.CC.loadPins, w, key, stateKey) end
    local st = H.st(tb)
    if st and w then st.pins = w[stateKey] or {}; st.filterDirty = true end
end
function C.c4()
    local L = "4 pins"
    H.caseStart(L)
    C.pins("craft")
    C.pins("build")
    H.caseEnd(L)
end

-- ===================================================================== 5. double-click on a Build row (call 5)
function C.c5()
    local T = {}
    local L = "5 double"
    H.caseStart(L)
    H.toTab("build", T, L)
    H.step(2, function()
        if T.off then return end
        T.name = H.rname("cross")
        if not T.name then Q.skip(L, "the Building tab lists no cross"); T.off = true; return end
        T.br = H.give(S.stakeBranch)
        T.ls = H.give("Base.LongStick")
        T.rag = H.give("Base.RippedSheets")
        H.lootRefresh()
        local e = H.entry("build", T.name)
        H.setSearch("build", e and e.displayName or "cross")
    end)
    H.wait(8000, function()
        if T.off then return true end
        local rd = H.row("build", T.name)
        return H.zone("build", "recipeRow", T.name) ~= nil and rd ~= nil and rd.status == "craftable"
    end, function(ok)
        if T.off then return end
        if not ok then Q.skip(L, "the cross's row never read buildable with one set carried (" .. H.rowText("build", T.name) .. ")"); T.off = true; return end
        H.shut("build")
    end)
    -- two clicks inside 300 ms
    H.step(3, function()
        if T.off then return end
        T.cnt0 = H.md("ZeD_BuildCounts", T.name)
        T.t1 = getTimestampMs()
        H.click("build", H.zone("build", "recipeRow", T.name), L .. ", the first click")
        T.sel1 = H.st("build").selected
        T.cur1 = H.drag()
    end)
    H.step(2, function()
        if T.off then return end
        local z = H.zone("build", "recipeRow", T.name)
        T.dt = getTimestampMs() - T.t1
        H.click("build", z, L .. ", the second click")
        T.cur = H.drag()
    end)
    H.step(2, function()
        if T.off then return end
        Q.check(T.sel1 == T.name and T.cur1 == nil and H.isBuildCur(T.cur) and H.md("ZeD_BuildCounts", T.name) - T.cnt0 == 1 and T.dt <= 300,
            L .. " (call 5): two clicks on the row inside 300 ms start the build cursor (the card's own Build), counted once",
            "the first opened " .. tostring(T.sel1) .. " (cursor " .. H.dragType(T.cur1) .. "); the second " .. T.dt .. " ms later: " .. H.dragType(T.cur)
            .. ", count +" .. (H.md("ZeD_BuildCounts", T.name) - T.cnt0))
        H.noDrag()
        H.shut("build")
    end)
    -- two clicks 600 ms apart
    H.step(3, function()
        if T.off then return end
        T.cnt1 = H.md("ZeD_BuildCounts", T.name)
        T.s1 = H.click("build", H.zone("build", "recipeRow", T.name), L .. ", a slow first click")
    end)
    Q.waitMs(600)
    H.step(1, function()
        if T.off then return end
        T.s2 = H.click("build", H.zone("build", "recipeRow", T.name), L .. ", a slow second click")
        Q.check(T.s1 and T.s2 and H.drag() == nil and H.st("build").selected == T.name and H.md("ZeD_BuildCounts", T.name) == T.cnt1,
            L .. ": two clicks 600 ms apart open the card and start nothing", "both clicks on the row " .. tostring(T.s1) .. "/" .. tostring(T.s2)
            .. "; cursor " .. H.dragType(H.drag()) .. ", card " .. tostring(H.st("build").selected))
        H.noDrag()
        H.shut("build")
        H.padOn()
    end)
    -- the pad: A then A
    H.focusOn(T, "fRow", function() return "build:row:" .. tostring(T.name) end)
    H.tapA(function() return T.fRow end)
    H.wait(3000, function() return T.off or (H.st("build").selected == T.name and H.focusedId() == "build:actBuild") end, function(ok)
        if T.off then return end
        T.onBuild = ok
        if not ok and H.st("build").selected == T.name then T.onBuild = H.focusEl("build:actBuild"); T.moved = true end
    end)
    H.tapA(function() return T.onBuild end)
    H.wait(3000, function() return T.off or H.isBuildCur(H.drag()) end, function(ok)
        if T.off then return end
        Q.check(T.fRow and T.onBuild and not T.moved and ok, L .. ", pad (call 5): A on the row opens the card on Build, A again starts the cursor",
            "on the row " .. tostring(T.fRow) .. ", then on " .. tostring(H.focusedId()) .. (T.moved and " (the focus put on Build by the script)" or "")
            .. "; cursor " .. H.dragType(H.drag()))
        H.noDrag()
        H.padOff()
        -- a row that cannot be built
        H.removeItem(T.rag)
        H.lootRefresh()
        H.shut("build")
    end)
    H.wait(8000, function() local rd = H.row("build", T.name); return T.off or (rd and rd.status ~= "craftable" and rd.status ~= "unlocked") end, function(ok)
        if T.off then return end
        T.cnt2 = H.md("ZeD_BuildCounts", T.name)
        T.d1 = H.click("build", H.zone("build", "recipeRow", T.name), L .. ", short: the first click")
    end)
    H.step(2, function()
        if T.off then return end
        T.d2 = H.click("build", H.zone("build", "recipeRow", T.name), L .. ", short: the second click")
        Q.check(T.d1 and T.d2 and H.drag() == nil and H.md("ZeD_BuildCounts", T.name) == T.cnt2, L .. ": a double-click on a row that cannot be built (no rag) starts nothing",
            "both clicks on the row " .. tostring(T.d1) .. "/" .. tostring(T.d2) .. "; row " .. H.rowText("build", T.name) .. "; cursor " .. H.dragType(H.drag()))
        H.noDrag()
    end)
    H.caseEnd(L)
end

-- ===================================================================== 6. Show: All and the red skill tag (call 6)
function C.c6()
    local T = {}
    local L = "6 skill"
    H.caseStart(L)
    -- a fresh Build tab (the state found set aside and put back after, vk3_craft's way)
    H.step(2, function()
        local w = RT.ww()
        if not w then T.off = true; return end
        H.tab("craft")
        T.was, T.taken = w._buildState, true
        w._buildState = nil
    end)
    H.step(8, function() if not T.off then H.tab("build") end end)
    H.wait(8000, function() return T.off or (H.showing("build") and H.st("build") ~= nil and H.st("build").filteredCache ~= nil) end, function(ok)
        if T.off then return end
        local st = H.st("build")
        local mode = nil
        pcall(function() mode = S.CC.showMode(st, nil) end)
        Q.check(ok and mode == "all", L .. " (call 6): a fresh Building tab opens on Show: All", "Show " .. tostring(mode) .. " (the state's own " .. tostring(st and st.show) .. ")")
        H.setLevel("Woodwork", 0)
        T.lv = H.level("Woodwork")
        RT.ww()._buildCache = nil
        st.filterDirty = true
        T.crate = H.rname("crate")
    end)
    H.wait(5000, function() local rd = T.crate and H.row("build", T.crate); return T.off or (rd ~= nil and rd.hasSkill == false) end, function(ok)
        if T.off then return end
        if not T.crate then Q.skip(L, "no skill-needing wood crate is listed"); T.off = true; return end
        -- every row: a tag exactly when the game says a skill is short, and the game's name and level for it
        local d, st = H.dat("build"), H.st("build")
        local listed = {}
        for _, rd in ipairs(st.filteredCache or {}) do listed[rd.entry.name] = true end
        local short, bad, hidden = 0, {}, {}
        for _, rd in ipairs((d and d.recipes) or {}) do
            local want = H.gameSkillTag(rd.entry)
            if want then short = short + 1 end
            if rd.skillTag ~= want then bad[#bad + 1] = rd.entry.name .. " ZeD " .. tostring(rd.skillTag) .. ", the game " .. tostring(want) end
            if want and not listed[rd.entry.name] then hidden[#hidden + 1] = rd.entry.name end
        end
        Q.check(ok and short > 0 and #bad == 0, L .. " (call 6): every row short of skill carries the game's skill name and level, no other row a tag",
            "Carpentry " .. tostring(T.lv) .. "; " .. short .. " rows short; differ: " .. H.list(bad, 5))
        Q.check(#hidden == 0, L .. ": under Show: All the rows short of skill are listed", #hidden .. " not listed: " .. H.list(hidden, 5))
        T.want = H.gameSkillTag(H.entry("build", T.crate))
        local e = H.entry("build", T.crate)
        H.setSearch("build", e and e.displayName or "crate")
    end)
    H.wait(4000, function() return T.off or (H.zone("build", "recipeRow", T.crate) ~= nil and H.fresh2(S.rowSeen[T.crate])) end, function(ok)
        if T.off then return end
        C.c6drawn(T, L .. ", mouse", false)
    end)
    H.themeShots(6, "skilltag", "the Build list searched for crates at Carpentry 0: each row short of skill tagged with the skill and level in red",
        function() return not T.off end)
    H.step(2, function() if not T.off then H.padOn() end end)
    H.focusOn(T, "fRow", function() return "build:row:" .. tostring(T.crate) end)
    H.step(8, function()
        if T.off then return end
        if not T.fRow then Q.check(false, L .. ", pad: the crate's row takes the focus", tostring(H.focusedId())); H.padOff(); return end
        C.c6drawn(T, L .. ", pad (the focus on the row)", true)
        H.padOff()
    end)
    H.step(2, function()
        H.levelBack("Woodwork")
        local w = RT.ww()
        if w and T.taken then
            if T.was then w._buildState = T.was end
            w._buildCache = nil
        end
    end)
    H.caseEnd(L)
end
function C.c6drawn(T, label, focus)
    local r = S.rowSeen[T.crate]
    local c = r and r.c
    local danger = ZeD.T.danger
    local textOk = c ~= nil and (focus or H.sameColor(c.tc, ZeD.T.dangerText or danger))
    Q.check(H.fresh2(r) and r.tag == T.want and r.danger == true and c ~= nil and c.text == T.want and H.sameColor(c.color, danger) and textOk,
        label .. " (call 6): the crate's row draws \"" .. tostring(T.want) .. "\" as its tag in the danger color (the game writes the short skill in red)",
        "drawn tag \"" .. tostring(r and r.tag) .. "\", danger " .. tostring(r and r.danger) .. ", Atoms.drawTag \"" .. tostring(c and c.text) .. "\" border danger "
        .. tostring(c and H.sameColor(c.color, danger)) .. ", words " .. (focus and "the focus color" or ("danger " .. tostring(c and c.tc ~= nil and H.sameColor(c.tc, ZeD.T.dangerText or danger)))))
end

-- ===================================================================== 7. the build card's materials (call 7)
-- the slot of entry that takes both types, and the type of the pair the game's own logic does not take there
function H.pairSlot(entry, a, b)
    for i, d in ipairs((entry and entry.inputDefs) or {}) do if d.validTypes and d.validTypes[a] and d.validTypes[b] then return i, d end end
    return nil, nil
end
function C.c7()
    local T = {}
    local L = "7 build"
    H.caseStart(L)
    -- (from where he stood when the run began: a case before may have walked him to a bench)
    H.step(2, function() H.home() end)
    H.toTab("build", T, L)
    H.step(2, function()
        if T.off then return end
        T.name = H.rname("cross")
        local e = T.name and H.entry("build", T.name)
        if not e then Q.skip(L, "the Building tab lists no cross"); T.off = true; return end
        T.a = H.pairSlot(e, "Base.TreeBranch2", "Base.WoodenStick2")
        T.b = H.pairSlot(e, "Base.LongStick", "Base.Sapling")
        if not (T.a and T.b) then Q.skip(L, "the cross's slots do not take branch-or-stick and long-stick-or-sapling here"); T.off = true; return end
        T.crate = H.mkCrate()
        T.sq = H.clearSq()
        if not (T.crate and T.sq) then Q.skip(L, "no crate beside him or no clear square 2 off"); T.off = true; return end
        -- one of each type: the first carried, the second in the crate
        T.it = {
            ["Base.TreeBranch2"] = H.give("Base.TreeBranch2"), ["Base.WoodenStick2"] = H.giveTo(T.crate.inv, "Base.WoodenStick2"),
            ["Base.LongStick"] = H.give("Base.LongStick"), ["Base.Sapling"] = H.giveTo(T.crate.inv, "Base.Sapling"),
        }
        T.rag = H.give("Base.RippedSheets")
        H.lootRefresh()
        local set = H.bUses(e)
        T.pa = set[T.it["Base.TreeBranch2"]] and "Base.WoodenStick2" or "Base.TreeBranch2"
        T.pb = set[T.it["Base.LongStick"]] and "Base.Sapling" or "Base.LongStick"
        T.wa, T.wb = T.it[T.pa], T.it[T.pb]
        T.oa = T.it[(T.pa == "Base.TreeBranch2") and "Base.WoodenStick2" or "Base.TreeBranch2"]
        T.ob = T.it[(T.pb == "Base.LongStick") and "Base.Sapling" or "Base.LongStick"]
        H.note(L .. ": the game's own logic takes the " .. ((T.pa == "Base.TreeBranch2") and "stick" or "branch") .. " and the "
            .. ((T.pb == "Base.LongStick") and "sapling" or "long stick") .. "; chosen: " .. T.pa .. " and " .. T.pb
            .. " (the stick and sapling are in the crate beside him)")
        H.setSearch("build", e.displayName or "cross")
    end)
    H.stageOpen("build", T, function() return T.name end, L, nil)
    -- slot a by the mouse
    H.step(2, function()
        if T.off then return end
        T.ia = H.ingName("build", T.name, T.a)
        T.ib = H.ingName("build", T.name, T.b)
        local z = H.slotZone("build", T.a)
        if not z then Q.check(false, L .. ": the cross's first slot opens an alternatives list on the build card", "no slotAlt zone"); T.off = true; return end
        H.click("build", z, L .. ", the first slot")
    end)
    H.step(3, function()
        if T.off then return end
        local z = H.zone("build", "altPick", T.pa)
        if not (H.st("build").altSlotName and z) then Q.check(false, L .. ": the build card's list offers " .. T.pa, tostring(H.st("build").altSlotName)); T.off = true; return end
        H.click("build", z, L .. ", the type")
    end)
    H.step(4, function()
        if T.off then return end
        local st = H.st("build")
        local p = st.picks and st.picks[T.name]
        Q.check(p ~= nil and p[T.a] == T.pa, L .. ", mouse (call 7): a click on a type in the build card's list chooses it (the craft card's pick list)", "picks " .. tostring(p and p[T.a]))
        local rows = H.zones("build", "altItem")
        Q.check(#rows == 0, L .. ": the Build list opens no item rows under the chosen type (Build's picks are by type: BuildingTab.applyPicks reads state.picks only)",
            #rows .. " item rows drawn (CraftingCore.lua:3420 opens them wherever state._pickOn, which Build's pickIngredients sets)")
    end)
    H.themeShots(7, "picklist", "the cross's build card with its first slot's list open, the type chosen marked", function() return not T.off end)
    H.step(2, function() if not T.off then if not H.press("build", "altStrip_back", L .. ", Back") then pcall(S.CC.exitAltMode, H.st("build")) end end end)
    -- slot b by the pad: A, A, then B leaves the list and the card stays
    H.step(3, function() if not T.off then H.padOn() end end)
    H.focusOn(T, "fSlot", function() return "build:slotAlt:" .. tostring(T.ib) end)
    H.tapA(function() return T.fSlot end)
    H.focusOn(T, "fType", function() return "build:altPick:" .. tostring(T.pb) end)
    H.tapA(function() return T.fType end)
    H.step(4, function()
        if T.off then return end
        local st = H.st("build")
        local p = st.picks and st.picks[T.name]
        T.padPick = p and p[T.b]
    end)
    H.tapB(function() return not T.off and H.st("build").altSlotName ~= nil end)
    H.step(4, function()
        if T.off then return end
        local st = H.st("build")
        Q.check(T.fSlot and T.fType and T.padPick == T.pb, L .. ", pad (call 7): A on the slot opens its list, A on a type chooses it",
            "slot stop " .. tostring(T.fSlot) .. ", type stop " .. tostring(T.fType) .. ", chosen " .. tostring(T.padPick))
        Q.check(st.altSlotName == nil and st.selected == T.name, L .. ", pad: B leaves the alternatives list first, the card stays open",
            "list " .. tostring(st.altSlotName) .. ", card " .. tostring(st.selected))
        H.padOff()
    end)
    -- Build: the cursor's own logic holds the chosen items; placed, the chosen ones are used and the carried ones kept
    H.step(3, function()
        if T.off then return end
        T.cnt0 = H.md("ZeD_BuildCounts", T.name)
        S.halo = {}
        H.noDrag()
        H.press("build", "action_build", L .. ", Build")
        T.cur = H.drag()
        if not H.isBuildCur(T.cur) then Q.check(false, L .. ": Build with the chosen materials starts the cursor", H.dragType(T.cur) .. "; said " .. H.list((function() local o = {}; for _, h in ipairs(S.halo) do o[#o + 1] = h.text end; return o end)())); T.off = true; return end
        local holds = {}
        pcall(function()
            local lg = T.cur.buildPanelLogic
            lg:canPerformCurrentRecipe()
            local items = lg:getRecipeData():getAllInputItems()
            for i = 0, items:size() - 1 do holds[items:get(i)] = true end
        end)
        Q.check(holds[T.wa] and holds[T.wb] and not holds[T.oa] and not holds[T.ob], L .. " (call 7): the cursor's own logic (BuildingTab.applyPicks, manual select) holds the chosen items",
            "chosen " .. tostring(holds[T.wa] == true) .. " / " .. tostring(holds[T.wb] == true) .. ", the others " .. tostring(holds[T.oa] == true) .. " / " .. tostring(holds[T.ob] == true))
        T.before = H.snapObjs(10)
        T.watch = function() return H.carried(T.wa) and H.carried(T.wb) end
        H.speed(1)
        H.placeAt(T.cur, T.sq, L)
        T.go = H.qlen() > 0
        if not T.go then Q.check(false, L .. ": the placement 2 squares off queues the build", "valid " .. tostring(T.cur.canBeBuild) .. ", queue " .. H.qkinds()) end
    end)
    H.runBuild(T, 50000)
    H.step(2, function()
        if T.off or not T.go then return end
        Q.check(#(T.new or {}) >= 1 and H.gone(T.wa) and H.gone(T.wb) and not H.gone(T.oa) and not H.gone(T.ob),
            L .. " (call 7): the cross stands, built from the chosen materials; the ones the game would have taken are kept",
            #(T.new or {}) .. " new objects, " .. tostring(T.acts) .. " build action(s); chosen " .. (H.gone(T.wa) and "used" or "KEPT") .. " / " .. (H.gone(T.wb) and "used" or "KEPT")
            .. ", the others " .. (H.gone(T.oa) and "USED" or "kept") .. " / " .. (H.gone(T.ob) and "USED" or "kept"))
        Q.check(T.inReach == true, L .. ": the chosen materials (in the crate) are moved to him before the walk (the B7 move carries the picks)",
            "carried when the build action started: " .. tostring(T.inReach))
        H.noDrag()
        for _, o in ipairs(T.new or {}) do H.rmObjRaw(o) end
    end)
    -- Build again: the chosen types are used up; by the pad
    H.step(3, function()
        if T.off then return end
        T.rag2 = H.give("Base.RippedSheets")
        H.lootRefresh()
        local st = H.st("build")
        if st.selected ~= T.name then pcall(S.CC.openCraft, st, T.name) end
        local p = st.picks and st.picks[T.name]
        T.still = p and p[T.a] == T.pa and p[T.b] == T.pb
        S.halo = {}
        T.cnt1 = H.md("ZeD_BuildCounts", T.name)
        H.padOn()
    end)
    H.focusOn(T, "fBuild", "build:actBuild")
    H.tapA(function() return T.fBuild end)
    H.step(8, function()
        if T.off then return end
        local said, want, heard = H.saidInputs()
        Q.check(T.fBuild and H.drag() == nil and H.md("ZeD_BuildCounts", T.name) == T.cnt1 and T.still,
            L .. ", pad (call 7): with the chosen types used up, A on Build starts nothing (the other branch and long stick are not taken instead)",
            "picks kept " .. tostring(T.still) .. "; focus " .. tostring(T.fBuild) .. "; cursor " .. H.dragType(H.drag()))
        Q.check(said, L .. ": and the character says the game's words (IGUI_CraftingWindow_Error_Inputs)", "wanted \"" .. tostring(want) .. "\"; said " .. tostring(heard))
        local sr = S.slotSeen[tostring(T.ia)]
        H.note(L .. ": with " .. T.pa .. " used up the slot row reads \"" .. tostring(sr and sr.disp) .. "\" " .. tostring(sr and sr.have) .. "/" .. tostring(sr and sr.need)
            .. " (a type pick names the type but keeps the slot's count of every type it takes, CraftingCore.lua:3937-3938) while Build refuses")
        H.noDrag()
    end)
    -- B on the card closes it
    H.step(2, function()
        if T.off then return end
        T.fCard = H.focusEl("build:card:req") or H.focusEl("build:icon")
    end)
    H.tapB(function() return T.fCard end)
    H.step(6, function()
        if T.off then return end
        Q.check(T.fCard and H.st("build").selected == nil, L .. ", pad: B on the card (out of the list) closes it", "card " .. tostring(H.st("build").selected) .. ", focus " .. tostring(H.focusedId()))
        H.padOff()
    end)
    -- planks by type
    H.step(2, function()
        local d = H.dat("build")
        local found = nil
        for _, e in ipairs((d and d.flatRecipes) or {}) do
            for _, def in ipairs(e.inputDefs or {}) do
                if not found and def.validTypes and def.validTypes["Base.Plank"] and (def.altCount or 0) > 0 then found = e.name .. "/" .. tostring(def.name) end
            end
        end
        if found then
            H.note(L .. ": a build slot takes planks with another type (" .. found .. "): not staged here; the cross's slots carry the proof")
        else
            Q.skip(L .. ": planks chosen by type", "no build recipe here takes planks with a second type: every plank slot is Base.Plank alone (altCount 0, CraftingCore.lua:1058), so the card opens no list for it and planks cannot be chosen; the cross's branch-or-stick and long-stick-or-sapling slots carry the proof of call 7")
        end
    end)
    H.caseEnd(L)
end

-- ===================================================================== put back
function H.putBack()
    if not S.back.on then return end
    S.back.on = nil
    local f = S.found
    H.speed(1)
    H.qstop()
    H.noDrag()
    H.park(false)
    H.padOff()
    H.themeBack()
    H.wrapOff()
    pcall(function() if S.orig.walk then ISEntityUI.WalkToEntity = S.orig.walk end end)
    pcall(function() S.ST.unbind(S.p) end)
    for _, c in ipairs(S.objs) do H.rmObj(c) end
    for _, o in ipairs(S.built) do if H.objOn(o) then H.rmObjRaw(o) end end
    for _, it in ipairs(S.made) do H.removeItem(it) end
    S.xpGrew, S.xpLeft = H.xpBack()
    local md = S.p:getModData()
    for k, v in pairs(S.fav) do md[k] = v.v end
    if f.recorded then
        for key, v in pairs(f.mdKeys or {}) do
            if v.v then local t = {}; for k2, v2 in pairs(v.v) do t[k2] = v2 end; md[key] = t else md[key] = nil end
        end
        local w = RT.ww()
        if w then
            pcall(S.CC.loadPins, w, "ZeD_CraftPins", "_craftPins")
            pcall(S.CC.loadPins, w, "ZeD_BuildPins", "_buildPins")
            w._craftCache, w._buildCache, w._craftQueued, w._craftQueuedRecipe = nil, nil, nil, nil
            if f.bstate and w._buildState ~= f.bstate then w._buildState = f.bstate end
        end
        pcall(function() S.p:setTimedActionInstantCheat(f.inst and true or false) end)
        pcall(function() S.p:setBuildCheat(f.bc and true or false) end)
        pcall(function() ISBuildMenu.cheat = f.bm end)
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
        pcall(function()
            local a, b = f.hands.p, f.hands.s
            S.p:setPrimaryHandItem((a and S.p:getInventory():containsRecursive(a)) and a or nil)
            S.p:setSecondaryHandItem((b and S.p:getInventory():containsRecursive(b)) and b or nil)
        end)
        H.home()
        if f.layout and ZEDQA_LAYOUT_BACK then pcall(ZEDQA_LAYOUT_BACK, f.layout, "cb_calls") end
        H.lootRefresh()
        if f.st then pcall(function() S.ST.bind(S.p, f.st) end) end
        pcall(S.WW.openTab, S.pn, "craft")
    end)
    Q.step(20, function()
        local f = S.found
        if not f.recorded then return end
        local cst, bst = H.st("craft"), H.st("build")
        if cst and f.ckeep then H.putState("craft", cst, f.ckeep) end
        if bst and f.bkeep then H.putState("build", bst, f.bkeep) end
        H.tab(f.tab or "loot")
    end)
    Q.step(20, function()
        local f = S.found
        if not f.recorded then Q.skip("put back", "nothing was staged"); return end
        local left = {}
        for _, it in ipairs(S.made) do if not H.gone(it) then left[#left + 1] = H.ft(it) end end
        Q.check(#left == 0, "put back: every thing the run gave is gone (inventory, crates, floor)", #S.made .. " given; left " .. H.list(left))
        local extra = {}
        for _, it in ipairs(H.all()) do if not f.inv0[it] then extra[#extra + 1] = H.ft(it) end end
        Q.check(#extra == 0 and (S.lost or 0) == 0, "put back: he carries what he carried (nothing crafted left, his set-aside things back)",
            "new " .. H.list(extra) .. "; " .. tostring(S.swept) .. " swept, " .. tostring(S.floorSwept) .. " off the floor, " .. tostring(S.refilled)
            .. " of his own used things given again, " .. tostring(S.lost) .. " set-aside things not given back")
        local objs = {}
        for _, c in ipairs(S.objs) do if H.objLeft(c) then objs[#objs + 1] = c.what end end
        for _, o in ipairs(S.built) do if H.objOn(o) then objs[#objs + 1] = "built " .. H.objName(o) end end
        for _, o in ipairs(H.newObjs(f.objs0 or {}, 10)) do objs[#objs + 1] = "new " .. H.objName(o) end
        Q.check(#objs == 0, "put back: every object laid or built is gone (tables, crates, the pottery wheel, the crosses)", #S.objs .. " laid, " .. #S.built .. " built; left " .. H.list(objs))
        local inst, bc = nil, nil
        pcall(function() inst, bc = S.p:isTimedActionInstantCheat(), S.p:isBuildCheat() end)
        Q.check((inst and true or false) == (f.inst and true or false) and (bc and true or false) == (f.bc and true or false) and ISBuildMenu.cheat == f.bm,
            "put back: the cheats as found (instant actions, his BuildCheat, ISBuildMenu.cheat)", tostring(inst) .. ", " .. tostring(bc) .. ", " .. tostring(ISBuildMenu.cheat))
        local md = S.p:getModData()
        local pinsOk, why = true, {}
        for key, v in pairs(f.mdKeys or {}) do
            local now = md[key]
            local a, b = 0, 0
            for _ in pairs(v.v or {}) do a = a + 1 end
            for _ in pairs(now or {}) do b = b + 1 end
            local same = a == b
            if same and v.v then for k2, v2 in pairs(v.v) do if now[k2] ~= v2 then same = false end end end
            if not same then pinsOk = false; why[#why + 1] = key .. " " .. a .. " found, " .. b .. " now" end
        end
        local favOk = true
        for k, v in pairs(S.fav) do if md[k] ~= v.v then favOk = false end end
        local w = RT.ww()
        Q.check(pinsOk and favOk, "put back: ZeD's craft and build pins and counts, and the game's favourite flags, as found",
            H.list(why) .. "; favourite flags " .. tostring(favOk))
        local lvlLeft = 0
        pcall(function() for _, r in ipairs(S.xp) do if S.p:getPerkLevel(r.perk) ~= r.lvl then lvlLeft = lvlLeft + 1 end end end)
        if S.xpLeftText then H.note("put back: XP drift left (levels checked): " .. S.xpLeftText) end
        Q.check(lvlLeft == 0, "put back: the skill levels as found (Carpentry set to 0 in case 6)", tostring(S.xpGrew) .. " skills changed, " .. lvlLeft .. " not at their level")
        local dx, dy = math.abs(S.p:getX() - f.pos.x), math.abs(S.p:getY() - f.pos.y)
        Q.check(dx < 0.6 and dy < 0.6 and S.ST.current(S.p) == (f.st or nil) and H.qlen() == 0 and getGameSpeed() == 1 and H.drag() == nil,
            "put back: he stands where he stood, the station as found, no action queued, no cursor, game speed 1",
            string.format("%.1f,%.1f off", dx, dy) .. ", " .. H.qkinds() .. ", cursor " .. H.dragType(H.drag()))
        Q.check(ZeD.currentBase == f.base and H.lockFound() == (S.lockWas or H.lockFound()) and S.parked == nil and S.w0 == nil
            and (not ISEntityUI or ISEntityUI.WalkToEntity == S.orig.walk),
            "put back: the theme, the input lock, the pointer, the draw watchers and the game's walk as found", tostring(ZeD.currentBase) .. ", lock " .. H.lockFound())
        local cst, bst = H.st("craft"), H.st("build")
        local ck, bk = f.ckeep or {}, f.bkeep or {}
        Q.check((cst == nil or (cst.selected == ck.sel and (cst.search or "") == (ck.search or "") and cst.activeCat == ck.cat and cst.show == ck.show))
            and (bst == nil or (bst == f.bstate and bst.selected == bk.sel and (bst.search or "") == (bk.search or "") and bst.show == bk.show)),
            "put back: both tabs' card, search, category and Show as found, the Build tab's own state", tostring(cst and cst.show) .. " / " .. tostring(bst and bst.show)
            .. ", the Build state the one found " .. tostring(bst == f.bstate))
        Q.check(S.errs == 0, "put back: nothing ZeD ran for this script threw", S.errs .. " caught")
        local e1 = H.errN()
        if S.err0 and e1 then Q.check(e1 == S.err0, "the cb_calls run ran with no Lua error", (e1 - S.err0) .. " new")
        else Q.skip("the cb_calls run's Lua error count", "the game's Lua error count cannot be read here") end
        H.note("put back: skill XP the crafts and builds awarded is set back as far as the game lets Lua set it (drift above, if any)")
    end)
    Q.step(10, function()
        local f = S.found
        if f.pair == false and RT.isOpen() then RT.pairShut() end
    end)
end

-- ===================================================================== the run
-- (the knife and branch types the cases queue with are known when the queue is built; setup checks them)
S.stakeKnife, S.stakeBranch = H.kind("knife"), H.kind("branch")
S.setup()
C.c1()
C.c2()
C.c3()
C.c4()
C.c5()
C.c6()
C.c7()
S.buildPutBack()
Q.start()
