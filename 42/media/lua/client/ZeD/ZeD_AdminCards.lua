-- ZeD-UI/42/media/lua/client/ZeD/ZeD_AdminCards.lua
-- ============================================================================
-- THE ADMIN CARDS (ZeDUI/MP_ADMIN_SCOPE.md, Phase 2; the drawing is mockups/zed_admin_tools_v1.html). Drawing and input
-- only: ZeD_Admin.lua is the model. The cards run on the ticket cards' engine (ZeD_TicketCards.lua): the back bar, the
-- scroll, the fields, the foot and its confirm swap, the pad stops and the help band are all that file's.
--   the Admin tab's list   AC.homeItems: Tickets, Players, Admin powers, Server message, Roles, Bans, Spawn items
--   Player card            facts, the acts, Kick, Ban, role and warning points in the card, skills, logs, tickets
--   Roles, Role            the list; a role's name, description, color and capabilities as ticks in five groups
--   Bans                   ban someone who isn't on; each ban; Unban behind the foot's confirm; what they see
--   Spawn items            find, pick, how many, to whom
-- Every control that cannot be used stays on the card, gray, and its reason is in the help band: M.why gives the
-- capability it needs and the role that has it. A grayed control under the controller says it in the foot's line.
--
-- All player text is drawn with drawText, never through the game's rich text. Simple mode draws these same cards.
--
-- QA: ZeD.Admin.qaHold, qaLink, qaCaps (ZeD_Admin.lua), and AC.qaOpen(win, st, kind, ...).
-- ZeDUI/tools/qa/mp_admin_cards.lua walks every state of the drawing with these.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/Tr"
require "ZeD/ZeD_TicketProto"
require "ZeD/ZeD_AdminProto"
require "ZeD/ZeD_ServerLink"
require "ZeD/ZeD_Admin"
require "ZeD/ZeD_TicketCards"

ZeD = ZeD or {}
ZeD.AdminCards = ZeD.AdminCards or {}
local AC = ZeD.AdminCards
local M = ZeD.Admin
local TC = ZeD.TicketCards
local Tk = ZeD.Tk
local Adm = ZeD.Adm
local C = ZeD.Tickets
local D, B = TC._D, TC._B
local AL = Adm.L

local SPAWN_PAGE = 20                 -- items in one page of the spawn card
local SWATCH = 22                     -- design units
local ROW_V, GAP = 6, 6
local COLORS = {                      -- the drawing's ten, for a role's name and tag
    { 0.83, 0.83, 0.85 }, { 0.48, 0.48, 0.48 }, { 0.31, 0.53, 0.78 }, { 0.25, 0.65, 0.60 }, { 0.35, 0.60, 0.29 },
    { 0.77, 0.69, 0.25 }, { 0.83, 0.57, 0.16 }, { 0.77, 0.56, 0.25 }, { 0.77, 0.25, 0.25 }, { 0.60, 0.42, 0.77 },
}

local F = {}     -- the file's helpers (a table: Kahlua counts every local in the chunk)
local P = {}     -- the cards' parts

local function tr(k, ...) return ZeD.tr(k, ...) end
local function px(n) return ZeD.T.px(n) end

-- ---------------------------------------------------------------------------
-- SMALL PARTS
-- ---------------------------------------------------------------------------
-- the role as a tag in its own color, as drawn; a tag never by color alone: it holds the role's name
local _tag = { keepCase = true }
function F.roleColor(name)
    local r = M.role(name)
    return r and r.color or nil
end
function F.tagW(text) return ZeD.Atoms.tagW(text, false, _tag) end
function F.drawTag(panel, x, y, text, color, onFocus)
    local T = ZeD.T
    local c = onFocus and T.textOnFocus or color or T.textDim
    _tag.textColor, _tag.frameColor, _tag.alpha = c, c, 1
    return ZeD.Atoms.drawTag(panel, x, y, text, nil, _tag)
end

function F.ago(sec)
    if type(sec) ~= "number" then return nil end
    local gone = getTimestamp() - sec
    if gone < 120 then return tr("UI_ZeD_Adm_AgoNow") end
    if gone < 7200 then return tr("UI_ZeD_Adm_AgoMin", math.floor(gone / 60)) end
    if gone < 172800 then return tr("UI_ZeD_Adm_AgoHours", math.floor(gone / 3600)) end
    return tr("UI_ZeD_Adm_AgoDays", math.floor(gone / 86400))
end

function F.lastSeen(r)
    if r.on then return tr("UI_ZeD_Adm_Online") end
    return F.ago(r.lastT) or r.lastText or tr("UI_ZeD_Adm_NeverSeen")
end

function F.gate(c, capName, extra)
    c.live = function(cc)
        local why = nil
        if capName and not M.can(capName) then why = M.why(capName) end
        if not why and extra then why = extra(cc) end
        -- (a button, while a press waits for its answer; a chip or a tick is only a choice)
        if not why and not cc.style and cc.text and F.t and F.t.busy then why = tr("UI_ZeD_Tk_Busy") end
        cc.disabled, cc.why = why ~= nil, why
    end
    c.live(c)
    return c
end

function F.needPart() if not M.live() then return tr("UI_ZeD_Adm_NeedPart") end return nil end

-- the server's word. Its own errors first; the ones it shares with tickets speak of tickets, so they have words here too
local ADM_ERR = { self = true, protected = true, rank = true, offline = true, item = true, ipperm = true, gone = true, state = true, frozen = true, text = true, full = true,
    unknown = true, already = true, part = true, added = true, noplace = true, pinned = true }
function F.errOf(a)
    if ADM_ERR[a.err] then return tr("UI_ZeD_Adm_Err_" .. a.err) end
    return C.errText(a.err, a.left)
end

-- a command from a card: one at a time, its answer in the help band, and the words stay on a refusal. okText may be a
-- function of the answer; errOf: a card's own words for the server's refusals
function F.act(win, st, send, okText, after, errOf)
    local t = TC.qaState(st)
    if t.busy then return end
    F.t = t
    t.busy = true
    send(function(a)
        t.busy = nil
        if a.ok == false then
            D.flash(t, (errOf or F.errOf)(a))
            return
        end
        if type(okText) == "function" then okText = okText(a) end
        if okText then D.flash(t, okText) end
        if after then after(a) end
    end)
end

