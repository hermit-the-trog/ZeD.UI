-- ZeDUI/tools/qa/mp_leftovers_sim.lua  (Nov 7 2026, Build): the multiplayer windows the game still opened with ZeD on
-- (docs/reference/VANILLA_WINDOWS_20261107.md, C1 to C5, C15 to C17), with no game running. The real Tokens, Tr, Atoms, Molecules,
-- ZeD_MainMenu, ZeD_MainMenuPlayers, ZeD_FormCard, ZeD_MpLeftovers, ZeD_LeftScreen, ZeD_Messages, ServerTab, AdminTab, the
-- ticket, claim and community files, and the game's own ISItemEditPanel.lua from its install, on Lua 5.1 stubs (the harness
-- is community_cards_sim.lua's). It walks: the pause window's Players page (the scoreboard's reply, a pick, the game's
-- actions by role, Kick asking first, a long list under the D-pad) and Invite page (the game's InviteFriends doing the work);
-- the Server tab's options card (the game's words for on, off and an enum; Change only for staff; the Admin tab's row);
-- the saving note; admin messages as notes with Teleport; a map mark's sharing card with mouse and pad; the admin's
-- Edit item card (the game's own fields and save); the kicked or disconnected desk screen at the Deck, 1080p and 4K (the slot
-- where the engine writes its line). Every one of these fails on the code before Nov 7: the game's own windows opened.
-- What it cannot prove is what the engine does: real fonts, focus landing, the keyboard, the engine's own line.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/mp_leftovers_sim.lua
-- It prints FAIL lines and a last line "mp_leftovers_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]mp_leftovers_sim%.lua$", "")

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

-- the clock, the game's globals -----------------------------------------------------------
local nowMs = 1000000
function getTimestampMs() return nowMs end
function getTimestamp() return math.floor(nowMs / 1000) end
function triggerEvent() end
function isClient() return true end
function isServer() return false end
function isMouseButtonDown() return false end
ZEDQA_CAPS = { TeleportToCoordinates = true, CanSeePlayersStats = true, AnswerTickets = true }
Capability = setmetatable({}, { __index = function(_, k) return k end })
local ROLE = { hasCapability = function(_, c) return ZEDQA_CAPS[c] == true end, getName = function() return "admin" end, hasAdminTool = function() return true end, hasAdminPower = function() return false end }
local PLAYER = { hours = 300, showTag = true, pvp = false, getUsername = function() return "Aretha" end, getX = function() return 6347.4 end, getY = function() return 5372.2 end, getZ = function() return 0 end,
    getRole = function() return ROLE end, getHoursSurvived = function(self) return self.hours end, getSafety = function() return nil end, getPlayerNum = function() return 0 end,
    isShowTag = function(self) return self.showTag end, setShowTag = function(self, v) self.showTag = v end,
    isFactionPvp = function(self) return self.pvp end, setFactionPvp = function(self, v) self.pvp = v end }
