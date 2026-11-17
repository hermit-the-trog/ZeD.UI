-- ZeDUI/tools/qa/grid_layout_sim.lua  (Nov 15 2026, add-on hooks): ZeD.GridLayout and ZeD.ItemRules, the public hooks
-- an add-on (ZeD Multi-Slot) uses to lay out ZeD's grid view and to refuse moves with a reason, with no game running.
-- It runs the real GridLayout.lua and ItemRules.lua, and InventoryRenderer's grid cell cut from the file, on stub
-- panels that record every draw.
--   SAME       no provider and no rule: drawGridCell and drawGridList draw exactly what they drew before the hooks
--              (the Nov 15 2026 code, frozen below as OLD_SRC): every rect, border, icon, word and hit zone, with a
--              selected cell, a hovered one, a stack, the pad's focus, a matched and a dimmed Filter cell. attach leaves
--              the column alone, modelFolds hands the folds back, filter hands the same list back, the X hold, the
--              wheel, a release and the pad's buttons are untouched; the windows' focus rects fall back to gcell
--   SPANS      a provider's 1 x 4 and 2 x 2 cells: drawn, hit-tested and focus-sized on the whole span; the icon grows
--              to fit, at most twice its square size; the spans in _itemRenderWMap / HMap
--   CELLS      a cell of several things draws as a stack (count, summed weight, carried by a drag); a cell's rep is
--              the selection, hover and focus key; a cell of an item ZeD does not list is left out
--   COLS       a provider wider than the column: the squares shrink to fit (no sideways scroll)
--   STRIPS     aside above the grid, overflow below in the warning colour with the warning mark, one square each;
--              headLine in the heading
--   FIXED      fixed rows: every empty square a faint slot
--   NET        a listed thing in no cell: a square of its own, first free
--   GROUPS     sorted by category and not flat: a heading per category, folds hide their cells
--   CACHE      layout is asked once per model, again after dirty(inv), dirty(nil), a resize or a fold; never per frame
--   GHOST      a mouse drag over the grid: the footprint centered on the square under the pointer, positive or danger
--              edge, the reason on the help line; R / the wheel turn (dragShape asked anew); the drop: same container
--              drop only, another container drop then ZeD's move, refused nothing and the reason kept
--   PAD        X hold on a cell: place mode from the cell's square; the D-pad moves a square, off the side onto the
--              next column's grid (same row); A turns; B cancels; letting go of X drops (another container: ZeD's
--              move); the help line's prompts; a cell in list view or a provider gone keeps the quick use
--   RULES      ItemRules: the first refusal wins (in the order registered); a drop and the band's moves leave refused
--              things where they are and say the first reason once; a rule that errors lets things go
--   ERRORS     a provider whose layout, decorate, dragShape or canPlace errors: logged once, ZeD's own grid, the draw
--              goes on
-- Run from the repo root:  lua51 ZeDUI/tools/qa/grid_layout_sim.lua
-- It prints FAIL lines and a last line "grid_layout_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]grid_layout_sim%.lua$", "")

-- The grid cell as it was on Nov 15 2026 before the add-on hooks (InventoryRenderer.lua at 15b3bd481, from
-- drawCellCondition to drawGridList), the reference for SAME: do not edit
local OLD_SRC = [==[
local function drawCellCondition(self, item, ax, cy, cell, stackInfo)
    local T = ZeD.T
    local IM = ZeD.ItemMeter
    local kind, f = IM.ofStack(item, stackInfo and stackInfo.count > 1 and stackInfo.items or nil)   -- (162)
    if kind == nil or kind == "hidden" then return cy + cell, false end
    local fc, graduated = IM.style(kind)
    local bh = T.px(5)
    local by = cy + cell - T.px(3) - bh
    local hov = ZeD.Atoms.drawFillBar(self, ax + T.px(3), by, cell - T.px(6), f, graduated, fc, bh, IM.label(kind))
    return by, hov
end

-- A stack's total weight, summed as vanilla's inventory sums a stack
-- (ISInventoryPane: getUnequippedWeight of each).
local function stackWeight(stackInfo)
    local total = 0
    for _, si in ipairs(stackInfo.items) do total = total + (si:getUnequippedWeight() or 0) end
    return total
end

-- A row's or a cell's weight: an item's own ("0.5"), a stack's total in
-- brackets ("(2.5)": five at 0.5; open the stack and each row shows its
-- own). A total wider than room in font drops its
-- decimal ("(120)"), then gives way to the item's own.
local function weightText(item, stackInfo, font, room)
    local unit = string.format("%.1f", item:getUnequippedWeight() or 0)
    if not (stackInfo and stackInfo.count > 1 and stackInfo.items) then return unit end
    local total = stackWeight(stackInfo)
    local s = "(" .. string.format("%.1f", total) .. ")"
    if room and ZeD.TM:MeasureStringX(font, s) > room then
        s = "(" .. string.format("%.0f", total) .. ")"
        if ZeD.TM:MeasureStringX(font, s) > room then return unit end
    end
    return s
end
ZeD.InventoryRenderer.weightText = weightText

-- The bracket's share of a weight column set px wide: what it holds past the
-- unit's width. COND and CAT drop on the column less this share, so the bracket
-- never drops a column; it takes its room from the name instead.
local function wtShare(cw, set)
    return math.max(0, math.min(cw.wtB - cw.wtU, set - cw.wtU))
end

-- The list's weight column for room px (the row less the icon, the paddings and
-- the other columns): its set width while the name keeps minName less the
-- bracket's share; past that the bracket gives way (a stack's row draws what
-- fits, see weightText), so it only gives way where the name, with the unit
-- alone, is already under minName. A column set under the unit's width (a drag)
-- is left as set.
local function wtFit(cw, set, room, minName)
    local share = wtShare(cw, set)
    local give = math.min(share, (minName - share) - (room - set))
    return set - math.max(0, give)
end

