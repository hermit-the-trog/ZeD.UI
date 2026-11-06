-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Chat.lua
-- ============================================================================
-- CHAT (the director's multiplayer decisions, Nov 5 2026: ZeDUI/MP_DECISIONS.md, section 2)
-- On a server, the game's chat box at the lower left is replaced by:
--   * a chat key on the belt, next to the Messages note, with the count of new lines (ZeD_Belt.lua)
--   * a chat window you drag and size, which stays where you put it (kept in Lua/ZeD_chatwin.txt). Tabs as the
--     game's: General, Faction, Safehouse, Private, Admin (Faction and Safehouse while you have one, Admin for
--     admins). When idle it dims where it is; a new line brings it back to full strength. No fading out.
--   * the game's chat key (T) opens it with the line to type in; on a controller the chat key opens it to read,
--     and the pad keyboard opens only when you pick the line (A on it).
-- The game's chat stays the engine and is never shown: every line still arrives through the game's OnAddMessage,
-- and what you type goes out through the game's own calls for each channel (processSayMessage, proceedPM ...),
-- with the game's slash commands (/all /s /y /w /f /sh /a, and the rest to the server) and its slow mode.
-- In safe mode (SafeMode.lua, piece "chat") the game's chat comes back as it was.
-- ============================================================================

require "ZeD/Tr"
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/Organisms"
require "Chat/ISChat"

ZeD = ZeD or {}
ZeD.Chat = ZeD.Chat or {}
local C = ZeD.Chat

local MAX_LINES = 300            -- the oldest go first (FIFO)
local IDLE_MS = 12000            -- no new line, no typing, no pointer for this long: the window dims
local DIM_A = 0.35               -- the dimmed window's surfaces and words
local U = { W = 440, H = 260, MIN_W = 300, MIN_H = 160, PAD = 8, GAP = 6, LINE_GAP = 2 }   -- design units

C.lines = C.lines or {}
C.unreadN = C.unreadN or 0
C.tab = C.tab or "general"
C.lastLineAt = 0
C.slowUntil = 0

local function tr(k, ...) return ZeD.tr(k, ...) end
local function safe(fn, d) local ok, v = pcall(fn); if ok and v ~= nil then return v end; return d end
local function px(n) return ZeD.T.px(n) end

-- ---------------------------------------------------------------------------
-- WHERE IT RUNS: a server, ZeD not in safe mode
-- ---------------------------------------------------------------------------
function C.active()
    return isClient() and not (ZeD.Safe and ZeD.Safe.on("chat"))
end
function C.onBelt() return C.active() end
function C.unread() return C.unreadN end

