-- ZeD-UI/42/media/lua/client/ZeD/ZeD_TabFill.lua
-- ============================================================================
-- THE TAB FILL BLOCKS. Client side, a molecule kit for the tabs' lower halves:
-- the Health tab's Moodles / Fitness / Regularity / Muscle Strain, the Thermal
-- tab's picked region, the radio tabs' Channels / Heard / Power and the
-- Notebooks page's Writing / Papers / Books. Each block is a fold head, the
-- inventory's "v Name (n)" row, and its rows: a status square, the words
-- (wrapped, never cut; a row that asks for one line, a radio's channel name, is
-- cut with "..." only where it does not fit), a value, a stepped bar and a word
-- at the right.
--
-- A tab draws its blocks with F.head and F.row each frame, at its own place in
-- its own scroll; with no panel they only measure (the same code, so a measure
-- and a draw never disagree). The rows a press or the controller can reach are
-- stamped as zones under the tab's key; the tab hands its clicks to F.onClick
-- and adds F.focusables to its controller stops. Nothing here reads the game:
-- each tab gathers its facts on its own throttle and passes words in.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"

ZeD = ZeD or {}
ZeD.TabFill = ZeD.TabFill or {}
local F = ZeD.TabFill

local HEAD_H = 20      -- a block's fold head (design units)
local ROW_MIN = 24     -- a row's least height
local PAD_V = 4        -- over and under a row's words
local PAD_X = 6        -- a row's inner left and right pad
local DOT_BOX = 7      -- the status square's box
local GAP = 6          -- between a row's parts

local function fh(f) return ZeD.TM:getFontHeight(f) end
local function tw(f, s) return ZeD.TM:MeasureStringX(f, s) end

-- the tab's zones for this frame (and last frame's, which the controller reads)
local function bag(win, key)
    win._fill = win._fill or {}
    local b = win._fill[key]
    if not b then b = { zones = {}, last = {}, fold = {}, pool = {}, folds = {} }; win._fill[key] = b end
    return b
end

