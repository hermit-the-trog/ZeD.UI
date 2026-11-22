-- ZeDUI/tools/qa/vx11_craft.lua  (Nov 21 2026, QA batch 11; tag vx11_crf): the in-game proof of Build's fix for
-- B11-1, B11-2 and B11-4 (findings in ZeDUI/qa/audits/2026-11-21_beast_batch11.md). Written against the code the
-- findings were traced on (d31a4b72f): every check marked "old code FAIL" fails there, and passes once the fix the
-- finding describes is in. Needs zedqa_prelude.lua and rt_kit.lua first. grep "ZEDQA vx11_crf". Manifest: vx11.txt
-- (vx11_craft.lua | vx11_crf | timeout=420). Nothing is crafted or built: Craft and Build are never pressed. Built on
-- vx10_craft.lua: its staging, its watch of the card's drawing, its sort watch, its calm moments and its put-back.
--
-- What each check proves:
--   B11-2, the world (passes on the old code too): the QA save's See Not Known Recipes (SeeNotLearntRecipe) is on, as
--     in all four sandbox presets. The Crafting tab's flicker needs it on; off, its checks below say SKIP.
--   B11-2, the Build tab (opened first by its own press, its Show as found): Metal floor (MetalFloorLvl1: must be
--     learned, no skill). Every drawn frame for 7 s with nothing changing:
--     * the Build list is not sorted again and Metal floor's row keeps one status (old code FAIL: the row reads
--       unlocked after each 1 s row refresh and locked after each 1.2 s BuildLogic scan, and every scan sorts the
--       list again);
--     * its row reads not learned, as the game's isRecipeKnown(recipe, true) says (old code FAIL: BuildingTab hands
--       every build recipe learned = true).
--     SKIP when the World window has no Build tab, the game has no Metal floor, or he has learned it.
--   Every watch window (here and on the Crafting tab below) counts the tab's row refreshes and scans: one that saw
--   fewer than 4 of either (the tab not drawn: its rows hold still and nothing sorts) FAILs its checks, never PASSes.
--   B11-1 (the World window's Crafting tab: Show All, sorted Craftable, a table beside him as vx10_craft stages it):
--     * 4 bowls and a pot of soup given, Divide Food into 4 Bowls (Make4Bowls) opened from its row: the open card's
--       drawn Outputs rows (CC.renderCraftCard's Outputs section, the data each Molecules.drawSlotRow is handed,
--       watched every frame) name what the game's output mapper names for what is in reach, Bowl of Soup and
--       Cooking Pot, within 6 s (old code FAIL: "Bowl of Pasta" and "Cooking Pot", each mapper's first result);
--     * the soup swapped for a saucepan of rice (Base.RicePan), the card left open: the rows follow within 8 s, Bowl
--       of Rice and Saucepan (old code FAIL: "Bowl of Pasta" and "Cooking Pot" again).
--     The reference is vx10_craft's information line, now a check: OutputScript:getOutputMapper():getOutputItem(the
--     recipe data, true), the vanilla window's manual-select naming (ISWidgetOutput.lua:286-295), the data filled as
--     the game fills it (a HandcraftLogic on the game's own container list and the table). It must name what the
--     game's script maps for the food in reach (recipes_cooking.txt, bowlType and potType: Base.SoupBowl and Base.Pot,
--     then Base.RiceBowl and Base.Saucepan; vx10_craft read exactly these in game at 4K and 1280x800): anything else
--     FAILs as the staging's fault, never PASSes (a data left empty names Bowl of Pasta, the old card's own name, and
--     the old card would match it). The card sits on screen.
--   B11-2, the Crafting tab (Show All, no card open, the B11-1 things taken back, 3 s let pass): the recipe watched
--     is a must-learn hand recipe (no station) he has the skill for and has not learned (isRecipeKnown(recipe, true)
--     false): the first the list holds of Make Improvised Lighter (MakeImprovisedLighter: no skill, any surface; the
--     game teaches it at Electrical 5), Make Stone Awl (MakeStoneAwl: no skill; taught at Knapping 2), Make Barbed
--     Wire, Make Tarp Tank Top, Make Firecracker (MakeBarbedWire, MakeTarpTankTop, MakeFirecracker: no skill);
--     else the first such recipe by name that needs no skill, else the first by name. It is said. Every drawn frame
--     for 7 s with nothing changing:
--     * its row keeps one status, locked (old code FAIL: locked after each scan, unlocked after each row refresh);
--     * the list is not refiltered or sorted again (a new filtered list, counted as vx10_craft's sort watch counts;
--       old code FAIL: every 1.2 s scan sorts it again);
--     * its row's learned agrees with isRecipeKnown(recipe, true) every frame (old code FAIL: CraftingTab.lua:278 asks
--       the one-argument form, which answers yes at once while the option is on).
--     A window in which a re-sort met a row changing status that the old flicker does not move (any row but a
--     must-learn one he has not learned: the world changed) is run again, once.
--     Then:
--     * every must-learn row the tab holds reads learned exactly when isRecipeKnown(recipe, true) says so (old code
--       FAIL: every unlearned one reads learned);
--     * Show: Known leaves the recipe out (old code FAIL: listed as known);
--     * the item card's Known (ZeD.RecipeIndex.known, RecipeIndex.lua:164) reads it not learned (old code FAIL);
--     * the Journal's Recipes rows (ZeD.JournalTab.gatherRecipeData, handed a table of its own: the Character
--       window's Journal is not touched) read it not learned and locked (old code FAIL: JournalTab.lua:787).
--   B11-4 (the B10-4 hold lands on its pixel): the list's span (state._listGeo: totalH - viewH) gives every whole
--     offset W for which floor((W / span) * span) < W (the old hold stored W / span; the list draws floor(share *
--     span)). The row that is not must-learn and has no mapped output, whose view range holds the most such offsets
--     (a ready, pinned or most-used row first: today's flicker never moves those; then a missing or station row; a
--     locked row last, its open card rewrote its status on the old code, B13-2), has its card opened from its row.
--     Then for each W, at a calm moment (vx10_craft's H.calm: the next row refresh and scan both 0.4 s away, the rows
--     as the last sort saw them): the list set to draw from W exactly ((W + 0.5) / span), one frame drawn, a re-sort
--     forced (state.filterDirty), the next frame read. A try whose re-sort moved the row's place is tried again once.
--     * at up to 3 such offsets the open recipe's row stays exactly where it was (0 px) and the list draws from W
--       (old code FAIL: 1 px lower, the list drawn from W - 1);
--     * (a guard, passes on the old code too) at an offset the old hold lands exactly, the row stays exactly.
--     SKIP when the list does not scroll, or no row's view range holds an offset that lands short.
-- How it stages: both windows open as a pair; a station bound is unbound for the run; the Build tab, then the
-- Crafting tab, each by its own press (RT.worldTab); on the Crafting tab Show All, sorted Craftable, every category,
-- the All group and Outputs unfolded, a search found emptied (field and list); a table beside him (the first table
-- sprite the game takes as a crafting surface). Waits go by the clock; no pixel size is written in (the offsets, the
-- span and the rows' places are read from the list's own geometry, at 4K and UI scale 1.75 as at 1280x800 and Auto).
-- Run offline before the first game run (Nov 21-22 2026: KRun, rt_kit.lua and this script in the game's Kahlua against
-- a stubbed game and the shipped CraftingCore, CraftingTab, BuildingTab, RecipeIndex and the Journal's recipe rows; the
-- harness is not in the repo; every throw a pcall caught was counted: none): d31a4b72f FAIL 12 (every check marked
-- old code FAIL; the guards and the put-back PASS), at 3840x2160 and 1280x800; ae5476af2 (Build's batch 11 fix,
-- 0ae4ee2a1 and c77b5b0fc) FAIL 1, the Build tab's sort check (QA's B13-1: the status was decided before learned, so
-- each row refresh wrote unlocked, the quick scan missing and the scan locked, and every scan sorted the list again);
-- 945599f98 (B13-1 and B13-2 fixed) PASS 21 at both sizes. Also run on both: the tabs found open (a card, Show Known,
-- sorted by name, scrolled; the World window on Build), See Not Known Recipes off (the world check FAILs, the Crafting
-- watch says SKIP), Metal floor learned (SKIP), a recipe turning ready in the first Crafting window (run again, PASS),
-- the clock leaping past the limit at four points (the put-back PASS each time); and the review's two (Nov 22): the
-- Build tab not drawn through its watch (its sort check FAILs, on d31a4b72f and 945599f98; before the review it
-- PASSed on d31a4b72f), the game's own reference naming Bowl of Pasta (both B11-1 checks FAIL as a staging fault on
-- both; before the review both PASSed on d31a4b72f's card).
-- Puts back (also after a step throws or the time runs out): ZeD's four drawing functions, every thing given
-- (RT.takeBack: bowls, soup, rice), the table, a bound station; the Crafting tab's Show / Sort / category / folds /
-- Owned only / search (the field and the list together), then once the list is filtered again the open card with its
-- picks and amount, then at a calm moment the list's scroll; the World window's tab, the Build tab's scroll (a press
-- on a tab sets its scroll to the top), the window pair as found. The sweep takes away only the script's own things
-- (marked ZeDQA_spawned): anything else new is said, never deleted. No option is changed or saved, no file is written.

