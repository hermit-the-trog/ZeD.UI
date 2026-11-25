-- ZeDUI/tools/qa/loot_calls_card_sim.lua  (Nov 24 2026, Build; the loot KISS design calls, ZeDUI/qa/audits/
-- 2026-11-24_kiss_loot.md, the director's picks)
--   CARD     call 4: ItemCardOrganism's compactVerbs (cut from the real file): on a narrow card Grab always stays; where
--            Grab, the main verb and More don't fit, the main verb goes into More (Grab, More); where they fit, all
--            three; a thing of his own (no Grab) keeps its main verb and More
--   HIDE     call 7: InventoryFilter.lua's IF.view (the real file) over InventoryRenderer's real list model
--            (buildItemModel, cut): a row that doesn't match leaves the list, a category with nothing matching goes,
--            a heading's count is its matches, an open stack's header stays above its first kept row, a folded
--            category with a match stays, the flat list (another sort) drops the same rows; nothing narrowing: the
--            model itself; the counts ("3 of 12", the chips) still count everything
--   COLUMN   the real filterColumn (cut) hands back the view, and renderItemList draws from it (source): the rows the
--            pad walks (_invRowItems), the category stops and the open-stack stops are the view's, so no stop on a
--            hidden row; a list with things that the Filter emptied says "Nothing matches", an empty one "Nothing here."
-- Run from the repo root:  lua51 ZeDUI/tools/qa/loot_calls_card_sim.lua
-- It prints FAIL lines and a last line "loot_calls_card_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]loot_calls_card_sim%.lua$", "")
local Z = ROOT .. "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function readFile(p)
    local f = io.open(p, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return (s:gsub("\r\n", "\n"))
end
local function cut(src, from, to)
    local a = src and string.find(src, from, 1, true)
    if not a then return nil end
    local b = string.find(src, to, a, true)
    if not b then return nil end
    return string.sub(src, a, b + #to - 1) .. "\n"
end
local function has(src, s) return src ~= nil and string.find(src, s, 1, true) ~= nil end

local ORG = readFile(Z .. "ItemCardOrganism.lua") or ""
local IR = readFile(Z .. "InventoryRenderer.lua") or ""
local IFsrc = readFile(Z .. "InventoryFilter.lua") or ""
local EN = readFile(ROOT .. "42/media/lua/shared/Translate/EN/UI.json") or ""
check("SOURCE: files read", #ORG > 0 and #IR > 0 and #IFsrc > 0 and #EN > 0)

-- ---------------------------------------------------------------------------
-- STUBS (as inventory_filter_sim's)
-- ---------------------------------------------------------------------------
getTimestampMs = function() return 1762500000000 end
Events = { OnContainerUpdate = { Add = function() end }, OnClothingUpdated = { Add = function() end } }
instanceof = function() return false end
ZeD = {}
ZeD._trGen = 1
ZeD.T = { px = function(n) return n end, buttonH = 24, fontF3 = "F3" }
-- (7 units a letter)
ZeD.TM = { MeasureStringX = function(_, f, s) return #tostring(s) * 7 end, getFontHeight = function() return 14 end }
ZeD.tr = function(key, ...)
    local out = key
    for _, v in ipairs({ ... }) do out = out .. "|" .. tostring(v) end
    return out
end
ZeD.btnCase = function(s) return s end
ZeD.ItemMeter = { sortKey = function() return 1 end }
ZeD.ContainerGates = { get = function() return nil end, keeps = function() return true end }
ZeD.ContainerGroups = { groupOf = function() return nil end, keys = function() return {} end,
                        sortKeys = function(k) table.sort(k) end, sig = function() return false end }
ZeD.InventoryRenderer = {
    catKey = function(item) return item:getDisplayCategory() end,
    catLabel = function(key) return tostring(key) end,
    WORN_KEY = "zz:worn",
}
stackWeight = function(s) return #s.items * 0.5 end

-- ---------------------------------------------------------------------------
print("-- CARD: call 4, Grab stays on a narrow card")
local cv = cut(ORG, "local function compactVerbs(verbs, w)", "\nend")
check("CARD: compactVerbs found", cv ~= nil)
local compactVerbs
if cv then
    local fn, e = loadstring(cv .. "return compactVerbs\n", "compactVerbs")
    check("CARD: compactVerbs compiles", fn ~= nil, e)
    if fn then compactVerbs = fn() end
end
if compactVerbs then
    local function V(...)
        local out = {}
        for _, t in ipairs({ ... }) do out[#out + 1] = t end
        return out
    end
    local function ids(list)
        local o = {}
        for i, v in ipairs(list) do o[i] = v.id end
        return table.concat(o, ",")
    end
    local grab = { id = "TAKE", label = "Grab" }
    local eat = { id = "EAT", label = "Eat", primary = true }
    local more = { id = "MORE", label = "More", isMore = true }
    -- Grab 4 letters, Eat 3, More 4: (4+3+4)*7 + 3 * (8*2 + 4) = 77 + 60 = 137 needed; room = w - 8 - 20 - 4 = w - 32
    check("CARD: wide enough: Grab, Eat, More", ids(compactVerbs(V(grab, eat, more), 220)) == "TAKE,EAT,MORE",
        ids(compactVerbs(V(grab, eat, more), 220)))
    local narrow = compactVerbs(V(grab, eat, more), 120)
    check("CARD: too narrow for three: Grab stays, Eat goes into More (Grab, More)", ids(narrow) == "TAKE,MORE", ids(narrow))
    check("CARD: ... the same Grab and More (their actions run as before)", narrow[1] == grab and narrow[2] == more)
    -- a long main verb (the game's word for a smoke or a pill) on a 220 card: the old card dropped Grab here
    local pills = { id = "USE", label = "Take Pills Now Please", primary = true }
    check("CARD: a long main verb goes into More, Grab stays", ids(compactVerbs(V(grab, pills, more), 220)) == "TAKE,MORE",
        ids(compactVerbs(V(grab, pills, more), 220)))
    local gp = { id = "TAKE", label = "Grab", primary = true }
    check("CARD: a thing with no verb of its own: Grab, More", ids(compactVerbs(V(gp, more), 80)) == "TAKE,MORE",
        ids(compactVerbs(V(gp, more), 80)))
    local drop = { id = "DROP", label = "Drop" }
    check("CARD: his own thing (no Grab) keeps its main verb and More", ids(compactVerbs(V(eat, drop, more), 120)) == "EAT,MORE",
        ids(compactVerbs(V(eat, drop, more), 120)))
end
check("CARD: the header comment says Grab stays (call 4)", has(ORG, "Grab stays and the main verb goes into More instead"))
check("CARD: More's menu is the item's whole context menu (the main verb is there)",
    has(readFile(Z .. "ItemCard.lua") or "", "CM.createMenu(playerNum, mine, self:_markedWith(item) or items, x, y)"))

-- ---------------------------------------------------------------------------
print("-- HIDE: call 7, the Filter hides what doesn't match")
local IFfn, IFe = loadstring(IFsrc, "@InventoryFilter.lua")
check("HIDE: InventoryFilter.lua loads", IFfn ~= nil, IFe)
if IFfn then IFfn() end
local IF = ZeD.InvFilter
check("HIDE: IF.view exists", IF and type(IF.view) == "function")

local chunk = cut(IR, "local MODEL_REFRESH_MS", "-- ROW PARTS")
check("HIDE: the list model found", chunk ~= nil)
local buildItemModel
if chunk then
    local fn, e = loadstring(chunk .. "\nreturn buildItemModel\n", "model")
    check("HIDE: the list model compiles", fn ~= nil, e)
    if fn then buildItemModel = fn() end
end

local function list(t) return { size = function() return #t end, get = function(_, i) return t[i + 1] end } end
local function mkInv(rows)
    local inv = { things = {} }
    function inv:getItems() return list(self.things) end
    function inv:getCapacityWeight() return #self.things end
    for _, r in ipairs(rows) do
        for _ = 1, r[3] do
            local nm, cat, ft = r[1], r[2], r[4] or ("Base." .. r[1]:gsub("%W", ""))
            local it = { nm = nm, cat = cat }
            function it:getName() return nm end
            function it:getDisplayCategory() return cat end
            function it:getCategory() return cat end
            function it:getFullType() return ft end
            function it:isHidden() return false end
            function it:getContainer() return inv end
            function it:getUnequippedWeight() return 0.5 end
            inv.things[#inv.things + 1] = it
        end
    end
    return inv
end
-- a crate: Scrap Metal x3, Sheet Metal x2, Rope, Metal Pipe, Wrench, Apple x4; one Hammer renamed "Metal Hammer"
-- in a stack of two Hammers (a stack kept by a renamed thing in it)
local CRATE = mkInv({
    { "Scrap Metal", "Material", 3 }, { "Sheet Metal", "Material", 2 }, { "Rope", "Material", 1 },
    { "Metal Pipe", "Weapon", 1 }, { "Wrench", "Tool", 1 }, { "Apple", "Food", 4 },
    { "Hammer", "Tool", 1, "Base.Hammer" }, { "Metal Hammer", "Tool", 1, "Base.Hammer" },
})

local function names(rows)
    local o = {}
    for i, it in ipairs(rows) do o[i] = it.nm end
    return table.concat(o, ",")
end

if buildItemModel and IF and IF.view then
    local S = IF.of({})
    S.store = {}
    S.open = true
    local M = buildItemModel(CRATE, nil, false, "cat", true, {}, { ["Base.ScrapMetal"] = true })
    local res = IF.result(S, M)
    check("HIDE: nothing narrowing: the model itself", IF.view(M, res) == M)
    IF.setQuery(S, "metal")
    res = IF.result(S, M)
    local V = IF.view(M, res)
    check("HIDE: narrowing: a view, the built model untouched", V ~= M and #M.flatItems >= #V.flatItems)
    check("HIDE: the counts still count everything (7 of 14)", res.matched == 7 and res.total == 14,
        res.matched .. " of " .. res.total)
    check("HIDE: Food (nothing matches) leaves the list", table.concat(V.catOrder, ",") == "Material,Tool,Weapon",
        table.concat(V.catOrder, ","))
    check("HIDE: Material's rows: the open Scrap Metal's three, Sheet Metal; no Rope",
        names(V.stackedGroups.Material) == "Scrap Metal,Scrap Metal,Scrap Metal,Sheet Metal", names(V.stackedGroups.Material))
    check("HIDE: Material's heading counts its matches (5, not 6)", #V.groups.Material == 5, #V.groups.Material)
    check("HIDE: the open stack's header stays, above its first row", #V.heads == 1 and V.headOf[V.stackedGroups.Material[1]] == V.heads[1])
    check("HIDE: Material's row count has the header (4 rows + 1)", V.catRowCount.Material == 5, V.catRowCount.Material)
    check("HIDE: Tool keeps the Hammer stack (its renamed Metal Hammer matches), no Wrench",
        #V.stackedGroups.Tool == 1 and V.stacks[V.stackedGroups.Tool[1]] ~= nil and V.stacks[V.stackedGroups.Tool[1]].count == 2,
        names(V.stackedGroups.Tool))
    check("HIDE: the flat rows are the categories' rows in order (the pad walks these)",
        names(V.flatItems) == names(V.stackedGroups.Material) .. "," .. names(V.stackedGroups.Tool) .. "," .. names(V.stackedGroups.Weapon),
        names(V.flatItems))
    local hidden = false
    for _, it in ipairs(V.flatItems) do
        local s = V.stacks[it]
        local any = res.match[it]
        if s then for _, si in ipairs(s.items) do any = any or res.match[si] end end
        if not any then hidden = true end
    end
    check("HIDE: no row left that nothing in it matches", not hidden)
    check("HIDE: kept until the filter changes", IF.view(M, res) == V)
    IF.setQuery(S, "apple")
    local V2 = IF.view(M, IF.result(S, M))
    check("HIDE: a new filter, a new view (Apple only)", V2 ~= V and names(V2.flatItems) == "Apple" and #V2.groups.Food == 4,
        names(V2.flatItems))
    -- a folded category with a match stays (its heading, no rows); one with none goes
    IF.setQuery(S, "metal")
    local MF = buildItemModel(CRATE, nil, false, "cat", true, { Material = true }, {})
    local VF = IF.view(MF, IF.result(S, MF))
    check("HIDE: a folded Material with matches stays, no rows", VF.catOrder[1] == "Material" and #VF.stackedGroups.Material == 0
        and VF.catRowCount.Material == 0, table.concat(VF.catOrder, ","))
    -- another sort: one flat list, no headings
    local MW = buildItemModel(CRATE, nil, false, "wt", true, {}, {})
    local VW = IF.view(MW, IF.result(S, MW))
    local okFlat = #VW.flatItems > 0
    for _, it in ipairs(VW.flatItems) do
        if it.nm == "Rope" or it.nm == "Apple" or it.nm == "Wrench" then okFlat = false end
    end
    check("HIDE: the flat list (by weight) drops the same rows", okFlat and #VW.flatItems == 4, names(VW.flatItems))
    check("HIDE: ... and its categories too (the empty line reads them)", #VW.catOrder == 3, #VW.catOrder)
    IF.setQuery(S, "chainsaw")
    local VN = IF.view(M, IF.result(S, M))
    check("HIDE: nothing matches: no rows, no categories", #VN.flatItems == 0 and #VN.catOrder == 0)

    -- the real filterColumn (cut): it hands the view back
    print("-- COLUMN: the list draws the view")
    local fc = cut(IR, "local function filterColumn(self, M)", "\nend")
    check("COLUMN: filterColumn found", fc ~= nil)
    if fc then
        local fn, e = loadstring("local IFL = ZeD.InvFilter\n" .. fc .. "return filterColumn\n", "filterColumn")
        check("COLUMN: filterColumn compiles", fn ~= nil, e)
        if fn then
            local filterColumn = fn()
            IF.setQuery(S, "metal")
            local p = { _zedFilter = S }
            S.shown, S.nFrame, S.frame = true, 0, {}
            local got = filterColumn(p, M)
            check("COLUMN: narrowing: the view comes back", got ~= M and got == IF.view(M, IF.result(S, M)))
            check("COLUMN: ... the row marks still know the matches", p._fres ~= nil and p._fres.active)
            S.open = false
            check("COLUMN: a shut bar: the model itself, no marks", filterColumn(p, M) == M and p._fres == nil)
            S.open = true
        end
    end
end

-- source: renderItemList draws from the view, and every list's stops read it
local rl = cut(IR, "    M = filterColumn(self, M)", "self._headOf         = M.headOf")
check("COLUMN: renderItemList takes the view before it reads the model", rl ~= nil
    and has(rl, "local groups, catOrder, flatItems = M.groups, M.catOrder, M.flatItems")
    and has(rl, "self._invRowItems    = flatItems") and has(rl, "self._openHeads      = M.heads"))
check("COLUMN: the grid's add-on layout gets the view too",
    has(IR, "ZeD.GridLayout.attach(self, self._gv, M, inv, playerObj, useGroups, catHdrH"))
check("COLUMN: the Loot columns save the view's rows for the pad (cs.flatItems, catGroups, openHeads)",
    has(IR, "cs.flatItems       = self._flatItems") and has(IR, "cs.catGroups       = self._stackedGroups")
    and has(IR, "cs.openHeads       = self._openHeads"))
check("COLUMN: the heading's count stays the whole container (shownCount reads the cached model, not the view)",
    has(IR, "if c and c.m and c.m.nShown then return c.m.nShown end"))
check("COLUMN: a list the Filter emptied says Nothing matches; an empty one Nothing here.",
    has(IR, "(self._fres and self._fres.total > 0 and ZeD.tr(\"UI_ZeD_Inv_FilterNone\"))")
    and has(EN, "\"UI_ZeD_Inv_FilterNone\": \"Nothing matches\"") and has(EN, "\"UI_ZeD_Inv_Empty\": \"Nothing here.\""))
check("COLUMN: the help says hides, not dims", has(EN, "\"UI_ZeD_Inv_FilterHelp\": \"Filter: hides what does not match")
    and not has(EN, "Filter: dims what"))

print(string.format("loot_calls_card_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
