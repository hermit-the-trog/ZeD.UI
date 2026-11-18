-- ZeDUI/tools/qa/rt_addon.lua  (Nov 18 2026, QA): the release test's add-on hooks (RELEASE_TEST.md, row rt_addon.lua).
-- Built on rt_kit.lua (the global RT). grep "ZEDQA rt_addon".
-- A stand-in provider for ZeD's grid layout hook (GridLayout.lua, version 2) is registered for the run, the
-- character's own inventory is shown as a grid in the Character window, and the draw itself is read for one frame
-- (the content panel's drawRect / drawRectBorder / drawText / drawTextureScaledAspect, attributed to each cell through
-- ZeD.InventoryRenderer._drawGridCell, the entry GridLayout.draw calls for every cell):
--   * the provider's answer is taken: its scale sets the squares, its masks set the cells (an "L" of three squares
--     around a hole, a bar of three), the stack cell counts its things;
--   * a shaped cell is drawn as its shape: nothing of it is drawn in its hole and none of its click zones is there,
--     and each of its squares is clickable;
--   * the picture and every label (the weight, the count "(3)", the condition strip) sit on the cell's FIRST square
--     (the top row's leftmost), nothing else is drawn outside the shape's own squares and lines;
--   * the pad's place mode (GridLayout.padDrag, what X held on a cell runs) carries the mask, and its ghost is drawn
--     as the mask's outline, not its box;
--   * unregistered at the end: the hook is empty and the grid is ZeD's own again.
-- Things given (three apples, a hammer at half condition) are taken back; the bag's view is put back as found.
-- A save where another add-on's provider is on (Multi-Slot) SKIPs: GridLayout keeps the active provider's id to
-- itself, so the stand-in could not hand it back.
local Q = RT.make("rt_addon")
local pn = RT.pn
local T = ZeD.T
local GL = ZeD.GridLayout
local R = ZeD.InventoryRenderer
local ID = "zedqa_rt_addon_standin"
local SCALE = 0.9
local MASK_A, MASK_B = "XX/X.", "X/X/X"     -- A: squares (0,0) (1,0) (0,1), a hole at (1,1); B: a bar of three, down
local S = { rec = {}, ghost = {}, calls = 0, on = false }

-- ===================================================================== the stand-in provider
local P = {}
function P.layout(ctx)
    S.calls = S.calls + 1
    S.ctx = ctx
    if ctx.inv ~= S.inv or not S.apples then return { cells = {} } end
    local cols = ctx.cols or 1
    local cells = {}
    local listed = {}
    for _, it in ipairs(ctx.items or {}) do listed[it] = true end
    if listed[S.apples[1]] then
        cells[#cells + 1] = { item = S.apples[1], items = { S.apples[1], S.apples[2], S.apples[3] }, x = 0, y = 0, mask = MASK_A }
    end
    if S.hammer and listed[S.hammer] then
        if cols >= 3 then cells[#cells + 1] = { item = S.hammer, x = 2, y = 0, mask = MASK_B }
        else cells[#cells + 1] = { item = S.hammer, x = 0, y = 2, mask = MASK_B } end
    end
    return { cells = cells, shapes = true, scale = SCALE, flat = true }
end
function P.dragShape(items, ctx)
    if items and items[1] == S.hammer then return 1, 3, MASK_B end
    return 2, 2, MASK_A
end
function P.canPlace(items, ctx, x, y, w, h, mask) return true end
function P.drop(items, ctx, x, y, srcInv) S.dropped = true; return true end

-- ===================================================================== helpers
local function cnt() local w = RT.cw(); return w and w._mainContent end
local function within(x, y, w, h, b, slack)
    return x >= b.x - slack and y >= b.y - slack and x + w <= b.x + b.w + slack and y + h <= b.y + b.h + slack
end
local function hits(x, y, w, h, b)   -- does the rect touch b's inside (1 px in from each side)
    return x < b.x + b.w - 1 and x + w > b.x + 1 and y < b.y + b.h - 1 and y + h > b.y + 1
end
-- the geo's own rects (the squares, the lines between them, the outline; the hover and selection paint the hits)
local function isGeoRect(r, g, ax, cy)
    for _, list in ipairs({ g.fill, g.gaps, g.edges, g.hits }) do
        for k = 1, #list, 4 do
            if math.abs(r.x - (ax + list[k])) < 0.5 and math.abs(r.y - (cy + list[k + 1])) < 0.5
               and math.abs(r.w - list[k + 2]) < 0.5 and math.abs(r.h - list[k + 3]) < 0.5 then return true end
        end
    end
    return false
end
local function sameColor(c, r, g, b) return c ~= nil and math.abs(c.r - r) < 0.002 and math.abs(c.g - g) < 0.002 and math.abs(c.b - b) < 0.002 end

-- one frame's draws read: the panel's draw calls, put under the cell being drawn (S.cur), or (outside every cell) the
-- ghost's colors only
local WRAP = { "drawRect", "drawRectBorder", "drawText", "drawTextureScaledAspect" }
local function record(kind, x, y, w, h, text, r, g, b)
    local e = { kind = kind, x = x, y = y, w = w, h = h, text = text }
    if S.cur then
        local L = S.rec[S.cur]
        if L then L.calls[#L.calls + 1] = e end
    elseif kind == "rect" and S.ghostOn and (sameColor(T.positive, r, g, b) or sameColor(T.danger, r, g, b)) then
        S.ghost[#S.ghost + 1] = e
    end
end
local function wrapOn()
    local c = cnt()
    if not c or S.on then return false end
    S.panel = c
    S.own = {}
    for _, m in ipairs(WRAP) do S.own[m] = rawget(c, m) end
    local dR, dB, dT, dX = c.drawRect, c.drawRectBorder, c.drawText, c.drawTextureScaledAspect
    c.drawRect = function(self, x, y, w, h, a, r, g, b) record("rect", x, y, w, h, nil, r, g, b); return dR(self, x, y, w, h, a, r, g, b) end
    c.drawRectBorder = function(self, x, y, w, h, a, r, g, b) record("rect", x, y, w, h, nil, r, g, b); return dB(self, x, y, w, h, a, r, g, b) end
    c.drawText = function(self, s, x, y, r, g, b, a, f) record("text", x, y, 0, 0, s); return dT(self, s, x, y, r, g, b, a, f) end
    c.drawTextureScaledAspect = function(self, tex, x, y, w, h, a, r, g, b) record("tex", x, y, w, h); return dX(self, tex, x, y, w, h, a, r, g, b) end
    S.origCell = R._drawGridCell
    local orig = S.origCell
    R._drawGridCell = function(panel, GV, item, cx, cy, w, h, geo)
        local mine = panel == S.panel and (item == S.repA or item == S.repB)
        if mine then
            S.rec[item] = { calls = {}, ax = GV.xOff + cx, cy = cy, geo = geo, gap = GV.gap, zedCell = GV.zedCell, cell = GV.cell }
            S.cur = item
        end
        local ok, e = pcall(orig, panel, GV, item, cx, cy, w, h, geo)
        if mine then S.cur = nil end
        if not ok then error(e) end
    end
    S.on = true
    return true
end
local function wrapOff()
    if not S.on then return end
    S.on = false
    if S.origCell then R._drawGridCell = S.origCell end
    local c = S.panel
    if c then for _, m in ipairs(WRAP) do c[m] = S.own[m] end end
    S.cur = nil
end

-- the first square, and the square (dx, dy) of a recorded cell, in the panel's px
local function square(rec, dx, dy)
    local sq = rec.geo.cell
    local step = sq + rec.gap
    return { x = rec.ax + dx * step, y = rec.cy + dy * step, w = sq, h = sq }
end
local function firstSquare(rec) local g = rec.geo; return { x = rec.ax + g.fx, y = rec.cy + g.fy, w = g.cell, h = g.cell } end

-- the labels of a recorded cell: every draw that is not the shape's own squares and lines must sit on its first
-- square. Returns the count of stray draws (and the first one, said), the texts drawn, the picture's draws, the
-- rects in the lower half of the first square (the condition strip)
local function labels(rec)
    local fsq = firstSquare(rec)
    local stray, first = 0, nil
    local texts, pics, low = {}, 0, 0
    for _, e in ipairs(rec.calls) do
        local ok = true
        if e.kind == "rect" then
            if not isGeoRect(e, rec.geo, rec.ax, rec.cy) then
                ok = within(e.x, e.y, e.w, e.h, fsq, 1)
                if ok and e.y >= fsq.y + math.floor(fsq.h / 2) then low = low + 1 end
            end
        elseif e.kind == "text" then
            texts[#texts + 1] = tostring(e.text)
            ok = e.x >= fsq.x - 1 and e.x < fsq.x + fsq.w and e.y >= fsq.y - 1 and e.y < fsq.y + fsq.h
        elseif e.kind == "tex" then
            pics = pics + 1
            ok = within(e.x, e.y, e.w, e.h, fsq, 1)
        end
        if not ok then
            stray = stray + 1
            first = first or string.format("%s %s at %d,%d %dx%d (first square %d,%d %d)", e.kind, tostring(e.text or ""),
                math.floor(e.x), math.floor(e.y), math.floor(e.w), math.floor(e.h), fsq.x, fsq.y, fsq.w)
        end
    end
    return stray, first, texts, pics, low
end

-- ===================================================================== setup
Q.step(10, function()
    S.skip = nil
    if not (GL and GL.register and (GL.VERSION or 0) >= 2) then S.skip = "this ZeD has no grid layout hook version 2"; return end
    if GL.active() ~= nil then S.skip = "another add-on's grid layout provider is on (Multi-Slot?): the stand-in would replace it for good"; return end
    S.wasOpen = RT.isOpen()
    RT.pairOpen()
end)
Q.waitFor(5, 300, function() return S.skip ~= nil or (RT.cw() ~= nil and RT.cw():isVisible()) end, function(ok)
    if S.skip then return end
    if not ok then S.skip = "the Character window did not open"; return end
    local w = RT.cw()
    S.tab0 = w._activeTab
    RT.charTab("loot")
    local c = cnt()
    S.inv = c and c._inventory
    if S.inv ~= RT.p:getInventory() then S.skip = "the Character window's list is not the character's own inventory"; return end
    -- the bag as a grid (its own view choice, put back as found: nil, true or false)
    S.key = R.containerKey(S.inv, RT.p)
    pcall(function() local t = RT.p:getModData().ZeD_GridViews; S.view0 = t and t[S.key] end)
    R.setGridKey(S.key, true, RT.p)
    -- the things: three apples (one stack cell, its count) and a hammer at half condition (its strip)
    S.apples = { RT.give("Base.Apple"), RT.give("Base.Apple"), RT.give("Base.Apple") }
    S.hammer = RT.give("Base.Hammer")
    if not (S.apples[1] and S.apples[2] and S.apples[3] and S.hammer) then S.skip = "the test things could not be given"; return end
    pcall(function() S.hammer:setCondition(math.max(1, math.floor(S.hammer:getConditionMax() / 2))) end)
    S.repA, S.repB = S.apples[1], S.hammer
    S.regOk = GL.register(ID, P)
    GL.dirty(S.inv)
    pcall(R.dirtyModels)
end)
Q.waitFor(5, 600, function()
    if S.skip then return true end
    local L = GL.layoutOf(cnt(), S.inv)
    return L and L.geo and L.geo[S.repA] ~= nil and L.geo[S.repB] ~= nil
end, function(ok)
    if S.skip then Q.skip("the add-on grid hook", S.skip); return end
    Q.check(S.regOk == true and GL.active() == P, "the stand-in provider registers (hook version " .. tostring(GL.VERSION) .. ")")
    local ctx = S.ctx
    Q.check(S.calls > 0 and ctx ~= nil and tonumber(ctx.avail) ~= nil and tonumber(ctx.cell) ~= nil and tonumber(ctx.gap) ~= nil,
        "the provider's layout is asked, with version 2's avail, cell and gap", "calls " .. S.calls)
    local L = GL.layoutOf(cnt(), S.inv)
    S.L = L
    Q.check(ok and L ~= nil, "the bag is laid out by the provider", "layout " .. tostring(L ~= nil))
    if not L then return end
    Q.check(L.shapes == true and L.flat == true, "its answer is taken: shapes on, one flat grid")
    if (L.cols or 0) < 2 then S.skip = "the bag's grid is one square across here"; Q.skip("the shaped cells", S.skip); return end
    Q.check(L.sqw[S.repA] == 2 and L.sqh[S.repA] == 2 and L.has[S.repA] ~= nil and L.geo[S.repA].n == 3,
        "the L cell takes its mask: a 2 x 2 box of three squares", string.format("%sx%s, %s squares", tostring(L.sqw[S.repA]), tostring(L.sqh[S.repA]), tostring(L.geo[S.repA] and L.geo[S.repA].n)))
    Q.check(L.sqw[S.repB] == 1 and L.sqh[S.repB] == 3 and L.geo[S.repB].n == 3, "the bar cell takes its mask: three squares down",
        tostring(L.sqw[S.repB]) .. "x" .. tostring(L.sqh[S.repB]))
    Q.check(L.stacks[S.repA] ~= nil and L.stacks[S.repA].count == 3, "the L cell holds the three apples as one stack",
        "count " .. tostring(L.stacks[S.repA] and L.stacks[S.repA].count))
    local g = L.geo[S.repA]
    Q.check(g.fx == 0 and g.fy == 0 and g.ix == g.fx and g.iy == g.fy and g.wx == g.fx and g.wy == g.fy,
        "the L cell's labels are placed on its first square (the strip's and the weight's square is the picture's)")
end)
-- the squares at the provider's scale (read once a frame has drawn the cells: GV.zedCell is ZeD's own square)
Q.step(5, function()
    if S.skip then return end
    if not wrapOn() then Q.check(false, "the draw can be read (the Character window's list)"); return end
end)
Q.step(4, function()
    if S.skip or not S.on then return end
    local ra, rb = S.rec[S.repA], S.rec[S.repB]
    Q.check(ra ~= nil and rb ~= nil and ra.geo ~= nil and rb.geo ~= nil, "both shaped cells are drawn as shapes (with their drawing, not a box)",
        "L " .. tostring(ra ~= nil and ra.geo ~= nil) .. ", bar " .. tostring(rb ~= nil and rb.geo ~= nil))
    if not (ra and rb and ra.geo and rb.geo) then return end
    local want = math.max(4, math.floor((ra.zedCell or 0) * SCALE))
    Q.check(ra.geo.cell == want and S.L.cell == want, "the squares are the provider's scale of ZeD's own",
        string.format("%d px, want %d (ZeD's %d, scale %.1f)", ra.geo.cell, want, ra.zedCell or 0, SCALE))
    -- the L's hole: nothing drawn there, no click zone there; each of its squares clickable
    local hole = square(ra, 1, 1)
    local inHole = 0
    for _, e in ipairs(ra.calls) do
        if e.kind ~= "text" and hits(e.x, e.y, e.w, e.h, hole) then inHole = inHole + 1 end
    end
    Q.check(#ra.calls > 0 and inHole == 0, "the L cell draws nothing in its hole", inHole .. " of " .. #ra.calls .. " draws there")
    local zHole, sqHit = 0, { 0, 0, 0 }
    local sqs = { square(ra, 0, 0), square(ra, 1, 0), square(ra, 0, 1) }
    for _, z in ipairs(S.panel._hitZones or {}) do
        if z.id == S.repA then
            if hits(z.x, z.y, z.w, z.h, hole) then zHole = zHole + 1 end
            for i, s in ipairs(sqs) do
                local mx, my = s.x + math.floor(s.w / 2), s.y + math.floor(s.h / 2)
                if mx >= z.x and mx < z.x + z.w and my >= z.y and my < z.y + z.h then sqHit[i] = sqHit[i] + 1 end
            end
        end
    end
    Q.check(zHole == 0, "the L cell takes no click in its hole", zHole .. " click zones there")
    Q.check(sqHit[1] > 0 and sqHit[2] > 0 and sqHit[3] > 0, "each of the L cell's squares takes a click", table.concat(sqHit, ", "))
    -- the labels on the first square
    local one = not (ra.zedCell and ra.geo.cell >= math.floor(ra.zedCell * 0.75))
    local stray, first, texts, pics = labels(ra)
    Q.check(pics >= 1 and stray == 0, "the L cell's picture and labels sit on its first square", (first or "all on it") .. "; texts " .. table.concat(texts, " "))
    local hasCount = false
    for _, s in ipairs(texts) do if s == "(3)" then hasCount = true end end
    Q.check(hasCount, "the L cell shows its count (3)", table.concat(texts, " "))
    if not one then Q.check(#texts >= 2, "the L cell shows its weight as well", table.concat(texts, " ")) end
    local strayB, firstB, textsB, picsB, lowB = labels(rb)
    Q.check(picsB >= 1 and strayB == 0, "the bar cell's picture and labels sit on its first square (the top one)", (firstB or "all on it") .. "; texts " .. table.concat(textsB, " "))
    local kind = nil
    pcall(function() kind = ZeD.ItemMeter.ofStack(S.hammer, nil) end)
    if kind ~= nil and kind ~= "hidden" then
        Q.check(lowB >= 1, "the bar cell's condition strip is on its first square's foot", lowB .. " rects there")
    else
        Q.skip("the bar cell's condition strip", "the hammer shows no strip here (" .. tostring(kind) .. ")")
    end
    RT.bounds(Q, "the bag as the provider's grid")
end)
-- the pad's place mode (X held on the L cell runs GridLayout.padDrag): the ghost is the mask's outline
Q.step(2, function()
    if S.skip or not S.on then return end
    S.ghost = {}
    S.ghostOn = true
    pcall(GL.padDrag, RT.cw(), { item = S.repA }, nil)
end)
Q.step(4, function()
    if S.skip or not S.on then return end
    S.ghostOn = false
    local st = GL._pad and GL._pad[pn]
    local g = st and st.geo
    Q.check(st ~= nil and st.mask == MASK_A and g ~= nil and g.n == 3, "the pad's place mode carries the L cell's mask",
        "mask " .. tostring(st and st.mask) .. ", squares " .. tostring(g and g.n))
    local ra = S.rec[S.repA]
    if not (g and ra and ra.geo) then return end
    -- every edge of the mask's outline drawn at the cell's own square, in the ghost's colour, and none in the hole
    local found, missing = 0, 0
    local e = g.edges
    for k = 1, #e, 4 do
        local x, y = ra.ax + e[k], ra.cy + e[k + 1]
        local seen = false
        for _, r in ipairs(S.ghost) do
            if math.abs(r.x - x) < 0.5 and math.abs(r.y - y) < 0.5 and math.abs(r.w - e[k + 2]) < 0.5 and math.abs(r.h - e[k + 3]) < 0.5 then seen = true end
        end
        if seen then found = found + 1 else missing = missing + 1 end
    end
    local hole = square(ra, 1, 1)
    local inHole = 0
    for _, r in ipairs(S.ghost) do if hits(r.x, r.y, r.w, r.h, hole) then inHole = inHole + 1 end end
    Q.check(found > 0 and missing == 0 and inHole == 0, "the place mode's ghost is the mask's outline, not its box",
        found .. " edges drawn, " .. missing .. " missing, " .. inHole .. " in the hole")
end)

-- ===================================================================== put back
Q.mark()
Q.step(2, function()
    wrapOff()
    S.ghostOn = false
    pcall(GL.padCancel, pn)
    if GL and GL.active() == P then GL.unregister(ID) end
    if S.inv then GL.dirty(S.inv) end
    pcall(R.dirtyModels)
end)
Q.waitFor(5, 300, function()
    if S.skip and not S.regOk then return true end
    local c = cnt()
    return c == nil or c._gridLayoutGen == nil
end, function(ok)
    if S.skip and not S.regOk then return end
    Q.check(GL.active() == nil, "unregistered, the hook has no provider")
    Q.check(ok, "the bag's grid is ZeD's own again (no add-on layout on the list)")
    Q.check(S.dropped ~= true, "the place mode was cancelled: nothing was dropped")
end)
Q.step(2, function()
    if S.key then
        pcall(function()
            local t = RT.p:getModData().ZeD_GridViews
            if t then t[S.key] = S.view0 end
        end)
    end
    if S.tab0 and S.tab0 ~= "loot" then RT.charTab(S.tab0) end
    if S.wasOpen == false then RT.pairShut() end
end)
Q.start()
