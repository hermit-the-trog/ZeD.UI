-- ZeDUI/tools/qa/zedqa_inventory_filter.lua  (Nov 11 2026, Build): the inventory Filter (punch list 168) in game.
-- QA save only (Saves/Sandbox/ZeD-QA), the character on open ground (the drag strip). Copy to Zomboid/Lua/zedqa.lua,
-- bump zedqa.go, grep console.txt for "ZEDQA flt". PASS / FAIL lines, ending DONE.
-- Screenshots/zqa_flt_*.png: take the set at 4K 1.75x, then again at the Deck size (1280x800, Auto, Normal and Large
-- text); the script does not resize.
--   1  things given (cans, apples, bandages, a candle) and things on the floor (scrap and sheet metal, a pipe, rope)
--   2  Character window: Filter opens the bar; "can": Canned Corn / Chili, Can Opener, Candle bright, the rest faded in
--      place (no row gone); the count "N of M"; a Food chip narrows to the two cans; a second chip widens
--   3  Grid view: the same filter, cells faded, matched cells edged; back to List
--   4  "chainsaw": the count says Nothing matches, every row faded, none hidden
--   5  saved: the character's mod data holds the filter by the inventory's key; a new filter state (as after a reload)
--      takes it back; Clear takes it off
--   6  World window: one filter for the floor's column(s); "metal"; its chips are the floor's categories
--   7  controller: the Filter button, the field, Clear and the chips are ring stops; X clears; A on Filter shuts it
--   8  cleanup: both filters shut and cleared, the things taken away
local function say(s) print("ZEDQA flt " .. tostring(s)) end
local fails = 0
local function check(ok, what, extra) if not ok then fails = fails + 1 end; say((ok and "PASS " or "FAIL ") .. what .. (extra ~= nil and (" | " .. tostring(extra)) or "")) end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_flt_" .. n .. ".png") end) end
local p = getPlayer()
local IF, IR = ZeD.InvFilter, ZeD.InventoryRenderer
local Det = ZeD.Input.Detector
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local function CC() local w = CWm.getWindow(); return w and w._mainContent end
local function WC() local w = WWm.getWindow(); return w and w._mainContent end
local GIVEN, FLOOR = {}, {}

local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end

