-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Chat.lua
-- ============================================================================
-- CHAT — multiplayer chat as a ZeD window. Client organism (ZeD_ChatWindow, a
-- ZeD_Window) plus the ZeD.Chat table the belt and the admin feed call into.
-- On a server, the game's chat box at the lower left is replaced by:
--   * a chat key on the belt, next to the Messages note, with the count of new lines (ZeD_Belt.lua)
--   * a chat window you drag and size, which stays where you put it (kept in Lua/ZeD_chatwin.txt). Tabs as the
--     game's: General, Faction, Safehouse, Private, Admin (Faction and Safehouse while you have one, Admin for
--     admins). When idle it dims where it is; a new line brings it back to full strength. No fading out.
--     It first opens at the foot of the screen, just right of the belt's chat key. The roll box after its title rolls
--     it down to its title bar on the screen's bottom edge (the box again, a press on the bar, the chat key or T bring it
--     back up). The pin box keeps it open; pinned, with the pointer off it, it ghosts: its surfaces nearly clear, its
--     words whole (the director, Nov 23 2026).
--   * the game's chat key (T) opens it with the line to type in; on a controller the chat key opens it to read,
--     and the pad keyboard opens only when you pick the line (A on it).
--   * pick a line for what you can do about its sender: Report to the admins,
--     Mute (for you, kept in Lua/ZeD_chatmute.txt, nobody told), and for
--     admins Player card and Teleport. The buttons sit in the list under the line. On a controller Up and Down step through the
--     lines with a sender in view and scroll on past them, A picks, Left and Right walk the buttons, B goes back.
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
require "ZeD/ZeD_TicketProto"
require "Chat/ISChat"

ZeD = ZeD or {}
ZeD.Chat = ZeD.Chat or {}
local C = ZeD.Chat

local MAX_LINES = 300            -- the oldest go first (FIFO)
local IDLE_MS = 12000            -- no new line, no typing, no pointer for this long: the window dims
local DIM_A = 0.35               -- the dimmed window's surfaces and words
-- (W 440 to 360 and MIN_W 300 to 260: "a little more narrow", the director, Nov 23 2026)
local U = { W = 360, H = 260, MIN_W = 260, MIN_H = 160, PAD = 8, GAP = 6, LINE_GAP = 2 }   -- design units
-- pinned, the pointer off it: the alpha of every surface and line (its words stay whole) (the director, Nov 23 2026)
local GHOST_A = 0.15
C.GHOST_A = GHOST_A
local MUTE_FILE = "ZeD_chatmute.txt"
local MUTE_MAX = 200             -- names kept for one server, oldest out
local NOTE_MS = 6000             -- a press's answer stays in the help line this long

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
    local win = C.win
    if win then win._dirty = true end
    -- (muted by you: the line is kept for Unmute, and wakes nothing)
    if author and C.mutedByMe(author) then return end
    C.lastLineAt = getTimestampMs()
    -- (rolled down, only its title bar shows: the chat key counts the line, and the window stays down)
    if not (win and win:getIsVisible() and not win.windowShaded) then C.unreadN = C.unreadN + 1 end
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
    if not (win and win:getIsVisible() and not win.windowShaded) then C.unreadN = C.unreadN + 1 end   -- (rolled down: counted too)
    if win then win._dirty = true end
end

-- ---------------------------------------------------------------------------
-- YOUR OWN MUTE: on this computer, for this server. Nobody is told, and the server never hears of it. Their lines stay in the list
-- as a word, so Unmute gives them back. It covers this window; the words over a head are the game's.
-- ---------------------------------------------------------------------------
C.muteSeq = C.muteSeq or 0
local function muteKey()
    return safe(function() return tostring(getServerIP()) .. ":" .. tostring(getServerPort()) end, "")