F.oneLine = {}
function F.field(items, key, rows, hint, land, max)
    B.field(items, key, rows, hint, land, max)
    -- (one row is a name or an address: Enter puts no line break in it)
    if rows == 1 then
        items[#items].one = true
        F.oneLine[key] = true
    end
end
function F.text(win, key)
    local s = Tk.clean(D.fieldText(win, key)) or ""
    if F.oneLine[key] then s = string.gsub(s, "\n", " ") end    -- (a paste can still bring one in)
    return s
end

function F.inset(items, tone, fn)
    items[#items + 1] = { k = "insetTop", tone = tone }
    local from = #items + 1
    fn()
    for i = from, #items do items[i].ind = 8 end
    items[#items + 1] = { k = "insetEnd" }
end

function F.flow(items, ctls) items[#items + 1] = { k = "aflow", ctls = ctls } end

-- ---------------------------------------------------------------------------
-- NEW ITEMS: each works in a card and in the tab's list (TC.items)
-- ---------------------------------------------------------------------------
-- aflow: a run of buttons, chips, swatches, words and ticks that wraps. c.push sends one to the row's right edge.
function F.ctlSize(c)
    local T, M2 = ZeD.T, ZeD.Molecules
    local s = c.style
    if s == "chip" then return D.chipW(c.text), D.chipH() end
    if s == "swatch" then return px(SWATCH), px(SWATCH) end
    if s == "text" then return ZeD.TM:MeasureStringX(T.fontF3, c.text), D.chipH() end
    if s == "tick" then
        local cb = T.checkboxSz or px(12)
        return cb + px(6) + ZeD.TM:MeasureStringX(T.fontF2, c.text), math.max(cb, ZeD.TM:getFontHeight(T.fontF2))
    end
    return M2.buttonW(c.text), T.buttonH
end

function F.flowLayout(win, it, w)
    local gap = px(GAP)
    local x, y, rowH, first = 0, 0, 0, 1
    local function closeRow(last)
        for i = first, last do
            local c = it.ctls[i]
            c.dy = y + math.floor((rowH - c.h) / 2)
            if c.push then c.dx = w - c.w end
        end
    end
    for i, c in ipairs(it.ctls) do
        c.w, c.h = F.ctlSize(c)
        c.w = math.min(c.w, w)
        if x > 0 and x + c.w > w then
            closeRow(i - 1)
            y = y + rowH + gap
            x, rowH, first = 0, 0, i
        end
        c.dx = x
        x = x + c.w + gap
        rowH = math.max(rowH, c.h)
    end
    closeRow(#it.ctls)
    return y + rowH
end

function F.drawCtl(panel, win, t, c, x, y, mx, my, ctx)
    local T, A, M2 = ZeD.T, ZeD.Atoms, ZeD.Molecules
    if c.live then c.live(c) end
    local id = ctx.prefix .. (c.id or "")
    local hov = mx ~= nil and mx >= x and mx < x + c.w and my >= y and my < y + c.h
    local s = c.style
    if s == "text" then
        local tc = c.tone and T[c.tone] or T.textDim
        panel:drawText(c.text, x, y + math.floor((c.h - ZeD.TM:getFontHeight(T.fontF3)) / 2), tc.r, tc.g, tc.b, tc.a or 1, T.fontF3)
        return
    elseif s == "chip" then
        D.drawChip(panel, win, x, y, c.w, c.h, c, id, mx, my)
    elseif s == "swatch" then
        local col = c.color
        panel:drawRect(x, y, c.w, c.h, 1, col[1], col[2], col[3])
        D.mark(panel, x, y, c.w, c.h, D.focusOf(win, id))
        A.frame(panel, x, y, c.w, c.h, c.on and T.accent or T.borderS)
        if c.on then A.frame(panel, x + px(2), y + px(2), c.w - px(4), c.h - px(4), T.accent) end
        if hov and (c.why or c.help) then ZeD.Help.set(win, c.why or c.help) end
    elseif s == "tick" then
        local cb = T.checkboxSz or px(12)
        local onF = D.mark(panel, x, y, c.w, c.h, D.focusOf(win, id))
        A.drawCheckbox(panel, x, y + math.floor((c.h - cb) / 2), c.on and true or false, hov, c.disabled)
        local tc = onF and T.textOnFocus or T.text
        local a = c.disabled and T.disabledAlpha or 1
        panel:drawText(c.text, x + cb + px(6), y + math.floor((c.h - ZeD.TM:getFontHeight(T.fontF2)) / 2), tc.r, tc.g, tc.b, (tc.a or 1) * a, T.fontF2)
        if hov and (c.why or c.help) then ZeD.Help.set(win, c.why or c.help) end
    else
        M2.drawButton(panel, x, y, c.w, c.h, c.text, c.danger and "danger" or (c.primary and "primary" or "default"), hov and isMouseButtonDown(0), nil,
            { hover = hov, disabled = c.disabled, help = c.why or c.help, win = win, focus = D.focusOf(win, id), default = c.primary })
    end
    ctx.hits[#ctx.hits + 1] = { x = x, y = y, w = c.w, h = c.h, c = c }
end

TC.items.aflow = {
    gap = 6,
    layout = F.flowLayout,
    draw = function(panel, win, t, it, x, dy, w, mx, my, ctx)
        for _, c in ipairs(it.ctls) do F.drawCtl(panel, win, t, c, x + c.dx, dy + c.dy, mx, my, ctx) end
    end,
    stops = function(it, x0, dy, w, add)
        for _, c in ipairs(it.ctls) do
            if c.style ~= "text" then add(c, x0 + c.dx, dy + c.dy, c.w, c.h, it.y + c.dy) end
        end
    end,
}

-- aline: a row of words in a tab's list, in the band's color
TC.items.aline = {
    layout = function(win, it, w)
        if it.wrapW ~= w then
            it.wrapW = w
            it.lines = D.wrap(it.text, ZeD.T.fontF2, math.max(1, w))
        end
        return #it.lines * ZeD.TM:getFontHeight(ZeD.T.fontF2) + px(6)
    end,
    draw = function(panel, win, t, it, x, dy, w)
        local T = ZeD.T
        local c = it.tone and T[it.tone] or T.textDim
        local fh = ZeD.TM:getFontHeight(T.fontF2)
        for i, s in ipairs(it.lines or {}) do
            panel:drawText(s, x, dy + px(2) + (i - 1) * fh, c.r, c.g, c.b, c.a or 1, T.fontF2)
        end
    end,
    stops = function() end,
}

-- arow: a list row. left, tag { text, color }, meta, dot (a green mark before the meta), warn, right, rtag (a tag at its
-- end), chev, lines under it, ctl (a button at its end), on
TC.items.arow = {
    layout = function(win, it, w)
        local T = ZeD.T
        local f2h = ZeD.TM:getFontHeight(T.fontF2)
        local h = f2h + 2 * px(ROW_V)
        if it.ctl then
            it.ctl.w, it.ctl.h = ZeD.Molecules.buttonW(it.ctl.text), T.buttonH - px(4)
            h = math.max(h, it.ctl.h + 2 * px(3))
        end
        if it.sub then
            if it.wrapW ~= w then
                it.wrapW = w
                it.lines = D.wrap(it.sub, T.fontF2, math.max(1, w - px(4)))
            end
            h = h + #it.lines * f2h + px(4)
        end
        return h
    end,
    draw = function(panel, win, t, it, x, dy, w, mx, my, ctx)
        local T, A = ZeD.T, ZeD.Atoms
        local c = it.c
        local f2h = ZeD.TM:getFontHeight(T.fontF2)
        local topH = f2h + 2 * px(ROW_V)
        if it.ctl then topH = math.max(topH, it.ctl.h + 2 * px(3)) end
        local hov = c ~= nil and mx ~= nil and mx >= x and mx < x + w and my >= dy and my < dy + it.h
        if c and c.live then c.live(c) end
        if it.on then
            local a = T.accent
            panel:drawRect(x, dy, w, it.h, 0.25, a.r, a.g, a.b)
        elseif hov then
            local hv = T.hover
            panel:drawRect(x, dy, w, it.h, hv.a or 1, hv.r, hv.g, hv.b)
        end
        if hov and c and (c.why or c.help) then ZeD.Help.set(win, c.why or c.help) end
        local onF = c ~= nil and D.mark(panel, x, dy, w, it.h, D.focusOf(win, ctx.prefix .. tostring(c.id)))
        local rx = x + w - px(4)
        local ty = dy + math.floor((topH - f2h) / 2)
        local f3y = dy + math.floor((topH - ZeD.TM:getFontHeight(T.fontF3)) / 2)
        if it.chev then
            local tc = onF and T.textOnFocus or T.textDim
            if it.open then
                A.drawTriangleDown(panel, rx - px(6), dy + math.floor(topH / 2) - px(3), px(6), tc)
            else
                A.drawTriangleRight(panel, rx - px(6), dy + math.floor(topH / 2) - px(3), px(6), tc)
            end
            rx = rx - px(14)
        end
        if it.ctl then
            rx = rx - it.ctl.w
            F.drawCtl(panel, win, t, it.ctl, rx, dy + math.floor((topH - it.ctl.h) / 2), mx, my, ctx)
            rx = rx - px(8)
        end
        if it.rtag then
            local rw = F.tagW(it.rtag.text)
            F.drawTag(panel, rx - rw, dy + math.floor((topH - px(16)) / 2), it.rtag.text, it.rtag.color, onF)
            rx = rx - rw - px(6)
        end
        if it.right then
            local rw = ZeD.TM:MeasureStringX(T.fontF3, it.right)
            local tc = onF and T.textOnFocus or T.textDim
            panel:drawText(it.right, rx - rw, f3y, tc.r, tc.g, tc.b, tc.a or 1, T.fontF3)
            rx = rx - rw - px(8)
        end
        if it.warn then
            local rw = ZeD.TM:MeasureStringX(T.fontF3, it.warn)
            local tc = onF and T.textOnFocus or T.warning
            panel:drawText(it.warn, rx - rw, f3y, tc.r, tc.g, tc.b, tc.a or 1, T.fontF3)
            rx = rx - rw - px(8)
        end
        -- the left: name, tag, meta. The meta gives way first, then the name, then the tag
        local tx = x + px(4)
        local room = rx - tx
        local leftW = ZeD.TM:MeasureStringX(T.fontF2, it.left or "")
        local keep = math.min(leftW, px(it.leftMin or 90))
        local tagText = it.tag and it.tag.text or nil
        local dotW = it.dot and px(10) or 0
        if tagText and F.tagW(tagText) + px(8) > room - keep then
            tagText = A.truncateText(tagText, T.fontF1, math.max(px(16), room - keep - px(18)))
        end
        local tagW = tagText and (F.tagW(tagText) + px(8)) or 0
        local metaRoom = room - keep - tagW - dotW - px(8)
        local meta = it.meta
        if meta and metaRoom > px(24) then
            meta = A.truncateText(meta, T.fontF3, metaRoom)
        else
            meta = nil
        end
        local metaW = meta and (ZeD.TM:MeasureStringX(T.fontF3, meta) + dotW + px(8)) or 0
        local left = A.truncateText(it.left or "", T.fontF2, math.max(px(20), room - tagW - metaW))
        local lc = onF and T.textOnFocus or T.text
        local a = (c and c.disabled) and T.disabledAlpha or 1
        panel:drawText(left, tx, ty, lc.r, lc.g, lc.b, (lc.a or 1) * a, T.fontF2)
        local cx = tx
        if it.left then cx = tx + math.max(ZeD.TM:MeasureStringX(T.fontF2, left), keep) + px(8) end
        if tagText then
            F.drawTag(panel, cx, dy + math.floor((topH - px(16)) / 2), tagText, it.tag.color, onF)
            cx = cx + tagW
        end
        if meta then
            local mc = onF and T.textOnFocus or T.textDim
            if it.dot then
                A.drawStatusDot(panel, cx, dy + math.floor((topH - px(7)) / 2), onF and T.textOnFocus or T.positive, px(7))
                cx = cx + dotW
            end
            panel:drawText(meta, cx, f3y, mc.r, mc.g, mc.b, mc.a or 1, T.fontF3)
        end
        if it.lines then
            local sc = onF and T.textOnFocus or T.textDim
            for i, s in ipairs(it.lines) do
                panel:drawText(s, tx, dy + topH + (i - 1) * f2h, sc.r, sc.g, sc.b, sc.a or 1, T.fontF2)
            end
        end
        A.drawDividerH(panel, x, dy + it.h - T.hair, w, false)
        if c then ctx.hits[#ctx.hits + 1] = { x = x, y = dy, w = w, h = it.h, c = c } end
    end,
    stops = function(it, x0, dy, w, add)
        if it.c then add(it.c, x0, dy, w, it.h, it.y) end
        if it.ctl then add(it.ctl, x0 + w - it.ctl.w - px(4), dy, it.ctl.w, it.ctl.h, it.y) end
    end,
}

-- atick: a tick with its line under it
TC.items.atick = {
    layout = function(win, it, w)
        local T = ZeD.T
        local cb = T.checkboxSz or px(12)
        local f2h = ZeD.TM:getFontHeight(T.fontF2)
        if it.wrapW ~= w then
            it.wrapW = w
            it.heads = D.wrap(it.text, T.fontF2, math.max(1, w - cb - px(8)))
            it.lines = it.sub and D.wrap(it.sub, T.fontF3, math.max(1, w - cb - px(8))) or {}
        end
        return math.max(cb, #it.heads * f2h) + #it.lines * ZeD.TM:getFontHeight(T.fontF3) + px(4)
    end,
    draw = function(panel, win, t, it, x, dy, w, mx, my, ctx)
        local T, A = ZeD.T, ZeD.Atoms
        local c = it.c
        if c.live then c.live(c) end
        local cb = T.checkboxSz or px(12)
        local f2h = ZeD.TM:getFontHeight(T.fontF2)
        local hov = mx ~= nil and mx >= x and mx < x + w and my >= dy and my < dy + it.h
        local onF = D.mark(panel, x, dy, w, it.h, D.focusOf(win, ctx.prefix .. c.id))
        A.drawCheckbox(panel, x, dy + px(1), c.on and true or false, hov, c.disabled)
        local tc = onF and T.textOnFocus or T.text
        local a = c.disabled and T.disabledAlpha or 1
        local tx = x + cb + px(8)
        for i, s in ipairs(it.heads or {}) do
            panel:drawText(s, tx, dy + (i - 1) * f2h, tc.r, tc.g, tc.b, (tc.a or 1) * a, T.fontF2)
        end
        local sc = onF and T.textOnFocus or T.textDim
        local y2 = dy + math.max(cb, #(it.heads or {}) * f2h)
        for i, s in ipairs(it.lines or {}) do
            panel:drawText(s, tx, y2 + (i - 1) * ZeD.TM:getFontHeight(T.fontF3), sc.r, sc.g, sc.b, sc.a or 1, T.fontF3)
        end
        if hov and (c.why or c.help) then ZeD.Help.set(win, c.why or c.help) end
        ctx.hits[#ctx.hits + 1] = { x = x, y = dy, w = w, h = it.h, c = c }
    end,
    stops = function(it, x0, dy, w, add) add(it.c, x0, dy, w, it.h, it.y) end,
}

-- askill: a skill's name, its pips, Level Down and Level Up
TC.items.askill = {
    layout = function(win, it)
        local T = ZeD.T
        for _, c in ipairs(it.ctls) do c.w, c.h = ZeD.Molecules.buttonW(c.text), T.buttonH - px(4) end
        return it.ctls[1].h + px(2)
    end,
    draw = function(panel, win, t, it, x, dy, w, mx, my, ctx)
        local T, A = ZeD.T, ZeD.Atoms
        local rx = x + w
        for i = #it.ctls, 1, -1 do
            local c = it.ctls[i]
            rx = rx - c.w
            F.drawCtl(panel, win, t, c, rx, dy, mx, my, ctx)
            c.sx = rx
            rx = rx - px(4)
        end
        local pipW = math.min(px(70), math.floor(w * 0.3))
        rx = rx - px(4) - pipW
        A.drawSegBar(panel, rx, dy + math.floor((it.h - px(8)) / 2), pipW, px(8), 10, it.lv, T.accent, T.surf3 or T.borderS, 1)
        local tc = T.text
        local name = A.truncateText(it.name, T.fontF2, math.max(px(20), rx - x - px(6)))
        panel:drawText(name, x, dy + math.floor((it.h - ZeD.TM:getFontHeight(T.fontF2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
    end,
    stops = function(it, x0, dy, w, add)
        for _, c in ipairs(it.ctls) do add(c, c.sx or (x0 + w - px(60)), dy, c.w, c.h, it.y) end
    end,
}

-- afind: a one-line field that answers as you type, with a chip after it
TC.items.afind = {
    layout = function(win, it, w)
        local T = ZeD.T
        if it.chip then it.chip.w, it.chip.h = D.chipW(it.chip.text), D.chipH() end
        return T.inputH + px(8)
    end,
    draw = function(panel, win, t, it, x, dy, w, mx, my, ctx)
        local T, A = ZeD.T, ZeD.Atoms
        local h = T.inputH
        local fy = dy + px(4)
        local fw = w
        if it.chip then
            fw = w - it.chip.w - px(8)
            local cy = fy + math.floor((h - it.chip.h) / 2)
            F.drawCtl(panel, win, t, it.chip, x + fw + px(8), cy, mx, my, ctx)
            it.chip.sy = cy
        end
        local box = D.fieldOf(win, it.key)
        if not box then
            box = D.makeField(win, panel, it.key, false, it.hint)
            box._lastText = it.start or ""
            D.setField(win, it.key, box._lastText)
        end
        box.onFilter = it.onText
        D.mark(panel, x, fy, fw, h, D.focusOf(win, ctx.prefix .. it.c.id))
        if fy >= ctx.viewY and fy + h <= ctx.viewY + ctx.viewH and not ctx.covered then
            D.showField(box, x, fy, fw, h)
        else
            local bg, bc = T.surf1, T.borderS
            panel:drawRect(x, fy, fw, h, bg.a or 1, bg.r, bg.g, bg.b)
            panel:drawRectBorder(x, fy, fw, h, bc.a or 1, bc.r, bc.g, bc.b)
            local text = box:getText() or ""
            local tc = (text == "") and T.textDim or T.text
            local s = A.truncateText((text == "") and it.hint or text, T.fontF2, fw - px(32))
            panel:drawText(s, x + px(26), fy + math.floor((h - ZeD.TM:getFontHeight(T.fontF2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
        end
        ctx.hits[#ctx.hits + 1] = { x = x, y = fy, w = fw, h = h, c = it.c, keep = true }
    end,
    stops = function(it, x0, dy, w, add)
        local fw = w
        if it.chip then fw = w - it.chip.w - px(8) end
        add(it.c, x0, dy + px(4), fw, ZeD.T.inputH, it.y)
        if it.chip then add(it.chip, x0 + fw + px(8), it.chip.sy or dy, it.chip.w, it.chip.h, it.y) end
    end,
}

-- afield: the card's typed field, in a tab's list too
TC.items.afield = {
    layout = function(win, it, w, sh) return D.fieldH(win, it, w, sh) + px(4) end,
    draw = function(panel, win, t, it, x, dy, w, mx, my, ctx)
        it.c.fullId = ctx.prefix .. it.c.id
        D.drawField(panel, win, t, it, x, dy, w, it.h - px(4), ctx.viewY, ctx.viewH, ctx.covered)
        ctx.hits[#ctx.hits + 1] = { x = x, y = dy, w = w, h = it.h, c = it.c, keep = true }
    end,
    stops = function(it, x0, dy, w, add) add(it.c, x0, dy, w, it.h - px(4), it.y) end,
}

-- ---------------------------------------------------------------------------
-- WHAT A BANNED PLAYER SEES: the lines, shared by the Bans card's sample and the screen itself
-- ---------------------------------------------------------------------------
function F.serverName()
    local so = getServerOptions and getServerOptions()
    local ok, name = pcall(function() return so:getOption("PublicName") end)
    if ok and name and name ~= "" then return name end
    local ok2, n2 = pcall(getServerName)
    return ok2 and n2 or ""
end

function AC.leaveLines(info)
    local out = {}
    if info.kind == "kick" then
        out[1] = tr("UI_ZeD_Adm_SeeKicked", F.serverName())
    elseif info.untilT then
        out[1] = tr("UI_ZeD_Adm_SeeUntil", F.serverName(), D.realDate(info.untilT) or "")
    else
        out[1] = tr("UI_ZeD_Adm_SeeBanned", F.serverName())
    end
    if info.reason then out[#out + 1] = tr("UI_ZeD_Adm_SeeReason", info.reason) end
    if info.appeal then out[#out + 1] = tr("UI_ZeD_Adm_SeeAppeal", info.appeal) end
    return out
end

-- the screen a banned client shows. Phase 5 sets M.leaveScreen, which fills in the appeal line and calls this. It covers the
-- game, the words wrap, and Leave ends it early; the model's clock ends it anyway.
ZeD_LeaveScreen = ISPanel:derive("ZeD_LeaveScreen")

function ZeD_LeaveScreen:new(info)
    local core = getCore()
    local o = ISPanel:new(0, 0, core:getScreenWidth(), core:getScreenHeight())
    setmetatable(o, self)
    self.__index = self
    o.info = info
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    return o
end

function ZeD_LeaveScreen:prerender()
    if M.leave ~= self.info then
        local pad = JoypadState.players[1]
        if pad and pad.focus == self then setJoypadFocus(0, nil) end
        self:setVisible(false)
        self:removeFromUIManager()
    end
end

function ZeD_LeaveScreen:render()
    local T, A, M2 = ZeD.T, ZeD.Atoms, ZeD.Molecules
    local bg = T.base
    self:drawRect(0, 0, self.width, self.height, 0.94, bg.r, bg.g, bg.b)
    local w = math.min(px(480), self.width - px(40))
    local x = math.floor((self.width - w) / 2)
    local y = math.floor(self.height / 3)
    local fh = ZeD.TM:getFontHeight(T.fontF2)
    local tc = T.text
    for _, line in ipairs(AC.leaveLines(self.info)) do
        for _, s in ipairs(D.wrap(line, T.fontF2, w)) do
            self:drawText(s, x, y, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
            y = y + fh
        end
        y = y + px(6)
    end
    local dc = T.textDim
    if self.info.hold then          -- (the game's call removes them: there is nothing to press and no count to give)
        self:drawText(tr("UI_ZeD_Adm_SeeRemoved"), x, y, dc.r, dc.g, dc.b, dc.a or 1, T.fontF2)
        self.btn = nil
        return
    end
    local left = math.max(0, math.ceil(((M.leaveAt or 0) - getTimestampMs()) / 1000))
    self:drawText(tr("UI_ZeD_Adm_SeeLeaving", left), x, y, dc.r, dc.g, dc.b, dc.a or 1, T.fontF2)
    y = y + fh + px(10)
    local label = tr("UI_ZeD_Adm_Leave")
    self.btn = { x = x, y = y, w = M2.buttonW(label), h = T.buttonH }
    M2.drawButton(self, x, y, self.btn.w, self.btn.h, label, "primary", false, nil, { default = true })
end

function ZeD_LeaveScreen:onMouseDown(x, y)
    local b = self.btn
    if b and x >= b.x and x < b.x + b.w and y >= b.y and y < b.y + b.h then M.leaveNow() end
    return true
end

function ZeD_LeaveScreen:onJoypadDown(button)
    if button == Joypad.AButton and not self.info.hold then M.leaveNow() end
end

function M.defaultLeave(info)
    local ui = ZeD_LeaveScreen:new(info)
    ui:initialise()
    ui:addToUIManager()
    ui:setAlwaysOnTop(true)
    if JoypadState.players[1] then setJoypadFocus(0, ui) end
end

-- ---------------------------------------------------------------------------
-- THE ADMIN TAB'S LIST
-- ---------------------------------------------------------------------------
function P.ticketSummary()
    local counts = C.counts and C.counts.kinds
    local parts = {}
    for _, k in ipairs(Tk.KINDS) do
        local n = counts and counts[k]
        if n and n > 0 then parts[#parts + 1] = tr("UI_ZeD_Adm_SumKind", n, TC.kindWord(k)) end
    end
    local none = counts and counts[Tk.NONE]
    if none and none > 0 then parts[#parts + 1] = tr("UI_ZeD_Adm_SumNone", none) end
    if #parts > 0 then return table.concat(parts, ", ") end
    if TC.openCount() > 0 then return tr("UI_ZeD_Adm_SumOpen", TC.openCount()) end
    return tr("UI_ZeD_Tk_NothingOpen")
end

function F.push(win, st, card)
    card.parent = st.card
    D.push(win, st, card)
end

function P.summary(out, id, text, meta, capName, run, rtag)
    local c = F.gate({ id = id, run = run, help = text }, capName)
    out[#out + 1] = { k = "tk", t = "arow", left = text, right = meta, rtag = rtag, leftMin = 400, chev = true, c = c }
end

function P.playerRow(st, r, me)
    local warn = nil
    if r.warn and r.warn > 0 then warn = tr((r.warn == 1) and "UI_ZeD_Adm_OneWarn" or "UI_ZeD_Adm_Warns", r.warn) end
    local name = (r.user == me) and tr("UI_ZeD_Adm_NameYou", r.user) or r.user
    local c = { id = "p:" .. r.user, help = tr("UI_ZeD_Adm_HelpPlayer"), run = function(ww) AC.openPlayer(ww, st, r.user, "adm:tk:p:" .. r.user) end }
    return { k = "tk", t = "arow", left = name, tag = r.role and { text = r.role, color = F.roleColor(r.role) } or nil,
        meta = F.lastSeen(r), dot = r.on, warn = warn, chev = true, c = c, on = false }
end

-- the game's tooltips hold rich text tags, and these lines are plain
function F.plainTip(s)
    if not s then return nil end
    return (string.gsub(s, "%s*<LINE>%s*", " "))
end

-- every power the game has: one this role lacks stays on the list, gray, and says why
function P.powers(out, win, p)
    local opts = ISAdminPowerUI and ISAdminPowerUI.OptionList or {}
    if #opts > 0 then out[#out + 1] = { k = "head", text = tr("UI_ZeD_Adm_PowersHead"), right = tr("UI_ZeD_Adm_Yours") } end
    for _, o in ipairs(opts) do
        local capName = F.capName(o.capability)
        local c = F.gate({ id = "pw:" .. o.id, help = F.plainTip(getTextOrNull("IGUI_CheatPanel_" .. o.id .. "_tooltip")),
            run = function()
                local pl = getPlayer()     -- (the object from before a death is not the one to tell the server about)
                o.player = pl
                local was = o:getValue() and true or false
                o:setValue(not was)
                sendPlayerExtraInfo(pl)
                M.powerLog(o.id, not was)
            end }, capName)
        local gray = c.live
        c.live = function(cc)
            gray(cc)
            if cc.disabled then
                cc.on = false
                return
            end
            o.player = getPlayer()
            local ok, v = pcall(function() return o:getValue() end)
            cc.on = ok and v and true or false
        end
        c.live(c)
        out[#out + 1] = { k = "tk", t = "atick", win = win, text = o.text, sub = c.help, c = c }
    end
    if #opts > 0 then out[#out + 1] = { k = "tk", t = "aline", text = tr("UI_ZeD_Adm_PowerTag"), win = win } end
end

function F.capName(cap)
    if type(cap) == "string" then return cap end
    local ok, n = pcall(function() return cap:name() end)
    return ok and n or nil
end

function P.message(out, win, st, t)
    out[#out + 1] = { k = "head", text = tr("UI_ZeD_Adm_ServerMsg") }
    local can = "DisplayServerMessage"
    if not M.can(can) then
        out[#out + 1] = { k = "tk", t = "aline", text = M.why(can), win = win }
        return
    end
    out[#out + 1] = { k = "tk", t = "afield", win = win, key = "msg", rows = 2, hint = tr("UI_ZeD_Adm_MsgHint"), max = AL.MSG_MAX,
        c = { id = "f:msg", help = tr("UI_ZeD_Adm_HelpServerMsg"), run = function(ww) D.useField(ww, "msg") end } }
    local ctls = {}
    ctls[1] = F.gate({ id = "rep", style = "tick", text = tr("UI_ZeD_Adm_RepeatEvery"), on = st.msgRepeat, help = tr("UI_ZeD_Adm_HelpRepeat"),
        run = function() st.msgRepeat = not st.msgRepeat; M.bump() end }, nil, F.needPart)
    for _, m in ipairs(Adm.EVERY) do
        ctls[#ctls + 1] = F.gate({ id = "ev:" .. m, style = "chip", text = tr("UI_ZeD_Adm_EveryMin", m), on = (st.msgEvery or 60) == m, help = tr("UI_ZeD_Adm_HelpRepeat"),
            run = function() st.msgEvery = m; M.bump() end }, nil, F.needPart)
    end
    ctls[#ctls + 1] = F.gate({ id = "send", text = tr("UI_ZeD_Adm_Send"), primary = true, push = true, help = tr("UI_ZeD_Adm_HelpSendMsg"),
        run = function(ww)
            local text = F.text(ww, "msg")
            local every = (st.msgRepeat and M.live()) and (st.msgEvery or 60) or nil
            local okText = every and tr("UI_ZeD_Adm_SentRepeat", every) or tr("UI_ZeD_Adm_SentOnce")
            F.act(ww, st, function(cb) M.message(text, every, cb) end, okText, function() D.setField(ww, "msg", "") end)
        end }, nil, function()
            if F.text(win, "msg") == "" then return tr("UI_ZeD_Adm_WriteMsg") end
            return nil
        end)
    out[#out + 1] = { k = "tk", t = "aflow", win = win, ctls = ctls }
    if #M.repeats > 0 then
        out[#out + 1] = { k = "tk", t = "aline", win = win, text = tr("UI_ZeD_Adm_Repeating"), tone = "textHead" }
        for _, r in ipairs(M.repeats) do
            local id = r.id
            local stop = F.gate({ id = "stop:" .. id, text = tr("UI_ZeD_Adm_Stop"), help = tr("UI_ZeD_Adm_HelpStop"),
                run = function(ww) F.act(ww, st, function(cb) M.stop(id, cb) end, tr("UI_ZeD_Adm_Stopped")) end }, nil, F.needPart)
            out[#out + 1] = { k = "tk", t = "arow", left = D.oneLine(r.text), leftMin = 120, right = tr("UI_ZeD_Adm_EveryN", r.every), ctl = stop }
        end
    end
end

-- the list above Safehouses, Factions and More tools, as drawn. Rebuilt when the model changes
function AC.homeItems(out, win, st, p)
    local t = TC.qaState(st)
    local me = M.me()
    local key = table.concat({ tostring(M.seq), tostring(C.seq), tostring(st.pfind), tostring(st.ponly), tostring(st.msgRepeat), tostring(st.msgEvery),
        tostring(M.live()), tostring(#M.repeats), tostring(M.qaCaps), tostring(ZeD.Logs and ZeD.Logs.live()),
        AC.homeKey and AC.homeKey() or "", AC.extrasKey and AC.extrasKey() or "" }, ":")
    if st.homeKey ~= key or not st.homeItems then
        st.homeKey = key
        t.listGen = t.listGen + 1
        local L = {}
        -- TICKETS
        L[#L + 1] = { k = "head", text = getText("UI_userpanel_tickets"), right = tr("UI_ZeD_Tk_NOpen", TC.openCount()) }
        P.summary(L, "sum:tickets", P.ticketSummary(), nil, "AnswerTickets", function(ww) AC.openTickets(ww, st) end)
        -- LOG
        if ZeD.LogCards then ZeD.LogCards.homeRow(L, st, P) end
        -- PLAYERS
        L[#L + 1] = { k = "head", text = tr("UI_ZeD_Srv_Players"), right = tr("UI_ZeD_Adm_PlayerCount", M.onlineN or 0, #M.rows) }
        L[#L + 1] = { k = "tk", t = "afind", win = win, key = "pfind", hint = tr("UI_ZeD_Adm_FindHint"), start = st.pfind or "",
            onText = function(_, text) st.pfind = text end,
            c = { id = "f:pfind", help = tr("UI_ZeD_Adm_HelpFind"), run = function(ww) D.useField(ww, "pfind") end },
            chip = { id = "ponly", style = "chip", text = tr("UI_ZeD_Adm_OnlineOnly"), on = st.ponly, help = tr("UI_ZeD_Adm_HelpOnlineOnly"), run = function() st.ponly = not st.ponly end } }
        local rows = M.findRows(st.pfind, st.ponly)
        if #rows == 0 then
            L[#L + 1] = { k = "tk", t = "aline", win = win, text = tr((#M.rows == 0) and "UI_ZeD_Srv_PlayersWait" or "UI_ZeD_Adm_NobodyMatches") }
        end
        for _, r in ipairs(rows) do L[#L + 1] = P.playerRow(st, r, me) end
        -- ADMIN POWERS
        P.powers(L, win, p)
        -- SERVER MESSAGE
        P.message(L, win, st, t)
        -- ROLES, BANS, SPAWN ITEMS
        L[#L + 1] = { k = "head", text = tr("UI_ZeD_Adm_Roles"), right = tostring(#M.roles()) }
        local newRole = M.defaultRoleName()
        P.summary(L, "sum:roles", tr("UI_ZeD_Adm_RolesSum"), newRole and tr("UI_ZeD_Adm_NewPlayersGet") or nil, "RolesRead", function(ww) AC.openRoles(ww, st) end,
            newRole and { text = newRole, color = F.roleColor(newRole) } or nil)
        L[#L + 1] = { k = "head", text = tr("UI_ZeD_Adm_Bans"), right = tostring(#M.banRows()) }
        P.summary(L, "sum:bans", tr("UI_ZeD_Adm_BansSum"), nil, "BanUnbanUser", function(ww) AC.openBans(ww, st) end)
        L[#L + 1] = { k = "head", text = tr("UI_ZeD_Adm_Spawn") }
        P.summary(L, "sum:spawn", tr("UI_ZeD_Adm_SpawnSum"), nil, "AddItem", function(ww) AC.openSpawn(ww, st) end)
        -- RULES AND NEWS (Phase 5: ZeD_CommunityCards.lua, on a server with that part), then SERVER EXTRAS (ZeD_ExtrasCards.lua)
        if AC.homeExtra then AC.homeExtra(L, win, st) end
        if AC.extrasHome then AC.extrasHome(L, win, st) end
        for _, it in ipairs(L) do it.win = win end
        st.homeItems = L
    end
    for _, it in ipairs(st.homeItems) do out[#out + 1] = it end
end

function AC.homeHelp() return tr("UI_ZeD_Adm_HelpHome") end

-- the head of the tab, as drawn: your own role, in its color
function AC.drawYou(panel, x, y, w, h)
    local T = ZeD.T
    local name = M.myRoleName()
    if not name then return end
    if F.tagW(name) > math.floor(w / 3) then name = ZeD.Atoms.truncateText(name, T.fontF1, math.floor(w / 3)) end
    local rx = x + w - px(10) - F.tagW(name)
    F.drawTag(panel, rx, y + math.floor((h - px(16)) / 2), name, F.roleColor(name), false)
    ZeD.Atoms.drawTextRight(panel, tr("UI_ZeD_Adm_YouRole"), rx - px(6), y + math.floor((h - ZeD.TM:getFontHeight(T.fontF1)) / 2), T.fontF1, T.textDim)
end

-- a note's Open: to the Admin tab, where the Bans card opens
function AC.openNote(item)
    item.read = true
    M.openBansNext = true
    M.bump()
    if ZeD_WorldWindow and ZeD_WorldWindow.openTab then pcall(ZeD_WorldWindow.openTab, 0, "admin") end
end

-- once a frame on the tab, card or list
function AC.frame(win, st)
    if M.openPlayerNext then           -- (chat's Player card)
        local user = M.openPlayerNext
        M.openPlayerNext = nil
        st.card, st.screen = nil, nil
        AC.openPlayer(win, st, user, "adm:tk:p:" .. user)
        return
    end
    if not M.openBansNext then return end
    M.openBansNext = nil
    if not M.can("BanUnbanUser") then return end
    st.card, st.screen = nil, nil
    AC.openBans(win, st)
end

function AC.openTickets(win, st)
    st.screen = "tickets"
    st.homeKey = nil
    D.focusNext(win, st, function(e) return e.id == "adm:tk:s:Open" end)
end

-- ---------------------------------------------------------------------------
-- THE PLAYER CARD
-- ---------------------------------------------------------------------------
function AC.openPlayer(win, st, user, from)
    D.setField(win, "reason", "")
    F.push(win, st, { kind = "player", user = user, from = from, warnN = 1, len = Adm.DEFAULT_LEN, keep = {} })
    M.loadCard(user, true)
    M.loadLog(user)
end

-- the ticket card's Player card: this card over that one
function AC.openFromTicket(win, st, user)
    AC.openPlayer(win, st, user, "tk:pcard")
end

function P.rolePick(win, st, card, row, view, self)
    -- closed: the server kept the saved role of an account that is off, so "user" would be a wrong fact. name stays nil
    -- and the box names the power it takes (false, not nil, for the picker: no row is marked and nil means "use the
    -- ticket filter" there)
    local closed = view and view.closed and not row.role
    local name = (view and view.role) or row.role or ((not closed) and "user") or nil
    if self then
        return { label = tr("UI_ZeD_Adm_Role"), value = tr("UI_ZeD_Adm_OwnRole", name or "user") }
    end
    local c = F.gate({ id = "role", box = true, text = card.newRole or name or M.why("SeeNetworkUsers"), help = tr("UI_ZeD_Adm_HelpRolePick") }, "ChangeAccessLevel", function()
        if not M.can("ModifyNetworkUsers") then return M.why("ModifyNetworkUsers") end
        return nil
    end)
    c.run = function(ww)
        local modes = {}
        local mine = M.role(M.myRoleName())
        for _, r in ipairs(M.roles()) do
            if not mine or r.pos <= mine.pos then modes[#modes + 1] = { id = r.name, label = r.name } end
        end
        TC.openPicker(ww, st, c, modes, card.newRole or name or false, function(id)
            if id == name then
                card.newRole, card.open = nil, nil
            else
                card.newRole, card.open = id, "role"
                card.keep = {}
                D.focusId(ww, st, "tk:rno")
            end
            M.bump()
        end)
    end
    return { label = tr("UI_ZeD_Adm_Role"), value = "", c = c }
end

function M.myRoleName()
    local p = getPlayer()
    local ok, n = pcall(function() return p:getRole():getName() end)
    return ok and n or nil
end

function P.facts(items, win, st, card, row, view, self)
    local on = (view and view.on) or row.on
    B.fact(items, tr("UI_ZeD_Adm_Username"), card.user)
    B.fact(items, tr("UI_ZeD_Adm_SteamName"), (row.steam ~= nil and row.steam ~= "" and row.steam) or tr(M.onSteam() and "UI_ZeD_Adm_SteamUnknown" or "UI_ZeD_Adm_NoSteam"))
    local rp = P.rolePick(win, st, card, row, view, self)
    B.fact(items, rp.label, rp.value, rp.c)
    -- (closed: the server kept the record of an account that is off, so "not seen yet" would be wrong)
    local lastHere = (view and view.closed and not row.lastText) and M.why("SeeNetworkUsers")
        or tr("UI_ZeD_Adm_LastHere", F.ago(view and view.last) or row.lastText or tr("UI_ZeD_Adm_NeverSeen"))
    B.fact(items, tr("UI_ZeD_Adm_Status"), on and tr("UI_ZeD_Adm_Online") or lastHere)
    local where = tr("UI_ZeD_Adm_NotOnMap")
    if view and view.x then where = Tk.whereText({ x = view.x, y = view.y })
    elseif view and view.hidden then where = tr("UI_ZeD_Adm_WhereHidden") end
    B.fact(items, tr("UI_ZeD_Adm_Where"), where)
    -- (the game's user list alone holds these: 0 here would read as a clean record)
    local unread = row.warn == nil and not M.can("SeeNetworkUsers")
    B.fact(items, tr("UI_ZeD_Adm_WarnFact"), unread and M.why("SeeNetworkUsers") or tr("UI_ZeD_Adm_WarnValue", row.warn or 0, row.kicks or 0))
    local ban = M.banOf(card.user)
    if ban or (view and view.banId) then
        local untilT = (view and view.banUntil) or (ban and ban.untilT)
        B.fact(items, tr("UI_ZeD_Adm_BanFact"), untilT and tr("UI_ZeD_Adm_Until", D.realDate(untilT) or "") or tr("UI_ZeD_Adm_LenPerm"))
    end
end

function P.notOn(user, on)
    return function()
        if not on() then return tr("UI_ZeD_Adm_NotOnline", user) end
        return nil
    end
end

function P.acts(items, win, st, card, row, view, t)
    local user = card.user
    local function isOn()
        local v = M.cards[user]
        if v then return v.on end
        local r = M.row(user)
        return r and r.on
    end
    local notOn = P.notOn(user, isOn)
    local ctls = {}
    ctls[1] = F.gate({ id = "tp", land = true, text = getText("UI_Scoreboard_Teleport"), help = tr("UI_ZeD_Adm_HelpTp"),
        run = function(ww) F.act(ww, st, function(cb) M.teleport(user, cb) end, tr("UI_ZeD_Adm_Teleported", user)) end }, "TeleportToPlayer", notOn)
    ctls[2] = F.gate({ id = "tpme", text = getText("UI_Scoreboard_TeleportToYou"), help = tr("UI_ZeD_Adm_HelpBring"),
        run = function(ww) F.act(ww, st, function(cb) M.bring(user, cb) end, tr("UI_ZeD_Adm_Brought", user)) end }, "TeleportPlayerToAnotherPlayer", notOn)
    local muted = M.muted(user)
    local live = M.live()
    local muteWord = live and (muted and "UI_ZeD_Adm_Unmuted" or "UI_ZeD_Adm_Muted") or (muted and "UI_ZeD_Adm_VoiceUnmuted" or "UI_ZeD_Adm_VoiceMuted")
    ctls[3] = F.gate({ id = "mute", text = getText(muted and "UI_Scoreboard_Unmute" or "UI_Scoreboard_Mute"), help = tr(live and "UI_ZeD_Adm_HelpMute" or "UI_ZeD_Adm_HelpMuteVoice"),
        run = function(ww)
            F.act(ww, st, function(cb) M.mute(user, not muted, cb) end, tr(muteWord, user))
        end }, "BanUnbanUser", function()
            if muted then return nil end     -- (Unmute works on someone who has gone)
            return notOn()
        end)
    ctls[4] = F.gate({ id = "warnb", text = getText("IGUI_UserList_AddWarningPoint"), help = tr("UI_ZeD_Adm_HelpWarn"),
        run = function(ww) P.openPart(ww, st, card, "warn", "tk:wp") end }, "AddUserlog")
    ctls[5] = F.gate({ id = "kick", text = getText("IGUI_UserList_Kick"), danger = true, help = tr("UI_ZeD_Adm_HelpKick"),
        run = function(ww) P.openPart(ww, st, card, "kick", "tk:f:reason") end }, "KickUser", notOn)
    -- a ban stands: Unban in Ban's place. A second ban would be a second row on the game's one
    local ban = M.banOf(user) or (view and view.banId and { id = view.banId, user = user }) or nil
    if ban then
        ctls[6] = F.gate({ id = "unban", text = getText("IGUI_UserList_UnBan"), help = tr("UI_ZeD_Adm_HelpUnban"),
            run = function(ww)
                t.confirm = ban
                D.focusId(ww, st, "tk:cno")
            end }, "BanUnbanUser")
    elseif row.role ~= "banned" then
        ctls[6] = F.gate({ id = "ban", text = getText("IGUI_UserList_Ban"), danger = true, help = tr("UI_ZeD_Adm_HelpBan"),
            run = function(ww) P.openPart(ww, st, card, "ban", "tk:f:reason") end }, "BanUnbanUser")
    end
    F.flow(items, ctls)
end

function P.openPart(win, st, card, part, focus)
    card.open = part
    card.warnN, card.banIp = 1, false
    card.len = M.live() and Adm.DEFAULT_LEN or "perm"       -- (timed bans are the server part's)
    D.setField(win, "reason", "")
    D.focusId(win, st, focus)
    M.bump()
end

function P.closePart(win, st, card, focus)
    card.open, card.newRole = nil, nil
    D.setField(win, "reason", "")
    D.focusId(win, st, focus or "tk:back")
    M.bump()
end

function P.reasonGate(win)
    return function()
        if F.text(win, "reason") == "" then return tr("UI_ZeD_Adm_WriteReason") end
        return nil
    end
end

function P.kickPart(items, win, st, card)
    local user = card.user
    F.inset(items, "danger", function()
        B.label(items, tr("UI_ZeD_Adm_Reason"), tr("UI_ZeD_Adm_TheySee", user))
        F.field(items, "reason", 2, tr("UI_ZeD_Adm_ReasonHint"), true, AL.REASON_MAX)
        F.flow(items, {
            { id = "kno", text = getText("UI_Cancel"), run = function(ww) P.closePart(ww, st, card, "tk:kick") end },
            F.gate({ id = "kyes", text = getText("IGUI_UserList_Kick"), danger = true, push = true, help = tr("UI_ZeD_Adm_HelpKick"),
                run = function(ww)
                    local reason = F.text(ww, "reason")
                    F.act(ww, st, function(cb) M.kick(user, reason, cb) end, tr("UI_ZeD_Adm_Kicked", user), function()
                        P.closePart(ww, st, card, "tk:kick")
                        M.loadCard(user, true)
                    end)
                end }, nil, P.reasonGate(win)),
        })
    end)
end

function P.banLine(id)
    local l = Adm.LENGTH[id]
    if not l or not l.sec then return tr("UI_ZeD_Adm_UntilUnban") end
    return tr("UI_ZeD_Adm_LiftsAt", D.realDate(getTimestamp() + l.sec) or "")
end

-- a timed length chosen, and the server part gone since
function P.timedGate(card)
    if Adm.LENGTH[card.len].sec and not M.live() then return tr("UI_ZeD_Adm_NeedPart") end
    return nil
end

function P.lenChips(card, id0)
    local ctls = {}
    for _, l in ipairs(Adm.LENGTHS) do
        local id = l.id
        ctls[#ctls + 1] = F.gate({ id = id0 .. id, style = "chip", text = tr(l.key), on = card.len == id, help = tr("UI_ZeD_Adm_HelpLen"),
            run = function()
                card.len = id
                if Adm.LENGTH[id].sec and not Adm.TIMED_IP then card.banIp = false end
                M.bump()
            end }, nil, function()
                if Adm.LENGTH[id].sec and not M.live() then return tr("UI_ZeD_Adm_NeedPart") end
                return nil
            end)
    end
    return ctls
end

function P.banPart(items, win, st, card)
    local user = card.user
    F.inset(items, "danger", function()
        B.label(items, tr("UI_ZeD_Adm_Reason"), tr("UI_ZeD_Adm_TheySee", user))
        F.field(items, "reason", 2, tr("UI_ZeD_Adm_ReasonHint"), true, AL.REASON_MAX)
        B.label(items, tr("UI_ZeD_Adm_For"))
        F.flow(items, P.lenChips(card, "bl:"))
        B.sub(items, P.banLine(card.len))
        local ip = F.gate({ id = "banip", on = card.banIp, help = tr("UI_ZeD_Adm_BanIpLine"),
            run = function() card.banIp = not card.banIp; M.bump() end }, nil, function()
                if Adm.LENGTH[card.len].sec and not Adm.TIMED_IP then return tr("UI_ZeD_Adm_IpPermOnly") end
                local r = M.row(user)
                if not (r and r.on) then return getText("IGUI_UserList_BanIPNotOnline") end
                return nil
            end)
        items[#items + 1] = { k = "atick", text = tr("UI_ZeD_Adm_BanIp"), sub = tr("UI_ZeD_Adm_BanIpLine"), c = ip }
        F.flow(items, {
            { id = "bno", text = getText("UI_Cancel"), run = function(ww) P.closePart(ww, st, card, "tk:ban") end },
            F.gate({ id = "byes", text = getText("IGUI_UserList_Ban"), danger = true, push = true, help = tr("UI_ZeD_Adm_HelpBan"),
                run = function(ww)
                    local reason = F.text(ww, "reason")
                    F.act(ww, st, function(cb) M.ban(user, reason, card.len, card.banIp, cb) end, tr("UI_ZeD_Adm_Banned", user), function()
                        P.closePart(ww, st, card, "tk:back")
                        M.loadCard(user, true)
                    end)
                end }, nil, function() return P.timedGate(card) or P.reasonGate(win)() end),
        })
    end)
end

function P.rolePart(items, win, st, card, fromRole)
    local user, to = card.user, card.newRole
    local gain, lose, powers = M.roleChange(fromRole, to)
    F.inset(items, "warning", function()
        B.label(items, tr("UI_ZeD_Adm_MakeAsk", user, to))
        B.sub(items, (#gain > 0) and tr("UI_ZeD_Adm_WillDo", table.concat(gain, ", ")) or tr("UI_ZeD_Adm_NothingNew"))
        if #lose > 0 then B.sub(items, tr("UI_ZeD_Adm_WillLose", table.concat(lose, ", "))) end
        if #powers > 0 and not M.live() then
            -- (only the server part can turn them off: the game's own change leaves them on, so nothing here to tick)
            local words = {}
            for i, pw in ipairs(powers) do words[i] = getText("IGUI_CheatPanel_" .. pw.id) end
            B.label(items, tr("UI_ZeD_Adm_PowersOn"))
            B.sub(items, table.concat(words, ", "))
            B.sub(items, tr("UI_ZeD_Adm_PowersStayOn"))
            items[#items].tone = "warning"
        elseif #powers > 0 then
            B.label(items, tr("UI_ZeD_Adm_PowersOn"))
            for _, pw in ipairs(powers) do
                local id = pw.id
                local on = card.keep[id] == true
                local word = getText("IGUI_CheatPanel_" .. id)
                items[#items + 1] = { k = "atick", text = tr(on and "UI_ZeD_Adm_PowerStays" or "UI_ZeD_Adm_PowerOff", word),
                    c = { id = "kp:" .. id, on = on, help = tr("UI_ZeD_Adm_HelpKeepPower"),
                        run = function()
                            card.keep[id] = not on or nil
                            M.bump()
                        end } }
            end
            B.sub(items, tr("UI_ZeD_Adm_KeepLine"))
            items[#items].tone = "warning"
        end
        F.flow(items, {
            { id = "rno", text = getText("UI_Cancel"), run = function(ww) P.closePart(ww, st, card, "tk:role") end },
            { id = "ryes", text = tr("UI_ZeD_Adm_ChangeRole"), primary = true, push = true, help = tr("UI_ZeD_Adm_HelpChangeRole"),
                run = function(ww)
                    local keep = {}
                    for id in pairs(card.keep) do keep[#keep + 1] = id end
                    F.act(ww, st, function(cb) M.setRole(user, to, keep, cb) end, tr((M.live() and #powers > #keep) and "UI_ZeD_Adm_RoleSetOff" or "UI_ZeD_Adm_RoleSet", user, to), function()
                        P.closePart(ww, st, card, "tk:role")
                        M.loadCard(user, true)
                    end)
                end },
        })
    end)
end

function P.warnPart(items, win, st, card, row)
    local user = card.user
    F.inset(items, "warning", function()
        B.label(items, getText("IGUI_UserList_AddWarningPoint"))
        F.flow(items, {
            F.gate({ id = "wm", text = "-", run = function() card.warnN = card.warnN - 1; M.bump() end }, nil, function()
                if card.warnN <= 1 then return tr("UI_ZeD_Adm_WarnLeast") end
                return nil
            end),
            { style = "text", text = tostring(card.warnN), tone = "text" },
            F.gate({ id = "wp", text = "+", run = function() card.warnN = card.warnN + 1; M.bump() end }, nil, function()
                if card.warnN >= AL.WARN_MAX then return tr("UI_ZeD_Adm_WarnMost", AL.WARN_MAX) end
                return nil
            end),
            { style = "text", text = tr("UI_ZeD_Adm_WarnAfter", row.warn or 0, (row.warn or 0) + card.warnN) },
        })
        B.label(items, tr("UI_ZeD_Adm_Reason"), tr("UI_ZeD_Adm_TheySee", user))
        F.field(items, "reason", 2, tr("UI_ZeD_Adm_ReasonHint"), true, AL.REASON_MAX)
        F.flow(items, {
            { id = "wno", text = getText("UI_Cancel"), run = function(ww) P.closePart(ww, st, card, "tk:warnb") end },
            F.gate({ id = "wyes", text = tr("UI_ZeD_Adm_Add"), primary = true, push = true, help = tr("UI_ZeD_Adm_HelpWarn"),
                run = function(ww)
                    local reason, n = F.text(ww, "reason"), card.warnN
                    local done = (n == 1) and tr("UI_ZeD_Adm_WarnDone1", user) or tr("UI_ZeD_Adm_WarnDone", n, user)
                    F.act(ww, st, function(cb) M.warn(user, n, reason, cb) end, done, function()
                        P.closePart(ww, st, card, "tk:warnb")
                    end)
                end }, nil, P.reasonGate(win)),
        })
    end)
end

function P.skills(items, win, st, card, view)
    local user = card.user
    local list = view and view.skills or {}
    local shown = 0
    for _, s in ipairs(list) do
        if s.lv > 0 or card.allSkills then shown = shown + 1 end
    end
    B.label(items, tr("UI_ZeD_Adm_Skills"), getText("IGUI_PlayerStats_LevelUp") .. ", " .. getText("IGUI_PlayerStats_LevelDown"))
    local function notOn()
        local v = M.cards[user]
        if not (v and v.on) then return tr("UI_ZeD_Adm_NotOnline", user) end
        return nil
    end
    for _, s in ipairs(list) do
        if s.lv > 0 or card.allSkills then
            local id = s.id
            items[#items + 1] = { k = "askill", name = s.name, lv = s.lv, ctls = {
                F.gate({ id = "sd:" .. id, text = "-", help = getText("IGUI_PlayerStats_LevelDown"),
                    run = function(ww) F.act(ww, st, function(cb) M.skill(user, id, -1, cb) end, tr("UI_ZeD_Adm_SkillDone", s.name)) end }, "AddXP", function()
                        if s.lv <= 0 then return tr("UI_ZeD_Adm_SkillLeast") end
                        return notOn()
                    end),
                F.gate({ id = "su:" .. id, text = "+", help = getText("IGUI_PlayerStats_LevelUp"),
                    run = function(ww) F.act(ww, st, function(cb) M.skill(user, id, 1, cb) end, tr("UI_ZeD_Adm_SkillDone", s.name)) end }, "AddXP", function()
                        if s.lv >= 10 then return tr("UI_ZeD_Adm_SkillMost") end
                        return notOn()
                    end),
            } }
        end
    end
    if view and view.closed and #list == 0 then
        -- (the server kept this account's skills back, so "no skill above 0" would be a guess: name the power instead)
        B.sub(items, M.why("SeeNetworkUsers"))
    elseif shown == 0 then
        B.sub(items, tr("UI_ZeD_Adm_NoSkills"))
    end
    if #list > 0 then
        F.flow(items, { { id = "allskills", style = "chip", text = tr("UI_ZeD_Adm_AllSkills"), on = card.allSkills, help = tr("UI_ZeD_Adm_HelpAllSkills"),
            run = function() card.allSkills = not card.allSkills; M.bump() end } })
    end
end

function P.logs(items, card)
    local list = M.logs[card.user] or {}
    B.label(items, getText("IGUI_PlayerStats_UserLogs"), tostring(#list))
    if not M.can("ReadUserLog") then
        B.sub(items, M.why("ReadUserLog"))
    elseif #list == 0 then
        B.sub(items, tr("UI_ZeD_Adm_NothingLogged"))
    end
    for _, l in ipairs(list) do
        B.msg(items, tr("UI_ZeD_Adm_LogHead", tostring(l.when or ""), tostring(l.type), tostring(l.by)), tostring(l.text), (l.type == "WarningPoint") and "note" or "plain")
    end
end

function P.tickets(items, win, st, card, view)
    if not M.can("AnswerTickets") then          -- (the server sends a player's tickets to staff alone)
        B.label(items, getText("UI_userpanel_tickets"))
        B.sub(items, M.why("AnswerTickets"))
        return
    end
    local rows = view and view.tickets or {}
    B.label(items, getText("UI_userpanel_tickets"), tostring(view and view.ticketN or #rows))
    if #rows == 0 then B.sub(items, tr("UI_ZeD_Adm_NoTickets")) end
    for _, r in ipairs(rows) do
        local id = r.id
        local c = F.gate({ id = "tkt:" .. id, help = tr("UI_ZeD_Adm_HelpTicket"),
            run = function(ww)
                local prev = st.card
                TC.openStaff(ww, st, id)
                st.card.parent = prev
                st.card.from = "tk:tkt:" .. id
            end }, "AnswerTickets")
        items[#items + 1] = { k = "arow", left = "#" .. tostring(id) .. " " .. TC.kindWord(r.kind), leftMin = 200, right = D.stWord(D.staffSt(r.st)), meta = D.oneLine(r.first), chev = true, c = c }
    end
end

function P.playerItems(win, st, t, card, data)
    local items = {}
    local row, view = data.row, data.view
    local self = card.user == M.me()
    P.facts(items, win, st, card, row, view, self)
    if not M.live() then B.sub(items, tr("UI_ZeD_Adm_NoPartCard")) end
    if not self then P.acts(items, win, st, card, row, view, t) end
    if card.open == "kick" then P.kickPart(items, win, st, card)
    elseif card.open == "ban" then P.banPart(items, win, st, card)
    elseif card.open == "warn" then P.warnPart(items, win, st, card, row)
    elseif card.open == "role" and card.newRole then P.rolePart(items, win, st, card, (view and view.role) or row.role) end
    if M.live() then
        B.label(items, tr("UI_ZeD_Adm_ProfTraits"))
        local list = {}
        for _, s in ipairs(view and view.traits or {}) do list[#list + 1] = s end
        if view and view.prof then
            B.sub(items, (#list > 0) and tr("UI_ZeD_Adm_ProfWith", view.prof, table.concat(list, ", ")) or view.prof)
        elseif view and view.closed then
            -- (an account that is off: the server keeps its record from a role without the power for every account)
            B.sub(items, M.why("SeeNetworkUsers"))
        else
            B.sub(items, (M.can("CanSeePlayersStats") and tr("UI_ZeD_Tk_Loading")) or M.why("CanSeePlayersStats"))
        end
        P.skills(items, win, st, card, view)
    end
    -- (add XP, a trait, a profession: the game's window has them until they are ZeD's)
    F.flow(items, { F.gate({ id = "stats", text = tr("UI_ZeD_Adm_Stats"), help = tr("UI_ZeD_Adm_HelpStats"), run = function(ww) D.statsWindow(ww, card.user) end },
        "CanSeePlayersStats", function()
            if not getPlayerFromUsername(card.user) then return tr("UI_ZeD_Adm_NotSeen") end
            return nil
        end) })
    B.label(items, tr("UI_ZeD_Adm_Inventory"))
    items[#items + 1] = { k = "arow", left = getText("IGUI_PlayerStats_ManageInventory", card.user), leftMin = 300, meta = tr("UI_ZeD_Adm_GameWindow"), chev = true,
        c = F.gate({ id = "inv", help = tr("UI_ZeD_Adm_HelpInv"), run = function() M.openInventory(card.user, view and view.oid) end }, "InspectPlayerInventory") }
    P.logs(items, card)
    if M.live() then P.tickets(items, win, st, card, view) end
    return items
end

TC.kinds.player = {
    data = function(card) return { row = M.row(card.user) or { user = card.user }, view = M.cards[card.user] } end,
    tick = function(win, st, t, card)
        M.watch()
        M.loadCard(card.user)
    end,
    key = function(t, card)
        return table.concat({ tostring(M.seq), tostring(card.open), tostring(card.newRole), tostring(card.warnN), tostring(card.len), tostring(card.banIp), tostring(card.allSkills) }, ":")
    end,
    title = function(card) return card.user end,
    help = function(t, card)
        if t.confirm then return tr("UI_ZeD_Adm_HelpUnbanAsk") end
        if card.open == "ban" then return tr("UI_ZeD_Adm_HelpBanCard") end
        if card.open == "role" then return tr("UI_ZeD_Adm_HelpRoleCard") end
        return tr("UI_ZeD_Adm_HelpPlayerCard", card.user)
    end,
    items = function(win, st, t, card, data) return P.playerItems(win, st, t, card, data) end,
    flag = function(panel, win, t, card, data, x, y, w, bar)
        local name = (data.view and data.view.role) or data.row.role
        if name then
            F.drawTag(panel, x + w - px(10) - F.tagW(name), y - bar + math.floor((bar - px(16)) / 2), name, F.roleColor(name), false)
        end
        return 0
    end,
    -- Unban, behind the foot's confirm
    foot = function(win, st, t, card)
        local row = t.confirm
        if not row then return { main = {} } end
        return { question = tr("UI_ZeD_Adm_UnbanAsk", card.user), main = {
            D.btn("cno", tr("UI_ZeD_Adm_KeepBan"), function(ww)
                t.confirm = nil
                D.focusId(ww, st, "tk:unban")
            end, nil, tr("UI_ZeD_Adm_HelpKeepBan")),
            D.btn("cyes", getText("IGUI_UserList_UnBan"), function(ww)
                t.confirm = nil
                F.act(ww, st, function(cb) M.unban(row, cb) end, tr("UI_ZeD_Adm_Unbanned", card.user), function()
                    D.focusId(ww, st, "tk:back")
                    M.loadCard(card.user, true)
                end)
            end, "primary", tr("UI_ZeD_Adm_HelpUnban")) } }
    end,
    cancel = function(win, st, t, card)
        if t.confirm then
            t.confirm = nil
            D.focusId(win, st, "tk:unban")
            return true
        end
        if card.open then
            P.closePart(win, st, card, "tk:" .. (card.open == "warn" and "warnb" or card.open))
            return true
        end
        return false
    end,
}

-- ---------------------------------------------------------------------------
-- ROLES
-- ---------------------------------------------------------------------------
function AC.openRoles(win, st)
    F.push(win, st, { kind = "roles", from = "adm:tk:sum:roles" })
end

TC.kinds.roles = {
    data = function() return true end,
    tick = function() M.watch() end,
    key = function() return tostring(M.seq) .. ":" .. tostring(#M.roles()) end,
    title = function() return tr("UI_ZeD_Adm_Roles") end,
    help = function() return tr("UI_ZeD_Adm_HelpRoles") end,
    items = function(win, st, t, card)
        local items = {}
        B.sub(items, tr("UI_ZeD_Adm_RolesTop"))
        for _, r in ipairs(M.roles()) do
            local name = r.name
            local right = tr("UI_ZeD_Adm_NPlayers", M.roleCount(name))
            for _, d in ipairs(r.defaults) do
                if d == "defaultForNewUser" then right = tr("UI_ZeD_Adm_NewPlayers") .. " | " .. right end
            end
            items[#items + 1] = { k = "arow", tag = { text = name, color = r.color }, meta = r.desc, right = right, chev = true,
                c = { id = "r:" .. name, help = r.desc, land = true, run = function(ww) AC.openRole(ww, st, name) end } }
        end
        F.flow(items, { F.gate({ id = "addrole", text = getText("IGUI_RolesList_AddRole"), help = tr("UI_ZeD_Adm_HelpAddRole"), run = function(ww) AC.openRole(ww, st, nil) end }, "RolesWrite") })
        return items
    end,
}

function AC.openRole(win, st, name)
    local r = name and M.role(name)
    local d = { name = name or "", desc = r and r.desc or "", color = r and { r = r.color.r, g = r.color.g, b = r.color.b } or { r = 0.25, g = 0.65, b = 0.60 }, caps = {} }
    if r then
        for k in pairs(r.caps) do d.caps[k] = true end
    end
    D.setField(win, "rname", d.name)
    D.setField(win, "rdesc", d.desc)
    F.push(win, st, { kind = "role", name = name, d = d, from = name and ("tk:r:" .. name) or "tk:addrole", closed = {} })
end

function P.canEditRole(card)
    local r = card.name and M.role(card.name)
    return function()
        if r and r.readOnly then return tr("UI_ZeD_Adm_RoleLocked") end
        return nil
    end
end

function P.capRows(items, card)
    local d = card.d
    local isPower = {}
    for _, pw in ipairs(Adm.POWERS) do isPower[pw.cap] = true end
    local seen = {}
    local groups = {}
    for i, g in ipairs(Adm.GROUPS) do groups[i] = { id = g.id, key = g.key, caps = g.caps } end
    -- a capability a later game added: in the last group, under its own name
    local extra = {}
    for _, g in ipairs(groups) do
        for _, c in ipairs(g.caps) do seen[c] = true end
    end
    for _, c in ipairs(M.allCaps()) do
        if not seen[c] then extra[#extra + 1] = c end
    end
    local total, on = 0, 0
    for _, g in ipairs(groups) do
        local list = g.caps
        if g.id == "server" and #extra > 0 then
            list = {}
            for _, c in ipairs(g.caps) do list[#list + 1] = c end
            for _, c in ipairs(extra) do list[#list + 1] = c end
        end
        local n = 0
        for _, c in ipairs(list) do
            if d.caps[c] then n = n + 1 end
        end
        total, on = total + #list, on + n
        local shut = card.closed[g.id] == true
        local gid = g.id
        items[#items + 1] = { k = "arow", left = tr(g.key), leftMin = 300, right = tr("UI_ZeD_Adm_NOfM", n, #list), chev = true, open = not shut,
            c = { id = "g:" .. gid, help = tr("UI_ZeD_Adm_HelpGroup"), run = function() card.closed[gid] = not shut or nil; M.bump() end } }
        if not shut then
            for _, c in ipairs(list) do
                local name = c
                local help = getTextOrNull and getTextOrNull("IGUI_CapabilitiesTooltips_" .. name) or nil
                items[#items + 1] = { k = "atick", text = M.capWord(name), sub = isPower[name] and tr("UI_ZeD_Adm_PowerRoleLine") or nil,
                    c = F.gate({ id = "cap:" .. name, on = d.caps[name] == true, help = help,
                        run = function()
                            d.caps[name] = (not d.caps[name]) or nil
                            M.bump()
                        end }, "RolesWrite", P.canEditRole(card)) }
            end
        end
    end
    return on, total
end

function M.allCaps()
    if M.qaAllCaps then return M.qaAllCaps end
    local out = {}
    pcall(function()
        local list = getCapabilities()
        for i = 0, list:size() - 1 do
            local n = list:get(i):name()
            if n ~= "None" then out[#out + 1] = n end
        end
    end)
    return out
end

function P.roleItems(win, st, t, card)
    local items = {}
    local d = card.d
    local r = card.name and M.role(card.name)
    B.label(items, tr("UI_ZeD_Adm_Name"))
    if card.name then
        B.sub(items, card.name)
    else
        F.field(items, "rname", 1, tr("UI_ZeD_Adm_RoleNameHint"), true, 40)
    end
    B.label(items, tr("UI_ZeD_Adm_Description"))
    F.field(items, "rdesc", 2, tr("UI_ZeD_Adm_RoleDescHint"), card.name ~= nil, 150)
    items[#items].seed = d.desc       -- (the first time this drawer shows the field, it has only now been made)
    B.label(items, tr("UI_ZeD_Adm_Color"), tr("UI_ZeD_Adm_ColorLine"))
    local ctls = {}
    for i, c in ipairs(COLORS) do
        local col = c
        local on = math.abs(d.color.r - c[1]) < 0.02 and math.abs(d.color.g - c[2]) < 0.02 and math.abs(d.color.b - c[3]) < 0.02
        ctls[i] = F.gate({ id = "c:" .. i, style = "swatch", color = c, on = on, help = tr("UI_ZeD_Adm_ColorLine"),
            run = function()
                d.color = { r = col[1], g = col[2], b = col[3] }
                M.bump()
            end }, "RolesWrite", P.canEditRole(card))
    end
    F.flow(items, ctls)
    local label = { k = "label", text = getText("IGUI_RolesList_Edit") }
    items[#items + 1] = label
    label.text = tr("UI_ZeD_Adm_Capabilities")
    local on, total = P.capRows(items, card)
    label.right = tr("UI_ZeD_Adm_NOfM", on, total)
    if r then
        local isDefault = false
        for _, def in ipairs(r.defaults) do
            if def == "defaultForNewUser" then isDefault = true end
        end
        if isDefault then
            B.sub(items, tr("UI_ZeD_Adm_IsDefault"))
        else
            F.flow(items, { F.gate({ id = "def", text = getText("IGUI_RolesList_SetDefaultForNewUser"), help = tr("UI_ZeD_Adm_HelpDefault"),
                run = function(ww) F.act(ww, st, function(cb) M.defaultRole(card.name, cb) end, tr("UI_ZeD_Adm_DefaultDone")) end }, "RolesWrite") })
        end
        F.flow(items, {
            -- (this list runs least to most, the game's most to least: Up here is less rank)
            F.gate({ id = "rup", text = getText("IGUI_RolesList_Up"), help = tr("UI_ZeD_Adm_HelpRoleUp"),
                run = function(ww) F.act(ww, st, function(cb) M.moveRole(card.name, -1, cb) end) end }, "RolesWrite", P.canEditRole(card)),
            F.gate({ id = "rdown", text = getText("IGUI_RolesList_Down"), help = tr("UI_ZeD_Adm_HelpRoleUp"),
                run = function(ww) F.act(ww, st, function(cb) M.moveRole(card.name, 1, cb) end) end }, "RolesWrite", P.canEditRole(card)),
        })
    end
    return items
end

function P.roleChanged(win, card)
    local d = card.d
    local r = card.name and M.role(card.name)
    if not r then return true end
    if D.fieldOf(win, "rdesc") and F.text(win, "rdesc") ~= (Tk.clean(r.desc) or "") then return true end
    local c = r.color
    if math.abs(c.r - d.color.r) > 0.01 or math.abs(c.g - d.color.g) > 0.01 or math.abs(c.b - d.color.b) > 0.01 then return true end
    for k in pairs(d.caps) do
        if not r.caps[k] then return true end
    end
    for k in pairs(r.caps) do
        if not d.caps[k] then return true end
    end
    return false
end

function P.saveRole(win, st, card)
    local d = card.d
    local isNew = card.name == nil
    if isNew then d.name = F.text(win, "rname") end
    d.desc = F.text(win, "rdesc")
    F.act(win, st, function(cb) M.saveRole(d, isNew, cb) end, tr("UI_ZeD_Adm_RoleSaved"), function()
        if isNew then card.name = d.name end
        M.bump()
    end)
end

function P.roleSaveBtn(win, st, t, card)
    local b = D.btn("rsave", getText("IGUI_RolesList_Save"), function(ww) P.saveRole(ww, st, card) end, "primary", tr("UI_ZeD_Adm_HelpSaveRole"))
    local r = card.name and M.role(card.name)
    if not M.can("RolesWrite") then D.disable(b, M.why("RolesWrite"))
    elseif r and r.readOnly then D.disable(b, tr("UI_ZeD_Adm_RoleLocked"))
    elseif not card.name and F.text(win, "rname") == "" then D.disable(b, tr("UI_ZeD_Adm_WriteRoleName"))
    elseif not card.name and M.role(F.text(win, "rname")) then D.disable(b, tr("UI_ZeD_Adm_RoleExists"))
    elseif not P.roleChanged(win, card) then D.disable(b, tr("UI_ZeD_Adm_NothingToSave"))
    elseif t.busy then D.disable(b, tr("UI_ZeD_Tk_Busy")) end
    return b
end

TC.kinds.role = {
    data = function(card) return card.d end,
    tick = function() M.watch() end,
    key = function(t, card) return tostring(M.seq) .. ":" .. tostring(card.name) end,
    title = function(card)
        if card.name then return card.name end
        return tr("UI_ZeD_Adm_NewRole")
    end,
    flag = function(panel, win, t, card, data, x, y, w, bar)
        if card.name then
            F.drawTag(panel, x + w - px(10) - F.tagW(card.name), y - bar + math.floor((bar - px(16)) / 2), card.name, F.roleColor(card.name), false)
        end
        return 0
    end,
    help = function(t, card)
        if t.confirm then return tr("UI_ZeD_Adm_HelpDeleteRole") end
        return tr("UI_ZeD_Adm_HelpRole")
    end,
    items = function(win, st, t, card) return P.roleItems(win, st, t, card) end,
    foot = function(win, st, t, card)
        if t.confirm then
            return { question = tr("UI_ZeD_Adm_DeleteRoleAsk", tostring(card.name), M.roleCount(card.name)), main = {
                D.btn("cno", tr("UI_ZeD_Tk_KeepIt"), function(ww)
                    t.confirm = nil
                    D.focusId(ww, st, "tk:rdel")
                end, nil, tr("UI_ZeD_Adm_HelpKeepRole")),
                D.btn("cyes", getText("IGUI_RolesList_DeleteRole"), function(ww)
                    t.confirm = nil
                    F.act(ww, st, function(cb) M.deleteRole(card.name, cb) end, tr("UI_ZeD_Adm_RoleDeleted"), function()
                        if st.card == card then TC.back(ww, st) end      -- (a late answer: never a card opened since)
                    end)
                end, "danger", tr("UI_ZeD_Adm_HelpDeleteRole")) } }
        end
        local lead = {}
        local r = card.name and M.role(card.name)
        if card.name then
            local del = D.btn("rdel", getText("IGUI_RolesList_DeleteRole"), function(ww)
                t.confirm = true
                D.focusId(ww, st, "tk:cno")
            end, "danger", tr("UI_ZeD_Adm_HelpDeleteRole"))
            if not M.can("RolesWrite") then D.disable(del, M.why("RolesWrite"))
            elseif r and r.readOnly then D.disable(del, tr("UI_ZeD_Adm_RoleLocked"))
            elseif r and #r.defaults > 0 then D.disable(del, tr("UI_ZeD_Adm_RoleDefault")) end
            lead[1] = del
        end
        local changed = P.roleChanged(win, card)
        return { lead = lead, status = changed and tr("UI_ZeD_Adm_NotSaved") or nil, main = {
            D.btn("rcancel", getText("UI_Cancel"), function(ww) TC.back(ww, st) end, nil, tr("UI_ZeD_Adm_HelpLeaveRole")),
            P.roleSaveBtn(win, st, t, card) } }
    end,
    padX = function(win, st, t, card)
        if t.confirm then return nil end       -- (the foot asks another question now)
        local b = P.roleSaveBtn(win, st, t, card)
        return { label = b.label, run = b.run, disabled = b.disabled, why = b.why }
    end,
    cancel = function(win, st, t, card)
        if not t.confirm then return false end
        t.confirm = nil
        D.focusId(win, st, "tk:rdel")
        return true
    end,
}

-- ---------------------------------------------------------------------------
-- BANS
-- ---------------------------------------------------------------------------
function AC.openBans(win, st)
    D.setField(win, "btarget", "")
    D.setField(win, "breason", "")
    F.push(win, st, { kind = "bans", from = "adm:tk:sum:bans", len = "perm" })
end

function P.banName(b) return b.user or b.sid or b.ip or "" end

-- out of the Unban confirm: back to the row's own Unban
function P.keepBan(win, st, t)
    local from = t.confirmFrom
    t.confirm, t.confirmFrom = nil, nil
    D.focusId(win, st, from or "tk:bgo")
end

function P.banRow(items, st, b, i)
    local until_ = b.untilT and tr("UI_ZeD_Adm_Until", D.realDate(b.untilT) or "") or tr("UI_ZeD_Adm_LenPerm")
    local parts = {}
    if b.reason and b.reason ~= "" then parts[#parts + 1] = b.reason end
    if b.game then
        parts[#parts + 1] = tr("UI_ZeD_Adm_BanGame")
    else
        parts[#parts + 1] = tr("UI_ZeD_Adm_BanBy", tostring(b.by), D.day(b.day) or "")
    end
    if b.sid and b.user then parts[#parts + 1] = tr("UI_ZeD_Adm_BanSteam", b.sid) end
    if b.banIp then parts[#parts + 1] = tr("UI_ZeD_Adm_BanIpToo") end
    if b.stay then parts[#parts + 1] = tr("UI_ZeD_Adm_BanStayed") end
    local row = b
    items[#items + 1] = { k = "arow", left = P.banName(b), leftMin = 110, meta = until_, sub = table.concat(parts, " "),
        ctl = F.gate({ id = "ub:" .. i, text = getText("IGUI_UserList_UnBan"), help = tr("UI_ZeD_Adm_HelpUnban"),
            run = function(ww)
                local t = TC.qaState(st)
                t.confirm, t.confirmFrom = row, "tk:ub:" .. i
                D.focusId(ww, st, "tk:cno")
            end }, "BanUnbanUser") }
    if b.stay and b.untilT and not b.gameBan and b.id then
        F.flow(items, { F.gate({ id = "gb:" .. i, text = tr("UI_ZeD_Adm_UseGameBan"), danger = true, help = tr("UI_ZeD_Adm_HelpGameBan"),
            run = function(ww) F.act(ww, st, function(cb) M.gameBan(row.id, cb) end, tr("UI_ZeD_Adm_GameBanDone", P.banName(row))) end }, "BanUnbanUser", F.needPart) })
    end
end

function P.bansItems(win, st, t, card)
    local items = {}
    B.label(items, tr("UI_ZeD_Adm_BanOff"), tr("UI_ZeD_Adm_BanOffLine"))
    F.field(items, "btarget", 1, tr("UI_ZeD_Adm_BanTargetHint"), true, AL.TARGET_MAX)
    B.label(items, tr("UI_ZeD_Adm_Reason"), tr("UI_ZeD_Adm_ReasonOff"))
    F.field(items, "breason", 2, tr("UI_ZeD_Adm_ReasonHint"), nil, AL.REASON_MAX)
    B.label(items, tr("UI_ZeD_Adm_For"))
    F.flow(items, P.lenChips(card, "bo:"))
    B.sub(items, P.banLine(card.len))
    F.flow(items, { F.gate({ id = "bgo", text = getText("IGUI_UserList_Ban"), danger = true, help = tr("UI_ZeD_Adm_HelpBanOff"),
        run = function(ww)
            local target, reason = F.text(ww, "btarget"), F.text(ww, "breason")
            local function said(a) return a.unknown and tr("UI_ZeD_Adm_BannedUnknown", target) or tr("UI_ZeD_Adm_Banned", target) end
            F.act(ww, st, function(cb) M.banTyped(target, reason, card.len, cb) end, said, function()
                D.setField(ww, "btarget", "")
                D.setField(ww, "breason", "")
            end)
        end }, "BanUnbanUser", function()
            local target = F.text(win, "btarget")
            if target == "" then return tr("UI_ZeD_Adm_WriteTarget") end
            if F.text(win, "breason") == "" then return tr("UI_ZeD_Adm_WriteReason") end
            if Adm.targetKind(target) == "ip" and Adm.LENGTH[card.len].sec then return tr("UI_ZeD_Adm_IpPermOnly") end
            return P.timedGate(card)
        end) })
    local rows = M.banRows()
    B.label(items, tr("UI_ZeD_Adm_Banned2"), tostring(#rows))
    if #rows == 0 then B.sub(items, tr("UI_ZeD_Adm_NobodyBanned")) end
    for i, b in ipairs(rows) do P.banRow(items, st, b, i) end
    B.label(items, tr("UI_ZeD_Adm_WhatTheySee"))
    F.inset(items, nil, function()
        local sample = rows[1] or { reason = tr("UI_ZeD_Adm_ReasonHint"), untilT = getTimestamp() + 259200 }
        local appeal = ZeD.Community and ZeD.Community.appeal() or nil
        for _, s in ipairs(AC.leaveLines({ kind = "ban", reason = sample.reason or tr("UI_ZeD_Adm_ReasonHint"), untilT = sample.untilT, appeal = appeal })) do B.sub(items, s) end
    end)
    B.sub(items, tr("UI_ZeD_Adm_SeeGameLine"))
    return items
end

TC.kinds.bans = {
    data = function() return true end,
    tick = function() M.watch() end,
    key = function(t, card) return tostring(M.seq) .. ":" .. tostring(card.len) end,
    title = function() return tr("UI_ZeD_Adm_Bans") end,
    help = function(t)
        if t.confirm then return tr("UI_ZeD_Adm_HelpUnbanAsk") end
        return tr("UI_ZeD_Adm_HelpBans")
    end,
    items = function(win, st, t, card) return P.bansItems(win, st, t, card) end,
    foot = function(win, st, t, card)
        local row = t.confirm
        if not row then return { main = {} } end
        return { question = tr("UI_ZeD_Adm_UnbanAsk", P.banName(row)), main = {
            D.btn("cno", tr("UI_ZeD_Adm_KeepBan"), function(ww) P.keepBan(ww, st, t) end, nil, tr("UI_ZeD_Adm_HelpKeepBan")),
            D.btn("cyes", getText("IGUI_UserList_UnBan"), function(ww)
                t.confirm, t.confirmFrom = nil, nil
                F.act(ww, st, function(cb) M.unban(row, cb) end, tr("UI_ZeD_Adm_Unbanned", P.banName(row)))
            end, "primary", tr("UI_ZeD_Adm_HelpUnban")) } }
    end,
    cancel = function(win, st, t, card)
        if not t.confirm then return false end
        P.keepBan(win, st, t)
        return true
    end,
}

-- ---------------------------------------------------------------------------
-- SPAWN ITEMS
-- ---------------------------------------------------------------------------
function AC.openSpawn(win, st)
    local t = TC.qaState(st)
    -- (the box outlives the card: empty it, and what it last told onFilter)
    local box = D.fieldOf(win, "ifind")
    if box then
        D.setField(win, "ifind", "")
        box._lastText = ""
    end
    F.push(win, st, { kind = "spawn", from = "adm:tk:sum:spawn", page = 1, n = 1, to = "me", find = "" })
    t.spawnGen = (t.spawnGen or 0) + 1
end

function P.toWord(to)
    if to == "me" then return tr("UI_ZeD_Adm_ToYou") end
    if to == "ground" then return tr("UI_ZeD_Adm_ToGround") end
    return to
end

function P.spawnItems(win, st, t, card)
    local items = {}
    items[#items + 1] = { k = "afind", key = "ifind", hint = tr("UI_ZeD_Adm_ItemHint"), start = card.find,
        onText = function(_, text)
            card.find = text
            card.page = 1
            M.bump()
        end,
        c = { id = "f:ifind", land = true, help = tr("UI_ZeD_Adm_HelpItemFind"), run = function(ww) D.useField(ww, "ifind") end } }
    local list = M.findItems(card.find)
    B.sub(items, tr("UI_ZeD_Adm_ItemCount", #list, #M.items()))
    local pages = math.max(1, math.ceil(#list / SPAWN_PAGE))
    card.page = math.min(card.page, pages)
    local from = (card.page - 1) * SPAWN_PAGE
    for i = 1, math.min(SPAWN_PAGE, #list - from) do
        local it = list[from + i]
        local on = card.item and card.item.full == it.full
        items[#items + 1] = { k = "arow", left = it.name, leftMin = 120, meta = it.full, right = it.cat, on = on,
            c = { id = "it:" .. it.full, help = tr("UI_ZeD_Adm_HelpItem"),
                run = function()
                    card.item = it
                    card.n = 1
                    M.bump()
                end } }
    end
    if #list == 0 then B.sub(items, tr("UI_ZeD_Tk_NoMatch")) end
    if pages > 1 then
        local n = card.page
        F.flow(items, {
            F.gate({ id = "iprev", text = tr("UI_ZeD_Tk_Prev"), run = function() card.page = n - 1; M.bump() end }, nil, function()
                if n <= 1 then return tr("UI_ZeD_Tk_FirstPage") end
                return nil
            end),
            { style = "text", text = tr("UI_ZeD_Tk_PageOf", n, pages) },
            F.gate({ id = "inext", text = tr("UI_ZeD_Tk_Next"), run = function() card.page = n + 1; M.bump() end }, nil, function()
                if n >= pages then return tr("UI_ZeD_Tk_LastPage") end
                return nil
            end),
        })
    end
    if card.item then
        B.label(items, tr("UI_ZeD_Adm_HowMany"), tr("UI_ZeD_Adm_UpTo", AL.SPAWN_MAX))
        local ctls = {
            F.gate({ id = "nm", text = "-", run = function() card.n = card.n - 1; M.bump() end }, nil, function()
                if card.n <= 1 then return tr("UI_ZeD_Adm_SpawnLeast") end
                return nil
            end),
            { style = "text", text = tostring(card.n), tone = "text" },
            F.gate({ id = "np", text = "+", run = function() card.n = card.n + 1; M.bump() end }, nil, function()
                if card.n >= AL.SPAWN_MAX then return tr("UI_ZeD_Adm_UpTo", AL.SPAWN_MAX) end
                return nil
            end),
        }
        for _, n in ipairs({ 1, 5, 10, 50 }) do
            ctls[#ctls + 1] = { id = "n" .. n, style = "chip", text = tostring(n), on = card.n == n, run = function() card.n = n; M.bump() end }
        end
        F.flow(items, ctls)
        B.label(items, tr("UI_ZeD_Adm_To"))
        local tos = {
            { id = "to:me", style = "chip", text = tr("UI_ZeD_Adm_MyInventory"), on = card.to == "me", run = function() card.to = "me"; M.bump() end },
            F.gate({ id = "to:ground", style = "chip", text = tr("UI_ZeD_Adm_GroundHere"), on = card.to == "ground", run = function() card.to = "ground"; M.bump() end }, nil, F.needPart),
        }
        local me = M.me()
        for _, r in ipairs(M.rows) do
            if r.on and r.user ~= me then
                local u = r.user
                tos[#tos + 1] = { id = "to:" .. u, style = "chip", text = u, on = card.to == u, run = function() card.to = u; M.bump() end }
            end
        end
        F.flow(items, tos)
    end
    return items
end

function P.spawnBtn(win, st, t, card)
    local it = card.item
    if not it then return nil end
    local b = D.btn("spawnb", tr("UI_ZeD_Adm_SpawnBtn"), function(ww)
        F.act(ww, st, function(cb) M.spawn(it.full, card.n, card.to, cb) end, tr("UI_ZeD_Adm_Spawned", card.n, it.name, P.toWord(card.to)))
    end, "primary", tr("UI_ZeD_Adm_HelpSpawnBtn"))
    if not M.can("AddItem") then D.disable(b, M.why("AddItem"))
    elseif card.to == "ground" and not M.live() then D.disable(b, tr("UI_ZeD_Adm_NeedPart"))
    elseif t.busy then D.disable(b, tr("UI_ZeD_Tk_Busy")) end
    return b
end

TC.kinds.spawn = {
    data = function() return true end,
    tick = function() M.watch() end,
    key = function(t, card) return table.concat({ tostring(M.seq), tostring(card.page), tostring(card.n), tostring(card.to), tostring(card.item and card.item.full), tostring(card.find) }, ":") end,
    title = function() return tr("UI_ZeD_Adm_Spawn") end,
    help = function(t, card) return tr(card.item and "UI_ZeD_Adm_HelpSpawnLog" or "UI_ZeD_Adm_HelpSpawn") end,
    items = function(win, st, t, card) return P.spawnItems(win, st, t, card) end,
    foot = function(win, st, t, card)
        local b = P.spawnBtn(win, st, t, card)
        if not b then return { main = {} } end
        return { status = tr("UI_ZeD_Adm_SpawnLine", card.n, card.item.name, P.toWord(card.to)), main = { b } }
    end,
    padX = function(win, st, t, card)
        local b = P.spawnBtn(win, st, t, card)
        if not b then return nil end
        return { label = b.label, run = b.run, disabled = b.disabled, why = b.why }
    end,
}

-- ---------------------------------------------------------------------------
-- QA
-- ---------------------------------------------------------------------------
function AC.qaOpen(win, st, kind, a, b)
    if kind == "player" then AC.openPlayer(win, st, a, "adm:tk:p:" .. a)
    elseif kind == "roles" then AC.openRoles(win, st)
    elseif kind == "role" then
        st.card = nil
        AC.openRoles(win, st)
        AC.openRole(win, st, a)
    elseif kind == "bans" then AC.openBans(win, st)
    elseif kind == "spawn" then AC.openSpawn(win, st) end
end

function AC.qaPart(st, part, extra)
    local card = st.card
    if part == "role" then
        card.open, card.newRole, card.keep = "role", extra, {}
    else
        card.open = part
    end
    M.bump()
end

AC._F, AC._P = F, P

return AC