function getPlayer() return PLAYER end
function getSpecificPlayer() return PLAYER end
local ONLINE = true
function getPlayerFromUsername(u) return ONLINE and { getUsername = function() return u end } or nil end
function getGameTime() return { getWorldAgeHours = function() return 270 end } end
function getSoundManager() return { playUISound = function() end } end
function getCore() return { getOptionFontSizeReal = function() return 1 end, getScreenWidth = function() return 1280 end, getScreenHeight = function() return 800 end } end
OPTS = {}
function getServerOptions() return { getOption = function() return "Knox Survivors" end, getBoolean = function(_, k) return OPTS[k] == true end, getInteger = function(_, k) return OPTS[k] or 0 end } end
function getServerName() return "Knox" end
function getServerIP() return "10.0.0.5" end
function getServerPort() return "16261" end
FILES = {}
function getFileWriter(name)
    local lines = {}
    return { write = function(_, s) lines[#lines + 1] = s end, close = function() FILES[name] = table.concat(lines) end }
end
function getFileReader(name)
    local body = FILES[name]
    if not body then return nil end
    local at = 1
    return { readLine = function()
        local e = string.find(body, "\n", at, true)
        if not e then return nil end
        local l = string.sub(body, at, e - 1)
        at = e + 1
        return l
    end, close = function() end }
end
KEYS_ON, LEFT = true, 0
function doKeyPress(on) KEYS_ON = on end
function forceDisconnect() LEFT = LEFT + 1 end
PADS = {}
function setJoypadFocus(n, ui) if JoypadState.players[n + 1] then JoypadState.players[n + 1].focus = ui end end
function updateJoypadFocus() end
OPENED = {}
function scoreboardUpdate() end
-- the game's lists, and its calls: each logged in CALLS and done at once, unless REFUSE says the game said no
GS, GF, WARS, CALLS, OTHER, NOTES, INSIDE = {}, {}, {}, {}, {}, {}, true
SYNCS = {}   -- what the server's FactionSync will write, the next tick
local function jlist(t)
    return { size = function() return #t end, get = function(_, i) return t[i + 1] end,
        contains = function(_, v) for _, x in ipairs(t) do if x == v then return true end end return false end }
end
local safeN = 0
function newSafe(x, y, w, h, owner)
    safeN = safeN + 1
    local s = { x = x, y = y, w = w, h = h, owner = owner, title = owner, players = { owner }, respawn = {}, onlineId = 500 + safeN, id = "s" .. safeN }
    function s.getId(self) return self.id end
    function s.getOwner(self) return self.owner end
    function s.getTitle(self) return self.title end
    function s.getX(self) return self.x end
    function s.getY(self) return self.y end
    function s.getOnlineID(self) return self.onlineId end
    function s.getLocation() return "Riverside" end
    function s.getDatetimeCreatedStr() return "Nov 2, 1993" end
    function s.getPlayers(self) return jlist(self.players) end
    function s.isOwner(self, who) return self.owner == who:getUsername() end
    function s.isRespawnInSafehouse(self, who) return self.respawn[who] == true end
    function s.playerAllowed(self, who)
        for _, n in ipairs(self.players) do if n == who:getUsername() then return true end end
        return false
    end
    function s.alreadyHaveSafehouse(self, who)
        if OTHER[who] then return { getTitle = function() return "Their place" end } end
        return nil
    end
    GS[#GS + 1] = s
    return s
end
function newFaction(name, owner)
    local f = { name = name, owner = owner, players = {} }
    function f.getName(self) return self.name end
    function f.getOwner(self) return self.owner end
    function f.getTag(self) return self.tag end
    function f.setTag(self, s) self.tag = s end
    function f.getTagColor(self) return self.color end
    function f.setTagColor(self, c) self.color = c end
    function f.getPlayers(self) return jlist(self.players) end
    function f.isOwner(self, who) return self.owner == who end
    function f.canCreateTag(self) return #self.players + 1 >= (OPTS.FactionPlayersRequiredForTag or 1) end
    GF[#GF + 1] = f
    return f
end
function newWar(s, attacker, state, time)
    local w = { onlineId = s.onlineId, attacker = attacker, state = state, time = time }
    function w.getOnlineID(self) return self.onlineId end
    function w.getAttacker(self) return self.attacker end
    function w.getDefender() return s.owner end
    function w.getState(self) local st = self.state; return { name = function() return st end } end
    function w.getTime(self) return self.time end
    return w
end
local function inSafe(name)
    for _, s in ipairs(GS) do
        for _, n in ipairs(s.players) do if n == name then return s end end
    end
    return nil
end
local function inFaction(name)
    for _, f in ipairs(GF) do
        if f.owner == name then return f end
        for _, n in ipairs(f.players) do if n == name then return f end end
    end
    return nil
end
SafeHouse = {
    hasSafehouse = function(p) return inSafe(type(p) == "table" and p:getUsername() or p) end,
    getSafehouseList = function() return jlist(GS) end,
    getSafeHouse = function() return nil end,
    canBeSafehouse = function(sq, p)
        if not sq:getBuilding() then error("the game reads the building with no test") end
        return ""
    end,
    hasNotSurvivedEnoughToClaim = function(p) return p:getHoursSurvived() < (OPTS.SafehouseDaySurvivedToClaim or 0) * 24 end,
}
Faction = {
    getPlayerFaction = function(p) return inFaction(type(p) == "table" and p:getUsername() or p) end,
    getFactions = function() return jlist(GF) end,
    getFaction = function(n) for _, f in ipairs(GF) do if f.name == n then return f end end return nil end,
    factionExist = function(n) for _, f in ipairs(GF) do if f.name == n then return true end end return false end,
    tagExist = function(n) for _, f in ipairs(GF) do if f.tag == n then return true end end return false end,
    isAlreadyInFaction = function(p) return inFaction(p) ~= nil end,
    canCreateFaction = function(p)
        if not OPTS.Faction then return false end
        return p:getHoursSurvived() >= (OPTS.FactionDaySurvivedToCreate or 0) * 24
    end,
}
ColorInfo = { new = function(r, g, b) return { getR = function() return r end, getG = function() return g end, getB = function() return b end } end }
State = { Accepted = "Accepted", Refused = "Refused", Canceled = "Canceled", Ended = "Ended", Claimed = "Claimed" }
function getWars() return jlist(WARS) end
local function call(name, fn)
    _G[name] = function(...)
        CALLS[#CALLS + 1] = { name = name, a = { ... } }
        if not REFUSE and fn then fn(...) end
    end
end
call("sendSafehouseClaim", function(sq, p, title) local s = newSafe(6340, 5360, 20, 20, p:getUsername()); s.title = title end)
call("sendSafehouseChangeTitle", function(s, text) s.title = text end)
call("sendSafehouseChangeRespawn", function(s, who, on) s.respawn[who] = on or nil end)
call("sendSafehouseInvite")
call("acceptSafehouseInvite")
call("sendSafehouseChangeMember", function(s, who)
    for i = #s.players, 1, -1 do if s.players[i] == who then table.remove(s.players, i) end end
end)
call("sendSafehouseChangeOwner", function(s, who) s.owner = who end)
call("sendSafehouseRelease", function(s) for i = #GS, 1, -1 do if GS[i] == s then table.remove(GS, i) end end end)
call("sendFactionCreate", function(name, who) newFaction(name, who) end)
call("sendFactionChangeTitle", function(f, name) f.name = name end)
call("sendFactionChangeTag", function(f)
    local tag, color = f.tag, f.color
    SYNCS[#SYNCS + 1] = function() f.tag, f.color = tag, color end
end)
call("sendFactionInvite")
call("acceptFactionInvite")
call("sendFactionChangeOwner", function(f, who)
    for i = #f.players, 1, -1 do if f.players[i] == who then table.remove(f.players, i) end end
    f.players[#f.players + 1] = f.owner
    f.owner = who
end)
call("sendFactionRemoveMember", function(f, who)
    for i = #f.players, 1, -1 do if f.players[i] == who then table.remove(f.players, i) end end
end)
call("sendFactionDisband", function(f) for i = #GF, 1, -1 do if GF[i] == f then table.remove(GF, i) end end end)
call("sendFactionStatsChange")
call("sendWarManagerUpdate")
function PLAYER.getCurrentSquare() return { getBuilding = function() return INSIDE and {} or nil end } end
NonPvpZone = { getNonPvpZone = function() return nil end }
JoypadState = { players = {} }
Joypad = { AButton = 1, BButton = 2 }
Keyboard = { KEY_ESCAPE = 1 }
Translator = { getLanguage = function() return { name = function() return "EN" end } end, getAvailableLanguage = function() return nil end }
UIFont = setmetatable({}, { __index = function(_, k) return k end })
local TEXT = {}
do
    local f = assert(io.open(ROOT .. "42/media/lua/shared/Translate/EN/UI.json", "rb"))
    local s = f:read("*a")
    f:close()
    for k, v in s:gmatch('"([%w_]+)": "(.-)",?%s*\n') do TEXT[k] = v end
end
-- the game's own words, where its install is here: measured as they will draw
for _, name in ipairs({ "UI.json", "IG_UI.json", "ContextMenu.json" }) do
    local g = io.open("E:/Project Zomboid/steamapps/common/ProjectZomboid/media/lua/shared/Translate/EN/" .. name, "rb")
    if g then
        local s = g:read("*a")
        g:close()
        for k, v in s:gmatch('"([%w_]+)": "(.-)",?%s*\n') do TEXT[k] = TEXT[k] or v end
    end
end
TEXT.UI_Cancel, TEXT.UI_userpanel_tickets = "Cancel", "Tickets"
TEXT.IGUI_UserList_BannedIPs_Refresh = "Refresh"
function getText(k, ...)
    local s = TEXT[k] or k
    local a = { ... }
    for i = 1, 4 do
        if a[i] ~= nil then s = string.gsub(s, "%%" .. i, (string.gsub(tostring(a[i]), "%%", "%%%%"))) end
    end
    return s
end
getTextOrNull = function(k) return TEXT[k] end
local SENT, COMMANDS, GAME = {}, {}, {}
function sendClientCommand(p, m, c, a) SENT[#SENT + 1] = { m = m, c = c, a = a }; CLIENT[#CLIENT + 1] = { m = m, c = c, a = a } end
function SendCommandToServer(s) COMMANDS[#COMMANDS + 1] = s end
CLIENT = {}
function getTickets(who) GAME[#GAME + 1] = { "get", who } end
function addTicket(a, b, c) GAME[#GAME + 1] = { "add", a, b, c } end
function removeTicket(id) GAME[#GAME + 1] = { "remove", id } end
function viewedTicket(a, b) GAME[#GAME + 1] = { "viewed", a, b } end

local EVENTS = setmetatable({}, { __index = function(t, k)
    local e = { list = {} }
    e.Add = function(fn) e.list[#e.list + 1] = fn end
    e.Remove = function(fn) for i = #e.list, 1, -1 do if e.list[i] == fn then table.remove(e.list, i) end end end
    rawset(t, k, e)
    return e
end })
Events = EVENTS
LuaEventManager = { AddEvent = function() end }

-- the game's classes the files derive ------------------------------------------------------
ISUIElement = {}
ISPanel = {}
ISPanel.__index = ISPanel
function ISPanel:derive(name)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.Type = name
    return o
end
function ISPanel:new(x, y, w, h)
    local o = { x = x, y = y, width = w, height = h, visible = true, kids = {} }
    setmetatable(o, self)
    self.__index = self
    return o
end
function ISPanel:initialise() end
function ISPanel:instantiate() end
function ISPanel:createChildren() end
function ISPanel:update() end
function ISPanel:prerender() end
function ISPanel:render() end
function ISPanel:addChild(c)
    self.kids[#self.kids + 1] = c
    if c.createChildren then c:createChildren() end
end
function ISPanel:setVisible(v) self.visible = v end
function ISPanel:isVisible() return self.visible end
function ISPanel:getX() return self.x end
function ISPanel:getY() return self.y end
function ISPanel:getWidth() return self.width end
function ISPanel:getHeight() return self.height end
function ISPanel:setX(v) self.x = v end
function ISPanel:setY(v) self.y = v end
function ISPanel:setWidth(v) self.width = v end
function ISPanel:setHeight(v) self.height = v end
function ISPanel:drawRect() end
function ISPanel:drawRectBorder() end
function ISPanel:drawText() end

ISTextEntryBox = ISPanel:derive("ISTextEntryBox")
function ISTextEntryBox:new(text, x, y, w, h)
    local o = ISPanel.new(self, x, y, w, h)
    o.text = text or ""
    o.javaObject = { setMaxLines = function(_, n) o.maxL = n end, setMaxTextLength = function(_, n) o.maxT = n end, setCentreVertically = function() end }
    return o
end
function ISTextEntryBox:setMultipleLine(on) self.multi = on end
function ISTextEntryBox:setPlaceholderText() end
function ISTextEntryBox:setMaxTextLength(n) self.maxT = n end
function ISTextEntryBox:getText() return self.text end
function ISTextEntryBox:setText(s) self.text = s end
function ISTextEntryBox:focus() self.hasFocus = true end
function ISTextEntryBox:unfocus() self.hasFocus = false end
function ISTextEntryBox:isFocused() return self.hasFocus == true end

ISMouseDrag = {}
-- the window class: the frame's draws are ZeD_Window's own and need the engine, so a stub with its measures. Its panel calls are a stub panel's
ZeD_Window = ISPanel:derive("ZeD_Window")
function ZeD_Window:new(x, y, w, h, title)
    local o = ISPanel.new(self, x, y, w, h)
    o.title = title or ""
    return o
end
function ZeD_Window:titleBarHeight() return ZeD.T.titleBarH end
function ZeD_Window:footerHeight() return ZeD.T.px(22) end
function ZeD_Window:createChildren() self._closeBtnRect = {} end
function ZeD_Window:prerender() end
function ZeD_Window:render() end
function ZeD_Window:update() end
function ZeD_Window:close() self:setVisible(false) end
function ZeD_Window:onMouseDown() return true end
function ZeD_Window:closeRect() return nil end
function ZeD_Window:windowBoxRect() return nil end
function ZeD_Window:isMouseOver() return false end
function ISPanel:addToUIManager() self.inUI = true end
function ISPanel:removeFromUIManager() self.inUI = false end
function ISPanel:setAlwaysOnTop(v) self.onTop = v end
function ISPanel:bringToTop() end
function ISPanel:getIsVisible() return self.visible end
function ISPanel:getMouseX() return -1 end
function ISPanel:getMouseY() return -1 end
function ISPanel:setStencilRect() end
function ISPanel:clearStencilRect() end
function ISPanel:setWantKeyEvents() end
ISChat = { instance = nil, allChatStreams = {} }
KeybindId = {}
MSG_SENT = {}
function processSayMessage(t) MSG_SENT[#MSG_SENT + 1] = t end
ISPlayerStatsUI = { opened = 0 }
function ISPlayerStatsUI:new()
    ISPlayerStatsUI.opened = ISPlayerStatsUI.opened + 1
    return { initialise = function() end, addToUIManager = function() end }
end
ISAdminMessage = { AddAdminMessage = function() end }

-- the files --------------------------------------------------------------------------------
local LOADED = {}
local STUBBED = { ["ZeD/Organisms"] = true, ["ZeD/ZeD_CharacterWindow"] = true, ["ZeD/ZeD_WorldWindow"] = true, ["ZeD/ZeD_TabPx"] = true, ["ZeD/ZeD_Messages"] = true, ["ZeD/SafeMode"] = true }
function require(name)
    if LOADED[name] then return end
    LOADED[name] = true
    if STUBBED[name] or not string.find(name, "^ZeD/") then return end
    local short = string.sub(name, 5)
    local path = ROOT .. "42/media/lua/client/ZeD/" .. short .. ".lua"
    local f = io.open(path, "rb")
    if f then f:close() else path = ROOT .. "42/media/lua/shared/ZeD/" .. short .. ".lua" end
    local fn, err = loadfile(path)
    if not fn then error(err) end
    fn()
end

ZeD = {}
ZeD.logOnce = function(k, e) print("FAIL logged: " .. tostring(k) .. ": " .. tostring(e)); failed = failed + 1 end
-- measures from the font's own size: a little wider than Fira's real average, so this errs on the side of too long
-- the five role fonts' sizes (Tokens.lua: ZeD.TextSizes), Normal and Large
local function fontPx(font)
    local T, big = ZeD.T, ZEDQA_LARGE
    if font == T.fontF1 then return big and 13 or 11 end
    if font == T.fontF2 then return big and 15 or 13 end
    if font == T.fontF3 then return big and 13 or 11 end
    if font == T.fontF4 then return big and 17 or 15 end
    if font == T.fontF5 then return big and 11 or 9 end
    return 11
end
ZeD.TM = {
    MeasureStringX = function(_, font, s) return math.ceil(#tostring(s) * fontPx(font) * ZeD.T.root * 0.60) end,
    MeasureStringY = function(_, font, s) return math.ceil(fontPx(font) * ZeD.T.root * 1.3) end,
    getFontHeight = function(_, font) return math.ceil(fontPx(font) * ZeD.T.root * 1.3) end,
}
ZeD.Scale = { root = function() return ZEDQA_ROOT or 1 end }
ZeD.Help = { set = function(_, s) ZeD.Help.last = s end }
ZeD.Surface = nil
ZeD.Focus = { mark = function(panel, x, y, w, h, f) ZEDQA_MARKS = (ZEDQA_MARKS or 0) + 1; return true end }
ZeD.Messages = { ticket = function() end, ticketNew = function() end, invite = function(text) NOTES[#NOTES + 1] = text end }
ZeD.PadGlyphs = nil
ZeD.btnCase = function(s) return s end
ZeD.upper = function(s) return string.upper(s) end

local TABS = {}
ZeD_CharacterWindow = { addTab = function(def) TABS.server = def end, openTab = function(n, id) OPENED[#OPENED + 1] = id; return true end, getWindow = function() return "the Character window" end }
ZeD_WorldWindow = { addTab = function(def) TABS.admin = def end, openTab = function(n, id) OPENED[#OPENED + 1] = id; return true end, getWindow = function() return "the World window" end }
ZeD.Safe = { on = function(name) return SAFE == name end, guard = function(panel, fn)
    local ok, err = pcall(fn, panel)
    if ok then return true end
    return false
end, register = function() end }
ZeD.Prompt = { padNote = function(s) return s end }

local FOCUS = { id = nil, pad = false, soon = {} }
ZeD.Input = { Focus = {
    isFocused = function(_, _, id) return FOCUS.pad and id == FOCUS.id end,
    cuesVisible = function() return FOCUS.pad end,
    focusSoon = function(_, zone, pred) FOCUS.soon[#FOCUS.soon + 1] = { zone = zone, pred = pred } end,
    getFocusedWindow = function() return FOCUS.win end,
    getFocusedElement = function() return FOCUS.el end,
    claimFocus = function(w) FOCUS.claimed = w end,
    reclaimEngineFocus = function() FOCUS.reclaimed = true end,
    releaseFocus = function() FOCUS.win = nil end,
} }

require "ZeD/Tokens"
do
    -- (Kahlua's string.char takes wide characters, the test language's letters; Lua 5.1's does not)
    local char = string.char
    string.char = function(...)
        local a = { ... }
        for i, v in ipairs(a) do if v > 255 then a[i] = 63 end end
        return char(unpack(a))
    end
end
require "ZeD/Tr"
ZeD.tr = ZeD.tr
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
ZeD.btnCase = ZeD.btnCase or function(s) return s end
require "ZeD/ServerTab"
require "ZeD/AdminTab"
require "ZeD/ZeD_Chat"
local TC, C, S, Tk, CC, K = ZeD.TicketCards, ZeD.Tickets, ZeD.ServerPart, ZeD.Tk, ZeD.ClaimCards, ZeD.Claims
local CM, M, AC, A2, Cm, Ch = ZeD.CommunityCards, ZeD.Community, ZeD.AdminCards, ZeD.Admin, ZeD.Cm, ZeD.Chat
ZeD.applyTheme("dark", "orange", "small")
check("the real files load", TC ~= nil and TABS.server ~= nil and TABS.admin ~= nil)

local function newPanel(w, h)
    local p = { w = w, h = h, texts = {}, kids = {}, mx = -1, my = -1 }
    function p:getWidth() return self.w end
    function p:getHeight() return self.h end
    function p:getMouseX() return self.mx end
    function p:getMouseY() return self.my end
    function p:getAbsoluteX() return 0 end
    function p:getAbsoluteY() return 0 end
    local function op(self, o)
        if ZEDQA_SVG then
            o.clip = self.st
            self.ops[#self.ops + 1] = o
        end
    end
    p.op = op
    p.ops = {}
    function p:drawRect(x, y, ww, hh, a, r, g, b)
        assert(type(x) == "number" and type(y) == "number" and type(ww) == "number" and type(hh) == "number", "drawRect args")
        assert(type(b) == "number", "drawRect color")
        op(self, { k = "r", x = x, y = y, w = ww, h = hh, a = a, r = r, g = g, b = b })
    end
    function p:drawRectBorder(x, y, ww, hh, a, r, g, b)
        assert(type(b) == "number", "drawRectBorder color")
        op(self, { k = "b", x = x, y = y, w = ww, h = hh, a = a, r = r, g = g, b = b })
    end
    function p:drawText(s, x, y, r, g, b, a, font)
        assert(type(s) == "string", "drawText words: " .. tostring(s))
        assert(type(a) == "number", "drawText alpha")
        assert(font ~= nil, "drawText font")
        self.texts[#self.texts + 1] = { s = s, x = x, y = y, w = ZeD.TM:MeasureStringX(font, s), font = font }
        op(self, { k = "t", s = s, x = x, y = y, a = a, r = r, g = g, b = b, font = font })
    end
    function p:drawTexture() end
    function p:drawTextureScaled() end
    function p:drawTextureScaledAspect() end
    function p:setStencilRect(x, y, ww, hh) self.st = { x = x, y = y, w = ww, h = hh } end
    function p:clearStencilRect() self.st = nil end
    function p:addChild(c)
        self.kids[#self.kids + 1] = c
        if c.createChildren then c:createChildren() end
    end
    return p
end

local function coreOf(sw, sh)
    getCore = function() return { getOptionFontSizeReal = function() return 1 end, getScreenWidth = function() return sw end, getScreenHeight = function() return sh end,
        getOptionClock24Hour = function() return true end } end
end
ZeD.Safe.on = function() return SAFE == true end


-- ===========================================================================================
-- THIS SIM'S OWN STUBS: what the files below read that the harness above does not give
-- ===========================================================================================
ZeD.Surface = { fill = function() end }
function getGameTime() return { getWorldAgeHours = function() return 270 end, getHour = function() return 14 end, getMinutes = function() return 5 end,
    getTimeOfDay = function() return 14.1 end } end
function getTextManager() return { getFontHeight = function() return 16 end, MeasureStringX = function(_, f, s) return #tostring(s) * 8 end,
    MeasureStringY = function() return 16 end } end
function instanceof(o, cls) return type(o) == "table" and o._class == cls end
string.trim = string.trim or function(s) return (string.gsub(s, "^%s*(.-)%s*$", "%1")) end
luautils = { round = function(v, n) local m = 10 ^ (n or 0); return math.floor(v * m + 0.5) / m end }
function getSteamModeActive() return false end
function getSteamScoreboard() return false end
function getStreamModeActive() return false end
SENT_CMDS = {}
SendCommandToServer = function(s) SENT_CMDS[#SENT_CMDS + 1] = s end
VAN = {}
MainScreen = { instance = { inGame = true, scoreOption = { internal = "SCOREBOARD" }, inviteOption = { internal = "INVITE" }, bottomPanel = { isVisible = function() return true end } },
    onMenuItemMouseDownMainMenu = function(item) VAN[#VAN + 1] = item.internal end }
ISChat = { instance = { muted = {}, mutedUsers = {}, isMuted = function(self, u) return self.muted[u] == true end, mute = function(self, u) self.muted[u] = not self.muted[u] or nil end }, allChatStreams = {} }
VoiceManager = { m = {}, playerGetMute = function(self, u) return self.m[u] == true end, playerSetMute = function(self, u) self.m[u] = not self.m[u] end }
-- the panel stub's extra draws the menu's files use
function ISPanel:getAbsoluteX() return self.x end
function ISPanel:getAbsoluteY() return self.y end
function ISPanel:drawTexture() end
function ISPanel:drawTextureScaled() end
function ISPanel:drawTextureScaledAspect() end
function ISPanel:isMouseOver() return false end
function ISPanel:isReallyVisible() return self.visible end
function ISPanel:getChildren() return self.kids end
function ISTextEntryBox:getInternalText() return self.text end
function ISTextEntryBox:setOnlyNumbers(on) self.numbers = on end
function ISPanel:removeChild(c) for i = #self.kids, 1, -1 do if self.kids[i] == c then table.remove(self.kids, i) end end end
STUBBED["ZeD/PixelFonts"] = true
STUBBED["ZeD/MenuNote"] = true
STUBBED["ZeD/Input/SpatialNav"] = true

-- the game's server options (ServerOptions.getInstance(): getPublicOptions, getOptionByName)
local OPTS_LIST = {}
local function opt(name, typ, value, enumWords)
    local o = { name = name, typ = typ, value = value, _class = enumWords and "EnumConfigOption" or nil }
    function o.getType(self) return self.typ end
    function o.getValueAsString(self) return tostring(self.value) end
    function o.getValue(self) return self.value end
    if enumWords then function o.getValueTranslationByIndex(self, i) return enumWords[i] end end
    OPTS_LIST[#OPTS_LIST + 1] = o
    return o
end
opt("PVP", "boolean", true)
opt("MaxPlayers", "integer", 32)
opt("PublicName", "string", "Knox Survivors")
opt("loot", "enum", 2, { "Rare", "Normal", "Common" })
ServerOptions = { getInstance = function() return {
    getPublicOptions = function()
        local names = {}
        for _, o in ipairs(OPTS_LIST) do names[#names + 1] = o.name end
        return { size = function() return #names end, get = function(_, i) return names[i + 1] end }
    end,
    getOptionByName = function(_, n) for _, o in ipairs(OPTS_LIST) do if o.name == n then return o end end return nil end,
} end }
ISServerOptions = { opened = 0 }
function ISServerOptions:new() ISServerOptions.opened = ISServerOptions.opened + 1; return { initialise = function() end, addToUIManager = function() end } end

-- the game's saving pop-up, registered as its own file does
VAN_SAVING = 0
ISServerSavingMessage = { showPauseMessage = function() VAN_SAVING = VAN_SAVING + 1 end, showSavingFinishMessage = function() VAN_SAVING = VAN_SAVING - 1 end }
Events.OnServerStartSaving.Add(ISServerSavingMessage.showPauseMessage)
Events.OnServerFinishSaving.Add(ISServerSavingMessage.showSavingFinishMessage)
-- the game's admin pop-up, registered as its own file does
VAN_ADMIN = {}
-- (ZeD_Tickets.lua took the game's listener off as it loaded with the harness; its own reads this at each message)
ISAdminMessage.AddAdminMessage = function(m) VAN_ADMIN[#VAN_ADMIN + 1] = m end
-- the game's item editor: its window (only its OpenPanel), and its real field list (ISItemEditPanel.lua from the install)
VAN_EDITOR = 0
ISItemEditorUI = { OpenPanel = function() VAN_EDITOR = VAN_EDITOR + 1 end }
ISDebugUtils = { FONT_HGT_SMALL = 16 }
do
    local fn = loadfile("E:/Project Zomboid/steamapps/common/ProjectZomboid/media/lua/client/ISUI/AdminPanel/ISItemEditPanel.lua")
    if fn then fn() end
end
check("the game's ISItemEditPanel.lua is here to read", ISItemEditPanel ~= nil and ISItemEditPanel.initElements ~= nil)

-- the files under test, real ---------------------------------------------------------------------------------------------
STUBBED["ZeD/ZeD_Messages"] = nil
LOADED["ZeD/ZeD_Messages"] = nil
ZeD.Messages = nil
require "ZeD/ZeD_Messages"
local MS = ZeD.Messages
require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MainMenuPlayers"
require "ZeD/ZeD_FormCard"
-- the game's own map's Sharing tool (ISWorldMapSymbols.lua), as the file defines it
ISWorldMapSymbolTool_Sharing = { showPropertiesUI = function() VAN_TOOL = (VAN_TOOL or 0) + 1; return true end }
require "ZeD/ZeD_MpLeftovers"
require "ZeD/ZeD_LeftScreen"
local MM, PL, L, LS, FC = ZeD.MainMenu, ZeD.PausePlayers, ZeD.MpLeftovers, ZeD.LeftScreen, ZeD.FormCard
check("the files load", MM ~= nil and PL ~= nil and L ~= nil and LS ~= nil and FC ~= nil)

-- a frame of a window: its prerender on the stub's draws, with the ZeD frame stubbed
local function draws(win)
    local ok, err = pcall(function() win:prerender() end)
    check("a frame draws: " .. tostring(win.kind or win.Type), ok, err)
end

-- ===========================================================================================
-- C1 PLAYERS: the pause window's page, on the scoreboard, with the game's actions
-- ===========================================================================================
print("-- C1 players")
local pause = ZeD_MMWindow:new("pause")
pause:initialise()
MM.pause = pause
MM.act.players()
check("Players opens ZeD's page, not the game's scoreboard", pause.page == "players" and #VAN == 0, tostring(pause.page) .. " / " .. table.concat(VAN, ","))
local function specById(win, id) for _, s in ipairs(win._specs or {}) do if s.id == id then return s end end return nil end
local function fire(win, id)
    local s = specById(win, id)
    check("there is a " .. id, s ~= nil)
    if s and s.fn and not s.disabled then s.fn() end
end
-- the scoreboard's reply, as the game sends it
local function jl(t) return { size = function() return #t end, get = function(_, i) return t[i + 1] end } end
Events.OnScoreboardUpdate.list[#Events.OnScoreboardUpdate.list] = Events.OnScoreboardUpdate.list[#Events.OnScoreboardUpdate.list]
for _, fn in ipairs(Events.OnScoreboardUpdate.list) do fn(jl({ "Aretha", "bob", "Cleo" }), jl({ "Aretha", "Bob", "Cleo" }), jl({}), jl({ 40, 120, 80 })) end
check("the reply fills the list, by name", #PL.list == 3 and PL.list[2].user == "bob" and PL.list[2].ping == 120)
for _, prof in ipairs({ { 1280, 800, 0.75 }, { 1920, 1080, 1 }, { 3840, 2160, 2 } }) do
    coreOf(prof[1], prof[2])
    ZEDQA_ROOT = prof[3]
    ZeD.applyTheme("dark", "orange", "small")
    pause:build()
    draws(pause)
    check("three rows at " .. prof[1], specById(pause, "pl:bob") ~= nil and specById(pause, "pl:Cleo") ~= nil)
    check("the page fits the screen at " .. prof[1], pause.height <= prof[2] and pause.width <= prof[1], pause.width .. "x" .. pause.height)
end
check("no actions before a pick", specById(pause, "act:kick") == nil and specById(pause, "act:mute") == nil)
fire(pause, "pl:bob")
pause:build()
check("a pick shows Mute and Voice mute for another player", specById(pause, "act:mute") ~= nil and specById(pause, "act:voip") ~= nil)
check("no Kick for a role without it", specById(pause, "act:kick") == nil)
ZEDQA_CAPS.KickUser, ZEDQA_CAPS.BanUnbanUser, ZEDQA_CAPS.TeleportToPlayer = true, true, true
pause:build()
check("Kick, Ban, Ban IP and Teleport for staff", specById(pause, "act:kick") and specById(pause, "act:ban") and specById(pause, "act:banip") and specById(pause, "act:tp"))
fire(pause, "act:mute")
check("Mute is the game's chat mute, by username", ISChat.instance.muted.bob == true)
fire(pause, "act:tp")
check("Teleport sends the game's command", SENT_CMDS[#SENT_CMDS] == '/teleport "bob"', SENT_CMDS[#SENT_CMDS])
local before = #SENT_CMDS
fire(pause, "act:kick")
pause:build()
draws(pause)
check("Kick asks first in the band", pause._ask ~= nil and specById(pause, "ask:yes") ~= nil and #SENT_CMDS == before, tostring(pause._ask))
draws(pause)
fire(pause, "ask:no")
pause:build()
check("Cancel leaves no question and sends nothing", pause._ask == nil and #SENT_CMDS == before)
fire(pause, "act:kick")
draws(pause)
fire(pause, "ask:yes")
check("the answer sends the game's kick", SENT_CMDS[#SENT_CMDS] == '/kickuser "bob"', SENT_CMDS[#SENT_CMDS])
-- with ZeD's server part: Kick and Ban open ZeD's Admin player card (it asks for the reason), no command, no question
do
    local Ad = ZeD.Admin
    local realLive = Ad.live
    Ad.live = function() return true end
    OPENED = {}
    local n0 = #SENT_CMDS
    fire(pause, "act:kick")
    check("Kick opens ZeD's Admin player card on that player", Ad.openPlayerNext == "bob" and OPENED[#OPENED] == "admin" and #SENT_CMDS == n0
        and pause._pp.players.ask == nil, tostring(Ad.openPlayerNext))
    Ad.openPlayerNext = nil
    MM.act.players()
    pause:build()
    fire(pause, "pl:bob")
    pause:build()
    fire(pause, "act:banip")
    check("Ban IP too", Ad.openPlayerNext == "bob" and #SENT_CMDS == n0)
    Ad.openPlayerNext = nil
    fire(pause, "act:mute")
    check("Mute stays a quick action", ISChat.instance.muted.bob == nil)
    fire(pause, "act:mute")
    Ad.live = realLive
    MM.act.players()
    pause:build()
    fire(pause, "pl:bob")
    pause:build()
end
before = #SENT_CMDS
fire(pause, "act:ban")
draws(pause)
pause:joyB()
check("B with a question up is its Cancel, on the page, back on the button", pause.page == "players" and pause._pp.players.ask == nil
    and pause.focusId == "act:ban" and #SENT_CMDS == before, tostring(pause.page) .. " " .. tostring(pause.focusId))
fire(pause, "pl:Aretha")
pause:build()
check("your own row: no Kick, no Mute", specById(pause, "act:kick") == nil and specById(pause, "act:mute") == nil)
-- many players: the list scrolls under the D-pad
local many, names = {}, {}
for i = 1, 60 do many[#many + 1] = string.format("p%02d", i) end
for _, fn in ipairs(Events.OnScoreboardUpdate.list) do fn(jl(many), jl(many), jl({}), jl({})) end
coreOf(1280, 800)
pause.focusId = nil
pause:build()
local st = pause._pp.players
check("a long list shows a part of it", st.shown < 60 and st.shown >= 3, st.shown)
pause.focusId = "pl:" .. many[st.shown]
pause:joyDir("down")
check("down past the last row moves the list", st.off == 1 and pause.focusId == "pl:" .. many[st.shown + 1], tostring(st.off) .. " " .. tostring(pause.focusId))
pause:joyDir("up")
pause.focusId = "pl:" .. many[2]
pause:joyDir("up")
pause:joyDir("up")
check("up past the first row moves it back", st.off == 0)
draws(pause)
pause:joyB()
check("B goes back to the pause list, on the Players button", pause.page == nil and pause.focusId == "players", tostring(pause.focusId))

-- ===========================================================================================
-- C3 INVITE: the game's InviteFriends object does the work
-- ===========================================================================================
print("-- C3 invite")
local function friend(name, state, id) return { getName = function() return name end, getState = function() return state end, getSteamID = function() return id end, getAvatar = function() return nil end } end
local G = { invited = {}, isCoopHost = true, listbox = { items = {} }, saved = 0, invitedCalls = {} }
G.filterEntry = { t = "", setText = function(self, s) self.t = s end, getInternalText = function(self) return self.t end }
function G.fillList(self)
    -- (the game's: its filter entry's words narrow the list)
    local f = string.lower(self.filterEntry.t or "")
    self.listbox.items = {}
    for _, e in ipairs({ { "Ann", "Online", "1" }, { "Zed", "Offline", "2" } }) do
        if f == "" or string.find(string.lower(e[1]), f, 1, true) then
            self.listbox.items[#self.listbox.items + 1] = { text = e[1], item = friend(e[1], e[2], e[3]) }
        end
    end
end
function G.clickInvite(self) self.invitedCalls[#self.invitedCalls + 1] = self.listbox.items[self.listbox.selected].text end
function G.toggleAllowDeny(self, i) local id = self.listbox.items[i].item:getSteamID(); self.invited[id] = not self.invited[id] or nil end
function G.saveInvitedFile(self) self.saved = self.saved + 1 end
InviteFriends = { instance = G }
VAN = {}
MM.act.invite()
check("Invite opens ZeD's page, not the game's screen", pause.page == "invite" and #VAN == 0)
pause:build()
draws(pause)
check("the friends in the game's order", specById(pause, "iv:1") and specById(pause, "iv:2"))
check("a Find field above the friends", specById(pause, "iv:find") ~= nil and specById(pause, "iv:find").y < specById(pause, "iv:1").y)
check("the field is drawn in it", pause._ivFind ~= nil and pause._ivFind.visible == true)
pause._ivFind.text = "ze"
pause._ivFind.onTextChange()
pause:build()
check("Find narrows the list through the game's own filter", G.filterEntry.t == "ze" and specById(pause, "iv:2") ~= nil and specById(pause, "iv:1") == nil)
pause._ivFind.text = "qq"
pause._ivFind.onTextChange()
pause:build()
draws(pause)
check("no match: its own line, no rows", specById(pause, "iv:1") == nil and specById(pause, "iv:2") == nil)
pause._ivFind.text = ""
pause._ivFind.onTextChange()
pause:build()
draws(pause)
check("Invite waits for a pick", specById(pause, "invite") and specById(pause, "invite").disabled == true)
fire(pause, "iv:1")
draws(pause)
fire(pause, "invite")
check("Invite is the game's clickInvite on that friend", G.invitedCalls[1] == "Ann")
draws(pause)
fire(pause, "allow")
check("Allow is the game's toggleAllowDeny", G.invited["1"] == true)
draws(pause)
fire(pause, "back")
check("leaving keeps the game's invited list, and the Find field goes", G.saved == 1 and pause.page == nil and pause._ivFind.visible == false)
InviteFriends = nil
VAN = {}
MM.act.invite()
check("no game screen object: the game's own item", VAN[1] == "INVITE")

-- ===========================================================================================
-- C2 SERVER OPTIONS: a card in the Server tab
-- ===========================================================================================
print("-- C2 server options")
coreOf(1920, 1080)
ZEDQA_ROOT = 1
ZeD.applyTheme("dark", "orange", "small")
local SV = ZeD.ServerTab
local win = { _playerObj = PLAYER, playerNum = 0 }
local panel = newPanel(420, 700)
TABS.server.render(panel, win, 0, 0, 420, 700)
ISServerOptions.opened = 0
SV.OPEN.options(PLAYER, win)
check("See server options opens ZeD's card, not the game's window", win._serverTab.card and win._serverTab.card.kind == "srvopts" and ISServerOptions.opened == 0)
TABS.server.render(panel, win, 0, 0, 420, 700)
local rows = SV.optionRows()
check("the game's public options, by name", #rows == 4 and rows[1].name == "loot" and rows[4].name == "PVP", rows[1].name)
local byName = {}
for _, r in ipairs(rows) do byName[r.name] = r.value end
check("on and off in the game's words", byName.PVP == getText("UI_Yes"), byName.PVP)
check("an enum in its own words (the game's index is its value)", byName.loot == "Normal", byName.loot)
local drew = {}
for _, t in ipairs(panel.texts) do drew[t.s] = true end
check("the card draws the options", drew.MaxPlayers and drew["32"] and drew.PublicName, "")
for _, t in ipairs(panel.texts) do check("option text inside the card: " .. t.s, t.x >= -1 and t.x + t.w <= 421, t.x .. "+" .. t.w) end
local foot = ZeD.TicketCards.kinds.srvopts.foot(win, win._serverTab, nil, win._serverTab.card)
check("no Change for a player", #foot.main == 0)
ZEDQA_CAPS.ChangeAndReloadServerOptions = true
foot = ZeD.TicketCards.kinds.srvopts.foot(win, win._serverTab, nil, win._serverTab.card)
check("Change for staff who may change options", #foot.main == 1)
foot.main[1].run(win)
check("and Change is the game's own window", ISServerOptions.opened == 1)
ZEDQA_CAPS.ChangeAndReloadServerOptions = nil
local stops = TABS.server.buildFocusables(win)
local optStops = 0
for _, e in ipairs(stops) do if string.find(e.id or "", "opt:", 1, true) then optStops = optStops + 1 end end
check("the controller can step down the options", optStops >= 1, optStops)
-- the Admin tab's More tools row: the same card, in the Server tab
ZeD.TicketCards.back(win, win._serverTab)
OPENED = {}
for _, m in ipairs(ZeD.AdminTab.MORE) do if m.id == "options" then m.run(PLAYER) end end
check("More tools' server options open the Server tab's card", OPENED[1] == "server" and SV.openNext == "options" and ISServerOptions.opened == 1)
TABS.server.render(panel, win, 0, 0, 420, 700)
check("and the tab opens the card on its next frame", win._serverTab.card and win._serverTab.card.kind == "srvopts" and SV.openNext == nil)

-- ===========================================================================================
-- C4 SERVER SAVING: a notice in Messages (the director: every notice is the belt's bubble, kept in Messages)
-- ===========================================================================================
print("-- C4 saving")
check("the game's saving box is off the events", (function()
    for _, fn in ipairs(Events.OnServerStartSaving.list) do if fn == ISServerSavingMessage.showPauseMessage then return false end end
    return #Events.OnServerStartSaving.list >= 1
end)())
local seq0 = MS.seq
local SRV = ZeD.tr("UI_ZeD_Srv_Server")
local adm0 = MS.sources[ZeD.tr("UI_ZeD_Adm_NoteHead")] and #MS.sources[ZeD.tr("UI_ZeD_Adm_NoteHead")].items or 0
local realToast = ZeD.Settings
ZeD.Settings = { messagesToastOn = function() return true end, messagesCatchOn = function() return true end }
MS.toasts = {}
for _, fn in ipairs(Events.OnServerStartSaving.list) do fn() end
local top = MS.sources[SRV] and MS.sources[SRV].items[1]
check("saving is a notice under its own Server heading, not the game's box nor a panel", top ~= nil and top.k == "server" and top.text == ZeD.tr("UI_ZeD_Srv_Saving")
    and MS.seq > seq0 and VAN_SAVING == 0 and ZeD_SavingNote == nil)
check("not under Admin", (MS.sources[ZeD.tr("UI_ZeD_Adm_NoteHead")] and #MS.sources[ZeD.tr("UI_ZeD_Adm_NoteHead")].items or 0) == adm0)
check("an info bubble, not a warning", MS.toasts[#MS.toasts] and MS.toasts[#MS.toasts].kind == "info", MS.toasts[#MS.toasts] and MS.toasts[#MS.toasts].kind)
for _, fn in ipairs(Events.OnServerFinishSaving.list) do fn() end
top.read = true
for _, fn in ipairs(Events.OnServerStartSaving.list) do fn() end
for _, fn in ipairs(Events.OnServerStartSaving.list) do fn() end
check("one entry, updated in place each save", #MS.sources[SRV].items == 1 and MS.sources[SRV].items[1] == top and top.read == false)
ZeD.Settings = realToast
for _, fn in ipairs(Events.OnServerFinishSaving.list) do fn() end
check("done leaves the notice kept in Messages", MS.sources[SRV].items[1] == top and VAN_SAVING == 0)
SAFE = true
ZeD.Safe.on = function() return SAFE == true end
for _, fn in ipairs(Events.OnServerStartSaving.list) do fn() end
check("safe mode: the game's box", VAN_SAVING == 1)
for _, fn in ipairs(Events.OnServerFinishSaving.list) do fn() end
check("and the game's box goes away", VAN_SAVING == 0)
SAFE = nil

-- ===========================================================================================
-- C16 ADMIN MESSAGE: a note in Messages
-- ===========================================================================================
-- the game's user and admin panels' See server options
do
    local SV2 = ZeD.ServerTab
    local Panel = { van = 0 }
    function Panel.onOptionMouseDown(self, button) Panel.van = Panel.van + 1 end
    SV2.wrapPanel(Panel, "SERVEROPTIONS")
    OPENED = {}
    SV2.openNext = nil
    Panel.onOptionMouseDown({ player = PLAYER }, { internal = "SERVEROPTIONS" })
    check("the game's user panel's See server options opens ZeD's card", Panel.van == 0 and OPENED[1] == "server" and SV2.openNext == "options")
    SV2.openNext = nil
    Panel.onOptionMouseDown({ player = PLAYER }, { internal = "FACTION" })
    check("its other buttons stay the game's", Panel.van == 1)
end

print("-- C16 admin message")
VAN_ADMIN = {}
local adminFns = Events.OnAdminMessage.list
check("one admin listener, ZeD's", #adminFns == 1 and adminFns[1] ~= ISAdminMessage.AddAdminMessage, #adminFns)
adminFns[1]("Player <RGB:1,0,0> bob <LINE> dropped 40 items", 120, 340, 0)
local src = MS.sources[ZeD.tr("UI_ZeD_Adm_NoteHead")]
local it = src and src.items[1]
check("an admin message is a note in Messages, not the game's pop-up", it ~= nil and it.k == "adminmsg" and #VAN_ADMIN == 0)
check("in plain words", it and it.text == "Player bob dropped 40 items", it and it.text)
check("with the place for Teleport", it and it.tp and it.tp.x == 120 and it.tp.y == 340)
adminFns[1]("Server restart in 5 minutes", -1, -1, -1)
check("no place, no Teleport", MS.sources[ZeD.tr("UI_ZeD_Adm_NoteHead")].items[1].tp == nil)
SENT_CMDS = {}
L.teleport(it.tp)
check("Teleport is the game's own command", SENT_CMDS[1] == "/teleportto 120,340,0", SENT_CMDS[1])
SAFE = true
adminFns[1]("in safe mode", -1, -1, -1)
check("safe mode: the game's pop-up", VAN_ADMIN[1] == "in safe mode")
SAFE = nil
for i = 1, 40 do adminFns[1]("spam " .. i, -1, -1, -1) end
local n = 0
for _, x in ipairs(MS.sources[ZeD.tr("UI_ZeD_Adm_NoteHead")].items) do if x.k == "adminmsg" then n = n + 1 end end
check("admin messages keep a cap", n == 30, n)

-- ===========================================================================================
-- C5 MAP MARK SHARING: the form card
-- ===========================================================================================
print("-- C5 sharing")
local function symbol(private, everyone, fac, safe, players)
    local s = { private = private, everyone = everyone, fac = fac, safe = safe, players = players or {}, set = nil }
    function s.canClientModify() return true end
    function s.isPrivate(self) return self.private end
    function s.isVisibleToEveryone(self) return self.everyone end
    function s.isVisibleToFaction(self) return self.fac end
    function s.isVisibleToSafehouse(self) return self.safe end
    function s.getVisibleToPlayerCount(self) return #self.players end
    function s.getVisibleToPlayerByIndex(self, i) return self.players[i + 1] end
    function s.setSharing(self, t) self.set = t or "private" end
    return s
end
for _, fn in ipairs(Events.OnScoreboardUpdate.list) do fn(jl({ "Aretha", "bob" }), jl({ "Aretha", "Bob" }), jl({}), jl({})) end
local sym = symbol(false, false, true, false, { "gone_guy" })
-- the drawer that holds the map, and the map in it
local drawer = ISPanel:new(0, 0, 640, 520)
local mp = ISPanel:new(20, 60, 600, 400)
mp.playerObj = PLAYER
mp.parent = drawer
drawer.kids[#drawer.kids + 1] = mp
check("the card opens on a mark", L.openSharing(mp, sym, false) == true and L.shareCard ~= nil)
local card = L.shareCard
card:layout()
draws(card)
check("the card is in the map's drawer, not on the screen of its own", card.dockedIn == drawer and drawer.kids[#drawer.kids] == card and card.inUI ~= true)
check("at the map's right edge, inside the map", card.x + card.width == 620 and card.y == 60 and card.x >= 20 and card.height <= 400,
    card.x .. "," .. card.y .. " " .. card.width .. "x" .. card.height)
local function rowById(c, id) for _, r in ipairs(c._rows or {}) do if r.id == id then return r end end return nil end
check("the mark's sharing as it is: Other, Faction", rowById(card, "other").on and rowById(card, "faction").on and not rowById(card, "safehouse").on)
check("the players: online, then the one away", rowById(card, "p:bob") and rowById(card, "p:gone_guy") and rowById(card, "p:gone_guy").on, "")
check("you are not on the list", rowById(card, "p:Aretha") == nil)
card:pressRow(rowById(card, "p:bob"))
card:pressRow(rowById(card, "safehouse"))
card:layout()
card:pressButton(card._band.buttons[2])
check("Accept hands the choice to the mark as the game's panel does", type(sym.set) == "table" and sym.set.everyone == false and sym.set.faction == true and sym.set.safehouse == true
    and #sym.set.players == 2, type(sym.set) == "table" and #sym.set.players)
check("and the card is gone from the drawer", card._done == true and drawer.kids[#drawer.kids] == mp)
local sym2 = symbol(false, true, false, false)
L.openSharing(mp, sym2, false)
card = L.shareCard
card:layout()
check("Everyone: Faction and the players are gray", rowById(card, "all").on and rowById(card, "faction").disabled and rowById(card, "p:bob").disabled)
card:pressRow(rowById(card, "private"))
card:layout()
card:pressButton(card._band.buttons[2])
check("Private: the game's setSharing(nil)", sym2.set == "private")
L.openSharing(mp, sym2, false)
card = L.shareCard
sym2.set = nil
card:cancel()
check("Cancel changes nothing", sym2.set == nil and card._done)
-- the drawer leaves the map (another tab, a hidden map): the card goes and lets go
L.openSharing(mp, sym2, false)
card = L.shareCard
mp._drawnMs = getTimestampMs()
card:update()
check("the card stays while the map draws", not card._done)
mp._drawnMs = getTimestampMs() - 2000
card:update()
check("another tab in the drawer: the card closes", card._done and drawer.kids[#drawer.kids] == mp)
mp._drawnMs = nil
L.openSharing(mp, sym2, false)
card = L.shareCard
mp.visible = false
card:update()
check("a hidden map: the card closes", card._done)
check("and no card opens on a hidden map", FC.open({ title = "x", rows = function() return {} end, band = function() return {} end,
    dock = function() return nil end }) == nil)
mp.visible = true
-- Hide author, on someone else's shared mark (the game's setAuthorHidden)
local API = { hidden = {} }
function API.isAuthorHidden(self, a) return self.hidden[a] == true end
function API.setAuthorHidden(self, a, on) self.hidden[a] = on end
mp.mapAPI = { getSymbolsAPIv2 = function() return API end }
local sym3 = symbol(false, true, false, false)
function sym3.isShared() return true end
function sym3.isAuthorLocalPlayer() return false end
function sym3.getAuthor() return "bob" end
L.openSharing(mp, sym3, false)
card = L.shareCard
card:layout()
check("Hide author on someone else's shared mark", rowById(card, "hide") ~= nil and not rowById(card, "hide").on)
card:pressRow(rowById(card, "hide"))
card:layout()
card:pressButton(card._band.buttons[2])
check("Accept hides that author's marks, as the game's panel does", API.hidden.bob == true)
local sym4 = symbol(false, true, false, false)
function sym4.isShared() return true end
function sym4.isAuthorLocalPlayer() return true end
function sym4.getAuthor() return "Aretha" end
L.openSharing(mp, sym4, false)
L.shareCard:layout()
check("no Hide author on your own mark", rowById(L.shareCard, "hide") == nil)
L.shareCard:cancel()
mp.mapAPI = nil
-- the wheel over the card scrolls the card
L.openSharing(mp, sym, false)
card = L.shareCard
card:layout()
card._maxScroll, card._scroll = 100, 0
check("the card takes the wheel", card:onMouseWheel(1) == true and card._scroll > 0)
card:cancel()
-- the game's own map's Sharing tool reaches the card
do
    local gameMap = ISPanel:new(0, 0, 1920, 1080)
    gameMap.playerNum = 0
    local tool = { symbolsUI = { checkAnnotationForSharingMouse = function(u) u.mouseOverSymbol = 3 end, checkAnnotationForSharingJoypad = function() end },
        symbolsAPI = { getSymbolByIndex = function(_, i) return i == 3 and sym or nil end }, mapUI = gameMap }
    VAN_TOOL = 0
    L.shareCard = nil
    check("the game's map tool opens ZeD's card", ISWorldMapSymbolTool_Sharing.showPropertiesUI(tool) == true and VAN_TOOL == 0 and L.shareCard ~= nil)
    check("over the game's map, a card of its own (no drawer)", L.shareCard.dockedIn == nil and L.shareCard.inUI == true)
    L.shareCard:cancel()
    SAFE = true
    ISWorldMapSymbolTool_Sharing.showPropertiesUI(tool)
    check("safe mode: the game's panel", VAN_TOOL == 1)
    SAFE = nil
end
-- the pad
JoypadState.players[1] = { focus = nil, player = 0 }
L.openSharing(mp, sym, false)
card = L.shareCard
check("a controller holds the card", JoypadState.players[1].focus == card)
card:update()
card:layout()
draws(card)
card:onJoypadDirDown()
card:onJoypadDown(Joypad.AButton)
card:layout()
check("down and A pick Everyone", rowById(card, "all").on)
card:onJoypadDown(Joypad.BButton)
check("B cancels and gives the pad back", card._done and JoypadState.players[1].focus == nil)
JoypadState.players[1] = nil

-- ===========================================================================================
-- C15 EDIT ITEM: the game's field list, its save
-- ===========================================================================================
print("-- C15 edit item")
local function item()
    local i = { _class = "HandWeapon", name = "Axe", weight = 3.0, cond = 7, condMax = 10, headCond = 5, saved = {},
        r = 0.5, g = 0.5, b = 0.5 }
    function i.getFullType() return "Base.Axe" end
    function i.getFileName() return "items.txt" end
    function i.getName(self) return self.name end
    function i.setName(self, v) self.name = v; self.saved.name = v end
    function i.getActualWeight(self) return self.weight end
    function i.setActualWeight(self, v) self.weight = v; self.saved.weight = v end
    function i.setCustomWeight(self) self.saved.custom = true end
    function i.getCondition(self) return self.cond end
    function i.setCondition(self, v) self.cond = v; self.saved.cond = v end
    function i.getConditionMax(self) return self.condMax end
    function i.hasHeadCondition() return false end
    function i.isCustomColor() return false end
    function i.allowRandomTint() return false end
    function i.getContainer() return { setDrawDirty = function() end } end
    function i.getTex() return nil end
    function i.getDisplayName(self) return self.name end
    function i.getPlayer() return nil end
    for _, k in ipairs({ "MinDamage", "MaxDamage", "MinAngle", "MinRange", "MinRangeRanged", "MaxRange", "AimingTime", "RecoilDelay", "ReloadTime", "ClipSize", "Sharpness" }) do
        i["get" .. k] = function() return 1.23456 end
        i["set" .. k] = function(self, v) self.saved[k] = v end
    end
    function i.isRanged() return false end
    return i
end
local axe = item()
VAN_EDITOR = 0
ISItemEditorUI.OpenPanel(PLAYER, axe)
local ed = nil
for _, w in ipairs({ L.shareCard }) do end
check("Edit item opens ZeD's card, not the game's window", VAN_EDITOR == 0)
-- the card is the newest FormCard: find it through the hook's own open
local opened = nil
local realOpen = FC.open
FC.open = function(spec) opened = realOpen(spec); return opened end
ISItemEditorUI.OpenPanel(PLAYER, axe)
FC.open = realOpen
check("a card for the item", opened ~= nil and opened.spec.head.name == "Axe")
opened:layout()
draws(opened)
local fieldIds = {}
for _, r in ipairs(opened._rows) do if r.k == "field" then fieldIds[r.label] = r.id end end
check("the game's fields: Name, Weight, Condition", fieldIds[getText("IGUI_Name")] and fieldIds[getText("Tooltip_item_Weight")] and fieldIds[getText("IGUI_invpanel_Condition")], "")
check("read-only words as facts: the item type", (function() for _, r in ipairs(opened._rows) do if r.k == "fact" and r.value == "Base.Axe" then return true end end return false end)())
check("the weapon's fields show for a weapon", fieldIds[getText("IGUI_ItemEditor_MinDmg")] ~= nil)
opened:field({ id = fieldIds[getText("IGUI_Name")] }).text = "Lucky axe"
opened:field({ id = fieldIds[getText("IGUI_invpanel_Condition")] }).text = "99"
opened:pressButton(opened._band.buttons[2])
check("Save writes a changed name through the game's setter", axe.saved.name == "Lucky axe", axe.saved.name)
check("a number past its bound is held to it", axe.saved.cond == 10, axe.saved.cond)
check("a field left as it was is not written back", axe.saved.weight == nil and axe.saved.MinDamage == nil and axe.saved.custom == nil)
-- food holds negatives: the registered min (0) is not a bound, only the item's own funcMin / funcMax
local hungerEd = { originalValue = -0.2, min = 0 }
check("a food field keeps its negative value", L.numberText(hungerEd, "-0.5") == "-0.5", L.numberText(hungerEd, "-0.5"))
check("a field with no bound of the item's is not held", L.numberText({ originalValue = 1, max = 1 }, "5") == "5")
check("the item's own max holds", L.numberText({ originalValue = 1, zedMax = 10 }, "99") == "10")
check("the card is gone after Save", opened._done == true)
local axe2 = item()
opened = nil
FC.open = function(spec) opened = realOpen(spec); return opened end
ISItemEditorUI.OpenPanel(PLAYER, axe2)
FC.open = realOpen
opened:field({ id = fieldIds[getText("IGUI_Name")] }).text = "nope"
opened:pressButton(opened._band.buttons[1])
check("Cancel writes nothing", next(axe2.saved) == nil)
SAFE = true
VAN_EDITOR = 0
ISItemEditorUI.OpenPanel(PLAYER, item())
check("safe mode: the game's window", VAN_EDITOR == 1)
SAFE = nil

-- ===========================================================================================
-- C17 KICKED OR DISCONNECTED: the desk screen
-- ===========================================================================================
print("-- C17 left screen")
local CM, M, A2 = ZeD.CommunityCards, ZeD.Community, ZeD.Admin
TEXT.UI_OnConnectFailed_Banned = TEXT.UI_OnConnectFailed_Banned or "You are banned from this server."
TEXT.UI_Policy_KickReason = TEXT.UI_Policy_KickReason or "You have been kicked from this server for the following reason: %1"
check("a ban's words read as a ban", LS.isBan(getText("UI_OnConnectFailed_BannedReason", "griefing")) or LS.isBan("You were banned"))
check("a kick's do not", not LS.isBan(getText("UI_Policy_KickReason", "afk")))
local shown = nil
local realShow = LS.show
LS.show = function(info) shown = info; return true end
local notes = 0
local realNote = CM._P.showNote
CM._P.showNote = function() notes = notes + 1 end
A2.leave = { kind = "ban", appeal = "discord.gg/knox" }
CM.onDisconnect("lua-force-disconnect")
check("a ban that left: ZeD's screen, the appeal on it, no note over the game's", shown and shown.kind == "ban" and shown.appeal == "discord.gg/knox" and notes == 0)
shown = nil
CM.onDisconnect("Connection to server lost")
check("a lost server: ZeD's screen with no kind", shown and shown.kind == nil and shown.appeal == nil)
local head, below = LS.lines({ kind = "ban", appeal = "x" })
check("a ban's lines: the head and the appeal", head == ZeD.tr("UI_ZeD_Left_Banned") and #below == 1)
head, below = LS.lines({ kind = "kick", appeal = "x" })
check("a kick's: no appeal line", head == ZeD.tr("UI_ZeD_Left_Kicked") and #below == 0)
LS.show = realShow
CM._P.showNote = realNote
-- the screen itself, at each size
local exits = 0
ISServerDisconnectUI = { instance = { hidden = false, setVisible = function(self, v) self.hidden = not v end, onToMainMenu = function() exits = exits + 1 end, onToDesktop = function() exits = exits + 10 end } }
function getTextManager() return { getFontHeight = function() return 20 end, MeasureStringX = function(_, f, s) return #tostring(s) * 9 end } end
for _, prof in ipairs({ { 1280, 800, 0.75 }, { 1920, 1080, 1 }, { 3840, 2160, 2 } }) do
    coreOf(prof[1], prof[2])
    ZEDQA_ROOT = prof[3]
    ZeD.applyTheme("dark", "orange", "small")
    LS.desk, LS.win = nil, nil
    check("the screen goes up at " .. prof[1], LS.show({ reason = "You have been kicked from this server for the following reason: afk", kind = "kick" }) == true)
    check("the game's screen is out of sight", ISServerDisconnectUI.instance.hidden == true)
    local w = LS.win
    w:build()
    draws(w)
    local slotScreenY = w.y + w._slot.y
    local medH = ZeD.TM:getFontHeight(UIFont.Medium)
    check("the slot sits where the engine writes at " .. prof[1], slotScreenY <= prof[2] / 2 and slotScreenY + w._slot.h >= prof[2] / 2 + medH, slotScreenY .. " / " .. prof[2] / 2)
    check("the window is centered at " .. prof[1], math.abs(w.x + w.width / 2 - prof[1] / 2) <= 1)
    check("the window is on screen at " .. prof[1], w.y >= 0 and w.y + w.height <= prof[2] and w.width <= prof[1])
end
local w = LS.win
local ex = nil
for _, s in ipairs(w._specs) do if s.id == "exit" then ex = s end end
check("Exit to menu is the band's main button", ex ~= nil and ex.variant == "primary")
ex.fn()
check("Exit is the game's own call", exits == 1)
w:joyB()
check("B goes to Quit without quitting", w.focusId == "quit" and exits == 1)
-- a draw that fails gives the game's screen back
local realPre = ZeD_MMWindow.prerender
ZeD_MMWindow.prerender = function() error("a broken draw") end
local realLog = ZeD.logOnce
ZeD.logOnce = function() end
w:prerender()
ZeD_MMWindow.prerender, ZeD.logOnce = realPre, realLog
check("a failed draw: the game's own screen comes back", LS.desk == nil and ISServerDisconnectUI.instance.hidden == false)
SAFE = true
check("safe mode: the game's own screen", LS.show({ reason = "x" }) == false)
SAFE = nil

print("mp_leftovers_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed == 0 and 0 or 1)
