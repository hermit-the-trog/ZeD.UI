-- ZeDUI/tools/qa/community_cards_sim.lua  (Nov 6 2026, QA): multiplayer Phase 5, community's cards with no game running. The real
-- Tokens, Tr, Atoms, Molecules, the protos, ZeD_ServerLink, ZeD_Community, ZeD_TicketCards, ZeD_AdminCards, ZeD_CommunityCards, ServerTab,
-- AdminTab and ZeD_Chat, on Lua 5.1 stubs of a panel, a window, text measures from the fonts' own sizes, and the focus manager, with the
-- game's own words read from its install where it is there. It draws every state of mp_community_cards.lua at the Deck and 720 sizes
-- (root 0.75), 1080p and 4K, Normal and Large text, mouse and pad; checks what drew (nothing past the drawer's edges, no field outside
-- its view, stops unique and whole, every grayed foot button saying why), then walks the flows: the Server tab, the rules card, Rules and
-- news (typing, moving, removing, adding, saving, a second admin, posting, pinning, deleting), the join window with mouse and pad at every
-- size, never trapping anyone, the ban and kick screens, chat (picking, Mute, Report, Player card, Teleport, the pad), a report on its
-- ticket cards. The last block runs the real FocusManager against the join window: its Y, a claim, the right stick. It proves the logic
-- and the sums. What it cannot prove is what the engine does: the text box, the keyboard, focus landing, real font widths, the window's
-- chrome.
-- This file's first half is claim_cards_sim.lua's harness.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/community_cards_sim.lua
-- It prints FAIL lines and a last line "community_cards_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]community_cards_sim%.lua$", "")

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
-- (Organisms.lua's placeSelf, Nov 11 2026: a window that places itself keeps a drag or a saved place; copied as is)
function ZeD_Window:placeSelf(x, y, l, t, sw, sh)
    local last = self._selfPlace
    local nx, ny = self:getX(), self:getY()
    if last and (nx ~= last.x or ny ~= last.y) then self._placeKept = true end
    if self._placeKept then
        x = math.max(l, math.min(nx, l + sw - self:getWidth()))
        y = math.max(t, math.min(ny, t + sh - self:getHeight()))
    end
    if nx ~= x then self:setX(x) end
    if ny ~= y then self:setY(y) end
    if not last then last = {}; self._selfPlace = last end
    last.x, last.y = self:getX(), self:getY()
end
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

ZEDQA_CARDS_SIM = true
local Q = assert(loadfile(ROOT .. "ZeDUI/tools/qa/mp_community_cards.lua"))()

-- the stub panel: every draw is checked against the drawer ---------------------------------
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

local WINS = { server = { _playerObj = PLAYER, playerNum = 0 }, admin = { _playerObj = PLAYER, playerNum = 0 } }
local function stOf(tab)
    return (tab == "server") and WINS.server._serverTab or WINS.admin._adminTab
end

-- ZEDQA_SVG=<folder>: each state of a profile named in ZEDQA_SVG_ONLY is written as a picture, to read against the mockup
ZEDQA_SVG = os.getenv and os.getenv("ZEDQA_SVG")
local function esc(s) return (string.gsub(string.gsub(string.gsub(s, "&", "&amp;"), "<", "&lt;"), ">", "&gt;")) end
local function hex(c) return string.format("#%02x%02x%02x", math.floor(c.r * 255), math.floor(c.g * 255), math.floor(c.b * 255)) end
local function writeSvg(panel, name)
    local out = { string.format('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" font-family="Fira Sans, Segoe UI, sans-serif">', panel.w, panel.h) }
    local T = ZeD.T
    out[#out + 1] = string.format('<rect width="%d" height="%d" fill="%s"/>', panel.w, panel.h, hex(T.base))
    local n = 0
    for _, o in ipairs(panel.ops) do
        local clip = ""
        if o.clip then
            n = n + 1
            out[#out + 1] = string.format('<clipPath id="%s%d"><rect x="%d" y="%d" width="%d" height="%d"/></clipPath>', name, n, o.clip.x, o.clip.y, o.clip.w, o.clip.h)
            clip = string.format(' clip-path="url(#%s%d)"', name, n)
        end
        if o.k == "r" then
            out[#out + 1] = string.format('<rect x="%g" y="%g" width="%g" height="%g" fill="%s" fill-opacity="%.2f"%s/>', o.x, o.y, o.w, o.h, hex(o), o.a or 1, clip)
        elseif o.k == "b" then
            out[#out + 1] = string.format('<rect x="%g" y="%g" width="%g" height="%g" fill="none" stroke="%s" stroke-opacity="%.2f"%s/>', o.x, o.y, o.w, o.h, hex(o), o.a or 1, clip)
        else
            local px = math.ceil(fontPx(o.font) * T.root)
            local mono = o.font == T.fontF1 or o.font == T.fontF3
            out[#out + 1] = string.format('<text x="%g" y="%g" font-size="%d" fill="%s" fill-opacity="%.2f"%s%s>%s</text>', o.x, o.y + px, px, hex(o), o.a or 1,
                mono and ' font-family="Fira Mono, Consolas, monospace"' or "", clip, esc(o.s))
        end
    end
    for _, c in ipairs(panel.kids) do
        if c.visible then
            local text = c:getText()
            out[#out + 1] = string.format('<text x="%g" y="%g" font-size="%d" fill="#888">%s</text>', c.x + 6, c.y + 16, 12, esc(text ~= "" and text or (c.placeholder or "")))
        end
    end
    out[#out + 1] = "</svg>"
    local f = assert(io.open(ZEDQA_SVG .. "/" .. name .. ".svg", "wb"))
    f:write(table.concat(out, string.char(10)))
    f:close()
end

-- a frame of a tab, then its children as the engine would draw them; returns the panel
local function frame(tab, panel, w, h)
    panel.texts = {}
    panel.ops = {}
    TABS[tab].render(panel, WINS[tab], 0, 0, w, h)
    for _, c in ipairs(panel.kids) do
        if c.visible then c:prerender() end
    end
    local t = stOf(tab) and stOf(tab).tk
    if t and t.qaPopNext then
        local k = t.qaPopNext
        t.qaPopNext = nil
        TC._D.openPopup(stOf(tab), t, k)
        panel.texts = {}
        panel.ops = {}
        TABS[tab].render(panel, WINS[tab], 0, 0, w, h)
    end
    return panel
end

local function stops(tab) return TABS[tab].buildFocusables(WINS[tab]) end

-- what must hold in a drawn frame
local function verify(name, tab, panel, w, h)
    for _, t in ipairs(panel.texts) do
        if t.x + t.w > w + 1 or t.x < -1 then
            check(name .. ": text inside the drawer", false, t.s .. " at " .. t.x .. "+" .. t.w .. " of " .. w)
        end
    end
    checks = checks + 1
    local list = stops(tab)
    local seen = {}
    for _, e in ipairs(list) do
        check(name .. ": a stop has an id", type(e.id) == "string", tostring(e.id))
        check(name .. ": stop unique " .. tostring(e.id), not seen[e.id])
        seen[e.id] = true
        check(name .. ": stop size " .. tostring(e.id), type(e.x) == "number" and type(e.y) == "number" and (e.w or 0) > 0 and (e.h or 0) > 0)
        check(name .. ": stop inside the width " .. tostring(e.id), e.x >= -1 and e.x + e.w <= w + 1, e.x .. "+" .. tostring(e.w))
    end
    local st = stOf(tab)
    local t = st and st.tk
    if st and st.card then
        check(name .. ": card has stops", #list > 0)
        check(name .. ": every stop answers to B", (function()
            for _, e in ipairs(list) do if not e.onCancel then return false end end
            return true
        end)())
        check(name .. ": a card leaves room to read", (t.csh or 0) >= ZeD.T.px(120), t.csh)
        for _, r in ipairs(t.footRects or {}) do
            check(name .. ": foot button inside", r.x >= 0 and r.x + r.w <= w + 1 and r.y + r.h <= h + 1, r.b.id)
            if r.b.disabled then check(name .. ": grayed " .. r.b.id .. " says why", type(r.b.why) == "string" and r.b.why ~= "") end
        end
        -- no two foot buttons on top of each other
        local rects = t.footRects or {}
        for i = 1, #rects do
            for j = i + 1, #rects do
                local a, b = rects[i], rects[j]
                check(name .. ": foot buttons apart", a.x + a.w <= b.x or b.x + b.w <= a.x or a.y + a.h <= b.y or b.y + b.h <= a.y, a.b.id .. "/" .. b.b.id)
            end
        end
    end
    for _, c in ipairs(panel.kids) do
        if c.visible then
            local sy, sh
            if st.card then sy, sh = t.csy, t.csh else sy, sh = t.sy, t.sh end
            check(name .. ": a text box whole in its view", c.y >= sy and c.y + c.height <= sy + sh, c.y .. "+" .. c.height .. " in " .. sy .. "+" .. sh)
        end
    end
    return list
end

local PROFILES = {
    { name = "720 Normal", root = 0.75, size = "small", w = 360, h = 500 },
    { name = "720 Large", root = 0.75, size = "large", w = 414, h = 500 },
    { name = "Deck Normal", root = 0.75, size = "small", w = 360, h = 560 },
    { name = "Deck Large", root = 0.75, size = "large", w = 414, h = 560 },
    { name = "1080 Normal", root = 1, size = "small", w = 480, h = 800 },
    { name = "4K 1.75", root = 1.75, size = "small", w = 840, h = 1500 },
    { name = "4K Large", root = 1.75, size = "large", w = 966, h = 1500 },
    -- (no real window is this narrow: it stands in for a language with longer words, where the chips and the foot must wrap)
    { name = "Narrow", root = 1, size = "large", w = 300, h = 560 },
}
local SCREENS = {
    { name = "Deck Normal", root = 0.75, size = "small", sw = 1280, sh = 800 },
    { name = "Deck Large", root = 0.75, size = "large", sw = 1280, sh = 800 },
    { name = "720 Normal", root = 0.75, size = "small", sw = 1280, sh = 720 },
    { name = "720 Large", root = 0.75, size = "large", sw = 1280, sh = 720 },
    { name = "1080 Normal", root = 1, size = "small", sw = 1920, sh = 1080 },
    { name = "1080 Large", root = 1, size = "large", sw = 1920, sh = 1080 },
    { name = "4K 1.75", root = 1.75, size = "small", sw = 3840, sh = 2160 },
    { name = "4K Large", root = 1.75, size = "large", sw = 3840, sh = 2160 },
}

-- every state ----------------------------------------------------------------------------
S.present, S.staff, S.admin = true, true, true
-- (one drawing first, so the tabs have their state)
local base = newPanel(480, 800)
frame("server", base, 480, 800)
frame("admin", base, 480, 800)
local states = Q.bind(CM, M, TC, AC, A2, S)
check("states to walk", #states >= 36, #states)

function ZeDQA_noop() end
for _, prof in ipairs(PROFILES) do
    ZEDQA_ROOT = prof.root
    ZEDQA_LARGE = prof.size == "large"
    ZeD.applyTheme("dark", "orange", prof.size)
    local panels = { server = newPanel(prof.w, prof.h), admin = newPanel(prof.w, prof.h) }
    -- (each profile its own drawer, and so its own text boxes)
    WINS.server._tkFields, WINS.admin._tkFields = nil, nil
    for _, s in ipairs(states) do
        for _, pad in ipairs({ false, true }) do
            local name = prof.name .. (pad and " pad " or " mouse ") .. s.name
            FOCUS.pad = pad
            FOCUS.id, FOCUS.el, FOCUS.win = nil, nil, nil
            local win = WINS[s.tab]
            local st = stOf(s.tab)
            nowMs = nowMs + 20000
            Q.typed = nil
            TC.qaLink = nil
            s.reset(win, st)
            s.run(win, st)
            local p = panels[s.tab]
            WINS[s.tab]._tkFields = WINS[s.tab]._tkFields
            local ok, err = pcall(function()
                frame(s.tab, p, prof.w, prof.h)
                if Q.typed then CM.qaType(win, Q.typed[1], Q.typed[2]) end
                frame(s.tab, p, prof.w, prof.h)
                local list = verify(name, s.tab, p, prof.w, prof.h)
                if string.find(s.name, "confirm", 1, true) then check(name .. ": the confirm stands", st.tk.confirm ~= nil) end
                -- a box half under a fold must not show: a child is not cut by the stencil
                local t = st.tk
                if st.card and t.scroll.visible then
                    for i = 1, 8 do
                        t.scroll:setScrollPos(i / 8)
                        frame(s.tab, p, prof.w, prof.h)
                        frame(s.tab, p, prof.w, prof.h)
                        verify(name .. " scrolled", s.tab, p, prof.w, prof.h)
                    end
                    t.scroll:setScrollPos(0)
                    frame(s.tab, p, prof.w, prof.h)
                end
                if ZEDQA_SVG and not pad and (os.getenv("ZEDQA_SVG_ONLY") or "") == prof.name then writeSvg(p, s.name) end
                -- each stop under the controller: its mark draws, and the card's band has the reason for a gray one
                if pad then
                    for _, e in ipairs(list) do
                        FOCUS.id, FOCUS.el, FOCUS.win = e.id, e, WINS[s.tab]
                        frame(s.tab, p, prof.w, prof.h)
                    end
                    FOCUS.id, FOCUS.el, FOCUS.win = nil, nil, nil
                end
            end)
            check(name .. ": draws", ok, err)
        end
    end
    -- one flow per tab with the taller words: what is typed in a field grows the field, and nothing scrolls in it
end
FOCUS.pad = false
ZEDQA_ROOT = 1
ZEDQA_LARGE = false
ZeD.applyTheme("dark", "orange", "small")

-- the flows ---------------------------------------------------------------------------------
local WORDS = ZeD.tr
nowMs = 1793913240000
M.qaHold, M.qaLink, TC.qaHold, TC.qaLink, A2.qaHold, A2.qaLink, A2.qaCaps = nil, nil, nil, nil, nil, nil, nil
S.present, S.forceOff, S.cm, S.staff, S.admin, S.adm = true, nil, true, false, false, true
ZEDQA_CAPS = { [Cm.CAP_RULES] = true, [Cm.CAP_NEWS] = true, TeleportToPlayer = true, CanSeePlayersStats = true, RolesRead = true, AnswerTickets = true }

local W, H = 480, 800
local panel = newPanel(W, H)
FOCUS.pad = false
ZEDQA_ROOT, ZEDQA_LARGE = 1, false
ZeD.applyTheme("dark", "orange", "small")
local curTab = "server"
local win, st = WINS.server, stOf("server")
local t = TC.qaState(st)
local function useTab(tab)
    curTab = tab
    win, st = WINS[tab], stOf(tab)
    t = TC.qaState(st)
end
local function reset()
    for _, tab in ipairs({ "server", "admin" }) do
        local s0 = stOf(tab)
        s0.card = nil
        local t0 = TC.qaState(s0)
        t0.confirm, t0.busy, t0.flashText, t0.items = nil, nil, nil, nil
        t0.scroll:setScrollPos(0)
        s0.scroll:setScrollPos(0)
        WINS[tab]._tkFields = nil
    end
    panel = newPanel(W, H)
    CLIENT = {}
end
local function view(over)
    local v = Q.view(over)
    M.setView(v)
    return v
end
local function draw() frame(curTab, panel, W, H) end
local function tick(ms)
    nowMs = nowMs + (ms or 1100)
    for _, fn in ipairs(EVENTS.OnTick.list) do fn() end
end
local function stopOf(id)
    for _, e in ipairs(stops(curTab)) do if e.id == id then return e end end
    return nil
end
local function press(id)
    draw()
    draw()
    local e = stopOf(id)
    check("the stop is there: " .. id, e ~= nil)
    if e then e.onActivate(win) end
    draw()
    return e
end
local function click(id)
    draw()
    draw()
    local e = stopOf(id)
    check("clickable: " .. id, e ~= nil)
    -- (a foot stop is said to lie under the list: the rect is where it draws)
    for _, r in ipairs(t.footRects or {}) do
        if "tk:" .. r.b.id == id then e = { x = r.x, y = r.y } end
    end
    if e then TABS[curTab].onClick(win, e.x + 1, e.y + 1) end
    draw()
end
local function field(key) return win._tkFields and win._tkFields[key] end
local function typeIn(key, text)
    check("the field is there: " .. key, field(key) ~= nil)
    if field(key) then field(key)._entry:setText(text) end
    draw()
end
local function footOf(id)
    for _, r in ipairs(t.footRects or {}) do if r.b.id == id then return r.b end end
    return nil
end
local function textDrawn(s, p)
    local parts = {}
    for _, x in ipairs((p or panel).texts) do parts[#parts + 1] = x.s end
    return string.find(table.concat(parts, " "), s, 1, true) ~= nil
end
local function lastCmd(c)
    for i = #CLIENT, 1, -1 do if CLIENT[i].c == c then return CLIENT[i].a end end
    return nil
end
local function ack(c, extra)
    local a = lastCmd(c)
    check("the command went: " .. c, a ~= nil)
    local r = { ok = true, rid = a and a.rid }
    for k, v in pairs(extra or {}) do r[k] = v end
    S.routes["ZeDT"]("t_ack", r)
    draw()
end

-- the Server tab -----------------------------------------------------------------------------
do
    reset()
    useTab("server")
    view()
    draw()
    draw()
    check("the message of the day shows", textDrawn("Welcome to Knox Survivors"))
    check("The rules row", textDrawn(WORDS("UI_ZeD_Cm_Rules")) and textDrawn("5 rules | changed"))
    check("News with its count", textDrawn(WORDS("UI_ZeD_Cm_News")))
    check("pinned first", textDrawn("PINNED"))
    local ys = {}
    for _, x in ipairs(panel.texts) do
        if string.find(x.s, "Trading post Saturday at", 1, true) then ys.pin = ys.pin or x.y end
        if string.find(x.s, "Vehicle claims", 1, true) then ys.plain = x.y end
        if string.find(x.s, "Tickets", 1, true) then ys.tk = ys.tk or x.y end
    end
    check("a pinned post above a plain one", ys.pin and ys.plain and ys.pin < ys.plain)
    check("News above Tickets", ys.tk and ys.plain and ys.plain < ys.tk, tostring(ys.plain) .. "/" .. tostring(ys.tk))
    check("every post is a stop to read", stopOf("srv:tk:cm:post:3") ~= nil and stopOf("srv:tk:cm:post:3").promptA == false)
    check("the appeal line is no stop to press", stopOf("srv:tk:cm:motd").promptA == false)
    click("srv:tk:cm:rules")
    check("the row opens the rules", st.card and st.card.kind == "cmrules")
    check("the rules show as on joining", textDrawn("Be decent in chat") and textDrawn(WORDS("UI_ZeD_Cm_WrongHead")))
    check("the appeal line is text", textDrawn("discord.gg/knoxsurvivors"))
    check("no NEW here: this is not the join screen", not textDrawn(WORDS("UI_ZeD_Cm_New")))
    check("no foot", #(t.footRects or {}) == 0)
    M.view = nil
    M.bump()
    draw()
    draw()
    check("the server part gone: the card goes back", st.card == nil)
    check("a server without the part: no message, no rules, no news", not textDrawn("Welcome to Knox") and not textDrawn(WORDS("UI_ZeD_Cm_News")))
    check("nothing to reach", stopOf("srv:tk:cm:rules") == nil)
    S.cm = false
    view()
    draw()
    check("an older server part: the same", M.live() == false and not textDrawn("Welcome to Knox"))
    S.cm = true
end

-- Rules and news -----------------------------------------------------------------------------
do
    reset()
    useTab("admin")
    view()
    draw()
    draw()
    check("the Admin tab has the row", stopOf("adm:tk:sum:cmedit") ~= nil)
    click("adm:tk:sum:cmedit")
    local card = st.card
    check("the card opens", card and card.kind == "cmedit")
    draw()
    check("nothing to save yet", footOf("rsave") and footOf("rsave").disabled and footOf("rsave").why == WORDS("UI_ZeD_Cm_NothingToSave"))
    check("the foot says Saved", textDrawn(WORDS("UI_ZeD_Cm_Saved")))
    typeIn("cm:motd", "New words")
    check("Save is ready", footOf("rsave") and not footOf("rsave").disabled)
    check("the foot says not saved", textDrawn(WORDS("UI_ZeD_Cm_NotSaved")))
    check("X is Save", stopOf("tk:f:cm:motd").promptX == WORDS("UI_ZeD_Cm_Save"))
    -- move
    press("tk:cmdn:cm:r1")
    check("a rule moves down", card.rows[2].id == 1 and card.rows[1].id == 2)
    local soon = FOCUS.soon[#FOCUS.soon]
    check("focus stays on the key", soon and soon.pred({ id = "tk:cmdn:cm:r1" }))
    press("tk:cmup:cm:r1")
    check("and back", card.rows[1].id == 1)
    press("tk:cmup:cm:r3")
    check("the first rule's Up is gray and says why", (function()
        draw()
        local e = stopOf("tk:cmup:cm:r3")
        return e ~= nil
    end)())
    press("tk:cmdn:cm:r3")
    -- remove and add
    press("tk:cmrm:cm:r4")
    check("removed from the card", #card.rows == 4)
    draw()
    check("not gone until Save", M.view.rules.n == 5)
    press("tk:cmadd")
    check("a new row", #card.rows == 5 and card.rows[5].id == nil)
    draw()
    draw()
    check("empty: Save says which", footOf("rsave").disabled and footOf("rsave").why == WORDS("UI_ZeD_Cm_RuleEmpty", 5), footOf("rsave").why)
    local key = card.rows[5].key
    check("the new row has the caret", field(key) ~= nil and t.wantField == nil)
    typeIn(key, "No fires\nindoors")
    check("Save is ready again", not footOf("rsave").disabled)
    -- save
    CLIENT = {}
    click("tk:rsave")
    local a = lastCmd("m_save")
    check("Save sends it all", a and a.motd == "New words" and a.rules.n == 5 and a.base == 4)
    check("in the card's order, ids kept, a new one without", a.rules[1].id == 1 and a.rules[5].id == nil and a.rules[5].text == "No fires indoors")
    check("the ticks go with it", a.ask == true and a.reask == true)
    check("a press waits", t.busy == true)
    draw()
    check("no second press while it waits", footOf("rsave").disabled and footOf("rsave").why == WORDS("UI_ZeD_Tk_Busy"), footOf("rsave").why)
    ack("m_save", { base = 5, reasked = true })
    check("the answer", ZeD.Help.last == WORDS("UI_ZeD_Cm_SavedAsk"), ZeD.Help.last)
    -- the server's push: the rows take their ids
    local v = view({ motd = "New words", rules = { n = 5, { id = 1, text = Q.RULES[1], rev = 1 }, { id = 2, text = Q.RULES[2], rev = 2 }, { id = 3, text = Q.RULES[3], rev = 1 }, { id = 5, text = Q.RULES[5], rev = 1 }, { id = 6, text = "No fires indoors", rev = 3 } } })
    v.edit.base = 5
    draw()
    draw()
    check("the card takes the server's rows", card.rows[5].id == 6 and card.rows[5].key == "cm:r6" and card.base == 5)
    check("clean again", footOf("rsave").disabled)
    -- another admin saves while this card is clean, then while it is not
    local v2 = view({ motd = "From Bea", rules = v.rules })
    v2.edit.base, v2.edit.by = 6, "Bea"
    draw()
    draw()
    draw()
    check("clean: their words arrive", field("cm:motd"):getText() == "From Bea" and card.base == 6, field("cm:motd"):getText())
    typeIn("cm:motd", "Mine")
    local v3 = view({ motd = "Bea again", rules = v.rules })
    v3.edit.base = 7
    draw()
    draw()
    check("dirty: yours stay", field("cm:motd"):getText() == "Mine" and card.base == 6)
    CLIENT = {}
    click("tk:rsave")
    ack("m_save", { ok = false, err = "stale", base = 7, by = "Bea" })
    check("stale: the foot names who", textDrawn("Bea saved first"))
    check("the words stay", field("cm:motd"):getText() == "Mine")
    check("and the next press is on their copy", card.base == 7)
    nowMs = nowMs + 20000
    CLIENT = {}
    click("tk:rsave")
    check("Save again goes", lastCmd("m_save") and lastCmd("m_save").base == 7)
    ack("m_save", { base = 8 })
    local v4 = view({ motd = "Mine", rules = v.rules })
    v4.edit.base = 8
    draw()
    draw()
    check("the name goes with the save", not card.stale)
    -- ticks
    press("tk:cmask")
    check("Ask off", card.ask == false)
    draw()
    check("Ask again is gray and says why", (function()
        for _, it in ipairs(t.items) do
            if it.k == "atick" and it.c.id == "cmreask" then return it.c.disabled and it.c.why == WORDS("UI_ZeD_Cm_AskFirst") end
        end
        return false
    end)())
    press("tk:cmask")
    -- news
    check("Post is gray with nothing typed", (function()
        for _, it in ipairs(t.items) do
            if it.k == "aflow" then
                for _, c in ipairs(it.ctls) do if c.id == "cmpost" then return c.disabled and c.why == WORDS("UI_ZeD_Cm_WritePost") end end
            end
        end
        return false
    end)())
    typeIn("cm:post", "  Trading moved to Sunday  ")
    press("tk:cmpinnew")
    check("Pin it", card.pin == true)
    CLIENT = {}
    nowMs = nowMs + 20000
    press("tk:cmpost")
    check("posted at once, trimmed, pinned", lastCmd("m_post") and lastCmd("m_post").text == "Trading moved to Sunday" and lastCmd("m_post").pin == true)
    check("Save has not gone with it", lastCmd("m_save") == nil)
    ack("m_post", { id = 9 })
    check("the field empties", field("cm:post"):getText() == "")
    check("a pin is for one post", card.pin == false)
    check("said", ZeD.Help.last == WORDS("UI_ZeD_Cm_Posted"), ZeD.Help.last)
    nowMs = nowMs + 20000
    CLIENT = {}
    press("tk:cmpin:1")
    check("unpin", lastCmd("m_pin") and lastCmd("m_pin").id == 1 and lastCmd("m_pin").on == false)
    ack("m_pin")
    nowMs = nowMs + 20000
    CLIENT = {}
    press("tk:cmdel:1")
    check("Delete asks first, in the foot", t.confirm ~= nil and footOf("cmyes") ~= nil and footOf("cmno") ~= nil and lastCmd("m_del") == nil)
    check("the question", textDrawn(WORDS("UI_ZeD_Cm_DeleteAsk")))
    check("the pad lands on Keep it", FOCUS.soon[#FOCUS.soon].pred({ id = "tk:cmno" }))
    stopOf("tk:cmno").onCancel(win)
    draw()
    check("B keeps it", t.confirm == nil and footOf("rsave") ~= nil)
    press("tk:cmdel:1")
    click("tk:cmyes")
    check("Delete for good goes", lastCmd("m_del") and lastCmd("m_del").id == 1)
    check("the pad lands on the next post's Delete", FOCUS.soon[#FOCUS.soon].pred({ id = CM._P.afterPost(1) }) and string.sub(CM._P.afterPost(1), 1, 9) == "tk:cmdel:", CM._P.afterPost(1))
    check("the last post: the box to write one", CM._P.afterPost(12345) == "tk:f:cm:post")
    ack("m_del")
    -- the rights
    reset()
    view()
    ZEDQA_CAPS[Cm.CAP_RULES] = nil
    draw()
    draw()
    click("adm:tk:sum:cmedit")
    draw()
    check("a moderator: no Save", footOf("rsave") == nil)
    check("the rules to read, not to type", stopOf("tk:f:cm:motd") == nil and textDrawn("Be decent in chat"))
    check("and why", textDrawn(string.sub(A2.why(Cm.CAP_RULES), 1, 20)))
    check("news still works", stopOf("tk:f:cm:post") ~= nil)
    ZEDQA_CAPS[Cm.CAP_NEWS] = nil
    reset()
    view()
    draw()
    draw()
    local gray = stopOf("adm:tk:sum:cmedit")
    check("neither power: the row is gray and says why", gray and gray.tkWhy() == A2.why(Cm.CAP_NEWS), gray and gray.tkWhy())
    ZEDQA_CAPS[Cm.CAP_RULES], ZEDQA_CAPS[Cm.CAP_NEWS] = true, true
    S.cm = false
    reset()
    M.setView(nil)
    draw()
    draw()
    check("no server part: no row", stopOf("adm:tk:sum:cmedit") == nil)
    S.cm = true
end

-- the review's cases on Rules and news --------------------------------------------------------
do
    reset()
    useTab("admin")
    local v0 = view()
    draw()
    draw()
    click("adm:tk:sum:cmedit")
    local card = st.card
    draw()
    -- a key used once is never used again in this window: its box still holds what was typed
    press("tk:cmadd")
    draw()
    local k1 = card.rows[#card.rows].key
    typeIn(k1, "half a rule")
    TC.back(win, st)
    draw()
    draw()
    click("adm:tk:sum:cmedit")
    card = st.card
    draw()
    check("back out: the rule is gone", #card.rows == v0.rules.n)
    press("tk:cmadd")
    draw()
    draw()
    local k2 = card.rows[#card.rows].key
    check("Add a rule opens empty", k2 ~= k1 and field(k2) and field(k2):getText() == "", field(k2) and field(k2):getText())
    check("and Save says so", footOf("rsave").disabled and footOf("rsave").why == WORDS("UI_ZeD_Cm_RuleEmpty", #card.rows), footOf("rsave").why)
    press("tk:cmrm:" .. k2)
    -- typing nothing, another admin changes a rule and takes one away
    FOCUS.pad = false
    TC.back(win, st)
    draw()
    click("adm:tk:sum:cmedit")
    card = st.card
    draw()
    draw()
    local e = { n = 4 }
    for i = 1, 4 do e[i] = { id = v0.rules[i].id, text = v0.rules[i].text, rev = 1 } end
    e[1].text = "Reworded by Bea"
    local vb = view({ rules = e })
    vb.edit.base = card.base + 1
    vb.edit.by = "Bea"
    draw()
    draw()
    draw()
    check("an untouched card takes a changed rule", card.base == vb.edit.base and #card.rows == 4, card.base)
    check("the words are the new ones", field("cm:r" .. e[1].id):getText() == "Reworded by Bea", field("cm:r" .. e[1].id):getText())
    check("nothing to save", footOf("rsave").disabled and footOf("rsave").why == WORDS("UI_ZeD_Cm_NothingToSave"), footOf("rsave").why)
    check("and it says Saved", textDrawn(WORDS("UI_ZeD_Cm_Saved")) and not textDrawn(WORDS("UI_ZeD_Cm_NotSaved")))
    -- a tick changed is touching it
    press("tk:cmask")
    local vc = view({ rules = e, motd = "Newer" })
    vc.edit.base = card.base + 1
    draw()
    draw()
    check("a card you touched stays yours", card.base ~= vc.edit.base and textDrawn(WORDS("UI_ZeD_Cm_NotSaved")))
    press("tk:cmask")
    draw()
    draw()
    check("put back, it takes the new copy", card.base == vc.edit.base, card.base)
    -- the field that follows its seed has not been typed in
    local vd = view({ rules = e, motd = "Newer still" })
    vd.edit.base = card.base + 1
    draw()
    draw()
    draw()
    check("the message moves with the rest", card.base == vd.edit.base and field("cm:motd"):getText() == "Newer still", field("cm:motd"):getText())
    -- a pad's Add puts no caret in the box: A does that, with the pad keyboard
    FOCUS.pad = true
    press("tk:cmadd")
    check("the pad: no caret", t.wantField == nil)
    check("the pad lands on the new box", FOCUS.soon[#FOCUS.soon].pred({ id = "tk:f:" .. card.rows[#card.rows].key }))
    FOCUS.pad = false
    press("tk:cmrm:" .. card.rows[#card.rows].key)
    -- frozen: community's own word
    local vf = view({ frozen = true })
    draw()
    draw()
    typeIn("cm:motd", "typed")
    check("frozen: Save says rules and news", footOf("rsave").why == WORDS("UI_ZeD_Cm_Frozen"), footOf("rsave").why)
    for _, it in ipairs(t.items) do
        if it.k == "aflow" then
            for _, c in ipairs(it.ctls) do
                if c.id == "cmpost" then check("frozen: Post says so too", c.why == WORDS("UI_ZeD_Cm_Frozen"), c.why) end
            end
        end
    end
    vf.frozen = nil
    -- the row's counts
    check("one of each", CM._P.counts({ rules = { n = 1 }, news = { n = 1 } }) == "1 rule, 1 post", CM._P.counts({ rules = { n = 1 }, news = { n = 1 } }))
    check("several", CM._P.counts({ rules = { n = 5 }, news = { n = 3 } }) == "5 rules, 3 posts")
    check("none", CM._P.counts({ rules = { n = 0 }, news = { n = 0 } }) == "0 rules, 0 posts")
    reset()
end

-- the join window at every size, mouse and pad ------------------------------------------------
local function coreOf(sw, sh)
    getCore = function() return { getOptionFontSizeReal = function() return 1 end, getScreenWidth = function() return sw end, getScreenHeight = function() return sh end } end
end
local function joinFrame(w0)
    -- the panel calls of a real window, on this stub
    local p = newPanel(w0.width, w0.height)
    for _, k in ipairs({ "drawRect", "drawRectBorder", "drawText", "drawTexture", "drawTextureScaled", "drawTextureScaledAspect", "setStencilRect", "clearStencilRect", "getMouseX", "getMouseY", "getAbsoluteX", "getAbsoluteY" }) do w0[k] = p[k] end
    w0.texts, w0.ops = {}, {}
    w0.mx, w0.my = -1, -1
    w0:update()
    w0:prerender()
    return w0
end
do
    reset()
    useTab("server")
    for _, sc in ipairs(SCREENS) do
        ZEDQA_ROOT, ZEDQA_LARGE = sc.root, sc.size == "large"
        ZeD.applyTheme("dark", "orange", sc.size)
        coreOf(sc.sw, sc.sh)
        for _, over in ipairs({ {}, { rules = Q.manyRules(30, true), motd = string.rep("A long message of the day. ", 22) } }) do
            for _, pad in ipairs({ false, true }) do
                local name = "join " .. sc.name .. (pad and " pad" or " mouse") .. (next(over) and " long" or "")
                view(over)
                FOCUS.pad = pad
                JoypadState.players = pad and { {} } or {}
                KEYS_ON = true
                CM.joinWin = nil
                M.joinScreen()
                local w0 = CM.joinWin
                check(name .. ": up", w0 ~= nil and w0.inUI == true and w0.cover and w0.cover.inUI == true)
                check(name .. ": on top", w0.onTop == true and w0.cover.onTop == true)
                check(name .. ": keys held", KEYS_ON == false)
                check(name .. ": the pad's focus is here", (not pad) or JoypadState.players[1].focus == w0)
                joinFrame(w0)
                joinFrame(w0)
                check(name .. ": fits the screen", w0.x >= 0 and w0.y >= 0 and w0.x + w0.width <= sc.sw and w0.y + w0.height <= sc.sh, w0.width .. "x" .. w0.height)
                for _, x in ipairs(w0.texts) do
                    check(name .. ": inside", x.x >= -1 and x.x + x.w <= w0.width + 1, x.s)
                end
                local t0 = TC.qaState(w0.joinSt)
                check(name .. ": no back bar", t0.barRects.back == nil)
                check(name .. ": both answers", #t0.footRects == 2 and t0.footRects[1].b.id == "leave" and t0.footRects[2].b.id == "agree")
                check(name .. ": the default is last", t0.footRects[2].b.variant == "primary")
                for _, r in ipairs(t0.footRects) do
                    check(name .. ": answers inside", r.x >= 0 and r.x + r.w <= w0.width + 1 and r.y + r.h <= w0.height + 1)
                end
                check(name .. ": room to read", (t0.csh or 0) >= ZeD.T.px(120), t0.csh)
                check(name .. ": the first rule shows", textDrawn(next(over) and "A long rule" or "Be decent", w0))
                check(name .. ": the help fits its line", ZeD.TM:MeasureStringX(ZeD.T.fontF2, ZeD.tr("UI_ZeD_Cm_HelpJoin")) <= w0.width - 2 * ZeD.T.px(10))
                if not next(over) then
                    check(name .. ": NEW on the changed rule", textDrawn(ZeD.tr("UI_ZeD_Cm_New"), w0))
                    check(name .. ": the foot says which", textDrawn(ZeD.tr("UI_ZeD_Cm_NewOne", 2), w0))
                end
                if not next(over) then check(name .. ": the appeal line", textDrawn("discord.gg/knoxsurvivors", w0)) end
                w0:finish()
                check(name .. ": gone", CM.joinWin == nil and w0.inUI == false and w0.cover.inUI == false and KEYS_ON == true)
                check(name .. ": the pad let go", (not pad) or JoypadState.players[1].focus == nil)
            end
        end
    end
    ZEDQA_ROOT, ZEDQA_LARGE = 1, false
    ZeD.applyTheme("dark", "orange", "small")
    coreOf(1920, 1080)
    FOCUS.pad = false

    -- the mouse
    view()
    CLIENT, LEFT = {}, 0
    JoypadState.players = {}
    M.joinScreen()
    local w0 = CM.joinWin
    joinFrame(w0)
    local t0 = TC.qaState(w0.joinSt)
    w0:onMouseDown(t0.footRects[2].x + 1, t0.footRects[2].y + 1)
    check("I agree closes it at once", CM.joinWin == nil and KEYS_ON == true)
    check("and tells the server what was on screen", lastCmd("m_agree") and lastCmd("m_agree").rev == 2)
    check("it does not wait for an answer", LEFT == 0)
    S.routes["ZeDT"]("t_ack", { ok = false, err = "frozen", rid = lastCmd("m_agree").rid })
    check("a refusal after that changes nothing", CM.joinWin == nil)

    CLIENT = {}
    M.joinScreen()
    w0 = CM.joinWin
    joinFrame(w0)
    t0 = TC.qaState(w0.joinSt)
    w0:onMouseDown(t0.footRects[1].x + 1, t0.footRects[1].y + 1)
    check("Leave disconnects", LEFT == 1 and CM.joinWin == nil and lastCmd("m_agree") == nil)
    check("and the keys are back for the game's own screen", KEYS_ON == true)

    -- agreeing to the words on screen
    CLIENT = {}
    M.joinScreen()
    w0 = CM.joinWin
    joinFrame(w0)
    local v2 = Q.view()
    v2.rev = 3
    M.setView(v2)
    joinFrame(w0)
    t0 = TC.qaState(w0.joinSt)
    w0:onMouseDown(t0.footRects[2].x + 1, t0.footRects[2].y + 1)
    check("a push while reading: the rev on screen is the one agreed", lastCmd("m_agree").rev == 2)

    -- the pad
    view({ rules = Q.manyRules(30, true) })
    CLIENT, LEFT = {}, 0
    JoypadState.players = { {} }
    FOCUS.pad = true
    M.joinScreen()
    w0 = CM.joinWin
    joinFrame(w0)
    joinFrame(w0)
    t0 = TC.qaState(w0.joinSt)
    check("the pad lands on I agree", w0._padId == "tk:agree")
    check("a long card scrolls", t0.scroll.visible == true)
    w0:onJoypadDirDown()
    joinFrame(w0)
    check("Down scrolls and focus stays", t0.scroll.scrollPos > 0 and w0._padId == "tk:agree")
    local p1 = t0.scroll.scrollPos
    w0:onJoypadDirUp()
    check("Up scrolls back", t0.scroll.scrollPos < p1)
    w0:onJoypadDown(Joypad.BButton)
    check("B answers nothing", CM.joinWin == w0 and LEFT == 0)
    w0:onJoypadDirLeft()
    joinFrame(w0)
    check("Left: Leave", w0._padId == "tk:leave")
    w0:onJoypadDirRight()
    joinFrame(w0)
    check("Right: I agree", w0._padId == "tk:agree")
    check("the prompts are said", w0:getFooterPrompts() ~= nil)
    w0:onJoypadDown(Joypad.AButton)
    check("A: I agree", CM.joinWin == nil and lastCmd("m_agree") ~= nil)
    check("the pad is free", JoypadState.players[1].focus == nil)
    CLIENT = {}
    M.joinScreen()
    w0 = CM.joinWin
    joinFrame(w0)
    w0:onJoypadDirLeft()
    joinFrame(w0)
    w0:onJoypadDown(Joypad.AButton)
    check("A on Leave", LEFT == 1 and CM.joinWin == nil and lastCmd("m_agree") == nil)
    JoypadState.players = {}
    FOCUS.pad = false

    -- never a trap
    M.setView(nil)
    M.joinScreen()
    check("no view: no screen", CM.joinWin == nil and KEYS_ON == true)
    view()
    SAFE = "community"
    M.joinScreen()
    check("safe mode: no screen", CM.joinWin == nil and KEYS_ON == true)
    -- (Nov 7) asked in safe mode: the game's own yes/no box, since the server refuses every command until it is answered
    local modals = {}
    local realModal = ISModalDialog
    ISModalDialog = { new = function(_, x, y, w, h, text, yesno, target, onclick, pn)
        local m = { text = text, yesno = yesno, onclick = onclick, w = 400, h = 300, inUI = false, passW = w }
        function m.initialise() end
        function m.addToUIManager(self) self.inUI = true end
        function m.getWidth(self) return self.w end
        function m.getHeight(self) return self.h end
        function m.setX(self, v) self.x = v end
        function m.setY(self, v) self.y = v end
        modals[#modals + 1] = m
        return m
    end }
    view({ ask = true })
    CLIENT = {}
    M.joinScreen()
    local md1 = modals[1]
    check("safe mode and asked: the plain question instead", CM.joinWin == nil and md1 ~= nil and md1.yesno == true and md1.inUI)
    check("it holds every rule and the question", md1 and string.find(md1.text, "1. " .. Q.RULES[1], 1, true) ~= nil
        and string.find(md1.text, "UI_ZeD_Cm_SafeAsk", 1, true) == nil and string.find(md1.text, "\n", 1, true) ~= nil, md1 and md1.text)
    M.joinScreen()
    check("asked once", #modals == 1)
    md1.onclick(nil, { internal = "YES" })
    check("Yes agrees to these words", lastCmd("m_agree") ~= nil and lastCmd("m_agree").rev == 2)
    LEFT = 0
    M.joinScreen()
    modals[2].onclick(nil, { internal = "NO" })
    check("No leaves", LEFT == 1)
    view()
    M.joinScreen()
    check("not asked: no question", #modals == 2)
    -- a rule longer than a line is cut at its spaces, and a word longer than a line is cut too
    view({ ask = true, rules = { n = 1, { id = 1, rev = 1, text = string.rep("word ", 30) .. string.rep("x", 90) } } })
    M.joinScreen()
    local widest = 0
    for l in string.gmatch(modals[3].text .. "\n", "([^\n]*)\n") do widest = math.max(widest, #l) end
    check("the plain box stays narrow: no line past 70 characters", modals[3] and widest <= 70, widest)
    modals[3].onclick(nil, { internal = "YES" })
    -- (Nov 7 review) a long list on a short screen: the box is sized as the game sizes it (ISModalDialog.CalcSize, UIFont.Small)
    -- and must stay on screen at every resolution and text size, its rules scrolling, Yes and No in reach by mouse and pad
    local realFH, realMX = ZeD.TM.getFontHeight, ZeD.TM.MeasureStringX
    local function calc(text)
        local fh = ZeD.TM:getFontHeight(UIFont.Small)
        local n, wid = 0, 0
        for l in string.gmatch(text .. "\n", "([^\n]*)\n") do n = n + 1; wid = math.max(wid, ZeD.TM:MeasureStringX(UIFont.Small, l)) end
        return math.max(wid + 10, 232), 20 + n * fh + 20 + 25 + 10, n
    end
    local longRules = { n = 40 }
    for i = 1, 40 do longRules[i] = { id = i, rev = 1, text = "Rule " .. i .. ": " .. string.rep("keep the roads clear and the gates shut ", 3) } end
    local P = CM._P
    for _, scr in ipairs({ { 1280, 720 }, { 1280, 800 }, { 1920, 1080 }, { 3840, 2160 }, { 800, 600 } }) do
        for _, fh in ipairs({ 14, 19, 26 }) do
            local name = "safe box " .. scr[1] .. "x" .. scr[2] .. " small font " .. fh .. ": "
            coreOf(scr[1], scr[2])
            ZeD.TM.getFontHeight = function(self, font) if font == UIFont.Small then return fh end return realFH(self, font) end
            ZeD.TM.MeasureStringX = function(self, font, s) if font == UIFont.Small then return math.ceil(#tostring(s) * fh * 0.5) end return realMX(self, font, s) end
            local before = #modals
            view({ ask = true, rules = longRules })
            M.joinScreen()
            local md = modals[before + 1]
            check(name .. "asked", md ~= nil)
            if md then
                local w0, h, n0 = calc(md.text)
                local w = math.max(md.passW, w0)       -- (CalcSize: the width asked for, or the text's when wider; fixed from here)
                md.w, md.h = w, h
                check(name .. "the box fits the screen's height", h <= scr[2], h)
                check(name .. "and its width", w <= scr[1], w)
                local st = CM.safeState
                local full = table.concat(st.tail, "\n")
                check(name .. "the question and Yes/No always show", string.sub(md.text, -#full) == full)

                -- scrolled to the end by the wheel: the last rule shows, the box never grows
                local guard = 0
                local lastWords = string.sub(P.plainWrap("40. " .. longRules[40].text, st.n)[#P.plainWrap("40. " .. longRules[40].text, st.n)], 1, 10)
                local wSeen = 0
                while guard < 200 and not string.find(md.text, lastWords, 1, true) do
                    md.onMouseWheel(md, 1)
                    guard = guard + 1
                    wSeen = math.max(wSeen, (calc(md.text)))
                end
                check(name .. "the wheel reaches the last rule", string.find(md.text, lastWords, 1, true) ~= nil)
                check(name .. "no line scrolled in draws past the border", wSeen <= w, tostring(wSeen) .. " > " .. tostring(w))
                local _, h2 = calc(md.text)
                check(name .. "scrolling never grows the box", h2 == h, h2)
                for _ = 1, 100 do md.onJoypadDirUp(md) end
                check(name .. "the D-pad brings the first rule back", string.find(md.text, "1. " .. "Rule 1:", 1, true) ~= nil)
                md.onJoypadDirDown(md)
                if st.rows then check(name .. "the D-pad scrolls down", st.top > 1) end
                if scr[2] <= 800 then check(name .. "40 rules do not all fit a short screen: they scroll", st.rows ~= nil) end
                md.onclick(nil, { internal = "YES" })
                check(name .. "Yes still agrees", lastCmd("m_agree") ~= nil)
            end
        end
    end
    -- (outside review, Nov 7) short rules first and a wide one far down: the box takes its width when it opens, so it must already
    -- be as wide as that line, not only the lines showing then
    local narrowRules = { n = 40 }
    for i = 1, 40 do narrowRules[i] = { id = i, rev = 1, text = "Rule " .. i .. ": be kind" } end
    narrowRules[40].text = "Rule 40: " .. string.rep("keep the roads clear and the gates shut ", 3)
    for _, scr in ipairs({ { 1280, 720 }, { 1280, 800 }, { 800, 600 } }) do
        local fh = 19
        local name = "safe box, a wide rule far down, " .. scr[1] .. "x" .. scr[2] .. ": "
        coreOf(scr[1], scr[2])
        ZeD.TM.getFontHeight = function(self, font) if font == UIFont.Small then return fh end return realFH(self, font) end
        ZeD.TM.MeasureStringX = function(self, font, s) if font == UIFont.Small then return math.ceil(#tostring(s) * fh * 0.5) end return realMX(self, font, s) end
        local before = #modals
        view({ ask = true, rules = narrowRules })
        M.joinScreen()
        local md = modals[before + 1]
        local st = CM.safeState
        check(name .. "it scrolls", md ~= nil and st and st.rows ~= nil)
        if md and st and st.rows then
            local w0 = calc(md.text)
            local w = math.max(md.passW, w0)
            check(name .. "the wide rule is not showing when it opens", string.find(md.text, "Rule 40:", 1, true) == nil)
            local wSeen, guard = 0, 0
            while guard < 200 and st.top + st.rows - 1 < #st.body do
                md.onMouseWheel(md, 1)
                guard = guard + 1
                wSeen = math.max(wSeen, (calc(md.text)))
            end
            check(name .. "scrolled to it", string.find(md.text, "Rule 40:", 1, true) ~= nil)
            check(name .. "it stays inside the border it opened with", wSeen <= w, tostring(wSeen) .. " > " .. tostring(w))
            check(name .. "and the box still fits the screen", w <= scr[1] - 2 * P.SAFE_MARGIN, w)
            md.onclick(nil, { internal = "YES" })
        end
    end
    ZeD.TM.getFontHeight, ZeD.TM.MeasureStringX = realFH, realMX
    coreOf(1280, 800)
    ISModalDialog = realModal
    SAFE = nil
    M.joinScreen()
    w0 = CM.joinWin
    joinFrame(w0)
    local real = TC.renderCard
    TC.renderCard = function() error("it broke") end
    w0:prerender()
    TC.renderCard = real
    check("a draw that fails closes it", CM.joinWin == nil and KEYS_ON == true and w0.inUI == false)
    M.joinScreen()
    w0 = CM.joinWin
    CM.onDisconnect("Connection to server lost")
    check("the connection ending closes it", CM.joinWin == nil and KEYS_ON == true)
    M.joinScreen()
    local one = CM.joinWin
    M.joinScreen()
    check("never two", CM.joinWin == one)
    one:finish()

    -- a build that fails leaves nothing up
    local covers = {}
    local coverNew, winNew = ZeD_JoinCover.new, ZeD_JoinWindow.new
    ZeD_JoinCover.new = function(...)
        local c = coverNew(...)
        covers[#covers + 1] = c
        return c
    end
    ZeD_JoinWindow.new = function() error("a mod patched the window") end
    check("the build fails", not pcall(M.joinScreen))
    check("no window, no cover, the keys free", CM.joinWin == nil and #covers == 0 and KEYS_ON == true)
    ZeD_JoinWindow.new = winNew
    ZeD_JoinCover.new = coverNew

    -- the pad, whatever happens to it
    JoypadState.players = { {} }
    M.joinScreen()
    w0 = CM.joinWin
    local jd = JoypadState.players[1]
    local deathPanel = { isVisible = function() return true end }
    jd.focus = deathPanel
    joinFrame(w0)
    check("taken from it: the window takes the pad back", jd.focus == w0 and w0.joyfocus == jd and w0._padId == "tk:agree")
    w0:onJoypadDown(Joypad.AButton)
    check("and the answer gives it to whoever took it", CM.joinWin == nil and jd.focus == deathPanel, jd.focus)
    M.joinScreen()
    w0 = CM.joinWin
    jd.focus = { isVisible = function() return false end }
    joinFrame(w0)
    w0:finish()
    check("one that has gone since gets nothing", jd.focus == nil)
    JoypadState.players = {}
    M.joinScreen()
    w0 = CM.joinWin
    joinFrame(w0)
    check("no pad yet: no prompts", w0.joyfocus == nil and w0:getFooterPrompts() == nil)
    JoypadState.players = { {} }
    jd = JoypadState.players[1]
    joinFrame(w0)
    check("a pad that arrives late gets the window", jd.focus == w0 and w0.joyfocus == jd and w0:getFooterPrompts() ~= nil)
    w0:onJoypadDirLeft()
    joinFrame(w0)
    w0:onJoypadDown(Joypad.AButton)
    check("and can answer", CM.joinWin == nil)
    LEFT = 0
    M.joinScreen()
    w0 = CM.joinWin
    jd.inMainMenu = true
    local menu = { isVisible = function() return true end }
    jd.focus = menu
    joinFrame(w0)
    check("the game's pause menu keeps the pad", jd.focus == menu)
    jd.inMainMenu = nil
    jd.focus = nil
    joinFrame(w0)
    check("and back from it, the window has it", jd.focus == w0)
    w0:finish()
    -- the window the pad was in comes back
    FOCUS.win, FOCUS.claimed = "the Character window", nil
    local shown = { isVisible = function() return true end }
    FOCUS.win = shown
    M.joinScreen()
    w0 = CM.joinWin
    check("the window lets go of the pad for this", FOCUS.win == nil and w0.padBack == shown and jd.focus == w0)
    joinFrame(w0)
    w0:finish()
    check("and has it back at the end", FOCUS.claimed == shown)
    FOCUS.claimed = nil
    JoypadState.players = {}

    -- the model's own clock shows it once, on the hello that says so
    M.joined = nil
    CM.joinWin = nil
    M.onHello({ cm = Q.view({ ask = true }) })
    tick(10)
    check("the hello that asks shows the screen", CM.joinWin ~= nil)
    CM.joinWin:finish()
    M.onHello({ cm = Q.view({ ask = true }) })
    tick(10)
    check("a second hello does not", CM.joinWin == nil)
end

-- the ban and kick screens --------------------------------------------------------------------
do
    view()
    local shown = nil
    local base = A2.defaultLeave
    A2.defaultLeave = function(info) shown = info end
    A2.leaveScreen({ kind = "ban", reason = "griefing" })
    A2.defaultLeave = base
    check("the ban screen gets the appeal line", shown and shown.appeal == "discord.gg/knoxsurvivors")
    local lines = AC.leaveLines(shown)
    check("the reason and the line", #lines == 3 and string.find(lines[2], "griefing", 1, true) and string.find(lines[3], "discord.gg/knoxsurvivors", 1, true))
    shown = nil
    A2.defaultLeave = function(info) shown = info end
    A2.leaveScreen({ kind = "ban", reason = "griefing", appeal = "from the server" })
    A2.defaultLeave = base
    check("the server's own word first", shown.appeal == "from the server")
    M.setView(Q.view({ appeal = "" }))
    check("no appeal line: none shown", #AC.leaveLines({ kind = "kick", reason = "x", appeal = M.appeal() }) == 2)
    -- banned while being asked: the ban's screen, with nothing left to agree to
    view()
    M.joinScreen()
    check("up", CM.joinWin ~= nil)
    A2.defaultLeave = function(info) shown = info end
    A2.leaveScreen({ kind = "ban", reason = "griefing" })
    A2.defaultLeave = base
    check("a ban closes the join screen", CM.joinWin == nil and KEYS_ON == true)
    A2.leave = { kind = "ban" }
    M.joinScreen()
    check("and none goes up over it", CM.joinWin == nil)
    A2.leave = nil
    -- the game's disconnect screen
    view()
    local notes = 0
    local real = M.isRemoved
    local showNote = CM._P.showNote
    CM._P.showNote = function(a) notes = notes + 1; CM._last = a end
    A2.leave, A2.leaveAt = nil, nil
    CM.onDisconnect("Connection to server lost")
    check("a lost server: no appeal line", notes == 0)
    TEXT.UI_Policy_KickReason = TEXT.UI_Policy_KickReason or "You have been kicked from this server for the following reason:"
    CM.onDisconnect(TEXT.UI_Policy_KickReason .. " griefing")
    check("a kick: no appeal line (a ban's only: the director, Nov 7 2026)", notes == 0)
    A2.leave, A2.leaveAt = { kind = "ban", appeal = "kept with it" }, 5
    CM.onDisconnect("lua-force-disconnect")
    check("a ban that left: the appeal line under the game's words, and the screen's model cleared", notes == 1 and CM._last == "kept with it" and A2.leave == nil and A2.leaveAt == nil)
    CM._P.showNote = showNote
    M.isRemoved = real
    coreOf(1280, 720)
    ZEDQA_ROOT = 0.75
    ZeD.applyTheme("dark", "orange", "small")
    CM._P.showNote("discord.gg/knoxsurvivors")
    check("the note is drawn with no error", true)
    coreOf(1920, 1080)
    ZEDQA_ROOT = 1
    ZeD.applyTheme("dark", "orange", "small")
end

-- chat ---------------------------------------------------------------------------------------
local function msg(author, text, kind)
    return { getAuthor = function() return author end, getText = function() return text end, getDatetimeStr = function() return "9:" .. tostring(#Ch.lines + 10) end,
        getChat = function() return { getType = function() return kind or "say" end } end, isServerAlert = function() return kind == "server" end, isCustomColor = function() return false end }
end
local function chatWin(w0, h0)
    Ch.win = nil
    local cw = ZeD_ChatWindow:new(0, 0, w0, h0)
    cw:initialise()
    cw:instantiate()
    cw:createChildren()
    Ch.win = cw
    local p = newPanel(w0, h0)
    for _, k in ipairs({ "drawRect", "drawRectBorder", "drawText", "drawTexture", "drawTextureScaled", "drawTextureScaledAspect", "setStencilRect", "clearStencilRect", "getMouseX", "getMouseY", "getAbsoluteX", "getAbsoluteY" }) do cw[k] = p[k] end
    cw.ops = {}
    cw.mx, cw.my = -1, -1
    return cw
end
local function chatDraw(cw)
    cw.texts = {}
    cw:_drawBody()
    return cw
end
do
    S.cm, S.adm = true, true
    view()
    Ch.lines = {}
    Ch.myMutes, FILES["ZeD_chatmute.txt"] = nil, nil
    PLAYER.getSteamID = function() return 0 end
    ISChat.instance = nil
    for _, m in ipairs({ { "Kade_R", "anyone seen my truck? it was at the farm" }, { "mike_d", "lol nope" }, { "Rosa", "Kade, file a ticket and we'll look at the logs." },
        { "Aretha", "stuck behind the motel fence again" }, { "Mags_77", "who wants to run to the mall tomorrow" } }) do
        Ch.onMessage(msg(m[1], m[2]))
    end
    Ch.onMessage(msg(nil, "The server restarts at 4.", "server"))
    check("the lines arrive", #Ch.lines == 6)
    Ch.qaAdmin = false
    ZEDQA_CAPS.TeleportToPlayer, ZEDQA_CAPS.CanSeePlayersStats = true, true
    local cw = chatDraw(chatWin(440, 400))
    check("no line is picked", cw.picked == nil and textDrawn("lol nope", cw))
    local function rowOf(text)
        for _, h in ipairs(cw._rowHits or {}) do
            if h.ln.text == text then return h end
        end
        return nil
    end
    check("my own line is no pick", rowOf("stuck behind the motel fence again") == nil)
    check("a server line is no pick", rowOf("The server restarts at 4.") == nil)
    local row = rowOf("lol nope")
    check("a line with a sender is", row ~= nil)
    cw:onMouseDown(cw._linesRect.x + 2, row.y + 1)
    chatDraw(cw)
    check("a press picks it", cw.picked == row.ln)
    check("a player gets two buttons", cw._acts and #cw._acts == 2 and #cw._actHits == 2)
    check("the drawing's words", textDrawn(WORDS("UI_ZeD_Chat_Report"), cw) and textDrawn(WORDS("UI_ZeD_Chat_MuteYou"), cw))
    check("picked: what the buttons do", cw:getStatusLine() == WORDS("UI_ZeD_Chat_HelpMute"), cw:getStatusLine())
    cw.picked = nil
    chatDraw(cw)
    check("nothing picked, lines to pick: that you can", cw:getStatusLine() == WORDS("UI_ZeD_Chat_HelpPick"), cw:getStatusLine())
    check("it fits the line at the window's first size", ZeD.TM:MeasureStringX(ZeD.T.fontF2, WORDS("UI_ZeD_Chat_HelpPick")) <= cw.width - 2 * ZeD.T.px(10))
    cw:onMouseDown(cw._linesRect.x + 2, row.y + 1)
    chatDraw(cw)
    -- Mute
    local before = #CLIENT
    local unread = Ch.unreadN
    cw:onMouseDown(cw._actHits[2].x + 1, cw._actHits[2].y + 1)
    chatDraw(cw)
    check("muted, for you", Ch.mutedByMe("mike_d") and Ch.mutedByMe("MIKE_D"))
    check("nobody is told", #CLIENT == before)
    check("the line is a word now", textDrawn(WORDS("UI_ZeD_Chat_MutedByYou"), cw) and not textDrawn("lol nope", cw))
    check("the button turns to Unmute", textDrawn(WORDS("UI_ZeD_Chat_Unmute"), cw))
    check("the answer", cw:getStatusLine() == WORDS("UI_ZeD_Chat_MuteDone", "mike_d"), cw:getStatusLine())
    check("kept on this computer", FILES["ZeD_chatmute.txt"] == "10.0.0.5:16261|mike_d\n", FILES["ZeD_chatmute.txt"])
    Ch.myMutes = nil
    check("kept across a session", Ch.mutedByMe("mike_d"))
    local lastAt = Ch.lastLineAt
    nowMs = nowMs + 100
    Ch.onMessage(msg("mike_d", "you there?"))
    check("a muted line wakes nothing", Ch.lastLineAt == lastAt)
    check("and is kept for Unmute", Ch.lines[#Ch.lines].text == "you there?")
    chatDraw(cw)
    cw:onMouseDown(cw._actHits[2].x + 1, cw._actHits[2].y + 1)
    chatDraw(cw)
    check("Unmute gives the words back", textDrawn("lol nope", cw) and textDrawn("you there?", cw) and not Ch.mutedByMe("mike_d"))
    check("off the file", FILES["ZeD_chatmute.txt"] == "")
    -- the mute list is capped, and another server's stays
    FILES["ZeD_chatmute.txt"] = "1.1.1.1:1|other\n"
    Ch.myMutes = nil
    for i = 1, 205 do Ch.setMuted("name" .. i, true) end
    check("capped, oldest out", not Ch.mutedByMe("name1") and Ch.mutedByMe("name205"))
    check("another server's stay", string.find(FILES["ZeD_chatmute.txt"], "1.1.1.1:1|other", 1, true) ~= nil)
    FILES["ZeD_chatmute.txt"], Ch.myMutes = nil, nil
    Ch.muteSeq = Ch.muteSeq + 1
    -- Report
    chatDraw(cw)
    OPENED = {}
    cw:onMouseDown(cw._actHits[1].x + 1, cw._actHits[1].y + 1)
    check("Report opens the Server tab", OPENED[1] == "server")
    local r = TC.reportNext
    check("the player named", r and r.who == "mike_d")
    check("the chat around it", r.n >= 6 and r[2].text == "lol nope" and r[2].mark == true and r[1].text ~= nil)
    reset()
    useTab("server")
    view()
    draw()
    draw()
    check("the Ask card opens", st.card and st.card.kind == "ask" and TC.reportNext == nil)
    check("named", textDrawn(WORDS("UI_ZeD_Tk_FactReported")) and textDrawn("mike_d"))
    check("the kind is a start", t.ask.kind == "GRIEF" and t.ask.here == true)
    check("the chat shows, each line to read", stopOf("tk:chat:2") ~= nil and textDrawn("lol nope"))
    check("whose chat it is is said", textDrawn(string.sub(WORDS("UI_ZeD_Tk_ChatWhose"), 1, 24)))
    typeIn("ask", "He took my truck")
    CLIENT = {}
    click("tk:send")
    local a = lastCmd("t_new")
    check("Send carries it", a and a.report and a.report.who == "mike_d" and a.report.n == r.n and a.kind == "GRIEF", a and a.kind)
    check("the words are only the player's", a.text == "He took my truck")
    -- without the server part
    reset()
    S.forceOff = true
    TC.reportNext = { who = "mike_d", n = 1, { who = "mike_d", text = "lol nope", t = "9:32" } }
    draw()
    draw()
    check("no server part: the card still opens", st.card and st.card.kind == "ask" and t.ask.report == nil)
    check("the name in the player's words, no chat", field("ask") and field("ask"):getText() == "About mike_d: " and stopOf("tk:chat:1") == nil, field("ask") and field("ask"):getText())
    S.forceOff = nil
    -- admins
    Ch.qaAdmin = true
    cw = chatDraw(chatWin(440, 400))
    row = rowOf("lol nope")
    cw:onMouseDown(cw._linesRect.x + 2, row.y + 1)
    chatDraw(cw)
    check("an admin gets four", #cw._acts == 4)
    check("Player card and Teleport", textDrawn(WORDS("UI_ZeD_Tk_PlayerCard"), cw) and textDrawn(getText("UI_Scoreboard_Teleport"), cw))
    A2.qaLink = true
    cw:onMouseDown(cw._actHits[3].x + 1, cw._actHits[3].y + 1)
    check("Player card goes to the Admin tab", A2.openPlayerNext == "mike_d")
    reset()
    useTab("admin")
    view()
    draw()
    draw()
    check("the card opens on that player", st.card and st.card.kind == "player" and st.card.user == "mike_d" and A2.openPlayerNext == nil)
    A2.qaLink = nil
    useTab("server")
    CLIENT, COMMANDS2 = {}, nil
    chatDraw(cw)
    ZEDQA_CAPS.TeleportToPlayer = nil
    chatDraw(cw)
    check("Teleport without the power is gray and says why", cw._acts[4].disabled and cw._acts[4].why == A2.why("TeleportToPlayer"), cw._acts[4].why)
    ZEDQA_CAPS.TeleportToPlayer = true
    chatDraw(cw)
    cw:onMouseDown(cw._actHits[4].x + 1, cw._actHits[4].y + 1)
    check("Teleport asks the server first", lastCmd("a_tp") and lastCmd("a_tp").user == "mike_d")
    -- a second press lets the line go
    row = rowOf("lol nope")
    cw:onMouseDown(cw._linesRect.x + 2, row.y + 1)
    chatDraw(cw)
    check("a second press lets go", cw.picked == nil and not textDrawn(WORDS("UI_ZeD_Chat_Report"), cw))
    -- another tab
    cw.picked = rowOf("lol nope").ln
    chatDraw(cw)
    cw:pickTab("private")
    chatDraw(cw)
    check("another tab lets go", cw.picked == nil)
    cw:pickTab("general")
    -- the oldest line going takes the pick with it
    cw.picked = Ch.lines[1]
    chatDraw(cw)
    table.remove(Ch.lines, 1)
    chatDraw(cw)
    check("a line that went off the top lets go", cw.picked == nil)
    Ch.qaAdmin = false

    -- the buttons at the smallest window and the Deck's words
    for _, size in ipairs({ { 0.75, "small", 225, 200 }, { 0.75, "large", 225, 200 }, { 1, "small", 300, 200 }, { 1.75, "large", 770, 455 } }) do
        ZEDQA_ROOT, ZEDQA_LARGE = size[1], size[2] == "large"
        ZeD.applyTheme("dark", "orange", size[2])
        Ch.qaAdmin = true
        cw = chatDraw(chatWin(size[3], size[4]))
        cw.picked = Ch.lines[1]
        cw.seek = Ch.lines[1]
        chatDraw(cw)
        chatDraw(cw)
        local name = "chat buttons at " .. size[3] .. " " .. size[2]
        check(name .. ": all four", #cw._acts == 4)
        for _, b in ipairs(cw._acts) do
            check(name .. ": inside the list", b.dx + b.w <= cw._linesRect.w + 1, b.text)
        end
        for _, x in ipairs(cw.texts) do
            check(name .. ": words inside", x.x + x.w <= size[3] + 1, x.s)
        end
        Ch.qaAdmin = false
    end
    ZEDQA_ROOT, ZEDQA_LARGE = 1, false
    ZeD.applyTheme("dark", "orange", "small")

    -- the pad
    Ch.qaAdmin = true
    cw = chatDraw(chatWin(440, 300))
    local jd = { focus = cw }
    cw.joyfocus = jd
    FOCUS.pad = true
    cw.zone = "input"
    cw:_padStep("up")
    check("up from the line: the newest line with a sender", cw.zone == "lines" and cw.cur ~= nil and cw.cur.author == "mike_d", cw.cur and cw.cur.author)
    local newest = cw.cur
    chatDraw(cw)
    cw:_padStep("up")
    check("up: the one before", cw.cur ~= newest)
    chatDraw(cw)
    check("a line under the cursor is marked", (ZEDQA_MARKS or 0) > 0)
    local cur = cw.cur
    cw:onJoypadDown(Joypad.AButton, jd)
    chatDraw(cw)
    check("A picks", cw.picked == cur and cw.zone == "acts" and cw.actI == 1)
    check("the prompts say so", cw:getFooterPrompts() ~= nil)
    cw:_padStep("right")
    check("right: the next button", cw.actI == 2)
    cw:_padStep("left")
    cw:_padStep("left")
    check("no further left", cw.actI == 1)
    for _ = 1, 6 do cw:_padStep("right") end
    check("no further right", cw.actI == 4)
    ZEDQA_CAPS.TeleportToPlayer = nil
    chatDraw(cw)
    CLIENT = {}
    cw:onJoypadDown(Joypad.AButton, jd)
    check("a gray button says why, and does nothing", Ch.noteNow() == A2.why("TeleportToPlayer") and lastCmd("a_tp") == nil)
    ZEDQA_CAPS.TeleportToPlayer = true
    chatDraw(cw)
    cw:onJoypadDown(Joypad.BButton, jd)
    check("B goes back, the window stays", cw.zone == "lines" and cw.picked == nil and Ch.win == cw)
    cw:onJoypadDown(Joypad.AButton, jd)
    chatDraw(cw)
    cw:_padStep("down")
    check("down from the buttons: on to the next line", cw.zone == "lines" and cw.picked == nil)
    for _ = 1, 20 do cw:_padStep("down") end
    check("past the newest: the line to type in", cw.zone == "input")
    cw.zone = "lines"
    cw.cur = nil
    for _ = 1, 20 do
        if cw.zone == "lines" then cw:_padStep("up") end
    end
    check("past the oldest: the tabs", cw.zone == "tabs")
    cw:_padStep("down")
    check("down from the tabs: the lines", cw.zone == "lines")
    -- a tab with no sender: the list scrolls as it did
    cw:pickTab("private")
    chatDraw(cw)
    cw.zone = "lines"
    cw:_padStep("up")
    check("no line to land on: up goes to the tabs", cw.zone == "tabs")
    cw:pickTab("general")

    -- every line is reachable: the list scrolls past the last line with a sender, and past lines between two of them
    local function fill(list)
        Ch.lines = {}
        for _, m in ipairs(list) do Ch.onMessage(msg(m[1], m[2], m[3])) end
    end
    local list = {}
    for i = 1, 20 do list[#list + 1] = { nil, "restart notice " .. i, "server" } end
    for i = 1, 20 do list[#list + 1] = { "Aretha", "my own line " .. i } end
    list[#list + 1] = { "Kade_R", "the only line to pick" }
    fill(list)
    cw = chatDraw(chatWin(440, 300))
    cw.joyfocus = { focus = cw }
    cw.zone = "input"
    cw:_padStep("up")
    check("up from the line: the one line with a sender", cw.zone == "lines" and cw.cur and cw.cur.author == "Kade_R")
    chatDraw(cw)
    check("this window can scroll", (cw._maxScroll or 0) > 0)
    cw:_padStep("up")
    chatDraw(cw)
    check("no line left that way: it scrolls, it does not leave", cw.zone == "lines" and cw.scroll > 0, cw.zone)
    local presses = 0
    while cw.zone == "lines" and presses < 80 do
        cw:_padStep("up")
        chatDraw(cw)
        presses = presses + 1
    end
    check("the oldest line is reached", textDrawn("restart notice 1", cw) and cw.zone == "tabs" and cw.scroll == cw._maxScroll, presses)
    check("leaving lets the cursor go", cw.cur == nil)
    cw:_padStep("down")
    chatDraw(cw)
    check("down from the tabs: into the lines, at the top of the view", cw.zone == "lines" and cw.scroll == cw._maxScroll)
    presses = 0
    while cw.zone == "lines" and presses < 80 do
        cw:_padStep("down")
        chatDraw(cw)
        presses = presses + 1
    end
    check("and all the way back", cw.zone == "input" and cw.scroll == 0, cw.zone)

    list = { { "Mags_77", "the older line to pick" } }
    for i = 1, 30 do list[#list + 1] = { "Aretha", "my own line " .. i } end
    list[#list + 1] = { "Kade_R", "the newer line to pick" }
    fill(list)
    cw = chatDraw(chatWin(440, 300))
    cw.joyfocus = { focus = cw }
    cw.zone = "input"
    cw:_padStep("up")
    chatDraw(cw)
    local most, was = 0, cw.scroll
    presses = 0
    local lh = ZeD.TM:getFontHeight(ZeD.T.fontF2) + ZeD.T.px(2)
    while not (cw.cur and cw.cur.author == "Mags_77") and presses < 80 do
        cw:_padStep("up")
        chatDraw(cw)
        most = math.max(most, cw.scroll - was)
        was = cw.scroll
        presses = presses + 1
    end
    check("from one line to the next: the lines between go by", cw.cur and cw.cur.author == "Mags_77" and most <= 3 * lh + 1, most)
    cw:_padStep("up")
    chatDraw(cw)
    check("a line to land on from the tabs is the oldest in view", (function()
        while cw.zone == "lines" do
            cw:_padStep("up")
            chatDraw(cw)
        end
        cw:_padStep("down")
        chatDraw(cw)
        return cw.cur and cw.cur.author == "Mags_77"
    end)())

    -- the pad goes with the card a press opened
    fill({ { "Kade_R", "anyone seen my truck?" } })
    Ch.qaAdmin = true
    A2.qaLink = true
    cw = chatDraw(chatWin(440, 300))
    local function pickFirst()
        cw = chatDraw(chatWin(440, 300))
        JoypadState.players = { {} }
        JoypadState.players[1].focus = cw
        cw.joyfocus = JoypadState.players[1]
        cw.picked = Ch.lines[1]
        chatDraw(cw)
    end
    pickFirst()
    FOCUS.claimed, FOCUS.win, FOCUS.reclaimed = nil, nil, nil
    cw._acts[1].run(cw)
    check("Report: the pad goes to the Character window", FOCUS.claimed == "the Character window" and Ch.win == nil)
    pickFirst()
    FOCUS.claimed, FOCUS.win = nil, "the Character window"
    cw._acts[1].run(cw)
    check("already its window: the pad is pushed back to it", FOCUS.reclaimed == true and FOCUS.claimed == nil)
    pickFirst()
    FOCUS.claimed, FOCUS.win = nil, "the Character window"
    cw._acts[3].run(cw)
    check("Player card: the World window", FOCUS.claimed == "the World window")
    A2.openPlayerNext, TC.reportNext = nil, nil
    FOCUS.claimed, FOCUS.win, FOCUS.reclaimed = nil, nil, nil
    -- the mouse leaves focus alone
    cw = chatDraw(chatWin(440, 300))
    JoypadState.players = {}
    cw.picked = Ch.lines[1]
    chatDraw(cw)
    cw._acts[1].run(cw)
    check("a mouse press moves no pad", FOCUS.claimed == nil)
    TC.reportNext = nil
    A2.qaLink = nil
    -- no server part: Player card opens the game's window, which needs someone this client can see
    S.forceOff = true
    cw = chatDraw(chatWin(440, 300))
    cw.picked = Ch.lines[1]
    chatDraw(cw)
    check("someone near: live", cw._acts[3].disabled ~= true, cw._acts[3].why)
    ONLINE = false
    chatDraw(cw)
    check("no one to open it on: gray, and why", cw._acts[3].disabled == true and cw._acts[3].why ~= nil and cw._acts[3].why ~= "", cw._acts[3].why)
    ONLINE = true
    S.forceOff = nil
    Ch.qaAdmin = nil
    FOCUS.pad = false
end

-- a report the server can't keep: the name goes in the words, as with no server part --------------
do
    useTab("server")
    for _, case in ipairs({ { "frozen", function() S.frozen = true end, function() S.frozen = nil end },
        { "from before this phase", function() S.cm = false end, function() S.cm = true end } }) do
        reset()
        view()
        case[2]()
        TC.reportNext = { who = "mike_d", n = 1, { who = "mike_d", text = "lol nope", t = "9:32" } }
        draw()
        draw()
        check(case[1] .. ": no report to lose", st.card and st.card.kind == "ask" and t.ask.report == nil)
        check(case[1] .. ": the name is in the words", field("ask") and field("ask"):getText() == "About mike_d: ", field("ask") and field("ask"):getText())
        case[3]()
    end
end

-- the real Focus Manager: its Y, the pad's first press and the right stick --------------------------
do
    local stub, events, base = ZeD.Input, Events, print
    local ticks, modeFns = {}, {}
    Events = setmetatable({ OnTick = { Add = function(fn) ticks[#ticks + 1] = fn end, Remove = function() end },
        ZeD_InputModeChanged = { Add = function(fn) modeFns[#modeFns + 1] = fn end } }, { __index = function(self, k)
            local ev = { Add = function() end, Remove = function() end }
            rawset(self, k, ev)
            return ev
        end })
    ZeD.Input = { Detector = { getMode = function() return "gamepad" end } }
    print = function() end
    assert(loadfile(ROOT .. "42/media/lua/client/ZeD/Input/FocusManager.lua"))()
    Events = events
    local Fo = ZeD.Input.Focus
    local stick = 0
    getJoypadData = function() return JoypadState.players[1] and { id = 0 } or nil end
    getJoypadFocus = function() return JoypadState.players[1] and JoypadState.players[1].focus end
    getControllerCount = function() return 1 end
    isControllerConnected = function() return true end
    getControllerAxisValue = function() return stick end
    JoypadButton = setmetatable({}, { __index = function() return { isDown = function() return false end } end })
    local function panelStub()
        local w = ISPanel:new(0, 0, 100, 100)
        w.visible = true
        return w
    end
    local charWin, worldWin = panelStub(), panelStub()
    local opens = 0
    local cw0, ww0 = ZeD_CharacterWindow, ZeD_WorldWindow
    local isOpen = false
    ZeD_CharacterWindow = { isOpen = function() return isOpen end, getWindow = function() return charWin end,
        ensureBothOpenForGamepad = function() opens = opens + 1; isOpen = true end }
    ZeD_WorldWindow = { isOpen = function() return isOpen end, getWindow = function() return worldWin end }
    local function run(ms)
        nowMs = nowMs + (ms or 50)
        for _, fn in ipairs(ticks) do fn() end
    end
    local function tapY()
        Fo.qaButton("Y", true)
        run()
        run()
        Fo.qaButton("Y", false)
        run()
        run()
    end
    JoypadState.players = { {} }
    local jd = JoypadState.players[1]
    view()
    -- first with no screen: this is the path that took the pad
    tapY()
    check("no screen: Y opens the pair (the path under test is live)", opens == 1 and Fo.getFocusedWindow() == charWin and jd.focus == charWin, opens)
    Fo.releaseFocus()
    isOpen = false
    opens = 0
    jd.focus = nil
    M.joinScreen()
    local w0 = CM.joinWin
    check("the screen is up, the pad on it", w0 ~= nil and jd.focus == w0)
    check("the manager knows", Fo.held() == true)
    tapY()
    w0:update()
    check("Y opens nothing under it", opens == 0 and Fo.getFocusedWindow() == nil and jd.focus == w0, opens)
    Fo.claimFocus(charWin)
    check("a window's open path can't take the pad", Fo.getFocusedWindow() == nil and jd.focus == w0)
    for _ = 1, 3 do
        run()
        w0:update()
    end
    check("a Y held across the screen's end opens nothing", (function()
        Fo.qaButton("Y", true)
        run()
        w0:finish()
        run()
        Fo.qaButton("Y", false)
        run()
        run()
        return opens == 0 and Fo.held() == false
    end)())
    -- a window focused when the screen goes up, and the right stick
    Fo.claimFocus(charWin)
    check("a window has the pad", jd.focus == charWin and Fo.getFocusedWindow() == charWin)
    M.joinScreen()
    w0 = CM.joinWin
    check("the screen takes it", jd.focus == w0 and Fo.getFocusedWindow() == nil)
    nowMs = nowMs + 5000
    stick = 1
    run()
    run()
    stick = 0
    w0:update()
    check("the stick does not take it back", jd.focus == w0 and CM.joinWin == w0)
    w0:finish()
    check("and the window has it again at the end", jd.focus == charWin and Fo.getFocusedWindow() == charWin)
    -- (ZeD_CharacterWindow is too big for a stub world: the guard is read from its source)
    local f = assert(io.open(ROOT .. "42/media/lua/client/ZeD/ZeD_CharacterWindow.lua", "rb"))
    local src = f:read("*a")
    f:close()
    local at = string.find(src, "function ZeD_CharacterWindow.ensureBothOpenForGamepad", 1, true)
    check("the pair's own opener stops for the screen", at ~= nil and string.find(string.sub(src, at, at + 200), "Focus.held()", 1, true) ~= nil)
    -- (punch list 97: as the World window does, the drawer takes off what a tab left on, counting coverClear's clips)
    check("the Character window's drawer clears the clips a tab left on",
        string.find(src, "p._coverClears = (p._coverClears or 0) + 1", 1, true) ~= nil
        and string.find(src, "for _ = 1, (self._zedStencilN or 0) - clipsBefore + self._coverClears do self:clearStencilRect() end", 1, true) ~= nil)
    ZeD.Input, print = stub, base
    ZeD_CharacterWindow, ZeD_WorldWindow = cw0, ww0
    JoypadState.players = {}
end

-- a report on its ticket cards ----------------------------------------------------------------
do
    reset()
    useTab("server")
    C.one[7] = { id = 7, kind = "GRIEF", st = "Sent", day = 12, filed = getTimestamp(), thread = { n = 1, { who = "Aretha", text = "He took my truck" } }, can = true, report = Q.REP }
    TC.qaHold = true
    TC.openMine(win, st, 7)
    draw()
    draw()
    check("my ticket says who it names", textDrawn(WORDS("UI_ZeD_Tk_FactReported")) and textDrawn("mike_d"))
    check("and the chat", textDrawn("lol nope"))
    TC.qaHold = nil
    reset()
    useTab("admin")
    C.card = { id = 7, source = "zed", kind = "GRIEF", author = "Aretha", status = "Open", day = 12, filed = getTimestamp(), thread = { n = 1, { who = "Aretha", text = "He took my truck" } }, notes = { n = 0 }, report = Q.REP }
    TC.qaHold = true
    TC.openStaff(win, st, 7)
    draw()
    draw()
    check("staff read who is named", textDrawn(WORDS("UI_ZeD_Tk_FactReported")) and textDrawn("mike_d"))
    check("with the Player card", stopOf("tk:pcard2") ~= nil)
    check("and the chat, each line to step through", stopOf("tk:chat:1") ~= nil and textDrawn("anyone seen my truck"))
    check("saying whose it is", textDrawn(string.sub(WORDS("UI_ZeD_Tk_ChatWhose"), 1, 24)))
    TC.qaHold = nil
    C.card = nil
end

-- the three phases on one screen -----------------------------------------------------------------
do
    local E, Ex, Lm, AC2 = ZeD.Extras, ZeD.Ex, ZeD.Logs, ZeD.AdminCards
    local tr = ZeD.tr
    local function heads(list)
        local out = {}
        for _, it in ipairs(list or {}) do
            if it.k == "head" then out[#out + 1] = it.text end
        end
        return out
    end
    local function order(list, words)
        local at = 0
        for _, w in ipairs(words) do
            local found = nil
            for i = at + 1, #list do
                if list[i] == w then found = i; break end
            end
            if not found then return false, w end
            at = found
        end
        return true
    end
    reset()
    M.qaHold, M.qaLink, A2.qaHold, A2.qaLink, TC.qaHold = true, true, true, true, true
    M.view = Q.view({})
    M.bump()
    E.qaHold, E.qaLink = true, true
    E.set = Ex.defaults()
    E.set.vc.on = true
    E.mineRows = {}
    E.bump()
    Lm.qaLink = true
    useTab("admin")
    st.homeKey = nil
    draw()
    draw()
    local ok, miss = order(heads(st.homeItems), { getText("UI_userpanel_tickets"), tr("UI_ZeD_Log_Title"), tr("UI_ZeD_Srv_Players"), tr("UI_ZeD_Adm_Roles"), tr("UI_ZeD_Adm_Bans"),
        tr("UI_ZeD_Adm_Spawn"), tr("UI_ZeD_Cm_RulesNews"), tr("UI_ZeD_Ex_Title") })
    check("the Admin tab holds Log, Rules and news and Server extras, in order", ok, miss)
    local key = st.homeKey
    Lm.qaLink = false
    draw()
    check("the home key holds the log", st.homeKey ~= key)
    key = st.homeKey
    Lm.qaLink = true
    draw()
    key = st.homeKey
    M.bump()
    draw()
    check("and community", st.homeKey ~= key)
    key = st.homeKey
    E.bump()
    draw()
    check("and the extras", st.homeKey ~= key)

    useTab("server")
    draw()
    draw()
    ok, miss = order(heads(st.items), { tr("UI_ZeD_Srv_Server"), tr("UI_ZeD_Cm_News"), tr("UI_ZeD_Ex_Head"), getText("UI_userpanel_tickets") })
    check("the Server tab: Server, News, this server's extras, Tickets", ok, miss)
    local rowsAt, claimsAt, newsAt = nil, nil, nil
    for i, it in ipairs(st.items) do
        if it.c and it.c.id == "cm:rules" then rowsAt = i end
        if it.k == "head" and it.text == tr("UI_ZeD_Cm_News") then newsAt = i end
        if it.c and it.c.id == "xclaims" then claimsAt = i end
    end
    check("The rules sit in the Server block, ahead of News", rowsAt ~= nil and newsAt ~= nil and rowsAt < newsAt, rowsAt)

    -- a hello with no extras: the last server's go with it
    E.qaLink = nil
    E.onHello({})
    check("a server with no extras: nothing is kept from the last", E.set == nil and E.mineRows == nil and E.live() == false)
    E.onHello({ ex = Ex.defaults() })
    check("and a hello that has them brings them", E.set ~= nil)
    E.set, E.qaHold = nil, nil
    Lm.qaLink = nil

    -- a report from chat: Around sits under the Reported row, like any other ticket
    reset()
    useTab("admin")
    Lm.qaLink = true
    C.card = { id = 7, source = "zed", kind = "GRIEF", author = "Aretha", status = "Open", day = 12, filed = getTimestamp(), place = { x = 6280, y = 5350, z = 0 }, near = { n = 0 },
        thread = { n = 1, { who = "Aretha", text = "He took my truck" } }, notes = { n = 0 }, report = Q.REP }
    TC.openStaff(win, st, 7)
    draw()
    draw()
    local rep, around = stopOf("tk:pcard2"), stopOf("tk:around")
    check("a report's ticket has the Reported row", rep ~= nil)
    check("and Around, lit", around ~= nil and not (around.tkWhy and around.tkWhy()), around and around.tkWhy and around.tkWhy())
    C.card.place, C.card.report = nil, Q.REP
    C.seq = C.seq + 1
    draw()
    draw()
    around = stopOf("tk:around")
    check("unticked Include where I am: gray, with why", around ~= nil and around.tkWhy and around.tkWhy() == tr("UI_ZeD_Log_NoPlaceTicket"))
    C.card = nil
    Lm.qaLink = nil
    M.qaHold, M.qaLink, A2.qaHold, A2.qaLink, TC.qaHold = nil, nil, nil, nil, nil
    M.view = nil
    reset()
end

-- a whisper: the line empties once it went, and "/w name " comes back when the line is opened again in that tab,
-- as the game's chat does (ISChat:onCommandEntered keeps it, ISChat:focus gives it back; the outside review of beta 7)
do
    local PM = {}
    local was = proceedPM
    proceedPM = function(t)
        PM[#PM + 1] = t
        local q = t:match('^%s*"([^"]+)"')
        return q or t:match("^%s*(%S+)") or ""
    end
    local cw = chatDraw(chatWin(440, 400))
    Ch.tab, Ch.keep = "general", nil
    local function send(text)
        Ch.slowUntil = 0
        cw.input:setText(text)
        cw.input:focus()
        cw:submit()
    end
    send("/w mike_d you there?")
    check("the whisper went", PM[#PM] == "mike_d you there?", PM[#PM])
    check("the line is empty once it went", cw.input:getText() == "", cw.input:getText())
    cw:update()
    check("and stays empty while you are out of it", cw.input:getText() == "")
    cw:onMouseDown(cw._inputRect.x + 1, cw._inputRect.y + 1)
    check("opened again: the whisper's start comes back", cw.input:getText() == "/w mike_d " and cw.input:isFocused(), cw.input:getText())
    cw.input:unfocus()
    cw:update()
    check("left untouched: the line empties again", cw.input:getText() == "")
    send('/whisper "Big Mags" ok')
    check("the long command and a quoted name, by the game's answer", Ch.keep and Ch.keep.text == "/whisper Big Mags ", Ch.keep and Ch.keep.text)
    cw:pickTab("private")
    cw:onMouseDown(cw._inputRect.x + 1, cw._inputRect.y + 1)
    check("another tab keeps its own line", cw.input:getText() == "", cw.input:getText())
    cw.input:unfocus()
    cw:pickTab("general")
    cw.input:setText("half a thought")
    cw:onMouseDown(cw._inputRect.x + 1, cw._inputRect.y + 1)
    check("a line being written is left alone", cw.input:getText() == "half a thought")
    cw.input:setText("")
    send("hello all")
    check("a plain line leaves the whisper be, as the game's does", Ch.keep and Ch.keep.text == "/whisper Big Mags ")
    cw:onMouseDown(cw._inputRect.x + 1, cw._inputRect.y + 1)
    check("so the line still opens on it", cw.input:getText() == "/whisper Big Mags ", cw.input:getText())
    cw.input:unfocus()
    cw:update()
    send("/s hello all")
    check("another stream's command lets the whisper go", Ch.keep == nil)
    cw:onMouseDown(cw._inputRect.x + 1, cw._inputRect.y + 1)
    check("so the line opens empty", cw.input:getText() == "")
    cw.input:unfocus()
    proceedPM = was
    Ch.keep, Ch.win = nil, nil
end

print("community_cards_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