if not RT then
    print("ZEDQA vx11_crf ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA vx11_crf VERDICT FAIL 1")
    print("ZEDQA vx11_crf DONE")
    return
end

local Q = RT.make("vx11_crf")
-- (typically about two minutes; every wait at its limit comes to about five, and the put-back after a jump some
-- 25 s more: inside the manifest's 420 s)
Q.maxMs = 330000
local S = { had = {}, floorHad = {}, cap = { cards = 0 }, nl = {}, kn = {}, n1 = {}, n2 = {}, m = {}, mw1 = {}, mw2 = {}, bm = {},
    bw1 = {}, bw2 = {}, b4 = { offs = {} } }
local H = {}
S.p, S.pn = RT.p, RT.pn
S.CC = ZeD and ZeD.CraftingCore
S.CT = ZeD and ZeD.CraftingTab
S.WW = ZeD_WorldWindow
S.BOWLS, S.METAL = "Make4Bowls", "MetalFloorLvl1"
-- must-learn hand recipes that need no skill (the game's recipes_electrical.txt, recipes_knapping.txt,
-- recipes_metalWelding.txt, recipes_tailoring_garbageTapeAndTarp.txt, recipes_traps.txt)
S.PREFER = { "MakeImprovisedLighter", "MakeStoneAwl", "MakeBarbedWire", "MakeTarpTankTop", "MakeFirecracker" }
S.NEAR = { { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }
S.TABLES = { "furniture_tables_high_01_16", "furniture_tables_high_01_0", "furniture_tables_high_01_8", "furniture_tables_high_01_24",
    "furniture_tables_high_01_32", "furniture_tables_high_01_40", "furniture_tables_low_01_0", "furniture_tables_low_01_8" }
S.SCAN_MS = 1200   -- CraftingCore's LOGIC_EVERY_MS (local to CraftingCore, so written here)
S.RUNWAY = 400     -- ms clear of the next row refresh and scan for one B11-4 try (three frames)
S.WATCH_MS = 7000  -- each B11-2 window (five scans and six row refreshes at least)
S.LIVE = 4         -- row refreshes and scans a window must see: fewer, the tab was not drawn and the window proves nothing
-- what Make4Bowls' mappers make from the food in reach (the game's recipes_cooking.txt, its bowlType and potType): the
-- game's own answer for what is in reach must be this, or the staging did not reach the case
S.EXPECT = { soup = { "Base.SoupBowl", "Base.Pot" }, rice = { "Base.RiceBowl", "Base.Saucepan" } }
S.dead = false

if not (S.p and S.CC and S.CT and S.WW and ZeD.Molecules and ZeD.Atoms) then
    Q.check(false, "the player and ZeD's Crafting tab are loaded")
    Q.start()
    return
end
-- ZeD's own drawing functions as found (the card's watch wraps them for a few seconds; the put-back checks them)
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
function H.n(x) if type(x) ~= "number" then return tostring(x) end; return tostring(math.floor(x + 0.5)) end
function H.f4(x) if type(x) ~= "number" then return tostring(x) end; return string.format("%.4f", x) end
function H.ceil(x) local f = math.floor(x); if f < x then return f + 1 end; return f end

-- ===================================================================== helpers: the Crafting tab
function H.cst() local w = RT.ww(); return w and w._craftState end
function H.data() local w = RT.ww(); return w and w._craftCache end
function H.geo() local st = H.cst(); return st and st._listGeo end
function H.row(name) local d = H.data(); if not (d and d.byName and name) then return nil end; return d.byName[name] end
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
-- a press where a click lands: the tab's own mouse handler, the zone's middle
function H.click(z, what)
    local ww = RT.ww()
    if not ww then return false end
    local ok, err = pcall(S.CT.onClick, ww, z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2))
    if not ok then Q.check(false, what .. ": the click ran without an error", err) end
    return ok
end
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
-- the row's offset from the list view's top (px), its zone, the list's geometry and the offset the list draws from
-- (floor(scrollPos * span), as the list draws it)
function H.rel(name)
    local st, g, z = H.cst(), H.geo(), H.rowZone(name)
    if not (st and g and z and st.scroll) then return nil end
    local off = math.floor((st.scroll.scrollPos or 0) * math.max(0, (g.totalH or 0) - (g.viewH or 0)))
    return z.y - g.viewY, z, g, off
end
-- the list scrolled so the row sits relT px under the view's top (as far as the list's ends allow)
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
function H.listed(name)
    local st = H.cst()
    for _, rd in ipairs((st and st.filteredCache) or {}) do if rd.entry and rd.entry.name == name then return true end end
    return false
end
-- every listed row's status, by row
function H.snapStatus()
    local m = {}
    local st = H.cst()
    for _, rd in ipairs((st and st.filteredCache) or {}) do m[rd] = rd.status end
    return m
end
function H.statusChanges(m)
    local n = 0
    for rd, s in pairs(m or {}) do if rd.status ~= s then n = n + 1 end end
    return n
end
function H.keepState(st)
    return { show = st.show, showAll = st.showAll, sort = st.sort, cat = st.activeCat, req = st.reqCollapsed, out = st.outCollapsed,
        all = st.allCollapsed, owned = st.ownedOnly, search = st.search or "", sel = st.selected, picks = st.picks, qty = st.qty,
        scroll = (st.scroll and st.scroll.scrollPos) or 0, card = (st.cardScroll and st.cardScroll.scrollPos) or 0, alt = st.altSlotName }
end
-- the Crafting tab's search: its field and the tab's state set together (the field's own poll then sees no change,
-- so it does not fire later and reset the list's scroll)
function H.setSearch(st, text)
    local w = RT.ww()
    local f = w and w._craftSearch or nil
    if f and f.input then
        pcall(function() f.input:setText(text) end)
        f._lastText = text
    end
    st.search, st.filterDirty = text, true
end

-- ===================================================================== helpers: the sort watch and calm moments
-- every re-sort of the Crafting list counted as it happens (a re-sort makes a new filtered list), from the setup to
-- the put-back (OnPreUIDraw, read only), with every listed row's status as that sort saw it
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
function H.unwatch() if S.watching then pcall(function() Events.OnPreUIDraw.Remove(H.sortWatch) end); S.watching = false end end
-- whether every listed row still reads as the last sort saw it
function H.sameSinceSort()
    local st = H.cst()
    if not (st and S.sortSnap and st.filteredCache ~= nil and st.filteredCache == S.lastFc) then return false end
    for rd, s in pairs(S.sortSnap) do if rd.status ~= s then return false end end
    return true
end
-- the list's next row refresh and next scan are both more than ms away (CraftingTab: _craftRowsAt holds the next
-- refresh, _craftLogicAt the last scan)
function H.clear(ms)
    local w = RT.ww()
    if not w then return false end
    local now = getTimestampMs()
    local rows, scan = w._craftRowsAt, w._craftLogicAt
    if type(rows) ~= "number" or type(scan) ~= "number" then return false end
    return rows - now > ms and scan + S.SCAN_MS - now > ms
end
-- a calm moment: clear of the refresh and the scan, and every row reads as the last sort saw it
function H.calm(ms) return H.clear(ms) and H.sameSinceSort() end

