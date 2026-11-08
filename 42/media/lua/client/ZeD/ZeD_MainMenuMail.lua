-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuMail.lua
-- ============================================================================
-- MAIL ON THE DESK: the main menu's mail window. Client-side; an organism, a ZeD window on the desktop's monitor.
-- The model is early-90s email: dial in, mail moves both ways, hang up, read offline. At the main menu the game is
-- connected to no server, so everything here is the copy on this computer (ZeD_MailStore.lua): the letters handed
-- over at the last join to each server, and an Outbox that goes at the next one (ZeD_Mail.lua does the dial-in in
-- game). Reading and writing are offline, as they were.
--
-- A ZeD window on the monitor: on the left the mailbox (one for each server and name joined with, a pop-up when there
-- is more than one), the folders as tabs (Inbox, Outbox, Sent) and the folder's letters; on the right the letter, or the
-- new one being written (To, Subject, the letter). The band: New letter, Reply, Delete, and the last dial-in; while
-- writing, Cancel and Put in Outbox. Delete asks first and lands on Cancel; Cancel on a letter with words asks too.
-- Nobody has dialed in yet: the window says how mail comes.
--
-- Reply quotes the letter with "> " at the start of each line, as mail of the time did.
-- ============================================================================

require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MainMenuSaves"
require "ZeD/ZeD_MainMenuDesktop"
require "ZeD/ZeD_MainMenuNotes"
require "ZeD/ZeD_MailProto"
require "ZeD/ZeD_MailStore"

local MM = ZeD.MainMenu
local U  = MM.U
local UI = MM.ui
local MS = ZeD.MailStore
local Ml = ZeD.Ml

-- design units
local LIST_SHARE = 0.4
local ROW_H, DROP_H, FIELD_H, LABEL_W = 40, 26, 26, 72
local QUOTE_MAX = 600               -- characters of a letter quoted in a reply
local MONTHS = MM.MONTHS

local function tr(k, ...) return ZeD.tr(k, ...) end
local FOLDERS = { "inbox", "outbox", "sent" }
local FOLDER_WORD = { inbox = "UI_ZeD_Mail_Inbox", outbox = "UI_ZeD_Mail_Outbox", sent = "UI_ZeD_Mail_Sent" }

-- "Nov 7, 9:42 PM" on this computer's clock; borrows the ticket cards' date words when that file is loaded
local function when(sec)
    if type(sec) ~= "number" or sec <= 0 then return "" end
    local TCd = ZeD.TicketCards and ZeD.TicketCards._D
    if TCd and TCd.realDate then
        local ok, s = pcall(TCd.realDate, sec)
        if ok and s then return s end
    end
    local ok, d = pcall(os.date, "*t", sec)
    if not ok or type(d) ~= "table" then return "" end
    return tr(MONTHS[d.month or 1] or MONTHS[1]) .. " " .. tostring(d.day or 1) .. ", " .. string.format("%02d:%02d", d.hour or 0, d.min or 0)
end
MM.mailWhen = when

-- every mailbox's unread letters together (the desktop's icon shows the count)
local _unread = { seq = -1, n = 0 }
function MM.mailUnread()
    if _unread.seq == MS.seq then return _unread.n end
    local n = 0
    for _, b in ipairs(MS.boxes()) do n = n + MS.unread(b) end
    _unread.seq, _unread.n = MS.seq, n
    return n
end

-- ============================================================================
-- THE DESKTOP'S ICON AND THE ZeD MENU'S ITEM
-- ============================================================================
function MM.openMail()
    MM.ctx.open = nil
    MM.showView("mail")
end

-- The app is "ProtoPOP3 Mail" on the desk — the icon, the window and the menu; the in-game cards say Mail.
local MAIL_ITEM = { id = "mail", menu = "UI_ZeD_Mail_AppName", open = function() MM.openMail() end }
MAIL_ITEM.labelFn = function()
    local n = MM.mailUnread()
    if n > 0 then return tr("UI_ZeD_Mail_IconNew", n) end
    return tr("UI_ZeD_Mail_AppName")
