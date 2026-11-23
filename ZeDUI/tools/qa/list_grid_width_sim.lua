-- ZeDUI/tools/qa/list_grid_width_sim.lua  (Nov 22 2026, the director's two inventory notes): the grid's width and the
-- list's columns, with no game running. It cuts the real pieces out of InventoryRenderer.lua, loads the real
-- WindowHalves.lua, and runs them on stub windows and panels.
--   HUG      (Grid width: "In grid mode, can the width of the inventory hug the grid width?") gridHugW gives a width
--            that holds exactly n whole cells by the grid's own column count (gridState), at 1080p, 4K at 1.75,
--            1280 x 800 (0.75) and Large text: down to whole cells at rest, the nearest under a drag, up for
--            side-by-side columns; hugInvW keeps the least (three cells alone, MIN_COL_W side by side) and adds
--            the transfer strips between columns
--   WINDOW   ZeD.Halves.gridHug on a stub window: a grid side shrinks to whole cells (the Character window keeps its
--            right edge and anchor, the World window its left); a drag snaps to the nearest whole cell and keeps the
--            edge not dragged; nothing while a drawer slides, the cap holds part of a drawer, the side is rolled or
--            hidden; never past the window's widest; back to a list the side gets the list's width again (one
--            column: _baseInvW; side-by-side: the width before hugging); invMin lets one hugging column go to three
--            cells; both windows call it where the side is the residual, keep _baseInvW while hugging and take
--            invMin as the inventory's least
--   STATE    the renderer tells the window: a lone list sets _hugN only for a grid of ZeD's own cells (not an
--            add-on's layout); side-by-side columns only when every one is such a grid; the heading's narrow step
--            (headStacks) is taken by a grid whose one row would drop the weight, never by a list
--   COLUMNS  (List columns: "Name always wins. Weight comes in second place. Category comes in third place. And if
--            there's room, it shows condition.") fitColumns keeps Category before Status (read marks on or off),
--            Status only where the name keeps COND_NAME_U; the list asks it for a column among several too (no more
--            name and weight alone there); the headings are built from the shown columns only
--   BAND     (Buttons right, Nov 22 2026) the footer band's buttons right-aligned at its right end, their order kept
--   SORT     a sort on a hidden Status draws as Name (the choice kept); Category stays (its headings say it); the
--            grid keeps every sort; the pad's L3 skips a hidden Status
-- Run from the repo root:  lua51 ZeDUI/tools/qa/list_grid_width_sim.lua
-- It prints FAIL lines and a last line "list_grid_width_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]list_grid_width_sim%.lua$", "")

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
local PLAYER = { getModData = function() return {} end }
getSpecificPlayer = function() return PLAYER end
getPlayer = function() return PLAYER end
require = function() end
ZeD = { InventoryRenderer = {} }
local GRIDKEYS = {}
ZeD.InventoryRenderer.isGridKey = function(key) return GRIDKEYS[key] == true end
containerKeyOf = function(inv) return inv and inv.key end   -- (listSort's upvalue, a global in the cut chunk)
SORT_COLS = { "name", "cat", "cond", "wt" }

-- T at a scale: T.px as Tokens' (floor(units * scale + 0.5)), the spacing tokens it scales
local function mkT(sc)
    local T = { scale = sc }
    T.px = function(u) return math.floor(u * sc + 0.5) end
    T.sp = { sm = T.px(10), scrollbarW = T.px(14) }
    return T
end
ZeD.T = mkT(1)

local IR = readFile("42/media/lua/client/ZeD/InventoryRenderer.lua")
local function cut(from, to, ret, name)
    local a = IR:find(from, 1, true)
    local b = a and IR:find(to, a, true)
    check("cut " .. name, a ~= nil and b ~= nil)
    if not (a and b) then return nil end
    local ok, r1, r2 = pcall(function() return assert(loadstring(IR:sub(a, b - 1) .. "\n" .. (ret or ""), name))() end)
    check("load " .. name, ok, r1)
    return r1, r2
end
local R = ZeD.InventoryRenderer
cut("local GRID_CELL, GRID_GAP = 52, 4", "\n", "", "grid sizes")   -- (only to prove the line is there)
local cell, gap = IR:match("local GRID_CELL, GRID_GAP = (%d+), (%d+)")
GRID_CELL, GRID_GAP = tonumber(cell), tonumber(gap)
cut("-- (List columns, the director, Nov 22 2026) the sort a list draws with", "-- R3: the container", "", "listSort .. padSort")
R.MIN_COL_W = tonumber(IR:match("local MIN_COL_W%s*=%s*(%d+)"))
check("MIN_COL_W read", R.MIN_COL_W ~= nil)
local fitColumns = cut("local function fitColumns(", "\n-- A grid cell names its item", "return fitColumns", "fitColumns")
local gridState = cut("local function gridState(", "\nlocal function gridCount(", "return gridState", "gridState")

-- ---------------------------------------------------------------------------
section("HUG")
-- ---------------------------------------------------------------------------
-- the grid's own column count for a width (gridState, the real one)
local function colsAt(T, colW)
    ZeD.T = T
    local GV = gridState({}, { key = "k" }, PLAYER, colW, T.sp.scrollbarW, T.sp.sm, {})
    return GV.cols
end
for _, sc in ipairs({ 1.0, 1.75, 0.75, 1.15, 1.75 * 1.15 }) do
    local T = mkT(sc)
    ZeD.T = T
    local tag = "x" .. sc
    local okAll, bad = true, nil
    for w = T.px(150), T.px(900), 7 do
        local h = R.gridHugW(w)
        local n = colsAt(T, h)
        -- a hugged width holds whole cells: one more px of cells would be the next column, and its own cols are the
        -- cells it was snapped to; never wider than asked at rest
        if h > w and colsAt(T, w) >= 1 and h ~= R.gridHugW(T.px(1)) then okAll, bad = false, "wider " .. w .. "->" .. h end
        if colsAt(T, h - 1) ~= n - 1 and n > 1 then okAll, bad = false, "not tight at " .. w end
        if colsAt(T, w) ~= n and w >= R.gridHugW(0) then okAll, bad = false, "cols differ at " .. w .. ": " .. colsAt(T, w) .. " vs " .. n end
        local up, near = R.gridHugW(w, "up"), R.gridHugW(w, true)
        if up < w then okAll, bad = false, "up under at " .. w end
        if math.abs(near - w) > (T.px(GRID_CELL) + T.px(GRID_GAP)) / 2 + 0.5 then okAll, bad = false, "nearest far at " .. w end
        if colsAt(T, up) * 0 ~= 0 then okAll = false end
    end
    check("HUG " .. tag .. ": whole cells, as many as the grid fits, never wider at rest; up and nearest", okAll, bad)
    -- the snap is a fixed point: a hugged width snaps to itself every way
    local h = R.gridHugW(T.px(372))
    check("HUG " .. tag .. ": a hugged width snaps to itself (floor, nearest, up)",
        R.gridHugW(h) == h and R.gridHugW(h, true) == h and R.gridHugW(h, "up") == h, h)
    -- the least: three cells alone, MIN_COL_W side by side
    local least1 = R.hugInvW(0, 1, 0, false)
    check("HUG " .. tag .. ": one column's least is the widest whole width under 200 units", least1 <= T.px(200)
        and R.gridHugW(T.px(200)) == least1 and colsAt(T, least1) == 3, least1)
    local xfer = T.px(32)
    local least2 = R.hugInvW(0, 2, xfer, false)
    local per = (least2 - xfer) / 2
    check("HUG " .. tag .. ": side by side, each column at least MIN_COL_W in whole cells", per >= T.px(R.MIN_COL_W)
        and R.gridHugW(per) == per, per)
    local w3 = R.hugInvW(T.px(800), 3, xfer, false)
    local per3 = (w3 - 2 * xfer) / 3
    check("HUG " .. tag .. ": three columns: n whole widths and two strips", per3 == math.floor(per3) and R.gridHugW(per3) == per3
        and w3 <= T.px(800), w3)
end
ZeD.T = mkT(1)
check("HUG 1080p: the usual 372-unit side hugs six cells, 366 units", R.gridHugW(372) == 366 and colsAt(ZeD.T, 366) == 6, R.gridHugW(372))

-- ---------------------------------------------------------------------------
section("WINDOW")
-- ---------------------------------------------------------------------------
-- WindowHalves.lua, loaded whole
local okH, errH = pcall(function() assert(loadstring(readFile("42/media/lua/client/ZeD/WindowHalves.lua"), "@WindowHalves"))() end)
check("WindowHalves loads", okH, errH)
local H = ZeD.Halves
check("ZeD.Halves.gridHug and invMin", type(H.gridHug) == "function" and type(H.invMin) == "function")

local function mkWin(o)
    local w = { x = o.x or 100, w = o.w, minimumWidth = o.min or 0, _baseInvW = o.base or 372, _drawerEffW = o.drawer or 0 }
    function w:getWidth() return self.w end
    function w:setWidth(v) self.w = math.max(v, self.minimumWidth or 0) end   -- (Java's setWidth clamps to the minimum)
    function w:getX() return self.x end
    function w:setX(v) self.x = v end
    for k, v in pairs(o) do if k:sub(1, 1) == "_" then w[k] = v end end
    return w
end
local function mkContent(n, cols, xfer, visible)
    return { _hugN = n, _hugCols = cols or 1, _hugXfer = xfer or 0, vis = visible ~= false,
             getIsVisible = function(self) return self.vis end }
end
if H.gridHug then
    ZeD.T = mkT(1)
    local CHROME = 72   -- (the two strips)
    -- the Character window (anchored at its right edge), a grid side 372 wide, at rest
    local win = mkWin({ w = CHROME + 372, x = 500, _anchorRightEdge = 500 + CHROME + 372, _lastSetX = 500 })
    local c = mkContent(1)
    local inv = H.gridHug(win, c, 372, true, 960)
    check("WINDOW Character at rest: the side shrinks to whole cells", inv == 366 and win.w == CHROME + 366, inv)
    check("WINDOW Character: its right edge and anchor stay", win.x + win.w == 500 + CHROME + 372
        and win._anchorRightEdge == 500 + CHROME + 372 and win._lastSetX == win.x, win.x)
    check("WINDOW the list's width is remembered", win._gridHug and win._gridHug.n == 1)
    -- a second frame: nothing more
    local w0 = win.w
    inv = H.gridHug(win, c, inv, true, 960)
    check("WINDOW a hugged side stays put the next frame", inv == 366 and win.w == w0)
    -- a drag on the right edge: the nearest whole cell from the pointer's width, the left edge kept
    win._resizing, win._resizeMode = true, "e"
    win.w = CHROME + 366 + 40   -- (the pointer 40 px out: past half a cell, so a cell more)
    local x0 = win.x
    inv = H.gridHug(win, c, 366 + 40, true, 960)
    check("WINDOW a drag snaps to the nearest whole cell (a cell more)", inv == 366 + 56, inv)
    check("WINDOW a drag on the right edge keeps the left edge", win.x == x0)
    win.w = CHROME + 422 + 20   -- (20 px out: under half a cell, back to where it was)
    inv = H.gridHug(win, c, 422 + 20, true, 960)
    check("WINDOW a short drag snaps back (the nearest)", inv == 422, inv)
    -- a drag on the left edge keeps the right edge
    win._resizeMode = "w"
    local right = win.x + win.w
    win.w = win.w + 33; win.x = right - win.w
    inv = H.gridHug(win, c, 422 + 33, true, 960)
    check("WINDOW a drag on the left edge keeps the right edge", win.x + win.w == right and inv == 422 + 56, inv)
    win._resizing, win._resizeMode = nil, nil
    -- never past the window's widest: the whole width under it
    local wideW = CHROME + 500
    local wwin = mkWin({ w = wideW, _resizing = true, _resizeMode = "e" })
    inv = H.gridHug(wwin, c, 500, true, wideW + 10)
    check("WINDOW the nearest past the widest: the whole width under it", inv <= 500 and wwin.w <= wideW + 10 and R.gridHugW(inv) == inv, inv)
    -- left alone: a sliding drawer, the cap's hold, rolled, hidden
    local cases = {
        { "a drawer sliding", mkWin({ w = CHROME + 372 }), mkContent(1), false },
        { "the cap holding part of a drawer", mkWin({ w = CHROME + 372, _drawerCapLost = 30 }), mkContent(1), true },
        { "a rolled side", mkWin({ w = CHROME + 372, _rolled = true }), mkContent(1), true },
        { "a hidden content", mkWin({ w = CHROME + 372 }), mkContent(1, 1, 0, false), true },
        { "a list (no hug)", mkWin({ w = CHROME + 372 }), mkContent(nil), true },
    }
    for _, cs in ipairs(cases) do
        local r = H.gridHug(cs[2], cs[3], 372, cs[4], 960)
        check("WINDOW left alone: " .. cs[1], r == 372 and cs[2].w == CHROME + 372, r)
    end
    -- back to a list: the window's saved list width (the Character window's right edge kept)
    local bw = mkWin({ w = CHROME + 372, x = 300, _anchorRightEdge = 300 + CHROME + 372, base = 372 })
    local gc = mkContent(1)
    inv = H.gridHug(bw, gc, 372, true, 960)
    check("WINDOW hugging", inv == 366)
    check("WINDOW invMin while one column hugs: three cells", H.invMin(bw, gc) == R.gridHugW(200) and H.invMin(bw, gc) < 200, H.invMin(bw, gc))
    gc._hugN = nil
    inv = H.gridHug(bw, gc, inv, true, 960)
    check("WINDOW back to a list: the list's width again", inv == 372 and bw.w == CHROME + 372 and bw._gridHug == nil, inv)
    check("WINDOW back to a list: right edge kept", bw.x + bw.w == 300 + CHROME + 372)
    check("WINDOW invMin for a list: 200 units", H.invMin(bw, gc) == 200)
    -- back to a list while a drawer slides: waits for rest
    local sw = mkWin({ w = CHROME + 366, _gridHug = { n = 1, from = 372 } })
    inv = H.gridHug(sw, mkContent(nil), 366, false, 960)
    check("WINDOW back to a list waits while a drawer slides", inv == 366 and sw._gridHug ~= nil)
    -- the World window (no anchor): its left edge stays
    local ww = mkWin({ w = CHROME + 372, x = 1000 })
    inv = H.gridHug(ww, mkContent(1), 372, true, 960)
    check("WINDOW World at rest: shrinks, its left edge kept", inv == 366 and ww.x == 1000 and ww.w == CHROME + 366)
    -- side by side: two grids hug per column, the strip between them counted; back to lists: the width before
    local xfer = 32
    local mw = mkWin({ w = CHROME + 2 * 220 + xfer, x = 50 })
    local mc = mkContent(2, 2, xfer)
    inv = H.gridHug(mw, mc, 2 * 220 + xfer, true, 1900)
    local per = (inv - xfer) / 2
    check("WINDOW two grid columns: each whole cells, the strip kept", per == R.gridHugW(220) and inv == 2 * R.gridHugW(220) + xfer, inv)
    mc._hugN = nil
    inv = H.gridHug(mw, mc, inv, true, 1900)
    check("WINDOW two columns back to lists: the width they had", inv == 2 * 220 + xfer, inv)
    -- the minimum lowered before the width is set (Java's clamp)
    local nw = mkWin({ w = CHROME + 200, min = CHROME + 200 })
    inv = H.gridHug(nw, mkContent(1), 200, true, 960)
    check("WINDOW at 200 units the side goes to three cells under the old minimum", inv == R.gridHugW(200) and nw.w == CHROME + inv, inv)
end

-- the windows call it where the side is the residual, keep the list width while hugging, and take its least
for _, f in ipairs({ "ZeD_CharacterWindow.lua", "ZeD_WorldWindow.lua" }) do
    local S = readFile("42/media/lua/client/ZeD/" .. f)
    check("WINDOW " .. f .. " hugs the residual side", S:find("invW = ZeD.Halves.gridHug(win, content, invW, drawerDelta == 0", 1, true) ~= nil)
    check("WINDOW " .. f .. " keeps _baseInvW while hugging", S:find("and not win._gridHug then\n            local expectedW", 1, true) ~= nil)
    check("WINDOW " .. f .. " takes invMin as the inventory's least", S:find("not win._rolled and ZeD.Halves.invMin(win, content) or 0)", 1, true) ~= nil
        and not S:find("not win._rolled and T.px(200) or 0)", 1, true))
    local a = S:find("invW = ZeD.Halves.gridHug(", 1, true)
    local b = S:find("content:setWidth(math.max(invW, 0))", 1, true)
    check("WINDOW " .. f .. " hugs before the content takes its width", a and b and a < b)
end

-- ---------------------------------------------------------------------------
section("STATE")
-- ---------------------------------------------------------------------------
check("STATE a lone list: _hugN for ZeD's own grid only", IR:find("self._hugN = (self._gv.on and not self._gv.L) and 1 or nil", 1, true) ~= nil
    and IR:find("if not self._compactMode then\n        self._hugN", 1, true) ~= nil)
check("STATE side by side: every column a grid", IR:find("if not (self._gv and self._gv.on and not self._gv.L) then allGrid = false end", 1, true) ~= nil
    and IR:find("self._hugN = allGrid and N or nil", 1, true) ~= nil and IR:find("self._hugXfer, self._hugCols = xferW, N", 1, true) ~= nil)
check("STATE the heading's narrow step for a grid", IR:find("if (self._compactMode or ZeD.InventoryRenderer.headStacks(", 1, true) ~= nil)
if R.headStacks == nil then
    -- the heading's helper needs drawViewToggle: cut it with the heading
    ZeD.TM = { MeasureStringX = function(_, f, s) return #tostring(s) * 8 end, getFontHeight = function() return 14 end }
end
do
    local a = IR:find("function ZeD.InventoryRenderer.headStacks(", 1, true)
    local b = a and IR:find("\nend\n", a, true)
    local src = a and IR:sub(a, b + 4)
    local measured = 0
    local okS = pcall(function()
        local env = setmetatable({ drawViewToggle = function() measured = measured + 1; return 60 end }, { __index = _G })
        local fn = assert(loadstring(src, "headStacks"))
        setfenv(fn, env)
        fn()
    end)
    check("STATE headStacks loads", okS)
    ZeD.T = mkT(1); ZeD.T.fontF4 = "F4"; ZeD.T.sp.iconGap = 8
    ZeD.TM = { MeasureStringX = function(_, f, s) return #tostring(s) * 8 end }
    local panel = { _containerInfo = { name = "Inventory" } }   -- (72 wide at 8 a letter)
    local wide, narrow = 400, 190
    check("STATE a list never stacks", R.headStacks(panel, { on = false }, narrow, 10, 70, 14, 30) == false)
    check("STATE a wide grid keeps one row", R.headStacks(panel, { on = true }, wide, 10, 70, 14, 30) == false)
    check("STATE a narrow grid whose row would drop the weight stacks", R.headStacks(panel, { on = true }, narrow, 10, 70, 14, 30) == true)
    check("STATE no weight: no stack", R.headStacks(panel, { on = true }, narrow, 10, 0, 14, 30) == false)
end

-- ---------------------------------------------------------------------------
section("COLUMNS")
-- ---------------------------------------------------------------------------
if fitColumns then
    -- room past the name's least; Category 106, Status 50, the name's extra beside Status 40
    local c, k = fitColumns(300, 106, 50, 40)
    check("COLUMNS room for all: Category and Status", c and k)
    c, k = fitColumns(170, 106, 50, 40)
    check("COLUMNS Category and Status fit but not the name's extra: Category only", not c and k)
    c, k = fitColumns(110, 106, 70, 0)
    check("COLUMNS only one fits: Category (read marks or not)", not c and k)
    c, k = fitColumns(100, 106, 50, 0)
    check("COLUMNS Category does not fit: neither (Status never before Category)", not c and not k)
end
check("COLUMNS COND_NAME_U past MIN_NAME", IR:find("ZeD.InventoryRenderer.COND_NAME_U = 140", 1, true) ~= nil
    and IR:find("local MIN_NAME = T.px(100)", 1, true) ~= nil)
-- the usual widths, 1080p Small, English (Fira Mono Bold 11 px for the category, about 6.6 px a letter): the
-- default 372-unit list shows Category, not Status, with read marks on or off
do
    local nameX, padX, scrollW, wtD, MIN = 40, 10, 14, 46, 100
    local cat, condOff, condOn = 106, 50, 69
    local function at(w, cond) return fitColumns(w - nameX - wtD - padX - scrollW - MIN, cat, cond, 140 - MIN) end
    local c1, k1 = at(372, condOff)
    local c2, k2 = at(372, condOn)
    check("COLUMNS 372 units: name, Category, weight (marks off)", k1 and not c1)
    check("COLUMNS 372 units: name, Category, weight (marks on)", k2 and not c2)
    local c3, k3 = at(420, condOff)
    check("COLUMNS a wider list (420) adds Status", c3 and k3)
    local c4, k4 = at(296, condOff)
    check("COLUMNS 296 units (the Deck's opening width): name and weight", not c4 and not k4)
end
-- every list asks the one fit, a column among several too, with its compact weight column
check("COLUMNS one fit for every list (no forced name and weight in a column among several)",
    IR:find("local wtColW   = self._compactMode and colWData.wtC or colWData.wt", 1, true) ~= nil
    and not IR:find("-- Force compact in multi-column: NAME + WT only", 1, true)
    and IR:find("showCond, showCat = fitColumns(colW - nameX - wtD - padX - scrollW - MIN_NAME, catColW, condColW,", 1, true) ~= nil)
check("COLUMNS headings only for shown columns", IR:find("if showCat then\n        colDefs[#colDefs + 1] = {ZeD.tr(\"UI_ZeD_Inv_ColCat\")", 1, true) ~= nil
    and IR:find("if showCond then\n        -- (left, as Name", 1, true) ~= nil)

-- ---------------------------------------------------------------------------
section("SORT")
-- ---------------------------------------------------------------------------
local list = { _inventory = { key = "bag" }, _playerObj = PLAYER }
check("SORT a hidden Status sorts as Name", R.listSort(list, "cond", false) == "name")
check("SORT a shown Status keeps it", R.listSort(list, "cond", true) == "cond")
check("SORT Category keeps its sort hidden or not", R.listSort(list, "cat", false) == "cat")
check("SORT Weight and Name as they are", R.listSort(list, "wt", false) == "wt" and R.listSort(list, "name", false) == "name")
GRIDKEYS.bag = true
check("SORT the grid keeps a Status sort", R.listSort(list, "cond", false) == "cond")
GRIDKEYS.bag = nil
check("SORT the list draws with listSort, the choice kept", IR:find("local sortCol  = ZeD.InventoryRenderer.listSort(self, self._sortCol or \"name\", showCond)", 1, true) ~= nil)
-- the pad's L3: Category's next is Weight where Status is hidden, Status where it shows
ZeD.Input = { Focus = { getFocusedElement = function() return { colIdx = 1 } end } }
ZeD.uiSound = function() end
local function padNext(showCond)
    local cs = { sortCol = "cat", sortAsc = false, _showCond = showCond }
    local cnt = { _colStates = { cs } }
    R.padSort({ _mainContent = cnt })
    return cs.sortCol
end
check("SORT L3 skips a hidden Status", padNext(false) == "wt", padNext(false))
check("SORT L3 goes to a shown Status", padNext(true) == "cond", padNext(true))
check("SORT the grid counts every key shown", IR:find("if self._gv.on then self._showCat, self._showCond = true, true end", 1, true) ~= nil)
check("SORT each column keeps its shown Status", select(2, IR:gsub("cs._showCond       = self._showCond", "")) == 2)

-- ---------------------------------------------------------------------------
section("BAND")
-- ---------------------------------------------------------------------------
-- (Buttons right, the director, Nov 22 2026) the footer band's buttons right-aligned at its right end, their order kept
do
    local CC = readFile("42/media/lua/client/ZeD/ContainerControls.lua")
    local a = CC:find("local function btnW(label)", 1, true)
    local b = CC:find("--- Lays the band out for a list column", 1, true)
    check("BAND: layRow found", a and b)
    ZeD.T = mkT(1); ZeD.T.buttonH = 24
    ZeD.Molecules = { buttonW = function(label) return #label * 7 + 16 end }
    ZeD.PxIcon = { has = function(id) return id ~= nil end }
    CT = { GAP = 8, DIV_PAD = 4 }
    local ok, layRow = pcall(function() return assert(loadstring(CC:sub(a, b - 1) .. "\nreturn layRow", "layRow"))() end)
    check("BAND: layRow loads", ok, layRow)
    if ok then
        local moves = { { id = "take", label = "Take all" }, { id = "same", label = "Same", icon = "same_type" }, { id = "floor", label = "Floor", icon = "to_floor" } }
        local objs = { { id = "obj:1", label = "Light" } }
        local row = layRow(moves, objs, 8, 400)
        local keys, lastR, prev = {}, 0, -1
        local ordered = true
        for i, r in ipairs(row.rects) do
            keys[i] = r.key
            if r.tx <= prev then ordered = false end
            prev = r.tx
            lastR = math.max(lastR, r.tx + r.w)
        end
        check("BAND: the order kept (Take all, Same type, To floor, then the container's)", table.concat(keys, ",") == "take,same,floor,obj:1" and ordered, table.concat(keys, ","))
        check("BAND: the run ends at the band's right end", lastR == 400, lastR)
        check("BAND: the spare room is at the left (Take all well right of the band's left)", row.rects[1].tx > 8 + 100, row.rects[1].tx)
        check("BAND: the divider between the moves and the container's", row.divX and row.divX > row.rects[3].tx + row.rects[3].w and row.divX < row.rects[4].tx, row.divX)
        local tight = layRow(moves, objs, 8, 120)
        check("BAND: too narrow, the ribbon as before", tight.scroll ~= nil)
    end
end

print(string.format("list_grid_width_sim: %d checks, %d failed", checks, failed))
os.exit(failed == 0 and 0 or 1)