-- ===================================================================== helpers: the card's drawing, watched
-- ZeD's own drawing of the card, wrapped in memory (vx10_craft's watch): the card (CC.renderCraftCard: only this
-- tab's card of the named recipe is read), its section heads (the "Outputs" head opens the Outputs rows, any other
-- head ends them), its slot rows (the name each is handed) and the count each hands the right-aligned text. S.cap.last
-- holds the last drawn frame: head ({ count }) or nil, rows ({ name, drawn }); S.cap.cards counts the frames drawn.
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
            cur.heads = cur.heads + 1
            if c.word ~= nil and text == c.word then
                cur.head = { count = count, open = expanded }
                c.inOut = true
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
        if rec then rec.drawn = tostring(text) end
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
    if not last then return "nothing (no frame of the card drawn)" end
    local out = {}
    for _, r in ipairs(last.rows or {}) do out[#out + 1] = "\"" .. tostring(r.name) .. "\" " .. tostring(r.drawn) end
    if not last.head then return "no Outputs section" end
    if #out == 0 then return "an Outputs section with no rows" end
    return table.concat(out, ", ")
end

-- ===================================================================== helpers: B11-1, the game's output mapper
-- the game's own list for its craft window (the inventory, the bags, the floor, the open loot containers)
function H.gameList()
    local l = nil
    pcall(function()
        if getPlayerInventory(S.pn) ~= nil and getPlayerLoot(S.pn) ~= nil then l = ISInventoryPaneContextMenu.getContainers(S.p) end
    end)
    return l
end
-- what the game's output mapper names for Divide Food's outputs from what is in reach: { n (the outputs, the
-- automation-only ones left out as ZeD and the craft window leave them), names[i], fts[i] (nil: no mapper or no
-- answer), mapped (how many named), can (the game would start it), used (the inputs the data took), err }
function H.mapperNames()
    local m = { n = 0, names = {}, fts = {}, used = {}, mapped = 0 }
    local e = H.entry(S.BOWLS)
    local r = e and e.recipe
    if not r then m.err = "no " .. S.BOWLS .. " in ZeD's catalog"; return m end
    local ok, err = pcall(function()
        local l = HandcraftLogic.new(S.p, nil, S.surf)
        l:setContainers(H.gameList() or S.CC.buildContainers(S.p))
        l:setRecipe(r)
        m.can = l:canPerformCurrentRecipe() and true or false
        local data = l:getRecipeData()
        if data then
            pcall(function()
                local seen = {}
                local items = data:getAllInputItems()
                for i = 0, items:size() - 1 do
                    local ft = tostring(items:get(i):getFullType())
                    if not seen[ft] then seen[ft] = 0; m.used[#m.used + 1] = ft end
                    seen[ft] = seen[ft] + 1
                end
                for i = 1, #m.used do m.used[i] = m.used[i] .. " x" .. tostring(seen[m.used[i]]) end
            end)
        end
        local outs = r:getOutputs()
        for i = 0, outs:size() - 1 do
            local o = outs:get(i)
            local auto = false
            pcall(function() auto = o:isAutomationOnly() and true or false end)
            if not auto then
                m.n = m.n + 1
                local k = m.n
                local mp = nil
                pcall(function() mp = o:getOutputMapper() end)
                if mp and data then
                    local it = nil
                    pcall(function() it = mp:getOutputItem(data, true) end)
                    if it then
                        pcall(function() m.names[k] = tostring(it:getDisplayName()); m.fts[k] = tostring(it:getFullName()) end)
                        if m.names[k] then m.mapped = m.mapped + 1 end
                    end
                end
            end
        end
    end)
    if not ok then m.err = tostring(err) end
    return m
end
function H.refText(m)
    if not m then return "nothing" end
    local out = {}
    for i = 1, m.n do
        if m.names[i] then out[#out + 1] = "\"" .. m.names[i] .. "\" (" .. tostring(m.fts[i]) .. ")" else out[#out + 1] = "(no answer)" end
    end
    return ((#out > 0) and table.concat(out, ", ") or "no output") .. (m.err and (" (it threw: " .. m.err .. ")") or "")
        .. " (the game would start it: " .. tostring(m.can) .. "; the inputs it took: " .. ((#m.used > 0) and table.concat(m.used, ", ") or "none") .. ")"
end
-- the card's drawn Outputs rows name, in order, what the mapper names (every output named: H.refAsScript holds)
function H.namesMatch(last, m)
    if not (last and last.head and m and m.mapped == m.n and m.n > 0 and #(last.rows or {}) == m.n) then return false end
    for i = 1, m.n do
        if last.rows[i].name ~= m.names[i] then return false end
    end
    return true
end
-- the game's answer for what is in reach is what its script maps for that food (want: S.EXPECT): every output named,
-- the item each names as written. Anything else (a data left empty names the mapper's default, Bowl of Pasta, the old
-- card's own name) means the staging did not reach the case, and the card's rows cannot be judged by it.
function H.refAsScript(m, want)
    if not (m and want and m.err == nil and m.n == #want and m.mapped == m.n) then return false end
    for i = 1, #want do
        if m.fts[i] ~= want[i] then return false end
    end
    return true
end
-- the names case: the card's drawing watched every frame until a frame names the outputs as the mapper does (T.ref,
-- T.refOk: as the game's script maps them), at most ms; then the check
function H.namesWatch(T, ms, label)
    H.frames(ms, 0, function()
        if not T.go then return "now" end
        local last = S.cap.last
        if last then T.last = last end
        if last and T.refOk and H.namesMatch(last, T.ref) then
            T.match, T.at = true, getTimestampMs() - (T.t0 or getTimestampMs())
            return "now"
        end
        return false
    end, function()
        if not T.go then return end
        H.capOff()
        local m = T.ref
        if not T.refOk then
            -- (no PASS on a reference that is not the game's case: this is the staging's fault, said as such)
            Q.check(false, label, "the staging did not reach the case: the game's output mapper for what is in reach names " .. H.refText(m) .. ", not "
                .. table.concat(T.expect or {}, " and ") .. " as the game's script maps that food; the card's rows (" .. H.rowsText(T.last) .. ") are not judged")
            return
        end
        Q.check(T.match == true, label, "the card's Outputs rows read " .. H.rowsText(T.last) .. "; the game's output mapper for what is in reach names "
            .. H.refText(m) .. (T.match and (", the rows matched " .. H.sec(T.at) .. " after") or (", no frame matched in " .. H.sec(ms))))
    end)
end

-- ===================================================================== helpers: B11-2
-- the game's answer: does he really know it (nil when the game would not say)
function H.known(recipe)
    local k = nil
    if recipe then pcall(function() k = S.p:isRecipeKnown(recipe, true) and true or false end) end
    return k
end
-- must the recipe be learned (the Crafting catalog keeps it; the Build catalog does not: asked of the game once)
function H.needLearn(entry)
    if not entry then return false end
    if entry.needLearn ~= nil then return entry.needLearn and true or false end
    local v = S.nl[entry]
    if v == nil then
        v = false
        local r = entry.recipe
        if r then pcall(function() v = r:needToBeLearn() and true or false end) end
        S.nl[entry] = v
    end
    return v
end
function H.seeOpt()
    local o, v = nil, nil
    pcall(function()
        local so = getSandboxOptions()
        if so then o = so:getOptionByName("SeeNotLearntRecipe") end
    end)
    if o then pcall(function() v = o:getValue() end) end
    return v
end
-- every row's status (all the tab's rows, listed or not), by row
function H.snapRows(data)
    local m = {}
    for _, rd in ipairs((data and data.recipes) or {}) do m[rd] = rd.status end
    return m
end
-- a row whose status the old code flips with nothing changing (B11-2's flicker): a must-learn recipe he has not
-- really learned (the game's answer, asked once per recipe for the run). A must-learn recipe he knows is not one.
function H.flickers(rd)
    local e = rd and rd.entry
    if not (e and H.needLearn(e)) then return false end
    local k = S.kn[e]
    if k == nil then
        k = H.known(e.recipe)
        if k == nil then k = "unread" end
        S.kn[e] = k
    end
    return k == false
end
-- how many rows changed status between two snapshots, those B11-2's flicker moves left out (the first few named into
-- seen): a change of the world
function H.diffRows(a, b, seen)
    local n = 0
    for rd, s in pairs(b or {}) do
        local o = a and a[rd]
        if o ~= nil and o ~= s and not H.flickers(rd) then
            n = n + 1
            if #seen < 4 then seen[#seen + 1] = tostring(rd.entry and rd.entry.displayName) .. " " .. tostring(o) .. " to " .. tostring(s) end
        end
    end
    return n
end
-- a window saw the tab drawn: at least S.LIVE row refreshes and S.LIVE scans (a hidden tab refreshes and scans nothing,
-- so its rows hold still and its list is never sorted: a window that saw it proves nothing)
function H.live(W) return (W.scans or 0) >= S.LIVE and (W.refreshes or 0) >= S.LIVE end
function H.liveText(W)
    return tostring(W.refreshes) .. " row refreshes and " .. tostring(W.scans) .. " scans seen"
        .. (H.live(W) and "" or (" (fewer than " .. S.LIVE .. ": the tab was not drawn, the window proves nothing)"))
end
-- one watch window: every drawn frame for spec.ms, with nothing changing. Each re-sort (a new filtered list) is
-- counted, as a flicker (no row changed status since the last sort but the ones B11-2's flicker moves) or a change of
-- the world (another did: named); the watched row's status (each change kept with its time) and its learned against
-- the game's answer (spec.want); the tab's row refreshes and scans (the window's spec.rowsAt and spec.logicAt change at
-- each: CC.due, CC.logicScan). W.go: the window runs; W.done: it ran to its end.
function H.watch(spec, W)
    Q.waitFor(1, 4000000, function()
        if not W.go or S.dead then return true end
        local now = getTimestampMs()
        local st, data = spec.state(), spec.data()
        local fc = st and st.filteredCache
        local w = RT.ww()
        local la, ra = nil, nil
        if w then la, ra = w[spec.logicAt], w[spec.rowsAt] end
        if not W.t0 then
            W.t0, W.fc, W.snap, W.la, W.ra = now, fc, H.snapRows(data), la, ra
            W.sorts, W.flicker, W.world, W.flips, W.frames, W.disagree, W.scans, W.refreshes = 0, 0, 0, 0, 0, 0, 0, 0
            W.seen, W.flipSeen, W.worldSeen, W.learned = {}, {}, {}, {}
        else
            if fc ~= W.fc then
                W.fc = fc
                W.sorts = W.sorts + 1
                local snap = H.snapRows(data)
                if H.diffRows(W.snap, snap, W.worldSeen) > 0 then W.world = W.world + 1 else W.flicker = W.flicker + 1 end
                W.snap = snap
            end
            if la ~= W.la then W.la, W.scans = la, W.scans + 1 end
            if ra ~= W.ra then W.ra, W.refreshes = ra, W.refreshes + 1 end
        end
        local rd = spec.row()
        local s = rd and tostring(rd.status) or "no row"
        W.frames = W.frames + 1
        if W.last ~= nil and s ~= W.last then
            W.flips = W.flips + 1
            if #W.flipSeen < 6 then W.flipSeen[#W.flipSeen + 1] = W.last .. " to " .. s .. " at " .. H.sec(now - W.t0) end
        end
        W.last = s
        W.seen[s] = (W.seen[s] or 0) + 1
        local l = nil
        if rd then l = rd.learned end
        if l ~= spec.want then W.disagree = W.disagree + 1 end
        W.learned[tostring(l)] = (W.learned[tostring(l)] or 0) + 1
        if now - W.t0 >= spec.ms then W.done = true; return true end
        return false
    end, function() end)
end
function H.tally(t)
    local out = {}
    for k, v in pairs(t or {}) do out[#out + 1] = tostring(k) .. " " .. tostring(v) end
    table.sort(out)
    return (#out > 0) and table.concat(out, ", ") or "nothing"
end
-- the window that counts: the second when it ran (the first met a change of the world), else the first
function H.lastWindow(W1, W2) if W2.t0 then return W2, true end; return W1, false end
function H.sortText(W, again)
    return W.sorts .. " re-sorts in " .. H.sec(S.WATCH_MS) .. " (" .. W.flicker .. " with only must-learn rows he has not learned changing status, "
        .. W.world .. " with another changing" .. ((#W.worldSeen > 0) and (": " .. table.concat(W.worldSeen, "; ")) or "") .. ")"
        .. (again and "; the first window met a change of the world and was run again" or "")
end
function H.flipText(W)
    return "the row read " .. H.tally(W.seen) .. " (frames), " .. W.flips .. " changes" .. ((#W.flipSeen > 0) and (": " .. table.concat(W.flipSeen, ", ")) or "")
end
-- the recipe watched on the Crafting tab: a must-learn hand recipe (no station) the list holds, he has the skill for
-- and has not learned; S.PREFER first, then one that needs no skill, then any, each first by name. Returns the row
-- and how many such recipes the list holds.
function H.pickM()
    local d, st = H.data(), H.cst()
    local listed = {}
    for _, rd in ipairs((st and st.filteredCache) or {}) do listed[rd] = true end
    local c = { n = 0, byName = {} }
    for _, rd in ipairs((d and d.recipes) or {}) do
        local e = rd.entry
        if e and e.needLearn and e.recipe and not e.stationInfo and listed[rd] and rd.status ~= "station" then
            local skill = false
            pcall(function() skill = e.recipe:characterHasRequiredSkills(S.p) and true or false end)
            if skill and H.known(e.recipe) == false then
                c.n = c.n + 1
                c.byName[e.name] = rd
                local dn = tostring(e.displayName)
                if #(e.skillDefs or {}) == 0 and (c.none == nil or dn < tostring(c.none.entry.displayName)) then c.none = rd end
                if c.any == nil or dn < tostring(c.any.entry.displayName) then c.any = rd end
            end
        end
    end
    for _, nm in ipairs(S.PREFER) do if c.byName[nm] then return c.byName[nm], c.n end end
    return c.none or c.any, c.n
end

-- ===================================================================== helpers: B11-2, the Build tab
function H.bst() local w = RT.ww(); return w and w._buildState end
function H.bdata() local w = RT.ww(); return w and w._buildCache end
function H.bshowing() local s = false; pcall(function() s = S.WW.isTabShowing("build", S.pn) end); return s and true or false end
-- Metal floor's row: by its name, else the first row whose name has MetalFloor in it
function H.metalRow()
    local d = H.bdata()
    if not d then return nil end
    if d.byName and d.byName[S.METAL] then return d.byName[S.METAL] end
    for _, r in ipairs(d.recipes or {}) do
        if r.entry and type(r.entry.name) == "string" and string.find(r.entry.name, "MetalFloor", 1, true) then return r end
    end
    return nil
end

-- ===================================================================== helpers: B11-4
-- every whole offset of the span the old hold lands 1 px short of: the share W / span read back as floor(share *
-- span), the list's own reading (CraftingCore.renderRecipeList)
function H.shortOffs(span)
    local out = {}
    for w = 0, math.floor(span) do
        if math.floor((w / span) * span) < w then out[#out + 1] = w end
    end
    return out
end
function H.lands(w, span) return math.floor((w / span) * span) == w end
-- the first index of the sorted list whose value is at least v
function H.lowerBound(list, v)
    local lo, hi = 1, #list + 1
    while lo < hi do
        local mid = math.floor((lo + hi) / 2)
        if list[mid] < v then lo = mid + 1 else hi = mid end
    end
    return lo
end
function H.countIn(list, lo, hi)
    if hi < lo then return 0 end
    return H.lowerBound(list, math.floor(hi) + 1) - H.lowerBound(list, H.ceil(lo))
end
-- a recipe with an output named through a mapper (its card asks the game for the names: B11-1, not under test here)
function H.mapped(entry)
    for _, od in ipairs((entry and entry.outputDefs) or {}) do if od.mapped then return true end end
    return entry ~= nil and entry.name == S.BOWLS
end
-- the row to hold: not must-learn, no mapped output, the most short offsets in its view range (up to 4 counted), a
-- ready, pinned or most-used row first (today's flicker moves rows between the unlocked and locked groups, never
-- those), then a missing or station row (the game's answer, which its open card leaves alone), then any other (a
-- locked row's open card rewrote its status on the old code, B13-2); in each, the one nearest the list's middle.
-- Returns its name and its count.
function H.pickHold(shorts, span)
    local st, g = H.cst(), H.geo()
    if not (st and g and st.scroll) then return nil, 0 end
    local secs = {}
    for _, sec in ipairs(st._sections or {}) do
        if not sec.collapsed then
            for _, rd in ipairs(sec.items or {}) do if rd.entry then secs[rd.entry.name] = sec.id end end
        end
    end
    local off = math.floor((st.scroll.scrollPos or 0) * span)
    local best = { {}, {}, {} }
    for _, z in ipairs(st.zones or {}) do
        if z.type == "recipeRow" and type(z.y) == "number" and type(z.h) == "number" and z.h > 0 then
            local rd = H.row(z.id)
            if rd and rd.entry and not H.needLearn(rd.entry) and not H.mapped(rd.entry) then
                local cy = z.y - g.viewY + off
                local n = math.min(4, H.countIn(shorts, math.max(0, cy - (g.viewH - z.h)), math.min(span, cy)))
                if n > 0 then
                    local sid = secs[rd.entry.name]
                    local tier = ((sid == "pinned" or sid == "freq" or rd.status == "craftable") and 1)
                        or ((rd.status == "missing" or rd.status == "station") and 2) or 3
                    local b = best[tier]
                    local d = math.abs(cy - (g.totalH or 0) / 2)
                    if b.name == nil or n > b.n or (n == b.n and d < b.d) then b.name, b.n, b.d = rd.entry.name, n, d end
                end
            end
        end
    end
    for t = 1, 3 do
        if best[t].name then return best[t].name, best[t].n end
    end
    return nil, 0
end
-- the offsets for the held row at its place now: up to 3 that land short (nearest a place in the view's middle) and
-- a guard that lands exactly (next to the first); S.b4.offs
function H.chooseOffs(name, shorts, span)
    local rel, z, g, off = H.rel(name)
    if not rel then return "its row has no place in the list" end
    local cy = rel + off
    local lo, hi = math.max(0, cy - (g.viewH - z.h)), math.min(span, cy)
    local aim = cy - H.mid()
    local cands = {}
    for i = H.lowerBound(shorts, H.ceil(lo)), #shorts do
        if shorts[i] > hi then break end
        cands[#cands + 1] = shorts[i]
    end
    if #cands == 0 then return "no offset in its view range (" .. H.n(lo) .. " to " .. H.n(hi) .. " px) lands short now" end
    table.sort(cands, function(a, b) return math.abs(a - aim) < math.abs(b - aim) end)
    local offs = {}
    for i = 1, math.min(3, #cands) do offs[#offs + 1] = { w = cands[i] } end
    for k = 1, 40 do
        if not offs.guard then
            for _, w in ipairs({ cands[1] - k, cands[1] + k }) do
                if not offs.guard and w >= lo and w <= hi and H.lands(w, span) then offs.guard = w end
            end
        end
    end
    if offs.guard then offs[#offs + 1] = { w = offs.guard, guard = true } end
    S.b4.offs, S.b4.cy, S.b4.lo, S.b4.hi = offs, cy, lo, hi
    return nil
end
-- one try at offset slot i: at a calm moment the list set to draw from W, one frame drawn (the row's offset read and
-- a re-sort forced), the next frame read. A try whose re-sort moved the row's place in the list (or met another sort)
-- is left for the next try of the slot.
function H.holdTry(i)
    local T = {}
    Q.step(1, function()
        local b = S.b4
        local o = b.go and b.offs[i] or nil
        if not o or o.done or (o.tries or 0) >= 2 then return end
        o.tries = (o.tries or 0) + 1
        T.go, T.o = true, o
    end)
    H.frames(15000, 0, function()
        if not T.go then return "now" end
        local st = H.cst()
        if not (st and st.filterDirty == false and st.selected == S.b4.R and H.cardUp(S.b4.R)) then return false end
        -- (clear of the refresh and the scan; the rows as the last sort saw them, or after 6 s the clock alone)
        T.t0 = T.t0 or getTimestampMs()
        return H.clear(S.RUNWAY) and (H.sameSinceSort() or getTimestampMs() - T.t0 > 6000)
    end, function(ok)
        if not T.go then return end
        if not ok then T.go = false; T.o.why = "no calm moment with the card up in 15 s"; return end
        local st = H.cst()
        T.fcA = st.filteredCache
        st.scroll:setScrollPos((T.o.w + 0.5) / S.b4.span)
    end)
    Q.step(1, function()
        if not T.go then return end
        local st = H.cst()
        local rel, _, _, off = H.rel(S.b4.R)
        if not (rel and st and off == T.o.w and st.filteredCache == T.fcA) then
            T.go = false
            T.o.why = "the list did not draw from " .. T.o.w .. " px (it drew from " .. tostring(off) .. " px" .. ((st and st.filteredCache ~= T.fcA) and ", sorted again first" or "") .. ")"
            return
        end
        T.rel0, T.cy0, T.idx0, T.snap = rel, rel + off, H.idx(S.b4.R), H.snapStatus()
        T.fcB = st.filteredCache
        st.filterDirty = true
    end)
    Q.step(1, function()
        if not T.go then return end
        local st = H.cst()
        local rel, _, _, off = H.rel(S.b4.R)
        local o = T.o
        local sorted = st ~= nil and st.filteredCache ~= T.fcB and st.filterDirty == false
        local moved = H.statusChanges(T.snap)
        local clean = sorted and rel ~= nil and rel + off == T.cy0 and H.idx(S.b4.R) == T.idx0 and moved == 0
        if not clean then
            o.why = "the forced re-sort " .. (sorted and ("moved the row's place (" .. moved .. " rows changed status)") or "did not come") .. ", try " .. tostring(o.tries)
            Q.say("note B11-4: offset " .. o.w .. " px: " .. o.why)
            return
        end
        o.done, o.rel0, o.rel1, o.off1 = true, T.rel0, rel, off
        o.ok = rel == T.rel0 and off == o.w
    end)
end
function H.offText(o)
    if not o.done then return o.w .. " px: not read (" .. tostring(o.why) .. ")" end
    local d = o.rel1 - o.rel0
    return o.w .. " px: the row " .. H.n(o.rel0) .. " px under the list's top before, " .. H.n(o.rel1) .. " px after"
        .. ((d == 0) and " (0 px)" or (" (" .. H.n(math.abs(d)) .. " px " .. ((d > 0) and "lower" or "higher") .. ")")) .. ", the list drawn from " .. H.n(o.off1) .. " px"
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
function H.mine(it)
    local m = false
    pcall(function() m = it:getModData().ZeDQA_spawned == true end)
    return m
end
function H.wobItem(wo) local it = nil; pcall(function() it = wo:getItem() end); return it end
-- whatever the script made that is still carried or beside him (a thing a stray action moved): taken away. Only the
-- script's own things (H.mine): anything else new is counted by the put-back check, never deleted.
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

-- ===================================================================== setup
Q.step(2, function()
    S.dead = S.p:isDead() and true or false
    if S.dead then Q.check(false, "the character is alive (nothing is run on a dead one)"); return end
    if ZEDQA_HOME then ZEDQA_HOME("vx11_crf") end
    for _, it in ipairs(H.all()) do S.had[it] = true end
    H.snapFloor(S.floorHad)
    pcall(function() S.dirWas = S.p:getDir() end)
    S.pairWas = RT.isOpen()
    RT.pairOpen()
    Events.OnPreUIDraw.Add(H.sortWatch)
    S.watching = true
    local w = RT.ww()
    if w then
        S.tabWas = w._activeTab
        -- (the tabs' state as found, before a press sets a tab's scroll to the top and a station's unbinding resets
        -- the Crafting tab's category and scroll)
        if w._craftState then S.keep = H.keepState(w._craftState) end
        local bs = w._buildState
        if bs and bs.scroll then S.bscroll = bs.scroll.scrollPos end
    end
    pcall(function()
        local cur = ZeD.Stations and ZeD.Stations.current(S.p)
        if cur then
            S.stWas = cur
            ZeD.Stations.unbind(S.p)
            Q.say("note a station was bound: unbound for the run (the hand's recipes), bound again at the end")
        end
    end)
    S.see = H.seeOpt()
    Q.say("setup: the World window on " .. tostring(S.tabWas) .. ", the pair was open " .. tostring(S.pairWas) .. ", screen "
        .. tostring(getCore():getScreenWidth()) .. "x" .. tostring(getCore():getScreenHeight()) .. "; See Not Known Recipes (SeeNotLearntRecipe) " .. tostring(S.see))
    Q.check(S.see == true, "B11-2 (the world): the QA save has See Not Known Recipes on, as every sandbox preset (the Crafting tab's flicker needs it)",
        "SeeNotLearntRecipe " .. tostring(S.see))
end)

-- ===================================================================== B11-2: the Build tab, Metal floor
Q.step(15, function()
    if S.dead then return end
    S.bm.go = H.tab("build")
    if not S.bm.go then Q.skip("B11-2 (Build tab): the Build list is not sorted again every scan for Metal floor", "the World window offers no Build tab here") end
end)
H.wait(8000, function()
    if S.dead or not S.bm.go then return true end
    local st = H.bst()
    return H.bshowing() and st ~= nil and H.bdata() ~= nil and st.filteredCache ~= nil
end, function(ok)
    local B = S.bm
    if S.dead or not B.go then return end
    local why = nil
    local rd = ok and H.metalRow() or nil
    if not ok then
        local w = RT.ww()
        why = "the Build tab did not open with its list (the World window on " .. tostring(w and w._activeTab) .. ")"
    elseif not rd then
        why = "the Build tab lists no Metal floor (" .. S.METAL .. ") in this game"
    else
        B.name, B.title = rd.entry.name, tostring(rd.entry.displayName)
        B.known = H.known(rd.entry.recipe)
        if not H.needLearn(rd.entry) then why = B.title .. " need not be learned in this game"
        elseif B.known == nil then why = "the game would not say whether he knows " .. B.title
        elseif B.known then why = "he has learned " .. B.title .. ": nothing flips"
        elseif rd.hasSkill == false then why = "he lacks the skill " .. B.title .. " needs: it reads locked either way" end
    end
    if why then B.go = false; Q.skip("B11-2 (Build tab): the Build list is not sorted again every scan for Metal floor", why); return end
    local bst = H.bst()
    Q.say("B11-2 (Build tab): " .. B.title .. " (" .. B.name .. "): must be learned, not learned (isRecipeKnown(recipe, true) false), its row "
        .. tostring(rd.status) .. ", learned " .. tostring(rd.learned) .. "; the Build list shows " .. #((bst and bst.filteredCache) or {}) .. " rows (its Show as found); 3 s let pass, then watched "
        .. H.sec(S.WATCH_MS))
end)
-- (the tab's first sorts and scans let pass)
H.frames(3000, 0, function() if S.dead or not S.bm.go then return "now" end; return false end, function() end)
S.bspec = { ms = S.WATCH_MS, logicAt = "_buildLogicAt", rowsAt = "_buildRowsAt", state = function() return H.bst() end, data = function() return H.bdata() end,
    row = function() local d = H.bdata(); return (S.bm.name and d and d.byName) and d.byName[S.bm.name] or nil end, want = false }
Q.step(1, function() S.bw1.go = S.bm.go and not S.dead end)
H.watch(S.bspec, S.bw1)
Q.step(1, function() S.bw2.go = S.bw1.done == true and S.bw1.world > 0 end)
H.watch(S.bspec, S.bw2)
Q.step(1, function()
    local B = S.bm
    if S.dead or not B.go then return end
    local W, again = H.lastWindow(S.bw1, S.bw2)
    if not W.done then Q.check(false, "B11-2 (Build tab): the watch ran its " .. H.sec(S.WATCH_MS), "it stopped after " .. tostring(W.frames) .. " frames"); return end
    Q.check(H.live(W) and W.sorts == 0 and W.flips == 0, "B11-2 (Build tab): with nothing changing for " .. H.sec(S.WATCH_MS) .. ", the Build list is not sorted again and "
        .. B.title .. "'s row keeps one status (old code: locked after each scan, unlocked after each row refresh, the list sorted every scan)",
        H.liveText(W) .. "; " .. H.sortText(W, again) .. "; " .. H.flipText(W))
    Q.check(W.disagree == 0, "B11-2 (Build tab): " .. B.title .. "'s row reads not learned every frame, as the game's isRecipeKnown(recipe, true) says (old code: every build recipe read learned)",
        "its learned read " .. H.tally(W.learned) .. " (frames) over " .. W.frames .. " frames; the game: known " .. tostring(B.known))
end)

-- ===================================================================== the Crafting tab
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
    S.ok = Q.check(ok, "the World window's Crafting tab opens with its list", tostring(H.showing()))
    local st = H.cst()
    if not (S.ok and st) then S.ok = false; return end
    S.craftSeen = true
    S.keep = S.keep or H.keepState(st)
    if S.keep.alt then Q.say("note the tab was found in an ingredient's alternatives list: left for the recipe list, and not put back") end
    H.shut()
    -- Show: All, sorted Craftable, every category, the All group unfolded, Outputs unfolded
    pcall(S.CC.setShow, st, "all")
    st.sort, st.activeCat, st.allCollapsed, st.outCollapsed, st.filterDirty = "craftable", "all", false, false, true
    st._sectionsStale = true
    st.sortMenuOpen, st.showMenuOpen, st.catDropdownOpen, st.stDropdownOpen = false, false, false, false
    -- a search found typed: emptied in its field and the tab together, set back in the put-back
    local typed = ""
    local wwS = RT.ww()
    local fS = wwS and wwS._craftSearch or nil
    if fS then pcall(function() typed = fS:getText() or "" end) end
    if typed ~= "" or (st.search or "") ~= "" then
        S.searchWas = true
        H.setSearch(st, "")
        Q.say("note a search was typed (the field \"" .. tostring(typed) .. "\", the list's \"" .. tostring(S.keep.search) .. "\"): emptied for the run, set back at the end")
    end
    -- a table beside him (Divide Food is made on any surface: the game's mapper reads the data it fills)
    H.setTable()
    pcall(function() S.surf = ISEntityUI.FindCraftSurface(S.p, 2) end)
    Q.say("staged: table " .. tostring(S.tableSprite) .. " beside him (the game finds a crafting surface: " .. tostring(S.surf ~= nil) .. ")")
end)
H.wait(8000, function()
    if not S.ok then return true end
    local st = H.cst()
    return st ~= nil and st.filterDirty == false and (st.search or "") == "" and #(st.filteredCache or {}) > 20
end, function(ok)
    if not S.ok then return end
    Q.say("the list: " .. H.count() .. " rows (Show: All, sorted Craftable), settled " .. tostring(ok))
end)

-- ===================================================================== B11-1: the open card names its outputs
-- 4 bowls and a pot of soup given, Divide Food's card opened from its row (brought to the middle of the view)
Q.step(3, function()
    local T = S.n1
    if not S.ok then return end
    if not H.row(S.BOWLS) then Q.skip("B11-1: Divide Food into 4 Bowls' card names its outputs for what is in reach", "the Crafting tab does not list " .. S.BOWLS); return end
    H.shut()
    S.bowls = {}
    for _ = 1, 4 do
        local it = RT.give("Base.Bowl")
        if it then S.bowls[#S.bowls + 1] = it end
    end
    S.soup = RT.give("Base.PotOfSoup")
    H.floorChanged()
    H.place(S.BOWLS, H.mid())
    T.go = S.soup ~= nil and #S.bowls == 4
    if not T.go then Q.check(false, "B11-1: 4 bowls and a pot of soup are given", #S.bowls .. " bowls, the soup " .. tostring(S.soup ~= nil)) end
end)
Q.step(3, function() if S.n1.go then H.open(S.BOWLS, "B11-1, Divide Food into 4 Bowls") end end)
H.wait(6000, function() return not S.n1.go or H.cardUp(S.BOWLS) end, function(ok)
    local T = S.n1
    if not T.go then return end
    if not ok then
        T.go = false
        local st = H.cst()
        Q.check(false, "B11-1: Divide Food into 4 Bowls' card opens from its row", "the open card: " .. tostring(st and st.selected))
        return
    end
    T.ref, T.expect = H.mapperNames(), S.EXPECT.soup
    T.refOk = H.refAsScript(T.ref, T.expect)
    if not H.capOn(S.BOWLS) then T.go = false; Q.skip("B11-1: Divide Food into 4 Bowls' card names its outputs", "ZeD's card drawing could not be watched (a drawing function is missing)"); return end
    T.t0 = getTimestampMs()
end)
H.namesWatch(S.n1, 6000, "B11-1: 4 bowls and a pot of soup carried, Divide Food into 4 Bowls' open card names its outputs as the game makes them from what is in reach,"
    .. " Bowl of Soup and Cooking Pot (old code: Bowl of Pasta, each output's first result)")
Q.step(1, function() if S.n1.go then RT.bounds(Q, "the Crafting tab with a card open") end end)
-- the soup swapped for a saucepan of rice, the card left open
Q.step(3, function()
    local T = S.n2
    local st = H.cst()
    if not (S.ok and S.n1.go and st and st.selected == S.BOWLS) then return end
    H.takeOne(S.soup)
    S.rice = RT.give("Base.RicePan")
    H.floorChanged()
    if not S.rice then Q.check(false, "B11-1: a saucepan of rice (Base.RicePan) is given"); return end
    T.ref, T.expect = H.mapperNames(), S.EXPECT.rice
    T.refOk = H.refAsScript(T.ref, T.expect)
    if not H.capOn(S.BOWLS) then Q.skip("B11-1: the card follows a saucepan of rice", "ZeD's card drawing could not be watched"); return end
    T.go, T.t0 = true, getTimestampMs()
end)
H.namesWatch(S.n2, 8000, "B11-1: the soup swapped for a saucepan of rice with the card open, its Outputs rows follow, Bowl of Rice and Saucepan"
    .. " (old code: Bowl of Pasta and Cooking Pot whatever is in reach)")
-- the card shut, the bowls, the soup and the rice taken back
Q.step(3, function()
    H.capOff()
    if not S.ok then return end
    H.shut()
    for _, it in ipairs(S.bowls or {}) do H.takeOne(it) end
    H.takeOne(S.soup)
    H.takeOne(S.rice)
    H.floorChanged()
end)

-- ===================================================================== B11-2: the Crafting tab, a must-learn recipe
Q.step(3, function()
    local M = S.m
    if not S.ok then return end
    if S.see ~= true then
        Q.skip("B11-2: a must-learn recipe's row on the Crafting tab", "See Not Known Recipes is off in this world (" .. tostring(S.see) .. "): the one-argument isRecipeKnown answers as the game does, nothing flips")
        return
    end
    local rd, n = H.pickM()
    if not rd then
        Q.skip("B11-2: a must-learn recipe's row on the Crafting tab", "the list holds no must-learn hand recipe he has the skill for and has not learned")
        return
    end
    M.go, M.name, M.title, M.recipe = true, rd.entry.name, tostring(rd.entry.displayName), rd.entry.recipe
    local sk = {}
    for _, sd in ipairs(rd.entry.skillDefs or {}) do sk[#sk + 1] = tostring(sd.name) .. " " .. tostring(sd.required) end
    Q.say("B11-2: the recipe watched: " .. M.title .. " (" .. M.name .. "), must be learned, not learned (isRecipeKnown(recipe, true) false), "
        .. ((#sk > 0) and ("needs " .. table.concat(sk, ", ")) or "needs no skill") .. ", made by hand; one of " .. n
        .. " such recipes the list holds; its row now " .. tostring(rd.status) .. ", learned " .. tostring(rd.learned) .. "; 3 s let pass, then watched " .. H.sec(S.WATCH_MS))
end)
-- (the things taken back: the game's scan answers for them, one sort, before the watch)
H.frames(3000, 0, function() if not S.m.go then return "now" end; return false end, function() end)
S.mspec = { ms = S.WATCH_MS, logicAt = "_craftLogicAt", rowsAt = "_craftRowsAt", state = function() return H.cst() end, data = function() return H.data() end,
    row = function() return S.m.name and H.row(S.m.name) or nil end, want = false }
Q.step(1, function() S.mw1.go = S.m.go == true and S.ok == true end)
H.watch(S.mspec, S.mw1)
Q.step(1, function() S.mw2.go = S.mw1.done == true and S.mw1.world > 0 end)
H.watch(S.mspec, S.mw2)
Q.step(1, function()
    local M = S.m
    if not M.go then return end
    local W, again = H.lastWindow(S.mw1, S.mw2)
    if not W.done then Q.check(false, "B11-2: the watch ran its " .. H.sec(S.WATCH_MS), "it stopped after " .. tostring(W.frames) .. " frames"); return end
    local onlyLocked = W.seen.locked ~= nil and W.seen.locked == W.frames
    Q.check(H.live(W) and W.flips == 0 and onlyLocked, "B11-2: with nothing changing for " .. H.sec(S.WATCH_MS) .. ", " .. M.title .. "'s row keeps one status, locked, as the game's scan reads it"
        .. " (old code: locked after each scan, unlocked after each row refresh)", H.liveText(W) .. "; " .. H.flipText(W) .. " over " .. W.frames .. " frames")
    Q.check(H.live(W) and W.sorts == 0, "B11-2: in those " .. H.sec(S.WATCH_MS) .. " the Crafting list is not refiltered or sorted again (old code: every 1.2 s scan sorts it again)",
        H.liveText(W) .. "; " .. H.sortText(W, again))
    Q.check(W.disagree == 0, "B11-2: " .. M.title .. "'s row reads learned as the game's isRecipeKnown(recipe, true) does, every frame: not learned"
        .. " (old code: learned, the one-argument form answering yes while See Not Known Recipes is on)",
        "its learned read " .. H.tally(W.learned) .. " (frames) over " .. W.frames .. " frames; the game: known " .. tostring(H.known(M.recipe)))
    -- every must-learn row the tab holds, against the game
    local n, bad, seen = 0, 0, {}
    local d = H.data()
    for _, rd in ipairs((d and d.recipes) or {}) do
        if rd.entry and rd.entry.needLearn then
            local k = H.known(rd.entry.recipe)
            if k ~= nil then
                n = n + 1
                if (rd.learned and true or false) ~= k then
                    bad = bad + 1
                    if #seen < 4 then seen[#seen + 1] = tostring(rd.entry.displayName) .. " (ZeD " .. tostring(rd.learned) .. ", the game " .. tostring(k) .. ")" end
                end
            end
        end
    end
    Q.check(n > 0 and bad == 0, "B11-2: every must-learn recipe the Crafting tab holds reads learned exactly when isRecipeKnown(recipe, true) says so (" .. n .. " such rows)",
        bad .. " differ" .. ((bad > 0) and (": " .. table.concat(seen, "; ")) or ""))
end)
-- Show: Known (the card shut: the open card's recipe keeps its row whatever Show holds back)
Q.step(2, function()
    local M = S.m
    local st = H.cst()
    if not (M.go and st) then return end
    H.shut()
    M.fcK = st.filteredCache
    pcall(S.CC.setShow, st, "known")
    M.kgo = true
end)
H.wait(4000, function()
    local st = H.cst()
    return not S.m.kgo or (st ~= nil and st.filterDirty == false and st.filteredCache ~= S.m.fcK)
end, function(ok)
    local M = S.m
    if not M.kgo then return end
    local st = H.cst()
    local listed = H.listed(M.name)
    Q.check(ok and not listed, "B11-2: Show: Known leaves " .. M.title .. " out of the list (old code: listed, read as learned)",
        (ok and "" or "the list was not filtered again in 4 s; ") .. "listed " .. tostring(listed) .. ", " .. H.count() .. " rows under Show: Known")
    if st then pcall(S.CC.setShow, st, "all") end
end)
-- the item card's Known and the Journal's Recipes rows, asked of ZeD's own code
Q.step(3, function()
    local M = S.m
    if not M.go then return end
    local RI = ZeD.RecipeIndex
    local rec = nil
    if RI and RI.rec then pcall(function() rec = RI.rec(M.recipe, "craft") end) end
    local known, learned = nil, nil
    if rec and RI.known then
        local okK, a, b = pcall(RI.known, S.p, rec)
        if okK then known, learned = a, b end
    end
    if not rec then
        Q.skip("B11-2: the item card's Known (ZeD.RecipeIndex.known) reads " .. M.title .. " not learned", "ZeD.RecipeIndex could not read the recipe")
    else
        Q.check(learned == false and known == false, "B11-2: the item card's Known (ZeD.RecipeIndex.known) reads " .. M.title .. " not learned (old code: learned, Known)",
            "known " .. tostring(known) .. ", learned " .. tostring(learned))
    end
    local J = ZeD.JournalTab
    local data = nil
    if J and J.gatherRecipeData then
        -- (its own table for the window's cache: the Character window's Journal is not touched)
        local okJ, r = pcall(J.gatherRecipeData, S.p, {})
        if okJ then data = r end
    end
    local jrd = nil
    for _, rd in ipairs((data and data.recipes) or {}) do if rd.entry and rd.entry.name == M.name then jrd = rd end end
    if not jrd then
        Q.skip("B11-2: the Journal's Recipes rows read " .. M.title .. " not learned", "the Journal's recipe rows could not be read, or do not hold it (" .. #((data and data.recipes) or {}) .. " rows)")
    else
        Q.check(jrd.learned == false and jrd.status == "locked", "B11-2: the Journal's Recipes rows read " .. M.title .. " not learned and locked (old code: learned, unlocked)",
            "learned " .. tostring(jrd.learned) .. ", status " .. tostring(jrd.status))
    end
end)

-- ===================================================================== B11-4: the hold lands on its pixel
-- (Show: All back; two scans let pass, so the list is in the order the scans keep, then a calm moment)
H.frames(2600, 0, function() if not S.ok then return "now" end; return false end, function() end)
H.frames(15000, 0, function()
    if not S.ok then return "now" end
    local st = H.cst()
    return st ~= nil and st.filterDirty == false and st.selected == nil and H.calm(S.RUNWAY)
end, function(ok)
    local b = S.b4
    if not S.ok then return end
    local label = "B11-4: a re-sort with the card open leaves the open recipe's row exactly where it was"
    local g = H.geo()
    local span = g and ((g.totalH or 0) - (g.viewH or 0)) or 0
    if span < 2 then Q.skip(label, "the list does not scroll here (" .. tostring(g and g.totalH) .. " px of rows in a view of " .. tostring(g and g.viewH) .. " px)"); return end
    local t0 = getTimestampMs()
    local shorts = H.shortOffs(span)
    b.span, b.nShort = span, #shorts
    if #shorts == 0 then Q.skip(label, "no whole offset of this list's span (" .. H.n(span) .. " px) lands short"); return end
    local name, n = H.pickHold(shorts, span)
    if not name then Q.skip(label, "no row that need not be learned has an offset that lands short in its view range (" .. #shorts .. " of the span's offsets do)"); return end
    b.R, b.shorts = name, shorts
    local rd = H.row(name)
    b.title = tostring(rd and rd.entry and rd.entry.displayName)
    Q.say("B11-4: the list's span " .. H.n(span) .. " px (" .. H.n(g.totalH) .. " px of rows, a view of " .. H.n(g.viewH) .. " px): " .. #shorts .. " of its "
        .. (math.floor(span) + 1) .. " whole offsets land 1 px short as a share (" .. H.n(getTimestampMs() - t0) .. " ms to find); the row held: " .. b.title
        .. " (" .. tostring(rd and rd.status) .. ", " .. n .. (n >= 4 and " or more" or "") .. " such offsets in its view range), calm " .. tostring(ok))
    H.place(name, H.mid())
    b.go = true
end)
Q.step(3, function() if S.b4.go then H.open(S.b4.R, "B11-4, the row held") end end)
H.wait(6000, function() return not S.b4.go or H.cardUp(S.b4.R) end, function(ok)
    local b = S.b4
    if not b.go then return end
    if not ok then
        b.go = false
        local st = H.cst()
        Q.check(false, "B11-4: the held row's card opens from its row", "the open card: " .. tostring(st and st.selected))
    end
end)
-- the offsets, at a calm moment with the card up (the row's place in the list as the scans keep it)
H.frames(15000, 0, function()
    if not S.b4.go then return "now" end
    local st = H.cst()
    return st ~= nil and st.filterDirty == false and H.cardUp(S.b4.R) and H.calm(S.RUNWAY)
end, function(ok)
    local b = S.b4
    if not b.go then return end
    local why = H.chooseOffs(b.R, b.shorts, b.span)
    if why then
        b.go = false
        Q.skip("B11-4: a re-sort with the card open leaves the open recipe's row exactly where it was", b.title .. ": " .. why)
        return
    end
    local ws = {}
    for _, o in ipairs(b.offs) do ws[#ws + 1] = o.w .. (o.guard and " (lands exactly)" or "") end
    Q.say("B11-4: " .. b.title .. "'s card open, its row at " .. H.n(b.cy) .. " px down the list, in view from offset " .. H.n(b.lo) .. " to " .. H.n(b.hi)
        .. " px; offsets tried: " .. table.concat(ws, ", ") .. " (calm " .. tostring(ok) .. ")")
end)
for i = 1, 4 do
    H.holdTry(i)
    H.holdTry(i)
end
Q.step(1, function()
    local b = S.b4
    if not b.go then return end
    local label = "B11-4: with the card open, at offsets the old hold lands 1 px short of (floor((W / span) * span) = W - 1, span " .. H.n(b.span)
        .. " px), a re-sort leaves the open recipe's row exactly where it was, 0 px (old code: 1 px lower)"
    local parts, done, good = {}, 0, true
    local guard = nil
    for _, o in ipairs(b.offs) do
        if o.guard then guard = o
        else
            parts[#parts + 1] = H.offText(o)
            if o.done then done = done + 1; if not o.ok then good = false end end
        end
    end
    if done == 0 then Q.skip(label, "no offset was read clean: " .. table.concat(parts, "; ")) else Q.check(good, label, b.title .. ": " .. table.concat(parts, "; ")) end
    local glabel = "B11-4 (a guard): at an offset the old hold lands exactly, a re-sort leaves the row exactly where it was (passes on the old code too)"
    if not guard then Q.skip(glabel, "no offset next to the first lands exactly in the row's view range")
    elseif not guard.done then Q.skip(glabel, H.offText(guard))
    else Q.check(guard.ok == true, glabel, H.offText(guard)) end
end)
Q.step(3, function() if S.b4.go then H.shut() end end)

-- ===================================================================== put back
Q.mark()
-- (every line stands alone: one that throws does not stop the next)
Q.step(3, function()
    pcall(H.capOff)
    -- (the sort watch stays on until the scroll is read back: the calm moment for it reads the last sort)
    if S.dead then H.unwatch(); return end
    pcall(H.shut)
    pcall(RT.takeBack)
    pcall(function() if S.tableObj then H.removeObj(S.tableObj) end end)
    pcall(function() if S.stWas then ZeD.Stations.bind(S.p, S.stWas) end end)
    pcall(function() if S.dirWas then S.p:setDir(S.dirWas) end end)
    pcall(H.floorChanged)
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
        st.sortMenuOpen, st.showMenuOpen, st.catDropdownOpen, st.stDropdownOpen = false, false, false, false
        if S.searchWas then H.setSearch(st, k.search or "") end
    end)
end)
-- the list settled as found: filtered again, and the game's scan has answered for what was taken away (2 s); then
-- the card that was open, its picks and amount
H.frames(10000, 2000, function()
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
end)
-- the scroll set back at a calm moment (with a card open, a sort keeps the card's row where it was by moving the
-- scroll, so none may fall between the scroll set back and its reading)
H.frames(8000, 0, function()
    local st, k = H.cst(), S.keep
    if S.dead or not (st and k and S.craftSeen) then return "now" end
    return H.calm(400)
end, function()
    local st, k = H.cst(), S.keep
    if S.dead or not (st and k and S.craftSeen) then return end
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
    local w = RT.ww()
    local t = S.tabWas or "loot"
    if w and w._activeTab ~= t then pcall(H.tab, t) end
end)
Q.step(5, function()
    if S.dead then return end
    -- the Build tab's scroll as found (a press on it sets it to the top)
    pcall(function() local bs = H.bst(); if bs and bs.scroll and S.bscroll ~= nil then bs.scroll:setScrollPos(S.bscroll) end end)
    if S.pairWas == false then pcall(RT.pairShut) end
end)
Q.step(10, function()
    H.unwatch()
    pcall(H.capOff)
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
    Q.check(left == 0 and gone == 0 and floor == 0, "put back: he carries what he carried at the start, nothing of the script's left on him or on the floor beside him",
        tostring(S.swept) .. " stray things of the script's taken away, " .. left .. " of the script's still carried, " .. gone .. " of his own things not carried"
        .. ((gone > 0) and (" (" .. table.concat(goneSeen, ", ") .. ")") or "") .. ", " .. floor .. " of the script's on the floor"
        .. (((otherC + other) > 0) and ("; new and not the script's, left alone: " .. otherC .. " carried, " .. other .. " on the floor nearby") or ""))
    local hooks = S.CC.renderCraftCard == S.orig.card and ZeD.Molecules.drawSlotRow == S.orig.slot and ZeD.Molecules.drawCategoryRow == S.orig.cat
        and ZeD.Atoms.drawTextRight == S.orig.tr
    Q.check(not H.stands(S.tableObj) and hooks, "put back: no table left beside him, ZeD's card drawing as found",
        "the table standing " .. tostring(H.stands(S.tableObj)) .. ", the four drawing functions as found " .. tostring(hooks))
    local k, n = S.keep, S.stateNow
    if k and n and S.craftSeen then
        local same = n.show == k.show and n.showAll == k.showAll and n.sort == k.sort and n.cat == k.cat and (n.search or "") == (k.search or "")
            and n.sel == k.sel and (n.all and true or false) == (k.all and true or false) and (n.out and true or false) == (k.out and true or false)
            and (n.req and true or false) == (k.req and true or false) and (n.owned and true or false) == (k.owned and true or false)
        local field = nil
        local wwF = RT.ww()
        local fF = wwF and wwF._craftSearch or nil
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
    local bs = H.bst()
    local bNow = bs and bs.scroll and bs.scroll.scrollPos
    local bOk = S.bscroll == nil or (bNow ~= nil and math.abs(bNow - S.bscroll) < 0.0005)
    Q.check((S.tabWas == nil or tabNow == S.tabWas) and RT.isOpen() == S.pairWas and bOk, "put back: the World window's tab, the Build tab's scroll and the window pair as found",
        "tab " .. tostring(tabNow) .. " (found " .. tostring(S.tabWas) .. "), the Build tab's scroll " .. H.f4(bNow) .. " (found " .. H.f4(S.bscroll) .. "), the pair open "
        .. tostring(RT.isOpen()) .. " (found " .. tostring(S.pairWas) .. ")")
    RT.bounds(Q, "the end")
end)
Q.start()
