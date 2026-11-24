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
-- Then (Nov 18 2026, the FEATURE_MAP ledger's rows tagged rt_addon): the pad place mode's prompts, B and release; the
-- mail store; one bar per item; the loot card's content; an add-on item rule refusing a move; the Loadouts lists; the
-- fishing log; an add-on's ZeD setup group; the watch registry; the item facts factories; the Traits tab's sources;
-- ZeD's pad keyboard; the Lua console (-debug only). Each stand-in is taken away again (A.back).
-- Things given (apples, hammers, a water bottle, beans, a school bag) are taken back; the bag's view is put back as found.
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
    local e = { kind = kind, x = x, y = y, w = w, h = h, text = text, col = { r = r or 0, g = g or 0, b = b or 0 }, f = S.gframe }
    if S.cur then
        local L = S.rec[S.cur]
        if L then L.calls[#L.calls + 1] = e end
    -- (Nov 21 2026: with a full inventory another item's cell can sit in the L's hole, free space by design, and its
    -- condition strip draws in T.positive; draws made inside any other cell are not the ghost's)
    elseif not S.inCell and kind == "rect" and S.ghostOn and (sameColor(T.positive, r, g, b) or sameColor(T.danger, r, g, b)) then
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
        local theirs = panel == S.panel and not mine
        if mine then
            S.rec[item] = { calls = {}, ax = GV.xOff + cx, cy = cy, geo = geo, gap = GV.gap, zedCell = GV.zedCell, cell = GV.cell }
            S.cur = item
        end
        if theirs then S.inCell = true end
        local ok, e = pcall(orig, panel, GV, item, cx, cy, w, h, geo)
        if mine then S.cur = nil end
        if theirs then S.inCell = nil end
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
    S.inCell = nil
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
    -- (Nov 18 2026 ledger: a provider with no layout is refused; the real one under the same id follows)
    S.badReg = GL.register(ID, {})
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
    Q.check(S.badReg == false, "a provider with no layout function is refused (register returns false)", tostring(S.badReg))
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
-- (Nov 18 2026 ledger, FEATURE_MAP "Pad place mode"): its prompts, B ends it, and letting X go (GL.padRelease, what
-- FocusManager's hold release runs) hands the ghost's square to the provider's drop. The stand-in's drop only notes
-- the call (the square is the cell's own: nothing moves).
Q.step(2, function()
    if S.skip or not S.on then return end
    local pr = GL.padPrompts(pn)
    local gl = {}
    for _, p in ipairs(pr or {}) do gl[#gl + 1] = tostring(p.glyph) end
    Q.check(table.concat(gl, " ") == "D-PAD A X B" and pr[2].label == ZeD.tr("UI_ZeD_Looks_PromptTurn"),
        "the place mode's prompts: D-pad Move, A Turn, X Place, B Cancel", table.concat(gl, " "))
    local took = GL.padButton(pn, Joypad.BButton)
    Q.check(took == true and (GL._pad or {})[pn] == nil and S.dropped ~= true, "the place mode: B ends it, nothing placed")
    pcall(GL.padDrag, RT.cw(), { item = S.repA }, nil)
end)
Q.step(2, function()
    if S.skip or not S.on then return end
    local on = (GL._pad or {})[pn] ~= nil
    pcall(GL.padRelease, RT.cw(), { item = S.repA })
    Q.check(on and (GL._pad or {})[pn] == nil and S.dropped == true, "the place mode: letting X go hands the square to the provider's drop",
        "on " .. tostring(on) .. ", dropped " .. tostring(S.dropped))
    S.dropped = nil   -- (the put-back's check below is about the cancel at the end)
end)

-- (Nov 18 2026 ledger, FEATURE_MAP "Drag ghost (mouse)"): a mouse drag of the L cell through the list's own press
-- (onMouseDown, past the drag threshold), the pointer held over the cell's first square (the list's getMouseX /
-- getMouseY answer it while the drag draws): the over-state says canPlace's yes, the ghost is the mask's outline in
-- the yes colour; the wheel (content.onMouseWheel, as R) turns it (the provider's turn, its shape asked again); the
-- release hands the square to the provider's drop. Then canPlace says no with a reason: the ghost turns the no
-- colour, the release drops nothing and the reason stays on the help line. Put back by S.mdBack.
function S.mdFake(on)
    local c = S.panel
    if not c then return end
    if on then
        S.mdHad = { rawget(c, "getMouseX"), rawget(c, "getMouseY") }
        c.getMouseX = function() return S.mdX end
        c.getMouseY = function() return S.mdY end
    elseif S.mdHad then
        c.getMouseX, c.getMouseY = S.mdHad[1], S.mdHad[2]
        S.mdHad = nil
    end
end
function S.mdStart()
    local c, ra = S.panel, S.rec[S.repA]
    if not (c and ra and ra.geo) then return false end
    local sq = square(ra, 0, 0)
    S.mdX, S.mdY = sq.x + math.floor(sq.w / 2), sq.y + math.floor(sq.h / 2)
    c._zedLastClick = nil
    c:onMouseDown(S.mdX, S.mdY)
    local d = c._drag
    if not (d and d:isPending()) then return false end
    d:checkThreshold(d.startX + 40, d.startY + 40)
    if not d:isActive() then pcall(function() d:cancel() end); return false end
    S.mdFake(true)
    S.ghost = {}
    S.ghostOn = true
    if not S.gtickOn then Events.OnPreUIDraw.Add(S.gtick); S.gtickOn = true end
    return true
end
-- (Nov 18 2026, run r5) the frames counted while a mouse drag is on, so only the last frame's ghost is judged
S.gframe = 0
function S.gtick() S.gframe = S.gframe + 1 end
-- the ghost's rects matched against the mask's edges where GridLayout draws the mouse's ghost: the over-state's
-- square (GL._over's x, y), not the cell's own square (run r5: it is drawn there, 12 edges a frame, and was looked for
-- at the cell). Only the last frame drawn is judged. Returns found, missing, the rects not in col, and the rects in
-- the yes colour (T.positive).
function S.mdGhost(col)
    local ra = S.rec[S.repA]
    local L = GL.layoutOf(cnt(), S.inv)
    local g = L and L.geo and L.geo[S.repA]
    local O = GL._over
    local found, missing, other, yes = 0, 0, 0, 0
    if not (ra and g and L.px and L.py and L.px[S.repA] and L.py[S.repA] and O) then return 0, 1, 0, 0 end
    local step = L.cell + L.gap
    -- the cell's own square is (GV.xOff + GV.padX + L.px, y0 + L.py); the ghost's is (GV.xOff + GV.padX + O.x * step,
    -- y0 + L.gridTop + L.gap + O.y * step)
    local gx = ra.ax - L.px[S.repA] + O.x * step
    local gy = ra.cy - L.py[S.repA] + L.gridTop + L.gap + O.y * step
    local last = -1
    for _, r in ipairs(S.ghost) do if (r.f or 0) > last then last = r.f or 0 end end
    -- (Nov 18 2026, run r6) the mouse ghost's drawing is made with a 2-unit outline (shapeFrom in GridLayout.lua), the
    -- layout's own geo with 1: the expected edges are built the ghost's way. Only rects inside the ghost's 2 x 2
    -- footprint are judged (the recorder also catches other rows' status strips in the same colours).
    local has = L.has and L.has[S.repA]
    if not has then return 0, 1, 0, 0 end
    local tg = math.max(1, T.px(2))
    local okG, gg = pcall(GL.geom, has, 2, 2, L.cell, L.gap, tg)
    if okG and gg then g = gg end
    local box = { x = gx, y = gy, w = 2 * L.cell + L.gap, h = 2 * L.cell + L.gap }
    local rs = {}
    for _, r in ipairs(S.ghost) do
        if (r.f or 0) == last and within(r.x, r.y, r.w, r.h, box, 0.5) then rs[#rs + 1] = r end
    end
    local e = g.edges
    for k = 1, #e, 4 do
        local seen = false
        for _, r in ipairs(rs) do
            if math.abs(r.x - (gx + e[k])) < 0.5 and math.abs(r.y - (gy + e[k + 1])) < 0.5 and math.abs(r.w - e[k + 2]) < 0.5
               and math.abs(r.h - e[k + 3]) < 0.5 then seen = true end
        end
        if seen then found = found + 1 else missing = missing + 1 end
    end
    for _, r in ipairs(rs) do
        if not sameColor(r.col, col.r, col.g, col.b) then other = other + 1 end
        if sameColor(r.col, T.positive.r, T.positive.g, T.positive.b) then yes = yes + 1 end
    end
    return found, missing, other, yes
end
function S.mdBack()
    if S.gtickOn then Events.OnPreUIDraw.Remove(S.gtick); S.gtickOn = false end
    S.ghostOn = false
    S.mdFake(false)
    pcall(function() local d = S.panel and S.panel._drag; if d and (d:isActive() or d:isPending()) then d:cancel() end end)
    if S.mdOrig then P.canPlace, P.turn, P.dragShape = S.mdOrig[1], S.mdOrig[2], S.mdOrig[3]; S.mdOrig = nil end
end
Q.step(2, function()
    if S.skip or not S.on then return end
    S.mdOrig = { P.canPlace, P.turn, P.dragShape }
    S.mdTurns, S.mdAsks = 0, 0
    local ds = P.dragShape
    P.dragShape = function(items, ctx) S.mdAsks = S.mdAsks + 1; return ds(items, ctx) end
    P.turn = function() S.mdTurns = S.mdTurns + 1 end
    S.dropped = nil
    S.mdArm = Q.check(S.mdStart(), "mouse drag: a press on the L cell past the threshold starts ZeD's drag")
end)
Q.step(4, function()
    if not S.mdArm then return end
    local O = GL._over
    local found, missing, other, yes = S.mdGhost(T.positive)
    Q.check(O.panel == S.panel and O.ok == true and O.inv == S.inv, "mouse drag: over the grid, the over-state says canPlace's yes",
        "ok " .. tostring(O.ok) .. ", on this list " .. tostring(O.panel == S.panel))
    Q.check(found > 0 and missing == 0 and other == 0, "mouse drag: the ghost is the mask's outline, in the yes colour",
        found .. " edges drawn, " .. missing .. " missing, " .. other .. " in another colour (last frame, at the over-state's square "
        .. tostring(O.x) .. "," .. tostring(O.y) .. ")")
    S.mdAsk0 = S.mdAsks
    pcall(S.panel.onMouseWheel, S.panel, 1)
end)
Q.step(3, function()
    if not S.mdArm then return end
    Q.check(S.mdTurns == 1 and S.mdAsks > S.mdAsk0, "mouse drag: the wheel (as R) turns the dragged shape",
        S.mdTurns .. " turns, shape asked " .. (S.mdAsks - S.mdAsk0) .. " times since")
    pcall(S.panel.onMouseUp, S.panel, S.mdX, S.mdY)
end)
Q.step(3, function()
    if not S.mdArm then return end
    local d = S.panel._drag
    Q.check(S.dropped == true and not (d and d:isActive()), "mouse drag: the release hands the square to the provider's drop",
        "dropped " .. tostring(S.dropped))
    S.mdFake(false)
    S.dropped = nil
    S.mdWhy = "QA stand-in: no room here"
    P.canPlace = function() return false, S.mdWhy end
    S.mdArm = S.mdStart()
end)
Q.step(4, function()
    if not S.mdArm then return end
    local O = GL._over
    local found, missing, other, yes = S.mdGhost(T.danger)
    Q.check(O.ok == false and O.reason == S.mdWhy and found > 0 and missing == 0 and other == 0 and yes == 0,
        "mouse drag: canPlace's no turns the ghost the no colour, its reason said",
        "ok " .. tostring(O.ok) .. ", reason " .. tostring(O.reason) .. "; " .. found .. " edges, " .. missing .. " missing, "
        .. other .. " other colour (last frame)")
    pcall(S.panel.onMouseUp, S.panel, S.mdX, S.mdY)
end)
Q.step(3, function()
    if not S.mdArm then S.mdBack(); return end
    local O = GL._over
    Q.check(S.dropped ~= true and O.keepReason == S.mdWhy, "mouse drag: a refused release drops nothing, the reason kept",
        "dropped " .. tostring(S.dropped) .. ", kept " .. tostring(O.keepReason))
    S.dropped = nil
    S.mdBack()
end)

-- ===================================================================== the mail kept on this computer
-- (Nov 18 2026, FEATURE_MAP "Mail kept on this computer": ZeD_MailStore.lua, the model under the multiplayer mail.
-- It needs no server: a box per server and name, its Outbox, Inbox and Sent written to Zomboid/Lua and read back.
-- The store's file access (MS.io, its own seam) is pointed at "zedqa_rt_"-named files for the run, so the player's
-- real mail files are never read or written; the QA files are emptied after.)
local MAILQ = "zedqa_rt_"
local function mailLines(name)
    local out = nil
    pcall(function()
        local r = getFileReader(MAILQ .. name, false)
        if not r then return end
        out = {}
        local l = r:readLine()
        while l do out[#out + 1] = l; l = r:readLine() end
        r:close()
    end)
    return out
end
local function mailBack()
    local MSt = ZeD.MailStore
    if not (MSt and S.mIo) then return end
    for name in pairs(S.mFiles or {}) do
        pcall(function() local w = getFileWriter(MAILQ .. name, true, false); w:write(""); w:close() end)
    end
    MSt.io, MSt._boxes = S.mIo, S.mBoxes
    S.mIo = nil
end
Q.step(3, function()
    local MSt = ZeD.MailStore
    if not (MSt and MSt.box and MSt.queue and MSt.load and ZeD.Ml) then Q.check(false, "ZeD's mail store is loaded"); return end
    S.mIo, S.mBoxes = MSt.io, MSt._boxes
    S.mFiles = { [MSt.INDEX] = true }
    MSt.io = {
        reader = function(name) return getFileReader(MAILQ .. name, false) end,
        writer = function(name) S.mFiles[name] = true; return getFileWriter(MAILQ .. name, true, false) end,
    }
    -- (an earlier run's index emptied first: the box is made fresh)
    pcall(function() local w = getFileWriter(MAILQ .. MSt.INDEX, true, false); w:write(""); w:close() end)
    MSt._boxes = nil
    S.mText = "A letter | with a pipe\nand a second line."
    local ok, err = pcall(function()
        local b = MSt.box("rtqa-server", "rtqa-user", "QA server")
        S.mN = b.n
        S.mLetter = MSt.queue(b, "rtqa-friend", "QA subject", S.mText)
        MSt.receive(b, { id = 7, from = "rtqa-friend", to = "rtqa-user", t = 1, day = 2, subj = "QA reply", text = "Got it." })
        MSt.save(b)
    end)
    Q.check(ok and S.mLetter ~= nil, "mail store: a box is made for a server and name, a letter queued and one received", tostring(err))
    if not (ok and S.mN and S.mLetter) then return end
    local box, idx = mailLines(MSt.fileOf(S.mN)) or {}, mailLines(MSt.INDEX) or {}
    local hasOut, hasIn, hasBox = false, false, false
    for _, l in ipairs(box) do
        if string.sub(l, 1, 2) == "o|" and string.find(l, "QA subject", 1, true) and string.find(l, "\\p", 1, true) then hasOut = true end
        if string.sub(l, 1, 4) == "i|7|" then hasIn = true end
    end
    for _, l in ipairs(idx) do if string.find(l, "rtqa-server/rtqa-user", 1, true) then hasBox = true end end
    Q.check(hasOut and hasIn and hasBox, "mail store: the box's file holds the queued letter (its pipe escaped) and the received one; the index names the box",
        #box .. " lines in " .. MSt.fileOf(S.mN) .. ", box listed " .. tostring(hasBox))
end)
Q.step(3, function()
    local MSt = ZeD.MailStore
    if not (MSt and S.mIo and S.mN and S.mLetter) then mailBack(); return end
    -- read back from the files alone: the cache dropped
    MSt._boxes = nil
    local b, d = nil, nil
    pcall(function()
        b = MSt.find(MSt.keyOf("rtqa-server", "rtqa-user"))
        d = b and MSt.load(b)
    end)
    local o1, i1 = d and d.outbox[1], d and d.inbox[1]
    Q.check(o1 ~= nil and o1.subj == "QA subject" and o1.text == S.mLetter.text and o1.to == "rtqa-friend" and o1.cid == S.mLetter.cid,
        "mail store: the Outbox letter reads back whole (subject, words with the pipe and the line break, to)", tostring(o1 and o1.text))
    local unread = nil
    pcall(function() unread = MSt.unread(b) end)
    Q.check(i1 ~= nil and i1.id == 7 and i1.from == "rtqa-friend" and i1.subj == "QA reply" and not i1.read and unread == 1,
        "mail store: the Inbox letter reads back, unread", tostring(i1 and i1.subj) .. ", unread " .. tostring(unread))
    -- sent: the Outbox letter moves to Sent, and that reads back too
    pcall(function() MSt.sent(b, S.mLetter.cid) end)
    MSt._boxes = nil
    local d2 = nil
    pcall(function() local b2 = MSt.find(MSt.keyOf("rtqa-server", "rtqa-user")); d2 = b2 and MSt.load(b2) end)
    Q.check(d2 ~= nil and #d2.outbox == 0 and #d2.sent == 1 and d2.sent[1].subj == "QA subject", "mail store: a sent letter leaves the Outbox for Sent, read back",
        tostring(d2 and #d2.outbox) .. " out, " .. tostring(d2 and #d2.sent) .. " sent")
    local io0 = S.mIo
    mailBack()
    Q.check(MSt.io == io0, "mail store put back: its own file access again, the QA files emptied")
end)

-- ===================================================================== the other add-on hooks and models (Nov 18 2026)
-- (the FEATURE_MAP ledger's rows this script owns; each block names its row. Everything a block registers it takes
-- away again in the same block, and once more in the put-back if the run jumped there.)
local A = {}
A.RULE = "zedqa_rt_addon_rule"
A.OWNER = "zedqa_rt_addon"
A.FACTS = "zedqa_rt_addon_facts"
A.WATCH = "Base.ZedQAStandinWatch"
function A.back()
    pcall(function() ZeD.ItemRules.unregister(A.RULE) end)
    if A.note ~= nil then ZeD.Bubbles.note = A.note; A.note = nil end
    pcall(function()
        local O = ZeD.Options
        for i = #O.groups, 1, -1 do if O.groups[i].owner == A.OWNER then table.remove(O.groups, i); O.rev = O.rev + 1 end end
    end)
    pcall(function() ZeD.Watch.watches[A.WATCH] = nil end)
    pcall(function()
        local M = ZeD.ItemFactsPanel
        for i = #M._registry, 1, -1 do if M._registry[i].key == A.FACTS then table.remove(M._registry, i); M.gen = (M.gen or 0) + 1 end end
    end)
    pcall(function()
        local TT = ZeD.TraitsTab
        for i = #TT.sources, 1, -1 do if TT.sources[i].id == A.OWNER then table.remove(TT.sources, i) end end
    end)
    if A.fishWas ~= nil then pcall(function() RT.p:getModData()[ZeD.FishingLog.KEY] = A.fishWas.v end); A.fishWas = nil end
    if A.kbBox then
        pcall(function() if ZeD.Keyboard.isVisible() then ZeD.Keyboard.hide() end end)
        pcall(function() A.kbBox:removeFromUIManager() end)
        A.kbBox = nil
    end
    if A.dc then
        if not A.dc.was then pcall(ZeD.DebugConsole.close) end
        A.dc = nil
    end
end

-- One bar per item (FEATURE_MAP "Inventory: one bar per item"): ItemMeter.of, what the list's COND / AMT column and
-- the grid's strip draw
Q.step(3, function()
    local IM = ZeD.ItemMeter
    if not (IM and IM.of) then Q.check(false, "item bar: ZeD.ItemMeter is loaded"); return end
    local bottle, beans, hammer = RT.give("Base.WaterBottle"), RT.give("Base.TinnedBeans"), RT.give("Base.Hammer")
    if not (bottle and beans and hammer) then Q.check(false, "item bar: a water bottle, a can of beans and a hammer are given"); return end
    local want = nil
    pcall(function() local fc = bottle:getFluidContainer(); want = fc:getAmount() / fc:getCapacity() end)
    local kB, fB = IM.of(bottle)
    Q.check(kB == "fluid" and want ~= nil and type(fB) == "number" and math.abs(fB - want) < 0.001,
        "item bar: a water bottle's bar is its fluid, amount over capacity", tostring(kB) .. " " .. tostring(fB) .. " (want " .. tostring(want) .. ")")
    local kH = IM.of(hammer)
    Q.check(kH == "cond", "item bar: a weapon's bar is its condition", tostring(kH))
    local kC = IM.of(beans)
    Q.check(kC == nil, "item bar: a can of beans has no bar", tostring(kC))
end)

-- The hover loot card's content (FEATURE_MAP "Inventory: hover loot card"): LootCard.content, what the balloon shows
-- for a hovered row (the hover itself and the card on screen: rt_pad's card checks, by the pad's path)
Q.step(3, function()
    local LC = ZeD.LootCard
    local apple = RT.give("Base.Apple")
    if not (LC and LC.content and apple) then Q.check(false, "loot card: ZeD.LootCard is loaded and an apple given"); return end
    local c, f = nil, nil
    pcall(function() c = LC.content(apple, RT.p, 3); f = LC.facts(apple, RT.p) end)
    local name = apple:getName()
    local wrow = f and f.rows and f.rows[1]
    Q.check(c ~= nil and c.title == name .. " (3)" and wrow ~= nil and wrow[1] == ZeD.tr("UI_ZeD_Weight") and c.body ~= nil,
        "loot card: the card names the item with its count and leads with its weight",
        tostring(c and c.title) .. ", first row " .. tostring(wrow and wrow[1]))
end)

-- Item rules (FEATURE_MAP "Inventory: add-on rule refuses a move with a reason" and "Item rules (why a move is
-- refused)"): a stand-in rule refuses one apple into a bag; the band's own move (ContainerControls.moveItems, what
-- Take all, Transfer all, the pad's X and a drop run) moves the other and leaves that one, and the reason shows once
-- over the head (ZeD_Bubbles.note, counted here, not shown)
Q.step(3, function()
    A.ir = nil
    local IRu, CT = ZeD.ItemRules, ZeD.ContainerControls
    if not (IRu and IRu.register and CT and CT.moveItems and ZeD.Bubbles and ZeD.Bubbles.note) then
        Q.check(false, "item rules: ZeD.ItemRules and the band's move are loaded"); return
    end
    local bag, a, b = RT.give("Base.Bag_Schoolbag"), RT.give("Base.Apple"), RT.give("Base.Apple")
    local dest = nil
    pcall(function() dest = bag:getInventory() end)
    if not (dest and a and b) then Q.check(false, "item rules: a school bag and two apples are given"); return end
    A.ir = { a = a, b = b, dest = dest, src = a:getContainer(), notes = {}, why = "QA stand-in: no room for this apple" }
    A.note = ZeD.Bubbles.note
    ZeD.Bubbles.note = function(p2, text, kind) A.ir.notes[#A.ir.notes + 1] = tostring(text) end
    IRu.register(A.RULE, { canPut = function(item, d) if item == A.ir.a and d == A.ir.dest then return false, A.ir.why end; return true end })
    local okC, why = IRu.check(a, dest, RT.p, A.ir.src)
    Q.check(okC == false and why == A.ir.why, "item rules: the stand-in rule refuses its apple, with its reason", tostring(okC) .. ", " .. tostring(why))
    pcall(CT.moveItems, RT.p, { a, b }, dest)
end)
Q.waitFor(5, 1200, function()
    if not A.ir then return true end
    local inB = false
    pcall(function() inB = A.ir.b:getContainer() == A.ir.dest end)
    return inB
end, function(ok)
    if not A.ir then return end
    local ir = A.ir
    local aWhere = nil
    pcall(function() aWhere = ir.a:getContainer() end)
    Q.check(ok and aWhere == ir.src, "item rules: the refused apple stays put, the other moves into the bag",
        "other moved " .. tostring(ok) .. ", refused one in place " .. tostring(aWhere == ir.src))
    Q.check(#ir.notes == 1 and ir.notes[1] == ir.why, "item rules: the reason shows once over the head", #ir.notes .. " notes: " .. table.concat(ir.notes, " / "))
    ZeD.ItemRules.unregister(A.RULE)
    ZeD.Bubbles.note = A.note
    A.note = nil
    A.ir = nil
end)

-- Loadouts (FEATURE_MAP "Loadouts page: new, rename, delete, amounts"): ZeD.Lists, the model the Loadouts page's
-- New, Rename, Delete and amount boxes call; a list made, renamed, given a line and an amount, then deleted.
-- (Nov 23 2026, QA: the Loadouts split makes ZeD.Lists the add-on ZeD-GUI: Loadouts' module: with ZeD alone after the
-- split (ZeD.API there, no ZeD.Lists) these checks are a SKIP; ad_split checks ZeD alone has no Loadouts.)
Q.step(3, function()
    local L = ZeD.Lists
    if not L and ZeD.API then
        Q.skip("Loadouts: a new list is saved with the character, by its name", "ZeD-GUI: Loadouts is not loaded: ZeD.Lists is the add-on's since the split")
        return
    end
    if not (L and L.create and L.store) then Q.check(false, "Loadouts: ZeD.Lists is loaded"); return end
    local s = L.store(RT.p)
    local n0, next0 = #s.lists, s.nextId
    local l = L.create(RT.p, "loadout", "zedqa list")
    local md = nil
    pcall(function() md = RT.p:getModData().ZeD_Lists end)
    local last = md and md.lists and md.lists[#md.lists]
    Q.check(l ~= nil and #s.lists == n0 + 1 and last ~= nil and last.name == "zedqa list", "Loadouts: a new list is saved with the character, by its name",
        #s.lists .. " lists (were " .. n0 .. ")")
    if not l then return end
    local okR = L.rename(RT.p, l.id, "zedqa renamed")
    local g = L.get(RT.p, l.id)
    Q.check(okR and g ~= nil and g.name == "zedqa renamed", "Loadouts: a list renamed keeps its new name", tostring(g and g.name))
    local ln = L.addLine(RT.p, l.id, { type = "Base.Apple", unit = "n", amount = 1 })
    local amt = ln and L.setAmount(RT.p, l.id, ln.id, 3)
    Q.check(amt == 3 and ln.amount == 3, "Loadouts: a line's amount is set and kept", tostring(amt))
    local okD = L.delete(RT.p, l.id)
    Q.check(okD and #s.lists == n0 and L.get(RT.p, l.id) == nil, "Loadouts: a list deleted is gone from the character's lists", #s.lists .. " lists")
    if okD then s.nextId = next0 end
end)

-- The fishing log (FEATURE_MAP "Catches are logged"): the game's landing is wrapped, and the record it calls writes
-- the catch, newest last, with its name and weight. (No water on the QA save: the record is called as the wrap calls
-- it, into a fresh log; the character's own log is put back.)
Q.step(3, function()
    local FL = ZeD.FishingLog
    if not (FL and FL.record and FL.KEY) then Q.check(false, "fishing log: ZeD.FishingLog is loaded"); return end
    local Pk = Fishing and Fishing.States and Fishing.States.PickupFish
    Q.check(Pk ~= nil and Pk._zedOrigStart ~= nil and Pk.start ~= Pk._zedOrigStart, "fishing log: the game's landing (PickupFish.start) is wrapped")
    local md = RT.p:getModData()
    A.fishWas = { v = md[FL.KEY] }
    md[FL.KEY] = nil
    local ok, err = pcall(FL.record, RT.p, { kind = "fish", name = "QA Bass", wt = 2.5, len = 40 })
    local d = FL.data(RT.p)
    local e = d.log[#d.log]
    local r = FL.recent(RT.p, 1)
    Q.check(ok and #d.log == 1 and d.n == 1 and e ~= nil and e.name == "QA Bass" and e.wt == 2.5 and r[1] == e,
        "fishing log: a catch is logged, newest, with its name and weight", tostring(err) .. ", " .. #d.log .. " in the log")
    md[FL.KEY] = A.fishWas.v
    A.fishWas = nil
end)

-- An add-on's group on ZeD setup (FEATURE_MAP "Add-on group on ZeD setup"): ZeD.Options.addGroup (version 1) takes a
-- stand-in group, refuses one with no owner, and the same owner and title again replaces it. (Its rows on the
-- screen need the add-on's own PZAPI.ModOptions and the Options window: rt_system's ground.)
Q.step(3, function()
    local O = ZeD.Options
    if not (O and O.addGroup and O.groups) then Q.check(false, "add-on options: ZeD.Options is loaded"); return end
    local n0, rev0 = #O.groups, O.rev or 0
    local logged0 = O.logged["addGroup:noowner"]
    local bad = O.addGroup({ title = "x", rows = {} })
    O.logged["addGroup:noowner"] = logged0
    local spec = { owner = A.OWNER, title = "ZeD QA stand-in", rows = { { "zedqa", "onoff" } } }
    local ok = O.addGroup(spec)
    local g = O.groups[#O.groups]
    Q.check(O.VERSION == 1 and bad == false and ok == true and #O.groups == n0 + 1 and g.owner == A.OWNER and #g.rows == 1 and (O.rev or 0) > rev0,
        "add-on options: addGroup takes a stand-in group and refuses one with no owner", "version " .. tostring(O.VERSION) .. ", " .. #O.groups .. " groups")
    O.addGroup(spec)
    Q.check(#O.groups == n0 + 1, "add-on options: the same owner and title again replaces it, never twice", #O.groups .. " groups")
    A.back()
end)

-- The watch registry (FEATURE_MAP "Watch registry"): ZeD.Watch.register files a stand-in watch under its item type
-- (wearing a registered watch draws its plate: rt_hud's watch checks, with the game's own watches)
Q.step(2, function()
    local W = ZeD.Watch
    if not (W and W.register and W.watches) then Q.check(false, "watch registry: ZeD.Watch is loaded"); return end
    local def = { plate = "classic_gold", items = { A.WATCH } }
    W.register(def)
    Q.check(W.watches[A.WATCH] == def, "watch registry: a registered watch is filed under its item type")
    W.watches[A.WATCH] = nil
end)

-- The item facts factories (FEATURE_MAP "Item facts panel factories"): a stand-in factory registered first answers
-- for its item on the card's facts (ItemFactsPanel.factsFor, what ItemCardOrganism asks), not for another; gen bumps
Q.step(2, function()
    local M = ZeD.ItemFactsPanel
    local apple, hammer = RT.give("Base.Apple"), RT.give("Base.Hammer")
    if not (M and M.register and M.factsFor and apple and hammer) then Q.check(false, "item facts: ZeD.ItemFactsPanel is loaded, things given"); return end
    local gen0 = M.gen or 0
    M.register(A.FACTS, function(item) if item == apple then return { zedqa = true } end; return nil end, 1)
    local pa, ph = nil, nil
    pcall(function() pa = M.factsFor(apple, pn); ph = M.factsFor(hammer, pn) end)
    Q.check(pa ~= nil and pa.zedqa == true and pa._key == A.FACTS and (M.gen or 0) > gen0 and not (ph and ph._key == A.FACTS),
        "item facts: a registered factory gives its item's facts on the card", "key " .. tostring(pa and pa._key) .. ", gen " .. gen0 .. " -> " .. tostring(M.gen))
    A.back()
end)

-- The Traits tab's sources (FEATURE_MAP "Traits tab registry"): with no traits mod on this save, no source and no
-- Traits tab; a stand-in source added is listed, counted, laid out and owns its ids; taken away after
Q.step(2, function()
    local TT = ZeD.TraitsTab
    if not (TT and TT.addSource and TT.list) then Q.check(false, "traits tab: ZeD.TraitsTab is loaded"); return end
    local n0 = #TT.list()
    if n0 == 0 then
        local tab = nil
        for id, d in pairs(ZeD_CharacterWindow._extTabs or {}) do if d.iconName == "traits-tab-white" then tab = id end end
        Q.check(tab == nil, "traits tab: no source here, so no Traits tab", tostring(tab))
    end
    local a0 = TT.counts(nil, "", false)
    local y0 = TT.layout(nil, nil, 0, 10, 100, "", false)
    TT.addSource(A.OWNER, { counts = function() return 2, 1, 1 end, layout = function(win, L, x, y) return y + 5 end,
                            owns = function(id) return id == "zedqa:x" end })
    local a1 = TT.counts(nil, "", false)
    local y1 = TT.layout(nil, nil, 0, 10, 100, "", false)
    local own = TT.ownerOf("zedqa:x")
    Q.check(#TT.list() == n0 + 1 and a1 - a0 == 2 and y1 - y0 == 5 and own ~= nil and own.id == A.OWNER,
        "traits tab: a source added is listed, counted, laid out and owns its ids", "count +" .. tostring(a1 - a0) .. ", y +" .. tostring(y1 - y0))
    A.back()
end)

-- ZeD's pad keyboard (FEATURE_MAP "ZeD on-screen keyboard"): KB.edit (ZeD.padType, the A on every ZeD text box) on a
-- stand-in box, keys pressed with A as the pad presses them (the hand moved to the key), B leaves it with the text kept
Q.step(3, function()
    local KB = ZeD.Keyboard
    A.kbBox = nil
    if not (KB and KB.edit and ISTextEntryBox) then Q.check(false, "keyboard: ZeD.Keyboard is loaded"); return end
    local box = ISTextEntryBox:new("", T.px(100), T.px(100), T.px(200), T.px(24))
    box:initialise()
    box:instantiate()
    box:addToUIManager()
    A.kbBox = box
    local ok = false
    pcall(function() ok = KB.edit(box, pn) end)
    -- (Nov 18 2026, run r5: the keyboard opened, but KB.isVisible (isReallyVisible) is true only once UIManager adds it
    -- on the next update, so the opening is read from the keyboard's own box, and the keys wait for it to show)
    local kb = KB.instance
    if not Q.check(ok and kb ~= nil and kb.textEntryBox == box, "keyboard: A on a text box opens ZeD's keyboard on it") then
        pcall(function() KB.hide() end)
        pcall(function() box:removeFromUIManager() end)
        A.kbBox = nil
    end
end)
Q.waitFor(1, 60, function() return (not A.kbBox) or ZeD.Keyboard.isVisible() end, function(ok)
    local box, KB = A.kbBox, ZeD.Keyboard
    if not box then return end
    if not ok then
        Q.check(false, "keyboard: A on the a and b keys types ab", "the keyboard never showed")
        pcall(function() KB.hide() end)
        pcall(function() box:removeFromUIManager() end)
        A.kbBox = nil
        return
    end
    local kb = KB.instance
    for _, ch in ipairs({ "a", "b" }) do
        local at = nil
        for r, row in ipairs(kb._rows or {}) do
            for c, k in ipairs(row) do if not at and k.lo == ch then at = { r, c } end end
        end
        if at then kb._focus = at; pcall(kb.onJoypadDown, kb, Joypad.AButton) end
    end
end)
-- (a key types through the game's queued key events: the text is there a frame or two later)
Q.waitFor(2, 120, function()
    if not (A.kbBox and ZeD.Keyboard.isVisible()) then return true end
    return A.kbBox:getInternalText() == "ab"
end, function(ok)
    local box, KB = A.kbBox, ZeD.Keyboard
    if not box then return end
    if not KB.isVisible() then
        Q.check(false, "keyboard: A on the a and b keys types ab", "the keyboard closed before the text came: '" .. tostring(box:getInternalText()) .. "'")
        pcall(function() box:removeFromUIManager() end)
        A.kbBox = nil
        return
    end
    Q.check(ok, "keyboard: A on the a and b keys types ab", "'" .. tostring(box:getInternalText()) .. "'")
    RT.bounds(Q, "ZeD's keyboard")
    local kb = KB.instance
    pcall(kb.onJoypadDown, kb, Joypad.BButton)
    Q.check(not KB.isVisible() and box:getInternalText() == "ab", "keyboard: B leaves it and the text is kept", "'" .. tostring(box:getInternalText()) .. "'")
    pcall(function() box:removeFromUIManager() end)
    A.kbBox = nil
end)

-- The Lua console (FEATURE_MAP "Lua console window"): only in -debug. Opened (as the game's console key does), it is
-- ZeD's window, on screen, and a print reaches its log; shut again as found
Q.step(3, function()
    local DC = ZeD.DebugConsole
    A.dc = nil
    if not (DC and DC.open and DC.debug and DC.exists) then Q.check(false, "Lua console: ZeD.DebugConsole is loaded"); return end
    if not (DC.debug() and DC.exists()) then Q.skip("the Lua console", "the game is not in -debug, or its console is handed back"); return end
    A.dc = { was = DC.isOpen(), mark = "ZEDQA rt_addon console mark " .. tostring(getTimestampMs()) }
    pcall(DC.open)
end)
Q.waitFor(2, 120, function() return (not A.dc) or ZeD.DebugConsole.isOpen() end, function(ok)
    if not A.dc then return end
    Q.check(ok, "Lua console: it opens as ZeD's window")
    RT.bounds(Q, "the Lua console")
    print(A.dc.mark)
end)
Q.waitFor(2, 300, function()
    return (not A.dc) or string.find(tostring(ZeD.DebugConsole.text or ""), A.dc.mark, 1, true) ~= nil
end, function(ok)
    if not A.dc then return end
    Q.check(ok, "Lua console: a print reaches its log")
    if not A.dc.was then pcall(ZeD.DebugConsole.close) end
end)
Q.waitFor(2, 120, function() return (not A.dc) or A.dc.was or not ZeD.DebugConsole.isOpen() end, function(ok)
    if not A.dc then return end
    if not A.dc.was then Q.check(ok, "Lua console: closed again, as it was") end
    A.dc = nil
end)

-- ===================================================================== put back
Q.mark()
Q.step(2, function()
    mailBack()
    A.back()
    pcall(S.mdBack)
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
