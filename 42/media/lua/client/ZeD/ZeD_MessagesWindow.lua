-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MessagesWindow.lua
-- ============================================================================
-- THE MESSAGES WINDOW and the toasts (MESSAGES_SPEC.md; mockup
-- ZeDUI/mockups/zed_messages_v1.html, director Oct 24 2026: "notification
-- center works for me"). The store is ZeD_Messages.lua.
--
-- A ZeD window on the player's screen: the sources on the left (FROM MODS,
-- ERRORS: a dot, the name, a count), the chosen source's messages on the right
-- as cards (kind, source, when, the text as the mod wrote it, the mod's own
-- buttons), a help line, the footer (Show this mod's notes as pop-ups, Copy for
-- a bug report, Clear, Mark all read) and the strip of the keys or buttons that
-- work. Mouse and controller (D-pad between the list, the cards' buttons and
-- the footer; A presses, B closes). Toasts (Visual Catalog O12) stand on the
-- right of the screen for six seconds; a click opens the window on that source.
-- ============================================================================

require "ZeD/Tr"
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/Organisms"
require "ZeD/ZeD_Messages"

ZeD = ZeD or {}
ZeD.MessagesWindow = ZeD.MessagesWindow or {}
local W = ZeD.MessagesWindow
local MS = ZeD.Messages
W.windows = W.windows or {}

-- design units (1 px at 1080p; T.px scales them)
local U = {
    W = 760, BODY_H = 400, LIST_W = 240, ROW_H = 30, HEAD_H = 26, PAD = 10,
    CARD_GAP = 10, CARD_PAD = 10, CARD_HEAD_H = 24, HELP_H = 26, FOOT_H = 40, FOOT_PAD = 10,
    BTN_H = 24, BTN_MIN = 70, BTN_PAD = 12, CHK_GAP = 8,
    TOAST_W = 340, TOAST_H = 30, TOAST_GAP = 4, TOAST_TOP = 150, TOAST_RIGHT = 70,
}

local function fh(font) return ZeD.TM:getFontHeight(font) end
local function tw(font, s) return ZeD.TM:MeasureStringX(font, s) end
local function inRect(r, x, y) return r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end
local function sound(name) pcall(function() getSoundManager():playUISound(name or "UIActivateButton") end) end
local function tr(k, ...) return ZeD.tr(k, ...) end
local function btnLabel(s) return ZeD.btnCase and ZeD.btnCase(s) or s end

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
    o.themeFooter = false
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
    self:setVisible(false)
    self:removeFromUIManager()
    if JoypadState.players[self.playerNum + 1] then setJoypadFocus(self.playerNum, nil) end
end