end
-- every line of the file: { key, name }
local function readMutes()
    local out = {}
    local r = getFileReader(MUTE_FILE, false)
    if not r then return out end
    local l = r:readLine()
    while l do
        local at = string.find(l, "|", 1, true)
        if at then out[#out + 1] = { string.sub(l, 1, at - 1), string.sub(l, at + 1) } end
        l = r:readLine()
    end
    r:close()
    return out
end
local function loadMutes()
    C.myMutes = {}
    local key = muteKey()
    local ok, list = pcall(readMutes)
    if not ok then return end
    for _, e in ipairs(list) do
        if e[1] == key then C.myMutes[e[2]] = true end
    end
end
function C.mutedByMe(name)
    if type(name) ~= "string" then return false end
    if not C.myMutes then loadMutes() end
    return C.myMutes[string.lower(name)] == true
end
function C.setMuted(name, on)
    if not C.myMutes then loadMutes() end
    local low = string.lower(name)
    C.myMutes[low] = on and true or nil
    C.muteSeq = C.muteSeq + 1
    local ok, err = pcall(function()
        local key = muteKey()
        local list, mine = {}, 0
        for _, e in ipairs(readMutes()) do
            if not (e[1] == key and e[2] == low) then
                list[#list + 1] = e
                if e[1] == key then mine = mine + 1 end
            end
        end
        if on then
            list[#list + 1] = { key, low }
            mine = mine + 1
        end
        for i = 1, #list do
            if mine <= MUTE_MAX then break end
            if list[i] and list[i][1] == key then
                C.myMutes[list[i][2]] = nil
                list[i] = false
                mine = mine - 1
            end
        end
        local f = getFileWriter(MUTE_FILE, true, false)
        for _, e in ipairs(list) do
            if e then f:write(e[1] .. "|" .. e[2] .. "\n") end
        end
        f:close()
    end)
    if not ok then ZeD.logOnce("chat mute", err) end
end

-- ---------------------------------------------------------------------------
-- PICKING A LINE: what you can do about its sender
-- ---------------------------------------------------------------------------
function C.isAdmin()
    if C.qaAdmin ~= nil then return C.qaAdmin end
    return safe(function() return getPlayer():getRole():hasAdminTool() end, false) == true
end

-- a line with someone else behind it
function C.canPick(ln, me)
    return ln.author ~= nil and ln.author ~= me and ln.kind ~= "server"
end

-- a press's answer, for the help line
function C.note(text) C._note, C._noteAt = text, getTimestampMs() end
function C.noteNow()
    if C._note and getTimestampMs() - C._noteAt < NOTE_MS then return C._note end
    C._note = nil
    return nil
end

-- the lines around one in the open tab, for a report: the name, and what its reporter's screen held
function C.around(ln)
    local tab = tabOf(C.tab)
    local shown, at = {}, nil
    for _, l in ipairs(C.lines) do
        if tab.kinds[l.kind] then
            shown[#shown + 1] = l
            if l == ln then at = #shown end
        end
    end
    local r = { who = ln.author, n = 0 }
    if not at then return r end
    local reach = ZeD.Tk.REPORT_AROUND
    for i = math.max(1, at - reach), math.min(#shown, at + reach) do
        local l = shown[i]
        r.n = r.n + 1
        r[r.n] = { who = l.author or "", text = l.text, t = l.time or "", mark = (l == ln) and true or nil }
    end
    return r
end

-- a press in chat that opened a card in a window: the pad goes with it. openTab only presses the tab, and chat let go of the pad
function C.padTo(mod)
    local Fo = ZeD.Input and ZeD.Input.Focus
    if ZeD_CharacterWindow and ZeD_CharacterWindow.ensureBothOpenForGamepad then pcall(ZeD_CharacterWindow.ensureBothOpenForGamepad, 0) end
    local win = mod and mod.getWindow and mod.getWindow()
    if not (win and Fo and Fo.claimFocus) then return end
    if Fo.getFocusedWindow() == win then Fo.reclaimEngineFocus() else Fo.claimFocus(win) end
end

-- the buttons under a picked line. live: why it is gray, read as it draws
function C.actions(ln)
    local who = ln.author
    local list = {
        { id = "report", text = tr("UI_ZeD_Chat_Report"), help = tr("UI_ZeD_Chat_HelpReport"), run = function(win)
            local r = C.around(ln)
            local pn = win.playerNum or 0
            local pad = win.joyfocus ~= nil
            if pad then win:close() end
            if ZeD.TicketCards and ZeD.TicketCards.reportFromChat then ZeD.TicketCards.reportFromChat(pn, r) end
            if pad then C.padTo(ZeD_CharacterWindow) end
        end },
        { id = "mute", text = tr(C.mutedByMe(who) and "UI_ZeD_Chat_Unmute" or "UI_ZeD_Chat_MuteYou"), help = tr("UI_ZeD_Chat_HelpMute"), run = function()
            local on = not C.mutedByMe(who)
            C.setMuted(who, on)
            C.note(tr(on and "UI_ZeD_Chat_MuteDone" or "UI_ZeD_Chat_UnmuteDone", who))
        end },
    }
    if C.isAdmin() then
        local Ad = ZeD.Admin
        list[3] = { id = "card", text = tr("UI_ZeD_Tk_PlayerCard"), help = tr("UI_ZeD_Tk_HelpPlayerCard"),
            live = function(c)
                -- (the game's own window, with no server part: it opens only on someone this client can see)
                if not (Ad and Ad.live()) and ZeD.TicketCards then
                    c.author = who
                    ZeD.TicketCards._D.livePlayerCard(c)
                    return
                end
                c.why = (Ad and not Ad.can("CanSeePlayersStats")) and Ad.why("CanSeePlayersStats") or nil
                c.disabled = c.why ~= nil
            end,
            run = function(win)
                local pad = win.joyfocus ~= nil
                if pad then win:close() end
                if Ad and Ad.live() then
                    Ad.openPlayerNext = who
                    if ZeD_WorldWindow and ZeD_WorldWindow.openTab then ZeD_WorldWindow.openTab(0, "admin") end
                    if pad then C.padTo(ZeD_WorldWindow) end
                elseif ZeD.TicketCards then
                    ZeD.TicketCards._D.playerCard(win, who)
                end
            end }
        list[4] = { id = "tp", text = getText("UI_Scoreboard_Teleport"), help = tr("UI_ZeD_Adm_HelpTp"),
            live = function(c)
                c.why = (Ad and not Ad.can("TeleportToPlayer")) and Ad.why("TeleportToPlayer") or nil
                c.disabled = c.why ~= nil
            end,
            run = function()
                if not Ad then return end
                Ad.teleport(who, function(a)
                    if a.ok == false then C.note(ZeD.AdminCards and ZeD.AdminCards._F.errOf(a) or tostring(a.err))
                    else C.note(tr("UI_ZeD_Adm_Teleported", who)) end
                end)
            end }
    end
    return list
end

-- the buttons in rows across width w: each gets dx, dy, w, h. Returns the height
function C.flowActions(list, w)
    local T, M = ZeD.T, ZeD.Molecules
    local gap = px(U.GAP)
    local bx, by = 0, 0
    for _, b in ipairs(list) do
        b.w, b.h = math.min(w, M.buttonW(b.text)), T.buttonH
        if bx > 0 and bx + b.w > w then
            bx = 0
            by = by + T.buttonH + gap
        end
        b.dx, b.dy = bx, by
        bx = bx + b.w + gap
    end
    return by + T.buttonH + px(U.LINE_GAP)
end

-- ---------------------------------------------------------------------------
-- NAME COLORS — a line's name drawn in its author's own color, so you can tell
-- who is talking. The game already has the setting: the multiplayer text color (its Options' color
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
    whisper = function(t) return proceedPM(t) end,     -- (the game's answer: the name it went to)
    faction = function(t) proceedFactionMessage(t) end,
    safehouse = function(t) processSafehouseMessage(t) end,
    general = function(t) processGeneralMessage(t) end,
    admin = function(t) processAdminChatMessage(t) end,
}
-- typed as commands, but the server hands the answer to every player as a line authored "Server", so the receiving side's
-- mute, which goes by author, cannot catch it (GameServer.receiveReceiveCommand tests these two prefixes as typed;
-- "/cardHello there" comes back to everyone as "Unknown command cardHello there"). The other commands an ordinary player
-- can run answer the sender alone, /r and /radio among them: they only name a channel for checkPlayerCanUseChat.
local function toldToAll(text)
    local head = text:sub(1, 5)
    return head == "/roll" or head == "/card"
end

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
    -- (the strip comes before the parse: a pasted newline is what makes "/s\nhi" into "/s hi")
    text = tostring(text or "")
    if not cap("EmptyLinesInChat") then text = text:gsub("[\n\r]", " ") end
    local stream, body, typed = nil, text, ""
    for _, s in ipairs(STREAMS) do
        local cmd = (text:sub(1, #s[1]) == s[1] and s[1]) or (s[2] and text:sub(1, #s[2]) == s[2] and s[2]) or nil
        if cmd then stream, body, typed = s[3], text:sub(#cmd + 1), cmd; break end
    end
    -- (the mute is about chat: any other slash command still goes, it may be staff's)
    local isChat = stream or text:sub(1, 1) ~= "/" or toldToAll(text)
    if isChat and ZeD.Admin and ZeD.Admin.isMuted and ZeD.Admin.isMuted(p:getUsername()) then return false, "muted" end
    if not cap("IgnoreChatSlowMode") and C.slowLeft() > 0 then return false, "slow" end
    if text:gsub("%s", "") == "" then return false end
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
    local ok, res = pcall(fn, body)
    if not ok then ZeD.logOnce("chat send " .. stream, res); return false end
    -- the game's chat keeps "/w name " for the next whisper and gives it back when the line is opened again
    -- (ISChat:onCommandEntered and ISChat:focus, one per tab). As there, a line typed with another stream's command
    -- takes its place (ZeD opens on the tab's own stream, so it lets it go); a plain line leaves it be
    if stream == "whisper" then
        local name = (type(res) == "string" and res ~= "") and res or body:match("^%s*(%S+)")
        C.keep = name and { text = typed .. name .. " ", tab = C.tab } or nil
    elseif typed ~= "" and C.keep and C.keep.tab == C.tab then
        C.keep = nil
    end
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
    o.zone = "lines"       -- controller: "box" (the window box's menu) | "tabs" | "lines" | "acts" | "input"
    o.picked = nil         -- the line whose buttons are open
    o.cur = nil            -- controller: the line under the cursor
    o.actI = 1             -- controller: the button under the cursor
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
    if ZeD.Text and ZeD.Text.ownPlaceholder then ZeD.Text.ownPlaceholder(entry, tr("UI_ZeD_Chat_Type"))
    else entry:setPlaceholderText(tr("UI_ZeD_Chat_Type")) end
    entry.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    entry.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    entry:setMaxTextLength(500)
    local win = self
    entry.onCommandEntered = function() win:submit() end
    -- (Escape leaves the line, as the game's chat does)
    -- (the time is kept: a pinned window eats that Escape, so it does not also reach the game, onKeyPress)
    entry.onOtherKey = function(_, key) if key == Keyboard.KEY_ESCAPE then win._escAt = getTimestampMs(); entry:unfocus() end end
    self:addChild(entry)
    self.input = entry
end

function ZeD_ChatWindow:submit()
    local text = self.input:getText() or ""
    local ok, why = C.send(text)
    if ok then
        -- the line empties once it went, as the game's does; a whisper's "/w name " comes back when it is opened again
        self.input:setText("")
        self.scroll = 0
    elseif why == "slow" then
        self._slowNote = true
    elseif why == "muted" then
        C.serverLine(tr("UI_ZeD_Adm_YouMuted"))
    end
    self._usedAt = getTimestampMs()
    self.input:unfocus()
end

-- into the line to type: an empty line starts with the last whisper's "/w name " in its tab, as the game's chat does
function ZeD_ChatWindow:prefill()
    local k = C.keep
    if k and k.tab == C.tab and (self.input:getText() or "") == "" then self.input:setText(k.text) end
end
function ZeD_ChatWindow:focusInput()
    self:prefill()
    self.input:focus()
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
-- dimmed: the surfaces at DIM_A while idle (at once, no fade: ZeD has no animation), else as any window;
-- only where See-through works (Dark): Light and High Contrast always draw the window solid (the director, Nov 12 2026)
function ZeD_ChatWindow:_surfaceAlpha(T)
    if self._ghost then return GHOST_A end   -- (pinned, the pointer off it: in every theme)
    if self._dim and ZeD.seeThroughWorks() then return DIM_A end
    return ZeD_Window._surfaceAlpha(self, T)
end

-- ---------------------------------------------------------------------------
-- PINNED AND GHOSTED (the director, Nov 23 2026: "when you pin it and move the mouse off it, the window goes
-- transparent except for the text ... sort of ghosts out of the way"). It still takes clicks where it is: it is a
-- window, and the pointer on it brings it back to full at once (no animation: ZeD has none).
-- ---------------------------------------------------------------------------
-- ghosted this frame: pinned, and nothing on it (the pointer, the line being typed in, the pad, a drag or a resize)
function ZeD_ChatWindow:_ghostNow()
    if not self.pinned then return false end
    if self.moving or self._resizing then return false end
    if self.joyfocus then return false end
    if self.input and self.input:isFocused() then return false end
    return not self:isMouseOver()
end

-- the lines that frame the window and its parts go nearly clear with the surfaces (ZeD_Window swaps the surfaces)
local GHOST_KEYS = { "border", "borderS" }
function ZeD_ChatWindow:_swapSurfaces()
    ZeD_Window._swapSurfaces(self)
    if not self._ghost then return end
    local T = ZeD.T
    local saved = self._ghostSaved
    if not saved then saved = {}; self._ghostSaved = saved end
    local mine = self._ghostMine
    if not mine then mine = {}; self._ghostMine = mine end
    for _, k in ipairs(GHOST_KEYS) do
        local c = T[k]
        if c then
            saved[k] = c
            local m = mine[k]
            if not m then m = {}; mine[k] = m end
            m.r, m.g, m.b, m.a = c.r, c.g, c.b, (c.a or 1) * GHOST_A
            T[k] = m
        end
    end
    self._ghostT = T   -- (put back on the same table in _restoreSurfaces)
end
function ZeD_ChatWindow:_restoreSurfaces()
    local T = self._ghostT
    if T then
        for _, k in ipairs(GHOST_KEYS) do
            if self._ghostSaved[k] then T[k] = self._ghostSaved[k] end
        end
        self._ghostT = nil
    end
    ZeD_Window._restoreSurfaces(self)
end

-- words drawn on a ghosted window: a 1-unit edge in the opposite tone all round (dark under light words, light under
-- dark ones), so they read on grass, on snow and on dark ground in every theme
function C.inkText(p, s, x, y, c, f)
    local u = ZeD.T.px(1)
    local e = (lum(c) > 0.35) and 0 or 1
    local ea = 0.85
    p:drawText(s, x - u, y, e, e, e, ea, f)
    p:drawText(s, x + u, y, e, e, e, ea, f)
    p:drawText(s, x, y - u, e, e, e, ea, f)
    p:drawText(s, x, y + u, e, e, e, ea, f)
    p:drawText(s, x, y, c.r, c.g, c.b, 1, f)
end

-- the pin box: its own words in the help line (the window's are about rolling up, which this window does not do by
-- itself)
function ZeD_ChatWindow:pinRect()
    local box = self:windowBoxRect()
    if not box then return nil end
    local r = self._pinRect
    if not r then r = {}; self._pinRect = r end
    r.x, r.y, r.w, r.h = box.x - ZeD.T.sp.sm - box.w, box.y, box.w, box.h
    return r
end
function ZeD_ChatWindow:_watchBoxes()
    ZeD_Window._watchBoxes(self)
    if self._pinHover then self._updHelp = tr(self.pinned and "UI_ZeD_Chat_HelpUnpin" or "UI_ZeD_Chat_HelpPin") end
end
function ZeD_ChatWindow:onPinChange() C.savePlace(self) end

-- ---------------------------------------------------------------------------
-- ROLLED DOWN: only the title bar shows, where the window's bottom was (the director, Nov 23 2026: "disclose or
-- roll down into the bottom of the screen and a way to bring it back up"). ZeD's window shade, made to drop.
-- ---------------------------------------------------------------------------
-- (every way it rolls goes through here: the roll box, a double press on the title bar, the pad's X, the chat key)
function ZeD_ChatWindow:setWindowShaded(shaded)
    shaded = shaded and true or false
    if (self.windowShaded and true or false) == shaded then return end
    local tbH = self:titleBarHeight()
    -- the bottom edge it keeps: the window's foot, or the rolled bar's
    local bottom = self:getY() + (self.windowShaded and tbH or self:getHeight())
    if shaded then
        if self.input then self.input:unfocus() end
        self.picked = nil
        if self.joyfocus then setJoypadFocus(self.playerNum, nil); self.joyfocus = nil end   -- (nothing to steer: the pad goes back to the game)
    end
    ZeD_Window.setWindowShaded(self, shaded)
    local h = shaded and tbH or self:getHeight()
    local sh = getCore():getScreenHeight()
    self:setY(math.max(0, math.min(bottom - h, sh - h)))
    if not shaded then
        -- (up again: the lines are in view, the count on the chat key goes)
        C.unreadN = 0
        self._usedAt = getTimestampMs()
    end
    C.savePlace(self)
end

-- the roll box after the title: the curtain's box (WindowCurtain.lua), a down triangle (roll down), up while rolled
function ZeD_ChatWindow:_drawRollBox(tbH)
    local T = ZeD.T
    local tbp = T.sp.titleBoxPad
    local s = T.closeBoxSz
    local titleX = T.sp.sm + T.closeBoxSz + T.sp.md
    local r = self._rollRect
    if not r then r = {}; self._rollRect = r end
    r.x, r.y, r.w, r.h = titleX + (self._titleShownW or 0) + tbp + T.px(2), math.floor((tbH - s) / 2), s, s
    local over = self:isMouseOver() and ZeD.Atoms.mouseIn(self, r.x, r.y, r.w, r.h)
    local bg = over and T.hover or T.surf2
    self:drawRect(r.x, r.y, r.w, r.h, 1, bg.r, bg.g, bg.b)
    ZeD.Atoms.frame(self, r.x, r.y, r.w, r.h, T.borderS)
    local tri = math.max(T.px(5), math.min(T.px(7), s - T.px(6)))
    local tx, ty = r.x + math.floor((r.w - tri) / 2), r.y + math.floor((r.h - tri) / 2)
    if self.windowShaded then ZeD.Atoms.drawTriangleUp(self, tx, ty, tri, T.textDim)
    else ZeD.Atoms.drawTriangleDown(self, tx, ty, tri, T.textDim) end
    if over and ZeD.Help and ZeD.Help.set then
        ZeD.Help.set(self, tr(self.windowShaded and "UI_ZeD_Chat_HelpRollUp" or "UI_ZeD_Chat_HelpRollDown"))
    end
end

-- the title bar: ZeD's, with the roll box after the title; ghosted, its surface nearly clear and the title alone
function ZeD_ChatWindow:_drawTitleBar(w, tbH)
    local T = ZeD.T
    if self._ghost then
        ZeD.Surface.fill(self, 0, 0, w, tbH, "surf2")   -- (at the ghost's alpha: _swapSurfaces)
        local f3 = T.fontF3
        local th = T.textHead
        local y = math.floor((tbH - (T.fontF3H or ZeD.TM:getFontHeight(f3))) / 2)
        C.inkText(self, tostring(self.title or ""), T.sp.sm + T.closeBoxSz + T.sp.md, y, th, f3)
        if not self.windowShaded then
            local bs = T.borderS
            self:drawRect(0, tbH - T.hair, w, T.hair, bs.a or 1, bs.r, bs.g, bs.b)
        end
        return
    end
    -- (room kept after the title for the roll box: ZeD_Window cuts the title and stops the stats before it)
    self._titleReserve = T.closeBoxSz + T.sp.titleBoxPad + T.px(2)
    ZeD_Window._drawTitleBar(self, w, tbH)
    self:_drawRollBox(tbH)
end

-- the lines of the open tab, wrapped to the width (built again when the lines, the tab or the width change)
function ZeD_ChatWindow:_wrapped(w)
    local T = ZeD.T
    local key = tostring(#C.lines) .. ":" .. tostring(C.lines[#C.lines]) .. ":" .. C.tab .. ":" .. w .. ":" .. tostring(T) .. ":" .. tostring(self.picked) .. ":" .. C.muteSeq
    if self._wrapKey == key and self._wrap then return self._wrap end
    local tab = tabOf(C.tab)
    local out = {}
    local f = T.fontF2
    local lh = ZeD.TM:getFontHeight(f) + px(U.LINE_GAP)
    local found = false
    self._actAt = nil
    for _, ln in ipairs(C.lines) do
        if tab.kinds[ln.kind] then
            local head = ln.author and (ln.author .. ": ") or ""
            if ln.kind == "whisper" and ln.author then head = tr("UI_ZeD_Chat_From", ln.author) .. " " end
            if ln.kind == "shout" then head = ln.author and tr("UI_ZeD_Chat_Shouts", ln.author) .. " " or "" end
            local quiet = C.mutedByMe(ln.author)
            local parts = ZeD.Atoms.wrapText(head .. (quiet and tr("UI_ZeD_Chat_MutedByYou") or ln.text), f, w)
            -- (the head's width with its space: MeasureStringX does not count a trailing space)
            local hw = 0
            if head ~= "" then
                local sp = ZeD.TM:MeasureStringX(f, "a a") - ZeD.TM:MeasureStringX(f, "aa")
                hw = ZeD.TM:MeasureStringX(f, (head:gsub("%s+$", ""))) + math.max(sp, px(3))
            end
            for i, s in ipairs(parts) do out[#out + 1] = { s = s, ln = ln, first = i == 1, headW = (i == 1) and hw or 0, head = head, quiet = quiet } end
            -- the picked line's buttons take as many rows of the list as they need
            if ln == self.picked then
                found = true
                self._acts = C.actions(ln)
                local h = C.flowActions(self._acts, w)
                local rows = math.ceil(h / lh)
                self._actRows = rows
                self._actAt = #out + 1
                for i = 1, rows do out[#out + 1] = { s = "", ln = ln, first = false, headW = 0, head = "", acts = i == 1 } end
            end
        end
    end
    -- (the line went off the top, or into another tab)
    if self.picked and not found then
        self.picked, self._acts = nil, nil
        if self.zone == "acts" then self.zone = "lines" end
        key = key .. ":gone"
    end
    self._wrap, self._wrapKey = out, key
    return out
end

function ZeD_ChatWindow:prerender()
    local T = ZeD.T
    if not T then return end
    if not C.active() then self:close(true); return end   -- (the server gone: the pin kept)
    self.title = tr("UI_ZeD_Chat_Title")
    self._dim = ZeD.seeThroughWorks() and self:_idle()   -- (the words' wash too: solid themes never dim)
    self._ghost = self:_ghostNow()
    if self._ghost then self._dim = false end   -- (ghosted: no wash, the words stay whole)
    ZeD_Window.prerender(self)
    -- (after the frame's own, which sets every window's shared minimum: this one may be narrower)
    self.minimumWidth = px(U.MIN_W)
    self.minimumHeight = self.windowShaded and self:titleBarHeight() or px(U.MIN_H)
    if self.windowShaded then return end   -- (rolled down: the title bar alone)
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
    -- (the narrower window, Nov 23 2026: when every tab a player has does not fit the row at the tabs' own padding, the
    -- padding gives way, down to 3 units, so an admin's five tabs in a long language still fit)
    local f2 = T.fontF2
    local words, textW = {}, 0
    for i, t in ipairs(tabs) do
        words[i] = ZeD.Atoms.textCase(tr(t.key))
        textW = textW + ZeD.TM:MeasureStringX(f2, words[i])
    end
    local padX = T.sp.tabPadX
    local gaps = px(2) * math.max(0, #tabs - 1)
    if #tabs > 0 and textW + 2 * padX * #tabs + gaps > w - 2 * pad then
        padX = math.max(px(3), math.floor((w - 2 * pad - textW - gaps) / (2 * #tabs)))
    end
    for i, t in ipairs(tabs) do
        local label = words[i]
        local lw = ZeD.TM:MeasureStringX(f2, label) + 2 * padX
        local hov = (not cues) and my >= ty and my < ty + T.tabH and mx >= tx and mx < tx + lw
        local foc = (self.joyfocus and self.zone == "tabs" and C.tab == t.id) and { win = self } or nil
        local tw = M.drawTab(self, tx, ty, label, C.tab == t.id, hov, false, { focus = foc, padX = padX })
        if self._ghost then
            -- (ghosted: the tab's words again over its own, whole and edged)
            local fy = ty + math.floor((T.tabH - ZeD.TM:getFontHeight(f2)) / 2)
            C.inkText(self, label, tx + padX, fy, (C.tab == t.id) and T.textHead or T.text, f2)
        end
        self._tabHits[#self._tabHits + 1] = { x = tx, y = ty, w = tw, h = T.tabH, id = t.id }
        tx = tx + tw + px(2)
    end
    -- the window box (its menu: Name color, Theme, Accent...) has the controller: Up from the tabs
    if self.joyfocus and self.zone == "box" and ZeD.Focus and ZeD.Focus.mark then
        local b = self:windowBoxRect()
        if b then ZeD.Focus.mark(self, b.x, b.y, b.w, b.h, { win = self }) end
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
    -- (ghosted: the button's ring nearly clear with the surfaces, its word whole)
    local sendCols = nil
    if self._ghost then
        local a = T.accent
        sendCols = { border = { r = a.r, g = a.g, b = a.b, a = (a.a or 1) * GHOST_A } }
    end
    M.drawButton(self, sx, iy, sw, ih, sendLabel, "primary", shov and isMouseButtonDown(0), sendCols,
        { hover = shov, disabled = slow > 0 or mutedMe, win = self, help = sendHelp })
    if self._ghost then
        -- (its word again over its own, edged, where drawButton centers it)
        local f3 = T.fontF3
        local sl = ZeD.btnCase and ZeD.btnCase(sendLabel) or sendLabel
        local stw, sth = ZeD.TM:MeasureStringX(f3, sl), ZeD.TM:getFontHeight(f3)
        C.inkText(self, sl, sx + math.floor((sw - stw) / 2), iy + math.floor((ih - sth) / 2), T.text, f3)
    end
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
    self._rowHits, self._actHits = {}, {}
    if #rows == 0 then
        ZeD.Molecules.drawEmptyLine(self, x, y, w, tr("UI_ZeD_Chat_Nothing"))
        return
    end
    -- the line the controller moved to is brought into view
    if self.seek then
        local first, last = nil, nil
        for i, r in ipairs(rows) do
            if r.ln == self.seek then
                first = first or i
                last = i
            end
        end
        self.seek = nil
        if first then
            local foot = (#rows - last) * lh
            local head = (#rows - first) * lh + lh
            if foot < self.scroll then self.scroll = foot
            elseif head > self.scroll + h then self.scroll = head - h end
            self.scroll = math.max(0, math.min(maxS, self.scroll))
        end
    end
    self:setStencilRect(x, y, w, h)
    -- the bottom row sits at the foot; scroll moves the list down
    local by = y + h - lh + self.scroll
    local tc, hd, ac = T.text, T.textHead, T.accent
    local mx, my = self:getMouseX(), self:getMouseY()
    local Fo = ZeD.Input and ZeD.Input.Focus
    if Fo and Fo.cuesVisible and Fo.cuesVisible() then mx, my = nil, nil end
    local me = safe(function() return getPlayer():getUsername() end, nil)
    -- (from the row's place, not from reaching it: the loop stops at the top edge, and the buttons' first row can be over it
    -- with the rest in view)
    local actY = self._actAt and (by - (#rows - self._actAt) * lh) or nil
    for i = #rows, 1, -1 do
        local ry = by - (#rows - i) * lh
        if ry + lh < y then break end
        if ry <= y + h then
            local r = rows[i]
            local c = r.ln.color or ((r.ln.kind == "server" or r.ln.kind == "admin") and ac) or tc
            if r.quiet then c = T.textDim end
            local can = C.canPick(r.ln, me)
            local onF = false
            if r.ln == self.picked then
                self:drawRect(x, ry, w, lh, 0.25, ac.r, ac.g, ac.b)
            elseif can and mx ~= nil and mx >= x and mx < x + w and my >= ry and my < ry + lh and my >= y and my < y + h then
                local hv = T.hover
                self:drawRect(x, ry, w, lh, hv.a or 1, hv.r, hv.g, hv.b)
            end
            if can and self.joyfocus and self.zone == "lines" and self.cur == r.ln and ZeD.Focus and ZeD.Focus.mark then
                onF = ZeD.Focus.mark(self, x, ry, w, lh, { win = self, focused = true, pad = true }) and true or false
            end
            if onF then c = T.textOnFocus end
            if can and not r.acts and r.s ~= "" then self._rowHits[#self._rowHits + 1] = { y = ry, h = lh, ln = r.ln } end
            if self._ghost then
                -- (ghosted: the words whole, with an edge so they read over the world)
                if r.first and r.headW > 0 then
                    C.inkText(self, (r.head:gsub("%s+$", "")), x, ry, C.nameInk(r.ln.author) or hd, f)
                    C.inkText(self, r.s:sub(#r.head + 1), x + r.headW, ry, c, f)
                else
                    C.inkText(self, r.s, x, ry, c, f)
                end
            elseif r.first and r.headW > 0 then
                local nc = onF and T.textOnFocus or C.nameInk(r.ln.author) or hd
                self:drawText((r.head:gsub("%s+$", "")), x, ry, nc.r, nc.g, nc.b, nc.a or 1, f)
                self:drawText(r.s:sub(#r.head + 1), x + r.headW, ry, c.r, c.g, c.b, c.a or 1, f)
            else
                self:drawText(r.s, x, ry, c.r, c.g, c.b, c.a or 1, f)
            end
        end
    end
    if actY and self._acts and actY <= y + h and actY + (self._actRows or 1) * lh >= y then
        self:_drawActions(x, actY, y, h, mx, my)
    end
    self:clearStencilRect()
    -- (scrolled up: a mark at the foot that newer lines are below)
    if self.scroll > 0 then
        ZeD.Atoms.drawStatusDot(self, x + w - px(8), y + h - px(8), ac, px(6))
    end
end

-- the picked line's buttons, in the rows kept for them
function ZeD_ChatWindow:_drawActions(x, ay, viewY, viewH, mx, my)
    local M = ZeD.Molecules
    for i, b in ipairs(self._acts) do
        if b.live then b.live(b) end
        local bx, by = x + b.dx, ay + b.dy
        local hov = mx ~= nil and mx >= bx and mx < bx + b.w and my >= by and my < by + b.h and my >= viewY and my < viewY + viewH
        local foc = (self.joyfocus and self.zone == "acts" and self.actI == i) and { win = self, focused = true, pad = true } or nil
        M.drawButton(self, bx, by, b.w, b.h, b.text, "default", hov and isMouseButtonDown(0), nil,
            { hover = hov, disabled = b.disabled, help = b.why or b.help, win = self, focus = foc })
        -- (half under the fold: not a press)
        if by >= viewY and by + b.h <= viewY + viewH then
            self._actHits[#self._actHits + 1] = { x = bx, y = by, w = b.w, h = b.h, b = b }
        end
    end
end

function ZeD_ChatWindow:render() ZeD_Window.render(self) end

-- the help line's words for what the pointer is over (the window's footer)
function ZeD_ChatWindow:getStatusLine()
    if self._ghost then return nil end   -- (ghosted: the help line says nothing)
    local note = C.noteNow()
    if note then return note end
    if C.slowLeft() > 0 then return tr("UI_ZeD_Chat_Slow", C.slowLeft()) end
    if self.picked then return tr("UI_ZeD_Chat_HelpMute") end
    if self.scroll > 0 then return tr("UI_ZeD_Chat_Older") end
    if #(self._rowHits or {}) > 0 then return tr("UI_ZeD_Chat_HelpPick") end
    return tr("UI_ZeD_Chat_Help")
end

local function inRect(r, x, y) return r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end

function ZeD_ChatWindow:closeAction()
    pcall(function() ZeD.uiSound("UIActivateButton") end)
    self:close()
end
-- ghosted, the title bar's boxes aren't drawn, so they take no press either (QA, Nov 23 2026): a press in the frame the
-- pointer arrives would land on a box the player can't see. The ghost lifts at once with the pointer on the window.
function ZeD_ChatWindow:_watchBoxes()
    if self._ghost then
        self._boxPrevDown = isMouseButtonDown(0)
        self._closeWasDown, self._wboxWasDown, self._closeHover, self._wboxHover = false, false, false, false
        return
    end
    return ZeD_Window._watchBoxes(self)
end

-- keepPin: closed by the game, not the player (the server gone, safe mode): the pin is kept so a pinned window
-- reopens on the next join (QA, Nov 23 2026: a close at quit or disconnect wrote pinned 0)
function ZeD_ChatWindow:close(keepPin)
    if not keepPin then self.pinned = false end   -- (closing unpins it: the close box, B, Escape on an unpinned window)
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
    self.picked, self.cur = nil, nil
    pcall(function() ZeD.uiSound("UISelectListItem") end)
end

function ZeD_ChatWindow:onMouseDown(x, y)
    if not self:getIsVisible() then return true end
    self._usedAt = getTimestampMs()
    -- (ghosted: this press only brings it back; the roll box it can't see takes nothing: QA, Nov 23 2026)
    if self._ghost then self._ghost = false; return true end
    local cb = self:closeRect()
    if cb and inRect(cb, x, y) then return true end
    if inRect(self:windowBoxRect(), x, y) then return true end
    if inRect(self:pinRect(), x, y) then return true end   -- (the pin answers on release: ZeD_Window._watchBoxes)
    if inRect(self._rollRect, x, y) then
        pcall(function() ZeD.uiSound("UIActivateTab") end)
        self:setWindowShaded(not self.windowShaded)
        return true
    end
    if self.windowShaded then
        -- rolled down: a press on the bar brings it back up on release, unless it was a drag (onMouseUp); no double
        -- press, which would roll it again
        if y < self:titleBarHeight() then
            self._rollPress = { x = getMouseX(), y = getMouseY() }
            self._lastTitleClick = nil
        end
        return ZeD_Window.onMouseDown(self, x, y)
    end
    for _, t in ipairs(self._tabHits or {}) do
        if inRect(t, x, y) then self:pickTab(t.id); return true end
    end
    if inRect(self._sendRect, x, y) then
        if C.slowLeft() == 0 then self:submit() end
        return true
    end
    if inRect(self._inputRect, x, y) then self:focusInput(); return true end
    if self:_pressLines(x, y) then return true end
    -- anywhere else: the title bar drags (ZeD_Window), the rest does nothing
    return ZeD_Window.onMouseDown(self, x, y)
end

-- a press in the list: a button under the picked line, or a line to pick, or a second press to let it go
function ZeD_ChatWindow:_pressLines(x, y)
    for _, h in ipairs(self._actHits or {}) do
        if inRect(h, x, y) then
            if not h.b.disabled then self:_runAction(h.b) end
            return true
        end
    end
    local r = self._linesRect
    if not inRect(r, x, y) then return false end
    for _, h in ipairs(self._rowHits or {}) do
        if y >= h.y and y < h.y + h.h then
            self.picked = (self.picked ~= h.ln) and h.ln or nil
            pcall(function() ZeD.uiSound("UISelectListItem") end)
            return true
        end
    end
    return false
end

function ZeD_ChatWindow:_runAction(b)
    pcall(function() ZeD.uiSound("UIActivateButton") end)
    local ok, err = pcall(b.run, self)
    if not ok then ZeD.logOnce("chat action " .. tostring(b.id), err) end
end

-- the press on a rolled bar that did not move it (within 4 units): up again
function ZeD_ChatWindow:onMouseUp(x, y)
    local p = self._rollPress
    self._rollPress = nil
    local r = ZeD_Window.onMouseUp(self, x, y)
    if p and self.windowShaded and math.abs(getMouseX() - p.x) + math.abs(getMouseY() - p.y) <= px(4) then
        pcall(function() ZeD.uiSound("UIActivateTab") end)
        self:setWindowShaded(false)
        self._lastTitleClick = nil
    end
    return r
end
function ZeD_ChatWindow:onMouseUpOutside(x, y)
    self._rollPress = nil
    return ZeD_Window.onMouseUpOutside(self, x, y)
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
    -- left with only the whisper's "/w name " in it: the line empties, as the game's does when you leave it
    local k = C.keep
    if k and self.input and not self.input:isFocused() and self.input:getText() == k.text then self.input:setText("") end
    -- the place is kept a moment after a drag or a resize ends
    local now = getTimestampMs()
    if not (self._saveAt and now - self._saveAt < 2000) then self._saveAt = now; C.savePlace(self) end
end

-- pinned, Escape only leaves the line being typed in (the window stays); with nothing to leave, it is the game's
function ZeD_ChatWindow:_escLeavesLine()
    if self.input and self.input:isFocused() then return true end
    return self._escAt ~= nil and getTimestampMs() - self._escAt < 250   -- (the line's own Escape just left it)
end
function ZeD_ChatWindow:isKeyConsumed(key)
    if key ~= Keyboard.KEY_ESCAPE then return false end
    if self.pinned then return self:_escLeavesLine() end
    return true
end
function ZeD_ChatWindow:onKeyPress(key)
    if key ~= Keyboard.KEY_ESCAPE then return end
    if self.pinned then
        if self:_escLeavesLine() then
            if self.input then self.input:unfocus() end
            GameKeyboard.eatKeyPress(key)
        end
        return
    end
    self:close(); GameKeyboard.eatKeyPress(key)
end

-- the controller: the tabs (left / right), the lines (up / down: step, then scroll), the line to type in (A: the pad keyboard)
function ZeD_ChatWindow:onGainJoypadFocus(jd) self.joyfocus = jd end
function ZeD_ChatWindow:onLoseJoypadFocus(jd) self.joyfocus = nil end
function ZeD_ChatWindow:onJoypadDown(button, jd)
    if ZeD.padStart and ZeD.padStart(button, jd, self.playerNum) then return end   -- (Start pauses: punch list 263)
    if button == Joypad.BButton then
        if self.zone == "acts" then
            self.zone, self.picked = "lines", nil
            return
        end
        self:close()
        return
    end
    -- X rolls it down to its title bar and gives the pad back to the game (setWindowShaded); the belt's chat key or the
    -- wheel's Chat brings it up again (the director, Nov 23 2026)
    if button == Joypad.XButton then
        pcall(function() ZeD.uiSound("UIActivateTab") end)
        self:setWindowShaded(true)
        return
    end
    if button == Joypad.AButton and self.zone == "lines" and self.cur then
        self.picked, self.zone, self.actI = self.cur, "acts", 1
        self.seek = self.cur
        return
    end
    if button == Joypad.AButton and self.zone == "acts" then
        local b = self._acts and self._acts[self.actI]
        if not b then return end
        if b.live then b.live(b) end
        if b.disabled then C.note(b.why) else self:_runAction(b) end
        return
    end
    if button == Joypad.AButton and self.zone == "box" then
        -- the window box's menu, as a click on it; B or a choice gives the pad back here (the menu's origin)
        self:openWindowMenu()
        local WM = ZeD.WindowMenu
        if WM and WM.current and WM.current.win == self then WM.current.origin = self end
        return
    end
    if button == Joypad.AButton and self.zone == "input" then
        self:prefill()
        if OnScreenKeyboard and OnScreenKeyboard.Show then
            local ok = pcall(OnScreenKeyboard.Show, self.playerNum, self.input, jd)
            if not ok then self.input:focus() end
        else
            self.input:focus()
        end
    end
end
-- the lines the cursor can land on in view, oldest first (the rows the last frame drew, foot first, a wrapped line once)
function ZeD_ChatWindow:_inView()
    local out, seen = {}, {}
    local hits = self._rowHits or {}
    for i = #hits, 1, -1 do
        local ln = hits[i].ln
        if not seen[ln] then
            seen[ln] = true
            out[#out + 1] = ln
        end
    end
    return out
end

-- Up and Down among those lines: only what is in view, so no line in between is ever jumped past. Coming from outside, the
-- nearest end: the newest from the line to type in, the oldest from the tabs. False when none is left that way: the list
-- scrolls, and at its end the cursor goes on to the tabs or the line to type in (_padStep)
function ZeD_ChatWindow:_padLines(dir)
    local list = self:_inView()
    local at = nil
    for i, ln in ipairs(list) do
        if ln == self.cur then at = i end
    end
    local to = nil
    if at then to = list[at + ((dir == "up") and -1 or 1)]
    else to = list[(dir == "up") and #list or 1] end
    if not to then
        if not at then self.cur = nil end
        return false
    end
    self.cur, self.seek = to, to
    return true
end

function ZeD_ChatWindow:_padStep(dir)
    local tabs = C.tabsShown()
    if self.zone == "acts" then
        if dir == "left" or dir == "right" then
            local n = #(self._acts or {})
            local j = self.actI + ((dir == "right") and 1 or -1)
            if j >= 1 and j <= n then self.actI = j end
        else
            self.zone, self.picked = "lines", nil
            self:_padLines(dir)
        end
        pcall(function() ZeD.uiSound("UISelectListItem") end)
        return
    end
    if self.zone == "lines" and (dir == "up" or dir == "down") and self:_padLines(dir) then
        pcall(function() ZeD.uiSound("UISelectListItem") end)
        return
    end
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
    if self.zone == "box" then
        if dir == "down" then self.zone = "tabs" end
        pcall(function() ZeD.uiSound("UISelectListItem") end)
        return
    end
    if dir == "up" then
        if self.zone == "tabs" and self:windowBoxRect() then self.zone = "box"
        elseif self.zone == "input" then
            self.zone = "lines"
            self:_padLines("up")
        elseif self.zone == "lines" and self.scroll < (self._maxScroll or 0) then self.scroll = math.min(self._maxScroll or 0, self.scroll + lh * 3)
        elseif self.zone == "lines" then self.zone, self.cur = "tabs", nil end
    elseif dir == "down" then
        if self.zone == "tabs" then
            self.zone = "lines"
            self:_padLines("down")
        elseif self.zone == "lines" and self.scroll > 0 then self.scroll = math.max(0, self.scroll - lh * 3)
        elseif self.zone == "lines" then self.zone, self.cur = "input", nil end
    end
    pcall(function() ZeD.uiSound("UISelectListItem") end)
end
function ZeD_ChatWindow:onJoypadDirUp() self:_padStep("up") end
function ZeD_ChatWindow:onJoypadDirDown() self:_padStep("down") end
function ZeD_ChatWindow:onJoypadDirLeft() self:_padStep("left") end
function ZeD_ChatWindow:onJoypadDirRight() self:_padStep("right") end
function ZeD_ChatWindow:getFooterPrompts()
    if not self.joyfocus then return nil end
    local Pr = ZeD.Prompt
    local move = tr((self.zone == "tabs" and "UI_ZeD_Chat_PadTabs") or (self.zone == "acts" and "UI_ZeD_Chat_PadActs") or "UI_ZeD_Chat_PadMove")
    local P = { (Pr and Pr.padNote) and Pr.padNote(move) or move }
    -- (the help line holds the prompts: a press's answer and why a button is gray go first here)
    local note = C.noteNow()
    if not note and self.zone == "acts" then
        local b = self._acts and self._acts[self.actI]
        note = b and b.why or nil
    end
    if note then P[1] = note end
    if self.zone == "input" then P[#P + 1] = { glyph = "A", label = tr("UI_ZeD_Chat_PadType") } end
    if self.zone == "box" then P[#P + 1] = { glyph = "A", label = tr("UI_ZeD_Prompt_Menu") } end
    if (self.zone == "lines" and self.cur) or self.zone == "acts" then P[#P + 1] = { glyph = "A", label = tr("UI_ZeD_Chat_PadPick") } end
    P[#P + 1] = { glyph = "X", label = tr("UI_ZeD_Chat_PadRollDown") }
    P[#P + 1] = { glyph = "B", label = self.zone == "acts" and tr("UI_ZeD_Tk_PromptBack") or getText("UI_Close") }
    return P
end

-- ---------------------------------------------------------------------------
-- ITS PLACE, kept on this computer (Lua/ZeD_chatwin.txt: "v2 x y w h tab rolled pinned", x y w h in design units of
-- the whole window, rolled or not; rolled and pinned 1 or 0). A line without the "v2" is from before the window's new
-- first place by the chat key (Nov 23 2026) and is read as no place, once: everyone sees the new place.
-- ---------------------------------------------------------------------------
function C.savePlace(win)
    if not win then return end
    local T = ZeD.T
    local sc = (T and T.scale) or 1
    local h = (win.windowShaded and win.preShadeHeight) or win:getHeight()
    local y = win:getY()
    -- (rolled down, the bar sits where the window's foot was: its top is the bar's foot less the whole height)
    if win.windowShaded then y = y + win:titleBarHeight() - h end
    local s = string.format("v2 %d %d %d %d %s %d %d", math.floor(win:getX() / sc), math.floor(y / sc),
        math.floor(win:getWidth() / sc), math.floor(h / sc), C.tab, win.windowShaded and 1 or 0, win.pinned and 1 or 0)
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
    local x, y, w, h, tab, rolled, pinned = l:match("^v2 (%-?%d+) (%-?%d+) (%d+) (%d+) ?(%a*) ?(%d?) ?(%d?)")
    if not x then return nil end   -- (an old line, or none)
    return tonumber(x), tonumber(y), tonumber(w), tonumber(h), tab, rolled == "1", pinned == "1"
end
C._readPlace = readPlace   -- (for the sims)

-- the first place: its foot on the screen's foot, its left edge an icon's gap (the belt row's group space, B.ICON_GAP)
-- right of the belt's chat key, and past the PvP marker when the server shows one right after the key, so the window
-- does not cover it; on the screen. No belt or no chat key: the old place, low on the left (the director, Nov 23 2026)
function C.defaultPlace(w, h, sw, sh)
    local Bt = ZeD.Belt
    local hud = Bt and Bt.getHUD and Bt.getHUD(0)
    local key = nil
    if hud and hud._boxes and hud:getIsVisible() then
        for _, b in ipairs(hud._boxes) do
            if b.kind == "chat" then key = b
            elseif key and b.kind == "pvp" then key = b end
        end
    end
    if not key then return px(15), sh - h - px(140) end
    local x = hud:getAbsoluteX() + key.x + key.w + px(Bt.ICON_GAP or 38)
    x = math.max(0, math.min(x, sw - w))
    local y = math.max(0, sh - h)
    -- a narrow screen pushed it back over the belt row (it would cover the row's right end): it stands on the row
    -- instead, its foot a gap above the row's top (QA, Nov 23 2026)
    local hx, hy = hud:getAbsoluteX(), hud:getAbsoluteY()
    local rowR = hx + key.x + key.w
    if x < rowR and y + h > hy then y = math.max(0, hy - h - px(Bt.ICON_GAP or 38) / 2) end
    return x, y
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
        -- (pcall, not safe(): safe() hands back only the first value, and readPlace returns seven)
        local ok, x, y, w, h, tab, rolled, pinned = pcall(readPlace)
        if not ok then x = nil end
        if x and y and w and h then x, y, w, h = x * sc, y * sc, w * sc, h * sc
        else
            w, h = px(U.W), px(U.H)
            x, y = C.defaultPlace(w, h, sw, sh)
            rolled, pinned = false, false
        end
        -- (on the screen, whatever screen it was kept on)
        w = math.min(w, sw); h = math.min(h, sh)
        x = math.max(0, math.min(x, sw - w)); y = math.max(0, math.min(y, sh - h))
        if tab and tab ~= "" then C.tab = tab end
        win = ZeD_ChatWindow:new(x, y, w, h)
        win:initialise()
        win:instantiate()
        win:addToUIManager()
        win:setAlwaysOnTop(true)
        win.pinned = pinned and true or false
        C.win = win
        -- (kept rolled down: only a pinned window coming back by itself stays down, C.tick; any key brings it up below)
        if rolled and C._openRolled then win:setWindowShaded(true) end
    end
    win:setVisible(true)
    -- the chat key, the belt's key, the wheel's Chat: a rolled window comes back up
    if win.windowShaded and not C._openRolled then win:setWindowShaded(false) end
    win._usedAt = getTimestampMs()
    if not win.windowShaded then C.unreadN = 0 end
    if pad then
        -- pad: true (player 1's) or the player's number, so players 2-4 open it on their own pads; the window is one,
        -- and the player who opened it last holds it
        local pn = (type(pad) == "number") and pad or 0
        local jd = JoypadState.players[pn + 1]
        if jd then
            if win.playerNum ~= pn and win.joyfocus then setJoypadFocus(win.playerNum, nil) end
            win.playerNum = pn
            win.zone = "lines"; jd.focus = win; updateJoypadFocus(jd)
        end
    elseif typing and win.input then
        win.playerNum = 0   -- (the keyboard is player 1's)
        win.zone = "input"
        win:focusInput()
    end
    return win
end
-- the belt's chat key: rolled down, it comes up; pinned, it rolls down and stays (a pinned window closes only by its
-- close box or B); else it opens or closes
function C.toggle(pad)
    local w = C.win
    if w and w:getIsVisible() then
        if w.windowShaded then C.open(false, pad)
        elseif w.pinned then w:setWindowShaded(true)
        else w:close() end
    else
        C.open(false, pad)
    end
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
    -- a window left pinned when the player last left comes back by itself, once, where it was and rolled as it was
    if not C._pinChecked and ZeD.T and getPlayer() then
        C._pinChecked = true
        local ok, x, _, _, _, _, rolled, pinned = pcall(readPlace)
        if ok and x and pinned and not C.win then
            C._openRolled = rolled
            pcall(C.open, false)
            C._openRolled = nil
        end
    end
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
            if C.win then C.win:close(true) end   -- (safe mode: the pin kept)
            local gc = ISChat and ISChat.instance
            if gc then gc:setVisible(true) end
        end,
    })
end

return C
