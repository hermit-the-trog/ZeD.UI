-- ZeD-UI/42/media/lua/client/ZeD/ZeD_CommunityCards.lua
-- ============================================================================
-- COMMUNITY IN CARDS (ZeDUI/MP_ADMIN_SCOPE.md, Phase 5; the drawing is mockups/zed_community_v1.html, its Server extras are Phase
-- 6). Drawing and input only: ZeD_Community.lua is the model. The frame is the ticket cards' (ZeD_TicketCards.lua). This file
-- registers three cards and its own items with it:
--   cmrules   the rules, as on joining, from the Server tab
--   cmedit    Rules and news, from the Admin tab: typed in place, Save in the foot; news posts at once
--   cmjoin    joining: the same card in a window of its own, over a cover, with Leave and I agree
-- and gives the two tabs their pieces: the message of the day, The rules, News, and the Rules and news row.
--
-- The appeal line is text, drawn with drawText like all player text, and never a link: nothing here opens anything.
--
-- The join window keeps to itself on a controller, as ZeD_Prompt does: the pad's focus is on the window, Up and Down scroll, Left
-- and Right pick Leave or I agree, and the window's focus never leaves those two. It is not a Focus Manager window. The manager
-- would open the pair under it (Y, and the first press of a pad), so while it stands Focus.held() stops that, and the window takes
-- the pad back from whatever else takes it, a pad that arrives late included. It holds nothing it could trap anyone with: it goes
-- up only on the server's word (a server without this part never says it), I agree closes it without waiting for an answer, a
-- draw that fails closes it, safe mode closes it, and so does the connection ending. If it cannot be built nothing is left up.
--
-- A client that will not agree cannot play only because this client leaves: the server cannot remove a player (A7). The world
-- runs on behind the cover, as behind any window.
--
-- Simple mode draws these same cards: they are already plain.
--
-- QA, read at draw time: ZeD.Community.qaHold, qaLink (ZeD_Community.lua), and CM.qaOpen(win, st, kind), CM.qaJoinCard(st).
-- ZeDUI/tools/qa/mp_community_cards.lua walks every state of the drawing with these.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/Tr"
require "ZeD/ZeD_TicketProto"
require "ZeD/ZeD_CommunityProto"
require "ZeD/ZeD_ServerLink"
require "ZeD/ZeD_Community"
require "ZeD/ZeD_TicketCards"
require "ZeD/ZeD_AdminCards"
require "ISUI/ISServerDisconnectUI"

ZeD = ZeD or {}
ZeD.CommunityCards = ZeD.CommunityCards or {}
local CM = ZeD.CommunityCards
local M = ZeD.Community
local A2 = ZeD.Admin
local TC = ZeD.TicketCards
local AC = ZeD.AdminCards
local C = ZeD.Tickets
local Cm = ZeD.Cm
local Tk = ZeD.Tk
local D, B, F = TC._D, TC._B, AC._F
local CL = Cm.L

local NUM_W = 22             -- design units: a rule's number
local JOIN_W, JOIN_H = 480, 620
local PAD_SCROLL_LINES = 3   -- a D-pad press on the join screen

local P = {}     -- the file's helpers (a table: Kahlua counts every local in the chunk)
CM._P = P

local function tr(k, ...) return ZeD.tr(k, ...) end
local function px(n) return ZeD.T.px(n) end

-- ---------------------------------------------------------------------------
-- WHAT THE RULES SAY: the body of the join screen and of the rules card
-- ---------------------------------------------------------------------------
function P.changed(v)
    local day = v.changed and D.shortDate(v.changed) or nil
    return day and tr("UI_ZeD_Cm_Changed", day) or nil
end

function P.ruleItem(i, text, isNew)
    return { k = "cmrule", n = i, text = text, new = isNew, c = { id = "cmr:" .. tostring(i) } }
end

function P.wrongLine(v)
    local appeal = (v.appeal and v.appeal ~= "") and v.appeal or nil
    if appeal then return tr("UI_ZeD_Cm_WrongAppeal", appeal) end
    return tr("UI_ZeD_Cm_Wrong")
end

