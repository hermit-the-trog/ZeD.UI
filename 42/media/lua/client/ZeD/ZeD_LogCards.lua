-- ZeD-UI/42/media/lua/client/ZeD/ZeD_LogCards.lua
-- ============================================================================
-- THE LOG CARD (ZeDUI/MP_ADMIN_SCOPE.md, Phase 4; the drawing is mockups/zed_logs_v1.html). Drawing and input only:
-- ZeD_Log.lua is the model. The card runs on the ticket cards' engine (ZeD_TicketCards.lua): the back bar, the scroll, the
-- fields, the pick list and the pad stops are all that file's, and the buttons are the admin cards' (ZeD_AdminCards.lua).
--   the Admin tab's row   LC.homeRow: the Log card, or the game's own PvP log without the server part
--   the ticket card's row LC.aroundFact: Around ticket #14, the same card with a place and a time on it
--   the Log card          kind chips, who, last hour / today / 3 days, Find; each line the real time and the in-game day, the kind
--                         as a word on a colored tag, who, what, where, and the source when it isn't ZeD's. Pick a line for Go
--                         there and the players' cards; from a ticket, Add to ticket too
-- A control that cannot be used stays on the card, gray, and says why. All player text is drawn with drawText, never through
-- the game's rich text. Simple mode draws this same card.
--
-- QA: ZeD.Logs.qaHold, qaLink (ZeD_Log.lua) and LC.qaOpen(win, st, around), LC.qaPick(st, s).
-- ZeDUI/tools/qa/mp_log_cards.lua walks every state of the drawing with these.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/Tr"
require "ZeD/ZeD_TicketProto"
require "ZeD/ZeD_LogProto"
require "ZeD/ZeD_ServerLink"
require "ZeD/ZeD_Log"
require "ZeD/ZeD_TicketCards"
require "ZeD/ZeD_AdminCards"

ZeD = ZeD or {}
ZeD.LogCards = ZeD.LogCards or {}
local LC = ZeD.LogCards
local Lm = ZeD.Logs
local Lg = ZeD.Lg
local Tk = ZeD.Tk
local TC = ZeD.TicketCards
local AC = ZeD.AdminCards
local M = ZeD.Admin
local D = TC._D
local B = TC._B
local F = AC._F

local ROW_V, COL_W, COL_GAP = 5, 66, 8    -- design units, as drawn
local FIND_MS = 400                       -- Find waits this long after the last key
local ASK_MS = 700                        -- at most one read in this long: the server's general limit drops past 2 a second
local LIVE_MS = 10000                     -- the first page is read again this often while the card shows
local NAME_ON_BTN = 16                    -- a name past this is cut on a player's card button

local P = {}     -- the card's parts (a table: Kahlua counts every local in the chunk)

local function tr(k, ...) return ZeD.tr(k, ...) end
local function px(n) return ZeD.T.px(n) end
local function now() return getTimestampMs() end

