-- ZeDUI/tools/qa/inventory_filter_sim.lua  (Nov 11 2026, Build): the inventory Filter (punch list 168), with no game
-- running. InventoryFilter.lua runs whole; from InventoryRenderer.lua it cuts the list model (buildItemModel, so
-- stacks are the real ones), the Filter's frame / column / row-mark helpers and its pad stops (toggleElements), and
-- runs them on stub panels.
--   NAME      the typed text matches names holding it, any case ("can": Canned Corn, Can Opener, Candle)
--   CATEGORY  a chip keeps one category; several chips widen; text and chips together narrow
--   DIM       the rows stay (the model is the same with or without a filter); a row that does not match is drawn
--             faded (a rect at DIM_A), one that matches is not, the matched letters underlined; the row the
--             controller is on never fades; a category row with nothing matching fades
--   COUNT     items, not rows ("8 of 50": a stack of 4 counts 4); "Nothing matches"; the plain count when idle
--   CLEAR     Clear empties text and chips and keeps the bar open; the Filter button shuts and clears
--   SAVED     the filter is written to every container the window shows (by its key), taken back by a new window
--             after a reload (a new panel, the same mod data), emptied for a container with none, and a
--             container shown again gets its own back; clearing takes it off
--   WINDOWS   the World window's columns share one filter (one count across them, one chip list, the saved filter
--             on each); the Character window's filter is its own
--   GRID      a cell is a stack's head: it dims by the head's match, which is the stack's (same name, same
--             category); the grid's draw is wired to the same test
--   STACKS    an open stack's rows each match, the stack counts every item
--   ONCE      the matches are worked out once per change: frames with nothing changed ask no item anything, make no
--             new count and lay nothing out again
--   PAD       the Filter button, the field, Clear and each chip are stops; the bar's ground is not; A on a chip
--             picks it, X clears, the field's A prompt is Type
--   FLOOR KEY the floor (the game's one floor container: the real containerKey gives "type:floor" in every town) and
--             a car not yet saved keep no filter: typed on the floor it is not saved, a new window on the floor opens
--             unfiltered, a crate shown beside the floor is never given its filter, and one an old save kept is let go
--   TIMED     the real itemModel builds each column's model again about once a second with nothing changed: the count
--             stays the same table and the bar is not laid out again (no pad stops rebuilt) for ten seconds; a new
--             thing in a crate changes the count without moving a stop; a narrower window moves them
--   COLUMNS   the real Loot column refresh of both windows (charMC / worldMC, on the real FocusManager): the pad on
--             the Filter button, Clear or a chip in a column's zone stays there when the bar is laid out again
--   EDGE      the real press code of both windows on the real scrollbar: a press on Clear's right end (the strip
--             beside the scrollbar under the heading) is the bar's, not the scrollbar's; the scrollbar reads a press
--             and a drag on its own y
-- Run from the repo root:  lua51 ZeDUI/tools/qa/inventory_filter_sim.lua
-- It prints FAIL lines and a last line "inventory_filter_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]inventory_filter_sim%.lua$", "")

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end

local function readFile(path)
    local f = assert(io.open(ROOT .. path, "rb"))
    local s = f:read("*a")
    f:close()
    return (s:gsub("\r\n", "\n"))
end

-- ---------------------------------------------------------------------------
-- STUBS
-- ---------------------------------------------------------------------------
local NOW = 1762500000000
getTimestampMs = function() return NOW end
Events = { OnContainerUpdate = { Add = function() end }, OnClothingUpdated = { Add = function() end } }
instanceof = function() return false end
getSoundManager = function() return { playUISound = function() end } end

local function rgb(r, g, b, a) return { r = r, g = g, b = b, a = a or 1 } end
ZeD = {}
-- (Atoms.lua's: a window's player number, split view)
ZeD.playerNumOf = function(w) local p = w and w._playerObj; return p and p.getPlayerNum and p:getPlayerNum() or 0 end
ZeD._trGen = 1
ZeD.T = {
    px = function(n) return n end, scale = 1, inputH = 22, buttonH = 24, hair = 1,
    sp = { sm = 10, buttonPadX = 12, scrollbarW = 14 },
    fontF1 = "F1", fontF2 = "F2", fontF3 = "F3", fontF5 = "F5",
    base = rgb(0.1, 0.1, 0.12), accent = rgb(0.28, 0.63, 0.55), accentText = rgb(0.3, 0.7, 0.6),
    text = rgb(0.8, 0.8, 0.8), textDim = rgb(0.5, 0.5, 0.5), toneNorm = rgb(0.8, 0.8, 0.8),
    textOnAccent = rgb(0, 0, 0), textOnFocus = rgb(0, 0, 0), surf1 = rgb(0.13, 0.13, 0.15), surf2 = rgb(0.16, 0.16, 0.18),
    borderS = rgb(1, 1, 1, 0.2), hover = rgb(1, 1, 1, 0.08),
}
ZeD.TM = {
    MeasureStringX = function(_, font, s) return #tostring(s) * 7 end,
    getFontHeight = function(_, font) return 14 end,
}
ZeD.tr = function(key, ...)
    local out = key
    for _, v in ipairs({ ... }) do out = out .. "|" .. tostring(v) end
    return out