end
MM.leftApps = MM.leftApps or {}
do
    local have = false
    for _, a in ipairs(MM.leftApps) do if a.id == "mail" then have = true end end
    if not have then MM.leftApps[#MM.leftApps + 1] = MAIL_ITEM end
end

-- ============================================================================
-- THE WINDOW
-- ============================================================================
ZeD_MMMail = ZeD_MMWindow:derive("ZeD_MMMail")

function ZeD_MMMail:new()
    local o = ZeD_MMWindow.new(self, "mail")
    o.noResetControl = true
    o.boxKey = nil          -- the mailbox shown
    o.folder = "inbox"
    o.sel = nil             -- the letter shown (the table itself)
    o.lscroll, o.rscroll = 0, 0
    o.compose = nil         -- { to, subj, text (the seeds) } while writing
    o.confirm = false       -- false | "delete" | "discard"
    o.note = nil            -- a line for the band (the Outbox full, a letter put in it)
    return o
end

function ZeD_MMMail:createChildren()
    ZeD_Window.createChildren(self)
    self.toEntry = UI.newEntry(self)
    self.toEntry:setMaxTextLength(Ml.L.TO_MAX)
    self.subjEntry = UI.newEntry(self)
    self.subjEntry:setMaxTextLength(Ml.L.SUBJ_MAX)
    self.textEntry = UI.newEntry(self)
    self.textEntry:setMultipleLine(true)
    self.textEntry:setMaxLines(200)
    self.textEntry:setMaxTextLength(Ml.L.TEXT_MAX)
    for _, e in ipairs({ self.toEntry, self.subjEntry, self.textEntry }) do
        e.onEscape = function() e:unfocus() end
        e.onTextChange = function() self.note = nil end
        e:setVisible(false)
    end
end

function ZeD_MMMail:box()
    local list = MS.boxes()
    if self.boxKey then
        local b = MS.find(self.boxKey)
        if b then return b end
    end
    local b = list[1]
    self.boxKey = b and b.key or nil
    return b
end

function ZeD_MMMail:letters()
    local b = self:box()
    if not b then return {} end
    return MS.load(b)[self.folder] or {}
end

function ZeD_MMMail:onShow()
    self.confirm = false
    self.note = nil
    if not self.compose then self:showFields(false) end
    local list = self:letters()
    local keep = false
    for _, m in ipairs(list) do if m == self.sel then keep = true end end
    if not keep then self.sel = nil end
    self.focusId = self.compose and "f:to" or (self.sel and "row:sel" or "tab:" .. self.folder)
end

function ZeD_MMMail:showFields(on)
    for _, e in ipairs({ self.toEntry, self.subjEntry, self.textEntry }) do
        if e:isVisible() ~= on then e:setVisible(on) end
        if not on and e:isFocused() then e:unfocus() end
    end
end

-- ACTIONS ---------------------------------------------------------------------

function ZeD_MMMail:pickFolder(f)
    if self.folder == f then return end
    self.folder, self.sel, self.lscroll, self.rscroll = f, nil, 0, 0
    MM.hoverSound()
end

function ZeD_MMMail:pick(m)
    self.sel, self.rscroll = m, 0
    local b = self:box()
    if b and self.folder == "inbox" then MS.markRead(b, m) end
    MM.hoverSound()
end

function ZeD_MMMail:pickBox()
    local items = {}
    for _, b in ipairs(MS.boxes()) do
        local key = b.key
        items[#items + 1] = { text = tr("UI_ZeD_Mail_BoxName", b.user, b.server), check = key == self.boxKey, fn = function()
            self.boxKey, self.sel, self.lscroll, self.rscroll = key, nil, 0, 0
        end }
    end
    for _, s in ipairs(self._specs) do
        if s.id == "box" then
            MM.openPopup("mailboxes", items, { x = self:getAbsoluteX() + s.x, y = self:getAbsoluteY() + s.y, w = s.w, h = s.h }, false)
            return
        end
    end
end

function ZeD_MMMail:startCompose(to, subj, text)
    self.compose = { to = to or "", subj = subj or "", text = text or "" }
    self.toEntry:setText(to or "")
    self.subjEntry:setText(subj or "")
    self.textEntry:setText(text or "")
    self:showFields(true)
    self.note = nil
    self.focusId = (to and to ~= "") and "f:text" or "f:to"
    MM.clickSound()
end

function ZeD_MMMail:reply()
    local m = self.sel
    if not (m and self.folder == "inbox" and not m.returned and m.from ~= "") then return end
    local subj = m.subj or ""
    if string.sub(string.lower(subj), 1, 4) ~= "re: " then subj = "Re: " .. subj end
    if #subj > Ml.L.SUBJ_MAX then subj = string.sub(subj, 1, Ml.L.SUBJ_MAX) end
    local body = m.text or ""
    if #body > QUOTE_MAX then body = string.sub(body, 1, QUOTE_MAX) .. "..." end
    local quoted = "> " .. string.gsub(body, "\n", "\n> ")
    self:startCompose(m.from, subj, "\n\n" .. tr("UI_ZeD_Mail_Wrote", m.from) .. "\n" .. quoted)
    pcall(function() self.textEntry:setCursorPos(0) end)
end

function ZeD_MMMail:composeWords()
    return self.toEntry:getText() or "", self.subjEntry:getText() or "", self.textEntry:getText() or ""
end

-- why Put in Outbox is gray, or nil
function ZeD_MMMail:putWhy()
    local b = self:box()
    if not b then return tr("UI_ZeD_Mail_NoBoxes") end
    local to, subj, text = self:composeWords()
    if #MS.load(b).outbox >= MS.OUT_MAX then return tr("UI_ZeD_Mail_OutboxFull", MS.OUT_MAX) end
    if not Ml.line(to, Ml.L.TO_MAX) then return tr("UI_ZeD_Mail_NeedTo") end
    if not Ml.subject(subj) then return tr("UI_ZeD_Mail_SubjLong", Ml.L.SUBJ_MAX) end
    local clean = ZeD.Tk and ZeD.Tk.clean(text) or text
    if not clean or clean == "" then return tr("UI_ZeD_Mail_NeedText") end
    if #clean > Ml.L.TEXT_MAX then return tr("UI_ZeD_Mail_TooLong", Ml.L.TEXT_MAX) end
    return nil
end

function ZeD_MMMail:put()
    if self:putWhy() then return end
    local b = self:box()
    local to, subj, text = self:composeWords()
    local m, err = MS.queue(b, to, subj, text)
    if not m then self.note = tr("UI_ZeD_Mail_OutboxFull", MS.OUT_MAX); return end
    self.compose = nil
    self:showFields(false)
    self.folder, self.sel, self.lscroll = "outbox", m, 0
    self.note = tr("UI_ZeD_Mail_Queued", b.server)
    self.focusId = "new"
    MM.clickSound()
end

function ZeD_MMMail:cancelCompose(force)
    local to, subj, text = self:composeWords()
    local c = self.compose or {}
    local changed = to ~= (c.to or "") or subj ~= (c.subj or "") or text ~= (c.text or "")
    if changed and not force then self:setConfirm("discard"); return end
    self.compose = nil
    self:showFields(false)
    self:setConfirm(false)
    self.focusId = "new"
end

function ZeD_MMMail:delete()
    local b, m = self:box(), self.sel
    if b and m then MS.remove(b, self.folder, m) end
    self.sel = nil
    self:setConfirm(false)
end

function ZeD_MMMail:setConfirm(mode)
    if self.confirm == mode then return end
    self.confirm = mode
    MM.clickSound()
    if mode then
        for _, e in ipairs({ self.toEntry, self.subjEntry, self.textEntry }) do if e:isFocused() then e:unfocus() end end
        self.focusId = "confirm:no"            -- a question that loses work lands on Cancel
    else
        self.focusId = self.compose and "f:text" or "new"
    end
end

function ZeD_MMMail:close()
    if self.confirm then self:setConfirm(false); return end
    if self.compose then self:cancelCompose(false); if self.compose then return end end
    MM.clickSound()
    MM.showView("desktop")
end
function ZeD_MMMail:back() self:close() end

-- LAYOUT + DRAWING ---------------------------------------------------------------

function ZeD_MMMail:prerender()
    local T = ZeD.T
    self._specs, self._hits = {}, {}
    local w, h = UI.placeOnTube(self)
    local b = self:box()
    self.title = tr("UI_ZeD_Mail_AppName")
    self.titleStats = b and { { text = tr("UI_ZeD_Mail_BoxName", b.user, b.server), noMark = true } } or {}
    ZeD_Window.prerender(self)
    local tb = T.titleBarH
    local pad = T.px(U.STACK_PAD)
    local stripH = MM.bandH()
    local stripY = h - self:footerHeight() - stripH
    local bodyY, bodyH = tb + pad, stripY - tb - pad * 2
    if not b then
        self:showFields(false)
        self:drawNone(pad, bodyY, w - pad * 2, bodyH)
    else
        local lw = math.floor((w - pad * 3) * LIST_SHARE)
        self:drawLeft(b, pad, bodyY, lw, bodyH)
        local rx = pad * 2 + lw
        if self.compose then self:drawCompose(rx, bodyY, w - rx - pad, bodyH)
        else
            self:showFields(false)
            self:drawLetter(b, rx, bodyY, w - rx - pad, bodyH)
        end
    end
    self:buildBand(b, stripY, w)
end

function ZeD_MMMail:render()
    UI.drawStripAndButtons(self)
    ZeD_Window.render(self)
end

-- nobody has dialed in: how mail comes
function ZeD_MMMail:drawNone(x, y, w, h)
    local T = ZeD.T
    UI.insetBox(self, x, y, w, h)
    local c, d = T.text, T.textDim
    local cy = y + T.px(16)
    self:drawText(tr("UI_ZeD_Mail_NoBoxes"), x + T.px(16), cy, c.r, c.g, c.b, c.a or 1, T.fontF4)
    cy = cy + MM.fontH(T.fontF4) + T.px(10)
    for _, l in ipairs(ZeD.Atoms.wrapText(tr("UI_ZeD_Mail_NoBoxesHow"), T.fontF2, w - T.px(32))) do
        self:drawText(l, x + T.px(16), cy, d.r, d.g, d.b, d.a or 1, T.fontF2)
        cy = cy + MM.fontH(T.fontF2) + T.px(2)
    end
end

function ZeD_MMMail:drawLeft(b, x, y, w, h)
    local T = ZeD.T
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local gp = MM.gamepad()
    -- the mailbox: a pop-up when there is more than one
    local dh = T.px(DROP_H)
    local many = #MS.boxes() > 1
    local hid = "mail:box"
    MM.drawDropBox(self, x, y, w, dh, tr("UI_ZeD_Mail_BoxName", b.user, b.server), (not gp) and MM.ctx.hot == hid, not many, gp and self.focusId == "box", self)
    self._specs[#self._specs + 1] = { id = "box", listRow = true, row = 10, col = 1, x = x, y = y, w = w, h = dh, disabled = not many,
                                      fn = function() self:pickBox() end, help = tr("UI_ZeD_Mail_HelpBox") }
    if many then self._hits[#self._hits + 1] = { id = hid, x = ax + x, y = ay + y, w = w, h = dh, fn = function() self:pickBox() end } end
    -- the folders as tabs
    local ty = y + dh + T.px(8)
    local tx = x
    for i, f in ipairs(FOLDERS) do
        local n = (f == "inbox") and MS.unread(b) or #(MS.load(b)[f] or {})
        local label = tr(FOLDER_WORD[f])
        if n > 0 then label = label .. " (" .. tostring(n) .. ")" end
        local thid = "mail:tab:" .. f
        local tw = ZeD.Molecules.drawTab(self, tx, ty, label, self.folder == f, (not gp) and MM.ctx.hot == thid, false,
            (gp and self.focusId == "tab:" .. f) and { focus = MM.focusOpts(self) } or nil)
        self._hits[#self._hits + 1] = { id = thid, x = ax + tx, y = ay + ty, w = tw, h = T.tabH, fn = function() self:pickFolder(f) end }
        self._specs[#self._specs + 1] = { id = "tab:" .. f, listRow = true, row = 20, col = i, x = tx, y = ty, w = tw, h = T.tabH, fn = function() self:pickFolder(f) end }
        tx = tx + tw + T.sp.tabGap
    end
    -- the letters
    local ly = ty + T.tabH
    local lh = y + h - ly
    UI.insetBox(self, x, ly, w, lh)
    local list = self:letters()
    local rh = T.px(ROW_H)
    local total = #list * rh
    self.lscroll = math.max(0, math.min(self.lscroll, math.max(0, total - lh + T.px(2))))
    local sbw = (total > lh) and T.sp.scrollbarW or 0
    self._list = { x = x, y = ly, w = w, h = lh }
    if #list == 0 then
        ZeD.Molecules.drawEmptyLine(self, x + T.px(8), ly + T.px(8), w - T.px(16), tr("UI_ZeD_Mail_EmptyFolder"))
        return
    end
    self:setStencilRect(x + T.px(1), ly + T.px(1), w - T.px(2), lh - T.px(2))
    local f2, f3 = T.fontF2, T.fontF3
    for i, m in ipairs(list) do
        local ry = ly + T.px(1) + (i - 1) * rh - self.lscroll
        local rw = w - T.px(2) - sbw
        local id = "row:" .. tostring(i)
        local isSel = m == self.sel
        local inView = ry + rh > ly and ry < ly + lh
        if inView then
            local rhid = "mail:" .. id
            local onF = MM.rowLook(self, x + T.px(1), ry, rw, rh, isSel, (not gp) and MM.ctx.hot == rhid, gp and (self.focusId == id or (self.focusId == "row:sel" and isSel)), self)
            local c = onF and T.textOnFocus or T.text
            local d = onF and T.textOnFocus or T.textDim
            local who
            if self.folder == "inbox" then who = m.returned and tr("UI_ZeD_Mail_Returned") or m.from
            else who = tr("UI_ZeD_Mail_ToName", m.to) end
            local nx = x + T.px(10)
            if self.folder == "inbox" and not m.read then
                local dsz = T.px(7)
                ZeD.Atoms.drawStatusDot(self, nx, ry + T.px(6) + math.floor((MM.fontH(f2) - dsz) / 2), T.accent, dsz)
                nx = nx + dsz + T.px(6)
            end
            local date = when(m.t)
            local dw = MM.textW(f3, date)
            self:drawText(date, x + rw - T.px(8) - dw, ry + T.px(6), d.r, d.g, d.b, d.a or 1, f3)
            self:drawText(ZeD.Atoms.truncateText(who, f2, x + rw - T.px(16) - dw - nx), nx, ry + T.px(5), c.r, c.g, c.b, c.a or 1, f2)
            local subj = (m.subj ~= "" and m.subj) or tr("UI_ZeD_Mail_NoSubject")
            self:drawText(ZeD.Atoms.truncateText(subj, f3, rw - T.px(20)), x + T.px(10), ry + T.px(6) + MM.fontH(f2), d.r, d.g, d.b, d.a or 1, f3)
            local vy0, vy1 = math.max(ry, ly), math.min(ry + rh, ly + lh)
            if vy1 > vy0 then self._hits[#self._hits + 1] = { id = rhid, x = ax + x, y = ay + vy0, w = rw, h = vy1 - vy0, fn = function() self:pick(m); self.focusId = id end } end
        end
        self._specs[#self._specs + 1] = { id = id, listRow = true, listId = "letters", clip = self._list, row = 100 + i, col = 1, x = x, y = ry, w = rw, h = rh,
                                          chosen = isSel, fn = function() self:pick(m) end }
        if self.focusId == "row:sel" and isSel then self.focusId = id end
    end
    self:clearStencilRect()
    if sbw > 0 then
        MM.scrollBar(self, "mail:list", x + w - sbw - T.px(1), ly + T.px(1), sbw, lh - T.px(2), self.lscroll, total, function(v) self.lscroll = v end, { step = rh })
    end
end

-- a label and its value on one line of the letter's head
local function headLine(p, x, y, w, label, value)
    local T = ZeD.T
    local d, c = T.textDim, T.text
    p:drawText(label, x, y, d.r, d.g, d.b, d.a or 1, T.fontF3)
    p:drawText(ZeD.Atoms.truncateText(value or "", T.fontF2, w - T.px(LABEL_W)), x + T.px(LABEL_W), y, c.r, c.g, c.b, c.a or 1, T.fontF2)
    return y + MM.fontH(T.fontF2) + T.px(4)
end

function ZeD_MMMail:drawLetter(b, x, y, w, h)
    local T = ZeD.T
    UI.insetBox(self, x, y, w, h)
    local m = self.sel
    self._read = { x = x, y = y, w = w, h = h }
    if not m then
        ZeD.Molecules.drawEmptyLine(self, x + T.px(12), y + T.px(12), w - T.px(24), tr("UI_ZeD_Mail_PickLetter"))
        return
    end
    local ix, iw = x + T.px(12), w - T.px(24)
    local cy = y + T.px(10)
    if self.folder == "inbox" then
        cy = headLine(self, ix, cy, iw, tr("UI_ZeD_Mail_From"), m.returned and tr("UI_ZeD_Mail_Returned") or m.from)
        cy = headLine(self, ix, cy, iw, tr("UI_ZeD_Mail_To"), m.to)
    else
        cy = headLine(self, ix, cy, iw, tr("UI_ZeD_Mail_To"), m.to)
    end
    cy = headLine(self, ix, cy, iw, tr("UI_ZeD_Mail_Date"), when(m.t))
    cy = headLine(self, ix, cy, iw, tr("UI_ZeD_Mail_Subject"), (m.subj ~= "" and m.subj) or tr("UI_ZeD_Mail_NoSubject"))
    if self.folder == "outbox" then
        local wc = T.warning
        self:drawText(ZeD.Atoms.truncateText(tr("UI_ZeD_Mail_Waiting", b.server), T.fontF3, iw), ix, cy, wc.r, wc.g, wc.b, wc.a or 1, T.fontF3)
        cy = cy + MM.fontH(T.fontF3) + T.px(4)
    end
    ZeD.Atoms.drawDividerH(self, x + T.px(1), cy + T.px(2), w - T.px(2), true)
    cy = cy + T.px(8)
    -- the words (drawText only: a letter is never read as the game's rich text)
    local top, bot = cy, y + h - T.px(4)
    local lineH = MM.fontH(T.fontF2) + T.px(2)
    local lines = {}
    for _, para in ipairs(self:paras(m.text or "")) do
        if para == "" then lines[#lines + 1] = "" else
            for _, l in ipairs(ZeD.Atoms.wrapText(para, T.fontF2, iw)) do lines[#lines + 1] = l end
        end
    end
    local total = #lines * lineH
    self.rscroll = math.max(0, math.min(self.rscroll, math.max(0, total - (bot - top))))
    self._readText = { x = x, y = top, w = w, h = bot - top }
    self:setStencilRect(x + T.px(1), top, w - T.px(2), bot - top)
    local c = T.text
    for i, l in ipairs(lines) do
        local ly = top + (i - 1) * lineH - self.rscroll
        if ly + lineH > top and ly < bot then self:drawText(l, ix, ly, c.r, c.g, c.b, c.a or 1, T.fontF2) end
    end
    self:clearStencilRect()
    if total > bot - top then
        local sbw = T.sp.scrollbarW
        MM.scrollBar(self, "mail:read", x + w - sbw - T.px(1), top, sbw, bot - top, self.rscroll, total, function(v) self.rscroll = v end, { step = lineH })
    end
end

function ZeD_MMMail:paras(text)
    local out, from = {}, 1
    while true do
        local at = string.find(text, "\n", from, true)
        if not at then out[#out + 1] = string.sub(text, from); break end
        out[#out + 1] = string.sub(text, from, at - 1)
        from = at + 1
    end
    return out
end

function ZeD_MMMail:drawCompose(x, y, w, h)
    local T = ZeD.T
    UI.insetBox(self, x, y, w, h)
    self._read = nil
    local ix, iw = x + T.px(12), w - T.px(24)
    local fh = T.px(FIELD_H)
    local d = T.textDim
    local cy = y + T.px(10)
    local fx, fw = ix + T.px(LABEL_W), iw - T.px(LABEL_W)
    local function field(id, label, e, fy, fhh, row)
        self:drawText(label, ix, fy + math.floor((math.min(fhh, fh) - MM.fontH(T.fontF3)) / 2), d.r, d.g, d.b, d.a or 1, T.fontF3)
        UI.styleEntry(e, fx, fy, fw, fhh)
        self._specs[#self._specs + 1] = { id = id, listRow = true, noDraw = true, row = row, col = 2, x = fx, y = fy, w = fw, h = fhh,
                                          fn = function() MM.editField(e) end }
        if MM.gamepad() and self.focusId == id and not e:isFocused() then
            local ac = T.accent
            self:drawRectBorder(fx - T.px(2), fy - T.px(2), fw + T.px(4), fhh + T.px(4), 1, ac.r, ac.g, ac.b)
        end
    end
    field("f:to", tr("UI_ZeD_Mail_To"), self.toEntry, cy, fh, 30)
    cy = cy + fh + T.px(8)
    field("f:subj", tr("UI_ZeD_Mail_Subject"), self.subjEntry, cy, fh, 31)
    cy = cy + fh + T.px(8)
    local th = y + h - T.px(10) - cy
    field("f:text", tr("UI_ZeD_Mail_Letter"), self.textEntry, cy, th, 32)
    self:showFields(true)
end

function ZeD_MMMail:buildBand(b, stripY, w)
    local T = ZeD.T
    local row = 1000
    if self.confirm == "delete" then
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", getText("UI_btn_cancel"), function() self:setConfirm(false) end },
            { "confirm:yes", getText("UI_btn_delete"), function() self:delete() end, "danger", false, tr("UI_ZeD_Mail_HelpDelete") } },
            tr("UI_ZeD_Mail_AskDelete"))
    elseif self.confirm == "discard" then
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", tr("UI_ZeD_Mail_KeepWriting"), function() self:setConfirm(false) end },
            { "confirm:yes", ZeD.tr("UI_ZeD_MMWord_DiscardChanges"), function() self:cancelCompose(true) end, "danger" } },
            tr("UI_ZeD_Mail_AskDiscard"))
    elseif self.compose then
        local why = self:putWhy()
        UI.stripSpecs(self, stripY, w, row, {},
            { { "cancel", getText("UI_btn_cancel"), function() self:cancelCompose(false) end },
              { "put", tr("UI_ZeD_Mail_PutInOutbox"), function() self:put() end, "primary", why ~= nil, why or tr("UI_ZeD_Mail_HelpPut") } },
            self.note or tr("UI_ZeD_Mail_GoesNext", b and b.server or ""), true)
    else
        local status, color
        if self.note then status, color = self.note, T.positive
        elseif b then
            local parts = { (b.t or 0) > 0 and tr("UI_ZeD_Mail_LastDial", when(b.t)) or tr("UI_ZeD_Mail_NeverDialed") }
            local n = #MS.load(b).outbox
            if n > 0 then parts[#parts + 1] = tr("UI_ZeD_Mail_OutboxCount", n) end
            status = table.concat(parts, MM.DOT or " | ")
        else status = tr("UI_ZeD_Mail_NoBoxes") end
        local m = self.sel
        local canReply = m ~= nil and self.folder == "inbox" and not m.returned and (m.from or "") ~= ""
        UI.stripSpecs(self, stripY, w, row, {},
            { { "new", tr("UI_ZeD_Mail_NewLetter"), function() self:startCompose() end, "default", b == nil, b and tr("UI_ZeD_Mail_HelpNew") or tr("UI_ZeD_Mail_NoBoxesHow") },
              { "reply", tr("UI_ZeD_Mail_Reply"), function() self:reply() end, "default", not canReply, tr("UI_ZeD_Mail_HelpReply") },
              { "delete", getText("UI_btn_delete"), function() self:setConfirm("delete") end, "default", m == nil, tr("UI_ZeD_Mail_HelpDelete") } },
            status, true, color)
    end
end

-- KEYS, CONTROLLER, WHEEL ----------------------------------------------------------
function ZeD_MMMail:joyB()
    if self.confirm then self:setConfirm(false); return end
    self:close()
end
function ZeD_MMMail:getFooterPrompts()
    if not MM.gamepad() then return nil end
    if self.confirm then return { { glyph = "A", label = ZeD.tr("UI_ZeD_MainMenu_PromptSelect") }, { glyph = "B", label = getText("UI_Cancel") } } end
    return { { glyph = "A", label = ZeD.tr("UI_ZeD_MainMenu_PromptSelect") }, { glyph = "B", label = getText("UI_Close") } }
end
function ZeD_MMMail:keyEscape()
    for _, e in ipairs({ self.toEntry, self.subjEntry, self.textEntry }) do
        if e:isFocused() then e:unfocus(); return true end
    end
    if self.confirm then self:setConfirm(false); return true end
    self:close()
    return true
end
function ZeD_MMMail:keyOther(key) return false end
function ZeD_MMMail:getStatusLine() return tr("UI_ZeD_Mail_HelpPrivate") end

function ZeD_MMMail:wheel(del)
    local T = ZeD.T
    local mx, my = getMouseX() - self:getAbsoluteX(), getMouseY() - self:getAbsoluteY()
    local function inside(r) return r and mx >= r.x and mx <= r.x + r.w and my >= r.y and my <= r.y + r.h end
    if inside(self._list) then self.lscroll = self.lscroll + del * T.px(ROW_H); return true end
    if not self.compose and inside(self._readText) then self.rscroll = self.rscroll + del * T.px(40); return true end
    return false
end
function ZeD_MMMail:onMouseWheel(del) return MM.wheel(del) end
-- Keep the base MM.wheel once, so a Lua reload never wraps the wrapper.
local _wheel = MM._mailWheelBase or MM.wheel
MM._mailWheelBase = _wheel
function MM.wheel(del)
    if MM.view == "mail" and MM.root and MM.root.mailWin then return MM.root.mailWin:wheel(del) end
    return _wheel(del)
end

MM.addView("mail", "mailWin", function() return ZeD_MMMail:new() end)
