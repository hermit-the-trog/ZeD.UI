-- ZeDUI/tools/qa/vk1_cards.lua  (Nov 22 2026, QA batch K1; tag vk1_cc): the in-game proof of Build's fixes for the
-- KISS audit's plain bugs K1-2, K1-7, K1-10, K1-12 and K1-13 (findings: ZeDUI/qa/audits/2026-11-22_kiss_bugs_K1.md).
-- The old code is 2488ceead (what shipped as 0.3.0-beta21c); the fix is 0ebd56570: 327549a67 (K1-7, K1-10's search
-- and category, K1-12), 9a7b0461a (K1-10's clear X, K1-13's words, the NeedsSurface key), e25f4ca68 (K1-2) and
-- 0ebd56570 (K1-13, clothes read Wear). Built on rt_kit.lua (the global RT), run after zedqa_prelude.lua.
-- grep "ZEDQA vk1_cc". Manifest line (QA writes vk1.txt): vk1_cards.lua | vk1_cc | timeout=420
--
-- Every check below FAILS on the old code and PASSES on the fix, for the reason its label gives. The put-back checks
-- at the end pass on both (they prove the script left the game as it found it). A staging that does not come off
-- prints a FAIL line saying "staging" (never a PASS); a world that does not hold the case says SKIP and why.
-- Nothing is crafted, eaten, drunk, worn or read: no Craft, Drink, Wear or Read is pressed. The one press is Eat on a
-- sealed can (D3 below), and the queue it fills is cleared in the same step, before a tick runs.
--
-- K1-13, the UI's words (read through ZeD.tr, the words the UI draws; ZeD's English, so SKIP in another language or
-- with ZeD's test language on):
--   W1 the list heads UI_ZeD_Inv_ColCat / ColWt and UI_ZeD_Equip_ColWeight / ColScratch / ColBullet read Category,
--      Weight, Weight, Scratch, Bullet.                                  Old code: Cat, Wt, Wt, Scr, Bul.
--   W2 the nine help lines ZeD draws that name a mouse button say the game's own Left Click / Right Click
--      (IGUI_mouse_btn_0 / _1), none LMB or RMB (UI_ZeD_Inv_RowHelp, changed too, is drawn by no ZeD code: left out).
--                                                                        Old code: LMB and RMB.
--   W3 eleven help lines and tips name the tabs Crafting, Building and Equipment, the tab strip's help says "press to
--      open its tab", and none says Craft tab, Build tab, Equip tab or drawer.
--                                                                        Old code: "Craft or Build tab", "Equip tab",
--                                                                        "show it in the drawer", "tab drawer", "rod".
--   W4 the pad's In your bags heading (UI_ZeD_Belt_InBags) reads Also on you.   Old code: In your bags.
--   W5 ZeD setup's Wheels and Other mods' notes tips read "A takes and B closes" and "and a click opens Messages".
--                                                                        Old code: "A takes, B closes", "; click it".
-- K1-13 on the Crafting tab:
--   W6 with no station bound, the Station select reads By hand (the value ZeD.Stations.drawSelect is handed as the
--      tab draws its header, watched).                                   Old code: Hand.
-- K1-12 (the World window's Crafting tab):
--   C1 Show: Ready, every category on the Category menu's first page: the number the menu draws beside the category
--      (ZeD.Atoms.drawTextRight inside CC.renderCatDropdownOverlay, watched) is the number of rows the list holds once
--      that row is clicked. The menu is opened by a click on the select and the row picked by a click where it sits,
--      both through ZeD.CraftingTab.onClick, the tab's own click handler. The row's height is read from the menu's
--      own drawing (no pixel size is written in).
--                                                                        Old code: the catalog's total (cat.count),
--                                                                        hundreds for All while Ready lists a few.
--   C2 Sort, opened by a click on its box: its choices (the rows it takes clicks on, state._sortMenuZones, and the
--      words handed to the list) hold no Recent.                         Old code: Recent is the fifth choice.
--   (A NOTE line, not a check: with a held sort of "recent" the Sort box's words and whether the list orders as Freq.)
-- K1-10 (the Crafting tab, Show: All):
--   T1 a tool is picked from S.K10_CANDS: the one with the most recipes the old search misses (staging below; with no
--      miss for any of them, the one with the most recipes, and T2 alone says SKIP); the
--      Category is left on the category holding the fewest of its recipes; then the item's Craft as the game's
--      right-click option runs it: ISEntityUI.OpenHandcraftWindow(player, nil, "*", false, nil, "!" .. fullType),
--      which ZeD routes to the tab (Overrides/Stations.lua). The Category select, drawn after, reads All.
--                                                                        Old code: the category left stays.
--   T2 the category on All (set by hand where the old code left another): the list holds every recipe of the tab
--      that has an ingredient slot whose possible items include the tool (the game's own
--      InputScript:getPossibleInputItems(), automation-only slots left out, as ZeD and the game's window leave them).
--                                                                        Old code: misses every recipe whose name,
--                                                                        category, slots' first items and outputs
--                                                                        do not hold the tool's name (at least one).
--   T3 a click at the search box's right end, where its clear X sits (the box's own mouse handler,
--      UITextBox2.onMouseDown, which clears the words when its clear button is on and the click is past the box's
--      width less the button): the box and the list's search are empty within 2 s.
--                                                                        Old code: no clear button; the click puts
--                                                                        the cursor at the end, the words stay.
-- K1-7 (the Crafting tab, Show: All; each card opened from its row, as a click opens it):
--   R1 a recipe made in the hands that takes 2 uses of duct tape: Make Tarp Sling Bag (MakeTarpSlingBag: a tarp and
--      the tape), else Duct Tape Spear (DuctTapeSpear: a kitchen knife, a long stick and the tape); neither needs a
--      skill or learning. Its things are given, the roll of duct tape set to 1 use (setCurrentUses). The game's own
--      reading (a HandcraftLogic on the containers in reach) must refuse the craft with the tape's slot the only one
--      short, else SKIP. The card's drawing is watched (CC.renderCraftCard; the Required rows ZeD.Molecules.drawSlotRow
--      is handed; the texts it hands CC.truncText, the line under the rows among them). Once every row counts by
--      whole items (the Required head drawn n/n), the tape's row is drawn red (have below need) within 12 s, the
--      other rows stay green and no workbench line shows.             Old code: the tape row green, 1/1, and
--                                                                        "Needs a workbench or station nearby."
--   R2 a recipe made on any surface: Saw Down Baseball Bat (SawDownBaseballBat: a bat and a saw), else Put Eggs in
--      Carton (PutEggsInCarton: 12 eggs). Its things are given; the game's ISEntityUI.FindCraftSurface finds no table
--      or counter within 2 squares (the drag strip), and the game reads every slot satisfied and refuses the craft,
--      else SKIP. After the head reads n/n, within 12 s every row is green and the line under the rows reads "Needs a
--      table or counter nearby.", no workbench line.                     Old code: "Needs a workbench or station
--                                                                        nearby."
-- K1-2 (the Character window's list, his inventory; each card opened by a click on its row; its verbs and marks read
-- from what ZeD_ItemCard.renderBody draws for that thing, watched: the card's _lastHeaderVerbs, its button words):
--   D1 the cards of bleach, rubbing alcohol (Base.Disinfectant) and a gas can (Base.PetrolCan) draw no Drink at all,
--      while a water bottle's main button is Drink.                      Old code: Drink is the main button on all
--                                                                        four (any unsealed fluid container).
--   D2 on a pad, held A on those rows drinks only where the card offers Drink: the word the hint strip shows beside a
--      held A on each row (padItemButtons' promptHold, ZeD.InventoryRenderer.padPromptHold) is not the row's Drink
--      word for the three and is for the water, and the test the hold runs before it drinks (onHoldActivate asks
--      ZeD.InventoryRenderer.padIsDrink first) answers no for the three, yes for the water. A is never held (on the
--      old code that would drink the bleach). The gas can is taken back right after.
--                                                                        Old code: Drink and yes for all four.
--   D3 a sealed can of beans, a can opener given: its card's Eat pressed through the card's own dispatch
--      (ZeD_ItemCard:_dispatchHeaderVerb, what a click on the button and the pad's A both run). The first eat or
--      craft it queues is the can's opening (an ISHandcraftAction of its OpeningRecipe, the game's Open and eat);
--      the queue is cleared at once, in the same step, so nothing is opened or eaten. SKIP if he is stuffed or
--      something is already queued for him.                             Old code: an ISEatFoodAction on the sealed can.
--   D4 stuffed: his eaten-food timer set to 3.5 times its standard (the game's own Well Fed rule: above twice the
--      standard is 3, above three times 4), Well Fed read at 3 or more, then an apple's card: its Eat is drawn
--      grayed and its help line is the game's "Too full to eat more." (Tooltip_CantEatMore). The timer is set back
--      the moment the card is read.                                      Old code: Eat lit, its usual help line.
-- K1-13 on the cards:
--   E1 a T-shirt's main button reads Wear (ZeD.ItemCard.verbText("WEAR"), the game's ContextMenu_Wear).
--                                                                        Old code: Equip.
--   E2 the card's three marks name themselves Favorite, Unusable in Recipes and Unwanted: the words the T-shirt's
--      card hands ZeD.Atoms.drawFlagChip as it draws them (drawn beside each icon on a full-width card, the chip's
--      name on a narrow one); with Lite on, which draws no marks, the chip keys' words.
--                                                                        Old code: Fav, No-craft, Dispose.
-- Not covered here (see the run's NOTE lines): the workbench line on a bound bench (needs a bench; its words are the
-- old code's too), the marks' hover help lines (they need the real pointer), "Freq", "Dist" and "Wt" in the sort
-- bars (left as they were: K1-13 partly), and a held "recent" (no ZeD path saves the Sort; the box then reads
-- "Sort: Craftable" while the list orders as Freq, on the fix: a NOTE line, not a check).
--
-- How it stages: ZEDQA_HOME (the drag strip: open asphalt, no table in reach); both windows open as a pair; a bound
-- station unbound for the run; the World window on its Crafting tab (by its own press), Show All, sorted Craftable,
-- every category, Required and Outputs unfolded, a search found emptied; the Character window on Loot, its extra
-- columns shut, each given kind's stack opened and every category fold opened so each thing has its own row. The
-- tool candidates for T2 are given nothing: the item's Craft takes only the tool's type, as the game's option does.
-- Waits go by the clock. Each staged thing is marked ZeDQA_spawned and taken back.
-- What it puts back (also when a step throws or the time runs out): every wrapper taken off (checked), every thing
-- given (RT.takeBack; strays of the script's own swept, anything else new is said, never deleted), the eaten-food
-- timer, a queue the script filled cleared, the search box let go of the keys, a bound station, his facing, the
-- Crafting tab's Show / Sort / category / folds / Owned only / search (field and list) / open card / scroll, the
-- Character list's stacks, folds, scroll and columns, both windows' tabs, the pair as found. It checks he ate and
-- drank nothing (hunger and thirst not down), gained no poison, food sickness or sickness and lost no health. Not put
-- back: ZEDQA_HOME's move to the drag strip (the QA save keeps it, as every script's). No option is changed or saved,
-- no file is written, ZEDQA_LAYOUT_BACK is never called.
-- Parse-checked with the game's Kahlua compiler (KCheck); not run offline (the vx harness is not in the repo).
-- The live run loads the tree as it is: 0ebd56570 plus Build's KISS K2 commits (194d5dd2a, da6134ec4). None of K2
-- changes what is checked here: K2-3 keeps a pinned recipe listed under any Show, and counts it in the Category
-- numbers the same way; K2-7 only changes a Drainable's card verb; K2-8 a double-click (never sent here).
-- (Nov 22 2026, review: W2 dropped UI_ZeD_Inv_RowHelp, a key no ZeD code draws; D2 reads the hint strip's held-A
-- word too; D3 compares the opening recipe without its module; the gas can goes back after D2; with no tool that
-- the old search misses, T1 and T3 still run and T2 alone says SKIP; the NOTE lines the header names are printed.)
-- (Nov 23 2026, QA: the Loadouts split: UI_ZeD_Settings_RestockTip, UI_ZeD_Settings_LoadoutsTip and UI_ZeD_Todo_HelpBack
-- are the add-on ZeD-GUI: Loadouts' keys (its own UI.json). With Loadouts loaded (built in or the add-on) they are
-- checked as before; ZeD alone after the split has no such words, and the tab-name check leaves them out, said so.)

if not (RT and RT.make) then
    print("ZEDQA vk1_cc ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA vk1_cc VERDICT FAIL 1")
    print("ZEDQA vk1_cc DONE")
    return
end

local Q = RT.make("vk1_cc")
-- (typically about two minutes; every wait at its limit comes to about four and a half, and the put-back after a
-- jump some 20 s more: inside the manifest's 420 s)
Q.maxMs = 330000
local S = { p = RT.p, pn = RT.pn, had = {}, floorHad = {}, cap = {}, sel = {}, dd = {}, card = {}, cards = {}, was = {},
    wraps = {}, k7a = {}, k7b = {}, k10 = {}, k10c = {}, k12s = {}, k12n = {}, beans = {}, full = {}, stackWas = {},
    folds = {}, cols = {}, k12 = { drawn = {}, shown = {}, ids = {}, labels = {}, catalog = {}, why = {}, n = 0 } }
local H = {}
S.CC = ZeD and ZeD.CraftingCore or nil
S.CT = ZeD and ZeD.CraftingTab or nil
S.WW = ZeD_WorldWindow
-- K1-7's recipes (the game's recipes_tailoring.txt, recipes_spears.txt, recipes.txt; none needs a skill or learning):
-- in the hands with 2 uses of duct tape (Make Tarp Sling Bag, else Duct Tape Spear); on any surface (Saw Down
-- Baseball Bat, else Put Eggs in Carton)
S.SLING, S.SPEAR, S.TAPE = "MakeTarpSlingBag", "DuctTapeSpear", "Base.DuctTape"
S.BAT, S.EGGS = "SawDownBaseballBat", "PutEggsInCarton"
S.EGGS_GIVE = {}
for _ = 1, 12 do S.EGGS_GIVE[#S.EGGS_GIVE + 1] = "Base.Egg" end
-- the tools T2 may use: in many recipes as one of a slot's possible items, rarely the first
S.K10_CANDS = { "Base.KitchenKnife", "Base.HuntingKnife", "Base.Screwdriver", "Base.Hammer", "Base.Scissors", "Base.Saw",
    "Base.Pliers", "Base.TinOpener" }
S.CAT_PICKS = 16   -- at most this many of the Category menu's first page (the menu shows 14 before it scrolls)
S.STATS = { "HUNGER", "THIRST", "FATIGUE", "STRESS", "SICKNESS", "FOOD_SICKNESS", "POISON" }
-- (the put-back: hunger or thirst down means he ate or drank; poison, food sickness or sickness up means he was
-- poisoned. Both rise and fall slowly by themselves the other way, so only these directions count)
S.STATS_DOWN, S.STATS_UP = { "HUNGER", "THIRST" }, { "POISON", "FOOD_SICKNESS", "SICKNESS" }
S.CARD_ITEMS = {
    { key = "bleach", ft = "Base.Bleach", name = "the bleach", fluid = true },
    { key = "alcohol", ft = "Base.Disinfectant", name = "the rubbing alcohol (Disinfectant)", fluid = true },
    { key = "petrol", ft = "Base.PetrolCan", name = "the gas can", fluid = true },
    { key = "water", ft = "Base.WaterBottle", name = "the water bottle", fluid = true },
    { key = "shirt", ft = "Base.Tshirt_DefaultTEXTURE_TINT", name = "the T-shirt" },
    { key = "beans", ft = "Base.TinnedBeans", name = "the sealed can of beans" },
    { key = "opener", ft = "Base.TinOpener", name = "the can opener" },
    { key = "apple", ft = "Base.Apple", name = "the apple" },
}
S.WORDS = {
    marks = { fav = "Favorite", nocraft = "Unusable in Recipes", dispose = "Unwanted" },
    markKeys = { fav = "UI_ZeD_Card_ChipFav", nocraft = "UI_ZeD_Card_ChipNoCraft", dispose = "UI_ZeD_Card_ChipDispose" },
    heads = { { "UI_ZeD_Inv_ColCat", "Category" }, { "UI_ZeD_Inv_ColWt", "Weight" }, { "UI_ZeD_Equip_ColWeight", "Weight" },
        { "UI_ZeD_Equip_ColScratch", "Scratch" }, { "UI_ZeD_Equip_ColBullet", "Bullet" } },
    -- (UI_ZeD_Inv_RowHelp is left out: the fix changed it too, but no ZeD code draws it, only ..._RowHelpLoot)
    mouse = { "UI_ZeD_Skills_HelpPin", "UI_ZeD_Lists_HelpLine", "UI_ZeD_Map_HelpMarkGrid",
        "UI_ZeD_Order_HelpRow", "UI_ZeD_Folders_StatusPicked", "UI_ZeD_Folders_DetEmpty", "UI_ZeD_Seps_HelpRow",
        "UI_ZeD_Seps_HelpHeld", "UI_ZeD_Cl_WarHow" },
    -- (K1-13 named these sort-bar words too; the fix left them: NOTE lines, not checks, as they read so on both codes)
    leftAsWas = { "UI_ZeD_Craft_SortFreq", "UI_ZeD_Char_SortDist", "UI_ZeD_Char_SortWt", "UI_ZeD_World_SortDist",
        "UI_ZeD_World_SortWt" },
    tabs = { { "UI_ZeD_Card_MakesHelp", "Crafting or Building tab" }, { "UI_ZeD_Card_MakesMoreHelp", "Crafting tab" },
        { "UI_ZeD_Todo_HelpBack", "Equipment tab" }, { "UI_ZeD_Settings_EquipViewTip", "Equipment tab" },
        { "UI_ZeD_Settings_RestockTip", "Equipment tab" }, { "UI_ZeD_Settings_LoadoutsTip", "Equipment tab" },
        { "UI_ZeD_Options_MootCraftingXP", "Crafting tab" }, { "UI_ZeD_CW_TabHelp", "open its tab" },
        { "UI_ZeD_Curtain_RollHelp", "title bar" }, { "UI_ZeD_Win_HelpPinTabs", "Pin the tabs" },
        { "UI_ZeD_Win_HelpUnpinTabs", "Unpin the tabs" } },
    -- (the add-on ZeD-GUI: Loadouts' keys since the split: left out of the tab check when no Loadouts is loaded)
    tabsAddon = { UI_ZeD_Settings_RestockTip = true, UI_ZeD_Settings_LoadoutsTip = true, UI_ZeD_Todo_HelpBack = true },
    tabsNot = { "Craft tab", "Build tab", "Equip tab", "drawer" },
    bags = { "UI_ZeD_Belt_InBags", "Also on you" },
    tips = { { "UI_ZeD_Options_WheelsTip", "A takes and B closes" }, { "UI_ZeD_Options_MsgNotesTip", "and a click opens Messages" } },
    hand = "By hand",
}
S.dead = false

-- ===================================================================== helpers: time (vx11_craft.lua)
-- cond asked every 100 ms (a UI update), at most ms; fn(true) when cond came true
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
-- every drawn frame: until cond() has held without a break for steadyMs (cond may answer "now": stop at once, fn
-- then gets false), at most ms; fn(ok)
function H.frames(ms, steadyMs, cond, fn)
    local w = {}
    Q.waitFor(1, 4000000, function()
        local now = getTimestampMs()
        w.t0 = w.t0 or now
        local ok, r = pcall(cond)
        if ok and r == "now" then return true end
        if ok and r then
            w.since = w.since or now
            if now - w.since >= steadyMs then w.ok = true; return true end
        else
            w.since = nil
        end
        return now - w.t0 >= ms
    end, function() fn(w.ok == true) end)
end
function H.sec(ms) if type(ms) ~= "number" then return tostring(ms) end; return string.format("%.1f s", ms / 1000) end
function H.q(s) return "\"" .. tostring(s) .. "\"" end
function H.has(s, sub) return string.find(tostring(s or ""), sub, 1, true) ~= nil end
-- a script name without its module ("Base.OpenCannedFood" -> "OpenCannedFood")
function H.bare(s) s = tostring(s or ""); return string.match(s, "([^%.]+)$") or s end
function H.nm(it)
    if it == nil then return "nil" end
    local n = nil
    pcall(function() n = it:getDisplayName() end)
    return tostring(n or it)
end
function H.ft(it)
    local f = nil
    if it then pcall(function() f = it:getFullType() end) end
    return f
end

-- ===================================================================== helpers: the words
-- the game's language, and ZeD's English to read (not the test language)
function H.enWords()
    local nm, L = nil, nil
    local TR = Translator
    if TR and TR.getLanguage then pcall(function() L = TR.getLanguage() end) end
    if L then pcall(function() nm = tostring(L:name()) end) end
    local test = false
    if ZeD.trTestOn then pcall(function() test = ZeD.trTestOn() and true or false end) end
    return nm == "EN" and not test, tostring(nm) .. (test and ", ZeD's test language on" or "")
end
function H.tr(key, a1)
    local s = key
    pcall(function() s = ZeD.tr(key, a1) end)
    return tostring(s)
end
function H.lite()
    local on = false
    pcall(function() on = ZeD.Settings ~= nil and ZeD.Settings.lite ~= nil and ZeD.Settings.lite() and true or false end)
    return on
end

-- ===================================================================== helpers: his state
function H.fed()
    local m = S.p and S.p:getMoodles() or nil
    local lv = nil
    if m and MoodleType and MoodleType.FOOD_EATEN then pcall(function() lv = m:getMoodleLevel(MoodleType.FOOD_EATEN) end) end
    return lv
end
function H.stats()
    local out = {}
    local st = S.p and S.p:getStats() or nil
    for _, k in ipairs(S.STATS) do
        local cs = CharacterStat and CharacterStat[k] or nil
        if st and cs then pcall(function() out[k] = st:get(cs) end) end
    end
    local bd = S.p and S.p:getBodyDamage() or nil
    if bd then
        pcall(function() out.health = bd:getOverallBodyHealth() end)
        pcall(function() out.timer = bd:getHealthFromFoodTimer() end)
    end
    out.fed = H.fed()
    return out
end
function H.num(v) if type(v) ~= "number" then return tostring(v) end; return string.format("%.3f", v) end
-- the game's action queue for him (its list, the queue's own table), or nil
function H.queue()
    local TQ = ISTimedActionQueue
    local q = (TQ and TQ.getTimedActionQueue) and TQ.getTimedActionQueue(S.p) or nil
    return q and q.queue or nil
end
function H.qText(list)
    local out = {}
    for _, a in ipairs(list or {}) do
        if type(a) == "table" then
            local s = tostring(a.Type)
            if a.craftRecipe then pcall(function() s = s .. " (" .. tostring(a.craftRecipe:getName()) .. ")" end)
            elseif a.item then s = s .. " (" .. H.nm(a.item) .. ")" end
            out[#out + 1] = s
        end
    end
    return (#out > 0) and table.concat(out, ", ") or "nothing"
end
-- the eaten-food timer as found (D4's staging undone)
function H.fullBack()
    local F = S.full
    if not F.staged then return end
    F.staged = false
    local bd = S.p and S.p:getBodyDamage() or nil
    if bd and F.was then pcall(function() bd:setHealthFromFoodTimer(F.was) end) end
end
-- the craft search box let go of the keys (a click away from its X takes them on the old code)
function H.unfocusSearch()
    local w = RT.ww()
    local f = w and w._craftSearch or nil
    local inp = f and f.input or nil
    if not inp then return false end
    local foc = false
    pcall(function() foc = inp:isFocused() and true or false end)
    if foc then pcall(function() inp:unfocus() end) end
    return foc
end

-- ===================================================================== helpers: things and the floor (vx11_craft.lua)
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
function H.takeOne(it)
    if not it then return end
    pcall(function() if S.p:getPrimaryHandItem() == it then S.p:setPrimaryHandItem(nil) end end)
    pcall(function() if S.p:getSecondaryHandItem() == it then S.p:setSecondaryHandItem(nil) end end)
    pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
end
function H.mine(it)
    local m = false
    pcall(function() m = it:getModData().ZeDQA_spawned == true end)
    return m
end
function H.where(it)
    local c = nil
    if it then pcall(function() c = it:getContainer() end) end
    if c == nil then return nil end
    local inList = true
    pcall(function() inList = c:getItems():contains(it) end)
    return inList and c or nil
end
function H.floorChanged() local w = RT.ww(); if w then w._containersDirty = true end end
function H.snapFloor(set)
    local cx, cy, cz = math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())
    local cell = getCell()
    if not cell then return end
    for y = cy - 6, cy + 6 do
        for x = cx - 6, cx + 6 do
            local sq = cell:getGridSquare(x, y, cz)
            local wos = sq and sq:getWorldObjects()
            for i = 0, (wos and wos:size() or 0) - 1 do set[wos:get(i)] = true end
        end
    end
end
function H.wobItem(wo) local it = nil; pcall(function() it = wo:getItem() end); return it end
-- whatever the script made that is still carried or beside him: taken away. Only the script's own things (H.mine).
function H.sweep()
    local n = 0
    for _, it in ipairs(H.all()) do
        if not S.had[it] and H.mine(it) then H.takeOne(it); n = n + 1 end
    end
    local now = {}
    H.snapFloor(now)
    for wo in pairs(now) do
        local it = H.wobItem(wo)
        if not S.floorHad[wo] and it and H.mine(it) then
            pcall(function() local sq = wo:getSquare(); if sq then sq:transmitRemoveItemFromSquare(wo) end end)
            pcall(function() wo:removeFromWorld() end)
            pcall(function() wo:removeFromSquare() end)
            n = n + 1
        end
    end
    return n
end

-- ===================================================================== helpers: wrappers (one list, taken off at the end)
-- tbl[key] = fn, the one found kept; group: "craft" or "card"
function H.wrap(tbl, key, fn, group)
    S.wraps[#S.wraps + 1] = { tbl = tbl, key = key, orig = tbl[key], fn = fn, on = true, group = group }
    tbl[key] = fn
end
-- the group's wrappers taken off; false when another hand wrapped one of them since (then it is left, and said)
function H.unwrap(group)
    local ok = true
    for _, w in ipairs(S.wraps) do
        if w.on and (group == nil or w.group == group) then
            if w.tbl[w.key] == w.fn then w.tbl[w.key] = w.orig else ok = false end
            w.on = false
        end
    end
    if group == nil or group == "craft" then S.cwOn = false end
    if group == nil or group == "card" then S.kwOn = false end
    return ok
end
function H.wrapsBack()
    local bad = {}
    for _, w in ipairs(S.wraps) do if w.tbl[w.key] ~= w.orig then bad[#bad + 1] = tostring(w.key) end end
    return #bad == 0, bad
end

-- ===================================================================== helpers: the Crafting tab (vx11_craft.lua)
function H.cst() local w = RT.ww(); return w and w._craftState or nil end
function H.data() local w = RT.ww(); return w and w._craftCache or nil end
function H.geo() local st = H.cst(); return st and st._listGeo or nil end
function H.row(name) local d = H.data(); if not (d and d.byName and name) then return nil end; return d.byName[name] end
function H.entry(name)
    local rd = H.row(name)
    if rd then return rd.entry end
    local d = H.data()
    for _, e in ipairs((d and d.flatRecipes) or {}) do if e.name == name then return e end end
    return nil
end
function H.showing() local s = false; pcall(function() s = S.WW.isTabShowing("craft", S.pn) end); return s and true or false end
function H.tab(id)
    if RT.worldTab(id) then return true end
    return pcall(S.WW.openTab, S.pn, id) and true or false
end
function H.rowH() local h = 24; pcall(function() h = ZeD.T.px(S.CC.ROW_H) end); return h end
function H.zone(kind, pred)
    local st = H.cst()
    for _, z in ipairs((st and st.zones) or {}) do
        if z.type == kind and z.w > 0 and z.h > 0 and (pred == nil or pred(z)) then return z end
    end
    return nil
end
function H.rowZone(name) return H.zone("recipeRow", function(z) return z.id == name end) end
function H.inView(z)
    local g = H.geo()
    return g ~= nil and z ~= nil and z.y >= g.viewY and z.y + z.h <= g.viewY + g.viewH
end
-- a press where a click lands: the tab's own mouse handler, at (x, y) in the tab's coordinates
function H.clickAt(x, y, what)
    local ww = RT.ww()
    if not ww then return false end
    local ok, err = pcall(S.CT.onClick, ww, x, y)
    if not ok then Q.check(false, tostring(what) .. ": the click ran without an error", err) end
    return ok
end
function H.click(z, what) return H.clickAt(z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2), what) end
-- a recipe's card opened as a click on its row does (from code, said, when the row is out of view)
function H.open(name, what)
    local st = H.cst()
    if not st then return false end
    if st.altSlotName then pcall(S.CC.exitAltMode, st) end
    if st.selected == name then return true end
    local z = H.rowZone(name)
    if z and H.inView(z) then
        H.click(z, what)
    else
        local ok, err = pcall(S.CC.openCraft, st, name)
        if not ok then Q.check(false, what .. ": the card opened without an error", err) end
        Q.say("note " .. what .. ": " .. tostring(name) .. " has no row in view, its card is opened from code")
    end
    return st.selected == name
end
function H.shut()
    local st = H.cst()
    if not st then return end
    if st.altSlotName then pcall(S.CC.exitAltMode, st) end
    if st.selected then pcall(S.CC.closeCraft, st) end
end
function H.cardUp(name)
    local st, rd = H.cst(), H.row(name)
    return st ~= nil and rd ~= nil and st.selected == name and rd.ingredients ~= nil and (st.splitFrac or 0) >= 0.99
end
function H.rel(name)
    local st, g, z = H.cst(), H.geo(), H.rowZone(name)
    if not (st and g and z and st.scroll) then return nil end
    local off = math.floor((st.scroll.scrollPos or 0) * math.max(0, (g.totalH or 0) - (g.viewH or 0)))
    return z.y - g.viewY, z, g, off
end
function H.place(name, relT)
    local st = H.cst()
    local rel, _, g, off = H.rel(name)
    if not (rel and st.scroll.setScrollPos) then return false end
    local span = (g.totalH or 0) - (g.viewH or 0)
    if span <= 0 then return true end
    local want = rel + off - relT
    if want < 0 then want = 0 end
    if want > span then want = span end
    st.scroll:setScrollPos((want + 0.5) / span)
    return true
end
function H.mid()
    local g = H.geo()
    if not g then return 0 end
    return math.max(0, math.floor((g.viewH - H.rowH()) / 2))
end
function H.keepState(st)
    return { show = st.show, showAll = st.showAll, sort = st.sort, cat = st.activeCat, req = st.reqCollapsed, out = st.outCollapsed,
        all = st.allCollapsed, owned = st.ownedOnly, search = st.search or "", sel = st.selected, picks = st.picks, qty = st.qty,
        scroll = (st.scroll and st.scroll.scrollPos) or 0, card = (st.cardScroll and st.cardScroll.scrollPos) or 0, alt = st.altSlotName }
end
-- the search: its field and the tab's state set together (the field's own poll then sees no change)
function H.setSearch(st, text)
    local w = RT.ww()
    local f = w and w._craftSearch or nil
    if f and f.input then
        pcall(function() f.input:setText(text) end)
        f._lastText = text
    end
    st.search, st.filterDirty = text, true
end
function H.fieldText()
    local w = RT.ww()
    local f = w and w._craftSearch or nil
    local t = nil
    if f then pcall(function() t = f:getText() end) end
    return t
end
function H.order()
    local st = H.cst()
    local out = {}
    for _, rd in ipairs((st and st.filteredCache) or {}) do if rd.entry then out[#out + 1] = tostring(rd.entry.name) end end
    return out
end
function H.sameOrder(a, b)
    if #a ~= #b then return false end
    for i = 1, #a do if a[i] ~= b[i] then return false end end
    return true
end

-- ===================================================================== helpers: the Crafting tab's drawing, watched
-- ZeD's own drawing, wrapped in memory for Part A. Each wrapper calls ZeD's function with every argument it was
-- handed and returns what it returns.
--   the card (S.cap: c.name, the recipe watched; c.last, its last drawn frame: rows { name, have, need } of the
--     Required section, head (the "n/m" its head is drawn with), texts (every text it hands CC.truncText));
--   the Category menu (S.dd.last: the numbers it draws, in row order, with their y, and its scroll);
--   the band's pop-up boxes' words (S.popSeen, while a list is held there);
--   the selects (S.sel[label] = { v = the value drawn, t = when }).
function H.craftWatchOn()
    if S.cwOn then return true end
    local CC, M, A, ST = S.CC, ZeD.Molecules, ZeD.Atoms, ZeD.Stations
    if not (CC.renderCraftCard and CC.truncText and CC.renderCatDropdownOverlay and M and M.drawSlotRow and M.drawCategoryRow
        and M.drawPopupMenu and A and A.drawTextRight and ST and ST.drawSelect) then return false end
    local o = { card = CC.renderCraftCard, trunc = CC.truncText, dd = CC.renderCatDropdownOverlay, slot = M.drawSlotRow,
        cat = M.drawCategoryRow, pop = M.drawPopupMenu, tr = A.drawTextRight, sel = ST.drawSelect }
    local c, d = S.cap, S.dd
    H.wrap(CC, "renderCraftCard", function(panel, x, y, w, h, state, config, rd, playerObj, ...)
        local mine = c.name ~= nil and state ~= nil and state == c.state and rd ~= nil and rd.entry ~= nil and rd.entry.name == c.name
        if mine then c.cur = { panel = panel, rows = {}, texts = {}, head = nil, inReq = false } else c.cur = nil end
        local r1, r2, r3, r4 = o.card(panel, x, y, w, h, state, config, rd, playerObj, ...)
        if mine and c.cur then c.last = c.cur; c.n = (c.n or 0) + 1 end
        c.cur = nil
        return r1, r2, r3, r4
    end, "craft")
    H.wrap(M, "drawCategoryRow", function(panel, x, y, w, text, count, expanded, opts, ...)
        local cur = c.cur
        if cur and panel == cur.panel then
            if text == S.wReq then cur.inReq = true; cur.head = tostring(count) else cur.inReq = false end
        end
        return o.cat(panel, x, y, w, text, count, expanded, opts, ...)
    end, "craft")
    H.wrap(M, "drawSlotRow", function(panel, x, y, w, data, selected, hovered, opts, ...)
        local cur = c.cur
        if cur and cur.inReq and panel == cur.panel and type(data) == "table" then
            cur.rows[#cur.rows + 1] = { name = tostring(data.displayName or data.name), have = tonumber(data.have) or 0, need = tonumber(data.need) or 1 }
        end
        return o.slot(panel, x, y, w, data, selected, hovered, opts, ...)
    end, "craft")
    H.wrap(CC, "truncText", function(str, font, maxW, ...)
        local cur = c.cur
        if cur then cur.texts[#cur.texts + 1] = tostring(str) end
        return o.trunc(str, font, maxW, ...)
    end, "craft")
    H.wrap(CC, "renderCatDropdownOverlay", function(panel, state, data, ...)
        d.on, d.cur = true, { rows = {} }
        local r1, r2 = o.dd(panel, state, data, ...)
        d.on = false
        if type(state) == "table" then d.cur.scroll = state.catDropdownScroll end
        d.last, d.n, d.cur = d.cur, (d.n or 0) + 1, nil
        return r1, r2
    end, "craft")
    H.wrap(A, "drawTextRight", function(panel, text, x, y, font, color, ...)
        if d.on and d.cur then d.cur.rows[#d.cur.rows + 1] = { text = tostring(text), y = y } end
        return o.tr(panel, text, x, y, font, color, ...)
    end, "craft")
    H.wrap(M, "drawPopupMenu", function(panel, x, y, w, h, label, ...)
        local P = S.popSeen
        if type(P) == "table" and #P < 40 then P[#P + 1] = tostring(label) end
        return o.pop(panel, x, y, w, h, label, ...)
    end, "craft")
    H.wrap(ST, "drawSelect", function(panel, x, y, w, h, label, value, ...)
        S.sel[tostring(label)] = { v = tostring(value), t = getTimestampMs() }
        return o.sel(panel, x, y, w, h, label, value, ...)
    end, "craft")
    S.cwOn = true
    return true
end
function H.capArm(name) local c = S.cap; c.name, c.state, c.last, c.cur, c.n = name, H.cst(), nil, nil, 0 end
function H.capDisarm() local c = S.cap; c.name, c.state, c.cur = nil, nil, nil end
function H.rowsText(last)
    if not last then return "nothing (no frame of the card drawn)" end
    local out = {}
    for _, r in ipairs(last.rows or {}) do
        out[#out + 1] = r.name .. " " .. tostring(r.have) .. "/" .. tostring(r.need) .. ((r.have < r.need) and " (red)" or " (green)")
    end
    return "Required " .. tostring(last.head) .. ": " .. ((#out > 0) and table.concat(out, ", ") or "no rows")
end
function H.lineText(last)
    local bench, surf = false, false
    for _, t in ipairs((last and last.texts) or {}) do
        if t == S.wBench then bench = true end
        if t == S.wSurf then surf = true end
    end
    if bench and surf then return "both the workbench line and the table line" end
    if bench then return "the workbench line " .. H.q(S.wBench) end
    if surf then return "the table line " .. H.q(S.wSurf) end
    return "no line under the rows"
end
-- every row counted by whole items: the Required head drawn "n/n" over all its rows
function H.allCounted(last)
    if not (last and last.head and last.rows and #last.rows > 0) then return false end
    local a, b = string.match(last.head, "^(%d+)/(%d+)$")
    return a ~= nil and a == b and tonumber(b) == #last.rows
end

-- ===================================================================== helpers: K1-7, the game's own reading
-- A HandcraftLogic on the containers in reach, as the game fills it (no bench, no surface): g.can (it would start
-- the craft), g.short (the slots, numbered as ZeD's rows are, it reads short), g.n (slots), g.j (the slot that takes
-- keyFt), g.err. The inputs are filled as the game fills a manual pick (the only way to read each slot).
function H.gameRead(recipeName, keyFt)
    local g = { short = {}, n = 0 }
    local e = H.entry(recipeName)
    local r = e and e.recipe or nil
    if not r then g.err = "no " .. tostring(recipeName) .. " in ZeD's catalog"; return g end
    if not (HandcraftLogic and ResourceType) then g.err = "HandcraftLogic is not there"; return g end
    local sm = getScriptManager and getScriptManager() or nil
    local si = nil
    if sm and keyFt then si = sm:FindItem(keyFt) end
    local ok, err = pcall(function()
        local l = HandcraftLogic.new(S.p, nil, nil)
        local conts = nil
        if S.CC.craftContainers then conts = S.CC.craftContainers(S.p) else conts = S.CC.buildContainers(S.p) end
        l:setContainers(conts)
        l:setRecipe(r)
        g.can = l:canPerformCurrentRecipe() and true or false
        l:setManualSelectInputs(true)
        l:autoPopulateInputs()
        local data = l:getRecipeData()
        local ins = r:getInputs()
        if not ins then return end
        local k = 0
        for i = 0, ins:size() - 1 do
            local inp = ins:get(i)
            if inp and not inp:isAutomationOnly() then
                k = k + 1
                local poss = inp:getPossibleInputItems()
                if si and poss and poss:contains(si) then g.j = k end
                if data and inp:getResourceType() == ResourceType.Item then
                    local dd = data:getDataForInputScript(inp)
                    if dd and not dd:isInputItemsSatisfied() then g.short[#g.short + 1] = k end
                end
            end
        end
        g.n = k
    end)
    if not ok then g.err = tostring(err) end
    return g
end
function H.gameText(g)
    if g.err then return "the game would not answer: " .. g.err end
    local s = {}
    for _, k in ipairs(g.short) do s[#s + 1] = tostring(k) end
    return "the game would start it " .. tostring(g.can) .. ", slots short " .. ((#s > 0) and table.concat(s, ", ") or "none") .. " of " .. tostring(g.n)
end
function H.surfaceNear()
    local o = nil
    if ISEntityUI and ISEntityUI.FindCraftSurface then pcall(function() o = ISEntityUI.FindCraftSurface(S.p, 2) end) end
    return o
end
-- one K1-7 card: T = { choices ({ recipe, give (full types) }: the first the tab lists is used), label, stage (T:
-- returns why, or nil), keyFt, pre (T, g: returns why, or nil), fixed (T, last: true when the frame shows the fix) }.
-- The tab staged (Show All, every category, no search, no card), the things given, the game's reading, the card
-- opened from its row, its drawing watched until the head reads n/n, then until a frame shows the fix (at most
-- 12 s); then the check, the card shut, the things taken back.
function H.queueK7(T)
    Q.step(3, function()
        T.go, T.items = false, {}
        if S.dead or not S.ok then return end
        local st = H.cst()
        if not st then return end
        H.shut()
        pcall(S.CC.setShow, st, "all")
        st.activeCat, st.reqCollapsed, st.allCollapsed, st.filterDirty, st._sectionsStale = "all", false, false, true, true
        H.setSearch(st, "")
        local names = {}
        for _, ch in ipairs(T.choices) do
            names[#names + 1] = ch.recipe
            if not T.recipe and H.row(ch.recipe) then T.recipe, T.give = ch.recipe, ch.give end
        end
        if not T.recipe then Q.skip(T.label, "the Crafting tab lists none of " .. table.concat(names, ", ") .. " here"); return end
        for _, ft in ipairs(T.give) do
            local it = RT.give(ft)
            if not it then Q.check(false, T.label .. " (staging)", ft .. " could not be given"); return end
            T.items[#T.items + 1] = it
        end
        local why = T.stage and T.stage(T) or nil
        if why then Q.check(false, T.label .. " (staging)", why); return end
        H.floorChanged()
        T.go = true
    end)
    Q.step(5, function()
        if not T.go then return end
        T.g = H.gameRead(T.recipe, T.keyFt)
        local why = T.pre(T, T.g)
        if why then T.go = false; Q.skip(T.label, why); return end
        Q.say(T.recipe .. ": " .. H.gameText(T.g) .. "; its card opened from its row")
        H.place(T.recipe, H.mid())
    end)
    Q.step(3, function() if T.go then H.open(T.recipe, T.recipe) end end)
    H.wait(6000, function() return not T.go or H.cardUp(T.recipe) end, function(ok)
        if not T.go then return end
        if not ok then
            T.go = false
            local st = H.cst()
            Q.check(false, T.label .. " (staging)", "its card did not open from its row (the open card: " .. tostring(st and st.selected) .. ")")
            return
        end
        H.capArm(T.recipe)
    end)
    H.frames(12000, 0, function()
        if not T.go then return "now" end
        local last = S.cap.last
        if not last then return false end
        if not T.gateAt and H.allCounted(last) then T.gateAt = getTimestampMs() end
        if T.gateAt and T.fixed(T, last) then T.match = last; return "now" end
        return false
    end, function()
        if not T.go then return end
        local last = T.match or S.cap.last
        local how
        if not T.gateAt then how = "the head never read n/n in 12 s (the rows were not all counted): the case was not reached"
        elseif T.match then how = "shown " .. H.sec(getTimestampMs() - T.gateAt) .. " after the rows were all counted"
        else how = "not shown in the " .. H.sec(getTimestampMs() - T.gateAt) .. " after the rows were all counted" end
        Q.check(T.match ~= nil, T.label, H.rowsText(last) .. "; " .. H.lineText(last) .. " (" .. tostring(S.cap.n) .. " frames of the card drawn); " .. how)
    end)
    Q.step(3, function()
        H.capDisarm()
        H.shut()
        for _, it in ipairs(T.items or {}) do H.takeOne(it) end
        H.floorChanged()
    end)
end

-- ===================================================================== helpers: K1-10
-- the old search's rule (staging only: to pick a tool that exercises the fix): the name, the category, each slot's
-- first item, each output
function H.oldMatch(e, low)
    if H.has(string.lower(tostring(e.displayName or "")), low) then return true end
    if H.has(string.lower(tostring(e.category or "")), low) then return true end
    for _, inp in ipairs(e.inputDefs or {}) do if H.has(string.lower(tostring(inp.name or "")), low) then return true end end
    for _, od in ipairs(e.outputDefs or {}) do if H.has(string.lower(tostring(od.name or "")), low) then return true end end
    return false
end
-- each candidate tool: the recipes of the tab with a slot whose possible items hold it (the game's script items),
-- and how many of them the old rule misses; the one with the most misses (then the most recipes), or nil and why
function H.k10Pick()
    local d = H.data()
    if not (d and d.recipes) then return nil, "the Crafting tab has no rows" end
    local sm = getScriptManager and getScriptManager() or nil
    if not sm then return nil, "the game's script manager is not there" end
    local cands = {}
    for _, ft in ipairs(S.K10_CANDS) do
        local si = sm:FindItem(ft)
        local nm = nil
        if si then pcall(function() nm = si:getDisplayName() end) end
        if si and nm and tostring(nm) ~= "" then
            cands[#cands + 1] = { ft = ft, si = si, name = tostring(nm), low = string.lower(tostring(nm)), E = {}, nE = 0, miss = 0, missNames = {} }
        end
    end
    if #cands == 0 then return nil, "none of the tools is in the game's scripts" end
    for _, rd in ipairs(d.recipes) do
        local e = rd.entry
        local r = e and e.recipe or nil
        if r and e.name then
            pcall(function()
                local ins = r:getInputs()
                if not ins then return end
                for i = 0, ins:size() - 1 do
                    local inp = ins:get(i)
                    if inp and not inp:isAutomationOnly() then
                        local poss = inp:getPossibleInputItems()
                        if poss then
                            for _, c in ipairs(cands) do
                                if not c.E[e.name] and poss:contains(c.si) then
                                    c.E[e.name] = e
                                    c.nE = c.nE + 1
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
    local best, most = nil, nil
    for _, c in ipairs(cands) do
        for _, e in pairs(c.E) do
            if not H.oldMatch(e, c.low) then
                c.miss = c.miss + 1
                if #c.missNames < 4 then c.missNames[#c.missNames + 1] = tostring(e.displayName) end
            end
        end
        if c.miss > 0 and (best == nil or c.miss > best.miss or (c.miss == best.miss and c.nE > best.nE)) then best = c end
        if most == nil or c.nE > most.nE then most = c end
    end
    local said = {}
    for _, c in ipairs(cands) do said[#said + 1] = c.name .. " " .. c.nE .. "/" .. c.miss end
    S.k10.candText = table.concat(said, ", ")
    if best then return best, nil, nil end
    -- (no miss anywhere: T1 and T3 still run on the tool with the most recipes; only T2 has no case)
    return most, nil, "no tool here has a recipe the old search would miss (recipes / missed: " .. S.k10.candText .. ")"
end
-- the category (not All) holding the fewest of the tool's recipes
function H.k10Cat(c)
    local st = H.cst()
    local best, bestN = nil, nil
    for _, cat in ipairs((st and st.categoryList) or {}) do
        if cat.id ~= "all" then
            local n = 0
            for _, e in pairs(c.E) do if string.lower(tostring(e.category)) == cat.id then n = n + 1 end end
            if bestN == nil or n < bestN then best, bestN = cat, n end
        end
    end
    return best, bestN
end

-- ===================================================================== helpers: K1-12, one category picked
-- the Category menu opened by a click on its select; its drawn numbers read; row k clicked where it sits; the list
-- followed; its rows counted
function H.queueCatPick(k)
    local T = {}
    Q.step(1, function()
        local K = S.k12
        T.go = K.go == true and (k == 1 or k <= K.n)
        if not T.go then return end
        local z = H.zone("catDropdown")
        if not z then T.go = false; K.go = false; Q.check(false, "K1-12 (staging): the Category select is on the tab"); return end
        T.n0 = S.dd.n or 0
        H.click(z, "K1-12, the Category select")
    end)
    H.frames(3000, 0, function()
        if not T.go then return "now" end
        local st = H.cst()
        return st ~= nil and st.catDropdownOpen == true and (S.dd.n or 0) > (T.n0 or 0) and S.dd.last ~= nil
    end, function(ok)
        if not T.go then return end
        local K, st = S.k12, H.cst()
        if not ok then T.go = false; K.go = false; Q.check(false, "K1-12 (staging): the Category menu opens and draws", "not in 3 s (row " .. k .. ")"); return end
        local rows = S.dd.last.rows or {}
        local scroll = S.dd.last.scroll or 0
        local cats = st.categoryList or {}
        if k == 1 then
            K.n = math.min(#rows, math.min(#cats, S.CAT_PICKS))
            K.total = #cats
            if #rows >= 2 then K.rowH = rows[2].y - rows[1].y end
        end
        local cat, r, g = cats[k], rows[k - scroll], st._ddGeo
        if not (cat and r and g and K.rowH and K.rowH > 0) then
            T.go = false
            K.why[k] = "row " .. k .. " not drawn (" .. #rows .. " rows drawn, scrolled " .. tostring(scroll) .. ")"
            pcall(function() st.catDropdownOpen = false end)
            return
        end
        K.ids[k], K.drawn[k], K.catalog[k] = cat.id, r.text, cat.count
        K.labels[k] = tostring(cat.full or cat.label or cat.id)
        pcall(function() K.labels[k] = S.CC.categoryLabel(cat.full or cat.label or cat.id) end)
        H.clickAt(g.x + math.floor(g.w / 2), g.y + (k - 1 - scroll) * K.rowH + math.floor(K.rowH / 2), "K1-12, the Category menu's row " .. k)
    end)
    H.wait(3000, function()
        if not T.go then return true end
        local st = H.cst()
        return st ~= nil and st.catDropdownOpen == false and st.activeCat == S.k12.ids[k] and st.filterDirty == false
    end, function(ok)
        if not T.go then return end
        local st = H.cst()
        if ok then S.k12.shown[k] = #((st and st.filteredCache) or {})
        else S.k12.why[k] = "the list did not follow the pick in 3 s (its category " .. tostring(st and st.activeCat) .. ")" end
    end)
end

-- ===================================================================== helpers: the Character window's list (vx10_food.lua)
function H.content() local w = RT.cw(); return w and w._mainContent or nil end
function H.cardObj() local w = RT.cw(); return w and w._itemCard or nil end
function H.cardOn(item)
    local w = RT.cw()
    local c = w and w._itemCard or nil
    return item ~= nil and w ~= nil and w._drawerItem == item and c ~= nil and c.item == item
end
function H.invZone(item)
    local c = H.content()
    for _, z in ipairs((c and c._hitZones) or {}) do if z.id == item then return z end end
    return nil
end
-- the row drawn last frame stands whole in the list's view and a click at its middle lands on it
function H.rowShown(item)
    local c, z = H.content(), H.invZone(item)
    if not (c and z) then return false end
    local rv = c._rowView
    local grid = c._gv ~= nil and c._gv.on == true
    if not grid and not (rv and rv.top and rv.bottom and z.y >= rv.top and z.y + z.h <= rv.bottom) then return false end
    local hit = nil
    pcall(function() hit = c:hitZoneAt(z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)) end)
    return hit == z
end
-- (a condition, every 100 ms: the row shown whole, else the list one step further down; wraps at the end. The step is
-- at most half a view, so every row stands whole at one of them)
function H.seekRow(item)
    local c = H.content()
    if not c then return false end
    if H.rowShown(item) then return true end
    local sc = c._scroll
    if sc and sc.setScrollPos then
        local r = tonumber(sc.barSizeRatio) or 1
        local step = 0.1
        if r > 0 and r < 1 then step = math.max(0.01, math.min(0.1, 0.5 * r / (1 - r))) end
        local at = S.seekPos
        if at == nil or at >= 1 then at = 0 else at = math.min(1, at + step) end
        S.seekPos = at
        pcall(function() sc:setScrollPos(at) end)
    end
    return false
end
-- a plain click on the row, down and up at its middle; never the second of a double-click (that would use it)
function H.invClick(item)
    local c = H.content()
    local z = H.invZone(item)
    if not (c and z) then return false end
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    c._zedLastClick = nil
    local ok, err = pcall(function() c:onMouseDown(x, y); c:onMouseUp(x, y) end)
    c._zedLastClick = nil
    if not ok then Q.check(false, H.nm(item) .. ": the click on its row ran without an error", tostring(err)) end
    return ok
end
function H.pressCharTab(id)
    local w = RT.cw()
    local strip = w and w._tabStripPanel or nil
    for _, z in ipairs((strip and strip._hitZones) or {}) do
        if z.id == "tab:" .. id then
            pcall(function() strip:onMouseDown(z.x + 2, z.y + 2) end)
            return true
        end
    end
    return false
end
-- the list as found: stacks, folds, selection, scroll, columns, the window's tab (once)
function H.listBack()
    if S.listBackDone or not S.listTouched then return end
    S.listBackDone = true
    local c = H.content()
    if c then
        pcall(function()
            if c._expandedStacks then for ft, was in pairs(S.stackWas) do c._expandedStacks[ft] = was or nil end end
        end)
        c._zedLastClick = nil
        c._selectedItems = {}
        c._lastClickedItem = nil
        if S.scrollWas and c._scroll and c._scroll.setScrollPos then pcall(function() c._scroll:setScrollPos(S.scrollWas) end) end
    end
    if S.foldsOf then for _, k in ipairs(S.folds) do S.foldsOf[k] = true end end
    for _, inv in ipairs(S.cols) do pcall(ZeD_CharacterWindow.toggleColumn, inv, S.pn) end
    local w = RT.cw()
    if w and S.was.charTab and w._activeTab ~= S.was.charTab then pcall(RT.charTab, S.was.charTab) end
end

-- ===================================================================== helpers: the item card's drawing, watched
-- ZeD_ItemCard.renderBody wrapped for Part B: for the Character window's card (S.card.obj) drawing the thing wanted
-- (S.card.want), the verbs it drew this frame (its _lastHeaderVerbs: id, the button's word, main, grayed, help line)
-- and the marks' words it handed ZeD.Atoms.drawFlagChip: S.card.last = { item, verbs, chips, t }
function H.cardWatchOn()
    if S.kwOn then return true end
    if not (ZeD_ItemCard and ZeD_ItemCard.renderBody and ZeD.Atoms and ZeD.Atoms.drawFlagChip) then return false end
    local o = { body = ZeD_ItemCard.renderBody, chip = ZeD.Atoms.drawFlagChip }
    local K = S.card
    H.wrap(ZeD_ItemCard, "renderBody", function(self, ctx, ...)
        local mine = K.obj ~= nil and self == K.obj
        if mine then K.inBody, K.chipsCur = true, {} end
        local r1, r2, r3, r4 = o.body(self, ctx, ...)
        if mine then
            K.inBody = false
            local it = self.item
            if it ~= nil and it == K.want then
                local vs = {}
                for i, v in ipairs(self._lastHeaderVerbs or {}) do
                    if type(v) == "table" then
                        vs[i] = { id = v.id, label = v.label, primary = v.primary and true or false, disabled = v.disabled and true or false, help = v.help }
                    end
                end
                K.last = { item = it, verbs = vs, chips = K.chipsCur or {}, t = getTimestampMs() }
            end
            K.chipsCur = nil
        end
        return r1, r2, r3, r4
    end, "card")
    H.wrap(ZeD.Atoms, "drawFlagChip", function(panel, x, y, kind, on, glyph, label, outRect, compact, opts, ...)
        if K.inBody and K.chipsCur and panel == K.obj then
            K.chipsCur[#K.chipsCur + 1] = { kind = tostring(kind), label = tostring(label), compact = compact and true or false }
        end
        return o.chip(panel, x, y, kind, on, glyph, label, outRect, compact, opts, ...)
    end, "card")
    S.kwOn = true
    return true
end
function H.verbsText(rec)
    if not rec then return "nothing (no frame of its card read)" end
    local out = {}
    for _, v in ipairs(rec.verbs or {}) do
        out[#out + 1] = tostring(v.label) .. (v.primary and " (main)" or "") .. (v.disabled and " (grayed)" or "")
    end
    return (#out > 0) and table.concat(out, ", ") or "no verbs"
end
function H.verb(rec, id)
    for _, v in ipairs((rec and rec.verbs) or {}) do if v.id == id then return v end end
    return nil
end
function H.primary(rec)
    for _, v in ipairs((rec and rec.verbs) or {}) do if v.primary then return v end end
    return nil
end
-- the card of one thing given (S.cards[key].item) opened as a click on its row opens it, then a frame of the card
-- drawn for it read into S.cards[key].rec. minT (optional): a time the frame must be drawn after; need (optional):
-- the read runs only while it answers true.
function H.queueCard(key, label, minT, need)
    local T = {}
    Q.step(2, function()
        local C = S.cards[key]
        T.go = S.bOk == true and not S.dead and C ~= nil and C.item ~= nil and (need == nil or need())
        if not T.go then return end
        C.rec = nil
        S.card.want, S.card.last, S.card.obj = C.item, nil, H.cardObj()
        S.seekPos = nil
    end)
    H.wait(10000, function() return not T.go or H.seekRow(S.cards[key].item) end, function(ok)
        if not T.go then return end
        if not ok then
            T.go = false
            Q.check(false, label .. ": its row stands whole in the Character window's list, where a click lands on it (staging)", H.nm(S.cards[key].item))
            return
        end
        T.t0 = getTimestampMs()
        if not H.invClick(S.cards[key].item) then T.go = false end
    end)
    H.wait(5000, function()
        if not T.go then return true end
        local it, K = S.cards[key].item, S.card
        local after = T.t0 or 0
        local m = minT and minT() or nil
        if m and m > after then after = m end
        return H.cardOn(it) and K.last ~= nil and K.last.item == it and (K.last.t or 0) > after
    end, function(ok)
        if not T.go then return end
        if ok then S.cards[key].rec = S.card.last; return end
        local w = RT.cw()
        local c = w and w._itemCard or nil
        Q.check(false, label .. ": a click on its row opens its item card, drawn (staging)", "the card shows " .. H.nm(c and c.item) .. ", the drawer holds " .. H.nm(w and w._drawerItem))
    end)
end

-- ===================================================================== setup
Q.step(2, function()
    S.dead = (S.p == nil) or S.p:isDead()
    if S.dead then Q.check(false, "the character is alive (nothing is run on a dead one)"); return end
    if not (S.CC and S.CT and S.WW and ZeD.Molecules and ZeD.Atoms and ZeD.Stations and ZeD.ItemCard and ZeD.ItemCard.verbText
        and ZeD_ItemCard and ZeD.InventoryRenderer and ZeD_CharacterWindow) then
        S.dead = true
        Q.check(false, "ZeD's Crafting tab, item card and inventory list are loaded")
        return
    end
    if ZEDQA_HOME then ZEDQA_HOME("vk1_cc") end
    for _, it in ipairs(H.all()) do S.had[it] = true end
    H.snapFloor(S.floorHad)
    pcall(function() S.dirWas = S.p:getDir() end)
    S.was.stats = H.stats()
    S.pairWas = RT.isOpen()
    RT.pairOpen()
    local w, cw = RT.ww(), RT.cw()
    if w then
        S.tabWas = w._activeTab
        -- (the tab's state as found, before a station's unbinding resets its category and scroll)
        if w._craftState then S.keep = H.keepState(w._craftState) end
    end
    if cw then S.was.charTab = cw._activeTab end
    pcall(function()
        local cur = ZeD.Stations.current(S.p)
        if cur then
            S.stWas = cur
            ZeD.Stations.unbind(S.p)
            Q.say("note a station was bound: unbound for the run (the hand's recipes), bound again at the end")
        end
    end)
    local list = H.queue()
    S.was.queue = list and #list or nil
    S.en, S.lang = H.enWords()
    S.wReq = H.tr("UI_ZeD_Craft_Required")
    S.wStation = H.tr("UI_ZeD_Station_SelectLabel")
    S.wCat = H.tr("IGUI_invpanel_Category")
    S.wBench = H.tr("UI_ZeD_Craft_NeedsBench")
    S.wSurf = H.tr("UI_ZeD_Craft_NeedsSurface")
    if S.wSurf == "UI_ZeD_Craft_NeedsSurface" then S.wSurf = "Needs a table or counter nearby." end   -- (the fix's own stand-in)
    S.wRecent = H.tr("UI_ZeD_Craft_SortRecent")
    S.wSortPick = H.tr("UI_ZeD_Craft_SortPick", "")
    S.wAll = "All"
    pcall(function() S.wAll = tostring(S.CC.categoryLabel("All")) end)
    S.wCantEat = tostring(getText("Tooltip_CantEatMore"))
    S.vtWear, S.vtEquip = tostring(ZeD.ItemCard.verbText("WEAR")), tostring(ZeD.ItemCard.verbText("EQUIP"))
    local s = S.was.stats
    Q.say("setup: screen " .. tostring(getCore():getScreenWidth()) .. "x" .. tostring(getCore():getScreenHeight()) .. ", the World window on "
        .. tostring(S.tabWas) .. ", the Character window on " .. tostring(S.was.charTab) .. ", the pair was open " .. tostring(S.pairWas)
        .. "; language " .. tostring(S.lang) .. "; queued " .. tostring(S.was.queue) .. "; hunger " .. H.num(s.HUNGER) .. ", thirst " .. H.num(s.THIRST)
        .. ", Well Fed " .. tostring(s.fed) .. ", eaten-food timer " .. H.num(s.timer) .. ", health " .. H.num(s.health))
end)

-- ===================================================================== K1-13: the UI's words
Q.step(2, function()
    if S.dead then return end
    local W = S.WORDS
    if not S.en then
        Q.skip("K1-13: the UI's words (list heads, help lines, tab names, the pad's bag heading, setup tips)",
            "the game is not in ZeD's English (" .. tostring(S.lang) .. "): the words checked are ZeD's English")
        return
    end
    local parts, bad = {}, 0
    for _, kv in ipairs(W.heads) do
        local s = H.tr(kv[1])
        if s ~= kv[2] then bad = bad + 1 end
        parts[#parts + 1] = kv[1] .. " " .. H.q(s)
    end
    Q.check(bad == 0, "K1-13: the list heads read whole words, Category, Weight, Weight, Scratch, Bullet (the inventory list's Category and Weight, the Equipment tab's Weight, Scratch and Bullet; old code: Cat, Wt, Wt, Scr, Bul)",
        table.concat(parts, ", "))
    local L0, L1 = tostring(getText("IGUI_mouse_btn_0")), tostring(getText("IGUI_mouse_btn_1"))
    parts, bad = {}, 0
    for _, k in ipairs(W.mouse) do
        local s = H.tr(k)
        local stale = H.has(s, "LMB") or H.has(s, "RMB")
        local game = H.has(s, L0) or H.has(s, L1)
        if stale or not game then bad = bad + 1; parts[#parts + 1] = k .. " " .. H.q(s) end
    end
    Q.check(bad == 0, "K1-13: the help lines that name a mouse button say the game's " .. L0 .. " and " .. L1 .. ", never LMB or RMB (" .. #W.mouse
        .. " lines; old code: LMB and RMB)", (bad == 0) and ("all " .. #W.mouse .. " read so, e.g. UI_ZeD_Map_HelpMarkGrid " .. H.q(H.tr("UI_ZeD_Map_HelpMarkGrid"))) or table.concat(parts, "; "))
    parts, bad = {}, 0
    -- (the Loadouts split: no Loadouts loaded, built in or the add-on, leaves its three keys out of the check)
    local noLo = ZeD.Lists == nil
    local nT, leftOut = 0, {}
    for _, kv in ipairs(W.tabs) do
        if noLo and W.tabsAddon[kv[1]] then
            leftOut[#leftOut + 1] = kv[1]
        else
            nT = nT + 1
            local s = H.tr(kv[1])
            local stale = nil
            for _, o in ipairs(W.tabsNot) do if H.has(s, o) then stale = o end end
            if stale or not H.has(s, kv[2]) then
                bad = bad + 1
                parts[#parts + 1] = kv[1] .. " " .. H.q(s) .. (stale and (" (says " .. H.q(stale) .. ")") or (" (no " .. H.q(kv[2]) .. ")"))
            end
        end
    end
    if #leftOut > 0 then Q.say("NOTE K1-13: left out, ZeD-GUI: Loadouts' words with no Loadouts loaded: " .. table.concat(leftOut, ", ")) end
    Q.check(bad == 0, "K1-13: the help lines name the tabs by their own names (Crafting, Building, Equipment), the tab strip's help says press to open its tab, and none speaks of a drawer ("
        .. nT .. " lines; old code: Craft or Build tab, Equip tab, show it in the drawer, the tab drawer)",
        (bad == 0) and ("all " .. nT .. " read so, e.g. UI_ZeD_Card_MakesHelp " .. H.q(H.tr("UI_ZeD_Card_MakesHelp")) .. ", UI_ZeD_CW_TabHelp " .. H.q(H.tr("UI_ZeD_CW_TabHelp"))) or table.concat(parts, "; "))
    local bags = H.tr(W.bags[1])
    Q.check(bags == W.bags[2], "K1-13: the pad's In your bags heading (the belt's list of what else he carries) reads Also on you (old code: In your bags)",
        W.bags[1] .. " " .. H.q(bags))
    parts, bad = {}, 0
    for _, kv in ipairs(W.tips) do
        local s = H.tr(kv[1])
        if not H.has(s, kv[2]) then bad = bad + 1 end
        parts[#parts + 1] = kv[1] .. " " .. H.q(s)
    end
    Q.check(bad == 0, "K1-13: ZeD setup's Wheels and Other mods' notes tips read as plain sentences, A takes and B closes, and a click opens Messages (old code: A takes, B closes; click it to open Messages)",
        table.concat(parts, "; "))
    -- (the gaps, said in the run: the sort bars' words K1-13 named and the fix left; what needs a bench or the pointer)
    parts = {}
    for _, k in ipairs(W.leftAsWas) do parts[#parts + 1] = k .. " " .. H.q(H.tr(k)) end
    Q.say("NOTE K1-13 (not a check, the fix left them): " .. table.concat(parts, ", "))
    Q.say("NOTE K1-13 / K1-7 (not checked here): the marks' hover help lines need the real pointer; the workbench line on a bound bench reads as on the old code")
end)

-- ===================================================================== A. the Crafting tab
Q.step(3, function()
    if S.dead then return end
    local w = RT.ww()
    if S.tabWas == nil and w then S.tabWas = w._activeTab end
    H.tab("craft")
end)
H.wait(8000, function()
    if S.dead then return true end
    local st = H.cst()
    return H.showing() and st ~= nil and H.data() ~= nil and st.filteredCache ~= nil
end, function(ok)
    if S.dead then return end
    S.ok = ok
    if not ok then Q.check(false, "the World window's Crafting tab opens with its list (staging)", "showing " .. tostring(H.showing())); return end
    local st = H.cst()
    S.craftSeen = true
    S.keep = S.keep or H.keepState(st)
    if S.keep.alt then Q.say("note the tab was found in an ingredient's alternatives list: left for the recipe list, and not put back") end
    H.shut()
    pcall(S.CC.setShow, st, "all")
    st.sort, st.activeCat, st.allCollapsed, st.reqCollapsed, st.outCollapsed, st.filterDirty = "craftable", "all", false, false, false, true
    st._sectionsStale = true
    st.sortMenuOpen, st.showMenuOpen, st.catDropdownOpen, st.stDropdownOpen = false, false, false, false
    local typed = H.fieldText() or ""
    if typed ~= "" or (st.search or "") ~= "" then
        S.searchWas = true
        H.setSearch(st, "")
        Q.say("note a search was typed (the field " .. H.q(typed) .. ", the list's " .. H.q(S.keep.search) .. "): emptied for the run, set back at the end")
    end
    S.searchTouched = true
    if not H.craftWatchOn() then S.ok = false; Q.check(false, "ZeD's Crafting tab drawing can be watched (staging): a drawing function is missing"); return end
    S.selT0 = getTimestampMs()
end)
-- K1-13: the Station select, drawn with no station bound
H.wait(6000, function()
    if not S.ok then return true end
    local st = H.cst()
    local v = S.sel[S.wStation]
    return st ~= nil and st.filterDirty == false and v ~= nil and v.t > (S.selT0 or 0)
end, function(ok)
    if not S.ok then return end
    local label = "K1-13: with no station bound, the Crafting tab's Station select reads By hand (old code: Hand)"
    if not S.en then Q.skip(label, "the game is not in ZeD's English (" .. tostring(S.lang) .. ")"); return end
    local v = S.sel[S.wStation]
    local cur = nil
    pcall(function() cur = ZeD.Stations.current(S.p) end)
    if cur then Q.skip(label, "a station is bound (" .. tostring(cur.name) .. "): the select names it"); return end
    -- (QA, Nov 22: K3 #48, the director's pick, shows the Station box only when a station is in reach, so with none the
    -- select is not drawn at all; the K1-13 wording is then moot)
    if v == nil then
        local near = nil
        pcall(function() near = ZeD.Stations.nearby(S.p) end)
        if not (near and #near > 0) then Q.skip(label, "no station in reach: K3 #48 draws no Station box"); return end
    end
    Q.check(ok and v ~= nil and v.v == S.WORDS.hand, label, "the select " .. H.q(S.wStation) .. " is drawn reading " .. H.q(v and v.v) .. (ok and "" or " (no frame drawn in 6 s)"))
end)

-- ===================================================================== K1-12: the Category menu's numbers
Q.step(3, function()
    local K = S.k12
    K.go = false
    local st = H.cst()
    if not (S.ok and st) then return end
    H.shut()
    st.activeCat, st.catDropdownOpen, st.catDropdownScroll, st.sortMenuOpen, st.showMenuOpen, st.stDropdownOpen = "all", false, 0, false, false, false
    pcall(S.CC.setShow, st, "ready")
    st.filterDirty = true
    K.go = true
end)
H.wait(4000, function()
    local st = H.cst()
    return not S.k12.go or (st ~= nil and st.filterDirty == false and st.activeCat == "all")
end, function(ok)
    local K = S.k12
    if not K.go then return end
    if not ok then K.go = false; Q.check(false, "K1-12 (staging): the list filters again under Show: Ready", "not in 4 s"); return end
    Q.say("K1-12: Show: Ready, every category: the list holds " .. #((H.cst() or {}).filteredCache or {}) .. " rows")
end)
for k = 1, S.CAT_PICKS do H.queueCatPick(k) end
Q.step(1, function()
    local K = S.k12
    if not (K.go and K.n and K.n > 0) then return end
    local parts, bad, unread, oldDiff = {}, 0, 0, 0
    for k = 1, K.n do
        local d, s = tonumber(K.drawn[k]), K.shown[k]
        if d == nil or s == nil then
            unread = unread + 1
            parts[#parts + 1] = tostring(K.labels[k] or ("row " .. k)) .. " not read (" .. tostring(K.why[k]) .. ")"
        else
            if d ~= s then bad = bad + 1 end
            if K.catalog[k] ~= nil and K.catalog[k] ~= s then oldDiff = oldDiff + 1 end
            parts[#parts + 1] = tostring(K.labels[k]) .. " " .. tostring(K.drawn[k]) .. "/" .. tostring(s) .. ((d ~= s) and " (differs)" or "")
                .. " [catalog " .. tostring(K.catalog[k]) .. "]"
        end
    end
    Q.check(unread == 0 and bad == 0, "K1-12: under Show: Ready the Category menu's number beside each category is the rows the list holds once that category is clicked (the menu's first page, "
        .. K.n .. " of " .. tostring(K.total) .. " rows; old code: the catalog's total)",
        "drawn / listed: " .. table.concat(parts, ", ") .. "; the catalog's totals (what the old menu drew) differ from the list for " .. oldDiff .. " of them")
end)

-- ===================================================================== K1-12: Sort has no Recent
Q.step(2, function()
    local P = S.k12s
    P.go = false
    local st = H.cst()
    if not (S.ok and st) then return end
    st.activeCat, st.catDropdownOpen, st.filterDirty = "all", false, true
    pcall(S.CC.setShow, st, "all")
    st.sort = "craftable"
    local z = H.zone("sortMenu")
    if not z then Q.check(false, "K1-12: Sort offers no Recent (staging)", "the Sort box is not on the tab"); return end
    H.click(z, "K1-12, the Sort box")
    P.go = true
end)
H.frames(3000, 0, function()
    if not S.k12s.go then return "now" end
    local st = H.cst()
    return st ~= nil and st.sortMenuOpen == true and type(st._sortMenuZones) == "table" and #st._sortMenuZones > 0
end, function(ok)
    local P = S.k12s
    if not P.go then return end
    local st = H.cst()
    local label = "K1-12: Sort, opened by a click on its box, offers no Recent (old code: Recent, which ordered exactly as Freq)"
    if not ok then Q.check(false, label, "the Sort list did not open and draw in 3 s"); return end
    local ids, words, recent = {}, {}, false
    for _, z in ipairs(st._sortMenuZones or {}) do
        ids[#ids + 1] = tostring(z.id)
        if z.id == "recent" then recent = true end
    end
    local g = st._sortMenuGeo
    for _, m in ipairs((g and g.modes) or {}) do
        words[#words + 1] = tostring(m.label)
        if m.id == "recent" or m.label == S.wRecent then recent = true end
    end
    Q.check(#ids >= 3 and not recent, label, "its choices " .. table.concat(ids, ", ") .. " (" .. table.concat(words, ", ") .. ")")
    -- shut by a click away from it, as a player's does
    H.clickAt(-5, -5, "K1-12, a click away from the Sort list")
end)
-- (a NOTE, not a check: nothing in ZeD saves the Sort, so a held "recent" reaches no player, and the order under it
-- was Freq's on the old code too)
Q.step(2, function()
    local N = S.k12n
    N.go = false
    local st = H.cst()
    if not (S.ok and st) then return end
    if st.sortMenuOpen then pcall(S.CC.closePopMenu, st, "sort") end
    st.sort, st.filterDirty = "recent", true
    N.go = true
end)
H.wait(3000, function() local st = H.cst(); return not S.k12n.go or (st ~= nil and st.filterDirty == false) end, function()
    local N = S.k12n
    if not N.go then return end
    N.orderR = H.order()
    S.popSeen = {}
end)
H.frames(1500, 0, function() return not S.k12n.go or #(S.popSeen or {}) >= 2 end, function()
    local N = S.k12n
    if not N.go then S.popSeen = nil; return end
    for _, l in ipairs(S.popSeen or {}) do
        if S.wSortPick ~= "" and string.sub(l, 1, #S.wSortPick) == S.wSortPick then N.box = l end
    end
    S.popSeen = nil
    local st = H.cst()
    if st then st.sort, st.filterDirty = "freq", true end
end)
H.wait(3000, function() local st = H.cst(); return not S.k12n.go or (st ~= nil and st.filterDirty == false) end, function()
    local N = S.k12n
    if not N.go then return end
    local orderF = H.order()
    Q.say("NOTE K1-12 (not a check): with a held sort of \"recent\" the Sort box reads " .. H.q(N.box) .. " and the list's order is Freq's: "
        .. tostring(H.sameOrder(N.orderR or {}, orderF)) .. " (" .. #(N.orderR or {}) .. " rows)")
    local st = H.cst()
    if st then st.sort, st.filterDirty = "craftable", true end
end)

-- ===================================================================== K1-10: an item's Craft
Q.step(3, function()
    local X = S.k10
    X.go = false
    local st = H.cst()
    if not (S.ok and st) then return end
    H.shut()
    pcall(S.CC.setShow, st, "all")
    st.activeCat, st.sort = "all", "craftable"
    H.setSearch(st, "")
    local t0 = getTimestampMs()
    local c, why, t2why = H.k10Pick()
    if not c then Q.skip("K1-10: an item's Craft (category, every recipe the tool fits, the clear X)", why); return end
    local cat, n = H.k10Cat(c)
    if not cat then Q.skip("K1-10: an item's Craft", "the tab has no category but All"); return end
    X.c, X.cat, X.catN, X.t2why = c, cat, n, t2why
    st.activeCat, st.filterDirty = cat.id, true
    X.go = true
    Q.say("K1-10: the tool " .. c.name .. " (" .. c.ft .. "): " .. c.nE .. " recipes of the tab take it in a slot, " .. c.miss
        .. " of them missed by the old search (e.g. " .. table.concat(c.missNames, "; ") .. "); recipes / missed per tool: " .. tostring(S.k10.candText)
        .. " (" .. tostring(getTimestampMs() - t0) .. " ms); the Category left on " .. tostring(cat.id) .. " (" .. n .. " of its recipes there)")
end)
H.wait(3000, function()
    local st = H.cst()
    return not S.k10.go or (st ~= nil and st.filterDirty == false and st.activeCat == S.k10.cat.id)
end, function(ok)
    local X = S.k10
    if not X.go then return end
    if not ok then X.go = false; Q.check(false, "K1-10 (staging): the list filters again on the category left", "not in 3 s"); return end
    -- the item's Craft, as the game's right-click option runs it (ISInventoryPaneContextMenu.doRecipeListForItem)
    X.t0 = getTimestampMs()
    if not (ISEntityUI and ISEntityUI.OpenHandcraftWindow) then
        X.go = false
        Q.check(false, "K1-10 (staging): the game's item Craft (ISEntityUI.OpenHandcraftWindow) is there")
        return
    end
    local okO, errO = pcall(ISEntityUI.OpenHandcraftWindow, S.p, nil, "*", false, nil, "!" .. X.c.ft)
    if not okO then Q.check(false, "K1-10 (staging): the item's Craft ran without an error", tostring(errO)) end
end)
H.wait(4000, function()
    local st = H.cst()
    return not S.k10.go or (st ~= nil and st.search == S.k10.c.name and st.filterDirty == false)
end, function(ok)
    local X = S.k10
    if not X.go then return end
    X.applied = ok
    X.selT = getTimestampMs()
end)
H.frames(2000, 0, function()
    local v = S.sel[S.wCat]
    return not S.k10.go or (v ~= nil and v.t > (S.k10.selT or 0))
end, function()
    local X = S.k10
    if not X.go then return end
    local st = H.cst()
    local v = S.sel[S.wCat]
    local label = "K1-10: an item's Craft resets the category: the Category select reads All after the tool's Craft (old code: the category left stays)"
    Q.check(X.applied == true and v ~= nil and v.v == S.wAll, label, "the search " .. H.q(st and st.search) .. (X.applied and "" or " (the item's Craft was not applied in 4 s)")
        .. "; the Category select reads " .. H.q(v and v.v) .. " (left on " .. H.q(X.cat.id) .. ", the list's category now " .. H.q(st and st.activeCat) .. ")")
end)
Q.step(1, function()
    local X = S.k10
    if not X.go then return end
    local st = H.cst()
    if st and st.activeCat ~= "all" then
        st.activeCat, st.filterDirty = "all", true
        X.byHand = true
    end
end)
H.wait(3000, function()
    local st = H.cst()
    return not S.k10.go or (st ~= nil and st.filterDirty == false and st.activeCat == "all")
end, function(ok)
    local X = S.k10
    if not X.go then return end
    if X.t2why then
        Q.skip("K1-10: the tool's search lists every recipe with an ingredient slot that takes it", X.t2why)
        return
    end
    local st = H.cst()
    local shown = {}
    for _, rd in ipairs((st and st.filteredCache) or {}) do if rd.entry then shown[rd.entry.name] = true end end
    local miss, names = 0, {}
    for name, e in pairs(X.c.E) do
        if not shown[name] then
            miss = miss + 1
            if #names < 5 then names[#names + 1] = tostring(e.displayName) end
        end
    end
    Q.check(ok and miss == 0, "K1-10: the tool's search lists every recipe with an ingredient slot that takes it (" .. X.c.nE .. " recipes for "
        .. X.c.name .. "; old code: those whose name, category, slots' first items and outputs lack the tool's name are missed, "
        .. X.c.miss .. " here)", miss .. " missing" .. ((miss > 0) and (", e.g. " .. table.concat(names, "; ")) or "") .. "; the list holds "
        .. #((st and st.filteredCache) or {}) .. " rows for the search " .. H.q(st and st.search)
        .. (X.byHand and "; the category set to All by hand first, as the fix leaves it" or ""))
end)
-- the search box's clear X: a click at its right end, through the box's own mouse handler
Q.step(2, function()
    local C = S.k10c
    C.go = false
    if not (S.k10.go and S.ok) then return end
    local w = RT.ww()
    local f = w and w._craftSearch or nil
    local inp = f and f.input or nil
    local jo = inp and inp.javaObject or nil
    C.label = "K1-10: the search box has a clear X: a click at its right end empties the box and the list's search (old code: no clear button, the click puts the cursor there and the words stay)"
    if not (inp and jo) then Q.check(false, C.label, "staging: the search box is not there"); return end
    C.was = H.fieldText() or ""
    if C.was == "" then Q.check(false, C.label, "staging: the box is empty (the item's Craft typed nothing)"); return end
    pcall(function() C.hasX = inp:hasClearButton() and true or false end)
    local bw, bh = 0, 0
    pcall(function() bw, bh = inp:getWidth(), inp:getHeight() end)
    C.x, C.y = bw - 2, math.floor(bh / 2)
    C.okD = pcall(function() jo:onMouseDown(C.x, C.y) end)
    C.okU = pcall(function() jo:onMouseUp(C.x, C.y) end)
    C.go = true
end)
H.wait(2000, function()
    if not S.k10c.go then return true end
    local st = H.cst()
    return H.fieldText() == "" and st ~= nil and (st.search or "") == "" and st.filterDirty == false
end, function(ok)
    local C = S.k10c
    if not C.go then return end
    local st = H.cst()
    local foc = H.unfocusSearch()
    Q.check(ok, C.label, "the box held " .. H.q(C.was) .. ", clicked at x " .. tostring(C.x) .. " of its width (the press ran " .. tostring(C.okD) .. ", the release "
        .. tostring(C.okU) .. "); its clear button " .. tostring(C.hasX) .. "; now the box reads " .. H.q(H.fieldText()) .. ", the list's search " .. H.q(st and st.search)
        .. (foc and "; the click had taken the keyboard: let go" or ""))
    if st and (st.search or "") ~= "" then H.setSearch(st, "") end
end)

-- ===================================================================== K1-7: the cause under Craft
S.k7a = { keyFt = S.TAPE,
    choices = { { recipe = S.SLING, give = { "Base.Tarp", S.TAPE } }, { recipe = S.SPEAR, give = { "Base.KitchenKnife", "Base.LongStick", S.TAPE } } },
    label = "K1-7: a hand recipe that takes 2 uses of duct tape (Make Tarp Sling Bag, else Duct Tape Spear), its roll at 1 use, every row counting by whole items: the tape's row is drawn red, the other rows stay green and no workbench line shows (old code: the tape row green 1/1 and Needs a workbench or station nearby.)" }
S.k7a.stage = function(T)
    local tape = nil
    for _, it in ipairs(T.items) do if H.ft(it) == S.TAPE then tape = it end end
    if not tape then return "no roll of duct tape among the things given" end
    pcall(function() tape:setCurrentUses(1) end)
    local u = nil
    pcall(function() u = tape:getCurrentUses() end)
    T.uses = u
    if u ~= 1 then return "the roll of duct tape did not keep 1 use (it reads " .. tostring(u) .. ")" end
    return nil
end
S.k7a.pre = function(T, g)
    if g.err then return "the game's reading failed: " .. g.err end
    if g.can then return "the game would make it (" .. H.gameText(g) .. "): he carries more duct tape, so the case is not here" end
    if not g.j then return "no slot of " .. T.recipe .. " takes " .. T.keyFt end
    if not (#g.short == 1 and g.short[1] == g.j) then return "the game reads other slots short too (" .. H.gameText(g) .. "; the tape is slot " .. tostring(g.j) .. ")" end
    return nil
end
S.k7a.fixed = function(T, last)
    local rows = last.rows or {}
    local j = T.g and T.g.j or nil
    if not (j and rows[j]) then return false end
    for i, r in ipairs(rows) do
        if i == j then
            if not (r.have < r.need) then return false end
        elseif r.have < r.need then
            return false
        end
    end
    for _, t in ipairs(last.texts or {}) do if t == S.wBench then return false end end
    return true
end
H.queueK7(S.k7a)
S.k7b = { keyFt = nil,
    choices = { { recipe = S.BAT, give = { "Base.BaseballBat", "Base.Saw" } }, { recipe = S.EGGS, give = S.EGGS_GIVE } },
    label = "K1-7: a recipe made on any surface (Saw Down Baseball Bat, else Put Eggs in Carton), every row green and no table or counter within 2 squares: the line under the rows reads Needs a table or counter nearby., not the workbench line (old code: Needs a workbench or station nearby.)" }
S.k7b.pre = function(T, g)
    local surf = H.surfaceNear()
    if surf then return "a table or counter stands within 2 squares of him (the game's FindCraftSurface found one): the case is not here" end
    if g.err then return "the game's reading failed: " .. g.err end
    if g.can then return "the game would make it with no surface (" .. H.gameText(g) .. ")" end
    if #g.short > 0 then return "the game reads slots short (" .. H.gameText(g) .. "): not the surface alone" end
    return nil
end
S.k7b.fixed = function(T, last)
    if not (last.rows and #last.rows > 0) then return false end
    for _, r in ipairs(last.rows) do if r.have < r.need then return false end end
    local surf, bench = false, false
    for _, t in ipairs(last.texts or {}) do
        if t == S.wSurf then surf = true end
        if t == S.wBench then bench = true end
    end
    return surf and not bench
end
H.queueK7(S.k7b)
Q.step(2, function()
    -- (the Crafting tab's drawing let go: Part B watches the item card)
    H.capDisarm()
    if S.cwOn then S.cwBackOk = H.unwrap("craft") end
end)

-- ===================================================================== B. the item cards (K1-2, K1-13)
Q.step(3, function()
    S.bOk = false
    if S.dead then return end
    local w = RT.cw()
    if not w then Q.check(false, "K1-2 and K1-13 (staging): the Character window is open for the item cards"); return end
    S.listTouched = true
    if S.was.charTab == nil then S.was.charTab = w._activeTab end
    -- (extra columns shut for the run, so the card opens over the plain list; opened again in the put-back)
    pcall(function()
        for _, j in ipairs(w._mcSelected or {}) do
            local e = w._containers and w._containers[j]
            if e then S.cols[#S.cols + 1] = e.inventory end
        end
        if #S.cols > 0 then ZeD_CharacterWindow.closeColumns(w) end
    end)
    RT.charTab("loot")
end)
Q.step(20, function()
    if S.dead then return end
    local w, c = RT.cw(), H.content()
    local rolled = w ~= nil and (w._rolled == true or (w._halves ~= nil and w._halves.inv ~= nil and w._halves.inv.rolled == true))
    local mine = c ~= nil and c._inventory == S.p:getInventory()
    local shown = false
    if c then pcall(function() shown = c:isReallyVisible() and true or false end) end
    if not (w and mine and shown and not rolled) then
        local why = "its list is not on screen"
        if w == nil then why = "the Character window is not open"
        elseif rolled then why = "its inventory side is rolled up"
        elseif not mine then why = "its list does not show his inventory" end
        Q.skip("K1-2 and K1-13 on the item cards", "the cards open from his inventory's rows: " .. why)
        return
    end
    if c._scroll then S.scrollWas = c._scroll.scrollPos end
    local given, notGiven = 0, {}
    for _, d in ipairs(S.CARD_ITEMS) do
        local it = RT.give(d.ft)
        S.cards[d.key] = { item = it, ft = d.ft, name = d.name }
        if it then given = given + 1 else notGiven[#notGiven + 1] = d.ft end
        if it and d.fluid then
            local fc = nil
            if it.getFluidContainer then pcall(function() fc = it:getFluidContainer() end) end
            local amt, fl = nil, nil
            if fc then
                pcall(function() amt = fc:getAmount() end)
                local pf = nil
                pcall(function() pf = fc:getPrimaryFluid() end)
                if pf then pcall(function() fl = tostring(pf:getFluidTypeString()) end) end
            end
            S.cards[d.key].fluid = tostring(fl) .. " " .. H.num(amt) .. " L"
            S.cards[d.key].empty = not (amt and amt > 0)
        end
    end
    if given < #S.CARD_ITEMS then Q.check(false, "K1-2 and K1-13 (staging): the things are given", "not given: " .. table.concat(notGiven, ", ")); return end
    -- each kind's stack opened (each thing its own row), every category fold opened (folded again at the end)
    pcall(function()
        c._expandedStacks = c._expandedStacks or {}
        for _, d in ipairs(S.CARD_ITEMS) do
            if S.stackWas[d.ft] == nil then S.stackWas[d.ft] = c._expandedStacks[d.ft] or false end
            c._expandedStacks[d.ft] = true
        end
    end)
    pcall(function()
        local cg = c._collapsedGroups
        if c._sortCol == "cat" and cg then
            for k, v in pairs(cg) do if v then S.folds[#S.folds + 1] = k end end
            for _, k in ipairs(S.folds) do cg[k] = nil end
            S.foldsOf = cg
        end
    end)
    if not H.cardWatchOn() then Q.check(false, "K1-2 and K1-13 (staging): the item card's drawing can be watched"); return end
    S.bOk = true
    local fl = {}
    for _, key in ipairs({ "bleach", "alcohol", "petrol", "water" }) do fl[#fl + 1] = key .. " " .. tostring(S.cards[key].fluid) end
    Q.say("staged: " .. #S.CARD_ITEMS .. " things given (" .. table.concat(fl, ", ") .. "); the list shows his inventory; Lite " .. tostring(H.lite()))
end)
H.queueCard("bleach", "K1-2, the bleach")
H.queueCard("alcohol", "K1-2, the rubbing alcohol")
H.queueCard("petrol", "K1-2, the gas can")
H.queueCard("water", "K1-2, the water bottle")
Q.step(1, function()
    if not S.bOk then return end
    local label = "K1-2: the card's big button is never Drink on bleach, rubbing alcohol or a gas can, no Drink on them at all, while a water bottle's main button is Drink (old code: Drink the main button on all four)"
    local parts, bad, unread = {}, 0, 0
    for _, key in ipairs({ "bleach", "alcohol", "petrol" }) do
        local C = S.cards[key]
        if not C.rec then
            unread = unread + 1
            parts[#parts + 1] = C.name .. ": its card not read"
        else
            if H.verb(C.rec, "DRINK") then bad = bad + 1 end
            if C.empty then bad = bad + 1 end
            parts[#parts + 1] = C.name .. " (" .. tostring(C.fluid) .. ((C.empty) and ", EMPTY: the case is not staged" or "") .. ") draws " .. H.verbsText(C.rec)
        end
    end
    local W = S.cards.water
    local wp = W and W.rec and H.primary(W.rec) or nil
    local wOk = wp ~= nil and wp.id == "DRINK" and not wp.disabled
    parts[#parts + 1] = "the water bottle (" .. tostring(W and W.fluid) .. ") draws " .. H.verbsText(W and W.rec)
    Q.check(unread == 0 and bad == 0 and wOk, label, table.concat(parts, "; "))
    -- (the pad: what the hint strip names beside a held A on each row, padItemButtons' promptHold, and the test its
    -- onHoldActivate asks before it drinks, padIsDrink. Nothing is held: on the old code a hold would drink the bleach)
    local IR = ZeD.InventoryRenderer
    local cwin = RT.cw()
    local pad, padBad = {}, 0
    for _, key in ipairs({ "bleach", "alcohol", "petrol", "water" }) do
        local it = S.cards[key].item
        local v, hold, dw = nil, nil, nil
        pcall(function() v = IR.padIsDrink(it) and true or false end)
        pcall(function() hold = IR.padPromptHold(cwin, { item = it }) end)
        pcall(function() dw = IR.padDrinkWord(it) end)
        local want = (key == "water")
        local holdDrinks = hold ~= nil and dw ~= nil and tostring(hold) == tostring(dw)
        if v ~= want or holdDrinks ~= want then padBad = padBad + 1 end
        pad[#pad + 1] = key .. ": held A reads " .. H.q(hold) .. ", drinks " .. tostring(v)
    end
    Q.check(padBad == 0, "K1-2: on a pad, held A drinks only where the card offers Drink: on the bleach, the rubbing alcohol and the gas can the hint strip's held-A word is not Drink and the hold's own test (padIsDrink) says no; on the water both say Drink (old code: Drink on all four)",
        table.concat(pad, "; "))
    -- (the gas can, up to 10 kg, goes back now: nothing after reads it)
    local P = S.cards.petrol
    if P and P.item then H.takeOne(P.item); H.floorChanged() end
end)
H.queueCard("shirt", "K1-13, the T-shirt")
Q.step(1, function()
    if not S.bOk then return end
    local rec = S.cards.shirt.rec
    local pv = rec and H.primary(rec) or nil
    Q.check(pv ~= nil and pv.label == S.vtWear and S.vtWear ~= S.vtEquip, "K1-13: a piece of clothing's main card button reads Wear, the game's word, as a backpack's does (old code: Equip)",
        "the T-shirt's card draws " .. H.verbsText(rec) .. "; Wear is " .. H.q(S.vtWear) .. ", Equip " .. H.q(S.vtEquip))
    local label = "K1-13: the card's three marks name themselves in the game's words, Favorite, Unusable in Recipes and Unwanted (old code: Fav, No-craft, Dispose)"
    if not S.en then Q.skip(label, "the game is not in ZeD's English (" .. tostring(S.lang) .. ")"); return end
    local got, src = {}, nil
    for _, ch in ipairs((rec and rec.chips) or {}) do got[ch.kind] = ch.label end
    if got.fav or got.nocraft or got.dispose then
        local compact = rec.chips[1] and rec.chips[1].compact
        src = "the words the T-shirt's card handed its chips as it drew them" .. (compact and " (a narrow card: the icons drawn, the words their names)" or " (drawn beside the icons)")
    else
        for k, key in pairs(S.WORDS.markKeys) do got[k] = H.tr(key) end
        src = "the chips' keys (the card drew no marks" .. (H.lite() and ": Lite is on" or "") .. ")"
    end
    local M = S.WORDS.marks
    Q.check(got.fav == M.fav and got.nocraft == M.nocraft and got.dispose == M.dispose, label, src .. ": " .. H.q(got.fav) .. ", " .. H.q(got.nocraft) .. ", " .. H.q(got.dispose))
end)
-- D3: the sealed can's Eat
H.queueCard("beans", "K1-2, the sealed can of beans")
Q.step(1, function()
    local B = S.beans
    B.label = "K1-2: Eat on a sealed can of beans, a can opener carried, queues the can's opening first, the game's Open and eat, never an eat of the sealed can (old code: an ISEatFoodAction on the sealed can)"
    if not S.bOk then return end
    local C = S.cards.beans
    local it, rec, card = C and C.item, C and C.rec, H.cardObj()
    if not (it and rec and card and H.cardOn(it)) then Q.check(false, B.label, "staging: the beans' card is not open (" .. H.verbsText(rec) .. ")"); return end
    local list = H.queue()
    if not list then Q.check(false, B.label, "staging: the game's action queue for him could not be read"); return end
    if #list > 0 then Q.skip(B.label, "an action is already queued for him (" .. H.qText(list) .. "): nothing is pressed"); return end
    if (H.fed() or 0) >= 3 then Q.skip(B.label, "he is stuffed (Well Fed " .. tostring(H.fed()) .. "): the game eats nothing then"); return end
    local opening = nil
    if it.getOpeningRecipe then pcall(function() opening = it:getOpeningRecipe() end) end
    if opening == nil or tostring(opening) == "" then Q.check(false, B.label, "staging: the beans have no opening recipe"); return end
    B.opening = tostring(opening)
    local v = H.verb(rec, "EAT")
    if not v then Q.check(false, B.label, "the card draws no Eat: " .. H.verbsText(rec)); return end
    -- the press: the card's own dispatch, what a click on the button and the pad's A both run
    S.queued = true
    local okP, errP = pcall(function() card:_dispatchHeaderVerb(v.id or v.label) end)
    -- what it queued, read and cleared in this same step: no tick runs between, so nothing starts
    local acts = {}
    for i, a in ipairs(list) do acts[i] = a end
    pcall(function() ISTimedActionQueue.clear(S.p) end)
    local first = nil
    for _, a in ipairs(acts) do
        local ty = type(a) == "table" and a.Type or nil
        if first == nil and (ty == "ISHandcraftAction" or ty == "ISEatFoodAction") then first = a end
    end
    local fName = nil
    if first and first.Type == "ISHandcraftAction" and first.craftRecipe then pcall(function() fName = tostring(first.craftRecipe:getName()) end) end
    B.done = true
    -- (the item names its opening recipe as the script does, with or without its module: compared without it)
    Q.check(okP and first ~= nil and fName ~= nil and H.bare(fName) == H.bare(B.opening), B.label, "Eat " .. (okP and "pressed" or ("threw: " .. tostring(errP))) .. "; it queued " .. H.qText(acts)
        .. "; the can's opening recipe " .. B.opening .. "; the queue cleared at once")
end)
Q.step(2, function()
    local B = S.beans
    if not B.done then return end
    local list = H.queue()
    if list and #list > 0 then pcall(function() ISTimedActionQueue.clear(S.p) end) end
    local it = S.cards.beans and S.cards.beans.item
    Q.say("note K1-2: after the press his queue holds " .. H.qText(H.queue()) .. "; the can is " .. tostring(H.ft(it)) .. ", in his inventory "
        .. tostring(it ~= nil and H.where(it) == S.p:getInventory()))
end)
-- D4: stuffed, an apple's Eat
Q.step(2, function()
    local F = S.full
    F.go = false
    F.label = "K1-2: stuffed (Well Fed at 3 or more), an apple's card draws its Eat grayed, its help line the game's " .. H.q(S.wCantEat) .. " (old code: Eat lit, its usual help line)"
    if not (S.bOk and S.cards.apple and S.cards.apple.item) then return end
    local bd = S.p:getBodyDamage()
    if not bd then Q.check(false, F.label, "staging: his body could not be read"); return end
    local std = nil
    pcall(function() F.was = bd:getHealthFromFoodTimer(); std = bd:getStandardHealthFromFoodTime() end)
    if not (F.was and std and std > 0) then Q.check(false, F.label, "staging: the eaten-food timer could not be read"); return end
    F.fedWas = H.fed()
    F.staged = true
    pcall(function() bd:setHealthFromFoodTimer(std * 3.5) end)
    F.go = true
end)
H.wait(4000, function() return not S.full.go or (H.fed() or 0) >= 3 end, function(ok)
    local F = S.full
    if not F.go then return end
    if not ok then
        F.go = false
        H.fullBack()
        Q.skip(F.label, "the game did not raise his Well Fed to 3 in 4 s (it reads " .. tostring(H.fed()) .. ")")
        return
    end
    F.at = getTimestampMs()
end)
H.queueCard("apple", "K1-2, the apple while he is stuffed", function() return S.full.at and (S.full.at + 300) or nil end, function() return S.full.go == true end)
Q.step(1, function()
    local F = S.full
    if not F.go then H.fullBack(); return end
    local rec = S.cards.apple.rec
    local fedNow = H.fed()
    -- the timer as found, the moment the card is read
    H.fullBack()
    local v = rec and H.verb(rec, "EAT") or nil
    Q.check(v ~= nil and v.disabled == true and v.help == S.wCantEat, F.label, "Well Fed " .. tostring(fedNow) .. ": the apple's card draws " .. H.verbsText(rec)
        .. "; its Eat's help line " .. H.q(v and v.help))
end)
H.wait(4000, function() return S.full.fedWas == nil or (H.fed() or 0) <= S.full.fedWas end, function(ok)
    if S.full.fedWas == nil then return end
    Q.say("note Well Fed back to " .. tostring(H.fed()) .. " (found " .. tostring(S.full.fedWas) .. ")" .. (ok and "" or ", not yet in 4 s"))
end)
-- the things taken back (the open card follows its thing out of the bags and closes by itself)
Q.step(2, function()
    if S.kwOn then S.kwBackOk = H.unwrap("card") end
    S.card.want, S.card.obj, S.card.last = nil, nil, nil
    for _, d in ipairs(S.CARD_ITEMS) do
        local C = S.cards[d.key]
        if C and C.item then H.takeOne(C.item) end
    end
end)
H.wait(3000, function() local w = RT.cw(); return not S.listTouched or w == nil or w._drawerItem == nil end, function(held)
    if not S.listTouched then return end
    if not held then H.pressCharTab("loot") end
    H.listBack()
end)

-- ===================================================================== put back
Q.mark()
-- (every line stands alone: one that throws does not stop the next)
Q.step(3, function()
    pcall(function() H.unwrap(nil) end)
    pcall(H.capDisarm)
    S.popSeen = nil
    if S.dead then return end
    pcall(H.fullBack)
    pcall(function()
        local list = H.queue()
        if S.queued and list and #list > 0 then ISTimedActionQueue.clear(S.p) end
    end)
    pcall(H.unfocusSearch)
    pcall(H.shut)
    pcall(RT.takeBack)
    pcall(function() if S.stWas then ZeD.Stations.bind(S.p, S.stWas) end end)
    pcall(function() if S.dirWas then S.p:setDir(S.dirWas) end end)
    pcall(H.floorChanged)
    pcall(H.listBack)
    -- (the Crafting tab showing again when the run stopped elsewhere: its state is set back while it draws)
    pcall(function()
        local w = RT.ww()
        if S.craftSeen and w and w._activeTab ~= "craft" then H.tab("craft") end
    end)
end)
-- the Crafting tab's choices as found: Show, Sort, category, folds, Owned only, the search (its field too)
Q.step(4, function()
    if S.dead then return end
    pcall(function()
        local st, k = H.cst(), S.keep
        if not (st and k and S.craftSeen) then return end
        st.show, st.showAll, st.sort, st.activeCat = k.show, k.showAll, k.sort, k.cat
        st.reqCollapsed, st.outCollapsed, st.allCollapsed, st.ownedOnly = k.req and true or false, k.out and true or false, k.all and true or false, k.owned and true or false
        st.qty, st.filterDirty, st._sectionsStale = k.qty or 1, true, true
        st.sortMenuOpen, st.showMenuOpen, st.catDropdownOpen, st.stDropdownOpen, st.catDropdownScroll = false, false, false, false, 0
        if S.searchTouched then H.setSearch(st, k.search or "") end
    end)
end)
-- the list filtered again as found; then the card that was open, its picks and amount, the scroll
H.frames(10000, 1500, function()
    local st, k = H.cst(), S.keep
    if S.dead or not (st and k and S.craftSeen) then return "now" end
    return (st.search or "") == (k.search or "") and st.filterDirty == false
end, function(ok)
    if S.dead then return end
    pcall(function() S.swept = H.sweep() end)
    local st, k = H.cst(), S.keep
    if not (st and k and S.craftSeen) then return end
    if not ok then Q.say("note put back: the Crafting tab's list was not filtered again within 10 s: the card and scroll are set back anyway") end
    pcall(function() if k.sel and st.selected ~= k.sel then S.CC.openCraft(st, k.sel) end end)
    pcall(function() st.picks = k.picks or {}; st.qty = k.qty or 1 end)
    pcall(function() st.scroll:setScrollPos(k.scroll or 0) end)
    pcall(function() st.cardScroll:setScrollPos(k.card or 0) end)
end)
Q.step(3, function()
    if S.dead then return end
    local st = H.cst()
    S.stateNow = st and H.keepState(st) or nil
    S.fieldNow = H.fieldText()
    -- the World window's tab as found (the Crafting tab's state is read first: a hidden tab draws nothing)
    local w = RT.ww()
    local t = S.tabWas or "loot"
    if w and w._activeTab ~= t then pcall(H.tab, t) end
    local cw = RT.cw()
    if cw and S.was.charTab and cw._activeTab ~= S.was.charTab then pcall(RT.charTab, S.was.charTab) end
end)
Q.step(5, function()
    if S.dead then return end
    if S.pairWas == false then pcall(RT.pairShut) end
end)
H.wait(4000, function()
    local s = S.was.stats
    return S.dead or s == nil or s.fed == nil or (H.fed() or 0) <= s.fed
end, function() end)
Q.step(10, function()
    pcall(function() H.unwrap(nil) end)
    if S.dead then return end
    -- the script's things still carried or on the floor, his own things no longer carried; anything else new is said
    local left, held, gone, otherC = 0, {}, 0, 0
    for _, it in ipairs(H.all()) do
        held[it] = true
        if not S.had[it] then
            if H.mine(it) then left = left + 1 else otherC = otherC + 1 end
        end
    end
    local goneSeen = {}
    for it in pairs(S.had) do
        if not held[it] then
            gone = gone + 1
            if #goneSeen < 3 then goneSeen[#goneSeen + 1] = tostring(H.ft(it)) end
        end
    end
    local now, floor, other = {}, 0, 0
    H.snapFloor(now)
    for wo in pairs(now) do
        if not S.floorHad[wo] then
            local it = H.wobItem(wo)
            if it and H.mine(it) then floor = floor + 1 else other = other + 1 end
        end
    end
    Q.check(left == 0 and gone == 0 and floor == 0, "put back: he carries what he carried at the start, nothing of the script's left on him or on the floor beside him",
        tostring(S.swept) .. " stray things of the script's taken away, " .. left .. " of the script's still carried, " .. gone .. " of his own things not carried"
        .. ((gone > 0) and (" (" .. table.concat(goneSeen, ", ") .. ")") or "") .. ", " .. floor .. " of the script's on the floor"
        .. (((otherC + other) > 0) and ("; new and not the script's, left alone: " .. otherC .. " carried, " .. other .. " on the floor nearby") or ""))
    local wOk, wBad = H.wrapsBack()
    local list = H.queue()
    local qn = list and #list or nil
    local foc = false
    pcall(function()
        local w = RT.ww()
        local f = w and w._craftSearch or nil
        if f and f.input then foc = f.input:isFocused() and true or false end
    end)
    Q.check(wOk and (qn == nil or qn <= (S.was.queue or 0)) and not foc, "put back: ZeD's drawing functions as found (the watches taken off), nothing left queued for him, the search box not holding the keys",
        "wrappers " .. (wOk and ("all " .. #S.wraps .. " off") or ("still on: " .. table.concat(wBad, ", "))) .. "; queued " .. tostring(qn) .. " (found " .. tostring(S.was.queue)
        .. "): " .. H.qText(list) .. "; the search box holds the keys " .. tostring(foc))
    local a, b = S.was.stats or {}, H.stats()
    local drift, parts = {}, {}
    for _, k in ipairs(S.STATS) do
        if a[k] ~= nil and b[k] ~= nil then parts[#parts + 1] = string.lower(k) .. " " .. H.num(b[k]) .. " (" .. H.num(a[k]) .. ")" end
    end
    for _, k in ipairs(S.STATS_DOWN) do
        if a[k] ~= nil and b[k] ~= nil and b[k] < a[k] - 0.05 then drift[#drift + 1] = string.lower(k) .. " down" end
    end
    for _, k in ipairs(S.STATS_UP) do
        if a[k] ~= nil and b[k] ~= nil and b[k] > a[k] + 0.05 then drift[#drift + 1] = string.lower(k) .. " up" end
    end
    local healthOk = a.health == nil or b.health == nil or b.health >= a.health - 1
    local timerOk = a.timer == nil or b.timer == nil or b.timer <= a.timer + 1
    local fedOk = a.fed == nil or b.fed == nil or b.fed <= a.fed
    local alive = not S.p:isDead()
    Q.check(alive and #drift == 0 and healthOk and timerOk and fedOk and not S.full.staged, "put back: he is alive and well: he ate and drank nothing (hunger and thirst not down), gained no poison, food sickness or sickness, lost no health, the eaten-food timer and Well Fed as found",
        ((#drift > 0) and ("CHANGED: " .. table.concat(drift, ", ") .. "; ") or "") .. table.concat(parts, ", ") .. "; health " .. H.num(b.health) .. " (" .. H.num(a.health)
        .. "), eaten-food timer " .. H.num(b.timer) .. " (" .. H.num(a.timer) .. "), Well Fed " .. tostring(b.fed) .. " (" .. tostring(a.fed) .. ") (now (found))")
    local k, n = S.keep, S.stateNow
    if k and n and S.craftSeen then
        local same = n.show == k.show and n.showAll == k.showAll and n.sort == k.sort and n.cat == k.cat and (n.search or "") == (k.search or "")
            and n.sel == k.sel and (n.all and true or false) == (k.all and true or false) and (n.out and true or false) == (k.out and true or false)
            and (n.req and true or false) == (k.req and true or false) and (n.owned and true or false) == (k.owned and true or false)
        if S.searchTouched and S.fieldNow ~= nil and S.fieldNow ~= (k.search or "") then same = false end
        local scr = n.scroll ~= nil and math.abs(n.scroll - (k.scroll or 0)) < 0.0005
        Q.check(same and scr, "put back: the Crafting tab's Show, Sort, category, folds, search (field and list), open card and scroll as found",
            "Show " .. tostring(n.show) .. "/" .. tostring(k.show) .. ", Sort " .. tostring(n.sort) .. "/" .. tostring(k.sort) .. ", category " .. tostring(n.cat) .. "/" .. tostring(k.cat)
            .. ", search " .. H.q(n.search) .. "/" .. H.q(k.search) .. " (the field " .. H.q(S.fieldNow) .. "), card " .. tostring(n.sel) .. "/" .. tostring(k.sel)
            .. ", scroll " .. string.format("%.4f", n.scroll or -1) .. "/" .. string.format("%.4f", k.scroll or -1) .. " (now / found)")
    end
    local w, cw = RT.ww(), RT.cw()
    local tabNow = w and w._activeTab or nil
    local ctabNow = cw and cw._activeTab or nil
    local stNow = nil
    pcall(function() stNow = ZeD.Stations.current(S.p) end)
    local stOk = (S.stWas == nil and stNow == nil) or (S.stWas ~= nil and stNow ~= nil)
    Q.check((S.tabWas == nil or tabNow == S.tabWas) and (S.was.charTab == nil or ctabNow == S.was.charTab) and RT.isOpen() == S.pairWas and stOk,
        "put back: the World and Character windows' tabs, the window pair and a bound station as found",
        "World on " .. tostring(tabNow) .. " (found " .. tostring(S.tabWas) .. "), Character on " .. tostring(ctabNow) .. " (found " .. tostring(S.was.charTab)
        .. "), the pair open " .. tostring(RT.isOpen()) .. " (found " .. tostring(S.pairWas) .. "), a station bound " .. tostring(stNow ~= nil) .. " (found " .. tostring(S.stWas ~= nil) .. ")")
end)
Q.start()
