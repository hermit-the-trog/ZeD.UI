-- ZeD-UI/42/media/lua/client/ZeD/GridLayout.lua
-- ============================================================================
-- GRID LAYOUT (client; a public hook for add-ons, Nov 15 2026)
--
-- ZeD's grid view draws one square per thing (a stack is one square). An add-on
-- (ZeD Multi-Slot: bigger things take more squares) registers ONE layout
-- provider here and decides the cells instead: which things make a cell, where
-- each cell sits and how many squares it spans. ZeD still draws every cell with
-- its own parts (InventoryRenderer's drawGridCell), hit-tests it, gives the pad
-- its focus rects and runs the drags. With no provider, nothing here runs and the
-- grid is exactly ZeD's own.
--
--   ZeD.GridLayout.VERSION                  1 (an add-on checks it talks to a ZeD that has this hook)
--   ZeD.GridLayout.register(id, provider)   one provider at a time; a second logs a line and wins
--   ZeD.GridLayout.unregister(id)
--   ZeD.GridLayout.active()                 the provider, or nil
--   ZeD.GridLayout.dirty(inv)               a new layout of inv (nil: of every container) on the next frame
--
-- provider.layout(ctx) -> answer (required). Called for a grid column when its
-- list model is rebuilt (a container event, a drop, about once a second anyway),
-- after dirty(inv), when the column's width, text size or folds change, or when a
-- provider registers. Never every frame: the answer is kept until then.
--   ctx = { inv, player, key, cols, items, stacks }   (read only; ZeD keeps it for the drag calls below)
--     items   every thing the column lists, one entry per thing (stacks not merged), in ZeD's order
--     stacks  ZeD's own stacks for reference: stacks[rep] = { count, items }
--   answer = { cells, aside, asideText, cols, rows, fixed, flat, overflow, overflowText, headLine }
--     cells   { { item = rep, items = { ... }, x =, y =, w =, h = }, ... } 0-based squares. A cell draws as a stack
--             cell does (count #items, their weight summed, the stack's condition strip; a drag carries them all).
--             A cell with no x / y goes in the first free square that fits it.
--     aside   cells drawn one square each in a strip ABOVE the grid, headed asideText (not part of the grid)
--     overflow cells drawn one square each in a strip UNDER the grid, headed overflowText in the warning colour
--     cols    squares across (nil: ctx.cols). Wider than ctx.cols: the squares shrink to fit, never a sideways scroll
--     rows    the grid's height in squares (nil: as tall as the cells need)
--     fixed   true: every empty square of cols x rows draws as a faint slot
--     flat    true: no category headings with Sort by Category (one grid). Without it, sorted by category, each
--             category is its own grid and ZeD packs its cells first-fit (their x / y are not used then; the drag's
--             ghost and the pad's place mode work only in a single grid)
--     headLine words for the column heading's second line in place of the count ("15 / 30 squares")
--   A thing the column lists that is in no cell, no aside and no overflow cell gets a square of its own in the first
--   free square (the safety net). A cell whose item ZeD does not list is left out.
-- provider.decorate(panel, item, x, y, w, h) (optional): after a visible cell draws, every frame, panel coords.
--   Must not make tables or strings.
-- provider.dragShape(items, ctx) -> w, h          the squares the dragged things take (nil: 1 x 1)
-- provider.canPlace(items, ctx, x, y, w, h) -> ok, reason   may they land with their top-left on square x, y
-- provider.turn(items, ctx)                       turn the dragged thing a quarter (dragShape answers anew)
-- provider.drop(items, ctx, x, y, srcInv) -> handled
--   A mouse drag from a ZeD list over a single grid: the ghost (the footprint at the square under the pointer,
--   centered on it) has a T.positive edge when canPlace says ok, T.danger when not, and the reason is on the help
--   line. R or the mouse wheel turns. On release: drop is called first; into the same container ZeD does nothing more;
--   into another container ZeD makes its usual move, unless canPlace said no (then nothing moves and the help line
--   keeps the reason a moment).
--   The pad (place mode): hold X on a cell of a single grid. The D-pad moves the ghost a square (off the column's
--   side onto the next column's grid, same row), A turns, letting go of X places (drop, then ZeD's move when the
--   container differs), B cancels. The help line reads D-pad Move, A Turn, X Place (let go), B Cancel.
-- Every provider call is guarded: an error is logged once and ZeD falls back to its own grid (layout), draws on
-- (decorate), or treats the drag as 1 x 1 and allowed (dragShape, canPlace).
--
-- VERSION 2 (Nov 16 2026, Multi-Slot 0.2's shaped items). Everything above still holds; a version 1 provider is
-- drawn exactly as before. New:
--   cell.mask        the cell's squares, written row by row: "XXX/XXX/X../X.." (X a square, any other letter a hole;
--                    rows split by "/"). Its w and h come from the mask (c.w, c.h are not read then). The squares
--                    inside its box that are holes are not the cell's: they draw nothing, take no click, and
--                    another cell may sit in them.
--   answer.shapes    true: every grid cell draws square by square (a block is a mask with no holes): each square
--                    filled with the item's tint (GridTint, always on here, whatever the Item-colored tiles setting
--                    says; a plain tile where an item has none), the lines between its squares one shade darker,
--                    a dark outline round the whole shape, the game's picture in the FIRST square (the top row's
--                    leftmost) at one size for every item. A cell with a mask draws so even without it.
--   answer.scale     the squares' size as a share of ZeD's own (0.4 to 1; Multi-Slot: two thirds).
--   ctx.avail, ctx.cell, ctx.gap   the px across, ZeD's square and its gap; GL.colsAt(ctx, scale) is how many
--                    squares of that scale fit across (the provider's cols when nothing else sets them).
--   provider.dragShape(items, ctx) -> w, h, mask   (mask optional: the dragged shape as it lies now)
--   provider.canPlace(items, ctx, x, y, w, h, mask) the mask the ghost has, so holes may land over other cells
--   The ghost and the pad's place mode draw the shape's outline, not its box.
-- InventoryRenderer calls attach (a column's layout), draw (its cells), modelFolds (its model) and takeDrop (a
-- release); the windows read the spans (_itemRenderWMap / _itemRenderHMap) for the pad's focus rects, and
-- padButtons gives the cells their X hold. Kahlua: no next(), no goto, ASCII only, no tables made per frame.
-- ============================================================================

ZeD = ZeD or {}
ZeD.GridLayout = ZeD.GridLayout or {}
local GL = ZeD.GridLayout

GL.VERSION = 2   -- (raise it when the provider's contract changes; add-ons compare against it. 2: shaped cells)

-- (hoisted: the closures below capture these names when they are made, so they are declared first)
local _id, _prov = nil, nil      -- the provider's id and table
local _gen = 0                   -- goes up on register, unregister and dirty(nil): every layout is made anew
local _invGen, _invGenN = {}, 0  -- dirty(inv): a count per container, and how many containers are counted
local _serial = 0                -- every layout made gets the next number (the windows rebuild their pad stops on it)
local _logged = {}               -- "<id>:<call>" -> true once that call's error was logged
local NO_FOLD = {}               -- (the folds handed to the model while a provider is on: none)
local _pad = {}                  -- playerNum -> the pad's place mode, while X is held on a cell
GL._pad = _pad                   -- (read by the sims)

-- One line in the console the first time a provider call fails (not every frame after)
local function logOnce(call, err)
    local k = tostring(_id) .. ":" .. call
    if _logged[k] then return end
    _logged[k] = true
    print("ZeD.GridLayout: " .. tostring(_id) .. "." .. call .. " failed; ZeD falls back to its own grid: " .. tostring(err))
end
GL._logOnce = logOnce

-- ---------------------------------------------------------------------------
-- REGISTRY
-- ---------------------------------------------------------------------------
--- Registers the layout provider. id: the add-on's mod id. One provider is active; a second logs a line and wins.
--- Returns true when registered (false: no provider.layout function).
function GL.register(id, provider)
    if type(provider) ~= "table" or type(provider.layout) ~= "function" then
        print("ZeD.GridLayout.register(" .. tostring(id) .. "): the provider has no layout function; not registered")
        return false
    end
    if _prov and _id ~= id then
        print("ZeD.GridLayout: " .. tostring(id) .. " replaces " .. tostring(_id) .. " (one layout provider at a time)")
    end
    _id, _prov = id, provider
    _gen = _gen + 1          -- (every column makes its layout with the new provider)
    _logged = {}             -- (a new provider's errors are logged afresh)
    return true
end

--- Takes the provider away (only the one registered under id): the grid is ZeD's own again on the next frame.
function GL.unregister(id)
    if not _prov or _id ~= id then return end
    _id, _prov = nil, nil
    _gen = _gen + 1
    for k in pairs(_pad) do _pad[k] = nil end   -- (a place mode in progress ends: nothing to place with)
end

--- The provider, or nil.
function GL.active() return _prov end

--- Asks for a new layout of inv on its next frame (nil: of every container).
function GL.dirty(inv)
    if inv == nil then _gen = _gen + 1; return end
    if _invGen[inv] == nil then
        _invGenN = _invGenN + 1
        -- (containers come and go as the player walks: past 64 the counts start over, every layout anew)
        if _invGenN > 64 then
            _invGen, _invGenN = {}, 1
            _gen = _gen + 1
        end
    end
    _invGen[inv] = (_invGen[inv] or 0) + 1
end

-- ---------------------------------------------------------------------------
-- THE MODEL'S FOLDS
-- ---------------------------------------------------------------------------
--- The folds InventoryRenderer builds a column's model with: none while a provider is on and the column is a grid
--- (the provider is handed every thing; the folds are applied here, per category), else the column's own, untouched.
--- panel (optional): the column's panel; where its last layout of inv failed, ZeD's own grid keeps the folds too.
function GL.modelFolds(collapsed, inv, playerObj, panel)
    if not _prov or not inv then return collapsed end
    local c = panel and panel._zedGL and panel._zedGL[inv]
    if c and c.L == false then return collapsed end   -- (false: the provider's layout failed for it)
    local R = ZeD.InventoryRenderer
    local p = playerObj or getSpecificPlayer(0)
    if not R.isGridKey(R._containerKeyOf(inv, p), p) then return collapsed end
    return NO_FOLD
end

-- the folds as last seen equal the column's folds now (no table or string made: the copy is compared key by key)
local function foldsSame(now, copy)
    if not copy then return false end
    for k, v in pairs(now or NO_FOLD) do
        if (v and true or false) ~= (copy[k] or false) then return false end
    end
    for k in pairs(copy) do
        if not (now and now[k]) then return false end
    end
    return true
end

-- a copy of the folds that are set (made only when a layout is made)
local function foldsCopy(now)
    local c = {}
    for k, v in pairs(now or NO_FOLD) do if v then c[k] = true end end
    return c
end

-- ---------------------------------------------------------------------------
-- MAKING A LAYOUT (only when the cache below says so)
-- ---------------------------------------------------------------------------
-- a number from the provider, whole, at least lo (nil when it is not a number)
local function whole(v, lo)
    v = tonumber(v)
    if not v then return nil end
    v = math.floor(v)
    if lo and v < lo then v = lo end
    return v
end

-- The full type of a thing, for a cell's stack key (dragItems and the card read stk.key)
local function typeOf(item)
    local ok, t = pcall(function() return item:getFullType() end)
    return ok and t or tostring(item)
end

-- One cell of the provider's answer, checked: its rep and things must be things the column lists and in no other
-- cell yet. Returns the cell's rep (nil: left out). L.stacks[rep] is made as a stack: { rep, items, count, key }.
local function takeCell(L, c, listed, used)
    if type(c) ~= "table" then return nil end
    local rep = c.item
    if rep == nil or not listed[rep] or used[rep] then return nil end
    local items = { rep }   -- (the rep first: the card and the drag chip show it)
    used[rep] = true
    if type(c.items) == "table" then
        for _, it in ipairs(c.items) do
            if it ~= rep and listed[it] and not used[it] then
                used[it] = true
                items[#items + 1] = it
            end
        end
    end
    L.stacks[rep] = { rep = rep, items = items, count = #items, key = typeOf(rep) }
    return rep
end

-- ---------------------------------------------------------------------------
-- SHAPES (version 2): a mask is the table has[dy * w + dx] = true for each square of a w x h box (0-based)
-- ---------------------------------------------------------------------------
-- a square of the mask letters: X (or x, #)
local function isSq(ch) return ch == "X" or ch == "x" or ch == "#" end

--- A mask written row by row ("XXX/X../X..") as w, h, has; its empty rows and columns at the edges are trimmed.
--- nil for no squares, not a string, or wider or taller than 16.
function GL.parseMask(s)
    if type(s) ~= "string" then return nil end
    -- the rows, split by "/" by hand (no gmatch: Kahlua and empty captures, see the engine notes)
    local rows, at = {}, 1
    while true do
        local j = string.find(s, "/", at, true)
        if not j then rows[#rows + 1] = string.sub(s, at); break end
        rows[#rows + 1] = string.sub(s, at, j - 1)
        at = j + 1
    end
    local x0, y0, x1, y1 = 1000, 1000, -1, -1
    for y = 1, #rows do
        local r = rows[y]
        for x = 1, string.len(r) do
            if isSq(string.sub(r, x, x)) then
                if x < x0 then x0 = x end
                if x > x1 then x1 = x end
                if y < y0 then y0 = y end
                if y > y1 then y1 = y end
            end
        end
    end
    if x1 < 0 then return nil end
    local w, h = x1 - x0 + 1, y1 - y0 + 1
    if w > 16 or h > 16 then return nil end
    local has = {}
    for y = y0, y1 do
        local r = rows[y]
        for x = x0, x1 do
            if isSq(string.sub(r, x, x)) then has[(y - y0) * w + (x - x0)] = true end
        end
    end
    return w, h, has
end

-- a w x h block as a mask (every square)
local function fullMask(w, h)
    local has = {}
    for i = 0, w * h - 1 do has[i] = true end
    return has
end

--- The drawing of a mask, worked out once (at layout time, or once per drag turn), never per frame: px offsets from
--- the box's top left in flat lists of x, y, w, h. cell, gap: the squares' px; t: the outline's thickness.
---   fill   the squares             gaps   the gaps between two squares of the shape (and a corner where 3 meet)
---   edges  the outline: t px inside each side of the shape that has nothing beyond it
---   hits   fill and gaps together (the cell's click zones)
---   fx, fy the first square (top row, leftmost: the picture's); ix, iy the last (bottom row, rightmost: the
---          condition strip and the count); wx, wy, wroom the weight's square (the top row's run's last square
---          when the run is two or more, else the square under the first, below the picture) and the px the weight may take
function GL.geom(has, w, h, cell, gap, t)
    local step = cell + gap
    local function sq(dx, dy)
        if dx < 0 or dy < 0 or dx >= w or dy >= h then return false end
        return has[dy * w + dx] == true
    end
    -- the fine blocks: even i / j a square's column / row, odd a gap's
    local function F(i, j)
        if i < 0 or j < 0 or i > 2 * w - 2 or j > 2 * h - 2 then return false end
        local dx, dy = math.floor(i / 2), math.floor(j / 2)
        local oi, oj = i - dx * 2, j - dy * 2
        if oi == 0 and oj == 0 then return sq(dx, dy) end
        if oi == 1 and oj == 0 then return sq(dx, dy) and sq(dx + 1, dy) end
        if oi == 0 and oj == 1 then return sq(dx, dy) and sq(dx, dy + 1) end
        local n = (sq(dx, dy) and 1 or 0) + (sq(dx + 1, dy) and 1 or 0) + (sq(dx, dy + 1) and 1 or 0) + (sq(dx + 1, dy + 1) and 1 or 0)
        return n >= 3
    end
    local function bpos(i)
        local d = math.floor(i / 2)
        if i - d * 2 == 0 then return d * step, cell end
        return d * step + cell, gap
    end
    local g = { fill = {}, gaps = {}, edges = {}, hits = {}, n = 0, bw = w * cell + (w - 1) * gap, bh = h * cell + (h - 1) * gap, cell = cell }
    local function put(list, x, y, bw, bh)
        if bw <= 0 or bh <= 0 then return end
        list[#list + 1] = x; list[#list + 1] = y; list[#list + 1] = bw; list[#list + 1] = bh
    end
    for j = 0, 2 * h - 2 do
        for i = 0, 2 * w - 2 do
            if F(i, j) then
                local bx, bw = bpos(i)
                local by, bh = bpos(j)
                local isSquare = (i - math.floor(i / 2) * 2 == 0) and (j - math.floor(j / 2) * 2 == 0)
                if isSquare then put(g.fill, bx, by, bw, bh); g.n = g.n + 1 else put(g.gaps, bx, by, bw, bh) end
                put(g.hits, bx, by, bw, bh)
                if bw > 0 and bh > 0 then
                    -- a side with nothing beyond it: the outline, run on t into a block beside it along the side
                    -- (so a concave corner closes)
                    local xl = bx - (F(i - 1, j) and t or 0)
                    local xr = bx + bw + (F(i + 1, j) and t or 0)
                    local yt = by - (F(i, j - 1) and t or 0)
                    local yb = by + bh + (F(i, j + 1) and t or 0)
                    if not F(i, j - 1) then put(g.edges, xl, by, xr - xl, t) end
                    if not F(i, j + 1) then put(g.edges, xl, by + bh - t, xr - xl, t) end
                    if not F(i - 1, j) then put(g.edges, bx, yt, t, yb - yt) end
                    if not F(i + 1, j) then put(g.edges, bx + bw - t, yt, t, yb - yt) end
                end
            end
        end
    end
    -- the first square (top row, leftmost), its row's run, and the last square (bottom row, rightmost)
    local fx, fy, lx, ly = nil, nil, 0, 0
    for dy = 0, h - 1 do
        for dx = 0, w - 1 do
            if sq(dx, dy) then
                if fx == nil then fx, fy = dx, dy end
                lx, ly = dx, dy
            end
        end
    end
    fx, fy = fx or 0, fy or 0
    local run = 0
    while sq(fx + run, fy) do run = run + 1 end
    g.fx, g.fy, g.ix, g.iy = fx * step, fy * step, lx * step, ly * step
    if run >= 2 then
        g.wx, g.wy, g.wroom = (fx + run - 1) * step, fy * step, (run - 1) * step
    else
        -- (Nov 17 2026, the director, after seeing it with the icon: a one-wide shape's weight goes "below the icon",
        -- top right of the square under the first; a lone square keeps none, drawShapeCell)
        if sq(fx, fy + 1) then
            g.wx, g.wy, g.wroom = fx * step, (fy + 1) * step, cell
        else
            g.wx, g.wy, g.wroom = g.fx, g.fy, cell
        end
    end
    return g
end

-- may a mask (has, or every square when nil) of w x h sit with its top left on x, y of occ (cols across)
local function fits(occ, cols, x, y, w, h, has)
    if x < 0 or x + w > cols then return false end
    for dy = 0, h - 1 do
        for dx = 0, w - 1 do
            if (has == nil or has[dy * w + dx]) and occ[(y + dy) * cols + x + dx] then return false end
        end
    end
    return true
end

-- marks a placed cell's squares taken (has: its mask; nil: every square of its box)
local function mark(occ, cols, x, y, w, h, has)
    for dy = 0, h - 1 do
        for dx = 0, w - 1 do
            if has == nil or has[dy * w + dx] then occ[(y + dy) * cols + x + dx] = true end
        end
    end
end

-- the first free spot for a w x h cell (mask has, nil a block) in an occupancy table (occ[y * cols + x] = true),
-- row by row; marks it
local function firstFit(occ, cols, w, h, has)
    local y = 0
    while true do
        for x = 0, cols - w do
            if fits(occ, cols, x, y, w, h, has) then
                mark(occ, cols, x, y, w, h, has)
                return x, y
            end
        end
        y = y + 1
    end
end

--- How many squares of scale (a share of ZeD's own square) fit across a layout's ctx.
function GL.colsAt(ctx, scale)
    local gap = tonumber(ctx and ctx.gap) or 0
    local cell = math.max(4, math.floor((tonumber(ctx and ctx.cell) or 32) * (tonumber(scale) or 1)))
    return math.max(1, math.floor(((tonumber(ctx and ctx.avail) or cell) + gap) / (cell + gap)))
end

-- Squares into px: each cell's spot relative to the grid's left edge and the layout's top (px, py), its size (wmap,
-- hmap); rows of one-square strips (aside, overflow) wrap at cols. Returns the height used from top.
local function placeSquares(L, reps, top, oneSquare)
    local step = L.cell + L.gap
    local rows = 0
    for i, rep in ipairs(reps) do
        if oneSquare then
            L.sqx[rep], L.sqy[rep], L.sqw[rep], L.sqh[rep] = (i - 1) % L.cols, math.floor((i - 1) / L.cols), 1, 1
        end
        local x, y, w, h = L.sqx[rep], L.sqy[rep], L.sqw[rep], L.sqh[rep]
        L.px[rep] = x * step
        L.py[rep] = top + L.gap + y * step
        L.wmap[rep] = w * L.cell + (w - 1) * L.gap
        L.hmap[rep] = h * L.cell + (h - 1) * L.gap
        if y + h > rows then rows = y + h end
    end
    return rows
end

-- The grid cells of one grid placed: with an x and y as given (kept inside cols), the rest first-fit after them.
-- Returns the rows they use.
local function placeGrid(L, reps, given, fixedRows)
    local cols, occ, later = L.cols, {}, {}
    for _, rep in ipairs(reps) do
        local w = math.min(L.sqw[rep], cols)
        if w ~= L.sqw[rep] and L.has[rep] then
            -- (a shape wider than the grid: drawn as its box cut to the grid, every square, so it never breaks)
            L.has[rep], L.geo[rep] = nil, nil
        end
        L.sqw[rep] = w
        local g = given and given[rep]
        if g then
            local x = math.max(0, math.min(g.x, cols - w))
            L.sqx[rep], L.sqy[rep] = x, g.y
            mark(occ, cols, x, g.y, w, L.sqh[rep], L.has[rep])
        else
            later[#later + 1] = rep
        end
    end
    for _, rep in ipairs(later) do
        L.sqx[rep], L.sqy[rep] = firstFit(occ, cols, L.sqw[rep], L.sqh[rep], L.has[rep])
    end
    local rows = fixedRows or 0
    for _, rep in ipairs(reps) do
        if L.sqy[rep] + L.sqh[rep] > rows then rows = L.sqy[rep] + L.sqh[rep] end
    end
    return rows, occ
end

-- the cells in reading order (row by row, then left to right): the pad's list and shift-click ranges follow it
local function byPlace(L)
    return function(a, b)
        if L.sqy[a] ~= L.sqy[b] then return L.sqy[a] < L.sqy[b] end
        return L.sqx[a] < L.sqx[b]
    end
end

-- the height of a grid of rows squares, as InventoryRenderer's gridH (nothing for none)
local function rowsH(L, rows)
    if rows <= 0 then return 0 end
    return L.gap + rows * (L.cell + L.gap)
end

-- The provider's answer made into what the draw reads (L). M: the column's model; GV: its grid state; hh: a heading
-- row's height; avail: the px across for squares. Everything here is made once per layout, never per frame.
local function shape(res, ctx, M, GV, useGroups, collapsed, hh, avail)
    local L = { ctx = ctx, list = {}, stacks = {}, kind = {}, sqx = {}, sqy = {}, sqw = {}, sqh = {},
                px = {}, py = {}, wmap = {}, hmap = {}, empties = {}, heads = {}, has = {}, geo = {} }
    L.gap = GV.gap
    L.cols = whole(res.cols, 1) or ctx.cols
    L.cell = GV.cell
    -- (version 2: the provider's squares may be smaller than ZeD's own)
    local scale = tonumber(res.scale)
    if scale then
        scale = math.max(0.4, math.min(1, scale))
        L.cell = math.max(4, math.floor(GV.cell * scale))
    end
    if L.cols > ctx.cols or L.cols * (L.cell + L.gap) - L.gap > avail then
        -- (wider than the column: the squares shrink to fit, never a sideways scroll)
        L.cell = math.max(4, math.min(L.cell, math.floor((avail + L.gap) / L.cols) - L.gap))
    end
    L.shapes = res.shapes == true
    -- the picture in a shape's first square: ZeD's own picture size, less where the square is small
    L.isz = math.min(math.floor(GV.cell * 32 / 52), math.floor(L.cell * 0.8))
    L.flat = (res.flat == true) or not useGroups
    L.fixedRows = whole(res.rows, 1)
    L.headLine = res.headLine ~= nil and tostring(res.headLine) or nil
    local listed, used = {}, {}
    for _, it in ipairs(ctx.items) do listed[it] = true end
    -- the strips' cells and the grid's, checked
    local aside, grid, over, given = {}, {}, {}, {}
    for _, c in ipairs(type(res.aside) == "table" and res.aside or NO_FOLD) do
        local rep = takeCell(L, c, listed, used)
        if rep then aside[#aside + 1] = rep; L.kind[rep] = "aside" end
    end
    for _, c in ipairs(type(res.cells) == "table" and res.cells or NO_FOLD) do
        local rep = takeCell(L, c, listed, used)
        if rep then
            grid[#grid + 1] = rep
            L.kind[rep] = "grid"
            L.sqw[rep], L.sqh[rep] = whole(c.w, 1) or 1, whole(c.h, 1) or 1
            -- (version 2: a mask sets the cell's box and the squares in it)
            local mw, mh, has = GL.parseMask(c.mask)
            if mw then L.sqw[rep], L.sqh[rep], L.has[rep] = mw, mh, has end
            local x, y = whole(c.x, 0), whole(c.y, 0)
            if x and y then given[rep] = { x = x, y = y } end
        end
    end
    for _, c in ipairs(type(res.overflow) == "table" and res.overflow or NO_FOLD) do
        local rep = takeCell(L, c, listed, used)
        if rep then over[#over + 1] = rep; L.kind[rep] = "over" end
    end
    -- the safety net: a listed thing in no cell gets a square of its own, first free
    for _, it in ipairs(ctx.items) do
        if not used[it] then
            local rep = takeCell(L, { item = it }, listed, used)
            grid[#grid + 1] = rep
            L.kind[rep] = "grid"
            L.sqw[rep], L.sqh[rep] = 1, 1
        end
    end
    -- top to bottom: the aside strip, the grid (or a grid per category), the overflow strip
    local off = 0
    if #aside > 0 then
        L.asideHeadY, L.asideText = off, res.asideText ~= nil and tostring(res.asideText) or ""
        off = off + hh
        off = off + rowsH(L, placeSquares(L, aside, off, true))
        for _, rep in ipairs(aside) do L.list[#L.list + 1] = rep end
    end
    if L.flat then
        local rows, occ = placeGrid(L, grid, given, L.fixedRows)
        L.gridTop, L.rows = off, rows
        placeSquares(L, grid, off, false)
        table.sort(grid, byPlace(L))
        for _, rep in ipairs(grid) do L.list[#L.list + 1] = rep end
        if res.fixed == true then
            -- (the empty squares, as numbers y * cols + x: drawn as faint slots)
            for i = 0, rows * L.cols - 1 do if not occ[i] then L.empties[#L.empties + 1] = i end end
        end
        off = off + rowsH(L, rows)
    else
        -- sorted by category, not flat: a heading and a first-fit grid per category, ZeD's order; a fold hides its cells
        local byCat, order = {}, {}
        for _, cat in ipairs(M.catOrder or NO_FOLD) do byCat[cat] = {}; order[#order + 1] = cat end
        for _, rep in ipairs(grid) do
            local cat = (M.catOf and M.catOf[rep]) or ZeD.InventoryRenderer.catKey(rep)
            if not byCat[cat] then byCat[cat] = {}; order[#order + 1] = cat end
            local t = byCat[cat]
            t[#t + 1] = rep
        end
        for _, cat in ipairs(order) do
            local n = 0
            for _, rep in ipairs(byCat[cat]) do n = n + L.stacks[rep].count end
            local closed = collapsed and collapsed[cat] and true or false
            L.heads[#L.heads + 1] = { cat = cat, y = off, n = n, closed = closed }
            off = off + hh
            if not closed then
                local rows = placeGrid(L, byCat[cat], nil, nil)
                placeSquares(L, byCat[cat], off, false)
                table.sort(byCat[cat], byPlace(L))
                for _, rep in ipairs(byCat[cat]) do L.list[#L.list + 1] = rep end
                off = off + rowsH(L, rows)
            end
        end
    end
    if #over > 0 then
        L.ovHeadY, L.ovText = off, res.overflowText ~= nil and tostring(res.overflowText) or ""
        off = off + hh
        off = off + rowsH(L, placeSquares(L, over, off, true))
        for _, rep in ipairs(over) do L.list[#L.list + 1] = rep end
    end
    L.totalH = off
    -- (version 2: each shaped cell's drawing, worked out once here; the strips' cells are one square each)
    local t = (ZeD.T and ZeD.T.px) and math.max(1, ZeD.T.px(1)) or 1
    local one = nil
    for _, rep in ipairs(L.list) do
        local has = (L.kind[rep] == "grid") and L.has[rep] or nil
        if has or L.shapes then
            local w, h = L.sqw[rep], L.sqh[rep]
            if has then
                L.geo[rep] = GL.geom(has, w, h, L.cell, L.gap, t)
            elseif w == 1 and h == 1 then
                one = one or GL.geom(fullMask(1, 1), 1, 1, L.cell, L.gap, t)
                L.geo[rep] = one
            else
                L.geo[rep] = GL.geom(fullMask(w, h), w, h, L.cell, L.gap, t)
            end
        end
    end
    return L
end
GL._shape = shape

-- ---------------------------------------------------------------------------
-- A COLUMN'S LAYOUT (InventoryRenderer.renderItemList, every frame: kept until something it is made from changes)
-- ---------------------------------------------------------------------------
--- Sets GV.L to this column's layout (nil: ZeD's own grid) and, with one, the rows the rest of ZeD reads: the
--- panel's flat list, stacks, cell size, the spans (_itemRenderWMap / _itemRenderHMap) and the layout's number
--- (_gridLayoutGen). avail: the px across the squares take (the column less its padding and scroll bar).
function GL.attach(panel, GV, M, inv, playerObj, useGroups, hh, avail)
    if not (_prov and GV.on and inv and M) then
        GV.L = nil
        if panel._gridLayoutGen ~= nil then
            panel._gridLayoutGen, panel._itemRenderWMap, panel._itemRenderHMap = nil, nil, nil
        end
        return
    end
    local cache = panel._zedGL
    if not cache then
        cache = {}
        panel._zedGL, panel._zedGLN = cache, 0
    end
    local c = cache[inv]
    if not c then
        -- (containers come and go as the player walks: start over past 24, as the model's cache does)
        panel._zedGLN = panel._zedGLN + 1
        if panel._zedGLN > 24 then
            cache = {}
            panel._zedGL, panel._zedGLN = cache, 1
        end
        c = {}
        cache[inv] = c
    end
    local collapsed = panel._collapsedGroups
    -- kept: the same model, provider, dirty count, size, text size and (sorted by category) the same folds
    if not (c.L ~= nil and c.m == M and c.gen == _gen and c.ig == (_invGen[inv] or 0) and c.cols == GV.cols
            and c.cell == GV.cell and c.avail == avail and c.hh == hh and c.ug == useGroups
            and (not useGroups or foldsSame(collapsed, c.folds))) then
        c.m, c.gen, c.ig, c.cols, c.cell, c.avail, c.hh, c.ug = M, _gen, (_invGen[inv] or 0), GV.cols, GV.cell, avail, hh, useGroups
        c.folds = useGroups and foldsCopy(collapsed) or nil
        -- every thing the column lists, one entry each (a stack's things in its order)
        local items = {}
        for _, rep in ipairs(M.flatItems or NO_FOLD) do
            local s = M.stacks and M.stacks[rep]
            if s and s.items then
                for _, it in ipairs(s.items) do items[#items + 1] = it end
            else
                items[#items + 1] = rep
            end
        end
        local ctx = { inv = inv, player = playerObj, key = GV.key, cols = GV.cols, items = items, stacks = M.stacks or {},
                      avail = avail, cell = GV.cell, gap = GV.gap }   -- (avail, cell, gap: version 2, GL.colsAt)
        local ok, res = pcall(_prov.layout, ctx)
        if ok and type(res) ~= "table" then ok, res = false, "layout returned " .. type(res) end
        if ok then
            local okS, L = pcall(shape, res, ctx, M, GV, useGroups, collapsed, hh, avail)
            if okS then
                _serial = _serial + 1
                L.serial = _serial
                c.L = L
            else
                logOnce("layout (its answer)", L)
                c.L = false
            end
        else
            logOnce("layout", res)
            c.L = false   -- (false: ZeD's own grid until the next rebuild)
        end
    end
    local L = c.L or nil
    GV.L = L
    if not L then
        if panel._gridLayoutGen ~= nil then
            panel._gridLayoutGen, panel._itemRenderWMap, panel._itemRenderHMap = nil, nil, nil
        end
        return
    end
    GV.cols, GV.cell = L.cols, L.cell
    panel._gridCell = L.cell
    panel._flatItems, panel._invRowItems, panel._stacks = L.list, L.list, L.stacks
    panel._itemRenderWMap, panel._itemRenderHMap, panel._gridLayoutGen = L.wmap, L.hmap, L.serial
end

--- The layout a panel's column of inv is drawn with now (nil: none).
function GL.layoutOf(panel, inv)
    local c = panel and inv and panel._zedGL and panel._zedGL[inv]
    return c and c.L or nil
end

-- ---------------------------------------------------------------------------
-- THE MOUSE'S DRAG
-- ---------------------------------------------------------------------------
-- The over-state: the single grid the pointer is over while a ZeD drag is on (stamped at each draw), so the drop,
-- the wheel and R know where. One table, filled in place.
local O = { at = 0, panel = nil, L = nil, inv = nil, x = 0, y = 0, w = 1, h = 1, ok = true, reason = nil,
            keepUntil = 0, keepPanel = nil, keepReason = nil }
GL._over = O
local FRESH_MS = 250    -- (the over-state counts this long after the last draw that stamped it)
local KEEP_MS = 2500    -- (a refused drop's reason stays on that list's help line this long)
-- the dragged things and their shape, made once per drag and turn (not per frame)
local D = { rows = nil, carried = nil, turn = 0, shapeFor = nil, shapeTurn = -1, shapeL = nil, w = 1, h = 1,
            mask = nil, geo = nil,
            askL = nil, askX = -1, askY = -1, askW = 0, askH = 0, askTurn = -1, askRows = nil }

-- a dragged shape from the provider's dragShape answer, on layout L: w, h (kept inside the grid's columns), the
-- mask words (nil: a block) and the ghost's drawing (nil: the box's frame). Made once per drag, turn and grid.
local function shapeFrom(L, w, h, mask)
    w, h = whole(w, 1) or 1, whole(h, 1) or 1
    local mw, mh, has = GL.parseMask(mask)
    if mw then w, h = mw, mh else mask = nil end
    if w > L.cols then w, mask, has = L.cols, nil, nil end
    local geo = nil
    if has then
        local t = (ZeD.T and ZeD.T.px) and math.max(1, ZeD.T.px(2)) or 2
        geo = GL.geom(has, w, h, L.cell, L.gap, t)
    end
    return w, h, mask, geo
end

--- The ZeD list a mouse drag is on for player pn: its content panel and its drag state, or nil.
-- the list of window W (a window module) for pn, when a drag is on in it
local function dragIn(W, pn)
    local w = W and W.getWindow and W.getWindow(pn)
    local c = w and w._contentPanel
    if c and c._drag and c._drag.isActive and c._drag:isActive() then return c end
    return nil
end
function GL.mouseDrag(pn)
    local c = dragIn(ZeD_CharacterWindow, pn) or dragIn(ZeD_WorldWindow, pn)
    if c then return c, c._drag end
    return nil
end

-- the things a drag carries (a stack's row is its whole stack), worked out once per drag
local function carriedOf(content, drag)
    if D.rows ~= drag.items then
        D.rows = drag.items
        D.carried = ZeD.InventoryRenderer.dragItems(content, drag.items or {}, content._dragSourceInv)
        D.turn = 0
    end
    return D.carried
end

-- the dragged things' shape on layout L (asked of the provider once per drag, turn and grid)
local function dragShape(items, L)
    if D.shapeFor == items and D.shapeTurn == D.turn and D.shapeL == L then return D.w, D.h end
    D.shapeFor, D.shapeTurn, D.shapeL = items, D.turn, L
    D.w, D.h, D.mask, D.geo = 1, 1, nil, nil
    if _prov and _prov.dragShape then
        local ok, w, h, mask = pcall(_prov.dragShape, items, L.ctx)
        if ok then D.w, D.h, D.mask, D.geo = shapeFrom(L, w, h, mask)
        else logOnce("dragShape", w) end
    end
    return D.w, D.h
end

-- may items land with their top-left on x, y of layout L: the provider's canPlace, then (into another container)
-- the add-ons' rules (ItemRules). Returns ok, reason. mask: the dragged shape's words (version 2; nil a block).
local function askPlace(items, L, x, y, w, h, src, mask)
    local ok, reason = true, nil
    if _prov and _prov.canPlace then
        local okC, yes, why = pcall(_prov.canPlace, items, L.ctx, x, y, w, h, mask)
        if okC then
            if yes == false then ok, reason = false, why ~= nil and tostring(why) or nil end
        else
            logOnce("canPlace", yes)
        end
    end
    if ok and src ~= L.ctx.inv and ZeD.ItemRules then
        ok, reason = ZeD.ItemRules.checkAll(items, L.ctx.inv, L.ctx.player, src)
    end
    return ok, reason
end
GL._askPlace = askPlace

-- the top-left square of a w x h footprint centered on square sx, sy, kept inside the grid's columns (and its rows,
-- when the provider fixed them)
local function clampSpot(L, sx, sy, w, h)
    local x = math.max(0, math.min(sx - math.floor((w - 1) / 2), L.cols - w))
    local y = math.max(0, sy - math.floor((h - 1) / 2))
    if L.fixedRows then y = math.max(0, math.min(y, L.fixedRows - h)) end
    return x, y
end

-- the ghost: the footprint's edge in the status colour (2 units), over the cells; a shape (geo, version 2) draws
-- its own outline, not its box
local function drawGhost(panel, GV, L, gy, x, y, w, h, ok, geo)
    local T = ZeD.T
    local step = L.cell + L.gap
    local c = ok and T.positive or T.danger
    local gx, gy2 = GV.xOff + GV.padX + x * step, gy + L.gap + y * step
    if geo and geo.cell == L.cell then
        local e = geo.edges
        for k = 1, #e, 4 do panel:drawRect(gx + e[k], gy2 + e[k + 1], e[k + 2], e[k + 3], c.a or 1, c.r, c.g, c.b) end
        return
    end
    ZeD.Atoms.frame(panel, gx, gy2, w * L.cell + (w - 1) * L.gap, h * L.cell + (h - 1) * L.gap, c, nil, T.px(2))
end

-- A mouse drag over this column's single grid (y0: where the layout starts): the ghost, the reason on the help line,
-- and the over-state stamped for the drop. Nothing when no drag is on or the pointer is elsewhere.
local function mouseOver(panel, GV, L, y0)
    if not GV.mouseIn then return end
    local content, drag = GL.mouseDrag(ZeD.playerNumOf(panel))
    if not content then return end
    local step = L.cell + L.gap
    local gy = y0 + L.gridTop
    local lx, ly = GV.lmx - GV.padX, GV.my - gy - L.gap
    if lx < 0 or lx >= L.cols * step or ly < 0 or GV.my < GV.top then
        if O.panel == panel and O.L == L then O.at = 0 end   -- (off the grid: a release here is ZeD's usual drop)
        return
    end
    local items = carriedOf(content, drag)
    local w, h = dragShape(items, L)
    local x, y = clampSpot(L, math.floor(lx / step), math.floor(ly / step), w, h)
    local src = content._dragSourceInv
    -- (asked again only when the spot, the shape or the grid changes)
    if not (D.askL == L and D.askX == x and D.askY == y and D.askW == w and D.askH == h and D.askTurn == D.turn
            and D.askRows == items) then
        D.askL, D.askX, D.askY, D.askW, D.askH, D.askTurn, D.askRows = L, x, y, w, h, D.turn, items
        O.ok, O.reason = askPlace(items, L, x, y, w, h, src, D.mask)
    end
    O.at, O.panel, O.L, O.inv, O.x, O.y, O.w, O.h, O.items = getTimestampMs(), panel, L, L.ctx.inv, x, y, w, h, items
    drawGhost(panel, GV, L, gy, x, y, w, h, O.ok, D.geo)
    if O.reason then ZeD.Help.set(panel, O.reason) end
end

-- the over-state is this frame's (or the last few frames')
local function overFresh()
    return O.panel ~= nil and getTimestampMs() - O.at < FRESH_MS
end

--- Turns the dragged thing while a mouse drag is over a provider's grid (the windows' mouse wheel, and R). True when
--- it turned (the wheel then scrolls nothing).
function GL.dragTurn()
    if not (_prov and overFresh() and O.items) then return false end
    if _prov.turn then
        local ok, err = pcall(_prov.turn, O.items, O.L.ctx)
        if not ok then logOnce("turn", err) end
    end
    D.turn = D.turn + 1   -- (dragShape and canPlace are asked anew on the next frame)
    return true
end

--- A ZeD list's release (InventoryRenderer.handleDrop, the World window's floor drops): over a provider's grid,
--- drop goes first. True when the drop ends here: the place was refused (nothing moves; the reason stays on that
--- list's help line a moment) or the things stay in the one container. False: ZeD makes its usual move.
function GL.takeDrop(content, items, srcInv)
    if not (_prov and overFresh()) then return false end
    O.at = 0   -- (used once: a second call for the same release finds nothing)
    local L = O.L
    if not O.ok then
        O.keepUntil, O.keepPanel, O.keepReason = getTimestampMs() + KEEP_MS, O.panel, O.reason
        return true
    end
    if _prov.drop then
        local ok, err = pcall(_prov.drop, items, L.ctx, O.x, O.y, srcInv)
        if not ok then logOnce("drop", err) end
    end
    GL.dirty(L.ctx.inv)
    if srcInv ~= nil and srcInv == L.ctx.inv then return true end   -- (the same container: the add-on re-placed it)
    return false
end

-- R during a mouse drag over a provider's grid turns it (the wheel is the windows' own call, GL.dragTurn)
local function onKey(key)
    if Keyboard and key == Keyboard.KEY_R then GL.dragTurn() end
end
if Events and Events.OnKeyPressed then Events.OnKeyPressed.Add(onKey) end

-- ---------------------------------------------------------------------------
-- THE PAD'S PLACE MODE (hold X on a cell of a single grid)
-- ---------------------------------------------------------------------------
-- the column a pad element is in: its content panel, its column number (nil: the one list) and its container
local function padColumn(w, el)
    local cnt = w and w._mainContent
    if not (cnt and el and el.item) then return nil end
    local inv = el.item:getContainer()
    return cnt, el.colIdx or el.mcSlot, inv
end

--- May X held on el start place mode (FocusManager asks, holdDragIf): a provider, a single grid, el one of its cells.
function GL.padCan(w, el)
    if not _prov then return false end
    -- (guarded: FocusManager asks this inside its tick; a thing gone from the world must not stop the pad)
    local ok, yes = pcall(function()
        local cnt, _, inv = padColumn(w, el)
        local L = cnt and GL.layoutOf(cnt, inv)
        return (L and L.flat and L.kind[el.item] ~= nil) and true or false
    end)
    return ok and yes or false
end

-- the place mode's footprint asked anew (its shape after a turn, kept inside the grid, then canPlace)
local function padAsk(S)
    local L = S.L
    S.w, S.h, S.mask, S.geo = 1, 1, nil, nil
    if _prov.dragShape then
        local ok, w, h, mask = pcall(_prov.dragShape, S.items, L.ctx)
        if ok then S.w, S.h, S.mask, S.geo = shapeFrom(L, w, h, mask) else logOnce("dragShape", w) end
    end
    S.x = math.max(0, math.min(S.x, L.cols - S.w))
    S.y = math.max(0, S.y)
    if L.fixedRows then S.y = math.max(0, math.min(S.y, L.fixedRows - S.h)) end
    S.ok, S.reason = askPlace(S.items, L, S.x, S.y, S.w, S.h, S.src, S.mask)
end

-- the layout of the column beside S's (dir -1 left, +1 right) in a side-by-side view, with its container
local function padNeighbour(S, dir)
    local cs = S.col and S.cnt._colStates and S.cnt._colStates[S.col + dir]
    local L = cs and GL.layoutOf(S.cnt, cs.inventory)
    if L and L.flat then return L, S.col + dir end
    return nil
end

--- X held on a cell (FocusManager's onHoldContextDrag): dir nil starts place mode at the cell's own square; a
--- D-pad dir moves the ghost one square (off the column's side onto the next column's grid, the same row).
function GL.padDrag(w, el, dir)
    local pn = ZeD.playerNumOf(w)
    if dir == nil then
        local cnt, col, inv = padColumn(w, el)
        local L = cnt and GL.layoutOf(cnt, inv)
        if not (_prov and L and L.flat and L.kind[el.item]) then return end
        local stk = L.stacks[el.item]
        local onGrid = L.kind[el.item] == "grid"
        local S = { win = w, cnt = cnt, col = col, L = L, src = inv, rep = el.item, items = stk and stk.items or { el.item },
                    x = onGrid and L.sqx[el.item] or 0, y = onGrid and L.sqy[el.item] or 0 }
        _pad[pn] = S
        padAsk(S)
        return
    end
    local S = _pad[pn]
    if not S then return end
    if dir == "up" then S.y = S.y - 1
    elseif dir == "down" then S.y = S.y + 1
    elseif dir == "left" or dir == "right" then
        local d = (dir == "left") and -1 or 1
        local nx = S.x + d
        if nx < 0 or nx + S.w > S.L.cols then
            -- off the column's side: the next column's grid, the same row; else it stays at the edge
            local L2, col2 = padNeighbour(S, d)
            if L2 then
                S.L, S.col = L2, col2
                nx = (d < 0) and (L2.cols - S.w) or 0
            else
                nx = S.x
            end
        end
        S.x = nx
    end
    padAsk(S)
end

--- The column keeps the place mode's ghost in view (InventoryRenderer's renderItemList, beside its scroll-follow
--- for the focused row; Nov 15 2026, add-on hooks: the add-on's first run found the ghost scrolled away below a long
--- list). As the row's follow, it pins only when the ghost has moved (or place mode has just started), so a
--- wheel scrolled past it is not pulled back. top: the rows' top on screen; totalH / visH: the list's and the
--- view's heights. Works from where the grid drew last frame (S.gridY), as the row's follow does.
function GL.followPad(panel, inv, scroll, totalH, visH, top)
    local S = _pad[ZeD.playerNumOf(panel)]
    if not (S and S.cnt == panel and S.gridY and S.drawnL == S.L and S.L.ctx.inv == inv) then return end
    if not (scroll and totalH > visH) then return end
    if S.pinX == S.x and S.pinY == S.y and S.pinL == S.L then return end
    S.pinX, S.pinY, S.pinL = S.x, S.y, S.L
    local L = S.L
    local span = totalH - visH
    local old = math.floor(scroll.scrollPos * span)
    -- the ghost's top in the list's own space (screen y less the rows' top, plus the scroll it was drawn at)
    local gy = S.gridY - top + old + S.y * (L.cell + L.gap)
    local gh = S.h * L.cell + (S.h - 1) * L.gap
    if gy < old then scroll:setScrollPos(math.max(0, gy) / span)
    elseif gy + gh > old + visH then scroll:setScrollPos(math.min(span, gy + gh - visH) / span) end
end

-- the place mode ends: B, a release, a provider gone
local function padEnd(pn) _pad[pn] = nil end
--- Ends pn's place mode without placing (FocusManager: the hold was dropped, the mouse took over or the pad went).
function GL.padCancel(pn) padEnd(pn) end

--- X let go (FocusManager's onHoldContextRelease): the ghost's square. Allowed: drop, then ZeD's move when the
--- container differs (ContainerControls, with its rules). Refused: nothing moves and the reason shows over the head.
function GL.padRelease(w, el)
    local pn = ZeD.playerNumOf(w)
    local S = _pad[pn]
    if not S then return end
    padEnd(pn)
    local L, dest = S.L, S.L.ctx.inv
    if not S.ok then
        if S.reason and ZeD.Bubbles and ZeD.Bubbles.note then pcall(ZeD.Bubbles.note, pn, S.reason, "bad") end
        return
    end
    if _prov and _prov.drop then
        local ok, err = pcall(_prov.drop, S.items, L.ctx, S.x, S.y, S.src)
        if not ok then logOnce("drop", err) end
    end
    GL.dirty(dest)
    if ZeD.InventoryRenderer.dirtyModels then ZeD.InventoryRenderer.dirtyModels() end
    if dest == S.src then return end
    local CT = ZeD.ContainerControls
    local player = S.cnt._playerObj
    if not (CT and player) then return end
    -- (out of the world: the game's grab walks to the container first; from the character's own things: the move)
    local okO, inChar = pcall(function() return S.src:isInCharacterInventory(player) end)
    local own = S.src == player:getInventory() or (okO and inChar)
    if own then CT.moveItems(player, S.items, dest) else CT.grabItems(player, S.items, dest) end
end

--- A pad button while place mode is on (FocusManager, before its own handling): A turns, B cancels. True when taken.
function GL.padButton(pn, button)
    local S = _pad[pn]
    if not S or not Joypad then return false end
    if button == Joypad.AButton then
        if _prov and _prov.turn then
            local ok, err = pcall(_prov.turn, S.items, S.L.ctx)
            if not ok then logOnce("turn", err) end
        end
        padAsk(S)
        return true
    elseif button == Joypad.BButton then
        padEnd(pn)
        return true
    end
    return false
end

-- the help line's prompts while place mode is on (made once; the words read through ZeD.tr when made)
local _prompts = nil
local _promptsGen = -1
--- The prompts in place of the focused cell's while place mode is on for pn (nil: none on).
function GL.padPrompts(pn)
    if not _pad[pn] then return nil end
    if not _prompts or _promptsGen ~= ZeD._trGen then
        _promptsGen = ZeD._trGen
        _prompts = {
            { glyph = "D-PAD", label = ZeD.tr("UI_ZeD_Inv_PromptMove") },
            { glyph = "A", label = ZeD.tr("UI_ZeD_Looks_PromptTurn") },
            { glyph = "X", label = ZeD.tr("UI_ZeD_Grid_PromptPlace") },
            { glyph = "B", label = getText("UI_Cancel") },
        }
    end
    return _prompts
end

--- Gives an item cell's pad element the X hold of place mode (InventoryRenderer.padItemButtons). Only while a
--- provider is on: FocusManager asks holdDragIf at the hold, and where it says no the X hold stays the quick use.
function GL.padButtons(el)
    if not _prov then return el end
    el.onHoldContextDrag = GL.padDrag
    el.onHoldContextRelease = GL.padRelease
    el.holdDragIf = GL.padCan
    return el
end

-- ---------------------------------------------------------------------------
-- DRAWING (InventoryRenderer.renderItemList, a grid column with a layout)
-- ---------------------------------------------------------------------------
-- a strip's heading row (aside: the list's dim words; overflow: the warning mark and words in the warning colour)
local function stripHead(panel, GV, y, hh, text, warn)
    if y + hh <= GV.top or y >= GV.h then return end
    local T = ZeD.T
    local x = GV.xOff + GV.padX
    local f = T.fontF1
    local ty = y + math.floor((hh - ZeD.TM:getFontHeight(f)) / 2)
    local c = T.toneNorm or T.text
    if warn then
        local sz = T.px(7)
        ZeD.Atoms.drawStatusDot(panel, x, y + math.floor((hh - sz) / 2), T.warning, sz)
        x = x + sz + T.px(4)
        c = T.warning
    end
    panel:drawText(text, x, ty, c.r, c.g, c.b, c.a or 1, f)
end

--- Draws a column's layout from y0 (scrolled): headings, empty slots, the cells (InventoryRenderer's own
--- drawGridCell on each span), the add-on's marks, then the drag's and the pad's ghosts. Returns the y after it.
function GL.draw(panel, GV, y0, scrollX, hh)
    local L = GV.L
    local R = ZeD.InventoryRenderer
    local T = ZeD.T
    if L.asideHeadY then stripHead(panel, GV, y0 + L.asideHeadY, hh, L.asideText, false) end
    for i = 1, #L.heads do
        local hd = L.heads[i]
        local y = y0 + hd.y
        if GV.ymap then GV.ymap["cat:" .. hd.cat] = y end   -- (the heading's place: its pad stop, punch list 256)
        if y + hh > GV.top and y < GV.h then
            local hover = GV.mouseIn and GV.my >= y and GV.my < y + hh and GV.lmx < scrollX
            R._drawCatRow(panel, GV.xOff, y, scrollX, hh, hd.cat, hd.n, hd.closed, hover, GV.padX + T.px(2))
            panel:addHitZone("cat:" .. hd.cat, GV.xOff, y, scrollX, hh)
        end
    end
    if L.ovHeadY then stripHead(panel, GV, y0 + L.ovHeadY, hh, L.ovText, true) end
    local step = L.cell + L.gap
    if #L.empties > 0 then
        local gy = y0 + L.gridTop + L.gap
        local bc = T.border or T.borderS
        for i = 1, #L.empties do
            local n = L.empties[i]
            local sy = gy + math.floor(n / L.cols) * step
            if sy + L.cell > GV.top and sy < GV.h then
                ZeD.Atoms.frame(panel, GV.xOff + GV.padX + (n % L.cols) * step, sy, L.cell, L.cell, bc)
            end
        end
    end
    local dec = _prov and _prov.decorate
    for i = 1, #L.list do
        local rep = L.list[i]
        local cx, cy, w, h = GV.padX + L.px[rep], y0 + L.py[rep], L.wmap[rep], L.hmap[rep]
        R._drawGridCell(panel, GV, rep, cx, cy, w, h, L.geo[rep])   -- (geo: a shape, version 2; nil a span)
        if dec and cy + h > GV.top and cy < GV.h then
            local ok, err = pcall(dec, panel, rep, GV.xOff + cx, cy, w, h)
            if not ok then logOnce("decorate", err); dec = nil end
        end
    end
    if L.flat then
        mouseOver(panel, GV, L, y0)
        -- the pad's place mode on this column: its ghost and its reason
        local S = _pad[ZeD.playerNumOf(panel)]
        if S and S.cnt == panel and S.L.ctx.inv == L.ctx.inv then
            -- (the layout is made anew as the model rebuilds, about once a second: place mode follows the new one,
            -- so its drop and canPlace get the add-on's current ctx)
            if S.L ~= L then
                S.L = L
                if S.geo and S.geo.cell ~= L.cell then padAsk(S) end   -- (the squares changed size: the ghost anew)
            end
            drawGhost(panel, GV, L, y0 + L.gridTop, S.x, S.y, S.w, S.h, S.ok, S.geo)
            -- (where this layout's grid starts on screen this frame, for GL.followPad's scroll on the next one)
            S.gridY, S.drawnL = y0 + L.gridTop + L.gap, L
            if S.reason then ZeD.Help.set(panel, S.reason) end
        end
    end
    -- a refused drop's reason stays a moment on that list's help line
    if O.keepPanel == panel and O.keepReason and getTimestampMs() < O.keepUntil then ZeD.Help.set(panel, O.keepReason) end
    return y0 + L.totalH
end
