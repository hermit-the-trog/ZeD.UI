-- ZeDUI/tools/qa/vx10_craft.lua  (Nov 21 2026, QA): the in-game proof of Build's fix for QA batch 10's B10-2 (the
-- amount half) and B10-4 (commit a87984ace, CraftingCore.lua; findings in ZeDUI/qa/audits/2026-11-21_beast_batch10.md).
-- Needs zedqa_prelude.lua and rt_kit.lua first. grep "ZEDQA vx10_crf". Manifest: vx10.txt (vx10_craft.lua | vx10_crf |
-- timeout=360). The World window's Crafting tab, Show: All, sorted Craftable. Nothing is crafted: Craft is never pressed.
--   B10-2 (the card's Outputs read one craft's yield):
--     * ZeD's output definitions (CC.prebakeOutputs: the catalog Craft, Build and the Journal share) against the game's
--       own amount (OutputScript:getIntAmount for an item output, as vanilla's ISWidgetOutput.lua:147-151 reads it):
--       the whole catalog, and by name Divide Food into 4 Bowls (4 and 1), Open Candy Package (5 and 5), Break Large
--       Stone into Stones (10) and Make Coke (4). The old code kept no amount at all (nil on every output).
--     * the open card: each of those four opened from its row (brought into the list's view, then clicked), and the
--       numbers its Outputs rows draw read where they are drawn: CC.renderCraftCard, its section heads
--       (Molecules.drawCategoryRow, the "Outputs" head), its rows (Molecules.drawSlotRow) and the count each row hands
--       Atoms.drawTextRight, watched for two drawn frames (the four wrapped in memory and put back at once). The old
--       card drew 1 on every row, and no Outputs section at all for the stones and the coke (one output, named in the
--       title).
--     * the whole catalog: a single output making more than one keeps the section (CC.outputsRepeatTitle false; the
--       old code hid every one). A guard, passing on the old code too: a single output of one named in the title
--       still hides it, over the catalog and on the anvil mold's open card.
--     * information for Build (said, not scored): with 4 bowls and a pot of soup carried, then a saucepan of rice, the
--       names ZeD's Outputs rows give Divide Food's outputs, and the names the game's output mapper gives for what is
--       in reach (OutputScript:getOutputMapper():getOutputItem(the recipe data, true): the vanilla window's
--       manual-select naming, ISWidgetOutput.lua:286-295; the data filled as the game fills it, a HandcraftLogic on
--       the game's own container list and the table).
--   B10-4 (the Craftable sort keeps the open recipe in place), staged as bxr_craft.lua's W24 / W25: the anvil mold
--     (MakeWoodenBlacksmithAnvilMold: a hammer, a saw, 4 planks and a nail, any surface, Carpentry 2), a table beside
--     him, his own planks set aside, a hammer, a saw, nails and ONE plank given, Carpentry raised to 2 if lower. The
--     row's offset from the list view's top is read from its click zone (stamped for every row, in view or not) and
--     the list's geometry (state._listGeo). The row is placed in view no lower than the ready rows before it by name
--     can carry it, so a perfect hold is never stopped by the list's top.
--     * timing: in a world with See Not Known Recipes on (the game's default; QA's world has it on) the list is sorted
--       again about every 1.2 s with nothing changing (a must-learn recipe not learned reads "unlocked" after each row
--       refresh and "locked" after each scan: S.FLICKER below), so no wait here asks for the list to fall quiet. The
--       card is opened at a calm moment (H.calm: the next row refresh and scan both 0.7 s away, no row changed since
--       the last sort), after a fresh sort with no card open (the old code too then has the row in its place by name).
--     * the card opened from the row and shut by Escape before that refresh and scan (no other sort and no status
--       change between; else tried once more): the offset before and after the shut. (Nov 25 2026, KISS #47: a second
--       click on the open row leaves its card open; the click is still made and must keep the card, then Escape,
--       CC.takeEscape, shuts it. The check used to shut it with that second click.) The old code sorted on
--       the shut with the open recipe's missing count (key 12010 against the others' 12000: after every missing and
--       station row), so the row jumped down the list.
--     * the card open (opened at a calm moment, the first change made before the next scan): 2 planks dropped at his
--       feet (other recipes turn ready and the list is sorted again; the 2-plank Crude Bench Vise mold, after the anvil
--       by name, goes up to the ready rows, so the anvil's row moves one place down the list), 2 more in a crate in
--       reach (the mold itself turns ready and moves up to the ready rows), then the crate's planks taken back (it
--       turns missing again). Each time the game's scan (CC.logicScan, every 1.2 s) and its sort are waited for (the
--       list sorted since the change, the mold reading as wanted for 1.5 s) and the offset is read again: the same
--       within 2 px (1 px more for each sort past two: a held scroll is a fraction and may land a px low), and in view.
--       The old code kept the scroll fraction and moved the row (to the end of the missing rows, then up to the ready
--       rows, then back), so the offset jumped by many rows.
--     * the key half alone (after the shut, and after each change that leaves the mold missing): in the sorted list
--       the mold sits in its place by name among the rows of its sort group (missing and station), each row's group
--       read as the sort saw it (S.sortSnap). The old key added the open recipe's missing count and put it after all
--       of them.
-- Run offline before the first game run (Nov 21 2026: KRun, rt_kit.lua and this script in the game's Kahlua against a
-- stubbed game and the shipped CraftingCore.lua; the harness is not in the repo): a87984ace PASS 24, a87984ace~1 FAIL
-- 14 (every B10-2 and B10-4 check; the guards and the put-back PASS), at 3840x2160 and 1280x800, the crate taken in at
-- once, on the turn or never (the floor stand-in), a re-sort while the shut check's card is open (tried again), and
-- found with a card open, another sort, a scroll, a search typed, the mold pinned (B10-4 SKIP, said why). The review
-- (Nov 21 2026) added the See Not Known Recipes flicker to a copy of the harness (must-learn rows the refresh reads
-- learned and the game's scan invalid: the list sorted every scan) and reworked the timing for it; after its changes
-- a87984ace PASS 24, a87984ace~1 FAIL 14 with and without the flicker, in every variant above; a thing the script
-- never made appearing in his inventory is said and left alone, not deleted.
-- Puts back: every thing given (RT.takeBack), his own planks set aside, the planks on the floor, the crate, the table,
-- Carpentry as found, a bound station, his facing, the game's loot list read afresh (the crate taken away leaves it),
-- ZeD's four drawing functions; then the Crafting tab's Show / Sort / category / folds / Owned only / search (the field
-- and the list together), set after a station bound again has reset them; then, once the list is filtered again and
-- the game's scan has answered for what was taken away (2 s), the open card with its picks and amount; then, at a calm
-- moment (no sort due to move it before it is read), the scroll; the World window's tab, the window pair as found.
-- The sweep takes away only the script's own things (marked ZeDQA_spawned): anything else new is said, never deleted.
-- Nothing is applied or saved, no file is written.

if not RT then
    print("ZEDQA vx10_crf ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA vx10_crf VERDICT FAIL 1")
    print("ZEDQA vx10_crf DONE")
    return
end

local Q = RT.make("vx10_crf")
-- (typically about a minute; every wait at its limit comes to about 220 s, and the put-back after a jump takes some
-- 25 s more: inside the manifest's 360 s)
Q.maxMs = 300000
local S = { had = {}, floorHad = {}, aside = {}, floorIts = {}, extraIts = {}, crateIts = {}, cap = { cards = 0 } }
local H = {}
S.p, S.pn = RT.p, RT.pn
S.CC = ZeD and ZeD.CraftingCore
S.CT = ZeD and ZeD.CraftingTab
S.WW = ZeD_WorldWindow
S.MOLD, S.PLANK = "MakeWoodenBlacksmithAnvilMold", "Base.Plank"
S.BOWLS, S.CANDY, S.STONES, S.COKE = "Make4Bowls", "OpenCandyPackage", "Make_Stones_from_Large_Stone", "MakeCoke"
S.NAMED = { S.BOWLS, S.CANDY, S.STONES, S.COKE }
-- one craft's yield as the game's scripts write it (recipes_cooking.txt, recipes_stonemasonry_i.txt,
-- entity_dome_kiln_craftRecipe.txt): said beside the game's own reading, the check goes by the game's reading
S.SCRIPT = { Make4Bowls = "4, 1", OpenCandyPackage = "5, 5", Make_Stones_from_Large_Stone = "10", MakeCoke = "4" }
S.NEAR = { { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }
S.TABLES = { "furniture_tables_high_01_16", "furniture_tables_high_01_0", "furniture_tables_high_01_8", "furniture_tables_high_01_24",
    "furniture_tables_high_01_32", "furniture_tables_high_01_40", "furniture_tables_low_01_0", "furniture_tables_low_01_8" }
S.TOL = 2        -- px: a held scroll is a fraction of the list, and may land one px low
S.dead = false

if not (S.p and S.CC and S.CT and S.WW and ZeD.Molecules and ZeD.Atoms) then
    Q.check(false, "the player and ZeD's Crafting tab are loaded")
    Q.start()
    return
end
-- ZeD's own drawing functions as found (the card's watch wraps them for a few frames; the put-back checks them)
S.orig = { card = S.CC.renderCraftCard, slot = ZeD.Molecules.drawSlotRow, cat = ZeD.Molecules.drawCategoryRow, tr = ZeD.Atoms.drawTextRight }

-- ===================================================================== helpers: time
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
-- every drawn frame, each re-sort of the list counted as it happens (a re-sort makes a new filtered list): until
-- cond() has held without a break for steadyMs (cond may answer "now": done at once), at most ms. Re-sorts do not
-- stop the wait: in a world with See Not Known Recipes on (the game's default) the list is sorted again about every
-- 1.2 s with nothing changing (see S.FLICKER), so a wait for the list to fall quiet would never end.
-- fn(ok, how many re-sorts were seen)
function H.frames(ms, steadyMs, cond, fn)
    local w = {}
    Q.waitFor(1, 4000000, function()
        local now = getTimestampMs()
        local st = H.cst()
        local fc = st and st.filteredCache
        if w.t0 == nil then
            w.t0, w.fc, w.n = now, fc, 0
        elseif fc ~= w.fc then
            w.fc, w.n = fc, w.n + 1
        end
        local ok, r = pcall(cond)
        if ok and r == "now" then return true end
        if ok and r then
            w.since = w.since or now
            if now - w.since >= steadyMs then w.ok = true; return true end
        else
            w.since = nil
        end
        return now - w.t0 >= ms
    end, function() fn(w.ok == true, w.n or 0) end)
end
function H.n(x) if type(x) ~= "number" then return tostring(x) end; return tostring(math.floor(x + 0.5)) end
function H.f4(x) if type(x) ~= "number" then return tostring(x) end; return string.format("%.4f", x) end
-- every re-sort of the list counted as it happens (a re-sort makes a new filtered list), from the setup to the
-- put-back (OnPreUIDraw, read only), with every listed row's status as that sort saw it (S.sortSnap: the statuses
-- do not change between the sort and the next frame's OnPreUIDraw)
S.sorts = 0
function H.sortWatch()
    local st = H.cst()
    local fc = st and st.filteredCache
    if fc ~= S.lastFc then
        S.lastFc = fc
        S.sorts = S.sorts + 1
        S.sortSnap = H.snapStatus()
    end
end
-- (S.FLICKER) The Crafting tab's rows are rewritten once a second (CraftingTab.gatherData, its "learned" read through
-- isRecipeKnown(recipe), which answers yes for every recipe while the world's See Not Known Recipes is on), and the
-- game's scan asks every 1.2 s (CC.logicScan: CachedRecipeInfo:isValid, the game's isRecipeKnown(recipe, true), which
-- does not take that shortcut). A must-learn recipe not learned, needing no skill, reads "unlocked" after each
-- refresh and "locked" after each scan, and every scan sorts the list again; a sort that comes between (the card's
-- shut) sees it "unlocked", ahead of the missing rows. So the open and the shut of the card are timed for a calm
-- moment (H.calm), and the sort-order checks read the statuses each sort saw (S.sortSnap).
S.SCAN_MS = 1200   -- CraftingCore's LOGIC_EVERY_MS (the scan's pace: local to CraftingCore, so written here)
S.RUNWAY = 700     -- ms the open and the shut need, place to shut's sort (0.28 s of card animation, a few frames)
-- whether every listed row still reads as the last sort saw it (no row refresh or scan has changed one since)
function H.sameSinceSort()
    local st = H.cst()
    if not (st and S.sortSnap and st.filteredCache ~= nil and st.filteredCache == S.lastFc) then return false end
    for rd, s in pairs(S.sortSnap) do if rd.status ~= s then return false end end
    return true
end
-- a calm moment: the list's next row refresh and next scan are both more than ms away, and every row still reads as
-- the last sort saw it
function H.calm(ms)
    local w = RT.ww()
    if not w then return false end
    local now = getTimestampMs()
    local rows, scan = w._craftRowsAt, w._craftLogicAt
    if type(rows) ~= "number" or type(scan) ~= "number" then return false end
    if rows - now <= ms or scan + S.SCAN_MS - now <= ms then return false end
    return H.sameSinceSort()
end

-- ===================================================================== helpers: the tab
function H.cst() local w = RT.ww(); return w and w._craftState end
function H.data() local w = RT.ww(); return w and w._craftCache end
function H.geo() local st = H.cst(); return st and st._listGeo end
function H.row(name) local d = H.data(); return d and d.byName and d.byName[name] or nil end
-- a recipe's catalog entry: its row's, else the catalog's own (a recipe the list does not show)
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
function H.inViewRel(rel, g, h) return rel ~= nil and g ~= nil and rel >= -1 and rel + h <= g.viewH + 1 end
-- a press where a click lands: the tab's own mouse handler, the zone's middle
function H.click(z, what)
    local ok, err = pcall(S.CT.onClick, RT.ww(), z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
    if not ok then Q.check(false, what .. ": the click ran without an error", err) end
    return ok
end
-- a recipe's card opened as a click on its row does (from code, said, when the row is out of view)
function H.open(name, what)
    local st = H.cst()
    if not st then return false end
    pcall(function() if st.altSlotName then S.CC.exitAltMode(st) end end)
    if st.selected == name then return true end
    local z = H.rowZone(name)
    if z and H.inView(z) then
        H.click(z, what)
    else
        local ok, err = pcall(S.CC.openCraft, st, name)
        if not ok then Q.check(false, what .. ": the card opened without an error", err) end
        Q.say("note " .. what .. ": " .. name .. " has no row in view, its card is opened from code")
    end
    return st.selected == name
end
function H.shut()
    local st = H.cst()
    if not st then return end
    pcall(function() if st.altSlotName then S.CC.exitAltMode(st) end end)
    pcall(function() if st.selected then S.CC.closeCraft(st) end end)
end
function H.cardUp(name)
    local st, rd = H.cst(), H.row(name)
    return st ~= nil and rd ~= nil and st.selected == name and rd.ingredients ~= nil and (st.splitFrac or 0) >= 0.99
end
-- the row's offset from the list view's top (px), its zone, the list's geometry and its scroll offset (px)
function H.rel(name)
    local st, g, z = H.cst(), H.geo(), H.rowZone(name)
    if not (st and g and z) then return nil end
    local off = math.floor(((st.scroll and st.scroll.scrollPos) or 0) * math.max(0, (g.totalH or 0) - (g.viewH or 0)))
    return z.y - g.viewY, z, g, off
end
-- the list scrolled so the row sits relT px under the view's top (as far as the list's ends allow)
function H.place(name, relT)
    local st = H.cst()
    local rel, _, g, off = H.rel(name)
    if not (rel and st.scroll and st.scroll.setScrollPos) then return false end
    local span = (g.totalH or 0) - (g.viewH or 0)
    if span <= 0 then return true end
    local want = rel + off - relT
    if want < 0 then want = 0 end
    if want > span then want = span end
    st.scroll:setScrollPos(want / span)
    return true
end
function H.mid()
    local g = H.geo()
    if not g then return 0 end
    return math.max(0, math.floor((g.viewH - H.rowH()) / 2))
end
-- the row's place in the drawn list (1 = the first row drawn) and the group it is in
function H.idx(name)
    local st = H.cst()
    local i = 0
    for _, sec in ipairs((st and st._sections) or {}) do
        if not sec.collapsed then
            for _, rd in ipairs(sec.items or {}) do
                i = i + 1
                if rd.entry and rd.entry.name == name then return i, sec.id end
            end
        end
    end
    return nil, nil
end
function H.count() local st = H.cst(); return #((st and st.filteredCache) or {}) end
-- every listed row's status, by row (to tell a clean shut from one that met a status change)
function H.snapStatus()
    local m = {}
    for _, rd in ipairs((H.cst() and H.cst().filteredCache) or {}) do m[rd] = rd.status end
    return m
end
function H.statusChanges(m)
    local n = 0
    for rd, s in pairs(m or {}) do if rd.status ~= s then n = n + 1 end end
    return n
end
-- the least content offset (px) the row can have once it reads ready: its group's first row, plus every row of the
-- group that reads ready now and comes before it by name (more planks never turn a ready recipe missing)
function H.readyFloor(name)
    local st, me, g = H.cst(), H.row(name), H.geo()
    if not (st and me and g and st._sections) then return 0 end
    local off = math.floor(((st.scroll and st.scroll.scrollPos) or 0) * math.max(0, (g.totalH or 0) - (g.viewH or 0)))
    -- (each row's status as the last sort saw it: between sorts a must-learn row may read otherwise, S.FLICKER)
    local seen = (S.sortSnap and st.filteredCache == S.lastFc) and S.sortSnap or nil
    for _, sec in ipairs(st._sections) do
        local items = sec.items or {}
        local has = false
        for _, rd in ipairs(items) do if rd == me then has = true end end
        if has and items[1] then
            local z = H.rowZone(items[1].entry.name)
            if not z then return 0 end
            local n = 0
            for _, rd in ipairs(items) do
                local s = (seen and seen[rd]) or rd.status
                if rd ~= me and s == "craftable" and rd.entry.displayName < me.entry.displayName then n = n + 1 end
            end
            return math.max(0, z.y - g.viewY + off) + n * z.h
        end
    end
    return 0
end
-- whether the row sits in its place by name among the rows of its own sort group in the sorted list
-- (state.filteredCache): the group is the sort key's (pinned or not, and the status rank, CraftingCore's
-- STATUS_RANK); the row before it in the group comes earlier by name, the row after it later. The old key added the
-- open recipe's missing count, which put its row after every other missing and station row.
S.RANK = { craftable = 0, unlocked = 1, missing = 2, station = 2, locked = 3 }
function H.byName(name)
    local st = H.cst()
    local list = (st and st.filteredCache) or {}
    local pins = {}
    for _, p in ipairs((st and st.pins) or {}) do pins[p] = true end
    -- (each row's status as the sort saw it: a row refresh since may have changed a must-learn row's, S.FLICKER)
    local seen = (S.sortSnap and st and st.filteredCache == S.lastFc) and S.sortSnap or nil
    local function stat(rd) return (seen and seen[rd]) or rd.status end
    local function group(rd) return (pins[rd.entry.name] and 0 or 10) + (S.RANK[stat(rd)] or 3) end
    for i, rd in ipairs(list) do
        if rd.entry.name == name then
            local g, before, after = group(rd), list[i - 1], list[i + 1]
            local okB = before == nil or group(before) ~= g or before.entry.displayName <= rd.entry.displayName
            local okA = after == nil or group(after) ~= g or after.entry.displayName >= rd.entry.displayName
            local function nm(r) return r and ("\"" .. tostring(r.entry.displayName) .. "\" (" .. tostring(stat(r)) .. ")") or "none" end
            return okB and okA, "the row before it " .. nm(before) .. ", the row after it " .. nm(after) .. " (it is " .. tostring(stat(rd)) .. ")"
        end
    end
    return false, "it is not in the sorted list"
end
-- what the open card's slot that takes the type reads: have, need
function H.ingHave(name, ft)
    local rd = H.row(name)
    for _, ing in ipairs((rd and rd.ingredients) or {}) do
        if ing.validTypes and ing.validTypes[ft] and not ing.isTool then return ing.have, ing.need end
    end
    return nil, nil
end

-- ===================================================================== helpers: the game's own amounts
-- a recipe's outputs as the game reads them, the automation-only ones left out (as ZeD and the craft window do):
-- { item = an item output, amt = how many one craft makes (an item's getIntAmount, at least 1; 1 for a fluid) }
function H.gameOuts(recipe)
    local out = {}
    local ok = pcall(function()
        local outs = recipe:getOutputs()
        for i = 0, outs:size() - 1 do
            local o = outs:get(i)
            local auto = false
            pcall(function() auto = o:isAutomationOnly() and true or false end)
            if not auto then
                local e = { item = false, amt = 1 }
                pcall(function()
                    if o:getResourceType() == ResourceType.Item then e.item = true; e.amt = math.max(1, o:getIntAmount()) end
                end)
                out[#out + 1] = e
            end
        end
    end)
    return ok and out or nil
end
function H.amts(list, field)
    local out = {}
    for _, v in ipairs(list or {}) do out[#out + 1] = tostring(v[field]) end
    return table.concat(out, ", ")
end
function H.andList(g)
    local out = {}
    for _, o in ipairs(g or {}) do out[#out + 1] = tostring(o.amt) end
    if #out <= 1 then return out[1] or "?" end
    local last = table.remove(out)
    return table.concat(out, ", ") .. " and " .. last
end
-- the title names the output (ZeD's own test, CC.outputsRepeatTitle)
function H.inTitle(e, def)
    if not (e and def and def.name and def.name ~= "?" and e.displayName) then return false end
    return string.find(string.lower(tostring(e.displayName)), string.lower(tostring(def.name)), 1, true) ~= nil
end
-- one catalog entry against the game: c gathers the counts for the catalog checks
function H.catalogOne(c, e)
    local g = e.recipe and H.gameOuts(e.recipe)
    if not g then c.unread = c.unread + 1; return end
    c.read = c.read + 1
    local defs = e.outputDefs or {}
    local wrong, more = #defs ~= #g, false
    for i, o in ipairs(g) do
        if o.amt > 1 then more = true end
        if not (defs[i] and defs[i].amount == o.amt) then wrong = true end
    end
    if more then c.many = c.many + 1 end
    if wrong then
        c.bad = c.bad + 1
        if #c.badSeen < 4 then c.badSeen[#c.badSeen + 1] = tostring(e.displayName) .. " (ZeD " .. H.amts(defs, "amount") .. ", the game " .. H.amts(g, "amt") .. ")" end
    end
    if #g == 1 and #defs == 1 and g[1].item and H.inTitle(e, defs[1]) then
        local hides = false
        pcall(function() hides = S.CC.outputsRepeatTitle(e) and true or false end)
        if g[1].amt > 1 then
            c.multi = c.multi + 1
            if hides then
                c.multiBad = c.multiBad + 1
                if #c.multiSeen < 4 then c.multiSeen[#c.multiSeen + 1] = tostring(e.displayName) .. " (" .. tostring(g[1].amt) .. ")" end
            end
        else
            c.one = c.one + 1
            if not hides then
                c.oneBad = c.oneBad + 1
                if #c.oneSeen < 4 then c.oneSeen[#c.oneSeen + 1] = tostring(e.displayName) end
            end
        end
    end
end

-- ===================================================================== helpers: the card's drawing, watched
-- ZeD's own drawing of the card, wrapped in memory: the card (CC.renderCraftCard: only this tab's card of the named
-- recipe is read), its section heads (the "Outputs" head opens the Outputs rows, any other head ends them), its slot
-- rows, and the count each row hands the right-aligned text. S.cap.last holds the last drawn frame: head ({ count })
-- or nil when no Outputs section is drawn, rows ({ name, have, need, drawn }); S.cap.cards counts the frames drawn.
-- H.capOff puts the four back (and the put-back does, whatever ran).
function H.capOn(name)
    local c = S.cap
    c.name, c.cards, c.last, c.cur, c.inOut, c.inRow = name, 0, nil, nil, false, nil
    c.state = H.cst()
    if S.capOrig then return true end
    local M, A, CC = ZeD.Molecules, ZeD.Atoms, S.CC
    if not (M.drawSlotRow and M.drawCategoryRow and A.drawTextRight and CC.renderCraftCard) then return false end
    local o = { card = CC.renderCraftCard, slot = M.drawSlotRow, cat = M.drawCategoryRow, tr = A.drawTextRight }
    S.capOrig = o
    c.word = nil
    pcall(function() c.word = ZeD.tr("IGUI_CraftingWindow_Creates") end)
    -- (each wrapper hands on every argument it is given, the ones it does not read too)
    CC.renderCraftCard = function(panel, x, y, w, h, state, config, rd, playerObj, ...)
        local mine = c.state ~= nil and state == c.state and rd ~= nil and rd.entry ~= nil and rd.entry.name == c.name
        if mine then c.cur = { panel = panel, head = nil, heads = 0, rows = {} } else c.cur = nil end
        c.inOut, c.inRow = false, nil
        local r = o.card(panel, x, y, w, h, state, config, rd, playerObj, ...)
        if mine and c.cur then c.last = c.cur; c.cards = c.cards + 1 end
        c.cur, c.inOut, c.inRow = nil, false, nil
        return r
    end
    M.drawCategoryRow = function(panel, x, y, w, text, count, expanded, opts, ...)
        local cur = c.cur
        if cur and panel == cur.panel then
            cur.heads = cur.heads + 1   -- (every section head the card draws: Required, Outputs)
            if c.word ~= nil and text == c.word then
                cur.head = { count = count, open = expanded }
                c.inOut = true
                c.sawOut = true   -- (the watch has seen an Outputs head: it can tell a hidden one from a missed one)
            else
                c.inOut = false
            end
        end
        return o.cat(panel, x, y, w, text, count, expanded, opts, ...)
    end
    M.drawSlotRow = function(panel, x, y, w, data, selected, hovered, opts, ...)
        local cur, rec = c.cur, nil
        if cur and c.inOut and panel == cur.panel and type(data) == "table" then
            rec = { name = tostring(data.displayName or data.name), have = data.have, need = data.need }
            cur.rows[#cur.rows + 1] = rec
        end
        c.inRow = rec
        local r = o.slot(panel, x, y, w, data, selected, hovered, opts, ...)
        c.inRow = nil
        return r
    end
    A.drawTextRight = function(panel, text, x, y, font, color, ...)
        local rec = c.inRow
        if rec then rec.drawn = tostring(text) end   -- (a slot row's last right-aligned text: its count)
        return o.tr(panel, text, x, y, font, color, ...)
    end
    return true
end
function H.capOff()
    local o = S.capOrig
    if not o then return end
    S.capOrig = nil
    S.CC.renderCraftCard = o.card
    ZeD.Molecules.drawSlotRow = o.slot
    ZeD.Molecules.drawCategoryRow = o.cat
    ZeD.Atoms.drawTextRight = o.tr
    S.cap.cur, S.cap.inOut, S.cap.inRow, S.cap.state = nil, false, nil, nil
end
function H.rowsText(last)
    local out = {}
    for _, r in ipairs((last and last.rows) or {}) do out[#out + 1] = "\"" .. tostring(r.name) .. "\" " .. tostring(r.drawn) end
    if #out == 0 then return "none" end
    return table.concat(out, ", ")
end
-- the drawn Outputs against the game: every row's drawn count is the game's amount, in the game's order
function H.yieldRead(last, rd)
    local g = (rd and rd.entry and rd.entry.recipe and H.gameOuts(rd.entry.recipe)) or {}
    local good = last ~= nil and last.head ~= nil and #last.rows == #g and #g > 0
    for i, o in ipairs(g) do
        local r = last and last.rows[i]
        if not (r and r.drawn == tostring(o.amt)) then good = false end
    end
    local head = (last and last.head) and ("an Outputs section drawn (" .. tostring(last.head.count) .. "), its rows read ") or "no Outputs section drawn, rows "
    return good, head .. H.rowsText(last) .. "; the game makes " .. H.amts(g, "amt") .. " (one craft)", g
end
-- a recipe's card opened from its row (the row brought to the middle of the list's view, then clicked), then two of
-- its drawn frames watched: spec.read(the last frame's Outputs, the row). spec.before runs first (things given).
function H.cardRead(spec)
    local T = {}
    Q.step(3, function()
        if not S.ok then return end
        T.rd = H.row(spec.name)
        if not T.rd then Q.skip(spec.label, "the Crafting tab does not list " .. spec.name .. " for this character"); return end
        if spec.before then spec.before() end
        H.place(spec.name, H.mid())
        T.go = true
    end)
    Q.step(3, function() if T.go then H.open(spec.name, spec.label) end end)
    H.wait(6000, function() return not T.go or H.cardUp(spec.name) end, function(ok)
        if not T.go then return end
        if not ok then
            T.go = false
            Q.check(false, spec.label .. ": the recipe's card opens from its row", "the open card: " .. tostring(H.cst() and H.cst().selected))
            return
        end
        if not H.capOn(spec.name) then T.go = false; Q.skip(spec.label, "ZeD's card drawing could not be watched (a drawing function is missing)") end
    end)
    Q.waitFor(2, 900, function() return not T.go or S.cap.cards >= 2 end, function()
        if not T.go then return end
        local last, n = S.cap.last, S.cap.cards
        H.capOff()
        if n < 2 or not last then Q.check(false, spec.label .. ": the open card is drawn", n .. " frames drawn"); return end
        spec.read(last, H.row(spec.name) or T.rd)
    end)
end
-- information for Build: the names ZeD's Outputs rows give Divide Food's outputs, and the game's output mapper's
-- names for what is in reach (the vanilla window's manual-select naming)
function H.mapperSay(label, last)
    local names, used, can = {}, {}, nil
    local e = H.entry(S.BOWLS)
    local ok, err = pcall(function()
        local r = e.recipe
        local l = HandcraftLogic.new(S.p, nil, S.surf)
        l:setContainers(H.gameList() or S.CC.buildContainers(S.p))
        l:setRecipe(r)
        can = l:canPerformCurrentRecipe() and true or false
        local data = l:getRecipeData()
        pcall(function()
            local seen = {}
            local items = data:getAllInputItems()
            for i = 0, items:size() - 1 do
                local ft = tostring(items:get(i):getFullType())
                if not seen[ft] then seen[ft] = 0; used[#used + 1] = ft end
                seen[ft] = seen[ft] + 1
            end
            for i = 1, #used do used[i] = used[i] .. " x" .. tostring(seen[used[i]]) end
        end)
        local outs = r:getOutputs()
        for i = 0, outs:size() - 1 do
            local o = outs:get(i)
            local nm = "?"
            local okm, em = pcall(function()
                local m = o:getOutputMapper()
                if not m then nm = "(no mapper)"; return end
                local it = m:getOutputItem(data, true)
                if it then nm = "\"" .. tostring(it:getDisplayName()) .. "\" (" .. tostring(it:getFullName()) .. ")" else nm = "(none)" end
            end)
            if not okm then nm = "(it threw: " .. tostring(em) .. ")" end
            names[#names + 1] = nm
        end
    end)
    local defs = {}
    for _, d in ipairs((e and e.outputDefs) or {}) do defs[#defs + 1] = "\"" .. tostring(d.name) .. "\"" end
    Q.say("info for Build (B10-2, the names): Divide Food into 4 Bowls, " .. label .. ": ZeD's Outputs rows read " .. H.rowsText(last)
        .. " (its definitions name " .. table.concat(defs, ", ") .. ", the first result the game lists for each output); the game's output mapper"
        .. " for what is in reach names " .. (ok and table.concat(names, ", ") or ("nothing: it threw " .. tostring(err)))
        .. " (the game would start it: " .. tostring(can) .. "; the inputs it took: " .. (#used > 0 and table.concat(used, ", ") or "none") .. ")")
end

-- ===================================================================== helpers: things and the floor
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
-- the game's own list for its craft window (the inventory, the bags, the floor, the open loot containers)
function H.gameList()
    local l = nil
    pcall(function()
        if getPlayerInventory(S.pn) ~= nil and getPlayerLoot(S.pn) ~= nil then l = ISInventoryPaneContextMenu.getContainers(S.p) end
    end)
    return l
end
function H.inReach(ft)
    local n = 0
    pcall(function()
        local l = H.gameList() or S.CC.buildContainers(S.p)
        for i = 0, l:size() - 1 do
            local items = l:get(i):getItems()
            for j = 0, items:size() - 1 do if items:get(j):getFullType() == ft then n = n + 1 end end
        end
    end)
    return n
end
function H.listHolds(c)
    local has = false
    pcall(function()
        local l = H.gameList()
        for i = 0, l:size() - 1 do if l:get(i) == c then has = true end end
    end)
    return has
end
-- his own things of the type, set aside (not one worn, held or on the belt); H.asideBack gives them back
function H.setAside(ft)
    local n = 0
    for _, it in ipairs(H.all()) do
        local t, c, free = nil, nil, false
        pcall(function()
            t, c = it:getFullType(), it:getContainer()
            free = it:getAttachedSlot() == -1 and not it:isEquipped() and S.p:getPrimaryHandItem() ~= it and S.p:getSecondaryHandItem() ~= it
        end)
        if t == ft and c and free and pcall(function() c:Remove(it) end) then
            S.aside[#S.aside + 1] = { it = it, c = c }
            n = n + 1
        end
    end
    return n
end
function H.asideBack()
    local lost = 0
    for _, e in ipairs(S.aside) do
        pcall(function() if e.it:getContainer() == nil then e.c:AddItem(e.it) end end)
        local back = false
        pcall(function() back = e.it:getContainer() ~= nil end)
        if not back then lost = lost + 1 end
    end
    S.aside = {}
    return lost
end
function H.floorChanged() pcall(function() local w = RT.ww(); if w then w._containersDirty = true end end) end
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
-- a square beside him: loaded, a floor, free, no tree, no other object or thing on it, no car, in reach
function H.freeSq(dx, dy)
    local sq = nil
    pcall(function() sq = getCell():getGridSquare(math.floor(S.p:getX()) + dx, math.floor(S.p:getY()) + dy, math.floor(S.p:getZ())) end)
    local good = false
    pcall(function()
        good = sq ~= nil and sq:getFloor() ~= nil and sq:isFree(false) and not sq:HasTree()
            and sq:getObjects():size() <= 1 and sq:getWorldObjects():size() == 0 and sq:getVehicleContainer() == nil
    end)
    if good then pcall(function() good = S.p:getCurrentSquare():canReachTo(sq) and true or false end) end
    return good and sq or nil
end
function H.removeObj(obj)
    local sq = nil
    pcall(function() sq = obj:getSquare() end)
    if not sq then return end
    pcall(function() sq:transmitRemoveItemFromSquare(obj) end)
    pcall(function() if obj:getObjectIndex() >= 0 then sq:RemoveTileObject(obj) end end)
end
function H.stands(obj)
    local up = false
    pcall(function() up = obj ~= nil and obj:getSquare() ~= nil and obj:getObjectIndex() >= 0 end)
    return up
end
-- a table beside him: the first table sprite the game itself takes as a crafting surface
function H.setTable()
    for _, d in ipairs(S.NEAR) do
        local sq = (not S.tableObj) and H.freeSq(d[1], d[2]) or nil
        if sq then
            for _, name in ipairs(S.TABLES) do
                if not S.tableObj then
                    local o = nil
                    pcall(function() o = IsoObject.new(getCell(), sq, name); sq:AddTileObject(o) end)
                    local takes = false
                    if o then pcall(function() takes = S.p:canUseAsGenericCraftingSurface(o) and true or false end) end
                    if o and takes then S.tableObj, S.tableSq, S.tableSprite = o, sq, name elseif o then H.removeObj(o) end
                end
            end
        end
    end
    return S.tableObj ~= nil
end
-- a crate on a free square beside him (the sides first), its container explored
function H.setCrate()
    for _, d in ipairs(S.NEAR) do
        local sq = (not S.crate) and H.freeSq(d[1], d[2]) or nil
        if sq and sq ~= S.tableSq then
            pcall(function()
                local o = IsoObject.new(getCell(), sq, "carpentry_01_16")
                o:createContainersFromSpriteProperties()
                sq:AddTileObject(o)
                S.crateObj, S.crateKeep, S.crate, S.crateSq = o, o, o:getContainer(), sq
            end)
            if S.crateObj and not S.crate then H.removeObj(S.crateObj); S.crateObj = nil end
        end
    end
    if S.crate then pcall(function() S.crate:setExplored(true) end) end
    return S.crate ~= nil
end
-- a thing the script made (RT.give marks what it gives; H.drop and the crate mark theirs the same way)
function H.mark(it) if it then pcall(function() it:getModData().ZeDQA_spawned = true end) end; return it end
function H.mine(it)
    local m = false
    pcall(function() m = it:getModData().ZeDQA_spawned == true end)
    return m
end
-- a thing put on the floor at his feet (the game's own call for a dropped thing); list: where it is kept
function H.drop(ft, list, ox, oy)
    local it = nil
    pcall(function() it = S.p:getCurrentSquare():AddWorldInventoryItem(ft, ox, oy, 0.0) end)
    if it then H.mark(it); list[#list + 1] = it end
    return it
end
-- the game's own loot list (its hidden loot page) read afresh, as a turn or a step makes it read (a crate set or
-- taken away joins or leaves the list the craft logic counts from); ZeD's mod support calls the same
function H.lootRefresh()
    pcall(function()
        local lp = getPlayerLoot(S.pn)
        if lp and lp.refreshBackpacks then lp:refreshBackpacks() end
    end)
end
-- the Crafting tab's search: its field and the tab's state set together (the field's own poll then sees no change,
-- so it does not fire later and reset the list's scroll or drop the rows after the put-back has set them)
function H.setSearch(st, text)
    pcall(function()
        local f = RT.ww()._craftSearch
        f.input:setText(text)
        f._lastText = text
    end)
    st.search, st.filterDirty = text, true
end
function H.unfloor(list)
    for _, it in ipairs(list or {}) do
        pcall(function()
            local wo = it:getWorldItem()
            if wo then
                local sq = wo:getSquare()
                if sq then sq:transmitRemoveItemFromSquare(wo) end
                pcall(function() wo:removeFromWorld() end)
                pcall(function() wo:removeFromSquare() end)
            end
        end)
        -- (one picked up by a stray action: out of whatever holds it)
        pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end)
    end
end
function H.crateBack()
    for _, it in ipairs(S.crateIts) do pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    S.crateIts = {}
    if S.crateObj then H.removeObj(S.crateObj) end
    S.crateObj, S.crate = nil, nil
end
-- whatever the script made that is still carried or beside him (a thing a stray action moved): taken away. Only
-- the script's own things (H.mine): anything else new is counted by the put-back check, never deleted.
function H.wobItem(wo) local it = nil; pcall(function() it = wo:getItem() end); return it end
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
function H.woodwork(n)
    pcall(function() S.p:setPerkLevelDebug(Perks.Woodwork, n) end)
    local w = RT.ww()
    if w then w._craftCache = nil end   -- (the rows are gathered again with the new level)
    local st = H.cst()
    if st then st.filterDirty = true end
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
function H.keepState(st)
    return { show = st.show, showAll = st.showAll, sort = st.sort, cat = st.activeCat, req = st.reqCollapsed, out = st.outCollapsed,
        all = st.allCollapsed, owned = st.ownedOnly, search = st.search or "", sel = st.selected, picks = st.picks, qty = st.qty,
        scroll = (st.scroll and st.scroll.scrollPos) or 0, card = (st.cardScroll and st.cardScroll.scrollPos) or 0, alt = st.altSlotName }
end

-- ===================================================================== setup
Q.step(2, function()
    S.dead = S.p:isDead() and true or false
    if S.dead then Q.check(false, "the character is alive (nothing is run on a dead one)"); return end
    if ZEDQA_HOME then ZEDQA_HOME("vx10_crf") end
    for _, it in ipairs(H.all()) do S.had[it] = true end
    H.snapFloor(S.floorHad)
    pcall(function() S.dirWas = S.p:getDir() end)
    pcall(function() S.woodWas = S.p:getPerkLevel(Perks.Woodwork) end)
    S.pairWas = RT.isOpen()
    RT.pairOpen()
    Events.OnPreUIDraw.Add(H.sortWatch)
    S.watching = true
    local w = RT.ww()
    if w then
        S.tabWas = w._activeTab
        -- (the tab's state as found, before a station's unbinding resets its category and scroll)
        if w._craftState then S.keep = H.keepState(w._craftState) end
    end
    pcall(function()
        local cur = ZeD.Stations and ZeD.Stations.current(S.p)
        if cur then
            S.stWas = cur
            ZeD.Stations.unbind(S.p)
            Q.say("note a station was bound: unbound for the run (the hand's recipes), bound again at the end")
        end
    end)
    Q.say("setup: Carpentry " .. tostring(S.woodWas) .. ", the World window on " .. tostring(S.tabWas) .. ", the pair was open " .. tostring(S.pairWas)
        .. ", screen " .. tostring(getCore():getScreenWidth()) .. "x" .. tostring(getCore():getScreenHeight()))
end)
Q.step(15, function()
    if S.dead then return end
    local w = RT.ww()
    if S.tabWas == nil and w then S.tabWas = w._activeTab end
    H.tab("craft")
end)
H.wait(8000, function() return S.dead or (H.showing() and H.cst() ~= nil and H.data() ~= nil and H.cst().filteredCache ~= nil) end, function(ok)
    if S.dead then return end
    S.ok = Q.check(ok, "the World window's Crafting tab opens with its list", tostring(H.showing()))
    local st = H.cst()
    if not (S.ok and st) then S.ok = false; return end
    S.keep = S.keep or H.keepState(st)
    if S.keep.alt then Q.say("note the tab was found in an ingredient's alternatives list: left for the recipe list, and not put back") end
    H.shut()
    -- Show: All (the missing recipes listed), sorted Craftable, every category, the All group unfolded, Outputs unfolded
    pcall(S.CC.setShow, st, "all")
    st.sort, st.activeCat, st.allCollapsed, st.outCollapsed, st.filterDirty = "craftable", "all", false, false, true
    st._sectionsStale = true
    st.sortMenuOpen, st.showMenuOpen, st.catDropdownOpen, st.stDropdownOpen = false, false, false, false
    -- a search found typed: emptied in its field and the tab together (H.setSearch), and the found one set back in
    -- the put-back (the tab's own search, S.keep.search: the field shows it again)
    local typed = ""
    local wwS = RT.ww()
    local fS = wwS and wwS._craftSearch or nil   -- (asked first: no throw when the field is not there)
    if fS then pcall(function() typed = fS:getText() or "" end) end
    if typed ~= "" or (st.search or "") ~= "" then
        S.searchWas = true
        H.setSearch(st, "")
        Q.say("note a search was typed (the field \"" .. tostring(typed) .. "\", the list's \"" .. tostring(S.keep.search) .. "\"): emptied for the run, set back at the end")
    end
    -- a table beside him (Divide Food and the anvil mold are made on any surface), his own planks aside, Carpentry
    -- at the mold's level (the game's own check: below it the mold is locked and never turns ready)
    H.setTable()
    pcall(function() S.surf = ISEntityUI.FindCraftSurface(S.p, 2) end)
    S.asideN = H.setAside(S.PLANK)
    local e = H.entry(S.MOLD)
    local need = 0
    for _, sd in ipairs((e and e.skillDefs) or {}) do
        local pt = nil
        pcall(function() pt = S.CC.getPerkType(sd.name) end)
        if pt == Perks.Woodwork then need = sd.required or 0 end
    end
    if need > (S.woodWas or 0) then
        S.woodSet = true
        H.woodwork(need)
    end
    Q.say("staged: table " .. tostring(S.tableSprite) .. " beside him (the game finds a crafting surface: " .. tostring(S.surf ~= nil) .. "), "
        .. tostring(S.asideN) .. " of his own planks set aside, Carpentry " .. tostring(S.woodWas) .. (S.woodSet and (" -> " .. need .. " (put back at the end)") or ""))
end)

-- ===================================================================== B10-2: the definitions, the whole catalog
H.wait(8000, function()
    if not S.ok then return true end
    local st = H.cst()
    return st ~= nil and st.filterDirty == false and (st.search or "") == "" and #(st.filteredCache or {}) > 20
end, function(ok)
    if not S.ok then return end
    local d = H.data()
    local flat = d and d.flatRecipes
    if not flat then Q.check(false, "B10-2: ZeD's recipe catalog can be read (the Crafting tab's rows)"); return end
    Q.say("the list: " .. H.count() .. " rows (Show: All, sorted Craftable), settled " .. tostring(ok))
    local c = { read = 0, unread = 0, many = 0, bad = 0, badSeen = {}, multi = 0, multiBad = 0, multiSeen = {}, one = 0, oneBad = 0, oneSeen = {} }
    for _, e in ipairs(flat) do H.catalogOne(c, e) end
    Q.check(c.bad == 0 and c.many > 0, "B10-2: every recipe's outputs carry how many one craft makes, as the game reads it (" .. c.many .. " recipes make more than one of something)",
        c.read .. " recipes read, " .. c.bad .. " whose outputs differ from the game's" .. ((c.bad > 0) and (": " .. table.concat(c.badSeen, "; ")) or "")
        .. ((c.unread > 0) and (", " .. c.unread .. " the game would not read") or ""))
    Q.check(c.multi > 0 and c.multiBad == 0, "B10-2: a recipe whose one output makes more than one keeps its Outputs section though its title names the output ("
        .. c.multi .. " such recipes), so the amount shows",
        c.multiBad .. " hide it" .. ((c.multiBad > 0) and (": " .. table.concat(c.multiSeen, "; ")) or ""))
    Q.check(c.one > 0 and c.oneBad == 0, "B10-2 (a guard): a recipe whose one output of one is named in its title still hides its Outputs section (" .. c.one .. " such recipes)",
        c.oneBad .. " show it" .. ((c.oneBad > 0) and (": " .. table.concat(c.oneSeen, "; ")) or ""))
    -- the four named, by name (one this game's catalog lacks is said as a SKIP of its own, not passed with the rest)
    local seen, good, titles, gone = {}, true, {}, {}
    for _, nm in ipairs(S.NAMED) do
        local e = H.entry(nm)
        if not e then
            gone[#gone + 1] = nm
        else
            titles[#titles + 1] = tostring(e.displayName)
            local g = H.gameOuts(e.recipe) or {}
            local same = #g > 0 and #(e.outputDefs or {}) == #g
            for i, o in ipairs(g) do if not (e.outputDefs[i] and e.outputDefs[i].amount == o.amt) then same = false end end
            if not same then good = false end
            seen[#seen + 1] = tostring(e.displayName) .. ": ZeD " .. H.amts(e.outputDefs, "amount") .. ", the game " .. H.amts(g, "amt") .. " (its script " .. tostring(S.SCRIPT[nm]) .. ")"
        end
    end
    if #gone > 0 then
        Q.skip("B10-2: the named recipes' definitions, " .. table.concat(gone, ", "), "not in this game's recipe catalog")
    end
    if #titles > 0 then
        Q.check(good, "B10-2: " .. table.concat(titles, ", ") .. ": ZeD's definitions carry the game's amounts", table.concat(seen, "; "))
    end
end)

-- ===================================================================== B10-2: the open card's Outputs rows
-- Divide Food into 4 Bowls, with 4 bowls and a pot of soup carried (the names, for Build, read on the same frames)
H.cardRead({ name = S.BOWLS, label = "B10-2, Divide Food into 4 Bowls",
    before = function()
        S.bowls = {}
        for _ = 1, 4 do
            local it = RT.give("Base.Bowl")
            if it then S.bowls[#S.bowls + 1] = it end
        end
        S.soup = RT.give("Base.PotOfSoup")
        H.floorChanged()
    end,
    read = function(last, rd)
        local good, detail, g = H.yieldRead(last, rd)
        Q.check(good, "B10-2: " .. tostring(rd.entry.displayName) .. ": the open card's Outputs rows read how many one craft makes, " .. H.andList(g)
            .. " (the old card: 1 on every row)", detail)
        RT.bounds(Q, "the Crafting tab with a card open")
        H.mapperSay("4 bowls and a pot of soup carried", last)
    end })
-- the same card with a saucepan of rice in place of the soup (information only)
Q.step(3, function()
    S.riceGo = false
    if not (S.ok and H.cst() and H.cst().selected == S.BOWLS) then return end
    H.takeOne(S.soup)
    S.rice = RT.give("Base.RicePan")
    H.floorChanged()
    S.riceGo = S.rice ~= nil
end)
Q.waitMs(600)
Q.step(1, function() if S.riceGo then S.riceGo = H.capOn(S.BOWLS) end end)
Q.waitFor(2, 900, function() return not S.riceGo or S.cap.cards >= 2 end, function()
    if not S.riceGo then return end
    local last = S.cap.last
    H.capOff()
    H.mapperSay("4 bowls and a saucepan of rice (Base.RicePan) carried", last)
end)
H.cardRead({ name = S.CANDY, label = "B10-2, Open Candy Package",
    read = function(last, rd)
        local good, detail, g = H.yieldRead(last, rd)
        Q.check(good, "B10-2: " .. tostring(rd.entry.displayName) .. ": the open card's Outputs rows read how many one craft makes, " .. H.andList(g)
            .. " (the old card: 1 on every row)", detail)
    end })
H.cardRead({ name = S.STONES, label = "B10-2, Break Large Stone into Stones",
    read = function(last, rd)
        local good, detail, g = H.yieldRead(last, rd)
        Q.check(good, "B10-2: " .. tostring(rd.entry.displayName) .. ": its one output, named in the title, makes " .. H.andList(g)
            .. ": the open card shows its Outputs section and the row reads " .. H.andList(g) .. " (the old card hid the section: the amount showed nowhere)", detail)
    end })
H.cardRead({ name = S.COKE, label = "B10-2, Make Coke",
    read = function(last, rd)
        local good, detail, g = H.yieldRead(last, rd)
        Q.check(good, "B10-2: " .. tostring(rd.entry.displayName) .. ": its one output, named in the title, makes " .. H.andList(g)
            .. ": the open card shows its Outputs section and the row reads " .. H.andList(g) .. " (the old card hid the section)", detail)
    end })
-- a single output of one named in the title (the anvil mold: one Wooden Blacksmith Anvil Mold): the section stays hidden
H.cardRead({ name = S.MOLD, label = "B10-2, the anvil mold",
    read = function(last, rd)
        local g = H.gameOuts(rd.entry.recipe) or {}
        local defs = rd.entry.outputDefs or {}
        local single = #g == 1 and g[1].amt == 1 and #defs == 1 and H.inTitle(rd.entry, defs[1])
        if not single then
            Q.skip("B10-2 (a guard): a single output of one named in the title hides the Outputs section on the open card",
                tostring(rd.entry.displayName) .. " is no such recipe in this game (the game makes " .. H.amts(g, "amt") .. ", named " .. H.amts(defs, "name") .. ")")
            return
        end
        -- (a hidden section is told from a missed one only when the watch saw this card's Required head and an
        -- Outputs head on a card before it: else "no Outputs section" could be the watch's blindness)
        if not (S.cap.sawOut and (last.heads or 0) >= 1) then
            Q.skip("B10-2 (a guard): a single output of one named in the title hides the Outputs section on the open card",
                "the watch of the card's drawing saw " .. tostring(last.heads or 0) .. " section heads on this card and an Outputs head before it "
                .. tostring(S.cap.sawOut == true) .. ": it cannot tell a hidden section from a missed one")
            return
        end
        Q.check(last.head == nil and #last.rows == 0, "B10-2 (a guard): " .. tostring(rd.entry.displayName) .. " makes one " .. tostring(defs[1].name)
            .. ", named in its title: the open card still hides its Outputs section",
            ((last.head == nil) and "no Outputs section drawn" or ("an Outputs section drawn, rows " .. H.rowsText(last)))
            .. " (" .. tostring(last.heads) .. " section heads drawn on the card)")
    end })
-- the card shut, the bowls, the soup and the rice taken back (the anvil mold's staging counts no food)
Q.step(3, function()
    if not S.ok then return end
    H.shut()
    for _, it in ipairs(S.bowls or {}) do H.takeOne(it) end
    H.takeOne(S.soup)
    H.takeOne(S.rice)
    H.floorChanged()
end)

-- ===================================================================== B10-4: the staging (W24: one plank carried)
Q.step(3, function()
    if not S.ok then return end
    S.b4 = {}
    local b = S.b4
    if not H.row(S.MOLD) then Q.skip("B10-4: the open recipe keeps its place in the list", "the Crafting tab does not list the anvil mold (" .. S.MOLD .. ")"); return end
    local pinned = false
    pcall(function() pinned = S.CC.isPinned(RT.ww(), S.MOLD, "_craftPins") and true or false end)
    if pinned then Q.skip("B10-4: the open recipe keeps its place in the list", "the anvil mold is pinned: its row sits in the Pinned group, which the sort does not order"); return end
    H.shut()
    for _, ft in ipairs({ "Base.Hammer", "Base.Saw", "Base.Nails", S.PLANK }) do RT.give(ft) end
    H.floorChanged()
    b.go = true
end)
-- the game's answer settled: the mold missing (asked of the game, not ZeD's guess) and no card open, held for 2.6 s
-- (two of the game's scans)
H.frames(15000, 2600, function()
    local b = S.b4
    if not (b and b.go) then return "now" end
    local rd = H.row(S.MOLD)
    return rd ~= nil and rd.fromLogic == true and rd.status == "missing" and H.cst().selected == nil
end, function(ok)
    local b = S.b4
    if not (b and b.go) then return end
    local rd = H.row(S.MOLD)
    local idx, sec = H.idx(S.MOLD)
    b.planks = H.inReach(S.PLANK)
    local why = nil
    if not ok then
        why = "the anvil mold did not read missing from the game for 2.6 s with no card open (status " .. tostring(rd and rd.status) .. ", answered by the game " .. tostring(rd and rd.fromLogic)
            .. ", Carpentry " .. tostring(S.p:getPerkLevel(Perks.Woodwork)) .. ")"
    elseif b.planks ~= 1 then
        why = "the game's list holds " .. b.planks .. " planks, not the one given (planks in reach that are not his own)"
    elseif sec ~= "all" then
        why = "its row is in the " .. tostring(sec) .. " group, which the sort does not order"
    end
    if not why and not H.geo() then why = "the list drew no geometry (state._listGeo)" end
    if why then b.go = false; Q.skip("B10-4: the open recipe keeps its place in the list", why); return end
    local g, h = H.geo(), H.rowH()
    local floor = H.readyFloor(S.MOLD)
    b.relT = math.max(0, math.min(math.floor(g.viewH / 3), floor, g.viewH - h))
    Q.say("B10-4: the anvil mold settled as missing (1 plank of 4 in reach), row " .. tostring(idx) .. " of " .. H.count() .. "; it is placed "
        .. H.n(b.relT) .. " px under the list's top (its least offset once ready: " .. H.n(floor) .. " px; the view " .. H.n(g.viewH) .. " px, a row " .. H.n(h) .. " px)")
    pcall(function()
        local F = ZeD.Input and ZeD.Input.Focus
        local fz = F and F.getFocusedZone and F.getFocusedZone(RT.ww())
        if fz and fz.zone == "worldTabContent" then Q.say("note the controller's focus is in the tab's content: its scroll-follow could move the list too") end
    end)
end)

-- ===================================================================== B10-4: the card opened at a calm moment
-- The anvil mold's card opened by a click on its row at a calm moment: no card open and the rows clear of the last
-- card's missing count (CC.refreshRow drops it once a second), the list sorted afresh with no card open (on the old
-- code that puts the row back in its place by name), then, with the list's next row refresh and next scan both
-- S.RUNWAY ms away and no row changed since the last sort (H.calm), the row placed b.relT px under the list's top and
-- clicked. What comes next (the shut, or the first change) falls before that refresh and scan: no other sort and no
-- status change between. T.go: this one runs; T.open: the card opened (T.fcOpen, T.s0: the list and the sort count
-- at the click).
function H.calmOpen(T, label)
    Q.step(2, function() if T.go then H.shut() end end)
    H.frames(5000, 0, function()
        if not T.go then return "now" end
        local rd = H.row(S.MOLD)
        return H.cst().selected == nil and rd ~= nil and (rd.missingCount or 0) == 0
    end, function()
        if T.go then H.cst().filterDirty = true end
    end)
    H.frames(20000, 0, function()
        if not T.go then return "now" end
        return H.cst().filterDirty == false and H.calm(S.RUNWAY)
    end, function(ok)
        if not T.go then return end
        if not ok then
            T.go = false
            Q.skip(label, "no calm moment came in 20 s (the list's next row refresh and scan both " .. S.RUNWAY
                .. " ms away, no row changed since the list was last sorted): the card could not be opened and shut clear of them")
            return
        end
        H.place(S.MOLD, S.b4.relT)
        T.placed = true
    end)
    Q.step(1, function()
        if not (T.go and T.placed) then return end
        local st = H.cst()
        T.fcOpen, T.s0, T.rel0, T.openAt = st.filteredCache, S.sorts, H.rel(S.MOLD), getTimestampMs()
        T.open = H.open(S.MOLD, label)
        if not T.open then
            T.go = false
            Q.check(false, "B10-4: the anvil mold's card opens from its row", "the open card: " .. tostring(st.selected))
        end
    end)
end

-- ===================================================================== B10-4: the card shut leaves the row in place
-- (try 2 runs only when try 1 met another sort or a status change while the card was open)
function H.closeTry(n)
    local T = {}
    Q.step(1, function()
        local b = S.b4
        if not (b and b.go) or b.closeDone or (n == 2 and not b.retry) then return end
        T.go = true
    end)
    H.calmOpen(T, "B10-4, the card shut")
    H.frames(4000, 0, function()
        if not T.go then return "now" end
        local rd = H.row(S.MOLD)
        -- (the old code's jump needs the card's missing count still on the row at the shut's sort: the calm open
        -- keeps the shut clear of the row refresh that drops it)
        return H.cardUp(S.MOLD) and rd ~= nil and (rd.missingCount or 0) >= 1
    end, function(ok)
        if not T.go then return end
        local st, rd = H.cst(), H.row(S.MOLD)
        if not ok then
            T.go = false
            Q.check(false, "B10-4: the anvil mold's card opens and counts what it lacks", "the open card " .. tostring(st.selected) .. ", missing " .. tostring(rd and rd.missingCount))
            return
        end
        -- (clean: no other sort since the click, and every row reads as the last sort saw it)
        T.clean = st.filteredCache == T.fcOpen and H.sameSinceSort()
        T.rel, T.z = H.rel(S.MOLD)
        T.idx = H.idx(S.MOLD)
        T.snap = H.snapStatus()
        T.fc, T.pos, T.miss = st.filteredCache, st.scroll.scrollPos, rd.missingCount
        T.shutAt = getTimestampMs()
        -- (KISS #47, CraftingCore.handleRecipeClick: a second click on the open row leaves its card open; another row or
        -- Escape, CC.takeEscape, shuts it. The click is made and must keep the card; Escape then shuts it, with the
        -- same re-sort the old click's shut made: closeCraft marks the list for a new sort)
        local z = H.rowZone(S.MOLD)
        if z and H.inView(z) then
            H.click(z, "B10-4, a second click on the open row")
            if st.selected ~= S.MOLD then
                T.go = false
                Q.check(false, "B10-4: a second click on the open recipe's row leaves its card open (KISS #47)", "the open card: " .. tostring(st.selected))
                return
            end
        else
            Q.say("note B10-4: the mold's row is out of view with its card open (" .. H.n(T.rel) .. " px): no second click, Escape alone")
        end
        local okE, took = pcall(S.CC.takeEscape)
        if not (okE and took) then
            pcall(S.CC.closeCraft, st)
            Q.say("note B10-4: Escape did not take the card (" .. tostring(took) .. "): it is shut from code")
        end
        if st.selected ~= nil then T.go = false; Q.check(false, "B10-4: Escape shuts the open recipe's card (KISS #47)", "the open card: " .. tostring(st.selected)) end
    end)
    H.frames(4000, 0, function()
        if not T.go then return "now" end
        local st = H.cst()
        -- (the statuses the shut's own sort saw, read the first frame after it: a row refresh later is not the shut's)
        if st.filteredCache ~= T.fc and T.changes == nil then T.changes = H.statusChanges(T.snap) end
        return st.filteredCache ~= T.fc and st.filterDirty == false and (st.splitFrac or 0) <= 0.01
    end, function(ok)
        if not T.go then return end
        local b, st = S.b4, H.cst()
        local rel, z, g = H.rel(S.MOLD)
        local idx = H.idx(S.MOLD)
        local changes = T.changes or H.statusChanges(T.snap)
        local clean = T.clean and changes == 0
        if n == 1 and not clean then
            b.retry = true
            Q.say("note B10-4, the card shut, try 1: " .. (T.clean and "" or "the list was sorted again, or a row changed status, while the card was open; ") .. changes
                .. " rows changed status at the shut: not a clean shut, tried again at another calm moment")
            return
        end
        b.closeDone = true
        local good = ok and rel ~= nil and T.rel ~= nil and math.abs(rel - T.rel) <= S.TOL and H.inViewRel(rel, g, z.h)
        Q.check(good, "B10-4: shutting the card leaves its recipe's row where it was in the list (no jump down to the missing rows' end)",
            "offset " .. H.n(T.rel) .. " px with the card open (" .. H.n(T.rel0) .. " px before it opened), " .. H.n(rel) .. " px after it shut; row "
            .. tostring(T.idx) .. " -> " .. tostring(idx) .. " of " .. H.count() .. "; the scroll " .. H.f4(T.pos) .. " -> " .. H.f4(st.scroll.scrollPos)
            .. "; the card counted " .. tostring(T.miss) .. " missing; open " .. H.n((T.shutAt or 0) - (T.openAt or 0)) .. " ms"
            .. (clean and "" or ("; not clean either (" .. changes .. " status changes): the check is not sharp")))
        local inPlace, around = H.byName(S.MOLD)
        Q.check(inPlace, "B10-4: after the card shut, the recipe keeps its place by name among the missing rows (the sort no longer sends it after them)", around)
    end)
end
H.closeTry(1)
H.closeTry(2)

-- ===================================================================== B10-4: re-sorts with the card open
-- (opened at a calm moment as the shut check's card, so the old code too has the row in its place by name when the
-- first change comes; S.fl: the card's T)
S.fl = {}
Q.step(1, function() local b = S.b4; if b and b.go then S.fl.go = true end end)
H.calmOpen(S.fl, "B10-4: the open recipe's row through the changes (2 planks dropped, the crate, the crate's planks back)")
H.frames(4000, 0, function()
    if not (S.fl.go and S.fl.open) then return "now" end
    return H.cardUp(S.MOLD)
end, function(ok)
    if not (S.fl.go and S.fl.open) then return end
    if not ok then S.fl.open = false; Q.check(false, "B10-4: the anvil mold's card opens", "the open card: " .. tostring(H.cst().selected)); return end
    local rel = H.rel(S.MOLD)
    local have, need = H.ingHave(S.MOLD, S.PLANK)
    Q.say("B10-4: the mold's card open (planks " .. tostring(have) .. "/" .. tostring(need) .. "), its row " .. H.n(rel) .. " px under the list's top, row "
        .. tostring(H.idx(S.MOLD)) .. " of " .. H.count())
end)
-- one change: spec.act(T) changes what is in reach; spec.mid(T) queues more steps; then the game's scan and its
-- re-sort are waited for (the list sorted since the change and spec.want(the row) holding for S.SETTLE ms: one scan
-- more) and the row's offset is read again
S.SETTLE = 1500
function H.flip(spec)
    local T = {}
    Q.step(2, function()
        local b = S.b4
        if not (b and b.go and S.fl.go and S.fl.open) then return end
        local st = H.cst()
        if st.selected ~= S.MOLD then Q.check(false, spec.label, "the mold's card is no longer open (the open card: " .. tostring(st.selected) .. ")"); return end
        T.rel = H.rel(S.MOLD)
        if not T.rel then Q.check(false, spec.label, "the mold's row has no place in the list"); return end
        T.idx = H.idx(S.MOLD)
        T.fc, T.pos, T.s0 = st.filteredCache, st.scroll.scrollPos, S.sorts
        -- (a sort since the card opened, before the first change: on the old code the row had already jumped then)
        if spec.first and (S.fl.s0 or S.sorts) ~= S.sorts then
            Q.say("note " .. spec.label .. ": the list was sorted again " .. (S.sorts - S.fl.s0) .. " times while the card was open, before the planks: on the old code this check is not sharp")
        end
        T.go = true
        spec.act(T)
    end)
    if spec.mid then spec.mid(T) end
    H.frames(spec.ms, S.SETTLE, function()
        if not T.go then return "now" end
        return H.cst().filteredCache ~= T.fc and spec.want(H.row(S.MOLD))
    end, function(ok)
        if not T.go then return end
        local st = H.cst()
        local rel, z, g, off = H.rel(S.MOLD)
        local idx = H.idx(S.MOLD)
        local rd = H.row(S.MOLD)
        local have, need = H.ingHave(S.MOLD, S.PLANK)
        local sorts = S.sorts - T.s0
        local state = "the mold " .. tostring(rd and rd.status) .. ", planks " .. tostring(have) .. "/" .. tostring(need)
        if st.filteredCache == T.fc and sorts == 0 then
            Q.skip(spec.label, "the list was not sorted again within " .. H.n(spec.ms / 1000) .. " s: no recipe changed status (" .. state .. ")")
            return
        end
        if not rel then Q.check(false, spec.label, "the mold's row is gone from the list (" .. state .. ")"); return end
        -- where a perfect hold leaves it: the old offset, unless the list's ends stop the scroll
        local cy = rel + off
        local span = math.max(1, (g.totalH or 0) - (g.viewH or 0))
        local want = cy - T.rel
        if want < 0 then want = 0 end
        if want > span then want = span end
        local exp = cy - want
        local tol = math.max(S.TOL, sorts)
        local good = math.abs(rel - exp) <= tol and H.inViewRel(rel, g, z.h)
        local detail = "offset " .. H.n(T.rel) .. " px before, " .. H.n(rel) .. " px after" .. ((exp ~= T.rel) and (" (the list's end allows " .. H.n(exp) .. ")") or "")
            .. " (within " .. tol .. "); row " .. tostring(T.idx) .. " -> " .. tostring(idx) .. " of " .. H.count()
            .. ((T.idx == idx) and " (its place in the list did not change: nothing to hold)" or "")
            .. "; " .. sorts .. " re-sorts; the scroll " .. H.f4(T.pos) .. " -> " .. H.f4(st.scroll.scrollPos) .. "; " .. state
        if ok then
            Q.check(good, spec.label, detail)
        else
            Q.skip(spec.label, spec.wantWord .. " did not happen within " .. H.n(spec.ms / 1000) .. " s (" .. state .. "); the re-sorts that did happen are scored below")
            Q.check(good, "B10-4: the list sorted again with the card open: the open recipe's row stays where it was on screen", detail)
        end
        -- (the key half alone, where the mold is missing: the old key sent the open recipe after the other missing rows)
        if spec.order and rd and rd.status == "missing" then
            local inPlace, around = H.byName(S.MOLD)
            Q.check(inPlace, "B10-4: " .. spec.order .. ", the open recipe keeps its place by name among the missing rows (the sort no longer sends it after them)", around)
        end
    end)
end
-- two more planks at his feet (the crate's stand-in when the game's list never takes the crate in)
function H.extraFloor()
    H.drop(S.PLANK, S.extraIts, 0.3, 0.7)
    H.drop(S.PLANK, S.extraIts, 0.7, 0.3)
    H.floorChanged()
end
-- W25: two planks on the floor at his feet; the mold still missing (3 of 4), other recipes turn ready
H.flip({ label = "B10-4: two planks dropped at his feet (other recipes turn ready, the list is sorted again): the open recipe's row stays where it was on screen",
    wantWord = "the mold reading 3 planks, still missing,", ms = 12000, first = true, order = "two planks dropped",
    act = function(T)
        H.drop(S.PLANK, S.floorIts, 0.35, 0.45)
        H.drop(S.PLANK, S.floorIts, 0.65, 0.6)
        H.floorChanged()
        Q.say("B10-4: " .. #S.floorIts .. " planks put on the floor at his feet")
    end,
    want = function(rd) return rd ~= nil and rd.status == "missing" and H.ingHave(S.MOLD, S.PLANK) == 3 end })
-- W25: two more in a crate in reach; the mold itself turns ready
H.flip({ label = "B10-4: two more planks in a crate in reach (the open recipe itself turns ready): its row stays where it was on screen",
    wantWord = "the mold turning ready", ms = 15000,
    act = function(T)
        if H.setCrate() then
            for _ = 1, 2 do
                local it = nil
                pcall(function() it = S.crate:AddItem(S.PLANK) end)
                if it then S.crateIts[#S.crateIts + 1] = H.mark(it) end
            end
            -- (what the game fires when a thing with a container is put into the world)
            pcall(function() triggerEvent("OnContainerUpdate") end)
        end
        H.floorChanged()
        T.crate = S.crate ~= nil and #S.crateIts == 2
        Q.say("B10-4: a crate with " .. #S.crateIts .. " planks set beside him: " .. tostring(T.crate))
        if not T.crate then
            -- (a crate short of its 2 planks goes: the count must read 5, then 3 when the stand-in's go)
            H.crateBack()
            S.b4.fallback = true
            H.extraFloor()
            Q.say("note B10-4: no crate with 2 planks could be set: 2 more planks put at his feet instead")
        end
    end,
    -- the game's loot list (what the tab counts from) takes a new container in when he turns or steps (a hidden
    -- loot page refreshes only then): turned to the crate if it is not in after 1.5 s, then back as he stood
    mid = function(T)
        H.wait(1500, function() return not (T.go and T.crate) or H.listHolds(S.crate) end, function(ok)
            if not (T.go and T.crate) then return end
            T.still = ok
            if not ok then
                local was, to = nil, H.dirTo(S.crateSq)
                pcall(function() was = S.p:getDir() end)
                pcall(function() S.p:setDir(to) end)
                -- (already facing it, the turn changes nothing the page looks at: the list read as the turn makes it)
                if was == to then H.lootRefresh() end
            end
        end)
        H.wait(3000, function() return not (T.go and T.crate) or H.listHolds(S.crate) end, function(ok)
            if not (T.go and T.crate) then return end
            pcall(function() if S.dirWas then S.p:setDir(S.dirWas) end end)
            Q.say("B10-4: the game's loot list holds the crate: " .. tostring(ok) .. (T.still and " (with him standing still)" or " (once he had turned to it)"))
            if not ok then
                -- (the crate goes first: one joining the list later would make the count 7, and taking the stand-in's
                -- planks back would leave the mold ready)
                H.crateBack()
                S.b4.fallback = true
                H.extraFloor()
                Q.say("note B10-4: the crate never reached the game's list: it is taken away, 2 more planks put at his feet instead")
            end
        end)
    end,
    want = function(rd) return rd ~= nil and rd.status == "craftable" end })
-- the crate's planks taken back (or the stand-in's); the mold turns missing again (3 of 4)
H.flip({ label = "B10-4: the crate's planks taken back (the open recipe turns missing again): its row stays where it was on screen",
    wantWord = "the mold reading 3 planks again, missing,", ms = 12000, order = "the crate's planks taken back",
    act = function(T)
        if S.b4.fallback then
            H.unfloor(S.extraIts)
            S.extraIts = {}
        else
            for _, it in ipairs(S.crateIts) do pcall(function() S.crate:Remove(it) end) end
            S.crateIts = {}
            pcall(function() triggerEvent("OnContainerUpdate") end)
        end
        H.floorChanged()
    end,
    want = function(rd) return rd ~= nil and rd.status == "missing" and H.ingHave(S.MOLD, S.PLANK) == 3 end })
Q.step(3, function() if S.b4 and S.b4.go then H.shut() end end)

-- ===================================================================== put back
Q.mark()
-- (every line stands alone: one that throws does not stop the next)
function H.unwatch() pcall(function() if S.watching then Events.OnPreUIDraw.Remove(H.sortWatch); S.watching = false end end) end
Q.step(3, function()
    pcall(H.capOff)
    -- (the sort watch stays on until the scroll is read back: the calm moment for it reads the last sort)
    if S.dead then H.unwatch(); return end
    pcall(H.shut)
    pcall(function() H.unfloor(S.floorIts); S.floorIts = {} end)
    pcall(function() H.unfloor(S.extraIts); S.extraIts = {} end)
    pcall(H.crateBack)
    pcall(function() if S.tableObj then H.removeObj(S.tableObj) end end)
    pcall(RT.takeBack)
    pcall(function() S.asideLost = H.asideBack() end)
    pcall(function() if S.woodSet then H.woodwork(S.woodWas or 0) end end)
    -- (a station bound again resets the tab's category and scroll on its next drawn frame, CraftingTab's
    -- syncStation: the tab's choices are set after that, below)
    pcall(function() if S.stWas then ZeD.Stations.bind(S.p, S.stWas) end end)
    pcall(function() if S.dirWas then S.p:setDir(S.dirWas) end end)
    pcall(function() triggerEvent("OnContainerUpdate") end)
    pcall(H.floorChanged)
    -- (the game's loot list drops the crate taken away, as his next turn or step would make it)
    pcall(H.lootRefresh)
end)
-- the Crafting tab's choices as found: Show, Sort, category, folds, Owned only, the search (its field too)
Q.step(4, function()
    if S.dead then return end
    pcall(function()
        local st, k = H.cst(), S.keep
        if not (st and k) then return end
        st.show, st.showAll, st.sort, st.activeCat = k.show, k.showAll, k.sort, k.cat
        st.reqCollapsed, st.outCollapsed, st.allCollapsed, st.ownedOnly = k.req and true or false, k.out and true or false, k.all and true or false, k.owned and true or false
        st.qty, st.filterDirty, st._sectionsStale = k.qty or 1, true, true
        st.sortMenuOpen, st.showMenuOpen, st.catDropdownOpen, st.stDropdownOpen = false, false, false, false
        if S.searchWas then H.setSearch(st, k.search or "") end
    end)
end)
-- the list settled as found: filtered again, and the game's scan has answered for what was taken away (2 s: more
-- than one scan); then the card that was open, its picks and amount
H.frames(10000, 2000, function()
    local st, k = H.cst(), S.keep
    if S.dead or not (st and k) then return "now" end
    return (st.search or "") == (k.search or "") and st.filterDirty == false
end, function(ok)
    if S.dead then return end
    pcall(function() S.swept = H.sweep() end)
    local st, k = H.cst(), S.keep
    if not (st and k) then return end
    if not ok then Q.say("note put back: the Crafting tab's list was not filtered again within 10 s: the card and scroll are set back anyway") end
    pcall(function() if k.sel and st.selected ~= k.sel then S.CC.openCraft(st, k.sel) end end)
    pcall(function() st.picks = k.picks or {}; st.qty = k.qty or 1 end)
end)
-- the scroll set back at a calm moment (H.calm): with a card open, a sort keeps the card's row where it was by
-- moving the scroll, so none may fall between the scroll set back and its reading 3 frames on
H.frames(8000, 0, function()
    local st, k = H.cst(), S.keep
    if S.dead or not (st and k) then return "now" end
    return H.calm(400)
end, function()
    local st, k = H.cst(), S.keep
    if S.dead or not (st and k) then return end
    pcall(function() st.scroll:setScrollPos(k.scroll or 0) end)
    pcall(function() st.cardScroll:setScrollPos(k.card or 0) end)
end)
Q.step(3, function()
    H.unwatch()
    if S.dead then return end
    local st = H.cst()
    S.scrollNow = st and st.scroll and st.scroll.scrollPos
    S.stateNow = st and H.keepState(st)
    -- the World window's tab as found (the Crafting tab's state is read first: a hidden tab draws nothing)
    local t = S.tabWas
    if t ~= "craft" then pcall(H.tab, t or "loot") end
end)
Q.step(5, function()
    if S.dead then return end
    if S.pairWas == false then pcall(RT.pairShut) end
end)
Q.step(10, function()
    H.unwatch()
    if S.dead then return end
    -- (the script's things still carried or on the floor, his own things no longer carried; anything else new is
    -- said, not counted and never deleted: the script did not make it)
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
            if #goneSeen < 3 then
                local ft = "?"
                pcall(function() ft = tostring(it:getFullType()) end)
                goneSeen[#goneSeen + 1] = ft
            end
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
    Q.check(left == 0 and gone == 0 and floor == 0 and (S.asideLost or 0) == 0, "put back: he carries what he carried at the start, nothing of the script's left on him or on the floor beside him",
        tostring(S.swept) .. " stray things of the script's taken away, " .. left .. " of the script's still carried, " .. gone .. " of his own things not carried"
        .. ((gone > 0) and (" (" .. table.concat(goneSeen, ", ") .. ")") or "") .. ", " .. floor
        .. " of the script's on the floor, " .. tostring(S.asideLost or 0) .. " of his own planks not back"
        .. (((otherC + other) > 0) and ("; new and not the script's, left alone: " .. otherC .. " carried, " .. other .. " on the floor nearby") or ""))
    local stood = (H.stands(S.tableObj) and 1 or 0) + (H.stands(S.crateKeep) and 1 or 0)
    local hooks = S.CC.renderCraftCard == S.orig.card and ZeD.Molecules.drawSlotRow == S.orig.slot and ZeD.Molecules.drawCategoryRow == S.orig.cat
        and ZeD.Atoms.drawTextRight == S.orig.tr
    Q.check(stood == 0 and hooks, "put back: no table or crate left beside him, ZeD's card drawing as found",
        stood .. " standing, the four drawing functions as found " .. tostring(hooks))
    local wood = nil
    pcall(function() wood = S.p:getPerkLevel(Perks.Woodwork) end)
    Q.check(wood == S.woodWas, "put back: Carpentry as found", tostring(wood) .. " (found " .. tostring(S.woodWas) .. ")")
    local k, n = S.keep, S.stateNow
    if k and n then
        local same = n.show == k.show and n.showAll == k.showAll and n.sort == k.sort and n.cat == k.cat and (n.search or "") == (k.search or "")
            and n.sel == k.sel and (n.all and true or false) == (k.all and true or false) and (n.out and true or false) == (k.out and true or false)
            and (n.req and true or false) == (k.req and true or false) and (n.owned and true or false) == (k.owned and true or false)
        -- (the search field shows the list's search again)
        local field = nil
        local wwF = RT.ww()
        local fF = wwF and wwF._craftSearch or nil   -- (asked first: no throw when the field is not there)
        if fF then pcall(function() field = fF:getText() end) end
        if S.searchWas and field ~= nil and field ~= (k.search or "") then same = false end
        local scr = S.scrollNow ~= nil and math.abs(S.scrollNow - (k.scroll or 0)) < 0.0005
        Q.check(same and scr, "put back: the Crafting tab's Show, Sort, category, folds, search, open card and scroll as found",
            "Show " .. tostring(n.show) .. "/" .. tostring(k.show) .. ", Sort " .. tostring(n.sort) .. "/" .. tostring(k.sort) .. ", category " .. tostring(n.cat) .. "/" .. tostring(k.cat)
            .. ", search \"" .. tostring(n.search) .. "\"/\"" .. tostring(k.search) .. "\", card " .. tostring(n.sel) .. "/" .. tostring(k.sel)
            .. ", scroll " .. H.f4(S.scrollNow) .. "/" .. H.f4(k.scroll) .. " (now / found)")
    end
    local w = RT.ww()
    local tabNow = w and w._activeTab
    Q.check((S.tabWas == nil or tabNow == S.tabWas) and RT.isOpen() == S.pairWas, "put back: the World window's tab and the window pair as found",
        "tab " .. tostring(tabNow) .. " (found " .. tostring(S.tabWas) .. "), the pair open " .. tostring(RT.isOpen()) .. " (found " .. tostring(S.pairWas) .. ")")
    RT.bounds(Q, "the end")
end)
Q.start()