-- ---------------------------------------------------------------------------
-- THE FILTERS' ITEMS: a label at the left, as drawn, and the controls beside it
-- ---------------------------------------------------------------------------
-- (a label at the left is the list's "chips" item without its fill, and with a popup box beside chips)
TC.items.lfilt = {
    gap = 2,
    layout = function(win, it, w) return D.flow(it.ctls, w, it.lw + px(8)) + px(4) end,
    draw = function(panel, win, t, it, x, dy, w, mx, my, ctx)
        local T = ZeD.T
        local lc = T.textHead
        panel:drawText(it.label, x, dy + math.floor((D.chipH() - ZeD.TM:getFontHeight(T.fontF1)) / 2), lc.r, lc.g, lc.b, lc.a or 1, T.fontF1)
        for _, c in ipairs(it.ctls) do
            local cx, cy = x + c.dx, dy + c.dy
            local id = ctx.prefix .. c.id
            if c.box then
                local hov = mx ~= nil and mx >= cx and mx < cx + c.w and my >= cy and my < cy + c.h
                ZeD.Molecules.drawPopupMenu(panel, cx, cy, c.w, c.h, c.text, hov, D.focusOf(win, id), false, nil, true)
                if hov and c.help then ZeD.Help.set(win, c.help) end
                c.bx, c.by = cx, cy
            else
                D.drawChip(panel, win, cx, cy, c.w, c.h, c, id, mx, my)
            end
            ctx.hits[#ctx.hits + 1] = { x = cx, y = cy, w = c.w, h = c.h, c = c }
        end
    end,
    stops = function(it, x0, dy, w, add)
        for _, c in ipairs(it.ctls) do add(c, x0 + c.dx, dy + c.dy, c.w, c.h, it.y + c.dy) end
    end,
}

TC.items.lfind = {
    gap = 2,
    layout = function() return ZeD.T.inputH + px(4) end,
    draw = function(panel, win, t, it, x, dy, w, mx, my, ctx)
        local T, A = ZeD.T, ZeD.Atoms
        local h = T.inputH
        local lc = T.textHead
        panel:drawText(it.label, x, dy + math.floor((h - ZeD.TM:getFontHeight(T.fontF1)) / 2), lc.r, lc.g, lc.b, lc.a or 1, T.fontF1)
        local fx = x + it.lw + px(8)
        local fw = w - it.lw - px(8)
        local box = D.fieldOf(win, it.key)
        if not box then
            box = D.makeField(win, panel, it.key, false, it.hint)
            box._lastText = it.start or ""
            D.setField(win, it.key, box._lastText)
        end
        box.onFilter = it.onText
        D.mark(panel, fx, dy, fw, h, D.focusOf(win, ctx.prefix .. it.c.id))
        if dy >= ctx.viewY and dy + h <= ctx.viewY + ctx.viewH and not ctx.covered then
            D.showField(box, fx, dy, fw, h)
        else
            local bg, bc = T.surf1, T.borderS
            panel:drawRect(fx, dy, fw, h, bg.a or 1, bg.r, bg.g, bg.b)
            panel:drawRectBorder(fx, dy, fw, h, bc.a or 1, bc.r, bc.g, bc.b)
            local text = box:getText() or ""
            local tc = (text == "") and T.textDim or T.text
            local s = A.truncateText((text == "") and it.hint or text, T.fontF2, fw - px(32))
            panel:drawText(s, fx + px(26), dy + math.floor((h - ZeD.TM:getFontHeight(T.fontF2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
        end
        ctx.hits[#ctx.hits + 1] = { x = fx, y = dy, w = fw, h = h, c = it.c, keep = true }
    end,
    stops = function(it, x0, dy, w, add) add(it.c, x0 + it.lw + px(8), dy, w - it.lw - px(8), ZeD.T.inputH, it.y) end,
}

-- ---------------------------------------------------------------------------
-- A LINE: the time and the day at the left, the tag, who and what, the place and the source, the buttons when it is picked
-- ---------------------------------------------------------------------------
local _tag = { keepCase = true }

function P.tagText(r) return ZeD.upper(P.kindWord(r.k)) end

function P.kindWord(k)
    if Lg.KIND[k] then return tr("UI_ZeD_Log_Kind_" .. k) end
    return tr("UI_ZeD_Log_Kind_other")
end

-- the words after the tag: the first line beside it, the rest under it
function P.wrapAfter(text, font, w1, w2)
    local first = D.wrap(text, font, math.max(1, w1))
    if #first <= 1 then return first end
    local head = first[1]
    local from = #head + 1
    while string.sub(text, from, from) == " " do from = from + 1 end
    local out = { head }
    for _, s in ipairs(D.wrap(string.sub(text, from), font, math.max(1, w2))) do out[#out + 1] = s end
    return out
end

function P.lineH(it)
    local T = ZeD.T
    local f2h, f3h = ZeD.TM:getFontHeight(T.fontF2), ZeD.TM:getFontHeight(T.fontF3)
    local body = #it.lines * f2h + #it.meta * f3h + px(2)
    local col = #it.col * f3h
    return math.max(body, col) + 2 * px(ROW_V)
end

TC.items.lline = {
    layout = function(win, it, w)
        local T = ZeD.T
        if it.wrapW ~= w then
            it.wrapW = w
            local cw = 0
            for _, s in ipairs(it.col) do cw = math.max(cw, ZeD.TM:MeasureStringX(T.fontF3, s)) end
            -- (the column is the drawing's width, or the words' at Large text, and never more than a third of the line)
            it.colW = math.min(math.max(px(COL_W), cw), math.floor(w / 3))
            it.tx = it.colW + px(COL_GAP)
            local room = w - it.tx
            it.tagW = ZeD.Atoms.tagW(it.tag, false, _tag) + px(6)
            it.lines = P.wrapAfter(it.text, T.fontF2, room - it.tagW, room)
            it.meta = D.wrap(it.metaText, T.fontF3, math.max(1, room))
        end
        it.rowH = P.lineH(it)
        if it.btns then
            it.btnH = F.flowLayout(win, it.btns, w - it.tx) + px(6)
            return it.rowH + it.btnH
        end
        return it.rowH
    end,
    draw = function(panel, win, t, it, x, dy, w, mx, my, ctx)
        local T, A = ZeD.T, ZeD.Atoms
        local c = it.c
        local f2h, f3h = ZeD.TM:getFontHeight(T.fontF2), ZeD.TM:getFontHeight(T.fontF3)
        local hov = mx ~= nil and mx >= x and mx < x + w and my >= dy and my < dy + it.rowH
        if it.open then
            local a = T.accent
            panel:drawRect(x, dy, w, it.h, 0.15, a.r, a.g, a.b)
        elseif hov then
            local hv = T.hover
            panel:drawRect(x, dy, w, it.rowH, hv.a or 1, hv.r, hv.g, hv.b)
        end
        if hov and c.help then ZeD.Help.set(win, c.help) end
        local onF = D.mark(panel, x, dy, w, it.rowH, D.focusOf(win, ctx.prefix .. c.id))
        local dim = onF and T.textOnFocus or T.textDim
        local tc = onF and T.textOnFocus or T.text
        local y0 = dy + px(ROW_V)
        for i, s in ipairs(it.col) do
            panel:drawText(A.truncateText(s, T.fontF3, it.colW), x, y0 + (i - 1) * f3h, dim.r, dim.g, dim.b, dim.a or 1, T.fontF3)
        end
        local tx = x + it.tx
        local kc = onF and T.textOnFocus or Lm.kindColor(it.kindK)
        _tag.textColor, _tag.frameColor, _tag.alpha = kc, kc, 1
        A.drawTag(panel, tx, y0, it.tag, nil, _tag)
        local room = w - it.tx
        for i, s in ipairs(it.lines) do
            local sx = tx + ((i == 1) and it.tagW or 0)
            local ly = y0 + (i - 1) * f2h
            panel:drawText(s, sx, ly, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
            -- (the name stands out, as drawn: the fonts have no bold, so it is struck twice)
            if i == 1 and string.sub(s, 1, #it.who) == it.who then
                panel:drawText(it.who, sx + px(1), ly, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
            end
        end
        local my2 = y0 + #it.lines * f2h + px(2)
        for i, s in ipairs(it.meta) do
            panel:drawText(s, tx, my2 + (i - 1) * f3h, dim.r, dim.g, dim.b, dim.a or 1, T.fontF3)
        end
        ctx.hits[#ctx.hits + 1] = { x = x, y = dy, w = w, h = it.rowH, c = c }
        if it.btns then
            for _, b in ipairs(it.btns.ctls) do F.drawCtl(panel, win, t, b, tx + b.dx, dy + it.rowH + b.dy, mx, my, ctx) end
        end
        ZeD.Atoms.drawDividerH(panel, x, dy + it.h - T.hair, w, false)
    end,
    stops = function(it, x0, dy, w, add)
        add(it.c, x0, dy, w, it.rowH, it.y)
        if it.btns then
            for _, b in ipairs(it.btns.ctls) do add(b, x0 + it.tx + b.dx, dy + it.rowH + b.dy, b.w, b.h, it.y + it.rowH + b.dy) end
        end
    end,
}

-- the column's words: "8:26 PM", "Day 12"; a line from another date says the date too
function P.col(r, today)
    local clock, d = D.clock(r.t)
    local out = {}
    out[1] = clock or tostring(r.t)
    local dayWord = D.day(r.day) or ""
    if d and today and (d.day ~= today.day or d.month ~= today.month) then
        out[2] = tr("UI_ZeD_Log_MonthDay", tr(D.MONTHS[d.month or 1]), d.day or 1)
        out[3] = dayWord
    else
        out[2] = dayWord
    end
    return out
end

-- ---------------------------------------------------------------------------
-- WHAT THE CARD HOLDS
-- ---------------------------------------------------------------------------
function P.goBtn(st, r)
    local place = { x = r.x, y = r.y, z = r.z }
    return { id = "lgo:" .. r.s, text = tr("UI_ZeD_Tk_GoThere"), help = tr("UI_ZeD_Log_HelpGo"),
        live = function(c)
            if r.hid then
                c.disabled, c.why = true, tr("UI_ZeD_Log_NoPlaceLine")
            elseif not r.x then
                c.disabled, c.why = true, tr("UI_ZeD_Log_NoPlaceHeld")
            elseif r.src == "tap" then
                -- (any client can write a line: one press must not take staff to a spot a griefer chose)
                c.disabled, c.why = true, tr("UI_ZeD_Log_NoGoTap")
            else
                D.liveGo(c)
            end
        end,
        run = function() D.goThere(st, place) end }
end

function P.cardBtn(st, card, id, r, user)
    -- (one line on a button, whatever the name: a name can run to 64 characters)
    local short = (#user > NAME_ON_BTN) and (string.sub(user, 1, NAME_ON_BTN) .. "...") or user
    return F.gate({ id = id .. r.s, text = tr("UI_ZeD_Log_PlayerCard", short), help = tr("UI_ZeD_Adm_HelpPlayer"),
        run = function(ww)
            card.pos = TC.qaState(st).scroll.scrollPos
            AC.openPlayer(ww, st, user, "tk:" .. id .. r.s)
        end }, "CanSeePlayersStats", F.needPart)
end

function P.noteBtn(st, card, r)
    return F.gate({ id = "lnote:" .. r.s, text = tr("UI_ZeD_Log_AddTo", card.around), help = tr("UI_ZeD_Log_HelpAdd"),
        run = function(ww)
            F.act(ww, st, function(cb) Lm.toNote(card.around, r.s, cb) end, tr("UI_ZeD_Log_Added", card.around), function()
                card.added[r.s] = true
                Lm.bump()
            end)
        end }, "AnswerTickets", function() return card.added[r.s] and tr("UI_ZeD_Log_AlreadyOn") or nil end)
end

function P.lineItem(st, card, r, today)
    local who = Lm.whoText(r)
    local open = card.sel == r.s
    local it = { k = "lline", r = r, kindK = r.k, tag = P.tagText(r), who = who, text = who .. " " .. Lm.lineText(r), metaText = Lm.metaText(r), col = P.col(r, today),
        open = open, c = { id = "l:" .. r.s, help = tr("UI_ZeD_Log_HelpLine"), run = function()
            if card.sel == r.s then card.sel = nil else card.sel = r.s end
            Lm.bump()
        end } }
    if open then
        local ctls = { P.goBtn(st, r) }
        if who ~= "" and r.who ~= Tk.SYS and r.src ~= "tap" then ctls[#ctls + 1] = P.cardBtn(st, card, "lpc:", r, who) end
        local other = Lm.otherName(r)
        if other and other ~= who then ctls[#ctls + 1] = P.cardBtn(st, card, "lpo:", r, other) end
        if card.around then ctls[#ctls + 1] = P.noteBtn(st, card, r) end
        it.btns = { ctls = ctls }
    end
    return it
end

function P.filterItems(items, st, card, page)
    local T, tm = ZeD.T, ZeD.TM
    local lKind, lWho, lFind = tr("UI_ZeD_Tk_FilterKind"), tr("UI_ZeD_Log_FWho"), tr("UI_ZeD_Tk_FilterFind")
    local lw = math.max(tm:MeasureStringX(T.fontF1, lKind), tm:MeasureStringX(T.fontF1, lWho), tm:MeasureStringX(T.fontF1, lFind))
    local function setKind(k)
        card.kindF, card.page, card.sel = k, 1, nil
        Lm.bump()
    end
    local chips = { { id = "lk:All", text = tr("UI_ZeD_Tk_ShowAll"), on = card.kindF == nil, help = tr("UI_ZeD_Log_HelpKind"), run = function() setKind(nil) end } }
    for _, k in ipairs(Lg.KINDS) do
        if k ~= "container" or (page and page.opt) then
            chips[#chips + 1] = { id = "lk:" .. k, text = P.kindWord(k), on = card.kindF == k, help = tr("UI_ZeD_Log_HelpKind"), run = function() setKind(k) end }
        end
    end
    items[#items + 1] = { k = "lfilt", label = lKind, lw = lw, ctls = chips }
    local word = card.who or tr("UI_ZeD_Log_Anyone")
    local who = { id = "lwho", text = word, box = true, boxW = ZeD.Molecules.popupMenuW(word, true), help = tr("UI_ZeD_Log_HelpWho") }
    who.run = function(ww)
        local modes = { { id = "ALL", label = tr("UI_ZeD_Log_Anyone") } }
        for _, u in ipairs(card.names or {}) do modes[#modes + 1] = { id = "u:" .. u, label = u } end
        TC.openPicker(ww, st, who, modes, card.who and ("u:" .. card.who) or "ALL", function(id)
            card.who = (id ~= "ALL") and string.sub(id, 3) or nil
            card.page, card.sel = 1, nil
            Lm.bump()
        end)
    end
    local ctls = { who }
    if not card.around then
        for _, w in ipairs(Lg.WHENS) do
            ctls[#ctls + 1] = { id = "lw:" .. w, text = tr("UI_ZeD_Log_When_" .. w), on = card.when == w, help = tr("UI_ZeD_Log_HelpWhen"),
                run = function()
                    card.when, card.page, card.sel = w, 1, nil
                    Lm.bump()
                end }
        end
    end
    items[#items + 1] = { k = "lfilt", label = lWho, lw = lw, ctls = ctls }
    items[#items + 1] = { k = "lfind", key = "lfind", label = lFind, lw = lw, hint = tr("UI_ZeD_Log_FindHint"), start = card.find or "",
        onText = function(_, text)
            card.find = string.sub(text or "", 1, Lg.L.FIND_MAX)
            card.findAt = now()
        end,
        c = { id = "lfind", help = tr("UI_ZeD_Log_HelpFind"), run = function(ww) D.useField(ww, "lfind") end } }
end

-- the band over a card opened from a ticket, as drawn
function P.band(items, st, card, page)
    local a = page and page.around
    F.inset(items, "warning", function()
        B.label(items, tr("UI_ZeD_Log_Around", card.around))
        if a then
            local from, to = D.clock(a.from) or "", D.clock(a.to) or ""
            B.sub(items, tr("UI_ZeD_Log_AroundSub", Tk.NEAR, tostring(a.x) .. " x " .. tostring(a.y), from, to))
            for _, m in ipairs(a.missed or {}) do
                B.sub(items, tr("UI_ZeD_Log_Missed", tostring(m.who), D.clock(m.from) or "", D.clock(m.to) or "", D.clock(a.filed) or ""))
                items[#items].tone = "warning"
            end
        end
        F.flow(items, { { id = "lclear", text = tr("UI_ZeD_Log_Clear"), help = tr("UI_ZeD_Log_HelpClear"),
            run = function(ww)
                card.around, card.page, card.sel = nil, 1, nil
                Lm.bump()
                D.focusId(ww, st, "tk:lk:All")
            end } })
    end)
end

function P.pager(items, card, page)
    local n, of = page.page or 1, page.pages or 1
    if of < 2 then return end
    local function go(to)
        card.page, card.sel = to, nil
        Lm.bump()
    end
    F.flow(items, { { id = "lpage", style = "text", text = tr("UI_ZeD_Tk_PageOf", n, of) },
        { id = "lprev", text = tr("UI_ZeD_Tk_Prev"), disabled = n <= 1, why = (n <= 1) and tr("UI_ZeD_Tk_FirstPage") or nil, run = function() go(n - 1) end },
        { id = "lnext", text = tr("UI_ZeD_Tk_Next"), disabled = n >= of, why = (n >= of) and tr("UI_ZeD_Tk_LastPage") or nil, run = function() go(n + 1) end } })
end

function P.footWords(page)
    local n = page.n or 0
    local s = tr((n == 1) and "UI_ZeD_Log_OneLine" or "UI_ZeD_Log_Lines", n)
    if not page.opt then s = s .. " " .. tr("UI_ZeD_Log_NoContainer") end
    if TC.DATE_SAYS_UTC then s = s .. " " .. tr("UI_ZeD_Log_TimesUtc") end
    return s
end

function P.items(win, st, t, card, page)
    local items = {}
    if card.around then P.band(items, st, card, page) end
    P.filterItems(items, st, card, page)
    if page then
        if page.names then card.names = page.names end
        local rows = page.rows or {}
        if #rows == 0 then B.sub(items, tr("UI_ZeD_Log_NoMatch")) end
        local _, today = D.clock(getTimestamp())
        for i, r in ipairs(rows) do
            local it = P.lineItem(st, card, r, today)
            it.c.land = i == 1
            items[#items + 1] = it
        end
        P.pager(items, card, page)
        B.sub(items, P.footWords(page))
    else
        B.sub(items, tr("UI_ZeD_Tk_Loading"))
    end
    -- (nothing to land on but the filters while the page is on its way)
    if #(page and page.rows or {}) == 0 then
        for _, it in ipairs(items) do
            if it.k == "lfilt" then
                it.ctls[1].land = true
                break
            end
        end
    end
    return items
end

-- a card back on top after another log card sat over it: stacked log cards share the Find field and the page, so its own words go
-- back in the field and its read goes out again
function P.onTop(win, card)
    if P.top == card then return end
    P.top = card
    D.setField(win, "lfind", card.find or "")
    local box = D.fieldOf(win, "lfind")
    if box then box._lastText = card.find or "" end
    card.sentKey, card.askAt = nil, nil
end

-- what the card asks for now, and the same as a key
function P.query(card)
    local find = Tk.clean(card.find)
    if find == "" then find = nil end
    return { kind = card.kindF, who = card.who, when = card.when, find = find, page = card.page, around = card.around }
end
function P.queryKey(q)
    return table.concat({ tostring(q.kind), tostring(q.who), tostring(q.when), tostring(q.find), tostring(q.page), tostring(q.around) }, ":")
end

function P.refused(win, st, card, a)
    if st.card ~= card then return end
    -- (a read that was dropped or went unanswered is asked again: a page the first read can't bring back would strand the card)
    if a.err == "wait" or a.err == "fail" then card.sentKey = nil end
    if a.err == "wait" then return end
    D.flash(TC.qaState(st), F.errOf(a))
    if a.err == "perm" or a.err == "gone" then TC.back(win, st) end
end

TC.kinds.log = {
    data = function() return Lm.page end,
    key = function(t, card)
        return table.concat({ tostring(Lm.seq), tostring(card.sel), tostring(card.kindF), tostring(card.who), tostring(card.when), tostring(card.around) }, ":")
    end,
    title = function() return tr("UI_ZeD_Log_Title") end,
    tick = function(win, st, t, card)
        if card.pos then
            t.scroll:setScrollPos(card.pos)
            card.pos = nil
        end
        P.onTop(win, card)
        if Lm.qaHold then return end
        -- (a second log card, from a ticket on a player's card over this one, took the page with it: read this one's again)
        if card.had and not Lm.page and not Lm.waiting then
            card.had, card.sentKey, card.askAt = nil, nil, nil
            t.pushedAt = now()
        end
        local clock = now()
        if card.findAt then
            if clock - card.findAt < FIND_MS then return end
            card.findAt, card.page = nil, 1
        end
        if card.askAt and clock - card.askAt < ASK_MS then return end
        local q = P.query(card)
        local key = P.queryKey(q)
        if key ~= card.sentKey or (card.page == 1 and clock - (card.askAt or 0) >= LIVE_MS) then
            card.sentKey, card.askAt = key, clock
            Lm.ask(q, function(a) P.refused(win, st, card, a) end)
        end
    end,
    help = function(t, card)
        return tr(card.around and "UI_ZeD_Log_HelpAround" or "UI_ZeD_Log_HelpCard")
    end,
    items = function(win, st, t, card, data) return P.items(win, st, t, card, data) end,
    foot = function() return { main = {} } end,
    -- how many lines pass, of how many, at the bar's right as drawn
    flag = function(panel, win, t, card, data, x, y, w, bar)
        if data then
            local T = ZeD.T
            local s = tr("UI_ZeD_Log_Count", data.n or 0, data.all or 0)
            ZeD.Atoms.drawTextRight(panel, s, x + w - px(10), y - bar + math.floor((bar - ZeD.TM:getFontHeight(T.fontF3)) / 2), T.fontF3, T.textDim)
        end
        return 0
    end,
    back = function() Lm.close() end,
}

-- ---------------------------------------------------------------------------
-- OPENING
-- ---------------------------------------------------------------------------
function P.open(win, st, card)
    Lm.close()
    D.setField(win, "lfind", "")
    local box = D.fieldOf(win, "lfind")
    if box then box._lastText = "" end
    card.kind, card.when, card.page, card.added = "log", Lg.DEFAULT_WHEN, 1, {}
    F.push(win, st, card)
end

function LC.open(win, st) P.open(win, st, { from = "adm:tk:sum:log" }) end
function LC.openAround(win, st, id) P.open(win, st, { from = "tk:around", around = id }) end

-- the game's own PvP log, with no server part to hold ZeD's (the Admin tab's More tools has the same window)
function P.gameLog(win)
    local p = win._playerObj or getPlayer()
    for _, m in ipairs(ZeD.AdminTab and ZeD.AdminTab.MORE or {}) do
        if m.id == "pvplog" then
            local ok, err = pcall(m.run, p)
            if not ok then ZeD.logOnce("log card: the game's PvP log", err) end
        end
    end
end

function LC.homeRow(L, st, AP)
    L[#L + 1] = { k = "head", text = tr("UI_ZeD_Log_Title") }
    if Lm.live() then
        AP.summary(L, "sum:log", tr("UI_ZeD_Log_Sum"), nil, Lg.VIEW_CAP, function(ww) LC.open(ww, st) end)
    else
        AP.summary(L, "sum:log", tr("UI_ZeD_Log_SumGame"), nil, "PVPLogTool", function(ww) P.gameLog(ww) end)
    end
end

-- the ticket card's row. A ticket with no place has nothing to look around: gray, with why
function LC.aroundFact(items, st, data)
    local c = { id = "around", text = tr("UI_ZeD_Log_Show"), help = tr("UI_ZeD_Log_HelpShow", data.id),
        live = function(cc)
            local why = nil
            if not Lm.live() then why = tr("UI_ZeD_Adm_NeedPart")
            elseif not (data.place and data.filed) then why = tr("UI_ZeD_Log_NoPlaceTicket") end
            cc.disabled, cc.why = why ~= nil, why
        end,
        run = function(ww) LC.openAround(ww, st, data.id) end }
    B.fact(items, tr("UI_ZeD_Log_Title"), tr("UI_ZeD_Log_FactAround"), c)
end

-- ---------------------------------------------------------------------------
-- QA
-- ---------------------------------------------------------------------------
function LC.qaOpen(win, st, around)
    st.card = nil
    if around then LC.openAround(win, st, around) else LC.open(win, st) end
end
function LC.qaPick(st, s)
    st.card.sel = s
    Lm.bump()
end
function LC.qaSet(st, field, value)
    st.card[field] = value
    Lm.bump()
end

LC._P = P

return LC
