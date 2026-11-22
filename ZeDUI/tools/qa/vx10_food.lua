-- ZeDUI/tools/qa/vx10_food.lua  (Nov 21 2026, QA; tag vx10_food): the in-game proof of Build's fix for B10-3
-- (ZeDUI/qa/audits/2026-11-21_beast_batch10.md; Build's commit 2cff8f8f3, ItemFactsPanel.lua's NutritionFacts).
-- Built on rt_kit.lua (the global RT); run by vx10.txt after zedqa_prelude.lua and rt_kit.lua. grep "ZEDQA vx10_food".
-- No pictures. About 10 seconds.
--
-- B10-3  A frozen food's item card never said Frozen: a frozen steak's card read Cooked Raw and Fresh Fresh and nothing
--        about freezing, while its Boredom +30 and Happiness -30 were the game's frozen penalty; and food neither fresh
--        nor rotten had no freshness row at all.
--        Fixed: one row after Fresh. Labelled "Frozen" (the game's Tooltip_food_Frozen) while the food is frozen, else
--        "Freezing" (IGUI_invpanel_FreezingTime) while its freezing time is above 0; its value the percent only while
--        the freezing time is between 0 and 100, else "Frozen"; marked as a warning only while frozen and the food is
--        not ice cream or tagged goodfrozen (the game's penalty needs the frozen flag and spares those). Food neither
--        fresh nor rotten has a Fresh row reading "Stale" (Tooltip_food_Stale).
--
-- The scene: given to the character, a raw steak, a tub of ice cream, a popsicle (spared by the game's goodfrozen
-- tag, not by the name ice cream) and an apple aged to halfway between its fresh and its rotten day. Each card is read
-- the way the card reads it (ZeD.ItemFactsPanel.factsFor(item, playerNum): the facts every item card shows, as
-- bx_cook.lua's H.modelFresh reads them) in the same step as the food is staged. The steak's real card is also opened
-- once (a click on its row in the Character window's list, as bx_cook.lua opens a card) and its kept model (the
-- facts the card draws, built again every 250 ms) is read after each stage. Freezing is staged the game's way:
-- setFreezingTime (100 sets the frozen flag, 0 clears it, a value between leaves it), then setFrozen.
--
--   what is staged             what the card must show                                   on the old code
--   steak never frozen         no Freezing or Frozen row; Fresh reads Fresh               the same (a control)
--   steak partly frozen        a Freezing row after Fresh: 50%, not a warning             no such row: FAIL
--     (freezing 50, not frozen)
--   steak frozen through       a Frozen row after Fresh: Frozen (no percent), a warning   no such row: FAIL
--     (freezing 100, frozen)   Boredom and Happiness read the game's own                  the same (a guard: those
--                              getBoredomChange / getUnhappyChange (+30 / -30)            rows were right before)
--   steak half thawed          the Frozen row: 50%, still a warning; Boredom and          no such row: FAIL
--     (freezing 50, frozen)    Happiness still the game's (its penalty kept)              (the mood rows: a guard)
--   steak thawed (0)           the row is gone again                                      the same (a control)
--   ice cream frozen           a Frozen row: Frozen, not a warning; Boredom and           no such row: FAIL
--                              Happiness as the game has them (no penalty)
--   popsicle frozen            the same, spared through its tag                           no such row: FAIL
--   apple stale                the Fresh row reads Stale                                  no Fresh row: FAIL
--   the steak's open card      each steak stage again, in its kept model within 2.5 s     no such row: FAIL
--
-- Held still: the open card is read across frames, and ZeD's list ages every food it lists about once a second
-- (InventoryRenderer.lua, item:updateAge(): out of a freezer a frozen steak starts to thaw at once, and 99.6 of 100
-- already reads "100%"). So the steak is made one that neither freezes nor thaws for the run (setCanBeFrozen(false):
-- the game's freezing and thawing both ask it first); nothing the card or the game's boredom and unhappiness read
-- looks at that flag. The other foods are staged and read in one step, so nothing moves between.
-- A food the game does not stage as asked (its freezing not kept, ice cream not spared, an apple not stale) is a
-- SKIP with why, never a PASS. The window not showing the character's inventory list on screen (shut, rolled up, on a
-- bag) is a SKIP for the open card's checks.
-- A "no such row" read counts only on a food's facts (the nutrition panel with its Cooked row): no facts, or another
-- item's, is a FAIL, never a quiet PASS.
-- The row is clicked only once it stands whole in the list's view and a click at its middle lands on it: the list's
-- heading and buttons sit over its top and are hit first, so a half-hidden row's middle could press the Name heading
-- (a sort) instead. The list is stepped down in steps small enough for every row to stand whole at one of them, and
-- a group folded under the category sort is opened for the run (folded again in the put-back).
--
-- Put back: the four foods taken away (the open card follows the steak out of the bags and closes by itself; if it
-- stays, the Loot tab is pressed, as a player's click shuts it), the list's opened stack, its folded groups and its
-- scroll, the window's extra columns and its tab, the pair open or shut as found. No option is touched, nothing is
-- saved, no file is written.

if not (RT and RT.make) then
    print("ZEDQA vx10_food ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA vx10_food VERDICT FAIL 1")
    print("ZEDQA vx10_food DONE")
    return
end

local Q = RT.make("vx10_food")
Q.maxMs = 120000   -- (the runner allows 200 s, timeout=200 in vx10.txt: past 2:00 the queue jumps to the put-back)
local S = { p = RT.p, pn = RT.pn, was = {}, stackWas = {}, given = {}, L = {}, cols = {}, folds = {} }
local H = {}

-- the steak's stages, in order. label: the row the card must show ("freezing" or "frozen"; none: no such row);
-- pct: its value when a percent (else the game's "Frozen"); warn: marked as a warning
S.STAGES = {
    { short = "partly frozen", name = "steak partly frozen (freezing 50 of 100, not yet frozen)", ft = 50, frozen = false,
      label = "freezing", pct = "50%", warn = false,
      says = "a Freezing row after Fresh reading 50%, not marked as a warning" },
    { short = "frozen through", name = "steak frozen through (freezing 100 of 100)", ft = 100, frozen = true,
      label = "frozen", warn = true, mood = true,
      says = "a Frozen row after Fresh reading Frozen, no percent, marked as a warning" },
    { short = "half thawed", name = "steak half thawed (still frozen, 50 of 100 left)", ft = 50, frozen = true,
      label = "frozen", pct = "50%", warn = true, mood = true,
      says = "the Frozen row after Fresh reading 50%, still marked as a warning" },
    { short = "thawed", name = "steak thawed (0 of 100)", ft = 0, frozen = false,
      says = "no Freezing or Frozen row any more" },
}

-- ===================================================================== helpers: the queue and things
-- queue: from the next frame on, every frame until cond() holds or ms of real time pass; then fn(held)
function H.wait(ms, cond, fn)
    local st = {}
    Q.waitFor(1, math.floor(ms / 3) + 900, function()
        st.t = st.t or getTimestampMs()
        local okC, r = pcall(cond)
        if okC and r then st.ok = true; return true end
        return getTimestampMs() - st.t >= ms
    end, function() fn(st.ok == true) end)
end
function H.nm(it)
    if it == nil then return "nil" end
    local n = nil
    pcall(function() n = it:getDisplayName() end)
    return tostring(n or it)
end
function H.inv() return S.p:getInventory() end
function H.typeOf(inv) local t = "nothing"; pcall(function() t = tostring(inv:getType()) end); return t end
-- the container a thing is really in: its link, when that container's own list holds it
function H.where(it)
    local c = nil
    pcall(function() c = it:getContainer() end)
    if c == nil then return nil end
    local inList = true
    pcall(function() inList = c:getItems():contains(it) end)
    return inList and c or nil
end
function H.ftText(item)
    local ft, fr = nil, nil
    pcall(function() ft, fr = item:getFreezingTime(), item:isFrozen() end)
    return string.format("freezing %.1f, frozen %s", ft or -1, tostring(fr))
end

-- ===================================================================== helpers: the card's facts
-- the facts an item card shows, read as the card reads them (and the error when it threw)
function H.facts(item)
    local ok, panel = pcall(ZeD.ItemFactsPanel.factsFor, item, S.pn)
    if not ok then return nil, "factsFor: " .. tostring(panel) end
    return panel, nil
end
function H.row(panel, label)
    for _, g in ipairs((panel and panel.groups) or {}) do
        for _, r in ipairs(g.rows or {}) do if r.label == label then return r end end
    end
    return nil
end
-- the row the fix adds (labelled Freezing or Frozen) and the row just before it in its group
function H.freezeRow(panel)
    for _, g in ipairs((panel and panel.groups) or {}) do
        local rows = g.rows or {}
        for i, r in ipairs(rows) do
            if r.label == S.L.freezing or r.label == S.L.frozen then return r, rows[i - 1] end
        end
    end
    return nil, nil
end
-- the state rows (the group the Cooked row leads) in words: "Cooked Raw (bad); Fresh Fresh (good); Frozen Frozen (warn)"
function H.stateText(panel)
    for _, g in ipairs((panel and panel.groups) or {}) do
        local rows = g.rows or {}
        if rows[1] and rows[1].label == S.L.cooked then
            local out = {}
            for _, r in ipairs(rows) do
                out[#out + 1] = tostring(r.label) .. " " .. tostring(r.value) .. (r.valueClass and (" (" .. tostring(r.valueClass) .. ")") or "")
            end
            return table.concat(out, "; ")
        end
    end
    return panel and ("no Cooked row (facts " .. tostring(panel._key) .. ")") or "no facts"
end
-- a food's facts: the nutrition panel with its state rows (anything else proves nothing about the freezing row)
function H.isFood(panel)
    return panel ~= nil and panel._key == "nutrition" and H.row(panel, S.L.cooked) ~= nil
end
-- the freezing row as want says (want nil: no such row; else want.label, want.value, want.warn, and after Fresh);
-- either way only on a food's facts: no facts, or another item's, never reads as "no such row"
function H.freezeOK(panel, want)
    local r, before = H.freezeRow(panel)
    local text = H.stateText(panel)
    if not H.isFood(panel) then return false, text end
    if not want then return r == nil, text end
    if not r then return false, text end
    local warned = r.valueClass == "warn" or r.valueClass == "bad"
    local ok = r.label == want.label and r.value == want.value and warned == want.warn
        and before ~= nil and before.label == S.L.fresh
    return ok, text
end
function H.want(st)
    if not st.label then return nil end
    return { label = S.L[st.label], value = st.pct or S.L.frozen, warn = st.warn == true }
end
-- the game's own boredom and unhappiness for the food as it is, and with its frozen flag off (the penalty's size)
function H.game(item)
    local g = { b = 0, u = 0, b0 = 0, u0 = 0, frozen = false }
    pcall(function()
        g.frozen = item:isFrozen()
        g.b, g.u = item:getBoredomChange(), item:getUnhappyChange()
    end)
    g.b0, g.u0 = g.b, g.u
    if g.frozen then
        pcall(function()
            item:setFrozen(false)
            g.b0, g.u0 = item:getBoredomChange(), item:getUnhappyChange()
        end)
        pcall(function() item:setFrozen(true) end)
    end
    return g
end
-- a number as the card writes it: whole, signed ("+30", "-30", "+0")
function H.signed(v) return string.format("%+d", math.floor((v or 0) + 0.5)) end
-- the card's Boredom and Happiness rows against the game's numbers (the card writes happiness as minus unhappiness)
function H.moodOK(panel, item)
    local g = H.game(item)
    local br, hr = H.row(panel, S.L.boredom), H.row(panel, S.L.happy)
    local wantB, wantH = H.signed(g.b), H.signed(-g.u)
    local ok = br ~= nil and hr ~= nil and br.value == wantB and hr.value == wantH
    return ok, "Boredom " .. tostring(br and br.value) .. " (the game " .. wantB .. "), Happiness " .. tostring(hr and hr.value)
        .. " (the game " .. wantH .. "); the game's frozen penalty in them: boredom " .. H.signed(g.b - g.b0)
        .. ", unhappiness " .. H.signed(g.u - g.u0)
end
-- a food's freezing set as the game keeps it; true when the game kept what was asked
function H.stage(item, ft, frozen)
    local ok = pcall(function()
        item:setFreezingTime(ft)
        item:setFrozen(frozen and true or false)
    end)
    local nowFt, nowFr = -1, nil
    pcall(function() nowFt, nowFr = item:getFreezingTime(), item:isFrozen() end)
    return ok and math.abs(nowFt - ft) < 0.01 and nowFr == (frozen and true or false)
end
-- a food the game spares when frozen, frozen through and read (spared: its own test, true and the words why)
function H.frozenTreat(item, name, spared)
    local label = name .. " frozen"
    if not item then Q.skip(label, "it could not be given"); return end
    local isSpared, why = spared(item)
    if not isSpared then Q.skip(label, "the game does not count it as one meant to be frozen (" .. tostring(why) .. ")"); return end
    if not H.stage(item, 100, true) then Q.skip(label, "the game did not keep it frozen (" .. H.ftText(item) .. ")"); return end
    local g = H.game(item)
    if g.b - g.b0 > 0.5 or g.u - g.u0 > 0.5 then
        Q.skip(label, "the game puts its frozen penalty on it here (boredom " .. H.signed(g.b - g.b0) .. "), so it is not the case to prove")
        return
    end
    local panel, err = H.facts(item)
    local okR, text = H.freezeOK(panel, { label = S.L.frozen, value = S.L.frozen, warn = false })
    Q.check(okR, label .. ": its card has a Frozen row after Fresh reading Frozen, not marked as a warning (the game puts no frozen penalty on it)",
        err or text)
    local okM, mt = H.moodOK(panel, item)
    Q.check(okM, label .. ": its card's Boredom and Happiness read the game's own numbers", mt)
end
function H.isIcecream(it)
    local t = nil
    pcall(function() t = it:getType() end)
    return t == "Icecream", "type " .. tostring(t)
end
function H.taggedOnly(it)
    local tagged, t = false, nil
    pcall(function() tagged = it:hasTag(ItemTag.GOOD_FROZEN) and true or false end)
    pcall(function() t = it:getType() end)
    return tagged and t ~= "Icecream", "goodfrozen tag " .. tostring(tagged) .. ", type " .. tostring(t)
end

-- ===================================================================== helpers: the window, the row, the open card
function H.content() local w = RT.cw(); return w and w._mainContent end
function H.card() local w = RT.cw(); return w and w._itemCard end
function H.cardOn(item)
    local w = RT.cw()
    local c = w and w._itemCard
    return item ~= nil and w ~= nil and w._drawerItem == item and c ~= nil and c.item == item
end
-- the open card's kept model of the steak (what it draws), or nil
function H.model()
    local c = H.card()
    local m = c and c._model
    if m and H.cardOn(S.steak) and m.item == S.steak then return m end
    return nil
end
function H.rowZone(item)
    local c = H.content()
    for _, z in ipairs((c and c._hitZones) or {}) do if z.id == item then return z end end
    return nil
end
-- the row drawn last frame stands whole in the list's view (InventoryRenderer's _rowView; a grid has none) and a
-- click at its middle lands on it: the heading's and the buttons' zones come first (hitZoneAt takes the first), so
-- the middle of a row half under the heading would press "Name" (a sort) instead
function H.rowShown(item)
    local c, z = H.content(), H.rowZone(item)
    if not (c and z) then return false end
    local rv = c._rowView
    local grid = c._gv ~= nil and c._gv.on == true
    if not grid and not (rv and rv.top and rv.bottom and z.y >= rv.top and z.y + z.h <= rv.bottom) then return false end
    local hit = nil
    pcall(function() hit = c:hitZoneAt(z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)) end)
    return hit == z
end
-- (a condition, every frame: the row shown whole last frame, else the list one step further down; wraps at the
-- end. The step is at most half a view (the bar's size ratio r: a view is r / (1 - r) of the scroll), so every row
-- stands whole in the view at one of them, however long the list)
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
-- a plain click on the row, down and up at its middle; never the second of a double-click (that would eat it)
function H.click(item)
    local c = H.content()
    local z = H.rowZone(item)
    if not (c and z) then return false end
    local x, y = z.x + math.floor(z.w / 2), z.y + math.floor(z.h / 2)
    c._zedLastClick = nil
    local ok, err = pcall(function() c:onMouseDown(x, y); c:onMouseUp(x, y) end)
    if not ok then Q.check(false, "steak: the click on its row ran without an error", tostring(err)) end
    return ok
end
-- the Character window's tab strip pressed on a tab, as a click does (even on the tab already shown)
function H.pressTab(id)
    local w = RT.cw()
    local strip = w and w._tabStripPanel
    for _, z in ipairs((strip and strip._hitZones) or {}) do
        if z.id == "tab:" .. id then
            pcall(function() strip:onMouseDown(z.x + 2, z.y + 2) end)
            return true
        end
    end
    return false
end

-- ===================================================================== 0. the scene
Q.step(2, function()
    S.ok = ZeD ~= nil and ZeD.ItemFactsPanel ~= nil and ZeD.ItemFactsPanel.factsFor ~= nil and S.p ~= nil
    pcall(function()
        S.L.cooked = getText("Tooltip_food_Cooked")
        S.L.fresh = getText("Tooltip_food_Fresh")
        S.L.stale = getText("Tooltip_food_Stale")
        S.L.frozen = getText("Tooltip_food_Frozen")
        S.L.freezing = getText("IGUI_invpanel_FreezingTime")
        S.L.boredom = getText("Tooltip_food_Boredom")
        S.L.happy = ZeD.tr("UI_ZeD_Card_Happiness")
    end)
    local words = 0
    for _, k in ipairs({ "cooked", "fresh", "stale", "frozen", "freezing", "boredom", "happy" }) do
        if type(S.L[k]) == "string" and S.L[k] ~= "" then words = words + 1 end
    end
    S.ok = Q.check(S.ok and words == 7, "ZeD's item card facts are loaded and the game's words for the food rows read",
        "Frozen " .. tostring(S.L.frozen) .. ", Freezing " .. tostring(S.L.freezing) .. ", Stale " .. tostring(S.L.stale))
    if not S.ok then return end
    S.was.pair = RT.isOpen()
    RT.pairOpen()
end)
Q.step(20, function()
    if not S.ok then return end
    local w = RT.cw()
    S.was.charTab = w and w._activeTab
    -- (extra columns shut for the run, so the card opens over the plain list; opened again in the put-back)
    if w then
        pcall(function()
            for _, j in ipairs(w._mcSelected or {}) do
                local e = w._containers and w._containers[j]
                if e then S.cols[#S.cols + 1] = e.inventory end
            end
            if #S.cols > 0 then ZeD_CharacterWindow.closeColumns(w) end
        end)
    end
    RT.charTab("loot")
end)
Q.step(20, function()
    if not S.ok then return end
    local w, c = RT.cw(), H.content()
    local rolled = w ~= nil and (w._rolled == true or (w._halves ~= nil and w._halves.inv ~= nil and w._halves.inv.rolled == true))
    local mine = c ~= nil and c._inventory == H.inv()
    local shown = false
    if c then pcall(function() shown = c:isReallyVisible() and true or false end) end
    S.listOK = mine and not rolled and shown
    if w == nil then S.listWhy = "the Character window is not open"
    elseif rolled then S.listWhy = "its inventory side is rolled up"
    elseif not mine then S.listWhy = "it shows " .. H.typeOf(c and c._inventory) .. ", not the character's inventory"
    else S.listWhy = "its list is not on screen" end
    if S.listOK and c._scroll then S.scrollWas = c._scroll.scrollPos end
    S.steak, S.ice = RT.give("Base.Steak"), RT.give("Base.Icecream")
    S.pop, S.apple = RT.give("Base.Popsicle"), RT.give("Base.Apple")
    for _, k in ipairs({ "steak", "ice", "pop", "apple" }) do if S[k] then S.given[#S.given + 1] = S[k] end end
    Q.check(#S.given == 4, "staged: a raw steak, a tub of ice cream, a popsicle and an apple given to the character",
        H.nm(S.steak) .. ", " .. H.nm(S.ice) .. ", " .. H.nm(S.pop) .. ", " .. H.nm(S.apple))
    if S.steak then
        pcall(function() S.cbfWas = S.steak:canBeFrozen() end)
        pcall(function() S.steak:setCanBeFrozen(false) end)
        Q.say("NOTE the steak is held still for the run: it neither freezes nor thaws (setCanBeFrozen false)")
    end
end)

-- ===================================================================== 1. the steak never frozen, read as its card reads it
Q.step(2, function()
    if not (S.ok and S.steak) then return end
    if not H.stage(S.steak, 0, false) then
        Q.skip("steak never frozen", "its freezing could not be set to 0 (" .. H.ftText(S.steak) .. ")")
        return
    end
    local panel, err = H.facts(S.steak)
    local okR, text = H.freezeOK(panel, nil)
    local fr = H.row(panel, S.L.fresh)
    Q.check(okR and fr ~= nil and fr.value == S.L.fresh, "steak never frozen: its card has no Freezing or Frozen row, and Fresh reads Fresh",
        err or text)
end)

-- ===================================================================== 2. ice cream and a popsicle frozen; an apple gone stale
Q.step(2, function()
    if not S.ok then return end
    H.frozenTreat(S.ice, "ice cream", H.isIcecream)
    H.frozenTreat(S.pop, "popsicle (spared by the game's goodfrozen tag, not by the name ice cream)", H.taggedOnly)
end)
Q.step(2, function()
    if not S.ok then return end
    local label = "apple past its fresh days but not rotten"
    if not S.apple then Q.skip(label, "it could not be given"); return end
    local a0, a1 = -1, -1
    pcall(function()
        a0, a1 = S.apple:getOffAge(), S.apple:getOffAgeMax()
        S.apple:setAge(a0 + (a1 - a0) * 0.5)
    end)
    local fresh, rotten, age = nil, nil, -1
    pcall(function() fresh, rotten, age = S.apple:isFresh(), S.apple:isRotten(), S.apple:getAge() end)
    local ages = string.format("age %.1f days, fresh until %d, rotten from %d", age or -1, math.floor(a0 or -1), math.floor(a1 or -1))
    if fresh ~= false or rotten ~= false then
        Q.skip(label, "an age halfway between its fresh and its rotten day did not make it stale (" .. ages .. ")")
        return
    end
    local panel, err = H.facts(S.apple)
    local fr = H.row(panel, S.L.fresh)
    Q.check(fr ~= nil and fr.value == S.L.stale, label .. ": its card's Fresh row reads Stale", (err or H.stateText(panel)) .. "; " .. ages)
end)

-- ===================================================================== 3. the steak's real card, opened once from its row
Q.step(3, function()
    S.seekArm = false
    if not (S.ok and S.steak) then return end
    if not S.listOK then
        Q.skip("the steak's open card (its kept model after each stage)", "the Character window's list cannot show its row: " .. tostring(S.listWhy))
        return
    end
    local c = H.content()
    pcall(function()
        local ft = S.steak:getFullType()
        c._expandedStacks = c._expandedStacks or {}
        if S.stackWas[ft] == nil then S.stackWas[ft] = c._expandedStacks[ft] or false end
        c._expandedStacks[ft] = true
    end)
    -- (sorted by category, a folded group hides its rows: every fold opened for the run, folded again in the put-back)
    pcall(function()
        local cg = c._collapsedGroups
        if c._sortCol == "cat" and cg then
            for k, v in pairs(cg) do if v then S.folds[#S.folds + 1] = k end end
            for _, k in ipairs(S.folds) do cg[k] = nil end
            S.foldsOf = cg
        end
    end)
    S.seekPos = nil
    S.seekArm = true
end)
H.wait(10000, function() return not S.seekArm or H.seekRow(S.steak) end, function(held)
    if not S.seekArm then return end
    if Q.check(held, "steak: its row stands whole in the Character window's list, where a click lands on it", H.nm(S.steak)) then
        S.clicked = H.click(S.steak)
    end
end)
H.wait(3000, function() return not S.clicked or H.cardOn(S.steak) end, function(held)
    if not S.clicked then return end
    S.cardUp = Q.check(held, "steak: a click on its row opens its item card", "the card shows " .. H.nm(H.card() and H.card().item))
end)
H.wait(2500, function() return S.cardUp ~= true or H.model() ~= nil end, function(held)
    if S.cardUp ~= true then return end
    local m = H.model()
    local okR, text = H.freezeOK(m and m.facts, nil)
    Q.check(held and m ~= nil and okR, "the steak's open card, never frozen: no Freezing or Frozen row",
        m and text or "the card holds no model of the steak")
end)

-- ===================================================================== 4. the steak through its stages: its card's facts, then its open card
function H.queueStage(st)
    Q.step(3, function()
        S.arm = false
        if not (S.ok and S.steak) then return end
        if not H.stage(S.steak, st.ft, st.frozen) then
            Q.skip(st.name, "the game did not keep the staged freezing (" .. H.ftText(S.steak) .. ")")
            return
        end
        S.tStage = getTimestampMs()
        local panel, err = H.facts(S.steak)
        local okR, text = H.freezeOK(panel, H.want(st))
        Q.check(okR, st.name .. ": its card has " .. st.says, err or text)
        if st.mood then
            local okM, mt = H.moodOK(panel, S.steak)
            Q.check(okM, st.name .. ": its card's Boredom and Happiness read the game's own numbers, its frozen penalty in them", mt)
        end
        S.arm = S.cardUp == true
    end)
    H.wait(2500, function()
        local m = H.model()
        return not S.arm or (m ~= nil and (m.at or 0) > (S.tStage or 0))
    end, function(held)
        if not S.arm then return end
        local m = H.model()
        local built = held and m ~= nil
        local okR, text = H.freezeOK(m and m.facts, H.want(st))
        local why = text
        if not built then
            why = "the card did not build its facts again within 2.5 s" .. (H.cardOn(S.steak) and "" or "; it is no longer open on the steak")
        end
        Q.check(built and okR, "the steak's open card, " .. st.short .. ", within 2.5 s: " .. st.says, why)
        if st.mood and built then
            local okM, mt = H.moodOK(m.facts, S.steak)
            Q.check(okM, "the steak's open card, " .. st.short .. ": Boredom and Happiness read the game's own numbers", mt)
        end
    end)
end
for _, st in ipairs(S.STAGES) do H.queueStage(st) end

-- ===================================================================== put back
Q.mark()
Q.step(2, function()
    S.arm, S.seekArm, S.clicked = false, false, false
    pcall(function() if S.steak and S.cbfWas ~= nil then S.steak:setCanBeFrozen(S.cbfWas) end end)
    -- everything given, taken away: the open card follows the steak out of the bags and closes by itself
    RT.takeBack()
    local c = H.content()
    if c then
        pcall(function()
            if c._expandedStacks then
                for ft, was in pairs(S.stackWas) do c._expandedStacks[ft] = was or nil end
            end
        end)
        c._zedLastClick = nil
    end
    if S.foldsOf then for _, k in ipairs(S.folds) do S.foldsOf[k] = true end end
end)
H.wait(3000, function() local w = RT.cw(); return w == nil or w._drawerItem == nil end, function(held)
    -- (the card did not close by itself: the Loot tab is pressed, which shuts it as a player's click does)
    if not held then H.pressTab("loot") end
    local c = H.content()
    if c then
        c._selectedItems = {}
        c._lastClickedItem = nil
        if S.scrollWas and c._scroll and c._scroll.setScrollPos then pcall(function() c._scroll:setScrollPos(S.scrollWas) end) end
    end
    local w = RT.cw()
    local cardShut = w == nil or w._drawerItem == nil
    for _, inv in ipairs(S.cols) do pcall(ZeD_CharacterWindow.toggleColumn, inv, S.pn) end
    if S.was.charTab and S.was.charTab ~= "loot" then RT.charTab(S.was.charTab) end
    local left = {}
    for _, it in ipairs(S.given) do if H.where(it) ~= nil then left[#left + 1] = H.nm(it) end end
    Q.check(#left == 0 and cardShut, "put back: every food given is taken away and the item card is closed",
        ((#left == 0) and "nothing left" or ("left: " .. table.concat(left, ", "))) .. (held and "" or "; the card stayed open, the Loot tab pressed"))
end)
Q.step(5, function() if S.was.pair == false then RT.pairShut() end end)
Q.start()
