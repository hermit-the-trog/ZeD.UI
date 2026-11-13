-- ZeD-UI/42/media/lua/client/ZeD/ZeD_ConsolePages.lua
-- ============================================================================
-- THE LUA CONSOLE'S OTHER PAGES: Help (and Commands), drawn into the console window from its page strip.
-- Client. Part of the ZeD_DebugConsoleWindow organism: this file adds the window's page methods (_drawPage,
-- _pageDir, _pageButton and the rest), which ZeD_DebugConsole.lua calls whenever the page is not the log.
--
-- Help is one scrolling page of fold headers: what runs where, the keys, the controller, the files. Its band has
-- one keycap, Back to the log. Controller: the hand walks the fold headers (A folds one), each brought into view
-- with its section, down reading on through a section taller than the view, then the band; D-pad left from the
-- page goes to the strip.
--
-- Commands (ZeD_ConsoleCommands.lua holds the list): the search and your role at the top, the commands under group
-- fold headers (name, what it does, and the lowest role that may use it, or in single player the debug menu's way
-- of doing it), the picked one's syntax, example and the rest under the list, then the chat line and the band. On a
-- server a click fills the chat line with the example and Send sends it; one that can't be undone asks first, in the
-- band, about the line as it stands (an edit drops the question). In single player a pick opens its debug window
-- where there is one (the band's keycap does too). Controller: the hand walks the search, the list, the line and the
-- band; A fills (or opens), X sends (on an empty line X fills it first and the hand goes to Send).
--
-- The one thing to know: the page draws inside the window's own prerender, so everything it measures is kept per
-- width and text size and laid out again only when one of them, or a fold, changes.
-- ============================================================================

require "ZeD/ZeD_DebugConsole"
require "ZeD/ZeD_ConsoleCommands"

local DC = ZeD.DebugConsole
local CC = ZeD.ConsoleCommands
local W = ZeD_DebugConsoleWindow
local UI = DC.ui
local U = UI.U
local S = ZeD.ConsoleScratch

local function tr(k, ...) return ZeD.tr(k, ...) end
local function px(n) return ZeD.T.px(n) end
local function fh(font) return ZeD.TM:getFontHeight(font) end
local function inRect(r, x, y) return r ~= nil and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end
local function sound(name) pcall(function() getSoundManager():playUISound(name or "UISelectListItem") end) end
local function btn(s) return ZeD.btnCase and ZeD.btnCase(s) or s end

-- ---------------------------------------------------------------------------
-- HELP: its sections (the key names and file paths stay as written; the words are translated)
-- ---------------------------------------------------------------------------
-- the game's key for its console, by name (Toggle Lua Console in its key options; "`" when it can't be read)
local function toggleKey()
    local ok, name = pcall(function() return Keyboard.getKeyName(getCore():getKey("Toggle Lua Console")) end)
    if ok and name ~= nil and tostring(name) ~= "" then return tostring(name) end
    return "`"
end

local HELP = {
    { id = "where", key = "UI_ZeD_Console_HelpFoldWhere",
      paras = { "UI_ZeD_Console_HelpWhere1", "UI_ZeD_Console_HelpWhere2", "UI_ZeD_Console_HelpWhere3",
                "UI_ZeD_Console_HelpWhere4", "UI_ZeD_Console_HelpWhere5" } },
    { id = "keys", key = "UI_ZeD_Console_HelpFoldKeys",
      rows = { { k = toggleKey, d = "UI_ZeD_Console_HelpKeyToggle" }, { k = "Enter", d = "UI_ZeD_Console_HelpKeyEnter" },
               { k = "Shift+Enter", d = "UI_ZeD_Console_HelpKeyShiftEnter" }, { k = "Up / Down", d = "UI_ZeD_Console_HelpKeyUpDown" },
               { k = "Tab", d = "UI_ZeD_Console_HelpKeyTab" }, { k = "Esc", d = "UI_ZeD_Console_HelpKeyEsc" },
               { k = "F11", d = "UI_ZeD_Console_HelpKeyF11" } } },
    { id = "pad", key = "UI_ZeD_Console_HelpFoldPad",
      rows = { { k = "D-pad", d = "UI_ZeD_Console_HelpPadDpad" }, { k = "A", d = "UI_ZeD_Console_HelpPadA" },
               { k = "B", d = "UI_ZeD_Console_HelpPadB" }, { k = "X", d = "UI_ZeD_Console_HelpPadX" },
               { k = "Y", d = "UI_ZeD_Console_HelpPadY" }, { k = "LB / RB", d = "UI_ZeD_Console_HelpPadBumpers" } } },
    { id = "files", key = "UI_ZeD_Console_HelpFoldFiles",
      rows = { { k = "Zomboid/Lua/ZeD_console_*.log", d = "UI_ZeD_Console_HelpFileExport" },
               { k = "Zomboid/Lua/" .. S.SNIP_FILE, d = "UI_ZeD_Console_HelpFileSnippets" },
               { k = "Zomboid/Lua/" .. S.HIST_FILE, d = "UI_ZeD_Console_HelpFileHistory", arg = S.HIST_CAP } } },
}
DC.HELP = HELP

local function sectionCount(sec) return #(sec.paras or sec.rows or {}) end