end
ZeD.btnCase = function(s) return s end
ZeD.Atoms = {
    frame = function(p, x, y, w, h, c) p:drawRect(x, y, w, 1, c.a or 1, c.r, c.g, c.b) end,
    drawDividerH = function() end,
    truncateText = function(s) return s end,
    mouseIn = function() return false end,
}
ZeD.Molecules = { drawButton = function(p, x, y, w, h, text, v, pr, col, opts) p._buttons[#p._buttons + 1] = { text = text, opts = opts } end }
ZeD.Surface = { fill = function() end }
ZeD.Focus = { mark = function() return true end }
ZeD.Help = { set = function() end }
ZeD.ItemMeter = { sortKey = function() return 1 end }
ZeD.ContainerGates = { get = function() return nil end, keeps = function() return true end }
ZeD.ContainerGroups = { groupOf = function() return nil end, keys = function() return {} end,
                        sortKeys = function(k) table.sort(k) end, sig = function() return false end }
ZeD.InventoryRenderer = {
    catKey = function(item)
        local dc = item:getDisplayCategory()
        if dc and dc ~= "" then return dc end
        return item:getCategory() or "Other"
    end,
    catLabel = function(key) return "L:" .. tostring(key) end,
    setGridKey = function() end,
}
stackWeight = function(s) local t = 0 for _, i in ipairs(s.items) do t = t + i:getUnequippedWeight() end return t end

-- every name asked counts (the "once per change" checks)
local NAMES_ASKED = 0

-- ---------------------------------------------------------------------------
-- THE THINGS: the mockup's two windows (Character: your inventory; World: a crate and a shelf)
-- ---------------------------------------------------------------------------
local function list(t) return { size = function() return #t end, get = function(_, i) return t[i + 1] end } end
local idN = 0
local function mkInv(key, rows)
    local inv = { key = key, things = {} }
    function inv:getItems() return list(self.things) end
    function inv:getParent() return nil end
    function inv:getCapacityWeight() return #self.things end
    for _, r in ipairs(rows) do
        for _ = 1, r[3] do
            idN = idN + 1
            local nm, cat = r[1], r[2]
            local it = { id = idN, nm = nm, cat = cat }
            function it:getName() NAMES_ASKED = NAMES_ASKED + 1; return nm end
            function it:getDisplayCategory() return cat end
            function it:getCategory() return cat end
            function it:getFullType() return "Base." .. nm:gsub("%W", "") end
            function it:isHidden() return false end
            function it:getContainer() return inv end
            function it:getUnequippedWeight() return 0.5 end
            inv.things[#inv.things + 1] = it
        end
    end
    return inv
end
local CHAR = mkInv("player", {
    { "Chest Rig", "Bag", 1 }, { "ValuTech Walkie Talkie", "Communications", 1 }, { "Can Opener", "Cooking", 1 },
    { "Bandage", "FirstAid", 4 }, { "Disinfectant", "FirstAid", 1 }, { "Painkillers", "FirstAid", 1 },
    { "Apple", "Food", 4 }, { "Canned Corn", "Food", 3 }, { "Canned Chili", "Food", 2 }, { "Chocolate", "Food", 1 },
    { "Crisps", "Food", 2 }, { "Matches", "FireSource", 1 }, { "Candle", "LightSource", 2 },
    { "Flashlight", "LightSource", 1 }, { "Duct Tape", "Material", 2 }, { "Ripped Sheets", "Material", 8 },
    { "Nails", "Material", 10 }, { "Hammer", "ToolWeapon", 1 }, { "Kitchen Knife", "ToolWeapon", 1 },
    { "Screwdriver", "Tool", 1 }, { "Water Bottle", "Water", 1 },
})
local CRATE = mkInv("obj:10,20,0:crate", {
    { "Battery", "Electronics", 4 }, { "Scrap Metal", "Material", 6 }, { "Sheet Metal", "Material", 3 },
    { "Rope", "Material", 1 }, { "Metal Pipe", "Weapon", 2 }, { "Wrench", "Tool", 1 },
})
local SHELF = mkInv("obj:11,20,0:shelf", {
    { "Small Metal Sheet", "Material", 2 }, { "Gas Can", "VehicleMaintenance", 1 }, { "Jack", "VehicleMaintenance", 1 },
})
containerKeyOf = function(inv) return inv and inv.key end
gpFocusedToggle = function() return nil end

-- ---------------------------------------------------------------------------
-- LOAD
-- ---------------------------------------------------------------------------
local IF = assert(loadstring(readFile("42/media/lua/client/ZeD/InventoryFilter.lua"), "@InventoryFilter.lua"))()
IF = ZeD.InvFilter
check("InventoryFilter.lua loads", type(IF) == "table" and type(IF.result) == "function")
local IR = readFile("42/media/lua/client/ZeD/InventoryRenderer.lua")
local function cutChunk(from, to, ret, name)
    local a = IR:find(from, 1, true)
    local b = a and IR:find(to, a, true)
    check("cut " .. name, a ~= nil and b ~= nil)
    return assert(loadstring(IR:sub(a, b - 1) .. "\n" .. ret, name))()
end
local itemModel, buildItemModel = cutChunk("local MODEL_REFRESH_MS", "-- ROW PARTS", "return itemModel, buildItemModel", "model")
local filterFrame, filterColumn, filterEnd, filterDim, filterRowMarks = cutChunk("local IFL = ZeD.InvFilter",
    "-- The grid's state for one column", "return filterFrame, filterColumn, filterEnd, filterDim, filterRowMarks", "filter")
cutChunk("-- The Filter's stops (its button", "-- is this item the controller's focused element", "return true", "stops")
local toggleElements = ZeD.InventoryRenderer.toggleElements

local function model(inv, expanded)
    return buildItemModel(inv, nil, false, "cat", true, {}, expanded or {})
end

-- a list panel as the windows make it (the Character window: one list, its heading 37 high)
local STORE = {}
local function mkPanel(inv, cols)
    local p = { _inventory = inv, _hdrYOffset = 37, _defaultHdrYOffset = 37, _barH = 0, _rects = {}, _buttons = {} }
    if cols then
        p._colStates = {}
        for i, c in ipairs(cols) do p._colStates[i] = { inventory = c } end
    end
    function p:getWidth() return 420 end
    function p:drawRect(x, y, w, h, a) self._rects[#self._rects + 1] = { x = x, y = y, w = w, h = h, a = a } end
    function p:drawText() end
    IF.of(p).store = STORE
    return p
end
local function frame(p, multi, models)
    filterFrame(p, multi)
    for _, M in ipairs(models) do filterColumn(p, M) end
    p._rects, p._buttons = {}, {}
    filterEnd(p)
end
local function names(set)
    local out = {}
    for it in pairs(set) do out[#out + 1] = it.nm end
    table.sort(out)
    local u, last = {}, nil
    for _, n in ipairs(out) do if n ~= last then u[#u + 1] = n; last = n end end
    return table.concat(u, ",")
end

-- ---------------------------------------------------------------------------
section("NAME / CATEGORY")
local charP = mkPanel(CHAR)
local S = IF.of(charP)
local MC = model(CHAR)
frame(charP, false, { MC })
check("the bar starts shut, nothing narrows", not S.open and not IF.active(S) and charP._fres == nil)
IF.toggleOpen(S)
check("the Filter button opens the bar", S.open)
IF.setQuery(S, "CAN")
local r = IF.result(S, MC)
check("NAME: 'CAN' finds every name holding it, any case", names(r.match) == "Can Opener,Candle,Canned Chili,Canned Corn", names(r.match))
check("NAME: things count, not rows (1 + 2 + 2 + 3)", r.matched == 8, r.matched)
local total = #CHAR.things
check("NAME: the total is every thing in the list", r.total == total, r.total)
IF.setQuery(S, "NED")
r = IF.result(S, MC)
local corn
for _, it in ipairs(CHAR.things) do if it.nm == "Canned Corn" then corn = it end end
check("NAME: where the text starts in the name is kept (caNNED Corn: 4)", r.hit[corn] == 4, r.hit[corn])
IF.setQuery(S, "")
IF.toggleCat(S, "Food")
r = IF.result(S, MC)
check("CATEGORY: one chip keeps one category", names(r.match) == "Apple,Canned Chili,Canned Corn,Chocolate,Crisps", names(r.match))
IF.toggleCat(S, "FirstAid")
r = IF.result(S, MC)
check("CATEGORY: several chips widen", r.matched == 12 + 6, r.matched)
IF.toggleCat(S, "FirstAid")
IF.setQuery(S, "can")
r = IF.result(S, MC)
check("NARROW: text and a chip together narrow", names(r.match) == "Canned Chili,Canned Corn" and r.matched == 5, names(r.match))
check("NARROW: the chips' counts follow the text (Cooking 1, Food 5, Light 2)",
    r.catNamed.Cooking == 1 and r.catNamed.Food == 5 and r.catNamed.LightSource == 2 and r.catNamed.Material == 0)

section("COUNT")
frame(charP, false, { MC })
local agg = S.agg
check("COUNT: '5 of N' across the window", IF.countText(S, agg) == "UI_ZeD_Inv_FilterCount|5|" .. total, IF.countText(S, agg))
local chipKeys = {}
for _, c in ipairs(agg.chips) do chipKeys[#chipKeys + 1] = c.key .. "=" .. c.n .. (c.on and "*" or "") end
check("COUNT: a chip per category in the list, by label, the picked one marked",
    table.concat(chipKeys, " ") == "Bag=0 Communications=0 Cooking=1 FireSource=0 FirstAid=0 Food=5* LightSource=2 Material=0 Tool=0 ToolWeapon=0 Water=0",
    table.concat(chipKeys, " "))
IF.setQuery(S, "chainsaw")
frame(charP, false, { MC })
check("COUNT: nothing matches says so", IF.countText(S, S.agg) == "UI_ZeD_Inv_FilterNone")

section("DIM")
IF.clear(S)
IF.setQuery(S, "can")
local ME = model(CHAR, { ["Base.CannedCorn"] = true, ["Base.Bandage"] = true })
local M0 = model(CHAR, { ["Base.CannedCorn"] = true, ["Base.Bandage"] = true })
frame(charP, false, { ME })
check("DIM: the rows are the same with the filter on (nothing hidden)", #ME.flatItems == #M0.flatItems, #ME.flatItems .. " vs " .. #M0.flatItems)
local fr = charP._fres
check("DIM: the list knows the filter narrows", fr ~= nil and fr.active)
local dimmed, bright, underlined = 0, 0, 0
for _, item in ipairs(ME.flatItems) do
    charP._rects = {}
    filterRowMarks(charP, fr, item, 40, 5, item.nm, 0, 0, 400, 30, false)
    local d = charP._rects[1]
    if d and d.a == IF.DIM_A then dimmed = dimmed + 1
    else
        bright = bright + 1
        if d and d.h == 1 then underlined = underlined + 1 end
        check("DIM: a bright row matches (" .. item.nm .. ")", fr.match[item] == true)
    end
end
local nMatchRows = 0
for _, item in ipairs(ME.flatItems) do if fr.match[item] then nMatchRows = nMatchRows + 1 end end
check("DIM: every row that does not match is faded", dimmed == #ME.flatItems - nMatchRows, dimmed)
check("DIM: every row that matches is underlined where it matched", underlined == bright and bright == nMatchRows, underlined)
charP._rects = {}
local apple
for _, it in ipairs(CHAR.things) do if it.nm == "Apple" then apple = it end end
filterRowMarks(charP, fr, apple, 40, 5, "Apple", 0, 0, 400, 30, true)
check("DIM: the row the controller is on is never faded", #charP._rects == 0)
charP._rects = {}
filterRowMarks(charP, fr, CHAR.things[3], 40, 5, "Can Op...", 0, 0, 400, 30, false)
check("DIM: a matched name cut short where the match still shows is underlined", #charP._rects == 1 and charP._rects[1].h == 1)
check("DIM: a category with nothing matching knows it (Material 0, Food 5)", (fr.catMatched.Material or 0) == 0 and fr.catMatched.Food == 5)
check("DIM: the category rows are wired to fade", IR:find("if fr and (fr.catMatched[cat] or 0) == 0 then filterDim(self, x, y, w, h) end", 1, true) ~= nil)

section("STACKS / GRID")
local cornN, cornRows = 0, 0
for _, item in ipairs(ME.flatItems) do
    if item.nm == "Canned Corn" then cornRows = cornRows + 1; if fr.match[item] then cornN = cornN + 1 end end
end
check("STACKS: an open stack's rows each match (Canned Corn x3 open: 3 rows)", cornRows == 3 and cornN == 3, cornRows .. "/" .. cornN)
local bandRows = 0
for _, item in ipairs(ME.flatItems) do if item.nm == "Bandage" and not fr.match[item] then bandRows = bandRows + 1 end end
check("STACKS: an open stack that does not match fades every row (Bandage x4)", bandRows == 4, bandRows)
local okCells, cells = true, 0
for _, item in ipairs(ME.flatItems) do
    local s = ME.stacks[item]
    if s and not ME.childParent[item] then
        cells = cells + 1
        for _, si in ipairs(s.items) do if (fr.match[si] == true) ~= (fr.match[item] == true) then okCells = false end end
    end
end
check("GRID: a cell (a stack's head) matches exactly when its whole stack does", okCells and cells > 0, cells)
check("GRID: the cells are wired to the same test (edge on a match, faded otherwise, not under the pad's mark)",
    IR:find("if fr.ql ~= \"\" then ZeD.Atoms.frame(self, ax, cy, cell, cell, T.accent) end", 1, true) ~= nil
    and IR:find("elseif not fo then\n            filterDim(self, ax, cy, cell, cell)", 1, true) ~= nil)
check("LIST: the rows are wired to the marks", IR:find("filterRowMarks(self, self._fres, item, xOff + nameX + childIndent + chevW, textY, displayName", 1, true) ~= nil)

section("CLEAR")
IF.clear(S)
check("CLEAR: text and chips empty, the bar stays open", S.q == "" and S.nCats == 0 and S.open and not IF.active(S))
frame(charP, false, { MC })
check("CLEAR: nothing fades once cleared", charP._fres == nil)
check("CLEAR: the idle count is the item count", IF.countText(S, S.agg) == "UI_ZeD_Inv_ItemsMany|" .. total)
IF.setQuery(S, "apple")
IF.toggleOpen(S)
check("CLEAR: the Filter button shuts the bar and clears it", not S.open and S.q == "" and not IF.active(S))
frame(charP, false, { MC })
check("CLEAR: a shut bar takes no room and dims nothing", charP._fbarH == 0 and charP._fres == nil)

section("SAVED (per container, across a reload)")
IF.toggleOpen(S)
IF.setQuery(S, "can")
IF.toggleCat(S, "Food")
check("SAVED: the Character window's filter is on its container", STORE["player"] == "can\nFood", STORE["player"])
local q2, c2 = IF.decode(IF.encode(S))
check("SAVED: encode / decode round trip", q2 == "can" and #c2 == 1 and c2[1] == "Food")
-- a reload: a new window, a new panel, the same mod data
local charP2 = mkPanel(CHAR)
frame(charP2, false, { model(CHAR) })
local S2 = IF.of(charP2)
check("SAVED: after a reload the window takes the container's filter back, bar open", S2.q == "can" and S2.cats.Food and S2.open)
check("SAVED: and narrows at once", charP2._fres ~= nil and charP2._fres.matched == 5)

-- the World window: two columns, crate and shelf, one filter
local worldP = mkPanel(nil, { CRATE, SHELF })
local SW = IF.of(worldP)
local MCr, MSh = model(CRATE), model(SHELF)
frame(worldP, true, { MCr, MSh })
check("WINDOWS: the World window's filter is its own (the Character window's is not in it)", not IF.active(SW) and not SW.open)
IF.toggleOpen(SW)
IF.setQuery(SW, "metal")
frame(worldP, true, { MCr, MSh })
check("WINDOWS: one filter narrows both columns (Scrap 6 + Sheet 3 + Pipe 2, Small Metal Sheet 2)",
    SW.agg.matched == 13 and SW.agg.total == 17 + 4, SW.agg.matched .. " of " .. SW.agg.total)
check("WINDOWS: both columns dim by it", MCr._fres.active and MSh._fres.active and MSh._fres.matched == 2)
local wchips = {}
for _, c in ipairs(SW.agg.chips) do wchips[#wchips + 1] = c.key .. "=" .. c.n end
check("WINDOWS: one chip list across the columns, counts summed",
    table.concat(wchips, " ") == "Electronics=0 Material=11 Tool=0 VehicleMaintenance=0 Weapon=2", table.concat(wchips, " "))
check("SAVED: written to every container the window shows", STORE[CRATE.key] == "metal" and STORE[SHELF.key] == "metal")
check("WINDOWS: the Character window's filter untouched", STORE["player"] == "can\nFood" and S.q == "can")
-- the window turns to another container with nothing saved: the filter empties, the bar stays open
local JUNK = mkInv("obj:12,20,0:bin", { { "Rag", "Material", 1 } })
worldP._colStates = { { inventory = JUNK } }
frame(worldP, true, { model(JUNK) })
check("SAVED: a container with no saved filter: the filter empties, the bar stays open", SW.q == "" and SW.open)
check("SAVED: and that container keeps nothing", STORE[JUNK.key] == nil)
worldP._colStates = { { inventory = SHELF } }
frame(worldP, true, { MSh })
check("SAVED: a container shown again gets its own filter back", SW.q == "metal")
IF.clear(SW)
check("SAVED: Clear takes it off the containers shown", STORE[SHELF.key] == nil and STORE[CRATE.key] == "metal")

section("ONCE (not per frame)")
IF.setQuery(SW, "sheet")
worldP._colStates = { { inventory = CRATE }, { inventory = SHELF } }
frame(worldP, true, { MCr, MSh })
local asked0, agg0, lgen0 = NAMES_ASKED, SW.agg, SW.lgen
for _ = 1, 120 do frame(worldP, true, { MCr, MSh }) end
check("ONCE: 120 frames with nothing changed ask no item its name", NAMES_ASKED == asked0, NAMES_ASKED - asked0)
check("ONCE: the count is the same table (not made again)", SW.agg == agg0)
check("ONCE: the bar is not laid out again", SW.lgen == lgen0, SW.lgen - lgen0)
IF.setQuery(SW, "sheets")
frame(worldP, true, { MCr, MSh })
check("ONCE: a keystroke works the matches out once per column", NAMES_ASKED - asked0 == #CRATE.things + #SHELF.things, NAMES_ASKED - asked0)
local MCr2 = model(CRATE)
asked0 = NAMES_ASKED
frame(worldP, true, { MCr2, MSh })
check("ONCE: a rebuilt model (things moved) is matched again, only that column", NAMES_ASKED - asked0 == #CRATE.things, NAMES_ASKED - asked0)

section("BAR / PAD")
check("BAR: the bar takes room under the heading while open", worldP._fbarH > 0 and SW.y == 37)
local kinds = {}
for _, rc in ipairs(SW.rects) do kinds[#kinds + 1] = rc.key end
check("BAR: field, Clear, a chip per category, then the bar's ground", kinds[1] == "field" and kinds[2] == "clear"
    and kinds[#kinds] == "bg" and #kinds == 3 + #SW.agg.chips, table.concat(kinds, ","))
local below = true
for _, rc in ipairs(SW.rects) do if rc.y < SW.y or rc.y + rc.h > SW.y + SW.barH then below = false end end
check("BAR: every stop inside the bar", below)
check("BAR: Clear drawn, live while something narrows", worldP._buttons[1] and worldP._buttons[1].opts.disabled == false)
local rects = { { x = 300, y = 8, w = 24, h = 24, view = "filter", key = CRATE.key, id = "view:filter:" .. CRATE.key } }
for _, rc in ipairs(SW.rects) do rects[#rects + 1] = rc end
local els = toggleElements(rects)
check("PAD: the Filter button and every bar stop but the ground", #els == #rects - 1)
local byId = {}
for _, e in ipairs(els) do byId[e.id] = e end
local win = { _mainContent = worldP }
check("PAD: ids match the drawn stops' (the focus mark finds them)", byId["view:fbar:field"] and byId["view:fbar:chip:Material"] and byId["view:filter:" .. CRATE.key])
check("PAD: the field's A says Type", byId["view:fbar:field"].promptA == "UI_ZeD_Inv_PromptType")
byId["view:fbar:chip:Weapon"].onActivate(win, byId["view:fbar:chip:Weapon"])
check("PAD: A on a chip picks it", SW.cats.Weapon == true)
check("PAD: X's prompt is Clear while something narrows", byId["view:fbar:clear"].promptX(win) == "UI_ZeD_Inv_FilterClear")
byId["view:fbar:chip:Weapon"].onContextMenu(win)
check("PAD: X clears from any stop", not IF.active(SW) and SW.open)
check("PAD: X's prompt hides once there is nothing to clear", byId["view:fbar:clear"].promptX(win) == false)
byId["view:filter:" .. CRATE.key].onActivate(win, byId["view:filter:" .. CRATE.key])
check("PAD: A on the Filter button shuts the bar", not SW.open)

section("QA FLOOR (Nov 11 2026: 4 found where the script wanted 7)")
do
    -- the floor zedqa_inventory_filter drops, by the game's 42.22 names: only the scrap is named metal, so the filter
    -- (names, as the mockup says) finds 4; the script's fixed 7 was wrong, and it now counts the floor's own names
    local FLOOR = mkInv("floor:13935,5729,0", {
        { "Scrap Metal", "Material", 4 }, { "Steel Sheet", "Material", 2 }, { "Iron Pipe", "Weapon", 1 }, { "Rope", "Material", 1 },
    })
    local fp = mkPanel(nil, { FLOOR })
    local SF = IF.of(fp)
    local MF = model(FLOOR)
    frame(fp, true, { MF })   -- (the window first sees its containers: a filter typed before that would be emptied)
    IF.toggleOpen(SF)
    IF.setQuery(SF, "metal")
    frame(fp, true, { MF })
    check("FLOOR: 'metal' finds the four Scrap Metal, not the Steel Sheet or the Iron Pipe",
        SF.agg.matched == 4 and SF.agg.total == 8, SF.agg.matched .. " of " .. SF.agg.total)
    local qs = readFile("ZeDUI/tools/qa/zedqa_inventory_filter.lua") or ""
    check("FLOOR: the script counts the floor's own names", qs:find("S.agg.matched >= want", 1, true) ~= nil
        and qs:find("S.agg.matched >= 7", 1, true) == nil)
end

section("FLOOR KEY (the floor and a car not yet saved keep no filter)")
do
    -- the real containerKey on the game's floor (vanilla's ItemContainer.new("floor", nil, nil): no parent, no bag,
    -- no vehicle part) and on a part of a car not yet saved (its database id is still -1)
    local ckey = cutChunk("local function containerKey(inv, playerObj)", "ZeD.InventoryRenderer.containerKey = containerKey",
        "return containerKey", "containerKey")
    local floorInv = { getContainingItem = function() return nil end, getType = function() return "floor" end,
                       getParent = function() return nil end }
    check("FLOOR KEY: the real key of the game's floor is the same in every town", ckey(floorInv) == "type:floor", ckey(floorInv))
    local carInv = { getContainingItem = function() return nil end, getVehiclePart = function()
        return { getVehicle = function() return { getSqlId = function() return -1 end } end, getId = function() return "TruckBed" end }
    end }
    check("FLOOR KEY: a car not yet saved has no id in its key yet", ckey(carInv) == "veh:-1:TruckBed", ckey(carInv))
    check("FLOOR KEY: the floor, a car not yet saved and a part with no car have no place of their own",
        IF.placed ~= nil and not IF.placed("type:floor") and not IF.placed("veh:-1:TruckBed") and not IF.placed("veh:?:TruckBed"))
    check("FLOOR KEY: a crate, a saved car's trunk, a bag and the inventory have one",
        IF.placed ~= nil and IF.placed("obj:1,2,0:crate") and IF.placed("veh:12:TruckBed") and IF.placed("item:55") and IF.placed("player"))
    -- the floor in one town: "nails"
    local FLOORI = mkInv("type:floor", { { "Nails", "Material", 10 }, { "Plank", "Material", 2 } })
    local MF = model(FLOORI)
    local fp = mkPanel(FLOORI)
    local SF = IF.of(fp)
    frame(fp, false, { MF })
    IF.toggleOpen(SF)
    IF.setQuery(SF, "nails")
    frame(fp, false, { MF })
    check("FLOOR KEY: the floor narrows while the window shows it", SF.agg and SF.agg.matched == 10, SF.agg and SF.agg.matched)
    check("FLOOR KEY: its filter is not saved", STORE["type:floor"] == nil, STORE["type:floor"])
    -- the window shut, opened again in another town: a new panel, the same floor key
    local fp2 = mkPanel(FLOORI)
    frame(fp2, false, { MF })
    local SF2 = IF.of(fp2)
    check("FLOOR KEY: a new window on the floor opens unfiltered, the bar shut", not SF2.open and not IF.active(SF2), SF2.q)
    -- the floor beside a crate never filtered (side-by-side columns)
    local NEWC = mkInv("obj:40,40,0:crate", { { "Nails", "Material", 3 }, { "Rope", "Material", 1 } })
    local MN = model(NEWC)
    local cp = mkPanel(nil, { NEWC, FLOORI })
    frame(cp, true, { MN, MF })
    check("FLOOR KEY: a crate shown beside the floor is not given a filter", STORE[NEWC.key] == nil and not IF.active(IF.of(cp)),
        STORE[NEWC.key])
    -- and a crate's filter beside the floor stays the crate's
    local SC = IF.of(cp)
    IF.toggleOpen(SC)
    IF.setQuery(SC, "rope")
    frame(cp, true, { MN, MF })
    check("FLOOR KEY: a filter typed beside the floor is kept on the crate alone", STORE[NEWC.key] == "rope" and STORE["type:floor"] == nil,
        tostring(STORE[NEWC.key]) .. " / " .. tostring(STORE["type:floor"]))
    -- a save from before this kept the floor's filter (and an unsaved car's)
    STORE["type:floor"], STORE["veh:-1:TruckBed"] = "nails", "gas"
    local fp3 = mkPanel(FLOORI)
    frame(fp3, false, { MF })
    check("FLOOR KEY: a floor filter an old save kept is not applied", not IF.active(IF.of(fp3)) and not IF.of(fp3).open)
    check("FLOOR KEY: it is let go from the save, with the unsaved car's", STORE["type:floor"] == nil and STORE["veh:-1:TruckBed"] == nil)
    check("FLOOR KEY: the crates' own filters stay", STORE[NEWC.key] == "rope" and STORE["player"] ~= nil)
end

section("TIMED (each column's model built again about once a second)")
do
    -- the World window's two columns, the bar open on "sheet", the real itemModel on a clock moving 16 ms a frame
    worldP._colStates = { { inventory = CRATE }, { inventory = SHELF } }
    if not SW.open then IF.toggleOpen(SW) end
    IF.setQuery(SW, "sheet")
    local function timedFrame()
        NOW = NOW + 16
        local a = itemModel(worldP, CRATE, nil, false, "cat", true, {}, {})
        local b = itemModel(worldP, SHELF, nil, false, "cat", true, {}, {})
        frame(worldP, true, { a, b })
        return a
    end
    for _ = 1, 3 do timedFrame() end
    local agg0, lgen0, matched0 = SW.agg, SW.lgen, SW.agg.matched
    local builds, last = 0, nil
    for _ = 1, 600 do
        local a = timedFrame()
        if a ~= last then builds, last = builds + 1, a end
    end
    check("TIMED: ten seconds: the models were built again (the timer ran)", builds >= 8, builds)
    check("TIMED: the count stays the same table", SW.agg == agg0)
    check("TIMED: the bar is not laid out again, so no pad stop is rebuilt", SW.lgen == lgen0, SW.lgen - lgen0)
    -- a new thing in the crate: a new count, its chip's number one up, no stop moved
    local extra = mkInv("tmp", { { "Sheet Metal", "Material", 1 } }).things[1]
    CRATE.things[#CRATE.things + 1] = extra
    timedFrame()
    check("TIMED: a new thing in the crate: the count follows", SW.agg.matched == matched0 + 1 and SW.agg ~= agg0, SW.agg.matched)
    check("TIMED: no stop moved: the pad stops are not rebuilt", SW.lgen == lgen0, SW.lgen - lgen0)
    local own = {}
    for _, c in ipairs(SW.agg.chips) do own[c] = true end
    local drawn = true
    for _, rc in ipairs(SW.rects) do if rc.chip and not own[rc.chip] then drawn = false end end
    check("TIMED: the chips drawn are the new count's", drawn)
    CRATE.things[#CRATE.things] = nil
    timedFrame()
    -- a narrower window moves the stops: the pad stops are rebuilt
    local lgen1 = SW.lgen
    worldP.getWidth = function() return 300 end
    timedFrame()
    check("TIMED: a narrower window moves the stops: rebuilt once", SW.lgen == lgen1 + 1, SW.lgen - lgen1)
    timedFrame()
    check("TIMED: and once only", SW.lgen == lgen1 + 1, SW.lgen - lgen1)
    worldP.getWidth = function() return 420 end
    timedFrame()
end

section("COLUMNS (the pad on the Filter's stops in a Loot column)")
do
    -- the real FocusManager zone code, and both windows' real Loot column refresh
    local FM = readFile("42/media/lua/client/ZeD/Input/FocusManager.lua")
    local fa = FM:find("local function _resolveZoneIdx(w, zoneRef)", 1, true)
    local fb = fa and FM:find("--- Toggle focusable flag on a zone", fa, true)
    check("cut FocusManager's zone code", fa ~= nil and fb ~= nil)
    -- (stand-ins for FocusManager's state the cut reads: player 1's record and the lookups liveZone uses)
    local Focus = assert(loadstring("local Focus = {}\nlocal _st0 = { cues = false }\nlocal _st = { [0] = _st0 }\n"
        .. "local function _S() return _st0 end\nlocal function _pnOf() return 0 end\n" .. FM:sub(fa, fb - 1)
        .. "\nreturn Focus", "focus"))()
    Focus.setZoneFocusable = function() end
    local CWS = readFile("42/media/lua/client/ZeD/ZeD_CharacterWindow.lua")
    local WWS = readFile("42/media/lua/client/ZeD/ZeD_WorldWindow.lua")
    local function cutText(src, from, to)
        local x = src:find(from, 1, true)
        local y = x and src:find(to, x, true)
        return (x and y) and src:sub(x, y - 1) or nil
    end
    local cwChunk = cutText(CWS, "local function _charMCColumnDirty(win, slot, cs)", "-- Item card action strip focusables")
    local wwDirty = cutText(WWS, "local function _worldMCColumnDirty(win, slot, cs)", "-- Dynamic per-column MC ring zone restructuring.")
    local wwLoop = cutText(WWS, '        if Focus and win._focusRing and win._activeTab == "loot" then',
        "        -- the tab's stops (content._tabStopsRefresh, above). Rebuilt every")
    check("cut both windows' Loot column refresh", cwChunk ~= nil and wwDirty ~= nil and wwLoop ~= nil)
    -- a column's stops as the windows build them: a row per thing, then the heading's (the renderer's rects)
    local function build(win, slot)
        local cs = win._mainContent._colStates[slot]
        local els = {}
        for i, it in ipairs(cs.flatItems) do els[#els + 1] = { id = "row:" .. i, item = it, x = 0, y = 80 + i * 26, w = 200, h = 26 } end
        for _, e in ipairs(toggleElements(cs.viewToggleRects)) do els[#els + 1] = e end
        return els
    end
    local refreshChar = assert(loadstring("local _buildCharacterMCColumnFocusables = ...\n" .. (cwChunk or "")
        .. "\nreturn _refreshCharMCZones", "charMC"))(build)
    local refreshWorld = assert(loadstring("local _buildWorldMCColumnFocusables = ...\n" .. (wwDirty or "")
        .. "\nreturn function(win, self, Focus)\n" .. (wwLoop or "") .. "\nend", "worldMC"))(build)
    local sides = {
        { zone = "charMC1", run = function(w) refreshChar(w, Focus) end },
        { zone = "worldMC1", run = function(w) refreshWorld(w, w._mainContent, Focus) end },
    }
    for _, side in ipairs(sides) do
        local zn = side.zone
        STORE[CRATE.key], STORE[SHELF.key] = nil, nil   -- (the window opens with the bar shut)
        local panel = mkPanel(nil, { CRATE, SHELF })
        local S = IF.of(panel)
        local MA, MB = model(CRATE), model(SHELF)
        local cs = panel._colStates[1]
        cs.flatItems, cs.scroll, cs.itemRenderYMap, cs.renderX, cs.renderW, cs.containerIdx = MA.flatItems, { scrollPos = 0 }, {}, 0, 200, 2
        -- the column's heading: the Filter button, and the bar's stops while it is open (drawViewToggle's GV.toggles)
        local function heading()
            frame(panel, true, { MA, MB })
            local t = { { x = 150, y = 8, w = 24, h = 24, view = "filter", key = CRATE.key, id = "view:filter:" .. CRATE.key } }
            if S.open then for _, rc in ipairs(S.rects) do t[#t + 1] = rc end end
            cs.viewToggleRects = t
        end
        heading()
        local win = { _activeTab = "loot", _mcSelected = { 2 }, _mainContent = panel,
                      _focusRing = { { zone = zn, elements = {}, focusedElementIdx = 1, focusable = true } } }
        side.run(win)
        local z = win._focusRing[1]
        local function focusOn(id)
            for i, e in ipairs(z.elements) do if e.id == id then z.focusedElementIdx = i; return true end end
            return false
        end
        local function focusedId() local e = z.elements[z.focusedElementIdx or 1]; return e and e.id end
        win._gpFocusedMCItem = cs.flatItems[#cs.flatItems]   -- (the last row the pad was on, before Up took it to the heading)
        check(zn .. ": the Filter button is a stop in the column", focusOn("view:filter:" .. CRATE.key))
        local fbEl = z.elements[z.focusedElementIdx]
        fbEl.onActivate(win, fbEl)   -- (A: the bar opens, its stops join the column's)
        heading()
        side.run(win)
        check(zn .. ": A on the Filter button: the pad stays on it", focusedId() == "view:filter:" .. CRATE.key, focusedId())
        check(zn .. ": Clear is a stop in the column", focusOn("view:fbar:clear"))
        IF.setQuery(S, "metal")
        heading()
        S.lgen = S.lgen + 1   -- (the bar laid out again: a chip's number grew a digit, a stop moved)
        heading()
        side.run(win)
        check(zn .. ": the bar laid out again: the pad stays on Clear", focusedId() == "view:fbar:clear", focusedId())
        check(zn .. ": a chip is a stop in the column", focusOn("view:fbar:chip:Material"))
        local chipEl = z.elements[z.focusedElementIdx]
        chipEl.onActivate(win, chipEl)
        S.lgen = S.lgen + 1
        heading()
        side.run(win)
        check(zn .. ": A on a chip picks it, and the pad stays on the chip", S.cats.Material == true and focusedId() == "view:fbar:chip:Material",
            focusedId())
        focusOn("row:2")
        win._gpFocusedMCItem = cs.flatItems[2]
        S.lgen = S.lgen + 1
        heading()
        side.run(win)
        check(zn .. ": a row keeps its row", focusedId() == "row:2", focusedId())
        IF.clear(S)
    end
end

section("EDGE (Clear's right end, beside the scrollbar)")
do
    local MOL = readFile("42/media/lua/client/ZeD/Molecules.lua")
    local ma = MOL:find("ZeD_ScrollbarState = {}", 1, true)
    local mb = ma and MOL:find("ZeD.Molecules.ScrollbarState = ZeD_ScrollbarState", ma, true)
    check("cut the scrollbar", ma ~= nil and mb ~= nil)
    local SB = assert(loadstring(MOL:sub(ma, mb - 1) .. "\nreturn ZeD_ScrollbarState", "scrollbar"))()
    local CWS = readFile("42/media/lua/client/ZeD/ZeD_CharacterWindow.lua")
    local WWS = readFile("42/media/lua/client/ZeD/ZeD_WorldWindow.lua")
    -- each window's press on its list, from the scrollbar test to the zones: false when it goes on to the zones
    local function pressCode(src, from, name)
        local x = src:find(from, 1, true)
        local y = x and src:find("        local zone = self:hitZoneAt(x, y)", x, true)
        check("cut " .. name, x ~= nil and y ~= nil)
        return assert(loadstring("return function(self, x, y, win, w, scrollW)\n" .. src:sub(x or 1, (y or 2) - 1)
            .. "\nreturn false\nend", name))()
    end
    local pressChar = pressCode(CWS, "        -- Multi-container: column-aware scroll check", "the Character window's press")
    local pressWorld = pressCode(WWS, "        -- MC column-aware scrollbar check", "the World window's press")
    -- the Character window's one list (420 wide), the bar open, the list longer than its view
    local p = mkPanel(CHAR)
    local S = IF.of(p)
    frame(p, false, { model(CHAR) })
    if not S.open then IF.toggleOpen(S) end
    frame(p, false, { model(CHAR) })
    local clear = S.rects[2]
    local sb = SB:new()
    sb.x, sb.y, sb.width, sb.height, sb.arrowH = 420 - 14, 37 + S.barH + 20, 14, 300, 14
    sb.visible = true
    sb:setBarSize(0.4)
    p._scroll = sb
    local px, py = clear.x + clear.w - 2, clear.y + 4
    check("EDGE: Clear's right end is in the scrollbar's strip (the case)", clear.key == "clear" and px >= sb.x, px)
    local win = { _mcSelected = {} }
    local function fresh() sb.scrollPos, sb.upPressed, sb.downPressed, sb.dragging = 0.5, false, false, false end
    fresh()
    local took = pressChar(p, px, py, win, 420, 14)
    check("EDGE (Character): a press on Clear's right end goes on to Clear", took == false and sb.scrollPos == 0.5,
        tostring(took) .. " " .. sb.scrollPos)
    fresh()
    sb.visible = false
    took = pressChar(p, 415, 200, win, 420, 14)
    check("EDGE (Character): a list that fits has no scrollbar to take the strip", took == false, took)
    sb.visible = true
    fresh()
    took = pressChar(p, sb.x + 7, sb.y + 5, win, 420, 14)
    check("EDGE (Character): the scrollbar reads a press on its own y (its up arrow: a line up)",
        took == true and sb.upPressed and sb.scrollPos < 0.5, tostring(took) .. " " .. sb.scrollPos)
    fresh()
    took = pressWorld(p, px, py, win)
    check("EDGE (World): a press on Clear's right end goes on to Clear (with the scrollbar showing)",
        took == false and sb.scrollPos == 0.5, tostring(took) .. " " .. sb.scrollPos)
    fresh()
    took = pressWorld(p, sb.x + 7, sb.y + 5, win)
    check("EDGE (World): the scrollbar's up arrow still a line up", took == true and sb.upPressed and sb.scrollPos < 0.5, sb.scrollPos)
    -- side-by-side columns: a press under a column's scrollbar (the container buttons' row) is not the scrollbar's
    local csb = SB:new()
    csb.x, csb.y, csb.width, csb.height, csb.arrowH = 186, 80, 14, 200, 14
    csb.visible = true
    csb:setBarSize(0.4)
    csb.scrollPos = 0.5
    local mp = { _colStates = { { scroll = csb } }, _scroll = sb }
    local mwin = { _mcSelected = { 2 } }
    check("EDGE (columns): a press under a column's scrollbar is not the scrollbar's",
        pressChar(mp, 190, 300, mwin, 420, 14) == false and pressWorld(mp, 190, 300, mwin) == false and csb.scrollPos == 0.5, csb.scrollPos)
    check("EDGE: both windows hand the scrollbar a move on its own y, as they hand it a press",
        CWS:find("self._scroll:handleMouseMove(my - self._scroll.y)", 1, true) ~= nil
        and WWS:find("self._scroll:handleMouseMove(self:getMouseY() - self._scroll.y)", 1, true) ~= nil)
end

section("WIRED")
local CW = readFile("42/media/lua/client/ZeD/ZeD_CharacterWindow.lua")
local WW = readFile("42/media/lua/client/ZeD/ZeD_WorldWindow.lua")
check("WIRED: both windows hand the press's panel to onViewZone", CW:find("onViewZone(zid, self)", 1, true) ~= nil and WW:find("onViewZone(zid, self)", 1, true) ~= nil)
check("WIRED: both windows rebuild pad stops when the Filter's move", select(2, CW:gsub("filterGen", "")) >= 2 and select(2, WW:gsub("filterGen", "")) >= 2)
check("WIRED: the Filter button is the ZeD pixel funnel", IR:find('M.drawIconButton(self, tx, ty, bw, "filter", o)', 1, true) ~= nil)
check("WIRED: the heading makes room for the bar", IR:find("+ (self._fbarH or 0)   -- (and the Filter bar)", 1, true) ~= nil)
check("WIRED: the side-by-side columns start and end the Filter's frame", IR:find("filterFrame(self, true)", 1, true) ~= nil and IR:find("    filterEnd(self)\n    self._fres = nil", 1, true) ~= nil)

print(string.format("inventory_filter_sim: %d checks, %d failed", checks, failed))
os.exit(failed > 0 and 1 or 0)
