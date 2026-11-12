-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MessagesWindow.lua
-- ============================================================================
-- THE MESSAGES WINDOW and the toasts: the notification center's face.
-- Client-side; an organism. The store is ZeD_Messages.lua.
--
-- A ZeD window on the player's screen: the sources on the left (From mods,
-- Errors: a square mark, the name, a count), the chosen source's messages on the
-- right as cards (kind, source, when, the text as the mod wrote it, the mod's own
-- buttons) with a scrollbar when they overflow, a band at the foot (Show this
-- mod's notes as pop-ups, Delete, Mark all read) and the window's help line under
-- it (the plain words for what the pointer is over, the controller's prompts).
-- Mouse and controller (D-pad between the list, the cards' buttons and the band;
-- A presses, B closes). Its notices are speech balloons out of the Messages
-- note on the belt for six seconds, so every notice comes out of the one place
-- (they were corner toasts once; ZeD_Bubbles.layoutNoticeBalloons); a click
-- opens the window on that source.
-- ============================================================================

require "ZeD/Tr"
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/Organisms"
require "ZeD/ZeD_Messages"
require "ZeD/ZeD_Bubbles"

ZeD = ZeD or {}
ZeD.MessagesWindow = ZeD.MessagesWindow or {}
local W = ZeD.MessagesWindow
local MS = ZeD.Messages
W.windows = W.windows or {}

-- design units (1 px at 1080p; T.px scales them)
local U = {
    W = 760, BODY_H = 400, LIST_W = 240, HEAD_H = 20, PAD = 10,
    CARD_GAP = 10, CARD_PAD = 10, CARD_HEAD_H = 24, BAND_EDGE = 8, BAND_GAP = 8,
    NOTICE_LIFT = 4,        -- the balloons' tail tip above the note's top edge
    NOTICE_FREE_BOTTOM = 80, -- no note on the screen: the balloons this far over the screen's bottom (or the dash)
}

local function fh(font) return ZeD.TM:getFontHeight(font) end
local function tw(font, s) return ZeD.TM:MeasureStringX(font, s) end
local function inRect(r, x, y) return r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end
local function sound(name) pcall(function() getSoundManager():playUISound(name or "UIActivateButton") end) end
local function tr(k, ...) return ZeD.tr(k, ...) end
local function btnLabel(s) return ZeD.btnCase and ZeD.btnCase(s) or s end

-- The window keeps its own controller focus (it is not under FocusManager), so its marks say
-- what has the focus (focused) and that a controller holds it (pad).
local _fo = {}
local function focusOpts(win)
    _fo.win, _fo.focused, _fo.pad = win, true, true
    return _fo
end

-- the text of a message as blocks: rich text read as the prompts read it, plain text as paragraphs
local function blocksOf(it)
    if it._blocks then return it._blocks end
    local P = ZeD.Prompt
    local src = tostring(it.text or "")
    if P and P.parseRich and (it.rich or src:find("<")) then it._blocks = P.parseRich(src)
    else
        it._blocks = {}
        for para in (src:gsub("\r", "") .. "\n\n"):gmatch("(.-)\n%s*\n") do
            para = para:gsub("^%s+", ""):gsub("%s+$", "")
            if para ~= "" then it._blocks[#it._blocks + 1] = { kind = "para", text = para } end
        end
    end
    return it._blocks
end

-- ---------------------------------------------------------------------------
-- the window
-- ---------------------------------------------------------------------------
ZeD_MessagesWindow = ZeD_Window:derive("ZeD_MessagesWindow")

function ZeD_MessagesWindow:new(playerNum)
    local o = ZeD_Window.new(self, 0, 0, 100, 100, "")
    o.resizable = false
    o.pin = true
    o.anchorLeft, o.anchorRight, o.anchorTop, o.anchorBottom = true, false, true, false
    o.moveWithMouse = false
    o.playerNum = playerNum or 0
    o.sel = nil          -- the chosen source's name
    o.scroll = 0         -- the cards' scroll, px
    o.zone = "list"      -- controller: "list" | "cards" | "foot"
    o.cardFocus = 1      -- controller: which card button (in reading order)
    o.footFocus = 1
    o._hover = nil
    o._down = nil
    o:setWantKeyEvents(true)
    return o
end

function ZeD_MessagesWindow:createChildren()
    ZeD_Window.createChildren(self)
    self.minimumWidth, self.minimumHeight = 0, 0
end

function ZeD_MessagesWindow:close()
    local wasGuest = self.guestJoy ~= nil
    -- (opened with a controller nobody plays with yet: it lets go, W.openGuest)
    local guest = self.guestJoy
    if guest then
        self.guestJoy = nil
        if guest.focus == self then guest.focus, guest.lastfocus = nil, nil end
        guest.activeWhilePaused = nil
    end
    self:setVisible(false)
    self:removeFromUIManager()
    -- (a guest's window leaves player one's own focus where it is)
    local own = JoypadState.players[self.playerNum + 1]
    if own and (not wasGuest or own.focus == self) then setJoypadFocus(self.playerNum, nil) end
end

-- the sources in list order, and the chosen one (the first when none or gone)
function ZeD_MessagesWindow:rows()
    local mods, errs, halos = MS.list()
    local rows = {}
    if #mods > 0 then rows[#rows + 1] = { head = tr("UI_ZeD_Msg_FromMods") } end
    for _, s in ipairs(mods) do rows[#rows + 1] = { src = s } end
    if #errs > 0 then rows[#rows + 1] = { head = tr("UI_ZeD_Msg_Errors") } end
    for _, s in ipairs(errs) do rows[#rows + 1] = { src = s } end
    -- (the notes over your head: ZeD_HaloText)
    if halos and #halos > 0 then rows[#rows + 1] = { head = tr("UI_ZeD_Msg_GameNotes") } end
    for _, s in ipairs(halos or {}) do rows[#rows + 1] = { src = s } end
    local cur
    for _, r in ipairs(rows) do if r.src and r.src.name == self.sel then cur = r.src end end
    if not cur then
        for _, r in ipairs(rows) do if r.src then cur = r.src; break end end
        self.sel = cur and cur.name or nil
        if cur then MS.markRead(cur.name) end
    end
    return rows, cur
end

function ZeD_MessagesWindow:choose(name)
    if self.sel ~= name then self.scroll = 0; self.cardFocus = 1; self.asking = nil end
    self.sel = name
    if name then MS.markRead(name) end
end

-- ---------------------------------------------------------------------------
-- LAYOUT (every frame from the live tokens; local px)
-- ---------------------------------------------------------------------------
-- The cards of the chosen source in an area areaW wide starting at areaX, scrolled: wrapped
-- text, the mod's own buttons right-aligned (the primary last). Fills g.cards and g.btns;
-- returns the height of all of them.
function ZeD_MessagesWindow:buildCards(g, cur, areaX, areaW)
    local T = ZeD.T
    local Mo = ZeD.Molecules
    local px = T.px
    local cx, cw = areaX + px(U.PAD), areaW - px(U.PAD) * 2
    local inner = cw - px(U.CARD_PAD) * 2
    local cy = g.body.y + px(U.PAD) - self.scroll
    local bh = T.buttonH
    g.cards, g.btns = {}, {}
    for _, it in ipairs(cur and cur.items or {}) do
        local lines = {}
        local textH = 0
        if it.k == "err" then
            lines[#lines + 1] = { text = tr("UI_ZeD_Msg_ErrorCount", it.count, cur.name), font = T.fontF4 }
            local np = #(it.placeOrder or {})
            if np > 0 then
                -- (each place has its card below: here only how many places)
                lines[#lines + 1] = { text = tr(np == 1 and "UI_ZeD_Msg_PlacesOne" or "UI_ZeD_Msg_PlacesMany", np), font = T.fontF2, dim = true }
            else
                for _, f in ipairs(it.firsts or {}) do
                    for _, l in ipairs(ZeD.Atoms.wrapText(f, T.fontF1, inner)) do lines[#lines + 1] = { text = l, font = T.fontF1, mono = true } end
                end
            end
        elseif it.k == "ticket" or it.k == "ticketnew" or it.k == "adminnote" or it.k == "adminmsg" or it.k == "server" or it.k == "invite" or it.k == "pad" then
            -- (a ticket's note carries a username: drawn plain, never read for markup)
            if it.k == "pad" and it.head then
                for _, l in ipairs(ZeD.Atoms.wrapText(tostring(it.head), T.fontF4, inner)) do lines[#lines + 1] = { text = l, font = T.fontF4 } end
            end
            for _, l in ipairs(ZeD.Atoms.wrapText(tostring(it.text or ""), T.fontF2, inner)) do lines[#lines + 1] = { text = l, font = T.fontF2 } end
            if it.k == "pad" and it.answer then
                lines[#lines + 1] = { gap = true }
                lines[#lines + 1] = { text = tr("UI_ZeD_Msg_YouAnswered", it.answer), font = T.fontF2, dim = true }
            end
        else
            for bi, bl in ipairs(blocksOf(it)) do
                if bl.kind ~= "image" then
                    local font = bl.kind == "head" and T.fontF4 or T.fontF2
                    if bi > 1 then lines[#lines + 1] = { gap = true } end
                    for _, l in ipairs(ZeD.Atoms.wrapText(bl.text, font, inner)) do lines[#lines + 1] = { text = l, font = font } end
                end
            end
            if it.k == "halo" and (it.n or 1) > 1 then
                lines[#lines + 1] = { text = tr("UI_ZeD_Msg_Times", it.n), font = T.fontF2, dim = true }
            end
            if it.k == "ask" and it.answer and it.answer ~= "" then
                lines[#lines + 1] = { gap = true }
                lines[#lines + 1] = { text = tr("UI_ZeD_Msg_YouAnswered", it.answer), font = T.fontF2, dim = true }
            end
        end
        for _, l in ipairs(lines) do textH = textH + (l.gap and px(6) or (fh(l.font) + px(3))) end
        local btns = {}
        if it.k == "note" and not it.done then
            for bi, b in ipairs(it.buttons or {}) do btns[#btns + 1] = { label = btnLabel(tostring(b.title or "")), i = bi, primary = bi == #it.buttons } end
        elseif it.k == "err" then
            btns[#btns + 1] = { label = btnLabel(tr("UI_ZeD_Msg_CopyAll")), copy = true, primary = true }
        elseif it.k == "ticket" then
            btns[#btns + 1] = { label = btnLabel(tr("UI_ZeD_Tk_NoteOpen")), ticket = true, primary = true }
        elseif it.k == "adminnote" and it.bans then
            btns[#btns + 1] = { label = btnLabel(tr("UI_ZeD_Tk_NoteOpen")), bans = true, primary = true }
        elseif it.k == "invite" then
            btns[#btns + 1] = { label = btnLabel(tr("UI_ZeD_Tk_NoteOpen")), invite = true, primary = true }
        elseif it.k == "notice" and it.run then
            -- (a notice of ZeD's that does something, the survival guide's: its Open does it)
            btns[#btns + 1] = { label = btnLabel(tr("UI_ZeD_Tk_NoteOpen")), noticeRun = it.run, primary = true }
        elseif it.k == "adminmsg" and it.tp then
            -- (the game's pop-up asked "Teleport?" under a place: ZeD_MpLeftovers.lua sends its own answer)
            btns[#btns + 1] = { label = btnLabel(getText("UI_Scoreboard_Teleport")), teleport = true, primary = true }
        elseif it.k == "pad" and not it.done then
            -- (a controller's note: the game's own choices, in its order; one alone is the default)
            local pb = it.padButtons or {}
            for bi, b in ipairs(pb) do btns[#btns + 1] = { label = btnLabel(tostring(b.label or "")), padRun = b.run, primary = #pb == 1 } end
        end
        -- (the card and its buttons, placed; shared by the per-error cards below)
        local function place(cit, clines, cbtns, cTextH)
            local ch = px(U.CARD_HEAD_H) + px(U.CARD_PAD) + cTextH + px(U.CARD_PAD) + (#cbtns > 0 and (bh + px(U.CARD_PAD)) or 0)
            local card = { x = cx, y = cy, w = cw, h = ch, it = cit, lines = clines, btns = cbtns }
            local bx = cx + cw - px(U.CARD_PAD)
            for bi = #cbtns, 1, -1 do
                local b = cbtns[bi]
                local bw = Mo.buttonW(b.label)
                bx = bx - bw
                b.x, b.y, b.w, b.h, b.card = bx, cy + ch - px(U.CARD_PAD) - bh, bw, bh, card
                bx = bx - px(U.BAND_GAP)
            end
            for _, b in ipairs(cbtns) do g.btns[#g.btns + 1] = b end
            g.cards[#g.cards + 1] = card
            cy = cy + ch + px(U.CARD_GAP)
        end
        place(it, lines, btns, textH)
        -- one card per place the errors come from (punch list 170), newest first: the file and line, how
        -- often and when, the game's message, the same in plain words where that is certain, what called
        -- it; Copy, and Open in Mods for a mod's file
        if it.k == "err" and #(it.placeOrder or {}) > 0 then
            local isMod = cur.name ~= tr("UI_ZeD_Msg_TheGame")
            for _, p in ipairs(it.placeOrder) do
                local el, eh = {}, 0
                local function add(text, font, opts)
                    for _, l in ipairs(ZeD.Atoms.wrapText(text, font, inner)) do
                        local e = { text = l, font = font }
                        if opts then for k, v in pairs(opts) do e[k] = v end end
                        el[#el + 1] = e
                        eh = eh + fh(font) + px(3)
                    end
                end
                local where = tr("UI_ZeD_Msg_PlaceAt", p.file, p.line)
                if p.fn and p.fn ~= "" then where = tr("UI_ZeD_Msg_PlaceIn", where, p.fn) end
                add(where, T.fontF4)
                add((p.count > 1) and tr("UI_ZeD_Msg_PlaceWhenMany", p.count, p.first or "", p.last or "") or tr("UI_ZeD_Msg_PlaceWhenOne", p.first or ""), T.fontF2, { dim = true })
                add(tostring(p.msg or ""), T.fontF1, { mono = true })
                local plain = MS.plainWords(p.msg)
                if plain then add(tr("UI_ZeD_Msg_PlainHead", plain), T.fontF2) end
                local c = p.caller
                if c then add(tr("UI_ZeD_Msg_CalledFrom", (c.fn and c.fn ~= "") and c.fn or "?", c.file, c.line), T.fontF2, { dim = true }) end
                local pb = {}
                if isMod then pb[#pb + 1] = { label = btnLabel(tr("UI_ZeD_Msg_OpenInMods")), openMods = true, place = p } end
                pb[#pb + 1] = { label = btnLabel(tr("UI_ZeD_Msg_CopyOne")), copy = true, place = p, primary = true }
                place({ k = "err", when = (p.count > 1) and tr("UI_ZeD_Msg_Times", p.count) or tr("UI_ZeD_Msg_Once") }, el, pb, eh)
            end
        -- every kept error its own card, newest first, with its own Copy (errors that name no Lua file)
        elseif it.k == "err" then
            local n = #(it.texts or {})
            for i = n, 1, -1 do
                local t = it.texts[i]
                local first = t:match("([^\n]*Exception[^\n]*)") or t:match("([^\n]+)") or t
                first = first:gsub("^%s+", ""):sub(1, 300)
                local el, eh = {}, 0
                for _, l in ipairs(ZeD.Atoms.wrapText(first, T.fontF1, inner)) do el[#el + 1] = { text = l, font = T.fontF1, mono = true }; eh = eh + fh(T.fontF1) + px(3) end
                local eit = { k = "err", when = tostring((it.whens and it.whens[i]) or "") .. " | " .. tr("UI_ZeD_Msg_ErrorNofM", n - i + 1, n) }
                place(eit, el, { { label = btnLabel(tr("UI_ZeD_Msg_CopyOne")), copy = true, idx = i } }, eh)
            end
        end
    end
    return cy + self.scroll - g.body.y
end

function ZeD_MessagesWindow:layout()
    local T = ZeD.T
    local Mo = ZeD.Molecules
    local px = T.px
    local g = { rows = {}, cards = {}, btns = {}, foot = {} }
    local tbH = self:titleBarHeight()
    local w = px(U.W)
    local bodyY, bodyH = tbH, px(U.BODY_H)
    local listW = px(U.LIST_W)
    local bandY, bandH = bodyY + bodyH, Mo.bandH()
    local h = bandY + bandH + self:footerHeight()   -- (the band, then the window's help line)
    local sbW = T.sp.scrollbarW
    g.body = { y = bodyY, h = bodyH }
    g.list = { x = 0, y = bodyY, w = listW, h = bodyH }
    g.cardsArea = { x = listW, y = bodyY, w = w - listW, h = bodyH }
    g.band = { y = bandY, h = bandH }

    -- the list
    local rows, cur = self:rows()
    self._cur = cur
    local y = bodyY
    for _, r in ipairs(rows) do
        local rh = r.head and px(U.HEAD_H) or T.rowH
        g.rows[#g.rows + 1] = { x = 0, y = y, w = listW, h = rh, head = r.head, src = r.src }
        y = y + rh
    end

    -- the cards; a scrollbar beside them when they overflow (the cards then wrap narrower)
    local ca = g.cardsArea
    local ch = self:buildCards(g, cur, ca.x, ca.w)
    if ch > ca.h then
        g.needsBar = true
        ch = self:buildCards(g, cur, ca.x, ca.w - sbW)
    end
    g.contentH = ch
    local maxS = math.max(0, ch - ca.h)
    if self.scroll > maxS then self.scroll = maxS end
    self._maxS = maxS
    local sb = self._sb
    if not sb then
        sb = ZeD_ScrollbarState:new()
        local win = self
        sb.onScroll = function(pos) win.scroll = math.floor(pos * (win._maxS or 0) + 0.5) end
        self._sb = sb
    end
    sb.visible = g.needsBar == true
    sb.width, sb.arrowH = sbW, sbW
    sb.x, sb.y, sb.height = w - sbW, ca.y, ca.h
    sb:setBarSize(ca.h / math.max(1, ch))
    if not sb.dragging then sb.scrollPos = maxS > 0 and math.min(1, self.scroll / maxS) or 0 end
    g.sb = sb

    -- the band: the checkbox (a mod's) at the left, the buttons right-aligned, 8u apart; a
    -- Delete that waits for its answer swaps the band for the question and its two buttons
    -- (the rects here are the ones the library draws them at: the band's own measures)
    local bh = T.buttonH
    local fy = bandY + px(5)
    if self.asking and not cur then self.asking = nil end
    local right = {}
    if self.asking then
        g.asking = true
        right[#right + 1] = { id = "askno", label = tr("UI_Cancel") }
        right[#right + 1] = { id = "askyes", label = btnLabel(tr("UI_ZeD_Msg_Clear")) }
    else
        if cur and cur.kind ~= "err" then
            local label = tr("UI_ZeD_Msg_ShowPopups")
            g.foot[#g.foot + 1] = { id = "popups", x = px(U.BAND_EDGE), y = fy, w = T.checkboxSz + px(6) + tw(T.fontF2, label), h = bh, label = label, check = true }
        end
        if cur then right[#right + 1] = { id = "clear", label = btnLabel(tr("UI_ZeD_Msg_Clear")), help = tr("UI_ZeD_Msg_HelpClear") } end
        right[#right + 1] = { id = "allread", label = btnLabel(tr("UI_ZeD_Msg_MarkAllRead")), primary = true, help = tr("UI_ZeD_Msg_HelpAllRead") }
    end
    local rx = w - px(U.BAND_EDGE)
    for i = #right, 1, -1 do
        local b = right[i]
        local bw = Mo.buttonW(b.label)
        rx = rx - bw
        b.x, b.y, b.w, b.h = rx, fy, bw, bh
        rx = rx - px(U.BAND_GAP)
    end
    for _, b in ipairs(right) do g.foot[#g.foot + 1] = b end

    -- size and place: the middle of the player's screen
    if self.width ~= w then self:setWidth(w) end
    if self.height ~= h then self:setHeight(h) end
    local pn = self.playerNum
    local x = getPlayerScreenLeft(pn) + math.floor((getPlayerScreenWidth(pn) - w) / 2)
    local yy = getPlayerScreenTop(pn) + math.floor((getPlayerScreenHeight(pn) - h) / 2)
    if self.x ~= x then self:setX(x) end
    if self.y ~= yy then self:setY(yy) end
    self._g = g
end

-- ---------------------------------------------------------------------------
-- DRAW
-- ---------------------------------------------------------------------------
-- the band's buttons and checkbox, kept between frames
local _bandBtns, _cardBtn = {}, {}
local _bandCheck = {}
local _bandSpec = { buttons = _bandBtns }
local _askOpts = { danger = true }

function ZeD_MessagesWindow:prerender()
    local T = ZeD.T
    if not T then return end
    self.minimumWidth, self.minimumHeight = 0, 0
    self.title = tr("UI_ZeD_Msg_Title")
    local n = MS.count()
    self.titleStats = { { text = tr("UI_ZeD_Msg_CountStat", n), noMark = true } }
    local ok, err = pcall(self.layout, self)
    if not ok then ZeD.logOnce("messages window", err); self:close(); return end
    ZeD_Window.prerender(self)
    self.minimumWidth, self.minimumHeight = 0, 0
    local g = self._g
    local A, Mo = ZeD.Atoms, ZeD.Molecules
    local w = self.width
    local px = T.px
    local tc, th, td = T.text, T.textHead, T.textDim
    local ac = T.accent
    local hv = T.hover
    local joy = self.joyfocus ~= nil

    -- the list (the window's own surface shows through; a line at its edge)
    local bs = T.borderS
    self:drawRect(g.list.w, g.list.y, T.hair, g.list.h, bs.a or 1, bs.r, bs.g, bs.b)
    for _, r in ipairs(g.rows) do
        if r.head then
            Mo.drawSectionHeader(self, r.x + px(U.PAD), r.y, r.w - px(U.PAD), r.head, nil, true, false, nil, nil, px(U.PAD), r.h, true)
        else
            local s = r.src
            local on = self.sel == s.name
            local focus = joy and self.zone == "list" and on
            local hover = (not joy) and self._hover and self._hover.row == s.name
            if on then self:drawRect(r.x, r.y, r.w, r.h, T.selectionA, ac.r, ac.g, ac.b)
            elseif hover then self:drawRect(r.x, r.y, r.w, r.h, hv.a or 1, hv.r, hv.g, hv.b) end
            if hover then ZeD.Help.set(self, tr("UI_ZeD_Msg_HelpRow", s.name)) end
            local onFocus = focus and ZeD.Focus.mark(self, r.x, r.y, r.w, r.h, focusOpts(self), nil)
            local unread = 0
            for _, it in ipairs(s.items) do if not it.read then unread = unread + 1 end end
            local dsz = px(8)
            local dy = r.y + math.floor((r.h - dsz) / 2)
            local dc = (s.kind == "err" and T.danger) or (unread > 0 and ac) or nil
            if dc then A.drawStatusDot(self, r.x + px(U.PAD), dy, dc, dsz)
            else A.drawStatusHollow(self, r.x + px(U.PAD), dy, td, dsz) end
            local cnt = tostring(s.kind == "err" and (s.items[1] and s.items[1].count or 0) or #s.items)
            local cw = tw(T.fontF1, cnt)
            local col = onFocus and T.textOnFocus or tc
            local cc = onFocus and T.textOnFocus or td
            local nx = r.x + px(U.PAD) + dsz + px(8)
            self:drawText(A.truncateText(s.name, T.fontF2, r.w - (nx - r.x) - cw - px(U.PAD) * 2), nx, r.y + math.floor((r.h - fh(T.fontF2)) / 2), col.r, col.g, col.b, col.a or 1, T.fontF2)
            self:drawText(cnt, r.x + r.w - px(U.PAD) - cw, r.y + math.floor((r.h - fh(T.fontF1)) / 2), cc.r, cc.g, cc.b, cc.a or 1, T.fontF1)
        end
    end
    if #g.rows == 0 then
        Mo.drawEmptyLine(self, px(U.PAD), g.list.y + px(8), g.list.w - px(U.PAD) * 2, tr("UI_ZeD_Msg_None"))
    end

    -- the cards (clipped to their area)
    local ca = g.cardsArea
    self:setStencilRect(ca.x, ca.y, ca.w, ca.h)
    for _, c in ipairs(g.cards) do
        if c.y + c.h >= ca.y and c.y <= ca.y + ca.h then
            local it = c.it
            A.frame(self, c.x, c.y, c.w, c.h, T.border)
            -- the head: kind (a tag), source, when
            local tagH = px(16)
            local hy = c.y + math.floor((px(U.CARD_HEAD_H) - tagH) / 2)
            local kindKey = ({ note = "UI_ZeD_Msg_KindNote", ask = "UI_ZeD_Msg_KindAnswered", err = "UI_ZeD_Msg_KindError", ticket = "UI_ZeD_Tk_KindTicket", ticketnew = "UI_ZeD_Tk_KindTicket", adminnote = "UI_ZeD_Adm_NoteHead", adminmsg = "UI_ZeD_Adm_NoteHead", server = "UI_ZeD_Srv_Server", invite = "UI_ZeD_Cl_KindInvite" })[it.k] or "UI_ZeD_Msg_KindNote"
            local kcol = (it.k == "err" and T.danger) or (it.k == "ask" and (T.warning or ac)) or (T.info or ac)
            -- (a note over your head: good news, bad news or plain, as its mark over the head said)
            if it.k == "halo" then
                kindKey = (it.tone == "good" and "UI_ZeD_Msg_KindGood") or (it.tone == "bad" and "UI_ZeD_Msg_KindBad") or "UI_ZeD_Msg_KindNote"
                kcol = (it.tone == "good" and T.positive) or (it.tone == "bad" and T.danger) or T.textDim
            end
            local kw = Mo.drawTag(self, c.x + px(U.CARD_PAD), hy, tr(kindKey), kcol)
            local meta = self.sel .. " | " .. tostring(it.when or "") .. ((it.done and it.answer) and (" | " .. tr("UI_ZeD_Msg_Answered", it.answer)) or "")
            self:drawText(A.truncateText(meta, T.fontF1, c.w - kw - px(U.CARD_PAD) * 3), c.x + px(U.CARD_PAD) * 2 + kw, c.y + math.floor((px(U.CARD_HEAD_H) - fh(T.fontF1)) / 2), td.r, td.g, td.b, td.a or 1, T.fontF1)
            A.drawDividerH(self, c.x, c.y + px(U.CARD_HEAD_H), c.w, false)
            -- the text
            local ty = c.y + px(U.CARD_HEAD_H) + px(U.CARD_PAD)
            for _, l in ipairs(c.lines) do
                if l.gap then ty = ty + px(6)
                else
                    local col = l.dim and td or ((l.font == T.fontF4) and th or tc)
                    self:drawText(l.text, c.x + px(U.CARD_PAD), ty, col.r, col.g, col.b, col.a or 1, l.font)
                    ty = ty + fh(l.font) + px(3)
                end
            end
            -- the mod's own buttons
            for bi, b in ipairs(c.btns) do
                local focused = joy and self.zone == "cards" and self:cardButtons()[self.cardFocus] == b
                local hov = (not joy) and self._hover and self._hover.btn == b
                local o = _cardBtn
                o.hover, o.focus, o.win = hov, focused and focusOpts(self) or nil, self
                o.help = (b.ticket and tr("UI_ZeD_Tk_NoteOpenHelp")) or (b.bans and tr("UI_ZeD_Adm_NoteOpenHelp")) or (b.invite and tr("UI_ZeD_Cl_NoteOpenHelp")) or (b.copy and tr("UI_ZeD_Msg_HelpCopy")) or (b.openMods and tr("UI_ZeD_Msg_HelpOpenInMods")) or tr("UI_ZeD_Msg_HelpCardButton", b.label)
                Mo.drawButton(self, b.x, b.y, b.w, b.h, b.label, b.primary and "primary" or "default", self._down == b, nil, o)
            end
        end
    end
    self:clearStencilRect()
    if #g.cards == 0 and self._cur == nil then
        Mo.drawEmptyLine(self, ca.x + px(U.PAD), ca.y + px(8), ca.w - px(U.PAD) * 2, tr("UI_ZeD_Msg_NoneHelp"))
    end
    if g.sb and g.sb.visible then g.sb:draw(self) end

    -- the band
    local f = g.band
    if g.asking then
        -- Delete asked first: the question, Cancel and Delete (the pad starts on Cancel)
        local o = _askOpts
        o.cancelFocus = (joy and self.zone == "foot" and self.footFocus == 1) and focusOpts(self) or nil
        o.verbFocus = (joy and self.zone == "foot" and self.footFocus == 2) and focusOpts(self) or nil
        o.cancelHelp, o.verbHelp, o.win = tr("UI_ZeD_Msg_HelpAskNo"), tr("UI_ZeD_Msg_HelpClear"), self
        local ask = (self._cur and self._cur.kind == "err") and tr("UI_ZeD_Msg_DeleteAskErrors") or tr("UI_ZeD_Msg_DeleteAsk")
        Mo.drawQuestionBand(self, 0, f.y, w, ask, btnLabel(tr("UI_ZeD_Msg_Clear")), o)
        return
    end
    local nb = 0
    local check = nil
    for fi, b in ipairs(g.foot) do
        local focused = joy and self.zone == "foot" and self.footFocus == fi
        local hov = (not joy) and self._hover and self._hover.foot == b
        if b.check then
            -- "Show this mod's notes as pop-ups": the band's checkbox slot
            local c = _bandCheck
            c.label, c.id, c.help = b.label, b.id, tr("UI_ZeD_Msg_HelpPopups")
            c.on = self._cur and MS.popupsFor(self._cur.name) or false
            c.hover = hov and true or false
            c.focus = focused and focusOpts(self) or nil
            check = c
        else
            nb = nb + 1
            local e = _bandBtns[nb]
            if not e then e = {}; _bandBtns[nb] = e end
            e.label, e.variant, e.id, e.help = b.label, b.primary and "primary" or "default", b.id, b.help
            e.hover, e.pressed = hov and true or false, self._down == b
            e.focus = focused and focusOpts(self) or nil
        end
    end
    for i = #_bandBtns, nb + 1, -1 do _bandBtns[i] = nil end
    _bandSpec.win, _bandSpec.check = self, check
    Mo.drawBand(self, 0, f.y, w, _bandSpec)
end

-- the help line's prompts while a controller holds the window (the help words, with the mouse)
function ZeD_MessagesWindow:getFooterPrompts()
    if not self.joyfocus then return nil end
    local P = ZeD.Prompt
    local move = P and P.padNote and P.padNote(tr("UI_ZeD_Msg_DpadMove")) or tr("UI_ZeD_Msg_DpadMove")
    -- (B answers a Delete question with No before it closes the window)
    return { move, { glyph = "A", label = tr("UI_ZeD_Msg_Choose") }, { glyph = "B", label = self.asking and tr("UI_Cancel") or getText("UI_Close") } }
end


function ZeD_MessagesWindow:render() ZeD_Window.render(self) end

-- ---------------------------------------------------------------------------
-- ACTIONS
-- ---------------------------------------------------------------------------
-- a note's Open goes to a card in a window. Under a controller the pad goes with it, as from chat's buttons, and Messages
-- closes; with the mouse Messages stays open beside it
local function openThere(self, mod, open)
    local pad = self.joyfocus ~= nil
    if pad then self:close() end
    open()
    if pad and ZeD.Chat and ZeD.Chat.padTo then ZeD.Chat.padTo(mod) end
end

function ZeD_MessagesWindow:pressCard(b)
    if not b then return end
    sound("UIActivateButton")
    if b.openMods then
        -- (the pause window opens on its Mods page, saying where the Mods screen will open: it takes the screen)
        local name = self.sel
        self:close()
        MS.openInMods(name, b.place)
        return
    end
    if b.copy then
        local text = (b.place and MS.reportPlace(self.sel, b.place)) or (b.idx and MS.reportOne(self.sel, b.idx)) or MS.report(self.sel)
        pcall(function() Clipboard.setClipboard(text) end)
        b.label = btnLabel(tr("UI_ZeD_Msg_Copied"))
        return
    end
    if b.ticket then
        openThere(self, ZeD_CharacterWindow, function()
            if ZeD.Tickets and ZeD.Tickets.openNote then ZeD.Tickets.openNote(b.card.it) end
        end)
        return
    end
    if b.bans then
        openThere(self, ZeD_WorldWindow, function()
            if ZeD.AdminCards and ZeD.AdminCards.openNote then ZeD.AdminCards.openNote(b.card.it) end
        end)
        return
    end
    if b.teleport then
        local it = b.card.it
        it.read = true
        if ZeD.MpLeftovers and ZeD.MpLeftovers.teleport then ZeD.MpLeftovers.teleport(it.tp) end
        return
    end
    if b.invite then
        openThere(self, ZeD_CharacterWindow, function()
            if ZeD_CharacterWindow and ZeD_CharacterWindow.openTab then ZeD_CharacterWindow.openTab(0, "server") end
            -- (the notes draw in the tab's list: a card left open there would hide them)
            if ZeD.Claims then ZeD.Claims.openNext = "invite" end
            b.card.it.read = true
        end)
        return
    end
    if b.noticeRun then
        -- the line's Open: with a controller Messages closes first (the thing it opens takes the controller), as above
        b.card.it.read = true
        if self.joyfocus ~= nil then self:close() end
        local ok, err = pcall(b.noticeRun)
        if not ok then ZeD.logOnce("messages: a notice's Open", err) end
        return
    end
    if b.padRun then
        -- a controller's choice: Messages closes first (the controller it was opened with lets go of it), then the
        -- game's own command runs; the note keeps what was chosen
        local it = b.card.it
        self:close()
        local ok, done = pcall(b.padRun)
        if not ok then print("[ZeD] Messages: a controller's choice: " .. tostring(done)) end
        if ok and done then it.done, it.answer, it.read = true, b.label, true end
        return
    end
    MS.press(b.card.it, b.i)
end

function ZeD_MessagesWindow:pressFoot(b)
    if not b then return end
    sound("UIActivateButton")
    local cur = self._cur
    if b.id == "popups" and cur then MS.setPopups(cur.name, not MS.popupsFor(cur.name))
    elseif b.id == "clear" and cur then
        -- deleting cannot be undone: ask first (the pad starts on Cancel)
        self.asking = true
        self.zone, self.footFocus = "foot", 1
    elseif b.id == "askyes" and cur then
        MS.clear(cur.name); self.sel = nil; self.scroll = 0; self.zone = "list"; self.asking = nil
    elseif b.id == "askno" then self:cancelAsk()
    elseif b.id == "allread" then MS.markAllRead() end
end

-- the question about Delete answered No (Cancel, B, Escape): back to the band, the pad on Delete
function ZeD_MessagesWindow:cancelAsk()
    self.asking = nil
    local cur = self._cur
    self.footFocus = (cur and cur.kind ~= "err") and 2 or 1
end

function ZeD_MessagesWindow:cardButtons()
    return (self._g and self._g.btns) or {}
end

-- ---------------------------------------------------------------------------
-- MOUSE (top-level: hit-tested here)
-- ---------------------------------------------------------------------------
function ZeD_MessagesWindow:hitAt(x, y)
    local g = self._g
    if not g then return nil end
    for _, b in ipairs(g.foot) do if inRect(b, x, y) then return { foot = b } end end
    if inRect(g.cardsArea, x, y) then
        for _, b in ipairs(g.btns) do if inRect(b, x, y) then return { btn = b } end end
        return { cards = true }
    end
    for _, r in ipairs(g.rows) do if r.src and inRect(r, x, y) then return { row = r.src.name } end end
    return nil
end

-- the close box (the window calls this on a press and release on the box)
function ZeD_MessagesWindow:closeAction()
    sound("UIActivateButton")
    self:close()
end

function ZeD_MessagesWindow:onMouseDown(x, y)
    if not self:getIsVisible() then return true end
    -- the close box and the window box answer on release (ZeD_Window:update): a press on
    -- either does not drag
    local cb = self:closeRect()
    if cb and inRect(cb, x, y) then return true end
    if inRect(self:windowBoxRect(), x, y) then return true end
    -- the cards' scrollbar
    local sb = self._sb
    if sb and sb.visible and x >= sb.x and x < sb.x + sb.width and y >= sb.y and y < sb.y + sb.height then
        sb:handleMouseDown(y - sb.y)
        return true
    end
    local h = self:hitAt(x, y)
    if h and h.row then self:choose(h.row); self.zone = "list"; sound("UISelectListItem") end
    if h and (h.btn or h.foot) then self._down = h.btn or h.foot end
    return true
end

function ZeD_MessagesWindow:onMouseUp(x, y)
    local down = self._down
    self._down = nil
    if self._sb then self._sb:handleMouseUp() end
    local h = self:hitAt(x, y)
    if down and h and h.btn == down then self:pressCard(down) end
    if down and h and h.foot == down then self:pressFoot(down) end
    return true
end

function ZeD_MessagesWindow:onMouseUpOutside(x, y)
    self._down = nil
    if self._sb then self._sb:handleMouseUp() end
end

-- a drag on the scrollbar's thumb follows the pointer, in the window or outside it
function ZeD_MessagesWindow:onMouseMove(dx, dy)
    local sb = self._sb
    if sb and sb.dragging then sb:handleMouseMove(self:getMouseY() - sb.y) end
end
function ZeD_MessagesWindow:onMouseMoveOutside(dx, dy) self:onMouseMove(dx, dy) end

function ZeD_MessagesWindow:onMouseWheel(del)
    local g = self._g
    if not g then return true end
    local maxS = math.max(0, g.contentH - g.cardsArea.h)
    self.scroll = math.max(0, math.min(maxS, self.scroll + del * ZeD.T.px(40)))
    return true
end

function ZeD_MessagesWindow:update()
    ZeD_Window.update(self)   -- the window box, the resize edges and the close box (closeAction)
    -- the scrollbar's arrows and thumb light up under the pointer; a drag follows it
    local sb = self._sb
    if sb and sb.visible then
        local mx, my = self:getMouseX(), self:getMouseY()
        if sb.dragging or (mx >= sb.x and mx < sb.x + sb.width) then sb:handleMouseMove(my - sb.y) end
        if sb.dragging and not isMouseButtonDown(0) then sb:handleMouseUp() end
    end
    local jd = JoypadState and JoypadState.players and JoypadState.players[self.playerNum + 1]
    local guest = self.guestJoy
    self.joyfocus = (jd and jd.focus == self) and jd or ((guest and guest.focus == self) and guest) or (W.qaJoy and self or nil)
    self._hover = self:hitAt(self:getMouseX(), self:getMouseY())
end

-- ---------------------------------------------------------------------------
-- KEYS: Escape closes (the prompts' key hook asks the window too: W.takeEscape)
-- ---------------------------------------------------------------------------
function ZeD_MessagesWindow:isKeyConsumed(key) return key == Keyboard.KEY_ESCAPE end
function ZeD_MessagesWindow:onKeyPress(key)
    if key == Keyboard.KEY_ESCAPE then
        if self.asking then self:cancelAsk() else self:close() end
        GameKeyboard.eatKeyPress(key)
    end
end

-- ---------------------------------------------------------------------------
-- CONTROLLER: the list, the cards' buttons, the footer
-- ---------------------------------------------------------------------------
function ZeD_MessagesWindow:onGainJoypadFocus(joypadData) self.joyfocus = joypadData end
function ZeD_MessagesWindow:onLoseJoypadFocus(joypadData) self.joyfocus = nil end

local function sourcesInOrder(self)
    local out = {}
    for _, r in ipairs((self._g and self._g.rows) or {}) do if r.src then out[#out + 1] = r.src.name end end
    return out
end

-- keep the focused card button in view
local function showButton(self, b)
    local g = self._g
    if not (g and b) then return end
    local ca = g.cardsArea
    if b.y < ca.y then self.scroll = math.max(0, self.scroll - (ca.y - b.y) - ZeD.T.px(U.PAD))
    elseif b.y + b.h > ca.y + ca.h then self.scroll = self.scroll + (b.y + b.h - (ca.y + ca.h)) + ZeD.T.px(U.PAD) end
end

function ZeD_MessagesWindow:onJoypadDown(button, joypadData)
    if button == Joypad.BButton then
        if self.asking then self:cancelAsk() else self:close() end
        return
    end
    if button ~= Joypad.AButton then return end
    if self.zone == "cards" then self:pressCard(self:cardButtons()[self.cardFocus])
    elseif self.zone == "foot" then self:pressFoot(self._g and self._g.foot[self.footFocus])
    elseif self.zone == "list" and #self:cardButtons() > 0 then self.zone = "cards"; self.cardFocus = 1; sound("UISelectListItem") end
end

function ZeD_MessagesWindow:onJoypadDirUp()
    if self.zone == "list" then
        local s = sourcesInOrder(self)
        for i, n in ipairs(s) do if n == self.sel and i > 1 then self:choose(s[i - 1]); sound("UISelectListItem"); return end end
    elseif self.zone == "cards" then
        if self.cardFocus > 1 then self.cardFocus = self.cardFocus - 1; showButton(self, self:cardButtons()[self.cardFocus]); sound("UISelectListItem") end
    elseif self.zone == "foot" then
        if #self:cardButtons() > 0 then self.zone = "cards"; self.cardFocus = #self:cardButtons() else self.zone = "list" end
        sound("UISelectListItem")
    end
end

function ZeD_MessagesWindow:onJoypadDirDown()
    if self.zone == "list" then
        local s = sourcesInOrder(self)
        for i, n in ipairs(s) do
            if n == self.sel then
                if i < #s then self:choose(s[i + 1]) else self.zone = "foot"; self.footFocus = 1 end
                sound("UISelectListItem"); return
            end
        end
        self.zone = "foot"; self.footFocus = 1
    elseif self.zone == "cards" then
        local n = #self:cardButtons()
        if self.cardFocus < n then self.cardFocus = self.cardFocus + 1; showButton(self, self:cardButtons()[self.cardFocus])
        else self.zone = "foot"; self.footFocus = 1 end
        sound("UISelectListItem")
    end
end

function ZeD_MessagesWindow:onJoypadDirRight()
    if self.zone == "list" and #self:cardButtons() > 0 then self.zone = "cards"; self.cardFocus = 1; sound("UISelectListItem")
    elseif self.zone == "foot" and self._g and self.footFocus < #self._g.foot then self.footFocus = self.footFocus + 1; sound("UISelectListItem") end
end

function ZeD_MessagesWindow:onJoypadDirLeft()
    if self.zone == "cards" then self.zone = "list"; sound("UISelectListItem")
    elseif self.zone == "foot" and self.footFocus > 1 then self.footFocus = self.footFocus - 1; sound("UISelectListItem") end
end

-- ---------------------------------------------------------------------------
-- ENTRY
-- ---------------------------------------------------------------------------
function W.open(pn, name)
    pn = pn or 0
    local win = W.windows[pn]
    if not win then
        win = ZeD_MessagesWindow:new(pn)
        win:initialise()
        win:instantiate()
        W.windows[pn] = win
    end
    if name then win:choose(name) end
    if not win:isReallyVisible() then
        win:setVisible(true)
        win:addToUIManager()
        win:setAlwaysOnTop(true)
    end
    win.zone = "list"
    MS.toasts = {}
    local jd = JoypadState.players[pn + 1]
    if jd then
        jd.focus = win
        updateJoypadFocus(jd)
    end
    return win
end

-- the window for a controller nobody plays with yet (Overrides/Controllers.lua: A on a controller's "plugged in"
-- note): player one's window, on that source, worked by that controller (it works while paused, as the game's
-- join list did); closing it lets the controller go
function W.openGuest(joypadData, name)
    if not joypadData then return nil end
    local win = W.windows[0]
    if not win then
        win = ZeD_MessagesWindow:new(0)
        win:initialise()
        win:instantiate()
        W.windows[0] = win
    end
    if name then win:choose(name) end
    if not win:isReallyVisible() then
        win:setVisible(true)
        win:addToUIManager()
        win:setAlwaysOnTop(true)
    end
    MS.toasts = {}
    win.guestJoy = joypadData
    -- the pad starts on the note's first choice when there is one
    win.zone = "list"
    if #win:cardButtons() > 0 then win.zone, win.cardFocus = "cards", 1 end
    joypadData.focus = win
    joypadData.activeWhilePaused = true
    updateJoypadFocus(joypadData)
    return win
end

function W.get(pn) return W.windows[pn or 0] end

-- Escape from anywhere (the prompts' key hook asks): the window on screen closes
function W.takeEscape()
    for _, win in pairs(W.windows) do
        if win and win:isReallyVisible() then
            if win.asking then win:cancelAsk() else win:close() end
            return true
        end
    end
    return false
end
ZeD.EscapeTakers = ZeD.EscapeTakers or {}
ZeD.EscapeTakers.messages = W.takeEscape

-- ---------------------------------------------------------------------------
-- THE NOTICES: speech balloons out of the Messages note on the belt. An element as big
-- as the balloons on show, over the note: the newest balloon lowest with its tail down to the note, the older ones
-- stacked over it. With no note on the screen (a vehicle seat, the belt given back to the game, the UI hidden) they
-- stand at the bottom middle of player one's screen, over the dash when one shows, without a tail.
-- ---------------------------------------------------------------------------
ZeD_MessagesToasts = ISUIElement:derive("ZeD_MessagesToasts")

-- pn: the player whose balloons this element shows (a notice for no one in particular is player one's)
function ZeD_MessagesToasts:new(pn)
    local o = ISUIElement.new(self, 0, 0, 1, 1)
    o.anchorLeft, o.anchorRight, o.anchorTop, o.anchorBottom = true, false, true, false
    o.playerNum = pn or 0
    o._boxes = {}
    o._list = {}
    return o
end

-- THE DASH'S NOTE (every dash gets the same Messages icon): the belt's Messages note,
-- the same box, paper and count, at the dash's top right corner while driving (the belt hides in a seat), on the
-- full dash and the Simple one, while Messages keeps anything; a click opens Messages. Notices come out of it then.
ZeD_DashNote = ISUIElement:derive("ZeD_DashNote")
local NOTE_U = 38   -- the belt's LAMP
function ZeD_DashNote:new()
    local o = ISUIElement.new(self, 0, 0, 1, 1)
    o.anchorLeft, o.anchorRight, o.anchorTop, o.anchorBottom = true, false, true, false
    return o
end
-- where it stands: the dash's top right corner, a gap above the dash (nil: no dash showing, nothing kept)
function W.dashNoteRect()
    local D = ZeD.Dashboard
    local dash = D and D.getInstance and D.getInstance()
    if not (dash and dash:getIsVisible() and MS.count() > 0) then return nil end
    local T = ZeD.T
    local s = T.px(NOTE_U)
    return dash:getX() + dash:getWidth() - s - T.px(10), dash:getY() - s - T.px(6), s, s
end
local noteTex = nil
-- shown or not, and where, before each frame draws (a hidden element gets no prerender to show itself again)
function W.dashNoteFrame()
    local note = W.dashNote
    if not note then return end
    local x, y, w, h = nil, nil, nil, nil
    if ZeD.T then x, y, w, h = W.dashNoteRect() end
    if not x then
        if note:getIsVisible() then note:setVisible(false) end
        return
    end
    if not note:getIsVisible() then note:setVisible(true) end
    if note.x ~= x then note:setX(x) end
    if note.y ~= y then note:setY(y) end
    if note.width ~= w then note:setWidth(w); note:setHeight(h) end
end
if Events and Events.OnPreUIDraw then Events.OnPreUIDraw.Add(function() pcall(W.dashNoteFrame) end) end

function ZeD_DashNote:prerender()
    local T = ZeD.T
    local x, y, w, h = nil, nil, nil, nil
    if T then x, y, w, h = W.dashNoteRect() end
    if not x then return end
    if self.x ~= x then self:setX(x) end
    if self.y ~= y then self:setY(y) end
    if self.width ~= w then self:setWidth(w); self:setHeight(h) end
    local s1, bd, ac = T.surf1, T.borderS, T.accent
    self:drawRect(0, 0, w, h, 0.92, s1.r, s1.g, s1.b)
    if self:isMouseOver() then local hv = T.hover; self:drawRect(0, 0, w, h, hv.a or 1, hv.r, hv.g, hv.b) end
    self:drawRectBorder(0, 0, w, h, 1, bd.r, bd.g, bd.b)
    if noteTex == nil then noteTex = getTexture("media/textures/ZeD/icons/msg_note.png") or false end
    if noteTex then
        local k = math.max(1, math.floor(h * 0.75 / 14))
        local iw, ih = 13 * k, 14 * k
        self:drawTextureScaledAspect(noteTex, math.floor((w - iw) / 2), math.floor((h - ih) / 2), iw, ih, 1, 1, 1, 1)
    end
    local un, err = MS.unread()
    if un > 0 then
        local t = tostring(un > 99 and "99" or un)
        local f = T.fontF1
        local pw, ph = tw(f, t) + T.px(6), fh(f) + T.px(2)
        local c = err and T.danger or ac
        local ink = T.base or { r = 0.05, g = 0.05, b = 0.05 }
        self:drawRect(w - pw, 0, pw, ph, 1, c.r, c.g, c.b)
        self:drawText(t, w - pw + T.px(3), T.px(1), ink.r, ink.g, ink.b, 1, f)
    end
end
function ZeD_DashNote:onMouseDown(x, y)
    sound("UIActivateButton")
    MS.open()
    return true
end

-- where a player's balloons come from (screen pixels), and whether they point at a note: that player's belt note,
-- else the dash's note while driving, else the bottom middle of that player's screen without a tail
function W.noticeAnchor(pn)
    pn = pn or 0
    local B = ZeD.Belt
    local ax, ay = nil, nil
    if B and B.noteAnchor then ax, ay = B.noteAnchor(pn) end
    if ax then return ax, ay - ZeD.T.px(U.NOTICE_LIFT), true end
    if pn == 0 then
        local nx, ny, nw = W.dashNoteRect()
        if nx then return nx + math.floor(nw / 2), ny - ZeD.T.px(U.NOTICE_LIFT), true end
    end
    local x = getPlayerScreenLeft(pn) + math.floor(getPlayerScreenWidth(pn) / 2)
    local y = getPlayerScreenTop(pn) + getPlayerScreenHeight(pn) - ZeD.T.px(U.NOTICE_FREE_BOTTOM)
    local D = ZeD.Dashboard
    local dash = D and D.getInstance and D.getInstance()
    if dash and dash:getIsVisible() then y = math.min(y, dash:getY() - ZeD.T.px(8)) end
    return x, y, false
end

-- the balloons' scale: the bubbles' own whole multiple (the action bar's)
local function noticeK()
    local AB = ZeD.ActionBar
    if AB and AB.k then local ok, k = pcall(AB.k); if ok and k then return k end end
    return 1
end

-- this element's player's toasts (a notice for no one in particular goes to player one; a player who is not
-- playing any more hands theirs to player one too)
function W.toastsFor(pn, all)
    local out = {}
    for _, t in ipairs(all) do
        local to = t.pn or 0
        if to ~= 0 and not getSpecificPlayer(to) then to = 0 end
        if to == pn then out[#out + 1] = t end
    end
    return out
end

-- the first balloon waits for its anchor: before the belt has drawn its Messages note the anchor falls to the bottom
-- middle with no tail, a wrong spot that shows for a moment. A balloon not yet shown is held while there is no tail
-- (NOTICE_HOLD_MS at most, then it shows as it is); once shown it stays put. true = hold it this frame.
W.NOTICE_HOLD_MS = 400
function W.noticeHold(el, tail, now)
    if tail or el._noticeShown then
        el._noticeSince = nil
        return false
    end
    el._noticeSince = el._noticeSince or now
    return now - el._noticeSince < W.NOTICE_HOLD_MS
end

function ZeD_MessagesToasts:prerender()
    local T = ZeD.T
    local pn = self.playerNum or 0
    local list = W.toastsFor(pn, MS.toasts)
    local Bb = ZeD.Bubbles
    if not T or not Bb or #list == 0 or not getPlayer() then
        if self.width > 1 then self:setWidth(1); self:setHeight(1) end
        self._boxes, self._list = {}, {}
        self._noticeShown, self._noticeSince = nil, nil
        return
    end
    Bb.syncColours(T)
    local k = noticeK()
    local ax, ay, tail = W.noticeAnchor(pn)
    if W.noticeHold(self, tail, getTimestampMs()) then
        if self.width > 1 then self:setWidth(1); self:setHeight(1) end
        self._boxes, self._list = {}, {}
        return
    end
    self._noticeShown = true
    -- each toast's balloon: its head, then where it is from and what it says (the list's own order, oldest first)
    local items = {}
    for i, t in ipairs(list) do
        -- (a bare notice, the survival guide's bubble: its head is its name already, so the text stands alone)
        local body = t.bare and tostring(t.text or "") or (tostring(t.source or "") .. ((t.text and t.text ~= "") and (" | " .. t.text) or ""))
        local lines, tw0 = Bb.noticeLines(t.head, body, t.long)
        items[i] = { lines = lines, tw = tw0, dot = (t.kind == "crit" and T.danger) or (t.kind == "info" and (T.info or T.accent)) or (T.warning or T.accent), source = t.source, toast = t }
    end
    local sl = getPlayerScreenLeft(pn)
    local sr = sl + getPlayerScreenWidth(pn)
    local x0, y0, x1, y1 = Bb.layoutNoticeBalloons(items, math.floor((sl - ax) / k), math.floor((sr - ax) / k), tail)
    local ex, ey = ax + x0 * k, ay + y0 * k
    local ew, eh = (x1 - x0) * k + k, (y1 - y0) * k + k
    if self.x ~= ex then self:setX(ex) end
    if self.y ~= ey then self:setY(ey) end
    if self.width ~= ew then self:setWidth(ew) end
    if self.height ~= eh then self:setHeight(eh) end
    -- (the click areas, in the element's pixels)
    self._boxes = {}
    for _, n in ipairs(items) do
        self._boxes[#self._boxes + 1] = { x = (n.x - x0) * k, y = (n.y - y0) * k, w = n.w * k, h = n.h * k, source = n.source, toast = n.toast }
    end
    self._list, self._ox, self._oy, self._k, self._tail = items, -x0, -y0, k, tail
end

-- (the pixel text routes its rects through this element's alpha, as the action bar's layer does)
function ZeD_MessagesToasts:drawRect(x, y, w, h, a, r, g, b)
    ISUIElement.drawRect(self, x, y, w, h, a * (self._zedAlpha or 1), r, g, b)
end

function ZeD_MessagesToasts:render()
    local list = self._list
    if not list or #list == 0 or not ZeD.Bubbles or not ZeD.Px then return end
    local k = self._k or 1
    local cv = ZeD.Px.canvas(self, self._ox * k, self._oy * k, k)
    self._zedAlpha = 1
    ZeD.Bubbles.drawNoticeBalloons(cv, ZeD.T, list, self._tail, 1)
    -- the pointer over a balloon: the hover wash on it (a click opens Messages there)
    local mx, my = self:getMouseX(), self:getMouseY()
    local hv = ZeD.T.hover
    for _, b in ipairs(self._boxes or {}) do
        if mx >= b.x and mx < b.x + b.w and my >= b.y and my < b.y + b.h then
            ISUIElement.drawRect(self, b.x + k, b.y + k, b.w - 2 * k, b.h - 2 * k, hv.a or 1, hv.r, hv.g, hv.b)
        end
    end
end

function ZeD_MessagesToasts:onMouseDown(x, y)
    for _, b in ipairs(self._boxes) do
        if y >= b.y and y < b.y + b.h and x >= b.x and x < b.x + b.w then
            sound("UIActivateButton")
            -- (a balloon that does something, the survival guide's: the click does it, and the balloon goes)
            local t = b.toast
            if t and t.run then
                MS.dropToast(t)
                local ok, err = pcall(t.run)
                if not ok then ZeD.logOnce("messages: a balloon's click", err) end
                return true
            end
            MS.open(b.source)
            return true
        end
    end
    return false
end

-- a right-click on a balloon that can be dismissed sends it away and tells its owner (the survival guide's bubble
-- then stops coming back); the plain notices have nothing to dismiss and keep their click
function ZeD_MessagesToasts:onRightMouseDown(x, y)
    for _, b in ipairs(self._boxes or {}) do
        if y >= b.y and y < b.y + b.h and x >= b.x and x < b.x + b.w and b.toast and b.toast.dismiss then
            sound("UIActivateButton")
            MS.dropToast(b.toast)
            local ok, err = pcall(b.toast.dismiss)
            if not ok then ZeD.logOnce("messages: a balloon's dismiss", err) end
            return true
        end
    end
    return false
end

-- one balloon element per player (split screen: each from its own player's note), and the dash's note
local toasts
Events.OnGameStart.Add(function()
    if toasts then return end
    toasts = {}
    for pn = 0, 3 do
        local t = ZeD_MessagesToasts:new(pn)
        t:initialise()
        t:addToUIManager()
        t:setAlwaysOnTop(true)
        toasts[pn] = t
    end
    local note = ZeD_DashNote:new()
    note:initialise()
    note:addToUIManager()
    note:setVisible(false)
    W.dashNote = note
end)