-- a zone table for this id, kept from frame to frame (a frame makes no new tables for its rows)
local function zoneFor(b, id)
    local z = b.pool[id]
    if not z then z = { id = id }; b.pool[id] = z end
    b.zones[#b.zones + 1] = z
    return z
end

--- Start a tab's frame: last frame's zones are kept for the controller, this
--- frame's start empty.
function F.begin(win, key)
    local b = bag(win, key)
    -- (the two lists swap: last frame's is kept for the controller, the older one is emptied for this frame)
    local old = b.last
    b.last = b.zones
    for i = #old, 1, -1 do old[i] = nil end
    b.zones = old
end

--- A zone the tab stamps itself (a grid cell, say), kept by its id from frame to frame: the tab
--- sets its x, y, w, h, fn (and partName, read) on the table this returns.
function F.zone(win, key, id)
    return zoneFor(bag(win, key), id)
end

--- This frame's zones for the tab (what F.onClick reads).
function F.zones(win, key) return bag(win, key).zones end

--- True when the block is folded shut (open until the player shuts it).
function F.folded(win, key, block)
    return bag(win, key).fold[block] == true
end

-- the controller's mark options when the element has the focus
local _focusOpts = {}
local function focusOf(win, id)
    local Fo = ZeD.Input and ZeD.Input.Focus
    if Fo and Fo.isFocused and Fo.isFocused(win, nil, id) then
        _focusOpts.win = win
        return _focusOpts
    end
    return nil
end
F.focusOf = focusOf

--- The fold head's height.
function F.headH() return ZeD.T.px(HEAD_H) end

--- A block's fold head, "v Name (n)": a press (or A) folds and unfolds it.
--- panel nil: measure only. opts { view (the tab's view rect, bounds the hover) }.
--- Returns its height.
function F.head(panel, win, key, block, x, y, w, label, count, opts)
    local T = ZeD.T
    local h = T.px(HEAD_H)
    if not panel then return h end
    local b = bag(win, key)
    b.headIds = b.headIds or {}
    local id = b.headIds[block]
    if not id then id = "fill:" .. key .. ":head:" .. block; b.headIds[block] = id end
    local open = b.fold[block] ~= true
    local hover = ZeD.Atoms.mouseIn(panel, x, y, w, h, opts and opts.view)
    ZeD.Molecules.drawCategoryRow(panel, x, y, w, label, count, open, { hover = hover, focus = focusOf(win, id), h = h })
    if hover and ZeD.Help then ZeD.Help.set(win, ZeD.tr(open and "UI_ZeD_Lists_HelpHide" or "UI_ZeD_Lists_HelpShow", label)) end
    local fn = b.folds[block]
    if not fn then fn = function() b.fold[block] = not b.fold[block] end; b.folds[block] = fn end
    local z = zoneFor(b, id)
    z.x, z.y, z.w, z.h, z.fn, z.read = x, y, w, h, fn, false
    return h
end

-- the room a row's right side takes: the value, the bar and the word
local function rightParts(r, w)
    local T, A = ZeD.T, ZeD.Atoms
    local f1 = T.fontF1
    local vw = (r.value and r.value ~= "") and tw(f1, r.value) or 0
    local bw = 0
    if r.bar then bw = math.max(A.fillBarMinW(), math.min(A.rowBarW(), math.floor(w * 0.3))) end
    local ww = 0
    if r.word and r.word ~= "" then ww = math.max(r.wordW or 0, tw(f1, r.word)) end
    local g = T.px(GAP)
    local used = 0
    if vw > 0 then used = used + vw + g end
    if bw > 0 then used = used + bw + g end
    if ww > 0 then used = used + ww + g end
    return used, vw, bw, ww
end

--- One row. r = {
---   id         controller / press id (nil: a row nothing presses and no stop)
---   dot        status square color (nil none); hollow = true draws it hollow
---   label      the words (F2, wrapped); sub = a second line under them (F3, dim, wrapped)
---   cut        the label on one line, cut with "..." only where it does not fit (a
---              radio's channel names: a list of names reads down one column)
---   value      short words at the right (F1); bar = 0..1 for a stepped bar beside it,
---              barN its steps (10), barColor (the accent)
---   word       a word at the far right (F1, dim); wordW its column's width
---   sel        the selected one (the accent wash); dim = the words dimmed
---   fn         what a press (or A) does; read = true makes it a stop A does nothing on
---   help       the help line's words on hover
--- }
--- panel nil: measure only. opts { view, dotCol (reserve the square's room) }. Returns its height.
function F.row(panel, win, key, r, x, y, w, opts)
    local T, A = ZeD.T, ZeD.Atoms
    local f1, f2, f3 = T.fontF1, T.fontF2, T.fontF3
    local padX, padV = T.px(PAD_X), T.px(PAD_V)
    local dotW = (r.dot or (opts and opts.dotCol)) and (T.px(DOT_BOX) + T.px(GAP)) or 0
    local used, vw, bw, ww = rightParts(r, w)
    local textX = x + padX + dotW
    local textW = math.max(T.px(40), w - padX * 2 - dotW - used)
    local lines
    if r.cut then
        -- (the one line kept on the row: no table made per frame; the cut is the atoms' memo)
        lines = r._oneLine
        if not lines then lines = {}; r._oneLine = lines end
        lines[1] = A.truncateText(r.label or "", f2, textW)
    else
        lines = A.wrapText(r.label or "", f2, textW)
    end
    local subs = (r.sub and r.sub ~= "") and A.wrapText(r.sub, f3, textW) or nil
    local ch = #lines * fh(f2) + (subs and (#subs * fh(f3) + T.px(1)) or 0)
    local h = math.max(T.px(ROW_MIN), padV * 2 + ch)
    if not panel then return h end

    local view = opts and opts.view
    local live = r.fn ~= nil
    local hover = live and A.mouseIn(panel, x, y, w, h, view)
    if r.sel then
        local ac = T.accent
        panel:drawRect(x, y, w, h, T.selectionA or 0.30, ac.r, ac.g, ac.b)
    end
    if hover then
        local hv = T.hover
        panel:drawRect(x, y, w, h, hv.a, hv.r, hv.g, hv.b)
    end
    if (hover or (r.help and A.mouseIn(panel, x, y, w, h, view))) and r.help and ZeD.Help then ZeD.Help.set(win, r.help) end
    local onFocus = false
    if r.id then
        local fo = focusOf(win, r.id)
        if fo then onFocus = ZeD.Focus.mark(panel, x, y, w, h, fo) end
    end
    local top = y + math.floor((h - ch) / 2)
    local l1 = top + math.floor((fh(f2) - fh(f1)) / 2)   -- the right side sits on the first line
    if r.dot then
        local dy = top + math.floor((fh(f2) - T.px(DOT_BOX)) / 2)
        if r.hollow then A.drawStatusHollow(panel, x + padX, dy, r.dot, T.px(DOT_BOX))
        else A.drawStatusDot(panel, x + padX, dy, r.dot, T.px(DOT_BOX)) end
    end
    local tc = onFocus and T.textOnFocus or (r.dim and T.textDim or T.text)
    for i, s in ipairs(lines) do
        panel:drawText(s, textX, top + (i - 1) * fh(f2), tc.r, tc.g, tc.b, tc.a or 1, f2)
    end
    if subs then
        local dc = onFocus and T.textOnFocus or T.textDim
        local sy = top + #lines * fh(f2) + T.px(1)
        for i, s in ipairs(subs) do
            panel:drawText(s, textX, sy + (i - 1) * fh(f3), dc.r, dc.g, dc.b, dc.a or 1, f3)
        end
    end
    -- the right side, from the edge in: the word, the bar, the value
    local rx = x + w - padX
    if ww > 0 then
        rx = rx - ww
        local dc = onFocus and T.textOnFocus or T.textDim
        panel:drawText(r.word, rx, l1, dc.r, dc.g, dc.b, dc.a or 1, f1)
        rx = rx - T.px(GAP)
    end
    if bw > 0 then
        rx = rx - bw
        local bh = A.fillBarCompactH()
        local n = r.barN or A.FILL_SEGS
        local hov = A.drawSegFill(panel, rx, top + math.floor((fh(f2) - bh) / 2), bw, bh, n, A.fillSegsLit(r.bar, n), r.barColor or T.accent)
        if hov and ZeD.Help and r.value then ZeD.Help.set(win, ZeD.tr("UI_ZeD_Bar_Help", r.label or "", r.value)) end
        rx = rx - T.px(GAP)
    end
    if vw > 0 then
        rx = rx - vw
        local vc = onFocus and T.textOnFocus or (T.toneNorm or T.text)
        panel:drawText(r.value, rx, l1, vc.r, vc.g, vc.b, vc.a or 1, f1)
    end
    if r.id then
        local z = zoneFor(bag(win, key), r.id)
        z.x, z.y, z.w, z.h, z.fn, z.read, z.partName = x, y, w, h, r.fn, (r.fn == nil), nil
    end
    return h
end

--- A block: its head and, unless folded, its rows. rows = a list of F.row specs.
--- panel nil: measure only. Returns its height (0 for no rows).
function F.block(panel, win, key, block, x, y, w, label, count, rows, opts)
    if not rows or #rows == 0 then return 0 end
    local h = F.head(panel, win, key, block, x, y, w, label, count, opts)
    if F.folded(win, key, block) then return h + ZeD.T.px(4) end
    local dotCol = false
    for _, r in ipairs(rows) do if r.dot then dotCol = true; break end end
    local o = F._rowOpts
    o.view, o.dotCol = opts and opts.view, dotCol
    for _, r in ipairs(rows) do h = h + F.row(panel, win, key, r, x, y + h, w, o) end
    return h + ZeD.T.px(6)
end
F._rowOpts = {}

--- A press on one of the tab's zones: true when it was one (its fn ran).
function F.onClick(win, key, x, y)
    local b = win and win._fill and win._fill[key]
    if not b then return false end
    for _, z in ipairs(b.zones) do
        if x >= z.x and x < z.x + z.w and y >= z.y and y < z.y + z.h then
            if z.fn then
                z.fn()
                pcall(function() getSoundManager():playUISound("UISelectListItem") end)
            end
            return true
        end
    end
    return false
end

--- The tab's zones as controller stops, clipped to the view { x, y, w, h } (a zone
--- out of view is no stop). Each carries fillStop = true and its whole rect in fullY /
--- fullH (the tab's scroll-follow reads them).
function F.focusables(win, key, view)
    local b = win and win._fill and win._fill[key]
    local out = {}
    if not b then return out end
    for _, z in ipairs(b.zones) do
        local y, h = z.y, z.h
        if view then
            local top, bot = math.max(y, view.y), math.min(y + h, view.y + view.h)
            if bot - top < 2 then y = nil else y, h = top, bot - top end
        end
        if y then
            local fn = z.fn
            out[#out + 1] = {
                x = z.x, y = y, w = z.w, h = h, fullY = z.y, fullH = z.h, id = z.id, fillStop = true,
                partName = z.partName,
                onFocus = z.onFocus or function() end,
                onActivate = fn and function() fn() end or nil,
            }
        end
    end
    return out
end

-- the zone with this id in a list of zones, or nil
local function findZone(list, id)
    for _, z in ipairs(list) do
        if z.id == id then return z end
    end
    return nil
end

--- The scroll offset that brings the focused stop (id) whole into view, from last
--- frame's zones: nil when it is in view or not one of the tab's. viewY / viewH: the
--- view; off: the scroll now (px); span: the most it can scroll.
-- Last frame's zones are this frame's list until the tab's F.begin runs, and the kept
-- list after it: the radio tabs ask before their F.begin, the Notebooks page after its
-- (the Journal starts every page's frame first), so both lists are looked in.
function F.follow(win, key, id, viewY, viewH, off, span)
    local b = win and win._fill and win._fill[key]
    if not (b and id) then return nil end
    local z = findZone(b.zones, id) or findZone(b.last, id)
    if not z then return nil end
    local m = ZeD.T.px(8)
    local newOff = off
    if z.y < viewY + m then newOff = off - (viewY + m - z.y)
    elseif z.y + z.h > viewY + viewH - m then newOff = off + (z.y + z.h - (viewY + viewH - m)) end
    newOff = math.max(0, math.min(span, newOff))
    if newOff ~= off then return newOff end
    return nil
end

--- Where a tab body's scroll goes when the controller's focus lands on el, one of the
--- body's stops (clipped to the view; ly / lh its whole rect from the top of the
--- scrolled content). The lowest stop shown scrolls the body on so the ones under it
--- come into view, and Up onto the highest one shown scrolls back the same way: the
--- stop goes a third of the view from the edge it came from, so the next ones that way
--- show and the ones it came past stay in view. Any other stop takes the least scroll
--- that shows it whole. The band's stops (bandStop) and the header's disclosure are
--- pinned, so they never count as above or below a body stop. viewH: the view's
--- height; off: the scroll now (px); span: the most it can scroll. Returns the new
--- scroll, the stop whole in view whatever the rule.
function F.followStop(win, el, ly, lh, viewH, off, span)
    local Focus = ZeD.Input and ZeD.Input.Focus
    local up = win._navLast ~= nil and win._navLast.dir == "up"
    local ey, eh = el.y or 0, el.h or 0
    local lowest, highest = true, true
    local z = Focus and Focus.getFocusedZone and Focus.getFocusedZone(win)
    for _, o in ipairs(z and z.elements or {}) do
        if o ~= el and not o.bandStop and not o.isDisclosure and type(o.y) == "number" then
            if o.y + (o.h or 0) > ey + eh + 1 then lowest = false end
            if o.y < ey - 1 then highest = false end
        end
    end
    local third = math.floor(viewH / 3)
    local target = off
    if up and highest and off > 0 then
        target = math.min(off, math.max(0, ly + lh - (viewH - third)))
    elseif lowest and not up then
        target = math.max(off, math.min(span, ly - third))
    elseif ly < off then
        target = ly
    elseif ly + lh > off + viewH then
        target = ly + lh - viewH
    end
    if ly + lh > target + viewH then target = ly + lh - viewH end
    if ly < target then target = ly end
    return math.max(0, math.min(span, target))
end

--- The rows of a stepped meter's place word: the vanilla scale's three words (low,
--- mid, high) for where a 0..1 value stands (thirds); mid false: two words (halves).
function F.scaleWord(v, low, mid, high)
    v = v or 0
    if not mid then return (v < 0.5) and low or high end
    if v < 1 / 3 then return low end
    if v > 2 / 3 then return high end
    return mid
end
