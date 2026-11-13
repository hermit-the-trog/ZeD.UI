-- ZeDUI/tools/qa/footer_picked_sim.lua  (Nov 11 2026, Build): the weight leaves the window footer (the director:
-- weight showed three times with keyboard and mouse). The help line's resting words for an inventory side become
-- "48 items", or "3 of 48 picked | 4.2 kg" while rows are picked. Checked on the real pieces of the changed files
-- with no game running.
--   MODULE   InventoryPicked.lua: nothing picked says "N items" with no weight; picks say "k of N picked | w kg";
--            a closed stack row counts its every thing, an open one its own row, a grid stack the whole stack;
--            one picked thing says "1 of N"; the weight is summed then shown with one decimal, as the rows show it
--   COLUMNS  several columns: every column's picks against every shown column's things; a table two places share
--            (the panel's own and the last column's) counts once
--   CHAR     the Character window's own lines (cut out of ZeD_CharacterWindow.lua, single list and columns)
--   WORLD    the World window's own lines (cut out of ZeD_WorldWindow.lua: single, the floor, one column left,
--            columns)
--   PAD      the controller's marks (InventoryRenderer padMark, cut out and run) feed the same count, a stack header
--            marking its whole stack
--   HELP     ZeD_Surface's H.take: an element's hover help still wins; the resting line only with nothing under it
--   PERF     at 60 and 240 FPS over ten seconds, the picks are looked at every 100 ms and weighed only when they
--            change, plus once a second; a new pick of the same size shows within 100 ms
--   KEPT     the title bar's weight (the character's load over their max) and the container headings' weights stay
--            where they were; since the weights were made one format (Nov 12 2026) they all write it through
--            ZeD.Atoms.loadText, "7.0 / 19 kg"
-- What it can't show: the line drawn in the game (zedqa_footer_picked.lua does that).
-- Run from the repo root:  lua51 ZeDUI/tools/qa/footer_picked_sim.lua
-- It prints FAIL lines and a last line "footer_picked_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]footer_picked_sim%.lua$", "")

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end