-- One cell: the icon, the stack's weight top right, its count bottom right, the
-- condition strip along the bottom, a BELT n key square; hover T.hover, selected
-- the T.selectionA wash, the controller's focus mark under the icon. Its hit zone
-- is the item itself, as a row's is.
local function drawGridCell(self, GV, item, cx, cy)
    local T = ZeD.T
    local cell, xOff = GV.cell, GV.xOff
    GV.ymap[item] = cy
    GV.xmap[item] = xOff + cx
    if cy + cell <= GV.top or cy >= GV.h then return end
    local ax = xOff + cx
    local ac, bs = T.accent, T.borderS
    local st = T.stripe
    self:drawRect(ax, cy, cell, cell, st.a, st.r, st.g, st.b)
    self:drawRectBorder(ax, cy, cell, cell, bs.a or 1, bs.r, bs.g, bs.b)
    local isSelected = GV.sel and GV.sel[item]
    -- the pointer (its name in a hint, and the help line) / the controller
    local over = GV.mouseIn and not cuesOn() and GV.lmx >= cx and GV.lmx < cx + cell and GV.my >= cy and GV.my < cy + cell
                 and GV.my >= GV.top and GV.my < GV.top + GV.visH
    if isSelected then
        self:drawRect(ax, cy, cell, cell, T.selectionA, ac.r, ac.g, ac.b)
    elseif over or (self._ccMarks and ccMarked(self, item)) then
        -- (rows a pointed-at Same type button would move read as pointed at too)
        local hv = T.hover
        self:drawRect(ax, cy, cell, cell, hv.a, hv.r, hv.g, hv.b)
    end
    local fo = gpFocusedItem(item, ZeD.playerNumOf(self))
    if fo then
        ZeD.Focus.mark(self, ax, cy, cell, cell, fo)
        local si = self._stacks and self._stacks[item]
        padTip(self, item, ax, cy, cell, cell, si and si.count or 1)
    end
    local stackInfo = self._stacks and self._stacks[item]
    local count = (stackInfo and stackInfo.count) or 1
    local tex = item:getTex()
    local isz = math.floor(cell * 32 / 52)
    -- the read mark (ReadMarks.lua): read items faded when "Dim read items" is on
    local rs = ZeD.ReadMarks.state(GV.player, item)
    if tex then
        local ia = (rs and rs.st == "r" and ZeD.ReadMarks.dimOn()) and 0.5 or 1
        self:drawTextureScaledAspect(tex, ax + math.floor((cell - isz) / 2), cy + math.floor((cell - isz) / 2), isz, isz, ia, 1, 1, 1)
    end
    -- condition, the framed strip along the bottom (the list's colours); a readable
    -- item shows its read mark instead, as the list's COND column does
    local condTop, condHov = cy + cell, false
    if not rs then condTop, condHov = drawCellCondition(self, item, ax, cy, cell, stackInfo) end
    -- on the belt: its key, top left (the list's BELT n tag), drawn below; measured here for the weight's room
    local f5 = T.fontF5
    local okAS, aslot = pcall(function() return item:getAttachedSlot() end)
    local k = okAS and aslot and aslot > 0 and ZeD.Belt and ZeD.Belt.keyLabel and tostring(ZeD.Belt.keyLabel(aslot) or aslot)
    local kw = k and math.max(ZeD.TM:MeasureStringX(f5, k) + T.px(6), GV.f5FH) or 0
    -- the weight, top right: the item's own, a stack's total in brackets (the grid opens no
    -- stacks: the card has each one's own); short of the key or the next level's arrow (ReadMarks.drawUp, 5 x 4)
    local leftW = (kw > 0 and kw + T.px(2) or 0) + ((rs and rs.next and ZeD.ReadMarks.nextOn()) and T.px(9) or 0)
    local wtStr = weightText(item, stackInfo, f5, cell - T.px(6) - leftW)
    local wtw = ZeD.TM:MeasureStringX(f5, wtStr)
    -- (the chips fill from the window's surface token, at the see-through value like the rest of
    -- the window: no literal alpha; they are small and sit over the cell, so they are not claimed)
    local s1 = T.surf1
    self:drawRect(ax + cell - wtw - T.px(5), cy + T.px(1), wtw + T.px(4), GV.f5FH, s1.a or 1, s1.r, s1.g, s1.b)
    local th = T.accentText or T.text
    self:drawText(wtStr, ax + cell - wtw - T.px(3), cy + T.px(1), th.r, th.g, th.b, th.a or 1, f5)
    -- the count, bottom right (above the condition strip)
    if count > 1 then
        local cs = "(" .. count .. ")"   -- (Nov 15 2026, the director: counts read as the game's, "(3)", like the totals' weight)
        local f1 = T.fontF1
        local cw2 = ZeD.TM:MeasureStringX(f1, cs)
        local cy2 = math.min(cy + cell - GV.secFH - T.px(4), condTop - GV.secFH - T.px(1))
        self:drawRect(ax + cell - cw2 - T.px(5), cy2, cw2 + T.px(4), GV.secFH, s1.a or 1, s1.r, s1.g, s1.b)
        local tc = T.text
        self:drawText(cs, ax + cell - cw2 - T.px(3), cy2, tc.r, tc.g, tc.b, tc.a or 1, f1)
    end
    -- the belt key (measured above)
    if k then
        self:drawRect(ax, cy, kw, GV.f5FH, ac.a or 1, ac.r, ac.g, ac.b)
        local tc = T.textOnAccent
        self:drawText(k, ax + math.floor((kw - ZeD.TM:MeasureStringX(f5, k)) / 2), cy, tc.r, tc.g, tc.b, 1, f5)
        GV._beltW = kw
    else
        GV._beltW = 0
    end
    -- read: the square mark in the free corner, bottom left; a book for the next level: the small arrow top left (after a BELT key)
    if rs then
        local RM = ZeD.ReadMarks
        local ms = RM.markSize()
        RM.drawMark(self, ax + T.px(3), cy + cell - ms - T.px(3), rs.st)
        if rs.next and RM.nextOn() then RM.drawUp(self, ax + T.px(2) + (GV._beltW > 0 and GV._beltW + T.px(2) or 0), cy + T.px(2)) end
    end
    queueMark(self, item, nil, nil, 0, ax, cy, cell, cell)   -- (waiting to move: the bar along its foot)
    if over then
        local nm = item:getName() or "?"
        if count > 1 then nm = nm .. " (" .. count .. ")" end
        self._gridHintCand = { key = item, text = nm, read = rs, x = ax, y = cy, w = cell, h = cell }
        if ZeD.InvTip and not cuesOn() then   -- (the loot card, Alt the game's tooltip: punch list 146)
            local r = _tipRect
            r.x, r.y, r.w, r.h = ax, cy, cell, cell
            ZeD.InvTip.want(self, item, r, count, true)   -- (beside the cell, not over it)
        end
        if not condHov then ZeD.Help.set(self, ZeD.tr("UI_ZeD_Inv_RowHelpLoot", nm)) end   -- (on the strip: its condition)
    end
    -- the Filter: a matched cell takes an accent edge while text is typed (a picture has no letters to underline);
    -- one that does not match dims in place, unless the controller is on it
    local fr = self._fres
    if fr then
        if fr.match[item] then
            if fr.ql ~= "" then ZeD.Atoms.frame(self, ax, cy, cell, cell, T.accent) end
        elseif not fo then
            filterDim(self, ax, cy, cell, cell)
        end
    end
    self:addHitZone(item, ax, cy, cell, cell)
end

-- A list of items as cells from y; returns the y after them
local function drawGridList(self, GV, list, y)
    local n = 0
    local top = y + GV.gap
    for _, item in ipairs(list or {}) do
        if not GV.child[item] then
            local c, r = n % GV.cols, math.floor(n / GV.cols)
            drawGridCell(self, GV, item, GV.padX + c * (GV.cell + GV.gap), top + r * (GV.cell + GV.gap))
            n = n + 1
        end
    end
    return y + gridH(GV, n)
end

-- END
]==]

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
-- STUBS (the engine and the ZeD parts the grid cell and the hooks read)
-- ---------------------------------------------------------------------------
local NOW = 100000
getTimestampMs = function() return NOW end
getText = function(k) return k end
local PRINTS = {}
local realPrint = print
print = function(s) if tostring(s):find("^ZeD%.") then PRINTS[#PRINTS + 1] = tostring(s) else realPrint(s) end end
local function rgb(r, g, b, a) return { r = r, g = g, b = b, a = a or 1 } end
Joypad = { AButton = 0, BButton = 1, XButton = 2 }
Keyboard = { KEY_R = 19 }
ZeD = {}
ZeD._trGen = 1
ZeD.T = {
    px = function(n) return n end, selectionA = 0.3, hair = 1,
    accent = rgb(0.3, 0.6, 0.5), borderS = rgb(0.4, 0.4, 0.4), border = rgb(0.3, 0.3, 0.3), stripe = rgb(0.1, 0.1, 0.1, 0.5),
    hover = rgb(1, 1, 1, 0.1), surf1 = rgb(0.2, 0.2, 0.2, 0.9), accentText = rgb(0.4, 0.7, 0.6), text = rgb(0.9, 0.9, 0.9),
    textOnAccent = rgb(0, 0, 0), positive = rgb(0, 1, 0), danger = rgb(1, 0, 0), warning = rgb(1, 0.8, 0),
    toneNorm = rgb(0.8, 0.8, 0.8), fontF1 = "F1", fontF5 = "F5",
}
ZeD.TM = {
    MeasureStringX = function(_, font, s) return #tostring(s) * 6 end,
    getFontHeight = function() return 12 end,
}
ZeD.tr = function(k, a) return a and (k .. ":" .. tostring(a)) or k end
local HELP = {}
ZeD.Help = { set = function(p, t) HELP[#HELP + 1] = t end }
local FRAMES = {}
ZeD.Atoms = {
    drawFillBar = function() return false end,
    frame = function(p, x, y, w, h, c, a, t) FRAMES[#FRAMES + 1] = { x = x, y = y, w = w, h = h, c = c, t = t }; if p.log then p.log[#p.log + 1] = string.format("frame %d %d %d %d", x, y, w, h) end end,
    drawStatusDot = function(p, x, y, c, sz) p.log[#p.log + 1] = "dot " .. ((c == ZeD.T.warning) and "warning" or "other") end,
}
ZeD.ItemMeter = { ofStack = function(item, items) if item._cond then return "cond", item._cond end return nil end,
                  style = function() return rgb(0, 1, 0), true end, label = function() return "Condition" end }
ZeD.ReadMarks = { state = function() return nil end, dimOn = function() return false end, nextOn = function() return false end }
ZeD.Focus = { mark = function(p, x, y, w, h) p.log[#p.log + 1] = string.format("focus %d %d %d %d", x, y, w, h) end }
ZeD.playerNumOf = function() return 0 end
local NOTES = {}
ZeD.Bubbles = { note = function(pn, t, tone) NOTES[#NOTES + 1] = { pn = pn, t = t, tone = tone } end }
-- the renderer's own locals the cut chunk reads (globals here)
cuesOn = function() return false end
ccMarked = function() return false end
local FOCUSED = nil
gpFocusedItem = function(item) return item == FOCUSED and "focus" or nil end
padTip = function() end
queueMark = function() end
filterDim = function(p, x, y, w, h) p.log[#p.log + 1] = string.format("dim %d %d %d %d", x, y, w, h) end
_tipRect = {}
gridH = function(GV, n) if n <= 0 then return 0 end return GV.gap + math.ceil(n / GV.cols) * (GV.cell + GV.gap) end

-- a panel that records every draw
local function mkPanel()
    local p = { log = {}, zones = {} }
    function p:drawRect(x, y, w, h, a, r, g, b) self.log[#self.log + 1] = string.format("rect %d %d %d %d %.2f", x, y, w, h, a or -1) end
    function p:drawRectBorder(x, y, w, h) self.log[#self.log + 1] = string.format("border %d %d %d %d", x, y, w, h) end
    function p:drawTextureScaledAspect(t, x, y, w, h, a) self.log[#self.log + 1] = string.format("tex %s %d %d %d %d %.2f", tostring(t), x, y, w, h, a) end
    function p:drawText(s, x, y) self.log[#self.log + 1] = string.format("text %s %d %d", s, x, y) end
    function p:addHitZone(id, x, y, w, h) self.zones[#self.zones + 1] = { id = id, x = x, y = y, w = w, h = h }; self.log[#self.log + 1] = string.format("zone %s %d %d %d %d", tostring(id), x, y, w, h) end
    return p
end

-- things and containers
local function mkInv(name) return { name = name, isInCharacterInventory = function() return false end, getType = function() return "crate" end } end
local function mkItem(name, wt, inv, cat)
    local it = { _name = name, _wt = wt, _inv = inv, _cat = cat or "Misc" }
    function it:getTex() return "tex_" .. self._name end
    function it:getName() return self._name end
    function it:getUnequippedWeight() return self._wt end
    function it:getAttachedSlot() return -1 end
    function it:getFullType() return "Base." .. self._name end
    function it:getContainer() return self._inv end
    function it:getDisplayCategory() return self._cat end
    function it:getCategory() return self._cat end
    return it
end

-- ---------------------------------------------------------------------------
-- LOAD: the old cell (frozen), the new one (cut from the file), the hooks
-- ---------------------------------------------------------------------------
ZeD.InventoryRenderer = {}   -- (the cut chunk hands weightText out on it)
local IR = readFile("42/media/lua/client/ZeD/InventoryRenderer.lua")
local function cutChunk(src, from, to, ret, name)
    local a = src:find(from, 1, true)
    local b = a and src:find(to, a, true)
    check("cut " .. name, a ~= nil and b ~= nil)
    return assert(loadstring(src:sub(a, b - 1) .. "\n" .. ret, name))()
end
local oldCell, oldList = cutChunk(OLD_SRC, "local function drawCellCondition(", "-- END", "return drawGridCell, drawGridList", "old cell")
local newCell, newList = cutChunk(IR, "local function drawCellCondition(", "-- The column's heading", "return drawGridCell, drawGridList", "new cell")

local CATS = {}
local IRT = {
    _drawGridCell = newCell,
    _drawCatRow = function(p, x, y, w, h, cat, n, closed) CATS[#CATS + 1] = { cat = cat, y = y, n = n, closed = closed } end,
    _containerKeyOf = function(inv) return inv and inv.name end,
    isGridKey = function(key) return key ~= "listview" end,
    catKey = function(it) return it._cat end,
    dragItems = function(content, rows) return rows end,
    dirtyModels = function() end,
}
for k, v in pairs(IRT) do ZeD.InventoryRenderer[k] = v end
dofile(ROOT .. "42/media/lua/client/ZeD/GridLayout.lua")
dofile(ROOT .. "42/media/lua/client/ZeD/ItemRules.lua")
local GL, RU = ZeD.GridLayout, ZeD.ItemRules

-- a grid state as renderItemList makes it (gridState, then the fields it stamps before the cells draw)
local function mkGV(cols, over)
    return { key = "crate", on = true, cell = 52, gap = 4, cols = cols or 5, child = {}, player = {}, toggles = {},
             xOff = 0, padX = 10, top = 0, h = 2000, visH = 2000, sel = {}, ymap = {}, xmap = {},
             mouseIn = over ~= nil, lmx = over and over[1] or -1, my = over and over[2] or -1, f5FH = 10, secFH = 12 }
end

-- ---------------------------------------------------------------------------
section("SAME (no provider, no rule)")
local CRATE = mkInv("crate")
local items = {}
for i = 1, 9 do items[i] = mkItem("Thing" .. i, i * 0.5, CRATE) end
items[3]._cond = 0.5
local function runList(fn, opts)
    local p = mkPanel()
    p._stacks = { [items[2]] = { count = 3, items = { items[2], items[2], items[2] } } }
    if opts.filter then p._fres = { match = { [items[1]] = true }, ql = "th" } end
    FOCUSED = opts.focus
    local GV = mkGV(4, opts.over)
    GV.sel[items[4]] = true
    fn(p, GV, items, 20)
    return p.log, GV
end
for _, o in ipairs({ {}, { over = { 75, 40 } }, { focus = items[5] }, { filter = true }, { over = { 20, 100 }, focus = items[1], filter = true } }) do
    local a, ga = runList(oldList, o)
    local b, gb = runList(newList, o)
    local same = #a == #b
    local first
    for i = 1, math.max(#a, #b) do if a[i] ~= b[i] then same = false; first = first or (tostring(a[i]) .. " / " .. tostring(b[i])) end end
    check("SAME: every draw and zone as before (" .. #a .. " calls)", same and #a > 40, first)
    local mapsSame = true
    for _, it in ipairs(items) do if ga.xmap[it] ~= gb.xmap[it] or ga.ymap[it] ~= gb.ymap[it] then mapsSame = false end end
    check("SAME: the cells' x / y maps as before", mapsSame)
end
FOCUSED = nil
-- the hooks with nothing registered
local p0 = mkPanel()
local GV0 = mkGV(5)
local M0 = { flatItems = items, stacks = {}, catOrder = {}, catOf = {} }
GL.attach(p0, GV0, M0, CRATE, {}, false, 24, 300)
check("SAME: attach without a provider: no layout", GV0.L == nil)
check("SAME: the column's own fields untouched", p0._flatItems == nil and p0._stacks == nil and p0._gridCell == nil and p0._itemRenderWMap == nil and GV0.cell == 52 and GV0.cols == 5)
local folds = { Food = true }
check("SAME: modelFolds hands the folds back", GL.modelFolds(folds, CRATE, {}) == folds)
check("SAME: ItemRules.filter hands the same list back", RU.filter(items, CRATE, {}, CRATE) == items)
local el0 = { item = items[1] }
GL.padButtons(el0)
check("SAME: an item cell gets no X-hold drag", el0.onHoldContextDrag == nil and el0.holdDragIf == nil and el0.onHoldContextRelease == nil)
check("SAME: a release, the wheel, the pad's buttons, the prompts: untouched",
    GL.takeDrop({}, items, CRATE) == false and GL.dragTurn() == false and GL.padButton(0, Joypad.AButton) == false and GL.padPrompts(0) == nil)
-- the windows read the spans only when an add-on's layout made them (else gcell, as before)
for _, f in ipairs({ "ZeD_CharacterWindow.lua", "ZeD_WorldWindow.lua" }) do
    local s = readFile("42/media/lua/client/ZeD/" .. f)
    local n = 0
    for _ in s:gmatch("RenderWMap and [%w%._]+RenderWMap%[item%]%) or gcell") do n = n + 1 end
    check("SAME: " .. f .. ": both grid focus rects fall back to gcell", n == 2, n)
end
local FM = readFile("42/media/lua/client/ZeD/Input/FocusManager.lua")
check("SAME: FocusManager: an element without holdDragIf drags as before", FM:find("el.onHoldContextDrag and (not el.holdDragIf or el.holdDragIf(", 1, true) ~= nil)
check("SAME: renderItemList: no layout, ZeD's own grid", IR:find("if self._gv.L then\n            -- (Nov 15 2026, add-on hooks: the add-on's layout draws its cells, spans and strips, GridLayout.lua)\n            y = ZeD.GridLayout.draw(self, self._gv, y, scrollX, catHdrH)\n        elseif useGroups then\n            y = drawGridGroups(", 1, true) ~= nil)

-- ---------------------------------------------------------------------------
section("SPANS / CELLS / STRIPS")
local BAG = mkInv("bag")
local rifle, jacket = mkItem("Rifle", 3.5, BAG, "Weapon"), mkItem("Jacket", 1.0, BAG, "Clothing")
local can1, can2, can3 = mkItem("Can", 0.6, BAG, "Food"), mkItem("Can", 0.6, BAG, "Food"), mkItem("Can", 0.6, BAG, "Food")
local hat, lost, stray = mkItem("Hat", 0.2, BAG, "Clothing"), mkItem("Lost", 0.1, BAG), mkItem("Stray", 0.1, mkInv("other"))
local bullets = mkItem("Bullets", 0.1, BAG, "Ammo")
local spare = mkItem("Spare", 0.3, BAG)
local LIST = { rifle, jacket, can1, hat, lost, bullets, spare }
local STK = { [can1] = { count = 3, items = { can1, can2, can3 } } }
local M1 = { flatItems = LIST, stacks = STK, catOrder = { "Weapon", "Clothing", "Food", "Misc", "Ammo" }, catOf = {} }
for _, it in ipairs({ rifle, jacket, can1, can2, can3, hat, lost, bullets, spare }) do M1.catOf[it] = it._cat end
local CALLS, CTX = 0, nil
local ANSWER = nil
local P = {
    layout = function(ctx)
        CALLS = CALLS + 1
        CTX = ctx
        return ANSWER(ctx)
    end,
}
local function answerA(ctx)
    return {
        cells = {
            { item = rifle, items = { rifle }, x = 0, y = 0, w = 1, h = 4 },
            { item = jacket, x = 1, y = 0, w = 2, h = 2 },
            { item = can1, items = { can1, can2 }, x = 3, y = 0, w = 1, h = 1 },   -- (two cans make one cell)
            { item = can3, x = 4, y = 0, w = 1, h = 1 },                         -- (the third its own square)
            { item = stray, x = 4, y = 1 },                                       -- (not listed: left out)
            { item = spare },                                                     -- (no x / y: first free)
        },
        aside = { { item = hat } },
        asideText = "Worn and held",
        overflow = { { item = bullets } },
        overflowText = "No room: move these out first",
        headLine = "9 / 20 squares",
    }
end
ANSWER = answerA
check("register: true", GL.register("ZeDMultiSlot", P) == true)
check("active: the provider", GL.active() == P)
local p1 = mkPanel()
local GV1 = mkGV(5)
GL.attach(p1, GV1, M1, BAG, {}, false, 24, 300)
local L = GV1.L
check("a layout", L ~= nil, PRINTS[#PRINTS])
check("ctx: every thing, one entry each, stacks not merged", CTX and #CTX.items == 9 and CTX.items[3] == can1 and CTX.items[5] == can3, CTX and #CTX.items)
check("ctx: inv, key, cols, stacks", CTX.inv == BAG and CTX.key == "crate" and CTX.cols == 5 and CTX.stacks == STK)
check("CELLS: the two cans are one cell of two", L.stacks[can1].count == 2 and L.stacks[can1].items[2] == can2)
check("CELLS: the third can its own cell", L.stacks[can3] and L.stacks[can3].count == 1)
check("CELLS: a thing ZeD does not list is left out", L.stacks[stray] == nil and L.kind[stray] == nil)
check("NET: the lost thing (in no cell) gets a square of its own", L.kind[lost] == "grid" and L.sqw[lost] == 1)
-- grid: rifle 0,0 1x4; jacket 1,0 2x2; cans at 3,0 / 4,0; spare first free = 3,1; lost next = 4,1
check("NET: a cell without x / y goes in the first free square", L.sqx[spare] == 3 and L.sqy[spare] == 1, tostring(L.sqx[spare]) .. "," .. tostring(L.sqy[spare]))
check("NET: the safety net after the others", L.sqx[lost] == 4 and L.sqy[lost] == 1, tostring(L.sqx[lost]) .. "," .. tostring(L.sqy[lost]))
check("SPANS: the rifle 52 x (4*52+3*4)", L.wmap[rifle] == 52 and L.hmap[rifle] == 220, L.wmap[rifle] .. "x" .. L.hmap[rifle])
check("SPANS: the jacket (2*52+4) square", L.wmap[jacket] == 108 and L.hmap[jacket] == 108)
check("SPANS: the column's maps are the layout's", p1._itemRenderWMap == L.wmap and p1._itemRenderHMap == L.hmap and p1._gridLayoutGen == L.serial)
check("CELLS: the column's list and stacks are the cells (drag, card, pad read them)", p1._flatItems == L.list and p1._invRowItems == L.list and p1._stacks == L.stacks)
check("STRIPS: the aside first, the overflow last in the list", L.list[1] == hat and L.list[#L.list] == bullets)
check("STRIPS: the aside above the grid", L.py[hat] < L.py[rifle] and L.asideHeadY == 0)
check("STRIPS: the overflow under the grid", L.py[bullets] > L.py[rifle] + L.hmap[rifle] and L.ovHeadY > L.gridTop)
check("STRIPS: headLine", L.headLine == "9 / 20 squares")
-- draw it
p1._stacks = L.stacks
local Y1 = GL.draw(p1, GV1, 30, 300, 24)
local function zoneOf(p, id) for _, z in ipairs(p.zones) do if z.id == id then return z end end end
local zr = zoneOf(p1, rifle)
check("SPANS: the rifle's hit zone is its whole span", zr and zr.w == 52 and zr.h == 220, zr and (zr.w .. "x" .. zr.h))
local zj = zoneOf(p1, jacket)
check("SPANS: the jacket's hit zone", zj and zj.w == 108 and zj.h == 108)
local logs = table.concat(p1.log, "\n")
-- icon: square 32 (52*32/52); rifle box 32 x min(220*32/52=135, 64) = 64; jacket min(66,64) = 64 both
check("SPANS: the rifle's icon grows to its span, at most twice", logs:find("tex tex_Rifle %d+ %d+ 32 64", 1) ~= nil)
check("SPANS: the jacket's icon at most twice its square size", logs:find("tex tex_Jacket %d+ %d+ 64 64", 1) ~= nil)
check("CELLS: the cans' cell counts two", logs:find("text %(2%)") ~= nil)
check("CELLS: and weighs both (1.2)", logs:find("text %(1%.2%)") ~= nil)
check("STRIPS: the aside heading", logs:find("text Worn and held", 1, true) ~= nil)
check("STRIPS: the overflow heading with the warning mark", logs:find("dot warning", 1, true) ~= nil and logs:find("text No room: move these out first", 1, true) ~= nil)
check("STRIPS: an overflow cell is one square", L.wmap[bullets] == 52 and L.hmap[bullets] == 52)
check("STRIPS: the cells stamped in the x / y maps", GV1.xmap[bullets] ~= nil and GV1.ymap[rifle] == 30 + L.py[rifle])
check("draw returns the y after the layout", Y1 == 30 + L.totalH, Y1)

section("COLS")
ANSWER = function(ctx) return { cols = ctx.cols + 3, cells = { { item = rifle, x = 0, y = 0, w = 1, h = 2 } } } end
GL.dirty(BAG)
local GV2 = mkGV(5)
GL.attach(mkPanel(), GV2, M1, BAG, {}, false, 24, 292)
local L2 = GV2.L
check("COLS: 8 across", L2.cols == 8 and GV2.cols == 8)
check("COLS: the squares shrink to fit the column", L2.cell < 52 and 8 * L2.cell + 7 * L2.gap <= 292, L2.cell)
check("COLS: the column's cell size follows (the pad's rects)", GV2.cell == L2.cell)

section("FIXED")
ANSWER = function(ctx) return { cols = 4, rows = 3, fixed = true, flat = true, cells = { { item = rifle, x = 0, y = 0, w = 1, h = 3 }, { item = jacket, x = 2, y = 1, w = 2, h = 2 } } } end
GL.dirty(BAG)
local GV3 = mkGV(5)
GL.attach(mkPanel(), GV3, M1, BAG, {}, false, 24, 300)
local L3 = GV3.L
-- 12 squares, rifle 3, jacket 4, the safety net puts the 7 others (cans 3, hat, lost, bullets, spare) as 1x1 first free:
-- free were 5 -> 2 more rows
check("FIXED: rows at least 3", L3.rows >= 3)
local occ = 0
for _, rep in ipairs(L3.list) do occ = occ + L3.sqw[rep] * L3.sqh[rep] end
check("FIXED: every empty square a slot", #L3.empties == L3.rows * 4 - occ, #L3.empties .. " vs " .. (L3.rows * 4 - occ))
local p3 = mkPanel()
FRAMES = {}
GL.draw(p3, GV3, 0, 300, 24)
check("FIXED: the slots drawn as faint frames", #FRAMES >= #L3.empties and FRAMES[1].c == ZeD.T.border)

section("GROUPS")
ANSWER = function(ctx) return { cells = { { item = rifle, x = 0, y = 0, w = 1, h = 2 }, { item = jacket, w = 2, h = 2 } } } end
GL.dirty(BAG)
local p4 = mkPanel()
p4._collapsedGroups = { Food = true }
local GV4 = mkGV(5)
GL.attach(p4, GV4, M1, BAG, {}, true, 24, 300)
local L4 = GV4.L
check("GROUPS: a heading per category", #L4.heads == 5, #L4.heads)
local food
for _, h in ipairs(L4.heads) do if h.cat == "Food" then food = h end end
check("GROUPS: the folded Food: its heading closed, its cans not in the list", food and food.closed and L4.kind[can1] and (function() for _, r in ipairs(L4.list) do if r == can1 then return false end end return true end)())
CATS = {}
GL.draw(p4, GV4, 0, 300, 24)
check("GROUPS: the headings drawn", #CATS == 5 and CATS[1].cat == "Weapon")
check("GROUPS: not flat (no ghost, no place mode)", L4.flat == false)
local foldCalls = CALLS
GL.attach(p4, GV4, M1, BAG, {}, true, 24, 300)
check("CACHE: the same folds: no new layout", CALLS == foldCalls)
p4._collapsedGroups = {}
GL.attach(p4, mkGV(5), M1, BAG, {}, true, 24, 300)
check("CACHE: a fold opened: a new layout", CALLS == foldCalls + 1)

section("CACHE")
ANSWER = answerA
GL.dirty(BAG)
local p5 = mkPanel()
local n0 = CALLS
for f = 1, 30 do
    local g = mkGV(5)
    GL.attach(p5, g, M1, BAG, {}, false, 24, 300)
    GL.draw(p5, g, 0, 300, 24)
end
check("CACHE: 30 frames, one layout", CALLS == n0 + 1, CALLS - n0)
GL.dirty(BAG)
GL.attach(p5, mkGV(5), M1, BAG, {}, false, 24, 300)
check("CACHE: dirty(inv): a new layout", CALLS == n0 + 2)
GL.dirty(mkInv("elsewhere"))
GL.attach(p5, mkGV(5), M1, BAG, {}, false, 24, 300)
check("CACHE: another container's dirty: kept", CALLS == n0 + 2)
GL.dirty()
GL.attach(p5, mkGV(5), M1, BAG, {}, false, 24, 300)
check("CACHE: dirty(nil): a new layout", CALLS == n0 + 3)
local M1b = { flatItems = M1.flatItems, stacks = STK, catOrder = M1.catOrder, catOf = M1.catOf }
GL.attach(p5, mkGV(5), M1b, BAG, {}, false, 24, 300)
check("CACHE: the model rebuilt: a new layout", CALLS == n0 + 4)
GL.attach(p5, mkGV(5), M1b, BAG, {}, false, 24, 260)
check("CACHE: the column resized: a new layout", CALLS == n0 + 5)
local gList = mkGV(5)
gList.on = false
GL.attach(p5, gList, M1b, BAG, {}, false, 24, 260)
check("CACHE: list view: no layout, the spans gone", gList.L == nil and p5._itemRenderWMap == nil and p5._gridLayoutGen == nil and CALLS == n0 + 5)
check("modelFolds: a grid with a provider: no folds (every thing is handed over)", GL.modelFolds(folds, BAG, {}) ~= folds)
check("modelFolds: list view keeps the folds", GL.modelFolds(folds, { name = "listview" }, {}) == folds)

section("GHOST (mouse)")
ANSWER = function(ctx) return { cols = 5, rows = 4, flat = true, cells = { { item = rifle, x = 0, y = 0, w = 1, h = 4 } } } end
GL.dirty(BAG)
local SHAPE, ASKS, TURNS, DROPS = { 1, 3 }, 0, 0, {}
local REFUSE = nil
P.dragShape = function(its, ctx) return SHAPE[1], SHAPE[2] end
P.canPlace = function(its, ctx, x, y, w, h) ASKS = ASKS + 1; if REFUSE then return false, REFUSE end return true end
P.turn = function(its, ctx) TURNS = TURNS + 1; SHAPE = { SHAPE[2], SHAPE[1] } end
P.drop = function(its, ctx, x, y, src) DROPS[#DROPS + 1] = { items = its, inv = ctx.inv, x = x, y = y, src = src }; return true end
local SRC = mkPanel()
local DRAG = { items = { jacket }, isActive = function() return true end }
SRC._drag, SRC._dragSourceInv = DRAG, BAG
ZeD_CharacterWindow = { getWindow = function() return { _contentPanel = SRC } end }
ZeD_WorldWindow = { getWindow = function() return nil end }
local pg = mkPanel()
-- square (2, 1): grid top 0, gap 4: x = 10 + 2*56 + 5, y = 4 + 1*56 + 5
local function frameDraw(over)
    local g = mkGV(5, over)
    GL.attach(pg, g, M1, BAG, {}, false, 24, 300)
    FRAMES, HELP = {}, {}
    GL.draw(pg, g, 0, 300, 24)
    return g
end
frameDraw({ 10 + 2 * 56 + 5, 4 + 1 * 56 + 5 })
local gh = FRAMES[#FRAMES]
-- 1 x 3 centered on (2,1): top-left (2, 0)
check("GHOST: the footprint centered on the square under the pointer", gh and gh.x == 10 + 2 * 56 and gh.y == 4 and gh.w == 52 and gh.h == 3 * 52 + 2 * 4, gh and (gh.x .. "," .. gh.y .. " " .. gh.w .. "x" .. gh.h))
check("GHOST: ok: the positive edge, 2 units", gh and gh.c == ZeD.T.positive and gh.t == 2)
local asks = ASKS
frameDraw({ 10 + 2 * 56 + 5, 4 + 1 * 56 + 5 })
check("GHOST: the same square: canPlace not asked again", ASKS == asks)
REFUSE = "No room for Jacket"
GL.dirty(BAG)   -- (a new layout: asked anew)
frameDraw({ 10 + 2 * 56 + 5, 4 + 1 * 56 + 5 })
gh = FRAMES[#FRAMES]
check("GHOST: refused: the danger edge", gh and gh.c == ZeD.T.danger)
check("GHOST: the reason on the help line", HELP[#HELP] == "No room for Jacket")
REFUSE = nil
GL.dirty(BAG)
frameDraw({ 10 + 2 * 56 + 5, 4 + 1 * 56 + 5 })
check("TURN: the wheel / R turn while over the grid", GL.dragTurn() == true and TURNS == 1)
frameDraw({ 10 + 2 * 56 + 5, 4 + 1 * 56 + 5 })
gh = FRAMES[#FRAMES]
check("TURN: dragShape asked anew: 3 x 1, centered", gh and gh.w == 3 * 52 + 8 and gh.h == 52 and gh.x == 10 + 1 * 56 and gh.y == 4 + 56, gh and (gh.x .. "," .. gh.y .. " " .. gh.w .. "x" .. gh.h))
-- R on the keyboard: GridLayout listens on OnKeyPressed and calls the same dragTurn (no Events here)
-- drop: same container
local r1 = GL.takeDrop(SRC, { jacket }, BAG)
check("DROP: the same container: drop, nothing else", r1 == true and #DROPS == 1 and DROPS[1].x == 1 and DROPS[1].y == 1 and DROPS[1].src == BAG)
check("DROP: used once (a second call for the same release finds nothing)", GL.takeDrop(SRC, { jacket }, BAG) == false and #DROPS == 1)
frameDraw({ 10 + 0 * 56 + 5, 4 + 3 * 56 + 5 })
local CR2 = mkInv("crate2")
local r2 = GL.takeDrop(SRC, { jacket }, CR2)
check("DROP: from another container: drop first, then ZeD's usual move", r2 == false and #DROPS == 2 and DROPS[2].src == CR2)
REFUSE = "Bag full"
GL.dirty(BAG)
frameDraw({ 10 + 0 * 56 + 5, 4 + 0 * 56 + 5 })
local r3 = GL.takeDrop(SRC, { jacket }, CR2)
check("DROP: refused: no drop, no move", r3 == true and #DROPS == 2)
HELP = {}
local gk = mkGV(5)
GL.attach(pg, gk, M1, BAG, {}, false, 24, 300)
DRAG.isActive = function() return false end
GL.draw(pg, gk, 0, 300, 24)
check("DROP: the reason stays on that list's help line a moment", HELP[#HELP] == "Bag full")
NOW = NOW + 5000
HELP = {}
GL.draw(pg, gk, 0, 300, 24)
check("DROP: then goes", #HELP == 0)
REFUSE = nil
local offTurns = TURNS
check("TURN: no drag over a grid: the wheel scrolls as before", GL.dragTurn() == false and TURNS == offTurns)

section("PAD (place mode)")
ANSWER = function(ctx)
    if ctx.inv == BAG then return { cols = 5, rows = 4, flat = true, cells = { { item = rifle, x = 1, y = 0, w = 1, h = 4 } } } end
    return { cols = 3, rows = 4, flat = true, cells = {} }
end
GL.dirty()
SHAPE = { 1, 4 }
local cnt = mkPanel()
cnt._playerObj = { getInventory = function() return "playerinv" end, getPlayerNum = function() return 0 end }
local CRATE2 = mkInv("crate2b")
local M2 = { flatItems = {}, stacks = {}, catOrder = {}, catOf = {} }
cnt._colStates = { { inventory = BAG }, { inventory = CRATE2 } }
GL.attach(cnt, mkGV(5), M1, BAG, {}, false, 24, 300)
GL.attach(cnt, mkGV(3), M2, CRATE2, {}, false, 24, 200)
local W = { _mainContent = cnt }
local el = { item = rifle, colIdx = 1 }
GL.padButtons(el)
check("PAD: a cell gets the X hold's drag with a provider", el.onHoldContextDrag == GL.padDrag and el.onHoldContextRelease == GL.padRelease and el.holdDragIf == GL.padCan)
check("PAD: holdDragIf yes on a cell of a single grid", GL.padCan(W, el) == true)
check("PAD: holdDragIf no on a thing in list view (the quick use stays)", GL.padCan({ _mainContent = mkPanel() }, el) == false)
GL.padDrag(W, el, nil)
local S = GL._pad[0]
check("PAD: place mode starts at the cell's own square", S and S.x == 1 and S.y == 0 and S.w == 1 and S.h == 4)
check("PAD: the help line's prompts", (function() local pr = GL.padPrompts(0); return pr and #pr == 4 and pr[1].glyph == "D-PAD" and pr[2].glyph == "A" and pr[3].glyph == "X" and pr[3].label == "UI_ZeD_Grid_PromptPlace" and pr[4].glyph == "B" end)())
GL.padDrag(W, el, "right")
check("PAD: D-pad right: a square", S.x == 2 and S.y == 0)
GL.padDrag(W, el, "down")
check("PAD: down is held inside the fixed rows (1 x 4 in 4 rows)", S.y == 0)
check("PAD: A turns", GL.padButton(0, Joypad.AButton) == true and S.w == 4 and S.h == 1, S.w .. "x" .. S.h)
check("PAD: turned, kept inside the columns", S.x == 1, S.x)
GL.padDrag(W, el, "down")
check("PAD: down a square", S.y == 1)
GL.padButton(0, Joypad.AButton)   -- (1 x 4 again)
check("PAD: turned back, kept inside the fixed rows", S.w == 1 and S.h == 4 and S.y == 0, S.y)
GL.padDrag(W, el, "right"); GL.padDrag(W, el, "right"); GL.padDrag(W, el, "right")
check("PAD: right to the column's edge", S.x == 4 and S.L.ctx.inv == BAG, S.x)
GL.padDrag(W, el, "right")
check("PAD: off the side: the next column's grid, its first square, the same row", S.L.ctx.inv == CRATE2 and S.x == 0 and S.y == 0, tostring(S.x) .. "," .. tostring(S.y))
GL.padDrag(W, el, "left")
check("PAD: back off its left side: the first column's last square", S.L.ctx.inv == BAG and S.x == 4)
-- the ghost draws on the place mode's column
local gp = mkGV(5)
GL.attach(cnt, gp, M1, BAG, {}, false, 24, 300)
FRAMES = {}
GL.draw(cnt, gp, 0, 300, 24)
gh = FRAMES[#FRAMES]
check("PAD: the ghost on the column", gh and gh.x == 10 + 4 * 56 and gh.c == ZeD.T.positive)
-- (Nov 15 2026, the add-on's first run: the list scrolls to keep the ghost in view, pinning only when it moved)
local SC = { scrollPos = 0 }
function SC:setScrollPos(v) self.scrollPos = v end
GL.followPad(cnt, BAG, SC, 2000, 60, 0)
local gBottom = S.gridY + S.h * S.L.cell + (S.h - 1) * S.L.gap
check("PAD: follow: a ghost below the view scrolls it into view", SC.scrollPos > 0 and math.abs(SC.scrollPos * 1940 - (gBottom - 60)) < 1,
    tostring(SC.scrollPos * 1940) .. " want " .. tostring(gBottom - 60))
SC.scrollPos = 0
GL.followPad(cnt, BAG, SC, 2000, 60, 0)
check("PAD: follow: no re-pin while the ghost stays put (a wheel past it is not pulled back)", SC.scrollPos == 0)
GL.followPad(cnt, CRATE2, SC, 2000, 60, 0)
check("PAD: follow: another column's list is left alone", SC.scrollPos == 0)
-- (scrolled to the end, the ghost last drew 500 px above the view's top)
S.pinX, S.gridY = nil, -500
SC.scrollPos = 1
GL.followPad(cnt, BAG, SC, 2000, 60, 0)
check("PAD: follow: a ghost above the view scrolls up to it", math.abs(SC.scrollPos * 1940 - (1940 - 500)) < 1, tostring(SC.scrollPos * 1940))
check("PAD: the renderer asks GridLayout to follow the ghost beside the row's follow",
    IR:find("ZeD.GridLayout.followPad(self, inv, scroll, totalContentH, visibleH, contentTop)", 1, true) ~= nil)
-- B cancels
check("PAD: B cancels", GL.padButton(0, Joypad.BButton) == true and GL._pad[0] == nil and GL.padPrompts(0) == nil)
local nd = #DROPS
GL.padRelease(W, el)
check("PAD: letting go after B: nothing", #DROPS == nd)
-- a release into the same container: drop only
GL.padDrag(W, el, nil)
GL.padDrag(W, el, "right")
GL.padRelease(W, el)
check("PAD: letting go of X: drop at the ghost's square", #DROPS == nd + 1 and DROPS[#DROPS].x == 2 and DROPS[#DROPS].inv == BAG and GL._pad[0] == nil)
-- into the next column: drop, then ZeD's move
local MOVES = {}
ZeD.ContainerControls = {
    moveItems = function(pl, its, dest) MOVES[#MOVES + 1] = { how = "move", dest = dest, n = #its } end,
    grabItems = function(pl, its, dest) MOVES[#MOVES + 1] = { how = "grab", dest = dest, n = #its } end,
}
GL.padDrag(W, el, nil)
for i = 1, 5 do GL.padDrag(W, el, "right") end
GL.padRelease(W, el)
check("PAD: into the next column: drop there, then ZeD's move", DROPS[#DROPS].inv == CRATE2 and #MOVES == 1 and MOVES[1].dest == CRATE2 and MOVES[1].how == "grab")
-- refused: a note over the head, no drop
REFUSE = "No room"
NOTES = {}
GL.padDrag(W, el, nil)
local ndr = #DROPS
GL.padRelease(W, el)
check("PAD: refused: nothing moves, the reason over the head", #DROPS == ndr and NOTES[1] and NOTES[1].t == "No room" and NOTES[1].tone == "bad")
REFUSE = nil
-- the pad's hold dropped mid-way (FocusManager's _dropHolds): nothing placed
GL.padDrag(W, el, nil)
GL.padCancel(0)
check("PAD: a hold cut short: place mode ends", GL._pad[0] == nil)
check("PAD: FocusManager ends it on a dropped hold, and asks GridLayout first for A / B",
    FM:find("ZeD.GridLayout.padCancel(s.pn)", 1, true) ~= nil and FM:find("ZeD.GridLayout.padButton(pn, button)", 1, true) ~= nil)
check("PAD: the D-pad goes to the drag only once a drag was armed", FM:find("s.xHeld and s.xUsed and s.xDrag and s.xEl", 1, true) ~= nil)

section("RULES")
local order = {}
RU.register("a", { canPut = function(item, dest) order[#order + 1] = "a"; if item == can1 then return false, "A says no" end return true end })
RU.register("b", { canPut = function(item, dest) order[#order + 1] = "b"; if item == can1 or item == hat then return false, "B says no" end return true end })
local okc, why = RU.check(can1, BAG, nil, CRATE)
check("RULES: the first refusal wins, in the order registered", okc == false and why == "A says no" and order[#order] == "a")
okc, why = RU.check(hat, BAG, nil, CRATE)
check("RULES: the second rule's refusal", okc == false and why == "B says no")
check("RULES: allowed", (RU.check(rifle, BAG, nil, CRATE)) == true)
NOTES = {}
local PL = { getPlayerNum = function() return 0 end }
local kept = RU.filter({ rifle, can1, hat, jacket }, BAG, PL, CRATE)
check("RULES: a move leaves refused things where they are", #kept == 2 and kept[1] == rifle and kept[2] == jacket)
check("RULES: the first reason, once, over the head", #NOTES == 1 and NOTES[1].t == "A says no" and NOTES[1].tone == "bad")
local all = { rifle, jacket }
check("RULES: nothing refused: the same list", RU.filter(all, BAG, PL, CRATE) == all)
-- the band's moves (ContainerControls.moveItems, cut from the file): refused things stay
local CC = readFile("42/media/lua/client/ZeD/ContainerControls.lua")
local QUEUED = {}
ISTimedActionQueue = { add = function(a) QUEUED[#QUEUED + 1] = a end }
ISInventoryTransferUtil = { newInventoryTransferAction = function(pl, it, s, d) return { item = it, dest = d } end }
ZeD.ContainerGates = { refuses = function() return false end }
local CTm = {}
local env = setmetatable({ CT = CTm, isFloor = function(i) return i and i.floor end, zedFloor = function() return nil end,
    sortForTransfer = function() end, corpseStorageCheck = nil }, { __index = _G })
-- (the file's CT.moveItems, run in a table that holds its own file's locals: it defines CTm.moveItems)
local mvA, mvB = CC:find("function CT.moveItems(", 1, true), CC:find("-- Take all:", 1, true)
check("cut moveItems", mvA ~= nil and mvB ~= nil)
local fnChunk = assert(loadstring(CC:sub(mvA, mvB - 1), "moveItems"))
setfenv(fnChunk, env)
fnChunk()
for _, it in ipairs({ rifle, can1, hat, jacket }) do it._inv = CRATE end
CRATE.isItemAllowed = function() return true end
BAG.isItemAllowed = function() return true end
NOTES = {}
CTm.moveItems({ getPlayerNum = function() return 0 end }, { rifle, can1, hat, jacket }, BAG)
check("RULES: the band's moves (Take all, Transfer all, Same type, the pad's X grab): refused things stay", #QUEUED == 2 and QUEUED[1].item == rifle and QUEUED[2].item == jacket, #QUEUED)
check("RULES: the band's move says the first reason once", #NOTES == 1 and NOTES[1].t == "A says no")
-- the drag over another list: the reason on the help line
HELP = {}
DRAG.isActive = function() return true end
DRAG.items = { can1 }
SRC._dragSourceInv = CRATE
local pl = mkPanel()
pl._gv = { mouseIn = true }
RU.dragOver(pl, BAG)
check("RULES: dragged over a list it refuses: the reason on the help line", HELP[#HELP] == "A says no")
HELP = {}
RU.dragOver(pl, CRATE)
check("RULES: over its own list: nothing", #HELP == 0)
-- a rule that errors lets things go, logged once
RU.unregister("a"); RU.unregister("b")
RU.register("bad", { canPut = function() error("boom") end })
PRINTS = {}
check("RULES: a rule that errors lets things go", (RU.check(can1, BAG, nil, CRATE)) == true and (RU.check(hat, BAG, nil, CRATE)) == true)
check("RULES: its error logged once", #PRINTS == 1, #PRINTS)
RU.unregister("bad")
check("RULES: none left: the same list back", RU.filter(all, BAG, PL, CRATE) == all and RU.any() == false)

section("ERRORS")
PRINTS = {}
local BAD = { layout = function() error("layout broke") end }
GL.register("Broken", BAD)
check("ERRORS: a second provider logs a line and wins", GL.active() == BAD and PRINTS[1] and PRINTS[1]:find("replaces") ~= nil)
local pe = mkPanel()
pe._gridLayoutGen = 5
local ge = mkGV(5)
local ok1 = pcall(GL.attach, pe, ge, M1, BAG, {}, false, 24, 300)
check("ERRORS: layout errors: no error out of attach, ZeD's own grid", ok1 and ge.L == nil and pe._gridLayoutGen == nil and ge.cell == 52)
GL.attach(pe, mkGV(5), M1, BAG, {}, false, 24, 300)
local nlog = 0
for _, s in ipairs(PRINTS) do if s:find("layout failed") then nlog = nlog + 1 end end
check("ERRORS: logged once", nlog == 1, nlog)
check("ERRORS: its own grid keeps the folds (modelFolds)", GL.modelFolds(folds, BAG, {}, pe) == folds)
BAD.layout = function() return "nonsense" end
GL.dirty()
GL.attach(pe, ge, M1, BAG, {}, false, 24, 300)
check("ERRORS: an answer that is not a table: ZeD's own grid", ge.L == nil)
BAD.layout = function() return { cells = { { item = rifle, x = "a", y = {}, w = "wide" }, 7, { item = 3 } }, cols = "x" } end
GL.dirty()
local gw = mkGV(5)
GL.attach(pe, gw, M1, BAG, {}, false, 24, 300)
check("ERRORS: a malformed answer: drawn as far as it makes sense (the rest first free)", gw.L ~= nil and gw.L.sqw[rifle] == 1 and gw.L.kind[jacket] == "grid")
BAD.layout = answerA
BAD.decorate = function() error("decorate broke") end
BAD.dragShape = function() error("shape broke") end
BAD.canPlace = function() error("place broke") end
GL.dirty()
local gd = mkGV(5, { 10 + 5, 24 + 60 + 4 + 5 })   -- (under the aside strip: its heading 24, its row 60)
GL.attach(pe, gd, M1, BAG, {}, false, 24, 300)
DRAG.items = { jacket }
SRC._dragSourceInv = BAG
local okd = pcall(GL.draw, pe, gd, 0, 300, 24)
check("ERRORS: decorate, dragShape and canPlace errors: the draw goes on", okd and #pe.zones >= #gd.L.list)
local nDec = 0
for _, s in ipairs(PRINTS) do if s:find("decorate failed") then nDec = nDec + 1 end end
GL.draw(pe, gd, 0, 300, 24)
check("ERRORS: decorate logged once", nDec == 1)
check("ERRORS: dragShape / canPlace failing: a 1 x 1 ghost, allowed", GL._over.w == 1 and GL._over.h == 1 and GL._over.ok == true)
GL.unregister("ZeDMultiSlot")
check("unregister: only its own id", GL.active() == BAD)
GL.unregister("Broken")
check("unregister: gone", GL.active() == nil)
local gu = mkGV(5)
GL.attach(pe, gu, M1, BAG, {}, false, 24, 300)
check("unregister: ZeD's own grid again", gu.L == nil and pe._itemRenderWMap == nil)
check("VERSION", GL.VERSION == 2)
check("register refuses a provider with no layout", GL.register("x", {}) == false and GL.active() == nil)

-- ---------------------------------------------------------------------------
-- (Nov 16 2026, Multi-Slot 0.2) VERSION 2: shaped cells. Everything above is a version 1 provider and still passes.
section("SHAPES (version 2)")
local AXE = "XXX/XXX/X../X../X../X.."
local aw, ah, ahas = GL.parseMask(AXE)
local na = 0
for _ in pairs(ahas or {}) do na = na + 1 end
check("MASK: the axe is 3 x 6, ten squares", aw == 3 and ah == 6 and na == 10, tostring(aw) .. "x" .. tostring(ah) .. " " .. na)
check("MASK: the head's squares and the handle's, the holes empty", ahas[0] and ahas[5] and ahas[6] and ahas[15] and not ahas[7] and not ahas[17])
local tw, th = GL.parseMask("..X/..X/...")
check("MASK: empty edges trimmed", tw == 1 and th == 2)
check("MASK: no squares, or not words: nil", GL.parseMask("...") == nil and GL.parseMask(nil) == nil and GL.parseMask(5) == nil)
local g = GL.geom(ahas, aw, ah, 10, 2, 1)
check("GEOM: ten squares filled", g.n == 10 and #g.fill == 40)
check("GEOM: the first square top left; the last the handle's foot", g.fx == 0 and g.fy == 0 and g.ix == 0 and g.iy == 5 * 12)
check("GEOM: the weight at the top row's run's end (three squares)", g.wx == 2 * 12 and g.wy == 0 and g.wroom == 2 * 12)
-- the outline closes: a raster of the shape (its squares and gaps) and of its edges
local function raster(list)
    local s = {}
    for k = 1, #list, 4 do
        for y = list[k + 1], list[k + 1] + list[k + 3] - 1 do
            for x = list[k], list[k] + list[k + 2] - 1 do s[y * 1000 + x] = true end
        end
    end
    return s
end
local function outlineOk(geo)
    local R, E = raster(geo.hits), raster(geo.edges)
    local missing, outside = 0, 0
    for p in pairs(R) do
        local y = math.floor(p / 1000)
        local x = p - y * 1000
        local edge = false
        for dy = -1, 1 do for dx = -1, 1 do if not R[(y + dy) * 1000 + x + dx] then edge = true end end end
        if edge and not E[p] then missing = missing + 1 end
    end
    for p in pairs(E) do if not R[p] then outside = outside + 1 end end
    return missing == 0 and outside == 0, missing .. " missing, " .. outside .. " outside"
end
local okO, whyO = outlineOk(g)
check("GEOM: the axe's outline closes all round, concave corners too, never outside it", okO, whyO)
for _, m in ipairs({ "XX/X.", "XXX/.X./.X./.X.", "XXXXXX/XXX...", "X", "XXX/X.X/XXX", "XXXXX/..X../..X.." }) do
    local w2, h2, has2 = GL.parseMask(m)
    local ok2, why2 = outlineOk(GL.geom(has2, w2, h2, 10, 2, 1))
    check("GEOM: " .. m .. " outline closes", ok2, why2)
end
local gp2 = GL.geom(select(3, GL.parseMask("XX/X.")), 2, 2, 10, 2, 1)
local cornerIn = false
for k = 1, #gp2.gaps, 4 do if gp2.gaps[k] == 10 and gp2.gaps[k + 1] == 10 then cornerIn = true end end
check("GEOM: where three squares meet the corner gap is filled (the L's inside corner)", cornerIn)
check("GEOM: the pistol's weight on its two-square top row", gp2.wx == 12 and gp2.wroom == 12)
local gk2 = GL.geom(select(3, GL.parseMask("X/X")), 1, 2, 10, 2, 1)
check("GEOM: a one-wide shape: the weight on its last square", gk2.wx == 0 and gk2.wy == 12 and gk2.wroom == 10)
-- colsAt
check("colsAt: 300 px, 52 squares at two thirds (34), gap 4: 8 across", GL.colsAt({ avail = 300, cell = 52, gap = 4 }, 2 / 3) == 8)

-- a shaped layout: an axe, a small thing in the hole beside its handle, a block, the strips
local SBAG = mkInv("sbag")
local axe, nut, box, worn = mkItem("Axe", 3, SBAG, "Weapon"), mkItem("Nut", 0.1, SBAG), mkItem("Box", 1, SBAG), mkItem("Worn", 0.2, SBAG)
local SL = { axe, nut, box, worn }
local MS = { flatItems = SL, stacks = {}, catOrder = {}, catOf = {} }
local SP = {}
local DRAGMASK, CANMASK = AXE, "unset"
SP.layout = function(ctx)
    return { flat = true, shapes = true, scale = 2 / 3, cols = 6, rows = 6, fixed = true,
             cells = { { item = axe, x = 0, y = 0, mask = AXE, w = 9, h = 9 },
                       { item = nut, x = 1, y = 2 },
                       { item = box, w = 2, h = 2 } },
             aside = { { item = worn } }, asideText = "On you" }
end
SP.dragShape = function(its, ctx) if DRAGMASK then local w2, h2 = GL.parseMask(DRAGMASK); return w2, h2, DRAGMASK end return 1, 1 end
SP.canPlace = function(its, ctx, x, y, w, h, mask) CANMASK = mask; return true end
GL.register("ZeDMultiSlot", SP)
local ps = mkPanel()
local gs = mkGV(5)
GL.attach(ps, gs, MS, SBAG, {}, false, 24, 300)
local LS = gs.L
check("LAYOUT: made", LS ~= nil, PRINTS[#PRINTS])
check("LAYOUT: the mask sets the box (c.w / c.h not read)", LS.sqw[axe] == 3 and LS.sqh[axe] == 6)
check("LAYOUT: the small thing sits in the hole beside the handle", LS.sqx[nut] == 1 and LS.sqy[nut] == 2)
check("LAYOUT: the block first-fit beside the head, never over the axe", LS.sqx[box] == 3 and LS.sqy[box] == 0, tostring(LS.sqx[box]) .. "," .. tostring(LS.sqy[box]))
check("LAYOUT: two thirds of ZeD's square (52 -> 34)", LS.cell == 34 and gs.cell == 34)
check("LAYOUT: the picture: ZeD's size, less in a small square", LS.isz == math.min(32, math.floor(34 * 0.8)))
check("LAYOUT: every grid cell has its drawing (shapes on), the strips' too", LS.geo[axe] and LS.geo[nut] and LS.geo[box] and LS.geo[worn] and LS.geo[axe].n == 10 and LS.geo[box].n == 4)
local emptyHole = false
for _, n in ipairs(LS.empties) do if n == 2 * 6 + 2 then emptyHole = true end end
check("LAYOUT: an empty hole inside the axe's box draws as a free slot", emptyHole)
-- draw: the axe's squares only
ZeD.GridTint = { of = function(T, tex, force) if force and tex == "tex_Axe" then return 0.5, 0.2, 0.1 end return nil end }
ps._stacks = LS.stacks
GL.draw(ps, gs, 0, 300, 24)
local az = 0
local inHole = false
local x0, y0 = 10 + LS.px[axe], LS.py[axe]
for _, z in ipairs(ps.zones) do
    if z.id == axe then
        az = az + 1
        -- the hole square (1, 2): x0 + 38 .. x0 + 72, y0 + 76 .. y0 + 110
        if z.x < x0 + 72 and z.x + z.w > x0 + 38 and z.y < y0 + 110 and z.y + z.h > y0 + 76 then inHole = true end
    end
end
check("DRAW: the axe's click zones are its squares and gaps", az == #LS.geo[axe].hits / 4, az)
check("DRAW: no click zone of the axe over its hole", not inHole)
local tinted = false
for _, l in ipairs(ps.log) do if l == string.format("rect %d %d 34 34 %.2f", x0, y0, ZeD.T.surf1.a) then tinted = true end end
check("DRAW: the axe's first square in its tint, at the surface's alpha (forced on)", tinted)
local pic = false
for _, l in ipairs(ps.log) do if l:find("^tex tex_Axe " .. (x0 + 3) .. " " .. (y0 + 3) .. " 27 27") then pic = true end end
check("DRAW: the picture in the first square, centered, one size", pic)
-- (Nov 17 2026, QA's 0.2 pass) a one-square stack: no weight chip, the count inside its square, a slim condition strip
do
    local p1 = mkPanel()
    local g1 = mkGV(5)
    GL.attach(p1, g1, MS, SBAG, {}, false, 24, 300)
    local L1 = g1.L
    local st = {}
    for k, v in pairs(L1.stacks) do st[k] = v end
    st[nut] = { rep = nut, items = { nut, nut, nut }, count = 30, key = "Base.Nut" }
    p1._stacks = st
    nut._cond = 0.5
    GL.draw(p1, g1, 0, 300, 24)
    nut._cond = nil
    local sx, sy, sq = 10 + L1.px[nut], L1.py[nut], L1.cell
    local inSq = function(x, y) return x >= sx and x < sx + sq and y >= sy and y < sy + sq end
    local weight, count, countIn, chipIn = false, false, false, true
    for _, l in ipairs(p1.log) do
        local s, x, y = l:match("^text (%S+) (%-?%d+) (%-?%d+)$")
        x, y = tonumber(x), tonumber(y)
        if s and inSq(x, y) then
            if s:match("^%(?%d+%.%d%)?$") then weight = true end
            if s == "(30)" then count = true; countIn = x + #s * 6 <= sx + sq end
        end
        local rx, ry, rw = l:match("^rect (%-?%d+) (%-?%d+) (%d+) %d+")
        rx, ry, rw = tonumber(rx), tonumber(ry), tonumber(rw)
        if rx and ry >= sy and ry < sy + sq and rx < sx + sq and rx + rw > sx and rw < sq and (rx < sx or rx + rw > sx + sq) then chipIn = false end
    end
    check("ONE SQUARE: no weight chip over the picture", not weight)
    check("ONE SQUARE: the count is drawn, inside its square", count and countIn)
    check("ONE SQUARE: no chip spills past its square", chipIn)
end
-- hover over the hole: the nut, not the axe
local gh2 = mkGV(5, { 10 + LS.px[nut] + 5, LS.py[nut] + 5 })
local ph = mkPanel()
GL.attach(ph, gh2, MS, SBAG, {}, false, 24, 300)
ph._stacks = gh2.L.stacks
HELP = {}
GL.draw(ph, gh2, 0, 300, 24)
check("DRAW: the pointer in the hole is on the small thing", HELP[#HELP] == "UI_ZeD_Inv_RowHelpLoot:Nut", HELP[#HELP])
-- a version 1 provider's cell draws as a span (no geo), as before
check("DRAW: no mask and no shapes: a span, as version 1", (function()
    local L1 = GL._shape({ cells = { { item = axe, x = 0, y = 0, w = 2, h = 3 } } }, { items = { axe }, cols = 5 }, MS, mkGV(5), false, nil, 24, 300)
    return L1.geo[axe] == nil and L1.cell == 52
end)())
-- the mouse ghost: the shape's outline, its mask handed to canPlace
SRC._drag, SRC._dragSourceInv = { items = { axe }, isActive = function() return true end }, SBAG
local gm = mkGV(5, { 10 + 4 * 38 + 5, 3 * 38 + 5 })
local pmg = mkPanel()
GL.attach(pmg, gm, MS, SBAG, {}, false, 24, 300)
pmg._stacks = gm.L.stacks
FRAMES = {}
local before = #pmg.log
GL.draw(pmg, gm, 0, 300, 24)
check("GHOST: canPlace gets the dragged mask", CANMASK == AXE, tostring(CANMASK))
check("GHOST: the shape's outline drawn (no box frame)", GL._over.w == 3 and GL._over.h == 6 and #FRAMES == #gm.L.empties)
DRAGMASK = nil
GL.unregister("ZeDMultiSlot")
ZeD.GridTint = nil

print = realPrint
print(string.format("grid_layout_sim: %d checks, %d failed", checks, failed))
os.exit(failed > 0 and 1 or 0)