-- the page laid out at a width: a flat list of { t = "fold" | "para" | "row", y, h, ... } and its whole height
function W:_helpLayout(w)
    local T = ZeD.T
    self.hFold = self.hFold or {}
    local f2, f3 = T.fontF2, T.fontF3
    local key = tostring(w) .. "|" .. tostring(f2) .. "|" .. tostring(T.scale) .. "|" .. tostring(fh(f2))
    for _, sec in ipairs(HELP) do key = key .. (self.hFold[sec.id] and "1" or "0") end
    if self._hKey == key and self._hItems then return self._hItems, self._hTotal end
    local A = ZeD.Atoms
    local items = {}
    local y = px(6)
    local foldH = px(U.FOLD)
    local step2, step3 = fh(f2) + px(2), fh(f3) + px(2)
    local indent = px(24)
    local textW = math.max(px(40), w - indent - px(14))
    local keyW = math.min(px(170), math.floor(textW * 0.4))
    for si, sec in ipairs(HELP) do
        if si > 1 then y = y + px(6) end
        items[#items + 1] = { t = "fold", sec = sec, si = si, y = y, h = foldH }
        y = y + foldH + px(4)
        if not self.hFold[sec.id] then
            if sec.paras then
                for _, pk in ipairs(sec.paras) do
                    local lines = A.wrapText(tr(pk), f2, textW)
                    items[#items + 1] = { t = "para", lines = lines, y = y, h = #lines * step2 }
                    y = y + #lines * step2 + px(6)
                end
            else
                for _, r in ipairs(sec.rows) do
                    local k = type(r.k) == "function" and r.k() or r.k
                    local kl = A.wrapText(k, f3, keyW - px(8))
                    local d = r.arg ~= nil and tr(r.d, r.arg) or tr(r.d)
                    local dl = A.wrapText(d, f2, textW - keyW - px(12))
                    local h = math.max(#kl * step3, #dl * step2)
                    items[#items + 1] = { t = "row", kl = kl, dl = dl, keyW = keyW, y = y, h = h }
                    y = y + h + px(2)
                end
            end
        end
    end
    self._hKey, self._hItems, self._hTotal = key, items, y + px(8)
    return items, self._hTotal
end

-- the fold headers' items, in order (the controller's stops), kept with the layout they came from
local _foldsOf, _folds = nil, nil
local function helpFolds(items)
    if _foldsOf == items then return _folds end
    local out = {}
    for _, it in ipairs(items) do if it.t == "fold" then out[#out + 1] = it end end
    _foldsOf, _folds = items, out
    return out
end

-- the page as the last draw laid it out, at the same width (the controller's moves read the headers from it)
function W:_helpNow()
    return self:_helpLayout(self._hLayW or px(400))
end

-- the controller's header brought into view with as much of its section as fits under it, in a view h tall (a
-- header that only reached the foot of the view left its rows below it, the last section's for good)
local function seekHeader(win, folds, total, h)
    win.hSeek = nil
    local it = folds[win.hFocus or 1]
    if not it then return end
    local nxt = folds[(win.hFocus or 1) + 1]
    local secEnd = nxt and nxt.y or total
    local s = win.hScroll or 0
    if it.y < s then s = it.y
    elseif secEnd > s + h then s = math.min(it.y, secEnd - h) end
    win.hScroll = math.max(0, math.min(math.max(0, total - h), s))
end

function W:_drawHelp(x, y, w, h, joy)
    local T = ZeD.T
    local M = ZeD.Molecules
    local sbW = T.sp.scrollbarW
    self._hLayW = w - sbW
    local items, total = self:_helpLayout(w - sbW)
    self.hScroll = self.hScroll or 0
    self.hFocus = self.hFocus or 1
    local folds = helpFolds(items)
    if self.hFocus > #folds then self.hFocus = #folds end
    if self.hSeek then seekHeader(self, folds, total, h) end
    local maxS = math.max(0, total - h)
    self.hScroll = math.max(0, math.min(maxS, self.hScroll))
    self._hMax = maxS
    local iw = w - (total > h and sbW or 0)
    local mx, my = self:getMouseX(), self:getMouseY()
    if joy then mx, my = nil, nil end
    self._hHits = {}
    self:setStencilRect(x, y, iw, h)
    local f2, f3 = T.fontF2, T.fontF3
    local step2, step3 = fh(f2) + px(2), fh(f3) + px(2)
    local tc, kc = T.text, T.text
    local fi = 0
    for _, it in ipairs(items) do
        local yy = y + it.y - self.hScroll
        if it.t == "fold" then fi = fi + 1 end
        if yy + it.h > y and yy < y + h then
            if it.t == "fold" then
                local hover = mx ~= nil and mx >= x and mx < x + iw and my >= yy and my < yy + it.h and my >= y and my < y + h
                local foc = joy and self.zone == "page" and self.hFocus == fi
                M.drawSectionHeader(self, x + px(8), yy, iw - px(8), tr(it.sec.key), sectionCount(it.sec), not self.hFold[it.sec.id], hover, nil, true, px(8), it.h, nil,
                    foc and { focus = UI.focusOpts(self) } or nil)
                self._hHits[#self._hHits + 1] = { y = yy, h = it.h, id = it.sec.id, fi = fi }
            elseif it.t == "para" then
                for i, s in ipairs(it.lines) do
                    self:drawText(s, x + px(24), yy + (i - 1) * step2, tc.r, tc.g, tc.b, tc.a or 1, f2)
                end
            else
                for i, s in ipairs(it.kl) do
                    self:drawText(s, x + px(24), yy + (i - 1) * step3 + math.floor((step2 - step3) / 2), kc.r, kc.g, kc.b, kc.a or 1, f3)
                end
                for i, s in ipairs(it.dl) do
                    self:drawText(s, x + px(24) + it.keyW + px(12), yy + (i - 1) * step2, tc.r, tc.g, tc.b, tc.a or 1, f2)
                end
            end
        end
    end
    self:clearStencilRect()
    if total > h then
        local win = self
        M.scrollBar(self, nil, "help", x + w - sbW, y, sbW, h, self.hScroll, total, function(v) win.hScroll = v end, { step = step2 })
    end
    self._hRect = { x = x, y = y, w = iw, h = h }
end

-- a fold header folded or opened
function W:helpFold(id)
    self.hFold = self.hFold or {}
    if self.hFold[id] then self.hFold[id] = nil else self.hFold[id] = true end
    sound()
end

-- ---------------------------------------------------------------------------
-- COMMANDS: the boxes (the search, the chat line), made with the window's own
-- ---------------------------------------------------------------------------
local baseChildren = W.createChildren
function W:createChildren()
    baseChildren(self)
    local win = self
    local q = UI.makeEntry(self, 100)
    q.onCommandEntered = function() q:unfocus() end
    q.onOtherKey = function(_, key) if key == Keyboard.KEY_ESCAPE then q:unfocus() end end
    self.cq = q
    local c = UI.makeEntry(self, 256)
    c.onCommandEntered = function() win:cmdSend() end
    c.onOtherKey = function(_, key) if key == Keyboard.KEY_ESCAPE then c:unfocus() end end
    self.chat = c
    self.cFold, self.cScroll, self.cFocus, self.cbFocus = {}, 0, 1, 2
    self._cqSt, self._chatSt = {}, {}
end

local LEVEL_COLOR = { "textDim", "textDim", "positive", "warning", "danger" }
local function levelColor(rank) return ZeD.T[LEVEL_COLOR[rank or 4] or "warning"] or ZeD.T.textDim end

-- the single-player words for a command: "Debug menu > Cheats", the place said, or nothing like it
local function aloneWords(c, long)
    local a = CC.alone(c)
    if a and a.open then return tr("UI_ZeD_Console_SpMenu", a.label), true end
    if a and a.say then return a.say, true end
    return tr(long and "UI_ZeD_Console_SpNoneLong" or "UI_ZeD_Console_SpNone"), false
end

-- The flat rows: a fold header per group shown, then its commands (unless folded); made again when the search or a
-- fold changes, and once a second for a role that changed under it. Each command's row keeps what it shows (what it
-- does, its level or its single-player words), and the page keeps the count it shows against and your role, made
-- with it: a frame walks no command and asks the role nothing (the count alone ran every command's capability
-- checks each frame). server: CC.server() when the caller has it.
function W:_cmdItems(server)
    if server == nil then server = CC.server() end
    local q = self.cq and tostring(self.cq:getText() or "") or ""
    local sec = math.floor(getTimestampMs() / 1000)
    local fold = 0
    for _, g in ipairs(CC.GROUPS) do fold = fold * 2 + (self.cFold[g.id] and 1 or 0) end
    local k = self._cKey
    if k and self._cItems and k.q == q and k.server == server and k.sec == sec and k.fold == fold then
        return self._cItems, self._cShown
    end
    local groups, n = CC.shown(q)
    local items = {}
    for _, gr in ipairs(groups) do
        items[#items + 1] = { t = "fold", g = gr.group, n = #gr.cmds }
        if not self.cFold[gr.group.id] then
            for _, c in ipairs(gr.cmds) do
                local it = { t = "cmd", c = c, does = CC.does(c) }
                if server then it.word, it.rank = CC.level(c) else it.word, it.has = aloneWords(c, false) end
                items[#items + 1] = it
            end
        end
    end
    if self._cQ ~= q then self.cScroll, self._cQ = 0, q end
    self._cKey, self._cItems, self._cShown = { q = q, server = server, sec = sec, fold = fold }, items, n
    self._cTotal = CC.total()
    self._cRole = server and CC.myRole() or nil
    if self.cFocus > #items then self.cFocus = math.max(1, #items) end
    return items, n
end

function W:_cmdSel()
    local n = self.csel
    if not n then return nil end
    if self._cSelOf ~= n then self._cSelOf, self._cSel = n, CC.byName[string.lower(n)] end
    return self._cSel
end

--- A command picked (a click, A): on a server its example fills the chat line; in single player its debug window
--- opens where there is one.
function W:cmdPick(c)
    if not c then return end
    self.csel = c.name
    self.cConfirm = nil
    self._cStatus = nil
    sound()
    if CC.server() then
        self.chat:setText(c.ex)
    else
        CC.openAlone(c)
    end
end

--- The line the band's question asks about, while the line still says it. A line edited under the question drops
--- it: the band offers its own Send again, which asks about what the line says now.
function W:_cmdAsking()
    local q = self.cConfirm
    if q and q ~= tostring(self.chat:getText() or "") then
        self.cConfirm = nil
        return nil
    end
    return q
end

--- Send the chat line (Enter in it, Send, X). One that can't be undone asks first, in the band; confirmed (the
--- question's Send) stands only for the line it asked about.
function W:cmdSend(confirmed)
    if not CC.server() then return end
    local text = tostring(self.chat:getText() or "")
    if UI.blank(text) then return end
    if CC.asks(text) and not (confirmed and text == self.cConfirm) then
        self.cConfirm = text
        if self.joyfocus then self.zone, self.cbFocus = "pband", 1 end
        sound("UIActivateButton")
        return
    end
    self.cConfirm = nil
    local how = CC.send(text)
    local T = ZeD.T
    if how == "sent" or how == "chat" then
        self._cStatus = { text = tr("UI_ZeD_Console_CmdSent", text), color = T.positive }
        self.chat:setText("")
    elseif how == "filled" then
        self._cStatus = { text = tr("UI_ZeD_Console_CmdFilled", text), color = T.warning }
    else
        self._cStatus = { text = tr("UI_ZeD_Console_CmdNotSent"), color = T.danger }
    end
    sound("UIActivateButton")
    DC.lastSent = text
end

-- a typed field: its box, the magnifier or the mark, the words over the hidden game box
function W:_cmdField(inp, st, x, y, w, h, mark, placeholder, zone, joy)
    local T = ZeD.T
    local s1 = T.base or T.surf1
    self:drawRect(x, y, w, h, s1.a or 1, s1.r, s1.g, s1.b)
    local focused = inp:isFocused()
    local bc = focused and T.accent or T.borderS
    self:drawRectBorder(x, y, w, h, bc.a or 1, bc.r, bc.g, bc.b)
    local ex
    if mark then
        local f3, td = T.fontF3, T.textDim
        self:drawText(mark, x + px(6), y + math.floor((h - fh(f3)) / 2), td.r, td.g, td.b, td.a or 1, f3)
        ex = x + px(6) + ZeD.TM:MeasureStringX(f3, mark) + px(6)
    else
        ex = x + px(6) + ZeD.Atoms.drawSearchIcon(self, x + px(6), y, h) + px(6)
    end
    local ew = math.max(px(10), x + w - px(4) - ex)
    UI.parkEntry(inp, ew, y, h)
    self:_drawTyped(inp, ex, y, ew, h, T.fontF3, focused, placeholder, st)
    if joy and self.zone == zone then UI.mark(self, x, y, w, h) end
    return { x = x, y = y, w = w, h = h }
end

-- the head: the search, your role (or single player), "shown of total" (the role and the total kept with the rows)
function W:_cmdHead(x, y, w, h, joy, shown, server)
    local T = ZeD.T
    local f3 = T.fontF3
    local pad = px(U.PAD)
    ZeD.Atoms.drawDividerH(self, x, y + h - px(1), w)
    local role = server and tr("UI_ZeD_Console_CmdYourRole", self._cRole or "?") or tr("UI_ZeD_Console_CmdSingle")
    local cs = tr("UI_ZeD_Console_CmdCount", shown, self._cTotal or 0)
    local rw, cw = ZeD.TM:MeasureStringX(f3, role), ZeD.TM:MeasureStringX(f3, cs)
    local ih = T.inputH
    local fy = y + math.floor((h - ih) / 2)
    local fw = w - 2 * pad - cw - rw - px(20)
    local showRole = fw >= px(120)
    if not showRole then fw = w - 2 * pad - cw - px(10) end
    fw = math.max(px(60), fw)
    self._cqRect = self:_cmdField(self.cq, self._cqSt, x + pad, fy, fw, ih, nil, tr("UI_ZeD_Console_CmdSearch"), "csearch", joy)
    local tc, td = T.text, T.textDim
    local ty = y + math.floor((h - fh(f3)) / 2)
    if showRole then self:drawText(role, x + pad + fw + px(10), ty, tc.r, tc.g, tc.b, tc.a or 1, f3) end
    if x + pad + fw + px(10) + cw <= x + w then self:drawText(cs, x + w - pad - cw, ty, td.r, td.g, td.b, td.a or 1, f3) end
end

-- one command row (an item of _cmdItems): name, what it does, and its level (a server) or the debug menu's way
-- (single player)
function W:_cmdRow(it, x, y, w, h, hover, foc, cols, server)
    local T = ZeD.T
    local A = ZeD.Atoms
    local f2, f3 = T.fontF2, T.fontF3
    local c = it.c
    local picked = self.csel == c.name
    local onFocus = false
    if picked then
        local a = T.accent
        self:drawRect(x, y, w, h, a.a or 1, a.r, a.g, a.b)
    elseif hover then
        local hv = T.hover
        self:drawRect(x, y, w, h, hv.a or 1, hv.r, hv.g, hv.b)
    end
    if foc then onFocus = UI.mark(self, x, y, w, h) end
    local sp = not server
    local words, has = it.word, true
    if sp then has = it.has end
    local alpha = (sp and not has) and (T.disabledAlpha or 0.4) or 1
    local tc = onFocus and T.textOnFocus or (picked and T.textOnAccent or T.text)
    local dc = onFocus and T.textOnFocus or (picked and T.textOnAccent or T.textDim)
    local ty3, ty2 = y + math.floor((h - fh(f3)) / 2), y + math.floor((h - fh(f2)) / 2)
    local nx = x + px(22)
    self:drawText(A.truncateText("/" .. c.name, f3, cols.cmdW - px(4)), nx, ty3, tc.r, tc.g, tc.b, (tc.a or 1) * alpha, f3)
    local rx = x + w - px(10) - cols.rightW
    local dx = nx + cols.cmdW + px(10)
    if rx - px(10) > dx then
        self:drawText(A.truncateText(it.does, f2, rx - px(10) - dx), dx, ty2, tc.r, tc.g, tc.b, (tc.a or 1) * alpha, f2)
    end
    if sp then
        self:drawText(A.truncateText(words, f3, cols.rightW), rx, ty3, dc.r, dc.g, dc.b, (dc.a or 1) * alpha, f3)
    else
        local word, rank = it.word, it.rank
        local sq = px(U.MARK)
        A.drawStatusDot(self, rx, y + math.floor((h - sq) / 2), (picked or onFocus) and dc or levelColor(rank), sq)
        self:drawText(A.truncateText(word, f3, cols.rightW - sq - px(5)), rx + sq + px(5), ty3, dc.r, dc.g, dc.b, dc.a or 1, f3)
    end
end

function W:_cmdList(x, y, w, h, joy, server)
    local T = ZeD.T
    local M = ZeD.Molecules
    local items = self:_cmdItems(server)
    local foldH, rowH = px(U.FOLD), math.max(px(22), fh(T.fontF2) + px(4))
    local total = px(4)
    for _, it in ipairs(items) do total = total + (it.t == "fold" and foldH or rowH) end
    local sbW = T.sp.scrollbarW
    local bar = total > h
    local iw = w - (bar and sbW or 0)
    if self.cSeek then
        self.cSeek = nil
        local yy = px(4)
        for i, it in ipairs(items) do
            local ih = it.t == "fold" and foldH or rowH
            if i == self.cFocus then
                if yy < self.cScroll then self.cScroll = yy elseif yy + ih > self.cScroll + h then self.cScroll = yy + ih - h end
                break
            end
            yy = yy + ih
        end
    end
    self.cScroll = math.max(0, math.min(math.max(0, total - h), self.cScroll))
    self._cMax = math.max(0, total - h)
    self._cHits = {}
    self._cListRect = { x = x, y = y, w = iw, h = h }
    if #items == 0 then
        local q = tostring(self.cq:getText() or "")
        local line = server and tr("UI_ZeD_Console_CmdNoMatch", q) or tr("UI_ZeD_Console_CmdNoMatchSP", q)
        local hh = M.drawEmptyLine(self, x + px(12), y + px(12), w - px(24), line)
        M.drawEmptyLine(self, x + px(12), y + px(16) + hh, w - px(24), tr("UI_ZeD_Console_CmdSearchHint"))
        return
    end
    local cols = self._cCols or {}
    self._cCols = cols
    cols.cmdW = math.min(px(168), math.floor(iw * 0.28))
    cols.rightW = server and px(96) or math.min(px(200), math.floor(iw * 0.32))
    local mx, my = self:getMouseX(), self:getMouseY()
    if joy then mx, my = nil, nil end
    self:setStencilRect(x, y, iw, h)
    local yy = y + px(4) - self.cScroll
    for i, it in ipairs(items) do
        local ih = it.t == "fold" and foldH or rowH
        if yy + ih > y and yy < y + h then
            local hover = mx ~= nil and mx >= x and mx < x + iw and my >= yy and my < yy + ih and my >= y and my < y + h
            local foc = joy and self.zone == "page" and self.cFocus == i
            if it.t == "fold" then
                M.drawSectionHeader(self, x + px(8), yy, iw - px(8), tr(it.g.key), it.n, not self.cFold[it.g.id], hover, nil, true, px(8), ih, nil,
                    foc and { focus = UI.focusOpts(self) } or nil)
            else
                self:_cmdRow(it, x, yy, iw, ih, hover, foc, cols, server)
                if hover then ZeD.Help.set(self, tr(server and "UI_ZeD_Console_CmdHelpServer" or "UI_ZeD_Console_CmdHelpSP")) end
            end
            self._cHits[#self._cHits + 1] = { y = math.max(y, yy), h = math.min(yy + ih, y + h) - math.max(y, yy), i = i }
        end
        yy = yy + ih
    end
    self:clearStencilRect()
    if bar then
        local win = self
        M.scrollBar(self, nil, "cmds", x + w - sbW, y, sbW, h, self.cScroll, total, function(v) win.cScroll = v end, { step = rowH })
    end
end

-- the picked command's lines: { label, words, mono } after its head line
function W:_cmdDetailRows(c, server)
    if server == nil then server = CC.server() end
    local rows = { { "UI_ZeD_Console_CmdSyntax", c.syn, true }, { "UI_ZeD_Console_CmdExample", c.ex, true } }
    if #c.also > 0 then rows[#rows + 1] = { "UI_ZeD_Console_CmdAlso", "/" .. table.concat(c.also, "  /"), true } end
    if server then
        rows[#rows + 1] = { "UI_ZeD_Console_CmdDoes", CC.does(c) }
        local w, has = aloneWords(c, false)
        if has then rows[#rows + 1] = { "UI_ZeD_Console_CmdAlone", w } end
    else
        rows[#rows + 1] = { "UI_ZeD_Console_CmdSP", (aloneWords(c, true)) }
        rows[#rows + 1] = { "UI_ZeD_Console_CmdDoes", CC.does(c) }
    end
    return rows
end

-- the picked command's detail lines, level and single-player way, kept until the pick, the side or the rows change
-- (at most once a second)
function W:_cmdDet(c, server)
    local d = self._cDet
    if d and d.c == c and d.server == server and d.key == self._cKey then return d end
    d = { c = c, server = server, key = self._cKey, rows = self:_cmdDetailRows(c, server), alone = CC.alone(c) }
    d.word, d.rank = CC.level(c)
    self._cDet = d
    return d
end

-- the detail under the list: the name, its level and capabilities (and "can't be undone"), then its lines; each
-- line cut to fit, so it never pushes the list off a small window
function W:_cmdDetail(c, x, y, w, h, server)
    local T = ZeD.T
    local A = ZeD.Atoms
    local f2, f3 = T.fontF2, T.fontF3
    local d = self:_cmdDet(c, server)
    A.drawDividerH(self, x, y, w)
    local lh = math.max(fh(f2), fh(f3)) + px(3)
    local yy = y + px(6)
    local tc, td = T.text, T.textDim
    self:setStencilRect(x, y, w, h)
    local hx = x + px(12)
    self:drawText("/" .. c.name, hx, yy, tc.r, tc.g, tc.b, tc.a or 1, f3)
    hx = hx + ZeD.TM:MeasureStringX(f3, "/" .. c.name) + px(10)
    local word, rank = d.word, d.rank
    local sq = px(U.MARK)
    local tag = word .. " | " .. table.concat(c.caps, ", ")
    A.drawStatusDot(self, hx, yy + math.floor((fh(f3) - sq) / 2), levelColor(rank), sq)
    tag = A.truncateText(tag, f3, math.max(0, x + w - px(12) - hx - sq - px(5)))
    self:drawText(tag, hx + sq + px(5), yy, td.r, td.g, td.b, td.a or 1, f3)
    if c.undo == false then
        local nx = hx + sq + px(5) + ZeD.TM:MeasureStringX(f3, tag) + px(12)
        local s = tr("UI_ZeD_Console_CmdNoUndo")
        if nx + sq + px(5) + ZeD.TM:MeasureStringX(f3, s) <= x + w - px(12) then
            A.drawStatusDot(self, nx, yy + math.floor((fh(f3) - sq) / 2), T.danger, sq)
            self:drawText(s, nx + sq + px(5), yy, td.r, td.g, td.b, td.a or 1, f3)
        end
    end
    yy = yy + lh
    local labW = math.min(px(116), math.floor(w * 0.25))
    for _, r in ipairs(d.rows) do
        if yy + lh > y + h then break end
        local f = r[3] and f3 or f2
        self:drawText(A.truncateText(tr(r[1]), f3, labW - px(4)), x + px(12), yy, td.r, td.g, td.b, td.a or 1, f3)
        self:drawText(A.truncateText(tostring(r[2] or ""), f, math.max(0, w - labW - px(34))), x + px(12) + labW + px(10), yy, tc.r, tc.g, tc.b, tc.a or 1, f)
        yy = yy + lh
    end
    self:clearStencilRect()
end

function W:_cmdDetailH(c, server)
    if not c then return 0 end
    if server == nil then server = CC.server() end
    local T = ZeD.T
    local lh = math.max(fh(T.fontF2), fh(T.fontF3)) + px(3)
    return px(12) + lh * (1 + #self:_cmdDet(c, server).rows)
end

local _cBtns = { { id = "ccopy" }, { id = "csend", variant = "primary" } }
local _cSpec = { buttons = _cBtns }
local _cOpen = { { id = "copen", variant = "primary" } }
local _cOpenSpec = { buttons = _cOpen }

function W:_cmdBand(bandY, joy, server)
    if server == nil then server = CC.server() end
    local c = self:_cmdSel()
    local out
    if not server then
        local b = _cOpen[1]
        local a = c and self:_cmdDet(c, server).alone
        if a and a.open then b.label, b.disabled = btn(tr("UI_ZeD_Console_SpOpen", a.label)), false
        else b.label, b.disabled = btn(tr("UI_ZeD_Console_SpNothing")), true end
        b.focus = (joy and self.zone == "pband") and UI.focusOpts(self) or nil
        b.pressed = self._down == b.id
        if joy then b.hover = false else b.hover = nil end
        _cOpenSpec.win = self
        _cOpenSpec.status = self._cStatus
        local _
        _, out = ZeD.Molecules.drawBand(self, 0, bandY, self.width, _cOpenSpec)
        self._bandRects = out and out.buttons or {}
        return
    end
    if self:_cmdAsking() then
        local fo = UI.focusOpts
        local _, cr, vr = ZeD.Molecules.drawQuestionBand(self, 0, bandY, self.width, tr("UI_ZeD_Console_CmdAsk", self.cConfirm), btn(tr("UI_ZeD_Console_CmdSend")),
            { win = self, cancelFocus = (joy and self.zone == "pband" and self.cbFocus == 1) and fo(self) or nil,
              verbFocus = (joy and self.zone == "pband" and self.cbFocus == 2) and fo(self) or nil })
        if cr then cr.id = "cno" end
        if vr then vr.id = "cyes" end
        self._bandRects = { cr, vr }
        return
    end
    local blankLine = UI.blank(tostring(self.chat:getText() or ""))
    local b1, b2 = _cBtns[1], _cBtns[2]
    if (self._copiedUntil or 0) > getTimestampMs() then b1.label = btn(tr("UI_ZeD_Msg_Copied")) else b1.label = btn(tr("UI_ZeD_Msg_CopyOne")) end
    b1.disabled = blankLine
    b2.label = btn(tr("UI_ZeD_Console_CmdSend"))
    b2.disabled = blankLine
    for i, b in ipairs(_cBtns) do
        b.focus = (joy and self.zone == "pband" and self.cbFocus == i) and UI.focusOpts(self) or nil
        b.pressed = self._down == b.id
        if joy then b.hover = false else b.hover = nil end
    end
    _cSpec.win = self
    _cSpec.status = self._cStatus
    local _
    _, out = ZeD.Molecules.drawBand(self, 0, bandY, self.width, _cSpec)
    self._bandRects = out and out.buttons or {}
end

-- (on a server or not is asked once a frame and handed down: each ask is a pcall and a Java call)
function W:_drawCmds(x, top, w, h, bandY, joy)
    local T = ZeD.T
    local pad = px(U.PAD)
    local hh = px(U.HEAD)
    local server = CC.server()
    local _, shown = self:_cmdItems(server)
    self:_cmdHead(x, top, w, hh, joy, shown, server)
    local ih = T.inputH
    local lineH = server and (ih + 2 * pad) or 0
    local c = self:_cmdSel()
    local room = h - hh - lineH
    local dh = math.min(self:_cmdDetailH(c, server), math.floor(room * 0.45))
    local ly = top + hh + px(2)
    local lh = math.max(0, top + h - lineH - dh - ly)
    self:_cmdList(x, ly, w, lh, joy, server)
    if c and dh > 0 then self:_cmdDetail(c, x, ly + lh, w, dh, server) end
    if server then
        local fy = top + h - lineH + pad
        ZeD.Atoms.drawDividerH(self, x, top + h - lineH, w)
        self._chatRect = self:_cmdField(self.chat, self._chatSt, x + pad, fy, w - 2 * pad, ih, tr("UI_ZeD_Console_CmdChatMark"), tr("UI_ZeD_Console_CmdPickHint"), "cline", joy)
    else
        self._chatRect = nil
        UI.parkEntry(self.chat, px(10), top, ih)
    end
    self:_cmdBand(bandY, joy, server)
end

-- the page's words for the help line
function W:_cmdStatus()
    if not CC.server() then return tr("UI_ZeD_Console_CmdHelpSP") end
    local c = self:_cmdSel()
    if self:_cmdAsking() then return tr("UI_ZeD_Console_CmdHelpUndo") end
    if c and c.undo == false then return tr("UI_ZeD_Console_CmdHelpUndo") end
    if c then return tr("UI_ZeD_Console_CmdHelpServer") end
    return tr("UI_ZeD_Console_CmdHelpPick")
end

function W:_cmdUse(it)
    if not it then return end
    if it.t == "fold" then
        sound()
        if self.cFold[it.g.id] then self.cFold[it.g.id] = nil else self.cFold[it.g.id] = true end
    else
        self:cmdPick(it.c)
    end
end

function W:_cmdMouseDown(x, y)
    if inRect(self._cqRect, x, y) then
        self.zone = "csearch"
        self.cq:focus()
        UI.placeCursor(self.cq, self._cqSt, x)
        return true
    end
    if inRect(self._chatRect, x, y) then
        self.zone = "cline"
        self.chat:focus()
        UI.placeCursor(self.chat, self._chatSt, x)
        return true
    end
    if inRect(self._cListRect, x, y) then
        local items = self:_cmdItems()
        for _, hit in ipairs(self._cHits or {}) do
            if y >= hit.y and y < hit.y + hit.h then
                self.cFocus = hit.i
                self:_cmdUse(items[hit.i])
                return true
            end
        end
        return true
    end
    return false
end

function W:_cmdPress(id)
    if id == "csend" then self:cmdSend(); return true end
    if id == "cyes" then self:cmdSend(true); return true end
    if id == "cno" then sound("UIActivateButton"); self.cConfirm = nil; if self.zone == "pband" then self.cbFocus = 2 end; return true end
    if id == "ccopy" then
        local text = tostring(self.chat:getText() or "")
        if UI.blank(text) then return true end
        sound("UIActivateButton")
        pcall(function() Clipboard.setClipboard(text) end)
        DC.lastCopy = text
        self._copiedUntil = getTimestampMs() + 1500
        return true
    end
    if id == "copen" then
        local c = self:_cmdSel()
        if c and CC.openAlone(c) then sound("UIActivateButton") end
        return true
    end
    return false
end

function W:_cmdWheel(del)
    self.cScroll = math.max(0, math.min(self._cMax or 0, (self.cScroll or 0) + del * px(U.FROW) * 3))
end

-- the controller: the search, the list, the line (a server), the band
function W:_cmdDir(dir)
    local z = self.zone
    local server = CC.server()
    local items = self:_cmdItems()
    local bandN = server and 2 or 1
    if z == "csearch" then
        if dir == "down" then self.zone, self.cSeek = "page", true; return true end
        return dir ~= "left"
    elseif z == "cline" then
        if dir == "up" then self.zone, self.cSeek = "page", true
        elseif dir == "down" then self.zone, self.cbFocus = "pband", bandN end
        return dir ~= "left"
    elseif z == "pband" then
        if dir == "up" then self.zone = server and "cline" or "page"; self.cSeek = true
        elseif dir == "left" then
            if self.cbFocus > 1 then self.cbFocus = self.cbFocus - 1 else return false end
        elseif dir == "right" then self.cbFocus = math.min(bandN, self.cbFocus + 1) end
        return true
    end
    -- the list (and the zone a page starts on from the strip)
    if z ~= "page" then self.zone, self.cSeek = "page", true; return dir ~= "left" end
    if dir == "up" then
        if self.cFocus > 1 then self.cFocus = self.cFocus - 1 else self.zone = "csearch" end
    elseif dir == "down" then
        if self.cFocus < #items then self.cFocus = self.cFocus + 1
        else self.zone, self.cbFocus = server and "cline" or "pband", bandN end
    else
        return dir ~= "left"
    end
    self.cSeek = true
    -- (moving onto a command shows its detail; A picks it)
    local it = items[self.cFocus]
    if it and it.t == "cmd" and self.zone == "page" then self.csel = it.c.name end
    return true
end

function W:_cmdButton(button, jd)
    local z = self.zone
    if button == Joypad.BButton then
        if self:_cmdAsking() then sound("UIActivateButton"); self.cConfirm = nil; self.cbFocus = 2; return true end
        return false
    end
    if button == Joypad.XButton then
        local server = CC.server()
        if server then
            local it = z == "page" and self:_cmdItems(server)[self.cFocus] or nil
            if it and it.t == "cmd" and UI.blank(tostring(self.chat:getText() or "")) then
                -- (an empty line takes the row's example and the hand goes to Send: an example is never sent unseen,
                -- a second X or A sends it)
                self:cmdPick(it.c)
                self.zone, self.cbFocus = "pband", 2
                return true
            end
            self:cmdSend()
        end
        return true
    end
    if button ~= Joypad.AButton then return true end
    if z == "csearch" then sound("UIActivateButton"); self:openKeyboard(jd or self.joyfocus, self.cq)
    elseif z == "cline" then sound("UIActivateButton"); self:openKeyboard(jd or self.joyfocus, self.chat)
    elseif z == "pband" then
        local id
        if self:_cmdAsking() then id = self.cbFocus == 1 and "cno" or "cyes"
        elseif CC.server() then id = self.cbFocus == 1 and "ccopy" or "csend"
        else id = "copen" end
        self:press(id)
    else
        self:_cmdUse(self:_cmdItems()[self.cFocus])
    end
    return true
end

function W:_cmdPrompts(out)
    local z = self.zone
    local server = CC.server()
    if z == "csearch" or z == "cline" then
        out[#out + 1] = { glyph = "A", label = tr("UI_ZeD_Prompt_Keyboard") }
    elseif z == "pband" then
        out[#out + 1] = { glyph = "A", label = tr("UI_ZeD_Prompt_Press") }
    else
        local it = self:_cmdItems(server)[self.cFocus]
        if it and it.t == "fold" then out[#out + 1] = { glyph = "A", label = self.cFold[it.g.id] and tr("UI_ZeD_Prompt_Unfold") or tr("UI_ZeD_Prompt_Fold") }
        elseif it then out[#out + 1] = { glyph = "A", label = server and tr("UI_ZeD_Console_PadFill") or tr("UI_ZeD_Console_PadOpen") } end
    end
    if server and not self:_cmdAsking() then out[#out + 1] = { glyph = "X", label = tr("UI_ZeD_Console_CmdSend") } end
end

function W:_cmdBLabel()
    if self:_cmdAsking() then return getText("UI_Cancel") end
    return nil
end

-- the pad keyboard put away on the chat line: on Send, ready
function W:_pageKbDone(entry)
    if entry == self.chat and not UI.blank(tostring(self.chat:getText() or "")) then self.zone, self.cbFocus = "pband", 2 end
end

function W:_cmdLeave(old)
    if old == "cmds" then
        if self.cq then self.cq:unfocus() end
        if self.chat then self.chat:unfocus() end
        self.cConfirm = nil
    end
end

function W:_cmdClose()
    local mine = {}
    if self.cq then self.cq:unfocus(); mine[self.cq] = true end
    if self.chat then self.chat:unfocus(); mine[self.chat] = true end
    self.cConfirm = nil
    return mine
end

-- ---------------------------------------------------------------------------
-- THE PAGE HOOKS the window calls (page ~= "log")
-- ---------------------------------------------------------------------------
local _hBtns = { { id = "tolog", variant = "primary" } }
local _hSpec = { buttons = _hBtns }

function W:_drawPage(x, top, w, h, bandY, joy)
    if self.page == "help" then
        self:_drawHelp(x, top, w, h, joy)
        local b = _hBtns[1]
        b.label = btn(tr("UI_ZeD_Console_BackToLog"))
        b.focus = (joy and self.zone == "pband") and UI.focusOpts(self) or nil
        b.pressed = self._down == b.id
        if joy then b.hover = false else b.hover = nil end
        _hSpec.win = self
        local _, out = ZeD.Molecules.drawBand(self, 0, bandY, self.width, _hSpec)
        self._bandRects = out and out.buttons or {}
    elseif self._drawCmds then
        self:_drawCmds(x, top, w, h, bandY, joy)
    else
        ZeD.Molecules.drawEmptyLine(self, x + px(16), top + px(16), w - px(32), tr("UI_ZeD_Console_Coming"))
    end
end

function W:_pageStatus()
    if self.page == "help" then return tr("UI_ZeD_Console_HelpPage") end
    if self._cmdStatus then return self:_cmdStatus() end
    return ""
end

function W:_pageMouseDown(x, y)
    if self.page == "help" then
        if inRect(self._hRect, x, y) then
            for _, hit in ipairs(self._hHits or {}) do
                if y >= hit.y and y < hit.y + hit.h then self.hFocus = hit.fi; self:helpFold(hit.id); return true end
            end
            return true
        end
        return false
    end
    if self._cmdMouseDown then return self:_cmdMouseDown(x, y) end
    return false
end

function W:_pagePress(id)
    if id == "tolog" then sound("UIActivateButton"); self:setPage("log"); return true end
    if self._cmdPress then return self:_cmdPress(id) end
    return false
end

function W:_pageWheel(del, mx, my)
    if self.page == "help" then
        self.hScroll = math.max(0, math.min(self._hMax or 0, (self.hScroll or 0) + del * px(U.FROW) * 3))
    elseif self._cmdWheel then
        self:_cmdWheel(del, mx, my)
    end
end

-- the controller on the Help page: the headers are its stops, and down reads on through a section taller than the
-- view, a view at a time, before the next header (or, past the last, the band with the page at its foot); up goes
-- back to a header read off the top before the one above it
function W:_helpDir(dir)
    local items, total = self:_helpNow()
    local folds = helpFolds(items)
    if self.zone == "pband" then
        if dir == "up" then self.zone = "page"; self.hSeek = true; return true end
        return dir ~= "left"
    end
    self.zone = "page"
    local i = math.min(self.hFocus or 1, #folds)
    local it = folds[i]
    local view = self._hRect and self._hRect.h or 0
    -- (a move not drawn yet is put in place first: the next one starts from where it left the page)
    if self.hSeek and view > 0 then seekHeader(self, folds, total, view) end
    local s = self.hScroll or 0
    if dir == "up" then
        if it and it.y < s then self.hScroll = it.y
        elseif i > 1 then self.hFocus = i - 1; self.hSeek = true end
        return true
    elseif dir == "down" then
        local nxt = folds[i + 1]
        local secEnd = nxt and nxt.y or total
        if it and view > 0 and secEnd > s + view then
            local line = fh(ZeD.T.fontF2) + px(2)
            self.hScroll = s + math.min(secEnd - (s + view), math.max(line, view - line))
        elseif nxt then
            self.hFocus = i + 1
            self.hSeek = true
        else
            self.zone = "pband"
            self.hScroll = math.max(0, total - view)
        end
        return true
    end
    return dir ~= "left"
end

-- the controller on a page: true when it moved; false on the left edge (the window goes to the strip)
function W:_pageDir(dir)
    if self.page == "help" then return self:_helpDir(dir) end
    if self._cmdDir then return self:_cmdDir(dir) end
    return false
end

function W:_pageButton(button, jd)
    if self.page == "help" then
        if button == Joypad.AButton then
            if self.zone == "pband" then self:press("tolog")
            else
                local folds = helpFolds((self:_helpNow()))
                local it = folds[self.hFocus or 1]
                if it then self:helpFold(it.sec.id) end
            end
            return true
        end
        return false
    end
    if self._cmdButton then return self:_cmdButton(button, jd) end
    return false
end

function W:_pagePrompts(out)
    if self.page == "help" then
        if self.zone == "pband" then
            out[#out + 1] = { glyph = "A", label = tr("UI_ZeD_Prompt_Press") }
        else
            local folds = helpFolds((self:_helpNow()))
            local it = folds[self.hFocus or 1]
            if it then out[#out + 1] = { glyph = "A", label = (self.hFold and self.hFold[it.sec.id]) and tr("UI_ZeD_Prompt_Unfold") or tr("UI_ZeD_Prompt_Fold") } end
        end
        return
    end
    if self._cmdPrompts then self:_cmdPrompts(out) end
end

function W:_pageBLabel()
    if self._cmdBLabel then return self:_cmdBLabel() end
    return nil
end

function W:_pageLeave(old)
    if old == "help" then self.hSeek = nil end
    if self._cmdLeave then self:_cmdLeave(old) end
end

function W:_pageClose()
    if self._cmdClose then return self:_cmdClose() end
    return {}
end

return W