local function readFile(rel)
    local f = io.open(ROOT .. rel, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return (string.gsub(s, "\r\n", "\n"))
end
local function srcOf(rel) return readFile("42/media/lua/client/ZeD/" .. rel) or "" end
-- the text from the first `from` (plain, searched from init) to the end of the line where the first `to` after it is
local function cut(src, from, to, init)
    local a = string.find(src, from, init or 1, true)
    if not a then return nil end
    local b = string.find(src, to, a + #from, true)
    if not b then return nil end
    local e = string.find(src, "\n", b + #to, true) or #src
    return string.sub(src, a, e)
end

-- ---------------------------------------------------------------------------
-- stubs: the English strings, a clock, containers, items
-- ---------------------------------------------------------------------------
local EN = {}
for k, v in string.gmatch(readFile("42/media/lua/shared/Translate/EN/UI.json") or "", '"(UI_ZeD_[%w_]+)": "([^"\n]*)"') do EN[k] = v end

local CLOCK = 0
function getTimestampMs() return CLOCK end

local WEIGHED = 0
local function item(name, w)
    return { name = name, getUnequippedWeight = function() WEIGHED = WEIGHED + 1; return w end }
end
local function inv(n) return { n = n } end

local GRID = {}   -- container -> shown as a grid
ZeD = {
    tr = function(key, ...)
        local s = EN[key]
        if not s then return key end
        local args = { ... }
        return (string.gsub(s, "%%(%d)", function(d) return tostring(args[tonumber(d)]) end))
    end,
    ContainerGates = {
        count = function(i) return i and i.n or 0 end,
        status = function() return nil end,
    },
    InventoryRenderer = {
        containerKey = function(i) return i end,
        isGridKey = function(k) return GRID[k] == true end,
    },
    Atoms = {},
}
-- the one way a load over a capacity is written (the headings and the title bar): the real Atoms.loadText; and the
-- count the headings and this line give, what the rows show (the real InventoryRenderer.shownCount: with no list
-- drawn here, the container's own count)
do
    local at = readFile("42/media/lua/client/ZeD/Atoms.lua") or ""
    local a1 = at:find("function ZeD.Atoms.loadText(load, cap)", 1, true)
    local b1 = a1 and at:find("\nend\n", a1, true)
    check("Atoms.lua has loadText", a1 ~= nil and b1 ~= nil)
    if a1 and b1 then assert(loadstring(at:sub(a1, b1 + 4), "=loadText"))() end
    local ir = readFile("42/media/lua/client/ZeD/InventoryRenderer.lua") or ""
    local a2 = ir:find("function ZeD.InventoryRenderer.shownCount(panel, inv, playerObj)", 1, true)
    local b2 = a2 and ir:find("\nend\n", a2, true)
    check("InventoryRenderer.lua has shownCount", a2 ~= nil and b2 ~= nil)
    if a2 and b2 then assert(loadstring(ir:sub(a2, b2 + 4), "=shownCount"))() end
end

-- (Nov 12 2026) the headings ask the game's capacity for the character (InventoryRenderer.capacityOf, cut out and run:
-- the character's own inventory its carry limit, any other container getEffectiveCapacity)
do
    local f = io.open(ROOT .. "42/media/lua/client/ZeD/InventoryRenderer.lua", "rb")
    local s = f and (f:read("*a"):gsub("\r\n", "\n")) or ""
    if f then f:close() end
    local a = s:find("function ZeD.InventoryRenderer.capacityOf(", 1, true)
    local e = a and s:find("\nend\n", a, true)
    if a and e then assert(loadstring(s:sub(a, e + 4)))() end
end

local okM, eM = pcall(dofile, ROOT .. "42/media/lua/client/ZeD/InventoryPicked.lua")
check("InventoryPicked.lua loads", okM, eM)
local P = ZeD.InventoryPicked

-- a panel's line now, the clock moved past the look's period first (a fresh look every call)
local function lineNow(holder, cols, total, one, many)
    CLOCK = CLOCK + 1000
    return P.line(holder, cols, total, one or "UI_ZeD_Inv_ItemsOne", many or "UI_ZeD_Inv_ItemsMany", nil)
end

local a, b, c = item("a", 0.5), item("b", 1.25), item("c", 0.3)
local s1, s2, s3 = item("s1", 0.1), item("s2", 0.1), item("s3", 0.1)
local STACK = { count = 3, items = { s1, s2, s3 }, key = "nails" }

section("MODULE")
do
    local cInv = inv(48)
    local h = { _selectedItems = {}, _inventory = cInv, _stacks = {} }
    local t = lineNow(h, nil, 48)
    check("nothing picked: N items", t == "48 items", t)
    check("nothing picked: no weight", not t:find("kg"), t)
    check("one thing in the list: 1 item", lineNow({ _selectedItems = {} }, nil, 1) == "1 item")
    h._selectedItems[a] = true
    t = lineNow(h, nil, 48)
    check("one picked: 1 of 48 picked | 0.5 kg", t == "1 of 48 picked | 0.5 kg", t)
    h._selectedItems[b] = true; h._selectedItems[c] = true
    t = lineNow(h, nil, 48)
    -- 0.5 + 1.25 + 0.3 = 2.05: summed first, one decimal after (2.0 or 2.1 by the float; the rows' own %.1f)
    check("three picked: 3 of 48 picked | sum kg", t == "3 of 48 picked | " .. string.format("%.1f", 2.05) .. " kg", t)
    -- a closed stack's row stands for its three things
    h._selectedItems = { [s1] = true }
    h._stacks = { [s1] = STACK }
    h._expandedStacks = {}
    t = lineNow(h, nil, 48)
    check("a closed stack's row counts the stack", t == "3 of 48 picked | 0.3 kg", t)
    h._expandedStacks = { nails = true }
    t = lineNow(h, nil, 48)
    check("an open stack's row counts its own thing", t == "1 of 48 picked | 0.1 kg", t)
    GRID[cInv] = true
    t = lineNow(h, nil, 48)
    check("a grid opens no stacks: the cell is the stack", t == "3 of 48 picked | 0.3 kg", t)
    GRID[cInv] = nil
    -- the pad's marks put every thing of the stack in the table: still three, not six
    h._selectedItems = { [s1] = true, [s2] = true, [s3] = true }
    h._expandedStacks = {}
    t = lineNow(h, nil, 48)
    check("a marked stack and its row count each thing once", t == "3 of 48 picked | 0.3 kg", t)
    h._selectedItems = {}
    t = lineNow(h, nil, 48)
    check("picks gone: back to N items", t == "48 items", t)
end

section("COLUMNS")
do
    local i1, i2, i3 = inv(10), inv(20), inv(5)
    local cs1 = { inventory = i1, selectedItems = { [a] = true } }
    local cs2 = { inventory = i2, selectedItems = { [s1] = true }, stacks = { [s1] = STACK }, expandedStacks = {} }
    local cs3 = { inventory = i3, selectedItems = { [b] = true } }
    -- (the panel's own table is the last column's, as the renderer leaves it)
    local h = { _selectedItems = cs3.selectedItems, _inventory = i3 }
    local t = lineNow(h, { cs1, cs2, cs3 })
    check("picks across columns against every column's things",
        t == "5 of 35 picked | " .. string.format("%.1f", 2050 / 1000) .. " kg", t)   -- (summed in grams: one answer)
    cs1.selectedItems, cs2.selectedItems, cs3.selectedItems = {}, {}, {}
    h._selectedItems = cs3.selectedItems
    t = lineNow(h, { cs1, cs2, cs3 })
    check("nothing picked in any column: the columns' N items", t == "35 items", t)
end

-- ---------------------------------------------------------------------------
-- the windows' own lines, cut out and run
-- ---------------------------------------------------------------------------
local function round(x, n) local m = 10 ^ (n or 0); return math.floor(x * m + 0.5) / m end
local function javaInv(n, w, max)
    return { n = n, getCapacityWeight = function() return w end, getMaxWeight = function() return max end,
             getEffectiveCapacity = function() return max end }
end
-- a character whose own inventory is `main` (its heading reads the carry limit)
local function playerOf(main) return { getInventory = function() return main end } end
local function run(piece, name, ...)
    local f, err = loadstring(piece, "=" .. name)
    if not f then return nil, err end
    return pcall(f, ...)
end

local CW = srcOf("ZeD_CharacterWindow.lua")
local WW = srcOf("ZeD_WorldWindow.lua")

section("CHAR")
do
    local single = cut(CW, "            local cnt = win._containers[viewIdx]\n", "\"UI_ZeD_Char_ItemsOne\", \"UI_ZeD_Char_ItemsMany\", win._playerObj)")
    check("the Character window's single-list line is found", single ~= nil)
    if single then
        local cInv = javaInv(48, 7.04, 19)
        local self = { _selectedItems = {}, _stacks = {} }
        local win = { _containers = { { name = "Inventory", isMain = true, inventory = cInv } }, _playerObj = playerOf(cInv) }
        local ok, e = run("local self, win, viewIdx, round = ...\n" .. single .. "\nend", "char single", self, win, 1, round)
        check("it runs", ok, e)
        CLOCK = CLOCK + 1000
        run("local self, win, viewIdx, round = ...\n" .. single .. "\nend", "char single", self, win, 1, round)
        check("at rest: 48 items, no weight", win._statusLine == "48 items", win._statusLine)
        check("the heading keeps the container's weight", self._containerInfo and self._containerInfo.stats == "7.0 / 19 kg",
            self._containerInfo and self._containerInfo.stats)
        self._selectedItems[a] = true; self._selectedItems[c] = true
        CLOCK = CLOCK + 1000
        run("local self, win, viewIdx, round = ...\n" .. single .. "\nend", "char single", self, win, 1, round)
        check("picked: 2 of 48 picked | 0.8 kg", win._statusLine == "2 of 48 picked | 0.8 kg", win._statusLine)
    end
    local multi = cut(CW, "            r.renderMultiColumnContent(self)\n", "\"UI_ZeD_Char_ItemsOne\", \"UI_ZeD_Char_ItemsMany\", win._playerObj)")
    check("the Character window's columns line is found", multi ~= nil)
    if multi then
        local cs1 = { inventory = inv(12), selectedItems = { [a] = true } }
        local cs2 = { inventory = inv(30), selectedItems = { [b] = true, [c] = true } }
        local self = { _colStates = { cs1, cs2 }, _selectedItems = cs2.selectedItems }
        local win = { _playerObj = {} }
        local r = { renderMultiColumnContent = function() end }
        CLOCK = CLOCK + 1000
        local ok, e = run("local self, win, r = ...\n" .. multi, "char multi", self, win, r)
        check("it runs", ok, e)
        check("columns: 3 of 42 picked", win._statusLine == "3 of 42 picked | " .. string.format("%.1f", 2.05) .. " kg", win._statusLine)
        check("the old 'N containers' line is gone from the help line", not CW:find("win._statusLine = win._titleSub", 1, true))
    end
end

section("WORLD")
do
    local single = cut(WW, "            local cnt = win._containers[viewIdx]\n            -- (set every frame", "\"UI_ZeD_Inv_ItemsOne\", \"UI_ZeD_Inv_ItemsMany\", win._playerObj)")
    check("the World window's single-list line is found", single ~= nil)
    if single then
        local head = "local self, win, viewIdx, round, mcSel = ...\n"
        local crate = javaInv(20, 12.3, 50)
        local floor = javaInv(4, 3, 0)
        local self = { _selectedItems = {}, _stacks = {} }
        local win = { _containers = { { name = "Crate", inventory = crate }, { name = "Floor", isFloor = true, inventory = floor } },
            _playerObj = playerOf(javaInv(0, 0, 22)), _mainVisible = true }
        CLOCK = CLOCK + 1000
        local ok, e = run(head .. single .. "\nend", "world single", self, win, 1, round, {})
        check("it runs", ok, e)
        check("at rest: 20 items, no weight", win._statusLine == "20 items", win._statusLine)
        check("the heading keeps the container's weight", self._containerInfo.stats == "12.3 / 50 kg", self._containerInfo.stats)
        self._selectedItems[b] = true
        CLOCK = CLOCK + 1000
        run(head .. single .. "\nend", "world single", self, win, 1, round, {})
        check("picked: 1 of 20 picked | 1.2 kg", win._statusLine == "1 of 20 picked | " .. string.format("%.1f", 1.25) .. " kg", win._statusLine)
        -- the floor: its count at rest, the picks' weight while picked
        self._selectedItems = {}
        CLOCK = CLOCK + 1000
        run(head .. single .. "\nend", "world floor", self, win, 2, round, {})
        check("the floor at rest: 4 items", win._statusLine == "4 items", win._statusLine)
        self._selectedItems = { [a] = true }
        CLOCK = CLOCK + 1000
        run(head .. single .. "\nend", "world floor", self, win, 2, round, {})
        check("the floor picked: 1 of 4 picked | 0.5 kg", win._statusLine == "1 of 4 picked | 0.5 kg", win._statusLine)
        -- one column left of several (main hidden): its picks sit in its column state
        self._selectedItems = {}
        self._colStates = { { inventory = crate, selectedItems = { [a] = true, [c] = true } } }
        win._mainVisible = false
        CLOCK = CLOCK + 1000
        run(head .. single .. "\nend", "world one column", self, win, 1, round, { 1 })
        check("one column left: its column's picks count", win._statusLine == "2 of 20 picked | 0.8 kg", win._statusLine)
    end
    local multi = cut(WW, "            r.renderMultiColumnContent(self)\n", "\"UI_ZeD_Inv_ItemsOne\", \"UI_ZeD_Inv_ItemsMany\", win._playerObj)")
    check("the World window's columns line is found", multi ~= nil)
    if multi then
        local cs1 = { inventory = inv(7), selectedItems = {} }
        local cs2 = { inventory = inv(3), selectedItems = {} }
        local self = { _colStates = { cs1, cs2 }, _selectedItems = cs2.selectedItems }
        local win = { _playerObj = {} }
        local r = { renderMultiColumnContent = function() end }
        CLOCK = CLOCK + 1000
        local ok, e = run("local self, win, r = ...\n" .. multi, "world multi", self, win, r)
        check("it runs", ok, e)
        check("columns at rest: 10 items (the line was empty before)", win._statusLine == "10 items", win._statusLine)
        cs1.selectedItems[a] = true; cs2.selectedItems[b] = true
        CLOCK = CLOCK + 1000
        run("local self, win, r = ...\n" .. multi, "world multi", self, win, r)
        check("columns picked: 2 of 10", win._statusLine == "2 of 10 picked | " .. string.format("%.1f", 1.75) .. " kg", win._statusLine)
    end
    check("the World help line's weight string is gone", not WW:find("UI_ZeD_World_WeightOf", 1, true))
end

section("PAD")
do
    local IR = srcOf("InventoryRenderer.lua")
    local piece = cut(IR, "local function padSel(w, el)", "    padRefresh(w, cnt)\nend")
    check("the pad's mark code is found", piece ~= nil)
    if piece then
        local ok, e = run(piece, "pad marks")
        check("it runs", ok, e)
        local cnt = { _selectedItems = {}, _stacks = { [s1] = STACK } }
        local w = { _mainContent = cnt }
        ZeD.InventoryRenderer.padMark(w, { item = a })
        ZeD.InventoryRenderer.padMark(w, { item = s1 })
        local t = lineNow(cnt, nil, 48)
        check("pad marks: a thing and a stack header are 4 picked", t == "4 of 48 picked | " .. string.format("%.1f", 0.8) .. " kg", t)
        -- in columns, a mark lands in its column's table
        local cs1 = { inventory = inv(5), selectedItems = {} }
        local cs2 = { inventory = inv(6), selectedItems = {} }
        local cnt2 = { _colStates = { cs1, cs2 }, _selectedItems = cs2.selectedItems }
        ZeD.InventoryRenderer.padMark({ _mainContent = cnt2 }, { item = b, colIdx = 1 })
        ZeD.InventoryRenderer.padMark({ _mainContent = cnt2 }, { item = c, colIdx = 2 })
        t = lineNow(cnt2, cnt2._colStates)
        check("pad marks in two columns count together", t == "2 of 11 picked | " .. string.format("%.1f", 1.55) .. " kg", t)
        check("the pad's own count agrees", ZeD.InventoryRenderer.padMarkCountOf(cnt2) == 2)
    end
end

section("HELP")
do
    local S = srcOf("ZeD_Surface.lua")
    local take = cut(S, "function H.take(win)", "\nend")
    take = take and cut(S, "function H.take(win)", "    return nil\nend")
    check("H.take is found", take ~= nil)
    if take then
        local H = {}
        local f = loadstring("local H = ...\n" .. take)
        f(H)
        local win = { _statusLine = "48 items" }
        win.getStatusLine = function(self) return self._statusLine end
        win._helpText = "Drag to move it; RMB for its menu"
        check("hover help wins over the resting line", H.take(win) == "Drag to move it; RMB for its menu")
        check("with nothing under the pointer, the resting line", H.take(win) == "48 items")
    end
    check("the windows still hand the help line their status line",
        CW:find("win.getStatusLine = function(self) return self._statusLine end", 1, true) ~= nil
        and WW:find("win.getStatusLine = function(self) return self._statusLine end", 1, true) ~= nil)
end

section("PERF")
do
    local many = {}
    for i = 1, 200 do many[i] = item("m" .. i, 0.25) end
    local origGather = P.gather
    for _, fps in ipairs({ 60, 240 }) do
        local h = { _selectedItems = {} }
        for _, it in ipairs(many) do h._selectedItems[it] = true end
        local gathers = 0
        P.gather = function(...) gathers = gathers + 1; return origGather(...) end
        WEIGHED = 0
        local t0 = CLOCK + 5000
        CLOCK = t0
        local frames = fps * 10
        local text
        for f = 0, frames - 1 do
            CLOCK = t0 + math.floor(f * 1000 / fps)
            text = P.line(h, nil, 400, "UI_ZeD_Inv_ItemsOne", "UI_ZeD_Inv_ItemsMany")
        end
        check(fps .. " FPS: the line is right", text == "200 of 400 picked | 50.0 kg", text)
        check(fps .. " FPS: looked at every 100 ms, not every frame", gathers <= 101, gathers .. " looks in " .. frames .. " frames")
        check(fps .. " FPS: weighed once a second when nothing changed", WEIGHED <= 11 * 200, WEIGHED .. " weight calls")
        P.gather = origGather
    end
    -- a new pick of the same size (a click on another row): seen within one period
    local h = { _selectedItems = { [a] = true } }
    CLOCK = CLOCK + 5000
    local t1 = P.line(h, nil, 9, "UI_ZeD_Inv_ItemsOne", "UI_ZeD_Inv_ItemsMany")
    h._selectedItems[a] = nil; h._selectedItems[b] = true
    CLOCK = CLOCK + 16
    local t2 = P.line(h, nil, 9, "UI_ZeD_Inv_ItemsOne", "UI_ZeD_Inv_ItemsMany")
    CLOCK = CLOCK + 100
    local t3 = P.line(h, nil, 9, "UI_ZeD_Inv_ItemsOne", "UI_ZeD_Inv_ItemsMany")
    check("the first pick shows", t1 == "1 of 9 picked | 0.5 kg", t1)
    check("inside the period the line holds", t2 == t1, t2)
    check("a swapped pick shows within 100 ms", t3 == "1 of 9 picked | " .. string.format("%.1f", 1.25) .. " kg", t3)
end

section("KEPT")
do
    -- (the weights stay where they were and say what they said, one format since Nov 12 2026: ZeD.Atoms.loadText)
    local function oneFormat(rel, from, to)
        local now = cut(srcOf(rel), from, to)
        return now ~= nil and now:find("ZeD.Atoms.loadText(", 1, true) ~= nil, now == nil and "not found" or "another format"
    end
    local ok, why = oneFormat("ZeD_CharacterWindow.lua", "        -- Weight (rightmost):", "noMark = true }")
    check("the title bar's weight: the load over the max, in the one format", ok, why)
    ok, why = oneFormat("ZeD_CharacterWindow.lua", "                self._containerInfo = {", "                }")
    check("the Character heading's weight, in the one format", ok, why)
    ok, why = oneFormat("ZeD_WorldWindow.lua", "                self._containerInfo = {", "                }")
    check("the World heading's weight, in the one format", ok, why)
    ok, why = oneFormat("InventoryRenderer.lua", "            local weight   = inv and inv:getCapacityWeight() or 0", "local statsStr")
    check("the column heading's weight, in the one format", ok, why)
    -- (Nov 12 2026: the headings' capacity is the game's for the character, InventoryRenderer.capacityOf)
    local colNow = cut(srcOf("InventoryRenderer.lua"), "            local weight   = inv and inv:getCapacityWeight() or 0", "local statsStr")
    check("the column heading's capacity asks the game's for the character",
        colNow ~= nil and colNow:find("local capacity = ZeD.InventoryRenderer.capacityOf(inv, self._playerObj)", 1, true) ~= nil)
    check("the Character heading's capacity asks the game's for the character",
        srcOf("ZeD_CharacterWindow.lua"):find("round(ZeD.InventoryRenderer.capacityOf(cInv, win._playerObj), 1)", 1, true) ~= nil)
    -- every new string in every language
    for _, L in ipairs({ "AR", "CA", "CH", "CN", "CS", "DA", "DE", "EN", "ES", "ES_CL", "ES_MX", "FI", "FR", "HU", "ID", "IT",
                         "JP", "KO", "NL", "NO", "PL", "PT", "PTBR", "RO", "RU", "TH", "TR", "UA" }) do
        local j = readFile("42/media/lua/shared/Translate/" .. L .. "/UI.json") or ""
        local one = j:match('"UI_ZeD_Inv_PickedOne": "([^"]*)"')
        local many = j:match('"UI_ZeD_Inv_PickedMany": "([^"]*)"')
        check(L .. ": both picked strings, with %1 %2 %3", one and many and one:find("%1", 1, true) and one:find("%2", 1, true)
            and one:find("%3", 1, true) and many:find("%1", 1, true) and many:find("%2", 1, true) and many:find("%3", 1, true))
    end
end

print(string.format("footer_picked_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
