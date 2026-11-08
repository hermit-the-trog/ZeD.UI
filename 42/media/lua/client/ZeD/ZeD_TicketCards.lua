-- ZeD-UI/42/media/lua/client/ZeD/ZeD_TicketCards.lua
-- ============================================================================
-- THE TICKET CARDS. Client; drawing and input only: ZeD_Tickets.lua is the model, and this file reads it and calls it.
-- It is also the card engine (organism-level) the other multiplayer cards are built on.
--
-- Two tabs use these parts. Each tab keeps its one list; a card is a second render path behind st.card, the tab
-- underneath and the card pushed on top with a back bar:
--   Server tab   the Tickets block (N open, Ask the admins, my tickets); the Ask the admins card; my ticket's card
--   Admin tab    the Tickets queue (filters, Find, rows, the pages); the ticket card
-- A tab asks for items (TC.playerItems, TC.queueItems), measures and draws them with TC.itemH and TC.drawItem, and hands
-- on clicks and stops (TC.listClick, TC.itemStops). A card does all of that here (TC.renderCard, TC.cardClick,
-- TC.cardStops).
--
-- Without the server part the same cards read the game's list: one question and one answer, the help line saying
-- what is left out. Simple mode draws these same cards: they are already plain.
--
-- The admin tools (ZeD_AdminCards.lua) and the safehouse and faction cards (ZeD_ClaimCards.lua) push their cards on this
-- same engine: TC.kinds holds a card kind's parts (data, items, foot, title, help, key, tick, back, gone, cancel, flag,
-- padX, noBack) and TC.items a new item's (gap, layout, draw, stops), in a card or a tab's list alike. The join screen
-- (ZeD_CommunityCards.lua) draws one such card in a window of its own, with its own pad: win._padId names the stop it holds.
-- Before touching a helper: D and B go out as TC._D and TC._B, and the admin, claim, community, extras, log, mail and
-- stats cards, the Server tab, chat and the main menu's mail and documents all use them.
--
-- All player text is drawn with drawText, never through the game's rich text, which would act on <LINE> or <IMAGE:...>.
-- Kind and status always carry their word, never color alone.
--
-- QA, read at draw time (the Identity tab's style):
--   TC.qaRole    "admin" / "moderator": what the cards draw for, whatever the role
--   TC.qaGo      true / false: the teleport power, for Go there
--   TC.qaStats   true / false: Player card can open (the power, and the player online)
--   TC.qaLink    "wait" / "off" / "frozen": the link as Send and the queue read it
--   TC.qaHold    true: no traffic. The screen shows only what the QA script put in the model
--   TC.qaOpen(win, st, "ask" | "mine" | "staff", id, game), TC.qaConfirm(st), TC.qaFlash(st, text), TC.qaAsk(st, kind, here)
-- ZeDUI/tools/qa/mp_ticket_cards.lua walks every state with these, with sample tickets put in the model.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/Tr"
require "ZeD/ZeD_TicketProto"
require "ZeD/ZeD_ServerLink"
require "ZeD/ZeD_Tickets"

ZeD = ZeD or {}
ZeD.TicketCards = ZeD.TicketCards or {}
local TC = ZeD.TicketCards
local C = ZeD.Tickets
local S = ZeD.ServerPart
local Tk = ZeD.Tk
local L = Tk.LIMITS

-- The game's OsLib reads real time in UTC, as far as its bytecode says, so a real date carries the word UTC.
-- TODO: settle it in play (os.date("%H:%M", getTimestamp()) printed beside the clock); the word stays until then.
local DATE_SAYS_UTC = true
TC.DATE_SAYS_UTC = DATE_SAYS_UTC

local PAD, ROW_PAD, CARD_PAD = 10, 7, 12   -- design units
local CHIP_GAP, FIELD_PAD = 6, 4
local FACT_GAP, FLAG_H = 10, 26
local DIM_A = 0.55                         -- a row that is no longer open, as drawn
local FLASH_MS = 6000                      -- a card's answer stays in the help line this long
local FIND_MS = 400                        -- Find waits this long after the last key
local QUEUE_IDLE_MS = 1500                 -- no frame of the queue for this long: it is closed
local LIVE_MS = 3000                       -- at most one fresh page in this long while rows change
local LOAD_MS = 10000                      -- a card that gets no data in this long goes back with the error
local FALLBACK_MINE_MS = 15000             -- without the server part, my list is read this often
local FIELD_LINES = 60                     -- past the rows drawn, a field grows; nothing scrolls inside it

local KIND_WORD = {
    BUG = "UI_ZeD_Tk_KindBug", GRIEF = "UI_ZeD_Tk_KindGrief", STUCK = "UI_ZeD_Tk_KindStuck",
    QUESTION = "UI_ZeD_Tk_KindQuestion", APPEAL = "UI_ZeD_Tk_KindAppeal", OTHER = "UI_ZeD_Tk_KindOther",
    NONE = "UI_ZeD_Tk_KindNone",
}
local KIND_HELP = {
    BUG = "UI_ZeD_Tk_HelpBug", GRIEF = "UI_ZeD_Tk_HelpGrief", STUCK = "UI_ZeD_Tk_HelpStuck",
    QUESTION = "UI_ZeD_Tk_HelpQuestion", APPEAL = "UI_ZeD_Tk_HelpAppeal", OTHER = "UI_ZeD_Tk_HelpOther",
}
local ST_WORD = {
    Sent = "UI_ZeD_Tk_StSent", Seen = "UI_ZeD_Tk_StSeen", Open = "UI_ZeD_Tk_StOpen", Progress = "UI_ZeD_Tk_StProgress",
    Answered = "UI_ZeD_Tk_StAnswered", Closed = "UI_ZeD_Tk_StClosed", Spam = "UI_ZeD_Tk_StSpam",
}
-- the mark's shape and token: the ZeD fonts have no round glyphs, and a status is a square mark
local ST_MARK = {
    Sent = { "hollow", "textDim" }, Seen = { "dot", "info" }, Open = { "dot", "accent" }, Progress = { "half", "warning" },
    Answered = { "dot", "positive" }, Closed = { "hollow", "textDim" }, Spam = { "dot", "danger" },
}
local MONTHS = {
    "UI_ZeD_Journal_MonthJan", "UI_ZeD_Journal_MonthFeb", "UI_ZeD_Journal_MonthMar", "UI_ZeD_Journal_MonthApr",
    "UI_ZeD_Journal_MonthMay", "UI_ZeD_Journal_MonthJun", "UI_ZeD_Journal_MonthJul", "UI_ZeD_Journal_MonthAug",
    "UI_ZeD_Journal_MonthSep", "UI_ZeD_Journal_MonthOct", "UI_ZeD_Journal_MonthNov", "UI_ZeD_Journal_MonthDec",
}

local D = {}     -- the file's helpers (a table: Kahlua counts every local in the chunk against its limit)
local B = {}     -- what each card holds
-- both go out to the other card files, which build their cards from these same parts
TC._D, TC._B = D, B
D.MONTHS = MONTHS
-- Cards and items other files build on this frame (ZeD_AdminCards.lua, ZeD_ClaimCards.lua).
-- TC.kinds: kind -> { data(card), items(win, st, t, card, data), foot(win, st, t, card, data), title(card, data),
--   help(t, card, data), key(t, card), tick(win, st, t, card), back(win, st, t, card), gone(card),
--   flag(panel, win, t, card, data, x, y, w, bar), padX(win, st, t, card),
--   cancel(win, st, t, card): true when it answered B, or the frame's own answer runs,
--   noBack: true leaves out the back bar (a card with nowhere to go back to) }
-- TC.items: k -> { gap: design units above it, layout(win, it, w, sh), draw(panel, win, t, it, x, dy, w, mx, my, ctx),
--   stops(it, x0, dy, w, add) }, in a card or a tab's list alike. ctx: hits, prefix, viewY, viewH, covered.
--   stops may be left out: nothing to press. add returns the stop.
TC.kinds = TC.kinds or {}
TC.items = TC.items or {}

local function tr(k, ...) return ZeD.tr(k, ...) end
local function px(n) return ZeD.T.px(n) end
local function now() return getTimestampMs() end
local function inside(r, x, y) return r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end
local function sound(n) pcall(function() getSoundManager():playUISound(n or "UIActivateButton") end) end

-- ---------------------------------------------------------------------------
-- STATE: one table per tab, st.tk
-- ---------------------------------------------------------------------------
local function ts(st)
    local t = st.tk
    if not t then
        t = { scroll = ZeD_ScrollbarState:new(), hits = {}, listHits = {}, listGen = 0, prefix = "",
              q = { status = "Open", newest = true, page = 1, find = "" }, ask = { here = false } }
        st.tk = t
    end
    return t
end

--- A tab names its stops' prefix and its focus zone, every frame. Returns the tab's card state.
function TC.bind(win, st, prefix, zone)
    local t = ts(st)
    t.prefix = prefix
    st.tkZone, st.tkWin = zone, win
    win._tkSt = st
    return t
end

--- A press's answer: the card's line (or the help line) shows text for FLASH_MS.
function D.flash(t, text) t.flashText, t.flashAt = text, now() end
-- a press on a gray control: why it is gray, as the answer in the card's line (hover alone says it otherwise, and a
-- press would read as doing nothing: Mute on an offline player's card, say)
function D.grayPress(t, c)
    if c and c.why then
        D.flash(t, c.why)
        -- (a card that has its own line for answers takes it there too: the help band is where hover said it already)
        if c.onGray then c.onGray(c.why) end
    end
end
function D.flashNow(t)
    if t.flashText and now() - t.flashAt < FLASH_MS then return t.flashText end
    t.flashText = nil
    return nil
end

--- The link as the cards read it: "wait", "on" or "off", and frozen (reads work, writes are refused).
function D.link()
    local q = TC.qaLink
    if q == "off" or q == "wait" then return q, false end
    if q == "frozen" then return "on", true end
    if S.forceOff then return "off", false end
    if S.present == nil then return "wait", false end
    if S.present == false then return "off", false end
    return "on", S.frozen == true
end

function D.me()
    local p = getPlayer()
    return p and p:getUsername() or ""
end

function D.cap(name)
    local p = getPlayer()
    local c = Capability and Capability[name]
    if not (p and c) then return false end
    local ok, r = pcall(function() return p:getRole():hasCapability(c) end)
    return ok and r == true
end

function D.isAdmin()
    if TC.qaRole then return TC.qaRole == "admin" end
    if D.link() == "on" then return S.admin == true end
    return D.cap("AnswerTickets")      -- (without the server part Delete is the game's Remove)
end

--- True while the controller is in use (its cues show).
function D.padOn()
    local Fo = ZeD.Input and ZeD.Input.Focus
    return (Fo and Fo.cuesVisible and Fo.cuesVisible()) and true or false
end

local _fo = {}
--- The focus mark's options when the controller is on stop id in win, else nil. solid: the element is already solid
--- accent. The table is reused: use it before the next call.
function D.focusOf(win, id, solid)
    -- (a window with its own pad: the mark's own test passes, as ZeD_Prompt's does)
    if win._padId then
        if win._padId ~= id then return nil end
        _fo.win, _fo.solid, _fo.focused, _fo.pad = win, solid, true, true
        return _fo
    end
    local Fo = ZeD.Input and ZeD.Input.Focus
    if Fo and Fo.isFocused and Fo.isFocused(win, nil, id) then
        _fo.win, _fo.solid, _fo.focused, _fo.pad = win, solid, nil, nil
        return _fo
    end
    return nil
end

--- Draw the focus mark when f (from D.focusOf) is set. True when the words drawn over it take textOnFocus.
function D.mark(panel, x, y, w, h, f)
    if f and ZeD.Focus and ZeD.Focus.mark then return ZeD.Focus.mark(panel, x, y, w, h, f) and true or false end
    return false
end

--- Move the controller, soon, to the first stop in the tab's zone that pred(stop) accepts; D.focusId: to stop id.
function D.focusNext(win, st, pred)
    local Fo = ZeD.Input and ZeD.Input.Focus
    if Fo and Fo.focusSoon and st.tkZone then Fo.focusSoon(win, st.tkZone, pred, 1) end
end
function D.focusId(win, st, id)
    if id then D.focusNext(win, st, function(e) return e.id == id end) end
end

-- ---------------------------------------------------------------------------
-- WORDS
-- ---------------------------------------------------------------------------
--- "Day 12": the game day n, or nil.
function D.day(n) return n and tr("UI_ZeD_Tk_Day", n) or nil end

-- true for "21:42": the game's own clock option (24-hour clock) is on and the game's language isn't English. English
-- always keeps "9:42 PM". Read at most once a second, as a list asks once per row.
local _h24 = { at = -1, on = false }
function D.clock24()
    local t = now()
    if t >= _h24.at and t - _h24.at < 1000 then return _h24.on end
    _h24.at = t
    local on = false
    pcall(function()
        local core = getCore and getCore()
        local lang = Translator and Translator.getLanguage and Translator.getLanguage()
        -- (each method checked before it is called: another build of the game may lack one)
        if core and core.getOptionClock24Hour and lang and lang.name then
            on = core:getOptionClock24Hour() == true and tostring(lang:name()) ~= "EN"
        end
    end)
    _h24.on = on
    return on
end

--- "9:42 PM" (or "21:42", D.clock24) from real seconds, and the date's table; nil for no number.
function D.clock(sec)
    if type(sec) ~= "number" then return nil end
    local ok, d = pcall(os.date, "*t", sec)
    if not ok or type(d) ~= "table" then return nil end
    if D.clock24() then return string.format("%02d:%02d", d.hour or 0, d.min or 0), d end
    local h, pm = d.hour or 0, (d.hour or 0) >= 12
    if h > 12 then h = h - 12 elseif h == 0 then h = 12 end
    return tr(pm and "UI_ZeD_Tk_TimePm" or "UI_ZeD_Tk_TimeAm", h, string.format("%02d", d.min or 0)), d
end

--- "Nov 5, 9:42 PM" from the seconds filed, drawn on the viewer's side, with UTC after it while DATE_SAYS_UTC.
function D.realDate(sec)
    local clock, d = D.clock(sec)
    if not clock then return nil end
    return tr(DATE_SAYS_UTC and "UI_ZeD_Tk_WhenUtc" or "UI_ZeD_Tk_When", tr(MONTHS[d.month or 1] or MONTHS[1]), d.day or 1, clock)
end

--- "Nov 5", for what happened on a day.
function D.shortDate(sec)
    local _, d = D.clock(sec)
    if not d then return nil end
    return tr("UI_ZeD_Tk_ShortDate", tr(MONTHS[d.month or 1] or MONTHS[1]), d.day or 1)
end

function D.replies(n)
    if not n or n < 1 then return tr("UI_ZeD_Tk_NoReply") end
    if n == 1 then return tr("UI_ZeD_Tk_OneReply") end
    return tr("UI_ZeD_Tk_Replies", n)
end

--- s with its line breaks turned to spaces.
function D.oneLine(s) return (string.gsub(s or "", "\n", " ")) end

-- how many characters of s fit in maxW, at least one
function D.fitChars(s, font, maxW)
    local lo, hi = 1, #s
    while lo < hi do
        local mid = math.ceil((lo + hi) / 2)
        if ZeD.TM:MeasureStringX(font, string.sub(s, 1, mid)) <= maxW then lo = mid else hi = mid - 1 end
    end
    return lo
end

--- The wrap for words a player typed: as the atom's, but a word wider than the line is cut to fit, and an empty line
--- stays. Returns the lines.
function D.wrap(text, font, maxW)
    local lines = {}
    if not text or text == "" then return lines end
    local from, n = 1, #text
    while from <= n + 1 do
        local brk = string.find(text, "\n", from, true) or (n + 1)
        local para = string.sub(text, from, brk - 1)
        if para == "" then
            lines[#lines + 1] = ""
        else
            for _, one in ipairs(ZeD.Atoms.wrapText(para, font, maxW)) do
                while #one > 1 and ZeD.TM:MeasureStringX(font, one) > maxW do
                    local fit = D.fitChars(one, font, maxW)
                    lines[#lines + 1] = string.sub(one, 1, fit)
                    one = string.sub(one, fit + 1)
                end
                lines[#lines + 1] = one
            end
        end
        from = brk + 1
    end
    return lines
end

--- A kind's word in the player's language; an unknown kind reads as no kind.
function TC.kindWord(k) return tr(KIND_WORD[k] or KIND_WORD.NONE) end
--- A status's word; and the status as staff see it (a ticket the player sees as Seen is still Open to staff).
function D.stWord(st) return tr(ST_WORD[st] or ST_WORD.Open) end
function D.staffSt(st) if st == "Seen" then return "Open" end return st or "Open" end

function D.kindColor(k)
    local T = ZeD.T
    if k == "GRIEF" then return T.danger elseif k == "STUCK" then return T.warning elseif k == "BUG" then return T.info
    elseif k == "QUESTION" then return T.positive elseif k == "APPEAL" then return T.violet or T.info end
    return T.textDim
end

-- ---------------------------------------------------------------------------
-- SMALL PARTS: the kind's tag, the status, a chip
-- ---------------------------------------------------------------------------
local _tag = { keepCase = true }
function D.kindUpper(k) return ZeD.upper(tr(KIND_WORD[k] or KIND_WORD.NONE)) end

function D.drawKind(panel, x, y, k, a, onFocus)
    local T = ZeD.T
    local c = onFocus and T.textOnFocus or D.kindColor(k)
    _tag.textColor, _tag.frameColor, _tag.alpha = c, c, a
    return ZeD.Atoms.drawTag(panel, x, y, D.kindUpper(k), nil, _tag)
end

-- the widest kind's tag, for the rows' first column (kept while the text measures hold)
function D.kindColW()
    local X = ZeD.Text
    local e = tostring(X and X.measureEpoch and X.measureEpoch() or 0) .. ":" .. tostring(px(100)) .. ":" .. tostring(ZeD.TM:getFontHeight(ZeD.T.fontF1))
    if D._kcE ~= e or not D._kcW then
        local w = 0
        for k in pairs(KIND_WORD) do w = math.max(w, ZeD.Atoms.tagW(D.kindUpper(k), false, _tag)) end
        D._kcE, D._kcW = e, w
    end
    return D._kcW
end

function D.markAt(panel, x, y, st, a, onFocus)
    local T, A = ZeD.T, ZeD.Atoms
    local m = ST_MARK[st] or ST_MARK.Open
    local c = T[m[2]] or T.textDim
    if onFocus then c = T.textOnFocus end
    if a and a < 1 then c = { r = c.r, g = c.g, b = c.b, a = (c.a or 1) * a } end
    local sz = T.px(6)
    if m[1] == "dot" then A.drawStatusDot(panel, x, y, c, sz)
    elseif m[1] == "half" then A.drawStatusHalf(panel, x, y, c, sz)
    else A.drawStatusHollow(panel, x, y, c, sz) end
end

function D.statusW(st)
    return ZeD.T.px(10) + ZeD.TM:MeasureStringX(ZeD.T.fontF3, D.stWord(st))
end

-- the mark and its word from x, on one line of height h
function D.drawStatus(panel, x, y, h, st, a, onFocus)
    local T = ZeD.T
    local fh = ZeD.TM:getFontHeight(T.fontF3)
    D.markAt(panel, x, y + math.floor((h - T.px(6)) / 2), st, a, onFocus)
    local c = onFocus and T.textOnFocus or T.textDim
    panel:drawText(D.stWord(st), x + T.px(10), y + math.floor((h - fh) / 2), c.r, c.g, c.b, (c.a or 1) * (a or 1), T.fontF3)
end

--- A chip's height, and its width for text.
function D.chipH() return ZeD.TM:getFontHeight(ZeD.T.fontF3) + ZeD.T.px(7) end
function D.chipW(text) return ZeD.TM:MeasureStringX(ZeD.T.fontF3, text) + ZeD.T.px(16) end

--- A chip: a small button with its word (c.text), solid accent while c.on, grayed by c.disabled; on hover c.why or
--- c.help goes to the help line. id: its stop, for the focus mark; mx, my: the pointer, or nil.
function D.drawChip(panel, win, x, y, w, h, c, id, mx, my)
    local T, A = ZeD.T, ZeD.Atoms
    local hov = mx ~= nil and mx >= x and mx < x + w and my >= y and my < y + h
    local a = c.disabled and T.disabledAlpha or 1
    local bg = c.on and T.accent or T.surf1
    panel:drawRect(x, y, w, h, (bg.a or 1) * a, bg.r, bg.g, bg.b)
    if hov and not c.on and not c.disabled then
        local hv = T.hover
        panel:drawRect(x, y, w, h, hv.a or 1, hv.r, hv.g, hv.b)
    end
    local onF = D.mark(panel, x, y, w, h, D.focusOf(win, id, c.on))
    A.frame(panel, x, y, w, h, c.on and T.accent or T.borderS, a)
    local tc = (onF and T.textOnFocus) or (c.on and T.textOnAccent) or T.text
    local tw, fh = ZeD.TM:MeasureStringX(T.fontF3, c.text), ZeD.TM:getFontHeight(T.fontF3)
    panel:drawText(c.text, x + math.floor((w - tw) / 2), y + math.floor((h - fh) / 2), tc.r, tc.g, tc.b, (tc.a or 1) * a, T.fontF3)
    if hov and (c.why or c.help) then ZeD.Help.set(win, c.why or c.help) end
end

--- A run of controls wrapped into width w from dx0: each gets dx, dy, w, h. Returns the height used.
function D.flow(ctls, w, dx0)
    local gap = px(CHIP_GAP)
    local h = D.chipH()
    local dx, dy = dx0, 0
    for _, c in ipairs(ctls) do
        c.w = math.min(c.boxW or D.chipW(c.text), w - dx0)
        if dx > dx0 and dx + c.w > w then
            dx = dx0
            dy = dy + h + gap
        end
        c.dx, c.dy, c.h = dx, dy, h
        dx = dx + c.w + gap
    end
    return dy + h
end

-- ---------------------------------------------------------------------------
-- THE TEXT FIELDS. A field is the game's text box in the drawer, as the Journal's is. A child cannot be cut by the
-- list's stencil, so it shows only while it is whole in view and nothing lies over it; otherwise the box goes and its
-- words are drawn in the field's place. It also shows only in a frame that drew it: the drawer is shared and nothing
-- says the tab has changed. The test in its own prerender runs after the drawer's render, so a frame that did not stamp
-- it never shows it.
-- ---------------------------------------------------------------------------
--- A field by its key in this window; below, its inner text box, its text, and setting its text.
function D.fieldOf(win, key) return win._tkFields and win._tkFields[key] or nil end

function D.fieldInner(box) return box and (box._entry or box.input) or nil end

function D.fieldText(win, key)
    local box = D.fieldOf(win, key)
    -- a masked box (a password) answers getText with its stars; the typed words are its internal text, as
    -- vanilla reads its own password boxes
    local inner = D.fieldInner(box)
    if inner and inner.javaObject and inner.isMasked and inner:isMasked() then return inner:getInternalText() or "" end
    return box and box:getText() or ""
end

function D.setField(win, key, text)
    local inner = D.fieldInner(D.fieldOf(win, key))
    if inner then inner:setText(text or "") end
end

function D.gate(box)
    local base = box.prerender
    box.prerender = function(self)
        if not self._tkShown then
            local e = D.fieldInner(self)
            if e and e:isFocused() then e:unfocus() end
            self:setVisible(false)
            return
        end
        self._tkShown = false
        base(self)
    end
end

--- Make the field key as a hidden child of panel: multi, a text box; else a Find box. hint: the words while it is
--- empty. it.one: a name, one line: Enter runs it.enter, Escape it.esc; it.max: its most characters
function D.makeField(win, panel, key, multi, hint, it)
    win._tkFields = win._tkFields or {}
    local box
    if multi then
        box = ZeD_TextEntry:new(0, 0, px(200), px(48), hint)
        box.maxLines = (it and it.one) and 1 or FIELD_LINES
        box.maxLength = (it and it.max) or L.TEXT_MAX
    else
        box = ZeD_SearchField:new(0, 0, px(200), hint)
    end
    box:initialise()
    box:setVisible(false)
    panel:addChild(box)
    D.gate(box)
    local inner = D.fieldInner(box)
    if inner then
        -- (Escape leaves the field, as chat's line does)
        inner.onOtherKey = function(_, k)
            if k == Keyboard.KEY_ESCAPE then
                inner:unfocus()
                if box.tkEsc then box.tkEsc() end
            end
        end
        if it and it.one then
            inner:setMultipleLine(false)
            inner.onCommandEntered = function() if box.tkEnter then box.tkEnter() end end
        end
        -- (the wheel scrolls the card or the tab under the pointer: nothing scrolls inside the scroll)
        inner.onMouseWheel = function(_, del)
            local st = win._tkSt
            local sc = st and (TC.activeScroll(st) or st.scroll)
            if sc and sc.visible then sc:handleMouseWheel(del) end
            return true
        end
        if not multi then inner.javaObject:setMaxTextLength(L.FIND_MAX) end
    end
    win._tkFields[key] = box
    return box
end

--- Place a field's box and show it for this frame only (D.gate hides it in a frame that does not call this).
function D.showField(box, x, y, w, h)
    if box:getX() ~= x then box:setX(x) end
    if box:getY() ~= y then box:setY(y) end
    if box:getWidth() ~= w then box:setWidth(w) end
    if box:getHeight() ~= h then box:setHeight(h) end
    if not box:isVisible() then box:setVisible(true) end
    box._tkShown = true
end

-- a text box under the controller: ZeD's keyboard types into it, and the window has the pad back when it closes
function D.padType(win, box)
    local inner = D.fieldInner(box)
    if not inner then return end
    local jd = getJoypadData and getJoypadData(win.playerNum or 0)
    if jd and OnScreenKeyboard and OnScreenKeyboard.Show then
        local ok, osk = pcall(OnScreenKeyboard.Show, jd.player or 0, inner, jd)
        if ok and osk then
            -- (one RT ends the typing. On several lines the keyboard's RT makes a line break, which leaves B, and B puts
            -- the field back as it was, as the plain way out)
            if osk.setSingleLine then osk:setSingleLine() else osk._multi = false end
            osk.prevFocus = win
            jd.focus = osk
            if updateJoypadFocus then updateJoypadFocus(jd) end
            return
        end
    end
    inner:focus()
end

--- Type into a field: with the controller through ZeD's keyboard (D.padType), else the caret goes into its box
--- while it shows.
function D.useField(win, key)
    local box = D.fieldOf(win, key)
    if not box then return end
    if D.padOn() then D.padType(win, box); return end
    local inner = D.fieldInner(box)
    if inner and box:isVisible() then inner:focus() end
end

--- A field's height: its rows, and more for the words it holds, up to the card's view (sh): a field taller than the
--- view could never show its box.
function D.fieldH(win, it, w, sh)
    local T = ZeD.T
    local lh = ZeD.TM:getFontHeight(T.fontF2)
    if it.one then return lh + px(2 * FIELD_PAD) end
    local text = D.fieldText(win, it.key)
    if text ~= it.seen then
        it.seen = text
        it.count = #D.wrap(text, T.fontF2, math.max(1, w - px(2 * FIELD_PAD + 8)))
    end
    local h = math.max(it.rows, (it.count or 0) + 1) * lh + px(2 * FIELD_PAD)
    if sh then h = math.min(h, math.max(lh + px(2 * FIELD_PAD), sh - px(2))) end
    return h
end

--- Draw field it at (x, y, w, h): its box shows while it is whole in the view (viewY, viewH) and not covered, and
--- otherwise its words, or its hint, are drawn in its place.
function D.drawField(panel, win, t, it, x, y, w, h, viewY, viewH, covered)
    local T, A = ZeD.T, ZeD.Atoms
    local box = D.fieldOf(win, it.key) or D.makeField(win, panel, it.key, true, it.hint, it)
    box.placeholder = ""             -- (the box draws one line and nothing cuts it: the hint is drawn here, wrapped)
    box.tkEnter, box.tkEsc = it.enter, it.esc
    local inner = D.fieldInner(box)
    local focused = inner and inner:isFocused()
    -- it.seed: what the game holds. The words follow it unless someone has typed over them
    if it.seed ~= nil and box._tkSeed ~= it.seed then
        if box._tkSeed == nil or box:getText() == box._tkSeed then D.setField(win, it.key, it.seed) end
        box._tkSeed = it.seed
    end
    local f = D.focusOf(win, it.c.fullId)
    local bg = T.surf1
    panel:drawRect(x, y, w, h, bg.a or 1, bg.r, bg.g, bg.b)
    D.mark(panel, x, y, w, h, f)
    A.frame(panel, x, y, w, h, (focused or f) and T.accent or T.borderS)
    -- (a box with the caret stays: hiding it would hand the next keys to the game)
    local shown = not covered and (focused or (y >= viewY and y + h <= viewY + viewH))
    if shown then
        D.showField(box, x, y, w, h)
        if t.wantField == it.key then
            t.wantField = nil
            if inner then inner:focus() end
        end
    end
    -- its words where the box would be, or under an empty box its hint (the list's stencil cuts them)
    local text = box:getText() or ""
    if shown and (text ~= "" or focused) then return end
    local c = (text == "") and T.textDim or T.text
    local s = (text == "") and it.hint or text
    -- (it.mask: a password, starred here as the box itself stars it)
    if it.mask and text ~= "" then s = string.rep("*", #text) end
    local lh = ZeD.TM:getFontHeight(T.fontF2)
    for i, line in ipairs(D.wrap(s, T.fontF2, math.max(1, w - px(2 * FIELD_PAD + 8)))) do
        panel:drawText(line, x + px(6), y + px(FIELD_PAD) + (i - 1) * lh, c.r, c.g, c.b, c.a or 1, T.fontF2)
    end
end

-- ---------------------------------------------------------------------------
-- THE TICKET ROW (mine and the queue, as drawn: the kind, two lines, the status)
-- ---------------------------------------------------------------------------
--- A ticket row's height: its two lines and their padding.
function D.rowH()
    local T = ZeD.T
    return ZeD.TM:getFontHeight(T.fontF2) + ZeD.TM:getFontHeight(T.fontF3) + px(2) + 2 * px(ROW_PAD)
end

function D.drawRow(panel, win, t, it, x, dy, cw, mx, my)
    local T, A = ZeD.T, ZeD.Atoms
    local pad = px(PAD)
    local hov = mx ~= nil and mx >= x and mx < x + cw and my >= dy and my < dy + it.h
    if hov then
        local hv = T.hover
        panel:drawRect(x, dy, cw, it.h, hv.a or 1, hv.r, hv.g, hv.b)
        if it.help then ZeD.Help.set(win, it.help) end
    end
    local onF = D.mark(panel, x + pad, dy, cw - pad, it.h, D.focusOf(win, t.prefix .. it.c.id))
    local a = it.dim and DIM_A or 1
    local tx = x + pad
    D.drawKind(panel, tx, dy + px(ROW_PAD), it.kind, a, onF)
    local sx = x + cw - pad - D.statusW(it.st)
    local bx = tx + D.kindColW() + px(8)
    local room = math.max(0, sx - px(8) - bx)
    local f2h = ZeD.TM:getFontHeight(T.fontF2)
    local tc = onF and T.textOnFocus or T.text
    panel:drawText(A.truncateText(it.text, T.fontF2, room), bx, dy + px(ROW_PAD), tc.r, tc.g, tc.b, (tc.a or 1) * a, T.fontF2)
    local mc = onF and T.textOnFocus or T.textDim
    panel:drawText(A.truncateText(it.meta, T.fontF3, room), bx, dy + px(ROW_PAD) + f2h + px(2), mc.r, mc.g, mc.b, (mc.a or 1) * a, T.fontF3)
    D.drawStatus(panel, sx, dy + px(ROW_PAD), px(16), it.st, a, onF)
    A.drawDividerH(panel, x, dy + it.h - T.hair, cw, false)
    t.listHits[#t.listHits + 1] = { x = x, y = dy, w = cw, h = it.h, c = it.c }
end

-- ---------------------------------------------------------------------------
-- ITEMS IN A TAB'S LIST (w: the width inside the tab's side margins)
-- ---------------------------------------------------------------------------
--- An item's height at width w; TC.items' own kinds measure themselves.
function TC.itemH(it, w)
    local T = ZeD.T
    local tt = it.t
    local ext = TC.items[tt]
    if ext then return ext.layout(it.win, it, w, nil) end
    if tt == "row" then return D.rowH() end
    if tt == "wrap" then
        if it.wrapW ~= w then
            it.wrapW = w
            it.lines = ZeD.Atoms.wrapText(it.text, T.fontF2, math.max(1, w))
        end
        return #it.lines * ZeD.TM:getFontHeight(T.fontF2) + px(6)
    end
    if tt == "chips" then return D.flow(it.ctls, w, it.lw + px(8)) + px(8) end
    if tt == "find" then return T.inputH + px(8) end
    if tt == "pager" then
        -- Refresh at the left, the page's words beside it, Previous and Next at the right
        for _, c in ipairs(it.ctls) do c.w, c.h = ZeD.Molecules.buttonW(c.text), T.buttonH end
        local right = w
        for i = #it.ctls, 2, -1 do
            local c = it.ctls[i]
            right = right - c.w
            c.dx, c.dy = right, 0
            right = right - px(CHIP_GAP)
        end
        it.ctls[1].dx, it.ctls[1].dy = 0, 0
        return T.buttonH + px(8)
    end
    return 0
end

function D.drawChips(panel, win, t, it, x, dy, cw, mx, my)
    local T, A, M = ZeD.T, ZeD.Atoms, ZeD.Molecules
    local pad = px(PAD)
    A.surfaceFill(panel, x, dy, cw, it.h, "surf1")
    local lc = T.textHead
    panel:drawText(it.label, x + pad, dy + px(4) + math.floor((D.chipH() - ZeD.TM:getFontHeight(T.fontF1)) / 2), lc.r, lc.g, lc.b, lc.a or 1, T.fontF1)
    for _, c in ipairs(it.ctls) do
        local cx, cy = x + pad + c.dx, dy + px(4) + c.dy
        local id = t.prefix .. c.id
        if c.box then
            local hov = mx ~= nil and mx >= cx and mx < cx + c.w and my >= cy and my < cy + c.h
            M.drawPopupMenu(panel, cx, cy, c.w, c.h, c.text, hov, D.focusOf(win, id), false, nil, true)
            if hov and c.help then ZeD.Help.set(win, c.help) end
            c.bx, c.by = cx, cy
        else
            D.drawChip(panel, win, cx, cy, c.w, c.h, c, id, mx, my)
        end
        t.listHits[#t.listHits + 1] = { x = cx, y = cy, w = c.w, h = c.h, c = c }
    end
end

function D.drawFind(panel, win, st, t, it, x, dy, cw)
    local T, A = ZeD.T, ZeD.Atoms
    local pad = px(PAD)
    A.surfaceFill(panel, x, dy, cw, it.h, "surf1")
    local lc = T.textHead
    local h = T.inputH
    panel:drawText(it.label, x + pad, dy + px(4) + math.floor((h - ZeD.TM:getFontHeight(T.fontF1)) / 2), lc.r, lc.g, lc.b, lc.a or 1, T.fontF1)
    local fx = x + pad + it.lw + px(8)
    local fw = cw - pad - (fx - x)
    local fy = dy + px(4)
    local box = D.fieldOf(win, "find")
    if not box then
        box = D.makeField(win, panel, "find", false, it.hint)
        box._lastText = t.q.find or ""
        D.setField(win, "find", box._lastText)
        box.onFilter = function(_, text) TC.onFind(st, text) end
    end
    D.mark(panel, fx, fy, fw, h, D.focusOf(win, t.prefix .. it.c.id))
    if fy >= t.sy and fy + h <= t.sy + t.sh and not t.popup and win._drawerItem == nil then
        D.showField(box, fx, fy, fw, h)
    else
        local bg, bc = T.surf1, T.borderS
        panel:drawRect(fx, fy, fw, h, bg.a or 1, bg.r, bg.g, bg.b)
        panel:drawRectBorder(fx, fy, fw, h, bc.a or 1, bc.r, bc.g, bc.b)
        local text = box:getText() or ""
        local tc = (text == "") and T.textDim or T.text
        local s = A.truncateText((text == "") and it.hint or text, T.fontF2, fw - px(32))
        panel:drawText(s, fx + px(26), fy + math.floor((h - ZeD.TM:getFontHeight(T.fontF2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
    end
    t.listHits[#t.listHits + 1] = { x = fx, y = fy, w = fw, h = h, c = it.c, keep = true }
end

function D.drawPager(panel, win, t, it, x, dy, cw, mx, my)
    local T, A, M = ZeD.T, ZeD.Atoms, ZeD.Molecules
    local pad = px(PAD)
    for _, c in ipairs(it.ctls) do
        local bx, by = x + pad + c.dx, dy + px(4) + c.dy
        local hov = mx ~= nil and mx >= bx and mx < bx + c.w and my >= by and my < by + c.h
        M.drawButton(panel, bx, by, c.w, c.h, c.text, "default", hov and isMouseButtonDown(0), nil,
            { hover = hov, disabled = c.disabled, help = c.why or c.help, win = win, focus = D.focusOf(win, t.prefix .. c.id) })
        t.listHits[#t.listHits + 1] = { x = bx, y = by, w = c.w, h = c.h, c = c }
    end
    if it.text then
        local first, second = it.ctls[1], it.ctls[2]
        local lx = x + pad + first.dx + first.w + px(8)
        local rx = x + pad + (second and second.dx or (cw - 2 * pad))
        local c = T.textDim
        local s = A.truncateText(it.text, T.fontF3, math.max(0, rx - lx - px(8)))
        panel:drawText(s, lx, dy + px(4) + math.floor((T.buttonH - ZeD.TM:getFontHeight(T.fontF3)) / 2), c.r, c.g, c.b, c.a or 1, T.fontF3)
    end
end

--- Draw one item of a tab's list at (x, dy), cw wide; mx, my: the pointer, or nil.
function TC.drawItem(panel, win, st, it, x, dy, cw, mx, my)
    local T = ZeD.T
    local t = ts(st)
    local tt = it.t
    local ext = TC.items[tt]
    if ext then
        local ctx = { hits = t.listHits, prefix = t.prefix, viewY = t.sy, viewH = t.sh, covered = t.popup ~= nil or win._drawerItem ~= nil }
        ext.draw(panel, win, t, it, x + px(PAD), dy, cw - 2 * px(PAD), mx, my, ctx)
    elseif tt == "row" then
        D.drawRow(panel, win, t, it, x, dy, cw, mx, my)
    elseif tt == "wrap" then
        local c = T.textDim
        local fh = ZeD.TM:getFontHeight(T.fontF2)
        for i, s in ipairs(it.lines or {}) do
            panel:drawText(s, x + px(PAD), dy + (i - 1) * fh + px(2), c.r, c.g, c.b, c.a or 1, T.fontF2)
        end
    elseif tt == "chips" then
        D.drawChips(panel, win, t, it, x, dy, cw, mx, my)
    elseif tt == "find" then
        D.drawFind(panel, win, st, t, it, x, dy, cw)
    elseif tt == "pager" then
        D.drawPager(panel, win, t, it, x, dy, cw, mx, my)
    end
end

--- One controller stop for a control: A runs c.run unless c is disabled; cy: its y in the list, for scrolling.
function D.stop(c, id, x, y, w, h, cy)
    return { x = x, y = y, w = w, h = h, cy = cy, id = id, help = c.why or c.help,
        onFocus = function() end,
        onActivate = function(ww) if not c.disabled and c.run then c.run(ww) end end }
end

--- The stops of one item, in reading order, added to out; flag: a field set true on each (the tab's own mark).
function TC.itemStops(out, st, it, x0, dy, cw, flag)
    local t = ts(st)
    local tt = it.t
    local pad = px(PAD)
    local function add(c, x, y, w, h, cy)
        local e = D.stop(c, t.prefix .. c.id, x, y, w, h, cy)
        e[flag] = true
        e.tkWhy = function() return c.why end
        out[#out + 1] = e
        return e
    end
    local ext = TC.items[tt]
    if ext then
        if ext.stops then ext.stops(it, x0, dy, cw - 2 * pad, add) end
    elseif tt == "row" then
        add(it.c, x0, dy, cw - 2 * pad, it.h, it.y)
    elseif tt == "chips" then
        for _, c in ipairs(it.ctls) do add(c, x0 + c.dx, dy + px(4) + c.dy, c.w, c.h, it.y + c.dy) end
    elseif tt == "find" then
        add(it.c, x0 + it.lw + px(8), dy + px(4), cw - 2 * pad - it.lw - px(8), ZeD.T.inputH, it.y)
    elseif tt == "pager" then
        for _, c in ipairs(it.ctls) do add(c, x0 + c.dx, dy + px(4), c.w, c.h, it.y) end
    end
end

--- A key that changes with the list's items and its open pop-up: part of the tab's scroll key, so the controller's
--- stops are rebuilt when it changes.
function TC.listKey(st)
    local t = st.tk
    if not t then return "" end
    return tostring(t.listGen) .. (t.popup and ("p" .. tostring(t.popup.key)) or "")
end

--- A tab's list starts its frame; base is the help line's words until something under the pointer says more.
function TC.beginList(win, st, sy, sh, base)
    local t = ts(st)
    t.listHits = {}
    t.sy, t.sh = sy, sh
    if base then ZeD.Help.set(win, base) end
end

--- A click in a tab's list; true when the list took it.
function TC.listClick(win, st, x, y)
    local t = st.tk
    if not t then return false end
    if t.popup then
        D.popupClick(st, t, x, y)
        return true
    end
    if y < (t.sy or 0) then return false end
    for _, h in ipairs(t.listHits) do
        if inside(h, x, y) then
            if h.keep then return false end      -- (a field: its own box takes the press)
            if not h.c.disabled and h.c.run then
                sound()
                h.c.run(win)
            elseif h.c.disabled then
                D.grayPress(t, h.c)
            end
            return true
        end
    end
    return false
end

-- ---------------------------------------------------------------------------
-- THE SERVER TAB'S BLOCK
-- ---------------------------------------------------------------------------
function D.playerOpen(st) return st == "Sent" or st == "Seen" or st == "Progress" end

function D.mineOpen()
    local n = 0
    for _, r in ipairs(C.mine or {}) do
        if D.playerOpen(r.st) then n = n + 1 end
    end
    return n
end

function D.mineRow(st, r)
    local parts = { "#" .. tostring(r.id) }
    if r.day then parts[#parts + 1] = D.day(r.day) end
    parts[#parts + 1] = D.replies(r.replies)
    return { k = "tk", t = "row", kind = r.kind or Tk.NONE, text = D.oneLine(r.last), meta = table.concat(parts, " | "),
        st = r.st or "Sent", dim = not D.playerOpen(r.st), help = tr("UI_ZeD_Tk_HelpMine"),
        c = { id = "t:" .. tostring(r.id), run = function(win) TC.openMine(win, st, r.id, r.game) end } }
end

--- Once a frame on the Server tab, card or list: a report from chat, a note's Open, and my list without the server
--- part.
function TC.frameServer(win, st)
    local t = ts(st)
    if TC.reportNext then
        local r = TC.reportNext
        TC.reportNext = nil
        st.card = nil
        TC.openReport(win, st, r)
    end
    if TC.qaHold then return end
    if C.openId then
        local id = C.openId
        C.openId = nil
        st.card = nil
        TC.openMine(win, st, id)
    end
    if D.link() == "off" and (not t.mineAt or now() - t.mineAt >= FALLBACK_MINE_MS) then
        t.mineAt = now()
        C.loadMine()
    end
end

function D.flashItem(t)
    local s = D.flashNow(t)
    if t.flashItemText ~= s then
        t.flashItemText = s
        t.flashIt = { k = "tk", t = "wrap", text = s }
    end
    return t.flashIt
end

-- why the stop under the controller is gray: the help line holds the prompts, so a list says it in a line beside it
function D.padWhy(win)
    local Fo = ZeD.Input and ZeD.Input.Focus
    local el = Fo and Fo.getFocusedElement and Fo.getFocusedElement(win)
    return el and el.tkWhy and el.tkWhy() or nil
end

--- A tab's own words under the controller: a press's answer, or why the stop is gray; nil with the mouse.
function TC.padWords(win, st)
    if not D.padOn() then return nil end
    local t = ts(st)
    return D.flashNow(t) or D.padWhy(win)
end

function D.whyItem(t, s)
    if t.whyItemText ~= s then
        t.whyItemText = s
        t.whyIt = { k = "tk", t = "wrap", text = s }
    end
    return t.whyIt
end

--- The Tickets block's items, added to out. btnItem makes the tab's own button.
function TC.playerItems(out, win, st, btnItem)
    local t = ts(st)
    local key = tostring(C.seq) .. ":" .. tostring((D.link()))
    if t.mineKey ~= key or not t.mineItems then
        t.mineKey = key
        t.listGen = t.listGen + 1
        local items = {}
        items[#items + 1] = { k = "head", text = getText("UI_userpanel_tickets"), right = tr("UI_ZeD_Tk_NOpen", D.mineOpen()) }
        items[#items + 1] = btnItem("ask", tr("UI_ZeD_Srv_AskAdmins"), tr("UI_ZeD_Srv_HelpTickets"))
        items[#items + 1] = { k = "tk", t = "wrap", text = tr("UI_ZeD_Tk_AskSub") }
        if #(C.mine or {}) == 0 then items[#items + 1] = { k = "tk", t = "wrap", text = tr("UI_ZeD_Tk_NoneYet") } end
        for _, r in ipairs(C.mine or {}) do items[#items + 1] = D.mineRow(st, r) end
        t.mineItems = items
    end
    local pad = D.padOn()
    for i, it in ipairs(t.mineItems) do
        out[#out + 1] = it
        -- (with the controller the help line holds the prompts: the answer to Send is a line here)
        if i == 2 and pad and D.flashNow(t) then out[#out + 1] = D.flashItem(t) end
    end
end

function TC.mineHelp() return tr("UI_ZeD_Tk_HelpMine") end

-- ---------------------------------------------------------------------------
-- THE QUEUE
-- ---------------------------------------------------------------------------
function D.qArgs(t)
    local q = t.q
    local find = q.find
    if find == "" then find = nil end
    return { status = q.status, kind = q.kind, who = q.who, mine = q.mine, find = find, newest = q.newest, page = q.page }
end

function D.sendQueue(t)
    t.queueKey = nil
    if TC.qaHold then return end
    if D.link() == "on" then C.setQueue(D.qArgs(t)) else C.seq = C.seq + 1 end
end

function D.setQ(t, field, value)
    t.q[field] = value
    t.q.page = 1
    D.sendQueue(t)
end

function TC.onFind(st, text)
    local t = ts(st)
    t.q.find = string.sub(text or "", 1, L.FIND_MAX)
    t.findAt = now()
end

--- How many tickets are open: the server's count with the server part, else the game's list for staff (0 for
--- anyone else).
function TC.openCount()
    if D.link() == "on" then return (C.counts and C.counts.open) or 0 end
    if D.cap("AnswerTickets") then return C.fallbackOpen() end
    return 0
end

--- The tab's name with the open count after it, when there is one.
function TC.tabLabel(base)
    local n = TC.openCount()
    if n > 0 then return tr("UI_ZeD_Tk_TabCount", base, n) end
    return base
end

-- the page the tab shows: the server's, or the game's list read here
function D.queuePage(t, mode)
    if mode == "on" then return C.queue end
    return C.fallbackQueue(D.qArgs(t))
end

function D.queueHelp(t, mode, page)
    if mode == "off" then return tr("UI_ZeD_Tk_HelpFallback") end
    if t.q.status == "Spam" then return tr(D.isAdmin() and "UI_ZeD_Tk_HelpSpamAdmin" or "UI_ZeD_Tk_HelpSpamMod") end
    return tr("UI_ZeD_Tk_HelpQueue", page and page.n or 0)
end

-- the lines that say something is off with this server (frozen, no saves, the game's window holding more)
function D.queueNotes(frozen, page, mode)
    local out = {}
    if mode == "off" then out[#out + 1] = tr("UI_ZeD_Tk_HelpFallback") end
    if C.gameSilent then out[#out + 1] = tr((mode == "off") and "UI_ZeD_Tk_GameSilentOff" or "UI_ZeD_Tk_GameSilent") end
    if frozen then out[#out + 1] = C.errText("frozen") end
    if page and page.noSave then out[#out + 1] = tr("UI_ZeD_Tk_NoSave") end
    if page and page.skipped and page.skipped > 0 then out[#out + 1] = tr("UI_ZeD_Tk_Skipped", page.skipped) end
    return out
end

function D.statusChips(t, mode, page)
    local list = (mode == "on") and { "Open", "Answered", "Closed", "All", "Spam" } or { "Open", "Answered", "All" }
    local spam = (page and page.spam) or (C.counts and C.counts.spam) or 0
    local ctls = {}
    for _, s in ipairs(list) do
        local word = (s == "All") and tr("UI_ZeD_Tk_ShowAll") or D.stWord(s)
        if s == "Spam" and spam > 0 then word = tr("UI_ZeD_Tk_SpamN", spam) end
        ctls[#ctls + 1] = { id = "s:" .. s, text = word, on = t.q.status == s, help = tr("UI_ZeD_Tk_HelpShow"),
            run = function() D.setQ(t, "status", s) end }
    end
    return ctls
end

function D.popupWord(t, key)
    local q = t.q
    if key == "kind" then
        if q.kind then return tr(KIND_WORD[q.kind] or KIND_WORD.NONE) end
        return tr("UI_ZeD_Tk_AnyKind")
    elseif key == "who" then
        return q.who or tr("UI_ZeD_Tk_AnyPlayer")
    end
    if q.mine == "ME" then return tr("UI_ZeD_Tk_TakenMe") end
    if q.mine == "NOBODY" then return tr("UI_ZeD_Tk_NotTaken") end
    return tr("UI_ZeD_Tk_Anyones")
end

function D.popupBox(st, t, key, help)
    local text = D.popupWord(t, key)
    return { id = "pop:" .. key, text = text, box = true, boxW = ZeD.Molecules.popupMenuW(text, true), help = help,
        run = function() D.openPopup(st, t, key) end }
end

function D.staffRow(st, r)
    local parts = { "#" .. tostring(r.id), tostring(r.author) }
    parts[#parts + 1] = r.day and D.day(r.day) or tr("UI_ZeD_Tk_NoDay")
    if r.where then parts[#parts + 1] = r.where end
    if r.assignee then parts[#parts + 1] = r.assignee end
    return { k = "tk", t = "row", kind = r.kind or Tk.NONE, text = D.oneLine(r.first), meta = table.concat(parts, " | "),
        st = D.staffSt(r.st), dim = not Tk.isOpen(r.st),
        c = { id = "t:" .. tostring(r.id), run = function(win) TC.openStaff(win, st, r.id, r.game) end } }
end

function D.pagerItem(t, page)
    local n, of = page.page or 1, page.pages or 1
    local ctls = { { id = "refresh", text = getText("IGUI_UserList_BannedIPs_Refresh"), help = tr("UI_ZeD_Tk_HelpRefresh"), run = function()
        if TC.qaHold then return end
        if D.link() == "on" then C.openQueue(D.qArgs(t)) else C.adminAsk(true) end
    end } }
    if of > 1 then
        ctls[2] = { id = "prev", text = tr("UI_ZeD_Tk_Prev"), disabled = n <= 1, why = (n <= 1) and tr("UI_ZeD_Tk_FirstPage") or nil,
            run = function() t.q.page = n - 1; D.sendQueue(t) end }
        ctls[3] = { id = "next", text = tr("UI_ZeD_Tk_Next"), disabled = n >= of, why = (n >= of) and tr("UI_ZeD_Tk_LastPage") or nil,
            run = function() t.q.page = n + 1; D.sendQueue(t) end }
    end
    return { k = "tk", t = "pager", ctls = ctls, text = (of > 1) and tr("UI_ZeD_Tk_PageOf", n, of) or nil }
end

function D.buildQueue(st, t, mode, frozen, page)
    local T, tm = ZeD.T, ZeD.TM
    local items = {}
    local open = (page and page.open) or (C.counts and C.counts.open) or 0
    items[#items + 1] = { k = "head", text = getText("UI_userpanel_tickets"), right = tr("UI_ZeD_Tk_NOpen", open) }
    if mode == "wait" then
        items[#items + 1] = { k = "tk", t = "wrap", text = tr("UI_ZeD_Tk_LinkWait") }
        return items
    end
    if page and page.authors then t.authors = page.authors end
    local lShow, lKind, lFind = tr("UI_ZeD_Tk_FilterShow"), tr("UI_ZeD_Tk_FilterKind"), tr("UI_ZeD_Tk_FilterFind")
    local lw = math.max(tm:MeasureStringX(T.fontF1, lShow), tm:MeasureStringX(T.fontF1, lKind), tm:MeasureStringX(T.fontF1, lFind))
    items[#items + 1] = { k = "tk", t = "chips", label = lShow, lw = lw, ctls = D.statusChips(t, mode, page) }
    local picks = { D.popupBox(st, t, "kind", tr("UI_ZeD_Tk_HelpFilterKind")), D.popupBox(st, t, "who", tr("UI_ZeD_Tk_HelpFilterWho")) }
    if mode == "on" then picks[#picks + 1] = D.popupBox(st, t, "mine", tr("UI_ZeD_Tk_HelpFilterMine")) end
    picks[#picks + 1] = { id = "sort", text = tr(t.q.newest and "UI_ZeD_Tk_Newest" or "UI_ZeD_Tk_Oldest"),
        help = tr("UI_ZeD_Tk_HelpSort"), run = function() D.setQ(t, "newest", not t.q.newest) end }
    items[#items + 1] = { k = "tk", t = "chips", label = lKind, lw = lw, ctls = picks }
    items[#items + 1] = { k = "tk", t = "find", label = lFind, lw = lw, hint = tr("UI_ZeD_Tk_FindHint"),
        c = { id = "find", help = tr("UI_ZeD_Tk_HelpFind"), run = function(ww) D.useField(ww, "find") end } }
    for _, s in ipairs(D.queueNotes(frozen, page, mode)) do items[#items + 1] = { k = "tk", t = "wrap", text = s } end
    if not page then
        items[#items + 1] = { k = "tk", t = "wrap", text = tr("UI_ZeD_Tk_Loading") }
        return items
    end
    if #(page.rows or {}) == 0 then
        local q = t.q
        local plain = q.status == "Open" and not q.kind and not q.who and not q.mine and (q.find or "") == ""
        items[#items + 1] = { k = "tk", t = "wrap", text = tr(plain and "UI_ZeD_Tk_NothingOpen" or "UI_ZeD_Tk_NoMatch") }
    end
    for _, r in ipairs(page.rows or {}) do items[#items + 1] = D.staffRow(st, r) end
    items[#items + 1] = D.pagerItem(t, page)
    return items
end

-- once a frame while a staff surface shows: the queue stays open, Find settles, a changed row brings a fresh page
function D.queueTick(st, t)
    t.seenAt = now()
    TC._queueT = t
    if t.qaPopNext then       -- (QA: mp_ticket_cards' pop-ups)
        local k = t.qaPopNext
        t.qaPopNext = nil
        D.openPopup(st, t, k)
    end
    if TC.qaHold then return end
    local mode = D.link()
    local settled = t.findAt and now() - t.findAt >= FIND_MS
    if mode == "on" then
        if not C.queueOpen then
            C.openQueue(D.qArgs(t))
            t.rowSeq, t.liveAt = C.rowSeq, now()      -- (that ask is this frame's: no second one behind it)
        end
        if C.queue and C.queue.page and C.queue.page ~= t.q.page and not settled and not C.queueRid then t.q.page = C.queue.page end
        if settled then
            t.findAt = nil
            t.q.page = 1
            C.setQueue(D.qArgs(t))
        elseif not st.card and t.rowSeq ~= C.rowSeq and (not t.liveAt or now() - t.liveAt >= LIVE_MS) then
            t.rowSeq = C.rowSeq
            t.liveAt = now()
            C.setQueue(D.qArgs(t))
        end
    elseif mode == "off" then
        C.adminAsk(false)
        if settled then
            t.findAt = nil
            t.q.page = 1
            C.seq = C.seq + 1
        end
    end
end

--- The queue's items for the Admin tab's list, added to out.
function TC.queueItems(out, win, st)
    local t = ts(st)
    D.queueTick(st, t)
    local mode, frozen = D.link()
    local q = t.q
    local key = table.concat({ tostring(C.seq), mode, tostring(frozen), q.status, q.kind or "", q.who or "", q.mine or "",
        tostring(q.newest), tostring(q.page), (mode == "off") and (q.find or "") or "" }, ":")
    if t.queueKey ~= key or not t.queueList then
        t.queueKey = key
        t.listGen = t.listGen + 1
        local page = D.queuePage(t, mode)
        t.queueList = D.buildQueue(st, t, mode, frozen, page)
        t.queuePageNow = page
    end
    local pad = D.padOn()
    local why = pad and D.padWhy(win) or nil
    for i, it in ipairs(t.queueList) do
        if why and it.t == "pager" then out[#out + 1] = D.whyItem(t, why) end
        out[#out + 1] = it
        if i == 1 and pad and D.flashNow(t) then out[#out + 1] = D.flashItem(t) end
    end
    local notes = D.queueNotes(frozen, t.queuePageNow, mode)
    t.helpNow = notes[1] or D.queueHelp(t, mode, t.queuePageNow)
end

--- The queue kept open while its summary shows, so counts and the game's list stay read (the Admin tab's Tickets row).
function TC.queueWatch(st)
    D.queueTick(st, ts(st))
end

--- The help line's words for the queue, as TC.queueItems last worked them out.
function TC.queueHelp(st)
    local t = st.tk
    return t and t.helpNow or nil
end

-- the queue was left: nothing to sync for. (No window hook says a tab has gone, so the clock does.)
function D.onTick()
    local t = TC._queueT
    if t and C.queueOpen and t.seenAt and now() - t.seenAt >= QUEUE_IDLE_MS then
        TC._queueT = nil
        C.closeQueue()
    end
end

-- ---------------------------------------------------------------------------
-- THE FILTERS' POP-UP LISTS: a list that opens over the rest, modal while open
-- ---------------------------------------------------------------------------
function D.popupModes(t, key)
    local out = {}
    if key == "kind" then
        out[1] = { id = "ALL", label = tr("UI_ZeD_Tk_AnyKind") }
        for _, k in ipairs(Tk.KINDS) do out[#out + 1] = { id = k, label = tr(KIND_WORD[k]) } end
        out[#out + 1] = { id = Tk.NONE, label = tr(KIND_WORD.NONE) }
    elseif key == "who" then
        out[1] = { id = "ALL", label = tr("UI_ZeD_Tk_AnyPlayer") }
        for _, a in ipairs(t.authors or {}) do out[#out + 1] = { id = a, label = a } end
    else
        out[1] = { id = "ALL", label = tr("UI_ZeD_Tk_Anyones") }
        out[2] = { id = "ME", label = tr("UI_ZeD_Tk_TakenMe") }
        out[3] = { id = "NOBODY", label = tr("UI_ZeD_Tk_NotTaken") }
    end
    return out
end

function D.popupActive(t, key)
    if t.popup and t.popup.active ~= nil then return t.popup.active end
    local q = t.q
    if key == "kind" then return q.kind or "ALL" end
    if key == "who" then return q.who or "ALL" end
    return q.mine or "ALL"
end

function D.openPopup(st, t, key)
    t.popup = { key = key, modes = D.popupModes(t, key) }
    local active = D.popupActive(t, key)
    D.focusNext(st.tkWin, st, function(e) return e.tkPop == active end)
end

function D.closePopup(st, t)
    local pop = t.popup
    t.popup = nil
    if pop and pop.from then D.focusId(st.tkWin, st, pop.from)
    elseif pop and pop.key then D.focusId(st.tkWin, st, t.prefix .. "pop:" .. pop.key) end
end

--- A list of picks over a card: box is the control it opens from, modes its rows, active the row now chosen, pick
--- what a row does.
function TC.openPicker(win, st, box, modes, active, pick)
    local t = ts(st)
    t.popup = { key = box.id, modes = modes, box = box, active = active, pick = pick, from = "tk:" .. box.id }
    D.focusNext(win, st, function(e) return e.tkPop == active end)
end

function D.popupPick(st, t, id)
    local pop = t.popup
    local key = pop and pop.key
    D.closePopup(st, t)
    if not key or id == "MORE" then return end
    if pop.pick then
        pop.pick(id)
        return
    end
    if id == "ALL" then id = nil end
    D.setQ(t, key, id)
end

-- the list, last in the frame. Past what fits it stops at a line that points to Find: no scrolling inside scrolling.
function D.drawPopup(panel, win, t, top, bottom)
    local M = ZeD.Molecules
    local pop = t.popup
    local box = pop.box
    if not box then
        for _, it in ipairs(t.queueList or {}) do
            for _, c in ipairs(it.ctls or {}) do
                if c.id == "pop:" .. pop.key then box = c end
            end
        end
    end
    if not (box and box.bx) then
        t.popup = nil
        return
    end
    local rowH = M.popupListH(1)
    local fit = math.max(3, math.floor((bottom - top) / rowH))
    local modes = pop.modes
    if #modes > fit then
        local cut = {}
        for i = 1, fit - 1 do cut[i] = modes[i] end
        cut[fit] = { id = "MORE", label = tr("UI_ZeD_Tk_MorePlayers", #modes - fit + 1), disabled = true }
        modes = cut
    end
    local h = rowH * #modes
    local ly = box.by + box.h
    if ly + h > bottom then ly = math.max(top, bottom - h) end
    local hover = nil
    if not D.padOn() then
        local mx, my = panel:getMouseX(), panel:getMouseY()
        for _, z in ipairs(pop.zones or {}) do
            if inside(z, mx, my) then hover = z.id end
        end
    end
    local o = { minW = box.w, win = win }
    for _, m in ipairs(modes) do
        local f = D.focusOf(win, t.prefix .. "row:" .. tostring(m.id))
        if f then o.focusId, o.focus = m.id, f end
    end
    local _, _, zones = M.drawSortMenuList(panel, box.bx, ly, modes, D.popupActive(t, pop.key), hover, o)
    pop.zones = zones
end

function D.popupClick(st, t, x, y)
    for _, z in ipairs(t.popup.zones or {}) do
        if inside(z, x, y) and not z.disabled then
            sound("UISelectListItem")
            D.popupPick(st, t, z.id)
            return
        end
    end
    D.closePopup(st, t)
end

--- The open list's rows alone are the stops (FocusManager's _menuRows). True when a list is open.
function TC.popupStops(st, out)
    local t = st.tk
    if not (t and t.popup and t.popup.zones) then return false end
    out._menuRows = true
    for _, z in ipairs(t.popup.zones or {}) do
        local id = z.id
        out[#out + 1] = { x = z.x, y = z.y, w = z.w, h = z.h, id = t.prefix .. "row:" .. tostring(id), tkPop = id,
            onFocus = function() end,
            onActivate = function() if not z.disabled then D.popupPick(st, t, id) end end,
            onCancel = function() D.closePopup(st, t) end, promptB = tr("UI_Cancel") }
    end
    return true
end

--- The end of a tab's list: the open pop-up, last and over the rest, and a card's answer in the help line.
function TC.endList(panel, win, st, top, bottom)
    local t = st.tk
    if not t then return end
    if t.popup then D.drawPopup(panel, win, t, top, bottom) end
    local s = D.flashNow(t)
    if s and not D.padOn() then ZeD.Help.set(win, s) end
end

-- ---------------------------------------------------------------------------
-- OPENING AND CLOSING A CARD
-- ---------------------------------------------------------------------------
--- Push card on top of the tab: a fresh scroll, no confirm or pop-up, and the controller lands on its landing stop.
--- card.from: the stop to land on when it goes back; card.parent (the caller's to set): the card it goes back to.
function D.push(win, st, card)
    local t = ts(st)
    st.tkWin = win
    st.card = card
    t.items, t.itemsKey, t.confirm, t.popup, t.busy = nil, nil, nil, nil, nil
    t.scroll:setScrollPos(0)
    t.pushedAt = now()
    D.focusNext(win, st, function(e) return e.tkLand == true end)
end

-- the server's word on a card asked for: a refusal leaves the card at once, with no typed words to speak of
function D.loadAnswer(win, st, card, a)
    if a.ok ~= false or st.card ~= card then return end
    if a.err == "fail" and card.had then return end     -- (what it holds is on screen; a push may yet come)
    D.flash(ts(st), (a.err == "fail") and tr("UI_ZeD_Tk_LoadFail") or C.errText(a.err))
    TC.back(win, st)
end

-- the first frame with data on a card that opened empty: the landing D.push asked for found only the back key. Not if
-- the controller has moved on, and only onto a real stop, since the stops are a frame behind.
function D.landLate(win, st)
    local Fo = ZeD.Input and ZeD.Input.Focus
    local el = Fo and Fo.getFocusedElement and Fo.getFocusedElement(win)
    if el and el.id ~= "tk:back" then return end
    D.focusNext(win, st, function(e) return e.tkLand == true and e.id ~= "tk:back" end)
end

--- Open the Ask the admins card, empty.
function TC.openAsk(win, st)
    local t = ts(st)
    t.ask = { here = false }
    D.setField(win, "ask", "")
    D.push(win, st, { kind = "ask", from = "srv:ask" })
end

-- from chat: Ask the admins with that player named and the chat around the line. The kind is a start: the player can change
-- it. Where the server can't keep a report (no server part, a frozen table, a server part without community, S.cm) only the
-- name goes, in the words: the game's tickets are public and hold no more
function TC.openReport(win, st, r)
    local t = ts(st)
    local ask = { kind = "GRIEF", here = true }
    local mode, frozen = D.link()
    if mode == "on" and not frozen and S.cm == true then
        ask.report = r
    else
        ask.seed = tr("UI_ZeD_Tk_ReportSeed", r.who)
    end
    t.ask = ask
    D.setField(win, "ask", ask.seed or "")
    D.push(win, st, { kind = "ask", from = "srv:ask" })
end

--- Chat asks for a report: the Server tab opens, and its next frame opens the card. r: who, and the chat lines.
function TC.reportFromChat(playerNum, r)
    TC.reportNext = r
    if ZeD_CharacterWindow and ZeD_CharacterWindow.openTab then ZeD_CharacterWindow.openTab(playerNum or 0, "server") end
end

function TC.openMine(win, st, id, game)
    local t = ts(st)
    D.setField(win, "reply", "")
    local card = { kind = "mine", id = id, game = game, from = t.prefix .. "t:" .. tostring(id) }
    D.push(win, st, card)
    if game or TC.qaHold then return end
    C.loadOne(id, function(a) D.loadAnswer(win, st, card, a) end)
    C.read(id)
end

--- Open the staff card on ticket id. game: a row of the game's own list, read without the server part.
function TC.openStaff(win, st, id, game)
    local t = ts(st)
    D.setField(win, "answer", "")
    D.setField(win, "note", "")
    local card = { kind = "staff", id = id, game = game, from = t.prefix .. "t:" .. tostring(id) }
    D.push(win, st, card)
    if TC.qaHold then return end
    if game then
        if D.cap("AnswerTickets") then C.gameView(id) end
        return
    end
    C.openCard(id, function(a) D.loadAnswer(win, st, card, a) end)
end

--- Off the card on top: back to the card under it (card.parent) or the tab's list, the controller on card.from.
function TC.back(win, st)
    local t = ts(st)
    local card = st.card
    if not card then return end
    st.card = card.parent
    t.items, t.confirm, t.popup = nil, nil, nil
    t.itemsKey = nil
    local K = TC.kinds[card.kind]
    if K and K.back then K.back(win, st, t, card) end
    if card.kind == "staff" then
        t.queueKey = nil
        if not card.game and not TC.qaHold then
            C.closeCard()
            if D.link() == "on" then C.setQueue(D.qArgs(t)) end
        end
    else
        t.mineKey = nil
    end
    -- back onto a ticket that another took the one staff card from: this client and the server hold one each, so it is
    -- asked for again. What it held stays on screen until the answer
    local under = st.card
    if under and under.kind == "staff" and not under.game and not TC.qaHold and not (C.card and C.card.id == under.id) then
        under.again = true
        C.openCard(under.id, function(a) D.loadAnswer(win, st, under, a) end)
    end
    D.focusId(win, st, card.from)
end

-- a command sent from a card: its buttons wait, the answer goes in the help line, typed words stay on a refusal
function D.act(win, st, send, okText, after)
    local t = ts(st)
    local card = st.card
    t.busy = true
    send(function(a)
        t.busy = nil
        if a.ok == false then
            D.flash(t, C.errText(a.err, a.left))
            if a.err == "gone" and st.card == card then TC.back(win, st) end
            return
        end
        if okText then D.flash(t, okText) end
        -- (a late answer acts on the card that sent it, never on one opened since)
        if after and st.card == card then after(a) end
    end)
end

-- ---------------------------------------------------------------------------
-- WHAT EACH CARD HOLDS. Built once per change; words wrapped once per width.
-- ---------------------------------------------------------------------------
--- The builders: each adds one item to a card's list. label: a heading, right a hint at its right. sub: dim words,
--- wrapped. msg: a message, who above the words; tone "staff", "note" or "plain". fact: a label and its value, c an
--- inline control. field: a text field at least rows lines tall; land: the controller lands on it; max: its most
--- characters.
function B.label(items, text, right) items[#items + 1] = { k = "label", text = text, right = right } end
function B.sub(items, text) items[#items + 1] = { k = "sub", text = text } end
function B.msg(items, who, text, tone)
    local n = #items + 1
    items[n] = { k = "msg", who = who, text = text, tone = tone, stop = "tk:m:" .. tostring(n) }
end
function B.fact(items, label, value, c) items[#items + 1] = { k = "fact", label = label, value = value, c = c } end
function B.field(items, key, rows, hint, land, max)
    items[#items + 1] = { k = "field", key = key, rows = rows, hint = hint, max = max,
        c = { id = "f:" .. key, land = land, run = function(ww) D.useField(ww, key) end } }
end

-- a report from chat on a card. Every word is what the reporter's client held: the server hears no chat
function B.reportChat(items, rep)
    if not rep or (rep.n or 0) == 0 then return end
    B.label(items, tr(rep.letter and "UI_ZeD_Tk_ReportedLetter" or "UI_ZeD_Tk_ChatAround"))
    for i = 1, rep.n do
        local l = rep[i]
        if l then
            local head = (l.t and l.t ~= "") and (l.t .. " ") or ""
            local who = (l.who and l.who ~= "") and (l.who .. ": ") or ""
            items[#items + 1] = { k = "chatline", text = head .. who .. tostring(l.text), mark = l.mark, c = { id = "chat:" .. tostring(i) } }
        end
    end
    B.sub(items, tr(rep.letter and "UI_ZeD_Tk_LetterWhose" or "UI_ZeD_Tk_ChatWhose"))   -- (a letter: the server did carry it)
end

function B.ask(st, t)
    local items = {}
    local ask = t.ask
    if ask.report then B.fact(items, tr("UI_ZeD_Tk_FactReported"), ask.report.who) end
    B.label(items, tr("UI_ZeD_Tk_AskAbout"))
    local chips = {}
    for i, k in ipairs(Tk.KINDS) do
        chips[i] = { id = "k:" .. k, text = tr(KIND_WORD[k]), on = ask.kind == k, land = i == 1, help = tr(KIND_HELP[k]),
            run = function()
                ask.kind = k
                if k == "GRIEF" or k == "STUCK" then ask.here = true end
            end }
    end
    items[#items + 1] = { k = "chips", ctls = chips }
    B.sub(items, ask.kind and tr(KIND_HELP[ask.kind]) or tr("UI_ZeD_Tk_AskPick"))
    B.label(items, tr("UI_ZeD_Tk_AskWhere"))
    local sub = tr("UI_ZeD_Tk_HereOff")
    if ask.here then
        local p = getPlayer()
        sub = tr("UI_ZeD_Tk_HereOn", p and (tostring(math.floor(p:getX())) .. " x " .. tostring(math.floor(p:getY()))) or "")
    end
    items[#items + 1] = { k = "check", text = tr("UI_ZeD_Tk_Here"), sub = sub,
        c = { id = "here", on = ask.here, run = function() ask.here = not ask.here end } }
    B.label(items, tr("UI_ZeD_Tk_AskWhat"))
    B.field(items, "ask", 6, tr("UI_ZeD_Tk_AskHint"))
    items[#items].seed = ask.seed
    B.reportChat(items, ask.report)
    return items
end

-- the thread; each line says who, and whether staff or the game's window wrote it
function B.thread(items, th)
    for i = 1, (th and (th.n or #th) or 0) do
        local e = th[i]
        if e then
            local who = tostring(e.who)
            if e.staff then who = tr("UI_ZeD_Tk_ByAdmin", who)
            elseif e.game then who = tr("UI_ZeD_Tk_ByGame", who) end
            B.msg(items, who, e.text, e.staff and "staff" or "plain")
        end
    end
end

-- a push closed the field being typed in: the words stay on the card, and the foot says why
function B.unsent(items, win, key)
    local text = Tk.clean(D.fieldText(win, key)) or ""
    if text ~= "" then B.msg(items, tr("UI_ZeD_Tk_NotSent"), text, "plain") end
end

function B.mine(win, card, data)
    local items = {}
    if not data then
        B.sub(items, tr("UI_ZeD_Tk_Loading"))
        return items
    end
    local sent = {}
    if data.day then sent[#sent + 1] = D.day(data.day) end
    local real = D.realDate(data.filed)
    if real then sent[#sent + 1] = real end
    B.fact(items, tr("UI_ZeD_Tk_FactSent"), (#sent > 0) and table.concat(sent, ", ") or tr("UI_ZeD_Tk_NotRecorded"))
    B.fact(items, tr("UI_ZeD_Tk_FactWhere"), Tk.whereFull(data.place) or tr("UI_ZeD_Tk_NotIncluded"))
    if data.report then B.fact(items, tr("UI_ZeD_Tk_FactReported"), tostring(data.report.who)) end
    B.thread(items, data.thread)
    B.reportChat(items, data.report)
    if card.game then
        B.sub(items, tr("UI_ZeD_Tk_OneAnswer"))
    elseif data.can then
        B.label(items, tr("UI_ZeD_Tk_AddTo"))
        B.field(items, "reply", 3, tr("UI_ZeD_Tk_AddHint"), true)
    else
        B.sub(items, tr((data.st == "Answered") and "UI_ZeD_Tk_DoneAnswered" or "UI_ZeD_Tk_DoneClosed"))
        B.unsent(items, win, "reply")
    end
    return items
end

function B.staffFacts(items, st, data)
    B.fact(items, tr("UI_ZeD_Tk_FactPlayer"), tostring(data.author), { id = "pcard", text = tr("UI_ZeD_Tk_PlayerCard"),
        help = tr("UI_ZeD_Tk_HelpPlayerCard"), live = D.livePlayerCard, author = data.author,
        run = function(ww) D.playerCard(ww, data.author) end })
    local when = nil
    if data.day then
        when = D.day(data.day)
        local real = D.realDate(data.filed)
        if real then when = when .. " | " .. real end
    end
    B.fact(items, tr("UI_ZeD_Tk_FactWhen"), when or tr("UI_ZeD_Tk_FromGame"))
    if data.place then
        B.fact(items, tr("UI_ZeD_Tk_FactWhere"), Tk.whereFull(data.place), { id = "go", text = tr("UI_ZeD_Tk_GoThere"),
            help = tr("UI_ZeD_Tk_HelpGo"), live = D.liveGo, run = function() D.goThere(st, data.place) end })
        local near = {}
        for i = 1, (data.near and data.near.n or 0) do near[i] = tostring(data.near[i]) end
        B.fact(items, tr("UI_ZeD_Tk_FactNear"), (#near > 0) and table.concat(near, ", ") or tr("UI_ZeD_Tk_NobodyNear", Tk.NEAR))
    else
        B.fact(items, tr("UI_ZeD_Tk_FactWhere"), tr("UI_ZeD_Tk_NotIncluded"))
        B.fact(items, tr("UI_ZeD_Tk_FactNear"), tr("UI_ZeD_Tk_NotRecorded"))
    end
    if data.gameGone then B.fact(items, tr("UI_ZeD_Tk_FactGame"), tr("UI_ZeD_Tk_RemovedGame")) end
    if data.report then
        local who = tostring(data.report.who)
        B.fact(items, tr("UI_ZeD_Tk_FactReported"), who, { id = "pcard2", text = tr("UI_ZeD_Tk_PlayerCard"),
            help = tr("UI_ZeD_Tk_HelpPlayerCard"), live = D.livePlayerCard, author = who,
            run = function(ww) D.playerCard(ww, who) end })
    end
    if ZeD.LogCards then ZeD.LogCards.aroundFact(items, st, data) end
end

function B.staff(win, st, card, data)
    local items = {}
    if not data then
        B.sub(items, tr("UI_ZeD_Tk_Loading"))
        return items
    end
    B.staffFacts(items, st, data)
    if data.source == "game" and not card.game then B.sub(items, tr("UI_ZeD_Tk_HelpGameCard")) end
    B.thread(items, data.thread)
    B.reportChat(items, data.report)
    local notes = data.notes
    for i = 1, (notes and (notes.n or #notes) or 0) do
        local e = notes[i]
        if e then
            B.msg(items, tr(e.game and "UI_ZeD_Tk_NoteGame" or "UI_ZeD_Tk_NoteBy", tostring(e.who), tostring(data.author)), e.text, "note")
        end
    end
    local author = tostring(data.author)
    if card.game then
        B.sub(items, tr("UI_ZeD_Tk_HelpFallback"))
        if data.st == "Answered" then
            B.sub(items, tr("UI_ZeD_Tk_OneAnswer"))
        else
            B.label(items, tr("UI_ZeD_Tk_AnswerTo", author))
            B.field(items, "answer", 3, tr("UI_ZeD_Tk_AnswerHint", author), true)
        end
        return items
    end
    if Tk.canAnswer(data.status) then
        B.label(items, tr("UI_ZeD_Tk_AnswerTo", author))
        B.field(items, "answer", 3, tr("UI_ZeD_Tk_AnswerHint", author), true)
    else
        B.unsent(items, win, "answer")
    end
    B.label(items, tr("UI_ZeD_Tk_AdminNote"))
    B.field(items, "note", 2, tr("UI_ZeD_Tk_NoteHint"))
    items[#items + 1] = { k = "btn", c = { id = "addnote", text = tr("UI_ZeD_Tk_AddNote"), help = tr("UI_ZeD_Tk_HelpAddNote"),
        live = D.liveAddNote, win = win, tk = ts(st), run = function(ww) D.addNote(ww, st, card.id) end } }
    return items
end

-- the data behind a card, or nil
function D.cardData(card)
    local K = TC.kinds[card.kind]
    if K then return K.data(card) end
    if card.kind == "mine" then
        if card.game then
            for _, r in ipairs(C.mine or {}) do
                if r.id == card.id and r.game then
                    local th = { n = 1, { who = D.me(), text = r.text or r.last } }
                    if r.ansText then
                        th.n = 2
                        th[2] = { who = r.ansWho, text = r.ansText, staff = not r.claim, game = r.claim }
                    end
                    return { id = r.id, kind = r.kind, st = r.st, thread = th, can = false }
                end
            end
            return nil
        end
        return C.one[card.id]
    elseif card.kind == "staff" then
        if card.game then
            local r = C.fallbackRow(card.id)
            if not r then return nil end
            local th = { n = 1, { who = r.author, text = r.text } }
            if r.ansText then
                th.n = 2
                th[2] = { who = r.ansWho, text = r.ansText, staff = not r.claim, game = r.claim }
            end
            return { id = r.id, kind = r.kind, author = r.author, status = r.st, st = r.st, thread = th, notes = { n = 0 }, source = "game" }
        end
        if C.card and C.card.id == card.id then
            card.held, card.again = C.card, nil
            return C.card
        end
        return card.again and card.held or nil
    end
    return true
end

function D.cardItems(win, st, t, card, data)
    local K = TC.kinds[card.kind]
    if K then return K.items(win, st, t, card, data) end
    if card.kind == "ask" then return B.ask(st, t) end
    if card.kind == "mine" then return B.mine(win, card, data) end
    return B.staff(win, st, card, data)
end

-- ---------------------------------------------------------------------------
-- ACTIONS ON A CARD
-- ---------------------------------------------------------------------------
function D.send(win, st)
    local t = ts(st)
    local ask = t.ask
    local card = st.card
    t.busy = true
    local r = C.ask(ask.kind, ask.here, D.fieldText(win, "ask"), function(a)
        t.busy = nil
        if a.ok == false then
            D.flash(t, C.errText(a.err, a.left))
            return
        end
        D.flash(t, a.fallback and tr("UI_ZeD_Tk_SentGame") or tr("UI_ZeD_Tk_Sent", a.id))
        -- (Cancel stays live while it goes: a late answer closes this card, never one opened since)
        if st.card == card then
            D.setField(win, "ask", "")
            TC.back(win, st)
        end
    end, ask.report)
    if r ~= "sent" then
        t.busy = nil
        D.flash(t, (r == "wait") and tr("UI_ZeD_Tk_LinkWait") or C.errText("text"))
    end
end

function D.reply(win, st, id)
    D.act(win, st, function(cb) C.reply(id, D.fieldText(win, "reply"), cb) end, tr("UI_ZeD_Tk_Added"), function()
        D.setField(win, "reply", "")
    end)
end

function D.answer(win, st, card)
    local text = D.fieldText(win, "answer")
    if card.game then
        C.gameAnswer(card.id, text)
        D.setField(win, "answer", "")
        D.flash(ts(st), tr("UI_ZeD_Tk_AnsweredGame"))
        D.focusId(win, st, "tk:del")
        return
    end
    local data = D.cardData(card)
    D.act(win, st, function(cb) C.answer(card.id, text, cb) end, tr("UI_ZeD_Tk_Answered", tostring(data and data.author)), function()
        D.setField(win, "answer", "")
        D.focusNext(win, st, function(e) return e.id == "tk:reopen" or e.id == "tk:f:answer" end)
    end)
end

function D.addNote(win, st, id)
    D.act(win, st, function(cb) C.addNote(id, D.fieldText(win, "note"), cb) end, tr("UI_ZeD_Tk_NoteAdded"), function()
        D.setField(win, "note", "")
    end)
end

function D.delete(win, st, card)
    local t = ts(st)
    t.confirm = nil
    if card.game then
        C.gameRemove(card.id)
        D.flash(t, tr("UI_ZeD_Tk_Deleted"))
        TC.back(win, st)
        return
    end
    D.act(win, st, function(cb) C.delete(card.id, cb) end, tr("UI_ZeD_Tk_Deleted"), function() TC.back(win, st) end)
end

--- Go to a ticket's place (the game's /teleportto), and say so in the card's line.
function D.goThere(st, place)
    if not (place and place.x and place.y) then return end
    SendCommandToServer("/teleportto " .. tostring(place.x) .. "," .. tostring(place.y) .. "," .. tostring(place.z or 0))
    D.flash(ts(st), tr("UI_ZeD_Tk_Going", Tk.whereText(place) or ""))
end

--- The Player card (ZeD_AdminCards.lua) over an open card while the server part holds the admin tools; otherwise
--- the player's stats (D.statsWindow).
function D.playerCard(win, author)
    if ZeD.AdminCards and ZeD.Admin.live() and win._tkSt and win._tkSt.card then
        ZeD.AdminCards.openFromTicket(win, win._tkSt, author)
        return
    end
    D.statsWindow(win, author)
end

-- the player's stats: ZeD's stats card (ZeD_StatsCards.lua) over a card in the Admin tab, or the Admin tab opened on it from
-- anywhere else; the game's own window only when that tab can't show (no admin tool, the window away)
function D.statsWindow(win, author)
    local SC = ZeD.StatsCards
    local ast = win and win._adminTab
    if SC and ast and ast.card then
        SC.openStats(win, ast, author, "tk:pcard")
        return
    end
    if SC and ZeD.AdminTab and ZeD.AdminTab.openNext and ZeD.AdminTab.openNext({ kind = "pstats", user = author }, win and win.playerNum) then return end
    local who = getPlayerFromUsername(author)
    local p = win._playerObj or getPlayer()
    if not (who and p) then return end
    if ISPlayerStatsUI.instance then pcall(function() ISPlayerStatsUI.instance:close() end) end
    local ui = ISPlayerStatsUI:new(50, 50, 800 + getCore():getOptionFontSizeReal() * 50, 800, who, p)
    ui:initialise()
    ui:addToUIManager()
end

function D.canGo()
    if TC.qaGo ~= nil then return TC.qaGo end
    return D.cap("TeleportToCoordinates")
end

--- Read as Go there draws: grayed, with the reason, without the teleport power.
function D.liveGo(c)
    local can = D.canGo()
    c.disabled = not can
    c.why = (not can) and tr("UI_ZeD_Tk_NoGo") or nil
end

--- Read as Player card draws: grayed, with the reason, without the stats power; and, while the server part holds no
--- admin tools, when the player isn't near this client.
function D.livePlayerCard(c)
    local why = nil
    if ZeD.AdminCards and ZeD.Admin.live() and TC.qaStats == nil then
        if not D.cap("CanSeePlayersStats") then why = tr("UI_ZeD_Tk_NoStats") end
    elseif TC.qaStats ~= nil then
        if not TC.qaStats then why = tr("UI_ZeD_Tk_NoStats") end
    elseif not D.cap("CanSeePlayersStats") then why = tr("UI_ZeD_Tk_NoStats")
    elseif not getPlayerFromUsername(c.author) then why = tr(D.onServer(c.author) and "UI_ZeD_Adm_NotSeen" or "UI_ZeD_Tk_NotOnline") end
    c.disabled, c.why = why ~= nil, why
end

-- a client knows only the players near it: the scoreboard says who is on the server at all
function D.onServer(author)
    local S2 = ZeD.ServerTab
    if not S2 then return false end
    if S2.askPlayers then S2.askPlayers() end
    for _, pl in ipairs(S2.players or {}) do
        if pl.user == author then return true end
    end
    return false
end

function D.liveAddNote(c)
    local _, frozen = D.link()
    local empty = (Tk.clean(D.fieldText(c.win, "note")) or "") == ""
    local why = (frozen and C.errText("frozen")) or (c.tk.busy and tr("UI_ZeD_Tk_Busy")) or (empty and tr("UI_ZeD_Tk_WriteNote")) or nil
    c.disabled, c.why = why ~= nil, why
end

-- ---------------------------------------------------------------------------
-- THE FOOT: the card's own band. lead at the left (Delete, Spam), the answers at the right, the main one last.
-- ---------------------------------------------------------------------------
--- A foot button: its stop id, its word, run(win), variant ("primary", "danger" or nil) and help words.
function D.btn(id, text, run, variant, help)
    return { id = id, label = text, run = run, variant = variant, help = help }
end

--- Gray a button with the reason it is gray; returns it.
function D.disable(b, why)
    b.disabled, b.why = true, why
    return b
end

-- the words for a field a push took away while it held text
function D.fieldGone(win, key)
    if (Tk.clean(D.fieldText(win, key)) or "") == "" then return nil end
    return tr("UI_ZeD_Tk_FieldGone")
end

function D.footAsk(win, st, t)
    local ask = t.ask
    local text = Tk.clean(D.fieldText(win, "ask")) or ""
    local send = D.btn("send", tr("UI_ZeD_Tk_Send"), function(ww) D.send(ww, st) end, "primary", tr("UI_ZeD_Tk_HelpSend"))
    local status
    if not ask.kind then
        status = tr("UI_ZeD_Tk_AskPickShort")
        D.disable(send, status)
    elseif text == "" then
        status = tr("UI_ZeD_Tk_AskWrite")
        D.disable(send, status)
    elseif D.link() == "wait" then
        status = tr("UI_ZeD_Tk_LinkWait")
        D.disable(send, status)
    else
        local clock = D.clock(getTimestamp()) or ""
        local dayN = math.floor(getGameTime():getWorldAgeHours() / 24) + 1
        status = tr(DATE_SAYS_UTC and "UI_ZeD_Tk_GoesWithUtc" or "UI_ZeD_Tk_GoesWith", D.day(dayN), clock)
    end
    if t.busy then D.disable(send, tr("UI_ZeD_Tk_Busy")) end
    return { status = status, main = {
        D.btn("cancel", getText("UI_Cancel"), function(ww) TC.back(ww, st) end, nil, tr("UI_ZeD_Tk_HelpCancelAsk")), send } }
end

function D.footMine(win, st, t, card, data)
    if not data or card.game or not data.can then
        return { main = {}, status = (data and not card.game) and D.fieldGone(win, "reply") or nil }
    end
    local send = D.btn("psend", tr("UI_ZeD_Tk_Send"), function(ww) D.reply(ww, st, card.id) end, "primary", tr("UI_ZeD_Tk_HelpReply"))
    local _, frozen = D.link()
    if frozen then D.disable(send, C.errText("frozen"))
    elseif (Tk.clean(D.fieldText(win, "reply")) or "") == "" then D.disable(send, tr("UI_ZeD_Tk_WriteReply"))
    elseif t.busy then D.disable(send, tr("UI_ZeD_Tk_Busy")) end
    return { main = { send } }
end

function D.answerBtn(win, st, card)
    local ans = D.btn("ans", tr("UI_ZeD_Tk_Answer"), function(ww) D.answer(ww, st, card) end, "primary", tr("UI_ZeD_Tk_HelpAnswer"))
    if (Tk.clean(D.fieldText(win, "answer")) or "") == "" then D.disable(ans, tr("UI_ZeD_Tk_WriteAnswer")) end
    return ans
end

-- Take it, Close or Reopen, Answer
function D.footOpen(win, st, card, data, foot)
    local id = card.id
    if Tk.isOpen(data.status) and data.assignee ~= D.me() then
        foot.main[1] = D.btn("take", tr("UI_ZeD_Tk_Take"), function(ww)
            D.act(ww, st, function(cb) C.take(id, cb) end, tr("UI_ZeD_Tk_Taken"), function() D.focusId(ww, st, "tk:f:answer") end)
        end, nil, tr("UI_ZeD_Tk_HelpTake"))
    end
    if Tk.canClose(data.status) then
        foot.main[#foot.main + 1] = D.btn("close", tr("UI_ZeD_Tk_Close"), function(ww)
            D.act(ww, st, function(cb) C.close(id, cb) end, tr("UI_ZeD_Tk_ClosedDone"), function() D.focusId(ww, st, "tk:reopen") end)
        end, nil, tr("UI_ZeD_Tk_HelpClose"))
    else
        foot.main[#foot.main + 1] = D.btn("reopen", tr("UI_ZeD_Tk_Reopen"), function(ww)
            D.act(ww, st, function(cb) C.reopen(id, cb) end, tr("UI_ZeD_Tk_ReopenDone"), function() D.focusId(ww, st, "tk:f:answer") end)
        end, nil, tr("UI_ZeD_Tk_HelpReopen"))
    end
    if Tk.canAnswer(data.status) then foot.main[#foot.main + 1] = D.answerBtn(win, st, card) end
end

function D.footStaff(win, st, t, card, data)
    if not data then return { main = {} } end
    local id = card.id
    local admin = D.isAdmin()
    if t.confirm then
        local keep = D.btn("nodel", tr("UI_ZeD_Tk_KeepIt"), function(ww)
            t.confirm = nil
            D.focusId(ww, st, "tk:del")
        end, nil, tr("UI_ZeD_Tk_HelpKeep"))
        return { question = tr("UI_ZeD_Tk_DeleteAsk", id), main = { keep,
            D.btn("yesdel", tr("UI_ZeD_Tk_DeleteGood"), function(ww) D.delete(ww, st, card) end, "danger", tr("UI_ZeD_Tk_HelpDeleteGood")) } }
    end
    local del = D.btn("del", tr("UI_ZeD_Tk_Delete"), function(ww)
        t.confirm = true
        D.focusId(ww, st, "tk:nodel")
    end, "danger", tr("UI_ZeD_Tk_HelpDelete"))
    if card.game then
        local foot = { lead = { del }, main = {} }
        if data.st ~= "Answered" then foot.main[1] = D.answerBtn(win, st, card) end
        return foot
    end
    local foot
    if data.status == "Spam" then
        local unspam = D.btn("unspam", tr("UI_ZeD_Tk_NotSpam"), function(ww)
            D.act(ww, st, function(cb) C.unspam(id, cb) end, tr("UI_ZeD_Tk_NotSpamDone"), function() D.focusId(ww, st, "tk:spam") end)
        end, nil, tr("UI_ZeD_Tk_HelpNotSpam"))
        foot = { lead = admin and { del } or {}, main = { unspam }, status = (not admin) and tr("UI_ZeD_Tk_OnlyAdmin") or nil }
    else
        local spam = D.btn("spam", tr("UI_ZeD_Tk_Spam"), function(ww)
            D.act(ww, st, function(cb) C.spam(id, cb) end, tr(admin and "UI_ZeD_Tk_SpamDoneAdmin" or "UI_ZeD_Tk_SpamDoneMod"),
                function() TC.back(ww, st) end)
        end, nil, tr("UI_ZeD_Tk_HelpSpam"))
        foot = { lead = {}, main = {} }
        if admin then foot.lead[1] = del end
        foot.lead[#foot.lead + 1] = spam
        D.footOpen(win, st, card, data, foot)
    end
    -- a frozen server part reads and refuses every write: said on each button. So is a command on its way.
    local _, frozen = D.link()
    local why = (frozen and C.errText("frozen")) or (t.busy and tr("UI_ZeD_Tk_Busy")) or nil
    if why then
        for _, b in ipairs(foot.lead) do D.disable(b, why) end
        for _, b in ipairs(foot.main) do D.disable(b, why) end
    end
    if not foot.status and not Tk.canAnswer(data.status) then foot.status = D.fieldGone(win, "answer") end
    return foot
end

function D.footOf(win, st, t, card, data)
    local K = TC.kinds[card.kind]
    if K then return K.foot and K.foot(win, st, t, card, data) or { main = {} } end
    if card.kind == "ask" then return D.footAsk(win, st, t) end
    if card.kind == "mine" then return D.footMine(win, st, t, card, data) end
    return D.footStaff(win, st, t, card, data)
end

-- the foot's height; two bands when lead and answers will not fit on one line
function D.footH(foot, w)
    local M = ZeD.Molecules
    local lead, main = foot.lead or {}, foot.main or {}
    if #main == 0 and #lead == 0 and not foot.status and not foot.question then return 0, false end
    local need = 2 * px(8)
    for _, b in ipairs(lead) do need = need + M.buttonW(b.label) + px(8) end
    for _, b in ipairs(main) do need = need + M.buttonW(b.label) + px(8) end
    if foot.question then need = need + px(12) + ZeD.TM:MeasureStringX(ZeD.T.fontF2, foot.question) end
    if need > w and (foot.question or (#lead > 0 and #main > 0)) then return 2 * M.bandH(), true end
    return M.bandH(), false
end

-- the band's line: the reason a grayed control is gray and the answer to a press under the controller, where the help
-- line holds the prompts; otherwise the foot's own line
function D.footWords(win, t, foot)
    if foot.line then return foot.line end
    if foot.question then return nil end
    if D.padOn() then
        local s = D.flashNow(t)
        if s then return s end
        local Fo = ZeD.Input and ZeD.Input.Focus
        local el = Fo and Fo.getFocusedElement and Fo.getFocusedElement(win)
        if el and el.tkWhy then
            local why = el.tkWhy()
            if why then return why end
        end
    end
    return foot.status
end

-- With the controller the words get a line of their own above the bands: a grayed control's reason and the answer to a
-- press are read here, and between a card's buttons they would be cut to a word. The line is kept while the card has a
-- foot, or the card would jump as focus moves. Returns its height and lines. foot.line: a question too long for the band,
-- on this line with mouse or pad.
function D.footLine(foot, w, words, bandsH)
    if (not D.padOn() and not foot.line) or foot.question or (bandsH == 0 and not words) then return 0, nil end
    local T = ZeD.T
    local lines = words and D.wrap(words, T.fontF2, math.max(1, w - 2 * px(8))) or {}
    return math.max(1, #lines) * ZeD.TM:getFontHeight(T.fontF2) + px(8), lines
end

function D.drawFootLine(panel, x, y, w, h, lines, tone)
    local T, A = ZeD.T, ZeD.Atoms
    A.surfaceFill(panel, x, y, w, h, "surf2")
    A.drawDividerH(panel, x, y, w, true)
    local c = (tone and T[tone]) or T.text
    for i, s in ipairs(lines) do
        panel:drawText(s, x + px(8), y + px(4) + (i - 1) * ZeD.TM:getFontHeight(T.fontF2), c.r, c.g, c.b, c.a or 1, T.fontF2)
    end
end

function D.bandSpec(win, list)
    local out = {}
    for i, b in ipairs(list or {}) do
        local f = D.focusOf(win, "tk:" .. b.id)
        out[i] = { label = b.label, variant = b.variant, disabled = b.disabled, help = b.why or b.help, id = b.id,
            focus = f and { win = win, focused = f.focused, pad = f.pad } or nil }
    end
    return out
end

function D.drawFoot(panel, win, t, foot, x, y, w, two, words, noLine)
    local M = ZeD.Molecules
    local rects = {}
    local function keep(out, list, field)
        for i, r in ipairs(out[field] or {}) do
            if list[i] then rects[#rects + 1] = { x = r.x, y = r.y, w = r.w, h = r.h, b = list[i] } end
        end
    end
    local lead, main = foot.lead or {}, foot.main or {}
    if two then
        local _, o1 = M.drawBand(panel, x, y, w, { lead = D.bandSpec(win, lead), question = foot.question, win = win, noLine = noLine })
        keep(o1, lead, "lead")
        local _, o2 = M.drawBand(panel, x, y + M.bandH(), w,
            { buttons = D.bandSpec(win, main), status = words and { text = words } or nil, win = win, noLine = true })
        keep(o2, main, "buttons")
    else
        local spec = { lead = D.bandSpec(win, lead), buttons = D.bandSpec(win, main), win = win, noLine = noLine }
        if foot.question then spec.question = foot.question
        elseif words then spec.status = { text = words } end
        local _, o = M.drawBand(panel, x, y, w, spec)
        keep(o, lead, "lead")
        keep(o, main, "buttons")
    end
    t.footRects = rects
end

-- ---------------------------------------------------------------------------
-- A CARD'S LAYOUT
-- ---------------------------------------------------------------------------
function D.factLabelW(items)
    local w = 0
    for _, it in ipairs(items) do
        if it.k == "fact" then w = math.max(w, ZeD.TM:MeasureStringX(ZeD.T.fontF1, it.label)) end
    end
    return w
end

function D.layout(win, items, wAll, sh)
    local T, A, M, tm = ZeD.T, ZeD.Atoms, ZeD.Molecules, ZeD.TM
    local f2h, f3h, f1h = tm:getFontHeight(T.fontF2), tm:getFontHeight(T.fontF3), tm:getFontHeight(T.fontF1)
    local y = px(10)
    local lw = D.factLabelW(items)
    local last = nil
    local top = nil      -- the inset being measured
    for _, it in ipairs(items) do
        local k = it.k
        local w = it.ind and (wAll - 2 * px(it.ind)) or wAll
        local ext = TC.items[k]
        if ext then
            y = y + px(ext.gap or 0)
            it.h = ext.layout(win, it, w, sh)
        elseif k == "insetTop" then
            y = y + px(8)
            it.h = px(8)
            top = it
        elseif k == "insetEnd" then
            it.h = px(8)
        elseif k == "label" then
            if last and last ~= "label" then y = y + px(12) end
            if it.wrapW ~= w then it.wrapW, it.lines = w, D.wrap(it.text, T.fontF1, math.max(1, w)) end
            -- the hint (a count, a short note) sits at the right of the heading's first line when both fit with a gap;
            -- when they don't (a long heading in some language), it goes on its own lines under the heading instead
            local right = it.right or (it.rightFn and it.rightFn())
            it.below = nil
            if right and right ~= "" then
                local head = it.lines[1] or ""
                local headW = tm:MeasureStringX(T.fontF1, head)
                -- once a hint has gone under, it stays there while the width and heading stay the same: a typing
                -- counter ("9/30" to "10/30") would otherwise hop up and down, moving the field under it as the player types
                local stuck = it.stuckW == w and it.stuckHead == head
                if stuck or headW + px(8) + tm:MeasureStringX(T.fontF3, right) > w then
                    it.stuckW, it.stuckHead = w, head
                    -- (wrapped again only when the hint or the width changed)
                    if it.belowText ~= right or it.belowW ~= w then
                        it.belowText, it.belowW, it.belowLines = right, w, D.wrap(right, T.fontF3, math.max(1, w))
                    end
                    it.below = it.belowLines
                end
            end
            it.h = #it.lines * f1h + (it.below and #it.below * f3h or 0) + px(6)
        elseif k == "sub" then
            y = y + px(4)
            if it.liveText then
                local s = it.liveText() or ""
                if s ~= it.text then it.text, it.wrapW = s, nil end
            end
            if it.wrapW ~= w then it.wrapW, it.lines = w, D.wrap(it.text, T.fontF2, math.max(1, w)) end
            it.h = #it.lines * f2h
        elseif k == "chips" then
            it.h = D.flow(it.ctls, w, 0)
        elseif k == "check" then
            y = y + px(it.top or 0)
            local cb = T.checkboxSz or px(12)
            if it.wrapW ~= w then
                it.wrapW, it.lines = w, A.wrapText(it.sub, T.fontF2, math.max(1, w - cb - px(8)))
                it.heads = D.wrap(it.text, T.fontF2, math.max(1, w - cb - px(8)))
            end
            it.h = math.max(cb, #it.heads * f2h) + #it.lines * f2h + px(4)
        elseif k == "field" then
            it.h = D.fieldH(win, it, w, sh)
        elseif k == "fact" then
            local btnW = 0
            if it.c then
                it.c.w, it.c.h = M.buttonW(it.c.text), T.buttonH - px(4)
                if it.c.box then it.c.w = M.popupMenuW(it.c.text, true) end
                btnW = it.c.w + px(8)
            end
            local vw = math.max(px(40), w - lw - px(FACT_GAP) - btnW)
            if it.wrapW ~= vw then it.wrapW, it.lines = vw, D.wrap(it.value, T.fontF2, vw) end
            it.lw = lw
            it.h = math.max(#it.lines * f2h, it.c and it.c.h or 0) + px(3)
        elseif k == "msg" then
            y = y + px(8)
            local mw = w - px(18)
            if it.wrapW ~= mw then it.wrapW, it.lines = mw, D.wrap(it.text, T.fontF2, math.max(1, mw)) end
            it.h = f3h + px(3) + #it.lines * f2h + px(14)
        elseif k == "btn" then
            y = y + px(6)
            it.c.w, it.c.h = M.buttonW(it.c.text), T.buttonH
            it.h = T.buttonH
        end
        it.y = y
        y = y + it.h
        if k == "insetEnd" and top then
            top.spanH = y - top.y
            top = nil
        end
        last = k
    end
    return y + px(14)
end

--- Draw a card's inline control at (x, y): a button, or a pop-up box when c.box. c.live, if any, runs first to gray it.
function D.drawInline(panel, win, t, c, x, y, mx, my)
    local M = ZeD.Molecules
    if c.live then c.live(c) end
    local hov = mx ~= nil and mx >= x and mx < x + c.w and my >= y and my < y + c.h
    if c.box then
        M.drawPopupMenu(panel, x, y, c.w, c.h, c.text, hov, D.focusOf(win, "tk:" .. c.id), c.disabled, nil, true)
        c.bx, c.by = x, y
        if hov and (c.why or c.help) then ZeD.Help.set(win, c.why or c.help) end
    else
        M.drawButton(panel, x, y, c.w, c.h, c.text, c.variant or "default", hov and isMouseButtonDown(0), nil,
            { hover = hov, disabled = c.disabled, help = c.why or c.help, win = win, focus = D.focusOf(win, "tk:" .. c.id) })
    end
    c.sx = x
    t.hits[#t.hits + 1] = { x = x, y = y, w = c.w, h = c.h, c = c }
end

function D.drawCheckItem(panel, win, t, it, x, dy, w, mx, my)
    local T, A = ZeD.T, ZeD.Atoms
    local c = it.c
    local f2h = ZeD.TM:getFontHeight(T.fontF2)
    local cb = T.checkboxSz or px(12)
    local hov = mx ~= nil and mx >= x and mx < x + w and my >= dy and my < dy + it.h
    local onF = D.mark(panel, x, dy, w, it.h, D.focusOf(win, "tk:" .. c.id))
    A.drawCheckbox(panel, x, dy + px(1), c.on and true or false, hov, c.disabled)
    if hov and (c.why or c.help) then ZeD.Help.set(win, c.why or c.help) end
    local tc = onF and T.textOnFocus or T.text
    local tx = x + cb + px(8)
    for i, s in ipairs(it.heads or {}) do
        panel:drawText(s, tx, dy + (i - 1) * f2h, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
    end
    local sc = onF and T.textOnFocus or T.textDim
    local y2 = dy + math.max(cb, #(it.heads or {}) * f2h) + px(2)
    for i, s in ipairs(it.lines or {}) do
        panel:drawText(s, tx, y2 + (i - 1) * f2h, sc.r, sc.g, sc.b, sc.a or 1, T.fontF2)
    end
    t.hits[#t.hits + 1] = { x = x, y = dy, w = w, h = it.h, c = c }
end

function D.drawMsg(panel, win, it, x, dy, w)
    local T = ZeD.T
    local f2h = ZeD.TM:getFontHeight(T.fontF2)
    local tone = it.tone
    local bg = T.surf1
    panel:drawRect(x, dy, w, it.h, bg.a or 1, bg.r, bg.g, bg.b)
    D.mark(panel, x, dy, w, it.h, D.focusOf(win, it.stop))
    local bar = (tone == "staff" and T.accent) or (tone == "note" and T.warning) or T.borderS
    panel:drawRect(x, dy, px(3), it.h, bar.a or 1, bar.r, bar.g, bar.b)
    local wc = (tone == "note") and T.warning or T.textDim
    panel:drawText(ZeD.Atoms.truncateText(it.who, T.fontF3, w - px(16)), x + px(10), dy + px(6), wc.r, wc.g, wc.b, wc.a or 1, T.fontF3)
    local tc = T.text
    local ty = dy + px(6) + ZeD.TM:getFontHeight(T.fontF3) + px(3)
    for i, s in ipairs(it.lines or {}) do
        panel:drawText(s, x + px(10), ty + (i - 1) * f2h, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
    end
end

function D.drawCardItem(panel, win, t, it, x, dy, w, mx, my, viewY, viewH, covered)
    local T = ZeD.T
    local k = it.k
    local f2h = ZeD.TM:getFontHeight(T.fontF2)
    if it.ind then
        x = x + px(it.ind)
        w = w - 2 * px(it.ind)
    end
    local ext = TC.items[k]
    if ext then
        ext.draw(panel, win, t, it, x, dy, w, mx, my, { hits = t.hits, prefix = "tk:", viewY = viewY, viewH = viewH, covered = covered })
    elseif k == "insetTop" then
        local bg = T.surf1
        panel:drawRect(x, dy, w, it.spanH or it.h, bg.a or 1, bg.r, bg.g, bg.b)
        ZeD.Atoms.frame(panel, x, dy, w, it.spanH or it.h, T[it.tone or "borderS"] or T.borderS)
    elseif k == "label" then
        local c = T.textHead
        for i, s in ipairs(it.lines or {}) do
            panel:drawText(s, x, dy + (i - 1) * ZeD.TM:getFontHeight(T.fontF1), c.r, c.g, c.b, c.a or 1, T.fontF1)
        end
        local right = it.right or (it.rightFn and it.rightFn())
        if it.below then
            -- the hint didn't fit beside the heading (D.layout): its lines go under it, at the left
            local f1h, f3h = ZeD.TM:getFontHeight(T.fontF1), ZeD.TM:getFontHeight(T.fontF3)
            local by = dy + #(it.lines or {}) * f1h
            local dc = T.textDim
            for i, s in ipairs(it.below) do
                panel:drawText(s, x, by + (i - 1) * f3h, dc.r, dc.g, dc.b, dc.a or 1, T.fontF3)
            end
        elseif right then
            local room = w - ZeD.TM:MeasureStringX(T.fontF1, (it.lines and it.lines[1]) or it.text) - px(8)
            ZeD.Atoms.drawTextRight(panel, ZeD.Atoms.truncateText(right, T.fontF3, math.max(0, room)), x + w, dy, T.fontF3, T.textDim)
        end
    elseif k == "sub" then
        local c = (it.tone and T[it.tone]) or T.textDim
        for i, s in ipairs(it.lines or {}) do
            panel:drawText(s, x, dy + (i - 1) * f2h, c.r, c.g, c.b, c.a or 1, T.fontF2)
        end
    elseif k == "chips" then
        for _, c in ipairs(it.ctls) do
            local cx, cy = x + c.dx, dy + c.dy
            D.drawChip(panel, win, cx, cy, c.w, c.h, c, "tk:" .. c.id, mx, my)
            t.hits[#t.hits + 1] = { x = cx, y = cy, w = c.w, h = c.h, c = c }
        end
    elseif k == "check" then
        D.drawCheckItem(panel, win, t, it, x, dy, w, mx, my)
    elseif k == "field" then
        it.c.fullId = "tk:" .. it.c.id
        D.drawField(panel, win, t, it, x, dy, w, it.h, viewY, viewH, covered)
        t.hits[#t.hits + 1] = { x = x, y = dy, w = w, h = it.h, c = it.c, field = it }
    elseif k == "fact" then
        local lc, vc = T.textHead, T.text
        panel:drawText(it.label, x, dy, lc.r, lc.g, lc.b, lc.a or 1, T.fontF1)
        local vx = x + it.lw + px(FACT_GAP)
        for i, s in ipairs(it.lines or {}) do
            panel:drawText(s, vx, dy + (i - 1) * f2h, vc.r, vc.g, vc.b, vc.a or 1, T.fontF2)
        end
        if it.c then D.drawInline(panel, win, t, it.c, it.c.box and vx or (x + w - it.c.w), dy, mx, my) end
    elseif k == "msg" then
        D.drawMsg(panel, win, it, x, dy, w)
    elseif k == "btn" then
        D.drawInline(panel, win, t, it.c, x, dy, mx, my)
    end
end

-- where the back bar goes, in words
function D.backHelp(st, card)
    if st.tkZone ~= "worldTabContent" then return tr("UI_ZeD_Tk_BackServer") end
    local from = card.parent and card.parent.kind
    if from == "roles" then return tr("UI_ZeD_Adm_BackRoles") end
    if from == "player" then return tr("UI_ZeD_Adm_BackPlayer") end
    if from == "staff" then return tr("UI_ZeD_Tk_BackTicket") end
    if from == "pstats" then return tr("UI_ZeD_St_BackStats") end
    if from == "pinv" then return tr("UI_ZeD_St_BackInv") end
    if st.screen == "tickets" then return tr("UI_ZeD_Tk_BackTickets") end
    return tr("UI_ZeD_Tk_BackQueue")
end

function D.cardTitle(card, data)
    local K = TC.kinds[card.kind]
    if K then return K.title(card, data) end
    if card.kind == "ask" then return tr("UI_ZeD_Srv_AskAdmins") end
    if card.kind == "mine" then return tr("UI_ZeD_Tk_CardMine", card.id) end
    return tr("UI_ZeD_Tk_CardStaff", card.id, tostring(data and data ~= true and data.author or ""))
end

function D.drawFlag(panel, card, data, x, y, w)
    local T, A = ZeD.T, ZeD.Atoms
    local h = px(FLAG_H)
    local pad = px(CARD_PAD)
    local top = y + math.floor((h - px(16)) / 2)
    local kw = D.drawKind(panel, x + pad, top, data.kind or Tk.NONE, 1, false)
    local sx = x + pad + kw + px(8)
    local st = (card.kind == "staff") and D.staffSt(data.status) or data.st
    D.drawStatus(panel, sx, top, px(16), st, 1, false)
    if card.kind == "staff" then
        local s
        if data.status == "Spam" then s = tr("UI_ZeD_Tk_SpamBy", tostring(data.spamBy))
        elseif data.assignee then s = tr("UI_ZeD_Tk_TakenBy", tostring(data.assignee))
        elseif not card.game then s = tr("UI_ZeD_Tk_NotTaken") end
        if s then
            local room = x + w - pad - (sx + D.statusW(st) + px(8))
            A.drawTextRight(panel, A.truncateText(s, T.fontF3, math.max(0, room)), x + w - pad,
                y + math.floor((h - ZeD.TM:getFontHeight(T.fontF3)) / 2), T.fontF3, T.textDim)
        end
    end
    A.drawDividerH(panel, x, y + h - T.hair, w, false)
    return h
end

function D.cardHelp(t, card, data)
    local K = TC.kinds[card.kind]
    if K then return K.help(t, card, data) end
    if card.kind == "ask" then
        return t.ask.kind and tr(KIND_HELP[t.ask.kind]) or tr("UI_ZeD_Tk_HelpAsk")
    elseif card.kind == "mine" then
        return tr(card.game and "UI_ZeD_Tk_OneAnswer" or "UI_ZeD_Tk_HelpMineCard")
    end
    if not data then return nil end
    if card.game then return tr("UI_ZeD_Tk_HelpFallback") end
    if data.status == "Spam" then return tr(D.isAdmin() and "UI_ZeD_Tk_HelpSpamCardAdmin" or "UI_ZeD_Tk_HelpSpamCardMod") end
    if data.gameGone then return tr("UI_ZeD_Tk_RemovedGame") end
    if data.source == "game" then return tr("UI_ZeD_Tk_HelpGameShort") end
    return tr("UI_ZeD_Tk_HelpStaffCard")
end

-- the key of what the card holds
function D.cardKey(t, card, inner)
    local X = ZeD.Text
    local parts = { card.kind, tostring(card.id), tostring(C.seq), tostring(inner),
        tostring(X and X.measureEpoch and X.measureEpoch() or 0), tostring(t.ask.kind), tostring(t.ask.here), tostring((D.link())) }
    local p = getPlayer()
    if card.kind == "ask" and t.ask.here and p then
        parts[#parts + 1] = tostring(math.floor(p:getX())) .. "," .. tostring(math.floor(p:getY()))
    end
    local K = TC.kinds[card.kind]
    if K and K.key then parts[#parts + 1] = tostring(K.key(t, card)) end
    return table.concat(parts, ":")
end

-- the field being typed in, if any
function D.typing(win, t)
    for _, it in ipairs(t.items or {}) do
        if it.k == "field" or it.isField then
            local inner = D.fieldInner(D.fieldOf(win, it.key))
            if inner and inner:isFocused() then return it end
        end
    end
    return nil
end

-- the card's list against its scroll; the field being typed in kept in view as it grows, else the controller's focus.
-- Returns the offset.
function D.cardScroll(win, t, x, w, sy, sh, listH)
    local T = ZeD.T
    local scroll = t.scroll
    local needs = listH > sh
    scroll.visible = needs
    if not needs then
        scroll:setScrollPos(0)
        return 0, false
    end
    local maxOff = math.max(0, listH - sh)
    scroll.x, scroll.y, scroll.height = x + w - T.sp.scrollbarW, sy, sh
    scroll:setBarSize(sh / math.max(1, listH))
    local Fo = ZeD.Input and ZeD.Input.Focus
    local fe = Fo and Fo.getFocusedWindow and Fo.getFocusedWindow() == win and Fo.liveElement and Fo.liveElement(win)   -- (nil under the mouse)
    local field = D.typing(win, t)
    if field then
        fe = { tkc = true, cy = field.y, h = field.h }
    end
    if fe and fe.tkc and fe.cy then
        local off0 = math.floor(scroll.scrollPos * maxOff)
        local off1 = off0
        if fe.cy < off0 or (fe.h or 0) >= sh then off1 = fe.cy
        elseif fe.cy + (fe.h or 0) > off0 + sh then off1 = fe.cy + (fe.h or 0) - sh end
        if off1 ~= off0 then scroll:setScrollPos(math.max(0, math.min(1, off1 / maxOff))) end
    end
    return math.floor(scroll.scrollPos * maxOff), true
end

--- Draw the card on top of the tab inside (x, y, w, h): back bar, flag, the scrolled body and the foot. A card that
--- loses its data, or never gets any in LOAD_MS, goes back with the reason.
function TC.renderCard(panel, win, st, x, y, w, h)
    local T, M = ZeD.T, ZeD.Molecules
    local t = ts(st)
    local card = st.card
    if card.kind == "staff" then D.queueTick(st, t) end
    local K = TC.kinds[card.kind]
    if K and K.tick then K.tick(win, st, t, card) end
    local data = D.cardData(card)
    if data then
        if card.waited then
            card.waited = nil
            D.landLate(win, st)
            card.landIn = 2      -- and again once the window has built this card's stops (it moves only off the back key)
        elseif card.landIn then
            card.landIn = card.landIn - 1
            if card.landIn <= 0 then
                card.landIn = nil
                D.landLate(win, st)
            end
        end
        card.had = true
    elseif card.had then
        -- it was deleted while open, or the record went
        D.flash(t, (K and K.gone and K.gone(card)) or C.errText("gone"))
        TC.back(win, st)
        return
    elseif not TC.qaHold and t.pushedAt and now() - t.pushedAt >= LOAD_MS then
        D.flash(t, tr("UI_ZeD_Tk_LoadFail"))
        TC.back(win, st)
        return
    else
        card.waited = true
    end
    if card.kind == "mine" and not card.game then C.onCard(card.id) end
    w = math.min(w, px(480))
    t.hits = {}
    ZeD.Help.set(win, D.cardHelp(t, card, data))
    -- the back bar and the flags
    t.barRects = t.barRects or {}
    local bar = 0
    if K and K.noBack then
        t.barRects.back = nil
    else
        bar = M.drawCardBackBar(panel, x, y, w, D.cardTitle(card, data), nil, false, false, t.barRects,
            { win = win, focusParts = { back = D.focusOf(win, "tk:back") },
              backHelp = D.backHelp(st, card) })
    end
    local flagH = 0
    if K then
        if K.flag then flagH = K.flag(panel, win, t, card, data, x, y + bar, w, bar) end
    elseif card.kind ~= "ask" and data then
        flagH = D.drawFlag(panel, card, data, x, y + bar, w)
    end
    -- the foot, measured first: the body takes what is left
    local foot = D.footOf(win, st, t, card, data)
    local bandsH, two = D.footH(foot, w)
    local words = D.footWords(win, t, foot)
    local lineH, lineWords = D.footLine(foot, w, words, bandsH)
    local footH = bandsH + lineH
    local sy = y + bar + flagH
    local sh = y + h - footH - sy
    local pad = px(CARD_PAD)
    local inner = w - T.sp.scrollbarW - 2 * pad
    local key = D.cardKey(t, card, inner)
    if t.itemsKey ~= key or not t.items then
        t.itemsKey = key
        t.items = D.cardItems(win, st, t, card, data)
    end
    local items = t.items
    local listH = D.layout(win, items, inner, sh)
    local off, needs = D.cardScroll(win, t, x, w, sy, sh, listH)
    t.listH, t.off, t.csy, t.csh, t.cx, t.cpad, t.cin = listH, off, sy, sh, x, pad, inner
    local mx, my = panel:getMouseX(), panel:getMouseY()
    if not (mx >= x and mx < x + w and my >= sy and my < sy + sh) or D.padOn() then mx, my = nil, nil end
    local covered = win._drawerItem ~= nil or t.popup ~= nil
    panel:setStencilRect(x, sy, w, sh)
    for _, it in ipairs(items) do
        local dy = sy + it.y - off
        if dy + (it.spanH or it.h) >= sy and dy <= sy + sh then
            D.drawCardItem(panel, win, t, it, x + pad, dy, inner, mx, my, sy, sh, covered)
        end
    end
    panel:clearStencilRect()
    -- (PZ clips do not nest: the list's rect, once cleared, stays shut to what draws next, so the
    -- whole card is opened again for the scrollbar and the pop-up over the list...)
    panel:setStencilRect(0, 0, panel:getWidth(), panel:getHeight())
    if needs then t.scroll:draw(panel) end
    if t.popup then D.drawPopup(panel, win, t, sy, sy + sh) end
    if lineH > 0 then D.drawFootLine(panel, x, y + h - footH, w, lineH, lineWords, foot.tone) end
    if bandsH > 0 then
        D.drawFoot(panel, win, t, foot, x, y + h - bandsH, w, two, (lineH == 0) and words or nil, lineH > 0)
    else
        t.footRects = {}
    end
    -- (...and that clip comes off here: a card ends with the clips it started with, in a window's
    -- tab and on the join screen alike)
    panel:clearStencilRect()
    local s = D.flashNow(t)
    if s and not D.padOn() then ZeD.Help.set(win, s) end
end

-- a line of chat on a report: the picked line in the accent, and a stop so the controller can step down and read it
TC.items.chatline = {
    layout = function(win, it, w)
        if it.wrapW ~= w then
            it.wrapW = w
            it.lines = D.wrap(it.text, ZeD.T.fontF2, math.max(1, w))
        end
        return #it.lines * ZeD.TM:getFontHeight(ZeD.T.fontF2) + px(2)
    end,
    draw = function(panel, win, t, it, x, dy, w, mx, my, ctx)
        local T = ZeD.T
        local onF = D.mark(panel, x, dy, w, it.h, D.focusOf(win, ctx.prefix .. it.c.id))
        local c = (onF and T.textOnFocus) or (it.mark and T.accent) or T.text
        local f2h = ZeD.TM:getFontHeight(T.fontF2)
        for i, s in ipairs(it.lines or {}) do
            panel:drawText(s, x, dy + (i - 1) * f2h, c.r, c.g, c.b, c.a or 1, T.fontF2)
        end
    end,
    stops = function(it, x0, dy, w, add) add(it.c, x0, dy, w, it.h, it.y).promptA = false end,
}

-- ---------------------------------------------------------------------------
-- A CARD'S INPUT
-- ---------------------------------------------------------------------------
--- The open card's scroll, or nil when no card is open.
function TC.activeScroll(st)
    local t = st.tk
    if st.card and t then return t.scroll end
    return nil
end

-- a press on a field whose box is hidden: its place scrolls into view, and the box takes the caret when it shows
function D.fieldPress(win, t, h)
    local it = h.field
    local box = D.fieldOf(win, it.key)
    if box and box:isVisible() then return end
    local maxOff = math.max(0, (t.listH or 0) - (t.csh or 0))
    if maxOff > 0 then t.scroll:setScrollPos(math.max(0, math.min(1, it.y / maxOff))) end
    t.wantField = it.key
end

--- A click on the open card: its pop-up, scrollbar, back bar, foot, then its items.
function TC.cardClick(win, st, x, y)
    local t = ts(st)
    if t.popup then
        D.popupClick(st, t, x, y)
        return
    end
    local sc = t.scroll
    if sc.visible and x >= sc.x and x < sc.x + sc.width and y >= sc.y and y < sc.y + sc.height then
        sc:handleMouseDown(y - sc.y)
        return
    end
    if inside(t.barRects and t.barRects.back, x, y) then
        sound()
        TC.back(win, st)
        return
    end
    for _, r in ipairs(t.footRects or {}) do
        if inside(r, x, y) then
            if not r.b.disabled then
                sound()
                r.b.run(win)
            else
                D.grayPress(t, r.b)
            end
            return
        end
    end
    if t.csy and (y < t.csy or y >= t.csy + t.csh) then return end
    for _, h in ipairs(t.hits) do
        if inside(h, x, y) then
            if h.field then
                D.fieldPress(win, t, h)
            elseif not h.c.disabled and h.c.run then
                sound("UISelectListItem")
                h.c.run(win)
            elseif h.c.disabled then
                D.grayPress(t, h.c)
            end
            return
        end
    end
end

-- B: out of the confirm, else off the card
function D.cancel(win, st)
    local t = ts(st)
    local K = st.card and TC.kinds[st.card.kind]
    if K and K.cancel and K.cancel(win, st, t, st.card) then return end
    if t.confirm then
        t.confirm = nil
        D.focusId(win, st, "tk:del")
    else
        TC.back(win, st)
    end
end

-- what every stop on a card answers to: B, and X for Go there when the ticket has a place
function D.dress(win, st, t, e, c, place)
    e.tkc = true
    e.onCancel = function(ww) D.cancel(ww, st) end
    e.promptB = tr("UI_ZeD_Tk_PromptBack")
    if c then
        e.tkWhy = function() return c.why end
        -- (A on a gray control: its why as the card's answer, as a click gives it)
        local go = e.onActivate
        e.onActivate = function(ww)
            if c.disabled then D.grayPress(t, c) elseif go then go(ww) end
        end
    end
    if place then
        e.promptX = tr("UI_ZeD_Tk_GoThere")
        e.onContextMenu = function()
            if D.canGo() then D.goThere(st, place) else D.flash(t, tr("UI_ZeD_Tk_NoGo")) end
        end
    end
    local K = st.card and TC.kinds[st.card.kind]
    if K and K.padX then
        local b = K.padX(win, st, t, st.card)
        if b then
            e.promptX = b.label
            e.onContextMenu = function() if not b.disabled then b.run(win) else D.flash(t, b.why) end end
        end
    end
    return e
end

--- The open card's controller stops: the back key, the items in reading order, the foot's buttons (only the
--- pop-up's rows while one is open).
function TC.cardStops(win, st)
    local t = ts(st)
    local out = {}
    local card = st.card
    if not card or not t.items then return out end
    if t.popup and TC.popupStops(st, out) then return out end
    local sy, off = t.csy or 0, t.off or 0
    local x0 = (t.cx or 0) + (t.cpad or 0)
    local inner = t.cin or px(300)
    local data = D.cardData(card)
    local place = (card.kind == "staff" and data and data.place) or nil
    local land = nil
    local function add(c, x, y, w, h, cy)
        local e = D.dress(win, st, t, D.stop(c, "tk:" .. c.id, x, y, w, h, cy), c, place)
        if c.land and not land then
            land = e
            e.tkLand = true
        end
        out[#out + 1] = e
        return e
    end
    -- the back key first, said to lie above the list so Up reaches every stop on the way
    local r = t.barRects and t.barRects.back
    if r then
        local e = D.dress(win, st, t, D.stop({ run = function(ww) TC.back(ww, st) end }, "tk:back", r.x, math.min(r.y, sy - off - r.h), r.w, r.h), nil, place)
        e.promptA = tr("UI_ZeD_Tk_PromptBack")
        out[#out + 1] = e
    end
    for _, it in ipairs(t.items) do
        local dy = sy + it.y - off
        local k = it.k
        local xi, wi = x0, inner
        if it.ind then
            xi, wi = x0 + px(it.ind), inner - 2 * px(it.ind)
        end
        local ext = TC.items[k]
        if ext then
            if ext.stops then ext.stops(it, xi, dy, wi, add) end
        elseif k == "chips" then
            for _, c in ipairs(it.ctls) do add(c, xi + c.dx, dy + c.dy, c.w, c.h, it.y + c.dy) end
        elseif k == "check" then
            add(it.c, x0, dy, inner, it.h, it.y)
        elseif k == "field" then
            add(it.c, xi, dy, wi, it.h, it.y)
        elseif k == "fact" and it.c then
            -- (not drawn yet, under the fold: where it will draw, at the end of the row or after the label)
            add(it.c, it.c.sx or (it.c.box and (x0 + (it.lw or 0) + px(FACT_GAP)) or (x0 + inner - it.c.w)), dy, it.c.w, it.c.h, it.y)
        elseif k == "btn" then
            add(it.c, x0, dy, it.c.w, it.c.h, it.y)
        elseif k == "msg" then
            -- (nothing to press: a stop so the controller can step through a thread and read it)
            local e = D.dress(win, st, t, D.stop({}, it.stop, x0, dy, inner, it.h, it.y), nil, place)
            e.promptA = false
            out[#out + 1] = e
        end
    end
    -- the foot's stops are said to lie under the list, or a stop under the fold could not be reached with Down
    local listEnd = sy + (t.listH or 0) - off
    for _, rc in ipairs(t.footRects or {}) do
        local b = rc.b
        local e = D.dress(win, st, t, D.stop({ run = b.run, disabled = b.disabled, help = b.help }, "tk:" .. b.id,
            rc.x, math.max(rc.y, listEnd), rc.w, rc.h), b, place)
        if (b.variant == "primary" or b.land or b.id == "nodel" or b.id == "unspam" or b.id == "reopen") and not land then
            land = e
            e.tkLand = true
        end
        out[#out + 1] = e
    end
    if not land and out[1] then out[1].tkLand = true end
    return out
end

--- A key that changes when the card's stops would: the tab's scroll key while a card is open.
function TC.cardKey(st)
    local t = st.tk
    if not t then return "" end
    local parts = { tostring(t.off or 0), tostring(st.card and st.card.kind), tostring(t.itemsKey), tostring(t.confirm),
        (t.popup and ("p" .. tostring(t.popup.key)) or "") }
    for _, r in ipairs(t.footRects or {}) do
        parts[#parts + 1] = r.b.id
        parts[#parts + 1] = tostring(r.b.disabled)
    end
    for _, it in ipairs(t.items or {}) do
        if it.k == "field" or it.isField then parts[#parts + 1] = tostring(it.h) end
    end
    return table.concat(parts, ",")
end

-- ---------------------------------------------------------------------------
-- QA
-- ---------------------------------------------------------------------------
--- The tab's card state (st.tk), made if missing. Named for QA, but the other card files reach the state this way too.
function TC.qaState(st) return ts(st) end
function TC.qaOpen(win, st, kind, id, game)
    if kind == "ask" then TC.openAsk(win, st)
    elseif kind == "mine" then TC.openMine(win, st, id, game)
    else TC.openStaff(win, st, id, game) end
end
function TC.qaConfirm(st) ts(st).confirm = true end
function TC.qaFlash(st, text) D.flash(ts(st), text) end
function TC.qaAsk(st, kind, here)
    local t = ts(st)
    t.ask.kind, t.ask.here = kind, here
    t.items = nil
end

if not TC.hooked then
    TC.hooked = true
    if Events and Events.OnTick then Events.OnTick.Add(function() D.onTick() end) end
end

return TC