-- marks: rule number -> true
function P.body(items, v, marks)
    if (v.motd or "") ~= "" then
        B.label(items, tr("UI_ZeD_Cm_Motd"))
        items[#items + 1] = { k = "cmrule", text = v.motd, c = { id = "cmmotd" } }
    end
    B.label(items, tr("UI_ZeD_Cm_Rules"), P.changed(v))
    for i = 1, v.rules.n do
        local r = v.rules[i]
        if r then items[#items + 1] = P.ruleItem(i, r.text, marks and marks[i]) end
    end
    if v.rules.n == 0 then B.sub(items, tr("UI_ZeD_Cm_NoRules")) end
    B.label(items, tr("UI_ZeD_Cm_WrongHead"))
    items[#items + 1] = { k = "cmrule", text = P.wrongLine(v), c = { id = "cmwrong" } }
end

-- ---------------------------------------------------------------------------
-- NEW ITEMS: each works in a card and in the tab's list (TC.items)
-- ---------------------------------------------------------------------------
-- cmrule: words, with a number and a NEW tag when they have them. A stop with nothing to press: the controller steps down to read
TC.items.cmrule = {
    layout = function(win, it, w)
        local T, tm = ZeD.T, ZeD.TM
        local f2h = tm:getFontHeight(T.fontF2)
        local num = it.n and px(NUM_W) or 0
        if it.wrapW ~= w then
            it.wrapW = w
            it.lines = D.wrap(it.text, T.fontF2, math.max(1, w - num))
            it.tagRow = nil
            if it.new then
                local tag = tr("UI_ZeD_Cm_New")
                local lastW = tm:MeasureStringX(T.fontF2, it.lines[#it.lines] or "")
                if lastW + px(6) + F.tagW(tag) <= w - num then
                    it.tagRow, it.tagX = #it.lines, lastW + px(6)
                else
                    it.tagRow, it.tagX = #it.lines + 1, 0
                end
            end
        end
        return math.max(#it.lines, it.tagRow or 0) * f2h + px(5)
    end,
    draw = function(panel, win, t, it, x, dy, w, mx, my, ctx)
        local T = ZeD.T
        local f2h = ZeD.TM:getFontHeight(T.fontF2)
        local onF = D.mark(panel, x, dy, w, it.h, D.focusOf(win, ctx.prefix .. it.c.id))
        local tc = onF and T.textOnFocus or T.text
        local tx = x
        if it.n then
            local nc = onF and T.textOnFocus or T.textDim
            panel:drawText(tostring(it.n) .. ".", x, dy + px(2), nc.r, nc.g, nc.b, nc.a or 1, T.fontF2)
            tx = x + px(NUM_W)
        end
        for i, s in ipairs(it.lines or {}) do
            panel:drawText(s, tx, dy + px(2) + (i - 1) * f2h, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
        end
        if it.tagRow then
            F.drawTag(panel, tx + it.tagX, dy + px(2) + (it.tagRow - 1) * f2h, tr("UI_ZeD_Cm_New"), T.warning, onF)
        end
    end,
    stops = function(it, x0, dy, w, add) add(it.c, x0, dy, w, it.h, it.y).promptA = false end,
}

function P.postMeta(post)
    local day = D.shortDate(post.t)
    if not day then return tostring(post.by) end
    return tr("UI_ZeD_Cm_PostBy", tostring(post.by), day)
end

-- cmpost: a post, its PINNED tag, who and when; on the Admin card its Pin and Delete
TC.items.cmpost = {
    layout = function(win, it, w)
        local T, tm = ZeD.T, ZeD.TM
        local f2h, f3h = tm:getFontHeight(T.fontF2), tm:getFontHeight(T.fontF3)
        it.tagW = it.pin and (F.tagW(tr("UI_ZeD_Cm_Pinned")) + px(6)) or 0
        if it.wrapW ~= w then
            it.wrapW = w
            it.lines = D.wrap(it.text, T.fontF2, math.max(1, w - it.tagW))
        end
        local foot = f3h
        it.below = false
        if it.ctls then
            local bw = 0
            for _, c in ipairs(it.ctls) do
                c.w, c.h = ZeD.Molecules.buttonW(c.text), T.buttonH - px(4)
                bw = bw + c.w + px(6)
            end
            it.ctlW = bw - px(6)
            it.below = tm:MeasureStringX(T.fontF3, it.meta) + px(8) + it.ctlW > w
            foot = it.below and (f3h + px(4) + T.buttonH - px(4)) or math.max(f3h, T.buttonH - px(4))
            -- (here, not at draw: a post under the fold still needs its stops in the right place)
            local bx = w - it.ctlW
            local by = px(5) + #it.lines * f2h + px(3) + (it.below and (f3h + px(4)) or 0)
            for _, c in ipairs(it.ctls) do
                c.dx, c.dy = bx, by
                bx = bx + c.w + px(6)
            end
        end
        return px(5) + #it.lines * f2h + px(3) + foot + px(5)
    end,
    draw = function(panel, win, t, it, x, dy, w, mx, my, ctx)
        local T, tm = ZeD.T, ZeD.TM
        local f2h, f3h = tm:getFontHeight(T.fontF2), tm:getFontHeight(T.fontF3)
        local onF = (not it.ctls) and D.mark(panel, x, dy, w, it.h, D.focusOf(win, ctx.prefix .. it.c.id)) or false
        if it.pin then F.drawTag(panel, x, dy + px(5), tr("UI_ZeD_Cm_Pinned"), T.accent, onF) end
        local tc = onF and T.textOnFocus or T.text
        for i, s in ipairs(it.lines or {}) do
            panel:drawText(s, x + it.tagW, dy + px(5) + (i - 1) * f2h, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
        end
        local fy = dy + px(5) + #it.lines * f2h + px(3)
        local mc = onF and T.textOnFocus or T.textDim
        local room = it.ctls and not it.below and (w - it.ctlW - px(8)) or w
        panel:drawText(ZeD.Atoms.truncateText(it.meta, T.fontF3, room), x, fy, mc.r, mc.g, mc.b, mc.a or 1, T.fontF3)
        for _, c in ipairs(it.ctls or {}) do D.drawInline(panel, win, t, c, x + c.dx, dy + c.dy, mx, my) end
        ZeD.Atoms.drawDividerH(panel, x, dy + it.h - T.hair, w, false)
    end,
    stops = function(it, x0, dy, w, add)
        if not it.ctls then
            add(it.c, x0, dy, w, it.h, it.y).promptA = false
            return
        end
        for _, c in ipairs(it.ctls) do add(c, x0 + c.dx, dy + c.dy, c.w, c.h, it.y + c.dy) end
    end,
}

function P.upGlyph(p, x, y, s, c)
    local t = math.max(ZeD.T.px(6), math.floor(s * 0.6))
    ZeD.Atoms.drawTriangleUp(p, x + math.floor((s - t) / 2), y + math.floor((s - t) / 2), t, c)
end
function P.downGlyph(p, x, y, s, c)
    local t = math.max(ZeD.T.px(6), math.floor(s * 0.6))
    ZeD.Atoms.drawTriangleDown(p, x + math.floor((s - t) / 2), y + math.floor((s - t) / 2), t, c)
end
function P.crossGlyph(p, x, y, s, c)
    local t = math.max(ZeD.T.px(6), math.floor(s * 0.6))
    ZeD.Atoms.drawCrossGlyph(p, x + math.floor((s - t) / 2), y + math.floor((s - t) / 2), t, c)
end

-- a rule's height: its words, no spare line, and those words before its box exists, or a row would jump as it scrolled in
function P.fieldH(win, it, w, sh)
    local T = ZeD.T
    local lh = ZeD.TM:getFontHeight(T.fontF2)
    local text = D.fieldOf(win, it.key) and D.fieldText(win, it.key) or (it.seed or "")
    if text ~= it.seen or it.seenW ~= w then
        it.seen, it.seenW = text, w
        it.count = #D.wrap(text, T.fontF2, math.max(1, w - px(16)))
    end
    local h = math.max(it.rows, it.count) * lh + px(8)
    if sh then h = math.min(h, math.max(lh + px(8), sh - px(2))) end
    return h
end

-- cmrow: a rule typed in place, with its number and Up, Down, Remove beside it, or under it when they will not fit
TC.items.cmrow = {
    gap = 4,
    layout = function(win, it, w, sh)
        local T = ZeD.T
        local s = T.buttonH - px(2)
        local keys = 3 * s + 2 * px(4)
        local num = px(NUM_W)
        it.s, it.keysW = s, keys
        it.under = w - num - px(6) - keys < px(150)
        it.fw = it.under and (w - num) or (w - num - px(6) - keys)
        it.fh = P.fieldH(win, it, it.fw, sh)
        if it.under then return it.fh + px(4) + s end
        return math.max(it.fh, s)
    end,
    draw = function(panel, win, t, it, x, dy, w, mx, my, ctx)
        local T = ZeD.T
        local num = px(NUM_W)
        local nc = T.textDim
        panel:drawText(tostring(it.n), x, dy + px(4), nc.r, nc.g, nc.b, nc.a or 1, T.fontF3)
        it.c.fullId = ctx.prefix .. it.c.id
        D.drawField(panel, win, t, it, x + num, dy, it.fw, it.fh, ctx.viewY, ctx.viewH, ctx.covered)
        ctx.hits[#ctx.hits + 1] = { x = x + num, y = dy, w = it.fw, h = it.fh, c = it.c, field = it }
        local kx = x + w - it.keysW
        local ky = it.under and (dy + it.fh + px(4)) or dy
        for i, c in ipairs(it.keys) do
            if c.live then c.live(c) end
            local bx = kx + (i - 1) * (it.s + px(4))
            c.dx, c.dy = bx - x, ky - dy
            local hov = mx ~= nil and mx >= bx and mx < bx + it.s and my >= ky and my < ky + it.s
            ZeD.Molecules.drawIconButton(panel, bx, ky, it.s, c.glyph,
                { hover = hov, disabled = c.disabled, help = c.why or c.help, win = win, focus = D.focusOf(win, ctx.prefix .. c.id), iconSize = it.s - px(4) })
            ctx.hits[#ctx.hits + 1] = { x = bx, y = ky, w = it.s, h = it.s, c = c }
        end
    end,
    stops = function(it, x0, dy, w, add)
        local num = px(NUM_W)
        add(it.c, x0 + num, dy, it.fw, it.fh, it.y)
        local kx = x0 + w - it.keysW
        local ky = it.under and (it.fh + px(4)) or 0
        for i, c in ipairs(it.keys) do
            add(c, kx + (i - 1) * (it.s + px(4)), dy + ky, it.s, it.s, it.y + ky)
        end
    end,
}

-- ---------------------------------------------------------------------------
-- THE SERVER TAB'S PIECES
-- ---------------------------------------------------------------------------
-- the two blocks, rebuilt when the model changes; the list's stops are rebuilt with them
function P.tabParts(win, st)
    local key = tostring(M.seq) .. ":" .. tostring(M.live())
    if st.cmKey == key and st.cmTop then return st.cmTop, st.cmNews end
    st.cmKey = key
    local t = TC.qaState(st)
    t.listGen = t.listGen + 1
    local top, news = {}, {}
    local v = M.view
    if M.live() and v then
        if (v.motd or "") ~= "" then top[#top + 1] = { k = "tk", t = "cmrule", win = win, text = v.motd, c = { id = "cm:motd" } } end
        if v.rules.n > 0 then
            local parts = { tr((v.rules.n == 1) and "UI_ZeD_Cm_OneRule" or "UI_ZeD_Cm_NRules", v.rules.n) }
            if P.changed(v) then parts[2] = P.changed(v) end
            top[#top + 1] = { k = "tk", t = "arow", win = win, left = tr("UI_ZeD_Cm_Rules"), right = table.concat(parts, " | "), leftMin = 120, chev = true,
                c = { id = "cm:rules", help = tr("UI_ZeD_Cm_HelpRulesRow"), run = function(ww) CM.openRules(ww, st) end } }
        end
        if (v.news.n or 0) > 0 then
            news[1] = { k = "head", text = tr("UI_ZeD_Cm_News"), right = tostring(v.news.n) }
            for i = 1, v.news.n do
                local post = v.news[i]
                news[#news + 1] = { k = "tk", t = "cmpost", win = win, text = post.text, pin = post.pin, meta = P.postMeta(post), c = { id = "cm:post:" .. tostring(post.id) } }
            end
        end
    end
    st.cmTop, st.cmNews = top, news
    return top, news
end

function CM.serverItems(L, win, st)
    local top = P.tabParts(win, st)
    for _, it in ipairs(top) do L[#L + 1] = it end
end

function CM.newsItems(L, win, st)
    local _, news = P.tabParts(win, st)
    for _, it in ipairs(news) do L[#L + 1] = it end
end

function CM.openRules(win, st) F.push(win, st, { kind = "cmrules", from = "srv:tk:cm:rules" }) end

TC.kinds.cmrules = {
    data = function() return M.live() and M.view or nil end,
    key = function() return tostring(M.seq) end,
    title = function() return tr("UI_ZeD_Cm_Rules") end,
    help = function() return tr("UI_ZeD_Cm_HelpRules") end,
    gone = function() return tr("UI_ZeD_Cm_Gone") end,
    items = function(win, st, t, card, data)
        local items = {}
        P.body(items, data)
        return items
    end,
}

-- ---------------------------------------------------------------------------
-- THE ADMIN TAB'S ROW
-- ---------------------------------------------------------------------------
function P.mayOpen()
    if M.canRules() or M.canNews() then return nil end
    return A2.why(Cm.CAP_NEWS)
end

function AC.homeKey() return tostring(M.seq) .. ":" .. tostring(M.live()) end

function AC.homeExtra(L, win, st)
    if not M.live() then return end
    local v = M.view
    L[#L + 1] = { k = "head", text = tr("UI_ZeD_Cm_RulesNews") }
    local c = F.gate({ id = "sum:cmedit", help = tr("UI_ZeD_Cm_RulesNews"), run = function(ww) CM.openEdit(ww, st) end }, nil, P.mayOpen)
    L[#L + 1] = { k = "tk", t = "arow", win = win, left = tr("UI_ZeD_Cm_RulesNewsSum"), leftMin = 200, chev = true, c = c,
        right = v and P.counts(v) or nil }
end

function P.counts(v)
    local posts = v.news.n or 0
    return tr("UI_ZeD_Cm_Counts", tr((v.rules.n == 1) and "UI_ZeD_Cm_OneRule" or "UI_ZeD_Cm_NRules", v.rules.n),
        tr((posts == 1) and "UI_ZeD_Cm_OnePost" or "UI_ZeD_Cm_NPosts", posts))
end

-- ---------------------------------------------------------------------------
-- RULES AND NEWS: the rows, the words typed, the Save
-- ---------------------------------------------------------------------------
-- what a field holds: its box, or before the box exists what it was given
function P.val(win, key, seed)
    local box = D.fieldOf(win, key)
    if box then return box:getText() or "" end
    return seed or ""
end

function P.seed(win, key, text)
    local box = D.fieldOf(win, key)
    if box then
        D.setField(win, key, text or "")
        box._tkSeed = text or ""
    end
end

-- the card takes what the server holds
function P.load(win, card)
    local v = M.view
    if not v then return end
    local e = v.edit or {}
    card.ask, card.reask, card.base = e.ask == true, e.reask == true, e.base
    card.rows = {}
    local was = { motd = v.motd, appeal = v.appeal, ask = card.ask, reask = card.reask, n = v.rules.n }
    for i = 1, v.rules.n do
        local r = v.rules[i]
        card.rows[i] = { key = "cm:r" .. tostring(r.id), id = r.id, seed = r.text }
        was[i] = { id = r.id, text = r.text }
        P.seed(win, card.rows[i].key, r.text)
    end
    card.loaded = was
    P.seed(win, "cm:motd", v.motd)
    P.seed(win, "cm:appeal", v.appeal)
    card.stale = nil
    card.gen = (card.gen or 0) + 1
end

function CM.openEdit(win, st)
    D.setField(win, "cm:post", "")
    local card = { kind = "cmedit", from = "adm:tk:sum:cmedit", pin = false, gen = 0 }
    P.load(win, card)
    F.push(win, st, card)
    M.get()
end

function P.rowText(win, row) return Cm.line(P.val(win, row.key, row.seed), 100000) or "" end

function P.dirty(win, card)
    local v = M.view
    if not (v and card.rows) then return false end
    local e = v.edit or {}
    if (Tk.clean(P.val(win, "cm:motd", v.motd)) or "") ~= v.motd then return true end
    if P.rowText(win, { key = "cm:appeal", seed = v.appeal }) ~= v.appeal then return true end
    if card.ask ~= (e.ask == true) or card.reask ~= (e.reask == true) then return true end
    if #card.rows ~= v.rules.n then return true end
    for i, row in ipairs(card.rows) do
        local r = v.rules[i]
        if row.id ~= r.id or P.rowText(win, row) ~= r.text then return true end
    end
    return false
end

-- has anyone touched this card since it loaded? Not the same as dirty, which reads against the view: when another admin saves,
-- an untouched card differs from the new view and has to take it. (The message and the appeal line follow their seeds, so words
-- that match the new view are not typed either.)
function P.typed(win, card)
    local was, v = card.loaded, M.view
    if not (was and v) then return false end
    local motd = Tk.clean(P.val(win, "cm:motd", was.motd)) or ""
    if motd ~= was.motd and motd ~= v.motd then return true end
    local appeal = P.rowText(win, { key = "cm:appeal", seed = was.appeal })
    if appeal ~= was.appeal and appeal ~= v.appeal then return true end
    if card.ask ~= was.ask or card.reask ~= was.reask then return true end
    if #card.rows ~= was.n then return true end
    for i, row in ipairs(card.rows) do
        if row.id ~= was[i].id or P.rowText(win, row) ~= was[i].text then return true end
    end
    return false
end

-- why Save is gray, or nil
function P.saveWhy(win, t, card)
    if not M.canRules() then return A2.why(Cm.CAP_RULES) end
    if M.frozen() then return tr("UI_ZeD_Cm_Frozen") end
    if t.busy then return tr("UI_ZeD_Tk_Busy") end
    if not P.dirty(win, card) then return tr("UI_ZeD_Cm_NothingToSave") end
    for i, row in ipairs(card.rows) do
        local text = P.rowText(win, row)
        if text == "" then return tr("UI_ZeD_Cm_RuleEmpty", i) end
        if #text > CL.RULE_MAX then return tr("UI_ZeD_Cm_RuleLong", i, CL.RULE_MAX) end
    end
    if #(Tk.clean(P.val(win, "cm:motd", M.view.motd)) or "") > CL.MOTD_MAX then return tr("UI_ZeD_Cm_MotdLong", CL.MOTD_MAX) end
    if #P.rowText(win, { key = "cm:appeal", seed = M.view.appeal }) > CL.APPEAL_MAX then return tr("UI_ZeD_Cm_AppealLong", CL.APPEAL_MAX) end
    return nil
end

function P.save(win, st, t, card)
    local d = { motd = Tk.clean(P.val(win, "cm:motd", M.view.motd)) or "", appeal = P.rowText(win, { key = "cm:appeal", seed = M.view.appeal }),
        ask = card.ask and #card.rows > 0, reask = card.reask, base = card.base, rules = { n = #card.rows } }
    for i, row in ipairs(card.rows) do d.rules[i] = { id = row.id, text = P.rowText(win, row) } end
    F.act(win, st, function(cb)
        M.save(d, function(a)
            if a.err == "stale" then card.base, card.stale = a.base, a.by or "" end
            if a.ok then card.savedBase, card.base, card.stale = a.base, a.base, nil end
            cb(a)
        end)
    end, function(a)
        return tr(a.reasked and "UI_ZeD_Cm_SavedAsk" or "UI_ZeD_Cm_SavedDone")
    end)
end

function P.saveBtn(win, st, t, card)
    if not M.canRules() then return nil end
    local b = D.btn("rsave", tr("UI_ZeD_Cm_Save"), function(ww) P.save(ww, st, t, card) end, "primary", tr("UI_ZeD_Cm_HelpSave"))
    local why = P.saveWhy(win, t, card)
    if why then D.disable(b, why) end
    return b
end

-- moving a rule keeps its box: the box is its key's. Focus stays on the key that was pressed
function P.move(win, st, card, i, dir)
    local rows = card.rows
    local j = i + dir
    if not (rows[i] and rows[j]) then return end
    rows[i], rows[j] = rows[j], rows[i]
    card.gen = card.gen + 1
    D.focusId(win, st, "tk:" .. ((dir < 0) and "cmup:" or "cmdn:") .. rows[j].key)
end

function P.removeRow(win, st, card, i)
    table.remove(card.rows, i)
    card.gen = card.gen + 1
    local nextRow = card.rows[i] or card.rows[i - 1]
    D.focusId(win, st, nextRow and ("tk:cmrm:" .. nextRow.key) or "tk:cmadd")
end

-- (the key is the window's to count: a box lives as long as the window, and a key used twice brings back what was typed in it)
function P.addRow(win, st, t, card)
    win._cmRowKey = (win._cmRowKey or 0) + 1
    local row = { key = "cm:n" .. tostring(win._cmRowKey), seed = "" }
    card.rows[#card.rows + 1] = row
    card.gen = card.gen + 1
    if not D.padOn() then t.wantField = row.key end
    D.focusId(win, st, "tk:f:" .. row.key)
end

function P.ruleRow(win, st, t, card, i, row)
    local key = row.key
    local up = F.gate({ id = "cmup:" .. key, glyph = P.upGlyph, help = tr("UI_ZeD_Cm_HelpUp"), run = function(ww) P.move(ww, st, card, P.indexOf(card, key), -1) end }, nil,
        function() if P.indexOf(card, key) == 1 then return tr("UI_ZeD_Cm_AtTop") end return nil end)
    local down = F.gate({ id = "cmdn:" .. key, glyph = P.downGlyph, help = tr("UI_ZeD_Cm_HelpDown"), run = function(ww) P.move(ww, st, card, P.indexOf(card, key), 1) end }, nil,
        function() if P.indexOf(card, key) == #card.rows then return tr("UI_ZeD_Cm_AtBottom") end return nil end)
    local rm = { id = "cmrm:" .. key, glyph = P.crossGlyph, help = tr("UI_ZeD_Cm_HelpRemove"), run = function(ww) P.removeRow(ww, st, card, P.indexOf(card, key)) end }
    return { k = "cmrow", isField = true, n = i, key = key, rows = 1, hint = tr("UI_ZeD_Cm_RuleHint"), max = CL.RULE_MAX, seed = row.seed, keys = { up, down, rm }, c = { id = "f:" .. key, help = tr("UI_ZeD_Cm_HelpRule"),
        land = i == 1, run = function(ww) D.useField(ww, key) end } }
end

function P.indexOf(card, key)
    for i, row in ipairs(card.rows) do
        if row.key == key then return i end
    end
    return 0
end

function P.rulesPart(items, win, st, t, card, v)
    B.label(items, tr("UI_ZeD_Cm_Motd"), tr("UI_ZeD_Cm_MotdWhere"))
    B.field(items, "cm:motd", 2, tr("UI_ZeD_Cm_MotdHint"), #card.rows == 0, CL.MOTD_MAX)
    items[#items].seed = v.motd
    B.label(items, tr("UI_ZeD_Cm_Rules"), tostring(#card.rows))
    for i, row in ipairs(card.rows) do items[#items + 1] = P.ruleRow(win, st, t, card, i, row) end
    items[#items + 1] = { k = "btn", c = F.gate({ id = "cmadd", text = tr("UI_ZeD_Cm_AddRule"), help = tr("UI_ZeD_Cm_HelpAddRule"),
        run = function(ww) P.addRow(ww, st, t, card) end }, nil, function()
            if #card.rows >= CL.RULES_MAX then return tr("UI_ZeD_Cm_RulesFull", CL.RULES_MAX) end
            return nil
        end) }
    B.label(items, tr("UI_ZeD_Cm_Appeal"), tr("UI_ZeD_Cm_AppealWhere"))
    items[#items + 1] = { k = "field", key = "cm:appeal", rows = 1, one = true, hint = tr("UI_ZeD_Cm_AppealHint"), max = CL.APPEAL_MAX, seed = v.appeal,
        c = { id = "f:cm:appeal", help = tr("UI_ZeD_Cm_HelpAppeal"), run = function(ww) D.useField(ww, "cm:appeal") end } }
    B.label(items, tr("UI_ZeD_Cm_Joining"))
    items[#items + 1] = { k = "atick", win = win, text = tr("UI_ZeD_Cm_AskAll"), sub = tr("UI_ZeD_Cm_AskAllSub"), c = F.gate({ id = "cmask", style = "tick", help = tr("UI_ZeD_Cm_AskAllSub"),
        run = function() card.ask = not card.ask end }, nil, function(cc)
            cc.on = card.ask and #card.rows > 0
            if #card.rows == 0 then return tr("UI_ZeD_Cm_AskNeedsRule") end
            return nil
        end) }
    items[#items + 1] = { k = "atick", win = win, text = tr("UI_ZeD_Cm_AskAgain"), sub = tr("UI_ZeD_Cm_AskAgainSub"), c = F.gate({ id = "cmreask", style = "tick", help = tr("UI_ZeD_Cm_AskAgainSub"),
        run = function() card.reask = not card.reask end }, nil, function(cc)
            cc.on = card.reask
            if not card.ask or #card.rows == 0 then return tr("UI_ZeD_Cm_AskFirst") end
            return nil
        end) }
end

function P.postCtls(win, st, t, post)
    local id = post.id
    local pin = F.gate({ id = "cmpin:" .. id, text = tr(post.pin and "UI_ZeD_Cm_Unpin" or "UI_ZeD_Cm_Pin"), help = tr("UI_ZeD_Cm_HelpPin"),
        run = function(ww) F.act(ww, st, function(cb) M.pin(id, not post.pin, cb) end, tr(post.pin and "UI_ZeD_Cm_Unpinned" or "UI_ZeD_Cm_PinnedDone")) end }, Cm.CAP_NEWS, P.newsWhy)
    local del = F.gate({ id = "cmdel:" .. id, text = tr("UI_ZeD_Tk_Delete"), variant = "danger", help = tr("UI_ZeD_Cm_HelpDelete"),
        run = function(ww)
            if Cm.DELETE_ASKS then
                t.confirm = { post = post }
                D.focusId(ww, st, "tk:cmno")
            else
                P.delete(ww, st, id)
            end
        end }, Cm.CAP_NEWS, P.newsWhy)
    return { pin, del }
end

function P.newsWhy()
    if M.frozen() then return tr("UI_ZeD_Cm_Frozen") end
    return nil
end

function P.delete(win, st, id)
    F.act(win, st, function(cb) M.del(id, cb) end, tr("UI_ZeD_Cm_Deleted"))
end

-- where the pad goes when a post goes: the next post's Delete, the one before, or the box to write one
function P.afterPost(id)
    local news = M.view and M.view.news or {}
    for i = 1, news.n or 0 do
        if news[i].id == id then
            local other = news[i + 1] or news[i - 1]
            if other then return "tk:cmdel:" .. tostring(other.id) end
        end
    end
    return "tk:f:cm:post"
end

function P.newsPart(items, win, st, t, card, v)
    B.label(items, tr("UI_ZeD_Cm_News"), tr("UI_ZeD_Cm_NewsWhere"))
    if M.canNews() then
        B.field(items, "cm:post", 2, tr("UI_ZeD_Cm_PostHint"), not M.canRules(), CL.POST_MAX)
        F.flow(items, {
            F.gate({ id = "cmpinnew", style = "tick", text = tr("UI_ZeD_Cm_PinIt"), help = tr("UI_ZeD_Cm_HelpPinIt"), on = card.pin, run = function() card.pin = not card.pin end }, nil,
                function(cc) cc.on = card.pin; return nil end),
            F.gate({ id = "cmpost", text = tr("UI_ZeD_Cm_Post"), primary = true, push = true, help = tr("UI_ZeD_Cm_HelpPost"),
                run = function(ww)
                    F.act(ww, st, function(cb) M.post(F.text(ww, "cm:post"), card.pin, cb) end, tr("UI_ZeD_Cm_Posted"), function()
                        D.setField(ww, "cm:post", "")
                        card.pin = false          -- (a pin is chosen for one post: pinned posts are never pushed off)
                    end)
                end }, nil, function()
                    if M.frozen() then return tr("UI_ZeD_Cm_Frozen") end
                    if F.text(win, "cm:post") == "" then return tr("UI_ZeD_Cm_WritePost") end
                    return nil
                end),
        })
    else
        B.sub(items, A2.why(Cm.CAP_NEWS))
    end
    for i = 1, v.news.n or 0 do
        local post = v.news[i]
        items[#items + 1] = { k = "cmpost", text = post.text, pin = post.pin, meta = P.postMeta(post), c = { id = "cmp:" .. tostring(post.id) },
            ctls = M.canNews() and P.postCtls(win, st, t, post) or nil }
    end
end

function P.editItems(win, st, t, card, v)
    local items = {}
    if M.canRules() then
        P.rulesPart(items, win, st, t, card, v)
    else
        B.sub(items, A2.why(Cm.CAP_RULES))
        P.body(items, v)
    end
    P.newsPart(items, win, st, t, card, v)
    return items
end

TC.kinds.cmedit = {
    data = function() return M.live() and M.view or nil end,
    tick = function(win, st, t, card)
        local e = M.view and M.view.edit
        if not e then return end
        if card.savedBase then
            if e.base >= card.savedBase then
                card.savedBase = nil
                P.load(win, card)
            end
        elseif e.base ~= card.base and not P.typed(win, card) then
            P.load(win, card)
        end
    end,
    key = function(t, card) return tostring(M.seq) .. ":" .. tostring(card.gen) .. ":" .. tostring(#card.rows) end,
    title = function() return tr("UI_ZeD_Cm_RulesNews") end,
    gone = function() return tr("UI_ZeD_Cm_Gone") end,
    help = function(t)
        if t.confirm then return tr("UI_ZeD_Cm_HelpDeleteAsk") end
        return tr("UI_ZeD_Cm_HelpEdit")
    end,
    items = function(win, st, t, card, data) return P.editItems(win, st, t, card, data) end,
    foot = function(win, st, t, card)
        if t.confirm then
            local post = t.confirm.post
            return { question = tr("UI_ZeD_Cm_DeleteAsk"), main = {
                D.btn("cmno", tr("UI_ZeD_Tk_KeepIt"), function(ww) CM.keepPost(ww, st, t) end, nil, tr("UI_ZeD_Cm_HelpKeep")),
                D.btn("cmyes", tr("UI_ZeD_Tk_DeleteGood"), function(ww)
                    t.confirm = nil
                    D.focusId(ww, st, P.afterPost(post.id))
                    P.delete(ww, st, post.id)
                end, "danger", tr("UI_ZeD_Cm_HelpDelete")) } }
        end
        local b = P.saveBtn(win, st, t, card)
        if not b then return { main = {} } end
        local status = tr(P.dirty(win, card) and "UI_ZeD_Cm_NotSaved" or "UI_ZeD_Cm_Saved")
        if card.stale then status = tr("UI_ZeD_Cm_StaleBy", tostring(card.stale)) end
        return { status = status, main = { b } }
    end,
    padX = function(win, st, t, card)
        if t.confirm then return nil end
        return P.saveBtn(win, st, t, card)
    end,
    cancel = function(win, st, t)
        if not t.confirm then return false end
        CM.keepPost(win, st, t)
        return true
    end,
}

function CM.keepPost(win, st, t)
    local post = t.confirm and t.confirm.post
    t.confirm = nil
    if post then D.focusId(win, st, "tk:cmdel:" .. tostring(post.id)) end
end

-- ---------------------------------------------------------------------------
-- JOINING: the card
-- ---------------------------------------------------------------------------
function P.newWords(view)
    local list = Cm.newRules(view)
    if #list == 0 then return nil end
    if #list == 1 then return tr("UI_ZeD_Cm_NewOne", list[1]) end
    return tr("UI_ZeD_Cm_NewMany", #list)
end

TC.kinds.cmjoin = {
    noBack = true,
    -- (what was on screen when it opened: agreeing means agreeing to these words, whatever a push has brought since)
    data = function(card) return card.view end,
    key = function() return "join" end,
    title = function() return F.serverName() end,
    help = function() return tr("UI_ZeD_Cm_HelpJoin") end,
    items = function(win, st, t, card, data)
        local marks = {}
        for _, n in ipairs(Cm.newRules(data)) do marks[n] = true end
        local items = {}
        P.body(items, data, marks)
        return items
    end,
    foot = function(win, st, t, card, data)
        local foot = { main = {
            D.btn("leave", tr("UI_ZeD_Adm_Leave"), function(ww) P.joinLeave(ww) end, nil, tr("UI_ZeD_Cm_HelpLeave")),
            D.btn("agree", tr("UI_ZeD_Cm_Agree"), function(ww) P.joinAgree(ww, card) end, "primary", tr("UI_ZeD_Cm_HelpAgree")) } }
        local words = P.newWords(data)
        if words then
            -- (the band's left when it fits; a long list of numbers goes on the line over it)
            local room = (t.cin or px(300)) - ZeD.Molecules.buttonW(foot.main[1].label) - ZeD.Molecules.buttonW(foot.main[2].label) - px(40)
            if ZeD.TM:MeasureStringX(ZeD.T.fontF2, words) <= room then foot.status = words else foot.line = words end
        end
        return foot
    end,
}

function P.joinAgree(win, card)
    M.agree(card.view and card.view.rev or nil)
    if win.finish then win:finish() end
end

function P.joinLeave(win)
    if win.finish then win:finish() end
    M.leave()
end

-- ---------------------------------------------------------------------------
-- JOINING: the window and its cover. (Built at first use: the ticket cards' sims load this file with no window class.)
-- ---------------------------------------------------------------------------
function P.classes()
    if ZeD_JoinWindow then return end

    -- safe mode: the join screen goes, and is not put up
    ZeD.Safe.register("community", {
        leave = function()
            if CM.joinWin then CM.joinWin:finish() end
        end,
    })

    -- the cover: nothing behind it can be pressed. Keys go nowhere while it stands (doKeyPress), and the pad's focus is the window's
    ZeD_JoinCover = ISPanel:derive("ZeD_JoinCover")
    function ZeD_JoinCover:prerender()
        local core = getCore()
        if self.width ~= core:getScreenWidth() then self:setWidth(core:getScreenWidth()) end
        if self.height ~= core:getScreenHeight() then self:setHeight(core:getScreenHeight()) end
    end
    function ZeD_JoinCover:render()
        local bg = ZeD.T.base
        self:drawRect(0, 0, self.width, self.height, 0.94, bg.r, bg.g, bg.b)
    end
    function ZeD_JoinCover:onMouseDown() return true end
    function ZeD_JoinCover:onMouseUp() return true end
    function ZeD_JoinCover:onRightMouseDown() return true end
    function ZeD_JoinCover:onRightMouseUp() return true end

    ZeD_JoinWindow = ZeD_Window:derive("ZeD_JoinWindow")

    function ZeD_JoinWindow:new(view)
        local o = ZeD_Window.new(self, 0, 0, px(JOIN_W), px(JOIN_H), "")
        o.resizable = false
        o.pin = true
        o.noWindowBox = true
        o.moveWithMouse = false
        o.playerNum = 0
        o.pick = "agree"
        o.joinSt = { card = { kind = "cmjoin", view = view } }
        return o
    end

    -- (no close box: closing here would mean something, and Leave and I agree say what)
    function ZeD_JoinWindow:createChildren()
        ZeD_Window.createChildren(self)
        self._closeBtnRect = nil
        self.minimumWidth, self.minimumHeight = 0, 0
    end

    function ZeD_JoinWindow:place()
        local core = getCore()
        local sw, sh = core:getScreenWidth(), core:getScreenHeight()
        local w = math.min(px(JOIN_W), sw - px(16))
        local h = math.min(px(JOIN_H), sh - px(16))
        if self.width ~= w then self:setWidth(w) end
        if self.height ~= h then self:setHeight(h) end
        local x, y = math.floor((sw - w) / 2), math.floor((sh - h) / 2)
        if self:getX() ~= x then self:setX(x) end
        if self:getY() ~= y then self:setY(y) end
    end

    function ZeD_JoinWindow:_body()
        local top = self:titleBarHeight()
        TC.renderCard(self, self, self.joinSt, 0, top, self.width, self.height - self:footerHeight() - top)
        self:clearStencilRect()
    end

    function ZeD_JoinWindow:prerender()
        if self.done or not ZeD.T then return end
        self:place()
        self.title = F.serverName()
        ZeD_Window.prerender(self)
        -- (a card that cannot draw must never stand between a player and the game)
        if not ZeD.Safe.guard(self, self._body, "join screen") then self:finish() end
    end

    function ZeD_JoinWindow:update()
        ZeD_Window.update(self)
        if self.done then return end
        -- the pad is this window's, however it got away and whenever it arrived: a death's panel takes it, and a pad can come after
        -- this opened. Whoever held it gets it back at the end (finish). Not from the game's pause menu, which gives it back itself
        local jd = JoypadState and JoypadState.players and JoypadState.players[1]
        if jd and jd.focus ~= self and not jd.inMainMenu then
            if jd.focus then self.padTaken = jd.focus end
            setJoypadFocus(0, self)
        end
        self.joyfocus = (jd and jd.focus == self) and jd or nil
        self._padId = self.joyfocus and ("tk:" .. self.pick) or nil
    end

    function ZeD_JoinWindow:press(id)
        local t = TC.qaState(self.joinSt)
        for _, r in ipairs(t.footRects or {}) do
            if r.b.id == id and r.b.run then
                pcall(function() getSoundManager():playUISound("UIActivateButton") end)
                r.b.run(self)
                return
            end
        end
    end

    function ZeD_JoinWindow:onMouseDown(x, y)
        TC.cardClick(self, self.joinSt, x, y)
        return true
    end
    function ZeD_JoinWindow:onMouseMove(dx, dy)
        local sc = TC.qaState(self.joinSt).scroll
        if sc.dragging then sc:handleMouseMove(self:getMouseY() - sc.y) end
        return true
    end
    function ZeD_JoinWindow:onMouseUp() TC.qaState(self.joinSt).scroll:handleMouseUp(); return true end
    function ZeD_JoinWindow:onMouseUpOutside() TC.qaState(self.joinSt).scroll:handleMouseUp(); return true end
    function ZeD_JoinWindow:onMouseWheel(del)
        local sc = TC.qaState(self.joinSt).scroll
        if sc.visible then sc:handleMouseWheel(del) end
        return true
    end

    function ZeD_JoinWindow:padScroll(dir)
        local t = TC.qaState(self.joinSt)
        local sc = t.scroll
        local range = (t.listH or 0) - (t.csh or 0)
        if not sc.visible or range <= 0 then return end
        local step = PAD_SCROLL_LINES * ZeD.TM:getFontHeight(ZeD.T.fontF2) / range
        sc:setScrollPos(math.max(0, math.min(1, sc.scrollPos + dir * step)))
    end

    function ZeD_JoinWindow:onGainJoypadFocus(jd) self.joyfocus = jd end
    function ZeD_JoinWindow:onLoseJoypadFocus(jd) self.joyfocus = nil end
    -- (B answers nothing: neither word is one to press by accident)
    function ZeD_JoinWindow:onJoypadDown(button, jd)
        if button == Joypad.AButton then self:press(self.pick) end
    end
    function ZeD_JoinWindow:onJoypadDirUp() self:padScroll(-1) end
    function ZeD_JoinWindow:onJoypadDirDown() self:padScroll(1) end
    function ZeD_JoinWindow:onJoypadDirLeft() self.pick = "leave" end
    function ZeD_JoinWindow:onJoypadDirRight() self.pick = "agree" end

    function ZeD_JoinWindow:getFooterPrompts()
        if not self.joyfocus then return nil end
        local Pr = ZeD.Prompt
        local words = tr("UI_ZeD_Prompt_DPadScroll")
        return { (Pr and Pr.padNote) and Pr.padNote(words) or words, { glyph = "A", label = tr("UI_ZeD_Prompt_Press") } }
    end

    function ZeD_JoinWindow:finish()
        if self.done then return end
        self.done = true
        CM.joinWin = nil
        pcall(doKeyPress, true)
        local jd = JoypadState and JoypadState.players and JoypadState.players[1]
        local taken = self.padTaken
        if taken and not (taken.isVisible and taken:isVisible()) then taken = nil end
        if jd and jd.focus == self then setJoypadFocus(0, taken) end
        self:setVisible(false)
        self:removeFromUIManager()
        if self.cover then
            self.cover:setVisible(false)
            self.cover:removeFromUIManager()
        end
        -- (the window the pad was in when this opened)
        local back = self.padBack
        if back and not taken and back:isVisible() and not back.windowShaded then ZeD.Input.Focus.claimFocus(back) end
    end
end

function M.joinScreen()
    if CM.joinWin or not M.view or A2.leave then return end
    if ZeD.Safe and ZeD.Safe.on("community") then return end
    P.classes()
    -- the window first. If it cannot be built there is nothing up to cover the game, and past this point it can always be answered
    local win = ZeD_JoinWindow:new(M.view)
    win:initialise()
    win:instantiate()
    win:addToUIManager()
    win:setAlwaysOnTop(true)
    CM.joinWin = win
    local core = getCore()
    local cover = ZeD_JoinCover:new(0, 0, core:getScreenWidth(), core:getScreenHeight())
    win.cover = cover
    cover:initialise()
    cover:addToUIManager()
    cover:setAlwaysOnTop(true)
    win:bringToTop()
    pcall(doKeyPress, false)
    local Fo = ZeD.Input and ZeD.Input.Focus
    if Fo and Fo.getFocusedWindow then
        win.padBack = Fo.getFocusedWindow()
        if win.padBack then Fo.releaseFocus() end
    end
    local jd = JoypadState and JoypadState.players and JoypadState.players[1]
    if jd then setJoypadFocus(0, win) end
end

-- ---------------------------------------------------------------------------
-- LEAVING: the ban screen's appeal line, and the game's own kick screen
-- ---------------------------------------------------------------------------
A2.leaveScreen = function(info)
    -- (a banned player has nothing left to agree to)
    if CM.joinWin then CM.joinWin:finish() end
    info.appeal = info.appeal or M.appeal()
    A2.defaultLeave(info)
end

-- the line under the words the game draws in the middle of its disconnect screen. Text: there is nothing here to press
function P.showNote(appeal)
    local core = getCore()
    local T = ZeD.T
    local text = tr("UI_ZeD_Adm_SeeAppeal", appeal)
    local w = math.min(px(JOIN_W), core:getScreenWidth() - px(40))
    local lines = D.wrap(text, T.fontF2, w)
    local fh = ZeD.TM:getFontHeight(T.fontF2)
    local note = ISPanel:new(math.floor((core:getScreenWidth() - w) / 2), math.floor(core:getScreenHeight() / 2) + px(40), w, #lines * fh + px(4))
    note.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    note.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    note.render = function(self)
        local c = ZeD.T.text
        for i, s in ipairs(lines) do
            local tw = ZeD.TM:MeasureStringX(ZeD.T.fontF2, s)
            self:drawText(s, math.floor((self.width - tw) / 2), (i - 1) * fh, c.r, c.g, c.b, c.a or 1, ZeD.T.fontF2)
        end
    end
    note:initialise()
    note:addToUIManager()
    note:setAlwaysOnTop(true)
end

-- the connection has ended, for whatever reason: nothing of ours may stand over the game's screen, its Exit and Quit
function CM.onDisconnect(reason)
    if CM.joinWin then CM.joinWin:finish() end
    local gone = A2.leave
    A2.leave, A2.leaveAt = nil, nil        -- (the ban screen closes itself when this goes)
    if not (gone or M.isRemoved(reason)) then return end
    local appeal = (gone and gone.appeal) or M.appeal()
    if appeal and ZeD.T then P.showNote(appeal) end
end

if not CM.offHooked and ISServerDisconnectUI_OnServerDisconnectUI then
    CM.offHooked = true
    local base = ISServerDisconnectUI_OnServerDisconnectUI
    ISServerDisconnectUI_OnServerDisconnectUI = function(reason)
        base(reason)
        local ok, err = pcall(CM.onDisconnect, reason)
        if not ok then ZeD.logOnce("community: the disconnect screen", err) end
    end
end

-- ---------------------------------------------------------------------------
-- QA
-- ---------------------------------------------------------------------------
function CM.qaOpen(win, st, kind)
    if kind == "rules" then CM.openRules(win, st) else CM.openEdit(win, st) end
end
-- the join card on a tab's panel, for the sims and the pictures: the window is the same card
function CM.qaJoinCard(st)
    st.card = { kind = "cmjoin", view = M.view }
    TC.qaState(st).items = nil
end
function CM.qaType(win, key, text) D.setField(win, key, text) end
function CM.qaAdd(win, st, t, card) P.addRow(win, st, t, card) end
function CM.qaConfirm(st, post) TC.qaState(st).confirm = { post = post } end

return CM