-- ---------------------------------------------------------------------------
-- THE TABS: which channels each shows, and where plain typing goes
-- ---------------------------------------------------------------------------
-- (ChatType's names: general, whisper, say, shout, faction, safehouse, radio, admin, server, notDefined)
local TABS = {
    { id = "general",   key = "UI_ZeD_Chat_TabGeneral",   kinds = { general = true, say = true, shout = true, radio = true, server = true, notDefined = true }, stream = "say" },
    { id = "faction",   key = "UI_ZeD_Chat_TabFaction",   kinds = { faction = true }, stream = "faction" },
    { id = "safehouse", key = "UI_ZeD_Chat_TabSafehouse", kinds = { safehouse = true }, stream = "safehouse" },
    { id = "private",   key = "UI_ZeD_Chat_TabPrivate",   kinds = { whisper = true }, stream = "whisper" },
    { id = "admin",     key = "UI_ZeD_Chat_TabAdmin",     kinds = { admin = true }, stream = "admin" },
}
C.TABS = TABS
local function tabOf(id) for _, t in ipairs(TABS) do if t.id == id then return t end end; return TABS[1] end

-- the tabs this player has: Faction and Safehouse while in one, Admin for an admin
function C.tabsShown(p)
    p = p or getPlayer()
    local out = {}
    for _, t in ipairs(TABS) do
        local show = true
        if t.id == "faction" then show = safe(function() return Faction.getPlayerFaction(p) ~= nil end, false)
        elseif t.id == "safehouse" then show = safe(function() return SafeHouse.hasSafehouse(p) ~= nil end, false)
        elseif t.id == "admin" then show = safe(function() return p:getRole():hasAdminTool() end, false) end
        if show then out[#out + 1] = t end
    end
    return out
end

-- ---------------------------------------------------------------------------
-- THE LINES (the game's OnAddMessage)
-- ---------------------------------------------------------------------------
-- the game's rich-text marks (<RGB:1,0,0>, <LINE>, <SIZE:small> ...) are not words
local function plain(s)
    s = tostring(s or "")
    s = s:gsub("<[A-Z][A-Z_]*:?[^>]*>", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    return s
end

function C.onMessage(message)
    if not C.active() then return end
    local author = safe(function() return message:getAuthor() end, nil)
    -- (muted in the game's chat: kept out here too)
    local muted = safe(function() return ISChat.instance and ISChat.instance.mutedUsers and ISChat.instance.mutedUsers[author] end, nil)
    if author and muted then return end
    -- (muted by staff, on the server's list: ZeD_Admin.lua. Staff still read them, marked)
    local staffMuted = author and ZeD.Admin and ZeD.Admin.isMuted and ZeD.Admin.isMuted(author)
    if staffMuted and not (ZeD.Adm.MUTE_STAFF_SEES and ZeD.Admin.can("BanUnbanUser")) then return end
    local kind = safe(function() return tostring(message:getChat():getType()) end, "general")
    if safe(function() return message:isServerAlert() end, false) then kind = "server" end
    local text = plain(safe(function() return message:getText() end, ""))
    if text == "" then return end
    -- the server's DEFAULT welcome (ServerOptions' ServerWelcomeMessage as shipped) tells of the game's chat box, its
    -- Tab key and Gear icon, which ZeD's window does not have: ZeD's own line instead. A welcome the server's admin
    -- wrote is kept as written.
    if text:find("Welcome to Project Zomboid Multiplayer!", 1, true) and text:find("Gear icon", 1, true) then
        text = tr("UI_ZeD_Chat_Welcome")
    end
    local col = nil
    if safe(function() return message:isCustomColor() end, false) then
        local c = safe(function() return message:getTextColor() end, nil)
        if c then col = { r = safe(function() return c:getR() end, 1), g = safe(function() return c:getG() end, 1), b = safe(function() return c:getB() end, 1) } end
    end
    local L = C.lines
    if staffMuted then text = tr("UI_ZeD_Adm_MutedLine", text) end
    L[#L + 1] = {
        text = text, author = (author and author ~= "") and author or nil, kind = kind, color = col,
        time = safe(function() return message:getDatetimeStr() end, ""),
    }
    while #L > MAX_LINES do table.remove(L, 1) end
    C.lastLineAt = getTimestampMs()
    local win = C.win
    if not (win and win:getIsVisible()) then C.unreadN = C.unreadN + 1 end
    if win then win._dirty = true end
end

-- a repeating server message (ZeD_ServerAdmin.lua): server Lua cannot reach the game's chat, so it arrives here and goes
-- in the same list as the game's own server alerts
function C.serverLine(text)
    if not C.active() or type(text) ~= "string" or text == "" then return end
    local L = C.lines
    L[#L + 1] = { text = plain(text), kind = "server", time = "" }
    while #L > MAX_LINES do table.remove(L, 1) end
    C.lastLineAt = getTimestampMs()
    local win = C.win
    if not (win and win:getIsVisible()) then C.unreadN = C.unreadN + 1 end
    if win then win._dirty = true end
end

-- ---------------------------------------------------------------------------
-- NAME COLORS (the director, Nov 5 2026: "Allow players to select their username color in the chat. So it helps
-- distinguish who's talking.") The game already has the setting: the multiplayer text color (its Options' color
-- picker, getCore():getMpTextColor()), the color of your speech over your head, which the server shares with every
-- player (setSpeakColourInfo, sendPersonalColor). A line's name is drawn in its author's speak color; a player out of
-- reach, or a color that would not read on this player's window (under 3:1 against its surface), takes the theme's
-- heading color. The chat window's menu sets your own, the game's way, so it shows for everyone and in the game's
-- Options too.
-- ---------------------------------------------------------------------------
C.PALETTE = {
    { k = "red",    name = "ContextMenu_Red",    r = 0.90, g = 0.32, b = 0.30 },
    { k = "orange", name = "ContextMenu_Orange", r = 0.95, g = 0.58, b = 0.20 },
    { k = "yellow", name = "ContextMenu_Yellow", r = 0.95, g = 0.85, b = 0.30 },
    { k = "green",  name = "ContextMenu_Green",  r = 0.42, g = 0.80, b = 0.40 },
    { k = "teal",   name = "UI_ZeD_Accent_Teal", r = 0.30, g = 0.80, b = 0.75 },
    { k = "blue",   name = "ContextMenu_Blue",   r = 0.42, g = 0.62, b = 0.95 },
    { k = "purple", name = "ContextMenu_Purple", r = 0.70, g = 0.52, b = 0.95 },
    { k = "pink",   name = "ContextMenu_Pink",   r = 0.95, g = 0.50, b = 0.75 },
    { k = "white",  name = "ContextMenu_White",  r = 0.95, g = 0.95, b = 0.95 },
}
local function lum(c)
    local function ch(v) if v <= 0.03928 then return v / 12.92 end; return ((v + 0.055) / 1.055) ^ 2.4 end
    return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b)
end
local function contrast(a, b)
    local la, lb = lum(a), lum(b)
    if la < lb then la, lb = lb, la end
    return (la + 0.05) / (lb + 0.05)
end
-- the color the game keeps for you (your Options' multiplayer text color)
function C.myColor()
    return safe(function()
        local c = getCore():getMpTextColor()
        return { r = c:getR(), g = c:getG(), b = c:getB() }
    end, nil)
end
-- an author's color, looked up again every few seconds (nil: not known here)
C._names = C._names or {}
function C.nameColor(author)
    if not author then return nil end
    local now = getTimestampMs()
    local e = C._names[author]
    if e and now - e.t < 3000 then return e.c end
    local c = nil
    local me = safe(function() return getPlayer():getUsername() end, nil)
    if author == me then c = C.myColor()
    else
        c = safe(function()
            local p = getPlayerFromUsername(author)
            local sc = p and p:getSpeakColour()
            return sc and { r = sc:getR(), g = sc:getG(), b = sc:getB() } or nil
        end, nil)
    end
    C._names[author] = { t = now, c = c }
    return c
end
-- the name's color as it draws on this window: the author's, else the heading color
function C.nameInk(author)
    local T = ZeD.T
    local c = C.nameColor(author)
    if c and T.surf1 and contrast(c, T.surf1) >= 3 then return c end
    return T.textHead
end
-- your own color, set the game's way (Options' gameOption.apply for the multiplayer text color)
function C.setMyColor(e)
    local ok, err = pcall(function()
        getCore():setMpTextColor(ColorInfo.new(e.r, e.g, e.b, 1))
        getCore():saveOptions()
        local p = getPlayer()
        if p then
            p:setSpeakColourInfo(getCore():getMpTextColor())
            sendPersonalColor(p)
        end
    end)
    if not ok then ZeD.logOnce("chat name color", err) end
    C._names = {}
end
-- the chat window's menu: Name color, the palette with a check by the one you have
function C.menuItems()
    local cur = C.myColor()
    local kids = {}
    for _, e in ipairs(C.PALETTE) do
        local entry = e
        kids[#kids + 1] = {
            name = getTextOrNull(e.name) or tr(e.name), category = "pick",
            onFire = function() C.setMyColor(entry) end,
            checked = function()
                local c = C.myColor()
                return c ~= nil and math.abs(c.r - entry.r) < 0.02 and math.abs(c.g - entry.g) < 0.02 and math.abs(c.b - entry.b) < 0.02
            end,
        }
    end
    return { { name = tr("UI_ZeD_Chat_NameColor"), category = "own", children = kids } }
end

-- ---------------------------------------------------------------------------
-- SENDING: as the game's ISChat:onCommandEntered, for the tab you are in
-- ---------------------------------------------------------------------------
local STREAMS = {   -- the game's ISChat.allChatStreams: command, short command, the stream
    { "/say ", "/s ", "say" }, { "/yell ", "/y ", "yell" }, { "/whisper ", "/w ", "whisper" },
    { "/faction ", "/f ", "faction" }, { "/safehouse ", "/sh ", "safehouse" }, { "/all ", nil, "general" },
    { "/admin ", "/a ", "admin" },
}
local SEND = {
    say = function(t) processSayMessage(t) end,
    yell = function(t) processShoutMessage(t) end,
    whisper = function(t) proceedPM(t) end,
    faction = function(t) proceedFactionMessage(t) end,
    safehouse = function(t) processSafehouseMessage(t) end,
    general = function(t) processGeneralMessage(t) end,
    admin = function(t) processAdminChatMessage(t) end,
}

-- seconds left of the server's slow mode (0: you may send)
function C.slowLeft()
    local left = C.slowUntil - getTimestampMs()
    if left <= 0 then return 0 end
    return math.ceil(left / 1000)
end

-- returns true when it went (or was a command), false with a reason key when it did not
function C.send(text)
    local p = getPlayer()
    if not p then return false end
    local cap = function(name) return safe(function() return p:getRole():hasCapability(Capability[name]) end, false) end
    -- (a slash command still goes: it may be staff's, and the mute is about chat)
    if ZeD.Admin and ZeD.Admin.isMuted and ZeD.Admin.isMuted(p:getUsername()) and tostring(text or ""):sub(1, 1) ~= "/" then return false, "muted" end
    if not cap("IgnoreChatSlowMode") and C.slowLeft() > 0 then return false, "slow" end
    if not cap("EmptyLinesInChat") then text = tostring(text or ""):gsub("[\n\r]", " ") end
    if not text or text:gsub("%s", "") == "" then return false end
    local stream, body = nil, text
    for _, s in ipairs(STREAMS) do
        local cmd = (text:sub(1, #s[1]) == s[1] and s[1]) or (s[2] and text:sub(1, #s[2]) == s[2] and s[2]) or nil
        if cmd then stream, body = s[3], text:sub(#cmd + 1); break end
    end
    if not stream then
        if text:sub(1, 1) == "/" then
            -- any other command goes to the server as typed (the game's /help, an admin's commands)
            pcall(SendCommandToServer, text)
            return true
        end
        stream = tabOf(C.tab).stream
    end
    if body:gsub("%s", "") == "" then return false end
    local fn = SEND[stream]
    if not fn then return false end
    local ok, err = pcall(fn, body)
    if not ok then ZeD.logOnce("chat send " .. stream, err); return false end
    if not cap("IgnoreChatSlowMode") then
        local secs = safe(function() return getServerOptions():getInteger("ChatMessageSlowModeTime") end, 0)
        C.slowUntil = getTimestampMs() + secs * 1000
    end
    -- (as the game does: the Enter that sent it must not reach the game as a key)
    pcall(doKeyPress, false)
    C._keysBackIn = 20
    return true
end

-- ---------------------------------------------------------------------------
-- THE WINDOW
-- ---------------------------------------------------------------------------
ZeD_ChatWindow = ZeD_Window:derive("ZeD_ChatWindow")

function ZeD_ChatWindow:new(x, y, w, h)
    local o = ZeD_Window.new(self, x, y, w, h, "")
    o.resizable = true
    o.pin = true
    o.moveWithMouse = false
    o.playerNum = 0
    o.scroll = 0           -- px up from the newest line (0: at the bottom)
    o.zone = "lines"       -- controller: "tabs" | "lines" | "input"
    o._dirty = true
    o._usedAt = getTimestampMs()
    o.extraMenu = function() return C.menuItems() end
    o:setWantKeyEvents(true)
    return o
end

function ZeD_ChatWindow:createChildren()
    ZeD_Window.createChildren(self)
    local T = ZeD.T
    local entry = ISTextEntryBox:new("", 0, 0, 100, T.inputH)
    entry:initialise()
    entry:instantiate()
    entry.zedEntry = true
    entry.javaObject:setCentreVertically(true)
    entry:setPlaceholderText(tr("UI_ZeD_Chat_Type"))
    entry.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    entry.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    entry:setMaxTextLength(500)
    local win = self
    entry.onCommandEntered = function() win:submit() end
    -- (Escape leaves the line, as the game's chat does)
    entry.onOtherKey = function(_, key) if key == Keyboard.KEY_ESCAPE then entry:unfocus() end end
    self:addChild(entry)
    self.input = entry
end

function ZeD_ChatWindow:submit()
    local text = self.input:getText() or ""
    local ok, why = C.send(text)
    if ok then
        -- a whisper keeps "/w name " for the next one, as the game's chat does
        local keep = text:match("^(/w%a* %S+ )") or ""
        self.input:setText(keep)
        self.scroll = 0
    elseif why == "slow" then
        self._slowNote = true
    elseif why == "muted" then
        C.serverLine(tr("UI_ZeD_Adm_YouMuted"))
    end
    self._usedAt = getTimestampMs()
    self.input:unfocus()
end

-- the window is in use: the pointer on it, the line being typed in, the pad on it, or a line came lately
function ZeD_ChatWindow:_idle()
    local now = getTimestampMs()
    if self.input and self.input:isFocused() then self._usedAt = now end
    if self:isMouseOver() then self._usedAt = now end
    if self.joyfocus then self._usedAt = now end
    local last = math.max(self._usedAt or 0, C.lastLineAt or 0)
    return now - last > IDLE_MS
end
-- dimmed: the surfaces at DIM_A while idle (at once, no fade: ZeD has no animation), else as any window
function ZeD_ChatWindow:_surfaceAlpha(T)
    if self._dim then return DIM_A end
    return ZeD_Window._surfaceAlpha(self, T)
end

-- the lines of the open tab, wrapped to the width (built again when the lines, the tab or the width change)
function ZeD_ChatWindow:_wrapped(w)
    local T = ZeD.T
    local key = tostring(#C.lines) .. ":" .. tostring(C.lines[#C.lines]) .. ":" .. C.tab .. ":" .. w .. ":" .. tostring(T)
    if self._wrapKey == key and self._wrap then return self._wrap end
    local tab = tabOf(C.tab)
    local out = {}
    local f = T.fontF2
    for _, ln in ipairs(C.lines) do
        if tab.kinds[ln.kind] then
            local head = ln.author and (ln.author .. ": ") or ""
            if ln.kind == "whisper" and ln.author then head = tr("UI_ZeD_Chat_From", ln.author) .. " " end
            if ln.kind == "shout" then head = ln.author and tr("UI_ZeD_Chat_Shouts", ln.author) .. " " or "" end
            local parts = ZeD.Atoms.wrapText(head .. ln.text, f, w)
            -- (the head's width with its space: MeasureStringX does not count a trailing space)
            local hw = 0
            if head ~= "" then
                local sp = ZeD.TM:MeasureStringX(f, "a a") - ZeD.TM:MeasureStringX(f, "aa")
                hw = ZeD.TM:MeasureStringX(f, (head:gsub("%s+$", ""))) + math.max(sp, px(3))
            end
            for i, s in ipairs(parts) do out[#out + 1] = { s = s, ln = ln, first = i == 1, headW = (i == 1) and hw or 0, head = head } end
        end
    end
    self._wrap, self._wrapKey = out, key
    return out
end

function ZeD_ChatWindow:prerender()
    local T = ZeD.T
    if not T then return end
    if not C.active() then self:close(); return end
    self.minimumWidth, self.minimumHeight = px(U.MIN_W), px(U.MIN_H)
    self.title = tr("UI_ZeD_Chat_Title")
    self._dim = self:_idle()
    ZeD_Window.prerender(self)
    local ok, err = pcall(self._drawBody, self)
    if not ok then ZeD.logOnce("chat window", err) end
end

-- the tabs, the lines, the line to type in
function ZeD_ChatWindow:_drawBody()
    local T = ZeD.T
    local M = ZeD.Molecules
    local w = self.width
    local pad = px(U.PAD)
    local top = self:titleBarHeight()
    local bot = self.height - self:footerHeight()
    local tabs = C.tabsShown()
    -- (a tab you no longer have: back to General)
    local has = false
    for _, t in ipairs(tabs) do if t.id == C.tab then has = true end end
    if not has then C.tab = "general" end
    local mx, my = self:getMouseX(), self:getMouseY()
    local Fo = ZeD.Input and ZeD.Input.Focus
    local cues = Fo and Fo.cuesVisible and Fo.cuesVisible()
    -- the tabs
    local tx, ty = pad, top + px(U.GAP)
    self._tabHits = {}
    for i, t in ipairs(tabs) do
        local label = tr(t.key)
        local hov = (not cues) and my >= ty and my < ty + T.tabH and mx >= tx and mx < tx + M.buttonW(label)
        local foc = (self.joyfocus and self.zone == "tabs" and C.tab == t.id) and { win = self } or nil
        local tw = M.drawTab(self, tx, ty, label, C.tab == t.id, hov, false, { focus = foc })
        self._tabHits[#self._tabHits + 1] = { x = tx, y = ty, w = tw, h = T.tabH, id = t.id }
        tx = tx + tw + px(2)
    end
    -- the line to type in, and Send, at the foot
    local ih = T.inputH
    local iy = bot - pad - ih
    local sendLabel = tr("UI_ZeD_Chat_Send")
    local sw = M.buttonW(sendLabel)
    local iw = w - 2 * pad - px(U.GAP) - sw
    local inp = self.input
    if inp then
        if inp:getX() ~= pad then inp:setX(pad) end
        if inp:getY() ~= iy then inp:setY(iy) end
        if inp:getWidth() ~= iw then inp:setWidth(iw) end
        if inp:getHeight() ~= ih then inp:setHeight(ih) end
    end
    local s1, bs = T.surf1, T.borderS
    self:drawRect(pad, iy, iw, ih, s1.a or 1, s1.r, s1.g, s1.b)
    local ib = (inp and inp:isFocused()) and T.accent or bs
    self:drawRectBorder(pad, iy, iw, ih, ib.a or 1, ib.r, ib.g, ib.b)
    if self.joyfocus and self.zone == "input" and ZeD.Focus and ZeD.Focus.mark then ZeD.Focus.mark(self, pad, iy, iw, ih, { win = self }) end
    local sx = pad + iw + px(U.GAP)
    local shov = (not cues) and mx >= sx and mx < sx + sw and my >= iy and my < iy + ih
    local slow = C.slowLeft()
    local mutedMe = ZeD.Admin and ZeD.Admin.isMuted and ZeD.Admin.isMuted(ZeD.Admin.me())
    local sendHelp = (mutedMe and tr("UI_ZeD_Adm_YouMuted")) or ((slow > 0) and tr("UI_ZeD_Chat_Slow", slow)) or tr("UI_ZeD_Chat_HelpSend")
    M.drawButton(self, sx, iy, sw, ih, sendLabel, "primary", shov and isMouseButtonDown(0), nil,
        { hover = shov, disabled = slow > 0 or mutedMe, win = self, help = sendHelp })
    self._sendRect = { x = sx, y = iy, w = sw, h = ih }
    self._inputRect = { x = pad, y = iy, w = iw, h = ih }
    -- the lines, newest at the bottom, between the tabs and the line to type in
    local ly0, ly1 = ty + T.tabH + px(U.GAP), iy - px(U.GAP)
    self._linesRect = { x = pad, y = ly0, w = w - 2 * pad, h = ly1 - ly0 }
    self:_drawLines(pad, ly0, w - 2 * pad, ly1 - ly0)
    if self._dim then
        -- (the words dim with the window: a wash of the base over the body)
        local b = T.base or { r = 0, g = 0, b = 0 }
        self:drawRect(0, top, w, bot - top, 1 - DIM_A - 0.2, b.r, b.g, b.b)
    end
end

function ZeD_ChatWindow:_drawLines(x, y, w, h)
    local T = ZeD.T
    local f = T.fontF2
    local lh = ZeD.TM:getFontHeight(f) + px(U.LINE_GAP)
    local rows = self:_wrapped(w)
    local total = #rows * lh
    local maxS = math.max(0, total - h)
    if self.scroll > maxS then self.scroll = maxS end
    if self.scroll < 0 then self.scroll = 0 end
    self._maxScroll = maxS
    if #rows == 0 then
        ZeD.Molecules.drawEmptyLine(self, x, y, w, tr("UI_ZeD_Chat_Nothing"))
        return
    end
    self:setStencilRect(x, y, w, h)
    -- the bottom row sits at the foot; scroll moves the list down
    local by = y + h - lh + self.scroll
    local tc, hd, ac = T.text, T.textHead, T.accent
    for i = #rows, 1, -1 do
        local ry = by - (#rows - i) * lh
        if ry + lh < y then break end
        if ry <= y + h then
            local r = rows[i]
            local c = r.ln.color or ((r.ln.kind == "server" or r.ln.kind == "admin") and ac) or tc
            if r.first and r.headW > 0 then
                local nc = C.nameInk(r.ln.author) or hd
                self:drawText((r.head:gsub("%s+$", "")), x, ry, nc.r, nc.g, nc.b, nc.a or 1, f)
                self:drawText(r.s:sub(#r.head + 1), x + r.headW, ry, c.r, c.g, c.b, c.a or 1, f)
            else
                self:drawText(r.s, x, ry, c.r, c.g, c.b, c.a or 1, f)
            end
        end
    end
    self:clearStencilRect()
    -- (scrolled up: a mark at the foot that newer lines are below)
    if self.scroll > 0 then
        ZeD.Atoms.drawStatusDot(self, x + w - px(8), y + h - px(8), ac, px(6))
    end
end

function ZeD_ChatWindow:render() ZeD_Window.render(self) end

-- the help line's words for what the pointer is over (the window's footer)
function ZeD_ChatWindow:getStatusLine()
    if C.slowLeft() > 0 then return tr("UI_ZeD_Chat_Slow", C.slowLeft()) end
    if self.scroll > 0 then return tr("UI_ZeD_Chat_Older") end
    return tr("UI_ZeD_Chat_Help")
end

local function inRect(r, x, y) return r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end

function ZeD_ChatWindow:closeAction()
    pcall(function() getSoundManager():playUISound("UIActivateButton") end)
    self:close()
end
function ZeD_ChatWindow:close()
    C.savePlace(self)
    if self.input then self.input:unfocus() end
    self:setVisible(false)
    self:removeFromUIManager()
    if JoypadState.players[self.playerNum + 1] and self.joyfocus then setJoypadFocus(self.playerNum, nil) end
    C.win = nil
end

function ZeD_ChatWindow:pickTab(id)
    if C.tab == id then return end
    C.tab = id
    self.scroll = 0
    pcall(function() getSoundManager():playUISound("UISelectListItem") end)
end

function ZeD_ChatWindow:onMouseDown(x, y)
    if not self:getIsVisible() then return true end
    self._usedAt = getTimestampMs()
    local cb = self:closeRect()
    if cb and inRect(cb, x, y) then return true end
    if inRect(self:windowBoxRect(), x, y) then return true end
    for _, t in ipairs(self._tabHits or {}) do
        if inRect(t, x, y) then self:pickTab(t.id); return true end
    end
    if inRect(self._sendRect, x, y) then
        if C.slowLeft() == 0 then self:submit() end
        return true
    end
    if inRect(self._inputRect, x, y) then self.input:focus(); return true end
    -- anywhere else: the title bar drags (ZeD_Window), the rest does nothing
    return ZeD_Window.onMouseDown(self, x, y)
end

function ZeD_ChatWindow:onMouseWheel(del)
    local lh = ZeD.TM:getFontHeight(ZeD.T.fontF2) + px(U.LINE_GAP)
    self.scroll = math.max(0, math.min(self._maxScroll or 0, self.scroll - del * lh * 3))
    self._usedAt = getTimestampMs()
    return true
end

function ZeD_ChatWindow:update()
    ZeD_Window.update(self)
    local jd = JoypadState and JoypadState.players and JoypadState.players[self.playerNum + 1]
    self.joyfocus = (jd and jd.focus == self) and jd or nil
    if self.joyfocus then self._usedAt = getTimestampMs() end
    -- the place is kept a moment after a drag or a resize ends
    local now = getTimestampMs()
    if not (self._saveAt and now - self._saveAt < 2000) then self._saveAt = now; C.savePlace(self) end
end

function ZeD_ChatWindow:isKeyConsumed(key) return key == Keyboard.KEY_ESCAPE end
function ZeD_ChatWindow:onKeyPress(key)
    if key == Keyboard.KEY_ESCAPE then self:close(); GameKeyboard.eatKeyPress(key) end
end

-- the controller: the tabs (left / right), the lines (up / down scroll), the line to type in (A: the pad keyboard)
function ZeD_ChatWindow:onGainJoypadFocus(jd) self.joyfocus = jd end
function ZeD_ChatWindow:onLoseJoypadFocus(jd) self.joyfocus = nil end
function ZeD_ChatWindow:onJoypadDown(button, jd)
    if button == Joypad.BButton then self:close(); return end
    if button == Joypad.AButton and self.zone == "input" then
        if OnScreenKeyboard and OnScreenKeyboard.Show then
            local ok = pcall(OnScreenKeyboard.Show, self.playerNum, self.input, jd)
            if not ok then self.input:focus() end
        else
            self.input:focus()
        end
    end
end
function ZeD_ChatWindow:_padStep(dir)
    local tabs = C.tabsShown()
    if self.zone == "tabs" and (dir == "left" or dir == "right") then
        for i, t in ipairs(tabs) do
            if t.id == C.tab then
                local j = i + ((dir == "right") and 1 or -1)
                if tabs[j] then self:pickTab(tabs[j].id) end
                return
            end
        end
    end
    local lh = ZeD.TM:getFontHeight(ZeD.T.fontF2) + px(U.LINE_GAP)
    if dir == "up" then
        if self.zone == "input" then self.zone = "lines"
        elseif self.zone == "lines" and self.scroll < (self._maxScroll or 0) then self.scroll = math.min(self._maxScroll or 0, self.scroll + lh * 3)
        elseif self.zone == "lines" then self.zone = "tabs" end
    elseif dir == "down" then
        if self.zone == "tabs" then self.zone = "lines"
        elseif self.zone == "lines" and self.scroll > 0 then self.scroll = math.max(0, self.scroll - lh * 3)
        elseif self.zone == "lines" then self.zone = "input" end
    end
    pcall(function() getSoundManager():playUISound("UISelectListItem") end)
end
function ZeD_ChatWindow:onJoypadDirUp() self:_padStep("up") end
function ZeD_ChatWindow:onJoypadDirDown() self:_padStep("down") end
function ZeD_ChatWindow:onJoypadDirLeft() self:_padStep("left") end
function ZeD_ChatWindow:onJoypadDirRight() self:_padStep("right") end
function ZeD_ChatWindow:getFooterPrompts()
    if not self.joyfocus then return nil end
    local Pr = ZeD.Prompt
    local move = tr(self.zone == "tabs" and "UI_ZeD_Chat_PadTabs" or "UI_ZeD_Chat_PadMove")
    local P = { (Pr and Pr.padNote) and Pr.padNote(move) or move }
    if self.zone == "input" then P[#P + 1] = { glyph = "A", label = tr("UI_ZeD_Chat_PadType") } end
    P[#P + 1] = { glyph = "B", label = getText("UI_Close") }
    return P
end

-- ---------------------------------------------------------------------------
-- ITS PLACE, kept on this computer (Lua/ZeD_chatwin.txt: x y w h in design units, and the tab)
-- ---------------------------------------------------------------------------
function C.savePlace(win)
    if not win then return end
    local T = ZeD.T
    local sc = (T and T.scale) or 1
    local s = string.format("%d %d %d %d %s", math.floor(win:getX() / sc), math.floor(win:getY() / sc),
        math.floor(win:getWidth() / sc), math.floor((win.windowShaded and win.preShadeHeight or win:getHeight()) / sc), C.tab)
    if s == C._savedPlace then return end
    C._savedPlace = s
    pcall(function()
        local f = getFileWriter("ZeD_chatwin.txt", true, false)
        f:write(s); f:close()
    end)
end
local function readPlace()
    local r = getFileReader("ZeD_chatwin.txt", false)
    if not r then return nil end
    local l = r:readLine()
    r:close()
    if not l then return nil end
    local x, y, w, h, tab = l:match("^(%-?%d+) (%-?%d+) (%d+) (%d+) ?(%a*)")
    if not x then return nil end
    return tonumber(x), tonumber(y), tonumber(w), tonumber(h), tab
end

-- ---------------------------------------------------------------------------
-- OPEN, CLOSE (the belt's key, the game's chat key)
-- ---------------------------------------------------------------------------
function C.open(typing, pad)
    if not C.active() then return nil end
    local win = C.win
    if not win then
        local T = ZeD.T
        local sc = (T and T.scale) or 1
        local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
        -- (every value kept: safe() hands back only the first, and the rest came back nil, QA Nov 5 2026)
        local ok, x, y, w, h, tab = pcall(readPlace)
        if not ok then x = nil end
        if x and y and w and h then x, y, w, h = x * sc, y * sc, w * sc, h * sc
        else w, h = px(U.W), px(U.H); x, y = px(15), sh - h - px(140) end
        -- (on the screen, whatever screen it was kept on)
        w = math.min(w, sw); h = math.min(h, sh)
        x = math.max(0, math.min(x, sw - w)); y = math.max(0, math.min(y, sh - h))
        if tab and tab ~= "" then C.tab = tab end
        win = ZeD_ChatWindow:new(x, y, w, h)
        win:initialise()
        win:instantiate()
        win:addToUIManager()
        win:setAlwaysOnTop(true)
        C.win = win
    end
    win:setVisible(true)
    win._usedAt = getTimestampMs()
    C.unreadN = 0
    if pad then
        local jd = JoypadState.players[1]
        if jd then win.zone = "lines"; jd.focus = win; updateJoypadFocus(jd) end
    elseif typing and win.input then
        win.zone = "input"
        win.input:focus()
    end
    return win
end
function C.toggle(pad)
    if C.win and C.win:getIsVisible() then C.win:close() else C.open(false, pad) end
end

-- the game's chat key opens ZeD's window with the line to type in (the game's own handler stays for safe mode)
C._origToggle = C._origToggle or (ISChat and ISChat.onToggleChatBox)
if ISChat and C._origToggle then
    ISChat.onToggleChatBox = function(key)
        if C.active() then
            if getCore():isKey(KeybindId.TOGGLE_CHAT, key) then
                -- (not while typing somewhere else: the key is then a letter)
                local w = C.win
                if not (w and w.input and w.input:isFocused()) then C.open(true) end
            end
            return
        end
        return C._origToggle(key)
    end
end

-- every tick on a server: the game's chat box hidden (it stays the engine), the game's keys back after a send
function C.tick()
    if C._keysBackIn then
        C._keysBackIn = C._keysBackIn - 1
        if C._keysBackIn <= 0 then C._keysBackIn = nil; pcall(doKeyPress, true) end
    end
    if not C.active() then return end
    local gc = ISChat and ISChat.instance
    if gc and gc:getIsVisible() then
        pcall(function() gc:unfocus() end)
        gc:setVisible(false)
    end
    -- a new line wakes the dimmed window (prerender reads C.lastLineAt)
end

if Events then
    if Events.OnAddMessage then Events.OnAddMessage.Add(C.onMessage) end
    if Events.OnTick then Events.OnTick.Add(C.tick) end
end

-- safe mode: the game's chat box back, ZeD's window closed
if ZeD.Safe and ZeD.Safe.register then
    ZeD.Safe.register("chat", {
        leave = function()
            if C.win then C.win:close() end
            local gc = ISChat and ISChat.instance
            if gc then gc:setVisible(true) end
        end,
    })
end

return C
