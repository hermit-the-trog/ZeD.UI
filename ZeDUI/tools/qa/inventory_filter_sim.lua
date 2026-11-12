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
ZeD._trGen = 1
ZeD.T = {
    px = function(n) return n end, scale = 1, inputH = 22, buttonH = 24, hair = 1,
    sp = { sm = 10, buttonPadX = 12 },
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