-- the sources in list order, and the chosen one (the first when none or gone)
function ZeD_MessagesWindow:rows()
    local mods, errs = MS.list()
    local rows = {}
    if #mods > 0 then rows[#rows + 1] = { head = tr("UI_ZeD_Msg_FromMods") } end
    for _, s in ipairs(mods) do rows[#rows + 1] = { src = s } end
    if #errs > 0 then rows[#rows + 1] = { head = tr("UI_ZeD_Msg_Errors") } end
    for _, s in ipairs(errs) do rows[#rows + 1] = { src = s } end
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
    if self.sel ~= name then self.scroll = 0; self.cardFocus = 1 end
    self.sel = name
    if name then MS.markRead(name) end
end

-- ---------------------------------------------------------------------------
-- LAYOUT (every frame from the live tokens; local px)
-- ---------------------------------------------------------------------------
function ZeD_MessagesWindow:layout()
    local T = ZeD.T
    local px = T.px
    local g = { rows = {}, cards = {}, btns = {}, foot = {} }
    local tbH = self:titleBarHeight()
    local w = px(U.W)
    local bodyY, bodyH = tbH, px(U.BODY_H)
    local listW = px(U.LIST_W)
    local helpY, helpH = bodyY + bodyH, px(U.HELP_H)
    local footY, footH = helpY + helpH, px(U.FOOT_H)
    local stripH = T.sp.scrollbarW
    local h = footY + footH + stripH
    g.body = { y = bodyY, h = bodyH }
    g.list = { x = 0, y = bodyY, w = listW, h = bodyH }
    g.cardsArea = { x = listW, y = bodyY, w = w - listW, h = bodyH }
    g.help = { y = helpY, h = helpH }
    g.footR = { y = footY, h = footH }
    g.strip = { y = footY + footH, h = stripH }

    -- the list
    local rows, cur = self:rows()
    self._cur = cur
    local y = bodyY + px(4)
    for _, r in ipairs(rows) do
        local rh = r.head and px(U.HEAD_H) or px(U.ROW_H)
        g.rows[#g.rows + 1] = { x = px(2), y = y, w = listW - px(4), h = rh, head = r.head, src = r.src }
        y = y + rh
    end

    -- the cards (heights from the wrapped text; then scrolled)
    local cx, cw = listW + px(U.PAD), w - listW - px(U.PAD) * 2
    local inner = cw - px(U.CARD_PAD) * 2
    local cy = bodyY + px(U.PAD) - self.scroll
    local bh = px(U.BTN_H)
    for _, it in ipairs(cur and cur.items or {}) do
        local lines = {}
        local textH = 0
        if it.k == "err" then
            lines[#lines + 1] = { text = tr("UI_ZeD_Msg_ErrorCount", it.count, cur.name), font = T.fontF4 }
            for _, f in ipairs(it.firsts or {}) do
                for _, l in ipairs(ZeD.Atoms.wrapText(f, T.fontF1, inner)) do lines[#lines + 1] = { text = l, font = T.fontF1, mono = true } end
            end
        else
            for bi, bl in ipairs(blocksOf(it)) do
                if bl.kind ~= "image" then
                    local font = bl.kind == "head" and T.fontF4 or T.fontF2
                    if bi > 1 then lines[#lines + 1] = { gap = true } end
                    for _, l in ipairs(ZeD.Atoms.wrapText(bl.text, font, inner)) do lines[#lines + 1] = { text = l, font = font } end
                end
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
            btns[#btns + 1] = { label = btnLabel(tr("UI_ZeD_Msg_Copy")), copy = true, primary = true }
        end
        local ch = px(U.CARD_HEAD_H) + px(U.CARD_PAD) + textH + px(U.CARD_PAD) + (#btns > 0 and (bh + px(U.CARD_PAD)) or 0)
        local card = { x = cx, y = cy, w = cw, h = ch, it = it, lines = lines, btns = btns }
        -- buttons right-aligned, the primary last
        local bx = cx + cw - px(U.CARD_PAD)
        for bi = #btns, 1, -1 do
            local b = btns[bi]
            local bw = math.max(px(U.BTN_MIN), tw(T.fontF3, b.label) + px(U.BTN_PAD) * 2)
            bx = bx - bw
            b.x, b.y, b.w, b.h, b.card = bx, cy + ch - px(U.CARD_PAD) - bh, bw, bh, card
            bx = bx - px(6)
        end
        for _, b in ipairs(btns) do g.btns[#g.btns + 1] = b end
        g.cards[#g.cards + 1] = card
        cy = cy + ch + px(U.CARD_GAP)
    end
    g.contentH = cy + self.scroll - bodyY

    -- the footer: the switch (a mod's), then the buttons right-aligned
    local fy = footY + math.floor((footH - bh) / 2)
    local fx = px(U.FOOT_PAD)
    if cur and cur.kind ~= "err" then
        local label = tr("UI_ZeD_Msg_ShowPopups")
        local cb = T.checkboxSz
        g.foot[#g.foot + 1] = { id = "popups", x = fx, y = footY + math.floor((footH - cb) / 2), w = cb + px(U.CHK_GAP) + tw(T.fontF2, label), h = cb, label = label, check = true }
    end
    local right = {}
    if cur then right[#right + 1] = { id = "clear", label = btnLabel(tr("UI_ZeD_Msg_Clear")) } end
    right[#right + 1] = { id = "allread", label = btnLabel(tr("UI_ZeD_Msg_MarkAllRead")), primary = true }
    local rx = w - px(U.FOOT_PAD)
    for i = #right, 1, -1 do
        local b = right[i]
        local bw = math.max(px(U.BTN_MIN), tw(T.fontF3, b.label) + px(U.BTN_PAD) * 2)
        rx = rx - bw
        b.x, b.y, b.w, b.h = rx, fy, bw, bh
        rx = rx - px(6)
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
function ZeD_MessagesWindow:prerender()
    local T = ZeD.T
    if not T then return end
    self.minimumWidth, self.minimumHeight = 0, 0
    self.title = tr("UI_ZeD_Msg_Title")
    local n = MS.count()
    self.titleStats = { { text = tr("UI_ZeD_Msg_CountStat", n) } }
    local ok, err = pcall(self.layout, self)
    if not ok then ZeD.logOnce("messages window", err); self:close(); return end
    ZeD_Window.prerender(self)
    self.minimumWidth, self.minimumHeight = 0, 0
    local g = self._g
    local A, Mo = ZeD.Atoms, ZeD.Molecules
    local w = self.width
    local px = T.px
    local tc, th = T.text, T.textHead
    local ac = T.accent
    local joy = self.joyfocus ~= nil

    -- the list
    self:drawRect(px(1), g.list.y, g.list.w, g.list.h, 1, T.surf1.r, T.surf1.g, T.surf1.b)
    self:drawRect(g.list.w, g.list.y, px(1), g.list.h, 1, T.borderS.r, T.borderS.g, T.borderS.b)
    for _, r in ipairs(g.rows) do
        if r.head then
            self:drawText(ZeD.upper(r.head), r.x + px(U.PAD), r.y + math.floor((r.h - fh(T.fontF1)) / 2), ac.r, ac.g, ac.b, 1, T.fontF1)
        else
            local s = r.src
            local on = self.sel == s.name
            local focus = joy and self.zone == "list" and on
            if on then self:drawRect(r.x, r.y, r.w, r.h, focus and 0.55 or 0.35, ac.r, ac.g, ac.b)
            elseif self._hover and self._hover.row == s.name then self:drawRect(r.x, r.y, r.w, r.h, 0.18, ac.r, ac.g, ac.b) end
            local unread = 0
            for _, it in ipairs(s.items) do if not it.read then unread = unread + 1 end end
            local dsz = px(8)
            local dy = r.y + math.floor((r.h - dsz) / 2)
            local dc = (s.kind == "err" and T.danger) or (unread > 0 and ac) or nil
            if dc then A.drawStatusDot(self, r.x + px(U.PAD), dy, dc, dsz)
            else self:drawRectBorder(r.x + px(U.PAD), dy, dsz, dsz, 0.6, tc.r, tc.g, tc.b) end
            local cnt = tostring(s.kind == "err" and (s.items[1] and s.items[1].count or 0) or #s.items)
            local cw = tw(T.fontF1, cnt)
            local col = on and (T.textOnAccent or th) or tc
            local nx = r.x + px(U.PAD) + dsz + px(8)
            self:drawText(A.truncateText(s.name, T.fontF2, r.w - (nx - r.x) - cw - px(U.PAD) * 2), nx, r.y + math.floor((r.h - fh(T.fontF2)) / 2), col.r, col.g, col.b, col.a or 1, T.fontF2)
            self:drawText(cnt, r.x + r.w - px(U.PAD) - cw, r.y + math.floor((r.h - fh(T.fontF1)) / 2), col.r, col.g, col.b, 0.8, T.fontF1)
        end
    end
    if #g.rows == 0 then
        self:drawText(tr("UI_ZeD_Msg_None"), px(U.PAD), g.list.y + px(U.PAD), tc.r, tc.g, tc.b, 0.7, T.fontF2)
    end

    -- the cards (clipped to their area)
    local ca = g.cardsArea
    self:setStencilRect(ca.x, ca.y, ca.w, ca.h)
    for _, c in ipairs(g.cards) do
        if c.y + c.h >= ca.y and c.y <= ca.y + ca.h then
            local it = c.it
            self:drawRect(c.x, c.y, c.w, c.h, 1, T.surf1.r, T.surf1.g, T.surf1.b)
            self:drawRectBorder(c.x, c.y, c.w, c.h, 1, T.borderS.r, T.borderS.g, T.borderS.b)
            -- the head: kind, source, when
            local hy = c.y + math.floor((px(U.CARD_HEAD_H) - fh(T.fontF1)) / 2)
            local kindKey = ({ note = "UI_ZeD_Msg_KindNote", ask = "UI_ZeD_Msg_KindAnswered", err = "UI_ZeD_Msg_KindError" })[it.k] or "UI_ZeD_Msg_KindNote"
            local kcol = (it.k == "err" and T.danger) or (it.k == "ask" and (T.warning or ac)) or (T.info or ac)
            local kt = ZeD.upper(tr(kindKey))
            local kw = tw(T.fontF1, kt) + px(8)
            self:drawRectBorder(c.x + px(U.CARD_PAD), hy - px(1), kw, fh(T.fontF1) + px(2), 1, kcol.r, kcol.g, kcol.b)
            self:drawText(kt, c.x + px(U.CARD_PAD) + px(4), hy, kcol.r, kcol.g, kcol.b, 1, T.fontF1)
            local meta = self.sel .. " | " .. tostring(it.when or "") .. ((it.done and it.answer) and (" | " .. tr("UI_ZeD_Msg_Answered", it.answer)) or "")
            self:drawText(A.truncateText(meta, T.fontF1, c.w - kw - px(U.CARD_PAD) * 3), c.x + px(U.CARD_PAD) * 2 + kw, hy, tc.r, tc.g, tc.b, 0.75, T.fontF1)
            A.drawDividerH(self, c.x, c.y + px(U.CARD_HEAD_H), c.w, false)
            -- the text
            local ty = c.y + px(U.CARD_HEAD_H) + px(U.CARD_PAD)
            for _, l in ipairs(c.lines) do
                if l.gap then ty = ty + px(6)
                else
                    local col = (l.font == T.fontF4) and th or tc
                    self:drawText(l.text, c.x + px(U.CARD_PAD), ty, col.r, col.g, col.b, l.dim and 0.7 or (col.a or 1), l.font)
                    ty = ty + fh(l.font) + px(3)
                end
            end
            -- the buttons
            for bi, b in ipairs(c.btns) do
                local focused = joy and self.zone == "cards" and self:cardButtons()[self.cardFocus] == b
                local hov = self._hover and self._hover.btn == b
                local colors = (hov or focused) and { fill = { r = ac.r, g = ac.g, b = ac.b, a = focused and 0.55 or 0.22 } } or nil
                Mo.drawButton(self, b.x, b.y, b.w, b.h, b.label, b.primary and "primary" or "default", self._down == b, colors)
            end
        end
    end
    self:clearStencilRect()
    if #g.cards == 0 and self._cur == nil then
        self:drawText(tr("UI_ZeD_Msg_NoneHelp"), ca.x + px(U.PAD), ca.y + px(U.PAD), tc.r, tc.g, tc.b, 0.7, T.fontF2)
    end

    -- the help line
    local s2 = T.surf2
    A.drawDividerH(self, px(1), g.help.y, w - px(2), false)
    self:drawText(A.truncateText(tr("UI_ZeD_Msg_Help"), T.fontF1, w - px(U.PAD) * 2), px(U.PAD), g.help.y + math.floor((g.help.h - fh(T.fontF1)) / 2), tc.r, tc.g, tc.b, 0.75, T.fontF1)

    -- the footer
    local f = g.footR
    self:drawRect(px(1), f.y, w - px(2), f.h, s2.a or 1, s2.r, s2.g, s2.b)
    A.drawDividerH(self, px(1), f.y, w - px(2), false)
    for fi, b in ipairs(g.foot) do
        local focused = joy and self.zone == "foot" and self.footFocus == fi
        local hov = self._hover and self._hover.foot == b
        if b.check then
            local on = self._cur and MS.popupsFor(self._cur.name) or false
            if focused then self:drawRect(b.x - px(4), b.y - px(4), b.w + px(8), b.h + px(8), 0.55, ac.r, ac.g, ac.b) end
            A.drawCheckbox(self, b.x, b.y, on, hov, false)
            self:drawText(b.label, b.x + T.checkboxSz + px(U.CHK_GAP), b.y + math.floor((b.h - fh(T.fontF2)) / 2), tc.r, tc.g, tc.b, 1, T.fontF2)
        else
            local colors = (hov or focused) and { fill = { r = ac.r, g = ac.g, b = ac.b, a = focused and 0.55 or 0.22 } } or nil
            Mo.drawButton(self, b.x, b.y, b.w, b.h, b.label, b.primary and "primary" or "default", self._down == b, colors)
        end
    end
    -- the strip
    local st = g.strip
    self:drawRect(px(1), st.y, w - px(2), st.h, s2.a or 1, s2.r, s2.g, s2.b)
    A.drawDividerH(self, px(1), st.y, w - px(2), false)
    Mo.drawGlyphPrompts(self, T.sp.sm, st.y, st.h, self:stripPrompts())
end

function ZeD_MessagesWindow:stripPrompts()
    if self.joyfocus then
        return { tr("UI_ZeD_Msg_DpadMove"), { glyph = "A", label = tr("UI_ZeD_Msg_Choose") }, { glyph = "B", label = getText("UI_Close") } }
    end
    return { { glyph = "ESC", label = getText("UI_Close") } }
end

function ZeD_MessagesWindow:render() ZeD_Window.render(self) end

-- ---------------------------------------------------------------------------
-- ACTIONS
-- ---------------------------------------------------------------------------
function ZeD_MessagesWindow:pressCard(b)
    if not b then return end
    sound("UIActivateButton")
    if b.copy then
        pcall(function() Clipboard.setClipboard(MS.report(self.sel)) end)
        b.label = btnLabel(tr("UI_ZeD_Msg_Copied"))
        return
    end
    MS.press(b.card.it, b.i)
end

function ZeD_MessagesWindow:pressFoot(b)
    if not b then return end
    sound("UIActivateButton")
    local cur = self._cur
    if b.id == "popups" and cur then MS.setPopups(cur.name, not MS.popupsFor(cur.name))
    elseif b.id == "clear" and cur then MS.clear(cur.name); self.sel = nil; self.scroll = 0; self.zone = "list"
    elseif b.id == "allread" then MS.markAllRead() end
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

function ZeD_MessagesWindow:onMouseDown(x, y)
    if not self:getIsVisible() then return true end
    local cb = self:closeRect()
    if cb and inRect(cb, x, y) then self._down = "close"; return true end
    local h = self:hitAt(x, y)
    if h and h.row then self:choose(h.row); self.zone = "list"; sound("UISelectListItem") end
    if h and (h.btn or h.foot) then self._down = h.btn or h.foot end
    return true
end

function ZeD_MessagesWindow:onMouseUp(x, y)
    local down = self._down
    self._down = nil
    if down == "close" then
        local cb = self:closeRect()
        if cb and inRect(cb, x, y) then sound("UIActivateButton"); self:close() end
        return true
    end
    local h = self:hitAt(x, y)
    if down and h and h.btn == down then self:pressCard(down) end
    if down and h and h.foot == down then self:pressFoot(down) end
    return true
end

function ZeD_MessagesWindow:onMouseUpOutside(x, y) self._down = nil end

function ZeD_MessagesWindow:onMouseWheel(del)
    local g = self._g
    if not g then return true end
    local maxS = math.max(0, g.contentH - g.cardsArea.h)
    self.scroll = math.max(0, math.min(maxS, self.scroll + del * ZeD.T.px(40)))
    return true
end

function ZeD_MessagesWindow:update()
    ISPanel.update(self)
    local jd = JoypadState and JoypadState.players and JoypadState.players[self.playerNum + 1]
    self.joyfocus = (jd and jd.focus == self) and jd or (W.qaJoy and self or nil)
    self._hover = self:hitAt(self:getMouseX(), self:getMouseY())
end

-- ---------------------------------------------------------------------------
-- KEYS: Escape closes (the prompts' key hook asks the window too: W.takeEscape)
-- ---------------------------------------------------------------------------
function ZeD_MessagesWindow:isKeyConsumed(key) return key == Keyboard.KEY_ESCAPE end
function ZeD_MessagesWindow:onKeyPress(key)
    if key == Keyboard.KEY_ESCAPE then self:close(); GameKeyboard.eatKeyPress(key) end
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
    if button == Joypad.BButton then self:close(); return end
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

function W.get(pn) return W.windows[pn or 0] end

-- Escape from anywhere (the prompts' key hook asks): the window on screen closes
function W.takeEscape()
    for _, win in pairs(W.windows) do
        if win and win:isReallyVisible() then win:close(); return true end
    end
    return false
end
ZeD.EscapeTakers = ZeD.EscapeTakers or {}
ZeD.EscapeTakers.messages = W.takeEscape

-- ---------------------------------------------------------------------------
-- THE TOASTS (O12): a top-level strip sized to the toasts on show
-- ---------------------------------------------------------------------------
ZeD_MessagesToasts = ISUIElement:derive("ZeD_MessagesToasts")

function ZeD_MessagesToasts:new()
    local o = ISUIElement.new(self, 0, 0, 1, 1)
    o.anchorLeft, o.anchorRight, o.anchorTop, o.anchorBottom = true, false, true, false
    o._boxes = {}
    return o
end

function ZeD_MessagesToasts:prerender()
    local T = ZeD.T
    local list = MS.toasts
    if not T or #list == 0 or not getPlayer() then
        if self.width > 1 then self:setWidth(1); self:setHeight(1) end
        self._boxes = {}
        return
    end
    local px = T.px
    local w, bh, gap = px(U.TOAST_W), px(U.TOAST_H), px(U.TOAST_GAP)
    local h = #list * (bh + gap) - gap
    local x = getPlayerScreenLeft(0) + getPlayerScreenWidth(0) - px(U.TOAST_RIGHT) - w
    local y = getPlayerScreenTop(0) + px(U.TOAST_TOP)
    if self.x ~= x then self:setX(x) end
    if self.y ~= y then self:setY(y) end
    if self.width ~= w then self:setWidth(w) end
    if self.height ~= h then self:setHeight(h) end
    self._boxes = {}
    local A = ZeD.Atoms
    for i, t in ipairs(list) do
        local by = (i - 1) * (bh + gap)
        local c = (t.kind == "crit" and T.danger) or (T.warning or T.accent)
        local b = T.base or { r = 0.05, g = 0.05, b = 0.05 }
        self:drawRect(0, by, w, bh, 0.92, b.r, b.g, b.b)
        self:drawRectBorder(0, by, w, bh, 1, c.r, c.g, c.b)
        local hx = px(10)
        local head = ZeD.upper(tostring(t.head or ""))
        local fy1 = by + math.floor((bh - fh(T.fontF1)) / 2)
        self:drawText(head, hx, fy1, c.r, c.g, c.b, 1, T.fontF1)
        local tx = hx + tw(T.fontF1, head) + px(8)
        local body = tostring(t.source or "") .. ((t.text and t.text ~= "") and (" | " .. t.text) or "")
        local tc = T.text
        self:drawText(A.truncateText(body, T.fontF2, w - tx - px(10)), tx, by + math.floor((bh - fh(T.fontF2)) / 2), tc.r, tc.g, tc.b, 1, T.fontF2)
        self._boxes[#self._boxes + 1] = { y = by, h = bh, source = t.source }
    end
end

function ZeD_MessagesToasts:onMouseDown(x, y)
    for _, b in ipairs(self._boxes) do
        if y >= b.y and y < b.y + b.h and x >= 0 and x < self.width then
            sound("UIActivateButton")
            MS.open(b.source)
            return true
        end
    end
    return false
end

local toasts
Events.OnGameStart.Add(function()
    if toasts then return end
    toasts = ZeD_MessagesToasts:new()
    toasts:initialise()
    toasts:addToUIManager()
    toasts:setAlwaysOnTop(true)
end)