local function give(full, n)
    for _ = 1, n do
        local ok, it = pcall(function() return p:getInventory():AddItem(full) end)
        if ok and it then GIVEN[#GIVEN + 1] = it end
    end
end
local function drop(full, n)
    local sq = p:getCurrentSquare()
    for _ = 1, n do
        local ok, it = pcall(function() return sq:AddWorldInventoryItem(full, 0.5, 0.5, 0) end)
        if ok and it then FLOOR[#FLOOR + 1] = it end
    end
end
local function rows(c) return c and c._flatItems and #c._flatItems or 0 end
local function ringHas(win, id)
    for _, z in ipairs(win._focusRing or {}) do
        for _, e in ipairs(z.elements or {}) do if e.id == id then return e end end
    end
end

-- 1  the things
add(300, function()
    p:setGodMod(true)
    give("Base.CannedCorn", 3); give("Base.CannedChili", 2); give("Base.Apple", 4); give("Base.TinOpener", 1)
    give("Base.Candle", 2); give("Base.Bandage", 4)
    drop("Base.ScrapMetal", 4); drop("Base.SheetMetal", 2); drop("Base.MetalPipe", 1); drop("Base.Rope", 1)
    say("given " .. #GIVEN .. ", on the floor " .. #FLOOR)
    if not CWm.isOpen() then CWm.toggleBothPaired(0) end
end)

-- 2  the Character window
local before
add(1500, function()
    local c = CC()
    check(c ~= nil, "the Character window's list is there")
    local S = IF.of(c)
    check(S.shown, "the window has a Filter (its heading shows)")
    before = rows(c)
    shot("01_char_off")
    IF.act(S, "filter")
    IF.setQuery(S, "can")
end)
add(800, function()
    local c = CC(); local S = IF.of(c)
    check(S.open and c._fbarH and c._fbarH > 0, "the bar is open under the heading", c._fbarH)
    check(rows(c) == before, "no row hidden by the filter", rows(c) .. " vs " .. before)
    check(c._fres and c._fres.active, "the list dims by it")
    check(S.agg and S.agg.matched >= 8, "the count: things whose name holds 'can'", IF.countText(S, S.agg))
    shot("02_char_can")
    IF.toggleCat(S, "Food")
end)
add(800, function()
    local c = CC(); local S = IF.of(c)
    check(S.agg and S.agg.matched >= 5 and S.agg.matched < 8, "a Food chip narrows to the cans", IF.countText(S, S.agg))
    shot("03_char_can_food")
    IF.setQuery(S, "")
    IF.toggleCat(S, "FirstAid")
end)
add(800, function()
    local c = CC(); local S = IF.of(c)
    check(S.nCats == 2 and S.agg.matched >= 8, "a second chip widens", IF.countText(S, S.agg))
    shot("04_char_two_chips")
    IF.clear(S)
    IF.setQuery(S, "can")
    IR.setGridKey("player", true)
end)
-- 3  the grid
add(1000, function()
    local c = CC()
    check(c._gridCell ~= nil, "the grid shows, the same filter on it")
    shot("05_char_grid")
    IR.setGridKey("player", false)
    IF.setQuery(IF.of(c), "chainsaw")
end)
-- 4  nothing matches
add(800, function()
    local c = CC(); local S = IF.of(c)
    check(S.agg.matched == 0 and IF.countText(S, S.agg) == ZeD.tr("UI_ZeD_Inv_FilterNone"), "nothing matches says so")
    check(rows(c) == before, "and every row is still there, faded")
    shot("06_char_nothing")
    IF.setQuery(S, "can")
    IF.toggleCat(S, "Food")
end)
-- 5  saved
add(600, function()
    local md = p:getModData().ZeD_Filters or {}
    check(md.player == "can\nFood", "saved on the inventory's key", tostring(md.player))
    local c = CC()
    IF.hideField(c._zedFilter)
    c._zedFilter = nil   -- (a new state, as after a reload)
end)
add(800, function()
    local S = IF.of(CC())
    check(S.open and S.q == "can" and S.cats.Food, "a new window takes the saved filter back", S.q)
    shot("07_char_restored")
    IF.clear(S)
    check((p:getModData().ZeD_Filters or {}).player == nil, "Clear takes it off")
    IF.act(S, "filter")
end)
-- 6  the World window
add(1000, function()
    local c = WC()
    check(c ~= nil, "the World window's list is there")
    local S = IF.of(c)
    shot("08_world_off")
    IF.act(S, "filter")
    IF.setQuery(S, "metal")
end)
add(800, function()
    local c = WC(); local S = IF.of(c)
    check(S.open and S.agg and S.agg.matched >= 7, "the floor narrowed to the metal", IF.countText(S, S.agg))
    local keys = {}
    for _, ch in ipairs(S.agg.chips) do keys[#keys + 1] = ch.key .. "=" .. ch.n end
    say("world chips " .. table.concat(keys, " "))
    check(not IF.active(IF.of(CC())), "the Character window's filter is its own (still off)")
    shot("09_world_metal")
end)
-- 7  the controller
add(500, function() Det.setLockedMode(Det.MODE_GAMEPAD) end)
add(1200, function()
    local w = WWm.getWindow()
    local fld, clr = ringHas(w, "view:fbar:field"), ringHas(w, "view:fbar:clear")
    local chip
    for _, z in ipairs(w._focusRing or {}) do
        for _, e in ipairs(z.elements or {}) do if type(e.id) == "string" and e.id:sub(1, 15) == "view:fbar:chip:" then chip = e end end
    end
    check(fld ~= nil and clr ~= nil and chip ~= nil, "the field, Clear and the chips are stops")
    check(fld and fld.promptA == ZeD.tr("UI_ZeD_Inv_PromptType"), "A on the field says Type")
    shot("10_world_pad")
    if chip then chip.onActivate(w, chip) end
end)
add(600, function()
    local w = WWm.getWindow(); local S = IF.of(WC())
    check(S.nCats == 1, "A on a chip picks it")
    local clr = ringHas(w, "view:fbar:clear")
    if clr then clr.onContextMenu(w) end
end)
add(600, function()
    local w = WWm.getWindow(); local S = IF.of(WC())
    check(not IF.active(S) and S.open, "X clears, the bar stays")
    local fb
    for _, z in ipairs(w._focusRing or {}) do
        for _, e in ipairs(z.elements or {}) do if e.view == "filter" then fb = e end end
    end
    check(fb ~= nil, "the Filter button is a stop")
    if fb then fb.onActivate(w, fb) end
end)
-- 8  cleanup
add(600, function()
    check(not IF.of(WC()).open, "A on Filter shuts the bar")
    Det.setLockedMode(nil)
    local S = IF.of(CC())
    if S.open then IF.act(S, "filter") end
    for _, it in ipairs(GIVEN) do pcall(function() p:getInventory():Remove(it) end) end
    for _, it in ipairs(FLOOR) do pcall(function()
        local wo = it:getWorldItem()
        if wo then wo:getSquare():transmitRemoveItemFromSquare(wo); wo:removeFromSquare() end
    end) end
    say("fails " .. fails)
    say("DONE")
end)

local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
